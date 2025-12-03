/*************************************************************************/
/*   Archivo:              info_actividad.sp                             */
/*   Stored procedure:     sp_info_actividad                             */
/*   Base de datos:        cob_credito                                   */
/*   Producto:             Credito                                       */
/*   Disenado por:         Jose Mieles      							 */
/*   Fecha de escritura:   17/Nov/2021                                   */
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
/*  Traer nombre de actividades de la tabla cob_workflow..wf_actividad   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                   RAZON                	 */
/*    17/Nov/2021    	  Jose Mieles             Emision Inicial        */
/*                                                                       */
/*************************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_info_actividad')
			drop proc sp_info_actividad
go

CREATE PROCEDURE sp_info_actividad
@s_user                    	login        	= null,
	@s_term                    	varchar(30)  	= null,
	@s_date                   	datetime     	= null,
	@s_ofi                     	smallint		= null,    
	@s_rol                     	smallint     	= null,
	@t_show_version         	bit             = 0,    -- Mostrar la version del programa
	@t_debug                	char(1)         = 'N',
	@t_file                 	varchar(10)     = null,
	@t_from                 	varchar(32)     = null,
	@t_trn                  	int        		= null
		
as
declare
   	@w_sp_name                 	descripcion,
   	@w_error					int

	select   	@w_sp_name = 'sp_wf_actividad'
	
	
	select ac_codigo_actividad, ac_nombre_actividad from cob_workflow..wf_actividad where ac_estado = 'ACT' 
	
   
return 0

ERROR:
    begin --Devolver mensaje de Error
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = @w_error

        return @w_error
    end


return @w_error
 
GO
