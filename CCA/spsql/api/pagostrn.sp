USE cob_cartera
GO
/************************************************************************************/
/*  Archivo:            pagos_trn.sp                                                */
/*  Stored procedure:   sp_pagos_trn                                                */
/*  Base de datos:      cob_cartera                                                 */
/*  Producto:           Cartera                                                     */
/*  Disenado por:       Luis Castellanos                                            */
/*  Fecha de creacion:  11/MAY/2020                                                 */
/************************************************************************************/
/*          IMPORTANTE                                                              */
/*  Este programa es propiedad de "COBISCORP". Ha sido desarrollado                 */
/*  bajo el ambiente operativo COBIS-sistema desarrollado por                       */
/*  "COBISCORP S.A."-Ecuador                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como                      */
/*  cualquier alteracion o agregado hecho por alguno de sus                         */
/*  usuarios sin el debido consentimiento por escrito de la                         */
/*  Gerencia General de COBISCORP o su representante.                               */
/************************************************************************************/
/*          PROPOSITO                                                               */
/*  Este procedimiento permite la ejecucion de los procedimientos almacenados para  */
/*  Ingreso de un Abono a una operacion de Cartera                                  */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  11/MAY/2020       Luis Castellanos        Emision Inicial                       */
/************************************************************************************/

if exists ( select 1 from sysobjects where name = 'sp_pagos_trn' )
   drop proc sp_pagos_trn
go

create proc sp_pagos_trn
   @s_user                 login       = NULL,
   @s_term                 varchar(30) = NULL,
   @s_date                 datetime    = NULL,
   @s_sesn                 int         = NULL,
   @s_ssn                  int,
   @s_srv                  varchar(30),
   @s_ofi                  smallint    = NULL,
   @i_operacion            char(1)     = NULL,
   @i_banco                varchar(16) = NULL,
   @i_operacionca          int         = NULL,
   @i_secuencial           int         = NULL,
   @i_beneficiario         varchar(64) = NULL,
   @i_fecha_vig            datetime    = NULL,
   @i_ejecutar             char(1)     = 'S',
   @i_retencion            smallint    = 0,
   @i_en_linea             char(1)     = 'S',
   @i_producto             varchar(10) = NULL,
   @i_monto_mpg            money       = 0,
   @i_cuenta               varchar(16) = NULL,
   @i_moneda               tinyint     = 0,
   @i_dividendo            smallint    = 0,
   @i_cheque               int         = null,
   @i_cod_banco            varchar(10) = null,
   @i_tipo_cobro           varchar(10) = null, 
   @i_tipo_reduccion       char(1)     = null,
   @i_tipo_aplicacion      char(1)     = null,
   @i_pago_ext             char(1)     = 'N',   
   @i_sec_desem_renova     int         = null,
   @i_pago_gar_grupal      char(1)     = 'N',
   @i_formato_fecha        int         = 101,
   @i_referencia_pr        varchar(64) = NULL,-- Por precancelacion grupal
   @i_valor_multa          money       = 0,
   @i_valida_sobrante      char(1)     = 'S',
   @i_simulado             char(1)     = 'N',  --Pago Simulado
   @i_condonacion          char(1)     = 'N',
   @i_rubro_condonar       varchar(10) = NULL, --Conceptos o rubros a condonar 
   @o_secuencial_ing       int         = NULL out,
   @o_msg_matriz           varchar(64) = NULL out  
   as
   declare
   @w_sp_name              varchar(64),
   @w_return               int,
   @w_est_vigente          tinyint,
   @w_est_no_vigente       tinyint,
   @w_est_vencido          tinyint,
   @w_est_mora             tinyint,
   @w_est_cancelado        tinyint,
   @w_operacionca          int,
   @w_monto                money,
   @w_moneda               tinyint,
   @w_fecha_ini            datetime,
   @w_toperacion           varchar(10),
   @w_secuencial           int,
   @w_estado               tinyint,
   @w_fecha_ult_proceso    datetime,
   @w_cuota_completa       char(1),
   @w_aceptar_anticipos    char(1),
   @w_tipo_reduccion       char(1),
   @w_retencion            tinyint,
   @w_tipo_cobro           char(1),
   @w_tipo_aplicacion      char(1),
   @w_prioridad            tinyint,
   @w_cotizacion_mpg       money,
   @w_tcotizacion_mop      char(1),
   @w_tcotizacion_mpg      char(1),
   @w_fecha                datetime,
   @w_pago_atx             char(1),
   @w_secuencial_ing       int,
   @w_concepto_aux         varchar(10),
   @w_valor                varchar(20),
   @w_procedimiento        varchar(64),
   @w_numero_recibo        int,
   @w_tipo                 char(1),
   @w_div_vigente          smallint,
   @w_valor_rubro          money,
   @w_concepto             varchar(10),
   @w_num_dec              smallint,
   @w_moneda_nacional      smallint,
   @w_tcot_moneda          char(1),
   @w_beneficiario         char(50),
   @w_monto_mop            money,
   @w_monto_mn             money,
   @w_cot_moneda           float,
   @w_moneda_op            smallint,
   @w_num_periodo_d        smallint,
   @w_periodo_d            varchar(10),
   @w_valor_pagado         money,
   @w_fecha_proceso        datetime,
   @w_valor_dia_rubro      money,
   @w_dias_div             int,
   @w_di_fecha_ven         datetime,
   @w_dias_faltan_cuota    int,
   @w_devolucion           money,
   @w_monto_max            money,
   @w_fecha_ven_op         datetime,
   @w_cotizacion_hoy       money,
   @w_prepago_desde_lavigente char(1),
   @w_monto_mpg               money,
   @w_parametro_control       varchar(10),
   @w_dias_retencion          smallint,
   @w_error		      int,
   @w_operacion_alterna       int,
   @w_num_dec_op              smallint,
   @w_rowcount                int,
   @w_monto_seg               money  

   /*  NOMBRE DEL SP Y FECHA DE HOY */
   select  @w_sp_name = 'sp_pagos_trn'

   /* ESTADOS DE CARTERA */
   exec @w_error = sp_estados_cca
   @o_est_novigente  = @w_est_no_vigente   out,
   @o_est_vigente    = @w_est_vigente   out,
   @o_est_vencido    = @w_est_vencido   out,
   @o_est_cancelado  = @w_est_cancelado out
   
   if @w_error <> 0  return @w_error

   /* LECTURA DE LA OPERACION VIGENTE */
   /***********************************/
   if @i_banco is null and @i_operacionca is null
   begin
         select @o_msg_matriz = 'ERROR NO SE INDICA EL NUMERO DE PRESTAMO'
         return 725054 --'No existe la operación'
   end


if @i_operacion = 'I' begin

   select @w_moneda_nacional = pa_tinyint
   from cobis..cl_parametro
   where pa_producto = 'ADM'
   and   pa_nemonico = 'MLO'
   set transaction isolation level read uncommitted

   /*DETERMINAR FECHA DE PROCESO*/
   select @w_fecha_proceso = fc_fecha_cierre,
          @s_date          = isnull(@s_date, fc_fecha_cierre)
   from cobis..ba_fecha_cierre 
   where  fc_producto = 7

   select
   @w_operacionca             = op_operacion,
   @w_moneda                  = op_moneda,
   @w_monto                   = op_monto,
   @w_fecha_ini               = op_fecha_ini,
   @w_toperacion              = op_toperacion,
   @w_estado                  = op_estado,
   @w_fecha_ult_proceso       = op_fecha_ult_proceso,
   @w_cuota_completa          = op_cuota_completa,
   @w_aceptar_anticipos       = op_aceptar_anticipos,
   @w_tipo_cobro              = isnull(@i_tipo_cobro,op_tipo_cobro),
   @w_tipo_aplicacion         = isnull(@i_tipo_aplicacion,op_tipo_aplicacion),
   @w_tipo                    = op_tipo,
   @w_num_periodo_d           = op_periodo_int,
   @w_periodo_d               = op_tdividendo,
   @w_fecha_ven_op            = op_fecha_fin,
   @w_prepago_desde_lavigente = op_prepago_desde_lavigente,
   @w_tipo_reduccion          = isnull(@i_tipo_reduccion, op_tipo_reduccion)
   from  ca_operacion, ca_estado
   where op_banco       = @i_banco
   and   op_estado      = es_codigo
   and   es_acepta_pago = 'S'

   if @@rowcount = 0 return 701025

   if exists (select 1 from cob_cartera..ca_operacion_tmp where opt_operacion = @w_operacionca)
      delete cob_cartera..ca_operacion_tmp where opt_operacion = @w_operacionca

   if datediff(dd,@w_fecha_ult_proceso, @i_fecha_vig) <> 0 begin 
  
      if @i_fecha_vig < @w_fecha_ini 
         return 710070

      exec @w_error = sp_fecha_valor 
      @s_date        = @w_fecha_proceso,     
      @s_user        = @s_user,
      @s_term        = @s_term,
      @s_ofi         = @s_ofi ,
      @t_trn         = 7049,
      @i_fecha_mov   = @w_fecha_proceso, 
      @i_fecha_valor = @i_fecha_vig,
      @i_banco       = @i_banco,
      @i_secuencial  = 1,
      @i_operacion   = 'F'
   
      if @w_error != 0 begin
         select @o_msg_matriz = 'ERROR AL EJECUTAR PROCESO DE FECHA VALOR INICIAL'
         return @w_error
      end
  
   end


   /* DETERMINAR EL VALOR DE COTIZACION DEL DIA / MONEDA OPERACION*/
   /***************************************************************/

   select 
   @w_cotizacion_hoy = 1.0,
   @w_cotizacion_mpg = 1.0
	  
   if @w_moneda != @w_moneda_nacional begin
      exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda,
      @i_fecha      = @w_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion_hoy output
	  
	  /* VALOR COTIZACION MONEDA DE PAGO */
	  /***********************************/
	  exec sp_buscar_cotizacion
	  @i_moneda     = @i_moneda,
	  @i_fecha      = @w_fecha_ult_proceso,
	  @o_cotizacion = @w_cotizacion_mpg output
   
   end

   /* RETENCION DE LA FORMA DE PAGO */
   /*********************************/

   select @w_retencion = isnull(cp_retencion,0)
   from   ca_producto
   where  cp_categoria = @i_producto
   and    cp_moneda    = @i_moneda

   select @w_retencion = isnull(@w_retencion,0)

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
   select @w_monto_mpg = @i_monto_mpg * @w_cotizacion_mpg

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
      if @i_condonacion = 'S' 
      begin
         insert into ca_abono_det
         (
         abd_secuencial_ing,    abd_operacion,                abd_tipo,                 abd_concepto,
         abd_cuenta,            abd_beneficiario,             abd_monto_mpg,            abd_monto_mop,
         abd_monto_mn,          abd_cotizacion_mpg,           abd_cotizacion_mop,       abd_moneda,
         abd_tcotizacion_mpg,   abd_tcotizacion_mop,          abd_cheque,               abd_cod_banco,
		 abd_solidario)                                                                                    --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
         values
         (
         @w_secuencial_ing,     @w_operacionca,               'CON',                    @i_rubro_condonar,
         @i_cuenta,             isnull(@i_beneficiario,''),   @i_monto_mpg,             isnull(@i_monto_mpg/@w_cotizacion_hoy,0),
         @w_monto_mpg,          @w_cotizacion_mpg,            @w_cotizacion_hoy,        @i_moneda,
         'N',                   'N',                          @i_cheque,                @i_cod_banco,
		 'N')

         if @@error <> 0 return 710295
      end
      else
      begin
         insert into ca_abono_det
         (
         abd_secuencial_ing,    abd_operacion,                abd_tipo,                 abd_concepto,
         abd_cuenta,            abd_beneficiario,             abd_monto_mpg,            abd_monto_mop,
         abd_monto_mn,          abd_cotizacion_mpg,           abd_cotizacion_mop,       abd_moneda,
         abd_tcotizacion_mpg,   abd_tcotizacion_mop,          abd_cheque,               abd_cod_banco,
		 abd_solidario)
         values
         (
         @w_secuencial_ing,     @w_operacionca,               'PAG',                    @i_producto,
         @i_cuenta,             isnull(@i_beneficiario,''),   @i_monto_mpg,             isnull(@i_monto_mpg/@w_cotizacion_hoy,0),
         @w_monto_mpg,          @w_cotizacion_mpg,            @w_cotizacion_hoy,        @i_moneda,
         'N',                   'N',                          @i_cheque,                @i_cod_banco,
		 'N')

         if @@error <> 0 return 710295
      end
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
			  abd_solidario)
              values
              (
              @w_secuencial_ing,     @w_operacionca,               'PAG',                    'DEV_SEG',
              @i_cuenta,             isnull(@i_beneficiario,''),   @w_monto_seg,             isnull(@w_monto_seg/@w_cotizacion_hoy,0),
              @w_monto_seg,          @w_cotizacion_mpg,            @w_cotizacion_hoy,        @i_moneda,
              'N',                   'N',                          @i_cheque,                @i_cod_banco,
			  'N')

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
      abd_tcotizacion_mpg,   abd_tcotizacion_mop,          abd_cheque,               abd_cod_banco)
      select
      @w_secuencial_ing,     @w_operacionca,               'PAG',                    @i_producto,
      dp_garantia,           isnull(@i_beneficiario,''),   dp_monto,                 isnull(dp_monto/@w_cotizacion_hoy,0),
      dp_monto,                 @w_cotizacion_mpg,            @w_cotizacion_hoy,        @i_moneda,
      'N',                   'N',                          @i_cheque,                @i_cod_banco
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

      select @i_retencion = @w_dias_retencion
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
      @i_secuencial_ing = @w_secuencial_ing,
      @i_en_linea       = @i_en_linea,
      @i_fecha_proceso  = @i_fecha_vig,
      @i_operacionca    = @w_operacionca,
      /*@i_banco          = @i_banco,
      @i_tipo_dpf       = @i_tipo_dpf,   --P.Fijo*/
      @i_cotizacion     = @w_cotizacion_hoy

      if @w_return <> 0
         return @w_return

      /** APLICACION EN LINEA DEL PAGO SIN RETENCION **/

      if @i_retencion = 0
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
         @i_valor_multa    = @i_valor_multa,
         @i_sec_desem_renova = @i_sec_desem_renova,
         @i_simulado         = @i_simulado,
         @i_cuenta_aux     = @i_cuenta,   --RENOVACION
         @o_msg_matriz     = @o_msg_matriz          --Req. 300

         if @w_return <> 0
            return @w_return
      end --retencion
   end

   select 
   @w_fecha_ult_proceso = op_fecha_ult_proceso
   from  ca_operacion 
   where op_banco    = @i_banco


   if datediff(dd,@w_fecha_proceso, @i_fecha_vig)<>0 begin
  
      exec @w_error = sp_fecha_valor 
      @s_date        = @w_fecha_proceso,    
      @s_user        = @s_user,
      @s_term        = @s_term,
      @s_ofi         = @s_ofi ,
      @t_trn         = 7049,
      @i_fecha_mov   = @w_fecha_proceso, --@w_fecha_pago,
      @i_fecha_valor = @w_fecha_proceso, --@w_fecha_ult_proceso,
      @i_banco       = @i_banco,
      @i_secuencial  = 1,
      @i_operacion   = 'F'
   
      if @w_error <> 0 begin
         select @o_msg_matriz = 'ERROR AL RETORNAR A LA FECHA ORIGINAL DEL PRESTAMO ' + @i_banco
         return @w_error
      end
   end

   return 0

end

if @i_operacion = 'A' begin

   if @i_operacionca is null and @i_banco is not null  
      select @i_operacionca = op_operacion from ca_operacion where op_banco = @i_banco

   if @i_secuencial is null
      select @i_secuencial = 0

   exec sp_prorrateo_pago_grp
   @s_user             = @s_user,
   @s_date             = @s_date,
   @i_operacionca      = @i_operacionca,
   @i_formato_fecha    = @i_formato_fecha,
   @i_secuencial_ing   = @i_secuencial,
   @i_operacion        = 'A',
   @i_sec_detpago      = 0

end


GO


/*

declare @o_secuencial_ing   int,
        @o_msg_matriz       varchar(64)
exec sp_api_payments
   @s_user                 = 'luiss',
   @s_term                 = 'termx',
   @s_date                 = null,
   @s_sesn                 = 1,
   @s_ssn                  = 1,
   @s_srv                  = 'CTSSRV',
   @s_ofi                  = 1,
   @i_operacion            = 'A', --'A'Consulta,'I'Ingreso
   @i_banco                = '0001014208',
   @i_operacionca          = NULL,
   @i_secuencial           = NULL,
   @i_beneficiario         = 'LUIS',
   @i_fecha_vig            = '12/21/2019',
   @i_ejecutar             = 'S',
   @i_retencion            = 0,
   @i_en_linea             = 'S',
   @i_producto             = 'EFMN', -- catalogo de formas de pago: ca_producto
   @i_monto_mpg            = 1000,
   @i_cuenta               = '0000', -- referencia, cuenta aho o cte
   @i_moneda               = 0,
   @i_dividendo            = 0,
   @i_cheque               = NULL,
   @i_cod_banco            = NULL,
   @i_tipo_cobro           = 'P', --'A'cumulado, 'P'royectado 
   @i_tipo_reduccion       = 'T', --'C'uota,'T'iempo
   @i_tipo_aplicacion      = 'D', --'D'ividendos, 'C'onceptos
   @i_pago_ext             = 'N',   
   @i_sec_desem_renova     = null,
   @i_pago_gar_grupal      = 'N',
   @i_referencia_pr        = NULL,-- Por precancelacion grupal
   @i_valor_multa          = 0,
   @i_valida_sobrante      = 'S',
   @i_simulado             = 'N',  --Pago Simulado
   @i_condonacion          = 'N',
   @i_rubro_condonar       = 'CAP', --Conceptos o rubros a condonar 
   @o_secuencial_ing       = @o_secuencial_ing out,
   @o_msg_matriz           = @o_msg_matriz out 
select @o_secuencial_ing, @o_msg_matriz
*/
