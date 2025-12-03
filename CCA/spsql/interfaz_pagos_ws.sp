/************************************************************************/ 
/*    ARCHIVO:         interfaz_pagos_ws.sp                             */ 
/*    NOMBRE LOGICO:   sp_interfaz_pagos_ws                             */ 
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
/* Proceso creado para realizar el pago por medio de un web service     */
/*                                                                      */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 18/05/2021    J. Hernandez	 Versión Inicial                        */
/* 29/11/2021    G. Fernandez    Cambio de codigo de error de llave     */
/* 02/12/2021    G. Fernandez    Actualización de nombre de parametros  */
/*                               para WS                                */
/* 07/12/2021     J. Hernandez       Ingreso de parametro de nombre     */
/*                                   de catalogo. Se modifica nombre    */
/*                                   Para que sea generico              */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_interfaz_pagos_ws')
   drop proc sp_interfaz_pagos_ws
go
create proc sp_interfaz_pagos_ws
@s_srv                  varchar(30)   = null,
@s_rol                  smallint      = null,      
@s_ssn                  int           = null,
@s_lsrv                 varchar(30)   = null,            
@s_user                 login         = null,
@s_date                 datetime      = null,
@s_sesn                 int           = null,
@s_term                 descripcion   = null,
@t_trn                  int           = null,
@s_ofi                  smallint      = null,
@s_format_date          int           = null,
@i_llave_conexion       varchar(255)  ,       -- Llave de conexion
@i_fecha                varchar(30)   = null, --Fecha del pago
@i_hora                 varchar(30)   = null, --Hora del pago
@i_id_prestamo          varchar(30)   ,       --num prestamo
@i_nombre_agente        varchar(30)   = null, --Nombre del agente comercial Iniciales
@i_cod_sucursal_agente  varchar(30)   = null, --codigo del agente comercial
@i_monto_pago           money         ,       -- monto 
@i_operacion            varchar(1)    ,       -- tipo operacion 1 pagos, 2 reversos
@i_cajero               varchar(64)   = null, -- Número de cajero
@i_num_autorizacion     varchar(30)   ,       -- numero de autorizacion de transaccion 
@i_num_auto_rever       varchar(30)   = null, -- numero de autorizacion de transaccion 
@i_nom_catalogo         varchar(400)  ,       -- Nombre del Catalogo
@o_error                int          out ,    -- numero de error
@o_msg_error            varchar(255) out      -- mensaje de error

as declare
@w_return           int,
@w_num              int,
@w_error		    int,
@w_msg			    varchar(64),
@w_sp_name          varchar(64),
@w_cod_banco        int,
@w_cta_banco        varchar(20),
@w_f_pago           varchar(20),
@w_llave            varchar(255),
@w_moneda_local     int,
@w_msg_error        varchar(255),
@w_operacion_pago   char(1)

--Parametros 

select @w_sp_name = 'sp_interfaz_pagos_ws'

select @w_num =  codigo from cobis..cl_tabla 
where  tabla = @i_nom_catalogo 

--codigo de error

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

select @w_llave     =  valor
from cobis..cl_catalogo
where tabla = @w_num
and   codigo = 'LLAVE'


if @i_llave_conexion <> @w_llave
begin
    select @w_error = 725117 
    goto ERROR	
end

if @i_operacion = 1
begin 
    select @w_operacion_pago = 'P'
end
else 
begin
    select @w_error = 725114 
    goto ERROR	
end

/*CONSULTA CODIGO DE MONEDA LOCAL */
SELECT  @w_moneda_local = pa_tinyint
FROM cobis..cl_parametro
WHERE pa_nemonico = 'MLO'
AND pa_producto = 'ADM'
set transaction isolation level read uncommitted

exec @w_return = cob_cartera..sp_interfaz_pago
@s_srv                  = @s_srv,
@s_rol                  = @s_rol,      
@s_ssn                  = @s_ssn,          
@s_user                 = @s_user,
@s_date                 = @s_date ,
@s_sesn                 = @s_sesn,
@s_term                 = @s_term,
@s_ofi                  = @s_ofi,              
@i_operacion            = @w_operacion_pago,
@i_banco                = @i_id_prestamo,
@i_monto                = @i_monto_pago,
@i_moneda               = @w_moneda_local,
@i_canal                = 3,
@i_aplica_en_linea      = 'S',
@i_fecha_pago           = @s_date,
@i_forma_pago           = @w_f_pago,                
@i_banco_pago           = @w_cod_banco, 
@i_cta_banco_pago       = @w_cta_banco, 
@i_formato_fecha        = @s_format_date,
@i_id_referencia_inter  = @i_num_autorizacion,
@i_referencia_pago      = @i_num_autorizacion,
@i_observacion          = null


if @w_return <> 0
begin
   select @w_msg_error = mensaje from cobis..cl_errores
   where numero = @w_return

   select @w_error = @w_return
   
   select @o_error = @w_error, 
          @o_msg_error = @w_msg_error 
		  
   goto ERROR
end	


select @o_error = isnull (@w_error,0) , 
       @o_msg_error = 'Pago realizado con éxito'  

return 0

ERROR:
select @w_msg_error = mensaje from cobis..cl_errores
       where numero = @w_error
	   
select @o_error = @w_error, 
       @o_msg_error = @w_msg_error 

exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error 



return @w_error
go