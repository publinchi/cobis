/********************************************************************/
/*    NOMBRE LOGICO:       fn_parsea_identificacion                 */
/*    NOMBRE FISICO:       fn_parsea_identificacion.sp              */
/*    PRODUCTO:            CLIENTES                                 */
/*    Disenado por:        E. Báez                                  */
/*    Fecha de escritura:  28-Jun-2023                              */
/* ******************************************************************/
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
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                           PROPOSITO                              */
/*  Función para parsear la identificación de un cliente y guardar  */
/*  retornar el valor convertido                                    */
/* ******************************************************************/
/*               MODIFICACIONES                                     */
/*   FECHA       	AUTOR                RAZON                      */
/*   28-Jun-2023   	E. Báez	             S849151 se crea la función */
/*                                       para menejo de máscara    */
/*                                       del tipo de identificación */
/********************************************************************/

use cobis
GO

if exists (select * from sysobjects where name = 'fn_parsea_identificacion')
    drop function fn_parsea_identificacion
go

CREATE FUNCTION fn_parsea_identificacion
(
    @inputText VARCHAR(255),
    @pattern VARCHAR(255)
)
RETURNS VARCHAR(30)
AS
BEGIN
    DECLARE @outputText VARCHAR(30) = '';
    DECLARE @inputLength INT = LEN(@inputText);
    DECLARE @patternLength INT = LEN(@pattern);
    DECLARE @i INT = 1;
    DECLARE @j INT = 1;
    WHILE @i <= @patternLength
    BEGIN
        IF @j <= @inputLength
        BEGIN
            IF SUBSTRING(@pattern, @i, 1) in ('#', '&', '?')
            BEGIN
                SET @outputText = CONCAT(@outputText, SUBSTRING(@inputText, @j, 1));
                SET @j = @j + 1;
            END
            ELSE
            BEGIN
                SET @outputText = CONCAT(@outputText, SUBSTRING(@pattern, @i, 1));
            END
        END
        ELSE
        BEGIN
            SET @outputText = CONCAT(@outputText, SUBSTRING(@pattern, @i, 1));
        END
        SET @i = @i + 1;
    END
    RETURN @outputText;
END
	