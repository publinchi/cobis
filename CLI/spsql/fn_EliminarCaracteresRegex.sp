/************************************************************************/
/*   Archivo           : fn_EliminarCaracteresRegex.sp                  */
/*   Stored procedure  : fn_EliminarCaracteresRegex                     */
/*   Base de datos     : cobis                                          */
/*   Producto:                CLIENTES                                  */
/*   Disenado por:  Bruno Dueñas                                        */
/*   Fecha de escritura: 19-Feb-2024                                    */
/************************************************************************/
/*                    IMPORTANTE                                        */
/*   Esta aplicacion es parte de los  paquetes bancarios                */
/*   propiedad de COBISCORP S.A.                                        */
/*   Su uso no autorizado queda  expresamente  prohibido                */
/*   asi como cualquier alteracion o agregado hecho  por                */
/*   alguno de sus usuarios sin el debido consentimiento                */
/*   por escrito de COBISCORP.                                          */
/*   Este programa esta protegido por la ley de derechos                */
/*   de autor y por las convenciones  internacionales de                */
/*   propiedad intelectual.  Su uso  no  autorizado dara                */
/*   derecho a COBISCORP para obtener ordenes de secuestro              */
/*   o  retencion  y  para  perseguir  penalmente a  los                */
/*   autores de cualquier infraccion.                                   */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Elimina caracteres que hagan match con el regex                     */
/* **********************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA          AUTOR                RAZON                          */
/*   19/Feb/2024    Bruno Dueñas       Emision Inicial                  */
/*   21/Feb/2024    Bruno Dueñas       Se reemplaza por espacio         */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go
if exists(select 1 from sysobjects where name = 'fn_EliminarCaracteresRegex')
   drop function fn_EliminarCaracteresRegex
go

CREATE FUNCTION fn_EliminarCaracteresRegex
(
    @i_string VARCHAR(MAX),
    @i_regex varchar(max)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
DECLARE @index INT

SET @index = PATINDEX(@i_regex, @i_string)

WHILE @index > 0
BEGIN
    SET @i_string = STUFF(@i_string, @index, 1, ' ')
    SET @index = PATINDEX(@i_regex, @i_string)
END

set @i_string = trim(@i_string)

return @i_string
END

go
