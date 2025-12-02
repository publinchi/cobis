/************************************************************************/
/*  Archivo:              archivo_tabla_manual.sp                       */
/*  Stored procedure:     sp_archivo_tabla_manual                       */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         Juan Carlos Guzmán                            */
/*  Fecha de escritura:   22/Nov/2021                                   */
/************************************************************************/
/*             IMPORTANTE                                               */
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
/*  Inserción de registros leidos de archivo plano mediante Bulk Copy   */
/*  con modificaciones de prestamos para resolver diferimientos         */
/*  masivos.                                                            */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA          AUTOR       RAZON                                    */
/*  22/Nov/2021    JGU         Emision Inicial                          */
/************************************************************************/

use cob_cartera
go

set nocount on
go

if exists(select 1 from sysobjects where name = 'sp_archivo_tabla_manual' and type = 'P')
   drop proc sp_archivo_tabla_manual 
go

create proc sp_archivo_tabla_manual
(
   @i_param1   varchar(100)  = null        --> Nombre del archivo
)

as
declare @w_return         int = 0,
        @w_tipo_bcp       varchar(10),
        @w_separador      varchar(1),
		@w_path_destino   varchar(500),
		@w_sql            varchar(255),
		@w_mensaje        varchar(1000),
		@w_sp_name        varchar(30)

select  @w_tipo_bcp     = 'in',
        @w_path_destino = CONCAT('C:\COBIS\Vbatch\cartera\listados\', @i_param1),
        @w_separador    = '|',
		@w_sql			= 'cob_cartera..ca_archivo_tabla_manual',
		@w_sp_name      = 'sp_archivo_tabla_manual'


-- ELIMINAR REGISTROS DE LA TABLA TEMPORAL
truncate table cob_cartera..ca_archivo_tabla_manual

-- Ejecución de Bulk Copy
exec @w_return          = cobis..sp_bcp_archivos
     @i_sql             = @w_sql,           --select o nombre de tabla para generar archivo plano
     @i_tipo_bcp        = @w_tipo_bcp,      --tipo de bcp in,out,queryout
     @i_rut_nom_arch    = @w_path_destino,   --ruta y nombre de archivo
     @i_separador       = @w_separador   --separador

if @w_return != 0
begin
  select @w_mensaje = 'Error al llenar tabla temp bcp cobis..sp_bcp_archivos'
  goto ERROR
end

return 0


ERROR:
   exec cobis..sp_cerror
      @t_from     = @w_sp_name
      ,@i_num     = @w_return
	  ,@i_msg     = @w_mensaje

   return @w_return

go