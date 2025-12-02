/************************************************************************/
/*	Archivo: 		cal_div.sp				*/
/*	Stored procedure: 	sp_calcula_dividendo			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Zoila Bedon				*/
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
/*	Este programas calcula los dividendos.				*/
/************************************************************************/  
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	17-04-1996	Zoila Bedon	Emision inicial			*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calcula_dividendo')
	drop proc sp_calcula_dividendo
go
create proc sp_calcula_dividendo  (
               @s_user         login 	= null, 
               @s_term         login 	= null,
               @s_date         datetime = null,
               @s_ofi          smallint = null,
               @i_operacion    char(1)
)
as
declare		@w_sp_name	varchar(30),
                @w_dividendo    catalogo,
                @w_factor       smallint               

/*  Captura nombre del Stored Procedure  */
select @w_sp_name = 'sp_calcula_dividendo'


if @i_operacion ='Q' Begin
   select  td_tdividendo,
           td_factor
   from ca_tdividendo
   where td_estado = 'V'
   order by td_tdividendo
end                               
return 0
go

