/********************************************************************/
/*   NOMBRE LOGICO:      sp_reporte_datos_grp                       */
/*   NOMBRE FISICO:      repdatosgrp.sp                             */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       William Lopez                              */
/*   FECHA DE ESCRITURA: 23-Feb-2023                                */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Sp de consulta de datos para generacion de reportes operaciones*/
/*   grupales hijas                                                 */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA           AUTOR    RAZON                                 */
/*   23-Feb-2023     WLO      Emision Inicial                       */
/*   30-Mar-2023     WLO      S802866 Agrega Símbolo moneda         */
/*                            y ciclo del grupo                     */
/*   08-Dic/2023     KDR      R221182 Corecc. Cap ven. condonaciones*/
/*   04-Sep-2024     KDR      R242440 Cambio valor tasa imo estCuent*/
/*   11-Nov-2024     KDR      R251092 Ajuste consulta pagos FP VAC  */
/********************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reporte_datos_grp')
   drop proc sp_reporte_datos_grp
go

create proc sp_reporte_datos_grp
   @s_ssn           int           = null,
   @s_sesn          int           = null,
   @s_ofi           smallint      = null,
   @s_rol           smallint      = null,
   @s_user          login         = null,
   @s_date          datetime      = null,
   @s_term          descripcion   = null,
   @t_debug         char(1)       = 'N',
   @t_file          varchar(10)   = null,
   @t_from          varchar(32)   = null,
   @s_srv           varchar(30)   = null,
   @s_lsrv          varchar(30)   = null,
   @t_trn           int           = null,
   @s_format_date   int           = null,
   @s_ssn_branch    int           = null,
   @s_culture       varchar(10)   = 'NEUTRAL',
   @i_cod_reporte   smallint      = null,
   @i_nemonico      varchar(10)   = null,
   @i_canal         catalogo      = 1   , -- 1: Cartera, 2: Batch, 3: Web service, 4: ATX
   @i_banco         varchar(30),          -- Numero de operacion
   @i_operacion     char(1)               -- A: Datos para reporte de estado cuenta grupal

as 
declare
   @w_sp_name                varchar(65),
   @w_return                 int,
   @w_retorno_ej             int,
   @w_error                  int,
   @w_mensaje                varchar(1000),
   @w_mensaje_err            varchar(255),
   @w_contador               int,
   @w_contador2              int,
   @w_err_cursor             char(1),
   @w_cod_prod_cca           int,
   @w_fecha_proc             varchar(15),
   @w_fecha_cierre           datetime,
   @w_fecha_sig_pgo          varchar(15),
   @w_est_vigente            smallint,
   @w_est_novigente          smallint,
   @w_est_cancelado          smallint,
   @w_est_credito            smallint,
   @w_est_anulado            smallint,
   @w_est_castigado          smallint,
   @w_est_vencido            smallint,
   @w_tipo_operacion         char(1),
   @w_op_operacion           int,
   @w_op_tramite             int,
   @w_op_cliente             int,
   @w_canal                  catalogo, -- 1: Cartera, 2: Batch, 3: Web service, 4: ATX
   @w_tasa_nominal           decimal(18,2),
   @w_tasa_efec              decimal(18,2),
   @w_tasa_moratoria         decimal(18,2),
   @w_param_sob_aut          varchar(30),
   @w_valcap_capgrp          money,
   @w_valcap_vengrp          money,
   @w_valcap_resolgrp        money,
   @w_conceptogrp            varchar(30),
   @w_sec                    int,
   @w_fechamovimientogrp     datetime,
   @w_formagrp               varchar(30),
   @w_saldo_acum             money,
   @w_fila                   int,
   @w_valcap_viggrp          money,
   @w_dif_imo_int            decimal(18,2)

select @w_sp_name       = 'sp_pago_grupal_consulta_montos',
       @w_error         = 0,
       @w_return        = 0,
       @w_retorno_ej    = 0,
       @w_mensaje       = '',
       @w_contador      = 1,
       @w_contador2     = 0,
       @w_err_cursor    = 'N',
       @w_mensaje_err   = null,
       @w_canal         = @i_canal,
       @w_valcap_viggrp = 0

-- CULTURA
exec cobis..sp_ad_establece_cultura
   @o_culture = @s_culture out

-- Código de producto CCA
select @w_cod_prod_cca = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'

--parametro
select @w_param_sob_aut = isnull(pa_char,'')
from   cobis..cl_parametro
where  pa_nemonico = 'SOBAUT'
and    pa_producto = 'CCA'

-- Fecha de Proceso
select @w_fecha_cierre = isnull(fc_fecha_cierre,''),
       @w_fecha_proc   = isnull(convert(varchar,@s_date,103),'')
from   cobis..ba_fecha_cierre
where  fc_producto = @w_cod_prod_cca

--Estados de Cartera
exec @w_return = sp_estados_cca
   @o_est_vigente   = @w_est_vigente   out, --1
   @o_est_novigente = @w_est_novigente out, --0
   @o_est_cancelado = @w_est_cancelado out, --3
   @o_est_credito   = @w_est_credito   out, --99
   @o_est_anulado   = @w_est_anulado   out, --6
   @o_est_castigado = @w_est_castigado out, --4
   @o_est_vencido   = @w_est_vencido   out  --2

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   select @w_error = @w_return
   goto ERROR  
end

--Obtener informacion de prestamo
select @w_op_operacion = op_operacion,
       @w_op_tramite   = op_tramite,
       @w_op_cliente   = op_cliente,
       @w_tasa_efec    = isnull(op_tasa_cap,0)
from   ca_operacion
where  op_banco = @i_banco
if @@rowcount = 0
begin
   select @w_error   = 725054,  --No existe la operación
          @w_mensaje = 'No existe la operación'
   goto ERROR
end

--fecha sig pago
select @w_fecha_sig_pgo = convert(varchar(10),isnull(max(di_fecha_ven),'01/01/1900'),103)
from   ca_dividendo
where  di_operacion  = @w_op_operacion
and    di_fecha_ini >= @s_date
and    di_fecha_ven <= @s_date
if @w_fecha_sig_pgo in (null,'01/01/1900')
begin
   select @w_fecha_sig_pgo = convert(varchar(10),isnull(min(di_fecha_ven),'01/01/1900'),103) 
   from   ca_dividendo  
   where  di_operacion = @w_op_operacion 
   and    di_estado    = @w_est_novigente
end

--tasas de interes nominal
select @w_tasa_nominal   = isnull(round(convert(decimal(18,2), sum(ro_porcentaje)) , 2), 0)
from   ca_rubro_op 
where  ro_operacion  = @w_op_operacion
and    ro_tipo_rubro = 'I' --Interes

--tasas de interes moratorio
select @w_tasa_moratoria = isnull(round(convert(decimal(18,2), sum(ro_porcentaje)) , 2), 0)
from   ca_rubro_op
where  ro_operacion  = @w_op_operacion
and    ro_tipo_rubro = 'M' --Mora

-- Diferencia entre tasa IMO e INT
select @w_dif_imo_int = isnull((@w_tasa_moratoria - @w_tasa_nominal), 0)

-- Tipo de operación [G: Grupal Padre, H: Grupal Hija, N: Individual]
exec @w_return = sp_tipo_operacion
   @i_banco    = @i_banco,
   @i_en_linea = 'N',
   @o_tipo     = @w_tipo_operacion out

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   select @w_error = @w_return
   goto ERROR
end

if @w_tipo_operacion != 'G'
begin
   select @w_error   = 70203,  --ERROR: OPERACION NO EXISTE O NO ES UNA OPERACION GRUPAL
          @w_mensaje = 'ERROR: OPERACION NO EXISTE O NO ES UNA OPERACION GRUPAL'
   goto ERROR
end

--Datos para reporte de estado cuenta grupal
if @i_operacion = 'A'
begin

   --Datos de cabecera

   select 'fecha_proc'        = @w_fecha_proc,
          'num_cligrp'        = a.op_cliente,
          'nombrecligrp'      = isnull((select isnull(en_nombre,'') + ' ' + isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'')
                                        from   cobis..cl_ente
                                        where  en_ente = a.op_cliente), ''),
          'num_grupo'         = isnull(a.op_grupo,0),
          'desc_grupo'        = isnull(b.gr_nombre,''),
          'num_op_banco'      = a.op_banco,
          'cuota_grp'         = a.op_cuota,
          'fecha_pag_grp'     = @w_fecha_sig_pgo,
          'tipo_operacion'    = isnull((select valor
                                        from   cobis..cl_tabla t, cobis..cl_catalogo c
                                        where  t.tabla  = 'ca_toperacion'
                                        and    c.tabla  = t.codigo
                                        and    c.codigo = a.op_toperacion
                                        and    c.estado = 'V'), ''),
          'interes_nominal'   = @w_tasa_nominal,
          'interes_efect'     = @w_tasa_efec,
          'interes_moratorio' = @w_dif_imo_int,
          'plazo'             = isnull(a.op_plazo,0),
          'fechaotorgamiento' = isnull(convert(varchar(10),op_fecha_ini,103),''),
          'fecha_fin'         = isnull(convert(varchar(10),op_fecha_fin,103),''),
          'frecuencia_pgo'    = isnull((select td_descripcion
                                        from   ca_tdividendo
                                        where  td_tdividendo = a.op_tplazo), ''),
          'cod_destino'       = isnull(tr_cod_actividad,''),
          'desc_destino'      = isnull((select valor
                                        from   cobis..cl_tabla t, cobis..cl_catalogo c
                                        where  t.tabla  = 'cl_subactividad_ec'
                                        and    c.tabla  = t.codigo
                                        and    c.codigo = tr_cod_actividad
                                        and    c.estado = 'V'), ''),
          'simbolo_moneda'    = isnull((select mo_simbolo 
                                        from cobis..cl_moneda
                                        where op_moneda = mo_moneda), ''),
          'ciclo_grupo'       = isnull((select ci_ciclo 
                                        from ca_ciclo with (nolock)
                                        where a.op_operacion = ci_operacion), 0)
   from   cob_cartera..ca_operacion a,
          cobis..cl_grupo b,
          cob_credito..cr_tramite
   where  a.op_banco   = @i_banco
   and    a.op_grupo   = b.gr_grupo
   and    a.op_tramite = tr_tramite

   --Datos de detalle

   --Tabla temporal para el universo de operaciones hijas
   if exists (select 1 from sysobjects where name = '#saldos_grp')
      drop table #saldos_grp

   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al borrar tabla #saldos_grp',
             @w_return  = @w_error
      goto ERROR
   end

   --Creacion de tabla temporal para el universo de operaciones hijas
   create table #saldos_grp ( 
      fila                int         null,
      contador            int         null,
      fechamovimientogrp  datetime    null,
      conceptogrp         varchar(30) null,
      formagrp            varchar(30) null,
      val_recibgrp        money       null,
      valcap_capgrp       money       null,
      valcap_vengrp       money       null,
      valcap_resolgrp     money       null,
      val_intgrp          money       null,
      val_moragrp         money       null,
      val_segv            money       null,
      val_sege            money       null,
      val_otrosgrp        money       null,
      saldogrp            money       null,
      excesogrp           money       null
   )
   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al crear tabla #saldos_grp',
             @w_return  = @w_error
      goto ERROR
   end

   --Para las transacciones DES
   select row_number() over( partition by tr_operacion,tr_secuencial,tr_tran
                       order by tr_operacion,tr_secuencial,tr_tran) as numero_fila,
          tr_operacion     as num_operacion,      tr_secuencial     as tran_secuencial,
          tr_fecha_mov     as fechamovimientogrp, tr_tran           as conceptogrp,
          dtr_concepto     as formagrp,           dtr_monto         as val_recibgrp,
          convert(money,0) as valcap_capgrp,      convert(money,0)  as valcap_vengrp, 
          convert(money,0) as valcap_resolgrp,    convert(money,0)  as val_intgrp,
          convert(money,0) as val_moragrp,        convert(money,0)  as val_segv,
          convert(money,0) as val_sege,           convert(money,0)  as val_otrosgrp,
          convert(money,0) as saldogrp,           convert(money,0)  as excesogrp
   into   #saldos_grp_tmp
   from   cob_cartera..ca_operacion,
          cob_cartera..ca_transaccion,
          cob_cartera..ca_det_trn,
          cob_cartera..ca_producto
   where  op_ref_grupal        = @i_banco
   and    tr_operacion         = op_operacion
   and    tr_tran              = 'DES'
   and    tr_estado           != 'RV'
   and    dtr_operacion        = tr_operacion
   and    dtr_secuencial       = tr_secuencial
   and    dtr_concepto         = cp_producto

   --Capital Vigente DES
   select @w_valcap_viggrp = isnull(sum(dtr_monto),0)
   from   #saldos_grp_tmp,
          ca_det_trn,
          ca_rubro_op
   where  dtr_operacion  = num_operacion
   and    dtr_secuencial = tran_secuencial
   and    dtr_concepto   = ro_concepto
   and    dtr_operacion  = ro_operacion
   and    ro_tipo_rubro  = 'C'    --Capital
   and    dtr_estado    in (0,1)
   and    numero_fila    = 1 -- garantiza la actualizacion de 1 registro

   --Para las transacciones PAG
   insert into #saldos_grp_tmp(
          num_operacion,   tran_secuencial, fechamovimientogrp, conceptogrp,
          formagrp,        val_recibgrp,    valcap_capgrp,      valcap_vengrp,
          valcap_resolgrp, val_intgrp,      val_moragrp,        val_segv,
          val_sege,        val_otrosgrp,    saldogrp,           excesogrp
          )
   select tr_operacion     as num_operacion,      tr_secuencial     as tran_secuencial,
          tr_fecha_mov     as fechamovimientogrp, tr_tran           as conceptogrp,
          abd_concepto     as formagrp,           sum(abd_monto_mn) as val_recibgrp, 
          convert(money,0) as valcap_capgrp,      convert(money,0)  as valcap_vengrp, 
          convert(money,0) as valcap_resolgrp,    convert(money,0)  as val_intgrp,
          convert(money,0) as val_moragrp,        convert(money,0)  as val_segv,
          convert(money,0) as val_sege,           convert(money,0)  as val_otrosgrp,
          convert(money,0) as saldogrp,           convert(money,0)  as excesogrp
   from   ca_abono_det,
          ca_abono,
          ca_operacion,
          ca_transaccion,
          ca_producto
   where  op_ref_grupal        = @i_banco
   and    tr_operacion         = op_operacion
   and    tr_tran              = 'PAG'
   and    tr_estado           != 'RV' 
   and    tr_secuencial        = ab_secuencial_pag
   and    ab_secuencial_ing    = abd_secuencial_ing
   and    ab_operacion         = tr_operacion
   and    abd_operacion        = ab_operacion
   and    abd_concepto         = cp_producto
   --and    abd_concepto  not like 'VAC%'
   and    abd_concepto        != @w_param_sob_aut
   group by tr_operacion, tr_secuencial, tr_fecha_mov, tr_tran, abd_concepto

   create nonclustered index idx_saldos_grp_ope_1
       on #saldos_grp_tmp(num_operacion,tran_secuencial)

   create nonclustered index idx_saldos_grp_ope_2
       on #saldos_grp_tmp(fechamovimientogrp,conceptogrp,formagrp)

   alter table #saldos_grp_tmp add secuencial int identity(1,1)

   --Capital Vigente
   update #saldos_grp_tmp
   set    valcap_capgrp = (select isnull(sum(dtr_monto),0)
                           from   ca_det_trn,
                                  ca_rubro_op,
                                  ca_concepto
                           where  dtr_operacion  = num_operacion
                           and    dtr_secuencial = tran_secuencial
                           and    dtr_concepto   = ro_concepto
                           and    dtr_operacion  = ro_operacion
                           and    ro_tipo_rubro  = 'C'    --Capital
                           and    dtr_concepto   = co_concepto
                           and    ro_tipo_rubro  = co_categoria
                           and    ((dtr_estado    in (0,1)) --Estados de vigente contablemente
                                  or
                                  (((dtr_codvalor%(co_codigo*1000))/10) in (0,1)))
                           )
   from  #saldos_grp_tmp,
         ca_det_trn
   where num_operacion      = dtr_operacion
   and   tran_secuencial    = dtr_secuencial
   and   numero_fila        is null

   --Capital Vencido
   update #saldos_grp_tmp
   set    valcap_vengrp = (select isnull(sum(dtr_monto),0)
                           from   ca_det_trn,
                                  ca_rubro_op,
                                  ca_concepto
                           where  dtr_operacion  = num_operacion
                           and    dtr_secuencial = tran_secuencial
                           and    dtr_concepto   = ro_concepto
                           and    dtr_operacion  = ro_operacion
                           and    ro_tipo_rubro  = 'C'        --Vencido
                           and    dtr_concepto   = co_concepto
                           and    ro_tipo_rubro  = co_categoria
                           and    ((dtr_estado    in (2,5,10,11)) --Estados vencidos contablemente
                                  or
                                  (((dtr_codvalor%(co_codigo*1000))/10) in (2,5,10,11)))
                           )
   from   #saldos_grp_tmp,
          ca_det_trn
   where  dtr_operacion  = num_operacion
   and    dtr_secuencial = tran_secuencial
   and    numero_fila    is null

   --Capital resolucion(castigado)
   update #saldos_grp_tmp
   set    valcap_resolgrp = (select isnull(sum(dtr_monto),0)
                             from   ca_det_trn,
                                    ca_rubro_op,
                                    ca_concepto
                             where  dtr_operacion  = num_operacion
                             and    dtr_secuencial = tran_secuencial
                             and    dtr_concepto   = ro_concepto
                             and    dtr_operacion  = ro_operacion
                             and    ro_tipo_rubro  = 'C'  --resolucion(castigado)
                             and    dtr_concepto   = co_concepto
                             and    ro_tipo_rubro  = co_categoria
                             and    ((dtr_estado    in (4)) -- Estados de resolucion(castigado)
                                    or
                                    (((dtr_codvalor%(co_codigo*1000))/10) in (4)))
                             )
   from   #saldos_grp_tmp,
          ca_det_trn
   where  dtr_operacion  = num_operacion
   and    dtr_secuencial = tran_secuencial
   and    numero_fila    is null   

   --Intereses
   update #saldos_grp_tmp
   set    val_intgrp = (select isnull(sum(dtr_monto),0)
                        from   ca_det_trn,
                               ca_rubro_op
                        where  dtr_operacion  = num_operacion
                        and    dtr_secuencial = tran_secuencial
                        and    dtr_concepto   = ro_concepto
                        and    dtr_operacion  = ro_operacion
                        and    ro_tipo_rubro  = 'I' )--Intereses
   from   #saldos_grp_tmp,
          ca_det_trn
   where  dtr_operacion  = num_operacion
   and    dtr_secuencial = tran_secuencial

   --Interes de mora
   update #saldos_grp_tmp
   set    val_moragrp = (select isnull(sum(dtr_monto),0)
                         from   ca_det_trn,
                                ca_rubro_op
                         where  dtr_operacion  = num_operacion
                         and    dtr_secuencial = tran_secuencial
                         and    dtr_concepto   = ro_concepto
                         and    dtr_operacion  = ro_operacion
                         and    ro_tipo_rubro  = 'M') --Interes de mora
   from   #saldos_grp_tmp,
          ca_det_trn
   where  dtr_operacion  = num_operacion
   and    dtr_secuencial = tran_secuencial

   --Seguro de V
   update #saldos_grp_tmp
   set    val_segv = (select isnull(sum(dtr_monto),0)
                      from   ca_det_trn
                      where  dtr_operacion  = num_operacion
                      and    dtr_secuencial = tran_secuencial
                      and    dtr_concepto   = 'SDV') --Seguro de V
   from   #saldos_grp_tmp,
          ca_det_trn
   where  dtr_operacion  = num_operacion
   and    dtr_secuencial = tran_secuencial
   and    dtr_concepto   = 'SDV'

   --Seguro de E
   update #saldos_grp_tmp
   set    val_sege = (select isnull(sum(dtr_monto),0)
                      from   ca_det_trn
                      where  dtr_operacion  = num_operacion
                      and    dtr_secuencial = tran_secuencial
                      and    dtr_concepto   = 'SDE') --Seguro de E
   from   #saldos_grp_tmp,
          ca_det_trn
   where  dtr_operacion  = num_operacion
   and    dtr_secuencial = tran_secuencial
   and    dtr_concepto   = 'SDE'

   --Otros
   update #saldos_grp_tmp
   set    val_otrosgrp = (select isnull(sum(dtr_monto),0)
                          from   ca_det_trn,
                                 ca_rubro_op
                          where  dtr_operacion  = num_operacion
                          and    dtr_secuencial = tran_secuencial
                          and    dtr_concepto   = ro_concepto
                          and    dtr_operacion  = ro_operacion
                          and    ro_tipo_rubro not in ('C','I','M') --Otros
                          and    dtr_concepto  not in ('SDV','SDE'))
   from   #saldos_grp_tmp,
          ca_det_trn
   where  dtr_operacion  = num_operacion
   and    dtr_secuencial = tran_secuencial

   --Excesos
   update #saldos_grp_tmp
   set    excesogrp = (select isnull(sum(dtr_monto),0)
                       from   ca_det_trn
                       where  dtr_operacion  = num_operacion
                       and    dtr_secuencial = tran_secuencial
                       and    dtr_concepto   = @w_param_sob_aut) --Excesos
   from   #saldos_grp_tmp,
          ca_det_trn
   where  dtr_operacion  = num_operacion
   and    dtr_secuencial = tran_secuencial
   and    dtr_concepto   = @w_param_sob_aut

   --Insercion en tabla final de reporte
   insert into #saldos_grp(
          fila,         fechamovimientogrp, conceptogrp,   formagrp,
          val_recibgrp, valcap_capgrp,      valcap_vengrp, valcap_resolgrp,
          val_intgrp,   val_moragrp,        val_segv,      val_sege,
          val_otrosgrp, saldogrp,           excesogrp
          )
   select row_number() over( partition by fechamovimientogrp,conceptogrp
                       order by fechamovimientogrp,conceptogrp) as fila,
          isnull(fechamovimientogrp, '01/01/1900'),
          isnull(conceptogrp,''),
          isnull(formagrp,''),
          isnull(round(sum(isnull(val_recibgrp, 0)) , 2), 0),
          isnull(round(sum(isnull(valcap_capgrp, 0)) , 2), 0),
          isnull(round(sum(isnull(valcap_vengrp, 0)) , 2), 0),
          isnull(round(sum(isnull(valcap_resolgrp, 0)) , 2), 0),
          isnull(round(sum(isnull(val_intgrp, 0)) , 2), 0),
          isnull(round(sum(isnull(val_moragrp, 0)) , 2), 0),
          isnull(round(sum(isnull(val_segv, 0)) , 2), 0),
          isnull(round(sum(isnull(val_sege, 0)) , 2), 0),
          isnull(round(sum(isnull(val_otrosgrp, 0)) , 2), 0),
          isnull(round(sum(isnull(saldogrp, 0)) , 2), 0),
          isnull(round(sum(isnull(excesogrp, 0)) , 2), 0)
   from   #saldos_grp_tmp
   group by fechamovimientogrp, conceptogrp, formagrp
   order by conceptogrp

   update #saldos_grp
   set contador     = @w_contador2,
       @w_contador2 = @w_contador2 + 1

   --actualizar columna saldo por medio de un bucle

   select @w_contador   = 1,
          @w_saldo_acum = 0

   select @w_contador2 = count(1) from #saldos_grp

   while @w_contador <= @w_contador2   
   begin

      select  @w_valcap_capgrp   = 0,
              @w_valcap_vengrp   = 0,
              @w_valcap_resolgrp = 0,
              @w_sec             = 0,
              @w_conceptogrp     = ''

      select @w_valcap_capgrp      = isnull(valcap_capgrp,0),
             @w_valcap_vengrp      = isnull(valcap_vengrp,0),
             @w_valcap_resolgrp    = isnull(valcap_resolgrp,0),
             @w_conceptogrp        = isnull(conceptogrp,''),
             @w_fechamovimientogrp = isnull(fechamovimientogrp,''),
             @w_formagrp           = isnull(formagrp,''),
             @w_sec                = contador,
             @w_fila               = fila
      from   #saldos_grp
      where  contador = @w_contador

      if @@rowcount = 0
         goto SIGUIENTE

      if @w_conceptogrp = 'DES'
      begin
         if @w_fila = 1
         begin
            select @w_saldo_acum = @w_saldo_acum + (@w_valcap_viggrp)
         end
         else
         begin
            select @w_saldo_acum = @w_saldo_acum
         end
      end

      if @w_conceptogrp = 'PAG'
      begin
         select @w_saldo_acum = @w_saldo_acum - (@w_valcap_capgrp + @w_valcap_vengrp + @w_valcap_resolgrp)
      end

      update #saldos_grp
      set    saldogrp = @w_saldo_acum
      where  contador = @w_contador

      SIGUIENTE:
      select @w_contador = @w_contador + 1

   end

   --Resultado final
   select 'contador'           = isnull(contador,0),
          'fechamovimientogrp' = isnull(convert(varchar(10),fechamovimientogrp,103),''),
          'conceptogrp'        = isnull(conceptogrp,''),
          'formagrp'           = isnull(formagrp,''),
          'val_recibgrp'       = isnull(round(convert(decimal(18,2), val_recibgrp)    , 2), 0),
          'valcap_capgrp'      = isnull(round(convert(decimal(18,2), valcap_capgrp)   , 2), 0),
          'valcap_vengrp'      = isnull(round(convert(decimal(18,2), valcap_vengrp)   , 2), 0),
          'valcap_resolgrp'    = isnull(round(convert(decimal(18,2), valcap_resolgrp) , 2), 0),
          'val_intgrp'         = isnull(round(convert(decimal(18,2), val_intgrp)      , 2), 0),
          'val_moragrp'        = isnull(round(convert(decimal(18,2), val_moragrp)     , 2), 0),
          'val_segv'           = isnull(round(convert(decimal(18,2), val_segv)        , 2), 0),
          'val_sege'           = isnull(round(convert(decimal(18,2), val_sege)        , 2), 0),
          'val_otrosgrp'       = isnull(round(convert(decimal(18,2), val_otrosgrp)    , 2), 0),
          'saldogrp'           = isnull(round(convert(decimal(18,2), saldogrp)        , 2), 0),
          'excesogrp'          = isnull(round(convert(decimal(18,2), excesogrp)       , 2), 0)
   from   #saldos_grp
end

return 0

ERROR:
exec @w_return = cobis..sp_cerror
     @t_debug  = @t_debug,
     @t_file   = @t_file,
     @t_from   = @w_sp_name,
     @i_num    = @w_error

return @w_error
go
