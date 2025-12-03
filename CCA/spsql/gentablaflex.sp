/************************************************************************/
/*      Archivo:                gentablaflex.sp                         */
/*      Stored procedure:       sp_gentabla_flexible                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     May. 2014                               */
/*      Nro. procedure          1                                       */
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
/*      Genera la tabla de amortizacion FLEXIBLE.                       */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-05-13     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/************************************************************************/  

use cob_cartera
go

--- SECCION:ERRORES no quitar esta seccion
delete cobis..cl_errores where numero between 70001001 and 70001999
go
   insert into cobis..cl_errores values(70001001, 0, 'Error de datos: prestamo no ha sido pasado a tablas para recalculo')
   insert into cobis..cl_errores values(70001002, 0, 'Tramite no cuenta con flujo requerido para este tipo de amortizacion. Por favor verifique.')
   insert into cobis..cl_errores values(70001003, 0, 'Flujo de disponibles solo puede tener un valor por cada mes. Por favor verifique el flujo.')
   insert into cobis..cl_errores values(70001004, 0, 'Error tecnico descuadra el monto del credito')
   insert into cobis..cl_errores values(70001005, 0, 'No cumple condiciones: Flujo no alcanza para cubrir el capital de la deuda.')
   insert into cobis..cl_errores values(70001006, 0, 'Error de datos: el tramite registrado en cartera no existe en el modulo de credito.')
   insert into cobis..cl_errores values(70001007, 0, 'Error al crear el concepto de seguros.')
   insert into cobis..cl_errores values(70001008, 0, 'Error realizando la preparacion inicial del flujo de disponibles.')
   insert into cobis..cl_errores values(70001009, 0, 'Para este tipo de amortizacion, debe definir el dia de pago fijo del mes.')
   insert into cobis..cl_errores values(70001010, 0, 'No fue posible calcular la tabla de amortizacion')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_gentabla_flexible')
   drop proc sp_gentabla_flexible
go

---NR000392
create proc sp_gentabla_flexible
   @i_debug                         char(1) = 'N',
   @i_operacionca                   int,
   @i_num_dec                       tinyint,
   @o_fecha_fin                     datetime     = null out,
   @o_plazo                         int          = null out,
   @o_tplazo                        catalogo     = null out,
   @o_cuota                         money        = null out,
   @o_msg_msv                       varchar(255) = null out
     
as
declare
   @w_saldo_deuda             float,
   @w_saldo_cap               money,
   @w_saldo                   money,
   @w_op_fecha_ini            datetime,
   @w_fecha_ini               datetime,
   @w_fecha_fin               datetime,
   @w_control_fecha_fin       tinyint,
   @w_icta                    smallint,
   @w_nro_anio                smallint,
   @w_ult_div                 smallint,
   @w_error                   int,

   @w_op_dia_fijo             smallint,
   @w_op_toperacion           catalogo,
   @w_op_banco                cuenta,
   @w_op_cliente              int,
   @w_op_oficina              int,
   @w_op_tipo                 char,
   @w_fecha_limite_fng        datetime,
   @w_op_dias_anio            smallint,
   @w_op_causacion            char,
   @w_parametro_segdeuven     catalogo,
   @w_parametro_segdeuem      catalogo,
   @w_cto_fng_vencido         catalogo,
   @w_cto_fng_iva             catalogo,
   @w_matriz_mipyme_tflex     catalogo,
   @w_cto_mipyme              catalogo,
   @w_cto_mipyme_iva          catalogo,
   @w_max_dias_cuota          smallint,
   @w_min_cuotas_anio         smallint,
   @w_min_dias_cuotas         tinyint,
   @w_op_tramite              int,
   @w_tr_destino              catalogo,
   @w_intentos_anio           int,

   @w_seg_concepto            catalogo,
   @w_seg_valor               money,
   @w_seg_tasa_efa            float,

   @w_tasa_ponderada          float,
   @w_proporcion_deuda        float,
   @w_ubicacion_cuota_anio    tinyint,
   @w_fecha_seg_ini           datetime,
   @w_fecha_seg_fin           datetime,
   @w_vr_mensual              money

begin
   select @w_nro_anio = 0,
          @w_control_fecha_fin = 0,
          @w_min_cuotas_anio = 4,
          @w_intentos_anio = 0,
          @w_ubicacion_cuota_anio = 0

   if not exists(select 1
                 from   cob_credito..cr_disponibles_tramite
                 where  dt_operacion_cca = @i_operacionca)
   begin
      return 70001002 -- NECESITA TENER FLUJO DE DISPONIBLES PARA UTILIZAR ESTE TIPO DE AMORTIZACION
   end
   
   select @w_cto_mipyme = pa_char
   from   cobis..cl_parametro  with (nolock)
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'MIPYME'
   
   select @w_matriz_mipyme_tflex = @w_cto_mipyme

   select @w_matriz_mipyme_tflex = pa_char
   from   cobis..cl_parametro  with (nolock)
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'MIPYFX'

   select @w_fecha_ini           = opt_fecha_ini,
          @w_op_fecha_ini        = opt_fecha_ini,
          @w_fecha_fin           = dateadd(YEAR, 1, opt_fecha_ini),
          @w_op_dia_fijo         = opt_dia_fijo,
          @w_op_toperacion       = opt_toperacion,
          @w_op_tipo             = opt_tipo,
          @w_fecha_limite_fng    = opt_fecha_dex,
          @w_op_dias_anio        = opt_dias_anio,
          @w_op_causacion        = opt_causacion,
          @w_op_tramite          = isnull(opt_tramite, 0),
          @w_saldo_cap           = opt_monto,
          @w_saldo_deuda         = opt_monto,
          @w_op_banco            = opt_banco,
          @w_op_cliente          = opt_cliente,
          @w_op_oficina          = opt_oficina
   from   ca_operacion_tmp
   where  opt_operacion = @i_operacionca

   if @@ROWCOUNT = 0
   begin
      return 70001001 -- PRESTAMO NO EXISTE EN LA TABLAS TEMPORALES
   end

   exec @w_error = cob_credito..sp_seguros_tramite 
        @i_tramite   = @w_op_tramite,
        @i_operacion = 'P',
        @i_tflexible = 'S'
   
   if @w_error <> 0 
   begin
      return @w_error
   end 
   
   if @w_op_tramite is not null
   begin
      select @w_tr_destino = isnull(tr_destino, ''),
             @w_saldo_cap  = tr_monto_solicitado
      from   cob_credito..cr_tramite
      where  tr_tramite = @w_op_tramite

      if @@ROWCOUNT = 0
      begin
         return 70001006 -- ERROR DE DATOS, EL TRAMITE REGISTRADO EN CARTERA NO EXISTE EN CRÉDITO
      end
      
      select @w_saldo_deuda = @w_saldo_cap
      
      if @i_debug = 'S'
         print 'Saldo microcrédito ' + convert(varchar, @w_saldo_deuda)

      -- ACTUALIZACION DE LOS CONCEPTOS DE SEGUROS
      delete ca_rubro_op_tmp
      from   cob_credito..cr_corresp_sib
      where  rot_operacion = @i_operacionca
      and    tabla = 'T155'
      and    rot_concepto = codigo_sib
      
      select @w_tasa_ponderada = 0
      
      declare
         cur_seguros cursor
         for select concepto  = codigo_sib,
                    sum(isnull(ps_valor_mensual,0) * isnull(datediff(MONTH,as_fecha_ini_cobertura,as_fecha_fin_cobertura), 0)) as vr_seguro,
                    avg(isnull(ps_tasa_efa, 0)) as tasa_efa,
                    max(datediff(MONTH,as_fecha_ini_cobertura,as_fecha_fin_cobertura))
             from  cob_credito..cr_seguros_tramite with (nolock),
                   cob_credito..cr_asegurados      with (nolock),
                   cob_credito..cr_plan_seguros_vs ps,
                   cob_credito..cr_corresp_sib
             where st_tramite           = @w_op_tramite
             and   st_secuencial_seguro = as_secuencial_seguro
             and   as_plan              = ps_codigo_plan
             and   st_tipo_seguro       = ps_tipo_seguro
             and   ps_estado            = 'V'      
             and   as_tipo_aseg         = (case when ps_tipo_seguro in(2, 3, 4) then 1 else as_tipo_aseg end)
             and   tabla = 'T155'
             and   codigo = ps_tipo_seguro
             group by codigo_sib
         for read only

      open cur_seguros

      fetch cur_seguros
      into  @w_seg_concepto, @w_seg_valor, @w_seg_tasa_efa, @w_icta

      while @@FETCH_STATUS = 0
      begin
         if @i_debug = 'S'
            print '  CTO SEG ' + @w_seg_concepto + ', valor ' + convert(varchar, @w_seg_valor) + ', MESES ' + convert(varchar, @w_icta)

         insert into ca_rubro_op_tmp
               (rot_operacion,            rot_concepto,        rot_tipo_rubro,
                rot_fpago,                rot_prioridad,       rot_paga_mora,
                rot_provisiona,           rot_signo,           rot_factor,
                rot_referencial,          rot_signo_reajuste,  rot_factor_reajuste,
                rot_referencial_reajuste, rot_valor,
                rot_porcentaje,           rot_porcentaje_aux,  rot_gracia,
                rot_concepto_asociado,    rot_redescuento,     rot_intermediacion,
                rot_principal,            rot_porcentaje_efa,  rot_garantia,
                rot_tipo_puntos,          rot_saldo_op,        rot_saldo_por_desem,
                rot_base_calculo,         rot_num_dec,         rot_limite,
                rot_iva_siempre,          rot_monto_aprobado,  rot_porcentaje_cobrar,
                rot_tipo_garantia,        rot_nro_garantia,    rot_porcentaje_cobertura,
                rot_valor_garantia,       rot_tperiodo,        rot_periodo,
                rot_tabla,                rot_saldo_insoluto,  rot_calcular_devolucion)
         select @i_operacionca,           ru_concepto,         ru_tipo_rubro,
                ru_fpago,                 ru_prioridad,        ru_paga_mora,
                ru_provisiona,            null,                null,
                null,                     null,                null,
                null,                     @w_seg_valor,
                @w_seg_tasa_efa,          0,                   null,
                ru_concepto_asociado,     null,                ru_intermediacion,
                ru_principal,             @w_seg_tasa_efa,     '',
                null,                     ru_saldo_op,         ru_saldo_por_desem,
                @w_seg_valor,             @i_num_dec,          ru_limite,
                ru_iva_siempre,           ru_monto_aprobado,   -392,
                ru_tipo_garantia,         null,                ru_porcentaje_cobertura,
                ru_valor_garantia,        ru_tperiodo,         ru_periodo,
                ru_tabla,                 ru_saldo_insoluto,   ru_calcular_devolucion
         from   ca_rubro
         where  ru_concepto            = @w_seg_concepto
         and    ru_toperacion          = @w_op_toperacion
         
         if @@error != 0
         begin
            return 70001007 -- ERROR AL CREAR EL CONCEPTO DE SEGUROS
         end

         select @w_saldo_cap = @w_saldo_cap + @w_seg_valor
         if @i_debug = 'S'
            print '  NVO MONTO ' + convert(varchar, @w_saldo_cap)
         --
         fetch cur_seguros
         into  @w_seg_concepto, @w_seg_valor, @w_seg_tasa_efa, @w_icta
      end

      close cur_seguros
      deallocate cur_seguros

      select @w_proporcion_deuda = @w_saldo_deuda / cast(@w_saldo_cap  as float)

      -- CALCULO DE LA TASA PONDERADA DE LOS SEGUROS VOLUNTARIOS
      select @w_tasa_ponderada = isnull(sum(rot_porcentaje_efa * cast(rot_valor as float) / cast(@w_saldo_cap  as float)), 0)
      from   ca_rubro_op_tmp
      where  rot_operacion = @i_operacionca
      and    rot_porcentaje_cobrar = -392
      
      -- CALCULO DE LA TASA PONDERADA TOTAL QUE QUEDARÁ EN EL CAMPO ro_porcentaje_cobrar DEL CONCEPTO INTERÉS
      update ca_rubro_op_tmp
      set    rot_porcentaje_cobrar = round(isnull((rot_porcentaje_efa * @w_saldo_deuda / cast(@w_saldo_cap  as float) ) + @w_tasa_ponderada, rot_porcentaje_efa), 4)
      where  rot_operacion = @i_operacionca
      and    rot_tipo_rubro = 'I'
      
      update ca_rubro_op_tmp
      set    rot_porcentaje_cobrar = @w_proporcion_deuda
      where  rot_operacion = @i_operacionca
      and    (   rot_concepto  = @w_cto_mipyme -- PROPORCION DE DEUDA PARA MIPYME
              or rot_tipo_rubro = 'C')         -- Y EN EL CAPITAL

      update ca_rubro_op_tmp
      set    rot_porcentaje_cobrar = round(cast(rot_valor as float) / cast(@w_saldo_cap as float), 4)
      where  rot_operacion = @i_operacionca
      and    rot_porcentaje_cobrar = -392  -- PARA LOS SEGUROS INVOLUNTARIOS

      -- FIN: FQ SECCION DE INTEGRACION DE DEUDA CON SEGUROS VOLUNTARIOS ********************************************************
   end

   select @w_saldo = @w_saldo_cap
   
   -- DETERMINAR PORCENTAJE DE COMISIÓN MIPYME
   declare
      @w_SMV               money,
      @w_cliente_nuevo     char,
      @w_monto_parametro   float,
      @w_factor            float

   if exists (select 1
               from   ca_operacion with (rowlock)
               where  op_cliente = @w_op_cliente
               and    op_estado  in (0, 1, 2, 3, 4, 5, 9, 99)
               and    op_operacion != @i_operacionca)
      select @w_cliente_nuevo = 'R'     --R: Renovado
   else         
      select @w_cliente_nuevo = 'N'     --N: new

   select @w_SMV      = pa_money 
   from   cobis..cl_parametro with (nolock)
   where  pa_producto  = 'ADM'
   and    pa_nemonico  = 'SMV'
   
   exec  @w_error = cob_cartera..sp_retona_valor_en_smlv
         @i_matriz         = @w_matriz_mipyme_tflex,
         @i_monto          = @w_saldo,
         @i_smv            = @w_SMV,
         @o_MontoEnSMLV    = @w_monto_parametro out

   if @w_error != 0
      return @w_error

   if @w_monto_parametro  = -1
      select @w_monto_parametro = @w_saldo / @w_SMV

   select @w_factor = rot_porcentaje
   from   ca_rubro_op_tmp
   where  rot_operacion = @i_operacionca
   and    rot_concepto  = @w_cto_mipyme
   
   if @w_monto_parametro > 0
   begin        
      exec @w_error  = sp_matriz_valor
           @i_matriz      = @w_matriz_mipyme_tflex,
           @i_fecha_vig   = @w_op_fecha_ini,  
           @i_eje1        = @w_op_oficina,   
           @i_eje2        = @w_monto_parametro,     
           @i_eje3        = @w_cliente_nuevo,
           @o_valor       = @w_factor     OUTPUT, 
           @o_msg         = @o_msg_msv    OUTPUT
                
      if @w_error <> 0  return @w_error      
   end
   
   update ca_rubro_op_tmp with (rowlock)
   set    rot_porcentaje =  isnull(@w_factor, rot_porcentaje)
   where  rot_operacion = @i_operacionca
   and    rot_concepto  = @w_cto_mipyme

   if isnull(@w_op_dia_fijo, 0) = 0
   begin
      if @i_debug = 'S'
         print 'DIA FIJO NULO PARA OBLIGACION  ' + convert(varchar, @i_operacionca)
      return 70001009 -- POR FAVOR DEFINA EL DIA DE PAGO FIJO DEL MES
   end

   if exists(select datepart(YEAR, dt_fecha), datepart(MONTH, dt_fecha), count(1)
          from   cob_credito..cr_disponibles_tramite
          where  dt_operacion_cca = @i_operacionca
          group  by datepart(YEAR, dt_fecha), datepart(MONTH, dt_fecha)
          having count(1) > 1 )
   begin
      return 70001003 -- LOS DATOS DE FLUJOS SOLO PUEDEN TENER UN DISPONIBLE POR MES, POR FAVOR REVISAR EL FLUJO
   end

   update cob_credito..cr_disponibles_tramite
   set    dt_fecha = DATEADD(DAY, -DATEPART(DAY, dt_fecha) + @w_op_dia_fijo , dt_fecha),
          dt_dividendo = 0,
          dt_valido = 'S'
   where  dt_operacion_cca = @i_operacionca

   if @@ERROR != 0
   begin
      return 70001008 -- ERROR REALIZANDO LA PREPARACION INICIAL DEL FLUJO DE DISPONIBLES
   end

   -- PARAMETRO GENERAL PARA DIAS MINIMOS CUOTA 
   select @w_min_dias_cuotas = pa_tinyint
   from   cobis..cl_parametro with (nolock)
   where  pa_nemonico = 'DMINC'
   and    pa_producto   = 'CCA'
   
   select @w_min_cuotas_anio = pa_smallint
   from cobis..cl_parametro  with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'FXMNCT'

   select @w_parametro_segdeuven = pa_char
   from cobis..cl_parametro  with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'SEDEVE'

   --LECTURA DEL PARAMETRO CODIGO DEL RUBRO SEGURO DEUDORES EMPLEADO
   select @w_parametro_segdeuem = pa_char
   from   cobis..cl_parametro  with (nolock)
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'SEDEEM'

   select @w_cto_fng_vencido = rot_concepto
   from   ca_rubro_op_tmp
   where  rot_operacion = @i_operacionca
   and    rot_fpago in ('P','A')
   and    rot_concepto = (select pa_char
                          from   cobis..cl_parametro with (nolock)
                          where  pa_producto = 'CCA'
                          and    pa_nemonico = 'COMFNG')
   
   if @@rowcount <> 0
   begin
      select @w_cto_fng_iva = rot_concepto
      from   ca_rubro_op_tmp
      where  rot_operacion = @i_operacionca
      and    rot_concepto_asociado = @w_cto_fng_vencido
   end 

   select @w_cto_mipyme_iva = pa_char
   from cobis..cl_parametro  with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'IVAMIP'

   select @w_max_dias_cuota = pa_smallint
   from cobis..cl_parametro  with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'FXMXCT'

   select @w_nro_anio = 1

   while @w_saldo > 0 and @w_intentos_anio < 50
   begin
      select @w_intentos_anio = @w_intentos_anio + 1
      select @w_ult_div = isnull(max(dit_dividendo), 0)
      from   ca_dividendo_tmp
      where  dit_operacion = @i_operacionca

      if @i_debug = 'S'
      begin
         print ''
         print 'calcular el año: ' + cast(@w_nro_anio as varchar) + '  desde ' + CONVERT(varchar, @w_fecha_ini, 111)  + ' hasta ' + CONVERT(varchar, @w_fecha_fin, 111)
               + ' ult cuota: ' + CONVERT(varchar, @w_ult_div) + '  SALDO: ' + convert(varchar, @w_saldo)
      end

      if @w_nro_anio > 1
         select @w_ubicacion_cuota_anio = 1
      else
         select @w_ubicacion_cuota_anio = 0

      exec @w_error = sp_gentabla_flexible_anio
           @i_debug                 = @i_debug,
           @i_operacion             = @i_operacionca,
           @i_capital_financiar     = @w_saldo_cap,
           @i_fecha_ini_anio        = @w_fecha_ini,
           @i_fecha_fin_anio        = @w_fecha_fin,
           @i_nro_ult_cuota         = @w_ult_div,
           @i_num_dec               = @i_num_dec,

           @i_op_dia_fijo           = @w_op_dia_fijo,
           @i_op_toperacion         = @w_op_toperacion,
           @i_op_tipo               = @w_op_tipo,
           @i_fecha_limite_fng      = @w_fecha_limite_fng,
           @i_op_dias_anio          = @w_op_dias_anio, -- EL TIPO MONEY ES PARA EVITAR PROBLEMAS DE AUTOCONVERSION EN LOS CALCULOS
           @i_op_causacion          = @w_op_causacion,
           @i_parametro_segdeuven   = @w_parametro_segdeuven,
           @i_parametro_segdeuem    = @w_parametro_segdeuem,
           @i_cto_fng_vencido       = @w_cto_fng_vencido,
           @i_cto_fng_iva           = @w_cto_fng_iva,
           @i_cto_mipyme            = @w_cto_mipyme,
           @i_cto_mipyme_iva        = @w_cto_mipyme_iva,
           @i_max_dias_cuota        = @w_max_dias_cuota,
           @i_min_cuotas_anio       = @w_min_cuotas_anio,
           @i_min_dias_cuotas       = @w_min_dias_cuotas,
           @i_ubicacion_cuota_anio  = @w_ubicacion_cuota_anio,
           @i_proporcion_deuda      = @w_proporcion_deuda,

           @o_saldo_anio            = @w_saldo              OUTPUT,
           @o_control_fecha_fin     = @w_control_fecha_fin  OUTPUT

      if @w_error != 0
      begin
         return @w_error
      end

      if @w_control_fecha_fin = 1 -- RECALCULAR DESDE EL AÑO ANTERIOR AL CORRIENTE
      begin
         -- RECALCULAR LOS PARAMETROS DEL AÑO ANTERIOR QUE SE VAN A CALCULAR
         select @w_nro_anio = @w_nro_anio - 1,
                @w_fecha_ini = dateadd(YEAR, -1, @w_fecha_ini)

         select @w_fecha_fin = max(dit_fecha_ven)
         from   ca_dividendo_tmp
         where  dit_operacion = @i_operacionca

         if @i_debug = 'S'
            print 'Se activo el control de fecha: eliminar la tabla posterior a ' + convert(varchar, @w_fecha_ini, 111)

         -- BORRAR EL AÑO QUE SE VA RECALCULAR
         delete ca_amortizacion_tmp
         from   ca_dividendo_tmp
         where  amt_operacion = @i_operacionca
         and    amt_dividendo = dit_dividendo
         and    dit_operacion = @i_operacionca
         and    dit_fecha_ven > @w_fecha_ini

         delete ca_dividendo_tmp
         where  dit_operacion = @i_operacionca
         and    dit_fecha_ven > @w_fecha_ini

         if @i_debug = 'S'
            print 'REINTENTAR '  + convert(varchar, @w_nro_anio) + ' desde ' + CONVERT(varchar, @w_fecha_ini, 111) + ' - '+ CONVERT(varchar, @w_fecha_fin, 111)
      end
      
      if @w_control_fecha_fin = 2 -- CASI BIEN ESTE AÑO, SE EXTINGUIO EL SALDO ANTES DE TIEMPO
      begin
         if @i_debug = 'S'
            print 'REINTENTAR POR EXTINCION DE SALDO'  + convert(varchar, @w_nro_anio) + ' desde ' + CONVERT(varchar, @w_fecha_ini, 111) + ' - '+ CONVERT(varchar, @w_fecha_fin, 111)

         -- DESHACER LO QUE SE HAYA GRABADO PARA EL ULTIMO AÑO EN CURSO, EL CUAL NO ES VÁLIDO
         delete ca_amortizacion_tmp
         from   ca_dividendo_tmp
         where  amt_operacion = @i_operacionca
         and    amt_dividendo = dit_dividendo
         and    dit_operacion = @i_operacionca
         and    dit_fecha_ven > @w_fecha_ini

         -- ES EL MISMO PERIODO PERO EL FIN DE AÑO ES HASTA LA CUOTA CALCULADA
         select @w_fecha_fin = isnull(max(dit_fecha_ven), @w_fecha_fin)
         from   ca_dividendo_tmp
         where  dit_operacion = @i_operacionca
         and    dit_fecha_ven > @w_fecha_ini

         delete ca_dividendo_tmp
         where  dit_operacion = @i_operacionca
         and    dit_fecha_ven > @w_fecha_ini
      end

      if @w_control_fecha_fin = 0 -- BIEN ESTE AÑO
      begin
         exec @w_error = sp_validar_act_financiar
              @i_debug           = @i_debug,
              @i_operacionca     = @i_operacionca,
              @i_destino         = @w_tr_destino,
              @i_anio            = @w_nro_anio

         if @w_error != 0
         begin
            return @w_error
         end
         select @w_nro_anio = @w_nro_anio + 1

         select @w_fecha_ini = @w_fecha_fin,
                @w_fecha_fin = dateadd(YEAR, 1, @w_fecha_fin)
         
         if @i_debug = 'S'
         begin
            print 'Año terminado, ahora iniciar año ' + convert(varchar, @w_nro_anio) + ' desde ' + convert(varchar, @w_fecha_ini, 111) + ' hasta ' + convert(varchar, @w_fecha_fin, 111)
            print ' '
         end
      end
   end
   
   if (@w_saldo < 0)
   begin
      return 70001004 -- ERROR TECNICO EN EL SALDO
   end

   if @w_saldo > 0
   begin
      return 70001005 -- NO SE PUDO CALCULAR LA TABLA, QUEDA SALDO AL FINAL SIN DISTRIBUIR
   end

   select @o_fecha_fin = null

   select @o_fecha_fin = max(dit_fecha_ven)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacionca

   if @o_fecha_fin is null
      return 70001010 -- NO SE PUDO CALCULAR LA TABLA DE AMORTIZACION
   
   update ca_operacion
   set    op_fecha_fin = @o_fecha_fin
   where  op_operacion = @i_operacionca

   select @o_tplazo = 'D',
          @o_cuota  = 0,
          @o_msg_msv = ''

   exec @w_error = sp_dias_cuota_360
        @i_fecha_ini = @w_op_fecha_ini,
        @i_fecha_fin = @o_fecha_fin,
        @o_dias      = @o_plazo     OUTPUT
      
   update ca_operacion_tmp
   set    opt_fecha_fin = @o_fecha_fin,
          opt_plazo     = @o_plazo,
          opt_tplazo    = @o_tplazo,
          opt_cuota     = 0,
          opt_monto     = @w_saldo_cap,
          opt_monto_aprobado = @w_saldo_cap
   where  opt_operacion = @i_operacionca
   
   update cob_credito..cr_tramite
   set    tr_monto = @w_saldo_cap
   where  tr_tramite =  @w_op_tramite

   update ca_rubro_op_tmp
   set    rot_valor = @w_saldo_cap
   where  rot_operacion = @i_operacionca
   and    rot_tipo_rubro = 'C'         -- Y EN EL CAPITAL

   declare
      @w_tipo_garantia     catalogo,
      @w_parametro_fng_des catalogo,
      @w_param_iva_fng_des catalogo
      
   -- PARAMETRO DE LA GARANTIA DE FNG ANUAL
   select @w_parametro_fng_des = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'COFNGD'
   set transaction isolation level read uncommitted

   select @w_param_iva_fng_des = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'IVFNGD'
   set transaction isolation level read uncommitted

   select @w_tipo_garantia = tc_tipo
   from   cob_custodia..cu_custodia with (nolock),
          cob_credito..cr_gar_propuesta with (nolock),
          cob_cartera..ca_operacion with (nolock),
          cob_custodia..cu_tipo_custodia with (nolock)
   where  op_banco          = @w_op_banco
   and    op_tramite        = gp_tramite 
   and    gp_garantia       = cu_codigo_externo
   and    cu_tipo           = tc_tipo
   and    tc_tipo_superior  in ( (select w_cod_gar_fng = pa_char
                                    from cobis..cl_parametro with (nolock)
                                    where pa_producto  = 'GAR'
                                    and   pa_nemonico  = 'CODFNG'),
                                    (select w_cod_gar_usaid = pa_char
                                    from cobis..cl_parametro with (nolock)
                                    where pa_producto = 'GAR'
                                    and pa_nemonico = 'CODUSA')
                                 )


   if @w_tipo_garantia is not null
   begin
      update cob_credito..cr_gar_propuesta
      set    gp_valor_resp_garantia = round((gp_porcentaje * @w_saldo_cap /100.0) + 0.49, @i_num_dec)
      from   cob_custodia..cu_custodia with (nolock)
      where  gp_tramite = @w_op_tramite
      and    cu_codigo_externo = gp_garantia
      and    cu_tipo = @w_tipo_garantia

      -- ACTUALIZAR EL RO_VAOR DEL CONCEPTO COMISION FNG ANUAL
      -- NO ES PROBLEMA SI NO LO TIENE

      if @o_plazo < 360
         select @w_factor = cast(@o_plazo as float) / 360.0
      else
         select @w_factor = 1

      update ca_rubro_op_tmp
      set    rot_valor = round(@w_saldo_cap * rot_porcentaje / 100.0 *  @w_factor, @i_num_dec) -- ESTE SERIA EL VALOR ANUAL
      where  rot_operacion = @i_operacionca
      and    rot_concepto  = @w_parametro_fng_des

      select @w_factor = 0
      select @w_factor = rot_valor
      from   ca_rubro_op_tmp
      where  rot_operacion = @i_operacionca
      and    rot_concepto  = @w_parametro_fng_des

      update ca_rubro_op_tmp
      set    rot_valor = round(rot_porcentaje *  @w_factor / 100.0, @i_num_dec) -- ESTE SERIA EL VALOR ANUAL
      where  rot_operacion = @i_operacionca
      and    rot_concepto  = @w_param_iva_fng_des
   end

   exec @w_error = sp_seguros_tflexible
        @i_debug          = @i_debug,
        @i_operacionca    = @i_operacionca,
        @i_tramite        = @w_op_tramite,
        @i_saldo_cap      = @w_saldo_cap,
        @i_num_dec        = @i_num_dec,
        @i_dias_anio      = @w_op_dias_anio,
        @i_causacion      = @w_op_causacion,
        @o_msg_msv        = @o_msg_msv OUTPUT

   if @w_error != 0
      return @w_error

   -- AHORA UNAS VALIDACIONES FINALES
   exec @w_error = sp_validar_plazo_tflex
        @i_operacion = @i_operacionca

   if @w_error != 0
      return @w_error
   
   return 0
end
go

