use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crear_operacion_int')
    drop proc sp_crear_operacion_int
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO
---NR.436 MAR.04.2015
create proc sp_crear_operacion_int
/*************************************************************************/
/*   NOMBRE LOGICO:      creaopin.sp                                     */
/*   NOMBRE FISICO:      sp_crear_operacion_int                          */
/*   BASE DE DATOS:      cob_cartera                                     */
/*   PRODUCTO:           Cartera                                         */
/*   DISENADO POR:       Fabian de la Torre, Rodrigo Garces              */
/*   FECHA DE ESCRITURA: Ene. 1998                                       */
/*************************************************************************/
/*                     IMPORTANTE                                        */
/*   Este programa es parte de los paquetes bancarios que son            */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,       */
/*   representantes exclusivos para comercializar los productos y        */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida      */
/*   y regida por las Leyes de la República de España y las              */
/*   correspondientes de la Unión Europea. Su copia, reproducción,       */
/*   alteración en cualquier sentido, ingeniería reversa,                */
/*   almacenamiento o cualquier uso no autorizado por cualquiera         */
/*   de los usuarios o personas que hayan accedido al presente           */
/*   sitio, queda expresamente prohibido; sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de       */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto       */
/*   en el presente texto, causará violaciones relacionadas con la       */
/*   propiedad intelectual y la confidencialidad de la información       */
/*   tratada; y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Crea una operacion de Cartera con sus rubros asociados y su     */
/*      tabla de amortizacion sp interno llamado por otros sp           */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      24/jul/98      A. Ramirez       El numero op_banco se genera en */
/*                                      la liquidacion  ALR B.ESTADO    */
/*      11/May/99   Ramiro Buitrn (CONTEXT) Personalizacion  CORFINSURA */
/*      EPB: ABR-12-2002                                                */
/*      MRoa:Abr-11-2008                Validacion monto del prestamo   */
/*      EPB: JUL-06-2010                Inc. 00129 Dia Pago             */
/*      EPB: MAR-12-2015                 NR.436 BAncamia                */
/*      LRE  05/Ene/2017                Incluir concepto de Agrupamiento*/
/*                                      de Operaciones                  */
/*      LGU  12/Abr/2017                Incluir concepto de Agrupamiento*/
/*      JSA  22/May/2017                CGS-S112643                     */
/*      JSA  13/May2017                 Parametros de entrada           */
/*                                      @i_tdividendo                   */
/*                                      @i_periodo_cap                  */
/*                                      @i_periodo_int                  */
/*      AGI  07/Mar/2019                CCA-S226083-Campos de Grupales  */ 
/*      AGI  10/Abr/2019                CCA-S234465-Operaciones Grupales*/ 
/*    LGBC 29/04/2019                Cambio en la asignacion de la tasa */
/*      AGI  08/May/2019                CAR-S244096-Enlace con Tramite  */ 
/*      LRE  05/Jul/2018                Creacion Operaciones InterCiclo */
/*      LPO  07/Feb/2020                CDIG. Quitar Prints             */
/*      LPO  03/Abr/2020                CDIG. Ajustes creacion operacion*/
/*      LPO  17/Jul/2020                CDIG. Nuevos campos Renovaciones*/
/*      PNA  17/Nov/2020                TipoPlazo Anual a Mensual       */
/* 06/Ene/2021   P.Narvaez  Tipo de Reestructuracion/Tipo Renovacion    */
/*																		*/
/*      19-APR-2021     Aldair Fortiche se captura campo 				*/
/*										admin_individual de tabla		*/
/*										ca_default_toperacion   		*/
/*      06/Ene/2022  Guisela Fernandez  Ingreso de campo para           */
/*                                      grupo contable                  */
/*      21/Feb/2022  Guisela Fernandez  Calculo de rubros finanaciados  */
/*      08/Mar/2022  Kevin Rodríguez    Validacion dia pago, fecha fija,*/
/*                                      y control dia pago tipos divi-  */
/*                                      dendos especiales               */
/*      22/03/20222  Kevin Rodríguez    Envío grupo a inserta rub Finan.*/
/*      21/04/2022   Kevin Rodríguez    Se quita validación fecha primer*/
/*                                      vencimiento de tablas especiales*/
/*      06/May/2022  Kevin Rodríguez    Actualizar num oper Grupal Hija */
/*      01/Jun/2022  Guisela Fernandez  Se comenta prints               */
/*      17/Ago/2023  Kevin Rodríguez    R213355 Quita validacion control*/
/*                                      dia pago de divs especiales     */
/************************************************************************/
   @s_user              login        = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   @s_ssn               int          = null,
   @s_ofi               smallint     = null,
   @s_srv               varchar(30)  = null,
   @i_anterior          cuenta       = null,
   @i_migrada           cuenta       = null,
   @i_tramite           int          = null,
   @i_cliente           int          = null,
   @i_nombre            descripcion  = null,
   @i_sector            catalogo     = null,
   @i_toperacion        catalogo     = null,
   @i_oficina           smallint     = null,
   @i_moneda            tinyint      = null,
   @i_comentario        varchar(255) = null,
   @i_oficial           smallint     = null,
   @i_fecha_ini         datetime     = null,
   @i_monto             money        = null,
   @i_monto_aprobado    money        = null,
   @i_destino           catalogo     = null,
   @i_lin_credito       cuenta       = null,
   @i_ciudad            int          = null,
   @i_forma_pago        catalogo     = null,
   @i_cuenta            cuenta       = null,
   @i_formato_fecha     int          = 101,
   @i_salida            char(1)      = 'S',
   @i_crear_pasiva      char(1)      = 'N',
   @i_toperacion_pasiva catalogo     = null,
   @i_operacion_activa  int          = null,
   @i_periodo_crecimiento smallint   = 0,
   @i_tasa_crecimiento  float        = 0,
   @i_direccion         tinyint      = 1,
   @i_clase_cartera     catalogo     = null,
   @i_origen_fondos     catalogo     = null, --LPO CDIG. Ajustes creacion operacion
   @i_tipo_empresa      catalogo     = null,
   @i_validacion        catalogo     = null,
   @i_ult_dia_habil     char(1)      = 'N',
   @i_fondos_propios    char(1)      = 'N',
   @i_ref_exterior      cuenta       = null,
   @i_sujeta_nego       char(1)      = null ,
   @i_ref_red           varchar(24)  = null ,
   @i_convierte_tasa    char(1)      = null ,
   @i_tasa_equivalente  char(1)      = null ,
   @i_reestructuracion  char(1)      = null ,
   @i_subtipo           char(1)      = null ,
   @i_fec_embarque      datetime     = null,
   @i_fec_dex           datetime     = null,
   @i_num_deuda_ext     cuenta       = null,
   @i_num_comex         cuenta       = null,
   @i_no_banco          char(1)      = null,
   @i_batch_dd          char(1)      = null,
   @i_tramite_hijo      int          = null,
   @i_numero_reest      int          = null,    -- RRB Feb 21 - 2002 Circular 50
   @i_oper_pas_ext      varchar(64)  = null,
   @i_banca             catalogo     = null,    --XMA
   @s_sesn              int          = null,
   @i_tplazo            catalogo     = null,   --MRoa Parametro nuevo para crear la operacion y validar el plazo desde tramites
   @i_plazo             smallint     = null,    --MRoa Parametro nuevo para crear la operacion y validar el plazo desde tramites
   @i_fecha_fija        char(1)      = null,     --LRE 02/ABR/2019 ---- KDR Se respeta lo que viene de Front-End
   @i_dia_pago          tinyint      = null,
   @i_tdividendo        catalogo     = null,
   @i_periodo_cap       int          = null,
   @i_periodo_int       int          = null,
   @i_simulacion        char(1)      = null,
   @i_signo             char(1)      = null,
   @i_factor            float        = null,
   @i_crea_ext          char(1)      = null,
   @i_tipo_tramite      char(1)      = null,     -- Req. 436 Normalizacion
   @i_grupal            char(1)      = null,     --LRE 05/Ene/2017
   @i_promocion         char(1)      = null, --LPO Santander
   @i_acepta_ren        char(1)      = null, --LPO Santander
   @i_no_acepta         char(1000)   = null, --LPO Santander
   @i_emprendimiento    char(1)      = null, --LPO Santander
   @i_grupo             int          = 0,    --AGI TeCreemos
   @i_ref_grupal        cuenta       = null, --AGI TeCreemos
   @i_es_grupal         char(1)      = 'N',  --AGI TeCreemos
   @i_fondeador         tinyint      = null, --AGI TeCreemos
   @i_tasa              float        = null, --JSA Santander
   --PQU nuevo par?metro con tasa de inter?s
   --LPO TEC se adiciona fecha ven primera cuota y tasa grupal, grupo ya se estaba pasando y ahorro esperado no aplica.
   @i_fecha_ven_pc      DATETIME      = NULL, --LPO TEC
   @i_tasa_grupal       FLOAT         = NULL, --LPO TEC   
   @i_es_interciclo     char(1)       = NULL, --LRE TEC  --10/Jul/2019
   @i_es_revolvente     char(1)      = 'N', --JJEC  --LPO CDIG. Ajustes creacion operacion
   @i_ref_revolvente    cuenta       = null, --AGI TeCreemos --LPO CDIG. Ajustes creacion operacion
   @i_gracia_cap        INT          = NULL, --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_gracia_int        INT          = NULL, --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_dist_gracia       char(1)      = NULL, --LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones 
   @i_periodo_reajuste  SMALLINT     = NULL, --LPO CDIG APIS II
   @i_reajuste_especial char(1)      = NULL, --LPO CDIG APIS II
   @i_tipo              char(1)      = NULL, --LPO CDIG APIS II
   @i_dias_anio         SMALLINT     = NULL, --LPO CDIG APIS II
   @i_tipo_amortizacion VARCHAR(30)  = NULL, --LPO CDIG APIS II
   @i_cuota_completa    CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_tipo_cobro        CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_tipo_reduccion    CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_aceptar_anticipos CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_precancelacion    CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_tipo_aplicacion   CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_evitar_feriados   CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_renovacion        CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_mes_gracia        INT          = NULL, --LPO CDIG APIS II
   @i_reajustable       CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_base_calculo      CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_causacion         CHAR(1)      = NULL, --LPO CDIG APIS II
   @i_nace_vencida      CHAR(1)      = NULL, --LPO CDIG APIS II
   /*LPO CDIG Operaciones Pasivas INICIO*/
   @i_tipo_acreedor     catalogo      = NULL,
   @i_num_cont          VARCHAR(100)  = NULL,
   @i_numreg_bc         VARCHAR(25)   = NULL,
   @i_tipo_deuda        catalogo      = NULL,
   @i_fecha_aut         datetime      = NULL,
   @i_num_aut           VARCHAR(100)  = NULL,
   @i_num_facilidad     VARCHAR(25)   = NULL,
   @i_forma_reposicion  catalogo      = NULL,
   @i_causa_fin_sub     catalogo      = NULL,
   @i_mercado_obj_fin   catalogo      = NULL,   
   /*LPO CDIG Operaciones Pasivas FIN*/
   @i_tipo_renovacion   char(1)      = null,
   @i_tipo_reest        char(1)      = null,
   @i_grupo_contable    catalogo     = null, --GFP 06/Ene/2022
   
   @o_banco             cuenta       = null output,
   @o_msg_msv           varchar(255) = null output
      
as
declare
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_msg               mensaje,
   @w_anterior          cuenta ,
   @w_migrada           cuenta,
   @w_tramite           int,
   @w_cliente           int,
   @w_nombre            descripcion,
   @w_sector            catalogo,
   @w_toperacion        catalogo,
   @w_oficina           smallint,
   @w_moneda            tinyint,
   @w_comentario        varchar(255),
   @w_oficial           smallint,
   @w_fecha_ini         datetime,
   @w_fecha_f           varchar(10),
   @w_fecha_fin         datetime,
   @w_fecha_ult_proceso datetime,
   @w_fecha_liq         datetime,
   @w_fecha_reajuste    datetime,
   @w_monto             money,
   @w_monto_aprobado    money,
   @w_destino           catalogo,
   @w_lin_credito       cuenta,
   @w_ciudad            smallint,
   @w_estado            tinyint,
   @w_periodo_reajuste  smallint,
   @w_reajuste_especial char(1),
   @w_tipo              char(1),
   @w_forma_pago        catalogo,
   @w_cuenta            cuenta,
   @w_dias_anio         smallint,
   @w_tipo_amortizacion varchar(30),
   @w_cuota_completa    char(1),
   @w_tipo_cobro        char(1),
   @w_tipo_reduccion    char(1),
   @w_aceptar_anticipos char(1),
   @w_precancelacion    char(1),
   @w_num_dec           tinyint,
   @w_tplazo            catalogo,
   @w_plazo             smallint,
   @w_tdividendo        catalogo,
   @w_periodo_cap       smallint,
   @w_periodo_int       smallint,
   @w_gracia_cap        smallint,
   @w_gracia_int        smallint,
   @w_dist_gracia       char(1),
   @w_fecha_fija        char(1),
   @w_dia_pago          tinyint,
   @w_cuota_fija        char(1),
   @w_evitar_feriados   char(1),
   @w_tipo_producto     char(1),
   @w_renovacion        char(1),
   @w_mes_gracia        tinyint,
   @w_tipo_aplicacion   char(1),
   @w_reajustable       char(1),
   @w_est_novigente     tinyint,
   @w_est_credito       tinyint,
   @w_dias_dividendo    int,
   @w_dias_aplicar      int,
   @w_operacionca       int,
   @w_banco             cuenta,
   @w_sal_min_cla_car   int,
   @w_sal_min_vig       money,
   @w_base_calculo      char(1),
   @w_ult_dia_habil     char(1),
   @w_recalcular        char(1),
   @w_prd_cobis         tinyint,
   @w_tipo_redondeo     tinyint,
   @w_causacion         char(1),
   @w_convierte_tasa    char(1),
   @w_tasa_equivalente  char(1),
   @w_tipo_linea        catalogo,
   @w_subtipo_linea     catalogo,
   @w_bvirtual          char(1),
   @w_extracto          char(1),
   @w_reestructuracion  char(1),
   @w_subtipo           char(1),
   @w_naturaleza        char(1),
   @w_pago_caja         char(1),
   @w_nace_vencida      char(1),
   @w_valor_rubro       money,
   @w_calcula_devolucion char(1),
   @w_concepto_interes  catalogo,
   @w_est_cancelado     tinyint,
   @w_clase_cartera     catalogo,
   @w_dias_gracia       smallint,
   @w_tasa_referencial  catalogo,
   @w_porcentaje        float,
   @w_modalidad         char(1),
   @w_periodicidad      char(1),
   @w_tasa_aplicar      catalogo,
   @w_entidad_convenio  catalogo,
   @w_mora_retroactiva  char(1),
   @w_prepago_desde_lavigente  char(1),
   @w_rowcount          int,
   @w_control_dia_pago  char(1),
   @w_pa_dimive         tinyint,
   @w_pa_dimave         tinyint,
   @w_tr_tipo           char(1),
   @w_monto_seguros     money,                      -- Req. 366 Seguros
-- LGU-INI 12/ABR/2017 CONTROL DE DIAS DE LA PRIMERA CUOTA - INTERCICLO
   @w_fecha_pri_cuot    datetime,
   @w_operacionca_grp   int,
-- LGU-FIN 12/ABR/2017 CONTROL DE DIAS DE LA PRIMERA CUOTA - INTERCICLO
   @w_fondos_propios    char(1),
   @w_origen_fondos     catalogo,   
   @w_ciclo                int,
   @w_saldo_vencido        money,
   @w_ahorro_ini           money,
   @w_ahorro_ini_int       money,
   @w_ahorro_voluntario    money,
   @w_incentivos           money,
   @w_extras               money,
   @w_devoluciones         money,
   @w_ciclo_det            int,
   @w_admin_individual     char(1),
   @w_dias_cuota           smallint,  --LPO CDIG. Ajustes creacion operacion
   @w_dias_di              smallint

/* CARGAR VALORES INICIALES */
select
@w_sp_name       = 'sp_crear_operacion_int',
@w_est_novigente = 0,
@w_est_credito   = 99,
@w_valor_rubro   = 0,
@w_est_cancelado = 3,
@w_dias_aplicar  = 0

/* CONTROLAR DIA MINIMO DEL MES PARA FECHAS DE VENCIMIENTO */
select @w_pa_dimive = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'DIMIVE'
and   pa_producto = 'CCA'


/* CONTROLAR DIA MAXIMO DEL MES PARA FECHAS DE VENCIMIENTO */
select @w_pa_dimave = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'DIMAVE'
and   pa_producto = 'CCA'

select @w_concepto_interes = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'

/*Si el tipo de plazo es Anual, se cambia a Mensual, para colocar como entero el plazo
recalculado en procesos como reestructuras, abonos extraordinarios u otros, si solo se llama 
al programa interno se coloca aqui tambien este control*/

if @i_tplazo = 'A' and isnull(@i_tdividendo,'M') = 'M'
begin
   select @i_plazo = @i_plazo *(a.td_factor/b.td_factor)
   from ca_tdividendo a, ca_tdividendo b
   where a.td_tdividendo = @i_tplazo
   and   b.td_tdividendo = 'M'

   select @i_tplazo = 'M'
end

--INI AGI.  Creaci?n Operaciones Grupales
if @i_es_grupal = 'S'
begin
    --Validar que el grupo exista
    if not exists (select 1 from cobis..cl_grupo where gr_grupo = @i_grupo )
    begin
        select @o_msg_msv = 'Grupo ' + cast(@i_grupo as varchar) + ' no existe. '
        return 101198
    end
 --LRE 04/JUL/2019 Para operaciones de interciclo no aplica esta validacion
  if not exists (select 1 from cob_cartera..ca_operacion where op_grupo = @i_grupo and op_estado <> 3 and op_grupal = 'S') 
  begin
    --Validar que el cliente es el representante del grupo
    if not exists (select 1 from cobis..cl_grupo where gr_grupo = @i_grupo and gr_representante = @i_cliente)
    begin
        select @o_msg_msv = 'Cliente  ' + cast(@i_cliente as varchar) + ' no es representante del grupo ' + cast(@i_grupo as varchar)
        return 101089
    end
  end
end
--FIN AGI.

-- REQ. 366 GENERA MONTO BASE DE LA OPERACION   --PQU quitar esta parte de seguros
--LPO TEC Entonces se comenata este c?digo, se asigna select @w_monto_seguros = 0
select @w_monto_seguros = 0
/*
-- Validacion Seguros asociados

if exists (select 1 from cob_credito..cr_seguros_tramite
           where st_tramite = @i_tramite)

begin

   select @w_monto_seguros = 0
   select @w_monto_seguros = isnull(sum(sed_cuota_cap - sed_pago_cap),0)
   from ca_seguros_det, ca_seguros
   where sed_sec_seguro = se_sec_seguro
   and se_tramite = @i_tramite

   select @i_monto = @i_monto - @w_monto_seguros

end  -- Fin Generar monto base de la operaci+?n Req 366
*/
--LPO TEC FIN Entonces se comenta este c?digo, se asigna select @w_monto_seguros = 0
--fin PQU 

/* DETERMINAR LOS VALORES POR DEFECTO PARA EL TIPO DE OPERACION */
--PQU validar que no se lean de la parametrizaci?n por defecto valores como dia de pago (que se saca de la fecha de vencimiento del primer dividendo), tasa, frecuencia pago, plazo que vienen de la interface
--LPO TEC Entonces extraemos el d?a de pago de la fecha de vencimiento de la primera cuota s?lo si @i_grupal = 'S'
if @i_es_revolvente = 'N'  --LPO CDIG. Ajustes creacion operacion INICIO
begin
select
@w_periodo_reajuste          = dt_periodo_reaj,
@w_reajuste_especial         = dt_reajuste_especial,
@w_precancelacion            = dt_precancelacion,
@w_tipo                      = dt_tipo,
@w_cuota_completa            = dt_cuota_completa,
@w_tipo_reduccion            = dt_tipo_reduccion,
@w_aceptar_anticipos         = dt_aceptar_anticipos,
--xma @w_tipo_reduccion     = dt_tipo_reduccion,
@w_tplazo                    = dt_tplazo,
@w_plazo                     = dt_plazo,
@w_tdividendo                = dt_tdividendo,
@w_periodo_cap               = isnull(@i_periodo_cap, dt_periodo_cap),
@w_periodo_int               = isnull(@i_periodo_int, dt_periodo_int),
@w_gracia_cap                = dt_gracia_cap,
@w_gracia_int                = dt_gracia_int,
@w_dist_gracia               = dt_dist_gracia,
@w_dias_anio                 = dt_dias_anio,
@w_tipo_amortizacion         = dt_tipo_amortizacion,
@w_fecha_fija                = isnull(@i_fecha_fija, dt_fecha_fija),
@w_dia_pago                  = isnull(@i_dia_pago, dt_dia_pago),
@w_cuota_fija                = dt_cuota_fija,
@w_evitar_feriados           = dt_evitar_feriados,
@w_renovacion                = dt_renovacion,
@w_mes_gracia                = dt_mes_gracia,
@w_tipo_aplicacion           = dt_tipo_aplicacion,
@w_tipo_cobro                = dt_tipo_cobro,
@w_reajustable               = dt_reajustable,
@w_base_calculo              = dt_base_calculo,
@w_ult_dia_habil             = dt_dia_habil,
@w_recalcular                = dt_recalcular_plazo,
@w_prd_cobis                 = dt_prd_cobis,
@w_tipo_redondeo             = dt_tipo_redondeo,
@w_causacion                 = dt_causacion,
@w_convierte_tasa            = isnull(dt_convertir_tasa, 'S'),
@w_tipo_linea                = dt_tipo_linea,
@w_subtipo_linea             = dt_subtipo_linea,
@w_bvirtual                  = dt_bvirtual,
@w_extracto                  = dt_extracto,
@w_naturaleza                = dt_naturaleza,
@w_pago_caja                 = dt_pago_caja,
@w_nace_vencida              = dt_nace_vencida,
@w_calcula_devolucion        = dt_calcula_devolucion,
@w_dias_gracia               = dt_dias_gracia,
@w_entidad_convenio          = dt_entidad_convenio,
@w_mora_retroactiva          = dt_mora_retroactiva,
@w_prepago_desde_lavigente   = isnull(dt_prepago_desde_lavigente,'N'),
@w_control_dia_pago          = dt_control_dia_pago,
@w_sector                    = isnull(@i_sector, dt_clase_sector),  --PQU 16/08/2021 Finca puede enviar sectores diferentes
@w_clase_cartera             = isnull(@i_clase_cartera,dt_clase_cartera), --PQU 16/08/2021 Finca puede enviar sectores diferentes
@w_origen_fondos             = dt_categoria,
@w_admin_individual          = dt_admin_individual
from ca_default_toperacion
where dt_toperacion = @i_toperacion
and   dt_moneda     = @i_moneda

if @@rowcount = 0 return 710072
end
else -- ES PRESTAMO DE LINEA REVOLVENTE  --LPO CDIG. Ajustes creacion operacion
begin
   select
   @w_periodo_reajuste        = op_periodo_reajuste,
   @w_reajuste_especial       = op_reajuste_especial,
   @w_precancelacion          = op_precancelacion,
   @w_tipo                    = op_tipo,
   @w_cuota_completa          = op_cuota_completa,
   @w_tipo_reduccion          = op_tipo_reduccion,
   @w_aceptar_anticipos       = op_aceptar_anticipos,
   @w_tplazo                  = op_tplazo,
   --@w_plazo                   = dt_plazo,
   @w_tdividendo              = op_tdividendo,
   @w_periodo_cap             = op_periodo_cap,
   @w_periodo_int             = op_periodo_int,
   @w_gracia_cap              = op_gracia_cap,
   @w_gracia_int              = op_gracia_int,
   @w_dist_gracia             = op_dist_gracia,
   @w_dias_anio               = op_dias_anio,
   @w_tipo_amortizacion       = op_tipo_amortizacion, --FRANCESA
   @w_dia_pago                = op_dia_fijo,
   @w_evitar_feriados         = op_evitar_feriados,
   @w_renovacion              = op_renovacion,
   @w_mes_gracia              = op_mes_gracia,
   @w_tipo_aplicacion         = op_tipo_aplicacion,
   @w_tipo_cobro              = op_tipo_cobro,
   @w_reajustable             = op_reajustable,
   @w_base_calculo            = op_base_calculo,
   @w_ult_dia_habil           = op_dia_habil,
   @w_recalcular              = op_recalcular_plazo,
   @w_prd_cobis               = op_prd_cobis,
   @w_tipo_redondeo           = op_tipo_redondeo,
   @w_causacion               = op_causacion,
   @w_convierte_tasa          = op_convierte_tasa,
   @w_tipo_linea              = op_tipo_linea,
   @w_subtipo_linea           = op_subtipo_linea,
   @w_bvirtual                = op_bvirtual,
   @w_extracto                = op_extracto,
   @w_naturaleza              = op_naturaleza,
   @w_pago_caja               = op_pago_caja,
   @w_nace_vencida            = op_nace_vencida,
   @w_calcula_devolucion      = op_calcula_devolucion,
   @w_entidad_convenio        = op_entidad_convenio,
   @w_mora_retroactiva        = op_mora_retroactiva,
   @w_prepago_desde_lavigente = op_prepago_desde_lavigente,
   @i_lin_credito             = op_lin_credito,
   @i_forma_pago              = op_forma_pago,
   @w_dias_aplicar            = op_dias_clausula,
   @i_periodo_crecimiento     = op_periodo_crecimiento,
   @i_tasa_crecimiento        = op_tasa_crecimiento,
   @i_clase_cartera           = op_clase,
   @i_origen_fondos           = op_origen_fondos,
   @i_tipo_empresa            = op_tipo_empresa,
   @i_validacion              = op_validacion,
   @i_fondos_propios          = op_fondos_propios,
   @i_ref_exterior            = op_ref_exterior,
   @i_sujeta_nego             = op_sujeta_nego,
   @i_ref_red                 = op_nro_red,
   @i_reestructuracion        = op_reestructuracion,
   @i_subtipo                 = op_tipo_cambio,
   @i_num_deuda_ext           = op_num_deuda_ext,
   @i_num_comex               = op_num_comex,
   @i_oper_pas_ext            = op_codigo_externo,
   @i_numero_reest            = op_numero_reest,
   @i_banca                   = op_banca,
   @w_tasa_equivalente        = op_usar_tequivalente,
   @i_toperacion              = op_toperacion,
   @i_moneda                  = op_moneda,
   @i_oficina                 = op_oficina,
   @w_sector                  = op_sector,
   @i_oficial                 = op_oficial,
   @i_destino                 = op_destino,
   @i_ciudad                  = op_ciudad,
   @i_monto_aprobado          = op_monto_aprobado
   from ca_operacion
   where op_banco = @i_ref_revolvente
   
   if @@rowcount = 0 return 710072   
end		--LPO CDIG. Ajustes creacion operacion FIN



select
@w_tplazo           = isnull(@i_tplazo, @w_tplazo),
@w_plazo            = isnull(@i_plazo,  @w_plazo),
@w_tasa_equivalente = isnull(@i_tasa_equivalente, 'N'),
@w_tdividendo       = isnull(@i_tdividendo, @w_tdividendo),
@i_sector           = @w_sector,
@i_clase_cartera    = isnull(@i_clase_cartera,@w_sector),
@i_fondos_propios   = isnull(@i_fondos_propios,'N'),
@i_origen_fondos    = isnull(@i_origen_fondos,@w_origen_fondos)--,
--PQU integración @w_admin_individual = 'N'   --LRE 28Ago19 S276526 

-- KDR 03/03/2021 Si los tipos de dividendos son especiales, no debe tener valores de control día pago(N), fecha fija (N) y dia de pago(0).
if @w_tdividendo in ('W','28D','35D','Q','14D')
begin
   -- KDR El valor de la columna para Control día Pago viene por defectoEN 'S' desde APF, por lo cual no se la considera para la validación
   if /*@w_control_dia_pago = 'S' or*/ @w_fecha_fija = 'S' or @w_dia_pago > 0
   begin
      select @w_error = 725141  -- Tipo dividendo no admite fecha fija, día pago fijo, ni control dia de pago, revisar parametrización o condiciones de amortización
      return @w_error
   end
end

/* VERIFICAR QUE EXISTAN LOS RUBROS NECESARIOS */
if not exists (select 1 from ca_rubro
where  ru_toperacion = @i_toperacion
and    ru_moneda     = @i_moneda
and    ru_tipo_rubro = 'C'
and    ru_crear_siempre = 'S'
and    ru_estado     = 'V')
begin
   --GFP se suprime print
   /*
   if @i_crea_ext is null
      PRINT 'creaopin.sp entro a este error @i_toperacion ' + cast(@i_toperacion as varchar) + ', @i_moneda ' + cast(@i_moneda as varchar)
   else
   */
      select @o_msg_msv = 'creaopin.sp entro a este error @i_toperacion ' + cast(@i_toperacion as varchar) + ', @i_moneda ' + cast(@i_moneda as varchar)
   return 710016
end

select @w_dias_cuota = td_factor
from cob_cartera..ca_tdividendo
where td_tdividendo = @w_tdividendo

/* -- KDR Se comenta Dia de pago fijo para dividendos especiales no aplica en Finca
--LPO TEC se extrae dia de pago de la fecha de vencimiento de la primera cuota s?lo si @i_grupal = 'S'
IF (@i_grupal = 'S' AND @w_tdividendo = 'W') 
BEGIN
--   SELECT @w_dia_pago = datepart(dd,@i_fecha_ven_pc) --LPO TEC se extrae dia de pago de la fecha de vencimiento de la primera cuota   
   SELECT @w_dia_pago = datepart(dw,@i_fecha_ven_pc)
END
*/


/* SE REALIZA LA ASIGNACION DE CLASE DE CARTERA */
IF @i_clase_cartera IS NULL --LPO CDIG. Ajustes creacion operacion
   SELECT @i_clase_cartera = 4 --LPO CDIG. Ajustes creacion operacion
   
if @i_clase_cartera is null begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         print 'Clase Cartera en blanco o Clase de Cupo es Null'
      else
	  */
         select @o_msg_msv = 'Clase Cartera en blanco o Clase de Cupo es Null'
      return 701065

end


if @i_tramite is null
   select @w_estado = @w_est_novigente
else
   select @w_estado = @w_est_credito

--AGI. Si la creaci?n es una operacion hija el estado es de acuerdo a la administraci?n del Grupal
if @w_admin_individual = 'N'  --  Hijas estado 99 - TR-MITE  Padre con estado 0 - NO VIGENTE
begin
    if @i_es_grupal = 'S'
       select @w_estado = @w_est_novigente
       
    if exists (select 1 from ca_operacion_tmp where opt_banco = @i_ref_grupal)   
        select @w_estado = @w_est_credito
end
ELSE  --PQU integracion
begin
    if @i_grupal = 'S'
       select @w_estado = @w_est_credito
END        --fin PQU
--FIN AGI    
    
/*OBTENCION DE LOS DIAS DE MI DIVIDENDO PARA DIAS CLAUSULA*/
select @w_dias_dividendo = td_factor
from ca_tdividendo
where td_tdividendo = @w_tdividendo

if @i_no_banco = 'S'
begin
   exec @w_operacionca = sp_gen_sec
   @i_operacion   = -1

   select @w_banco = convert(varchar(20),@w_operacionca)
end
else
begin
   exec @w_return = sp_numero_oper
   @s_date        = @s_date,
   @i_oficina     = @i_oficina,
   @i_tramite     = @i_tramite,
   @o_operacion   = @w_operacionca out,
   @o_num_banco   = @w_banco       out

   if @w_return <> 0 return @w_return
end

/* ACTUALIZAR EL NUMERO DE OPERACION EN LA TABLA TEMPORAL DE CLIENTES */
update ca_cliente_tmp
set clt_operacion = cast(@w_operacionca as varchar)
where clt_user    = @s_user
and   clt_sesion  = @s_sesn

if @@error <> 0 return 710002


/* REGISTRAR LOS CLIENTES INGRESADOS PARA SEGUROS DE VIDA Y COBRO DE COMISION POR CONSULTAS A LA CENTRAL DE RIESGOS */
insert into ca_deu_segvida
select clt_operacion, clt_cliente, clt_rol,
    case clt_rol when 'D' then 'S' else 'N' end,
clt_central_riesgo
from ca_cliente_tmp
where clt_user   = @s_user
and   clt_sesion = @s_sesn

if @@error <> 0 return 710001

select @w_error = 0


select @w_tr_tipo = isnull(tr_tipo,'X')
from cob_credito..cr_tramite
where tr_tramite = @i_tramite

if @@rowcount  = 0
   select @w_tr_tipo = 'X'


/*CONTROL PLAZO LINEA*/

/*
if isnull(@w_tr_tipo,'0') not in ('E','M') and isnull(@i_simulacion,'0') <>  'S' and @i_tipo_tramite <> 'M'
begin
   exec @w_return    = sp_parametros_matriz
   @i_fecha          = @i_fecha_ini,
   @i_toperacion     = @i_toperacion,
   @i_plazo          = @w_plazo,
   @i_tplazo         = @w_tplazo,
   @i_monto_valida   = @i_monto,
   @i_cliente        = @i_cliente,
   @o_msg            = @w_msg   out

   if @w_return <> 0 begin
      if @i_crea_ext is null
         print @w_msg
      else
         select @o_msg_msv = @w_msg
      return @w_return
   end
end
*/


   /* NUEVA RUTINA PARA EL CONTROL DE DIA DE PAGO */
if @w_dia_pago is not null and @w_fecha_fija = 'S' and @i_grupal = 'N'
begin
   select @w_control_dia_pago = 'S'
   if @i_fecha_ven_pc is not null and @w_dias_cuota >= 30 --LPO CDIG. Ajustes creacion operacion
      select @w_dia_pago = datepart(dd, @i_fecha_ven_pc)  --LPO CDIG. Ajustes creacion operacion
   -- else                                                   --LPO CDIG. Ajustes creacion operacion
   --select @w_dia_pago = @i_dia_pago
end
--LPO CDIG. Ajustes creacion operacion INICIO
if @i_fecha_ven_pc is not null and @w_fecha_fija = 'S' and @w_dias_cuota >= 30
begin
   select @w_control_dia_pago = 'S'
   select @w_dia_pago = datepart(dd,@i_fecha_ven_pc)
end
--LPO CDIG. Ajustes creacion operacion FIN

--GFP se valida que los tipos de dividendos menores a 30 dias y tengan un dia de pago fijo no se pueda generar el prestamo
select @w_dias_di = @w_periodo_int*td_factor
from ca_tdividendo
where td_tdividendo = @w_tdividendo

if (@w_dias_di % 30 <> 0 ) and  @w_dia_pago  <> 0
begin
	return 711100
end

if @w_control_dia_pago = 'S' and @w_tipo <> 'C' and @w_tipo <> 'R' --LRE 02/Abr/2019 and @i_crea_ext = 'S'
begin

   if @w_dia_pago < @w_pa_dimive or @w_dia_pago > @w_pa_dimave
   begin
       /*OBTIENE NUEVO DIA DE PAGO*/
      select @w_dia_pago = datepart(dd, @i_fecha_ini)
      select @w_dia_pago = valor
      from cobis..cl_catalogo
      where tabla = (select codigo from cobis..cl_tabla
                     where tabla = 'ca_dias_vencimiento')
      and  codigo = convert(char(10),@w_dia_pago)
   end
end


---Inc. 00129
if @w_tipo = 'C' or @w_tipo = 'R'
begin
   select @w_dia_pago = datepart(dd, @i_fecha_ini)
end

--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- LGU-INI: controlar que se creen los interciclos con la parametrizacion del padre
if (@i_es_interciclo  = 'S'	and @i_ref_grupal is not NULL)	  --LRE 10/Jul/2019
begin
    
    select
      @w_periodo_reajuste        = op_periodo_reajuste,
      @w_reajuste_especial       = op_reajuste_especial,
      @w_precancelacion          = op_precancelacion,
      @w_tipo                    = op_tipo,
      @w_cuota_completa          = op_cuota_completa,
      @w_tipo_reduccion          = op_tipo_reduccion,
      @w_aceptar_anticipos       = op_aceptar_anticipos,
      @w_tdividendo              = op_tdividendo,
      @w_periodo_cap             = op_periodo_cap,
      @w_periodo_int             = op_periodo_int,
      @w_gracia_cap              = op_gracia_cap,
      @w_gracia_int              = op_gracia_int,
      @w_dist_gracia             = op_dist_gracia,
      @w_dias_anio               = op_dias_anio,
      @w_tipo_amortizacion       = op_tipo_amortizacion,
      @w_dia_pago                = op_dia_fijo,
      @w_evitar_feriados         = op_evitar_feriados,
      @w_renovacion              = op_renovacion,
      @w_mes_gracia              = op_mes_gracia,
      @w_tipo_aplicacion         = op_tipo_aplicacion,
      @w_tipo_cobro              = op_tipo_cobro,
      @w_reajustable             = op_reajustable,
      @w_base_calculo            = op_base_calculo,
      @w_ult_dia_habil           = op_dia_habil,
      @w_recalcular              = op_recalcular_plazo,
      @w_prd_cobis               = op_prd_cobis,
      @w_tipo_redondeo           = op_tipo_redondeo,
      @w_causacion               = op_causacion,
      @w_convierte_tasa          = op_convierte_tasa,
      @w_tipo_linea              = op_tipo_linea,
      @w_subtipo_linea           = op_subtipo_linea,
      @w_bvirtual                = op_bvirtual,
      @w_extracto                = op_extracto,
      @w_naturaleza              = op_naturaleza,
      @w_pago_caja               = op_pago_caja,
      @w_nace_vencida            = op_nace_vencida,
      @w_calcula_devolucion      = op_calcula_devolucion,
      @w_entidad_convenio        = op_entidad_convenio,
      @w_mora_retroactiva        = op_mora_retroactiva,
      @w_prepago_desde_lavigente = op_prepago_desde_lavigente,

      @i_lin_credito             = op_lin_credito,
      @i_forma_pago              = op_forma_pago,
      @w_dias_aplicar            = op_dias_clausula,
      @i_periodo_crecimiento     = op_periodo_crecimiento,
      @i_tasa_crecimiento        = op_tasa_crecimiento,
      @i_clase_cartera           = op_clase,
      @i_origen_fondos           = op_origen_fondos,
      @i_tipo_empresa            = op_tipo_empresa,
      @i_validacion              = op_validacion,
      @i_fondos_propios          = op_fondos_propios,
      @i_ref_exterior            = op_ref_exterior,
      @i_sujeta_nego             = op_sujeta_nego,
      @i_ref_red                 = op_nro_red,
      @i_reestructuracion        = op_reestructuracion,
      @i_subtipo                 = op_tipo_cambio,
      @i_num_deuda_ext           = op_num_deuda_ext,
      @i_num_comex               = op_num_comex,
      @i_oper_pas_ext            = op_codigo_externo,
      @i_numero_reest            = op_numero_reest,
      @i_banca                   = op_banca,
      @w_tasa_equivalente        = op_usar_tequivalente,
	  @i_grupal                  = 'S' 
      --@i_ref_grupal              = op_banco      
   from ca_operacion
   where op_banco = @i_ref_grupal
   
   if @@rowcount = 0 return 710072
   select @w_dias_gracia = max(di_gracia_disp)
   from ca_dividendo
   where di_operacion = @w_operacionca_grp

   select @w_dias_gracia = isnull(@w_dias_gracia, 0)

    select @i_tasa = ro_porcentaje       
    from ca_rubro_op
    where ro_operacion = @w_operacionca_grp
    and   ro_concepto = 'INT'
    
    --INI AGI    Incluirla en el InterCiclo
    set rowcount 1
    
     insert into ca_det_ciclo(
      dc_grupo,        dc_ciclo_grupo,         dc_cliente,
      dc_operacion,    dc_referencia_grupal,
      dc_ciclo,        dc_tciclo,              dc_saldo_vencido,
      dc_ahorro_ini,   dc_ahorro_ini_int,      dc_ahorro_voluntario,
      dc_incentivos,   dc_extras,              dc_devoluciones)
    select
      dc_grupo,        dc_ciclo_grupo,         @i_cliente,
      @w_operacionca,  @i_ref_grupal, 
      dc_ciclo,        'I',                    @w_saldo_vencido,
      @w_ahorro_ini,   @w_ahorro_ini_int,      @w_ahorro_voluntario,
      @w_incentivos,   @w_extras,              @w_devoluciones
    from ca_det_ciclo
    where dc_referencia_grupal  = @i_ref_grupal
    

    if @@error <> 0
        return 70011005
    
    set rowcount 0
    
    --FIN AGI.
end
-- LGU-INI: controlar que se creen los interciclos con la parametrizacion del padre
-- LGU-fin 10/abr/2017 calcular plazo y fecha de una interciclo
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


--LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones INICIO
IF @i_gracia_cap IS NOT NULL
   SELECT @w_gracia_cap = @i_gracia_cap 
IF @i_gracia_int IS NOT NULL
   SELECT @w_gracia_int = @i_gracia_int
IF @i_dist_gracia IS NOT NULL
   SELECT @w_dist_gracia = @i_dist_gracia
   
   
--LPO CDIG Multimoneda Nuevos campos en pantalla de Renovaciones FIN


--LPO CDIG APIS II	 
IF @i_periodo_reajuste IS NULL
   SELECT @i_periodo_reajuste = @w_periodo_reajuste

IF @i_reajuste_especial IS NULL 
   SELECT @i_reajuste_especial = @w_reajuste_especial 

IF @i_tipo IS NULL
   SELECT @i_tipo = @w_tipo
   
IF @i_tipo IS NULL
   SELECT @i_tipo = 'O'

IF @i_dias_anio IS NULL
   SELECT @i_dias_anio = @w_dias_anio

IF @i_tipo_amortizacion IS NULL
   SELECT @i_tipo_amortizacion = @w_tipo_amortizacion

IF @i_cuota_completa IS NULL
   SELECT @i_cuota_completa = @w_cuota_completa

IF @i_tipo_cobro IS NULL
   SELECT @i_tipo_cobro = @w_tipo_cobro

IF @i_aceptar_anticipos IS NULL
   SELECT @i_aceptar_anticipos = @w_aceptar_anticipos
   
IF @i_precancelacion IS NULL
   SELECT @i_precancelacion = @w_precancelacion

IF @i_tipo_aplicacion IS NULL
   SELECT @i_tipo_aplicacion = @w_tipo_aplicacion

IF @i_tplazo IS NULL
   SELECT @i_tplazo = @w_tplazo
   
IF @i_plazo IS NULL
   SELECT @i_plazo = @w_plazo
   
IF @i_tdividendo IS NULL
   SELECT @i_tdividendo = @w_tdividendo

IF @i_periodo_cap IS NULL
   SELECT @i_periodo_cap = @w_periodo_cap
   
IF @i_periodo_int IS NULL
   SELECT @i_periodo_int = @w_periodo_int
   
IF @i_dist_gracia IS NULL
   SELECT @i_dist_gracia = @w_dist_gracia   

IF @i_gracia_cap IS NULL
   SELECT @i_gracia_cap = @w_gracia_cap
   
IF @i_gracia_int IS NULL
   SELECT @i_gracia_int = @w_gracia_int
   
IF @i_dia_pago IS NULL
   SELECT @i_dia_pago = @w_dia_pago

IF @i_evitar_feriados IS NULL
   SELECT @i_evitar_feriados = @w_evitar_feriados

IF @i_renovacion IS NULL
   SELECT @i_renovacion = @w_renovacion

IF @i_mes_gracia IS NULL
   SELECT @i_mes_gracia = @w_mes_gracia

IF @i_reajustable IS NULL
   SELECT @i_reajustable = @w_reajustable

IF @i_base_calculo IS NULL
   SELECT @i_base_calculo = @w_base_calculo
   
IF @i_causacion IS NULL
   SELECT @i_causacion = @w_causacion

IF @i_convierte_tasa IS NULL
   SELECT @i_convierte_tasa = @w_convierte_tasa
   
IF @i_tasa_equivalente IS NULL
   SELECT @i_tasa_equivalente = @w_tasa_equivalente
   
IF @i_nace_vencida IS NULL
   SELECT @i_nace_vencida = @w_nace_vencida

IF @i_tipo_reduccion IS NULL
   SELECT @i_tipo_reduccion = @w_tipo_reduccion

SELECT 	@w_admin_individual = dt_admin_individual -- AFL-19APR2021
FROM 	ca_default_toperacion
WHERE 	dt_toperacion = @i_toperacion
AND   	dt_moneda     = @i_moneda
												 
						   
									
								

/* CREAR LA OPERACION TEMPORAL */
exec @w_return                  = sp_operacion_tmp
     @s_user                    = @s_user,
     @s_sesn                    = @s_sesn,
     @s_ofi                     = @s_ofi,
     @s_date                    = @s_date,
     @s_ssn                     = @s_ssn,
     @s_term                    = @s_term,
     @s_srv                     = @s_srv,
     @i_operacion               = 'I',
     @i_operacionca             = @w_operacionca,
     @i_banco                   = @w_banco,
     @i_anterior                = @i_anterior,
     @i_migrada                 = @i_migrada,
     @i_tramite                 = @i_tramite,
     @i_cliente                 = @i_cliente,
     @i_nombre                  = @i_nombre,
     @i_sector                  = @i_sector,
     @i_toperacion              = @i_toperacion,
     @i_oficina                 = @i_oficina,
     @i_moneda                  = @i_moneda,
     @i_comentario              = @i_comentario,
     @i_oficial                 = @i_oficial,
     @i_fecha_ini               = @i_fecha_ini,
     @i_fecha_fin               = @i_fecha_ini,
     @i_fecha_ult_proceso       = @i_fecha_ini,
     @i_fecha_liq               = @i_fecha_ini,
     @i_fecha_reajuste          = @i_fecha_ini,
     @i_monto                   = @i_monto,
     @i_monto_aprobado          = @i_monto_aprobado,
     @i_destino                 = @i_destino,
     @i_lin_credito             = @i_lin_credito,
     @i_ciudad                  = @i_ciudad,
     @i_estado                  = @w_estado,
     @i_periodo_reajuste        = @i_periodo_reajuste,  --@w_periodo_reajuste,
     @i_reajuste_especial       = @i_reajuste_especial, --@w_reajuste_especial,
     @i_tipo                    = @i_tipo, --@w_tipo, --(Hipot/Redes/Normal)
     @i_forma_pago              = @i_forma_pago,
     @i_cuenta                  = @i_cuenta,
     @i_dias_anio               = @i_dias_anio, --@w_dias_anio,
     @i_tipo_amortizacion       = @i_tipo_amortizacion, --@w_tipo_amortizacion,
     @i_cuota_completa          = @i_cuota_completa, --@w_cuota_completa,
     @i_tipo_cobro              = @i_tipo_cobro, --@w_tipo_cobro,
     @i_tipo_reduccion          = @i_tipo_reduccion, --@w_tipo_reduccion,
     @i_aceptar_anticipos       = @i_aceptar_anticipos, --@w_aceptar_anticipos,
     @i_precancelacion          = @i_precancelacion, --@w_precancelacion,
     @i_tipo_aplicacion         = @i_tipo_aplicacion, --@w_tipo_aplicacion,
     @i_tplazo                  = @i_tplazo, --@w_tplazo,
     @i_plazo                   = @i_plazo, --@w_plazo,
     @i_tdividendo              = @i_tdividendo, --@w_tdividendo,
     @i_periodo_cap             = @i_periodo_cap, --@w_periodo_cap,
     @i_periodo_int             = @i_periodo_int, --@w_periodo_int,
     @i_dist_gracia             = @i_dist_gracia, --@w_dist_gracia,
     @i_gracia_cap              = @i_gracia_cap, --@w_gracia_cap,
     @i_gracia_int              = @i_gracia_int, --@w_gracia_int,
     @i_dia_fijo                = @i_dia_pago, --@w_dia_pago,
     @i_cuota                   = 0,
     @i_evitar_feriados         = @i_evitar_feriados, --@w_evitar_feriados,
     @i_renovacion              = @i_renovacion, --@w_renovacion,
     @i_mes_gracia              = @i_mes_gracia, --@w_mes_gracia,
     @i_reajustable             = @i_reajustable, --@w_reajustable,
     @i_dias_clausula           = @w_dias_aplicar,
     @i_periodo_crecimiento     = @i_periodo_crecimiento,
     @i_tasa_crecimiento        = @i_tasa_crecimiento,
     @i_direccion               = @i_direccion,
     @i_clase_cartera           = @i_clase_cartera,
     @i_origen_fondos           = @i_origen_fondos ,
     @i_base_calculo            = @i_base_calculo, --@w_base_calculo ,
     @i_ult_dia_habil           = @w_ult_dia_habil ,
     @i_recalcular              = @w_recalcular, 
     @i_tipo_empresa            = @i_tipo_empresa,
     @i_validacion              = @i_validacion, 
     @i_fondos_propios          = @i_fondos_propios,
     @i_ref_exterior            = @i_ref_exterior, 
     @i_sujeta_nego             = @i_sujeta_nego, 
     @i_prd_cobis               = @w_prd_cobis, 
     @i_ref_red                 = @i_ref_red, 
     @i_tipo_redondeo           = @w_tipo_redondeo, 
     @i_causacion               = @i_causacion,  --@w_causacion,
     @i_convierte_tasa          = @i_convierte_tasa, --@w_convierte_tasa,
     @i_tasa_equivalente        = @i_tasa_equivalente, --@w_tasa_equivalente,
     @i_tipo_linea              = @w_tipo_linea, 
     @i_subtipo_linea           = @w_subtipo_linea, 
     @i_bvirtual                = @w_bvirtual, 
     @i_extracto                = @w_extracto, 
     @i_reestructuracion        = @i_reestructuracion, 
     @i_subtipo                 = @i_subtipo, 
     @i_naturaleza              = @w_naturaleza, 
     @i_fec_embarque            = @i_fec_embarque, 
     @i_fec_dex                 = @i_fec_dex, 
     @i_num_deuda_ext           = @i_num_deuda_ext, 
     @i_num_comex               = @i_num_comex, 
     @i_pago_caja               = @w_pago_caja, 
     @i_nace_vencida            = @i_nace_vencida, --@w_nace_vencida, --SI
     @i_calcula_devolucion      = @w_calcula_devolucion, 
     @i_oper_pas_ext            = @i_oper_pas_ext, 
     @i_num_reest               = @i_numero_reest, 
     @i_entidad_convenio        = @w_entidad_convenio, 
     @i_mora_retroactiva        = @w_mora_retroactiva, 
     @i_prepago_desde_lavigente = @w_prepago_desde_lavigente, 
     @i_tipo_crecimiento        = 'A',    --AUTOMATICA, NO DIGITAN VALORES DE CAPITAL FIJO, O CUOTA FIJA
     @i_banca                   = @i_banca,
     @i_grupal                  = @i_grupal,        --LRE 05/Ene/2017
     @i_promocion               = @i_promocion,     --LPO Santander
     @i_acepta_ren              = @i_acepta_ren,    --LPO Santander
     @i_no_acepta               = @i_no_acepta,     --LPO Santander
     @i_emprendimiento          = @i_emprendimiento,--LPO Santander
     @i_fecha_pri_cuot          = @i_fecha_ven_pc, --@w_fecha_pri_cuot, --LPO CDIG. Ajustes creacion operacion -- LGU 11/abr/2017 para controlar la fecha de primer vencimiento del Grupal-Emergente
     @i_grupo                   = @i_grupo,          --AGI TeCreemos
     @i_ref_grupal              = @i_ref_grupal,     --AGI TeCreemos
     @i_es_grupal               = @i_es_grupal,      --AGI TeCreemos
     @i_fondeador               = @i_fondeador,    --AGI TeCreemos     
   --PQU pasar el ahorro esperado
   --LPO TEC ahorro esperado no aplica
   --LPO TEC se pasan los dos campos nuevos de ca_operacion (op_admin_individual y op_estado_hijas)
     @i_admin_individual        = @w_admin_individual,  --LPO TEC
     @i_estado_hijas            = 'I', --Ingresado       --LPO TEC
     @i_tipo_acreedor       = @i_tipo_acreedor,
     @i_num_cont            = @i_num_cont,
     @i_numreg_bc           = @i_numreg_bc,
     @i_tipo_deuda          = @i_tipo_deuda,
     @i_fecha_aut           = @i_fecha_aut,
     @i_num_aut             = @i_num_aut,
     @i_num_facilidad       = @i_num_facilidad,
     @i_forma_reposicion    = @i_forma_reposicion,
     @i_causa_fin_sub       = @i_causa_fin_sub,
     @i_mercado_obj_fin     = @i_mercado_obj_fin,
     @i_tipo_renovacion     = @i_tipo_renovacion,
     @i_tipo_reest          = @i_tipo_reest,
	 @i_grupo_contable      = @i_grupo_contable  --GFP 06/Ene/2022
     
--end
   
if @w_return <> 0 return @w_return

/* CREAR LOS RUBROS TEMPORALES DE LA OPERACION */
--print 'Tasa GRUPAL: ' + cast(@i_tasa_grupal as varchar)
if @i_es_revolvente = 'N' or @i_salida = 'D' --LPO CDIG. Ajustes creacion operacion INICIO / Tmp Desembolso Parcial
begin

exec @w_return            = sp_gen_rubtmp
     @s_user              = @s_user,
     @s_date              = @s_date,
     @s_term              = @s_term,
     @s_ofi               = @s_ofi,
     @i_crear_pasiva      = @i_crear_pasiva,
     @i_toperacion_pasiva = @i_toperacion_pasiva,
     @i_operacion_activa  = @i_operacion_activa,
     @i_operacionca       = @w_operacionca ,
     @i_tramite_hijo      = @i_tramite_hijo,
     @i_tasa              = @i_tasa,  --JSA Santander
     --@i_es_revolvente     = 'S' --LPO CDIG. Ajustes creacion operacion
	 --PQU enviar la tasa de inter?s
	 --LPO TEC Entonces pasamos @i_tasa_grupal y adem?s @i_grupal para condicionar la asignaci?n de la tasa s?lo a las grupales, dentro del sp
     @i_tasa_grupal       = @i_tasa_grupal, --LPO TEC
     @i_grupal            = @i_grupal       --LPO TEC
if @w_return <> 0
begin
   if @i_crea_ext is null begin
      --GFP se suprime print
      --print 'Error al Ejecurar sp_gen_rubtmp'
      print @w_return
   end
   else
      select @o_msg_msv = 'Error al Ejecurar sp_gen_rubtmp'
   return @w_return
end
end --LPO CDIG. Ajustes creacion operacion FIN

/*ACTUALIZA SIGNO Y SPREAD OPERACIONES  QUE UTILIZAN LA MATRIZ DE TASA_MAX Y TASA_MIN */
if  (@i_signo is not null and @i_factor is not null) Begin
    update ca_rubro_op_tmp set
    rot_signo           =  @i_signo,
    rot_factor          =  @i_factor
    where rot_operacion = @w_operacionca
    and   rot_concepto  = @w_concepto_interes

     if @@error <> 0 return 710002
End


/* GENERACION DE LA TABLA DE AMORTIZACION */
exec @w_return           = sp_gentabla
     @i_operacionca      = @w_operacionca,
     @i_actualiza_rubros = 'S',
     @i_tabla_nueva      = 'S',
     @i_control_tasa     = 'C',
     @i_crear_op         = 'S',
     @i_batch_dd         = @i_batch_dd,
     @i_tramite_hijo     = @i_tramite_hijo,
     @i_dias_gracia      = @w_dias_gracia,
     @i_crea_ext         = @i_crea_ext,
     @i_tasa             = @i_tasa, --JSA Santander
  --PQU pasar fecha de vencimiento primer dividendo
  --LPO TEC Entonces pasamos @i_fecha_ven_pc y adem?s la @i_tasa_grupal porque dentro se llama otra vez al sp_gen_rubtmp
     @i_fecha_ven_pc     = @i_fecha_ven_pc, --LPO TEC  
     @i_tasa_grupal      = @i_tasa_grupal,  --LPO TEC
     @i_grupal           = @i_grupal,       --LPO TEC     
     @o_fecha_fin        = @w_fecha_fin out,
     @o_msg_msv          = @o_msg_msv   out

if @w_return <> 0
begin
   --GFP se suprime print
   /*
   if @i_crea_ext is null
      PRINT 'creaopin.sp salio con error de sp_gentabla ' + @o_msg_msv
   else
   */
      select @o_msg_msv = 'creaopin.sp salio con error de sp_gentabla ' +  @o_msg_msv
   return @w_return
end


/*CONTROL DE LA TASA IBC ANTES DE CREAR LA OP*/
select
@w_tasa_aplicar     = rot_referencial,
@w_porcentaje       = rot_porcentaje
from ca_rubro_op_tmp
where rot_operacion = @w_operacionca
and   rot_concepto  = @w_concepto_interes

select @w_tasa_referencial = vd_referencia
from ca_valor_det
where vd_tipo   =  @w_tasa_aplicar
and   vd_sector =  @w_clase_cartera

select
@w_modalidad         = tv_modalidad,
@w_periodicidad      = tv_periodicidad
from ca_tasa_valor
where tv_nombre_tasa = @w_tasa_referencial
and tv_estado        = 'V'

exec @w_return         = sp_rubro_control_ibc
     @i_operacionca    = @w_operacionca,
     @i_concepto       = @w_concepto_interes,
     @i_porcentaje     = @w_porcentaje,
     @i_periodo_o      = @w_periodicidad,
     @i_modalidad_o    = @w_modalidad,
     @i_num_periodo_o  = 1

if @w_return <> 0
begin
   --GFP se suprime print
   /*
   if @i_crea_ext is null
      PRINT 'creopin.sp Mensaje Informativo Tasa Total de Interes supera el maximo permitido...'
   else
   */
      select @o_msg_msv = 'creopin.sp Mensaje Informativo Tasa Total de Interes supera el maximo permitido...'
end


/* ACTUALIZAR LA FECHA DE REAJUSTE DE LA OPERACION */
select @w_fecha_reajuste = '01/01/1900'

if isnull(@w_periodo_reajuste,0) <> 0 begin

   if @w_periodo_reajuste % @w_periodo_int = 0
      select @w_fecha_reajuste = dit_fecha_ven
      from   ca_dividendo_tmp
      where  dit_operacion = @w_operacionca
      and    dit_dividendo = @w_periodo_reajuste / @w_periodo_int
   else
      select @w_fecha_reajuste =
      dateadd(dd,td_factor*@w_periodo_reajuste, @i_fecha_ini)
      from ca_tdividendo
      where td_tdividendo = @w_tdividendo
end

update ca_operacion_tmp set
opt_fecha_reajuste  = @w_fecha_reajuste
where opt_operacion = @w_operacionca

if @@error <> 0 return 710002

select
@w_fecha_f = convert(varchar(10),@w_fecha_fin,@i_formato_fecha),
@o_banco   = @w_banco

if @i_salida = 'S' begin
   if @i_crea_ext is null
   begin
      select @w_banco
      select @w_fecha_f
      select es_descripcion from ca_estado where es_codigo = 0
      select @w_tipo
      select @i_sector

      select  c.valor
      from  cobis..cl_tabla t, cobis..cl_catalogo c
      where c.tabla = t.codigo      
      and   t.tabla = 'cr_clase_cartera'
      and c.codigo = ltrim(rtrim(@i_clase_cartera))      
      select @w_rowcount = @@rowcount
   end
   else
   begin
      select  @w_rowcount = count(1)
      from  cobis..cl_tabla t, cobis..cl_catalogo c
      where c.tabla = t.codigo      
      and   t.tabla = 'cr_clase_cartera'
      and c.codigo = ltrim(rtrim(@i_clase_cartera))      
   end
   if @w_rowcount = 0 return 710218
end

/*PROCESAMIENTO OPERACION NACE VENCIDA*/
select @w_nace_vencida = opt_nace_vencida
from ca_operacion_tmp
where opt_operacion = @w_operacionca

if @@rowcount = 0 return 701002


if @w_nace_vencida = 'S' begin

   update ca_operacion_tmp set
   opt_fecha_fin = opt_fecha_ini
   where opt_operacion = @w_operacionca

   if @@error <> 0 return 701002

   update ca_dividendo_tmp set
   dit_fecha_ven = dit_fecha_ini
   where dit_operacion = @w_operacionca

   if @@error <> 0 return 705043

   update ca_amortizacion_tmp set
   amt_acumulado = amt_cuota
   where amt_operacion = @w_operacionca

   if @@rowcount = 0 return 705022


   /** CANCELACION DEL INTERES **/
   update ca_amortizacion_tmp set
   amt_pagado    = 0,
   amt_acumulado = 0,
   amt_cuota     = 0,
   amt_estado    = @w_est_cancelado
   where amt_operacion = @w_operacionca
   and   amt_concepto  = @w_concepto_interes

   if @@rowcount = 0 return 705022

end

-- KDR Actualización de regitros de operaciones Grupales Hijas
if @i_ref_grupal is not null and @i_grupal = 'S'
   update cob_credito..cr_tramite_grupal
   set tg_operacion = @w_operacionca,
       tg_prestamo  = @w_banco
   where tg_referencia_grupal = @i_ref_grupal
   and   tg_cliente           = @i_cliente
 

--GFP 21/Feb/2022 Calculo de rubros financiados
if exists (select 1 from ca_rubro where ru_toperacion = @i_toperacion
                         and ru_moneda = 0
                         and ru_financiado = 'S'
                         and ru_crear_siempre = 'S')
begin
exec @w_return         = sp_inserta_rubros_financiados
     @s_user           = @s_user,
     @s_term           = @s_term,
     @s_ofi            = @s_ofi,  
     @s_date           = @s_date,
     @i_operacionca    = @w_operacionca,
	 @i_toperacion     = @i_toperacion,
	 @i_moneda         = @i_moneda,
	 @i_banco          = @w_banco,
	 @i_grupo          = @i_grupo             -- KDR Se incluye parámetro enviado
	 
if @w_return <> 0 
return @w_return
end

return 0

go

