/***********************************************************************/
/*	Archivo:            conver.sp                                      */
/*	Stored procedure:   sp_conversion_moneda                           */
/*	Base de datos:  	cob_cartera                                    */
/*	Producto:           Cartera                                        */
/*	Disenado por:                                                      */
/*	Fecha de escritura:                                                */
/***********************************************************************/
/*                     IMPORTANTE                                      */
/*	Este programa es parte de los paquetes bancarios propiedad de      */
/*	"MACOSA"                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como         */
/*	cualquier alteracion o agregado hecho por alguno de sus            */
/*	usuarios sin el debido consentimiento por escrito de la            */
/*	Presidencia Ejecutiva de MACOSA o su representante                 */
/***********************************************************************/  
/*                     PROPOSITO                                       */
/*      Permite consultar la cotizacion de la moneda asi como convertir*/
/*      a monto en moneda legal                                        */
/***********************************************************************/
/*                                 MODIFICACIONES                      */
/*   FECHA           AUTOR             RAZON                           */
/*   21/Jun/2020     Luis Ponce        CDIG Multimoneda                */
/***********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_conversion_moneda')
        drop proc sp_conversion_moneda
go

create proc sp_conversion_moneda
@s_date                 datetime,
@i_opcion               char(1)  = 'L',
@i_operacion            char(1)  = NULL,
@i_cot_contable         char(1)  = NULL,
@i_moneda_monto		tinyint  = null,
@i_moneda_resultado	tinyint  = null,
@i_monto		money 	 = null,
@i_fecha                datetime = null, 
@o_monto_resultado	money 	 = null out,
@o_tipo_cambio          float 	 = null out
as
declare
@w_sp_name		descripcion,
@w_return		int,
@w_num_dec		smallint,
@w_moneda_n		tinyint,
@w_num_dec_n		smallint,
@w_cot_ori		money,
@w_cot_des		float,
@w_monto_ori_nac MONEY, --@w_monto_ori_pes	money,
@w_monto_nac_des MONEY --@w_monto_pes_des	money


/** SELECCION DE VARIABLES **/
select @w_sp_name = 'sp_conversion_moneda'


-- INICIALIZACION DE VARIABLES
if @i_fecha is null
   select @i_fecha = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7

select @w_cot_ori = 1,
       @w_cot_des = 1

exec @w_return = sp_decimales
@i_moneda       = @i_moneda_resultado,
@o_decimales    = @w_num_dec out,
--@o_mon_nacional = @w_moneda_n out,
@o_dec_nacional = @w_num_dec_n out
  
   if @w_return != 0
      return @w_return

-- Codigo de moneda local
select @w_moneda_n = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
  and pa_nemonico = 'MLO' --'CMNAC'   
  
  
  

exec @w_return = cob_cartera..sp_consulta_divisas
   @s_date                = @s_date,
   @t_trn                 = 77541,
   @i_operacion           = @i_operacion,
   @i_cot_contable        = @i_cot_contable,
   @i_moneda_origen       = @i_moneda_monto,
   @i_valor               = @i_monto,
   @i_moneda_destino      = @w_moneda_n,
   @o_cotizacion          = @w_cot_ori out--,  
--   @o_valor_convertido    = @o_monto_resultado out,  
--   @o_tipo_op             = @o_tipo_op out  

/*
PRINT '@i_monto FFF ' + CAST(@i_monto AS VARCHAR)
PRINT '@i_moneda_monto FFF ' + CAST(@i_moneda_monto AS VARCHAR)
PRINT '@w_moneda_n FFF ' + CAST(@w_moneda_n AS VARCHAR)
*/

   if @w_return <> 0
      return @w_return

exec @w_return = cob_cartera..sp_consulta_divisas
   @s_date                = @s_date,
   @t_trn                 = 77541,
   @i_operacion           = @i_operacion,
   @i_cot_contable        = @i_cot_contable,
   @i_moneda_origen       = @i_moneda_resultado,
   @i_valor               = @i_monto,
   @i_moneda_destino      = @w_moneda_n,
   @o_cotizacion          = @w_cot_des out--,  
--   @o_valor_convertido    = @o_monto_resultado out,  
--   @o_tipo_op             = @o_tipo_op out  

   if @w_return <> 0
      return @w_return
/*   
PRINT '@i_monto EEE ' + CAST(@i_monto AS VARCHAR)
PRINT '@i_moneda_resultado EEE ' + CAST(@i_moneda_resultado AS VARCHAR)
PRINT '@w_moneda_n EEE ' + CAST(@w_moneda_n AS VARCHAR)
*/
   
   --/** CONVERSION DE MONTOS */ 
   
   --De monto origen a moneda nacional
   select @w_monto_ori_nac = round(@i_monto*@w_cot_ori,@w_num_dec_n)
   
   --De moneda nacional a monto destino
   select @w_monto_nac_des = round(@w_monto_ori_nac / @w_cot_des, @w_num_dec)
/*
PRINT '@i_monto EEE ' + CAST(@i_monto AS VARCHAR)
PRINT '@w_cot_ori EEE ' + CAST(@w_cot_ori AS VARCHAR)
PRINT '@w_moneda_n EEE ' + CAST(@w_moneda_n AS VARCHAR)
*/   
   
   --/** RETORNO DE VALORES **
   select @o_monto_resultado = @w_monto_nac_des
   select @o_tipo_cambio = @w_cot_ori / @w_cot_des



--LPO CDIG Multimoneda Se comenta INICIO
/*
if @i_opcion = 'L' begin

   if @i_moneda_monto = @i_moneda_resultado begin
      select @o_monto_resultado = @i_monto
      select @o_tipo_cambio = 1.0
      return 0
   end
   
   -- INICIALIZACION DE VARIABLES
   if @i_fecha is null
      select @i_fecha = fc_fecha_cierre
      from   cobis..ba_fecha_cierre
      where  fc_producto = 7


   select @w_cot_ori = 1,
          @w_cot_des = 1

   exec @w_return = sp_decimales
   @i_moneda       = @i_moneda_resultado,
   @o_decimales    = @w_num_dec out,
   @o_mon_nacional = @w_moneda_n out,
   @o_dec_nacional = @w_num_dec_n out
  
   if @w_return != 0
      return @w_return
 
   -- SELECCION DE COTIZACIONES
   exec sp_buscar_cotizacion
        @i_moneda     = @i_moneda_monto,
        @i_fecha      = @i_fecha,
        @o_cotizacion = @w_cot_ori output
   
   exec sp_buscar_cotizacion
        @i_moneda     = @i_moneda_resultado,
        @i_fecha      = @i_fecha,
        @o_cotizacion = @w_cot_des output

   --** CONVERSION DE MONTOS **
  

   --* De monto origen a pesos *
   select @w_monto_ori_pes = round(@i_monto*@w_cot_ori,@w_num_dec_n)

   --** De pesos a monto destino *
   select @w_monto_pes_des = round(@w_monto_ori_pes / @w_cot_des, @w_num_dec)  
 
      
   --** RETORNO DE VALORES **
   select @o_monto_resultado = @w_monto_pes_des
   select @o_tipo_cambio = @w_cot_ori / @w_cot_des


end --@i_opcion = 'L'
*/
--LPO CDIG Multimoneda Se comenta FIN

return 0

go
