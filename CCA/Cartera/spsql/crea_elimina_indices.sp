/************************************************************************/
/*   NOMBRE LOGICO:      crea_elimina_indices.sp                        */            
/*   NOMBRE FISICO:      sp_crea_elimina_indices                        */
/*   BASE DE DATOS:      cob_cartera_his                                */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Kevin Rodríguez                                */
/*   FECHA DE ESCRITURA: Marzo 2023                                     */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Programa que crea y elimina índices de tablas de la base de datos  */
/*   de históricos de cartera                                           */
/*                                                                      */
/************************************************************************/
/*                             CAMBIOS                                  */
/*   FECHA       AUTOR             RAZON                                */
/* 22/Mar/2023   Kevin Rodríguez   Version inicial                      */
/************************************************************************/

use cob_cartera_his
go

if exists (select 1 from sysobjects where name = 'sp_crea_elimina_indices')
   drop proc sp_crea_elimina_indices
go

create proc sp_crea_elimina_indices (
@i_operacion    char(1)   -- Eliminar (E), Crear (C)
)

as declare
@w_sp_name  varchar(30),
@w_error    int 

---  VARIABLES DE TRABAJO  
select @w_sp_name = 'sp_crea_elimina_indices'


-- Crear índices para las tablas de la base de datos de históricos de Cartera
if @i_operacion = 'C'
begin

   -- ca_operacion
   if not exists (select 1 from sys.indexes where name='ca_operacion_1' and object_id = OBJECT_ID('ca_operacion'))
      CREATE UNIQUE NONCLUSTERED INDEX ca_operacion_1
   	  ON ca_operacion (op_operacion)
   
   if not exists (select 1 from sys.indexes where name='ca_operacion_2' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_2
   	  ON ca_operacion (op_migrada)

   if not exists (select 1 from sys.indexes where name='ca_operacion_3' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_3
   	  ON ca_operacion (op_tramite)
   
   if not exists (select 1 from sys.indexes where name='ca_operacion_4' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_4
      ON ca_operacion (op_cliente)

   if not exists (select 1 from sys.indexes where name='ca_operacion_5' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_5
   	  ON ca_operacion (op_oficial)
   
   if not exists (select 1 from sys.indexes where name='ca_operacion_6' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_6
   	  ON ca_operacion (op_oficina)
   
   if not exists (select 1 from sys.indexes where name='ca_operacion_7' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_7
   	  ON ca_operacion (op_banco)
   
   if not exists (select 1 from sys.indexes where name='ca_operacion_8' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_8 
      on ca_operacion (op_lin_credito)
   
   if not exists (select 1 from sys.indexes where name='ca_operacion_9' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_9
   	  ON ca_operacion (op_estado, op_fecha_liq, op_tramite, op_oficial)
   
   if not exists (select 1 from sys.indexes where name='ca_operacion_10' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_10 
      on ca_operacion (op_oficial, op_tramite, op_cliente, op_estado)

   if not exists (select 1 from sys.indexes where name='ca_operacion_idx11' and object_id = OBJECT_ID('ca_operacion'))
      CREATE NONCLUSTERED INDEX ca_operacion_idx11 
      on ca_operacion (op_naturaleza, op_fecha_ult_proceso, op_cuenta, op_operacion, op_estado, op_forma_pago)
    
   -- ca_rubro_op 
   if not exists (select 1 from sys.indexes where name='ca_rubro_op_1' and object_id = OBJECT_ID('ca_rubro_op'))
      CREATE UNIQUE NONCLUSTERED INDEX ca_rubro_op_1
   	  ON ca_rubro_op (ro_operacion, ro_concepto)
   
   if not exists (select 1 from sys.indexes where name='ca_rubro_op_idx2' and object_id = OBJECT_ID('ca_rubro_op'))
      CREATE NONCLUSTERED INDEX ca_rubro_op_idx2
      ON ca_rubro_op (ro_operacion, ro_tipo_rubro, ro_concepto, ro_porcentaje, ro_fpago)
   
   if not exists (select 1 from sys.indexes where name='ca_rubro_op_idx3' and object_id = OBJECT_ID('ca_rubro_op'))
      CREATE NONCLUSTERED INDEX ca_rubro_op_idx3 
      on ca_rubro_op (ro_operacion, ro_provisiona, ro_tipo_rubro, ro_concepto, ro_fpago, ro_valor, ro_porcentaje, ro_concepto_asociado, ro_porcentaje_efa, ro_num_dec)
   
   if not exists (select 1 from sys.indexes where name='ca_rubro_op_idx4' and object_id = OBJECT_ID('ca_rubro_op'))
      CREATE NONCLUSTERED INDEX ca_rubro_op_idx4 
      on ca_rubro_op (ro_operacion, ro_paga_mora, ro_concepto, ro_fpago)
   

   -- ca_dividendo
   if not exists (select 1 from sys.indexes where name='ca_dividendo_1' and object_id = OBJECT_ID('ca_dividendo'))
      CREATE UNIQUE CLUSTERED INDEX ca_dividendo_1
   	  ON ca_dividendo (di_operacion, di_dividendo)
   
   if not exists (select 1 from sys.indexes where name='ca_dividendo_2' and object_id = OBJECT_ID('ca_dividendo'))
      CREATE NONCLUSTERED INDEX ca_dividendo_2 
      on ca_dividendo (di_operacion, di_estado)
   
   if not exists (select 1 from sys.indexes where name='ca_dividendo_idx3' and object_id = OBJECT_ID('ca_dividendo'))
      CREATE NONCLUSTERED INDEX  ca_dividendo_idx3 
      on ca_dividendo (di_estado, di_operacion, di_dividendo, di_fecha_ven, di_gracia)
   
   
   -- ca_amortizacion
   if not exists (select 1 from sys.indexes where name='ca_amortizacion_1' and object_id = OBJECT_ID('ca_amortizacion'))
      CREATE UNIQUE CLUSTERED INDEX ca_amortizacion_1
      ON ca_amortizacion (am_operacion, am_dividendo, am_concepto, am_secuencia)
   
   if not exists (select 1 from sys.indexes where name='ca_amortizacion_idx2' and object_id = OBJECT_ID('ca_amortizacion'))
      CREATE NONCLUSTERED INDEX ca_amortizacion_idx2 
      on ca_amortizacion (am_concepto, am_operacion, am_dividendo, am_cuota, am_gracia, am_pagado)


   -- ca_cuota_adicional
   if not exists (select 1 from sys.indexes where name='ca_cuota_adicional_1' and object_id = OBJECT_ID('ca_cuota_adicional'))
      create unique nonclustered index ca_cuota_adicional_1 
      on ca_cuota_adicional (ca_operacion, ca_dividendo)
   
   if not exists (select 1 from sys.indexes where name='ca_cuota_adicional_2' and object_id = OBJECT_ID('ca_cuota_adicional'))
      create nonclustered index ca_cuota_adicional_2 
      on ca_cuota_adicional (ca_operacion, ca_dividendo, ca_cuota)
   
   
   -- ca_tasas
   if not exists (select 1 from sys.indexes where name='ca_tasas_I1' and object_id = OBJECT_ID('ca_tasas'))
      CREATE CLUSTERED INDEX ca_tasas_I1
   	  ON ca_tasas (ts_operacion, ts_dividendo, ts_concepto, ts_fecha)
   
   
   -- ca_transaccion
   if not exists (select 1 from sys.indexes where name='ca_transaccion_3' and object_id = OBJECT_ID('ca_transaccion'))
      create nonclustered index ca_transaccion_3 
      on ca_transaccion (tr_fecha_mov, tr_tran, tr_ofi_usu)

   if not exists (select 1 from sys.indexes where name='ca_transaccion_4' and object_id = OBJECT_ID('ca_transaccion'))
      create nonclustered index ca_transaccion_4 
      on ca_transaccion (tr_fecha_mov,tr_comprobante)
   
   if not exists (select 1 from sys.indexes where name='ca_transaccion_5' and object_id = OBJECT_ID('ca_transaccion'))
      create nonclustered index ca_transaccion_5 
      on ca_transaccion (tr_tran, tr_estado, tr_fecha_ref, tr_secuencial, tr_fecha_mov, tr_toperacion, tr_banco, tr_secuencial_ref)
   
   if not exists (select 1 from sys.indexes where name='ca_transaccion_idx6' and object_id = OBJECT_ID('ca_transaccion'))
      create nonclustered index ca_transaccion_idx6 
      on ca_transaccion (tr_operacion, tr_secuencial, tr_tran, tr_estado)
   
   if not exists (select 1 from sys.indexes where name='ca_transaccion_1' and object_id = OBJECT_ID('ca_transaccion'))
      create nonclustered index ca_transaccion_1 
      on ca_transaccion (tr_operacion, tr_secuencial)
   
   if not exists (select 1 from sys.indexes where name='ca_transaccion_2' and object_id = OBJECT_ID('ca_transaccion'))
      create nonclustered index ca_transaccion_2 
      on ca_transaccion (tr_banco)
   

   -- ca_det_trn
   if not exists (select 1 from sys.indexes where name='ca_det_trn_1' and object_id = OBJECT_ID('ca_det_trn'))
      create clustered index ca_det_trn_1 
      on ca_det_trn (dtr_operacion, dtr_secuencial, dtr_dividendo, dtr_codvalor)
	  
	  
   -- ca_transaccion_prv
   if not exists (select 1 from sys.indexes where name='idx1' and object_id = OBJECT_ID('ca_transaccion_prv'))
      create clustered index idx1 
      on ca_transaccion_prv (tp_operacion, tp_fecha_mov)
   
   if not exists (select 1 from sys.indexes where name='idx2' and object_id = OBJECT_ID('ca_transaccion_prv'))
      create nonclustered index idx2 
      on ca_transaccion_prv (tp_fecha_ref, tp_estado, tp_operacion)
   
   if not exists (select 1 from sys.indexes where name='idx5' and object_id = OBJECT_ID('ca_transaccion_prv'))
      create nonclustered index idx5 
      on ca_transaccion_prv (tp_fecha_mov,tp_comprobante)
	  
	 
   -- ca_operacion_datos_adicionales
   if not exists (select 1 from sys.indexes where name='ca_operacion_datos_adicionales1' and object_id = OBJECT_ID('ca_operacion_datos_adicionales'))
      create unique nonclustered index ca_operacion_datos_adicionales1
      ON ca_operacion_datos_adicionales (oda_operacion)
   
   -- ca_abono
   if not exists (select 1 from sys.indexes where name='ca_abono_1' and object_id = OBJECT_ID('ca_abono'))
      CREATE UNIQUE CLUSTERED INDEX ca_abono_1
   	  ON ca_abono (ab_operacion, ab_secuencial_ing)
   
   if not exists (select 1 from sys.indexes where name='ca_abono_3' and object_id = OBJECT_ID('ca_abono'))
      CREATE NONCLUSTERED INDEX ca_abono_3
   	  ON ca_abono (ab_secuencial_pag)
   
   if not exists (select 1 from sys.indexes where name='ca_abono_4' and object_id = OBJECT_ID('ca_abono'))
      CREATE NONCLUSTERED INDEX  ca_abono_4 
      on ca_abono (ab_estado)
   
   if not exists (select 1 from sys.indexes where name='ca_abono_5' and object_id = OBJECT_ID('ca_abono'))
      CREATE NONCLUSTERED INDEX  ca_abono_5 
      on ca_abono (ab_fecha_pag)

   if not exists (select 1 from sys.indexes where name='ca_abono_idx6' and object_id = OBJECT_ID('ca_abono'))
      CREATE NONCLUSTERED INDEX  ca_abono_idx6 
      on ca_abono (ab_secuencial_rpa, ab_secuencial_ing, ab_operacion, ab_fecha_ing)
   
   
   -- ca_abono_det
   if not exists (select 1 from sys.indexes where name='ca_abono_det_1' and object_id = OBJECT_ID('ca_abono_det'))
      CREATE UNIQUE NONCLUSTERED INDEX ca_abono_det_1
   	  ON ca_abono_det (abd_operacion, abd_secuencial_ing, abd_tipo, abd_concepto, abd_cuenta)
   
   -- ca_otro_cargo
   if not exists (select 1 from sys.indexes where name='ca_otro_cargo_1' and object_id = OBJECT_ID('ca_otro_cargo'))
      CREATE UNIQUE NONCLUSTERED INDEX ca_otro_cargo_1 
      on ca_otro_cargo (oc_operacion, oc_secuencial)
   
   
   -- ca_operacion_his
   if not exists (select 1 from sys.indexes where name='ca_operacion_his_1' and object_id = OBJECT_ID('ca_operacion_his'))
      create unique nonclustered index ca_operacion_his_1
      on ca_operacion_his (oph_operacion, oph_secuencial) 
   
   -- ca_rubro_op_his
   if not exists (select 1 from sys.indexes where name='ca_rubro_op_his_1' and object_id = OBJECT_ID('ca_rubro_op_his'))
      create nonclustered index ca_rubro_op_his_1
      on ca_rubro_op_his (roh_operacion, roh_secuencial)

   -- ca_amortizacion_his
   if not exists (select 1 from sys.indexes where name='ca_amortizacion_his_1' and object_id = OBJECT_ID('ca_amortizacion_his'))
      create nonclustered index ca_amortizacion_his_1
      on ca_amortizacion_his (amh_operacion, amh_secuencial)
   
   if not exists (select 1 from sys.indexes where name='ca_amortizacion_his_idx2' and object_id = OBJECT_ID('ca_amortizacion_his'))
      create nonclustered index ca_amortizacion_his_idx2 
      on ca_amortizacion_his (amh_secuencial, amh_operacion, amh_dividendo, amh_concepto, amh_estado, 
   	                          amh_periodo, amh_cuota, amh_gracia, amh_pagado, amh_acumulado, amh_secuencia)
   
   -- ca_dividendo_his
   if not exists (select 1 from sys.indexes where name='ca_dividendo_his_1' and object_id = OBJECT_ID('ca_dividendo_his'))
      create nonclustered index ca_dividendo_his_1
      on ca_dividendo_his (dih_operacion, dih_secuencial)
   
   
   -- ca_cuota_adicional_his
   if not exists (select 1 from sys.indexes where name='ca_cuota_adicional_his_1' and object_id = OBJECT_ID('ca_cuota_adicional_his'))
      create nonclustered index ca_cuota_adicional_his_1
      on ca_cuota_adicional_his (cah_operacion, cah_secuencial)

end

-- Eliminar índices de las tablas de la base de datos de históricos de Cartera
if @i_operacion = 'E'
begin

   -- ca_operacion
   drop index if exists 
   ca_operacion_1     on ca_operacion, 
   ca_operacion_2     on ca_operacion,
   ca_operacion_3     on ca_operacion,
   ca_operacion_4     on ca_operacion,
   ca_operacion_5     on ca_operacion,
   ca_operacion_6     on ca_operacion,
   ca_operacion_7     on ca_operacion,
   ca_operacion_8     on ca_operacion,
   ca_operacion_9     on ca_operacion,
   ca_operacion_10    on ca_operacion,
   ca_operacion_idx11 on ca_operacion
   
   -- ca_rubro_op
   drop index if exists 
   ca_rubro_op_1    on ca_rubro_op, 
   ca_rubro_op_idx2 on ca_rubro_op,
   ca_rubro_op_idx3 on ca_rubro_op,
   ca_rubro_op_idx4 on ca_rubro_op
   
   -- ca_dividendo
   drop index if exists 
   ca_dividendo_1    on ca_dividendo, 
   ca_dividendo_2    on ca_dividendo,
   ca_dividendo_idx3 on ca_dividendo
   
   -- ca_amortizacion
   drop index if exists 
   ca_amortizacion_1    on ca_amortizacion, 
   ca_amortizacion_idx2 on ca_amortizacion
   
   -- ca_cuota_adicional
   drop index if exists 
   ca_cuota_adicional_1 on ca_cuota_adicional, 
   ca_cuota_adicional_2 on ca_cuota_adicional
   
   -- ca_tasas
   drop index if exists 
   ca_tasas_I1 on ca_tasas
   
   -- ca_transaccion
   drop index if exists 
   ca_transaccion_3    on ca_transaccion, 
   ca_transaccion_4    on ca_transaccion,
   ca_transaccion_5    on ca_transaccion,
   ca_transaccion_idx6 on ca_transaccion,
   ca_transaccion_1    on ca_transaccion,
   ca_transaccion_2    on ca_transaccion
   
   -- ca_det_trn
   drop index if exists 
   ca_det_trn_1 on ca_det_trn
   
   -- ca_transaccion_prv
   drop index if exists 
   idx1 on ca_transaccion_prv, 
   idx2 on ca_transaccion_prv,
   idx5 on ca_transaccion_prv

   -- ca_operacion_datos_adicionales
   drop index if exists 
   ca_operacion_datos_adicionales1 on ca_operacion_datos_adicionales
   
   -- ca_abono
   drop index if exists 
   ca_abono_1    on ca_abono, 
   ca_abono_3    on ca_abono,
   ca_abono_4    on ca_abono,
   ca_abono_5    on ca_abono,
   ca_abono_idx6 on ca_abono
   
   -- ca_abono_det
   drop index if exists 
   ca_abono_det_1 on ca_abono_det
   
   -- ca_otro_cargo
   drop index if exists 
   ca_otro_cargo_1 on ca_otro_cargo
   
   -- ca_operacion_his
   drop index if exists 
   ca_operacion_his_1 on ca_operacion_his
   
   -- ca_rubro_op_his
   drop index if exists 
   ca_rubro_op_his_1 on ca_rubro_op_his
   
   -- ca_amortizacion_his
   drop index if exists 
   ca_amortizacion_his_1    on ca_amortizacion_his,
   ca_amortizacion_his_idx2 on ca_amortizacion_his
   
   -- ca_dividendo_his
   drop index if exists 
   ca_dividendo_his_1 on ca_dividendo_his
   
   -- ca_cuota_adicional_his
   drop index if exists 
   ca_cuota_adicional_his_1 on ca_cuota_adicional_his

end

SALIR:

return 0

ERROR:
return @w_error

GO


