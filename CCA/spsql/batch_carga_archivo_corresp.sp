/************************************************************************/ 
/*    ARCHIVO:         batch_carga_archivo_corresp.sp                   */ 
/*    NOMBRE LOGICO:   sp_batch_carga_archivo_corresp                   */ 
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:    Johan Hernandez                                   */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 18/05/2021    J. Hernandez	 Versión Inicial                        */
/* 27/06/2021    K. Rodríguez    Obtener número de filas de archivo .csv*/
/* 03/08/2021    G. Fernández    Se aumenta tabla temporal para carga   */
/*                               inicial de registros de pagos          */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_batch_carga_archivo_corresp')
   drop proc sp_batch_carga_archivo_corresp
go
create proc sp_batch_carga_archivo_corresp
(
@i_param1               varchar(255)  ,   -- nombre del catalogo
@i_param2               datetime      ,   -- fecha proceso
@i_param3               char(1)  = 'N',   -- reprocesable
@i_param4               varchar(4000) ,   -- nombre archivo CSV
@i_param5               varchar(4000) ,    -- nombre archivo FMT
@i_param6               varchar(4000)    -- ruta en la que se encuentran los archivos            
)
as declare
@w_return              int,
@w_num                 int,
@w_error		       int,
@w_msg			       varchar(64),
@w_sp_name             varchar(64),
@w_cod_banco           int,
@w_cta_banco           varchar(20),
@w_f_pago              varchar(20),
@w_mensaje             descripcion,
@w_tipo_bcp            varchar(10), 
@w_separador           varchar(1),
@w_fecha_proceso       datetime,
@w_directorio          varchar(255),
@w_ssn                 int         ,
@w_error_inter         int         ,
@w_srv                 varchar(20) ,
@w_user                varchar(20) ,
@w_rol                 int         ,
@w_ofi                 int         ,
@w_term                varchar(20) ,
@w_formato_fecha       int,
@w_cmd                 varchar(5000),
@w_cmd_filas           varchar(5000),
@w_prueba_cmd          varchar(5000),
@w_nom_servidor        varchar(100),   --nombre de servidor donde se procesa bcp
@w_filas               varchar(4000),
@w_cont                int,
@w_fila_inicial        int
--Parametros 
select @w_sp_name        = 'sp_batch_carga_archivo_corresp',
       @w_user           = 'op_batch',
	   @w_ofi            = 0,
	   @w_rol            = 1,
	   @w_term           = 'TERM BATCH',
	   @w_formato_fecha  = 103, 
       @w_tipo_bcp       = 'in',
       @w_separador      = ';',
	   @w_nom_servidor   = null,
	   @w_directorio     = @i_param6,  -- Directorio de ubicacion de archivos
	   @w_fila_inicial   = 1

--Se obtiene la información del catalogo
select @w_num =  codigo from cobis..cl_tabla 
where  tabla = @i_param1     

if @@rowcount <> 1
begin
	select @w_error = 725108 
      goto ERROR
end 

select @w_cod_banco =  valor
from cobis..cl_catalogo
where tabla = @w_num
and   codigo = 'BANCO'

select @w_cta_banco =  valor
from cobis..cl_catalogo
where tabla = @w_num
and   codigo = 'CTA_BANCO'

select  @w_f_pago    =  valor
from cobis..cl_catalogo
where tabla = @w_num
and   codigo = 'FPAGO'


-- DETERMINAR FECHA PROCESO 
select @w_fecha_proceso = isnull(@i_param2,fp_fecha)
from   cobis..ba_fecha_proceso with (nolock)

--creacion de tabla
CREATE TABLE ##ca_batch_pagos_corresponsal_tmp
	(
	bpc_fecha_proceso     DATETIME,
	bpc_nom_catalogo      VARCHAR (30),
	bpc_num_operacion     VARCHAR (20),
	bpc_valor_pago        MONEY,
	bpc_num_boleta        VARCHAR (20),
	bpc_fecha_pago        DATETIME,
	bpc_estado            CHAR (1),
	bpc_cod_error_valida  INT,
	bpc_msg_error_valida  VARCHAR (4000),
	bpc_cod_error_procesa INT,
	bpc_msg_error_procesa VARCHAR (4000)
	)

-- Validación de existencia de registros y no es reprocesable
if exists(select 1
          from   cob_cartera..ca_batch_pagos_corresponsal
          where  bpc_fecha_proceso = @w_fecha_proceso
          and    bpc_nom_catalogo = @i_param1) 
   and @i_param3 = 'N'
begin 
	select @w_error = 725119
	goto ERROR
end

-- Validación de reprocesable de la carga de archivos
if @i_param3 = 'S'
begin
    delete from cob_cartera..ca_batch_pagos_corresponsal
    where  bpc_fecha_proceso = @w_fecha_proceso
    and    bpc_nom_catalogo  = @i_param1
	
	if @@error <> 0 
    begin
      select @w_error = 725121
	  goto ERROR
    end
end

--Servidor para la ejecución BCP
if @w_nom_servidor is null
begin 
   --parametro de nombre de servidor central
   select @w_nom_servidor = isnull(pa_char,'')
   from   cobis..cl_parametro
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'SCVL'

end


-- Se arma el llamado del BCP
select @w_cmd = 'bcp cob_cartera..##ca_batch_pagos_corresponsal_tmp in ' + @w_directorio  + @i_param4 + '.csv -f ' +  + @w_directorio + @i_param5 + '.fmt -F ' +convert(varchar(1),@w_fila_inicial)+ ' -T -S'+ @w_nom_servidor

print 'Cadena para bcp2: ' + @w_cmd
--generar bcp
exec @w_error = xp_cmdshell @w_cmd

if @w_error != 0 or @@error <> 0
BEGIN
   select @w_mensaje = 'Error al generar BCP '+@w_cmd,
          @w_return  = @w_error
   goto ERROR
end   

update ##ca_batch_pagos_corresponsal_tmp
set  bpc_fecha_proceso = @w_fecha_proceso,
     bpc_nom_catalogo  = @i_param1,
	 bpc_estado        = 'I'

 if @@error <> 0 
 begin
    select @w_error = 725120
	goto ERROR
 end
 
 --Ingreso de registros en tabla definitiva
insert into ca_batch_pagos_corresponsal
select * from ##ca_batch_pagos_corresponsal_tmp

--Comando que permite conocer cuantos registros posee el archivo
select @w_cmd_filas = 'find /v /c "" ' +  @w_directorio  + @i_param4 + '.csv'
create table #output (output varchar(255) null)
insert #output exec xp_cmdshell @w_cmd_filas
select @w_filas = output from #output where output is not null

--select @w_filas = isnull(substring(@w_filas, len(@w_filas), len (@w_filas)),'')
select @w_filas = isnull(ltrim(substring(@w_filas, (charindex('.CSV:', @w_filas)+len('.csv')+1), len(@w_filas))),'') -- KDR Obtiene número de filas de .csv 

if @w_filas = ''
   select @w_filas = '0'  -- KDR Para evitar error de transformación al comparar con @w_cont
  
select @w_cont= count(*)
from cob_cartera..ca_batch_pagos_corresponsal
where bpc_nom_catalogo = @i_param1
and  bpc_fecha_proceso = @w_fecha_proceso



if @w_cont <> @w_filas
begin 
    select @w_error = 725122
	delete cob_cartera..ca_batch_pagos_corresponsal
    where bpc_nom_catalogo = @i_param1
	and  bpc_fecha_proceso = @w_fecha_proceso
	
	goto ERROR
end


DROP TABLE ##ca_batch_pagos_corresponsal_tmp
return 0

ERROR: 
DROP TABLE ##ca_batch_pagos_corresponsal_tmp
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error 

return @w_error
go