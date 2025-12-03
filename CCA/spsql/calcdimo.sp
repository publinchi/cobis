/************************************************************************/
/*   Nombre Fisico:         calcdimo.sp                                 */
/*   Nombre Logico:      	sp_calculo_diario_mora                      */
/*   Base de datos:         cob_cartera                                 */
/*   Producto:              Cartera                                     */
/*   Disenado por:          Marcelo Poveda                              */
/*   Fecha de escritura:    Ene. 1998                                   */
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
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Procedimiento que realiza el calculo diario de intereses de mora   */
/************************************************************************/
/* FECHA           AUTOR             CAMBIO                             */
/*  28/abr/2023   Guisela Fernandez Ingreso de campo dereestructuracion */
/************************************************************************/
/*                              CAMBIOS                                 */
/*   FECHA             AUTOR             CAMBIO                         */
/*  OCT-2010         Elcira Pelaez    Quitar llamado  Diferidos NR059   */
/*  MAR-2011         Elcira Pelaez    Poner control para que retorne 0  */
/*                                    si no hay div. Vencidos           */
/*  ENE-2013         Luis Guzman      CCA 409 Interes Mora Seguros      */
/*  SEP-30_2015      Elcira Pelaez    Optimizacion                      */
/*  FEB-2019         Edison Cajas     Calculo Iva Mora                  */
/*  MAR-2019         Lorena Regalado  Calculo IMO, CMO, IVA_IMO, IVA_CMO*/
/*  SEP-2019         Lorena Regalado  Calculo del COM_PGOTAR, IVA_COPGOT*/
/*   19/11/2020   Patricio Narvaez   Esquema de Inicio de Dia, 7x24 y   */
/*                                   Doble Cierre automatico            */
/*   DIC/22/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*   Abr/12/2022   C.Tiguaque        Ajuste default ciudad nacional     */
/*   Jun/29/2022   K. Rodríguez  Ajuste estado IMO al insertar en amort.*/
/*   Jul/26/2022   K. Rodríguez  Ajuste variable local de fecha proceso */
/*   Jun/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_calculo_diario_mora')
   drop proc sp_calculo_diario_mora
go

create proc sp_calculo_diario_mora
   @s_user               login,
   @s_term               varchar(30),
   @s_date               datetime,
   @s_ofi                smallint,
   @i_en_linea           char(1),
   @i_banco              cuenta,
   @i_operacionca        int,
   @i_moneda             smallint,
   @i_oficina            smallint,
   @i_fecha_proceso      datetime,
   @i_cotizacion         float,
   @i_num_dec            tinyint,
   @i_num_dec_mn         tinyint = 0,
   @i_est_suspenso       tinyint,
   @i_est_vencido        tinyint,
   @i_ciudad_nacional    int = 9999

as
declare
   @w_secuencial        int,
   @w_error             int,
   @w_sp_name           descripcion,
   @w_monto_mora        money,
   @w_dias_calc         int,
   @w_valor_calc        float,
   @w_valor_calc_mn     float,
   @w_codvalor          int,
   @w_di_dividendo      int,
   @w_di_gracia_disp    smallint,
   @w_di_fecha_ven      datetime,
   @w_di_gracia         smallint,
   @w_ro_concepto       catalogo,
   @w_ro_porcentaje     float,
   @w_am_estado         tinyint,
   @w_am_secuencia      tinyint,
   @w_am_periodo        tinyint,
   @w_dtr_monto         float,
   @w_max_dividendo     int,
   @w_dias_dividendo    int,
   @w_fecultpro         datetime,
   @w_dividendo         smallint,
   @w_tasa_equivalente  char(1),
   @w_min_div_vencido   smallint,
   @w_max_div_vencido   smallint,
   @w_sig_dividendo     smallint,
   @w_toperacion        catalogo,
   @w_monto_mn          money,
   @w_estado_op         tinyint,
   @w_estado            tinyint,
   @w_dias_feriados     int,
   @w_reestructuracion  char(1),
   @w_calificacion      catalogo,
   @w_dias_mora_retro   int,
   @w_mora_retroactiva  char(1),
   @w_primera_vez       int,
   @w_ms_trn            datetime,
   @w_clase_cartera     catalogo,
   @w_op_tdividendo     char(1),
   @w_op_periodo_int    int,
   @w_dias_int          int,
   -- CALCULO DE LA MORA ACUMULADA (PARA EL CALCULO RETROACTIVO)
   @w_retr_dia          int,
   @w_retr_monto        float,
   @w_retr_val_cal      float,
   @w_retr_valor_mora   float,
   @w_ro_valor          money,
   @w_ciudad            int,
   @w_siguiente_dia     datetime,
   @w_op_monto          money,     -- FCP 10/OCT/2005 REQ 389
   @w_dias_calculados   char,
   @w_dias_anio_mora    smallint,
   @w_fecha_sig         datetime,
   @w_dia_fin           int,
   @w_op_moneda         smallint,
   @w_op_naturaleza     char(1),
   @w_tiene_seguro      char(1),
   @w_banco             cuenta,
   @w_ro_referencial    varchar(55),
   @w_monto_seg_mora    money,
   @w_tramite           int,
   @w_tasa_maxima_mora  float,
   @w_oficina_op        int,
   @w_cont_gracia       int,      --LRE
   @w_fecha_ini         datetime, --LRE
   @w_siglas_int        catalogo, --LRE
   @w_siglas_imo        catalogo, --LRE
   @w_mas_gracia        smallint, --LRE
   @w_siglas_com_pta     catalogo,   --LRE
   @w_div_ant            smallint,    --LRE
   @w_gracia_ant         smallint,    --LRE
   @w_ro_provisiona      char(1),      --LRE
   @w_fecha_proceso      datetime

/* INCIAR VARIABLES DE TRABAJO */
select
@w_dias_calculados = 'N',
@w_tiene_seguro    = 'N',
@w_monto_seg_mora  = 0,
@w_cont_gracia     = 0,  --LRE
@w_div_ant         = 0,  --LRE
@w_gracia_ant      = 0,   --LRE
@w_fecha_proceso   = @i_fecha_proceso -- dateadd(dd,-1,@i_fecha_proceso)--@i_fecha_proceso esta un dia adelante como inicio de dia

--LRE 22/Mar/2019 PARAMETROS DE NEMONICOS DE INT, IMO
select @w_siglas_int = pa_char from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico in ('INT')


select @w_siglas_imo = pa_char from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico in ('IMO')


--LRE 11Sep19 PARAMETROS RUBROS PRESTAMOS GRUPALES TEC
select @w_siglas_com_pta = pa_char from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico in ('COMPTA')

--FIN LRE 11Sep19 PARAMETROS RUBROS PRESTAMOS GRUPALES TEC


-- SELECCION DE RANGO DE DIVIDENDOS VENCIDOS
select
@w_min_div_vencido = isnull(min(di_dividendo),0),
@w_max_div_vencido = isnull(max(di_dividendo),0)
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_estado    = @i_est_vencido

if @w_min_div_vencido = 0 return 0

if @i_moneda = 2 select @i_num_dec_mn = 2 -- PARA MEJORAR LA PRECISION DE UVR

--- DATOS DE LA OPERACION
select
@w_banco            = op_banco,                            -- REQ 089 - ACUERDOS DE PAGO - 01/DIC/2010
@w_fecultpro        = op_fecha_ult_proceso,
@w_tasa_equivalente = op_usar_tequivalente,
@w_toperacion       = op_toperacion,
@w_estado_op        = op_estado,
@w_reestructuracion = isnull(op_reestructuracion, ''),
@w_calificacion     = isnull(op_calificacion, ''),
@w_mora_retroactiva = op_mora_retroactiva,
@w_clase_cartera    = op_clase,
@w_op_tdividendo    = op_tdividendo,
@w_op_monto         = op_monto,
@w_op_periodo_int   = op_periodo_int,
@w_op_naturaleza    = op_naturaleza,
@w_op_moneda        = op_moneda,
@w_tramite          = op_tramite,
@w_oficina_op       = op_oficina,
@w_mora_retroactiva = op_mora_retroactiva
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount = 0 begin
  PRINT 'calcdimo.sp No existe Operacion para este calculo Revisar'
  return  701049
end

/* CIUDAD DE LA OFICINA DE LA OPERACION */
select @w_ciudad  = of_ciudad
from   cobis..cl_oficina
where  of_oficina = @i_oficina

--OCT-24-2006 DEF:
if @w_op_naturaleza = 'A'
begin
   if not exists (select 1 from   ca_rubro_op
                  where  ro_operacion = @i_operacionca
                  and    ro_tipo_rubro = 'M')
   begin
      --Insertar el rubro Mora en la tabla de rubros
      insert into ca_rubro_op
            (ro_operacion,             ro_concepto,                ro_tipo_rubro,
             ro_fpago,                 ro_prioridad,               ro_paga_mora,
             ro_provisiona,            ro_signo,                   ro_factor,
             ro_referencial,           ro_signo_reajuste,          ro_factor_reajuste,
             ro_referencial_reajuste,  ro_valor,                   ro_porcentaje,
             ro_gracia,                ro_porcentaje_aux,          ro_principal,
             ro_porcentaje_efa,        ro_concepto_asociado,       ro_garantia,
             ro_tipo_puntos,            ro_saldo_op,                ro_saldo_por_desem,
             ro_base_calculo,          ro_num_dec,                 ro_tipo_garantia,
             ro_nro_garantia,          ro_porcentaje_cobertura,    ro_valor_garantia,
             ro_tperiodo,              ro_periodo,                 ro_saldo_insoluto,
             ro_porcentaje_cobrar,     ro_iva_siempre)
      select @i_operacionca,           ru_concepto,                 ru_tipo_rubro,
             ru_fpago,                  ru_prioridad,                ru_paga_mora,
             'S',                       '+',                          0,
             ru_referencial,            '+',                           0,
             null,                      0,                             0,
             0,                         0,                          ru_principal,
             null,                      ru_concepto_asociado,        0,
             null,                      'N',                         'N',
             0,                         @i_num_dec,                  ru_tipo_garantia,
             null,                     'N',                         'N',
             null,                      null,                'N',
             0,                         ru_iva_siempre
      from   ca_rubro
      where  ru_toperacion = @w_toperacion
      and    ru_moneda     = @w_op_moneda
      and    ru_tipo_rubro =  'M'
      and    ru_concepto = @w_siglas_imo

      if @@error <> 0 return 710562

     --LRE 22/Mar/2019 Asignar el doble de la tasa de interes como tasa IMO
     select @w_ro_porcentaje = ro_porcentaje
     from cob_cartera..ca_rubro_op
     where ro_operacion = @i_operacionca
     and   ro_concepto  = @w_siglas_int

     if @@rowcount = 0
     begin
         print '(calcdimo.sp) Tasa de Interes. No se obtiene tasa Rubro INT' + cast(@w_ro_porcentaje as varchar)
         return 701130
     end

     select @w_ro_porcentaje = @w_ro_porcentaje * 2

     update cob_cartera..ca_rubro_op set ro_porcentaje = @w_ro_porcentaje
     where ro_operacion = @i_operacionca
     and   ro_concepto  = @w_siglas_imo

     if @@error <> 0
     begin
        print '(calcdimo.sp) Tasa de Interes Mora. Erros al actualizar tasa Rubro IMO'
        return 710002
     end

     --print 'Porc INT : ' + cast(@w_ro_porcentaje as varchar)
     --FIN LRE 22/Mar/2019 Asignar el doble de la tasa de interes como tasa IMO

   end

end



-- XMA NR-501
select @w_dias_anio_mora = dt_dias_anio_mora
from ca_default_toperacion
where dt_toperacion = @w_toperacion
and   dt_moneda     = @i_moneda

if @w_dias_anio_mora is null  or @w_dias_anio_mora = 0
   select @w_dias_anio_mora = 365

-- VARIABLES DE TRABAJO
select
@w_sp_name        = 'sp_calculo_diario_mora',
@w_am_secuencia   = 1,
@w_am_estado      = 1,
@w_primera_vez    = 1,
@w_secuencial     = null

create table #ca_rubro_imo_tmp_1(
ro_operacion          int      null,
ro_concepto           catalogo null,
ro_porcentaje         float    null,
ro_tipo_rubro         char(1)  null,
ro_provisiona         char(1)  null,
ro_fpago              char(1)  null,
ro_concepto_asociado  char(1)  null,
ro_valor              money    null,
ro_num_dec            tinyint  null,
ro_referencial        varchar(10)
)

delete #ca_rubro_imo_tmp_1 where ro_operacion = @i_operacionca

-- CARGA TABLA TEMPORAL DE TRABAJO
insert into #ca_rubro_imo_tmp_1
select
ro_operacion,         ro_concepto,    ro_porcentaje,
ro_tipo_rubro,        ro_provisiona,  ro_fpago,
ro_concepto_asociado, ro_valor,       ro_num_dec,
ro_referencial
from   ca_rubro_op
where  ro_operacion  = @i_operacionca
and    ro_tipo_rubro = 'M'
UNION                                                       --LRE 11/SEP/2019 Comision Pago Tardio para Grupales TEC
select
ro_operacion,         ro_concepto,    ro_porcentaje,
ro_tipo_rubro,        ro_provisiona,  ro_fpago,
ro_concepto_asociado, ro_valor,       ro_num_dec,
ro_referencial
from   ca_rubro_op
where  ro_operacion  = @i_operacionca
and    ro_concepto   = @w_siglas_com_pta
and    ro_tipo_rubro = 'Q'


if @@rowcount = 0 return 0 -- Si operacion no tiene rubros tipo mora SALIR


/* OTORGAR DIAS DE GRACIA AUTOMATICO EN CASO DE VENCIMIENTO EN FERIADO SI NO LO HIZO EL PROGRA DE VERIFICA VENCIMIENTO */
if @w_mora_retroactiva = 'S' begin

   --LRE 12-Mar-2019
   select @w_fecha_ini = @w_fecha_proceso
   while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @i_ciudad_nacional  and df_fecha = @w_fecha_ini )
   begin
         select @w_cont_gracia = @w_cont_gracia + 1
         select @w_fecha_ini = dateadd(dd,1,@w_fecha_ini)
   end

   update ca_dividendo set
   di_gracia      = @w_cont_gracia,
   di_gracia_disp = @w_cont_gracia
   where  di_operacion   = @i_operacionca
   and    di_fecha_ven   = @w_fecha_proceso
   and    di_gracia_disp = 0  --Si el programa de verifica vencimiento no le asigno, se lo hace aqui.

   if @@error <> 0
      return 705043

end


select @w_dias_int = @w_op_periodo_int * td_factor
from   ca_tdividendo
where  td_tdividendo = @w_op_tdividendo

if @w_estado_op = @i_est_suspenso
   select @w_estado = @i_est_suspenso
else
   if @w_estado_op = 4
      select @w_estado = 4
   else
      select @w_estado = @i_est_vencido


select @w_sig_dividendo = @w_min_div_vencido

/* LAZO PARA PROCESAR TODAS LAS CUOTAS DE ESTE RUBRO DE MORA */
while @w_sig_dividendo <= @w_max_div_vencido
begin

   select @w_mas_gracia = 0,
          @w_dias_calc = 1

   select
   @w_di_dividendo   = di_dividendo,
   @w_di_gracia_disp = di_gracia_disp,
   @w_di_fecha_ven   = di_fecha_ven,
   @w_di_gracia      = di_gracia
   from   ca_dividendo
   where  di_operacion  = @i_operacionca
   and    di_dividendo  = @w_sig_dividendo

   if @w_mora_retroactiva = 'S'
   begin

      if @w_di_gracia > 0
      begin
         if @w_di_gracia_disp > 0
         begin

            update ca_dividendo set
            di_gracia_disp = di_gracia_disp - 1
            where  di_operacion   = @i_operacionca
            and    di_dividendo   = @w_di_dividendo
            and    di_gracia_disp > 0

            if @@error <> 0  return 705043

            goto NEXTDIVIDENDO

         end
         else
         begin

            select @w_mas_gracia = @w_di_gracia
            select @w_di_gracia  = 0

            update ca_dividendo
            set di_gracia = -1 * di_gracia
            where di_operacion = @i_operacionca
            and   di_dividendo = @w_di_dividendo

            if @@error != 0 return 705043

         end --else
      end  --if (@w_di_gracia > 0

     if @w_mas_gracia <> 0
        select @w_dias_calc = @w_mas_gracia + @w_dias_calc

   end  --@w_mora_retroactiva = 'S'

   /* LAZO PARA PROCESAR TODOS LOS RUBROS DE MORA */
   select @w_ro_concepto = ''

   while 1 = 1
   begin

      select top 1
      @w_ro_concepto    = ro_concepto,
      @w_ro_porcentaje  = ro_porcentaje,
      @w_ro_referencial = ro_referencial,
      @w_ro_provisiona  = ro_provisiona
      from   #ca_rubro_imo_tmp_1
      where  ro_operacion = @i_operacionca
      and    ro_concepto > @w_ro_concepto
      order by ro_concepto

      if @@rowcount = 0 break

      /* DETERMINAR EL VALOR SOBRE EL CUAL SE COBRA LA MORA */
      select @w_monto_mora = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_rubro_op, ca_amortizacion
      where  ro_operacion =  @i_operacionca
      and    ro_paga_mora = 'S'
      and    am_operacion = ro_operacion
      and    am_concepto  = ro_concepto      --LRE 21/Mar/2019
      and    am_dividendo = @w_di_dividendo + charindex('A', ro_fpago)

      select
      @w_valor_calc     = 0,
      @w_monto_mora     =  isnull(@w_monto_mora,0)

      if @w_monto_mora > 0 begin

            select @w_am_secuencia = isnull(max(am_secuencia),1)
            from   ca_amortizacion
            where  am_operacion    = @i_operacionca
            and    am_dividendo    = @w_di_dividendo
            and    am_concepto     = @w_ro_concepto

            select
            @w_am_estado  = am_estado,
            @w_am_periodo = am_periodo
            from   ca_amortizacion
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_di_dividendo
            and    am_concepto  = @w_ro_concepto
            and    am_secuencia = @w_am_secuencia

            if @@rowcount = 0 begin

               insert ca_amortizacion(
               am_operacion,   am_dividendo,      am_concepto,
               am_estado,      am_periodo,        am_cuota,
               am_gracia,      am_pagado,         am_acumulado,
               am_secuencia )
               values(
               @i_operacionca, @w_di_dividendo,   @w_ro_concepto,
               @w_estado_op,   0,                 0,               -- KDR Ingreso de la Mora a la Amortización según estado de operación
               0,              0,                 0,
               1)

               if @@error <> 0 return 703079

            end


            if (@w_monto_mora <> 0) begin
               if @w_ro_porcentaje > 0 begin
                  select @w_monto_mora = round(@w_monto_mora, @i_num_dec)

                  exec @w_error = sp_calc_intereses -- DE UN DIA EXPONENCIAL
                       @tasa           = @w_ro_porcentaje,
                       @monto          = @w_monto_mora,
                       @dias_anio      = @w_dias_anio_mora,
                       @num_dias       = @w_dias_calc,
                       @causacion      = 'L',
                       @causacion_acum = 0,
                       @intereses      = @w_valor_calc out

                  if @w_error <> 0 return @w_error

                end

               select @w_valor_calc   = round(@w_valor_calc, @i_num_dec)
            end

            select @w_valor_calc = isnull(@w_valor_calc, 0)
            select @w_valor_calc_mn = round(@w_valor_calc*@i_cotizacion,@i_num_dec_mn)

            select @w_codvalor = co_codigo * 1000 + @w_am_estado * 10 + 0
            from   ca_concepto
            where  co_concepto = @w_ro_concepto

            if @w_valor_calc <> 0 begin

              if @w_ro_provisiona = 'S'  --LRE 12/Sep/2019  Generar provision solo para rubros que provisionan segun parametrizacion
              begin

                 /* Insertar en tabla de transacciones de PRV */
                 insert into ca_transaccion_prv with (rowlock)(
                 tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
                 tp_secuencial_ref,   tp_estado,           tp_dividendo,
                 tp_concepto,         tp_codvalor,         tp_monto,
                 tp_secuencia,        tp_ofi_oper,         tp_comprobante,
                 tp_monto_mn,         tp_moneda,           tp_cotizacion,
                 tp_tcotizacion,      tp_reestructuracion)
                 values(
                 @s_date,            @i_operacionca,      @i_fecha_proceso,
                 0,                  'ING',               @w_di_dividendo,     ---Estado no contabiliza (NCO)
                 @w_ro_concepto,     @w_codvalor,         @w_valor_calc,
                 @w_am_secuencia,    @w_oficina_op,       0,
                 round(@w_valor_calc*@i_cotizacion,@i_num_dec_mn), @w_op_moneda, @i_cotizacion,
                 'N',                @w_reestructuracion)

                 if @@error <> 0 return 708165
              end

              if @w_valor_calc < 0
                 return 710299  -- Error  saldo  mora  ven < 0

              update ca_amortizacion
              set    am_cuota      = @w_valor_calc  +  am_acumulado,
                     am_acumulado  = @w_valor_calc  +  am_acumulado
              where  am_operacion = @i_operacionca
              and    am_dividendo = @w_di_dividendo
              and    am_concepto  = @w_ro_concepto
              and    am_secuencia = @w_am_secuencia

              if @@error <> 0 return 705050

               ---PARA VERIFICAR SOBRE QUE BASE SE COBRA LA MORA
              update ca_rubro_op
              set    ro_base_calculo = @w_monto_mora
              where  ro_operacion = @i_operacionca
              and    ro_concepto  = @w_ro_concepto

               select @w_valor_calc = 0
            end  -- @w_valor_calc <> 0

            --LRE 22/Mar/2019 Registrar el dividendo en el historico de tasas
            if not exists(select 1 from ca_tasas
                 where ts_operacion = @i_operacionca
                 and   ts_dividendo = @w_di_dividendo
                 and   ts_concepto  = @w_ro_concepto)
            begin

               exec @w_secuencial = sp_gen_sec
                     @i_operacion = @i_operacionca

                insert into ca_tasas (
              ts_operacion,       ts_dividendo,     ts_fecha,
                 ts_concepto,        ts_porcentaje,    ts_secuencial,
                 ts_porcentaje_efa,  ts_referencial,   ts_signo,
                 ts_factor )
              values(
              @i_operacionca,     @w_di_dividendo,  @w_fecha_proceso,
                 @w_ro_concepto,     @w_ro_porcentaje, @w_secuencial,
                 0,           NULL,             '+',
                 0)

                if @@error <> 0
                   return 703118
            end

            --FIN LRE 22/Mar/2019 Registrar el dividendo en el historico de tasas

            --CALCULO DEL IVA_IMO
            exec @w_error     = sp_otros_cargos
            @s_date           = @s_date,
             @s_user           = 'usrbatch',
             @s_term           = 'consola',
             @s_ofi            = @w_oficina_op,
             @i_banco          = @w_banco,
             @i_moneda         = @w_op_moneda,
             @i_operacion      = 'A',
             @i_toperacion     = @w_toperacion,
             @i_desde_batch    = 'N',
             @i_en_linea       = 'N',
             @i_tipo_rubro     = 'O',
             @i_concepto       = @w_ro_concepto,
             @i_monto          = 0,
             @i_div_desde      = @w_di_dividendo,
             @i_div_hasta      = @w_di_dividendo,
             @i_comentario     = 'GENERADO POR: sp_calculo_diario_mora',
            @i_fecha_proceso  = @i_fecha_proceso

             if @w_error <> 0 return @w_error

      end  --@w_monto_mora > 0

   end -- WHILE rubros

   NEXTDIVIDENDO:
   select @w_sig_dividendo = @w_sig_dividendo + 1

end   --while dividendos

delete #ca_rubro_imo_tmp_1
where  ro_operacion = @i_operacionca

return 0


go
