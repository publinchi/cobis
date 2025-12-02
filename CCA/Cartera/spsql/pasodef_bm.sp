/*pasodef_bancamia.sp****************************************************/
/*      Stored procedure:       sp_paso_definitivo_bm                   */
/*      Base de Datos:          cob_cartera                             */
/*      Disenado Por:           Fabian de la Torre                      */
/*      Fecha:                  Sep/2002                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA' del Ecuador.                                           */
/*                                                                      */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*   07-07-2009             Lilian Alvarez         Incidencia 1001      */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_paso_definitivo_bm')
   drop proc sp_paso_definitivo_bm
go
 
 
create proc sp_paso_definitivo_bm

as declare 
   @w_fecha_proceso    datetime, 
   @w_error            int, 
   @w_sp_name          varchar(20),
   @w_mensaje          varchar(255)

-- DETERMINAR FECHA DE PROCESO --

select @w_sp_name = 'sp_paso_definitivo_bm',
       @w_fecha_proceso  = convert(varchar(10), getdate(),101)

begin tran

insert  into ca_transaccion_bancamia
select * from ca_transaccion_bancamia_2

if @@error <> 0 begin
   select 
   @w_error   = 710001,
   @w_mensaje = 'ERROR AL PASO A DEFINITIVAS ca_transaccion_bancamia'
   goto ERRORFIN
end

insert  into ca_det_trn_bancamia
select * from ca_det_trn_bancamia_2

if @@error <> 0 begin
   select 
   @w_error   = 710001,
   @w_mensaje = 'ERROR AL PASO A DEFINITIVAS ca_det_trn_bancamia'
   goto ERRORFIN
end

commit tran

/****INSERTANDO DATOS EN SB_DATO_TRANSACCION ***/

if exists( select 1 from cob_conta_super..sb_dato_transaccion where dt_fecha = @w_fecha_proceso and dt_aplicativo = 200) begin
   delete cob_conta_super..sb_dato_transaccion 
   where dt_fecha = @w_fecha_proceso 
   and dt_aplicativo = 200
End
 
insert into cob_conta_super..sb_dato_transaccion(
dt_fecha,      dt_secuencial,   dt_banco,  
dt_toperacion, dt_aplicativo,   dt_fecha_trans,  
dt_tipo_trans, dt_reversa,      dt_naturaleza,
dt_canal,      dt_oficina)
select  
convert(smalldatetime,@w_fecha_proceso),  tr_secuencial,   tr_banco,
'xxx',             200,             tr_fecha_mov,
tr_tran,     case when tr_estado = 'REV' then 'S' else 'N'  end,  case when tr_tran = 'DES' then 'C' else 'D' end,
'OFI',             tr_ofi_usu
from cob_cartera..ca_transaccion_bancamia_2

if @@error <> 0 begin
   select 
   @w_error   = 28001,
   @w_mensaje = 'ERROR INSERTANDO DATOS sb_dato_transaccion'
   goto ERRORFIN
end

/*****INSERTANDO DATSOS EN LA SB_DATO_TRANSACCION_DET ***/
if exists( select 1 from cob_conta_super..sb_dato_transaccion_det where dd_fecha = @w_fecha_proceso and dd_aplicativo = 200) begin
   delete cob_conta_super..sb_dato_transaccion_det
   where dd_fecha = @w_fecha_proceso 
   and dd_aplicativo = 200
End

insert into cob_conta_super..sb_dato_transaccion_det(
dd_fecha,       dd_secuencial,   dd_banco, 
dd_toperacion,  dd_aplicativo,   dd_concepto, 
dd_moneda,      dd_cotizacion,   dd_monto)
select 
convert(smalldatetime,@w_fecha_proceso),  dtr_secuencial,      dtr_banco,
'xxx',          200,                 dtr_concepto,       
dtr_moneda,     dtr_cotizacion,       dtr_monto
from ca_det_trn_bancamia_2     

if @@error <> 0 begin
   select 
   @w_error   = 28002,
   @w_mensaje = 'ERROR INSERTANDO DATOS sb_dato_transaccion_det'
   goto ERRORFIN
end 

truncate table ca_transaccion_bancamia_2

if @@error <> 0 begin
   select 
   @w_error   = 710001,
   @w_mensaje = 'ERROR AL TRUNCAR ca_transaccion_bancamia_2'
   goto ERRORFIN
end

truncate table ca_det_trn_bancamia_2

if @@error <> 0 begin
   select 
   @w_error   = 710001,
   @w_mensaje = 'ERROR AL TRUNCAR ca_det_trn_bancamia_2'
   goto ERRORFIN
end

return 0

ERRORFIN:
if @@trancount > 0 rollback tran

exec sp_errorlog
@i_fecha       = @w_fecha_proceso, 
@i_error       = 7200, 
@i_usuario     = 'OPERADOR',
@i_tran        = 7000, 
@i_tran_name   = @w_sp_name,
@i_rollback    = 'N',
@i_cuenta      = 'PASO DEF BANCAMIA', 
@i_descripcion = @w_mensaje

return @w_error

go

