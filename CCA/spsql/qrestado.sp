/************************************************************************/
/*	Archivo: 		qrestado.sp    				*/
/*	Stored procedure: 	sp_consulta_estado			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Catalina Espinel			*/
/*				Yomar Pazmino				*/
/*	Fecha de escritura: 	Abril 1996				*/
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
/*	Este programa consulta los tipos de estados			*/
/*									*/
/************************************************************************/  
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*      05/02/96       Z.Bedon          Emision Inicial                 */  
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_estado')
    drop proc sp_consulta_estado
go
create proc sp_consulta_estado 

as

declare
@w_return             int,          /* valor que retorna */
@w_sp_name            varchar(32)  /* nombre stored proc*/

select  @w_sp_name = 'sp_consulta_estado'

/* Consulta de tipos de estados */
select
'DESCRIPCION'       = substring(es_descripcion,1,35),
'PROCESA'           = es_procesa,
'ACEPTA PAGO'       = es_acepta_pago,
'CODIGO DEL ESTADO' = es_codigo
from ca_estado
order by es_codigo
return 0

go
