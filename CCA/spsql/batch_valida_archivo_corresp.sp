/************************************************************************/ 
/*    ARCHIVO:         batch_valida_archivo_corresp.sp                  */ 
/*    NOMBRE LOGICO:   sp_batch_valida_archivo_corresp                  */ 
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
/* 27/06/2021    K. Rodríguez    Ajuste actualización tabla batch pagos */
/* 18/07/2022    G. Fernandez	 Cambio de tipo de dato en num_boleta de*/
/*                               int a varchar                          */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_batch_valida_archivo_corresp')
   drop proc sp_batch_valida_archivo_corresp
go
create proc sp_batch_valida_archivo_corresp
(
@i_param1               varchar(255)  ,   -- nombre del catalogo
@i_param2               datetime      ,   -- fecha proceso 
@i_param3               varchar(4000) ,   -- directorio salida
@i_param4               varchar(4000)     -- nombre del archivo salida    
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
@w_llave               varchar(255),
@w_moneda_local        int,
@w_mensaje             descripcion,
@w_total_registros     int,
@w_contador            int,
@w_numero              int,
@w_comprobante         varchar(100),
@w_sql                 varchar(255),
@w_tipo_bcp            varchar(10), 
@w_separador           varchar(1),
@w_nombre_arch         varchar(255),
@w_fecha_proceso       datetime,
@w_bpc_fecha_proceso     datetime,
@w_bpc_nom_catalogo      varchar(30),
@w_bpc_num_operacion     varchar(20), 
@w_bpc_valor_pago        money, 
@w_bpc_num_boleta        varchar(20),  --GFP 18/07/2022
@w_bpc_fecha_pago        datetime, 
@w_bpc_estado            char(1), 
@w_bpc_cod_error_valida  int, 
@w_bpc_cod_error_procesa int,
@w_bpc_msg_error_valida    varchar(4000),
@w_bpc_msg_error_procesa   varchar(4000),
@w_msg_error           varchar(255),
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
@w_directorio          varchar(4000) --directorio de ubicación de archivos.

--Parametros 
select @w_sp_name        = 'sp_batch_valida_archivo_corresp',
       @w_user           = 'op_batch',
	   @w_ofi            = 0,
	   @w_rol            = 1,
	   @w_term           = 'TERM BATCH',
	   @w_formato_fecha  = 103, 
       @w_tipo_bcp       = 'in',
       @w_separador      = ';',
	   @w_nom_servidor   = null,
	   @w_directorio     = @i_param3  -- Directorio de ubicacion de archivos
	   
--CREACION DE TABLA PARA SALIDA DE DATOS	   
create table ##ca_batch_pagos_corresponsal_tmp
(
bpct_fecha_proceso     datetime       null,
bpct_nom_catalogo      varchar(30)    null,  
bpct_num_operacion     varchar(20)    null,  
bpct_valor_pago        money          null,        
bpct_num_boleta        varchar(20)    null,    --GFP 18/07/2022      
bpct_fecha_pago        datetime       null,     
bpct_estado            char(1)        null,      
bpct_cod_error_valida  int            null,          
bpct_msg_error_valida  varchar(4000)  null ,
bpct_cod_error_procesa int            null,          
bpct_msg_error_procesa varchar(4000)  null  
)


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
select @w_fecha_proceso = fp_fecha
from   cobis..ba_fecha_proceso with (nolock)



--Servidor para la ejecución BCP
if @w_nom_servidor is null
begin 
   --parametro de nombre de servidor central
   select @w_nom_servidor = isnull(pa_char,'')
   from   cobis..cl_parametro
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'SCVL'

end

declare validacion_pagos_cartera cursor for select 
bpc_fecha_proceso   , bpc_nom_catalogo,     
bpc_num_operacion   , bpc_valor_pago  ,     
bpc_num_boleta      , bpc_fecha_pago  ,     
bpc_estado          , bpc_cod_error_valida, 
bpc_msg_error_valida, bpc_cod_error_procesa,
bpc_msg_error_procesa 
from cob_cartera..ca_batch_pagos_corresponsal
where bpc_fecha_proceso = @i_param2
and   bpc_nom_catalogo  = @i_param1
and   bpc_estado        = 'I'
for read only

open  validacion_pagos_cartera                                     
fetch validacion_pagos_cartera into  
@w_bpc_fecha_proceso   , @w_bpc_nom_catalogo,    
@w_bpc_num_operacion   , @w_bpc_valor_pago  ,      
@w_bpc_num_boleta      , @w_bpc_fecha_pago  ,     
@w_bpc_estado          , @w_bpc_cod_error_valida, 
@w_bpc_msg_error_valida, @w_bpc_cod_error_procesa,
@w_bpc_msg_error_procesa


while (@@fetch_status = 0)  
begin
	
    -- Validación si existe la operación 
	
    if not exists (select 1 from cob_cartera..ca_operacion 
	           where op_banco = @w_bpc_num_operacion)
	begin
	    select  @w_error = 725128
		select  @w_mensaje = mensaje from cobis..cl_errores
		where   numero     = @w_error
		
		update cob_cartera..ca_batch_pagos_corresponsal
        set   bpc_estado            = 'E',
		      bpc_cod_error_valida  = @w_error,
			  bpc_msg_error_valida  = @w_mensaje
	    where bpc_num_operacion     = @w_bpc_num_operacion
		and   bpc_fecha_proceso     = @i_param2
        and   bpc_nom_catalogo      = @i_param1
        and	  bpc_num_boleta        = @w_bpc_num_boleta   -- KDR 
			
       	
	    goto SIGUIENTE
	end
	
	-- validación monto
	if @w_bpc_valor_pago < 0
	begin
	    
	    select  @w_error = 724621
		select  @w_mensaje = mensaje from cobis..cl_errores
		where   numero     = @w_error
		
		update cob_cartera..ca_batch_pagos_corresponsal
        set   bpc_estado            = 'E',
		      bpc_cod_error_valida  = @w_error,
			  bpc_msg_error_valida  = @w_mensaje
	    where bpc_num_operacion     = @w_bpc_num_operacion
		and   bpc_fecha_proceso     = @i_param2
        and   bpc_nom_catalogo      = @i_param1
		and	  bpc_num_boleta        = @w_bpc_num_boleta   -- KDR
		
		goto SIGUIENTE 
	end
	
	--Validación fecha de pago
	if @w_bpc_fecha_pago > @w_fecha_proceso
	begin
	 
        select  @w_error = 70178
		select  @w_mensaje = mensaje from cobis..cl_errores
		where   numero     = @w_error
		
		update cob_cartera..ca_batch_pagos_corresponsal
        set  bpc_estado            = 'E',
		     bpc_cod_error_valida  = @w_error,			 
			 bpc_msg_error_valida  = @w_mensaje
	    where bpc_num_operacion     = @w_bpc_num_operacion
		and   bpc_fecha_proceso     = @i_param2
        and   bpc_nom_catalogo      = @i_param1
		and	  bpc_num_boleta        = @w_bpc_num_boleta   -- KDR
		
	    goto SIGUIENTE	
	end

	select @w_mensaje = 'Validacion Exitosa'
	update cob_cartera..ca_batch_pagos_corresponsal
    set  bpc_estado            = 'V',
	     bpc_cod_error_valida  = 0,
		  bpc_msg_error_valida  = @w_mensaje
	where bpc_num_operacion     = @w_bpc_num_operacion
	and   bpc_fecha_proceso     = @i_param2
    and   bpc_nom_catalogo      = @i_param1
    and	  bpc_num_boleta        = @w_bpc_num_boleta   -- KDR	

    
	SIGUIENTE:
    fetch validacion_pagos_cartera into  
    @w_bpc_fecha_proceso   , @w_bpc_nom_catalogo,    
    @w_bpc_num_operacion   , @w_bpc_valor_pago  ,      
    @w_bpc_num_boleta      , @w_bpc_fecha_pago  ,     
    @w_bpc_estado          , @w_bpc_cod_error_valida, 
    @w_bpc_msg_error_valida, @w_bpc_cod_error_procesa,
    @w_bpc_msg_error_procesa

end

close validacion_pagos_cartera          
deallocate validacion_pagos_cartera


insert into ##ca_batch_pagos_corresponsal_tmp
select bpc_fecha_proceso   , bpc_nom_catalogo,     
       bpc_num_operacion   , bpc_valor_pago  ,     
       bpc_num_boleta      , bpc_fecha_pago  ,     
       bpc_estado          , bpc_cod_error_valida, 
       bpc_msg_error_valida, bpc_cod_error_procesa,
       bpc_msg_error_procesa 
       from cob_cartera..ca_batch_pagos_corresponsal
       where bpc_fecha_proceso = @i_param2
       and   bpc_nom_catalogo  = @i_param1

select @w_tipo_bcp = 'out',
       @w_sql = '##ca_batch_pagos_corresponsal_tmp',
       @w_nombre_arch = @w_directorio + @i_param4+'-out-' +convert(VARCHAR(24),@w_fecha_proceso,23)+'.csv'

exec @w_return          = cobis..sp_bcp_archivos
    @i_sql              = @w_sql,           --select o nombre de tabla para generar archivo plano
    @i_tipo_bcp         = @w_tipo_bcp,      --tipo de bcp in,out,queryout
    @i_rut_nom_arch     = @w_nombre_arch,   --ruta y nombre de archivo
    @i_separador        = @w_separador   --separador

if @w_return <> 0
BEGIN
	select @w_error = 725113  
    goto ERROR
end

drop table ##ca_batch_pagos_corresponsal_tmp

return 0

ERROR:
if @w_error <> 0 
begin 
    exec cobis..sp_cerror
    @t_debug = 'N',
    @t_file  = null,
    @t_from  = @w_sp_name,
    @i_num   = @w_error 
    
    close validacion_pagos_cartera          
    deallocate validacion_pagos_cartera
    drop table ##ca_batch_pagos_corresponsal_tmp
end

return @w_error
go