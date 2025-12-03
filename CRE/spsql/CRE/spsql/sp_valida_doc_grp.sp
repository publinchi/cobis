/***********************************************************************/
/*     Base de Datos:           cob_credito                            */
/*     Stored procedure:        sp_verifica_aprobacion_act             */
/*     Producto:                Credito                                */
/*     Disenado por:                                                   */
/*     Fecha de Documentacion:  16/Jun/21                              */
/***********************************************************************/
/*                            IMPORTANTE                               */
/*     Este programa es parte de los paquetes bancarios propiedad de   */
/*     'COBISCORP S.A.'.                                               */
/*     Su uso no autorizado queda expresamente prohibido asi como      */
/*     cualquier autorizacion o agregado hecho por alguno de sus       */
/*     usuario sin el debido consentimiento por escrito de la          */
/*     Presidencia Ejecutiva de COBISCORP S.A. o su representante      */
/***********************************************************************/
/*                            PROPOSITO                                */
/*     Verifica documentos de cada integrante que participe en un      */
/*      credito gruapl.                                                */
/***********************************************************************/
/*                           MODIFICACIONES                            */
/*   FECHA              AUTOR                     RAZON                */
/*   12/JUL/2022        DMO                 Emision Inicial            */
/***********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_valida_doc_grp')
   drop procedure sp_valida_doc_grp
GO

CREATE PROCEDURE  sp_valida_doc_grp   (
   @t_debug          char(1)        = 'N',
   @t_file           varchar(14)    = null,
   @t_show_version   bit            = 0,     -- Mostrar la version del programa
   @s_ssn            int            = null,
   @s_sesn           int            = null,
   @s_term           descripcion    = null,
   @s_ofi            smallint,
   @s_user           login,
   @s_date           datetime,
   @s_srv            varchar(30)   = null,
   @s_lsrv           varchar(30)   = null,
   @s_rol            smallint      = null,
   @s_org_err        char(1)       = null,
   @s_error          int           = null,
   @s_sev            tinyint       = null,
   @s_msg            descripcion   = null,
   @s_org            char(1)       = null,
   @s_culture        varchar(10)   = null,
   @t_rty            char(1)       = null,
   @t_from           varchar(32)   = null,
   @t_trn            int           = null,
   @i_operacion      char(1)       = null,
   @i_tramite        int           = null


)
as

--print 'Declaracion de Variables'
declare     @w_sp_name               varchar(32),
            @w_msg_error             varchar(132),
            @w_nomlar                varchar(132),
            @w_error                 int,
            @w_integrante            int,
            @w_documento_cliente     varchar(2),
            @w_documento_grupal      varchar(6),
            @w_op_banco_padre        cuenta,
            @w_grupo                 int

--Versionamiento
if @t_show_version = 1
begin
      print 'Stored procedure sp_valida_doc_grp, Version 4.0.0.1'
      return 0
end

select @w_documento_cliente = 'CL'
select @w_documento_grupal = 'GRUPAL'

if(@i_operacion = 'V')
begin
    select @w_op_banco_padre = op_banco ,
           @w_grupo          = op_grupo
    from cob_cartera..ca_operacion where op_tramite = @i_tramite

    if (@w_op_banco_padre is null)
    begin
        select @w_error = 701049
        goto   ERROR
    end

    --DMO VALIDA DOCUMENTOS OBLIGATORIAS DE CADA CLIENTE - GRUPO
    if exists(
    select 1 from
        (select td_codigo_tipo_doc_fk
        from cob_workflow..wf_entidad_documentos
        where ed_tipo_entidad = @w_documento_grupal
        and ed_mandatorio = 1) as DOC_CLI
    left join
        (select td_codigo_tipo_doc_fk
        from cob_workflow..wf_documentos_ins
        where di_entidad_codigo_ins =  @w_grupo
        and di_tipo_entidad = @w_documento_grupal) as ALL_DOC
    on DOC_CLI.td_codigo_tipo_doc_fk = ALL_DOC.td_codigo_tipo_doc_fk
    where ALL_DOC.td_codigo_tipo_doc_fk is null)
    begin
        select @w_error = 2110399
        goto   ERROR
    end
	
	
    --CURSOR DE INTEGRANTES QUE PARTCIPAN
    declare cur_integrantes cursor for (
        select op_cliente from cob_cartera..ca_operacion
        where op_ref_grupal = @w_op_banco_padre
        and op_estado != 6
    )

    open cur_integrantes

    fetch cur_integrantes into @w_integrante

    while (@@fetch_status = 0)
    begin
        --DMO VALIDA DOCUMENTOS OBLIGATORIAS DE CADA CLIENTE
        if exists(
        select 1 from
            (select td_codigo_tipo_doc_fk
            from cob_workflow..wf_entidad_documentos
            where ed_tipo_entidad = @w_documento_cliente
            and ed_mandatorio = 1) as DOC_CLI
        left join
            (select td_codigo_tipo_doc_fk
            from cob_workflow..wf_documentos_ins
            where di_entidad_codigo_ins =  @w_integrante
            and di_tipo_entidad = @w_documento_cliente) as ALL_DOC
        on DOC_CLI.td_codigo_tipo_doc_fk = ALL_DOC.td_codigo_tipo_doc_fk
        where ALL_DOC.td_codigo_tipo_doc_fk is null)
        begin

            close cur_integrantes
            deallocate cur_integrantes
            select @w_nomlar = cast(@w_integrante as varchar)
            select @w_error = 2110398
            select @w_msg_error = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
            goto   ERROR
        end

        fetch cur_integrantes into @w_integrante
    end

    close cur_integrantes
    deallocate cur_integrantes

end


return 0
ERROR:
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_file  = '',
   @t_from  = @w_sp_name,
   @i_msg   = @w_msg_error,
   @i_num   = @w_error
   return @w_error


GO