/************************************************************************/
/*       Archivo:               casalpas.sp                             */
/*       Stored procedure:      sp_saldo_pasivas                         */
/*       Base de datos:         cob_cartera                             */
/*       Producto:              Cartera                                 */
/*       Disenado por:          Juan B. Quinche                         */
/*       Fecha de escritura:    Abr. 2009                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Generador de los datos de las operaciones reestructuras de acuerdo */
/*   diferentes condiciones de seleccion.                               */
/************************************************************************/
/*                         Modificaciones                               */
/* 6-Abr-2009         JBQ               Version Inicial                 */
/************************************************************************/
USE cob_cartera
GO


if exists (select 1 from sysobjects where name = 'sp_saldo_pasivas')
   drop proc sp_saldo_pasivas
go
create procedure sp_saldo_pasivas
   @i_fecha_proceso  datetime
as

declare
@w_error                   int,
@w_return                  int,
@w_sp_name                 descripcion,
@w_est_vigente             tinyint,
@w_op_banco                cuenta,
@w_op_tramite              int,
@w_op_oficina              int,
@w_op_codigo_externo       cuenta,
@w_op_fecha_ini            datetime,
@w_op_nombre               varchar(40),
@w_op_sector               char(1),
@w_op_tdividendo           char(1),
@w_op_tipo_linea           catalogo,
@w_op_cliente              int,
@w_op_moneda               tinyint,
@w_op_margen_redescuento   float,
@w_op_opcion_cap           char(1),
@w_op_operacion            int,
@w_op_monto                money,
@w_op_gracia_cap           money,
@w_saldo_cap               money,
@w_op_gracia               money,
@w_op_gracia_int           money,
@w_nom_credito             varchar(40),
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
@w_puntos_c                varchar(10),
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
@w_est_vencido             int,
@w_est_cancelado           int,
@w_est_castigado           int,
@w_est_suspenso            int,
@w_fecha_ini               datetime,
@w_fecha_fin               datetime,
@w_plazo                   int,
@w_tplazo                  char(1),
@w_op_toperacion           varchar(10),
@w_diferencia              money,
@w_tasa_efa                money,
@w_tasa_nom                money,
@w_saldo_cap_corto         money,
@w_saldo_cap_largo         money,
@w_saldo_int_corto         money,
@w_saldo_int_largo         money,
@w_cuota_cap               money,
@w_fecha_ult_pago          datetime,
@w_capital                 money,
@w_intereses               money,
@w_costos                 money,
@w_valor_aplicado          money,      
@w_tipo_garantia           char(1),
@w_fecha_sep               datetime,
@w_secuencial              int



-- CARGADO DE VARIABLES DE TRABAJO
select @w_sp_name = 'sp_conciliacion_mensual'

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted


-- ESTADOS PARA OPERACIONES


select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


select @w_est_vigente = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'CANCELADO'

select @w_est_castigado = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'CASTIGADO'

select @w_est_suspenso = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'SUSPENSO'


if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ca_saldos_pasivas_tmp ]') and OBJECTPROPERTY(id, N'IsTable') = 1)
   drop table cob_cartera..ca_saldos_pasivas_tmp 

create table ca_saldos_pasivas_tmp
(
   sp_entidad                    varchar(64),
   sp_banco                      cuenta,
   sp_monto                      money,
   sp_saldo_cap                  money,
   sp_saldo_cap_corto            money,
   sp_saldo_cap_largo            money,
   sp_saldo_int_corto            money,
   sp_saldo_int_largo            money,
   sp_nom_credito                varchar(40),
   sp_codigo_externo             varchar(20),
   sp_moneda                     smallint,
   sp_cotizacion                 money,
   sp_diferencia                 money,
   sp_tipo_int                    char(1),
   sp_fecha_ini                  datetime,
   sp_fecha_fin                  datetime,
   sp_plazo                      int,
   sp_gracia_cap                 int,
   sp_gracia_int                 int,
   sp_tasa_nom                   money,
   sp_tasa_efa                   money,
   sp_cuota_cap                  char(1),
   sp_tipo_cuota                 char(1),
   sp_fecha_ult_pago             datetime,
   sp_capital                    money,
   sp_intereses                  money,
   sp_costos                     money,
   sp_valor_aplicado             money,
   sp_tipo_garantia              char(1)
)



create table #oper
(
   op_operacion                  int,
   op_banco                      cuenta,
   op_monto                      money,
   op_codigo_externo             varchar(20),
   op_fecha_ini                  datetime,
   op_fecha_fin                  datetime,
   op_plazo                      int,
   op_gracia_cap                 int,
   op_gracia_int                 int,
   op_toperacion                 catalogo,
   op_modalidad_pago             char(1)
)

insert into #oper
select
   op_operacion,        op_banco,         op_monto,         op_codigo_externo,   op_fecha_ini,   
   op_fecha_fin,        op_plazo,         op_gracia_cap,    op_gracia_int,       op_toperacion, 
   op_tplazo
from cob_cartera..ca_operacion
where  op_estado in (@w_est_vigente,@w_est_vencido)
and    op_naturaleza = 'P'
--and    op_tipo = 'R'

delete #oper
from cob_cartera..ca_saldos_pasivas_tmp
where sp_banco = op_banco

-- CURSOR PARA LEER LOS VENCIMIENTOS DE LA FECHA
declare cursor_saldos_pasivas_men cursor for
select
   op_operacion,     op_banco,   op_monto,      op_codigo_externo, op_fecha_ini,
   op_fecha_fin,     op_plazo,   op_gracia_cap, op_gracia_int,     op_toperacion,
   op_modalidad_pago

from #oper
for read only

open  cursor_saldos_pasivas_men

fetch cursor_saldos_pasivas_men into
   @w_op_operacion,    @w_op_banco,   @w_op_monto,          @w_op_codigo_externo,   @w_fecha_ini,
   @w_fecha_fin,       @w_plazo,      @w_op_gracia_cap,     @w_op_gracia_int,       @w_op_toperacion,
   @w_tplazo

while @@fetch_status =0
begin


select
@w_op_cliente           =op_cliente,
@w_op_moneda            =op_moneda,
@w_op_margen_redescuento=op_margen_redescuento,
@w_op_tramite           =isnull(op_tramite,0),
@w_op_oficina           =op_oficina,
@w_op_codigo_externo    =isnull(op_codigo_externo,'0'),
@w_op_fecha_ini         =op_fecha_ini,
@w_op_nombre            =substring(op_nombre,1,35),
@w_op_sector            =op_sector,
@w_op_tdividendo        =op_tdividendo,
@w_op_tipo_linea        =op_tipo_linea,
@w_op_opcion_cap        =op_opcion_cap,
@w_op_fecha_ult_proceso =op_fecha_ult_proceso,
@w_op_toperacion        =op_toperacion
from  ca_operacion
where op_operacion = @w_op_operacion

   -- LECTURA DE DECIMALES
   exec @w_return  = sp_decimales
   @i_moneda       = @w_op_moneda,
   @o_decimales    = @w_num_dec_op out,
   @o_mon_nacional = @w_moneda_mn  out,
   @o_dec_nacional = @w_num_dec_n  out

   select @w_nom_credito = c.valor
   from cobis..cl_tabla as t,
        cobis..cl_catalogo as c
   where t.tabla='ca_toperacion'
   and t.codigo = c.tabla
   and c.codigo = @w_op_toperacion


   -- DIVIDENDO VIGENTE y PROXIMO PAGO INT
   select @w_dividendo_vigente  = di_dividendo
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

   select @w_saldo_cap = isnull(@w_saldo_capital,0)
   select @w_fecha_sep = dateadd(yy,1,@i_fecha_proceso)
   
   --- separar  corto y largo plazo
   select @w_saldo_cap_corto = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from  ca_dividendo, ca_amortizacion
   where am_operacion  = @w_op_operacion
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
   and   am_estado     <> 3  -- Cancelado
   and   am_concepto   = 'CAP'
   and   di_fecha_ven  <=  @w_fecha_sep
   
   
    select @w_saldo_cap_largo = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from  ca_dividendo, ca_amortizacion
   where am_operacion  = @w_op_operacion
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
   and   am_estado     <> 3  -- Cancelado
   and   am_concepto   = 'CAP'
   and   di_fecha_ven  >  @w_fecha_sep
   
   
      select @w_saldo_int_corto = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from  ca_dividendo, ca_amortizacion
   where am_operacion  = @w_op_operacion
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
   and   am_estado     <> 3  -- Cancelado
   and   am_concepto   = 'INT'
   and   di_fecha_ven  <=  @w_fecha_sep
   
   
    select @w_saldo_int_largo = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from  ca_dividendo, ca_amortizacion
   where am_operacion  = @w_op_operacion
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
   and   am_estado     <> 3  -- Cancelado
   and   am_concepto   = 'INT'
   and   di_fecha_ven  >  @w_fecha_sep
   
   -- FORMULA TASA
   select
   @w_referencial  = ro_referencial,
   @w_signo        = ro_signo,
   @w_puntos       = convert(money,ro_factor),
   @w_fpago        = ro_fpago,
   @w_tasa_nominal = ro_porcentaje,
   @w_tasa_efa     = ro_porcentaje_efa
   from  ca_rubro_op
   where ro_operacion = @w_op_operacion
   and   ro_concepto  = 'INT'

   select @w_tasa_mercado = vd_referencia
   from  ca_valor_det
   where vd_tipo = @w_referencial
   and   vd_sector = @w_op_sector
   
   -- calcular diferencia en cambio
   select @w_diferencia = 0

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

   select @w_puntos_c  = convert(varchar(10),@w_puntos)

   select @w_tasa_mercado = rtrim(ltrim(@w_tasa_mercado))
   select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c

   -- NORMA LEGAL
   select @w_norma_legal = substring(dt_valor,1,4)
   from cob_credito..cr_datos_tramites
   where dt_dato = 'NL'
   and   dt_tramite = @w_op_tramite

   if @@rowcount = 0
      select @w_norma_legal = 'No'

   -- ABONO INTERES
   select @w_abono_interes = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_rubro_op, ca_amortizacion, ca_concepto
   where  ro_operacion = @w_op_operacion
   and    ro_tipo_rubro in ('I', 'M')
   and    co_concepto = ro_concepto
   and    am_operacion = ro_operacion
   and    am_concepto  = ro_concepto
   and    am_estado in (1, 2, 4, 44)
   group by co_codigo*1000 + am_estado * 10, am_concepto, am_estado
   having sum(am_acumulado - am_pagado)!= 0

   select @w_prox_pago_int = di_fecha_ven
   from  ca_dividendo
   where di_operacion = @w_op_operacion
   and   di_dividendo = @w_dividendo_vigente + 1
   
   
   select @w_secuencial = max(tr_secuencial) 
   from ca_transaccion
   where tr_operacion= @w_op_operacion
   and tr_tran='PAG'
    
   select @w_fecha_ult_pago = tr_fecha_mov
   from ca_transaccion
   where tr_operacion= @w_op_operacion
   and tr_tran='PAG'
   and tr_secuencial= @w_secuencial
   
   if @w_fecha_ult_pago is null
   select @w_fecha_ult_pago ='01/01/1900'
    
   select @w_capital=sum(dtr_monto) 
   from ca_det_trn
   where dtr_operacion= @w_op_operacion
   and dtr_secuencial=@w_secuencial
   and dtr_concepto='CAP'
   
   select @w_capital=isnull(@w_capital,0)
   
   select @w_intereses=sum(dtr_monto) 
   from ca_det_trn
   where dtr_operacion= @w_op_operacion
   and dtr_secuencial=@w_secuencial
   and dtr_concepto in ('INT','IMO')
  
   select @w_intereses= isnull(@w_intereses,0)
   
   select @w_costos= sum(dtr_monto) 
   from ca_det_trn
   where dtr_operacion= @w_op_operacion
   and dtr_secuencial=@w_secuencial
   and dtr_concepto not in ( 'CAP','INT','IMO','VAC0')
   
   select @w_costos= isnull(@w_costos,0)
   
   select @w_valor_aplicado = @w_capital + @w_intereses + @w_costos
   
   select @w_tipo_garantia= go_tipo_cust
   from cob_custodia..cu_garantia_operacion
   where go_operacion = @w_op_operacion
   
   if @w_tipo_garantia is null
      select @w_tipo_garantia= ''

   -- VALOR A CAPITALIZAR
   select
   @w_valor_capitalizar = 0,
   @w_porcentaje_capitalizar = 0

   if @w_op_opcion_cap = 'S' begin

      if exists (select 1 from ca_acciones
                 where ac_operacion = @w_op_operacion
                 and   @w_dividendo_vigente between ac_div_ini and ac_div_fin)  begin

         select @w_porcentaje_capitalizar = ac_porcentaje
         from  ca_acciones
         where ac_operacion = @w_op_operacion
         and  @w_dividendo_vigente between ac_div_ini and ac_div_fin

         select @w_valor_capitalizar = (@w_abono_interes * @w_porcentaje_capitalizar )/100
         select @w_abono_interes = round(@w_abono_interes - @w_valor_capitalizar,@w_num_dec_op)
      end
   end
 
   -- IDENTIFICACION
   select
   @w_tipo_identificacion = en_tipo_ced,
   @w_identificacion      = en_ced_ruc
   from cobis..cl_ente
   where en_ente = @w_op_cliente
   set transaction isolation level read uncommitted

   if ltrim(rtrim(@w_tipo_identificacion)) = 'N'   ---solo para tipo de identificacion NIT, NO SE TOMA EN CUENTA EL DIGITO VERIFICADOR
      select @w_identificacion = substring (@w_identificacion,1,9)

   select @w_cotizacion = 0

   if @w_op_moneda <> @w_moneda_nacional begin

      exec sp_buscar_cotizacion
      @i_moneda     = @w_op_moneda,
      @i_fecha      = @w_op_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion output

      select @w_abono_capital     = round((@w_abono_capital * @w_cotizacion),0)
      select @w_abono_interes     = round((@w_abono_interes * @w_cotizacion),0)
      select @w_saldo_redescuento = round((@w_saldo_redescuento * @w_cotizacion),0)

   end else

   select @w_cotizacion = 1
   print 'insert'
   insert into ca_saldos_pasivas_tmp(
   sp_entidad,             sp_banco,               sp_monto,
   sp_saldo_cap,           sp_saldo_cap_corto,     sp_saldo_cap_largo,
   sp_saldo_int_corto,     sp_saldo_int_largo,     sp_nom_credito,
   sp_codigo_externo,      sp_moneda,              sp_cotizacion,
   sp_diferencia,          sp_tipo_int,            sp_fecha_ini ,
   sp_fecha_fin,           sp_plazo,               sp_gracia_cap,
   sp_gracia_int,          sp_tasa_nom,            sp_tasa_efa,   
   sp_cuota_cap,           sp_tipo_cuota,          sp_fecha_ult_pago,
   sp_capital,             sp_intereses,           sp_costos,
   sp_valor_aplicado,      sp_tipo_garantia
      )
   values 
   (
   @w_op_nombre,           @w_op_banco,            @w_op_monto,
   @w_saldo_cap,           @w_saldo_cap_corto,     @w_saldo_cap_largo,
   @w_saldo_int_corto,     @w_saldo_int_largo,     @w_nom_credito,         
   @w_op_codigo_externo,   @w_op_moneda,           @w_cotizacion,          
   @w_diferencia,          @w_modalidad,           @w_fecha_ini  ,           
   @w_fecha_fin,           @w_plazo,               @w_op_gracia_cap,  
   @w_op_gracia_int,       @w_tasa_nominal,        @w_tasa_efa,            
   @w_tplazo,              @w_tplazo,              @w_fecha_ult_pago,      
   @w_capital,             @w_intereses,           @w_costos,              
   @w_valor_aplicado,      @w_tipo_garantia 
   )

fetch cursor_saldos_pasivas_men into
   @w_op_operacion,    @w_op_banco,   @w_op_monto,          @w_op_codigo_externo,   @w_fecha_ini,
   @w_fecha_fin,       @w_plazo,      @w_op_gracia_cap,     @w_op_gracia_int,       @w_op_toperacion,
   @w_tplazo
   
end -- CURSOR

close cursor_saldos_pasivas_men
deallocate cursor_saldos_pasivas_men

return 0

go