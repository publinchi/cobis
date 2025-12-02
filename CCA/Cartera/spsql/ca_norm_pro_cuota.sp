/************************************************************************/
/*      Nombre Fisico:          ca_norm_pro_cuota.sp                    */
/*      Nombre Logico:       	sp_norm_pro_cuota                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               COBIS-CARTERA                           */
/*      Disenado por:           Luis Guzman                             */
/*      Fecha de escritura:     11-Sep-14                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios que son        */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                                PROPOSITO                             */
/* Normalizacion de Cartera - Prorroga de Cuota                         */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      11/Sep/14       L. Guzman       Emision Inicial                 */
/*    06/06/2023	 M. Cordova		 Cambio variable @w_op_calificacion	*/
/*									 de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_norm_pro_cuota')
   drop proc sp_norm_pro_cuota
go

create proc sp_norm_pro_cuota(
   @s_user           login        = 'batch',
   @s_ofi            smallint     = null,
   @s_term           varchar(30)  = null,
   @s_date           datetime     = null,
   @i_operacionca    int          = null,
   @i_fecha_prorroga datetime     = null,
   @i_cuota_prorroga tinyint      = null,
   @i_debug          char         = 'N'
)
as
declare
   @w_error             int,
   @w_msg               varchar(132),
   @w_sp_name           varchar(32),
--   @w_cuota_actual      tinyint,
   @w_est_cuota_pro     smallint,
   @w_fecha_ini_pro     datetime,
   @w_fecha_fin_pro     datetime,   
   @w_fecha_fin_sig     datetime,
   @w_saldo_cap_pro     money,
   @w_saldo_cap_sig     money,
   @w_int_acu_tot_pro       money,
   @w_int_acu_tot_sig       money,
   @w_int_nue_pro       money,
   @w_int_nue_sig       money,
   @w_int_causado_pro   money,
   @w_int_causado_sig   money,
   @w_monto_prv         money,
   @w_tasa_efa          float,
   @w_tasa_nom_pro      float,        
   @w_tasa_nom_sig      float,        
   @w_dias_cuota_pro    int,
   @w_dias_cuota_sig    int,
   @w_dias_causados_pro int,
   @w_codvalor          int,   
   @w_dias_anio         smallint,
   @w_base_calculo      char(1),
   @w_ro_fpago          char(1),   
   @w_ro_num_dec        tinyint,
   @w_est_vigente       tinyint,
   @w_est_novigente     tinyint,
   @w_est_vencido       tinyint,
   @w_est_cancelado     tinyint,
   @w_est_castigado     tinyint,
   @w_est_suspenso      tinyint,
   @w_est_anulado       tinyint,
   @w_am_secuencia      tinyint,
   @w_secuencial_tran   int,
   @w_di_estado         smallint,
   @w_fecha_proceso     datetime,
   @w_fecha_proc_op     datetime,
   @w_toperacion        catalogo,
   @w_moneda            tinyint,
   @w_banco             cuenta,
   @w_oficina           smallint,
   @w_gerente           int,
   @w_op_calificacion   catalogo,
   @w_op_gar_admisible  char(1),
   @w_tramite           int,
   @w_op_cliente        int,
   @w_op_estado         tinyint,
   @w_sec               int,
   @w_est_int_sig      int,
   @w_sec_int_sig           int,
   @w_int_acu_sig         money,
   @w_int_acu_tot        money,
   @w_int_proy_sig       money,
   @w_diff_cuota        money,
   @w_diff_acu          money,
   @w_int_proy_tot_pro         money,
   @w_int_proy_tot     money
   
   
   
/*INICIALIZA VARIABLE*/

select @w_sp_name = 'sp_norm_pro_cuota'

select @w_dias_causados_pro = 0,
       @w_tramite           = 0,
       @w_int_causado_pro   = 0,
       @w_monto_prv         = 0

/* OBTIENE FECHA DE PROCESO */
select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

if @@rowcount = 0
begin
   select @w_msg = 'ERROR AL LEER FECHA DE PROCESO DE CARTERA',
          @w_error = 801085
          
   goto ERRORFIN
end

-- ESTADOS DE CARTERA
exec @w_error    = sp_estados_cca
@o_est_vigente   = @w_est_vigente   out,
@o_est_vencido   = @w_est_vencido   out,
@o_est_cancelado = @w_est_cancelado out,
@o_est_novigente = @w_est_novigente out,
@o_est_suspenso  = @w_est_suspenso  out,
@o_est_anulado   = @w_est_anulado   out

if @w_error <> 0
begin 
      select @w_msg   = 'ERROR CONSULTADO ESTADOS DE CARTERA'             
      goto ERRORFIN
end

/* VALIDA PARAMETROS DE ENTRADA */
if @i_operacionca is null or @i_fecha_prorroga is null or @i_cuota_prorroga is null
begin
   select @w_msg   = 'PARAMETROS DE ENTRADA FALTANTES...',
          @w_error = 708192
             
   goto ERRORFIN   
end

/* OBTIENE DATOS BASICOS DE LA OPERACION DE LA OPERACION */
select @w_base_calculo     = op_base_calculo,
       @w_dias_anio        = op_dias_anio,
       @w_fecha_proc_op    = op_fecha_ult_proceso,
       @w_toperacion       = op_toperacion,
       @w_moneda           = op_moneda,
       @w_banco            = op_banco,
       @w_oficina          = op_oficina,
       @w_gerente          = op_oficial,
       @w_op_calificacion  = isnull(op_calificacion,'A'),
       @w_op_gar_admisible = isnull(op_gar_admisible, 'O'),
       @w_op_cliente       = op_cliente,
       @w_op_estado        = op_estado
from ca_operacion
where op_operacion = @i_operacionca

if @@rowcount = 0
begin
   select @w_msg = 'ERROR, NO ES POSIBLE OBTENER DATOS BASICOS DE LA OPERACION',
          @w_error = 708153
          
   goto ERRORFIN
end

/* ESTADOS DE LA OPERACION NO VALIDOS PARA NORMALIZAR */
if @w_op_estado in (@w_est_cancelado, @w_est_castigado, @w_est_novigente, @w_est_anulado)
begin
   select @w_msg = 'ERROR, EL ESTADO DE LA OPERACION NO ES VALIDO PARA NORMALIZAR',
          @w_error = 708153
          
   goto ERRORFIN
end

if @w_fecha_proc_op <> @w_fecha_proceso
begin
   select @w_msg = 'ERROR, LA OPERACION NO ESTA A FECHA DEL DIA',
          @w_error = 708153
          
   goto ERRORFIN
end

/* OBTIENE MAXIMO NUMERO DE TRAMITE DE PRORROGA DE FECHA */
select @w_tramite = MAX(tr_tramite)
from cob_credito..cr_tramite
where tr_numero_op_banco = @w_banco
and   tr_tipo    = 'M'  -- NORMALIZACION
and   tr_grupo   = 1    -- SUBTIPO PRORROGA DE CUOTA
and   tr_estado  <> 'Z'  -- DIFERENTE DE ANULADOS

if @@rowcount = 0
begin
   select @w_msg = 'ERROR, NO ES POSIBLE OBTENER NUMERO DE TRAMITE PARA PRORROGA DE FECHA',
          @w_error = 708153
          
   goto ERRORFIN
end


/* SELECCIONA DATOS DE LA CUOTA A PRORROGAR */
select @w_fecha_ini_pro  = di_fecha_ini,
       @w_fecha_fin_pro  = di_fecha_ven,
       @w_est_cuota_pro  = di_estado
from ca_dividendo
where di_operacion = @i_operacionca
and   di_dividendo = @i_cuota_prorroga

if @@rowcount = 0
begin
   select @w_msg = 'ERROR, NO ES POSIBLE OBTENER FECHA DE INICIO DEL DIVIDENDO A PRORROGAR',
          @w_error = 701103
          
   goto ERRORFIN
end

if @w_est_cuota_pro = @w_est_cancelado
begin
   select @w_msg = 'ERROR, NO ES POSIBLE PRORROGAR CUOTAS CANCELADAS',
          @w_error = 2101271
          
   goto ERRORFIN
end

/* SELECCIONA FECHA DE VENCIMIENTO DE LA CUOTA SIGUIENTE */
select 
   @w_fecha_fin_sig = di_fecha_ven
from ca_dividendo
where di_operacion = @i_operacionca
and   di_dividendo = @i_cuota_prorroga + 1

if @@rowcount = 0
begin
   select @w_msg = 'ERROR, NO ES POSIBLE OBTENER FECHA FIN DEL DIVIDENDO SIGUIENTE A LA PRORROGA',
          @w_error = 701103
          
   goto ERRORFIN
end

if @i_fecha_prorroga = @w_fecha_fin_pro
begin
   select @w_msg = 'LA FECHA DE PRORROGA DEBE SER POSTERIOR A LA FECHA DE VENCIMIENTO DE LA CUOTA',
          @w_error = 2101265
          
   goto ERRORFIN
end

if @i_fecha_prorroga <= @w_fecha_proceso
begin
   select @w_msg = 'ERROR: LA FECHA DE PRORROGA DEBE SER MAYOR A LA FECHA DEL SISTEMA',
          @w_error = 2101263
          
   goto ERRORFIN
end

if @i_fecha_prorroga >= @w_fecha_fin_sig
begin
   select @w_msg = 'LA FECHA DE PRORROGA DEBE SER MENOR A LA FECHA DE VENCIMIENTO DE LA SIGUIENTE CUOTA',
          @w_error = 2101266
          
   goto ERRORFIN
end

/*SALDO CAPITAL CUOTA A PRORROGAR*/
select @w_saldo_cap_pro = SUM(am_cuota) 
from cob_cartera..ca_amortizacion
where am_operacion = @i_operacionca
and   am_concepto in ('CAP')
and   am_dividendo >= @i_cuota_prorroga

if @@rowcount = 0
begin
   select @w_msg = 'ERROR, NO ES POSIBLE OBTENER EL SALDO CAPITAL DE LA CUOTA A PRORROGAR',
          @w_error = 724563
          
   goto ERRORFIN
end

/*SALDO CAPITAL CUOTA SIGUIENTE*/
select @w_saldo_cap_sig = SUM(am_cuota) 
from cob_cartera..ca_amortizacion
where am_operacion = @i_operacionca
and   am_concepto in ('CAP')
and   am_dividendo >= @i_cuota_prorroga + 1

if @@rowcount = 0
begin
   select @w_msg = 'ERROR, NO ES POSIBLE OBTENER EL SALDO CAPITAL DE LA CUOTA SIGUIENTE A LA PRORROGAR',
          @w_error = 724564
          
   goto ERRORFIN
end

/* TASA EFA ORIGINAL */
select @w_tasa_efa = ro_porcentaje_efa
from cob_cartera..ca_rubro_op
where ro_operacion = @i_operacionca
and   ro_concepto  = ('INT')

if @@rowcount = 0
begin
   select @w_msg = 'ERROR, NO ES POSIBLE OBTENER LA TASA EFA DE LA OPERACION',
          @w_error = 710037
          
   goto ERRORFIN
end


/* OBTIENE NUEVO NUMERO DE DIAS DE LA CUOTA A PRORROGAR */
if @w_base_calculo = 'E'  
begin
   exec @w_error = sp_dias_cuota_360
   @i_fecha_ini  = @w_fecha_ini_pro,
   @i_fecha_fin  = @i_fecha_prorroga,
   @o_dias       = @w_dias_cuota_pro out

   if @w_error <> 0
   begin
      select @w_msg   = 'ERROR EJECUTANDO sp_dias_cuota_360 PARA LA CUOTA DE LA PRORROGA'
             
      goto ERRORFIN
   end      
end

if @w_base_calculo = 'R'
   select @w_dias_cuota_pro = datediff(dd,@w_fecha_ini_pro,@i_fecha_prorroga)


/* OBTIENE NUEVO NUMERO DE DIAS DE LA SIGUIENTE CUOTA */
if @w_base_calculo = 'E'
begin  
   exec @w_error = sp_dias_cuota_360
   @i_fecha_ini  = @i_fecha_prorroga,
   @i_fecha_fin  = @w_fecha_fin_sig,
   @o_dias       = @w_dias_cuota_sig out
   
   if @w_error <> 0
   begin
      select @w_msg   = 'ERROR EJECUTANDO sp_dias_cuota_360 PARA LA CUOTA SIGUIENTE A LA PRORROGA'
             
      goto ERRORFIN
   end      
end

if @w_base_calculo = 'R'
   select @w_dias_cuota_sig = datediff(dd,@i_fecha_prorroga,@w_fecha_fin_sig)

/****************** RECALCULO DE INTERESES ***********************/

/* OBTIENE INTERES ACUMULADO ACTUAL DE LA CUOTA A PRORROGAR */
select @w_int_acu_tot_pro = sum(am_acumulado)
from ca_amortizacion
where am_operacion = @i_operacionca
and   am_concepto  = 'INT'
and   am_dividendo = @i_cuota_prorroga

if @@ROWCOUNT = 0
begin
   select @w_msg   = 'ERROR, NO ES POSIBLE ENCONTRAR VALOR ACUMULADO DEL INTERES DE LA CUOTA A PRORROGAR',
          @w_error = 721901
             
   goto ERRORFIN
end      

/* OBTIENE INTERES ACUMULADO ACTUAL DE LA CUOTA SIGUIENTE */
select @w_int_acu_tot_sig = sum(am_acumulado)
from ca_amortizacion
where am_operacion = @i_operacionca
and   am_concepto  = 'INT'
and   am_dividendo = @i_cuota_prorroga + 1

if @@ROWCOUNT = 0
begin
   select @w_msg   = 'ERROR, NO ES POSIBLE ENCONTRAR VALOR ACUMULADO DEL INTERES DE LA CUOTA SIGUIENTE',
          @w_error = 721901
             
   goto ERRORFIN
end      

/* OBTIENE FORMA DE PAGO DEL CONCEPTO INT PARA CALCULO DE TASA NOMINAL */
select 
@w_ro_fpago    = ro_fpago,
@w_ro_num_dec  = ro_num_dec
from cob_cartera..ca_rubro_op
where ro_operacion = @i_operacionca
and ro_concepto in ('INT')
and ro_fpago    in ('P','A','T')

if @@ROWCOUNT = 0
begin
   select @w_msg   = 'ERROR, NO ES POSIBLE ENCONTRAR LA FORMA DE PAGO DE LA OPERACION',
          @w_error = 710344
             
   goto ERRORFIN
end      
   
if @w_ro_fpago in ('P', 'T')
   select @w_ro_fpago = 'V'	 


/* CONVIERTE TASA EFA A NOMINAL DE LA CUOTA A PRORROGAR DE ACUERDO A LOS NUEVOS DIAS DE LA CUOTA */	    
exec @w_error = sp_conversion_tasas_int
   @i_periodo_o       = 'A',
   @i_modalidad_o     = 'V',
   @i_num_periodo_o   = 1,
   @i_tasa_o          = @w_tasa_efa,
   @i_periodo_d       = 'D',
   @i_modalidad_d     = @w_ro_fpago,
   @i_num_periodo_d   = @w_dias_cuota_pro,
   @i_dias_anio       = @w_dias_anio,
   @i_num_dec         = @w_ro_num_dec,
   @o_tasa_d          = @w_tasa_nom_pro output
   
if @w_error <> 0 
begin
   select @w_msg   = 'ERROR CONVIRTIENDO TASA EFA A NOMINAL PARA LA CUOTA A PRORROGAR'
   
   goto ERRORFIN
end

/* CONVIERTE TASA EFA A NOMINAL DE LA CUOTA SIGUIENTE DE ACUERDO A LOS NUEVOS DIAS DE LA CUOTA */	    
exec @w_error = sp_conversion_tasas_int
   @i_periodo_o       = 'A',
   @i_modalidad_o     = 'V',
   @i_num_periodo_o   = 1,
   @i_tasa_o          = @w_tasa_efa,
   @i_periodo_d       = 'D',
   @i_modalidad_d     = @w_ro_fpago,
   @i_num_periodo_d   = @w_dias_cuota_sig,
   @i_dias_anio       = @w_dias_anio,
   @i_num_dec         = @w_ro_num_dec,
   @o_tasa_d          = @w_tasa_nom_sig output
   
if @w_error <> 0 
begin
   select @w_msg   = 'ERROR CONVIRTIENDO TASA EFA A NOMINAL PARA CUOTA SIGUIENTE A LA PRORROGA'
          
   goto ERRORFIN
end

/* OBTIENE SECUENCIAL PARA LA TRANSACCION */
exec @w_secuencial_tran = sp_gen_sec
@i_operacion            = @i_operacionca

if @@ERROR <> 0
begin
   select 
      @w_msg   = 'ERROR AL OBTENER SECUENCIAL DE LA TRANSACCION',
      @w_error = 708153
      
   goto ERRORFIN
end

-- OBTENER RESPALDO ANTES DE LA REESTRUCTURACION
exec @w_error  = sp_historial
@i_operacionca = @i_operacionca,
@i_secuencial  = @w_secuencial_tran

if @@ERROR <> 0
begin
   select 
      @w_msg   = 'ERROR GUARDANDO HISTORIAL DE LA OPERACION',
      @w_error = 708153
   
   goto ERRORFIN          
end

/* CALCULA NUEVO INTERES PROYECTADO DE LA CUOTA A PRORROGAR Y DE LA SIGUIENTE */
select @w_int_nue_pro = ROUND((@w_tasa_nom_pro/100.0 * @w_saldo_cap_pro)/CAST(@w_dias_anio as float) * @w_dias_cuota_pro,0),
       @w_int_nue_sig = ROUND((@w_tasa_nom_sig/100.0 * @w_saldo_cap_sig)/CAST(@w_dias_anio as float) * @w_dias_cuota_sig,0)

/* SI EL ESTADO DE LA CUOTA A PRORROGAR ES VENCIDO SE CAMBIA A VIGENTE */
if @w_est_cuota_pro = @w_est_vencido
   select @w_est_cuota_pro = @w_est_vigente
  
/* ACTUALIZA LA CUOTA A PRORROGAR */
update ca_dividendo 
set di_fecha_ven   = @i_fecha_prorroga,
    di_dias_cuota  = @w_dias_cuota_pro,
    di_estado      = @w_est_cuota_pro
where di_operacion = @i_operacionca
and   di_dividendo = @i_cuota_prorroga

if @@error <> 0
begin
   /* ERROR AL ACTUALIZA FECHA DE PROROGA */
 select 
   @w_msg = 'ERROR AL ACTUALIZA FECHA DE PROROGA',
   @w_error   = 710002       

   goto ERRORFIN
end

/* ACTUALIZA CUOTA SIGUIENTE CON ESTADO NO VIGENTE */         
update ca_dividendo 
set di_fecha_ini   = @i_fecha_prorroga,
    di_dias_cuota  = @w_dias_cuota_sig,
    di_estado      = 0
where di_operacion = @i_operacionca
and   di_dividendo = @i_cuota_prorroga + 1

if @@error <> 0
begin
   /* ERROR AL ACTUALIZA FECHA DE PROROGA */
   select 
   @w_msg = 'ERROR AL ACTUALIZA FECHA DE LA CUOTA SIGUIENTE A LA PRORROGA',
   @w_error   = 710002        

   goto ERRORFIN
end
   
/* GENERA TRANSACCION CONTABLE */
insert into ca_transaccion (
tr_secuencial,      tr_fecha_mov,         tr_toperacion,
tr_moneda,          tr_operacion,         tr_tran,
tr_en_linea,        tr_banco,             tr_dias_calc,
tr_ofi_oper,        tr_ofi_usu,           tr_usuario,
tr_terminal,        tr_fecha_ref,         tr_secuencial_ref,
tr_estado,          tr_gerente,           tr_calificacion,
tr_gar_admisible,   tr_observacion,       tr_comprobante,
tr_fecha_cont,      tr_reestructuracion,  tr_fecha_real)
values (
@w_secuencial_tran, @s_date,              @w_toperacion,
@w_moneda,          @i_operacionca,       'PNO',
'S',                @w_banco,             0,
@w_oficina,         @s_ofi,               @s_user,
@s_term,            @w_fecha_proc_op,     0,
'NCO',              @w_gerente,          @w_op_calificacion,
@w_op_gar_admisible,'NORMALIZACION PRORROGA DE FECHA',   0,
'',                 'S',                  getdate()
)

if @@error <> 0 begin
   print 'ERROR EN INGRESO DE TRANSACCION DE NORMALIZACION PRORROGA DE CUOTA'
   select @w_error = 710001
   
   goto ERRORFIN
end

/* ACTUALIZA LA TASA NOMINAL DEL CREDITO SI LA CUOTA A PRORROGAR ES LA VIGENTE 
   NOTA: EL verifven.sp SE ENCARGA DE ACTUALIZAR LA TASA NOMINAL AL MOMENTO DE INICIAR UN DIVIDENDO*/   
if @w_est_cuota_pro = @w_est_vigente
begin
   update ca_rubro_op
   set ro_porcentaje  = @w_tasa_nom_pro
   where ro_operacion = @i_operacionca
   and   ro_concepto  = 'INT'
   
   if @@error <> 0
   begin
      /* ERROR AL ACTUALIZAR INTERES PROYECTADO CUOTA SIGUIENTE */
      select 
      @w_msg = 'ERROR AL ACTUALIZAR INTERES PROYECTADO CUOTA SIGUIENTE',
      @w_error   = 710002          
   
      goto ERRORFIN
   end
end

/* ACTUALIZAR INTERESES ACUMULADOS EN LA CUOTA PRORROGADA */
if @w_fecha_ini_pro < @w_fecha_proc_op and @w_est_cuota_pro = @w_est_vigente
begin

   /* OBTIENE DIAS CAUSADOS PARA LA CUOTA PRORROGADA */
   if @w_base_calculo = 'E'
   begin  
      exec @w_error = sp_dias_cuota_360
      @i_fecha_ini  = @w_fecha_ini_pro,
      @i_fecha_fin  = @w_fecha_proc_op,
      @o_dias       = @w_dias_causados_pro out
   
      if @w_error <> 0
      begin
         select @w_msg   = 'ERROR EJECUTANDO sp_dias_cuota_360 PARA LA CUOTA PRORROGADA'
             
         goto ERRORFIN
      end      
   end

   if @w_base_calculo = 'R'
      select @w_dias_causados_pro = datediff(dd,@w_fecha_ini_pro,@w_fecha_proc_op)

   /* CALCULA NUEVO INTERES ACUMULADO HASTA EL MOMENTO PARA LA CUOTA PRORROGADA */        
   select @w_int_causado_pro = ROUND(@w_int_nue_pro * @w_dias_causados_pro / @w_dias_cuota_pro,0)
   
   /* GENERA TRANSACCION PRV DE AJUSTE POR LA DIFERENCIA DE INTERESES ACUMULADOS EN LA CUOTA PRORROGADA */
   if @w_int_causado_pro  > (@w_int_acu_tot_pro + @w_int_acu_tot_sig)
   begin             
   
      /* CALCULA EL VALOR DE LA TRANSACCION PRV DE AJUSTE */
      select @w_monto_prv = @w_int_causado_pro - (@w_int_acu_tot_pro + @w_int_acu_tot_sig)
      
      /* OBTIENE EL CODIGO VALOR PARA EL REGISTRO DE LA TRANSACCION PRV */
      select @w_codvalor = co_codigo * 1000 + @w_est_cuota_pro * 10 + 0
      from   ca_concepto
      where  co_concepto    = 'INT'
      
      if @@ROWCOUNT = 0 
      begin
         select @w_msg   = 'ERROR AL OBTENER EL CODIGO VALOR PARA LA TRANSACCION PRV',
                @w_error = 708153
                
         goto ERRORFIN 
      end
      
      /* OBTIENE SECUENCIA PARA EL REGISTRO DE LA TRANSACCION PRV */
      select 
      @w_am_secuencia = isnull(max(am_secuencia),1)
      from   ca_amortizacion
      where  am_operacion    = @i_operacionca
      and    am_dividendo    = @i_cuota_prorroga
      and    am_concepto     = 'INT'
      
      if @@ROWCOUNT = 0
      begin
         select @w_msg   = 'ERROR AL OBTENER SECUENCIAL PARA EL REGISTRO DE LA TRANSACCION PRV',
                @w_error = 708153
         
         goto ERRORFIN
      end
       
      /* CREA TRANSACCION PRV DE AJUSTE DE INTERESES */
      insert into ca_transaccion_prv with (rowlock)
      (
      tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
      tp_secuencial_ref,   tp_estado,           tp_dividendo,
      tp_concepto,         tp_codvalor,         tp_monto,
      tp_secuencia,        tp_comprobante,      tp_ofi_oper
      )
      values
      (
      @s_date,             @i_operacionca,      @w_fecha_proceso,
      0,                   'ING',               @i_cuota_prorroga,
      'INT',               @w_codvalor,         @w_monto_prv,
      @w_am_secuencia,     0,                   @w_oficina
      )

      if @@ERROR <> 0
      begin
         select @w_msg   = 'ERROR INSERTANDO REGISTRO DE LA TRANSACCION PRV',
                @w_error = 710001
             
         goto ERRORFIN
      end      
         
   end
end

/* CREA TABLA TEMPORAL DE INTERES ACTUAL POR ESTADOS DEL DIVIDENDO */
select am_dividendo dividendo, am_concepto concepto, am_cuota cuota, 
       am_acumulado acumulado, am_estado estado,     am_secuencia secuencia
into #int_act
from ca_amortizacion
where am_operacion = @i_operacionca
and   am_concepto  = 'INT'
and   am_dividendo in (@i_cuota_prorroga, @i_cuota_prorroga + 1)
order by am_dividendo, am_secuencia

if @@error <> 0
begin
   /* ERROR AL ACTUALIZAR INTERES PROYECTADO CUOTA PRORROGADA */
   select 
   @w_msg = 'ERROR AL CREAR TABLA TEMPORAL DE INTERES ACUMULADO',
   @w_error   = 710001

   goto ERRORFIN
end

/* CREA SECUENCIAL AUTOMATICO A LA TABLA TEMPORAL */
alter table #int_act
add sec int identity

select @w_sec = 0

/* OBTIENE EL INTERES PROYECTADO DE LA CUOTA PRORROGADA */
select @w_int_proy_tot_pro = sum(cuota)
from #int_act
where dividendo = @i_cuota_prorroga

   

/* MUEVE INTERES DE CUOTA SIGUIENTE A CUOTA PRORROGADA */
while 1=1
begin

   select top 1 @w_int_proy_sig  = cuota,
                @w_int_acu_sig   = acumulado,
                @w_est_int_sig   = estado,
                @w_sec_int_sig   = secuencia,
                @w_sec           = sec
   from #int_act
   where dividendo = @i_cuota_prorroga + 1
   and   sec > @w_sec
   
   if @@ROWCOUNT = 0
      break  
      
   /* SI EL INTERES PROYECTADO DE LA CUOTA PROROGADA SUMADO LOS INTERESES PROYECTADOS DE LA SIGUIENTE CUOTA
      SOBREPASA EL VALOR DE LOS INTERESES PROYECTADOS NUEVOS CALCULADOS CON EL NUEVO NUMERO DE DIAS 
      SE REALIZA EL AJUSTE DE LA DIFERENCIA EN LA CUOTA PRORROGADA */
   if  @w_int_proy_tot_pro + @w_int_proy_sig > @w_int_nue_pro
      select @w_int_proy_sig = @w_int_nue_pro - @w_int_proy_tot_pro
      
   select @w_int_proy_tot_pro = @w_int_proy_tot_pro + @w_int_proy_sig

   /* SI EL ESTADO DEL RUBRO DE INTERES ES SUSPENSO SE VALIDA SU EXISTENCIA EN LA CUOTA PRORROGADA
      CASO QUE EXISTA SE ACTUALIZA SINO SE CREA */
   
   if @w_est_int_sig = @w_est_suspenso
   begin
   
      if exists(select 1 from ca_amortizacion
                where am_operacion = @i_operacionca
                and   am_concepto  = 'INT'
                and   am_dividendo = @i_cuota_prorroga
                and   am_estado    = @w_est_suspenso)
      begin          
         update ca_amortizacion
         set am_cuota     = am_cuota     + @w_int_proy_sig,
             am_acumulado = am_acumulado + @w_int_acu_sig
         where am_operacion = @i_operacionca
         and   am_concepto  = 'INT'
         and   am_dividendo = @i_cuota_prorroga
         and   am_estado    = @w_est_suspenso
         
         if @@error <> 0
         begin
            /* ERROR AL ACTUALIZAR CUOTA DE INTERES EN SUSPENSO */
            select 
            @w_msg = 'ERROR AL ACTUALIZAR CUOTA DE INTERES EN SUSPENSO',
            @w_error   = 710002

            goto ERRORFIN
         end
         
         
      end
      else
      begin
         
         /*SELECCIONA MAXIMO SECUENCIAL DE INTERES DE LA CUOTA A PRORROGAR*/
         select @w_sec_int_sig = MAX(secuencia) + 1 from #int_act
         where dividendo = @i_cuota_prorroga
    
         insert into ca_amortizacion (am_operacion, am_dividendo, am_concepto,
                                      am_estado,    am_periodo,   am_cuota,
                                      am_gracia,    am_pagado,    am_acumulado,
                                      am_secuencia)
         values (@i_operacionca,  @i_cuota_prorroga, 'INT', 
                 @w_est_suspenso, 0,                 @w_int_proy_sig, 
                 0,               0,                 @w_int_acu_sig, 
                 @w_sec_int_sig)

         if @@error <> 0
         begin
            /* ERROR AL INSERTAR ROBRO DE INTERES EN SUSPENSO DE LA CUOTA A PRORROGAR */
            select 
            @w_msg = 'ERROR AL INSERTAR RUBRO DE INTERES EN SUSPENSO DE LA CUOTA A PRORROGAR',
            @w_error   = 710001

            goto ERRORFIN
         end                         
      end      
   end
   else 
   begin

      /* ACTUALIZA INTERESES EN ESTADO DIFERENTE A SUSPENSO */      
      select @w_sec_int_sig = MAX(secuencia) 
      from #int_act
      where dividendo = @i_cuota_prorroga
      and   estado    <> @w_est_suspenso
      
      if @@ROWCOUNT = 0
      begin
         select 
            @w_msg = 'ERROR NO SE ENCUENTRA SECUENCIUAL DE INTERES EN TABLA TEMPORAL',
            @w_error   = 708153
            
         goto ERRORFIN
      end
   
      update ca_amortizacion
      set am_cuota     = am_cuota + @w_int_proy_sig,
          am_acumulado = am_acumulado + @w_int_acu_sig,
          am_estado    = @w_est_cuota_pro
      where am_operacion = @i_operacionca
      and   am_concepto  = 'INT'
      and   am_dividendo = @i_cuota_prorroga
      and   am_secuencia = @w_sec_int_sig
      
      if @@error <> 0
      begin
         /* ERROR AL ACTUALIZAR CUOTA DE INTERES DIFERENTE DE SUSPENSO */
         select 
         @w_msg = 'ERROR AL ACTUALIZAR CUOTA DE INTERES DIFERENTE DE SUSPENSO',
         @w_error   = 710002

         goto ERRORFIN
      end                  
   end 
end  -- FIN WHILE

/* OBTIENE INTERES ACUMULADO ACTUAL */
--select @w_int_proy_tot   = SUM(cuota),
--       @w_int_acu_tot   = SUM(acumulado) 
--from #int_act

select @w_int_proy_tot   = SUM(am_cuota),
       @w_int_acu_tot   = SUM(am_acumulado)
from ca_amortizacion
where am_operacion = @i_operacionca
and   am_concepto  = 'INT'
and   am_dividendo = @i_cuota_prorroga


select @w_diff_acu   = @w_int_causado_pro - @w_int_acu_tot,
       @w_diff_cuota = @w_int_nue_pro - @w_int_proy_tot

--update #int_act
--set cuota     = cuota + @w_diff_cuota,
--    acumulado = acumulado + @w_diff_acu
--where dividendo = @i_cuota_prorroga
--and   secuencia = (select MAX(secuencia) from #int_act where dividendo = @i_cuota_prorroga)

--if @@error <> 0
--begin
--   /* ERROR AL ACTUALIZAR CUOTA DE INTERES DE LA CUOTA A PRORROGAR EN TABLA TEMPORAL */
--   select 
--   @w_msg = 'ERROR AL ACTUALIZAR CUOTA DE INTERES DE LA CUOTA A PRORROGAR EN TABLA TEMPORAL',
--   @w_error   = 710002

--   goto ERRORFIN
--end                  

/* ACTUALIZA INTERESES CUOTA PROYECTADO Y ACUMULADO CUOTA PRORROGADA */
update ca_amortizacion
set am_cuota     = am_cuota + @w_diff_cuota,
    am_acumulado = am_acumulado + @w_diff_acu
where am_operacion = @i_operacionca
and   am_concepto = 'INT'
and   am_dividendo = @i_cuota_prorroga
and   am_secuencia = (select MAX(am_secuencia) from ca_amortizacion
                      where am_operacion = @i_operacionca 
                      and   am_concepto = 'INT'
                      and   am_dividendo = @i_cuota_prorroga)

if @@error <> 0
begin
   /* ERROR AL ACTUALIZAR INTERES PROYECTADO CUOTA PRORROGADA */
   select 
   @w_msg = 'ERROR AL ACTUALIZAR TABLA DE AMORTIZACION CUOTA PRORROGADA',
   @w_error   = 710002          

   goto ERRORFIN
end

/* ACTUALIZA INTERES PROYECTADO, INTERES ACUMULADO Y ESTADO DE LA CUOTA SIGUIENTE */
delete ca_amortizacion
where am_operacion = @i_operacionca
and   am_concepto = 'INT'
and   am_dividendo = @i_cuota_prorroga + 1

if @@error <> 0
begin
   /* ERROR AL ELIMINAR RUBROS DE INTERES DE LA CUOTA SIGUIENTE EN LA TABLA DE AMORTIZACION */
   select 
   @w_msg = 'ERROR AL ELIMINAR RUBROS DE INTERES DE LA CUOTA SIGUIENTE EN LA TABLA DE AMORTIZACION',
   @w_error   = 710002

   goto ERRORFIN
end                  


insert into ca_amortizacion (am_operacion, am_dividendo, am_concepto,
                             am_estado,    am_periodo,   am_cuota,
                             am_gracia,    am_pagado,    am_acumulado,
                             am_secuencia)
values (@i_operacionca,  @i_cuota_prorroga+ 1, 'INT', 
        @w_op_estado,    0,                 @w_int_nue_sig, 
        0,               0,                 0, 
        1)

if @@error <> 0
begin
   /* ERROR AL INSERTAR ROBRO DE INTERES EN SUSPENSO DE LA CUOTA A PRORROGAR */
   select 
   @w_msg = 'ERROR AL INSERTAR RUBRO DE INTERES EN SUSPENSO DE LA CUOTA SIGUIENTE',
   @w_error   = 710001

   goto ERRORFIN
end    


/* ACTUALIZA LA MARCA DE REESTRUCTURADO PARA LA OPERACION NORMALIZADA */
update cob_cartera..ca_operacion
set op_numero_reest = op_numero_reest + 1,
    op_reestructuracion = 'S'
where op_operacion = @i_operacionca    
                     
if @@error <> 0
begin
   /* ERROR AL ACTUALIZA FECHA DE PROROGA */
 select 
   @w_msg = 'ERROR AL ACTUALIZAR LA MARCA DE REESTRUCTURADOS DE LA OPERACION',
   @w_error   = 710002       

   goto ERRORFIN
end

/* INSERTA TABLA DE CONTROL DE NORMALIZACION DE CARTERA */
insert into ca_normalizacion (nm_tramite, nm_cliente, nm_tipo_norm, nm_estado, nm_fecha_apl,nm_fecha_pro_antes,nm_fecha_pro_despues,nm_cuota_pro)
values (isnull(@w_tramite,0), @w_op_cliente, 1, 'A', @w_fecha_proceso,@w_fecha_fin_pro,@i_fecha_prorroga,@i_cuota_prorroga)

if @@error <> 0
begin
   /* ERROR AL INSERTAR EN TABLA DE CONTROL DE NORMALIZACION DE CARTERA */
   select 
   @w_msg   = 'ERROR AL INSERTAR EN TABLA DE CONTROL DE NORMALIZACION DE CARTERA',
   @w_error = 710001

   goto ERRORFIN
end   

return 0

ERRORFIN:
   if @i_debug = 'S'
      print @w_msg
      
--exec cobis..sp_helptext sp_cerror
--@t_from  = @w_sp_name,
--@i_num   = @w_error,
--@i_msg   = @w_msg,
--@i_sev   = 0


--exec sp_errorlog
--@i_fecha        = @w_fecha_proceso,
--@i_error        = @w_error,
--@i_usuario      = @s_user,
--@i_tran_name    = 'PROFECHA',
--@i_tran         = 0,
--@i_rollback     = 'N',
--@i_descripcion  = @w_msg

return @w_error

go
