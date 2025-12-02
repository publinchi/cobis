/********************************************************************/
/*  NOMBRE LOGICO:          sp_tramite                              */
/*  NOMBRE FISICO:          tramite.sp                              */
/*  PRODUCTO:               Credito                                 */
/*  Disenado por:           Geovanny Guaman                         */
/*  Fecha de escritura:     23/Abr/2019                             */
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
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                           PROPOSITO                              */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito             */
/*                                                                  */
/********************************************************************/
/*                         MODIFICACIONES                           */
/*  FECHA             AUTOR            RAZON                        */
/*  23/04/2019     gguaman        Emision Inicial                   */
/*  23/06/2021     cveintemilla   Valida para desembolso bajo linea */
/*  25/06/2021     pmora          GFI-B494087                       */
/*  20/08/2021     pmora          Validación de capacidad de pago   */
/*                                bajo línea de crédito.            */
/*  17/09/2021     pmora          GFI-B533488                       */
/*  11/01/2022     DMO            Cambios para forzar actualizacion */
/*                                de operacion                      */
/*  09/03/2022     pmoreno        Validacion no forzar update en    */
/*                                grupal                            */
/*  05/04/2022     pmoreno        No forzar update en caso de       */
/*                                rechazo de solicitud.             */
/*  11/04/2023     pjarrin        S784659: Cambios por Control de   */
/*                                TEA                               */
/*  03/05/2023     oalquinga      S784841: Cambios para la APP      */
/*  02/06/2023     dmorales       Se valida @i_sector para APP      */
/*  22/06/2023     dmorales       No se valida sector para tramites */
/*                                tipo G y L                        */
/*  29/06/2023     bduenas       Se asocia beneficiaros del ente al */
/*                               tramite                            */
/*  11/07/2023     bduenas       Se agrega direccion default        */
/*  03/10/2023     ebaez         Mejora control oficiales           */
/*                               S911708-R216187                    */
/*  10/11/2023     O. Guaño      R219170: Se setea la oficina       */
/*                               correspondiente al oficial         */
/*  12/12/2023     D. Morales    R220707: Se valida flujos de       */
/*                               graduacion                         */
/********************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_tramite')
    drop proc sp_tramite
go

create proc sp_tramite (
            @s_ssn                     int              = null,
            @s_user                    login            = null,
            @s_sesn                    int              = null,
            @s_term                    descripcion      = null,         --MTA
            @s_date                    datetime         = null,
            @s_srv                     varchar(30)      = null,
            @s_lsrv                    varchar(30)      = null,
            @s_rol                     smallint         = null,
            @s_ofi                     smallint         = null,
            @s_org_err                 char(1)          = null,
            @s_error                   int              = null,
            @s_sev                     tinyint          = null,
            @s_msg                     descripcion      = null,
            @s_ssn_branch              int              = null,
            @s_org                     char(1)          = null,
            @t_rty                     char(1)          = null,
            @t_trn                     int              = null,
            @t_debug                   char(1)          = 'N',
            @t_file                    varchar(14)      = null,
            @t_from                    varchar(30)      = null,
            @t_show_version            bit              = 0,            -- Mostrar la version del programa
            @s_culture                 varchar(10)      = 'NEUTRAL',
            @i_operacion               char(1)          = null,
            @i_tramite                 int              = null,
            @i_tipo                    char(1)          = null,
            @i_truta                   tinyint          = null,
            @i_oficina_tr              smallint         = null,
            @i_usuario_tr              login            = null,
            @i_fecha_crea              datetime         = null,
            @i_oficial                 smallint         = null,
            @i_sector                  catalogo         = null,
            @i_ciudad                  int              = null,
            @i_estado                  char(1)          = null,
            @i_numero_op_banco         cuenta           = null,
            @i_migarada                cuenta           = null,         --RZ
            @i_cuota                   money            = null,
            @i_frec_pago               catalogo         = null,
            @i_moneda_solicitada       tinyint          = null,
            @i_provincia               int              = null,
            @i_monto_solicitado        money            = null,
            @i_monto_desembolso        money            = null,
            @i_pplazo                  smallint         = null,
            @i_tplazo                  catalogo         = null,
            /* campos para tramites de garantias */
            @i_proposito               catalogo         = null,
            @i_razon                   catalogo         = null,
            @i_txt_razon               varchar(255)     = null,
            @i_efecto                  catalogo         = null,
            /* campos para lineas de credito */
            @i_cliente                 int              = null,
            @i_grupo                   int              = null,
            @i_fecha_inicio            datetime         = null,
            @i_num_dias                smallint         = 0,
            @i_per_revision            catalogo         = null,
            @i_condicion_especial      varchar(255)     = null,
            @i_rotativa                char(1)          = null,
            @i_destino_fondos          varchar(255)     = null,
            @i_comision_tramite        float            = null,
            @i_subsidio                float            = null,
            @i_tasa_aplicar            float            = null,
            @i_tasa_efectiva           float            = null,
            @i_plazo_desembolso        smallint         = null,
            @i_forma_pago              varchar(255)     = null,
            @i_plazo_vigencia          smallint         = null,
            @i_origen_fondos           varchar(255)     = null,
            @i_formalizacion           catalogo         = null,
            @i_cuenta_corrientelc      cuenta           = null,
            /* operaciones originales y renovaciones */
            @i_linea_credito           cuenta           = null,
            @i_toperacion              catalogo         = null,
            @i_producto                catalogo         = null,
            @i_monto                   money            = null,
            @i_moneda                  tinyint          = null,
            @i_periodo                 catalogo         = null,
            @i_num_periodos            smallint         = 0,
            @i_destino                 catalogo         = null,
            @i_ciudad_destino          int              = null,
            -- solo para prestamos de cartera
            @i_reajustable             char(1)          = null,
            @i_per_reajuste            tinyint          = null,
            @i_reajuste_especial       char(1)          = null,
            @i_fecha_reajuste          datetime         = null,
            @i_cuota_completa          char(1)          = null,
            @i_tipo_cobro              char(1)          = null,
            @i_tipo_reduccion          char(1)          = null,
            @i_aceptar_anticipos       char(1)          = null,         --JSB 99-07-14 cambio de char por char(1)
            @i_precancelacion          char(1)          = null,         --JSB 99-07-14 cambio de char por char(1)
            @i_tipo_aplicacion         char(1)          = null,         --JSB 99-07-14 cambio de char por char(1)
            @i_renovable               char(1)          = null,         --JSB 99-07-14 cambio de char por char(1)
            @i_fpago                   catalogo         = null,
            @i_cuenta                  cuenta           = null,
            -- generales
            @i_renovacion              smallint         = null,
            @i_cliente_cca             int              = null,
            @i_es_acta                 char(1)          = null,
            @i_op_renovada             cuenta           = null,
            @i_deudor                  int              = null,
            -- reestructuraciones
            @i_op_reestructurar        cuenta           = null,
            @i_sector_contable         catalogo         = null,         --TME 08/09/98 nuevas variables
            @i_cupos_terceros          catalogo         = null,
            @i_origen_fondo            catalogo         = null,         --JCL 26/05/98
            @i_fondos_propios          char(1)          = null,
            @i_plazo                   catalogo         = null,
            @i_tram_anticipo           int              = null,
            @i_ssn                     int              = null,
            --Financiamientos JSB 99-03-30
            @i_trm_tmp                 int              = null,
            @i_revolvente              char(1)          = null,
            @i_her_ssn                 int              = null,
            @i_causa                   char(1)          = null,         -- Personalizaci+n Banco Atlantic
            @i_contabiliza             char(1)          = null,         --Persobalizaci+n Banco Atlantic
            @i_tvisa                   varchar(24)      = null,         --Persobalizaci+n Banco Atlantic
            @i_migrada                 cuenta           = null,         --RZ
            @i_tipo_linea              varchar(10)      = null,
            @i_plazo_dias_pago         int              = null,
            @i_tipo_prioridad          char(1)          = null,
            @i_linea_credito_pas       cuenta           = null,
            @i_linea_cancelar          varchar(20)      = null,
            @i_fecha_irenova           datetime         = null,
            @i_fdescuento              catalogo         = null,         --Vivi
            @i_cta_descuento           cuenta           = null,         --Vivi
            @i_proposito_op            catalogo         = null,         --Vivi
            @i_subtipo                 catalogo         = null,         --Vivi - CD00013, 2/May/05
            @i_tipo_tarjeta            catalogo         = null,         --Vivi - CD00013, 2/May/05
            @i_motivo                  catalogo         = null,         --Vivi
            @i_plazo_pro               int              = null,         --Vivi
            @i_fecha_valor             char(1)          = null,         --Vivi
            @i_estado_lin              catalogo         = null,         --Vivi
            @i_tasa_asociada           char(1)          = null,
            @i_tpreferencial           char(1)          = 'N',
            @i_porcentaje_preferencial float            = null,
            @i_monto_preferencial      money            = 0,
            @i_abono_ini               money            = null,
            @i_opcion_compra           money            = null,
            @i_beneficiario            descripcion      = null,
            @i_financia                char(1)          = null,
            @i_medio                   int              = null,
            @i_ult_tramite             int              = null,         --Vivi, Tramite del que hereda condiciones si tiene linea asociada
            @i_empleado                int              = null,         --Vivi, C+digo del empleado para Tarjeta Corporativa
            @i_tran_servicio           char(1)          = 'S',          --DAG
            @i_migracion               char(1)          = 'N',          --Vivi, se envia S cuando se desea migrar
            @i_nombre_empleado         varchar(40)      = null,         --Nombre del Empleado para Linea Visa
            @i_formato_fecha           tinyint          = 103,          --LIM 30/Mar/2006
            @i_canal                   tinyint          = 0,            -- Canal: 0=Fronend  1=Batch   2=Workflow
            @i_promotor                int              = null,
            @i_comision_pro            float            = null,
            @i_iniciador               descripcion      = null,
            @i_entrevistador           descripcion      = null,
            @i_vendedor                descripcion      = null,
            @i_cuenta_vende            descripcion      = null,
            @i_agencia_venta           descripcion      = null,
            @i_aut_valor_aut           money            = null,
            @i_aut_abono_aut           money            = null,
            @i_canal_venta             catalogo         = null,
            @i_referido                varchar(1)       = null,
            @i_FIniciacion             datetime         = null,
            -- Prestamos Gemelos
            @i_gemelo                  char(1)          = null,
            @i_tasa_prest_orig         float            = null,
            @i_banco_padre             cuenta           = null,
            @i_num_cuenta              char(16)         = null,
            @i_prod_bancario           smallint         = null,
            @i_actsaldo                char(1)          = 'N',
            --PCOELLO Para manejo de Promociones
            @i_monto_promocion         money            = null,         --Valor que se va a dar al cliente por promocion
            @i_saldo_promocion         money            = null,         --Saldo pendiente de pago de la promocion
            @i_tipo_promocion          catalogo         = null,         --Tipo de promocion
            @i_cuota_promocion         money            = null,         --Cuota mensual a pagar por el cliente por promocion
            @i_workflow                char(1)          = null,         -- ABE Variable para que se ejecute desde el m=dulo de Workflow
            @i_id_inst_proc            int              = null,         --Instancia de proceso de CWF
            @i_compra_operacion        char(1)          = 'N',          --SRO, 25 Marzo 2009, indica si la operacion de factoring es comprada o no.
            @i_destino_descripcion     descripcion      = null,         --DCH, 02-Feb-2015 Descripcion especifica del destino
            @i_patrimonio              money            = null,         --JMA, 02-Marzo-2015
            @i_ventas                  money            = null,         --JMA, 02-Marzo-2015
            @i_num_personal_ocupado    int              = null,         --JMA, 02-Marzo-2015
            @i_tipo_credito            catalogo         = null,         --JMA, 02-Marzo-2015
            @i_indice_tamano_actividad float            = null,         --JMA, 02-Marzo-2015
            @i_objeto                  catalogo         = null,         --JMA, 02-Marzo-2015
            @i_actividad               catalogo         = null,         --JMA, 02-Marzo-2015
            @i_descripcion_oficial     descripcion      = null,         --JMA, 02-Marzo-2015
            @i_sindicado               char(1)          = 'N',          --JMA, 02-Marzo-2015
            @i_tipo_cartera            catalogo         = null,         --JMA, 02-Marzo-2015
            @i_ventas_anuales          money            = null,         --NMA, 10-Abril-2015
            @i_activos_productivos     money            = null,         --NMA, 10-Abril-2015
            @i_sector_cli              catalogo         = null,         --JCA, 05-Mayo-2015 ORI-H005-3 Activdad Analisis del Oficial / Sector y Actividad del Cliente
            @i_cuota_maxima            float            = null,         --NMA campo nuevo en cr_liquida
            @i_cuota_maxima_linea      float            = null,         --NMA campo nuevo en cr_liquida
            @i_expromision             catalogo         = null,         --JES 05-Junio-2015
            @i_level_indebtedness      char(1)          = null,                    --DCA
            @i_asigna_fecha_cic        char(1)          = null,
            @i_convenio                char(1)          = null,
            @i_codigo_cliente_empresa  varchar(10)      = null,
            @i_reprogramingObserv      varchar(255)     = null,         --MCA - Observación de la reprogramación
            @i_motivo_uno              varchar(255)     = null,         --ADCH, 05/10/2015 motivo para tipo de solicitud
            @i_motivo_dos              varchar(255)     = null,         --ADCH, 05/10/2015 motivo para tipo de solicitud
            @i_motivo_rechazo          catalogo         = null,
            @i_valida_estado           char(1)          ='S',
            @i_numero_testimonio       varchar(50)      = null,
            @i_tamanio_empresa         varchar(5)       = null,         --ABE Tamaño de la empresa
            @i_producto_fie            catalogo         = null,
            @i_num_viviendas           tinyint          = null,
            @i_tipo_calificacion       catalogo         = null,
            @i_calificacion            catalogo         = null,
            @i_es_garantia_destino     char(1)          = null,
            @i_tasa                    float            = null,
            @i_sub_actividad           catalogo         = null,
            @i_departamento            catalogo         = null,
            --CAMPOS AUMENTADOS EN INTEGRACION FIE 
            @i_actividad_destino       catalogo         = null,         --SPO Actividad economica de destino
            @i_parroquia               catalogo         = null,         -- ITO:12/12/2011
            @i_canton                  catalogo         = null,         
            @i_barrio                  catalogo         = null,         
            @i_toperacion_ori          catalogo         = null,         --Policia Nacional: Se incrementa por tema de interceptor
            @i_credito_es              catalogo         = null,
            @i_financiado              char(2)          = null,
            @i_presupuesto             money            = null,
            @i_fecha_avaluo            datetime         = null,
            @i_valor_comercial         money            = null,
            @i_dia_fijo                smallint         = null,         --PQU se añade por integración Procesos negocio
            @i_enterado                catalogo         = null,         --PQU se añade por integración Procesos negocio
            @i_otros_ent               varchar(64)      = null,         --PQU se añade por integración Procesos negocio
            -- FBO Tabla Amortizacion                                   
            @i_pasa_definitiva         char(1)         = 'S',           --PQU se añade por integración Procesos negocio
            @i_regenera_rubro          char(1)         = 'S',           --PQU se añade por integración Procesos negocio
            -- Manejo de seguros                                         
            @i_seguro_basico           char(1)         = null,          --PQU se añade por integración Procesos negocio
            @i_seguro_voluntario       char(1)         = null,          --PQU se añade por integración Procesos negocio
            @i_tipo_seguro             catalogo        = null,          --PQU se añade por integración Procesos negocio
            @i_is_app                  char(1)         = 'N',          --OA Se agrega para la APP
            @i_tipo_producto           catalogo        = null,         --OA Se agrega para la APP
            @o_office_oficial          int             = null   out,
            @o_tramite                 int             = null   out
)
as
declare
            @w_spid                    smallint,                        --OGU 07/08/2012
            @w_today                   datetime,                        /* fecha del dia */
            @w_error                   int,                             /* valor que retorna */
            @w_sp_name                 varchar(32),                     /* nombre stored proc*/
            @w_existe                  tinyint,                         /* existe el registro*/
            @w_tramite                 int,
            @w_tipo                    char(1),
            @w_oficina_tr              smallint,
            @w_usuario_tr              login,
            @w_fecha_crea              datetime,
            @w_oficial                 smallint,
            @w_sector                  catalogo,
            @w_ciudad                  int,
            @w_estado                  char(1),
            @w_numero_op               int,
            @w_numero_op_banco         cuenta,
            @w_proposito               catalogo,                        /* garantias */
            @w_razon                   catalogo,
            @w_txt_razon               varchar(255),
            @w_efecto                  catalogo,
            @w_cliente                 int,                             /* lineas de credito */
            @w_grupo                   int,
            @w_fecha_inicio            datetime,
            @w_num_dias                smallint,
            @w_per_revision            catalogo,
            @w_condicion_especial      varchar(255),
            @w_linea_credito           int,                             /* renovaciones y operaciones */
            @w_toperacion              catalogo ,
            @w_producto                catalogo ,
            @w_monto                   money,
            @w_moneda                  tinyint,
            @w_periodo                 catalogo,
            @w_num_periodos            smallint,
            @w_destino                 catalogo,
            @w_ciudad_destino          int,
            @w_cuenta_corriente        cuenta,
            @w_renovacion              smallint,
            @w_fecha_concesion         datetime,
            @w_cuota                   money,
            @w_frec_pago               catalogo,
            @w_moneda_solicitada       tinyint,
            @w_provincia               int,
            @w_monto_solicitado        money,
            @w_monto_desembolso        money,
            @w_pplazo                  smallint,
            @w_tplazo                  catalogo,
            /* variables de trabajo */
            @w_cont                    int,
            @w_numero_aux              int,
            @w_linea                   int,
            @w_numero_linea            int,
            @w_numero_operacion        int,
            @w_prioridad               tinyint,
            @o_linea_credito           cuenta,
            @o_numero_op               cuenta,
            /* variables para ingreso en cr_ruta_tramite */
            @w_estacion                smallint,
            @w_etapa                   tinyint,
            @w_login                   login,
            @w_paso                    tinyint,
            @w_origen_fondo            catalogo,
            @w_fondos_propios          char(1),
            @w_cupos_terceros          catalogo,
            @w_sector_contable         catalogo,
            @w_monto_anticipo          money,
            @w_monto_org               money,
            @w_monto_linea             money,
            @w_moneda_df               tinyint,
            @w_causa                   char(1),                         --Personalización Banco Atlantic
            @w_tipo_linea              varchar(10),
            @w_tipo_prioridad          char(1),
            @w_tot_reg                 int,
            @w_operacionca             int,
            @w_fecha_irenova           datetime,
            @w_linea_cancelar          int,
            @w_linea_can_sobvis        int,
            @w_subtplazo               catalogo,                        --Vivi - CD00013
            @w_subplazos               smallint,                        --Vivi
            @w_subdplazo               int,
            @w_subtbase                varchar(10),
            @w_subporcentaje           float,
            @w_subsigno                char(1),
            @w_subvalor                float,
            @w_linea_cred_ant          cuenta,                          --Vivi
            @w_tipo_visa               catalogo,                        --Vivi
            @w_tipo_sobregiro          catalogo,                        --Vivi
            @w_motivo_suspen           catalogo,                        --Vivi
            @w_motivo_cancel           catalogo,                        --Vivi
            @w_tasa_asociada           char(1),
            @w_tasa                    float,                           --Vivi
            @w_medio                   int,
            @w_tot                     int,
            @w_li_monto                money,                           -- FCP
            @w_sp_name1                varchar(32),                     /* nombre stored proc*/
            @w_est_vencido             int,
            @w_saldo_imo               money,
            @w_rubro_imo               catalogo,
            @w_grupo_eco               int,                             -- BSA
            @w_tipo_oper               char(1),
            @w_codpais                 varchar(30),                     --MDI 21/Nov/2011
            @w_nemonico                varchar(30),
            @w_fecha_nueva             datetime,
            @w_fecha_anterior          datetime,
            @w_banco_anterior          varchar(20),
            @w_destino_descripcion     descripcion,
            @w_motivo_uno              varchar(255),                    -- ADCH, 05/10/2015 motivo para tipo de solicitud
            @w_motivo_dos              varchar(255),                    -- ADCH, 05/10/2015 motivo para tipo de solicitud
            @w_variables               varchar(64),                     --PQU integracion
            @w_return_variable         varchar(25),                     --PQU integracion
            @w_return_results          varchar(25),                     --PQU integracion
            @w_return_results_plazo    varchar(255),                    --PQU integracion
            @w_last_condition_parent   int,                             --PQU integracion
            @w_tipo_pa                 varchar(10),                     --PQU integracion
            @w_band_regla              int,                             --PQU integracion
            @w_msg                     varchar(255),                    --PQU integracion
            @w_valIni                  varchar(20),                     --PQU integracion
            @w_valFin                  varchar(20),                     --PQU integracion
            @w_frecuency               varchar(20),                     --PQU integracion
            @w_plazo_meses             int,                             --PQU integracion
            @w_tramite_ret             int,                             --PQU integracion
            @w_monto_utilizado_linea   money,
            @w_moneda_linea            int,
            @w_monto_min               money,
            @w_monto_max               money,
            @w_de_cliente              int,
            @w_forzar_update           char(1),
            @w_product_id              varchar(10),
            @w_destino_eco             varchar(30),
            @w_product_category        int,
            @w_parent_node             varchar(10),
            @w_seguro                  varchar(10),
            --R216187 Validar que el oficial sea el mismo que del grupo
            @w_controlar_oficial       char(10),
            @w_oficial_ente            int,
			@w_es_cliente_graduacion   char(1),
			@w_msg_error               varchar(132),
			@w_flujos_graducacion      varchar(100)

if @t_show_version = 1
begin
    print 'Stored procedure sp_tramite, Version 4.0.0.2'
    return 0
end

select @w_forzar_update = 'N' --DMO 10/01/2022

select @w_spid = @@spid       --OGU 07/08/2012

-- DFL Inicio: Cambios en variables equivalentes para version base de FIE
select @i_moneda_solicitada = @i_moneda
select @i_revolvente = @i_rotativa

-- DFL
select @w_codpais = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ABPAIS'
and pa_producto   = 'ADM'

select @w_nemonico = pa_char
from cobis..cl_parametro
where pa_nemonico = 'CLIENT'
and pa_producto   = 'ADM'

select @w_destino_eco = pa_char
from cobis..cl_parametro
where pa_nemonico = 'DESECO'
and pa_producto   = 'CRE'

select @w_today  = isnull(@s_date, fp_fecha)
from   cobis..ba_fecha_proceso
select @w_moneda_df = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'MLOCR'
and    pa_producto = 'CRE'

--Control Oficiales
select @w_controlar_oficial = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'CTROFG'

select @w_sp_name     = 'sp_tramite',
       @w_est_vencido = 2,
       @w_product_id = ''


--Validacion App
if @i_is_app = 'S'
begin
    if not exists(select 1 
      from cob_fpm..fp_processbyproduct
     where pp_flow_id = (select pa_smallint 
                           from cobis..cl_parametro 
                          where pa_nemonico ='CWSCI' 
                            and pa_producto = 'PAM')
       and bp_product_idfk = @i_tipo_producto)
    begin
      select @w_error = 2110425
      goto ERROR
    end
    
    --parametro FONDOS PROPIOS OFSCRE
    select @i_origen_fondo = pa_char
     from cobis..cl_parametro
    where pa_nemonico   = 'OFSCRE'
      and pa_producto   = 'PAM'
    
    --bp_parentnode tipo de producto
    select @w_parent_node  = bp_parentnode
    from cob_fpm..fp_bankingproducts
    where bp_product_id = @i_tipo_producto
    
    select @w_product_category = ntc_productcategory
     from cob_fpm..fp_bankingproducts
    where bp_product_id = @w_parent_node
    
    select @i_sector = trim(ntc_mnemonic) from cob_fpm..fp_nodetypecategory 
    where ntc_productcategory_id = @w_product_category  
    and ntp_nodetype_idfk = 4
    
    if @i_sector is null
    begin
        select @i_sector = dt_clase_sector
        from ca_default_toperacion
        where dt_toperacion = @i_toperacion
        and   dt_moneda     = @i_moneda_solicitada
    end
    
    if @i_sector is null
    begin
    /*Registro no existe */
      select @w_error = 2110426
      goto ERROR
    end
    
    select @i_fecha_inicio = fp_fecha 
      from cobis..ba_fecha_proceso
    
    --Destino Geografico 
    select @i_ciudad         = ci_ciudad, 
           @i_provincia      = ci_provincia,
           @i_ciudad_destino = ci_ciudad,
           @o_office_oficial = of_oficina
      from cobis..cl_ciudad, cobis..cl_oficina, cobis..cl_funcionario, cobis..cc_oficial 
     where fu_oficina     = of_oficina
       and ci_ciudad      = of_ciudad
       and fu_funcionario = oc_funcionario
       and oc_oficial     = @i_oficial
       
    select @i_convenio   = ' ',
           @i_enterado   = '7',--Otros
           @i_canal      = 0,   --tomar el canal 0 ya que ahi retorna el id del proceso
		   @i_oficina_tr = @o_office_oficial -- R219170 - Oficina del oficial
end

-- Valida si el parametro @i_tplazo es null lo setea con el campo @i_frec_pago
if @i_tplazo IS null
begin
 select @i_tplazo = @i_frec_pago
end

-- Valida si el parametro @i_fecha_irenova es null lo setea con el campo @i_fecha_inicio
if @i_fecha_irenova is null
  begin
    select @i_fecha_irenova = @i_fecha_inicio
  end

-- Se valida si el i_cliente es null para igualar con i_cliente_cca
if @i_cliente IS null
begin
    select @i_cliente = @i_cliente_cca
end

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn != 21020 and @i_operacion = 'I') or
   (@t_trn != 21120 and @i_operacion = 'U') or
   (@t_trn != 21220 and @i_operacion = 'D') or
   (@t_trn not in (21520,73932) and @i_operacion = 'Q')
begin --Tipo de transaccion no corresponde
   select @w_error = 2101006
   goto ERROR
end

if @i_operacion != 'Q' and @i_motivo_rechazo is null
begin
 /* Chequeo de Existencias */
 /**************************/
 select
       @w_tramite            = tr_tramite,
       @w_tipo               = tr_tipo,
       @w_oficina_tr         = tr_oficina,
       @w_usuario_tr         = tr_usuario,
       @w_fecha_crea         = tr_fecha_crea,
       @w_oficial            = tr_oficial,
       @w_sector             = tr_sector,
       @w_ciudad             = tr_ciudad,
       @w_estado             = tr_estado,
       @w_numero_op          = tr_numero_op,
       @w_numero_op_banco    = tr_numero_op_banco,
       /* garantias*/
       @w_proposito          = tr_proposito,
       @w_razon              = tr_razon,
       @w_txt_razon          = rtrim(tr_txt_razon),
       @w_efecto             = tr_efecto,
       /*lineas*/            
       @w_cliente            = tr_cliente,
       @w_grupo              = tr_grupo,
       @w_fecha_inicio       = tr_fecha_inicio,
       @w_num_dias           = tr_num_dias,
       @w_per_revision       = tr_per_revision,
       @w_condicion_especial = tr_condicion_especial,
       /*renov. y operaciones*/
       @w_linea_credito      = tr_linea_credito,
       @w_toperacion         = tr_toperacion,
       @w_producto           = tr_producto,
       @w_monto              = tr_monto,
       @w_moneda             = tr_moneda,
       @w_periodo            = tr_periodo,
       @w_num_periodos       = tr_num_periodos,
       @w_destino            = tr_destino,
       @w_ciudad_destino     = tr_ciudad_destino,
       @w_renovacion         = tr_renovacion,
       @w_causa              = tr_causa,                       --Personalización Banco Atlantic
       @w_tipo_linea         = tr_toperacion,
       @w_fecha_irenova      = tr_fecha_irenova,
       @w_linea_cancelar     = tr_linea_cancelar,
       @w_tasa_asociada      = tr_tasa_asociada,
       @w_cuota              = tr_cuota,
       @w_frec_pago          = tr_frec_pago,
       @w_moneda_solicitada  = tr_moneda_solicitada,
       @w_provincia          = tr_provincia,
       @w_monto_solicitado   = tr_monto_solicitado,
       @w_monto_desembolso   = tr_monto_desembolso,
       @w_pplazo             = tr_plazo,
       @w_tplazo             = tr_tplazo
 from cr_tramite
 where tr_tramite = @i_tramite
 if @@rowcount > 0
  select @w_existe = 1
 else
  select @w_existe = 0

-- VALIDACION DEL MONTO APROBADO 
 select @w_monto_min = dt_monto_min,
        @w_monto_max = dt_monto_max
 from   cob_cartera..ca_default_toperacion
 where  dt_toperacion = @i_toperacion
 and    dt_moneda     = @i_moneda

if (@i_tipo <> 'L' and  @i_tipo <> 'G')  --PQU
begin
if isnull(@i_monto,0) > 0
   if isnull(@w_monto_min,0) > 0 or isnull(@w_monto_max,0) > 0
      if @i_monto < @w_monto_min or @i_monto > @w_monto_max
       begin
          select @w_error = 21110120
          goto ERROR
       END
END 

-- VALIDACION DESTINO ECONOMICO POR SECTOR DE CARTERA
if (@i_tipo <> 'L' and  @i_tipo <> 'G') --PQU
begin
    if (@i_sector is not null) 
    begin
        select @w_product_id = bp_product_id 
        from cob_fpm..fp_bankingproducts 
        where bp_name = (select ltrim(rtrim(b.valor)) 
                            from cobis..cl_tabla a, cobis..cl_catalogo b 
                        where a.codigo = b.tabla 
                            and a.tabla = 'cl_sector_neg' 
                            and b.codigo = @i_sector)
                            
        if not exists (select 1
                        from cob_fpm..fp_dictionaryfields , cob_fpm..fp_unitfunctionalityvalues
                        where dc_fields_id     = dc_fields_id_fk
                        and bp_product_id_fk = @w_product_id
                        and uf_delete        = 'N'
                        and upper(dc_name)   = upper(@w_destino_eco)
                        and uf_value         = @i_actividad_destino)
        begin
            select @w_error = 2110415
            goto ERROR
        
        end
    end
end

if (@i_tipo = 'P' and (@i_operacion = 'I' or @i_operacion = 'U')) or
   (@i_tipo = 'L' and @i_operacion = 'U')
begin
     /** OBTIENE TIPO DE LINEA DE SOBREGIRO  **/
     --Vivi
     select @w_tipo_sobregiro = pa_char
       from cobis..cl_parametro
      where pa_producto = 'CRE' and pa_nemonico = 'OPSOBG'

     /** OBTIENE MOTIVO DE SUSPENSION Y CANCELACION DE LA LINEA DE SOBREGIRO  **/
    select @w_motivo_suspen = pa_char
      from cobis..cl_parametro
     where pa_producto = 'CRE' and pa_nemonico = 'MOTSUS'

    select @w_motivo_cancel = pa_char
      from cobis..cl_parametro
     where pa_producto = 'CRE' and pa_nemonico = 'MOTCAN'

    -- VERifICAR LAS DISTRIBUCIONES CONTRA EL MONTO DE LA LINEA
    -- cotizaciones
    /* Lleno una tabla temporal con la cotizacion de las monedas */
       insert into cr_cotiz3_tmp
       (spid, moneda, cotizacion)
       select distinct @w_spid,
       a.ct_moneda, a.ct_compra
       from   cb_cotizaciones a
       where  ct_fecha = (select max(b.ct_fecha)
                          from  cb_cotizaciones b
                          where b.ct_moneda = a.ct_moneda
                          and   b.ct_fecha <= @w_today)
       -- insertar un registro para la moneda local
    if not exists (select 1 from cr_cotiz3_tmp  --PQU cambio de * a 1
                   where moneda = @w_moneda_df)
    insert into cr_cotiz3_tmp (spid, moneda, cotizacion)
    values (@w_spid, @w_moneda_df, 1)

    -- NUEVO MONTO DE LA LINEA DE CREDITO EN ML
    select     @w_monto_linea = isnull(@i_monto,isnull(@w_monto,0)) * cotizacion
    from     cr_cotiz3_tmp
    where    isnull(@i_moneda,isnull(@w_moneda,0)) = moneda

    if @i_tipo = 'L'
        select @w_numero_linea   = li_numero,
               @w_linea_cred_ant = li_num_banco --Vivi
        from  cr_linea
        where li_tramite = @i_tramite
    else
        select  @w_numero_linea   = li_numero * -1,
                @w_linea_cred_ant = li_num_banco, --Vivi
                @w_monto_org      = isnull(li_utilizado, 0),
                @w_li_monto       = li_monto      -- FCP
        from  cr_linea
        where li_num_banco = @i_linea_credito

      /** VERifICA SI ES PRORROGA QUE EXISTA SOLO UNA ACTIVA **/
      if (@i_tipo = 'P' and (@i_operacion = 'I' or @i_operacion = 'U')) and
          exists(select 1 from cr_tramite
                 where tr_tipo = 'P' and tr_tramite != @i_tramite and tr_linea_credito = abs(@w_numero_linea) and tr_numero_op_banco is null and tr_estado != 'Z' )
      begin
         select @w_error = 2101079
         goto ERROR
      end

      /** NO SE PERMITE CREAR UNA PRORROGA CON VALOR MENOR AL UTILIZADO**/
      if @w_monto_linea < @w_monto_org and @i_tipo = 'P' and @i_motivo != @w_motivo_suspen
      begin
         if @w_tipo_sobregiro = isnull(@w_toperacion, @i_tipo_linea) and @i_motivo = @w_motivo_cancel
             select @w_tipo_sobregiro = @w_toperacion
         else
         begin
            if @i_motivo = @w_motivo_cancel
            begin
               select @w_error = 2101084
               goto ERROR
            end
         end
      end

  /** MONTO APROBADO DEL SUBLIMITE NO DEBE SER MENOR A UTILIZADO DEL SUBLIMITE **/
     if (@i_tipo = 'L' or (@i_tipo = 'P' and @i_motivo != @w_motivo_suspen ) ) and
             exists (select 1 from cr_lin_ope_moneda
                     where om_linea = @w_numero_linea
                       and om_monto < om_utilizado )
     begin
         if @w_tipo_sobregiro = isnull(@w_toperacion, @i_tipo_linea) and @i_motivo = @w_motivo_cancel
              select @w_tipo_sobregiro = @w_toperacion
     end

    -- EVALUACION CON DISTRIBUCION DE LA LINEA EN MIEMBROS DE GRUPO
    if exists (select  1
               from  cr_lin_grupo
               where lg_linea = @w_numero_linea
               and lg_monto > isnull(@i_monto,isnull(@w_monto,0)) )
     begin
        -- ERROR: Existen distribuciones entre los miembros de grupo que superan
        -- el monto total de la Linea de Credito
          select @w_error = 2101085
          goto ERROR
     end

     /** OBTIENE TIPO DE LINEA DE VISA  **/
     --Vivi
     select @w_tipo_visa = pa_char
       from cobis..cl_parametro
      where pa_producto = 'CRE'
        and pa_nemonico = 'OPVISA'
end

/*INI SNU 13/08/2009 Validacion para la reestructuracion */
if @i_tipo = 'E'
begin
   select @w_saldo_imo  = sum(am_cuota + am_gracia - am_pagado)
     from cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
    where op_operacion  = am_operacion
      and am_operacion  = ro_operacion
      and am_concepto   = ro_concepto
      and ro_tipo_rubro = 'M'
      and op_banco      = @i_op_reestructurar

  if (@w_nemonico = 'MIB'  and @w_codpais = 'PA') -- MDI  para MIB
  begin
     select @w_tipo_oper = op_tipo  from cob_cartera..ca_operacion where op_banco  = @i_op_reestructurar

     if @w_tipo_oper != 'N'
     begin
        exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 2110385
       return 2110385
     end
   end
end

if @i_tipo = 'R'
  if (@w_nemonico = 'MIB'  and @w_codpais = 'PA') -- MDI  para MIB
  begin
    select @w_fecha_nueva = op_fecha_ini from cob_cartera..ca_operacion where op_tramite = @i_tramite

   select @w_banco_anterior = or_num_operacion, @w_fecha_anterior = op_fecha_ult_proceso
   from cob_credito..cr_op_renovar, cob_cartera..ca_operacion
   where or_tramite = @i_tramite
     and op_banco   = or_num_operacion
     and op_fecha_ult_proceso != @w_fecha_nueva
   if @@rowcount != 0
    begin
        print 'Atención la operación nueva inicia el :'+ convert(varchar(10),@w_fecha_nueva,103) +'  y la operación anterior  '+ @w_banco_anterior +' tiene fecha valor al '+ convert(varchar(10),@w_fecha_anterior,103)
       return 1
    end
  end
/* FIN SNU 13/08/2009 Validacion para la reestructuracion */

/* BSA 15/09/2009 Validacion de distribucion a miembro del grupo */
if @i_tipo = 'O' and @i_linea_credito is not null
begin
     select @w_linea     = li_numero,
            @w_grupo_eco = li_grupo
     from   cr_linea
     where  li_num_banco = @i_linea_credito

     if @w_grupo_eco is not null
     begin
          /* SRO INI 06/NOV/2009 CR00071 */
          if @w_existe = 1
          begin
             select @i_deudor = de_cliente
             from cob_credito..cr_deudores
             where de_tramite = @i_tramite
               and de_rol = 'D'
          end
          /* SRO FIN 06/NOV/2009 CR00071 */

          if not exists(select 1 from cr_lin_grupo
          where    lg_linea   = @w_linea
          and      lg_cliente = @i_deudor)
          begin
               exec cobis..sp_cerror
                  @t_debug  =  @t_debug,
                  @t_file   =  @t_file,
                  @t_from   =  @w_sp_name,
                  @i_num    =  2107037
               return 1
          end
      end
end

/* Chequeo de Linea de Credito */
if @i_linea_credito is not null --CVA
begin
    if (@i_operacion = 'I' or @i_operacion = 'U') and @i_tipo = 'O'
    begin
        if not exists ( select 1 
                        from cob_credito..cr_lin_ope_moneda 
                        join cob_credito..cr_linea on cr_linea.li_numero = cr_lin_ope_moneda.om_linea
                        where li_num_banco = @i_linea_credito 
                        and om_toperacion = @i_toperacion 
                        and om_moneda = @i_moneda)
         begin
            exec cobis..sp_cerror
              @t_debug  =  @t_debug,
              @t_file   =  @t_file,
              @t_from   =  @w_sp_name,
              @i_num    =  2110118
            return 2110118
         end
    
        if exists (select  1
                   from  cr_lin_ope_moneda, cr_linea
                   where om_linea      = li_numero
                     and li_num_banco  = @i_linea_credito
                     and om_toperacion = @i_toperacion
                     and om_moneda     = @i_moneda
                     and ((om_monto - isnull(om_utilizado,0)) < isnull(@i_monto,isnull(@w_monto,0))))
         begin
            exec cobis..sp_cerror
              @t_debug  =  @t_debug,
              @t_file   =  @t_file,
              @t_from   =  @w_sp_name,
              @i_num    =  2101027
            return 2101027
         end
        
        select @w_monto_utilizado_linea = (li_monto - isnull(li_utilizado,0)), @w_moneda_linea = li_moneda
        from cr_linea
        where li_num_banco = @i_linea_credito
        
        exec cob_credito..sp_conversion_moneda
                @s_date                = @i_fecha_inicio,
                @i_fecha_proceso       = @i_fecha_inicio,
                @i_moneda_monto        = @w_moneda_linea,
                @i_moneda_resultado    = @i_moneda,
                @i_monto               = @w_monto_utilizado_linea,
                @o_monto_resultado     = @w_monto_utilizado_linea out,
                @o_monto_mn_resul      = null
                
        if @w_monto_utilizado_linea < @i_monto
         begin
            exec cobis..sp_cerror
                          @t_debug  =  @t_debug,
                          @t_file   =  @t_file,
                          @t_from   =  @w_sp_name,
                          @i_num    =  2101027
            return 2101027
         end
    end

    select
    @w_numero_linea = li_numero,
    @w_li_monto     = li_monto      -- FCP
    from       cob_credito..cr_linea
    where    li_num_banco = @i_linea_credito
    if @@rowcount = 0
     begin
      if @i_operacion = 'I'
       delete cr_deudores_tmp where dt_ssn = @i_ssn
       /** registro no existe **/
       select @w_error = 2101010
       goto ERROR
     end

     /** VERifICA SI ES PRORROGA QUE EXISTA SOLO UNA ACTIVA **/
     if (@i_tipo = 'P' and (@i_operacion = 'I' or @i_operacion = 'U')) and
         exists( select 1 from cr_tramite
                 where tr_tipo = 'P' and tr_tramite != @i_tramite and tr_linea_credito = abs(@w_numero_linea) and tr_numero_op_banco is null and tr_estado != 'Z' )
      begin
         select @w_error = 2101079
         goto ERROR
      end
end

/* Chequeo de Numero de operacion */
if @i_numero_op_banco is not null
 begin
    if @i_producto = 'CCA'
     begin
        select @w_numero_operacion = op_operacion
        from   cob_cartera..ca_operacion
        where  op_banco = @i_numero_op_banco
        if @@rowcount = 0
         begin
          if @i_operacion = 'I'
          delete cr_deudores_tmp where dt_ssn = @i_ssn
        /** registro no existe **/
          select @w_error =  2101011
          goto ERROR
         end
     end
 end
end

if @i_operacion = 'I' or @i_operacion = 'U'
begin

   /* SYR 12/Julio/2007 */
   /* Chequeo Anticipos */
   if (@i_tram_anticipo = 1 and @i_operacion = 'U')
    begin
        select @w_monto_anticipo = isnull(sum(tr_monto), 0)
        from cr_tramite
        where tr_tramite = @i_tramite

        select @w_monto_org = isnull(sum(tr_monto), 0)
        from cr_anticipo, cr_tramite
        where an_tram_anticipo = @i_tramite
          and tr_tramite = an_tramite_org

        if isnull(@i_monto,isnull(@w_monto,0)) >= @w_monto_org
         begin
         if @i_operacion = 'I'
          delete cr_deudores_tmp where dt_ssn = @i_ssn
           select @w_error =  710271 --'[sp_tramite] El monto del anticipo tiene que ser menor al monto original'
           goto ERROR
         end
    end

   /** Obtener prioridad **/
   select @w_prioridad = tt_prioridad
   from   cr_tipo_tramite
   where  tt_tipo = @i_tipo

   if @@rowcount = 0
   begin
      select @w_prioridad = 1
   end   
end

/*Control de Oficiales */
/**********************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin

	select @w_flujos_graducacion = pa_char 
	from cobis..cl_parametro with(nolock)
    where pa_nemonico = 'FPGRA'
    and pa_producto = 'CRE'
	
	if @@rowcount = 0
	begin
		select @w_error = 2110432
        select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje('FPGRA', @w_error, @s_culture)
        goto ERROR
	end

   if exists(select 1 from cob_workflow..wf_proceso with(nolock)
			  inner join cob_workflow..wf_inst_proceso on pr_codigo_proceso = io_codigo_proc 
			  where io_id_inst_proc = @i_id_inst_proc
			  and pr_nemonico in (select value from string_split(@w_flujos_graducacion,';')))
	begin
		if (@i_tipo = 'R' or @i_tipo = 'F') and @i_is_app = 'N' 
		begin
			set @w_es_cliente_graduacion = 'S'
		end
		else 
		begin
			select @w_error = 2110439
			goto ERROR
		end
	end
	else
	begin
		set @w_es_cliente_graduacion = 'N'
	end

	
   /*VALIDAR QUE EL CLIENTE Y LA SOLICITUD TENGAN EL MISMO OFICIAL*/
   --R220707: NO SE VALIDA PARA FLUJOS DE GRADUACION
   if @w_controlar_oficial = 'S' and @w_es_cliente_graduacion = 'N'
   begin
      select @w_oficial_ente = en_oficial
        from cobis..cl_ente
	   where en_ente = @i_cliente
      
      if @w_oficial_ente <> @i_oficial
      begin
         select @w_error = 2110435
         goto ERROR
	  end	  
   end
end

/* Insercion del registro */
/**************************/
if @i_operacion = 'I'
begin
    if @i_tipo is null
     begin
        delete cr_deudores_tmp where dt_ssn = @i_ssn
        /* Campos NOT null con valores nulos */
        select @w_error =  2101001
        goto ERROR
     end

    if @i_linea_cancelar is not null   --recupero numero interno de linea
     begin
       select @w_linea_cancelar=li_numero
         from cr_linea
        where li_num_banco=@i_linea_cancelar
     end

    --INTEGRACION FIE 
    if(@i_cliente IS null AND @i_tipo = 'G')
     begin
        select @i_cliente = op_cliente from cob_cartera..ca_operacion where op_banco = @i_numero_op_banco
     end

/*Incluir Financiamientos  SBU: 20/abr/2000 */
if (@i_deudor is null  and @i_tipo = 'O')
or (@i_deudor is null  and @i_tipo = 'R')
or (@i_deudor is null  and @i_tipo = 'F')
or (@i_deudor is null  and @i_tipo = 'P')           --Vivi
begin
 if @i_operacion = 'I'
    delete cr_deudores_tmp where dt_ssn = @i_ssn
/* Campos NOT null con valores nulos */
    select @w_error =  2101001
    goto ERROR
 end

if @w_existe = 1
 begin
   if @i_operacion = 'I'
    delete cr_deudores_tmp where dt_ssn = @i_ssn
    select @w_error =  2101002
    goto ERROR
 end

--Llamada al stored procedure que inserta tramites
--begin TRAN --Optimizacion JSA
if @i_trm_tmp is null
 begin
      select @i_trm_tmp = @i_ssn
 end

select @w_sp_name1 = 'cob_credito..sp_in_tramite',
       @i_monto  = isnull(@i_monto, isnull(@w_monto,0)),
       @i_moneda = isnull(@i_moneda,isnull(@w_moneda,0))

   exec @w_error = @w_sp_name1  --cob_credito..sp_in_tramite
        @s_ssn                     = @s_ssn,
        @s_user                    = @s_user,
        @s_sesn                    = @s_sesn,
        @s_term                    = @s_term,
        @s_date                    = @s_date,
        @s_srv                     = @s_srv,
        @s_lsrv                    = @s_lsrv,
        @s_rol                     = @s_rol,
        @s_ofi                     = @s_ofi,
        @s_org_err                 = @s_org_err,
        @s_error                   = @s_error,
        @s_sev                     = @s_sev,
        @s_msg                     = @s_msg,
        @s_org                     = @s_org,
        @t_rty                     = @t_rty,
        @t_trn                     = @t_trn,
        @t_debug                   = @t_debug,
        @t_file                    = @t_file,
        @t_from                    = @t_from,
        @i_operacion               = @i_operacion,
        @i_tramite                 = @i_tramite,
        @i_tipo                    = @i_tipo,
        @i_oficina_tr              = @i_oficina_tr,
        @i_usuario_tr              = @i_usuario_tr,
        @i_fecha_crea              = @i_fecha_crea,
        @i_oficial                 = @i_oficial,
        @i_sector                  = @i_sector,
        @i_ciudad                  = @i_ciudad,
        @i_estado                  = @i_estado,
        @i_numero_op_banco         = @i_numero_op_banco,
        @i_cuota                   = @i_cuota,
        @i_frec_pago               = @i_frec_pago,
        @i_moneda_solicitada       = @i_moneda_solicitada,
        @i_provincia               = @i_provincia,
        @i_monto_solicitado        = @i_monto_solicitado,
        @i_monto_desembolso        = @i_monto_desembolso,
        @i_monto                   = @i_monto,
        @i_moneda                  = @i_moneda,
        @i_pplazo                  = @i_pplazo,
        @i_tplazo                  = @i_tplazo,
        /* campos para tramites de garantias */
        @i_proposito               = @i_proposito,
        @i_razon                   = @i_razon,
        @i_txt_razon               = @i_txt_razon,
        @i_efecto                  = @i_efecto,
       /* campos para lineas de credito */
        @i_cliente                 = @i_cliente,
        @i_grupo                   = @i_grupo,
        @i_fecha_inicio            = @i_fecha_inicio,
        @i_num_dias                = @i_num_dias,
        @i_per_revision            = @i_per_revision,
        @i_condicion_especial      = @i_condicion_especial,
        @i_rotativa                = @i_rotativa,
        @i_destino_fondos          = @i_destino_fondos,
        @i_comision_tramite        = @i_comision_tramite,
        @i_subsidio                = @i_subsidio,
        @i_tasa_aplicar            = @i_tasa_aplicar,
        @i_tasa_efectiva           = @i_tasa_efectiva,
        @i_plazo_desembolso        = @i_plazo_desembolso,
        @i_forma_pago              = @i_forma_pago,
        @i_plazo_vigencia          = @i_plazo_vigencia,
        @i_formalizacion           = @i_formalizacion,
        @i_cuenta_corrientelc      = @i_cuenta_corrientelc,
        /* operaciones originales y renovaciones */
        @i_linea_credito           = @i_linea_credito,
        @i_toperacion              = @i_toperacion,
        @i_producto                = @i_producto,
        @i_periodo                 = @i_periodo,
        @i_num_periodos            = @i_num_periodos,
        @i_destino                 = @i_destino,
        @i_ciudad_destino          = @i_ciudad_destino,
        -- solo para prestamos de cartera
        @i_reajustable             = @i_reajustable,
        @i_per_reajuste            = @i_per_reajuste,
        @i_reajuste_especial       = @i_reajuste_especial,
        @i_fecha_reajuste          = @i_fecha_reajuste,
        @i_cuota_completa          = @i_cuota_completa,
        @i_tipo_cobro              = @i_tipo_cobro,
        @i_tipo_reduccion          = @i_tipo_reduccion,
        @i_aceptar_anticipos       = @i_aceptar_anticipos,
        @i_precancelacion          = @i_precancelacion,
        @i_tipo_aplicacion         = @i_tipo_aplicacion,
        @i_renovable               = @i_renovable,
        @i_fpago                   = @i_fpago,
        @i_cuenta                  = @i_cuenta,
        -- generales               
        @i_renovacion              = @i_renovacion,
        @i_cliente_cca             = @i_cliente_cca,
        @i_op_renovada             = @i_op_renovada,
        @i_deudor                  = @i_deudor,
        -- reestructuracion
        @i_op_reestructurar        = @i_op_reestructurar,
        @i_sector_contable         = @i_sector_contable,
        @i_origen_fondo            = @i_origen_fondo,
        @i_fondos_propios          = @i_fondos_propios,
        @i_plazo                   = @i_plazo,
        @i_numero_linea            = null,
        -- Financiamientos
        @i_revolvente              = @i_revolvente,
        @i_trm_tmp                 = @i_trm_tmp,
        @i_her_ssn                 = @i_her_ssn,
        @i_causa                   = @i_causa,
        @i_contabiliza             = @i_contabiliza,
        @i_tvisa                   = @i_tvisa,
        @i_migrada                 = @i_migrada,
        @i_tipo_linea              = @i_tipo_linea,
        @i_plazo_dias_pago         = @i_plazo_dias_pago,
        @i_tipo_prioridad          = @i_tipo_prioridad,
        @i_linea_credito_pas       = @i_linea_credito_pas,
        --Vivi
        @i_proposito_op            = @i_proposito_op,
        @i_linea_cancelar          = @w_linea_cancelar,
        @i_fecha_irenova           = @i_fecha_irenova,
        @i_subtipo                 = @i_subtipo,                    --Vivi - CD00013
        @i_tipo_tarjeta            = @i_tipo_tarjeta,               --Vivi - CD00013
        @i_motivo                  = @i_motivo,                     --Vivi
        @i_plazo_pro               = @i_plazo_pro,                  --Vivi
        @i_fecha_valor             = @i_fecha_valor,                --Vivi
        @i_estado_lin              = @i_estado_lin,                 --Vivi
        @i_subtplazo               = @w_subtplazo,                  --Vivi - CD00013
        @i_subplazos               = @w_subplazos,
        @i_subdplazo               = @w_subdplazo,
        @i_subtbase                = @w_subtbase,
        @i_subporcentaje           = @w_subporcentaje,
        @i_subsigno                = @w_subsigno,
        @i_subvalor                = @w_subvalor,
        @i_tasa_asociada           = @i_tasa_asociada,
        @i_tpreferencial           = @i_tpreferencial,
        @i_porcentaje_preferencial = @i_porcentaje_preferencial,
        @i_monto_preferencial      = @i_monto_preferencial,
        @i_abono_ini               = @i_abono_ini,
        @i_opcion_compra           = @i_opcion_compra,
        @i_beneficiario            = @i_beneficiario,
        @i_financia                = @i_financia,
        @i_ult_tramite             = @i_ult_tramite,                --Vivi, Tramite del que hereda condiciones si tiene linea asociada
        @i_empleado                = @i_empleado,                   --Vivi, C+digo del empleado para Tarjeta Corporativa
        @i_ssn                     = @i_ssn,
        @i_nombre_empleado         = @i_nombre_empleado,
        @i_canal                   = @i_canal,
        @i_promotor                = @i_promotor,
        @i_comision_pro            = @i_comision_pro,
        @i_iniciador               = @i_iniciador,
        @i_entrevistador           = @i_entrevistador,
        @i_vendedor                = @i_vendedor,
        @i_cuenta_vende            = @i_cuenta_vende ,
        @i_agencia_venta           = @i_agencia_venta,
        @i_aut_valor_aut           = @i_aut_valor_aut,
        @i_aut_abono_aut           = @i_aut_abono_aut,
        @i_canal_venta             = @i_canal_venta,
        @i_referido                = @i_referido,
        @i_FIniciacion             = @i_FIniciacion,
        --Prestamos Gemelos
        @i_gemelo                  = @i_gemelo,
        @i_tasa_prest_orig         = @i_tasa_prest_orig,
        @i_banco_padre             = @i_banco_padre,
        @i_num_cuenta              = @i_num_cuenta,
        @i_prod_bancario           = @i_prod_bancario,
        --PCOELLO MANEJO DE PROMOCIONES
        @i_monto_promocion         = @i_monto_promocion,
        @i_saldo_promocion         = @i_saldo_promocion,
        @i_tipo_promocion          = @i_tipo_promocion,
        @i_cuota_promocion         = @i_cuota_promocion,
       --SRO INI Factoring VERSION
        @i_destino_descripcion     = @i_destino_descripcion,        --DC 04-Feb-2015
        @i_expromision             = @i_expromision,
        @i_objeto                  = @i_objeto,
        @i_actividad               = @i_actividad,
        @i_descripcion_oficial     = @i_descripcion_oficial,
        @i_tipo_cartera            = @i_tipo_cartera,
        @i_sector_cli              = @i_sector_cli,
        @i_convenio                = @i_convenio,
        @i_codigo_cliente_empresa  = @i_codigo_cliente_empresa,
        @i_tipo_credito            = @i_tipo_credito,               -- ADCH, 05/10/2015 motivo para tipo de solicitud
        @i_motivo_uno              = @i_motivo_uno,                 -- ADCH, 05/10/2015 motivo para tipo de solicitud
        @i_motivo_dos              = @i_motivo_dos,                 -- ADCH, 05/10/2015 motivo para tipo de solicitud
        @i_motivo_rechazo          = @i_motivo_rechazo,
        @i_tamanio_empresa         = @i_tamanio_empresa,
        @i_producto_fie            = @i_producto_fie,
        @i_num_viviendas           = @i_num_viviendas,
        @i_reprogramingObserv      = @i_reprogramingObserv,
        @i_sub_actividad           = @i_sub_actividad,
        @i_departamento            = @i_departamento,
        @i_credito_es              = @i_credito_es,
        @i_financiado              = @i_financiado,
        @i_presupuesto             = @i_presupuesto,
        @i_fecha_avaluo            = @i_fecha_avaluo,
        @i_valor_comercial         = @i_valor_comercial,
        --SRO FIN Factoring VERSION
        --INTEGRACION FIE       
        @i_actividad_destino       = @i_actividad_destino,          -- SPO Campo Actividad de destino de la operacion     
        @i_parroquia               = @i_parroquia,                  -- ITO:13/12/2011 parroquia
        @i_canton                  = @i_canton,
        @i_barrio                  = @i_barrio,
        @i_toperacion_ori          = @i_toperacion_ori,             --Policia Nacional: Se incrementa por tema de interceptor  VERifICAR SI SE INCLUYE
        @i_dia_fijo                = @i_dia_fijo,                   --PQU integración
        @i_enterado                = @i_enterado,                   --PQU integración
        @i_otros_ent               = @i_otros_ent,                  --PQU integración
        @i_seguro_basico           = @i_seguro_basico,              --PQU integración
        @i_seguro_voluntario       = @i_seguro_voluntario,          --PQU integración
        @i_tipo_seguro             = @i_tipo_seguro,                --PQU integración
        @o_retorno                 = @i_tramite              out
   if @w_error != 0
   begin
      --rollback tran Optimizacion JSA
      delete cr_deudores_tmp where dt_ssn = @i_ssn
      goto ERROR
   end

   delete cr_deudores_tmp where dt_ssn = @i_ssn
   select @o_tramite = @i_tramite

if @i_tipo <> 'L' and @i_linea_credito is not null
 begin
   exec @w_error          = cob_credito..sp_valida_capacidad_pago
        @i_tramite        = @i_tramite,
        @i_fecha_inicio   = @i_fecha_inicio, 
        @i_linea_credito  = @i_linea_credito,
        @i_cliente        = @i_cliente      
     if @w_error != 0
      begin
       return @w_error
      end
 end
 
 --Asociar beneficiaros del ente al trámite
if exists(select 1 from cobis.dbo.cl_beneficiario_seguro cbs where bs_nro_operacion = @i_deudor * -1 and bs_tramite is null and bs_producto = 1)
and not exists(select 1 from cobis.dbo.cl_beneficiario_seguro cbs where bs_tramite = @i_tramite and bs_producto = 7)
begin
   select @w_seguro = pa_char
   from cobis.dbo.cl_parametro
   where pa_nemonico = 'SEGCOL'
           
   insert into cobis.dbo.cl_beneficiario_seguro 
         (bs_nro_operacion,    bs_producto,   bs_tipo_id,       bs_ced_ruc,        bs_nombres, bs_apellido_paterno, 
          bs_apellido_materno, bs_porcentaje, bs_parentesco,    bs_secuencia,      bs_ente,    bs_fecha_mod, 
          bs_fecha_nac,        bs_telefono,   bs_direccion,     bs_provincia,      bs_ciudad,  bs_parroquia, 
          bs_codpostal,        bs_localidad,  bs_ambos_seguros, bs_tramite,        bs_seguro)
   SELECT @i_tramite * -1,     7,             bs_tipo_id,       bs_ced_ruc,        bs_nombres, bs_apellido_paterno, 
          bs_apellido_materno, bs_porcentaje, bs_parentesco,    bs_secuencia,      bs_ente,    getdate(), 
          bs_fecha_nac,        bs_telefono,   (case when bs_direccion is null then '||' else bs_direccion end),     bs_provincia,      bs_ciudad,  bs_parroquia, 
          bs_codpostal,        bs_localidad,  bs_ambos_seguros, @i_tramite,        @w_seguro 
   FROM cobis.dbo.cl_beneficiario_seguro 
   WHERE bs_nro_operacion = @i_deudor * -1 
   AND bs_producto = 1
   and bs_tramite is null
   if @@error != 0
   begin
       select  @w_error    = 725041              
       GOTO ERROR
   end
end
--COMMIT TRAN -- Optimizacion JSA
end --Fin de i_operacion = 'I'

/* Actualizacion del registro */
/******************************/
if @i_operacion = 'U'
begin
--  eliminacion de formas de pago en el caso de existir cambio de tipo de operacion
--  en un producto de comercio exterior
    select  @w_toperacion = tr_toperacion,
            @w_producto   = tr_producto,
            @i_destino    = isnull(@i_destino, tr_destino)     --PQU integracion se añade                                         
    from    cr_tramite
    where   tr_tramite = @i_tramite

    if  @i_tramite is null or @i_tipo is null
     begin
    /* Campos NOT null con valores nulos */
       select @w_error = 2101001
       goto ERROR
     end

    if @w_existe = 0
     begin
    /* Registro a actualizar no existe */
       select @w_error = 2105002
       goto ERROR
     end

    if @i_linea_cancelar is not null   --recupero numero interno de linea
     begin
       select @w_linea_cancelar=li_numero
         from cr_linea
        where li_num_banco=@i_linea_cancelar
     end
    else
     select @w_linea_cancelar = null

    /**==============================================================================**/
    /**     SI EL CAMPO TASA ASOCIADA A LA PRENDA ES 'S' OBTIENE TASA CALCULADA      **/
    /**     OJOOO, debe ir antes del Begin Tran, x creacion de tablas temporales     **/
    --Vivi
    if ((@i_tipo = 'L' or @i_tipo = 'P') and @w_toperacion != @w_tipo_visa and @i_tasa_asociada = 'S'  )
       or ((@i_tipo = 'O' or @i_tipo = 'R' or @i_tipo = 'E' or @i_tipo = 'F') and @i_tasa_asociada = 'S'  )
    begin
      /**  TASA NO VALIDA  **/
      if @w_tasa is null
        begin
        /* Error en insercion de transaccion de servicio */
         select @w_error = 2101071
         goto ERROR
        end
    end     /** end DE TASA ASOCIADA **/
/**==============================================================================**/

 /* llamada al stored procedure de actualizacion */
 begin tran
 /*PARA TIPO DE TRAMITE TIPO LINEA BORRA LOS DEUDORES ACTUALES Y GRABA LOS **/
 /*NUEVOS, YA QUE PUEDE CAMBIAR DE GRUPO A PERSONA/CIA.                    **/

--DMO variable @w_forzar_update para forzar actualizacion de operacion
if not exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
begin 
    create table #deudores(
        codigo_cliente  int
    )

    insert into #deudores select de_cliente from cob_credito..cr_deudores where de_tramite = @i_tramite

    declare cur_deudores cursor for
        select dt_cliente from cob_credito..cr_deudores_tmp where dt_tramite = @i_tramite
        
                    
    open cur_deudores
    fetch cur_deudores into     @w_de_cliente   
                    
    while(@@fetch_status = 0)
    begin
            
            if not exists (select 1 from cob_credito..cr_deudores where de_tramite = @i_tramite and de_cliente = @w_de_cliente )
            begin
                select @w_forzar_update = 'S' --DMO SI EXISTEN NUEVOS DEUDORES
            end
                
            delete #deudores where codigo_cliente = @w_de_cliente
            
            fetch cur_deudores into    @w_de_cliente        
                            
    end
    close cur_deudores
    deallocate cur_deudores

    if exists (select 1 from #deudores)
    begin
        select @w_forzar_update = 'S' --DMO SI SE BORRAN DEUDORES
    end

    drop table #deudores

    if not exists( select 1 from cob_cartera..ca_operacion where op_tramite = @i_tramite and op_destino = @i_destino)
    begin
               select   @w_forzar_update = 'S' --DMO SI SE CAMBIA DESTINO
    end
end
-- FIN DMO variable @w_forzar_update para forzar actualizacion de operacion
if (@i_motivo_rechazo is NOT null) --PMO no forzar update en caso de rechazo de solicitud
begin
   select @w_forzar_update = 'N'
end
 /*Se quita la validiación ya que esto se lo debe hacer para todos los trámites Version Cobis 4.4*/
 if exists( select 1 from cr_deudores_tmp, cobis..cl_ente where dt_ssn = @i_ssn and en_ente = dt_cliente)
  begin
    delete cr_deudores where de_tramite = @i_tramite
    insert cr_deudores
    select @i_tramite, dt_cliente, dt_rol, en_ced_ruc, dt_segvida, dt_cobro_cen 
    from cr_deudores_tmp, cobis..cl_ente
    where dt_ssn  = @i_ssn
      and en_ente = dt_cliente
    if @@error != 0
     begin
       rollback tran
      /* Error en insercion de registro */
       select @w_error = 2103001
       goto ERROR
     end
    delete cr_deudores_tmp where dt_ssn = @i_ssn
  end
    select @i_oficial  = isnull(@i_oficial,@w_oficial),
           @w_sp_name1 = 'cob_credito..sp_up_tramite',
           @i_monto    = isnull(@i_monto,isnull(@w_monto,0)),
           @i_moneda   = isnull(@i_moneda,isnull(@w_moneda,0))

/* parametros de tran-server */
 exec   @w_error                   = @w_sp_name1 -- cob_credito..sp_up_tramite        
        @s_ssn                     = @s_ssn,
        @s_user                    = @s_user,
        @s_sesn                    = @s_sesn,
        @s_term                    = @s_term,
        @s_date                    = @s_date,
        @s_srv                     = @s_srv,
        @s_lsrv                    = @s_lsrv,
        @s_rol                     = @s_rol,
        @s_ofi                     = @s_ofi,
        @s_org_err                 = @s_org_err,
        @s_error                   = @s_error,
        @s_sev                     = @s_sev,
        @s_msg                     = @s_msg,
        @s_org                     = @s_org,
        @t_rty                     = @t_rty,
        @t_trn                     = @t_trn,
        @t_debug                   = @t_debug,
        @t_file                    = @t_file,
        @t_from                    = @t_from,
        /* parametros de input */
        @i_operacion               = @i_operacion,
        @i_tramite                 = @i_tramite,
        @i_tipo                    = @i_tipo,
        @i_oficina_tr              = @i_oficina_tr,
        @i_usuario_tr              = @i_usuario_tr,
        @i_fecha_crea              = @i_fecha_crea,
        @i_oficial                 = @i_oficial,
        @i_sector                  = @i_sector,
        @i_ciudad                  = @i_ciudad,
        @i_estado                  = @i_estado,
        @i_numero_op_banco         = @i_numero_op_banco,
        @i_cuota                   = @i_cuota,
        @i_frec_pago               = @i_frec_pago,
        @i_moneda_solicitada       = @i_moneda_solicitada,
        @i_provincia               = @i_provincia,
        @i_monto_solicitado        = @i_monto_solicitado,
        @i_monto_desembolso        = @i_monto_desembolso,
        @i_pplazo                  = @i_pplazo,
        @i_tplazo                  = @i_tplazo,
        @i_proposito               = @i_proposito,
        @i_razon                   = @i_razon,
        @i_txt_razon               = @i_txt_razon,
        @i_efecto                  = @i_efecto,
        @i_cliente                 = @i_cliente,
        @i_grupo                   = @i_grupo,
        @i_fecha_inicio            = @i_fecha_inicio,
        @i_num_dias                = @i_num_dias,
        @i_per_revision            = @i_per_revision,
        @i_condicion_especial      = @i_condicion_especial,
        @i_rotativa                = @i_rotativa,
        @i_linea_credito           = @i_linea_credito,
        @i_toperacion              = @i_toperacion,
        @i_toperacion_ori          = @i_toperacion_ori,
        @i_producto                = @i_producto,
        @i_monto                   = @i_monto,
        @i_moneda                  = @i_moneda,
        @i_periodo                 = @i_periodo,
        @i_num_periodos            = @i_num_periodos,
        @i_destino                 = @i_destino,
        @i_ciudad_destino          = @i_ciudad_destino,
        @i_reajustable             = @i_reajustable,
        @i_per_reajuste            = @i_per_reajuste,
        @i_reajuste_especial       = @i_reajuste_especial,
        @i_fecha_reajuste          = @i_fecha_reajuste,
        @i_cuota_completa          = @i_cuota_completa,
        @i_tipo_cobro              = @i_tipo_cobro,
        @i_tipo_reduccion          = @i_tipo_reduccion,
        @i_aceptar_anticipos       = @i_aceptar_anticipos,
        @i_precancelacion          = @i_precancelacion,
        @i_tipo_aplicacion         = @i_tipo_aplicacion,
        @i_renovable               = @i_renovable,
        @i_fpago                   = @i_fpago,
        @i_cuenta                  = @i_cuenta,
        @i_renovacion              = @i_renovacion,
        @i_cliente_cca             = @i_cliente_cca,
        @i_op_renovada             = @i_op_renovada,
        @i_deudor                  = @i_deudor,
        -- reestructuracion
        @i_op_reestructurar        = @i_op_reestructurar,
        -- Financiamientos SBU: 20/abr/2000
        @i_destino_fondos          = @i_destino_fondos,
        @i_comision_tramite        = @i_comision_tramite,
        @i_subsidio                = @i_subsidio,
        @i_tasa_aplicar            = @i_tasa_aplicar,
        @i_tasa_efectiva           = @i_tasa_efectiva,
        @i_plazo_desembolso        = @i_plazo_desembolso,
        @i_forma_pago              = @i_forma_pago,
        @i_plazo_vigencia          = @i_plazo_vigencia,
        @i_origenfondos            = @i_origen_fondos,
        @i_formalizacion           = @i_formalizacion,
        @i_cuenta_corrientelc      = @i_cuenta_corrientelc,
        /* valores del registro actual */
        @i_w_tipo                  = @w_tipo,
        @i_w_oficina_tr            = @w_oficina_tr,
        @i_w_usuario_tr            = @w_usuario_tr,
        @i_w_fecha_crea            = @w_fecha_crea,
        @i_w_oficial               = @w_oficial,
        @i_w_sector                = @w_sector,
        @i_w_ciudad                = @w_ciudad,
        @i_w_estado                = @w_estado,
        @i_w_numero_op_banco       = @w_numero_op_banco,
        @i_w_numero_op             = @w_numero_op,
        @i_w_proposito             = @w_proposito,
        @i_w_razon                 = @w_razon,
        @i_w_txt_razon             = @w_txt_razon,
        @i_w_efecto                = @w_efecto,
        @i_w_cliente               = @w_cliente,
        @i_w_grupo                 = @w_grupo,
        @i_w_fecha_inicio          = @w_fecha_inicio,
        @i_w_num_dias              = @w_num_dias,
        @i_w_per_revision          = @w_per_revision,
        @i_w_condicion_especial    = @w_condicion_especial,
        @i_w_linea_credito         = @w_linea_credito,
        @i_w_toperacion            = @w_toperacion,
        @i_w_producto              = @w_producto,
        @i_w_monto                 = @w_monto,
        @i_w_moneda                = @w_moneda,
        @i_w_periodo               = @w_periodo,
        @i_w_num_periodos          = @w_num_periodos,
        @i_w_destino               = @w_destino,
        @i_w_ciudad_destino        = @w_ciudad_destino,
        @i_w_renovacion            = @w_renovacion,
        @i_w_plazo                 = @w_pplazo,
        @i_w_tplazo                = @w_tplazo,
        @i_w_cuota                 = @w_cuota,                    --PQU2 la cuota puede ir
        -- nuevas variable Salvador
        @i_sector_contable         = @i_sector_contable,
        @i_origen_fondo            = @i_origen_fondo,
        @i_fondos_propios          = @i_fondos_propios,
        @i_plazo                   = @i_plazo,
        @i_revolvente              = @i_revolvente,
        @i_causa                   = @i_causa,                    --Personalización Banco Atlantic
        @i_contabiliza             = @i_contabiliza,              --Personalización Banco Atlantic
        @i_tvisa                   = @i_tvisa,                    --Personalización Banco Atlantic
        @i_migrada                 = @i_migrada,                  --RZ Personalización Banco Atlantic
        @i_tipo_linea              = @i_tipo_linea,
        @i_plazo_dias_pago         = @i_plazo_dias_pago,
        @i_tipo_prioridad          = @i_tipo_prioridad,
        @i_linea_credito_pas       = @i_linea_credito_pas,
        @i_cta_descuento           = @i_cta_descuento,            --Vivi
        @i_proposito_op            = @i_proposito_op,
        @i_linea_cancelar          = @w_linea_cancelar,
        @i_fecha_irenova           = @i_fecha_irenova,
        @i_subtipo                 = @i_subtipo,                  --Vivi - CD00013
        @i_tipo_tarjeta            = @i_tipo_tarjeta,             --Vivi - CD00013
        @i_motivo                  = @i_motivo,                   --Vivi
        @i_plazo_pro               = @i_plazo_pro,                --Vivi
        @i_fecha_valor             = @i_fecha_valor,              --Vivi
        @i_estado_lin              = @i_estado_lin,               --Vivi
        @i_subtplazo               = @w_subtplazo,                --Vivi - CD00013
        @i_subplazos               = @w_subplazos,                
        @i_subdplazo               = @w_subdplazo,                
        @i_subtbase                = @w_subtbase,                 
        @i_subporcentaje           = @w_subporcentaje,            
        @i_subsigno                = @w_subsigno,                 
        @i_subvalor                = @w_subvalor,                 
        @i_tasa_asociada           = @i_tasa_asociada,            
        @i_tasa_prenda             = @w_tasa,                     --Vivi
        @i_tpreferencial           = @i_tpreferencial,
        @i_porcentaje_preferencial = @i_porcentaje_preferencial,
        @i_abono_ini               = @i_abono_ini,
        @i_opcion_compra           = @i_opcion_compra,
        @i_beneficiario            = @i_beneficiario,
        @i_financia                = @i_financia,
        @i_ult_tramite             = @i_ult_tramite,              --Tramite del que hereda condiciones si tiene linea asociada
        @i_empleado                = @i_empleado,                 --Vivi, C+digo del empleado para Tarjeta Corporativa
        @i_nombre_empleado         = @i_nombre_empleado,
        @i_actsaldo                = @i_actsaldo,
        @i_canal                   = @i_canal,
        @i_destino_descripcion     = @i_destino_descripcion,
        @i_patrimonio              = @i_patrimonio,
        @i_ventas                  = @i_ventas,
        @i_num_personal_ocupado    = @i_num_personal_ocupado,
        @i_tipo_credito            = @i_tipo_credito,
        @i_indice_tamano_actividad = @i_indice_tamano_actividad,
        @i_objeto                  = @i_objeto,
        @i_actividad               = @i_actividad,
        @i_descripcion_oficial     = @i_descripcion_oficial,
        @i_tipo_cartera            = @i_tipo_cartera,
        @i_ventas_anuales          = @i_ventas_anuales,           --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales
        @i_activos_productivos     = @i_activos_productivos,      --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales
        @i_sector_cli              = @i_sector_cli,
        @i_cuota_maxima            = @i_cuota_maxima,             --NMA campo nuevo en cr_liquida
        @i_cuota_maxima_linea      = @i_cuota_maxima_linea,       --NMA campo nuevo en cr_liquida
        @i_expromision             = @i_expromision,
        @i_level_indebtedness      = @i_level_indebtedness,       --DCA
        @i_asigna_fecha_cic        = @i_asigna_fecha_cic,
        @i_convenio                = @i_convenio,
        @i_codigo_cliente_empresa  = @i_codigo_cliente_empresa,
        @i_reprogramingObserv      = @i_reprogramingObserv,       -- MCA - Ingresa para observación de la reprogramación
        @i_motivo_uno              = @i_motivo_uno,               -- ADCH, 05/10/2015 motivo para tipo de solicitud
        @i_motivo_dos              = @i_motivo_dos,               -- ADCH, 05/10/2015 motivo para tipo de solicitud
        @i_motivo_rechazo          = @i_motivo_rechazo,
        @i_valida_estado           = @i_valida_estado,
        @i_numero_testimonio       = @i_numero_testimonio,
        @i_tamanio_empresa         = @i_tamanio_empresa,
        @i_producto_fie            = @i_producto_fie,
        @i_num_viviendas           = @i_num_viviendas,
        @i_tipo_calificacion       = @i_tipo_calificacion,
        @i_calificacion            = @i_calificacion,
        @i_es_garantia_destino     = @i_es_garantia_destino,
        @i_tasa                    = @i_tasa,
        @i_sub_actividad           = @i_sub_actividad,
        @i_departamento            = @i_departamento,
        --INTEGRACION FIE     
        @i_actividad_destino       = @i_actividad_destino,        -- SPO Campo Actividad de destino de la operacion     
        @i_parroquia               = @i_parroquia,                -- ITO:13/12/2011 parroquia
        @i_canton                  = @i_canton,
        @i_barrio                  = @i_barrio,
        @i_credito_es              = @i_credito_es,
        @i_financiado              = @i_financiado,
        @i_presupuesto             = @i_presupuesto,
        @i_fecha_avaluo            = @i_fecha_avaluo,
        @i_valor_comercial         = @i_valor_comercial,
        @i_dia_fijo                = @i_dia_fijo,                 --PQU integracion
        @i_enterado                = @i_enterado,                 --PQU integracion
        @i_otros_ent               = @i_otros_ent,                --PQU integracion
        @i_pasa_definitiva         = @i_pasa_definitiva,          --PQU integracion
        @i_regenera_rubro          = @i_regenera_rubro,           --PQU integracion
        @i_seguro_basico           = @i_seguro_basico ,           --PQU integracion
        @i_seguro_voluntario       = @i_seguro_voluntario,        --PQU integracion
        @i_tipo_seguro             = @i_tipo_seguro,               --PQU integracion
        @i_forzar_update           = @w_forzar_update             --DMO INTEGRACION
        if @w_error != 0
         begin
            rollback tran
            return 1
         end

if @i_tipo <> 'L' and @i_linea_credito is not null
  begin
      exec  @w_error          = cob_credito..sp_valida_capacidad_pago
            @i_tramite        = @i_tramite,
            @i_fecha_inicio   = @i_fecha_inicio, 
            @i_linea_credito  = @i_linea_credito,
            @i_cliente        = @i_cliente      
      if @w_error != 0
       begin
          return @w_error
       end
  end
 commit tran
end

/* Eliminacion de registros */
/****************************/
if @i_operacion = 'D'
begin
if @w_existe = 0
begin  /* Registro a eliminar no existe */
   select @w_error = 2101005
   goto ERROR
end

exec @w_error = cob_credito..sp_de_tramite
    -- parametros de tran-server 
     @s_ssn,          
     @s_user,    
     @s_sesn,    
     @s_term,  
     @s_date, 
     @s_srv, 
     @s_lsrv,
     @s_rol,
     @s_ofi,
     @s_org_err,
     @s_error,
     @s_sev,
     @s_msg,
     @s_org,
     @t_rty,
     @t_trn,
     @t_debug,
     @t_file,
     @t_from,
    --parametros de input
     @i_operacion,
     @i_tramite,
     @i_toperacion,
    -- valores del registro actual
    -- registro anterior
     @w_tipo,
     @w_oficina_tr,
     @w_usuario_tr,
     @w_fecha_crea,
     @w_oficial,
     @w_sector,
     @w_ciudad,
     @w_estado,
     @w_numero_op,
     @w_numero_op_banco,
     @w_proposito,
     @w_razon,
     @w_txt_razon,
     @w_efecto,
     @w_cliente,
     @w_grupo,
     @w_fecha_inicio,
     @w_num_dias,
     @w_per_revision,
     @w_condicion_especial,
     @w_linea_credito,
     @w_toperacion,
     @w_producto,
     @w_monto,
     @w_moneda,
     @w_periodo,
     @w_num_periodos,
     @w_destino,
     @w_ciudad_destino,
     @w_renovacion,
     @i_tran_servicio    --DAG
if @w_error != 0
    goto ERROR  --PQU integracion   
    return 0    --PQU integracion cambio de 1 por 0
end

/* Consulta opcion QUERY */
/*************************/
if @i_operacion = 'Q'
begin
  select @w_tipo    = tr_tipo,
         @w_cliente = tr_cliente,
         @w_grupo   = tr_grupo
  from  cr_tramite
  where tr_tramite  = @i_tramite

  if @@rowcount = 0
   begin
   /*Registro no existe */
     select @w_error = 2101005
     goto ERROR
   end

  if @i_cliente is not null or @i_grupo is not null
  begin
    if @w_tipo in ('O', 'R', 'E', 'F')
     if @i_cliente is not null
      begin
        if not exists (select 1
                       from  cr_deudores
                       where de_tramite = @i_tramite
                       and de_cliente   = @i_cliente
                       and de_rol       = 'D')
                begin
                   /*Registro no existe */
                   select @w_error = 2101005
                   goto ERROR
                end
      end
        else
         begin
           /*Registro no existe */
           select @w_error = 2101005
           goto ERROR
         end
    if @w_tipo in ('L', 'P', 'G')
      if (@i_cliente != @w_cliente and @i_grupo != @w_grupo ) or
         (@i_cliente != @w_cliente and @i_grupo is null) or
         (@i_grupo != @w_grupo and @i_cliente is null)
          begin
           select @w_error = 2101005
           goto ERROR
          end
   end

   select @w_sp_name1 = 'cob_credito..sp_query_tramite'

   exec @w_error           = @w_sp_name1 --sp_query_tramite
        @s_user            = @s_user,
        @t_debug           = @t_debug,
        @t_file            = @t_file,
        @t_from            = @t_from,
        @i_tramite         = @i_tramite,
        @i_numero_op_banco = @i_numero_op_banco,
        @i_linea_credito   = @i_linea_credito,
        @i_producto        = @i_producto,
        @i_es_acta         = @i_es_acta,
        @i_formato_fecha   = @i_formato_fecha    --LIM 30/Mar/2006
        if @w_error != 0 goto ERROR

   -- PASAR LAS FORMAS DE PAGO A LA TABLA TEMPORAL, PUES SE LE DA MANTENIMIENTO DESDE CREDITO
  if @w_tipo in ('O', 'R', 'E', 'F')  --PQU integración revisar quitar comentario
   begin
      select @w_operacionca = op_operacion
        from cob_cartera..ca_operacion
       where op_tramite = @i_tramite
   end 
end

/* Consulta opcion QUERY */
/*************************/
if @i_operacion = 'W'
begin
   -- PASAR LAS FORMAS DE PAGO A LA TABLA TEMPORAL, PUES SE LE DA MANTENIMIENTO DESDE CREDITO
   if @w_tipo in ('O', 'R', 'E', 'F')
   begin
      select @w_operacionca = op_operacion
      from cob_cartera..ca_operacion
      where op_tramite = @i_tramite           
   end
end

/* Consulta opcion M */
/*************************/
if @i_operacion = 'M'
begin
    if @i_toperacion is not null and @i_moneda is not null
        select @w_monto_max  = dt_monto_max
          from cob_cartera..ca_default_toperacion
         where dt_toperacion = @i_toperacion
           and dt_moneda     = @i_moneda
    --Retorna el valor al frontend
    select @w_monto_max
end

delete cr_cotiz3_tmp where spid = @w_spid
return 0

ERROR:
   --Devolver mensaje de Error
   if @i_canal in (0,1) --Frontend o batch
    begin
     exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = @w_error,
		   @i_msg   = @w_msg_error
     return @w_error
    end
   else
     return @w_error

go