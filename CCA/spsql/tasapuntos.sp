/************************************************************************/
/*   Archivo             : tasapuntos.sp                                */
/*   Stored procedure    : sp_tasa_puntos                               */
/*   Base de datos       : cob_cartera                                  */
/*   Producto            : Cartera                                      */
/*   Disenado por        : Fabian Gregorio Quint                        */
/*   Fecha de escritura  : MAYO-2007                                    */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*   PROPOSITO                                                          */
/*   Retorna la tasa actual de una operacion  Efectiva y  Nominal       */
/* Segun la combinaionde de tipo de puntos y tipo de tasa               */
/************************************************************************/ 
/*                            CAMBIOS                                   */
/*   FECHA           AUTOR               MODIFICACION                   */
/*   Junio - 01 -2007                                                   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tasa_puntos')
   drop proc sp_tasa_puntos
go

create proc sp_tasa_puntos (
   @i_fecha             datetime,
   @i_signo             char(1),
   @i_factor            float,
   @i_tipo_puntos       char(1),
   @i_modalidad_nom     char(1),
   @i_tperiodo_nom      char(1),
   @i_num_periodo_nom   smallint,
   @i_num_dec_tapl      smallint,
   @i_base_calculo      char(1),
   @i_dias_anio         smallint,
   @i_tasa_aplicar      catalogo,
   @i_sector            catalogo,
   @o_tasa_puntos_efa   float  OUTPUT,
   @o_tasa_puntos_nom   float  OUTPUT
)
as
declare
   @w_error                   int,
   @w_valor_tasa_referencial  float,
   @w_tv_modalidad            char(1),
   @w_tv_periodicidad         char(1),
   @w_max_fecha_ref           datetime,
   @w_referencial             catalogo
begin
   
   
   select @w_referencial = vd_referencia
   from   ca_valor_det  with (nolock)
   where  vd_tipo    = @i_tasa_aplicar
   and    vd_sector  = @i_sector   
   
   select @w_max_fecha_ref = max(vr_fecha_vig)
   from   ca_valor_referencial with (nolock)
   where  vr_tipo = @w_referencial
   and    vr_fecha_vig  <=  @i_fecha
   
   if @@rowcount = 0
   begin
        PRINT 'tasapuntos.sp No existe tasa referencial para la fecha: ' + CAST(@i_fecha AS VARCHAR) + ' : ' + CAST(@w_referencial AS VARCHAR)
        return 722204  
   end     
   

   select @w_valor_tasa_referencial = vr_valor
   from   ca_valor_referencial with (nolock)
   where  vr_tipo    = @w_referencial
   and    vr_secuencial = (select max(vr_secuencial)
                           from ca_valor_referencial with (nolock)
                           where vr_tipo     = @w_referencial
                           and vr_fecha_vig  = @w_max_fecha_ref)   

                         
  
   
   if @i_tipo_puntos not in ('E', 'N', 'B')
      return 722203
   
   if @i_modalidad_nom = 'P'
      select @i_modalidad_nom = 'V'
   
   select @w_tv_modalidad = tv_modalidad,
          @w_tv_periodicidad = tv_periodicidad
   from   ca_tasa_valor with (nolock)
   where  tv_nombre_tasa = @w_referencial
   
   if @@rowcount = 0
   begin
      return 722202
   end
   
   
   
   -- PARA PUNTOS EN TASA NOMINAL
   if @i_tipo_puntos = 'N'
   begin
      declare
         @w_tasa_ref_en_nominal  float
      
      -- PASAR A NOMINAL
      exec @w_error    =  sp_conversion_tasas_int
           @i_base_calculo   = @i_base_calculo,
           @i_dias_anio      = @i_dias_anio,
           
           @i_modalidad_o    = @w_tv_modalidad,
           @i_periodo_o      = @w_tv_periodicidad,
           @i_num_periodo_o  = 1, 
           @i_tasa_o         = @w_valor_tasa_referencial,
           
           @i_modalidad_d    = @i_modalidad_nom,
           @i_periodo_d      = @i_tperiodo_nom,
           @i_num_periodo_d  = @i_num_periodo_nom,
           @i_num_dec        = @i_num_dec_tapl,
           
           @o_tasa_d         = @w_tasa_ref_en_nominal OUTPUT  -- NOMINAL DE TASA REFERENCIAL
      
      if @w_error != 0
         return @w_error
      
      if @i_signo = '+'
         select @o_tasa_puntos_nom = @w_tasa_ref_en_nominal + @i_factor
      if @i_signo = '-'
         select @o_tasa_puntos_nom = @w_tasa_ref_en_nominal - @i_factor
      if @i_signo = '*'
         select @o_tasa_puntos_nom = @w_tasa_ref_en_nominal * @i_factor
      if @i_signo = '/'
         select @o_tasa_puntos_nom = @w_tasa_ref_en_nominal / @i_factor
      
      -- PASAR A EFA
      exec @w_error    =  sp_conversion_tasas_int
           @i_base_calculo   = @i_base_calculo,
           @i_dias_anio      = @i_dias_anio,
           
           @i_modalidad_o    = @i_modalidad_nom,
           @i_periodo_o      = @i_tperiodo_nom,
           @i_num_periodo_o  = @i_num_periodo_nom, 
           @i_tasa_o         = @o_tasa_puntos_nom,
           
           @i_modalidad_d    = 'V',
           @i_periodo_d      = 'A',
           @i_num_periodo_d  = 1,
           @i_num_dec        = @i_num_dec_tapl,
           
           @o_tasa_d         = @o_tasa_puntos_efa OUTPUT  -- NOMINAL DE TASA REFERENCIAL
      
      if @w_error != 0
         return @w_error
   end
   
   if @i_tipo_puntos = 'E'
   begin
      declare
         @w_tasa_ref_en_efa  float
      
      -- PASAR A EFA
      exec @w_error    =  sp_conversion_tasas_int
           @i_base_calculo   = @i_base_calculo,
           @i_dias_anio      = @i_dias_anio,
           
           @i_modalidad_o    = @w_tv_modalidad,
           @i_periodo_o      = @w_tv_periodicidad,
           @i_num_periodo_o  = 1, 
           @i_tasa_o         = @w_valor_tasa_referencial,
           
           @i_modalidad_d    = 'V',
           @i_periodo_d      = 'A',
           @i_num_periodo_d  = 1,
           @i_num_dec        = @i_num_dec_tapl,
           
           @o_tasa_d         = @w_tasa_ref_en_efa OUTPUT  -- NOMINAL DE TASA REFERENCIAL
      
      if @w_error != 0
         return @w_error
      
      
      if @i_signo = '+'
         select @o_tasa_puntos_efa = @w_tasa_ref_en_efa + @i_factor
      if @i_signo = '-'
         select @o_tasa_puntos_efa = @w_tasa_ref_en_efa - @i_factor
      if @i_signo = '*'
         select @o_tasa_puntos_efa = @w_tasa_ref_en_efa * @i_factor
      if @i_signo = '/'
         select @o_tasa_puntos_efa = @w_tasa_ref_en_efa / @i_factor
      
      -- PASAR A NOMINAL
      exec @w_error    =  sp_conversion_tasas_int
           @i_base_calculo   = @i_base_calculo,
           @i_dias_anio      = @i_dias_anio,
           
           @i_modalidad_o    = 'V',
           @i_periodo_o      = 'A',
           @i_num_periodo_o  = 1, 
           @i_tasa_o         = @o_tasa_puntos_efa,
           
           @i_modalidad_d    = @i_modalidad_nom,
           @i_periodo_d      = @i_tperiodo_nom,
           @i_num_periodo_d  = @i_num_periodo_nom,
           @i_num_dec        = @i_num_dec_tapl,
           
           @o_tasa_d         = @o_tasa_puntos_nom OUTPUT  -- NOMINAL DE TASA REFERENCIAL
      
      if @w_error != 0
         return @w_error
   end
   
   if @i_tipo_puntos = 'B'
   begin
      declare
         @w_tasa_ref_en_base  float
      
      if @i_signo = '+'
         select @w_tasa_ref_en_base = @w_valor_tasa_referencial + @i_factor
      if @i_signo = '-'
         select @w_tasa_ref_en_base = @w_valor_tasa_referencial - @i_factor
      if @i_signo = '*'
         select @w_tasa_ref_en_base = @w_valor_tasa_referencial * @i_factor
      if @i_signo = '/'
         select @w_tasa_ref_en_base = @w_valor_tasa_referencial / @i_factor
      
   
      -- PASAR A EFA
      exec @w_error    =  sp_conversion_tasas_int
           @i_base_calculo   = @i_base_calculo,
           @i_dias_anio      = @i_dias_anio,
           
           @i_modalidad_o    = @w_tv_modalidad,
           @i_periodo_o      = @w_tv_periodicidad,
           @i_num_periodo_o  = 1, 
           @i_tasa_o         = @w_tasa_ref_en_base,
           
           @i_modalidad_d    = 'V',
           @i_periodo_d      = 'A',
           @i_num_periodo_d  = 1,
           @i_num_dec        = @i_num_dec_tapl,
           
           @o_tasa_d         = @o_tasa_puntos_efa OUTPUT
      
      if @w_error != 0
         return @w_error
   
         
      -- PASAR A NOMINAL
      exec @w_error    =  sp_conversion_tasas_int
           @i_base_calculo   = @i_base_calculo,
           @i_dias_anio      = @i_dias_anio,
           
           @i_modalidad_o    = @w_tv_modalidad,
           @i_periodo_o      = @w_tv_periodicidad,
           @i_num_periodo_o  = 1, 
           @i_tasa_o         = @o_tasa_puntos_efa,
           
           @i_periodo_d      = @i_tperiodo_nom,
           @i_num_periodo_d  = @i_num_periodo_nom,
           @i_modalidad_d    = @i_modalidad_nom,
           @i_num_dec        = @i_num_dec_tapl,
           
           @o_tasa_d         = @o_tasa_puntos_nom OUTPUT  -- NOMINAL DE TASA REFERENCIAL
      
      if @w_error != 0
         return @w_error
 
         
   end
   
   return 0
end
go
