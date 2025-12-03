/************************************************************************/
/*  Archivo:            detamint.sp                                     */
/*  Stored procedure:   sp_detalle_amortizacion_int                     */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Credito y Cartera                               */
/*  Disenado por:       Fabian de la Torre                              */
/*  Fecha de escritura: Mar 1999                                        */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Desplegar el detalle de los valores a pagar para cancelar           */
/*      cuotas completas                                                */
/*                              CAMBIOS                                 */
/*       FECHA                 AUTOR             CAMBIO                 */
/*       jul/28/2001           EPB               Proyeccion de pago Acum*/
/*                                               mulado no debe sumar   */
/*                                               lo proyectado          */
/* 04/10/2010         Yecid Martinez         Fecha valor baja Intensidad*/
/*                                           NYMR 7x24                  */
/* 16/03/2012         Luis Carlos Moreno     REQ 293 - Sumar valor por  */
/*                                           reconocimiento a cada div  */
/*                                           en pago proyectado         */
/* 02/07/2014         Luis Carlos Moreno     REQ 433 - Ajuste para ver  */
/*                                           correctamente el valor de  */
/*                                           los saldos por reco.       */
/* 25/02/2014         I.Berganza             Req: 397 - Reportes FGA    */
/* 11/01/2021         P.Narvaez    Rubros anticipados, CoreBase         */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_detalle_amortizacion_int')
    drop proc sp_detalle_amortizacion_int
go

create proc sp_detalle_amortizacion_int (
   @s_user              login       = null,
   @s_date              datetime    = null,
   @s_term              descripcion = null,
   @s_ofi               smallint    = null,
   @i_banco             cuenta,
   @i_dividendo         int = 0,
   @i_tipo_cobro        char(1),
   @i_tipo_proyeccion   char(1) = 'C',
   @i_tasa_prepago      float,
   @i_formato_fecha     int,
   @i_monto_pago        money    = null,
   @i_operacion         char(1)  = null,
   @i_fecha             datetime = null,
   @i_moneda            tinyint  = null,
   @i_vlrsec            money    = null,
   @i_atx               char(1) = 'N' --Inc_7624
   

)

as declare
   @w_sp_name               descripcion,
   @w_operacionca           int,
   @w_return                int,
   @w_error                 int,
   @w_di_dividendo          int,
   @w_fecha_ult_proceso     datetime,
   @w_di_fecha_ini          datetime,
   @w_di_estado             int,
   @w_pago                  money,
   @w_pago2                 money,
   @w_pagov                 money,
   @w_pagoa                 money,
   @w_valor_cap             money,
   @w_devolucion            money,
   @w_calculo_int_vig       money,
   @w_est_cancelado         int,
   @w_dividendo_can         int,
   @w_contador              int,
   @w_di_dividendo2         int,
   @w_dias_i                int,
   @w_di_fecha_ini2         datetime,
   @w_di_fecha_ven2         datetime,
   @w_di_fecha_ven          datetime,
   @w_di_fecha_ven_aux      datetime,
   @w_di_fecha_ini_aux      datetime,
   @w_found                 smallint,
   @w_dias_cuota            int,
   @w_periodo_int           int,
   @w_tdividendo            catalogo,
   @w_dividendo_vig         int,
   @w_dias                  int,
   @w_est_vigente           int,
   @w_dividendo             int,
   @w_dd_antes              int,
   @w_dd_despues            int,
   @w_dias_anio             int,
   @w_base_calculo          char(1),
   @w_ro_tipo_rubro         char(1),
   @w_pago_presente         money,
   @w_estado                catalogo,
   @w_modalidad             char(1),
   @w_tasa_prepago          float,
   @w_dividendo_max         int,
   /*VARIABLES DE PROYECCION DE TOTAL DEL PRESTAMO*/
   @w_dividendo_max_ven     int,
   @w_dividendo_min_ven     int,
   @w_fecha_fin_op          datetime,
   @w_monto_venc_v          money,
   @w_monto_venc_a          money,
   @w_monto_vig_v           money,
   @w_monto_vig_a           money,
   @w_monto_proy_v          money,
   @w_monto_proy_a          money,
   @w_monto_vencido         money,
   @w_monto_vigente         money,
   @w_monto_proyectado      money,
   @w_total_x_rubro         money,
   @w_ro_concepto           catalogo,
   @w_est_vencido           int,
   @w_sum_vencido           money,
   @w_sum_vigente           money,
   @w_sum_proyectado        money,
   @w_sum_t_x_rubro         money,
   @w_tasa_vp               float,
   @w_moneda                int,
   @w_num_dec               int,
   @w_num_dec_tapl          tinyint,
   @w_causacion             char(1),
   @w_monto_pago            money,
   @w_pago3                 money,
   @w_pago4                 money,
   @w_prioridad_cap         tinyint,
   @w_di_de_capital         char(1),
   @w_categoria_rubro       char(1),
   @w_dividendo_sig         int,
   @w_valor_calc            money,
   @w_vigente1              money,
   @w_vencido1              money,
   @w_int_en_vp             money,
   @w_valor_futuro_int      money,
   @w_valor_futuro_int_ant  money,
   @w_valor_int_cap         money,
   @w_fecha_proceso         datetime,
   @w_cuota_cap             money,
   @w_vp_cobrar             money,
   @w_subtotal              money,
   @w_int                   catalogo,
   @w_periodo_d             catalogo,
   @w_num_periodo_d         smallint,
   @w_ro_porcentaje         float,
   @w_decimales_tasa        smallint,
   @w_cuota_anterior        money,
   @w_tipo_cobro_o          char(1),
   @w_max_secuencia         int,
   @w_saldo_seg             money,
   @w_saldo_seg_mn          money,
   @w_estado_op             tinyint,
   @w_saldo_seg_cot_hoy     money,
   @w_moneda_nacional       tinyint,
   @w_cotizacion_op         float,
   @w_cotizacion_mpg        float,
   @w_rowcount              int,
   @w_tiene_reco            char(1),--LCM - 293
   @w_1_vlr_venc            money,  --LCM - 293
   @w_1_div_venc            int,    --LCM - 293
   @w_1_vlr_cap_venc        money,  --LCM - 293
   @w_concepto_rec_fng      varchar(30), --LCM - 293
   @w_sec_rpa_rec           int,    --LCM - 293
   @w_sec_rpa_pag           int,    --LCM - 293
   @w_monto_reconocer       money,  --LCM - 293
   @w_cap_pag_rec           money,  --LCM - 293
   @w_cap_div               money,  --LCM - 293
   @w_vlr_calc_fijo         money,  --LCM - 293
   @w_div_pend              money   --LCM - 293

/* INICIALIZACION DE VARIABLES */
select
@w_sp_name         = 'sp_detalle_amortizacion_int',
@w_est_cancelado   = 3,
@w_est_vigente     = 1,
@w_est_vencido     = 2,
@w_contador        = 0,
@i_tasa_prepago    = isnull(@i_tasa_prepago,0),
@w_tasa_prepago    = isnull(@i_tasa_prepago,0),
@w_tasa_vp         = 0,
@w_num_dec_tapl    = null,
@w_max_secuencia   = 0,
@w_moneda_nacional = 0,
@i_tipo_proyeccion = isnull(@i_tipo_proyeccion, 'C')

/* DETERMINAR LOS DATO DE LA OPERACION */
select
@w_operacionca        = op_operacion,
@w_fecha_ult_proceso  = op_fecha_ult_proceso,
@w_fecha_fin_op       = op_fecha_fin,
@w_periodo_int        = op_periodo_int,
@w_tdividendo         = op_tdividendo,
@w_moneda             = op_moneda,
@w_dias_anio          = op_dias_anio,
@w_causacion          = op_causacion,
@w_fecha_proceso      = op_fecha_ult_proceso,
@w_base_calculo       = op_base_calculo,
@w_periodo_d          = op_tdividendo,
@w_num_periodo_d      = op_periodo_int,
@w_estado_op          = op_estado,
@i_tipo_cobro         = isnull(@i_tipo_cobro, op_tipo_cobro)
from   ca_operacion
where  op_banco       = @i_banco

if @@rowcount = 0 return 


if @i_atx = 'S'begin 
  
   --PRINT '--INICIO NYMR 7x24 Ejecuto FECHA VALOR BAJA INTENSIDAD s_user ' + CAST(@s_user as varchar)
  
   EXEC @w_return = sp_validar_fecha
      @s_user                  = @s_user,
      @s_term                  = @s_term,
      @s_date                  = @s_date ,
      @s_ofi                   = @s_ofi,
      @i_operacionca           = @w_operacionca,
      @i_debug                 = 'N' 

   if @w_return <> 0  
      return @w_return
 
end

-- LCM - 293: VALIDA SI TIENE UN PAGO POR RECONOCIMIENTO ACTIVO
select @w_tiene_reco      = 'N',
       @w_vlr_calc_fijo   = 0,
       @w_div_pend        = 0,
       @w_monto_reconocer = 0

select
@w_vlr_calc_fijo = pr_vlr_calc_fijo,
@w_div_pend      = pr_div_pend
from cob_cartera..ca_pago_recono
where pr_banco = @i_banco
and   pr_estado    = 'A'

if @@rowcount <> 0
   select @w_tiene_reco = 'S'

--select @i_tipo_cobro = 'A'  --OJO BORRAR
   
/* OPTIMIZACION PARA EVITAR ENTRAR EN LOS CURSORES EN CASO DE PAGO PROYECTADO */
--if @i_tipo_cobro = 'P' and @i_tipo_proyeccion = 'C' and @i_monto_pago is null 
if @i_tipo_proyeccion = 'C' and @i_monto_pago is null 
begin
   if @i_atx = 'N'
   begin
      --set rowcount 25
      
      set rowcount 20
      
      select
      dividendo = di_dividendo,
      fec_ven   = convert(varchar(10),di_fecha_ven,@i_formato_fecha),
      pago      = case when @i_tipo_cobro = 'A' then isnull(sum(am_acumulado + am_gracia - am_pagado ),0)
                       else isnull(sum(am_cuota + am_gracia - am_pagado ),0) end,
      estado    = case di_estado when 0 then 'NO VIGENTE' when 1 then 'VIGENTE' when 2 then 'VENCIDO' end 
      into #dividendos
      from ca_dividendo, ca_amortizacion, ca_rubro_op
      where di_operacion  = @w_operacionca
      and   am_operacion  = @w_operacionca
      and   di_operacion  = am_operacion
      and   am_dividendo <= di_dividendo + charindex (ro_fpago, 'A')
      and   am_operacion  = ro_operacion
      and   di_operacion  = ro_operacion
      and   am_concepto   = ro_concepto
      and   di_dividendo > @i_dividendo
      and   di_estado   in (0,1,2)
      and   am_estado   <> 3
      group by di_dividendo, convert(varchar(10),di_fecha_ven,@i_formato_fecha), case di_estado when 0 then 'NO VIGENTE' when 1 then 'VIGENTE' when 2 then 'VENCIDO' end 
      order by di_dividendo

      if @w_tiene_reco = 'S'
      begin
         /* BUSCA LA PRIMERA CUOTA VENCIDA QUE TENGA LA OBLIGACION */
         select top 1 @w_1_vlr_venc = pago,
                @w_1_div_venc = dividendo
         from #dividendos
         where estado = 'VENCIDO'
         order by dividendo

         if @@rowcount > 0
         begin
            /* BUSCA LA TRANSACCION RPA DEL PAGO POR RECONOCIMIENTO */
            select @w_sec_rpa_rec = dtr_secuencial
            from
            ca_transaccion with (nolock),
            ca_det_trn with (nolock)
            where tr_operacion  = @w_operacionca
            and   tr_operacion  = dtr_operacion
            and   tr_secuencial = dtr_secuencial
            and   tr_secuencial > 0
            and   tr_tran       = 'RPA'
            and   tr_estado     <> 'RV'
            and   dtr_concepto  in (select c.codigo
                                    from cobis..cl_tabla t, cobis..cl_catalogo c
                                    where t.tabla = 'ca_fpago_reconocimiento'
                                    and   t.codigo = c.tabla) -- Req. 397  Formas de pago por reconocimiento

            /* OBTIENE EL SECUENCIAL PAG DEL PAGO POR RECONOCIMIENTO */
            select @w_sec_rpa_pag = ab_secuencial_pag
            from ca_abono with (nolock)
            where ab_operacion = @w_operacionca
            and   ab_secuencial_rpa = @w_sec_rpa_rec

            /* OBTIENE CAPITAL PAGADO POR EL RECONOCIMIENTO */
            select @w_cap_pag_rec = isnull(dtr_monto,0)
            from ca_det_trn with (nolock)
            where dtr_operacion = @w_operacionca
            and   dtr_secuencial = @w_sec_rpa_pag
            and   dtr_dividendo = @w_1_div_venc
            and   dtr_concepto = 'CAP'
            if @w_cap_pag_rec <> 0
            begin 
               select @w_cap_div = isnull(am_cuota,0)
               from ca_amortizacion with (nolock)
               where am_operacion = @w_operacionca
               and   am_dividendo = @w_1_div_venc
               and   am_concepto  = 'CAP'

               if @w_cap_div >= @w_cap_pag_rec
               begin
                  /* OBTIENE MONTO CUOTA PROXIMA VENCIDA  */
                  select @w_1_vlr_cap_venc = sum(am_acumulado)
                  from ca_amortizacion
                  where am_operacion = @w_operacionca
                  and   am_dividendo = @w_1_div_venc

                  if @@rowcount > 0 /* MUESTRA MENSAJE CON EL VALOR A CANCELAR DE LA PRIMERA CUOTA VENCIDA */
                     print 'Cliente con reconocimiento de garantia colateral. El valor de la cuota a cancelar es de $' + cast(@w_1_vlr_cap_venc as varchar)
               end
            end 
         end            

         /* SI EL RECONOCIMIENTO TIENE DIVIDENDOS VIGENTES PENDUENTES CALCULA EL VALOR DEL RECONOCIMIENTO */
         /* QUE SE DEBE SUMAR AL VALOR DE LA CUOTA */
         if @w_div_pend > 0
         begin
            select @w_monto_reconocer = round(isnull(@w_vlr_calc_fijo / @w_div_pend, 0),0)

            /* CALCULA EL VALOR PARA AMORTIZAR EL CAPITAL DEL RECONOCIMIENTO POR DIVIDENDO */
            select
            dividendo_rec = di_dividendo,
            rec       = sum(@w_monto_reconocer)
            into #recono
            from ca_dividendo, ca_amortizacion
            where di_operacion  = @w_operacionca
            and   am_operacion  = @w_operacionca
            and   di_operacion  = am_operacion
            and   am_dividendo <= di_dividendo
            and   di_dividendo > @i_dividendo
            and   di_estado   in (0,1,2)
            and   am_estado   <> 3
            and   am_concepto = 'CAP'
            group by di_dividendo, convert(varchar(10),di_fecha_ven,103), case di_estado when 0 then 'NO VIGENTE' when 1 then 'VIGENTE' when 2 then 'VENCIDO' end 
            order by di_dividendo

            /* ACTUALIZA EL VALOR DEL PAGO ADICIONANDO EL VALOR POR CAPITAL DEL RECONOCIMIENTO */
            update #dividendos
            set pago = pago + rec
            from #recono
            where dividendo = dividendo_rec
         end

      end

      /* RETORNA CONSULTA */
      select
      'No. CUOTA'= dividendo,
      'VENCE'    = fec_ven,
      'PAGO'     = pago,
      'ESTADO'   = estado
      from #dividendos
      order by dividendo

      set rowcount 0 
      return 0
   end
   if @i_atx = 'S'
   begin   
      set rowcount 40
      
      select
      dividendo = di_dividendo,
      fec_ven   = convert(varchar(10),di_fecha_ven,@i_formato_fecha),
      pago      = case when @i_tipo_cobro = 'A' then isnull(sum(am_acumulado + am_gracia - am_pagado ),0)
                       else isnull(sum(am_cuota + am_gracia - am_pagado ),0) end,
      estado    = case di_estado when 0 then 'NO VIGENTE' when 1 then 'VIGENTE' when 2 then 'VENCIDO' end 
      into #dividendos_atx
      from ca_dividendo, ca_amortizacion, ca_rubro_op
      where di_operacion = @w_operacionca
      and   am_operacion = @w_operacionca
      and   di_operacion = am_operacion
      and   di_dividendo > @i_dividendo    
      and   am_dividendo <= di_dividendo + charindex (ro_fpago, 'A')
      and   am_operacion  = ro_operacion
      and   di_operacion  = ro_operacion
      and   am_concepto   = ro_concepto
      and   di_estado   in (0,1,2)
      and   am_estado   <> 3
      group by di_dividendo, convert(varchar(10),di_fecha_ven,@i_formato_fecha), case di_estado when 0 then 'NO VIGENTE' when 1 then 'VIGENTE' when 2 then 'VENCIDO' end 
      order by di_dividendo
      
      if @w_tiene_reco = 'S'
      begin
         /* BUSCA LA PRIMERA CUOTA VENCIDA QUE TENGA LA OBLIGACION */
         select top 1 @w_1_vlr_venc = pago,
                @w_1_div_venc = dividendo
         from #dividendos_atx
         where estado = 'VENCIDO'
         order by dividendo

         if @@rowcount > 0
         begin
            /* BUSCA LA TRANSACCION RPA DEL PAGO POR RECONOCIMIENTO */
            select @w_sec_rpa_rec = dtr_secuencial
            from
            ca_transaccion with (nolock),
            ca_det_trn with (nolock)
            where tr_operacion  = @w_operacionca
            and   tr_operacion  = dtr_operacion
            and   tr_secuencial = dtr_secuencial
            and   tr_secuencial > 0
            and   tr_tran       = 'RPA'
            and   tr_estado     <> 'RV'
            and   dtr_concepto  in (select c.codigo
                                    from cobis..cl_tabla t, cobis..cl_catalogo c
                                    where t.tabla = 'ca_fpago_reconocimiento'
                                    and   t.codigo = c.tabla)

            /* OBTIENE EL SECUENCIAL PAG DEL PAGO POR RECONOCIMIENTO */
            select @w_sec_rpa_pag = ab_secuencial_pag
            from ca_abono with (nolock)
            where ab_operacion = @w_operacionca
            and   ab_secuencial_rpa = @w_sec_rpa_rec

            /* OBTIENE CAPITAL PAGADO POR EL RECONOCIMIENTO */
            select @w_cap_pag_rec = isnull(dtr_monto,0)
            from ca_det_trn with (nolock)
            where dtr_operacion = @w_operacionca
            and   dtr_secuencial = @w_sec_rpa_pag
            and   dtr_dividendo = @w_1_div_venc
            and   dtr_concepto = 'CAP'
            if @w_cap_pag_rec <> 0
            begin 
               select @w_cap_div = isnull(am_cuota,0)
               from ca_amortizacion with (nolock)
               where am_operacion = @w_operacionca
               and   am_dividendo = @w_1_div_venc
               and   am_concepto  = 'CAP'

               if @w_cap_div >= @w_cap_pag_rec
               begin

                  /* OBTIENE MONTO CUOTA PROXIMA VENCIDA  */
                  select @w_1_vlr_cap_venc = sum(am_acumulado)
                  from ca_amortizacion
                  where am_operacion = @w_operacionca
                  and   am_dividendo = @w_1_div_venc

                  if @@rowcount > 0 /* MUESTRA MENSAJE CON EL VALOR A CANCELAR DE LA PRIMERA CUOTA VENCIDA */
                     print 'Cliente con reconocimiento de garantia colateral. El valor de la cuota a cancelar es de $' + cast(@w_1_vlr_cap_venc as varchar)
               end
            end 
         end            

         /* SI EL RECONOCIMIENTO TIENE DIVIDENDOS VIGENTES PENDUENTES CALCULA EL VALOR DEL RECONOCIMIENTO */
         /* QUE SE DEBE SUMAR AL VALOR DE LA CUOTA */
         if @w_div_pend > 0
         begin
            select @w_monto_reconocer = round(isnull(@w_vlr_calc_fijo / @w_div_pend, 0),0)

            /* CALCULA EL VALOR PARA AMORTIZAR EL CAPITAL DEL RECONOCIMIENTO POR DIVIDENDO */
            select
            dividendo_rec = di_dividendo,
            rec       = sum(@w_monto_reconocer)
            into #recono_atx
            from ca_dividendo, ca_amortizacion
            where di_operacion  = @w_operacionca
            and   am_operacion  = @w_operacionca
            and   di_operacion  = am_operacion
            and   am_dividendo <= di_dividendo
            and   di_dividendo > @i_dividendo
            and   di_estado   in (0,1,2)
            and   am_estado   <> 3
            and   am_concepto = 'CAP'
            group by di_dividendo, convert(varchar(10),di_fecha_ven,103), case di_estado when 0 then 'NO VIGENTE' when 1 then 'VIGENTE' when 2 then 'VENCIDO' end 
            order by di_dividendo

            /* ACTUALIZA EL VALOR DEL PAGO ADICIONANDO EL VALOR POR CAPITAL DEL RECONOCIMIENTO */
            update #dividendos_atx
            set pago = pago + rec
            from #recono_atx
            where dividendo = dividendo_rec
         end

      end


      /* RETORNA CONSULTA */
      select
      'No. CUOTA'= dividendo,
      'VENCE'    = fec_ven,
      'PAGO'     = pago,
      'ESTADO'   = estado
      from #dividendos_atx
      order by dividendo

      return 0
   end
end


-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


/*TABLA PARA CONSULTA DE PROYECCION DEL PAGO TOTAL DEL PRESTAMO*/


-- DETERMINAR EL VALOR DE COTIZACION DEL DIA PARA MONEDA DE LA OPERACION Y DE PAGO
if @w_moneda = @w_moneda_nacional
   select @w_cotizacion_op = 1.0
else
begin
   exec sp_buscar_cotizacion
        @i_moneda     = @w_moneda,
        @i_fecha      = @w_fecha_ult_proceso,
        @o_cotizacion = @w_cotizacion_op output
end

if @i_moneda = @w_moneda_nacional
   select @w_cotizacion_mpg = 1.0
else
begin
   exec sp_buscar_cotizacion
        @i_moneda     = @i_moneda,
        @i_fecha      = @w_fecha_ult_proceso,
        @o_cotizacion = @w_cotizacion_mpg output
end

/* VALORES POR DEFECTO SI NO SE TRANSMITEN DE FRONT END */
if @i_fecha is null
   select @i_fecha = @w_fecha_proceso

if @i_moneda is null
   select @i_moneda = @w_moneda


/** MANEJO DE DECIMALES **/
exec @w_return = sp_decimales
        @i_moneda    = @i_moneda,
        @o_decimales = @w_num_dec out

if @w_return <> 0 return @w_return

select @w_int = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
   PRINT 'no se definio paraemtro general INT'


delete ca_prestamo_pagos_tmp
where operacion_pag  = @w_operacionca

delete ca_detalle_tmp
where operacion_det     = @w_operacionca


exec @w_return = sp_decimales
        @i_moneda      = @w_moneda,
        @o_decimales   = @w_num_dec out

if @w_return <> 0
   return @w_return



/*CALCULAR TASA DE INTERES PRESTAMO*/
if @i_tasa_prepago = 0
begin
   select @i_tasa_prepago = isnull(sum(ro_porcentaje),0),
          @w_num_dec_tapl = ro_num_dec
   from  ca_rubro_op
   where ro_operacion  = @w_operacionca
   and   ro_tipo_rubro = 'I'
   and   ro_fpago     in ('A','P')
   group by ro_num_dec
end



/* BUSQUEDA DEL SIGUIENTE DIVIDENDO QUE NO SEA CANCELADO */
select @w_dividendo_can = isnull(max(di_dividendo),0)
from   ca_dividendo
where di_operacion = @w_operacionca
and   di_estado    = @w_est_cancelado


if @i_dividendo < @w_dividendo_can
   select @w_dividendo = @w_dividendo_can
else
   select @w_dividendo = @i_dividendo


/*MAXIMO DIVIDENDO*/
select @w_dividendo_max = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @w_operacionca


/* BUSCAR DIVIDENDO VIGENTE */
select @w_dividendo_vig = di_dividendo
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vigente

if @@rowcount = 0
   select @w_dividendo_vig = @w_dividendo_max + 1


select @w_dividendo_min_ven = min(di_dividendo)
from ca_dividendo
where di_operacion = @w_operacionca
and   di_estado    = @w_est_vencido


select @w_dividendo_max_ven = max(di_dividendo)
from ca_dividendo
where di_operacion = @w_operacionca
and   di_estado    = @w_est_vencido


/* VERIFICAR SI LA OPERACION TIENE RUBROS DE TIPO ANTICIPADO */
if exists(select 1 from ca_rubro_op
          where ro_operacion  = @w_operacionca
          and   ro_fpago      = 'A'
          and   ro_tipo_rubro = 'I')
   select @w_modalidad = 'A'
else
   select @w_modalidad = 'V'



/*COVERTIR TASA DE LA OPERACION A EFECTIVA */
exec @w_return =  sp_conversion_tasas_int
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = @w_tdividendo,
        @i_modalidad_o    = @w_modalidad,
        @i_num_periodo_o  = @w_periodo_int,
        @i_tasa_o         = @i_tasa_prepago,
        @i_periodo_d      = 'A',
        @i_modalidad_d    = 'V',
        @i_num_periodo_d  = 1,
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_vp output

if @w_return <> 0
   return @w_return

select @w_tasa_vp = @w_tasa_vp / 100  --DAG


/*COVERTIR TASA DE PREPAGO A TASA DIARIA VENCIDA */
exec @w_return =  sp_conversion_tasas_int
        @i_dias_anio      = @w_dias_anio,
        @i_periodo_o      = @w_tdividendo,
        @i_modalidad_o    = @w_modalidad,
        @i_num_periodo_o  = @w_periodo_int,
        @i_tasa_o         = @i_tasa_prepago,
        @i_periodo_d      = 'D',
        @i_modalidad_d    = 'V',
        @i_num_periodo_d  = 1,
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @i_tasa_prepago output

if @w_return <> 0
   return @w_return


select @w_di_fecha_ini    = @w_fecha_ult_proceso,
       @w_tipo_cobro_o    = @i_tipo_cobro,
       @w_calculo_int_vig = 0,
       @w_monto_pago      = @i_monto_pago,
       @w_pago3           = 0,
       @w_pago4           = 0



--print 'i_tipo_proyeccion.....%1!',@i_tipo_proyeccion

if @i_tipo_proyeccion = 'C'
begin  --INICIO DE PROYECCION POR CUOTA
    if @i_tipo_proyeccion = 'C'
    declare cursor_dividendo cursor for
            select  di_dividendo, di_fecha_ven, di_estado, di_de_capital
            from   ca_dividendo
            where  di_operacion  =  @w_operacionca
            and    di_dividendo  >  @w_dividendo
            and    di_dividendo  <=  @w_dividendo_max 
        for read only
    else
        declare cursor_dividendo cursor for
            select  di_dividendo, di_fecha_ven, di_estado, di_de_capital
            from   ca_dividendo
            where  di_operacion  =  @w_operacionca
            and    di_dividendo  >  @w_dividendo
        for read only

    open    cursor_dividendo

    fetch   cursor_dividendo into
        @w_di_dividendo, @w_di_fecha_ven, @w_di_estado, @w_di_de_capital

    while   @@fetch_status = 0
    begin
        if (@@fetch_status = -1)
        begin
            select @w_error = 708999
            goto ERROR
        end

        /*SI ES PROYECCION CUOTA A PAGAR DESPLIEGA 88 CUOTAS MAS LA ULTIMA*/
        if @i_operacion = 'Y' and @w_contador = 88 and @w_di_dividendo <> @w_dividendo_max
        begin
           fetch   cursor_dividendo into
           @w_di_dividendo, @w_di_fecha_ven, @w_di_estado, @w_di_de_capital
           continue
        end

        select @w_contador = @w_contador + 1

        if @w_contador = 90
           break

        ---     print 'tipo_de_cobro...%1!',@i_tipo_cobro

        if @i_tipo_cobro = 'E'  and @w_di_fecha_ven = @w_fecha_ult_proceso  and @w_di_estado = @w_est_vigente
           select @i_tipo_cobro = 'P'
        else
           select @i_tipo_cobro = @w_tipo_cobro_o

        if @i_tipo_cobro = 'A'
        begin
            if @w_modalidad = 'V'
            begin

                select @w_pago = isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)             -- REQ 175: PEQUEÑA EMPRESA
                from ca_amortizacion, ca_rubro_op
                where ro_operacion = @w_operacionca
                and   ro_operacion = am_operacion
                and   ro_concepto  = am_concepto
                and   ro_fpago     <> 'A'
                and   am_estado    <> @w_est_cancelado
                and   am_dividendo > @w_dividendo_can
                and   am_dividendo <= @w_di_dividendo


                /*CUANDO EXISTE GRACIA */
                if @w_pago < 0 select @w_pago = 0
                    select @w_pago2 =  isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)       -- REQ 175: PEQUEÑA EMPRESA
                    from ca_amortizacion, ca_rubro_op
                    where ro_operacion = @w_operacionca
                    and   ro_operacion = am_operacion
                    and   ro_concepto  = am_concepto
                    and   am_estado    <> @w_est_cancelado
                    and   ro_fpago     = 'A'
                    and   am_dividendo > @w_dividendo_can
                    and   am_dividendo <= @w_di_dividendo + 1

                select @w_pago = @w_pago + @w_pago2
            end
            else
            begin
                --ESTO ES PARA SACAR TODOS LOS RUBROS A EXCEPCION DE ANTICIPADOS
                select @w_pago =  isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)            -- REQ 175: PEQUEÑA EMPRESA
                from ca_amortizacion, ca_rubro_op
                where ro_operacion = @w_operacionca
                and   ro_operacion = am_operacion
                and   ro_concepto  = am_concepto
                and   am_estado    <> @w_est_cancelado
                and   ro_fpago     <> 'A'
                and   am_dividendo > @w_dividendo_can
                and   am_dividendo <= @w_di_dividendo

                if @w_di_fecha_ven = @w_fecha_ult_proceso
                   select @w_dividendo_vig = @w_dividendo_vig + 1

                select @w_pago2 = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
                from ca_amortizacion, ca_rubro_op
                where ro_operacion = @w_operacionca
                and   ro_operacion = am_operacion
                and   ro_concepto  = am_concepto
                and   ro_fpago     = 'A'
                and   am_estado    <> @w_est_cancelado
                and   am_dividendo > @w_dividendo_can
                and   am_dividendo <= @w_dividendo_vig


                if @w_di_dividendo = @w_dividendo_vig
                begin
                    /* VALOR DEL INTERES POR PAGAR DEL DIVIDENDO VIGENTE */
                    if exists(select 1 from ca_dividendo
                                   where di_operacion = @w_operacionca
                                     and di_dividendo = @w_di_dividendo - 1
                                     and di_estado = @w_est_cancelado)
                        select @w_pago3 =  isnull(sum(am_cuota + am_gracia - am_pagado ),0)
                        from ca_amortizacion, ca_rubro_op
                        where ro_operacion = @w_operacionca
                        and   ro_operacion = am_operacion
                        and   ro_concepto  = am_concepto
                        and   am_estado    <> @w_est_cancelado
                        and   ro_fpago     = 'A'
                        and   am_dividendo = @w_dividendo_vig

                    select @w_prioridad_cap = ro_prioridad
                    from ca_rubro_op
                    where ro_operacion = @w_operacionca
                    and ro_tipo_rubro = 'C'


                    /* VALOR DE RUBOS NI DE INTERES, NI DE CAPITAL CON PRIORIDAD MENOR A LA DEL CAPITAL */
                    select @w_pago4 = isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)     -- REQ 175: PEQUEÑA EMPRESA
                    from ca_amortizacion, ca_rubro_op
                    where ro_operacion = @w_operacionca
                    and   ro_operacion = am_operacion
                    and   ro_concepto  = am_concepto
                    and   ro_fpago     <> 'A'
                    and   am_estado    <> @w_est_cancelado
                    and   ro_tipo_rubro <> 'C'
                    and   ro_prioridad <= @w_prioridad_cap
                    and   am_dividendo = @w_dividendo_vig
                end


                /* CALCULAR SALDO DE CAPITAL */
                if @w_di_dividendo >= @w_dividendo_vig
                begin
                   select @w_valor_cap = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
                   from  ca_amortizacion, ca_rubro_op
                   where ro_operacion = @w_operacionca
                   and   ro_operacion = am_operacion
                   and   ro_concepto  = am_concepto
                   and   ro_tipo_rubro= 'C'
                   and   am_dividendo >= @w_di_dividendo
                   and   am_estado    <> @w_est_cancelado

                   if @i_monto_pago is not null
                   begin
                        if @w_di_dividendo = @w_dividendo_vig
                        begin
                            if (@w_monto_pago - @w_pago3 - @w_pago4) > 0
                            begin
                            if @w_valor_cap > (@w_monto_pago-@w_pago3-@w_pago4)
                                select @w_valor_cap = @w_monto_pago-@w_pago3-@w_pago4
                            end
                            else
                                select @w_valor_cap = 0
                        end
                    end
                end
                else
                   select @w_valor_cap = 0  --si esta vencido no hay devolucion


            select @w_di_fecha_ven_aux = di_fecha_ven,
                   @w_di_fecha_ini_aux = di_fecha_ini,
                   @w_dias_cuota       = di_dias_cuota
            from ca_dividendo
            where di_operacion = @w_operacionca
            and   di_dividendo = @w_dividendo_vig
            
            if @@rowcount = 0
               select @w_found = 0
            else
               select @w_found = 1
            
            if @w_di_dividendo = @w_dividendo_vig
            begin
               if @w_found = 1
               begin
                  if @w_causacion = 'L'
                  begin
                     if @w_base_calculo = 'R'
                     begin
                        select @w_dd_antes = datediff(dd,@w_di_fecha_ini_aux, @w_fecha_ult_proceso)
                        select @w_dd_despues = datediff(dd, @w_fecha_ult_proceso, @w_di_fecha_ven_aux)
                     end
                     else
                     begin
                        exec @w_return = sp_dias_base_comercial
                               @i_fecha_ini = @w_di_fecha_ini_aux,
                               @i_fecha_ven = @w_fecha_ult_proceso,
                               @i_opcion    = 'D',
                               @o_dias_int  = @w_dd_antes out
            
                        exec @w_return = sp_dias_base_comercial
                               @i_fecha_ini = @w_fecha_ult_proceso,
                               @i_fecha_ven = @w_di_fecha_ven_aux,
                               @i_opcion    = 'D',
                               @o_dias_int  = @w_dd_despues out
                     end
            
                     if @w_dias_cuota = (@w_dd_antes + @w_dd_despues)
                        select @w_dias = @w_dd_despues
            
                     if @w_dias_cuota < (@w_dd_antes + @w_dd_despues)
                        select @w_dias = @w_dd_despues - abs(@w_dias_cuota - (@w_dd_antes + @w_dd_despues))
            
                     if @w_dias_cuota > (@w_dd_antes + @w_dd_despues)
                        select @w_dias = @w_dd_despues + abs(@w_dias_cuota - (@w_dd_antes + @w_dd_despues))
                  end --@w_causacion = 'L'
                  else
                  begin  --esto es por exponencial
                     select @w_devolucion = sum((abs(am_cuota - am_acumulado) + (am_cuota - am_acumulado))/2)
                     from ca_amortizacion, ca_rubro_op
                     where ro_operacion = @w_operacionca
                     and   ro_operacion = am_operacion
                     and   ro_concepto  = am_concepto
                     and   ro_tipo_rubro = 'I'
                     and   ro_fpago     = 'A'
                     and   am_dividendo = @w_di_dividendo
                     and   am_estado    <> @w_est_cancelado
                  end
               end  --@w_found = 1
               else
                    select @w_dias = 0
            end   --@w_di_dividendo = @w_dividendo_vig
            else
                select @w_dias = di_dias_cuota
                from ca_dividendo
                where di_operacion = @w_operacionca
                and   di_dividendo = @w_di_dividendo
            
            
            if @w_causacion = 'L'
                select @w_devolucion = (@w_valor_cap * @w_tasa_prepago * @w_dias) / (100 * @w_dias_anio)
            
            select @w_devolucion = round(@w_devolucion,@w_num_dec)

         if @w_di_dividendo = @w_dividendo_vig
         begin
            if @i_monto_pago is null
            begin
               select @w_calculo_int_vig = @w_devolucion
               select @w_pago2 = @w_pago2 - @w_devolucion
               select @w_pago = @w_pago + @w_pago2
            end
            else
            begin
               if @w_monto_pago > 0
                begin
                    if @w_valor_cap > 0
                    begin
                        select @w_calculo_int_vig = @w_devolucion
                        select @w_pago = (@i_monto_pago - @w_monto_pago) + (@w_valor_cap + @w_pago3 + @w_pago4) - @w_devolucion
                        select @w_monto_pago = @w_monto_pago - (@w_valor_cap + @w_pago3 + @w_pago4)
                    end
                    else
                    begin
                        select @w_pago       = @i_monto_pago,
                               @w_monto_pago = 0
                    end
                end
                else
                    select @w_pago = 0
            end
         end
         else
         begin
            select @w_pago = @w_pago + @w_pago2 - @w_calculo_int_vig

            if @i_monto_pago is not null
                if (@w_pago + @w_calculo_int_vig) > @i_monto_pago
                begin
                    select @w_pago = @i_monto_pago - @w_calculo_int_vig
                    select @w_monto_pago = 0
                end
                else
                    select @w_monto_pago = @i_monto_pago - (@w_pago + @w_calculo_int_vig)
         end
      end
   end


    if @i_tipo_cobro = 'P'
    begin

      select @w_pago =
      isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_rubro_op
      where ro_operacion = @w_operacionca
      and   ro_operacion = am_operacion
      and   ro_concepto  = am_concepto
      and   ro_fpago     <> 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo > @w_dividendo_can
      and   am_dividendo <= @w_di_dividendo

      select @w_pago2 =
      isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_rubro_op
      where ro_operacion = @w_operacionca
      and   ro_operacion = am_operacion
      and   ro_concepto  = am_concepto
      and   ro_fpago     = 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo > @w_dividendo_can
      and   am_dividendo <= @w_di_dividendo + 1

      select @w_pago = @w_pago + @w_pago2

    end

   if @i_tipo_cobro = 'E'  begin

      /* CALCULA VALORES DIFERENTES A INTERES */
      select @w_pago =
      isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_rubro_op
      where ro_operacion = @w_operacionca
      and   ro_operacion = am_operacion
      and   ro_concepto  = am_concepto
      and   ro_fpago     <> 'A'
      and   am_estado    <> @w_est_cancelado
      and   ro_tipo_rubro <> 'I'
      and   am_dividendo > @w_dividendo_can
      and   am_dividendo = @w_di_dividendo

      /* CALCULA VALORES DIFERENTES A INTERES PARA RUBROS ANTICIPADOS */
      select @w_pago2 =  isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_rubro_op
      where ro_operacion = @w_operacionca
      and   ro_operacion = am_operacion
      and   ro_concepto  = am_concepto
      and   ro_fpago     = 'A'
      and   am_estado    <> @w_est_cancelado
      and   ro_tipo_rubro <> 'I'
      and   am_dividendo > @w_dividendo_can
      and   am_dividendo = @w_di_dividendo + 1

      select @w_valor_calc = @w_pago + @w_pago2

      select
      @w_cuota_anterior   = pago
      from ca_detalle_tmp
      where operacion_det = @w_operacionca
      and   dividendo     = @w_di_dividendo - 1

      /** SELECCION DE LA MAXIMA SECUENCIA DEL RUBRO **/
      select @w_max_secuencia = max(am_secuencia)
      from ca_amortizacion
      where am_operacion = @w_operacionca
      and am_dividendo   = @w_dividendo_vig
      and am_concepto    = @w_int

      if @w_di_estado not in (2,3)
      begin
         if @w_di_estado = 1 and @w_max_secuencia > 1
         begin
            select @w_valor_calc = isnull(sum(am_acumulado - am_pagado),0)
            from ca_amortizacion
            where am_operacion =  @w_operacionca
            and am_dividendo   =  @w_dividendo_vig
            and am_concepto    =  @w_int
            and am_estado    <> @w_est_cancelado
         end
         else
               begin
                  /* TASA NOMINAL PARA LA OPERACION */
                  select @w_ro_porcentaje  = ro_porcentaje,
                         @w_decimales_tasa = ro_num_dec
                  from   ca_rubro_op
                  where  ro_operacion  = @w_operacionca
                  and    ro_tipo_rubro = 'I'
            
                  select @w_dias = datediff(dd,@w_fecha_proceso,@w_di_fecha_ven)
            
                  if @w_dias_anio = 360
                  begin
                      exec  sp_dias_cuota_360
                          @i_fecha_ini = @w_fecha_proceso,
                          @i_fecha_fin = @w_di_fecha_ven,
                          @o_dias      = @w_dias out
                  end
            
            
                  /*TASA EQUIVALENTE A LOS DIAS QUE FALTAN*/
                  exec @w_return =  sp_conversion_tasas_int
                  @i_dias_anio      = @w_dias_anio,
                  @i_base_calculo   = @w_base_calculo,
                  @i_periodo_o      = @w_periodo_d,
                  @i_modalidad_o    = 'V',
                  @i_num_periodo_o  = @w_num_periodo_d,
                  @i_tasa_o         = @w_ro_porcentaje,
                  @i_periodo_d      = 'D',
                  @i_modalidad_d    = 'A', ---La tasa equivalente  debe ser anticipada
                  @i_num_periodo_d  = @w_dias,
                  @i_num_dec        = @w_decimales_tasa,
                  @o_tasa_d         = @w_tasa_prepago output
            
                  if @w_return <> 0
                     return @w_return
            
                  /* VALOR DEL INTERES PARA BASE DE VALOR PRESENTE */
                  select @w_valor_futuro_int = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
                  from ca_amortizacion, ca_rubro_op
                  where ro_operacion = @w_operacionca
                  and   ro_operacion = am_operacion
                  and   ro_concepto  = am_concepto
                  and   ro_fpago     <> 'A'
                  and   am_estado    <> @w_est_cancelado
                  and   ro_tipo_rubro = 'I'
                  and   am_dividendo > @w_dividendo_can
                  and   am_dividendo = @w_di_dividendo
            
            
                  /* VALOR DEL INTERES ANTICIPADO PARA BASE DE VALOR PRESENTE */
                  select @w_valor_futuro_int_ant = isnull(sum(am_cuota
                                                            + case when am_gracia > 0 then 0 else am_gracia end
                                                            - am_pagado ),0)
                  from ca_amortizacion, ca_rubro_op
                  where ro_operacion = @w_operacionca
                  and   ro_operacion = am_operacion
                  and   ro_concepto  = am_concepto
                  and   ro_fpago     = 'A'
                  and   am_estado    <> @w_est_cancelado
                  and   ro_tipo_rubro = 'I'
                  and   am_dividendo > @w_dividendo_can
                  and   am_dividendo = @w_di_dividendo + 1
            
                  select @w_valor_futuro_int = @w_valor_futuro_int + @w_valor_futuro_int_ant
            
                  /* VALOR DEL CAPITAL PARA BASE DE VALOR PRESENTE */
                  select @w_cuota_cap  = isnull(am_cuota - am_pagado ,0)
                  from ca_amortizacion,ca_rubro_op
                  where am_operacion = @w_operacionca
                  and   am_operacion  = ro_operacion
                  and   am_concepto = ro_concepto
                  and   ro_tipo_rubro = 'C'
                  and   am_estado    <> @w_est_cancelado
                  and am_dividendo   = @w_di_dividendo
            
                  select  @w_valor_int_cap = @w_valor_futuro_int + @w_cuota_cap
            
                  /* CALCULA VALOR DE INTERESES EN VALOR PRESENTE */
                  exec @w_return = sp_calculo_valor_presente
                  @i_tasa_prepago        = @w_tasa_prepago,
                  @i_valor_int_cap      = @w_valor_int_cap,
                  @i_dias                  = @w_dias,
                  @i_valor_futuro_int      = @w_valor_futuro_int,
                  @i_numdec_op             = @w_num_dec,
                  @o_monto              = @w_vp_cobrar  output
            
                  select @w_int_en_vp      =   @w_vp_cobrar
                  select @w_valor_calc = @w_int_en_vp
            
                end ---valor presente secuencias = 1
            
                select @w_pago = @w_valor_calc + @w_pago + @w_pago2
            end
            else
            begin
                 /* CALCULA VALORES INTERES */
                 select @w_pago = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
                 from ca_amortizacion, ca_rubro_op
                 where ro_operacion = @w_operacionca
                 and   ro_operacion = am_operacion
                 and   ro_concepto  = am_concepto
                 and   ro_fpago     <> 'A'
                 and   am_estado    <> @w_est_cancelado
                 and   ro_tipo_rubro = 'I'
                 and   am_dividendo > @w_dividendo_can
                 and   am_dividendo = @w_di_dividendo

                /* CALCULA VALORES INTERES PARA RUBROS ANTICIPADOS */
                select @w_pago2 = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
                from ca_amortizacion, ca_rubro_op
                where ro_operacion = @w_operacionca
                and   ro_operacion = am_operacion
                and   ro_concepto  = am_concepto
                and   ro_fpago     = 'A'
                and   am_estado    <> @w_est_cancelado
                and   ro_tipo_rubro = 'I'
                and   am_dividendo > @w_dividendo_can
                and   am_dividendo = @w_di_dividendo + 1
  
                select @w_pago = @w_valor_calc + @w_pago + @w_pago2
            end
        end
        /*FIN VALOR PRESENTE (VP) ***/
        --   print 'Valor calculado:' + cast(isnull(@w_pago,0) as varchar)
        --   if @w_dividendo_max = @w_di_dividendo
        --   begin
        --      exec @w_return    = sp_calcula_saldo
        --      @i_operacion      = @w_operacionca,
        --      @i_tipo_pago      = @i_tipo_cobro,
        --      @o_saldo          = @w_pago out
        --   end

        select @w_estado = es_descripcion
        from ca_estado
        where es_codigo = @w_di_estado
        
        if @w_pago > 0 and @w_moneda <> @i_moneda
        begin
            select @w_pago = ceiling(@w_pago * @w_cotizacion_op /@w_cotizacion_mpg)
        end


        if @i_tipo_cobro = 'E' and @w_dividendo_max <> @w_di_dividendo
            select @w_pago = @w_pago + isnull(@w_cuota_anterior,0)
        
        if @w_dividendo_max <> @w_di_dividendo
        begin
            if @w_pago < @i_vlrsec
                select @w_pago = @w_pago + isnull(@i_vlrsec,0)
        
            if @w_moneda = 2  and @w_saldo_seg_mn > 0
                select @w_pago = @w_pago + isnull(@w_saldo_seg_mn,0)
        end
        
        insert into ca_detalle_tmp (
                dividendo,       fecha,             pago,
                estado,          max_pago ,         operacion_det )
        values(
                @w_di_dividendo, @w_di_fecha_ven,   round(@w_pago,@w_num_dec),
                @w_estado,       0,                 @w_operacionca)
        
        if @w_monto_pago = 0
           break
        
        select @w_di_fecha_ini = @w_di_fecha_ven
        
        fetch cursor_dividendo
            into  @w_di_dividendo, @w_di_fecha_ven, @w_di_estado, @w_di_de_capital
    end
    
    close cursor_dividendo
    deallocate cursor_dividendo
    
    select
    'No. CUOTA'    = dividendo,
    'VENCE'    = convert(varchar(10),fecha,@i_formato_fecha),
    'PAGO'     = round(convert(float, pago),@w_num_dec),
    'ESTADO'   = estado --,
    --'MAX_PAGO' = max_pago
    from ca_detalle_tmp
    where operacion_det = @w_operacionca
    order by dividendo

end --Fin de Proyeccion de Cuota



/*PRINT 'proycuot.sp  PROYECCION PRESTAMO @i_tipo_cobro %1!',@i_tipo_cobro */

if @i_tipo_proyeccion = 'P'
begin
   declare cursor_rubros cursor for
        select ro_concepto,   ro_tipo_rubro
        from   ca_rubro_op
        where  ro_operacion  =  @w_operacionca
        and    ro_fpago      <> 'L'
   for read only

   open  cursor_rubros

   fetch cursor_rubros into
        @w_ro_concepto, @w_ro_tipo_rubro

   while   @@fetch_status = 0 begin

   if (@@fetch_status = -1) begin
      select @w_error = 708999
      goto ERROR
   end

   /*CATEGORIA DEL RUBRO*/
   select @w_categoria_rubro = co_categoria
   from ca_concepto
   where co_concepto = @w_ro_concepto


   if @i_tipo_cobro = 'A'
   begin

      select @w_monto_venc_v = isnull(sum(am_acumulado + am_gracia - am_pagado ),0)
      from  ca_amortizacion, ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago     <> 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo >= @w_dividendo_min_ven
      and   am_dividendo <= @w_dividendo_max_ven

      select @w_monto_venc_a =  isnull(sum(am_acumulado + am_gracia - am_pagado ),0)
      from ca_amortizacion,ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago      = 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo >= @w_dividendo_min_ven
      and   am_dividendo <= @w_dividendo_max_ven


      select @w_monto_vig_v =  isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)             -- REQ 175: PEQUEÑA EMPRESA
      from  ca_amortizacion, ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago     <> 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo = @w_dividendo_vig

      select @w_monto_vig_a =  isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)             -- REQ 175: PEQUEÑA EMPRESA
      from ca_amortizacion,ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago      = 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo  = @w_dividendo_vig


      select @w_monto_proy_v = isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)             -- REQ 175: PEQUEÑA EMPRESA
      from  ca_amortizacion, ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago     <> 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo > @w_dividendo_vig

      select @w_monto_proy_a = isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)             -- REQ 175: PEQUEÑA EMPRESA
      from ca_amortizacion,ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago      = 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo  > @w_dividendo_vig

      if @w_categoria_rubro in ('V','S')
         select @w_monto_proy_v = 0,
                @w_monto_proy_a = 0

      select @w_monto_vencido = round(@w_monto_venc_v + @w_monto_venc_a,@w_num_dec),
             @w_monto_vigente = round(@w_monto_vig_v + @w_monto_vig_a,@w_num_dec),
             @w_monto_proyectado = round(@w_monto_proy_v + @w_monto_proy_a,@w_num_dec)

      select @w_total_x_rubro = round(@w_monto_vencido + @w_monto_vigente + @w_monto_proyectado,@w_num_dec)
   end


   if @i_tipo_cobro = 'P'
   begin /*PROYECTADO PRESTAMO*/

      select @w_monto_venc_v =  isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from  ca_amortizacion, ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago     <> 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo >= @w_dividendo_min_ven
      and   am_dividendo <= @w_dividendo_max_ven

      select @w_monto_venc_a = isnull(sum(am_acumulado + am_gracia - am_pagado ),0)
      from ca_amortizacion,ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago      = 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo >= @w_dividendo_min_ven
      and   am_dividendo <= @w_dividendo_max_ven

      select @w_monto_vig_v =  isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from  ca_amortizacion, ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago     <> 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo = @w_dividendo_vig

      select @w_monto_vig_a =  isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion,ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago      = 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo  = @w_dividendo_vig

      select @w_monto_proy_v = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from  ca_amortizacion, ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago     <> 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo > @w_dividendo_vig

      select @w_monto_proy_a = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion,ca_rubro_op
      where am_operacion  = @w_operacionca
      and   ro_operacion  = @w_operacionca
      and   ro_concepto   = @w_ro_concepto
      and   ro_concepto   = am_concepto
      and   ro_fpago      = 'A'
      and   am_estado    <> @w_est_cancelado
      and   am_dividendo  > @w_dividendo_vig

      if @w_categoria_rubro in ('V','S')
         select @w_monto_proy_v = 0,
                @w_monto_proy_a = 0


      if @w_categoria_rubro = 'I'
      begin

         /*POR SI TIENE GRACIA DISTRIBUIDA EN LAS CUOTAS RESTANTES*/
         select @w_monto_proy_v = isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)             -- REQ 175: PEQUEÑA EMPRESA
         from  ca_amortizacion, ca_rubro_op
         where am_operacion  = @w_operacionca
         and   ro_operacion  = @w_operacionca
         and   ro_concepto   = @w_ro_concepto
         and   ro_concepto   = am_concepto
         and   ro_fpago     <> 'A'
         and   am_estado    <> @w_est_cancelado
         and   am_dividendo > @w_dividendo_vig

         select @w_monto_proy_a = isnull(sum(case when am_acumulado + am_gracia - am_pagado < 0 then 0 else am_acumulado + am_gracia - am_pagado end), 0)             -- REQ 175: PEQUEÑA EMPRESA
         from ca_amortizacion,ca_rubro_op
         where am_operacion  = @w_operacionca
         and   ro_operacion  = @w_operacionca
         and   ro_concepto   = @w_ro_concepto
         and   ro_concepto   = am_concepto
         and   ro_fpago      = 'A'
         and   am_estado    <> @w_est_cancelado
         and   am_dividendo  > @w_dividendo_vig
      end

      select @w_monto_vencido = round(@w_monto_venc_v + @w_monto_venc_a,@w_num_dec),
             @w_monto_vigente = round(@w_monto_vig_v + @w_monto_vig_a,@w_num_dec),
             @w_monto_proyectado = round(@w_monto_proy_v + @w_monto_proy_a,@w_num_dec)

      /*PRINT '(proycuota.sp) @w_monto_vencido %1!,
                       @w_monto_vigente %2!,
                       @w_monto_proyectado %3!,
                       @w_ro_concepto %4!', @w_monto_vencido,@w_monto_vigente,@w_monto_proyectado,@w_ro_concepto*/

      select @w_total_x_rubro = round(@w_monto_vencido + @w_monto_vigente + @w_monto_proyectado,@w_num_dec)
   end

   insert into ca_prestamo_pagos_tmp (
        rubro,                          vencido,                        vigente,       
        proyectado,                     total_x_rubro,                  operacion_pag) 
   values(
        @w_ro_concepto,                 isnull(@w_monto_vencido,0),     isnull(@w_monto_vigente,0),
        isnull(@w_monto_proyectado,0),  isnull(@w_total_x_rubro,0),     @w_operacionca)

   fetch   cursor_rubros into
   @w_ro_concepto,@w_ro_tipo_rubro
   end

   close cursor_rubros
   deallocate cursor_rubros

   if exists(select 1 from ca_prestamo_pagos_tmp where operacion_pag = @w_operacionca)
   begin
        select @w_sum_vencido = sum(vencido),
               @w_sum_vigente = sum(vigente),
               @w_sum_proyectado = sum(proyectado),
               @w_sum_t_x_rubro = sum(total_x_rubro)
        from ca_prestamo_pagos_tmp
        where operacion_pag = @w_operacionca

        insert into ca_prestamo_pagos_tmp (
            rubro,              vencido,            vigente,
            proyectado,         total_x_rubro,      operacion_pag
            )
        values(
            'Total General :',  @w_sum_vencido,     @w_sum_vigente,
            @w_sum_proyectado,  @w_sum_t_x_rubro,   @w_operacionca
            )
   end

    select
        'CONCEPTO'      = rubro,
        'VENCIDO'       = vencido,
        'VIGENTE'       = vigente,
        'PROYECTADO'    = proyectado,
        'TOTAL x RUBRO' = total_x_rubro
    from ca_prestamo_pagos_tmp
    where operacion_pag = @w_operacionca
end --Fin de Proyeccion de Total del Prestamo

return 0

ERROR:
exec cobis..sp_cerror
    @t_debug='N',         @t_file = null,
    @t_from =@w_sp_name,   @i_num = @w_error
    --@i_cuenta= ' '

return @w_error

go

