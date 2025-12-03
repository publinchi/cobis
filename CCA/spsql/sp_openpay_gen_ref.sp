/************************************************************************/
/*    Base de datos:            cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sonia Rojas                             */
/*      Fecha de escritura:     13/09/2018                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                         PROPOSITO                                    */
/*      Tiene como propósito procesar los pagos de los corresponsales   */
/*                        MOFICACIONES                                  */
/* 24/07/2018         SRO                  SP generación y validación de*/
/*                                         referencia openpay           */
/************************************************************************/  
use cob_cartera
go


if exists(select 1 from sysobjects where name ='sp_openpay_gen_ref')
	drop proc sp_openpay_gen_ref
GO

CREATE proc sp_openpay_gen_ref(
    @s_ssn              int                = null,
    @s_user             login              = null,
    @s_sesn             int                = null,
    @s_term             varchar(30)        = null,
    @s_date             datetime           = null,
    @s_srv              varchar(30)        = null,
    @s_lsrv             varchar(30)        = null,
    @s_ofi              smallint           = null,
    @s_servicio         int                = null,
    @s_cliente          int                = null,
    @s_rol              smallint           = null,
    @s_culture          varchar(10)        = null,
    @s_org              char(1)            = null,
    @i_tipo_tran        char(5),           -- (GL) Garantia Líquida, (PG) Préstamo Grupal, (PI) Préstamo Individual, 
	                                       -- (PR) Precancelación, (CG)Cancelacción de Crédito Grupal, (CI)Cancelación de Crédito Individual
	@i_id_referencia    varchar(30),
	@i_monto            money              = null, --valor sugerido a pagar
	@i_monto_desde      money              = null,
	@i_monto_hasta      money              = null,
	@i_fecha_lim_pago   datetime,
	@o_referencia	    varchar(255)       out	
)
as
declare @w_error           int,
        @w_sp_name         varchar(30),
        @w_param_ISSUER    varchar(20),
		@w_referencia      varchar(64),
		@w_referencia_in   varchar(64),
		@w_referencia_out  varchar(64),
		@w_msg             varchar(255)

select @w_sp_name = 'sp_openpay_gen_ref'

print 'Tipo: '+ @i_tipo_tran
if  @i_tipo_tran <> 'GL'
and @i_tipo_tran <> 'PG'
and @i_tipo_tran <> 'PI'
and @i_tipo_tran <> 'PR'
and @i_tipo_tran <> 'CG'
and @i_tipo_tran <> 'CI' begin
   select @w_error = 70204,
          @w_msg   = 'ERROR: TIPO DE TRANSACCIÓN NO VÁLIDA'
   goto ERROR_FIN
end

--Parametro referencia del corresponsal
select @w_param_ISSUER = pa_char
  from cobis..cl_parametro 
 where pa_nemonico = 'ISSUER' 
   and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
    select @w_error = 724629
    goto ERROR_FIN
end

select @w_referencia_in = rtrim(ltrim(@i_tipo_tran)) + dbo.LlenarI(convert(varchar, @i_id_referencia), '0', 12)


if @i_tipo_tran = 'GL' begin
   select @w_referencia = 
   dbo.CalcularDigitoVerificadorOpenPay (@w_param_ISSUER +
   (replicate('0', 7 - datalength(convert(varchar,@i_id_referencia))) +  convert(varchar,@i_id_referencia)) + 'G' +
   (replicate('0', 2 - datalength(convert(varchar,day(@i_fecha_lim_pago)))) +  convert(varchar,day (@i_fecha_lim_pago))) +
   (replicate('0', 2 - datalength(convert(varchar,month (@i_fecha_lim_pago)))) +  convert(varchar,month (@i_fecha_lim_pago))) +
   substring ( convert(varchar,year (@i_fecha_lim_pago)) ,3 ,datalength(convert(varchar,year (@i_fecha_lim_pago)))) + 
   (replicate('0', 8 - datalength(replace(convert(varchar,@i_monto ),'.','')))) + replace(convert(varchar,@i_monto),'.','')) 
   select @o_referencia = @w_referencia
end
else begin
   select @w_referencia_out = @w_referencia_in + convert(varchar,dbo.fn_base10(@w_referencia_in))
   select @o_referencia = @w_referencia_out
end
print 'referencia: ' +@o_referencia


return 0

ERROR_FIN:

exec cobis..sp_cerror 
    @t_from = @w_sp_name, 
    @i_num  = @w_error, 
    @i_msg  = @w_msg
return @w_error

go
