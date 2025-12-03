/************************************************************************/
/* Archivo            :       sp_plano_cond.sp                          */
/* Stored procedure   :       sp_plano_cond                             */
/* Base de datos      :       cob_cartera                               */
/* Producto           :       Cartera                                   */
/* Disenado por       :       Paulina Galindo                           */
/* Fecha de escritura :       Feb-2010                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/* Este programa es parte de los paquetes bancarios propiedad de MACOSA */
/* Su uso no autorizado queda expresamente prohibido asi como cualquier */
/* alteracion o agregado hecho por alguno de sus usuarios sin el debido */
/* consentimiento por escrito de la Presidencia Ejecutiva de MACOSA     */
/* o su representante.                                                  */
/************************************************************************/
/*                              PROPOSITO                               */
/* Envia informacion para impresion de plano general de condonaciones   */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*  Fecha           Nombre            Proposito                         */
/*  29/07/2013      Oscar Saavedra    ORS541                            */
/*  08/05/2015      Alejandra Cels    NR447                             */
/*  21/09/2017      Tania Baidal      Modificacion estructura           */
/*                                    sb_dato_operacion_rubro           */
/************************************************************************/

use cob_cartera
go

set nocount on
go

if exists (select 1 from sysobjects where name = 'sp_plano_cond')
   drop procedure sp_plano_cond
go

create procedure sp_plano_cond
  @i_param1          varchar(10)

as declare
  @w_vlr_cancelar   money,
  @w_tabla_cat      int,
  @w_servidor       varchar(20),
  @w_path_s_app     varchar(250),
  @w_fecha          datetime,
  @w_path           varchar(250),
  @w_s_app          varchar(250),
  @w_cmd            varchar(250),
  @w_bd             varchar(250),
  @w_tabla          varchar(250),
  @w_fecha_arch     varchar(10),
  @w_error          int,
  @w_comando        varchar(500),
  @w_destino        varchar(250),
  @w_errores        varchar(250),
  @w_erroresc       varchar(250),
  @w_archivoc       varchar(64),
  @w_archivod       varchar(64),
  @w_destinoc       varchar(250),
  @w_archivo        varchar(64),
  @w_msg            varchar(255),
  @anio_listado     varchar(10),
  @mes_listado      varchar(10),
  @dia_listado      varchar(10),
  @w_nombre         varchar(60),
  @i_fecha          datetime,
  @w_fecha_ini      datetime,
  @w_fecha_sb       datetime,
  @w_banco          varchar(20),
  @w_tot_acon       money,
  @w_saldo_cap      money,
  @w_est_vigente    int,
  @w_est_castigado  int,
  @w_est_vencido   int,
  @w_est_suspenso   int,
  @w_est_diferido   int

select @i_fecha = convert(datetime,@i_param1)

select @w_fecha_ini = dateadd(dd,1-datepart(dd,@i_fecha), @i_fecha)

/* ESTADOS DE CARTERA */
exec @w_error = cob_cartera..sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_castigado  = @w_est_castigado out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_suspenso   = @w_est_suspenso  out
  
select @w_tabla_cat = codigo
from   cobis..cl_tabla
where  tabla    = 'cl_cargo'

if exists (select 1 from sysobjects where name = 'cab_condonacion' and xtype = 'U')
    drop table cab_condonacion

if exists (select 1 from sysobjects where name = 'det_condonacion' and xtype = 'U')
    drop table det_condonacion

if exists (select * from sysobjects where name = 'cab_condonacion')
    drop table cab_condonacion

create table cab_condonacion
(obligacion        varchar(30),
 cliente           varchar(30),
 cedula            varchar(30),
 oficina           varchar(30),
 valor_tot_oblig   varchar(30),
 valor_cancelado   varchar(30),
 valor_cap         varchar(30),
 valor_cap_cond    varchar(30),
 valor_int         varchar(30),
 valor_int_cond    varchar(30),
 porce_int         varchar(30),
 valor_mora        varchar(30),
 valor_mora_cond   varchar(30),
 porce_mora        varchar(30),
 otros             varchar(30),
 fecha_cond        varchar(30),
 usuario           varchar(30),
 cargo             varchar(30),
 estado_ant        varchar(30),
 dias_mora_ant     varchar(30),
 dias_mora         varchar(30),
 fecha_contable    varchar(30),   --fecha contable
 anio_castigo      varchar(30),   --anio del castigo
 fecha_fin         varchar(30),   --fecha ultimo vencimiento del credito
 fecha_prox_cuota  varchar(30),   --fecha primera cuota vencida
 valor_cap_con_ven varchar(30),   --valor capital condonado vencido
 porc_cap_con_ven  varchar(30),   --porcentaje capital condonado vencido
 valor_cap_con_vig varchar(30),   --valor capital condonado vigente
 porc_cap_con_vig  varchar(30),   --porcentaje capital condonado vigente
 valor_int_vig     varchar(30),   --valor interes vigente
 valor_int_con_vig varchar(30),   --valor interes condonado vigente
 porc_int_con_vig  varchar(30),   --porcentaje interes condonado vigente
 valor_int_ven     varchar(30),   --valor interes vencido
 valor_int_con_ven varchar(30),   --valor interes condonado vencido
 porc_int_con_ven  varchar(30),   --porcentaje interes condonado vencido
 autoriza_cond     varchar(30),   --Indicar S(si) N(no) el usuario requiere autorizacion para ingreso de condonacion
 autoriza_rol      varchar(30),   --rol que autoriza
 autoriza_usuario  varchar(30),   --usuario que autoriza
 porc_cap_connoven varchar(30),   --porcentaje capital condonado No vencido
 valor_cap_connoven varchar(30),   --valor capital condonado vencido
 porc_cap_ex        varchar(30),   --porcentaje capital condonado por excepcion
 valor_cap_ex       varchar(30),   --valor capital condonado por excepcion
 porc_int_ex        varchar(30),   --porcentaje int condonado por excepcion
 valor_int_ex       varchar(30),   --valor int condonado por excepcion
 porc_imo_ex        varchar(30),   --porcentaje imo condonado por excepcion
 valor_imo_ex       varchar(30)     --valor imo condonado por excepcion
)

select distinct
cn_banco             = op_banco,                                                                                   -- NUMERO OPERACION
cn_nombre            = op_nombre,                                                                                  -- NOMBRE CLIENTE
cn_ced_ruc           = en_ced_ruc,                                                                                 -- CEDULA DE IDENTIDAD
cn_oficina           = (select substring(of_nombre, 1, 15)                                                         
                        from   cobis..cl_oficina                                                                   
                        where  of_oficina = op.op_oficina),                                                        -- OFICINA OPERACION
cn_tot_acon          = 0,                                                                                          -- valor total de la obligacion:  (valor total adeudado por el cliente antes de la condonacion)                                                                                         -- VALOR PAGADO POR EL CLIENTE
cn_valor_cancelado   = convert(money,0),                                                                           -- VALOR PAGADO POR EL CLIENTE
cn_capital           = 0,                                                                                          -- VALOR DE CAPITAL ADEUDADO DE LA OBLIGACION
cn_por_capcon        = convert(money,0),                                                                           -- % Capital condonado:      Porcentaje del valor del capital condonado
cn_int_acon          = 0,                                                                                          -- Valor Intereses corrientes:    (Antes de la condonacion)
cn_val_int_con       = convert(money,0),                                                                           -- Valor Intereses Corrientes condonados:  Valor por int cte condonado
cn_imo_acon          = 0,                                                                                          -- Valor Intereses Mora:    Antes de la condonacion
cn_imo_cond          = sum(case when abd_concepto in ('IMO','IMOSEGDAN','IMOSEGEXE','IMOSEGPRI','IMOSEGVID') then abd_monto_mn       else 0 end ),                      -- Valor intereses mora condonado:   Valor Int Mora condonado
cn_por_imo_cond      = sum(case when abd_concepto in ('IMO','IMOSEGDAN','IMOSEGEXE','IMOSEGPRI','IMOSEGVID') then abd_porcentaje_con else 0 end ),                      -- Porcentaje int mora condonado
cn_otros             = sum(case when abd_concepto not in ('CAP', 'INT', 'IMO','IMOSEGDAN','IMOSEGEXE','IMOSEGPRI','IMOSEGVID') then abd_monto_mn else 0 end),      -- Valor otros rubros como iva, comisiones,Honorarios, seguros, etc (antes de la condonacion)
cn_fecha             = convert(varchar(10), ab_fecha_pag, 103),                                                    -- FECHA EN LA CUAL SE INGRESO LA CONDONACION
cn_usuario           = ab_usuario,                                                                                 -- USUARIO QUE INGRESO LA CONDONACION -LOGIN
cn_cargo             = '                                                 ',                                        -- CARGO DEL USUARIO QUE INGRESO LA CONDONACION.
cn_estado_ant        = '                      ',                                                                   -- ESTADO DE LA OBLIGACION ANTES DE LA CONDONACION
cn_estado            = es_descripcion,                                                                             -- ESTADO DE LA OBLIGACION DESPUES DE LA CONDONACION: ESTADO EN QUE QUEDA LA OBLIGACION (PUEDE SER CANCELADO O VIGENTE).
cn_dmora_acond       = 0,                                                                                          -- Dias de mora Antes de la condonacion (justo antes del momento de la Condonacion)
cn_dmora_dcond       = 0,                                                                                          -- Dias Mora despues de la Condonacion:   Dias mora despues de la condonacion
cn_fecha_contable    = convert(varchar(12),''),                                                                    -- fecha contable
cn_anio_castigo      = convert(varchar(4),''),                                                                     -- anio del castigo
cn_fecha_fin         = convert(varchar(12),''),                                                                    -- fecha ultimo vencimiento del credito
cn_fecha_prox_cuota  = convert(varchar(12),''),                                                                    -- fecha primera cuota vencida
cn_valor_cap_con_ven = convert(money,0),
cn_porc_cap_con_ven  = convert(float,0),
cn_valor_cap_con_vig = convert(money,0),
cn_porc_cap_con_vig  = convert(float,0),
cn_valor_int_vig     = convert(money,0),                                                                           
cn_valor_int_con_vig = convert(money,0),
cn_porc_int_con_vig  = convert(float,0),
cn_valor_int_ven     = convert(money,0),                                                                           
cn_valor_int_con_ven = convert(money,0),
cn_porc_int_con_ven  = convert(float,0),
cn_autoriza_cond     = convert(tinyint,0),
cn_autoriza_rol      = convert(tinyint,0),
cn_autoriza_usuario  = convert(varchar(24),''),
cn_secuencial        = ab_secuencial_pag,                                                                          -- SECUENCIAL PAGO
cn_operacion         = ab_operacion,
cn_sec               = isnull(ab_secuencial_ing,0),
cn_autoriza          = convert(varchar(1),'N'),
cn_sec_rpa           = isnull(ab_secuencial_rpa,0),
cn_ult_fecha_con     = max(ab_fecha_pag),                                                                          -- Ultima Condonacion Realizada
cn_op_estado         = op.op_estado_cobranza,
cn_porc_cap_connoven  = convert(float,0),
cn_valor_cap_connoven = convert(money,0),
cn_porc_cap_ex        = convert(float,0),
cn_valor_cap_ex       = convert(money,0),
cn_porc_int_ex        = convert(float,0),
cn_valor_int_ex       = convert(money,0),
cn_porc_imo_ex        = convert(float,0),
cn_valor_imo_ex       = convert(money,0)

into #det_condonacion
from   cob_cartera..ca_abono ab with (nolock), cob_cartera..ca_abono_det abd with (nolock), cob_cartera..ca_operacion op with (nolock) , 
       cobis..cl_ente with (nolock), cob_cartera..ca_estado with (nolock)
where  ab_operacion      = abd_operacion
and    ab_secuencial_ing = abd_secuencial_ing
and    ab_estado         = 'A'
and    abd_tipo          = 'CON'
and    ab_fecha_pag      between @w_fecha_ini and @i_fecha
and    ab_operacion      = op_operacion
--and    ab_operacion      = 6712533 --5211069
and    op_cliente        = en_ente
and    op_estado         = es_codigo
group by ab_fecha_pag,       ab_usuario,        ab_secuencial_pag, 
         ab_operacion,       op_banco,          op_nombre,         
         en_ced_ruc,         es_descripcion,    op_oficina, 
         ab_secuencial_ing,  ab_secuencial_rpa, op_estado_cobranza
         
select @w_fecha_sb = max(do_fecha)
from cob_conta_super..sb_dato_operacion with (nolock)

select do_banco, do_fecha_castigo, do_fecha_vencimiento, do_fecha_prox_vto
into #sb_dato
from cob_conta_super..sb_dato_operacion with (nolock)
where do_fecha = @w_fecha_sb

select fecha_mov = tr_fecha_cont, tr_operacion
into  #sb_dato_trn
from  cob_cartera..ca_transaccion, #det_condonacion
where tr_operacion  = cn_operacion
and   tr_secuencial = cn_secuencial
and   tr_secuencial >= 0
order by tr_secuencial

create index idx1 on #sb_dato (do_banco)
create index idx1 on #sb_dato_trn (tr_operacion)
create index idx1 on #det_condonacion (cn_banco)
create index idx2 on #det_condonacion (cn_operacion, cn_secuencial)

update #det_condonacion set
cn_fecha_fin        = convert(varchar(12), do_fecha_vencimiento,103),
cn_anio_castigo     = convert(varchar(4), datepart(yy,do_fecha_castigo)),
cn_fecha_prox_cuota = convert(varchar(12), do_fecha_prox_vto,103)
from #sb_dato
where cn_banco = do_banco

update #det_condonacion set
cn_fecha_contable  = convert(varchar(12), fecha_mov, 103)
from #sb_dato_trn
where cn_operacion = tr_operacion

update #det_condonacion set
cn_autoriza_cond    = co_autoriza              
from cob_cartera..ca_condonacion with (nolock)
where cn_operacion  = co_operacion
and   cn_sec        = co_secuencial

update #det_condonacion set
cn_autoriza = case when ((cn_autoriza_cond is null) or (cn_autoriza_cond = 0)) then 'N' else 'S' end

update #det_condonacion set
cn_autoriza_usuario = case when cn_autoriza = 'S' then cos_usuario_ts else ' ' end,
cn_autoriza_rol     = case when cn_autoriza = 'S' then cos_autoriza else 0 end
from cob_cartera..ca_condonacion_ts
where  cn_operacion     = cos_operacion
and    cn_sec           = cos_secuencial
and    cn_autoriza_cond = cos_autoriza
and    cos_operacion_ts = 'A'

--VALOR_CAP_CON_VEN - Valor del capital condonado vencido
--PORC_CAP_CON_VEN - Porcentaje que se condono del capital vencido
update #det_condonacion set
cn_valor_cap_con_ven = co_valor,
cn_porc_cap_con_ven  = round(co_porcentaje, 2)
from cob_cartera..ca_condonacion with (nolock)
where  cn_operacion  = co_operacion
and    cn_sec        = co_secuencial
and    co_concepto   = 'CAP'
and    co_estado_concepto = 2
and    co_excepcion = 'N'

--VALOR_IMO_COND - Valor del imo
--PORC_IMO_COND - Porcentaje IMO
update #det_condonacion set
cn_imo_cond = co_valor,
cn_por_imo_cond  = round(co_porcentaje, 2)
from cob_cartera..ca_condonacion with (nolock)
where  cn_operacion  = co_operacion
and    cn_sec        = co_secuencial
and    co_concepto   = 'IMO'
and    co_estado_concepto = 2
and    co_excepcion = 'N'


update  #det_condonacion
set cn_imo_cond = 0,
cn_por_imo_cond  = 0
from #det_condonacion a,  cob_cartera..ca_condonacion
where cn_operacion = co_operacion
and    co_concepto   = 'IMO'
and    co_estado_concepto = 2
and    co_excepcion = 'N'
and cn_sec not in (select co_secuencial from cob_cartera..ca_condonacion
                   where    co_operacion = a.cn_operacion
			and  co_concepto   = 'IMO'
			and  co_estado_concepto = 2
			and  co_excepcion = 'N' )


--acelis Req 447
--VALOR_CAP_CONNOVEN - Valor del capital condonado no vencido
--PORC_CAP_CONNOVEN - Porcentaje que se condono del capital no vencido

update #det_condonacion set
cn_valor_cap_connoven = co_valor,
cn_porc_cap_connoven  = round(co_porcentaje, 2)
from cob_cartera..ca_condonacion with (nolock)
where  cn_operacion  = co_operacion
and    co_concepto   = 'CAP'
and    cn_sec        = co_secuencial  
and    co_estado_concepto = 0
and    co_excepcion = 'N'

--VALOR_CAP_POR EXCEPCION
--PORC_CAP POR EXCEPCION aca
select valor       = round(sum(co_valor),2),
       porcentaje  = round(sum(co_porcentaje), 2),
       operacion   = co_operacion,
       concepto    = 'CAP'
into   #excepcion      
from   cob_cartera..ca_condonacion with (nolock), #det_condonacion
where  co_concepto   = 'CAP'
and    co_estado_concepto in (0,1,2)
and    co_excepcion = 'S'
and    cn_operacion  = co_operacion
and    cn_sec        = co_secuencial  
group by co_operacion 


update #det_condonacion set
cn_valor_cap_ex = valor,
cn_porc_cap_ex  = porcentaje
from #excepcion
where  cn_operacion  = operacion
and    concepto = 'CAP'

--VALOR_INT_POR EXCEPCION
--PORC_INT POR EXCEPCION
insert into   #excepcion 
select valor       = round(sum(co_valor),2),
       porcentaje  = round(sum(co_porcentaje), 2),
       operacion   = co_operacion,
       concepto    = 'INT'
from   cob_cartera..ca_condonacion with (nolock), #det_condonacion
where  co_concepto   = 'INT'
and    co_estado_concepto in (0,1,2)
and    co_excepcion = 'S'
and    cn_operacion  = co_operacion
and    cn_sec        = co_secuencial  
group by co_operacion 
if @@error <> 0  begin
   select @w_msg = 'ERROR INSERTA TMP EXCEPCIONES POR INT'
   goto ERROR
end

update #det_condonacion set
cn_valor_int_ex = valor,
cn_porc_int_ex  = porcentaje
from #excepcion
where  cn_operacion  = operacion
and    concepto = 'INT'

if @@error <> 0  begin
   select @w_msg = 'ERROR ACTUALIZA TMP EXCEPCIONES POR INT'
   goto ERROR
end

--VALOR_IMO_POR EXCEPCION
--PORC_ IMO POR EXCEPCION
insert into   #excepcion 
select valor       = round(sum(co_valor ),2),
       porcentaje  = round(sum(co_porcentaje), 2),
       operacion   = co_operacion,
       concepto    = 'IMO'
from   cob_cartera..ca_condonacion with (nolock), #det_condonacion
where  co_concepto in (select co_concepto from cob_cartera..ca_concepto where co_categoria = 'M')
and    co_estado_concepto in (0,1,2)
and    co_excepcion = 'S'
and    cn_operacion  = co_operacion
and    cn_sec        = co_secuencial  
group by co_operacion 
if @@error <> 0  begin
   select @w_msg = 'ERROR INSERTA TMP EXCEPCIONES POR IMO'
   goto ERROR
end


update #det_condonacion set
cn_valor_imo_ex = valor,
cn_porc_imo_ex  = porcentaje
from #excepcion
where  cn_operacion  = operacion
and    concepto in (select co_concepto from cob_cartera..ca_concepto where co_categoria = 'M')
if @@error <> 0  begin
   select @w_msg = 'ERROR ACTUALIZA TMP EXCEPCIONES POR IMO'
   goto ERROR
end



--VALOR_CAP_CON_VIG - Valor del capital condonado vigente
--PORC_CAP_CON_VIG - Porcentaje que se condono del capital vigente
update #det_condonacion set
cn_valor_cap_con_vig = co_valor,
cn_porc_cap_con_vig  = round(co_porcentaje, 2)
from cob_cartera..ca_condonacion with (nolock)
where  cn_operacion  = co_operacion
and    co_concepto   = 'CAP'
and    cn_sec        = co_secuencial
and    co_estado_concepto = 1
and    co_excepcion = 'N'

--VALOR_INT_CON_VIG - Valor del interes vigente condonado
--PORC_INT_CON_VIG - Porcentaje del interes vigente condonado
--VALOR_INT_VIG - Valor del interes vigente antes de la condonación
update #det_condonacion set
cn_valor_int_con_vig = co_valor,
cn_porc_int_con_vig  = round(co_porcentaje, 2),
cn_valor_int_vig     = round(((co_valor * 100) / round(co_porcentaje, 2)),0)
from cob_cartera..ca_condonacion with (nolock)
where  co_operacion  = cn_operacion
and    co_concepto   = 'INT'
and    cn_sec        = co_secuencial  
and    co_estado_concepto = 1
and    co_excepcion = 'N'


--VALOR_INT_CON_VEN - Valor del interes vencido condonado
--%_COND_INT - Porcentaje de interés  vencido Condonado
--VALOR_INT_VEN - Valor del interes vencido antes de la condonación
update #det_condonacion set
cn_valor_int_con_ven = co_valor,
cn_porc_int_con_ven  = round(co_porcentaje, 2),
cn_valor_int_ven     = round(((co_valor * 100) / round(co_porcentaje, 2)),0)
from cob_cartera..ca_condonacion with (nolock)
where  cn_operacion  = co_operacion
and    co_concepto   = 'INT'
and    cn_sec        = co_secuencial  
and    co_estado_concepto = 2
and    co_excepcion = 'N'

--VALOR_CAPITAL_COND - Valor Total de la condonación de Capital.  Corresponde a la suma del capital condonado Vencido y Vigente 
select va_cap = (sum(cn_valor_cap_con_vig) + sum(cn_valor_cap_con_ven) + sum(cn_valor_cap_connoven)),
       va_op  = cn_operacion,
       va_cta = cn_banco--,       va_sec = cn_sec
into #ValoresCond
from #det_condonacion
group by cn_operacion, cn_banco--, cn_sec


update #det_condonacion 
set    cn_por_capcon  = va_cap       
from   #ValoresCond
where  cn_operacion   = va_op
--and    cn_sec         = va_sec

-- CONSULTA Y ACTUALIZA CARGO
update #det_condonacion
set   cn_cargo = isnull(valor, 'NO EXISTE DESCRIPCION')
from  cobis..cl_catalogo, cobis..cl_funcionario
where tabla    = @w_tabla_cat
and   codigo   = fu_cargo
and   fu_login = cn_usuario

-- CALCULA VALOR PAGADO POR EL CLIENTE
update #det_condonacion
set    cn_valor_cancelado = isnull(abd_monto_mn,0)
from   ca_abono, ca_abono_det
where  ab_operacion       = abd_operacion
and    ab_operacion       = cn_operacion
and    ab_secuencial_ing  = abd_secuencial_ing
and    ab_secuencial_pag  > cn_secuencial
and    ab_fecha_pag      between @w_fecha_ini and @i_fecha
and    abd_tipo           = 'PAG'

-- ESTADO ANTES DE LA CONDONACION
update #det_condonacion
set    cn_estado_ant = es_descripcion
from   cob_cartera..ca_operacion_his, cob_cartera..ca_estado
where  oph_operacion  = cn_operacion
and    oph_secuencial = cn_secuencial
and    oph_estado     = es_codigo

--- VALORES POR RUBRO ANTES DE LA CONDONACION
update #det_condonacion
set    cn_imo_acon = con_deuda_IMO,
       cn_otros    = con_deuda_otros
from   cob_cartera..ca_datos_condonaciones, #det_condonacion
where  con_operacion  = cn_operacion
and    con_secuencial_pag = cn_secuencial

--Calcula fecha Antes de la ultima Condonacion
select ac_fecha_ant = max(dr_fecha), ac_banco = cn_banco
into   #ant_ult_cond
from   cob_conta_super..sb_dato_operacion_rubro, #det_condonacion
where  dr_banco    = cn_banco
and    dr_fecha    < cn_ult_fecha_con
group by cn_banco

update #det_condonacion
set    cn_ult_fecha_con = ac_fecha_ant
from   #ant_ult_cond
where  cn_banco    = ac_banco

--VALOR_CAPITAL - Valor del capital antes de la condonación
update #det_condonacion
set    cn_capital  = dr_valor
from   cob_conta_super..sb_dato_operacion_rubro 
where  dr_banco    = cn_banco
and    dr_fecha    = cn_ult_fecha_con
and    dr_concepto = 'CAP'
and    dr_estado in (@w_est_vigente,@w_est_vencido,@w_est_suspenso,@w_est_castigado)

--VALOR_INTERES - Valor del interés antes de la condonación
update #det_condonacion
set    cn_int_acon  = dr_valor
from   cob_conta_super..sb_dato_operacion_rubro 
where  dr_banco    = cn_banco
and    dr_fecha    = cn_ult_fecha_con
and    dr_concepto = 'INT'
and    dr_estado in (@w_est_vigente,@w_est_vencido,@w_est_suspenso,@w_est_castigado)

--Sumatoria Valores en Suspenso y Vigentes
select va_valor      = sum(dr_valor),
       va_cuenta     = dr_banco, 
       va_fecha      = dr_fecha, 
       va_secuencial = cn_secuencial
into   #ValoresObligacion
from   cob_conta_super..sb_dato_operacion_rubro, #det_condonacion 
where  dr_banco    = cn_banco
and    dr_fecha    = cn_ult_fecha_con
and    dr_estado   in (@w_est_vigente,@w_est_vencido,@w_est_suspenso,@w_est_castigado)
group by dr_banco, dr_fecha, cn_secuencial

--VALOR_TOTAL_OBLIGACION - Valor total de la oblgación antes de la condonación
update #det_condonacion
set    cn_tot_acon = va_valor
from   #ValoresObligacion 
where  va_cuenta    = cn_banco
and    va_secuencial = cn_secuencial

select
ha_banco     = cn_banco,
ha_tot_acon  = cn_tot_acon
into #Honorarios_Abogado
from #det_condonacion

--Calcula Honorarios de Abogados
while 1=1 begin 

   select top 1
   @w_banco    = ha_banco,
   @w_tot_acon = ha_tot_acon
   from #Honorarios_Abogado
   
   if @@rowcount = 0
      break
      
   exec sp_saldo_honorarios
   @i_banco          = @w_banco,
   @i_saldo_cap      = @w_tot_acon,
   @o_saldo_tot      = @w_saldo_cap out
   
   update #det_condonacion
   set    cn_tot_acon = @w_saldo_cap
   where  cn_banco    = @w_banco
   
   delete #Honorarios_Abogado
   where  ha_banco = @w_banco

end

drop table #Honorarios_Abogado


-- DIAS DE MORA ANTES DE LA CONDONACION (JUSTO ANTES DEL MOMENTO DE LA CONDONACION)
select cn_operacion  as operacion_ant, 
       cn_secuencial as secuencial_ant, 
       datediff(dd,min(con_fecha_div_mas_vencido), con_fecha_pag) as dias_mora_ant into #op_dias_mora_ant
from   cob_cartera..ca_datos_condonaciones, #det_condonacion
where  con_operacion  = cn_operacion
and    con_secuencial_pag = cn_secuencial
group by cn_operacion, cn_secuencial,con_fecha_div_mas_vencido,con_fecha_pag

-- DIAS DE MORA DESPUES DE LA CONDONACION 
select cn_operacion  as operacion_des, 
       cn_secuencial as secuencial_des, 
       datediff(dd,min(di_fecha_ven), @i_fecha) as dias_mora_des into #op_dias_mora_des
from   cob_cartera..ca_dividendo, #det_condonacion
where  di_operacion  = cn_operacion
and    di_estado     = 2
group by cn_operacion, cn_secuencial,di_fecha_ven

-- DIAS DE MORA ANTES DE LA CONDONACION
update #det_condonacion
set    cn_dmora_acond = isnull(dias_mora_ant,0)
from   #op_dias_mora_ant
where  cn_operacion  = operacion_ant
and    cn_secuencial = secuencial_ant

-- DIAS DE MORA DESPUES DE LA CONDONACION
update #det_condonacion
set    cn_dmora_dcond = case when dias_mora_des > 0 then dias_mora_des else 0 end
from   #op_dias_mora_des
where  cn_operacion  = operacion_des
and    cn_secuencial = secuencial_des


select va_int = (sum(cn_valor_int_con_vig) + sum(cn_valor_int_con_ven) ),
       va_op  = cn_operacion,
       va_cta = cn_banco--,       va_sec = cn_sec
into #ValoresCondInt
from #det_condonacion
group by cn_operacion, cn_banco--, cn_sec


update #det_condonacion 
set    cn_val_int_con  = va_int
from   #ValoresCondInt
where  cn_operacion   = va_op
--and    cn_sec         = va_sec


-- CONSULTA Y ACTUALIZA CARGO
select *
into #det_condonacion_def
from #det_condonacion
where 1=2

insert into #det_condonacion_def (
cn_banco,                  cn_nombre,                 cn_ced_ruc,
cn_oficina,                cn_tot_acon,               cn_valor_cancelado,
cn_capital,                cn_por_capcon,             cn_int_acon,
cn_val_int_con,            cn_imo_acon,               cn_imo_cond,
cn_por_imo_cond,           cn_otros,                  cn_fecha,
cn_usuario,                cn_cargo,                  cn_estado_ant,
cn_estado,                 cn_dmora_acond,            cn_dmora_dcond,
cn_fecha_contable,         cn_anio_castigo,           cn_fecha_fin,
cn_fecha_prox_cuota,       cn_valor_cap_con_ven,      cn_porc_cap_con_ven,
cn_valor_cap_con_vig,      cn_porc_cap_con_vig,       cn_valor_int_vig,
cn_valor_int_con_vig,      cn_porc_int_con_vig,       cn_valor_int_ven,
cn_valor_int_con_ven,      cn_porc_int_con_ven,       cn_autoriza,
cn_autoriza_rol,           cn_autoriza_usuario,       cn_secuencial,
cn_operacion,              cn_sec,                    cn_sec_rpa,
cn_porc_cap_connoven,      cn_valor_cap_connoven,     cn_porc_cap_ex,
cn_valor_cap_ex,           cn_porc_int_ex,            cn_valor_int_ex,
cn_porc_imo_ex,            cn_valor_imo_ex
)

select 
max(cn_banco),             max(cn_nombre),            max(cn_ced_ruc),
max(cn_oficina),           max(cn_tot_acon),          max(cn_valor_cancelado),
max(cn_capital),           max(cn_por_capcon),        max(cn_int_acon),          
max(cn_val_int_con),       max(cn_imo_acon),          sum(cn_imo_cond), 
sum(cn_por_imo_cond),      sum(cn_otros),             max(cn_fecha),
max(cn_usuario),           max(cn_cargo),             max(cn_estado_ant),
max(cn_estado),            max(cn_dmora_acond),       max(cn_dmora_dcond),
max(cn_fecha_contable),    max(cn_anio_castigo),      max(cn_fecha_fin),
max(cn_fecha_prox_cuota),  sum(cn_valor_cap_con_ven), sum(cn_porc_cap_con_ven), 
sum(cn_valor_cap_con_vig), sum(cn_porc_cap_con_vig),  max(cn_valor_int_vig),
sum(cn_valor_int_con_vig), sum(cn_porc_int_con_vig),  sum(cn_valor_int_ven),
sum(cn_valor_int_con_ven), sum(cn_porc_int_con_ven),  max(cn_autoriza),
max(cn_autoriza_rol),      max(cn_autoriza_usuario),  max(cn_secuencial),        
max(cn_operacion),         max(cn_sec),               max(cn_sec_rpa),
sum(cn_porc_cap_connoven), sum(cn_valor_cap_connoven),max(cn_porc_cap_ex), 
max(cn_valor_cap_ex),      max (cn_porc_int_ex),      max(cn_valor_int_ex),    
max(cn_porc_imo_ex),       max(cn_valor_imo_ex) 
from #det_condonacion
group by cn_banco

-- CABECERA
insert into cab_condonacion 
values (
'FECHA_CONDONACION',        'FECHA_CONTABLE',          'OBLIGACION',        
'CLIENTE',                  'CEDULA',                  'ANO_CASTIGO',            
'FECHA_FIN',                'FECHA_PROX_CUOTA',        'OFICINA',           
'VALOR_TOTAL_OBLIGACION',   'VALOR_CANCELADO',         'VALOR_CAPITAL_TOTAL',     
'VALOR_CAPITAL_TOTAL_COND', 'VALOR_CAP_COND_VEN',      '%_CAP_COND_VEN',
'VALOR_CAP_COND_VIG',       '%_CAP_COND_VIG',          'VALOR CAP_COND_X_VEN',
'%_CAP_COND_X_VEN',         'VALOR_CAP_COND_EXCEP',    '%_CAP_COND_EXCEP',
'VALOR_INT_TOTAL',          'VALOR_INT_TOTAL_COND',    'VALOR_INT_COND_VEN',   
'%_INT_COND_VEN',           'VALOR_INT_COND_VIG',      '%_INT_COND_VIG',
'VALOR_INT_COND_EXCEP',     '%_INT_COND_EXCEP',        'VALOR_IMO_TOTAL',            
'VALOR_IMO_TOTAL_COND',     '%_IMO_TOTAL_COND',        'VALOR_IMO_COND_EXCEP',
'%_IMO_COND_EXCEP',         'OTROS',                   'USUARIO',
'CARGO',                    'ESTADO_ANTES',            'ESTADO_ACTUAL',
'DIAS_MORA_ANT',            'DIAS_MORA_ACT',           'AUTORIZA_COND',
'AUTORIZA_ROL',             'AUTORIZA_USUARIO',        '',
''
)  

select 
cn_fecha,                   cn_fecha_contable,         cn_banco,               
cn_nombre,                  cn_ced_ruc,                cn_anio_castigo,          
cn_fecha_fin,               cn_fecha_prox_cuota,       cn_oficina,             
cn_tot_acon,                cn_valor_cancelado,        cn_capital,             
cn_por_capcon,              cn_valor_cap_con_ven,      cn_porc_cap_con_ven,
cn_valor_cap_con_vig,       cn_porc_cap_con_vig,       cn_valor_cap_connoven,
cn_porc_cap_connoven,       cn_valor_cap_ex,           cn_porc_cap_ex,
cn_int_acon,                cn_val_int_con,            cn_valor_int_con_ven,
cn_porc_int_con_ven,        cn_valor_int_con_vig,      cn_porc_int_con_vig,
cn_valor_int_ex,            cn_porc_int_ex,            cn_imo_acon,
cn_imo_cond,                cn_por_imo_cond,           cn_valor_imo_ex,
cn_porc_imo_ex,             cn_otros,                  cn_usuario,
cn_cargo,                   cn_estado_ant,             cn_estado,
cn_dmora_acond,             cn_dmora_dcond,            cn_autoriza,
cn_autoriza_rol,            cn_autoriza_usuario       
into det_condonacion
from #det_condonacion_def

-----------------
/* HAGO EL BCP */
-----------------
select @w_path_s_app = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'S_APP'

if @w_path_s_app is null begin
   select @w_msg = 'NO EXISTE PARAMETRO GENERAL S_APP'
   goto ERROR
end

select
@w_s_app      = @w_path_s_app+'s_app'

select
@w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = 7946
                          
/* TABLA DEL REPORTE */
select
@w_cmd      = @w_s_app+' bcp -auto -login ',
@w_bd       = 'cob_cartera',
@w_tabla    = 'cab_condonacion',
@w_archivoc  = 'cab_condonacion'

select 
@w_destinoc  = @w_path + @w_archivoc +'.txt',
@w_erroresc  = @w_path + @w_archivoc +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destinoc + ' -b5000 -c -e'+@w_erroresc + ' -t"|" ' + '-config '+@w_s_app+'.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO CABECERA '+@w_destinoc+ ' '+ convert(varchar, @w_error)
   goto ERROR
end

/* -- DATOS  */
/* TABLA DEL REPORTE */
select
@w_cmd      = @w_s_app+' bcp -auto -login ',
@w_bd       = 'cob_cartera',
@w_tabla    = 'det_condonacion',
@w_archivod = 'det_condonacion'

select 
@w_destino  = @w_path + @w_archivod +'.txt',
@w_errores  = @w_path + @w_archivod +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destino + ' -b5000 -c -e'+@w_errores + ' -t"|" ' + '-config '+@w_s_app+'.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO '+@w_destino+ ' '+ convert(varchar, @w_error)
   goto ERROR
end

select @w_fecha_arch = convert(varchar, @i_fecha, 112),
       @anio_listado = substring(@w_fecha_arch,1,4),
       @mes_listado  = substring(@w_fecha_arch,5,2), 
       @dia_listado  = substring(@w_fecha_arch,7,2)

select @w_fecha_arch = @mes_listado + @dia_listado + @anio_listado 

/*** CONCATENACION DE ARCHIVO CABECERA CON ARCHIVO DE DATOS  ***/
select @w_nombre = 'ca_planocon' + @w_fecha_arch

select
@w_archivo  = @w_path + @w_nombre +'.txt',
@w_comando = 'type ' + @w_destinoc + ' ' + @w_destino + ' > ' + @w_archivo

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end

/*** ELIMINACION DE ARCHIVO DE CABECERA Y DATOS  ***/

select
@w_comando = 'rm ' + @w_destinoc 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end

select
@w_comando = 'rm ' + @w_erroresc 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end

select
@w_comando = 'rm ' + @w_destino 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end

select
@w_comando = 'rm ' + @w_errores 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end


return 0
ERROR:
   print @w_msg 
   exec @w_error = sp_errorlog
        @i_fecha      = @i_fecha,
        @i_error      = 1900000,
        @i_usuario    = 'sa',
        @i_tran       = 7946,
        @i_tran_name  = @w_msg,
        @i_rollback   = 'N'

return 1900000

go

