/************************************************************************/
/*   Archivo:             abonomas.sp                                   */
/*   Stored procedure:    sp_abono_masivo                               */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        RRB                                           */
/*   Fecha de escritura:  May 09                                        */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Aplicacion de pagos antes de cierre fin dia batch                  */
/*   cartera.                                                           */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_abono_masivo')
   drop proc sp_abono_masivo
go

CREATE proc sp_abono_masivo
   @s_user              varchar(14)   = null,
   @s_term              varchar(30)   = null,
   @s_date              datetime      = null,
   @s_ofi               smallint      = null
as declare              
   @w_error             int,
   @w_return            int,
   @w_sp_name           varchar(64),
   @w_detener_proceso   char(1),
   @w_operacionca       int,
   @w_fecha_pago        datetime,
   @w_banco             cuenta,
   @w_op_moneda         tinyint,
   @w_moneda_nacional   tinyint,
   @w_cotizacion_hoy    money,
   @w_rowcount          int,
   @w_dias_fecha_val    tinyint,
   @w_ab_secuencial     int,
   @w_op_operacion      int,
   @w_ab_secuencial_ing int,
   @w_est_novigente     tinyint,
   @w_est_cancelado     tinyint,
   @w_est_credito       tinyint,
   @w_est_anulado       tinyint,   
   @w_fecha_op_proceso  datetime
   
    
/* CARGADO DE VARIABLES DE TRABAJO */
select 
@w_sp_name           = 'sp_abono_masivo',
@s_user              = isnull(@s_user, suser_name()),
@s_term              = isnull(@s_term, 'BATCH_CARTERA'),
@s_ofi               = isnull(@s_ofi , 1),
@w_detener_proceso   = 'N',
@w_ab_secuencial_ing = 0,
@w_op_operacion      = 0

/* MONEDA NACIONAL */
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount

--PARAMETRO DIAS FECHA VALOR
select @w_dias_fecha_val = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DFVR'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_credito    = @w_est_credito   out

select @s_date = convert(varchar(10),fc_fecha_cierre,101)
from cobis..ba_fecha_cierre with (nolock)
where fc_producto = 7
 
while @w_detener_proceso = 'N' begin

   set rowcount 1
   select             
   @w_operacionca        = ab_operacion,
   @w_fecha_pago         = ab_fecha_pag,
   @w_banco              = op_banco,
   @w_op_moneda          = op_moneda,
   @w_ab_secuencial      = ab_secuencial_ing,
   @w_fecha_op_proceso   = op_fecha_ult_proceso
   from ca_abono with (nolock), ca_operacion with (nolock)
   where ab_estado in ('ING', 'NA')
   and ab_operacion      = op_operacion
   and op_operacion in (897 , 54758 , 1287, 4080 , 889 , 54775, 54702 , 54778)
   and op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_credito,@w_est_anulado)
   order by op_operacion , ab_secuencial_ing
   
   if @@rowcount = 0 begin
      set rowcount 0
      print 'FIN'
      break
   end
   
   set rowcount 0
   
   -- Validacion pago en fecha posterior a la de proceso del modulo o inferior a N dias
   if datediff(dd, @s_date , @w_fecha_pago) < (@w_dias_fecha_val * -1) or 
      datediff(dd, @s_date , @w_fecha_pago) > 0 begin
      select @w_error = 724517
      goto ERROR
   end   
   
   -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
   if @w_op_moneda = @w_moneda_nacional begin
      select @w_cotizacion_hoy = 1.0
   end else begin
      exec sp_buscar_cotizacion
      @i_moneda     = @w_op_moneda,
      @i_fecha      = @w_fecha_pago,
      @o_cotizacion = @w_cotizacion_hoy output
   end   

   if datediff(dd, @w_fecha_op_proceso , @w_fecha_pago) <> 0 begin
      exec @w_return = sp_fecha_valor 
      @s_date              = @s_date,
      @s_user              = @s_user,
      @s_term              = @s_term,
      @i_fecha_valor       = @w_fecha_pago,
      @i_banco             = @w_banco,
      @i_operacion         = 'F',
      @i_observacion       = 'Recaudo',
      @i_observacion_corto = 'Recaudo',
      @i_en_linea          = 'N'
      
      if @w_return != 0 begin
         select @w_error =  @w_return
         goto ERROR
      end                 
   end

   exec @w_return = sp_abonos_batch
   @s_user          = @s_user,
   @s_term          = @s_term,
   @s_date          = @s_date,
   @s_ofi           = @s_ofi,
   @i_en_linea      = 'N',
   @i_fecha_proceso = @w_fecha_pago,
   @i_operacionca   = @w_operacionca,
   @i_banco         = @w_banco,
   @i_pry_pago      = 'N',
   @i_cotizacion    = @w_cotizacion_hoy
   
   if @w_return != 0 begin
      select @w_error =  @w_return
      goto ERROR
   end
   
   goto SIGUIENTE
   
   ERROR:
   while @@trancount > 0 rollback
   exec sp_errorlog 
   @i_fecha      = @s_date,
   @i_error      = @w_error, 
   @i_usuario    = @s_user, 
   @i_tran       = 7999,
   @i_tran_name  = @w_sp_name,
   @i_cuenta     = @w_banco,
   @i_rollback  = 'S' 
   
   update ca_abono
   set ab_estado = 'E'
   where ab_operacion      = @w_operacionca
   and   ab_secuencial_ing = @w_ab_secuencial
   
   SIGUIENTE:

end
  
return 0
 
go
