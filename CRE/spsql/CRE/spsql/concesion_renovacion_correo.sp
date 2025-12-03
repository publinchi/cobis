/********************************************************************/
/*   NOMBRE LOGICO:         concesion_renovacion_correo             */
/*   NOMBRE FISICO:         concesion_renovacion_correo.sp          */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          D. Morales.                             */
/*   FECHA DE ESCRITURA:    03-Mar-2023                             */
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
/*   Se registran los clientes que aplican a una renovacion en sus  */
/*   creditos.                                                      */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   03-Mar-2023        D. Morales.        Emision Inicial          */
/*   23-Mar-2023        D. Morales.        Se añade correo de jefe  */
/*   24-Abr-2023        P. Jarrin.         S809618- SMS Proceso Ren.*/
/*   03-May-2023        D. Morales.        Eliminacion de registros */
/*                                         ingresados el mismo dia  */
/*   23-May-2023        D. Morales.        Se añade nuevos campos   */
/*                                         fecha_ven, saldo_capital */
/*   24-Oct-2023        B. Duenas.         Se agrega rango de horas */
/*                                         para envio de SMS        */
/*   25-Oct-2023        B. Duenas.         Se agrega fecha actual   */
/*   27-Oct-2023        B. Duenas.         Se valida numero de tlfn */
/********************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'concesion_renovacion_correo')
begin
   drop proc concesion_renovacion_correo
end   
go

create procedure concesion_renovacion_correo
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_fecha_actual             date,
        @w_error                    int,    
        @w_variables                varchar(64),
        @w_return_variable          varchar(25),
        @w_return_results           varchar(25),
        @w_last_condition_parent    varchar(10),
        @w_return_results_rule      varchar(25),
        @w_id                       int,
        @w_id_cliente               int,
        @w_tramite                  int,
        @w_num_operacion            int,
        @w_num_op_banco             varchar(24),
        @w_toperacion               varchar(10),
        @w_grupo                    int,
        @w_nombre_grupo             varchar(254),
        @w_ref_op_padre             varchar(24),
        @w_id_oficial               int,
        @w_promedio_mora            int,
        @w_porcentaje_pag           int,
        @w_monto_total              money,
        @w_capital_pag              money,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_correo_oficial           varchar(200),
        @w_correo_jefe              varchar(200),
        @w_path                     varchar(254),
        @w_nom_ofi                  varchar(254),
        @w_ente                     int,    
        @w_tope                     varchar(10),
        @w_texto_msg                varchar(500),
        @w_desctope                 varchar(64),
        @w_telefono                 varchar(64),
        @w_fecha_ven                date,
        @w_saldo_capital            money,
        --Variables para determinar rango de envio SMS
        @w_day                      datetime,
        @w_start_hour               datetime,
        @w_end_hour                 datetime
        
-- Información proceso batch

select @w_termina      = 0,
       @w_ente         = 0,
       @w_tope         = '',
       @w_texto_msg    = '',
       @w_desctope     = '',
       @w_telefono     = ''


select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..concesion_renovacion_correo'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end

/*
select @w_sarta = 21000,
       @w_batch = 21014
*/
if (OBJECT_ID('tempdb.dbo.#tmp_oficiales','U')) is not null
begin
    drop table #tmp_oficiales
end

create table #tmp_oficiales (
id_oficial      int         null
)
create nonclustered index idx_id_oficial
on #tmp_oficiales (id_oficial)

insert into #tmp_oficiales
(id_oficial)
select distinct
cr_oficial
from cr_clientes_renovacion
--Variables fecha
select @w_day = dateadd(day, 1, getdate())
SELECT @w_start_hour = DATEADD(hh, 8, DATEADD(dd, DATEDIFF(dd, 0, @w_day), 0)), --08:00
       @w_end_hour   = DATEADD(hh, 18, DATEADD(dd, DATEDIFF(dd, 0, @w_day), 0)) --18:00
--Path carpeta
select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente like '%cob_credito..concesion_renovacion_correo%'

--Limpieza de la carpeta
declare @w_path_del varchar(100)
set @w_path_del = 'del /Q ' + @w_path +'\clientes_renova_*.*'
EXEC master.dbo.xp_cmdshell @w_path_del

--ENVIO DE CORREO A OFICIALES
select @w_id_oficial = min(id_oficial) 
from tempdb.dbo.#tmp_oficiales
while @w_id_oficial is not NULL
begin
    select @w_correo_oficial = null,    
           @w_nom_ofi        = null,
           @w_correo_jefe    = null
           
           
   select @w_correo_oficial = fu_correo_electronico,
          @w_nom_ofi        = fu_nombre
   from cobis..cl_funcionario, cobis..cc_oficial 
   where fu_funcionario = oc_funcionario 
   and oc_oficial = @w_id_oficial
   
   select @w_correo_jefe = fu_correo_electronico
   from cobis..cl_funcionario
   inner join cobis..cc_oficial on fu_funcionario = oc_funcionario 
   where  oc_oficial in (select oc_ofi_nsuperior 
   from   cobis..cc_oficial 
   where oc_oficial = @w_id_oficial)
   
   /* CREACION DE TABLA TEMPORAL CON REGISTROS DE INFORMACION DEL CLIENTE*/
   if (OBJECT_ID('tempdb..##tmp_info_renova')) is not null
   begin
      drop table ##tmp_info_renova
   end
   
   create table ##tmp_info_renova (
      codigo        varchar(254)   null,
      nombre        varchar(254)   null,
      num_operacion varchar(254)   null,
      num_grupo     varchar(254)   null,
      nom_grupo     varchar(254)   null,
      tipo_producto varchar(254)   null,
      saldo_cap     varchar(254)   null,
      fecha_ven     varchar(254)   null,
      celular       varchar(254)   null,
      telefono      varchar(254)   null,  
      correo        varchar(254)   null,  
      direccion     varchar(254)   null
   )
   
   
   insert into ##tmp_info_renova
   (codigo,     nombre,                             num_operacion,  num_grupo,  nom_grupo,  tipo_producto,  saldo_cap,  fecha_ven,      celular,    telefono,   correo,     direccion)
   select 
   'Fecha:',    convert(varchar, getdate(), 103),   null,           null,       null,       null,           null,        null,          null,       null,       'Oficial:', @w_nom_ofi
   
   insert into ##tmp_info_renova
   (codigo,         
   nombre,  num_operacion,  num_grupo,  nom_grupo,  tipo_producto,  saldo_cap,  fecha_ven,    celular,    telefono,   correo,     direccion)
   select 
   'LISTADO DE CLIENTES PARA RENOVACIÓN DE SUS CREDITOS', 
   null,    null,            null,       null,          null,       null,       null,         null,       null,       null,       null
  
  insert into ##tmp_info_renova
   (codigo,     nombre,     num_operacion,      num_grupo,      nom_grupo,          tipo_producto,  
   saldo_cap,           fecha_ven,              celular,            telefono,       correo,                 direccion)
   select 
   'CODIGO',    'NOMBRE',   'NRO OPERACION',    'CODIGO GRUPO', 'NOMBRE DEL GRUPO', 'TIPO DE PRODUCTO',
   'SALDO DE CAPITAL',  'FECHA DE VENCIMIENTO', 'TELEFONO CELULAR', 'TELEFONO FIJO', 'CORREO ELECTRONICO',   'DIRECCION'
   
   insert into ##tmp_info_renova
   (codigo, 
   nombre, 
   num_operacion,
   num_grupo,
   nom_grupo,
   tipo_producto,
   saldo_cap,
   fecha_ven,
   celular,
   telefono,
   correo, 
   direccion)
   select
          convert(varchar,cr_ente), --CODIGO
          (isnull(en_nombre + ' ','') + isnull(p_s_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','') + isnull(p_c_apellido,'')),--NOMBRE
          cr_num_banco, --NRO OPERACION
          (case  when cr_grupo > 0 then convert(varchar,cr_grupo) else '' end), --CODIGO GRUPO
          cr_nombre_grupo,
          cr_toperacion, --'TIPO DE PRODUCTO
          cr_saldo_capital,
          cr_fecha_venc,
          (case                 
              when (select top 1 ea_telef_recados from cobis..cl_ente_aux  where ea_ente = cr_ente) is not null                      and (select top 1  ea_telef_recados from cobis..cl_ente_aux  where ea_ente = cr_ente) <> ''
              then (select top 1  ea_telef_recados from cobis..cl_ente_aux  where ea_ente = cr_ente)
              when (select top 1 di_direccion from cobis..cl_direccion where di_principal = 'S' and di_ente = cr_ente) is not null                 
              then (select top 1  te_valor from cobis..cl_direccion , cobis..cl_telefono where te_ente = di_ente  and di_ente = cr_ente and te_tipo_telefono = 'C' and  di_principal = 'S')
              else (select top 1 te_valor from  cobis..cl_telefono where te_ente = cr_ente and te_tipo_telefono = 'C') 
          end),--CELULAR
          (case                 
              when (select top 1 di_direccion from cobis..cl_direccion where di_principal = 'S' and di_ente = cr_ente) is not null                 
              then (select top 1  te_valor from cobis..cl_direccion , cobis..cl_telefono where te_ente = di_ente  and di_ente = cr_ente and te_tipo_telefono = 'D' and  di_principal = 'S')
              else (select top 1 te_valor from  cobis..cl_telefono where te_ente = cr_ente and te_tipo_telefono = 'D')                
          end),--TELEFONO
          (select top 1 di_descripcion from cobis..cl_direccion where di_tipo = 'CE' and di_ente = cr_ente),
          (case                 
              when (select top 1 di_direccion from cobis..cl_direccion where di_principal = 'S' and di_ente = cr_ente) is not null                 
              then (select top 1 di_descripcion from cobis..cl_direccion , cobis..cl_telefono where te_ente = di_ente  and di_ente = cr_ente and te_tipo_telefono = 'D' and  di_principal = 'S')
              when (select top 1 di_descripcion  from cobis..cl_direccion where di_tipo = 'RE' and di_ente = cr_ente) is not null
              then (select top 1 di_descripcion  from cobis..cl_direccion where di_tipo = 'RE' and di_ente = cr_ente)
              else  (select top 1 di_descripcion  from cobis..cl_direccion where di_tipo = 'AE' and di_ente = cr_ente)
              end)--DIRECCION
          from cr_clientes_renovacion inner join  cobis..cl_ente on en_ente = cr_ente 
          where cr_oficial = @w_id_oficial
   
   --csv
   DECLARE @csv_file_path NVARCHAR(MAX) = @w_path + '\clientes_renova_' + convert(varchar, @w_id_oficial)+'.csv' 
   
   declare @w_file varchar (254)= 'clientes_renova_' + convert(varchar, @w_id_oficial)+'.csv' 
   declare @w_return int,
           @w_separador char(1)
   set @w_separador = ';'
   
   
   
   DECLARE @query NVARCHAR(MAX) = 'select codigo,nombre,num_operacion,num_grupo,nom_grupo,tipo_producto,saldo_cap,fecha_ven,celular,telefono,correo,direccion from ##tmp_info_renova' --Datos
   -- Export query result to CSV file using BCP 
   DECLARE @bcp_command NVARCHAR(MAX) = 'bcp "' + @query + '" queryout "' + @csv_file_path + '" -c -t, -T -S ' 
   
   
   exec @w_return          = cobis..sp_bcp_archivos
        @i_sql             = @query,           --select o nombre de tabla para generar archivo plano
        @i_tipo_bcp        = 'queryout',             --tipo de bcp in,out,queryout
        @i_rut_nom_arch    = @csv_file_path,   --ruta y nombre de archivo
        @i_separador       = @w_separador      --separador
        
    
   --envio de correo
   exec cobis..sp_despacho_ins
                @i_cliente          = 1,
                @i_servicio         = 1,
                @i_template         = 0, --@w_template,
                @i_estado           = 'P',
                @i_tipo             = 'MAIL',
                @i_tipo_mensaje     = 'I',
                @i_prioridad        = 1,
                @i_from             = null,
                @i_to               = @w_correo_oficial, -- correo del cliente
                @i_cc               = @w_correo_jefe,
                @i_bcc              = '',
                @i_subject          = 'LISTADO DE CLIENTES PARA RENOVACIÓN DE SUS CREDITOS',
                @i_body             = '',
                @i_content_manager  = 'TEXT',
                @i_retry            = 'S',
                @i_tries            = 0,
                @i_max_tries        = 3,
                @i_var1             = @w_file
   --Nuevo registro
   select @w_id_oficial = min(id_oficial) from tempdb.dbo.#tmp_oficiales
   where id_oficial > @w_id_oficial
end
--Generar csv
select @w_fecha_actual = getdate()
--ENVIO SMS por Proceso Renovacion
declare cur_ente_renov cursor
    for select cr_ente, cr_toperacion
         from cob_credito..cr_clientes_renovacion 
        where cr_fecha = convert(date, @w_fecha_actual)
        order by cr_ente
open cur_ente_renov     
fetch next from cur_ente_renov into @w_ente, @w_tope
    
while @@fetch_status = 0
begin  
    select @w_desctope  = (select isnull(trim(valor),'') from cobis..cl_catalogo c, cobis..cl_tabla t where c.tabla = t.codigo and t.tabla = 'ca_toperacion' and c.codigo = trim(@w_tope)),
           @w_telefono  = (case                 
                              when (select top 1 ea_telef_recados from cobis..cl_ente_aux  where ea_ente = @w_ente) is not null and (select top 1  ea_telef_recados from cobis..cl_ente_aux  where ea_ente = @w_ente) <> ''
                              then (select top 1 ea_telef_recados from cobis..cl_ente_aux  where ea_ente = @w_ente)
                              when (select top 1 di_direccion from cobis..cl_direccion where di_principal = 'S' and di_ente = @w_ente) is not null                 
                              then (select top 1 te_valor from cobis..cl_direccion , cobis..cl_telefono where te_ente = di_ente  and di_ente = @w_ente and te_tipo_telefono = 'C' and  di_principal = 'S')
                              else (select top 1 te_valor from  cobis..cl_telefono where te_ente = @w_ente and te_tipo_telefono = 'C') 
                          end),
           @w_texto_msg = 'Estimado(a) cliente, ya puede renovar su crédito: "' + @w_desctope + '" de Enlace (restricciones aplican). Contacte a su asesor(a) para mayor información.'
    
    select @w_telefono = trim(@w_telefono)
    
    if @w_telefono is not null and @w_telefono != ''
    begin
       exec cobis..sp_despacho_ins
           @i_cliente         = @w_ente,
           @i_template        = null,
           @i_servicio        = 1,
           @i_estado          = 'P',
           @i_tipo            = 'SMS',
           @i_tipo_mensaje    = 'I',
           @i_prioridad       = 1,
           @i_from            = null,
           @i_to              = @w_telefono,
           @i_cc              = null,
           @i_bcc             = null,
           @i_subject         = 'NOTIFICACION DE RENOVACION CREDITO',
           @i_body            = @w_texto_msg,
           @i_content_manager = 'TEXT',
           @i_retry           = 'S',
           @i_fecha_envio     = @w_day,
           @i_hora_ini        = @w_start_hour,
           @i_hora_fin        = @w_end_hour,
           @i_tries           = 0,
           @i_max_tries       = 2      
    end   
    select @w_texto_msg = ''
    fetch next from cur_ente_renov into @w_ente, @w_tope    
end
close cur_ente_renov
deallocate  cur_ente_renov

select @w_termina = 1
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
         @i_sarta   = @w_sarta,
         @i_batch   = @w_batch,
         @i_error   = @w_error,
         @i_detalle = @w_mensaje
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
