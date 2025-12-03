/************************************************************************/
/*  Archivo:                contingencias.sp                            */
/*  Stored procedure:       sp_contingencias                            */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_contingencias')
    drop proc sp_contingencias
go

create proc sp_contingencias(
   @i_fecha             datetime
)

as

declare
@w_sp_name              descripcion,
@w_aplicativo           int,
@w_mensaje              varchar(250),
@w_causa_rechazo        varchar(255),
@w_error                int,
@w_usuario              login


select @w_sp_name       = 'sp_contingencias',
       @w_aplicativo    = 21,
       @w_usuario       = 'crebatch'


select @w_error = 21001

--Aprobados No Desembolsados Tramites Originales

select
operacion      = op_operacion,
banco          = op_banco,
toperacion     = 'APROB',
cliente        = op_cliente,
oficina        = tr_oficina,
monto          = tr_monto,
moneda         = tr_moneda,
tasa           = 0,
modalidad      = 'V',
fecha_des      = isnull(op_fecha_ini,@i_fecha),
fecha_ven      = isnull(op_fecha_fin,@i_fecha),
reest          = 'N',
fecha_reest    = null,
num_renov      = 0,
destino_ec     = isnull(tr_destino,''),
clase_cartera  = '0',
fecha_prox     = null,
estado         = op_estado,
numero_linea   = tr_linea_credito,
periodicidad   = 0,
fecha_ult_pago = null,
valor_cuota    = 0,
cuotas_pag     = 0,
plazo_dias     = 0,
cuotas_ven     = 0,
saldo_ven      = 0,
num_cuotas     = 0,
valor_ult_pago = 0,
fecha_cas      = null,
num_acta       = null,
nat_reest      = null,
num_reest      = 0,
clausula       = null,
edad_mora      = 0,
oficial        = tr_oficial,
val_nominal    = 0.00,
emision        = ' '
into #credito
from cob_credito..cr_tramite, cob_cartera..ca_operacion
where tr_estado     = 'A'
and   tr_tipo       = 'O'
and   tr_tramite    = op_tramite
and   op_estado     in (0,99)
and   op_naturaleza = 'A'

if @@error <> 0 begin
   select @w_mensaje = 'Error Creando en #credito APROBADOS NO DESEMBOLSADOS <Originales> '
   goto ERRORFIN
end

--Aprobados no Desembolsados Tramites de Renovaciones
select tramite_ren=tr_tramite, monto_ren=tr_monto
into #tram_renovacion
from cob_credito..cr_tramite, cob_cartera..ca_operacion
where tr_estado  = 'A'
and   tr_tipo    = 'R'
and   op_estado  in (0,99)
and   tr_tramite = op_tramite

select tramite_ren, op_operacion_ant = op_operacion
into #op_anteriores
from cr_op_renovar, #tram_renovacion, cob_cartera..ca_operacion
where tramite_ren      = or_tramite
and   or_num_operacion = op_banco

select tramite_ant=tramite_ren, deuda=sum(am_acumulado-am_pagado)
into #valor_operacion
from cob_cartera..ca_amortizacion, #op_anteriores
where am_operacion = op_operacion_ant
group by tramite_ren

--monto pendiente de contabilizar Renovaciones
select tramite=tramite_ren, valor=isnull(monto_ren,0)-isnull(deuda,0)
into #valor_contabilizar
from #valor_operacion, #tram_renovacion
where tramite_ant = tramite_ren

insert into #credito
select
tr_tramite,        op_banco,       'APROB',
tr_cliente,        tr_oficina,     valor,
tr_moneda,         0,              'V',
isnull(tr_fecha_apr,@i_fecha),      isnull(tr_fecha_apr,@i_fecha),   'N',
null,              0,              isnull(tr_destino,''),
'0',               null,           1,
0,                 0,              null,
0,                 0,              0,
0,                 0,              0,
0,                 null,           null,
null,              0,              null,
0,                 tr_oficial,     0.00,
' '
from #valor_contabilizar, cr_tramite, cob_cartera..ca_operacion
where tramite    = tr_tramite
and   tr_tramite = op_tramite

if @@error <> 0 begin
   select @w_mensaje = 'Error Insertando en #credito APROBADOS NO DESEMBOLSADOS <Renovaciones> '
   goto ERRORFIN
end


--Cupos de Credito
insert into #credito
select
tr_tramite,        li_num_banco,   'CUPOS',
tr_cliente,        tr_oficina,     isnull(li_monto,0) - isnull(li_utilizado,0),
tr_moneda,         0,              'V',
tr_fecha_apr,      tr_fecha_apr,   'N',
null,              0,              isnull(tr_destino,''),
'0',               null,           1,
li_numero,         0,              null,
0,                 0,              0,
0,                 0,              0,
0,                 null,           null,
null,              0,              null,
0,                 tr_oficial,     0.00,
' '
from cob_credito..cr_tramite, cob_credito..cr_linea
where tr_estado        = 'A'
and   tr_tipo          = 'C'
and   tr_tramite       = li_tramite
and   li_estado        = 'V'
and   tr_cliente       = li_cliente
and   li_num_banco     > ''
and   isnull(li_monto,0) - isnull(li_utilizado,0) > 0

if @@error <> 0 begin
   select @w_mensaje = 'Error Insertando en #credito CUPOS DE CREDITO '
   goto ERRORFIN
end

delete cob_externos..ex_dato_operacion_rubro
where dr_aplicativo  = @w_aplicativo

if @@error <> 0 begin
   select @w_mensaje = 'Error Eliminando cob_externos..ex_dato_operacion_rubro <Credito> '
   goto ERRORFIN
end

delete cob_externos..ex_dato_operacion
where do_aplicativo  = @w_aplicativo
and do_fecha = @i_fecha

if @@error <> 0 begin
   select @w_mensaje = 'Error Eliminando cob_externos..ex_dato_operacion <Credito> '
   goto ERRORFIN
end

--Validaciones
select banco, cliente_err=cliente, mensaje= ' No tiene Codigo del Cliente '
into #errores
from #credito
where cliente is null

delete #credito
where cliente is null

if @@error <> 0 begin
   select @w_mensaje = 'Error Eliminando #credito Validando Cliente '
   goto ERRORFIN
end

insert into #errores
select banco, cliente, mensaje = 'No tiene Acta de Castigo '
from #credito
where num_acta is null
and   fecha_cas is not null

if @@error <> 0 begin
   select @w_mensaje = 'Error Insertando #errores Validando Castigos '
   goto ERRORFIN
end

insert into #errores
select banco, cliente, mensaje = 'Cliente No Existe en cl_ente'
from #credito
where cliente not in (select en_ente from cobis..cl_ente)

if @@error <> 0 begin
   select @w_mensaje = 'Error Insertando #errores Validando Existencia de Cliente '
   goto ERRORFIN
end

delete #credito
from #errores
where cliente = cliente_err
and   mensaje = 'Cliente No Existe en cl_ente'

if @@error <> 0 begin
   select @w_mensaje = 'Error Eliminando #credito Validando Existencia Cliente '
   goto ERRORFIN
end


--Inserta Aprobados no Desembolsados/Cupos
insert into cob_externos..ex_dato_operacion (
do_fecha,                do_operacion,           do_banco,
do_toperacion,           do_aplicativo,          do_cliente,
do_oficina,              do_moneda,              do_monto,
do_tasa,                 do_modalidad,           do_fecha_desembolso,
do_fecha_vencimiento,    do_reestructuracion,    do_fecha_reest,
do_num_renovaciones,     do_destino_economico,   do_clase_cartera,
do_fecha_prox_vto,       do_estado,              do_cupo_credito,
do_periodicidad_cuota,   do_fecha_ult_pago,      do_valor_cuota,
do_cuotas_pag,           do_plazo_dias,          do_cuotas_ven,
do_saldo_ven,            do_num_cuotas,          do_valor_ult_pago,
do_fecha_castigo,        do_num_acta,            do_nat_reest,
do_num_reest,            do_clausula,            do_edad_mora,
do_oficial,              do_valor_nominal,       do_emision
)
select
@i_fecha,                operacion,              banco,
toperacion,              @w_aplicativo,          cliente,
oficina,                 moneda,                 monto,
tasa,                    modalidad,              fecha_des,
fecha_ven,               reest,                  fecha_reest,
num_renov,               destino_ec,             clase_cartera,
fecha_prox,              estado,                 numero_linea,
periodicidad,            fecha_ult_pago,         valor_cuota,
cuotas_pag,              plazo_dias,             cuotas_ven,
saldo_ven,               num_cuotas,             valor_ult_pago,
fecha_cas,               num_acta,               nat_reest,
num_reest,               clausula,               edad_mora,
oficial,                 val_nominal,            emision
from #credito

if @@error <> 0 begin
   select @w_mensaje = 'Error Insertando cob_externos..ex_dato_operacion <Credito> '
   goto ERRORFIN
end

--Inserta ex_dato_operacion_rubro
insert into cob_externos..ex_dato_operacion_rubro (
dr_fecha,            dr_banco,            dr_toperacion,
dr_aplicativo,       dr_concepto,         dr_valor_vigente,
dr_valor_suspenso,   dr_valor_castigado,  dr_valor_diferido
)
select
@i_fecha,            banco,               toperacion,
@w_aplicativo,       'CAP',               0,
monto,               0,                   0
from #credito

if @@error <> 0 begin
   select @w_mensaje = 'Error Insertando cob_externos..ex_dato_dato_operacion_rubro <Credito> '
   goto ERRORFIN
end

--Extrae Deudores
select distinct
opera   = operacion,
fecha   = @i_fecha,
banco   = banco,
topera  = toperacion,
cliente = cliente,
rol     = 'D'
into #deudores
from #credito

update #deudores set
rol = ltrim(rtrim(de_rol))
from cob_credito..cr_deudores
where  opera   = de_tramite
and    cliente = de_cliente

if @@error <> 0 begin
   select @w_mensaje = 'Error Actualizando #deudores <Credito> '
   goto ERRORFIN
end

-- INSERTO FCP
delete #deudores
from   cob_externos..ex_dato_deudores
where de_aplicativo  = @w_aplicativo
and   de_fecha = fecha
and   de_cliente = cliente

if @@error <> 0 begin
   select @w_mensaje = 'Error Eliminando cob_externos..ex_dato_deudores <Credito> '
   goto ERRORFIN
end


--Inserta ex_dato_deudores
insert into cob_externos..ex_dato_deudores (
de_fecha,            de_banco,            de_toperacion,
de_aplicativo,       de_cliente,          de_rol
)
select
fecha,               banco,               topera,
@w_aplicativo,       cliente,             ltrim(rtrim(rol))
from #deudores

if @@error <> 0 begin
   select @w_mensaje = 'Error Insertando cob_externos..ex_dato_deudores <Credito> '
   goto ERRORFIN
end

--Inserta en tabla de errores
insert into cr_errorlog
select
@i_fecha,        @w_error,    @w_usuario,
@w_error,        banco,       mensaje
from #errores

return 0

ERRORFIN:

while @@trancount > 0 rollback tran

select @w_mensaje = @w_sp_name + ' --> ' + @w_mensaje

insert into cr_errorlog
values (@i_fecha, @w_error, @w_usuario, 21000, 'CONSOLIDADOR', @w_mensaje)

return 1


GO

