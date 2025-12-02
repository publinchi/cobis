
/************************************************************************/
/*   Archivo:              desmarcar_conta.sp                           */
/*   Stored procedure:     sp_desmarcar_conta       					*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Andy Gonzalez                                */
/*   Fecha de escritura:   Diciembre 2017                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Desmarcar las transacciones de cartera que no fueron validadas     */
/*   por el proceso 6525 -Validación de Comprobantes                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_desmarcar_conta')
   drop proc sp_desmarcar_conta
go

create proc sp_desmarcar_conta
as declare 
@w_commit    char(1), 
@w_error     int,
@w_msg       varchar(255),
@w_fecha_pro datetime,
@w_sp_name   varchar(30)


select 
@w_commit   = 'N',
@w_sp_name  = 'sp_desmarcar_conta'

--fecha proceso
select 
@w_fecha_pro = fp_fecha 
from cobis..ba_fecha_proceso	   
	   

create table #trn_desmarcar(
td_operacion   int, 
td_secuencial  int,
td_fecha_mov   datetime,
td_fecha_ref   datetime,
td_comprobante int,
td_mensaje     varchar(255))


insert into #trn_desmarcar
select tr_operacion, tr_secuencial,tr_fecha_mov,tr_fecha_ref,tr_comprobante,ec_mensaje 
from ca_transaccion, cob_interface..cco_error_conaut
where ec_fecha_conta = tr_fecha_mov
and   ec_comprobante = tr_comprobante 
and   tr_estado      = 'CON'
and   ec_producto    = 7
if @@error <> 0 begin 
   select 
   @w_error = 710001, 
   @w_msg   = 'ERROR AL DETERMINAR TRN A DESMARCAR DESDE LA ca_transaccion'
   goto ERROR 
end 


insert into #trn_desmarcar
select tp_operacion, 0,tp_fecha_mov,tp_fecha_ref,tp_comprobante,ec_mensaje 
from ca_transaccion_prv, cob_interface..cco_error_conaut
where ec_fecha_conta = tp_fecha_mov
and   ec_comprobante = tp_comprobante 
and   tp_estado      = 'CON'
and   ec_producto    = 7
if @@error <> 0 begin 
   select 
   @w_error = 710001, 
   @w_msg   = 'ERROR AL DETERMINAR TRN A DESMARCAR DESDE LA ca_transaccion_prv'
   goto ERROR 
end 


--begin tran
if @@trancount = 0 begin
   select @w_commit = 'S'
   begin tran
end	  
	  
--desmarcar las transaccion y la de prv contra trn_desmarcar
insert into ca_errorlog (er_fecha_proc,er_error,er_usuario,er_tran,er_cuenta,er_descripcion,er_anexo)
select @w_fecha_pro, 601181, 'usrbatch', tr_secuencial, tr_banco, ec_mensaje, 'TRN:'+tr_tran+' FECHA REF: ' + convert(varchar, tr_fecha_ref, 103)
from ca_transaccion,  cob_interface..cco_error_conaut
where tr_fecha_mov    = ec_fecha_conta 
and   tr_comprobante  = ec_comprobante
and   ec_producto     = 7


if @@error <> 0 begin 
   select 
   @w_error = 710001, 
   @w_msg   = 'ERROR AL INSERT cob_interface..cco_error_conaut'
   goto ERROR 
end 



update ca_transaccion set 
tr_estado      = 'ING',
tr_comprobante = 0
from #trn_desmarcar
where tr_fecha_mov    = td_fecha_mov 
and   tr_comprobante  = td_comprobante

if @@error <> 0 begin 
   select 
   @w_error = 710002, 
   @w_msg   = 'ERROR AL MARCAR COMO NO CONTABILIZADOLA ca_transaccion'
   goto ERROR 
end 

insert into ca_errorlog (er_fecha_proc,er_error,er_usuario,er_tran,er_cuenta,er_descripcion,er_anexo)
select @w_fecha_pro, 601181, 'usrbatch', 0, convert(varchar,tp_operacion), ec_mensaje, 'TRN:PRV FECHA REF: ' + convert(varchar, tp_fecha_ref, 103)+ ' MONTO: '+ convert(varchar, tp_monto)
from   ca_transaccion_prv,cob_interface..cco_error_conaut
where tp_fecha_mov    = ec_fecha_conta 
and   tp_comprobante  = ec_comprobante
and   ec_producto     = 7

if @@error <> 0 begin 
   select 
   @w_error = 710001, 
   @w_msg   = 'ERROR AL INSERT cob_interface..cco_error_conaut'
   goto ERROR 
end 


update ca_transaccion_prv set 
tp_estado      = 'ING',
tp_comprobante = 0
from #trn_desmarcar
where tp_fecha_mov   = td_fecha_mov
and   tp_comprobante = td_comprobante

if @@error <> 0 begin 
   select 
   @w_error = 710002, 
   @w_msg   = 'ERROR AL MARCAR COMO NO CONTABILIZADOLA ca_transaccion_prv'
   goto ERROR 
end 

--delete a la con_error aut


delete cob_interface..cco_error_conaut 
where ec_producto = 7
if @@error <> 0 begin 
   select 
   @w_error = 710003, 
   @w_msg   = 'ERROR AL MOVER LOS MENSAJES DE ERROR DESDE LA cob_interface..cco_error_conaut'
   goto ERROR 
end 

--commit tran
if @w_commit = 'S'begin
   select @w_commit = 'N'
   commit tran
end	 

return 0 
--ERROR LOG 
ERROR:
if @w_commit = 'S'begin
   select @w_commit = 'N'
   rollback tran
end


  exec cob_cartera..sp_errorlog 
    @i_fecha       = @w_fecha_pro,
    @i_error       = @w_error,
    @i_usuario     = 'usrbatch',
    @i_tran        = 7999,
    @i_tran_name   = @w_sp_name,
    @i_cuenta      = '',
    @i_descripcion = @w_msg,
	@i_rollback    = 'N'

return @w_error 
