use cob_cartera
go
/************************************************************************/
/*      Archivo:                sp_grupo_pag_apl.sp                     */
/*      Stored procedure:       sp_grupo_pag_apl                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           LGU                                     */
/*      Fecha de escritura:     Abr. 2017                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Recuperar y Aplicar los pagos que llegan del banco              */
/*      aplicar fecha valor                                             */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR             RAZON                         */
/* 19-Abr-2017          LGU          Emision inicial                    */
/* 20/10/2021      G. Fernandez      Ingreso de nuevo campo de          */
/*                                   solidario en ca_abono_det          */
/************************************************************************/

if exists (select 1 from sysobjects where name = 'sp_grupo_pag_apl')
    drop proc sp_grupo_pag_apl
go

create proc sp_grupo_pag_apl(
-- parametros del bacth
   @i_param1           varchar(255)  = null, -- opcion
   @i_param2           varchar(255)  = null, -- fecha proceso
   @i_param3           varchar(255)  = null, -- nombre archivo
-- parametros del bacth

   @i_opcion               char(10) = null, -- I = Ingresar E = envio  R = recepcion A = aplicar , T = para insertar en tabla temporal , B = BCP
   @i_fecha_proceso        datetime = null,
   @i_archivo              varchar(255)  = null,
   @i_modo                 tinyint  = 9,  --aplica solo para la opcion T
   @s_user                 login    = 'pag-grp',
   @i_fecha_envio          datetime = null,
   @i_identificacion       char(24) = null,
   @i_tipo_identificacion  char(10) = null,
   @i_numero_cta_debito    char(16) = null,
   @i_cuenta_expediente    char(13) = null,
   @i_referencia_grupal   char(15) = null,
   @i_operacionca          int      = null,
   @i_banco                char(16) = null,
   @i_valor_debitar        money    = null,
   @i_valor_debitado       money    = null,
   @i_estado               char(1)  = null,
   @i_tipo_pago            char(10)  = null,
   @i_transaccion_id       varchar(64) = null
   )
as
declare
   @w_hora              char(6),
   @w_est_ing           char(1),
   @w_est_env           char(1),
   @w_est_rcp           char(1),
   @w_est_apl           char(1),
   @w_return            int,
   @w_term              catalogo,
   @w_error             int,
   @w_sp_name           varchar(64),
   @w_banco             cuenta,
   @w_msg               varchar(255),
   @w_secuencial        int,
   @w_numero_recibo     int,
   @w_cuota_completa    char(1),
   @w_aceptar_anticipos char(1),
   @w_prep_desde_lavig  char(1),
   @w_moneda            tinyint,
   @w_cotizacion_mpg    money,
   @w_cotizacion_hoy    money,
   @w_moneda_nacional   smallint,
   @w_oficina           smallint,
   @w_tipo_cobro        char(1),
   @w_sec_ing           int,
   @w_secuencial_new    int,
   @w_parametro_freverso catalogo,
   @w_tipo_reduccion     catalogo,
   @w_forma_pago         catalogo,
   @w_num_cta            varchar(32),
   @w_fecha_pago         datetime,
   @w_valor_debitado     money,
   @w_dividendo          smallint,
   @w_transaccion_id     varchar(65),
   @w_entidad            varchar(10),
   @w_estado_reg         varchar(10),
   @w_secuencial_ing     int,


   /*******************************/
   @w_path_sapp  varchar(200),
   @w_sapp       varchar(200),
   @w_path       varchar(200),
   @w_comando    varchar(2000),
   @w_bd         varchar(200),
   @w_tabla      varchar(200),
   @w_destino    varchar(200),
   @w_errores    varchar(200),
   @w_sep        varchar(1),
   @w_fecha_arch varchar(10),
   @w_descripcion varchar(100),
   @w_fecha_archivo   datetime,
   @w_operacionca int,
   @w_reg_subidos int,
   @w_reg_est_env int,
   @w_reg_upd     int

select
   @i_opcion           = @i_param1,
   @i_fecha_proceso    = convert(datetime, @i_param2, 101),
   @i_archivo          = isnull(@i_param3, 'CBRPRESTGRUPAL')


select
   @w_est_ing = 'I',
   @w_est_env = 'E',
   @w_est_rcp = 'R',
   @w_est_apl = 'A',

   @w_sp_name = 'sp_grupo_pag_apl'

if @i_opcion = 'A' -- Aplicacion del pago
begin
   -- CODIGO DE LA MONEDA LOCAL
   select @w_moneda_nacional = pa_tinyint
   from   cobis..cl_parametro with (nolock)
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'MLO'
   --select @w_rowcount = @@rowcount

   --if @w_rowcount = 0 begin
   if @@rowcount = 0 begin
      select @w_descripcion = 'Error no hay cotizacion par aplicar los pagos'
      select @w_return = 708174
      goto ERROR
   end

   select
   @w_term              = 'BATCH_GRUPAL'

   declare cur_1 cursor for select
      pa_fecha_envio       ,pa_operacion         ,pa_banco       ,
      pa_transaccion_id    ,pa_entidad           ,pa_numero_cta_debito    ,
      pa_valor_debitado    ,pa_dividendo         ,pa_fecha_ven,
      pa_estado            ,pa_secuencial_ing
   from ca_pago_grp_apl
   where isnull(pa_valor_debitado,0) > 0
   --///////////////////////////////////////////////////////////////////////////////
   and pa_estado    = @w_est_rcp -- R=recuperados o recibidos
   and pa_tipo_pago = 'N'        -- N=PAGO NORMAL = se aplica para cada prestamo que llega
   --///////////////////////////////////////////////////////////////////////////////
   order by pa_operacion asc , pa_fecha_envio asc
   FOR UPDATE OF
         pa_estado ,
         pa_secuencial_ing;

   open cur_1
   fetch cur_1 into @w_fecha_archivo  ,@w_operacionca, @w_banco,
                    @w_transaccion_id ,@w_entidad    , @w_num_cta  ,
                    @w_valor_debitado ,@w_dividendo  , @w_fecha_pago,
                    @w_estado_reg     ,@w_secuencial_ing

   while @@FETCH_STATUS = 0
   begin
      select
         @w_moneda                  = op_moneda,
         @w_cuota_completa          = op_cuota_completa,
         @w_aceptar_anticipos       = op_aceptar_anticipos,
         @w_tipo_cobro              = op_tipo_cobro,
         @w_prep_desde_lavig        = op_prepago_desde_lavigente,
         @w_tipo_reduccion          = op_tipo_reduccion,
         @w_oficina                 = op_oficina
      from  ca_operacion, ca_estado
      where op_banco             = @w_banco
      and   op_estado            = es_codigo
      and   es_acepta_pago       = 'S'

      select @w_forma_pago = isnull(@w_forma_pago,'NDAH')

      ---  DETERMINAR EL VALOR DE COTIZACION DEL DIA / MONEDA OPERACION
      if @w_moneda = @w_moneda_nacional
         select @w_cotizacion_hoy = 1.0
      else begin
         exec sp_buscar_cotizacion
         @i_moneda     = @w_moneda,
         @i_fecha      = @w_fecha_pago,
         @o_cotizacion = @w_cotizacion_hoy output
      end

      ---  GENERAR EL SECUENCIAL DE INGRESO
      exec @w_secuencial = sp_gen_sec
      @i_operacion       = @w_operacionca

      if @w_secuencial  =  0  or @w_secuencial is null
      begin
         select @w_msg = 'ERROR GENERANDO SECUENCIAL PAGO ' + CAST( @w_banco AS VARCHAR)
         goto ERROR_PAG
      end

      ---  INSERTAR PRIORIDADES
      insert into ca_abono_prioridad
      (ap_secuencial_ing, ap_operacion, ap_concepto, ap_prioridad)
      select @w_secuencial, @w_operacionca, ro_concepto, ro_prioridad
      from   ca_rubro_op
      where  ro_operacion = @w_operacionca
      and    ro_fpago not in ('L','B')
      select @w_error = @@error
      if @w_error <> 0  begin
         select @w_msg = 'ERROR INSERTANDO PRIORIDAD  ' + CAST( @w_banco AS VARCHAR)
         goto ERROR_PAG
      end

      ---  INSERCION DE CA_DET_ABONO
      insert into ca_abono_det
      (
      abd_secuencial_ing,    abd_operacion,         abd_tipo,
      abd_concepto,          abd_cuenta,            abd_beneficiario,
      abd_monto_mpg,         abd_monto_mop,         abd_monto_mn,
      abd_cotizacion_mpg,    abd_cotizacion_mop,    abd_moneda,
      abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,
      abd_cod_banco,         abd_solidario                            --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
      )
      values
      (
      @w_secuencial,         @w_operacionca,        'PAG',
      @w_forma_pago,         @w_num_cta,            'TRX:'+@w_transaccion_id + ';' + @w_entidad     ,
      @w_valor_debitado,     @w_valor_debitado,     @w_valor_debitado*@w_cotizacion_hoy,
      @w_cotizacion_hoy,     @w_cotizacion_hoy,     @w_moneda,
      'N',                   'N',                   0,
      '',                    'N'
      )
      select @w_error = @@error
      if @w_error <> 0  begin
         select @w_msg = 'ERROR INSERTARNDO ABONO DETALLE ' + CAST( @w_banco AS VARCHAR)
         goto ERROR_PAG
      end

      ---GENERAL NRO. RECIBO
      exec @w_error  = sp_numero_recibo
      @i_tipo    = 'P',
      @i_oficina = @w_oficina,
      @o_numero  = @w_numero_recibo out

      if @w_error  <> 0
       begin
         select @w_msg = 'ERROR GENERANDO SECUENCIAL DEL RECIBO DE PAGO ' + CAST( @w_secuencial AS VARCHAR)
         goto ERROR_PAG
      end

      ---  INSERCION DE CA_ABONO
      insert into ca_abono
      (
      ab_operacion,          ab_fecha_ing,          ab_fecha_pag,
      ab_cuota_completa,     ab_aceptar_anticipos,  ab_tipo_reduccion,
      ab_tipo_cobro,         ab_dias_retencion_ini, ab_dias_retencion,
      ab_estado,             ab_secuencial_ing,     ab_secuencial_rpa,
      ab_secuencial_pag,     ab_usuario,            ab_terminal,
      ab_tipo,               ab_oficina,            ab_tipo_aplicacion,
      ab_nro_recibo,         ab_tasa_prepago,       ab_dividendo,
      ab_prepago_desde_lavigente
      )
      values
      (
      @w_operacionca,        @w_fecha_pago,         @w_fecha_pago,
      @w_cuota_completa,     @w_aceptar_anticipos,  @w_tipo_reduccion,
      @w_tipo_cobro,         0,                     0,
      'ING',                 @w_secuencial,         0,
      0,                     @s_user,               @w_term,
      'PAG',                 @w_oficina,            'C',
      @w_numero_recibo,      0,                     @w_dividendo,
      @w_prep_desde_lavig
      )

      select @w_error = @@error
      if @w_error <> 0  begin
         select @w_msg = 'ERROR INSERTARNDO ABONO ' + CAST(  @w_banco AS VARCHAR)
         goto ERROR_PAG
      end


   goto SIGUIENTE

ERROR_PAG:
         begin
            if @w_error is null or @w_error = 0
               select @w_error = 710001
            print ''
            print ''
            print  @w_msg
            print ''
            print ''

            exec sp_errorlog
            @i_fecha       = @i_fecha_proceso,
            @i_error       = @w_error,
            @i_usuario     = @s_user,
            @i_tran        = 7998,
            @i_tran_name   = @w_sp_name,
            @i_cuenta      = @w_banco,
            @i_descripcion = @w_msg,
            @i_rollback    = 'N'

            select @w_error = 0

            goto SIGUIENTE
         end

SIGUIENTE:

      -- Actualizo el estado y el secuencial_ing del pago
      update ca_pago_grp_apl set
         pa_estado = @w_est_apl,
         pa_secuencial_ing = @w_secuencial
      WHERE CURRENT OF cur_1



      fetch cur_1 into @w_fecha_archivo  ,@w_operacionca, @w_banco,
                       @w_transaccion_id ,@w_entidad    , @w_num_cta  ,
                       @w_valor_debitado ,@w_dividendo  , @w_fecha_pago,
                       @w_estado_reg     ,@w_secuencial_ing
   end -- while
   close cur_1
   deallocate cur_1

   return 0
end

--///////////////////////////////////////////////////////////////////////////////////////////////
if @i_opcion = 'T' -- Grabar los pagos en Temporal para luego pasar a la definitiva: INSERT
begin
   if @i_modo = 0
   begin
      truncate table tmp_pago_grupal
   end
   else
   begin
      insert into tmp_pago_grupal (
            pt_fecha_proceso     ,pt_fecha_envio       ,pt_identificacion     ,pt_tipo_identificacion ,
            pt_numero_cta_debito ,pt_cuenta_expediente ,pt_referencia_grupal  ,pt_operacion  ,
            pt_banco             ,pt_valor_debitar     ,pt_valor_debitado     ,pt_estado ,
            pt_tipo_pago         ,pt_transaccion_id)
      values (
            @i_fecha_proceso     ,@i_fecha_envio       ,@i_identificacion     ,@i_tipo_identificacion ,
            @i_numero_cta_debito ,@i_cuenta_expediente ,@i_referencia_grupal  ,@i_operacionca  ,
            @i_banco             ,@i_valor_debitar     ,@i_valor_debitado     ,@i_estado ,
            @i_tipo_pago         ,@i_transaccion_id)

      if @@error != 0
      begin
         select @w_msg = 'ERROR AL INSERTAR'
         select @w_return = 724608
         print ' Error al insertar en temporales los pagos recibidos ' + convert (varchar, @w_return)
         return @w_return
      end
   end -- else if @i_modo = 0
end  -- opcion T
--///////////////////////////////////////////////////////////////////////////////////////////////
if @i_opcion = 'B' -- Grabar los pagos en Temporal para luego pasar a la definitiva: BCP
begin
   select @w_path_sapp = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'S_APP'

   if @w_path_sapp is null
   begin
      select @w_msg = 'NO EXISTE PARAMETRO GENERAL S_APP'
      select @w_return = 724607
      goto ERROR
    end

   select @w_path  = pp_path_destino
   from cobis..ba_path_pro
   where pp_producto  = 7

   select @w_sapp      = @w_path_sapp + 's_app'

   select
      @w_bd       = 'cob_cartera',
      @w_tabla    = 'tmp_pago_grupal',
      @w_sep      = '|' --char(9)  -- tabulador

   select @w_fecha_arch = convert(varchar, @i_fecha_proceso, 112)
   select @w_hora = substring(convert(varchar, getdate(), 108), 1,2)+
                    substring(convert(varchar, getdate(), 108), 4,2)+
                    substring(convert(varchar, getdate(), 108), 7,2)

   truncate table tmp_pago_grupal

   select
      @w_destino  = @i_archivo + '_' + @w_fecha_arch + '.txt',
      @w_errores  = @i_archivo + '_' + @w_fecha_arch + '_' + @w_hora + '.err'

   select  @w_comando = @w_sapp + ' bcp -auto -login ' + @w_bd + '..' + @w_tabla + ' in ' + @w_path+@w_destino + ' -b5000 -c -e' + @w_path+@w_errores + ' -t"'+@w_sep + '" -config ' + @w_sapp + '.ini'

   print ' COMANDO = '+ @w_comando
   exec @w_return = xp_cmdshell @w_comando
   if @w_return <> 0 begin
      select @w_msg = 'ERROR AL GENERAR ARCHIVO '+@w_destino+ ' '+ convert(varchar, @w_return)
      goto ERROR
   end

   select @i_opcion = 'R'
end  -- opcion B
--///////////////////////////////////////////////////////////////////////////////////////////////
if @i_opcion = 'R' -- Recuperar los pagos
begin
   select @w_reg_subidos = count(1) from tmp_pago_grupal
   select @w_reg_est_env = count(1) from tmp_pago_grupal where pt_estado = @w_est_env

   --- pasar a la tabla de pagos definitiva
   if @w_reg_subidos = @w_reg_est_env
   begin
      insert into ca_pago_grp_apl (
         pa_fecha_proceso       ,  pa_fecha_envio         ,  pa_identificacion  ,
         pa_tipo_identificacion ,  pa_numero_cta_debito   ,  pa_operacion       ,
         pa_banco               ,  pa_valor_debitar       ,  pa_valor_debitado  ,
         pa_cuenta_expediente   ,  pa_referencia_grupal   ,  pa_estado          ,

         pa_grupo               ,  pa_dividendo           ,  pa_fecha_ven       ,
         pa_cliente             ,  pa_tipo_pago           ,  pa_transaccion_id  ,
         pa_entidad             ,  pa_secuencial_ing)
      select
         pt_fecha_proceso       ,  pt_fecha_envio         ,  pt_identificacion  ,
         pt_tipo_identificacion ,  pt_numero_cta_debito   ,  pt_operacion       ,
         pt_banco               ,  pt_valor_debitar       ,  pt_valor_debitado  ,
         pt_cuenta_expediente   ,  pt_referencia_grupal   ,  @w_est_rcp         ,
         pe_grupo               ,  pe_dividendo           ,  pe_fecha_ven       ,
         pe_cliente             ,  pe_tipo_pago           ,  pt_transaccion_id  ,
         pt_entidad             ,  0
      from cob_cartera..tmp_pago_grupal, cob_cartera..ca_pago_grp_env
      where pt_fecha_envio = pe_fecha_envio
      and pt_banco         = pe_banco
      and pe_estado        = pt_estado
      and pe_estado        = @w_est_env

      select @w_reg_upd = @@rowcount

      if @w_reg_upd <> @w_reg_subidos
      begin
         select @w_msg = 'Registros cargados ' + convert(varchar, @w_reg_subidos) + ' Registros Insertados ' + convert(varchar, @w_reg_upd)
         select @w_error =  799999
         select @w_return = 0
         exec sp_errorlog
            @i_fecha      = @i_fecha_proceso,
            @i_error      = @w_error,
            @i_usuario    = @s_user,
            @i_tran       = 7888,
            @i_tran_name  = @w_sp_name,
            @i_cuenta     = @w_banco,
            @i_rollback   = 'N',
            @i_descripcion = @w_msg
      end

      update cob_cartera..ca_pago_grp_env set
         pe_estado = @w_est_rcp
      from cob_cartera..ca_pago_grp_apl
      where pa_fecha_envio = pe_fecha_envio
      and pa_banco         = pe_banco
      and pa_estado        = @w_est_rcp
      and pe_estado        = @w_est_env

   end
   else
   begin
      select @w_msg = 'existen registros cargados con estado diferente a E = enviado '
      select @w_error =  799999
      select @w_return = 0
      select @w_banco = 'TODOS_PAG-TMP'
      goto ERROR
   end

   return 0
end

return 0

ERROR:
   exec sp_errorlog
   @i_fecha      = @i_fecha_proceso,
   @i_error      = @w_error,
   @i_usuario    = @s_user,
   @i_tran       = 7888,
   @i_tran_name  = @w_sp_name,
   @i_cuenta     = @w_banco,
   @i_rollback   = 'N',
   @i_descripcion = @w_msg

   return @w_return

go


