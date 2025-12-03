
/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Andy Gonzalez                           */
/*      Fecha de escritura:     Noviembre 2018                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera la distribucion para la LINEA de Credito Rotativa        */
/*      														         */
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dist_rotativa')
   drop proc sp_dist_rotativa
go

create proc sp_dist_rotativa
   @i_operacionca int = null

as declare 
@w_error  int 



insert into ca_amortizacion_tmp  with (rowlock) (
amt_operacion,             amt_dividendo,             amt_concepto,
amt_cuota,                 amt_gracia,                amt_pagado,
amt_acumulado,             amt_estado,                amt_periodo,
amt_secuencia)
values(
@i_operacionca,              1,                      'CAP',
0,                           0,                       0,
0,                           0,                       0,
1 )


if @@error <> 0
   begin
   select @w_error = 710001
   goto ERROR
end



return 0 

ERROR:
return @w_error
go