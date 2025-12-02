/************************************************************************/
/*  Archivo:                situacion_lineas.sp                         */
/*  Stored procedure:       sp_situacion_lineas                         */
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

if exists(select 1 from sysobjects where name ='sp_situacion_lineas')
    drop proc sp_situacion_lineas
go

create proc sp_situacion_lineas (
        @t_file               varchar(14) = null,
        @t_debug              char(1)  = 'N',
        @s_ssn                int = null,
        @s_sesn               int = null,
        @s_date               datetime = null,
        @s_user               login = null,
        @i_tramite            int   = 0,
        @i_tramite_d          int   = null,
        @i_grupo              int   = null,
        @i_cliente            int   = null,
        @i_tipo_deuda         char(1) = 'T',
        @i_prendario          char(1) = 'S',
        @i_impresion          char(1) = 'S',
        @t_show_version       bit = 0,
        @i_act_can            char(1) = 'N', -- Activos (N) y Cancelados + Activos (S),
        @i_vista_360          char(1) = 'N'
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
   @w_cancelada         catalogo,
   @w_vigente           catalogo,
   @w_tipo_personal     catalogo,
   @w_linea             int,
   @w_factor_aux        int,
   @w_sector            catalogo,
   @w_tbase             catalogo,
   @w_spread            float,
   @w_porcentaje        float,
   @w_tasa_calc         float,
   @w_tasa_asociada     char(1),
   @w_tramite           int,
   @w_return            int,
   @w_tipo_tr           char(1),
   @w_monto_pro         money,
   @w_monto_lin         money,
   @w_cliente_con       int,
   @w_tr_monto          money,
   @w_sl_monto_riesgo   money,
   @w_li_utilizado      money,
   @w_producto          catalogo,
   @w_utilizado         money,
   @w_estado_garantia    varchar(64),
   @w_spid              smallint,
   @w_tipo_linea       varchar(64)


select @w_sp_name = 'sp_situacion_lineas',
       @w_archivo = 'cr_silin.sp'

if @t_show_version = 1
begin
    print 'Stored procedure sp_situacion_lineas , Version 4.0.0.3'
    return 0
end

-- obtengo numero de proceso
select @w_spid = @@spid

select @w_tipo_linea = 'LCR'

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

-- CREACION DE TABLA DE COTIZACIONES
delete from cr_cotiz3_tmp where spid = @w_spid
insert into cr_cotiz3_tmp
(spid, moneda, cotizacion)
select
@w_spid, a.ct_moneda, a.ct_compra
from  cob_credito..cb_cotizaciones a

-- insertar un registro para moneda local en caso de no existir
if not exists(select * from cr_cotiz3_tmp where moneda = @w_def_moneda and spid = @w_spid)
insert into cr_cotiz3_tmp (spid, moneda, cotizacion)
values (@w_spid, @w_def_moneda, 1)

/*** CODIGO DEL ESTADO CANCELADA DE LA LINEA  ***/
select @w_cancelada = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CRE'
   and pa_nemonico = 'ECANLN'

/*** CODIGO DEL ESTADO VIGENTE DE LA LINEA  ***/
select @w_vigente = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CRE'
   and pa_nemonico = 'EVIGLN'


-- Riesgos Directos
if @i_tipo_deuda = 'D' or @i_tipo_deuda = 'T'
BEGIN
    -- LINEAS DE SOBREGIRO
    insert into  cr_situacion_lineas
    (sl_cliente,      sl_usuario,     sl_secuencia,       sl_tramite,
     sl_tipo_con,     sl_cliente_con, sl_identico,        sl_producto,
     sl_tramite_d,    sl_sector,      sl_numero_op_banco, sl_linea,
     sl_fecha_apr,    sl_fecha_vct,   sl_limite_credito,
     sl_val_utilizado,
     sl_disponible,   sl_disponible_ml,     sl_moneda,    sl_utilizado_ml,
     sl_tipo,         sl_desc_tipo,
     sl_tasa,         sl_estado   ,   sl_desc_estado,
     sl_execeso,
     sl_monto_riesgo,
     sl_tipo_deuda,
     sl_plazo,
     sl_frecuencia
    )
    select distinct   tr_cliente,     sc_usuario,     sc_secuencia,     sc_tramite,
     sc_tipo_con,     sc_cliente_con, sc_identico,    isnull( tr_toperacion, 'CRE'),
     l.li_tramite,    tr_sector,      l.li_num_banco, l.li_numero,
     l.li_fecha_inicio,l.li_fecha_vto, l.li_monto,

    (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end),
     (isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end)),
     (isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end))*cotizacion,
     l.li_moneda,
     (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end) *cotizacion,
     tr_toperacion,
     isnull( (select valor from cobis..cl_catalogo b, cobis..cl_tabla a
       where a.tabla = 'cr_clase_linea' and a.codigo = b.tabla
         and b.codigo = cr_tramite.tr_toperacion), 'CREDITO'),
     0.0,            l.li_estado,  (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                   where a.tabla = 'cr_estado_linea' and a.codigo = b.tabla
                                     and b.codigo = l.li_estado),
     case sign( li_monto - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end)  )
      when -1 then abs(li_monto - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end)  )
      else 0.0 end,

     case sign(isnull( l.li_monto * cotizacion,0) - (case sign( cc_disponible * cotizacion) when -1 then abs(cc_disponible *cotizacion ) else 0 end))
      when -1 then 0
      else abs(isnull( l.li_monto * cotizacion,0) - (case sign( cc_disponible * cotizacion) when -1 then abs(cc_disponible *cotizacion) else 0 end)) end,
     'D',
     isnull(tr_plazo, datediff(dd, li_fecha_inicio, li_fecha_vto)/30),
     0 --no existe tr_tplazo
    from cr_linea l,
        cr_tramite, -- JES --> with (index(tr_toperacion_key)) ,
        cr_cotiz3_tmp b,
        cr_situacion_cliente,
        cr_deudores, cob_cuentas..cc_ctacte
    where l.li_tramite = tr_tramite
    and   tr_toperacion= 'SGC'
    and   l.li_moneda  = b.moneda
    and   tr_tramite   = de_tramite
    and   de_cliente   = sc_cliente
    and   sc_usuario   = @s_user
    and   sc_secuencia = @s_sesn
    and   sc_tramite   = @i_tramite
    and   sc_tipo_con  = 'C'
    and   l.li_estado  <> (case @i_act_can when 'N' then @w_cancelada  else '' end)--@w_cancelada
    and   l.li_num_banco <> ''
    and   0 = cc_cta_banco  --and   l.li_cuenta  = cc_cta_banco
    and   li_cliente   = sc_cliente
    and   tr_estado in ('A', 'N')
    and   spid         = @w_spid

    if @@error <> 0
    begin
       /* Error en insercion de registro */
    exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2103001
        rollback
    return 1
    end

    insert into  cr_situacion_lineas
    (sl_cliente,      sl_usuario,     sl_secuencia,       sl_tramite,
     sl_tipo_con,     sl_cliente_con, sl_identico,        sl_producto,
     sl_tramite_d,    sl_sector,      sl_numero_op_banco, sl_linea,
     sl_fecha_apr,    sl_fecha_vct,   sl_limite_credito,

     sl_val_utilizado,
     sl_disponible,   sl_disponible_ml,     sl_moneda,    sl_utilizado_ml,
     sl_tipo,         sl_desc_tipo,
     sl_tasa,         sl_estado   ,   sl_desc_estado,
     sl_execeso,
     sl_monto_riesgo,
     sl_tipo_deuda,
     sl_plazo,
     sl_frecuencia
    )
    select distinct   tr_cliente,     sc_usuario,     sc_secuencia,     sc_tramite,
     sc_tipo_con,     sc_cliente_con, sc_identico,    isnull( tr_toperacion, 'CRE'),
     l.li_tramite,    tr_sector,      l.li_num_banco, l.li_numero,
     l.li_fecha_inicio,l.li_fecha_vto, l.li_monto,

     0,
     l.li_monto ,
     l.li_monto*cotizacion,
     l.li_moneda,
     0,
     tr_toperacion,
     isnull( (select valor from cobis..cl_catalogo b, cobis..cl_tabla a
       where a.tabla = 'cr_clase_linea' and a.codigo = b.tabla
         and b.codigo = cr_tramite.tr_toperacion), 'CREDITO'),
     0.0,            l.li_estado,  (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                   where a.tabla = 'cr_estado_linea' and a.codigo = b.tabla
                                     and b.codigo = l.li_estado),
     0.0,
     l.li_monto*cotizacion,
     'D',
     isnull(tr_plazo, datediff(dd, li_fecha_inicio, li_fecha_vto)/30),
     0 --no existe tr_tplazo
    from cr_linea l,
        cr_tramite,
        cr_cotiz3_tmp b,
        cr_situacion_cliente,
        cr_deudores, cob_cuentas..cc_ctacte
    where l.li_tramite = tr_tramite
    and   tr_toperacion= 'SGC'
    and   l.li_moneda  = b.moneda
    and   tr_tramite   = de_tramite
    and   de_cliente   = sc_cliente
    and   sc_usuario   = @s_user
    and   sc_secuencia = @s_sesn
    and   sc_tramite   = @i_tramite
    and   sc_tipo_con  = 'C'
    and   l.li_estado  <> (case @i_act_can when 'N' then @w_cancelada  else '' end)--@w_cancelada
    and   l.li_num_banco = ''
    --and   l.li_cuenta  = cc_cta_banco
    and   '0'  = cc_cta_banco
    and   li_cliente   = sc_cliente
    and   tr_estado in ('A', 'N')
    and   spid         = @w_spid

    if @@error <> 0
    begin
       /* Error en insercion de registro */
    exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2103001
        rollback
    return 1
    end

    -- LINEAS DE CREDITO Y VISA
    insert into  cr_situacion_lineas
    (sl_cliente,      sl_usuario,     sl_secuencia,       sl_tramite,
     sl_tipo_con,     sl_cliente_con, sl_identico,        sl_producto,
     sl_tramite_d,    sl_sector,      sl_numero_op_banco, sl_linea,
     sl_fecha_apr,    sl_fecha_vct,   sl_limite_credito,  sl_val_utilizado,
     sl_disponible,   sl_disponible_ml,     sl_moneda,    sl_utilizado_ml,
     sl_tipo,         sl_desc_tipo,
     sl_tasa,         sl_estado   ,   sl_desc_estado,
     sl_execeso,
     sl_monto_riesgo,
     sl_tipo_deuda,
     sl_plazo,
     sl_frecuencia,
     sl_rol,
     sl_tipo_rotativo
    )
    select distinct
     tr_cliente,     sc_usuario,     sc_secuencia,     sc_tramite,
     sc_tipo_con,     sc_cliente_con, sc_identico,    isnull( tr_toperacion, 'CRE'),
     l.li_tramite,    tr_sector,      l.li_num_banco, l.li_numero,
     l.li_fecha_inicio,l.li_fecha_vto, om_monto,om_utilizado,
     (isnull( om_monto,0) - isnull( om_utilizado,0)),
     (isnull( om_monto,0)*b.cotizacion - isnull( om_utilizado,0))*b.cotizacion,
     om_moneda,
     isnull(om_utilizado,0)*b.cotizacion,
     om_toperacion,to_descripcion,
     0.0,            l.li_estado,  (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                   where a.tabla = 'cr_estado_linea' and a.codigo = b.tabla
                                     and b.codigo = l.li_estado),

     case sign( li_monto - isnull(li_utilizado,0)  )
      when -1 then abs(li_monto * b2.cotizacion - isnull(li_utilizado,0) * b2.cotizacion /*(select c.cotizacion from cr_cotiz3_tmp c where l.li_moneda = c.moneda and spid = @w_spid)*/)
      else 0.0 end,
     case sign(isnull( li_monto,0) - isnull( li_utilizado,0))
      when -1 then 0
      else abs(isnull( li_monto,0) * b2.cotizacion - isnull( li_utilizado,0) * b2.cotizacion /*(select c.cotizacion from cr_cotiz3_tmp c where l.li_moneda = c.moneda and spid = @w_spid)*/) end,
     'D',
     isnull(tr_plazo, datediff(dd, li_fecha_inicio, li_fecha_vto)/30),
     0,-- no existe tr_plazo -> isnull(tr_tplazo,'M'),
     case sc_rol when 'D' then 'DEUDOR' else 'CODEUDOR' end,
     case li_rotativa when 'S' then 'ROTATIVA'
                             when 'N' then 'NORMAL'
                             else ''
    end
    from cr_linea l,
        cr_tramite, -- JES --> with (index(tr_toperacion_key)) ,
        cr_cotiz3_tmp b,
        cr_cotiz3_tmp b2,
        cr_situacion_cliente,
        cr_deudores, cr_lin_ope_moneda, cr_toperacion
    where l.li_tramite = tr_tramite
    and   tr_toperacion<> 'SGC'
    and   om_moneda    = b.moneda
    and   li_moneda    = b2.moneda
    and   tr_tramite   = de_tramite
    and   de_cliente   = sc_cliente
    and   sc_usuario   = @s_user
    and   sc_secuencia = @s_sesn
    and   sc_tramite   = @i_tramite
    and   sc_tipo_con  = 'C'
    and   l.li_estado  <> (case @i_act_can when 'N' then  @w_cancelada  else '' end)--@w_cancelada
    and   li_cliente   = sc_cliente
    and   tr_estado in ('A', 'N')
    and   om_linea = li_numero
    and   om_toperacion = to_toperacion
    and   (li_tipo is null or li_tipo = @w_tipo_linea)
    and   b2.spid          = @w_spid
    and   b.spid          = @w_spid

    insert into  cr_situacion_lineas
    (sl_cliente,      sl_usuario,     sl_secuencia,       sl_tramite,
     sl_tipo_con,     sl_cliente_con, sl_identico,        sl_producto,
     sl_tramite_d,    sl_sector,      sl_numero_op_banco, sl_linea,
     sl_fecha_apr,    sl_fecha_vct,   sl_limite_credito,  sl_val_utilizado,
     sl_disponible,   sl_disponible_ml,     sl_moneda,    sl_utilizado_ml,
     sl_tipo,         sl_desc_tipo,
     sl_tasa,         sl_estado   ,   sl_desc_estado,
     sl_execeso,
     sl_monto_riesgo,
     sl_tipo_deuda,
     sl_plazo,
     sl_frecuencia
    )
    select distinct
     tr_cliente,     sc_usuario,     sc_secuencia,     sc_tramite,
     sc_tipo_con,     sc_cliente_con, sc_identico,    isnull( tr_toperacion, 'CRE'),
     l.li_tramite,    tr_sector,      l.li_num_banco, l.li_numero,
     l.li_fecha_inicio,l.li_fecha_vto, li_monto,li_utilizado,
     (isnull( li_monto,0) - isnull( li_utilizado,0)),
     (isnull( li_monto,0) - isnull( li_utilizado,0))*cotizacion,
     li_moneda,
     isnull(li_utilizado,0)*cotizacion,
     '','LINEA DE CREDITO',



     0.0,            l.li_estado,  (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                   where a.tabla = 'cr_estado_linea' and a.codigo = b.tabla
                                     and b.codigo = l.li_estado),

     case sign( li_monto - isnull(li_utilizado,0)  )
      when -1 then abs(li_monto - isnull(li_utilizado,0) * cotizacion /*(select c.cotizacion from cr_cotiz3_tmp c where l.li_moneda = c.moneda and spid = @w_spid  )  */)
      else 0.0 end,
     case sign(isnull( li_monto,0) - isnull( li_utilizado,0))
      when -1 then 0
      else abs(isnull( li_monto,0) - isnull( li_utilizado,0) * cotizacion /*(select c.cotizacion from cr_cotiz3_tmp c where l.li_moneda = c.moneda and spid = @w_spid)*/) end,
     'D',
     isnull(tr_plazo, datediff(dd, li_fecha_inicio, li_fecha_vto)/30),
     0 --no existe tr_tplazo
    from cr_linea l,
        cr_tramite, -- JES --> with (index(tr_toperacion_key)) ,
        cr_cotiz3_tmp b,
        cr_situacion_cliente,
        cr_deudores
    where l.li_tramite = tr_tramite
    and   tr_toperacion<> 'SGC'
    and   l.li_moneda  = b.moneda
    and   tr_tramite   = de_tramite
    and   de_cliente   = sc_cliente
    and   sc_usuario   = @s_user
    and   sc_secuencia = @s_sesn
    and   sc_tramite   = @i_tramite
    and   sc_tipo_con  = 'C'
    and   l.li_estado  <> (case @i_act_can when 'N' then @w_cancelada  else '' end)--@w_cancelada
    and   li_cliente   = sc_cliente
    and   tr_estado in ('A', 'N')
    and   li_numero not in (select sl_linea from cr_situacion_lineas where sl_usuario =  @s_user and sl_secuencia = @s_sesn)
    and   (li_tipo is null or li_tipo = @w_tipo_linea)
    and   spid         = @w_spid


    --LINEAS DE GRUPO DE SOBREGIRO
    --1) CLIENTES DEL GRUPO
    insert into  cr_situacion_lineas
    (sl_cliente,      sl_usuario,     sl_secuencia,       sl_tramite,
     sl_tipo_con,     sl_cliente_con, sl_identico,        sl_producto,
     sl_tramite_d,    sl_sector,      sl_numero_op_banco, sl_linea,
     sl_fecha_apr,    sl_fecha_vct,   sl_limite_credito,  sl_val_utilizado,
     sl_disponible,   sl_disponible_ml,     sl_moneda,    sl_utilizado_ml,
     sl_tipo,         sl_desc_tipo,
     sl_tasa,         sl_estado   ,   sl_desc_estado,
     sl_execeso,
     sl_monto_riesgo,
     sl_tipo_deuda,
     sl_plazo,
     sl_frecuencia
    )
    select distinct  isnull(tr_cliente, tr_grupo),     sc_usuario,      sc_secuencia,     sc_tramite,
     sc_tipo_con,    sc_cliente_con,     sc_identico,     isnull( tr_toperacion, 'CRE'),
     l.li_tramite,   tr_sector,    l.li_num_banco,  l.li_numero,
     l.li_fecha_inicio, l.li_fecha_vto,  l.li_monto, (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end),
     (isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end))*cotizacion,
     (isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end))*cotizacion,
     l.li_moneda,
     (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end),
     tr_toperacion,
     isnull( (select b.valor from cobis..cl_catalogo b, cobis..cl_tabla a
       where a.tabla = 'cr_clase_linea' and a.codigo = b.tabla
         and b.codigo = cr_tramite.tr_toperacion), 'CREDITO'),
     0.0,            li_estado,  (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                   where a.tabla = 'cr_estado_linea' and a.codigo = b.tabla
                                     and b.codigo = l.li_estado),
     case sign( li_monto - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end)  )
      when -1 then abs(li_monto - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end)  )
      else 0.0 end,
     case sign(isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end))
      when -1 then 0
      else abs(isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end)) end,
     'D',
     isnull(tr_plazo, datediff(dd, li_fecha_inicio, li_fecha_vto)/30),
     0 --no existe tr_tplazo
    from cr_linea l, cob_cuentas..cc_ctacte,
        cr_tramite, cr_situacion_cliente, cr_deudores,
        cr_cotiz3_tmp b,
        cobis..cl_cliente_grupo
    where li_tramite   = tr_tramite
    and   tr_toperacion= 'SGC'
    and   tr_tramite   = de_tramite
    and   de_cliente   = sc_cliente
    and   sc_usuario   = @s_user
    and   sc_secuencia = @s_sesn
    and   sc_tramite   = @i_tramite
    and   sc_tipo_con  in ( 'G','V')
    and   l.li_moneda  = b.moneda
    and   '0'  = cc_cta_banco --and   l.li_cuenta  = cc_cta_banco
    and   l.li_estado  <> (case @i_act_can when 'N' then @w_cancelada  else '' end)--@w_cancelada
    and   cg_ente = sc_cliente
    and   cg_grupo = @i_grupo
    and   li_cliente = cg_ente
    and   tr_estado in ('A', 'N')
    and   spid         = @w_spid


    --LINEAS DE GRUPO DE SOBREGIRO
    --2) LINEAS SOLO DEL GRUPO
    insert into  cr_situacion_lineas
    (sl_cliente,      sl_usuario,     sl_secuencia,       sl_tramite,
     sl_tipo_con,     sl_cliente_con, sl_identico,        sl_producto,
     sl_tramite_d,    sl_sector,      sl_numero_op_banco, sl_linea,
     sl_fecha_apr,    sl_fecha_vct,   sl_limite_credito,  sl_val_utilizado,
     sl_disponible,   sl_disponible_ml,     sl_moneda,    sl_utilizado_ml,
     sl_tipo,         sl_desc_tipo,
     sl_tasa,         sl_estado   ,   sl_desc_estado,
     sl_execeso,
     sl_monto_riesgo,
     sl_tipo_deuda,
     sl_plazo,
     sl_frecuencia
    )
    select distinct  isnull(tr_grupo, tr_cliente),     sc_usuario,      sc_secuencia,     sc_tramite,
     sc_tipo_con,    sc_cliente_con,     sc_identico,     isnull( tr_toperacion, 'CRE'),
     l.li_tramite,   tr_sector,    l.li_num_banco,  l.li_numero,
     l.li_fecha_inicio, l.li_fecha_vto,  l.li_monto, (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end),
     (isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end))*cotizacion,
     (isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end))*cotizacion,
     l.li_moneda,
     (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end),
     tr_toperacion,
     isnull( (select b.valor from cobis..cl_catalogo b, cobis..cl_tabla a
       where a.tabla = 'cr_clase_linea' and a.codigo = b.tabla
         and b.codigo = cr_tramite.tr_toperacion), 'CREDITO'),
     0.0,            li_estado,  (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                   where a.tabla = 'cr_estado_linea' and a.codigo = b.tabla
                                     and b.codigo = l.li_estado),
     case sign( li_monto - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end)  )
      when -1 then abs(li_monto - (case sign( cc_disponible) when -1 then abs(cc_disponible) else 0 end)  )
      else 0.0 end,
     case sign(isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible* cotizacion) else 0 end))
      when -1 then 0
      else abs(isnull( l.li_monto,0) - (case sign( cc_disponible) when -1 then abs(cc_disponible* cotizacion) else 0 end)) end,
     'D',
     isnull(tr_plazo, datediff(dd, li_fecha_inicio, li_fecha_vto)/30),
     0 --no existe tr_tplazo
    from cr_linea l, cob_cuentas..cc_ctacte,
        cr_tramite, cr_situacion_cliente, cr_deudores,
        cr_cotiz3_tmp b,
        cobis..cl_cliente_grupo
    where li_tramite   = tr_tramite
    and   tr_toperacion= 'SGC'
    and   de_cliente   = sc_cliente
    and   sc_usuario   = @s_user
    and   sc_secuencia = @s_sesn
    and   sc_tramite   = @i_tramite
    and   sc_tipo_con  in ( 'G','V')
    and   l.li_moneda  = b.moneda
    and   '0'  = cc_cta_banco -- and   l.li_cuenta  = cc_cta_banco
    and   l.li_estado  <> (case @i_act_can when 'N' then @w_cancelada  else '' end)--@w_cancelada
    and   cg_ente = sc_cliente
    and   cg_grupo = @i_grupo
    and   li_grupo = cg_grupo
    and   tr_estado in ('A', 'N')
    and   spid     = @w_spid

    --LINEAS DE GRUPO DE VISA Y CREDITO
    -- 1) CLIENTES DEL GRUPO
    insert into  cr_situacion_lineas
    (sl_cliente,      sl_usuario,     sl_secuencia,       sl_tramite,
     sl_tipo_con,     sl_cliente_con, sl_identico,        sl_producto,
     sl_tramite_d,    sl_sector,      sl_numero_op_banco, sl_linea,
     sl_fecha_apr,    sl_fecha_vct,   sl_limite_credito,  sl_val_utilizado,
     sl_disponible,   sl_disponible_ml,     sl_moneda,    sl_utilizado_ml,
     sl_tipo,         sl_desc_tipo,
     sl_tasa,         sl_estado   ,   sl_desc_estado,
     sl_execeso,
     sl_monto_riesgo,
     sl_tipo_deuda,
     sl_plazo,
     sl_frecuencia
    )
    select distinct  isnull(tr_cliente, tr_grupo),     sc_usuario,      sc_secuencia,     sc_tramite,
     sc_tipo_con,    sc_cliente_con,     sc_identico,     isnull( tr_toperacion, 'CRE'),
     l.li_tramite,   tr_sector,    l.li_num_banco,  l.li_numero,
     l.li_fecha_inicio, l.li_fecha_vto,  l.li_monto, l.li_utilizado,
     (isnull( l.li_monto,0) - isnull( l.li_utilizado,0))*cotizacion,
     (isnull( l.li_monto,0) - isnull( l.li_utilizado,0))*cotizacion,
     l.li_moneda,
     isnull( l.li_utilizado,0),
     tr_toperacion,
     isnull( (select b.valor from cobis..cl_catalogo b, cobis..cl_tabla a
       where a.tabla = 'cr_clase_linea' and a.codigo = b.tabla
         and b.codigo = cr_tramite.tr_toperacion), 'CREDITO'),
     0.0,            li_estado,  (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                   where a.tabla = 'cr_estado_linea' and a.codigo = b.tabla
                                     and b.codigo = l.li_estado),
     case sign( li_monto - isnull(li_utilizado,0)  )
      when -1 then abs(li_monto - isnull(li_utilizado,0)  * cotizacion /*(select c.cotizacion from cr_cotiz3_tmp c where l.li_moneda = c.moneda and spid = @w_spid) */)
      else 0.0 end,
     case sign(isnull( l.li_monto,0) - isnull( l.li_utilizado,0))
      when -1 then 0
      else abs(isnull( l.li_monto,0) - isnull( l.li_utilizado,0) * cotizacion /*(select c.cotizacion from cr_cotiz3_tmp c where l.li_moneda = c.moneda and spid = @w_spid)*/) end,
     'D',
     isnull(tr_plazo, datediff(dd, li_fecha_inicio, li_fecha_vto)/30),
     0 --no existe tr_tplazo
    from cr_linea l,
        cr_tramite, cr_situacion_cliente, cr_deudores,
        cr_cotiz3_tmp b,
        cobis..cl_cliente_grupo
    where li_tramite   = tr_tramite
    and   tr_toperacion<> 'SGC'
    and   (tr_tramite   = de_tramite)
    and   de_cliente   = sc_cliente
    and   sc_usuario   = @s_user
    and   sc_secuencia = @s_sesn
    and   sc_tramite   = @i_tramite
    and   sc_tipo_con  in ( 'G','V')
    and   li_moneda    = b.moneda
    and   l.li_estado  <> (case @i_act_can when 'N' then @w_cancelada  else '' end)--@w_cancelada
    and   cg_ente = sc_cliente
    and   cg_grupo = @i_grupo
    and   li_cliente = cg_ente
    and   tr_estado in ('A', 'N')
    and   (li_tipo is null or li_tipo = @w_tipo_linea)
    and   spid       = @w_spid


   --LINEAS DE GRUPO DE VISA Y CREDITO
   -- 2) LINEAS SOLO DEL GRUPO
   insert into  cr_situacion_lineas
    (sl_cliente,      sl_usuario,     sl_secuencia,       sl_tramite,
     sl_tipo_con,     sl_cliente_con, sl_identico,        sl_producto,
     sl_tramite_d,    sl_sector,      sl_numero_op_banco, sl_linea,
     sl_fecha_apr,    sl_fecha_vct,   sl_limite_credito,  sl_val_utilizado,
     sl_disponible,   sl_disponible_ml,     sl_moneda,    sl_utilizado_ml,
     sl_tipo,         sl_desc_tipo,
     sl_tasa,         sl_estado   ,   sl_desc_estado,
     sl_execeso,
     sl_monto_riesgo,
     sl_tipo_deuda,
     sl_plazo,
     sl_frecuencia
    )
     select distinct  isnull(tr_grupo, tr_cliente),     sc_usuario,      sc_secuencia,     sc_tramite,
     sc_tipo_con,    sc_cliente_con,     sc_identico,     isnull( tr_toperacion, 'CRE'),
     l.li_tramite,   tr_sector,    l.li_num_banco,  l.li_numero,
     l.li_fecha_inicio, l.li_fecha_vto,  l.li_monto, l.li_utilizado,
     (isnull( l.li_monto,0) - isnull( l.li_utilizado,0))*cotizacion,
     (isnull( l.li_monto,0) - isnull( l.li_utilizado,0))*cotizacion,
     l.li_moneda,
     isnull( l.li_utilizado,0),
     tr_toperacion,
     isnull( (select b.valor from cobis..cl_catalogo b, cobis..cl_tabla a
       where a.tabla = 'cr_clase_linea' and a.codigo = b.tabla
         and b.codigo = cr_tramite.tr_toperacion), 'CREDITO'),
     0.0,            li_estado,  (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                   where a.tabla = 'cr_estado_linea' and a.codigo = b.tabla
                                     and b.codigo = l.li_estado),
     case sign( li_monto - isnull(li_utilizado,0)  )
      when -1 then abs(li_monto * cotizacion - isnull(li_utilizado,0)  * cotizacion /*(select c.cotizacion from cr_cotiz3_tmp c where l.li_moneda = c.moneda and spid = @w_spid)*/ )
      else 0.0 end,
     case sign(isnull( l.li_monto,0) - isnull( l.li_utilizado,0))
      when -1 then 0
      else abs(isnull( l.li_monto,0) * cotizacion - isnull( l.li_utilizado,0) * cotizacion /*(select c.cotizacion from cr_cotiz3_tmp c where l.li_moneda = c.moneda and spid = @w_spid)*/) end,
     'D',
     isnull(tr_plazo, datediff(dd, li_fecha_inicio, li_fecha_vto)/30),
     0 --no existe tr_tplazo
    from cr_linea l,
        cr_tramite, cr_situacion_cliente, cr_deudores,
        cr_cotiz3_tmp b,
        cobis..cl_cliente_grupo
    where li_tramite   = tr_tramite
    and   tr_toperacion<> 'SGC'
    and   de_cliente   = sc_cliente
    and   sc_usuario   = @s_user
    and   sc_secuencia = @s_sesn
    and   sc_tramite   = @i_tramite
    and   sc_tipo_con  in ( 'G','V')
    and   li_moneda    = b.moneda
    and   l.li_estado  <> (case @i_act_can when 'N' then @w_cancelada  else '' end)--@w_cancelada
    and   cg_ente = sc_cliente
    and   cg_grupo = @i_grupo
    and   li_grupo = cg_grupo
    and   tr_estado in ('A', 'N')
    and   (li_tipo is null or li_tipo = @w_tipo_linea)
    and   spid     = @w_spid

END

/**  LINEAS INDIRECTAS   **/

if @i_tipo_deuda = 'I' or @i_tipo_deuda = 'T'
BEGIN

    /** OBTIENE CODIGO DE GARANTIAS TIPO PERSONAL **/
    select @w_tipo_personal = pa_char
      from cobis..cl_parametro
     where pa_producto = 'GAR'
       and pa_nemonico = 'GARPER'
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

    if @i_act_can = 'S'
      select @w_estado_garantia = '''A'''
   else if @i_act_can = 'N'
         select @w_estado_garantia= '''C'',''A'''

    insert into  cr_situacion_lineas
    (sl_cliente,        sl_usuario,       sl_secuencia,        sl_tramite,
     sl_tipo_con,       sl_cliente_con,   sl_identico,         sl_producto,
     sl_tramite_d,      sl_sector,        sl_numero_op_banco,  sl_linea,
     sl_fecha_apr,      sl_fecha_vct,     sl_limite_credito,   sl_val_utilizado,
     sl_disponible,
     sl_disponible_ml,
     sl_moneda,
     sl_utilizado_ml,
     sl_tipo,
     sl_desc_tipo,
     sl_tasa,           sl_estado   ,     sl_desc_estado,
     sl_execeso,
     sl_monto_riesgo,
     sl_tipo_deuda,
     sl_plazo,
     sl_frecuencia
    )
    select distinct
     tr_cliente,         sc_usuario,       sc_secuencia,     sc_tramite,
     sc_tipo_con,        sc_cliente_con,   sc_identico,      tr_toperacion,
     li_tramite,         tr_sector,        li_num_banco,     li_numero,
     li_fecha_inicio,     li_fecha_vto,     li_monto,         li_utilizado,
     (isnull( li_monto,0) - isnull( li_utilizado,0)),
     (isnull( li_monto,0) - isnull( li_utilizado,0))*cotizacion,
     li_moneda,
     isnull(li_utilizado,0)*cotizacion,
     tr_toperacion,
     isnull( (select valor from cobis..cl_catalogo b, cobis..cl_tabla a
       where a.tabla = 'cr_clase_linea' and a.codigo = b.tabla
         and b.codigo = cr_tramite.tr_toperacion), 'CREDITO'),
     0.0,                li_estado,  (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
                                   where a.tabla = 'cr_estado_linea' and a.codigo = b.tabla
                                     and b.codigo = cr_linea.li_estado),
     case sign( li_monto - isnull(li_utilizado,0)  )
      when -1 then abs(li_monto - isnull(li_utilizado,0)  )
      else 0.0 end,
     case sign(isnull( li_monto,0) - isnull( li_utilizado,0))
      when -1 then 0
      else abs(isnull( li_monto,0)*cotizacion - isnull( li_utilizado,0)*cotizacion) end,
     'I',
     isnull(tr_plazo, datediff(dd, li_fecha_inicio, li_fecha_vto)/30),
     0 --no existe tr_tplazo
    from cr_situacion_cliente, cr_gar_propuesta,
         cob_custodia..cu_custodia,
         cob_custodia..cu_tipo_custodia,
         cr_tramite, -- JES --> with (index(tr_toperacion_key)) ,
         cr_linea,
        cr_cotiz3_tmp b
    where sc_usuario    = @s_user
     and  sc_secuencia  = @s_sesn
     and  sc_tramite    = isnull( @i_tramite, 0)
     and  cu_garante    = sc_cliente
     and  cu_tipo       = tc_tipo
     --and  cu_estado    not in ('C','A')
     and  cu_estado    not in ( select @w_estado_garantia) ---Se incluye condición de Activas y Canceladas
     --and  tc_clase_garantia = @w_tipo_personal TEC
     and  gp_garantia   = cu_codigo_externo
     and  gp_tramite    = tr_tramite
     and  tr_tramite    = li_tramite
     and  tr_tipo in ('L', 'P')
     and  li_moneda     = b.moneda
     and  li_tramite  not in (select distinct sl_tramite_d
                                from cr_situacion_lineas
                               where sl_usuario    = @s_user
                                and  sl_secuencia  = @s_sesn
                                and  sl_tramite    = isnull( @i_tramite, 0))
     and   li_estado    <> (case @i_act_can when 'N' then @w_cancelada  else '' end)--@w_cancelada
     and   tr_estado in ('A', 'N')
     and   spid = @w_spid

    if @@error <> 0
    begin
        /* Error en insercion de registro */
    exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2103001
        rollback
    return 1
    end
END

/** BORRO LINEAS DUPLICADAS  PARA LA VINCULACION**/
if @i_impresion = 'S'
begin
   delete cr_situacion_lineas
    where sl_usuario   = @s_user
      and sl_secuencia = @s_sesn
      and sl_tramite   = isnull(@i_tramite, 0)
      and sl_cliente <> sl_cliente_con
      and sl_tramite_d in (select sl_tramite_d  from cr_situacion_lineas
                            where sl_usuario = @s_user    and sl_secuencia = @s_sesn
                              and sl_tramite = @i_tramite and sl_cliente = sl_cliente_con )
end

delete from cr_cotiz3_tmp where spid = @w_spid --tabla de cotizaciones

return 0

GO
