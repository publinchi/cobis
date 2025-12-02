/************************************************************************/
/*      Archivo:                valorpre.sp                             */
/*      Stored procedure:       sp_calculo_valor_presente               */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     Feb.2003                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Procedimiento que retorna el calculo del valor presente .       */
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calculo_valor_presente')
   drop proc sp_calculo_valor_presente
go

create proc sp_calculo_valor_presente
@i_tasa_prepago          float = 0,
@i_valor_int_cap         money = 0,
@i_dias                  int   = 0,
@i_valor_futuro_int      money = 0,
@i_numdec_op             smallint = 0,
@o_monto	         money  = null out
as
declare
@w_return        int,
@w_error         int,
@w_vp_int        money,
@w_no_cobrado_int  money


  --PRINT 'llego a sp_calculo_valor_presente  @i_valor_int_cap %1! @i_tasa_prepago %2!',@i_valor_int_cap,@i_tasa_prepago
  --COMO LO CALCULA EL BANCO BAC, SETA FORMULA RETORNA SOLO EL VALOR DE INTERES EN VP
  select @w_vp_int = (@i_tasa_prepago * @i_valor_int_cap) / (100 * 360) * @i_dias
  select @w_vp_int = round((@i_valor_futuro_int -  @w_vp_int),@i_numdec_op)



select @o_monto = isnull(@w_vp_int,0.00)

return 0
go

