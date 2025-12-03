/* **********************************************************************/
/*      Archivo           : sp_generar_curp.sp                          */
/*      Stored procedure  : sp_generar_curp                             */
/*      Base de datos     : cobis                                       */
/*   Producto:                CLIENTES                                   */
/*   Disenado por:  RIGG   				                                 */
/*   Fecha de escritura: 30-Abr-2019                                     */
/* **********************************************************************/
/*                          IMPORTANTE                                  */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de 'COBISCorp'.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Para calcular el CURP y RFC (mexico), elimina acentos               */
/* **********************************************************************/
/*               MODIFICACIONES                                          */
/*   FECHA       	AUTOR                RAZON                           */
/*   30/Abr/2019   	RIGG	             Versión Inicial Te Creemos      */
/*   15/Dic/2020   	MGB	             	 Se agregan caracteres nuevos    */
/************************************************************************/

use cobis
go

SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go


if exists(select 1 from sysobjects where name = 'fn_filtra_acentos')
   drop function fn_filtra_acentos
go
create function fn_filtra_acentos(
@i_cadena    varchar(200)
)
returns varchar(200)
as
begin
	SELECT @i_cadena = ltrim(rtrim(upper(@i_cadena)))

    select @i_cadena = replace(@i_cadena,'Ñ','N')

    select @i_cadena = replace(@i_cadena,'Ý','Y')
    
	select @i_cadena = replace(@i_cadena,'Ç','C')

    select @i_cadena = replace(@i_cadena,'À','A')
    select @i_cadena = replace(@i_cadena,'Á','A')
    select @i_cadena = replace(@i_cadena,'Â','A')
    select @i_cadena = replace(@i_cadena,'Ã','A')
    select @i_cadena = replace(@i_cadena,'Ä','A')
    select @i_cadena = replace(@i_cadena,'Å','A')
    select @i_cadena = replace(@i_cadena,'Æ','A')
	select @i_cadena = replace(@i_cadena,'Ä','A')

    select @i_cadena = replace(@i_cadena,'È','E')
    select @i_cadena = replace(@i_cadena,'É','E')
    select @i_cadena = replace(@i_cadena,'Ê','E')
    select @i_cadena = replace(@i_cadena,'Ë','E')
    select @i_cadena = replace(@i_cadena,'Ë','E')

    select @i_cadena = replace(@i_cadena,'Ì','I')
    select @i_cadena = replace(@i_cadena,'Í','I')
    select @i_cadena = replace(@i_cadena,'Î','I')
    select @i_cadena = replace(@i_cadena,'Ï','I')
	select @i_cadena = replace(@i_cadena,'Ï','I')

    select @i_cadena = replace(@i_cadena,'Ò','O')
    select @i_cadena = replace(@i_cadena,'Ó','O')
    select @i_cadena = replace(@i_cadena,'Ô','O')
    select @i_cadena = replace(@i_cadena,'Õ','O')
    select @i_cadena = replace(@i_cadena,'Ö','O')
	select @i_cadena = replace(@i_cadena,'Ö','O')

    select @i_cadena = replace(@i_cadena,'Ù','U')
    select @i_cadena = replace(@i_cadena,'Ú','U')
    select @i_cadena = replace(@i_cadena,'Û','U')
    select @i_cadena = replace(@i_cadena,'Ü','U')
	select @i_cadena = replace(@i_cadena,'Ü','U')
	
    return (@i_cadena)
    
end

GO

