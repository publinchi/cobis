/************************************************************************/
/*	Archivo:		verimor.sp				*/
/*	Stored procedure:	sp_verifica_cambio_TMM   		*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera         			*/
/*	Disenado por:  		Xavier Maldonado       			*/
/*	Fecha de escritura:	abril 2002 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Verifica si cambio el valor de TMM para la fecha de proceso     */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_verifica_cambio_TMM')
   drop proc sp_verifica_cambio_TMM
go

create proc sp_verifica_cambio_TMM
@i_fecha_proceso datetime,
@i_codigo_tmm    catalogo,
@o_cambio        char(1) out
as

declare
   @w_return         	 int,
   @w_sp_name        	 descripcion,
   @w_fecha_anterior        datetime,
   @w_valor_actual          float,
   @w_valor_anterior        float,
   @w_nemo_tasa_ipc         catalogo,
   @w_secuencial_ipc        int,
   @w_valor_ipc	         float,
   @w_secuencial_ibc        int,
   @w_max_fecha             datetime

-- CARGADO DE VARIABLES DE TRABAJO
select @w_sp_name = 'sp_verifica_cambio_TMM'

-- VALOR DEL TMM A LA FECHA DE PROCESO

select @w_max_fecha = null

select @w_max_fecha = max(vr_fecha_vig)
from   ca_valor_referencial
where  vr_tipo       = @i_codigo_tmm
and    vr_fecha_vig <= @i_fecha_proceso

if @w_max_fecha is null
   return 710453

select @w_secuencial_ibc = null
select @w_secuencial_ibc = max(vr_secuencial)
from   ca_valor_referencial
where  vr_tipo      = @i_codigo_tmm
and    vr_fecha_vig = @w_max_fecha

if @w_secuencial_ibc is null
   return 710453

select @w_valor_actual = vr_valor
from   ca_valor_referencial
where  vr_tipo       = @i_codigo_tmm
and    vr_fecha_vig  = @w_max_fecha
and    vr_secuencial = @w_secuencial_ibc

if @@rowcount = 0 
   return 710453

-- VALOR DEL TMM A LA FECHA DE PROCESO - 1

select @w_fecha_anterior = dateadd(dd, -1, @i_fecha_proceso)

select @w_max_fecha = null
select @w_max_fecha = max(vr_fecha_vig)
from   ca_valor_referencial
where  vr_tipo       = @i_codigo_tmm
and    vr_fecha_vig <= @w_fecha_anterior

if @w_max_fecha is null -- NO HAY DATO EN FECHAS ANTERIORES
begin
   select @o_cambio = 'N'
   return 0
end

select @w_secuencial_ibc = null
select @w_secuencial_ibc = max(vr_secuencial)
from   ca_valor_referencial
where  vr_tipo      = @i_codigo_tmm
and    vr_fecha_vig = @w_max_fecha

if @@rowcount = 0 
   return 710453

select @w_valor_anterior = vr_valor
from   ca_valor_referencial
where  vr_tipo       = @i_codigo_tmm
and    vr_fecha_vig = @w_max_fecha
and    vr_secuencial = @w_secuencial_ibc

if @@rowcount = 0 
   return 710453

-- SI VALOR ACTUAL ES DEFERENTE A VALOR ANTERIOR ENTONCES RETORNAR QUE SI CAMBIA

if @w_valor_actual <> @w_valor_anterior
   select @o_cambio = 'S'
else
   select @o_cambio = 'N'

return 0
go
