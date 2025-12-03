/* **********************************************************************/
/*      Archivo           : fn_UTF8_2_ASCII.sp                          */
/*      Stored procedure  : fn_UTF8_2_ASCII                             */
/*      Base de datos     : cobis                                       */
/*   Producto:                CLIENTES                                  */
/*   Disenado por:  JAFL   				                                */
/*   Fecha de escritura: 08-07-2019                                     */
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
/* **********************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA       	AUTOR                RAZON                          */
/*   08/07/2019   	JAFL	             Versión Inicial Te Creemos     */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go
if exists(select 1 from sysobjects where name = 'fn_UTF8_2_ASCII')
   drop function fn_UTF8_2_ASCII
go

CREATE FUNCTION [dbo].[fn_UTF8_2_ASCII] (@value varchar(250))
RETURNS varchar(500)
AS
BEGIN

	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(129),'Á')	
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(128),'À')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(137),'É')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(136),'È')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(141),'Í')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(140),'Ì')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(147),'Ó')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(146),'Ò')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(154),'Ú')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(153),'Ù')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(143),'Ï')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(156),'Ü')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(135),'Ç')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(145),'Ñ')

	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(161),'á')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(160),'à')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(169),'é')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(168),'è')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(173),'í')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(172),'ì')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(179),'ó')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(178),'ò')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(186),'ú')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(185),'ù')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(175),'ï')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(188),'ü')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(167),'ç')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(195)+char(177),'ñ')
	
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(194)+char(186),'º')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(194)+char(170),'ª')
	SELECT @value = REPLACE(@value COLLATE Latin1_General_CS_AS,char(226)+char(130)+char(172),'€')

	RETURN @value
END