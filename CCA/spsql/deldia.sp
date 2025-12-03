/************************************************************************/
/*   NOMBRE LOGICO:      deldia.sp                                      */
/*   NOMBRE FISICO:      sp_deldia                                      */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Veronica Brown                                 */
/*   FECHA DE ESCRITURA: 01/10/1998                                     */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Ejecuta los procedimientos de eliminacion para inicio de dia    */
/************************************************************************/
/*                              ACTUALIZACIONES                         */
/*      NOV-29-2006    EPB               def. 7524 limpiar fec-valmasivo*/  
/*      JUL-01-2019    LRE               S250610 Limpiar tablas de inter*/
/*                                       face                           */
/*      JUL-22-2019    AGI               S268895 Limpiar tabla incentivo*/
/*      Nov-16-2020    PNA               Limpia tablas reestructuras    */
/*      Ene-12-2022    GFP            Limpia tabla datos adicionales tmp*/
/*      Mar-07-2023    KDR            Vaciar tabla tmp de consultas de  */
/*                                    transacciones                     */
/*      Jul-03-2023    GFP            Ingreso de ca_en_fecha_valor_grupal */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_deldia')
   drop proc sp_deldia
go

create proc sp_deldia 

as


--NOTA: el partition  se puede hacer a tablas  si estas tienen indices nonclustered 

--PRINT 'deldia.sp  va  ca_abono_prioridad_tmp'

/*
if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_abono_prioridad_tmp')
begin
   alter table ca_abono_prioridad_tmp unpartition
end
   truncate table ca_abono_prioridad_tmp
   --alter table ca_abono_prioridad_tmp partition  200
   update statistics ca_abono_prioridad_tmp 
   exec sp_recompile ca_abono_prioridad_tmp

--PRINT 'deldia.sp  va  ca_amortizacion_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_amortizacion_tmp')
begin
   alter table ca_amortizacion_tmp unpartition
end
   truncate table ca_amortizacion_tmp
   --alter table ca_amortizacion_tmp partition  200
   update statistics ca_amortizacion_tmp 
   exec sp_recompile ca_amortizacion_tmp 

PRINT 'deldia.sp  va  ca_cliente_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_cliente_tmp')
begin
   alter table ca_cliente_tmp unpartition
end
   truncate table ca_cliente_tmp
   --alter table ca_cliente_tmp partition  200
   update statistics ca_cliente_tmp 
   exec sp_recompile ca_cliente_tmp 
   
PRINT 'deldia.sp  va  ca_cuota_adicional_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_cuota_adicional_tmp')
begin
   alter table ca_cuota_adicional_tmp unpartition
end
   truncate table ca_cuota_adicional_tmp
  -- alter table ca_cuota_adicional_tmp partition  200
   update statistics ca_cuota_adicional_tmp 
   exec sp_recompile ca_cuota_adicional_tmp 
   
PRINT 'deldia.sp  va  ca_dividendo_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_dividendo_tmp')
begin
   alter table ca_dividendo_tmp unpartition
end
   truncate table ca_dividendo_tmp
  -- alter table ca_dividendo_tmp partition  200
   update statistics ca_dividendo_tmp 
   exec sp_recompile ca_dividendo_tmp 

PRINT 'deldia.sp  va  ca_dividendo_original_tmp               '

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_dividendo_original_tmp')
begin
   alter table ca_dividendo_original_tmp unpartition
end
   truncate table ca_dividendo_original_tmp
   --alter table ca_dividendo_original_tmp partition  200
   update statistics ca_dividendo_original_tmp 
   exec sp_recompile ca_dividendo_original_tmp 
   
PRINT 'deldia.sp  va  ca_operacion_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_operacion_tmp')
begin
   alter table ca_operacion_tmp unpartition
end
   truncate table ca_operacion_tmp
  -- alter table ca_operacion_tmp partition  200
   update statistics ca_operacion_tmp 
   exec sp_recompile ca_operacion_tmp 
   
PRINT 'deldia.sp  va  ca_relacion_ptmo_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_relacion_ptmo_tmp')
begin
   alter table ca_relacion_ptmo_tmp unpartition
end
   truncate table ca_relacion_ptmo_tmp
 --  alter table ca_relacion_ptmo_tmp partition  200
   update statistics ca_relacion_ptmo_tmp 
   exec sp_recompile ca_relacion_ptmo_tmp 

PRINT 'deldia.sp  va  ca_rubro_op_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_rubro_op_tmp')
begin
   alter table ca_rubro_op_tmp unpartition
end
   truncate table ca_rubro_op_tmp
  -- alter table ca_rubro_op_tmp partition  200
   update statistics ca_rubro_op_tmp 
   exec sp_recompile ca_rubro_op_tmp 

-- Tablas de Trabajo

PRINT 'deldia.sp  va  ca_detalle_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_detalle_tmp')
begin
   alter table ca_detalle_tmp unpartition
end
   truncate table ca_detalle_tmp
 --  alter table ca_detalle_tmp partition  200
   update statistics ca_detalle_tmp 
   exec sp_recompile ca_detalle_tmp 

PRINT 'deldia.sp  va  ca_saldos_contables_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_saldos_contables_tmp')
begin
   alter table ca_saldos_contables_tmp unpartition
end
   truncate table ca_saldos_contables_tmp
   --alter table ca_saldos_contables_tmp partition  200
   update statistics ca_saldos_contables_tmp 
   exec sp_recompile ca_saldos_contables_tmp 
   
PRINT 'deldia.sp  va  ca_rubro_calculado_tmp '

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_rubro_calculado_tmp')
begin
   alter table ca_rubro_calculado_tmp unpartition
end
   truncate table ca_rubro_calculado_tmp
 --  alter table ca_rubro_calculado_tmp partition  200
   update statistics ca_rubro_calculado_tmp 
   exec sp_recompile ca_rubro_calculado_tmp 

PRINT 'deldia.sp  va  ca_prestamo_pagos_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_prestamo_pagos_tmp')
begin
   alter table ca_prestamo_pagos_tmp unpartition
end
   truncate table ca_prestamo_pagos_tmp
  -- alter table ca_prestamo_pagos_tmp partition  200
   update statistics ca_prestamo_pagos_tmp
   exec sp_recompile ca_prestamo_pagos_tmp
   
PRINT 'deldia.sp  va  ca_rubro_imo_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_rubro_imo_tmp')
begin
   alter table ca_rubro_imo_tmp unpartition
end
   truncate table ca_rubro_imo_tmp
  -- alter table ca_rubro_imo_tmp partition  200
   update statistics ca_rubro_imo_tmp
   exec sp_recompile ca_rubro_imo_tmp

PRINT 'deldia.sp  va  ca_rubro_int_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_rubro_int_tmp')
begin
   alter table ca_rubro_int_tmp unpartition
end
   truncate table ca_rubro_int_tmp
 --  alter table ca_rubro_int_tmp partition  200
   update statistics ca_rubro_int_tmp
   exec sp_recompile ca_rubro_int_tmp

PRINT 'deldia.sp  va  ca_relacion_ptmo_pago_temp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_relacion_ptmo_pago_temp')
begin
   alter table ca_relacion_ptmo_pago_temp unpartition
end
   truncate table ca_relacion_ptmo_pago_temp
  -- alter table ca_relacion_ptmo_pago_temp partition  200
   update statistics ca_relacion_ptmo_pago_temp
   exec sp_recompile ca_relacion_ptmo_pago_temp

PRINT 'deldia.sp  va  ca_interes_proyectado_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_interes_proyectado_tmp')
begin
   alter table ca_interes_proyectado_tmp unpartition
end
   truncate table ca_interes_proyectado_tmp
  -- alter table ca_interes_proyectado_tmp partition  200
   update statistics ca_interes_proyectado_tmp
   exec sp_recompile ca_interes_proyectado_tmp

PRINT 'deldia.sp  va  ca_total_prioridad_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_total_prioridad_tmp')
begin
   alter table ca_total_prioridad_tmp unpartition
end
   truncate table ca_total_prioridad_tmp
  -- alter table ca_total_prioridad_tmp partition  200
   update statistics ca_total_prioridad_tmp
   exec sp_recompile ca_total_prioridad_tmp
   
PRINT 'deldia.sp  va  ca_consutar_transacciones_tmp1'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_consutar_transacciones_tmp1')
begin
   alter table ca_consutar_transacciones_tmp1 unpartition
end
   truncate table ca_consutar_transacciones_tmp1
 --  alter table ca_consutar_transacciones_tmp1 partition  200
   update statistics ca_consutar_transacciones_tmp1
   exec sp_recompile ca_consutar_transacciones_tmp1
   
PRINT 'deldia.sp  va  ca_consutar_transacciones_tmp2'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_consutar_transacciones_tmp2')
begin
   alter table ca_consutar_transacciones_tmp2 unpartition
end
   truncate table ca_consutar_transacciones_tmp2
  -- alter table ca_consutar_transacciones_tmp2 partition  200
   update statistics ca_consutar_transacciones_tmp2
   exec sp_recompile ca_consutar_transacciones_tmp2

PRINT 'deldia.sp  va  ca_cursor_dividendo_temp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_cursor_dividendo_temp')
begin
   alter table ca_cursor_dividendo_temp unpartition
end
   truncate table ca_cursor_dividendo_temp
  -- alter table ca_cursor_dividendo_temp partition  200
   update statistics ca_cursor_dividendo_temp
   exec sp_recompile ca_cursor_dividendo_temp
   
PRINT 'deldia.sp  va  ca_cursor_dividendo_ru_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_cursor_dividendo_ru_tmp')
begin
   alter table ca_cursor_dividendo_ru_tmp unpartition
end
   truncate table ca_cursor_dividendo_ru_tmp
  -- alter table ca_cursor_dividendo_ru_tmp partition  200
   update statistics ca_cursor_dividendo_ru_tmp
   exec sp_recompile ca_cursor_dividendo_ru_tmp
   
PRINT 'deldia.sp  va  ca_buscar_operaciones_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_buscar_operaciones_tmp')
begin
   alter table ca_buscar_operaciones_tmp unpartition
end
   truncate table ca_buscar_operaciones_tmp
  -- alter table ca_buscar_operaciones_tmp partition  200
   update statistics ca_buscar_operaciones_tmp
   exec sp_recompile ca_buscar_operaciones_tmp
   
PRINT 'deldia.sp  va  ca_detalles_garantia_deudor'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_detalles_garantia_deudor')
begin
   alter table ca_detalles_garantia_deudor unpartition
end
   truncate table ca_detalles_garantia_deudor
 --  alter table ca_detalles_garantia_deudor partition  200
   update statistics ca_detalles_garantia_deudor
   exec sp_recompile ca_detalles_garantia_deudor
   
PRINT 'deldia.sp  va  ca_extracto_linea_tmp'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_extracto_linea_tmp')
begin
   alter table ca_extracto_linea_tmp unpartition
end
   truncate table ca_extracto_linea_tmp
  -- alter table ca_extracto_linea_tmp partition  200
   update statistics ca_extracto_linea_tmp
   exec sp_recompile ca_extracto_linea_tmp
   
PRINT 'deldia.sp  va ca_inf_general_evaluacion'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_inf_general_evaluacion')
begin
   alter table ca_inf_general_evaluacion unpartition
end
   truncate table ca_inf_general_evaluacion
  -- alter table ca_inf_general_evaluacion partition  200
   update statistics ca_inf_general_evaluacion
   exec sp_recompile ca_inf_general_evaluacion
   
PRINT 'deldia.sp  va ca_en_temporales'

if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'ca_en_temporales')
begin
   alter table ca_en_temporales unpartition
end
   truncate table ca_en_temporales
 --  alter table ca_en_temporales partition  200
   update statistics ca_en_temporales
   exec sp_recompile ca_en_temporales

PRINT 'deldia.sp  va tmp_gar_especiales'
if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'tmp_gar_especiales')
begin
   alter table tmp_gar_especiales unpartition
end
   truncate table tmp_gar_especiales
  -- alter table tmp_gar_especiales partition  200
   update statistics tmp_gar_especiales
   exec sp_recompile tmp_gar_especiales
   
PRINT 'deldia.sp  va tmp_garantias_tramite'
if exists(select 1 from sysobjects o, syspartitions p
           where o.id = p.id
           and   o.name = 'tmp_garantias_tramite')
begin
   alter table tmp_garantias_tramite unpartition
end
   truncate table tmp_garantias_tramite
   --alter table tmp_garantias_tramite partition  200
   update statistics tmp_garantias_tramite
   exec sp_recompile tmp_garantias_tramite

---DEF-7524 NOV-29-2006
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

truncate table ca_abono_prioridad_tmp
--update statistics ca_abono_prioridad_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_abono_prioridad_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_amortizacion_tmp
--update statistics ca_amortizacion_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_amortizacion_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_cliente_tmp
--update statistics ca_cliente_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_cliente_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_cuota_adicional_tmp
--update statistics ca_cuota_adicional_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_cuota_adicional_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_dividendo_tmp
--update statistics ca_dividendo_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_dividendo_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_dividendo_original_tmp
--update statistics ca_dividendo_original_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_dividendo_original_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_operacion_tmp
--update statistics ca_operacion_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_operacion_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_relacion_ptmo_tmp
--update statistics ca_relacion_ptmo_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_relacion_ptmo_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_rubro_op_tmp
--update statistics ca_rubro_op_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_rubro_op_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

/* Tablas de Trabajo */

truncate table ca_detalle_tmp
--update statistics ca_detalle_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_detalle_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_saldos_contables_tmp
--update statistics ca_saldos_contables_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_saldos_contables_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_rubro_calculado_tmp
--update statistics ca_rubro_calculado_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_rubro_calculado_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_prestamo_pagos_tmp
--update statistics ca_prestamo_pagos_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_prestamo_pagos_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_rubro_imo_tmp
--update statistics ca_rubro_imo_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_rubro_imo_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_rubro_int_tmp
--update statistics ca_rubro_int_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_rubro_int_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_relacion_ptmo_pago_temp
--update statistics ca_relacion_ptmo_pago_temp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_relacion_ptmo_pago_temp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_interes_proyectado_tmp
--update statistics ca_interes_proyectado_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_interes_proyectado_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_total_prioridad_tmp
--update statistics ca_total_prioridad_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_total_prioridad_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_consutar_transacciones_tmp1
--update statistics ca_consutar_transacciones_tmp1 --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_consutar_transacciones_tmp1 --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_consutar_transacciones_tmp2
--update statistics ca_consutar_transacciones_tmp2 --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_consutar_transacciones_tmp2 --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_cursor_dividendo_temp
--update statistics ca_cursor_dividendo_temp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_cursor_dividendo_temp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_cursor_dividendo_ru_tmp
--update statistics ca_cursor_dividendo_ru_tmp
--exec sp_recompile ca_cursor_dividendo_ru_tmp
   
truncate table ca_buscar_operaciones_tmp
--update statistics ca_buscar_operaciones_tmp
--exec sp_recompile ca_buscar_operaciones_tmp
   
truncate table ca_detalles_garantia_deudor
--update statistics ca_detalles_garantia_deudor --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_detalles_garantia_deudor --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_extracto_linea_tmp
--update statistics ca_extracto_linea_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_extracto_linea_tmp --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_inf_general_evaluacion
--update statistics ca_inf_general_evaluacion --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_inf_general_evaluacion --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table ca_en_temporales
--update statistics ca_en_temporales --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_en_temporales --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table tmp_gar_especiales
--update statistics tmp_gar_especiales --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile tmp_gar_especiales --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
   
truncate table tmp_garantias_tramite
--update statistics tmp_garantias_tramite --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile tmp_garantias_tramite --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

---DEF-7524 NOV-29-2006

delete cob_cartera..ca_fval_masivo
where fm_estado = 'I'

-- NYM 7x24 

truncate table ca_en_fecha_valor   
--update statistics ca_en_fecha_valor --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_en_fecha_valor --LPO CDIG Se comenta temporalmente porque MySql no lo soporta

truncate table ca_op_renovar_tmp

-- GFP  Se borra tabla temporal ca_operacion_datos_adicionales_tmp
truncate table ca_operacion_datos_adicionales_tmp


-- KDR Borrado de tabla temporal ca_qr_transacciones_tmp
truncate table ca_qr_transacciones_tmp

--GFP Borrado de la tabla ca_en_fecha_valor_grupal
truncate table ca_en_fecha_valor_grupal

return 0
go
