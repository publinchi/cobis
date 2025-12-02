/************************************************************************/
/*Archivo               :    Cainfext.sp                                */
/*Stored procedure      :    sp_info_extractos                          */
/*Base de datos         :    cob_cartera                                */
/*Producto              :    Cartera                                    */
/*Disenado por          :    Jorge Latorre                              */
/*Fecha de escritura    :    dic 19 2000                                */
/************************************************************************/
/*                       IMPORTANTE                                     */
/*Este programa es parte de los paquetes bancarios propiedad de         */
/*'MACOSA'.                                                             */
/*Su uso no autorizado queda expresamente prohibido asi como            */
/*cualquier alteracion o agregado hecho por alguno de sus               */
/*usuarios sin el debido consentimiento por escrito de la               */
/*Presidencia Ejecutiva de MACOSA o su representante.                   */
/*PROPOSITO                                                             */
/*                                                                      */ 
/*I: poblar una tabla para estraccion de extractos                      */
/*                            MODIFICACIONES                            */
/*      FECHA             AUTOR                       RAZON             */
/*     06/09/2003       Julio C Quintero    Modificaci½n Obtenci½n Ciu- */
/*                                          dad, Seguros Anticipados,   */
/*                                          Conceptos en Pesos para     */
/*                                          L­neas en UVR, Tasas INT    */
/*                                          e IMO efectivas             */
/*     ABR-17-2004      Elcira Pelaez        Cambio solicitado por WM   */
/*                                           para excluir las op. con   */
/*                                           clausula o > 90 dias       */
/*     MAR -2005        Elcira Pelaez        NR-F3-012  MEnsaje         */
/*     ene -2005        Xavier Maldonado     NR-381  MEnsaje            */
/*     ABR-2006         ElciraPelaez         NR-379  Traslado a CXCINTES*/
/*     MAYO-2006        ElciraPelaez         NR-012-381 des_moneda      */
/*                                           ULT:ACT:JUN-15-2006        */
/*     JUNIO-2006       ElciraPelaez         DEF. 6759 fecha fact       */
/*     JULIO-2006       ElciraPelaez         DEF. 6815 COND             */
/*     JULIO-2006       ElciraPelaez         DEF. 6857 BAC              */
/*     Agos-2-2007      Sandra Lievano       NR794 crédito rotativo     */
/*     Febr-2-2021      K. Rodríguez         Se comenta uso de concepto */
/*                                           CXCINTES                   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_info_extractos')
   drop proc sp_info_extractos
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_info_extractos
        @i_fecha_ini           datetime,
        @i_fecha_fin           datetime,
        @i_fecha_fact          datetime
as
declare
   @w_sp_name                     descripcion,
   @w_operacionca                 int,
   @w_return                      int,
   @w_error                       int,
   @w_ente                        int,
   @w_nombre                      descripcion, 
   @w_ie_numero_obligacion        cuenta,
   @w_ie_tipo_producto            catalogo,
   @w_descripcion_linea           varchar(50),
   @w_ie_oficina_obligacion       smallint,
   @w_descripcion_ofi             varchar(20),
   @w_ie_nombre                   descripcion,
   @w_ie_direccion                varchar(60),
   @w_ie_ciudad                   descripcion,
   @w_ie_fecha_proceso            datetime,  
   @w_ie_saldo_cap                money,
   @w_ie_numero_cuota             smallint,  
   @w_ie_saldo_mora_cap           money,
   @w_ie_num_cuotas_enmora        smallint,
   @w_ie_frecuencia_int           varchar(25),  
   @w_ie_frecuencia_cap           varchar(25),  
   @w_ie_mora_desde               datetime,
   @w_op_migrada                  cuenta,
   @w_ie_abono_capital_ant        money,
   @w_ie_abono_int_ant            money,  
   @w_ie_abono_intmora_ant        money,
   @w_ie_seguros_ant              money,
   @w_ie_otros_cargos_ant         money,
   @w_ie_total_abono_ant          money,
   @w_ie_abono_capital            money,
   @w_ie_abono_int                money,  
   @w_ie_abono_intmora            money,
   @w_ie_seguros                  money,
   @w_ie_seguros_anticipado       money,
   @w_ie_otros_cargos             money,
   @w_ie_total_abono              money,
   @w_ie_fecha_ven                datetime,
   @w_op_periodo_int              smallint,
   @w_op_tdividendo               catalogo,
   @w_op_periodo_cap              smallint,
   @w_op_estado                   tinyint,    
   @w_td_factor                   smallint,
   @w_ro_fpago                    char(1),
   @w_di_dividendo                smallint,
   @w_op_dias_anio                smallint, 
   @w_op_reajustable              char(1),
   @w_op_cliente                  int,
   @w_op_ciudad                   int,
   @w_ab_secuencial_pag           int,
   @w_mora                        money,
   @w_intereses                   money,
   @w_seguro                      money,
   @w_otros_cargos                money,
   @w_producto                    tinyint,
   @w_descripcion                 varchar(64),
   @w_referencial                 catalogo,
   @w_cod_ciudad                  int,     
   @w_max_secuencial              int,
   @w_moneda                      int,
   @w_moneda_nacional             tinyint,
   @w_pago                        money,
   @w_numero_cuota_vig            int,
   @w_ie_tasa_efectiva            float,
   @w_ie_tasa_nominal_int         float,
   @w_op_fecha_liq                datetime,
   @w_op_monto                    money,
   @w_provincia                   int,
   @w_ie_dpto                     varchar(20),
   @w_ie_des_moneda               varchar(64),
   @w_tabla_linea                 int,
   @w_di_direccion                int,
   @w_ie_total_cuotas             smallint,
   @w_ie_num_cuotas_canceladas    smallint,
   @w_ie_otrosc_anticipado        money,
   @w_ab_secuencial_ing           int,
   @w_ie_total_abono_ant1         money,
   @w_dias_mora                   int,
   @w_min_fecha_ven               datetime,
   @w_op_direccion                tinyint,
   @w_op_tipo_amortizacion        char(15),
   @w_tasa_pactada                varchar(30),
   @w_signo                       char(1),
   @w_puntos                      money,
   @w_puntos_c                    char(15),
   @w_fpago                       char(1),
   @w_tasa_mercado                varchar(10),
   @w_cotizacion                  float,
   @w_cotizacion_ini              float,
   @w_cuotas_no_cobradas          char(15),
   @w_minima_cuotas_ven           int,
   @w_op_tplazo                   catalogo,
   @w_dias_plazo                  int,
   @w_plazo_en_meses              catalogo,
   @w_ie_saldo_cap_u              float,     
   @w_ie_saldo_mora_cap_u         float,
   @w_ie_abono_capital_ant_u      float,
   @w_ie_abono_int_ant_u          float,
   @w_ie_abono_intmora_ant_u      float,
   @w_ie_seguros_ant_u            float,
   @w_ie_otros_cargos_ant_u       float,
   @w_plazo                       int,
   @w_ie_total_abono_ant_u        float,
   @w_ie_abono_capital_u          float,
   @w_ie_abono_int_u              float,
   @w_ie_abono_intmora_u          float,
   @w_ie_seguros_u                float,
   @w_ie_otros_cargos_u           float,
   @w_ie_total_abono_u            float,
   @w_ie_monto_u                  float,
   @w_intereses_u                 float,
   @w_referencial_t               catalogo,
   @w_op_sector                   catalogo,
   @w_op_tdividendo_aux           catalogo,
   @w_di_dias_cuota               int,
   @w_max_div_oper                int,
   @w_moneda_nac                  smallint,
   @w_num_dec_mon_op              smallint,
   @w_num_dec_mon_nac             smallint,
   @w_di_fecha_ini                datetime,
   @w_di_fecha_fin                datetime,
   @w_op_anterior                 cuenta,
   @w_op_monto_aprobado           money,
   @w_total_dias                  float,
   @w_total_dias_1                int,
   @w_cola_mes                    int,
   @w_ie_referencia               varchar(255),
   @w_op_tramite                  int,
   @w_toperacion                  catalogo,          
   @w_codregional                 smallint,
   @w_tr_tipo_prod                varchar(24),
   @w_sujeto_credito              catalogo,
   @w_tr_destino                  catalogo,
   @w_zona                        smallint,
   @w_tr_mercado                  catalogo,
   @w_tr_mercado_ob               catalogo,
   @w_tipo_banca                  catalogo,
   @w_extracto                    char(1),
   @w_ab_secuencial_min_pag       int,
   @w_ab_secuencial_max_pag       int,
   @w_ab_secuencial_min_ing       int,
   @w_ab_secuencial_max_ing       int,
   @w_parametro_cxcintes          catalogo,   ---NR 379
   @w_concepto_traslado           catalogo,    ---NR 379
   @w_cxcintes_ven                money,        ---NR 379
   @w_cxcinte_vigentes            money,         --- NR 379
   @w_op_fecha_embarque           datetime,  ---281
   @w_reloj                       datetime,
   --SLI NR794
   @w_op_tipo                     char(1),
   @w_ie_cupo_total               money,
   @w_ie_cargos                   money,
   @w_ie_abonos                   money,
   @w_total_abonos                money,
   @w_ie_cupo_disponible          money,
   @w_ie_pago_total               money,
   @w_rowcount                    int

--- NOMBRE DEL SP Y FECHA DE HOY 
select @w_sp_name  = 'sp_info_extractos',
       @w_ie_total_abono_ant1  = 0,
       @w_dias_mora            = 0,
       @w_intereses_u          = 0

--- MONEDA NACIONAL JCQ 06/09/2003 
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

--- TOMA DE TABLAS PARA CATALOGOS 
select @w_tabla_linea = codigo
from   cobis..cl_tabla
where  tabla = 'ca_toperacion'
set transaction isolation level read uncommitted

-- borra las operaciones_anteriores
delete cob_cartera..ca_info_extracto WHERE ie_numero_obligacion >= ''


select @w_producto = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted 

--NR 281
select @w_ie_fecha_proceso = fc_fecha_cierre 
from   cobis..ba_fecha_cierre
where  fc_producto = @w_producto

if not exists (select 1
               from cob_conta..cb_cotizacion
               where ct_fecha = @i_fecha_fin
               and   ct_moneda = 2)
begin
   PRINT 'ERROR!!! PARAMETRIZACIONNN  NO EXISTE Cotiz fecha  ' + cast(@i_fecha_fin as varchar)
   
   insert ca_errorlog
         (er_fecha_proc,   er_error,   er_usuario,
          er_tran,   er_cuenta,   er_descripcion,
          er_anexo)
   values(@w_ie_fecha_proceso,   708177,   'batch',
          0, '', 'NO ESTAN TODAS LAS COTIZACIONES PARA LA GENERACION DEL EXTRACTO',
          'NO SE GENERO LA FACTURACION')
   return 0
end                     

-- FECHA DE PROCESO
-- NR 379
select @w_parametro_cxcintes = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CXCINT'
set transaction isolation level read uncommitted

/*  -- KDR Sección no aplica para la versión de Finca
select @w_concepto_traslado  = co_concepto
from   ca_concepto
where  co_concepto = @w_parametro_cxcintes

if @@rowcount = 0 
   return 711017
*/ -- FIN KDR

-- CREA LA TABLA TEMPORAL
select op_operacion,op_banco,      op_toperacion,     op_oficina,             op_nombre, 
       op_cliente,  op_ciudad,     op_periodo_int,    op_tdividendo,          op_periodo_cap,
       op_estado,   op_migrada,    op_fecha_liq,      op_monto,               op_direccion,
       op_moneda,   op_tplazo,      op_sector,      op_tipo_amortizacion,   op_plazo,
       op_anterior, op_monto_aprobado,  op_tramite, op_fecha_embarque,      op_tipo 
into   #ca_operacion_aux
from   ca_operacion
where  op_tipo    != 'R'  -- JCQ 06/12/2003 Se excluyen las operaciones pasivas
and    op_extracto = 'S'
and    op_clausula_aplicada = 'N'
and    op_estado  != 4
and    isnull(op_estado_cobranza, 'CN') != 'CJ'
and    op_estado in (select es_codigo from ca_estado where es_procesa = 'S')

declare
   operaciones cursor
   for select op_operacion,   op_banco,          op_toperacion,  op_oficina,          op_nombre, 
              op_cliente,     op_ciudad,         op_periodo_int, op_tdividendo,       op_periodo_cap,
              op_estado,      op_migrada,        op_fecha_liq,   op_monto,            op_direccion, 
              op_moneda,      op_tplazo,         op_sector,      op_tipo_amortizacion,   op_plazo,
              op_anterior,    op_monto_aprobado,   op_tramite,   isnull(op_fecha_embarque,op_fecha_liq), op_tipo
       from   #ca_operacion_aux
   for read only

open operaciones
      
fetch operaciones
into  @w_operacionca,   @w_ie_numero_obligacion,    @w_ie_tipo_producto,   @w_ie_oficina_obligacion, @w_ie_nombre,
      @w_op_cliente,    @w_op_ciudad,               @w_op_periodo_int,     @w_op_tdividendo,         @w_op_periodo_cap,
      @w_op_estado,     @w_op_migrada,              @w_op_fecha_liq,       @w_op_monto,              @w_op_direccion,
      @w_moneda,        @w_op_tplazo,               @w_op_sector,          @w_op_tipo_amortizacion,  @w_plazo,
      @w_op_anterior,   @w_op_monto_aprobado,       @w_op_tramite,         @w_op_fecha_embarque, @w_op_tipo

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin

print '@w_operacionca ' + cast(@w_operacionca as varchar) + ' @w_op_tipo '  + cast(@w_op_tipo as varchar)

   select @w_min_fecha_ven = isnull(min(di_fecha_ven), @w_ie_fecha_proceso)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado in (1, 2)
   
   select @w_dias_mora = datediff(dd, @w_min_fecha_ven, @w_ie_fecha_proceso)
   
   if @w_dias_mora < 0
      select  @w_dias_mora = 0
   
   select @w_extracto = 'N'
   
   if   @w_dias_mora < 200 --90
   and  exists(select 1
               from   ca_dividendo 
               where  di_operacion = @w_operacionca
               and    di_fecha_ven between @i_fecha_ini and @i_fecha_fin
               and    di_estado in (1,2))
   begin
     print '1'
      select @w_extracto = 'S'
   end
   else
      select @w_extracto = 'N'
   
 
   if @w_extracto = 'S'
   begin
      ---NR 381
      if @w_op_fecha_embarque is null
         select @w_op_fecha_embarque = @w_ie_fecha_proceso
      
      --- SACAR EL NUMERO DE DECIMALES PARA REDONDEO 
      exec @w_error   = sp_decimales
           @i_moneda       = @w_moneda,
           @o_decimales    = @w_num_dec_mon_op out,
           @o_mon_nacional = @w_moneda_nac out,
           @o_dec_nacional = @w_num_dec_mon_nac out
      
           
      --- NUMERO DE CUOTA  QUE PAGA 
      select @w_ie_numero_cuota = 0
      
      select @w_ie_numero_cuota = isnull(max(di_dividendo),0)
      from   ca_dividendo 
      where  di_operacion = @w_operacionca  
      and    di_estado    = 1
      
      --- FECHA DE VENCIMIENTO DE LA CUOTA A PAGAR
      select @w_ie_fecha_ven = di_fecha_ven
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      and    di_dividendo   = @w_ie_numero_cuota
      
      if @@rowcount = 0 
      begin
         select @w_ie_fecha_ven = min(di_fecha_ven) 
         from   ca_dividendo
         where  di_operacion = @w_operacionca
         and    di_estado = 2
      end
      
      if  @w_moneda <> @w_moneda_nacional
      begin
      
         exec sp_buscar_cotizacion
              @i_moneda     = @w_moneda,
              @i_fecha      = @w_ie_fecha_ven,
              @o_cotizacion = @w_cotizacion output
      end
      ELSE
      begin
         select @w_cotizacion   = 1,
                @w_num_dec_mon_op  = @w_num_dec_mon_nac
      end
      
      -- DIRECCION
      -- CIUDAD JCQ 05/23/2003 QUE CORRESPONDE A LA DIRECCION
      select @w_ie_direccion = di_descripcion,
             @w_cod_ciudad   = di_ciudad,
             @w_di_direccion = di_direccion
      from   cobis..cl_direccion  
      where  di_ente = @w_op_cliente
      and    di_direccion = @w_op_direccion
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted
      
      if @w_rowcount = 0 
      begin
         ---SACA LA PRIMERA QUE ENCUENTRA
         select @w_ie_direccion = di_descripcion,
                @w_cod_ciudad   = di_ciudad,
                @w_di_direccion = di_direccion
         from   cobis..cl_direccion  
         WHERE  di_ente = @w_op_cliente
         and    di_direccion = 1
         set transaction isolation level read uncommitted
      end
      
      
      --CIUDAD
      select @w_ie_ciudad = ci_descripcion,
             @w_provincia = ci_provincia
      from   cobis..cl_ciudad
      where  ci_ciudad = @w_cod_ciudad 
      set transaction isolation level read uncommitted
      
      select @w_ie_dpto = pv_descripcion 
      from cobis..cl_provincia
      where  pv_provincia = @w_provincia
      set transaction isolation level read uncommitted
      
      ---SACA TELEFONO DE LA DIRECCION
      Select @w_ie_des_moneda = ''
      
      Select @w_ie_des_moneda = mo_descripcion
      from   cobis..cl_moneda
      where  mo_moneda  = @w_moneda
      
      --SALDO DE CAPITAL
      select @w_ie_saldo_cap = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
      from   ca_concepto, ca_amortizacion 
      where  co_concepto = am_concepto 
      and    co_categoria  = 'C'
      and    am_operacion  = @w_operacionca
      
      select @w_ie_saldo_cap_u = 0
      select @w_ie_saldo_cap_u = @w_ie_saldo_cap
      
      -- TASA CORRIENTE EFECTIVA
      select @w_ie_tasa_efectiva = isnull(sum(ro_porcentaje_efa) ,0.00)
      from   ca_rubro_op 
      where  ro_operacion = @w_operacionca  
      and    ro_tipo_rubro = 'I'
      
      --TASA DE NOMINAL INT
      select @w_ie_tasa_nominal_int = isnull(sum(ro_porcentaje) ,0.00)
      from   ca_rubro_op 
      where  ro_operacion = @w_operacionca  
      and    ro_tipo_rubro = 'I'
      
      -- PARA LA CUOTA NO VIGENTE DE SEGUROS, NO DEBE INCLUIR RANGO DE FECHAS
      select @w_numero_cuota_vig = 0
      
      select @w_numero_cuota_vig = isnull(max(di_dividendo) ,0)
      from   ca_dividendo 
      where  di_operacion = @w_operacionca  
      and    di_estado = 1
      
      if @@rowcount = 0
         select @w_numero_cuota_vig = 0
      
      -- SALDO EN MORA CAPITAL
      select @w_ie_saldo_mora_cap = isnull(sum(am_cuota + am_gracia - am_pagado),0)  
      from   ca_dividendo, ca_amortizacion, ca_concepto
      where  am_dividendo = di_dividendo  
      and    co_concepto = am_concepto 
      and    co_categoria = 'C'
      and    di_estado = 2
      and    am_operacion = di_operacion 
      and    am_operacion = @w_operacionca   
      
      select @w_ie_saldo_mora_cap_u = 0
      select @w_ie_saldo_mora_cap_u = @w_ie_saldo_mora_cap
      
      -- NUMERO DE CUOTAS EN MORA
      select @w_ie_num_cuotas_enmora = 0
      
      select @w_ie_num_cuotas_enmora = isnull(count(1),0)
      from   ca_dividendo
      where  di_estado = 2
      and    di_operacion = @w_operacionca
      
      -- DESCRIPCION DE CATALOGO
      select @w_descripcion = td_descripcion
      from   ca_tdividendo
      where  td_tdividendo = @w_op_tdividendo
      
      --EPB:DEFECTO NO.3450
      select @w_max_div_oper = max(di_dividendo)
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      
      select @w_di_dias_cuota = di_dias_cuota
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      and    di_dividendo = @w_max_div_oper
      
      select @w_op_tdividendo_aux = @w_op_tdividendo
      
      select @w_op_tdividendo = td_tdividendo
      from ca_tdividendo
      where td_factor = @w_di_dias_cuota
      
      if @w_op_tdividendo is null 
         select @w_op_tdividendo = @w_op_tdividendo_aux
      
      --EPB:defecto No.3450
      -- FRECUENCIA DE PAGO INTERES
      select @w_ie_frecuencia_int = substring(convert(varchar, @w_op_periodo_int) + ' ' + @w_descripcion, 1, 18)
      
      -- FRECUENCIA DE PAGO CAPITAL 
      select @w_ie_frecuencia_cap = substring(convert(varchar, @w_op_periodo_cap) + ' ' + @w_descripcion, 1, 18)
      
      -- MORA DESDE
      select @w_ie_mora_desde = min(di_fecha_ven) 
      from   ca_dividendo
      where  di_estado = 2
      and    di_operacion = @w_operacionca
      
      -- ULTIMO ABONO
      select @w_ab_secuencial_pag = max(ab_secuencial_pag)
      from   ca_abono
      where  ab_estado = 'A' 
      and    ab_operacion = @w_operacionca
      
      select @w_ab_secuencial_min_pag = 0
      
      -- RANGO MINIMO DE ABONO   ---XMA NR_381
      select @w_ab_secuencial_min_pag = isnull(min(ab_secuencial_pag), 0)
      from   ca_abono
      where  ab_estado = 'A' 
      and    ab_operacion = @w_operacionca
      and    ab_fecha_pag >= @w_op_fecha_embarque 
      
      select @w_ab_secuencial_max_pag = 0
      
      -- RANGO MAXIMO DE ABONO   ---XMA NR_381
      select @w_ab_secuencial_max_pag = isnull(max(ab_secuencial_pag), 0)
      from   ca_abono
      where  ab_estado = 'A' 
      and    ab_operacion = @w_operacionca
      and    ab_fecha_pag <= @w_ie_fecha_proceso
      
      -- ABONO ANTERIOR CAPITAL 
      select @w_ie_abono_capital_ant = round(isnull(sum(dtr_monto_mn),0),0)
      from   ca_abono, ca_det_trn, ca_concepto
      where  ab_estado = 'A' 
      and    co_categoria = 'C'
      and    ab_operacion = @w_operacionca
      and    dtr_concepto = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      and    dtr_codvalor  not in(10099, 10019, 10370)
      
      select @w_ie_abono_capital_ant_u = 0
      
      select @w_ie_abono_capital_ant_u = round (isnull(sum(dtr_monto),0),@w_num_dec_mon_op)
      from   ca_abono,ca_det_trn, ca_concepto  
      where  ab_estado = 'A' 
      and    co_categoria = 'C'
      and    ab_operacion = @w_operacionca
      and    dtr_concepto = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      and    dtr_codvalor  not in(10099, 10019, 10370)
      
      -- ABONO ANTERIOR INTERESES CORRIENTES 
      select @w_ie_abono_int_ant = round(isnull(sum(dtr_monto_mn),0),0)
      from   ca_abono,ca_det_trn, ca_concepto  
      where  ab_estado = 'A' 
      and    co_categoria = 'I'
      and    ab_operacion = @w_operacionca
      and    dtr_concepto = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      
      select @w_ie_abono_int_ant_u = 0
      select @w_ie_abono_int_ant_u = round(isnull(sum(dtr_monto),0),@w_num_dec_mon_op)
      from   ca_abono,ca_det_trn, ca_concepto  
      where  ab_estado = 'A' 
      and    co_categoria = 'I'
      and    ab_operacion = @w_operacionca
      and    dtr_concepto = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      
      -- Abono ANTERIOR INTERESES MORA 
      select @w_ie_abono_intmora_ant = round(isnull(sum(dtr_monto_mn),0) ,0)
      from   ca_abono,ca_det_trn, ca_concepto  
      where  ab_estado = 'A' 
      and    co_categoria = 'M'
      and    ab_operacion = @w_operacionca
      and    dtr_concepto = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      
      select @w_ie_abono_intmora_ant_u = 0
      select @w_ie_abono_intmora_ant_u = round(isnull(sum(dtr_monto),0) ,@w_num_dec_mon_op)
      from   ca_abono,ca_det_trn, ca_concepto  
      where  ab_estado = 'A' 
      and    co_categoria = 'M'
      and    ab_operacion = @w_operacionca
      and    dtr_concepto = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      
      -- Abono ANTERIOR SEGUROS 
      select @w_ie_seguros_ant = round(isnull(sum(dtr_monto_mn),0),0)
      from   ca_abono,ca_det_trn, ca_concepto  
      where  ab_estado       = 'A' 
      and    co_categoria      = 'S'
      and    ab_operacion      = @w_operacionca
      and    dtr_concepto      = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      
      select @w_ie_seguros_ant_u = 0
      select @w_ie_seguros_ant_u = round(isnull(sum(dtr_monto),0),@w_num_dec_mon_op)
      from   ca_abono,ca_det_trn, ca_concepto  
      where  ab_estado       = 'A' 
      and    co_categoria      = 'S'
      and    ab_operacion      = @w_operacionca
      and    dtr_concepto      = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      
      -- ABONO ANTERIOR OTROS 
      select @w_ie_otros_cargos_ant = round(isnull(sum(dtr_monto_mn),0),0)
      from   ca_abono,ca_det_trn, ca_concepto  
      where  ab_estado = 'A' 
      and    co_categoria NOT IN ('S','M','I','C')
      and    ab_operacion = @w_operacionca
      and    dtr_concepto = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      
      select @w_ie_otros_cargos_ant_u = 0
      select @w_ie_otros_cargos_ant_u = round(isnull(sum(dtr_monto),0),@w_num_dec_mon_op)
      from   ca_abono,ca_det_trn, ca_concepto  
      where  ab_estado = 'A' 
      and    co_categoria NOT IN ('S','M','I','C')
      and    ab_operacion = @w_operacionca
      and    dtr_concepto = co_concepto
      and    ab_secuencial_pag = dtr_secuencial
      and    ab_operacion      = dtr_operacion
      and    ab_secuencial_pag between @w_ab_secuencial_min_pag  and @w_ab_secuencial_max_pag
      
      -- TOTAL ABONO ANTERIOR
      select @w_ie_total_abono_ant1 = isnull(sum(@w_ie_abono_capital_ant + @w_ie_abono_int_ant + @w_ie_abono_intmora_ant + @w_ie_seguros_ant + @w_ie_otros_cargos_ant),0)
      
      select @w_ie_total_abono_ant1 = round(@w_ie_total_abono_ant1,@w_num_dec_mon_op)
      
      select @w_ie_total_abono_ant = 0
      
      if @w_ie_total_abono_ant1 > 0
      begin
         select @w_ab_secuencial_ing = ab_secuencial_ing
         from   ca_abono
         where  ab_operacion = @w_operacionca
         and    ab_secuencial_pag = @w_ab_secuencial_pag
         
         -- XMA NR_381
         select @w_ab_secuencial_min_ing = ab_secuencial_ing
         from   ca_abono
         where  ab_operacion = @w_operacionca
         and    ab_secuencial_pag = @w_ab_secuencial_min_pag
         
         select @w_ab_secuencial_max_ing = ab_secuencial_ing
         from   ca_abono
         where  ab_operacion = @w_operacionca
         and    ab_secuencial_pag = @w_ab_secuencial_max_pag
         
         select @w_ie_total_abono_ant = round(isnull(sum(abd_monto_mn),0),@w_num_dec_mon_op) 
         from   ca_abono_det
         where  abd_operacion = @w_operacionca
         and    abd_secuencial_ing between @w_ab_secuencial_min_ing  and @w_ab_secuencial_max_ing   ---XMA=  @w_ab_secuencial_ing
         
         select @w_ie_total_abono_ant_u = round(isnull(sum(abd_monto_mop),0),@w_num_dec_mon_op)
         from   ca_abono_det
         where  abd_operacion = @w_operacionca
         and    abd_secuencial_ing between @w_ab_secuencial_min_ing  and @w_ab_secuencial_max_ing   ---XMA=  @w_ab_secuencial_ing
      end
      
      -- ABONO CAPITAL CUOTA A PAGAR
      select @w_ie_abono_capital = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_concepto, ca_amortizacion, ca_dividendo
      where  co_concepto = am_concepto
      and    am_operacion = @w_operacionca
      and    co_categoria = 'C'
      and    di_estado = 1
      and    am_operacion = di_operacion
      and    am_dividendo = di_dividendo
      
      select @w_ie_abono_capital   = @w_ie_abono_capital + @w_ie_saldo_mora_cap     
      select @w_ie_abono_capital_u = 0
      select @w_ie_abono_capital_u = @w_ie_abono_capital
      
      -- INTERESES CORRIENTES VENCIDOS
      select @w_intereses = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_dividendo, ca_amortizacion, ca_concepto
      where  am_dividendo = di_dividendo  
      and    co_concepto = am_concepto 
      and    co_categoria = 'I'
      and    di_estado = 2
      and    am_operacion = di_operacion
      and    am_operacion = @w_operacionca
      
      -- NR 379 INTERESES CORRIENTES VENCIDOS CXCINTES
      select @w_cxcintes_ven = 0
      select @w_cxcintes_ven = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_dividendo, ca_amortizacion
      where  am_dividendo = di_dividendo  
      and    di_estado = 2
      and    am_operacion = di_operacion
      and    am_operacion = @w_operacionca
      and    am_concepto = @w_concepto_traslado
      
      select @w_intereses = @w_intereses +   @w_cxcintes_ven   
      select @w_intereses_u  =  @w_intereses
      
      -- INTERESES CORRIENTES VIGENTES
      select @w_ie_abono_int = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
      from   ca_concepto, ca_amortizacion, ca_dividendo 
      where  co_concepto = am_concepto 
      and    am_operacion = @w_operacionca                      
      and    co_categoria = 'I'
      and    am_dividendo = @w_ie_numero_cuota  
      and    am_operacion = di_operacion
      and    am_dividendo = di_dividendo
      
      --NR 379 SI LOS INTERESES VAN A SER TRASLADADOS ESTOS SE COLCOAN EN 0
      if exists (select 1
                 from   ca_traslado_interes
                 where  ti_operacion = @w_operacionca
                 and    ti_cuota_orig = @w_ie_numero_cuota)
         select @w_ie_abono_int = 0.0
      
      --NR 379 CXCINTES VIGENTES
      select @w_cxcinte_vigentes = 0
      select @w_cxcinte_vigentes = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
      from   ca_amortizacion, ca_dividendo 
      where  am_operacion = @w_operacionca                      
      and    am_dividendo = @w_ie_numero_cuota  
      and    am_operacion = di_operacion
      and    am_dividendo = di_dividendo
      and    am_concepto  = @w_concepto_traslado
      
      select  @w_ie_abono_int_u = @w_ie_abono_int + @w_cxcinte_vigentes
      select  @w_ie_abono_int   = @w_ie_abono_int + @w_intereses + @w_cxcinte_vigentes
      select  @w_ie_abono_int_u = @w_ie_abono_int_u + @w_intereses_u
      
      -- INTERESES DE MORA ACTUAL
      select @w_ie_abono_intmora = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
      from   ca_amortizacion, ca_concepto, ca_dividendo
      where  am_concepto = co_concepto
      and    am_operacion = @w_operacionca
      and    co_categoria = 'M'
      and    am_operacion = di_operacion
      and    am_dividendo = di_dividendo
      and    di_estado = 2
      
      select @w_ie_abono_intmora_u = 0
      select @w_ie_abono_intmora_u = @w_ie_abono_intmora
      
      select @w_seguro = 0,
             @w_ie_seguros = 0,
             @w_ie_seguros_anticipado = 0
      
      -- SEGUROS DIVIDENDOS VENCIDOS
      select @w_seguro = isnull(sum(am_cuota + am_gracia - am_pagado),0)  
      from   ca_dividendo, ca_amortizacion, ca_concepto 
      where  am_dividendo = di_dividendo  
      and    co_concepto = am_concepto 
      and    co_categoria = 'S'
      and    di_estado = 2
      and    am_operacion = di_operacion
      and    am_operacion = @w_operacionca
      
      -- SEGUROS DIVIDENDO VIGENTE
      select @w_ie_seguros = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
      from   ca_concepto, ca_amortizacion, ca_dividendo
      where  co_concepto = am_concepto 
      and    co_categoria = 'S'
      and    am_dividendo = @w_ie_numero_cuota
      and    am_operacion = @w_operacionca
      and    am_operacion = di_operacion
      and    am_dividendo = di_dividendo
      
      -- SEGUROS DIVIDENDO SIGUIENTE NO VIGENTE (SEGUROS ANTICIPADOS)
      select @w_ie_seguros_anticipado = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
      from   ca_concepto, ca_amortizacion, ca_operacion, ca_rubro, ca_dividendo
      where  co_concepto  = am_concepto 
      and    co_categoria  = 'S'
      and    am_dividendo  = @w_numero_cuota_vig + 1
      and    am_operacion  = @w_operacionca
      and    am_operacion  = op_operacion
      and    ru_toperacion = op_toperacion
      and    ru_concepto   = am_concepto
      and    ru_fpago = 'A'
      and    am_operacion  = di_operacion
      and    am_dividendo  = di_dividendo
      
      select @w_ie_seguros = @w_seguro + @w_ie_seguros + @w_ie_seguros_anticipado
      select @w_ie_seguros_u = 0
      select @w_ie_seguros_u = @w_ie_seguros
      
      -- OTROS CARGOS CUOTA ACTUAL
      -- OTROS CARGOS DIVIDENDOS VENCIDOS
      
      select @w_otros_cargos = isnull(sum(am_cuota + am_gracia - am_pagado),0)  
      from   ca_dividendo, ca_amortizacion, ca_concepto
      where  am_dividendo = di_dividendo  
      and    co_concepto = am_concepto 
      and    co_categoria NOT IN ('S','M','I','C')
      and    di_estado = 2
      and    am_operacion = di_operacion
      and    am_operacion = @w_operacionca
      and    am_concepto != @w_concepto_traslado
      
      -- OTROS CARGOS DIVIDENDO VIGENTE
      select @w_ie_otros_cargos = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
      from   ca_concepto, ca_amortizacion, ca_dividendo
      where  co_concepto = am_concepto 
      and    co_categoria NOT IN ('S','M','I','C')
      and    am_dividendo = @w_ie_numero_cuota  
      and    am_operacion = @w_operacionca   
      and    am_operacion = di_operacion
      and    am_dividendo = di_dividendo
      and    am_concepto  != @w_concepto_traslado
      
      -- Otros Cargos Dividendo Siguiente No Vigente (Ivas  Anticipados)
      select @w_ie_otrosc_anticipado = 0
      
      select @w_ie_otrosc_anticipado = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
      from   ca_amortizacion, ca_rubro_op, ca_concepto
      where  ro_operacion =  am_operacion
      and    am_concepto    = co_concepto
      and    co_categoria not in ('S','M','I','C')
      and    am_operacion   = @w_operacionca
      and    am_dividendo   = @w_numero_cuota_vig + 1  
      and    ro_fpago       = 'A'
      and    am_concepto    = ro_concepto
      and    am_concepto  != @w_concepto_traslado
      
      select @w_ie_otros_cargos = @w_ie_otros_cargos + @w_otros_cargos + @w_ie_otrosc_anticipado
      select @w_ie_otros_cargos_u = 0
      select @w_ie_otros_cargos_u = @w_ie_otros_cargos
      
      -- CUOTA TOTAL
      ---VALIDAR LA MONEDA PARA HACER LA CONVERSION A PESOS SI ES <>
      select @w_ie_total_abono = isnull(sum(@w_ie_abono_capital + @w_ie_abono_int + @w_ie_abono_intmora + @w_ie_seguros + @w_ie_otros_cargos),0)
      
      if  @w_moneda <> @w_moneda_nacional 
      begin
         select @w_ie_abono_capital    = round(@w_ie_abono_capital * @w_cotizacion ,0),
                @w_ie_abono_int        = round(@w_ie_abono_int * @w_cotizacion ,0),
                @w_ie_abono_intmora    = round(@w_ie_abono_intmora * @w_cotizacion ,0),
                @w_ie_seguros          = round(@w_ie_seguros  * @w_cotizacion ,0),
                @w_ie_otros_cargos     = round(@w_ie_otros_cargos  * @w_cotizacion ,0),
                @w_ie_saldo_cap        = round(@w_ie_saldo_cap  * @w_cotizacion ,0),
                @w_ie_total_abono      = round(@w_ie_total_abono  * @w_cotizacion ,0),
                @w_ie_saldo_mora_cap   = round( @w_ie_saldo_mora_cap  * @w_cotizacion ,0)
      end
      
      select @w_ie_total_abono_u = 0
      select @w_ie_total_abono_u = isnull(sum(@w_ie_abono_capital_u + @w_ie_abono_int_u + @w_ie_abono_intmora_u + @w_ie_seguros_u + @w_ie_otros_cargos_u),0)
      
      ---DESCRIPCION DE LA LINEA
      select @w_descripcion_linea = valor 
      from  cobis..cl_catalogo
      where tabla  = @w_tabla_linea
      and   codigo = @w_ie_tipo_producto
      set transaction isolation level read uncommitted
      
      ---DESCRIPCION DE LA OFICINA
      select @w_descripcion_ofi = of_nombre
      from   cobis..cl_oficina
      where  of_oficina  =  @w_ie_oficina_obligacion
      set transaction isolation level read uncommitted
      
      if @w_ie_direccion is null
         select @w_ie_direccion = 'RETENER OFICINA'
      
      --- TOTAL CUOTA
      select @w_ie_total_cuotas = count(1)
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      
      -- NUMERO DE CUOTAS CANCELADAS
      select @w_ie_num_cuotas_canceladas = 0
      select @w_ie_num_cuotas_canceladas = isnull(count(1),0)
      from   ca_dividendo
      where  di_estado = 3
      and    di_operacion = @w_operacionca
      
      ---  FORMULA TASA 
      select @w_referencial_t = ro_referencial,
             @w_signo       = ro_signo,
             @w_puntos      = convert(money,ro_factor),
             @w_fpago       = ro_fpago
      from   ca_rubro_op
      where  ro_operacion = @w_operacionca
      and    ro_tipo_rubro = 'I'
      
      select @w_tasa_mercado = vd_referencia
      from   ca_valor_det
      where  vd_tipo = @w_referencial_t  --ro_referencial
      and    vd_sector = @w_op_sector  ---op_Sector sacarlo en el cursor
      
      ---CONVERTIR LOS PUNTOS A CHAR
      select @w_puntos_c  = convert(varchar(15),@w_puntos)
      
      ---CONCATENAR LA TASA PARA MOSTRAR SEGUN SOLICITUD
      select @w_tasa_mercado = rtrim(ltrim(@w_tasa_mercado))
      
      select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c
      
      --NO DE CUOTAS QUE ESTA COBRANDO
      if @w_ie_num_cuotas_enmora  = 0
         select  @w_cuotas_no_cobradas =  convert(varchar,@w_ie_numero_cuota)
      ELSE
      begin
         --SACAR LA MINIMA VENCIDA
         select @w_minima_cuotas_ven = 0
         select @w_minima_cuotas_ven  = isnull(min(di_dividendo),0)
         from   ca_dividendo
         where  di_estado = 2
         and    di_operacion = @w_operacionca
         
         select  @w_cuotas_no_cobradas =   convert(varchar, @w_minima_cuotas_ven)  +  ' a '  +  convert(char(3), @w_ie_numero_cuota)  
      end
      
      select @w_dias_plazo = td_factor 
      from   ca_tdividendo
      where  td_tdividendo = @w_op_tdividendo
      
      select @w_di_fecha_ini = di_fecha_ini
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      and    di_dividendo = 1
      
      select @w_di_fecha_fin = di_fecha_ven
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      and    di_dividendo = @w_max_div_oper
      
      select @w_total_dias = floor(sum(di_dias_cuota)/30.0)
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      
      select @w_total_dias_1 = convert(int,@w_total_dias)
      
      select @w_cola_mes = sum(di_dias_cuota) % 30
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      
      if @w_cola_mes < 1
         select @w_cola_mes = convert(int,(@w_cola_mes * 100))
            
      if @w_cola_mes >  1   and @w_total_dias_1 > 0  
         select @w_plazo_en_meses = convert(varchar,@w_total_dias_1) + '.' + convert(varchar,@w_cola_mes)
      
      if @w_cola_mes <  1  and @w_total_dias_1 > 0
         select @w_plazo_en_meses = convert(varchar,@w_total_dias_1) 
      
      if @w_total_dias_1 <= 0    and @w_cola_mes >=  1
         select @w_plazo_en_meses = '0.' + convert(varchar,@w_cola_mes)
      
      -- VALOR CUOTA TABLA
      if @w_op_tipo_amortizacion = 'ALEMANA'
         select @w_op_tipo_amortizacion = 'CAP.FIJO'
              
      if @w_op_tipo_amortizacion = 'FRANCESA'
         select @w_op_tipo_amortizacion = 'CUOTA FIJA'
              
      if @w_op_tipo_amortizacion = 'MANUAL'
         select @w_op_tipo_amortizacion = 'PERSONALIZADA'
      
      if @w_moneda <> @w_moneda_nacional
      begin
         select @w_ie_monto_u = @w_op_monto
         exec sp_buscar_cotizacion
              @i_moneda     = @w_moneda,
              @i_fecha      = @w_op_fecha_liq,
              @o_cotizacion = @w_cotizacion_ini output
         
         select @w_op_monto = isnull(round(sum(@w_op_monto * @w_cotizacion_ini),0),0)
      end
      
      if @w_moneda =  @w_moneda_nacional 
      begin
         select @w_ie_saldo_cap_u              = 0.0,
                @w_ie_saldo_mora_cap_u         = 0.0,
                @w_ie_abono_capital_ant_u      = 0.0,
                @w_ie_abono_int_ant_u          = 0.0,
                @w_ie_abono_intmora_ant_u      = 0.0,
                @w_ie_seguros_ant_u            = 0.0,
                @w_ie_otros_cargos_ant_u       = 0.0,
                @w_ie_total_abono_ant_u        = 0.0,
                @w_ie_abono_capital_u          = 0.0,
                @w_ie_abono_int_u              = 0.0,
                @w_ie_abono_intmora_u          = 0.0,
                @w_ie_seguros_u                = 0.0,
                @w_ie_otros_cargos_u           = 0.0,
                @w_ie_total_abono_u            = 0.0,
                @w_ie_monto_u                  = 0.0
      end
      
      if @w_op_migrada is null and @w_op_anterior is not null
         select @w_op_migrada = @w_op_anterior 
                
      if @w_op_migrada is not null  and @w_op_anterior is not null
         select @w_op_migrada = @w_op_anterior 
      
      select @w_toperacion    = tr_toperacion,
             @w_tr_destino    = tr_destino,
             @w_tr_mercado    = tr_mercado, 
             @w_tr_mercado_ob = tr_mercado_objetivo, 
             @w_tr_tipo_prod  = tr_tipo_productor,
             @w_tipo_banca    = tr_sector,
             @w_sujeto_credito = '100'
      from   cob_credito..cr_tramite
      where  tr_tramite = @w_op_tramite
      
      select @w_codregional  = of_regional, 
             @w_zona         = of_zona      
      from   cobis..cl_oficina
      where  of_oficina = @w_ie_oficina_obligacion
      set transaction isolation level read uncommitted
      
      --NR794 CREDITO ROTATIVO SLI 2/AGOS/2007
      if @w_op_tipo = 'O'
      begin 
         
         select @w_ie_cupo_total = 0
         select @w_ie_cargos = 0
         select @w_ie_abonos = 0
         select @w_total_abonos = 0
         select @w_ie_cupo_disponible  = 0
         select @w_ie_pago_total = 0


         select @w_ie_cupo_total = @w_op_monto_aprobado
         
         select @w_ie_cargos =sum(dtr_monto_mn)
         from ca_transaccion,   ca_det_trn
         where tr_operacion =  @w_operacionca
         and tr_tran = 'DES'
         and tr_estado != 'RV'
         and dtr_operacion = tr_operacion
         and dtr_secuencial = tr_secuencial
         and dtr_concepto = 'CAP'

                 
         select @w_ie_abonos =  sum(dtr_monto_mn)
         from ca_transaccion, ca_det_trn
         where tr_operacion = @w_operacionca
         and tr_tran = 'PAG'
         and tr_estado != 'RV'
         and dtr_operacion = tr_operacion
         and dtr_secuencial = tr_secuencial
         and dtr_concepto = 'CAP'
      

        select @w_total_abonos = isnull(sum(dtr_monto_mn),0)
        from ca_transaccion, ca_det_trn, ca_producto
        where tr_operacion =  @w_operacionca
        and tr_tran = 'RPA'
        and tr_estado != 'RV'
        and dtr_operacion = tr_operacion
        and dtr_secuencial = tr_secuencial
        and dtr_concepto = cp_producto
        and cp_pago = 'S'


         select @w_ie_cupo_disponible = (@w_op_monto_aprobado - @w_ie_saldo_cap)
         
         select @w_ie_pago_total = (@w_ie_saldo_cap +  @w_total_abonos - @w_ie_abonos)
               
         
         begin
            exec @w_return = sp_info_ext_mov
            @i_fecha_ini  = @i_fecha_ini,
            @i_fecha_fin  = @i_fecha_fin,
            @i_operacion  = @w_operacionca 
        end
         
      end
         
      -- INSERT EN LA TABLA
      insert into ca_info_extracto
      values(@w_ie_numero_obligacion,      @w_descripcion_linea,      @w_descripcion_ofi,
             @w_ie_nombre,                 @w_ie_direccion,           @w_ie_ciudad,
             @w_ie_fecha_proceso,          @w_op_fecha_embarque,      @w_ie_saldo_cap,
             @w_ie_tasa_efectiva,          @w_ie_tasa_nominal_int,    @w_ie_num_cuotas_canceladas,  
             @w_ie_saldo_mora_cap,         @w_ie_num_cuotas_enmora,   @w_ie_frecuencia_int,  
             @w_ie_frecuencia_cap,         @w_ie_mora_desde,          @w_ie_referencia,                     
             @w_ie_abono_capital_ant,      @w_ie_abono_int_ant,       @w_ie_abono_intmora_ant,
             @w_ie_seguros_ant,            @w_ie_otros_cargos_ant,    @w_ie_total_abono_ant,
             @w_ie_abono_capital,          @w_ie_abono_int,           @w_ie_abono_intmora,
             @w_ie_seguros,                @w_ie_otros_cargos,        @w_ie_total_abono,
             @w_ie_fecha_ven,              @w_op_fecha_liq,           @w_op_monto,
             @w_ie_dpto,                   @w_ie_des_moneda,          @w_ie_total_cuotas,
             @w_op_tipo_amortizacion,      @w_tasa_pactada,           @w_cotizacion,
             @w_cuotas_no_cobradas,        @w_plazo_en_meses,         @w_ie_saldo_cap_u,            
             @w_ie_saldo_mora_cap_u,       @w_ie_abono_capital_ant_u, @w_ie_abono_int_ant_u,        
             @w_ie_abono_intmora_ant_u,    @w_ie_seguros_ant_u,       @w_ie_otros_cargos_ant_u,     
             @w_ie_total_abono_ant_u,      @w_ie_abono_capital_u,     @w_ie_abono_int_u,            
             @w_ie_abono_intmora_u,        @w_ie_seguros_u,           @w_ie_otros_cargos_u,         
             @w_ie_total_abono_u,          @w_ie_monto_u,             @w_op_migrada,
             isnull(@w_sujeto_credito,''), isnull(@w_tr_tipo_prod,''),     isnull(@w_tipo_banca,''),        
             isnull(@w_tr_mercado,''),     isnull(@w_tr_mercado_ob,''),    isnull(@w_toperacion,''),           
             isnull(@w_tr_destino,''),     isnull(@w_zona,0),              isnull(@w_codregional,0),          
             isnull(@w_op_estado,0),       isnull(@w_ie_oficina_obligacion,0)
            )
      
      if @@error <> 0 
      begin
         select @w_error = 705068
         goto ERROR
      end
   end -- if @w_extracto = 'S'
   
   fetch operaciones
   into  @w_operacionca,   @w_ie_numero_obligacion,    @w_ie_tipo_producto,   @w_ie_oficina_obligacion, @w_ie_nombre,
         @w_op_cliente,    @w_op_ciudad,               @w_op_periodo_int,     @w_op_tdividendo,         @w_op_periodo_cap,
         @w_op_estado,     @w_op_migrada,              @w_op_fecha_liq,       @w_op_monto,              @w_op_direccion,
         @w_moneda,        @w_op_tplazo,               @w_op_sector,          @w_op_tipo_amortizacion,  @w_plazo,
         @w_op_anterior,   @w_op_monto_aprobado,       @w_op_tramite,         @w_op_fecha_embarque,     @w_op_tipo
end

close operaciones
deallocate operaciones

--- SE BUSCA EL MENSAJE PARAMETRIZADO POR EL USUARIO 
if exists (select 1
           from   ca_mensaje_facturacion
           where  mf_fecha_ini_facturacion = @i_fecha_ini
           and    mf_fecha_fin_facturacion = @i_fecha_fin)
begin
   exec sp_mensaje_extracto
        @i_fecha_ini  = @i_fecha_ini,
        @i_fecha_fin  = @i_fecha_fin
end


--Actualizacion de la fecha de última facturación

update ca_operacion
set    op_fecha_embarque = @i_fecha_fact  ---fecha que entra como parámetro
from   ca_operacion,
       ca_info_extracto
where  op_banco = ie_numero_obligacion  


return 0

ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null,
     @t_from  = @w_sp_name,
     @i_num   = @w_error
return @w_error

go
