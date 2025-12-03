/************************************************************************/
/*  Archivo:                diario_operaciones_ex.sp                    */
/*  Stored procedure:       sp_diario_operaciones_ex                    */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
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
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_diario_operaciones_ex')
    drop proc sp_diario_operaciones_ex
go

create proc sp_diario_operaciones_ex(
   @i_param1   varchar(255) = null 
)   
as
declare
@w_return	   int,
@w_fecha	   datetime

select @w_fecha = convert(datetime, @i_param1)

exec @w_return = cob_credito..sp_diario_operaciones
	 @i_fecha    = @w_fecha

return @w_return

GO

