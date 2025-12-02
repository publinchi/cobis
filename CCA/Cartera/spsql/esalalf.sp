/************************************************************************/
/*   Archivo:                 esalalf.sp                                */
/*   Stored procedure:        sp_esalalf                                */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Francisco Lopez                           */
/*   Fecha de Documentacion:  Julio 2009                                */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                         PROPOSITO                                    */
/*   Generar la informacion necesaria para reporte esalalf              */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA            AUTOR             RAZON                            */
/*                                 Emision Inicial                      */
/*  21/09/2017     Tania Baidal    Modificacion de estructura           */
/*                                 sb_dato_operacion                    */
/************************************************************************/

use cob_cartera
go 
if not object_id('tmp_esalalf') is null drop table tmp_esalalf
go

--INI AGI. 22ABR19.  Se comenta porque no se encuentra cob_conta_super..sb_dato_operacion
/* 
select 
tmp_oficina         = do_oficina,
tmp_letra           = convert(varchar(1),''),
tmp_cliente         = do_codigo_cliente,
tmp_nombre_cli      = convert(varchar(100),''),
tmp_operacion       = convert(int,0),
tmp_banco           = do_banco,
tmp_num_id          = convert(varchar(24),''),
tmp_subtipo         = convert(varchar(10),''),
tmp_fecha_ini       = do_fecha_concesion,
tmp_moneda          = do_moneda,
tmp_saldo_cap       = do_saldo_cap,
tmp_defecto_gar     = convert(money,0),
tmp_saldo_int       = do_saldo_int,
tmp_saldo_int_cont  = do_saldo_int_contingente,
tmp_saldo_imo       = convert(money,0),
tmp_saldo_imo_cont  = convert(money,0), 
tmp_prov_cap        = do_prov_cap,
tmp_prov_int        = do_prov_int,
tmp_prov_cxc        = do_prov_cxc,
tmp_fecha_prox_venc = isnull(do_fecha_prox_vto,'01/01/1900'),
tmp_dias_venc       = do_edad_mora,
tmp_calificacion    = isnull(do_calificacion,'A'),
tmp_dias_causados   = datediff(dd,do_fecha_concesion,do_fecha),
tmp_tasa_int        = do_tasa,
tmp_tipo_tabla      = convert(varchar(10),''),
tmp_clausula        = convert(varchar(1),''),
tmp_tipo_productor  = convert(varchar(64),''),
tmp_clase_cartera   = do_clase_cartera,
tmp_des_clase_car   = convert(varchar(64),''), 
tmp_fecha_ult_proc  = do_fecha,
tmp_toperacion      = convert(varchar(10),''),
tmp_tipo            = convert(varchar(10),''),
tmp_segvida         = convert(varchar(10),'N'),
tmp_segvehi         = convert(varchar(10),'N'),
tmp_max_vig_ven     = convert(int,0),   
tmp_seg_vid_vig     = convert(money,0),
tmp_seg_vig_ven     = convert(money,0),
tmp_seg_vid_sig     = convert(money,0),
tmp_seg_sig         = convert(money,0),
tmp_gas_jud         = convert(money,0),  
tmp_gas_otr         = convert(money,0) 
into tmp_esalalf
from cob_conta_super..sb_dato_operacion
where 1 = 2

*/  --FIN AGI
go




if exists(select 1 from cob_cartera..sysobjects where name = 'sp_esalalf')
   drop proc sp_esalalf
go



create proc sp_esalalf
   @i_fecha          varchar(10) = '',
   @i_banco          cuenta      = '',
   @i_oficina        int         = 0
as
declare 
   @w_conc_segvid    varchar(10),
   @w_conc_segveh    varchar(10),
   @w_cod_clase_car  int,
   @w_error          int,
   @w_est_vigente    tinyint,
   @w_est_vencido    tinyint,
   @w_est_suspenso   tinyint,
   @w_est_castigado  tinyint
       
	   
exec @w_error    = cob_externos..sp_estados
@i_producto      = 7,
@o_est_vencido   = @w_est_vencido   out,
@o_est_suspenso  = @w_est_suspenso   out,
@o_est_vigente   = @w_est_vigente   out,
@o_est_castigado = @w_est_castigado out
	   
if @i_fecha   = ''  select @i_fecha = null
if @i_banco   = ''  select @i_banco = null
if @i_oficina = 0   select @i_oficina = null


select @w_conc_segvid = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'SEGURO'

select @w_conc_segveh = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and pa_nemonico = ' SEGVEH'

select @w_cod_clase_car = codigo 
from cobis..cl_tabla 
where tabla = 'cr_clase_cartera'

if @i_fecha is null
   select @i_fecha = fp_fecha
   from cobis..ba_fecha_proceso

if not object_id('tmp_esalalf') is null drop table tmp_esalalf

--INI AGI. 22ABR19.  Se comenta porque no se encuentra cob_conta_super..sb_dato_operacion
/*
select 
tmp_oficina         = do_oficina,
tmp_letra           = convert(varchar(1),''),
tmp_cliente         = do_codigo_cliente,
tmp_nombre_cli      = convert(varchar(100),''),
tmp_operacion       = convert(int,0),
tmp_banco           = do_banco,
tmp_num_id          = convert(varchar(24),''),
tmp_subtipo         = convert(varchar(10),''),
tmp_fecha_ini       = do_fecha_concesion,
tmp_moneda          = do_moneda,
tmp_saldo_cap       = do_saldo_cap,
tmp_defecto_gar     = convert(money,0),
tmp_saldo_int       = do_saldo_int,
tmp_saldo_int_cont  = do_saldo_int_contingente,
tmp_saldo_imo       = convert(money,0),
tmp_saldo_imo_cont  = convert(money,0), 
tmp_prov_cap        = do_prov_cap,
tmp_prov_int        = do_prov_int,
tmp_prov_cxc        = do_prov_cxc,
tmp_fecha_prox_venc = isnull(do_fecha_prox_vto,'01/01/1900'),
tmp_dias_venc       = do_edad_mora,
tmp_calificacion    = isnull(do_calificacion,'A'),
tmp_dias_causados   = datediff(dd,do_fecha_concesion,do_fecha),
tmp_tasa_int        = do_tasa,
tmp_tipo_tabla      = convert(varchar(10),''),
tmp_clausula        = convert(varchar(1),''),
tmp_tipo_productor  = convert(varchar(64),''),
tmp_clase_cartera   = do_clase_cartera,
tmp_des_clase_car   = convert(varchar(64),''), 
tmp_fecha_ult_proc  = do_fecha,
tmp_toperacion      = convert(varchar(10),''),
tmp_tipo            = convert(varchar(10),''),
tmp_segvida         = convert(varchar(10),'N'),
tmp_segvehi         = convert(varchar(10),'N'),
tmp_max_vig_ven     = convert(int,0),   
tmp_seg_vid_vig     = convert(money,0),
tmp_seg_vig_ven     = convert(money,0),
tmp_seg_vid_sig     = convert(money,0),
tmp_seg_sig         = convert(money,0),
tmp_gas_jud         = convert(money,0),  
tmp_gas_otr         = convert(money,0) 
into tmp_esalalf
from cob_conta_super..sb_dato_operacion
where do_fecha          =  @i_fecha
and   do_aplicativo     = 7
and   do_estado_cartera in (1,2,4,8,9)
and   do_banco          =  isnull(@i_banco,do_banco)
and   do_oficina        =  isnull(@i_oficina,do_oficina)
and   do_clase_cartera  > 0
order by tmp_oficina,tmp_nombre_cli,tmp_cliente
if @@error <> 0 return 1

--Actualizar datos de la operacion
update tmp_esalalf
set tmp_operacion     = op_operacion,
    tmp_letra         = substring(ltrim(op_nombre),1,1),
    tmp_nombre_cli    = ltrim(rtrim(op_nombre)),
    tmp_toperacion    = op_toperacion,
    tmp_tipo_tabla    = op_tipo_amortizacion,
    tmp_clausula      = op_clausula_aplicada,
    tmp_tipo          = op_tipo,
    tmp_des_clase_car = (select valor from cobis..cl_catalogo
                         where tabla  = @w_cod_clase_car
                         and   codigo = tmp_clase_cartera)
from cob_cartera..ca_operacion
where op_banco = tmp_banco
and   op_tipo  not in ('P','G')
if @@error <> 0 return 1

--Actualizar datos del Cliente
update tmp_esalalf
set tmp_num_id  = en_ced_ruc,
    tmp_subtipo = en_subtipo
from cobis..cl_ente
where tmp_cliente = en_ente
if @@error <> 0 return 1

--Actualizar datos de credito
update tmp_esalalf
set tmp_defecto_gar = isnull(go_saldo,0) - isnull(go_cubierto,0)
from   cob_credito..cr_peso_rubro
where  go_operacion = tmp_operacion
if @@error <> 0 return 1

--Actualizar datos rubro op
update tmp_esalalf
set tmp_saldo_imo      = case when dr_estado = @w_est_vigente  then dr_valor else 0 end, 
    tmp_saldo_imo_cont = case when dr_estado = @w_est_suspenso then dr_valor else 0 end
from cob_conta_super..sb_dato_operacion_rubro
where dr_banco       = tmp_banco
and   dr_toperacion  = tmp_toperacion
and   dr_fecha       = tmp_fecha_ult_proc
and   dr_concepto    = 'IMO'
if @@error <> 0 return 1

--Tipo Productor
update tmp_esalalf
set tmp_tipo_productor = c.valor
from cob_credito..cr_tramite, cobis..cl_tabla t, cobis..cl_catalogo c
where tr_numero_op_banco = tmp_banco
and   t.codigo           = c.tabla
and   t.tabla            = 'cl_tipo_productor'
and   c.codigo           = tr_tipo_productor
if @@error <> 0 return 1

--Seguro de vida
update tmp_esalalf
set tmp_segvida = 'S'
from ca_rubro_op
where ro_operacion = tmp_operacion
and   ro_concepto  = @w_conc_segvid
if @@error <> 0 return 1

--Seguro de vehiculo
update tmp_esalalf
set tmp_segvehi = 'S'
from ca_rubro_op
where ro_operacion = tmp_operacion
and   ro_concepto  = @w_conc_segveh
if @@error <> 0 return 1

--Maximo Vigente/Vencido
select di_operacion, max_div=max(di_dividendo)
into #max_div
from ca_dividendo,tmp_esalalf
where di_operacion =  tmp_operacion
and   di_estado    in (1,2) 
group by di_operacion
if @@error <> 0 return 1

update tmp_esalalf
set tmp_max_vig_ven = max_div
from #max_div
where tmp_operacion = di_operacion
if @@error <> 0 return 1

drop table #max_div

--Seguros Vigente/Vencido
select am_operacion,
       seg_vid_vig = sum(case am_concepto 
                            when @w_conc_segvid then 
                               isnull(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end, 0)             -- &valor_segvida_vigente -- REQ 175: PEQUEÑA EMPRESA
                            else 0
                         end),
       seg_vig_ven = sum(case am_concepto 
                            when @w_conc_segvid then 0
                            else
                               isnull(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end, 0)             -- &valor_seguro_vigven   -- REQ 175: PEQUEÑA EMPRESA
                         end)
into #dat_vig_ven
from ca_dividendo,ca_amortizacion, ca_concepto, tmp_esalalf
where am_operacion  =  di_operacion
and   am_dividendo  =  di_dividendo
and   di_estado     in (1,2)
and   am_operacion  =  tmp_operacion
and   am_concepto   =  co_concepto
and   co_categoria  =  'S'
group by am_operacion
if @@error <> 0 return 1

update tmp_esalalf
set tmp_seg_vid_vig = seg_vid_vig,
    tmp_seg_vig_ven = seg_vig_ven
from #dat_vig_ven
where tmp_operacion = am_operacion
if @@error <> 0 return 1

drop table #dat_vig_ven

--Seguros Siguiente a Vigente/Vencido
select am_operacion,
       seg_vid_sig = sum(case am_concepto 
                            when @w_conc_segvid then 
                               isnull(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end, 0)             -- &valor_segvida_vigente -- REQ 175: PEQUEÑA EMPRESA
                            else 0
                         end),
       seg_sig     = sum(case am_concepto 
                            when @w_conc_segvid then 0
                            else
                               isnull(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end, 0)             -- &valor_seguro_vigven   -- REQ 175: PEQUEÑA EMPRESA
                         end)
into #dat_sig
from ca_dividendo,ca_amortizacion, ca_concepto, tmp_esalalf
where am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   di_dividendo = tmp_max_vig_ven + 1
and   am_operacion = tmp_operacion
and   am_concepto  = co_concepto
and   co_categoria = 'S'
group by am_operacion
if @@error <> 0 return 1

update tmp_esalalf
set tmp_seg_vid_sig = seg_vid_sig,
    tmp_seg_sig     = seg_sig
from #dat_sig
where tmp_operacion = am_operacion
if @@error <> 0 return 1

drop table #dat_sig

--Gastos Judiciales
select am_operacion,
       gas_jud = isnull(sum(am_acumulado  - am_pagado),0)
into #gas_jud
from ca_amortizacion, ca_concepto, tmp_esalalf
where am_operacion    = tmp_operacion
and   co_concepto     = am_concepto
and   co_categoria    = 'H'   
and   am_estado       <> 3
group by am_operacion
if @@error <> 0 return 1

update tmp_esalalf
set tmp_gas_jud = gas_jud
from #gas_jud
where tmp_operacion = am_operacion
if @@error <> 0 return 1

drop table #gas_jud

--Gastos Otros
select am_operacion,
       gas_otros = isnull(sum(am_acumulado  - am_pagado),0)
into #gas_otros
from ca_amortizacion, ca_concepto, tmp_esalalf
where am_operacion   =  tmp_operacion
and   co_concepto    =  am_concepto
and   co_categoria   in ('G','R')
and   am_estado      <> 3
group by am_operacion
if @@error <> 0 return 1

update tmp_esalalf
set tmp_gas_otr = gas_otros
from #gas_otros
where tmp_operacion = am_operacion
if @@error <> 0 return 1

drop table #gas_otros
*/  --FIN AGI
return 0
go

