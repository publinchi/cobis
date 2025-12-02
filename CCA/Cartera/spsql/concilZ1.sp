/************************************************************************/
/*	Archivo:		concilZ1.sp				*/
/*	Stored procedure:	sp_conciliacion_dia_Z1		        */
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
/*	Genera vencimientos que reporta COBIS y no son cobrados         */
/*      por BANCO DE SEGUNDO PISO					*/
/*	Actualiza la tabla	ca_conciliacion_diaria campo 	cd_z1	*/
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*	Mar 2003	M¢nica Mari¤o	   Desarrollo/Modificaciones    */   
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_conciliacion_dia_Z1')
   drop proc sp_conciliacion_dia_Z1
go

create proc sp_conciliacion_dia_Z1
@i_fecha_proceso     	datetime
as

declare 
	@w_error          	 int,
	@w_return         	 int,
	@w_sp_name        	 descripcion,
	@w_cd_llave_redescuento  cuenta,
        @w_bs_oper_llave_redes	 varchar(24),
        @w_bs_sucursal           varchar(3),
        @w_centuria              char(1),
        @w_llave_segundo_p	 char(5),
        @w_existe                char(5),
        @w_bs_identificacion     cuenta,
        @w_cd_identificacion     char(15),
        @w_fecha_desembolso      datetime

        


/** CARGADO DE VARIABLES DE TRABAJO **/
select 
@w_sp_name          = 'sp_conciliacion_dia_Z1'


if exists(select 1 from cob_cartera..ca_plano_banco_segundo_piso
          where  convert(datetime,substring(bs_fecha_pago,3,2) + '/' + substring(bs_fecha_pago,1,2) + '/' + substring(bs_fecha_pago,5,4),101) =  @i_fecha_proceso)
begin
         
   select (ltrim(rtrim(bs_sucursal))) + (ltrim(rtrim(bs_linea_norlegal))) + (ltrim(rtrim(bs_oper_llave_redes))) as llave, bs_oper_llave_redes into #llave_finagro_cd
   from cob_cartera..ca_plano_banco_segundo_piso
   where  convert(datetime,substring(bs_fecha_pago,3,2) + '/' + substring(bs_fecha_pago,1,2) + '/' + substring(bs_fecha_pago,5,4),101) 	=  @i_fecha_proceso

   update ca_conciliacion_diaria
   set cd_z1 = 'S'
   where cd_llave_redescuento not in (select llave from #llave_finagro_cd)

end




return 0

go


