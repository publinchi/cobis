
/************************************************************************/
/*      Archivo:                borratcca.sp                            */
/*      Stored procedure:       sp_borra_tablas_cca                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Ene. 1998                               */
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
/*      Eliminación de Datos de Cartera.                                */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_borra_tablas_cca')
   drop proc sp_borra_tablas_cca
go


create proc sp_borra_tablas_cca (
       @s_ssn                 int         = null,
       @s_sesn                int         = null,
       @s_date                datetime    = null,
       @s_ofi                 smallint    = null,
       @s_user                login       = null,
       @s_term                varchar(30) = null,
       @s_srv                 varchar(30) = null,
       @i_banco               cuenta, 
       @i_operacionca         int
)
as

declare @w_sp_name           descripcion

   select @w_sp_name = 'sp_borra_tablas_cca'

   if @i_banco is null
      select  @i_banco = op_banco
        from ca_operacion
      where op_operacion = @i_operacionca

   delete ca_amortizacion
   where am_operacion = @i_operacionca
   if @@error != 0  return 707023

   delete ca_rubro_op
    where ro_operacion = @i_operacionca 
   if @@error != 0  return 707003

   delete ca_dividendo
    where di_operacion = @i_operacionca 
   if @@error != 0  return 707054

   delete ca_cuota_adicional
    where ca_operacion = @i_operacionca 
   if @@error != 0  return 705062

   delete ca_diferir_fecha
    where df_operacion = @i_operacionca
   if @@error != 0 return 705062

   delete ca_tasas
    where ts_operacion = @i_operacionca 
   if @@error != 0  return 710003

 
   delete ca_reajuste_det
    where red_operacion = @i_operacionca
   if @@error != 0  return 710043

   delete ca_reajuste
    where re_operacion = @i_operacionca 
   if @@error != 0  return 710042

   delete ca_operacion
    where op_operacion = @i_operacionca
   if @@error != 0  return 707007

   delete ca_det_trn
    where dtr_operacion = @i_operacionca
   if @@error != 0  return 708155

   delete ca_transaccion
    where tr_operacion = @i_operacionca
   if @@error != 0  return  707013

   delete ca_desembolso
    where dm_operacion = @i_operacionca
   if @@error != 0  return 707044

   delete ca_relacion_ptmo
    where rp_activa = @i_operacionca

   if @@error != 0  return 707070

   delete cob_cartera..ca_abono
    where ab_operacion = @i_operacionca
   
   delete cob_cartera..ca_abono_det
    where abd_operacion = @i_operacionca
   
   delete cob_cartera..ca_abono_prioridad
    where ap_operacion = @i_operacionca

   delete cob_cartera..ca_abono_prioridad
    where ap_operacion = @i_operacionca

   
 delete cobis..cl_cliente
     from cobis..cl_det_producto
    where cl_det_producto = dp_det_producto
      and dp_producto = 7
      and dp_cuenta = @i_banco

    delete cobis..cl_det_producto 
     where dp_cuenta   = @i_banco
       and dp_producto =  7

    delete ca_otro_cargo where oc_operacion = @i_operacionca
    if @@error != 0  return 710003

    delete ca_operacion_his where oph_operacion = @i_operacionca
    if @@error != 0  return 710003

    delete ca_dividendo_his where dih_operacion = @i_operacionca
    if @@error != 0  return 707059

    delete ca_amortizacion_his where amh_operacion = @i_operacionca
    if @@error != 0  return 707057

    delete ca_rubro_op_his     where roh_operacion = @i_operacionca
    if @@error != 0  return 707058

 
    delete ca_venta_relacion where vr_operacion_vta = @i_operacionca
    if @@error != 0  return 701161

    delete ca_venta_comision where vm_operacion = @i_operacionca
    if @@error != 0  return 708155

    delete ca_venta_cartera  where vc_operacion =  @i_operacionca
    if @@error != 0  return 707058

    delete ca_venta_transaccion  where vt_operacion_vta = @i_operacionca
    if @@error != 0  return 710144


    delete ca_pago_automatico  where pa_operacion = @i_operacionca
    if @@error != 0  return 710216

return 0

go

