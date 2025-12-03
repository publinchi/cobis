/****************************************************************************/
/*   Archivo             :  ca_rep_opercan.sp                               */
/*   Stored procedure    :  sp_rep_opercan                                  */
/*   Base de datos       :  cob_cartera                                     */
/*   Producto            :  CARTERA                                         */
/*   Disenado por        :  Liana Coto                                      */
/*   Fecha de escritura  :  SEPT/2015                                       */
/****************************************************************************/
/*                           IMPORTANTE                                     */
/*   Este programa es parte de los paquetes bancarios propiedad de          */
/*   'MACOSA'.                                                              */
/*   Su uso no autorizado queda expresamente prohibido asi como cualquier   */
/*   alteracion o agregado hecho por alguno de sus usuarios sin el debido   */
/*   consentimiento por escrito de la Presidencia Ejecutiva de MACOSA o     */
/*   su representante.                                                      */
/****************************************************************************/
/*                           PROPOSITO                                      */
/*   Proceso Batch para reporte de operaciones canceladas                   */
/****************************************************************************/
/*                           MODIFICACIONES                                 */
/*      FECHA           AUTOR                         RAZON                 */
/*     SEPT/2015      LianaCoto               Emisión Inicial --Req 535     */
/****************************************************************************/

use 
cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rep_opercan' and type = 'P')
   drop proc sp_rep_opercan
go

create proc sp_rep_opercan
   @i_param1  datetime,   -- Fecha Inicio
   @i_param2  datetime    -- Fecha Fin

as
declare
@w_fecha_ini      datetime,
@w_fecha_fin      datetime,
@w_fecha_proc     varchar(12),
@w_sp_name        varchar(15),
/*PARAMETROS BCP*/
@w_s_app          varchar(255),
@w_path           varchar(255),
@w_nombre         varchar(255),
@w_nombre_cab     varchar(255),
@w_destino        varchar(2500),
@w_errores        varchar(1500),
@w_columna        varchar(100),
@w_cabecera       varchar(2500),
@w_nom_tabla      varchar(100),
@w_comando        varchar(2500),
@w_nombre_plano   varchar(2500),
@w_path_error     varchar(2500),
@w_fecha1         varchar(10),
@w_cmd            varchar(2500),
@w_anio           varchar(4),
@w_mes            varchar(2),
@w_dia            varchar(2),
@w_msg            descripcion,
@w_error          int,
@w_col_id         int

select @w_sp_name   = 'sp_rep_opercan',
       @w_fecha_ini = @i_param1,
       @w_fecha_fin = @i_param2
       
if  @w_fecha_ini is null or @w_fecha_fin is null
begin
   print 'LOS PARAMETROS FECHA INICIO Y FECHA FIN SON OBLIGATORIOS '
   select @w_error = 701185,
          @w_msg   = 'LOS PARAMETROS FECHA INICIO Y FECHA FIN SON OBLIGATORIOS '
   goto ERRORFIN
end

select @w_fecha_proc = convert(varchar,fp_fecha,101)
from cobis..ba_fecha_proceso 

if  @w_fecha_ini > @w_fecha_proc or @w_fecha_fin > @w_fecha_proc
begin
   print 'LA FECHA INGRESADA ES MAYOR A LA FECHA DE PROCESO'
   select @w_error = 701185,
          @w_msg   = 'LA FECHA INGRESADA ES MAYOR A LA FECHA DE PROCESO'          
   goto ERRORFIN
end
       
select banco   = op_banco,    fecha_can  = convert(varchar,op_fecha_ult_proceso,101),    id_cliente = op_cliente,
       nombre  = op_nombre,   cedula     = convert(varchar(15),'0'),                     oficina    = op_oficina, 
       nom_ofi = convert(varchar(50), '')  
into #ca_operacion
from ca_operacion
where op_fecha_ult_proceso between @w_fecha_ini and @w_fecha_fin
and   op_estado            = 3

if @@error <> 0
begin
   print 'ERROR AL INSERTAR EN  #ca_operacion'
   select @w_error = 701185,
          @w_msg = 'ERROR AL INSERTAR EN  #ca_operacion'
   goto ERRORFIN
end

update #ca_operacion
set cedula = en_ced_ruc
from #ca_operacion a , cobis..cl_ente
where a.id_cliente = en_ente

if @@error <> 0
begin
    print'ERROR AL ACTUALIZAR CEDULA EN #ca_operacion'
    select @w_error = 708152,
           @w_msg = 'ERROR AL ACTUALIZAR CEDULA EN #ca_operacion'
    goto ERRORFIN

end

update #ca_operacion
set nom_ofi = of_nombre
from #ca_operacion a , cobis..cl_oficina
where of_oficina = a.oficina

if @@error <> 0
begin
    print'ERROR AL ACTUALIZAR OFICINA EN #ca_operacion'
    select @w_error = 708152,
           @w_msg = 'ERROR AL ACTUALIZAR OFICINA EN #ca_operacion'
    goto ERRORFIN
end

if exists (select 1 from sysobjects where name = 'rep_opercan' and type = 'U')
begin
 drop table rep_opercan
end

select 
'FECHA_REPORTE'  = ltrim(rtrim(@w_fecha_proc)),
'CODIGO_OFICINA' = ltrim(rtrim(oficina)),
'NOMBRE_OFICINA' = ltrim(rtrim(nom_ofi)),
'FECHA_CAN_OBLI' = ltrim(rtrim(fecha_can)),
'NUM_OBLIGACION' = ltrim(rtrim(banco)),
'NOMBRE_CLIENTE' = ltrim(rtrim(nombre)),
'NUM_ID_CLIENTE' = ltrim(rtrim(cedula))
into rep_opercan
from #ca_operacion
order by oficina asc

if @@error <> 0
begin
   print'ERROR AL INSERTAR EN  rep_opercan'
   select @w_error = 701185,
          @w_msg = 'ERROR AL INSERTAR EN  rep_opercan'
   goto ERRORFIN
end

------------------------------------------------------------------
--------------------------REALIZANDO BCP--------------------------
------------------------------------------------------------------

select @w_anio = convert(varchar(4),datepart(yyyy,@w_fecha_proc)),
       @w_mes = convert(varchar(2),datepart(mm,@w_fecha_proc)), 
       @w_dia = convert(varchar(2),datepart(dd,@w_fecha_proc))
       
select @w_fecha1  = (right('00' + @w_mes,2) + right('00'+ @w_dia,2) + @w_anio)

select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

--GENERACIÓN DE LISTADO
select @w_path = pp_path_destino
from cobis..ba_path_pro 
where pp_producto  = 7
								
----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select 	@w_nombre       = 'rep_opercan',
		@w_nom_tabla    = 'rep_opercan',
		@w_col_id       = 0,
		@w_columna      = '',
		@w_cabecera     = convert(varchar(2000), ''),
		@w_nombre_cab   = @w_nombre
				
select @w_nombre_plano = @w_path + @w_nombre_cab + '_' + @w_fecha1 + '.txt'

while 1 = 1 
begin
   set rowcount 1
   select   @w_columna = c.name,
			@w_col_id  = c.colid
   from cob_cartera..sysobjects o, cob_cartera..syscolumns c
   where o.id    = c.id
   and   o.name  = @w_nom_tabla
   and   c.colid > @w_col_id
   order by c.colid

       if @@rowcount = 0 
	   begin
		  set rowcount 0
		  break
	   end

    select @w_cabecera = @w_cabecera + @w_columna + '^|'
end

select @w_cabecera = left(@w_cabecera, datalength(@w_cabecera) - 2)

--Escribir Cabecera
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 
   begin
      select @w_error    = 2902797, 
	         @w_msg  = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
             goto ERRORFIN
   end

--Ejecucion para Generar Archivo Datos
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..rep_opercan out '

select  @w_destino  = @w_path + 'rep_opercan.txt',
		@w_errores  = @w_path + 'rep_opercan.err'
				
select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'				

exec @w_error = xp_cmdshell @w_comando

    if @w_error <> 0 
	begin
	   select @w_msg = 'ERROR GENERANDO REPORTE rep_opercan' 
	   goto ERRORFIN
	end

----------------------------------------
--Union de archivos (cab) y (dat)
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'rep_opercan.txt' + ' ' + @w_nombre_plano							
exec @w_error = xp_cmdshell @w_comando
	
select @w_cmd = 'del ' + @w_destino 
exec xp_cmdshell @w_cmd
                       
    if @w_error <> 0 
	begin
	   select @w_error   = 2902797, 
	          @w_msg = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
	   goto ERRORFIN
	end

return 0

ERRORFIN:

exec sp_errorlog 
     @i_fecha       = @w_fecha_proc,
     @i_error       = @w_error, 
     @i_tran        = null,
     @i_usuario     = 'op_batch', 
     @i_tran_name   = @w_sp_name,
     @i_cuenta      = '',
     @i_rollback    = 'N',
     @i_descripcion = @w_msg   
     print @w_msg
return 1

go
