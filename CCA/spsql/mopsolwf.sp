/********************************************************************/
/*   NOMBRE LOGICO:      sp_modificar_oper_sol_wf                   */
/*   NOMBRE FISICO:      mopsolwf.sp                                */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Raul Altamirano Mendez                     */
/*   FECHA DE ESCRITURA: 12-Ene-2017                                */
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
/*                     PROPOSITO                                    */
/*   Sp de modificacion de datos de solicitudes de workflow         */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR         RAZON                         */
/*   12-Ene-2017    Raul Altamirano  Emision Inicial - Version MX   */
/*   26-Sep-2017    Ma. Jose Taco    Borrar y Crear integrantes en  */
/*                                   actualizacion de grupos        */
/*   18-Oct-2019    A. Miramon       Ajuste en calculo de CAT       */
/*   20-Jul-2021    C Veintemilla    Setea tipo dividendo cuando    */
/*                                   es nulo                        */
/*   03-Ago-2021    P Mora           ORI-S473510-GFI                */
/*   19-Oct-2021    William Lopez    ORI-S544332-GFI                */
/*   26-Nov-2021    William Lopez    ORI-S542854-GFI                */
/*   24-Feb-2021    Kevin Rodríguez  Se comenta calculo CAT (Cálculo*/
/*                                   ya se hace en sp_operacion_def)*/
/*   01-Mar-2023    Dilan Morales    Se reasigna el valor de        */
/*                                   @i_cliente con codigo cliente  */
/*   01-Ago-2023    William Lopez    CCA-B872876-ENL                */
/*   03/Oct-2023    Kevin Rodiguez   R216451 Se elimina asignación  */
/*                                   de días año en base a calculo  */
/*   03-Oct-2023    Esteban Báez     Mejora control oficiales       */
/*                                   S911708-R216187                */
/*  18-Oct-2023     K. Rodiguez      R217473 Recalc. valor rubros Q */
/********************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_modificar_oper_sol_wf')
    drop proc sp_modificar_oper_sol_wf
go

create proc sp_modificar_oper_sol_wf(
   @s_srv                    varchar(30),
   @s_lsrv                   varchar(30),
   @s_ssn                    int,
   @s_user                   login,
   @s_term                   varchar(30),
   @s_date                   datetime,
   @s_sesn                   int,
   @s_ofi                    smallint,
   @t_debug                  char(1)      = 'N',
   @t_file                   varchar(10)  = null,    
   ---------------------------------------
   @t_trn                    int          = null,
   ---------------------------------------
   @i_operacion              varchar(1)   = null,   --*
   @i_calcular_tabla         varchar(1)   = 'N',
   @i_tabla_nueva            varchar(1)   = 'S',
   @i_operacionca            int          = null,
   @i_banco                  cuenta       = null,
   @i_tipo                   varchar(1)   = 'N',
   @i_anterior               cuenta       = null,
   @i_migrada                cuenta       = null,
   @i_tramite                int          = null,
   @i_cliente                int          = 0,
   @i_nombre                 descripcion  = null,
   --@i_codeudor             int          = 0,
   @i_sector                 catalogo     = null,
   @i_toperacion             catalogo     = null,
   @i_oficina                smallint     = null,
   @i_moneda                 tinyint      = null,
   @i_comentario             varchar(255) = null,
   @i_oficial                smallint     = null,
   @i_fecha_ini              datetime     = null,
   @i_fecha_fin              datetime     = null,    --*
   @i_fecha_ult_proceso      datetime     = null,    --*
   @i_fecha_liq              datetime     = null,    --*
   @i_fecha_reajuste         datetime     = null,    --*
   @i_monto                  money        = null,
   @i_monto_aprobado         money        = null,
   @i_destino                catalogo     = null,
   @i_lin_credito            cuenta       = null,
   @i_ciudad                 int          = null,
   @i_estado                 tinyint      = null,
   @i_periodo_reajuste       smallint     = 0,
   @i_reajuste_especial      varchar(1)   = 'N',     --*
   @i_forma_pago             catalogo     = null,
   @i_cuenta                 cuenta       = null,
   @i_dias_anio              smallint     = null,    --*
   @i_tipo_amortizacion      varchar(10)  = null,    --*
   @i_cuota_completa         varchar(1)   = null,    --*
   @i_tipo_cobro             varchar(1)   = null,    --*
   @i_tipo_reduccion         varchar(1)   = null,    --*
   @i_aceptar_anticipos      varchar(1)   = null,    --*
   @i_precancelacion         varchar(1)   = null,    --*
   @i_tipo_aplicacion        varchar(1)   = null,    --*
   @i_tplazo                 catalogo     = null,    --*
   @i_plazo                  int          = null,    --*
   @i_tdividendo             catalogo     = null,    --*
   @i_periodo_cap            int          = null,    --*
   @i_periodo_int            int          = null,    --*
   @i_dist_gracia            varchar(1)   = null,    --*
   @i_gracia_cap             int          = null,    --*
   @i_gracia_int             int          = null,    --*
   @i_dia_fijo               int          = null,    --*
   @i_cuota                  money        = null,    --*
   @i_evitar_feriados        varchar(1)   = null,    --*
   @i_num_renovacion         int          = 0,       --*  --PQU este parámetro tiene el día de pago en originacion
   @i_renovacion             varchar(1)   = null,    --*
   @i_mes_gracia             tinyint      = null,    --*
   @i_upd_clientes           varchar(1)   = 'U',     --*
   @i_dias_gracia            smallint     = null,    --*
   @i_reajustable            varchar(1)   = null,    --*
   @i_es_interno             varchar(1)   = 'N',     --*
   @i_formato_fecha          int          = 101,
   @i_no_banco               varchar(1)   = 'S',
   @i_grupal                 char(1)      = null,
   @i_banca                  catalogo     = null,
   @i_en_linea               varchar(1)   = 'S',
   @i_externo                varchar(1)   = 'S',
   @i_desde_web              varchar(1)   = 'S',
   @i_salida                 varchar(1)   = 'N',
   @i_promocion              char(1)      = null,         --LPO Santander
   @i_acepta_ren             char(1)      = null,         --LPO Santander
   @i_no_acepta              char(1000)   = null,         --LPO Santander
   @i_emprendimiento         char(1)      = null,         --LPO Santander
   @i_garantia               float        = null,         --LPO Santander
   @i_alianza                int          = null,         --Santander -- tr_alianza  
   @i_ciudad_destino         int          = null,         --Santander
   @i_experiencia_cli        char(1)      = null,         --Santander
   @i_monto_max_tr           money        = null,         --Santander
   @i_recalc_rubs_enl        char(1)      = 'S',          --KDR Recalcular Rubros Q (versión Enlace)
   ---------------------------------------
   @o_banco                  cuenta       = null out,
   @o_operacion              int          = null out,
   @o_tramite                int          = null out,
   @o_plazo                  smallint     = null out,
   @o_tplazo                 catalogo     = null out,
   @o_cuota                  money        = null out,
   @o_msg                    varchar(100) = null out,
   @o_tasa_grp               varchar(255) = null out
)
as
declare
   @w_sp_name                varchar(64),
   @w_return                 int,
   @w_error                  int,   
   @w_fecha_proceso          datetime,
   @w_banco                  cuenta,
   @w_ced_ruc                varchar(15),
   @w_ced_ruc_codeudor       varchar(15),
   @w_nombre                 varchar(60),
   @w_prod_cobis             smallint,   
   @w_tramite                int,
   @w_tplazo                 catalogo,
   @w_plazo                  smallint,
   @w_commit                 char(1),
   @w_dias_plazo             smallint,
   @w_moneda                 smallint,
   @w_dias_dividendo         int,
   @w_toperacion             catalogo,
   @w_filas_rec              int,
   @w_op_estado              smallint,
   @w_monto_min              money,
   @w_monto_aprobado         money,
   @w_monto_aprobado_tmp     money,
   @w_valida_bloqueos        char(1),
   @w_doble_alicuota         char(1),
   @w_est_novigente          tinyint,
   @w_est_credito            tinyint,
   @w_clase_bloqueo          char(1),
   @w_cliente                int,
   @w_dias_gracia            int,
   @w_monto                  money,
   @w_fecha_reajuste         datetime,
   @w_monto_tmp              money,
   @w_monto_max              money,
   @w_fecha_fin              datetime,
   @w_fecha_f                datetime,
   @w_fecha_ini              datetime,
   @w_estado                 char(1),
   @w_razon                  catalogo     = null,
   @w_txt_razon              varchar(255) = null,
   @w_tr_fecha_ini           datetime     = null,
   @w_tr_num_dias            smallint     = 0,
   @w_tr_monto               money        = 0,
   @w_tr_plazo               smallint     = null,
   @w_tr_monto_soli          money        = null,
   @w_miembros               int,--SRO
   @w_monto_antes_aux        money,
   @w_promocion              char(1)      = null,
   @w_acepta_ren             char(1)      = null,
   @w_no_acepta              char(1000)   = null,
   @w_emprendimiento         char(1)      = null,
   @w_garantia               float        = null,
   @w_tr_tplazo              catalogo     = null,
   @w_alianza                int          = null,
   @i_w_alianza              int          = null,
   @i_w_ciudad_destino       int          = null,  --Santander
   @i_w_experiencia_cli      char(1)      = null,  --Santander
   @i_w_monto_max_tr         money        = null,  --Santander
   @w_ofi_def_app_movil      smallint,
   @w_grupo                  int          = null,
   @w_oficina_aux            int          = null,
   @w_tg_prestamo            varchar(20),
   @w_tg_operacion           int,
   @w_nueva_op_aux           int,
   @w_tramite_hijo           int,
   @w_estado_cl              varchar(2),
   @w_val_ahorro_vol         float ,
   @w_base_calculo           char(1),              --LGU
   @w_paso_actual            int         ,
   @w_codigo_actividad       int         ,
   @w_desc_actividad         varchar(255),
   @w_procesa_gentabla       char(1),
   @w_fecha_liq              datetime,
   @w_admin_individual       char(1),   
   @w_dia_fijo               tinyint,              --PQU integracion
   @w_suma_monto_solicitado  money,                --PQU integracion
   @w_destino_tmp            varchar(10),
   @w_destino                varchar(10),
   @w_ref_grupal             int,
   --EBAEZ R216187 Validar que el oficial sea el mismo que del grupo
   @w_controlar_oficial        char(10),
   @w_oficial_grupo            int,
   @w_recalculo_rubs           char(1)

-- PMO Destino de operación por defecto.
   select @w_destino_tmp = pa_char from cobis..cl_parametro
   where  pa_nemonico    = 'DEST'                    
   select @w_destino = isnull(@i_destino,@w_destino_tmp)

-- AMG 2019/10/18 - Calculo de CAT
declare 
   @w_cat float
  
--PRINT 'CARGAR VALORES INICIALES'
select @w_sp_name     = 'sp_modificar_oper_sol_wf',
       @w_commit      = 'N',
       @w_oficina_aux = @i_oficina,
       @w_procesa_gentabla = 'N'

--CVA setea tipo de dividendo cuando es nulo
if @i_tdividendo is null
    select @i_tdividendo = @i_tplazo
    
--PRINT 'CONSULTAR FECHA DE PROCESO'
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

-- PRINT 'NUMERO DE OFICINA POR DEFECTO DEL APP MOVIL'
select @w_ofi_def_app_movil = pa_smallint from cobis..cl_parametro 
where  pa_nemonico = 'OFIAPP' 
and    pa_producto = 'CRE'

----EBAEZ R216187-Control Oficiales
select @w_controlar_oficial = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'CTROFG'

----EBAEZ R216187-Control Oficiales   
/*VALIDAR QUE EL GRUPO Y LA SOLICITUD TENGAN EL MISMO OFICIAL*/
if @w_controlar_oficial = 'S'
begin
   select @w_oficial_grupo = gr_oficial
     from cobis..cl_grupo
    where gr_grupo = @i_cliente
   if @w_oficial_grupo <> @i_oficial
   begin
      select @w_error = 725306
      goto ERROR_PROCESO
   end	  
end

if(@i_oficina = @w_ofi_def_app_movil)
begin
    select @i_oficina = fu_oficina  
    from   cobis..cl_funcionario, cobis..cc_oficial
    where  oc_oficial     = @i_oficial
    and    oc_funcionario = fu_funcionario
end

if @i_es_interno = 'S' select @i_salida = 'N'

exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   out

   select @w_banco = op_banco from ca_operacion 
   where op_operacion = @i_operacionca

if @i_operacionca is null or @i_operacionca = 0
begin
   select @i_operacionca    = opt_operacion,
          @w_toperacion     = opt_toperacion,
          @w_moneda         = opt_moneda,
          @w_cliente        = opt_cliente,
          @w_op_estado      = opt_estado,
          @w_monto          = opt_monto,
          @w_monto_aprobado = opt_monto_aprobado,
          @w_tramite        = opt_tramite,
          @w_banco          = opt_banco,
          @w_base_calculo   = opt_base_calculo, --LGU
          @w_plazo          = opt_plazo,        --PQU
          @w_tplazo         = opt_tplazo,       --PQU
          @w_dia_fijo       = opt_dia_fijo,     --PQU 
          @w_ref_grupal     = opt_ref_grupal    --JCM
   from   cob_cartera..ca_operacion_tmp
   where  opt_banco = @i_banco
end
else 
begin
   select @i_banco          = opt_banco,
          @w_toperacion     = opt_toperacion,
          @w_moneda         = opt_moneda,
          @w_cliente        = opt_cliente,
          @w_op_estado      = opt_estado,
          @w_monto          = opt_monto,
          @w_monto_aprobado = opt_monto_aprobado,
          @w_tramite        = opt_tramite,
          @w_banco          = opt_banco,
          @w_base_calculo   = opt_base_calculo, --LGU
          @w_plazo          = opt_plazo,        --PQU
          @w_tplazo         = opt_tplazo,       --PQU
          @w_dia_fijo       = opt_dia_fijo,     --PQU 
          @w_ref_grupal     = opt_ref_grupal    --JCM
   from   cob_cartera..ca_operacion_tmp
   where  opt_operacion = @i_operacionca
end

--select @w_filas_rec = @@rowcount

if @@rowcount = 0
begin
   select @w_error = 708153
   goto ERROR_PROCESO
end

select @i_tramite = isnull(@i_tramite, @w_tramite)

select @w_monto_min        = dt_monto_min,
       @w_monto_max        = dt_monto_max,
       @w_admin_individual = dt_admin_individual
from   cob_cartera..ca_default_toperacion
where  dt_toperacion       = @w_toperacion
and    dt_moneda           = @w_moneda

--PQU integracion
if @i_monto = 0 
    select @i_monto = @w_monto_min
    
if @i_monto_aprobado = 0 
    select @i_monto_aprobado = @w_monto_min
--fin PQU integracion  
if isnull(@i_monto_aprobado, 0) > 0 
begin
   if @w_ref_grupal is not null
   begin
	   if isnull(@w_monto_min,0) > 0 or isnull(@w_monto_max,0) > 0
	   begin
	      if @i_monto_aprobado < @w_monto_min or @i_monto_aprobado > @w_monto_max 
	      begin
	         select @w_error = 724609
	         goto ERROR_PROCESO
	      end
	   end
   end
end

--PARA SIMULACION DE OPERACIONES SE DEBE ENVIAR EL CODIGO -666
if @w_cliente = -666 select @i_cliente = @w_cliente

if @@trancount = 0
begin
   begin tran
   select @w_commit = 'S'
end   

-- MODIFICAR LA OPERACION TEMPORAL

--print 'antes de cob_cartera..sp_operacion_tmp'

--desde el app llega 0 en lugar de null
if @i_ciudad=0
SET @i_ciudad=null

/**REQUERIMIENTO 98119 para que cuando recalcula la tabla al Guardar en la etapa de Eliminar Integrante, tome la fecha de dispersión que es parte del cambio **/
select @w_fecha_ini  = opt_fecha_ini
from   cob_cartera..ca_operacion_tmp with (nolock)
where  opt_operacion = @i_operacionca

select @w_fecha_liq = op_fecha_liq
from cob_cartera..ca_operacion
where op_banco = @i_banco

if @w_fecha_liq is not null and @w_fecha_liq > @i_fecha_ini
select @i_fecha_ini = @w_fecha_liq

select @i_dia_fijo = isnull(@i_dia_fijo, @i_num_renovacion) --PQU integracion                                            

--DMO SE REASIGNA CON EL CODIGO DEL PRESIDENTE
if @i_grupal = 'S'
begin
   select @w_grupo = @i_cliente
   
   select @i_cliente = cg_ente
   from cobis..cl_cliente_grupo
   where cg_grupo  = @w_grupo 
     and cg_rol    = 'P'
     and cg_estado = 'V'
	 
   --INI WLO_B872876
   select @i_nombre  = en_nomlar
   from   cobis..cl_ente
   where  en_ente = @i_cliente

   if @i_nombre is null
   begin
      select @w_error = 710200  --No existe cliente solicitado
      goto ERROR_PROCESO
   end
   --FIN WLO_B872876
end 

-- Proceso de recalculo de valor rubros calculados(versión Enlace) Parte 1: Respaldo e eliminación
if @i_recalc_rubs_enl = 'S'
begin   
   exec @w_return = sp_recalcula_rubros_enl
   @s_user              = @s_user,
   @s_date              = @s_date,
   @s_term              = @s_term,
   @s_ofi               = @s_ofi,
   @i_operacion         = 'D',
   @i_banco             = @i_banco,
   @i_tdividendo        = @i_tdividendo,
   @i_periodo_int       = @i_periodo_int,
   @i_recalc_rubs_enl   = @i_recalc_rubs_enl,
   @o_recalculo_rubs    = @w_recalculo_rubs out -- Bandera para volver a ingresar los rubros eliminados
   
   if @w_return <> 0
   begin 
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
end
   

exec @w_return = sp_operacion_tmp
@s_user                 = @s_user,
@s_sesn                 = @s_sesn,
@s_date                 = @s_date,
@i_operacion            = 'U',
@i_operacionca          = @i_operacionca ,
@i_banco                = @i_banco ,
@i_anterior             = @i_anterior,
@i_migrada              = @i_migrada,
@i_tramite              = @i_tramite,
@i_cliente              = @i_cliente,
@i_nombre               = @i_nombre,
@i_sector               = @i_sector,
@i_toperacion           = @i_toperacion,
@i_oficina              = @i_oficina,
@i_moneda               = @i_moneda, 
@i_comentario           = @i_comentario,
@i_oficial              = @i_oficial,
@i_fecha_ini            = @i_fecha_ini,
@i_fecha_fin            = @i_fecha_fin,
@i_fecha_ult_proceso    = @i_fecha_ult_proceso,
@i_fecha_liq            = @i_fecha_liq,
@i_fecha_reajuste       = @i_fecha_reajuste, 
@i_monto                = @i_monto, 
@i_monto_aprobado       = @i_monto_aprobado,
@i_destino              = @w_destino,
@i_lin_credito          = @i_lin_credito,
@i_ciudad               = @i_ciudad,
@i_estado               = @i_estado,
@i_periodo_reajuste     = @i_periodo_reajuste,
@i_reajuste_especial    = @i_reajuste_especial,
@i_tipo                 = @i_tipo, --(Hipot/Redes/Normal)
@i_forma_pago           = @i_forma_pago,
@i_cuenta               = @i_cuenta,
@i_dias_anio            = @i_dias_anio, 
@i_tipo_amortizacion    = @i_tipo_amortizacion,
@i_cuota_completa       = @i_cuota_completa,
@i_tipo_cobro           = @i_tipo_cobro,
@i_tipo_reduccion       = @i_tipo_reduccion,
@i_aceptar_anticipos    = @i_aceptar_anticipos,
@i_precancelacion       = @i_precancelacion,
@i_tipo_aplicacion      = @i_tipo_aplicacion,
@i_tplazo               = @i_tplazo,
@i_plazo                = @i_plazo,
@i_tdividendo           = @i_tdividendo,
@i_periodo_cap          = @i_periodo_cap,
@i_periodo_int          = @i_periodo_int,
@i_dist_gracia          = @i_dist_gracia,
@i_gracia_cap           = @i_gracia_cap,
@i_gracia_int           = @i_gracia_int,
@i_dia_fijo             = @i_dia_fijo,
@i_cuota                = @i_cuota,
@i_evitar_feriados      = @i_evitar_feriados,
@i_renovacion           = @i_renovacion,
@i_mes_gracia           = @i_mes_gracia,
@i_reajustable          = @i_reajustable,
@i_dias_clausula        = null,
@i_base_calculo         = @w_base_calculo,      --LGU    'E',
@i_recalcular           = null,
@i_tipo_empresa         = 1, 
@i_tipo_crecimiento     = 'A',    --AUTOMATICA, NO DIGITAN VALORES DE CAPITAL FIJO, O CUOTA FIJA
@i_banca                = @i_banca,
@i_grupal               = @i_grupal,
@i_promocion            = @i_promocion,         --LPO Santander
@i_acepta_ren           = @i_acepta_ren,        --LPO Santander
--PQU Fincca @i_no_acepta            = @i_no_acepta,     --LPO Santander
@i_origen_fondos        = @i_no_acepta,         --PQU Finca este parámetro tiene el origen de fondos
@i_emprendimiento       = @i_emprendimiento,    --LPO Santander
@i_admin_individual     = @w_admin_individual   --LPO Santander

if @w_return <> 0
begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end

-- DIAS DE GRACIA CUANDO LLAMO DESDE RUBROS
select @w_dias_gracia =dit_gracia
from cob_cartera..ca_dividendo_tmp
where dit_operacion = @i_operacionca 
and dit_dividendo = 1

if @i_dias_gracia is null
   select @i_dias_gracia = isnull(@w_dias_gracia,0)

select --@i_seg_cre = isnull(@i_seg_cre,@w_seg_cre),
       --@i_seg_cre = isnull(@i_seg_cre,@w_seg_cre),
       @i_monto   = isnull(@i_monto, @w_monto),
       @i_monto_aprobado = isnull(@i_monto_aprobado, @w_monto_aprobado)

select @w_promocion = isnull(tr_promocion,@i_promocion)
from cob_credito..cr_tramite
where tr_tramite = @i_tramite   

print 'modifica operacion:'+ @w_promocion  + 'parametro: ' + @i_promocion 

if @i_calcular_tabla = 'N' and @w_op_estado in (@w_est_novigente, @w_est_credito)
begin
    exec cob_credito..sp_busca_etapa_tramite
         @i_tramite          = @i_tramite              ,
         @o_paso_actual      = @w_paso_actual       out,
         @o_codigo_actividad = @w_codigo_actividad  out,
         @o_desc_actividad   = @w_desc_actividad    out
    
    if exists(select 1 
              from cobis..cl_tabla t, cobis..cl_catalogo c
              where t.tabla  = 'cr_etapa_genera_tabla'
              and   t.codigo = c.tabla
              and   c.codigo = convert(varchar(8),@w_codigo_actividad))
           select @w_procesa_gentabla = 'S'
   
   if (@i_monto <> 0 and @i_monto <> @w_monto) or (@i_monto_aprobado <> 0 and @i_monto_aprobado <> @w_monto_aprobado) or @w_procesa_gentabla = 'S'  --or 
    begin
       select @i_calcular_tabla = 'S'
    end
    if (@i_plazo <> @w_plazo) or (@i_tplazo <> @w_tplazo) or  (@i_dia_fijo <> @w_dia_fijo) --PQU
        select @i_calcular_tabla = 'S'  --PQU
end

if @i_calcular_tabla = 'S'
begin
   print 'antes de ejecutar: cob_cartera..sp_gentabla'

   exec @w_return = cob_cartera..sp_gentabla
   @i_operacionca = @i_operacionca,
   @i_tabla_nueva = @i_tabla_nueva,
   @i_dias_gracia = @i_dias_gracia,
   @i_promocion   = @w_promocion  ,
   @o_fecha_fin   = @w_fecha_fin    out,
   @o_cuota       = @o_cuota        out,
   @o_plazo       = @o_plazo        out,
   @o_tplazo      = @o_tplazo       out

   if @w_return <> 0
   begin
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
   
   -- ACTUALIZACION DE LA OPERACION 
   if isnull(@i_periodo_reajuste,0) != 0
   begin
      select @w_fecha_reajuste = min(re_fecha)
      from   cob_cartera..ca_reajuste
      where  re_operacion = @i_operacionca
      and    re_fecha    >= @i_fecha_ult_proceso

      select @w_fecha_reajuste = isnull(@i_fecha_reajuste,@w_fecha_reajuste)
   end 
   else 
      select @w_fecha_reajuste = '01/01/1900'
      
   --CONTROL DEL MONTO SEA MENOR O IGUAL AL MONTO APROBADO
   select 
   @w_monto_tmp          = opt_monto,
   @w_monto_aprobado_tmp = opt_monto_aprobado,
   @w_fecha_ini          = opt_fecha_ini
   from  cob_cartera..ca_operacion_tmp
   where opt_banco = @i_banco

   if @w_monto_tmp > @w_monto_aprobado_tmp 
   begin
      print 'inconsistencia en monto aprobado'
     -- select @w_error = 710024
      --goto ERROR_PROCESO
   end   

   update cob_cartera..ca_operacion_tmp
   set opt_fecha_fin   = @w_fecha_fin,
   opt_fecha_reajuste  = @w_fecha_reajuste,
   opt_plazo           = @o_plazo,
   opt_tplazo          = @o_tplazo
   where opt_operacion = @i_operacionca

   if @@error != 0 
   begin
      select @w_error = 710002
      goto ERROR_PROCESO
   end
   
   --SE DISPLAYA DATOS AL FRONTend DESDE LA PANTALLA FGENAMORTIZACION
   if @i_salida = 'S'
   begin
      select @w_fecha_f  = convert(varchar(10),@w_fecha_fin,@i_formato_fecha)

      select 
      @w_fecha_f,     --1
      @o_cuota,
      @o_plazo,       --3
      @o_tplazo,
      td_descripcion  --5
      from  cob_cartera..ca_tdividendo
      where td_tdividendo = @o_tplazo  
   end
end

select @w_fecha_ini  = opt_fecha_ini
from   cob_cartera..ca_operacion_tmp
where  opt_operacion = @i_operacionca

select @i_fecha_ini = isnull(@i_fecha_ini, @w_fecha_ini)

-- Proceso de recalculo de valor rubros calculados(versión Enlace) Parte 2: Registro
if @i_recalc_rubs_enl = 'S' and @w_recalculo_rubs = 'S'
begin
   
   exec @w_return = sp_recalcula_rubros_enl
   @s_user              = @s_user,
   @s_date              = @s_date,
   @s_term              = @s_term,
   @s_ofi               = @s_ofi,
   @i_operacion         = 'I',
   @i_banco             = @i_banco,
   @i_tdividendo        = @i_tdividendo,
   @i_periodo_int       = @i_periodo_int,
   @i_recalc_rubs_enl   = @i_recalc_rubs_enl
   
   if @w_return <> 0
   begin
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
  
end

--MODIFICAR TRAMITE DEBIDO AL RECHAZO

if isnull(@i_tramite, 0) > 0 and (@w_op_estado in (@w_est_novigente, @w_est_credito))
begin
--print 'antes de cob_credito..sp_up_tramite'
   select 
   @w_estado             = tr_estado,
   @w_razon              = tr_razon,
   @w_txt_razon          = tr_txt_razon,
   @w_tr_fecha_ini       = tr_fecha_inicio,
   @w_tr_num_dias        = tr_num_dias,   
   @w_tr_monto           = tr_monto,
   @w_tr_monto_soli      = tr_monto_solicitado,
   @w_tr_plazo           = tr_plazo,
   @w_promocion          = tr_promocion,
   @w_acepta_ren         = tr_acepta_ren,
   @w_no_acepta          = tr_no_acepta,
   @w_emprendimiento     = tr_emprendimiento,
   @w_garantia           = isnull(tr_porc_garantia,0),
   @w_tr_tplazo          = tr_tipo_plazo,
   @w_alianza            = isnull(tr_alianza,0),
   @i_w_ciudad_destino   = tr_ciudad_destino,
   @i_w_experiencia_cli  = tr_experiencia,
   @i_w_monto_max_tr     = tr_monto_max
   from cob_credito..cr_tramite
   where tr_tramite = @i_tramite

   if @@rowcount = 0
   begin
      select @w_error = 2105002
      goto ERROR_PROCESO
   end
   
   --Almacena el valor del monto antes de actualizar para comparar
   --con el valor de ingreso y asi realizar la divisi=n para grupos
   select  @w_monto_antes_aux = tr_monto
   from    cob_credito..cr_tramite 
   where   tr_tramite = @i_tramite
   select @w_suma_monto_solicitado = isnull(sum(tg_monto_aprobado),0) --PQU integracion, este campo tiene lo solicitado
   from   cob_credito..cr_tramite_grupal
   where  tg_tramite = @i_tramite
   and    tg_participa_ciclo = 'S' --WLO_S544332

   exec @w_return        = cob_credito..sp_up_tramite_cca
   @s_date               = @s_date,
   @s_lsrv               = @s_lsrv,
   @s_ofi                = @s_ofi,
   @s_sesn               = @s_sesn,
   @s_srv                = @s_srv,
   @s_ssn                = @s_ssn,
   @s_term               = @s_term,
   @s_user               = @s_user,
   @t_trn                = @t_trn,
   @i_operacion          = 'U',
   @i_tramite            = @i_tramite,
   @i_fecha_inicio       = @i_fecha_ini,
   @i_num_dias           = @i_plazo,
   @i_monto              = @i_monto_aprobado,
   @i_grupal             = @i_grupal,
   @i_monto_solicitado   = @w_suma_monto_solicitado, --PQU cambio para que grabe el solicitado
   @i_plazo              = @i_plazo,
   @i_tplazo             = @i_tplazo,                -- Santander
   @i_estado             = @i_estado,
   @i_w_estado           = @w_estado,
   @i_w_razon            = @w_razon,
   @i_w_txt_razon        = @w_txt_razon,
   @i_w_numero_op_banco  = @i_banco,
   @i_w_fecha_inicio     = @w_tr_fecha_ini,
   @i_w_num_dias         = @w_tr_num_dias,
   @i_w_monto            = @w_tr_monto,
   @i_w_plazo            = @w_tr_plazo,
   @i_w_monto_solicitado = @w_tr_monto_soli,
   @i_promocion          = @i_promocion,             --LPO Santander
   @i_acepta_ren         = @i_acepta_ren,            --LPO Santander
   --PQU Finca integracion @i_no_acepta          = @i_no_acepta,      --LPO Santander
   @i_emprendimiento     = @i_emprendimiento,        --LPO Santander
   @i_garantia           = @i_garantia,              --LPO Santander
   @i_w_promocion        = @w_promocion,             --PARA REGISTRAR CAMBIOS
   @i_w_acepta_ren       = @w_acepta_ren,            --PARA REGISTRAR CAMBIOS
   @i_w_no_acepta        = @w_no_acepta,             --PARA REGISTRAR CAMBIOS
   @i_w_emprendimiento   = @w_emprendimiento,        --PARA REGISTRAR CAMBIOS
   @i_w_garantia         = @w_garantia,              --PARA REGISTRAR CAMBIOS   
   @i_w_tplazo           = @w_tr_tplazo,
   @i_alianza            = @i_alianza,
   @i_w_alianza          = @w_alianza,
   @i_ciudad_destino     = @i_ciudad_destino,        --Santander
   @i_experiencia_cli    = @i_experiencia_cli,       --Santander
   @i_monto_max_tr       = @i_monto_max_tr,          --Santander
   @i_w_ciudad_destino   = @i_w_ciudad_destino,
   @i_w_experiencia_cli  = @i_w_experiencia_cli,
   @i_w_monto_max_tr     = @i_w_monto_max_tr,
   @i_origen_fondos      = @i_no_acepta,             --PQU integracion Finca, esto porque necesitamos enviar el origen de fondos y se está usando el mismo campo en el servicio de ingreso y actualización
   @i_destino            = @i_destino,               --PQU integracion Finca
   @i_oficial            = @i_oficial                --WLO_S542854
--   @o_tasa_grp           = @o_tasa_grp out         --PQU no es un parámetro del sp

   if @w_return <> 0 
   begin
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
end

--TRASLADO DE INFORMACION DESDE LAS TMP A DEFINITIVAS
print '---antes de sp_operacion_def'
exec @w_return = sp_operacion_def
@s_date  = @s_date,
@s_sesn  = @s_sesn,
@s_user  = @s_user,
@s_ofi   = @s_ofi,
@i_banco = @w_banco

if @w_return <> 0
begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end

print '---despues de sp_operacion_def'

   /*KDR 24/02/2021 Se comenta llamado a programa de cálculo del CAT.
   -- AMG 2019/10/18 - Calculo de CAT
   exec @w_return = sp_calculo_cat @i_banco = @w_banco, @o_cat = @w_cat out
   --print 'cat: ' + convert(VARCHAR, @w_cat)

   if @w_return != 0
   begin 
    print ' return tir : ' + convert(VARCHAR,@w_return)
      select @w_error = @w_return
      goto ERROR_PROCESO
   end

   update cob_cartera..ca_operacion SET 
        op_valor_cat = @w_cat
   where op_operacion = @i_operacionca

   if @@error <> 0 begin
      select @w_error = 2103001
      goto ERROR_PROCESO
   end
   */ -- FIN KDR

-- LGU-FIN 2017-11-11

if(@w_oficina_aux = @w_ofi_def_app_movil)
begin
   --Elimina y crea integrantes de grupo cuando es desde la mobil
    select 
        @w_grupo        = tg_grupo,
        @w_nueva_op_aux = tg_nueva_op
    from cob_credito..cr_tramite_grupal 
    where tg_tramite = @i_tramite

    select 
    @w_val_ahorro_vol = tr_porc_garantia ,
    @w_oficina_aux    = tr_oficina
    from cob_credito..cr_tramite
    where tr_tramite = @i_tramite

    /*update cob_workflow..wf_inst_proceso set 
    io_oficina_inicio  = @w_oficina_aux,
    io_oficina_entrega = @w_oficina_aux 
    where io_campo_3    = @i_tramite*/

    select @w_val_ahorro_vol = isnull( @w_val_ahorro_vol , (select pa_int from cobis..cl_parametro 
                                                            where pa_nemonico = 'VAHVO' and pa_producto = 'CRE' ))

    select @w_cliente = 0
    
    while 1=1 -- procesar el grupo
    begin
        select top 1 
            @w_cliente   = cg_ente ,
            @w_estado_cl = cg_estado 
        from cobis..cl_cliente_grupo cg
        where cg_grupo  = @w_grupo
          and cg_ente   > @w_cliente
        order by cg_ente
        if @@rowcount = 0 break

        if @w_estado_cl <> 'V' -- ya no es miembro, entonces BORRAR las operaciones hijas
        begin
            
            delete from cob_credito..cr_tramite_grupal where tg_tramite=@i_tramite and tg_cliente=@w_cliente
            select 
                @w_tg_prestamo   = '',
                @w_tg_operacion  = 0
                
            select 
                  @w_tg_prestamo   = tg_prestamo,
                  @w_tg_operacion  = tg_operacion
            from cob_credito..cr_tramite_grupal
            where tg_tramite       = @i_tramite
            and   tg_cliente       = @w_cliente
            
            select 
                  @w_tg_prestamo   = isnull(@w_tg_prestamo, ''),
                  @w_tg_operacion  = isnull(@w_tg_operacion,0)
                
           -- si son diferentes, se entiende que ya esta creada laoperacion hija
           if (@i_banco <> @w_tg_prestamo) and  @w_tg_prestamo <> '' -- YA SE CREO OP HIJA, BORRAR
           begin
                select @w_tramite_hijo = op_tramite from cob_cartera..ca_operacion where op_operacion = @w_tg_operacion
    
                delete cob_credito..cr_tramite           where tr_tramite   = @w_tramite_hijo and @w_tramite_hijo <> @i_tramite
                delete cob_cartera..ca_operacion         where op_operacion = @w_tg_operacion and @w_tg_operacion <> @i_operacionca 
                delete cob_cartera..ca_rubro_op          where ro_operacion = @w_tg_operacion and @w_tg_operacion <> @i_operacionca 
                delete cob_cartera..ca_dividendo         where di_operacion = @w_tg_operacion and @w_tg_operacion <> @i_operacionca 
                delete cob_cartera..ca_amortizacion      where am_operacion = @w_tg_operacion and @w_tg_operacion <> @i_operacionca 
                delete cob_cartera..ca_cuota_adicional   where ca_operacion = @w_tg_operacion and @w_tg_operacion <> @i_operacionca 
                delete cob_credito..cr_documento         where do_tramite   = @w_tramite_hijo and @w_tramite_hijo <> @i_tramite
                delete cob_cartera..ca_valores           where va_operacion = @w_tg_operacion and @w_tg_operacion <> @i_operacionca 
                delete cob_cartera..ca_definicion_nomina where dn_operacion = @w_tg_operacion and @w_tg_operacion <> @i_operacionca 
                delete cob_cartera..ca_relacion_ptmo     where rp_pasiva    = @w_tg_operacion and @w_tg_operacion <> @i_operacionca 
    
                select @w_tramite_hijo = 0
           end
        end
        if @w_estado_cl = 'V' -- es miembro, entonces analizar si CREAR  o no hacer NADA
        begin
            if not exists(select 1 from cob_credito..cr_tramite_grupal 
                          where tg_tramite = @i_tramite
                          and tg_cliente   = @w_cliente )
            begin
                insert into cob_credito..cr_tramite_grupal (
                       tg_tramite,         tg_cliente,              tg_monto, 
                       tg_grupal,          tg_grupo,                tg_operacion,
                       tg_prestamo,        tg_referencia_grupal,    tg_nueva_op,
                       tg_ahorro,          tg_monto_aprobado )
                select 
                       @i_tramite,         @w_cliente,               0,
                       'S',                @w_grupo,                 @i_operacionca,
                       @i_banco,           @i_banco,                 @w_nueva_op_aux,
                       @w_val_ahorro_vol,  0
                
                if @@error <> 0
                begin
                    select @w_error = 150000 -- ERROR EN INSERCION
                    goto ERROR_PROCESO
                end
            end 
        end
    end -- while grupo
    
    update cob_credito..cr_documento set do_numero = 0 where do_tramite   = @i_tramite
end -- si es desde el MOVIL

select 
@w_oficina_aux    = tr_oficina
from cob_credito..cr_tramite
where tr_tramite = @i_tramite

/*update cob_workflow..wf_inst_proceso set 
io_oficina_inicio  = @w_oficina_aux,
io_oficina_entrega = @w_oficina_aux 
where io_campo_3    = @i_tramite*/

--print 'ENVIO DE LOS NUMEROS DE OPERACION Y TRAMITE GENERADOS'
select 
@o_banco     = @w_banco,
@o_operacion = @i_operacionca,
@o_tramite   = @w_tramite
---------------------------------------------

if @w_commit = 'S' begin 
   commit tran
   select @w_commit = 'N'
end

return 0

ERROR_PROCESO:
--print 'ERROR NUMERO ' + CONVERT(VARCHAR, @w_error) + @w_sp_name
if @w_commit = 'S'
   rollback tran
    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = @w_error
    return @w_error
go
