/************************************************************************/
/*  Archivo:                         listas_negras.sp                   */
/*  Stored procedure:                sp_listas_negras                   */
/*  Base de datos:                   cobis                              */
/*  Producto:                        Clientes                           */
/*  Disenado por:                    ACA                                */
/*  Fecha de escritura:              14-10-2021                         */
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
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                          PROPOSITO                                   */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      14/10/21        ACA           Emision Inicial                   */
/*      16/12/22        BDU           Cambio de logica direcciones mail */
/*      07/11/23        DMO          R218833: Se valida apellido casado */
/*      12/12/23        DMO          R220191: Se modifica validaciones  */
/*                                   de listas con catalogo cl_causales_*/
/*      08/03/24        DMO          R227230: Se crea codigo de manera  */
/*                                   manual ya que @i_transaccion_ref es*/
/*                                   null                               */
/*      29/05/24       DMO           R233137: Se corrige validaciones   */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_listas_negras')
   drop proc sp_listas_negras
go
CREATE PROCEDURE sp_listas_negras (
        @s_ssn                           int          = null,
        @s_user                          login        = null,
        @s_term                          varchar(32)  = null,
        @s_sesn                          int          = null,
        @s_culture                       varchar(10)  = 'NEUTRAL',
        @s_date                          datetime     = null,
        @s_srv                           varchar(30)  = null,
        @s_lsrv                          varchar(30)  = null,
        @s_rol                           smallint     = NULL,
        @s_org_err                       char(1)      = NULL,
        @s_error                         int          = NULL,
        @s_sev                           tinyint      = NULL,
        @s_msg                           descripcion  = NULL,
        @s_org                           char(1)      = NULL,
        @s_ofi                           smallint     = NULL,
        @t_debug                         char(1)      = 'N',
        @t_file                          varchar(14)  = null,
        @t_from                          varchar(30)  = null,
        @t_trn                           int          = null,
        @t_show_version                  bit          = 0,     -- Mostrar la version del programa
        @i_operacion                     char(1)      = null,  -- Valor de la operacion a realizar
        @i_tipo                          char(1)      = null,  -- P o C
        @i_apellido                      varchar(255) = null,             
        @i_nombre                        varchar(255) = null,             
        @i_nombre_compania               varchar(255) = null,
        @i_nombre_usuario                varchar(255) = null,
        @i_porcentaje_precision          tinyint      = null,
        @i_pais                          varchar(3)   = null,
        @i_parametros_adicionales        varchar(255) = null,
        @i_ente                          int          = null,
        @i_tipo_iden                     varchar(24)  = null,
        @i_numero_iden                   varchar(30)  = null,
        @i_fecha_nacimiento              varchar(10)  = null,
        @i_transaccion_ref               varchar(51)  = null,
        @i_numero_coincidencia           int          = null,
        @i_nro_proceso                   int          = null,
        @i_aml                           varchar(10)  = null,
        @i_justificacion                 varchar(500) = null,
        @i_apellido_casada               varchar(255) = null,
        @o_id_transaccion                varchar(51)  = null out,
        @o_coincidencia                  int          = null out
        )
as
declare 
        @w_sp_name                   varchar(32),
        @w_return                    int,
        @w_contador                  smallint,
        @w_estado_resolucion         char(1),
        @w_error                     int,
        @w_sp_msg                    varchar(100),
        @w_nombre_completo           varchar(500),
        @w_xml                       nvarchar(2000),
        @w_tipo_proceso              varchar(255),
        @w_solucion                  varchar(255),
        @w_template                  int,
        @w_email_func                varchar(2000),
        @w_ente                      int,
        @w_solicitud                 varchar(50),
        @w_producto                  catalogo,
        @w_identificacion            varchar(58),
        @w_fecha_nac                 date,
        @w_cargo                     smallint,
        @w_subject                   varchar(250)

select  @w_sp_name             = 'listas_negras',
        @w_ente                = isnull(@i_ente,0),
        @i_numero_coincidencia = isnull(@i_numero_coincidencia,0),
        @w_contador            = 0,
        @w_nombre_completo     = @i_nombre + ' ' + isnull(@i_apellido,''),
        @w_email_func          = ''
select  @w_subject             = pa_char from cobis..cl_parametro where pa_producto = 'CLI' and pa_nemonico = 'SCLN'

if not exists (select 1 from cl_ente where en_ente = @i_ente)   
begin
   select @w_error = 1720035
   goto ERROR_FIN
end


create table #cl_causales_interno_buro(
        codigo char(10) null
)

insert into #cl_causales_interno_buro
select c.codigo  
from cl_tabla t with(nolock)
inner join cl_catalogo c on c.tabla = t.codigo 
where t.tabla = 'cl_causales_interno_buro'


select @i_numero_iden = upper(@i_numero_iden)

if @i_numero_coincidencia < 0
begin
   set @w_subject +=  ' (TIMEOUT)'
   if isnull (@i_numero_iden,'') <> ''
   begin
         select @w_identificacion = isnull(@i_tipo_iden,'') + ' - ' + isnull(@i_numero_iden,'')
   end
   
   if @s_culture != 'NEUTRAL'
   begin
   select @i_justificacion = re_valor                                                                                                                                                                           
         from   cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int                                                                                                                                                                                                                        
         and    re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where numero = 1720602 
   end
   else
   begin
   select top 1 @i_justificacion = mensaje                                                                                                                                                                           
         from   cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int)                                                                                                                                                                                                           
         where numero = 1720602
   end
end
else
begin

   if isnull (@i_ente,'') <> ''
   begin
      select @i_numero_coincidencia = @i_numero_coincidencia + count(1) 
      from cl_mala_ref 
      where mr_ente = @i_ente
      and mr_treferencia in (select codigo  
                             from #cl_causales_interno_buro)
   end
   
   if isnull (@i_numero_iden,'') <> ''
   begin
      select @w_identificacion = isnull(@i_tipo_iden,'') + ' - ' + isnull(@i_numero_iden,'')
      select @w_contador       = @w_contador + count(1) from cl_narcos where na_cedula = @i_numero_iden
      
      select @w_contador       = @w_contador + count(1) 
      from cl_com_liquidacion 
      where cl_ced_ruc = @i_numero_iden
      and cl_problema in (select codigo  
                          from #cl_causales_interno_buro)
      
      if (@w_contador = 0)
      begin
         select @w_contador = @w_contador + count(1) from cl_narcos where na_nombre = @w_nombre_completo
         
         select @w_contador = @w_contador + count(1) 
         from cl_com_liquidacion 
         where cl_nombre = @w_nombre_completo
         and cl_problema in (select codigo  
                             from #cl_causales_interno_buro)
      end
      
      select @i_numero_coincidencia = @i_numero_coincidencia + @w_contador
   
   end
   
end
if @i_tipo = 'C' and isnull(@i_apellido ,'') <> ''
begin
   select @i_apellido  = null,
          @w_fecha_nac = ''
end
else
begin
   select @w_fecha_nac = convert (Date, @i_fecha_nacimiento, 103)
end

--DMO SE GENERA CODIGO. PROVEEDOR NO PROPORCIONA CODIGO
select @i_transaccion_ref += @i_pais + '-' + (concat((convert(varchar, @i_ente)),('-'+convert(varchar, @s_ssn))))       



insert into cl_listas_negras_log (ln_fecha_consulta,         ln_usuario,          ln_id_verificacion,
                                  ln_numero_coincidencias,   ln_nombre,           ln_apellido,
                                  ln_codigo_cliente,         ln_nro_proceso,      ln_tipo_documento,
                                  ln_numero_documento,       ln_fecha_nacimiento)   
values                           (getDate(),                 @i_nombre_usuario,   @i_transaccion_ref,
                                  @i_numero_coincidencia,    @i_nombre,           @i_apellido,
                                  @i_ente,                   @i_nro_proceso,      @i_tipo_iden,
                                  @i_numero_iden,            @w_fecha_nac)
   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
if @@error <> 0 begin
   select @w_error = 1720577
   goto ERROR_FIN
end

select @o_coincidencia   = @i_numero_coincidencia,
       @o_id_transaccion = @i_transaccion_ref

if (@i_numero_coincidencia <> 0)
begin
   select @w_estado_resolucion = 'S' --Bloqueado
 
   exec @w_error = cobis..sp_liberacion_listas
       @s_ssn                  = @s_ssn,
       @s_sesn                 = @s_sesn,
       @s_user                 = @s_user,
       @s_term                 = @s_term,
       @s_date                 = @s_date,
       @s_srv                  = @s_srv,
       @s_lsrv                 = @s_lsrv,
       @s_ofi                  = @s_ofi,
       @s_rol                  = @s_rol,
       @s_org_err              = @s_org_err,
       @s_error                = @s_error,
       @s_sev                  = @s_sev,
       @s_msg                  = @s_msg,
       @s_org                  = @s_org,
       @s_culture              = @s_culture,
       @t_debug                = @t_debug,
       @t_file                 = @t_file,
       @t_from                 = @t_from,
       @t_trn                  = 172218,
       @t_show_version         = @t_show_version,
       @i_operacion            = 'I',
       @i_nombres              = @i_nombre,
       @i_apellidos            = @i_apellido,
       @i_ente                 = @i_ente,
       @i_tipo                 = @i_tipo,
       @i_id                   = @i_transaccion_ref,
       @i_numero_coincidencia  = @i_numero_coincidencia,
       @i_nro_proceso          = @i_nro_proceso,
       @i_aml                  = @i_aml,
       @i_justificacion        = @i_justificacion,
       @i_estado               = null --estado siempre null

   if @w_error <> 0
   begin
      return @w_error
   end
   
   if isnull(@i_nro_proceso,'') <> ''
   begin
      select @w_solicitud = io_codigo_alterno from cob_workflow..wf_inst_proceso where io_id_inst_proc = @i_nro_proceso
      select @w_producto = op_toperacion from cob_workflow..wf_inst_proceso, cob_cartera..ca_operacion where io_id_inst_proc = @i_nro_proceso and io_campo_3 = op_tramite
   end
   
    select @w_nombre_completo = case when @w_nombre_completo not like '%' + @i_apellido_casada + '%' then @w_nombre_completo + ' ' + isnull(@i_apellido_casada,'') --AGREGAR CUANDO NO ESTE
          else @w_nombre_completo --SI ESTA NO AGREGAR EL APELLIDO DE CASADA
          end,
   @w_xml = '<?xml version="1.0" encoding="UTF-8"?><data><nombreCliente>' + UPPER(@w_nombre_completo) + '</nombreCliente><codigoCliente>' + convert(varchar(10),@w_ente) + '</codigoCliente><solicitud>'+ UPPER(@w_solicitud) + '</solicitud><producto>' + @w_producto + '</producto><identificacion>' + (@w_identificacion) + '</identificacion><fechaNacimiento>' + @i_fecha_nacimiento + '</fechaNacimiento><coincidencia>' + convert(varchar(10),@i_numero_coincidencia) + '</coincidencia></data>'
   
   --envio de correo
   
   select @w_template = te_id from cobis..ns_template  where te_nombre  = 'CorreoListasNegras.xslt'
   
   --Se obtiene parametro para cargo de funcionario
     
   select @w_cargo = pa_smallint from cobis..cl_parametro where pa_nemonico = 'COFCUM'
   /* Ya no se envia correo por rol
   select @w_email_func = fu_correo_electronico + ';'+ @w_email_func from cobis..cl_funcionario where fu_cargo = @w_cargo and fu_correo_electronico is not null and fu_estado = 'V'
   */
   select @w_email_func = valor + ';'+ @w_email_func
   from cobis..cl_catalogo A, 
        cobis..cl_tabla B
   where B.codigo = A.tabla
     and B.tabla  = 'cr_correos_listas' 
     and A.estado = 'V'
     
   if isnull(@w_email_func,'') = '' or @w_email_func = '' begin
      select @w_error = 1720580
      goto ERROR_FIN
   end  

   exec cobis..sp_despacho_ins
   @i_cliente = @w_ente,
   @i_template= @w_template,
   @i_servicio = 1,
   @i_estado = 'P',
   @i_tipo = 'MAIL',
   @i_tipo_mensaje = 'I',
   @i_prioridad = 1,
   @i_from = null,
   @i_to = @w_email_func,
   @i_cc = '',
   @i_bcc = null,
   @i_subject = @w_subject,
   @i_body = @w_xml,
   @i_content_manager = 'HTML',
   @i_retry = 'S',
   @i_fecha_envio = null,
   @i_hora_ini = null,
   @i_hora_fin = null,
   @i_tries = 0,
   @i_max_tries = 2
   
   if @w_error <> 0
   begin
      return @w_error
   end
   
end
else
begin
   --Registro antes del cambio
   insert into ts_listas_negras (
   secuencial,              tipo_transaccion,               clase,
   fecha,                   usuario,                        terminal,
   srv,                     lsrv,                           ne_id_verificacion,
   ne_coincidencia,         ne_nombre,                      ne_apellido,
   ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
   ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
   ne_nro_aml)
   select
   @s_ssn,                  @t_trn,                         'A',
   getdate(),               @s_user,                        @s_term,
   @s_srv,                  @s_lsrv,                        @i_transaccion_ref ,
   ne_coincidencia,         ne_nombre,                      ne_apellido,
   ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
   ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
   ne_nro_aml
   from cl_listas_negras_rfe
   where ne_codigo_cliente = @i_ente
   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end
   
   if @s_culture != 'NEUTRAL'
   begin
   select @i_justificacion = re_valor                                                                                                                                                                           
         from   cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int                                                                                                                                                                                                                        
         and    re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where numero = 1720603 
   end
   else
   begin
   select top 1 @i_justificacion = mensaje                                                                                                                                                                           
         from   cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int)                                                                                                                                                                                                           
         where numero = 1720603
   end
   update cl_listas_negras_rfe set ne_justificacion     = @i_justificacion,
                                   ne_nombre            = @i_nombre,
                                   ne_apellido          = @i_apellido,                                 
                                   ne_coincidencia      = 0, 
                                   ne_estado_resolucion = 'N', 
                                   ne_fecha_resolucion  = getdate(),
                                   ne_id_verificacion   = @i_transaccion_ref 
   where ne_codigo_cliente = @i_ente
   
   update cl_ente set en_estado = 'N' 
   where en_ente = @i_ente
   
   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720578
      goto ERROR_FIN
   end
   
   --Registro despues del cambio
   insert into ts_listas_negras (
   secuencial,              tipo_transaccion,               clase,
   fecha,                   usuario,                        terminal,
   srv,                     lsrv,                           ne_id_verificacion,
   ne_coincidencia,         ne_nombre,                      ne_apellido,
   ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
   ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
   ne_nro_aml)
   select
   @s_ssn,                  @t_trn,                         'D',
   getdate(),               @s_user,                        @s_term,
   @s_srv,                  @s_lsrv,                        @i_transaccion_ref ,
   ne_coincidencia,         ne_nombre,                      ne_apellido,
   ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
   ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
   ne_nro_aml
   from cl_listas_negras_rfe
   where ne_codigo_cliente = @i_ente
   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end
   
end
return 0

ERROR_FIN:
exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_error
return @w_error

go
