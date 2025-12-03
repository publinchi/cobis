/************************************************************************/
/*    Archivo:                sp_in_tramite.sp                          */
/*    Stored procedure:       sp_in_tramite                             */
/*    Base de Datos:          cob_credito                               */
/*    Producto:               Credito                                   */
/*    Disenado por:           Myriam Davila                             */
/*    Fecha de Documentacion: 10/Nov/95                                 */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                           PROPOSITO                                  */
/*    Este stored procedure hace el ingreso de un nuevo                 */
/*    registro   en la tabla cr_tramite                                 */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*    FECHA        AUTOR                      RAZON                     */
/*  10/Nov/95    Myriam Davila    Emision Inicial                       */
/*  15/Dic/97    Myriam Davila    Upgrade de Cartera                    */
/*  26/May/98    Julio Lopez      Personalizacion SV                    */
/*  02/Jun/98    Julio Lopez      Personalizacion SV                    */
/*  27/Abr/99    Sergio Lucha     Prorrogas de Lineas                   */
/*  06/Oct/01    Susana Paredes   Porcentaje de cobertura               */
/*                                y eliminacion de campos en gp         */
/*  07/Abr/05    Vivi Arias       Agrega parametros                     */
/*  07/Jul/05    Vivi Arias       Se pone lógica de cartera             */
/*                                en otro sp.                           */
/*  01/Abr/06    Diego Aguilar    Heredar polizas de lineas de CR       */
/*  11/Jun/07    Viviana Arias    Hereda poliza asociada                */
/*                                a una garantia para P.                */
/*  13/Jul/07    Clotilde Vargas  Determinar por medio                  */
/*                                de la parametrizacion                 */
/*                                del motivo si se                      */
/*                                acumula los dias de las               */
/*                                prorrogas de lineas                   */
/*  18-Ago-2007  Pedro Coello     Cambios por manejos de                */
/*                                promociones                           */
/*  26-sep-07    Mirna Gonzalez   Manejo de Subsidio Agrop Lineas       */
/*                                de Credito                            */
/*  11/MAR/09    Fdo Carvajal     Revision de Clientes para Grupos      */
/*  25-Mar-2009  Sandra Robayo    Se ingresa el campo que indica si     */
/*                                la operacion de factoring es comprada */
/*                                por el banco o no.                    */
/*  27/Ago/2015  Geovanny Duran   Se aumentan parametros para Reestrura */
/*                                tipo (E)                              */
/*  30/Jun/2021  Patricio Mora    Ajuste para GFI B499291               */
/*  01/Sep/2021  Paulina Quezada  Ajuste para deudores                  */
/*  02/Mar/2022  Dilan Morales    Se envia @i_dia_fijo en               */
/*                                sp_operacion_cartera                  */
/*  02/Jun/2023  Dilan Morales    Se añade tipo credito F en chequeo de */
/*                                operación a reestructurar             */ 
/*  13/Jul/2023  Bruno Duenas     Se agrega subtipo al tramite          */
/************************************************************************/

use cob_credito
go

if exists (select * from sysobjects where name = 'sp_in_tramite')
    drop proc sp_in_tramite
go

create procedure sp_in_tramite (
         @s_ssn                      int            = null,
         @s_user                     login          = null,
         @s_sesn                     int            = null,
         @s_term                     varchar(30)    = null,
         @s_date                     datetime       = null,
         @s_srv                      varchar(30)    = null,
         @s_lsrv                     varchar(30)    = null,
         @s_rol                      smallint       = null,
         @s_ofi                      smallint       = null,
         @s_org_err                  char(1)        = null,  --10
         @s_error                    int            = null,
         @s_sev                      tinyint        = null,
         @s_msg                      descripcion    = null,
         @s_org                      char(1)        = null,
         @t_show_version             bit            = 0,     -- Mostrar la version del programa
         @t_rty                      char(1)        = null,
         @t_trn                      smallint       = null,
         @t_debug                    char(1)        = 'N',
         @t_file                     varchar(14)    = null,
         @t_from                     varchar(30)    = null,
         @i_operacion                char(1)        = null,  --20
         @i_tramite                  int            = null,
         @i_tipo                     char(1)        = null,
         @i_truta                    tinyint        = null,
         @i_oficina_tr               smallint       = null,
         @i_usuario_tr               login          = null,
         @i_fecha_crea               datetime       = null,
         @i_oficial                  smallint       = null,
         @i_sector                   catalogo       = null,
         @i_ciudad                   int            = null,
         @i_estado                   char(1)        = null,  --30
         @i_numero_op_banco          cuenta         = null,
         @i_cuota                    money          = 0,
         @i_frec_pago                catalogo       = null,
         @i_moneda_solicitada        tinyint        = null,
         @i_provincia                int            = null,
         @i_monto_solicitado         money          = null,
         @i_monto_desembolso         money          = null,
         @i_pplazo                   smallint       = null,
         @i_tplazo                   catalogo       = null,
         /* campos para tramites de garantias */
         @i_proposito                catalogo       = null,
         @i_razon                    catalogo       = null,
         @i_txt_razon                varchar(255)   = null,
         @i_efecto                   catalogo       = null,
         /* campos para lineas de credito */
         @i_cliente                  int            = null,
         @i_grupo                    int            = null,  --40
         @i_fecha_inicio             datetime       = null,
         @i_num_dias                 smallint       = 0,
         @i_per_revision             catalogo       = null,
         @i_condicion_especial       varchar(255)   = null,
         @i_rotativa                 char(1)        = null,
         @i_destino_fondos           varchar(255)   = null,
         @i_comision_tramite         float          = null,
         @i_subsidio                 float          = null,
         @i_tasa_aplicar             float          = null,
         @i_tasa_efectiva            float          = null,
         @i_plazo_desembolso         smallint       = null,
         @i_forma_pago               varchar(255)   = null,
         @i_plazo_vigencia           smallint       = null,
         @i_origenfondos             varchar(255)   = null,
         @i_formalizacion            catalogo       = null,
         @i_cuenta_corrientelc       cuenta         = null,
         /* operaciones originales y renovaciones */
         @i_linea_credito            cuenta         = null,
         @i_toperacion               catalogo       = null,
         @i_producto                 catalogo       = null,
         @i_monto                    money          = 0,
         @i_moneda                   tinyint        = 0,
         @i_periodo                  catalogo       = null,  --50
         @i_num_periodos             smallint       = 0,
         @i_destino                  catalogo       = null,
         @i_ciudad_destino           int            = null,
         -- solo para prestamos de cartera
         @i_reajustable              char(1)        = null,
         @i_per_reajuste             tinyint        = null,
         @i_reajuste_especial        char(1)        = null,
         @i_fecha_reajuste           datetime       = null,  --60
         @i_cuota_completa           char(1)        = null,
         @i_tipo_cobro               char(1)        = null,
         @i_tipo_reduccion           char(1)        = null,
         @i_aceptar_anticipos        char(1)        = null,
         @i_precancelacion           char(1)        = null,
         @i_tipo_aplicacion          char(1)        = null,
         @i_renovable                char(1)        = null,
         @i_fpago                    catalogo       = null,
         @i_cuenta                   cuenta         = null,
         -- generales
         @i_renovacion               smallint       = null,  -- 70
         @i_cliente_cca              int            = null,
         @i_op_renovada              cuenta         = null,
         @i_deudor                   int            = null,
         -- reestructuracion
         @i_op_reestructurar         cuenta         = null,
         -- TME se agregan las siguientes variables 08/09/1998 solicitadas por banco
         @i_sector_contable          catalogo       = null,
         @i_origen_fondo             catalogo       = null,
         @i_fondos_propios           char(1)        = null,
         @i_plazo                    catalogo       = null,
         @i_numero_linea             int            = null,
         -- Financiamiento
         @i_revolvente               char(1)        = null,
         @i_trm_tmp                  int            = null,
         @i_her_ssn                  int            = null,
         @i_causa                    char(1)        = null,         --Personalizaci½n Banco Atlantic
         @i_contabiliza              char(1)        = null,         --Persobalizaci½n Banco Atlantic
         @i_tvisa                    varchar(24)    = null,         --Persobalizaci½n Banco Atlantic
         @i_migrada                  cuenta         = null,         --RZ Persobalizaci½n Banco Atlantic
         @i_tipo_linea               varchar(10)    = null,
         @i_plazo_dias_pago          int            = null,
         @i_tipo_prioridad           char(1)        = 'V',
         @i_linea_credito_pas        cuenta         = null,
         @i_proposito_op             catalogo       = null,         --Vivi
         @i_linea_cancelar           int            = null,    
         @i_fecha_irenova            datetime       = null,    
         @i_subtipo                  catalogo       = null,         --Vivi - CD00013
         @i_tipo_tarjeta             catalogo       = null,         --Vivi - CD00013
         @i_motivo                   catalogo       = null,         --Vivi
         @i_plazo_pro                int            = null,         --Vivi
         @i_fecha_valor              char(1)        = null,         --VIvi
         @i_estado_lin               catalogo       = null,         --Vivi
         @i_subtplazo                catalogo       = null,
         @i_subplazos                smallint       = null,
         @i_subdplazo                int            = null,
         @i_subtbase                 varchar(1)     = null,
         @i_subporcentaje            float          = null,
         @i_subsigno                 char(1)        = null,
         @i_subvalor                 float          = null,
         @i_tasa_asociada            char(1)        = null,
         @i_tpreferencial            char(1)        = 'N',
         @i_porcentaje_preferencial  float          = null,
         @i_monto_preferencial       money          = 0,
         @i_abono_ini                money          = null,
         @i_opcion_compra            money          = null,
         @i_beneficiario             descripcion    = null,
         @i_financia                 char(1)        = null,
         @i_ult_tramite              int            = null,         --Vivi, Tramite del que hereda condiciones
         @i_empleado                 int            = null,         --Vivi, C½digo del empleado para Tarjeta Corporativa
         @i_ssn                      int            = null,         
         @i_nombre_empleado          varchar( 40)   = null,         --Nombre del Empleado para Linea Visa
         @i_canal                    tinyint        = 0,            --Canal: 0=Frontend  1=Batch  2=workflow
         @i_promotor                 int            = null,        
         @i_comision_pro             float          = null,        
         @i_iniciador                descripcion    = null,        
         @i_entrevistador            descripcion    = null,        
         @i_vendedor                 descripcion    = null,        
         @i_cuenta_vende             descripcion    = null,        
         @i_agencia_venta            descripcion    = null,        
         @i_aut_valor_aut            money          = null,        
         @i_aut_abono_aut            money          = null,        
         @i_canal_venta              catalogo       = null,        
         @i_referido                 varchar(1)     = null,        
         @i_FIniciacion              datetime       = null,        
         -- Prestamos Gemelos                                      
         @i_gemelo                   char(1)        = null,        
         @i_tasa_prest_orig          float          = null,        
         @i_banco_padre              cuenta         = null,        
         @i_num_cuenta               char(16)       = null,        
         @i_prod_bancario            smallint       = null,        
         --PCOELLO Para manejo de Promociones                      
         @i_monto_promocion          money          = null,         --Valor que se va a dar al cliente por promocion
         @i_saldo_promocion          money          = null,         --Saldo pendiente de pago de la promocion
         @i_tipo_promocion           catalogo       = null,         --Tipo de promocion
         @i_cuota_promocion          money          = null,         --Cuota mensual a pagar por el cliente por promocion
         @i_destino_descripcion      descripcion    = null,         --DCH, 02-Feb-2015 Descripcion especifica del destino
         @i_expromision              catalogo       = null,         --JES 05-Junio-2015
         @i_objeto                   catalogo       = null,         --JMA, 02-Marzo-2015
         @i_actividad                catalogo       = null,         --JMA, 02-Marzo-2015
         @i_descripcion_oficial      descripcion    = null,         --JES, 25-Junio-2015
         @i_tipo_cartera             catalogo       = null,         --JES, 21-Julio-2015
         @i_sector_cli               catalogo       = null,         --JES, 21-Julio-2015
         @i_convenio                 char(1)        = null,
         @i_codigo_cliente_empresa   varchar(10)    = null,
         @i_tipo_credito             catalogo       = null,
         @i_motivo_uno               varchar(255)   = null,         -- ADCH, 05/10/2015 motivo para tipo de solicitud
         @i_motivo_dos               varchar(255)   = null,         -- ADCH, 05/10/2015 motivo para tipo de solicitud
         @i_motivo_rechazo           catalogo       = null,
         @i_tamanio_empresa          varchar(5)     = null,
         @i_producto_fie             catalogo       = null,
         @i_num_viviendas            tinyint        = null,
         @i_reprogramingObserv       varchar(255)   = null,
         @i_sub_actividad            catalogo       = null,
         @i_departamento             catalogo       = null,
         @i_credito_es               catalogo       = null,
         @i_financiado               char(2)        = null,
         @i_presupuesto              money          = null,
         @i_fecha_avaluo             datetime       = null,
         @i_valor_comercial          money          = null,
         @i_vinculado                char(1)        = 'N',
         @i_activa_TirTea            char(1)        = 'S',
         @i_causal_vinculacion       catalogo       = null,
         --CAMPOS AUMENTADOS EN INTEGRACION FIE
         @i_actividad_destino        catalogo       = null,         --SPO Actividad economica de destino
         @i_parroquia                catalogo       = null,         -- ITO:12/12/2011
         @i_canton                   catalogo       = null,
         @i_barrio                   catalogo       = null,
         @i_toperacion_ori           catalogo       = null,         --Policia Nacional: Se incrementa por tema de interceptor
         @i_dia_fijo                 smallint,                      --PQU integración
         @i_enterado                 catalogo,                      --PQU integración
         @i_otros_ent                varchar(64),                   --PQU integración
         -- Manejo de seguros                                       --PQU integración
         @i_seguro_basico            char(1)        = 'X',          -- (S/N/X) - S=Crea el Seguro, N:Elimina el Seguro, X:No hace nada
         @i_seguro_voluntario        char(1)        = 'X',          -- (S/N/X) - S=Crea el Seguro, N:Elimina el Seguro, X:No hace nada
         @i_tipo_seguro              catalogo       = null,         --fin --PQU integración
         @o_retorno                  int            = null  out
)
as
declare
         @w_today                    datetime,                      /* fecha del dia */
         @w_error                    int,                           /* valor que retorna */
         @w_sp_name                  varchar(32),                   /* nombre stored proc*/
         @w_existe                   tinyint,                       /* existe el registro*/
         @w_numero_op                int,                           
         @w_linea_credito            int ,                          /* renovaciones y operaciones */
         @w_numero_linea             int,
         @w_numero_operacion         int,
         @w_numero_op_banco          cuenta,
         @o_tramite                  int,
         @o_linea_credito            cuenta,
         @o_numero_op                cuenta,
         @w_etapa                    tinyint,
         @w_banco                    cuenta,
         @w_fecha_ini                varchar(10),
         @w_tramite                  int,
         @w_des_periodo              descripcion,
         @w_num_periodos             int,
         @w_val_tasaref              float,
         @w_periodo                  catalogo,
         @w_hora_0                   varchar(8),
         @w_hora_1                   varchar(8),
         @w_nombre_cli_cca           descripcion,                   --optimizacion de CCA
         @w_tramite_rest             int,                           -- tramite de operacion a reestructurar
         @w_cliente_rest             int,                           -- deudor de operacion a reestructurar
         @w_monto_rest               money,                         -- monto inicial de operacion a reestructurar
         @w_moneda_rest              tinyint,                       -- moneda de operacion a reestructurar
         @w_saldo_rest               money,                         -- saldo de operacion a reestructurar
         @w_fecha_liq_rest           datetime,                      -- fecha de liquidacion de op. a reestructurar
         @w_toperacion_rest          catalogo,                      -- tipo de prestamo de operacion a reestructurar
         @w_operacion_rest           int,                           -- numero secuencial de operacion a reestructurar
         @w_sector_contable          catalogo,                      -- TME 08/09/98 nuevas variables
         @w_tamano_empresa           catalogo,
         @w_fondos_propios           char(1),
         @w_plazo                    catalogo,
         @w_ciudad                   int,
         @w_tr_linea                 int,
         @w_deu_linea                int,
         @w_tr_pgroup                catalogo,
         @w_de_cliente               int,
         @w_secuencial               int,
         @w_cedula_ruc               varchar(35),
         @w_de_rol                   catalogo,
         @w_fecha_fin                datetime,
         @w_tipo                     char(1),
         @w_tipo_prioridad           char(1),
         @w_documento                varchar(10),
         @w_acumulado_pro            smallint,                      --Vivi
         @w_garantia_poliza          varchar(64),                   --Diego
         @w_total                    int,                           
         @w_li_grupo                 int,                           --FCP 11/MAR/2009 Revision de Clientes para Grupos
         @w_dias                     int,
         @w_tipo_aplica_reest        char(1),
         @w_destino_reest            catalogo,
         @w_financia                 char(1),
         @w_abono_ini                money,
         @w_opcion_compra            money,
         @w_beneficiario             descripcion,
         @w_destino_tramite          catalogo,
         @w_tea                      float,
         @w_return                   int,
         @w_ced_ruc                  varchar(30),
         @w_tipo_seg_basico          catalogo,                      --PQU integración
         @w_operacionca              int,                            --PQU integración
         @w_base                     char(1),
         @w_tipo_tra                 char(1)

select @w_today  = isnull(@s_date, fp_fecha)
from   cobis..ba_fecha_proceso
select @w_sp_name = 'sp_in_tramite'

if @t_show_version = 1
begin
    print 'Stored procedure sp_in_tramite, Version 4.0.0.3'
    return 0
end

/******* Verificaciones Previas **********/
/*****************************************/
/* Chequeo de Linea de Credito */
If @i_linea_credito is not null
begin
    select  @w_numero_linea  = li_numero,
            @w_acumulado_pro = li_acumulado_prorroga,    --Vivi
            @w_tr_linea      = li_tramite,               --Vivi, para verificar deudores
            @w_li_grupo      = li_grupo                  --FCP 11/MAR/2009 Revision de Clientes para Grupos
    from    cob_credito..cr_linea
    where   li_num_banco = @i_linea_credito
    if @@rowcount = 0
    begin
           select @w_error = 2101010
     goto ERROR
    end

    --I.4491 CVA Jul-13-07
    /**DETERMINAR POR EL MOTIVO SI PARA EL NUEVO TRAMITE SE ACUMULA LOS DIAS DE LA PRORROGA DE LA LINEA **/
    if @i_tipo = 'P'
    begin
        if @i_motivo is not null
        begin
            if not exists(select el_tipo from cob_credito..cr_estado_linea
                          where el_tipo         = 'M' --Motivos de Modificacion
                          and   el_codigo       = @i_motivo
                          and   el_acumula_dias = 'S')
            select @w_acumulado_pro =  0
        end
    end
    --I.4491 CVA Jul-13-07
end

/* Chequeo de Numero de operacion */
if @i_numero_op_banco is not null
begin
    if @i_producto = 'CCA'
    begin
        select    @w_numero_operacion = op_operacion
        from       cob_cartera..ca_operacion
        where    op_banco = @i_numero_op_banco
        If @@rowcount = 0
        begin
            select @w_error = 2101021
            goto ERROR
        end
    end
    if @i_producto = 'CEX'
    begin
        select   @w_numero_operacion = op_operacion
        from     cob_comext..ce_operacion
        where    op_operacion_banco = @i_numero_op_banco
        If @@rowcount = 0
        begin
            select @w_error = 2101021
            goto ERROR
        end
    end
end

/** Chequeo de Operacion a Reestructurar o Renovar **/
If @i_tipo IN ('E', 'R', 'F')
begin
   if @i_op_reestructurar is null
   begin
      select @w_error = 2101001
      goto ERROR
   end
   select @w_tramite_rest      = op_tramite,
          @w_cliente_rest      = op_cliente,
          @w_monto_rest        = op_monto_aprobado,
          @w_moneda_rest       = op_moneda,
          @w_fecha_liq_rest    = op_fecha_liq,
          @w_toperacion_rest   = op_toperacion,
          @w_operacion_rest    = op_operacion,
          @w_tipo_aplica_reest = op_tipo_aplicacion,
          @w_destino_reest     = op_destino
   from cob_cartera..ca_operacion
   where op_banco = @i_op_reestructurar
   if @@rowcount = 0
   begin
      select @w_error = 2101011
      goto ERROR
   end
end

/**================================================================================**/
/**--  SI EL TRAMITE TIENE ASOCIADA UNA LINEA, VERIFICA QUE LOS DEUDORES DE  LA  --**/
/**--  LINEA SEAN LOS MISMOS QUE LOS DEL TRAMITE, SINO, NO SE PERMITE LA TRN.    --**/
if @i_linea_credito is not null and @i_tipo != 'P'
begin
   /* FCP 11/MAR/2009 BUSCAR EN EL REGISTRO DE GRUPO */
   if @w_li_grupo is not null
   begin
      if exists (select 1 from cr_deudores_tmp where dt_ssn = @i_trm_tmp
                 and dt_cliente not in (select en_ente from cr_deudores, cobis..cl_ente where de_tramite = @w_tr_linea and en_grupo = de_cliente) )
         begin
            select @w_error = 2101070
            goto ERROR
         end
   end
 end
/**===============================================================================**/

/**** INSERCION DEL REGISTRO *******/
/***********************************/
begin tran
    /* Numero secuencial de tramite */
    exec cobis..sp_cseqnos
       @t_debug     = @t_debug,
       @t_file      = @t_file,
       @t_from      = @w_sp_name,
       @i_tabla     = 'cr_tramite',
       @o_siguiente = @o_tramite out
    if @o_tramite is null
    begin
        select @w_error = 2101007
        goto ERROR
    end
    select @i_tramite = @o_tramite
commit tran

begin tran
    --REGISTRO LOS DEUDORES
    if  @i_tipo != 'M' AND @i_tipo != 'C' -- ABE Flujo Moratoria
    begin
       if exists(select 1 from cr_deudores_tmp, cobis..cl_ente where dt_ssn = @i_ssn and en_ente = dt_cliente)
       begin 
          insert cr_deudores
          select @i_tramite,   dt_cliente,   dt_rol,    en_ced_ruc , dt_segvida, dt_cobro_cen
          from cr_deudores_tmp, cobis..cl_ente
          where dt_ssn = @i_ssn
          and en_ente = dt_cliente

          if @@error != 0
          begin
             rollback tran
             select @w_error = 2103001
             goto ERROR
           end
       end 
     if not exists (select 1 from cob_credito..cr_deudores where de_tramite = @i_tramite)and @i_cliente_cca is not null --PQU para integración con app Finca
     begin
         select @w_ced_ruc = en_ced_ruc from cobis..cl_ente where en_ente = @i_cliente_cca
         insert into cr_deudores values (@i_tramite, @i_cliente_cca, 'D', @w_ced_ruc, null,'N')  
         if @@error != 0
         begin
            rollback tran
            select @w_error = 2103001
            goto ERROR
         end
      end 
      --fin PQU    
    end

    if @i_tipo = 'L' or @i_tipo = 'P'
     begin
          select @i_toperacion = isnull(@i_tipo_linea,@i_toperacion) --DFL cuando @i_tipo_linea es null
          if @i_cliente is not null
          begin
             select @w_tr_pgroup = '0' -- MSU en_product_group
             from cobis..cl_ente
             where en_ente = @i_cliente
          end
          if @i_grupo is not null
          begin
             select @w_tr_pgroup = '0' --MSU gr_product_group
             from cobis..cl_grupo
             where gr_grupo = @i_grupo
          end
     end
    else
     begin
        select @w_tr_pgroup = null
     end
    /* insercion en la tabla cr_tramite */
       insert into cr_tramite
       (
        tr_tramite, tr_tipo, tr_subtipo, tr_oficina, tr_usuario, tr_fecha_crea,
        tr_oficial, tr_sector, tr_ciudad, tr_estado,
        tr_numero_op, tr_numero_op_banco,
        tr_proposito, tr_razon, tr_txt_razon, tr_efecto, tr_cliente,
        tr_grupo, tr_fecha_inicio, tr_num_dias, tr_per_revision,
        tr_condicion_especial,
        tr_linea_credito,tr_toperacion, tr_producto, tr_monto,
        tr_moneda, tr_periodo,tr_num_periodos, tr_destino,
        tr_ciudad_destino,
        tr_renovacion,
        tr_causa,  tr_lin_comext,
        tr_proposito_op,
        tr_fecha_irenova,tr_linea_cancelar, tr_tasa_asociada,
     -- SRO 25-MAR-2009 Factoring
        tr_cuota, tr_frec_pago, tr_moneda_solicitada, tr_provincia,  --MIB solicitud generica  COBIS5
        tr_monto_solicitado, tr_monto_desembolso, tr_plazo, tr_tplazo , tr_expromision , tr_origen_fondos,
        tr_sector_cli,tr_enterado,tr_otros, --PQU se añade tr_enterado, tr_otros por integración
        tr_cod_actividad --PQU almacena actividad
       )
       values
       (
        @i_tramite, @i_tipo, @i_subtipo, @i_oficina_tr, @i_usuario_tr, @w_today,
        @i_oficial, @i_sector, @i_ciudad, 'N',
        @w_numero_operacion, @i_numero_op_banco,
        @i_proposito, @i_razon, @i_txt_razon, @i_efecto, @i_cliente,
        @i_grupo, @i_fecha_inicio, @i_num_dias, @i_per_revision,
        @i_condicion_especial,
        @w_numero_linea, @i_toperacion, @i_producto, @i_monto,
        @i_moneda, @i_periodo, @i_num_periodos, @i_destino,
        @i_ciudad_destino,
        @i_renovacion,
        @i_causa, @i_linea_credito_pas,
        @i_proposito_op,    --Vivi
        @i_fecha_irenova,@i_linea_cancelar, @i_tasa_asociada,
       -- SRO 25-MAR-2009 Factoring
        @i_cuota, @i_frec_pago, @i_moneda_solicitada, @i_provincia, --MIB solicitud generica  COBIS5
        @i_monto_solicitado, @i_monto_desembolso,  @i_pplazo, @i_tplazo , @i_expromision , @i_origen_fondo,
        @i_sector_cli,@i_enterado,@i_otros_ent,  --PQU se añade i_enterado, i_otros_ent por integración
        @i_actividad_destino
       )
    if @@error != 0
    begin
        select @w_error = 2103001
        goto ERROR
    end

       /**** tranSACCION DE SERVICIO ***/
    if @i_canal = 0 --Llmado desde el frontend
    begin
        insert into ts_tramite
           (secuencial, tipo_transaccion, clase, fecha, usuario, terminal,
            oficina, tabla, lsrv, srv, tramite, tipo, oficina_tr, usuario_tr,
            fecha_crea, oficial, sector, ciudad, estado,
            numero_op, numero_op_banco, proposito, razon,
            txt_razon, efecto, cliente, grupo, fecha_inicio, num_dias, per_revision,
            condicion_especial, linea_credito, toperacion, producto,
            monto, moneda, periodo, num_periodos, destino, ciudad_destino,
            renovacion,/*causa,*/
            cuota_aproximada,  monto_solicitado,  --MIB solicitud generica  COBIS5
            montodesembolsop,plazo, tipo_plazo,
            cod_actividad
           )
           values
           (@s_ssn, @t_trn, 'N', @s_date, @s_user, @s_term,
            @s_ofi, 'cr_tramite', @s_lsrv, @s_srv, @i_tramite, @i_tipo, @i_oficina_tr, @i_usuario_tr,
            @w_today, @i_oficial, 'P', @i_ciudad, 'N',
            @w_numero_operacion, @i_numero_op_banco, @i_proposito, @i_razon,
            @i_txt_razon, @i_efecto, @i_cliente, @i_grupo, @i_fecha_inicio, @i_num_dias, @i_per_revision,
            @i_condicion_especial, @w_numero_linea, @i_toperacion, @i_producto,
            @i_monto, @i_moneda, @i_periodo, @i_num_periodos, @i_destino, @i_ciudad_destino,
            @i_renovacion, /*@i_causa,*/
            @i_cuota, @i_monto_solicitado, --MIB solicitud generica  COBIS5
            @i_monto_desembolso, @i_pplazo, @i_tplazo,
            @i_actividad_destino
           )
           if @@error != 0
           begin
              select @w_error = 2103003
              goto ERROR
           end
    end
    /* RETORNO DE NUMERO DE TRAMITE AL FRONT end */
    if @i_canal = 0 --Desde frontend
    select  @i_tramite
    select  @w_tramite = @i_tramite,
 @o_retorno = @i_tramite

    /* REGISTRA DATOS ADICIONALES DEL TRAMITE*/
    if @i_tipo != 'C'
    begin

    select @i_departamento = pv_depart_pais from cobis..cl_provincia where pv_provincia = @i_provincia

    exec @w_error         = cob_credito..sp_tr_datos_adicionales
         @s_ssn           = @s_ssn,
         @s_user          = @s_user,
         @s_sesn          = @s_sesn,
         @s_term          = @s_term,
         @s_date          = @s_date,
         @s_srv           = @s_srv,
         @s_lsrv          = @s_lsrv,
         @s_rol           = @s_rol,
         @s_ofi           = @s_ofi,
         @s_org_err       = @s_org_err,
         @s_error         = @s_error,
         @s_sev           = @s_sev,
         @s_msg           = @s_msg,
         @s_org           = @s_org,
         @t_rty           = @t_rty,
         @t_trn           = 21118,
         @t_debug         = @t_debug,
         @t_file          = @t_file,
         @t_from          = @t_from,
         @t_show_version  = 0, -- Mostrar la version del programa
         @i_operacion     ='I',
         @i_tramite       = @i_tramite,
         @i_tipo_cartera  = @i_tipo_cartera
        if @w_error != 0
            begin
                return @w_error
            end
    end     
     /* SI EL TRAMITE ES DE GARANTIAS COPIAR LOS DEUDORES */
    /********************************************************************/
    if @i_tipo = 'G'
    BEGIN
        SELECT @w_cedula_ruc = isnull(en_ced_ruc,'')
        FROM cobis..cl_ente
        WHERE en_ente = @i_cliente
        
        INSERT INTO cob_credito..cr_deudores VALUES (@i_tramite, @i_cliente, 'D', @w_cedula_ruc, NULL,'N')
        if @@error != 0
        begin
           select @w_error = 2103003
           goto ERROR
        end          
     end
    /* SI EL TRAMITE ES DE LINEA DE CREDITO ==> CREAR REGISTRO DE LINEA */
    /********************************************************************/
    if @i_tipo = 'L'
    begin
         select @w_dias = isnull(datediff(day,@i_fecha_crea,(dateadd(month, @i_num_dias, @i_fecha_crea))) , 0)
         declare @w_fecha_tmp datetime
         set @w_fecha_tmp = isnull(@i_fecha_crea,@i_fecha_inicio)

           exec @w_error              = cob_credito..sp_linea  --PQU integración quitar el comentario de línea
                @s_ssn                = @s_ssn,
                @s_user               = @s_user,
                @s_sesn               = @s_sesn,
                @s_term               = @s_term,
                @s_date               = @s_date,
                @s_srv                = @s_srv,
                @s_lsrv               = @s_lsrv,
                @s_rol                = @s_rol,
                @s_ofi                = @s_ofi,
                @s_org_err            = @s_org_err,
                @s_error              = @s_error,
                @s_sev                = @s_sev,
                @s_msg                = @s_msg,
                @s_org                = @s_org,
                @t_debug              = @t_debug,
                @t_file               = @t_file,
                @t_from               = @t_from,
                @t_trn                = 21026,
                @i_operacion          = 'I',
                @i_numero             = null,
                @i_num_banco          = null,
                @i_oficina            = @i_oficina_tr,
                @i_tramite            = @i_tramite,
                @i_cliente            = @i_cliente,
                @i_grupo              = @i_grupo,                
                @i_original           = null,
                @i_fecha_inicio       = @w_fecha_tmp,                
                @i_per_revision       = @i_per_revision,                
                @i_fecha_vto          = null,                
                @i_dias               = @i_num_dias,             --@w_dias,--@i_num_dias,
                @i_condicion_especial = @i_condicion_especial,                
                @i_monto              = @i_monto,                ---@i_monto, ---PQU cambio de monto solicitado por monto
                @i_moneda             = @i_moneda_solicitada,    --@i_moneda,                
                @i_rotativa           = @i_rotativa,
                @i_sector             = @i_sector  
           if @w_error != 0
               return @w_error  --PQU integración quitar comentario de línea 

    end            -- FIN DE LINEA DE CREDITO

    /* SI EL TRAMITE ES ORIGINAL/RENOVACION/FINANCIAMIENTO */
    if (@i_tipo = 'O' or @i_tipo = 'R' or @i_tipo = 'F' or @i_tipo = 'L')
    begin
        if @i_tipo = 'L'
            select @w_deu_linea =  @i_cliente
        else
            select @w_deu_linea =  @i_deudor
    end

    /* SI EL TRAMITE ES ORIGINAL/RENOVACION/FINANCIAMIENTO */
    if (@i_tipo = 'O' or @i_tipo = 'R' or @i_tipo = 'F')
    begin
        -- TODAS LAS GARANTIAS DE LA L+NEA QUE LA RESPALDAN DEBEN ADJUNTARSE
        -- AUROMATICAMENTE AL NUEVO TRAMITE
        -- -----------------------------------------------------------------
        if @w_numero_linea is not null
         begin
            select @w_tr_linea = li_tramite
            from   cr_linea
            where  li_numero = @w_numero_linea

            insert into cr_gar_propuesta(
                    gp_tramite,          gp_garantia,
                    gp_abierta,          gp_porcentaje,
                    gp_deudor,           gp_est_garantia,     gp_valor_resp_garantia, gp_fecha_mod)
            select distinct
                    @i_tramite,          gp_garantia,
                    cu_abierta_cerrada,  gp_porcentaje,
                    @i_deudor ,          cu_estado,           gp_valor_resp_garantia, @s_date
                    from    cob_credito..cr_gar_propuesta
                    inner join cob_custodia..cu_custodia on gp_garantia = cu_codigo_externo and cu_estado not in ('A','C') -- No las Canceladas
                    where  gp_tramite     = @w_tr_linea
                    and    gp_garantia not in (select a.gp_garantia
                                               from   cr_gar_propuesta a
                                               where  a.gp_tramite = @i_tramite)
            if @@error != 0
             begin
                /* Error en insercion de registro */
                select @w_error = 2103001
                rollback
                goto ERROR
             end
         end
    end    -- fin de COMEXT  **********/

/* SI EL TRAMITE ES ORIGINAL/RENOVACION Y DE CARTERA */
/* Comprobar que el tramite sea financiamiento */
if (@i_tipo = 'O' or @i_tipo = 'R' or @i_tipo = 'F' or @i_tipo = 'E') and (@i_producto = 'CCA') -- ECA  incluyo la reestructuracion
 begin
       /* asigno el numero de banco como tramite */
       select @w_banco = rtrim(convert(char(24), @i_tramite))
       /* optimizacion de cartera */
       select  @w_nombre_cli_cca = rtrim(en_nomlar)        --RZ
       from       cobis..cl_ente
       where   en_ente = @i_cliente_cca

       select @w_ciudad = convert (int, @i_ciudad_destino)

       select @i_linea_credito = isnull(@i_linea_credito_pas, @i_linea_credito)

        --retorna el destino de la operacion
        select @w_destino_tramite=tr_destino
        from  cob_credito..cr_tramite
        where tr_tramite        = @i_tramite

        select @w_destino_tramite
        --actualiza el destino del tramite con el de la operacion
        update cob_cartera..ca_operacion
        set
           op_destino           = @w_destino_tramite
        where op_tramite        = @i_tramite
        if @@error != 0
        begin
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2110328
            return 2110328
        end

        if @i_tipo = 'R'
        begin
            select @i_fecha_inicio = isnull( @i_fecha_irenova, @i_fecha_inicio )

            -- obtener el saldo de la operacion a reestructurar
            select @w_saldo_rest = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0))-- - isnull(am_exponencial,0))
            from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
            where  ro_operacion = @w_operacion_rest
            and    ro_tipo_rubro IN ('C')    -- tipo de rubro capital
            and    am_operacion = ro_operacion
            and    am_concepto  = ro_concepto
            select @w_tipo_tra = tr_tipo from cob_credito..cr_tramite where tr_tramite = @i_tramite
            if @w_tipo_tra in ('R', 'F')
            begin
               select @w_base = 'N'
            end
            else if @w_tipo_tra in ('E')
            begin
               select @w_base = 'S' 
            end
            -- insertar un registro en cr_op_renovar
            insert into cob_credito..cr_op_renovar
            (or_tramite,or_num_operacion,or_producto,or_abono,
             or_moneda_abono,or_monto_original,or_moneda_original,
             or_saldo_original,or_fecha_concesion,or_toperacion, 
             or_base)
            values
            (@i_tramite, @i_op_reestructurar, 'CCA', 0,
             null, @w_monto_rest, @w_moneda_rest,
             @w_saldo_rest, @w_fecha_liq_rest, @w_toperacion_rest, 
             @w_base)
            if @@ERROR != 0
            begin
                -- Error en insercion de registro
                exec cobis..sp_cerror
                    @t_debug = @t_debug,
                    @t_file  = @t_file,
                    @t_from  = @w_sp_name,
                    @i_num   = 2110329
                return 2110329
            end
        end

           --if @i_canal = 2 print 'Antes de llamar al sp_operacion_cartera'
           /** LLAMA SP QUE REALIZA LA INTERFACE CON CARTERA Y CREA LA OPERACION **/
       exec @w_error                   = sp_operacion_cartera
            @s_user                    = @s_user,
            @s_sesn                    = @s_sesn,
            @s_ofi                     = @s_ofi,
            @s_date                    = @s_date,
            @s_term                    = @s_term,
            @t_debug                   = @t_debug,
            @t_file                    = @t_file,
            @t_from                    = @t_from,
            @i_transaccion             = 'I',
            @i_anterior                = @i_op_renovada,
            @i_num_renovacion          = @i_renovacion,
            @i_migrada                 = @i_migrada,
            @i_tramite                 = @i_tramite,
            @i_cliente                 = @i_cliente_cca,
            @i_nombre                  = @w_nombre_cli_cca,
            @i_sector                  = @i_sector,
            @i_toperacion              = @i_toperacion,
            @i_oficina                 = @i_oficina_tr,
            @i_moneda                  = @i_moneda,
            @i_comentario              = null,
            @i_oficial                 = @i_oficial,
            @i_fecha_ini               = @i_fecha_inicio,
            @i_monto                   = @i_monto,
            @i_monto_aprobado          = @i_monto_desembolso,
            @i_destino                 = @i_destino,
            @i_lin_credito             = @i_linea_credito,
            @i_ciudad                  = @w_ciudad,
            @i_ciudad_destino          = @w_ciudad,                 --DAG
            @i_forma_pago              = @i_fpago,
            @i_cuenta                  = @i_cuenta,
            @i_formato_fecha           = 103,
            @i_no_banco                = 'N',
            @i_origen_fondo            = @i_origen_fondo,
            @i_fondos_propios          = @i_fondos_propios ,
            @i_sector_contable         = @i_sector_contable,
            @i_tipo_tr                 = @i_tipo,                   --tipo de tramite
            @i_plazo                   = @i_pplazo,                 --plazo
            @i_tplazo                  = @i_tplazo,                 --unidad de tiempo
            @i_plazo_con               = @i_plazo,
            @i_dia_fijo                = @i_dia_fijo,
            @i_tipo_aplicacion         = @i_tipo_aplicacion,
            @i_tipo_prioridad          = @i_tipo_prioridad,
            @i_tpreferencial           = @i_tpreferencial,
            @i_porcentaje_preferencial = @i_porcentaje_preferencial,
            @i_monto_preferencial      = @i_monto_preferencial,
            @i_abono_ini               = @i_abono_ini,
            @i_opcion_compra           = @i_opcion_compra,
            @i_beneficiario            = @i_beneficiario,
            @i_financia                = @i_financia,
            @i_cuota_completa          = @i_cuota_completa,
            @i_tipo_cobro              = @i_tipo_cobro,
            @i_tipo_reduccion          = @i_tipo_reduccion,
            @i_aceptar_anticipos       = @i_aceptar_anticipos,
            @i_precancelacion          = @i_precancelacion,
            @i_renovable               = @i_renovable,
            @i_reajustable             = @i_reajustable,
            @i_fecha_reajuste          = @i_fecha_reajuste,
            @i_per_reajuste            = @i_per_reajuste,
            @i_reajuste_especial       = @i_reajuste_especial,
            @i_numero_banco            = @w_banco,
            @i_trm_tmp                 = @i_trm_tmp,
            @i_ult_tramite             = @i_ult_tramite,
            @i_promotor                = @i_promotor,
            @i_comision_pro            = @i_comision_pro,
            @i_iniciador               = @i_iniciador,
            @i_cuenta_vendedor         = @i_cuenta_vende,
            @i_vendedor                = @i_vendedor,
            @i_agencia_venta           = @i_agencia_venta,
            @i_entrevistador           = @i_entrevistador,
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
            @i_cuota_promocion         = @i_cuota_promocion
            --SRO FACTORING 08/ABR/2009
       if @w_error != 0
          return @w_error
       
       /*modificacion de las condiciones de forma de pago */
       update cob_cartera..ca_operacion
       set op_fecha_reajuste    = isnull(@i_fecha_reajuste,op_fecha_reajuste),
           op_periodo_reajuste  = isnull(@i_per_reajuste,op_periodo_reajuste),
           op_reajuste_especial = isnull(@i_reajuste_especial,op_reajuste_especial),
           op_forma_pago        = isnull(@i_fpago,op_forma_pago),
           op_cuenta            = isnull(@i_cuenta,op_cuenta),
           op_cuota_completa    = isnull(@i_cuota_completa,op_cuota_completa),
           op_tipo_cobro        = isnull(@i_tipo_cobro,op_tipo_cobro),
           op_tipo_reduccion    = isnull(@i_tipo_reduccion,op_tipo_reduccion),
           op_aceptar_anticipos = isnull(@i_aceptar_anticipos,op_aceptar_anticipos),
           op_precancelacion    = isnull(@i_precancelacion,op_precancelacion),
           op_tipo_aplicacion   = isnull(@i_tipo_aplicacion,op_tipo_aplicacion),
           op_renovacion        = isnull(@i_renovable,op_renovacion),
           op_reajustable       = isnull(@i_reajustable,op_reajustable),
           op_num_renovacion    = isnull(@i_renovacion,op_num_renovacion)
       where op_banco = @w_banco

       if @@error != 0
       begin
           /* Error en insercion de registro */
              exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2110330
              return 2110330
       end

       -- GENERACION DE LAS FECHAS DE REAJUSTE
           if ISnull(@i_per_reajuste,0) != 0 and @i_reajustable = 'S'
            begin
               exec @w_return = cob_cartera..sp_fecha_reajuste
                    @s_ssn         = @s_ssn,
                    @s_user        = @s_user,
                    @i_banco       = @w_banco,
                    @i_tipo        = 'I'

               if @w_return != 0
               begin
                 /* Error en insercion de registro */
                exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 710045
                return 710045
               end
            end
           else
            begin
              delete cob_cartera..ca_reajuste_det
              from cob_cartera..ca_operacion
              where red_operacion = op_operacion
              and op_banco = @w_banco

              if @@error !=0
               begin
                /* Error en eliminacion de registro */
                exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 710042
                return 710042
               end

              delete cob_cartera..ca_reajuste
              from cob_cartera..ca_operacion
              where re_operacion = op_operacion
              and op_banco = @w_banco

              if @@error != 0
               begin
                 /* Error en eliminacion de registro */
                exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 710042
                return 710042
               end
            end

       /* borrado de las tablas temporales */
       exec @w_return = cob_cartera..sp_borrar_tmp
            @s_user   = @s_user,
            @s_sesn   = @s_sesn,
            @i_banco  = @w_banco
       if @w_return != 0
          return @w_return
end
    /* SI EL TRAMITE ES DE FINANCIAMIETNO */
    -- Copiar los clientes de la tabla temporal.
    if @i_tipo = 'F'
     begin
        insert into cr_deudores
        select  @i_tramite,
                dt_cliente,
                dt_rol,
                dt_ced_ruc,
                dt_segvida,
                dt_cobro_cen
        from    cr_deudores_tmp
        where   dt_ssn = @i_trm_tmp
        
        if not exists (select 1 from cob_credito..cr_deudores where de_tramite = @i_tramite)  --PQU para integración con app Finca
        begin
           select @w_ced_ruc = en_ced_ruc from cobis..cl_ente where en_ente = @i_cliente_cca
           insert into cr_deudores values ( @i_tramite, @i_cliente_cca, 'D', @w_ced_ruc, null,'N')  
           if @@error != 0
           begin
              rollback tran
              select @w_error = 2103001
              goto ERROR
           end
        end 
        --fin PQU 
     end

    if @i_her_ssn is not null
     begin
        update cr_observaciones
        set ob_tramite = @i_tramite,
            ob_etapa = @w_etapa
        where ob_tramite = @i_her_ssn
        if @@error != 0
         begin
        /* Error en insercion de registro */
            exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 2110331
            return 2110331
         end
        update cr_ob_lineas
        set ol_tramite = @i_tramite
        where ol_tramite = @i_her_ssn
           if @@error != 0
            begin
             /* Error en insercion de registro */
             exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 2110331
             return 2110331
            end
    end
commit tran

/* retorno de datos al frontend */
select @w_periodo      = td_tdividendo,
       @w_des_periodo  = td_descripcion,
       @w_num_periodos = op_plazo,
       @w_val_tasaref  = ro_porcentaje
from   cob_cartera..ca_operacion,
       cob_cartera..ca_tdividendo,cob_cartera..ca_rubro_op
where  op_tramite      = @w_tramite
and    td_tdividendo   = op_tplazo
and    ro_concepto     = 'INT'
and    ro_operacion    = op_operacion

if @i_canal = 0 --Frontned
 begin
   select @w_periodo
   select @w_des_periodo
   select @w_num_periodos
   select @w_val_tasaref
 end

return 0

ERROR:
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

go