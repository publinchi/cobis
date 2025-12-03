/********************************************************************/
/*    NOMBRE LOGICO:         sp_tanqueo_dte                         */
/*    NOMBRE FISICO:         sp_tanqueo_dte.sp                      */
/*    PRODUCTO:              Facturacion Electronica                */
/*    Disenado por:          Armando Quishpe                        */
/*    Fecha de escritura:    31-Marzo-2023                          */
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
/* Sp que permite crear un guid para la facturacion electronica     */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  20-Abr-2023      A. Quishpe       Emision Inicial               */
/********************************************************************/
USE cob_externos
GO

if object_id('sp_retorno_registro_fac') is not null
begin
      drop procedure sp_retorno_registro_fac
end
go

create proc sp_retorno_registro_fac( 
       @t_show_version  bit          = 0,
	   @i_cadena      VARCHAR(max),
       @o_valor_1     VARCHAR(255) = '' OUT,
	   @o_valor_2     VARCHAR(255) = '' OUT,
	   @o_valor_3     VARCHAR(255) = '' OUT,
	   @o_valor_4     VARCHAR(255) = '' OUT,
	   @o_valor_5     VARCHAR(255) = '' OUT,
	   @o_valor_6     VARCHAR(255) = '' OUT,
	   @o_valor_7     VARCHAR(255) = '' OUT,
	   @o_valor_8     VARCHAR(255) = '' OUT
)
as
declare 
    @w_sp_name    varchar(30),
    @w_pos        int,
    @w_valor      varchar(255), 
    @w_contador   int,    
    @w_valor_1    VARCHAR(255),
    @w_valor_2    VARCHAR(255),
    @w_valor_3    VARCHAR(255),
    @w_valor_4    VARCHAR(255),
	@w_valor_5    VARCHAR(255),
	@w_valor_6    VARCHAR(255),
	@w_valor_7    VARCHAR(255),
	@w_valor_8    VARCHAR(255)


select
@w_sp_name = 'sp_retorno_registro_fac'

if @t_show_version = 1
begin
  print 'Version: sp_retorno_registro_fac: 5.0.0.0 '
  return 0
end

SELECT @w_contador = 0
while @i_cadena > ''
BEGIN
	SELECT @w_pos = charindex('|', @i_cadena)
    IF @w_pos = 0            
        SELECT @w_valor = ltrim(rtrim(@i_cadena))    
    ELSE
        SELECT @w_valor = ltrim(rtrim(substring(@i_cadena, 1, @w_pos -1)))    
	
    IF ltrim(rtrim(@i_cadena)) = ltrim(rtrim(@w_valor))
        SELECT @i_cadena = '|'    
    ELSE
        SELECT @i_cadena = substring(@i_cadena, @w_pos+1,len(@i_cadena))    
	
    IF ltrim(rtrim(@i_cadena)) = '|'
        SELECT @i_cadena = ''    
	
	IF @w_contador = 0
    BEGIN
        SELECT @w_valor_1 = @w_valor
    END
    ELSE IF @w_contador = 1
    BEGIN
        SELECT @w_valor_2 = @w_valor
    END
    ELSE IF @w_contador = 2
    BEGIN
        SELECT @w_valor_3 = @w_valor
    END
    ELSE IF @w_contador = 3
    BEGIN
        SELECT @w_valor_4 = @w_valor
    END
    ELSE IF @w_contador = 4
    BEGIN
        SELECT @w_valor_5 = @w_valor
    END
	ELSE IF @w_contador = 5
    BEGIN
        SELECT @w_valor_6 = @w_valor
    END
	ELSE IF @w_contador = 6
    BEGIN
        SELECT @w_valor_7 = @w_valor
    END
	ELSE IF @w_contador = 7
    BEGIN
        SELECT @w_valor_8 = @w_valor
    END
	   
    SELECT @w_contador = @w_contador + 1;
END

SELECT  @o_valor_1  = @w_valor_1,
        @o_valor_2  = @w_valor_2,
        @o_valor_3  = @w_valor_3,
        @o_valor_4  = @w_valor_4,
        @o_valor_5  = @w_valor_5,
	    @o_valor_6  = @w_valor_6,
	    @o_valor_7  = @w_valor_7,
	    @o_valor_8  = @w_valor_8

return 0
go
