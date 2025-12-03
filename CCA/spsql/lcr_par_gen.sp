/************************************************************************/
/*      Archivo:                lcr_pargen.sp                           */
/*      Stored procedure:       sp_lcr_parametros_generales             */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           TBA                                     */
/*      Fecha de escritura:     Nov/2018                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera preguntas de verificacion para recuperacion de clave     */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/*    21/Nov/2018           TBA              Emision Inicial            */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_lcr_parametros_generales')
    drop proc sp_lcr_parametros_generales
go

create proc sp_lcr_parametros_generales(
@s_ssn           int          = null,
@s_sesn          int          = null,
@s_date          datetime     = null,
@s_user          login        = null,
@s_term          varchar(30)  = null,
@s_ofi           smallint     = null,
@s_srv           varchar(30)  = null,
@s_lsrv          varchar(30)  = null,
@s_rol           smallint     = null,
@s_org           varchar(15)  = null,
@s_culture       varchar(15)  = null,
@t_rty           char(1)      = null,
@t_debug         char(1)      = 'N',
@t_file          varchar(14)  = null,
@t_trn           smallint     = null,
@i_banco         cuenta,
@i_cliente       int,
@o_msg           varchar(200) = null output
)
as
declare
@w_sp_name              varchar(25),
@w_tasa_iva             float,
@w_error                int,
@w_tasa_referencial     varchar(20),
@w_sector               catalogo,
@w_operacionca          int,
@w_valor_variable_regla varchar(200), 
@w_msg                  varchar(200), 
@w_monto_min            varchar(200),
@w_monto_max            varchar(200),
@w_nro_ciclo            int,
@w_tipo_mercado         varchar(10)

select  @w_sp_name = 'sp_lcr_parametros_generales'

IF OBJECT_ID('tempdb..#tasas_comision') IS NOT NULL DROP TABLE #tasas_comision

create table #tasas_comision (
valor_inicio money,
valor_fin money,
porcentaje float
)


select
@w_sector      = op_sector, 
@w_operacionca = op_operacion
from ca_operacion
where op_banco    = @i_banco

if @@rowcount = 0 begin
    select 
	@w_error = 724617, 
	@o_msg   = 'ERROR: ESTE CLIENTE NO TIENE OPERACION REVOLVENTE'
	goto ERROR
end

select @w_tasa_referencial = ro_referencial
from cob_cartera..ca_rubro_op
where ro_operacion = @w_operacionca
and ro_concepto = 'IVA_INT'

select @w_tasa_iva = vd_valor_default
from ca_valor_det
where vd_tipo = @w_tasa_referencial
and vd_sector = @w_sector

if @@rowcount = 0 begin
    select 
	@w_error = 724669, 
	@o_msg   = 'ERROR: AL OBTENER LA TASA IVA'
	goto ERROR
end

--SRO. Valor tipo Mercado
SELECT @w_nro_ciclo = en_nro_ciclo  
from cobis..cl_ente
where en_ente = @i_cliente

if isnull(@w_nro_ciclo, 0) = 0
   select @w_tipo_mercado = 'MA'
else 
   select @w_tipo_mercado = 'CC'

select @w_valor_variable_regla = @w_tipo_mercado
exec @w_error           = cob_cartera..sp_ejecutar_regla
@s_ssn                  = @s_ssn,
@s_ofi                  = @s_ofi,
@s_user                 = @s_user,
@s_date                 = @s_date,
@s_srv                  = @s_srv,
@s_term                 = @s_term,
@s_rol                  = @s_rol,
@s_lsrv                 = @s_lsrv,
@s_sesn                 = @s_ssn,
@i_regla                = 'LCRMMUTI', 
@i_tipo_ejecucion       = 'REGLA',
@i_valor_variable_regla = @w_valor_variable_regla,
@o_resultado1           = @w_monto_min out

if @w_error <> 0 or @w_monto_min is null
begin
    select @w_monto_min = 100
end

exec @w_error           = cob_cartera..sp_ejecutar_regla
@s_ssn                  = @s_ssn,
@s_ofi                  = @s_ofi,
@s_user                 = @s_user,
@s_date                 = @s_date,
@s_srv                  = @s_srv,
@s_term                 = @s_term,
@s_rol                  = @s_rol,
@s_lsrv                 = @s_lsrv,
@s_sesn                 = @s_ssn,
@i_regla                = 'LCRVALINC', 
@i_tipo_ejecucion       = 'REGLA',	 
@i_valor_variable_regla = @w_valor_variable_regla,
@o_resultado2           = @w_monto_max out

if @w_error <> 0
begin
    select @w_monto_max = 0
end

insert into #tasas_comision
select 
'valor_inicio'=case cr1.cr_operator when 'between' then cr1.cr_min_value when '>' then cr1.cr_max_value +1 else 0 end,
'valor_fin'=case cr1.cr_operator when 'between' then cr1.cr_max_value else @w_monto_max end,
'porcentaje'=cr2.cr_max_value
from cob_pac..bpl_condition_rule cr1 inner join cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent
inner join cob_workflow..wf_variable v1 on cr1.vd_id = v1.vb_codigo_variable
inner join cob_workflow..wf_variable v2 on cr2.vd_id = v2.vb_codigo_variable
inner join cob_pac..bpl_rule_version rv on cr2.rv_id = rv.rv_id
inner join cob_pac..bpl_rule ru on rv.rl_id = ru.rl_id
where rl_acronym           = 'LCRPORCOM'
and   rv_status            = 'PRO'
and   v2.vb_abrev_variable = 'PORCOMIS'
and   v1.vb_abrev_variable = 'VALDISPO'

update #tasas_comision
set valor_inicio = @w_monto_min
where valor_inicio = 0

select @w_tasa_iva

select valor_inicio,
valor_fin,
porcentaje
from #tasas_comision
order by valor_inicio

if @@rowcount = 0 begin
    select 
	@w_error = 724669, 
	@o_msg   = 'ERROR: AL OBTENER PORCENTAJE DE COMISION POR UTILIZACION'
	goto ERROR
end

return 0

ERROR:

		
return @w_error

go
