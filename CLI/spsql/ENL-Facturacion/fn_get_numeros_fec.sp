

/********************************************************************/
/*    NOMBRE LOGICO: fn_get_numeros_fec                             */
/*    NOMBRE FISICO: fn_get_numeros_fec.sp                          */
/*    PRODUCTO: Clientes                                            */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.".         */
/********************************************************************/
/*                           PROPOSITO                              */
/*  Función para extraer solo numeros del NIT, NRC facturación      */
/*  electrónica de Cobis VS Ricoh                                               */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR            RAZON                       */
/*  28-JUL-2023        A. Quishpe       Emisión inicial             */
/********************************************************************/
use cob_externos
go

if exists (select 1
             from sysobjects
            where id = object_id('fn_get_numeros_fec'))
   drop function fn_get_numeros_fec

go

create function fn_get_numeros_fec (@valueAlphaNumeric varchar(256))
returns varchar(256) AS
begin
    declare @valorNumerico int
    select @valorNumerico = PATINDEX('%[^0-9]%', @valueAlphaNumeric)
    begin
        while @valorNumerico > 0
        begin
            select @valueAlphaNumeric = STUFF(@valueAlphaNumeric, @valorNumerico, 1, '' )
            select @valorNumerico = PATINDEX('%[^0-9]%', @valueAlphaNumeric )
        end
    end
    return isnull(@valueAlphaNumeric,0)
end
go
