/****************************************************************************/
/*  Archivo:                ca_ej_notif.sp                                  */
/*  Stored procedure:       sp_ca_ejecuta_notificacion_jar                  */ 
/*  Base de datos:          cob_cartera                                     */
/*  Producto:               Cuentas de Ahorros                              */
/****************************************************************************/
/*              IMPORTANTE                                                  */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad            */
/*  de COBISCorp.                                                           */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como        */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus        */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.       */
/*  Este programa esta protegido por la ley de   derechos de autor          */
/*  y por las    convenciones  internacionales   de  propiedad inte-        */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para     */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir            */
/*  penalmente a los autores de cualquier   infraccion.                     */
/****************************************************************************/
/*                              PROPOSITO                                   */
/*  Este programa realiza la generacion de estados en cuenta de cartera     */
/****************************************************************************/
/*                           MODIFICACIONES                                 */
/*  FECHA           AUTOR           RAZON                                   */
/*20/04/2018       P. Ortiz        Cambio de base y devolucion de errores   */
/****************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ca_ejecuta_notificacion_jar')
   drop proc sp_ca_ejecuta_notificacion_jar
go

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

create proc sp_ca_ejecuta_notificacion_jar (
	@i_param1      varchar(10)         --TIPO NOTIFICACION
)
as
declare
@w_return        int,
@w_mensaje       varchar(255),
@w_fecha         datetime,
@w_comando       varchar(255),
@w_path          varchar(100),
@w_param_path    varchar(100)

declare @resultadobcp table (linea varchar(max))

select @w_path = ba_path_fuente 
   from cobis..ba_batch 
   where ba_batch = '7072'
    
select @w_param_path = pa_char
	from cobis..cl_parametro 
	where pa_nemonico = 'RBATN' 
	and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
   select @w_return = 724627
	goto ERRORFIN
end

select @w_path = isnull(@w_param_path, @w_path)

select @w_comando = @w_path + 'ca_notif.bat ' + @i_param1 + ' ' + @w_path

/* EJECUTAR CON CMDSHELL */
delete from @resultadobcp
insert into @resultadobcp
exec xp_cmdshell @w_comando

select * from @resultadobcp

--SELECCIONA CON %ERROR% SI NO ENCUENTRA EN EL FORMATO: ERROR = 
if @w_mensaje is null
    select top 1 @w_mensaje =  linea 
         from @resultadobcp 
         where upper(linea) LIKE upper('%Error%')
         and not (upper(linea) LIKE upper('%Error StatusLogger%'))
         and not (upper(linea) LIKE upper('%Archivo xml no existe.%'))
         and not (upper(linea) LIKE upper('%errors to%'))         
         and not (upper(linea) LIKE upper('%error%@%'))         
if @w_mensaje is not null
begin
    select
        @w_mensaje = 'ERROR EJECUTANDO JAR NOTIFICADOR ' + @w_mensaje,
        @w_return = 724626      
    goto ERRORFIN
end

return 0

ERRORFIN:
select @w_fecha = getdate() 

exec cob_cartera..sp_errorlog
@i_fecha       = @w_fecha,
@i_error       = @w_return,
@i_usuario     = 'admuser',     
@i_descripcion = @w_mensaje,
@i_rollback    = 'N',
@i_tran        = 7072,
@i_tran_name   = 'sp_ca_ejecuta_notificacion_jar'
  
return @w_return

go

