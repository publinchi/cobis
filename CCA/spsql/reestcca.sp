/********************************************************************/
/*  Archivo:            reestcca.sp                                 */
/*  Stored procedure:   sp_reestructuracion_cca                     */
/*  Base de datos:      cob_cartera                                 */
/*  Producto:           Cartera                                     */
/*  Disenado por:       RRB                                         */
/*  Fecha de escritura: Abr 09                                      */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/  
/*                              PROPOSITO                           */
/*  Stored procedure autorizado por Cartera para restructurar       */
/*  un prestamo desde otro modulo cobis                             */
/* 04/10/2010        Yecid Martinez     Fecha valor baja Intensidad */
/*                                      NYMR 7x24                   */
/* 22/Feb/2011        Johan Ardila      REQ 246 - Reestructuraciones*/
/* MAR-2011          Elcira Pelaez B    Recalculo FNG despues de    */
/*                                      la Reestructuracion cuando  */
/*                                      el saldo ya esta definido   */
/* MAR-2015          Elcira Pelaez B    NR.436. BANCAMIA            */
/* 17/abr/2023     Guisela Fernandez    S807925 Ingreso de campo    */
/*                                      de reestructuracion         */
/********************************************************************/

use cob_cartera
go
set ansi_warnings off
go
if exists (select 1 from sysobjects where name = 'sp_reestructuracion_cca')
   drop proc sp_reestructuracion_cca
go

---NR.436 NORMALIZACION MAR.26.2015

create proc sp_reestructuracion_cca 
   @s_user               login        = null,
   @s_term              varchar(30)  = null,
   @s_sesn               int          = null,
   @s_date               datetime     = null,
   @s_ofi                smallint     = null,
   @i_banco              cuenta       = null,
   @i_anterior           cuenta       = null,
   @i_migrada            cuenta       = null,
   @i_tramite            int          = null,
   @i_cliente            int          = null,
   @i_nombre             descripcion  = null,
   @i_sector             catalogo     = null,
   @i_toperacion         catalogo     = null,
   @i_oficina            smallint     = null,
   @i_moneda             tinyint      = null,
   @i_comentario         varchar(255) = null,
   @i_oficial            smallint     = null,
   @i_fecha_ini          datetime     = null,
   @i_fecha_fin          datetime     = null,
   @i_fecha_ult_proceso  datetime     = null,
   @i_fecha_liq          datetime     = null,
   @i_fecha_reajuste     datetime     = null,
   @i_monto              money        = null,
   @i_monto_aprobado     money        = null,
   @i_destino            catalogo     = null,
   @i_lin_credito        cuenta       = null,
   @i_ciudad             int          = null,
   @i_periodo_reajuste   smallint     = null,
   @i_reajuste_especial  char(1)      = null,
   @i_tipo               char(1)      = null,
   @i_forma_pago         catalogo     = null,
   @i_cuenta             cuenta       = null,
   @i_dias_anio          smallint     = null,
   @i_tipo_amortizacion  varchar(10)  = null,
   @i_cuota_completa     char(1)      = null,
   @i_tipo_cobro         char(1)      = null,
   @i_tipo_reduccion     char(1)      = null,
   @i_aceptar_anticipos  char(1)      = null,
   @i_precancelacion     char(1)      = null,
   @i_tipo_aplicacion    char(1)      = null,
   @i_tplazo             catalogo     = null,
   @i_plazo              int          = null,
   @i_tdividendo         catalogo     = null,
   @i_periodo_cap        int          = null,
   @i_periodo_int        int          = null,
   @i_dist_gracia        char(1)      = null,
   @i_gracia_cap         int          = null,
   @i_gracia_int         int          = null,
   @i_dia_fijo           int          = null,
   @i_cuota              money        = null,
   @i_evitar_feriados    char(1)      = null,
   @i_renovacion         char(1)      = null,
   @i_mes_gracia         tinyint      = null,
   @i_formato_fecha      int          = 101, 
   @i_upd_clientes       char(1)      = null,
   @i_dias_gracia        smallint     = null,
   @i_reajustable        char(1)      = null,
   @i_clase_cartera      catalogo     = null,
   @i_origen_fondos      catalogo     = null,
   @i_dias_clausula      int          = null,
   @i_reestructuracion   char(1)      = null,
   @i_convierte_tasa     char(1)      = null,
   @i_tramite_nuevo      int          = null,
   @i_paso               Char(1)      = null, -- (S) Simulacion � (D) Defintiva - (C) Consulta - (T) Borra Temporales - (P) Valida Pago
   @i_pago               Char(1)      = null, -- (S) Exige Pago � (N) No Exige Pago
   @i_tasa               float        = -1,   -- Nueva tasa Efectiva
   @i_dividendo          int          = null,
   @i_opcion             tinyint      = null,
   @i_concepto           catalogo     = '',
   @i_fecha_fija_pago    Char(1)      = null,
   @i_bloquear_salida    char(1)      = 'N',
   @i_validar_cuota      char(1)      = 'N',
   @i_batch              char(1)      = 'N'
   
   
as declare  
   @w_sp_name            varchar(30),
   @w_operacionca        int,
   @w_max_sec_rec        int,
   @w_ro_porcentaje      float,
   @w_dias_anio          smallint,
   @w_tdividendo         char(1),
   @w_ro_fpago           char(1),
   @w_rot_num_dec        tinyint,
   @w_error              int,
   @w_filas_rubros       int,
   @w_primer_des         int,
   @w_bytes_env          int,
   @w_filas              int,
   @w_buffer             int,
   @w_count              int,
   @w_monto              money,
   @w_concepto           catalogo, 
   @w_dividendo_ini      int,
   @w_estado             tinyint,
   @w_est_vigente        tinyint,
   @w_est_vencido        tinyint,
   @w_fecha_ult_pago     smalldatetime,
   @w_fecha_ult_proceso  smalldatetime,
   @w_cuota_inicial      money,
   @w_cuota_reest        float,
   @w_dias_pago          tinyint,
   @w_cuota_res          money,
   @w_max_tram_rees      int,
   @w_val_pend           money,
   @w_tramite            int,
   @w_monto_cap          money,
   @w_parametro_fng      catalogo,
   @w_di_dividendo       int,
   @w_secuencial         int,
   @w_tramite_reest      int,
   @w_cod_gar_fng        catalogo,
   @w_monto_hisrorico    money,
   @w_diff               money,
   @w_max_div_reest      smallint,                       -- REQ 175: PEQUE�A EMPRESA
   @w_divini_reg         smallint,                       -- REQ 175: PEQUE�A EMPRESA
   @w_opcion_cap         char(1),                         -- REQ 175: PEQUE�A EMPRESA
   @w_tiene_fng          char(1),
   @w_op_hija            int,
   @w_secuencial_res     int,
   @w_banco_hija         cuenta,
   @w_monto_otros        money,
   @w_cuota              money,
   @w_div_vigente        int,
   @w_fecha_hoy          datetime,
   @w_cap_pagado         money ,
   @w_val_capitalizar    money,
   @w_op_monto           money,
   @w_secuencial_trn     int,
   @w_saldo_antes        money,
   @w_saldo_ok           money,
   @w_monto_amor         money,
   @w_min_div_reest      smallint,
   @w_co_categoria       char(1),
   @w_cap_amor_antes     money,
   @w_est_novigente      tinyint,
   @w_est_suspenso       tinyint,
   @w_plazo_tramite      int,
   @w_tplazo_inicial     char(1),
   @w_tplazo_tmp         char(1),
   @w_op_cuota_tmp       money,   
   @w_cambio_rubros      tinyint,
   @w_con_r              catalogo,
   @w_con_t              catalogo,
   @w_linea_hija         catalogo,
   @w_toperacion         catalogo,
   @w_tipo               char(1),
   @w_total_capitalizado money,
   @w_tr_sujcred         catalogo,
   @w_superior_fng       char(10),
   @w_tdividendo_org     catalogo,
   @w_tasa_org           float,
   @w_tr_tipo_cuota      catalogo,
   @w_rfechant           char(1),
   @w_cliente_victima    char(1),
   @w_op_cliente         int,
   @w_parametro_VHV      catalogo
   
--- VARIABLES INICIALES 
select   
@w_sp_name            = 'sp_reestructuracion_cca',
@w_buffer             = 2500,   --TAMANIO MAXIMO DEL BUFFER DE RED
@w_cambio_rubros      = 0,
@w_op_hija            = 0,
@w_monto_otros        = 0,
@w_val_pend           = 0,
@w_total_capitalizado = 0

select @w_fecha_hoy = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

if @s_date is null
select  @s_date = @w_fecha_hoy
        
--- MAXIMO % NUEVA PARA CUOTA 
select @w_cuota_reest = pa_float
from cobis..cl_parametro
where pa_nemonico = 'MPNC'
and pa_producto = 'CCA'

--- MINIMO DIAS PARA PAGO 
select @w_dias_pago = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'MDPP'
and pa_producto = 'CCA'

--- PARAMETRO PARA REALIZAR REESTRUCTURACION CON FECHA OPERACION <> FECHA DE PROCESO 
select @w_rfechant = pa_char
from cobis..cl_parametro
where pa_nemonico = 'RFECHA'
and pa_producto = 'CCA'

--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_suspenso   = @w_est_suspenso  out

if @w_error <> 0 goto ERROR

---PARAMETRO DE LA GARANTIA DE FNG
select @w_parametro_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'

select @w_linea_hija = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'OPHIJA'

select @w_superior_fng = pa_char   
 from cobis..cl_parametro
where pa_nemonico = 'GARFNG'
 and pa_producto = 'CCA'  
 set transaction isolation level read uncommitted

 
select 
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_operacionca       = op_operacion,
@w_estado            = op_estado,
@w_op_monto          = op_monto,
@w_tramite_reest     = op_tramite,
@w_toperacion        = op_toperacion,
@w_op_cliente        = op_cliente
from ca_operacion
where op_banco = @i_banco   

select @w_tramite = isnull(max(tr_tramite),0)
from cob_credito..cr_tramite
where tr_numero_op = @w_operacionca
and tr_tipo        = 'E'
and tr_estado     <> 'Z'

---VALIDACION QUE SEA UN TRAMITE DE VHV
select @w_parametro_VHV = pa_char
from cobis..cl_parametro
where pa_nemonico = 'VHV'
and pa_producto = 'CRE'

-- INI JAR REQ 246 -- Si la operacion esta amparada por garantia FNG debe crearse operacion hija por el monto de los valores diferidos

---CODIGO PADRE GARANTIA DE FNG
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and pa_nemonico   = 'CODFNG'   

select tc_tipo as tipo 
into #garfng
from cob_custodia..cu_tipo_custodia
where tc_tipo_superior = @w_cod_gar_fng

---RECUPERAR LAS GARANTAIS INICIALES PARA TEENRLAS ANTES DE RECALCULAR EL FNG EN LA TABLA DE AMORTIZACION
---INC110938
if exists (select 1 from cob_cartera..ca_gar_propuesta_tmp
          where gpt_tramite = @w_tramite_reest)
begin
     
    delete cob_credito..cr_gar_propuesta
    where gp_tramite = @w_tramite_reest
    
	if @@error <> 0 begin
	    select @w_error = 707016
	    goto ERROR
	 end	    
    insert into cob_credito..cr_gar_propuesta
    select gpt_tramite,gpt_garantia,gpt_clasificacion,gpt_exceso,gpt_monto_exceso,
           gpt_abierta,gpt_deudor,gpt_est_garantia,gpt_porcentaje,gpt_valor_resp_garantia,
           gpt_fecha_mod,gpt_proceso,gpt_procesado,gpt_previa, gpt_saldo_cap_op
    from cob_cartera..ca_gar_propuesta_tmp
    where gpt_tramite = @w_tramite_reest
    and   gpt_tramite_E = @w_tramite
    
	if @@error <> 0 begin
	     print ' reestca.sp entro a poner las garantias' + cast (@w_tramite_reest as varchar) + 'tramite O ' + cast (@w_tramite as varchar)
	    select @w_error = 708154
	    goto ERROR
	 end	    
    
end          
     
--INC110938


if exists (select 1 from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta, cob_credito..cr_tramite, #garfng
           where gp_tramite   = @w_tramite_reest
           and gp_garantia  = cu_codigo_externo 
           and cu_estado    in ('P','F','V')
           and tr_tramite   = gp_tramite
           and cu_tipo      = tipo)
   select @w_tiene_fng = 'S'
else
   select @w_tiene_fng = 'N'
   
--- NO SE PERMITE REESTRUCTURAR OPERACIONES CASTIGADAS, CANCELADAS O NO VIGENTES 
if @w_estado in (0,99,3,4) and @w_tipo = 'E' begin
   PRINT 'reestcca.sp INF. T.Tram. ' + cast (@w_tipo as varchar) + 'Est.Oper: ' + cast (@w_estado as varchar) + 'Tramite_new: ' + cast (@w_tramite as varchar)
   select @w_error = 701010
   goto ERROR
end


--SPO Req059 Valores tabla de rubros
select @w_tramite = max(tr_tramite)
from cob_credito..cr_tramite
where tr_numero_op = @w_operacionca
and tr_tipo        = 'E'
and tr_estado     <> 'Z'

if @w_tramite is null
begin
   select @w_tramite = max(tr_tramite)
   from cob_credito..cr_tramite
   where tr_numero_op = @w_operacionca
   and tr_tipo        = 'E'
   and tr_estado      = 'Z'
end

--- Tomar los datos definidos en tramites d desde credito
select @w_tr_sujcred    = tr_sujcred,
       @w_tr_tipo_cuota = tr_tipo_cuota,
       @i_toperacion    = tr_toperacion
from cob_credito..cr_tramite
where tr_tramite = @w_tramite
   

-- Cargar valores e reestructuracion
-- Cambio de L�nea
if exists (select 1 from ca_op_reest_padre_hija where ph_op_padre = @w_operacionca) or
   @i_toperacion <>  @w_toperacion
   select @i_periodo_cap = dt_periodo_cap,
          @i_periodo_int = dt_periodo_int,
          @i_gracia_cap  = dt_gracia_cap,
          @i_gracia_int  = dt_gracia_int,
          @i_dist_gracia = dt_dist_gracia
   from ca_default_toperacion
   where dt_toperacion = @i_toperacion
else
   select 
   @i_periodo_cap = isnull(rg_per_pago_capital,@i_periodo_cap) ,
   @i_periodo_int = isnull(rg_per_pago_int,@i_periodo_int),
   @i_gracia_cap  = isnull(rg_gracia_capital,@i_gracia_cap),
   @i_gracia_int  = isnull(rg_gracia_int,@i_gracia_int),
   @i_dist_gracia = isnull(rg_dist_gracia,@i_dist_gracia)
   from cob_credito..cr_reest_gracia
   where rg_banco      = @i_banco

if @i_paso = 'S' begin -- (S) Simulacion 

   select @w_tipo = tr_tipo
   from cob_credito..cr_tramite
   where tr_tramite = @w_tramite
   
	if @w_estado in (0,99,3,4) and @w_tipo = 'E' begin
	   PRINT 'reestcca.sp INF. T.Tram. ' + cast (@w_tipo as varchar) + 'Est.Oper: ' + cast (@w_estado as varchar) + 'TramiteOri: ' + cast (@w_tramite_reest as varchar)
	   select @w_error = 701010
	   goto ERROR
	end

  
	 ---Inc 34262 
    if ( select di_fecha_ini
         from ca_dividendo
         where di_operacion = @w_operacionca
         and   di_estado    = 1
        ) > @w_fecha_ult_proceso
        and @w_tipo = 'E'
    begin
       select @w_error = 701192
       goto ERROR
    end   
    ---Inc 34262 

    select @w_cap_amor_antes = 0
    
	select @w_cap_amor_antes = sum(am_cuota)
    from ca_amortizacion, ca_rubro_op
    where am_operacion  = @w_operacionca
    and   am_operacion  = ro_operacion
    and   am_concepto   = ro_concepto 
    and   ro_tipo_rubro = 'C'
    
    if @w_op_monto <> @w_cap_amor_antes
     begin
          ----EL MONTRO DEL CAPITAL DEBE SER IGUAL  A LA DISTRIBUCION
          ---PUDO MODIFICARSE EN LA SIMULACION REALIZADA DESDE CREDITO
          update ca_operacion
          set op_monto = @w_cap_amor_antes,
              op_monto_aprobado = @w_cap_amor_antes
          where op_banco = @i_banco
     end

    delete ca_datos_reestructuraciones_cca
    where res_secuencial_res = -999999
    and   res_operacion_cca = @w_operacionca
   
    select @w_min_div_reest = min(di_dividendo)
	from ca_dividendo
	where di_operacion = @w_operacionca
	and   di_estado in (@w_est_vigente, @w_est_vencido) 

	select @w_max_div_reest = max(di_dividendo)
	from ca_dividendo
	where di_operacion = @w_operacionca
	and   di_estado in (@w_est_vigente, @w_est_vencido) 

   --SPO Req059 Valores tabla de rubros

   if exists (select 1 from ca_datos_reestructuraciones_cca
        	   where res_secuencial_res <> -999999
               and   res_tramite_cre   = @w_tramite
               and   res_estado_tran   = 'ING'
               and   res_operacion_cca = @w_operacionca
               and   @i_batch = 'N')
    begin
      select @w_error = 710148
      goto ERROR
    end  
          
	select  @w_cap_pagado = isnull(sum(am_pagado),0)
	from ca_amortizacion
	where am_operacion = @w_operacionca
	and am_estado <> 3
	and am_acumulado > 0
	and am_concepto = 'CAP'
	and am_pagado > 0

   ---EN ESTE MOMENTO SE CARGAN LOS DATOS INICIALES DE LA AOBLIGACION
   Insert into ca_datos_reestructuraciones_cca 
          (res_tramite_cre, res_operacion_cca,   res_saldo_cap_antes , res_valor_capitalizado, res_saldo_cap_depues, 
           res_usuario_cca, res_fecha_final_trn, res_secuencial_res ,  res_estado_tran ,res_pagado_CAP,res_min_div_rees,
           res_cuota_anterior)
   values (@w_tramite,      @w_operacionca,      @w_cap_amor_antes,    0,       0,
           @s_user,         getdate(),          -999999 ,                'ING',              @w_cap_pagado, @w_min_div_reest,
           @w_cuota_inicial
           )

   if @w_max_div_reest = 1 and @i_batch = 'N'
    begin
       ---POR lA INVERNAL NO SE CAPITALIZA  NI SE PAGA
       ---SE VUELVEN A CALCULAR EN LA CUOTA POR QUEPARTE DE La 1
       update ca_amortizacion
	   set am_acumulado = am_pagado
	   from ca_amortizacion,ca_rubro_op
	   where am_operacion = @w_operacionca
	   and   am_dividendo = @w_max_div_reest 
	   and   am_acumulado > 0
	   and   am_operacion = ro_operacion
	   and   am_concepto  = ro_concepto
	   and   ro_tipo_rubro not in('C','I','M')    
    end
    
   if not exists (select 1 from ca_operacion_tmp where opt_operacion = @w_operacionca )
   begin
  
	   --- GENERAR TABLAS TEMPORALES 
	   exec @w_error = sp_crear_tmp
	   @s_user            = @s_user,
	   @s_term            = @s_term,
	   @i_banco           = @i_banco,
	   @i_bloquear_salida = @i_bloquear_salida,
	   @i_accion          = 'R'
	   
	   if @w_error <> 0 goto ERROR
   end
  
  -- JH Se agregan las columnas de la tabla 
   if not exists (select 1 from ca_rubro_op_reest where ror_operacion = @w_operacionca) begin
      insert into ca_rubro_op_reest  (
	    ror_operacion,             ror_concepto,               ror_tipo_rubro,
        ror_fpago,                 ror_prioridad,              ror_paga_mora,
        ror_provisiona,            ror_signo,                  ror_factor,
        ror_referencial,           ror_signo_reajuste,         ror_factor_reajuste,
        ror_referencial_reajuste,  ror_valor,                  ror_porcentaje,
        ror_porcentaje_aux,        ror_gracia,                 ror_concepto_asociado,
        ror_redescuento,           ror_intermediacion,         ror_principal,
        ror_porcentaje_efa,        ror_garantia,               ror_tipo_puntos,
        ror_saldo_op,              ror_saldo_por_desem,        ror_base_calculo,
        ror_num_dec,               ror_limite,                 ror_iva_siempre,
        ror_monto_aprobado,        ror_porcentaje_cobrar,      ror_tipo_garantia,
        ror_nro_garantia,          ror_porcentaje_cobertura,   ror_valor_garantia,
        ror_tperiodo,              ror_periodo,                ror_tabla,
        ror_saldo_insoluto,        ror_calcular_devolucion
      )
      select
	    rot_operacion,             rot_concepto,               rot_tipo_rubro,
        rot_fpago,                 rot_prioridad,              rot_paga_mora,
        rot_provisiona,            rot_signo,                  rot_factor,
        rot_referencial,           rot_signo_reajuste,         rot_factor_reajuste,
        rot_referencial_reajuste,  rot_valor,                  rot_porcentaje,
        rot_porcentaje_aux,        rot_gracia,                 rot_concepto_asociado,
        rot_redescuento,           rot_intermediacion,         rot_principal,
        rot_porcentaje_efa,        rot_garantia,               rot_tipo_puntos,
        rot_saldo_op,              rot_saldo_por_desem,        rot_base_calculo,
        rot_num_dec,               rot_limite,                 rot_iva_siempre,
        rot_monto_aprobado,        rot_porcentaje_cobrar,      rot_tipo_garantia,
        rot_nro_garantia,          rot_porcentaje_cobertura,   rot_valor_garantia,
        rot_tperiodo,              rot_periodo,                rot_tabla,
        rot_saldo_insoluto,        rot_calcular_devolucion
	  from ca_rubro_op_tmp where rot_operacion   = @w_operacionca 
   end
   else begin

      if @w_cambio_rubros = 0 begin
         select @w_cambio_rubros = count(1) from ca_rubro_op, ca_rubro_op_tmp
         where rot_operacion   = @w_operacionca 
         and   ro_operacion   = rot_operacion
         and   ro_concepto    = rot_concepto
         and  (ro_porcentaje_efa <> rot_porcentaje_efa or ro_porcentaje <> rot_porcentaje or 
               ro_factor         <> rot_factor         or ro_signo      <> rot_signo)
      end

      if @w_cambio_rubros = 0 begin
         select @w_con_r = '', @w_con_t = ''
         while 1 = 1 begin
            set rowcount 1
            select @w_con_r = ro_concepto  from ca_rubro_op     where ro_operacion = @w_operacionca  and ro_concepto  > @w_con_r order by ro_concepto 
            select @w_con_t = rot_concepto from ca_rubro_op_tmp where rot_operacion = @w_operacionca and rot_concepto > @w_con_t order by rot_concepto 
            if @@rowcount = 0 
               break
            if @w_con_r <> @w_con_t begin
               select @w_cambio_rubros = 1 
               break
            end
         end
         set rowcount 0
      end

      if @w_cambio_rubros > 0 begin
         delete ca_rubro_op_reest where ror_operacion = @w_operacionca 
         insert into ca_rubro_op_reest(
	        ror_operacion,             ror_concepto,               ror_tipo_rubro,
            ror_fpago,                 ror_prioridad,              ror_paga_mora,
            ror_provisiona,            ror_signo,                  ror_factor,
            ror_referencial,           ror_signo_reajuste,         ror_factor_reajuste,
            ror_referencial_reajuste,  ror_valor,                  ror_porcentaje,
            ror_porcentaje_aux,        ror_gracia,                 ror_concepto_asociado,
            ror_redescuento,           ror_intermediacion,         ror_principal,
            ror_porcentaje_efa,        ror_garantia,               ror_tipo_puntos,
            ror_saldo_op,              ror_saldo_por_desem,        ror_base_calculo,
            ror_num_dec,               ror_limite,                 ror_iva_siempre,
            ror_monto_aprobado,        ror_porcentaje_cobrar,      ror_tipo_garantia,
            ror_nro_garantia,          ror_porcentaje_cobertura,   ror_valor_garantia,
            ror_tperiodo,              ror_periodo,                ror_tabla,
            ror_saldo_insoluto,        ror_calcular_devolucion
        )
         select 
			rot_operacion,             rot_concepto,               rot_tipo_rubro,
            rot_fpago,                 rot_prioridad,              rot_paga_mora,
            rot_provisiona,            rot_signo,                  rot_factor,
            rot_referencial,           rot_signo_reajuste,         rot_factor_reajuste,
            rot_referencial_reajuste,  rot_valor,                  rot_porcentaje,
            rot_porcentaje_aux,        rot_gracia,                 rot_concepto_asociado,
            rot_redescuento,           rot_intermediacion,         rot_principal,
            rot_porcentaje_efa,        rot_garantia,               rot_tipo_puntos,
            rot_saldo_op,              rot_saldo_por_desem,        rot_base_calculo,
            rot_num_dec,               rot_limite,                 rot_iva_siempre,
            rot_monto_aprobado,        rot_porcentaje_cobrar,      rot_tipo_garantia,
            rot_nro_garantia,          rot_porcentaje_cobertura,   rot_valor_garantia,
            rot_tperiodo,              rot_periodo,                rot_tabla,
            rot_saldo_insoluto,        rot_calcular_devolucion
		 from ca_rubro_op_tmp where rot_operacion   = @w_operacionca       
      end
      else begin
         delete ca_rubro_op_tmp where rot_operacion = @w_operacionca 
         insert into ca_rubro_op_tmp (
			rot_operacion,             rot_concepto,               rot_tipo_rubro,
			rot_fpago,                 rot_prioridad,              rot_paga_mora,
			rot_provisiona,            rot_signo,                  rot_factor,
			rot_referencial,           rot_signo_reajuste,         rot_factor_reajuste,
			rot_referencial_reajuste,  rot_valor,                  rot_porcentaje,
			rot_porcentaje_aux,        rot_gracia,                 rot_concepto_asociado,
			rot_redescuento,           rot_intermediacion,         rot_principal,
			rot_porcentaje_efa,        rot_garantia,               rot_tipo_puntos,
			rot_saldo_op,              rot_saldo_por_desem,        rot_base_calculo,
			rot_num_dec,               rot_limite,                 rot_iva_siempre,
			rot_monto_aprobado,        rot_porcentaje_cobrar,      rot_tipo_garantia,
			rot_nro_garantia,          rot_porcentaje_cobertura,   rot_valor_garantia,
			rot_tperiodo,              rot_periodo,                rot_tabla,
			rot_saldo_insoluto,        rot_calcular_devolucion
		 )
         select 
			ror_operacion,             ror_concepto,               ror_tipo_rubro,
            ror_fpago,                 ror_prioridad,              ror_paga_mora,
            ror_provisiona,            ror_signo,                  ror_factor,
            ror_referencial,           ror_signo_reajuste,         ror_factor_reajuste,
            ror_referencial_reajuste,  ror_valor,                  ror_porcentaje,
            ror_porcentaje_aux,        ror_gracia,                 ror_concepto_asociado,
            ror_redescuento,           ror_intermediacion,         ror_principal,
            ror_porcentaje_efa,        ror_garantia,               ror_tipo_puntos,
            ror_saldo_op,              ror_saldo_por_desem,        ror_base_calculo,
            ror_num_dec,               ror_limite,                 ror_iva_siempre,
            ror_monto_aprobado,        ror_porcentaje_cobrar,      ror_tipo_garantia,
            ror_nro_garantia,          ror_porcentaje_cobertura,   ror_valor_garantia,
            ror_tperiodo,              ror_periodo,                ror_tabla,
            ror_saldo_insoluto,        ror_calcular_devolucion
		 from ca_rubro_op_reest where ror_operacion = @w_operacionca 
      end
   end              

   select 
   @w_cuota_inicial     = op_cuota,
   @w_tplazo_inicial    = op_tplazo,
   @i_anterior          = isnull(@i_anterior,          op_anterior),          
   @i_migrada           = isnull(@i_migrada,           op_migrada),           
   @i_tramite           = isnull(@i_tramite,           op_tramite),           
   @i_cliente           = isnull(@i_cliente,           op_cliente),           
   @i_nombre            = isnull(@i_nombre,            op_nombre),            
   @i_sector            = isnull(@i_sector,            op_sector),            
   @i_toperacion        = isnull(@i_toperacion,        op_toperacion),        
   @i_oficina           = isnull(@i_oficina,           op_oficina),           
   @i_moneda            = isnull(@i_moneda,            op_moneda),            
   @i_comentario        = isnull(@i_comentario,        op_comentario),        
   @i_oficial           = isnull(@i_oficial,           op_oficial),           
   @i_fecha_ini         = isnull(@i_fecha_ult_proceso, op_fecha_ult_proceso), 
   @i_fecha_fin         = isnull(@i_fecha_fin,         op_fecha_fin),         
   @i_fecha_ult_proceso = isnull(@i_fecha_ult_proceso, op_fecha_ult_proceso), 
   @i_fecha_liq         = isnull(@i_fecha_liq,         op_fecha_liq),         
   @i_fecha_reajuste    = isnull(@i_fecha_reajuste,    op_fecha_reajuste),    
   @i_monto             = isnull(@i_monto,             op_monto),             
   @i_monto_aprobado    = isnull(@i_monto_aprobado,    op_monto_aprobado),    
   @i_destino           = isnull(@i_destino,           op_destino),           
   @i_lin_credito       = isnull(@i_lin_credito,       op_lin_credito),       
   @i_ciudad            = isnull(@i_ciudad,            op_ciudad),            
   @i_periodo_reajuste  = isnull(@i_periodo_reajuste,  op_periodo_reajuste),  
   @i_reajuste_especial = isnull(@i_reajuste_especial, op_reajuste_especial), 
   @i_tipo              = isnull(@i_tipo,              op_tipo),              --(Hipot/Redes/Normal)
   @i_forma_pago        = isnull(@i_forma_pago,        op_forma_pago),        
   @i_cuenta            = isnull(@i_cuenta,            op_cuenta),            
   @i_dias_anio         = isnull(@i_dias_anio,         op_dias_anio),         
   @i_tipo_amortizacion = isnull(@i_tipo_amortizacion, op_tipo_amortizacion), 
   @i_cuota_completa    = isnull(@i_cuota_completa,    op_cuota_completa),    
   @i_tipo_cobro        = isnull(@i_tipo_cobro,        op_tipo_cobro),        
   @i_tipo_reduccion    = isnull(@i_tipo_reduccion,    op_tipo_reduccion),    
   @i_aceptar_anticipos = isnull(@i_aceptar_anticipos, op_aceptar_anticipos), 
   @i_precancelacion    = isnull(@i_precancelacion,    op_precancelacion),    
   @i_tipo_aplicacion   = isnull(@i_tipo_aplicacion,   op_tipo_aplicacion),   
   @i_tplazo            = isnull(@i_tplazo,            op_tplazo),            
   @i_plazo             = isnull(@i_plazo,             op_plazo),             
   @i_tdividendo        = isnull(@i_tdividendo,        @w_tr_tipo_cuota),        
   @i_periodo_cap       = isnull(@i_periodo_cap,       op_periodo_cap),       
   @i_periodo_int       = isnull(@i_periodo_int,       op_periodo_int),       
   @i_dist_gracia       = isnull(@i_dist_gracia,       op_dist_gracia),       
   @i_gracia_cap        = isnull(@i_gracia_cap,        op_gracia_cap),        
   @i_gracia_int        = isnull(@i_gracia_int,        op_gracia_int),        
   @i_dia_fijo          = isnull(@i_dia_fijo,          op_dia_fijo),          
   @i_cuota             = isnull(@i_cuota,             0),             
   @i_evitar_feriados   = isnull(@i_evitar_feriados,   op_evitar_feriados),   
   @i_renovacion        = isnull(@i_renovacion,        op_renovacion),        
   @i_mes_gracia        = isnull(@i_mes_gracia,        op_mes_gracia),        
   @i_upd_clientes      = isnull(@i_upd_clientes,      'N'),      
   @i_reajustable       = isnull(@i_reajustable ,      op_reajustable ),      
   @i_dias_gracia       = isnull(@i_dias_gracia,       0),       
   @i_clase_cartera     = isnull(@i_clase_cartera,     op_clase),     
   @i_origen_fondos     = isnull(@i_origen_fondos,     op_origen_fondos),     
   @i_dias_clausula     = isnull(@i_dias_clausula,     op_dias_clausula),     
   @i_convierte_tasa    = isnull(@i_convierte_tasa,    op_convierte_tasa),
   @w_opcion_cap        = op_opcion_cap                                    -- REQ 175: PEQUE�A EMPRESA
   from ca_operacion
   where op_banco = @i_banco
                  
   select 
   @w_estado        = opt_estado,
   @w_operacionca   = opt_operacion,
   @w_tdividendo    = opt_tdividendo,
   @w_monto         = opt_monto
   from ca_operacion_tmp
   where opt_banco = @i_banco

   select 
   @w_tdividendo_org    = op_tdividendo,
   @w_dias_anio         = op_dias_anio
   from ca_operacion
   where op_banco = @i_banco
      
   ---Nota el itasa no aplica ya quela tasa en RES debe ser conservada
   if (@i_tasa > -1) or (@w_tdividendo_org <>  @w_tr_tipo_cuota )
    begin
      
      select 
      @w_ro_fpago    = rot_fpago,
      @w_rot_num_dec = rot_num_dec,
      @w_tasa_org    = rot_porcentaje_efa
      from ca_rubro_op_tmp
      where rot_operacion = @w_operacionca
      and   rot_tipo_rubro = 'I'
      
      if @w_ro_fpago in ('P', 'T') select @w_ro_fpago = 'V'
      
      exec @w_error = sp_conversion_tasas_int
      @i_periodo_o     = 'A',
      @i_modalidad_o   = 'V',
      @i_num_periodo_o = 1,
      @i_tasa_o        = @w_tasa_org,
      @i_periodo_d     = @w_tr_tipo_cuota,
      @i_modalidad_d   = @w_ro_fpago,
      @i_num_periodo_d = 1,
      @i_dias_anio     = @w_dias_anio,
      @i_num_dec       = @w_rot_num_dec,
      @o_tasa_d        = @w_ro_porcentaje output
      
      if @w_error <> 0 goto ERROR
     
      update ca_rubro_op_tmp set 
      rot_porcentaje     = @w_ro_porcentaje,
      rot_porcentaje_aux = @w_tasa_org,
      rot_porcentaje_efa = @w_tasa_org
      where rot_operacion = @w_operacionca
      and   rot_tipo_rubro = 'I'
      
      if @@rowcount = 0 begin
         select @w_error = 710002
         goto ERROR
      end
   end
   
   exec @w_error = sp_calcula_saldo
   @i_operacion = @w_operacionca,
   @i_tipo_pago = 'A',
   @o_saldo     = @w_monto out
   
   if @w_error <> 0 goto ERROR   

   if (
        (@w_tramite > 0) and (@w_fecha_ult_proceso = @w_fecha_hoy ) and  (@i_batch = 'N')
      ) or
      ( (@w_tramite > 0) and (@i_batch = 'N')  and  (@w_tr_sujcred = @w_parametro_VHV)
       ) or
      ( (@w_tramite > 0) and (@i_batch = 'N')  and  (@w_rfechant = 'S')
       )
   begin
            
      ---ESTA SECCION ES  VALIDA SOLO EL  MISMO DIA DE LA REESTRUCTURACION
      ---DESPUES YA NO POR QUE  YA LO QUE EL CLIENTE PAGO LO PAGO Y EN UNA 
      ---REAPLICACION ESTO NO SE COBRA NUEVAMENTE
           
      -- Valor Orden Pago

      select @w_val_pend  = 0

      select @w_val_pend  = isnull(sum(rp_valor_cobro),0)
      from   cob_credito..cr_rub_pag_reest
      where  rp_tramite = @w_tramite      

      if @w_val_pend > 0
      begin 

	      -- Verificar si ya se realizo el pago para mostrar el saldo real de la operacion
	
	      if not exists (
	         select 1 from ca_abono, ca_abono_det, cob_credito..cr_tramite_cajas, cob_credito..cr_tramite
	         where ab_operacion = @w_operacionca
	         and   ab_operacion = abd_operacion
	         and   ab_secuencial_ing = abd_secuencial_ing
	         and   tc_valor     = abd_monto_mop 
	         and   tc_tramite   = tr_tramite
	         and   ab_estado    = 'A'
	         and   tr_tramite   = @w_tramite
	         and   ab_fecha_ing >= tr_fecha_crea
	         )
	         and   @w_tiene_fng = 'N'
	         begin
	            select @w_monto = @w_monto - @w_val_pend  
	            PRINT 'reestca.sp ATENCION SE RESTARA EL VALOR PAGO GENERADO AL MONTO A REESTRUCTURAR ' + CAST (@w_val_pend as varchar) + ' - Monto: ' + cast(@w_monto as varchar)
	         end
      end
      
      if @w_tiene_fng = 'S' begin      
         select @w_monto = sum(am_acumulado + am_gracia - am_pagado) 
         from ca_amortizacion, ca_rubro_op
         where am_operacion  = @w_operacionca
         and   am_operacion  = ro_operacion
         and   am_concepto   = ro_concepto
         and   ro_tipo_rubro = 'C'
      end      
   end
   else 
   if (@i_batch = 'N') begin
      print 'reestcca.sp (1)No se encontro un tramite de Reestructuracion para la operacion O la operacion no esta en fecha de proceso - Tramite: ' + cast(isnull(@w_tramite, 0) as varchar) + ' - Fecha : ' + cast(isnull(@w_fecha_ult_proceso, '01/01/1000') as varchar) + '@w_fecha_hoy ' + cast(@w_fecha_hoy as varchar)
      select @w_error = 701187
      goto ERROR
   end
  
   select    
   @i_monto          = @w_monto,
   @i_monto_aprobado = @w_monto
          
   update ca_rubro_op_tmp set 	
   rot_valor        = @i_monto,
   rot_base_calculo = 0                            -- REQ 175: PEQUE�A EMPRESA
   where rot_operacion = @w_operacionca
   and   rot_tipo_rubro = 'C'

   if @@error <> 0 begin
      select @w_error = 710002
      goto ERROR
   end            
      
   -- INI - REQ 175: PEQUE�A EMPRESA - DETERMINACION DE GRACIA BASE
   select
   @w_max_div_reest = max(di_dividendo)
   from ca_dividendo
   where di_operacion = @w_operacionca
   and   di_estado in (@w_est_vigente, @w_est_vencido) 

   select
   @w_max_div_reest = @w_max_div_reest - 1
   from ca_dividendo
   where di_operacion = @w_operacionca
   and   di_dividendo = @w_max_div_reest
   and   di_fecha_ini = @i_fecha_ini
   
   select @w_divini_reg = @w_max_div_reest + 1
   
   if @w_opcion_cap <> 'S'
      select @w_opcion_cap = 'C'
   -- FIN - REQ 175: PEQUE�A EMPRESA
   
   --- RECONSTRUIR LA TABLA TEMPORAL 
   exec @w_error = sp_modificar_operacion_int
   @s_user              = @s_user,
   @s_sesn              = @s_sesn,
   @s_date              = @s_date,
   @s_ofi               = @s_ofi,
   @s_term              = @s_term,
   @i_calcular_tabla    = 'S', 
   @i_tabla_nueva       = 'S',
   @i_salida            = 'N',
   @i_operacionca       = @w_operacionca,
   @i_banco             = @i_banco,
   @i_anterior          = @i_anterior,
   @i_migrada           = @i_migrada,
   @i_tramite           = @i_tramite,
   @i_cliente           = @i_cliente,
   @i_nombre            = @i_nombre,
   @i_sector            = @i_sector,
   @i_toperacion        = @i_toperacion,
   @i_oficina           = @i_oficina,
   @i_moneda            = @i_moneda, 
   @i_comentario        = @i_comentario,
   @i_oficial           = @i_oficial,
   @i_fecha_ini         = @i_fecha_ult_proceso,
   @i_fecha_fin         = @i_fecha_fin,
   @i_fecha_ult_proceso = @i_fecha_ult_proceso,
   @i_fecha_liq         = @i_fecha_liq,
   @i_fecha_reajuste    = @i_fecha_reajuste,
   @i_monto             = @i_monto, 
   @i_monto_aprobado    = @i_monto_aprobado, 
   @i_destino           = @i_destino,
   @i_lin_credito       = @i_lin_credito,
   @i_ciudad            = @i_ciudad,
   @i_periodo_reajuste  = @i_periodo_reajuste,
   @i_reajuste_especial = @i_reajuste_especial,
   @i_tipo              = @i_tipo, --(Hipot/Redes/Normal)
   @i_forma_pago        = @i_forma_pago,
   @i_cuenta            = @i_cuenta,
   @i_dias_anio         = @i_dias_anio, 
   @i_tipo_amortizacion = @i_tipo_amortizacion,
   @i_cuota_completa    = @i_cuota_completa,
   @i_tipo_cobro        = @i_tipo_cobro,
   @i_tipo_reduccion    = @i_tipo_reduccion,
   @i_aceptar_anticipos = @i_aceptar_anticipos,
   @i_precancelacion    = @i_precancelacion,
   @i_tipo_aplicacion   = @i_tipo_aplicacion,
   @i_tplazo            = @i_tplazo,
   @i_plazo             = @i_plazo,
   @i_tdividendo        = @w_tr_tipo_cuota,
   @i_periodo_cap       = @i_periodo_cap,
   @i_periodo_int       = @i_periodo_int,
   @i_dist_gracia       = @i_dist_gracia,
   @i_gracia_cap        = @i_gracia_cap,
   @i_gracia_int        = @i_gracia_int,
   @i_dia_fijo          = @i_dia_fijo,
   @i_cuota             = @i_cuota,
   @i_evitar_feriados   = @i_evitar_feriados,
   @i_renovacion        = @i_renovacion,
   @i_mes_gracia        = @i_mes_gracia,
   @i_upd_clientes      = @i_upd_clientes,
   @i_reajustable       = @i_reajustable ,
   @i_dias_gracia       = @i_dias_gracia,
   @i_clase_cartera     = @i_clase_cartera,
   @i_origen_fondos     = @i_origen_fondos,
   @i_dias_clausula     = @i_dias_clausula,
   @i_convierte_tasa    = @i_convierte_tasa,
   @i_actualiza_rubros  = 'N',
   @i_opcion_cap        = @w_opcion_cap,
   @i_valida_param      = 'N', --EN REESTRUCTURACION NO DEBE VALIDAR PARAMETROS   
   @i_divini_reg        = @w_divini_reg,
   @i_reestructuracion  = 'S'

   if @w_error <> 0 goto ERROR   

   if @i_validar_cuota = 'S'
   begin
	   ---COMPARA EL VALOR DE op_cuota 
	   ---ANTES y DESPUES
	    
	   select @w_tplazo_tmp   = opt_tplazo,
	          @w_op_cuota_tmp = opt_cuota
	   from ca_operacion_tmp
	   where opt_operacion = @w_operacionca
	   
	   select @w_plazo_tramite = tr_plazo
	   from cob_credito..cr_tramite
	   where tr_tramite = @w_tramite
	  
	   ----LA VALIDACION DE LA CUOTA DE DEBE HACER SIEMPRE Y CUANDO EL TIPO DE PLAZO SEA EL MISMO
	   ----YA QUENO SE PUEDE COMPARAR ANTES CON MESES Y DESPUES CON TRIMESTRES
	    
	   if ((@w_cuota_inicial * @w_cuota_reest)  < (@w_op_cuota_tmp))  and  @w_tplazo_inicial = @w_tplazo_tmp
	   begin  
	        ----VALIDAR QUE LACUOTA INCIAL ESTE BIEN CALCULADA
	      print 'Cuota anterior :' + cast(@w_cuota_inicial as varchar) +  ' - Porc. permitido: '  + cast(@w_cuota_reest as varchar) +   ' - Nueva Cuota:'  +  cast(@w_op_cuota_tmp as varchar) +  'new-plazo:' +  CAST (@w_plazo_tramite as varchar)
	      select @w_error = 724511
	      goto ERROR
	   end
   end
end

if @i_paso = 'P' begin -- (P) Valida Pago
   
   -- validar si el cliente realizo pago dentro del plazo establecido
   if @i_pago = 'S' begin
      select @w_fecha_ult_pago = isnull(max(ab_fecha_pag),'01/01/1900')
      from ca_abono
      where ab_operacion = @w_operacionca
      and ab_estado = 'A'
   end

   if datediff(dd,@w_fecha_ult_pago,@w_fecha_ult_proceso) > @w_dias_pago begin
      select @w_error = 722109    
      goto ERROR
   end
end

if @i_paso = 'D' begin -- (D) Defintiva 
   
   select @w_cliente_victima = en_victima 
   from cobis..cl_ente
   where en_ente = @w_op_cliente

   if @w_cliente_victima = 'N' or (@w_tr_sujcred <> @w_parametro_VHV)
   begin
     select @w_error = 724032    
     goto ERROR
   end
   
   if  @w_fecha_ult_proceso = @w_fecha_hoy
   begin
	   exec @w_error = cob_credito..sp_trn_cj_reest
	   @s_date         = @s_date,
	   @s_user         = @s_user,
	   @i_operacion    = 'I',
	   @i_cca          = 'S', --LLAMO EL PROCESO DESDE CARTERA
	   @i_banco        = @i_banco  
	
	   if @w_error <> 0 goto ERROR
   end

   begin tran

   -- INICIO JAR REQ 246 -  Crear Operacion Hija con saldos Diferebntes a (K) antes de la reestructuracion.
              
   if @w_tiene_fng = 'S' begin
   
      select @w_monto_otros = 0
      select @w_monto_otros = sum(am_acumulado + am_gracia - am_pagado)
      from ca_amortizacion, ca_rubro_op
      where am_operacion  = @w_operacionca
      and   am_operacion  = ro_operacion
      and   am_concepto   = ro_concepto
      and   ro_tipo_rubro <> 'C'
    
      update ca_operacion
      set op_estado = 6 -- Anular si existen hijas reversadas.
      from ca_op_reest_padre_hija
      where ph_op_padre = @w_operacionca
      and   ph_op_hija  = op_operacion
      and   op_estado   = 0

      select @w_op_hija = 0
      
      if @w_monto_otros > 0 begin
                     
         exec @w_error = sp_creaop_fng
            @s_user           = @s_user,
            @s_date           = @s_date,
            @s_ofi            = @s_ofi,
            @s_term           = @s_term,
            @i_fecha_proceso  = @s_date,
            @i_operacionca    = @w_operacionca,
            @i_sec_reest      = @w_secuencial,
            @i_toperacion     = @w_linea_hija,
            @i_monto          = @w_monto_otros,
            @o_op_hija        = @w_op_hija out,
            @o_secuencial_res = @w_secuencial_res out
         
         if @w_error <> 0
         begin
            print 'reestcca.sp salio con error de sp_creaop_fng ' + cast ( @w_error as varchar)
            goto ERROR
         end
      end
   end
   
   -- FIN JAR REQ 246      
   
   --- REESTRUCTURAR LA OPERACION ORIGINAL 
   exec @w_error = sp_reestructuracion_int
   @s_user        = @s_user,
   @s_term        = @s_term,
   @s_sesn        = @s_sesn,
   @s_date        = @s_date,
   @s_ofi         = @s_ofi,
   @i_banco       = @i_banco,
   @i_num_reest   = 'S',
   @i_op_hija     = @w_op_hija,
   @o_secuencial  = @w_secuencial_trn out
   
   if @w_error <> 0 goto ERROR

   ---VALIDACIONES DEL SALDO DE CAPITAL DESPUES DE REESTRUCTURAR
   select @w_monto_amor  = 0,
          @w_op_monto = 0
   
   select @w_monto_amor = sum(am_cuota)
   from ca_amortizacion, ca_operacion, ca_rubro_op
   where am_operacion  = op_operacion
   and   op_banco      = @i_banco
   and   op_operacion  = ro_operacion
   and   ro_concepto   = am_concepto
   and   ro_tipo_rubro = 'C'
   
   select @w_saldo_antes     = 0,
          @w_saldo_ok        = 0,
          @w_diff            = 0,
          @w_min_div_reest   = 0,
          @w_val_capitalizar = 0,
          @w_op_monto        = @w_monto_amor 
          
   select @w_val_capitalizar  = case @w_tiene_fng when 'N' then res_valor_capitalizado else 0 end,
          @w_saldo_antes      = res_saldo_cap_antes,
          @w_min_div_reest    = res_min_div_rees
   from ca_datos_reestructuraciones_cca
   where res_secuencial_res = @w_secuencial_trn
   and   res_operacion_cca = @w_operacionca

   update ca_operacion
   set op_monto = @w_op_monto
   where op_banco = @i_banco   
   
   if @w_val_capitalizar = 0 and @w_saldo_antes <> @w_op_monto
   begin
     select  @w_diff  = 0
     select  @w_diff  = @w_saldo_antes - @w_op_monto
     PRINT 'reestcca.sp  REVISAR ESTA DIFERENCIA FINAL NO HAY CAPITALIZACION : ' +  CAST (@w_saldo_antes as varchar) + ' monto_op: '  + CAST (@w_op_monto as varchar)  + ' Diff : '  + CAST (@w_diff as varchar)
     select @w_error = 708190
     goto ERROR   
   end

   if @w_op_monto < @w_saldo_antes begin
      select @w_diff = 0
      select @w_diff = @w_saldo_antes - @w_op_monto
      PRINT 'reestcca.sp  REVISAR ESTA DIFERENCIA FINAL  MONTO DISMINUYE  ' +  CAST (@w_saldo_antes as varchar) + ' monto_despues: '  + CAST (@w_op_monto as varchar) + ' @w_diff: '  + CAST (@w_diff as varchar)
      select @w_error = 708190
      goto ERROR
    end
    
    select @w_saldo_ok = @w_saldo_antes  + @w_val_capitalizar

    if @w_saldo_ok <> @w_op_monto
    begin
      PRINT 'reestcca.sp  REVISAR ESTA DIFERENCIA CAPITALIZO DIFERENTE  ' +  CAST (@w_saldo_ok as varchar) + ' monto_despues: '  + CAST (@w_op_monto as varchar) + '- Dif: :' + cast(@w_saldo_ok-@w_op_monto as varchar)
      select @w_error = 708190
      goto ERROR  
    end

	update ca_datos_reestructuraciones_cca
	set res_saldo_cap_depues = @w_op_monto
	where res_secuencial_res = @w_secuencial_trn
	and res_operacion_cca = @w_operacionca
   
   --- CAMBIO DE ESTADO A NORMALIZADO 
   
   select 
   cc_cobranza   = oc_cobranza,
   cc_banco      = cj_banco,
   cc_estado_ant = convert(varchar(10), null),
   cc_estado     = cj_estado_cb,
   cc_codigo_ab  = cj_codigo_ab
   into  #cambios_cobranza
   from  cob_credito..cr_operacion_cobranza, ca_op_cobranza_jud
   where cj_banco    = oc_num_operacion
   and   cj_banco    = @i_banco 

   if @@rowcount > 0 begin
     
      update #cambios_cobranza set
      cc_estado_ant = co_estado
      from   cob_credito..cr_cobranza
      where  co_cobranza = cc_cobranza
   
      insert into cob_credito..cr_cambio_estados(
      ce_cobranza,    ce_secuencial,  ce_estado_ant,  
      ce_estado_act,  ce_funcionario, ce_fecha)
      select
      cc_cobranza,    isnull(max(ce_secuencial) + 1, 1), isnull(cc_estado_ant, 'NO'), 
      cc_estado,      'script',               (select convert(varchar,(select fp_fecha from cobis..ba_fecha_proceso),101))
      from  #cambios_cobranza left outer join cob_credito..cr_cambio_estados on cc_cobranza = ce_cobranza
      group  by cc_cobranza, cc_estado_ant, cc_estado
   
      update cob_credito..cr_cobranza set
      co_estado        = cc_estado,
      co_observa       = 'CAMBIO NORMALIZADO POR REESTRUCTURACION', 
      co_abogado       = cc_codigo_ab
      from  #cambios_cobranza
      where co_cobranza = cc_cobranza

   end
   
    ---Validar por que hay montos que estan menores que el monto antes de la resetrucuracion
   select @w_max_sec_rec = 0,
          @w_diff        = 0,
          @w_monto_hisrorico = 0
          
   select @w_max_sec_rec = max(tr_secuencial)
   from ca_transaccion
   where tr_operacion = @w_operacionca
   and tr_tran = 'RES'
   and tr_estado <> 'RV'
   and tr_secuencial > 0
   
   if @w_max_sec_rec > 0
   begin
      select @w_monto_hisrorico =  oph_monto
      from ca_operacion_his
      where oph_operacion = @w_operacionca
      and oph_secuencial = @w_max_sec_rec
      
      if @w_monto < @w_monto_hisrorico begin
         select @w_diff = @w_monto_hisrorico - @w_monto         
         select @w_error = 708190
         goto ERROR
      end

   end
   
   select @i_toperacion = tr_toperacion
   from cob_credito..cr_tramite
   where tr_numero_op = @w_operacionca
   and   tr_estado    in ( 'N', 'A' )
   and   tr_tipo      = 'E'
           
   update ca_operacion set
   op_numero_reest    = isnull(op_numero_reest,0) + 1,
   op_toperacion      = @i_toperacion,
   op_estado          = @w_est_vigente,
   --op_monto           = @w_op_monto,
   op_estado_cobranza = 'NO'
   where op_banco     = @i_banco 
   
   if @@error <> 0 begin
      select @w_error = 705007
      goto ERROR
   end
   
    ---ANALIZAR DATOS REGISTRADOS PAR ACONTABILIDAD
	select @w_div_vigente = di_dividendo
	from   ca_dividendo
	where  di_operacion   = @w_operacionca
	and    di_estado      = @w_est_vigente

	   
   update ca_amortizacion
   set am_estado = @w_est_vigente
   where am_operacion = @w_operacionca
   and am_dividendo   = @w_div_vigente
   
   update ca_amortizacion
   set am_estado = 0
   where am_operacion = @w_operacionca
   and am_dividendo   > @w_div_vigente

         
   
   if exists (select 1
              from   ca_rubro_op
              where  ro_operacion = @w_operacionca
              and    ro_concepto  = @w_parametro_fng)
   begin

      exec @w_error =  sp_calulo_fng_vigentes
      @i_operacionca = @w_operacionca ,
      @i_concepto    = @w_parametro_fng
            
      if @w_error <> 0 goto ERROR

   end  
	
	declare 
	   Cur_dato_Cont cursor
	   for 
	   	select  tp_dividendo,tp_concepto,tp_monto,co_categoria
		from ca_transaccion_prv ,ca_concepto
		where  tp_operacion  = @w_operacionca
		and tp_concepto = co_concepto
	    and tp_dividendo >= @w_min_div_reest
	    and co_categoria not in ('I','M','C','R')
	    and tp_estado <> 'RV'
	    and tp_secuencial_ref >= 0
	      
		order by tp_operacion,tp_dividendo
	   
	open Cur_dato_Cont
	
	fetch Cur_dato_Cont
	into  @w_di_dividendo,@w_concepto,@w_cuota ,@w_co_categoria
	    
	while @@fetch_status = 0
	begin

       if not exists (select 1 from ca_amortizacion
	                   where am_operacion = @w_operacionca
	                   and   am_dividendo = @w_di_dividendo
	                   and   am_concepto  = @w_concepto
	                   and   am_acumulado =   @w_cuota)  or  ( @w_co_categoria in ('I','M'))
   	    begin            
			insert into ca_transaccion_prv with (rowlock) (
			tp_fecha_mov,           tp_operacion,        tp_fecha_ref,
			tp_secuencial_ref,      tp_estado,           tp_dividendo,
			tp_concepto,            tp_codvalor,         tp_monto,
			tp_secuencia,           tp_comprobante,      tp_ofi_oper,
			tp_reestructuracion)
			select 
			@w_fecha_hoy     ,      tp_operacion,        tp_fecha_mov,
			-999,                  'ING',                tp_dividendo,
			tp_concepto,            tp_codvalor,         tp_monto * -1,
			tp_secuencia,           tp_comprobante,      tp_ofi_oper,
			tp_reestructuracion
			from ca_transaccion_prv
			where tp_operacion      = @w_operacionca
			and   tp_estado         = 'CON'
			and   tp_monto          = @w_cuota
			and   tp_dividendo      = @w_di_dividendo
			and   tp_concepto       = @w_concepto
			and   tp_secuencial_ref >= 0
			            
			update ca_transaccion_prv set 
			tp_estado = 'RV'
			where tp_operacion       = @w_operacionca
			and   tp_dividendo       = @w_di_dividendo
			and   tp_concepto        = @w_concepto
			and   tp_secuencial_ref   >= 0	
			and   tp_monto            = @w_cuota	
	    end
		  		 
	   fetch Cur_dato_Cont
	   into  @w_di_dividendo,@w_concepto,@w_cuota,@w_co_categoria  	       
	
	end  ---while
	
	close Cur_dato_Cont
	deallocate Cur_dato_Cont
   
	if @w_op_hija > 0 and @w_tiene_fng = 'S' begin
   
      update ca_op_reest_padre_hija
      set ph_sec_reest = @w_secuencial_trn
      where ph_op_padre = @w_operacionca
      and   ph_op_hija  = @w_op_hija
   
      select @w_banco_hija = op_banco
      from ca_operacion
      where op_operacion = @w_op_hija

      --ACTUALIZA CAMPOS CALIFICACION, REESTRUCTURADA Y NUMERO DE REESTRUCTURACIONES A PARTIR DE LA OPERACION PADRE
      update ca_operacion set
      op_numero_reest     = isnull(a.op_numero_reest,0),
      op_reestructuracion = a.op_reestructuracion,
      op_calificacion     = a.op_calificacion
      from (select op_numero_reest, op_reestructuracion, op_calificacion
            from ca_operacion
            where op_banco = @i_banco) a
      where op_banco     = @w_banco_hija
      
      print 'Informar al Cliente:  ' + @i_nombre + ' que se le ha generado la Operacion : ' + @w_banco_hija + '  Por Reestructuracion aplicada a la Oper: ' + @i_banco   
   end
   
   select @w_cuota_inicial = res_cuota_anterior
   from ca_datos_reestructuraciones_cca
   where res_secuencial_res = @w_secuencial_trn
   and   res_operacion_cca  = @w_operacionca

   select @w_op_cuota_tmp = op_cuota
   from ca_operacion
   where op_operacion = @w_operacionca

   ----LA VALIDACION DE LA CUOTA DE DEBE HACER SIEMPRE Y CUANDO EL TIPO DE PLAZO SEA EL MISMO
   ----YA QUENO SE PUEDE COMPARAR ANTES CON MESES Y DESPUES CON TRIMESTRES    
   if ((@w_cuota_inicial * @w_cuota_reest)  < (@w_op_cuota_tmp))
   begin  
      ----VALIDAR QUE LACUOTA INCIAL ESTE BIEN CALCULADA
      print 'Cuota anterior :' + cast(@w_cuota_inicial as varchar) +  ' - Porc. permitido: '  + cast(@w_cuota_reest as varchar) +   ' - Nueva Cuota:'  +  cast(@w_op_cuota_tmp as varchar) 
      select @w_error = 724511
      goto ERROR
   end   

   commit tran

end

if @i_paso in ('C') begin -- (C) Consulta tabla amortizacion 

   select 
   @w_operacionca = opt_operacion,
   @w_monto       = opt_monto
   from ca_operacion_tmp
   where opt_banco = @i_banco
   
   select  @w_monto
   
   --SOLO PARA LA PRIMERA TRANSMISION 
   if @i_dividendo = 0 begin
   
      --- RUBROS QUE PARTICIPAN EN LA TABLA 
      select rot_concepto, co_descripcion, rot_tipo_rubro,rot_porcentaje
      from ca_rubro_op_tmp, ca_concepto
      where rot_operacion = @w_operacionca
      and   rot_fpago    in ('P','A','M','T')
      and   rot_concepto = co_concepto
      order by rot_concepto

      select @w_filas_rubros = @@rowcount
      
      if @w_filas_rubros < 10 
         select @w_filas_rubros = @w_filas_rubros + 3

      select @w_bytes_env    = @w_filas_rubros * 90  --83  --BYTES ENVIADOS

      select @w_primer_des = min(dm_secuencial)
      from   ca_desembolso
      where  dm_operacion  = @w_operacionca

      select dtr_dividendo, sum(dtr_monto),'D' ---DESEMBOLSOS PARCIALES
      from   ca_det_trn, ca_transaccion, ca_rubro_op_tmp
      where  tr_banco      = @i_banco 
      and    tr_secuencial = dtr_secuencial
      and    tr_operacion  = dtr_operacion
      and    dtr_secuencial <> @w_primer_des
      and    rot_operacion = @w_operacionca
      and    rot_tipo_rubro= 'C'
      and    tr_tran    = 'DES'
      and    tr_estado    in ('ING','CON')
      and    rot_concepto  = dtr_concepto 
      group by dtr_dividendo
      union
      select dtr_dividendo, sum(dtr_monto),'R'       ---REESTRUCTURACION
      from ca_det_trn, ca_transaccion, ca_rubro_op_tmp
      where  tr_banco      = @i_banco 
      and   rot_operacion = @w_operacionca
      and   rot_concepto  = dtr_concepto 
      and   rot_tipo_rubro= 'C'
      and   tr_tran      = 'RES'
      and   tr_estado    in ('ING','CON')
      and   tr_secuencial = dtr_secuencial
      and   tr_operacion  = dtr_operacion
      group by dtr_dividendo

      select @w_filas_rubros = @@rowcount
      
      select @w_bytes_env    = @w_bytes_env + (@w_filas_rubros * 13)

      select dit_dias_cuota
      from ca_dividendo_tmp 
      where dit_operacion = @w_operacionca
      and   dit_dividendo > @i_dividendo 
      order by dit_dividendo

      select @w_filas = @@rowcount
            
      select @w_bytes_env  = @w_bytes_env + (@w_filas * 4) --1) 
   end

   if @i_opcion = 0 begin
 
      if @i_dividendo = 0 begin
         select @w_count = (@w_buffer - @w_bytes_env) / 38  
      end
      else select @w_count = @w_buffer / 38
      set rowcount @w_count

      --- FECHAS DE VENCIMIENTOS DE DIVIDENDOS Y ESTADOS
      select convert(varchar(10),dit_fecha_ven,@i_formato_fecha),   substring(es_descripcion,1,20),
             0,dit_prorroga
      from ca_dividendo_tmp, ca_estado
      where dit_operacion = @w_operacionca
      and   dit_dividendo > @i_dividendo 
      and   dit_estado    = es_codigo

      order by dit_dividendo

      select @w_filas = @@rowcount
      select @w_bytes_env    =  (@w_filas * 38)

      select @w_count
   end
   else begin
      select 
      @w_filas = 0,
      @w_count = 1,
      @w_bytes_env = 0
   end

   if @w_filas < @w_count begin
      declare @w_total_reg int
         
      select @w_total_reg = count(distinct convert(varchar, dit_dividendo) + rot_concepto)
      from  ca_rubro_op_tmp                          
               inner join ca_dividendo_tmp on
                          (dit_dividendo > @i_dividendo
                     or   (dit_dividendo = @i_dividendo
                     and  rot_concepto > @i_concepto)) 
                     and  rot_operacion = @w_operacionca
                     and  rot_fpago    in ('P','A','M','T')   ---XSA adiciona fpago='M'  28/May/99 
                     and  dit_operacion  = @w_operacionca
                           left outer join ca_amortizacion_tmp on
                                          rot_concepto  = amt_concepto
                                    and   dit_dividendo = amt_dividendo
                                    and   amt_operacion = @w_operacionca
      
      select @w_count = (@w_buffer - @w_bytes_env) / 21  -- Esta linea antes era 21, se cambio a 21 
                                                         -- Para corregir una consulta puntual  def.5043
      if @i_dividendo > 0 and @i_opcion = 0
         select @i_dividendo = 0
         
      set rowcount @w_count
      
      select dit_dividendo,rot_concepto,
      convert(float, sum( isnull(amt_cuota,0) + isnull(amt_gracia,0))) 
      from ca_rubro_op_tmp
           inner join ca_dividendo_tmp on           
                  (dit_dividendo > @i_dividendo
                  or    (dit_dividendo = @i_dividendo 
                  and rot_concepto > @i_concepto)) 
                  and   rot_operacion = @w_operacionca                  
                  and   rot_fpago in ('P','A','M','T')  
                  and   dit_operacion  = @w_operacionca                           
                        left outer join ca_amortizacion_tmp on
                              rot_concepto  = amt_concepto
                              and   dit_dividendo = amt_dividendo
                              and amt_operacion = @w_operacionca      
                                      group by dit_dividendo,rot_concepto
                                      order by dit_dividendo,rot_concepto
       
         if @w_total_reg = @w_count 
            select @w_count = @w_count + 1
     
      select @w_count 
   end
end

if @i_paso in ('T') begin -- (T) Borra Temporales 

   --- BORRAR TABLAS TEMPORALES 
   exec @w_error    = sp_borrar_tmp_int
   @s_user           = @s_user,
   @s_sesn           = @s_sesn,
   @s_term           = @s_term,
   @i_banco          = @i_banco
   
   if @w_error <> 0 goto ERROR
end

if @i_paso in ('R') begin -- (R) Consulta Datos de la Reestruturacion 
 
   EXEC @w_error = sp_validar_fecha
      @s_user                  = @s_user,
      @s_term                  = @s_term,
      @s_date                  = @s_date ,
      @s_ofi                   = @s_ofi,
      @i_operacionca           = @w_operacionca,
      @i_debug                 = 'N' 

      if @w_error <> 0 
      begin

         goto ERROR
      end


   select @w_max_tram_rees = 0
   select @w_max_tram_rees = isnull(max(tr_tramite),0)
   from cob_credito..cr_tramite
   where tr_numero_op_banco  =  @i_banco
   and   tr_tipo             =  'E' --REESTRUCTURACION
   and   tr_estado           =  'A' --APROBADO
   
   if @w_max_tram_rees > 0
   begin
   select @w_tr_sujcred = tr_sujcred
   from cob_credito..cr_tramite
   where tr_tramite = @w_max_tram_rees
   end
   ELSE
   begin
      select @w_error = 701187
      goto ERROR 
   end

   ---validacion de tramite on la fecha
   select @w_max_tram_rees = 0
   select @w_max_tram_rees = isnull(max(tr_tramite),0)
   from cob_credito..cr_tramite
   where tr_numero_op_banco  =  @i_banco
   and   tr_tipo             =  'E' --REESTRUCTURACION
   and   tr_estado           =  'A' --APROBADO
   and  (  
        (datediff(dd,tr_fecha_apr,@w_fecha_ult_proceso) >= 0)  or (@w_tr_sujcred = @w_parametro_VHV)
        )
   
   if exists (select 1 from cob_credito..cr_tramite a, ca_transaccion b
              where a.tr_tramite         = @w_max_tram_rees
              and   b.tr_banco           = @i_banco
              and   b.tr_tran            = 'RES'
              and   b.tr_estado         <> 'RV'
              and   b.tr_secuencial       >= 0 ---18722              
              and   a.tr_numero_op_banco = b.tr_banco
              and   datediff(dd,tr_fecha_apr,tr_fecha_ref) > 0  
              
             )
       or @w_max_tram_rees = 0
   begin
       print 'reestcca.sp (2)'
      select @w_error = 701187
      goto ERROR 
   end
   else begin
      select             
      tr_plazo,  
      'N',  
      tr_tasa_reest,  
      tr_tipo_plazo,  
      tr_fecha_fija,  
      tr_dia_pago,
      tr_tipo_cuota,
      op_nombre     
      from   cob_credito..cr_tramite, ca_operacion
      where  tr_tipo            = 'E' --REESTRUCTURACION
      and    tr_estado          = 'A' --APROBADO
      and    tr_numero_op_banco = @i_banco
      and    op_banco = @i_banco
      and    tr_tramite = @w_max_tram_rees
   end
end


return 0

ERROR:

   if @@trancount > 0 rollback tran

    if @i_batch = 'N' ---CUando es batch no debe ejecutarse este es solo para reporte
	begin
	   exec cobis..sp_cerror
	   @t_from  = @w_sp_name,
	   @i_num   = @w_error
	   return @w_error
   end

go


