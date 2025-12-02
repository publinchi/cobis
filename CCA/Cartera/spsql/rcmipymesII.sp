/************************************************************************/
/*   Archivo:              rcmipymesII.sp                               */
/*   Stored procedure:     sp_rcmipymesII                               */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         XMA                                          */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Procesa y recalcula cada uno de los rubos MPYME, IVAMPYME de las   */
/*   obligaciones cargadas en el universo (sp_tabla_mpyme).             */
/*   RECALCULO MIPYMES, de tasa 7.82                                    */
/************************************************************************/
/*                                 MODIFICACIONES                       */
/*   FECHA           AUTOR             RAZON                            */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rcmipymesII')
   drop proc sp_rcmipymesII
go

create proc sp_rcmipymesII
as 

declare 
@w_error            int,
@w_sp_name          varchar(50),
@w_fecha_hoy        datetime
    

select 
@w_fecha_hoy = getdate(),
@w_sp_name   = 'sp_rcmipymesII'
               
exec  @w_error = cob_cartera..sp_tabla_mpymeII
if @w_error <> 0
begin
   PRINT 'Error ' + cast (@w_error as varchar) 
end


exec  @w_error = cob_cartera..sp_ajusta_mpymeII
if @w_error <> 0
begin
   PRINT 'Error ' + cast (@w_error as varchar)
end


return 0
go