/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Marcelo Poveda		                */
/*      Fecha de escritura:     Octubre 2001                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Consulta los saldos diarios de las obligaciones de Cartera para	*/
/*      la interfaz com MBS						*/
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/* **********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldos_mbs')
   drop proc sp_saldos_mbs
go

create proc sp_saldos_mbs
as
declare
@w_op_operacion		int,
@w_op_banco		cuenta,
@w_op_cliente		int,
@w_op_oficina		smallint,
@w_en_ced_ruc		cuenta,
@w_en_tipo_ced		varchar(2),
@w_longitud		tinyint,
@w_digito		char(1),
@w_tipo_doc		tinyint,
@w_fecha_ven		varchar(10),
@w_saldo		money


/** LIMPIAR TABLA **/
delete ca_saldos_mbs_tmp
where sm_banco > ''

/** SELECCION DE OPERACIONES EN CARTERA **/
declare cursor_operacion cursor for
select
op_operacion, op_banco,   op_cliente,
op_oficina,   en_ced_ruc, en_tipo_ced
from   ca_operacion, 
       ca_estado, 
       cobis..cl_ente,
       ca_default_toperacion
where  op_estado   = es_codigo
and    es_acepta_pago = 'S'
and    op_cliente  = en_ente
and    op_toperacion = dt_toperacion
and    op_moneda = dt_moneda
and    (op_estado_cobranza != 'CJ' or op_estado_cobranza is null)  -- No en Cobranza Judicial
and    dt_naturaleza = 'A'	   -- No Pasivas
for read only

open cursor_operacion

fetch cursor_operacion into
@w_op_operacion, @w_op_banco,   @w_op_cliente,
@w_op_oficina,   @w_en_ced_ruc, @w_en_tipo_ced


while @@fetch_status = 0 begin

   /** SELECCION DEL DIGITO VERIFICADOR DEL DOCUMENTOS **/
   select @w_longitud = datalength(@w_en_ced_ruc)
   select @w_digito = substring(@w_en_ced_ruc, @w_longitud, @w_longitud)

   /** SELECCION TIPO DE DOCUMENTO DEL CLIENTE **/
   select @w_tipo_doc = td_tipo_mbs
   from  ca_tipo_doc_mbs
   where td_tipo_cobis = @w_en_tipo_ced

   /** FECHA DE VENCIMIENTO DE LA CUOTA **/
   select @w_fecha_ven = convert(varchar(10),min(di_fecha_ven),103)
   from ca_dividendo
   where di_operacion = @w_op_operacion
   and   di_estado in (1,2)
   
   /** CALCULO DE SALDO A PAGAR DE LA OBLIGACION **/
   select @w_saldo = sum(((am_acumulado - am_gracia - am_pagado)+ abs(am_acumulado - am_gracia - am_pagado))/2)
   from  ca_amortizacion, ca_dividendo
   where am_operacion = @w_op_operacion
   and   di_operacion = @w_op_operacion
   and   am_operacion = di_operacion
   and   di_dividendo = am_dividendo
   and   di_estado in (1,2)

   /** INSERTAR LA INFORMACION **/
   insert ca_saldos_mbs_tmp(
   sm_tipo,    sm_num_doc, sm_digito,
   sm_oficina, sm_banco,   sm_monto,
   sm_fecha_ven)
   values(
   @w_tipo_doc,   @w_en_ced_ruc, @w_digito,
   @w_op_oficina, @w_op_banco,   @w_saldo,
   @w_fecha_ven) 
     
   fetch cursor_operacion into
   @w_op_operacion, @w_op_banco,   @w_op_cliente,
   @w_op_oficina,   @w_en_ced_ruc, @w_en_tipo_ced
end
close cursor_operacion
deallocate cursor_operacion

return 0
go
