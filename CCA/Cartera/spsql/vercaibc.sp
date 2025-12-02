/************************************************************************/
/*   Archivo:              vercaibc.sp                                  */
/*   Stored procedure:     sp_verifica_cambio_ibc                       */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Xavier Maldonado                             */
/*   Fecha de escritura:   Nov. 2002                                    */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Verifica si cambio el valor de TLU para la fecha de proceso        */
/*   mayo-2006    Elcira Pelaez    def. 6518                            */
/*   May 2007     Fabian Quintero  Defecto 8236                         */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_verifica_cambio_ibc')
   drop proc sp_verifica_cambio_ibc
go

create proc sp_verifica_cambio_ibc
@i_fecha_proceso        datetime,
@i_ibc                  catalogo,
@i_uvr                  char(1),
@o_cambio               char(1) out
as

declare 
   @w_fecha_anterior    datetime,
   @w_valor_actual      float,
   @w_valor_anterior    float,
   @w_nemo_tasa_ipc     catalogo,
   @w_secuencial_ipc    int,
   @w_valor_ipc         float,
   @w_secuencial_ibc    int,
   @w_max_fecha         datetime

select @o_cambio = 'S'
return 0
-- VALOR DEL TLU A LA FECHA DE PROCESO
select @w_max_fecha = max(vr_fecha_vig)
from   ca_valor_referencial
where  vr_tipo       = @i_ibc
and    vr_fecha_vig <= @i_fecha_proceso

if @@rowcount = 0 
   print '...Error en fecha TLU..vercaibc.sp' + @i_ibc + ' ' + cast(@i_fecha_proceso as varchar)

select @w_secuencial_ibc = max(vr_secuencial)
from   ca_valor_referencial
where  vr_tipo      = @i_ibc
and    vr_fecha_vig = @w_max_fecha
if @@rowcount = 0 
   print '...Error en secuencial TLU..vercaibc.sp' + @i_ibc + ' ' + cast(@w_max_fecha as varchar)

select @w_valor_actual = vr_valor
from   ca_valor_referencial
where  vr_tipo       = @i_ibc
and    vr_secuencial = @w_secuencial_ibc

if @@rowcount = 0 
   print '...Error en valor TLU..vercaibc.sp' + @i_ibc + ' ' + cast(@w_secuencial_ibc as varchar)

-- VALOR DEL TLU A LA FECHA DE LA ULTIMA TASA - 1

select @w_fecha_anterior = dateadd(dd, -1, @w_max_fecha)

select @w_max_fecha = max(vr_fecha_vig)
from   ca_valor_referencial
where  vr_tipo       = @i_ibc
and    vr_fecha_vig <= @w_fecha_anterior
if @@rowcount = 0 
   print '...Error en fecha maxima TLU..vercaibc.sp' + @i_ibc + ' ' + cast(@w_fecha_anterior as varchar)

select @w_secuencial_ibc = max(vr_secuencial)
from   ca_valor_referencial
where  vr_tipo      = @i_ibc
and    vr_fecha_vig = @w_max_fecha
if @@rowcount = 0 
   print '...Error en secuencial2 TLU..vercaibc.sp' + @i_ibc + ' ' + @w_max_fecha

select @w_valor_anterior = vr_valor
from   ca_valor_referencial
where  vr_tipo       = @i_ibc
and    vr_secuencial = @w_secuencial_ibc
if @@rowcount = 0 
   print '...Error en Valor anterior TLU..vercaibc.sp' + @i_ibc + ' ' + cast(@w_secuencial_ibc as varchar)

--- SI VALOR ACTUAL ES DEFERENTE A VALOR ANTERIOR ENTONCES RETORNAR QUE SI CAMBIA 
if @w_valor_actual != @w_valor_anterior
   select @o_cambio = 'S'
else
   select @o_cambio = 'N'

return 0
go
