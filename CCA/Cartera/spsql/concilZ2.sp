/************************************************************************/
/*	Archivo:		concilZ2.sp				*/
/*	Stored procedure:	sp_conciliacion_dia_Z2		        */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Elcira Pelaez				*/
/*	Fecha de escritura:	Feb.2003 				*/
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
/*	Genera vencimientos que son COBRADOS AL BANCO y que	        */
/*      COBIS no cargo  como vencimiento de la fecha  		        */
/*	Actualiza la tabla	ca_plano_banco_segundo_piso en campo 	*/
/*      bs_z2 = 'S'                                                     */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*			  		  				*/   
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_conciliacion_dia_Z2')
   drop proc sp_conciliacion_dia_Z2
go

create proc sp_conciliacion_dia_Z2
@i_fecha_proceso     	datetime
as

declare 
@w_error		int,
@w_return         	int,
@w_sp_name        	descripcion,
@w_bs_oper_llave_redes	varchar(24),
@w_bs_sucursal          varchar(3),
@w_centuria             char(1),
@w_llave_segundo_p	cuenta,
@w_bs_identificacion    cuenta,
@w_bs_identificacion_aux float,
@w_cd_identificacion     float,
@w_banco                 cuenta,
@w_bs_fecha_redescuento  datetime,
@w_bs_norma_legal	 varchar(4),
@w_llave_total           char(18)


/** CARGADO DE VARIABLES DE TRABAJO **/
select 
@w_sp_name          = 'sp_conciliacion_dia_Z2'


/* CURSO PARA LEER LOS VENCIMIENTOS DEL BAC*/


/* CURSO PARA LEER LOS VENCIMIENTOS DEL BAC*/

if exists(select 1 from cob_cartera..ca_plano_banco_segundo_piso
          where  convert(datetime,substring(bs_fecha_pago,3,2) + '/' + substring(bs_fecha_pago,1,2) + '/' + substring(bs_fecha_pago,5,4),101) =  @i_fecha_proceso)
begin

   select (ltrim(rtrim(bs_sucursal))) + (ltrim(rtrim(bs_linea_norlegal))) + (ltrim(rtrim(bs_oper_llave_redes))) as llave, bs_oper_llave_redes into #llave_finagro
   from cob_cartera..ca_plano_banco_segundo_piso
   where  convert(datetime,substring(bs_fecha_pago,3,2) + '/' + substring(bs_fecha_pago,1,2) + '/' + substring(bs_fecha_pago,5,4),101) 	=  @i_fecha_proceso


   select  bs_oper_llave_redes as llave_redes into #llave_no_cobis 
   from #llave_finagro 
   where llave  not in (select cd_llave_redescuento from ca_conciliacion_diaria
                        where cd_fecha_proceso = @i_fecha_proceso)

   update ca_plano_banco_segundo_piso  
   set bs_z2 = 'S'
   from #llave_no_cobis 
   where bs_oper_llave_redes = llave_redes
   ---and   cd_fecha_proceso    =  @i_fecha_proceso

end


PRINT 'concilZ2.sp FIN  LEER VENCIMIENTOS DE FINAGRO'

return 0

go


