/***********************************************************************/
/*     Stored procedure:                sp_corregir_cupos              */
/*     Base de Datos:                   cob_credito                    */
/*     Producto:                        Credito                        */
/*     Fecha de Documentacion:          21/Nov/95                      */
/***********************************************************************/
/*                         IMPORTANTE                                  */
/*     Este programa es parte de los paquetes bancarios propiedad de   */
/*     'MACOSA'. Su uso no autorizado esta prohibido asi como          */
/*     cualquier autorizacion o agregado hecho por alguno de sus       */
/*     usuario sin el debido consentimiento por escrito de la          */
/*     Presidencia Ejecutiva de MACOSA o su representante              */
/***********************************************************************/
/*                          PROPOSITO                                  */
/*     Controlar que el valor utilizado de los cupos de credito sea    */
/*     correcto. De no ser asi, se reporta el error y se ajusta el     */
/*     saldo.                                                          */
/***********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_corregir_cupos')
   drop proc sp_corregir_cupos
go

create proc sp_corregir_cupos
@i_cliente       int     = 0
as 

declare 
@w_msg           descripcion,
@w_commit        char(1),
@w_cliente       int

/* No debe volver a ejecutarse */
/* JAR REQ 215. Paquete 2      */
return 0

go
















