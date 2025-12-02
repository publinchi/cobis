/****************************************************************************/
/*  Archivo:                ca_ejejar.sp                                    */
/*  Stored procedure:       sp_ca_ejecuta_jar                               */ 
/*  Base de datos:          cob_ahorros                                     */
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
/*  03/01/2017      J. Salazar      Emision inicial                         */
/****************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ca_ejecuta_jar')
   drop proc sp_ca_ejecuta_jar
go

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

create proc sp_ca_ejecuta_jar (
@i_param1      char(1),         --Operacion
@i_param2      datetime,        --Fecha de proceso
@i_param3      cuenta   = null, --Codigo de Operacion
@i_param4      int      = null  --Codigo de Cliente
)
as
declare
@w_return        int,
@w_mensaje       varchar(255),
@w_fecha         datetime,
@w_comando       varchar(255),
@w_path          varchar(100)

if @i_param1 = 'I'
begin
   exec @w_return = cob_conta_super..sp_consulta_estados_js
        @i_operacion = @i_param1,
		@i_fecha     = @i_param2,
		@i_banco     = @i_param3,
		@i_cliente   = @i_param4
	
   if @w_return  <> 0 begin
       select
         @w_mensaje = 'ERROR INSERTANDO ESTADOS JAR',
         @w_return = 7000003      
       goto ERRORFIN
   end
end

if @i_param1 = 'Q'
begin

   select @w_path = ba_path_fuente 
   from cobis..ba_batch 
   where ba_batch = '28792'     

   select @w_comando = @w_path + 'caactest.bat ' + @i_param1 + ' ' + convert(char(10), @i_param2, 126)
	
   if @i_param3 is not null begin
      select @w_comando = @w_comando + ' ' + @i_param3
   
      if @i_param4 is not null
         select @w_comando = @w_comando + ' ' + convert(varchar, @i_param4)
   end

   print  @w_comando

   /* EJECUTAR CON CMDSHELL */
   exec @w_return = xp_cmdshell @w_comando
	
   if @w_return  <> 0 begin
       select
         @w_mensaje = 'ERROR ACTUALIZANDO ESTADOS JAR',
         @w_return = 7000003      
       goto ERRORFIN
   end
end

return 0

ERRORFIN:
select @w_fecha = getdate() 

exec cobis..sp_errorlog
@i_fecha       = @w_fecha,
@i_error       = @w_return,
@i_usuario     = 'admuser',     
@i_descripcion = @w_mensaje,
@i_rollback    = 'N',
@i_tran        = 7000,
@i_tran_name   = 'sp_ca_ejecuta_jar'
  
return @w_return

go

