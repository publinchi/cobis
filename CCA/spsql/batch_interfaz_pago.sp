/************************************************************************/ 
/*    ARCHIVO:         batch_interfaz_pago.sp                           */ 
/*    NOMBRE LOGICO:   sp_batch_interfaz_pago                           */ 
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
/* 22/04/2022    G. Fernandez	 Corrección de varible de mensaje error */
/* 18/07/2022    G. Fernandez	 Cambio de tipo de dato en num_boleta de*/
/*                               int a varchar                          */
/* 04/08/2022	 A. MONROY		 Oficina de usuario = Oficina Oper.		*/
/* 05/08/2022	 G. Fernandez	 Se incluye campo de num. boleta para la*/
/*                               act. del estado de gegistro de pago    */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_batch_interfaz_pago')
   drop proc sp_batch_interfaz_pago
go
create proc sp_batch_interfaz_pago
(
@i_param1               varchar(255)  ,   -- nombre del catalogo
@i_param2               datetime      ,   -- fecha proceso 
@i_param3               varchar(4000) ,   -- directorio salida
@i_param4               varchar(4000)     -- nombre del archivo salida    
)
as declare
@w_return                  int,
@w_num                     int,
@w_error		           int,
@w_msg			           varchar(64),
@w_sp_name                 varchar(64),
@w_cod_banco               int,
@w_cta_banco               varchar(20),
@w_f_pago                  varchar(20),
@w_llave                   varchar(255),
@w_moneda_local            int,
@w_mensaje                 descripcion,
@w_total_registros         int,
@w_contador                int,
@w_numero                  int,
@w_comprobante             varchar(100),
@w_sql                     varchar(255),
@w_tipo_bcp                varchar(10), 
@w_separador               varchar(1),
@w_nombre_arch             varchar(255),
@w_fecha_proceso           datetime,
@w_directorio              varchar(255),
@w_bpc_fecha_proceso       datetime,
@w_bpc_nom_catalogo        varchar(30),
@w_bpc_num_operacion       varchar(20), 
@w_bpc_valor_pago          money, 
@w_bpc_num_boleta          varchar(20),  --GFP 18/07/2022
@w_bpc_fecha_pago          datetime, 
@w_bpc_estado              char(1), 
@w_bpc_cod_error_valida    int, 
@w_bpc_cod_error_procesa   int,
@w_bpc_msg_error_valida    varchar(4000),
@w_bpc_msg_error_procesa   varchar(4000),
@w_msg_error               varchar(255),
@w_ssn                     int         ,
@w_error_inter             int         ,
@w_srv                     varchar(20) ,
@w_user                    varchar(20) ,
@w_rol                     int         ,
@w_ofi                     smallint    ,
@w_term                    varchar(20) ,
@w_formato_fecha           int


--CREACION DE TABLA PARA SALIDA DE DATOS	   
create table ##ca_batch_pagos_corresponsal_tmp
(
bpct_fecha_proceso     datetime,
bpct_nom_catalogo      varchar(30),
bpct_num_operacion     varchar(20),
bpct_valor_pago        money,
bpct_num_boleta        varchar(20),  --GFP 18/07/2022
bpct_fecha_pago        datetime,
bpct_estado            char(1),
bpct_cod_error_valida  int,
bpct_msg_error_valida  varchar(4000),
bpct_cod_error_procesa int,
bpct_msg_error_procesa varchar(4000),
)


--Parametros 
select @w_sp_name        = 'sp_batch_interfaz_pago',
       @w_user           = 'op_batch',
	   --@w_ofi            = 0, -- AMO 20220804
	   @w_rol            = 1,
	   @w_term           = 'TERM BATCH',
	   @w_formato_fecha  = 103, 
       @w_tipo_bcp       = 'in',
       @w_separador      = ';',
	   @w_directorio     = @i_param3  -- Directorio de ubicacion de archivos

select @w_num =  codigo from cobis..cl_tabla 
where  tabla = @i_param1     

if @@rowcount <> 1
begin
	select @w_error = 725108 -- Cambiar codigo de error 
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

select
@w_srv = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SRVR'

truncate table cob_cartera..ca_archivo_pagos_1_tmp
truncate table cob_cartera..ca_archivo_pagos_1

-- DETERMINAR FECHA PROCESO 
select @w_fecha_proceso = fp_fecha
from   cobis..ba_fecha_proceso with (nolock)

select @w_fecha_proceso = isnull (@i_param2, @w_fecha_proceso)


/*CONSULTA CODIGO DE MONEDA LOCAL */
SELECT  @w_moneda_local = pa_tinyint
FROM cobis..cl_parametro
WHERE pa_nemonico = 'MLO'
AND pa_producto = 'ADM'
set transaction isolation level read uncommitted


declare pagos_cartera cursor for select 
bpc_fecha_proceso   , bpc_nom_catalogo,     
bpc_num_operacion   , bpc_valor_pago  ,     
bpc_num_boleta      , bpc_fecha_pago  ,     
bpc_estado          , bpc_cod_error_valida, 
bpc_msg_error_valida, bpc_cod_error_procesa,
bpc_msg_error_procesa 
from cob_cartera..ca_batch_pagos_corresponsal
where bpc_fecha_proceso = @i_param2
and   bpc_nom_catalogo  = @i_param1
and   bpc_estado        = 'V'
for read only

open  pagos_cartera                                     
fetch pagos_cartera into  
@w_bpc_fecha_proceso   , @w_bpc_nom_catalogo,    
@w_bpc_num_operacion   , @w_bpc_valor_pago  ,      
@w_bpc_num_boleta      , @w_bpc_fecha_pago  ,     
@w_bpc_estado          , @w_bpc_cod_error_valida, 
@w_bpc_msg_error_valida, @w_bpc_cod_error_procesa,
@w_bpc_msg_error_procesa


while (@@fetch_status = 0)  
begin

	select @w_ssn = -1,
	       @w_return = 0,
		   @w_error = 0
		   
    SELECT @w_ofi = op_oficina
    FROM ca_operacion
    WHERE op_banco = @w_bpc_num_operacion
		   
    exec @w_ssn = master..rp_ssn
	
    exec @w_return = cob_cartera..sp_interfaz_pago
    @s_srv                  = @w_srv,
    @s_rol                  = @w_rol,      
    @s_ssn                  = @w_ssn,          
    @s_user                 = @w_user,
    @s_date                 = @w_fecha_proceso,
    @s_sesn                 = @w_ssn,
    @s_term                 = @w_term,
    @s_ofi                  = @w_ofi,              
    @i_operacion            = 'P',
    @i_banco                = @w_bpc_num_operacion,
    @i_monto                = @w_bpc_valor_pago,
    @i_moneda               = @w_moneda_local,
    @i_canal                = 2,
    @i_aplica_en_linea      = 'S',
    @i_fecha_pago           = @w_bpc_fecha_pago,
    @i_forma_pago           = @w_f_pago,                
    @i_banco_pago           = @w_cod_banco, 
    @i_cta_banco_pago       = @w_cta_banco, 
    @i_formato_fecha        = @w_formato_fecha,
    @i_id_referencia_inter  = @w_bpc_num_boleta,
    @i_referencia_pago      = @w_bpc_num_boleta,
    @i_observacion          = null,
   -- @i_debug                = 'S',
	@o_error                = @w_error out
	
    
    if @w_return <> 0
    begin
	    select @w_msg_error = mensaje from cobis..cl_errores
        where numero = @w_return
		
		while @@trancount > 0
        rollback tran
		
		update cob_cartera..ca_batch_pagos_corresponsal
        set   bpc_estado            = 'E',
		      bpc_cod_error_valida  = @w_error,  
			  bpc_msg_error_valida  = @w_msg_error   --GFP 22/04/2022
	    where bpc_num_operacion     = @w_bpc_num_operacion
		and   bpc_fecha_proceso     = @i_param2
        and   bpc_nom_catalogo      = @i_param1		

		
    end	
	else
	begin
	   select @w_mensaje = 'Pago Realizado correctamente'
	   update cob_cartera..ca_batch_pagos_corresponsal
       set  bpc_estado            = 'P',
	        bpc_cod_error_valida  = 0,
	   	  bpc_msg_error_valida  = @w_mensaje
	   where bpc_num_operacion     = @w_bpc_num_operacion
	   and   bpc_fecha_proceso     = @i_param2
       and   bpc_nom_catalogo      = @i_param1	
	   and   bpc_num_boleta        = @w_bpc_num_boleta
	end
	
   fetch pagos_cartera into  
   @w_bpc_fecha_proceso   , @w_bpc_nom_catalogo,    
   @w_bpc_num_operacion   , @w_bpc_valor_pago  ,      
   @w_bpc_num_boleta      , @w_bpc_fecha_pago  ,     
   @w_bpc_estado          , @w_bpc_cod_error_valida, 
   @w_bpc_msg_error_valida, @w_bpc_cod_error_procesa,
   @w_bpc_msg_error_procesa
	
end

close pagos_cartera          
deallocate pagos_cartera

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

close pagos_cartera          
deallocate pagos_cartera
drop table ##ca_batch_pagos_corresponsal_tmp
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error 

return @w_error
go