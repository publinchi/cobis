/************************************************************************/
/*  Archivo:                operacion_cartera.sp                        */
/*  Stored procedure:       sp_operacion_cartera                        */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Felipe Borja                                */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19      Felipe Borja      Emision Inicial                     */
/*  22/01/21      P.Narvaez         Ajustes MySql quitar tabla que no   */
/*                                  se usa tmp_montos_rule              */
/*  02/03/2022  Dilan Morales       Se envia  @i_tdividendo  en         */
/*                                   cob_cartera..sp_crear_operacion    */
/*  21/07/2022  Dilan Morales       Se añade llamado al sp              */
/*                                  sp_xsell_actualiza_monto_op         */
/*  26/07/2022  Dilan Morales       Se añade  @w_fecha_fija             */
/*  29/07/2022  Dilan Morales       Se cambia logica de cálculo de rubros */
/*  02/08/2022  Dilan Morales       Se envia @i_tipo_renovacion         */
/*  18/08/2022  Dilan Morales       R-191499: Se envia cuota en 0       */
/*  31/10/2022  Dilan Morales       R-195955: Se mantiene plazo cuando  */ 
/*                                  cuota cuando es update              */ 
/*  22/11/2023  Dilan Morales       R219906 Se añade with(nolock) por   */ 
/*                                  deadlocks                           */ 
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_operacion_cartera' and type = 'P')
    drop procedure dbo.sp_operacion_cartera
go

create proc sp_operacion_cartera (
   @s_ssn                      int          = null,
   @s_srv                      varchar(30)  = null,
   @s_lsrv                     varchar(30)  = null,
   @s_rol                      smallint     = null,
   @s_org_err                  char(1)      = null,
   @s_error                    int          = null,
   @s_sev                      tinyint      = null,
   @s_msg                      descripcion  = null,
   @s_org                      char(1)      = null,
   @t_rty                      char(1)      = null,
   @t_trn                      smallint     = null,
   @t_debug                    char(1)      = 'N',
   @t_file                     varchar(14)  = null,
   @t_from                     varchar(30)  = null,
   @s_user                     login        = null,
   @s_sesn                     int          = null,
   @s_ofi                      int          = null,
   @s_date                     datetime     = null,
   @s_term                     varchar(30)  = null,
   @i_transaccion              char(1)      = null,
   @i_anterior                 cuenta       = null,
   @i_migrada                  cuenta       = null,
   @i_tramite                  int          = null,
   @i_cliente                  int          = null,
   @i_nombre                   descripcion  = null,
   @i_sector                   catalogo     = null,
   @i_toperacion               catalogo     = null,
   @i_toperacion_ori           catalogo     = null,
   @i_oficina                  smallint     = null,
   @i_moneda                   tinyint      = null,
   @i_comentario               varchar(255) = null,
   @i_oficial                  smallint     = null,
   @i_fecha_ini                datetime     = null,
   @i_monto                    money        = null,
   @i_monto_aprobado           money        = null,
   @i_destino                  catalogo     = null,
   @i_lin_credito              cuenta       = null,
   @i_ciudad                   int          = null,
   @i_forma_pago               catalogo     = null,
   @i_cuenta                   cuenta       = null,
   @i_formato_fecha            int          = 101,
   @i_no_banco                 char(1)      = null,
   @i_num_renovacion           int          = null,
   @i_origen_fondo             catalogo     = null,
   @i_fondos_propios           char(1)      = null,
   @i_cupos_terceros           catalogo     = '',
   @i_dias_desembolso          int          = null,
   @i_fecha_ins_desembolso     datetime     = null,
   @i_nro_bmi                  char(24)     = null,
   @i_sector_contable          catalogo     = ' ',
   @i_clabas                   catalogo     = ' ',
   @i_clabope                  catalogo     = ' ',
   @i_fecha_ven_legal          datetime     = null,
   @i_cuota_ballom             char(1)      = 'N',
   @i_tcertificado             catalogo     = null,
   @i_estado_manual            char(1)      = 'N',
   @i_sujeta_nego              char(1)      = 'N',
   @i_ref_exterior             catalogo     = null,
   @i_via_judicial             char(1)      = 'N',
   @i_reest_int                char(1)      = null,
   @i_garant_emi               char(1)      = 'N',
   @i_plazo_con                catalogo     = null,
   @i_oficial_cont             smallint     = null,
   @i_externo                  char(1)      = 'S',
   @i_plazo                    smallint     = null,      --Plazo
   @i_tplazo                   catalogo      = null,     --Unidad de Tiempo
   @i_premios                  money        = null,
   @i_banco_orig               cuenta       = null,      --Operacion a duplicar
   @i_venta_cartera            char(1)      = 'N',
   @i_tipo_prioridad           char(1)      = null,
   @i_promotor                 int          = null,
   @i_comision_pro             float        = null,
   @i_subsidio                 char(1)      = 'N',
   @i_tpreferencial            char(1)      = 'N',
   @i_porcentaje_preferencial  float        = null,
   @i_monto_preferencial       money        = 0,
   @i_abono_ini                money        = null,
   @i_opcion_compra            money        = null,
   @i_beneficiario             descripcion  = null,
   @i_financia                 char(1)      = null,
   @i_tipo_tr                  char(1)      = null,      --Tipo Tramite
   @i_reajustable              char(1)      = null,
   @i_reajuste_especial        char(1)      = null,
   @i_fecha_reajuste           datetime     = null,
   @i_cuota_completa           char(1)      = null,
   @i_per_reajuste             tinyint      = null,
   @i_tipo_cobro               char(1)      = null,
   @i_tipo_reduccion           char(1)      = null,
   @i_aceptar_anticipos        char(1)      = null,
   @i_precancelacion           char(1)      = null,
   @i_tipo_aplicacion          char(1)      = null,
   @i_renovable                char(1)      = null,
   @i_fpago                    catalogo     = null,
   @i_renovacion               smallint     = null,
   @i_numero_banco             cuenta       = null,
   @i_numero_op_banco          cuenta       = null,
   @i_monto_desembolso         money        = null,
   @i_ciudad_destino           int          = null,
  -------------------------------
   /* registro anterior */
   @i_w_tipo                   char(1)      = null,
   @i_w_truta                  tinyint      = null,
   @i_w_oficina_tr             smallint     = null,
   @i_w_usuario_tr             login        = null,
   @i_w_fecha_crea             datetime     = null,
   @i_w_oficial                smallint     = null,
   @i_w_sector                 catalogo     = null,
   @i_w_ciudad                 int          = null,
   @i_w_estado                 char(1)      = null,
   @i_w_nivel_ap               tinyint      = null,
   @i_w_fecha_apr              datetime     = null,
   @i_w_usuario_apr            login        = null,
   @i_w_numero_op_banco        cuenta       = null,
   @i_w_numero_op              int          = null,
   @i_w_proposito              catalogo     = null,
   @i_w_razon                  catalogo     = null,
   @i_w_txt_razon              varchar(255) = null,
   @i_w_efecto                 catalogo     = null,
   @i_w_cliente                int          = null,
   @i_w_grupo                  int          = null,
   @i_w_fecha_inicio           datetime     = null,
   @i_w_num_dias               smallint     = 0,
   @i_w_per_revision           catalogo     = null,
   @i_w_condicion_especial     varchar(255) = null,
   @i_w_linea_credito          int          = null,
   @i_w_toperacion             catalogo     = null,
   @i_w_producto               catalogo     = null,
   @i_w_monto                  money        = 0,
   @i_w_moneda                 tinyint      = 0,
   @i_w_periodo                catalogo     = null,
   @i_w_num_periodos           smallint     = 0,
   @i_w_destino                catalogo     = null,
   @i_w_ciudad_destino         int          = null,
   @i_w_cuenta_corriente       cuenta       = null,
   @i_w_garantia_limpia        char(1)      = null,
   @i_w_renovacion             smallint     = null,
   @i_w_plazo                  smallint     = null,
   @i_w_tplazo                 catalogo     = null,
   @i_trm_tmp                  int          = null,
   @i_ult_tramite              int          = null,
   @i_tasa_asociada            char(1)      = 'N',
   @i_tasa_prenda              float        = null,
   @i_cambio_critico           char(1)      = 'N',
   @i_iniciador                descripcion  = null,
   @i_entrevistador            descripcion  = null,
   @i_cuenta_vendedor          descripcion  = null,
   @i_vendedor                 descripcion  = null,
   @i_agencia_venta            descripcion  = null,
   @i_aut_valor_aut            money        = null,
   @i_aut_abono_aut            money        = null,
   @i_Monto_Solicitado         money        = null,
   @i_canal_venta              catalogo     = null,
   @i_referido                 varchar(1)   = null,
   @i_FIniciacion              datetime     = null,
   -- Prestamos Gemelos
   @i_gemelo                   char(1)      = null,
   @i_tasa_prest_orig          float        = null,
   @i_banco_padre              cuenta       = null,
   @i_num_cuenta               char(16)     = null,
   @i_prod_bancario            smallint     = null,
   @i_actsaldo                 char(1)      = 'N',
   --PCOELLO Para manejo de Promociones
   @i_monto_promocion          money        = null,      --Valor que se va a dar al cliente por promocion
   @i_saldo_promocion          money        = null,      --Saldo pendiente de pago de la promocion
   @i_tipo_promocion           catalogo     = null,      --Tipo de promocion
   @i_cuota_promocion          money        = null,      --Cuota mensual a pagar por el cliente por promocion
   --SRO Factoring                                       
   @i_compra_operacion         char(1)      = null,      -- SRO 08-ABR-2009 - indica si el banco compra operacion
   @i_fecha_vcmto1             datetime     = null,      -- JES Se aumenta campo para Originador.
   @i_debcta                   char(1)      = null,      -- JES FIE. Para validar dia de pago.
   @i_dia_fijo                 smallint     = null,      --PQU integración
   -- FBO Tabla Amortizacion                             
   @i_pasa_definitiva          char(1)      = 'S',       --PQU integración
   @i_regenera_rubro           char(1)      = 'S',       --PQU integración
   @i_tipo                     char(1)      = null,      --LPO CDIG APIS II
   @i_dias_anio                smallint     = null,      --LPO CDIG APIS II
   @i_tipo_amortizacion        varchar(30)  = null,      --LPO CDIG APIS II
   @i_tdividendo               smallint     = null,      --LPO CDIG APIS II
   @i_periodo_cap              int          = null,      --LPO CDIG APIS II
   @i_periodo_int              int          = null,      --LPO CDIG APIS II   
   @i_dist_gracia              CHAR(1)      = null,      --LPO CDIG APIS II
   @i_gracia_cap               int          = null,      --LPO CDIG APIS II
   @i_gracia_int               int          = null,      --LPO CDIG APIS II
   @i_evitar_feriados          char(1)      = null,      --LPO CDIG APIS II
   @i_renovac                  char(1)      = null,      --LPO CDIG APIS II
   @i_mes_gracia               int          = null,      --LPO CDIG APIS II
   @i_clase_cartera            catalogo     = null,      --LPO CDIG APIS II
   @i_origen_fondos            catalogo     = null,      --LPO CDIG APIS II
   @i_base_calculo             char(1)      = null,      --LPO CDIG APIS II
   @i_causacion                char(1)      = null,      --LPO CDIG APIS II
   @i_convierte_tasa           char(1)      = null,      --LPO CDIG APIS II
   @i_tasa_equivalente         char(1)      = null,      --LPO CDIG APIS II
   @i_nace_vencida             char(1)      = null,      --LPO CDIG APIS II
   @i_cuota                    money        = null,      --PQU puede enviar valor de cuota
   @i_w_cuota                  money        = null,       --PQU puede enviar valor de cuota
   @i_forzar_update            char(1)      = 'N'        --DMO forzar actualizacion de operacion
   
)
as
declare 
   @w_sp_name                  varchar (30),
   @w_error                    int,
   @w_existe                   char(1),
   /** cambios al registro anterior **/
   @w_cambio                   char(1),   /* existe un cambio */
   @w_monto_desembolso         money,
   /* numero de banco e interno para tabla temporal de cartera */
   @w_banco                    cuenta,
   @w_operacion                int,
   @w_periodo                  catalogo,
   @w_des_periodo              descripcion,
   @w_num_periodos             int,
   @w_val_tasaref              float,
   @w_de_cliente               int,
   @w_secuencial               int,
   @w_cedula_ruc               varchar(35),
   @w_de_rol                   catalogo,
   @w_fecha_fin                datetime,
   @w_tipo                     char(1),
   @w_operacionca              int,
   @w_tplazo                   catalogo,       --Unidad de Tiempo
   @w_plazo                    smallint,       --Plazo
   @w_subtbase                 catalogo,
   @w_subporcentaje            float,
   @w_subsigno                 char(1),
   @w_subvalor                 float,
   @w_tdividendo               catalogo,
-- @w_periodo_cap              smallint,
-- @w_periodo_int              smallint,
   @w_dist_gracia              char(1),
   @w_gracia_cap               smallint,
   @w_gracia_int               smallint,
   @w_operacion_ult            int,
   @w_cuota                    money,
   @w_lin_num_banco            cuenta,
   @w_proposito                catalogo,
   @w_tasa_prend_lin           char(1),
   @w_tasa_ref                 catalogo,
   @w_tipo_amortizacion        varchar(10),
   @w_porcentaje               float,
   @w_cambia_tasa              char(1),
   @w_factor_cal               smallint,
   @w_total_dias               smallint,
   @w_resultado                smallint,
   @w_default_tdividendo       catalogo,
   @w_residuo                  smallint,
   @w_actualiza_base           char(1),
   @w_fecha_ini                datetime,
   @w_fecha_vcmto1             datetime,
   @w_tasa_min                 float,
   @w_estado_op                tinyint,
   @w_dia_fijo                 smallint,        --PQU integración
   @w_op_monto                 money,
   @w_op_monto_hija            money,
   @w_fecha_fija               char(1),
   @w_tipo_renovacion          char(1),
   @w_plazo_tmp                smallint

select  @w_sp_name  = 'sp_operacion_cartera',
        @w_existe   = 'N',
        @w_cambia_tasa    = 'N',
        @w_actualiza_base = 'N'

--PQU integración delete from cob_cartera..tmp_montos_rule

--DMO VALIDACION DE TR_TIPO
select @w_tipo_renovacion   = @i_tipo_tr
if @i_tipo_tr  = 'O'
    select @w_tipo_renovacion   = null

/**  VERIFICA SI LA OPERACION EXISTE  **/
IF @i_cuota IS null
   select @i_cuota = 0
   
select @w_cuota = @i_cuota --PQU2 integracion
select @w_plazo_tmp = @i_plazo
--PRINT 'PQU cuota en operacion carteeera ' + convert(varchar,@i_cuota)
--PRINT 'PQU plazo en operacion carteeera ' + convert(varchar,@i_plazo)
IF @w_cuota > 0
   select @i_plazo = 0
   
--DMO VALIDACION FECHA DE FIJA
select  @w_fecha_fija   = 'S'
if(@i_dia_fijo = 0 or @i_dia_fijo is null)
   select  @w_fecha_fija   = 'N'
   
select @w_operacionca = op_operacion,
       @i_numero_banco = op_banco,
       --PQU2 integracion @w_cuota = op_cuota,
       @w_estado_op = op_estado
  from cob_cartera..ca_operacion
 where op_tramite = @i_tramite


if @@rowcount = 1
   select @w_existe = 'S'

-- OPERACION YA EXISTE Y SE ACTUALIZARA LOS DATOS 

if @w_existe = 'S'
begin
 select @w_banco             = opt_banco,
        @w_operacionca       = opt_operacion,
        @w_monto_desembolso  = opt_monto,
        @i_monto_desembolso  = isnull( @i_monto_desembolso, opt_monto_aprobado),
        @w_periodo           = td_tdividendo,
        @w_des_periodo       = td_descripcion,
        @w_num_periodos      = opt_plazo,
        @w_val_tasaref       = rot_porcentaje,
        @w_lin_num_banco     = opt_lin_credito,
      --@i_cuota_ballom      = opt_cuota_ballom,--TCRM
        @w_tipo_amortizacion = opt_tipo_amortizacion,
        @w_dia_fijo          = opt_dia_fijo    --PQU integración se añade
      from cob_cartera..ca_operacion_tmp,
           cob_cartera..ca_tdividendo, 
           cob_cartera..ca_rubro_op_tmp
     where opt_tramite    = @i_tramite
       and td_tdividendo  = opt_tplazo
       and rot_tipo_rubro = 'I'
       and rot_operacion  = opt_operacion

    if @@rowcount = 0
    begin
    select @w_banco             = op_banco,
           @w_operacionca       = op_operacion,
           @w_monto_desembolso  = op_monto,
           @i_monto_desembolso  = isnull( @i_monto_desembolso, op_monto_aprobado),
           @w_periodo           = td_tdividendo,
           @w_des_periodo       = td_descripcion,
           @w_num_periodos      = op_plazo,
           @w_val_tasaref       = ro_porcentaje,
           @w_lin_num_banco     = op_lin_credito,
         --@i_cuota_ballom      = op_cuota_ballom,--TCRM
           @w_tipo_amortizacion = op_tipo_amortizacion,
           @w_dia_fijo          = op_dia_fijo     --PQU integración se añade
      from cob_cartera..ca_operacion,
           cob_cartera..ca_tdividendo,
           cob_cartera..ca_rubro_op
     where op_tramite    = @i_tramite
       and td_tdividendo = op_tplazo
       and ro_tipo_rubro = 'I'
       and ro_operacion  = op_operacion
    end

--print ' DMO @w_banco: '+ @w_banco

    select @w_periodo
    select @w_des_periodo
    select @w_num_periodos
    select @w_val_tasaref

--PQU    if (@i_pasa_definitiva = 'S')  --PQU integración
--PQU    begin               --PQU integración       
    -- valido si ha cambiado el tipo de operacion, la moneda, el monto o el sector
    --Monto no es un cambio cr¡tico
    select @w_cambio = 'N'
    if @i_toperacion_ori != @i_w_toperacion
        select @w_cambio = 'S'
--print '1. @i_toperacion_ori '+ @i_toperacion_ori +', @i_w_toperacion: '+ @i_w_toperacion +', @w_cambio:'+ @w_cambio
    if @i_moneda != @i_w_moneda
        select @w_cambio = 'S'
--print '2. @i_moneda '+ convert(varchar,@i_moneda) +', @i_w_moneda: '+ convert(varchar,@i_w_moneda) +', @w_cambio: '+ @w_cambio
    if @i_sector != @i_w_sector and  @i_sector is not null
        select @w_cambio = 'S'
--print '3. @i_sector '+ @i_sector +', @i_w_sector: '+ @i_w_sector +', @w_cambio: '+ @w_cambio

    -- BANDERA PARA ACTUALIZAR BASE DE CALCULO
    if @i_monto != @i_w_monto
       select @w_actualiza_base = 'S',
              @w_cambio = 'S',
              @i_forzar_update = 'S'
--print '4. @i_monto '+ convert(varchar,@i_monto)+', @i_w_monto: '+ convert(varchar,@i_w_monto)+', @w_cambio: '+ @w_cambio

--print '5. @i_plazo '+ convert(varchar,@i_plazo) +', @i_w_plazo: '+ convert(varchar,@i_w_plazo) +', @w_cambio: '+ @w_cambio
    if @i_plazo != @i_w_plazo and  @i_plazo is not null
        select @w_cambio = 'S'

--print '6. @i_frecpago '+ convert(varchar,@i_frecpago) +', @i_w_frecpago: '+ convert(varchar,@i_w_frecpago) +', @w_cambio: '+ @w_cambio
    if @i_tplazo != @i_w_tplazo and  @i_tplazo is not null
        select @w_cambio = 'S'
 
 if @i_cuota != @i_w_cuota and  @i_cuota is not null--PQU2 por si cambia la cuota
        select @w_cambio = 'S'  --PQU2 por si cambia la cuota
 
    if @i_dia_fijo != @w_dia_fijo
            select @w_cambio = 'S'
        --print '7. @i_dia_fijo '+ convert(varchar,@i_dia_fijo) +', @w_dia_fijo: '+ convert(varchar,@w_dia_fijo) +', @w_cambio: '+ @w_cambio
   end                                                                                                                                          

   print 'Cambio ' + @w_cambio
   
   -- SI EXISTE UN CAMBIO CRITICO 
   if @w_cambio = 'S'
     begin
        if @i_numero_op_banco is not null
         begin
           select @w_error = 2105010
           goto ERROR
         end

/*        select @w_operacion = opt_operacion,
               @i_cliente   = opt_cliente
          from cob_cartera..ca_operacion_tmp
         where opt_banco = @w_banco

        --  BORRA LAS TABLA TEMPORALES DE CARTERA  
        delete cob_cartera..ca_operacion
         where op_banco = @w_banco

        delete cob_cartera..ca_amortizacion
         where am_operacion = @w_operacion

        delete cob_cartera..ca_cuota_adicional
         where ca_operacion = @w_operacion

        delete cob_cartera..ca_dividendo
         where di_operacion = @w_operacion

        delete cob_cartera..ca_rubro_op
         where ro_operacion = @w_operacion

        delete cob_cartera..ca_tasas
         where ts_operacion = @w_operacion

        delete cob_cartera..ca_operacion_tmp
       where opt_banco = @w_banco

        delete cob_cartera..ca_dividendo_tmp
       where dit_operacion = @w_operacion

        delete cob_cartera..ca_amortizacion_tmp
       where amt_operacion = @w_operacion

        delete cob_cartera..ca_cuota_adicional_tmp
       where cat_operacion = @w_operacion

        delete cob_cartera..ca_rubro_op_tmp
       where rot_operacion = @w_operacion*/

   end   -- FIN DE @i_cambio = 'S' 
 
--PQU END

-- SI EXISTE CAMBIO CRITICO O NO EXISTE, SE CREA LA OPERACION 
--PQU integración if @w_cambio = 'S' or @w_existe = 'N'
if @w_existe = 'N' --PQU integración 
 begin
  print 'Va a crear operacion'
--print 'cob_credito..sp_operacion_cartera ==> SI EXISTE CAMBIO CRITICO O NO EXISTE, SE CREA LA OPERACION'
--print ' @w_cambio = '+ @w_cambio +', @w_existe = ' + @w_existe
--print ' @i_sector = '+ @i_sector +', @i_destino = '+ @i_destino  --null, null

    -- llamada al sp que crea los datos en tablas temporales 
    exec @w_error = cob_cartera..sp_crear_operacion 
         @s_user            = @s_user,
         @s_sesn            = @s_sesn,
         @s_ofi             = @s_ofi,
         @s_date            = @s_date,
         @s_term            = @s_term,       
         @i_anterior        = @i_anterior,
       --@i_num_renovacion  = @i_num_renovacion,
         @i_migrada         = @i_migrada,
         @i_tramite         = @i_tramite,
         @i_cliente         = @i_cliente,
         @i_nombre          = @i_nombre,
         @i_sector          = @i_sector,
         @i_toperacion      = @i_toperacion,
       --@i_toperacion_ori  = @i_toperacion_ori,
         @i_oficina         = @i_oficina,
         @i_moneda          = @i_moneda,
         @i_comentario      = null,
         @i_oficial         = @i_oficial,
         @i_fecha_ini       = @i_fecha_ini,
         @i_monto           = @i_monto,
         @i_monto_aprobado  = @i_monto_aprobado,
         @i_destino         = @i_destino,
         @i_lin_credito     = @i_lin_credito,
         @i_ciudad          = @i_ciudad_destino,    --@i_ciudad,
         @i_forma_pago      = @i_forma_pago,
         @i_cuenta          = @i_cuenta,
         @i_formato_fecha   = @i_formato_fecha,
         @i_no_banco        = 'S',                  --PQU  integracion que no genere número largo se cambia a 'S'
         @i_origen_fondos   = @i_origen_fondo,      --PQU integración quitar comentar y colocar el parámetro i_origen_fondos
         @i_fondos_propios  = @i_fondos_propios,
         @i_plazo           = @i_plazo,
         @i_tplazo          = @i_tplazo,
         @i_tdividendo      = @i_tplazo,         
         @i_dia_pago        = @i_dia_fijo,           --PQU se añade para integración
         @i_fecha_fija      = @w_fecha_fija, --DMO 
         @i_tipo_renovacion = @w_tipo_renovacion     --DMO
    if @w_error != 0   
     return @w_error
    
    --PQU integracion, el número del op_banco tiene que ser el número de operación de crédito
    /*update cob_cartera..ca_operacion_tmp
    set opt_banco = convert(varchar(20),@i_tramite)
    where opt_tramite = @i_tramite*/

 end    -- FIN de @i_cambio = 'S' or @w_existe = 'N'
else
begin   
    print 'Pasa a temporales'
    --  CARGA LAS TABLAS TEMPORALES  
    exec @w_error = cob_cartera..sp_pasotmp
        @s_user              = @s_user,
        @s_term              = @s_term,
        @i_banco             = @w_banco,
        @i_operacionca       = 'S',
        @i_dividendo         = 'S',
        @i_amortizacion      = 'S',
        @i_cuota_adicional   = 'S',
        @i_rubro_op          = 'S',
        @i_relacion_ptmo     = 'S'
        --@i_pago_automatico   = 'N',
        --@i_capital_creciente = 'S'
    
    if @w_error != 0
    begin
        goto ERROR
    end
    select @w_cambio = 'S'
 end 

-- OBTIENE EL NUMERO DE OPERACION ASIGNADO AL TRAMITE 
select @w_operacionca  = opt_operacion,
       @i_numero_banco = opt_banco
  from cob_cartera..ca_operacion_tmp with(nolock)
 where opt_tramite = @i_tramite
 
 print 'Numero operacion de temporal ' + convert(varchar,@w_operacionca)

-- ACTUALIZA LA BASE DE CALCULO DE LOS RUBROS TIPO PORCENTAJE COBRADOS EN LA LIQUIDACION 
if @w_actualiza_base = 'S'
begin
   update cob_cartera..ca_rubro_op_tmp
      set rot_base_calculo = @i_monto
    where rot_operacion    = @w_operacionca
      and rot_tipo_rubro   = 'O'
      and rot_fpago        = 'L'

   if @@error != 0
   begin
      select @w_error = 2105005
      goto ERROR
   end
end

-- SI EL TRAMITE TIENE ASOCIADA UNA LINEA, Y ESTA LINEA DE CREDITO NO HA  
-- SIDO ASOCIADA A PRESTAMO ALGUNO Y EN EL SUBLIMITE EXISTE UNA OPERACION 
-- DEL MISMO TIPO QUE EL TRAMITE, SE HEREDA EL PLAZO Y TASA DEL SUBLIMITE 
--Vivi - CD00013

if (@i_lin_credito is not null and @w_existe = 'N') or (@i_lin_credito is not null and @i_lin_credito != @w_lin_num_banco) --or (@i_tasa_prenda is not null and @i_tasa_asociada = 'S')
begin
    select @w_proposito = tr_proposito_op
      from cr_tramite
     where tr_tramite = @i_tramite

    if @i_lin_credito is not null
    begin

        -- SI ES FINANCIAMIENTO Y TIENE PLAZO Y TASA DE COMEXT NO SE HEREDA DATOS DE LA LINEA 
        if @i_tipo_tr in ('O', 'R') or (@i_tipo_tr = 'F' and @i_tplazo is null and @i_plazo is null)
        begin

            -- VERIFICA SI LA LINEA ESTA ASOCIADA A PRESTAMO ALGUNO
            if exists  (select 1 from cr_linea, cr_tramite
                         where li_num_banco     = @i_lin_credito
                           and tr_linea_credito = li_numero
                           and tr_producto      = 'CCA'
                           and tr_proposito_op  = @w_proposito
                           and tr_tramite      != @i_tramite and tr_estado != 'Z') and @i_ult_tramite is not null
            begin

--print '@i_ult_tramite ==> '+ convert(varchar,@i_ult_tramite)

                -- SI LA LINEA YA ESTA ASOCIADA, OBTIENE DATOS DEL ULTIMO PRESTAMO 
                if @i_ult_tramite is not null
                begin
                    select @w_tplazo        = op_tplazo ,
                           @w_plazo         = op_plazo ,
                           @w_tdividendo    = op_tdividendo ,
--                         @w_periodo_cap   = op_periodo_cap ,
--                         @w_periodo_int   = op_periodo_int ,
                           @w_dist_gracia   = op_dist_gracia ,
                           @w_gracia_cap    = op_gracia_cap ,
                           @w_gracia_int    = op_gracia_int,
                           @w_operacion_ult = op_operacion
                      from cob_cartera..ca_operacion, cob_cartera..ca_tdividendo
                     where op_tramite    = @i_ult_tramite
                       and td_tdividendo = op_tplazo

                   -- SI EXISTE SUBLIMITE CON EL MISMO TIPO DE OPERACION ACTUALIZA TASA Y PLAZO 
                   if @@rowcount != 0
                   begin
                      --'No Existe Tipo de Plazo o Plazo'
                      if @w_tplazo is null or @w_plazo is null
                         return 2101075

--                      if @w_periodo_cap > @w_plazo
--                         select @w_plazo = @w_periodo_cap

                      select --@i_tplazo      = @w_tplazo,
                             --@i_plazo       = @w_plazo,
                               @w_cuota       = 0

                      select @w_subporcentaje = isnull( @i_tasa_prenda, ro_porcentaje),
                             @w_subtbase      = ro_referencial,
                             @w_subsigno      = isnull( ro_signo, '+'),
                             @w_subvalor      = isnull( ro_factor , 0),
                             @w_tasa_min      = ro_tasa_minima   --PQU integración se quita comentar
                        from cob_cartera..ca_rubro_op, cobis..cl_parametro
                       where ro_operacion  = @w_operacion_ult
                         and ro_concepto   = pa_char
                         and ro_tipo_rubro = 'I'
                         and pa_producto   = 'CCA'
                         and pa_nemonico   = 'int'

              if @i_tasa_prenda is not null
                      begin
                         if @w_subsigno = '+'
                      select @w_subporcentaje = @w_subporcentaje + isnull( @w_subvalor, 0)
                         else
                            select @w_subporcentaje = @w_subporcentaje - isnull( @w_subvalor, 0)
                      end

                      -- ACTUALIZA LOS RUBROS DE LA TASA 
                      update cob_cartera..ca_rubro_op_tmp
                        set rot_porcentaje  = @w_subporcentaje,
                            rot_referencial = (case when @i_tasa_asociada = 'S' then isnull( @w_subtbase, rot_referencial)
                       else @w_subtbase end),
                            rot_signo       = @w_subsigno,
                            rot_factor      = @w_subvalor,
                            rot_tasa_minima = @w_tasa_min  --PQU integración se quita comentar
                       from cobis..cl_parametro
                      where rot_operacion = @w_operacionca
                        and rot_concepto  = pa_char
                        and rot_tipo_rubro = 'I'
                        and pa_producto   = 'CCA'
                        and pa_nemonico   = 'int'

                      if @@error != 0 or @@rowcount = 0
                         return 2105005
                   end
                end
            end
            else
            begin

--verificar si linea es prendaria, si no lo es y tiene tasa fija, dejo en blando el campo rot_referencial

                -- SI LA LINEA NO ESTA ASOCIADA, VERIFICA Y OBTIENE DATOS A HEREDAR DEL 
                -- SUBLIMITE (tasa y plazo) Y CALCULA NUEVA FECHA DE VENCIMIENTO        
                select  @w_tplazo         = om_tplazo,   --PQU integración le quité el comentar
                        @w_plazo          = om_plazos,
                        @w_total_dias     = (td_factor * om_plazos),   --RZ
                      --@w_subtbase       = om_tbase,
                      --@w_subporcentaje  = isnull( @i_tasa_prenda, om_porcentaje),
                      --@w_subsigno       = isnull( om_signo, '+'),
                      --@w_subvalor       = isnull( om_valor, 0),
                        @w_tasa_prend_lin = tr_tasa_asociada--,
                      --@w_tasa_min       = om_tasa_minima
                  from cr_linea, cr_lin_ope_moneda, 
                       cob_cartera..ca_tdividendo, 
                       cr_tramite
                 where li_num_banco  = @i_lin_credito
                   and li_numero     = om_linea
                   and om_toperacion = @i_toperacion
                   and td_tdividendo = om_tplazo
                   --and om_proposito_op = @w_proposito
                   and tr_tramite    = li_tramite
                   --fin PQU integración quite comentar

                -- SI EXISTE SUBLIMITE CON EL MISMO TIPO DE OPERACION ACTUALIZA TASA Y PLAZO 
                if @@rowcount != 0
                begin
                    -- SYR 13/AGO/2007 Advertencia para tasa de prenda no definida
                    if @w_subporcentaje is null
                    begin
                         print 'ADVERTENCIA: Valor de porcentaje de tasa de prenda No definido, Se asumira cero (0) '
                         select @w_subporcentaje = 0
                    end

                    --Obtener el Factor del Tipo de Operacion del tramite

                     select @w_factor_cal   = td_factor,
                            @w_default_tdividendo  = dt_tdividendo
                      from cob_cartera..ca_default_toperacion,
                           cob_cartera..ca_tdividendo
                     where dt_toperacion = @i_toperacion
                       and dt_moneda     = @i_moneda
                       and td_tdividendo = dt_tdividendo

                   --Division entre los dias de la linea y el factor

                    select @w_resultado = @w_total_dias / @w_factor_cal
                    select @w_residuo = @w_total_dias -(@w_resultado *  @w_factor_cal)
           if @w_residuo > 0
                    select @w_resultado = @w_resultado + 1

                   --'No Existe Tipo de Plazo o Plazo'
                   if @w_tplazo is null or @w_plazo is null
                      return 2101075

                    select @i_tplazo   = @w_default_tdividendo, --@w_tplazo,
                           @i_plazo      = @w_resultado,--@w_plazo,
                           @w_cuota      = 0

                   --Vivi, Tasa Libor
                   if @w_subtbase is not null and @w_subtbase != ''
                   begin
                       -- OBTIENE EL VALOR DE LA TASA BASE 
                       exec @w_error = cob_cartera..sp_valor
                            @i_operacion   = 'H',
                            @i_tipoh       = 'B',
                            @i_tipo        = @w_subtbase,
                            @i_sector      = @i_sector,
                            @i_credito     = 'S',
                            @o_tasa        = @w_subporcentaje out
                       if @w_error != 0
                          goto ERROR
                   end

                   if @w_subsigno = '+'
                      select @w_subporcentaje = isnull(@w_subporcentaje,0) + isnull( @w_subvalor, 0)
                   else
                      select @w_subporcentaje = isnull(@w_subporcentaje,0) - isnull( @w_subvalor, 0)

                   -- ACTUALIZA LOS RUBROS DE LA TASA 
                   update cob_cartera..ca_rubro_op_tmp
                     set rot_porcentaje  = @w_subporcentaje,   -- porcentaje +/- valor -- TOTAL
                         rot_referencial = isnull(@w_subtbase, rot_referencial ),
                         rot_signo       = @w_subsigno,
                         rot_factor      = @w_subvalor,
                         rot_tasa_minima = @w_tasa_min--PQU integración se quita comentar
                       from cobis..cl_parametro
                   where rot_operacion   = @w_operacionca
                     and rot_concepto    = pa_char
                     and rot_tipo_rubro  = 'I'
                     and pa_producto     = 'CCA'
                     and pa_nemonico     = 'int'

                   if @@error != 0 or @@rowcount = 0
                      return 2105005

                   if @w_subtbase is null and @w_tasa_prend_lin = 'N'
                      update cob_cartera..ca_rubro_op_tmp
                         set rot_referencial = @w_subtbase
                        from cobis..cl_parametro
                       where rot_operacion = @w_operacionca
                         and rot_concepto  = pa_char
                         and rot_tipo_rubro = 'I'
                         and pa_producto   = 'CCA'
                         and pa_nemonico   = 'int'
                end  --rowcount
            end --else
        end
    end
end

if @i_tasa_asociada = 'S'
begin
  --ACTUALIZA LOS RUBROS DE LA TASA 
   select @w_subsigno    = rot_signo,
          @w_subvalor    = rot_factor,
          @w_porcentaje  = rot_porcentaje
     from cob_cartera..ca_rubro_op_tmp, 
          cobis..cl_parametro
    where rot_operacion  = @w_operacionca
      and rot_concepto   = pa_char
      and rot_tipo_rubro = 'I'
      and pa_producto    = 'CCA'
      and pa_nemonico    = 'int'

   if @w_subsigno = '+'
      select @w_subporcentaje = @i_tasa_prenda + isnull( @w_subvalor, 0)
   else
      select @w_subporcentaje = @i_tasa_prenda - isnull( @w_subvalor, 0)

   update cob_cartera..ca_rubro_op_tmp
      set rot_porcentaje  = @w_subporcentaje
     from cobis..cl_parametro
    where rot_operacion = @w_operacionca
      and rot_concepto  = pa_char
      and rot_tipo_rubro = 'I'
      and pa_producto   = 'CCA'
      and pa_nemonico   = 'int'

   if @@error != 0 or @@rowcount = 0
   begin
      select @w_error = 2105005
      goto ERROR
   end

   if @w_porcentaje != @w_subporcentaje
      select @w_cambia_tasa = 'S'
end

--REGISTRAR A LOS CLIENTES DEL TRAMITE EN LA TABLA DE CLIENTES DE CARTERA
delete cob_cartera..ca_cliente_tmp
 where clt_user = @s_user
   and clt_sesion = @s_sesn

insert into cob_cartera..ca_cliente_tmp
      (clt_user,       clt_sesion,        clt_operacion,
       clt_cliente,    clt_rol,           clt_ced_ruc,
       clt_titular,    clt_secuencial)
select @s_user,        @s_sesn,           @i_numero_banco,
       de_cliente,     de_rol,            de_ced_ruc,
       de_cliente,     0
  from cr_deudores
 where de_tramite = @i_tramite AND de_rol = 'D' --PQU OJO


if @@error !=0
begin
   select @w_error = 703023
   goto ERROR
end

-- @i_cuota=0 --> para Recalcular la cuota    @i_cuota=null --> para Mantener la cuota calculada



if @w_cambio = 'S' --PQU integración se añade esto 
begin
--print 'Entra a modificar operacion' 
--print 'Entra a modificar operacion' 
--exec @w_error = cob_pac..sp_modificar_operacion_busin

   select @w_cuota = 0
   
   exec @w_error = cob_cartera..sp_modificar_operacion
        @s_user                 = @s_user,
        @s_sesn                 = @s_sesn,
        @s_date                 = @s_date,
        @s_term                 = @s_term,
        @s_ofi                  = @s_ofi,
        @i_calcular_tabla       = 'S',
        @i_tabla_nueva          = 'S',
        @i_operacionca          = @w_operacionca,
        @i_banco                = @i_numero_banco,
        @i_tramite              = @i_tramite,
        @i_cliente              = @i_cliente,
        @i_nombre               = @i_nombre,
        @i_sector               = @i_sector,
        @i_toperacion           = @i_toperacion,
        @i_oficina              = @i_oficina,
        @i_moneda               = @i_moneda,
        @i_comentario           = @i_comentario,
        @i_oficial              = @i_oficial,
        @i_fecha_ini            = @w_fecha_ini,
        @i_fecha_fin            = @w_fecha_fin,
        @i_fecha_ult_proceso    = @s_date,
--      @i_fecha_liq            = @i_fecha_liq,
        @i_fecha_reajuste       = @i_fecha_reajuste,
        @i_monto                = @i_monto,
        @i_monto_aprobado       = @i_monto_aprobado,
        @i_destino              = @i_destino,
        @i_lin_credito          = @i_lin_credito,
--      @i_modifica_linea       = 'S',
        @i_ciudad               = @i_ciudad_destino,           --@i_ciudad,
--      @i_estado               = @i_estado,
        @i_periodo_reajuste     = @i_per_reajuste,
        @i_reajuste_especial    = @i_reajuste_especial,
        @i_forma_pago           = @i_forma_pago,
        @i_cuenta               = @i_cuenta,
        @i_cuota_completa       = @i_cuota_completa,
        @i_tipo_cobro           = @i_tipo_cobro,
        @i_tipo_reduccion       = @i_tipo_reduccion,
        @i_aceptar_anticipos    = @i_aceptar_anticipos,
        @i_precancelacion       = @i_precancelacion,
      --@i_tipo_aplicacion      = @i_tipo_aplicacion,
        @i_tplazo               = @i_tplazo,
        @i_tdividendo           = @i_tplazo,
        @i_plazo                = @w_plazo_tmp,
        @i_cuota                = @w_cuota,
        --HEREDA DEL ULTIMO PRESTAMO CUANDO TIENE ASOCIADA UNA LINEA
      --@i_tdividendo           = @w_tdividendo,
        @i_periodo_cap          = @i_periodo_cap,
        @i_periodo_int          = @i_periodo_int,
        @i_dist_gracia          = @i_dist_gracia,              --@w_dist_gracia,
        @i_gracia_cap           = @i_gracia_cap,               --@w_gracia_cap,
        @i_gracia_int           = @i_gracia_int,               --@w_gracia_int,
      --@i_num_renovacion       = @i_num_renovacion,
        @i_formato_fecha        = @i_formato_fecha,
        @i_reajustable          = @i_reajustable,
      --@i_origen_fondo         = @i_origen_fondo,
        @i_fondos_propios       = @i_fondos_propios,
      /*@i_dias_desembolso      = @i_dias_desembolso,
        @i_fecha_ins_desembolso = @i_fecha_ins_desembolso,*/
--      @i_nro_bmi              = @i_nro_bmi,
      /*@i_cupos_terceros       = @i_cupos_terceros,
        @i_sector_contable      = @i_sector_contable,
        @i_clabas               = @i_clabas,
        @i_clabope              = @i_clabope,*/
--      @i_plazo_contable       = @i_plazo_con,
--      @i_fecha_ven_legal      = @i_fecha_ven_legal,
      --@i_cuota_ballom         = @i_cuota_ballom,
--      @i_tcertificado         = null,
--      @i_estado_manual        = null,
        @i_sujeta_nego          = null,
        @i_ref_exterior         = null,
/*      @i_via_judicial         = null,
        @i_reest_int            = null,
        @i_garant_emi           = null,
        @i_oficial_cont         = null,
        @i_venta_cartera        = @i_venta_cartera,
        @i_banco_orig           = @i_banco_orig,*/
      --@i_tipo_prioridad       = @i_tipo_prioridad,
/*      @i_promotor             = @i_promotor,
        @i_comision_pro         = @i_comision_pro,
        @i_subsidio             = @i_subsidio,*/
      /*@i_financia             = @i_financia,
        @i_abono_ini            = @i_abono_ini,
        @i_opcion_compra        = @i_opcion_compra,
        @i_beneficiario         = @i_beneficiario,*/
      --@i_tpreferencial        = @i_tpreferencial,
        @i_tipo_amortizacion    = @w_tipo_amortizacion,
/*      @i_iniciador            = @i_iniciador,
        @i_entrevistador        = @i_entrevistador,
        @i_cuenta_vendedor      = @i_cuenta_vendedor,
        @i_vendedor             = @i_vendedor,
        @i_agencia_venta        = @i_agencia_venta, */
      --@i_fecha_vcmto1         = @w_fecha_vcmto1,
--      @i_actsaldo             = @i_actsaldo,
      --@i_compra_operacion     = @i_compra_operacion,  --SRO Factoring
        @i_dia_fijo             = @i_dia_fijo,
        @i_regenera_rubro       = @i_regenera_rubro,
        @i_grupal               = 'N',
        @i_fecha_fija           = @w_fecha_fija, --DMO 
        @i_tipo_renovacion      = @w_tipo_renovacion     --DMO
        
    --print'TRANSACCIONES despues sp_modificar_operacion_busin:' +convert(varchar(10),@@trancount)
    if @w_error != 0   
     return @w_error
     
    
    exec @w_error = cob_cartera..sp_xsell_actualiza_monto_op
               @i_banco              = @i_numero_banco,
               @s_user               = @s_user,
               @s_term               = @s_term,
               @s_ofi                = @s_ofi,
               @s_date               = @s_date,
               @i_monto_nuevo        = @i_monto_aprobado,
             --@i_sector             = @i_sector,  --No se puede modificar sector en registro de montos
             --@i_destino            = @i_tr_cod_actividad, 
               @i_grupal             = 'N',
               @i_pasa_a_temporales  = 'N',
               @i_recalcular_rub     = 'S',
               @i_pasar_a_def        = 'N',
               @o_monto_calculado    = @w_op_monto_hija out
    
    if @w_error != 0
     return @w_error
     
end  --fin PQU

-- SI EXISTE CAMBIO CRITICO O NO EXISTE, SE CREA LA OPERACION 
if @w_cambio = 'S' or @w_existe = 'N'
begin
   print 'cob_credito..sp_operacion_cartera ==> SI EXISTE CAMBIO CRITICO O NO EXISTE, SE llama a cob_cartera..sp_operacion_def'
   -- Llamada al sp que pasa los datos a tablas definitivas
   if(@i_pasa_definitiva = 'S')  --PQU integración se añade
   begin     --PQU integración se añade
      print 'va a pasar a definitivas'
      exec @w_error =  cob_cartera..sp_operacion_def
      @s_date    = @s_date,
      @s_sesn    = @s_sesn,
      @s_user    = @s_user,
      @s_ofi     = @s_ofi,
      @i_banco   = @i_numero_banco--,
      --@i_actsaldo= @i_actsaldo
      if @w_error != 0 return @w_error
      
      print 'Paso a definitivas'

      --Borrado de las tablas temporales
      exec @w_error = cob_cartera..sp_borrar_tmp
                @s_user   = @s_user,
                @s_sesn   = @s_sesn,
                @i_banco  = @i_numero_banco
      if @w_error != 0 return @w_error     
   end 

--Pasar los registros a la tabla temporal, se le da mantenimiento desde el frontend de credito

-- SINO ES UN TRAMITE DE WORFLOW, SE VERIFICA TABLA DE DESEMBOLSO 
if @i_FIniciacion is null and @i_tipo_tr = 'R' and not exists( select 1 from cr_desembolso where dm_operacion = @w_operacionca )
begin
   insert into cr_desembolso
        (dm_operacion,  dm_secuencial, dm_fecha_des,  dm_monto,  dm_monto_mn, dm_cotizacion, dm_estado)
   select op_operacion, 1, op_fecha_ini, op_monto, ( op_monto*ct_valor), ct_valor, 'NA'
     from cob_cartera..ca_operacion, cb_cotizaciones
    where op_operacion = @w_operacionca
      and op_moneda    = ct_moneda

   if @@error != 0
   begin
      select @w_error = 2103001
      goto ERROR
   end
end
end

--PQU revisar si quedó en temporales borrarla
if exists(select 1 from cob_cartera..ca_operacion_tmp with(nolock) where opt_operacion = @w_operacionca)
begin
    --Borrado de las tablas temporales
      exec @w_error = cob_cartera..sp_borrar_tmp
                @s_user   = @s_user,
                @s_sesn   = @s_sesn,
                @i_banco  = @i_numero_banco
      if @w_error != 0 return @w_error

end 

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug='N',@t_file='',
   @t_from =@w_sp_name, @i_num = @w_error
   return @w_error

go
