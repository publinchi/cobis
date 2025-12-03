/* **********************************************************************/
/*   Archivo           : sp_generar_curp.sp                             */
/*   Stored procedure  : sp_generar_curp                                */
/*   Base de datos     : cobis                                          */
/*   Producto:           CLIENTES                                       */
/*   Disenado por:       RIGG   				                        */
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
/*  Para calcular el CURP y RFC (mexico), elimina palabras comunes      */
/* **********************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA       	AUTOR                RAZON                          */
/*   30/Abr/2019   	RIGG	             Versión Inicial Te Creemos     */
/************************************************************************/
use cobis
go

SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go

if exists(select 1 from sysobjects where name = 'fn_filtra_nombres')
   drop function fn_filtra_nombres
go
create function fn_filtra_nombres(
@i_cadena    varchar(100)
)
returns varchar(100)
as
begin
    declare @w_pos smallint,
            @w_posicion smallint
			
    select @i_cadena = replace(@i_cadena,'DE LA '      ,' ')
    select @i_cadena = replace(@i_cadena,'DE '         ,' ')
    select @i_cadena = replace(@i_cadena,'Y '          ,' ')
    select @i_cadena = replace(@i_cadena,'DEL '        ,' ')
    select @i_cadena = replace(@i_cadena,'MA DE LOS '  ,' ')
    select @i_cadena = replace(@i_cadena,'MA DE LA '   ,' ')
    select @i_cadena = replace(@i_cadena,'MA DEL '     ,' ')
    select @i_cadena = replace(@i_cadena,'MARIA DE LA ' ,' ')
    select @i_cadena = replace(@i_cadena,'MARIA DE '   ,' ')
    select @i_cadena = replace(@i_cadena,'MARIA DEL '  ,' ')
    select @i_cadena = replace(@i_cadena,'MARIA '      ,' ')
    select @i_cadena = replace(@i_cadena,'JOSE '       ,' ')
    select @i_cadena = replace(@i_cadena,'JOSE DE '    ,' ')
    select @i_cadena = replace(@i_cadena,'.'           ,' ')
    select @i_cadena = replace(@i_cadena,','           ,' ')
    select @i_cadena = replace(@i_cadena,'LA '         ,' ')
    select @i_cadena = replace(@i_cadena,'LOS '        ,' ')
    select @i_cadena = replace(@i_cadena,'LAS '        ,' ')
    select @i_cadena = replace(@i_cadena,'MC '         ,' ')
    select @i_cadena = replace(@i_cadena,'MAC '        ,' ')
    select @i_cadena = replace(@i_cadena,'VON '        ,' ')
    select @i_cadena = replace(@i_cadena,'VAN '        ,' ')
    select @i_cadena = replace(@i_cadena,' MARIA '     ,' ')
    select @i_cadena = replace(@i_cadena,' JOSE '      ,' ')
    select @i_cadena = replace(@i_cadena,' MA. '       ,' ')
    select @i_cadena = replace(@i_cadena,' MA '        ,' ')
    select @i_cadena = replace(@i_cadena,' J.'         ,' ')
    select @i_cadena = replace(@i_cadena,' J '         ,' ')
    select @i_cadena = replace(@i_cadena,' PARA '      ,' ')
    select @i_cadena = replace(@i_cadena,' AND '       ,' ')
    select @i_cadena = replace(@i_cadena,' CON '       ,' ')
    select @i_cadena = replace(@i_cadena,' DEL '       ,' ')
    select @i_cadena = replace(@i_cadena,' LAS '       ,' ')
    select @i_cadena = replace(@i_cadena,' LOS '       ,' ')
    select @i_cadena = replace(@i_cadena,' MAC '       ,' ')
    select @i_cadena = replace(@i_cadena,' POR '       ,' ')
    select @i_cadena = replace(@i_cadena,' SUS '       ,' ')
    select @i_cadena = replace(@i_cadena,' THE '       ,' ')
    select @i_cadena = replace(@i_cadena,' VAN '       ,' ')
    select @i_cadena = replace(@i_cadena,' VON '       ,' ')
    select @i_cadena = replace(@i_cadena,' AL '        ,' ')
    select @i_cadena = replace(@i_cadena,' DE '        ,' ')
    select @i_cadena = replace(@i_cadena,' EL '        ,' ')
    select @i_cadena = replace(@i_cadena,' EN '        ,' ')
    select @i_cadena = replace(@i_cadena,' LA '        ,' ')
    select @i_cadena = replace(@i_cadena,' MC '        ,' ')
    select @i_cadena = replace(@i_cadena,' MI '        ,' ')
    select @i_cadena = replace(@i_cadena,' OF '        ,' ')
    select @i_cadena = replace(@i_cadena,' A '         ,' ')
    select @i_cadena = replace(@i_cadena,' E '         ,' ')
    select @i_cadena = replace(@i_cadena,' Y '         ,' ')
    /* Nuevas exclusiones */
    select @w_posicion = charindex('MA ',@i_cadena) 
    if @w_posicion = 1 
       select @i_cadena = replace(@i_cadena,'MA '         ,' ')
    
    select @w_posicion = charindex('DA ',@i_cadena)
    if @w_posicion = 1   
       select @i_cadena = replace(@i_cadena,'DA '         ,' ')
       
    select @w_posicion = charindex('DAS ',@i_cadena)
    if @w_posicion = 1
       select @i_cadena = replace(@i_cadena,'DAS '        ,' ')
       
    select @w_posicion = charindex('DE ',@i_cadena)
    if @w_posicion = 1
       select @i_cadena = replace(@i_cadena,'DE '         ,' ')
        
    select @w_posicion = charindex('DEL ',@i_cadena)
    if @w_posicion = 1
       select @i_cadena = replace(@i_cadena,'DEL '        ,' ')
       
    select @w_posicion = charindex('DER ',@i_cadena)
    if @w_posicion = 1
       select @i_cadena = replace(@i_cadena,'DER '        ,' ')
     
    select @w_posicion = charindex('DI ',@i_cadena)
    if @w_posicion = 1 
       select @i_cadena = replace(@i_cadena,'DI '         ,' ')
    
    select @w_posicion = charindex('DIE ',@i_cadena)
    if @w_posicion = 1
       select @i_cadena = replace(@i_cadena,'DIE '        ,' ')
    
    select @w_posicion = charindex('DD ',@i_cadena)
    if @w_posicion = 1   
       select @i_cadena = replace(@i_cadena,'DD '         ,' ')
    
    select @w_posicion = charindex('LE ',@i_cadena)
    if @w_posicion = 1   
       select @i_cadena = replace(@i_cadena,'LE '         ,' ')
    
    select @w_posicion = charindex('LES ',@i_cadena)
    if @w_posicion = 1   
       select @i_cadena = replace(@i_cadena,'LES '        ,' ')
	
	select @i_cadena = replace(@i_cadena,' MA '        ,' ')
    select @i_cadena = replace(@i_cadena,' DA '        ,' ')
    select @i_cadena = replace(@i_cadena,' DAS '       ,' ')
    select @i_cadena = replace(@i_cadena,' DE '        ,' ')
    select @i_cadena = replace(@i_cadena,' DEL '       ,' ')
    select @i_cadena = replace(@i_cadena,' DER '       ,' ')
    select @i_cadena = replace(@i_cadena,' DI '        ,' ')
    select @i_cadena = replace(@i_cadena,' DIE '       ,' ')
    select @i_cadena = replace(@i_cadena,' DD '        ,' ')
    select @i_cadena = replace(@i_cadena,' LE '        ,' ')
    select @i_cadena = replace(@i_cadena,' LES '       ,' ')
	

    select @i_cadena = case substring(@i_cadena,1,2)
        when 'CH' then
            replace(@i_cadena, 'CH', 'C')
        when 'LL' then
            replace(@i_cadena, 'LL', 'L')
        else
            @i_cadena
        end
    select @i_cadena = replace(@i_cadena, ' ','')
  return (@i_cadena)
end
go
