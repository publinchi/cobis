/************************************************************************/
/*      Archivo:                cabancoldex.sp                          */
/*      Stored procedure:       sp_colocacion_bancoldex                 */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Juan B. Quinche                         */
/*      Fecha de escritura:     Mayo 2009                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera datos para el reporte                                    */
/*      Reporte colocaciones por fondos BANCOLDEX                       */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_colocacion_bancoldex')
   drop proc sp_colocacion_bancoldex
go
create proc sp_colocacion_bancoldex
    @i_fecha_ini  datetime  = null, --Fecha inicial de fechas de desembolso
    @i_fecha_fin  datetime  = null  --Fecha final de fechas de desembolso

as

declare @w_sp_name            varchar(32),
        @w_return             int,
        @w_error              int,
        @w_est_vigente        tinyint,
        @w_est_vencido        tinyint,
        @w_est_cancelado      tinyint,
        @w_est_castigado      tinyint,
        @w_est_suspenso       tinyint,
        @w_pa_char_tdr        char(3),
        @w_pa_char_tdn        char(3),
        @w_en_tipo_ced        char(2),
        @w_des_tipo_ced       descripcion,
        @w_en_ced_ruc         numero,
        @w_op_nombre          descripcion,
        @w_op_banco           cuenta,
        @w_cod_estrato        varchar(10),
        @w_des_estrato        descripcion,
        @w_p_fecha_nac        datetime,
        @w_p_ciudad_nac       int,
        @w_nom_ciudad_nac     descripcion,
        @w_tr_fecha_apr       datetime,
        @w_op_tplazo          catalogo,
        @w_op_plazo           smallint,
        @w_plazo_meses        smallint,
        @w_p_sexo             sexo,
        @w_des_sexo           varchar(10),
        @w_dir_microempresa   varchar(254),
        @w_tel_microempresa   varchar(16),
        @w_op_ciudad          int,
        @w_nom_ciudad         descripcion,
        @w_tas_nominal        float,
        @w_edad_deudor        int,
        @w_tot_activos        money,
        @w_op_monto           money,
        @w_sal_capital        money

/* ESTADO DE LAS OPERACIONES */
select @w_est_vigente = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'CANCELADO'

select @w_est_castigado = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'CASTIGADO'

select @w_est_suspenso = es_codigo
from   ca_estado
where  ltrim(rtrim(es_descripcion)) = 'SUSPENSO'

/* PARAMETROS DE TIPOS DE DIRECCION */
select @w_pa_char_tdr = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'TDR'

select @w_pa_char_tdn = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'TDN'

/*CREACION DE TABLA TEMPORAL PARA EL REPORTE */
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ca_rep_coloca_fondos]') and OBJECTPROPERTY(id, N'IsTable') = 1) begin
    drop table cob_cartera..ca_rep_coloca_fondos
end
create table cob_cartera..ca_rep_coloca_fondos
   (
   tmp_en_tipo_ced         char(2)      null,  --Código del tipo de documento del cliente
   tmp_des_tipo_ced        descripcion  null,  --Descripción del tipo de documento del cliente
   tmp_en_ced_ruc          numero       null,  --Número de identificación del cliente
   tmp_op_nombre           descripcion  null,  --Nombre del cliente
   tmp_op_banco            cuenta       null,  --Número de operación de crédito
   tmp_cod_estrato         varchar(10)  null,  --Código del estrato del cliente
   tmp_des_estrato         descripcion  null,  --Descripción del estrato del cliente
   tmp_p_fecha_nac         datetime     null,  --Fecha de nacimiento del cliente
   tmp_p_ciudad_nac        int          null,  --Código ciudad de nacimiento del cliente
   tmp_nom_ciudad_nac      descripcion  null,  --Nombre de la ciudad de nacimiento del cliente
   tmp_tr_fecha_apr        datetime     null,  --Fecha de aprobación del trámite
   tmp_op_tplazo           catalogo     null,  --Tipo de plazo de la operación
   tmp_op_plazo            smallint     null,  --Plazo de la operación según el tipo de plazo
   tmp_pla_meses           smallint     null,  --Plazo de la operación en meses
   tmp_p_sexo              sexo         null,  --Sexo del deudor principal
   tmp_des_sexo            descripcion  null,  --Descripción del sexo del deudor principal
   tmp_dir_microempresa    varchar(254) null,  --Dirección de la microempresa
   tmp_tel_microempresa    varchar(16)  null,  --Teléfono de la microempresa
   tmp_op_ciudad           int          null,  --Código de la ciudad del préstamo
   tmp_nom_ciudad          descripcion  null,  --Nombre de la ciudad del préstamo
   tmp_tas_nominal         float        null,  --Valor de la tasa nominal de interés
   tmp_edad_deudor         int          null,  --Edad del deudor principal
   tmp_tot_activos         money        null,  --Total activos de la microempresa
   tmp_op_monto            money        null,  --Monto del desembolso
   tmp_sal_capital         money        null,  --Saldo de capital a la fecha
   tmp_nit_empresa         numero       null,  --Nit de la microempresa
   tmp_nom_empresa         descripcion  null,  --Nombre de la microempresa
   tmp_cod_act_eco         catalogo     null,  --Código de la actividad económica del cliente
   tmp_nom_act_eco         descripcion  null,  --Descripción de la actividad económica del cliente
   tmp_cod_sec_eco         catalogo     null,  --Código del sector económico del cliente
   tmp_nom_sec_eco         descripcion  null,  --Descripción del sector económico del cliente
   tmp_can_tra_emp         int          null,  --Número de trabajadores de la microempresa
   tmp_fec_liq             datetime     null,  --Fecha de liquidación de la operación
   tmp_tas_efectiva        float        null,  --Tasa efectiva de interés corriente
   tmp_op_cuota            money        null,  --Valor de la cuota inicial del préstamo
   tmp_num_cuo_pen         int          null,  --Número de cuotas pendientes
   tmp_sal_cap_int_imo     money        null,  --Saldo de capital con intereses
   tmp_vlr_com_hon         money        null,
   tmp_cod_destino         catalogo     null,  --Código destino del préstamo
   tmp_des_destino         descripcion  null,  --Descripción del destino económico del préstamo
   tmp_cod_ciu_mic         int          null,  --Código de la ciudad de la microempresa
   tmp_nom_ciu_mic         descripcion  null,  --Nombre de la ciudad de la microempresa
   tmp_num_tel_mic         descripcion  null,  --Número de teléfono de la microempresa
   tmp_cod_lin_cre         catalogo     null,  --Código de la línea de crédito de la operación
   tmp_des_lin_cre         descripcion  null,  --Descripción de la linea de crédito de la operación
   tmp_cod_ofi_pre         smallint     null,  --Código de la oficina de la operación
   tmp_des_ofi_pre         descripcion  null,  --Descripción de la oficina de la operación
   tmp_cod_bar_mic         smallint     null,  --Código del barrio de la microempresa
   tmp_des_bar_mic         descripcion  null,  --Descripción del barrio de la microempresa
   tmp_vlr_cuot            money        null,
   tmp_cod_est_ope         tinyint      null,  --Código del estado de la operación
   tmp_des_est_ope         descripcion  null,  --Descripción del estado de la operación
   tmp_com_pym             money        null,  --Valor rubro mipymes
   tmp_cuo_otr_rub         money        null,  --Valor cuota con otros rubros sin iva
   tmp_tot_gar_pre         money        null,   --Valor garantías prendarias
   tmp_num_obl_int         int          null,    -- Numero de obligacion del intermediario
   tmp_tipo_soc            char(3)      null,
   tmp_fec_desembolso      datetime     null,
   tmp_sector              char(1)      null
   )

/* crear tabla con codigos de fuentes de recurso emprender */
select c.codigo
into #temp_cod
from cobis..cl_tabla as t ,
cobis..cl_catalogo as c
where t.tabla='cr_fuente_recurso'
and t.codigo = c.tabla
and c.valor like '%BANCOLDEX%'


/* INSERCION EN TABLA TEMPORAL DE LOS DATOS DEL REPORTE */
insert into cob_cartera..ca_rep_coloca_fondos
select
      en_tipo_ced,                                --Código del tipo de documento del cliente
      (select valor                               --Nombre del tipo de documento del cliente
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cl_tipo_documento'
       and   c.tabla = t.codigo
       and   c.codigo = en_tipo_ced) ,
      en_ced_ruc,                                 --Número de identificación del cliente
      op_nombre,                                  --Nombre del cliente
      op_banco,                                   --Número de la operación de crédito
      en_estrato,                                 --Estrato del cliente
      (select valor                               --Descripción del estrato del cliente
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cl_estrato'
       and   c.tabla = t.codigo
       and   c.codigo = en_estrato),
      p_fecha_nac,                                --Fecha de nacimiento del cliente
      p_ciudad_nac,                               --Código de ciudad de nacimiento del cliente
      (select valor                               --Descripciópn de la ciudad de nacimiento del cliente
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cl_ciudad'
       and   c.tabla = t.codigo
       and   c.codigo = p_ciudad_nac),
      tr_fecha_apr,                               --Fecha de aprobación del trámite
      op_tplazo,                                  --Tipo de plazo de la operación
      op_plazo,                                   --Plazo de la operación
      (select (op_plazo * td_factor)/30           --Plazo en meses de la operación
       from cob_cartera..ca_tdividendo
       where td_tdividendo = op_tplazo),
      p_sexo,                                     --Código del sexo del cliente
      (select substring(isnull(valor,''),1,10)                               --Descripción del sexo del cliente
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cl_sexo'
       and   c.tabla = t.codigo
       and   c.codigo = p_sexo),
      isnull((select di_descripcion                 --Dirección de la microempresa
       from   cobis..cl_direccion
              left outer join cobis..cl_telefono
              on  te_ente      = di_ente
              and te_direccion = di_direccion
       where di_ente      = op_cliente
       and   di_direccion = @w_pa_char_tdn),'SIN DIRECCION'),
      isnull((select isnull(te_valor,0)                     --Teléfono de la microempresa
       from   cobis..cl_direccion
              left outer join cobis..cl_telefono
              on  te_ente      = di_ente
              and te_direccion = di_direccion
       where di_ente      = op_cliente
       and   di_direccion = @w_pa_char_tdn),''),
      op_ciudad,                                     --Código de ciudad de colocación
      (select valor                                  --Nombre de la ciudad de colocación
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cl_ciudad'
       and   c.tabla = t.codigo
       and   c.codigo = op_ciudad),
      (select ro_porcentaje                          --Tasa nominal del préstamo
       from cob_cartera..ca_rubro_op
       where ro_operacion = op_operacion
       and   ro_concepto = 'INT'),
      (select datediff(yy, p_fecha_nac, getdate())   --Edad del cliente
       from cobis..cl_ente
       where en_ente = op_cliente),
      isnull((select sum(mi_total_eyb + mi_total_cxc + mi_total_mp + mi_total_pep + mi_total_pt + mi_total_af) --Total activos de la microempresa
       from cob_credito..cr_microempresa
       where mi_tramite = op_tramite),0),
      op_monto,                                      --Monto del desembolso de la operación
      (select sum(am_cuota + am_gracia - am_pagado)  --Saldo de capital de la operación
       from cob_cartera..ca_amortizacion
       where am_operacion = op_operacion
       and   am_concepto  = 'CAP'),
      isnull((select mi_identificacion                      --Nit de la empresa
       from cob_credito..cr_microempresa
       where mi_tramite = tr_tramite),''),
      isnull((select mi_nombre                              --Nombre de la empresa
       from cob_credito..cr_microempresa
       where mi_tramite = tr_tramite),''),
      en_actividad,                                         --Actividad económica del cliente
      isnull((select valor                                  --Nombre de la actividad económica del cliente
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cl_actividad'
       and   c.tabla = t.codigo
       and   c.codigo = en_actividad),''),
      en_sector,                                            --Código del sector económico del cliente
      (select valor                                         --Nombre del sector económico del cliente
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cl_sectoreco'
       and   c.tabla = t.codigo
       and   c.codigo = en_sector),
      isnull((select isnull(mi_num_trabaj_remu,0) + isnull(mi_num_trabaj_no_remu,0)   --Número de trabajadores de la microempresa
       from cob_credito..cr_microempresa
       where mi_tramite = tr_tramite),0),                       -- numero de trabajadores
      op_fecha_liq,                                             --Fecha de liquidación de la operación
      (select ro_porcentaje_efa                                 --Tasa efectiva anual
       from cob_cartera..ca_rubro_op
       where ro_operacion = op_operacion
       and   ro_concepto = 'INT'),
      op_cuota,                                             --Valor de la cuota mensual
      (select isnull(count(*),0)                            --Número de cuotas pendientes
       from ca_dividendo
       where di_operacion = op_operacion
       and   di_estado    = 0),
      (select sum(am_cuota + am_gracia - am_pagado)         --Saldo de capital de la operación
       from cob_cartera..ca_amortizacion
       where am_operacion = op_operacion
       and   am_concepto  not in ('CAP','INT','IMO')),
       0,
      tr_destino,                                           --Código destino del préstamo
      isnull((select valor                                  --Descripción destino del préstamo
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cr_destino'
       and   c.tabla = t.codigo
       and   c.codigo = tr_destino),0) ,
      isnull((select mi_ciudad                               --Código ciudad de la microempresa
       from cob_credito..cr_microempresa
       where mi_tramite = tr_tramite),0),
      isnull((select valor                                   --Nombre de la ciudad de la microempresa
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cl_ciudad'
       and   c.tabla = t.codigo
       and   c.codigo = (select top 1 mi_ciudad
                         from cob_credito..cr_microempresa
                         where mi_tramite = tr_tramite)),''),
      isnull((select mi_telefono                                --Número de teléfono de la microempresa
       from cob_credito..cr_microempresa
       where mi_tramite = tr_tramite),''),
      op_toperacion,                                            --Código de la línea de crédito
      isnull((select valor                                      --Descripción de la línea de crédito
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'ca_toperacion'
       and   c.tabla = t.codigo
       and   c.codigo = op_toperacion),0),
      op_oficina,                                               --Código de la oficina
      (select of_nombre                                         --Nombre de la oficina
       from cobis..cl_oficina
       where of_oficina = op_oficina),

      isnull((select mi_barrio                               --Código barrio de la microempresa
       from cob_credito..cr_microempresa
       where mi_tramite = tr_tramite),''),
      isnull((select valor                                   --Nombre del barrio de la microempresa
       from cobis..cl_tabla t,
            cobis..cl_catalogo c
       where t.tabla = 'cl_parroquia'
       and   c.tabla = t.codigo
       and   c.codigo = (select top 1 mi_barrio
                         from cob_credito..cr_microempresa
                         where mi_tramite = tr_tramite)),''),
       0,
       op_estado,                                               --Código del estado de la operación
      isnull((select es_descripcion                             --Descripción del estado de la operación
       from ca_estado
       where es_codigo = op_estado),''),
      isnull((select ro_valor                                   --Valor MIPYMES
       from cob_cartera..ca_rubro_op
       where ro_operacion = op_operacion
       and   ro_concepto = 'MIPYMES'),''),
      (select sum(ro_valor)                                     --Valor cuota con otros rubros sin iva
       from cob_cartera..ca_rubro_op
       where ro_operacion = op_operacion
       and   ro_tipo_rubro in ('C','Q','M','I')),
      isnull((select sum(dj_total_bien)                         --Sumatoria de garantias prendarias de la microempresa
       from cob_credito..cr_microempresa,
            cob_credito..cr_dec_jurada
       where mi_tramite    = tr_tramite
       and   dj_codigo_mic = mi_secuencial
      group by mi_secuencial),0),
      0,                 
       '',
       isnull((select dm_fecha
        from cob_cartera..ca_desembolso
        where dm_operacion= op_operacion),''),
       ' '


from  cob_cartera..ca_operacion,
      cob_credito..cr_tramite,
      cobis..cl_ente
where op_estado     in (@w_est_vigente,@w_est_vencido,@w_est_cancelado,@w_est_castigado,@w_est_suspenso)
and   op_fecha_liq  between @i_fecha_ini and @i_fecha_fin
and   tr_tramite    = op_tramite
and   en_ente       = op_cliente
and   tr_fuente_recurso  in (select * from #temp_cod)    -- fondo emprender

order by op_oficina

select
tmp_en_tipo_ced,
tmp_des_tipo_ced,
tmp_en_ced_ruc,
tmp_op_nombre,
tmp_op_banco,
tmp_cod_estrato,
tmp_des_estrato,
tmp_p_fecha_nac,
tmp_p_ciudad_nac,
tmp_nom_ciudad_nac,
tmp_tr_fecha_apr,
tmp_op_tplazo,
tmp_op_plazo,
tmp_pla_meses ,
tmp_p_sexo   ,
tmp_des_sexo  ,
tmp_dir_microempresa,
tmp_tel_microempresa,
tmp_op_ciudad      ,
tmp_nom_ciudad     ,
tmp_tas_nominal    ,
tmp_edad_deudor    ,
tmp_tot_activos    ,
tmp_op_monto       ,
tmp_sal_capital,
tmp_nit_empresa,
tmp_nom_empresa,
tmp_cod_act_eco,
tmp_nom_act_eco,
tmp_cod_sec_eco,
tmp_nom_sec_eco,
tmp_can_tra_emp,
tmp_fec_liq  ,
tmp_tas_efectiva,
tmp_op_cuota  ,
tmp_num_cuo_pen,
tmp_sal_cap_int_imo,
tmp_vlr_com_hon,
tmp_cod_destino,
tmp_des_destino,
tmp_cod_ciu_mic,
tmp_nom_ciu_mic,
tmp_num_tel_mic,
tmp_cod_lin_cre,
tmp_des_lin_cre,
tmp_cod_ofi_pre,
tmp_des_ofi_pre,
tmp_cod_bar_mic,
tmp_des_bar_mic,
tmp_vlr_cuot, 
tmp_cod_est_ope,
tmp_des_est_ope,
tmp_com_pym,
tmp_cuo_otr_rub,   
tmp_tot_gar_pre,   
tmp_num_obl_int ,  
tmp_tipo_soc,
tmp_fec_desembolso,
tmp_sector
from ca_rep_coloca_fondos
return 0
ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error

return @w_error

go
