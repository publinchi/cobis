use cob_pac
go

if exists (select 1 from sysobjects where name = 'sp_operacion_def_busin')
   drop proc sp_operacion_def_busin
go
 
CREATE PROCEDURE sp_operacion_def_busin
        @s_date              datetime    = NULL,
        @s_sesn              int         = NULL,    
        @s_ssn               int         = NULL,    
        @s_user              login       = NULL,
        @s_ofi               int         = NULL,
        @s_term              varchar(30) = NULL,
        @i_banco             cuenta      = NULL,
        @i_dest_finan        varchar(10) = NULL,
        @i_act_eco_bce       varchar(10) = NULL,
        @i_dest_hipot        varchar(10) = NULL,
        @i_dest_consumo      varchar(10) = NULL,
        @i_ruteo_paso_def    varchar(1)  = 'S'
as
declare @w_sp_name           descripcion,
        @w_return            int,
        @w_error             int,
        @w_operacionca       int,
        @w_monto             money,
        @w_moneda            tinyint,
        @w_fecha_ini         datetime,
        @w_fecha_fin         datetime,
        @w_toperacion        catalogo, 
        @w_tplazo            catalogo,
        @w_plazo             int,
        @w_tipo_producto     catalogo,
        @w_periodo_reajuste  smallint,
        @w_operacionca_tmp   int,
        @w_monto_tmanual     money,
        @w_monto_capital     money,
        @w_tipo_tabla        varchar(10),
        @w_clase_bloqueo     char(1),
        @w_tipo_bloqueo      char(1),
        @w_cta_ahorro        cuenta,
        @w_cta_certificado   cuenta,
        @w_alicuota          catalogo,
        @w_alicuota_aho      catalogo,
        @w_valor_alicuota     float,
        @w_valor_alicuota_aho float,
        @w_doble_alicuota     char(1),
        @w_op_estado          smallint,
        @w_tramite            int,
        @w_clave1             varchar(255),
        @w_fecha_ult_proceso  datetime,
        @w_est_novigente      tinyint,
        @w_est_credito        tinyint,
        @w_tipo_cca           catalogo,
        @w_actividad_destino  catalogo,
        @w_cliente            int,
        @w_vinculado          char(1),
        @w_causal_vinculacion varchar(10),
        @w_cta_actual         varchar(24),
        @w_cta_anterior       varchar(24),
        @w_clase              catalogo,
        @w_programa           varchar(40),
        @w_valor_minimo       money,
        @w_valor_maximo       money,
        @w_seg_cre            catalogo,
        @w_tea                float,
        @w_msg                   varchar(100),
        @w_periodo_reajuste_ant  smallint,
        @w_reaj_diario_ant       char(1),
        @w_reaj_diario           char(1),
        @w_calcula_reajuste      char(1),
        @w_op_activa             char(1),
        @w_reajustable           char(1),
        @w_reajustable_ant       char(1),
        @w_existe                char(1),
        @w_reg_reajuste          int,
        @w_reajuste_especial_ant char(1),
        @w_reajuste_especial     char(1),
        @w_forma_pago_ant        catalogo,
        @w_forma_pago            catalogo,
        @w_tipo                  char(1),
        @w_sector                catalogo,
        @w_actividad_sujeto      catalogo,
        @w_destino               catalogo,
        @w_tramite_tmp           int

        
-- CARGAR VALORES INICIALES
select @w_sp_name       = 'sp_operacion_def',
       @w_est_novigente = 0,
       @w_est_credito   = 99,
       @w_existe        = 'S'

--PRON:10JUL07
select @w_cta_anterior          = op_cuenta,
       @w_forma_pago_ant        = op_forma_pago,
       @w_periodo_reajuste_ant  = op_periodo_reajuste,
       --@w_reaj_diario_ant       = isnull(op_reaj_diario,'N'),
       @w_reajustable_ant       = isnull(op_reajustable,'N'),
       @w_reajuste_especial_ant = isnull(op_reajuste_especial,'N'),
       @w_tipo                  = op_tipo
from   cob_cartera..ca_operacion
where  op_banco    = @i_banco

if @@rowcount = 0
   select @w_existe = 'N'

-- DATOS DE LA OPERACION TEMPORAL
select @w_tipo_tabla         = opt_tipo_amortizacion,
       @w_operacionca_tmp    = opt_operacion,
       --@w_tipo_bloqueo       = opt_tipo_bloqueo,
       --@w_clase_bloqueo      = opt_clase_bloqueo,
       --@w_cta_ahorro         = opt_cta_ahorro,
       --@w_cta_certificado    = opt_cta_certificado,
       --@w_doble_alicuota     = opt_doble_alicuota,
       --@w_alicuota           = opt_alicuota,
       --@w_alicuota_aho       = opt_alicuota_aho,
       --@w_valor_alicuota     = opt_valor_alicuota,
       --@w_valor_alicuota_aho = opt_valor_alicuota_aho,
       @w_cliente            = opt_cliente,
       @w_forma_pago         = opt_forma_pago,
       @w_cta_actual         = opt_cuenta,
       @w_clase              = opt_clase,
       --@w_seg_cre            = opt_seg_cre,
       --@w_tipo_cca           = opt_tipo_cca,
       @w_op_estado          = opt_estado,
       @w_fecha_ini          = opt_fecha_ini,
       @w_tipo               = opt_tipo,
       @w_sector             = opt_sector,
       @w_moneda             = opt_moneda,
       @w_destino            = opt_destino,
       --@w_actividad_destino  = opt_actividad_destino,
       @w_tramite_tmp        = opt_tramite
from   cob_cartera..ca_operacion_tmp
where  opt_banco = @i_banco


--RAL 19-Ene-2017 inconsistencia con orquestacion en el flujo
if @i_ruteo_paso_def = 'S'
begin
   exec @w_return = cob_cartera..sp_ruteo_oper_sol_wf
   @s_srv             = null,
   @s_lsrv            = null,
   @s_ssn             = @s_ssn,
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_date            = @s_date,
   @s_sesn            = @s_sesn,
   @s_ofi             = @s_ofi,
   @i_banco           = @i_banco

   if @w_return != 0
   begin 
      select @w_error = @w_return
      goto ERROR
   end   
end
else
begin
--RAL 19-Ene-2017 inconsistencia con orquestacion en el flujo

    --CLL Sprint 9 VALIDA QUE LA ACTIVIDAD CORRESPONDA AL SEGMENTO DE CREDITO Y DESTINO
    if not exists (select 1 from cob_cartera..ca_seg_destino_bce
                   where sd_segmento = @w_seg_cre
                   and   sd_destino_bce  = @w_destino
                   and   (sd_act_economica_bce = @w_actividad_destino or sd_act_economica_bce = null)) 
                   and @w_tipo <> 'R'  -- NO Valida para Obligaciones Financieras
    begin
       if (@w_op_estado = @w_est_novigente) or (@w_op_estado = @w_est_credito)
       begin
          select @w_error = 710177
          goto ERROR
       end
       else
       begin
          select @w_msg = mensaje
          from   cobis..cl_errores
          where  numero = 710177
          print '[AVISO: ] Actualmente ' + @w_msg
       end
    end

    -- VALIDA LA ACTIVIDAD ECONOMICA DEL SUJETO (DEUDOR, CODEUDORES Y GARANTES)
    -- TABLA TEMPORAL
    create table #tmp_clientes_val_act
    (cliente      int,
     rol         char(10)
    )
	
	/*
    exec @w_return  = cob_cartera..sp_valida_actividad
         @s_user    = @s_user,
         @s_sesn    = @s_sesn,
         @i_tramite = @w_tramite_tmp,
         @i_tipo    = @w_tipo

    if @w_return != 0 
    begin
       if (@w_op_estado = @w_est_novigente) or (@w_op_estado = @w_est_credito)
       begin
          select @w_error = @w_return
          goto ERROR
       end
       else
       begin
          select @w_msg = mensaje
          from   cobis..cl_errores
          where  numero = @w_return
          print '[AVISO] Actualmente ' + @w_msg
       end
    end
	*/

    -- VALIDA QUE EL SEGMENTO DE CREDITO CORRESPONDA AL TIPO DE CARTERA   
    select @w_programa     = st_programa,
           @w_valor_minimo = st_valor_minimo,
           @w_valor_maximo = st_valor_maximo
    from   cob_cartera..ca_segcred_tipocca
    where  st_seg_cred = @w_seg_cre
    and    st_tipo_cca = @w_tipo_cca

    if @@rowcount = 0 and @w_tipo <> 'R'
    begin
       if (@w_op_estado = @w_est_novigente) or (@w_op_estado = @w_est_credito)
       begin
          select @w_error = 710174
          goto ERROR
       end
       else
       begin
          select @w_msg = mensaje
          from   cobis..cl_errores
          where  numero = 710174
          print '[AVISO] Actualmente ' + @w_msg
       end
    end

    /*---------------------------*/
    /* VALIDACION DE SEGMENTOS   */
    /* PRON:11OCT2007            */
    /*---------------------------*/
    if @w_programa is not null
    begin
      if not exists (select 1 from cob_cartera..sysobjects where name = @w_programa)
      begin
        select @w_error = 707075
        goto ERROR
      end
      select @w_programa = 'cob_cartera..' + @w_programa
      exec @w_return      = @w_programa 
           @i_operacionca = @w_operacionca_tmp,
           @i_monto_min   = @w_valor_minimo,
           @i_monto_max   = @w_valor_maximo,
           @i_tipo_cca    = @w_tipo_cca,     
           @i_temporal    = 'S'

      if @w_return != 0 
      begin
         if (@w_op_estado = @w_est_novigente) or (@w_op_estado = @w_est_credito)
         begin
            select @w_error = @w_return       
            goto ERROR
         end
         else
         begin
            select @w_msg = mensaje
            from   cobis..cl_errores
            where  numero = @w_return 
            print '[AVISO] Actualmente ' + @w_msg
         end
      end
    end

    if (@w_doble_alicuota = 'S' and (@w_alicuota_aho is null or @w_alicuota is null))
    begin
      select @w_error = 701177
      goto ERROR          
    end
    else 
    if (@w_doble_alicuota = 'N' and @w_alicuota is null)
    begin
      select @w_error = 701177
      goto ERROR          
    end

    -- VALIDAR CUENTAS SOLO SI @w_doble_alicuota <> 'E'   --AOL 23FEB07
    if @w_doble_alicuota <> 'E' 
    begin
       if @w_clase_bloqueo in ('C','D') and @w_cta_certificado is null begin
          select @w_error = 701178
          goto ERROR
       end
       if @w_clase_bloqueo in ('A','D') and @w_cta_ahorro is null begin
          select @w_error = 701179
          goto ERROR
       end
    end

    -- CONTROLAR QUE LA TABLA MANUAL HAYA SIDO MODIFICADA DESPUES DE LA CREACION
    if @w_tipo_tabla = 'MANUAL' 
    begin
       select @w_monto_tmanual = sum(amt_cuota + amt_gracia)
         from cob_cartera..ca_amortizacion_tmp, cob_cartera..ca_rubro_op_tmp
        where amt_operacion = @w_operacionca_tmp
          and rot_operacion = @w_operacionca_tmp
          and rot_operacion = amt_operacion  --JG 16/12/98
          and rot_tipo_rubro= 'C'
          and amt_concepto  = rot_concepto

       select @w_monto_capital = sum(rot_valor)
         from cob_cartera..ca_rubro_op_tmp
        where rot_operacion    = @w_operacionca_tmp
          and rot_tipo_rubro   = 'C' 

       if @w_monto_tmanual <> @w_monto_capital begin
         select @w_error = 710079 
         goto ERROR
       end 
    end

    /* --------------------------------------*/
    /* PRON:24OCT07 Validacion de tea maxima */
    /* --------------------------------------*/

	/*
    if (@w_op_estado = @w_est_novigente) or (@w_op_estado = @w_est_credito)
    begin
      --crea tabla para calculo de TIR
      create table #dividendos_tea (
      operacion       int,
      dividendo       smallint,
      dias            int,
      cuota           money,
      amortiza        money,
      saldo_bloq_aho  money,
      saldo_bloq_cer  money 
      )

      exec @w_return = cob_cartera..sp_TIR_TEA
           @i_operacionca     = @w_operacionca_tmp,
           @i_fecha           = @w_fecha_ini,
           @i_calcula_TEA     = 'S',
           @i_valida_maxima   = 'S',
           @i_temporal        = 'S',
           @o_tea             = @w_tea out

      if @w_return != 0 begin
        select @w_error = @w_return
        goto ERROR
      end
    end
	*/

    begin tran

    if (@w_op_estado = @w_est_novigente) or (@w_op_estado = @w_est_credito)
    begin
        select @w_vinculado = en_vinculacion 
               --@w_causal_vinculacion = en_causal_vinculacion
        from   cobis..cl_ente
        where  en_ente = @w_cliente

        select @w_vinculado = isnull(@w_vinculado,'N')

        update cob_cartera..ca_operacion_tmp
        set    --opt_rubro     = @w_causal_vinculacion,       --Graba en este campo la causa de vinculacion
               ---opt_vinculado = @w_vinculado,
               opt_clase     = isnull(@w_clase,'N')
        where  opt_operacion = @w_operacionca_tmp

        --Obligaciones Financieras
		/*
        if @w_tipo = 'R'
        begin
           exec @w_return = cob_cartera..sp_calcula_margen
                @i_operacionca = @w_operacionca_tmp,
                @i_sector      = @w_sector,
                @i_seg_cre     = @w_seg_cre,
                @i_fecha       = @w_fecha_ini,
                @i_moneda      = @w_moneda
           if @w_return != 0 begin
              select @w_error = @w_return
              goto ERROR
           end   
        end
		*/
    end

    exec @w_return = cob_cartera..sp_pasodef
    @i_banco  = @i_banco,
    @i_operacionca     = 'S',
    @i_dividendo       = 'S',
    @i_amortizacion    = 'S',
    @i_cuota_adicional = 'S',
    @i_rubro_op        = 'S',
    @i_relacion_ptmo   = 'S'

    if @w_return != 0 begin
        select @w_error = @w_return
        goto ERROR
    end    

  --JZU Sprint 8(Se comenta para no realize la actualizion)
/*  exec @w_return = cob_pac..sp_inf_tasas_bce_busin
       @t_trn                  = 7450, 
       @i_operacion            = 'I', 
       @i_banco                = @i_banco,
       @i_dest_finan           = @i_dest_finan,
       @i_act_eco_bce          = @i_act_eco_bce,              
       @i_dest_hipot           = @i_dest_hipot,
       @i_dest_consumo         = @i_dest_consumo*/

    --if @w_return != 0 begin 
    --    select @w_error = @w_return
    --    return @w_error
    --end

    -- TIPO DE PRODUCTO
    select @w_tipo_producto = pd_tipo 
    from   cobis..cl_producto
    where  pd_producto = 7  

    select @w_monto             = op_monto,
           @w_moneda            = op_moneda,
           @w_fecha_ini         = op_fecha_ini,
           @w_fecha_fin         = op_fecha_fin,
           @w_toperacion        = op_toperacion,
           @w_tplazo            = op_tplazo,
           @w_plazo             = op_plazo,
           @w_periodo_reajuste  = op_periodo_reajuste,
           @w_operacionca       = op_operacion,
           @w_op_estado         = op_estado,
           @w_tramite           = op_tramite,
           --@w_tipo_cca          = op_tipo_cca,
           --@w_actividad_destino = op_actividad_destino,
           @w_fecha_ult_proceso = op_fecha_ult_proceso,
           --@w_reaj_diario       = isnull(op_reaj_diario,'N'),
           @w_reajustable       = isnull(op_reajustable,'N'),
           @w_reajuste_especial = isnull(op_reajuste_especial,'N'),
           --@w_seg_cre           = op_seg_cre,
           @w_destino           = op_destino
    from   cob_cartera..ca_operacion
    where  op_banco    = @i_banco

    if (@w_op_estado = @w_est_novigente) or (@w_op_estado = @w_est_credito)
    begin
       update cob_credito..cr_tramite 
          set --tr_tipo_cca          = @w_tipo_cca,
              --tr_actividad_destino = @w_actividad_destino,
              tr_fecha_inicio      = @w_fecha_ini,           --PRON:12MAY08
              --tr_seg_cre           = @w_seg_cre,
              tr_destino           = @w_destino
       where  tr_tramite = @w_tramite

       if @@error <> 0 begin
          select @w_error = 710002
          goto ERROR
       end 
    end

    exec @w_return = cob_cartera..sp_cliente
    @t_debug        = 'N',
    @t_file         = '',
    @t_from         = @w_sp_name,
    @s_date         = @s_date, 
    @i_usuario      = @s_user,
    @i_sesion       = @s_sesn,
    @i_oficina      = @s_ofi,
    @i_producto     = 7,
    @i_tipo         = @w_tipo_producto,
    @i_monto        = @w_monto,
    @i_moneda       = @w_moneda,
    @i_fecha        = @w_fecha_ini,
    @i_fecha_fin    = @w_fecha_fin,
    @i_toperacion   = @w_toperacion,
    @i_banco        = @i_banco,
    @i_tplazo       = @w_tplazo,
    @i_plazo        = @w_plazo,
    @i_operacion    = 'I',
    @i_tramite      = @w_tramite,    --PRON:19JUN06
    @i_estado       = @w_op_estado   --PRON:19JUN06

    if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
    end 

    --PRON:26NOV07 Si la operacion no esta activa recalcula el reajuste, caso contrario
--             verifica antes si hubo cambio en el periodo de reajuste para recalcular

    select @w_calcula_reajuste = 'N'
    if (@w_op_estado = @w_est_novigente or @w_op_estado = @w_est_credito)
       select @w_calcula_reajuste = 'S',
              @w_op_activa = 'N'
    else
    begin
     if (@w_periodo_reajuste_ant <> @w_periodo_reajuste) or (@w_reaj_diario_ant <> @w_reaj_diario) or
        (@w_reajustable <> @w_reajustable_ant)
        select @w_calcula_reajuste = 'S',
               @w_op_activa = 'S'
    end

    if @w_calcula_reajuste = 'S'
    begin
      -- GENERACION DE LAS FECHAS DE REAJUSTE
      if ISNULL(@w_periodo_reajuste,0) != 0 and @w_reajustable = 'S'
      begin
        exec @w_return  = cob_cartera..sp_fecha_reajuste
             @s_ssn     = @s_ssn,
             @s_user    = @s_user,
             @s_date    = @s_date,
             @s_ofi     = @s_ofi,
             @s_term    = @s_term,
             @i_banco   = @i_banco,
             @i_tipo    = 'I',
             @i_activa  = @w_op_activa

        if @w_return != 0 begin
          select @w_error = @w_return
          goto ERROR
        end
      end 
      else 
      begin
        delete cob_cartera..ca_reajuste_det
        from   cob_cartera..ca_reajuste
        where  re_operacion   = @w_operacionca
        and    re_fecha      >= @w_fecha_ult_proceso 
        and    red_operacion  = re_operacion
        and    red_secuencial = re_secuencial

        if @@error !=0 begin
          select @w_error = 710003
          goto ERROR
        end

        delete cob_cartera..ca_reajuste
        where re_operacion = @w_operacionca
        and   re_fecha    >= @w_fecha_ult_proceso 

        if @@error != 0 begin
          select @w_error = 710003
          goto   ERROR
        end

        --PRON:8JUL2008 Cuando es reajustable = 'N', encera los campos
        --              relacionados en la tabla
        update cob_cartera..ca_operacion
        set    op_fecha_reajuste   = null,
               --op_reaj_diario      = 'N',
               op_periodo_reajuste = 0
        where  op_operacion = @w_operacionca
                         
      end
    end
    else
       if (@w_reajuste_especial_ant <> @w_reajuste_especial) 
       begin
            --PRON:8JUL2008 Si unicamente cambia la condicion especial S/N del reajuste
            --              actualiza los reajustes futuros en la tabla
            update cob_cartera..ca_reajuste
            set   re_reajuste_especial = @w_reajuste_especial
            where re_operacion = @w_operacionca
            and   re_fecha    >= @w_fecha_ult_proceso   
       end

    if @w_op_estado <> @w_est_credito
    begin
       select @w_clave1 = convert(varchar(255),@w_operacionca_tmp)

       exec @w_return = cob_cartera..sp_tran_servicio
         @s_user    = @s_user,
         @s_date    = @s_date,
         @s_ofi     = @s_ofi,
         @s_term    = @s_term,
         @i_tabla   = 'ca_operacion',
         @i_clave1  = @w_clave1
       
       if @w_return != 0 begin
          select @w_error = @w_return
          goto ERROR
       end
    end

	/*
    --PRON:16MAY08
    --No existe en Tabla Definitivas, recien va a crear con estado NO VIGENTE
    --registra la transaccion para contabilizar el credito APROBADO
    if @w_existe = 'N' and @w_op_estado = @w_est_novigente and @w_tipo <> 'R'
    begin

      exec @w_return      = cob_cartera..sp_conta_tramite
           @s_user        = @s_user,
           @s_term        = @s_term,        
           @s_ofi         = @s_ofi,     
           @s_date        = @s_date,
           @i_operacionca = @w_operacionca,
           @i_operacion   = 'I'

      if @w_return != 0 return @w_return
    end
	*/


    if (@w_cta_anterior <>  @w_cta_actual) or (@w_forma_pago <> @w_forma_pago_ant)
    begin
       --PRON:10JUL07 Elimina los abonos pendientes de aplicar por debitos automaticos que estan registrados con la cuenta anterior
       update cob_cartera..ca_abono
       set   ab_estado = 'E'
       from  cob_cartera..ca_abono_det
       where ab_operacion = @w_operacionca
       and   ab_estado = 'ING'
       and   abd_operacion = ab_operacion
       and   abd_secuencial_ing = ab_secuencial_ing
       and   abd_beneficiario like 'Debito Automatico%'
    end


    commit tran

end      --RAL 19-Ene-2017 inconsistencia con orquestacion en el flujo

return 0

ERROR:
exec cobis..sp_cerror
    @t_debug  = 'N',         
    @t_file   = NULL,
    @t_from   = @w_sp_name,   
    @i_num    = @w_error
    --@i_cuenta = ' '

return @w_error

go
