/************************************************************************/
/*  Archivo:                concatena_mensaje.sp                        */
/*  Function:               fn_concatena_mensaje                        */
/*  Producto:               Clientes                                    */
/*  Disenado por:           Bruno Duenas                                */
/*  Fecha de escritura:     02-09-2021                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es una funcion para manejo de mensajes de error      */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA       AUTOR           RAZON                                   */
/*  02-09-2021  BDU             Emision inicial                         */
/************************************************************************/
use cob_interface

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

if exists (select 1 from sysobjects where name = 'fn_concatena_mensaje')
   drop function fn_concatena_mensaje
go

create function [dbo].[fn_concatena_mensaje](
   @i_valor    varchar(200),
   @i_error    int,
   @i_culture  varchar(10) = 'NEUTRAL'
)
returns varchar(132)
as
begin
declare @w_init_msg_error varchar(200),
        @w_sp_msg         varchar(MAX),
        @w_culture        varchar(10)
   --Si el mensaje es 1720018 es porque no encontro un valor en los catalogos
   if @i_error = 1720018 
   begin
      select @i_error = 1720552
   end
   select @w_culture = REPLACE(upper(@i_culture), '_', '%')
   if exists(select 1 from cobis..ad_error_i18n where pc_codigo_int = @i_error and re_cultura like '%'+@w_culture+'%')
   begin
   select @w_init_msg_error = convert(varchar,@i_error)+ ' - ' + re_valor                                                                                                                                                                           
         from   cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int                                                                                                                                                                                                                        
         and    re_cultura like '%'+@w_culture+'%')                                                                                                                                                                                                           
         where numero = @i_error 
   end
   else
   begin
      select @w_init_msg_error = convert(varchar,@i_error)+ ' - ' + mensaje                                                                                                                                                                           
      from   cobis..cl_errores                                                                                                                                                                                                     
      where numero = @i_error 
   end
   select @w_sp_msg = (@w_init_msg_error + ' ' + @i_valor)
   return @w_sp_msg
   
end

go
