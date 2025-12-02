/************************************************************************/
/*   Archivo            :        trnoconta.sp                           */
/*   Stored procedure   :        sp_trano_conta                         */
/*   Base de datos      :        cob_cartera                            */
/*   Producto           :        Cartera                                */
/*   Disenado por                Ivan Jimenez                           */
/*   Fecha de escritura :        Noviembre 09 de 2006                   */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Carga Tabla de trabajo para la consulta resumida de transacciones  */
/*   no contabilizadas                                                  */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*       Ago/14/2006    Ivan Jimenez      Emision inicial               */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_tran_no_conta')
begin
   drop table ca_tran_no_conta
end
go

create table ca_tran_no_conta
(
   tnc_secuencial  numeric(10,0) identity,
   tnc_estado      char(10) not null, 
   tnc_fecha_mov   datetime not null, 
   tnc_tipo_tran   catalogo not null, 
   tnc_perfil      catalogo not null, 
   tnc_num_tran    int not null
)
go

create index ca_tran_no_conta_1 on ca_tran_no_conta (tnc_secuencial)
go

if exists (select 1 from sysobjects where name = 'sp_trano_conta')
   drop proc sp_trano_conta
go

create proc sp_trano_conta
as
declare
   @w_contador    int,
   @w_secuencial  int   

truncate table ca_tran_no_conta

-- BORRA TABLA DE TRABAJO
-- INSERCION DE DATOS EN TABLA DE TRABAJO
insert into ca_tran_no_conta
      (tnc_estado,   tnc_fecha_mov, tnc_tipo_tran,
       tnc_perfil,   tnc_num_tran)
select tr_estado,    tr_fecha_mov,  tr_tran, 
       to_perfil,    count(1)
from   ca_transaccion,
       ca_trn_oper
where  tr_estado in ('ING', 'PVA')
and    to_toperacion = tr_toperacion
and    to_tipo_trn   = tr_tran
group  by tr_estado, tr_fecha_mov, tr_tran, to_perfil

print 'originales' + cast(@@rowcount as varchar)

insert into ca_tran_no_conta
      (tnc_estado,   tnc_fecha_mov, tnc_tipo_tran,
       tnc_perfil,   tnc_num_tran)
select rev.tr_estado,    rev.tr_fecha_mov,  rev.tr_tran, 
       to_perfil,    count(1)
from   ca_transaccion rev,
       ca_transaccion ori,
       ca_trn_oper
where  rev.tr_estado in ('ING', 'PVA')
and    rev.tr_tran   = 'REV'
and    ori.tr_operacion = rev.tr_operacion
and    ori.tr_secuencial = -rev.tr_secuencial
and    to_toperacion = ori.tr_toperacion
and    to_tipo_trn   = ori.tr_tran
group  by rev.tr_estado, rev.tr_fecha_mov, rev.tr_tran, to_perfil

print 'reversas' + cast(@@rowcount as varchar)

insert into ca_tran_no_conta
      (tnc_estado,   tnc_fecha_mov, tnc_tipo_tran,
       tnc_perfil,   tnc_num_tran)
select tr_estado,    tr_fecha_mov,  tr_tran, 
       'SIN PERFIL',    count(1)
from   ca_transaccion t
where  tr_estado in ('ING', 'PVA')
and    tr_secuencial > 0
and    not exists(select 1
                  from   ca_trn_oper
                  where  to_toperacion = t.tr_toperacion
                  and    to_tipo_trn   = t.tr_tran)
group  by tr_estado, tr_fecha_mov, tr_tran

print 'SIn perfil' + cast(@@rowcount as varchar)

--update statistics ca_tran_no_conta  --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
--exec sp_recompile ca_tran_no_conta  --LPO CDIG Se comenta temporalmente porque MySql no lo soporta
return 0
go