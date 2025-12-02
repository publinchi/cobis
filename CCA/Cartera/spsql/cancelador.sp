/************************************************************************/
/*      Base de datos:           cob_cartera                            */
/*      Producto:                Cartera                                */
/*      Archivo:                 cancelador.sp                          */
/*      Procedimiento:           sp_cancela_operacion                   */
/*      Disenado por:            Elcira Pelaez Burbano                  */
/*      Fecha de escritura:      Nov 2007                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Revisa si la operacion no tiene saldo y la cancela              */
/*                    CAMBIOS                                           */
/*      FECHA         AUTOR         CAMBIO                              */
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_cancela_operacion')
   drop proc sp_cancela_operacion
go


create proc sp_cancela_operacion
@i_fc_fecha_cierre      datetime     = NULL,
@s_date                 datetime     = NULL,
@s_term                 varchar (30) = NULL,
@s_ofi                  smallint     = NULL,
@s_user                 login        = NULL,
@i_tramite              int          = NULL,   
@i_operacionca          int ,
@i_op_naturaleza        char(1),
@i_reconocimiento       char(1) = 'N',
@i_bandera_be           char(1) = 'N',
@i_tipo_cobro           char(1) = 'A',
@i_vlr_despreciable     float,
@i_op_banco             cuenta,
@i_tipo                 char(1)

as
declare
   @w_error                      int,
   @w_estado_act                 smallint,
   @w_saldo_oper                 money,
   @w_rowcount_act               int


exec  sp_calcula_saldo
     @i_operacion = @i_operacionca,
     @i_tipo_pago = @i_tipo_cobro,
     @o_saldo     = @w_saldo_oper out
     
     
--PRINT 'cancelador.sp llego a REVISAR CANCELACION DE  OPERACION  SALDO -----> ' + cast (@w_saldo_oper as varchar)

if @w_saldo_oper > @i_vlr_despreciable
   select  @i_operacionca =  @i_operacionca
ELSE
begin
   update ca_operacion
   set    op_estado = 3
   where  op_operacion = @i_operacionca
   
   update ca_dividendo
   set    di_estado = 3,
          di_fecha_can = @i_fc_fecha_cierre
   where  di_operacion = @i_operacionca
   
   --select @w_rowcount_act = sqlcontext.gettriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN', 'N')
-- EXEC sp_addextendedproperty
--       'CCA_TRIGGER','S',@level0type='Schema',@level0name=dbo,
--       @level1type='Table',@level1name=ca_amortizacion,
--       @level2type='Trigger',@level2name=tg_ca_amortizacion_can
   update ca_amortizacion
   set    am_estado = 3
   where  am_operacion = @i_operacionca
   
   if @@error != 0
   begin
     --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--   EXEC sp_dropextendedproperty
--        'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--        @level1type='Table',@level1name=ca_amortizacion,
--        @level2type='Trigger',@level2name=tg_ca_amortizacion_can
      return 710002
   end
   --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
-- EXEC sp_dropextendedproperty
--        'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--        @level1type='Table',@level1name=ca_amortizacion,
--        @level2type='Trigger',@level2name=tg_ca_amortizacion_can

   if @i_tramite is not null and @i_op_naturaleza = 'A'
   begin
      
      exec @w_error = cob_custodia..sp_activar_garantia
           @i_opcion         = 'C',
           @i_tramite        = @i_tramite,
           @i_modo           = 2,
           @i_operacion      = 'I',
           @s_date           = @s_date,
           @s_user           = @s_user,
           @s_term           = @s_term,
           @s_ofi            = @s_ofi,
           @i_bandera_be     = @i_bandera_be
      
      if @w_error != 0
      begin
         PRINT 'cancelador.sp  salio por error de cob_custodia..sp_activar_garantia  ' + cast(@w_error as varchar)
         while @@trancount > 1
               rollback
         return @w_error
      end
   end
   --ACTUALIZA EL ESTADO DEL PRODUCTO EN CLIENTES
   update cobis..cl_det_producto 
   set dp_estado_ser = 'C'
   where dp_producto = 7 
   and dp_cuenta = @i_op_banco 
end  -- FIN DE CANCELAR TOTALMENTE LA OPERACION


select @w_estado_act =  op_estado
from ca_operacion
where op_operacion = @i_operacionca


if @i_op_naturaleza = 'A' and  @w_estado_act = 3
begin
   update ca_operacion
   set    op_fecha_ult_mov = @i_fc_fecha_cierre
   where  op_operacion = @i_operacionca
   
   insert into ca_activas_canceladas
         (can_operacion,   can_fecha_can,   can_usuario,  can_tipo,   can_fecha_hora)
   values(@i_operacionca,  @i_fc_fecha_cierre, @s_user,  @i_tipo,    getdate() )
end
--- LA SIGUIENTE INSERCION ES PARA EL MANEJO DE CREACION DE OBLIGACIONES AL TERNAS
--- LAS CUALES NECERAN A PARTIR DE ESTA  TABLA

return 0
go