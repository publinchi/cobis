/************************************************************************/
/*      Archivo:                verifi_fec.sp                           */
/*      Stored procedure:       sp_verifica_fecha                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Jose Julian Cortes                      */
/*      Fecha de escritura:     May. 2011                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Validacion de fechas para generacion de tabla de                */
/*      amortizacion                                                    */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      16/May/2011     Jose Cortes     Validacion fecha segun operacion*/ 
/*      01/May/2022     Guisela Fernandez  Se comenta prints            */
/*                                                                      */ 
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_verifica_fecha')
    drop proc sp_verifica_fecha
go
create proc sp_verifica_fecha
   @s_user              login        = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   @s_ofi               smallint     = null,
   @i_toperacion        catalogo     = null,
   @i_dia_pago          tinyint      = null
   
      
as
declare 
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_msg               mensaje,
   @w_pa_dimive               tinyint,
   @w_pa_dimave               tinyint,
   @w_dt_control_dia_pago     char(1),
   @w_dt_fecha_fija           char(1),
   @w_dt_dia_pago             int


/* CONTROLAR DIA MINIMO DEL MES PARA FECHAS DE VENCIMIENTO */
select @w_pa_dimive = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'DIMIVE'
and   pa_producto = 'CCA'

if @@rowcount = 0 begin
   --GFP se suprime print
   select @w_error = 2101084 --print 'NO SE ENCUENTRA EL PARAMETRO GENERAL DIMIVE DE CARTERA'
   goto ERROR
end


/* CONTROLAR DIA MAXIMO DEL MES PARA FECHAS DE VENCIMIENTO */
select @w_pa_dimave = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'DIMAVE'
and   pa_producto = 'CCA'


if @@rowcount = 0 begin
   --GFP se suprime print
   select @w_error = 2101084 --print 'NO SE ENCUENTRA EL PARAMETRO GENERAL DIMAVE DE CARTERA'
   goto ERROR
end


select @w_dt_control_dia_pago = dt_control_dia_pago,
       @w_dt_fecha_fija       = dt_fecha_fija,
       @w_dt_dia_pago         = dt_dia_pago
from ca_default_toperacion where dt_toperacion = @i_toperacion 


/*VALIDACION DE LA FECHA DE PAGO*/

if @w_dt_control_dia_pago = 'S' and @i_dia_pago > 0 begin 
   -- R-> Dentro de un rango establecido por parametros generales  
   if @i_dia_pago < @w_pa_dimive or @i_dia_pago > @w_pa_dimave begin
         --GFP se suprime print
         --print ' Dia de pago fijo no esta en el rango de dias definido para el pago ' + cast(@w_pa_dimive as varchar) + '-' + cast(@w_pa_dimave as varchar)+ ' se coloca el dia 15 por defecto'
         select @i_dia_pago = 15
   end
end
else begin   
   if @w_dt_fecha_fija = 'S' and @i_dia_pago <> @w_dt_dia_pago begin
      select @i_dia_pago = isnull(@i_dia_pago, @w_dt_dia_pago)
      -- P-> Libre de fechas predefinidas, se tomara la fecha de creacion del tramite o de la operación o el parametrizado en la linea
	  --GFP se suprime print
      --print ' Dia de Pago No Parametrizado Para la Linea de Credito - Dia Parametrizado: ' + cast(@w_dt_dia_pago as varchar) 
      select @w_error = 101114
      goto ERROR
   end
end

return 0

ERROR:
return @w_error
go