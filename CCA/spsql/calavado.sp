/************************************************************************/
/*   Archivo:             calavado.sp                                   */
/*   Stored procedure:    sp_lavado_activos                             */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Xavier Maldonado                              */
/*   Fecha de escritura:  Enero - 2006                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                             PROPOSITO                                */
/*                                                                      */
/************************************************************************/  
/*                             ACTUALIZACIONES                          */
/*                                                                      */
/*     FECHA              AUTOR            CAMBIO                       */
/*									*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_lavado_activos')
   drop proc sp_lavado_activos
go

create proc sp_lavado_activos
@i_fecha_inicio   		datetime,
@i_fecha_fin   			datetime

as declare
   @w_op_banco		 	cuenta



   insert into ca_lavado_activos_tmp (la_banco,          la_operacion,	la_secuencial_pag,	
	   		 	      la_fecha_pago,     la_oficina_or, la_oficina_ad,     
				      la_monto_mn,       la_cliente,	la_nombre,              
				      la_identificacion, la_forma_pago)
   select * from ca_lavado_activos
   where la_fecha_pago >= convert(varchar(10),@i_fecha_inicio,101)  
   and   la_fecha_pago <= convert(varchar(10),@i_fecha_fin,101)   


return 0
go             



