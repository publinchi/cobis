/************************************************************************/
/*  Archivo:             empleo_int.sp                                  */
/*  Stored procedure:    sp_empleo_int                                  */
/*  Base de datos:       cob_interface                                  */
/*  Producto:            Clientes                                       */
/*  Disenado por:        COB                                            */
/*  Fecha de escritura:  16-septiembre-21                               */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_empleo_int                              */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA           AUTOR           RAZON                               */
/*  13/09/21        COB          Emision Inicial                        */
/*  20/09/21        COB          Se agrega output para servicios REST   */
/*  22/01/24        BDU          R224055-Validar oficina app            */
/************************************************************************/
use cob_interface
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select * from sysobjects where  name = 'sp_empleo_int')
   drop proc sp_empleo_int
go

create proc sp_empleo_int
(
   @s_ssn                int,
   @s_sesn               int           = null,
   @s_user               login         = null,
   @s_term               varchar(32)   = null,
   @s_date               datetime,
   @s_srv                varchar(30)   = null,
   @s_lsrv               varchar(30)   = null,
   @s_ofi                smallint      = null,
   @s_rol                smallint      = null,
   @s_org_err            char(1)       = null,
   @s_error              int           = null,
   @s_sev                tinyint       = null,
   @s_msg                descripcion   = null,
   @s_org                char(1)       = null,
   @s_culture            varchar(10)   = 'NEUTRAL',
   @t_debug              char(1)       = 'n',
   @t_file               varchar(10)   = null,
   @t_from               varchar(32)   = null,
   @t_trn                int           = null,
   @t_show_version       bit           = 0,       -- versionamiento
   @i_operacion          char(1),
   @i_ente               int           = null,
   @i_secuencial         int           = null,
   @i_empresa            int           = null,
   @i_nombre_emp         varchar(64)   = null,
   @i_direccion          varchar(254)  = null,
   @i_tipo_cargo         catalogo      = null,
   @i_cargo              varchar(64)   = null,
   @i_antiguedad         int           = null,
   @i_func_publico       char(1)       = null,
   @i_planilla           varchar(64)   = null,
   @i_cod_actividad      catalogo      = null,
   @i_fecha_ingreso      date          = null,
   @i_fecha_salida       date          = null,
   @o_id                 int           = null  OUTPUT

)
as
declare @w_sp_name           varchar(30),
        @w_sp_msg            varchar(132),
        @w_relacion          int,
        @w_oficial           int,
        @w_estado_prospecto  char(1),
        @w_lado_relacion     char(1),
        @w_ente_c            int,
        @w_trn_dir           int,
        @w_error             int,
        @w_operacion         char(1),
        @w_existente         bit,
        @w_catalogo_valor    varchar(30),
        @w_init_msg_error    varchar(256),
        @w_cod_actividad     catalogo,
        @w_max_dir           int,
        @w_provincia         varchar(30),
        @w_canton            varchar(30),
        @w_parroquia         varchar(30),
        @w_calle_p           varchar(30),
        @w_calle_s           varchar(30)

/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_empleo_int',
@w_operacion        = '',
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
   select
      'Numero'              = tr_trabajo,
      'Empresa'             = substring(tr_empresa,1,20),
      'Cargo'               = substring(tr_cargo,1,20),
      'Tipo Empleo'         = tr_tipo_empleo,
      'Moneda'              = substring(mo_descripcion,1,15),
      'Sueldo'              = tr_sueldo,
      'Verif.'              = tr_verificado,
      'Vig.'                = tr_vigencia,
      'Fecha Ing.'          = (select format (tr_fecha_ingreso, 'dd/MM/yyyy HH:mm:ss') as date),
      'Fecha Sal.'          = (select format (tr_fecha_salida, 'dd/MM/yyyy HH:mm:ss') as date),
      'Fecha Mod.'          = (select format (tr_fecha_modificacion, 'dd/MM/yyyy HH:mm:ss') as date),
      'Maneja Rec Pub'      = tr_recpublicos,
      'Obs Verificado'      = tr_obs_verificado,
        'Actividad'           = tr_descripcion,--verificar
        'Direccion'           = tr_direccion_emp,
        'Telefono'            = tr_telefono,
        'Tipo Empresa'        = tr_tipo_emp,
        'Antiguedad'          = tr_antiguedad,
        'Funcionario Publico' = tr_func_public,
        'Planilla'            = tr_planilla,
        'Cod Actividad'       = tr_cod_actividad,
        'Id Empresa'          = tr_id_empresa,
        'Tipo Cargo'          = tr_tipo_cargo
      from   cobis..cl_trabajo left outer join cobis..cl_moneda
      on     tr_moneda      = mo_moneda
      where  tr_persona     = @i_ente

   if @@rowcount = 0
   begin
      select @w_error = 1720019
      goto ERROR_FIN
   end

   return 0

end

if @i_operacion in ('D','U')
begin
   if isnull(@i_secuencial, 0) = 0
   begin
      select @w_catalogo_valor = 'refSequential'
      goto VALIDAR_ERROR
   end
   if not exists (select 1 from cobis..cl_trabajo where tr_persona = @i_ente and tr_trabajo = @i_secuencial)
   begin
      select @w_error = 1720570
      goto ERROR_FIN
   end
end

if @i_operacion = 'D'
begin
   exec @w_error = cobis..sp_empleo
   @s_ssn         = @s_ssn,
   @s_date        = @s_date,
   @s_user        = @s_user,
   @s_ofi         = @s_ofi,
   @t_trn         = 1230,
   @i_operacion   = 'D',
   @i_ente        = @i_ente,
   @i_trabajo     = @i_secuencial

   if @w_error <> 0
   begin
      return @w_error
   end

   return 0
end

--CICLO CUANDO NO ENVIAN PERSONA JURIDICA
if isnull(@i_empresa, 0) = 0
begin
   if isnull(@i_nombre_emp, '') = ''
   begin
      select @w_catalogo_valor = 'companyName'
      goto VALIDAR_ERROR
   end

   select @i_nombre_emp = upper(@i_nombre_emp)
   select @i_direccion = upper(@i_direccion)

   if isnull(@i_cod_actividad,'') <> ''
   begin
      exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_actividad_ec', @i_valor = @i_cod_actividad
      if @w_error <> 0 and @w_error != 1720018
         goto ERROR_FIN
      else if @w_error = 1720018
      begin 
         select @w_catalogo_valor = @i_cod_actividad
         select @w_error = 1720552
         goto VALIDAR_ERROR
      end
   end
end
else
--CICLO CUANDO ENVIAN PERSONA JURIDICA
begin
   if not exists (select 1 from cobis..cl_ente where en_ente = @i_empresa and en_subtipo = 'C')
   begin
      select @w_error = 1720022
      goto ERROR_FIN
   end
   select @i_nombre_emp = en_nomlar from cobis..cl_ente where en_ente = @i_empresa

   select @w_cod_actividad = en_actividad from cobis..cl_ente where en_ente = @i_empresa
   select @i_cod_actividad = isnull(@w_cod_actividad,null)

   select @w_max_dir = max(di_direccion) from cobis..cl_direccion where di_ente = @i_empresa

   if @w_max_dir <> null
   begin
      select @w_provincia = (select b.valor
                             from cobis..cl_tabla a,
                                  cobis..cl_catalogo b
                             where a.tabla   = 'cl_provincia'
                             and   a.codigo  = b.tabla
                             and   b.codigo  = d.di_provincia),
             @w_canton    = (select  b.valor
                             from cobis..cl_tabla a,
                                  cobis..cl_catalogo b
                              where a.tabla  = 'cl_ciudad'
                              and   a.codigo = b.tabla
                              and   b.codigo = d.di_ciudad),
             @w_parroquia = (select b.valor
                             from cobis..cl_tabla a,
                                  cobis..cl_catalogo b
                             where a.tabla  = 'cl_parroquia'
                             and   a.codigo = b.tabla
                             and   b.codigo = d.di_parroquia),
             @w_calle_p   = di_casa,
             @w_calle_s   = di_calle
      from  cobis..cl_direccion d
      where di_ente      = @i_empresa
      and   di_direccion = @w_max_dir

      select @i_direccion = concat(@w_provincia,", " ,@w_canton,", ", @w_parroquia,
                                   ", ", @w_calle_s, ", ",   @w_calle_p)
   end

end

if isnull(@i_tipo_cargo, '') = ''
begin
   select @w_catalogo_valor = 'typeCharge'
   goto VALIDAR_ERROR
end
else
begin
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_rol_empresa', @i_valor = @i_tipo_cargo
   if @w_error <> 0 and @w_error != 1720018
      goto ERROR_FIN
   else if @w_error = 1720018
   begin 
      select @w_catalogo_valor = @i_tipo_cargo
      select @w_error = 1720552
      goto VALIDAR_ERROR
   end
end

select @i_cargo = upper(@i_cargo)

if @i_antiguedad > 100
begin
   select @w_error = 1720565
   goto ERROR_FIN
end

if isnull(@i_func_publico, '') = ''
begin
   select @w_catalogo_valor = 'publicServant'
   goto VALIDAR_ERROR
end
else
begin
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_mandatorio', @i_valor = @i_func_publico
   if @w_error <> 0 and @w_error != 1720018
      goto ERROR_FIN
   else if @w_error = 1720018
   begin 
      select @w_catalogo_valor = @i_func_publico
      select @w_error = 1720552
      goto VALIDAR_ERROR
   end
end

if isnull(@i_planilla, '') <> ''
begin
   if isnumeric(@i_planilla) <> 1
   begin
      select @w_error = 1720564
      goto ERROR_FIN
   end
end

if isnull(@i_fecha_ingreso,'') = ''
begin
   select @w_catalogo_valor = 'dateIn'
   goto VALIDAR_ERROR
end
else
begin
   if @i_fecha_ingreso > (select fp_fecha from cobis..ba_fecha_proceso)
   begin
      select @w_error = 1720566
      goto ERROR_FIN
   end
end

if isnull(@i_fecha_salida,'') <> ''
begin
   if @i_fecha_salida > (select fp_fecha from cobis..ba_fecha_proceso)
   begin
      select @w_error = 1720566
      goto ERROR_FIN
   end
end

if (@i_operacion = 'I')
begin

   exec @w_error = cobis..sp_empleo
   @s_ssn            = @s_ssn,
   @s_date           = @s_date,
   @s_user           = @s_user,
   @s_ofi            = @s_ofi,
   @t_trn            = 181,
   @i_operacion      = 'I',
   @i_ente           = @i_ente,
   @i_empresa        = @i_empresa,
   @i_nombre_emp     = @i_nombre_emp,
   @i_direccion      = @i_direccion,
   @i_tipo_cargo     = @i_tipo_cargo,
   @i_cargo          = @i_cargo,
   @i_fecha_ingreso  = @i_fecha_ingreso,
   @i_fecha_salida   = @i_fecha_salida,
   @i_antiguedad     = @i_antiguedad,
   @i_func_publico   = @i_func_publico,
   @i_planilla       = @i_planilla,
   @i_cod_actividad  = @i_cod_actividad,
   @o_siguiente      = @o_id out

   if @w_error <> 0
   begin
      return @w_error
   end

end
else if (@i_operacion = 'U')
begin
   exec @w_error = cobis..sp_empleo
   @s_ssn            = @s_ssn,
   @s_date           = @s_date,
   @s_user           = @s_user,
   @s_ofi            = @s_ofi,
   @t_trn            = 182,
   @i_operacion      = 'U',
   @i_ente           = @i_ente,
   @i_trabajo        = @i_secuencial,
   @i_empresa        = @i_empresa,
   @i_nombre_emp     = @i_nombre_emp,
   @i_direccion      = @i_direccion,
   @i_tipo_cargo     = @i_tipo_cargo,
   @i_cargo          = @i_cargo,
   @i_fecha_ingreso  = @i_fecha_ingreso,
   @i_fecha_salida   = @i_fecha_salida,
   @i_antiguedad     = @i_antiguedad,
   @i_func_publico   = @i_func_publico,
   @i_planilla       = @i_planilla,
   @i_cod_actividad  = @i_cod_actividad


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
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_msg   = @w_sp_msg,
        @i_num   = @w_error
       
return @w_error

go
