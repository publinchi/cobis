/************************************************************************/
/*   Stored procedure:     sp_desem_nej                                 */
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
 
if exists (select 1 from sysobjects where name = 'sp_desem_nej')
   drop proc sp_desem_nej
go
 
CREATE proc [dbo].[sp_desem_nej]
   @i_fecha_proceso    datetime

as
declare 
   @w_return           int,
   @w_sp_name          descripcion,
   @w_error            int,   
   @w_pa_cheger        varchar(30),
   @w_pa_cheotr        varchar(30),
   @w_rowcount         int

/*CREACION DE TABLA TEMPORAL PARA EL REPORTE */
create table #ca_desembolso_no(
op_banco        varchar(24) null,
op_cliente      int         null,
en_ced_ruc      varchar(30) null,
en_nombre       varchar(64) null,
dtr_concepto    varchar(64) null,
dtr_cuenta      char(24)    null, 
dtr_monto       money       null, 
tr_ofi_oper     smallint    null,        
tr_fecha_ref    datetime    null,
op_oficina      smallint    null,
op_oficial      smallint    null)

/* LECTURA DEL PARAMETRO CHEQUE DE GERENCIA */
select @w_pa_cheger = pa_char
from   cobis..cl_parametro
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'CHEGER'
select @w_rowcount    = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 701012 --No existe parametro cheque de gerencia
   goto ERROR
end

/* LECTURA DEL PARAMETRO CHEQUE LOCAL (Otros Bancos) */
select @w_pa_cheotr = pa_char
from   cobis..cl_parametro
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'CHELOC'
select @w_rowcount    = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 701012 --No existe parametro cheque de Otros Bancos
   goto ERROR
end

/* INSERCION EN TABLA TEMPORAL DE LOS DATOS DEL REPORTE */
insert into #ca_desembolso_no
select op_banco,
       op_cliente,
       en_ced_ruc,
       en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido,    
       dtr_concepto,
       dtr_cuenta,
       dtr_monto,
       tr_ofi_oper,
       tr_fecha_ref,
       op_oficina,
       op_oficial       
from  ca_operacion, cobis..cl_ente, ca_transaccion , ca_det_trn
where op_operacion  = tr_operacion
and   op_tipo       <> 'R'  ---Las pasivas no deben ir a este archivo
and   tr_tran       = 'DES'
and   tr_estado     = 'RV'
and   en_ente       = op_cliente
and   tr_fecha_mov  = @i_fecha_proceso
and   dtr_operacion = tr_operacion
and   dtr_secuencial = tr_secuencial
and   dtr_concepto  in (@w_pa_cheger, @w_pa_cheotr)

/*PARA MOSTRAR LA INFORMACION DE LA CONSULTA EN GRILLA O PARA REPORTE */
select
   op_banco,
   op_cliente,
   en_ced_ruc,
   en_nombre ,
   dtr_concepto,
   dtr_cuenta,
   dtr_monto,
   tr_ofi_oper,
   tr_fecha_ref, 
   op_oficina,
   op_oficial
from #ca_desembolso_no

return 0

ERROR:
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   
return @w_error
go
