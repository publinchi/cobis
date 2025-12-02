use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_fecha_valor_INCIDENCIAS')
   drop proc sp_fecha_valor_INCIDENCIAS
go

---INC. 117856

create proc sp_fecha_valor_INCIDENCIAS (
   @s_date                  datetime     = null,
   @s_lsrv                  varchar(30)  = null,
   @s_ofi                   smallint     = null,
   @s_org                   char(1)      = null,
   @s_rol                   smallint     = null,
   @s_sesn                  int          = null,
   @s_ssn                   int          = null,
   @s_srv                   varchar(30)  = null,
   @s_term                  descripcion  = null,
   @s_user                  login        = null,
   @t_rty                   char(1)      = null,
   @t_debug                 char(1)      = 'N',
   @t_file                  varchar(14)  = null,
   @t_trn                   smallint     = null,     
   @i_fecha_valor           datetime     = '01/01/1900',
   @i_banco                 cuenta,
   @i_secuencial            int          = NULL,
   @i_operacion             char(1)      = NULL,   --(F)Fecha Valor (R)Reversa
   @i_observacion           varchar(255) = '',
   @i_observacion_corto     char(62)     = '',
   @i_fecha_mov             datetime     = NULL,
   @i_susp_causacion        char(1)      = NULL,
   @i_en_linea              char(1)      = 'S',
   @i_con_abonos            char(1)      = 'S',
   @i_secuencial_hfm        int          = 0,   ---DEF-5968
   @i_control_fecha         char(1)      = 'S',
   @i_debug                 char(1)      = 'N',
   @i_es_atx                char(1)      = 'N',
   @i_pago_ext              char(1)      = 'N'  ---req 0309

   )     
   as 
   declare
   
   @w_sp_name               varchar (32),
   @w_error                 int,
   @w_return                int,
   @w_monto                 money,
   @w_monto_pag             money,
   @w_monto_des             money,
   @w_operacionca           int,
   @w_secuencial_retro      int,
   @w_secuencial_min        int,
   @w_secuencial_ref        int,
   @w_tran                  char(10),
   @w_prod_rev              catalogo,
   @w_abd_monto_mpg         money,
   @w_estado_no_vigente     int,
   @w_fecha_ult_p           datetime,
   @w_es_liq                char(1),
   @w_pcobis                tinyint,
   @w_cuenta                cuenta,
   @w_aplicar_clausula      char(1),
   @w_tipo                  char(1),
   @w_lin_credito           cuenta,
   @w_toperacion            catalogo,
   @w_moneda                int,
   @w_tramite               int,   
   @w_opcion                char(1),  
   @w_opcion_gar            char(1),
   @w_cliente               int,
   @w_modo_gar              tinyint,
   @w_tramite_ficticio      int,
   @w_grupo_fact            int,           
   @w_fecha_retro           datetime,
   @w_tr_operacion          int, 
   @w_di_fecha_ven          datetime,
   @w_di_gracia             smallint, 
   @w_di_gracia_disp        smallint,
   @w_gracia_ori            smallint,
   @w_diferencia_dias       int,
   @w_dividendo_vencido     smallint,
   @w_dividendo_vigente     smallint,
   @w_num_dias              int,
   @w_contador              int,
   @w_num_dias_habiles      int, 
   @w_fecha_temp            datetime,
   @w_numero_dividendos     tinyint,
   @w_nid                   tinyint,
   @w_ciudad                int,
   @w_moneda_trn            smallint,
   @w_cotizacion_trn        money,
   @w_categoria             catalogo,
   @w_fecha_ingreso         datetime,
   @w_dias_contr            smallint,
   @w_dias_hoy              int,
   @w_fecha_credito         datetime,
   @w_fecha_contable        datetime,
   @w_fecha_proceso         datetime,
   @w_periodo               smallint,
   @w_agotada               char(1),
   @w_contabiliza           char(1),
   @w_tipo_gar              varchar(64),
   @w_abierta_cerrada       char(1),
   @w_estado                char(1),
   @w_monto_gar             money, 
   @w_moneda_ab             int,
   @w_shela                 tinyint,
   @w_op_activa             int,
   @w_producto              tinyint,
   @w_cierre_calificacion   char(1),
   @w_numero_comex          cuenta,  
   @w_max_secuencial        int,
   @w_tipo_linea            catalogo, 
   @w_dividendo             smallint,
   @w_cheque                int,
   @w_cod_banco             catalogo,
   @w_beneficiario          varchar(50),
   @w_fecha_cartera         datetime,
   @w_sec_aux               int,
   @w_ab_sec_rpa            int,        -- FCP Interfaz Ahorros   
   @w_carga                 int,        --Reversos pagos cheques propios    
   @w_fecha_trc             catalogo,
   @w_oficina               int,
   @w_re_area               int,
   @w_categoria_rubro       char(1),
   @w_monto_otc             money,
   @w_mora_retroactiva      char(1),
   @w_estado_op             tinyint,
   @w_est_cancelado         tinyint,
   @w_procesa               char(1),
   @w_monto_pag_mn          money,
   @w_monto_des_mn          money,
   @w_monto_gar_mn          money,
   @w_tipo_oficina_ifase    char(1),
   @w_oficina_ifase         int,
   @w_codvalor_mpg          int,
   @w_saldo_cap_gar         money,
   @w_sperror               int,
   @w_secuencial_ing        int,
   @w_abd_tipo              catalogo,
   @w_numero_pagos          int,
   @w_pasiva                int,
   @w_rp_lin_pasiva         catalogo,
   @w_tramite_pasivo        int,
   @w_tr_fecha_ref          datetime,
   @w_tr_fecha_mov          datetime,
   @w_oph_fecha_ult_proceso datetime,
   @w_estado_trc            char(1),
   @w_bandera_be            char(1), --Para enviarla a Garantias
   @w_concepto_devseg       catalogo,
   @w_descripcion           varchar(255),
   @w_anexo                 varchar(255),
   @w_estado_trn            catalogo,
   @w_fecha_pag             datetime,
   @w_cotizacion_pago       money,
   @w_moneda_nac            tinyint,
   @w_forma_pago            catalogo,
   @w_banco_alterno         cuenta,
   --XMA   @w_trancount_ini         int,
   @w_prodcobis_rev         tinyint,
   @w_forma_reversa         catalogo,
   @w_forma_original        catalogo,
   @w_ht_lugar_his          tinyint,
   @w_ht_fecha_his          datetime,
   @w_fecha_movi            datetime,
   @w_fecha_movi_tran       datetime,
   
   -- FQ CONTROL DE REVERSOS DE PAGO
   @w_transaccion_pag       char(1),
   @w_secuencial_pag        int,
   @w_secuencial_rpa        int,
   @w_linea_fpago           catalogo,
   
   -- FQ CONTROL CONTABLE PARA FITAL
   @w_saldo_cap_antes_fv    money,
   @w_monto_cap_pag         money,
   @w_monto_cap_des         money,
   @w_monto_cap_crc         money, -- CAPITALIZACION
                            
   @w_monto_cap_pag_ing     money,
   @w_monto_cap_des_ing     money,
   @w_monto_cap_crc_ing     money, -- CAPITALIZACION
                            
   @w_saldo_cap_despues_fv  money,
                            
   @w_mensaje               varchar(255),
   @w_monto_cap_pag_rv      money,
   @w_monto_cap_des_rv      money,
   @w_monto_cap_crc_rv      money,
                            
   @w_monto_cap_pag_rv_ini  money,
   @w_monto_cap_des_rv_ini  money,
   @w_monto_cap_crc_rv_ini  money,
                            
   @w_rev_des               char(1),
   @w_tran_manual           char(1),
   @w_oper_fechaval         int,
   @w_parametro_fval        cuenta,
   @w_llave_redescuento     cuenta,
   @w_min_sec_prepago       int,
   @w_banco_pasivo          cuenta,
   @w_op_validacion         catalogo,
   @w_capitalizaciones      char(1),
   @w_capitaliza            char(1),
   @w_producto_foriginal    smallint,
   @w_cuenta_des            cuenta,
   @w_operacion_des         int,
   @w_par_fpago_depogar     catalogo,
   @w_fecha_4767            datetime,
   @w_fecha_des             datetime,
   @w_op_naturaleza         char(1),
   @w_fecha_hfp             datetime,
   @w_secuencial_preferido  int,
   @w_pa_cheger             varchar(30),
   @w_rowcount              int,
   @w_min_dividendo         smallint,
   @w_valor_recaudo         money,
   @w_valor_iva_recaudo     money,
   @w_idlote                int,
   @w_sec_orden             int,
   @w_orden_pag             int,
   @w_forma_rev             catalogo,   
   @w_utilizado_cupo        money,
   @w_monto_cap             money,
   @w_operacion             char(1),
   @w_servidor              varchar(20),
   @w_comando               varchar(255),
   @w_fecha_pago            datetime,
   @w_commit                char(1),
   @w_fecha_valor           datetime,
   @w_monto_cap_RES         char(1),
   @w_fecha_evaluar         datetime,
   @w_dm_pagado             char(1),
   @w_orden_caja            int,
   @w_fecha_ult_proceso     datetime,
   @w_tiene_reco            char(1),--LCM - 293
   @sec_pag_rec             int,    --LCM - 293
   @w_banco_hija            cuenta,    -- JAR REQ 246
   @w_msg                   varchar(200),
   @w_toperacion_ant        catalogo,
   @w_estado_cobran_ant     varchar(2),
   @w_est_anulado           tinyint,
   @w_parametro_fng         catalogo,
   @w_div_fng               smallint,
   @w_reg_falta             char(1),
   @w_parametro_iva_fng     catalogo,
   @w_di_fecha_ini          datetime,
   @w_sec_rpa_acuerdo       int,                 -- REQ 089: ACUERDOS DE PAGO - 01/DIC/2010
   @w_fecha_acuerdo         datetime,            -- REQ 089: ACUERDOS DE PAGO - 07/ENE/2011
   @w_fecha_obj             datetime,            -- REQ 089: ACUERDOS DE PAGO - 14/ENE/2011
   @w_dm_desembolso         tinyint,
   @w_FVALRE                catalogo,
   @w_fp_fng                varchar(30),
   @w_fp_usaid              varchar(30),
   @w_activar_garantia      char(1)
   
   
   -- INICIALIZACION DE VARIABLES
   select 
   @w_sp_name                = 'sp_fecha_valor_INCIDENCIAS',
   @w_estado_no_vigente      = 0,
   @w_est_cancelado          = 3,
   @w_es_liq                 = 'N',
   @w_procesa                = 'N',
   @w_numero_pagos           = 0,
   --XMA @w_trancount_ini    = @@trancount,
   @w_secuencial_rpa         = -1,
   @w_secuencial_pag         = -1,
   @w_transaccion_pag        = 'N',
   @w_tran_manual            = 'N',
   @w_oper_fechaval          = 0,
   @w_capitalizaciones       = 'N',
   @w_secuencial_preferido   = null,
   @w_utilizado_cupo         = 0,
   @w_commit                 = 'N',
   @w_fecha_valor            = null,
   @w_monto_cap_RES          = 'N',
   @w_dm_pagado              = 'I',
   @w_tiene_reco             = 'N',
   @sec_pag_rec              = 0
   

   /* ESTADOS DE CARTERA */
   exec @w_error = sp_estados_cca
   @o_est_anulado    = @w_est_anulado       out,
   @o_est_novigente  = @w_estado_no_vigente out,
   @o_est_cancelado  = @w_est_cancelado     out
       
   ---CAMBIO PARA EJECUTAR ESTE PROGRMA EN TRASLADO DE CALIFICACION tracalif.sp
   if @i_secuencial_hfm > 0
      select @i_secuencial = @i_secuencial_hfm
   
   select @w_secuencial_min = min(tr_secuencial)
   from   ca_transaccion
   where  tr_banco = @i_banco
   and    tr_estado <> 'RV'   
   and    tr_secuencial > 0
   
   select @w_nid = pa_tinyint 
   from   cobis..cl_parametro
   where  pa_nemonico = 'NID' 
   and    pa_producto = 'CCA'
   
   select @w_parametro_fval = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'FECVAL'
   and    pa_producto = 'CCA'
   
   select @w_fecha_4767 = pa_datetime
   from   cobis..cl_parametro
   where  pa_nemonico = 'FE4767'
   and    pa_producto = 'CCA'
   
   select @w_oper_fechaval = op_operacion
   from   ca_operacion
   where  op_banco = @w_parametro_fval
   
   select @w_moneda_nac = pa_tinyint
   from   cobis..cl_parametro
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'MLO'
   
   select @w_dias_contr = pa_smallint
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'DFVAL'
   
   if @@rowcount = 0 
   begin
      select @w_error = 710215
      goto ERROR
   end

   select @w_par_fpago_depogar = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'FPDGIA'
   and    pa_producto = 'CCA'
   
   /* PARAMETRO GENERAL SERVIDOR HISTORICOS*/
   select @w_servidor = pa_char
   from cobis..cl_parametro
   where pa_producto = 'CCA'
   and   pa_nemonico = 'SRVHIS'
   
   --- PARAMETRO FECHA VALOR CON RESTRUCTURACIONES
   select @w_FVALRE = pa_char
   from cobis..cl_parametro
   where pa_producto = 'CCA'
   and   pa_nemonico = 'FVALRE'
   
   select @i_observacion_corto = convert(char(62), @i_observacion)
   
   -- FECHA DE PROCESO
   select @w_fecha_cartera = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7
   
   select 
   @w_operacionca      = op_operacion
   from   ca_operacion
   where  op_banco  =  @i_banco
   and    op_estado <> @w_estado_no_vigente
   
   if @@rowcount = 0 
   begin
      select @w_error = 701025
      goto ERROR
   end
   
	select @w_fp_fng = pa_char
	from cobis..cl_parametro with (nolock)
	where pa_producto = 'CCA'
	and pa_nemonico = 'RECFNG'
	
	select @w_fp_usaid = pa_char
	from cobis..cl_parametro with (nolock)
	where pa_producto = 'CCA'
	and pa_nemonico = 'RECUSA'

   /* VALIDA SI LA OPERACION TIENE RECONOCIMIENTO */
   if exists (select 1 
              from ca_pago_recono with (nolock)
              where pr_operacion = @w_operacionca
              and   pr_estado    <> 'R')
      select @w_tiene_reco = 'S'

-- INICIO - REQ 089: ACUERDOS DE PAGO
   if @i_operacion = 'R'
   begin
      select @w_fecha_valor = tr_fecha_ref
      from ca_transaccion
      where  tr_operacion  = @w_operacionca
      and    tr_secuencial = @i_secuencial   
      
      select @w_fecha_obj = @w_fecha_valor
      
      if exists (select 1
                 from ca_abono, ca_condonacion with (nolock)
                 where ab_operacion      = @w_operacionca
                 and   ab_secuencial_pag = @i_secuencial    
                 and   co_operacion      = ab_operacion
                 and   co_secuencial     = ab_secuencial_ing)
      begin
         exec  @w_error = sp_condonaciones 
               @s_user              = @s_user,
               @s_term              = @s_term,
               @s_date              = @s_date,
               @s_ofi               = @s_ofi,
               @i_banco             = @i_banco,
               @i_operacion         = 'R',
               @i_secuencial        = @i_secuencial
             
          if @@error <> 0
          begin
             select @w_error = 705064
             goto ERROR
          end
      end
   end
      
   if @i_operacion = 'F' 
      select @w_fecha_obj = @i_fecha_valor
      
   -- ULTIMO ACUERDO VIGENTE
   select @w_fecha_acuerdo = max(ac_fecha_ingreso)
   from  cob_credito..cr_acuerdo
   where ac_banco  = @i_banco 
   and   ac_estado = 'V'
      
   -- NO SE PUEDE HACER FECHA VALOR A UNA FECHA ANTERIOR AL ACUERDO
   -- NI REVERSAR UNA TRANSACCION ANTERIOR AL ACUERDO
   if @w_fecha_obj < @w_fecha_acuerdo
   begin
      select @w_error = 724548
      goto ERROR
   end
   -- FIN - REQ 089: ACUERDOS DE PAGO

   if @i_operacion = 'R'
   begin
      select @w_sec_aux = tr_secuencial
      from   ca_transaccion, ca_tipo_trn
      where  tr_operacion    = @w_operacionca
      and    tr_secuencial > @i_secuencial
      and    tr_tran       = tt_codigo
      and    tt_reversa    = 'S'
      and    tr_tran not in ('EST', 'REJ', 'CMO','MIG','REC')
      and    tr_estado    <> 'RV'
      order  by tr_secuencial
      
      if @@rowcount > 0 
      begin
      
         select @w_fecha_valor = tr_fecha_ref
         from ca_transaccion
         where  tr_operacion  = @w_operacionca
         and    tr_secuencial = @i_secuencial
               
         if @w_fecha_valor is not null and @w_fecha_valor <> @w_fecha_cartera 
         begin
            exec @w_error = sp_fecha_valor_INCIDENCIAS
            @s_user              = @s_user,        
            @i_fecha_valor       = @w_fecha_valor,
            @s_term              = @s_term, 
            @s_date              = @w_fecha_cartera,
            @i_banco             = @i_banco,
            @i_operacion         = 'F',
            @i_en_linea          = @i_en_linea,
            @i_control_fecha     = 'N',
            @i_debug             = 'N'   
            
            if @@error <> 0
            begin
               select @w_error = 710215
               goto ERROR
            end
            
            if @w_error <> 0
               goto ERROR
         end
         else 
         begin
            if @i_pago_ext = 'N'
               print 'fechaval.sp @i_secuencial' + cast(@i_secuencial as varchar)
            select @w_error = 710534
            goto ERROR
         end
      end
   end

   -- VALIDAR LA EXISTENCIA DE LA OPERACION 
   select 
   @w_operacionca      = op_operacion,
   @w_fecha_ult_p      = op_fecha_ult_proceso,
   @w_lin_credito      = op_lin_credito,
   @w_toperacion       = op_toperacion,
   @w_moneda           = op_moneda,
   @w_cliente          = op_cliente,
   @w_opcion           = op_tipo,   
   @w_tramite          = op_tramite,
   @w_tramite_ficticio = op_tramite_ficticio,
   @w_grupo_fact       = op_grupo_fact,
   @w_ciudad           = op_ciudad,
   @w_numero_comex     = op_num_comex,
   @w_tipo_linea       = op_tipo_linea,
   @w_lin_credito      = op_lin_credito,
   @w_tipo             = op_tipo,
   @w_oficina          = op_oficina,
   @w_mora_retroactiva = op_mora_retroactiva,
   @w_estado_op        = op_estado,
   @w_llave_redescuento = op_codigo_externo,
   @w_op_validacion     = op_validacion,
   @w_op_naturaleza     = op_naturaleza
   from   ca_operacion
   where  op_banco  =  @i_banco
   and    op_estado <> @w_estado_no_vigente
   
   if @@rowcount = 0 
   begin
      select @w_error = 701025
      goto ERROR
   end
   
   if @w_op_naturaleza = 'P' -- PASIVA
      and @i_operacion = 'F' -- FECHA VALOR
      and @i_fecha_valor < @w_fecha_ult_p -- HACIA ATRAS
   begin
      -- BUSCA LA PRIMERA HFP DESPUES DE LA CATALOGACION
      select @w_fecha_hfp = isnull(min(tr_fecha_mov), dateadd(dd, -1, @w_fecha_4767))
      from   ca_transaccion
      where  tr_operacion = @w_operacionca
      and    tr_tran      = 'HFP'
      and    tr_estado   <> 'RV'
      and    tr_fecha_mov > @w_fecha_4767
      
      if (@w_fecha_hfp < @w_fecha_4767) -- SI LA HFP ES ANTERIOR A LA CATALOGACION
      or (@i_fecha_valor < @w_fecha_hfp) -- O SI EL FECHA VALOR ES ANTES DEL HFP
      begin
         select @w_fecha_des = isnull(min(tr_fecha_ref), 'mar 1 2004') -- BUSCA LA FECHA DEL DESEMBOLSO
         from   ca_transaccion
         where  tr_operacion = @w_operacionca
         and    tr_tran      = 'DES'
         and    tr_estado   <> 'RV'
         
         select @i_fecha_valor = @w_fecha_des
         
         select @w_secuencial_preferido = min(tr_secuencial) -- EL SECUENCIAL PREFERIDO
                                                             -- ES EL PRIMER SECUENCIAL CON HISTORIA
                                                             -- DE LA FECHA BUSCADA (PAG, IOC, etc)
                                                             -- NULL SIGNIFICA QUE NO HAY
         from   ca_transaccion, ca_operacion_his
         where  tr_operacion     = @w_operacionca
         and    tr_tran         <> 'DES'
         and    tr_estado       <> 'RV'
         and    tr_fecha_ref     = @w_fecha_des
         and    oph_operacion    = tr_operacion
         and    oph_secuencial   = tr_secuencial
      end
   end

   if @@trancount = 0
   begin
      select @w_commit = 'S'
      begin tran
   end
   
   update ca_transaccion
   set    tr_estado = 'CON'
   where  tr_operacion = @w_operacionca
   and    tr_tran      = 'PRV'
   and    tr_estado    = 'NCO'
   
   if @w_commit = 'S'        
   begin                    
      commit tran
      select @w_commit = 'N'            
   end                      
   
   -- FQ CONTROL
   select @w_saldo_cap_antes_fv = sum(am_acumulado - am_pagado)
   from   ca_amortizacion
   where  am_operacion = @w_operacionca
   and    am_concepto  = 'CAP'
   
   -- PRODUCTO COBIS
   -- **************
   select @w_producto = dt_prd_cobis
   from   cob_cartera..ca_default_toperacion
   where  dt_toperacion = @w_toperacion
   and    dt_moneda     = @w_moneda
   
   -- CONTROLES PARA PERMITIR O NO FECHA VALOR - REVERSOS
   -- ***************************************************
   if @i_operacion = 'F' 
      select @w_dias_hoy = datediff(dd,@i_fecha_valor,@w_fecha_cartera)
   else
      select @w_dias_hoy = datediff(dd,@i_fecha_mov,@w_fecha_cartera)
   
   if @w_dias_hoy > @w_dias_contr and @i_control_fecha = 'S' 
   begin
      select @w_error = 710212
      goto ERROR
   end

   -- PROCESO DE FECHA VALOR
   -- **********************
   if @i_fecha_valor < @w_fecha_ult_p
   begin   
      if @i_debug = 'S'
      begin 
         if @i_pago_ext = 'N'   
            print 'FECHA VALOR ATRAS: ' + convert(varchar, @i_fecha_valor, 103)
      end
      if @i_operacion = 'F' and  @i_secuencial_hfm = 0
         select @i_secuencial = null
      else 
      begin
         select @w_secuencial_retro = @i_secuencial
         
         select @w_fecha_retro = tr_fecha_ref
         from  ca_transaccion
         where tr_operacion   =  @w_operacionca
         and   tr_secuencial = @w_secuencial_retro
         and   tr_estado      in  ('ING','CON')
         and   tr_secuencial_ref <> -999  --RECONOCER PRV GENERADAS POR PAGOS
      end
      
      if @i_secuencial is null 
      begin
         select @w_secuencial_retro = null
         
         if @w_secuencial_preferido is not null 
         begin
            select @w_secuencial_retro = @w_secuencial_preferido
         end 
         else 
         begin -- BUSCAR SI SE PUEDE USAR EL DE DESEMBOLSO
            select @w_secuencial_preferido = min(tr_secuencial) -- PRIMER SECUENCIAL DE DESEMBOLSO DE LA FECHA BUSCADA
            from   ca_transaccion
            where  tr_operacion  = @w_operacionca
            and    tr_fecha_ref  = @i_fecha_valor
            and    tr_tran       = 'DES'
            and    tr_estado    <> 'RV'
            
            if @w_secuencial_preferido is not null -- ENCONTRO UN DESEMBOLSO EN LA FECHA BUSCADA
            begin 
               if exists(select 1 from   ca_transaccion
               where  tr_operacion  = @w_operacionca
               and    tr_secuencial < @w_secuencial_retro
               and    tr_tran       = 'DES'
               and    tr_estado    <> 'RV')-- PERO HAY TRANSACCIONES ANTERIORES A LA DE DESEMBOLSO
               begin
                  select @w_secuencial_retro = null -- ESTE SECUENCIAL NO SIRVE
               end
               else 
               begin-- NO HAY TRANSACCIONES ANTERIORES (NO ES DESEMBOLSO PARCIAL)
                  select @w_secuencial_retro = min(tr_secuencial) -- EL SECUENCIAL RETRO
                                                                  -- ES EL PRIMER SECUENCIAL CON HISTORIA (PAG, IOC, etc)
                                                                  -- DE LA FECHA BUSCADA 
                                                                  -- MAYOR AL SECUENCIAL PREFERIDO (DESEMBOLSO)
                                                                  -- NULL SIGNIFICA QUE NO HAY
                  from   ca_transaccion, ca_operacion_his
                  where  tr_operacion     = @w_operacionca
                  and    tr_tran         <> 'DES'
                  and    tr_estado       <> 'RV'
                  and    tr_fecha_ref     = @i_fecha_valor
                  and    tr_secuencial    > @w_secuencial_preferido
                  and    oph_operacion    = tr_operacion
                  and    oph_secuencial   = tr_secuencial
               end
            end
         end
            
         if @w_secuencial_retro is null 
         begin
   
            select @w_fecha_retro = isnull(max(tr_fecha_ref),'01/01/1900')
            from  ca_transaccion
            where tr_operacion   =  @w_operacionca
            and   tr_fecha_ref  <= @i_fecha_valor
            and   tr_tran        in  ('PRV','EST', 'AMO', 'MIG', 'HFM') 
            and   tr_estado      in  ('ING','CON', 'NCO')
            and   tr_secuencial  > 0
            and   tr_secuencial_ref <> -999  --RECONOCER PRV GENERADAS POR PAGOS
   
            if isnull(@w_fecha_retro,'01/01/1900') = '01/01/1900' 
            begin
               select @w_error = 710494
               goto ERROR
            end
            
            select @w_secuencial_retro = tr_secuencial
            from   ca_transaccion
            where  tr_operacion = @w_operacionca
            and    tr_tran      = 'MIG'
            and    tr_fecha_ref = @w_fecha_retro
            and    tr_estado      in  ('ING','CON')
            and    tr_secuencial  > 0
   
            if @@rowcount = 0 
            begin
               select @w_secuencial_retro = min(tr_secuencial)
               from  ca_transaccion
               where tr_operacion   = @w_operacionca
               and   tr_fecha_ref   = @w_fecha_retro
               and   tr_tran        in  ('PRV', 'EST', 'AMO', 'HFM')
               and   tr_estado      in  ('ING','CON', 'NCO')
               and   tr_secuencial  > 0
               and   tr_secuencial_ref <> -999  --RECONOCER PRV GENERADAS POR PAGOS
               
               if @w_secuencial_retro is null 
               begin
                  select @w_error = 710494
                  goto ERROR
               end
   
            end
         end
         
         if exists (select 1 
         from ca_transaccion
         where tr_operacion = @w_operacionca
         and   tr_secuencial  >= @w_secuencial_retro
         and   tr_tran = 'CRC'
         and   tr_estado <> 'RV')
         begin      
            -- REVISAR SI LA OPERACION TIENE COMISION FAG PARA ACTUALIZAR EL VALORE DE LA GARANTIA
            exec @w_error =  sp_comision_capitalizacion
            @s_ssn               = @s_ssn,
            @s_date              = @s_date,
            @s_user              = @s_user,
            @s_term              = @s_term,
            @s_ofi               = @s_ofi,
            @i_operacionca       = @w_operacionca,
            @i_secuencial_retro  = @w_secuencial_retro,
            @i_tramite           = @w_tramite
            
            if @@error <> 0 or @w_error <> 0
            begin
               goto ERROR
            end
         end
      end
      
      --REVISAR EXISTENCIA DE SECUENCIAL EN TABLA DE HISTORICOS
      
      select @w_ht_lugar_his =  ht_lugar,
             @w_ht_fecha_his =  ht_fecha
      from   ca_historia_tran
      where  ht_operacion = @w_operacionca
      and    ht_secuencial = @w_secuencial_retro
      
      if @@rowcount <> 0 
      begin
         if @i_pago_ext = 'N'
         begin
            if @w_ht_lugar_his = 1
               PRINT 'Señor Usuario: Para realizar esta transaccion, debe recuperar la historia por la opcion de Herramientas'
            else
               PRINT 'Señor Usuario: Solicite la recuperacion de backup de fecha  ' + cast(@w_ht_fecha_his as varchar) + ' para poder hacer la Transaccion' 
         end
         select @w_error = 0
         goto ERROR
      end
      
      -- DATOS DE LA TRANSACCION DE RETROCESO
      -- ************************************
      select 
      @w_secuencial_ref = tr_secuencial_ref,
      @w_tran           = tr_tran,
      @w_tr_fecha_ref   = tr_fecha_ref,
      @w_estado_trn     = tr_estado,
      @w_tr_fecha_mov   = tr_fecha_mov,
      @w_fecha_retro    = tr_fecha_ref
      from   ca_transaccion
      where  tr_secuencial = @w_secuencial_retro
      and    tr_operacion  = @w_operacionca

      
      -- Validar Origen y Concepto para reversar
        
      if @i_operacion = 'R' and ( @w_tran = 'PAG' or @w_tran = 'DES') 
      begin
      
         select @w_fecha_evaluar = '01/01/1900'
               
         if @w_tran = 'PAG' 
         begin
         
            select @w_fecha_evaluar = ab_fecha_pag 
            from ca_secuencial_atx, ca_abono, ca_operacion
            where sa_secuencial_cca = ab_secuencial_ing
            and   ab_operacion      = op_operacion
            and   op_banco          = sa_operacion     
            and   ab_secuencial_pag = @i_secuencial
            and   ab_operacion      = @w_operacionca
            and   ab_estado         = 'A'  
         
         end
         
         -- REQ 175: PEQUEÑA EMPRESA - CONTROL REVERSAS DE DESEMBOLSOS EN LA MISMA FECHA
         if @w_tran = 'DES' 
         begin
         
            select @w_fecha_evaluar = dm_fecha, @w_dm_pagado = dm_pagado, @w_orden_caja = isnull(dm_orden_caja,0)
            from  ca_desembolso
            where dm_secuencial = @i_secuencial
            and   dm_operacion  = @w_operacionca
   
            if @@rowcount = 0 
            begin
               select @w_error = 701121
               goto ERROR
            end
         
         end
         
         if @i_es_atx = 'N' and @w_fecha_cartera = @w_fecha_evaluar 
         begin
            if (@w_tran = 'DES' and @w_dm_pagado in ('E', 'S') and @w_orden_caja > 0) or @w_tran = 'PAG' 
            begin
               select @w_error = 724520 -- la reversa debe ser HOY desde Caja, Manana desde Cartera
               goto ERROR 
            end
         end
         
         if @i_es_atx = 'S' and @w_fecha_cartera <> @w_fecha_evaluar and @i_pago_ext = 'N' 
         begin
            select @w_error = 724520 -- la reversa debe ser HOY desde Caja, Manana desde Cartera
            goto ERROR 
         end
         
      end      
      
      -- NO SE PUEDE HACER FECHA VALOR O REVERSA SI EN LA LISTA DE TRANSACCIONES QUE SE VAN A REVERSAR
      -- EXISTE UNA TRANSACCION PENDIENTE DE VALIDAR
      if exists(select 1
      from   ca_transaccion
      where  tr_operacion = @w_operacionca
      and    tr_estado= 'PVA'
      and    tr_secuencial >= @w_secuencial_retro)
      begin
         select @w_error = 710507
         goto ERROR
      end   
      
      if @w_tran = 'DES' 
      begin
         select 
         @w_opcion_gar = 'R',
         @w_modo_gar   = 1
      end
      
      if @w_tran in ('PAG', 'PRE', 'CAN') 
      begin
         select 
         @w_opcion_gar = 'D',
         @w_modo_gar   = 2
      end
    
      ---   VERIFICA QUE NO EXISTA OTRAS OPERACIONES MANUALES
      if @w_FVALRE ='S' and @i_en_linea = 'S'
      begin
	      if exists (select 1
	      from   ca_transaccion
	      where  tr_operacion   = @w_operacionca
	      and    tr_secuencial > @w_secuencial_retro
	      and    tr_estado     <> 'RV'
	      and    tr_tran       in ('DES', 'PRO', 'AJP', 'MPC', 'ETM', 'SUM', 'ACE', 'CAS', 'MAN', 'TLI'))
	      begin
	         select @w_error = 710075
	         goto ERROR
	      end
	  end    
      ELSE
      begin
	      if exists (select 1
	      from   ca_transaccion
	      where  tr_operacion   = @w_operacionca
	      and    tr_secuencial > @w_secuencial_retro
	      and    tr_estado     <> 'RV'
	      and    tr_tran       in ('DES', 'RES', 'PRO', 'AJP', 'MPC', 'ETM', 'SUM', 'ACE', 'CAS', 'MAN', 'TLI'))
	      begin
	         select @w_error = 710075
	         goto ERROR
	      end      
      end
      
      if  @i_operacion = 'R' and @w_tran = 'IOC' 
      begin
         delete ca_otro_cargo
         where oc_operacion = @w_operacionca
         and   oc_secuencial = @i_secuencial
      end
      
      if  @i_operacion = 'R' and @w_tran = 'CAS' 
      begin
         if exists (select 1
         from   ca_castigo_masivo
         where  cm_banco = @i_banco)
         begin
            update ca_castigo_masivo
            set    cm_estado = 'R',
                   cm_usuario = @s_user
            where  cm_banco = @i_banco   
            and    cm_estado <> 'R' 
         end          
      end
      
       --- Dif Boc
      if  @i_operacion = 'R' and @w_tran = 'RES' 
      begin
         update ca_datos_reestructuraciones_cca
         set res_estado_tran = 'RV'
         where res_operacion_cca  = @w_operacionca
         and   res_secuencial_res = @i_secuencial
      end
      --- Dif Boc   
             
      --GARANTIAS ESPECIALES
      if @i_operacion = 'R' and @w_tran in ('PAG') 
      begin
         --SACAR LA FORMA DE PAGO PARA VER SI ES DE RECONOCIMIENTO DE GARANTIA ESPECIAL
         select @w_forma_pago = abd_concepto
         from   ca_abono_det, ca_abono
         where  ab_operacion        = @w_operacionca
         and    ab_secuencial_pag   = @i_secuencial
         and    abd_operacion       = ab_operacion
         and    abd_secuencial_ing  = ab_secuencial_ing
         and    abd_tipo            = 'PAG'
         
         select @w_forma_original = @w_forma_pago
         
         select @w_forma_reversa = cp_producto_reversa
         from   ca_producto
         where  cp_producto = @w_forma_pago
         
         if @@rowcount = 0
            select  @w_forma_reversa = @w_forma_pago
         
         ---SI LA FORMA DE PAGO EXISTE EN LAS RELACIONADAS CON LAS LINEAS ESPECIALES
         select @w_linea_fpago = valor
         from   cobis..cl_catalogo
         where  tabla = (select codigo
         from   cobis..cl_tabla
         where  tabla = 'ca_especiales')
         and    codigo = @w_forma_pago
            
         if @@rowcount > 0 
         begin         
            ---SE VALIDA LA EXISTENCIA DE LA OBLIGACION ALTERNA
            select @w_banco_alterno = op_banco
            from   ca_operacion
            where  op_anterior = @i_banco
            and    op_toperacion = @w_linea_fpago
            and    op_tipo     = 'G'
            and    op_estado   in (1,2,9)
            
            if @@rowcount > 0 
            begin   
               select @w_error = 710521
               goto ERROR
            end
            else 
            begin            
               update ca_alternas_tmp
               set   alt_estado = 'E'
               where alt_banco    = @i_banco
               and   alt_secuencial_pag = @i_secuencial   
               if @@error <> 0 
               begin
                  select @w_error = 710521
                  goto ERROR
               end 
            end 
         end
      end
--GARANTIAS ESPECIALES'
         
      if @i_operacion = 'R' and @w_tran = 'PAG' 
      begin ---XMA NR-237
         if exists (select 1
         from   ca_lavado_activos 
         where  la_operacion = @w_operacionca
         and    la_secuencial_pag = @i_secuencial)
         begin
            delete ca_lavado_activos
            where  la_operacion = @w_operacionca 
            and    la_secuencial_pag = @i_secuencial 
         end
      end                                        ---XMA FIN NR-237
      
      if @i_operacion = 'R' and @w_tran = 'DES' and  @w_secuencial_min = @i_secuencial 
      begin ---el primer desembolso
         if exists (select 1
         from   ca_deudores_tmp
         where  dt_operacion = @w_operacionca)
         begin
            delete ca_deudores_tmp
            where dt_operacion = @w_operacionca
         end
      end                                        ---XMA FIN NR-201
         
      -- VERIFICA QUE NO EXISTAN PAGOS AL REVERSAR EL PRIMER DESEMBOLSO
      if  @i_operacion  = 'R'
      and @w_secuencial_min = @i_secuencial
      and exists (select 1
      from   ca_transaccion
      where  tr_banco      = @i_banco 
      and    tr_estado     <> 'RV'
      and    tr_tran       = 'RPA'
      and    tr_secuencial > 0)
      begin
         select @w_error = 710133
         goto ERROR
      end  
      
            
      -- VERIFICAR LA EXISTENCIA DEL HISTORICO 
      if @w_tran not in ('HFM', 'DES', 'MIG') 
      begin
         select @w_oph_fecha_ult_proceso = oph_fecha_ult_proceso
         from   ca_operacion_his
         where  oph_operacion = @w_operacionca
         and    oph_secuencial= @w_secuencial_retro
         
         if @@rowcount = 0 
         begin
            select @w_error = 710132
            goto ERROR
         end
        
         select @w_tran_manual = 'N'
         
         -- NR-369 Se quito el IOC del grupo de transacciones 
         if @w_tran  in ('DES','RES','PRO','AJP','MPC','ETM','SUM','ACE','CAS','MAN', 'TLI') and @i_operacion = 'R'
            select @w_tran_manual = 'S'
         --- PILAS FQ
         if   @w_tr_fecha_mov < 'mar 8 2005' -- DESDE ESTA FECHA NO DEBE HABER ERRORES, SOLO SE ACEPTAN ERRORES ANTERIORES
         and  @w_tr_fecha_ref <> @w_oph_fecha_ult_proceso
         begin
            if @@trancount = 0          
            begin                    
               select @w_commit = 'S'
               begin tran            
            end                      
         
            update ca_transaccion
            set    tr_fecha_ref  = @w_oph_fecha_ult_proceso
            where  tr_operacion  = @w_operacionca
            and    tr_secuencial = @w_secuencial_retro
            
            if @w_commit = 'S'         
            begin                    
               select @w_commit = 'N'
               commit tran            
            end                      
         end
      end
         
      -- VERIFICAR LA EXISTENCIA DE LA TRANSACCION  TRC
      if exists (select 1 from ca_transaccion
      where tr_operacion  = @w_operacionca 
      and   tr_secuencial > @w_secuencial_retro
      and   tr_estado     <> 'RV'
      and   tr_tran       = 'TRC')
      begin
         select @w_fecha_trc = convert(varchar(10),tr_fecha_mov,103)
         from   ca_transaccion
         where  tr_operacion      = @w_operacionca 
         and    tr_secuencial > @w_secuencial_retro
         and    tr_estado     <> 'RV'
         and    tr_tran       = 'TRC'
         
         insert into   ca_control_trn_manual 
         values (@w_operacionca, 'TRC', @w_fecha_trc)
      end
         
      select @w_monto_cap_pag_rv_ini = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       in ('PAG', 'CON', 'PRN')
      and    tr_estado     = 'RV'
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = -tr_secuencial
      and    dtr_concepto   = 'CAP'
      and    dtr_codvalor <> 10017
      and    dtr_codvalor <> 10027
      and    dtr_codvalor <> 10097
      and    dtr_codvalor <> 10047
      and    dtr_codvalor <> 10080
      and    dtr_codvalor <> 10092 --LCM - 293 NO TENER EN CUENTA LOS VALORES AMORTIZADOS
      and    dtr_codvalor <> 10094 --LCM - 293 NO TENER EN CUENTA LOS VALORES AMORTIZADOS
      
      select @w_monto_cap_des_rv_ini = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       = 'DES'
      and    tr_estado     = 'RV'
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = -tr_secuencial
      and    dtr_concepto   = 'CAP'
      
      select @w_monto_cap_crc_rv_ini = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       = 'CRC'
      and    tr_estado     = 'RV'
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = -tr_secuencial
      and    dtr_concepto   = 'CAP'
      
      -- MONTO DE LOS PAGOS QUE SE VAN A REVERSAR
      select @w_monto_cap_pag = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       in ('PAG', 'CON', 'PRN')
      and    tr_estado     in ('CON', 'ING')
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_codvalor <> 10017
      and    dtr_codvalor <> 10027
      and    dtr_codvalor <> 10097
      and    dtr_codvalor <> 10047
      and    dtr_codvalor <> 10080
      and    dtr_codvalor <> 10092 --LCM - 293 NO TENER EN CUENTA LOS VALORES AMORTIZADOS
      and    dtr_codvalor <> 10094 --LCM - 293 NO TENER EN CUENTA LOS VALORES AMORTIZADOS
      and    dtr_concepto   = 'CAP'
      
      -- MONTO DE LOS DESEMBOLSOS QUE SE VAN A REVERSAR
      select @w_monto_cap_des = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       = 'DES'
      and    tr_estado     in ('CON', 'ING')
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_concepto   = 'CAP'
      
      select @w_monto_cap_crc = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       = 'CRC'
      and    tr_estado     in ('CON', 'ING')
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_concepto   = 'CAP'
      
      -- MONTO DE LOS PAGOS QUE SE VAN A REVERSAR PERO QUE ESTAN ING
      select @w_monto_cap_pag_ing = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       in ('PAG','CON', 'PRN')
      and    tr_estado     = 'ING'
      and    dtr_codvalor <> 10017
      and    dtr_codvalor <> 10027
      and    dtr_codvalor <> 10047
      and    dtr_codvalor <> 10097
      and    dtr_codvalor <> 10080
      and    dtr_codvalor <> 10092 --LCM - 293 NO TENER EN CUENTA LOS VALORES AMORTIZADOS
      and    dtr_codvalor <> 10094 --LCM - 293 NO TENER EN CUENTA LOS VALORES AMORTIZADOS
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_concepto   = 'CAP'
      
      -- MONTO DE LOS DESEMBOLSOS QUE SE VAN A REVERSAR PERO QUE ESTAN ING
      select @w_monto_cap_des_ing = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       = 'DES'
      and    tr_estado     = 'ING'
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_concepto   = 'CAP'
      
      select @w_monto_cap_crc_ing = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       = 'CRC'
      and    tr_estado     = 'ING'
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_concepto   = 'CAP'
      
      if exists (select 1
      from   ca_transaccion, ca_det_trn
      where  tr_operacion    = @w_operacionca
      and    tr_tran         = 'RES'
      and    tr_estado      in ('CON', 'ING')
      and    dtr_operacion   = tr_operacion
      and    dtr_secuencial  = tr_secuencial
      and    dtr_concepto   <> 'CAP'  
      and    tr_secuencial   > 0
      and    dtr_estado     <> 37 )
      begin
         select @w_monto_cap_RES  ='S'
      end
      
      if @@trancount = 0 
      begin
         begin tran
         select @w_commit = 'S'
      end                         ---XMA BEGIN TRAN
      
      -- BORRAR LAS TASAS MAYORES AL SECUENCIAL DE REVERSO
      delete ca_tasas
      where  ts_operacion  = @w_operacionca
      and    ts_fecha >= @w_fecha_retro
      
      if @@error <> 0 
      begin
         select @w_error = 71003
         goto ERROR
      end  
      
      -- ELIMINA LOS REAJUSTES AUTOMATICOS TLU%  o LOS REAJUSTES POR VARIACION DE LA TLU QUE SE
      -- IDENTIFICAN CON  re_desagio = 'e' EN LA TABLA DE REAJUSTES
      delete ca_reajuste
      from   ca_reajuste_det
      where  re_operacion     = @w_operacionca
      and    re_fecha        >= @w_fecha_retro
      and    red_operacion    = @w_operacionca
      and    red_secuencial   = re_secuencial
      and    (red_referencial  like 'TLU%' or re_desagio = 'e')
      
      delete ca_reajuste_det
      from   ca_reajuste_det d
      where  red_operacion = @w_operacionca
      and    not exists(select 1
      from   ca_reajuste
      where  re_operacion = @w_operacionca
      and    re_secuencial = d.red_secuencial)
      
      -- ANTES DE RECUPERAR LOS HISTORICOS SE DEBE OBTENER EL VALOR DEL OFICIAL ACTUAL
      
      -- TRARE HISTORICOS DE EL SERVIDOR DE HISTORICOS
   
      if @i_operacion = 'R' select @w_secuencial_retro = @i_secuencial
   
      if not exists (select 1 
      from ca_rubro_op_his
      where roh_operacion  = @w_operacionca
      and   roh_secuencial = @w_secuencial_retro
      )
      and @w_servidor <> 'NOHIST'
      begin
         exec @w_error = cob_cartera..sp_cpy_historico_lnk  
         @i_operacion   = @w_operacionca,
         @i_secuencial  = @w_secuencial_retro
         
         if @w_error  <> 0 
         begin
            goto ERROR
         end
         
         select @w_comando = 'exec '+ @w_servidor +'.cob_cartera.dbo.sp_bor_historico_lnk'
         select @w_comando = @w_comando + '  @i_operacion   = ' + convert(varchar(25),@w_operacionca)
         select @w_comando = @w_comando + ', @i_secuencial  = ' + convert(varchar(25),@w_secuencial_retro)
         exec @w_error = sp_sqlexec @w_comando   
         
         if @w_error  <> 0 
         begin
            goto ERROR
         end
      end
       
      -- PONER LOS HISTORICOS EN LAS TABLAS DEFINITIVAS
      exec @w_error  = sp_historia_def
      @i_operacionca  = @w_operacionca,  
      @i_secuencial   = @w_secuencial_retro
      
      if @w_error  <> 0 
      begin
         goto ERROR
      end
   
      --VALIDAR LA CONSISTENCIA DE LA TABLA DE AMORTIZACION
      --UNA VEZ SE CARGUE HISTORICOS
      
      select @w_rev_des = 'N'
      if exists(select 1
      from   ca_operacion
      where  op_operacion = @w_operacionca
      and    op_estado = 0)
      begin
         select @w_saldo_cap_despues_fv = 0,
         @w_rev_des = 'S'
      end
      else 
      begin
         select @w_saldo_cap_despues_fv = sum(am_acumulado - am_pagado)
         from   ca_amortizacion
         where  am_operacion = @w_operacionca
         and    am_concepto  = 'CAP'
      end
         
         
      if @w_tran = 'PAG' and @i_operacion = 'F' 
      begin
         -- VERIFICAR DIAS DE GRACIA NEGOCIADA PARA EL DIVIDENDO Y EL CAMPO di_intento
         select @w_tr_operacion = tr_operacion
         from   ca_transaccion
         where  tr_banco = @i_banco
         
         select @w_diferencia_dias = min(abs(datediff(dd, @i_fecha_valor, di_fecha_ven)))
         from   ca_dividendo
         where  di_operacion = @w_tr_operacion
         
         select @w_dividendo_vencido = di_dividendo - 1,
                @w_dividendo_vigente = di_dividendo
         from   ca_dividendo
         where  datediff(dd, @i_fecha_valor, di_fecha_ven) = @w_diferencia_dias
         and    di_operacion                               = @w_tr_operacion
         
         if @@rowcount = 0 
         begin
            select @w_dividendo_vigente = di_dividendo + 1,
                   @w_dividendo_vencido = di_dividendo 
            from   ca_dividendo
            where  datediff(dd, di_fecha_ven, @i_fecha_valor) = @w_diferencia_dias
            and    di_operacion                               = @w_tr_operacion
         end
         
         -- COMPROBAR QUE EXISTAN LOS DIVIDENDOS VIGENTE Y VENCIDO
         if exists(select 1
         from   ca_dividendo
         where  di_dividendo = @w_dividendo_vencido
         and    di_operacion = @w_tr_operacion)
            select @w_dividendo_vencido = @w_dividendo_vencido
         else
            select @w_dividendo_vencido = 0
         
         if exists(select 1
         from   ca_dividendo
         where  di_dividendo = @w_dividendo_vigente
         and    di_operacion = @w_tr_operacion)
            select @w_dividendo_vigente = @w_dividendo_vigente
         else
            select @w_dividendo_vigente = 0
         
         -- PARA DIVIDENDOS VIGENTES A LA FECHA-VALOR
         if @w_dividendo_vigente <> 0 
         begin
            select @w_di_gracia      = di_gracia,
                   @w_di_gracia_disp = di_gracia_disp,
                   @w_di_fecha_ven   = di_fecha_ven
            from   ca_dividendo
            where  di_operacion = @w_tr_operacion 
            and    di_dividendo = @w_dividendo_vigente 
            
            if @w_di_gracia < 0 
            begin
               update ca_dividendo
               set    di_gracia  = -1 * di_gracia,
                      di_gracia_disp = -1 * @w_di_gracia
               where  di_operacion = @w_tr_operacion 
               and    di_dividendo = @w_dividendo_vigente 
            end
            else 
            begin
               if @w_mora_retroactiva = 'S'  
               begin --FUNCIONALIDAD PARA BANCO AGRARIO
                  update ca_dividendo
                  set    di_gracia_disp = 0
                  where  di_operacion = @w_tr_operacion
                  and    di_dividendo = @w_dividendo_vigente
               end                             ---FIN
               else 
               begin
                  update ca_dividendo
                  set    di_gracia_disp = @w_di_gracia 
                  where  di_operacion = @w_tr_operacion
                  and    di_dividendo = @w_dividendo_vigente
               end 
            end
         end  --dividendo_vigente <> 0
         
         -- PARA DIVIDENDOS VENCIDOS A LA FECHA-VALOR
         If @w_dividendo_vencido <> 0 
         begin
            select @w_di_gracia      = di_gracia,
                   @w_di_gracia_disp = di_gracia_disp,
                   @w_di_fecha_ven   = di_fecha_ven
            from   ca_dividendo
            where  di_operacion = @w_tr_operacion 
            and    di_dividendo = @w_dividendo_vencido 
            
            if @w_di_gracia < 0
               select @w_gracia_ori = -1 * @w_di_gracia
            else
               select @w_gracia_ori = @w_di_gracia
            
            select @w_contador = 1
            
            select @w_num_dias_habiles = 1
            
            while @w_contador <= @w_diferencia_dias 
            begin
               select @w_fecha_temp = dateadd (dd,@w_contador, @w_di_fecha_ven)
               
               if exists(select df_fecha 
               from   cobis..cl_oficina, cobis..cl_dias_feriados
               where  of_oficina = @w_oficina
               and    of_ciudad  = df_ciudad
               and    df_fecha   = @w_fecha_temp)
                  select @w_num_dias_habiles = @w_num_dias_habiles
               else
                  select @w_num_dias_habiles = @w_num_dias_habiles +1
               
               select @w_contador = @w_contador + 1
            end --WHILE
            
            if @w_num_dias_habiles > @w_gracia_ori 
            begin
               update ca_dividendo
               set    di_gracia = -1 * @w_gracia_ori
               where  di_operacion = @w_tr_operacion 
               and    di_dividendo = @w_dividendo_vencido
            end
            else 
            begin
               if @w_mora_retroactiva = 'S' 
               begin ---FUNCIONALIDAD PARA BANCO AGRARIO
                  update ca_dividendo
                  set    di_gracia_disp = 0
                  where  di_operacion = @w_tr_operacion
                  and    di_dividendo = @w_dividendo_vencido 
               end                             ---FIN
               else 
               begin
                  update ca_dividendo set    
                  di_gracia          = @w_gracia_ori,
                  di_gracia_disp     = @w_gracia_ori - @w_num_dias_habiles
                  where di_operacion = @w_tr_operacion 
                  and   di_dividendo = @w_dividendo_vencido 
               end
            end
            
            -- ACTUALIZAR LOS VALORES DE DI_GRACIA Y DI_GRACIA_DISP DE 
            -- LOS DIVIDENDOS NO VIGENTES
            select @w_numero_dividendos = count (*) 
            from   ca_dividendo
            where  di_operacion = @w_tr_operacion 
            and    di_dividendo > @w_dividendo_vencido
            
            select @w_contador = 1
            
            while @w_contador <= @w_numero_dividendos 
            begin
               select @w_di_gracia = di_gracia
               from   ca_dividendo
               where  di_operacion = @w_tr_operacion 
               and    di_dividendo = @w_dividendo_vencido + @w_contador
               
               if @w_di_gracia < 0 
               begin
                  update ca_dividendo
                  set    di_gracia      = -1 * @w_di_gracia, 
                         di_gracia_disp = -1 * @w_di_gracia 
                  where  di_operacion = @w_tr_operacion 
                  and    di_dividendo = @w_dividendo_vencido + @w_contador
               end         
               else 
               begin
                  if @w_mora_retroactiva = 'S' 
                  begin --FUNCIONALIAD BANCO AGRARIO
                     update ca_dividendo
                     set    di_gracia_disp = 0
                     where  di_operacion   = @w_tr_operacion 
                     and    di_dividendo   = @w_dividendo_vencido + @w_contador  --FIN
                  end
                  else 
                  begin
                     update ca_dividendo
                     set    di_gracia_disp = di_gracia
                     where  di_operacion = @w_tr_operacion 
                     and    di_dividendo = @w_dividendo_vencido + @w_contador    
                  end
               end
               
               select @w_contador = @w_contador + 1
            end --WHILE
         end --DIVIDENDO_VENCIDO <>0
         
         -- CONTROL DEL CAMPO di_intento   
         
         if @w_dividendo_vencido <> 0 
         begin 
            if @w_num_dias_habiles < @w_nid 
            begin
               update ca_dividendo
               set    di_intento = @w_num_dias_habiles
               where  di_operacion = @w_tr_operacion
               and    di_dividendo = @w_dividendo_vencido 
            end
            
            -- ACTUALIZAR A CERO LOS VALORES DE INTENTOS DEL
            -- DIVIDENDO VIGENTE Y NO VIGENTES
            select @w_numero_dividendos = count (di_dividendo) 
            from   ca_dividendo 
            where  di_operacion = @w_tr_operacion
            and    di_dividendo > @w_dividendo_vencido 
            
            select @w_contador = 1
            
            while @w_contador <= @w_numero_dividendos 
            begin
               update ca_dividendo
               set    di_intento = 0 
               where  di_operacion = @w_tr_operacion 
               and    di_dividendo = @w_dividendo_vencido + @w_contador
               
               select @w_contador = @w_contador + 1  
            end --WHILE
         end
      end -- END  tipo tran es PAG and operacion = F
         
      --  SOLO PARA REVERSAS
      if @i_operacion = 'R' 
      begin

         if @w_tiene_reco = 'S'
         begin
         -- REALIZA REVERSION DEL RECONOCIMIENTO EN CASO QUE EXISTA
            exec @w_error = sp_pagxreco
                 @s_user             = @s_user,
                 @s_term             = @s_term,
                 @s_date             = @s_date,
                 @i_tipo_oper        = 'R',
                 @i_operacionca      = @w_operacionca,
                 @i_secuencial_pag   = @i_secuencial
      
            if @w_error <> 0 return @w_error
         end
   
         /*  CONTROL PARA OPERACIONES RENOVADAS**/
         if @w_tran = 'DES' 
         begin
            if exists (select 1 from   ca_operacion,  cob_credito..cr_op_renovar
            where  op_banco   = or_num_operacion
            and    or_tramite = @w_tramite
            and    op_estado  = 3)
            begin
               if @i_pago_ext = 'N'
                  print 'ESTA OP. ES RENOVADA, ...POR FAVOR REVERSAR PRIMERO EL PAGO(S) DE LA(S) OPERACION(ES) ANTERIOR(ES)' 
               select @w_error = 708162 
               goto ERROR          
            end       
         end    

         -- INI JAR REQ 246
         -- Control para Reversion de operaciones reestructuradas a las que se les
         -- haya creado una operación hija por concepto de diferidos 
         if @w_tran = 'RES' begin

            --Obtiene linea de credito anterior de la operacion
            select @w_toperacion_ant    = oph_toperacion,
                   @w_estado_cobran_ant = oph_estado_cobranza
            from ca_operacion_his with (nolock)
            where oph_operacion  = @w_operacionca
            and   oph_secuencial = @i_secuencial

            --Valida si la operacion tiene operaciones hijas vigentes
            select @w_banco_hija = op_banco
            from ca_op_reest_padre_hija with (nolock), ca_operacion with (nolock)
            where ph_op_padre    = @w_operacionca
            and   ph_sec_reest   = @i_secuencial
            and   op_operacion   = ph_op_hija
            and   op_estado     not in (@w_estado_no_vigente,@w_est_anulado)

            if @w_banco_hija is not null
            begin
               select @w_msg = 'ESTA OP. ESTA RELACIONADA CON UN OP.HIJA DEBIDO A UNA REESTRUCTURACION.' + char(13)
               select @w_msg = @w_msg + 'POR FAVOR REVERSAR PRIMERO DESEMBOLSO DE LA OP. HIJA No.: ' + @w_banco_hija 
               PRINT @w_msg
               select @w_error = 701195 
               goto ERROR
            end
         end
         -- FIN JAR REQ 246               
      
         -- REVERSAR  EL DESEMBOLSO EN OTROS PRODUCTOS
         if @w_tran = 'DES' 
         begin
            select 
            @w_forma_original = dm_producto,
            @w_cuenta_des     = dm_cuenta
            from   ca_desembolso
            where  dm_operacion   = @w_operacionca
            and    dm_secuencial  = @w_secuencial_retro
            
            select 
            @w_forma_reversa       = cp_producto_reversa,
            @w_producto_foriginal  = cp_pcobis
            from   ca_producto
            where  cp_producto = @w_forma_original
            
            if @@rowcount = 0
               select  @w_forma_reversa = @w_forma_original
               
            if @w_producto_foriginal = 7 
            begin
               select @w_operacion_des = op_operacion
               from ca_operacion
               where op_banco = @w_cuenta_des
               if exists (select 1 from ca_abono
               where ab_operacion = @w_operacion_des
               and   ab_estado in ('NA', 'ING', 'A'))
               begin
                  if @i_pago_ext = 'N'
                     PRINT 'sp fechaval.sp Genero abono a la Operacion Nro.' + cast(@w_cuenta_des as varchar)
                  select @w_error = 711056
                  goto ERROR
               end                              
            end
            
            -- REVERSAR INTANT  EN TABLA DE AMORTIZACION_ANT
            if exists (select 1
            from   ca_amortizacion_ant
            where  an_secuencial >= @w_secuencial_retro
            and    an_operacion  = @w_operacionca) 
            begin
               delete ca_amortizacion_ant
               where  an_secuencial >= @w_secuencial_retro
               and    an_operacion  = @w_operacionca 
            end
            
            if @w_tipo <> 'R' 
            begin
               if exists (select 1
               from ca_relacion_ptmo   
               where rp_activa = @w_operacionca)
               begin
                  delete ca_relacion_ptmo   
                  where rp_activa = @w_operacionca
               end
            end
            else 
            begin
               if exists (select 1
               from ca_relacion_ptmo   
               where rp_pasiva = @w_operacionca)
               begin
                  delete ca_relacion_ptmo   
                  where rp_pasiva = @w_operacionca
               end
            end
            
            -- AFECTACION A OTROS PRODUCTOS
            declare
               cursor_afecta_prod cursor
               for select cp_producto_reversa,  dm_monto_mds,  dm_cuenta,  
                          isnull(cp_pcobis,0),  dm_moneda,     dm_cotizacion_mds,
                          cp_codvalor, dm_idlote, dm_desembolso
                   from   ca_desembolso, ca_producto 
                   where  dm_operacion   = @w_operacionca
                   and    dm_secuencial  = @w_secuencial_retro
                   and    cp_producto    = dm_producto               
                   and    cp_pcobis      is not null 
                   and    cp_pcobis      <> 7
                   for read only
            
            open cursor_afecta_prod 
            
            fetch cursor_afecta_prod
            into  @w_prod_rev,         @w_monto,       @w_cuenta,
                  @w_pcobis,           @w_moneda_trn,  @w_cotizacion_trn,
                  @w_codvalor_mpg,     @w_idlote    ,  @w_dm_desembolso
            
            while (@@fetch_status = 0) 
            begin            
               --UNICAMENTE ENTRA SI DEBE REVERSAR OTROS PRODUCOTS DE COBIS
               --COMO CUENTA , AHORROS, 
               if @w_pcobis in (3,4,9,42) 
               begin
               
                  if @w_pcobis = 9  
                     select @w_cuenta = @i_banco
                  
                  select @w_oficina_ifase = @s_ofi
                  
                  select @w_tipo_oficina_ifase = dp_origen_dest
                  from   ca_trn_oper, cob_conta..cb_det_perfil
                  where  to_tipo_trn = 'DES'
                  and    to_toperacion = @w_toperacion
                  and    dp_empresa    = 1
                  and    dp_producto   = 7
                  and    dp_perfil     = to_perfil
                  and    dp_codval     = @w_codvalor_mpg
                  
                  if @@rowcount = 0 
                  begin
                     select @w_error = 710446
                     goto ERROR
                  end
                  
                  if @w_tipo_oficina_ifase = 'C' 
                  begin
                     select @w_oficina_ifase = pa_int
                     from   cobis..cl_parametro
                     where  pa_nemonico = 'OFC'
                     and    pa_producto = 'CON'
                     set transaction isolation level read uncommitted
                  end
                  
                  if @w_tipo_oficina_ifase = 'D' 
                  begin
                     select @w_oficina_ifase = @w_oficina
                  end
                  
                  if @i_debug = 'S' -- FCP Interfaz Ahorros 
                  begin
                     if @i_pago_ext = 'N'
                     begin 
                        print 'ANTES DE sp_afect_prod_cobis - REVERSA DESEMBOLSOS '
                        print 'w_secuencial_retro: ' + cast(@w_secuencial_retro as varchar)
                        print 'w_prod_rev: ' + @w_prod_rev
                     end
                  end
   
                  exec @w_error = sp_afect_prod_cobis   
                  @s_ssn          = @s_ssn,
                  @s_sesn         = @s_sesn,
                  @s_srv          = @s_srv,
                  @s_user         = @s_user,
                  @s_ofi          = @w_oficina_ifase,
                  @s_lsrv         = @s_lsrv,
                  @s_term         = @s_term,
                  @s_rol          = @s_rol,
                  @s_date         = @s_date,
                  @i_fecha        = @s_date,
                  @i_cuenta       = @w_cuenta,
                  @i_producto     = @w_prod_rev,
                  @i_monto        = @w_monto,
                  @i_operacionca  = @w_operacionca,  ---Para reversar moneda extranjera ce_transferencia_pendiente
                  @i_opcion       = 7,               --PARA COMERCIO EXTERIOR
                  @i_alt          = @w_operacionca,
                  @i_reversa      = 'S',
                  @i_mon          = @w_moneda_trn,
                  @i_en_linea     = @i_en_linea,
                  @i_sec_tran_cca = @w_secuencial_retro, -- FCP Interfaz Ahorros                     
                  @i_secuencial_tran = @w_idlote,
                  @i_dm_desembolso   = @w_dm_desembolso
                   
                  if @w_error <> 0 
                  begin
                     close cursor_afecta_prod
                     deallocate cursor_afecta_prod
                     goto ERROR
                  end
                  
               end   
               --FINALIZA LA INTERFAZ CON OTROS PRODUCTOS
                  
               -- PARA INTERFAZ CON TESORERIA
               select @w_categoria = cp_categoria
               from   ca_producto
               where  cp_producto = @w_prod_rev
               
               select @w_fecha_ingreso = getdate()
               
               if @w_categoria in ('NCAH','NCCC','NDAH','NDCC','EFEC','CHLO','CHOT','CHGE') 
               begin
                  if @i_debug = 'S' -- FCP Interfaz Ahorros 
                  begin
                     if @i_pago_ext = 'N'
                     begin 
                        print 'ANTES DE sp_interfaz_otros_modulos'
                        print 'w_secuencial_retro: ' + cast(@w_secuencial_retro as varchar)
                     end
                  end          
                  exec @w_error = sp_interfaz_otros_modulos
                  @s_user         = @s_user,
                  @i_cliente      = @w_cliente,
                  @i_modulo       = 'CCA',
                  @i_interfaz     = 'T',
                  @i_modo         = 'I',
                  @i_obligacion   = @i_banco,
                  @i_moneda       = @w_moneda_trn,
                  @i_sec_trn      = @w_secuencial_retro,
                  @i_fecha_trn    = @w_fecha_ingreso,
                  @i_desc_trn     = 'DESEMBOLSO DE CARTERA',
                  @i_monto_trn    = @w_monto,
                  @i_cotizacion   = @w_cotizacion_trn,
                  @i_forma_desm   = @w_prod_rev,
                  @i_oficina      = @s_ofi,
                  @i_gerente      = @s_user,
                  @i_afec_trn     = 'E',     --EGRESO
                  @i_tipo_trn     = 'R',      --REVERSA
                  @i_categoria    = @w_categoria
                  
                  if @w_error <> 0  
                     goto ERROR
               end
               
               fetch cursor_afecta_prod
               into  @w_prod_rev,     @w_monto,      @w_cuenta,
                     @w_pcobis,       @w_moneda_trn, @w_cotizacion_trn,
                     @w_codvalor_mpg, @w_idlote,     @w_dm_desembolso
            end --END WHILE
            
            close cursor_afecta_prod
            deallocate cursor_afecta_prod
            
            --EN EL REVERSO DEL DES PARA ASEGURAR LA EXISTENCIA DE LA OBLIGACION AL REALIZAR TRANSACCION DE R o F  
            if not exists(select 1
            from ca_operacion
            where op_operacion = @w_operacionca)
            begin
               select @w_error = 701049
               goto ERROR
            end     
         end
         
         -- REVERSAR LA PRIMERA LIQUIDACION
         if @w_tran = 'DES' 
         begin
            --NR-244
            if exists (select 1 from ca_pago_planificador
            where  pp_operacion = @w_operacionca
            and    pp_estado =  'I')
            begin
               update ca_pago_planificador
               set pp_estado =  'R'
               where   pp_operacion = @w_operacionca
               and     pp_estado =  'I'
            end         
            
            --REVERSO DEL ESTADO DEL DOCUMENTO PARA DD  NR-126
            if (@w_tipo = 'F') or  (@w_tipo = 'D' ) 
            begin
               exec @w_error =   sp_reversos_dd
               @i_tramite     = @w_tramite,
               @i_tran        = 'DES',
               @i_operacionca = @w_operacionca
               
               if @w_error <> 0  
                  goto ERROR
            end 
            
            select 
            @w_prod_rev       = dm_producto,
            @w_monto          = dm_monto_mds,
            @w_cotizacion_trn = dm_cotizacion_mds,
            @w_moneda_trn     =  dm_moneda
            from   ca_desembolso
            where  dm_operacion = @w_operacionca
            
            -- PARA INTERFAZ CON TESORERIA
            select @w_categoria = cp_categoria
            from   ca_producto
            where  cp_producto = @w_prod_rev
            
            select @w_fecha_ingreso = getdate()
            
            if @w_categoria in ('NCAH','NCCC','NDAH','NDCC','EFEC','CHLO','CHOT','CHGE') 
            begin
               if @i_debug = 'S' -- FCP Interfaz Ahorros 
               begin
                  if @i_pago_ext = 'N'
                  begin 
                     print 'ANTES DE sp_interfaz_otros_modulos'
                     print 'w_secuencial_retro: ' + cast(@w_secuencial_retro as varchar)
                  end
               end         
               exec @w_error = sp_interfaz_otros_modulos
               @s_user         = @s_user,
               @i_cliente      = @w_cliente,
               @i_modulo       = 'CCA',
               @i_interfaz     = 'T',
               @i_modo         = 'I',
               @i_obligacion   = @i_banco,
               @i_moneda       = @w_moneda_trn,
               @i_sec_trn      = @w_secuencial_retro,
               @i_fecha_trn    = @w_fecha_ingreso,
               @i_desc_trn     = 'DESEMBOLSO DE CARTERA',
               @i_monto_trn    = @w_monto,
               @i_cotizacion   = @w_cotizacion_trn,
               @i_forma_desm   = @w_prod_rev,
               @i_oficina      = @s_ofi,
               @i_gerente      = @s_user,
               @i_afec_trn     = 'E',     
               @i_tipo_trn     = 'R',
               @i_categoria    = @w_categoria
               
               if @w_error <> 0  
                  goto ERROR
            end
            
            
            /*CAMBIO DE ESTADO EN EL GENERA ORDEN PARA PAGOS DE CAJA*/
            
            select 
            @w_sec_orden =  max(dm_secuencial),    
            @w_orden_pag  = dm_orden_caja
            from ca_desembolso
            where dm_operacion =  @w_operacionca      
            group by dm_secuencial,dm_orden_caja
   
            if @w_orden_pag is not null
            begin 
               exec @w_return    = cob_remesas..sp_genera_orden
               @s_date           = @s_date,       --> Fecha de proceso
               @s_user           = @s_user,       --> Usuario
               @i_operacion      = 'A',           --> Operacion ('I' -> Insercion, 'A' Anulaci¢n)
               @i_causa          = '003',         --> Causal de Ingreso(cc_causa_oioe)
               @i_ente           = @w_cliente,    --> Cod ente,
               @i_tipo           = 'P',           --> 'C' -> Orden de Cobro/Ingreso, 'P' -> Orden de Pago/Egreso
               @i_idorden        = @w_orden_pag,  --> C¢d Orden cuando operaci¢n 'A', 
               @i_ref1           = 0,             --> Ref. N£merica no oblicatoria
               @i_ref2           = 0,             --> Ref. N£merica no oblicatoria
               @i_ref3           = @i_banco,      --> Ref. AlfaN£merica no oblicatoria
               @i_interfaz       = 'N'            --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve c¢d error
               
               if @@error <> 0 or  @w_error <> 0
               begin                        
                  goto ERROR
               end  
            end
         
            select @w_es_liq = 'S'
            
            delete ca_abono_det
            from   ca_abono,
                   ca_abono_det
            where  abd_operacion = @w_operacionca
            and    abd_operacion = ab_operacion
            and    abd_secuencial_ing = ab_secuencial_ing
            and    ab_secuencial_pag  > @w_secuencial_retro
            
            if @@error <> 0 
            begin
               select @w_error = 710003 
               goto ERROR
            end
            
            delete ca_abono
            where  ab_operacion = @w_operacionca
            and    ab_secuencial_pag  > @w_secuencial_retro
            
            if @@error <> 0 
            begin
               select @w_error = 710003
               goto ERROR
            end
            
            delete ca_desembolso
            where  dm_operacion = @w_operacionca
            and    dm_secuencial  = @w_secuencial_retro
            
            if @@error <> 0 
            begin
               select @w_error = 710003
               goto ERROR
            end
            
            delete ca_tasas
            where  ts_operacion = @w_operacionca
            
            if @@error <> 0 
            begin
               select @w_error = 710003
               goto ERROR
            end
            
            delete ca_ultima_tasa_op
            where ut_operacion = @w_operacionca   
            
            if @@error <> 0 
            begin
               select @w_error = 710003
               goto ERROR
            end
                     
            exec @w_error = cob_credito..sp_in_cupos_asoc 
                 @s_date        = @s_date,
                 @i_operacion   = 'R',
                 @i_operacionca = @w_operacionca
            
            if @@error <> 0 or @@trancount = 0 
            begin
               select @w_error = 710522
               goto ERROR
            end
            
            if @w_error <> 0 
            begin
               goto ERROR
            end
         end 
         
         -- REVERSAR UN DESEMBOLSO PARCIAL
         if (@w_tran = 'DES') and (@w_secuencial_retro > @w_secuencial_min) 
         begin
            select 
            @w_prod_rev       = dm_producto,
            @w_monto          = dm_monto_mds,
            @w_cotizacion_trn = dm_cotizacion_mds,
            @w_moneda_trn     = dm_moneda
            from   ca_desembolso
            where  dm_operacion = @w_operacionca
            
            -- PARA INTERFAZ CON TESORERIA
            select @w_categoria = cp_categoria
            from   ca_producto
            where  cp_producto = @w_prod_rev
            
            select @w_fecha_ingreso = getdate()  
            
            if @w_categoria in ('NCAH','NCCC','NDAH','NDCC','EFEC','CHLO','CHOT','CHGE') 
            begin
               exec @w_error = sp_interfaz_otros_modulos
               @s_user         = @s_user,
               @i_cliente      = @w_cliente,
               @i_modulo       = 'CCA',
               @i_interfaz     = 'T',
               @i_modo         = 'I',
               @i_obligacion   = @i_banco,
               @i_moneda       = @w_moneda_trn,
               @i_sec_trn      = @w_secuencial_retro,
               @i_fecha_trn    = @w_fecha_ingreso,
               @i_desc_trn     = 'DESEMBOLSO DE CARTERA',
               @i_monto_trn    = @w_monto,
               @i_cotizacion   = @w_cotizacion_trn,
               @i_forma_desm   = @w_prod_rev,
               @i_oficina      = @s_ofi,
               @i_gerente      = @s_user,
               @i_afec_trn     = 'E',     
               @i_tipo_trn     = 'R',
               @i_categoria    = @w_categoria
               
               if @w_error   <> 0 
               begin
                  goto ERROR
               end
            end
            
            delete ca_desembolso
            where  dm_secuencial = @w_secuencial_retro
            and    dm_operacion    = @w_operacionca
            
            if @@error <> 0 
            begin
               select @w_error = 710003
               goto ERROR
            end
            
            --EN EL REVERSO DEL DES PARA ASEGURAR LA EXISTENCIA DE LA OBLIGACION AL REALIZAR TRANSACCION DE R o F  
            if not exists(select 1
            from ca_operacion
            where op_operacion = @w_operacionca)
            begin
               select @w_error = 701049
               goto ERROR
            end
         end ---END DESEMBOLSO PARCIAL
   
         -- REVERSAR UN PAGO 
         if @w_tran in ('PAG', 'CON') 
         begin
            select @w_secuencial_pag = ab_secuencial_pag,
                   @w_secuencial_rpa = ab_secuencial_rpa
            from   ca_abono
            where  ab_operacion      = @w_operacionca
            and    ab_secuencial_pag = @w_secuencial_retro
            and    ab_estado         = 'A' -- SOLO SE REVIERTEN PAGOS APLICADOS
            
            if @@rowcount = 0 
            begin
               select @w_error = 710542
               goto ERROR
            end
            
            select @w_transaccion_pag = 'S'
            
            select @w_dividendo = dtr_dividendo
            from   ca_det_trn 
            where  dtr_secuencial = @w_secuencial_retro
            and    dtr_operacion = @w_operacionca
            
            update ca_abono
            set    ab_estado   = 'RV'
            where  ab_secuencial_pag = @w_secuencial_retro
            and    ab_operacion      = @w_operacionca
            
            if @@error <> 0 
            begin
               select @w_error = 710002
               goto ERROR
            end
            
            select @w_fecha_pag = ab_fecha_pag,
                   @w_secuencial_ing = ab_secuencial_ing
            from   ca_abono
            where  ab_secuencial_pag = @w_secuencial_retro
            and    ab_operacion = @w_operacionca
            
            
            update cobis..cl_det_producto
            set    dp_estado_ser   = 'V'
            from   cobis..cl_cliente
            where  dp_det_producto = cl_det_producto
            and    dp_producto     = 7
            and    dp_estado_ser   = 'C'
            and    cl_cliente      = @w_cliente
      
            
            ---UN PREPGO SE MARCA COMO REVERSADO SOLOSI AUN NO  HA SIDO APLICADO 
            ---A  LA OBLIGACION PASIVA
            if @w_tipo  = 'C' and @i_operacion = 'R' 
            begin
               --- REVISAR SI LA PASIVA TIENE UN PREPAGO EN ESTADO I PARA ESTE SECUENCIAL DE REVERSO
               select @w_min_sec_prepago = 0
               
               select @w_banco_pasivo = op_banco
               from   ca_operacion
               where  op_cliente = @w_cliente
               and    op_codigo_externo = @w_llave_redescuento
               and    op_tipo = 'R'
               
               if @@rowcount  <> 0 
               begin
                  if  exists (select 1
                  from   ca_prepagos_pasivas
                  where  pp_banco =  @w_banco_pasivo
                  and    pp_sec_pagoactiva  = @w_secuencial_retro  )
                  begin
                      --DEF-5493
                      --SE INSERTA PARA CONTROL DE PREPAGOS EN PASIVAS
                      insert into ca_prepagos_por_reversos
                      (
                      pr_fecha_cierre_rev, pr_fecha_de_pago, pr_operacion_activa,
                      pr_secuencial_pag,   pr_usuario
                      )
                      values
                      (
                      @w_fecha_cartera,    @w_fecha_pag,     @w_operacionca,
                      @w_secuencial_retro, @s_user
                      )
                  end
               end
            end
            
            if @w_tipo  = 'R' 
            begin
               if exists (select 1 from ca_prepagos_pasivas
               where pp_banco =  @i_banco
               and   pp_secuencial_ing = @w_secuencial_ing)
               begin
                  update ca_prepagos_pasivas set 
                  pp_estado_registro = 'R',
                  pp_causal_rechazo  = '7',
                  pp_comentario      = 'REVERSO DEL PAGO  OPERACION PASIVA'
                  where pp_banco =  @i_banco
                  and   pp_secuencial_ing = @w_secuencial_ing          
               end
            end         
            
            -- AFECTACION A OTROS PRODUCTOS
            declare
               cursor_afecta_productos cursor
               for select 
                   cp_producto_reversa, abs(abd_monto_mpg), abd_cuenta,
                   abd_moneda,          abd_cotizacion_mpg, abd_beneficiario,
                   isnull(cp_pcobis,0), abd_cheque,         abd_cod_banco,
                   abd_carga,           cp_codvalor,        abd_tipo,
                   ab_secuencial_rpa -- FCP Interfaz Ahorros                        
                   from   ca_abono_det, ca_producto, ca_abono
                   where  ab_secuencial_pag = @w_secuencial_retro
                   and    ab_operacion      = @w_operacionca
                   and    ab_operacion      = abd_operacion
                   and    ab_secuencial_ing = abd_secuencial_ing 
                   and    ab_operacion      = abd_operacion 
                   and    abd_concepto      = cp_producto             
                   and    abd_tipo          in('PAG', 'SEG')
                   for read only
      
            open  cursor_afecta_productos
            
            fetch cursor_afecta_productos
            into  @w_prod_rev,             @w_abd_monto_mpg,      @w_cuenta,
                  @w_moneda_trn,           @w_cotizacion_trn,     @w_beneficiario,
                  @w_pcobis,               @w_cheque,             @w_cod_banco,
                  @w_carga,                @w_codvalor_mpg,       @w_abd_tipo,             
                  @w_ab_sec_rpa   -- FCP Interfaz Ahorros 
            while (@@fetch_status = 0) 
            begin  
               if @w_prod_rev = null 
               begin
                  close cursor_afecta_productos 
                  deallocate cursor_afecta_productos 
                  select @w_error = 710345
                  goto ERROR
               end
               
               select @w_prodcobis_rev = isnull(cp_pcobis,0)
               from ca_producto
               where cp_producto = @w_prod_rev
               
               --SOLO SI LA FORMA DE REVERSO ES PARA AFECTAR A OTRO PRODUCTO DIFERENTE DE CARTERA
               --SE EJECUTARA EL afpcobis.sp
               
               if @w_prodcobis_rev in (3,4,9,48,26) 
               begin --AHO-CTAS-SIDAC-CARTERA
               
                  select @w_oficina_ifase = @s_ofi
                  
                  if @w_abd_tipo ='PAG' 
                  begin
                     select @w_tipo_oficina_ifase = dp_origen_dest
                     from   ca_trn_oper, cob_conta..cb_det_perfil
                     where  to_tipo_trn = 'RPA'
                     and    to_toperacion = @w_toperacion
                     and    dp_empresa    = 1
                     and    dp_producto   = 7
                     and    dp_perfil     = to_perfil
                     and    dp_codval     = @w_codvalor_mpg
                     
                     if @@rowcount = 0 
                     begin
                        select @w_error = 710446
                        goto ERROR
                     end
                  end
                  
                  if @w_abd_tipo ='SEG' 
                  begin
                     select @w_tipo_oficina_ifase = dp_origen_dest
                     from   ca_trn_oper, cob_conta..cb_det_perfil
                     where  to_tipo_trn = 'PAG'
                     and    to_toperacion = @w_toperacion
                     and    dp_empresa    = 1
                     and    dp_producto   = 7
                     and    dp_perfil     = to_perfil
                     and    dp_codval     = @w_codvalor_mpg
                     
                     if @@rowcount = 0 
                     begin
                        select @w_error = 710446
                        goto ERROR
                     end
                  end
                  
                  if @w_tipo_oficina_ifase = 'C' 
                  begin
                     select @w_oficina_ifase = pa_int
                     from   cobis..cl_parametro
                     where  pa_nemonico = 'OFC'
                     and    pa_producto = 'CON'
                     set transaction isolation level read uncommitted
                  end
                  
                  if @w_tipo_oficina_ifase = 'D' 
                  begin
                     select @w_oficina_ifase = @w_oficina
                  end
   
                  if @w_pcobis  in (3,4,26) 
                  begin
                     if @i_debug = 'S'  -- FCP Interfaz Ahorros 
                     begin
                        if @i_pago_ext = 'N'
                        begin 
                           print 'ANTES DE sp_afect_prod_cobis - REVERSA PAGOS'                     
                           print 'w_ab_sec_rpa: ' + cast(@w_ab_sec_rpa as varchar)
                           print 'w_prod_rev: ' + @w_prod_rev
                        end
                     end              
                     exec @w_error    = sp_afect_prod_cobis
                     @s_ssn            = @s_ssn,
                     @s_sesn           = @s_sesn,
                     @s_srv            = @s_srv,
                     @s_user           = @s_user,
                     @s_ofi            = @s_ofi,
                     @s_lsrv           = @s_lsrv,
                     @s_term           = @s_term,
                     @s_rol            = @s_rol,
                     @s_date           = @s_date,
                     @t_ssn_corr       = @w_carga,
                     @i_fecha          = @s_date,
                     @i_cuenta         = @w_cuenta,
                     @i_producto       = @w_prod_rev,
                     @i_beneficiario   = @w_beneficiario,   
                     @i_no_cheque      = @w_cheque,         
                     @i_abd_cod_banco  = @w_cod_banco,      
                     @i_reversa        = 'S',               
                     @i_monto          = @w_abd_monto_mpg,
                     @i_operacionca    = @w_operacionca,
                     @i_mon            = @w_moneda_trn,
                     @i_alt            = @w_operacionca,
                     @i_sec_tran_cca   = @w_ab_sec_rpa, -- FCP Interfaz Ahorros                       
                     @i_en_linea       = @i_en_linea
                     
                     if @w_error <> 0 
                     begin
                        close cursor_afecta_productos 
                        deallocate cursor_afecta_productos 
                        goto ERROR
                     end
                  end
                  -- PARA INTERFAZ CON TESORERIA
                  ------------------------------
                  select @w_categoria = cp_categoria
                  from   ca_producto
                  where  cp_producto = @w_prod_rev
                  
                  select @w_fecha_ingreso = getdate()
   
                  if @w_categoria in ('NCAH','NCCC','NDAH','NDCC','EFEC','CHLO','CHOT','CHGE') 
                  begin
                     exec @w_error = sp_interfaz_otros_modulos
                     @s_user         = @s_user,
                     @i_cliente      = @w_cliente,
                     @i_modulo       = 'CCA',
                     @i_interfaz     = 'T',
                     @i_modo         = 'I',
                     @i_obligacion   = @i_banco,
                     @i_moneda       = @w_moneda_trn,
                     @i_sec_trn      = @w_secuencial_retro,
                     @i_fecha_trn    = @w_fecha_ingreso,
                     @i_desc_trn     = 'DESEMBOLSO DE CARTERA',
                     @i_monto_trn    = @w_abd_monto_mpg,
                     @i_cotizacion   = @w_cotizacion_trn,
                     @i_forma_desm   = @w_prod_rev,
                     @i_oficina      = @s_ofi,
                     @i_gerente      = @s_user,
                     @i_afec_trn     = 'I',    
                     @i_tipo_trn     = 'R',
                     @i_categoria    = @w_categoria
                     
                     if @w_error <> 0 
                     begin
                        goto ERROR
                     end
                  end
                  
               end
               
               fetch cursor_afecta_productos
               into  @w_prod_rev,         @w_abd_monto_mpg,           @w_cuenta,
                     @w_moneda_trn,       @w_cotizacion_trn,          @w_beneficiario,
                     @w_pcobis,           @w_cheque,                  @w_cod_banco,
                     @w_carga,            @w_codvalor_mpg,            @w_abd_tipo,
                     @w_ab_sec_rpa  -- FCP Interfaz Ahorros
            end -- END WHILE
            
            close cursor_afecta_productos 
            deallocate cursor_afecta_productos 
            
            select 
            @w_estado          = cu_estado,
            @w_agotada         = cu_agotada,
            @w_abierta_cerrada = cu_abierta_cerrada,
            @w_tipo_gar        = cu_tipo
            from   cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta
            where  gp_garantia = cu_codigo_externo 
            and    cu_agotada = 'S'
            and    gp_tramite = @w_tramite
            
            select @w_contabiliza = tc_contabilizar
            from   cob_custodia..cu_tipo_custodia
            where  tc_tipo = @w_tipo_gar
            
            select @w_monto_gar = isnull(sum(dtr_monto),0),
                   @w_monto_gar_mn = isnull(sum(dtr_monto_mn),0)
            from   ca_transaccion, ca_det_trn, ca_rubro_op
            where  tr_operacion = @w_operacionca
            and    tr_tran  = 'PAG'
            and    tr_secuencial = @w_secuencial_retro
            and    tr_estado     <> 'RV'
            and    tr_secuencial  = dtr_secuencial
            and    tr_operacion   = dtr_operacion
            and    ro_operacion   = tr_operacion
            and    dtr_concepto   = ro_concepto 
            and    ro_tipo_rubro  = 'C' 
            
            if (@w_estado = 'V' and @w_agotada = 'S' and @w_abierta_cerrada = 'C' and @w_contabiliza = 'S') 
                and @w_tramite is not null
            begin
               select @w_capitaliza = 'N'
               if exists (select 1 from ca_acciones
               where ac_operacion = @w_operacionca)
                  select @w_capitaliza = 'S'   
      
               ---SE SACA EL SALDO DE CAPITAL ANTES DEL PAGO PARA CALCULOS EN GARANTIAS
               select @w_saldo_cap_gar = sum(am_cuota + am_gracia - am_pagado)
               from   ca_amortizacion, ca_rubro_op
               where  ro_operacion  = @w_operacionca 
               and    ro_tipo_rubro = 'C'
               and    am_operacion  = @w_operacionca
               and    am_estado <> 3
               and    am_concepto   = ro_concepto
               
               if @w_moneda = @w_moneda_nac
                  select @w_cotizacion_pago = 1.0
               else 
               begin
                  exec sp_buscar_cotizacion
                  @i_moneda     = @w_moneda,
                  @i_fecha      = @w_fecha_pag,
                  @o_cotizacion = @w_cotizacion_pago output
               end
               
               select @w_saldo_cap_gar = @w_saldo_cap_gar * @w_cotizacion_pago 
   
               exec @w_error = cob_custodia..sp_agotada 
               @s_ssn         = @s_ssn,
               @s_date        = @s_date,
               @s_user        = @s_user,
               @s_term        = @s_term,
               @s_ofi         = @s_ofi,
               @t_trn         = 19911,
               @t_debug       = 'N',
               @t_file        = NULL,
               @t_from        = NULL,
               @i_operacion   = 'R',          -- pago  'R' reversa de pago
               @i_monto       = @w_monto_gar, -- monto del pago
               @i_monto_mn    = @w_monto_gar_mn, ---monto moneda nacional
               @i_moneda      = @w_moneda,    -- moneda del pago
               @i_saldo_cap_gar = @w_saldo_cap_gar ,
               @i_tramite     = @w_tramite,    -- tramite 
               @i_capitaliza  = @w_capitaliza
                      
               select @w_sperror = @@error
               
               if @w_sperror <> 0 or @@trancount = 0 
               begin
                  select @w_error = 710522
                  goto ERROR
               end
                  
               if @w_error <> 0 
               begin
                  goto ERROR
               end
   
               
            end
            
            --REVERSO DEL ESTADO DEL DOCUMENTO PARA DD
            
            if (@w_tipo = 'F') or  (@w_tipo = 'D' ) 
            begin
                exec @w_error =   sp_reversos_dd
                @i_tramite     = @w_tramite,
                @i_tran        = 'PAG',
                @i_operacionca = @w_operacionca,
                @i_sec_rev      = @w_secuencial_retro
                
                if @w_error <> 0  
                   goto ERROR
            end
   
            -- ACTUALIZA ESTADO DE LA RENOVACION EN CREDITO
            update cob_credito..cr_op_renovar set 
               or_finalizo_renovacion = 'N',
               or_sec_prn             = null
            where or_num_operacion       = @i_banco
            and   or_finalizo_renovacion = 'S'
            and   or_sec_prn             = @w_secuencial_ing
            
            if @@error <> 0
            begin
               select @w_error = 724515
               goto ERROR
            end         
         end
      end  -- END (R)EVERSAS
 
           
      if @i_operacion = 'F' 
      begin
         select @w_numero_pagos = count(1)
         from   ca_abono
         where  ab_secuencial_pag >= @w_secuencial_retro
         and    ab_operacion       = @w_operacionca
         and    ab_fecha_pag      >= @i_fecha_valor
         and    ab_estado     not in ('RV','E', 'ING', 'ANU', 'UNI')
      end
       
      update ca_otro_cargo
      set    oc_estado = 'NA'
      where  oc_operacion = @w_operacionca
      and    oc_secuencial >=  @w_secuencial_retro
      
      -- ACTUALIZAR PAGOS COMO NO APLICADOS
      
      update ca_abono
      set    ab_estado         = 'NA',
             ab_dias_retencion = ab_dias_retencion_ini
      where  ab_secuencial_pag >= @w_secuencial_retro
      and    ab_operacion       = @w_operacionca
      and    ab_fecha_pag      >= @i_fecha_valor
      and    ab_estado     not in ('RV','E', 'ING', 'ANU')
      
      if @@error <> 0 
      begin
         select @w_error = 710002
         goto ERROR
      end
      
      update ca_abono
      set    ab_estado         = 'NA'
      where  ab_secuencial_pag>= @w_secuencial_retro
      and    ab_operacion      = @w_operacionca
      and    ab_fecha_pag      < @i_fecha_valor
      and    ab_estado     not in ('RV', 'E', 'ING', 'ANU')
      
      if @@error <> 0 
      begin
         select @w_error = 710002
         goto ERROR
      end
      
      delete ca_abono_det
      from   ca_abono, ca_abono_det
      where  ab_operacion = abd_operacion
      and    ab_secuencial_ing = abd_secuencial_ing
      and    ab_operacion       = @w_operacionca
      and    ab_fecha_pag      >= @i_fecha_valor
      and    ab_secuencial_pag >=  @w_secuencial_retro
      and    abd_tipo  in('SOB','SEG')
      and    ab_estado     not in ('RV','E', 'ING', 'ANU')      
         
      /******************************************************/
      /**** INICIA: REQ 089 - ACUERDOS DE PAGO        *******/
      /**** - EN CASO DE REVERSO DEL PAGO CON ACUERDO *******/
      /***    ACTUALIZACION DE SECUENCIAL RPA         *******/
      /**** - ACTUALIZACION ESTADO DE VENCIMIENTOS    *******/
      if @i_operacion = 'R'
      begin
         select @w_sec_rpa_acuerdo = ab_secuencial_rpa
         from ca_abono with (nolock)
         where ab_operacion      = @w_operacionca
         and   ab_estado         = 'RV'
         and   ab_secuencial_pag = @i_secuencial
      
         update cob_credito..cr_acuerdo with (rowlock)
         set ac_secuencial_rpa = null   
         where ac_banco          = @i_banco
         and   ac_estado         = 'V'
         and   ac_secuencial_rpa = @w_sec_rpa_acuerdo
         
         if @@error <> 0
         begin
            select @w_error = 710568 -- Error en la Actualizacion del registro!!! 
            goto ERROR
         end
      end
      
      update cob_credito..cr_acuerdo_vencimiento set 
      av_estado       = 'PV',
      av_fecha_estado = @w_fecha_obj
      from cob_credito..cr_acuerdo
      where ac_banco   = @i_banco
      and   ac_estado  = 'V'
      and   av_acuerdo = ac_acuerdo
      and   av_fecha  >= @w_fecha_obj
      
      if @@error <> 0
      begin
         select @w_error = 710568 -- Error en la Actualizacion del registro!!! 
         GOTO ERROR
      end
      /****       FINALIZA: ACUERDOS DE PAGOS             *******/
      /**********************************************************/            
              
      if @w_lin_credito is not null 
         select @w_shela  = 0
      else
         select @w_shela = 1
      
      select 
      @w_monto_pag    = isnull(sum(dtr_monto),0),
      @w_monto_pag_mn = isnull(sum(dtr_monto_mn),0)
      from   ca_transaccion, ca_det_trn, ca_rubro_op
      where  tr_operacion = @w_operacionca
      and    tr_tran  in ('PAG', 'PRN', 'CON')
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_estado     <> 'RV'
      and    tr_secuencial  = dtr_secuencial
      and    tr_operacion   = dtr_operacion
      and    ro_operacion   = tr_operacion
      and    dtr_concepto   = ro_concepto 
      and    ro_tipo_rubro  = 'C' 
      
      select @w_monto_des = isnull(sum(dtr_monto),0),
             @w_monto_des_mn = isnull(sum(dtr_monto_mn),0)
      from   ca_transaccion, ca_det_trn, ca_rubro_op
      where  tr_operacion = @w_operacionca
      and    tr_tran  = 'DES'
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_estado     <> 'RV'
      and    tr_secuencial  = dtr_secuencial
      and    tr_operacion   = dtr_operacion
      and    ro_operacion   = tr_operacion
      and    dtr_concepto   = ro_concepto 
      and    dtr_codvalor  <> 10990
      and    ro_tipo_rubro  = 'C' 
      
      if @w_moneda = 0
         select @w_monto_des = @w_monto_des - @w_monto_pag
      else
         select @w_monto_des = @w_monto_des_mn - @w_monto_pag_mn
      
      if @w_monto_des > 0 
         select @w_tipo ='X' --'D' XSA
      else
         select @w_tipo ='Y',  --'C' XSA
                @w_monto_des = -1 * @w_monto_des 
   
      if (@w_monto_des  > 0 and @w_tran = 'DES' ) or ( @w_monto_pag > 0 ) 
         and @w_tramite is not null and @w_lin_credito is not null 
         begin
         
         if @w_tran = 'DES'
            select @w_utilizado_cupo = @w_monto_des
         else
            select @w_utilizado_cupo = @w_monto_pag
      
         if @w_opcion = 'R'         -- REDESCUENTO
            select @w_opcion = 'P'  -- PASIVA
         else
            select @w_opcion = 'A'  -- ACTIVA
   
         exec @w_error = cob_credito..sp_utilizacion
         @s_date        = @s_date,
         @s_lsrv        = @s_lsrv,
         @s_ofi         = @s_ofi,
         @s_org         = @s_org,
         @s_rol         = @s_rol,
         @s_sesn        = @s_sesn,
         @s_srv         = @s_srv,
         @s_ssn         = @s_ssn,
         @s_term        = @s_term,
         @s_user        = @s_user,
         @t_trn         = 21888,
         @i_linea_banco = @w_lin_credito,
         @i_producto    = 'CCA',
         @i_toperacion  = @w_toperacion,
         @i_tipo        = @w_tipo,
         @i_moneda      = @w_moneda,
         @i_monto       = @w_utilizado_cupo,
         @i_secuencial  = @w_secuencial_retro,
         @i_tramite     = @w_tramite,   
         @i_opcion      = @w_opcion,  
         @i_opecca      = @w_operacionca,
         @i_fecha_valor = @i_fecha_valor,
         @i_cliente     = @w_cliente,
         @i_modo        = @w_shela,
         @i_numoper_cex = @w_numero_comex  ---EPB:oct-09-2001
         
         if @@error <> 0 or @@trancount = 0 
         begin
            select @w_error = 710522
            goto ERROR
         end
         
         if @w_error <> 0 
         begin 
            goto ERROR
         end
      end
   
--REVERSAR REGISTROS CONTABLES'
      exec @w_error =  sp_transaccion
      @s_date             = @s_date,
      @s_ofi              = @s_ofi,
      @s_term             = @s_term,
      @s_user             = @s_user,
      @i_operacion        = @i_operacion,
      @i_secuencial_retro = @w_secuencial_retro,
      @i_observacion      = @i_observacion_corto,
      @i_operacionca      = @w_operacionca,
      @i_fecha_retro      = @w_fecha_retro,
      @i_es_atx        = @i_es_atx
           
      if @w_error <> 0 
      begin
         if @i_pago_ext = 'N'
            print 'Error en sp_transaccion ' + cast(@s_date as varchar)
         goto ERROR
      end
    
      
      /* ACTUALIZACION SALDO FONDO DE RECURSOS POR DESEMBOLSO REVERSADO */
      if @i_operacion = 'R' and @w_tran = 'DES'
      begin
         if isnull(@w_error,0) = 0
         begin
            exec @w_return      = sp_actualiza_saldo_fondo
            @s_user        = @s_user,
            @i_operacion   = 'D',  --Opcion de desembolso
            @i_modo        = 'R',  --Opcion de reversion
            @i_operacionca = @w_operacionca,
            @i_valor       = 0
            if @w_return <> 0 
            begin
               select @w_error = @w_return
               goto ERROR
            end
         end
      end
      
      /* ACTUALIZACION SALDO FONDO DE RECURSOS POR PAGO REVERSADO */
      if @i_operacion = 'R' and @w_tran = 'PAG' 
      begin
         if isnull(@w_error,0) = 0 
         begin

            select @w_monto_cap_pag_rv = isnull(sum(dtr_monto), 0) - @w_monto_cap_pag_rv_ini
            from   ca_transaccion, ca_det_trn
            where  tr_operacion = @w_operacionca
            and    tr_secuencial >= @w_secuencial_retro
            and    tr_tran       = 'PAG'
            and    tr_estado     = 'RV'
            and    dtr_operacion = tr_operacion
            and    dtr_secuencial = tr_secuencial
            and    dtr_codvalor <> 10017
            and    dtr_codvalor <> 10027
            and    dtr_codvalor <> 10097
            and    dtr_concepto   = 'CAP'
   
            exec @w_return      = sp_actualiza_saldo_fondo
            @s_user        = @s_user,
            @i_operacion   = 'P',  --Opcion de pago
            @i_modo        = 'R',  --Opcion de reversion
            @i_operacionca = @w_operacionca,
            @i_valor       = @w_monto_cap_pag_rv
            
            if @w_return <> 0 
            begin
                select @w_error = @w_return
                goto ERROR
            end
            
         end
      end
   
               
      /* ELIMINACION DEL COBRO POR RECAUDO CONVENIO Y SU IVA POR PAGO REVERSADO */
      if @i_operacion = 'R' and @w_tran = 'PAG' 
      begin
         if isnull(@w_error,0) = 0 
         begin
             --LECTURA DEL VALOR A REVERSAR POR COMISION DE RECAUDO Y SU DIVIDENDO AFECTADO CORRESPONDIENTE
             select @w_valor_recaudo = isnull(dtr_monto, 0),
                    @w_min_dividendo = dtr_dividendo
             from   ca_transaccion, ca_det_trn
             where  tr_operacion   = @w_operacionca
             and    tr_secuencial  = @w_secuencial_retro
             and    tr_tran        = 'PAG'
             and    tr_estado      = 'RV'
             and    dtr_operacion  = tr_operacion
             and    dtr_secuencial = tr_secuencial
             and    dtr_concepto   = 'CMRCGTECH'
      
             if @w_valor_recaudo is null
                select @w_valor_recaudo = 0
      
              --ACTUALIZACION DEL VALOR COBRADO POR COMISION DE RECAUDO
              update ca_rubro_op
              set ro_valor = ro_valor - @w_valor_recaudo
              where ro_operacion = @w_operacionca
              and   ro_concepto  = 'CMRCGTECH'
      
              update ca_amortizacion
              set am_cuota     = am_cuota - @w_valor_recaudo,
                  am_acumulado = am_acumulado - @w_valor_recaudo
              where am_operacion = @w_operacionca
              and   am_dividendo = @w_min_dividendo
              and   am_concepto  = 'CMRCGTECH'
      
             --LECTURA DEL VALOR A REVERSAR POR IVA SOBRE LA COMISION POR RECAUDO Y SU DIVIDENDO CORRESPONDIENTE
             select @w_valor_iva_recaudo = isnull(dtr_monto, 0),
                    @w_min_dividendo = dtr_dividendo
             from   ca_transaccion, ca_det_trn
             where  tr_operacion   = @w_operacionca
             and    tr_secuencial  = @w_secuencial_retro
             and    tr_tran        = 'PAG'
             and    tr_estado      = 'RV'
             and    dtr_operacion  = tr_operacion
             and    dtr_secuencial = tr_secuencial
             and    dtr_concepto   = 'IVACOMGTCH'
      
             if @w_valor_iva_recaudo is null
                select @w_valor_iva_recaudo = 0
      
              --ACTUALIZACION DEL VALOR COBRADO POR IVA SOBRE LA COMISION DE RECAUDO
              update ca_rubro_op
              set ro_valor = ro_valor - @w_valor_iva_recaudo
              where ro_operacion = @w_operacionca
              and   ro_concepto  = 'IVACOMGTCH'
      
              update ca_amortizacion
              set am_cuota     = am_cuota - @w_valor_iva_recaudo,
                  am_acumulado = am_acumulado - @w_valor_iva_recaudo
              where am_operacion = @w_operacionca
              and   am_dividendo = @w_min_dividendo
              and   am_concepto  = 'IVACOMGTCH'
      
              if @w_return <> 0 
              begin
                  select @w_error = @w_return
                  goto ERROR
              end
              
              
              /*REVERSA EL VALOR DE LOS HONORARIOS DE ABOGADO E IVA */
              select 
              @w_valor_recaudo = 0,
              @w_min_dividendo = 0
                     
              select 
              @w_valor_recaudo = isnull(dtr_monto, 0),
              @w_min_dividendo = dtr_dividendo
              from   ca_transaccion, ca_det_trn
              where  tr_operacion   = @w_operacionca
              and    tr_secuencial  = @w_secuencial_retro
              and    tr_tran        = 'PAG'
              and    tr_estado      = 'RV'
              and    dtr_operacion  = tr_operacion
              and    dtr_secuencial = tr_secuencial
              and    dtr_concepto   = 'HONABO'
              
              if @w_valor_recaudo is null
                 select @w_valor_recaudo = 0
      
              --ACTUALIZACION DEL VALOR COBRADO POR COMISION DE RECAUDO
              update ca_rubro_op set 
              ro_valor           = ro_valor - @w_valor_recaudo
              where ro_operacion = @w_operacionca
              and   ro_concepto  = 'HONABO'
      
              update ca_amortizacion set 
              am_cuota     = am_cuota - @w_valor_recaudo,
              am_acumulado = am_acumulado - @w_valor_recaudo
              where am_operacion = @w_operacionca
              and   am_dividendo = @w_min_dividendo
              and   am_concepto  = 'HONABO'
      
              --LECTURA DEL VALOR A REVERSAR POR IVA SOBRE LA COMISION POR RECAUDO Y SU DIVIDENDO CORRESPONDIENTE
              select 
              @w_valor_iva_recaudo  = isnull(dtr_monto, 0),
              @w_min_dividendo      = dtr_dividendo
              from   ca_transaccion, ca_det_trn
              where  tr_operacion   = @w_operacionca
              and    tr_secuencial  = @w_secuencial_retro
              and    tr_tran        = 'PAG'
              and    tr_estado      = 'RV'
              and    dtr_operacion  = tr_operacion
              and    dtr_secuencial = tr_secuencial
              and    dtr_concepto   = 'IVAHONOABO'
              
              if @w_valor_iva_recaudo is null
                 select @w_valor_iva_recaudo = 0
      
              --ACTUALIZACION DEL VALOR COBRADO POR IVA SOBRE LA COMISION DE RECAUDO
              update ca_rubro_op set 
              ro_valor           = ro_valor - @w_valor_iva_recaudo
              where ro_operacion = @w_operacionca
              and   ro_concepto  = 'IVAHONOABO'
      
              update ca_amortizacion
              set am_cuota     = am_cuota - @w_valor_iva_recaudo,
                  am_acumulado = am_acumulado - @w_valor_iva_recaudo
              where am_operacion = @w_operacionca
              and   am_dividendo = @w_min_dividendo
              and   am_concepto  = 'IVAHONOABO'
      
              if @w_return <> 0 
              begin
                  select @w_error = @w_return
                  goto ERROR
              end
           end
         end
     
         -- CONTROL DE REVERSAS DE DESEMBOLSOS
         if @i_operacion = 'R' and @w_tran = 'DES' 
         begin
            if exists(select 1
            from   ca_transaccion
            where  tr_operacion = @w_operacionca
            and    tr_tran = 'DES'
            and    tr_secuencial < @w_secuencial_retro)
               select @w_operacionca = @w_operacionca
            else 
            begin -- ESTAN REVERSANDO EL PRIMER DESEMBOLSO
               if exists(select 1
               from   ca_operacion
               where  op_operacion = @w_operacionca
               and    op_estado    > 0) -- NO QUEDO EN ESTADO VIGENTE
               begin
                  if @i_pago_ext = 'N'
                     print 'ERROR REVIRTIENDO EL PRIMER DESEMBOLSO (op_estado <> 0)'
                  select @w_error = 710554
                  goto ERROR
               end
            end
         end
         
         -- MONTO DE LOS PAGOS QUE SE REVERSARON CON TRANSACCION REV (-tr_secuencial)
         select @w_monto_cap_pag_rv = isnull(sum(dtr_monto), 0) - @w_monto_cap_pag_rv_ini
         from   ca_transaccion, ca_det_trn
         where  tr_operacion = @w_operacionca
         and    tr_secuencial >= @w_secuencial_retro
         and    tr_tran       in ('PAG', 'PRN', 'CON')
         and    tr_estado     = 'RV'
         and    dtr_operacion = tr_operacion
         and    dtr_secuencial = -tr_secuencial
         and    dtr_concepto   = 'CAP'
         and    dtr_codvalor   in (10000, 10010, 10020, 10030,10040,10090)
         
         -- MONTO DE LOS DESEMBOLSOS QUE SE REVERSARON CON TRANSACCION REV (-tr_secuencial)
         select @w_monto_cap_des_rv = isnull(sum(dtr_monto), 0) - @w_monto_cap_des_rv_ini
         from   ca_transaccion, ca_det_trn
         where  tr_operacion = @w_operacionca
         and    tr_secuencial >= @w_secuencial_retro
         and    tr_tran       = 'DES'
         and    tr_estado     = 'RV'
         and    dtr_operacion = tr_operacion
         and    dtr_secuencial = -tr_secuencial
         and    dtr_concepto   = 'CAP'
         and    dtr_codvalor   in (10000, 10010, 10020, 10030,10040)
         
         select @w_monto_cap_crc_rv = isnull(sum(dtr_monto), 0) - @w_monto_cap_crc_rv_ini
         from   ca_transaccion, ca_det_trn
         where  tr_operacion = @w_operacionca
         and    tr_secuencial >= @w_secuencial_retro
         and    tr_tran       = 'CRC'
         and    tr_estado     = 'RV'
         and    dtr_operacion = tr_operacion
         and    dtr_secuencial = -tr_secuencial
         and    dtr_concepto   = 'CAP'
         and    dtr_codvalor   in (10000, 10010, 10020, 10030,10040)
            
      
      /* ACTUALIZACION SALDO FONDO DE RECURSOS POR DESEMBOLSO REVERSADO */
      if @i_operacion = 'R' and @w_tran = 'DES'
      begin
         select @w_monto_cap_des_rv = isnull(sum(dtr_monto), 0) 
         from   ca_transaccion, ca_det_trn
         where  tr_operacion = @w_operacionca
         and    tr_secuencial >= @w_secuencial_retro
         and    tr_tran       = 'DES'
         and    tr_estado     = 'RV'
         and    dtr_operacion = tr_operacion
         and    dtr_secuencial = tr_secuencial
         and    dtr_concepto   in (select cp_producto from ca_producto where cp_desembolso  = 'S')
            
         select 
         @w_monto_cap = @w_monto_cap_des_rv,
         @w_operacion = 'D'
      end
   
      if @i_operacion = 'R' and @w_tran = 'PAG'
      begin
         select @w_monto_cap_pag_rv = isnull(sum(dtr_monto), 0)
         from   ca_transaccion, ca_det_trn
         where  tr_operacion   = @w_operacionca
         and    tr_secuencial  >= @w_secuencial_retro
         and    tr_tran        = 'PAG'
         and    tr_estado      = 'RV'
         and    dtr_operacion  = tr_operacion
         and    dtr_secuencial = tr_secuencial
         and    dtr_concepto   = 'CAP'
     
         select 
         @w_monto_cap = @w_monto_cap_pag_rv,
         @w_operacion = 'P'
      end
   
   
      /* ACTUALIZACION SALDO FONDO DE RECURSOS POR PAGO REVERSADO */
      if @i_operacion = 'R' and @w_tran in ('PAG', 'DES') 
      begin
   
         /* ACTUALIZACION DE SALDOS INTERFAZ PALM */
         exec @w_error  = sp_datos_palm 
         @i_operacionca = @w_operacionca, 
         @i_operacion   = @w_operacion,
         @i_monto_cap   = @w_monto_cap,
         @i_reversa     = 'S'
         
         if @w_error <> 0  
         begin
            select @w_error = @w_return
            goto ERROR
         end   
      end   

      /* Actualizar Estado de cobranza y tipo de Operacion Cuando se reestructura Req 246*/
      if @i_operacion = 'R' begin 
         if @w_tran = 'RES' begin
            update ca_operacion
            set op_toperacion  = @w_toperacion_ant,
            op_estado_cobranza = @w_estado_cobran_ant
            where op_operacion = @w_operacionca
      
            if @@rowcount = 0 begin
               select @w_error = 710578
               goto ERROR
            end
         end

         if @w_tran = 'DES' begin
            select @w_banco_hija = op_banco
            from ca_op_reest_padre_hija, ca_operacion
            where ph_op_hija   = @w_operacionca
            and   op_operacion = @w_operacionca
         
            if @w_banco_hija is not null begin
               update ca_operacion
               set op_estado     = @w_est_anulado,
                   op_comentario = op_comentario + '- Operacion Anulada por reversa de restrucracion de la Operacion Padre: ' + cast( @i_banco as varchar)
               where op_operacion = @w_operacionca
      
               if @@rowcount = 0 begin
                  select @w_error = 701195 
                  goto ERROR
               end

               --ELIMINA RELACION PADRE - HIJA
               delete ca_op_reest_padre_hija
               where ph_op_hija   = @w_operacionca
      
               if @@rowcount = 0 begin
                  select @w_error = 701195 
                  goto ERROR
               end       
            end
         end                  
      end   
  
      -- BORRAR DATOS EN TABLA PARA SIPLA
      if @w_tran in ('PAG', 'CON') 
      begin
         exec @w_error = sp_interfaz_otros_modulos
         @s_user         = @s_user,
         @i_cliente      = 0,
         @i_modulo       = 'CCA',
         @i_interfaz     = 'S',
         @i_modo         = 'D',
         @i_obligacion   = @i_banco,
         @i_moneda       = 0,
         @i_sec_trn      = @i_secuencial,
         @i_fecha_trn    = '',
         @i_desc_trn     = '',
         @i_monto_trn    = 0,
         @i_gerente      = @s_user,
         @i_cotizacion   = 0,
         @i_categoria    = @w_categoria
         
         if @w_error <> 0 
         begin
            goto ERROR
         end
      end  ---PAG
        
      ---BORRAR REGISTRO DE ABONO VOLUNTARIO INGRESADO POR REVERSO O FECHA VALOR 
      if @i_operacion = 'F' 
      begin
         if exists (select 1
         from   ca_abonos_voluntarios
         where  av_operacion_activa = @w_operacionca
         and    av_secuencial_pag   >= @w_secuencial_retro) 
         begin   
            update  ca_abonos_voluntarios
            set   av_estado_registro = 'F' --de fecha valor
            where av_operacion_activa = @w_operacionca
            and   av_secuencial_pag   >= @w_secuencial_retro
         end
      end
      if @i_operacion = 'R' 
      begin
         if exists (select 1
         from   ca_abonos_voluntarios
         where  av_operacion_activa = @w_operacionca
         and    av_secuencial_pag   >= @w_secuencial_retro) 
         begin   
            update  ca_abonos_voluntarios
            set   av_estado_registro = 'R' --de Reversos
            where av_operacion_activa = @w_operacionca
            and   av_secuencial_pag   >= @w_secuencial_retro
         end
      end
      -- ELIMINAR REGISTROS EN CASO DE REVERSO O FECHA VALOR
      if exists(select 1 from ca_abono_rubro
      where ar_secuencial >= @w_secuencial_retro
      and ar_operacion  = @w_operacionca)
      begin
         delete ca_abono_rubro
         where ar_secuencial >= @w_secuencial_retro
         and ar_operacion    = @w_operacionca
      end
 
      if exists (select 1
      from   ca_pasivas_cobro_juridico
      where  pcj_operacion = @w_operacionca) 
      begin
         delete ca_pasivas_cobro_juridico
         where pcj_operacion = @w_operacionca
      end
      
      --SI HAY REVERSO  DEL DESEMBOLSO ELIMINAN LOS REGISTROS 
      --DE DISTRIBUCION DE GARANTIAS PARA ESTE TRAMITE
      if @i_operacion = 'R' and  @w_tran = 'DES' 
      begin
         if exists(select 1
         from   ca_seguros_base_garantia
         where  sg_tramite = @w_tramite) 
         begin
            delete ca_seguros_base_garantia
            where sg_tramite = @w_tramite
         end
      end
      
      -- REVERSA DE TRASLADO DE CARTERA
      if @w_tran = 'TCO' and  @i_operacion = 'R' 
      begin
         if exists (select 1  from   ca_traslados_cartera
         where  trc_secuencial_trn = @w_secuencial_retro
         and    trc_cliente       = @w_cliente
         and    trc_operacion     = @w_operacionca)
         begin
            delete ca_traslados_cartera
            where  trc_secuencial_trn = @w_secuencial_retro
            and    trc_cliente       = @w_cliente
            and    trc_operacion     = @w_operacionca      
         end
      end

      ---PARA LAS FECHA VALOR HAY QUE VEFIFICARSE QUE EL PAGO DE RECONOCIMIENTO 
      ---ESTE REALMENTE REVERSADO CASO CONTRARIO NO DEBERIA ACTIVAR LA GARANTIA
      ---CASO REPORTADO EN LA INC 113501 
      if @i_operacion = 'F'
      begin
	      select @w_activar_garantia  = 'S' ---113501
	      if exists(select  1 from ca_abono,ca_abono_det
	               where  ab_operacion       = @w_operacionca
	               and    ab_operacion       = abd_operacion
	               and    ab_secuencial_ing  = abd_secuencial_ing
	               and    abd_concepto in (@w_fp_fng,@w_fp_usaid)
	               and    ab_estado      = 'A'
	               )
	               select @w_activar_garantia  = 'N' ---113501 por que el pago esta aun vivo
       end
        
      if (@i_operacion = 'F' and @w_numero_pagos > 0)
      or (@i_operacion = 'R' and @w_tran in ('PAG', 'DES', 'PRE', 'CAN', 'PRN', 'CON'))
      begin
         if @i_operacion = 'F'
         begin
            select 
            @w_opcion_gar = 'D',
            @w_modo_gar   = 2
         end
         
         if @i_en_linea = 'N'
            select @w_bandera_be = 'S'
         else
            select @w_bandera_be = 'N'
         
         ---SI LA OBLIGACION NO TIENE RECONOCIMIENTO SE REALIZA ACTIVACION DE GARANTIA, EN CASO DE
         ---TENER RECONOCIMIENTO ESTA LOGICA LA REALIZA EL PROCEDIMIENTO sp_pagxreco
               
         if (
                 (@w_tiene_reco <> 'S'  and @i_operacion = 'R') 
              or ( @i_operacion = 'F' and  @w_activar_garantia = 'S' and @w_tiene_reco <> 'S')
               )
         begin
            ---113501
            exec @w_error = cob_custodia..sp_activar_garantia
            @i_opcion         = @w_opcion_gar,
            @i_tramite        = @w_tramite,
            @i_modo           = @w_modo_gar,
            @s_date           = @s_date,
            @i_operacion      = 'I',
            @s_user           = @s_user,
            @s_term           = @s_term,
            @s_ofi            = @s_ofi ,
            @i_banderafe      = 'N',
            @i_bandera_be     = @w_bandera_be
         
            if @@error <> 0 or @@trancount = 0 
            begin
               select @w_error = 710522
               goto ERROR
            end
         
            if @w_error <> 0 
            begin
               goto ERROR
            end
         end
      end
      --- 113501
      /* SI ES FECHA VALOR Y LA OPERACION TIENE RECONOCIMIENTO REVERSA CADA UNO DE LOS PAGOS */
      if ( @i_operacion = 'F' and @w_tiene_reco = 'S' and @w_activar_garantia = 'S')
      begin
         select tr_secuencial,'N' procesado
         into #reco
         from ca_transaccion with (nolock)
         where tr_operacion = @w_operacionca
         and   tr_estado <> 'RV'
         and   tr_tran = 'PAG'
         and   tr_secuencial >= @w_secuencial_retro

         while 1=1
         begin
            set rowcount 1
            select @sec_pag_rec = tr_secuencial
            from #reco
            where procesado = 'N'

            if @@rowcount = 0
            begin
               set rowcount 0
               break
            end
            set rowcount 0

            -- REALIZA REVERSION DEL RECONOCIMIENTO EN CASO QUE EXISTA
            exec @w_error = sp_pagxreco
	             @s_user             = @s_user,
	             @s_term             = @s_term,
	             @s_date             = @s_date,
                 @i_tipo_oper        = 'R',
                 @i_operacionca      = @w_operacionca,
                 @i_secuencial_pag   = @sec_pag_rec

            if @w_error <> 0 return @w_error

            update #reco
            set procesado = 'S'
            where tr_secuencial = @sec_pag_rec
         end
         set rowcount 0
      end

            
      ---113501
         
      if @w_tran  = 'PAG' 
      begin
         --- REVERSAR INTANT  EN TABLA DE AMORTIZACION_ANT y CONTROL
         if exists (select 1
         from   ca_amortizacion_ant
         where  an_secuencial >= @w_secuencial_retro
         and    an_operacion  = @w_operacionca) 
         begin
            delete ca_amortizacion_ant
            where  an_secuencial >= @w_secuencial_retro
            and    an_operacion  = @w_operacionca 
         end
         
         if exists(select 1
         from   ca_control_intant
         where  con_operacion = @w_operacionca
         and    con_secuencia_pag  >= @w_secuencial_retro) 
         begin
            delete ca_control_intant
            where  con_operacion = @w_operacionca
            and    con_secuencia_pag  >= @w_secuencial_retro
         end
      end -- PAG
   
      ---22120 LA tasa almacenada en ca_ultima_tasa_op debe ser la ULTIMA TASA PACTADA CON EL CLIENTE
      ---O LA ULTIMA TASA INGRESADA POR UN REAJUSTE QUE NO SEA LIMINTE DE USURA
      ---POR ESO CON FECHA VALOR SE DEBE ELIMINAR PARA QUE SE BUSQUE LA CORRECTA AL
      ---HACER LA VALIDACION DE LIMITE DE USURA en cambibc.sp
      ---PERO SI NO HAY DONDE BUSCARLA MEJOR NO SE ELIMINA POR QUE EL MANEJO CON HISTORICOS NO ES
      ---FACIL. Y SE DEJA LA QUE ESTE QUE DEBERIA SER LA PACTADA EN EL DESEBOLSO O LA MIGRACION
         
      select @w_fecha_ult_proceso = op_fecha_ult_proceso
      from ca_operacion
      where op_operacion = @w_operacionca
      
      if exists (select 1 from 
      ca_reajuste with (nolock),
      ca_reajuste_det with (nolock)
      where re_operacion = @w_operacionca
      and red_operacion  =  @w_operacionca
      and re_secuencial = red_secuencial
      and   re_fecha <= @w_fecha_ult_proceso
      and    isnull(red_referencial,'') not in ('TLU','TLU1','TLU2','TLU3','TLU4','TMM')
      )
      begin              
         delete ca_ultima_tasa_op         
         where ut_operacion = @w_operacionca   
      end
      ---22120   
         
      --XMA COMMIT TRAN
      
      if @w_commit = 'S' 
      begin
         commit tran
         select @w_commit = 'N'
      end
   
   end  --fin de @i_fecha_valor < @w_fecha_ult_p

   -- NYM 7x24 Ingresamos o actualizamos registro en fecha valor baja intensidad como control para que no se ejecute en batch1
   if  @i_fecha_valor < @w_fecha_ult_p 
   begin   
      if exists(select 1 
      from   cob_cartera..ca_en_fecha_valor
      where  bi_operacion = @w_operacionca) 
      begin
         update   ca_en_fecha_valor set      
         bi_fecha_valor = @i_fecha_valor,
         bi_user        = @s_user
         where    bi_operacion   = @w_operacionca
   
         if @@error <> 0 
         begin
            select @w_error = 710002  -- falta error
            goto ERROR
         end
   
      end
      else 
      begin
         insert into ca_en_fecha_valor
         (
         bi_operacion,   bi_banco,   bi_fecha_valor, 
         bi_user
         )
         values   
         (
         @w_operacionca, @i_banco,   @i_fecha_valor,  
         @s_user
         )
         
         if @@error <> 0 
         begin
            select @w_error = 710002 -- falta error
            goto ERROR
         end
      end
   end

   if @i_operacion = 'R'
      if @w_fecha_ult_p > @s_date
         select @i_fecha_valor = @w_fecha_ult_p
      else
         select @i_fecha_valor = @s_date
      
   if @i_susp_causacion = 'N' --Para no ejecutar el batch por suspencion de causacion(casuspe.sp)   
      select @w_es_liq = 'S'
   
   ---ACTUALIZAR PAGOS COMO NO APLICADOS
   
   update ca_abono
   set ab_nro_recibo = -999 
   from ca_abono, ca_abono_det
   where ab_operacion = @w_operacionca
   and   abd_operacion = @w_operacionca
   and abd_operacion = ab_operacion
   and abd_secuencial_ing = ab_secuencial_ing
   and ab_estado = 'NA'
   and abd_concepto = @w_par_fpago_depogar
      
   if @@error <> 0 
   begin
      select @w_error = 710002
      goto ERROR
   end
   
   -- LLEVAR A LA OPERACION A LA FECHA DE PROCESO
   if @w_es_liq = 'N'  and  @i_operacion <> 'R' 
   begin
      select @w_fecha_ult_p = op_fecha_ult_proceso
      from   ca_operacion
      where  op_banco = @i_banco
      
      if  @w_fecha_ult_p  <= @i_fecha_valor and  @i_secuencial_hfm = 0 
      begin
      
         if @i_debug = 'S'
         begin 
            if @i_pago_ext = 'N'
               print 'FECHA VALOR ADELANTE'
         end
            
         exec @w_error = sp_batch
         @s_user                = @s_user,
         @s_term                = @s_term,
         @s_date                = @s_date,
         @s_ofi                 = @s_ofi,
         @i_en_linea            = @i_en_linea,
         @i_banco               = @i_banco,
         @i_siguiente_dia       = @i_fecha_valor,
         @i_aplicar_clausula    = @w_aplicar_clausula,
         @i_aplicar_fecha_valor = 'S',
         @i_modo                = 'F',
         @i_control_fecha       = @i_control_fecha,
         @i_debug               = @i_debug
         
         if @w_error <> 0  
         begin
            goto ERROR
         end
      end
   end
   
   update ca_operacion
   set op_validacion = null
   where op_banco = @i_banco

   --PARA ASEGURAR LA EXISTENCIA DE LA OBLIGACION AL REALIZAR TRANSACCION DE R o F  
   if not exists(select 1
   from ca_operacion
   where op_operacion = @w_operacionca)
   begin
      select @w_error = 701049
      goto ERROR
   end
   
   --PARA ASEGURAR LA CONSISTENCIA DE LOS DATOS
   select @w_estado_op = op_estado
   from   ca_operacion
   where  op_banco = @i_banco
   
   if @w_estado_op <> 0 
   begin
      if not exists (select 1
      from   ca_dividendo
      where  di_operacion = @w_operacionca 
      and    di_estado not in (0,3))
      and    not (@w_banco_hija is not null and @w_tran = 'DES')
      begin
         select @w_error = 710575
         goto ERROR
      end
   end

   if @w_transaccion_pag = 'S' 
   begin -- SE REVIRTIO UNA TRANSACCION DE PAGO
      if @w_secuencial_pag = -1 or @w_secuencial_pag = -1 
      begin
         select @w_error = 710541
         goto ERROR
      end
      
      if exists(select 1
      from   ca_transaccion
      where  tr_operacion  = @w_operacionca
      and    tr_secuencial = @w_secuencial_rpa
      and    tr_estado     <> 'RV')
      begin
         select @w_error = 710541
         goto ERROR
      end
      
      if exists(select 1
      from   ca_transaccion
      where  tr_operacion  = @w_operacionca
      and    tr_secuencial = @w_secuencial_pag
      and    tr_estado     <> 'RV')
      begin
         select @w_error = 710543
         goto ERROR
      end
   end

   if  @w_op_naturaleza =  'A' and @w_tipo <> 'G'
   begin
        exec sp_revisa_otros_rubros 
        @i_operacion  = @w_operacionca,
        @i_fechaval   = 'S'
   end
        
   ---LOG fecha valor
   if @w_secuencial_retro  is null
      select @w_secuencial_retro = 0
     
   insert ca_log_fecha_valor  
   values (@w_operacionca,@w_secuencial_retro, @i_operacion, @i_fecha_valor, 'N', @s_user, getdate() )
   ---Inc 24225 
   /*REQ 0272 NUEVA GARANTIA FNG */

   if exists(select top 1 1 from ca_operacion
             where op_estado in(1,2,4,9)
             and   op_operacion <> @w_operacionca
             and   op_cliente = @w_cliente)
   begin
      update cobis..cl_ente
	  set en_bancarizado = 'I'
	  where en_ente  = @w_cliente
		
	  if @@error <> 0 begin
         select @w_error = 710001
         goto ERROR
	  end
   end    
   else
   begin
      update cobis..cl_ente
	  set en_bancarizado = 'N'
	  where en_ente  = @w_cliente
		
	  if @@error <> 0 begin
	     select @w_error = 710001
	     goto ERROR
	  end
   end
   
   return 0

ERROR:

   if @w_commit = 'S' 
   begin
      rollback tran
      select @w_commit = 'N'
   end
   
   
   if @w_error = 0 -- ESTA SALIDA SOLO FUE PARA ADVERTIR ALGO Y CERRAR LA TRANSACCION
   begin
      insert ca_log_fecha_valor  
       values (@w_operacionca,@w_secuencial_retro, @i_operacion, @i_fecha_valor, 'N', @s_user, getdate() )   
      return 0
   end   
   
   if @w_error = 701049 
   begin
      begin tran 
      
      insert into ca_errorlog
      (
      er_fecha_proc,      er_error,      er_usuario,
      er_tran,            er_cuenta,     er_descripcion
      )
      values
      (
      @s_date,            @w_error,      @s_user,
      7269,               @i_banco,      'SEGUIMIENTO' 
      ) 
      commit tran
   end
   
   if @i_pago_ext = 'N'
   begin                 
      if @i_en_linea  = 'S' 
      begin
         exec cobis..sp_cerror
         @t_debug = 'N',
         @t_from  = @w_sp_name,
         @i_num   = @w_error  
         return @w_error
      end
      else
         return @w_error
   end

   insert ca_log_fecha_valor  
   values (@w_operacionca,@w_secuencial_retro, @i_operacion, @i_fecha_valor, 'N', @s_user, getdate() )
      
   if @i_pago_ext = 'S'
      return @w_error                 
go
