/************************************************************************/
/*      Archivo:                borranom.sp                             */
/*      Stored procedure:       sp_borrar_nomina                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Angela Ramirez				*/ 
/*      Fecha de escritura:     Jun  1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Eliminar las tablas temporales de cuotas adicionales, nomina y  */
/*      definicion nomina, cuando se han modificado en la tabla de      */
/*      amortizacion Tipo de Plazo, el Tipo de Cuota, el Plazo y        */
/*      los Periodos de Capital.                                        */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      19/jun/98      A. Ramirez         Emision Inicial               */
/*                                        PERSONALIZACION B.ESTADO      */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_borrar_nomina')
	drop proc sp_borrar_nomina
go
create proc sp_borrar_nomina
	@i_operacionca		int  = null
as
declare @w_error		int ,
	@w_sp_name		descripcion

/*  NOMBRE DEL SP  */
select  @w_sp_name = 'sp_borrar_nomina'
                                             
/*UPDATE A LA TABLA CA_CUOTA_ADICIONAL*/
update ca_cuota_adicional_tmp
set cat_cuota = 0
where cat_operacion = @i_operacionca

if @@error <> 0 begin
   select @w_error = 710100
   goto ERROR
end 

/*DELETE EN LA TABLA CA_DISTRIBUCION_NOMINA*/
delete ca_definicion_nomina_tmp
where dnt_operacion = @i_operacionca    

if @@error <> 0begin
   select @w_error = 710101
   goto ERROR
end 

/*DELETE EN LA TABLA CA_NOMINA*/
delete ca_nomina_tmp
where not_operacion = @i_operacionca    

if @@error <> 0begin
   select @w_error = 710101
   goto ERROR
end 

return 0

ERROR:

return @w_error

go

