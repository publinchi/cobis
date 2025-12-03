/************************************************************************/
/*   Archivo:                   ca_recga.sp                             */
/*   Stored procedure:          sp_carga_reconoc_gar                    */
/*   Base de datos:             cob_cartera                             */
/*   Producto:                  Cartera                                 */
/*   Disenado por:              Julian Mendigaña                        */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Ejecutar la carga de un archivo plano, con los reconocimientos     */
/*   de garantias tipo FGA.                                             */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA               AUTOR                 RAZON                     */
/*  16/Mar/2015         Julian Mendigaña      Emision Inicial REQ 485   */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_carga_reconoc_gar')
   drop proc sp_carga_reconoc_gar
go

create proc sp_carga_reconoc_gar( 
   @i_param1    datetime = getdate,
   @i_param2    varchar(250) = 'ca_recon_gar.txt'
)
as       

declare  
   @w_msg           varchar(250),
   @w_path          varchar(250),
   @w_file          varchar(250),
   @w_s_app         varchar(250),
   @w_cmd           varchar(250),
   @w_bd            varchar(250),
   @w_tabla         varchar(250),
   @w_comando       varchar(1000),
   @w_fuente        varchar(250),
   @w_errores       varchar(250),
   @w_path_error_s_app varchar(250),
   @w_sp            varchar(250),
   @w_error         int,
   @w_return		int,
   @w_fechaproceso  datetime,
   @w_archivo_entrada varchar(250)

--select @w_fechaproceso = fp_fecha from cobis..ba_fecha_proceso with(nolock)

/*** Cargar el archivo a la tabla ***/
truncate table ca_rec_gar_mas

select @w_sp = 'cob_cartera..sp_carga_reconoc_gar'

select @w_archivo_entrada = @i_param2

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente = 'cob_cartera..sp_carga_reconoc_gar'

select @w_path_error_s_app = pa_char
from cobis..cl_parametro
where pa_nemonico = 'S_APP'

if @@rowcount = 0 begin
   print 'ERROR EN LA BUSQUEDA DEL PATH EN LA TABLA ba_batch'
   return 1   
end
/* Carga Parametros para el bcp */
select @w_s_app    = @w_path_error_s_app + 's_app',
       @w_cmd      = @w_s_app + ' bcp ',
       @w_bd       = 'cob_cartera'

select 
   @w_file    = @w_archivo_entrada,  
   @w_tabla   = 'ca_rec_gar_mas',
   @w_fuente  = @w_path + @w_file,
   @w_errores = @w_path + @w_file + '.err'

select
   @w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' in ' + @w_fuente + ' -c -t"|" -auto -login '  + '-config ' + @w_s_app + '.ini > ' + @w_errores
print @w_comando
exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print @w_error
   goto ERROR_FIN
end



return 0

ERROR_FIN:

exec sp_errorlog
@i_fecha       = @i_param1,
@i_error       = @w_error,
@i_usuario     = 'operador',
@i_tran        = 0,
@i_tran_name   = 'sp_carga_reconoc_gar',
@i_rollback    = 'N',
@i_cuenta      = null,
@i_descripcion = @w_comando

return @w_error




go


