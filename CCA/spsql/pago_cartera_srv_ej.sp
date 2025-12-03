/************************************************************************/
/*      Disenado por:           Raul Altamirano M.                      */
/*      Fecha de escritura:     Noviembre 2017                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Simular Pago de Domiciliacion a travez del IEN                  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_cartera_srv_ej')
   drop proc sp_pago_cartera_srv_ej
go
create proc sp_pago_cartera_srv_ej
(
@i_param1        cuenta           = NULL,  --@i_banco
@i_param2        datetime         = NULL,  --@i_fecha_valor
@i_param3        catalogo         = NULL,  --@i_forma_pago
@i_param4        money            = NULL,  --@i_monto_pago 
@i_param5        cuenta           = NULL   --@i_cuenta

)
as
declare 
@s_ssn  int, 
@s_sesn int, 
@s_user login, 
@s_term varchar(64),
@s_date datetime, 
@s_srv  varchar(64), 
@s_lsrv varchar(64), 
@s_rol  int,
@s_ofi  int, 
@s_culture varchar(100), 
@s_org     char (1), 
@i_banco   cuenta,	--Numero de Prestamo
@i_fecha_valor  datetime,  --Fecha Valor del Pago
@i_forma_pago   catalogo,  --Forma de Pago 
@i_monto_pago   money,  --Monto del Pago
@i_cuenta     cuenta,   --Cuenta Santander del Cliente
@w_sp_name    descripcion,
@w_error      int,
@w_msg        varchar(100),
@w_fecha_pro  datetime,
@w_sec_trn    int,
@w_est_cobis  char(1),
@w_ofi_oper   smallint,
@o_msg        varchar(255),
@o_secuencial_ing int


exec @s_ssn= ADMIN...rp_ssn


select 
@i_banco          = @i_param1,	--Numero de Prestamo
@i_fecha_valor    = @i_param2,  --Fecha Valor del Pago
@i_forma_pago     = @i_param3,  --Forma de Pago 
@i_monto_pago     = @i_param4,  --Monto del Pago
@i_cuenta         = @i_param5   --Cuenta Santander del Cliente

select @w_fecha_pro = fp_fecha from cobis..ba_fecha_proceso

select 
@s_sesn = @s_ssn, 
@s_user = 'usrbatch', 
@s_term = '0',
@s_date = @w_fecha_pro, 
@s_srv  = '0', 
@s_lsrv = 'CTSSRV', 
@s_rol = 3,
@s_ofi = 0, 
@s_culture = NULL, 
@s_org = 'U',
@w_sec_trn = @s_ssn,
@w_est_cobis = 'I',
@w_msg = NULL,
@w_sp_name = 'sp_pago_cartera_srv_ej'


/*
exec @w_error = sp_ingresar_resultado_cobro
@s_user           = @s_user,
@s_term           = @s_term,
@s_date           = @s_date,
@s_ofi            = @s_ofi,  
@i_sl_secuencial        = @w_sec_trn,
@i_sl_fecha_gen_orden   = @w_fecha_pro,
@i_sl_monto_pag         = @i_monto_pago,
@i_sl_estado_santander  = @w_est_cobis

if @w_error <> 0
begin 
   select @w_msg = 'Error !: Error al registrar informacion en Log de Pagos'
   goto ERROR_FIN
end
*/

select @w_ofi_oper = op_oficina
from  ca_operacion 
where op_banco = @i_banco

select @w_msg = NULL, @w_est_cobis = 'P'

exec @w_error     = sp_pago_cartera_srv
@s_user           = @s_user,
@s_term           = @s_term,
@s_date           = @s_date,
@s_ofi            = @w_ofi_oper,         
@i_banco          = @i_banco,		--Numero de Prestamo
@i_fecha_valor    = @i_fecha_valor, --Fecha Valor del Pago
@i_forma_pago     = @i_forma_pago,  --Forma de Pago 
@i_monto_pago     = @i_monto_pago,  --Monto del Pago
@i_cuenta         = @i_cuenta,      --Cuenta Santander del Cliente
@o_msg            = @o_msg out,
@o_secuencial_ing = @o_secuencial_ing out


if @w_error != 0 or @o_msg is not null
begin
   select @w_msg = @o_msg + 'Sec. Pago:' + convert(varchar, isnull(@o_secuencial_ing, 0)),
          @w_est_cobis = 'E'
		  
   goto ERROR_FIN		  
end		 


/*
exec @w_error = sp_actualizar_estado_resultado_cobro
@i_sl_secuencial        = @w_sec_trn,
@i_sl_fecha_gen_orden   = @w_fecha_pro,
@i_sl_estado_cobis      = @w_est_cobis,
@i_sl_mensaje_err_cobis = @w_msg

if @w_error <> 0
begin 
   select @w_msg = 'Error !: Error al actualizar informacion en Log de Pagos'
   goto ERROR_FIN
end	  
*/
	  
	  
return 0
   
ERROR_FIN:

  exec cob_cartera..sp_errorlog 
    @i_fecha       = @w_fecha_pro,
    @i_error       = @w_error,
    @i_usuario     = 'usrbatch',
    @i_tran        = 7999,
    @i_tran_name   = @w_sp_name,
    @i_cuenta      = @i_banco,
    @i_descripcion = @w_msg, 
    @i_rollback    = 'S' 
       
return @w_error


		 