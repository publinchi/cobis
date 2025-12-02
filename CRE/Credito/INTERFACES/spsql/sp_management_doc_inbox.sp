/**************************************************************************/
/*   ARCHIVO:         sp_management_doc_inbox.sp                          */
/*   NOMBRE LOGICO:   sp_management_doc_inbox                             */
/*   PRODUCTO:        COBIS                                               */
/**************************************************************************/
/*                            IMPORTANTE                                  */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad          */
/*  de COBISCorp.                                                         */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como      */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus      */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.     */
/*  Este programa esta protegido por la ley de   derechos de autor        */
/*  y por las    convenciones  internacionales   de  propiedad inte-      */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para    */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir          */
/*  penalmente a los autores de cualquier   infraccion.                   */
/* ************************************************************************/
/*                     PROPOSITO                                          */
/*   Exponer el servicio para actualizar los documentos                   */
/*   que se suban al repositorio del sharepoint                           */
/**************************************************************************/
/*                     MODIFICACIONES                                     */
/*   FECHA         AUTOR               RAZON                              */
/* 05/OCT/2021     EBA                 Emision Inicial                    */
/* 24/Ene/2023     DMO                 Prints debug                       */
/**************************************************************************/
USE cob_interface
GO
if exists (select 1 from sysobjects where name = 'sp_management_doc_inbox')
   drop proc sp_management_doc_inbox
go

CREATE PROCEDURE sp_management_doc_inbox (
        @s_ssn                  int          = null,
        @s_date                 datetime     = null,
        @s_user                 login        = null,
        @s_term                 varchar(64)  = null,
        @s_ofi                  smallint     = null,
        @s_srv                  varchar(30)  = null,
        @s_rol                  smallint     = null,
        @s_sesn                 int          = null,
        @s_org                  char(1)      = null,
        @s_culture              varchar(10)  = null,
        @s_lsrv                 varchar(30)  = null,
        @t_trn                  smallint     = null,
        @t_debug                char(1)      = 'N',
        @t_file                 varchar(14)  = null,
        @t_from                 varchar(30)  = null,
        @i_task_inst_id         int          = null,
        @i_codigo               smallint     = null,
        @i_nameDocument         varchar(255) = null,
        @i_observation          varchar(250) = null,
        @i_date_register        varchar(50)  = null,
        @i_excepcionable        tinyint      = 0,
        @i_identificador_doc    int          = null,
        @i_nombre_tipo_doc      VARCHAR(255) = NULL,
        @i_tramite              int          = null

)
as
declare @w_sp_name              varchar(32),
        @w_error                int,
        @w_return               int,
        @w_codigo_externo       varchar(64),
        @w_codigo_tipo_doc      int,
        @w_inst_proc            int
        


select @w_sp_name = 'sp_management_doc_inbox',
       @w_error           = 0,
       @w_return          = 0,
       @w_codigo_tipo_doc = 0


print '@i_tramite' + CAST(@i_tramite AS VARCHAR)
print '@i_nombre_tipo_doc' + CONVERT(varchar,@i_nombre_tipo_doc)
        
if @i_tramite is not null AND @i_nombre_tipo_doc is not null
begin
    select @w_codigo_tipo_doc = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @i_nombre_tipo_doc
    
    
    if @w_codigo_tipo_doc is null or @w_codigo_tipo_doc = 0
    begin
        select @w_error = 2110232 --No existe categoria de documento asociada al proceso
        goto ERROR
    END
    
    select @w_inst_proc  = io_id_inst_proc 
    from cob_workflow..wf_inst_proceso 
    where io_campo_3 = @i_tramite
    
    select @i_task_inst_id = ia_id_inst_act
    from cob_workflow..wf_inst_actividad
    where ia_id_inst_proc = @w_inst_proc
    and ia_estado = 'ACT'
    
    if @i_task_inst_id is null
    begin
       select @i_task_inst_id = ia_id_inst_act
       from cob_workflow..wf_inst_actividad
       where ia_id_inst_proc = @w_inst_proc
       and ia_secuencia = 1
    end
    
    if @i_task_inst_id is null or @i_task_inst_id = 0
    begin
        select @w_error = 2110223 --No existe categoria de documento asociada al proceso
        goto ERROR
    END
    
exec @w_error = cob_workflow..sp_aso_requisito_wf
     @s_srv                 = @s_srv,
     @s_user                = @s_user,
     @s_term                = @s_term,
     @s_ofi                 = @s_ofi,
     @s_rol                 = @s_rol,
     @s_ssn                 = @s_ssn,
     @s_lsrv                = @s_lsrv,
     @s_date                = @s_date,
     @s_sesn                = @s_sesn,
     @i_operacion           = 'R',
     @i_task_inst_id        = @i_task_inst_id,
     @i_codigo              = @w_codigo_tipo_doc,--codigo del tipo de documento
     @i_nameDocument        = @i_nameDocument,
     @i_observation         = @i_observation,
     @i_date_register       = @i_date_register,
     @i_excepcionable       = @i_excepcionable,
     @i_identificador_doc   = @i_identificador_doc
     
    if @w_error != 0
    begin
       goto ERROR
    end
end
else
begin
    select @w_error = 2110223 --Error inst proceso o codigo no pueden ser null
    goto ERROR
end
return 0

ERROR:    --Rutina que dispara sp_cerror dado el codigo de error
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return 1
GO

