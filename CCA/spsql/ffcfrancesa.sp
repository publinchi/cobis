/************************************************************************/
/*      Archivo:                ffcfrancesa.sp                          */
/*      Stored procedure:       sp_ffinanciero_cfrancesa                */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     Agosto-2019                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Cálculo de cuota Francesa para flujo financiero                 */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ffinanciero_cfrancesa')
    drop proc sp_ffinanciero_cfrancesa
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_ffinanciero_cfrancesa
(  
   @i_operacion        int,
   @i_plazo            smallint,
   @o_cuota            money  out 
)

as declare
   @w_return                int,
   @w_sp_name               varchar(32),
   @w_fec_proceso           datetime,
   @w_error                 int,
   @w_tplazo                catalogo,
   @w_cuota                 money,
   @w_dias_anio             smallint,
   @w_moneda                tinyint,
   @w_monto                 money,
   @w_monto_cap             money, 
   @w_tasa_int              float,
   @w_tasa_asociado         float,
   @w_plazo                 smallint,
   @w_num_dec               tinyint,
   @w_periodo_crecimiento   smallint,   
   @w_tasa_crecimiento      float,
   @w_dias_int              tinyint,
   @w_parametro_sincap      catalogo,
   @w_rub_asociado          catalogo,
   @w_ro_porc_aso           float,
   @w_maximo_segincap       money,
   @w_porcentaje_iva        float,
   @w_toperacion            catalogo
   
   
--CODIGO DEL RUBRO SEGURO DE INCAPACIDAD
select @w_parametro_sincap = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'SEGINC'

--VALOR MAXIMO A COBRAR POR SEGURO DEL SALDO DESEMBOLSADO
select @w_maximo_segincap = pa_money
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'MSINCA'

--PARAMETRO IVA
select @w_porcentaje_iva = 1 + (pa_float / 100) 
from   cobis..cl_parametro
where  pa_producto = 'CTE'
and    pa_nemonico = 'PIVA'


--Obtener datos para calcular la cuota    
select @w_monto                 = isnull(op_monto,0),
       @w_plazo                 = @i_plazo,
       @w_moneda                = op_moneda,
       @w_dias_anio             = op_dias_anio,
       @w_periodo_crecimiento   = op_periodo_crecimiento,
       @w_tasa_crecimiento      = op_tasa_crecimiento,
       @w_tplazo                = op_tplazo,
       @w_toperacion            = op_toperacion
from ca_operacion
where op_operacion = @i_operacion   

if @@rowcount = 0
begin
   select @w_error =  171096
   goto ERROR
end


select @w_tasa_int = sum(ro_porcentaje) --TASA DE INTERES TOTAL
from   ca_rubro_op
where  ro_operacion  = @i_operacion
and    ro_fpago      in ('P', 'A')
and    ro_tipo_rubro = 'I'

select @w_tasa_asociado = isnull(sum(a.ro_porcentaje), 0 ) --TASA DE INTERES TOTAL
from   ca_rubro_op as a inner join cob_cartera..ca_rubro_op as b 
       on b.ro_operacion = a.ro_operacion 
       and b.ro_concepto = a.ro_concepto_asociado 
       and b.ro_fpago in ('P', 'A') 
        and b.ro_tipo_rubro = 'I' 
where a.ro_operacion = @i_operacion

--TASA DE INTERES TOTAL
if @w_tasa_asociado > 0
   select @w_tasa_int = @w_tasa_int + @w_tasa_asociado
   
 
select @w_monto_cap = sum(ro_valor) 
from   ca_rubro_op
where  ro_operacion = @i_operacion
and    ro_fpago     = 'P'
and    ro_tipo_rubro= 'C'

select @w_dias_int = td_factor 
from   ca_tdividendo
where  td_tdividendo  = @w_tplazo


exec @w_error     = sp_decimales
     @i_moneda    = @w_moneda,
     @o_decimales = @w_num_dec out

exec @w_error = sp_formula_francesa
     @i_operacionca         = @i_operacion,
     @i_monto_cap           = @w_monto_cap,
     @i_tasa_int            = @w_tasa_int,
     @i_dias_anio           = @w_dias_anio,
     @i_num_dec             = @w_num_dec, 
     @i_dias_cap            = @w_dias_int,              
     @i_num_dividendos      = @w_plazo ,
     @i_periodo_crecimiento = @w_periodo_crecimiento,
     @i_tasa_crecimiento    = @w_tasa_crecimiento,
     @o_cuota               = @w_cuota out 

if (@w_error <> 0)
    goto ERROR
    

select @w_ro_porc_aso  = ro_porcentaje / 100
from   ca_rubro_op
where  ro_operacion  = @i_operacion
and    ro_concepto   = @w_parametro_sincap

if (@w_cuota * @w_ro_porc_aso ) >= @w_maximo_segincap
    select @w_cuota = @w_cuota + @w_maximo_segincap * @w_porcentaje_iva
else
    select @w_cuota = @w_cuota + ((@w_ro_porc_aso * @w_porcentaje_iva)* @w_cuota)
    
select @o_cuota = @w_cuota

return 0      


ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null, 
     @t_from  = @w_sp_name,
     @i_num   = @w_error,
	 @i_sev   = 0
    
return @w_error

go