@echo off
rem ***********************************************************************
rem *    ARCHIVO:         caastest.bat
rem *    NOMBRE LOGICO:   
rem *    PRODUCTO:        COB_CARTERA
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
rem *  realiza la actualizacion de estados en cuenta de cartera 
rem ***********************************************************************

echo off

if "%1"=="" goto ayuda
if "%2"=="" goto ayuda

cd C:\java\

java -jar C:\java\cloud-xmlgenerator-assets-1.0.0-jar-with-dependencies.jar %1 %2 %3 %4

goto fin

:ayuda
echo full.cmd [parametro 1] [parametro 2] [parametro 3] [parametro 4]
echo [parametro 1]: Operacion Programa
echo [parametro 2]: Fecha de Proceso
echo [parametro 3]: Codigo de Operacion
echo [parametro 4]: Codigo de Cliente
:fin
