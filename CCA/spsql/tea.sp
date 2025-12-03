/*tea.sp*****************************************************************/
/*      Archivo:                tea.sp                                  */
/*      Stored Procedure:       sp_tea                                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Luis Castellanos                        */
/*      Fecha de escritura:     29/AGO/2007                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA" del Ecuador.                                           */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Calculo de la Tasa Efectiva Anual (TEA)                         */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/*    29/AGO/07             LCA                   Emision Inicial       */
/************************************************************************/
use cob_cartera
go

if exists (select * from sysobjects where name = 'sp_tea')
   drop proc sp_tea
go

create proc sp_tea
   @i_tir                 float,
   @i_tdivi               smallint,
   @i_tplazo              smallint,
   @i_periodica           char(1),
   @i_pprom               int,
   @o_tasa                float out
as
declare
   @w_tir                 float,
   @w_tea                 float,
   @w_operacionca         int,
   @w_factor              money

if @i_tdivi = @i_tplazo begin
   select @w_factor = 360*1.0/@i_tplazo
   select @o_tasa = (power(1+@i_tir/(100*@w_factor),@w_factor) -1) * 100
end
else if @i_periodica = 'S' begin
   select @w_factor = periodo from ca_tasas_periodos where tdivi = @i_tdivi
   select @o_tasa = (power(1+@i_tir/(100*@w_factor),@w_factor) -1) * 100
end
else begin
   select @w_factor = 360.0/@i_pprom*1.0
   select @o_tasa = (power(1+@i_tir/(100*@w_factor),(@w_factor)) -1) * 100
end
--print 'tasa: ' + convert(VARCHAR,@o_tasa)
select @o_tasa = round(@o_tasa, 2)

SALIR:
return 0

go

