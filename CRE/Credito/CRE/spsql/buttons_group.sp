/*************************************************************************/
/*   Archivo:              buttons_group.sp                              */
/*   Stored procedure:     sp_buttons_group                              */
/*   Base de datos:        cob_credito                                   */
/*   Producto:             Credito                                       */
/*   Disenado por:         Jose Mieles      							 */
/*   Fecha de escritura:   16/Nov/2021                                   */
/*************************************************************************/
/*                          IMPORTANTE                                   */
/*    Este programa es parte de los paquetes bancarios propiedad de      */
/*    COBISCORP.                                                         */
/*    Su uso no autorizado queda expresamente prohibido asi como         */
/*    cualquier autorizacion o agregado hecho por alguno de sus          */
/*    usuario sin el debido consentimiento por escrito de la             */
/*    Presidencia Ejecutiva de COBISCORP o su representante.             */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Crea operacion hija de una operacion padre en grupales             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                   RAZON                	 */
/*    16/Nov/2021    	  Jose Mieles             Emision Inicial        */
/*                                                                       */
/*************************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_buttons_group')
			drop proc sp_buttons_group
go

CREATE PROCEDURE sp_buttons_group
	@s_ssn                   int         = null,
	   @s_user                  login       = null,
	   @s_sesn                  int         = null,
	   @s_term                  descripcion = null,
	   @s_date                  datetime    = null,
	   @s_srv                   varchar(30) = null,
	   @s_lsrv                  varchar(30) = null,
	   @s_rol                   smallint    = null,
	   @s_ofi                   smallint    = null,
	   @s_org_err               char(1)     = null,
	   @s_error                 int         = null,
	   @s_sev                   tinyint     = null,
	   @s_msg                   descripcion = null,
	   @s_org                   char(1)     = null,
	   @s_culture               varchar(10) = null,
	   @t_rty                   char(1)     = null,
	   @t_trn                   smallint    = null,
	   @t_debug                 char(1)     = 'N',
	   @t_file                  varchar(14) = null,
	   @t_from                  varchar(30) = null,
	   @i_operacion             char(1),
	   @i_funcionalidad         varchar(90) = null,
	   @i_actividad             varchar(90) = null,
	   @i_uso                   char(1)     = null,
	   @i_id					int 		= null,
	   @o_id					int 		= null out
AS 
declare	
	@w_sp_name 			varchar(32),
		@w_mensaje 			varchar(80),
		@w_id 				int,
		@w_funcionalidad	varchar(90),
		@w_actividad		varchar(90),
		@w_error       	int
	
	SELECT @w_sp_name = 'sp_buttons_group'
	
	
	if @i_operacion = 'I'
	begin
    	
		if (@i_funcionalidad is null) OR (@i_actividad is null) or (@i_uso is null)
		BEGIN
			select @w_error =  2110229
      		goto ERROR
		END
				
		select @w_actividad = ac_nombre_actividad from cob_workflow..wf_actividad where ac_codigo_actividad = @i_actividad
		
		if not EXISTS(select (1) from cob_workflow..wf_boton_actividad where ba_boton = @i_funcionalidad and ba_actividad = @w_actividad)
		BEGIN
		
			select @w_id = max(ba_id)
			from cob_workflow..wf_boton_actividad

			select @w_id = isnull(@w_id,0) + 1
			
			insert into cob_workflow..wf_boton_actividad 
				(ba_id, ba_boton, ba_actividad,	ba_uso)
			values
				(@w_id, @i_funcionalidad, @w_actividad, @i_uso)
		end
		ELSE
		BEGIN
		  select @w_error =  2110227 --error que no deben existir dos iguales
		  goto ERROR
		
		end
			
	end


	if @i_operacion = 'S'
	begin
		select
			ba_id,
			ba_boton,
			(select ac_codigo_actividad from cob_workflow..wf_actividad where ac_nombre_actividad  = ba_actividad),
			ba_uso
		from cob_workflow..wf_boton_actividad
	end

	if @i_operacion = 'U'
	begin
		
		if (@i_funcionalidad is null) OR (@i_actividad is null) or (@i_uso is null)
			BEGIN
				select @w_error =  2110229
				goto ERROR
			END
		
		if exists(select 1 from cob_workflow..wf_boton_actividad where ba_id = @i_id)
		BEGIN 
			
			select @w_actividad = ac_nombre_actividad from cob_workflow..wf_actividad where ac_codigo_actividad = @i_actividad
			
			if not EXISTS(select (1) from cob_workflow..wf_boton_actividad where ba_boton = @i_funcionalidad and ba_actividad = @w_actividad and ba_id <> @i_id)
			BEGIN
				update cob_workflow..wf_boton_actividad set
				ba_boton = @i_funcionalidad,		ba_actividad = @w_actividad,		ba_uso = @i_uso
				where ba_id = @i_id
			end
			ELSE
			BEGIN
		
			  select @w_error =  2110227 --error que no deben existir dos iguales
			  goto ERROR
			
			end
			
		END
		else
		begin
			 select @w_error =  2110228 --error que no deben existir dos iguales
			  goto ERROR
			
		end
		
	end

	if @i_operacion = 'D'
	begin
		if EXISTS(select (1) from cob_workflow..wf_boton_actividad where  ba_id = @i_id)
		BEGIN
			delete cob_workflow..wf_boton_actividad 
			where ba_id = @i_id
		END
		ELSE
		BEGIN

		  select @w_error =  2110228 --error que debe exixtir
		  goto ERROR
		
		end
	end

return 0

ERROR:
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error

    return @w_error
	
GO
