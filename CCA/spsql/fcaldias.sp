/************************************************************************/
/*      Archivo:                fcaldias.sp                             */
/*      Stored procedure:       sp_dias_calculo                         */
/*      Base de datos:          cobis                                   */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez Burbano                   */
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
/*      Funcion que retorna numero de dias de calculo de un interes     */
/*      enviado como parametro						*/
/*                                                                      */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA      AUTOR              RAZON                             */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists ( select name from sysobjects where type = 'P' and
		name = 'sp_dias_calculo')
	drop proc sp_dias_calculo
go
create proc sp_dias_calculo 	@tasa            float,
				@monto           money,
				@interes         money,
				@dias_anio       smallint      = 360,
				@dias            float   = null  output
as 

       select @dias = @interes / ((@tasa * @monto) / (100 * @dias_anio))

       select @dias = round(@dias,0)

       ---PRINT '(fcaldias.sp) dias %1!',@dias

       
 return 0
go
