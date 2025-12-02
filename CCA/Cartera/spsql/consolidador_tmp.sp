/************************************************************************/
/*   Archivo:             consolidador_tmp.sp                           */
/*   Stored procedure:    sp_tmp_113319                    */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez                                 */
/*   Fecha de escritura:  JUL.2013                                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Extraccion de datos para el consolidador y dejarlos en un atabla   */
/*   temporal  ca_dato_operacion_113319                                 */
/************************************************************************/
/*                               MODIFICACIONES                         */
/*  FECHA              AUTOR          CAMBIO                            */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_dato_operacion_113319')
   drop table  ca_dato_operacion_113319
go

create table ca_dato_operacion_113319 (
dot_fecha                   datetime         null,
dot_operacion               int              null,
dot_banco                   varchar   (24)   null,
dot_toperacion              varchar   (10)   null,
dot_aplicativo              tinyint          null,
dot_destino_economico       varchar   (10)   null,
dot_clase_cartera           varchar   (10)   null,
dot_cliente                 int              null,
dot_documento_tipo          varchar   (2 )   null,
dot_documento_numero        varchar   (24)   null,
dot_oficina                 int              null,
dot_moneda                  tinyint          null,
dot_monto                   money            null,
dot_tasa                    float            null,
dot_modalidad               char      (1 )   null,
dot_plazo_dias              int              null,
dot_fecha_desembolso        datetime         null,
dot_fecha_vencimiento       datetime         null,
dot_edad_mora               int              null,
dot_reestructuracion        char      (1 )   null,
dot_fecha_reest             datetime         null,
dot_nat_reest               varchar   (10)   null,
dot_num_reest               tinyint          null,
dot_num_renovaciones        int              null,
dot_estado                  tinyint          null,
dot_cupo_credito            varchar   (24)   null,
dot_num_cuotas              smallint         null,
dot_periodicidad_cuota      smallint         null,
dot_valor_cuota             money            null,
dot_cuotas_pag              smallint         null,
dot_cuotas_ven              smallint         null,
dot_saldo_ven               money            null,
dot_fecha_prox_vto          datetime         null,
dot_fecha_ult_pago          datetime         null,
dot_valor_ult_pago          money            null,
dot_fecha_castigo           datetime         null,
dot_num_acta                varchar   (24)   null,
dot_clausula                char      (1 )   null,
dot_oficial                 smallint         null,
dot_naturaleza              varchar   (2 )   null,
dot_fuente_recurso          varchar   (10)   null,
dot_categoria_producto      varchar   (10)   null,
dot_valor_mora              money            null, --va todo el valor vencido
dot_tipo_garantias          char      (1 )   null,
dot_op_anterior             varchar   (24)   null,
dot_edad_cod                tinyint          null,
dot_num_cuotas_reest        tinyint          null,
dot_tramite                 int              null,
dot_nota_int                tinyint          null,
dot_fecha_ini_mora          datetime         null,
dot_gracia_mora             smallint         null,
dot_estado_cobranza         catalogo         null,
dot_tasa_mora               float            null,
dot_tasa_com                float            null,
dot_entidad_convenio        varchar   (10)   null,
dot_fecha_cambio_linea      datetime         null,
dot_valor_nominal           money            null,
dot_emision                 varchar   (20)   null,
dot_sujcred                 varchar   (10)   null
)
go

if exists (select 1 from sysobjects where name = 'sp_tmp_113319')
   drop proc sp_tmp_113319
go
---INC. 113319 JUL.31.2013
CREATE proc sp_tmp_113319
   
as declare
   @w_error                 int,
   @w_sp_name               varchar(64),
   @w_fecha_proceso         smalldatetime,
   @w_fecha_ini             smalldatetime,   
   @w_fecha_ven             smalldatetime,   
   @w_msg                   varchar(64),
   @w_rubro_int             char(3),
   @w_est_vigente           tinyint,
   @w_est_vencido           tinyint,
   @w_est_cancelado         tinyint,
   @w_est_suspenso          tinyint,
   @w_est_castigado         tinyint,
   @w_est_diferido          tinyint,
   @w_fecha_fm              datetime,
   @w_ciudad                int,
   @w_sig_habil             datetime,
   @w_fin_mes               char(1),
   @w_dias_gracia_reest     tinyint,   --Nuevo Desarrollo Control de Cambio Reest
   @w_rubro_cap             catalogo,
   @w_concepto_rec_fng      varchar(30),
   @w_concepto_rec_usa      varchar(30),
   @w_cod_gar_esp           varchar(30),
   @w_cod_gar_fng           varchar(30),
   @w_cod_gar_usaid         varchar(30)   
   
set ansi_warnings off

/* CARGADO DE VARIABLES DE TRABAJO */
select 
@w_sp_name = 'sp_tmp_113319',
@w_fin_mes = 'N'

/*DETERMINAR LA FECHA DE PROCESO */
select 
@w_fecha_proceso = fc_fecha_cierre,
@w_fecha_ini     = dateadd(dd,1-datepart(dd,fc_fecha_cierre), fc_fecha_cierre)
from cobis..ba_fecha_cierre
where fc_producto = 7

-- Codigo padre para garantias colaterales
select @w_cod_gar_esp = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'GARESP'

---parametro para el cargue de los reconocimientos
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'

select @w_cod_gar_usaid = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and pa_nemonico = 'CODUSA'


select tc_tipo as tipo_sub 
into #colaterales
from cob_custodia..cu_tipo_custodia
where tc_tipo_superior = @w_cod_gar_esp
and   tc_tipo in (@w_cod_gar_fng,@w_cod_gar_usaid)

select @w_concepto_rec_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'RECFNG'

select @w_concepto_rec_usa = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'RECUSA'

/* CIUDAD DE FERIADOS */
select @w_ciudad = pa_int
from cobis..cl_parametro
where pa_nemonico = 'CIUN'
and   pa_producto = 'ADM'

select @w_fecha_fm = '01/01/1900'

/* PARAMETRO GENERAL INTERES */
select @w_rubro_int = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INT'

if @@rowcount = 0 begin
   select 
   @w_error = 724504, 
   @w_msg   = 'NO EXISTE EL PARAMETRO GENERAL "INT" PARA CARTERA'
   goto ERROR
end

select @w_rubro_cap = pa_char
from   cobis..cl_parametro 
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'

if @@rowcount = 0 begin
   select 
   @w_error = 710076, 
   @w_msg   = 'NO EXISTE EL PARAMETRO GENERAL "CAP" PARA CARTERA'
   goto ERROR
end

/* DETERMINAR SI HOY ES EL ULTIMO HABIL DEL MES */
select @w_sig_habil = dateadd(dd, 1, @w_fecha_proceso)

while exists (select 1
                  from cobis..cl_dias_feriados
                  where df_fecha = @w_sig_habil
                  and   df_ciudad = @w_ciudad)
begin
   select @w_sig_habil = dateadd(dd, 1, @w_sig_habil)
end

if datepart(mm, @w_sig_habil) <> datepart(mm, @w_fecha_proceso)
   select @w_fin_mes = 'S'

/* PARAMETRO GENERAL PARA DIAS DE REESTRUCTURACION */
select @w_dias_gracia_reest = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'DIASGR'
and    pa_producto = 'CRE'

if @w_dias_gracia_reest is null 
   select @w_dias_gracia_reest = 10


delete ca_dato_operacion_113319 WHERE dot_operacion >= 0

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_diferido   = @w_est_diferido  out

if @w_error <> 0 goto ERROR

/* CARGA DE OPERACIONES ACTIVAS */
select  
cop_fecha              =  @w_fecha_proceso,
cop_operacion          =  op_operacion,   
cop_banco              =  convert(varchar(24),op_banco),             
cop_toperacion         =  convert(varchar(10),op_toperacion),  
cop_aplicativo         =  convert(tinyint,7),           
cop_destino            =  convert(varchar(10),op_destino),                   
cop_clase              =  convert(varchar,op_clase),                    
cop_cliente            =  op_cliente,  
cop_documento_tipo     =  convert(varchar,null),
cop_documento_nume     =  convert(varchar,null),              
cop_oficina            =  convert(int,op_oficina),                
cop_moneda             =  op_moneda,                  
cop_monto              =  op_monto,  
cop_tasa               =  convert(float,0),
cop_modalidad          =  convert(char(1),'V'),
cop_plazo_dias         =  convert(int,op_plazo * (select td_factor from ca_tdividendo where td_tdividendo = op_tplazo)),                     
cop_fecha_liq          =  op_fecha_liq,               
cop_fecha_fin          =  op_fecha_fin,  
cop_edad_mora          =  0,             
cop_reestructuracion   =  convert(char(1),case when isnull(op_numero_reest,0) > 0 then 'S'          else 'N'  end), 
cop_fecha_reest        =  case when isnull(op_numero_reest,0) > 0 then op_fecha_ini else null end,
cop_natur_reest        =  convert(varchar,null),
cop_num_reest          =  convert(tinyint,isnull(op_numero_reest,0)), 
cop_num_renovacion     =  convert(int,isnull(op_num_renovacion,0)),
cop_estado             =  op_estado, --case op_estado when 3 then 4 when 4 then 3 else 1 end,   
cop_cupo_credito       =  convert(varchar,op_lin_credito),
cop_num_cuotas         =  op_plazo,
cop_per_cuotas         =  op_periodo_int * (select td_factor from ca_tdividendo where td_tdividendo = op_tdividendo),
cop_val_cuota          =  op_cuota,
cop_cuotas_pag         =  convert(smallint,0),
cop_cuotas_ven         =  convert(smallint,0),
cop_saldo_ven          =  convert(money,0),
cop_fecha_prox_vto     =  op_fecha_fin,
cop_fecha_ult_pago     =  convert(datetime,null),
cop_valor_ult_pago     =  convert(money,0),
cop_fecha_castigo      =  convert(datetime,case when op_estado = @w_est_castigado then '10/14/2008' else null end),
cop_num_acta           =  convert(varchar,null),
cop_clausula           =  isnull(op_clausula_aplicada,'N'),
cop_oficial            =  op_oficial,
cop_naturaleza         =  case when op_naturaleza = 'A' and op_tipo <> 'G' then '1' 
                               when op_naturaleza = 'A' and op_tipo =  'G' then '3'
                               else '2'
                          end,
cop_fuente_recurso     = (select b.codigo from cobis..cl_tabla a, cobis..cl_catalogo b
                          where a.tabla = 'ca_homo_fuente_recursos'
                          and   b.tabla = a.codigo
                          and   op_tipo_linea = valor
                         ),
cop_categoria_producto =  '1',
cop_valor_vencido      =  convert(money, 0),
cop_tipo_garantias     =  case when isnull(op_gar_admisible,'N') = 'N' then 'O' else 'E' end,
cop_op_anterior        =  op_anterior,
cop_edad_cod           =  convert(tinyint, 0),
cop_num_cuotas_reest   =  convert(tinyint, 0),
cop_tramite            =  op_tramite,
/* INI - GAL 01/AGO/2010 - OMC */
cop_nota_int              =  convert(tinyint, null),
cop_fecha_ini_mora        =  convert(datetime, null),
cop_gracia_mora           =  convert(smallint, null),
cop_estado_cobranza       =  op_estado_cobranza,
cop_tasa_mora             =  convert(float, null),
cop_tasa_com              =  convert(float, null),
/* FIN - GAL 01/AGO/2010 - OMC */
cop_entidad_convenio      = op_entidad_convenio,
cop_fecha_cambio_linea    = @w_fecha_proceso,
cop_valor_nominal         = 0.00,
cop_emision               = ' ',
cop_sujcred               = (select tr_sujcred from cob_credito..cr_tramite
							where tr_numero_op = op_operacion 
							and tr_tramite = (select max(tr_tramite) from cob_credito..cr_tramite
     				 							where tr_numero_op = op_operacion) 
                                				and tr_fecha_apr is not null )
into #operaciones_113319
from ca_operacion, ca_estado
where op_estado   = es_codigo
and  (es_procesa  = 'S' 
      --> OPERACIONES CANCELADAS DURANTE EL MES DE PROCESO
      or (op_estado=@w_est_cancelado and op_fecha_ult_proceso between @w_fecha_ini and @w_fecha_proceso)     
      
      --> OPERACIONES CANCELADAS DURANTE EL MES DE PROCESO CON FECHA VALOR A MESES ANTERIORES)
      or (op_estado=@w_est_cancelado and op_fecha_ult_proceso < @w_fecha_ini and op_fecha_ult_mov between @w_fecha_ini and @w_fecha_proceso)
     )     
create index idx1 on #operaciones_113319(cop_operacion)
create index idx2 on #operaciones_113319(cop_banco)

/* NO REPORTA OPERACIONES QUE FUERON CANCELADAS EN MESES ANTERIORES Y QUE VOLVIERON A SER CANCELADAS EN EL MES DE PROCESO POR FECHA VALOR */
select op_banco,  op_fecha_ult_mov, op_fecha_ult_proceso 
into #canceladas
from #operaciones_113319, cob_cartera..ca_operacion
where cop_estado = @w_est_cancelado
and   cop_banco  = op_banco
and   op_fecha_ult_proceso < @w_fecha_ini and op_fecha_ult_mov between @w_fecha_ini and @w_fecha_proceso

delete #operaciones_113319
from cob_conta_super..sb_dato_operacion, #canceladas
where do_banco = op_banco
and   do_fecha = op_fecha_ult_proceso 
and   cop_banco = op_banco
and   do_estado_cartera = @w_est_cancelado

---25045
select cop_banco, concepto = dif_concepto, 'valDiff' =sum(dif_valor_total - dif_valor_pagado ), adicionar='S'
into #diferidos
from #operaciones_113319, ca_diferidos
where cop_operacion = dif_operacion
group by cop_banco, dif_concepto
---25045

/* DETERMINAR LA TASA DE LA OPERACION*/
update #operaciones_113319 set
cop_tasa               =  ro_porcentaje_efa,
cop_modalidad          =  case ro_fpago when 'P' then 'V' else 'A' end
from ca_rubro_op
where ro_operacion = cop_operacion
and   ro_concepto  = @w_rubro_int
and   ro_fpago in ('A', 'P')

/* DETERMINAR LA FECHA DE REESTRUCTURACION */
select tr_operacion, tr_fecha_ref=max(tr_fecha_ref)
into #reest
from cob_cartera..ca_transaccion, #operaciones_113319
where tr_operacion = cop_operacion
and   tr_tran      = 'RES'
and   tr_estado   <> 'RV'
group by tr_operacion

update #operaciones_113319 set
cop_reestructuracion   =  'S', 
cop_fecha_reest        =  tr_fecha_ref
from #reest
where tr_operacion = cop_operacion

/* PARA OPERACIONES REESTRUCTURADAS, DETERMINAR EL MOTIVO DE LA REESTRUCTURACION */
update #operaciones_113319 set
cop_natur_reest        =  tr_motivo
from cob_credito..cr_tramite
where tr_numero_op = cop_operacion
and   tr_tipo      = 'E'
and   cop_reestructuracion = 'S'

/* DETERMINAR LA FECHA DEL PROXIMO VENCIMIENTO */
update #operaciones_113319 set
cop_fecha_prox_vto =  di_fecha_ven
from ca_dividendo
where di_operacion = cop_operacion
and   di_estado    = @w_est_vigente

/* DETERMINAR LA CANTIDAD DE CUOTAS VENCIDAS Y CANCELADAS */ 
select 
operacion  = di_operacion,
vencidas   = sum(case when di_estado = @w_est_vencido   then 1 else 0 end),
canceladas = sum(case when di_estado = @w_est_cancelado then 1 else 0 end)
into #resumen_cuotas
from ca_dividendo 
where di_estado in (@w_est_vencido, @w_est_cancelado)
group by di_operacion
  
update #operaciones_113319 set
cop_cuotas_pag =  canceladas,
cop_cuotas_ven =  vencidas
from #resumen_cuotas
where cop_operacion = operacion


/* DETERMINAR EL SALDO VENCIDO */
select 
operacion = am_operacion,
saldo_ven = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado))) / 2
into #saldo_ven
from ca_amortizacion, ca_dividendo 
where am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   di_estado  in (@w_est_vencido, @w_est_vigente)
group by am_operacion
    
update #operaciones_113319 set
cop_saldo_ven = saldo_ven
from #saldo_ven
where cop_operacion = operacion


/* DETERMINAR EL VALOR TOTAL VENCIDO */
select 
operacion = am_operacion,
tot_mora  = isnull(sum(am_cuota-am_pagado),0)
into #total_mora
from ca_amortizacion, ca_dividendo 
where am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   di_estado    = @w_est_vencido
group by am_operacion
    
update #operaciones_113319 set
cop_valor_vencido  = tot_mora
from #total_mora
where cop_operacion = operacion

/* DETERMINAR LA FECHA DE CASTIGO */
update #operaciones_113319 set
cop_fecha_castigo = tr_fecha_ref
from ca_transaccion 
where tr_operacion = cop_operacion
and   tr_tran      = 'CAS'
and   tr_estado   <> 'RV'
and   cop_estado   = @w_est_castigado

/* PARA LAS OPERACIONES MIGRADAS DE SICREDITO OBTENER LA FECHA DE CASTIGO DE LA CA_TRANSACCION_BANCAMIA */
update #operaciones_113319 set
cop_fecha_castigo = tr_fecha_mov
from ca_transaccion_bancamia 
where tr_banco     = cop_banco
and   tr_tran      = 'CAS'
and   tr_estado   <> 'RV'
and   cop_estado   = @w_est_castigado

/* DETERMINAR FECHA Y MONTO DEL ULTIMO PAGO */
select 
operacion  = ab_operacion, 
fecha      = max(ab_fecha_pag),
secuencial = 0
into #ult_pago
from  ca_abono, #operaciones_113319  
where ab_tipo = 'PAG'
and   ab_estado <> 'RV'
and   ab_operacion = cop_operacion 
group by  ab_operacion

select 
operacion  = operacion, 
fecha      = fecha,
secuencial = max(ab_secuencial_ing)
into #ult_pago_2
from ca_abono, #ult_pago
where ab_operacion = operacion
and   ab_fecha_pag = fecha
group by operacion, fecha

select 
operacion = operacion, 
fecha     = fecha,
monto     = sum(abd_monto_mop)
into #ult_pago_3
from ca_abono_det, #ult_pago_2
where abd_operacion      = operacion
and   abd_secuencial_ing = secuencial
group by operacion, fecha

update #operaciones_113319 set
cop_fecha_ult_pago  =  fecha,
cop_valor_ult_pago  =  monto
from #ult_pago_3
where cop_operacion = operacion

/* DIAS DE MORA */
select 
operacion = di_operacion,
fecha_ini = min(di_fecha_ven),
fecha_fin = @w_fecha_proceso
into #dias_mora
from ca_dividendo, #operaciones_113319
where di_estado = @w_est_vencido
and di_operacion = cop_operacion
and di_fecha_ven <  @w_fecha_proceso
group by di_operacion

update #operaciones_113319 set
cop_edad_mora  =  datediff(mm,fecha_ini,fecha_fin) * 30 + datediff(dd, dateadd(mm, datediff(mm,fecha_ini,fecha_fin), fecha_ini),   fecha_fin)
from #dias_mora
where cop_operacion = operacion

/* ACTUALIZACION PARA TEMPORALIDAD DIARIA */
update #operaciones_113319 set
cop_edad_cod  = ct_codigo 
from   cob_credito..cr_param_cont_temp
where  cop_clase           =  ct_clase
and    cop_edad_mora/30.0  >  case when ct_desde = 0 then -30000 else ct_desde end
and    cop_edad_mora/30.0  <= ct_hasta

/* OPERACIONES PARA CONTROL DE CUOTAS PAGADAS A TIEMPO DESDE LA FECHA DE REESTRUCTURACION*/
delete ca_fecha_reest_control
from #operaciones_113319
where cop_reestructuracion = 'N'
and   fr_operacion         = cop_operacion

update ca_fecha_reest_control set
fr_fecha = cop_fecha_reest
from #operaciones_113319
where cop_reestructuracion = 'S'
and   fr_operacion         = cop_operacion
and   fr_fecha             < cop_fecha_reest

insert into ca_fecha_reest_control
select cop_operacion, cop_fecha_reest
from #operaciones_113319
where cop_reestructuracion = 'S'
and   cop_operacion        not in (select fr_operacion from ca_fecha_reest_control)

select 
operacion = op_operacion, 
fecha     = fr_fecha
into #op_reest_1
from ca_operacion, ca_fecha_reest_control
where op_operacion = fr_operacion

select 
operacion     = di_operacion,
cuotas_total  = sum(case when di_fecha_ven > fecha and di_fecha_ven <= @w_fecha_proceso and di_fecha_ven > fecha then 1 else 0 end),
cuotas_can_ok = sum(case when di_estado = 3 and (dateadd(dd,@w_dias_gracia_reest,di_fecha_ven) >= di_fecha_can) and di_fecha_ven > fecha then 1 else 0 end),
cuotas_ven_ok = sum(case when di_estado = 2 and (dateadd(dd,@w_dias_gracia_reest,di_fecha_ven) >= @w_fecha_proceso) and di_fecha_ven > fecha then 1 else 0 end)
into #op_reest_2
from #op_reest_1, ca_dividendo
where di_operacion  = operacion
and   di_fecha_ven >  fecha 
and   di_fecha_ven <= @w_fecha_proceso
and   di_estado    <> 0
group by di_operacion

select 
operacion_di = di_operacion,
fecha_di     = max(dateadd(dd, 1, di_fecha_ven))
into #op_reest_3
from #op_reest_1, ca_dividendo
where di_operacion  = operacion
and   di_fecha_ven  >  fecha 
and   di_fecha_ven  <= @w_fecha_proceso
and   di_estado     = 2
group by di_operacion

update #operaciones_113319 set
cop_num_cuotas_reest =  case when cuotas_can_ok + cuotas_ven_ok >= cuotas_total then cuotas_can_ok else 0 end
from #op_reest_2
where cop_operacion = operacion

update ca_fecha_reest_control set
fr_fecha = case when cuotas_can_ok + cuotas_ven_ok >= cuotas_total then fr_fecha else @w_fecha_proceso end
from #op_reest_2
where operacion   = fr_operacion

update ca_fecha_reest_control set
fr_fecha = case when cuotas_can_ok + cuotas_ven_ok >= cuotas_total then fr_fecha else fecha_di end
from #op_reest_2, #op_reest_3
where operacion   = fr_operacion
and   operacion   = operacion_di

-- INI - GAL 27/JUL/2010
update #operaciones_113319 set 
cop_nota_int = ci_nota
from cob_credito..cr_califica_int_mod
where ci_banco = cop_banco

select 
operacion  = di_operacion,
dividendo  = min(di_dividendo)
into #min_dividendo
from ca_dividendo, #operaciones_113319
where di_estado    <> @w_est_cancelado
and   di_operacion  = cop_operacion
group by di_operacion

select 
operacion = di_operacion,
fecha_ven = di_fecha_ven,
gracia    = di_gracia
into #min_vto
from #min_dividendo, ca_dividendo
where di_operacion = operacion
and   di_dividendo = dividendo

update #operaciones_113319 set 
cop_fecha_ini_mora = fecha_ven,
cop_gracia_mora    = gracia
from #min_vto
where cop_operacion = operacion


update #operaciones_113319 set 
cop_tasa_mora = ro_porcentaje_efa
from ca_rubro_op
where ro_operacion = cop_operacion
and   ro_concepto  = 'IMO'

update #operaciones_113319 set 
cop_tasa_com  = ro_porcentaje
from ca_rubro_op
where ro_operacion = cop_operacion
and   ro_concepto  = 'MIPYMES'
-- FIN - GAL 27/JUL/2010 

--Actualizacion Fecha de Cambio de Linea (Control de Cambio 224 -Empleados)
update #operaciones_113319 set 
cop_fecha_cambio_linea = null

update #operaciones_113319 set
cop_fecha_cambio_linea = tl_fecha_traslado
from ca_traslado_linea
where tl_operacion = cop_operacion
and   tl_estado    = 'P'


/* REGISTRO DE LOS SALDOS DIARIOS DE LAS OPERACIONES EN ca_dato_operacion_113319 */
insert into ca_dato_operacion_113319
select * from #operaciones_113319
if @@error <> 0 begin
   select 
   @w_error = 724504, 
   @w_msg = 'Error en al Grabar en tabla ca_dato_operacion_113319'
   goto ERROR
end

return 0

ERROR:

exec sp_errorlog 
@i_fecha     = @w_fecha_proceso,
@i_error     = @w_error, 
@i_usuario   = 'sa', 
@i_tran      = 7999,
@i_tran_name = @w_sp_name,
@i_cuenta    = 'conso_tmp',
@i_anexo     = @w_msg,
@i_rollback  = 'S'

return @w_error

go


