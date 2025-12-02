/************************************************************************/
/*      Nombre Logico:			sp_cartera_abono_dd						*/
/*		Nombre Fisico:			abonocadd.sp							*/
/* 		Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     Febrero 2005                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*	 Este programa es parte de los paquetes bancarios que son       	*/
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
/*                              PROPOSITO                               */
/*      Aplica el abono. Este procedimiento solo puede aplicarse en     */
/*      registros que ya hayan generado registro de pago (RPA)en op     */
/*     de dd                                                            */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/*   23/abr/2010     Fdo Carvajal INTERFAZ AHORROS                      */
/*    20/10/2021       G. Fernandez      Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*    07/11/2023     Kevin Rodriguez  Actualiza valor despreciab        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cartera_abono_dd')
   drop proc sp_cartera_abono_dd
go



create proc sp_cartera_abono_dd
   @s_sesn           int          = NULL,
   @s_user           login        = NULL,
   @s_term           varchar (30) = NULL,
   @s_date           datetime     = NULL,
   @s_ofi            smallint     = NULL,
   @s_ssn            int          = null,
   @s_srv            varchar (30) = '',
   @s_lsrv           varchar (30) = null,
   @i_secuencial_ing int,
   @i_operacionca    int,
   @i_fecha_proceso  datetime,
   @i_en_linea       char(1)      = 'S',
   @i_cotizacion     float        = 1,
   @i_no_cheque      int          = null
as

declare
   @w_error                 int,
   @w_num_dec_op            int,
   @w_banco                 cuenta,
   @w_monto_mop             money,
   @w_moneda_op             smallint,
   @w_moneda_mn             smallint,
   @w_oficina_op            int,
   @w_est_vigente           tinyint,
   @w_est_cancelado         tinyint,
   @w_toperacion            catalogo,
   @w_secuencial_pag        int,
   @w_secuencial_rpa        int,
   @w_cotizacion            money,
   @w_tcotizacion           char(1),
   @w_monto_sobrante        float,
   @w_fpago                 catalogo,
   @w_cuenta                cuenta,
   @w_cliente               int,
   @w_moneda_ab             int,
   @w_tramite               int,
   @w_fecha_proceso         datetime,
   @w_gerente               smallint,
   @w_estado_div            smallint,
   @w_monto_devolucion      money,
   @w_monto_devolucion_mn   money,
   @w_beneficiario          varchar(30),
   @w_parametro_col         catalogo,
   @w_colchon               char(1),
   @w_colchon_neto          money,
   @w_colchon_bruto         money,
   @w_colchon_devolver      money,
   @w_moneda_local          smallint,
   @w_moneda_pago           smallint,
   @w_concepto_cxp          catalogo,
   @w_re_area               int,
   @w_grupo                 int,
   @w_num_negocio           varchar(64),
   @w_num_doc               varchar(16),
   @w_proveedor             int,
   @w_cotizacion_mop        money,
   @w_lin_credito           cuenta,
   @w_opcion                char(1),
   @w_prod_cobis            int,
   @w_gar_admisible         char(1),
   @w_reestructuracion      char(1),
   @w_calificacion          catalogo,
   @w_num_dec_n             smallint,
   @w_moneda_pag            smallint,
   @w_abd_monto_mn          money,
   @w_abd_monto_mpg         money,
   @w_abd_cotizacion_mpg    money,
   @w_cot_moneda            money,
   @w_abd_cuenta            cuenta,
   @w_rubro_cap             catalogo,
   @w_area                     int,
   @w_param_sobaut             char(24),
   @w_referencia_sidac         varchar(50),
   @w_descripcion              varchar(50),
   @w_operacion_sidac          varchar(15),
   @w_sec_sidac                varchar(15),
   @w_dividendo                int,
   @w_nro_factura              char(16),
   @w_operacionca              int,
   @w_producto                 int,
   @w_monto_gar                money,
   @w_monto_gar_mn             money,
   @w_abd_cheque               int,
   @w_tipo_cobro               char(1),
   @w_vlr_despreciable         float,
   @w_tipo_cobro_con           catalogo,
   @w_monto_condonado          money,
   @w_cancelar_div             char(1),
   @w_prox_vigente             smallint,
   @w_total_div                float,
   @w_ultimo_cancelado         int,
   @w_tipo                     char(1),
   @w_col_bruto                money,
   @w_col_neto                 money,
   @w_dev_colchon              catalogo,
   @w_col_mora                 money,
   @w_rowcount                 int


-- CARGADO DE LOS PARAMETROS DE CARTERA
select @s_term        =  isnull(@s_term,'consola'),
@w_colchon            ='N',
@w_colchon_devolver   = 0,
@w_monto_condonado    = 0,
@w_vlr_despreciable   = 0

--VALIDACION DE LA EXISTENCIA DEL sECUENCIAL @s_ssn

if @s_ssn is null
begin
   ---SECUENCIAL PARA SIDAC
   exec @s_ssn    = sp_gen_sec
   @i_operacion   = @i_operacionca
end

-- ESTADOS DE CARTERA
select @w_est_vigente = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'VIGENTE'

select @w_est_cancelado = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'CANCELADO'

    
-- CODIGO DEL RUBRO CAPITAL
select @w_rubro_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
   return 710076

--  DATOS DEL ABONO
select @w_tipo_cobro     = ab_tipo_cobro,
@w_secuencial_rpa        = ab_secuencial_rpa,
@w_operacionca           = ab_operacion,
@w_dividendo             = ab_dividendo
from   ca_abono
where  ab_operacion      = @i_operacionca
and    ab_secuencial_ing = @i_secuencial_ing
and    ab_secuencial_rpa is not null

if @@rowcount = 0 
   return 701119


-- DATOS DE CA_OPERACION
select @w_banco     = op_banco,
@w_toperacion       = op_toperacion,
@w_moneda_op        = op_moneda,
@w_oficina_op       = op_oficina,
@w_cliente          = op_cliente,
@w_tramite          = op_tramite,
@w_fecha_proceso    = op_fecha_ult_proceso,
@w_gerente          = op_oficial,
@w_lin_credito      = op_lin_credito,
@w_gar_admisible    = op_gar_admisible,
@w_reestructuracion = op_reestructuracion,
@w_calificacion     = op_calificacion,
@w_tipo             = op_tipo
from   ca_operacion
where  op_operacion = @w_operacionca

if @@rowcount = 0 
   return 701025


-- LECTURA DE DECIMALES
exec @w_error   = sp_decimales
@i_moneda       = @w_moneda_op,
@o_decimales    = @w_num_dec_op out,
@o_mon_nacional = @w_moneda_mn  out,
@o_dec_nacional = @w_num_dec_n  out

if @w_error != 0 
   return  @w_error


select @w_vlr_despreciable = 1.0 / power(10,  isnull((@w_num_dec_op + 2), 4))

   
--CODIGO DEL CONCEPTO
select @w_parametro_col = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COL'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
   return 710314


--CONSULTA CODIGO DE MONEDA LOCAL
SELECT @w_moneda_local = pa_tinyint
FROM   cobis..cl_parametro
WHERE  pa_nemonico = 'MLO'
AND    pa_producto = 'ADM'
set transaction isolation level read uncommitted

--CODIGO DEL PRODUCTO
select @w_producto = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted


exec @w_secuencial_pag = sp_gen_sec
@i_operacion           = @w_operacionca

-- OBTENER RESPALDO ANTES DE LA APLICACION DEL PAGO
exec @w_error   = sp_historial
@i_operacionca  = @w_operacionca,
@i_secuencial   = @w_secuencial_pag

if @w_error != 0
   return @w_error


--SACAR EL Nro de la factura
-- CALCULAR EL MONTO DEL PAGO
select @w_nro_factura = ltrim(rtrim(abd_beneficiario)),
@w_abd_cheque         = abd_cheque
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing 
and    abd_operacion      = @w_operacionca
and    abd_tipo = 'PAG'

---VALOR DEL PAGO
select @w_monto_mop = isnull(sum(abd_monto_mop), 0)
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing 
and    abd_operacion      = @w_operacionca
and    abd_tipo in ('PAG','DEV', 'CON')

if isnull(@w_monto_mop,0) <= 0  
begin
   return 710129 
end

-- EPB07FEB2004 CALCULAR EL MONTO DEL PAGO CONDoNADO
select @w_monto_condonado = isnull(sum(abd_monto_mop), 0)
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing 
and    abd_operacion      = @w_operacionca
and    abd_tipo  = 'CON'
-- EPB07FEB2004 CALCULAR EL MONTO DEL PAGO CONDoNADO

-- SELECCIONAR LA COTIZACION Y EL TIPO DE COTIZACION
select @w_cotizacion  = abd_cotizacion_mop,
@w_tcotizacion = abd_tcotizacion_mop,
@w_moneda_ab   = abd_moneda,
@w_fpago       = abd_concepto
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @w_operacionca
and    abd_tipo           = 'PAG'

if @@rowcount = 0 
   return 710035 
 

-- INSERCION DE CABECERA CONTABLE DE CARTERA
insert into ca_transaccion
(tr_fecha_mov,        tr_toperacion,     tr_moneda,
tr_operacion,         tr_tran,           tr_secuencial,
tr_en_linea,          tr_banco,          tr_dias_calc,
tr_ofi_oper,          tr_ofi_usu,        tr_usuario,
tr_terminal,          tr_fecha_ref,      tr_secuencial_ref,
tr_estado,            tr_gerente,        tr_gar_admisible,
tr_reestructuracion,  tr_calificacion,   tr_observacion,
tr_fecha_cont,        tr_comprobante)
values(@s_date,             @w_toperacion,     @w_moneda_op,
@w_operacionca,      'PAG',             @w_secuencial_pag,
@i_en_linea,         @w_banco,          0,
@w_oficina_op,       @s_ofi,            @s_user,
@s_term,             @w_fecha_proceso,  @w_secuencial_rpa,
'ING',               @w_gerente,        isnull(@w_gar_admisible,''),
isnull(@w_reestructuracion,''),isnull(@w_calificacion,''),'',
@s_date,             0)

if @@error != 0
   return 708165 

-- INSERCION DE CUENTA PUENTE PARA LA APLICACION DEL PAGO
if @w_monto_mop > 0 
begin
   insert into ca_det_trn
   (dtr_secuencial,        dtr_operacion,  dtr_dividendo,
   dtr_concepto,           dtr_estado,     dtr_periodo,
   dtr_codvalor,           dtr_monto,      dtr_monto_mn,
   dtr_moneda,             dtr_cotizacion, dtr_tcotizacion,
   dtr_afectacion,         dtr_cuenta,     dtr_beneficiario,
   dtr_monto_cont)
   select 
   @w_secuencial_pag,      @w_operacionca, dtr_dividendo,
   dtr_concepto,           dtr_estado,     dtr_periodo,
   isnull(dtr_codvalor,0), dtr_monto,      dtr_monto_mn,
   dtr_moneda,             dtr_cotizacion, dtr_tcotizacion,
   'D',                    dtr_cuenta,     dtr_beneficiario,
   dtr_monto_cont
   from   ca_det_trn
   where  dtr_secuencial = @w_secuencial_rpa
   and    dtr_operacion  = @w_operacionca
   and    dtr_concepto like 'VAC_%'
   
   if @@error != 0
      return 710036 
   
   -- INSERTAR EL REGISTRO DE LAS FORMAS DE PAGO PARA ca_abono_rubro
   insert into ca_abono_rubro
   (ar_fecha_pag,   ar_secuencial,     ar_operacion,
   ar_dividendo,    ar_concepto,       ar_estado,
   ar_monto,        ar_monto_mn,       ar_moneda,
   ar_cotizacion,   ar_afectacion,     ar_tasa_pago,
   ar_dias_pagados)
   select
   @s_date,         @w_secuencial_pag, @w_operacionca,
   dtr_dividendo,   @w_fpago,          dtr_estado,
   dtr_monto,       dtr_monto_mn,      dtr_moneda,
   dtr_cotizacion,  'D',               0,
   0
   from   ca_det_trn
   where  dtr_secuencial = @w_secuencial_rpa    ---FORMA DE PAGO DEL CLIENTE
   and    dtr_operacion  = @w_operacionca
   and    dtr_afectacion = 'D'
   
   if @@error != 0 
      return 710404
end 


-- APLICACION DE CONDONACIONES
if exists (select 1
           from   ca_abono_det
           where  abd_operacion = @w_operacionca
           and    abd_secuencial_ing = @i_secuencial_ing
           and    abd_tipo = 'CON')
begin
   if @w_tipo_cobro_con <> 'A'
      and exists (select 1
                  from   ca_abono_det
                  where  abd_operacion = @w_operacionca
                  and    abd_secuencial_ing = @i_secuencial_ing
                  and    abd_tipo = 'CON'
                  and    abd_concepto  in ('INT','INTANT'))
      return 710513
   
   exec @w_error     = sp_abono_condonaciones
   @s_ofi            = @s_ofi,
   @s_sesn           = @s_sesn,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @i_secuencial_ing = @i_secuencial_ing,
   @i_secuencial_pag = @w_secuencial_pag,
   @i_fecha_pago     = @i_fecha_proceso,
   @i_div_vigente    = @w_dividendo,
   @i_en_linea       = @i_en_linea,
   @i_tipo_cobro     = @w_tipo_cobro_con,
   @i_dividendo      = @w_dividendo,
   @i_en_gracia_int  = 'N',
   @i_operacionca    = @w_operacionca

   if @w_error != 0
      return @w_error
end

-- APLICACION DE PAGCUBIERTOS CON COLCHON PARA DD
if exists (select 1
           from   ca_rubro_op 
           where  ro_operacion = @w_operacionca
           and    ro_concepto  = @w_parametro_col )
begin
   select @w_colchon = 'S'
   
   exec 
   @w_error          = sp_abono_rubros_colchon
   @s_ofi            = @s_ofi,
   @s_sesn           = @s_sesn,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @i_secuencial_ing = @i_secuencial_ing,
   @i_secuencial_pag = @w_secuencial_pag,
   @i_fecha_pago     = @i_fecha_proceso,
   @i_div_vigente    = @w_dividendo,
   @i_operacionca    = @w_operacionca,
   @i_en_linea       = @i_en_linea,
   @i_tipo_cobro     = @w_tipo_cobro,
   @i_dividendo      = @w_dividendo,
   @i_operacionca    = @w_operacionca
   
   if @w_error != 0
      return @w_error
end -- EXISTE COLCHON


-- MARCAR COMO APLICADO EL ABONO
update ca_abono
set    ab_estado         = 'A',
       ab_secuencial_pag = @w_secuencial_pag
where  ab_secuencial_ing = @i_secuencial_ing
and    ab_operacion      = @w_operacionca

if @@error != 0 
   return 705048

--APLICAICON DEL PAGO

   exec @w_error           = sp_abona_rubro_dd
   @s_ofi                  = @s_ofi,
   @s_sesn                 = @s_sesn,
   @s_user                 = @s_user,
   @s_term                 = @s_term,
   @s_date                 = @s_date,
   @i_secuencial_pag       = @w_secuencial_pag,
   @i_operacionca          = @w_operacionca,           
   @i_dividendo            = @w_dividendo,
   @i_monto_pago           = @w_monto_mop,          
   @i_cotizacion           = @i_cotizacion,
   @i_tcotizacion          = @w_tcotizacion,
   @i_moneda               = @w_moneda_op,
   @i_condonacion          = 'N',
   @i_colchon              = 'N',
   @o_sobrante_pago        = @w_monto_sobrante   out
   
  if @w_error != 0
     return @w_error

--FIN APLICACION DEL PAGO


   if ( @w_monto_sobrante >= @w_vlr_despreciable)
   begin
      select @w_fpago = abd_concepto,
      @w_cuenta       = abd_cuenta,
      @w_moneda_pag   = abd_moneda,
      @w_abd_cuenta   = abd_cuenta
      from   ca_abono_det
      where  abd_secuencial_ing = @i_secuencial_ing
      and    abd_operacion      = @w_operacionca
      and    abd_tipo           = 'SOB'
   
      if @@rowcount = 0
         return 710115
   
   -- CONVERSION DEL MONTO CALCULADO A LA MONEDA DE PAGO Y OPERACION
   
      exec @w_error       = sp_conversion_moneda
      @s_date             = @i_fecha_proceso,
      @i_opcion           = 'L',
      @i_moneda_monto     = @w_moneda_op,
      @i_moneda_resultado = @w_moneda_pag,
      @i_monto            = @w_monto_sobrante,
      @i_fecha            = @i_fecha_proceso,
      @o_monto_resultado  = @w_abd_monto_mpg out,
      @o_tipo_cambio      = @w_abd_cotizacion_mpg out
      
      if @w_error ! = 0
         return @w_error
   
      exec @w_error       = sp_conversion_moneda
      @s_date             = @i_fecha_proceso,
      @i_opcion           = 'L',
      @i_moneda_monto     = @w_moneda_op,
      @i_moneda_resultado = @w_moneda_mn,
      @i_monto            = @w_monto_sobrante,
      @i_fecha            = @i_fecha_proceso,
      @o_monto_resultado  = @w_abd_monto_mn out,
      @o_tipo_cambio      = @w_cot_moneda out
   
      if @w_error ! = 0
         return @w_error
   
      select @w_prod_cobis = isnull(cp_pcobis,0)
      from   ca_producto
      where  cp_producto = @w_fpago
      
      if (@w_prod_cobis in (3,4,48))
      begin
      
      select @w_descripcion  = 'CANCELACION DE CREDITO FACTORING No.' + CAST(@w_banco AS VARCHAR) 
      
      exec @w_error   = sp_afect_prod_cobis
      @s_ssn          = @s_ssn,
      @s_sesn         = @s_ssn,
      @s_srv          = @s_srv,
      @s_lsrv         = @s_lsrv,
      @s_user         = @s_user,
      @s_date         = @s_date,
      @s_ofi          = @s_ofi,
      @i_fecha        = @s_date,
      @s_term         = @s_term,
      @i_cuenta       = @w_abd_cuenta,
      @i_producto     = @w_fpago,
      @i_monto        = @w_abd_monto_mpg,
      @i_sec_tran_cca = @w_secuencial_rpa, -- FCP Interfaz Ahorros
      @i_opcion       = 6,
      @i_operacionca  = @w_operacionca,
      @i_mon          = @w_moneda_pag,
      @i_no_chequ     = @i_no_cheque,
      @i_alt          = @w_operacionca,
      @i_descripcion  = @w_descripcion
      
      if @w_error != 0
         return @w_error
   end  
   -- ACTUALIZACION DEL VALOR SOBRANTE
   
   update ca_abono_det
   set    abd_monto_mop = @w_monto_sobrante,
          abd_monto_mpg = @w_abd_monto_mn,
          abd_monto_mn  = @w_abd_monto_mn,
          abd_cotizacion_mop =   @w_cot_moneda
   where  abd_secuencial_ing = @i_secuencial_ing
   and    abd_operacion      = @w_operacionca
   and    abd_tipo           = 'SOB'
   
   if @@error != 0 
      return 710002
   
   -- INSERCION DEL DETALLE DE LA TRANSACCION
   insert into ca_det_trn
   (dtr_secuencial,           dtr_operacion,     dtr_dividendo,
   dtr_concepto,              dtr_estado,        dtr_periodo, 
   dtr_codvalor,              dtr_monto,         dtr_monto_mn,
   dtr_moneda,                dtr_cotizacion,    dtr_tcotizacion,
   dtr_afectacion,            dtr_cuenta,        dtr_beneficiario,
   dtr_monto_cont)
   select
   @w_secuencial_pag,         @w_operacionca,    -1,
   @w_fpago,                  0,                 0,
   isnull(cp_codvalor,0),     @w_monto_sobrante, @w_abd_monto_mn,
   @w_moneda_op,              1,                 'N',
   isnull(cp_afectacion,'C'), @w_cuenta,         '',
   0
   from   ca_producto
   where  cp_producto = @w_fpago
   
   if @@error != 0
   begin
      print 'abonoca.sp error en insercion de ca_det_trn'
      return 710001
   end
   select @w_monto_sobrante = 0
end


--PARA ACTUALIZAR VALORES EN GARANTIAS Y CUPO DE CREDITO
if exists (select 1
           from   ca_det_trn 
           where  dtr_secuencial = @w_secuencial_pag 
           and    dtr_operacion  = @w_operacionca
           and    dtr_concepto   = @w_rubro_cap)  
           and @w_lin_credito is not null 
begin
  
   select @w_monto_gar = sum(dtr_monto)
   from   cob_cartera..ca_det_trn
   where  dtr_operacion  = @w_operacionca
   and    dtr_secuencial = @w_secuencial_pag
   and    dtr_concepto   = @w_rubro_cap
   
   select @w_monto_gar_mn = sum(dtr_monto_mn)
   from   cob_cartera..ca_det_trn
   where  dtr_operacion  = @w_operacionca
   and    dtr_secuencial = @w_secuencial_pag
   and    dtr_concepto   = @w_rubro_cap
   
   
   select @w_opcion = 'A'  -- ACTIVA
   
   if @w_moneda_op <> 0
      select @w_monto_gar =  @w_monto_gar_mn
   
   if @w_lin_credito is not null and @w_tramite  is not null and @w_tipo = 'O'
   begin
      exec @w_error  = cob_credito..sp_utilizacion
      @s_ofi         = @s_ofi,
      @s_sesn        = @s_sesn,
      @s_user        = @s_user,
      @s_term        = @s_term,
      @s_date        = @s_date,
      @t_trn         = 21888,
      @i_linea_banco = @w_lin_credito,
      @i_producto    = 'CCA',
      @i_toperacion  = @w_toperacion,
      @i_tipo        = 'R', 
      @i_moneda      = @w_moneda_op,
      @i_monto       = @w_monto_gar,
      @i_opcion      = @w_opcion, 
      @i_tramite     = @w_tramite,
      @i_secuencial  = @w_secuencial_pag,
      @i_opecca      = @w_operacionca,
      @i_cliente     = @w_cliente,
      @i_fecha_valor = @i_fecha_proceso,
      @i_modo        = 0
     
      if @w_error != 0 
         return @w_error
   end
end ---FIN DE ACTUALIZAR VALORES EN GARANTIAS Y CUPO DE CREDITO


-- INSERCION TRN DE LA DEVOLUCION
select @w_fpago        = abd_concepto,
@w_cuenta              = abd_cuenta,
@w_monto_devolucion    = abd_monto_mop,
@w_monto_devolucion_mn = abd_monto_mn,
@w_beneficiario        = abd_beneficiario,
@w_moneda_pago         = abd_moneda,
@w_cotizacion_mop      =  abd_cotizacion_mop
from  ca_abono_det
where abd_secuencial_ing = @i_secuencial_ing
and   abd_operacion      = @w_operacionca
and   abd_tipo           = 'DEV'

if @@rowcount <> 0 
begin  
   --ACTUALIZACION FORMA DE DEVOLUCION DEPENDIENDO DE LA MONEDA
   if @w_moneda_local = @w_moneda_pago 
   begin
      select @w_fpago = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'DEVDD0'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted
      
      if @w_rowcount = 0
         return 710332
   end
   ELSE
   begin
      select @w_fpago = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'DEVDD1'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted
      
      if @w_rowcount = 0  
         return 710333
   end
      
   update ca_abono_det
   set    abd_concepto = @w_fpago 
   where  abd_secuencial_ing = @i_secuencial_ing
   and    abd_operacion      = @w_operacionca
   and    abd_tipo           = 'DEV'
   
   if not exists (select 1 from ca_producto
                  where  cp_producto = @w_fpago)
   begin              
      PRINT 'abonocadd.sp definir la forma de pago para devoluciones @w_fpago ' + CAST(@w_fpago AS VARCHAR)
      return 710344
   end            
      
   -- INSERCION DE REGISTRO  DEV PARA CONTABILIDAD
   insert into ca_det_trn
   (dtr_secuencial,           dtr_operacion,       dtr_dividendo,
   dtr_concepto,              dtr_estado,          dtr_periodo,
   dtr_codvalor,              dtr_monto,           dtr_monto_mn,
   dtr_moneda,                dtr_cotizacion,      dtr_tcotizacion,
   dtr_afectacion,            dtr_cuenta,          dtr_beneficiario,
   dtr_monto_cont)
   select
   @w_secuencial_pag,         @w_operacionca,      -1,
   @w_fpago,                  0,                   0,
   isnull(cp_codvalor,0),     @w_monto_devolucion, @w_monto_devolucion_mn,
   @w_moneda_op,              @w_cotizacion_mop,   'N',
   'D',                       @w_cuenta,           @w_beneficiario,
   0
   from   ca_producto
   where  cp_producto = @w_fpago
   
   if @@error != 0  or @@rowcount = 0
   begin
      print 'abonoca.sp error en insercion de ca_det_trn (2 parte)'
      return 710001
   end
end

select @w_cancelar_div = 'N'

select @w_total_div=isnull(sum(am_cuota+am_gracia-am_pagado),0)
from   ca_amortizacion, ca_rubro_op,ca_concepto
where  am_operacion = @i_operacionca
and    ro_operacion = am_operacion
and    ro_concepto  = am_concepto
and    ro_concepto  = co_concepto
and    am_estado      != @w_est_cancelado
and   (
      (     am_dividendo = @w_dividendo + charindex (ro_fpago, 'A')
        and not(co_categoria in ('S','A') and am_secuencia > 1)
      )
       or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @w_dividendo)
      )

if round(@w_total_div, @w_num_dec_op) < @w_vlr_despreciable
   select @w_cancelar_div = 'S'
         
if @w_cancelar_div = 'S' 
begin  
   update ca_dividendo
   set    di_estado    = @w_est_cancelado,
          di_fecha_can = @w_fecha_proceso
   where  di_operacion = @i_operacionca
   and    di_dividendo = @w_dividendo   
   
   if @@error !=0
   begin
      PRINT 'aboncadd.sp error actualizado ca_dividendo'
      return 710002
   end
           
   update ca_amortizacion
   set    am_estado = @w_est_cancelado
   where  am_operacion = @i_operacionca
   and    am_dividendo = @w_dividendo
   and    am_estado    != @w_est_cancelado
   
   if @@error !=0
   begin
      PRINT 'aboncadd.sp error actualizado ca_amortizacion @w_est_cancelado ' + cast(@w_est_cancelado as varchar) + ' @w_dividendo ' + cast(@w_dividendo as varchar) + ' @i_operacionca ' + cast(@i_operacionca as varchar)
      return 710002
   end
   
   
   if not exists(select 1 from ca_dividendo
                         where di_operacion = @i_operacionca
                         and   di_estado in (0,1,2) )
   begin
      update ca_operacion
      set    op_estado = @w_est_cancelado
      where  op_operacion = @i_operacionca  
   end
   else
   if not exists (select 1 from ca_dividendo
                                   where di_operacion =  @i_operacionca
                   and di_estado = 1) 
   select @w_ultimo_cancelado = max(di_dividendo)
   from ca_dividendo
   where di_operacion = @i_operacionca
   and   di_estado = 3
    
   begin
      -- VIGENTE EL SIGUIENTE        
      update ca_dividendo
      set    di_estado = @w_est_vigente
      where  di_operacion = @i_operacionca
      and    di_dividendo = @w_ultimo_cancelado + 1
      and    di_estado    = 0
      
      if @@error !=0
      begin
         PRINT 'aboncadd.sp error actualizado ca_dividendo en cancelacion'
         return 710002
      end
      
      update ca_amortizacion
      set    am_estado = @w_est_vigente
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_ultimo_cancelado + 1
      and    am_estado    = 0
      
      if @@error !=0
      begin
         PRINT 'aboncadd.sp error actualizado ca_amortizacion en cancelacion'
         return 710002
      end
   
      -- ACTUALIZAR RUBROS
      update ca_amortizacion
      set    am_acumulado = am_cuota
      from   ca_amortizacion, ca_rubro_op
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_ultimo_cancelado + 1
      and    ro_operacion = @i_operacionca
      and    am_operacion = ro_operacion
      and    ro_concepto  = am_concepto
      and    ro_tipo_rubro not in ('C', 'I', 'M')
      and    am_estado != 3
      
      if @@error !=0
      begin
         PRINT 'aboncadd.sp error actualizado ca_amortizacion  acumulado'
         return 710002
      end
   end   
end  ---cancelar_div 

select @w_estado_div = di_estado
from ca_dividendo
where di_operacion = @i_operacionca
and di_dividendo   = @w_dividendo

if @w_estado_div = @w_est_cancelado
begin    
    ---cambio de estado por factura al cancelar la cuota
    select @w_col_bruto = 0,
           @w_col_neto  = 0
         
    declare facturas_can  cursor 
    for
    select fa_grupo,
           fa_num_negocio,
           fa_referencia,
           fa_proveedor,
           do_valor_neg,
           fa_valor
    from   cob_custodia..cu_documentos,  
           cob_credito..cr_facturas
    where  fa_tramite     = @w_tramite
    and    do_num_negocio = fa_num_negocio
    and    fa_referencia  = do_num_doc
    and    fa_dividendo   = @w_dividendo
    and    do_estado      = 'V'
   
    open facturas_can
   
    fetch facturas_can 
    into
    @w_grupo,
    @w_num_negocio,
    @w_num_doc,
    @w_proveedor,
    @w_colchon_bruto,
    @w_colchon_neto
   
    --while @@fetch_status not in (-1,0)
    while @@fetch_status = 0
    begin
       select @w_col_bruto = @w_col_bruto + isnull(@w_colchon_bruto,0),
              @w_col_neto  = @w_col_neto  + isnull(@w_colchon_neto ,0)
              
       exec @w_error  =  cob_custodia..sp_cambio_estado_doc
       @i_operacion   = 'I',
       @i_modo        =  2,
       @i_opcion      = 'C',
       @i_tramite     =  @w_tramite,
       @i_grupo       =  @w_grupo,
       @i_num_negocio =  @w_num_negocio,
       @i_num_doc     =  @w_num_doc,
       @i_proveedor   =  @w_proveedor
         
       if @w_error != 0
          return @w_error 
           
            
         --ANALIZAR SI EL VALOR DEL COLCHON DEBE SER DEVUELTO   

       fetch facturas_can into
       @w_grupo,
       @w_num_negocio,
       @w_num_doc,
       @w_proveedor,
       @w_colchon_bruto,
       @w_colchon_neto
   end
   
   close facturas_can
   deallocate facturas_can
      
/*  --MRoa: NO BORRAR ESTE CODIGO COMENTADO - FUNCIONALIDAD SIDAC FASE II BANCA MIA*/
   if  @w_colchon = 'S' and @w_col_bruto > @w_col_neto
   begin 
      select @w_concepto_cxp = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'CXPCOL'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted
       
      if @w_rowcount = 0
         return 710335
      
      select @w_re_area = pa_int
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'ARCXP'
      set transaction isolation level read uncommitted
       
      --Solo se hace devolucion del valor que corresponde
      --si con este valor se pago mora, no se devuelve el colchon completo
      select @w_col_mora = isnull(abd_monto_mn,0)
      from ca_abono_det
      where abd_secuencial_ing = @i_secuencial_ing
      and  abd_operacion = @i_operacionca
      and   abd_tipo = 'COL'
       
      select @w_colchon_devolver = isnull(@w_col_bruto - @w_col_neto,0)
       
      select @w_colchon_devolver = @w_colchon_devolver - isnull(@w_col_mora,0)

      --GENERAR NOTA DE CUENTA POR PAGAR A SIDAC 
      select @w_operacion_sidac = convert(varchar, @i_operacionca)
      select @w_sec_sidac       = convert(varchar, @w_secuencial_pag )
      select @w_referencia_sidac = rtrim(ltrim(@w_operacion_sidac)) + ':' + rtrim(ltrim(@w_sec_sidac))
       
      
      --- GENERAR NOTA A SIDAC 
      if @w_colchon_devolver > 0
      begin
         /* No se tiene cob_sidac - banca mia
         exec @w_error = cob_sidac..sp_cuentaxpagar
         @s_ssn               =  @s_ssn,
         @s_user              =  @s_user,
         @s_date              =  @s_date,
         @s_term              =  @s_term,
         @s_ssn_corr          =  @s_ssn,
         @s_srv               =  @s_srv,
         @s_ofi               =  @s_ofi,
         @t_trn               =  32550,
         @i_operacion         = 'I',
         @i_empresa           =  1,
         @i_fecha_rad         =  @s_date,
         @i_modulo            =  @w_producto,         -- 7  numero de cartera
         @i_fecha_ven         =  @s_date,             -- Fecha proceso
         @i_moneda            =  @w_moneda_op,        -- Moneda dela operacion
         @i_valor             =  @w_colchon_devolver, -- Valor del colchon
         @i_concepto          =  @w_concepto_cxp,     -- Este esta definido como parametro gral14CART18
         @i_condicion         = '1',                  -- 1 es un caracter
         @i_tipo_referencia   = '01',
         @i_formato_fecha     =  101,                 -- Formato de fecha
         @i_ente              =  @w_cliente,          -- Op_cliente
         @i_referencia        =  @w_referencia_sidac,            -- No. del credito y secuencial del pago
         @i_area              =  @w_re_area,
         @i_oficina           =  @w_oficina_op,       -- Ofi del credito
         @i_estado            = 'P',
         @i_descripcion       =  'DEVOLUCION POR COLCHON DE OPERACION EN FACTORING'
              
         if @w_error  != 0   
         begin
              PRINT 'abonoca.sp saliendo de CxC  1  @s_date %1! + @w_concepto_cxp %2!' + CAST(@s_date AS VARCHAR) +  CAST(@w_concepto_cxp AS VARCHAR)
              return 710336 
         end
         */  -- No se tiene cob_sidac - banca mia
         --PARAMETROP PARA DEVOLUCIONES DE COLCHON EN OEPRACIONES FACTORING

         select @w_dev_colchon = pa_char
         from cobis..cl_parametro
         where pa_nemonico = 'DEVCOL'
         and pa_producto = 'CCA'
         select @w_rowcount = @@rowcount
         set transaction isolation level read uncommitted
                     
         if @w_rowcount = 0
         begin              
            PRINT 'abonocadd.sp definir parametro general DEVCOL'
            return 710344
         end            

         if not exists (select 1 from ca_producto
                        where  cp_producto = @w_dev_colchon)
         begin              
            PRINT 'abonocadd.sp definir la forma de pago para devoluciones ' + CAST(@w_dev_colchon AS VARCHAR)
            return 710344
         end            

         ---Insertar en el detalle del pago para los reversos
         insert into ca_abono_det
         (abd_secuencial_ing,  abd_operacion,               abd_tipo,            abd_concepto ,
         abd_cuenta,           abd_beneficiario,            
         abd_moneda,           abd_monto_mpg,
         abd_monto_mop,        abd_monto_mn,                abd_cotizacion_mpg,  abd_cotizacion_mop,
         abd_tcotizacion_mpg,  abd_tcotizacion_mop,         abd_cheque,          abd_cod_banco,
         abd_inscripcion,      abd_carga,                   abd_solidario)                             --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
         values(@i_secuencial_ing,    @w_operacionca,       'DEV',               @w_dev_colchon,
         'A SIDAC',           'DEVOLUCION DE COLCHON POR CANCELACION DE FACTURAS',      
         0,          @w_colchon_devolver,
         @w_colchon_devolver,        @w_colchon_devolver,  1,                  1,
         'C',                  'C',                         null,                null,
         null,                 null,                        'N')
         
         if @@error != 0
         begin
            PRINT 'abonocadd.sp error insertando eldetalle de la devolcuion del colchon'
            return 710295
         end                    
      end --devolucion del colchon       

      -- ACTUALIZAR EL RUBRO COL 
      update ca_rubro_op
      set    ro_valor = ro_valor - @w_colchon_devolver
      where  ro_operacion = @i_operacionca
      and    ro_concepto = @w_parametro_col
      
      if @@error != 0
         return 710317
                          
   end ---colchon      

   ---Actualizar la tabla ca_facturas de cartera 
      
   update ca_facturas
   set fac_estado_factura = 3,
       fac_pagado = fac_valor_negociado        
   where fac_operacion =     @i_operacionca
   and   fac_nro_dividendo = @w_dividendo
   if @w_error != 0     
      return @w_error       
   /*--MRoa: FIN CODIGO COMENTADO - FUNCIONALIDAD SIDAC FASE II BANCA MIA */

end

return 0

go

