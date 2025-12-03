/************************************************************************/
/*   NOMBRE LOGICO:      pagcart.sp                                     */
/*   NOMBRE FISICO:      sp_pago_cartera                                */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Z.BEDON                                        */
/*   FECHA DE ESCRITURA: Ene. 1998                                      */
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
/*      Ingreso de abonos                                               */
/*      S: Seleccion de negociacion de abonos automaticos               */
/*      Q: Consulta de negociacion de abonos automaticos                */
/*      I: Insercion de abonos                                          */
/*      U: Actualizacion de negociacion de abonos automaticos           */
/*      D: Eliminacion de negociacion de abonos automaticos             */
/************************************************************************/
/*                                              MODIFICACIONES          */
/*      FECHA                   AUTOR           RAZON                   */
/*      Enero 1998       Z.Bedon            Emision Inicial             */
/* Febrero 7/2002        E.Laguna           Personalizacion errores     */
/*      May-2006         Ivan Jimenez IFJ   REQ 455 - Control de Pagos  */
/*                                          Operaciones Alternas        */
/* Junio 6/2006          Ivan Jimenez       NR 296                      */
/* Enero 18/2012         Javier Rocha       Req. 300                    */
/* Junio 22/20020        Luis Ponce         CDIG Multimoneda            */
/*  20/10/2021           G. Fernandez       Ingreso de nuevo campo de   */
/*                                          solidario en ca_abono_det   */
/*  19/11/2021           G. Fernandez       Ingreso de nuevos parametros*/
/*                                          para proceso de licitud     */
/*  10/08/2022           G. Fernandez       R191162 Cambio de parametro */
/*                                          beneficiario                */
/*  17/03/2023           K. Rodriguez       S795163 Ajustes retención   */
/*  06/03/2024           K. Rodríguez       R256950(235424) Optimizacion*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_cartera')
   drop proc sp_pago_cartera
go


create proc sp_pago_cartera
   @s_user                 login       = NULL,
   @s_term                 varchar(30) = NULL,
   @s_date                 datetime    = NULL,
   @s_sesn                 int         = NULL,
   @s_ssn                  int,
   @s_srv                  varchar(30),
   @s_ofi                  smallint    = NULL,
   --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos
   @s_ssn_branch           int         = null,
   @s_lsrv                 varchar(30) = null,
   @s_rol                  smallint    = null,
   @s_org                  char(1)     = null,
   @t_ssn_corr             int         = null,
   @t_debug                char(1)     = 'N',
   @t_file                 varchar(20) = null,
   @t_from                 descripcion = null,
   @t_trn                  smallint    = null,
   --GFP 18-11-2021 Fin de parametros solo utilizados para licitud de fondos
   @i_banco                cuenta,
   @i_secuencial           int         = NULL,
   @i_beneficiario         descripcion,
   @i_fecha_vig            datetime    = NULL,
   @i_ejecutar             char(1)     = 'S',
   @i_retencion            smallint    = 0,
   @i_en_linea             char(1)     = 'S',
   @i_producto             catalogo    = NULL,
   @i_monto_mpg            money       = 0,
   @i_cuenta               cuenta      = NULL,
   @i_moneda               tinyint     = 0,
   @i_hora_tandem          varchar(8)  = NULL,
   @i_dividendo            smallint    = 0,
   @i_tipo_dpf             char(1)     = NULL,  /* 'C'=CANCELACION 'R'=REVERSA  */
   @i_fecha_vendpf         datetime    = NULL,  /* Fecha de Vencimiento del DPF */
   @i_cheque               int         = null,
   @i_cod_banco            catalogo    = null,
   @i_tipo_cobro           catalogo    = null, 
   @i_tipo_reduccion       char(1)     = null,
   @i_pago_ext             char(1)     = 'N',   ---req 0309
   @i_sec_desem_renova     int         = null,
   @i_pago_gar_grupal      char(1)     = 'N',
   @i_referencia_pr        VARCHAR(64) = NULL,-- LGU, Por precancelacion grupal
   @i_aplica_licitud       char        = 'N', --GFP Aplica licitud de fondos,
   @i_reg_pago_grupal_hijo char(1)     = 'N', --KDR Bandera de abono de operación Hija desde un pago grupal
   @o_secuencial_ing       int         = NULL out,
   @o_msg_matriz           descripcion = NULL out,  --Req. 300
   -- GFP 12-11-2021 Parametros para licitud de fondos
   @o_consep               char(1)     = null out,
   @o_ssn                  int         = null out,   
   @o_monto                money       = null out,
   -- Parámetros salida factura electrónica
   @o_guid                 varchar(36) = null out,
   @o_fecha_registro       varchar(10) = null out,
   @o_ssn_fact             int         = null out,
   @o_orquestador_fact     char(1)     = null out
   
   as
   declare
   @w_sp_name              descripcion,
   @w_return               int,
   @w_operacionca          int,
   @w_monto                money,
   @w_moneda               tinyint,
   @w_secuencial           int,
   @w_fecha_ult_proceso    datetime,
   @w_cuota_completa       char(1),
   @w_aceptar_anticipos    char(1),
   @w_tipo_reduccion       char(1),
   @w_retencion            tinyint,
   @w_tipo_cobro           char(1),
   @w_tipo_aplicacion      char(1),
   @w_prioridad            tinyint,
   @w_cotizacion_mpg       money,
   @w_fecha                datetime,
   @w_secuencial_ing       int,
   @w_numero_recibo        int,
   @w_tipo                 char(1),
   @w_num_dec              smallint,
   @w_moneda_nacional      smallint,
   @w_cotizacion_hoy       money,
   @w_prepago_desde_lavigente char(1),
   @w_monto_mn               money,
   @w_parametro_control     catalogo,      -- NR 296
   @w_dias_retencion        smallint,      -- NR 296
   @w_error						     int,
   @w_rowcount              int,
   @w_monto_seg             MONEY,  -- LGU, precancelacion grupales hijas
   @w_cot_moneda            FLOAT,
   @w_usadeci               CHAR(1),
   @w_numdec                TINYINT,
   @w_saldo_anterior        money
   

   /*  NOMBRE DEL SP Y FECHA DE HOY */
   select  @w_sp_name = 'sp_pago_cartera'

   select @w_moneda_nacional = pa_tinyint
   from cobis..cl_parametro
   where pa_producto = 'ADM'
   and   pa_nemonico = 'MLO'
   set transaction isolation level read uncommitted

   --Encuentra parametro de decimales
   select @w_usadeci = mo_decimales
   from cobis..cl_moneda
   where mo_moneda = @i_moneda
   
   if @w_usadeci = 'S'
   begin   
     -- Numero de decimales para montos
     select @w_numdec = pa_tinyint
     from cobis..cl_parametro
     where pa_producto = 'ADM'
     and pa_nemonico = 'DECME'
   end
   else
     select @w_numdec = 0
   
   /* LECTURA DE LA OPERACION VIGENTE */
   /***********************************/

   select @w_tipo_reduccion   = @i_tipo_reduccion

   select
   @w_operacionca             = op_operacion,
   @w_moneda                  = op_moneda,
   @w_monto                   = op_monto,
   @w_fecha_ult_proceso       = op_fecha_ult_proceso,
   @w_cuota_completa          = op_cuota_completa,
   @w_aceptar_anticipos       = op_aceptar_anticipos,
   @w_tipo_cobro              = isnull(@i_tipo_cobro,op_tipo_cobro),
   @w_tipo_aplicacion         = op_tipo_aplicacion,
   @w_tipo                    = op_tipo,
   @w_prepago_desde_lavigente = op_prepago_desde_lavigente,
   @w_tipo_reduccion          = isnull(@i_tipo_reduccion, op_tipo_reduccion)
   from  ca_operacion, ca_estado
   where op_banco       = @i_banco
   and   op_estado      = es_codigo
   and   es_acepta_pago = 'S'

   if @@rowcount = 0 return 701025

   /* DETERMINAR EL VALOR DE COTIZACION DEL DIA / MONEDA OPERACION*/
   /***************************************************************/

   select 
   @w_cotizacion_hoy = 1.0,
   @w_cotizacion_mpg = 1.0

--LPO CDIG Multimoneda Se comenta INICIO
/*   if @w_moneda != @w_moneda_nacional begin
      exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda,
      @i_fecha      = @w_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion_hoy output
	  
	  --* VALOR COTIZACION MONEDA DE PAGO *
	  --***********************************
	  exec sp_buscar_cotizacion
	  @i_moneda     = @i_moneda,
	  @i_fecha      = @w_fecha_ult_proceso,
	  @o_cotizacion = @w_cotizacion_mpg output
   
   end
*/
--LPO CDIG Multimoneda Se comenta FIN


--LPO CDIG Multimoneda INICIO
-- CONVERSION DEL MONTO EN MONEDA DEL PAGO A MONEDA NACIONAL
exec @w_return = sp_conversion_moneda
@s_date             = @s_date,
@i_opcion           = 'L',
@i_operacion        = 'C', -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
@i_cot_contable     = 'N', -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables
@i_moneda_monto     = @i_moneda, 
@i_monto            = @i_monto_mpg,
@i_moneda_resultado = @w_moneda_nacional,
@o_monto_resultado  = @w_monto_mn OUT,
@o_tipo_cambio      = @w_cotizacion_mpg out
         
if @w_return <> 0
begin
   return @w_return
end

-- CONVERSION DEL MONTO EN MONEDA DE LA OPERACION A LA MONEDA NACIONAL
--(Se hace esto solo para obtener la cotizac�on de la moneda de la operacion versus la moneda nacional)
exec @w_return = sp_conversion_moneda
@s_date             = @s_date,
@i_opcion           = 'L',
@i_operacion        = 'C', -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
@i_cot_contable     = 'N', -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables
@i_moneda_monto     = @w_moneda, 
@i_monto            = @i_monto_mpg,
@i_moneda_resultado = @w_moneda_nacional,
--@o_monto_resultado  = @w_monto out,
@o_tipo_cambio      = @w_cot_moneda out

if @w_return <> 0 
begin
   return @w_return
end


--Monto en la Moneda de la Operacion:
SELECT @w_monto = round(@i_monto_mpg * @w_cotizacion_mpg / @w_cot_moneda, @w_numdec)


--LPO CDIG Multimoneda FIN

   /* RETENCION DE LA FORMA DE PAGO */
   /*********************************/

   select @w_retencion = isnull(cp_retencion,0)
   from   ca_producto
   where  cp_producto  = @i_producto
   and    cp_moneda    = @i_moneda

   select @w_retencion = isnull(@i_retencion, @w_retencion)

   /* GENERAR EL SECUENCIAL DE INGRESO */
   /************************************/
   if @i_secuencial is null
      exec @w_secuencial_ing = sp_gen_sec
      @i_operacion           = @w_operacionca
   else
      select @w_secuencial_ing = @i_secuencial

   select
   @o_secuencial_ing = @w_secuencial_ing,
   @w_numero_recibo  = @w_secuencial_ing

   /* MONTO MN */
   --select @w_monto_mpg = @i_monto_mpg * @w_cotizacion_mpg

   /* INSERCION DE CA_ABONO */
   /*************************/

   insert into ca_abono
   (
   ab_operacion,          ab_fecha_ing,                 ab_fecha_pag,            ab_cuota_completa,
   ab_aceptar_anticipos,  ab_tipo_reduccion,            ab_tipo_cobro,           ab_dias_retencion_ini,
   ab_dias_retencion,     ab_estado,                    ab_secuencial_ing,       ab_secuencial_rpa,
   ab_secuencial_pag,     ab_usuario,                   ab_terminal,             ab_tipo,
   ab_oficina,            ab_tipo_aplicacion,           ab_nro_recibo,           ab_tasa_prepago,
   ab_dividendo,          ab_prepago_desde_lavigente)
   values
   (
   @w_operacionca,        @i_fecha_vig,                 @i_fecha_vig,            @w_cuota_completa,
   @w_aceptar_anticipos,  @w_tipo_reduccion,            @w_tipo_cobro,           @w_retencion,
   @w_retencion,          'ING',                        @w_secuencial_ing,       0,
   0,                     @s_user,                      @s_term,                 'PAG',
   @s_ofi,                @w_tipo_aplicacion,           @w_numero_recibo,        0,
   @i_dividendo,          @w_prepago_desde_lavigente)

   if @@error <> 0
      return 710294

   if @i_pago_gar_grupal = 'N'
   begin
      /* INSERCION DE CA_DET_ABONO  */
      /******************************/
      insert into ca_abono_det
      (
      abd_secuencial_ing,    abd_operacion,                abd_tipo,                 abd_concepto,
      abd_cuenta,            abd_beneficiario,             abd_monto_mpg,            abd_monto_mop,
      abd_monto_mn,          abd_cotizacion_mpg,           abd_cotizacion_mop,       abd_moneda,
      abd_tcotizacion_mpg,   abd_tcotizacion_mop,          abd_cheque,               abd_cod_banco,
	  abd_solidario,         abd_descripcion)                                                                                   --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
      values
      (
      @w_secuencial_ing,     @w_operacionca,               'PAG',                    @i_producto,
      @i_cuenta,             '',                           @i_monto_mpg,             @w_monto, --isnull(@i_monto_mpg/@w_cotizacion_hoy,0),
      @w_monto_mn,           @w_cotizacion_mpg,            @w_cot_moneda,            @i_moneda,
      'N',                   'N',                          @i_cheque,                @i_cod_banco,
	  'N',                   @i_beneficiario)

      if @@error <> 0 return 710295

      if isnull(@i_referencia_pr,'') <> ''
      begin
          select @w_monto_seg = 0
          select @w_monto_seg = pr_monto_seg
          from ca_precancela_refer
          where pr_operacion = @w_operacionca
          and pr_secuencial  = (select max(prd_secuencial)
                                from   ca_precancela_refer_det
                                where  prd_operacion  = @w_operacionca
                                and    prd_referencia = @i_referencia_pr)
          select @w_monto_seg = isnull(@w_monto_seg, 0)

          if @w_monto_seg > 0 and exists(select 1 from ca_seguro_externo where se_operacion = @w_operacionca and se_estado = 'S') -- Se cruza con el valor del pago del seguro
          begin
              insert into ca_abono_det
              (
              abd_secuencial_ing,    abd_operacion,                abd_tipo,                 abd_concepto,
              abd_cuenta,            abd_beneficiario,             abd_monto_mpg,            abd_monto_mop,
              abd_monto_mn,          abd_cotizacion_mpg,           abd_cotizacion_mop,       abd_moneda,
              abd_tcotizacion_mpg,   abd_tcotizacion_mop,          abd_cheque,               abd_cod_banco,
			  abd_solidario,         abd_descripcion)                                                                                    --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
              values
              (
              @w_secuencial_ing,     @w_operacionca,               'PAG',                    'DEV_SEG',
              @i_cuenta,             '',                           @w_monto_seg,             isnull(@w_monto_seg/@w_cotizacion_hoy,0),
              @w_monto_seg,          @w_cotizacion_mpg,            @w_cotizacion_hoy,        @i_moneda,
              'N',                   'N',                          @i_cheque,                @i_cod_banco,
			  'N',                   @i_beneficiario)

              if @@error <> 0 return 710295
          end
      end
   end
   else
   begin

      insert into ca_abono_det
      (
      abd_secuencial_ing,    abd_operacion,                abd_tipo,                 abd_concepto,
      abd_cuenta,            abd_beneficiario,             abd_monto_mpg,            abd_monto_mop,
      abd_monto_mn,          abd_cotizacion_mpg,           abd_cotizacion_mop,       abd_moneda,
      abd_tcotizacion_mpg,   abd_tcotizacion_mop,          abd_cheque,               abd_cod_banco,
	  abd_solidario,         abd_descripcion)                                                                                 --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
      select
      @w_secuencial_ing,     @w_operacionca,               'PAG',                    @i_producto,
      dp_garantia,           '',                           dp_monto,                 isnull(dp_monto/@w_cotizacion_hoy,0),
      dp_monto,              @w_cotizacion_mpg,            @w_cotizacion_hoy,        @i_moneda,
      'N',                   'N',                          @i_cheque,                @i_cod_banco,
	  'N',                   @i_beneficiario
	  from #detalle_pagos
	  where dp_operacion = @w_operacionca

      if @@error <> 0 return 710295
   end


   ---NR 296
   ---Si la forma de pago es la parametrizada por el usuario CHLOCAL
   ---y el credito es clase O rotativo, se debe colocar unos dias de retencion al
   -- Pago apra que solo se aplique pasado este tiempo

   select  @w_parametro_control =  pa_char
   from cobis..cl_parametro
   where pa_nemonico = 'FPCHLO'
   and pa_producto = 'CCA'
   set transaction isolation level read uncommitted

   if @w_tipo = 'O' and @i_producto =  @w_parametro_control
   begin
      select  @w_dias_retencion =  pa_smallint
      from    cobis..cl_parametro
      where   pa_nemonico = 'DCHLO'
      and     pa_producto = 'CCA'

      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted

      if @w_rowcount = 0
         select  @w_dias_retencion = 0

      update ca_abono
      set    ab_dias_retencion      = @w_dias_retencion,
             ab_dias_retencion_ini  = @w_dias_retencion
      where  ab_operacion           = @w_operacionca
      and    ab_secuencial_ing      = @w_secuencial_ing

      select @w_retencion = @w_dias_retencion
   end
   --- NR 296

   /* INSERTAR PRIORIDADES */
   insert into ca_abono_prioridad (
   ap_secuencial_ing, ap_operacion,ap_concepto, ap_prioridad)
   select
   @w_secuencial_ing, @w_operacionca,ro_concepto, ro_prioridad
   from  ca_rubro_op
   where ro_operacion =  @w_operacionca
   and   ro_fpago not in ('L','B')

   if @@error <> 0
      return 710001

   if @i_reg_pago_grupal_hijo = 'N'
   begin
      -- Saldo Operación antes del pago
      exec @w_error     = sp_calcula_saldo
      @i_operacion      = @w_operacionca,
      @i_tipo_pago      = @w_tipo_cobro,
      @i_tipo_reduccion = @w_tipo_reduccion,
      @o_saldo          = @w_saldo_anterior out
      
      if @@error <> 0
         return 708201 -- ERROR. Retorno de ejecucion de Stored Procedure

   end

   /*CREACION DEL REGISTRO DE PAGO*/
   if (datediff(dd,@i_fecha_vig,@w_fecha_ult_proceso) = 0 and  (@i_ejecutar = 'S'))   --Aplicar en linea
   begin
      exec @w_return    = sp_registro_abono
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_ofi            = @s_ofi,
      @s_sesn           = @s_sesn,
      @s_ssn            = @s_ssn,
	  --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos
	  @s_ssn_branch     = @s_ssn_branch,
      @s_lsrv           = @s_lsrv,
      @s_rol            = @s_rol,
      @s_org            = @s_org,
      @t_ssn_corr       = @t_ssn_corr,
      @t_debug          = @t_debug,
      @t_file           = @t_file,
      @t_from           = @t_from,
      @t_trn            = @t_trn,
	  --GFP 18-11-2021 Fin de parametros solo utilizados para licitud de fondos
      @i_secuencial_ing = @w_secuencial_ing,
      @i_en_linea       = @i_en_linea,
      @i_fecha_proceso  = @i_fecha_vig,
      @i_operacionca    = @w_operacionca,
	  @i_aplica_licitud = @i_aplica_licitud,
      /*@i_banco          = @i_banco,
      @i_tipo_dpf       = @i_tipo_dpf,   --P.Fijo*/
      @i_cotizacion     = @w_cotizacion_hoy,
	  --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos
	  @o_consep         = @o_consep out,
      @o_ssn            = @o_ssn out,   
      @o_monto          = @o_monto out

      if @w_return <> 0
         return @w_return

      /** APLICACION EN LINEA DEL PAGO SIN RETENCION **/

      if @w_retencion = 0
      begin
         exec @w_return = sp_cartera_abono
         @s_user           = @s_user,
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_sesn           = @s_sesn,
         @s_ofi            = @s_ofi,
         @i_secuencial_ing = @w_secuencial_ing,
         @i_fecha_proceso  = @i_fecha_vig,
         @i_en_linea       = @i_en_linea,
         @i_operacionca    = @w_operacionca,
         @i_cotizacion     = @w_cotizacion_hoy,
         @i_pago_ext       = @i_pago_ext,
         @i_sec_desem_renova = @i_sec_desem_renova,
         @i_cuenta_aux     = @i_cuenta,   --RENOVACION
         @o_msg_matriz     = @o_msg_matriz          --Req. 300

         if @w_return <> 0
            return @w_return
			
         if @i_reg_pago_grupal_hijo = 'N'
		 begin
		 
            exec @w_return = sp_tanqueo_fact_cartera
            @s_user             = @s_user,
            @s_date             = @s_date,
            @s_rol              = @s_rol,
            @s_term             = @s_term,
            @s_ofi              = @s_ofi,
            @s_ssn              = @s_ssn,
            @t_corr             = 'N',
            @t_ssn_corr         = null,
            @t_fecha_ssn_corr   = null,
            @i_ope_banco        = @i_banco,
            @i_secuencial_ing   = @w_secuencial_ing,
            @i_tipo_operacion   = 'N', -- Individual
            @i_saldo_anterior   = @w_saldo_anterior,
			@i_fecha_ing        = @i_fecha_vig,
            @i_externo          = 'N',
            @i_tipo_tran        = 'PAG',
            @i_operacion        = 'I',
            @o_guid             = @o_guid             out,
            @o_fecha_registro   = @o_fecha_registro   out,
            @o_ssn              = @o_ssn_fact         out,
			@o_orquestador_fact = @o_orquestador_fact out
			
			if @w_return !=0  return @w_return
			
		 end
			
         
      end --retencion
   end

   return 0

go

