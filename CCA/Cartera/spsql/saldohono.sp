/************************************************************************/
/*   Archivo              :    saldohono.sp                             */
/*   Stored procedure     :    sp_saldo_honorarios                      */
/*   Base de datos        :    cob_cartera                              */
/*   Producto             :    Cartera                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                               PROPOSITO                              */
/*   Retorna el saldo de cancelación incluido honorarios                */
/************************************************************************/
/*                              ACTUALIZACIONES                         */
/*      FECHA               AUTOR            CAMBIO                     */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldo_honorarios' and type = 'P')
   drop proc sp_saldo_honorarios
go

create proc sp_saldo_honorarios
@i_banco                cuenta,
@i_saldo_cap            money   = null,
@i_num_dec              tinyint = null,
@o_saldo_tot            money   = null out,
@o_saldo_hon            money   = null out,
@o_saldo_iva            money   = null out

as
declare
@w_return               int,
@w_est_cancelado        tinyint,
@w_operacionca          int,
@w_abogado              catalogo,
@w_estado_cobranza      catalogo,
@w_total_honabo         money,
@w_regimen              char(1),
@w_porc_juridico        float,
@w_monto_base           money,
@w_monto_honabo         money,
@w_monto_iva            money,
@w_porc_prejuridico     float,
@w_iva                  float,
@w_num_dec              tinyint,
@w_moneda_op            smallint,
@w_saldo_cap            money,
@w_op_fecha_fin         datetime,
@w_op_fecha_ult_proceso datetime,
@w_estado_op            int,
-- INI JAR REQ 230
@w_porc_honorarios      float,
@w_porc_tarifa          money,
@w_factor               float
-- FIN JAR REQ 230
                 
/* ESTADOS DE CARTERA */
exec @w_return = cob_cartera..sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out

if @w_return <> 0
   return @w_return	

select
@w_operacionca          = op_operacion,
@w_moneda_op            = op_moneda,
@w_estado_cobranza      = op_estado_cobranza,
@w_op_fecha_fin         = op_fecha_fin,
@w_op_fecha_ult_proceso = op_fecha_ult_proceso,
@w_estado_op            = op_estado
from   ca_operacion
where  op_banco = @i_banco

if @@rowcount = 0 return 701025

/*

if @w_estado_cobranza not in ('CP', 'CJ') and isnull(@i_saldo_cap,0) > 0
begin
   select @o_saldo_tot = isnull(@i_saldo_cap,0)
   return 0
end
*/

if @i_num_dec is null
begin
   --- DECIMALES
   exec @w_return = sp_decimales
   @i_moneda      = @w_moneda_op,
   @o_decimales   = @w_num_dec out

   if @w_return <> 0
      return @w_return
end
else
   select @w_num_dec = @i_num_dec

if @i_saldo_cap is null
begin
   --- CONSULTA SALDO DE CANCELACION
   exec @w_return = sp_calcula_saldo
   @i_operacion   = @w_operacionca,
   @i_tipo_pago   = 'A',
   @o_saldo       = @w_saldo_cap out

   if @w_return <> 0
      return @w_return
end
else
   select @w_saldo_cap = @i_saldo_cap

select @w_total_honabo = 0
    
if exists (select 1 from cob_credito..cr_hono_mora   -- INI JAR REQ 230
            where hm_estado_cobranza = @w_estado_cobranza)
begin
   /* Clase de regimen del Abogado */
   select @w_abogado = isnull(isnull(co_abogado, co_ab_interno),'0')
   from   cob_credito..cr_operacion_cobranza, cob_credito..cr_cobranza
   where  oc_num_operacion = @i_banco
   and    co_cobranza      = oc_cobranza
   and    isnumeric(isnull(co_abogado,'0')) = 1
   
   if @@rowcount = 0 or @w_abogado = '0' return 711077
   
   select @w_regimen = rf_autorretenedor
   from   cobis..cl_ente, cob_conta..cb_regimen_fiscal, cob_credito..cr_abogado
   where  en_ente      = ab_abogado
   and    en_asosciada = rf_codigo
   and    ab_abogado   = @w_abogado
   
   if @@rowcount = 0 return 711078
   
   select @w_iva = pa_float
   from   cobis..cl_parametro with (nolock)
   where  pa_nemonico = 'PIVA'
   and    pa_producto = 'CTE'
   
   -- INI JAR REQ 230
   exec @w_return = sp_hon_abo
      @i_banco      = @i_banco,
      @i_abogado    = @w_abogado,
      @i_estado_cob = @w_estado_cobranza,
      @o_porcentaje = @w_porc_honorarios  out,
      @o_tarifa     = @w_porc_tarifa      out
   
   if @w_return <> 0 return @w_return
   
   --El calculo de los honorarios no debe tener en cuenta el factor para calcular la base.
   if @w_porc_honorarios is not null begin     
      
      select @w_monto_base =  @w_saldo_cap 
      select @w_monto_honabo = round((@w_monto_base*@w_porc_honorarios/100),@w_num_dec)
   end
   
   if @w_porc_tarifa is not null
      select @w_monto_honabo = @w_porc_tarifa
   -- FIN JAR REQ 230
    
   if @w_regimen = 'S' 
      select @w_monto_iva = round((@w_monto_honabo*@w_iva/100),@w_num_dec)
   else
      select @w_monto_iva = 0
     
   select @w_total_honabo = isnull(sum(@w_monto_honabo + @w_monto_iva),0)
end   -- if exists
-- FIN JAR REQ 230

select @w_saldo_cap = isnull(@w_saldo_cap,0) + isnull(@w_total_honabo,0)
       
select @o_saldo_tot = isnull(@w_saldo_cap, 0),
       @o_saldo_hon = isnull(@w_monto_honabo, 0),
       @o_saldo_iva = isnull(@w_monto_iva, 0)

return 0
go

