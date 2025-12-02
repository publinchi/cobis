/************************************************************************/
/*      Archivo:                fcalcint.sp                             */
/*      Stored procedure:       sp_calc_intereses                       */
/*      Base de datos:          cobis                                   */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Juan Jose Lam                           */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Funcion que realiza el calculo de los intereses                 */
/*                                                                      */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA      AUTOR              RAZON                             */
/*      20-Feb-95  Juan Lam           Creacion                          */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists ( select name from sysobjects where type = 'P' and name = 'sp_calc_intereses')
	drop proc sp_calc_intereses
go

create proc sp_calc_intereses 
@tasa            float,
@monto           float,
@dias_anio       float   = 360, ---(360 para INT) (365 para IMO)
@num_dias        float   = 1,
@causacion       char(1) = 'L',     
@causacion_acum  float   = 0,
@intereses       float   = null  output 
as 
declare 
@w_tasa_dia	 float,
@w_return        int



/*PRINT '(fcalcint.sp ) @tasa %1!,
                      @monto %2!,
                      @causacion %3!,
                      @causacion_acum %4!,
                      @num_dias %5!',@tasa,@monto,@causacion,@causacion_acum,@num_dias */



if @causacion = 'L'
   select @intereses = (@tasa * @monto) / (100 * @dias_anio) * @num_dias
else  
begin
   select @w_tasa_dia =(exp((1.0/@dias_anio)* log(1+((@tasa/100.0)/(@dias_anio/@dias_anio))))-1)

   select @w_tasa_dia = round(100.0*@w_tasa_dia ,6)

   select @intereses  = (@monto + @causacion_acum) * (@w_tasa_dia/ 100) 
end


return 0
go













