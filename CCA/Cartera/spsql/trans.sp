/************************************************************************/
/*   Archivo:             trans.sp                                      */
/*   Stored procedure:    sp_transaccion                                */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Fabian de la Torre                            */
/*   Fecha de escritura:  Feb 1999                                      */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*            PROPOSITO                                                 */
/*   Reversa las transacciones y los montos les pone por (-1)           */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA               AUTOR                 RAZON                 */
/*      05/12/2016      R. Sánchez              Modif. Apropiación    */
/*      30/Jun/2020     Luis Ponce    CDIG Multimoneda Reversar Posicion*/
/*   26/Nov/2020   Patricio Narvaez   Esquema de Inicio de Dia, Conta   */
/*                                    provisiones en moneda nacional    */
/*      20/Ago/2021     K. Rodríguez  Reverso devengamiento de rubros  */
/*                                    diferidos.                        */
/*      19/11/2021      G. Fernandez  Ingreso de nuevos parametros para */
/*                                     proceso de licitud               */
/*      01/06/2022      G. Fernandez  Se comenta prints                 */
/*      26/Jul/2022     K. Rodríguez  Incluir registros devengamiento   */
/*                                    de la fecha proceso del préstamo  */
/*      17/abr/2023     G. Fernandez  S807925 Ingreso de campo de       */
/*                                      reestructuracion                */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_transaccion')
   drop proc sp_transaccion
go

---INC. 117737 NOV.17.2014 PAgosNormales

create proc sp_transaccion
   @s_user              login,
   @s_term              descripcion,
   @s_ofi               smallint,
   @s_date              datetime,
   @s_ssn               INT = 0,
   @t_file              varchar(14)  = null, --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos
   @t_ssn_corr          int          = null, --GFP 18-11-2021
   @t_debug             char(1)      = 'N',  --GFP 18-11-2021
   @i_secuencial_retro  int,
   @i_operacion         char(1),     --(F)Fecha Valor (R)Reversa
   @i_observacion       varchar(62) = '',
   @i_operacionca       int,
   @i_fecha_retro       datetime,
   @i_es_atx            char(1)  = 'N',
   @i_tiene_rub_dif     char(1) = 'N', -- KDR-20/08/2021 Bandera si la operacion tiene rubros diferidos
   @i_aplica_licitud    CHAR(1) = null --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos
as

declare 
   @w_return                  int,
   @w_tran                    varchar(10),
   @w_sec_ref                 int,
   @w_op_moneda               tinyint,
   @w_moneda_uvr              tinyint,
   @w_decimales               tinyint,
   @w_forma_reversa           catalogo,
   @w_sec_divisas             INT,
   @w_sec_reversa             INT,
   @w_op_banco                cuenta,
   @w_op_cliente              INT
   
   
   
set ansi_warnings off

if exists (select 1 from cob_cartera_his..ca_transaccion
where tr_operacion = @i_operacionca
and   tr_secuencial >= @i_secuencial_retro)
   return 710494 
   
   
-- CODIGO DE MONEDA UVR
select @w_moneda_uvr = pa_tinyint 
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR' 

select @s_date = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

select @w_op_moneda = op_moneda,
       @w_op_banco  = op_banco,
       @w_op_cliente = op_cliente
from   ca_operacion
where  op_operacion = @i_operacionca

exec sp_decimales
@i_moneda    = @w_op_moneda,
@o_decimales = @w_decimales out

-- REVERSION DE LAS TRANSACCIONES DISTINTAS DE CMO, PRV, RPA, PAG

insert into ca_transaccion(
tr_secuencial,       tr_fecha_mov,        tr_toperacion,
tr_moneda,           tr_operacion,        tr_tran,
tr_en_linea,         tr_banco,            tr_dias_calc,
tr_ofi_oper,         tr_ofi_usu,          tr_usuario,
tr_terminal,         tr_fecha_ref,        tr_secuencial_ref,
tr_estado,           tr_observacion,      tr_gerente,
tr_gar_admisible,    tr_reestructuracion,
tr_calificacion,     tr_fecha_cont,       tr_comprobante)
select 
-1 * tr_secuencial,  @s_date,             tr_toperacion,
tr_moneda,           tr_operacion,        tr_tran,
tr_en_linea,         tr_banco,            tr_dias_calc,
tr_ofi_oper,         tr_ofi_usu,          @s_user, -- LAS REVERSAS SE HARAN CON LA MISMA OFICINA DE LA TRANSACCION ORIGINAL
@s_term,             tr_fecha_ref,        tr_secuencial,
'ING',               tr_observacion,      tr_gerente,
tr_gar_admisible,    tr_reestructuracion,
tr_calificacion,     @s_date,             tr_comprobante
from   ca_transaccion
where  tr_operacion   = @i_operacionca
and    tr_secuencial >= @i_secuencial_retro
and    tr_estado      = 'CON'
and    tr_tran       not in ('RPA', 'PRV', 'CMO','TRC','MIG','CGR', 'TCO')
and    tr_secuencial <> 0

if @@error <> 0 begin
   --GFP se suprime print
   --PRINT 'trans.sp Error Insertando en ca_transaccion No.1'
   return 710001
end

insert into ca_det_trn(
dtr_secuencial,     dtr_operacion,    dtr_dividendo,
dtr_concepto,       dtr_estado,       dtr_periodo,
dtr_codvalor,       dtr_monto,        dtr_monto_mn,
dtr_moneda,         dtr_cotizacion,   dtr_tcotizacion,
dtr_afectacion,     dtr_cuenta,       dtr_beneficiario, dtr_monto_cont)
select 
-1*dtr_secuencial,  dtr_operacion, dtr_dividendo,
dtr_concepto,
dtr_estado,         dtr_periodo,                  dtr_codvalor,
dtr_monto,          dtr_monto_mn,                 dtr_moneda,
dtr_cotizacion,     isnull(dtr_tcotizacion,''),   dtr_afectacion,
dtr_cuenta,         dtr_beneficiario,             0
from   ca_transaccion, ca_det_trn 
where  tr_operacion    = @i_operacionca
and    tr_secuencial  >= @i_secuencial_retro
and    tr_estado       = 'CON'
and    tr_tran         not in ('RPA', 'PRV', 'CMO','TRC','CGR','MIG','TCO')
and    tr_secuencial   = dtr_secuencial
and    tr_operacion    = dtr_operacion
and    tr_secuencial  <> 0

if @@error <> 0 begin
   --GFP se suprime print
   --PRINT 'trans.sp Error Insertando en ca_det_trn No. 1'
   return 710001
end

/* BORRADO DE TRANSACCIONS PRV NO CONTABILIZADAS */
delete ca_transaccion_prv with (rowlock)
where tp_fecha_ref      >= @i_fecha_retro  --Inicio de dia: la causacion se genera el dia anterior con fecha de ma�ana
and   tp_operacion      = @i_operacionca
and   tp_estado         = 'ING'
and   tp_secuencial_ref  = 0

if @@error <> 0  return 710003

/* BORRADO DE TRANSACCIONS PRV NO CONTABILIZADAS ASOCIADAS A LAS TRANSACCIONES QUE ESTAMOS REVERSANDO */
delete ca_transaccion_prv with (rowlock)
where tp_operacion       = @i_operacionca
and   tp_estado          = 'ING'
and   tp_secuencial_ref >= @i_secuencial_retro

if @@error <> 0  return 710003


insert into ca_transaccion_prv with (rowlock) (
tp_fecha_mov,           tp_operacion,        tp_fecha_ref,
tp_secuencial_ref,      tp_estado,           tp_dividendo,
tp_concepto,            tp_codvalor,         tp_monto,
tp_secuencia,           tp_comprobante,      tp_ofi_oper,
tp_monto_mn,            tp_moneda,           tp_cotizacion,
tp_tcotizacion,         tp_reestructuracion)
select 
@s_date,                tp_operacion,        tp_fecha_mov,
-999,                  'ING',                tp_dividendo,
tp_concepto,            tp_codvalor,         tp_monto * -1,
tp_secuencia,           tp_comprobante,      tp_ofi_oper,
tp_monto_mn * -1,       tp_moneda,           tp_cotizacion,
tp_tcotizacion,         tp_reestructuracion
from ca_transaccion_prv
where tp_fecha_ref      >= @i_fecha_retro --Inicio de dia: la causacion se genera el dia anterior con fecha de ma�ana
and   tp_operacion      = @i_operacionca
and   tp_estado         = 'CON'
and   abs(tp_monto)    >= 0.01
and   tp_secuencial_ref = 0

if @@error <> 0  return 708165
            
update ca_transaccion_prv set 
tp_estado = 'RV'
where tp_fecha_ref       >= @i_fecha_retro  --Inicio de dia: la causacion se genera el dia anterior con fecha de ma�ana
and   tp_operacion       = @i_operacionca
and   tp_secuencial_ref  = 0

if @@error <> 0 return 708165


/* EN CASO DE EXISTIR, REVERSAR TRANSACCIONES PRV'S ASOCIADAS A LA TRANSACCION PRINCIPAL */   
insert into ca_transaccion_prv with (rowlock)(
tp_fecha_mov,           tp_operacion,        tp_fecha_ref,
tp_secuencial_ref,      tp_estado,           tp_dividendo,
tp_concepto,            tp_codvalor,         tp_monto,
tp_secuencia,           tp_comprobante,      tp_ofi_oper,
tp_monto_mn,            tp_moneda,           tp_cotizacion,
tp_tcotizacion,         tp_reestructuracion)
select 
@s_date,                tp_operacion,        tp_fecha_mov,
-1*tp_secuencial_ref,   'ING',               tp_dividendo,
tp_concepto,            tp_codvalor,         tp_monto * -1,
tp_secuencia,           tp_comprobante,      tp_ofi_oper,
tp_monto_mn * -1,       tp_moneda,           tp_cotizacion,
tp_tcotizacion,         tp_reestructuracion
from ca_transaccion_prv
where tp_operacion      = @i_operacionca
and   tp_estado         = 'CON'
and   tp_secuencial_ref >= @i_secuencial_retro
and   abs(tp_monto)    >= 0.01

if @@error <> 0 return 708165
      
update ca_transaccion_prv set
tp_estado = 'RV'
where tp_operacion       = @i_operacionca
and   tp_secuencial_ref >= @i_secuencial_retro

if @@error <> 0 return 710002


      
-- MONEDA UVR, CORRECCION MONETARIA
if @w_moneda_uvr = @w_op_moneda begin

   insert into ca_det_trn(
   dtr_secuencial,     dtr_operacion,     dtr_dividendo,
   dtr_concepto,
   dtr_estado,         dtr_periodo,       dtr_codvalor,
   dtr_monto,          dtr_monto_mn,      dtr_moneda,
   dtr_cotizacion,     dtr_tcotizacion,   dtr_afectacion,
   dtr_cuenta,         dtr_beneficiario,  dtr_monto_cont)
   select 
   -1*dtr_secuencial,  dtr_operacion,     dtr_dividendo,
   dtr_concepto,
   dtr_estado,         dtr_periodo,       dtr_codvalor,
   dtr_monto_cont,     dtr_monto_cont,    dtr_moneda,
   dtr_cotizacion,     dtr_tcotizacion,   dtr_afectacion,
   dtr_cuenta,         dtr_beneficiario,  0
   from   ca_transaccion, ca_det_trn 
   where  tr_operacion    = @i_operacionca
   and    tr_secuencial  >= @i_secuencial_retro
   and    tr_tran         = 'CMO'
   and    tr_secuencial   = dtr_secuencial
   and    tr_operacion    = dtr_operacion
   
   if @@error <> 0  begin
      --GFP se suprime print
      --PRINT 'trans.sp Error Insertando en ca_det_trn No. 3'
      return 710001
   end
   
   -- GENERAR TRANSACCIONES DE REVERSA
   insert into ca_transaccion(
   tr_secuencial,      tr_fecha_mov,    tr_toperacion,
   tr_moneda,          tr_operacion,    tr_tran,
   tr_en_linea,        tr_banco,        tr_dias_calc,
   tr_ofi_oper,        tr_ofi_usu,      tr_usuario,
   tr_terminal,        tr_fecha_ref,    tr_secuencial_ref,
   tr_estado,          tr_observacion,  tr_gerente,
   tr_calificacion,    tr_gar_admisible,tr_fecha_cont,
   tr_comprobante,     tr_reestructuracion)
   select 
   -1 * tr_secuencial, @s_date,         tr_toperacion,
   tr_moneda,          tr_operacion,    tr_tran, 
   tr_en_linea,        tr_banco,        tr_dias_calc,
   tr_ofi_oper,        tr_ofi_usu,      @s_user, -- LAS REVERSAS SE HARAN CON LA MISMA OFICINA DE LA
                                                 -- TRANSACCION ORIGINAL
   @s_term,            tr_fecha_ref,    tr_secuencial, 
   'ING',              tr_observacion,  tr_gerente,
   tr_calificacion,    tr_gar_admisible,@s_date,
   tr_comprobante,   tr_reestructuracion
   from   ca_transaccion 
   where  tr_operacion   =  @i_operacionca
   and    tr_secuencial  >= @i_secuencial_retro
   and    tr_tran        =  'CMO'
   and    tr_estado      <>  'RV'
   
   if @@error <> 0  begin
      --GFP se suprime print
      --PRINT 'trans.sp Error Insertando en ca_transaccion No. 3 @i_secuencial_retro' + CAST(@i_secuencial_retro AS VARCHAR)
      return 710001
   end
   
end -- FIN MONEDA UVR

-- ACTUALIZAR LAS TRANSACCIONES COMO REVERSADAS
update ca_transaccion set
tr_estado      = 'RV',
tr_observacion = isnull(ltrim(rtrim(tr_observacion)), ' ') + ' RAZON REVERSO: ' + isnull(ltrim(rtrim(@i_observacion)),'')
where  tr_operacion   = @i_operacionca
and    tr_secuencial >= @i_secuencial_retro
and    tr_tran       not in ('RPA', 'MIG', 'TCO')
and    tr_estado     in ('CON','ING', 'ANU', 'NCO')

if @@error <> 0  return 710002


-- EN CASO DE REVERSA DE UN PAGO, ELIMINAR EL RPA
if @i_operacion = 'R' begin

   select 
   @w_tran    = tr_tran,
   @w_sec_ref = tr_secuencial_ref
   from   ca_transaccion
   where  tr_operacion  = @i_operacionca 
   and    tr_secuencial = @i_secuencial_retro
   
   if @w_tran = 'RPA' begin
      --GFP se suprime print
      --print 'NO SE PUEDE REVERTIR UNA TRANSACCION RPA DE FORMA DIRECTA'
      return  708166
   end

   if @w_tran = 'RES' begin

      /* ELIMINAR REGISTRO DE CAMBIO DE FECHA */
      delete ca_cambio_fecha
      where cf_operacion  = @i_operacionca
      and   cf_secuencial = @i_secuencial_retro

      if @@error <> 0 return 710003

   end

   
   if @w_tran = 'DES' begin

      update ca_det_trn set
      dtr_concepto = cp_producto_reversa,
      dtr_codvalor = cp_codvalor
      from   ca_producto
      where  dtr_operacion  = @i_operacionca
      and    dtr_secuencial = -@i_secuencial_retro
      and    dtr_concepto   = cp_producto
      and    dtr_codvalor   < 1000 -- SOLO PARA MEDIOS DE PAGO, DEFECTO 6858
      
      if @@error <> 0  return  708166
   end
   
   if @w_tran   = 'PAG' 
   begin
   
      delete ca_abono_fng
      where af_operacion  = @i_operacionca

      if @@error <> 0 return 710003
       
      --LPO CDIG Multimoneda Reversa INICIO
/*      --/ DETERMINAR SI DEBE REALIZARSE LA REVERSA DE LA TRANSACCION TRIBUTARIA DE CAMBIO DE DIVISAS /
      select @w_sec_divisas = tr_dias_calc
      from   ca_transaccion 
      where  tr_operacion  = @i_operacionca
      and    tr_secuencial = @i_secuencial_retro
      and    tr_tran       = 'PAG'
      
      select @w_sec_divisas = isnull(@w_sec_divisas, 0)
      
      --/ PROCESAR REVERSA DE TRANSACCION TRIBUTARIA DE DIVISAS /
      if @w_sec_divisas > 0
      begin
         select @w_sec_reversa = isnull(trd_sec_divisas,0)
         from   ca_tran_divisas 
         where  trd_operacion  = @i_operacionca
         and    trd_secuencial = @w_sec_divisas 
         
         if @w_sec_reversa > 0
         begin
            exec @w_return       = cob_cartera..sp_op_divisas_automatica
            @s_date          = @s_date,        --/ Fecha del sistema                                                         /
            @s_user          = @s_user,        --/ Usuario del sistema                                                       /
            @s_ssn           = @s_ssn,         --/ Secuencial Transaccion                                                    /
            @i_oficina       = @s_ofi,         --/ Oficina donde debe ser registrada la transaccion.  Afectar  contablemente /
            @i_cliente       = @w_op_cliente, --/ Codigo del cliente a nombre de quien se realiza la operacion de divisas   /
            @i_modulo        = 'CCA',          --/ Nemonico del modulo COBIS que origina la operacion de divisas             /
            @i_operacion     = 'R',            --/ C - Consulta, E - Ejecucion normal , R - Reversar una operacion anterior  /
            @i_secuencial    = @w_sec_reversa, --/ SSN de la operacion normal.  Usado para reversos                          /
            @i_batch         = 'N', --@i_en_linea,
            @i_empresa       = 1,
            @i_num_operacion = @w_op_banco,
            --@i_producto      = 7,              -- Producto Cartera. 
            @i_masivo        = 'L'         
                   
            if @w_return != 0
            begin
               return @w_return
            END
         END
      END
*/      
      --LPO CDIG Multimoneda Reversa FIN
      
      insert into ca_transaccion (
      tr_secuencial,     tr_fecha_mov,   tr_toperacion,
      tr_moneda,         tr_operacion,   tr_tran,
      tr_en_linea,       tr_banco,       tr_dias_calc,
      tr_ofi_oper,       tr_ofi_usu,     tr_usuario,
      tr_terminal,       tr_fecha_ref,   tr_secuencial_ref,
      tr_estado,         tr_observacion, tr_gerente,
      tr_gar_admisible,  tr_reestructuracion,
      tr_calificacion,   tr_fecha_cont,   tr_comprobante)
      select 
      -1*tr_secuencial,  @s_date,        tr_toperacion,
      tr_moneda,         tr_operacion,   tr_tran,
      tr_en_linea,       tr_banco,       tr_dias_calc,
      tr_ofi_oper,       tr_ofi_usu,     @s_user, 
      @s_term,           tr_fecha_ref,   tr_secuencial,
      'ING',             tr_observacion, tr_gerente,
      tr_gar_admisible,  tr_reestructuracion,
      tr_calificacion,   @s_date,        tr_comprobante
      from   ca_transaccion
      where  tr_operacion  = @i_operacionca
      and    tr_secuencial = @w_sec_ref
      and    tr_estado     = 'CON'
      
      if @@error <> 0 begin
	     --GFP se suprime print
         --PRINT 'trans.sp Error Insertando en ca_transaccion No. 4'
         return 710001
      end
      
      insert into ca_det_trn (
      dtr_secuencial,      dtr_operacion,               dtr_dividendo,
      dtr_concepto,
      dtr_estado,          dtr_periodo,                 dtr_codvalor,
      dtr_monto,           dtr_monto_mn,                dtr_moneda,
      dtr_cotizacion,      dtr_tcotizacion,             dtr_afectacion,
      dtr_cuenta,          dtr_beneficiario,            dtr_monto_cont )
      select 
      -1*dtr_secuencial,   dtr_operacion,               dtr_dividendo,
      dtr_concepto,
      dtr_estado,          dtr_periodo,                 dtr_codvalor,
      dtr_monto,           dtr_monto_mn,                dtr_moneda,
      dtr_cotizacion,      isnull(dtr_tcotizacion,''),  dtr_afectacion,
      dtr_cuenta,          dtr_beneficiario,            0
      from   ca_transaccion, ca_det_trn
      where  tr_operacion  = @i_operacionca
      and    tr_secuencial = @w_sec_ref
      and    tr_secuencial = dtr_secuencial
      and    tr_operacion  = dtr_operacion
      and    tr_estado     = 'CON'
      
      if @@error <> 0  begin
	     --GFP se suprime print
         --PRINT 'trans.sp Error Insertando en ca_det_trn No. 4'
         return 708165
      end
      
      update ca_transaccion set
      tr_estado = 'RV',
      tr_observacion = isnull(@i_observacion,'')
      where  tr_operacion = @i_operacionca 
      and    tr_secuencial = @w_sec_ref
      
      if @@error <> 0 return 710492
      
      if @i_es_atx = 'N' begin
         update ca_det_trn set
         dtr_concepto = cp_producto_reversa,
         dtr_codvalor = (select cp_codvalor from ca_producto where  cp_producto = orig.cp_producto_reversa)
         from   ca_producto orig
         where  dtr_operacion  = @i_operacionca
         and    dtr_secuencial = -@w_sec_ref
         and    dtr_concepto   = cp_producto
         and    dtr_codvalor    < 1000
         
         if @@error <> 0 return 710002
         
      end
      
	  --GFP 12-11-2021 Ingreso de licitud de fondos
	  if @i_aplica_licitud  = 'S'
	  begin
	  exec @w_return = cobis..sp_licitud 
	  @t_ssn_corr       = @t_ssn_corr,
	  @t_debug          = @t_debug, 
	  @t_file           = @t_file,
	  @i_operacion      = 'I',
	  @i_factor         = -1, --para reversos
	  @i_ente           = @w_op_cliente, -- codigo de ente cobis
	  @i_fecha          = @s_date,
	  @i_monto          = null,   -- Valor contable, efectivo mas cheques
	  @i_efectivo       = null,   -- Valor en efectivo
	  @i_batch          = 'N',
	  @i_tran           = 7058,   -- Transaccion original preguntar si seria @t_trn
	  
	  @i_reverso_cca    = 'S',
	  @i_ssn_cca        = @s_ssn,
	  @i_fecha_cca      = @s_date,
	  @i_cta_cca        = @w_op_banco

	  
	  if @w_return <> 0 return @w_return
	  end
	  	
   end   -- solo para reverso de pagos
      
end

-- KDR-20/08/2021 Reversar los devengamientos que generaron los rubros diferidos.
if @i_operacion = 'R' and @i_tiene_rub_dif = 'S'
begin
   
   /* Eliminar transacciones PRV que no se contabilizaron*/
   delete ca_transaccion_prv with (rowlock)
   where tp_fecha_ref      >= @i_fecha_retro 
   and   tp_operacion      = -1*@i_operacionca
   and   tp_estado         = 'ING'
   and   tp_secuencial_ref  = 0
   
   if @@error <> 0  return 710003
   
   insert into ca_transaccion_prv with (rowlock) (
   tp_fecha_mov,           tp_operacion,        tp_fecha_ref,
   tp_secuencial_ref,      tp_estado,           tp_dividendo,
   tp_concepto,            tp_codvalor,         tp_monto,
   tp_secuencia,           tp_comprobante,      tp_ofi_oper,
   tp_monto_mn,            tp_moneda,           tp_cotizacion,
   tp_tcotizacion,         tp_reestructuracion)
   select 
   @s_date,                tp_operacion,        tp_fecha_mov,
   -999,                  'ING',                tp_dividendo,
   tp_concepto,            tp_codvalor,         tp_monto * -1,
   tp_secuencia,           tp_comprobante,      tp_ofi_oper,
   tp_monto_mn * -1,       tp_moneda,           tp_cotizacion,
   tp_tcotizacion,         tp_reestructuracion
   from ca_transaccion_prv
   where tp_fecha_ref      >= @i_fecha_retro
   and   tp_operacion      = -1*@i_operacionca
   and   tp_estado         = 'CON'
   and   abs(tp_monto)    >= 0.01
   and   tp_secuencial_ref = 0
   
   if @@error <> 0  return 711105
               
   update ca_transaccion_prv set 
   tp_estado = 'RV'
   where tp_fecha_ref       >= @i_fecha_retro
   and   tp_operacion       = -1*@i_operacionca
   and   tp_secuencial_ref  = 0
   
   if @@error <> 0 return 711105

end

return 0

go
