/************************************************************************/
/*  Archivo:                int_ruteo.sp                                */
/*  Stored procedure:       sp_int_ruteo                                */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Mieles                                 */
/*  Fecha de Documentacion: 04/10/2021                                  */
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
/*  04/10/2021       jmieles        Emision Inicial                     */
/* **********************************************************************/ 
 use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_int_ruteo')
   drop procedure sp_int_ruteo
go


create proc sp_int_ruteo

 	  @s_ssn                int         = null,
	  @s_user               varchar(30) = null,
	  @s_sesn               int         = null,
	  @s_term               varchar(30) = null,
	  @s_date               datetime    = null,
	  @s_srv                varchar(30) = null,
	  @s_lsrv               varchar(30) = null,
	  @s_ofi                smallint    = null,
	  @t_trn                int         = null,
	  @t_debug              char(1)     = 'N',
	  @t_file               varchar(14) = null,
	  @t_from               varchar(30) = null,
	  @s_culture            varchar(10) = null,
	  @s_rol                smallint    = null,
	  @s_org_err            char(1)     = null,
	  @s_error              int         = null,
	  @s_sev                tinyint     = null,
	  @s_msg                descripcion = null,
	  @s_org                char(1)     = null,
	  @s_service            int         = null,
	  @t_rty                char(1)     = null,
      @i_operacion          char(1)     = null,
      @i_tramite	        int         = null
	  
AS 
	declare
		@w_error                    int,
		@w_sp_name1        			varchar(100),
		@w_id_inst_proc				int,
		@w_id_inst_act				int,
		@w_id_paso					int,
		@w_id_asig_act				int,
		@w_nombre_actividad	        varchar(255)
		
select @w_nombre_actividad = pa_char
from cobis..cl_parametro
where pa_nemonico = 'NARI'
and pa_producto   = 'CRE'
	
SELECT @w_id_inst_proc = io_id_inst_proc FROM cob_workflow..wf_inst_proceso WHERE io_campo_3 = @i_tramite --tramite

SELECT @w_id_inst_act = ia_id_inst_act, @w_id_paso = ia_id_paso FROM cob_workflow..wf_inst_actividad WHERE ia_id_inst_proc = @w_id_inst_proc and  ia_secuencia = (select max(ia_secuencia) FROM cob_workflow..wf_inst_actividad WHERE ia_id_inst_proc = @w_id_inst_proc) --and ia_estado = 'ACT'

SELECT @w_id_asig_act = aa_id_asig_act FROM cob_workflow..wf_asig_actividad WHERE aa_id_inst_act = @w_id_inst_act

if not exists(select 1 FROM cob_workflow..wf_inst_actividad WHERE ia_id_inst_proc = @w_id_inst_proc and  ia_secuencia = (select max(ia_secuencia) FROM cob_workflow..wf_inst_actividad WHERE ia_id_inst_proc = @w_id_inst_proc) and ia_nombre_act = @w_nombre_actividad )
begin 
	select
    @w_error = 2110224
    goto ERROR
end

insert into cob_interface..in_log_ruteo(lr_inst_proceso,lr_fecha,lr_usuario,lr_ultimo,lr_inst_actividad) 
values(@w_id_inst_proc,getdate(),@s_user,'S',@w_id_inst_act)

select @w_sp_name1 = 'cob_workflow..sp_resp_actividad_wf'
	
	  exec @w_error				   = @w_sp_name1  --cob_workflow..sp_resp_actividad_wf 
			@s_ssn                 = @s_ssn,
			@s_user                = @s_user,
			@s_sesn                = @s_sesn,
			@s_term                = @s_term,
			@s_date                = @s_date,
			@s_srv                 = @s_srv,
			@s_lsrv                = @s_lsrv,
			@s_ofi                 = @s_ofi,
			@t_debug               = @t_debug,
			@t_file                = @t_file,
			@t_from                = @t_from,
			@s_culture             = @s_culture,
			@s_rol                 = @s_rol,
			@s_org_err             = @s_org_err,
			@s_error 			   = @s_error,
			@s_sev                 = @s_sev,
			@s_msg                 = @s_msg,
			@s_org                 = @s_org,
			@s_service             = @s_service,
			@t_rty                 = @t_rty,
			@t_trn 				   = 73505,
			@i_actualiza_var 	   = 'S',
			@i_asig_manual 		   = 0,
			@i_id_inst_proc 	   = @w_id_inst_proc,
			@i_id_inst_act 	       = @w_id_inst_act,
			@i_id_asig_act         = @w_id_asig_act,
			@i_id_paso             = @w_id_paso,
			@i_codigo_res          = 1,
			@i_id_empresa          = 1,
			@i_operacion 		   = 'C',
			@o_ssn 				   = 0

		if @w_error != 0
			 begin
				goto ERROR
			 end
			 
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
