/************************************************************************/
/*   Archivo           : fn_altisonante.sp                              */
/*   Stored procedure  : fn_altisonante                                 */
/*   Base de datos     : cobis                                          */
/*   Producto:                CLIENTES                                  */
/*   Disenado por:  RIGG   				                                */
/*   Fecha de escritura: 30-Abr-2019                                    */
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
/*  Filtra palabras altisonantes para el CURP y RFC                     */
/* **********************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA       	AUTOR                RAZON                          */
/*   30/Abr/2019   	RIGG	   Versión Inicial Te Creemos               */
/*   07/Jul/2020    FSAP       Estandarizacion clientes                 */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go
if exists(select 1 from sysobjects where name = 'fn_altisonante')
   drop function fn_altisonante
go

create function fn_altisonante(
@i_origen    VARCHAR(10),
@i_cadena    varchar(100)
)
returns varchar(100)
as
begin
    declare @w_pos SMALLINT
    IF @i_origen = 'RFC' SELECT @w_pos = 4
    IF @i_origen = 'CURP' SELECT @w_pos = 2
    SELECT @i_cadena = CASE WHEN substring(@i_cadena, 1,4) IN (
							'BACA', 'BAKA', 'BUEI', 'BUEY', 'CACA',
							'CACO', 'CAGA', 'CAGO', 'CAKA', 'CAKO',
							'COGE', 'COGI', 'COJA', 'COJE', 'COJI',
							'COJO', 'COLA', 'CULO', 'FALO', 'FETO',
							'GETA', 'GUEI', 'GUEY', 'JETA', 'JOTO',
							'KACA', 'KACO', 'KAGA', 'KAGO', 'KAKA',
							'KAKO', 'KOGE', 'KOGI', 'KOJA', 'KOJE',
							'KOJI', 'KOJO', 'KOLA', 'KULO', 'LILO',
							'LOCA',
							'LOCO', 'LOKA', 'LOKO', 'MAME', 'MAMO',
							'MEAR', 'MEAS', 'MEON', 'MIAR', 'MION',
							'MOCO', 'MOKO', 'MULA', 'MULO', 'NACA',
							'NACO', 'PEDA', 'PEDO', 'PENE', 'PIPI',
							'PITO', 'POPO', 'PUTA', 'PUTO', 'QULO',
							'RATA', 'ROBA', 'ROBE', 'ROBO', 'RUIN',
							'SENO', 'TETA', 'VACA', 'VAGA', 'VAGO',
							'VAKA', 'VUEI', 'VUEY', 'WUEI', 'WUEY')
						  THEN
	        			substring(@i_cadena, 1, @w_pos -1) + 'X' + substring(@i_cadena,@w_pos + 1, 1000) 
	        			ELSE
	        			@i_cadena
						END

  return (@i_cadena)
end
go

