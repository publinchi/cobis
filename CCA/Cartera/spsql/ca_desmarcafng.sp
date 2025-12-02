/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Jose Rafael Molano                      */
/*      Fecha de escritura:     Agosto 2011                             */
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
/*                                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*                                                                      */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where type = 'P' and name = 'sp_desmarcafng')
   drop proc sp_desmarcafng
go

---INC. 62990 MAY.23.2012 

create proc sp_desmarcafng
as
declare 
@w_fecha_proceso datetime,
@w_msg           varchar(50),
@w_gar_fng       catalogo,
@w_concepto_fng  catalogo,
@w_parametro_iva_fng catalogo


select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

--Parametros generales
select @w_gar_fng  = pa_char
from   cobis..cl_parametro
where  pa_producto = 'GAR'
and    pa_nemonico = 'CODFNG'
set transaction isolation level read uncommitted

select @w_concepto_fng = pa_char   
 from cobis..cl_parametro
where pa_nemonico = 'COMFNG'
and pa_producto = 'CCA'  
set transaction isolation level read uncommitted
  
select @w_parametro_iva_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFNG' 
set transaction isolation level read uncommitted

select 
codigo_externo = cu_codigo_externo,
banco          = op_banco,
valor_gar      = cu_valor_actual,
est_gar        = cu_estado,
admisible      = op_gar_admisible,
operacion      = op_operacion
into #custodia
from cob_cartera..ca_operacion , 
     cob_credito..cr_gar_propuesta, 
     cob_custodia..cu_custodia,
     cob_custodia..cu_tipo_custodia
where op_tramite = gp_tramite
and gp_garantia  = cu_codigo_externo
and cu_tipo  = tc_tipo
and tc_tipo_superior  = @w_gar_fng
and op_banco in (select cf_banco from cob_cartera..ca_recfng_mas where cf_desmarca = 'S')

begin tran

update cob_credito..cr_gar_propuesta set    
gp_est_garantia = 'C'
from   #custodia
where  gp_garantia  = codigo_externo

if @@error <> 0 begin
   rollback tran
   select @w_msg = 'Error en actualizacion cr_gar_propuesta'
   GOTO ERROR
end

update cob_custodia..cu_custodia set    
cu_fecha_modif         = @w_fecha_proceso ,
cu_fecha_modificacion  = @w_fecha_proceso ,
cu_estado              = 'C'
from   #custodia
where  cu_codigo_externo = codigo_externo

if @@error <> 0 begin
   rollback tran
   select @w_msg = 'Error en actualizacion cu_custodia'
   GOTO ERROR
end

update cob_cartera..ca_operacion set    
op_estado_cobranza = cf_est_cob,
op_gar_admisible   = 'N'
from   ca_recfng_mas
where  op_banco = cf_banco

if @@error <> 0 begin
   rollback tran
   select @w_msg = 'Error en actualizacion ca_operacion'
   GOTO ERROR
end

update ca_rubro_op set    
ro_prioridad = 90
from   ca_recfng_mas, ca_operacion
where  ro_concepto  = 'CAP'
and    op_banco     = cf_banco
and    op_operacion = ro_operacion

if @@error <> 0 begin
   rollback tran
   select @w_msg = 'Error en actualizacion ca_rubro_op'
   GOTO ERROR
end

---Poner en 0 la comision para las cuotas futuras que 
---auno la tiene calculada y contabilizada
update ca_amortizacion
set am_cuota = 0
from #custodia,
     ca_amortizacion
where am_operacion =  operacion
and am_concepto in (@w_concepto_fng,@w_parametro_iva_fng)
and am_acumulado = 0
and am_cuota > 0
and am_estado <> 3
if @@error <> 0 begin
   rollback tran
   select @w_msg = 'Error actualizando ca_amortizacion'
   GOTO ERROR
end


delete ca_desmarca_fng_his
where df_fecha = @w_fecha_proceso

if @@error <> 0 begin
   rollback tran
   select @w_msg = 'Error eliminando ca_desmarca_fng_his'
   GOTO ERROR
end

insert into ca_desmarca_fng_his (
df_fecha,           df_aplicativo,     df_banco,          
df_garantia,        df_est_gar_ant,    df_est_gar_nue,    
df_val_ant,         df_val_nue,        df_admisible_ant,  
df_admisible_nue,   df_desmarca,       df_marca
)
select
@w_fecha_proceso,   7,                 banco,             
codigo_externo,     est_gar,           'C',               
valor_gar,          0,                 admisible,         
'N',                'S',               'N'
from #custodia

if @@error <> 0 begin
   rollback tran
   select @w_msg = 'Error Insertando ca_desmarca_fng_his'
   GOTO ERROR
end




commit tran

drop table #custodia

return 0

ERROR:
print @w_msg
return 1
go



