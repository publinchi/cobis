/************************************************************************/
/*   Archivo:             batch_desercion.sp                            */
/*   Stored procedure:    batch_desercion                               */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Bruno Duenas                                  */
/*   Fecha de escritura:  24-Abril-2023                                 */
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
/*   Proceso batch donde se registran la desercion de clientes          */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 24/Abril/2023            BDU                Emision Inicial          */
/* 01/Junio/2023            BDU                Agregar campos reporte   */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'batch_desercion')
begin
   drop proc batch_desercion
end   
go

create procedure batch_desercion(
   @i_param1         datetime          null,
   @i_param2         datetime          null
)
as
declare @w_tiempo                   int,
        @w_sarta                    int,
        @w_batch                    int,
        @w_producto                 catalogo,
        @w_fecha_actual             datetime,
        @w_error                    int,
        @w_id                       int,
        @w_id_oficial               int,
        @w_nom_ofi                  varchar(250),
        @w_mensaje                  varchar(250),
        @w_retorno_ej               int,
        @w_termina                  bit,
        @w_path                     varchar(254),
        @w_nombre_grupo             descripcion,
        @w_grupo                    int,
        @w_severidad                catalogo,
        @w_causa                    catalogo,
        @w_sp_name                  varchar(100),
        @w_causa_desc               varchar(256),
        @w_criticidad_desc          varchar(256)
        
        
-- Información proceso batch

select @w_termina = 0

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_credito..batch_desercion%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
if @@rowcount = 0
begin
   select @w_termina = 1
   select @w_error  = 808071 
   goto ERROR
end

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente like '%cob_credito..batch_desercion%'
/*
select @w_sarta = 21000,
       @w_batch = 21008
*/
--Parametros
select @w_tiempo = isnull(pa_smallint, 1)
from cobis..cl_parametro
where pa_nemonico = 'DBCRDE'
and pa_producto   = 'CRE'

select @w_fecha_actual = getdate()
--Limpieza de los archivos que empicen con 'desercion_'
declare @w_path_del varchar(100)
set @w_path_del = 'del /Q ' + @w_path +'\desercion_*.*'
EXEC master.dbo.xp_cmdshell @w_path_del
--tabla temporal para almacenar las operaciones
if (OBJECT_ID('tempdb.dbo.#tmp_operacion','U')) is not null
begin
   drop table #tmp_operacion
end

create table #tmp_operacion (
   ente               int              null,
   nombre             descripcion      null,
   grupo              int              null,
   nombre_grupo       descripcion      null,
   ciclo              int              null,
   calificacion       catalogo         null,
   monto              money            null,
   fecha              date             null,
   operacion          cuenta           null,
   causa              descripcion      null,
   severidad          descripcion      null,
   oficial            int              null,
   oficina            int              null,
   nombre_ofi         varchar(300)     null,
   tipo_producto      varchar(10)      null
)
        
select @w_sp_name = 'cob_credito..batch_desercion'
insert into #tmp_operacion(ente, operacion, nombre, calificacion, ciclo,
                           monto, fecha, oficina,   oficial, nombre_ofi, tipo_producto)
SELECT en_ente, op_operacion, en_nomlar, en_calificacion, en_nro_ciclo,
       op_monto, dateadd(day, 1,op_fecha_fin), op_oficina, op_oficial, (select fu_nombre
                                                                        from cobis..cc_oficial, 
                                                                             cobis..cl_funcionario
                                                                        where oc_oficial = op_oficial
                                                                        and oc_funcionario = fu_funcionario), op_toperacion
from cobis.dbo.cl_ente en,
     cob_cartera.dbo.ca_operacion
where op_cliente = en_ente
and (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
and op_estado not in (99,0,6)
and (op_fecha_ini > @i_param2 or op_fecha_fin <  @i_param1 )
and op_fecha_fin between dateadd(day, @w_tiempo * -1, @i_param1) and  @i_param1
and op_operacion in (SELECT max(op_operacion) 
                     FROM cob_cartera.dbo.ca_operacion
                     where op_cliente = en.en_ente 
                     and (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
                     and op_estado not in (99,0,6)
                     and (op_fecha_ini > @i_param2 or op_fecha_fin <  @i_param1 )
                     and op_fecha_fin between dateadd(day, @w_tiempo * -1, @i_param1) and  @i_param1)
order by en.en_ente desc

select @w_id = min(ente) from #tmp_operacion
--Ingreso de información extra 
while @w_id is not null
begin
   --Limpiar valores por cada cliente
   select @w_causa = null,
          @w_severidad = null,
          @w_grupo = null,
          @w_nombre_grupo = null,
          @w_causa_desc = null,
          @w_criticidad_desc = null
   --Info del grupo
   select @w_grupo = gr_grupo, 
          @w_nombre_grupo = gr_nombre 
          from cobis.dbo.cl_cliente_grupo,
               cobis.dbo.cl_grupo
   where gr_grupo = cg_grupo 
   and cg_ente = @w_id
   
   --Info de desercion anterior (de existir)
   if exists(select 1 from cob_credito..cr_causa_desercion where cd_ente = @w_id)
   begin
      select @w_causa     = cd_causa,
             @w_severidad = cd_severidad
      from cob_credito..cr_causa_desercion 
      where cd_ente = @w_id
      and cd_fecha = (select max(cd_fecha)
                      from cob_credito..cr_causa_desercion 
                      where cd_ente = @w_id)
      --Chequeo de catalogo                    
      select @w_causa_desc = c.valor 
      from cobis..cl_catalogo c, 
           cobis..cl_tabla t 
      where c.tabla = t.codigo 
      and t.tabla = 'cr_causa_desercion'
      and c.estado = 'V'  
      and c.codigo = @w_causa
      
      select 'causa' = isnull(@w_causa_desc, 'vacio')
      
      
      select @w_criticidad_desc = c.valor  
      from cobis..cl_catalogo c, 
           cobis..cl_tabla t  
      where c.tabla = t.codigo 
      and t.tabla = 'cr_criticidad_desercion'
      and c.estado = 'V'  
      and c.codigo = @w_severidad
      
      select 'criticidad' = isnull(@w_criticidad_desc, 'vacio')
   end
   
   
   update #tmp_operacion
   set grupo = @w_grupo,
       nombre_grupo = @w_nombre_grupo,
       severidad    = @w_criticidad_desc,
       causa        = @w_causa_desc
   where ente = @w_id
   
   
   select @w_id = min(ente) from #tmp_operacion
   where ente > @w_id
end

--while para armar el archivo por oficina
select @w_id = min(oficina) from #tmp_operacion
--Ingreso de información extra 
while @w_id is not null
begin
   /* CREACION DE TABLA TEMPORAL CON REGISTROS DE INFORMACION DE LOS CLIENTES DE DESERCION*/
   if (OBJECT_ID('tempdb..##tmp_info')) is not null
   begin
      drop table ##tmp_info
   end
   
   create table ##tmp_info (
      oficial            varchar(100)     null,
      idGrupo            varchar(100)     null,
      nomGrupo           varchar(254)     null,
      idEnte             varchar(100)     null,
      nomEnte            varchar(254)     null,  
      calificacion       varchar(100)     null,  
      monto              varchar(100)     null,
      ciclo              varchar(100)     null,
      ultFech            varchar(100)     null,
      ultCrit            varchar(100)     null,
      ultCaus            varchar(100)     null,
      total_monto        varchar(100)     null,
      total_clientes     varchar(100)     null,
      nombre_ofi         varchar(300)     null,
      tipo_producto      varchar(10)      null,
      operacion          varchar(12)      null
   )
   --Insertar cabecera
   insert into ##tmp_info(oficial, nombre_ofi, idGrupo, nomGrupo, idEnte, nomEnte, calificacion, operacion, tipo_producto, monto, ciclo, ultFech, ultCrit, ultCaus, total_monto, total_clientes)
   select null, null, null, null, null, null, 'DESERCION CLIENTES', null, null, null, null, null, null, null, null, null
   insert into ##tmp_info(oficial, nombre_ofi, idGrupo, nomGrupo, idEnte, nomEnte, calificacion, operacion, tipo_producto, monto, ciclo, ultFech, ultCrit, ultCaus, total_monto, total_clientes)
   select null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
   insert into ##tmp_info(oficial, nombre_ofi, idGrupo, nomGrupo, idEnte, nomEnte, calificacion, operacion, tipo_producto, monto, ciclo, ultFech, ultCrit, ultCaus, total_monto, total_clientes)
   select 'Fecha:', convert(varchar, @w_fecha_actual, 103), null, null, null, 'Oficina:', (select of_nombre from cobis..cl_oficina where of_oficina = @w_id), null, null, null, null, null, null, null, null, null
   insert into ##tmp_info(oficial, nombre_ofi, idGrupo, nomGrupo, idEnte, nomEnte, calificacion, operacion, tipo_producto, monto, ciclo, ultFech, ultCrit, ultCaus, total_monto, total_clientes)
   select 'Rango Fechas:', convert(varchar, @i_param1, 103), ' hasta ', convert(varchar, @i_param2, 103), null, null, null, null, null, null, null, null, null, null, null, null
   insert into ##tmp_info(oficial, nombre_ofi, idGrupo, nomGrupo, idEnte, nomEnte, calificacion, operacion, tipo_producto, monto, ciclo, ultFech, ultCrit, ultCaus, total_monto, total_clientes)
   select null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
   insert into ##tmp_info(oficial, nombre_ofi, idGrupo, nomGrupo, idEnte, nomEnte, calificacion, operacion, tipo_producto, monto, ciclo, ultFech, ultCrit, ultCaus, total_monto, total_clientes)
   select 'OFICIAL', 'NOMBRE OFICIAL', 'ID GRUPO', 'NOMBRE GRUPO', 'ID CLIENTE', 'NOMBRE CLIENTE', 'CALIFICACION', 'OPERACION', 'PRODUCTO', 'MONTO', 'CICLO', 'ULTIMA FECHA DESERCION', 'ULTIMA CRITICIDAD DESERCION', 'ULTIMA CAUSA DESERCION',
       'TOTAL MONTOS', 'TOTAL CLIENTES'
   
   
   select @w_id_oficial = min(oficial) 
   from #tmp_operacion
   where oficina = @w_id
   
   select *
   from #tmp_operacion
   while @w_id_oficial is not null
   begin
      
      --Insercion de la DATA
      insert into ##tmp_info(oficial, idGrupo, nomGrupo, idEnte, nomEnte, calificacion, monto, ciclo, ultFech, ultCrit, ultCaus, total_monto, total_clientes, operacion, tipo_producto, nombre_ofi)
      select convert(varchar, @w_id_oficial), convert(varchar, grupo), nombre_grupo, convert(varchar, ente), nombre, calificacion, convert(varchar, monto), convert(varchar, ciclo), convert(varchar, fecha, 103),severidad, causa, NULL, NULL, convert(varchar, operacion), tipo_producto, nombre_ofi
      from #tmp_operacion
      where oficial = @w_id_oficial
      and oficina = @w_id
      order by grupo desc, ente desc
      
      --Insercion de la TOTALIZACION
      insert into ##tmp_info(oficial, idGrupo, nomGrupo, idEnte, nomEnte, calificacion, monto, ciclo, ultFech, ultCrit, ultCaus, total_monto, total_clientes, operacion, tipo_producto, nombre_ofi)
      select convert(varchar, @w_id_oficial), null, null, null, null, null, null, null, null,null, null, convert(varchar, sum(monto)), convert(varchar, count(*)), null, null, null
      from #tmp_operacion
      where oficial = @w_id_oficial
      and oficina = @w_id
      --Siguiente oficial
      select @w_id_oficial = min(oficial) 
      from #tmp_operacion
      where oficina = @w_id
      and oficial > @w_id_oficial
   end
   
   
   --csv
   DECLARE @csv_file_path NVARCHAR(MAX) = @w_path + '\desercion_' + convert(varchar, @w_id)+'.csv' 
   
   declare @w_return int,
           @w_separador char(1)
   set @w_separador = ';'
   
   
   
   DECLARE @query NVARCHAR(MAX) = 'select oficial, nombre_ofi, idGrupo, nomGrupo, idEnte, nomEnte, calificacion, operacion, tipo_producto, monto, ciclo, ultFech, ultCrit, ultCaus, total_monto, total_clientes  from ##tmp_info' --Datos
   -- Export query result to CSV file using BCP 
   DECLARE @bcp_command NVARCHAR(MAX) = 'bcp "' + @query + '" queryout "' + @csv_file_path + '" -c -t, -T -S ' 
   
   
   exec @w_return          = cobis..sp_bcp_archivos
        @i_sql             = @query,           --select o nombre de tabla para generar archivo plano
        @i_tipo_bcp        = 'queryout',             --tipo de bcp in,out,queryout
        @i_rut_nom_arch    = @csv_file_path,   --ruta y nombre de archivo
        @i_separador       = @w_separador      --separador
   NEXT_LINE:
   --Obtener siguiente oficina
   select @w_id = min(oficina) from #tmp_operacion
   where oficina > @w_id
end


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
   if @w_termina = 0
   begin
      goto NEXT_LINE
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
