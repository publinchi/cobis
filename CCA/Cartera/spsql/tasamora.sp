/************************************************************************/
/*   Archivo:                 tasamora.sp                               */
/*   Stored procedure:        sp_consulta_tasa_mora                     */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Elcira Pelaez                             */
/*   Fecha de Documentacion:  nov. 2002                                 */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA",representantes exclusivos para el Ecuador de la           */
/*   AT&T                                                               */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta y de no existir la tasa para mora, la inserta en          */
/*   ca_tasas y actualiza ca_rubro_op con el valor correspondiente      */
/************************************************************************/
/*                           MODIFICACIONES                             */
/* Fecha             Autor            Modificacion                      */
/* Mar-13-2014       Luis Guzman      CCA 409 Tasa Mora Seguros         */
/*                                    Valida que la tasa de mora de los */
/*                                    seguros no pase la TMM.           */
/************************************************************************/  

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_consulta_tasa_mora')
   drop proc sp_consulta_tasa_mora
go

--- Inc. 23755 Jun-20-2011 Partiendo de la Ver. 5

create proc sp_consulta_tasa_mora
   @i_operacionca          int      = null,
   @i_dividendo            int      = null, 
   @i_concepto             catalogo = null,
   @i_sector               catalogo = null, 
   @i_fecha                datetime = null,
   @i_dias_anio            smallint,
   @i_base_calculo         char(1),
   @i_clase_cartera        catalogo,
   @i_tasa_maxima_efa      float,
   @i_tasa_corriente_efa   float,
   @i_tasa_corriente_nom   float,
   @i_op_tdividendo        char(1),
   @i_op_periodo_int       int,
   @i_modalidad            char(1),
   @i_dias                 int,
   @i_tasa_icte            catalogo,
   @o_tasa                 float    = null out
as
declare
   @w_return            int,
   @w_secuencial        int,
   @w_num_dec_tapl      smallint,
   @w_tmora_efa_act     float,
   @w_tmora_efa_nue     float,
   @w_limite1           float,
   @w_signo             char(1),
   @w_factor            float,
   @w_periodo_tasa      char(1),
   @w_modalidad_tasa    char(1),
   @w_referencial       catalogo,
   @w_tipo_puntos       char(1),
   @w_codigo_tmm        catalogo, 
   @w_codigo_tmmex      catalogo,
   @w_fecha_tasa        datetime,   
   @w_fecha_ref         datetime,
   @w_secuencial_ref    int,
   @w_dividendo_min     int,
   @w_dividendo_max     int,
   @w_referencial_tmm_clase catalogo,
   @w_tasa_maxima       float   

   
select @w_codigo_tmm = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'TMM'

select @w_codigo_tmmex = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'TMMEX'


/* DETERMINAR PARAMETRIA Y VALORES ACTUALES DE LA TASA DE MORA */
select 
@w_referencial   = ro_referencial,
@w_signo         = ro_signo,
@w_factor        = ro_factor,
@w_tipo_puntos   = ro_tipo_puntos,
@w_num_dec_tapl  = ro_num_dec,
@w_tmora_efa_act = isnull(ro_porcentaje_efa,0.00)
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_concepto  = @i_concepto

if @@rowcount = 0 select @w_tmora_efa_act = 0

/* CALCULAR NUEVAMENTE LA TASA DE MORA PARA VERIFICAR QUE NO HAYA CAMBIADO */

select @w_referencial_tmm_clase = ltrim(rtrim(@w_codigo_tmm)) + ltrim(rtrim(@i_clase_cartera))

if @w_referencial in (@w_codigo_tmm, ltrim(rtrim(@w_referencial_tmm_clase)))
 begin
   ---PRINT 'tasamora_prod.sp ENTRO @w_referencial ' +  CAST (@w_referencial as varchar) + ' @i_tasa_maxima_efa ' + CAST (@i_tasa_maxima_efa as varchar)  
   select @w_tmora_efa_nue = @i_tasa_maxima_efa   --truco para eviatar calcular la TMM todas las veces.
   
end else begin
   
---   PRINT 'tasamora_prod.sp ENTRO POR EL ELSE'
   select @w_referencial = vd_referencia
   from   ca_valor_det (nolock)
   where  vd_tipo   = @w_referencial
   and    vd_sector = @i_sector
   
   select @w_fecha_ref = max(vr_fecha_vig)
   from   ca_valor_referencial (nolock)
   where  vr_tipo       = @w_referencial
   and    vr_fecha_vig <= @i_fecha
   
   select @w_secuencial_ref = max(vr_secuencial)
   from   ca_valor_referencial (nolock)
   where  vr_tipo      = @w_referencial
   and    vr_fecha_vig = @w_fecha_ref
   
   select @w_tmora_efa_nue = vr_valor
   from   ca_valor_referencial (nolock)
   where  vr_tipo       = @w_referencial
   and    vr_fecha_vig  = @w_fecha_ref
   and    vr_secuencial = @w_secuencial_ref
   
   if @@rowcount = 0 begin
      PRINT 'tasamora.sp NO EXISTE para la fecha ' + cast(@w_referencial as varchar) + ' ' + cast(@i_fecha as varchar)
      return 701177
   end

   select 
   @w_periodo_tasa   = tv_periodicidad,
   @w_modalidad_tasa = tv_modalidad
   from   ca_tasa_valor (nolock)
   where  tv_nombre_tasa = @w_referencial

   if @w_tipo_puntos = 'B' and @w_signo is not null and @w_factor <> 0 begin
      if @w_signo = '+'  select @w_tmora_efa_nue = @w_tmora_efa_nue + @w_factor
      if @w_signo = '-'  select @w_tmora_efa_nue = @w_tmora_efa_nue - @w_factor
      if @w_signo = '*'  select @w_tmora_efa_nue = @w_tmora_efa_nue * @w_factor
      if @w_signo = '/'  select @w_tmora_efa_nue = @w_tmora_efa_nue / @w_factor
      select @w_signo = null
   end

   if @w_periodo_tasa <> 'A' or @w_modalidad_tasa <> 'V' begin -- SI NO ES EFECTIVA ANUAL, CONVERTIRLA A EFA
   
      select @w_return = 0
      
      exec @w_return = sp_conversion_tasas_int
      @i_dias_anio      = @i_dias_anio,
      @i_base_calculo   = @i_base_calculo,
      @i_periodo_o      = @w_periodo_tasa,
      @i_modalidad_o    = @w_modalidad_tasa,
      @i_num_periodo_o  = 1,
      @i_tasa_o         = @w_tmora_efa_nue,
      @i_periodo_d      = 'A',
      @i_modalidad_d    = 'V',
      @i_num_periodo_d  = 1,
      @i_num_dec        = @w_num_dec_tapl,
      @o_tasa_d         = @w_tmora_efa_nue output
      
      if @w_return <> 0 return @w_return
      
      select 
      @w_periodo_tasa = 'A',
      @w_modalidad_tasa = 'V'

   end
end

if @w_signo is not null and @w_factor <> 0 begin
   if @w_signo = '+' select @w_tmora_efa_nue = @w_tmora_efa_nue + @w_factor
   if @w_signo = '-' select @w_tmora_efa_nue = @w_tmora_efa_nue - @w_factor
   if @w_signo = '*' select @w_tmora_efa_nue = @w_tmora_efa_nue * @w_factor
   if @w_signo = '/' select @w_tmora_efa_nue = @w_tmora_efa_nue / @w_factor
end

if @w_tmora_efa_nue < 0 select @w_tmora_efa_nue = 0


/* CONTROLAR LOS LIMITES DE LA TASA DE MORA */
if @i_tasa_corriente_efa <= 0 begin

   select @w_limite1 = @w_tmora_efa_nue
   
end else begin
   
   if @i_clase_cartera <> '3'
      select @w_limite1 =  (@i_tasa_corriente_efa * 2)
   else
      select @w_limite1 =  (@i_tasa_corriente_efa * 1.5)
      
end
   
if @w_referencial in (select ltrim(rtrim(c.codigo)) + ltrim(rtrim(@i_clase_cartera))
                      from cobis..cl_tabla t, cobis..cl_catalogo c 
                      where t.tabla = 'ca_trefencial_mora_seg'
                      and   t.codigo = c.tabla)
begin    
   
   select @w_fecha_ref = max(vr_fecha_vig)
   from   ca_valor_referencial (nolock)
   where  vr_tipo       = @w_referencial_tmm_clase
   and    vr_fecha_vig <= @i_fecha      
   
   select @w_secuencial_ref = max(vr_secuencial)
   from   ca_valor_referencial (nolock)
   where  vr_tipo      = @w_referencial_tmm_clase
   and    vr_fecha_vig = @w_fecha_ref
         
   select @w_tasa_maxima = vr_valor
   from   ca_valor_referencial (nolock)
   where  vr_tipo       = @w_referencial_tmm_clase
   and    vr_fecha_vig  = @w_fecha_ref
   and    vr_secuencial = @w_secuencial_ref
     
   if @i_tasa_maxima_efa > @w_tasa_maxima 
      select @w_tmora_efa_nue = @w_tasa_maxima
   else if @w_tmora_efa_nue > @i_tasa_maxima_efa  
      select @w_tmora_efa_nue = @i_tasa_maxima_efa
   
end
else
begin   
   if @w_tmora_efa_nue > @w_limite1          select @w_tmora_efa_nue = @w_limite1
   if @w_tmora_efa_nue > @i_tasa_maxima_efa  select @w_tmora_efa_nue = @i_tasa_maxima_efa
end

if @w_tmora_efa_nue <> @w_tmora_efa_act begin -- INSERTAR NUEVA TASA

   /* EXPRESAR NUEVA TASA DE MORA EN PERIODICIDAD DIARIA MODALIDAD VENCIDA */
   exec @w_return = sp_conversion_tasas_int
   @i_dias_anio      = @i_dias_anio,
   @i_base_calculo   = @i_base_calculo,
   @i_periodo_o      = 'A',
   @i_modalidad_o    = 'V',
   @i_num_periodo_o  = 1,
   @i_tasa_o         = @w_tmora_efa_nue,   ---EFECTIVA ANUAL
   @i_periodo_d      = 'D',
   @i_modalidad_d    = 'V',
   @i_num_periodo_d  = 1,
   @i_num_dec        = @w_num_dec_tapl,
   @o_tasa_d         = @o_tasa output

   if @w_return <> 0 return @w_return

   update ca_rubro_op with (rowlock) set    
   ro_porcentaje_efa = @w_tmora_efa_nue,
   ro_porcentaje     = @o_tasa
   where  ro_operacion = @i_operacionca
   and    ro_concepto  = @i_concepto
   
   if @@error <> 0 return 710003

end

/* REGISTRAR LA TASA DE MORA QUE SE APLICARA A LOS DIVIDENDOS VENCIDOS EN EL HISTORICO DE TASAS (ca_tasas)*/
select 
@w_dividendo_min = isnull(min(di_dividendo),-00),
@w_dividendo_max = isnull(max(di_dividendo),-99)
from ca_dividendo
where di_operacion = @i_operacionca
and   di_estado    = 2

while @w_dividendo_min <= @w_dividendo_max begin  

   if @w_tmora_efa_nue <> @w_tmora_efa_act 
   or not exists(select 1 from ca_tasas
                 where ts_operacion = @i_operacionca
                 and   ts_dividendo = @w_dividendo_min
                 and   ts_concepto  = @i_concepto)
   begin
   
      exec @w_secuencial = sp_gen_sec
      @i_operacion = @i_operacionca
      
      insert into ca_tasas (
      ts_operacion,       ts_dividendo,     ts_fecha,
      ts_concepto,        ts_porcentaje,    ts_secuencial,
      ts_porcentaje_efa,  ts_referencial,   ts_signo,
      ts_factor ) 
      values(
      @i_operacionca,     @w_dividendo_min, @i_fecha,
      @i_concepto,        @o_tasa,          @w_secuencial,
      @w_tmora_efa_nue,   @w_referencial,   @w_signo,
      @w_factor)
      
      if @@error <> 0  begin
         PRINT 'tasamora.sp fecha ' + cast(@i_fecha as varchar) + ' @o_tasa ' + cast(@o_tasa as varchar) + ' concepto ' + cast(@i_concepto as varchar)
         return 703118 
      end
      
   end
      
   select @w_dividendo_min = @w_dividendo_min + 1
      
end --while


select @o_tasa = @w_tmora_efa_nue

return 0

go

