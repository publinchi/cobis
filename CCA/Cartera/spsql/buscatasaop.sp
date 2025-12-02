/************************************************************************/
/*   Archivo:              buscatasaop.sp                               */
/*   Stored procedure:     sp_buscar_tasa_operacion                     */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         ELcira Pelaez                                */
/*   Fecha de escritura:   May. 2007                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Este procedimiento permite:                                        */
/*   Busacr la tasa  para una obligacion la cual debe ser la ultima     */
/*   antes del cambio por limite de usuara                              */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*   Junio-22--2007     Elcira PElaez        def 8394                   */
/*   Octubre-17--2007   Elcira PElaez        def 8886                   */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_buscar_tasa_operacion')
   drop proc sp_buscar_tasa_operacion
go
---Inc. 31446 Sep-13-2011 partiendo de la version 3
create procedure sp_buscar_tasa_operacion(
   @s_date        datetime,
   @i_operacionca int
)
as
declare
   @w_sp_name              descripcion,
   @w_error                int,
   @w_factor               float,
   @w_signo                char(1),
   @w_concepto             catalogo,
   @w_sec                  int,
   @w_fecha_ult_proceso    datetime,
   @w_op_fecha_liq         datetime,
   @w_re_reajuste_especial char(1),
   @w_re_desagio           char(1),
   @w_re_fecha             datetime,
   @w_porcentaje           float,
   @w_fecha_sec            datetime,
   @w_ut_referencial             catalogo,
   @w_ut_signo                   char(1),
   @w_ut_factor                  float,
   @w_ut_reajuste_especial       char(1),
   @w_ut_tipo_puntos             char(1),
   @w_ut_fecha_pri_referencial   datetime,  
   @w_ut_porcentaje_efa          float,
   @w_ut_porcentaje              float,
   @w_valor_tasa_ref             float,
   @w_ts_tasa_ref                catalogo
   
 

select @w_sp_name = 'sp_buscar_tasa_operacion'

select @w_concepto = ro_concepto
from   ca_rubro_op with (nolock)
where  ro_operacion = @i_operacionca
and    ro_tipo_rubro = 'I'

if @@rowcount = 0
   return 722001 

select @w_fecha_ult_proceso     = op_fecha_ult_proceso,
       @w_op_fecha_liq          = op_fecha_liq,
       @w_ut_reajuste_especial  = op_reajuste_especial
from   ca_operacion with (nolock)
where  op_operacion = @i_operacionca


select @w_fecha_sec = max(re_fecha)
from   ca_reajuste with (nolock)
where  re_operacion = @i_operacionca
and    re_fecha <= @w_fecha_ult_proceso

select @w_sec = isnull((re_secuencial),0)
from   ca_reajuste with (nolock),
       ca_reajuste_det with (nolock)
where  re_operacion = @i_operacionca
and    re_fecha = @w_fecha_sec
and    isnull(re_desagio,'') != 'e' --OTRO AUTOMATICO
and    red_operacion = re_operacion
and    red_secuencial = re_secuencial
and    isnull(red_referencial,'') not in ('TLU','TLU1','TLU2','TLU3','TLU4','TMM')

if @w_sec > 0
begin
   select @w_ut_referencial          = red_referencial,
          @w_ut_signo                = red_signo,
          @w_ut_factor               = red_factor,
          @w_ut_reajuste_especial    = re_reajuste_especial,
          @w_ut_tipo_puntos           = re_desagio,
          @w_re_fecha             = re_fecha,
          @w_porcentaje           = red_porcentaje
   from ca_reajuste_det with (nolock),ca_reajuste with (nolock)
   where red_operacion = @i_operacionca
   and   red_secuencial = @w_sec
   and   red_secuencial = re_secuencial
   and   red_operacion  = re_operacion 

   ---PRINT 'buscatasaop.sp va para sp_tasas_actuales con porcentaje :' + CAST (@w_ut_porcentaje as varchar) + '@w_ut_porcentaje_efa: ' + CAST (@w_ut_porcentaje_efa as varchar)
         
   exec @w_error = sp_tasas_actuales
   @i_operacionca       =  @i_operacionca,
   @i_referencia        =  @w_ut_referencial,
   @i_concepto          =  @w_concepto,
   @i_reajuste          =  'S',
   @i_fecha_proceso     =  @w_re_fecha,
   @o_tasa_nom          =  @w_ut_porcentaje     OUTPUT,
   @o_tasa_efa          =  @w_ut_porcentaje_efa OUTPUT,
   @o_valor_tasa_ref    =  @w_valor_tasa_ref OUTPUT,
   @o_fecha_tasa_ref    =  @w_ut_fecha_pri_referencial  OUTPUT,
   @o_ts_tasa_ref       =  @w_ts_tasa_ref    OUTPUT
     
   if @w_error != 0  return @w_error
   
   ---PRINT 'buscatasaop.sp Datos Reajuste salio de  sp_tasas_actuales con porcentaje :' + CAST (@w_ut_porcentaje as varchar) + '@w_ut_porcentaje_efa: ' + CAST (@w_ut_porcentaje_efa as varchar)
   
     
end
ELSE
begin
      
   select 
   @w_ut_referencial     = ro_referencial,
   @w_ut_signo           = ro_signo,
   @w_ut_porcentaje      = ro_porcentaje,
   @w_ut_porcentaje_efa  = ro_porcentaje_efa,
   @w_ut_tipo_puntos     = ro_tipo_puntos,
   @w_ut_factor          = ro_factor
   from   ca_rubro_op with (nolock)
   where  ro_operacion           = @i_operacionca
   and    ro_concepto            = @w_concepto
  
   select  @w_ut_fecha_pri_referencial = @w_fecha_ult_proceso
   
   ---PRINT 'buscatasaop.sp Datos ca_rubro_op'
   
end

if @w_re_reajuste_especial  is null
 select @w_re_reajuste_especial = 'N'
 
if @w_re_desagio is null
 select @w_re_desagio = 'B'
    
delete ca_ultima_tasa_op           
where ut_operacion = @i_operacionca

---VALIDACION CAMPOS

if @w_ut_referencial is null
   select @w_factor = @w_porcentaje

   insert into  ca_ultima_tasa_op with (rowlock) (
   ut_operacion,             ut_concepto,                 ut_referencial, 
   ut_signo,                 ut_factor,                   ut_reajuste_especial,
   ut_tipo_puntos,           ut_fecha_pri_referencial,    ut_fecha_act,
   ut_porcentaje,            ut_porcentaje_efa) 
   values(
   @i_operacionca,           @w_concepto,                 @w_ut_referencial,    
   @w_ut_signo,              @w_ut_factor,                @w_ut_reajuste_especial,   
   @w_ut_tipo_puntos,        @w_ut_fecha_pri_referencial, @s_date,
   @w_ut_porcentaje,         @w_ut_porcentaje_efa)

   if @@error <> 0 return 710001
   
if @@error != 0
   return 722002
      
return 0
go
