/************************************************************************/
/*	Archivo:		diasanio.sp				*/
/*	Stored procedure:	sp_dias_anio                            */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		R Garces 		                */
/*	Fecha de escritura:	Jul. 1997 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA"							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*    Determina el numero de dias a aplicar para el interes:360,365,366 */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dias_anio')
	drop proc sp_dias_anio
go
create proc sp_dias_anio

        @i_fecha                        datetime ,
        @i_dias_anio                    smallint,
	@o_dias_anio                    smallint out
as
declare
	@w_sp_name			descripcion,
	@w_error			int

select @w_sp_name = 'sp_dias_anio'

if  @i_dias_anio = 360 or @i_dias_anio = 365 begin
   select @o_dias_anio = @i_dias_anio
   return 0
end

if  ((datepart (yy,@i_fecha) % 4) = 0 or (datepart(yy,@i_fecha) % 400) = 0)
and (datepart (yy,@i_fecha) % 100) != 0
/* ANIO BISIESTO */
   select @o_dias_anio = 366
else
   select @o_dias_anio = 365

return 0
ERROR:

return @w_error

go

