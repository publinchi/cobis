USE master;
GO
IF OBJECT_ID ( 'inicia_replica', 'P' ) IS NOT NULL 
    DROP PROCEDURE inicia_replica;
GO

/*********************************************************************/
/*    Archivo:                     inicia_replica.sql                */
/*    Stored procedure:            inicia_replica                    */
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
/*    Este stored procedure permite Iniciar replica cob_cartera      */
/*    desde el central a los branch de la tabla ca_valor_atx         */
/*                                                                   */
/*********************************************************************/
/*                  MODIFICACIONES                                   */
/* FECHA                AUTOR                        RAZON           */
/*                                                                   */
/*********************************************************************/

create procedure inicia_replica 
as
------------------------------------
-- Enabling the replication database
------------------------------------
SET NOCOUNT ON

DECLARE @Nombre varchar(70)

IF (SELECT COUNT(*) FROM master..Subscriber) > 0
BEGIN
	---- Adding the transactional articles

	exec cob_cartera..sp_addarticle @publication = N'cob_cartera', @article = N'ca_valor_atx', @source_owner = N'dbo', 
	@source_object = N'ca_valor_atx', @type = N'logbased', @description = N'', @creation_script = N'', 
	@pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', 
	@destination_table = N'ca_valor_atx', @destination_owner = N'dbo', @status = 24, 
	@vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_dboca_valor_atx]', 
	@del_cmd = N'CALL [sp_MSdel_dboca_valor_atx]', @upd_cmd = N'SCALL [sp_MSupd_dboca_valor_atx]'

	-- Adding the transactional subscriptions
	DECLARE replica_start CURSOR FOR 
	select * from master..Subscriber

	OPEN replica_start
	
	FETCH NEXT FROM replica_start 
	INTO @Nombre

	WHILE @@FETCH_STATUS = 0
	BEGIN

	exec cob_cartera..sp_addsubscription @publication = N'cob_cartera', @subscriber = @Nombre, 
	@destination_db = N'cobis', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', 
	@update_mode = N'read only', @subscriber_type = 0

	exec cob_cartera..sp_addpushsubscription_agent @publication = N'cob_cartera', @subscriber = @Nombre, 
	@subscriber_db = N'cobis', @job_login = null, @job_password = null, @subscriber_security_mode = 0, 
	@subscriber_login = N'usrcobisbrn', @subscriber_password = 'usrcobisbrn', @frequency_type = 64, 
	@frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, 
	@frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, 
	@active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, 
	@dts_package_location = N'Distributor'

	FETCH NEXT FROM replica_start 
	INTO @Nombre
	END 	
	CLOSE replica_start
	DEALLOCATE replica_start

	select @Nombre = name from distribution.dbo.MSsnapshot_agents where name like '%cob_cartera%' -- ver nombre de job para snapshot

	exec  msdb..sp_start_job @Nombre
	
	truncate table master..Subscriber
END
