/************************************************************************/
/*   Archivo:              tasa.sp                                      */
/*   Stored procedure:     sp_tasa                                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         P.Narvaez                                    */
/*   Fecha de escritura:   15/Jun/98                                    */
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
/*   Dado el codigo de la tasa o valor a aplicar,  devuelve el valor    */
/*      de la tasa a aplicar. Retorna el valor en efectivo anual        */
/************************************************************************/  
/*   May 2007     Fabian Quintero Defecto 8236                          */
/************************************************************************/  
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_tasa')
   drop proc sp_tasa
go

create proc sp_tasa
   @i_codigo          varchar(10), 
   @i_sector          catalogo  = null,   
   @i_fecha_ult_proc  datetime  = null,
   @i_dias_anio       smallint,
   @i_base_calculo    char(1),
   @i_efe_anual       char(1)   = 'N',
   @o_modalidad       char(1)   = null out,
   @o_periodicidad    char(1)   = null out,
   @o_valor           float     = 0 out,
   @o_valor_original  float     = 0 out
as

declare
   @w_sp_name           descripcion,
   @w_error             int,
   @w_factor            float,
   @w_signo             char(1),
   @w_valor_referencial float,
   @w_referencia        varchar(10),
   @w_modalidad         char(1),
   @w_periodicidad      char(1),
   @w_modalidad_efe     char(1),
   @w_periodicidad_efe  char(1),
   @w_tipo_puntos       char(1),
   @w_tipo_tasa         char(1),
   @w_num_dec_tapl      tinyint,
   @w_fecha             datetime

select @w_sp_name = 'sp_tasa',
       @w_num_dec_tapl = null

select @w_modalidad_efe    = 'V'  --MODALIDAD VENCIDA POR DEFECTO

select @w_periodicidad_efe = pa_char--PERIODICIDAD ANUAL POR DEFECTO
from    cobis..cl_parametro
where   pa_nemonico = 'PAN'
and     pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_modalidad    =  @w_modalidad_efe --MODALIDAD VENCIDA POR DEFECTO
select @w_periodicidad = @w_periodicidad_efe --PERIODICIDAD ANUAL POR DEFECTO

--print '@i_codigo...' + cast(@i_codigo as varchar(20))
--print '@i_sector...' + cast(@i_sector as varchar(20))

select @w_signo      =  vd_signo_default,
       @w_factor     =  vd_valor_default,
       @w_referencia =  vd_referencia ,
       @w_tipo_puntos = vd_tipo_puntos,
       @w_num_dec_tapl= vd_num_dec
from   ca_valor, ca_valor_det
where  vd_tipo   = @i_codigo
and    vd_tipo   = va_tipo
and    (vd_sector = @i_sector or @i_sector is null) 

if @@rowcount = 0
begin 
   --PRINT '(tasa.sp) salio por error para vd_tipo' + cast(@i_codigo as varchar)
   return 710076
end


select @o_valor          = @w_factor, --SI LA TASA ES UN VALOR ESTA EN EFECTIVO ANUAL
       @o_valor_original = @w_factor

if @w_referencia is not null -- SI LA TASA TIENE ASOCIADA UNA TASA REF.
begin 
   select @w_fecha = max(vr_fecha_vig)
   from ca_valor_referencial
   where vr_tipo       =  @w_referencia
   and   vr_fecha_vig  <= @i_fecha_ult_proc
   
   select @w_valor_referencial = vr_valor
   from   ca_valor_referencial
   where  vr_tipo    = @w_referencia
   and vr_secuencial = (select max(vr_secuencial)
                        from ca_valor_referencial
                        where vr_tipo       = @w_referencia
                        and   vr_fecha_vig  = @w_fecha)
   
   if @@rowcount = 0
   begin
      --PRINT '(tasa.sp) salio por error para  @w_referencia , @i_fecha_ult_proc ' + cast(@w_referencia as varchar) + ' ' + cast(@i_fecha_ult_proc as varchar)
      return 710093
   end

   -- MODALIDAD Y PERIODICIDAD ACTUAL DE LA TASA EN ca_tasa_valor

   select @w_modalidad    = tv_modalidad,
          @w_periodicidad = tv_periodicidad,
          @w_tipo_tasa    = tv_tipo_tasa
   from   ca_tasa_valor
   where  tv_nombre_tasa = @w_referencia
   and    tv_estado      = 'V'
   
   if @@rowcount = 0
   begin
      return 701177
   end

   exec sp_calcula_valor
        @i_base       = @w_valor_referencial,
        @i_factor     = @w_factor,
        @i_signo      = @w_signo,
        @o_resultado  = @o_valor out

   select @o_valor_original = @o_valor

   if @w_tipo_tasa = 'N'
   begin
      --SI LA TASA ES BASE LA COVIERTO A EFECTIVA
      exec @w_error =  sp_conversion_tasas_int
           @i_dias_anio      = @i_dias_anio,
           @i_periodo_o      = @w_periodicidad, 
           @i_num_periodo_o  = 1, 
           @i_modalidad_o    = @w_modalidad,   
           @i_tasa_o         = @o_valor,
           @i_periodo_d      = 'A',
           @i_num_periodo_d  = 1, 
           @i_modalidad_d    = 'V',
           @i_num_dec        = @w_num_dec_tapl,
           @o_tasa_d         = @o_valor output
      
      if @w_error != 0
         return @w_error
   end

   if @w_tipo_puntos = 'N'
   begin
      if @w_tipo_tasa in ('E','N')
      begin
         if @w_signo = '+'
            select @o_valor = @o_valor + @w_factor
         if @w_signo = '-'
            select @o_valor = @o_valor - @w_factor
         if @w_signo = '*'
            select @o_valor = @o_valor * @w_factor
         if @w_signo = '/'
            select @o_valor = @o_valor / @w_factor
      end
   end
   ELSE
   begin
      if @w_tipo_puntos = 'E'
      begin
         if @w_tipo_tasa = 'N'
         begin
            if @w_signo = '+'
               select @o_valor = @o_valor + @w_factor
            if @w_signo = '-'
               select @o_valor = @o_valor - @w_factor
            if @w_signo = '*'
               select @o_valor = @o_valor * @w_factor
            if @w_signo = '/'
               select @o_valor = @o_valor / @w_factor
         end
      end
   end

   if @i_efe_anual = 'S'
   begin
      select @w_modalidad    = @w_modalidad_efe,
             @w_periodicidad = @w_periodicidad_efe
   end
end

select @o_modalidad    = @w_modalidad,
       @o_periodicidad = @w_periodicidad

return 0

go
