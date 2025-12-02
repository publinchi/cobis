/* OJO FALTA CANAL EN cob_externos..ex_dato_transaccion */
/************************************************************************/
/*   Archivo:             consolidador_his.sp                           */
/*   Stored procedure:    sp_consolidador_his                           */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Ricardo Reyes                                 */
/*   Fecha de escritura:  Abr.09.                                       */
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
/*   Extraccion de datos para el consolidador ex_dato_operacion         */
/*  ABR-2017         TANIA BAIDAL     CL_ENTE_AUX POR CL_ENTE_ADICIONAL */
/************************************************************************/

use cob_cartera_his
go
 
if exists (select 1 from sysobjects where name = 'sp_consolidador_his')
   drop proc sp_consolidador_his
go

CREATE proc sp_consolidador_his
   
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
   @w_est_diferido          tinyint  
   

/* CARGADO DE VARIABLES DE TRABAJO */
select @w_sp_name = 'sp_consolidador_his'

/*DETERMINAR LA FECHA DE PROCESO */
select 
@w_fecha_proceso = fc_fecha_cierre,
@w_fecha_ini     = dateadd(dd,1-datepart(dd,fc_fecha_cierre), fc_fecha_cierre)
from cobis..ba_fecha_cierre
where fc_producto = 7


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

/* ESTADOS DE CARTERA */
exec @w_error = cob_cartera..sp_estados_cca
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
cop_plazo_dias         =  convert(int,op_plazo * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = op_tplazo)),                     
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
cop_per_cuotas         =  op_periodo_int * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = op_tdividendo),
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
cop_fuente_recurso     =  case when op_tipo_linea = '221' then '1'
                               when op_tipo_linea = '999' then '2'
                               when op_tipo_linea = '400' then '3'
                          end,
cop_categoria_producto =  '1',
cop_cap_mora           =  convert(money, 0),
cop_tipo_garantias     =  case when isnull(op_gar_admisible,'N') = 'N' then 'O' else 'E' end,
cop_op_anterior        =  op_anterior,
cop_emproblemado       = convert(char, null),
cop_dias_mora_ant      = convert(int, null),
cop_grupal             = convert(char, null)
into #operaciones
from ca_operacion
where op_fecha_ult_proceso between @w_fecha_ini and @w_fecha_proceso
and   op_banco not in (select do_banco from cob_conta_super..sb_dato_operacion where do_fecha = @w_fecha_proceso)

create index idx1 on #operaciones(cop_operacion)


/* DETERMINAR LA TASA DE LA OPERACION*/
update #operaciones set
cop_tasa               =  ro_porcentaje_efa,
cop_modalidad          =  case ro_fpago when 'P' then 'V' else 'A' end
from ca_rubro_op
where ro_operacion = cop_operacion
and   ro_concepto  = @w_rubro_int
and   ro_fpago in ('A', 'P')


/* DETERMINAR LA FECHA DE REESTRUCTURACION */
update #operaciones set
cop_reestructuracion   =  'S', 
cop_fecha_reest        =  tr_fecha_ref
from ca_transaccion
where tr_operacion = cop_operacion
and   tr_tran      = 'RES'
and   tr_estado   <> 'RV'

/* PARA OPERACIONES REESTRUCTURADAS, DETERMINAR EL MOTIVO DE LA REESTRUCTURACION */
update #operaciones set
cop_natur_reest        =  tr_motivo
from cob_credito..cr_tramite
where tr_numero_op = cop_operacion
and   tr_tipo      = 'E'
and   cop_reestructuracion = 'S'


/* DETERMINAR LA CANTIDAD DE CUOTAS VENCIDAS Y CANCELADAS */ 
select 
operacion  = di_operacion,
vencidas   = sum(case when di_estado = @w_est_vencido   then 1 else 0 end),
canceladas = sum(case when di_estado = @w_est_cancelado then 1 else 0 end)
into #resumen_cuotas
from ca_dividendo 
where di_estado in (@w_est_vencido, @w_est_cancelado)
group by di_operacion
  
update #operaciones set
cop_cuotas_pag =  canceladas,
cop_cuotas_ven =  vencidas
from #resumen_cuotas
where cop_operacion = operacion

/* DETERMINAR LA FECHA DE CASTIGO */
update #operaciones set
cop_fecha_castigo = tr_fecha_ref
from ca_transaccion 
where tr_operacion = cop_operacion
and   tr_tran      = 'CAS'
and   tr_estado   <> 'RV'
and   cop_estado   = @w_est_castigado

/* PARA LAS OPERACIONES MIGRADAS DE SICREDITO OBTENER LA FECHA DE CASTIGO DE LA CA_TRANSACCION_BANCAMIA */
update #operaciones set
cop_fecha_castigo = tr_fecha_mov
from cob_cartera..ca_transaccion_bancamia 
where tr_banco     = cop_banco
and   tr_tran      = 'CAS'
and   tr_estado   <> 'RV'
and   cop_estado   = @w_est_castigado

/* DETERMINAR FECHA Y MONTO DEL ULTIMO PAGO */
select 
operacion  = ab_operacion, 
fecha = max(ab_fecha_pag),
secuencial = 0
into #ult_pago
from  ca_abono, #operaciones  
where ab_tipo = 'PAG'
and   ab_estado != 'RV'
and   ab_operacion = cop_operacion 
group by  ab_operacion

/* DETERMINAR SI EL CLIENTE ESTA EMPROBLEMADO */ 
update #operaciones set
cop_emproblemado  = ea_char
from cobis..cl_ente_adicional
where cop_cliente = ea_ente
and ea_columna = 'en_emproblemado'

/* DETERMINAR CANTIDAD DE DIAS DE MORA */ 
update #operaciones set
cop_dias_mora_ant  = oe_int
from cob_cartera..ca_operacion_ext
where oe_operacion = cop_operacion
and oe_columna = 'op_dias_mora'

/* DETERMINAR SI OPERACION ES GRUPAL*/ 
update #operaciones set
cop_grupal  = ea_char
from cob_cartera..ca_operacion_ext
where oe_operacion = cop_operacion
and oe_columna = 'opt_grupal'

select 
operacion  = operacion, 
fecha = fecha,
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

update #operaciones set
cop_fecha_ult_pago  =  fecha,
cop_valor_ult_pago  =  monto
from #ult_pago_3
where cop_operacion = operacion

/* REGISTRO DE LOS SALDOS DIARIOS DE LAS OPERACIONES EN COB_EXTERNOS */
insert into cob_externos..ex_dato_operacion
select * from #operaciones
if @@error <> 0 begin
   select 
   @w_error = 724504, 
   @w_msg = 'Error en al Grabar en table cob_externos..ex_dato_operacion'
   goto ERROR
end

/* REGISTRO DEL DETALLE DE DEUDORES Y CODEUDORES DE LOS PRESTAMOS */
insert into cob_externos..ex_dato_deudores
select 
@w_fecha_proceso,
op_banco,
op_toperacion,  
7,
de_cliente,
de_rol
from cob_credito..cr_deudores, ca_operacion, #operaciones
where op_tramite = de_tramite
and   op_banco   = cop_banco

if @@error <> 0 begin
   select 
   @w_error = 724504, 
   @w_msg = 'Error en al Grabar en table cob_externos..ex_dato_deudores'
   goto ERROR
end


return 0

ERROR:

exec cob_cartera..sp_errorlog 
@i_fecha     = @w_fecha_proceso,
@i_error     = @w_error, 
@i_usuario   = 'sa', 
@i_tran      = 7999,
@i_tran_name = @w_sp_name,
@i_cuenta    = 'Masivo',
@i_anexo     = @w_msg,
@i_rollback  = 'S'

return @w_error

go
