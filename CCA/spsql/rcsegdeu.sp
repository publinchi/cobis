/********************************************************************/
/*   NOMBRE LOGICO:      rcsegdeu.sp                                */
/*   NOMBRE FISICO:      sp_rc_seguro_deuda                         */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Kevin Rodríguez                            */
/*   FECHA DE ESCRITURA: Mayo 2023                                  */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                           PROPOSITO                              */
/*   Programa que realiza el cálculo del valor para el rubro de     */ 
/*   SEGURO DE DEUDA (SDE)                                          */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  04-May-2023    K. Rodríguez (S785503)Emision Inicial            */
/*  18-Oct-2023    K. Rodiguez  R217473 Recalculo valor de rubros Q */
/*  02-Ene-2024    B. Dueñas    R221382 Agregar condicion recurrente*/
/*  24-Abr-2024    B. Dueñas    R233298 Agregar parámetros          */
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rc_seguro_deuda')
   drop proc sp_rc_seguro_deuda
go

create proc sp_rc_seguro_deuda
@i_operacion     int,
@i_usar_tmp      char(1)  = 'S',
@i_concepto      catalogo = null,  
@o_valor_rubro   money    = 0 out
        
as
declare 
@w_sp_name             descripcion,
@w_cod_cliente         int,
@w_fecha_nac_cli       datetime,
@w_fecha_ini           datetime,
@w_edad_cli            tinyint,
@w_monto               money,
@w_sector              catalogo,
@w_toperacion          catalogo,
@w_moneda              tinyint,
@w_periodo_int         smallint,
@w_tdividendo          catalogo,
@w_referencial         catalogo,
@w_signo               char(1),
@w_factor              float,        
@w_tipo_val            varchar(10),       
@w_clase               char(1),
@w_fecha_vig           datetime,
@w_secuencial_ref      int,
@w_vr_valor            float,
@w_sde                 float,
@w_edad_rub_oblig      tinyint,
@w_edad_rub_opcional   tinyint,
@w_num_credit_vigentes smallint,
@w_num_dec_op          tinyint,
@w_num_dec_nac         tinyint,
@w_error               int,
@w_calcular            char(1),
@w_valrub_fact_diario  float,
@w_dias_int            smallint,
@w_recurrente          char(1),
@w_cod_adic            int

-- Establecimiento de variables locales iniciales
select @w_sp_name           = 'sp_rc_seguro_deuda',
       @w_error             = 0,
       @w_calcular          = 'N' 

select @w_edad_rub_oblig = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'EDOBSD'

select @w_edad_rub_opcional = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'EDOPSD'

select @w_cod_adic = pa_int
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'CODARE'
--Validar que exista el parametro
if @@rowcount = 0
begin
   set @w_error = 1729000
   goto ERROR
end

--Validar que exista el dato adicional
if not exists(select 1 from cobis.dbo.cl_dato_adicion cda where cda.da_codigo = @w_cod_adic)
begin
   set @w_error = 1720465
   goto ERROR
end

if @i_usar_tmp = 'S'
begin

   select @w_cod_cliente = opt_cliente 
   from ca_operacion_tmp
   where opt_operacion = @i_operacion 
 
   if @w_cod_cliente = -1          -- KDR Desde simulación se forza el cálculo
      select @w_calcular = 'S'
   
   if @w_calcular = 'N'
      select @w_cod_cliente   = opt_cliente,
             @w_fecha_nac_cli = p_fecha_nac,
             @w_fecha_ini     = opt_fecha_ini,
             @w_monto         = opt_monto,
             @w_sector        = opt_sector,
             @w_toperacion    = opt_toperacion,
             @w_moneda        = opt_moneda,
             @w_periodo_int   = opt_periodo_int,
             @w_tdividendo    = opt_tdividendo
      from ca_operacion_tmp, cobis..cl_ente
      where opt_operacion = @i_operacion
      and opt_cliente     = en_ente
   else
      select @w_fecha_ini     = opt_fecha_ini,
             @w_monto         = opt_monto,
             @w_sector        = opt_sector,
             @w_toperacion    = opt_toperacion,
             @w_moneda        = opt_moneda,
             @w_periodo_int   = opt_periodo_int,
             @w_tdividendo    = opt_tdividendo
      from ca_operacion_tmp
      where opt_operacion = @i_operacion
   
end
else
begin

   select @w_cod_cliente = op_cliente 
   from ca_operacion
   where op_operacion = @i_operacion 
 
   if @w_cod_cliente = -1          -- KDR Desde simulación se forza el cálculo
      select @w_calcular = 'S'
   
   if @w_calcular = 'N'
      select @w_cod_cliente   = op_cliente,
             @w_fecha_nac_cli = p_fecha_nac,
             @w_fecha_ini     = op_fecha_ini,
             @w_monto         = op_monto,
             @w_sector        = op_sector,
             @w_toperacion    = op_toperacion,
             @w_moneda        = op_moneda,
             @w_periodo_int   = op_periodo_int,
             @w_tdividendo    = op_tdividendo
      from ca_operacion, cobis..cl_ente
      where op_operacion = @i_operacion
      and op_cliente     = en_ente
   else
      select @w_fecha_ini     = op_fecha_ini,
             @w_monto         = op_monto,
             @w_sector        = op_sector,
             @w_toperacion    = op_toperacion,
             @w_moneda        = op_moneda,
             @w_periodo_int   = op_periodo_int,
             @w_tdividendo    = op_tdividendo
      from ca_operacion
      where op_operacion = @i_operacion
end

if @@rowcount = 0
begin
   select @w_error = 701013 -- No existe operación activa de cartera
   goto ERROR  
end

-- Decimales
exec @w_error = sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec_op  out,
@o_dec_nacional = @w_num_dec_nac out

select @w_num_credit_vigentes = count(1) 
from ca_operacion with (nolock)
where op_cliente = @w_cod_cliente
and op_estado not in (0,3, 6, 99)

select @w_recurrente = de_valor 
from cobis.dbo.cl_dadicion_ente
where de_ente = @w_cod_cliente
and de_dato = @w_cod_adic


select @w_edad_cli            = datediff(yy, @w_fecha_nac_cli, getdate()),
       @w_num_credit_vigentes = isnull(@w_num_credit_vigentes, 0)

if (@w_edad_cli < @w_edad_rub_oblig --Menor a edad obligatoria
      or (@w_edad_cli >= @w_edad_rub_oblig 
          and @w_edad_cli <= @w_edad_rub_opcional --Entre edad obligatoria y edad opcional
          and @w_recurrente = 'S'--validar si hay que agregar la condicion de ser recurrente
          )
    )
   or @w_calcular = 'S' 
begin

   select @w_referencial = ru_referencial
   from ca_rubro
   where ru_toperacion = @w_toperacion
   and ru_moneda       = @w_moneda
   and ru_concepto     = @i_concepto
   
   if @w_referencial is null or @w_referencial = ''
   begin
      select @w_error = 725289 -- Error, no existe referencial de tasa de Seguro de Deuda en el producto, revisar parametrización
      goto ERROR
   end
   
   select
   @w_signo        = isnull(vd_signo_default,' '),
   @w_factor       = isnull(vd_valor_default,0),
   @w_tipo_val     = vd_referencia,
   @w_clase        = va_clase
   from    ca_valor,ca_valor_det
   where   va_tipo   =  @w_referencial
   and     vd_tipo   =  @w_referencial
   and     vd_sector =  @w_sector
   
   if @@rowcount = 0
   begin
      select @w_error = 725288 -- Error, tasa de Seguro de Deuda no existe o está mal parametrizada
      goto ERROR  
   end

   if @w_clase = 'F'
   begin
   
      if @w_signo not in ('+','-','/','*')
      begin
         select @w_error = 725288 -- Error, tasa de Seguro de Deuda no existe o está mal parametrizada
         goto ERROR  
      end
      
      -- Obtención de valor referencial de Tesorería
      -- Fecha más cercana vigente de la tasa referencial de tesorería
      select @w_fecha_vig = max(vr_fecha_vig)
      from   ca_valor_referencial
      where  vr_tipo = @w_tipo_val
      and    vr_fecha_vig <= @w_fecha_ini
      
      -- Secuencial del referencial de tesorería de donde se obtendrá el valor
      select @w_secuencial_ref = max(vr_secuencial)
      from   ca_valor_referencial
      where  vr_tipo = @w_tipo_val
      and    vr_fecha_vig = @w_fecha_vig
      
      if @w_secuencial_ref is null
      begin
         select @w_error = 701177 -- No existe Tasa Referencial a la fecha
         goto ERROR  
      end
      
      -- Valor referencial de tesorería para la tasa SDE
      select @w_vr_valor = vr_valor
      from   ca_valor_referencial
      where  vr_tipo       = @w_tipo_val
      and    vr_secuencial = @w_secuencial_ref
      
      -- Valor final de la tasa SEGURO DE DEUDA 
      if @w_signo = '+'
         select  @w_sde = @w_vr_valor + @w_factor
      if @w_signo = '-'
         select  @w_sde = @w_vr_valor - @w_factor
      if @w_signo = '/'
         select  @w_sde = @w_vr_valor / @w_factor
      if @w_signo = '*'
         select  @w_sde = @w_vr_valor * @w_factor
   
   end

   if @w_clase = 'V'
      select  @w_sde = @w_factor
     
   -- Factor Diario de valor mensual de rubro SDE
   select @w_valrub_fact_diario = (@w_monto * @w_sde) / 30
   
   -- Días cálculo de interés
   select @w_dias_int = @w_periodo_int * td_factor 
   from ca_tdividendo
   where td_tdividendo = @w_tdividendo
   
   select @o_valor_rubro = round( @w_valrub_fact_diario * @w_dias_int, @w_num_dec_nac) 
   
end
else
   select @o_valor_rubro = 0

return 0

ERROR:  
return @w_error
go
