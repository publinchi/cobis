/************************************************************************/
/*   Archivo:              ca_tabla_mpyme.sp                            */
/*   Stored procedure:     sp_tabla_mpyme                               */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         XMA                                          */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Realiza el registro del universo de las obligaciones que se van    */
/*   a procesar.                                                        */
/************************************************************************/
/*                                 MODIFICACIONES                       */
/*   FECHA           AUTOR             RAZON                            */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tabla_mpyme')
   drop proc sp_tabla_mpyme
go

create proc sp_tabla_mpyme
as 

if exists (select 1 from sysobjects where name = 'ca_recalculo_mipymes_datos' )
drop table ca_recalculo_mipymes_datos


select  
op_oficina                        as OFICINA,     
op_cliente                        as CLIENTE,
convert(varchar(30),'')           as CEDULA,
op_operacion                      as OPERACION,   
op_banco                          as OPBANCO,   
convert(varchar,op_fecha_liq,101) as FECHA_DESEMBOLSO,
convert(money,0)                  as VALOR_DESEMBOLSO,
0                                 as PLAZO,
0                                 as CUOTAS_PAGADAS,
0                                 as CUOTAS_VENCIDAS,
di_dividendo                      as DIVIDENDO,
di_estado                         as ESTADO_DIV,
am_concepto                       as CONCEPTO,
ro_porcentaje                     as TASA_OR,
am_estado                         as ESTADO_RUBRO,
am_cuota                          as CUOTA_OR,
am_pagado                         as PAGADO_OR,      
am_acumulado                      as ACUMULADO_OR,   
1200                              as PARAMETRO,   
convert(money,0)                  as CAPITAL_BASE,
CONVERT(float,0)                  as TASA_NUEVA,
convert(money,0)                  as CUOTA_NEW,
convert(money,0)                  as ACUMULADO_NEW
into ca_recalculo_mipymes_datos
from cob_cartera..ca_operacion with (nolock),
     cob_cartera..ca_amortizacion with (nolock),
     cob_cartera..ca_dividendo with (nolock),
     cob_cartera..ca_rubro_op  with (nolock)
where op_operacion = ro_operacion
and ro_concepto  = am_concepto
and ro_porcentaje in  (8.11, 4.71)  --(7.82, 4.61)  ----(@w_tasa1,@w_tasa2)   
and op_operacion = am_operacion
and op_operacion = di_operacion
and am_operacion = di_operacion
and am_dividendo = di_dividendo
and am_concepto  = ro_concepto
and am_concepto  = 'MIPYMES'
and am_pagado    = 0
and di_estado    = 0
and op_estado  in (1,2,9)
order by op_operacion, di_dividendo 

create nonclustered index ca_recalculo_idx on ca_recalculo_mipymes_datos (OPERACION,DIVIDENDO,CONCEPTO )


return 0
go


