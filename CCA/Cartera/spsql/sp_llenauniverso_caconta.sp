use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_llenauniverso_caconta')
   drop proc sp_llenauniverso_caconta
go

create procedure sp_llenauniverso_caconta
/*************************************************************************/
/*   NOMBRE LOGICO:      sp_llenauniverso_caconta.sp                     */
/*   NOMBRE FISICO:      sp_llenauniverso_caconta                        */
/*   BASE DE DATOS:      cob_cartera                                     */
/*   PRODUCTO:           Cartera                                         */
/*   DISENADO POR:       Sandro Vallejo                                  */
/*   FECHA DE ESCRITURA: Ago 2020                                        */
/*************************************************************************/
/*                     IMPORTANTE                                        */
/*   Este programa es parte de los paquetes bancarios que son            */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,       */
/*   representantes exclusivos para comercializar los productos y        */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida      */
/*   y regida por las Leyes de la República de España y las              */
/*   correspondientes de la Unión Europea. Su copia, reproducción,       */
/*   alteración en cualquier sentido, ingeniería reversa,                */
/*   almacenamiento o cualquier uso no autorizado por cualquiera         */
/*   de los usuarios o personas que hayan accedido al presente           */
/*   sitio, queda expresamente prohibido; sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de       */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto       */
/*   en el presente texto, causará violaciones relacionadas con la       */
/*   propiedad intelectual y la confidencialidad de la información       */
/*   tratada; y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.”.              */
/*************************************************************************/
/*                              PROPOSITO                                */
/*      Llena la tabla de operaciones con las operaciones que tienen     */
/*      registros de transacciones pendientes de contabilizar            */
/*************************************************************************/
/*                              MODIFICACIONES                           */
/*************************************************************************/
/*   01/Dec/2020  P.Narvaez    Tomar la fecha de cierre de Cartera       */
/*  22/01/21          P.Narvaez        optimizado para mysql             */
/*  16/07/21          G.Fernandez      Estandarizacion de parametros     */
/*  25/03/22          G.Fernandez      Incluir numero de operaciones     */
/*                                     negativas para rubros diferidos,  */
/*                                     incluir concepto en campo agrupado*/
/*  10/06/22          G.Fernandez      Actualizacion de comprobantes de  */
/*                                     inicio de cada año                */
/*  15/06/22          G.Fernandez      Validación de transacciones para  */
/*                                     contabilizar                      */
/*  16/06/22          G.Fernandez    Se ingresa print de control en debug*/
/*  22/06/22          G.Fernandez    Al cargar las transacciones elimina */
/*                                   filtro de operaciones positivas     */
/*  23/07/22          G.Fernandez    Corrección de sentencia de unión    */
/*  17/04/23          G.Fernandez    S807925 Ingreso de nuevo campo de   */
/*                                      reestructuracion                 */
/*  28/04/2023        G. Fernandez   B816885 Ingreso de nuevos campos    */
/*                                   para obtener claves de PRV	         */
/*  28/11/2023        K. Rodriguez   R220410 Ajuste Oficina de operación */
/*************************************************************************/
        @i_param1        char(1)       = 'N' -- debug
as

declare @w_sp_name       descripcion,
        @w_error         int,
        @w_dias_antes    int,      
        @w_fecha_antes   datetime, 
        @w_comprobante   int,
        @w_estado_prod   char(1),
        @w_cod_producto  tinyint,
        @w_fecha_hasta   datetime,
        @w_fecha_mov     datetime,
        @w_bancamia      varchar(24),
        @w_mensaje       varchar(255),
		@w_minuto        int,
		@w_segundo       int,
		@w_milisegundo   int,
	  --Variables para parametros batch	
		@i_debug         char(1)

--GFP 16/07/2021 paso de parametros de batch a variables locales
select
       @i_debug     =  @i_param1

select @w_sp_name      = 'sp_llenauniverso_caconta',
       @w_error        = 0,
       @w_comprobante  = 0,
       @w_cod_producto = 7

if @i_debug = 'S'
BEGIN
   select @w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
   print 'HORA1 : ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
end

-- DETERMINAR EL ESTADO DE ADMISION DE COMPROBANTES CONTABLES EN COBIS CONTABILIDAD 
select @w_estado_prod = pr_estado
from   cob_conta..cb_producto with (nolock)
where  pr_empresa  = 1
and    pr_producto = @w_cod_producto

-- VALIDA EL PRODUCTO EN CONTABILIDAD 
if @w_estado_prod not in ('V','E') 
begin
   select 
   @w_error   = 601018,
   @w_mensaje = ' PRODUCTO NO VIGENTE EN CONTA ' 
   goto ERRORFIN
end

-- DETERMINAR EL RANGO DE FECHAS DE LAS TRANSACCIONES QUE SE INTENTARAN CONTABILIZAR 
/*Solo se contabiliza las transacciones hasta la fecha de cierre de cartera, ya que pueden
haber transacciones con fecha de mañana o siguiente dia habil por el nuevo esquema de 
inicio de dia de causaciones de intereses*/

select @w_fecha_hasta = isnull(fc_fecha_cierre,'01/01/1900')
from   cobis..ba_fecha_cierre with (nolock)
where fc_producto = 7   

select @w_fecha_mov   = isnull(min(co_fecha_ini),'01/01/1900')
from   cob_conta..cb_corte with (nolock)
where  co_empresa = 1
and    co_estado in ('A','V')
and co_fecha_ini <= @w_fecha_hasta

if @w_fecha_mov = '01/01/1900' 
begin
   select 
   @w_error   = 601078,
   @w_mensaje = ' ERROR NO EXISTEN PERIODOS DE CORTE ABIERTOS ' 
   goto ERRORFIN
end

if @i_debug = 'S' 
begin
   print '--> sp_llenauniverso_caconta. Fecha Conta ' + cast(@w_fecha_mov as varchar)
   print '--> sp_llenauniverso_caconta. Fecha Hasta ' + cast(@w_fecha_hasta as varchar)
end

-- DETERMINAR CODIGO DE BANCAMIA PARA EMPLEADOS
select @w_bancamia  = convert(varchar(24),pa_int)
from   cobis..cl_parametro
where  pa_nemonico = 'CCBA'
and    pa_producto = 'CTE'

-- INICIALIZA TABLA DE TRANSACCIONES CONTABLES 
truncate table ca_conta_trn_tmp       

if @i_debug = 'S'
BEGIN
   select @w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
   print 'HORA2 : ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
end

-- CARGAR TRANSACCIONES A CONTABILIZAR
insert into ca_conta_trn_tmp    
select ct_operacion        = tr_operacion,
       ct_secuencial       = tr_secuencial,     
       ct_banco            = tr_banco, 
       ct_agrupado         = isnull(rtrim(tr_tran), '') + '-' + isnull(rtrim(tr_banco), '') + '-' + isnull(rtrim(convert(varchar,tr_secuencial)),''),
       ct_tran             = convert(varchar(10), tr_tran),
       ct_ofi_usu          = tr_ofi_usu,     
       ct_ofi_oper         = op_oficina,   --tr_ofi_oper KDR Se toma ofi actual del préstamo (la trn podría tener una oficina distinta si el préstamo tubo un traslado de oficina)
       ct_toperacion       = convert(varchar(10), tr_toperacion),     
       ct_fecha_mov        = tr_fecha_mov,
       ct_fecha_ref        = tr_fecha_ref,
       ct_perfil           = to_perfil,
       ct_sector           = convert(varchar(10), op_sector),
       ct_moneda           = tr_moneda,
       ct_gar_admisible    = case when isnull(op_gar_admisible,'N') = 'S' then 'I' else 'O' end,
       ct_calificacion     = isnull(ltrim(rtrim(op_calificacion)), 'A'),
       ct_clase            = op_clase,
       ct_cliente          = op_cliente,
       ct_tramite          = op_tramite,
       ct_categoria        = dt_categoria,
       ct_entidad_convenio = case when dt_entidad_convenio = @w_bancamia then '1' else '0' end,
       ct_subtipo_linea    = op_subtipo_linea,
       ct_concepto         = '',
       ct_codvalor         = 0,
       ct_monto            = 0,
       ct_monto_mn         = 0,
       ct_cotizacion       = 0,
	   ct_reestructuracion = tr_reestructuracion,
	   ct_categoria_plazo  = oda_categoria_plazo
from   ca_operacion, ca_default_toperacion, ca_tipo_trn,ca_operacion_datos_adicionales, ca_transaccion T LEFT JOIN ca_trn_oper O ON T.tr_toperacion = O.to_toperacion AND T. tr_tran = to_tipo_trn
where  op_operacion   = tr_operacion
and    tr_tran        > ''
and    tr_estado      = 'ING'
and    tr_fecha_mov  <= @w_fecha_hasta
and    tr_fecha_mov  >= @w_fecha_mov
and    tr_ofi_usu    >= 1
and    tr_tran   not in ('PRV','REJ','MIG','HFM','VEN') --LPO TEC Se exluye transaccion VEN
and    tr_operacion   = op_operacion
and    op_toperacion  = dt_toperacion
and    op_moneda      = dt_moneda
and    tr_tran        = tt_codigo  --GFP Se ingresa por validacion transaccion contabilizable si o no
and    tt_contable    = 'S'
and    op_operacion   = oda_operacion
union all
select ct_operacion        = case when tp_operacion < 0 then tp_operacion * -1 else tp_operacion end, --GFP 25/03/22
       ct_secuencial       = tp_secuencial_ref,    
       ct_banco            = op_banco, 
       ct_agrupado         = 'PRV-' + rtrim(op_toperacion)+ '-' + isnull(rtrim(convert(varchar,tp_concepto)),'') + '-Md' + convert(varchar,op_moneda) + '-Of' + convert(varchar,op_oficina) +
                             '-Sec' + convert(varchar,op_sector) + '-Fec' + rtrim(convert(varchar, tp_fecha_mov,101))+'-Reest' + convert(varchar,tp_reestructuracion) , ----GFP 25/03/22
       ct_tran             = 'PRV',
       ct_ofi_usu          = op_oficina, -- tp_ofi_oper,
       ct_ofi_oper         = op_oficina, -- tp_ofi_oper, KDR Se toma ofi actual del préstamo (la trn podría tener una oficina distinta si el préstamo tubo un traslado de oficina)      
       ct_toperacion       = convert(varchar(10), op_toperacion),     
       ct_fecha_mov        = tp_fecha_mov,
       ct_fecha_ref        = tp_fecha_ref,
       ct_perfil           = to_perfil,
       ct_sector           = convert(varchar(10), op_sector),
       ct_moneda           = op_moneda,
       ct_gar_admisible    = case when isnull(op_gar_admisible,'N') = 'S' then 'I' else 'O' end,
       ct_calificacion     = isnull(ltrim(rtrim(op_calificacion)), 'A'),
       ct_clase            = op_clase,
       ct_cliente          = op_cliente,
       ct_tramite          = op_tramite,
       ct_categoria        = dt_categoria,
       ct_entidad_convenio = case when dt_entidad_convenio = @w_bancamia then '1' else '0' end,
       ct_subtipo_linea    = op_subtipo_linea,
       ct_concepto         = tp_concepto,
       ct_codvalor         = tp_codvalor,
       ct_monto            = tp_monto,
       ct_monto_mn         = tp_monto_mn,
       ct_cotizacion       = tp_cotizacion,
	   ct_reestructuracion = tp_reestructuracion,
	   ct_categoria_plazo  = oda_categoria_plazo
from   ca_transaccion_prv, ca_default_toperacion, ca_operacion_datos_adicionales, ca_operacion O LEFT JOIN ca_trn_oper T ON O.op_toperacion = T.to_toperacion AND T.to_tipo_trn = 'PRV'
where  (tp_operacion   = op_operacion OR tp_operacion * -1  = op_operacion ) --GFP 25/03/22
and    tp_estado      = 'ING'
and    tp_fecha_mov  <= @w_fecha_hasta
and    tp_fecha_mov  >= @w_fecha_mov
and    op_toperacion  = dt_toperacion
and    op_moneda      = dt_moneda
and    op_operacion   = oda_operacion

if @i_debug = 'S'
BEGIN
   select @w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
   print 'HORA3 : ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
end

update statistics ca_conta_trn_tmp

if @i_debug = 'S'
BEGIN
   select @w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
   print 'HORA4 : ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
end

--Inicializa tabla de universo a procesar
truncate table ca_universo_conta

--Carga universo de operaciones con operaciones con transacciones a contabilizar
insert into ca_universo_conta (agrupado, intentos, hilo, comprobante)
select distinct ct_agrupado,
       0,
       0,
       0
from   ca_conta_trn_tmp 

if @i_debug = 'S'
BEGIN
   select @w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
   print 'HORA5 : ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
end

update statistics ca_universo_conta

-- Obtener datos de comprobante 
exec @w_error = cob_conta..sp_cseqcomp
@i_tabla      = 'cb_scomprobante', 
@i_empresa    = 1,
@i_fecha      = @w_fecha_hasta,
@i_modulo     = 7, 
@i_modo       = 0, -- Numera por EMPRESA-FECHA-PRODUCTO
@o_siguiente  = @w_comprobante out      
 
if @w_error <> 0 
begin
   select 
   @w_mensaje = ' ERROR AL GENERAR NUMERO COMPROBANTE ' 
   goto ERRORFIN
end

if @i_debug = 'S'
BEGIN
   select @w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
   print 'HORA6 : ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
end

-- Actualizar numero de comprobante
update ca_universo_conta 
set    comprobante = @w_comprobante + id
where id >= 0

if @i_debug = 'S'
BEGIN
   select @w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
   print 'HORA7 : ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
end

select @w_comprobante = max(comprobante)
from   ca_universo_conta

--Actualizar el secuencial de comprobantes del dia por si se reprocesa
update cob_conta..cb_seqnos_comprobante with (rowlock)
set    sc_actual = @w_comprobante
where  sc_empresa = 1
and    sc_fecha   = DATEADD(yy, DATEDIFF(yy, 0, @w_fecha_hasta), 0) --GFP 10/06/22 
and    sc_tabla   = 'cb_scomprobante'
and    sc_modulo  = 7

if @i_debug = 'S'
BEGIN
   select @w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
   print 'HORA8 : ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
end

return 0

ERRORFIN:
exec sp_errorlog
@i_fecha       = @w_fecha_hasta, 
@i_error       = @w_error, 
@i_usuario     = 'consola',
@i_tran        = 7000, 
@i_tran_name   = @w_sp_name, 
@i_rollback    = 'N',
@i_cuenta      = 'CONTABILIDAD', 
@i_descripcion = @w_mensaje

return @w_error

go


