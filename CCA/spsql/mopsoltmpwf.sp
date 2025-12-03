use cob_cartera
go

/************************************************************************/
/*   Archivo:              mopsoltmpwf.sp                               */
/*   Stored procedure:     sp_modificar_oper_soltmp_wf                  */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raul Altamirano Mendez                       */
/*   Fecha de escritura:   Ene-12-2017                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      ENE-12-2017    Raul Altamirano  Emision Inicial - Version MX    */
/*      JUL-21-2021    Ricardo Rincon   se agrega @i_plazo a ejecucion  */
/*                                      de sp_tramite_cca               */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_modificar_opertmp_wf')
    drop proc sp_modificar_opertmp_wf
go

create proc sp_modificar_opertmp_wf(
   @s_srv            varchar(30),
   @s_lsrv           varchar(30),
   @s_ssn            int,
   @s_user           login,
   @s_term           varchar(30),
   @s_date           datetime,
   @s_sesn           int,
   @s_ofi            smallint,
   ---------------------------------------
   @t_trn                 int          = null,
   ---------------------------------------
   @i_operacion           varchar(1)   = 'U',     --0
   @i_calcular_tabla      varchar(1)   = 'N',     --3
   @i_tabla_nueva         varchar(1)   = 'S',     --si
   @i_operacionca         int          = null,    --si
   @i_banco               cuenta       = null,    --2
   @i_tipo                varchar(1)   = 'O',     --si
   @i_anterior            cuenta       = null,    --si
   @i_migrada             cuenta       = null,    --si
   @i_tramite             int          = null,    --si
   @i_cliente             int          = 0,       --si
   @i_nombre              descripcion  = null,    --25
   @i_sector              catalogo     = null,    --si
   @i_toperacion          catalogo     = null,    --41
   @i_oficina             smallint     = null,    --27
   @i_moneda              tinyint      = null,    --22
   @i_comentario          varchar(255) = null,    --si
   @i_oficial             smallint     = null,    --26
   @i_fecha_ini           datetime     = null,    --15
   @i_fecha_fin           datetime     = null,    --si
   @i_fecha_ult_proceso   datetime     = null,    --si
   @i_fecha_liq           datetime     = null,    --si
   @i_fecha_reajuste      datetime     = null,    --si
   @i_monto               money        = null,    --23
   @i_monto_aprobado      money        = null,    --24
   @i_destino             catalogo     = null,    --9
   @i_lin_credito         cuenta       = null,    --20
   @i_ciudad              int          = null,    --4
   @i_estado              tinyint      = null,    --si
   @i_periodo_reajuste    smallint     = 0,       --30
   @i_reajuste_especial   varchar(1)   = 'N',     --34
   @i_forma_pago          catalogo     = null,    --16
   @i_cuenta              cuenta       = null,    --6
   @i_dias_anio           smallint     = null,    --11
   @i_tipo_amortizacion   varchar(10)  = null,    --37
   @i_cuota_completa      varchar(1)   = null,    --8
   @i_tipo_cobro          varchar(1)   = null,    --39
   @i_tipo_reduccion      varchar(1)   = null,    --40
   @i_aceptar_anticipos   varchar(1)   = null,    --1
   @i_precancelacion      varchar(1)   = null,    --32
   @i_tipo_aplicacion     varchar(1)   = null,    --38
   @i_tplazo              catalogo     = null,    --42
   @i_plazo               int          = null,    --31
   @i_tdividendo          catalogo     = null,    --36
   @i_periodo_cap         int          = null,    --28
   @i_periodo_int         int          = null,    --29
   @i_dist_gracia         varchar(1)   = null,    --13
   @i_gracia_cap          int          = null,    --18
   @i_gracia_int          int          = null,    --19
   @i_dia_fijo            int          = null,    --10
   @i_cuota               money        = null,    --7
   @i_evitar_feriados     varchar(1)   = null,    --14
   @i_num_renovacion      int          = 0,       --si 
   @i_renovacion          varchar(1)   = null,    --35
   @i_mes_gracia          tinyint      = null,    --21
   @i_dias_gracia         smallint     = null,    --12
   @i_reajustable         varchar(1)   = null,    --33
   @i_seg_cre             catalogo     = null,    --si
   @i_es_interno          varchar(1)   = 'N',     --si  
   @i_formato_fecha       int          = 101,     --16
   @i_no_banco            varchar(1)   = 'S',     --si
   @i_clase_cartera       catalogo     = null,    --si
   @i_origen_fondos       catalogo     = null,    --si
   @i_fondos_propios      varchar(1)   = 'S',     --si
   @i_sujeta_nego         varchar(1)   = 'N' ,    --si
   @i_reestructuracion    varchar(1)   = null,    --si
   @i_numero_reest        int          = 0,       --si
   @i_grupal              varchar(1)   = null,    --si
   @i_banca               catalogo     = null,    --si
   @i_en_linea            varchar(1)   = 'S',     --si
   @i_externo             varchar(1)   = 'S',     --si
   @i_desde_web           varchar(1)   = 'S',     --si
   @i_salida              varchar(1)   = 'N',     --si
   @i_upd_clientes        varchar(1)   =  NULL,   --si
   @i_fecha_vcmto1        datetime     =  NULL,   --si
   @o_banco               cuenta       = null out,
   @o_operacion           int          = null out,
   @o_tramite             int          = null out,
   @o_cta_ahorro          varchar(24)  = null output,
   @o_cta_certificado     varchar(24)  = null output,
   @o_plazo               smallint     = null out,
   @o_tplazo              catalogo     = null out,
   @o_cuota               money        = null out,
   @o_tir                 float        = null out,
   @o_tea                 float        = null out,
   @o_msg                 varchar(100) = null out
)as                       

declare
   @w_sp_name              varchar(64),
   @w_return               int,
   @w_error                int,   
   @w_fecha_proceso        datetime,
   @w_operacion            int,   
   @w_banco                cuenta,
   @w_ced_ruc              varchar(15),
   @w_ced_ruc_codeudor     varchar(15),
   @w_nombre               varchar(60),
   @w_prod_cobis           smallint,   
   @w_tramite              int,
   @w_tplazo               catalogo,
   @w_plazo                smallint,
   @w_commit               char(1),
   @w_dias_plazo           smallint,
   @w_moneda               smallint,
   @w_dias_dividendo       int,
   @w_toperacion           catalogo,
   @w_filas_rec            int,
   @w_op_estado            smallint,
   @w_old_tipo_cca         catalogo,
   @w_tipo_cca             catalogo,
   @w_seg_cre              catalogo, 
   @w_monto_min            money,
   @w_monto_aprobado       money,
   @w_monto_aprobado_tmp   money,
   @w_valida_bloqueos      char(1),
   @w_doble_alicuota       char(1),
   @w_est_novigente        tinyint,
   @w_est_credito          tinyint,
   --@x_cliente              int,
   @w_clase_bloqueo        char(1),
   @w_cliente              int,
   @w_dias_gracia          int,
   @w_monto                money,
   @w_fecha_reajuste       datetime,
   @w_monto_tmp            money,
   @w_monto_max            money,
   @w_fecha_fin            datetime,
   @w_fecha_f              datetime,
   @w_fecha_ini            datetime,
   @w_estado               char(1),
   @w_razon                catalogo = null,
   @w_txt_razon            varchar(255) = null,
   @w_tr_fecha_ini         datetime = null,
   @w_tr_num_dias          smallint = 0,
   @w_tr_monto             money = 0,
   @w_tr_plazo             smallint = null,
   @w_tr_monto_soli        money    = NULL,
   @w_base_calculo         char(1),  --LGU
   @w_ref_grupal           int       --JCM
   

   

PRINT 'CARGAR VALORES INICIALES'
select @w_sp_name  = 'sp_modificar_opertmp_wf',
       @w_commit   = 'N'


PRINT 'CONSULTAR FECHA DE PROCESO'
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7


if @i_es_interno = 'S' select @i_salida = 'N'


exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   out


--if @i_doble_alicuota = 'S' select @i_clase_bloqueo = 'D'


--select @i_upd_clientes  = 'N',
       --@w_fijo_desde    = @i_fijo_desde, 
       --@w_fijo_hasta    = @i_fijo_hasta,
       --@i_activa_TirTea = isnull(@i_activa_TirTea, 'S')
       

if isnull(@i_tipo_amortizacion,'') <> ''
begin
   select @w_dias_plazo = td_factor * @i_plazo
   from cob_cartera..ca_tdividendo
   where td_tdividendo = @i_tplazo

   select @w_dias_dividendo = td_factor * @i_periodo_cap
   from cob_cartera..ca_tdividendo
   where td_tdividendo = @i_tdividendo

   if (@w_dias_plazo / @w_dias_dividendo) = 1 
      select @i_dias_anio = 365 --base de calculo pagos NO Periodicos (un solo dividendo)
   else
      select @i_dias_anio = 360 --base de calculo pagos Periodicos
end


if @i_operacionca is null 
begin
   select @i_operacionca    = opt_operacion,
          @w_toperacion     = opt_toperacion,
          @w_moneda         = opt_moneda,
          @w_cliente        = opt_cliente,
          @w_op_estado      = opt_estado,
          @w_monto          = opt_monto,
          @w_monto_aprobado = opt_monto_aprobado,
          @w_tramite        = opt_tramite,
          @w_base_calculo   = opt_base_calculo, --LGU
          @w_ref_grupal     = opt_ref_grupal  
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
          @w_base_calculo   = opt_base_calculo, --LGU
          @w_ref_grupal     = opt_ref_grupal  
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

/*   
if @w_op_estado in (@w_est_novigente, @w_est_credito)
   select @w_filas_rec = 1

else if (@i_tipo_cca != @w_old_tipo_cca) and @w_filas_rec != 0
begin
   if @i_tipo_cca != null 
   begin
      print 'No puede modificar el Tipo de Cartera'
      select @w_error = 701002
      goto ERROR_PROCESO
   end
   --select @i_tipo_cca = @w_old_tipo_cca 
end
*/
   
/*
if @i_tipo_cca <> '-'
   select @i_tipo_cca = isnull(@i_tipo_cca,@w_tipo_cca)
else
   select @i_tipo_cca = null
*/   

/*
if @i_seg_cre <> '-'
    select @i_seg_cre = isnull(@i_seg_cre,@w_seg_cre)
else
   select @i_seg_cre = null
*/   

select @w_monto_min = dt_monto_min,
       @w_monto_max = dt_monto_max
from   cob_cartera..ca_default_toperacion
where  dt_toperacion = @w_toperacion
and    dt_moneda     = @w_moneda

if @w_ref_grupal is not null
begin
	if isnull(@i_monto_aprobado, 0) > 0 
	begin
	   if isnull(@w_monto_min,0) > 0 or isnull(@w_monto_max,0) > 0
	   begin
	      if @i_monto_aprobado < @w_monto_min or @i_monto_aprobado > @w_monto_max 
	      begin
	         select @w_error = 724609  --710124
	         goto ERROR_PROCESO
	      end
	   end
	end
end

/*
--Valida Obligatoriedad de los bloqueos
select @w_valida_bloqueos = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'VBLO'
*/

--select @w_valida_bloqueos = isnull(@w_valida_bloqueos,'S')
--select @x_doble_alicuota= isnull(@i_doble_alicuota, @w_doble_alicuota)
--select @x_cliente=  isnull(@i_cliente,0)

/*
if @w_valida_bloqueos = 'S' and @x_cliente <> 0
begin
   --Si la clase de bloqueo por defecto es distinta a NO APLICA
   --Verifica si el bloqueo por operacion esta como No aplica
   if @w_clase_bloqueo <> 'N' and @x_doble_alicuota = 'E' 
   begin
      select @w_error = 710130
      goto ERROR_PROCESO
   end      
end
*/

--PARA SIMULACION DE OPERACIONES SE DEBE ENVIAR EL CODIGO -666
if @w_cliente = -666 select @i_cliente = @w_cliente


if @@trancount = 0
begin
   begin tran
   select @w_commit = 'S'
end   

/*
--CREAR OPERACION ORIGINAL EN TEMPORALES
exec @w_return = sp_crear_tmp       
@t_trn    = 7011,
@i_accion = 'A',
@i_banco  = @i_banco

if @w_return != 0
begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end       
*/


-- MODIFICAR LA OPERACION TEMPORAL

print 'antes de cob_cartera..sp_operacion_tmp'

exec @w_return = sp_operacion_tmp
@s_user              = @s_user,
@s_sesn              = @s_sesn,
@s_date              = @s_date,
@t_trn               = 7011,
@i_operacion         = 'U',
@i_operacionca       = @i_operacionca ,
@i_banco             = @i_banco ,
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
@i_fecha_ini         = @i_fecha_ini,
@i_fecha_fin         = @i_fecha_ini,
@i_fecha_ult_proceso = @i_fecha_ini,
@i_fecha_liq         = @i_fecha_ini,
@i_fecha_reajuste    = @i_fecha_ini, 
@i_monto             = @i_monto, 
@i_monto_aprobado    = @i_monto_aprobado,
@i_destino           = @i_destino,
@i_lin_credito       = @i_lin_credito,
@i_ciudad            = @i_ciudad,
@i_estado            = @i_estado,
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
@i_tdividendo        = @i_tdividendo,
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
@i_reajustable       = @i_reajustable,
@i_dias_clausula     = null,
--@i_periodo_crecimiento = @i_periodo_crecimiento,
--@i_tasa_crecimiento   = @i_tasa_crecimiento,
--@i_direccion          = @i_direccion,
--@i_clase_cartera      = @i_clase_cartera, 
--@i_origen_fondos      = @i_origen_fondos ,
@i_base_calculo       = @w_base_calculo, -- LGU    'E',
--@i_ult_dia_habil    = @i_ult_dia_habil ,
@i_recalcular         = null,
@i_tipo_empresa       = 1, 
--@i_validacion         = @i_validacion,  
--@i_fondos_propios     = @i_fondos_propios, 
--@i_ref_exterior       = @i_ref_exterior, 
--@i_sujeta_nego        = @i_sujeta_nego,  
--@i_prd_cobis          = @i_prd_cobis,    
--@i_ref_red            = @i_ref_red,
--@i_tipo_redondeo      = @i_tipo_redondeo,
--@i_causacion          = @i_causacion,
--@i_convierte_tasa     = @i_convierte_tasa,
--@i_tasa_equivalente   = @i_tasa_equivalente,
--@i_tipo_linea         = @i_tipo_linea,
--@i_subtipo_linea      = @i_subtipo_linea,
--@i_bvirtual           = @i_bvirtual,
--@i_extracto           = @i_extracto,
--@i_reestructuracion   = @i_reestructuracion,
--@i_subtipo            = @i_subtipo,
--@i_naturaleza         = @i_naturaleza,
--@i_fec_embarque       = @i_fec_embarque,
--@i_fec_dex            = @i_fec_dex,        
--@i_num_deuda_ext      = @i_num_deuda_ext, 
--@i_num_comex          = @i_num_comex,     
--@i_pago_caja          = @i_pago_caja,
--@i_nace_vencida       = @i_nace_vencida,
--@i_calcula_devolucion = @i_calcula_devolucion,
--@i_oper_pas_ext       = @i_oper_pas_ext,
--@i_num_reest          = @i_numero_reest,
--@i_entidad_convenio   = @i_entidad_convenio,
--@i_mora_retroactiva   = @i_mora_retroactiva,
--@i_prepago_desde_lavigente = @i_prepago_desde_lavigente,
@i_tipo_crecimiento     = 'A',    --AUTOMATICA, NO DIGITAN VALORES DE CAPITAL FIJO, O CUOTA FIJA
@i_banca                = @i_banca,
@i_grupal               = @i_grupal


if @w_return != 0
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
       

if @i_calcular_tabla = 'N' and @w_op_estado in (@w_est_novigente, @w_est_credito)
begin
    if @i_monto <> @w_monto or @i_monto_aprobado <> @w_monto_aprobado --or
    begin
       select @i_calcular_tabla = 'S'
    end
end
       

if @i_calcular_tabla = 'S'
begin
   print 'antes de ejecutar: cob_cartera..sp_gentabla'

   exec @w_return = cob_cartera..sp_gentabla
   @i_operacionca = @i_operacionca,
   @i_tabla_nueva = @i_tabla_nueva,
   @i_dias_gracia = @i_dias_gracia,
   @o_fecha_fin   = @w_fecha_fin out,
   @o_cuota       = @o_cuota     out,
   @o_plazo       = @o_plazo     out,
   @o_tplazo      = @o_tplazo    out

   if @w_return != 0
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
      select @w_error = 710024
      goto ERROR_PROCESO
   end   


   update cob_cartera..ca_operacion_tmp
   set opt_fecha_fin  = @w_fecha_fin,
   opt_fecha_reajuste = @w_fecha_reajuste,
   opt_plazo          = @o_plazo,
   opt_tplazo         = @o_tplazo
   where opt_operacion = @i_operacionca

   if @@error != 0 
   begin
      select @w_error = 710002
      goto ERROR_PROCESO
   end
   
   
   --SE DISPLAYA DATOS AL FRONTEND DESDE LA PANTALLA FGENAMORTIZACION
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


select @w_fecha_ini = opt_fecha_ini
from   cob_cartera..ca_operacion_tmp
where  opt_operacion = @i_operacionca

select @i_fecha_ini = isnull(@i_fecha_ini, @w_fecha_ini)


--MODIFICAR TRAMITE DEBIDO AL RECHAZO
print 'antes de cob_credito..sp_up_tramite'

if isnull(@i_tramite, 0) > 0 and (@w_op_estado in (@w_est_novigente, @w_est_credito))
begin

   select 
   @w_estado       = tr_estado,
   @w_razon        = tr_razon,
   @w_txt_razon    = tr_txt_razon,
   @w_tr_fecha_ini = tr_fecha_inicio,
   @w_tr_num_dias  = tr_num_dias,   
   @w_tr_monto     = tr_monto,
   @w_tr_monto_soli= tr_monto_solicitado,
   @w_tr_plazo     = tr_plazo
   from cob_credito..cr_tramite
   where tr_tramite = @i_tramite

   if @@rowcount = 0
   begin
      select @w_error = 2105002
      goto ERROR_PROCESO
   end
   

   exec @w_return   = cob_credito..sp_up_tramite_cca
   @s_date          = @s_date,
   @s_lsrv          = @s_lsrv,
   @s_ofi           = @s_ofi,
   @s_sesn          = @s_sesn,
   @s_srv           = @s_srv,
   @s_ssn           = @s_ssn,
   @s_term          = @s_term,
   @s_user          = @s_user,
   @t_trn           = @t_trn,
   @i_operacion        = 'U',
   @i_tramite       = @i_tramite,
   @i_fecha_inicio  = @i_fecha_ini,
   @i_num_dias      = @i_plazo,
   @i_monto         = @i_monto_aprobado,
   @i_monto_solicitado = @i_monto,
   @i_plazo         = @i_plazo,
   @i_estado        = @i_estado,
   @i_w_estado      = @w_estado,
   @i_w_razon       = @w_razon,
   @i_w_txt_razon   = @w_txt_razon,
   @i_w_numero_op_banco = @i_banco,
   @i_w_fecha_inicio    = @w_tr_fecha_ini,
   @i_w_num_dias        = @w_tr_num_dias,
   @i_w_monto           = @w_tr_monto,
   @i_w_plazo           = @w_tr_plazo,
   @i_w_monto_solicitado= @w_tr_monto_soli

   if @w_return <> 0 
   begin
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
end


--select @o_tea  = 0.0, @o_tir  = 0.0

--------------------------------------------------------

/*
---------------------------------------------
PRINT 'CREACION DE LA OPERACION'
exec @w_return = cob_cartera..sp_crear_operacion
--@s_ssn            = @s_ssn,
@s_user           = @s_user,
@s_sesn           = @s_sesn,
@s_term           = @s_term,
@s_date           = @s_date,
@i_anterior       = @i_anterior,
@i_comentario     = @i_comentario,
@i_oficial        = @i_oficial,
@i_destino        = @i_destino,
@i_monto_aprobado = @i_monto_aprobado,
@i_fondos_propios = @i_fondos_propios,
@i_ciudad         = @i_ciudad,
@i_cliente        = @i_cliente,
@i_nombre         = @w_nombre,
@i_sector         = @i_sector,
@i_oficina        = @i_oficina,
@i_toperacion     = @i_toperacion,
@i_monto          = @i_monto,
@i_moneda         = @i_moneda,
@i_fecha_ini      = @i_fecha_ini,
@i_lin_credito    = @i_lin_credito,
@i_migrada        = @i_migrada,
@i_formato_fecha  = @i_formato_fecha,
@i_forma_pago     = @i_forma_pago,
@i_cuenta         = @i_cuenta,
@i_clase_cartera  = @i_clase_cartera,
@i_origen_fondos  = @i_origen_fondos,
@i_sujeta_nego    = @i_sujeta_nego,   -- sujeta a negociacion
@i_ref_exterior   = @i_ref_exterior,  -- numero de referencia exterior
@i_convierte_tasa = @i_convierte_tasa,  
@i_tasa_equivalente = @i_tasa_equivalente,  
@i_fec_embarque   = @i_fec_embarque,
@i_reestructuracion = @i_reestructuracion,
@i_tipo_cambio    = @i_tipo_cambio,
@i_grupal         = @i_grupal,
@o_banco          = @w_banco output

if @w_return != 0
begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end


PRINT 'GENERAR TRAMITE DEBIDO A LA CREACION DIRECTA EN CCA (VERIFICAR AL FINAL)'
exec @w_return = cob_credito..sp_tramite_cca
@s_ssn               = @s_ssn,
@s_user              = @s_user,
@s_sesn              = @s_sesn,
@s_term              = @s_term,
@s_date              = @s_date,
@s_srv               = @s_srv,
@s_lsrv              = @s_lsrv,
@s_ofi               = @s_ofi,
@i_oficina_tr        = @i_oficina,
@i_fecha_crea        = @i_fecha_ini,
@i_oficial           = @i_oficial,
@i_sector            = @i_sector,
@i_banco             = @w_banco,
@i_linea_credito     = @i_lin_credito,
@i_toperacion        = @i_toperacion,
@i_producto          = 'CCA',
@i_tipo              = @i_tipo,
@i_monto             = @i_monto,
@i_moneda            = @i_moneda,                                       
@i_periodo           = @w_tplazo,
@i_num_periodos      = @w_plazo,
@i_plazo             = @w_plazo,
@i_destino           = @i_destino,
@i_ciudad_destino    = @i_ciudad,
@i_renovacion        = @i_num_renovacion,
@i_clase             = @i_clase_cartera, 
@i_cliente           = @i_cliente,
@o_tramite           = @w_tramite out

if @w_return != 0
begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end


--TRASLADO DE INFORMACION DESDE LAS TMP A DEFINITIVAS
exec @w_return = sp_operacion_def
@s_date  = @s_date,
@s_sesn  = @s_sesn,
@s_user  = @s_user,
@s_ofi   = @s_ofi,
@i_banco = @w_banco

if @w_return != 0
begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end



PRINT 'ELIMINACION DE LA INFORMACION EN TEMPORALES'
exec @w_return = sp_borrar_tmp
--@s_date   = @s_date,
@s_sesn   = @s_sesn,
@s_user   = @s_user,
--@s_ofi    = @s_ofi,
@s_term   = @s_term,
@i_banco  = @w_banco

if @w_return != 0
begin 
   select @w_error = @w_return
   goto ERROR_PROCESO
end
*/
   
PRINT 'ENVIO DE LOS NUMEROS DE OPERACION Y TRAMITE GENERADOS'
select 
@o_banco     = @w_banco,
@o_operacion = @w_operacion,
@o_tramite   = @w_tramite
---------------------------------------------

if @w_commit = 'S' begin 
   commit tran
   select @w_commit = 'N'
end

return 0


ERROR_PROCESO:
PRINT 'ERROR NUMERO ' + CONVERT(VARCHAR, @w_error)
if @w_commit = 'S'
   rollback tran
   
return @w_error

go

