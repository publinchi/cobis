USE cob_interface
GO
/************************************************************/
/*   ARCHIVO:         sp_management_doc_member.sp           */
/*   NOMBRE LOGICO:   sp_management_doc_member              */
/*   PRODUCTO:        COBIS                                 */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*   Exponer el servicio para actualizar los documentos     */
/*   que se suban al repositorio del sharepoint             */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/* 27/OCT/2021     EBA                 Emision Inicial      */
/************************************************************/

if exists (select 1 from sysobjects where name = 'sp_management_doc_member')
   drop proc sp_management_doc_member
go

CREATE PROCEDURE sp_management_doc_member (
   @s_ssn                int          = null,
   @s_date               datetime     = null,
   @s_user               login        = null,
   @s_term               varchar(64)  = null,
   @s_corr               char(1)      = null,
   @s_ssn_corr           int          = null,
   @s_ofi                smallint     = null,
   @t_rty                char(1)      = null,
   @t_trn                int          = null,
   @t_debug              char(1)      =  'N',
   @t_file               varchar(14)  = null,
   @t_from               varchar(30)  = null,

   @i_tipo_entidad       varchar(10)  = null, --CL
   @i_entidad_codigo_ins INT          = null,  -- codigo de la entidad 3
   @i_ente               int          = null,-- codigo del cliente
   @i_codigo_tipo_doc    SMALLINT     = null,
   @i_observacion        VARCHAR(250) = null,
   @i_ruta_servidor      VARCHAR(250) = null, -- Nombre del archivo.
   @i_doc_identifier_id  INT          =    0,
   @i_nombre_tipo_doc    VARCHAR(255) = null  -- Nombre del documento a subir

)
as
declare @w_sp_name              varchar(32),
        @w_error                int,
		@w_return               int,
		@w_codigo_externo       varchar(64),
		@w_codigo_tipo_doc      int
        


select @w_sp_name = 'sp_management_doc_member',
       @w_error           = 0,
       @w_return          = 0,
	   @w_codigo_tipo_doc = 0

		
if @i_ente is not null
begin

	select @w_codigo_tipo_doc = td_codigo_tipo_doc
	  from cob_workflow..wf_tipo_documento
	 where td_nombre_tipo_doc = @i_nombre_tipo_doc
	
	if @w_codigo_tipo_doc is null or @w_codigo_tipo_doc = 0
	begin
		select @w_error = 2110232 --No existe categoria de documento asociada al proceso
		goto ERROR
	end
	
exec @w_error = cob_workflow..sp_entidad_documentos
     @s_user                = @s_user,
     @s_term                = @s_term,
     @s_ofi                 = @s_ofi,
     @s_ssn                 = @s_ssn,
     @s_date                = @s_date,
     @i_operacion           = 'I',
     @i_entidad_codigo_ins  = @i_ente,
     @i_tipo_entidad        = @i_tipo_entidad,
     @i_ente                = @i_ente,
     @i_codigo_tipo_doc     = @w_codigo_tipo_doc, --Codigo del tipo de documento sacado de la tabla wf_tipo_documento
     @i_observacion         = 'Asignación manual desde servicio Rest',
	 @i_ruta_servidor       = @i_ruta_servidor,
	 @i_doc_identifier_id   = @i_doc_identifier_id
	 
    if @w_error != 0
    begin
       goto ERROR
    end
end
else
begin
	select @w_error = 2110234 --No existe cliente asociado
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

