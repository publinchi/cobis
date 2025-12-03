/********************************************************************/
/*   NOMBRE LOGICO:         sp_reporte_riesgo_y_mora                */
/*   NOMBRE FISICO:         reriesmo.sp                             */
/*   BASE DE DATOS:         cob_cartera                             */
/*   PRODUCTO:              Cartera                                 */
/*   DISENADO POR:          P. Jarrin                               */
/*   FECHA DE ESCRITURA:    05-Jul-2023                             */
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
/*   Proceso que genera el reporte con información de Riesgo y Mora */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   05-Jul-2023        P. Jarrin.         Emision Inicial - S857681*/
/********************************************************************/

use cob_cartera
go

if exists (select 1 
           from sysobjects 
           where name = 'sp_reporte_riesgo_y_mora')
begin
   drop proc sp_reporte_riesgo_y_mora
end   
go

create procedure sp_reporte_riesgo_y_mora
as
declare @w_error            int,
        @w_sarta            int,
        @w_batch            int,
        @w_mensaje          varchar(255),
        @w_retorno_ej       int,
        @w_path             varchar(255),
        @w_fecha_proceso    datetime

-- Informacion Proceso Batch
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
  from cobis..ba_log,
       cobis..ba_batch
where ba_arch_fuente ='cob_cartera..sp_reporte_riesgo_y_mora'
   and lo_batch   = ba_batch
   and lo_estatus = 'E'

if @@rowcount = 0
begin
   select @w_error  = 808071 
   goto ERROR
end

select @w_path = ba_path_destino
 from cobis..ba_batch
where ba_arch_fuente = 'cob_cartera..sp_reporte_riesgo_y_mora'

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

exec @w_error = cob_cartera..sp_vencimientos
     @i_operacion = 'R', --Riesgo y mora
     @i_en_linea  = 'S',
     @i_oficina = null,
     @i_oficial = null

if @w_error <> 0
begin
    goto ERROR
end

--Limpieza de la carpeta
declare @w_path_del varchar(100)
select  @w_path_del = 'del /Q ' + @w_path +'\reporte_riesgo_y_mora_*.*'
EXEC master.dbo.xp_cmdshell @w_path_del

if (OBJECT_ID('tempdb..##tmp_info_riesgo_y_mora')) is not null
begin
  drop table ##tmp_info_riesgo_y_mora
end

create table ##tmp_info_riesgo_y_mora (  
  oficina           varchar(254)   null,
  desc_oficina      varchar(254)   null,
  oficial           varchar(254)   null,
  nom_oficial       varchar(254)   null,
  toperacion        varchar(254)   null,
  grupo             varchar(254)   null,
  cliente           varchar(254)   null,
  nom_cli           varchar(254)   null,
  fecha_ini         varchar(254)   null,
  fecha_ven         varchar(254)   null,
  monto             varchar(254)   null,
  saldo_cap         varchar(254)   null,
  valor_riesgo      varchar(254)   null,
  valor_mora        varchar(254)   null,
  max_ven           varchar(254)   null,
  dias_mora         varchar(254)   null
)

insert into ##tmp_info_riesgo_y_mora (oficina, desc_oficina, oficial, nom_oficial, toperacion, grupo, cliente, nom_cli, fecha_ini, fecha_ven, monto, saldo_cap, valor_riesgo, valor_mora, max_ven, dias_mora) 
select null, 'REPORTE DE RIESGO Y MORA', null, null, null, null, null, null, null, null, null, null, null, null, null, null

insert into ##tmp_info_riesgo_y_mora (oficina, desc_oficina, oficial, nom_oficial, toperacion, grupo, cliente, nom_cli, fecha_ini, fecha_ven, monto, saldo_cap, valor_riesgo, valor_mora, max_ven, dias_mora) 
select null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null

--Insertar cabecera
insert into ##tmp_info_riesgo_y_mora (oficina, desc_oficina, oficial, nom_oficial, toperacion, grupo, cliente, nom_cli, fecha_ini, fecha_ven, monto, saldo_cap, valor_riesgo, valor_mora, max_ven, dias_mora) 
select 'CÓDIGO OFICINA', 'NOMBRE OFICINA', 'CÓDIGO ASESOR', 'NOMBRE DEL ASESOR', 'PRODUCTO', 'GRUPO', 'CÓDIGO', 'CLIENTE', 'FECHA INICIAL', 'FECHA VTO', 'MONTO OTORGADO', 'SALDO', 'VALOR RIESGO', 'VALOR MORA', 'VENCIMIENTO MÁS ANTIGUO', 'DÍAS MORA'

--Insertar detalle
insert into ##tmp_info_riesgo_y_mora (oficina, desc_oficina, oficial, nom_oficial, toperacion, grupo, cliente, nom_cli, fecha_ini, fecha_ven, monto, saldo_cap, valor_riesgo, valor_mora, max_ven, dias_mora)
select oficina, desc_oficina, oficial, nom_oficial, toperacion, grupo, cliente, nom_cli, convert(varchar,fecha_ini, 103), convert(varchar, fecha_ven,103), monto, saldo_cap, valor_riesgo, valor_mora, convert(varchar, max_ven,103), dias_mora
  from ##ops_cuotas_cap_impago order by oficina, oficial, toperacion, grupo, cliente

--csv
declare @csv_file_path nvarchar(max) = @w_path + '\reporte_riesgo_y_mora_' +  convert(varchar, @w_fecha_proceso, 105)  + '.csv' 

declare @w_file varchar (254)= 'reporte_riesgo_y_mora_' + convert(varchar, @w_fecha_proceso, 105) + '.csv' 

declare @w_return int,
        @w_separador char(1)
        
select  @w_separador = ';'

 --Datos
declare @query nvarchar(max) = 'select oficina, desc_oficina, oficial, nom_oficial, toperacion, grupo, cliente, nom_cli, fecha_ini, fecha_ven, monto, saldo_cap, valor_riesgo, valor_mora, max_ven, dias_mora from ##tmp_info_riesgo_y_mora'

-- Export query result to CSV file using BCP 
declare @bcp_command nvarchar(max) = 'bcp "' + @query + '" queryout "' + @csv_file_path + '" -c -t, -T -S ' 


exec @w_return          = cobis..sp_bcp_archivos
     @i_sql             = @query,                 --select o nombre de tabla para generar archivo plano
     @i_tipo_bcp        = 'queryout',             --tipo de bcp in,out,queryout
     @i_rut_nom_arch    = @csv_file_path,         --ruta y nombre de archivo
     @i_separador       = @w_separador            --separador
    
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
