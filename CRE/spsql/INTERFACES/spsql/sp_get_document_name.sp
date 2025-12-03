/********************************************************************/
/*   ARCHIVO:         sp_get_document_name.sp                       */
/*   NOMBRE LOGICO:   sp_get_document_name                          */
/*   PRODUCTO:        COBIS WORKFLOW                                */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Devuelve las propiedades de los archivos subidos               */
/*   al workflow en base al id de la instancia.                     */
/*******************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA         AUTOR          RAZON                             */
/*   18-Oct-2021   EBA            Emision Inicial.                  */
/*   29-Oct-2021   EBA            Input Tramite                     */
/*   17-May-2023   BDU            Ajustes APP                       */
/*   18-May-2023   BDU            Ajustes query                     */
/*   10-Jul-2023   BDU            Se obtiene ultima act y paso      */
/********************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_get_document_name')
    drop proc sp_get_document_name
go

create procedure sp_get_document_name
(
  @s_ssn                        int          = null,
  @s_user                       varchar(30)  = null,
  @s_sesn                       int          = null,
  @s_term                       varchar(30)  = null,
  @s_date                       datetime     = null,
  @s_srv                        varchar(30)  = null,
  @s_lsrv                       varchar(30)  = null,
  @s_ofi                        smallint     = null,
  @t_debug                      char(1)      = 'N',
  @t_file                       varchar(14)  = null,
  @t_from                       varchar(30)  = null,
  @t_trn                        smallint     = null,
  @s_rol                        smallint     = null,
  @s_org_err                    char(1)      = null,
  @s_error                      int          = null,
  @s_sev                        tinyint      = null,
  @s_org                        char(1)      = null,
  @i_id_inst_proc               int          = null,
  @i_tipo_requisito             varchar(255) = null,
  @i_operacion                  char(1)      = null,
  @i_tipo_entidad               varchar(10)  = null,
  @i_tramite                    int          = null
  
)
as
    declare @w_mensaje              varchar(255),
            @w_error                int,
            @w_sp_name              varchar(64),
            @w_registros            int,
            @w_actividad            int,
            @w_paso                 int,
            @w_codigo_tipo_doc      smallint,
            @w_categoria_doc        varchar(10),
            @w_id_inst_proc         int,
            @w_tipo_requisito       varchar(255)


    select @w_sp_name = 'sp_get_document_name',
           @w_actividad = 0,
           @w_paso = 0,
           @w_codigo_tipo_doc = 0,
           @w_id_inst_proc = 0
           
--Se saca el nombre del doc de un parametro
select @w_tipo_requisito = pa_parametro 
from cobis.dbo.cl_parametro cp 
where pa_char = @i_tipo_requisito

if @i_operacion = 'R' --Requisitos Inbox
begin   
    if (@i_tramite is not null and @i_tramite <> 0) or (@i_id_inst_proc is not null and @i_id_inst_proc <> 0)
    begin
       if(@i_id_inst_proc is not null and @i_id_inst_proc <> 0)
       begin
          set @w_id_inst_proc = @i_id_inst_proc
       end
       else
       begin
          select  @w_id_inst_proc = io_id_inst_proc
          from cob_workflow..wf_inst_proceso
          where io_campo_3 = @i_tramite
          and io_estado = 'EJE'
       end
        
        if @w_id_inst_proc is null or @w_id_inst_proc = 0
        begin
            select @w_error = 2110230 --No existe instancia de proceso asociada
            goto ERROR
        end
        else
        begin
            select @w_registros = count(*) 
              from cob_workflow..wf_inst_actividad
             where ia_id_inst_proc = @w_id_inst_proc
            if @w_registros = 1
            begin
                select @w_actividad = ia_id_inst_act,
                       @w_paso      = ia_id_paso
                  from cob_workflow..wf_inst_actividad
                 where ia_id_inst_proc = @w_id_inst_proc
                   and ia_estado IN ('INA','ACT')
                
                if @w_actividad = 0 and @w_paso = 0
                begin
                    select @w_error = 2110231 --No existe una actividad asociada al proceso
                    goto ERROR
                end
            end
            else
            begin
                 select top 1 @w_actividad = ia_id_inst_act,
                      @w_paso      = ia_id_paso
                 from cob_workflow..wf_inst_actividad
                 where ia_id_inst_proc = @w_id_inst_proc
                 order by ia_id_inst_act desc
                
                if @w_actividad = 0 and @w_paso = 0
                begin
                    select @w_error = 2110231 --No existe una actividad asociada al proceso
                    goto ERROR
                end
            end
        end
    end
    
    select @w_codigo_tipo_doc = tr_codigo_tipo_doc
      from cob_workflow..wf_tipo_req_act
     where tr_id_paso = @w_paso
     and   tr_texto = @w_tipo_requisito
    
    if @w_codigo_tipo_doc <> 0
    begin
        select @w_categoria_doc = td_categoria_doc
          from cob_workflow..wf_tipo_documento
          where td_codigo_tipo_doc =  @w_codigo_tipo_doc
         
         if @w_categoria_doc is null
         begin
            select @w_error = 2110232 --No existe categoria de documento asociada al proceso
            goto ERROR
         end
    end
    else
    begin
        select @w_error = 2110233 --No existe tipo de requisito asociada al proceso
        goto ERROR
    end
    
    select 'actividad' = @w_actividad, 
           'categoria' = @w_categoria_doc,
           'nombre'    = @w_tipo_requisito,
           'instancia' = @w_id_inst_proc

end
if @i_operacion = 'I' --Requisitos por integrantes
begin

    SELECT @w_codigo_tipo_doc = td_codigo_tipo_doc
      FROM cob_workflow..wf_entidad_documentos ed
      JOIN cob_workflow..wf_tipo_documento td ON ed.td_codigo_tipo_doc_fk = td.td_codigo_tipo_doc
     WHERE ed_tipo_entidad = @i_tipo_entidad
     and   td_nombre_tipo_doc = @w_tipo_requisito

    if @@rowcount = 0
    begin
        select @w_error = 2110233 --No existe tipo de requisito asociada al proceso
        goto ERROR
    end
        
    select 'codigo' = @w_codigo_tipo_doc,
           'nombre'    = @w_tipo_requisito
end
if @i_operacion = 'C' --Requisitos por integrantes
begin

    select dp_codigo from cobis..cl_documento_parametro 
    WHERE  dp_detalle = @w_tipo_requisito-- 'DOCUMENTO DE IDENTIFICACIÓN'
      and  dp_tipo = @i_tipo_entidad
     --WHERE ed_tipo_entidad = @i_tipo_entidad
     --and   td_nombre_tipo_doc = @w_tipo_requisito

    if @@rowcount = 0
    begin
        select @w_error = 2110233 --No existe tipo de requisito asociada al proceso
        goto ERROR
    end
        
    select 'codigo' = @w_codigo_tipo_doc
end

RETURN 0

ERROR:    --Rutina que dispara sp_cerror dado el codigo de error
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return 1



GO

