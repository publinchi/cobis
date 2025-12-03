/************************************************************************/
/*  Nombre Fisico:      qroperh.sp                                      */
/*  Nombre Logico:      sp_qr_operacion_his                             */
/*  Base de datos:      cob_cartera_his                                 */
/*  Producto:           Cartera                                         */
/*  Disenado por:       Sandra Ortiz                                    */
/*  Fecha de escritura: 10/30/1994                                      */
/************************************************************************/
/* IMPORTANTE                                                           */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/  
/*              PROPOSITO                                               */
/*  Este programa ejecuta el query de operaciones de cartera            */
/*  llamado por el SP sp_operacion_qry.                                 */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*   FECHA                  AUTOR                  RAZON                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion	*/
/*									  de char(1) a catalogo				*/
/************************************************************************/  

use cob_cartera_his
go

if exists (select 1 from sysobjects where name = 'sp_qr_operacion_his')
   drop proc sp_qr_operacion_his
go

create proc sp_qr_operacion_his (
@i_banco        varchar(64) = null,
@i_formato_fecha        int = null
)
as
declare 
   @w_sp_name                  varchar(32),
   @w_return                   int,
   @w_operacionca              int,
   @w_banco                    varchar(64),
   @w_cliente                  int,
   @w_toperacion               varchar(64),
   @w_oficina                  smallint,
   @w_moneda                   tinyint,
   @w_oficial                  smallint,
   @w_fecha_ini                datetime,
   @w_fecha_fin                datetime,
   @w_monto                    money,
   @w_tplazo                   varchar(64),
   @w_plazo                    smallint,
   @w_destino                  varchar(64),
   @w_producto                 tinyint,
   @w_lin_credito              varchar(64),
   @w_reajuste                 char(1),
   @w_reajuste_periodo         smallint,
   @w_reajuste_especial        char (1),
   @w_reajuste_fecha           datetime,
   @w_reajuste_num             tinyint,
   @w_ciudad                   int,
   @w_estado                   varchar(64),
   @w_renovaciones             tinyint,
   @w_porcentaje               float,
   @w_valor                    int,
   @w_nem_producto             varchar(64),
   @w_cuenta                   varchar(64),
   @w_cuota_completa           char(1),
   @w_anticipado_int           char(1),
   @w_reajuste_intereses       char(1),
   @w_reduccion                char(1),
   @w_cuota_anticipada         char(1),
   @w_dias_anio                smallint,
   @w_tipo_amortizacion        varchar(10),
   @w_cuota_fija               char(1),
   @w_cuota                    money,
   @w_cuota_capital            money,
   @w_periodos_gracia          tinyint,
   @w_periodos_gracia_int      tinyint,
   @w_dist_gracia              char(1),
   @w_tdividendo               varchar(64),
   @w_periodo_cap              smallint,
   @w_periodo_int              smallint,
   @w_dias_gracia              tinyint,
   @w_dia_pago                 tinyint,
   @w_renovacion               char(1),
   @w_num_renovacion           tinyint,
   @w_precancelacion           char(1),
   @w_tipo                     char(1),
   @w_base_calculo             char(1),
   @w_porcentaje_fin           float,
   @w_tasa_fin                 float,
   @w_tramite                  int,
   @w_fecha_prox_pag           datetime,
   @w_fecha_p                  datetime,
   @w_direccion                tinyint,
   /** DESCRIPCIONES  **/      
   @w_desc_toperacion          varchar(64),
   @w_desc_reajuste            varchar(64),
   @w_desc_tvencimiento        varchar(64),
   @w_desc_tdividendo          varchar(64),
   @w_desc_t_empresa           varchar(64),
   @w_desc_tmnio_empresa       varchar(64),
   @w_desc_tplazo              varchar(64),
   @w_desc_moneda              varchar(64),
   @w_desc_ciudad              varchar(64),
   @w_desc_destino             varchar(64),
   @w_desc_producto            varchar(64),
   @w_desc_ofi                 varchar(64),
   @w_inicio                   varchar(10),
   @w_fin                      varchar(10),
   @w_nombre                   varchar(64),
   @w_tasa                     float,
   @w_valint                   float,
   @w_referencial              varchar(64),
   @w_desc_referencial         varchar(64),
   @w_nom_oficial              varchar(64),
   @w_sector                   varchar(64),
   @w_banca                    catalogo,
   @w_des_sector               varchar(64),
   @w_anterior                 varchar(64),
   @w_migrada                  varchar(64),
   @w_desembolso               money,
   @w_refer                    varchar(255),
   @w_fecha_liq                datetime,
   @w_cuota_adic               char(1),
   @w_fecha                    datetime,
   @w_monto_aprobado           money,
   @w_tipo_aplicacion          char(1), 
   @w_mes_gracia               tinyint,
   @w_gracia_int               tinyint,
   @w_num_dec                  tinyint,
   @w_fecha_fija               char(1),
   @w_meses_hip                tinyint,
   @w_evitar_feriados          char(1),
   @w_fecha_ult_proceso        datetime,
   @w_saldo_operacion          money,
   @w_dias_clausula            int,
   @w_clausula_aplicada        char(1),
   @w_periodo_crecimiento      smallint,
   @w_tasa_crecimiento         float,
   @w_desc_direccion           varchar(254),
   @w_desc_tipo                varchar(64),
   @w_clase_cartera            varchar(64),
   @w_desc_clase_cartera       varchar(64),
   @w_origen_fondos            varchar(64),
   @w_fondos_propios           char(1),
   @w_tabla                    varchar(64),
   @w_desc_origen_fondos       varchar(64),
   @w_calificacion             catalogo,
   @w_fecha_ini_venc           datetime,
   @w_desc_calificacion        varchar(64),
   @w_numero_reest             int ,
   @w_saldo_operacion_finan    money,
   @w_fecha_ult_rees           datetime,
   @w_dias_venc                int,
   @w_prd_cobis                tinyint,
   @w_ref_exterior             varchar(64),
   @w_sujeta_nego              char(1),
   @w_ref_red                  varchar(24),
   @w_sal_pro_pon              money,
   @w_tipo_empresa             varchar(64),
   @w_validacion               varchar(64),
   @w_fecha_pri_cuota          datetime,
   @w_tr_subtipo               char(1),
   @w_des_subtipo              varchar(20),
   @w_recalcular               char(1),
   @w_dia_habil                char(1),
   @w_usa_tasa_eq              char(1),
   @w_grupo_fact               int, 
   @w_tramite_ficticio         int,
   @w_reajustable              char(1),
   @w_bvirtual                 char(1),
   @w_extracto                 char(1),
   @w_reestructuracion         char(1),
   @w_subtipo                  char(1),
   @w_fecha_embarque           datetime,
   @w_fecha_dex                datetime,
   @w_num_deuda_ext            varchar(64),  
   @w_num_comex                varchar(64),  
   @w_nace_vencida             char(1),
   @w_calcula_devolucion       char(1),
   @w_edad                     varchar(64),
   @w_estado_cobranza          varchar(64),
   @w_cobranza                 varchar(64),
   @w_tipo_linea               varchar(64),
   @w_div_vencido              int,
   @w_dias_cap_ven             int,
   @w_op_divcap_original       int
  
/*  Captura nombre de Stored Procedure  */
select  @w_sp_name = 'sp_qr_operacion'

select @w_producto = pd_producto
from cobis..cl_producto
where pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted


select @w_fecha = convert(varchar(10),fc_fecha_cierre,101)
from cobis..ba_fecha_cierre
where fc_producto = @w_producto

/** PARCHADO HATA CUANDO SE DECIDA UTILIZAR -- JCQ -- 10/10/2002 **/

select  
@w_operacionca = op_operacion,      
@w_banco = op_banco,
@w_fecha_ini = op_fecha_ini,
@w_fecha_fin = op_fecha_fin,
@w_toperacion = op_toperacion,
@w_desc_toperacion = ltrim(rtrim(op_toperacion)) + ' - ' + cx.valor,
@w_monto = op_monto,            
@w_tplazo = op_tplazo,      
@w_plazo = op_plazo,
@w_destino = op_destino,        
@w_desc_destino = ( select valor
                from cobis..cl_catalogo y, cobis..cl_tabla t
                where t.tabla = 'cr_objeto'
                and y.tabla   = t.codigo
                and y.codigo  = x.op_destino),
@w_oficina             = op_oficina,        
@w_moneda              = op_moneda,
@w_desc_moneda         = mo_descripcion,
@w_oficial             = op_oficial,        
@w_lin_credito         = op_lin_credito,   
@w_nem_producto        = op_forma_pago,
@w_cuenta              = op_cuenta,         
@w_reajustable         = op_reajustable,
@w_reajuste_fecha      = op_fecha_reajuste,
@w_reajuste_periodo    = op_periodo_reajuste,
@w_reajuste_especial   = op_reajuste_especial,
@w_cliente             = op_cliente,
@w_ciudad              = op_ciudad,
@w_desc_ciudad         = ci_descripcion,
@w_estado              = substring(A.es_descripcion,1,30),
@w_cuota_completa      = op_cuota_completa,
@w_anticipado_int      = op_tipo_cobro,
@w_reajuste_intereses  = op_reajuste_especial,
@w_reduccion           = op_tipo_reduccion,
@w_cuota_anticipada    = op_aceptar_anticipos,
@w_dias_anio           = op_dias_anio,
@w_tipo_amortizacion   = op_tipo_amortizacion,
@w_cuota               = op_cuota,
@w_cuota_capital       = 0,
@w_periodos_gracia     = op_gracia_cap,
@w_periodos_gracia_int = op_gracia_int,
@w_dist_gracia         = op_dist_gracia,
@w_tdividendo          = op_tdividendo,
@w_periodo_cap         = op_periodo_cap,
@w_periodo_int         = op_periodo_int,
@w_dias_gracia         = 0,
@w_fecha_pri_cuota     = op_fecha_pri_cuot,
@w_dia_pago            = op_dia_fijo,
@w_renovacion          = op_renovacion ,
@w_num_renovacion      = op_num_renovacion,
@w_precancelacion      = op_precancelacion,
@w_tipo                = op_tipo,
@w_desc_tipo           = (select valor
                         from cobis..cl_catalogo
                         where tabla = (select codigo
                         from cobis..cl_tabla
                         where tabla  = 'ca_tipo_prestamo')
                         and   codigo = x.op_tipo),
@w_tramite             = op_tramite,
@w_fecha_prox_pag      = null,
@w_desc_ofi            = (select of_nombre
                          from cobis..cl_oficina
                          where of_oficina = x.op_oficina),
--@w_sector              = op_sector,
@w_banca               = op_banca,
@w_anterior            = op_anterior,
@w_migrada             = op_migrada,
@w_refer               = op_comentario,
@w_desembolso          = 0,
@w_fecha_liq           = op_fecha_liq,
@w_nombre              = op_nombre,
@w_monto_aprobado      = op_monto_aprobado,
@w_tipo_aplicacion     = op_tipo_aplicacion,
@w_gracia_int          = op_gracia_int,
@w_mes_gracia          = op_mes_gracia,
@w_evitar_feriados     = op_evitar_feriados,
@w_fecha_ult_proceso   = op_fecha_ult_proceso,
@w_dias_clausula       = op_dias_clausula,
@w_clausula_aplicada   = op_clausula_aplicada,
@w_periodo_crecimiento = op_periodo_crecimiento,
@w_tasa_crecimiento    = op_tasa_crecimiento,
@w_direccion           = op_direccion,
@w_clase_cartera       = op_clase,
@w_origen_fondos       = op_origen_fondos,
@w_calificacion        = op_calificacion,
@w_fondos_propios      = op_fondos_propios,
@w_numero_reest        = op_numero_reest,
@w_prd_cobis           = op_prd_cobis,
@w_ref_exterior        = op_ref_exterior,
@w_sujeta_nego         = op_sujeta_nego, 
@w_ref_red             = op_nro_red,
@w_sal_pro_pon         = op_sal_pro_pon,
@w_tipo_empresa        = op_tipo_empresa,
@w_dia_habil           = isnull(op_dia_habil,'N'),
@w_recalcular          = isnull(op_recalcular_plazo,'N'),
@w_usa_tasa_eq         = isnull(op_usar_tequivalente,'N'),
@w_base_calculo        = op_base_calculo,
@w_validacion          = op_validacion,
@w_grupo_fact          = op_grupo_fact,
@w_tramite_ficticio    = op_tramite_ficticio,
@w_bvirtual            = op_bvirtual,
@w_extracto            = op_extracto,
@w_reestructuracion    = op_reestructuracion,
@w_subtipo             = op_tipo_cambio,
@w_fecha_embarque      = op_fecha_embarque,
@w_fecha_dex           = op_fecha_dex,   
@w_num_deuda_ext       = op_num_deuda_ext,  
@w_nace_vencida        = op_nace_vencida,
@w_num_comex           = op_num_comex,
@w_calcula_devolucion  = op_calcula_devolucion,
@w_edad                = substring(B.es_descripcion,1,30),
@w_cobranza            = op_estado_cobranza,
@w_tipo_linea          = op_tipo_linea,
@w_op_divcap_original  = op_divcap_original

from
ca_operacion x,
cobis..cl_catalogo cx,
cobis..cl_tabla tx,
cobis..cl_moneda,
cobis..cl_ciudad,
cob_cartera..ca_estado A,
cob_cartera..ca_estado B
where   x.op_banco = @i_banco
and mo_moneda = op_moneda
and tx.tabla = 'ca_toperacion'
and cx.tabla = tx.codigo
and cx.codigo = op_toperacion
and ci_ciudad = op_ciudad
and     A.es_codigo = op_estado
and     B.es_codigo = op_edad

/* DECIMALES */
exec cob_cartera..sp_decimales
@i_moneda  = @w_moneda,
@o_decimales = @w_num_dec out

select  @w_desc_producto = cp_descripcion
from    cob_cartera..ca_producto
where   cp_producto = @w_nem_producto

/** TIPO DE REAJUSTE **/
select  @w_desc_tplazo = td_descripcion
from    cob_cartera..ca_tdividendo
where   td_tdividendo = @w_tplazo

/** LINEA DE CREDITO  **/
select 
@w_inicio = NULL,
@w_fin    = NULL
select 
@w_inicio = convert (varchar(10), li_fecha_inicio,@i_formato_fecha),
@w_fin    = convert (varchar(10), li_fecha_vto,@i_formato_fecha)
from   cob_credito..cr_linea
where  li_num_banco = @w_lin_credito

select @w_tr_subtipo = tr_subtipo
       from cob_credito..cr_tramite
       where tr_tramite = @w_tramite

if @w_tr_subtipo = 'O'
   select @w_des_subtipo = 'ORIGINAL'

if @w_tr_subtipo = 'R'
   select @w_des_subtipo = 'RENOVACION'

if @w_tr_subtipo = 'E'
   select @w_des_subtipo = 'REESTRUCTURACION'

if @w_tr_subtipo = 'P'
   select @w_des_subtipo = 'PRORROGA'

if @w_tr_subtipo = 'S'
   select @w_des_subtipo = 'SUBRROGACION'

if @w_tr_subtipo = 'T'
   select @w_des_subtipo = 'OTRO SI'

if @w_tr_subtipo = 'U'
   select @w_des_subtipo = 'FUSION'


/**  FECHAS DE REAJUSTE  **/
select @w_reajuste_fecha = min(re_fecha)
from ca_reajuste
where re_operacion = @w_operacionca
and   re_fecha    >= @w_fecha_ult_proceso

/**  TOTAL DE INTERES  **/
select 
@w_tasa=  isnull(sum(ro_porcentaje) ,0),
@w_valint=  isnull(sum(am_cuota) ,0)
from ca_rubro_op,ca_amortizacion
where ro_operacion  =  @w_operacionca
and ro_tipo_rubro =  'I'
and ro_fpago      in ('P','A') 
and am_operacion  =  @w_operacionca
and am_concepto   =  ro_concepto

select  @w_desc_tdividendo = td_descripcion
from    cob_cartera..ca_tdividendo
where   td_tdividendo = @w_tdividendo

select @w_nom_oficial = fu_nombre 
from cobis..cl_funcionario, cobis..cc_oficial   
where oc_oficial= @w_oficial
and   fu_funcionario = oc_funcionario
set transaction isolation level read uncommitted

select @w_des_sector   = Y.valor
from   cobis..cl_tabla X,cobis..cl_catalogo Y
where  X.tabla      = 'cl_banca_cliente' --xma 'cc_tipo_banca'  --'cc_sector'@w_sector
and    X.codigo     = Y.tabla
--and    Y.codigo     = @w_sector 
and    Y.codigo     = @w_banca
set transaction isolation level read uncommitted

/** VERIFICAR SI PRESENTA CUOTAS ADICIONALES **/ 
if exists(select 1 from ca_cuota_adicional
          where ca_operacion = @w_operacionca
          and ca_cuota <> 0)
   select @w_cuota_adic = 'S'
else
   select @w_cuota_adic = "N"

if isnull(@w_dia_pago,0) = 0
   select @w_fecha_fija = 'N'
else
   select @w_fecha_fija = 'S'   

if @w_tipo_amortizacion = 'FRANCESA'
   select @w_cuota_fija = 'S'
else
   select @w_cuota_fija = 'N'

if isnull(@w_reajustable,'N') = 'N'
   select @w_reajuste = 'N',
   @w_reajuste_periodo = 0
else
   select @w_reajuste = 'S' 

/*SALDO DE LA OPERACION. MODIFICADO*/
select @w_saldo_operacion = isnull(sum(am_cuota + am_gracia - am_pagado),0)
from ca_amortizacion, ca_rubro_op
where am_operacion = @w_operacionca
and ro_operacion = @w_operacionca
and ro_tipo_rubro= 'C'
and ro_concepto  = am_concepto


/*SALDO TOTAL DE LA OPERACION */
/*
/** CONSULTA SALDO DE CANCELACION **/
exec @w_return = sp_calcula_saldo
@i_operacion   = @w_operacionca,
@o_saldo       = @w_saldo_operacion_finan out
  */


select @w_saldo_operacion_finan = isnull(@w_saldo_operacion_finan,0)

/** FIN CONSULTA SALDO DE CANCELACION **/


/*OBTENIENDO DESCRIPCION DE LA DIRECCION DEL CLIENTE */
select @w_desc_direccion = di_descripcion
from cobis..cl_direccion
where di_ente    = @w_cliente
and di_direccion = @w_direccion
set transaction isolation level read uncommitted

/*DESCRIPCIONES DE CLASE DE CARTERA Y ORIGEN DE FONDOS*/
select @w_desc_clase_cartera = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'cr_clase_cartera'
and   X.codigo= Y.tabla
and   Y.codigo= @w_clase_cartera
set transaction isolation level read uncommitted

/*DESCRIPCIONES DE TIPO DE EMPRESA*/
select @w_desc_t_empresa = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'ca_tipo_empresa'
and   X.codigo= Y.tabla
and   Y.codigo= @w_tipo_empresa
set transaction isolation level read uncommitted

/*DESCRIPCIONES DE TAMA¾O DE EMPRESA*/
select @w_desc_tmnio_empresa = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'ca_validacion'
and   X.codigo= Y.tabla
and   Y.codigo= @w_validacion
set transaction isolation level read uncommitted

if   @w_fondos_propios = 'S'
     select @w_tabla = 'ca_fondos_propios'
else 
     select @w_tabla = 'ca_fondos_nopropios'


select @w_desc_origen_fondos = 'BANCO AGRARIO'

if @w_tipo  = 'R' begin
   select @w_desc_origen_fondos = valor
   from cobis..cl_tabla X, cobis..cl_catalogo Y
   where X.tabla = 'ca_tipo_linea'
   and   X.codigo= Y.tabla
   and   Y.codigo= @w_tipo_linea
   set transaction isolation level read uncommitted
end


/*CALIFICACION DE LA CARTERA*/
select @w_desc_calificacion = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'cr_calificacion'
and   X.codigo= Y.tabla
and   Y.codigo= @w_calificacion
set transaction isolation level read uncommitted

/*FECHA ULTIMA REESTRUCTURACION*/
select @w_fecha_ult_rees = max(tr_fecha_mov)
from ca_transaccion 
where tr_tran = 'RES'
and  tr_operacion = @w_operacionca

/* DIAS DE VENCIMIENTO*/
if @w_base_calculo = 'R'
select @w_dias_venc = isnull(datediff(day,min(di_fecha_ven), @w_fecha_ult_proceso ) ,0)
from ca_dividendo 
where di_operacion = @w_operacionca
and   di_estado    = 2 
else begin
   set rowcount 1
   select @w_fecha_ini_venc = di_fecha_ven
   from ca_dividendo 
   where di_operacion = @w_operacionca
   and di_estado = 2 

   set rowcount 0

   select @w_fecha_p = @w_fecha_ult_proceso 

   exec @w_return = cob_cartera..sp_dias_base_comercial
   @i_fecha_ini   = @w_fecha_ini_venc,
   @i_fecha_ven   = @w_fecha_p,
   @i_opcion      = 'D',
   @o_dias_int    = @w_dias_venc out
   
end


select @w_dias_venc = @w_dias_venc +  isnull(@w_op_divcap_original, 0)


/** ESTADO DE COBRANZA **/
select @w_estado_cobranza = c.valor
from   cobis..cl_tabla t,
cobis..cl_catalogo c
where  t.tabla = 'cr_estado_cobranza'
and    c.tabla = t.codigo
and    c.codigo = @w_cobranza
set transaction isolation level read uncommitted


/** CAPITAL VENCIDO **/

select @w_div_vencido = isnull(min(di_dividendo),0)
from ca_amortizacion, ca_rubro_op,ca_dividendo
where am_operacion = @w_operacionca
and ro_operacion = @w_operacionca
and am_operacion = di_operacion
and am_dividendo = di_dividendo
and am_cuota - am_pagado > 0   ---Que no este pagado
and di_estado    = 2
and ro_tipo_rubro= 'C'
and ro_concepto  = am_concepto


select @w_dias_cap_ven = 0
if @w_div_vencido > 0 begin

   select @w_dias_cap_ven = datediff(dd,di_fecha_ven,@w_fecha)
   from ca_dividendo
   where di_operacion = @w_operacionca
   and di_dividendo = @w_div_vencido
   if @w_dias_cap_ven < 0
      select @w_dias_cap_ven = 0
 

end

/**********************/
select  
@w_operacionca,
@w_banco,
@w_tramite,
@w_lin_credito,
@w_estado, 
@w_cliente,
@w_toperacion,
@w_desc_toperacion,
@w_moneda,
@w_desc_moneda, --10
@w_oficina, 
@w_oficial,
convert(varchar(10),@w_fecha_ini,@i_formato_fecha),
convert(varchar(10),@w_fecha_fin,@i_formato_fecha),
convert(varchar(10),@w_fecha_prox_pag,@i_formato_fecha),
convert(float, @w_monto),
@w_tplazo,
@w_desc_tplazo,
@w_plazo,
@w_tdividendo,  --20
@w_desc_tdividendo,
@w_periodo_cap,
@w_periodo_int,
@w_periodos_gracia,
@w_periodos_gracia_int,
@w_dist_gracia,
@w_destino,
@w_desc_destino, 
@w_ciudad,
@w_desc_ciudad, --30
@w_nem_producto,
@w_desc_producto,
@w_cuenta,
@w_reajuste_periodo,
convert(varchar(10),@w_reajuste_fecha,@i_formato_fecha),
@w_reajuste_num,
@w_renovacion,
@w_num_renovacion,
@w_precancelacion, 
@w_tipo, -- 40
@w_porcentaje_fin,
@w_tasa_fin,
@w_cuota_completa,
@w_anticipado_int,
@w_reajuste_intereses,
@w_reduccion,  
@w_cuota_anticipada,
@w_dias_anio,
@w_tipo_amortizacion,
@w_cuota_fija, -- 50
convert(float, @w_cuota),
convert(float, @w_cuota_capital),
@w_dias_gracia,
@w_dia_pago, 
@w_desc_ofi,
@w_inicio,
@w_fin,
@w_nombre,
@w_tasa,
@w_referencial, -- 60
@w_desc_referencial,
@w_nom_oficial,
0, -- Anterior periodo de calculo
@w_reajuste_especial,
@w_banca,     --xma @w_sector,
@w_des_sector,
@w_anterior,
@w_migrada,
@w_refer,
convert(float, @w_desembolso), -- 70
convert(varchar(10),@w_fecha_liq,@i_formato_fecha), 
@w_cuota_adic,
@w_meses_hip,
convert(float, @w_monto_aprobado),
@w_tipo_aplicacion,
@w_gracia_int,
@w_mes_gracia,
@w_num_dec,
@w_fecha_fija, 
@w_reajuste,   -- 80
@w_evitar_feriados,
convert(varchar(10),@w_fecha_ult_proceso,@i_formato_fecha),
convert(float, @w_saldo_operacion),
@w_dias_clausula,
@w_clausula_aplicada,
@w_periodo_crecimiento,
@w_tasa_crecimiento,
@w_desc_direccion,
@w_desc_tipo,
@w_clase_cartera,    --90
@w_desc_clase_cartera,
@w_origen_fondos,
@w_desc_origen_fondos,
@w_desc_calificacion,
@w_numero_reest,
convert(float, @w_saldo_operacion_finan),
convert(varchar(10),@w_fecha_ult_rees,@i_formato_fecha),
@w_dias_venc,
@w_fondos_propios ,
@w_prd_cobis , --100
@w_ref_exterior,
@w_sujeta_nego, 
@w_ref_red,
convert(float, @w_sal_pro_pon),
@w_tipo_empresa ,
@w_desc_t_empresa,
@w_validacion   ,
@w_desc_tmnio_empresa,
convert(varchar(10),@w_fecha_pri_cuota,@i_formato_fecha),
@w_des_subtipo, --110
@w_base_calculo,
@w_recalcular,
@w_dia_habil,
@w_usa_tasa_eq ,
@w_grupo_fact,
@w_dias_cap_ven, ---116 
@w_bvirtual,
@w_extracto,
@w_reestructuracion,
@w_subtipo, --120
convert(varchar(10),@w_fecha_embarque,@i_formato_fecha),
convert(varchar(10),@w_fecha_dex,@i_formato_fecha),
@w_num_deuda_ext,  
@w_nace_vencida, 
@w_num_comex,    --125 
@w_calcula_devolucion,
@w_edad, --127
@w_estado_cobranza  ---128




return 0

go
