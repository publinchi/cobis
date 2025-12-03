/************************************************************************/
/*  Archivo:                int_documents_client.sp                     */
/*  Stored procedure:       sp_int_documents_client                     */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Mieles                                 */
/*  Fecha de Documentacion: 19/10/2021                                  */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_interface               */ 
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  19/10/2021       jmieles        Emision Inicial                     */
/* **********************************************************************/

use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_int_documents_client')
   drop procedure sp_int_documents_client
go

CREATE PROCEDURE sp_int_documents_client
			@s_ssn                     int              = null,
            @s_user                    login            = null,
            @s_sesn                    int              = null,
            @s_term                    descripcion      = null,         
            @s_date                    datetime         = null,
            @s_srv                     varchar(30)      = null,
            @s_lsrv                    varchar(30)      = null,
            @s_rol                     smallint         = null,
            @s_ofi                     smallint         = null,
            @s_org_err                 char(1)          = null,
            @s_error                   int              = null,
            @s_sev                     tinyint          = null,
            @s_msg                     descripcion      = null,
            @s_org                     char(1)          = null,
            @t_rty                     char(1)          = null,
            @t_trn                     int              = null,
            @t_debug                   char(1)          = 'N',
            @t_file                    varchar(14)      = null,
            @t_from                    varchar(30)      = null,
            @t_show_version            bit              = 0,          
            @s_culture                 varchar(10)      = 'NEUTRAL',
			@i_operacion          	   char(1)  		= null,
			@i_id_inst_proc 		   int 			    = null,
			@i_tipo_operacion          varchar(255)  	= null,
			@i_id_cliente			   int 			    = 0,
			@i_id_grupo  			   int 			    = null,
			@o_ruta_documento          varchar(255)  	= null out
AS 
	declare
	@w_error            int,
	@w_sp_name1			varchar(255),
	@w_ruta_documento 	varchar (255)
			
select @w_sp_name1 = 'sp_int_management_documents_client'
	
if @i_operacion <> 'R' --and @i_operacion <> 'U'
	begin
		select
			@w_error = 2110173
	 
	        goto ERROR
	end


if @i_operacion = 'R'
begin

	if @i_tipo_operacion  = 'IBICP'
	begin 
		if @i_id_cliente <> 0
		begin
			if not exists (select 1 from cobis..cl_ente where en_ente = @i_id_cliente)
			begin
				select
				@w_error = 2110190
		 
				goto ERROR
			end
			select @w_ruta_documento = 'ProcessInstance/'+ convert(varchar(100),@i_id_inst_proc) + '/' + convert(varchar(100),@i_id_cliente)
		end
		else 
		begin 
			select @w_ruta_documento = 'ProcessInstance/'+ convert(varchar(100),@i_id_inst_proc)
		end
	end
	
	if @i_tipo_operacion  = 'BYCUS'
	begin 
		if @i_id_cliente <> 0
		begin
			if not exists (select 1 from cobis..cl_ente where en_ente = @i_id_cliente)
			begin
				select
				@w_error = 2110190
		 
				goto ERROR
			end
			select @w_ruta_documento = 'Customer/'+ convert(varchar(100),@i_id_cliente)
		end
		else 
		begin 
			select
				@w_error = 2110225
		 
				goto ERROR
		end
	end
	
	if @i_tipo_operacion  = 'GBIC'
	begin 
		if @i_id_grupo <> 0
		begin
			if not exists (select 1 from cobis..cl_grupo where gr_grupo = @i_id_grupo)
			begin
				select
				@w_error = 2110130
		 
				goto ERROR
			end
			if @i_id_inst_proc <> 0
			begin
				select @w_ruta_documento = 'Group/'+ convert(varchar(100),@i_id_grupo) + '/' + convert(varchar(100),@i_id_inst_proc)
			end
			else 
			begin 
				select @w_ruta_documento = 'Group/'+ convert(varchar(100),@i_id_grupo)
			end
			
		end
		else 
		begin 
			select
				@w_error = 2110226
		 
				goto ERROR
		end
	end
	
	
end
select @o_ruta_documento = @w_ruta_documento

SELECT 'w_ruta_documento' = @w_ruta_documento
	
return 0

ERROR:
   --Devolver mensaje de Error

      exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name1,
         @i_num   = @w_error
      return @w_error

GO