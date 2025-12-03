/************************************************************************/
/*  Nombre Fisico      :      creaopfng.sp                              */
/*  Nombre Logico      :      sp_creaop_fng                             */
/*  Base de datos      :      cob_cartera                               */
/*  Producto           :      Credito y Cartera                         */
/*  Disenado por       :      Johan F. Ardila R.                        */
/*  Fecha de escritura :      Feb 2011                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
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
/*                           PROPOSITO                                  */
/*  Crear una  operacion nueva hija por efecto de reestructuracion de   */
/*  operaciones. La operación hija se origina con los valores diferidos.*/
/*  basado en cofagint.sp                                               */
/*                        ACTUALIZACIONES                               */
/*  22/Feb/2011            Johan Ardila      Emision Inicial REQ 246    */
/*  24/Jun/2021       KDR               Nuevo parámetro sp_liquid       */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion y */
/*									  @w_op_calificacion				*/
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if object_id ('sp_creaop_fng') is not null
begin
   drop proc sp_creaop_fng
end
go

create proc sp_creaop_fng
   @s_sesn                 int         = null,
   @s_ssn                  int         = null,
   @s_user                 login       = null,
   @s_term                 varchar(30) = null,
   @s_date                 datetime    = null,
   @s_ofi                  smallint    = null,
   @i_fecha_proceso        datetime,
   @i_operacionca          int,
   @i_sec_reest            int         = 0,
   @i_toperacion           catalogo,
   @i_monto                money,
   @o_op_hija              int out,
   @o_secuencial_res       int out
as
declare
   @w_origen_fondos        catalogo,
   @w_cliente              int,
   @w_nombre_completo      descripcion,
   @w_sector               catalogo,
   @w_oficina_oper         smallint,
   @w_do_moneda            tinyint,
   @w_comentario           varchar(255),
   @w_oficial              smallint,
   @w_ciudad               int,
   @w_destino              catalogo,
   @w_op_banco             cuenta,
   @w_error                int,
   @w_fecha                datetime,
   @w_cot_moneda           money,
   @w_identificacion       numero,
   @w_sp_name              descripcion,
   @w_clase_cartera        catalogo,
   @w_ro_porcentaje_efa    float,
   @w_ts_porcentaje        float,
   @w_ts_porcentaje_efa    float,
   @w_ts_referencial       catalogo,
   @w_ts_signo             char(1),
   @w_ts_factor            float,
   @w_max_sec_tasa         int,
   @w_op_hija              int,
   @w_rubro_int            catalogo,
   @w_moneda_des           smallint,
   @w_monto_des            money,
   @w_dias_anio            int,
   @w_num_dec_tapl         tinyint,
   @w_tasa_efa             float,
   @w_base_calculo         char(1),
   @w_tasa_nominal         float,
   @w_op_estado            tinyint,
   @w_toperacion           catalogo,
   @w_abd_concepto         catalogo,
   @w_banca                catalogo,
   @w_dia_fijo             tinyint,
   @w_direccion            tinyint,
   @w_operacionca          int,
   @w_fecha_ult_proceso    datetime,
   @w_op_calificacion      catalogo,
   @w_op_gar_admisible     char(1),
   @w_secuencial           int,
   @w_calificacion         catalogo,
   @w_tramite              int,
   @w_tplazo               varchar(10), 
   @w_plazo                smallint,
   @w_fte_rec              catalogo
   
set ANSI_WARNINGS off

select 
   @w_moneda_des = 0,
   @w_sp_name    = 'sp_creaop_fng',
   @i_sec_reest  = isnull(@i_sec_reest, 0),
   @w_tramite    = 0
   
if isnull(@i_monto ,0) = 0 return 701194

/* PARAMETRO DE FORMA DE PAGO */
select @w_abd_concepto = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'DESREE'

if not exists (select * from cob_cartera..ca_producto where cp_producto = @w_abd_concepto and cp_estado = 'V') or @w_abd_concepto is null begin
   print 'No existe o no esta parametrizada Forma de Desembolso para Obligaciones Hija'
   return 710088
end

/* FUENTE DE RECURSO AUTONOMA */
select @w_fte_rec = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CRE'
   and pa_nemonico = 'FUPRA'

select @w_comentario = 'OPERACION HIJA POR VALORES DIFERIDOS' + '-' + @w_abd_concepto

/* HEREDAR INFORMACION DE LA OPERACION QUE VIENE */
select 
   @w_cliente            = op_cliente,
   @w_nombre_completo    = op_nombre,
   @w_sector             = op_sector,
   @w_oficina_oper       = op_oficina,
   @w_do_moneda          = op_moneda,
   @w_oficial            = op_oficial,
   @w_ciudad             = op_ciudad,
   @w_destino            = op_destino,
   @w_clase_cartera      = op_clase,
   @w_toperacion         = @i_toperacion,
   @w_banca              = op_banca,
   @w_dia_fijo           = op_dia_fijo,
   @w_calificacion       = op_calificacion
  from ca_operacion with(nolock)
 where op_operacion = @i_operacionca

select @w_banca = en_banca
  from cobis..cl_ente with(nolock)
 where en_ente = @w_cliente

/* SACAR SECUENCIALES SESIONES */
exec @s_ssn = sp_gen_sec 
   @i_operacion  = -1

exec @s_sesn = sp_gen_sec 
   @i_operacion  = -1

select @w_identificacion = cl_ced_ruc
  from cobis..cl_cliente with(nolock)
 where cl_cliente = @w_cliente
set transaction isolation level read uncommitted

select @w_direccion = min(di_direccion) 
  from cobis..cl_direccion with(nolock)
 where di_ente      = @w_cliente
   and di_vigencia  = 'S'
   and di_principal = 'S'
set transaction isolation level read uncommitted

/* CREACION DE LA OPERACION EN TEMPORALES */
exec @w_error = sp_crear_operacion_int
   @s_user                = @s_user,
   @s_sesn                = @s_sesn,
   @s_ofi                 = @s_ofi,
   @s_date                = @i_fecha_proceso,
   @s_term                = @s_term,
   @i_cliente             = @w_cliente,
   @i_nombre              = @w_nombre_completo,
   @i_sector              = @w_sector,
   @i_toperacion          = @w_toperacion,
   @i_oficina             = @w_oficina_oper,
   @i_moneda              = @w_do_moneda,
   @i_comentario          = @w_comentario,
   @i_oficial             = @w_oficial,
   @i_fecha_ini           = @i_fecha_proceso,
   @i_monto               = @i_monto,
   @i_monto_aprobado      = @i_monto,
   @i_destino             = @w_destino,
   @i_ciudad              = @w_ciudad,
   @i_formato_fecha       = 101,
   @i_periodo_crecimiento = 0,
   @i_tasa_crecimiento    = 0,
   @i_direccion           = @w_direccion,
   @i_clase_cartera       = @w_clase_cartera,
   @i_origen_fondos       = @w_origen_fondos,
   @i_dia_pago            = @w_dia_fijo, 
   @i_fecha_fija          = 'S',
   @i_fondos_propios      = 'N',
   @i_batch_dd            = 'N',
   @i_banca               = @w_banca,
   @i_salida              = 'N',
   @i_no_banco            = 'S',
   @o_banco               = @w_op_banco out

if @w_error <> 0 return @w_error

/* INGRESAR DEUDOR */
exec @w_error = sp_codeudor_tmp
   @s_sesn       = @s_sesn,
   @s_user       = @s_user,
   @i_borrar     = 'S',
   @i_secuencial = 1,
   @i_titular    = @w_cliente,
   @i_operacion  = 'A',
   @i_codeudor   = @w_cliente,
   @i_ced_ruc    = @w_identificacion,
   @i_rol        = 'D',
   @i_externo    = 'N',
   @i_banco      = @w_op_banco

if @w_error <> 0 return @w_error

exec @w_error = sp_operacion_def_int
   @s_date      = @i_fecha_proceso,
   @s_sesn      = @s_sesn,
   @s_user      = @s_user,
   @s_ofi       = @w_oficina_oper,
   @i_banco     = @w_op_banco,
   @i_claseoper = 'A'

if @w_error <> 0 return @w_error

select 
   @w_op_hija        = op_operacion,
   @w_dias_anio      = op_dias_anio,
   @w_base_calculo   = op_base_calculo,
   @w_op_estado      = op_estado,
   @w_tplazo         = op_tplazo,
   @w_plazo          = op_plazo
  from ca_operacion with(nolock)
 where op_banco = @w_op_banco

select @w_rubro_int = ro_concepto
  from ca_rubro_op with(nolock), ca_concepto with(nolock)
 where ro_operacion = @w_op_hija
   and ro_concepto  = co_concepto
   and co_categoria = 'I'
   
/* INGRESO DE DATOS EN TABLA RELACION OPERACION PADRE-HIJA */

update ca_op_reest_padre_hija with(rowlock)
set ph_op_hija   = @w_op_hija,
    ph_sec_reest = @i_sec_reest
where ph_op_padre = @i_operacionca

if @@rowcount = 0 begin
   insert into ca_op_reest_padre_hija( ph_op_padre,    ph_op_hija,    ph_sec_reest,  ph_fecha         )
                               values( @i_operacionca, @w_op_hija,    @i_sec_reest,  @i_fecha_proceso )
   if @@error <> 0 return 710001
end

/* DATOS DE LA TASA INT DE LA OPERACION REESTRUCTURADA */
select @w_max_sec_tasa = max(ts_secuencial)
  from ca_tasas with(nolock)
 where ts_operacion = @i_operacionca
   and ts_concepto  = @w_rubro_int

select 
   @w_ts_porcentaje     = ts_porcentaje,
   @w_ts_porcentaje_efa = ts_porcentaje_efa,
   @w_ts_referencial    = ts_referencial,
   @w_ts_signo          = ts_signo,
   @w_ts_factor         = ts_factor
  from ca_tasas with(nolock)
 where ts_operacion  = @i_operacionca
   and ts_concepto   = @w_rubro_int
   and ts_secuencial = @w_max_sec_tasa

update ca_tasas with(rowlock)
set
   ts_porcentaje     = @w_ts_porcentaje,
   ts_porcentaje_efa = @w_ts_porcentaje_efa,
   ts_referencial    = @w_ts_referencial,
   ts_signo          = @w_ts_signo,
   ts_factor         = @w_ts_factor
 where ts_operacion = @w_op_hija
   and ts_concepto  = @w_rubro_int

if @@error <> 0 return 705068

/* VALORES RUBROS OP A REESTRUCTURAR */
select @w_ro_porcentaje_efa = ro_porcentaje_efa
  from ca_rubro_op with(nolock)
 where ro_operacion = @i_operacionca
   and ro_concepto  = @w_rubro_int

select @w_num_dec_tapl = ro_num_dec
  from ca_rubro_op with(nolock)
 where ro_operacion  = @w_op_hija
   and ro_tipo_rubro = 'M'

exec @w_error = sp_conversion_tasas_int
   @i_dias_anio     = @w_dias_anio,
   @i_base_calculo  = @w_base_calculo,
   @i_periodo_o     = 'A',
   @i_modalidad_o   = 'V',
   @i_num_periodo_o = 1,
   @i_tasa_o        = @w_ro_porcentaje_efa,
   @i_periodo_d     = 'D',
   @i_modalidad_d   = 'V',
   @i_num_periodo_d = 1,
   @i_num_dec       = @w_num_dec_tapl,
   @o_tasa_d        = @w_tasa_nominal out

if @w_error <> 0 return @w_error

select @w_fecha = fc_fecha_cierre
  from cobis..ba_fecha_cierre
 where fc_producto = 7 

exec @w_error = sp_buscar_cotizacion
   @i_moneda     = @w_do_moneda,
   @i_fecha      = @w_fecha,
   @o_cotizacion = @w_cot_moneda out

if @w_error <> 0 return @w_error

select @w_monto_des = @i_monto

if @w_moneda_des <> @w_do_moneda
begin
   select @w_monto_des = ceiling(@i_monto * @w_cot_moneda)
end

/* ELIMINAR COMISIONES DE DESEMBOLSO */
delete ca_rubro_op_tmp
 where rot_operacion = @w_op_hija
   and rot_fpago     = 'L'

if @@error <> 0 return 707019

delete ca_rubro_op  
 where ro_operacion = @w_op_hija
   and ro_fpago     = 'L'

if @@error <> 0 return 707032

-- Crear tramite
exec @w_error = cob_credito..sp_tramite_cca
   @s_ssn               = @s_ssn,
   @s_user              = @s_user,
   @s_sesn              = @s_sesn,
   @s_term              = @s_term,
   @s_date              = @s_date,
   @s_ofi               = @s_ofi,
   @i_oficina_tr        = @w_oficina_oper,
   @i_fecha_crea        = @i_fecha_proceso,  -- la misma de creacion de la OP
   @i_oficial           = @w_oficial,
   @i_sector            = @w_sector,
   @i_banco             = @w_op_banco,
   @i_toperacion        = @w_toperacion,
   @i_producto          = 'CCA',
   @i_monto             = @i_monto,
   @i_moneda            = @w_do_moneda,                                       
   @i_periodo           = @w_tplazo,
   @i_num_periodos      = @w_plazo,
   @i_destino           = @w_destino,
   @i_ciudad_destino    = @w_ciudad,
   @i_clase             = @w_clase_cartera , 
   @i_cliente           = @w_cliente,
   @i_tipo              =  'O',
   @o_tramite           = @w_tramite out

   if @w_error <> 0 return @w_error

   if @w_tramite = 0  begin
     PRINT 'creaopfng.sp error al ejecutar cob_credito..cp_tramite_cca @w_tramite ' + cast(@w_tramite as varchar)
     return 710005 --cambiar este numero
   end
   else begin
     update cob_credito..cr_tramite
     set tr_fuente_recurso = @w_fte_rec
     where tr_tramite = @w_tramite

     update cob_cartera..ca_operacion_tmp
     set opt_origen_fondos = @w_fte_rec
     where opt_operacion = @w_op_hija
   end

exec @w_error = sp_desembolso
   @s_ofi            = @s_ofi,
   @s_term           = @s_term,
   @s_user           = @s_user,
   @s_date           = @s_date,
   @i_producto       = @w_abd_concepto,  --La misma forma de pago según parametro general
   @i_cuenta         = 'AUTOMATICO', 
   @i_beneficiario   = @w_nombre_completo,
   @i_oficina_chg    = @s_ofi,
   @i_banco_ficticio = @w_op_banco,
   @i_banco_real     = @w_op_banco,
   @i_monto_ds       = @w_monto_des,
   @i_tcotiz_ds      = 'N',
   @i_cotiz_ds       = 1.0,
   @i_tcotiz_op      = 'N',
   @i_cotiz_op       = @w_cot_moneda,
   @i_moneda_op      = @w_do_moneda,
   @i_moneda_ds      = @w_moneda_des,
   @i_operacion      = 'I',
   @i_externo        = 'N'

if @w_error <> 0 return @w_error

exec @w_error = sp_liquida
   @s_ssn            = @s_ssn,
   @s_sesn           = @s_sesn,
   @s_user           = @s_user,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @s_rol            = 1,
   @s_term           = @s_term,
   @i_banco_ficticio = @w_op_banco,
   @i_banco_real     = @w_op_banco,
   @i_afecta_credito = 'N',
   @i_fecha_liq      = @i_fecha_proceso,
   @i_tramite_batc   = 'N',
   @i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
   @i_externo        = 'N'

if @w_error <> 0 return @w_error

/* Nuevo banco de Operacion Hija */

select @w_op_banco = opt_banco
from ca_operacion_tmp
where opt_operacion = @w_op_hija

/* BORRAR TEMPORALES */
exec @w_error = sp_borrar_tmp
   @i_banco = @w_op_banco,
   @s_user  = @s_user

if @w_error <> 0 return @w_error

-- Transaccion de Reestructuracion

select 
@w_operacionca          = op_operacion,
@w_moneda_des           = op_moneda,
@w_oficina_oper         = op_oficina,
@w_fecha_ult_proceso    = op_fecha_ult_proceso,
@w_oficial              = op_oficial,
@w_op_calificacion      = isnull(op_calificacion, 'A'),
@w_op_gar_admisible     = isnull(op_gar_admisible, 'O'),
@w_op_estado            = op_estado
from  ca_operacion with(nolock)
where op_operacion = @w_op_hija

-- Marcar como No Contabiliza el Desmebolso

update ca_transaccion with(rowlock)
set tr_estado = 'ING'
where tr_operacion = @w_op_hija
and   tr_tran      = 'DES'

-- Obtener Secuencial
exec @w_secuencial = sp_gen_sec
@i_operacion       = @w_operacionca

select @o_op_hija        = @w_op_hija,
       @o_secuencial_res = @w_secuencial

-- Obtener respaldo
exec @w_error = sp_historial
@i_operacionca = @w_operacionca,
@i_secuencial  = @w_secuencial

if @w_error != 0 return @w_error

-- TRANSACCION CONTABLE 
insert into ca_transaccion (
tr_secuencial,      tr_fecha_mov,         tr_toperacion,
tr_moneda,          tr_operacion,         tr_tran,
tr_en_linea,        tr_banco,             tr_dias_calc,
tr_ofi_oper,        tr_ofi_usu,           tr_usuario,
tr_terminal,        tr_fecha_ref,         tr_secuencial_ref,
tr_estado,          tr_gerente,           tr_calificacion,
tr_gar_admisible,   tr_observacion,       tr_comprobante,
tr_fecha_cont,      tr_reestructuracion)
values (
@w_secuencial,      @s_date,              @i_toperacion,
@w_moneda_des,      @w_operacionca,       'RES',
'S',                @w_op_banco,          0,
@w_oficina_oper,    @s_ofi,               @s_user,
@s_term,            @w_fecha_ult_proceso, 0,
'ING',              @w_oficial,           @w_op_calificacion,
@w_op_gar_admisible,'REESTRUCTURACION AUTOMATICA POR GENERARSE DESDE OPERACION PADRE',   0,
'',                 '')

if @@error != 0 begin
   print 'Error en Ingreso de transaccion de Reestructuracion operacion Hija'
   select @w_error = 708165
   return @w_error
end

update ca_operacion with(rowlock)
set op_numero_reest = op_numero_reest + 1,
    op_calificacion = @w_calificacion,
    op_tramite      = @w_tramite
where op_operacion  = @w_operacionca

if @@error <> 0 return 705076

return 0
go
