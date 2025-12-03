/* ********************************************************************* */
/*   ARCHIVO:         lcr_gen_div.sp                                     */
/*   NOMBRE LOGICO:   sp_lcr_gen_dividendos                              */
/*   Base de datos:   cob_cartera                                        */
/*   PRODUCTO:        Cartera                                            */
/*   Fecha de escritura:   Enero 2019                                    */
/* ********************************************************************* */
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante legal.            */
/* ********************************************************************* */
/*                     PROPOSITO                                         */
/*  Crea un tabla temporal de dividendos para las operaciones LCR,       */
/*  En LCR las operaciones que son canceladas antes del vencimiento no   */
/*  crean dividendos                                                     */
/* ********************************************************************* */
/*                             MODIFICACION                              */
/*    FECHA                 AUTOR                 RAZON                  */
/*    10/Ene/2018           TBA                   Emisión Inicial        */
/* ********************************************************************* */

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_lcr_gen_dividendos')
    drop proc sp_lcr_gen_dividendos
go
create proc sp_lcr_gen_dividendos (
    @i_fecha           datetime, --FECHA PROCESO
	@i_cortes          int,
	@i_operacionca     int = null,
	@i_debug           char(1) = 'N'    
)
as 
declare
@w_fecha           datetime,
@w_est_novigente   int,
@w_est_vigente     int,
@w_est_vencido     int,
@w_est_cancelado   int,
@w_error           int,
@w_ciudad_nacional int,
@w_secuencial      int,
@w_fecha_ini       datetime,
@w_fecha_fin       datetime,
@w_utilizacion     money,
@w_pago            money,
@w_operacionca     int,
@w_fecha_des       datetime,
@w_dias_gracia     int,
@w_cont            int,
@w_semana          int,
@w_mes             int,
@w_q_par           int,
@w_q_impar         int,
@w_count           int

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select @w_dias_gracia = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'LCRGRA'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

exec @w_error    = sp_estados_cca
@o_est_novigente = @w_est_novigente out,
@o_est_vigente   = @w_est_vigente   out,
@o_est_vencido   = @w_est_vencido   out,
@o_est_cancelado = @w_est_cancelado out

create table #cortes (semana int, q_par int, q_impar int, mes int, fecha datetime)

select @i_fecha = isnull(@i_fecha, fp_fecha)
from cobis..ba_fecha_proceso

/* GENERAR TABLA CON CORTES DIARIOS */
select 
@w_fecha         = @i_fecha,
@w_semana        = 0,
@w_q_par         = 0,
@w_q_impar       = 0,
@w_mes           = 0

if @i_debug = 'S' select 'FECHA PROCESO ', @i_fecha

while @w_fecha > dateadd(dd, -380, @i_fecha) begin

   if datepart(dw,@i_fecha) = datepart(dw,@w_fecha)                        select @w_semana = @w_semana + 1
   if datepart(dw,@i_fecha) = datepart(dw,@w_fecha) and @w_semana % 2 =  0 select @w_q_par  = @w_q_par  + 1
   if datepart(dw,@i_fecha) = datepart(dw,@w_fecha) and @w_semana % 2 <> 0 select @w_q_impar= @w_q_impar+ 1
   if datepart(dd,@i_fecha) = datepart(dd,@w_fecha)                        select @w_mes    = @w_mes    + 1

   insert into #cortes values (@w_semana, @w_q_par, @w_q_impar, @w_mes, @w_fecha)

   select @w_fecha = dateadd(dd,-1,@w_fecha)
end



if object_id('tempdb..#dividendos') is null

create table #dividendos(
periodicidad       int,
dia_fijo           int,
evitar_feriados    char(1),
par                char(2),
fecha_ini          datetime,
fecha_fin          datetime,
semana             int,
q_par              int,
q_impar            int,
mes                int,
procesar           char(1))

delete #dividendos



insert into #dividendos
select distinct
periodicidad       = td_factor*op_periodo_int,
dia_fijo           = op_dia_fijo,
evitar_feriados    = op_evitar_feriados,
par                = 'NO',
fecha_ini          = case when td_factor*op_periodo_int = 30 then dateadd(mm,-1,fecha) else dateadd(dd,-1*td_factor*op_periodo_int,fecha) end,
fecha_fin          = fecha,
semana             = semana,
q_par              = q_par,
q_impar            = q_impar,
mes                = mes,
procesar           = 'N'
from ca_operacion, ca_tdividendo, #cortes
where op_tdividendo  = td_tdividendo
and   op_toperacion  = 'REVOLVENTE'
and   @i_fecha    between op_fecha_ini and op_fecha_fin

insert into #dividendos
select 
periodicidad, dia_fijo,  evitar_feriados,
'SI',         fecha_ini, fecha_fin,
semana,       q_par,     q_impar,
mes,          procesar 
from #dividendos
where periodicidad = 14

/* MARCAR LAS FECHAS DE LAS OPERACIONES SEMANALES */
update #dividendos set
procesar = 'S'
where datepart(dw, fecha_fin) = dia_fijo+1
and   periodicidad = 7

/* MARCAR LAS FECHAS DE LAS OPERACIONES MENSUALES */
update #dividendos set
procesar = 'S'
where datepart(dd, fecha_fin) = dia_fijo
and periodicidad = 30

/* MARCAR LAS FECHAS DE LAS CATORCENALES PARES */
update #dividendos set
procesar = 'S'
where datepart(dw, fecha_fin) = dia_fijo+1
and periodicidad = 14
and par          = 'SI'
and semana % 2   = 0

/* MARCAR LAS FECHAS DE LAS CATORCENALES IMPARES */
update #dividendos set
procesar = 'S'
where datepart(dw, fecha_fin) = dia_fijo+1
and periodicidad = 14
and par          = 'NO'
and semana % 2  <> 0

/* ELIMINAR REGISTROS EN QUE NO EXISTAN DIVIDENDOS */
delete #dividendos where procesar = 'N'

/* EVITAR FERIADOS */
while 1=1 begin
   update #dividendos set
   fecha_fin = dateadd(dd,1,fecha_fin)
   from cobis..cl_dias_feriados
   where df_ciudad = @w_ciudad_nacional  
   and   df_fecha  = fecha_fin
   and   evitar_feriados = 'S'
   if @@rowcount = 0 break
end

while 1=1 begin
   update #dividendos set
   fecha_ini = dateadd(dd,1,fecha_ini)
   from cobis..cl_dias_feriados
   where df_ciudad = @w_ciudad_nacional  
   and   df_fecha  = fecha_ini
   and   evitar_feriados = 'S'
   
   if @@rowcount = 0 break
   
end




if object_id('tempdb..#prestamos_lcr') is not null  drop table #prestamos_lcr


/* DETERMINAR LOS PRESTAMOS QUE DEBEN SER PROCESADOS EL DIA DE CORTE */
select distinct
operacion       = op_operacion,
banco           = op_banco,
cliente         = op_cliente,
tramite         = op_tramite,
monto_aprobado  = op_monto_aprobado,
id_inst_proceso = convert(int,0),
primer_ven      = op_fecha_pri_cuot,
fecha_des       = convert(datetime, null),
periodicidad    = td_factor*op_periodo_int,
dia_fijo        = op_dia_fijo,
evitar_feriados = op_evitar_feriados,
par             = case when td_factor*op_periodo_int = 14 then 'X' else 'NO' end -- si es catorcenal no sabemos si es par o impar
into #prestamos_lcr
from ca_operacion, ca_tdividendo
where op_toperacion   = 'REVOLVENTE'
and   op_tdividendo   = td_tdividendo
and   op_operacion    = isnull(@i_operacionca, op_operacion)
and   op_operacion    > 0

update #prestamos_lcr
set id_inst_proceso = io_id_inst_proc
from cob_workflow..wf_inst_proceso
where tramite = io_campo_3

if @i_debug = 'S' select '1',* from #prestamos_lcr

if object_id('tempdb..#primer_ven') is not null  drop table #primer_ven

/* DETERMINAR LA FECHA DE PRIMER DESEMBOLSO */
select 
pv_operacion       = tr_operacion,
pv_fecha_des       = min(tr_fecha_ref)
into #primer_ven
from ca_transaccion, #prestamos_lcr
where tr_operacion  =  operacion
and   tr_tran       =  'DES'
and   tr_estado     <> 'RV'
and   tr_secuencial >  0
group by tr_operacion, periodicidad, dia_fijo,evitar_feriados

if @i_debug = 'S' select '2',* from #primer_ven

/* ACTUALIZAR EN LA TABLA DE TRABAJO, LA FECHA DE PRIMER VENCIMIENTO */
update #prestamos_lcr set
fecha_des  = pv_fecha_des
from #primer_ven
where operacion = pv_operacion


update p set 
p.par = d.par
from #prestamos_lcr p, #dividendos d
where d.periodicidad    = p.periodicidad
and   d.dia_fijo        = p.dia_fijo
and   d.evitar_feriados = p.evitar_feriados
and   d.periodicidad    = 14
and   d.fecha_fin       = p.primer_ven

/* NO CONSIDERAR LOS PRESTAMOS SIN DESEMBOLSOS */
delete #prestamos_lcr 
where primer_ven is null

if object_id('tempdb..#prestamos_dividendos') is  null  
    create table #prestamos_dividendos(
    secuencial     int IDENTITY(1,1),
    operacion      int, 
    banco          cuenta,
    cliente        int,
    monto_aprobado money,
    id_inst_proceso int,
    fecha_ini      datetime,
    fecha_fin      datetime,
    fecha_des      datetime,
    utilizacion    money,
    pagos           money,
    diferencia     money
 )
	

--SEMANAL
	
insert into #prestamos_dividendos
select  
operacion       = p.operacion, 
banco           = banco,
cliente         = cliente,
monto_aprobado  = monto_aprobado,
id_inst_proceso = id_inst_proceso,
fecha_ini       = case when d.fecha_fin = p.primer_ven then dateadd(dd,-1,p.fecha_des) else d.fecha_ini end,
fecha_fin       = d.fecha_fin,
fecha_des       = p.fecha_des,
utilizacion     = convert(money,0),
pagos           = convert(money,0),
diferencia      = convert(money,0)
from #prestamos_lcr p, #dividendos d
where p.periodicidad       = d.periodicidad
and   p.dia_fijo           = d.dia_fijo
and   p.evitar_feriados    = d.evitar_feriados
and   p.par                = d.par
and   p.periodicidad       = 7
and   d.semana             <= @i_cortes
and   d.fecha_fin          >= p.primer_ven
order by fecha_fin desc 



--BISEMANAL IMPAR 

	
insert into #prestamos_dividendos
select  
operacion       = p.operacion, 
banco           = banco,
cliente         = cliente,
monto_aprobado  = monto_aprobado,
id_inst_proceso = id_inst_proceso,
fecha_ini       = case when d.fecha_fin = p.primer_ven then dateadd(dd,-1,p.fecha_des) else d.fecha_ini end,
fecha_fin       = d.fecha_fin,
fecha_des       = p.fecha_des,
utilizacion     = convert(money,0),
pagos           = convert(money,0),
diferencia      = convert(money,0)
from #prestamos_lcr p, #dividendos d
where p.periodicidad       = d.periodicidad
and   p.dia_fijo           = d.dia_fijo
and   p.evitar_feriados    = d.evitar_feriados
and   p.par                = d.par
and   p.periodicidad       = 14
and   p.par                = 'N'  
and   d.q_impar            <= @i_cortes
and   d.fecha_fin          >= p.primer_ven
order by fecha_fin desc 


--BISEMANAL PAR 

	
insert into #prestamos_dividendos
select  
operacion       = p.operacion, 
banco           = banco,
cliente         = cliente,
monto_aprobado  = monto_aprobado,
id_inst_proceso = id_inst_proceso,
fecha_ini       = case when d.fecha_fin = p.primer_ven then dateadd(dd,-1,p.fecha_des) else d.fecha_ini end,
fecha_fin       = d.fecha_fin,
fecha_des       = p.fecha_des,
utilizacion     = convert(money,0),
pagos           = convert(money,0),
diferencia      = convert(money,0)
from #prestamos_lcr p, #dividendos d
where p.periodicidad       = d.periodicidad
and   p.dia_fijo           = d.dia_fijo
and   p.evitar_feriados    = d.evitar_feriados
and   p.par                = d.par
and   p.periodicidad       = 14
and   p.par                = 'S'  
and   d.q_par              <= @i_cortes
and   d.fecha_fin          >= p.primer_ven
order by fecha_fin desc 


--MENSUAL 

insert into #prestamos_dividendos
select  
operacion       = p.operacion, 
banco           = banco,
cliente         = cliente,
monto_aprobado  = monto_aprobado,
id_inst_proceso = id_inst_proceso,
fecha_ini       = case when d.fecha_fin = p.primer_ven then dateadd(dd,-1,p.fecha_des) else d.fecha_ini end,
fecha_fin       = d.fecha_fin,
fecha_des       = p.fecha_des,
utilizacion     = convert(money,0),
pagos           = convert(money,0),
diferencia      = convert(money,0)
from #prestamos_lcr p, #dividendos d
where p.periodicidad       = d.periodicidad
and   p.dia_fijo           = d.dia_fijo
and   p.evitar_feriados    = d.evitar_feriados
and   p.par                = d.par
and   p.periodicidad       = 30
and   d.mes                <= @i_cortes
and   d.fecha_fin          >= p.primer_ven
order by fecha_fin desc




if @i_debug = 'S' select '3',* from #prestamos_lcr 
if @i_debug = 'S' select '3.1',* from #dividendos where periodicidad = 7 and dia_fijo = 2 and evitar_feriados = 'S' and par = 'NO' order by fecha_fin

if @i_debug = 'S' select '3.2',* from #prestamos_dividendos


select 
operacion   = p.operacion,
secuencial  = secuencial,
utilizacion = sum (dtr_monto)
into #trn_des
from #prestamos_dividendos p, ca_transaccion, ca_det_trn
where tr_operacion  = dtr_operacion 
and   tr_secuencial = dtr_secuencial
and   tr_tran = 'DES' 
and   tr_fecha_ref  >= fecha_ini  
and   tr_fecha_ref  < fecha_fin
and   tr_estado     <> 'RV'
and   tr_secuencial >  0
and   dtr_concepto  = 'CAP'
and   tr_operacion  = p.operacion
group by operacion, secuencial

if @i_debug = 'S' select '4',* from #trn_des


select 
operacion   = p.operacion,
secuencial  = secuencial,
pagos       = sum (dtr_monto)
into #trn_pag
from #prestamos_dividendos p, ca_transaccion, ca_det_trn
where tr_operacion  = dtr_operacion 
and   tr_secuencial = dtr_secuencial
and   tr_tran = 'PAG' 
and   tr_fecha_ref  > fecha_ini  
and   tr_fecha_ref <= fecha_fin
and   tr_estado     <> 'RV'
and   tr_secuencial >  0
and   dtr_concepto  = 'CAP'
and   tr_operacion  = p.operacion
group by operacion, secuencial


if @i_debug = 'S' select '5',* from #trn_pag


update p set
utilizacion = t.utilizacion
from #prestamos_dividendos p, #trn_des t	
where p.operacion = t.operacion
and p.secuencial = t.secuencial


update p set
pagos       = t.pagos,
diferencia  = p.utilizacion - t.pagos
from #prestamos_dividendos p, #trn_pag t	
where p.operacion = t.operacion
and  p.secuencial = t.secuencial


if @i_debug = 'S' select '6',* from #prestamos_dividendos order by fecha_fin




return 0
GO

