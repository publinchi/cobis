/************************************************************************/
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
/*  Para calcular el CURP y RFC (mexico), encuentra digito verificador  */
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

if exists(select 1 from sysobjects where name = 'fn_digito_rfc')
   drop function fn_digito_rfc
go
create function fn_digito_rfc(
@i_rfc varchar(100)
)
returns varchar(100)
as
begin

declare
@w_i            int,
@w_strChars     varchar(100),
@w_intIdx       int,
@w_strBuffer    varchar(100),
@w_intTemp      int,
@w_strCh        varchar(100),
@w_strDV        varchar(100),
@w_intSumas     int,
@w_intDV        int

select @w_strChars = '0123456789ABCDEFGHIJKLMN&OPQRSTUVWXYZ*'

select @w_i = 1,
       @w_intSumas = 0,
       @w_strBuffer= ''
while @w_i <= Len(@i_rfc)
begin
    select @w_strCh = substring(@i_rfc, @w_i, 1)
    if @w_strCh = ' ' select @w_strCh = '*' else select @w_strCh = @w_strCh
    select @w_intIdx    = charindex(@w_strCh, @w_strChars) - 1
    select @w_intSumas  = @w_intSumas + @w_intIdx * (14 - @w_i)
    select @w_strBuffer = @w_strBuffer + replicate('0', 2 - len(convert(varchar,@w_intIdx))) + convert(varchar,@w_intIdx)
    select @w_i         = @w_i + 1
end

select @w_intDV = 0

If @w_intSumas % 11 = 0
    select @w_strDV = '0'
Else
    select @w_intDV = 11 - @w_intSumas % 11

If @w_intDV > 9
    select @w_strDV = 'A'
Else
    select @w_strDV = convert(varchar,@w_intDV)

    return (@w_strDV)
end
go

