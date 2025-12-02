/************************************************************************/
/*      Archivo:                hmrestar.sp                             */
/*      Stored procedure:       sp_restaurar                            */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     AGOSTO. 2004                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Sacar de la base de datos cob_cartera_his y pasar a la base de  */
/*      datos cob_acrtea                                                */
/************************************************************************/  
/*                             ACTUALIZACIONES                          */
/*                                                                      */
/*   FECHA        AUTOR           CAMBIO                                */
/*   May-2005     Elcira Pelaez   restaurar de base datos depu          */
/*                                racion y retornar mensaje             */
/*                                solo si es en linea                   */
/*   09/AGO/2005  Elcira Pelaez   No recuperar historia de la tabla de  */
/*                                capitalizaziones ca_acciones          */
/*   10/OCT/2005  FDO CARVAJAL    DIFERIDOS REQ 389                     */
/*   10/NOV/2005  Elcira Pelaez   Recuperar tabla Documenos descontados */
/*   22/Nov/2005  Ivan Jimenez    REQ 379 Traslado de Intereses         */
/*   Jun 2006     Fabian Quintero Optimizacion. paso de transacciones   */
/*   May 2007     Fabian Quintero Defecto      8236                     */
/*   Oct 2007     Elcira Pelaez   Quitar tabla ca_ultima_tasa_op        */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_fecha_restauracion')
   drop table ca_fecha_restauracion
go

if exists (select 1 from sysobjects where name = 'sp_restaurar')
   drop proc sp_restaurar
go

create proc sp_restaurar
   @i_banco      cuenta,
   @i_en_linea   char(1) = 'S' -- ESTE PROGRAMA SIEMPRE DEBE SER EXTERNO Y TENER SU PROPIA TRANSACCION
                               -- ESTE PARAMETRO ES SOLO POR MOSTRAR EL MENSAJE
as
declare 
   @w_operacion      int,
   @w_estado         int,
   @w_rowcount_act   int,
   @w_error          int

begin
   select @w_operacion = op_operacion,
          @w_estado    = op_estado
   from   ca_operacion
   where  op_banco = @i_banco
   
   BEGIN TRAN
   
   -- REGISTRAR
   delete ca_historia_tran
   where  ht_operacion = @w_operacion
   and    ht_lugar = 1
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrado de ca_historia_tran'
      return 1
   end
   
   -- RECUPERAR
   --select @w_rowcount_act = sqlcontext.gettriggercontext ('CCA_TRIGGER', 'TRANSACCION_PAS', 'N')
--   EXEC sp_addextendedproperty
--        'CCA_TRIGGER','S',@level0type='Schema',@level0name=dbo,
--         @level1type='Table',@level1name=ca_amortizacion,
--         @level2type='Trigger',@level2name=tg_ca_amortizacion_can

   insert into cob_cartera..ca_transaccion
   select *
   from   cob_cartera_his..ca_transaccion
   where  tr_operacion = @w_operacion
   
   select @w_error = @@error
   
   --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'TRANSACCION_PAS')
--   EXEC sp_dropextendedproperty
--          'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--          @level1type='Table',@level1name=ca_amortizacion,
--          @level2type='Trigger',@level2name=tg_ca_amortizacion_can
   if @w_error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos basicos de transaccion'
      return 1
   end
   
   insert into cob_cartera..ca_det_trn
   select *
   from   cob_cartera_his..ca_det_trn
   where  dtr_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos basicos de transaccion'
      return 1
   end
   
   insert into cob_cartera..ca_operacion_his
   select *
   from   cob_cartera_his..ca_operacion_his
   where  oph_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando detalle de transacciones'
      return 1
   end
   
   insert into cob_cartera..ca_rubro_op_his
   select *
   from   cob_cartera_his..ca_rubro_op_his
   where  roh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos de conceptos'
      return 1
   end
   
   insert into cob_cartera..ca_dividendo_his
   select *
   from   cob_cartera_his..ca_dividendo_his
   where  dih_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos de cuotas'
      return 1
   end
   
   insert into cob_cartera..ca_amortizacion_his
   select *
   from   cob_cartera_his..ca_amortizacion_his
   where  amh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos de tabla de amortizacion'
      return 1
   end
   
   insert into cob_cartera..ca_cuota_adicional_his
   select *
   from   cob_cartera_his..ca_cuota_adicional_his
   where  cah_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos cuotas adicionales'
      return 1
   end
      
   insert into cob_cartera..ca_correccion_his
   select *
   from   cob_cartera_his..ca_correccion_his
   where  coh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos de correccion monetaria'
      return 1
   end
   
   insert into cob_cartera..ca_valores_his
   select *
   from   cob_cartera_his..ca_valores_his
   where  vah_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos de otros valores'
      return 1
   end
   
   -- INICIO FCP 10/OCT/2005 - REQ 389
   insert into cob_cartera..ca_diferidos_his 
   (difh_secuencial, difh_operacion, difh_valor_diferido, difh_valor_pagado, difh_concepto)
   select difh_secuencial, difh_operacion, 0, difh_valor_pagado, difh_concepto
   from   cob_cartera_his..ca_diferidos_his
   where  difh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos de diferidos'
      return 1
   end
   -- FIN FCP 10/OCT/2005 - REQ 389
   
   insert into cob_cartera..ca_facturas_his
   select *
   from   cob_cartera_his..ca_facturas_his
   where  fach_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos de facturas'
      return 1
   end

   -- INICIO REQ 379 IFJ 22/Nov/2005
   insert cob_cartera..ca_traslado_interes_his
   select *
   from  cob_cartera_his..ca_traslado_interes_his
   where tih_operacion  = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en insertando datos de traslado de intereses'
      return 1
   end
   -- FIN REQ 379 IFJ 22/Nov/2005
   
   
   -- BORRAR
   delete cob_cartera_his..ca_transaccion
   where  tr_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrando datos basicos de transacciones'
      return 1
   end
   
   delete cob_cartera_his..ca_det_trn
   where  dtr_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrando detalle de transacciones'
      return 1
   end
   
   delete cob_cartera_his..ca_operacion_his
   where  oph_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrando datos basicos'
      return 1
   end
   
   delete cob_cartera_his..ca_rubro_op_his
   where  roh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrando datos de conceptos'
      return 1
   end
   
   delete cob_cartera_his..ca_dividendo_his
   where  dih_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrando datos de cuotas'
      return 1
   end
   
   delete cob_cartera_his..ca_amortizacion_his
   where  amh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrando datos de tabla de amortizacion'
      return 1
   end
   
   delete cob_cartera_his..ca_cuota_adicional_his
   where  cah_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrando datos de cuotas adicionales'
      return 1
   end
   
   delete cob_cartera_his..ca_correccion_his
   where  coh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrando datos de correccion monetaria'
      return 1
   end
   
   delete cob_cartera_his..ca_valores_his
   where  vah_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error en borrando datos de otros valores'
      return 1
   end
   
   -- INICIO FCP 10/OCT/2005 - REQ 389
   delete cob_cartera_his..ca_diferidos_his
   where  difh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error borrando datos de diferidos'
      return 1
   end
   -- FIN FCP 10/OCT/2005 - REQ 389
   
   delete cob_cartera_his..ca_facturas_his
   where  fach_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error borrando de datos de facturas'
      return 1
   end
   
   -- INICIO REQ 379 IFJ 22/Nov/2005
   delete cob_cartera_his..ca_traslado_interes_his
   where  tih_operacion  = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print 'Error borrando de traslado de intereses'
      return 1
   end
   -- FIN REQ 379 IFJ 22/Nov/2005

/* No existe la instancia RRB

   --------------- AHORA DE COB_CARTERA DEPURACION
   -- REGISTRAR
   delete ca_historia_tran
   where  ht_operacion = @w_operacion
   and    ht_lugar = 2
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando datos de ca_historia_tran'
      return 1
   end
   
   -- RECUPERAR
   -- select @w_rowcount_act = sqlcontext.gettriggercontext ('CCA_TRIGGER', 'TRANSACCION_PAS', 'N')
--   EXEC sp_addextendedproperty
--         'CCA_TRIGGER','S',@level0type='Schema',@level0name=dbo,
--         @level1type='Table',@level1name=ca_amortizacion,
--         @level2type='Trigger',@level2name=tg_ca_amortizacion_can
   insert into cob_cartera..ca_transaccion
   select *
   from   cob_cartera_depuracion..ca_transaccion
   where  tr_operacion = @w_operacion
   
   select @w_error = @@error
   
   --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'TRANSACCION_PAS')
--   EXEC sp_dropextendedproperty
--          'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--          @level1type='Table',@level1name=ca_amortizacion,
--          @level2type='Trigger',@level2name=tg_ca_amortizacion_can
   
   if @w_error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando transacciones'
      return 1
   end
   
   insert into cob_cartera..ca_det_trn
   select *
   from   cob_cartera_depuracion..ca_det_trn
   where  dtr_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando detalle de transacciones'
      return 1
   end
   
   insert into cob_cartera..ca_operacion_his
   select *
   from   cob_cartera_depuracion..ca_operacion_his
   where  oph_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos basicos'
      return 1
   end
   
   insert into cob_cartera..ca_rubro_op_his
   select *
   from   cob_cartera_depuracion..ca_rubro_op_his
   where  roh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos de conceptos'
      return 1
   end
   
   insert into cob_cartera..ca_dividendo_his
   select *
   from   cob_cartera_depuracion..ca_dividendo_his
   where  dih_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos de cuotas'
      return 1
   end
   
   insert into cob_cartera..ca_amortizacion_his
   select *
   from   cob_cartera_depuracion..ca_amortizacion_his
   where  amh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos de tabla de amortizacion'
      return 1
   end
   
   insert into cob_cartera..ca_cuota_adicional_his
   select *
   from   cob_cartera_depuracion..ca_cuota_adicional_his
   where  cah_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos de cuotas adicionales'
      return 1
   end
   
   ---134 
   
   insert into cob_cartera..ca_correccion_his
   select *
   from   cob_cartera_depuracion..ca_correccion_his
   where  coh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos de correccion monetaria'
      return 1
   end
   
   insert into cob_cartera..ca_valores_his
   select *
   from   cob_cartera_depuracion..ca_valores_his
   where  vah_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos otros valores'
      return 1
   end
   
   ---141

   -- INICIO FCP 10/OCT/2005 - REQ 389
   insert into cob_cartera..ca_diferidos_his
   select *
   from   cob_cartera_depuracion..ca_diferidos_his
   where  difh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos de diferidos'
      return 1
   end
   -- FIN FCP 10/OCT/2005 - REQ 389
   
   insert into cob_cartera..ca_facturas_his
   select *
   from   cob_cartera_depuracion..ca_facturas_his
   where  fach_operacion = @w_operacion
   
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos de facturas'
      return 1
   end

   -- INICIO REQ 379 IFJ 22/Nov/2005
   insert cob_cartera..ca_traslado_interes_his
   select *
   from  cob_cartera_depuracion..ca_traslado_interes_his
   where tih_operacion  = @w_operacion
   
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en insertando datos de traslado de intereses'
      return 1
   end
   -- FIN REQ 379 IFJ 22/Nov/2005

   
   -- BORRAR
   delete cob_cartera_depuracion..ca_transaccion
   where  tr_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando transacciones'
      return 1
   end
   
   delete cob_cartera_depuracion..ca_det_trn
   where  dtr_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando detalle de transacciones'
      return 1
   end
   
   delete cob_cartera_depuracion..ca_operacion_his
   where  oph_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando datos basicos'
      return 1
   end
   
   delete cob_cartera_depuracion..ca_rubro_op_his
   where  roh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando conceptos'
      return 1
   end
   
   delete cob_cartera_depuracion..ca_dividendo_his
   where  dih_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando cuotas'
      return 1
   end
   
   delete cob_cartera_depuracion..ca_amortizacion_his
   where  amh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando tabla de amortizacion'
      return 1
   end
   
   ---158
   
   delete cob_cartera_depuracion..ca_cuota_adicional_his
   where  cah_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando cuotas adicionales'
      return 1
   end
   
   delete cob_cartera_depuracion..ca_correccion_his
   where  coh_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando correccion monetaria'
      return 1
   end
   
   delete cob_cartera_depuracion..ca_valores_his
   where  vah_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error en borrando otros valores'
      return 1
   end
   
   -- INICIO FCP 10/OCT/2005 - REQ 389
   delete cob_cartera_depuracion..ca_diferidos_his
   where  difh_operacion = @w_operacion   
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error borrando diferidos'
      return 1
   end   
   -- FIN FCP 10/OCT/2005 - REQ 389
   
   delete cob_cartera_depuracion..ca_facturas_his
   where  fach_operacion = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error borrando facturas'
      return 1
   end   
   
   -- INICIO REQ 379 IFJ 22/Nov/2005
   delete cob_cartera_depuracion..ca_traslado_interes_his
   where  tih_operacion  = @w_operacion
   if @@error != 0
   begin
      ROLLBACK
      print '(dep)Error borrando de traslado de intereses'
      return 1
   end
   -- FIN REQ 379 IFJ 22/Nov/2005


 No existe la instancia RRB */

   COMMIT
   
   if @i_en_linea = 'S'
      select  'Ok!!!   Recuperado'
   
   return 0
end
go
