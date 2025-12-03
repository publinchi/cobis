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
/*  Para calcular el CURP y RFC (mexico), encuentra la primera vocal    */
/*  o consonante                                                        */
/* **********************************************************************/
/*               MODIFICACIONES                                          */
/*   FECHA       	AUTOR                RAZON                           */
/*   30/Abr/2019   	RIGG	             Versión Inicial Te Creemos      */
/************************************************************************/

use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go


if exists(select 1 from sysobjects where name = 'fn_primera_letra')
   drop function fn_primera_letra
go
create function fn_primera_letra(
@i_cadena    varchar(100),
@i_vocal     varchar(1) -- 'c=consonante, v=vocal
)
returns varchar(10)
as
begin
-- devuelve la primera letra o primera consonante de una cadena
declare
@w_linea   varchar(1000),
@w_letra   varchar(1),
@w_vocales varchar(5)

select @w_vocales = 'AEIOU'
select  @w_linea = @i_cadena
while len(@w_linea) > 0
begin
    select @w_letra = substring(@w_linea,1,1)
    select @w_linea = substring(@w_linea,2,100)


    if @i_vocal = 'V'
    begin
        if charindex(@w_letra, @w_vocales )>0
        begin
           return @w_letra
           select @w_linea = null
        end
    end
    else
    begin
        if charindex(@w_letra, @w_vocales )<=0
        begin
           return @w_letra
           select @w_linea = null
        end
     end
end
return ('X')
end

GO
