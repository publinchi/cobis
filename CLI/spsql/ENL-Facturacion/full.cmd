echo off
rem ********************************************************
rem *    ARCHIVO:         full.cmd         
rem *    NOMBRE LOGICO:   full.cmd         
rem *    PRODUCTO:        Clientes-DTE         
rem ********************************************************
rem *                     IMPORTANTE         
rem *   Esta aplicacion es parte de los  paquetes bancarios
rem *   propiedad de COBISCORP
rem *   Su uso no autorizado queda  expresamente  prohibido
rem *   asi como cualquier alteracion o agregado hecho  por
rem *   alguno de sus usuarios sin el debido consentimiento
rem *   por escrito de COBISCORP.             
rem *   Este programa esta protegido por la ley de derechos
rem *   de autor y por las convenciones  internacionales de
rem *   propiedad intelectual.  Su uso  no  autorizado dara
rem *   derecho a COBISCORP para obtener ordenes  de secues
rem *   tro o retencion y para perseguir  penalmente a  los
rem *   autores de cualquier infraccion.         
rem ********************************************************
rem *                     PROPOSITO         
rem *   Compilacion de stored procedures de Clientes-DTE en 
rem *   cob_externos
rem ********************************************************
rem *                     MODIFICACIONES         
rem *   FECHA        AUTOR           RAZON         
rem *   22/Jun/2023  A. Quishpe     Emision Inicial
rem ********************************************************

rem Parametros:
rem %1 - Login
rem %2 - Password
rem %3 - Servidor SQL

set ERROR3=%3

if "%ERROR3%" == "" goto ayuda

if "%1" == "" goto ayuda
if "%2" == "" goto ayuda
if "%1" == "?" goto ayuda
if "%2" == "?" goto ayuda

if exist %5\*.out (
  del /F /Q %5\*.out
)

echo Compilacion de stored procedures 

for /L %%i in (1,1,3) do (
	echo Compilacion parte %%i
	for %%f in (*.sp) do ( 
		echo Compilando %%f
		sqlcmd -U%1 -P%2 -S%3 -i %%f -o %%f.out 
	)
)

echo Fin.
goto fin

:ayuda
echo full.cmd [parametro 1] [parametro 2] [parametro 3]
echo [parametro 1]: usuario de base de datos
echo [parametro 2]: password del usuario de de base de datos
echo [parametro 3]: nombre del servidor de base de datos
echo [parametro 4]: directorio de los fuentes de instalacion
echo [parametro 5]: directorio de los logs


:fin