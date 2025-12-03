@echo off
rem ***********************************************************************
rem *    ARCHIVO:         full.cmd
rem *    NOMBRE LOGICO:   full.cmd
rem *    PRODUCTO:        COBIS
rem ***********************************************************************
rem *                     IMPORTANTE
rem * Esta aplicacion es parte de los paquetes bancarios propiedad       
rem * de COBISCorp.                                                      
rem * Su uso no    autorizado queda  expresamente   prohibido asi como   
rem * cualquier    alteracion o  agregado  hecho por    alguno  de sus   
rem * usuarios sin el debido consentimiento por   escrito de COBISCorp.  
rem * Este programa esta protegido por la ley de   derechos de autor     
rem * y por las    convenciones  internacionales   de  propiedad inte-   
rem * lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para
rem * obtener ordenes  de secuestro o  retencion y para  perseguir       
rem * penalmente a los autores de cualquier   infraccion.                
rem ***********************************************************************
rem *                     PROPOSITO
rem *   Instalacion general de COBIS BackEnd Central
rem ***********************************************************************
rem *                     MODIFICACIONES
rem *   FECHA        AUTOR      RAZON
rem *  30/Abr/2019   rgalván    Emision Inicial
@echo off

set server_port = %3

if "%1"=="" goto ayuda
if "%2"=="" goto ayuda
if server_port =="" goto ayuda
if "%4"=="" goto ayuda
if "%5"=="" goto ayuda

@echo off
if exist %5\*.error (
  del %5\*.error
)
if not exist %4\log ( 
md %4\log
)
set contador=0
for %%i in (%4\*.sp) do (
  echo iniciando > %5\%%~ni.error
  set /a contador+=1
)
for %%j in (1 2 3) do (
    for %%k in (%5\*.error) do (
        echo Ejecutando %%~nk.sp
        del %5\%%~nk.error
        sqlcmd -U%1 -P%2 -S%3 -i %4\%%~nk.sp -m1 -o  %5\%%~nk.error
        for /F %%l in (%5\%%~nk.error) do (
            echo ERROR ... > %5\%%~nk.error2
        )
        if not exist %5\%%~nk.error2 (
            del %5\%%~nk.error
        ) else (
            echo ----- %%~nk.sp tiene errores
            del %5\%%~nk.error2
        )
    )
)
goto fin

:ayuda
echo full.cmd [parametro 1] [parametro 2] [parametro 3]  [parametro 4] [parametro 5]
echo donde:
echo [parametro 1]: usuario de BDD
echo [parametro 2]: password del usuario de BDD
echo [parametro 3]: "IP_Servidor,Puerto"
echo [parametro 4]: directorio de los fuentes
echo [parametro 5]: directorio del log de instalacion
:fin
