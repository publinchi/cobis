/************************************************************************/
/*   NOMBRE LOGICO:      regabono.sp                                   */
/*   NOMBRE FISICO:      sp_registro_abono                             */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       R. Garces                                      */
/*   FECHA DE ESCRITURA: Feb. 1995                                      */
/************************************************************************/
/*                        IMPORTANTE                                    */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                        PROPOSITO                                     */
/*   Realiza el registro de la forma de abono generando la              */
/*   transaccion respectiva.                                            */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*   FECHA           AUTOR             RAZON                            */
/*   FEB-06-2003     E. Pelaez         Personalizacion BAC              */
/*   MAR-07-2005     E. Pelaez         tr_fecha_ref                     */
/*   ENE-28-2010     I. Torres         Req.00088 CalHOnorarios          */
/*   FEB-11-2010     I. Torres         Req.00072 Condonacion por Rol    */
/*   23/abr/2010     Fdo Carvajal      MANEJO NOTAS DEBITO              */
/*   10/Jun/2010     ELcira Pelaez     Quitar Codigo causacion Pasivas  */
/*                                     y comentarios                    */
/*   20/Jun/2020     Luis Ponce        CDIG Multimoneda                 */
/*   20/10/2021      G. Fernandez       Ingreso de nuevo campo de       */
/*                                       solidario en ca_abono_det      */
/*   19/11/2021      G. Fernandez      Ingreso de nuevos parametros para*/
/*                                     proceso de licitud               */
/*   31/05/2021      K. Rodríguez      Ajustes para no tomar Condonación*/
/*   08/07/2021      K. Rodríguez      Monto de pago sin reducir margen */
/*                                     aceptable                        */
/*   01/02/2023    K. Rodriguez        S771317 Sec. RPA var. de salida  */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/ 
/*   01/08/2023	   G. Fernandez	      S873625 Se valida parametro para  */
/*									  licitud por categoria de fp       */ 
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_registro_abono')
   drop proc sp_registro_abono
go

--- INC.117192

create proc sp_registro_abono
@s_user           login = null,
@s_term           varchar(30) = null,
@s_date           datetime = null,
@s_ofi            smallint = null,
@s_ssn            int = null,
@s_sesn           int = null,
@s_srv            varchar(30) = null,
--Ingreso de parametros solo utilizados para licitud de fondos
@s_ssn_branch     int         = null,
@s_lsrv           varchar(30) = null,
@s_rol            smallint    = null,
@s_org            char(1)     = null,
@t_ssn_corr       int         = null,
@t_debug          char(1)     = 'N',
@t_file           varchar(20) = null,
@t_from           descripcion = null,
@t_trn            smallint    = null,
--Fin de parametros solo utilizados para licitud de fondos
@i_secuencial_ing int,
@i_operacionca    int,
@i_en_linea       char(1),
@i_fecha_proceso  datetime,
@i_no_cheque      int = null,
@i_cuenta         cuenta = null,
@i_mon            smallint=null,
@i_dividendo      int=0,
@i_cotizacion     money,
@i_secuencial_pag int    = null,    -- ITO 10/02/2010
@i_aplica_licitud  char   = 'N',
-- GFP 12-11-2021 Parametros para licitud de fondos
@o_consep         char(1)       = null out,
@o_ssn            int           = null out,   
@o_monto          money         = null out,
@o_secuencial_rpa int           = null out

as 

declare
   @w_cot_moneda           money,
   @w_num_dec              tinyint,
   @w_moneda_n             tinyint,
   @w_num_dec_n            tinyint,
   @w_secuencial_rpa       int,
   @w_monto                money,
   @w_monto_mop            money,
   @w_return               int,
   @w_cuota_completa       char(1),
   @w_toperacion           catalogo,
   @w_moneda_op            tinyint,
   @w_oficina_op           smallint,
   @w_moneda_pago          tinyint,
   @w_monto_mn             money,
   @w_puente               catalogo,
   @w_cotizacion_mop       money,
   @w_tcotizacion_mop      char(1),
   @w_debito               char(1), -- Afectacion D
   @w_credito              char(1), -- Afectacion C  
   @w_tipo_op              char(1),
   @w_tipo_cobro           char(1),
   @w_banco                cuenta,
   @w_sec_recibo           int,
   @w_abd_concepto         catalogo,
   @w_cp_codvalor          int,
   @w_abd_monto_mpg        money,
   @w_abd_monto_mn         money,
   @w_abd_moneda           smallint,
   @w_abd_cotizacion_mpg   money,
   @w_abd_tcotizacion_mpg  char(1),
   @w_abd_cuenta           cuenta,
   @w_abd_beneficiario     descripcion,
   @w_nota_debito          char(1),
   @w_cp_categoria         catalogo,
   @w_mon_ext              char(1),
   @w_estado               catalogo,
   @w_gerente              smallint,
   @w_cp_codvalor_pte      smallint,
   @w_monto_dev            money,
   @w_monto_real           money,
   @w_abd_cod_banco        catalogo,
   @w_pcobis               int,
   @w_gar_admisible        char(1),
   @w_reestructuracion     char(1),
   @w_calificacion         catalogo, 
   @w_abd_cheque           int,
   @w_secuencial           int,
   @w_fecha_u_proceso      datetime,
   @w_moneda_nacional      tinyint,
   @w_cotizacion           money,
   @w_tipo_oficina_ifase   char(1),
   @w_oficina_ifase        int,
   @w_codvalor             int,
   @w_di_fecha_ven         datetime,
   @w_ab_oficina           int,
   @w_op_estado_cobranza   catalogo,
   @w_param_est_cobranza   catalogo,
   @w_monto_honabo         money,
   @w_param_prejuridico    catalogo,
   @w_tipocon              money,      -- ITO 10/02/2010
   @w_div_vigente          int,
   @w_abd_tipo             catalogo,
   @w_forma_pago           catalogo,
   @w_sec_acuerdo          int,        -- REQ 089 - ACUERDOS DE PAGO - 01/DIC/2010
   @w_secuencial_ing       int,        -- REQ 089 - ACUERDOS DE PAGO - 01/DIC/2010
   @w_cap_cond             money,      -- REQ 089 - ACUERDOS DE PAGO - 03/DIC/2010
   @w_int_cond             money,      -- REQ 089 - ACUERDOS DE PAGO - 03/DIC/2010
   @w_imo_cond             money,      -- REQ 089 - ACUERDOS DE PAGO - 03/DIC/2010
   @w_otr_cond             money,      -- REQ 089 - ACUERDOS DE PAGO - 03/DIC/2010
   @w_secuencial_tmp       money,      -- REQ 089 - ACUERDOS DE PAGO - 06/ENE/2011
   @w_cotizacion_mpg       MONEY,      -- REQ 089 - ACUERDOS DE PAGO - 06/ENE/2011
   @w_abd_cotizacion_mop   MONEY,
   @w_tipo_cambio          FLOAT,
   @w_cotiz_destino        float,
   @w_cot_usd              FLOAT,
   @w_factor               FLOAT,
   @w_op_cliente           INT,
   @w_moneda_dolar         INT,
   @w_vlr_cuota            MONEY,
   @w_diff                 MONEY,
   @w_aceptable            FLOAT
         
      
   -- CODIGO DE LA MONEDA LOCAL
   select @w_moneda_nacional = pa_tinyint
   from   cobis..cl_parametro
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'MLO'
   set transaction isolation level read uncommitted
   
   -- Codigo de moneda base para tipos de cambio (DOLAR)
   select @w_moneda_dolar = pa_tinyint
   from cobis..cl_parametro
   where pa_producto = 'ADM'
     and pa_nemonico = 'CDOLAR'
   
   
   --- LECTURA DEL PARAMETRO DE COBRANZA JURIDICA 
   select @w_param_est_cobranza =  pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'ESTJUR'
   and    pa_producto = 'CRE'
   set transaction isolation level read uncommitted
   
   --- LECTURA DEL PARAMETRO DE COBRANZA PREJURIDICA    
   select @w_param_prejuridico = pa_char
   from  cobis..cl_parametro
   where pa_nemonico = 'ESTCPR'
   and pa_producto = 'CRE'  
   set transaction isolation level read uncommitted
     

   --- VERIFICA QUE EL PARAMETRO EXISTA EN CATALOGOS DE COBRANZA JURIDICA                                                        
      if not exists (select 1 from cobis..cl_tabla T,                                                                            
                     cobis..cl_catalogo C                                                                                        
                     where T.tabla  = 'cr_estado_cobranza'                                                                       
                     and   T.codigo = C.tabla                                                                                    
                     and   C.codigo = @w_param_est_cobranza)                                                                     
         return 1850219  -- Si el @i_estado_cobranza no esta definido en el catalogo cr_estado_cobranza devuelve c¾digo de error                                                                                                                                
                                                                                                                                          
-- VARIABLES DE TRABAJO
select @w_debito  = 'D',
       @w_credito = 'C'

-- LECTURA DE ABONO
select @w_cuota_completa = ab_cuota_completa,
       @w_tipo_cobro     = ab_tipo_cobro,
       @w_sec_recibo     = ab_nro_recibo,
       @w_estado         = ab_estado,
       @w_ab_oficina     = ab_oficina
from   ca_abono
where  ab_secuencial_ing = @i_secuencial_ing
and    ab_operacion      = @i_operacionca

if @@rowcount = 0 
   return 701119

-- LECTURA DE LA OPERACION

select @w_toperacion         = op_toperacion,
       @w_moneda_op          = op_moneda,
       @w_oficina_op         = op_oficina,
       @w_tipo_op            = op_tipo,
       @w_banco              = op_banco,
       @w_gerente            = op_oficial,
       @w_gar_admisible      = op_gar_admisible,
       @w_reestructuracion   = op_reestructuracion,
       @w_calificacion       = op_calificacion,
       @w_fecha_u_proceso    = op_fecha_ult_proceso,
       @w_op_estado_cobranza = op_estado_cobranza,
       @w_op_cliente         = op_cliente
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount = 0 
   return 701025


--- DETERMINAR EL VALOR DE COTIZACION DEL DIA 
if @w_moneda_op = @w_moneda_nacional
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
        @i_moneda     = @w_moneda_op,
        @i_fecha      = @w_fecha_u_proceso,
        @o_cotizacion = @w_cotizacion output
end

-- GENERACION DE LA CUENTA PUENTE
select @w_puente = 'VAC' + convert(varchar,@w_moneda_op)

-- AFECTACION DE LA CUENTA
if @w_tipo_op = 'R' --Redescuento
begin
   select @w_debito = 'C',
   @w_credito = 'D'
end

-- LECTURA DE DECIMALES
exec @w_return = sp_decimales
     @i_moneda       = @w_moneda_op,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_n out

if @w_return <> 0 
begin
   --print 'regabono.sp Error saliendo de sp_decimales'
   return @w_return
end

-- INICIO - REQ 089 - ACUERDO DE PAGO - 30/NOV/2010
select 
@w_sec_acuerdo = ac_acuerdo,
@w_cap_cond    = ac_cap_cond, 
@w_int_cond    = ac_int_cond,
@w_imo_cond    = ac_imo_cond,
@w_otr_cond    = ac_otr_cond
from cob_credito..cr_acuerdo
where ac_banco                 = @w_banco
and   ac_estado                = 'V'                         -- NO ANULADOS
and   ac_fecha_proy            = (Select min(ac_fecha_proy) from cob_credito..cr_acuerdo where ac_banco = @w_banco and ac_estado = 'V')
and   ac_secuencial_rpa        is null

if @w_sec_acuerdo is not null
begin
   -- EVITA EL CICLO INFINITO
   update cob_credito..cr_acuerdo
   set ac_secuencial_rpa = 0 
   where ac_banco   = @w_banco
   and   ac_acuerdo = @w_sec_acuerdo
   
   if @@error <> 0
      return 2108039
      
   if @w_cap_cond > 0 or @w_int_cond > 0 or @w_imo_cond > 0 or @w_otr_cond > 0
   begin
      
      create table #cond_x_acuerdo(
      concepto      varchar(10)    not null,
      valor         money          not null  )
      
      exec @w_return = sp_rubro_cond_ac
      @i_operacionca  = @i_operacionca,
      @i_sec_acuerdo  = @w_sec_acuerdo,
      @i_decimales    = @w_num_dec
      
      if @w_return <> 0
         return @w_return
      
      -- VALOR COTIZACION MONEDA DE PAGO 
      -- LA MONEDA DE PAGO ES IGUAL A LA DE LA OPERACION YA QUE LOS MONTOS DE CONDONACION 
      -- SON PORCENTAJES DE LOS SALDOS DE RUBROS DE LA OPERACION
      exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda_op,
      @i_fecha      = @w_fecha_u_proceso,
      @o_cotizacion = @w_cotizacion_mpg  out
      
      update ca_abono_det set
      abd_beneficiario = isnull(nullif(rtrim(ltrim(abd_beneficiario)), '') + '/', '') + 'PREMIO DE ACUERDO',
      abd_monto_mpg    = abd_monto_mpg + valor,
      abd_monto_mop    = abd_monto_mop + valor,
      abd_monto_mn     = abd_monto_mn  + valor * @w_cotizacion_mpg
      from #cond_x_acuerdo
      where abd_operacion      = @i_operacionca
      and   abd_secuencial_ing = @i_secuencial_ing
      and   abd_tipo           = 'CON'
      and   abd_concepto       = concepto
      
      if @@error <> 0 
         return 705047
      
      delete #cond_x_acuerdo
      from ca_abono_det
      where abd_operacion      = @i_operacionca
      and   abd_secuencial_ing = @i_secuencial_ing
      and   abd_tipo           = 'CON'
      and   abd_concepto       = concepto 
         
      insert into ca_abono_det(
      abd_secuencial_ing,    abd_operacion,                abd_tipo,                 abd_concepto,       
      abd_cuenta,            abd_beneficiario,             abd_monto_mpg,            abd_monto_mop,      
      abd_cotizacion_mpg,    abd_cotizacion_mop,           abd_moneda,               abd_monto_mn,
      abd_tcotizacion_mpg,   abd_tcotizacion_mop,          abd_cheque,               abd_cod_banco,
	  abd_solidario)                                                                                     --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
      select
      @i_secuencial_ing,     @i_operacionca,               'CON',                    concepto, 
      '',                    'PREMIO DE ACUERDO',          valor,                    valor,
      @w_cotizacion_mpg,     @w_cotizacion_mpg,            @w_moneda_op,             valor * @w_cotizacion_mpg, 
      'N',                   'N',                          0,                        '',
	  'N'
      from #cond_x_acuerdo
      
      if @@error <> 0 
         return 710295
  
   end
end
-- FIN - REQ 089 - ACUERDO DE PAGO - 30/NOV/2010

-- LECTURA DETALLE DE ABONO
select @w_moneda_pago   = abd_moneda,
       @w_abd_concepto  = abd_concepto,
       @w_abd_monto_mpg = abd_monto_mpg,
       @w_abd_monto_mn  = abd_monto_mn,
       @w_abd_tipo      = abd_tipo,
       @w_monto_mop     = abd_monto_mop,          --LPO CDIG Multimoneda Ajuste por decimales
       @w_abd_cotizacion_mop = abd_cotizacion_mop --LPO CDIG Multimoneda Ajuste por decimales
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca
and    (abd_tipo = 'PAG')

if @@rowcount = 0 
begin
   --print 'regabono.sp Error leyendo detalle abono' 
   return 701119 
end

--PRINT '@w_abd_monto_mn QQ ' + CAST(@w_abd_monto_mn AS VARCHAR)
--RETURN 222

--LPO CDIG Multimoneda Ajuste del Monto en Moneda Nacional por Decimales INICIO
SELECT @w_abd_monto_mn = @w_monto_mop * @w_abd_cotizacion_mop

update ca_abono_det
set abd_monto_mn = @w_abd_monto_mn
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca
and    abd_tipo           in  ('PAG')
--LPO CDIG Multimoneda Ajuste del Monto en Moneda Nacional por Decimales FIN


if not exists (select 1 from ca_concepto where co_concepto = @w_abd_concepto)
begin
   select @w_cp_categoria = cp_categoria
   from   ca_producto
   where  cp_producto = @w_abd_concepto 
   if @@rowcount = 0 
   begin
      --print 'concepto' + @w_abd_concepto
      return 701119 
   end
end


select @w_nota_debito = 'N'

if @w_cp_categoria in ('NDAH','NDCC')  
   select @w_nota_debito = 'S'

if @w_moneda_pago <> 0
   select @w_mon_ext = 'S'
   
--Se obtiene categoria para comprobar licitud
select @w_cp_categoria = cp_categoria
from   ca_producto
where  cp_producto = @w_abd_concepto 

if not exists (select 1 from cobis..cl_tabla t, cobis..cl_catalogo c
                    where t.codigo = c.tabla
                    and t.tabla = 'ca_categoria_fp_licitud'
					and c.valor = @w_cp_categoria)
   select @i_aplica_licitud = 'N'

-- DETERMINACION DEL MONTO A PAGAR
if @w_cuota_completa = 'S' and @w_tipo_op  not in ('R','V')
begin
   -- CONSULTAR LA CUOTA A PAGAR
   if @i_dividendo = 0
   begin
      select @i_dividendo = min(di_dividendo)
      from   ca_dividendo
      where  di_operacion = @i_operacionca
      and    di_estado = 1
   end
   
   select @w_di_fecha_ven = min(di_fecha_ven)
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_estado = 1

   if @@rowcount = 0 or  @w_di_fecha_ven <>  @i_fecha_proceso
      return 710496
      
   exec @w_return = sp_consulta_cuota
        @i_en_linea      = @i_en_linea,
        @i_operacionca   = @i_operacionca,
        @i_moneda        = @w_moneda_op,  --Antes @w_moneda_pago
        @i_tipo_cobro    = @w_tipo_cobro,
        @i_fecha_proceso = @i_fecha_proceso,
        @i_nota_debito   = @w_nota_debito,
        @i_mon_ext       = @w_mon_ext,
        @i_dividendo     = @i_dividendo,
        @i_tipo_op       = @w_tipo_op,
        @o_monto         = @w_monto out
   
   if @w_return <> 0
   begin
      if @w_return = 710130
      begin
         update ca_abono
         set    ab_estado     = 'E'
         where  ab_secuencial_ing = @i_secuencial_ing
         and    ab_operacion = @i_operacionca

         if @@error <> 0 
	 	 begin
		   --PRINT 'regabono.sp Error Actualizando  ca_abono_det Estado E'
		   return 708152
		 end            
      end
      
      return @w_return 
   end
   
   /* KDR - Se comenta
   if @w_tipo_op = 'D'
   begin
      select @w_monto_dev = isnull(sum(abd_monto_mop), 0)
      from   ca_abono_det
      where  abd_secuencial_ing = @i_secuencial_ing
      and    abd_operacion      = @i_operacionca
      and    abd_tipo = 'DEV'
      
      select @w_monto = @w_monto - @w_monto_dev
   end
   
   
   --LPO CDIG Multimoneda INICIO

   --OBTENER COTIZACION DE LA MONEDA DE PAGO A LA MONEDA DE LA OPERACION
   exec @w_return = cob_cartera..sp_consulta_divisas
      @s_date                = @s_date,
      @t_trn                 = 77541,
      @i_operacion           = 'C', -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
      @i_cot_contable        = 'N', -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables
      @i_moneda_origen       = @w_moneda_pago,
      @i_valor               = @w_monto,
      @i_moneda_destino      = @w_moneda_op,
      @o_cotizacion          = @w_abd_cotizacion_mpg OUT
      --@o_valor_convertido    = @w_monto out,
      
   if @w_return <> 0
      return @w_return
   
   
   EXEC @w_return = cob_cartera..sp_qr_pagos
   @s_date                     = @s_date,
   @i_banco                    = '',
   @i_formato_fecha            = 101,
   @i_operacion                = 'P',
   @i_moneda_op                = @w_moneda_op,
   @i_monto_prec_moneda_op     = @w_monto,
   @i_moneda_pago              = @w_moneda_pago,
   @i_monto_prec_moneda_op     = @w_monto,
   @i_cotizacion               = @w_abd_cotizacion_mpg, --LPO CDIG Multimoneda , se respeta la cotizacion de la moneda del pago obtenida antes
   @o_monto_prec_moneda_pago   = @w_abd_monto_mpg OUT, --LPO CDIG Multimoneda Monto en Moneda del Pago
   @o_tipo_cambio              = @w_tipo_cambio OUT,
   @o_cotiz_destino            = @w_abd_cotizacion_mop OUT, --LPO CDIG Cotizacion de la Moneda de la Operacion vs la Moneda Nacional
   @o_cot_usd                  = @w_cot_usd OUT,
   @o_factor                   = @w_factor OUT,
   @o_tipo_op                  = @w_tipo_op OUT
   
   if @w_return <> 0
      return @w_return
   
   IF @w_moneda_op = @w_moneda_nacional
      SELECT @w_abd_monto_mn = @w_monto
   ELSE
      SELECT @w_abd_monto_mn = @w_monto * @w_abd_cotizacion_mpg
   
   
   IF @w_moneda_pago <> @w_moneda_nacional
   BEGIN
   
      exec @w_return  = cob_cartera..sp_op_divisas_automatica
      @s_date             = @s_date,
      @s_user             = @s_user,
      @s_ssn              = @s_ssn,  --@w_dtr_sec,
      @i_oficina          = @s_ofi,
      @i_cliente          = @w_op_cliente,
      @i_modulo           = 'CCA',
      @i_concepto         = 'PAG',
      @i_operacion        = 'E',
-->               @i_operacion        = 'C',
-->               @i_cot_contable     = 'N',
      
      @i_moneda_origen    = @w_moneda_pago,    --Moneda Pago
      @i_valor            = @w_abd_monto_mpg,  --Monto en Moneda Operacion
      @i_moneda_destino   = @w_moneda_op,      --Moneda Desembolso
      @i_empresa          = 1,                 --C=digo de la empresa
      @i_num_operacion    = @w_banco,          --Numero de la cuenta, DPF ,operaci=n de cartera, cex, etc sobre la que se realiza la transacci=n					    
      --**               @o_cotizacion       = @w_dm_cotizacion_mds out,
      @o_cotizacion       = @w_abd_cotizacion_mop out, --Cotizacion de la Moneda de la OPeracion en relacion a la moneda Local
      @o_valor_convertido = @w_monto OUT
      --@o_msg_error        = @w_msg out,
      --@o_tipo_op          = @w_dm_tcotizacion_mop out
      
      if @w_return <> 0
         return @w_return
      
      insert into ca_tran_divisas (trd_secuencial,trd_operacion,trd_sec_divisas,trd_tran)
      values (@i_secuencial_ing, @i_operacionca, @s_ssn,'PAG')
      
      if @@error <> 0 
         RETURN 710107
   END
   --LPO CDIG Multimoneda FIN   
   */ -- Fin KDR Se comenta
   
   -- ACTUALIZACION DE LA INFORMACION DE CA_ABONO_DET
   update ca_abono_det
   set    --abd_monto_mpg      = @w_abd_monto_mpg,
          abd_monto_mop      = @w_monto
          --abd_cotizacion_mop = @w_abd_cotizacion_mop, --@w_cot_moneda,
          --abd_monto_mn       = @w_abd_monto_mn,
          --abd_cotizacion_mpg = @w_abd_cotizacion_mpg
   where  abd_secuencial_ing = @i_secuencial_ing
   and    abd_operacion      = @i_operacionca
   and    abd_tipo           in  ('PAG')   

   if @@error <> 0 
   begin
	  --PRINT 'regabono.sp Error Actualizando  ca_abono_det Montos Cuota Completa'
	  return 708152
   end
--PRINT 'Despues ca_abono_det'
end

/* KDR Se comenta
---PARA CONDONACIONES NO SE ESTA GENERANDO EL HISTORICO
---DEBE GENERARSE EN ESTE PUNTO PARA PORDER REVERSAR EN UN CASO DADO
-- OBTENER RESPALDO ANTES DE LA APLICACION DEL PAGO
if @w_abd_tipo = 'CON' 
begin
  
   if @i_secuencial_pag is null
   begin
   
      ---EL secuencial_pag para las condonaciones viene cargado
      ---pero si se ejecutan desde la sarta 7070 no se envia este 
      ---secuencial por tanto se saca aca a que las condonaciones
      ---son pocas
      
      select @i_secuencial_pag = ab_secuencial_pag
      from ca_abono
      where ab_operacion      = @i_operacionca
      and   ab_secuencial_ing = @i_secuencial_ing
      
      if @i_secuencial_pag = 0 or @i_secuencial_pag is null
      return  710106
      
   end

   	exec @w_return  = sp_historial
	@i_operacionca  = @i_operacionca,
	@i_secuencial   = @i_secuencial_pag
	
	if @w_return <> 0 return @w_return
	
end */ -- Fin KDR Se comenta

-- GENERACION DEL SECUENCIAL DEL REGISTRO DEL PAGO
exec @w_secuencial_rpa = sp_gen_sec
     @i_operacion      = @i_operacionca

select @o_secuencial_rpa = @w_secuencial_rpa

/* VERIFICA SI DEBE COBRAR HONORARIOS DE ABOGADO - OTROS CARGOS */
if exists (select 1 from cob_credito..cr_hono_mora   -- INI JAR REQ 230
            where hm_estado_cobranza = @w_op_estado_cobranza) and @w_abd_tipo <> 'CON'
begin
    
    select @w_forma_pago = abd_concepto
    from ca_abono_det
    where abd_operacion = @i_operacionca
    and   abd_secuencial_ing = @i_secuencial_ing
   
    
	if not exists (select 1 from cobis..cl_catalogo c
	  where c.tabla in (select codigo from cobis..cl_tabla
	                    where tabla = 'ca_fpago_sin_honorarios')
	and c.codigo = @w_forma_pago
	and c.estado = 'V')
	begin
	    exec @w_return          = sp_calculo_honabo
	         @s_user            = @s_user,           --Usuario de conexion
	         @s_ofi             = @s_ofi,            --Oficina del pago (si es por front es la de conexion)
	         @s_term            = @s_term,           --Terminal de operacion
	         @s_date            = @s_date,           --ba_fecha_proceso
	         @i_operacionca     = @i_operacionca,    --op_operacion de la operacion
	         @i_toperacion      = @w_toperacion,     --op_toperacion de la operacion
	         @i_moneda          = @w_moneda_op,      --op_moneda de la operacion
	         @i_monto_mpg       = @w_abd_monto_mpg   --Monto del pago que sera utilizado para el calculo de honabo
	      if @w_return <> 0
	         return @w_return
     end
end     


--LPO CDIG Multimoneda INICIO
--OBTENER COTIZACION DE LA MONEDA DE PAGO A LA MONEDA DE LA OPERACION
--/*--LPO AQUI DESCOMENTAR para actualizar cotizaciones INICIO

exec @w_return = cob_cartera..sp_consulta_divisas
   @s_date                = @s_date,
   @t_trn                 = 77541,
   @i_operacion           = 'C', -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
   @i_cot_contable        = 'N', -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables
   @i_moneda_origen       = @w_moneda_op, --@w_moneda_pago,
   @i_valor               = @w_abd_monto_mpg,--***
   @i_moneda_destino      = @w_moneda_pago, --@w_moneda_op,
   @o_cotizacion          = @w_abd_cotizacion_mpg out,  
   @o_cot_usd             = @w_cot_usd OUT,
   @o_factor              = @w_factor OUT       -- Factor de relacion de la moneda respecto al dolar(Tesoreria/Contabilidad)    
   --@o_valor_convertido    = @w_monto OUT
        
   if @w_return <> 0
      return @w_return
      
   if @w_moneda_pago <> @w_moneda_op
   BEGIN      
      if @w_moneda_pago = @w_moneda_nacional OR @w_moneda_op = @w_moneda_nacional
      BEGIN
         --select @w_monto = @w_monto --es el monto pagado convertido en monto en la moneda de la operacion
         --select @w_abd_monto_mpg = @w_abd_monto_mpg --es el monto pagado
         
         if @w_moneda_pago = @w_moneda_nacional
         begin
            select @w_abd_cotizacion_mpg = 1.0 --cotizacion de la moneda del pago vs. la moneda nacional
            select @w_abd_cotizacion_mop = @w_abd_cotizacion_mpg
            select @w_abd_monto_mn = @w_abd_monto_mpg  --@w_monto = @w_abd_monto_mpg  / @w_abd_cotizacion_mpg
            SELECT @w_monto = @w_abd_monto_mpg  / @w_abd_cotizacion_mpg
         end
         
         if @w_moneda_op = @w_moneda_nacional
         begin
            select @w_abd_cotizacion_mop = 1.0
            select @w_abd_cotizacion_mpg = @w_abd_cotizacion_mpg
            select @w_abd_monto_mn = @w_abd_monto_mpg  * @w_abd_cotizacion_mpg       
            SELECT @w_monto = @w_abd_monto_mpg  * @w_abd_cotizacion_mpg
         end
         
      end            
      
      IF @w_moneda_pago <> @w_moneda_nacional AND @w_moneda_op <> @w_moneda_nacional  --MONEDAS DIFERENTES Y NINGUNA ES LA NACIONAL, ENTONCES ES ARBITRAJE
      BEGIN
      
         --sp_qr_pagos para obtener el o_factor
         
         if @w_moneda_pago <> @w_moneda_dolar
         begin
            select @w_abd_cotizacion_mop = @w_cot_usd
            select @w_abd_cotizacion_mpg = @w_abd_cotizacion_mpg
            select @w_abd_monto_mn = @w_abd_monto_mpg * @w_cot_usd    --@w_monto = @w_abd_monto_mpg  * o_factor            
            SELECT @w_monto = @w_abd_monto_mpg  * @w_factor
         end
         else
         begin
            select @w_abd_cotizacion_mop = @w_abd_cotizacion_mpg
            select @w_abd_cotizacion_mpg = @w_cot_usd
            select @w_abd_monto_mn = @w_abd_monto_mpg * @w_cot_usd
            --@w_monto = @w_abd_monto_mpg  / o_factor            
            SELECT @w_monto = @w_abd_monto_mpg  / @w_factor
         end
      end
   end
   else  --Monedas iguales
   begin
      select @w_monto = @w_abd_monto_mpg --@w_monto --el mismo monto de la operacion
      select @w_abd_cotizacion_mpg = @w_abd_cotizacion_mpg --cotizacion de la moneda del pago vs. la moneda nacional
      select @w_abd_cotizacion_mop = @w_abd_cotizacion_mpg --es la misma cotizacion por ser la misma moneda
      select @w_abd_monto_mn = @w_abd_monto_mpg * @w_abd_cotizacion_mpg --monto en moneda nacional es el monto en moneda de la operacion por la cotizacion de la moneda de la operacion vs la moneda nacional
   end
   
   select @w_vlr_cuota = sum(am_cuota + am_gracia - am_pagado)
   from  ca_operacion, ca_dividendo,ca_amortizacion
   where op_operacion = @i_operacionca
   and   di_operacion = op_operacion
   and   di_estado    in (1,2)
   and   am_operacion = op_operacion
   and   am_dividendo = di_dividendo
   GROUP BY op_moneda
   
   --select @w_diff  = @w_vlr_cuota - @w_monto
   select @w_diff  = @w_monto - @w_vlr_cuota
   
   SELECT @w_aceptable = 1/ 10.0
      
   --if (abs (@w_diff) <= @w_aceptable)
   /* -- KDR 08/07/2021 Se comenta sección para que abono se aplique sin descontar valores aceptables
   if (@w_diff >= 0 and @w_diff <= @w_aceptable) --Solo cuando lo pagado es un poco mas del valor de la cuota se ajusta al valor de la cuota, 
                                                 --no se ajusta cuando se paga menos del valor de la cuota
   BEGIN
      SELECT @w_monto = @w_vlr_cuota
   END 
   */   
      
/*   IF @w_moneda_op = @w_moneda_nacional
      SELECT @w_abd_monto_mn = @w_monto
   ELSE
      SELECT @w_abd_monto_mn = @w_monto * @w_abd_cotizacion_mpg
*/   
   
   IF @w_moneda_pago <> @w_moneda_nacional
   BEGIN
   
      exec @w_return  = cob_cartera..sp_op_divisas_automatica
      @s_date             = @s_date,
      @s_user             = @s_user,
      @s_ssn              = @s_ssn,  --@w_dtr_sec,
      @i_oficina          = @s_ofi,
      @i_cliente          = @w_op_cliente,
      @i_modulo           = 'CCA',
      @i_concepto         = 'PAG',
      @i_operacion        = 'E',
-->               @i_operacion        = 'C',
-->               @i_cot_contable     = 'N',

      @i_moneda_origen    = @w_moneda_pago,    --Moneda Pago
      @i_valor            = @w_abd_monto_mpg,  --Monto en Moneda Operacion
      @i_moneda_destino   = @w_moneda_op,      --Moneda Desembolso
      @i_empresa          = 1,                 --C=digo de la empresa
      @i_num_operacion    = @w_banco--,          --Numero de la cuenta, DPF ,operaci=n de cartera, cex, etc sobre la que se realiza la transacci=n					    
      --**               @o_cotizacion       = @w_dm_cotizacion_mds out,
      ----@o_cotizacion       = @w_abd_cotizacion_mop out, --Cotizacion de la Moneda de la OPeracion en relacion a la moneda Local
      ----@o_valor_convertido = @w_monto OUT
      --@o_msg_error        = @w_msg out,
      --@o_tipo_op          = @w_dm_tcotizacion_mop out
      
      if @w_return <> 0
         return @w_return
      
      insert into ca_tran_divisas (trd_secuencial,trd_operacion,trd_sec_divisas,trd_tran)
      values (@i_secuencial_ing, @i_operacionca, @s_ssn,'PAG')
      
      if @@error <> 0 
         RETURN 710107
   END
   
--*/
--LPO AQUI DESCOMENTAR para actualizar cotizaciones FIN

/*  
-- CONVERSION DEL MONTO EN MONEDA DEL PAGO A MONEDA NACIONAL
exec @w_return = sp_conversion_moneda
@s_date             = @s_date,
@i_opcion           = 'L',
@i_operacion        = 'C', -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
@i_cot_contable     = 'N', -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables
@i_moneda_monto     = @w_moneda_pago, --@w_moneda_n,
@i_monto            = @w_abd_monto_mpg, --@w_abd_monto_mn,
@i_moneda_resultado = @w_moneda_n,    --@w_abd_moneda,
@i_fecha            = @i_fecha_proceso,
@o_monto_resultado  = @w_abd_monto_mn OUT, -- @w_abd_monto_mpg out,
@o_tipo_cambio      = @w_abd_cotizacion_mpg out
         
if @w_return <> 0
begin
   return @w_return
end

-- CONVERSION DEL MONTO EN MONEDA DE LA OPERACION A LA MONEDA NACIONAL
--(Se hace esto solo para obtener la cotizacìon de la moneda de la operacion versus la moneda nacional, 
--el monto en moneda nacional ya lo tenemos)
exec @w_return = sp_conversion_moneda
@s_date             = @s_date,
@i_opcion           = 'L',
@i_operacion        = 'C', -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
@i_cot_contable     = 'N', -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables
@i_moneda_monto     = @w_moneda_op, --@w_moneda_n,
@i_monto            = @w_abd_monto_mpg, --@w_monto, --@w_abd_monto_mn,
@i_moneda_resultado = @w_moneda_n,
@i_fecha            = @i_fecha_proceso,
--@o_monto_resultado  = @w_monto out,
@o_tipo_cambio      = @w_cot_moneda out

if @w_return <> 0 
begin
   return @w_return
END

--Monto en la Moneda de la Operacion:
SELECT @w_monto = @w_abd_monto_mpg * @w_abd_cotizacion_mpg / @w_cot_moneda
*/

/*
-- CONVERSION DEL MONTO EN MONEDA DEL PAGO A MONEDA DE LA OPERACION
--(No se obtiene el tipo de cambio porque no tendrìamos la cotizacìon de la moneda del pago versus la moneda nacional,
--sino la cotizacion entre la moneda delpago versus la operacion)
exec @w_return = sp_conversion_moneda
@s_date             = @s_date,
@i_opcion           = 'L',
@i_operacion        = 'C', -- C - Consulta, E - Ejecuci=n normal , R - Reversar una operaci=n anterior
@i_cot_contable     = 'N', -- Se usa solo en @i_operacion = 'C' para tomar cotizaciones contables
@i_moneda_monto     = @w_moneda_pago, --@w_moneda_n,
@i_monto            = @w_abd_monto_mpg, --@w_abd_monto_mn,
@i_moneda_resultado = @w_moneda_op,
@i_fecha            = @i_fecha_proceso,
@o_monto_resultado  = @w_monto out--,
--@o_tipo_cambio      = @w_cot_moneda out
         
if @w_return <> 0 
begin
   return @w_return
end
*/

----------*****************select @w_abd_tcotizacion_mpg = 'N'
--/****************** LPO AQUI DESCOMENTAR para actualizar cotizaciones INICIO
-- ACTUALIZACION DE LA INFORMACION DE CA_ABONO_DET
update ca_abono_det
set    abd_monto_mpg      = @w_abd_monto_mpg,
       abd_monto_mop      = @w_monto,
       abd_cotizacion_mop = @w_abd_cotizacion_mop, --@w_cot_moneda,
       abd_monto_mn       = @w_abd_monto_mn,
       abd_cotizacion_mpg = @w_abd_cotizacion_mpg
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca
and    abd_tipo           = 'PAG'

if @@error <> 0 
begin
   --PRINT 'regabono.sp Error Actualizando  ca_abono_det Montos'
   return 708152
end           
--*/
--LPO AQUI DESCOMENTAR para actualizar cotizaciones FIN
--LPO CDIG Multimoneda FIN


-- INGRESO DEL DETALLE DE LA TRANSACCION
declare cursor_detalle cursor
for select abd_concepto,                    isnull(cp_codvalor,0),   abd_monto_mpg,
               abd_monto_mn,                abd_moneda,              abd_cotizacion_mpg,
               abd_tcotizacion_mpg,         isnull(abd_cuenta,''),   isnull(abd_beneficiario,''), 
               isnull(abd_cod_banco,''),    abd_cheque
       from   ca_abono_det left outer join ca_producto on abd_concepto = cp_producto
       where  abd_secuencial_ing = @i_secuencial_ing
       and    abd_operacion      = @i_operacionca
       and    abd_tipo           in ('PAG','SOB')  --TIPO: CON (no se considera) CONDONACION NO INCLUYE DETALLE DE TRN EN RPA
       for read only

       open cursor_detalle
fetch cursor_detalle
into  @w_abd_concepto,        @w_cp_codvalor,
      @w_abd_monto_mpg,       @w_abd_monto_mn,        @w_abd_moneda,
      @w_abd_cotizacion_mpg,  @w_abd_tcotizacion_mpg, @w_abd_cuenta,
      @w_abd_beneficiario,    @w_abd_cod_banco,       @w_abd_cheque

while @@fetch_status = 0
begin
   if @@fetch_status = -1 
   begin
      close cursor_detalle
      deallocate cursor_detalle
      return 710004
   end
   
   if @w_estado <> 'P'
   begin
      -- AFECTACION A OTROS PRODUCTOS
      select @w_pcobis   = isnull(cp_pcobis,0),
             @w_codvalor = cp_codvalor
      from   ca_producto
      where  cp_producto = @w_abd_concepto
      
      if @w_pcobis in (3,4,19) and  @w_abd_monto_mn > 0
      begin
         select @w_oficina_ifase = @s_ofi
         
         select @w_tipo_oficina_ifase = dp_origen_dest
         from   ca_trn_oper, cob_conta..cb_det_perfil
         where  to_tipo_trn = 'RPA'
         and    to_toperacion = @w_toperacion
         and    dp_empresa    = 1
         and    dp_producto   = 7
         and    dp_perfil     = to_perfil
         and    dp_codval     = @w_codvalor
         
         if @@rowcount = 0
         begin
            close cursor_detalle
            deallocate cursor_detalle
            return 710446
         end
         
         if @w_tipo_oficina_ifase = 'C'
         begin
            select @w_oficina_ifase = pa_int
            from   cobis..cl_parametro
            where  pa_nemonico = 'OFC'
            and    pa_producto = 'CON'
            set transaction isolation level read uncommitted
         end
         
         if @w_tipo_oficina_ifase = 'D'
         begin
            select @w_oficina_ifase = @w_oficina_op
         END

--LPO CDIG Multimoneda INICIO
         exec @w_return = sp_afect_prod_cobis
              @s_user          = @s_user,
              @s_term          = @s_term,
              @s_date          = @s_date,
              @s_ssn           = @s_ssn,
              @s_sesn          = @s_sesn,
              @s_srv           = @s_srv,
              @s_ofi           = @w_oficina_ifase,
              @i_fecha         = @i_fecha_proceso,
              @i_cuenta        = @w_abd_cuenta,
              @i_producto      = @w_abd_concepto,
              @i_monto         = @w_abd_monto_mpg, --LPO CDIG Multimoneda --@w_abd_monto_mn, --Antes @w_abd_monto_mpg
              @i_beneficiario  = @w_abd_beneficiario,
              @i_no_cheque     = @w_abd_cheque,   ---Antes @i_no_cheque se saca del cursor ya que por concectate puede quedar ING,  
              @i_mon           = @w_moneda_pago,
              @i_operacionca   = @i_operacionca,
              @i_abd_cod_banco = @w_abd_cod_banco,
              @i_en_linea      = @i_en_linea,
              @i_alt           = @i_operacionca,
              @i_sec_tran_cca  = @w_secuencial_rpa,  -- FCP Interfaz Ahorros
              @o_monto_real    = @w_monto_real out,
              @o_secuencial    = @w_secuencial out
         
         if @w_return <> 0
         begin
            --- PRINT 'regabono.sp salio por error de afpcobis.sp' 
            close cursor_detalle
            deallocate cursor_detalle
            return @w_return
         end
      
--LPO CDIG Multimoneda FIN

      
--LPO CDIG Multimoneda. Se comenta INICIO
/*

      -- VALIDACION DEL MONTO DEBITADO
      if @w_abd_monto_mn > @w_monto_real
      begin
         select @w_abd_monto_mn = @w_monto_real
         
         -- CONVERSION DEL MONTO CALCULADO A LA MONEDA DE PAGO Y OPERACION
         exec @w_return = sp_conversion_moneda
              @s_date             = @s_date,
              @i_opcion           = 'L',
              @i_moneda_monto     = @w_moneda_n,
              @i_moneda_resultado = @w_abd_moneda,
              @i_monto            = @w_abd_monto_mn,
              @i_fecha            = @i_fecha_proceso,
              @o_monto_resultado  = @w_abd_monto_mpg out,
              @o_tipo_cambio      = @w_abd_cotizacion_mpg out
         
         if @w_return <> 0
         begin
            close cursor_detalle
            deallocate cursor_detalle
            return @w_return
         end 
         
         exec @w_return = sp_conversion_moneda
              @s_date             = @s_date,
              @i_opcion           = 'L',
              @i_moneda_monto     = @w_moneda_n,
              @i_moneda_resultado = @w_moneda_op,
              @i_monto            = @w_abd_monto_mn,
              @i_fecha            = @i_fecha_proceso,
              @o_monto_resultado  = @w_monto out,
              @o_tipo_cambio      = @w_cot_moneda out
         
         if @w_return <> 0 
         begin
            close cursor_detalle
            deallocate cursor_detalle
            return @w_return
         end 
         
         select @w_abd_tcotizacion_mpg = 'N'
         
         -- ACTUALIZACION DE LA INFORMACION DE CA_ABONO_DET
         update ca_abono_det
         set    abd_monto_mpg      = @w_abd_monto_mpg,
                abd_monto_mop      = @w_monto,
                abd_cotizacion_mop = @w_cot_moneda,
                abd_monto_mn       = @w_abd_monto_mn,
                abd_cotizacion_mpg = @w_abd_cotizacion_mpg
         where  abd_secuencial_ing = @i_secuencial_ing
         and    abd_operacion      = @i_operacionca
         and    abd_tipo           = 'PAG'

       	if @@error <> 0 
		begin
           close cursor_detalle
           deallocate cursor_detalle
           PRINT 'regabono.sp Error Actualizando  ca_abono_det Montos'
		   return 708152
           
		end           
*/
--LPO CDIG Multimoneda. Se comenta FIN

      end
   end
  
   -- INSERCION DEL DETALLE DE LA TRANSACCION
   insert into ca_det_trn
         (dtr_secuencial,        dtr_operacion,          dtr_dividendo,
          dtr_concepto,
          dtr_estado,            dtr_periodo,            dtr_codvalor,
          dtr_monto,             dtr_monto_mn,           dtr_moneda,
          dtr_cotizacion,        dtr_tcotizacion,        dtr_afectacion,
          dtr_cuenta,            dtr_beneficiario,       dtr_monto_cont)
   values(@w_secuencial_rpa,     @i_operacionca,         -1,
          @w_abd_concepto,
          0,                     0,                      @w_cp_codvalor,
          @w_abd_monto_mpg,      @w_abd_monto_mn,        @w_abd_moneda,
          @w_abd_cotizacion_mpg, @w_abd_tcotizacion_mpg, @w_debito,
          @w_abd_cuenta,         @w_abd_beneficiario,    0)
   
   if @@error <> 0 
   begin
       close cursor_detalle
       deallocate cursor_detalle
       return 710031
   end 
   
   fetch cursor_detalle
   into  @w_abd_concepto,        @w_cp_codvalor,
         @w_abd_monto_mpg,       @w_abd_monto_mn,        @w_abd_moneda,
         @w_abd_cotizacion_mpg,  @w_abd_tcotizacion_mpg, @w_abd_cuenta,
         @w_abd_beneficiario,    @w_abd_cod_banco,       @w_abd_cheque
end -- CURSOR

close cursor_detalle
deallocate cursor_detalle


-- INSERTAR CUENTA PUENTE PARA LA APLICACION DEL PAGO
select @w_monto_mop = isnull(sum(abd_monto_mop), 0),
       @w_monto_mn  = isnull(sum(abd_monto_mn), 0)
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca
and    abd_tipo in ('PAG','SOB') 


if @w_monto_mop > 0 or @w_monto_mn > 0
begin
   select @w_cp_codvalor_pte = cp_codvalor
   from   ca_producto
   where  cp_producto = @w_puente 
   
   select @w_cotizacion_mop  = abd_cotizacion_mop,
          @w_tcotizacion_mop = abd_tcotizacion_mop
   from   ca_abono_det
   where  abd_secuencial_ing = @i_secuencial_ing
   and    abd_operacion      = @i_operacionca
   and    abd_tipo in ('PAG')


   if @w_tipocon > 0
   select @w_monto_mop = @w_tipocon

   insert into ca_det_trn
         (dtr_secuencial,     dtr_operacion,       dtr_dividendo,
          dtr_concepto,       dtr_estado,          dtr_periodo,
          dtr_codvalor,       dtr_monto,           dtr_monto_mn,
          dtr_moneda,         dtr_cotizacion,      dtr_tcotizacion,
          dtr_afectacion,     dtr_cuenta,          dtr_beneficiario,
          dtr_monto_cont)
   values(@w_secuencial_rpa,  @i_operacionca,      0,
          @w_puente,          0,                   0,
          @w_cp_codvalor_pte, @w_monto_mop,        (@w_monto_mop * @w_cotizacion_mop), --@w_monto_mn, --LPO CDIG Multimoneda
          @w_moneda_op,       @w_cotizacion_mop,   @w_tcotizacion_mop,
          @w_credito,         '',                  '',
          0)
   
   if @@error <> 0 
   begin 
      --print 'regabono.sp error insertando en ca_det_trn' 
      return 710036  
   end 
end

-- INGRESO DE LA TRANSACCION DEL RPA
insert ca_transaccion
      (tr_fecha_mov,                   tr_toperacion,              tr_moneda,
       tr_operacion,                   tr_tran,                    tr_secuencial,
       tr_en_linea,                    tr_banco,                   tr_ofi_oper,
       tr_ofi_usu,                     tr_usuario,                 tr_terminal,
       tr_estado,                      tr_dias_calc,               tr_fecha_ref,
       tr_secuencial_ref,              tr_gerente,                 tr_gar_admisible, 
       tr_reestructuracion,            tr_calificacion,            tr_observacion,
       tr_comprobante,                 tr_fecha_cont)
values(@s_date,                        @w_toperacion,              @w_moneda_op,
       @i_operacionca,                 'RPA',                      @w_secuencial_rpa,
       @i_en_linea,                    @w_banco,                   @w_oficina_op,
       @w_ab_oficina,                  @s_user,                    isnull(@s_term,'consola'),
       'ING',                          @i_secuencial_ing, /*@w_sec_recibo,*/ @w_fecha_u_proceso,
       0,                              @w_gerente,                 isnull(@w_gar_admisible,''),
       isnull(@w_reestructuracion,''), isnull(@w_calificacion,''), '',
       0,                              @s_date)

if @@error <> 0 
begin
   --PRINT 'regabono.sp Error en Insert ca_transaccion 1'
   return 710030
end   

/* REQ 089 - ACUERDOS DE PAGO - SE TRASLADA APLICACION DE CONDONACION EN EL ABONO CARTERA
if exists(select 1 from ca_abono_det
where  abd_operacion = @i_operacionca
and    abd_secuencial_ing = @i_secuencial_ing
and    abd_tipo = 'CON')
begin
    --**********  ITO 11/02/2010*********    

	insert ca_transaccion
	      (tr_fecha_mov,                   tr_toperacion,              tr_moneda,
	       tr_operacion,                   tr_tran,                    tr_secuencial,
	       tr_en_linea,                    tr_banco,                   tr_ofi_oper,
	       tr_ofi_usu,                     tr_usuario,                 tr_terminal,
	       tr_estado,                      tr_dias_calc,               tr_fecha_ref,
	       tr_secuencial_ref,              tr_gerente,                 tr_gar_admisible, 
	       tr_reestructuracion,            tr_calificacion,            tr_observacion,
	       tr_comprobante,                 tr_fecha_cont)
	values(@s_date,                        @w_toperacion,              @w_moneda_op,
	       @i_operacionca,                 'PAG',                      @i_secuencial_pag,
	       @i_en_linea,                    @w_banco,                   @w_oficina_op,
	       @w_ab_oficina,                  @s_user,                    isnull(@s_term,'consola'),
	       'ING',                          0,                          @w_fecha_u_proceso,
	       @w_secuencial_rpa,              @w_gerente,                 isnull(@w_gar_admisible,''),
	       isnull(@w_reestructuracion,''), isnull(@w_calificacion,''), 'CONDONACION',
	       0,                              @s_date)
	
	if @@error <> 0 
	begin
	   PRINT 'regabono.sp Error en Insert ca_transaccion 2'
	   return 710030
	end   


   -- SELECCION DEL DIVIDENDO VIGENTE
   select @w_div_vigente = di_dividendo
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_estado    = 1

   
   exec @w_return = sp_abono_condonaciones
   @s_ofi            = @s_ofi,
   @s_sesn           = @s_sesn,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @i_secuencial_ing = @i_secuencial_ing,
   @i_secuencial_pag = @i_secuencial_pag,
   @i_secuencial_rpa = @w_secuencial_rpa,
   @i_fecha_pago     = @i_fecha_proceso,
   @i_div_vigente    = @w_div_vigente,
   @i_en_linea       = @i_en_linea,
   @i_tipo_cobro     = @w_tipo_cobro,
   @i_dividendo      = @i_dividendo,
   @i_operacionca    = @i_operacionca
   
   if @w_return <> 0 return @w_return
   
   update ca_abono
   set    ab_estado         = 'A',
          ab_secuencial_rpa = @w_secuencial_rpa
   where  ab_secuencial_ing = @i_secuencial_ing
   and    ab_operacion      = @i_operacionca

   	if @@error <> 0 
	begin
	   PRINT 'regabono.sp Error Actualizando  ca_abono Estado a A'
	   return 708152
	end   
	
end
ELSE*/
 
	-- ACTUALIZACION DE CA_ABONO
	update ca_abono
	set    ab_estado         = 'NA',
	       ab_secuencial_rpa = @w_secuencial_rpa
	where  ab_secuencial_ing = @i_secuencial_ing
	and    ab_operacion      = @i_operacionca
	
   	if @@error <> 0 
	begin
	   --PRINT 'regabono.sp Error Actualizando  ca_abono Estadoa NA'
	   return 708152
	end   	
	
	update ca_abono_det
	set    abd_carga          = @w_secuencial 
	where  abd_secuencial_ing = @i_secuencial_ing
	and    abd_operacion      = @i_operacionca
	and    abd_tipo           in ('PAG')

	if @@error <> 0 
	begin
	   --PRINT 'regabono.sp Error Actualizando  ca_abono_det abd_carga'
	   return 708152
	end   	


-- INICIO - REQ 089 - ACUERDOS DE PAGO - ACTUALIZACION DE SECUENCIAL DE REGISTRO DE PAGO
if @w_sec_acuerdo is not null
begin
   select @w_secuencial_rpa = ab_secuencial_rpa
   from ca_abono
   where ab_operacion      = @i_operacionca
   and   ab_secuencial_ing = @i_secuencial_ing
      
   if @@rowcount = 0
      return 701119
         
   update cob_credito..cr_acuerdo
   set ac_secuencial_rpa = @w_secuencial_rpa
   where ac_banco   = @w_banco
   and   ac_acuerdo = @w_sec_acuerdo
   
   if @@error <> 0
      return 2108039
end
-- FIN - REQ 089 - ACUERDOS DE PAGO

--GFP 12-11-2021 Ingreso de licitud de fondos
if @s_ssn_branch is not null and @i_aplica_licitud  = 'S' 
begin
	exec @w_return = cobis..sp_licitud
	@s_ssn            = @s_ssn,
	@s_ssn_branch     = @s_ssn_branch,
	@s_user           = @s_user,
	@s_term           = @s_term,
	@s_srv            = @s_srv,
	@s_lsrv           = @s_lsrv, 
	@s_ofi            = @s_ofi,
	@s_rol            = @s_rol,
	@s_org            = @s_org,
	@t_ssn_corr       = @t_ssn_corr,
	@t_debug          = @t_debug, 
	@t_file           = @t_file,
	@t_from           = @t_from,
	@t_trn            = 1296,
	@i_operacion      = 'I',
	@i_factor         = 1,
	@i_ente           = @w_op_cliente,
	@i_fecha          = @s_date,
	@i_monto          = @w_monto,
	@i_efectivo       = @w_monto,
	@i_cta_banco      = null,
	@i_causa          = null,
	@i_batch          = 'N',
	@i_tran           = 7058,
	@i_mon			  = @w_moneda_pago, -- AMP a solicitud de Geovanny Chulde
	@i_reverso_cca    = 'N',   -- S-Si, N-No
	@i_ssn_cca        = @s_ssn,
	@i_fecha_cca      = @i_fecha_proceso,  --@s_date
	@i_cta_cca        = @w_banco,
	@i_producto       = 7,
	
	@o_consep         = @o_consep out,
	@o_ssn            = @o_ssn out,   
	@o_monto          = @o_monto out
	
	if @w_return <> 0 return @w_return
end
return 0

go

