/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                repdatos.sp                             */
/*      Procedimiento:          fu_numletras.sp                         */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     14 de Feb 2019                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante           */
/*                              PROPOSITO                               */
/*      Conversion de Números a Letras                                  */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'CantidadConLetra')
   drop function [dbo].[CantidadConLetra]
go

CREATE FUNCTION [dbo].[CantidadConLetra]
(
    @Numero             Decimal(18,2)
)
RETURNS Varchar(180)
AS
BEGIN
    DECLARE @ImpLetra Varchar(180)
        DECLARE @lnEntero bigint,
                        @lcRetorno VARCHAR(512),
                        @lnTerna bigint,
                        @lcMiles VARCHAR(512),
                        @lcCadena VARCHAR(512),
                        @lnUnidades bigint,
                        @lnDecenas bigint,
                        @lnCentenas bigint,
                        @lnFraccion bigint
        SELECT  @lnEntero = CAST(@Numero AS bigint),
                        @lnFraccion = (@Numero - @lnEntero) * 100,
                        @lcRetorno = '',
                        @lnTerna = 1
  WHILE @lnEntero > 0
  BEGIN /* WHILE */
            -- Recorro terna por terna
            SELECT @lcCadena = ''
            SELECT @lnUnidades = @lnEntero % 10
            SELECT @lnEntero = CAST(@lnEntero/10 AS bigint)
            SELECT @lnDecenas = @lnEntero % 10
            SELECT @lnEntero = CAST(@lnEntero/10 AS bigint)
            SELECT @lnCentenas = @lnEntero % 10
            SELECT @lnEntero = CAST(@lnEntero/10 AS bigint)
            -- Analizo las unidades
            --SELECT @lcCadena =
            --CASE /* UNIDADES */
            --  WHEN @lnUnidades = 1 THEN 'UN ' + @lcCadena
            --  WHEN @lnUnidades = 2 THEN 'DOS ' + @lcCadena
            --  WHEN @lnUnidades = 3 THEN 'TRES ' + @lcCadena
            --  WHEN @lnUnidades = 4 THEN 'CUATRO ' + @lcCadena
            --  WHEN @lnUnidades = 5 THEN 'CINCO ' + @lcCadena
            --  WHEN @lnUnidades = 6 THEN 'SEIS ' + @lcCadena
            --  WHEN @lnUnidades = 7 THEN 'SIETE ' + @lcCadena
            --  WHEN @lnUnidades = 8 THEN 'OCHO ' + @lcCadena
            --  WHEN @lnUnidades = 9 THEN 'NUEVE ' + @lcCadena
            --  ELSE @lcCadena
            --END /* UNIDADES */
            if @lnUnidades = 1
               SELECT @lcCadena = 'UN ' + @lcCadena
            if @lnUnidades = 2 
               SELECT @lcCadena = 'DOS ' + @lcCadena
            if @lnUnidades = 3 
               SELECT @lcCadena = 'TRES ' + @lcCadena
            if @lnUnidades = 4 
               SELECT @lcCadena = 'CUATRO ' + @lcCadena
            if @lnUnidades = 5 
               SELECT @lcCadena = 'CINCO ' + @lcCadena
            if @lnUnidades = 6 
               SELECT @lcCadena = 'SEIS ' + @lcCadena
            if @lnUnidades = 7 
               SELECT @lcCadena = 'SIETE ' + @lcCadena
            if @lnUnidades = 8 
               SELECT @lcCadena = 'OCHO ' + @lcCadena
            if @lnUnidades = 9 
               SELECT @lcCadena = 'NUEVE ' + @lcCadena
 
            -- Analizo las decenas
            --SELECT @lcCadena =
            --CASE /* DECENAS */
            --  WHEN @lnDecenas = 1 THEN
            --    CASE @lnUnidades
            --      WHEN 0 THEN 'DIEZ '
            --      WHEN 1 THEN 'ONCE '
            --      WHEN 2 THEN 'DOCE '
            --      WHEN 3 THEN 'TRECE '
            --      WHEN 4 THEN 'CATORCE '
            --      WHEN 5 THEN 'QUINCE '
            --      WHEN 6 THEN 'DIECISEIS '
            --      WHEN 7 THEN 'DIECISIETE '
            --      WHEN 8 THEN 'DIECIOCHO '
            --      WHEN 9 THEN 'DIECINUEVE '
            --    END
            --  WHEN @lnDecenas = 2 THEN
            --  CASE @lnUnidades
            --    WHEN 0 THEN 'VEINTE '
            --    ELSE 'VEINTI' + @lcCadena
            --  END
            --  WHEN @lnDecenas = 3 THEN
            --  CASE @lnUnidades
            --    WHEN 0 THEN 'TREINTA '
            --    ELSE 'TREINTA Y ' + @lcCadena
            --   END
            --  WHEN @lnDecenas = 4 THEN
            --   CASE @lnUnidades
            --        WHEN 0 THEN 'CUARENTA'
            --        ELSE 'CUARENTA Y ' + @lcCadena
            --    END
            --  WHEN @lnDecenas = 5 THEN
            --    CASE @lnUnidades
            --        WHEN 0 THEN 'CINCUENTA '
            --        ELSE 'CINCUENTA Y ' + @lcCadena
            --    END
            --  WHEN @lnDecenas = 6 THEN
            --    CASE @lnUnidades
            --        WHEN 0 THEN 'SESENTA '
            --        ELSE 'SESENTA Y ' + @lcCadena
            --    END
            --  WHEN @lnDecenas = 7 THEN
            --     CASE @lnUnidades
            --        WHEN 0 THEN 'SETENTA '
            --       ELSE 'SETENTA Y ' + @lcCadena
            --     END
            --  WHEN @lnDecenas = 8 THEN
            --    CASE @lnUnidades
            --        WHEN 0 THEN 'OCHENTA '
            --        ELSE  'OCHENTA Y ' + @lcCadena
            --    END
            --  WHEN @lnDecenas = 9 THEN
            --    CASE @lnUnidades
            --        WHEN 0 THEN 'NOVENTA '
            --        ELSE 'NOVENTA Y ' + @lcCadena
            --    END
            --  ELSE @lcCadena
            --END /* DECENAS */
            if @lnDecenas = 1
            begin
               if @lnUnidades = 0 
                  select @lcCadena = 'DIEZ '
               if @lnUnidades = 1 
                  select @lcCadena = 'ONCE '
               if @lnUnidades = 2 
                  select @lcCadena = 'DOCE '
               if @lnUnidades = 3 
                  select @lcCadena = 'TRECE '
               if @lnUnidades = 4 
                  select @lcCadena = 'CATORCE '
               if @lnUnidades = 5 
                  select @lcCadena = 'QUINCE '
               if @lnUnidades = 6
                  select @lcCadena = 'DIECISEIS '
               if @lnUnidades = 7 
                  select @lcCadena = 'DIECISIETE '
               if @lnUnidades = 8 
                  select @lcCadena = 'DIECIOCHO '
               if @lnUnidades = 9 
                  select @lcCadena = 'DIECINUEVE '
            end
            if @lnDecenas = 2
            begin
               if @lnUnidades = 0
                  select @lcCadena = 'VEINTE '
               else
                  select @lcCadena = 'VEINTI' + @lcCadena
            end
            if @lnDecenas = 3
            begin
               if @lnUnidades = 0
                  select @lcCadena = 'TREINTA '
               else
                  select @lcCadena = 'TREINTA Y ' + @lcCadena
            end
            if @lnDecenas = 4
            begin
               if @lnUnidades = 0
                  select @lcCadena = 'CUARENTA'
               else
                  select @lcCadena = 'CUARENTA Y ' + @lcCadena
            end
            if @lnDecenas = 5
            begin
               if @lnUnidades = 0
                  select @lcCadena = 'CINCUENTA '
               else
                  select @lcCadena = 'CINCUENTA Y ' + @lcCadena
            end
            if @lnDecenas = 6
            begin
               if @lnUnidades = 0
                  select @lcCadena = 'SESENTA '
               else
                  select @lcCadena = 'SESENTA Y ' + @lcCadena
            end
            if @lnDecenas = 7
            begin
               if @lnUnidades = 0
                  select @lcCadena = 'SETENTA '
               else
                  select @lcCadena = 'SETENTA Y ' + @lcCadena
            end
            if @lnDecenas = 8
            begin
               if @lnUnidades = 0
                  select @lcCadena = 'OCHENTA '
               else
                  select @lcCadena = 'OCHENTA Y ' + @lcCadena
            end
            if @lnDecenas = 9
            begin
               if @lnUnidades = 0
                  select @lcCadena = 'NOVENTA '
               else
                  select @lcCadena = 'NOVENTA Y ' + @lcCadena
            end

            -- Analizo las centenas
            --SELECT @lcCadena =
            --CASE /* CENTENAS */
            --  WHEN @lnCentenas = 1 THEN 'CIENTO ' + @lcCadena
            --  WHEN @lnCentenas = 2 THEN 'DOSCIENTOS ' + @lcCadena
            --  WHEN @lnCentenas = 3 THEN 'TRESCIENTOS ' + @lcCadena
            --  WHEN @lnCentenas = 4 THEN 'CUATROCIENTOS ' + @lcCadena
            --  WHEN @lnCentenas = 5 THEN 'QUINIENTOS ' + @lcCadena
            --  WHEN @lnCentenas = 6 THEN 'SEISCIENTOS ' + @lcCadena
            --  WHEN @lnCentenas = 7 THEN 'SETECIENTOS ' + @lcCadena
            --  WHEN @lnCentenas = 8 THEN 'OCHOCIENTOS ' + @lcCadena
            --  WHEN @lnCentenas = 9 THEN 'NOVECIENTOS ' + @lcCadena
            --  ELSE @lcCadena
            --END /* CENTENAS */
             
            if @lnCentenas = 1 
               select @lcCadena = 'CIENTO ' + @lcCadena
            if @lnCentenas = 2 
               select @lcCadena = 'DOSCIENTOS ' + @lcCadena
            if @lnCentenas = 3 
               select @lcCadena = 'TRESCIENTOS ' + @lcCadena
            if @lnCentenas = 4 
               select @lcCadena = 'CUATROCIENTOS ' + @lcCadena
            if @lnCentenas = 5 
               select @lcCadena = 'QUINIENTOS ' + @lcCadena
            if @lnCentenas = 6 
               select @lcCadena = 'SEISCIENTOS ' + @lcCadena
            if @lnCentenas = 7 
               select @lcCadena = 'SETECIENTOS ' + @lcCadena
            if @lnCentenas = 8 
               select @lcCadena = 'OCHOCIENTOS ' + @lcCadena
            if @lnCentenas = 9 
               select @lcCadena = 'NOVECIENTOS ' + @lcCadena

            -- Analizo la terna
            --SELECT @lcCadena =
            --CASE /* TERNA */
            --  WHEN @lnTerna = 1 THEN @lcCadena
            --  WHEN @lnTerna = 2 THEN @lcCadena + 'MIL '
            --  WHEN @lnTerna = 3 THEN @lcCadena + 'MILLONES '
            --  WHEN @lnTerna = 4 THEN @lcCadena + 'MIL '
            --  ELSE ''
            --END /* TERNA */
            if @lnTerna = 1
               select @lcCadena = @lcCadena 
            else
               if @lnTerna = 2 
                  select @lcCadena = @lcCadena + 'MIL '
               else
                  if @lnTerna = 3 
                     select @lcCadena = @lcCadena + 'MILLONES '
                  else
                     if @lnTerna = 4 
                        select @lcCadena = @lcCadena + 'MIL '
                     else
                        select @lcCadena = ''

            -- Armo el retorno terna a terna
            SELECT @lcRetorno = @lcCadena  + @lcRetorno
            SELECT @lnTerna = @lnTerna + 1
   END /* WHILE */
   IF @lnTerna = 1
       SELECT @lcRetorno = 'CERO'
   DECLARE @sFraccion VARCHAR(15)
   SET @sFraccion = '00' + LTRIM(CAST(@lnFraccion AS varchar))
   SELECT @ImpLetra = LOWER(RTRIM(@lcRetorno))
   RETURN @ImpLetra
END;