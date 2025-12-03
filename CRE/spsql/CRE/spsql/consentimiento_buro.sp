/********************************************************************/
/*   NOMBRE LOGICO:         consentimiento_buro                     */
/*   NOMBRE FISICO:         consentimiento_buro.sp                  */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          P. Jarrin.                              */
/*   FECHA DE ESCRITURA:    09-May-2023                             */
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
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Enviar reporte consentimiento buró de crédito.                 */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR           RAZON                       */
/*   09-May-2023        P. Jarrin.      Emision Inicial - S784544   */
/*   01-Jun-2023        P. Jarrin.      Ajustes Review  - S834613   */
/*   03-Jul-2023        P. Jarrin.      Actualiza tabla tmp -S834613*/
/*   30-Nov-2023        D. Morales.     R220552: Se elimina solo    */
/*                                      archivo actual              */
/********************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'consentimiento_buro')
begin
   drop proc consentimiento_buro
end   
go

create procedure consentimiento_buro (
        @i_param1         datetime    null
)
as
declare @w_tiempo         int,
        @w_sarta          int,
        @w_batch          int,
        @w_error          int,
        @w_mensaje        varchar(250),
        @w_retorno_ej     int,
        @w_path           varchar(254),
        @w_correo         varchar(200),
        @w_subject        varchar(200),
        @w_body           varchar(200),
		@w_path_del       varchar(100)
		
        
-- Informacion Proceso Batch
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
  from cobis..ba_log,
       cobis..ba_batch
 where ba_arch_fuente ='cob_credito..consentimiento_buro'
   and lo_batch   = ba_batch
   and lo_estatus = 'E'
   
if @@rowcount = 0
begin
   select @w_error  = 808071 
   goto ERROR
end

select @w_path = ba_path_destino
 from cobis..ba_batch
where ba_arch_fuente = 'cob_credito..consentimiento_buro'

--Parametro General
select @w_correo = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'CPERCB'
  and pa_producto = 'CRE'

if @@rowcount = 0 
begin
   select @w_error  = 2110243 
   goto ERROR
end

declare @csv_file_path nvarchar(max) = @w_path + '\consentimiento_buro_' +  convert(varchar, @i_param1, 105)  + '.csv' 
declare @w_file varchar (254)= 'consentimiento_buro_' + convert(varchar, @i_param1, 105) + '.csv' 

--Limpieza de la carpeta
select  @w_path_del = 'del /Q ' + @csv_file_path
EXEC master.dbo.xp_cmdshell @w_path_del

if (OBJECT_ID('tempdb.dbo.#tmp_consentimiento','U')) is not null
begin
   drop table #tmp_consentimiento
end

create table #tmp_consentimiento (
   num_op_banco     varchar(24)  null,
   id_cliente       int          null,
   nombre_cliente   varchar(254) null,
   doc_principal    varchar(30)  null,
   doc_tributario   varchar(30)  null,
   doc_otro         varchar(30)  null,
   telefono         varchar(64)  null,
   correo           varchar(200) null,
   fecha_cons       datetime     null
)

insert into #tmp_consentimiento (num_op_banco, id_cliente, nombre_cliente, doc_principal, doc_tributario, doc_otro, telefono, correo, fecha_cons) 
select 
    (case  when op_banco =  convert(varchar, op_operacion) then '' else op_banco end), 
    en_ente, 
    ltrim(rtrim(en_nomlar)),
    (case when en_tipo_ced = 'DUI' then en_ced_ruc else '' end),    
    en_nit, 
    (case when en_tipo_ced = 'DUI' then '' else en_ced_ruc end), 
    (case
          when (ea_telef_recados) is not null and (ea_telef_recados) <> ''
          then (ea_telef_recados)
          when (select top 1 di_direccion from cobis..cl_direccion where di_principal = 'S' and di_ente = en_ente) is not null                 
          then (select top 1 te_valor from cobis..cl_direccion , cobis..cl_telefono where te_ente = di_ente  and di_ente = en_ente and te_tipo_telefono = 'C' and  di_principal = 'S')
          else (select top 1 te_valor from  cobis..cl_telefono where te_ente = en_ente and te_tipo_telefono = 'C') 
     end),
     (select top 1 di_descripcion from cobis..cl_direccion where di_tipo = 'CE' and di_ente = en_ente),
     op_fecha_ini
from cobis..cl_ente en, cobis..cl_ente_aux, cob_cartera..ca_operacion with (NOLOCK)
where en_ente      = ea_ente
  and en_ente      = op_cliente
  and op_cliente   = ea_ente
  and op_estado not in (0, 99, 3, 6) --No vigente, vencido, cancelado, anulado
  and (op_grupal   = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
  and ea_persona_recados = 'S'
  and convert(date, op_fecha_ini) = convert(date,@i_param1)
order by en_ente asc

if @@error <> 0 
begin
   select @w_error = 171161
   goto ERROR
end


if (OBJECT_ID('tempdb..##tmp_info_consentimiento')) is not null
begin
  drop table ##tmp_info_consentimiento
end

create table ##tmp_info_consentimiento (
  num_op_banco        varchar(254)   null,
  nombre_cliente      varchar(254)   null,
  doc_principal       varchar(254)   null,
  doc_tributario      varchar(254)   null,
  doc_otro            varchar(254)   null,
  telefono            varchar(254)   null,
  correo              varchar(254)   null,
  fecha_cons          varchar(254)   null
)

insert into ##tmp_info_consentimiento (num_op_banco, nombre_cliente, doc_principal, doc_tributario, doc_otro, telefono, correo, fecha_cons) 
select null, 'LISTADO CLIENTES ENLACE QUE DIERON CONSENTIMIENTO DE RECIBIR NOTIFICACIONES', null, null, null, null, null, null
if @@error <> 0 
begin
   select @w_error = 171161
   goto ERROR
end

insert into ##tmp_info_consentimiento (num_op_banco, nombre_cliente, doc_principal, doc_tributario, doc_otro, telefono, correo, fecha_cons) 
select null, null, null, null, null, null, null, null
if @@error <> 0 
begin
   select @w_error = 171161
   goto ERROR
end

--Insertar cabecera
insert into ##tmp_info_consentimiento (num_op_banco, nombre_cliente, doc_principal, doc_tributario, doc_otro, telefono, correo, fecha_cons) 
select 'REFERENCIA CREDITO', 'NOMBRE', 'DUI', 'NIT', 'OTRO DOCUMENTO', 'TELEFONO', 'CORREO ELECTRONICO', 'FECHA CONSENTIMIENTO'
if @@error <> 0 
begin
   select @w_error = 171161
   goto ERROR
end

--Insertar detalle
insert into ##tmp_info_consentimiento (num_op_banco, nombre_cliente, doc_principal, doc_tributario, doc_otro, telefono, correo, fecha_cons)
select num_op_banco, nombre_cliente, doc_principal, doc_tributario, doc_otro, telefono, correo, convert(varchar, fecha_cons, 103) 
  from #tmp_consentimiento order by id_cliente asc
if @@error <> 0 
begin
   select @w_error = 171161
   goto ERROR
end

--csv
declare @w_return int,
        @w_separador char(1)
        
select  @w_separador = ';'

 --Datos
declare @query nvarchar(max) = 'select num_op_banco,nombre_cliente,doc_principal,doc_tributario,doc_otro,telefono,correo,fecha_cons from ##tmp_info_consentimiento'

-- Export query result to CSV file using BCP 
declare @bcp_command nvarchar(max) = 'bcp "' + @query + '" queryout "' + @csv_file_path + '" -c -t, -T -S ' 


exec @w_return          = cobis..sp_bcp_archivos
     @i_sql             = @query,                 --select o nombre de tabla para generar archivo plano
     @i_tipo_bcp        = 'queryout',             --tipo de bcp in,out,queryout
     @i_rut_nom_arch    = @csv_file_path,         --ruta y nombre de archivo
     @i_separador       = @w_separador            --separador
    
--envio de correo
select @w_subject  = 'LISTADO CLIENTES ENLACE QUE DIERON CONSENTIMIENTO DE RECIBIR NOTIFICACIONES'
select @w_body     = 'Buenos días.' + char(13) + char(13) 
select @w_body     = @w_body + 'Se adjunta el detalle de autorizaciones y consentimientos correspondiente al cierre del día de hoy.' + char(13) 
select @w_body     = @w_body + 'Cualquier observación estamos a la orden.' + char(13) + char(13) 
select @w_body     = @w_body + 'Saludos.' + char(13) + char(13) 

exec @w_error =  cobis..sp_despacho_ins
            @i_cliente          = 1,
            @i_servicio         = 1,
            @i_template         = 0, --@w_template,
            @i_estado           = 'P',
            @i_tipo             = 'MAIL',
            @i_tipo_mensaje     = 'I',
            @i_prioridad        = 1,
            @i_from             = null,
            @i_to               = @w_correo,
            @i_cc               = '',
            @i_bcc              = '',
            @i_subject          = @w_subject,
            @i_body             = @w_body,
            @i_content_manager  = 'TEXT',
            @i_retry            = 'S',
            @i_tries            = 0,
            @i_max_tries        = 3,
            @i_var1             = @w_file
			
if @w_error <> 0
begin
   goto ERROR
end			
return 0

ERROR:
   if @w_mensaje is null
   begin
      select @w_mensaje = mensaje
        from cobis..cl_errores 
       where numero = @w_error
   end
   
   if(@w_sarta is not null or @w_batch is not null)
   begin
      exec @w_retorno_ej = cobis..sp_ba_error_log
           @i_sarta      = @w_sarta,
           @i_batch      = @w_batch,
           @i_error      = @w_error,
           @i_detalle    = @w_mensaje
   end
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end
go
