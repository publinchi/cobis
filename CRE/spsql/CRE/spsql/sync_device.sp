/************************************************************************/
/*  Archivo:                sync_device.sp                              */
/*  Stored procedure:       sp_sync_device                              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*  Genera archivo con dependecia de cob_sincroniza..sp_sinc_arch_xml   */
/*  y cobis..sp_xml_grupos                                              */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_sync_device')
    drop proc sp_sync_device
go

CREATE proc sp_sync_device (
    @s_user		login = null,
    @i_oficial 	INT
)
AS

PRINT '@i_oficial>>'+convert(VARCHAR(10),@i_oficial)
PRINT '@s_user>>'+@s_user

--sincronizar clientes

EXEC cob_sincroniza..sp_sinc_arch_xml
@i_param1 ='Q',
@i_param2=0,
@i_param3=4,
@i_oficial=@i_oficial

--sincronizar grupos
EXEC cobis..sp_xml_grupos
@i_oficial=@i_oficial,
@s_user=@s_user,
@i_operacion = 'O'

--sincronizar solicitudes
EXEC cob_credito..sp_sync_cuestionarios
@i_oficial=@i_oficial

--sincronizar cuestionarios
EXEC cob_credito..sp_sync_solicitudes
@i_oficial=@i_oficial


GO
