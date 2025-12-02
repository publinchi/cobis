/************************************************************************/
/*	Archivo: 		datosdiames.sp 			        */
/*	Stored procedure: 	sp_datos_maestro_dia_mes                */
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Xavier Maldonado  			*/
/*	Fecha de escritura: 	Junio 26-2003	         		*/
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
/*	Carga en la tabla ca_maestro_operaciones la informacion del dia */
/*      actual y los datos del ultimo fin de mes datos.                  */
/*				                                        */
/*				                                        */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'ca_fecha')
      drop table ca_fecha
go

create table ca_fecha(
fe_fecha  varchar(10)
)
go






if exists (select 1 from sysobjects where name = 'sp_datos_maestro_dia_mes')
   drop proc sp_datos_maestro_dia_mes
go

create proc sp_datos_maestro_dia_mes(
   @i_fecha_proceso     datetime    = null
   
)
as
declare @w_sp_name			varchar(32),
        @w_return			int,
        @w_fecha_hoy                    varchar(10),
        @w_fecha_fin_mes                varchar(10)

 

/*Captura nombre de Stored Procedure  */


select	@w_sp_name = 'sp_datos_maestro_dia_mes'

delete ca_fecha WHERE fe_fecha IS NOT NULL


/*SELECCION DE LA ULTIMA FECHA DE LA TABLA MAESTRO OPERACIONES*/
/**************************************************************/

select @w_fecha_hoy = max(mo_fecha_de_proceso)
from cob_cartera..ca_maestro_operaciones



/*SELECCION DE LA ULTIMA FECHA FIN DE MES (CIERRE DE CREDITO) */
/**************************************************************/

set rowcount 1

select @w_fecha_fin_mes = convert(varchar(10),co_fecha,101) 
from cob_credito..cr_calificacion_op
where co_producto = 7

set rowcount 0


/*INSERCION DE FECHAS A PROCESAR */
/*********************************/
insert into ca_fecha (fe_fecha) values (@w_fecha_hoy)
insert into ca_fecha (fe_fecha) values (@w_fecha_fin_mes)



INSERT INTO cob_cartera..ca_maestro_operaciones_tmp 
SELECT * 
FROM cob_cartera..ca_maestro_operaciones
WHERE mo_fecha_de_proceso in (select fe_fecha from cob_cartera..ca_fecha)



/* BORRA LA TABLA MAESTRO OPERACIONES */
/**************************************/
truncate table cob_cartera..ca_maestro_operaciones



return 0

go


