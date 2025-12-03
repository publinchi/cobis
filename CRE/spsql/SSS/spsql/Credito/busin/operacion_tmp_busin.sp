/************************************************************************/
/*  Archivo:                operacion_tmp_busin.sp                      */
/*  Stored procedure:       sp_operacion_tmp_busin                      */
/*  Base de Datos:          cob_pac                                     */
/*  Producto:               Credito                                     */
/*  Disenado por:           Felipe Borja                                */
/*  Fecha de Documentacion: 09/May/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP en base al programa de Cartera para manejar actualizacion de     */
/*  tablas temporales de rubros al eliminar un rubro.                   */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  09/05/19          Felipe Borja     Emision Inicial                  */
/* **********************************************************************/

use cob_pac
go

if exists(select 1 from sysobjects where name ='sp_operacion_tmp_busin')
    drop proc sp_operacion_tmp_busin
go

create proc sp_operacion_tmp_busin
   @s_user                      varchar(14)   = null,
   @s_sesn                      int           = null,
   @s_date                      datetime      = null,
   @s_rol                       int           = null,
   @i_operacionca               int           = null,
   @i_banco                     varchar(24)   = null,
   @i_anterior                  varchar(24)   = null,
   @i_migrada                   varchar(24)   = null,
   @i_tramite                   int           = null,
   @i_cliente                   int           = null,
   @i_nombre                    varchar(64)   = null,
   @i_sector                    varchar(10)   = null,
   @i_toperacion                varchar(10)   = null,
   @i_oficina                   smallint      = null,
   @i_moneda                    tinyint       = null,
   @i_comentario                varchar(255)  = null,
   @i_oficial                   smallint      = null,
   @i_fecha_ini                 datetime      = null,
   @i_fecha_fin                 datetime      = null,
   @i_fecha_ult_proceso         datetime      = null,
   @i_fecha_liq                 datetime      = null,
   @i_fecha_reajuste            datetime      = null,
   @i_monto                     money         = null,
   @i_monto_aprobado            money         = null,
   @i_destino                   varchar(10)   = null,
   @i_lin_credito               varchar(24)   = null,
   @i_ciudad                    int           = null,
   @i_estado                    tinyint       = null,
   @i_periodo_reajuste          smallint      = null,
   @i_reajuste_especial         char(1)       = null,
   @i_tipo                      char(1)       = null,
   @i_forma_pago                varchar(10)   = null,
   @i_cuenta                    varchar(24)   = null,
   @i_dias_anio                 smallint      = null,
   @i_tipo_amortizacion         varchar(10)   = null,
   @i_cuota_completa            char(1)       = null,
   @i_tipo_cobro                char(1)       = null,
   @i_tipo_reduccion            char(1)       = null,
   @i_aceptar_anticipos         char(1)       = null,
   @i_precancelacion            char(1)       = null,
   @i_operacion                 char(1)       = null,
   @i_tipo_aplicacion           char(1)       = null,
   @i_tplazo                    varchar(10)   = null,
   @i_plazo                     smallint      = null,
   @i_tdividendo                varchar(10)   = null,
   @i_periodo_cap               smallint      = null,
   @i_periodo_int               smallint      = null,
   @i_dist_gracia               char(1)       = null,
   @i_gracia_cap                smallint      = null,
   @i_gracia_int                smallint      = null,
   @i_dia_fijo                  tinyint       = null,
   @i_fecha_pri_cuot            datetime      = null,
   @i_cuota                     money         = null,
   @i_evitar_feriados           char(1)       = null,
   @i_num_renovacion            tinyint       = null,
   @i_renovacion                char(1)       = null,
   @i_mes_gracia                tinyint       = null,
   @i_upd_clientes              char(1)       = null,
   @i_reajustable               char(1)       = null,
   @i_dias_clausula             int           = null,
   @i_periodo_crecimiento       smallint      = 0,
   @i_tasa_crecimiento          float         = 0,
   @i_direccion                 tinyint       = 1,
   @i_opcion_cap                char          = 'N',
   @i_tasa_cap                  float         = null,
   @i_dividendo_cap             smallint      = null,
   @i_clase_cartera             varchar(10)   = null,
   @i_origen_fondos             varchar(10)   = null,
   @i_tipo_empresa              varchar(10)   = null,
   @i_validacion                varchar(10)   = null,
   @i_tipo_crecimiento          char(1)       = 'A',     --MARCA QUE INDICA SI LA TABLA DE AMORTIZACION SE GENERA CON UN VALOR DE CAPITAL O UN VALOR DE CUOTA FIJA
   @i_num_reest                 int           = null,
   @i_base_calculo              char(1)       = null,
   @i_ult_dia_habil             char(1)       = null,
   @i_tasa_equivalente          char(1)       = null,
   @i_recalcular                char(1)       = null,
   @i_fondos_propios            char(1)       = 'N',
   @i_ref_exterior              varchar(24)   = null,
   @i_sujeta_nego               char(1)       = null,
   @i_prd_cobis                 tinyint       = null,
   @i_ref_red                   varchar(24)   = ' ',
   @i_tipo_redondeo             tinyint       = null,
   @i_causacion                 char(1)       = null,
   @i_tramite_ficticio          int           = null,
   @i_grupo_fact                int           = null,
   @i_convierte_tasa            char(1)       = null,
   @i_tipo_linea                varchar(10)   = null,
   @i_subtipo_linea             varchar(10)   = null,
   @i_bvirtual                  char(1)       = null,
   @i_extracto                  char(1)       = null,
   @i_reestructuracion          char(1)       = null,
   @i_subtipo                   char(1)       = null,
   @i_naturaleza                char(1)       = null,
   @i_fec_embarque              datetime      = null,
   @i_fec_dex                   datetime      = null,
   @i_num_deuda_ext             varchar(24)   = null,
   @i_num_comex                 varchar(24)   = null,
   @i_pago_caja                 char(1)       = null,
   @i_nace_vencida              char(1)       = null,
   @i_oper_pas_ext              varchar(24)   = null,
   @i_calcula_devolucion        char(1)       = null,
   @i_entidad_convenio          varchar(10)   = null,
   @i_mora_retroactiva          char(1)       = null,
   @i_prepago_desde_lavigente   char(1)       = null,
   @i_banca                     catalogo      = null,
   @i_grupal                    char(1)       = null, --LRE 05/Ene/2017
   @i_promocion                 char(1)       = null, --LPO Santander
   @i_acepta_ren                char(1)       = null, --LPO Santander
   @i_no_acepta                 char(1000)    = null, --LPO Santander
   @i_emprendimiento            char(1)       = null, --LPO Santander
   @i_grupo                     int           = null, --AGI TeCreemos
   @i_ref_grupal                cuenta        = null, --AGI TeCreemos
   @i_es_grupal                 char(1)       = null, --AGI TeCreemos
   @i_origen_fondo              catalogo      = null, --AGI TeCreemos
   -- FBO Tabla Amortizacion
   @i_pasa_definitiva		    char(1)		  = 'S'


   as
   declare
   @w_sp_name              varchar(64),
   @w_return               int,
   @w_error                int,
   @w_banco                varchar(24),
   @w_rel_codeudor         int,
   @w_codeudores           int,
   @w_rol                  char(1),
   @w_cliente              int,
   @w_inicial              int,
   @w_dp_det_producto      int,
   @w_titular              int,

   /*VARIABLES PARA PARAMETROS DE FACTORING*/
   @w_periodo_reaj         smallint,
   @w_reajuste_especial    char(1),
   @w_precancelacion       char(1),
   @w_tipo                 char(1),
   @w_cuota_completa       char(1),
   @w_tipo_reduccion       char(1),
   @w_aceptar_anticipos    char(1),
   @w_tplazo               varchar(10),
   @w_plazo                smallint,
   @w_tdividendo           varchar(10),
   @w_periodo_cap          smallint,
   @w_periodo_int          smallint,
   @w_gracia_cap           smallint,
   @w_gracia_int           smallint,
   @w_dist_gracia          char(1),
   @w_dias_anio            smallint,
   @w_tipo_amortizacion    varchar(10),
   @w_dia_pago             tinyint,
   @w_evitar_feriados      char(1),
   @w_renovacion           char(1),
   @w_mes_gracia           tinyint,
   @w_tipo_aplicacion      char(1),
   @w_tipo_cobro           char(1),
   @w_reajustable          char(1),
   @w_base_calculo         char(1),
   @w_ult_dia_habil        char(1),
   @w_recalcular           char(1),
   @w_prd_cobis            tinyint,
   @w_tipo_redondeo        tinyint,
   @w_causacion            char(1),
   @w_convierte_tasa       char(1),
   @w_usar_tequivalente    char(1),
   @w_forma_pago           varchar(10),
   @w_operacion_fact       int,
   @w_fecha                DATETIME,
   @w_param_microcred      VARCHAR(15),    --LRE 06/ENE/2017
   @w_rowcount             INT ,           --LRE 06/ENE/2017
   @w_valIni                    VARCHAR(20),    --AGI 16ABR19
   @w_valFin                    VARCHAR(20),    --AGI 16ABR19
   @w_frecuency			        VARCHAR(20),    --AGI 16ABR19
   @w_plazo_meses               FLOAT,          --AGI 16ABR19
   @w_variables		            VARCHAR(64),    --AGI 16ABR19
   @w_return_variable	        VARCHAR(25),    --AGI 16ABR19
   @w_return_results	        VARCHAR(25),    --AGI 16ABR19
   @w_return_results_plazo      VARCHAR(255),   --AGI 16ABR19
   @w_last_condition_parent     VARCHAR(10),    --AGI 16ABR19
   @w_tipo_pa					VARCHAR(10),    --AGI 16ABR19
   @w_band_regla                INT,            --AGI 16ABR19
   @w_msg  					    VARCHAR(255)    --AGI 16ABR19

/* Fin RBU */

/* CARGAR VALORES INICIALES */
select @w_sp_name = 'sp_operacion_tmp',
       @w_fecha   = getdate()


--LRE 06/ENE/2017 PARAMETRO PARA IDENTIFICAR MICROCREDITOS
select @w_param_microcred = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CSMIC'

select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted


if @w_rowcount = 0 begin

   exec cobis..sp_cerror
       @t_debug='N',
       @t_file = null,
       @t_from =@w_sp_name,
       @i_num = 724598
       return 1
end
--FIN LRE 06/ENE/2017 PARAMETRO PARA IDENTIFICAR MICROCREDITOS

/* VALIDAR EXISTENCIA DE NUMERO DE OPERACION ANTERIOR */
select @i_num_renovacion = 0

if @i_anterior is not null
begin


   if @i_anterior like '72%'
   begin
      if not exists( select 1 from cob_cartera..ca_operacion where op_banco = @i_anterior)
         return 710074
   end

   select @w_banco = @i_anterior
end


--INI AGI.  --VALIDACION DE REGLAS
--REGLA DE DIA DE PAGO'
if @i_tplazo is null
    select @i_tplazo = opt_tplazo
    from cob_cartera..ca_operacion_tmp
    where opt_operacion =  @i_operacionca

if @i_plazo is null
    select @i_plazo = opt_plazo
    from cob_cartera..ca_operacion_tmp
    where opt_operacion =  @i_operacionca

if @i_monto is null
    select @i_monto = opt_plazo
    from cob_cartera..ca_operacion_tmp
    where opt_operacion =  @i_operacionca

if @i_toperacion is null
    select @i_toperacion = opt_toperacion
    from cob_cartera..ca_operacion_tmp
    where opt_operacion =  @i_operacionca

if @i_tipo is null
    select @i_toperacion = opt_tipo
    from cob_cartera..ca_operacion_tmp
    where opt_operacion =  @i_operacionca

select @w_frecuency = td_tdividendo
from   cob_cartera..ca_tdividendo
where  td_tdividendo = @i_tplazo

select @w_variables = @i_toperacion + '|' + @w_frecuency

--LPO CDIG Se quitan estas reglas porque eran solo de la version Te Creemos INICIO
/*
exec @w_error               = cob_pac..sp_rules_param_run
     @s_rol                   = @s_rol,
     @i_rule_mnemonic         = 'DIA_PAGO',
     @i_var_values            = @w_variables,
     @i_var_separator         = '|',
     @o_return_variable       = @w_return_variable  OUT,
     @o_return_results        = @w_return_results   OUT,
     @o_last_condition_parent = @w_last_condition_parent OUT


SELECT @w_return_results  = replace(@w_return_results,'|','')

SELECT @w_valIni = substring(@w_return_results,1,(charindex('-',@w_return_results)-1))

SELECT @w_valFin = substring(@w_return_results,charindex('-',@w_return_results)+1,(len(@w_return_results)-(charindex('-',@w_return_results)-1)))

IF(convert(INT,@w_valIni) > @i_dia_fijo OR convert(INT,@w_valFin) < @i_dia_fijo)
    return  2110105


--REGLA DE PLAZOS'
if @i_tplazo not in('W','Q' )
begin
    select  @w_plazo_meses = isnull((@i_plazo * (select td_factor
                                      from   cob_cartera..ca_tdividendo
                                              where  td_tdividendo = @i_tplazo))/30.0,0)
end
else
begin
    if @i_tplazo = 'W'
    begin
        SELECT  @w_plazo_meses = convert(INT,(@i_plazo/(52/12.0)))
    end
    if @i_tplazo = 'Q'
    begin
       SELECT @w_plazo_meses = @i_plazo / 2
    end
end

if(@w_plazo_meses > 0)
begin
    IF (@i_tipo = 'R')
        SELECT  @w_tipo_pa='S'
    ELSE
        SELECT @w_tipo_pa = 'N'

    select @w_variables = @i_toperacion + '|'
                          + convert(VARCHAR(25),@i_monto)+ '|'
                          + (SELECT p_calif_cliente FROM cobis..cl_ente
                               WHERE en_ente = @i_cliente) + '|'
                          + @w_tipo_pa

    exec @w_error               = cob_pac..sp_rules_param_run
      @s_rol                   = @s_rol,
      @i_rule_mnemonic         = 'RPLAZ',
      @i_var_values            = @w_variables,
      @i_var_separator         = '|',
      @o_return_variable       = @w_return_variable  OUT,
      @o_return_results        = @w_return_results_plazo   OUT,
      @o_last_condition_parent = @w_last_condition_parent OUT

    IF @w_error != 0
    begin
        return @w_error
    end
    else
    Begin
        SELECT @w_return_results_plazo = replace(@w_return_results_plazo,'|','')
        IF @w_return_results_plazo is null
        begin
           --El cliente no cumple con la calificación esperada
            return  2110107
        end
        IF @w_return_results_plazo = '0'
        begin
            return 2110104
        end
        if not exists(SELECT number FROM cob_pac..intlist_to_tbl(@w_return_results_plazo,',') WHERE number = @w_plazo_meses)
        BEGIN
           select @w_msg = 'Plazo no permitido, Los plazos permitidos son: '+ convert(varchar(100),@w_return_results_plazo)+' meses'
            exec cobis..sp_cerror
                 @t_from  = @w_sp_name,
                 @i_num   = 2110106,
                 @i_sev   = 1,
                 @i_msg   = @w_msg
            return @w_error
        END
    end
end
else
begin
    select @w_msg = 'Plazo no permitido'
    exec cobis..sp_cerror
         @t_from  = @w_sp_name,
         @i_num   = 2110106,
         @i_sev   = 1,
         @i_msg   = @w_msg
    return @w_error
end
--FIN  AGI
*/
--LPO CDIG Se quitan estas reglas porque eran solo de la version Te Creemos FIN


if @i_operacion = 'I'
begin

   insert into cob_cartera..ca_operacion_tmp (
   opt_operacion,            opt_banco,                     opt_anterior,
   opt_migrada,              opt_tramite,                   opt_cliente,
   opt_nombre,               opt_sector,                    opt_toperacion,
   opt_oficina,              opt_moneda,                    opt_comentario,
   opt_oficial,              opt_fecha_ini,                 opt_fecha_fin,
   opt_fecha_ult_proceso,    opt_fecha_liq,                 opt_fecha_reajuste,
   opt_monto,                opt_monto_aprobado,            opt_destino,
   opt_lin_credito,          opt_ciudad,                    opt_estado,
   opt_periodo_reajuste,     opt_reajuste_especial,         opt_tipo,
   opt_forma_pago,           opt_cuenta,                    opt_dias_anio,
   opt_tipo_amortizacion,    opt_cuota_completa,            opt_tipo_cobro,
   opt_tipo_reduccion,       opt_aceptar_anticipos,         opt_precancelacion,
   opt_tipo_aplicacion,      opt_tplazo,                    opt_plazo,
   opt_tdividendo,           opt_periodo_cap,               opt_periodo_int,
   opt_dist_gracia  ,        opt_gracia_cap,                opt_gracia_int,
   opt_numero_reest,         opt_dia_fijo,                  opt_cuota,
   opt_evitar_feriados,      opt_num_renovacion,            opt_renovacion,
   opt_mes_gracia,           opt_reajustable,               opt_dias_clausula,
   opt_clausula_aplicada,    opt_periodo_crecimiento,       opt_tasa_crecimiento,
   opt_direccion,            opt_opcion_cap,                opt_tasa_cap,
   opt_dividendo_cap,        opt_clase,       opt_edad,
   opt_origen_fondos,        opt_tipo_crecimiento,          opt_base_calculo,
   opt_dia_habil,            opt_recalcular_plazo,          opt_fondos_propios,
   opt_prd_cobis,            opt_ref_exterior,              opt_sujeta_nego,
   opt_nro_red,              opt_tipo_redondeo,             opt_tipo_empresa,
   opt_validacion,           opt_fecha_pri_cuot,            opt_causacion,
   opt_convierte_tasa,       opt_usar_tequivalente,         opt_tipo_linea,
   opt_subtipo_linea,        opt_bvirtual,                  opt_extracto,
   opt_num_deuda_ext,        opt_fecha_embarque,            opt_fecha_dex,
   opt_reestructuracion,     opt_tipo_cambio,               opt_naturaleza,
   opt_pago_caja,            opt_nace_vencida,              opt_num_comex,
   opt_calcula_devolucion,   opt_codigo_externo,            opt_entidad_convenio,
   opt_mora_retroactiva,     opt_prepago_desde_lavigente,   opt_banca,
   opt_promocion,            opt_acepta_ren,                opt_no_acepta,
   opt_emprendimiento,       opt_grupo,                     opt_ref_grupal,
   opt_grupal
   )
   values (
   @i_operacionca,                    @i_banco,                     @i_anterior,
   @i_migrada,                        @i_tramite,                   @i_cliente,
   @i_nombre,                         @i_sector,                    @i_toperacion,
   @i_oficina,                        @i_moneda,                    @i_comentario,
   @i_oficial,                        @i_fecha_ini,                 @i_fecha_fin,
   @i_fecha_ult_proceso,              @i_fecha_liq,                 @i_fecha_reajuste,
   @i_monto,                          @i_monto_aprobado,            @i_destino,
   @i_lin_credito,                    @i_ciudad,                    @i_estado,
   @i_periodo_reajuste,               @i_reajuste_especial,         @i_tipo,
   @i_forma_pago,                     @i_cuenta,                    @i_dias_anio,
   @i_tipo_amortizacion,              @i_cuota_completa,            @i_tipo_cobro,
   @i_tipo_reduccion,                 @i_aceptar_anticipos,         isnull(@i_precancelacion,'S'),
   @i_tipo_aplicacion,                @i_tplazo,                    @i_plazo,
   @i_tdividendo,                     @i_periodo_cap,               @i_periodo_int,
   @i_dist_gracia,                    @i_gracia_cap,                @i_gracia_int,
   isnull(@i_num_reest,0),            @i_dia_fijo,                  @i_cuota,
   @i_evitar_feriados,                @i_num_renovacion,            @i_renovacion,
   @i_mes_gracia,                     @i_reajustable,               @i_dias_clausula,
   'N',                               @i_periodo_crecimiento,       @i_tasa_crecimiento,
   @i_direccion,                      @i_opcion_cap,                @i_tasa_cap,
   @i_dividendo_cap,                  @i_clase_cartera,             1,
   @i_origen_fondos,                  @i_tipo_crecimiento,          @i_base_calculo,
   @i_ult_dia_habil,                  @i_recalcular,                @i_fondos_propios,
   @i_prd_cobis,                      @i_ref_exterior,              @i_sujeta_nego,
   @i_ref_red,                        @i_tipo_redondeo,             @i_tipo_empresa,
   @i_validacion,                     @i_fecha_pri_cuot,            @i_causacion,
   @i_convierte_tasa,                 @i_tasa_equivalente,          @i_tipo_linea,
   @i_subtipo_linea,                  @i_bvirtual,                  @i_extracto,
   @i_num_deuda_ext,                  @i_fec_embarque,              @i_fec_dex,
   isnull(@i_reestructuracion,'N'),   @i_subtipo,                   @i_naturaleza,
   @i_pago_caja,                      @i_nace_vencida,              @i_num_comex,
   @i_calcula_devolucion,             @i_oper_pas_ext,              @i_entidad_convenio,
   @i_mora_retroactiva,               @i_prepago_desde_lavigente,   @i_banca,
   @i_promocion,                      @i_acepta_ren,                @i_no_acepta,
   @i_emprendimiento,  @i_grupo,   @i_ref_grupal,
   @i_es_grupal
   )

  if @@error <> 0
   begin
--     PRINT 'opertmp.sp error de insercion de registro ' + cast(@@error as varchar)
     return 710001
   end

  --LRE 05/Ene/2016 Insertar Operacion con concepto de Agrupamiento en caso de que aplique
    IF @i_subtipo_linea = @w_param_microcred
    begin
       --print 'Llamar a proceso que inserta en tabla cob_cartera..ca_operacion_ext_tmp'
       exec @w_return = cob_cartera..sp_operacion_param
            @i_operacion = "I",
    @i_operacionca = @i_operacionca,
            @i_columna     = "opt_grupal",
            @i_grupal      = @i_grupal

       if @w_return != 0 return @w_return
    end

end

if @i_fecha_pri_cuot is null
begin
  select @i_fecha_pri_cuot = opt_fecha_pri_cuot
  from   cob_cartera..ca_operacion_tmp
  where  opt_operacion = @i_operacionca
end
ELSE
begin
   if @i_fecha_pri_cuot = @i_fecha_ini
      select @i_fecha_pri_cuot = null
end



if @i_operacion = 'U'
begin

   if @i_direccion = 0
       select @i_direccion = 1
   if @i_tramite_ficticio is null -- Operacion normal
   begin
      update cob_cartera..ca_operacion_tmp set
      opt_anterior                   = isnull(@i_anterior,opt_anterior),
      opt_migrada                    = isnull(@i_migrada,opt_migrada),
      opt_tramite                    = isnull(@i_tramite,opt_tramite),
      opt_cliente                    = isnull(@i_cliente,opt_cliente),
      opt_nombre                     = isnull(@i_nombre,opt_nombre),
      opt_sector                     = isnull(@i_sector,opt_sector),
      opt_toperacion                 = isnull(@i_toperacion,opt_toperacion),
      opt_oficina                    = isnull(@i_oficina,opt_oficina),
      opt_moneda                     = isnull(@i_moneda,opt_moneda),
      opt_comentario                 = isnull(@i_comentario,opt_comentario),
      opt_oficial                    = isnull(@i_oficial,opt_oficial),
      opt_fecha_ini                  = isnull(@i_fecha_ini,opt_fecha_ini),
      opt_fecha_fin                  = isnull(@i_fecha_fin,opt_fecha_fin),
      opt_fecha_ult_proceso          = isnull(@i_fecha_ult_proceso,opt_fecha_ult_proceso),
      opt_fecha_liq                  = isnull(@i_fecha_liq,opt_fecha_liq),
      opt_fecha_reajuste             = isnull(@i_fecha_reajuste,opt_fecha_reajuste),
      opt_monto                      = isnull(@i_monto,opt_monto),
      opt_monto_aprobado             = isnull(@i_monto_aprobado,opt_monto_aprobado),
      opt_destino                    = isnull(@i_destino,opt_destino),
      opt_lin_credito                = isnull(@i_lin_credito,opt_lin_credito),
      opt_ciudad                     = isnull(@i_ciudad,opt_ciudad),
      opt_estado                     = isnull(@i_estado,opt_estado),
      opt_periodo_reajuste           = isnull(@i_periodo_reajuste,opt_periodo_reajuste),
      opt_reajuste_especial          = isnull(@i_reajuste_especial,opt_reajuste_especial),
      opt_tipo                       = isnull(@i_tipo,opt_tipo),-- MPO Ref. 014 02/05/2002
      opt_forma_pago                 = isnull(@i_forma_pago,opt_forma_pago),
      opt_cuenta                     = isnull(@i_cuenta,opt_cuenta),-- MPO Ref. 014 02/05/2002
      opt_dias_anio                  = isnull(@i_dias_anio,opt_dias_anio),
      opt_tipo_amortizacion          = isnull(@i_tipo_amortizacion,opt_tipo_amortizacion),
      opt_cuota_completa             = isnull(@i_cuota_completa,opt_cuota_completa),
      opt_tipo_cobro                 = isnull(@i_tipo_cobro,opt_tipo_cobro),
      opt_tipo_reduccion             = isnull(@i_tipo_reduccion,opt_tipo_reduccion),
      opt_aceptar_anticipos          = isnull(@i_aceptar_anticipos,opt_aceptar_anticipos),
      opt_precancelacion             = isnull(@i_precancelacion,'S'),
      opt_tipo_aplicacion            = isnull(@i_tipo_aplicacion,opt_tipo_aplicacion),
      opt_tplazo                     = isnull(@i_tplazo,opt_tplazo),
      opt_plazo   = isnull(@i_plazo,opt_plazo),
      opt_tdividendo                 = isnull(@i_tdividendo,opt_tdividendo),
      opt_periodo_cap                = isnull(@i_periodo_cap,opt_periodo_cap),
      opt_periodo_int                = isnull(@i_periodo_int,opt_periodo_int),
      opt_dist_gracia                = isnull(@i_dist_gracia,opt_dist_gracia),
      opt_gracia_cap                 = isnull(@i_gracia_cap,opt_gracia_cap),
      opt_gracia_int                 = isnull(@i_gracia_int,opt_gracia_int),
      opt_dia_fijo                   = isnull(@i_dia_fijo,opt_dia_fijo),
      opt_cuota                      = isnull(@i_cuota,opt_cuota),
      opt_base_calculo               = isnull(@i_base_calculo, opt_base_calculo),
      opt_fecha_pri_cuot             = isnull(@i_fecha_pri_cuot, opt_fecha_pri_cuot),
      opt_dia_habil                  = isnull(@i_ult_dia_habil,opt_dia_habil),
      opt_recalcular_plazo           = isnull(@i_recalcular,opt_recalcular_plazo),
      opt_usar_tequivalente          = isnull(@i_tasa_equivalente,opt_usar_tequivalente),
      opt_evitar_feriados            = isnull(@i_evitar_feriados,opt_evitar_feriados),
      opt_num_renovacion             = isnull(@i_num_renovacion,opt_num_renovacion),
      opt_renovacion                 = isnull(@i_renovacion,opt_renovacion),
      opt_mes_gracia                 = isnull(@i_mes_gracia,opt_mes_gracia),
      opt_reajustable                = isnull(@i_reajustable,opt_reajustable),
      opt_dias_clausula              = isnull(@i_dias_clausula, opt_dias_clausula),
      opt_periodo_crecimiento        = isnull(@i_periodo_crecimiento, opt_periodo_crecimiento),
      opt_tasa_crecimiento           = isnull(@i_tasa_crecimiento,opt_tasa_crecimiento),
      opt_direccion                  = isnull(@i_direccion, opt_direccion),
      opt_opcion_cap                 = isnull(@i_opcion_cap, opt_opcion_cap),
      opt_tasa_cap                   = isnull(@i_tasa_cap, opt_tasa_cap),
      opt_dividendo_cap              = isnull(@i_dividendo_cap, opt_dividendo_cap),
      opt_clase                      = isnull(@i_clase_cartera,opt_clase),
      opt_origen_fondos              = isnull(@i_origen_fondos,opt_origen_fondos),
      opt_fondos_propios             = isnull(@i_fondos_propios,opt_fondos_propios),
      opt_tipo_crecimiento           = isnull(@i_tipo_crecimiento,opt_tipo_crecimiento),
      opt_numero_reest               = isnull(@i_num_reest,opt_numero_reest) ,
      opt_prd_cobis                  = isnull(@i_prd_cobis, opt_prd_cobis),
      opt_ref_exterior               = isnull(@i_ref_exterior, opt_ref_exterior),
      opt_sujeta_nego                = isnull(@i_sujeta_nego,  opt_sujeta_nego),
      opt_nro_red                    = isnull(@i_ref_red, opt_nro_red),
      opt_tipo_redondeo              = isnull(@i_tipo_redondeo, opt_tipo_redondeo),
      opt_tipo_empresa               = isnull(@i_tipo_empresa, opt_tipo_empresa),
      opt_validacion                 = isnull(@i_validacion,  opt_validacion),
      opt_causacion                  = isnull(@i_causacion, opt_causacion),
      opt_convierte_tasa             = isnull(@i_convierte_tasa,opt_convierte_tasa),
      opt_grupo_fact                 = isnull(@i_grupo_fact,opt_grupo_fact),
      opt_tramite_ficticio           = isnull(@i_tramite_ficticio,opt_tramite_ficticio),
      opt_bvirtual                   = isnull(@i_bvirtual,opt_bvirtual),
      opt_extracto                   = isnull(@i_extracto,opt_extracto),
      opt_num_deuda_ext              = isnull(@i_num_deuda_ext,opt_num_deuda_ext),
      opt_fecha_embarque             = isnull(@i_fec_embarque,opt_fecha_embarque),
    opt_fecha_dex                  = isnull(@i_fec_dex,opt_fecha_dex),
      opt_reestructuracion           = isnull(@i_reestructuracion,opt_reestructuracion),
      opt_tipo_cambio                = isnull(@i_subtipo,opt_tipo_cambio),
      opt_naturaleza                 = isnull(@i_naturaleza, opt_naturaleza),
      opt_pago_caja       = isnull(@i_pago_caja,opt_pago_caja),
      opt_nace_vencida               = isnull(@i_nace_vencida,opt_nace_vencida),
      opt_num_comex                  = isnull(@i_num_comex,opt_num_comex),
      opt_codigo_externo             = isnull(@i_oper_pas_ext,opt_codigo_externo),
      opt_calcula_devolucion         = isnull(@i_calcula_devolucion,opt_calcula_devolucion),
      opt_entidad_convenio           = isnull(@i_entidad_convenio,opt_entidad_convenio),
      opt_mora_retroactiva           = isnull(@i_mora_retroactiva,opt_mora_retroactiva),
      opt_prepago_desde_lavigente    = isnull(@i_prepago_desde_lavigente,opt_prepago_desde_lavigente),
      opt_banca                      = isnull(@i_banca, opt_banca),
      opt_promocion                  = isnull(@i_promocion, opt_promocion),
      opt_acepta_ren                 = isnull(@i_acepta_ren, opt_acepta_ren),
      opt_no_acepta                  = isnull(@i_no_acepta, opt_no_acepta),
      opt_emprendimiento             = isnull(@i_emprendimiento, opt_emprendimiento),
      opt_grupo                      = isnull(@i_grupo, opt_grupo),
      opt_ref_grupal                 = isnull(@i_ref_grupal, opt_ref_grupal),
      opt_grupal                     = isnull(@i_es_grupal, opt_grupal)
      where opt_operacion            = @i_operacionca

      if @@error != 0
        return 710002

      --LRE 05/Ene/2016 Insertar Operacion con concepto de Agrupamiento en caso de que aplique
      if @i_subtipo_linea = @w_param_microcred
      begin
           --print 'Llamar a proceso que actualiza en tabla cob_cartera..ca_operacion_ext_tmp desde actualizacion'
           --PRINT 'grupo' + @i_grupal

           exec @w_return = cob_cartera..sp_operacion_param
                @i_operacion = "U",
                @i_operacionca = @i_operacionca,
                @i_columna     = "opt_grupal",
                @i_grupal      = @i_grupal

           if @w_return != 0 return @w_return
          end
      end

   else
    begin

     --- Operacion de Factoring
     --- HEREDAR PARAMETROS DE OPERACION FACTORING PADRE
      select
      @w_operacion_fact    = op_operacion,
      @w_periodo_reaj      = op_periodo_reajuste,
      @w_reajuste_especial = op_reajuste_especial,
      @w_precancelacion    = op_precancelacion,
      @w_tipo              = op_tipo,
      @w_cuota_completa    = op_cuota_completa,
      @w_tipo_reduccion    = op_tipo_reduccion,
      @w_aceptar_anticipos = op_aceptar_anticipos,
      @w_tplazo            = op_tplazo,
      @w_plazo             = op_plazo,
      @w_tdividendo        = op_tdividendo,
      @w_periodo_cap       = op_periodo_cap,
      @w_periodo_int       = op_periodo_int,
      @w_gracia_cap        = op_gracia_cap,
      @w_gracia_int        = op_gracia_int,
      @w_dist_gracia       = op_dist_gracia,
      @w_dias_anio         = op_dias_anio,
      @w_tipo_amortizacion = op_tipo_amortizacion,
      @w_dia_pago          = op_dia_fijo,  --rev
      @w_evitar_feriados   = op_evitar_feriados,
      @w_renovacion        = op_renovacion,
      @w_mes_gracia        = op_mes_gracia,
      @w_tipo_aplicacion   = op_tipo_aplicacion,
      @w_tipo_cobro        = op_tipo_cobro,
      @w_reajustable       = op_reajustable,
      @w_base_calculo      = op_base_calculo,
      @w_ult_dia_habil     = op_dia_habil,
      @w_recalcular        = op_recalcular_plazo,
      @w_prd_cobis         = op_prd_cobis,
      @w_tipo_redondeo     = op_tipo_redondeo,
      @w_causacion         = op_causacion,
      @w_convierte_tasa    = op_convierte_tasa,
      @w_usar_tequivalente = op_usar_tequivalente,
      @w_forma_pago        = op_forma_pago
      from cob_cartera..ca_operacion
      where op_tramite = @i_tramite_ficticio

      update cob_cartera..ca_operacion_tmp set
      opt_anterior            = isnull(@i_anterior,opt_anterior),
      opt_migrada             = isnull(@i_migrada,opt_migrada),
      opt_tramite             = isnull(@i_tramite,opt_tramite),
      opt_cliente             = isnull(@i_cliente,opt_cliente),
      opt_nombre              = isnull(@i_nombre,opt_nombre),
      opt_sector              = isnull(@i_sector,opt_sector),
      opt_toperacion          = isnull(@i_toperacion,opt_toperacion),
      opt_oficina             = isnull(@i_oficina,opt_oficina),
      opt_moneda              = isnull(@i_moneda,opt_moneda),
      opt_comentario          = isnull(@i_comentario,opt_comentario),
      opt_oficial             = isnull(@i_oficial,opt_oficial),
      opt_fecha_ini           = isnull(@i_fecha_ini,opt_fecha_ini),
      opt_fecha_fin           = isnull(@i_fecha_fin,opt_fecha_fin),
      opt_fecha_ult_proceso   = isnull(@i_fecha_ult_proceso,opt_fecha_ult_proceso),
      opt_fecha_liq           = isnull(@i_fecha_liq,opt_fecha_liq),
      opt_fecha_reajuste      = isnull(@i_fecha_reajuste,opt_fecha_reajuste),
      opt_monto               = isnull(@i_monto,opt_monto),
      opt_monto_aprobado      = isnull(@i_monto_aprobado,opt_monto_aprobado),
      opt_destino             = isnull(@i_destino,opt_destino),
      opt_lin_credito         = isnull(@i_lin_credito,opt_lin_credito),
      opt_ciudad              = isnull(@i_ciudad,opt_ciudad),
      opt_estado              = isnull(@i_estado,opt_estado),
      opt_cuota               = isnull(@i_cuota,opt_cuota),
      opt_fecha_pri_cuot      = isnull(@i_fecha_pri_cuot,opt_fecha_pri_cuot),
      opt_num_renovacion      = isnull(@i_num_renovacion,opt_num_renovacion),
      opt_dias_clausula       = isnull(@i_dias_clausula, opt_dias_clausula),
      opt_periodo_crecimiento = isnull(@i_periodo_crecimiento, opt_periodo_crecimiento),
      opt_tasa_crecimiento    = isnull(@i_tasa_crecimiento,opt_tasa_crecimiento),
      opt_direccion           = isnull(@i_direccion, opt_direccion), /*MODIF 08/10/98 ANTES opt_tasa_crecimiento*/
      opt_opcion_cap          = isnull(@i_opcion_cap, opt_opcion_cap),
      opt_tasa_cap            = isnull(@i_tasa_cap, opt_tasa_cap),
      opt_dividendo_cap       = isnull(@i_dividendo_cap, opt_dividendo_cap),
      opt_clase               = isnull(@i_clase_cartera,opt_clase), /*AUMENTADO*/
      opt_origen_fondos       = isnull(@i_origen_fondos,opt_origen_fondos),/*AUMENTADO*/
      opt_fondos_propios      = isnull(@i_fondos_propios,opt_fondos_propios),
      opt_tipo_crecimiento    = isnull(@i_tipo_crecimiento,opt_tipo_crecimiento),-- 02/Feb/99
      opt_numero_reest        = isnull(@i_num_reest,opt_numero_reest) ,
      opt_ref_exterior        = isnull(@i_ref_exterior, opt_ref_exterior), -- LG
      opt_sujeta_nego         = isnull(@i_sujeta_nego,  opt_sujeta_nego),  -- LG
      opt_nro_red             = isnull(@i_ref_red, opt_nro_red),
      opt_tipo_empresa        = isnull(@i_tipo_empresa, opt_tipo_empresa), --DAG
      opt_validacion          = isnull(@i_validacion,  opt_validacion), --DAG
      opt_grupo_fact          = isnull(@i_grupo_fact,opt_grupo_fact),
      opt_tramite_ficticio    = isnull(@i_tramite_ficticio,opt_tramite_ficticio),
      opt_bvirtual            = isnull(@i_bvirtual,opt_bvirtual),
      opt_extracto            = isnull(@i_extracto,opt_extracto),
      opt_num_deuda_ext       = isnull(@i_num_deuda_ext,opt_num_deuda_ext),
      opt_fecha_embarque      = isnull(@i_fec_embarque,opt_fecha_embarque),
      opt_fecha_dex           = isnull(@i_fec_dex,opt_fecha_dex),
      opt_naturaleza          = isnull(@i_naturaleza, opt_naturaleza),
      opt_pago_caja           = isnull(@i_pago_caja,opt_pago_caja),
      opt_nace_vencida        = isnull(@i_nace_vencida,opt_nace_vencida),
      opt_num_comex           = isnull(@i_num_comex,opt_num_comex),
      opt_calcula_devolucion  = isnull(@i_calcula_devolucion,opt_calcula_devolucion),
      /* PARAMETROS DE PADRE FACTORING */
      opt_periodo_reajuste    = isnull(@w_periodo_reaj,opt_periodo_reajuste),
      opt_reajuste_especial   = isnull(@w_reajuste_especial,opt_reajuste_especial),
      opt_precancelacion      = isnull(@w_precancelacion,'S'),
      opt_tipo            = isnull(@w_tipo,opt_tipo),
      opt_cuota_completa      = isnull(@w_cuota_completa,opt_cuota_completa),
      opt_tipo_reduccion      = isnull(@w_tipo_reduccion,opt_tipo_reduccion),
      opt_aceptar_anticipos   = isnull(@w_aceptar_anticipos,opt_aceptar_anticipos),
      opt_tplazo              = isnull(@w_tplazo,opt_tplazo),
      opt_plazo               = isnull(@w_plazo,opt_plazo),
      opt_tdividendo          = isnull(@w_tdividendo,opt_tdividendo),
      opt_periodo_cap         = isnull(@w_periodo_cap,opt_periodo_cap),
      opt_periodo_int         = isnull(@w_periodo_int,opt_periodo_int),
      opt_gracia_cap          = isnull(@w_gracia_cap,opt_gracia_cap),
      opt_gracia_int          = isnull(@w_gracia_int,opt_gracia_int),
      opt_dist_gracia         = isnull(@w_dist_gracia,opt_dist_gracia),
      opt_dias_anio           = isnull(@w_dias_anio,opt_dias_anio),
      opt_tipo_amortizacion   = isnull(@w_tipo_amortizacion,opt_tipo_amortizacion),
      opt_dia_fijo            = isnull(@w_dia_pago,opt_dia_fijo),
      opt_evitar_feriados     = isnull(@w_evitar_feriados,opt_evitar_feriados),
      opt_renovacion          = isnull(@w_renovacion,opt_renovacion),
      opt_mes_gracia          = isnull(@w_mes_gracia,opt_mes_gracia),
      opt_tipo_aplicacion     = isnull(@w_tipo_aplicacion,opt_tipo_aplicacion),
      opt_tipo_cobro          = isnull(@w_tipo_cobro,opt_tipo_cobro),
      opt_reajustable         = isnull(@w_reajustable,opt_reajustable),
      opt_base_calculo        = isnull(@w_base_calculo,opt_base_calculo),
      opt_dia_habil           = isnull(@w_ult_dia_habil,opt_dia_habil),
      opt_recalcular_plazo    = isnull(@w_recalcular,opt_recalcular_plazo),
      opt_prd_cobis           = isnull(@w_prd_cobis,opt_prd_cobis),
      opt_tipo_redondeo       = isnull(@w_tipo_redondeo,opt_tipo_redondeo),
      opt_causacion           = isnull(@w_causacion,opt_causacion),
      opt_convierte_tasa      = isnull(@w_convierte_tasa,opt_convierte_tasa),
      opt_usar_tequivalente   = isnull(@w_usar_tequivalente,opt_usar_tequivalente),
      opt_forma_pago          = isnull(@w_forma_pago,opt_forma_pago)
      where opt_operacion     = @i_operacionca

      /* ACTUALIZACION DE RUBROS INTERES Y MORA EN cob_cartera..ca_rubro_op_tmp DE HIJA */

	  if (@i_pasa_definitiva = 'S')
	  begin
	      delete from cob_cartera..ca_rubro_op_tmp
	      where rot_tipo_rubro in ('I','M')
	      and   rot_operacion = @i_operacionca

	      insert into cob_cartera..ca_rubro_op_tmp
	      (rot_operacion, rot_concepto, rot_tipo_rubro, rot_fpago,
	      rot_prioridad, rot_paga_mora, rot_provisiona, rot_signo,
	      rot_factor, rot_referencial, rot_signo_reajuste,
	      rot_factor_reajuste, rot_referencial_reajuste, rot_valor,
	      rot_porcentaje, rot_porcentaje_aux, rot_gracia,
	      rot_concepto_asociado, rot_redescuento, rot_intermediacion,
	      rot_principal, rot_porcentaje_efa, rot_garantia, rot_tipo_puntos,
	      rot_saldo_op, rot_saldo_por_desem, rot_base_calculo, rot_num_dec)
	      select
	      @i_operacionca, ro_concepto, ro_tipo_rubro, ro_fpago,
	      ro_prioridad, ro_paga_mora, ro_provisiona, ro_signo,
	      ro_factor, ro_referencial, ro_signo_reajuste,
	      ro_factor_reajuste, ro_referencial_reajuste, ro_valor,
	      ro_porcentaje, ro_porcentaje_aux, ro_gracia,
	      ro_concepto_asociado, ro_redescuento, ro_intermediacion,
	      ro_principal, ro_porcentaje_efa, ro_garantia, ro_tipo_puntos,
	      ro_saldo_op, ro_saldo_por_desem, ro_base_calculo, ro_num_dec
	      from cob_cartera..ca_rubro_op
	      where ro_operacion = @i_operacionca
	      and   ro_tipo_rubro in ('I','M')
	  end
   end


   if @i_upd_clientes = 'S' begin


      exec @w_return  = cob_cartera..sp_cliente
      @t_debug        = 'N',
      @t_file         = '',
      @t_from         = @w_sp_name,
      @s_date         = @s_date,
      @i_usuario      = @s_user,
      @i_sesion       = @s_sesn,
      @i_banco        = @i_banco,
      @i_oficina      = @i_oficina,
      @i_tipo         = 'R',
      @i_moneda       = @i_moneda,
      @i_fecha        = @w_fecha,
      @i_producto    = 7,
      @i_operacion    = 'U'

      if @w_return != 0 return @w_return
   end

end

return 0


go
