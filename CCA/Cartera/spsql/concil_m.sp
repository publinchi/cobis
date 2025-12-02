/************************************************************************/
/*	Archivo:		concil_w.sp				*/
/*	Stored procedure:	sp_conciliacion_dia_m		        */
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
/*	Genera diferencias entre los vencimientos enviados por banco de */
/*      de segundo piso y vencimientos de COBIS                         */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*			  		  				*/   
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_conciliacion_dia_m')
   drop proc sp_conciliacion_dia_m
go

create proc sp_conciliacion_dia_m
@i_fecha_proceso     	datetime
as

declare 
	@w_error		int,
	@w_return         	int,
	@w_sp_name        	descripcion,
	@w_cd_llave_redescuento	cuenta

--- CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name          = 'sp_conciliacion_dia_m'



--- CURSO PARA GENERAR DIFERENCIAS EN VENCIMIENTOS 

/**********
	declare cursor_concil_m cursor for
	select cd_llave_redescuento
	from cob_cartera..ca_conciliacion_diaria 
	where  cd_fecha_proceso = @i_fecha_proceso
        for read only
         
	open  cursor_concil_m

	fetch cursor_concil_m into 
	@w_cd_llave_redescuento

	while @@fetch_status = 0 
	begin   
	   if @@fetch_status = -1 
	   begin    
       	     PRINT 'concil_m.sp error en lectura del cursor conciliacion diaria'
           end
   
           update ca_conciliacion_diaria           
            set   cd_llave_redescuento = replicate('0',11-datalength(convert(varchar(24),cd_llave_redescuento)))+convert(varchar(11),cd_llave_redescuento)
            where cd_llave_redescuento = @w_cd_llave_redescuento
          

           fetch cursor_concil_m into 
	   @w_cd_llave_redescuento

       end /* cursor_concil_m */

	close cursor_concil_m
	deallocate cursor_concil_m


   
 update ca_conciliacion_diaria           
 set   cd_llave_redescuento = replicate('0',11-datalength(convert(varchar(24),cd_llave_redescuento)))+convert(varchar(11),cd_llave_redescuento)

**********/      


 update ca_plano_banco_segundo_piso
 set bs_tasa_nom            = isnull((bs_tasa_nom / 100),1),
     bs_valor_saldo_antes   = isnull((bs_valor_saldo_antes / 100),1),
     bs_abono_capital       = isnull((bs_abono_capital / 100),1),     
     bs_valor_saldo_despues = isnull((bs_valor_saldo_despues / 100),1),
     bs_valor_int           = isnull((bs_valor_int / 100),1),
     bs_valor_pagar         = isnull((bs_valor_pagar / 100),1)
 WHERE bs_valor_pagar >= 0




return 0

go


