/************************************************************************/
/*      Archivo:                buscadisponiblesanio.sp                 */
/*      Stored procedure:       sp_buscar_disponibles_anio              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     May. 2014                               */
/*      Nro. procedure          3                                       */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Busca los parámetros disponibles para un año.                   */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-05-13     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_buscar_disponibles_anio')
   drop proc sp_buscar_disponibles_anio
go

---NR000392
create proc sp_buscar_disponibles_anio
@i_operacion               int,
@i_fecha_ini_anio          datetime,
@o_fecha_fin_anio          datetime    OUTPUT,
@o_nro_disponibles_anio    smallint    OUTPUT,
@o_fecha_disponible_ini    datetime    OUTPUT,
@o_fecha_disponible_fin    datetime    OUTPUT
as
begin
   select @o_nro_disponibles_anio = count(1),
          @o_fecha_disponible_ini = min(dt_fecha),
          @o_fecha_disponible_fin = max(dt_fecha)
   from   cob_credito..cr_disponibles_tramite
   where  dt_operacion_cca = @i_operacion
   and    dt_fecha > @i_fecha_ini_anio
   and    dt_fecha <= @o_fecha_fin_anio
   and    dt_valor_disponible > 0

   if @o_fecha_disponible_fin = (select max(dt_fecha)
                                 from   cob_credito..cr_disponibles_tramite
                                 where  dt_operacion_cca = @i_operacion
                                 and    dt_valor_disponible > 0)
   begin
      select @o_fecha_fin_anio = @o_fecha_disponible_fin
   end

   return 0
end
go
