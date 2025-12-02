/************************************************************************/
/*   NOMBRE LOGICO:      sp_cuota                                       */
/*   NOMBRE FISICO:      cuota.sp                                       */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:                                                      */
/*   FECHA DE ESCRITURA:                                                */
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
/*                             PROPOSITO                                */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*  FECHA           AUTOR            RAZON                              */
/*  08/Nov/2016     J. Salazar     Migracion Cobis Cloud                */
/*  14/11/2023      K. Rodriguez   R219105 Ajuste obtencion cuota       */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cuota')
	drop proc sp_cuota
go

create proc sp_cuota
   @i_operacion    int,
   @i_actualizar   char(1) = 'N',
   @o_cuota        money   = NULL  out
as 
declare
   @w_error          int,
   @w_cuota          money,
   @w_di_dividendo   int

-- Obtiene minimo dividendo por estado
select estado = di_estado, dividendo = min(di_dividendo) 
into #estados
from cob_cartera..ca_dividendo with (nolock)
where di_operacion = @i_operacion
and di_de_capital  = 'S'
group by di_estado

if @@rowcount = 0 
   return 724528 -- Error al calcular nueva cuota pactada

-- Obtiene maximo dividendo de los minimos obtenidos
select @w_di_dividendo = max(dividendo) 
from #estados

-- Obtiene valor de cuota basada en concepto de Capital e Interes
select @w_cuota = sum(am_cuota) 
from ca_amortizacion with (nolock), ca_rubro_op with (nolock)
where am_operacion = @i_operacion
and   am_dividendo = @w_di_dividendo
and   am_operacion = ro_operacion
and   am_concepto  = ro_concepto
and   ro_tipo_rubro in ('C', 'I')

if @i_actualizar = 'S' begin 
   update ca_operacion set 
   op_cuota = @w_cuota
   where op_operacion = @i_operacion
   
   if @@rowcount = 0 
      return 724529 -- Error al actualizar nueva cuota pactada
end

select @o_cuota = @w_cuota

return 0
go

