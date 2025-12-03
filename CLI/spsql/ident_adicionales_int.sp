/************************************************************************/
/*   Archivo:            ident_adicionales_int.sp                       */
/*   Stored procedure:   sp_ident_adicionales_int                       */
/*   Base de datos:      cob_interface                                  */
/*   Producto:           Clientes                                       */
/*   Disenado por:       COB                                            */
/*   Fecha de escritura: 28-septiembre-21                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_ident_adicionales                       */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      28/09/21         COB       Emision Inicial                      */
/************************************************************************/
use cob_interface

go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_ident_adicionales_int')
   drop proc sp_ident_adicionales_int
go

create proc sp_ident_adicionales_int (
   @s_ssn              int,
   @s_sesn             int           = null,
   @s_user             login         = null,
   @s_term             varchar(32)   = null,
   @s_date             datetime,
   @s_srv              varchar(30)   = null,
   @s_lsrv             varchar(30)   = null,
   @s_ofi              smallint      = null,
   @s_rol              smallint      = null,
   @s_org_err          char(1)       = null,
   @s_error            int           = null,
   @s_sev              tinyint       = null,
   @s_msg              descripcion   = null,
   @s_org              char(1)       = null,
   @s_culture          varchar(10)   = 'NEUTRAL',
   @t_debug            char(1)       = 'n',
   @t_file             varchar(10)   = null,
   @t_from             varchar(32)   = null,
   @t_trn              int           = null,
   @t_show_version     bit           = 0,       -- versionamiento
   @i_operacion        char(1),
   @i_ente             int,
   @i_tipo_iden        catalogo        = null,
   @i_nume_iden        varchar(20)     = null,
   @i_tipo_iden_new    catalogo        = null,
   @i_nume_iden_new    varchar(20)     = null
)

as
declare @w_sp_name          varchar(30),
        @w_sp_msg           varchar(132),
        @w_error            int,
        @w_catalogo_valor   varchar(30),
        @w_init_msg_error   varchar(256),
        @w_tipo_ente        char(1),
        @w_nacionalidad     smallint,
        @w_mascara          int,
        @w_pais_local       smallint,
        @w_tipo_residencia  catalogo

/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_ident_adicionales_int',
@w_error            = 1720548

/* VALIDACIONES */

-- Obligatorios
-- cliente
if isnull(@i_ente,'') = '' and @i_ente <> 0
begin
   select @w_catalogo_valor = 'personSequential'
   goto VALIDAR_ERROR
end
if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente)
begin
   select @w_error = 1720104
   goto ERROR_FIN
end

if @i_operacion = 'S'
begin
   select ie_tipo_doc, ie_numero 
   from   cobis..cl_ident_ente 
   where  ie_ente = @i_ente

   if @@rowcount = 0
   begin
      select @w_error = 1720019
      goto ERROR_FIN
   end

   return 0
end

if isnull(@i_tipo_iden,'') = ''
begin
   select @w_catalogo_valor = 'typeIdentification'
   goto VALIDAR_ERROR
end

if isnull(@i_nume_iden,'') = ''
begin
   select @w_catalogo_valor = 'numberIdentification'
   goto VALIDAR_ERROR
end

if @i_operacion = 'U'
begin
   if isnull(@i_tipo_iden_new,'') = ''
   begin
      select @w_catalogo_valor = 'typeIdentificationNew'
      goto VALIDAR_ERROR
   end
   
   if isnull(@i_nume_iden_new,'') = ''
   begin
      select @w_catalogo_valor = 'numberIdentificationNew'
      goto VALIDAR_ERROR
   end
end

if @i_operacion = 'D'
begin
   if not exists (select 1 from cobis..cl_ident_ente 
              where ie_ente     = @i_ente
              and   ie_tipo_doc = @i_tipo_iden
              and   ie_numero   = @i_nume_iden)
   begin
      select @w_error = 1720571
      goto ERROR_FIN
   end

   exec @w_error = cobis..sp_ident_adicionales
   @s_ssn         = @s_ssn,
   @s_date        = @s_date,
   @s_user        = @s_user,
   @i_operacion   = 'D',
   @i_ente        = @i_ente,
   @i_tipo_iden   = @i_tipo_iden,
   @i_nume_iden   = @i_nume_iden
   
   if @w_error <> 0
   begin
      return @w_error
   end

   return 0
end

--pais local
select @w_pais_local = pa_smallint
  from cobis..cl_parametro
  where pa_nemonico = 'CP'
  and pa_producto = 'CLI'

--tipo ente
select @w_tipo_ente = en_subtipo
from   cobis..cl_ente 
where  en_ente = @i_ente

--obtener nacionalidad
if @w_tipo_ente = 'P'
begin
   select @w_nacionalidad    = en_nacionalidad,
          @w_tipo_residencia = en_tipo_residencia 
   from   cobis..cl_ente 
   where  en_ente = @i_ente
end
else
begin
   select @w_nacionalidad = en_pais
   from   cobis..cl_ente 
   where  en_ente = @i_ente
end


if @i_operacion = 'I'
begin
   --tipo de identificacion en uso
   if exists (select 1 from cobis..cl_ident_ente where ie_tipo_doc = @i_tipo_iden and ie_ente = @i_ente)
   begin
      select @w_error = 1720546
      goto ERROR_FIN
   end
   
   /*validacion tabla tipo de identificacion*/
   --VALIDACIONES DE IDENTIFICACIONES
   --nacional
   if @w_pais_local = @w_nacionalidad
   begin
      if not exists(select 1 from cobis..cl_tipo_identificacion
                 where ti_tipo_cliente    = @w_tipo_ente
                 and   ti_tipo_documento  = 'O'
                 and   ti_nacionalidad    = 'N'
                 and   ti_codigo          = @i_tipo_iden)
      begin
         select @w_catalogo_valor = @i_tipo_iden
         select @w_error = 1720552
         goto VALIDAR_ERROR
      end
      else
      begin
         select @w_mascara = len(ti_mascara) from cobis..cl_tipo_identificacion
         where ti_tipo_cliente    = @w_tipo_ente
         and   ti_tipo_documento  = 'O'
         and   ti_nacionalidad    = 'N'
         and   ti_codigo          = @i_tipo_iden
      end
   end
   else
   --extranjero
   begin
      --compañia
      if @w_tipo_ente = 'C'
      begin
         if not exists(select 1 from cobis..cl_tipo_identificacion
                       where ti_tipo_cliente   = @w_tipo_ente
                       and   ti_tipo_documento = 'O'
                       and   ti_nacionalidad   = 'E'
                       and   ti_codigo         = @i_tipo_iden)
         begin
            select @w_catalogo_valor = @i_tipo_iden
            select @w_error = 1720552
            goto VALIDAR_ERROR
         end
         else
         begin
            select @w_mascara = len(ti_mascara) from cobis..cl_tipo_identificacion
            where ti_tipo_cliente   = @w_tipo_ente
            and   ti_tipo_documento = 'O'
            and   ti_nacionalidad   = 'E'
            and   ti_codigo         = @i_tipo_iden
         end
      end
      --Persona
      else if @w_tipo_ente = 'P'
      begin
         select @w_tipo_ente
         select @i_tipo_iden
         select @w_tipo_residencia
         if not exists(select 1 from cobis..cl_tipo_identificacion
                       where ti_tipo_cliente    = @w_tipo_ente
                       and   ti_tipo_documento  = 'O'
                       and   ti_nacionalidad    = 'E'
                       and   ti_codigo          = @i_tipo_iden
                       and   ti_tipo_residencia = @w_tipo_residencia)
         begin
            select @w_catalogo_valor = @i_tipo_iden
            select @w_error = 1720552
            goto VALIDAR_ERROR
         end
         else
         begin
            select @w_mascara = len(ti_mascara) from cobis..cl_tipo_identificacion
            where ti_tipo_cliente    = @w_tipo_ente
            and   ti_tipo_documento  = 'O'
            and   ti_nacionalidad    = 'E'
            and   ti_codigo          = @i_tipo_iden
            and   ti_tipo_residencia = @w_tipo_residencia
         end
      end
   end
   
   
   if not @w_mascara = len(@i_nume_iden)
   begin
      select @w_error = 1720550
      goto ERROR_FIN
   end
   
   if exists (select 1 from cobis..cl_ident_ente where ie_tipo_doc = @i_tipo_iden and ie_numero = @i_nume_iden)
   begin
      select @w_error = 1720442
      goto ERROR_FIN
   end

   if (select COUNT(*) from cobis..cl_ident_ente where ie_ente = @i_ente) >= (select pa_smallint from cobis..cl_parametro where pa_nemonico = 'NIAMP' and pa_producto = 'CLI')
   begin
      select @w_error = 1720535
      goto ERROR_FIN
   end

   exec @w_error = cobis..sp_ident_adicionales
   @s_ssn         = @s_ssn,
   @s_date        = @s_date,
   @s_user        = @s_user,
   @i_operacion   = 'I',
   @i_ente        = @i_ente,
   @i_tipo_iden   = @i_tipo_iden,
   @i_nume_iden   = @i_nume_iden

   if @w_error <> 0
   begin
      return @w_error
   end
end

if @i_operacion = 'U'
begin
   if not exists (select 1 from cobis..cl_ident_ente 
              where ie_ente     = @i_ente
              and   ie_tipo_doc = @i_tipo_iden
              and   ie_numero   = @i_nume_iden)
   begin
      select @w_error = 1720571
      goto ERROR_FIN
   end

   --tipo de identificacion en uso
   if @i_tipo_iden <> @i_tipo_iden_new
   begin
      if exists (select 1 from cobis..cl_ident_ente where ie_tipo_doc = @i_tipo_iden_new and ie_ente = @i_ente)
      begin
         select @w_error = 1720546
         goto ERROR_FIN
      end
   end
   
   /*validacion tabla tipo de identificacion*/
   
   --VALIDACIONES DE IDENTIFICACIONES
   --nacional
   if @w_pais_local = @w_nacionalidad
   begin
      if not exists(select 1 from cobis..cl_tipo_identificacion
                 where ti_tipo_cliente    = @w_tipo_ente
                 and   ti_tipo_documento  = 'O'
                 and   ti_nacionalidad    = 'N'
                 and   ti_codigo          = @i_tipo_iden_new)
      begin
         select @w_catalogo_valor = @i_tipo_iden_new
         select @w_error = 1720552
         goto VALIDAR_ERROR
      end
      else
      begin
         select @w_mascara = len(ti_mascara) from cobis..cl_tipo_identificacion
         where ti_tipo_cliente    = @w_tipo_ente
         and   ti_tipo_documento  = 'O'
         and   ti_nacionalidad    = 'N'
         and   ti_codigo          = @i_tipo_iden_new
      end
   end
   else
   --extranjero
   begin
      --compañia
      if @w_tipo_ente = 'C'
      begin
         if not exists(select 1 from cobis..cl_tipo_identificacion
                       where ti_tipo_cliente   = @w_tipo_ente
                       and   ti_tipo_documento = 'O'
                       and   ti_nacionalidad   = 'E'
                       and   ti_codigo         = @i_tipo_iden_new)
         begin
            select @w_catalogo_valor = @i_tipo_iden_new
            select @w_error = 1720552
            goto VALIDAR_ERROR
         end
         else
         begin
            select @w_mascara = len(ti_mascara) from cobis..cl_tipo_identificacion
            where ti_tipo_cliente   = @w_tipo_ente
            and   ti_tipo_documento = 'O'
            and   ti_nacionalidad   = 'E'
            and   ti_codigo         = @i_tipo_iden_new
         end
      end
      --Persona
      else if @w_tipo_ente = 'P'
      begin
         if not exists(select 1 from cobis..cl_tipo_identificacion
                       where ti_tipo_cliente    = @w_tipo_ente
                       and   ti_tipo_documento  = 'O'
                       and   ti_nacionalidad    = 'E'
                       and   ti_codigo          = @i_tipo_iden_new
                       and   ti_tipo_residencia = @w_tipo_residencia)
         begin
            select @w_catalogo_valor = @i_tipo_iden_new
            select @w_error = 1720552
            goto VALIDAR_ERROR
         end
         else
         begin
            select @w_mascara = len(ti_mascara) from cobis..cl_tipo_identificacion
            where ti_tipo_cliente    = @w_tipo_ente
            and   ti_tipo_documento  = 'O'
            and   ti_nacionalidad    = 'E'
            and   ti_codigo          = @i_tipo_iden_new
            and   ti_tipo_residencia = @w_tipo_residencia
         end
      end
   end
   
   if not @w_mascara = len(@i_nume_iden_new)
   begin
      select @w_error = 1720550
      goto ERROR_FIN
   end
   
   if exists (select 1 from cobis..cl_ident_ente where ie_tipo_doc = @i_tipo_iden_new and ie_numero = @i_nume_iden_new)
   begin
      select @w_error = 1720442
      goto ERROR_FIN
   end


   exec @w_error = cobis..sp_ident_adicionales
   @s_ssn         = @s_ssn,
   @s_date        = @s_date,
   @s_user        = @s_user,
   @i_operacion   = 'U',
   @i_ente        = @i_ente,
   @i_tipo_iden   = @i_tipo_iden_new,
   @i_nume_iden   = @i_nume_iden_new,
   @i_tipo_iden_a = @i_tipo_iden,
   @i_nume_iden_a = @i_nume_iden
   if @w_error <> 0
   begin
      return @w_error
   end
end

return 0

VALIDAR_ERROR:
   select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_catalogo_valor, @w_error, @s_culture)
   goto ERROR_FIN

ERROR_FIN:

select @w_sp_msg = UPPER(@w_sp_msg)

exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_msg      = @w_sp_msg,
         @i_num      = @w_error
       
return @w_error

go
