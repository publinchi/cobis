/************************************************************************/
/*   Archivo:              findex.sp                                    */
/*   Stored procedure:     sp_findeter_bancoldex                        */
/*   Base de datos:        cob_cartera                                  */
/*   Disenado por:          Xavier Maldonado                            */
/*   Fecha de escritura:   Jun.2005                                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Procedimiento que saca la informacion de los saldos a fin de mes   */
/*   de los bancos de segundo piso findeter y bancoldex                 */
/*      para insertcarlos en la estructura ca_findeter, ca_bancoldex    */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre         Proposito                        */
/*      JUN-2010        ELcira PElaez Quitar Codigo Causacion PAsivas   */
/*                                    y comentarios                     */
/************************************************************************/  
   
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_findeter_bancoldex')
   drop proc sp_findeter_bancoldex
go

create proc sp_findeter_bancoldex
@i_fecha_proceso        datetime,
@i_bco_2piso            catalogo

as

declare 
@w_error                   int,
@w_return                  int,
@w_sp_name                 descripcion,
@w_est_vigente             tinyint,
@w_est_vencido             tinyint,
@w_est_novigente           tinyint,
@w_est_cancelado           tinyint,
@w_est_credito             tinyint,
@w_est_suspenso            tinyint,
@w_est_castigado           tinyint,
@w_est_anulado             tinyint,
@w_est_novedades           tinyint,
@w_op_banco                cuenta,
@w_op_tramite              int,
@w_op_oficina              int,
@w_op_codigo_externo       cuenta,
@w_op_fecha_ini            datetime,
@w_op_nombre               varchar(32),
@w_op_tipo_linea           catalogo,
@w_op_cliente              int,
@w_op_moneda               tinyint,
@w_op_margen_redescuento   float,
@w_op_opcion_cap           char(1),
@w_op_operacion            int,
@w_dividendo_vigente       smallint,
@w_prox_pago_int           datetime,
@w_num_dec_op              tinyint,
@w_moneda_mn               tinyint,
@w_num_dec_n               tinyint,
@w_saldo_capital           float,
@w_tasa_mercado            varchar(10),
@w_saldo_redescuento       float,
@w_referencial             catalogo,
@w_signo                   char(1),
@w_puntos                  money,
@w_fpago                   char(1),
@w_tasa_nominal            float,
@w_tipo_tasa               char(1),
@w_modalidad               char(1),
@w_puntos_c                varchar(5),
@w_tasa_pactada            varchar(25),
@w_norma_legal             varchar(255),
@w_abono_interes           float,
@w_valor_capitalizar       float,
@w_porcentaje_capitalizar  float,
@w_identificacion          varchar(15),
@w_llaver                  char(24),
@w_ciudad_nacional         int,
@w_moneda_nacional         smallint,
@w_tipo_identificacion     char(2),
@w_cotizacion              float,
@w_abono_capital           money,
@w_op_fecha_ult_proceso    datetime,
@w_finagro                 catalogo,
@w_bcoldex                 catalogo,
@w_findeter                catalogo,
@w_dias                    int,
@w_total_pago              money,
@w_fecha_ini_cuota         datetime,
@w_fecha_fin_cuota         datetime,
@w_nro_pagare              varchar(64),                        
@w_tasa_redes              varchar(30),
@w_capital_cuota           money,
@w_op_ciudad               int,
@w_desc_ciudad             descripcion,
@w_numero_identificacion   numero,
@w_tipo_amortizacion       catalogo,
@w_dias_div                int,
@w_op_tdividendo           catalogo,
@w_op_dias_anio            int,
@w_op_sector               catalogo,
@w_op_fecha_liq            datetime,
@w_op_base_calculo         catalogo,
@w_op_causacion            catalogo,
@w_op_tipo                 catalogo,
@w_op_oficial              smallint,
@w_op_toperacion           catalogo,
@w_op_clausula             catalogo,
@w_op_dias_div             int,
@w_fecha_hoy               datetime



-- CARGADO DE VARIABLES DE TRABAJO 
select @w_sp_name = 'sp_conciliacion_mensual',
       @w_fecha_hoy = getdate()


-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted


-- ESTADOS PARA OPERACIONES
select @w_est_novigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

select @w_est_vigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CANCELADO'

select @w_est_credito  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CREDITO'

select @w_est_suspenso  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'SUSPENSO'

select @w_est_castigado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CASTIGADO'

select @w_est_anulado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'ANULADO'

select @w_est_novedades  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'NOVEDADES'

select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


select @w_bcoldex = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'BCOLDE'    ---221
set transaction isolation level read uncommitted


select @w_findeter = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FINDET'     ---222
set transaction isolation level read uncommitted


if @w_bcoldex = @i_bco_2piso      ---221
   delete ca_bancoldex WHERE ca_operacion IS NOT NULL

if @w_findeter = @i_bco_2piso     ---222
   delete ca_findeter WHERE ca_nro_credito IS NOT NULL
   


-- CURSOR PARA LEER LOS VENCIMIENTOS DE LA FECHA 
declare cursor_saldos_pasivas_men cursor for
select 
op_cliente,         op_moneda,      op_margen_redescuento,
op_banco,         isnull(op_tramite,0),   op_oficina,
isnull(op_codigo_externo,'0'),   op_fecha_ini,      substring(op_nombre,1,32),
op_sector,         op_tdividendo,      op_tipo_linea,
op_opcion_cap,         op_operacion,       op_fecha_ult_proceso,
op_ciudad,         op_toperacion,      op_dias_anio,
op_fecha_liq,              op_clausula_aplicada,   op_base_calculo,                
op_periodo_int,         op_causacion,      op_tipo,         
op_oficial
from  ca_operacion
where op_tipo = 'R'  
and op_tipo_linea = @i_bco_2piso
and   op_estado not in (@w_est_novigente, @w_est_cancelado, @w_est_credito, 
                        @w_est_castigado, @w_est_novedades, @w_est_anulado)
for read only

open  cursor_saldos_pasivas_men

fetch cursor_saldos_pasivas_men into
@w_op_cliente,         @w_op_moneda,      @w_op_margen_redescuento,
@w_op_banco,           @w_op_tramite,     @w_op_oficina,
@w_op_codigo_externo,  @w_op_fecha_ini,   @w_op_nombre,
@w_op_sector,          @w_op_tdividendo,  @w_op_tipo_linea,
@w_op_opcion_cap,      @w_op_operacion,   @w_op_fecha_ult_proceso,
@w_op_ciudad,          @w_op_toperacion,  @w_op_dias_anio,
@w_op_fecha_liq,       @w_op_clausula,    @w_op_base_calculo,     
@w_op_dias_div,        @w_op_causacion,   @w_op_tipo,      
@w_op_oficial


while @@fetch_status = 0 begin   

   if @@fetch_status = -1 begin    
      select @w_error = 710427 -- Crear error
      return @w_error
   end   


   select @w_cotizacion = 0,
          @w_dias_div   = 0

   if @w_op_moneda <> @w_moneda_nacional 
   begin
      exec sp_buscar_cotizacion
      @i_moneda     = @w_op_moneda,
      @i_fecha      = @w_op_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion output
   end

   /*DESCRIPCION CIUDAD*/
   select @w_desc_ciudad = ''

   select @w_desc_ciudad = ci_descripcion 
   from cobis..cl_ciudad
   where ci_ciudad  = @w_op_ciudad




   -- LECTURA DE DECIMALES 
   exec @w_return  = sp_decimales
   @i_moneda       = @w_op_moneda,
   @o_decimales    = @w_num_dec_op out,
   @o_mon_nacional = @w_moneda_mn  out,
   @o_dec_nacional = @w_num_dec_n  out

   -- DIVIDENDO VIGENTE y PROXIMO PAGO INT 

   select @w_dividendo_vigente  = 0,
          @w_dias               = 0

   select @w_dividendo_vigente  = di_dividendo,
          @w_dias               = di_dias_cuota,
          @w_fecha_ini_cuota    = di_fecha_ini,
          @w_fecha_fin_cuota    = di_fecha_ven
   from ca_dividendo 
   where di_operacion = @w_op_operacion
   and   di_estado    = @w_est_vigente

   -- SALDO_CAPITAL 
   select @w_saldo_capital = 0

   select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from  ca_dividendo, ca_amortizacion
   where am_operacion  = @w_op_operacion
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
   and   am_estado     <> 3  -- Cancelado
   and   am_concepto   = 'CAP'


   -- CAPITAL CUOTA
   select @w_capital_cuota = 0

   select @w_capital_cuota = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from  ca_dividendo, ca_amortizacion
   where am_operacion  = @w_op_operacion
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_dividendo  = @w_dividendo_vigente
   and   am_concepto   = 'CAP'


   -- ABONO INTERES
   select @w_abono_interes = 0

   select @w_abono_interes = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from  ca_dividendo, ca_amortizacion
   where am_operacion  = @w_op_operacion
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_dividendo  = @w_dividendo_vigente
   and   am_concepto   = 'INT'


   -- VALOR A CAPITALIZAR
   select 
   @w_valor_capitalizar = 0,
   @w_porcentaje_capitalizar = 0


   if  @w_op_opcion_cap = 'S' 
   begin
      if exists (select 1 from ca_acciones
                 where  ac_operacion = @w_op_operacion
                 and    @w_dividendo_vigente between ac_div_ini and ac_div_fin)  
      begin
         select @w_porcentaje_capitalizar = ac_porcentaje
         from ca_acciones
    where  ac_operacion = @w_op_operacion
         and  @w_dividendo_vigente between ac_div_ini and ac_div_fin
                        
         select @w_valor_capitalizar = (@w_abono_interes * @w_porcentaje_capitalizar )/100
         select @w_abono_interes = round(@w_abono_interes - @w_valor_capitalizar,@w_num_dec_op)
      end       
   end


   -- FORMULA TASA 
   select 
   @w_referencial  = '',
   @w_signo        = '',
   @w_puntos       = 0,
   @w_fpago        = '',
   @w_tasa_nominal = 0

   select 
   @w_referencial  = ro_referencial,
   @w_signo        = ro_signo,
   @w_puntos       = convert(money,ro_factor),
   @w_fpago        = ro_fpago,
   @w_tasa_nominal = ro_porcentaje
   from  ca_rubro_op
   where ro_operacion = @w_op_operacion
   and   ro_concepto  = 'INT'

   select @w_tasa_mercado = ''

   select @w_tasa_mercado = vd_referencia
   from  ca_valor_det
   where vd_tipo = @w_referencial  
   and   vd_sector = @w_op_sector  

   -- TIPO TASA 
   select @w_tipo_tasa = null

   select @w_tipo_tasa = tv_tipo_tasa
   from ca_tasa_valor
   where tv_nombre_tasa = @w_referencial

   -- MODALIDAD TASA 
   select @w_modalidad = 'V'  ---Por defecto

   if @w_fpago = 'P'
      select @w_modalidad = 'V'

   if @w_fpago = 'A'
      select @w_modalidad = 'A'

   select @w_puntos_c  = convert(varchar(5),@w_puntos)

   select @w_tasa_mercado = rtrim(ltrim(@w_tasa_mercado))
   select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c 


   if @w_op_moneda <> @w_moneda_nacional 
   begin
      select @w_saldo_capital     = round((@w_saldo_capital * @w_cotizacion),0)
      select @w_abono_interes     = round((@w_abono_interes * @w_cotizacion),0)
      select @w_capital_cuota     = round((@w_capital_cuota * @w_cotizacion),0)
   end 
   else      
      select @w_cotizacion = 1


   ---TOTAL A PAGAR
   select @w_total_pago  = 0
   select @w_total_pago  =  isnull(sum(@w_capital_cuota + @w_abono_interes), 0)


   /*NUMERO IDENTIFICACION*/
   select @w_numero_identificacion = null

   select @w_numero_identificacion = en_ced_ruc
   from cobis..cl_ente
   where en_ente = @w_op_cliente
   set transaction isolation level read uncommitted


   ---TASA REDESCUENTO
   select @w_tasa_redes  = ''

   select @w_tasa_redes  =  ltrim(rtrim(tv_nombre_tasa))   ---nombre tasa
   from ca_valor_det,ca_tasa_valor
   where vd_tipo       = @w_referencial
   and   vd_sector     = @w_op_sector
   and   vd_referencia = tv_nombre_tasa


   select @w_tasa_redes = @w_tasa_redes + ' ' + @w_signo + '' + convert(varchar(5),@w_puntos)

   begin tran
      if @w_bcoldex = @i_bco_2piso      begin ---221
         insert into ca_bancoldex(
         ca_operacion,      ca_ciudad,     ca_beneficiario,
         ca_referencia_ext, ca_saldo,      ca_tasa_redes,
         ca_tasa,           ca_dias,       ca_interes,      
         ca_capital,        ca_total_pag,  ca_fecha_proceso,
         ca_nit
         )
         values(
         @w_op_banco,          @w_desc_ciudad,    @w_op_nombre,
         @w_op_codigo_externo, @w_saldo_capital,  @w_tasa_redes,
         @w_tasa_nominal,      @w_dias,           @w_abono_interes,   
         @w_capital_cuota,     @w_total_pago,     @i_fecha_proceso,   
         @w_numero_identificacion
         )
      end

      if @w_findeter = @i_bco_2piso  begin   ---222
         insert into ca_findeter(
         ca_nro_credito,     ca_beneficiario,  ca_referencia,
         ca_saldo_cap,       ca_capital,       ca_fecha_ini_cuota,
         ca_fecha_fin_cuota, ca_dias,          ca_modalidad,
         ca_tasa_redes,      ca_tasa,          ca_interes,
         ca_neto_pag,        ca_fecha_proceso, ca_nit
         )
         values(
         @w_op_banco,        @w_op_nombre,     @w_op_codigo_externo,
         @w_saldo_capital,   @w_capital_cuota, @w_fecha_ini_cuota,
         @w_fecha_fin_cuota, @w_dias,          @w_modalidad,
         @w_tasa_redes,      @w_tasa_nominal,  @w_abono_interes,
         @w_total_pago,      @i_fecha_proceso, @w_numero_identificacion
         )
      end

   commit tran

   fetch cursor_saldos_pasivas_men into
   @w_op_cliente,        @w_op_moneda,     @w_op_margen_redescuento,
   @w_op_banco,          @w_op_tramite,    @w_op_oficina,
   @w_op_codigo_externo, @w_op_fecha_ini,  @w_op_nombre,
   @w_op_sector,         @w_op_tdividendo, @w_op_tipo_linea,
   @w_op_opcion_cap,     @w_op_operacion,  @w_op_fecha_ult_proceso,
   @w_op_ciudad,         @w_op_toperacion, @w_op_dias_anio,
   @w_op_fecha_liq,      @w_op_clausula,   @w_op_base_calculo,     
   @w_op_dias_div,       @w_op_causacion,  @w_op_tipo,      
   @w_op_oficial

end -- CURSOR

close cursor_saldos_pasivas_men
deallocate cursor_saldos_pasivas_men

return 0

go