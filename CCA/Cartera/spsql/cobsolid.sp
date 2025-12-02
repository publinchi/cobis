/************************************************************************/
/*   Archivo:              cobsolid.sp                                  */
/*   Stored procedure:     sp_cobranza_solidaria                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         DFu                                          */
/*   Fecha de escritura:   Julio 2017                                   */
/************************************************************************/
/*                            IMPORTANTE                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Genera informacion en formato xml para cobranza solidaria          */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA        AUTOR             RAZON                                */
/*  26/jul/2017  DFu               Emision inicial                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cobranza_solidaria')
   drop proc sp_cobranza_solidaria
go

create proc sp_cobranza_solidaria

as

declare
    @w_error                int,
    @w_return               int,
    @w_est_vigente          tinyint,
    @w_est_vencida          tinyint,
    @w_est_novigente        tinyint,
    @w_sp_name              varchar(30),
    @w_msg                  varchar(255),
    @w_secuencial           int,
    @w_id_entidad           varchar(24),
    @w_usuario              varchar(14),
    @w_fecha                datetime,
    @w_grupoId              int,
    @w_referencia_grupal    varchar(15),
    @w_dato_xml             xml,
    @w_detdato_xml          varchar(max),
    @w_cabdato_xml          varchar(max),
    @w_root_tag             varchar(39),
    @w_root_endtag          varchar(39),
    @w_fila                 int,
    @w_rowcount             int,
    @w_fecha_proceso        datetime,
    @w_fecha_vencimiento    datetime,
    @w_exigible             money,
    @w_afecta_cta           char(1),
    @w_entidad              varchar(15),
    @w_cod_entidad          varchar(10)


select @w_sp_name = 'sp_cobranza_solidaria'
select @w_fecha   = getdate() 
select @w_root_tag = '<solidarityPaymentSinchronizationData>',
       @w_root_endtag = '</solidarityPaymentSinchronizationData>'

exec @w_error = sp_estados_cca
@o_est_vigente  = @w_est_vigente out,
@o_est_vencido  = @w_est_vencida out,
@o_est_novigente= @w_est_novigente out

if @w_error != 0
begin
    select @w_msg = 'Error al obtener estados de cartera'
    goto ERROR_PROCESO
end

select @w_msg = 'ERROR DE EJECUCION: cob_cartera..sp_cobranza_solidaria'

select @w_fecha_proceso     = fc_fecha_cierre,
       @w_fecha_vencimiento = dateadd(dd, -1, fc_fecha_cierre)
from cobis..ba_fecha_cierre 
where  fc_producto = 7

/* Consulta datos generales de creditos grupales */
select distinct
fila               = row_number() over(order by tg_grupo,tg_referencia_grupal),
grupo_id           = tg_grupo,
grupo_name         = convert(varchar(60),''),
referencia_grupal  = tg_referencia_grupal,
ciclo_grupo        = convert(int, 0),
fecha_solicitud    = convert(datetime,null),
asesor_id          = convert(int, 0),
asesor_resp        = convert(varchar(64),''),
login_asesor       = convert(varchar(14),''),
sucursal_id        = convert(int, 0),
sucursal_name      = convert(varchar(64),''),
tipo_credito       = convert(varchar(10),''),
monto_grupal       = convert(money,0),
tasa               = convert(int,0),
plazo              = convert(varchar(10),'16 semanas'),
saldo_garantia     = convert(money,0),
proximo_venc       = convert(datetime,null),
monto_exigible     = convert(money,0),
pago_debito_cta    = convert(char(2),'SI'),
vencido_desde      = min(di_dividendo),
vencido_hasta      = max(di_dividendo),
cuotas_vencidas    = count(di_dividendo)
into #cab_cobranza
from   cob_credito..cr_tramite_grupal, ca_operacion, ca_dividendo 
where  tg_operacion  = op_operacion
and    op_operacion  = di_operacion 
and    di_estado     = @w_est_vencida 
and    op_estado    in (@w_est_vigente, @w_est_vencida)
and    di_fecha_ven <= @w_fecha_vencimiento
and    op_fecha_ult_proceso = @w_fecha_proceso
and    tg_monto     > 0
and    tg_participa_ciclo = 'S'
group by tg_grupo,tg_referencia_grupal
order by tg_grupo,tg_referencia_grupal

if (@@error != 0)
    goto ERROR_PROCESO

update #cab_cobranza set
fecha_solicitud = op_fecha_ini,
tipo_credito    = op_toperacion,
monto_grupal    = op_monto
from  ca_operacion 
where referencia_grupal = op_banco

if (@@error != 0)
    goto ERROR_PROCESO

update #cab_cobranza set
grupo_name = gr_nombre,
asesor_id  = gr_oficial,
sucursal_id= gr_sucursal
from  cobis..cl_grupo
where grupo_id  = gr_grupo

if (@@error != 0)
    goto ERROR_PROCESO
    
update #cab_cobranza set 
asesor_resp = fu_nombre,
login_asesor= fu_login 
from  cobis..cc_oficial, cobis..cl_funcionario
where asesor_id      = oc_oficial
and   oc_funcionario = fu_funcionario

if (@@error != 0)
    goto ERROR_PROCESO

update #cab_cobranza set sucursal_name = nombre
from  cobis..cl_sucursal
where sucursal_id = sucursal

update #cab_cobranza set
ciclo_grupo = ci_ciclo
from  cob_cartera..ca_ciclo
where ci_grupo          = grupo_id
and   referencia_grupal = ci_prestamo

if (@@error != 0)
    goto ERROR_PROCESO

select
grupo      = grupo_id,
operacion  = tg_operacion,
banco      = tg_prestamo,
ref_grupal = referencia_grupal,
cliente    = tg_cliente,
saldo      = (case when di_estado = @w_est_vencida then sum((am_cuota + am_gracia) - am_pagado) else 0 end)
into #saldos_exigible_div
from #cab_cobranza, cob_credito..cr_tramite_grupal,ca_amortizacion,ca_dividendo 
where referencia_grupal    = tg_referencia_grupal
and   tg_operacion  = am_operacion 
and   tg_operacion  = di_operacion
and   tg_participa_ciclo = 'S'
and   tg_monto           > 0
and   convert(varchar,tg_operacion) <> convert(varchar,tg_prestamo)
and   am_dividendo  = di_dividendo
group by grupo_id, referencia_grupal, tg_operacion, tg_prestamo, am_operacion, tg_cliente, di_estado

select
grupo,      operacion,  banco,
ref_grupal, cliente,    saldo =  sum(saldo)
into #saldos_exigible_op
from #saldos_exigible_div
group by grupo, operacion, banco, ref_grupal, cliente

delete ca_cobranza_det_tmp
where cdt_fecha = @w_fecha_proceso
    
insert into ca_cobranza_det_tmp (
cdt_grupo,   cdt_fecha,         cdt_operacion,
cdt_banco,   cdt_cliente,       cdt_monto_exigible)
select
grupo,       @w_fecha_proceso,  operacion,
banco,       cliente,           saldo
from #saldos_exigible_op

if @@error <> 0
begin
   select @w_error = 710001
   goto ERROR_PROCESO
end

select
grupo, ref_grupal, saldo = sum(saldo)
into #saldos_exigible
from #saldos_exigible_op
group by grupo, ref_grupal

if (@@error != 0)
    goto ERROR_PROCESO
    
update #cab_cobranza set monto_exigible = saldo
from  #saldos_exigible
where grupo_id          = grupo
and   referencia_grupal = ref_grupal

if (@@error != 0)
    goto ERROR_PROCESO

select 
grupo      = grupo_id,
ref_grupal = referencia_grupal,
saldo      = sum(cu_valor_actual)
into #saldos_garan
from #cab_cobranza, cob_credito..cr_tramite_grupal, ca_operacion,
     cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia
where referencia_grupal = tg_referencia_grupal
and   tg_prestamo       = op_banco
and   tg_participa_ciclo = 'S'
and   tg_monto           > 0
and   op_tramite        = gp_tramite
and   gp_garantia       = cu_codigo_externo
group by grupo_id, referencia_grupal

if (@@error != 0)
    goto ERROR_PROCESO
    
update #cab_cobranza set saldo_garantia = saldo
from  #saldos_garan
where grupo_id          = grupo
and   referencia_grupal = ref_grupal

if (@@error != 0)
    goto ERROR_PROCESO

update #cab_cobranza set tasa = ro_porcentaje
from ca_operacion, ca_rubro_op
where referencia_grupal = op_banco
and   op_operacion      = ro_operacion
and   ro_concepto       = 'INT'

if (@@error != 0)
    goto ERROR_PROCESO
    
select 
grupo      = grupo_id,
ref_grupal = referencia_grupal,
min(di_fecha_ven) fecha_venc
into  #proximo_venci
from  #cab_cobranza, cob_credito..cr_tramite_grupal,ca_dividendo
where referencia_grupal = tg_referencia_grupal
and   tg_operacion      = di_operacion
and   di_estado         = @w_est_novigente
group by grupo_id, referencia_grupal

if (@@error != 0)
    goto ERROR_PROCESO

update #cab_cobranza set proximo_venc = fecha_venc
from  #proximo_venci
where grupo_id          = grupo
and   referencia_grupal = ref_grupal

if (@@error != 0)
    goto ERROR_PROCESO


/* Datos de valores a recuperar */
select
grupo,
ref_grupal,
cliente as customerId,
upper(ltrim(isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'') + ' ' +
      isnull(en_nombre,'CLIENTE ' + convert(VARCHAR(10),cliente) + ' DEL GRUPO ' +
      convert(VARCHAR(10), grupo)))) as customerName,
convert(MONEY,0) as amountPayWholePayment,
saldo as dueBalance
INTO #ca_detcobsem
from  #saldos_exigible_op
left join cobis..cl_ente on cliente = en_ente

if (@@error != 0)
    goto ERROR_PROCESO

    /* Insertar dato xml */
select @w_fila = 1, @w_rowcount = 1


select @w_entidad = 'PAGOS'

select @w_cod_entidad = c.codigo
from   cobis..cl_tabla t, cobis..cl_catalogo c
where  t.tabla = 'si_sincroniza'
and    c.tabla = t.codigo
and    c.valor = @w_entidad


while @w_rowcount != 0
begin
    select @w_grupoId           = grupo_id,
           @w_referencia_grupal = referencia_grupal,
           @w_usuario           = login_asesor,
           @w_exigible          = monto_exigible,
           @w_afecta_cta        = substring(pago_debito_cta,1,1)
    from #cab_cobranza where fila = @w_fila

    select @w_rowcount = @@rowcount

    if @w_rowcount != 0
    begin
        select @w_secuencial = max(si_secuencial) from cob_sincroniza..si_sincroniza
        select @w_secuencial = isnull(@w_secuencial,0) + 1
                
        insert into cob_sincroniza..si_sincroniza (si_secuencial,si_cod_entidad,si_des_entidad,si_usuario,si_estado,si_fecha_ing,si_num_reg)
            values (@w_secuencial,@w_cod_entidad,@w_entidad,@w_usuario,'P',@w_fecha,1)
            
        if (@@error != 0)
        begin
            select @w_msg = 'Ocurrio un error al insertar el registro en la cob_sincroniza..si_sincroniza'
            goto ERROR_PROCESO
        end
                
        select @w_detdato_xml = (select amountPayWholePayment, customerId, customerName, dueBalance
                                    from #ca_detcobsem as solidarityPaymentCustomerData
                                    where grupo = @w_grupoId and ref_grupal = @w_referencia_grupal
                                    for xml auto, elements)

        select @w_cabdato_xml = (select monto_exigible  as amountChargeWholePayment,
                                        case when datepart(ms,convert(varchar,fecha_solicitud,127)) = 0
                                             then convert(varchar,fecha_solicitud,127) + '.000'
                                             else convert(varchar,fecha_solicitud,127)
                                        end + 'Z' as applicationDate,
                                        sucursal_name   as branchOffice,
                                        tipo_credito    as creditType,
                                        case pago_debito_cta when 'SI' then 'true' else 'false' end as debitsSavingAccounts,
                                        monto_grupal    as groupAmount,
                                        ciclo_grupo     as groupCycle,
                                        grupo_id        as groupId,
                                        grupo_name      as groupName,
                                        cuotas_vencidas as latePayments,
                                        saldo_garantia  as liquidCollateralBalance,
                                        case when datepart(ms,convert(varchar,proximo_venc,127)) = 0
                                             then convert(varchar,proximo_venc,127) + '.000'
                                             else convert(varchar,proximo_venc,127)
                                        end + 'Z' as nextDueDate,
                                        tasa            as rate,
                                        asesor_resp     as responsableOfficer,
                                        plazo           as term
                                from #cab_cobranza as solidarityPaymentData
                                where grupo_id = @w_grupoId and referencia_grupal = @w_referencia_grupal
                                for xml auto, elements)

            select @w_dato_xml = @w_root_tag + @w_detdato_xml + @w_cabdato_xml + @w_root_endtag

            insert into cob_sincroniza..si_sincroniza_det (sid_secuencial,sid_id_entidad,sid_id_1,sid_id_2,sid_xml,sid_accion,sid_observacion)
                values (@w_secuencial,@w_grupoId,0,0,@w_dato_xml,'INGRESAR','Ingresar los pagos solidarios')

            if (@@error != 0)
            begin
                select @w_msg = 'Ocurrio un error al insertar el registro en la cob_sincroniza..si_sincroniza_det'
                goto ERROR_PROCESO
            end
    end
    select @w_fila = @w_fila + 1
end

return 0

ERROR_PROCESO:
exec cobis..sp_ba_error_log
    @t_trn           = 7079,
    @i_operacion     = 'I',
    @i_sarta         = 4, 
    @i_batch         = 7079,
    @i_fecha_proceso = @w_fecha,
    @i_error         = @w_error,
    @i_detalle       = @w_msg

return @w_error

go

