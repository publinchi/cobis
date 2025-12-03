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
/*  Para calcular el CURP y RFC (mexico), encuentra homoclave           */
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

if exists(select 1 from sysobjects where name = 'fn_homoclave_rfc')
   drop function fn_homoclave_rfc
go
create function fn_homoclave_rfc(
@i_primer_apellido       varchar(100),
@i_segundo_apellido      varchar(100),
@i_nombres              varchar(100)
)
returns varchar(100)
as
begin
    declare @w_compuesto  varchar(300)
    declare @w_strCharsHc  varchar(300)
    declare @w_strCadena  varchar(300)

declare @w_i int,
    @w_intNum1  int,
    @w_intNum2  int,
    @w_intSum   int,
    @w_int3     int,
    @w_intQuo   int,
    @w_intRem   int,
    @w_strChr   varchar


    select @w_strCharsHc = '123456789ABCDEFGHIJKLMNPQRSTUVWXYZ'
    select @w_strCadena = '0'
    select @w_compuesto = @i_primer_apellido + ' ' + @i_segundo_apellido + ' ' + @i_nombres

    while len(@w_compuesto) > 0
    begin
        select @w_strChr = substring(@w_compuesto, 1, 1)
        select @w_compuesto = substring(@w_compuesto, 2, 100)
        --Convierte la letra a un numero de dos  digitos.
        if @w_strChr in (' ', '-')  select @w_strCadena = @w_strCadena + '00'
        if @w_strChr in ( 'Ü', '&')  select @w_strCadena = @w_strCadena + '10'
        if @w_strChr in ('Ñ')  select @w_strCadena = @w_strCadena + '40'
        if @w_strChr like ('[A-I]') select @w_strCadena = @w_strCadena + convert(varchar,(ascii(@w_strChr) - 54))
        if @w_strChr like ('[J-R]') select @w_strCadena = @w_strCadena + convert(varchar,(ascii(@w_strChr) - 53))
        if @w_strChr like ('[S-Z]') select @w_strCadena = @w_strCadena + convert(varchar,(ascii(@w_strChr) - 51))
        if @w_strChr like ('[0-9]') select @w_strCadena = @w_strCadena + '0'+ @w_strChr
    end

select @w_i = 1,
       @w_intSum = 0
while @w_i <= (len(@w_strCadena) - 1)
begin
    select @w_intNum1 = convert(int,substring(@w_strCadena, @w_i, 2))
    select @w_intNum2 = convert(int,substring(@w_strCadena, @w_i + 1, 1))
    select @w_intSum = @w_intSum + @w_intNum1 * @w_intNum2
    select @w_i = @w_i + 1
end

select @w_int3 = convert(int, right(convert(varchar,@w_intSum), 3))

select @w_intQuo = @w_int3 / 34
select @w_intRem = @w_int3 % 34

--'La homoclave se consigue usando el 'cociente y el residuo.

--'Se usa el cociente y residio para 'buscar las letras del homoclave 'dentro de la tabla de caracteres 'permitidos.
    return (substring(@w_strCharsHc, @w_intQuo + 1, 1) + substring(@w_strCharsHc, @w_intRem + 1, 1))
end
go
