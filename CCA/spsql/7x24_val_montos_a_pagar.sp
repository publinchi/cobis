/************************************************************************/ 
/*    ARCHIVO:         7x24_val_montos_a_pagar.sp                       */ 
/*    NOMBRE LOGICO:   sp_7x24_valida_montos_a_pagar                    */ 
/*   Base de datos:    cob_cartera                                      */
/*   Producto:         Cartera                                          */
/*   Disenado por:     Kevin Rodríguez                                  */
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
/*  Procedimiento encargado de validar si se encuentra habilitado el    */
/*  proceso de consultas o pagos desde el servicio web                  */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA       AUTOR           RAZON                                  */ 
/* 19/12/2022    K. Rodríguez    Versión Inicial                        */
/* 23/01/2023    G. Fernandez    Ingreso de parámetro de salida para    */
/*                               fecha de cierre                        */
/* 23/01/2023    G. Fernandez    S802833 Se valida el monto ingresado   */
/*                               con el valor de la tabla de saldo      */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_7x24_valida_montos_a_pagar')
   drop proc sp_7x24_valida_montos_a_pagar
go
create proc sp_7x24_valida_montos_a_pagar
@s_ssn                int           = null,
@s_sesn               int           = null,
@s_ofi                smallint      = null,
@s_rol                smallint      = null,
@s_user               login         = null,
@s_date               datetime      = null,
@s_term               descripcion   = null,
@t_debug              char(1)       = 'N',
@t_file               varchar(10)   = null,
@t_from               varchar(32)   = null,
@s_srv                varchar(30)   = null,
@s_lsrv               varchar(30)   = null,
@t_trn                int           = null,
@s_format_date        int           = null,   
@s_ssn_branch         int           = null,
@i_amounttopay        money         = null,
@i_reference          varchar(30)   = null,
@o_amounttopay        money         = null out,
@o_reference          varchar(30)   = null out,
@o_status             varchar(255)  = null out,  
@o_valida_montos      char(1)       = null out,  -- Variable que indica si está habilitada la consulta o pago desde WS.
@o_fecha_cierre       datetime      = null out

         
as declare
@w_error		    int,
@w_sp_name          varchar(64),
@w_fecha_cierre     datetime,
@w_saldo_a_pagar    money

-- Información inicial
select @w_sp_name = 'sp_7x24_valida_montos_a_pagar'
	     
-- Fecha de cierre de Cartera
select @w_fecha_cierre = convert(varchar(10),fc_fecha_cierre,101)
from   cobis..ba_fecha_cierre with (nolock)
where  fc_producto = 7

if @w_fecha_cierre in (select fc_fecha_proceso from ca_7x24_fcontrol) 
begin
   select @o_valida_montos = 'S',
          @o_fecha_cierre  = convert(varchar(10),@w_fecha_cierre,101)
		  
   select @w_saldo_a_pagar = sp_saldo_a_pagar 
   from  ca_7x24_saldos_prestamos
   where sp_num_banco = @i_reference

   if isnull(@i_amounttopay,0) <> isnull(@w_saldo_a_pagar,0)
   begin
      select @w_error = 725284 --Error, monto ingresado no coincide con el valor a pagar de la operación
      goto ERROR
   end

end
else
begin
   SELECT @w_error = 725254
   goto ERROR
end
			
return 0

ERROR:

exec cobis..sp_cerror
@t_debug  = 'N',    
@t_file   = null,
@t_from   = @w_sp_name,   
@i_num    = @w_error

return @w_error    

go
