/************************************************************************/
/*   Archivo:              conci_mw.sp                                  */
/*   Stored procedure:     sp_conciliacion_men_w                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Feb.2003                                     */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Genera diferencias de saldos y tasas en el cruce  de archivo       */
/*      de banco segundo piso  y saldos mensuales de COBIS              */
/************************************************************************/
/*   MODIFICACIONES                                                     */
/*      Fecha           Nombre        Proposito                         */
/*   04/Dic/2004  Johan Ardila - JAR  Optimizacion. Creacion de indice  */
/*                                    solo para actualizacion de datos  */
/*                                    en ca_conciliacion_mensual        */
/*   may-24-2006  Elcira Pelaez       def. 6503 cruzar unicamente con   */
/*                                    llave de redescuento              */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_datos_concil_men')
   drop table ca_datos_concil_men
go

create table ca_datos_concil_men
(cma_llave_redescuento     cuenta   null,
 pma_oper_llave_redes      cuenta   null,
 cma_norma_legal           cuenta   null,
 pma_linea_norlegal        cuenta   null,
 cma_saldo_redescuento     money    null,
 pma_valor_saldo_redes     money    null,
 cma_modalidad_pago        char(1)  null,
 pma_modalidad             char(1)  null,
 cma_tasa_nominal          float    null,
 pma_tasa_nom              float    null,
 cma_identificacion        cuenta   null,
 pma_identificacion        cuenta   null,
 cma_banco                 cuenta   null,
 cma_oficina               int      null,
 cma_fecha_redescuento     datetime null,
 cma_diferencia            money    null
)
go


if exists (select 1 from sysobjects where name = 'sp_conciliacion_men_w')
   drop proc sp_conciliacion_men_w
go

create proc sp_conciliacion_men_w
@i_fecha_proceso        datetime
as

declare 
   @w_error                int
begin
   truncate table ca_datos_concil_men
   -- COMPARACION DATOS QUE GENERAN DIFERENCIA
   -- Campos a comparar:
   -- Tasa Nominal
   -- Saldo de Redescuento
   
   if exists (select * from sysindexes where id=OBJECT_ID('dbo.ca_datos_concil_men')
              and name='ca_datos_concil_men_key')
              drop index ca_datos_concil_men.ca_datos_concil_men_key

    --Inserta los creditos cuya norma es diferente   
   insert into ca_datos_concil_men
   select cm_llave_redescuento,      ca_llave,
          cm_norma_legal,            ca_linea_norlegal,
          cm_saldo_redescuento,      ca_valor_saldo_redes/100,
          cm_modalidad_pago,         ca_modalidad,
          cm_tasa_nominal,           ca_tasa_nom,
          cm_identificacion,           ca_identificacion,
          cm_banco,           cm_oficina,
          cm_fecha_redescuento,      abs(cm_saldo_redescuento - ca_valor_saldo_redes/100)
   from   ca_conciliacion_mensual,ca_llave_finagro
   where  cm_llave_redescuento = ca_llave
   and    ltrim(rtrim(cm_norma_legal))  <> ltrim(rtrim(ca_linea_norlegal)) 
   
   --Inserta los creditos cuya tasa nominal  es diferente
   insert into ca_datos_concil_men
   select cm_llave_redescuento,      ca_llave,
          cm_norma_legal,            ca_linea_norlegal,
          cm_saldo_redescuento,      ca_valor_saldo_redes/100,
          cm_modalidad_pago,         ca_modalidad,
          cm_tasa_nominal,           ca_tasa_nom,
          cm_identificacion,           ca_identificacion,
          cm_banco,           cm_oficina,
          cm_fecha_redescuento,      abs(cm_saldo_redescuento - ca_valor_saldo_redes/100)
   from   ca_conciliacion_mensual,ca_llave_finagro
   where  cm_llave_redescuento = ca_llave
   and    cm_tasa_nominal  <> ca_tasa_nom 
   
   create index ca_datos_concil_men_key ON ca_datos_concil_men
         (cma_llave_redescuento, cma_identificacion)
   
   update cob_cartera..ca_conciliacion_mensual
   set    cm_mw = 'S',
          cm_diferencia = cma_diferencia
   from   ca_conciliacion_mensual, ca_datos_concil_men 
   where  cm_llave_redescuento = pma_oper_llave_redes         
end
return 0

go

