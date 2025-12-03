use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_llenauniverso_bocfin')
   drop proc sp_llenauniverso_bocfin
go

create procedure sp_llenauniverso_bocfin
/*************************************************************************/
/*      Archivo:                sp_llenauniverso_bocfin.sp               */
/*      Stored procedure:       sp_llenauniverso_bocfin                  */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Disenado por:           Sandro Vallejo                           */
/*      Fecha de escritura:     Sep 2020                                 */
/*********************************************************************** */
/*                              IMPORTANTE                               */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      'MACOSA', representantes exclusivos para el Ecuador de la        */
/*      'NCR CORPORATION'.                                               */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de sus          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de MACOSA o su representante.              */
/*************************************************************************/
/*                              PROPOSITO                                */
/*      Llena la tabla de cuentas que tienen registros de saldos boc     */
/*************************************************************************/
/*                              MODIFICACIONES                           */
/*     Fecha        Autor          Razón                                 */
/*     16/07/2021   K. Rodríguez   Estandarización de parámetros         */
/*************************************************************************/
/*************************************************************************/
		@i_param1        datetime,            -- Fecha
		@i_param2        char(1)       = 'N'  -- Debug
as

declare @w_sp_name       descripcion,
        @w_error         int,
        @w_cod_producto  tinyint,
        @w_mensaje       varchar(255),
		@i_debug         char(1),
        @i_fecha         datetime
		
-- KDR 16/07/21 Paso de parámetros a variables locales.
select @i_fecha  =  @i_param1,        
       @i_debug  =  @i_param2

select @w_sp_name      = 'sp_llenauniverso_bocfin',
       @w_error        = 0,
       @w_cod_producto = 7

if @i_debug = 'S' 
   print '--> sp_llenauniverso_bocfin. Fecha ' + cast(@i_fecha as varchar)

-- INICIALIZA TABLA DE TRANSACCIONES CONTABLES 
truncate table ca_bocfin_tmp                 

-- CARGAR CUENTAS DE BOC
insert into ca_bocfin_tmp (bt_agrupado, bt_ofi_oper, bt_cuenta, bt_monto)
select 'Of:' + convert(varchar,re_ofconta) + 'Cta:' + convert(varchar,bod_cuenta), re_ofconta, bod_cuenta, sum(bod_val_opera)
from   cob_conta..cb_boc_det, cob_conta..cb_relofi
where  bod_fecha    = @i_fecha
and    bod_producto = @w_cod_producto
AND    bod_oficina  = re_ofadmin
group by re_ofconta, bod_cuenta

update statistics ca_bocfin_tmp

--Inicializa tabla de universo a procesar
truncate table ca_universo_bocfin

--Carga universo de operaciones con operaciones con transacciones a contabilizar
insert into ca_universo_bocfin (agrupado, intentos, hilo)
select bt_agrupado,
       0,
       0
from   ca_bocfin_tmp
update statistics ca_universo_bocfin

return 0

ERRORFIN:
exec sp_errorlog
@i_fecha       = @i_fecha, 
@i_error       = @w_error, 
@i_usuario     = 'consola',
@i_tran        = 7000, 
@i_tran_name   = @w_sp_name, 
@i_rollback    = 'N',
@i_cuenta      = 'BOCFIN', 
@i_descripcion = @w_mensaje

return @w_error

go

