/***********************************************************************/
/*   Archivo:                 contasas.sp                              */
/*   Stored procedure:        sp_consulta_tasas                        */
/*   Base de Datos:           cob_cartera                              */
/*   Producto:                Cartera                                  */
/*   Disenado por:            Fabian de la Torre                       */
/*   Fecha de Documentacion:  Ene. 1998                                */
/***********************************************************************/
/*                         IMPORTANTE                                  */
/*   Este programa es parte de los paquetes bancarios propiedad de     */ 
/*   'MACOSA',representantes exclusivos para el Ecuador de la          */
/*   AT&T                                                              */
/*   Su uso no autorizado queda expresamente prohibido asi como        */
/*   cualquier autorizacion o agregado hecho por alguno de sus         */
/*   usuario sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante                */
/***********************************************************************/  
/*                          PROPOSITO                                  */
/*   Consulta y de no existir inserta en CA_TASAS las tasas a          */
/*   aplicar.                                                          */
/***********************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_consulta_tasas')
   drop proc sp_consulta_tasas
go
---INC.117216 AGO.30.2014
create proc sp_consulta_tasas (
   @i_operacionca           int      = null,
   @i_dividendo             int      = null,
   @i_concepto              catalogo = null,
   @i_sector                catalogo = null, 
   @i_fecha                 datetime = null,
   @i_equivalente           char(1)  = 'N',
   @i_tasa_efa_actual       float    = null,
   @o_tasa                  float    = null out
                            
)                           
as declare                  
   @w_sp_name               varchar(32),   
   @w_porcentaje            float,
   @w_clase                 char(1),
   @w_tasa_base             catalogo,
   @w_referencial           catalogo,
   @w_valor                 float,
   @w_signo                 char(1),
   @w_factor                float,
   @w_secuencial            int,
   @w_tipo_rubro            char(1),
   @w_secuencial_ref        int,
   @w_dias_anio             smallint,
   @w_periodicidad          char(1),
   @w_periodicidad_o        char(1),
   @w_num_periodo_o         smallint,
   @w_porcentaje_efa        float,
   @w_return                int,
   @w_seguro                char(1),
   @w_di_num_dias           int,
   @w_base_calculo          char(1),
   @w_num_dec_tapl          smallint,
   @w_sector                catalogo,
   @w_porcentaje_nom        float,
   @w_porcentaje_efa_aux    float,
   @w_periodicidad_tasa     char(1),
   @w_modalidad_tasa        char(1),
   @w_tipo_tasa             char(1),
   @w_tipo_puntos_def       char(1),
   @w_num_periodo_op        smallint,
   @w_fecha                 datetime,
   @w_valor_tasa_ref        float,
   @w_fecha_tasaref         datetime,
   @w_ts_tasa_ref           catalogo,
   @w_ts_fecha              datetime,
   @w_seguro_asociado       char(1),
   @w_tramite               int

---VARIABLES DE TRABAJO  
select 
@w_sp_name    = 'sp_consulta_tasas',
@w_secuencial = 0


select @w_periodicidad    = op_tdividendo,
       @w_dias_anio       = op_dias_anio,
       @w_base_calculo    = op_base_calculo,
       @w_sector          = op_sector,
       @w_num_periodo_op  = op_periodo_int,
       @w_tramite         = op_tramite
from   ca_operacion
where  op_operacion = @i_operacionca


-- REVISAR EXISTENCIA DE TASA PARA EL DIVIDENDO 
select @w_ts_fecha = isnull(max(ts_fecha),'01/01/1900')
from    ca_tasas
where   ts_operacion = @i_operacionca
and     ts_concepto  = @i_concepto
and     ts_fecha    <= @i_fecha
and     ts_dividendo = @i_dividendo

-- REVISAR EXISTENCIA DE TASA PARA EL DIVIDENDO 
select @w_secuencial = isnull(max(ts_secuencial),0)
from    ca_tasas
where   ts_operacion = @i_operacionca
and     ts_concepto  = @i_concepto
and     ts_fecha     = @w_ts_fecha
and     ts_dividendo = @i_dividendo


if @w_secuencial > 0 and @i_tasa_efa_actual is not null begin
   select  @o_tasa = ts_porcentaje_efa
   from    ca_tasas
   where   ts_operacion  = @i_operacionca
   and     ts_concepto   = @i_concepto
   and     ts_secuencial = @w_secuencial

   if @i_tasa_efa_actual = @o_tasa return 0
   
   select @w_secuencial  = 0
end

if @w_secuencial > 0 begin
   select   
   @w_tipo_rubro = ro_tipo_rubro
   from ca_rubro_op
   where ro_operacion = @i_operacionca
   and   ro_concepto  = @i_concepto

   if @w_tipo_rubro = 'M' begin

      --- PARA MORA SIEMPRE SE CALCULA CON LA MAXIMA TASA DE CA_TASAS
      select @w_secuencial = isnull(max(ts_secuencial),0)
      from    ca_tasas
      where   ts_operacion = @i_operacionca
      and     ts_concepto  = @i_concepto
      and     ts_fecha    <= @i_fecha
   
      select  @o_tasa = ts_porcentaje_efa
      from    ca_tasas
      where   ts_operacion  = @i_operacionca
      and     ts_concepto   = @i_concepto
      and     ts_secuencial = @w_secuencial

   end
   else begin
      select  @o_tasa = ts_porcentaje
      from    ca_tasas
      where   ts_operacion  = @i_operacionca
      and     ts_concepto   = @i_concepto
      and     ts_secuencial = @w_secuencial
   end
end 
else begin
   select 
   @w_referencial     = ro_referencial,
   @w_signo           = ro_signo,
   @w_factor          = ro_factor,
   @w_porcentaje_nom  = ro_porcentaje,
   @w_tipo_rubro      = ro_tipo_rubro,
   @w_porcentaje      = ro_porcentaje_efa,
   @w_num_dec_tapl    = ro_num_dec
   from ca_rubro_op
   where ro_operacion = @i_operacionca
   and   ro_concepto  = @i_concepto

   select                                                                 
   @w_tasa_base       = vd_referencia
   from  ca_valor, ca_valor_det,ca_tasa_valor
   where va_tipo        = @w_referencial
   and   vd_tipo        = @w_referencial
   and   tv_nombre_tasa = vd_referencia
   and   vd_sector      = @i_sector
   
   select @w_fecha = max(vr_fecha_vig)
   from   ca_valor_referencial
   where  vr_tipo      = @w_tasa_base 
   and  vr_fecha_vig  <= @i_fecha

   select @w_secuencial_ref = max(vr_secuencial)
   from   ca_valor_referencial
   where  vr_tipo      = @w_tasa_base 
   and  vr_fecha_vig   = @w_fecha

   -- TASA BASICA REFERENCIAL 
   select @w_valor     = vr_valor
   from   ca_valor_referencial
   where  vr_tipo      = @w_tasa_base 
   and    vr_secuencial = @w_secuencial_ref

   --VALORES PARA LOS NUEVOS CAMPOS DE CA_TASAS
   select 
   @w_valor_tasa_ref = @w_valor,
   @w_fecha_tasaref  = @w_fecha,
   @w_ts_tasa_ref    = @w_tasa_base

   if (@w_tipo_rubro = 'M' or @i_tasa_efa_actual is not null)  and  @w_clase = 'F' begin
      select                                                                 
      @w_clase             = va_clase,
      @w_tasa_base         = vd_referencia,
      @w_porcentaje        = vd_valor_default,  
      @w_periodicidad_tasa = tv_periodicidad,
      @w_modalidad_tasa    = tv_modalidad,
      @w_tipo_tasa         = tv_tipo_tasa,
      @w_tipo_puntos_def   = vd_tipo_puntos
      from  ca_valor, ca_valor_det,ca_tasa_valor
      where va_tipo        = @w_referencial
      and   vd_tipo        = @w_referencial
      and   tv_nombre_tasa = vd_referencia
      and   vd_sector      = @i_sector

      -- EPB PARA TASA EFECTIVA Y PUNTOS EFECTIVOS 
      if @w_tipo_puntos_def = 'E' and  @w_tipo_tasa = 'E' begin
         if @w_signo = '+'
            select @w_porcentaje = @w_valor + @w_factor
         if @w_signo = '-'
            select @w_porcentaje = @w_valor - @w_factor
         if @w_signo = '*'
            select @w_porcentaje = @w_valor * @w_factor
         if @w_signo = '/' 
            if @w_factor = 0  return 708146 
            else select @w_porcentaje = @w_valor / @w_factor

         exec @w_return =  sp_conversion_tasas_int               
         @i_dias_anio      = @w_dias_anio,                       
         @i_base_calculo   = @w_base_calculo,
         @i_periodo_o      = 'A',              
         @i_modalidad_o    = 'V',
         @i_num_periodo_o  = 1,                                  
         @i_tasa_o         = @w_porcentaje,                   ---EFECTIVA + PUNTOS = EFECTIVA FINAL             
         @i_periodo_d      = @w_periodicidad_tasa,                    
         @i_modalidad_d    = @w_modalidad_tasa,
         @i_num_periodo_d  = 1,   --@w_num_periodo_op,
         @i_num_dec        = @w_num_dec_tapl,
         @o_tasa_d         = @w_porcentaje_nom output          ---TASA NOMINAL  FINAL
                                                     
         if @w_return <> 0 return @w_return                      
      end  --- FIN EPB TASA EFECTIVA y PUNTOs EFECTIVOS


      --- EPB PARA TASA EFECTIVA Y PUNTOS NOMINALES 
      if @w_tipo_puntos_def = 'N' and  @w_tipo_tasa = 'E' begin
         exec @w_return =  sp_conversion_tasas_int               
         @i_dias_anio      = @w_dias_anio,                       
         @i_base_calculo   = @w_base_calculo,
         @i_periodo_o      = 'A',              
         @i_modalidad_o    = 'V',
         @i_num_periodo_o  = 1,                                  
         @i_tasa_o         = @w_valor,                   ---EFECTIVA BASE     
         @i_periodo_d      = @w_periodicidad_tasa,                    
         @i_modalidad_d    = @w_modalidad_tasa,
         @i_num_periodo_d  = 1, --@w_num_periodo_op,
         @i_num_dec        = @w_num_dec_tapl,
         @o_tasa_d         = @w_porcentaje_nom output    ---TASA NOMINAL  DE EFECTIVA BASE
                                                     
         if @w_return <> 0 return @w_return                      

         if @w_signo = '+'
            select @w_porcentaje_nom = @w_porcentaje_nom + @w_factor
         if @w_signo = '-'
            select @w_porcentaje_nom = @w_porcentaje_nom - @w_factor
         if @w_signo = '*'
            select @w_porcentaje_nom = @w_porcentaje_nom * @w_factor
         if @w_signo = '/' 
            if @w_factor = 0  return 708146 
            else select @w_porcentaje_nom = @w_porcentaje_nom / @w_factor

         exec @w_return =  sp_conversion_tasas_int               
         @i_dias_anio      = @w_dias_anio,                       
         @i_base_calculo   = @w_base_calculo,
         @i_periodo_o      = @w_periodicidad_tasa,              
         @i_modalidad_o    = @w_modalidad_tasa,
         @i_num_periodo_o  = 1, --@w_num_periodo_op,                                  
         @i_tasa_o         = @w_porcentaje_nom,                  
         @i_periodo_d      = 'A',                    
         @i_modalidad_d    = 'V',
         @i_num_periodo_d  = 1,
         @i_num_dec        = @w_num_dec_tapl,
         @o_tasa_d         = @w_porcentaje_efa_aux output   ---TASA EFECTIVA

         select @w_porcentaje = @w_porcentaje_efa_aux       ---TASA EFECTIVA FINAL
      end  

      if @w_tipo_puntos_def = 'E' and  @w_tipo_tasa = 'N' begin
         exec @w_return =  sp_conversion_tasas_int               
         @i_dias_anio      = @w_dias_anio,                       
         @i_base_calculo   = @w_base_calculo,
         @i_periodo_o      = @w_periodicidad_tasa,              
         @i_modalidad_o    = @w_modalidad_tasa,
         @i_num_periodo_o  = 1, --@w_num_periodo_op,                                  
         @i_tasa_o         = @w_valor,                     ---TASA NOMINAL BASE
         @i_periodo_d      = 'A',                    
         @i_modalidad_d    = 'V',
         @i_num_periodo_d  = 1,
         @i_num_dec        = @w_num_dec_tapl,
         @o_tasa_d         = @w_porcentaje_efa_aux output   ---TASA EFECTIVA DE LA BASE
                                                                 
         if @w_return <> 0 return @w_return                      

         if @w_signo = '+'
            select @w_porcentaje_efa_aux = @w_porcentaje_efa_aux + @w_factor
         if @w_signo = '-'
            select @w_porcentaje_efa_aux = @w_porcentaje_efa_aux - @w_factor
         if @w_signo = '*'
            select @w_porcentaje_efa_aux = @w_porcentaje_efa_aux * @w_factor
         if @w_signo = '/' 
            if @w_factor = 0  return 708146 
            else select @w_porcentaje_efa_aux = @w_porcentaje_efa_aux / @w_factor

         select @w_porcentaje = @w_porcentaje_efa_aux
                     
         exec @w_return =  sp_conversion_tasas_int               
         @i_dias_anio      = @w_dias_anio,                       
         @i_base_calculo   = @w_base_calculo,
         @i_periodo_o      = 'A',              
         @i_modalidad_o    = 'V',
         @i_num_periodo_o  = 1,                                  
         @i_tasa_o         = @w_porcentaje,                  
         @i_periodo_d      = @w_periodicidad_tasa,                    
         @i_modalidad_d    = @w_modalidad_tasa,
         @i_num_periodo_d  = 1, --@w_num_periodo_op,
         @i_num_dec        = @w_num_dec_tapl,
         @o_tasa_d         = @w_porcentaje_nom output      ---TASA NOMINAL FINAL 
                                                     
         if @w_return <> 0 return @w_return                      
      end  -- FIN EPB TASA NOMINAL y PUNTOs EFECTIVOS

      ---EPB PARA TASA NOMINAL Y PUNTOS NOMINALES  o  PUNTOS B (base)
      if (@w_tipo_puntos_def = 'N' and  @w_tipo_tasa = 'N') or @w_tipo_puntos_def = 'B' begin
          if @w_signo = '+'
            select @w_porcentaje_nom = @w_valor + @w_factor
         if @w_signo = '-'
            select @w_porcentaje_nom = @w_valor - @w_factor
         if @w_signo = '*'
            select @w_porcentaje_nom = @w_valor * @w_factor
         if @w_signo = '/' 
            if @w_factor = 0  return 708146 
            else select @w_porcentaje_nom = @w_valor / @w_factor
         
         exec @w_return =  sp_conversion_tasas_int               
         @i_dias_anio      = @w_dias_anio,                       
         @i_base_calculo   = @w_base_calculo,
         @i_periodo_o      = @w_periodicidad_tasa,              
         @i_modalidad_o    = @w_modalidad_tasa,
         @i_num_periodo_o  = 1, --@w_num_periodo_op,                                  
         @i_tasa_o         = @w_porcentaje,                  
         @i_periodo_d      = 'A',                    
         @i_modalidad_d    = 'V',
         @i_num_periodo_d  = 1,
         @i_num_dec        = @w_num_dec_tapl,
         @o_tasa_d         = @w_porcentaje_efa_aux output    ---TASA EFECTIVA FINAL
                                                     
         if @w_return <> 0 return @w_return                      

         select @w_porcentaje = @w_porcentaje_efa_aux

         exec @w_return =  sp_conversion_tasas_int               
         @i_dias_anio      = @w_dias_anio,                       
         @i_base_calculo   = @w_base_calculo,
         @i_periodo_o      = 'A',              
         @i_modalidad_o    = 'V',
         @i_num_periodo_o  = 1,                                  
         @i_tasa_o         = @w_porcentaje,                  
         @i_periodo_d      = @w_periodicidad_tasa,                    
         @i_modalidad_d    = @w_modalidad_tasa,
         @i_num_periodo_d  = 1, --@w_num_periodo_op,
         @i_num_dec        = @w_num_dec_tapl,
         @o_tasa_d         = @w_porcentaje_nom output       ---TASA NOMINAL FINAL
                                                     
         if @w_return <> 0 return @w_return                      
      end  --- FIN EPB TASA NOMINAL y PUNTOs NOMINALES
   end  --Rubro M clase Factor

   if @i_equivalente = 'S' and @w_tipo_rubro not in ( 'M' ,'I') begin
      select @w_di_num_dias = di_dias_cuota
      from ca_dividendo
      where di_operacion = @i_operacionca
      and di_dividendo = @i_dividendo

      ---CALCULAR TASA EQUIVALENTE A DIAS CORRESPONDIENTES 
      exec @w_return = sp_calcula_tasa_eq
      @i_operacionca = @i_operacionca,
      @i_dividendo   = @i_dividendo,
      @i_concepto    = @i_concepto,
      @i_num_dias    = @w_di_num_dias,
      @o_tasa_o      = @w_porcentaje_nom out,
      @o_tasa_efa    = @w_porcentaje out
   end
   
   exec @w_secuencial = sp_gen_sec
   @i_operacion  = @i_operacionca
   
   ---PRINT 'contasas.sp Antes de insertar @w_valor_tasa_ref %1! ,  @w_fecha_tasaref %2! efa %3!',@w_valor_tasa_ref , @w_fecha_tasaref,@w_porcentaje
   insert into ca_tasas (
   ts_operacion,      ts_dividendo,         ts_fecha,
   ts_concepto,       ts_porcentaje,        ts_secuencial,
   ts_porcentaje_efa, ts_referencial,       ts_signo,
   ts_factor,         ts_valor_referencial, ts_fecha_referencial,
   ts_tasa_ref
   ) 
   values (
   @i_operacionca,    @i_dividendo,         @i_fecha,
   @i_concepto,       @w_porcentaje_nom,    @w_secuencial,
   @w_porcentaje,     @w_referencial,       @w_signo, 
   @w_factor,         @w_valor_tasa_ref ,   @w_fecha_tasaref,
   @w_ts_tasa_ref
   )   
   if @@error <> 0 begin
      --PRINT '(contasas.sp) error 703118'
      return 703118 
   end

   ---ACTUALIZAR TABLA RUBROS SOLO SI NO TIEN SEGUROS POR QUE CASO CONTRARIO ACTAULIZA LA PONDERADA YA CALCULADA
   ---EN ca_seguros.sp
   select @w_seguro_asociado ='N'
   if exists (select 1
              from   cob_credito..cr_seguros_tramite  -- Req. 366 Seguros
              where  st_tramite = @w_tramite)
      select @w_seguro_asociado = 'S'

   if  @w_tipo_rubro = 'M'
   begin
      update ca_rubro_op
      set    ro_porcentaje      = @w_porcentaje_nom,
             ro_porcentaje_efa  = @w_porcentaje
      where  ro_operacion = @i_operacionca 
      and    ro_concepto  = @i_concepto
      
      if @@error <> 0
      begin
         --PRINT '(contasas.sp) error 710037 rubro ' + cast ( @i_concepto as varchar)
         return 710037 
      end   
   end
   else
   begin
      if @w_seguro_asociado = 'N' 
      begin
         update ca_rubro_op
         set    ro_porcentaje      = @w_porcentaje_nom,
                ro_porcentaje_efa  = @w_porcentaje
         where  ro_operacion = @i_operacionca 
         and    ro_concepto  = @i_concepto
         
         if @@error <> 0
         begin
            --PRINT '(contasas.sp) error 710037 rubro ' + cast ( @i_concepto as varchar)
            return 710037 
         end
      end
   end

   select @o_tasa = @w_porcentaje_nom  
end

return 0

go

