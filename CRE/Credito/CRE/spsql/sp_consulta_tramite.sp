/************************************************************************/
/*  Archivo:                sp_consulta_tramite.sp                      */
/*  Stored procedure:       sp_consulta_tramite                         */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Dayana Daza                                 */
/*  Fecha de Documentacion: 10-Ene-2012                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  10-Ene-2012       DDAZA            Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_consulta_tramite')
    drop proc sp_consulta_tramite
go

CREATE PROCEDURE sp_consulta_tramite(

	@s_ssn			int = NULL,
	@s_user			login = NULL,
	@s_sesn			int = NULL,
	@s_term			descripcion = NULL, --MTA
	@s_date			datetime = NULL,
	@s_srv			varchar(30) = NULL,
	@s_lsrv			varchar(30) = NULL, 
	@s_rol			smallint  = NULL,
	@s_ofi			smallint = NULL,
	@s_org_err		char(1) = NULL,
	@s_error		int = NULL,
	@s_sev			tinyint = NULL,
	@s_msg			descripcion = NULL,
	@s_org			char(1) = NULL,
	@s_culture		    varchar(10) = null,
	@t_debug		char(1) = 'N',
	@t_file			varchar(14) = null,
	@t_from			varchar(32) = null,
	@t_trn			int =NULL,	
	@i_modo      		tinyint = null,
	@i_tipo      		varchar(1) = null,
	@i_id_inst_proc         int=null, 
	@i_operacion		char(1) = null

)

as

declare @w_sp_name  varchar(32)

select @w_sp_name = 'sp_consulta_tramite'


if @t_debug = 'S'

begin

	exec cobis..sp_begin_debug @t_file = @t_file

	 
select '/** Stored Procedure **/ '  = @w_sp_name,

                s_ssn              = @s_ssn,
                s_user             = @s_user,
                s_term             = @s_term,
                s_date             = @s_date,
                s_srv              = @s_srv,
                s_lsrv             = @s_lsrv,
                s_ofi              = @s_ofi,
		s_rol		   = @s_rol,
		s_org_err	   = @s_org_err,
		s_error		   = @s_error,
		s_sev		   = @s_sev,
		s_msg		   = @s_msg,
		s_org 	           = @s_org,
	 	t_trn		   = @t_trn,
		t_file             = @t_file,
		t_from             = @t_from,
		i_modo             = @i_modo,
		i_tipo             = @i_tipo

		        

	exec cobis..sp_end_debug

end

if @i_operacion='S'--Consulta

BEGIN 

if @i_tipo='1' --Busca el numero de tramite

	begin

		select 'tramite' = io_campo_3,
               'campo_siete' = io_campo_7,
			   'campo_cinco' = io_campo_5
		from cob_workflow..wf_inst_proceso
		where io_id_inst_proc = @i_id_inst_proc

		if @@rowcount = 0
		begin
			  exec cobis..sp_cerror
				@t_debug    = @t_debug,
				@t_file     =  @t_file,
				@t_from     = @w_sp_name,
				@i_num      = 101001
				  /*'No existe dato solicitado'*/
			  return 1
		end

	end

		

END --fin operacion = S

return 0

GO
