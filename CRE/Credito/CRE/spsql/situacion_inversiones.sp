/************************************************************************/
/*  Archivo:                situacion_inversiones.sp                    */
/*  Stored procedure:       sp_situacion_inversiones                    */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_situacion_inversiones')
    drop proc sp_situacion_inversiones
go

create proc sp_situacion_inversiones(
    @t_file               varchar(14) = null,
    @t_debug              char(1)     = 'N',
    @s_sesn               int         = null,
    @s_user               login       = null,
    @s_date               datetime    = null,
    @i_tramite            int         = null,
    @i_act_can            char(1)     = 'N', -- ECA: Activos y cancelados
    @t_show_version       bit = 0 -- Mostrar la version del programa
    )
as
declare
   @w_sp_name           varchar(32),
   @w_cliente           int,
   @w_def_moneda        tinyint,
   @w_riesgo            money,
   @w_archivo           char(12),
   @w_mensaje           varchar(24),
   @w_fecha             datetime,
   @w_est_vencido       tinyint,
   @w_est_cancelado     tinyint,
   @w_est_vigente       tinyint,
   @w_descripcion       varchar(255),
   @w_nombre            varchar(255),
   @w_nombre_des        varchar(255),
   @w_operacion         int,
   @w_spid              smallint

select     @w_sp_name = 'sp_dato_inversiones',
    @w_archivo = 'cr_siinv.sp'

if @t_show_version = 1
begin
    print 'Stored procedure sp_situacion_inversiones, Version 4.0.0.3'
    return 0
end

-- obtengo numero de proceso
select @w_spid = @@spid

-- Cargo Moneda Local
select @w_def_moneda = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'MLOCR'

if @@rowcount = 0
begin
   /*Registro no existe */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101005
      return 1
end

-- Cargo fecha de proceso
select @w_fecha = fp_fecha
from cobis..ba_fecha_proceso

insert into cr_cotiz3_tmp
(spid, moneda, cotizacion)
select
@w_spid, a.ct_moneda, a.ct_compra
from  cob_credito..cb_cotizaciones a

if not exists(select * from cr_cotiz3_tmp where moneda = @w_def_moneda and spid = @w_spid)
insert into cr_cotiz3_tmp (spid, moneda, cotizacion)
values (@w_spid, @w_def_moneda, 1)

-- Inserto Datos de Cuentas Corrientes
--Se comenta porque en el proyecto no se tiene cuentas corrientes
/*
insert into  cr_situacion_inversiones
(si_cliente,
 si_tramite,
 si_usuario,
 si_secuencia,
 si_tipo_con,
 si_cliente_con,
 si_identico,
 si_categoria,
 si_desc_categoria,
 si_producto,
 si_tipo_op,
 si_desc_tipo_op,
 si_numero_operacion,
 si_tasa,
 si_fecha_apt,
 si_moneda,
 si_saldo,
 si_saldo_ml,
 si_saldo_promedio,
 si_fecha_ult_mov,
 si_interes_acumulado,
 si_valor_garantia,
 si_monto_prendado,
 si_valor_mercado,
 si_estado,
 si_desc_estado,
 si_operacion,
 si_valor_mercado_ml,
 si_rol,
 si_bloqueos,
 si_fecha_can,
 si_oficina,
 si_desc_oficina
)
select distinct
 cl_cliente,
 sc_tramite,
 sc_usuario,
 sc_secuencia,
 sc_tipo_con,
 sc_cliente_con,
 sc_identico,
 '01',
 (select x.valor
  from cobis..cl_catalogo x,
       cobis..cl_tabla y
  where y.codigo = x.tabla
  and   y.tabla = 'cl_categoria_prod'
  and   x.codigo = '01'),
 'CTE',
 convert(varchar(10), a.cc_prod_banc),
 pb_descripcion,
 a.cc_cta_banco,
 round( (isnull(a.cc_tasa_hoy,0)),4),
 a.cc_fecha_aper,
 a.cc_moneda,
 case a.cc_prod_banc  when 3 then 0 else (a.cc_disponible + a.cc_12h + a.cc_24h + a.cc_48h + a.cc_remesas ) end,                        -- SALDO CONTABLE Efectivo + Canje .... + cc_otros_valores),
 case a.cc_prod_banc  when 3 then 0 else (isnull((a.cc_disponible+  a.cc_12h + a.cc_24h+ a.cc_48h+ a.cc_remesas ),0) * cotizacion) end,  -- + cc_otros_valores
 case a.cc_prod_banc  when 3 then 0 else a.cc_promedio1 end,
 a.cc_fecha_ult_mov,
 case a.cc_prod_banc  when 3 then 0 else (a.cc_disponible - isnull(a.cc_monto_blq,0) - isnull( cc_monto_emb, 0)) end,            -- SALDO DISPONIBLE Vivi disponible - valores bloq - pignorados
 case a.cc_prod_banc  when 3 then 0 else (a.cc_12h+ a.cc_24h+ a.cc_48h+ a.cc_remesas) end,    --
 case a.cc_prod_banc  when 3 then 0 else (isnull( a.cc_monto_blq, 0)) end ,                    --
 sb_monto_aut,                                    -- Lìmite Sobre
 a.cc_estado,
 (select x.valor
  from cobis..cl_catalogo x,
       cobis..cl_tabla y
  where y.codigo = x.tabla
  and   y.tabla = 'cc_estado_cta'
  and   x.codigo = a.cc_estado),
 cc_protestos,
 case a.cc_prod_banc  when 3 then 0 else  ((a.cc_disponible - isnull(cc_monto_blq, 0) )* cotizacion) end,
 cl_rol,
 a.cc_monto_emb,
 case a.cc_estado when 'C' then (select max(hc_fecha) from cob_cuentas..cc_his_cierre where hc_estado = 'C' and hc_cuenta = a.cc_ctacte) else null end,
 a.cc_oficina,
 (select of_nombre from cobis..cl_oficina where of_oficina =  a.cc_oficina and of_filial = a.cc_filial)
from cob_cuentas..cc_ctacte a,
     cob_remesas..pe_pro_bancario,
     cobis..cl_det_producto, cobis..cl_cliente,
     cr_situacion_cliente,
     cob_cuentas..cc_sobregiro ,
     cr_cotiz3_tmp b
where     a.cc_moneda     = b.moneda
and     dp_det_producto = cl_det_producto
and     cl_cliente      = sc_cliente
and     dp_producto     = 3
and     dp_cuenta       = a.cc_cta_banco
and     cl_rol          <> 'F'
and     a.cc_estado     <> (case @i_act_can when 'N' then 'C' else '' end) -- ECA : Estados para las cuentas de ahorros
and     pb_pro_bancario = a.cc_prod_banc
and     sc_usuario      = @s_user
and     sc_secuencia    = @s_sesn
and     sc_tramite      = @i_tramite
and     sb_cuenta       =* a.cc_ctacte
and     sb_tipo         IN ('C', 'O')
and     sb_fecha_ven    >= @s_date
and     spid            = @w_spid

if @@error <> 0
begin
-- Error en insercion de registro
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 2103001
    ROLLBACK
    return 1
end
*/

-- INSERTO DATOS DE CUENTAS DE AHORRO
insert into  cr_situacion_inversiones
(si_cliente,
 si_tramite,
 si_usuario,
 si_secuencia,
 si_tipo_con,
 si_cliente_con,
 si_identico,
 si_categoria,
 si_desc_categoria,
 si_producto,
 si_tipo_op,
 si_desc_tipo_op,
 si_numero_operacion,
 si_tasa,
 si_fecha_apt,
 si_moneda,
 si_saldo,
 si_saldo_ml,
 si_saldo_promedio,
 si_fecha_ult_mov,
 si_interes_acumulado,
 si_valor_garantia,
 si_monto_prendado,
 si_valor_mercado,
 si_estado,
 si_desc_estado,
 si_rol,
 si_bloqueos,
 si_fecha_can,
 si_oficina,
 si_desc_oficina
)
select distinct
 cl_cliente,
 sc_tramite,
 sc_usuario,
 sc_secuencia,
 sc_tipo_con,
 sc_cliente_con,
 sc_identico,
 '012',
 (select x.valor
  from cobis..cl_catalogo x,
       cobis..cl_tabla y
  where y.codigo = x.tabla
  and   y.tabla = 'cl_categoria_prod'
  and   x.codigo = '04'),
 'AHO',
 convert(varchar(10), ah_prod_banc),
 pb_descripcion,
 ah_cta_banco,
 round((isnull( ah_tasa_hoy, 0) ),4),
 ah_fecha_aper,
 ah_moneda,
 case ah_prod_banc  when 6 then 0 else  (ah_12h+ah_24h+ah_48h+ah_remesas+ah_disponible) end,
 case ah_prod_banc  when 6 then 0 else  (isnull((ah_12h+ah_24h+ah_48h+ah_remesas+ah_disponible),0)*cotizacion) end,
 case ah_prod_banc  when 6 then 0 else  ah_promedio1 end,
 ah_fecha_ult_mov,
 case ah_prod_banc  when 6 then 0 else  (ah_disponible - isnull(ah_monto_bloq, 0) - isnull( ah_monto_emb, 0)) end,
 case ah_prod_banc  when 6 then 0 else  (ah_12h+ah_24h+ah_48h+ah_remesas) end,
 case ah_prod_banc  when 6 then 0 else  (isnull(ah_monto_bloq, 0)) end ,
 case ah_prod_banc  when 6 then 0 else  ((ah_disponible - isnull(ah_monto_bloq, 0) )* cotizacion) end,
 ah_estado,
 (select x.valor
  from cobis..cl_catalogo x,
       cobis..cl_tabla y
  where y.codigo = x.tabla
  and   y.tabla = 'ah_estado_cta'
  and   x.codigo = a.ah_estado),
 cl_rol,
 ah_monto_emb,
 case ah_estado when 'C' then (select max(hc_fecha) from cob_ahorros..ah_his_cierre where hc_estado = 'C' and hc_cuenta = a.ah_cuenta) else null end,
 ah_oficina,
 (select of_nombre from cobis..cl_oficina where of_oficina =  a.ah_oficina and of_filial = a.ah_filial)
from cob_ahorros..ah_cuenta as a,
     cob_remesas..pe_pro_bancario,
     cobis..cl_det_producto, cobis..cl_cliente,
     cr_situacion_cliente,
     cr_cotiz3_tmp b
where   ah_moneda       = b.moneda
and     dp_det_producto = cl_det_producto
and     cl_cliente      = sc_cliente
and     dp_producto     = 4
and     dp_cuenta       = ah_cta_banco
and     cl_rol          <> 'F'
and     ah_estado       <> (case @i_act_can when 'N' then 'C' else '' end) -- ECA : Estados para las cuentas de ahorros
and     pb_pro_bancario = ah_prod_banc
and     sc_usuario      = @s_user
and     sc_secuencia    = @s_sesn
and     sc_tramite      = @i_tramite
and     spid            = @w_spid

if @@error <> 0
begin
-- Error en insercion de registro
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 2103001
    ROLLBACK
    return 1
end

-- Inserto Datos de Plazo Fijo
insert into  cr_situacion_inversiones
(si_cliente,
 si_tramite,
 si_usuario,
 si_secuencia,
 si_tipo_con,
 si_cliente_con,
 si_identico,
 si_categoria,
 si_desc_categoria,
 si_producto,
 si_tipo_op,
 si_desc_tipo_op,
 si_numero_operacion,
 si_tasa,
 si_fecha_apt,
 si_fecha_vct,
 si_moneda,
 si_valor_garantia,
 si_monto_prendado,
 si_fecha_prox_p_int,
 si_fecha_utl_p_int,
 si_interes_acumulado,
 si_saldo,
 si_saldo_ml,
 si_estado,
 si_desc_estado,
 si_rol,
 si_plazo,
 si_fecha_can,
 si_oficina,
 si_desc_oficina
)
select distinct
 op_ente,
 sc_tramite,
 sc_usuario,
 sc_secuencia,
 sc_tipo_con,
 sc_cliente_con,
 sc_identico,
 '02',
 (select x.valor
  from cobis..cl_catalogo x,
       cobis..cl_tabla y
  where y.codigo = x.tabla
  and   y.tabla = 'cl_categoria_prod'
  and   x.codigo = '02'),
 'PFI',
 op_toperacion,
 td_descripcion,
 op_num_banco,
 op_tasa,
 op_fecha_valor,
 op_fecha_ven,
 op_moneda,
 op_monto_pgdo,
 op_monto_pgdo,
 op_fecha_pg_int,
 op_fecha_ult_pg_int,
 op_int_ganado,
 op_monto,
 isnull((op_monto),0) * cotizacion,
 op_estado,
 (select x.valor
  from cobis..cl_catalogo x,
       cobis..cl_tabla y
  where y.codigo = x.tabla
  and   y.tabla = 'pf_estado'
  and   x.codigo = o.op_estado),
 'T',
 op_plazo_orig,
 op_fecha_cancela,
 op_oficina,
 (select of_nombre from cobis..cl_oficina where of_oficina = o.op_oficina)
from   cob_pfijo..pf_operacion o with (index (pf_operacion_C_Key)),
       cob_pfijo..pf_tipo_deposito,
       cr_situacion_cliente,
       cr_cotiz3_tmp b
where  op_ente       = sc_cliente
and    b.moneda      = op_moneda
and    op_estado <> (case @i_act_can when 'N' then 'CAN' else '' end) -- ECA : Estados para las cuentas de ahorros
and    op_estado not in ('ANU', 'ING')
and    op_toperacion = td_mnemonico
and    sc_usuario    = @s_user
and    sc_secuencia  = @s_sesn
and    sc_tramite    = @i_tramite
and    spid          = @w_spid

if @@error <> 0
begin
/* Error en insercion de registro */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 2103001
    ROLLBACK
    return 1
end

-- Inserto Datos de Plazo Fijo
insert into  cr_situacion_inversiones
(si_cliente,
 si_tramite,
 si_usuario,
 si_secuencia,
 si_tipo_con,
 si_cliente_con,
 si_identico,
 si_categoria,
 si_desc_categoria,
 si_producto,
 si_tipo_op,
 si_desc_tipo_op,
 si_numero_operacion,
 si_tasa,
 si_fecha_apt,
 si_fecha_vct,
 si_moneda,
 si_valor_garantia,
 si_monto_prendado,
 si_fecha_prox_p_int,
 si_fecha_utl_p_int,
 si_interes_acumulado,
 si_saldo,
 si_saldo_ml,
 si_estado,
 si_desc_estado,
 si_rol,
 si_plazo,
 si_fecha_can,
 si_oficina,
 si_desc_oficina
)
select distinct
 be_ente,
 sc_tramite,
 sc_usuario,
 sc_secuencia,
 sc_tipo_con,
 sc_cliente_con,
 sc_identico,
 '02',
 (select x.valor
  from cobis..cl_catalogo x,
       cobis..cl_tabla y
  where y.codigo = x.tabla
  and   y.tabla = 'cl_categoria_prod'
  and   x.codigo = '02'),
 'PFI',
 op_toperacion,
 td_descripcion,
 op_num_banco,
 op_tasa,
 op_fecha_valor,
 op_fecha_ven,
 op_moneda,
 op_monto_pgdo,
 op_monto_pgdo,
 op_fecha_pg_int,
 op_fecha_ult_pg_int,
 op_int_ganado,
 op_monto,
 isnull((op_monto),0) * cotizacion,
 op_estado,
 (select x.valor
  from cobis..cl_catalogo x,
       cobis..cl_tabla y
  where y.codigo = x.tabla
  and   y.tabla = 'pf_estado'
  and   x.codigo = o.op_estado),
 case be_rol + be_tipo
 when 'TT' then 'T'
 when 'TF' then 'F'
 when 'AT' then 'A'
 end,
 op_plazo_orig,
 op_fecha_cancela,
 op_oficina,
 (select of_nombre from cobis..cl_oficina where of_oficina = o.op_oficina)
from   cob_pfijo..pf_operacion o with (index (pf_operacion_C_Key)),
       cob_pfijo..pf_tipo_deposito,
       cob_pfijo..pf_beneficiario,
       cr_situacion_cliente,
       cr_cotiz3_tmp b
where  be_ente = sc_cliente
and    be_ente <> op_ente
and    be_operacion = op_operacion
and    b.moneda = op_moneda
and    op_estado <> (case @i_act_can when 'S' then 'CAN' else '' end) -- ECA : Estados para las cuentas de ahorros
and    op_estado not in ('ANU', 'ING')
and    op_toperacion = td_mnemonico
and    sc_usuario = @s_user
and    sc_secuencia = @s_sesn
and    sc_tramite   = @i_tramite
and    be_estado = 'I'
and   op_num_banco not in (select si_numero_operacion
                             from cr_situacion_inversiones
                            where si_usuario   = @s_user
                              and si_secuencia = @s_sesn
                              and si_tramite   = @i_tramite
                              and si_categoria = '02')
and    spid         = @w_spid

if @@error <> 0
begin
/* Error en insercion de registro */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 2103001
    ROLLBACK
    return 1
end

delete from cr_cotiz3_tmp where spid = @w_spid --tabla de cotizaciones

return 0

GO
