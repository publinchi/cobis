/************************************************************************/
/*   Stored procedure:     sp_trn_ing                                   */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/************************************************************************/
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_trn_ing_prv')
   drop proc sp_trn_ing_prv
go
 
create proc sp_trn_ing_prv



as declare
   @w_error             int,
   @w_sp_name           varchar(20),
   @w_mensaje           varchar(255),
   @w_fecha_desde       datetime,
   @w_fecha_hasta       datetime,
   @w_fecha_proceso     datetime

-- VARIABLES DE TRABAJO --

select
@w_mensaje         = '',
@w_sp_name         = 'sp_trn_ing_prv'


select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

/* DETERMINAR EL RANGO DE FECHAS DE LAS TRANSACCIONES QUE SE INTENTARAN CONTABILIZAR */

select  
@w_fecha_desde = isnull(min(co_fecha_ini),'01/01/1900'),
@w_fecha_hasta = isnull(max(co_fecha_ini),'01/01/1900')
from cob_conta..cb_corte
where co_empresa = 1
and   co_estado in ('A','V')



if @w_fecha_desde = '01/01/1900' begin
   select 
   @w_error   = 601078,
   @w_mensaje = 'ERROR: NO EXISTEN PERIODOS DE CORTE ABIERTOS'
end



create table #comprobantes( 
comprobante  int      null,
fecha        datetime null,
mensaje      varchar(60))


while @w_fecha_desde <= @w_fecha_hasta begin

   insert into #comprobantes
   select ec_comprobante, ec_fecha_conta, substring (ec_mensaje, 1,60)
   from cob_ccontable..cco_error_conaut
   where ec_producto = 7
   and   ec_fecha_conta = @w_fecha_desde 
   and   ec_tran_modulo = -999
   and   ec_comprobante is not null   

   if @@error <> 0 begin
      select 
      @w_error   = 7200,
      @w_mensaje = 'ERROR AL INSERTAR #COMPROBANTE'
      goto ERRORFIN
   end
   select @w_fecha_desde = dateadd(dd, 1, @w_fecha_desde)
end


update ca_transaccion_prv set 
tp_estado       = 'ING',
tp_comprobante  = 0,
tp_fecha_cont   = '01/01/1900'
from  #comprobantes
where tp_comprobante = comprobante
and   tp_fecha_mov   = fecha
if @@error <> 0 begin
   select 
   @w_error   = 7200,
   @w_mensaje = 'ERROR AL ACTUALIZAR CA_TRANSACCION_BANCAMIA'
   goto ERRORFIN
end



return 0


ERRORFIN:

exec sp_errorlog
@i_fecha       = @w_fecha_proceso, 
@i_error       = 7200, 
@i_usuario     = 'OPERADOR',
@i_tran        = 7000, 
@i_tran_name   = @w_sp_name,
@i_rollback    = 'N',
@i_cuenta      = 'CONTABILIDAD', 
@i_descripcion = @w_mensaje

return @w_error

go

