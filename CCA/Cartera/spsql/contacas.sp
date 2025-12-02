/************************************************************************/
/*      Archivo:                contacas.sp                             */
/*      Stored procedure:       sp_contabilidad_cas                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           F.Quintero                              */
/*      Fecha de escritura:     Dic-2005                                */
/************************************************************************/
/*      IMPORTANTE                                                      */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Presenta los una lista de estado de cartera (ficticios)         */
/*      1 = activa, 2 Castigada                                         */
/*      NR 389                                                          */
/*      Transaccion NRO. 7442                                           */
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_cas')
   drop proc sp_contabilidad_cas
go

create proc sp_contabilidad_cas
@i_criterio1   char(10) = null
as
select 'Estado' = 1, 'Descripcion' = 'Cartera Activa'
union
select 'Estado' = 2, 'Descripcion' = 'Cartera Castigada'
return 0
go
