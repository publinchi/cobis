/************************************************************************/
/*   Archivo:              recalfag.sp                                  */
/*   Stored procedure:     sp_recalculo_fag                             */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Nov. 2006                                    */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*                                   PROPOSITO                          */
/*   Regenerar el rubro COMISIOFAG si el valor de la garant¡a ha        */
/*   cambiado     NR-433                                                */
/************************************************************************/
/*                                 MODIFICACIONES                       */
/*   FECHA         AUTOR            RAZON                               */
/*   jun-28-2006   Elcira Pelaez    def. 6762 BAC                       */
/*   sep-26-2006   Elcira Pelaez    def. 7151 BAC                       */
/*   May-22-2006   Elcira Pelaez    def. 8207 BAC                       */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_recalculo_fag')
   drop proc sp_recalculo_fag
go

create proc sp_recalculo_fag(   
   @i_operacionca  int,
   @i_tramite    int      = null,
   @i_sector     catalogo = null,
   @i_num_dec    float    = null
)as

Declare
   @w_nro_garantia      cuenta,
   @w_tipo_garantia     varchar(64),
   @w_parametro_fag     varchar(30),
   @w_valor_base        money,      
   @w_bg_base_calculo   money,
   @w_referencial_a     catalogo,
   @w_concepto_asociado catalogo,
   @w_porcentaje        float,
   @w_base_calculo      money,
   @w_valor_rubro       money,
   @w_factor_a          float,
   @w_valor_rubro_a     money, 
   @w_return            int,
   @w_cu_porcentaje_cobertura   float,
   @w_cu_valor_inicial   money,
   @w_tramite            int,
   @w_toperacion         catalogo

-- JAR REQ 175
-- No se requeire reclacular el rubro
return 0
   

--- Parametro de COMISION FAG 
select @w_parametro_fag = pa_char
from  cobis..cl_parametro
where pa_nemonico = 'COMFAG'
and   pa_producto = 'CCA'

select @w_nro_garantia  = ro_nro_garantia,
       @w_tipo_garantia = ro_tipo_garantia,
       @w_porcentaje    = ro_porcentaje
from ca_rubro_op
where ro_operacion = @i_operacionca
and   ro_concepto  = @w_parametro_fag


if @w_nro_garantia is null or @w_nro_garantia = 'N' or @w_nro_garantia = ''
begin

   
   --SE SELECCIONA LA GARANTIA SEGUNEL TIPO RELACIONADO
   select @w_nro_garantia   = gp_garantia
   from cob_credito..cr_gar_propuesta, 
   cob_custodia..cu_custodia,
   cob_custodia..cu_tipo_custodia
   where gp_tramite  =  @i_tramite
   and gp_garantia   =  cu_codigo_externo
   and cu_tipo       =  tc_tipo
   and (cu_tipo      =  @w_tipo_garantia or cu_tipo = tc_tipo_superior)
   and    cu_estado   in ('V', 'X', 'F')
   
   if @@rowcount = 0
      PRINT 'MENSAJE INFORMATIVO ---> NO HAY GARANTIA ADJUNTA AL RUBRO COMISION FAG REVISAR'
   else
   begin

      update  ca_rubro_op
      set   ro_nro_garantia = @w_nro_garantia
      where ro_operacion = @i_operacionca
      and   ro_concepto  = @w_parametro_fag      
      
   end   
   
end


select @w_cu_valor_inicial = cu_valor_inicial ,
       @w_cu_porcentaje_cobertura = isnull(cu_porcentaje_cobertura,0.0)
from  cob_custodia..cu_custodia,
      cob_credito..cr_gar_propuesta
where cu_codigo_externo = @w_nro_garantia
and   cu_codigo_externo = gp_garantia
and   gp_tramite        = @i_tramite
and   cu_estado   in ('V', 'X', 'F')


if @w_cu_valor_inicial > 0   
   select @w_valor_base = isnull(round( (@w_cu_valor_inicial * @w_cu_porcentaje_cobertura) /100,0),0)
else   
  select @w_valor_base = 0



select @w_bg_base_calculo = bg_base_calculo
from  ca_base_garantia
where bg_tramite = @i_tramite   

select @w_referencial_a     = ro_referencial,
       @w_concepto_asociado = ro_concepto
from  ca_rubro_op
where ro_operacion         = @i_operacionca
and   ro_concepto_asociado = @w_parametro_fag

if @w_referencial_a is null 
begin
    select @w_toperacion = op_toperacion
    from ca_operacion
    where op_operacion = @i_operacionca
    
    select @w_referencial_a = ru_referencial 
    from ca_rubro
    where ru_toperacion = @w_toperacion
    and ru_concepto_asociado = @w_parametro_fag
    
    if @w_referencial_a is null
       PRINT 'ERROR A LINEA NO TIENE PARA EL RUBRO IVACOMISIONFAG LA TASA REFERENCIAL'
    
end


---PRINT 'recalfag.sp @w_bg_base_calculo %1! @w_valor_base %2!',@w_bg_base_calculo,@w_valor_base

If @w_valor_base = 0
Begin
   
   ---PRINT 'MENSAJE INFORMATIVO --> EL VALOR BASE ES 0  SE ACTUALIZARA COMISION FAG EN 0'
   
   update ca_amortizacion
   set am_cuota     = 0,
       am_acumulado = 0
   from ca_dividendo
   where am_operacion =  @i_operacionca
   and   am_concepto  in (@w_concepto_asociado, @w_parametro_fag)
   and   am_estado    != 3
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo
   and   di_estado not in (2,3)
   
   
   update ca_rubro_op
   set ro_valor        = 0,
       ro_base_calculo = 0
   where ro_operacion =  @i_operacionca
   and   ro_concepto  in (@w_concepto_asociado, @w_parametro_fag)
   
   return 0
end




if @w_bg_base_calculo  <> @w_valor_base
begin
   
   --GENERAR NUEVAMENTE EL VALOR
   
   exec @w_return           = sp_rubro_calculado
   @i_tipo                  = 'Q',
   @i_concepto              = @w_parametro_fag,
   @i_operacion             = @i_operacionca,
   @i_porcentaje_cobertura  = 'S',
   @i_usar_tmp              = 'N',
   @i_tipo_garantia         = @w_tipo_garantia,
   @i_porcentaje            = @w_porcentaje,
   @o_nro_garantia          = @w_nro_garantia out,
   @o_base_calculo          = @w_base_calculo out,
   @o_valor_rubro           = @w_valor_rubro out
   
   if @w_return != 0 return @w_return

   ---Calulo del iva  rubro asociado asociado
   
   select @w_valor_rubro = round(@w_valor_rubro, @i_num_dec)

   select  @w_factor_a = isnull(vd_valor_default,0)
   from    ca_valor, ca_valor_det
   where   va_tipo   = @w_referencial_a 
   and     vd_tipo   = @w_referencial_a
   and     vd_sector = @i_sector

   select @w_valor_rubro_a = round(@w_factor_a * @w_valor_rubro / 100.0, @i_num_dec)

   ---PRINT  'recalgag.sp @w_valor_rubro_a %1! @w_base_calculo %2! @w_factor_a %3!',@w_valor_rubro_a,@w_base_calculo,@w_factor_a
  
  
  ---ACTUALIZAR RUBROS EN TABLA AMORTIZACION
  

   update ca_amortizacion
   set am_cuota     = @w_valor_rubro,
       am_acumulado = @w_valor_rubro
   where am_operacion = @i_operacionca
   and   am_concepto  = @w_parametro_fag
   and   am_cuota    != 0
   and   am_estado   != 3

   update ca_amortizacion
   set am_cuota     = @w_valor_rubro_a,
       am_acumulado = @w_valor_rubro_a
   where am_operacion = @i_operacionca
   and   am_concepto  = @w_concepto_asociado  
   and   am_cuota    != 0
   and   am_estado   != 3

   update ca_rubro_op
   set ro_valor        = @w_valor_rubro,
       ro_nro_garantia = @w_nro_garantia,
       ro_base_calculo = @w_base_calculo,
       ro_porcentaje   = @w_porcentaje
   where ro_operacion = @i_operacionca
   and   ro_concepto  = @w_parametro_fag

   update ca_rubro_op
   set ro_valor      = @w_valor_rubro_a,
       ro_porcentaje =  @w_factor_a
   where ro_operacion = @i_operacionca
   and   ro_concepto  = @w_concepto_asociado  

end  -- tienen valores base diferentes 
     
return 0
go
