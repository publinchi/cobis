

/************************************************************************/
/*  archivo:                lcr_crearcuota.sp                           */
/*  stored procedure:       sp_lcr_crear_cuota                          */
/*  base de datos:          cob_cartera                                 */
/*  producto:               credito                                     */
/*  disenado por:           Andy Gonzalez                               */
/*  fecha de documentacion: Noviembre 2018                              */
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
/*          proposito                                                   */
/*             CREA CUOTA MINIMA DE LA LCR                              */
/* FECHA           AUTOR                CAMBIO                          */
/*  17/abr/2023   Guisela Fernandez     S807925 Ingreso de campo de     */
/*                                      reestructuracion                */
/************************************************************************/

use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_lcr_crear_cuota')
	drop proc sp_lcr_crear_cuota
go

create proc sp_lcr_crear_cuota(
@i_operacionca        int,
@i_fecha_proceso      datetime        =null  
)
as
declare 
@w_abrir  			 char(1),
@w_dia_corte 		 descripcion,
@w_fecha_ini 		 datetime,
@w_tdividendo 		 char(2),
@w_periodo_int  	 int,
@w_plazo  			 int,
@w_dia_fecha_pro     descripcion,
@w_evitar_feriados   char(1),
@w_dia_mes           int,
@w_dia_mes_fecha_pro int,
@w_ciudad_nacional   int,
@w_dia_corte_mes     int,
@w_semanas           int,
@i_fecha_aux         datetime,
@w_primer_martes     datetime ,
@w_dias              int,
@w_fecha_pivote      datetime,
@w_max_corte         datetime ,
@w_fecha_fin         datetime ,
@w_dia_inicio        int,
@w_dias_martes       int,
@w_dd                int,
@w_div_vigente       int,
@w_fecha_min_div     datetime,
@w_dias_gracia       int ,
@w_sig_dividendo     int,
@w_fecha_corte       datetime,
@w_corte             int,
@w_fecha_feriado     datetime,
@w_saldo_cap_balon   money,
@w_commit            char(1),
@w_est_vigente       int, 
@w_est_novigente    int,
@w_est_vencido       int,
@w_error             int,
@w_param_cuotas      int,
@w_param_umbral      money,
@w_param_vencidos    int,
@w_moneda            int,
@w_numdec            int,
@w_saldo_cap_min     money,
@w_saldo_cap         money,
@w_div_vencidos      int,
@w_max_dividendo     int,
@w_fecha_ini_balon   datetime,
@w_div_balon         int,
@w_fecha_inimax      datetime,
@w_sp_name           descripcion,
@w_banco             cuenta,
@w_monto_iva         money,
@w_monto_int         money,
@w_tot_div           int ,
@w_iva               float,
@w_resultado         varchar(200),
@w_msg               descripcion,
@s_ssn               int,
@s_user              login,
@s_date              datetime ,
@s_srv               descripcion,
@s_term              descripcion,
@s_rol               int,
@s_lsrv              descripcion ,
@s_ofi               int,
@s_sesn              int,
@w_fecha_proceso     datetime,
@w_est_cancelado     int,
@w_deuda             money,
@w_monto             money,
@w_cap_min           money,
@w_balon_ini         money,
@w_factor            int,
@w_dia_pago          int,
@w_primer_corte      datetime,
@w_crear_cuota       char(1),
@w_toperacion        catalogo, 
@w_oficina_op        int ,     
@w_fecha_ult_proceso datetime ,
@w_oficial           int,
@w_secuencial        int,
@w_saldo_ini         money ,
@w_tasa_int          float,
@w_interes           money ,
@w_op_estado         int,
@w_cuota             money ,
@w_tramite           int,
@w_inst_proceso      int ,
@w_dias_anio         int,
@w_diferencia        FLOAT ,
@w_capital           money,
@w_reestructuracion  char(1)   
  

select @w_crear_cuota = 'S'  

--INICIALIZACION DE VARIABLES
--exec @s_ssn  = ADMIN...rp_ssn

select 
@w_abrir            = 'N',
@w_commit           = 'N' ,
@w_sp_name          = 'sp_lcr_crear_cuota',  
@s_user             ='usrbatch',
@s_srv              ='CTSSRV',
@s_term             ='batch-gcm',
@s_rol              =3,
@s_lsrv             ='CTSSRV',
@s_user             ='usrbatch', 
@s_srv              ='CTSSRV', 
@s_term             ='batch-gcm' ,  
@s_lsrv             = 'COBIS',
@s_sesn             = @s_ssn,
@s_date             = getdate(),
@w_fecha_proceso    = fp_fecha from cobis..ba_fecha_proceso




--INICIALIZACION DE CUOTA MINIMA 


select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted
/* CONTROLAR DIA MINIMO DEL MES PARA FECHAS DE VENCIMIENTO */

--DIAS DE GRACIA
select @w_dias_gracia = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'LCRGRA'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

--PARAMETRO DE CUOTA DIVIDIR 
select @w_param_cuotas = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'LCRCUO'
and    pa_producto = 'CCA'

--PARAMETRO UMBRAL
select @w_param_umbral = pa_money
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'LCRUMB'
and    pa_producto = 'CCA'

--PARAMETRO CUOTAS VENCIDAS
select @w_param_vencidos = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'LCRUMB'
and    pa_producto = 'CCA'



select 
@w_dias_gracia     = isnull(@w_dias_gracia, 7),
@w_param_cuotas    = isnull(@w_param_cuotas, 3),
@w_param_umbral    = isnull(@w_param_umbral, 100.0),
@w_param_vencidos  = isnull(@w_param_vencidos , 3)


select 
@w_banco             = op_banco,
@w_fecha_fin         = op_fecha_fin,
@w_periodo_int       = op_periodo_int,
@w_plazo             = op_plazo,
@w_tdividendo        = op_tdividendo,
@w_evitar_feriados   = op_evitar_feriados,
@w_moneda            = op_moneda,
@w_monto             = op_monto,
@s_ofi               = op_oficina,
@w_dia_pago          = op_dia_fijo,
@w_toperacion        = op_toperacion,
@w_oficina_op        = op_oficina,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_oficial           = op_oficial,
@w_op_estado         = op_estado,
@w_tramite           = op_tramite,
@w_dias_anio         = isnull(op_dias_anio,360),
@w_reestructuracion  = isnull(op_reestructuracion, 'N')
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount =0 begin 
   select @w_msg = 'ERROR NO EXISTE LA OPERACION ' 
   goto ERROR_FIN
end


select @w_fecha_ini = min(tr_fecha_ref) 
from ca_transaccion 
where tr_tran= 'DES'
and tr_estado <> 'RV'
and tr_secuencial >0
and tr_operacion =@i_operacionca

if @w_fecha_ini is null return 0  

--DETERMINAR INSTANCIA DE PROCESO
select @w_inst_proceso = io_id_inst_proc
from   cob_workflow..wf_inst_proceso
where  io_campo_3 = @w_tramite


if (@i_fecha_proceso > @w_fecha_fin) return 0


select @w_factor  = td_factor
from   ca_tdividendo 
where  td_tdividendo = @w_tdividendo




exec @w_error = sp_decimales
@i_moneda      = @w_moneda ,
@o_decimales   = @w_numdec out

exec sp_estados_cca 
@o_est_vencido   = @w_est_vencido   out ,
@o_est_vigente   = @w_est_vigente   out ,
@o_est_novigente = @w_est_novigente out,
@o_est_cancelado = @w_est_cancelado out

if exists (select 1 from ca_dividendo where di_operacion = @i_operacionca and di_fecha_ven = @i_fecha_proceso) return 0

select @w_iva     = ro_porcentaje 
from  ca_rubro_op 
where ro_operacion  = @i_operacionca 
and   ro_concepto   = 'IVA_INT'
  
select @w_tasa_int   = ro_porcentaje 
from  ca_rubro_op 
where ro_operacion  = @i_operacionca 
and   ro_concepto   = 'INT'


--MAXIMO DIVIDENDO ANTES DE LA GENERACION DE LA CUOTA BALON
select @w_max_dividendo = max(di_dividendo) 
from   ca_dividendo
where  di_operacion = @i_operacionca


--GENERACION DEL SIGUIENTE CORTE Y VALIDACION 

exec sp_lcr_calc_corte
@i_operacionca  = @i_operacionca,  
@i_fecha_proceso = @i_fecha_proceso, 
@o_fecha_corte   = @w_fecha_corte  out --

if dateadd(dd,-1,@w_fecha_corte) <> @i_fecha_proceso return 0   --NO GENERO CUOTA MINIMA 



--NUEVA TRANSACCION DE CUUOTAMIN GCM 
exec @w_secuencial  = sp_gen_sec
@i_operacion        = @i_operacionca

-- OBTENER RESPALDO ANTES DE la GCM
exec @w_error  = sp_historial
@i_operacionca  = @i_operacionca,
@i_secuencial   = @w_secuencial



 --INICIO ATOMICIDAD
if @@trancount = 0 begin  
  select @w_commit = 'S'
  begin tran 
end  




-- INSERCION DE CABECERA CONTABLE DE CARTERA  (REVISAR FV)
insert into ca_transaccion  with (rowlock)(
tr_fecha_mov,         tr_toperacion,     tr_moneda,
tr_operacion,         tr_tran,           tr_secuencial,
tr_en_linea,          tr_banco,          tr_dias_calc,
tr_ofi_oper,          tr_ofi_usu,        tr_usuario,
tr_terminal,          tr_fecha_ref,      tr_secuencial_ref,
tr_estado,            tr_gerente,        tr_gar_admisible,
tr_reestructuracion,  tr_calificacion,   tr_observacion,
tr_fecha_cont,        tr_comprobante)
values(
@w_fecha_corte,      @w_toperacion,        @w_moneda,
@i_operacionca,      'GCM',                @w_secuencial,
'N',                 @w_banco,             0,
@w_oficina_op,       @w_oficina_op,        'usrbatch',
@s_term,             @w_fecha_ult_proceso, 0, 
'ING',               @w_oficial,           '',
@w_reestructuracion, '',                   'GENERACION CUOTA MINIMA',
@s_date,             0)

if @@error <> 0 begin
   select 
   @w_error = 710001,
   @w_msg   = 'ERROR AL CREAR LA TRANSACCION GCM'
   goto ERROR_FIN
end
   

  
--DETERMINAR SI SE CREA CUOTAS MINIMAS
if (@w_fecha_corte = @w_fecha_fin)        select @w_crear_cuota = 'N' 

--VERIFICAR SI TIENE 3 CUOTAS VENCIDAS 
select @w_div_vencidos    = count (di_dividendo) 
from   ca_dividendo  
where  di_operacion       = @i_operacionca
and    di_estado          = @w_est_vencido
  
if (@w_div_vencidos >= @w_param_vencidos)  select @w_crear_cuota = 'N' 


select 
@w_saldo_cap         = round(isnull(sum(am_acumulado -am_pagado ),0) ,@w_numdec)
from ca_amortizacion  
where am_operacion   =  @i_operacionca 
and am_concepto      = 'CAP'
and am_dividendo     =  @w_max_dividendo

if @w_saldo_cap <= 0   return 0

--CASO 1 SALDO CAPITAL ES MAYOR A TRES VECES EL UMBRAL 
if (@w_saldo_cap > @w_param_cuotas*@w_param_umbral )  select @w_cap_min = isnull(round(@w_saldo_cap/@w_param_cuotas,@w_numdec),0)


--CASO 2 SALDO CAPITAL ENTRE 3 VECES EL UMBRAL Y EL UMBRAL 
if (@w_saldo_cap between @w_param_umbral and (@w_param_cuotas*@w_param_umbral)) select @w_cap_min =@w_param_umbral


--CASO 3 EL SALDO DE CAPITAL ES MENOR AL UMBRAL 
if (@w_saldo_cap < @w_param_umbral) select @w_cap_min = @w_saldo_cap  ,@w_crear_cuota = 'N'




if @w_crear_cuota = 'S' begin 

   
   select * into #dividendo    
   from ca_dividendo    
   where di_operacion = @i_operacionca 
   and di_dividendo   = @w_max_dividendo
   
   if @@error <> 0 begin
      select 
	  @w_error = 710001,
	  @w_msg   = 'ERROR AL CREAR LA TEMP DIVIDENDO'
      goto ERROR_FIN
   end
   

   update #dividendo set 
   di_fecha_ven  = @w_fecha_corte ,
   di_dias_cuota = datediff (dd,di_fecha_ini,@w_fecha_corte),
   di_estado     = @w_est_vigente
   
   if @@error <> 0 begin
      select 
	  @w_error = 710001,
	  @w_msg   = 'ERROR AL ACTUALIZAR LA TEMP DIVIDENDO'
      goto ERROR_FIN
   end
   
                            



   --CUOTA BALON
   update ca_dividendo set 
   di_dividendo  = di_dividendo +1,
   di_fecha_ini  = @w_fecha_corte,
   di_dias_cuota = datediff (dd,@w_fecha_corte,di_fecha_ven),
   di_estado     = @w_est_novigente
   where di_operacion = @i_operacionca 
   and  di_dividendo =  @w_max_dividendo
   
   if @@error <> 0 begin
      select 
	  @w_error = 710077,
	  @w_msg   = 'ERROR: AL ACTUALIZAR LA CA_DIVIDENDO'
      goto ERROR_FIN
   end

   --print 'SALDO CAP: '+convert(varchar,@w_saldo_cap)+' '+'CUOTA MINIMA:'+ convert (VARCHAR,isnull(@w_cap_min,-999))+'DIVIDENDO'+convert(varchar, @w_max_dividendo) 
   update ca_amortizacion set 
   am_dividendo       = am_dividendo +1,
   am_cuota           = am_cuota- @w_cap_min ,
   am_acumulado       = am_acumulado -@w_cap_min,
   am_estado          = @w_est_novigente
   where am_operacion = @i_operacionca
   and am_dividendo   = @w_max_dividendo
   and am_concepto    = 'CAP'
   
   if @@error <> 0 begin
      select 
	  @w_error = 710001,
	  @w_msg   = 'ERROR: AL ACTUALIZAR LA CA_AMORT'
      goto ERROR_FIN
   end
   
   --DESPLAZAMIENTO DE LA  NUEVA CUOTA BALON

   insert into ca_dividendo
   select * from #dividendo
   
   if @@error <> 0 begin
      select 
	  @w_error = 710001,
	  @w_msg   = 'ERROR: AL INSERTAR  LA CA_DIVIDENDO DE LA CUOTA BALON'
      goto ERROR_FIN
   end
   
   
   --CAPITAL
  
   
   insert into ca_amortizacion (
   am_operacion,             am_dividendo,             am_concepto,
   am_gracia,                am_pagado,                am_cuota,
   am_estado,                am_periodo,               am_acumulado,
   am_secuencia)
   values(
   @i_operacionca,             @w_max_dividendo,      'CAP',
   0,                          0,                      @w_cap_min ,
   @w_est_vigente,             0,                      @w_cap_min , 
   1 )
   
   if @@error <> 0 begin
      select 
	  @w_error = 710001,
	  @w_msg   = 'ERROR: AL INSERTAR  LA CA_AMORT DE LA CUOTA BALON'
      goto ERROR_FIN
   end
   
   
  
end else begin --NO VAMOS A CREAR CUOTA MINIMA 

  update ca_dividendo set 
  di_fecha_ven  = @w_fecha_corte,
  di_dias_cuota = datediff(dd,di_fecha_ini,@w_fecha_corte),
  di_estado     = @w_est_vigente
  where di_operacion = @i_operacionca
  and di_dividendo = @w_max_dividendo
  
  if @@error <> 0 begin
      select 
	  @w_error = 710001,
	  @w_msg   = 'ERROR: AL ACTUALIZAR LA FECHA DE VENC DE LA ULTIMA CUOTA'
      goto ERROR_FIN
   end
   
   
   update ca_amortizacion set 
   am_estado = @w_op_estado 
   where am_operacion = @i_operacionca
   and am_dividendo   = @w_max_dividendo
   
   if @@error <> 0 begin
      select 
	  @w_error = 710001,
	  @w_msg   = 'ERROR: AL ACTUALIZAR LOS ESTADOS DE LOS RUBROS DEL ULTIMO DE CORTE DE LA TABLA DE AMORT.'
      goto ERROR_FIN
   end
   
    
   update ca_operacion set 
   op_fecha_fin = @w_fecha_corte
   where op_operacion = @i_operacionca
   
   if @@error <> 0 begin
      select 
	  @w_error = 710001,
	  @w_msg   = 'ERROR: AL RECORTAR LA FECHA DE VENCIMIENTO DE LA OPERACION'
      goto ERROR_FIN
   end
   
end  


--MAXIMO DIVIDENDO ANTES DE LA GENERACION DE LA CUOTA BALON
select 
@w_fecha_ini = di_fecha_ini,
@w_fecha_fin = di_fecha_ven 
from   ca_dividendo
where  di_operacion = @i_operacionca
and di_dividendo    = @w_max_dividendo


if (@w_fecha_fin >@w_fecha_corte) select @w_fecha_fin =@w_fecha_corte 



--determinar saldo incial con que parte la cuota 
select 
@w_saldo_ini = sum(case tr_tran when 'DES' then dtr_monto else -1*dtr_monto end)
from ca_transaccion, ca_det_trn
where tr_operacion  = dtr_operacion 
and   tr_secuencial = dtr_secuencial
and   tr_fecha_ref  <= @w_fecha_ini
and   tr_tran  in ('PAG', 'DES')
and   dtr_concepto = 'CAP'
and   tr_estado <> 'RV'
and   tr_secuencial >0
and tr_operacion = @i_operacionca 


select 
fecha    = co_fecha_ini,
saldo    =0
into #saldos_inicial
from cob_conta..cb_corte 
where co_empresa = 1
and co_fecha_ini between @w_fecha_ini and dateadd(dd,-1,@w_fecha_fin)


--determinar saldo incial con que parte la cuota 
select 
fechatr = tr_fecha_ref,
monto = sum(case tr_tran when 'DES' then dtr_monto else -1*dtr_monto end)
into #transacciones
from ca_transaccion, ca_det_trn
where tr_operacion  = dtr_operacion 
and   tr_secuencial = dtr_secuencial
and   tr_fecha_ref  between dateadd(dd,1,@w_fecha_ini) and @w_fecha_fin
and   tr_tran  in ('DES', 'PAG')
and   tr_estado <> 'RV'
and   tr_secuencial >0
and   dtr_concepto = 'CAP'
and   tr_operacion = @i_operacionca 
group by tr_fecha_ref

insert into #transacciones values (@w_fecha_ini,@w_saldo_ini) --REGISTRO PARA RESUMIR EL SALDO INICIAL 

select 
fecha    = fecha,
saldo    = sum(saldo+monto) ,
interes  = convert(money,0)
into #saldos_diarios 
from #transacciones,#saldos_inicial
where fecha >=fechatr
group by fecha

update #saldos_diarios set 
interes  = interes +round(((saldo*@w_tasa_int)/100)/@w_dias_anio,@w_numdec)


--CALCULO DE INTERES E IVA 

select @w_interes = isnull(sum(interes),0) 
from #saldos_diarios

select @w_iva = round(@w_interes*ro_porcentaje/100, @w_numdec)
from ca_rubro_op 
where ro_operacion = @i_operacionca
and ro_concepto = 'IVA_INT'

if @@rowcount = 0 select @w_iva = 0


--print 'EL VALOR DEL INTERES CALCULADO PARA EL CORTE ES:'+convert(varchar,@w_interes) 
--select 'SALDO INICIAL',* 	from #saldos_diarios
--select 'TRANSACCIONES', * from #transacciones
--select 'SALDOS DIARIOS', * FROM #saldos_diarios 


--INT
insert into ca_amortizacion (
am_operacion,             am_dividendo,             am_concepto,
am_gracia,                am_pagado,                am_cuota,
am_estado,                am_periodo,               am_acumulado,
am_secuencia)
values(
@i_operacionca,             @w_max_dividendo,      'INT',
0,                          0,                     @w_interes ,
@w_est_vigente,             0,                     0, 
1 )

if @@error <> 0 begin
  select 
  @w_error = 710001,
  @w_msg   = 'ERROR: AL INSERTAR  LA CA_AMORT CONCEPTO INT'
  goto ERROR_FIN
end


--IVA
insert into ca_amortizacion (
am_operacion,             am_dividendo,             am_concepto,
am_gracia,                am_pagado,                am_cuota,
am_estado,                am_periodo,               am_acumulado,
am_secuencia)
values(
@i_operacionca,             @w_max_dividendo,      'IVA_INT',
0,                          0,                     @w_iva,
@w_est_vigente,             0,                     0, 
1 )

if @@error <> 0 begin
  select 
  @w_error = 710001,
  @w_msg   = 'ERROR: AL INSERTAR  LA CA_AMORT DE LA CONCEPTO IVA'
  goto ERROR_FIN
end

select @w_cuota  = isnull(sum(am_cuota),0) 
from ca_amortizacion 
where am_operacion = @i_operacionca
and am_dividendo   = @w_max_dividendo

--REDONDEO DE LA CUOTA SOLO SI EXISTE CUOTA BALON 

if exists ( select 1 from ca_dividendo where di_operacion =  @i_operacionca and di_dividendo =@w_max_dividendo+1) begin 

   select @w_diferencia = @w_cuota  -convert(int,@w_cuota) 
   
   if @w_diferencia >= 0.5 select @w_diferencia  = @w_diferencia-1 --redondeo 
   
   update ca_amortizacion set 
   am_cuota     = am_cuota     - @w_diferencia,
   am_acumulado = am_acumulado - @w_diferencia
   where am_operacion = @i_operacionca
   and am_dividendo   = @w_max_dividendo
   and am_concepto    = 'CAP'
   
   if @@error <> 0 begin
      select 
      @w_error = 710001,
      @w_msg   = 'ERROR: AL ACTUALIZAR LA TABLA DE AMORTIZACION CON LA DIFERENCIA'
      goto ERROR_FIN
   end
   
   
   update ca_amortizacion set 
   am_cuota     = am_cuota     + @w_diferencia,
   am_acumulado = am_acumulado + @w_diferencia
   where am_operacion = @i_operacionca
   and am_dividendo   = @w_max_dividendo +1
   and am_concepto    = 'CAP'
   
   
   if @@error <> 0 begin
      select 
      @w_error = 710001,
      @w_msg   = 'ERROR: AL ACTUALIZAR LA TABLA DE AMORTIZACION CON LA DIFERENCIA'
      goto ERROR_FIN
   end
    

end 


update ca_operacion set 
op_cuota = @w_cuota
where op_operacion = @i_operacionca

if @@error <> 0 begin
  select 
  @w_error = 710001,
  @w_msg   = 'ERROR: AL ACTUALIZAR LA CUOTA DE LA OPERACION'
  goto ERROR_FIN
end


if @w_commit = 'S'begin 
  select @w_commit = 'N'
  commit tran    
end 
   

--select * from  #saldos_diarios

return 0

ERROR_FIN:

if @w_commit = 'S'begin 
   select @w_commit = 'N'
   rollback tran    
end 

exec sp_errorlog 
@i_fecha     = @i_fecha_proceso,
@i_error     = @w_error,
@i_usuario   = 'lcr_cuotamin',
@i_tran      = 7999,
@i_tran_name = @w_sp_name,
@i_cuenta    = @w_banco,
@i_rollback  = 'N'

go