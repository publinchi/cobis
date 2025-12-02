/************************************************************************/
/*   NOMBRE LOGICO:      sp_reajuste_mora.sp                            */
/*   NOMBRE FISICO:      sp_reajuste_mora                               */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Kevin Rodríguez                                */
/*   FECHA DE ESCRITURA: Agosto 2024                                    */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*   Realiza el reajuste de la Tasa Mora en una fecha establecida       */
/************************************************************************/  
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR            CAMBIOS                              */
/*  30/Ago/2024   Kevin Rodríguez   R240885 Emisión inicial             */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reajuste_mora')
   drop proc sp_reajuste_mora
go

create proc sp_reajuste_mora
@i_operacionca    int,
@i_secuencial     int,
@i_fecha_proceso  datetime
as
declare 
@w_return             int,
@w_concepto           catalogo,
@w_porcentaje         float,
@w_porcentaje_efa     float,
@w_porcentaje_aux     float,
@w_referencial        catalogo,
@w_factor             float,
@w_signo              char(1),
@w_dias_anio          smallint,
@w_base_calculo       char(1),
@w_mora_retroactiva   char(1),
@w_num_dec_tapl       tinyint,
@w_banco              cuenta,
@w_tasa_anterior      float,
@w_clase              char(1),
@w_tipopuntos         char(1),
@w_porcentaje_red     float,
@w_valor_tasa_ref     float,
@w_fecha_tasaref      datetime,
@w_ts_tasa_ref        catalogo,
@w_secuencial         int,
@w_ro_porcentaje_efa  float,
@w_cont_r_imo_reaj    smallint,
@w_max_div_vencido    smallint,
@w_min_div_vencido    smallint,
@w_sig_div            smallint,
@w_di_dividendo       smallint,
@w_di_gracia_disp     smallint,
@w_di_fecha_ven       datetime, 
@w_di_gracia          smallint,
@w_est_vencido        tinyint

-- Estados de cartera
exec @w_return = sp_estados_cca 
@o_est_vencido = @w_est_vencido out

-- DETERMINAR EL SECUENCIAL DEL REAJUSTE  
select @w_secuencial = isnull(max(re_secuencial),0)
from ca_reajuste
where re_operacion = @i_operacionca
and   re_fecha     = @i_fecha_proceso

if @w_secuencial = 0 
   return 0  -- si no hay reajuste salir
   
-- DATOS DE LA OPERACION
select 
@w_dias_anio        = op_dias_anio,
@w_base_calculo     = op_base_calculo,
@w_banco            = op_banco,
@w_mora_retroactiva = op_mora_retroactiva
from   ca_operacion with (nolock)
where  op_operacion = @i_operacionca

-- Bucle Rubros de tipo Interés de Mora.
if object_id('tempdb..#tmp_rubros_imo_reaj') is not null
   drop table #tmp_rubros_imo_reaj

select ro_concepto,    ro_porcentaje_aux, ro_fpago, 
       ro_tipo_puntos, ro_num_dec,        ro_porcentaje_efa
into #tmp_rubros_imo_reaj
from  ca_rubro_op with (nolock)
where ro_operacion  = @i_operacionca
and   ro_tipo_rubro = 'M' 

select @w_cont_r_imo_reaj = count(1) 
from #tmp_rubros_imo_reaj

while @w_cont_r_imo_reaj > 0 
begin

   select top 1 
      @w_concepto          = ro_concepto,    
	  @w_porcentaje_aux    = ro_porcentaje_aux,   
	  @w_num_dec_tapl      = ro_num_dec,     
	  @w_ro_porcentaje_efa = ro_porcentaje_efa
   from #tmp_rubros_imo_reaj
   order by ro_concepto
     
   -- Detalles del reajuste
   select 
   @w_referencial    = red_referencial,
   @w_signo          = red_signo,
   @w_factor         = red_factor,
   @w_porcentaje_red = isnull(red_porcentaje, 0) --Porcentaje ingresado directamente, sin Tasa Referencial
   from   ca_reajuste_det with (nolock)
   where  red_operacion  = @i_operacionca
   and    red_concepto   = @w_concepto
   and    red_secuencial = @w_secuencial
   
   if @@rowcount = 0 goto SIG_RUBRO


   select @w_tasa_anterior = @w_porcentaje_aux  --Tasa Original del IMO

   exec @w_return =  sp_conversion_tasas_int
   @i_dias_anio      = @w_dias_anio,
   @i_base_calculo   = @w_base_calculo,
   @i_periodo_o      = 'A',
   @i_num_periodo_o  = 1,
   @i_modalidad_o    = 'V',
   @i_tasa_o         = @w_porcentaje_red,
   @i_periodo_d      = 'A',
   @i_num_periodo_d  = 1,
   @i_modalidad_d    = 'V',
   @i_num_dec        = @w_num_dec_tapl,
   @o_tasa_d         = @w_porcentaje  output
      
   if @w_return != 0 
      return @w_return

   select @w_porcentaje_efa = @w_porcentaje_red,
          @w_porcentaje     = @w_porcentaje_red, 
		  @w_porcentaje_aux = @w_porcentaje_red
      
   if @w_porcentaje < 0
      select @w_porcentaje     = 0,
             @w_porcentaje_efa = 0
      
   select @w_porcentaje     = round(@w_porcentaje,     isnull(@w_num_dec_tapl,2)),
          @w_porcentaje_efa = round(@w_porcentaje_efa, isnull(@w_num_dec_tapl,2)),
          @w_porcentaje_aux = round(@w_porcentaje_aux, isnull(@w_num_dec_tapl,2))
   

   if object_id('tempdb..#tmp_divs_vencidos') is not null
      drop table #tmp_divs_vencidos

   select * into #tmp_divs_vencidos
   from   ca_dividendo with (nolock)
   where  di_operacion = @i_operacionca
   and    di_estado    = @w_est_vencido
   
   -- Determinar si hay dividendos vencidos (Primero y Ultimo div vencido), en caso de que hoy sea el
   -- vencimiento de un div, este ya tiene estado vencido por que sp_verifica_vencimiento se ejecutó antes
   select @w_max_div_vencido = max (di_dividendo),
          @w_min_div_vencido = min (di_dividendo)
   from   #tmp_divs_vencidos
   where  di_operacion = @i_operacionca
   and    di_estado    = @w_est_vencido
	  
   select @w_sig_div = @w_min_div_vencido
 
   -- Registrar la nueva tasa en el o los dividendos vencidos que correspondan
   while @w_sig_div <= @w_max_div_vencido
   begin
   
      select
      @w_di_dividendo   = di_dividendo,
      @w_di_gracia_disp = di_gracia_disp,
      @w_di_fecha_ven   = di_fecha_ven,
      @w_di_gracia      = di_gracia
      from   #tmp_divs_vencidos
      where  di_operacion  = @i_operacionca
      and    di_dividendo  = @w_sig_div
      
      if @w_mora_retroactiva = 'S' 
      begin
         if @w_di_gracia > 0
            if @w_di_gracia_disp >= 0 -- No cargar la tasa si el Div esta vencido péro tiene gracia disponible
               goto NEXTDIVIDENDO
      end
	  
	  -- Si no existe el registro de la tasa en el dividendo en la fecha actual, lo registra
      if not exists(select 1 
                    from ca_tasas
                    where ts_operacion = @i_operacionca
                    and   ts_dividendo = @w_di_dividendo
                    and   ts_concepto  = @w_concepto
                    and   ts_fecha     = @i_fecha_proceso)
      begin
	     -- Insertar Tasa
         insert into ca_tasas (
            ts_operacion,   ts_dividendo,     ts_fecha,             ts_concepto,
            ts_porcentaje,  ts_secuencial,    ts_porcentaje_efa,    ts_referencial,
            ts_signo,       ts_factor,        ts_valor_referencial,	ts_fecha_referencial, 
            ts_tasa_ref )    
         values(
            @i_operacionca, @w_di_dividendo,  @i_fecha_proceso,     @w_concepto,
            @w_porcentaje,  @i_secuencial,    @w_porcentaje_efa,    @w_referencial,   
            @w_signo,       @w_factor,        @w_valor_tasa_ref,    @w_fecha_tasaref,
            @w_ts_tasa_ref)
	     
         if @@error != 0 
            return 703118 -- Error en insercion tabla de Tasas
      end
	  
	  NEXTDIVIDENDO:
	  select @w_sig_div = @w_sig_div + 1
   
   end
	  
   -- ACTUALIZACION DE TASAS EN ca_rubro_op
   update ca_rubro_op with (rowlock) set
   ro_porcentaje      = @w_porcentaje,
   ro_porcentaje_efa  = @w_porcentaje_efa,
   ro_porcentaje_aux  = @w_porcentaje_aux,
   ro_referencial     = @w_referencial,
   ro_signo           = @w_signo,
   ro_factor          = @w_factor
   where  ro_operacion = @i_operacionca
   and    ro_concepto  = @w_concepto
   
   if @@ERROR != 0 
      return 710002 -- Error en la actualizacion del registro

   SIG_RUBRO:  
   delete #tmp_rubros_imo_reaj where ro_concepto = @w_concepto
   set @w_cont_r_imo_reaj = (select count(1) from #tmp_rubros_imo_reaj)
   
end   ---Bucle rubros IMO

return 0

GO
