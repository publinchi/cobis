/**************************************************************************/
/*   Archivo:             execrepg.sp                                     */
/*   Stored procedure:    sp_exec_repg                                    */
/*   Base de datos:       cob_cartera                                     */
/*   Producto:            Credito y Cartera                               */
/*   Disenado por:        Silvia Portilla S.                              */
/*   Fecha de escritura:  Febrero 2010                                    */
/**************************************************************************/
/*                              IMPORTANTE                                */
/*   Este  programa  es parte  de los  paquetes  bancarios  propiedad de  */
/*   'MACOSA'.  El uso no autorizado de este programa queda expresamente  */
/*   prohibido as¡ como cualquier alteraci¢n o agregado hecho por alguno  */
/*   alguno  de sus usuarios sin el debido consentimiento por escrito de  */
/*   la Presidencia Ejecutiva de MACOSA o su representante.               */
/**************************************************************************/
/*                              PROPOSITO                                 */
/*   Permite obtener los datos de los pagos realizados en cartera         */
/**************************************************************************/
/*                             MODIFICACIONES                             */
/*      FECHA                 AUTOR                PROPOSITO              */
/*   2-Febrero-2010       Silvia Portilla S.      Emision Inicial         */
/**************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_exec_repg')
   drop proc sp_exec_repg
go

create proc sp_exec_repg
(
   @i_fecha_ini   datetime,
   @i_fecha_fin   datetime
)
as
declare
  @w_return          int,
  @w_sp_name         varchar(32),   -- NOMBRE STORED PROC
  @w_msg             varchar(255),  -- MENSAJE DE ERROR
  @w_fecha_hora      datetime,      -- FECHA Y HORA DE CORRDIDA
  @w_s_app           varchar(250),
  @w_cmd             varchar(250),
  @w_bd              varchar(250),
  @w_tabla           varchar(250),
  @w_fecha_arch      varchar(10),
  @w_path_s_app      varchar(250),
  @w_path            varchar(250),
  @w_comando         varchar(500),
  @w_destino         varchar(250),
  @w_errores         varchar(250),
  @w_error           int,
  @w_fecha_proceso   datetime,
  @w_archivo         varchar(64),
  @w_columna         varchar(50),
  @w_col_id          int,
  @w_cabecera        varchar(5000)

  
select @w_fecha_proceso  = fp_fecha
from cobis..ba_fecha_proceso 

select @w_path_s_app = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'S_APP'

if @w_path_s_app is null begin
   print 'NO EXISTE PARAMETRO GENERAL S_APP'
   print @w_comando
   return 1
end

----------------------------------------
--Generar Archivo Plano
----------------------------------------
select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = 7078

select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_cpagos_tmp out '

select @w_destino  = @w_path + 'reppag_' + replace(convert(varchar, @w_fecha_proceso, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.txt',
       @w_errores  = @w_path + 'reppag_' + replace(convert(varchar, @w_fecha_proceso, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.err'

select @w_comando = @w_cmd + @w_path + 'reppag -b5000 -c -e' + @w_errores + ' -t"!" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando Archivo de Pagos'
   print @w_comando
   return 1
end

----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select @w_col_id   = 0,
       @w_columna  = '',
       @w_cabecera = ''

while 1 = 1 begin
   set rowcount 1
   select @w_columna = c.name,
          @w_col_id  = c.colid
   from sysobjects o, syscolumns c
   where o.id    = c.id
   and   o.name  = 'ca_cpagos_tmp'
   and   c.colid > @w_col_id
   order by c.colid
    
   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   select @w_cabecera = @w_cabecera + @w_columna + '!'
end
--Escribir Cabecera
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_destino

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error generando Archivo de Cabeceras'
   print @w_comando
   return 1
end

select @w_comando = 'copy ' + @w_destino + ' + ' + @w_path + 'reppag ' + @w_destino

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error Agregando Cabeceras'
   print @w_comando
   return 1
end

return 0
go



