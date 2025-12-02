USE master;
GO
IF OBJECT_ID ( 'borra_replica', 'P' ) IS NOT NULL 
    DROP PROCEDURE borra_replica;
GO

/*********************************************************************/
/*    Archivo:                     borra_replica.sql                 */
/*    Stored procedure:            borra_replica                     */
/*    Base de Datos:               master                            */
/*    Producto:                                                      */
/*    Disenado por:                Juan C. Moreno                    */
/*    Fecha de Documentacion:      02/May/200                        */
/*********************************************************************/
/*                   IMPORTANTE                                      */
/*    Este programa es parte de los paquetes bancarios propiedad de  */
/*    "MACOSA",representantes exclusivos para el Ecuador de la       */
/*    AT&T                                                           */
/*    Su uso no autorizado queda expresamente prohibido asi como     */
/*    cualquier autorizacion o agregado hecho por alguno de sus      */
/*    usuario sin el debido consentimiento por escrito de la         */
/*    Presidencia Ejecutiva de MACOSA o su representante             */
/*********************************************************************/
/*                  PROPOSITO                                        */
/*    Este stored procedure permite Borrar replica cob_cartera       */
/*    desde el central a los branch de la tabla ca_valor_atx         */
/*                                                                   */
/*********************************************************************/
/*                  MODIFICACIONES                                   */
/* FECHA                AUTOR                        RAZON           */
/*                                                                   */
/*********************************************************************/

create procedure borra_replica 
as

-------------------------------------------
-- Dropping the transactional subscriptions
-------------------------------------------

SET NOCOUNT ON

DECLARE @Nombre varchar(70)

IF (SELECT COUNT(*) FROM master..Subscriber) = 0

begin

	truncate table master..Subscriber

	insert into master..Subscriber select subscriber from distribution.dbo.MSsubscriber_info

	if exists (SELECT * FROM distribution.dbo.MSpublications WHERE publication = 'cob_cartera')

	begin

		DECLARE replica_stop CURSOR FOR 
		select * from master..Subscriber

		OPEN replica_stop

		FETCH NEXT FROM replica_stop 
		INTO @Nombre

		WHILE @@FETCH_STATUS = 0
		BEGIN
	
		exec [cob_cartera]..sp_dropsubscription @publication = N'cob_cartera', @subscriber = @Nombre, 
		@destination_db = N'cobis', @article = N'all'

		FETCH NEXT FROM replica_stop 
		INTO @Nombre
		END 
		CLOSE replica_stop
		DEALLOCATE replica_stop

		-- Dropping the transactional articles
		exec cob_cartera..sp_dropsubscription @publication = N'cob_cartera', @article = N'ca_valor_atx', @subscriber = N'all', 
		@destination_db = N'all'

		exec cob_cartera..sp_droparticle @publication = N'cob_cartera', @article = N'ca_valor_atx', @force_invalidate_snapshot = 1
	end
end
-------------------------------------------------------------------------------------------------------------------------
