/************************************************************************/
/*  Archivo:              sp_bcp_archivos.sp                            */
/*  Stored procedure:     sp_bcp_archivos                               */
/*  Base de datos:        cobis                                         */
/*  Producto:             Visual Batch                                  */
/*  Disenado por:         William Lopez                                 */
/*  Fecha de escritura:   16/Abr/2021                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCorp.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCorp.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCorp para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  Genera o carga un archivo plano en base a tabla o consulta          */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  16/Abr/2021   William Lopez   Emision Inicial                       */
/************************************************************************/
use cobis
go

if @@error != 0
    raiserror(13000, 0, 127)
go

if exists(select 1 from sysobjects where name = 'sp_bcp_archivos' and type = 'P')
    drop procedure sp_bcp_archivos
go

create procedure sp_bcp_archivos
(
   @i_sql          varchar(1000),        --select o nombre de tabla para generar archivo plano
   @i_tipo_bcp     varchar(10),          --tipo de bcp: in,out,queryout
   @i_rut_nom_arch varchar(255),         --ruta y nombre de archivo
   @i_separador    varchar(5),           --separador
   @i_nom_servidor varchar(100) = null,  --nombre de servidor donde se procesa bcp
   @i_tam_lote     int          = 1000   --cantidad de registros de lote
)
as 
declare
   @w_sp_name      varchar(65),    
   @w_return       int,
   @w_retorno_ej   int,
   @w_error        int,
   @w_mensaje      varchar(255),
   @w_cmd          varchar(1000),
   @w_tam_lote     varchar(10),
   @w_nom_servidor varchar(100),
   @w_sql          varchar(1000)

select @w_sp_name      = 'sp_bcp_archivos',
       @w_error        = 0,
       @w_return       = 0,
       @w_tam_lote     = convert(varchar,@i_tam_lote),
       @i_tipo_bcp     = upper(@i_tipo_bcp),
       @w_nom_servidor = '',
       @w_sql          = upper(@i_sql)

if @i_tipo_bcp not in ('IN','OUT','QUERYOUT')
begin
   select @w_mensaje = 'Error en tipo de bcp '+@i_tipo_bcp,          
          @w_return  = 1
   goto ERROR
end

if @i_tipo_bcp = 'QUERYOUT' and charindex('SELECT',@w_sql) = 0
begin
   select @w_mensaje = 'Error tipo de bcp QUERYOUT: '+@i_tipo_bcp + ' No puede extraer tabla: ' +@w_sql,          
          @w_return  = 1
   goto ERROR
end

if @i_nom_servidor is null
begin 
   --parametro de nombre de servidor central
   select @i_nom_servidor = isnull(pa_char,'')
   from   cobis..cl_parametro
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'SCVL'

end

--generar cadena para bcp
select @w_cmd = 'bcp "'+ @i_sql + '" ' + @i_tipo_bcp + ' ' + @i_rut_nom_arch +' -b'+@w_tam_lote+ ' -c -t' + '"'+@i_separador + '"' + ' -T -S'+@i_nom_servidor

print 'Cadena para bcp: ' + @w_cmd

--generar bcp
exec @w_error = xp_cmdshell @w_cmd

if @w_error != 0 or @@error <> 0
begin
   select @w_mensaje = 'Error al generar BCP '+@w_cmd,
          @w_return  = @w_error
   goto ERROR
end   

return @w_return

ERROR:
   exec cobis..sp_cerror        
        @t_from  = @w_sp_name,
        @i_msg   = @w_mensaje,
        @i_num   = @w_return
   return @w_return
go
