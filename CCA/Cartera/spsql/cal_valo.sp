/************************************************************************/
/*	Archivo: 		cal_valo.sp				*/
/*	Stored procedure: 	sp_calcula_valor			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Fabian Espinosa				*/
/*	Fecha de escritura: 	19-06-1995				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Este programa realiza un calculo de la tasa de interes          */
/*      en base al margen definido para la operacion                   	*/
/************************************************************************/  
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	19-06-1995	Fabian Espinosa	Emision inicial			*/
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_calcula_valor')
	drop proc sp_calcula_valor
go
create proc sp_calcula_valor ( 
@i_base			float,
@i_factor		float,
@i_signo		char(1) ,
@o_resultado		float out
) 
as
declare
@w_sp_name		varchar(30),
@w_return               int

/*  Captura nombre del Stored Procedure  */
select @w_sp_name = 'sp_calcula_valor'

  if @i_signo = '+' select @o_resultado = @i_base + @i_factor
  if @i_signo = '-' select @o_resultado = @i_base - @i_factor
  if @i_signo = '*' select @o_resultado = @i_base * @i_factor
  if @i_signo = '/' begin
     if @i_factor = 0
        return 701143
        select @o_resultado = @i_base / @i_factor
  end

return 0
go
