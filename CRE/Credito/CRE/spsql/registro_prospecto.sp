/************************************************************************/
/*  Archivo:                registro_prospecto.sp                       */
/*  Stored procedure:       sp_registro_prospecto                       */
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

if exists(select 1 from sysobjects where name ='sp_registro_prospecto')
    drop proc sp_registro_prospecto
GO


create  proc sp_registro_prospecto(
@i_cliente           int            ,
@i_operacionca       int            ,
@i_fecha             datetime =null ,
@o_msg               descripcion
)
as
declare
@w_error           int,
@w_msg             varchar(255)


/*INICIALIZAR VARIABLES*/


if  exists(select 1 
           from cr_prospecto_contraoferta 
           where pr_cliente = @i_cliente 
           and pr_operacion = @i_operacionca )
   return 0

insert into cr_prospecto_contraoferta(
pr_cliente,   pr_operacion,     pr_fecha_proceso)
values(
@i_cliente ,  @i_operacionca,   @i_fecha)
      
if @@error <> 0
begin
  select @o_msg = 'NO SE PUDO INSERTAR EL DATO'
  return 143001
end

return 0


GO
