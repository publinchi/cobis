/***************************************************************************/
/*   Archivo:              contrtas.sp                                     */
/*   Stored procedure:     sp_control_tasa                                 */
/*   Base de datos:        cob_cartera                                     */
/*   Producto:             Cartera                                         */
/*   Disenado por:         Patricio Narvaez                                */
/*   Fecha de escritura:   27/Mayo/98                                      */
/***************************************************************************/
/*   IMPORTANTE                                                            */
/*   Este programa es parte de los paquetes bancarios propiedad de         */
/*   'MACOSA'                                                              */
/*   Su uso no autorizado queda expresamente prohibido asi como            */
/*   cualquier alteracion o agregado hecho por alguno de sus               */
/*   usuarios sin el debido consentimiento por escrito de la               */
/*   Presidencia Ejecutiva de MACOSA o su representante.                   */
/***************************************************************************/  
/*   PROPOSITO                                                             */
/*   Controla si la tasa total de interes a cobrarse,no sobrepasa  el      */
/*      1.5*IBC (Generacion de la Tabla de Amortizacion).  Devuelve el     */
/*      el valor de la tasa total de la operacion en efectiva anual, para  */
/*      tablas temporales y tablas definitivas                             */ 
/***************************************************************************/  
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_control_tasa')
   drop proc sp_control_tasa
go

create proc sp_control_tasa
@i_operacionca     int,
@i_temporales      char(1) = 'S',
@i_ibc             char(1) = 'S',
@o_tasa_total_efe  float   = null output

as
declare
   @w_return               int,
   @w_tasa_efe_anual       float,
   @w_tasa_final           float,
   @w_ibc                  float,
   @w_dias_anio            smallint,
   @w_base_calculo         char(1),
   @w_modalidad_op         char(1),
   @w_periodo_op           char(1),
   @w_periodo_int          int,
   @w_sector               catalogo,
   @w_concepto_tlu         varchar(11),
   @w_valor_original       float,
   @w_signo_ibc            char(1),
   @w_factor_ibc           float,
   @w_referencia_ibc       varchar(10) ,
   @w_tipo_puntos_ibc      char(1), 
   @w_fecha_ult_proc       datetime,
   @w_factor               tinyint,
   @w_moneda               int,
   @w_num_dec_tapl         tinyint,
   @w_decimales_ibc        tinyint,
   @w_ibc_final            float,
   @w_moneda_uvr           tinyint,
   @w_moneda_local         tinyint,
   @w_op_clase             char,
   @w_rowcount             int

select @w_tasa_efe_anual = 0

-- MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0  
   return 710076

-- CONSULTA CODIGO DE MONEDA LOCAL
select  @w_moneda_local = pa_tinyint
from    cobis..cl_parametro
where   pa_nemonico = 'MLO'
and     pa_producto = 'ADM'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0  
   return 710076

-- REALIZAR EL PROCESO PARA TABLAS TEMPORALES
if @i_temporales = 'S'
begin
   -- PERIODICIDAD ORIGEN DE LA OPERACION ES LA PERIODICIDAD ORIGEN DE   LOS RUBROS EXISTENTES
   select @w_dias_anio      = opt_dias_anio,
          @w_periodo_op     = opt_tdividendo,
          @w_base_calculo   = opt_base_calculo,
          @w_periodo_int    = opt_periodo_int,
          @w_sector         = opt_sector,
          @w_fecha_ult_proc = opt_fecha_ult_proceso,
          @w_moneda         = opt_moneda,
          @w_op_clase       = opt_clase
   from   ca_operacion_tmp
   where  opt_operacion = @i_operacionca
   
   --  OBTENCION DEL LA TASA TOTAL EN EFECTIVO ANUAL A COBRAR
   select @w_tasa_efe_anual = sum(rot_porcentaje_efa) 
   from   ca_rubro_op_tmp
   where  rot_operacion = @i_operacionca
   and    rot_fpago     in ('P','A')
   and    rot_tipo_rubro= 'I'
   and    rot_concepto not like 'C%'
   and    rot_referencial is not null
   
   select @w_modalidad_op = rot_fpago,
          @w_num_dec_tapl = rot_num_dec
   from   ca_rubro_op_tmp
   where  rot_operacion = @i_operacionca
   and    rot_fpago     in ('P','A')
   and    rot_tipo_rubro= 'I'
end

-- REALIZAR EL PROCESO PARA TABLAS DEFINITIVAS
if @i_temporales = 'N'
begin
   -- PERIODICIDAD ORIGEN DE LA OPERACION ES LA PERIODICIDAD ORIGEN DE LOS RUBROS EXISTENTES
   select @w_dias_anio      = op_dias_anio,
          @w_periodo_op     = op_tdividendo,
          @w_base_calculo   = op_base_calculo,
          @w_periodo_int    = op_periodo_int,
          @w_sector         = op_sector,
          @w_fecha_ult_proc = op_fecha_ult_proceso,
          @w_moneda         = op_moneda,
          @w_op_clase       = op_clase
   from   ca_operacion
   where  op_operacion = @i_operacionca
   
   -- OBTENCION DEL LA TASA TOTAL EN EFECTIVO ANUAL A COBRAR
   select @w_tasa_efe_anual = sum(ro_porcentaje_efa) 
   from   ca_rubro_op
   where  ro_operacion = @i_operacionca
   and    ro_fpago     in ('P','A')
   and    ro_tipo_rubro= 'I'
   and    ro_concepto not like 'C%'
   and    ro_referencial is not null
   
   select @w_modalidad_op = ro_fpago,
          @w_num_dec_tapl = ro_num_dec
   from   ca_rubro_op
   where  ro_operacion = @i_operacionca
   and    ro_fpago     in ('P','A')
   and    ro_tipo_rubro= 'I'
end

if @w_moneda = @w_moneda_local or @w_moneda = @w_moneda_uvr
begin
   select  @w_concepto_tlu = pa_char
   from    cobis..cl_parametro
   where   pa_nemonico = 'TLU' --TASA LIMITE DE USURA
   and     pa_producto = 'CCA' --'ADM'  DESCOMENTAR CON EL ADMIN
   set transaction isolation level read uncommitted
end
ELSE
begin
   select  @w_concepto_tlu = pa_char
   from    cobis..cl_parametro
   where   pa_nemonico = 'TLUEX' -- TASA LIMITE DE USURA MONEDA EXT.
   and     pa_producto = 'CCA' --'ADM"  DESCOMENTAR CON EL ADMIN
   set transaction isolation level read uncommitted
end

---EPB:oct-29-2001
-- DECIMALES PARA IBC
select @w_decimales_ibc = vd_num_dec
from   ca_valor_det
where  vd_tipo = @w_concepto_tlu
and    vd_sector = @w_sector

select @w_concepto_tlu = rtrim(@w_concepto_tlu) + @w_op_clase

select @i_ibc = 'N'
if @i_ibc = 'S'
begin
   -- OBTENER EL VALOR DEL IBC EN EFECTIVO ANUAL
   exec @w_return     = sp_tasa
        @i_codigo          = @w_concepto_tlu,
        @i_sector          = @w_sector,
        @i_fecha_ult_proc  = @w_fecha_ult_proc,
        @i_dias_anio       = @w_dias_anio,
        @i_base_calculo    = @w_base_calculo,
        @i_efe_anual       = 'S', 
        @o_valor           = @w_ibc out
   
   if @w_return <> 0
      return @w_return  
   ---EPB:OCT-29-2001 REDONDEAR A LOS DECIMALES DEL IBC
   select @w_ibc_final =  1.5 * @w_ibc
   select @w_tasa_efe_anual = round(@w_tasa_efe_anual, @w_decimales_ibc)     
   ---TASA DE INTERES SUPERA EL MAXIMO PERMITIDO*/
   if @w_tasa_efe_anual > @w_ibc_final
   begin      
      return 710094 
   end
end                                                	

-- TASA TOTAL DEL PRESTAMO EN EFECTIVO ANUAL
select @o_tasa_total_efe = @w_tasa_efe_anual

return 0

go
