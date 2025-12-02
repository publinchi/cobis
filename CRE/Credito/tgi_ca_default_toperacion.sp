/*************************************************************************/
/*   Archivo:              tgi_ca_default_toperacion.sp                  */
/*   Trigger:              tgi_ca_default_toperacion                     */
/*   Base de datos:        cob_cartera                                   */
/*   Producto:             Credito                                       */
/*   Disenado por:         Carlos Veintemilla							 */
/*   Fecha de escritura:   16/Jun/2021                                   */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las convenciones internacionales de propiedad inte-        */
/*   lectual. Su uso no autorizado dara derecho a MACOSA para        */
/*   obtener ordenes de secuestro o retencion y para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Para borrar las tablas temporales despues de reversar un tramite   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                   RAZON                	 */
/*    16/Jun/2021    	  Carlos Veintemilla      Emision Inicial        */
/*                                                                       */
/*************************************************************************/
use cob_cartera
go

IF EXISTS (SELECT OBJECT_ID FROM sys.triggers WHERE name = 'tgi_ca_default_toperacion ' and type = 'TR')
	DROP TRIGGER dbo.tgi_ca_default_toperacion
GO

CREATE TRIGGER tgi_ca_default_toperacion on ca_default_toperacion after insert,update
as
begin
	declare 
		@w_toperacion 	varchar(100),
		@w_moneda		tinyint,
		@w_total		int,
		@w_parcial		int
		
	select @w_toperacion = dt_toperacion , @w_moneda = dt_moneda
	from Inserted 
	
	if exists(select dt_toperacion from inserted) and not exists(select dt_toperacion from deleted)
	begin
		if not exists(select to_toperacion from cob_credito..cr_toperacion where to_toperacion = @w_toperacion)
		begin
			insert into cob_credito..cr_toperacion values (@w_toperacion,'CCA',@w_toperacion,'V',NULL,NULL)
		end
	end
	else
	begin
		select @w_total = count(*)
		from ca_default_toperacion
		where dt_toperacion = @w_toperacion
		
		select @w_parcial = count(*)
		from ca_default_toperacion
		where dt_toperacion = @w_toperacion
		and dt_estado = 'N'
		
		if(@w_total=@w_parcial)
		begin
			update cob_credito..cr_toperacion
			set to_estado = 'N'
			where to_toperacion = @w_toperacion
		end
	end   
end
go
