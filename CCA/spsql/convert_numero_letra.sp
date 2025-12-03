/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                convert_numero_letra.sp                             */
/*      Procedimiento:          sp_convert_numero_letra                        */
/*      Disenado por:           Luis Gerardo Barron Cortes                           */
/*      Fecha de escritura:     22 de Feb 2019                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante           */
/*                              PROPOSITO                               */
/*      Aplica el abono normal para extraordinario o aprecancelacion    */
/*                                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*                                                                      */
/************************************************************************/
USE cob_cartera
GO
IF EXISTS(SELECT 1 FROM sysobjects WHERE type = 'P' AND name = 'sp_convert_numero_letra')
   DROP PROCEDURE dbo.sp_convert_numero_letra
GO
CREATE PROCEDURE sp_convert_numero_letra (
	@Numero NUMERIC(20,2),
	@tipo int,
	@resultado varchar(512) out
)
AS 
	SET NOCOUNT ON 
	DECLARE @lnEntero INT, 
	@lcRetorno VARCHAR(512), 
	@lnTerna INT, 
	@lcMiles VARCHAR(512), 
	@lcCadena VARCHAR(512), 
	@lnUnidades INT, 
	@lnDecenas INT, 
	@lnCentenas INT, 
	@lnFraccion INT,
	@cadenaCompleta varchar(512)
	
	SELECT @lnEntero = CAST(@Numero AS INT), 
	@lnFraccion = (@Numero - @lnEntero) * 100, 
	@lcRetorno = '', 
	@lnTerna = 1 
	
	WHILE @lnEntero > 0 
	BEGIN /* WHILE */ 
		-- Recorro terna por terna 
		SELECT @lcCadena = '' 
		SELECT @lnUnidades = @lnEntero % 10 
		SELECT @lnEntero = CAST(@lnEntero/10 AS INT) 
		SELECT @lnDecenas = @lnEntero % 10 
		SELECT @lnEntero = CAST(@lnEntero/10 AS INT) 
		SELECT @lnCentenas = @lnEntero % 10 
		SELECT @lnEntero = CAST(@lnEntero/10 AS INT) 

            SELECT @lcCadena = @lcCadena
            IF @lnUnidades = 1 AND @lnTerna = 1 SELECT @lcCadena = 'UNO ' + @lcCadena 
			IF @lnUnidades = 1 AND @lnTerna <> 1 SELECT @lcCadena = 'UN ' + @lcCadena 
			IF @lnUnidades = 2 SELECT @lcCadena = 'DOS ' + @lcCadena 
			IF @lnUnidades = 3 SELECT @lcCadena = 'TRES ' + @lcCadena 
			IF @lnUnidades = 4 SELECT @lcCadena = 'CUATRO ' + @lcCadena 
			IF @lnUnidades = 5 SELECT @lcCadena = 'CINCO ' + @lcCadena 
			IF @lnUnidades = 6 SELECT @lcCadena = 'SEIS ' + @lcCadena 
			IF @lnUnidades = 7 SELECT @lcCadena = 'SIETE ' + @lcCadena 
			IF @lnUnidades = 8 SELECT @lcCadena = 'OCHO ' + @lcCadena 
			IF @lnUnidades = 9 SELECT @lcCadena = 'NUEVE ' + @lcCadena 


		-- Analizo las decenas 


			IF @lnDecenas = 1 
			BEGIN			   
				IF @lnUnidades = 0 SELECT @lcCadena = 'DIEZ ' 
				ELSE IF @lnUnidades = 1 SELECT @lcCadena = 'ONCE ' 
				ELSE IF @lnUnidades = 2 SELECT @lcCadena = 'DOCE ' 
				ELSE IF @lnUnidades = 3 SELECT @lcCadena = 'TRECE ' 
				ELSE IF @lnUnidades = 4 SELECT @lcCadena = 'CATORCE ' 
				ELSE IF @lnUnidades = 5 SELECT @lcCadena = 'QUINCE ' 
				ELSE SELECT @lcCadena = 'DIECI' + @lcCadena 
			END
			
			SELECT @lcCadena = @lcCadena 
			IF @lnDecenas = 2 AND @lnUnidades = 0 SELECT @lcCadena = 'VEINTE ' + @lcCadena 
			IF @lnDecenas = 2 AND @lnUnidades <> 0 SELECT @lcCadena = 'VEINTI' + @lcCadena 
			IF @lnDecenas = 3 AND @lnUnidades = 0 SELECT @lcCadena = 'TREINTA ' + @lcCadena 
			IF @lnDecenas = 3 AND @lnUnidades <> 0 SELECT @lcCadena = 'TREINTA Y ' + @lcCadena 
			IF @lnDecenas = 4 AND @lnUnidades = 0 SELECT @lcCadena = 'CUARENTA ' + @lcCadena 
			IF @lnDecenas = 4 AND @lnUnidades <> 0 SELECT @lcCadena = 'CUARENTA Y ' + @lcCadena 
			IF @lnDecenas = 5 AND @lnUnidades = 0 SELECT @lcCadena = 'CINCUENTA ' + @lcCadena 
			IF @lnDecenas = 5 AND @lnUnidades <> 0 SELECT @lcCadena = 'CINCUENTA Y ' + @lcCadena 
			IF @lnDecenas = 6 AND @lnUnidades = 0 SELECT @lcCadena = 'SESENTA ' + @lcCadena 
			IF @lnDecenas = 6 AND @lnUnidades <> 0 SELECT @lcCadena = 'SESENTA Y ' + @lcCadena 
			IF @lnDecenas = 7 AND @lnUnidades = 0 SELECT @lcCadena = 'SETENTA ' + @lcCadena 
			IF @lnDecenas = 7 AND @lnUnidades <> 0 SELECT @lcCadena = 'SETENTA Y ' + @lcCadena 
			IF @lnDecenas = 8 AND @lnUnidades = 0 SELECT @lcCadena = 'OCHENTA ' + @lcCadena 
			IF @lnDecenas = 8 AND @lnUnidades <> 0 SELECT @lcCadena = 'OCHENTA Y ' + @lcCadena 
			IF @lnDecenas = 9 AND @lnUnidades = 0 SELECT @lcCadena = 'NOVENTA ' + @lcCadena 
			IF @lnDecenas = 9 AND @lnUnidades <> 0 SELECT @lcCadena = 'NOVENTA Y ' + @lcCadena 
			
		-- Analizo las centenas 

			SELECT @lcCadena = @lcCadena 		
			IF @lnCentenas = 1 AND @lnUnidades = 0 AND @lnDecenas = 0 SELECT @lcCadena = 'CIEN ' + 
			@lcCadena 
			IF @lnCentenas = 1 AND NOT(@lnUnidades = 0 AND @lnDecenas = 0) SELECT @lcCadena = 
			'CIENTO ' + @lcCadena 
			IF @lnCentenas = 2 SELECT @lcCadena = 'DOSCIENTOS ' + @lcCadena 
			IF @lnCentenas = 3 SELECT @lcCadena = 'TRESCIENTOS ' + @lcCadena 
			IF @lnCentenas = 4 SELECT @lcCadena = 'CUATROCIENTOS ' + @lcCadena 
			IF @lnCentenas = 5 SELECT @lcCadena = 'QUINIENTOS ' + @lcCadena 
			IF @lnCentenas = 6 SELECT @lcCadena = 'SEISCIENTOS ' + @lcCadena 
			IF @lnCentenas = 7 SELECT @lcCadena = 'SETECIENTOS ' + @lcCadena 
			IF @lnCentenas = 8 SELECT @lcCadena = 'OCHOCIENTOS ' + @lcCadena 
			IF @lnCentenas = 9 SELECT @lcCadena = 'NOVECIENTOS ' + @lcCadena 



			IF @lnTerna = 1 SELECT @lcCadena = @lcCadena 
			ELSE IF @lnTerna = 2 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) SELECT @lcCadena = 
			@lcCadena + ' MIL ' 
			ELSE IF @lnTerna = 3 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) AND 
			@lnUnidades = 1 AND @lnDecenas = 0 AND @lnCentenas = 0 SELECT @lcCadena = @lcCadena + ' 
			MILLON ' 
			ELSE IF @lnTerna = 3 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) AND 
			NOT (@lnUnidades = 1 AND @lnDecenas = 0 AND @lnCentenas = 0) SELECT @lcCadena = @lcCadena 
			+ ' MILLONES ' 
			ELSE IF @lnTerna = 4 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) SELECT @lcCadena = 
			@lcCadena + ' MIL MILLONES '
			ELSE SELECT @lcCadena = ''			
		-- Armo el retorno terna a terna 
		SELECT @lcRetorno = @lcCadena + @lcRetorno 
		SELECT @lnTerna = @lnTerna + 1 
	END --/ WHILE / 
    
	
	IF @lnTerna = 1 
		SELECT @lcRetorno = 'CERO' 
	
	--Se valida que operacion se va a hacer
	IF @tipo = 1
	BEGIN
		SELECT @resultado = RTRIM(@lcRetorno) + ' PESOS CON ' + LTRIM(STR(@lnFraccion,2)) + '/100' 
	END
	
	IF @tipo = 2
	BEGIN
		SELECT @cadenaCompleta = RTRIM(@lcRetorno) + ' PUNTO ',
					 @lnEntero = CAST(@lnFraccion AS INT),
					 @lcRetorno = '', 
					 @lnTerna = 1 
					 
		WHILE @lnEntero > 0 
		BEGIN /* WHILE */ 
			-- Recorro terna por terna 
			SELECT @lcCadena = '' 
			SELECT @lnUnidades = @lnEntero % 10 
			SELECT @lnEntero = CAST(@lnEntero/10 AS INT) 
			SELECT @lnDecenas = @lnEntero % 10 
			SELECT @lnEntero = CAST(@lnEntero/10 AS INT) 
			SELECT @lnCentenas = @lnEntero % 10 
			SELECT @lnEntero = CAST(@lnEntero/10 AS INT) 
			-- Analizo las unidades 

			SELECT @lcCadena = @lcCadena 
				IF @lnUnidades = 1 AND @lnTerna = 1 SELECT @lcCadena = 'UNO ' + @lcCadena 
				IF @lnUnidades = 1 AND @lnTerna <> 1 SELECT @lcCadena = 'UN ' + @lcCadena 
				IF @lnUnidades = 2 SELECT @lcCadena = 'DOS ' + @lcCadena 
				IF @lnUnidades = 3 SELECT @lcCadena = 'TRES ' + @lcCadena 
				IF @lnUnidades = 4 SELECT @lcCadena = 'CUATRO ' + @lcCadena 
				IF @lnUnidades = 5 SELECT @lcCadena = 'CINCO ' + @lcCadena 
				IF @lnUnidades = 6 SELECT @lcCadena = 'SEIS ' + @lcCadena 
				IF @lnUnidades = 7 SELECT @lcCadena = 'SIETE ' + @lcCadena 
				IF @lnUnidades = 8 SELECT @lcCadena = 'OCHO ' + @lcCadena 
				IF @lnUnidades = 9 SELECT @lcCadena = 'NUEVE ' + @lcCadena 
            
			SELECT @lcCadena = @lcCadena 
				IF @lnDecenas = 1
				BEGIN				
					IF @lnUnidades = 0 SELECT @lcCadena = 'DIEZ ' 
					ELSE IF @lnUnidades = 1 SELECT @lcCadena = 'ONCE ' 
					ELSE IF @lnUnidades = 2 SELECT @lcCadena = 'DOCE ' 
					ELSE IF @lnUnidades = 3 SELECT @lcCadena = 'TRECE ' 
					ELSE IF @lnUnidades = 4 SELECT @lcCadena = 'CATORCE ' 
					ELSE IF @lnUnidades = 5 SELECT @lcCadena = 'QUINCE ' 
					ELSE SELECT @lcCadena = 'DIECI' + @lcCadena 
				END 
				
				IF @lnDecenas = 2 AND @lnUnidades = 0 SELECT @lcCadena = 'VEINTE ' + @lcCadena 
				IF @lnDecenas = 2 AND @lnUnidades <> 0 SELECT @lcCadena = 'VEINTI' + @lcCadena 
				IF @lnDecenas = 3 AND @lnUnidades = 0 SELECT @lcCadena = 'TREINTA ' + @lcCadena 
				IF @lnDecenas = 3 AND @lnUnidades <> 0 SELECT @lcCadena = 'TREINTA Y ' + @lcCadena 
				IF @lnDecenas = 4 AND @lnUnidades = 0 SELECT @lcCadena = 'CUARENTA ' + @lcCadena 
				IF @lnDecenas = 4 AND @lnUnidades <> 0 SELECT @lcCadena = 'CUARENTA Y ' + @lcCadena 
				IF @lnDecenas = 5 AND @lnUnidades = 0 SELECT @lcCadena = 'CINCUENTA ' + @lcCadena 
				IF @lnDecenas = 5 AND @lnUnidades <> 0 SELECT @lcCadena = 'CINCUENTA Y ' + @lcCadena 
				IF @lnDecenas = 6 AND @lnUnidades = 0 SELECT @lcCadena = 'SESENTA ' + @lcCadena 
				IF @lnDecenas = 6 AND @lnUnidades <> 0 SELECT @lcCadena = 'SESENTA Y ' + @lcCadena 
				IF @lnDecenas = 7 AND @lnUnidades = 0 SELECT @lcCadena = 'SETENTA ' + @lcCadena 
				IF @lnDecenas = 7 AND @lnUnidades <> 0 SELECT @lcCadena = 'SETENTA Y ' + @lcCadena 
				IF @lnDecenas = 8 AND @lnUnidades = 0 SELECT @lcCadena = 'OCHENTA ' + @lcCadena 
				IF @lnDecenas = 8 AND @lnUnidades <> 0 SELECT @lcCadena = 'OCHENTA Y ' + @lcCadena 
				IF @lnDecenas = 9 AND @lnUnidades = 0 SELECT @lcCadena = 'NOVENTA ' + @lcCadena 
				IF @lnDecenas = 9 AND @lnUnidades <> 0 SELECT @lcCadena = 'NOVENTA Y ' + @lcCadena 

			SELECT @lcCadena = @lcCadena
				IF @lnCentenas = 1 AND @lnUnidades = 0 AND @lnDecenas = 0 SELECT @lcCadena = 'CIEN ' + 
				@lcCadena 
				IF @lnCentenas = 1 AND NOT(@lnUnidades = 0 AND @lnDecenas = 0) SELECT @lcCadena = 
				'CIENTO ' + @lcCadena 
				IF @lnCentenas = 2 SELECT @lcCadena = 'DOSCIENTOS ' + @lcCadena 
				IF @lnCentenas = 3 SELECT @lcCadena = 'TRESCIENTOS ' + @lcCadena 
				IF @lnCentenas = 4 SELECT @lcCadena = 'CUATROCIENTOS ' + @lcCadena 
				IF @lnCentenas = 5 SELECT @lcCadena = 'QUINIENTOS ' + @lcCadena 
				IF @lnCentenas = 6 SELECT @lcCadena = 'SEISCIENTOS ' + @lcCadena 
				IF @lnCentenas = 7 SELECT @lcCadena = 'SETECIENTOS ' + @lcCadena 
				IF @lnCentenas = 8 SELECT @lcCadena = 'OCHOCIENTOS ' + @lcCadena 
				IF @lnCentenas = 9 SELECT @lcCadena = 'NOVECIENTOS ' + @lcCadena 
			

				IF @lnTerna = 1 SELECT @lcCadena = @lcCadena 
				ELSE IF @lnTerna = 2 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) SELECT @lcCadena = 
				@lcCadena + ' MIL ' 
				ELSE IF @lnTerna = 3 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) AND 
				@lnUnidades = 1 AND @lnDecenas = 0 AND @lnCentenas = 0 SELECT @lcCadena = @lcCadena + ' 
				MILLON ' 
				ELSE IF @lnTerna = 3 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) AND 
				NOT (@lnUnidades = 1 AND @lnDecenas = 0 AND @lnCentenas = 0) SELECT @lcCadena = @lcCadena 
				+ ' MILLONES ' 
				ELSE IF @lnTerna = 4 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) SELECT @lcCadena = 
				@lcCadena + ' MIL MILLONES ' 
				ELSE SELECT @lcCadena = ''  
			
			-- Armo el retorno terna a terna 
			SELECT @lcRetorno = @lcCadena + @lcRetorno 
			SELECT @lnTerna = @lnTerna + 1 
		END /* WHILE */ 
		IF @lnTerna = 1 
			SELECT @lcRetorno = 'CERO' 
			
		SELECT @resultado = @cadenaCompleta + RTRIM(@lcRetorno) + ' PORCIENTO ' 
	END
return  0 

GO