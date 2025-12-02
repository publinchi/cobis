/************************************************************************/
/*  Archivo:                rfc_int_error.sp                            */
/*  Stored procedure:       sp_rfc_int_error                            */
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
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_rfc_int_error')
    drop proc sp_rfc_int_error
go

create proc sp_rfc_int_error (	
	@i_operacion		char(1),
	@i_rfc 		     	VARCHAR(30) = null

)
as


--Consulta
if @i_operacion = 'I'
begin
	IF NOT EXISTS(SELECT 1 FROM cob_credito..cr_rfc_int_error WHERE rfc_int_error=@i_rfc)
	BEGIN
	    insert into cob_credito..cr_rfc_int_error ( rfc_int_error)
        values                                    ( @i_rfc       )
        -- si no se puede insertar, error --
        if @@error != 0
        begin
            return 1
        END
    END
	
end


return 0


GO
