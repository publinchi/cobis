/************************************************************************/
/*   Archivo:             concesion_cred_auto_correo.sp                 */
/*   Stored procedure:    concesion_cred_auto_correo                    */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Dilan Morales                                 */
/*   Fecha de escritura:  11-Septiembre-2023                            */
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
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                     PROPOSITO                                        */
/*   Se envia correos a los oficiales                                   */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 11/Septiembre/2023       DMO               Emision Inicial           */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'concesion_cred_auto_correo')
begin
   drop proc concesion_cred_auto_correo
end   
go

create procedure concesion_cred_auto_correo
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_fecha_actual             date,
        @w_error                    int,    
        @w_id_oficial               int,
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_correo_oficial           varchar(200),
        @w_correo_jefe              varchar(200),
        @w_path                     varchar(254),
        @w_nom_ofi                  varchar (254)
        
-- Informacion proceso batch
print 'INICIO PROCESO concesion_cred_auto_correo: '  + convert(varchar, getdate(),120)
select @w_termina = 0
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..concesion_cred_auto_correo%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end

select @w_fecha_actual = getdate()

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente like '%cob_credito..concesion_cred_auto_correo%'

--Limpieza de la carpeta
declare @w_path_del varchar(100)
set @w_path_del = 'del /Q ' + @w_path +'\clientes_*.*'
EXEC master.dbo.xp_cmdshell @w_path_del


create table #tmp_clients (
   idCliente       int   null,
   idOficial       int   null,
)

create nonclustered index ix_idcliente
on #tmp_clients (idCliente)

create nonclustered index ix_idoficial
on #tmp_clients (idOficial)


insert into #tmp_clients
select cc_ente, cc_oficial
from cr_clientes_credautomatico
where convert(date, cc_fecha) = convert(date, @w_fecha_actual)


--while para los oficiales
print 'INICIO GENEREACION DE INFORMES Y ENVIO DE CORREOS: '  + convert(varchar, getdate(),120)
select @w_id_oficial = min(idOficial) from #tmp_clients
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
   from  cobis..cc_oficial 
   where oc_oficial = @w_id_oficial)
   
   /* CREACION DE TABLA TEMPORAL CON REGISTROS DE INFORMACION DEL CLIENTE*/
   if (OBJECT_ID('tempdb..##tmp_info')) is not null
   begin
      drop table ##tmp_info
   end
   
   create table ##tmp_info (
      codigo       varchar(254)   null,
      nombre       varchar(254)   null,
      celular      varchar(16)    null,
      telefono     varchar(16)    null,  
      correo       varchar(254)   null,  
      direccion    varchar(254)   null  
   )
   
   
   insert into ##tmp_info(codigo,nombre,celular,telefono,correo, direccion)
   select 'Fecha:', convert(varchar, getdate(), 103), null, null, 'Oficial:', @w_nom_ofi
   insert into ##tmp_info(codigo,nombre,celular,telefono,correo, direccion)
   select 'LISTADO DE CLIENTES PARA CONCESION DE CREDITOS AUTOMATICOS', null, null, null, null, null
   insert into ##tmp_info(codigo,nombre,celular,telefono,correo, direccion)
   select 'CODIGO', 'NOMBRE', 'TELEFONO CELULAR', 'TELEFONO FIJO', 'CORREO ELECTRONICO', 'DIRECCION'
   
   insert into ##tmp_info(codigo,nombre,celular,telefono,correo, direccion)
    select convert(varchar,en_ente),
          (isnull(en_nombre + ' ','') + isnull(p_s_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','') + isnull(p_c_apellido,'')),
          (case                 
              when (select top 1 ea_telef_recados from cobis..cl_ente_aux  where ea_ente = en_ente) is not null                      and (select top 1  ea_telef_recados from cobis..cl_ente_aux  where ea_ente = en_ente) <> ''
              then (select top 1  ea_telef_recados from cobis..cl_ente_aux  where ea_ente = en_ente)
              when (select top 1 di_direccion from cobis..cl_direccion where di_principal = 'S' and di_ente = en_ente) is not null                 then (select top 1  te_valor from cobis..cl_direccion , cobis..cl_telefono where te_ente = di_ente  and di_ente = en_ente and te_tipo_telefono = 'C' and  di_principal = 'S')
              else (select top 1 te_valor from  cobis..cl_telefono where te_ente = en_ente and te_tipo_telefono = 'C')                 end),
          (case                 when (select top 1 di_direccion from cobis..cl_direccion where di_principal = 'S' and di_ente = en_ente) is not null                 then (select top 1  te_valor from cobis..cl_direccion , cobis..cl_telefono where te_ente = di_ente  and di_ente = en_ente and te_tipo_telefono = 'D' and  di_principal = 'S')
              else (select top 1 te_valor from  cobis..cl_telefono where te_ente = en_ente and te_tipo_telefono = 'D')                end),
          (select top 1 di_descripcion from cobis..cl_direccion where di_tipo = 'CE' and di_ente = en_ente),
          (case                 when (select top 1 di_direccion from cobis..cl_direccion where di_principal = 'S' and di_ente = en_ente) is not null                 then (select top 1 di_descripcion from cobis..cl_direccion , cobis..cl_telefono where te_ente = di_ente  and di_ente = en_ente and te_tipo_telefono = 'D' and  di_principal = 'S')
              when (select top 1 di_descripcion  from cobis..cl_direccion where di_tipo = 'RE' and di_ente = en_ente) is not null
              then (select top 1 di_descripcion  from cobis..cl_direccion where di_tipo = 'RE' and di_ente = en_ente)
              else  (select top 1 di_descripcion  from cobis..cl_direccion where di_tipo = 'AE' and di_ente = en_ente)
              end)
          from cobis..cl_ente  where en_ente in (select idCliente from #tmp_clients where idOficial = @w_id_oficial)
   
   --csv
   DECLARE @csv_file_path NVARCHAR(MAX) = @w_path + '\clientes_' + convert(varchar, @w_id_oficial)+'.csv' 
   
   declare @w_file varchar (254)= 'clientes_' + convert(varchar, @w_id_oficial)+'.csv' 
   declare @w_return int,
           @w_separador char(1)
   set @w_separador = ';'
   
   
   
   DECLARE @query NVARCHAR(MAX) = 'select codigo,nombre,celular,telefono,correo, direccion from ##tmp_info' --Datos
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
                @i_subject          = 'LISTADO DE CLIENTES PARA CONCESIÓN DE CREDITOS AUTOMATICOS',
                @i_body             = '',
                @i_content_manager  = 'TEXT',
                @i_retry            = 'S',
                @i_tries            = 0,
                @i_max_tries        = 3,
                @i_var1             = @w_file
   --Nuevo registro
   select @w_id_oficial = min(idOficial) from tempdb.dbo.#tmp_clients
   where idOficial > @w_id_oficial
end
print 'FIN PROCESO concesion_cred_auto_correo: '  + convert(varchar, getdate(),120)

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
