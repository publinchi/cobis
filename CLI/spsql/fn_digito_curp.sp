/************************************************************************/
/*   Archivo           : fn_digito_curp.sp                              */
/*   Stored procedure  : fn_digito_curp                                 */
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
/*   07/Jul/2020    FSAP                 Estandarizacion Clientes       */
/************************************************************************/
use cobis
go

SET ANSI_NULLS OFF
go
SET QUOTED_IDENTIFIER OFF
go

if exists(select 1 from sysobjects where name = 'fn_digito_curp')
   drop function fn_digito_curp
go
create function fn_digito_curp(
@i_curp varchar(100)
)
returns varchar(100)
as
begin
declare
@w_arreglo1   varchar (100),
@w_arreglo2   varchar (100),
@w_char       varchar (100),
@w_valores    varchar (100),
@w_l_acum     varchar (100) ,
@w_str_dv     varchar (100),
@w_pos        int,
@w_l_residuo  int,
@w_l_valor    int,
@w_i          int

select @w_arreglo1 = '0123456789ABCDEFGHIJKLMN-OPQRSTUVWXYZ*'

---- ciclo para obtener los valores de cada caracter de la curp en 'arreglo2()
---- y armar una cadena con estos valores
select @w_i = 1
select @w_valores = ''
while @w_i <= len(@i_curp)
begin
    select @w_char = substring(@i_curp, @w_i, 1) ----caracter actual
    if @w_char = ' '  select @w_char = '*'

    ----busca posicion del caracter dentro del 'arreglo1'
    select @w_pos = charindex(@w_char, @w_arreglo1) - 1

    if @w_pos > -1
    begin
        select @w_valores = @w_valores + replicate('0', 2 - len(convert(varchar,@w_pos))) + convert(varchar,@w_pos)
    end
    else
    begin
        select @w_valores = @w_valores + '00'
    end

    select @w_i = @w_i + 1
end

----Sumatoria de valores
select @w_i = 1
select @w_l_acum = ''
while @w_i <= 17
begin
    select @w_l_acum = @w_l_acum  + (substring(@w_valores, @w_i * 2 - 1, 2)) * (19 - @w_i)
    select @w_i = @w_i + 1
end

if @w_l_acum % 10 = 0
    select @w_str_dv = '0'
else
begin
    select @w_l_valor = 10 - (@w_l_acum % 10)
    select @w_str_dv = right(convert(varchar, @w_l_valor),1)
end

    return (@w_str_dv)
end
go

