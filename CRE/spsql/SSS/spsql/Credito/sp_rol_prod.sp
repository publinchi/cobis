USE cob_pac
go
IF OBJECT_ID ('sp_rol_prod') IS NOT NULL
    DROP PROCEDURE sp_rol_prod
GO

CREATE PROCEDURE sp_rol_prod(
/************************************************************/
/*   ARCHIVO:         sp_rol_prod                           */
/*   NOMBRE LOGICO:   sp_rol_prod.sp                        */
/*   PRODUCTO:        COBIS FPM                             */
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
/*   Consulta del Pseudocatálogo para listar las roles de   */
/*   workflow.                                              */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA             AUTOR                RAZON           */
/* 13-Mayo-2019      WToledo          Emisión Inicial       */
/* 04-Sept-2019   Jonathan Tomalá     agrega funcionalidad  */
/************************************************************/

   @s_ssn            int = NULL,
   @s_user           login = NULL,
   @s_sesn           int = NULL,
   @s_term           varchar(30) = NULL,
   @s_date           datetime = NULL,
   @s_srv            varchar(30) = NULL,
   @s_lsrv           varchar(30) = NULL,
   @s_rol            smallint = NULL,
   @s_ofi            smallint = NULL,
   @s_org_err        char(1) = NULL,
   @s_error          int = NULL,
   @s_sev            tinyint = NULL,
   @s_msg            descripcion = NULL,
   @s_org            char(1) = NULL,
   @t_debug          char(1) = 'N',
   @t_show_version   bit             = 0,
   @t_file           varchar(14) = null,
   @t_from           varchar(32) = null,
   @t_trn            smallint =NULL,
   -- -------
   @i_tipo               char(1) = null,
   @i_tabla              varchar(30) = null,
   @i_codigo             varchar(150) = null,
   @i_oficina            int = 1,
   @i_filas              int = 80,
   @i_descripcion        varchar(150) = ''
) as
declare
@w_sp_name  varchar(32),
@w_error    int

select @w_sp_name = 'sp_rol_prod'

---- VERSIONAMIENTO DEL PROGRAMA ----
if @t_show_version = 1
begin
   print 'stored procedure ' + @w_sp_name + ', version 1.0.0.0'
   return 0
end

if @i_tipo = 'B' begin --consulta los registros sin filtro
   set rowcount @i_filas

   select ro_id_rol, ro_nombre_rol
   from cob_workflow..wf_rol
   order by ro_id_rol

   set rowcount 0
   return 0
end
if @i_tipo = 'V' --consulta el registro por código
begin

   select ro_id_rol, ro_nombre_rol
   from cob_workflow..wf_rol
   where ro_id_rol = @i_codigo

   if @@rowcount =  0
   begin
     select @w_error = 101000  --No existe dato en catálogo
     goto ERROR
   end

end
if @i_tipo = 'S' --consulta los registros por la descripción o nombre.
begin
   set rowcount @i_filas

   select ro_id_rol, ro_nombre_rol
   from cob_workflow..wf_rol
   where ro_id_rol > convert(tinyint, isnull (@i_codigo, '0'))
   and upper(ro_nombre_rol) like upper('%'+ isnull(@i_descripcion,'') + '%')
   order by ro_id_rol

   set rowcount 0
   return 0
end
if @i_tipo = 'C' --consulta el número de registros con o sin filtro.
begin

   select count(ro_id_rol)
   from cob_workflow..wf_rol

   return 0
end
return 0

ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null,
     @t_from  = @w_sp_name,
     @i_num   = @w_error

return @w_error

go
