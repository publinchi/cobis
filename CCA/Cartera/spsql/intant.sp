/************************************************************************/
/*	Archivo: 		intant.sp   		 		*/
/*	Stored procedure: 	sp_interes_anticipado   		*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Fabian de la Torre, Rodrigo Garces     	*/
/*	Fecha de escritura: 	Ene 98					*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Desfasar un dividendo a los rubros tipo interes periodico       */
/*      anticipado                                                      */
/************************************************************************/  
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_interes_anticipado')
   drop proc sp_interes_anticipado
go

create proc sp_interes_anticipado (
@i_operacionca                  int = null
)
as
declare	
@w_sp_name                 	descripcion,
@w_return 			int

/*  Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_interes_anticipado'

/* DESFASE DE UN DIVIDENDO PARA LOS RUBROS TIPO INTERES ANTICIPADO */

update ca_amortizacion_tmp
set    amt_dividendo   = amt_dividendo - 1
from   ca_rubro_op_tmp
where  amt_operacion   = @i_operacionca
and    rot_operacion   = @i_operacionca
and    rot_fpago       = 'A'
and    rot_tipo_rubro  = 'I'
and    rot_concepto    = amt_concepto

if @@error != 0
   return 710002

update ca_amortizacion_tmp set
amt_pagado             = amt_cuota
where  amt_operacion   = @i_operacionca
and    amt_dividendo   = 0

if @@error != 0
   return 710002

return 0

go     

