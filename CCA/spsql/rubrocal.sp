/***********************************************************************/
/*   NOMBRE LOGICO:      rubrocal.sp                                   */
/*   NOMBRE FISICO:      sp_rubro_calculado                            */
/*   BASE DE DATOS:      cob_cartera                                   */
/*   PRODUCTO:           Cartera                                       */
/*   DISENADO POR:       LCA                                           */
/*   FECHA DE ESCRITURA:                                               */
/***********************************************************************/
/*                     IMPORTANTE                                      */
/*   Este programa es parte de los paquetes bancarios que son          */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,     */
/*   representantes exclusivos para comercializar los productos y      */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida    */
/*   y regida por las Leyes de la República de España y las            */
/*   correspondientes de la Unión Europea. Su copia, reproducción,     */
/*   alteración en cualquier sentido, ingeniería reversa,              */
/*   almacenamiento o cualquier uso no autorizado por cualquiera       */
/*   de los usuarios o personas que hayan accedido al presente         */
/*   sitio, queda expresamente prohibido; sin el debido                */
/*   consentimiento por escrito, de parte de los representantes de     */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto     */
/*   en el presente texto, causará violaciones relacionadas con la     */
/*   propiedad intelectual y la confidencialidad de la información     */
/*   tratada; y por lo tanto, derivará en acciones legales civiles     */
/*   y penales en contra del infractor según corresponda.”.            */
/***********************************************************************/
/*                            PROPOSITO                                */
/*  Este stored procedure permite calcular los valores para rubros     */
/*  calculados                                                         */
/***********************************************************************/
/*                           MODIFICACIONES                            */
/*      FECHA          AUTOR                   RAZON                   */
/*      13/Feb/97       LCA                    Emision Inicial         */
/*      02/Jun/2014     Elcira Pelaez          NR392 Tablas Flexibles  */
/*      14/Abr/2015     Luis Carlos Moreno     NR509 Finagro Fase 2    */
/*      11/Mar/2019     Adriana Giler          Cálculo de Rubros       */
/*      03/Jul/2020     Luis Ponce        CDIG Ajustes Migracion a Java*/
/*      21/Oct/2020     EMP-JJEC         Optimización Rubros calculados*/
/*      26/Jul/2021     GFP              Llamada SP rubros calculados  */
/*      27/12/2021      KDR              Llamada interfaz para cálculo */
/*                                       del valor de rubros calculados*/
/*		08/06/2022		AMO				 Suprimir validacion		   */
/*      27/12/2021      KDR              Calculo de valor de rubro por */
/*                                       llamado a SP parametrizado    */
/***********************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_rubro_calculado')
   drop proc sp_rubro_calculado
go

create proc sp_rubro_calculado (
/*   @i_tipo                  char(1)     = null, -- NO SE USA
   @i_modo                  char(1)     = 'A',  -- NO SE USA
   @i_parametro_fag         catalogo    = null, -- NO SE USA
   @i_tabla_tasa            varchar(30) = null, -- NO SE USA
   @i_fpago                 char(1)     = null, -- NO SE USA
   @i_op_monto_aprobado     money       = 0,    -- NO SE USA
   @i_categoria_rubro       char(1)     = null, -- NO SE USA */
-- PARAMETROS QUE SE USAN
   @i_monto                 money       = 0,    -- SI SE QUIERE ENVIAR UN VALOR PARA REALIZAR EL CALCULO
   @i_concepto              catalogo    = null, -- CODIGO DE RUBRO A CALCULAR
   @i_operacion             int         = null, -- NUMERO DE OPERACION  
   @i_saldo_op              char(1)     = 'N',  -- BANDERA QUE INDICA SI EL CALCULO SE REALIZARA CON EL SALDO CAPITAL DE LA OPERACION
   @i_saldo_por_desem       char(1)     = 'N',  -- BANDERA QUE INDICA SI EL CALCULO SE REALIZARA CON EL SALDO POR DESEMBOLSAR DE LA OPERACION
   @i_monto_aprobado        char(1)     = 'N',  -- BANDERA QUE INDICA SI EL CALCULO SE REALIZARA CON EL MONTO APROBADO DE LA OPERACION
   @i_saldo_insoluto        char(1)     = 'N',  -- BANDERA QUE INDICA SI EL CALCULO SE REALIZARA CON EL SALDO INSOLUTO DE LA OPERACION
   @i_porcentaje            float       = 0,    -- PORCENTAJE SI SE REQUIERE QUE EL CALCULO SE HAGA CON ESE POCENTAJE
   @i_usar_tmp              char(1)     = 'S',  -- BANDERA QUE INDICA SI EL CALCULO SE REALIZARA SOBRE DATOS DE TABLAS TEMPORALES O FIJOS
   @i_porcentaje_cobertura  char(1)     = 'N',  -- BANDERA QUE INDICA SI SE TOMARA EL PROCENTAJE DE COBERTURA DE LA GAR PARA EL CALCULO
   @i_valor_garantia        char(1)     = 'N',  -- BANDERA QUE INDICA SI SE TOMARA EL VALOR DE LA GARANTIA PARA EL CALCULO 
   @i_tipo_garantia         varchar(64) = null, -- TIPO DE GARANTIA A CONSIDERAR PARA EL CALCULO
   @i_tasa_matriz           char(1)     = 'S',  -- BANDERA SI INDICA QUE TOME LA TASA PARAMETRIZADA EN EL RUBRO DEFAULT = S
   @o_valor_rubro           money       = 0 out,
   @o_tasa_calculo          float       = 0 out,
   @o_nro_garantia          varchar(64) = null out,
   @o_base_calculo          money       = null out
   )
as declare
   @w_sp_name               varchar(32),    
   @w_return                int,
   @w_monto                 money, 
   @w_valor                 money,
   @w_sector                catalogo,
   @w_moneda                tinyint,
   @w_toperacion            catalogo,
   @w_monto_aprobado        money,
   @w_porcentaje            float,
   @w_est_novigente         tinyint,
   @w_est_vigente           tinyint,
   @w_tramite               int,
   @w_valor_act_garantia    money,
   @w_porcen_cobertura      float,
   @w_tplazo                catalogo,
   @w_plazo                 smallint,
   @w_tdividendo            catalogo,
   @w_periodo_int           smallint,
   @w_gracia_cap            smallint,
   @w_error                 int,
   @w_cliente               int,
   @w_dias_div              int,
   @w_nro_garantia          varchar(64),
   @w_otra_tasa_rubro       float,
   @w_modalidad_d           char(1),
   @w_base_calculo          char(1),
   @w_num_periodo_d         int,
   @w_dias_anio             smallint,
   @w_periodo_d             catalogo,
   @w_num_dec_tapl          smallint,
   @w_estado                tinyint,
   @w_moneda_local          smallint,
   @w_cotizacion            float,
   @w_num_dec               smallint,
   @w_num_dec_mn            smallint,
   @w_fecha_ult_proceso     datetime,
   @w_fecha_fin             datetime,
   @w_saldo1                money,
   @w_saldo2                money,
   @w_div_vigente           int,
   --REQ379
   @w_op_tipo_amortizacion    catalogo,
   @w_op_numero_reest         int,
   @w_nombre_sp               varchar(30), --GFP Nombre de SP para rubros calculados
   @w_valor_cal               money        --GFP valor calculado
   

select  
@w_sp_name            = 'sp_rubro_calculado',
@w_est_novigente      = 0,  
@w_est_vigente        = 1,    
@w_valor              = 0,
@w_valor_act_garantia = 0,
@w_otra_tasa_rubro    = 0,
@w_modalidad_d        = 'V',
@w_num_dec_tapl       = 2,
@w_dias_div           = 0,
@o_valor_rubro        = 0,
@w_saldo1             = 0,
@w_saldo2             = 0,
@w_div_vigente        = 0

create table #conceptos_gen (
codigo    varchar(10),
tipo_gar  varchar(64)
)

create table #rubros_gen (
garantia      varchar(10),
rre_concepto  varchar(64),
tipo_concepto varchar(10),
iva           varchar(5),
)

-- VALIDACION _ se comenta para revision posterior
--if @i_porcentaje = 0 and @i_tasa_matriz = 'N'
--   return 710386

/* AMO 20220608 SUPRIMIR VALIDACION
if @i_monto = 0 and @i_saldo_op <> 'S' and @i_saldo_por_desem <> 'S' and @i_monto_aprobado <> 'S' and @i_saldo_insoluto <> 'S'
   return 710081
*/


-- CONSULTA CODIGO DE MONEDA LOCAL
select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro
WHERE  pa_nemonico = 'MLO'
AND    pa_producto = 'ADM'
set transaction isolation level read uncommitted

--PARAMETRO QUE INDICARA QUE SI SE TOME O NO LA TASA POR DEFECTO EN UNOS CASOS
/*select @w_param_tasadefecto = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'TASADE' 
set transaction isolation level read uncommitted*/

/*if @w_param_tasadefecto is null
   select @w_param_tasadefecto  = 'N'*/



if @i_usar_tmp = 'S' 
begin
   select
   @w_monto_aprobado    = opt_monto_aprobado,
   @w_monto             = opt_monto,
   @w_sector            = opt_sector,
   @w_moneda            = opt_moneda,
   @w_toperacion        = opt_toperacion,
   @w_tramite           = opt_tramite,
   @w_tplazo            = opt_tplazo,
   @w_plazo             = opt_plazo,
   @w_tdividendo        = opt_tdividendo,
   @w_periodo_int       = opt_periodo_int,
   @w_gracia_cap        = opt_gracia_cap,
   @w_cliente           = opt_cliente,
   @w_num_periodo_d     = opt_periodo_int,
   @w_periodo_d         = opt_tdividendo,
   @w_sector            = opt_sector,
   @w_dias_anio         = opt_dias_anio,
   @w_base_calculo      = opt_base_calculo,
   @w_estado            = opt_estado,
   @w_fecha_ult_proceso = opt_fecha_ult_proceso,
   @w_op_tipo_amortizacion = opt_tipo_amortizacion,
   @w_op_numero_reest      = opt_numero_reest
   from ca_operacion_tmp
   where opt_operacion = @i_operacion

   select @w_valor = @w_monto  ---MONTO A DESEMBOLSAR
   
   -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
   if @w_moneda = @w_moneda_local
      select @w_cotizacion = 1.0
   else
   begin
      exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda,
      @i_fecha      = @w_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion output
   end

   ---MANEJO DE DECIMALES
   exec @w_return = sp_decimales
   @i_moneda       = @w_moneda,
   @o_decimales    = @w_num_dec out,
   @o_mon_nacional = @w_moneda_local out,
   @o_dec_nacional = @w_num_dec_mn out

   ---CUANTOS DIAS TIENE UNA CUOTA DE INTERES
   select @w_dias_div = td_factor *  @w_periodo_int
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo

   if isnull(@i_monto,0) > 0
   begin
      select @w_valor  = @i_monto
   end   
   else
   begin	
      --- VALOR PARA EL CALCULO SOBRE EL SALDO DE LA OPERACION 
      if @i_saldo_op = 'S'
      begin
         if exists(select 1 from ca_amortizacion_tmp 
                   where amt_operacion = @i_operacion)
         select @w_valor = sum(amt_acumulado-amt_pagado+amt_gracia)
         from ca_amortizacion_tmp, ca_dividendo_tmp, ca_rubro_op_tmp
         where dit_operacion = @i_operacion
         and   amt_operacion = @i_operacion
         and   rot_operacion = @i_operacion
         and   dit_estado in (@w_est_novigente, @w_est_vigente)
         and   amt_dividendo = dit_dividendo
         and   rot_tipo_rubro = 'C'
         and   rot_fpago = 'P'   --PERIODICO AL VENCIMIENTO
         and   amt_concepto = rot_concepto
      end
      
      --- VALOR PARA EL CALCULO SOBRE EL SALDO DEL MONTO APROBADO 
      if @i_monto_aprobado = 'S'
         select @w_valor = @w_monto_aprobado 
      
      --- VALOR PARA EL CALCULO SOBRE EL SALDO POR DESEMBOLSAR 
      if @i_saldo_por_desem = 'S'
         select @w_valor = @w_monto_aprobado - @w_monto
      
      --- VALOR PARA EL CALCULO TENIENDO EN CUENTA EL PORCENTAJE DE COBERTURA DE LA GARANTIA
      if @i_porcentaje_cobertura = 'S' 
      begin
         if @w_porcen_cobertura = 0.0
            select @w_porcen_cobertura = 100
      
            if exists(select 1 from ca_amortizacion_tmp 
                   where amt_operacion = @i_operacion)
            select @w_valor = sum(amt_acumulado-amt_pagado+amt_gracia)
            from ca_amortizacion_tmp, ca_dividendo_tmp, ca_rubro_op_tmp
            where dit_operacion = @i_operacion
            and   amt_operacion = @i_operacion
            and   rot_operacion = @i_operacion
            and   dit_estado in (@w_est_novigente, @w_est_vigente)
            and   amt_dividendo = dit_dividendo
            and   rot_tipo_rubro = 'C'
            and   rot_fpago = 'P'   --PERIODICO AL VENCIMIENTO
            and   amt_concepto = rot_concepto
            
            select @w_valor  = isnull((@w_valor * @w_porcen_cobertura)/100,0)  
      end
      if @i_saldo_insoluto = 'S'
      begin
         ---LA BASE PARA EL CALULO DEL SEGURO SOBRE SALDO INSOLUTO SE HACE SOBRE LO QUE DEBE A LA FECHA
         ---INCLUIDO EL MISMO RUBRO
         select @w_div_vigente = max(dit_dividendo)
         from ca_dividendo_tmp
         where dit_operacion = @i_operacion
         and dit_estado  in (1,2)
         
         select @w_saldo1 = isnull(sum(amt_acumulado - amt_pagado),0)
         from ca_amortizacion_tmp,
              ca_concepto
         where  amt_operacion   = @i_operacion
         and    amt_concepto    = co_concepto
         and    co_categoria in ('C','I','M')
         and    amt_estado <> 3
      
         select @w_saldo2 = isnull(sum(amt_acumulado - amt_pagado),0)
         from ca_amortizacion_tmp,
              ca_concepto
         where  amt_operacion   = @i_operacion
         and    amt_concepto    = co_concepto
         and    amt_dividendo <= @w_div_vigente
         and    co_categoria  not in  ('C','I','M')
         and    amt_estado <> 3
      
         select @w_valor = isnull(sum(@w_saldo1 + @w_saldo2 ),0)
      end   
   end   
end
else
begin
   select
   @w_monto_aprobado    = op_monto_aprobado,
   @w_monto             = op_monto,
   @w_sector            = op_sector,
   @w_moneda            = op_moneda,
   @w_toperacion        = op_toperacion,
   @w_tramite           = op_tramite,
   @w_tplazo            = op_tplazo,
   @w_plazo             = op_plazo,
   @w_tdividendo        = op_tdividendo,
   @w_periodo_int       = op_periodo_int,
   @w_gracia_cap        = op_gracia_cap,
   @w_cliente           = op_cliente,
   @w_num_periodo_d     = op_periodo_int,
   @w_periodo_d         = op_tdividendo,
   @w_sector            = op_sector,
   @w_dias_anio         = op_dias_anio,
   @w_base_calculo      = op_base_calculo,
   @w_estado            = op_estado,
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
   @w_fecha_fin         = op_fecha_fin,
   @w_op_tipo_amortizacion = op_tipo_amortizacion,
   @w_op_numero_reest      = op_numero_reest
   from ca_operacion
   where op_operacion = @i_operacion

   select @w_valor = @w_monto  ---MONTO A DESEMBOLSAR

   ---MANEJO DE DECIMALES
   exec @w_return = sp_decimales
   @i_moneda       = @w_moneda,
   @o_decimales    = @w_num_dec out,
   @o_mon_nacional = @w_moneda_local out,
   @o_dec_nacional = @w_num_dec_mn out


   -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
   if @w_moneda = @w_moneda_local
      select @w_cotizacion = 1.0
   else
   begin
      exec sp_buscar_cotizacion
           @i_moneda     = @w_moneda,
           @i_fecha      = @w_fecha_ult_proceso,
           @o_cotizacion = @w_cotizacion output
   end
   
   ---PRINT'rubrocal.sp Cotizacion %1!'+cast(@w_cotizacion as varchar)
   ---CUANTOS DIAS TIENE UNA CUOTA DE INTERES
   select @w_dias_div = td_factor *  @w_periodo_int
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo
   
   if isnull(@i_monto,0) > 0
   begin
      select @w_valor  = @i_monto
   end   
   else
   begin	
      --- VALOR PARA EL CALCULO SOBRE EL SALDO DE LA OPERACION 
      if @i_saldo_op = 'S' 
      begin
          if exists (select 1 from ca_amortizacion
                    where am_operacion = @i_operacion)
            select @w_valor = sum(am_acumulado-am_pagado+am_gracia)
            from ca_amortizacion, ca_dividendo, ca_rubro_op
            where di_operacion = @i_operacion
            and   am_operacion = @i_operacion
            and   ro_operacion = @i_operacion
            and   di_estado in (@w_est_novigente, @w_est_vigente)
            and   am_dividendo = di_dividendo
            and   ro_tipo_rubro = 'C'
            and   ro_fpago = 'P'   --PERIODICO AL VENCIMIENTO
            and   am_concepto = ro_concepto
         else
            select @w_valor = @w_monto
      end
      
      --- VALOR PARA EL CALCULO SOBRE EL SALDO DEL MONTO APROBADO 
      if @i_monto_aprobado = 'S'
         select @w_valor = @w_monto_aprobado
      
      --- VALOR PARA EL CALCULO SOBRE EL SALDO POR DESEMBOLSAR 
      if @i_saldo_por_desem = 'S'
         select @w_valor = @w_monto_aprobado - @w_monto
         
      --- VALOR PARA EL CALCULO TENIENDO EN CUENTA EL PORCENTAJE DE COBERTURA DE LA GARANTIA
      if @i_porcentaje_cobertura = 'S' 
      begin
         if @w_porcen_cobertura = 0.0
            select @w_porcen_cobertura = 100
      
            if exists(select 1 from ca_amortizacion
                   where am_operacion = @i_operacion)
            select @w_valor = sum(am_acumulado-am_pagado+am_gracia)
            from ca_amortizacion, ca_dividendo, ca_rubro_op
            where di_operacion = @i_operacion
            and   am_operacion = @i_operacion
            and   ro_operacion = @i_operacion
            and   di_estado in (@w_est_novigente, @w_est_vigente)
            and   am_dividendo = di_dividendo
            and   ro_tipo_rubro = 'C'
            and   ro_fpago = 'P'   --PERIODICO AL VENCIMIENTO
            and   am_concepto = ro_concepto
            
            select @w_valor  = isnull((@w_valor * @w_porcen_cobertura)/100,0)  
      end
      
      --- VALOR PARA EL CALCULO TENIENDO EN CUENTA EL SALDO INSOLUTO
      if @i_saldo_insoluto = 'S'
      begin
         ---LA BASE PARA EL CALULO DEL SEGURO SOBRE SALDO INSOLUTO SE HACE SOBRE LO QUE DEBE A LA FECHA
         ---INCLUIDO EL MISMO RUBRO
         select @w_div_vigente = max(di_dividendo)
         from ca_dividendo
         where di_operacion = @i_operacion
         and di_estado  in (1,2)
         
         select @w_saldo1 = isnull(sum(am_acumulado - am_pagado),0)
         from ca_amortizacion,
              ca_concepto
         where  am_operacion   = @i_operacion
         and    am_concepto    = co_concepto
         and    co_categoria in ('C','I','M')
         and    am_estado <> 3
      
         select @w_saldo2 = isnull(sum(am_acumulado - am_pagado),0)
         from ca_amortizacion,
              ca_concepto
         where  am_operacion   = @i_operacion
         and    am_concepto    = co_concepto
         and    am_dividendo <= @w_div_vigente
         and    co_categoria  not in  ('C','I','M')
         and    am_estado <> 3
      
         select @w_valor = isnull(sum(@w_saldo1 + @w_saldo2 ),0)
      end   
   end   
end


-- GFP Obtencion de paramentro nombre de SP para ejucion de rubros calculados
select @w_nombre_sp = ru_tabla 
from ca_rubro
where ru_concepto = @i_concepto
and ru_toperacion = @w_toperacion
and ru_tipo_rubro = 'Q'
and ru_moneda     = @w_moneda
  
if @w_nombre_sp is not null and @w_nombre_sp <> ''
begin
	exec @w_return = @w_nombre_sp
	@i_operacion             = @i_operacion,
	@i_usar_tmp              = @i_usar_tmp,
	@i_concepto              = @i_concepto,
	@o_valor_rubro           = @w_valor_cal out
    --@o_tasa_calculo          = @w_porcentaje    out,
	--o_nro_garantia          = @w_nro_garantia  out, 
	
    if @w_return != 0 
    begin
        select @w_error = @w_return
        goto   ERROR
    end
		
end

/* KDR Se comenta proceso que no aplica a esta versión
-- KDR Proceso para calcular el valor de un Rubro Calculado
exec @w_return = sp_procesa_rubros_calculados
@i_rubro       = @i_concepto,
@i_operacionca = @i_operacion,
@o_valor_rubro = @w_valor_cal out

if @w_return != 0 
begin
    select @w_error = @w_return
    goto   ERROR
end*/

select @o_nro_garantia       = isnull(@w_nro_garantia,0)
select @o_tasa_calculo       = isnull(@i_porcentaje,0)
select @o_base_calculo       = isnull(@w_valor,0)
select @o_valor_rubro        = isnull(@w_valor_cal,0)	


return 0 

ERROR:
exec  cobis..sp_cerror
      @t_debug  = 'N',
      @t_file   = null,
      @t_from   = @w_sp_name,
      @i_num    = @w_error

return @w_error
GO

