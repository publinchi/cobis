/************************************************************************/
/*   Archivo:                 qrrenope.sp                               */
/*   Stored procedure:        sp_qr_renova_opera                        */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            DFu                                       */
/*   Fecha de Documentacion:  Ene. 2017                                 */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consultar los prestamos candidatos a ser renovados dado un cliente */
/*   y una moneda específica                                            */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA        AUTOR             RAZON                                */
/*  11/ene/2017  DFu               Emision inicial                      */
/*  12/ago/2019  DFu               se agrega op_tramite                 */
/*  27/ago/2019  AGi            Calculo correcto de Valores a renovar   */
/*  03/dic/2019  Luis Ponce     Cobro Indiv Acumulado,Grupal Proyectado */
/*  17/jun/2020  Luis Ponce  CDIG Multimoneda consulta OP en varias mone*/
/************************************************************************/
use cob_cartera
go

if exists(select * from sysobjects where name = 'sp_qr_renova_opera')
   drop proc sp_qr_renova_opera
go
 
create proc sp_qr_renova_opera (
    @s_user                  varchar(14),
    @s_term                  varchar(30),
    @s_date                  datetime,
    @s_ofi                   smallint,
    @i_ente                  int,
    @i_moneda                SMALLINT = NULL, --LPO CDIG Multimoneda
    @i_formato_fecha         smallint = 101,
    @i_operacion             char(1) = null
)
as

declare 
@w_operacionca    int,
@w_error          int,
@w_msg            varchar(255),
@w_return         int, 
@w_est_novigente  smallint,
@w_est_vigente    smallint,
@w_est_vencido    smallint,
@w_est_cancelado  smallint,
@w_est_castigado  smallint,
@w_est_diferido   smallint,
@w_est_anulado    smallint,
@w_est_condonado  smallint,
@w_est_suspenso   smallint,
@w_est_credito    smallint


exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_novigente  = @w_est_novigente  out,
@o_est_cancelado  = @w_est_cancelado out

if @w_error <> 0 goto ERROR


--INI AGI.  Obtener saldos de operacion
-- CREAR TABLA DE OPERACIONES  
create table #TMP_operaciones (
       operacion            int,
       banco                cuenta,
       saldo_capital        money,
       saldo_interes        money,
       saldo_mora           money,
       saldo_otros          MONEY,
       tipo_grupal          CHAR(1) --LPO TEC para Marcar las operaciones como Grupal, Interciclo o Individual
       )

--Insertar Posibles operaciones a renovar
--LPO CDIG Multimoneda INICIO
IF @i_operacion = 'Q'
   insert into #TMP_operaciones
   select op_operacion, op_banco,  0, 0, 0, 0, NULL
   from   ca_operacion o, ca_default_toperacion
   where  op_toperacion = dt_toperacion 
   and    op_moneda     = dt_moneda 
   and    op_cliente    = @i_ente 
   --and    op_moneda     = @i_moneda 
   and    op_estado    in (@w_est_vigente, @w_est_vencido)
   and    dt_renovacion = 'S'
ELSE
   insert into #TMP_operaciones
   select op_operacion, op_banco,  0, 0, 0, 0, NULL
   from   ca_operacion o, ca_default_toperacion
   where  op_toperacion = dt_toperacion 
   and    op_moneda     = dt_moneda 
   and    op_cliente    = @i_ente 
   and    op_moneda     = @i_moneda 
   and    op_estado    in (@w_est_vigente, @w_est_vencido) 
   and    dt_renovacion = 'S'
  
--LPO CDIG Multimoneda FIN


--LPO TEC Marcar las operaciones como Grupal, Interciclo o Individual:
UPDATE #TMP_operaciones
SET tipo_grupal = 'G' --Grupal
--FROM #TMP_operaciones, ca_operacion, ca_ciclo --LPO CDIG Se quita la tabla porque en MySql no se soporta la misma tabla en update from 
FROM ca_operacion, ca_ciclo 
where op_operacion = ci_operacion
  and op_grupal = 'S'
  and op_ref_grupal is null
  and op_banco = banco

UPDATE #TMP_operaciones
SET tipo_grupal = 'I' --Interciclo
--FROM #TMP_operaciones, ca_operacion, ca_det_ciclo --LPO CDIG Se quita la tabla porque en MySql no se soporta la misma tabla en update from 
FROM ca_operacion, ca_det_ciclo 
where op_operacion = dc_operacion
  and op_banco = banco
  and (op_grupal = 'N' or op_grupal is null)
  and op_ref_grupal is not null
  and dc_tciclo = 'I'

UPDATE #TMP_operaciones
SET tipo_grupal = 'N' --Individual
--FROM #TMP_operaciones, ca_operacion  --LPO CDIG Se quita la tabla porque en MySql no se soporta la misma tabla en update from
FROM ca_operacion
where op_banco = banco
  and (op_grupal = 'N' or op_grupal is null)
  and op_operacion not in (select dc_operacion from ca_det_ciclo)
--LPO TEC FIN Marcar las operaciones como Grupal, Interciclo o Individual


--Obteniendo valores Proyecto cuota vigente
update #TMP_operaciones
set saldo_capital = CASE 
                        WHEN tipo_grupal = 'G' THEN --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
                        isnull((select (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado    in (@w_est_vencido, @w_est_vigente)
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria = 'C'),0)
                        ELSE
                        isnull((select (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado    in (@w_est_vencido, @w_est_vigente)
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria = 'C'),0)
                        
                        END,
     saldo_interes =CASE
                        WHEN tipo_grupal = 'G' THEN --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
                        isnull((select (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado    in (@w_est_vencido, @w_est_vigente)
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria = 'I'), 0)
                        ELSE 
                        isnull((select (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado    in (@w_est_vencido, @w_est_vigente)
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria = 'I'), 0)
                        END,
     saldo_mora    =CASE 
                        WHEN tipo_grupal = 'G' THEN --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
                        isnull((select (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado    in (@w_est_vencido, @w_est_vigente)
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria = 'M'),0)
                        ELSE
                        isnull((select (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado    in (@w_est_vencido, @w_est_vigente)
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria = 'M'),0)
                        END,
     saldo_otros   =CASE 
                        WHEN tipo_grupal = 'G' THEN --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
                        isnull((select (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado   <> @w_est_cancelado--in (@w_est_vencido, @w_est_vigente)
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria not in ('C','I','M')),0)
                        ELSE
                        isnull((select (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado   <> @w_est_cancelado-- in (@w_est_vencido, @w_est_vigente)
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria not in ('C','I','M')),0)
                        END
--from #TMP_operaciones o --LPO CDIG Se quita la tabla porque en MySql no se soporta la misma tabla en update from


-- Acumulado cuotas no vigentes
update #TMP_operaciones
set saldo_capital = saldo_capital + isnull((select (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado    = @w_est_novigente
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria = 'C'),0),
     saldo_interes = saldo_interes + isnull((select (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
                             from   ca_amortizacion, ca_concepto, ca_dividendo
                             where  di_operacion = am_operacion
                             and    di_dividendo = am_dividendo
                             and    di_estado    = @w_est_novigente
                             and    am_estado   <> @w_est_cancelado
                             and    am_concepto  = co_concepto 
                             and    am_operacion = operacion --o.operacion
                             and    co_categoria = 'I'), 0)                                    
--from #TMP_operaciones o  --LPO CDIG Se quita la tabla porque en MySql no se soporta la misma tabla en update from

   
--FiN AGI   

select 'op_toperacion'    = op_toperacion,
       'op_operacion'     = op_operacion,
       'op_banco'         = op_banco,
       'linea'            = (select c.valor 
                             from   cobis..cl_tabla t, cobis..cl_catalogo c 
                             where  t.codigo = c.tabla 
                             and    t.tabla  = 'ca_toperacion' 
                             and    c.codigo = o.op_toperacion),
       'op_monto'         = op_monto,
       'op_plazo'         = op_plazo,
       'saldo_capital'    = saldo_capital,
       'saldo_interes'    = saldo_interes,
       'saldo_mora'       = saldo_mora,
       'saldo_otros'      = saldo_otros,
       'plazo_residual'   = (select count(1) 
                             from   ca_dividendo 
                             where  di_estado in (@w_est_vigente,@w_est_novigente) 
                             and    di_operacion = o.op_operacion),
       'op_estado'        = op_estado,
       'moneda'           = o.op_moneda, --(select mo_nemonico from cobis..cl_moneda where mo_moneda = convert(char(10),o.op_moneda)),
       'cuotas_vencidas'  = (select count(1) from ca_dividendo where di_estado = @w_est_vencido and di_operacion = o.op_operacion),
       'op_cliente'       = op_cliente,
       'op_nombre'        = op_nombre,
	   --'op_tramite'       = convert(varchar(MAX),op_tramite)  -- GGU   8/12/2019
	   'op_tramite'       = convert(varchar,op_tramite)  -- GGU   8/12/2019
from   ca_operacion o,  #TMP_operaciones
where  op_operacion = operacion 


if @@rowcount = 0  
begin
    select @w_error = 710201
    goto ERROR
end

return 0

ERROR:
exec cobis..sp_cerror 
@t_debug = 'N', 
@t_file = null,
@t_from = 'sp_qr_renova_opera',
@i_num  = @w_error
return @w_error 




GO


