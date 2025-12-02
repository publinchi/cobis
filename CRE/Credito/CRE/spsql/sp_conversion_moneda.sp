/************************************************************************/
/*  Archivo:                sp_conversion_moneda.sp                     */
/*  Stored procedure:       sp_conversion_moneda                        */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Paulina Ivarra                              */
/*  Fecha de Documentacion: 23/06/2021                                  */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/06/21          cveintemilla     Emision Inicial                  */
/*  20/07/22          bduenas          Correccion de asignacion de valor*/
/*                                     para moneda resultado            */
/* **********************************************************************/

USE cob_credito
GO
IF OBJECT_ID ('dbo.sp_conversion_moneda') IS NOT NULL
    DROP PROCEDURE dbo.sp_conversion_moneda
GO
create proc sp_conversion_moneda
@s_date             datetime       = null,
@t_show_version     bit            = 0,    -- show the version of the stored procedure  
@i_fecha_proceso    datetime       = null,
@i_moneda_monto     tinyint        = null,
@i_moneda_resultado tinyint        = null,
@i_monto            money          = null, 
@o_monto_resultado  money          = null out,
@o_monto_mn_resul   money          = null out,
@o_cot_moneda       float          = null out,
@o_cot_result       float          = null out
as
declare
@w_sp_name          descripcion,
@w_return           int,
@w_cot_moneda       float,
@w_cot_result       float,
@w_resultado1       money,
@w_resultado2       money,
@w_num_dec          smallint,
@w_moneda_n         tinyint,
@w_num_dec_n        smallint,
@w_tcot_moneda      char(1),
@w_tcot_result      char(1),
@w_resultado1_d     decimal(38,10),
@w_resultado2_d     decimal(38,10),
@w_valor_convertido money,
@w_cotizacion       float,
@w_msg              varchar(255),
@w_moneda_local     int
        
/** SELECCION DE VARIABLES **/
select @w_sp_name = 'sp_conversion_moneda'

if @t_show_version = 1
begin
   print 'Stored procedure sp_conversion_moneda, Version 4.0.0.0'   
   return 0
end

select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'MLO'
and    pa_producto = 'ADM'

select @w_resultado1_d = null,
       @w_resultado2_d = null
 
if @i_fecha_proceso is null
   select @i_fecha_proceso = fp_fecha
   from   cobis..ba_fecha_proceso


/** CONSULTA DE DECIMALES **/
exec @w_return  = cob_cartera..sp_decimales
   @i_moneda       = @i_moneda_resultado,
   @o_decimales    = @w_num_dec out,
   @o_mon_nacional = @w_moneda_n out,
   @o_dec_nacional = @w_num_dec_n out
  
if @w_return != 0  return @w_return

if @i_moneda_resultado is null
   select @i_moneda_resultado = @w_moneda_n,
          @w_num_dec          = @w_num_dec_n
          

if @i_moneda_monto = @i_moneda_resultado 
begin
   /** SELECCION COTIZACION MONEDA DEL MONTO **/
   select @w_cot_moneda = ct_valor     --MSU (2DIC99)
   from   cob_conta..cb_cotizacion  
   where  ct_empresa = 1
   and    ct_moneda  = @i_moneda_monto
   and    ct_fecha = (select max(ct_fecha)
                      from cob_conta..cb_cotizacion
                      where  ct_empresa = 1
                      and    ct_moneda  = @i_moneda_monto
                      and    ct_fecha  <= @i_fecha_proceso)

   if @@rowcount = 0 return 701070

   select @w_cot_result  = @w_cot_moneda
      
end
else 
begin
   select @w_cot_moneda = ct_valor     --MSU (2DIC99)
   from   cob_conta..cb_cotizacion  
   where  ct_empresa = 1
   and    ct_moneda  = @i_moneda_monto
   and    ct_fecha = (select max(ct_fecha)
                      from cob_conta..cb_cotizacion
                      where  ct_empresa = 1
                      and    ct_moneda  = @i_moneda_monto
                      and    ct_fecha  <= @i_fecha_proceso)
                      


   if @@rowcount = 0 return 701070 

  /** SELECCION COTIZACION MONEDA DE RESULTADO **/
   select @w_cot_result = ct_valor
   from   cob_conta..cb_cotizacion --Optimizacion 2001
   where  ct_empresa = 1
   and    ct_moneda  = @i_moneda_resultado
    and    ct_fecha = (select max(ct_fecha)
                      from cob_conta..cb_cotizacion
                      where  ct_empresa = 1
                      and    ct_moneda  = @i_moneda_resultado
                      and    ct_fecha  <= @i_fecha_proceso)


   if @@rowcount = 0 return 701070

end

if @i_monto is not null
begin 
      --print 'Monto no null'
      /**CONVERSION DEL MONTO **/
      select @w_resultado1 = round(@i_monto * @w_cot_moneda,@w_num_dec)
      select @w_resultado2 = round(@w_resultado1 / @w_cot_result,@w_num_dec)
end

/**RETORNO DE VALORES**/
select @o_monto_resultado = @w_resultado2,
       @o_monto_mn_resul  = @w_resultado1,
       @o_cot_moneda      = @w_cot_moneda,
       @o_cot_result      = @w_cot_result
       
return 0
                                            

go