/************************************************************************/
/*    Archivo:                up_tramite.sp                            	*/
/*    Stored procedure:    sp_up_tramite_busin                          */
/*    Base de Datos:        cob_credito                            		*/
/*    Producto:               Credito                                   */
/*    Disenado por:        Myriam Davila                          		*/
/*    Fecha de Documentacion: 10/Nov/95                              	*/
/***********************************************************************/
/*            IMPORTANTE                              					*/
/*    Este programa es parte de los paquetes bancarios propiedad de  	*/
/*    'MACOSA',representantes exclusivos para el Ecuador de la       	*/
/*    AT&T                                   							*/
/*    Su uso no autorizado queda expresamente prohibido asi como     	*/
/*    cualquier autorizacion o agregado hecho por alguno de sus      	*/
/*    usuario sin el debido consentimiento por escrito de la         	*/
/*    Presidencia Ejecutiva de MACOSA o su representante           		*/
/************************************************************************/
/*            PROPOSITO                       							*/
/*    Este stored procedure:                           					*/
/*    actualiza un registro en la tabla cr_tramite                		*/
/*                                       								*/
/************************************************************************/
/*            MODIFICACIONES                       						*/
/*    FECHA        AUTOR            RAZON               				*/
/*    10/Nov/95    Myriam Davila       Emision Inicial           		*/
/*    17/Dic/97    Myriam Davila       Upgrade Cartera           		*/
/*      06/Oct/01       Susana Paredes     Eliminacion de campos clasif	*/
/*                                   y exceso en gp, ciudad_dest a int 	*/
/*    07/Abr/05    Vivi Arias        Agrega parametros      			*/
/*    08/Nov/06    Vivi Arias       Borra operaci¢n de Cartera si		*/
/*                                         se cambia producto.         	*/
/*      06/Ene/07       Viviana Arias      Hereda numero de linea para 	*/
/*                                         reestructuraciones.         	*/
/*      25/Abr/07       Viviana Arias   Agrega campo linea de Sob-VISA 	*/
/*                                      para refinanciamientos.        	*/
/*      12/Jul/07       Sandra Robayo   CD00237                        	*/
/*      13/Ago/07       Sandra Robayo   Actualiza campo de tr_truta    	*/
/*                                      CD00242                        	*/
/*     03/oct/07       Mirna Gonzalez   Gap - Subsidio Lineas de cred  	*/
/*     11/MAR/09       Fdo Carvajal   Revision de Clientes para Grupos 	*/
/*     25-Mar-2009     Sandra Robayo  Se ingresa el campo que indica si	*/
/*                                  la operacion de factoring es compra-*/
/*                                  da por el banco o no.               */
/*                                     FACTORING.                      	*/
/*      10-Abr-2015     Nancy Martillo Se agregan campos query para    	*/
/*                                     datos adicionales           		*/
/*      26-May-2015    Tania Suárez    En Prorroga se permite modificar */
/*                                     codeudores                      	*/
/*                                     datos adicionales               	*/
/*      26-May-2015     Nancy Martillo Se agregan campos update para    */
/*                                     cr_liquida                       */
/*      29/Sept/2015    Mariela Cabay  Se agrega Obsrv  reprogramación 	*/
/*      07/May/2019     Felipe Borja   Int. orquestador originacion     */
/*      07/Ago/2019     Jose Escobar   Manejo de seguros                */
/************************************************************************/
use cob_credito
go
if exists (select * from sysobjects where name = 'sp_up_tramite_busin')
    drop proc sp_up_tramite_busin
go

create proc sp_up_tramite_busin (
   @s_ssn                      int = null,
   @s_user                     login = null,
   @s_sesn                     int = null,
   @s_term                     varchar(30) = null,
   @s_date                     datetime = null,
   @s_srv                      varchar(30) = null,
   @s_lsrv                     varchar(30) = null,
   @s_rol                      smallint =  null,
   @s_ofi                      smallint = null,
   @s_org_err                  char(1) = null,
   @s_error                    int = null,
   @s_sev                      tinyint = null,
   @s_msg                      descripcion = null,
   @s_org                      char(1) = null,
   @t_show_version             bit = 0, -- Mostrar la version del programa
   @t_rty                      char(1)  = null,
   @t_trn                      smallint = null,
   @t_debug                    char(1)  = 'N',
   @t_file                     varchar(14) = null,
   @t_from                     varchar(30) = null,

   @i_operacion                char(1) = null,
   @i_tramite                  int  = null,
   /* nuevo registro */
   @i_tipo                     char(1) = null,
   --@i_truta                  tinyint = null,
   @i_oficina_tr               smallint = null,
   @i_usuario_tr               login = null,
   @i_fecha_crea               datetime = null,
   @i_oficial                  smallint = null,
   @i_sector                   catalogo = null,
   @i_ciudad                   int = null,
   @i_estado                   char(1) = null,
   --@i_nivel_ap               tinyint = null,
   --@i_fecha_apr              datetime = null,
   --@i_usuario_apr            login = null,
   @i_numero_op_banco          cuenta  = null,
   @i_cuota                    money = null,
   @i_frec_pago                catalogo = null,
   @i_moneda_solicitada        tinyint = null,
   @i_provincia                int = null,
   @i_monto_solicitado         money       = null,
   @i_monto_desembolso         money         = null,
   @i_pplazo                   smallint = null,
   @i_tplazo                   catalogo = null,
   @i_proposito                catalogo = null,
   @i_razon                    catalogo= null,
   @i_txt_razon                varchar(255) = null,
   @i_efecto                   catalogo = null,
   @i_cliente                  int = null,
   @i_grupo                    int = null,
   @i_fecha_inicio             datetime = null,
   @i_num_dias                 smallint = 0,
   @i_per_revision             catalogo = null,
   @i_condicion_especial       varchar(255) = null,
   @i_rotativa                 char(1) = null,
   @i_linea_credito            cuenta = null,
   @i_toperacion               catalogo = null,
   @i_producto                 catalogo = null,
   @i_monto                    money = 0,
   @i_moneda                   tinyint = 0,
   @i_periodo                  catalogo = null,
   @i_num_periodos             smallint = 0,
   @i_destino                  catalogo = null,
   @i_ciudad_destino           int = null,
   --@i_cuenta_corriente       cuenta = null,
   --@i_garantia_limpia        char(1) = null,

   @i_reajustable              char(1) = null,
   @i_per_reajuste             tinyint = null,
   @i_reajuste_especial        char(1) = null,
   @i_fecha_reajuste           datetime = null,
   @i_cuota_completa           char(1) = null,
   @i_tipo_cobro               char(1) = null,
   @i_tipo_reduccion           char(1) = null,
   @i_aceptar_anticipos        char(1) = null,
   @i_precancelacion           char(1) = null,
   @i_tipo_aplicacion          char(1) = null,
   @i_renovable                char(1) = null,
   @i_fpago                    catalogo = null,
   @i_cuenta                   cuenta = null,
   @i_renovacion               smallint = null,
   @i_cliente_cca              int = null,
   @i_op_renovada              cuenta = null,
   @i_deudor                   int = null,
   -- reestructuracion
   @i_op_reestructurar         cuenta = null,
   -- Financiamientos SBU: 20/abr/2000

/*Nuevos Campos para Lfneas de CrTdito*/

   @i_destino_fondos           varchar(255) = null,
   @i_comision_tramite         float = null,
   @i_subsidio                 float = null,
   @i_tasa_aplicar             float = null,
   @i_tasa_efectiva            float = null,
   @i_plazo_desembolso         smallint = null,
   @i_forma_pago               varchar(255) = null,
   @i_plazo_vigencia           smallint = null,
   @i_origenfondos             varchar(255) = null,
   @i_formalizacion            catalogo = null,
   @i_cuenta_corrientelc       cuenta = null,
   -------------------------------
   /* registro anterior */
   @i_w_tipo                   char(1) = null,
   @i_w_truta                  tinyint = null,
   @i_w_oficina_tr             smallint = null,
   @i_w_usuario_tr             login = null,
   @i_w_fecha_crea             datetime = null,
   @i_w_oficial                smallint = null,
   @i_w_sector                 catalogo = null,
   @i_w_ciudad                 int = null,
   @i_w_estado                 char(1) = null,
   @i_w_nivel_ap               tinyint = null,
   --@i_w_fecha_apr            datetime = null,
   @i_w_usuario_apr            login = null,
   @i_w_numero_op_banco        cuenta  = null,
   @i_w_cuota                  money = null,
   @i_w_frec_pago              catalogo = null,
   @i_w_moneda_solicitada      tinyint = null,
   @i_w_provincia              int = null,
   @i_w_monto_solicitado       money = null,
   @i_w_monto_desembolso       money = null,
   @i_w_pplazo                 smallint = null,
   @i_w_tplazo                 catalogo = null,
   @i_w_numero_op              int = null,
   @i_w_proposito              catalogo = null,
   @i_w_razon                  catalogo = null,
   @i_w_txt_razon              varchar(255) = null,
   @i_w_efecto                 catalogo = null,
   @i_w_cliente                int = null,
   @i_w_grupo                  int = null,
   @i_w_fecha_inicio           datetime = null,
   @i_w_num_dias               smallint = 0,
   @i_w_per_revision           catalogo = null,
   @i_w_condicion_especial     varchar(255) = null,
   @i_w_linea_credito          int = null,
   @i_w_toperacion             catalogo = null,
   @i_w_producto               catalogo = null,
   @i_w_monto                  money = 0,
   @i_w_moneda                 tinyint = 0,
   @i_w_periodo                catalogo = null,
   @i_w_num_periodos           smallint = 0,
   @i_w_destino                catalogo = null,
   @i_w_ciudad_destino         int = null,
   @i_w_cuenta_corriente       cuenta = null,
   @i_w_garantia_limpia        char(1) = null,
   @i_w_renovacion             smallint = null,
   @i_w_plazo                  smallint = null,
   @i_sector_contable          catalogo = null,
   --@i_cupos_terceros         catalogo = null,
   --@i_tamano_empresa         catalogo = null,
   --@i_referencia_bmi         varchar(30) = null,
   --@i_unidad_medida          catalogo = null,
   --@i_tipo_empresa           catalogo = null,
   --@i_tipo_sector            catalogo = null,
   --@i_cantidad               int = null,
   @i_origen_fondo             catalogo = null,
   @i_fondos_propios           char(1)  = null,
  -- @i_clabas                 catalogo = null,
   --@i_claope                 catalogo = null,
   --@i_fecha_contrato         datetime = null,
   @i_plazo                    catalogo = null,
   --@i_uso_financiamiento    varchar(24) 	= null,
  -- @i_forma_cont             catalogo = null,
   --@i_dias_desembolso        smallint = null,
   --@i_fecha_ins_desembolso   datetime = null,
   @i_tram_anticipo            int = null,
   @i_revolvente               char(1) = null,
   @i_w_oficial_conta          smallint = null,
  -- @i_oficial_conta          smallint = null,
   @i_w_cem                    money = null,    --cem
   --@i_cem                    money = null,   --cem
   @i_causa                    char(1)     = null,  --Personalizacion Banco Atlantic
   @i_contabiliza              char(1)     = null,  --Personalizacion Banco Atlantic
   @i_tvisa                    varchar(24)     = null,  --Personalizacion Banco Atlantic
   @i_migrada                  cuenta         = null,     --RZ Personalizacion Banco Atlantic
   @i_tipo_linea               varchar(10)     = null,
   @i_plazo_dias_pago          int            = null,
   @i_tipo_prioridad           char(1)      = null,
   @i_linea_credito_pas        cuenta         = null,
   --@i_documento              varchar(10)     = null,
   @i_fdescuento               catalogo      = null,    --Vivi
   @i_cta_descuento            cuenta        = null,    --Vivi
   @i_proposito_op             catalogo      = null,    --Vivi
   @i_linea_cancelar           int             = null,
   @i_fecha_irenova            datetime        = null,
   @i_subtipo                  catalogo        = null,        --Vivi - CD00013
   @i_tipo_tarjeta             catalogo        = null,         --Vivi
   @i_motivo                   catalogo        = null,      --Vivi
   @i_plazo_pro                int             = null,             --Vivi
   @i_fecha_valor              char(1)         = null,             --Vivi
   @i_estado_lin               catalogo        = null,             --Vivi
   @i_subtplazo                catalogo       = null,
   @i_subplazos                smallint       = null,
   @i_subdplazo                int            = null,
   @i_subtbase                 varchar(1)     = null,
   @i_subporcentaje            float          = null,
   @i_subsigno                 char(1)        = null,
   @i_subvalor                 float          = null,
   @i_tasa_asociada            char(1)        = null,
   @i_tasa_prenda              float          = null,
   @i_tpreferencial            char(1)      = 'N',
   @i_porcentaje_preferencial  float     = null,
   @i_monto_preferencial       money       = 0,
   @i_abono_ini                money           = null,
   @i_opcion_compra            money         = null,
   @i_beneficiario             descripcion     = null,
   @i_financia                 char(1)       = null,
   --@i_medio                  int            = null,
   @i_ult_tramite              int            = null,
   @i_empleado                 int            = null,     --Vivi, C=digo del empleado para Tarjeta Corporativa
   @i_nombre_empleado          varchar( 40)   = null,     --Nombre del Empleado para Linea Visa
   @i_actsaldo                 char(1)        = 'N',
   --@i_compra_operacion       char(1)        = null,     -- SRO 25-MAR-2009 - indica si el banco compra operacion
   --@i_linea_can_sobvis       int            = null,
   @i_canal                    tinyint        = 0,         --Canal: 0=Frontend  1=Batch  2=workflow
   @i_destino_descripcion      descripcion   =null,
   @i_patrimonio               money=null,         --JMA, 02-Marzo-2015
   @i_ventas                   money=null,         --JMA, 02-Marzo-2015
   @i_num_personal_ocupado     int = null,      --JMA, 02-Marzo-2015
   @i_tipo_credito             catalogo =  null,
   @i_indice_tamano_actividad  float = null,    --JMA, 02-Marzo-2015
   @i_objeto                   catalogo = null, --JMA, 02-Marzo-2015
   @i_actividad                catalogo = null,             --JMA, 02-Marzo-2015
   @i_descripcion_oficial      descripcion = null, --JMA, 02-Marzo-2015
   @i_tipo_cartera             catalogo    = null,    --JMA, 02-Marzo-2015
   @i_ventas_anuales           money        = null,    --NMA, 10-Abril-2015
   @i_activos_productivos      money         = null,     --NMA, 10-Abril-2015
   @i_sector_cli               catalogo = null,  -- JCA, 05-Mayo-2015 ORI-H005-3 Activdad Analisis del Oficial / Sector y Actividad del Cliente
   @i_cuota_maxima             float    = null,    --NMA campo nuevo en cr_liquida
   @i_cuota_maxima_linea       float    = null,     --NMA campo nuevo en cr_liquida
   @i_expromision              catalogo = null,      --JES 05-Junio-2015

   @i_level_indebtedness       char(1) = null,   --DCA
   @i_asigna_fecha_cic         char(1) = null,
   @i_convenio                 char(1) =  null,
   @i_codigo_cliente_empresa   varchar(10)          = null,
   @i_reprogramingObserv       varchar(255)          = null,
   @i_motivo_uno               varchar(255)          = null, -- ADCH 05/10/2015 motivo para tipo de solicitud
   @i_motivo_dos               varchar(255)          = null, -- ADCH 05/10/2015 motivo para tipo de solicitud
   @i_motivo_rechazo           catalogo      =null,
   @i_valida_estado            char(1) ='S',
   @i_numero_testimonio        varchar(50)  = null,
   @i_tamanio_empresa          varchar(5)   = null,
   @i_producto_fie             catalogo     = null,
   @i_num_viviendas            tinyint      = null,
   @i_tipo_calificacion        catalogo     = null,
   @i_calificacion             catalogo     = null,
   @i_es_garantia_destino      char(1)      = null,
   @i_tasa                     float        = null,
   @i_sub_actividad            catalogo     = null,
   @i_departamento             catalogo     = null,
   @i_credito_es               catalogo     = null,
   @i_financiado               char(2)      = null,
   @i_presupuesto              money        = null,
   @i_fecha_avaluo             datetime     = null,
   @i_valor_comercial          money        = null,
   --CAMPOS AUMENTADOS EN INTEGRACION FIE
   @i_actividad_destino        catalogo=null,       --SPO Actividad economica de destino
   @i_parroquia                catalogo = null,   -- ITO:12/12/2011
   @i_canton                   catalogo     = null,
      @i_barrio                catalogo     = null,
   @i_toperacion_ori           catalogo = null,     -- Se incrementa por tema de interceptor
   @i_dia_fijo                 smallint,
   @i_enterado                 catalogo,
   @i_otros_ent                varchar(64),
   -- FBO Tabla Amortizacion
   @i_pasa_definitiva          char(1)      = 'S',
   @i_regenera_rubro           char(1)      = 'S',
   -- Manejo de seguros
   @i_seguro_basico            char(1)      = 'X', -- (S/N/X) - S=Crea el Seguro, N:Elimina el Seguro, X:No hace nada
   @i_seguro_voluntario        char(1)      = 'X', -- (S/N/X) - S=Crea el Seguro, N:Elimina el Seguro, X:No hace nada
   @i_tipo_seguro              catalogo     = null
)
as
declare
   @w_today                    datetime,     /* fecha del dia */
   @w_return                   int,          /* valor que retorna */
   @w_sp_name                  varchar(32),  /* nombre stored proc*/
   @w_existe                   tinyint,      /* existe el registro*/
   @w_tramite                  int,
   @w_linea_credito            int ,    /* renovaciones y operaciones */
   @w_numero_linea             int,
   @w_numero_operacion         int,
   @w_numero_op_banco          cuenta,
   /* cambios al registro anterior **/
   @w_cambio                   char(1),   /* existe un cambio */
   @w_cambio_def               char(1),   /* existe cambio en parametros default */
   @w_default                  char(1),
   @w_monto_desembolso         money,
   /* valores default para operaciones de cartera **/
   @w_dt_reajustable           char(1),
   @w_dt_periodo_reaj          tinyint,
   @w_dt_reajuste_especial     char(1),
   @w_dt_cuota_completa        char(1),
   @w_dt_tipo_cobro            char(1),
   @w_dt_tipo_reduccion        char(1),
   @w_dt_aceptar_anticipos     char(1),
   @w_dt_precancelacion        char(1),
   @w_dt_tipo_aplicacion       char(1),
   @w_dt_renovacion            char(1),
   @w_dt_plazo_contable        catalogo,

   /* numero de banco e interno para tabla temporal de cartera */
   @w_banco                    cuenta,
   @w_operacion                int,
   @w_fecha_ini                varchar(10),
   @w_periodo                  catalogo,
   @w_des_periodo              descripcion,
   @w_num_periodos             int,
   @w_val_tasaref              float,
   @w_nombre_cli_cca           descripcion,    --optimizacion de CCA --RZ
   @w_op_reestructurar         cuenta,            --operacion anterior
   @w_tramite_rest             int,    -- tramite de operacion a reestructurar
   @w_cliente_rest             int,    -- deudor de operacion a reestructurar
   @w_monto_rest               money,     -- monto inicial de operacion a reestructurar
   @w_moneda_rest              tinyint, -- moneda de operacion a reestructurar
   @w_saldo_rest               money,      -- saldo de operacion a reestructurar
   @w_fecha_liq_rest           datetime, -- fecha de liquidacion de op. a reestructurar
   @w_toperacion_rest          catalogo,  -- tipo de prestamo de operacion a reestructurar
   @w_operacion_rest           int,       -- numero secuencial de operacion a reestructurar
   @w_operacion_rest_ant       int,       -- numero secuencial de operacion a reestructurar anterior
   @w_sector_contable          catalogo,    --MVI 25/09/98 correccion
   @w_cupos_terceros           catalogo,
   @w_tamano_empresa           catalogo,
   @w_referencia_bmi           varchar(30),
   @w_unidad_medida            catalogo,
   @w_tipo_empresa             catalogo,
   @w_tipo_sector              catalogo,
   @w_fecha_contrato           datetime,
   @w_origen_fondo             catalogo,
   @w_fondos_propios           char(1),
   @w_tram_anticipo            int,
   @w_ciudad                   int,
   @w_tr_linea_nw              int,
   @w_tr_linea_ol              int,
   --@w_tr_pgroup              catalogo,
   @w_de_cliente               int,
   @w_secuencial               int,
   @w_cedula_ruc               varchar(35),
   @w_de_rol                   catalogo,
   @w_fecha_fin                datetime,
   @w_tipo                     char(1),
   @w_tipo_prioridad           char(1),
   @w_operacionca              int,
   @w_subtipo                  catalogo,      --Vivi
   @w_acumulado_pro            smallint,      --Vivi
   @w_tipo_op                  char(1),
   @w_sec_poli                 int,
   @w_garantia_poliza          varchar(64),

   --SYR 13/AGO/2007 CD00242
   @w_estacion                 smallint,
   @w_etapa                    tinyint,
   @w_error                    int,          /* valor que retorna */
   @w_prioridad                tinyint,
   @w_paso                     tinyint,
   @w_li_grupo                 int,            -- FCP 11/MAR/2009 Revision de Clientes para Grupos
   @w_dias                     int,
   @w_tipo_aplica_reest        char(1),
   @w_destino_reest            catalogo,
   @w_financia                 char(1),
   @w_abono_ini                money,
   @w_opcion_compra            money,
   @w_beneficiario             descripcion,
   @w_oficina_tr               int,
   @w_tipo_seg_basico          catalogo



select     @w_today  = isnull(@s_date, fp_fecha)
from    cobis..ba_fecha_proceso
select     @w_sp_name = 'sp_up_tramite_busin'



if @t_show_version = 1
begin
    print 'Stored procedure sp_up_tramite_busin, Version 4.0.0.2'
    return 0
end
/* Verificaciones Previas **********/

print 'LLEGA UP_TRAMITE:' + @i_operacion +' - LINEA DE CREDITO:'+ @i_linea_credito +'- i_w_estado: '+ @i_w_estado
-- Chequeo de Linea de Credito
if @i_linea_credito is not null
begin
    select    @w_numero_linea  = li_numero,
            @w_acumulado_pro = li_acumulado_prorroga,    --Vivi
            @w_tr_linea_nw   = li_tramite,                  --, Verifica deudores
            @w_li_grupo      = li_grupo            -- FCP 11/MAR/2009 Revision de Clientes para Grupos
    from       cob_credito..cr_linea
    where    li_num_banco = @i_linea_credito

    if @@rowcount = 0
    begin
    /* registro no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2101010
        return 1
    end
end

if @i_producto = 'CCA'
begin
    select --@w_dt_plazo_contable = op_plazo_contable,--TCRM
           @w_tipo_op           = op_tipo
    from cob_cartera..ca_operacion
    where op_tramite = @i_tramite

   select @w_nombre_cli_cca = en_nomlar        --RZ
   from      cobis..cl_ente
   where  en_ente = @i_cliente_cca
end

/* Chequeo de Numero de operacion */
if @i_numero_op_banco is not null
begin
    if @i_producto = 'CCA'
    begin
        select    @w_numero_operacion = op_operacion
        from       cob_cartera..ca_operacion
        where    op_banco = @i_numero_op_banco

        if @@rowcount = 0
        begin
        --operacion referenciada no existe
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
          @i_num   = 2101021
            return 1
        end
    end

    if @i_producto = 'CEX'
    begin
        select    @w_numero_operacion = op_operacion
        from       cob_comext..ce_operacion
        where    op_operacion_banco = @i_numero_op_banco

        If @@rowcount = 0
        begin
        /*operacion referenciada no existe */
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2101021
            return 1
        end
    end
end


/*======= OPERACION DE DOCUMENTOS DESCONTADOS =======**/
if @w_tipo = 'D' and exists (select 1 from cob_credito..cr_facturas where fa_tramite = @i_tramite)
begin
   select @i_monto = sum(isnull(fa_valor,0))
     from cr_facturas
    where fa_tramite = @i_tramite

   select @i_fecha_inicio = min(fa_fecini_neg)
     from cr_facturas
    where fa_tramite = @i_tramite
end
/*======= FIN OPERACION DE DOCUMENTOS DESCONTADOS =======**/


/* Control de modificaciones una vez que el tramite ya ha sido aprobado **/
If @i_w_estado = 'A' and @i_valida_estado='S'
begin
    /* inicializacion de variables */
    select @w_cambio = 'N',@w_cambio_def = 'N', @w_default = 'N'
    /* COMPARAR CAMPOS ANTERIORES CON NUEVOS */
    if @i_sector != @i_w_sector select @w_cambio = 'S'
    /* garantias */
    if @i_proposito != @i_w_proposito select @w_cambio = 'S'
    if @i_razon != @i_w_razon select @w_cambio = 'S'
    if @i_efecto != @i_w_efecto select @w_cambio = 'S'
    /* lineas de credito */
    if @i_cliente != @i_w_cliente select @w_cambio = 'S'
    if @i_grupo != @i_w_grupo select @w_cambio = 'S'
    if @i_num_dias > @i_w_num_dias select @w_cambio = 'S'
    if @i_per_revision != @i_w_per_revision select @w_cambio = 'S'
 if @i_condicion_especial != @i_w_condicion_especial select @w_cambio = 'S'
      -- if @i_fecha_contrato != @i_fecha_contrato select @w_cambio = 'S'
    --originales y renovaciones
    if @i_w_linea_credito is not null and @i_linea_credito is null select @w_cambio = 'S'
    if @i_toperacion != @i_w_toperacion select @w_cambio = 'S'
    if @i_producto != @i_w_producto select @w_cambio = 'S'
    if @i_monto > @i_w_monto select @w_cambio = 'S'
    if @i_moneda != @i_w_moneda select @w_cambio = 'S'
    if @i_periodo != @i_w_periodo select @w_cambio_def = 'S'
    if @i_num_periodos != @i_w_num_periodos select @w_cambio_def = 'S'
    if @i_destino != @i_w_destino select @w_cambio = 'S'
    --if @i_garantia_limpia != @i_w_garantia_limpia select @w_cambio = 'S'
    if @i_renovacion != @i_w_renovacion select @w_cambio = 'S', @w_default = 'N'

    if @i_producto = 'CCA'
    begin
        select @w_default = 'S'
        /* comparar con los valores de cartera */
        /* (1) traer los valores anteriores de cartera */
       select
        @w_dt_reajustable = op_reajustable,
        @w_dt_periodo_reaj = op_periodo_reajuste,
        @w_dt_reajuste_especial = op_reajuste_especial,
        @w_dt_renovacion = op_renovacion,
        @w_dt_precancelacion = op_precancelacion,
        @w_dt_cuota_completa = op_cuota_completa,
        @w_dt_tipo_cobro = op_tipo_cobro,
        @w_dt_tipo_reduccion = op_tipo_reduccion,
        @w_dt_aceptar_anticipos = op_aceptar_anticipos,
        @w_dt_tipo_aplicacion = op_tipo_aplicacion/*,
    @w_dt_plazo_contable = op_plazo_contable,
        @w_tipo_prioridad  = op_tipo_prioridad*/--TCRM
        from cob_cartera..ca_operacion
        where op_tramite = @i_tramite

        if @@rowcount > 0
          if @w_dt_reajustable = @i_reajustable and
       @w_dt_periodo_reaj = @i_per_reajuste and
             @w_dt_reajuste_especial = @i_reajuste_especial and
             @w_dt_renovacion = @i_renovable and
             @w_dt_precancelacion = @i_precancelacion and
             @w_dt_cuota_completa =@i_cuota_completa and
             @w_dt_tipo_cobro = @i_tipo_cobro and
             @w_dt_tipo_reduccion = @i_tipo_reduccion and
             @w_dt_aceptar_anticipos = @i_aceptar_anticipos and
             @w_dt_tipo_aplicacion = @i_tipo_aplicacion and
                    @w_tipo_prioridad  = @i_tipo_prioridad
                 select @w_cambio_def = 'N'
          else
                 select @w_cambio_def = 'S'
    end
    if @w_cambio_def = 'S'    select @w_cambio = 'S'
-- si ha existido cambio, entonces cambiar el estado a 'N' (no aprobado) */
--SAL 17/09/1999
   if @w_cambio = 'S'
     select @i_estado = 'N'
    else
    select @i_estado = @i_w_estado
end
else
 select @i_estado = @i_w_estado

 /*if @i_tipo = 'L' or @i_tipo = 'P'
    begin
       select @i_toperacion = @i_tipo_linea

       if @i_cliente is not null
           select @w_tr_pgroup = '0' --MSU en_product_group
           from cobis..cl_ente
           where en_ente = @i_cliente---Jch eliminacion de campos en cr_tramite

       if @i_grupo is not null
           select @w_tr_pgroup = '0' --MSU gr_product_group
           from cobis..cl_grupo
           where gr_grupo = @i_grupo
     end
     else
        select @w_tr_pgroup = null*/

-- EN PRORROGA EL tr_renovacion no se actualiza.
-- --------------------------------------------
if @i_tipo = 'P'
    select @i_renovacion = @i_w_renovacion

/*===============================================================================**/
/*--  SI EL TRAMITE TIENE ASOCIADA UNA LINEA, VERIFICA QUE LOS DEUDORES DE  LA    --**/
/*--  LINEA SEAN LOS MISMOS QUE LOS DEL TRAMITE, SINO, NO SE PERMITE LA TRN.   --**/
if @i_linea_credito is not null
BEGIN

   /* FCP 11/MAR/2009 BUSCAR EN EL REGISTRO DE GRUPO */
   if @w_li_grupo is not null
   begin
         if exists ( select 1 from cr_deudores where de_tramite = @i_tramite
                     and de_cliente not in (select en_ente from cr_deudores,cobis..cl_ente where de_tramite = @w_tr_linea_nw and de_cliente = en_grupo) )
         begin
              exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2101070
              return 1
         end

   end
   else
   --FIN FCP 11/MAR/2009
         if exists ( select 1 from cr_deudores where de_tramite = @i_tramite and de_cliente != @i_deudor and de_rol = 'D')
--                     and de_cliente not in (select de_cliente from cr_deudores where de_tramite = @w_tr_linea_nw) )
         begin
              exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2101070
              return 1
         end
END
/*===============================================================================**/

/* Actualizacion del Registro ***/
begin tran

     --Si se actualiza el tramite con adelanto = 0 debe eliminar las referencia en cr_anticipo */
     --SYR 12/Jul/2007 CD00237

     /*if @i_tram_anticipo = 0
     begin

         delete from cr_anticipo
         where an_tram_anticipo = @i_tramite

     end */

     --SYR 13/Ago/2007 CD00242
     -- recuperar la ruta anterior, para verificar si hubo cambio de ruta

     --select @i_w_truta = tr_truta
     --from cr_tramite
     --where tr_tramite = @i_tramite

    --Se saca los valores anteriores de cuota y frecuencia de pago del tramite*/
     select @i_w_cuota = tr_cuota,
            @i_w_frec_pago = tr_frec_pago,
            @i_w_moneda_solicitada = tr_moneda_solicitada,
 @i_w_provincia = tr_provincia,
            @i_w_monto_solicitado = tr_monto_solicitado,
            @i_w_monto_desembolso = tr_monto_desembolso,
            @i_w_pplazo = tr_plazo,
            @i_w_tplazo  = tr_tplazo,
            @i_w_oficina_tr = tr_oficina

     from cr_tramite
     where tr_tramite = @i_tramite
     if @i_producto is not null and @i_producto != @i_w_producto and @i_w_producto = 'CCA' and @i_tipo in ('O', 'R', 'F')
     begin

          select @w_banco = convert( varchar, @i_tramite)
     /*exec @w_return = cob_cartera..sp_borra_operacion
               @i_banco         = @w_banco,
               @i_borra_tramite = 'N',
               @i_en_linea      = 'S'
          if @w_return != 0
          begin
              exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2101021
              return 1
          end*/
      select @w_banco = null
     end

     --RECUPERA EL NUMERO DE LA LINEA DE CREDITO

     --Se obtiene el numero de linea para que no se borre en el DESEMBOLSO
    if @i_tipo = 'O'
        select @w_numero_linea = isnull( @w_numero_linea,tr_linea_credito)
        from cr_tramite
        where tr_tramite = @i_tramite

    if @i_tipo = 'E'
        select @w_numero_linea = isnull( @w_numero_linea,tr_linea_credito),
               @i_linea_credito= isnull( @i_linea_credito,op_lin_credito)
          from cr_tramite, cob_cartera..ca_operacion
         where tr_tramite = @i_tramite
           and op_tramite = tr_tramite



        update     cr_tramite
        set tr_estado               = isnull(@i_estado,tr_estado),
            tr_oficina              = isnull(@i_oficina_tr,tr_oficina),
            tr_oficial              = isnull(@i_oficial,tr_oficial),
            tr_ciudad               = isnull(@i_ciudad,tr_ciudad),
            tr_numero_op            = isnull(@w_numero_operacion,tr_numero_op),
            tr_numero_op_banco      = isnull(@i_numero_op_banco,tr_numero_op_banco),
            tr_cuota                = isnull(@i_cuota,tr_cuota),
            tr_frec_pago            = isnull(@i_frec_pago,tr_frec_pago),
            tr_moneda_solicitada    = isnull(@i_moneda_solicitada,tr_moneda_solicitada),
            tr_provincia            = isnull(@i_provincia,tr_provincia),
            tr_monto_solicitado     = isnull(@i_monto_solicitado,tr_monto_solicitado),
            tr_monto_desembolso     = isnull(@i_monto_desembolso,tr_monto_desembolso),
            tr_plazo                = isnull(@i_pplazo,tr_plazo),
            tr_tplazo               = isnull(@i_tplazo,tr_tplazo),
            tr_sector               = isnull(@i_sector,tr_sector),
            tr_proposito            = isnull(@i_proposito,tr_proposito),
            tr_razon                = isnull(@i_razon,tr_razon),
            tr_txt_razon            = isnull(@i_txt_razon,tr_txt_razon),
            tr_efecto               = isnull(@i_efecto,tr_efecto),
            tr_cliente              = isnull(@i_cliente,tr_cliente),
            tr_grupo                = isnull(@i_grupo,tr_grupo),
            tr_fecha_inicio         = isnull(@i_fecha_inicio,tr_fecha_inicio),
            tr_num_dias             = isnull(@i_num_dias,tr_num_dias),
            tr_per_revision         = isnull(@i_per_revision,tr_per_revision),
            tr_condicion_especial   = isnull(@i_condicion_especial,tr_condicion_especial),
            tr_linea_credito        = @w_numero_linea,
            tr_toperacion           = isnull(@i_toperacion,tr_toperacion),
            tr_producto             = isnull(@i_producto,tr_producto),
            tr_monto                = isnull(@i_monto,tr_monto),
            tr_moneda               = isnull(@i_moneda,tr_moneda),
            tr_periodo              = isnull(@i_periodo,tr_periodo),
            tr_num_periodos         = isnull(@i_num_periodos,tr_num_periodos),
            tr_ciudad_destino       = isnull(@i_ciudad_destino,tr_ciudad_destino),
            tr_renovacion           = isnull(@i_renovacion,tr_renovacion),
            tr_sector_contable      = isnull(@i_sector_contable,tr_sector_contable),
            tr_destino              = isnull(@i_destino,tr_destino),
            tr_causa                = isnull(@i_causa,tr_causa),        --Personalizaci=n Banco Atlantic
            --tr_pgroup             = @w_tr_pgroup,
            tr_lin_comext           = isnull(@i_linea_credito_pas,@i_linea_credito_pas),
            tr_proposito_op         = isnull(@i_proposito_op,tr_proposito_op),    --Vivi
            tr_fecha_irenova        = isnull(@i_fecha_irenova,tr_fecha_irenova),
            tr_linea_cancelar       = isnull(@i_linea_cancelar,tr_linea_cancelar),
            --tr_fecha_contrato     = @i_fecha_contrato,   --Vivi
            tr_tasa_asociada        = isnull(@i_tasa_asociada,tr_tasa_asociada),
            tr_origen_fondos        = isnull(@i_origen_fondo,tr_origen_fondos),
            tr_sector_cli           = isnull(@i_sector_cli,tr_sector_cli),
            tr_expromision          = isnull(@i_expromision,tr_expromision),
            tr_enterado             = isnull(@i_enterado,tr_enterado),
            tr_otros                = isnull(@i_otros_ent,tr_otros)
        where   tr_tramite = @i_tramite

    if @@error != 0
    begin
         --Error en actualizacion de registro
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2105001
             return 1
    end

    select @w_linea_credito = tr_linea_credito
           from cr_tramite
           where tr_tramite = @i_tramite
/*
  if(@w_linea_credito is not null and @i_tipo = 'L')
    begin
        update cob_credito..cr_linea
           set li_cuota_maxima = isnull(@i_cuota_maxima,li_cuota_maxima),
               li_cuota_maxima_linea = isnull(@i_cuota_maxima_linea,li_cuota_maxima_linea),
               li_plazo_vigencia = isnull(@i_plazo_vigencia,li_plazo_vigencia),
               li_tasa_aplicar = isnull(@i_tasa_aplicar,li_tasa_aplicar)
         where li_numero = @w_linea_credito
    END*/

    select @w_tramite = @i_tramite
    --Transaccion de Servicio Registro Anterior
    insert into ts_tramite
         (secuencial, tipo_transaccion, clase, fecha, usuario, terminal,
          oficina, tabla, lsrv, srv, tramite, tipo, oficina_tr, usuario_tr,
          fecha_crea, oficial, sector, ciudad, estado,
          --truta,
           numero_op, numero_op_banco, proposito, razon,
          txt_razon, efecto, cliente, grupo, fecha_inicio, num_dias, per_revision,
          condicion_especial, linea_credito, toperacion, producto,
          monto, moneda, periodo, num_periodos, destino, ciudad_destino,
          --cuenta_corriente, garantia_limpia, renovacion,oficial_conta,cem,pgroup,
          --cuota, frec_pago, moneda_solicitada, provincia, monto_solicitado, monto_desembolso,
          plazo) --, tplazo,sector_cli) --MIB solicitud generica  COBIS5
    values
        (@s_ssn, @t_trn, 'P', getdate(), @s_user, @s_term,
         @s_ofi, 'cr_tramite', @s_lsrv, @s_srv, @i_tramite, @i_w_tipo, @i_w_oficina_tr, @i_w_usuario_tr,
         @i_w_fecha_crea,@i_w_oficial, 'P', @i_w_ciudad, @i_w_estado,
         @i_w_numero_op, @i_w_numero_op_banco, @i_w_proposito, @i_w_razon,
         @i_w_txt_razon, @i_w_efecto, @i_w_cliente, @i_w_grupo, @i_w_fecha_inicio, @i_w_num_dias, @i_w_per_revision,
         @i_w_condicion_especial, @i_w_linea_credito, @i_w_toperacion, @i_w_producto,
         @i_w_monto, @i_w_moneda, @i_w_periodo, @i_w_num_periodos, @i_w_destino, @i_w_ciudad_destino,
         --@i_w_cuenta_corriente, @i_w_garantia_limpia, @i_w_renovacion, @i_w_oficial_conta ,@i_w_cem,@w_tr_pgroup,
         --@i_w_cuota, @i_w_frec_pago, @i_w_moneda_solicitada, @i_w_provincia, @i_w_monto_solicitado, @i_w_monto_desembolso,
         @i_w_pplazo) --, @i_w_tplazo,@i_sector_cli) --MIB solicitud generica  COBIS5
    if @@error != 0
    begin
         --Error en insercion de transaccion de servicio
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2103003
    return 1
    end
    /* Transaccion de Servicio Registro Actual */
    insert into ts_tramite
    (secuencial, tipo_transaccion, clase, fecha, usuario, terminal,
     oficina, tabla, lsrv, srv, tramite, tipo, oficina_tr, usuario_tr,
     fecha_crea, oficial, sector, ciudad, estado,
     --nivel_ap, fecha_apr,usuario_apr, truta,
     numero_op, numero_op_banco, proposito, razon,
     txt_razon, efecto, cliente, grupo, fecha_inicio, num_dias, per_revision,
     condicion_especial, linea_credito, toperacion, producto,
     monto, moneda, periodo, num_periodos, destino, ciudad_destino,
     --cuenta_corriente, garantia_limpia, renovacion,oficial_conta ,cem,
     --cuota, frec_pago, moneda_solicitada, provincia, monto_solicitado, monto_desembolso,
     plazo ) --, tplazo,sector_cli) --MIB solicitud generica  COBIS5
    values
    (@s_ssn, @t_trn, 'N', getdate(), @s_user, @s_term,
     @s_ofi, 'cr_tramite', @s_lsrv, @s_srv, @i_tramite, @i_tipo, @i_oficina_tr, @i_w_usuario_tr,
     @i_w_fecha_crea, @i_oficial, 'P', @i_ciudad, @i_estado,
     --@i_nivel_ap, @i_fecha_apr,@i_usuario_apr, @i_truta,
     @w_numero_operacion, @i_numero_op_banco, @i_proposito, @i_razon,
     @i_txt_razon, @i_efecto, @i_cliente, @i_grupo, @i_fecha_inicio, @i_num_dias, @i_per_revision,
     @i_condicion_especial, @w_numero_linea, @i_toperacion, @i_producto,
     @i_monto, @i_moneda, @i_periodo, @i_num_periodos, @i_destino, @i_ciudad_destino,
     --@i_cuenta_corriente, @i_garantia_limpia, @i_renovacion,@i_oficial_conta ,@i_cem,
     --@i_cuota, @i_frec_pago, @i_moneda_solicitada, @i_provincia, @i_monto_solicitado, @i_monto_desembolso,
     @i_pplazo) --, @i_tplazo,@i_sector_cli) --MIB solicitud generica  COBIS5

    if @@error != 0
    begin
         -- Error en insercion de transaccion deservicio
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1

    end
    /*  SE ACTUALIZAN LOS DATOS ADICIONALES DEL TRAMITE*/
        IF @i_tipo != 'M' AND @i_tipo != 'C'
    BEGIN
    --INTEGRACION CON FIE
    IF charindex('(',@i_actividad_destino)!=0
    BEGIN
        SELECT @i_sub_actividad = substring(@i_actividad_destino,charindex('(',@i_actividad_destino)+1,(charindex(')',@i_actividad_destino)-1)-(charindex('(',@i_actividad_destino)))
    END
    ELSE
    BEGIN
        SELECT @i_sub_actividad = @i_actividad_destino
    end

    SELECT @i_actividad = se_codActEc,
           @i_destino_descripcion = se_descripcion
        from cobis..cl_subactividad_ec
        WHERE se_codigo = @i_sub_actividad

    /*select @i_departamento = pv_depart_pais
    FROM cobis..cl_provincia
    WHERE pv_provincia = (
            SELECT ci_provincia
            FROM cobis..cl_ciudad
            WHERE ci_ciudad = CAST(@i_parroquia AS INT ))*/

    /*SELECT @i_departamento = dp_mnemonico FROM cobis..cl_depart_pais
        WHERE dp_departamento = (SELECT pv_depart_pais FROM cobis..cl_provincia
                            WHERE pv_provincia = (
                                SELECT ci_provincia
                                FROM cobis..cl_ciudad
                                WHERE ci_ciudad = CAST(@i_parroquia AS INT )))*/
    SELECT @i_departamento = pv_depart_pais FROM cobis..cl_provincia WHERE pv_provincia = @i_provincia


    exec @w_return = cob_credito..sp_tr_datos_adicionales
                    @s_ssn =@s_ssn,
                    @s_user = @s_user,
                    @s_sesn = @s_sesn,
                    @s_term = @s_term,
                    @s_date = @s_date,
                    @s_srv  = @s_srv,
                    @s_lsrv    = @s_lsrv,
                    @s_rol  = @s_rol,
                    @s_ofi  = @s_ofi,
                    @s_org_err = @s_org_err,
                    @s_error = @s_error,
                    @s_sev = @s_sev,
                    @s_msg = @s_msg,
                    @s_org = @s_org,
                    @t_rty = @t_rty,
                    @t_trn = 21118,
                    @t_debug = @t_debug,
                    @t_file  = @t_file,
                    @t_from  = @t_from,
                    @t_show_version = 0, -- Mostrar la version del programa
                    @i_operacion   ='U',
                    @i_tramite     =@i_tramite,
                    @i_tipo_cartera  = @i_tipo_cartera,
                    @i_destino_descripcion =@i_destino_descripcion,
                    @i_patrimonio =@i_patrimonio,
                    @i_ventas  = @i_ventas,
                    @i_num_personal_ocupado =@i_num_personal_ocupado,
                    @i_tipo_credito = @i_tipo_credito,
                    @i_indice_tamano_actividad =@i_indice_tamano_actividad,
                    @i_objeto  = @i_objeto ,
                    @i_actividad  = @i_actividad ,
                    @i_descripcion_oficial = @i_descripcion_oficial,
                    @i_ventas_anuales = @i_ventas_anuales,        --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales
                    @i_activos_productivos = @i_activos_productivos,        --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales

                    @i_level_indebtedness=@i_level_indebtedness,--DCA
                    @i_asigna_fecha_cic = @i_asigna_fecha_cic,

                    @i_convenio                 = @i_convenio    ,
                    @i_codigo_cliente_empresa=@i_codigo_cliente_empresa,
                    @i_reprogramingObserv		= @i_reprogramingObserv, -- MCA - se ingresa observación de la reprogramación
                    @i_motivo_uno = @i_motivo_uno,        -- ADCH, 05/10/2015 motivo para tipo de solicitud
                    @i_motivo_dos = @i_motivo_dos,         -- ADCH, 05/10/2015 motivo para tipo de solicitud
                    @i_motivo_rechazo = @i_motivo_rechazo,
                    @i_tamanio_empresa = @i_tamanio_empresa,
                    @i_producto_fie    = @i_producto_fie,
                    @i_num_viviendas   = @i_num_viviendas,
                    @i_tipo_calificacion   = @i_tipo_calificacion,
                    @i_calificacion        = @i_calificacion,
                    @i_es_garantia_destino = @i_es_garantia_destino,
                    @i_tasa             = @i_tasa,
                    @i_sub_actividad       = @i_sub_actividad,
                    @i_departamento        		= @i_departamento,
                    @i_credito_es           	= @i_credito_es,
                    @i_financiado           	= @i_financiado,
                    @i_presupuesto  	     	= @i_presupuesto,
                    @i_fecha_avaluo         	= @i_fecha_avaluo,
                    @i_valor_comercial       	= @i_valor_comercial

            if @w_return != 0
                    return @w_return
        END

    /* SI EL TRAMITE ES DE LINEA DE CREDITO ==> ACTUALIZAR REGISTRO DE LINEA */

    if @i_tipo = 'L'
    begin
        SELECT @w_dias = isnull( DATEDIFF(DAY,@i_fecha_crea,(DATEADD( MONTH, @i_num_dias, @i_fecha_crea))) , 0)
        declare @w_fecha_tmp datetime, @w_litipo catalogo
        set @w_fecha_tmp = isnull(@i_fecha_crea,@i_fecha_inicio)

        select @i_oficina_tr = isnull(@i_oficina_tr,@i_w_oficina_tr)  --Oficina del tramite inicial

        select @w_litipo = li_tipo from cob_credito..cr_linea where li_tramite = @i_tramite
        set @i_subtipo = isnull(@w_litipo,@i_subtipo)

        /*exec @w_return = cob_credito..sp_linea
             @s_ssn = @s_ssn,
             @s_user = @s_user,
             @s_sesn = @s_sesn,
             @s_term = @s_term,
             @s_date = @s_date,
             @s_srv  = @s_srv,
             @s_lsrv = @s_lsrv,
             @s_rol  = @s_rol,
             @s_ofi  = @s_ofi,
             @s_org_err = @s_org_err,
             @s_error = @s_error,
             @s_sev = @s_sev,
             @s_msg = @s_msg,
             @s_org = @s_org,
             @t_debug = @t_debug,
             @t_file = @t_file,
             @t_from = @t_from,
             @t_trn = 21126,
             @i_operacion = 'U',
             @i_numero = null,
             @i_num_banco = null,
             @i_oficina = @i_oficina_tr,
             @i_tramite = @i_tramite,
             @i_cliente = @i_cliente,
             @i_grupo   = @i_grupo,
             @i_original = null,
             -- @i_fecha_aprob = @i_fecha_apr,
             @i_fecha_inicio = @w_fecha_tmp,
             @i_per_revision = @i_per_revision,
             @i_fecha_vto    = null,
             @i_dias         = @i_num_dias, --@w_dias,--@i_num_dias,
             @i_condicion_especial = @i_condicion_especial,
             @i_monto        = @i_monto,
             @i_moneda       = @i_moneda,--@i_moneda_solicitada,
             @i_rotativa     = @i_rotativa,
             --@i_fecha_contrato   = @i_fecha_contrato,
             @i_revolvente       = @i_revolvente,
             @i_destino_fondos   = @i_destino_fondos,
             @i_comision_tramite = @i_comision_tramite,
             @i_subsidio         = @i_subsidio,
             @i_tasa_aplicar     = @i_tasa_aplicar,
             @i_tasa_efectiva    = @i_tasa_efectiva,
             @i_plazo_desembolso = @i_plazo_desembolso,
             @i_forma_pago =  @i_forma_pago,
             @i_plazo_vigencia = @i_plazo_vigencia,
             @i_origenfondos = @i_origenfondos,
             @i_formalizacion = @i_formalizacion,
             @i_cuenta_corrientelc = @i_cuenta_corrientelc,
             @i_contabiliza = @i_contabiliza, --Personalizaci=n Banco Atlantic
             @i_tvisa = @i_tvisa, --Personalizaci=n Banco Atlantic
             @i_plazo_dias_pago = @i_plazo_dias_pago,
             @i_subtipo         = @i_subtipo,        --Vivi - CD00013
             @i_tipo_tarjeta    = @i_tipo_tarjeta,    --Vivi - CD00013
             @i_tasa_prenda     = @i_tasa_prenda,     --Vivi
             @i_fecha_valor     = @i_fecha_valor,           --Vivi
             @i_empleado        = @i_empleado,         --Vivi
             @i_nombre_empleado = @i_nombre_empleado,
             @i_cuota_maxima    = @i_cuota_maxima,    --NMA campo nuevo en cr_liquida
             @i_cuota_maxima_linea = @i_cuota_maxima_linea,        --NMA campo nuevo en cr_liquida
             @i_numero_testimonio = @i_numero_testimonio
        if @w_return != 0
          return @w_return*/
    end
    --SI EL TRAMITE ES UNA PRORROGA DE LINEA
    if (@i_tipo = 'P')
    begin
        print 'TIPO TRAMITE:['+ @i_tipo +'] - MONTO SOLICITADO:[' + convert(varchar,@i_monto) +']'
        SELECT @w_dias = DATEDIFF(DAY,@i_fecha_inicio,(DATEADD( MONTH, @i_num_dias, @i_fecha_inicio)))

        declare @w_prtipo catalogo
    SELECT @w_prtipo = pr_tipo from cob_credito..cr_prorroga where pr_tramite = @i_tramite
    set @i_subtipo = isnull(@w_prtipo,@i_subtipo)
/*
        exec @w_return = cob_credito..sp_prorroga_linea
             @s_ssn = @s_ssn,
             @s_user = @s_user,
             @s_sesn = @s_sesn,
             @s_term = @s_term,
             @s_date = @s_date,
             @s_srv  = @s_srv,
             @s_lsrv = @s_lsrv,
             @s_rol  = @s_rol,
             @s_ofi  = @s_ofi,
             @s_org_err = @s_org_err,
             @s_error = @s_error,
             @s_sev = @s_sev,
             @s_msg = @s_msg,
             @s_org = @s_org,
             @t_debug = @t_debug,
             @t_file = @t_file,
             @t_from = @t_from,
             @t_trn = 21026,
             @i_operacion = 'U',
             @i_numero = @w_numero_linea,
             @i_num_banco = @i_linea_credito,
             @i_oficina = @i_oficina_tr,
             @i_tramite = @i_tramite,
             @i_cliente = @i_cliente,
             @i_grupo   = @i_grupo,
             @i_original = null,
             --@i_fecha_aprob = @i_fecha_apr,
             @i_fecha_inicio = @i_fecha_inicio,
             @i_per_revision = @i_per_revision,
             @i_fecha_vto = null,
             @i_dias = @w_dias, -- @i_num_dias,
             @i_condicion_especial = @i_condicion_especial,
             --@i_monto = @i_monto,
             @i_monto = @i_monto,
             @i_moneda = @i_moneda,
             @i_rotativa = @i_rotativa,
             -- @i_fecha_contrato = @i_fecha_contrato,
             @i_revolvente = @i_revolvente,
             @i_contabiliza = @i_contabiliza,
             @i_tvisa = @i_tvisa,
             @i_plazo_dias_pago = @i_plazo_dias_pago,
             @i_subtipo         = @i_subtipo,      --Vivi - CD00013
             @i_tipo_tarjeta    = @i_tipo_tarjeta,  --Vivi - CD00013
             @i_motivo          = @i_motivo,              --Vivi - CD00013
             @i_plazo_pro       = @i_plazo_pro,             --Vivi - CD00013
             @i_acumulado_pro   = @w_acumulado_pro,         --Vivi
             @i_fecha_valor     = @i_fecha_valor,           --Vivi
             @i_estado_lin      = @i_estado_lin,            --Vivi
             @i_tasa_prenda     = @i_tasa_prenda,           --Vivi
             @i_nombre_empleado = @i_nombre_empleado,
             @i_subsidio        = @i_subsidio,
             @i_cuota_maxima    = @i_cuota_maxima,
             @i_cuota_maxima_linea    = @i_cuota_maxima_linea,
             @i_tasa            = @i_tasa_aplicar,
             @i_numero_testimonio =  @i_numero_testimonio

        if @w_return != 0
          return @w_return*/

    end
  /* SI EL TRAMITE ES ORIGINAL/RENOVACION/FINANCIAMIENTO Y DE CARTERA */

    print 'LLEGA UP_TRAMITE  --i_tipo '+ @i_tipo +' --iproducto '+ @i_producto

    if (@i_tipo = 'O' or @i_tipo = 'R' or @i_tipo = 'F' or @i_tipo = 'E') and (@i_producto = 'CCA') -- ECA-2017 - La reestructuración genera la tabla en funcion de las nuevas condiciones (igual que una original)
    begin
 select @w_banco = op_banco,
               @w_operacionca = op_operacion,
               @w_monto_desembolso = op_monto,
               @w_periodo = td_tdividendo,
               @w_des_periodo = td_descripcion,
               @w_num_periodos = op_plazo,
               @w_val_tasaref = ro_porcentaje
        from   cob_cartera..ca_operacion,
               cob_cartera..ca_tdividendo,cob_cartera..ca_rubro_op
        where  op_tramite = @w_tramite
        and    td_tdividendo = op_tplazo
        and    ro_tipo_rubro = 'I'
        and    ro_operacion = op_operacion

              if @i_tipo = 'R'
                 select @i_fecha_inicio = @i_fecha_irenova

        select @i_oficina_tr = isnull(@i_oficina_tr,@i_w_oficina_tr)  --Oficina del tramite inicial

           /*ACTUALIZA LA OPERACION DE CARTERA **/

        exec @w_return          = sp_operacion_cartera_busin
                @s_user            = @s_user,
                @s_sesn            = @s_sesn,
                @s_ofi             = @s_ofi,
                @s_date            = @s_date,
                @s_term            = @s_term,
                @t_debug           = @t_debug,
                @t_file            = @t_file,
                @t_from            = @t_from,
                @i_transaccion     = 'I',
                @i_anterior        = @i_op_renovada,
                @i_num_renovacion  = @i_renovacion,
                @i_migrada         = @i_migrada,
                @i_tramite         = @i_tramite,
                @i_cliente         = @i_cliente_cca,
                @i_nombre          = @w_nombre_cli_cca,
                @i_sector          = @i_sector,
                @i_toperacion      = @i_toperacion,
                @i_toperacion_ori  = @i_toperacion_ori,
                @i_oficina         = @i_oficina_tr,
                @i_moneda          = @i_moneda,
                @i_comentario      = null,
                @i_oficial         = @i_oficial,
                @i_fecha_ini       = @i_fecha_inicio,
                @i_monto           = @i_monto_desembolso,
                @i_monto_aprobado  = @i_monto,
                @i_destino         = @i_destino,
                @i_lin_credito     = @i_linea_credito,
                @i_ciudad          = @i_ciudad,
                @i_ciudad_destino  = @i_ciudad_destino,   --DAG
                @i_forma_pago      = @i_fpago,
                @i_cuenta          = @i_cuenta,
                @i_formato_fecha   = 103,
                @i_no_banco        = 'N',
                @i_origen_fondo    = @i_origen_fondo,
                @i_fondos_propios  = @i_fondos_propios ,
                --@i_cupos_terceros  = @i_cupos_terceros,
                @i_sector_contable = @i_sector_contable,
                --@i_clabas          = @i_clabas,
                --@i_clabope         = @i_claope,
                --@i_dias_desembolso = @i_dias_desembolso,
                --@i_fecha_ins_desembolso = @i_fecha_ins_desembolso,
                @i_tipo_tr         = @i_tipo,      --tipo de tramite
                @i_plazo           = @i_pplazo,     --plazo
                @i_tplazo          = @i_tplazo,     --unidad de tiempo
                @i_plazo_con       = @i_plazo,
                @i_tipo_aplicacion = @i_tipo_aplicacion,
                @i_tipo_prioridad  = @i_tipo_prioridad,
                @i_tpreferencial   = @i_tpreferencial,
                @i_porcentaje_preferencial = @i_porcentaje_preferencial,
                @i_monto_preferencial = @i_monto_preferencial,
                @i_abono_ini       = @i_abono_ini,
                @i_opcion_compra   = @i_opcion_compra,
                @i_beneficiario    = @i_beneficiario,
                @i_financia        = @i_financia,

                @i_cuota_completa  = @i_cuota_completa,
                @i_tipo_cobro      = @i_tipo_cobro,
                @i_tipo_reduccion  = @i_tipo_reduccion,
                @i_aceptar_anticipos = @i_aceptar_anticipos,
                @i_precancelacion  = @i_precancelacion,
                @i_renovable       = @i_renovable,
                @i_reajustable     = @i_reajustable,
                @i_fecha_reajuste  = @i_fecha_reajuste,
                @i_per_reajuste    = @i_per_reajuste,
                @i_reajuste_especial= @i_reajuste_especial,

                @i_w_toperacion    = @i_w_toperacion,
                @i_w_moneda        = @i_w_moneda,
                @i_w_monto         = @i_w_monto,
                @i_w_sector        = @i_w_sector,
                @i_w_plazo         = @i_w_pplazo,
                @i_w_tplazo       =  @i_w_tplazo,
                @i_numero_banco    = @w_banco,
                @i_tasa_asociada   = @i_tasa_asociada,
                @i_tasa_prenda     = @i_tasa_prenda,
                --SRO FACTORING 08/ABR/2009
                --@i_compra_operacion = @i_compra_operacion
                @i_dia_fijo        = @i_dia_fijo,
                @i_pasa_definitiva = @i_pasa_definitiva,
                @i_regenera_rubro  = @i_regenera_rubro

       if @w_return != 0
        begin
            print 'DESPUES DEL sp_operacion_cartera  '+ convert(varchar, @w_return)
                return @w_return
            end

    end /* operacion de cartera */

    if (@i_tipo = 'O' or @i_tipo = 'R' or @i_tipo = 'F')

    begin

        if @w_numero_linea != @i_w_linea_credito
 begin
            --ELIMINACION DE LAS POLIZAS RELACIONADAS A LA LINEA ANTERIOR
            delete cob_custodia..cu_poliza_asociada where pa_tramite = @i_tramite
            -- ELIMINACION DE REGISTROS DE
            -- gar_propuesta por LINEA ANTERIOR
           if @i_w_linea_credito is not null
            begin
                select     @w_tr_linea_ol = li_tramite
                from    cr_linea
                where    li_numero = @i_w_linea_credito
                delete     cr_gar_propuesta
        where    gp_tramite = @i_tramite
                and    gp_garantia in (select     a.gp_garantia
                            from     cr_gar_propuesta a
                            where     gp_tramite = @w_tr_linea_ol)
                if @@error!= 0
                begin
                     /* Error en actualizacion de registro */
                         exec cobis..sp_cerror
                         @t_debug = @t_debug,
                         @t_file  = @t_file,
                         @t_from  = @w_sp_name,
                         @i_num   = 2105001
                     ROLLBACK
                         return 1
                end
            end
            if @w_numero_linea is not null
            begin
                select    @i_deudor = de_cliente
                from    cr_deudores
                where    de_tramite = @i_tramite
                and    de_rol = 'D'
                select     @w_tr_linea_nw = li_tramite
                from    cr_linea
                where    li_numero = @w_numero_linea


                insert into cr_gar_propuesta(
                   gp_tramite,        gp_garantia,
                   gp_abierta,        gp_deudor,
                   gp_est_garantia, gp_porcentaje,
                   gp_valor_resp_garantia, gp_saldo_cap_op )
                select distinct
                   @i_tramite,        gp_garantia,
                   cu_abierta_cerrada, @i_deudor,
                   cu_estado,          gp_porcentaje,
                   gp_valor_resp_garantia, gp_saldo_cap_op
                from     cob_credito..cr_gar_propuesta
                inner join cob_custodia..cu_custodia on gp_garantia = cu_codigo_externo and cu_estado not in ('A','C') -- No las Canceladas
                where    gp_tramite     = @w_tr_linea_nw
                    and    gp_garantia not in (select     a.gp_garantia
                                            from     cr_gar_propuesta a
                                            where    a.gp_tramite = @i_tramite )
                if @@error != 0
                begin
 ---Error en insercion de registro
                         exec cobis..sp_cerror
                         @t_debug = @t_debug,
                         @t_file  = @t_file,
                         @t_from  = @w_sp_name,
                         @i_num= 2103001
                     ROLLBACK
                         return 1
                end
            end
        end  --@w_numero_linea != @i_w_linea_credito


            -- DIEGO 17SEP2005
                -- ASOCIAR POLIZAS ATADAS A LA LINEA DE CREDITO
            -- AUTOMATICAMENTE AL NUEVO TRAMITE
            -- -----------------------------------------------------------------
            if @w_numero_linea is not null and @w_tr_linea_nw is not null
            begin
                   select @w_sec_poli = 0
                   while 1=1
                   begin
                        set rowcount 1
                        select @w_sec_poli = pa_secuencial
                        from cob_custodia..cu_poliza_asociada
                        where pa_tramite = @w_tr_linea_nw
                          and pa_secuencial > @w_sec_poli
                        order by pa_secuencial
                        if @@rowcount = 0
                        begin
                           set rowcount 0
                     break
                        end
                        set rowcount 0

                        --VERIFICA SI YA NO EXISTEN
                        if not exists(select 1 from cob_custodia..cu_poliza_asociada
              where pa_tramite = @i_tramite
                                       and pa_secuencial = @w_sec_poli)
                        begin
                           set rowcount 1
                           insert into cob_custodia..cu_poliza_asociada
                           (pa_secuencial, pa_tramite, pa_garantia)
                           select pa_secuencial, @i_tramite, pa_garantia
                           from cob_custodia..cu_poliza_asociada
                            where pa_secuencial = @w_sec_poli
                             and pa_tramite = @w_tr_linea_nw

                           set rowcount 0
                        end
                   end --1=1

                   /*RELACIONAR LAS GARANTIAS DE LA LINEA  */
      select @w_garantia_poliza = ''
                   while 1=1
                   begin
                      set rowcount 1
                      select @w_garantia_poliza = gp_garantia
                        from cob_credito..cr_gar_propuesta
                 where gp_tramite = @w_tr_linea_nw
                         and gp_garantia > @w_garantia_poliza
                       order by gp_garantia

                      if @@rowcount = 0
                       begin
                         set rowcount 0
                         break
                      end
                      set rowcount 0

                      --VERIFICA SI YA NO EXISTEN
                      if not exists(select 1 from cob_custodia..cu_poliza_asociada
                         where pa_tramite = @i_tramite
                                      and pa_garantia = @w_garantia_poliza)
                      begin
                         set rowcount 1
                         insert into cob_custodia..cu_poliza_asociada
                         (pa_secuencial, pa_tramite, pa_garantia)
                         select pa_secuencial, @i_tramite, pa_garantia
                         from cob_custodia..cu_poliza_asociada
                          where pa_garantia = @w_garantia_poliza
                           and pa_tramite != @i_tramite

                         set rowcount 0
                      end
                   end --1=1
            end
    end

    -- reestructuraciones

    /* ECA - 2017 - Se comenta porque en la reestructuracion ya no se copia la operación reestructurada, se genera la tabla en
    if @i_tipo = 'E'
    BEGIN
        select  @w_operacion = op_operacion
        from    cob_cartera..ca_operacion
        where   op_tramite = @i_tramite

        if isnull(@w_operacion,0) = 0
        begin

           /*TOMA DATOS DE LA NUEVA OPERACION BASE*/
           if @i_op_reestructurar is null
           begin
              select @w_error = 2101001
              return @w_error
           end
           select @w_tramite_rest = op_tramite,
                  @w_cliente_rest = op_cliente,
                  @w_monto_rest= op_monto_aprobado,
                  @w_moneda_rest  = op_moneda,
                  @w_fecha_liq_rest = op_fecha_liq,
                  @w_toperacion_rest = op_toperacion,
                  @w_operacion_rest = op_operacion,
                  @w_tipo_aplica_reest = op_tipo_aplicacion,
                  @w_destino_reest = op_destino,
                  @w_tipo_prioridad = op_tipo_prioridad,
                  @w_financia = op_financia,
                  @w_abono_ini =  op_abono_ini,
                  @w_opcion_compra = op_opcion_compra,
                  @w_beneficiario = op_beneficiario
           from cob_cartera..ca_operacion
           where op_banco = @i_op_reestructurar
           if @@rowcount = 0
           begin
              select @w_error = 2101010
              return @w_error
           end

           /*SE BORRA LA TABLA DE RENOVAR PORQUE SE VUELVEN A INGRESAR LUEGO*/
           delete cob_credito..cr_op_renovar where or_tramite = @i_tramite

           /*SE ASIGNA EL TRAMITE A LA VARIABLE*/
           select @w_banco = convert(varchar(24),@i_tramite)

           /*SE BORRA LAS TABLAS TEMPORALES*/
           exec  cob_cartera..sp_borrar_tmp
                 @s_user   = @s_user,
                 @s_sesn   = @s_sesn,
                 @i_banco= @w_banco

           /*CREA NUEVA OPERACION*/
           exec @w_error = sp_copia_operacion
                @s_ssn    = @s_ssn,
                @s_user    = @s_user,
                @s_sesn    = @s_sesn,
                @s_term    = @s_term,
                @s_date    = @s_date,
                @s_srv    = @s_srv,
                @s_lsrv    = @s_lsrv,
                @s_rol    = @s_rol,
                @s_ofi    = @s_ofi,
                @s_org_err    = @s_org_err,
                @s_error    = @s_error,
                @s_sev    = @s_sev,
                @s_msg    = @s_msg,
                @s_org    = @s_org,
                @t_rty    = @t_rty,
                @t_trn    = 21218,
                @t_debug    = @t_debug,
                @t_file    = @t_file,
                @t_from    = @t_from,
                @i_tipo    = @i_tipo,                        --MDU PARA REESTRUC CON OTRA MONEDA
                @i_moneda_solicitada = @i_moneda_solicitada, --MDU PARA REESTRUC CON OTRA MONEDA
                @i_tramite    = @i_tramite,
                @i_banco    = @i_op_reestructurar,
                @i_monto     = @i_monto
            if @w_error != 0
                return @w_error

           /*ACTUALIZACION DEL NUEVO REGISTRO*/
            -- actualizar destino y ciudad
            update cob_cartera..ca_operacion
            set
               op_destino           = @w_destino_reest,
               op_ciudad            = convert (int, @i_ciudad_destino),
               op_tipo_aplicacion   = @w_tipo_aplica_reest,
               op_tipo_prioridad    = @w_tipo_prioridad,
               op_financia          = @w_financia,
               op_abono_ini         = @w_abono_ini,
               op_opcion_compra     = @w_opcion_compra,
               op_beneficiario     = @w_beneficiario
            where op_tramite        = @i_tramite
            if @@rowcount = 0
            begin
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from = @w_sp_name,
                @i_num   = 2110328
                return 2110328
            end
        end
    END
    */

            -- obtener la operacion a reestructurar
            /*select @w_op_reestructurar = or_num_operacion
            from   cr_op_renovar
            where  or_tramite = @i_tramite

            -- verificar si cambio la operacion a reestructurar
            if @w_op_reestructurar = @i_op_reestructurar
            begin
                * ACTUALIZA LA OPERACION DE CARTERA *
                exec @w_return          = sp_operacion_cartera
                    @s_user            = @s_user,
                    @s_sesn            = @s_sesn,
                    @s_ofi             = @s_ofi,
                    @s_date            = @s_date,
                    @s_term            = @s_term,
                    @t_debug           = @t_debug,
                    @t_file            = @t_file,
                    @t_from            = @t_from,
                    @i_transaccion     = 'I',
                    @i_anterior        = @i_op_renovada,
                    @i_num_renovacion  = @i_renovacion,
                    @i_migrada         = @i_migrada,
                    @i_tramite         = @i_tramite,
                    @i_cliente         = @i_cliente_cca,
                    @i_nombre          = @w_nombre_cli_cca,
                    @i_sector          = @i_sector,
                    @i_toperacion      = @i_toperacion,
                    @i_toperacion_ori  = @i_toperacion_ori,
                    @i_oficina         = @i_oficina_tr,
                    @i_moneda          = @i_moneda,
                    @i_comentario      = null,
                    @i_oficial         = @i_oficial,
                    @i_fecha_ini       = @i_fecha_inicio,
                    @i_monto           = @i_monto_desembolso,
                    @i_monto_aprobado  = @i_monto,
                    @i_destino         = @i_destino,
                    @i_lin_credito     = @i_linea_credito,
                    @i_ciudad          = @i_ciudad,
                    @i_ciudad_destino  = @i_ciudad_destino,   --DAG
                    @i_forma_pago      = @i_fpago,
                    @i_cuenta         = @i_cuenta,
                    @i_formato_fecha   = 103,
                    @i_no_banco        = 'N',
                    @i_origen_fondo    = @i_origen_fondo,
                    @i_fondos_propios  = @i_fondos_propios ,
                   --@i_cupos_terceros  = @i_cupos_terceros,
                    @i_sector_contable = @i_sector_contable,
                    --@i_clabas          = @i_clabas,
                   -- @i_clabope         = @i_claope,
                    --@i_dias_desembolso = @i_dias_desembolso,
                    --@i_fecha_ins_desembolso = @i_fecha_ins_desembolso,
                    @i_tipo_tr         = @i_tipo,      --tipo de tramite
                    @i_plazo           = @i_pplazo,     --plazo
                    @i_tplazo          = @i_tplazo,     --unidad de tiempo
                    @i_plazo_con       = @i_plazo,
                    @i_tipo_aplicacion = @i_tipo_aplicacion,
                    @i_tipo_prioridad  = @i_tipo_prioridad,
                    @i_tpreferencial   = @i_tpreferencial,
                    @i_porcentaje_preferencial = @i_porcentaje_preferencial,
                    @i_monto_preferencial = @i_monto_preferencial,
                    @i_abono_ini       = @i_abono_ini,
                    @i_opcion_compra   = @i_opcion_compra,
                    @i_beneficiario    = @i_beneficiario,
                    @i_financia        = @i_financia,
                    @i_cuota_completa  = @i_cuota_completa,
                    @i_tipo_cobro      = @i_tipo_cobro,
                    @i_tipo_reduccion  = @i_tipo_reduccion,
                    @i_aceptar_anticipos = @i_aceptar_anticipos,
                    @i_precancelacion  = @i_precancelacion,
                    @i_renovable       = @i_renovable,
                    @i_reajustable     = @i_reajustable,
                    @i_fecha_reajuste  = @i_fecha_reajuste,
                    @i_per_reajuste    = @i_per_reajuste,
                    @i_reajuste_especial= @i_reajuste_especial,
                    @i_w_toperacion    = @i_w_toperacion,
                    @i_w_moneda        = @i_w_moneda,
                    @i_w_monto         = @i_w_monto,
                    @i_w_sector        = @i_w_sector,
                    @i_numero_banco    = @w_banco,
                    @i_tasa_asociada   = @i_tasa_asociada,
                    @i_tasa_prenda     = @i_tasa_prenda,
                    @i_actsaldo        = @i_actsaldo
                    --SRO FACTORING 08/ABR/2009
                   -- @i_compra_operacion = @i_compra_operacion --eliminacion de campos en cr_tramite

                if @w_return != 0
                  return @w_return */

/*       -- no cambio la operacion ==> actualizar ca_operacion
          update cob_cartera..ca_operacion
          set
              op_cliente        = @i_cliente_cca,
              op_destino        = @i_destino,
              op_ciudad            = convert (int, @i_ciudad_destino),
              op_fecha_reajuste     = @i_fecha_reajuste,
              op_periodo_reajuste     = @i_per_reajuste,
              op_reajuste_especial     = @i_reajuste_especial,
              op_forma_pago          = @i_fpago,
              op_cuenta         = @i_cuenta,
              op_cuota_completa     = @i_cuota_completa,
              op_tipo_cobro         = @i_tipo_cobro,
              op_tipo_reduccion     = @i_tipo_reduccion,
              op_aceptar_anticipos     = @i_aceptar_anticipos,
              op_precancelacion     = @i_precancelacion,
              op_tipo_aplicacion     = @i_tipo_aplicacion,
              op_renovacion        = @i_renovable,
              op_reajustable         = @i_reajustable,
              op_nombre            = @w_nombre_cli_cca,
              op_origen_fondo         = @i_origen_fondo,
              op_fondos_propios     = @i_fondos_propios,
              --op_cupos_terceros= @i_cupos_terceros,
              op_sector_contable     = @i_sector_contable,
              --op_clabas         = @i_clabas,
              --op_clabope         = @i_claope,
              op_tipo_prioridad         = @i_tipo_prioridad,
              op_abono_ini            = @i_abono_ini,
              op_opcion_compra            = @i_opcion_compra,
              op_beneficiario        = @i_beneficiario,
              op_financia        = @i_financia
          where op_tramite = @i_tramite

          if @@error != 0
          begin
                 exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 2103001,
             @i_msg     = '[sp_up_tramite_busin] ERROR EN ACTUALIZACION DE OPERACION EN CARTERA'

                return 1

          end*/


               -- si hubo cambio ==> regenerar los datos
                -- eliminar la operacion copia
                --(1) traer numero secuencial de operacion
                /*select @w_operacion_rest_ant = op_operacion
                from   cob_cartera..ca_operacion
                where  op_tramite = @i_tramite

                --(2) borrar las tablas
                delete cob_cartera..ca_operacion
              where op_tramite = @i_tramite
                delete cob_cartera..ca_amortizacion
                 where am_operacion = @w_operacion_rest_ant

                delete cob_cartera..ca_cuota_adicional
                 where ca_operacion = @w_operacion_rest_ant

                delete cob_cartera..ca_dividendo
                 where di_operacion = @w_operacion_rest_ant

                delete cob_cartera..ca_rubro_op
                 where ro_operacion = @w_operacion_rest_ant

                delete cob_cartera..ca_tasas
                 where ts_operacion = @w_operacion_rest_ant

                delete cob_cartera..ca_relacion_ptmo
                 where rp_pasiva = @w_operacion_rest_ant

                delete cob_cartera..ca_operacion_tmp
              where opt_banco = @w_op_reestructurar

                delete cob_cartera..ca_dividendo_tmp
                 where dit_operacion = @w_operacion_rest_ant

                delete cob_cartera..ca_amortizacion_tmp
                 where amt_operacion = @w_operacion_rest_ant

                delete cob_cartera..ca_cuota_adicional_tmp
                 where cat_operacion = @w_operacion_rest_ant

                delete cob_cartera..ca_rubro_op_tmp
                 where rot_operacion = @w_operacion_rest_ant

                delete cr_op_renovar
                where  or_tramite = @i_tramite

                -- obtener los datos de la operacion a reestructurar
                select     @w_tramite_rest = op_tramite,
                        @w_cliente_rest = op_cliente,
                        @w_monto_rest   = op_monto_aprobado,
                    @w_moneda_rest  = op_moneda,
                    @w_fecha_liq_rest = op_fecha_liq,
                    @w_toperacion_rest = op_toperacion,
      @w_operacion_rest = op_operacion
                from cob_cartera..ca_operacion
                where op_banco = @i_op_reestructurar

                if @@rowcount = 0
                begin
                   --registro no existe
exec cobis..sp_cerror
                   @t_debug = @t_debug,
                   @t_file  = @t_file,
                   @t_from  = @w_sp_name,
                   @i_num   = 2101010

                   return 1
                end

                -- llamar al sp que crea copia
                exec @w_return = sp_copia_operacion
                @s_ssn        = @s_ssn,
                @s_user        = @s_user,
                @s_sesn        = @s_sesn,
                @s_term        = @s_term,
                @s_date        = @s_date,
                @s_srv        = @s_srv,
                @s_lsrv        = @s_lsrv,
                @s_rol        = @s_rol,
                @s_ofi        = @s_ofi,
                @s_org_err    = @s_org_err,
                @s_error    = @s_error,
                @s_sev        = @s_sev,
                @s_msg        = @s_msg,
                @s_org        = @s_org,
                @t_rty        = @t_rty,
                @t_trn        = 21218,
                @t_debug    = @t_debug,
                @t_file        = @t_file,
                @t_from        = @t_from,
                @i_tramite    = @i_tramite,
                @i_banco    = @i_op_reestructurar,
                @i_monto        = @i_monto

                if @w_return != 0
                   return @w_return
                -- actualizar destino y ciudad
                update cob_cartera..ca_operacion
                set op_destino     = @i_destino,
                    op_ciudad      = convert (int, @i_ciudad_destino),
                    op_financia    = @i_financia,
                    op_abono_ini    = @i_abono_ini,
                    op_opcion_compra= @i_opcion_compra,
                    op_beneficiario    = @i_beneficiario
                where op_tramite = @i_tramite

                if @@rowcount = 0
                begin
                   exec cobis..sp_cerror
                   @t_debug = @t_debug,
                   @t_file  = @t_file,
                   @t_from  = @w_sp_name,
                   @i_num= 2103001,
                   @i_msg     = '[sp_up_tramite_busin] ERROR EN ACTUALIZACION DE OPERACION EN CARTERA'
                   return 1
                end

                --Borra tablas temporales
                exec @w_return = cob_cartera..sp_borrar_tmp
                     @s_user   = @s_user,
                     @s_sesn   = @s_sesn,
                     @i_banco  = @w_banco
                if @w_return != 0
                   return @w_return

            end -- hubo cambio en la operacion a reestructurar*/
       --    end --
    -- MANEJO DEL SEGURO BASICO
    if @i_seguro_basico = 'S'  -- CREA SEGURO BASICO
    begin
        select @w_tipo_seg_basico = pa_char FROM cobis..cl_parametro WHERE pa_nemonico = 'SGBASI'

        exec @w_error = cob_cartera..sp_seguros_indv @i_opcion = 'I', @i_categoria = @w_tipo_seg_basico, @i_cliente = @i_cliente, @i_tramite = @i_tramite, @i_monto_seguro = @i_monto, @s_user = @s_user, @t_trn = 77511, @s_ofi = @s_ofi , @s_date = @s_date
        if @w_error != 0
        begin
           return @w_error
        end
    end
    else if @i_seguro_basico = 'N'  -- ELIMINA SEGURO BASICO
    begin
        select @w_tipo_seg_basico = pa_char FROM cobis..cl_parametro WHERE pa_nemonico = 'SGBASI'

        exec @w_error = cob_cartera..sp_seguros_indv @i_opcion = 'D', @i_categoria = @w_tipo_seg_basico, @i_cliente = @i_cliente, @i_tramite = @i_tramite, @s_user = @s_user, @t_trn = 77511
        if @w_error != 0
        begin
           return @w_error
        end
    end
    -- MANEJO DEL SEGURO VOLUNTARIO
    if @i_seguro_voluntario = 'S' and @i_tipo_seguro is not null  -- CREA SEGURO VOLUNTARIO
    begin
        exec @w_error = cob_cartera..sp_seguros_indv @i_opcion = 'I', @i_categoria = @i_tipo_seguro, @i_cliente = @i_cliente, @i_tramite = @i_tramite, @i_monto_seguro = @i_monto, @s_user = @s_user, @t_trn = 77511, @s_ofi = @s_ofi , @s_date = @s_date
        if @w_error != 0
        begin
           return @w_error
        end
    end
    else if @i_seguro_voluntario = 'N'  -- ELIMINA SEGURO VOLUNTARIO -- @i_categoria = 'X'
    begin
        exec @w_error = cob_cartera..sp_seguros_indv @i_opcion = 'D', @i_categoria = 'X', @i_cliente = @i_cliente, @i_tramite = @i_tramite, @s_user = @s_user, @t_trn = 77511
        if @w_error != 0
        begin
           return @w_error
        end
    end
    -- FIN MANEJO DE SEGUROS
commit tran

return 0

--ERROR:

   --Devolver mensaje de Error
   if @i_canal in (0,1) --Frontend o batch
   begin
      exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error

        return @w_error
   end
   else
      return @w_error


GO
