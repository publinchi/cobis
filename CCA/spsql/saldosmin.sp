/************************************************************************/
/*   Nombre Fisico:        saldosmin.sp                                 */
/*   Nombre Logico:        sp_saldos_minimos                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         XMA                                          */
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
/*                                   PROPOSITO                          */
/*   Realiza el registro de la forma de abono generando la              */
/*   transaccion respectiva.                                            */
/************************************************************************/
/*                                 MODIFICACIONES                       */
/*   FECHA           AUTOR             RAZON                            */
/*    DIC-2020       Patricio Narvaez   Contabilidad provisiones en     */
/*                                      moneda nacional                 */
/*  17/abr/2023   Guisela Fernandez     S807925 Ingreso de campo de     */
/*                                      reestructuracion                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldos_minimos')
   drop proc sp_saldos_minimos
go
---INC. 118151 .MAR.20.2015
create proc sp_saldos_minimos
@s_date                 datetime = null,
@s_user                 login   = null,
@s_sesn                 int     = null,
@i_secuencial_ing       int     = null,
@i_secuencial_pag       int     = null,
@i_operacionca          int     = null,
@i_monto_cancelacion    money   = null,
@i_pago_cuota           char(1) = 'N',
@i_monto_pago           money   = null,
@i_abono_extraordinario char(1) = 'N',
@i_tipo_pago            char(1) = null,
@i_op_estado            tinyint = null,
@i_num_dec              tinyint,
@i_num_dec_n            tinyint,
@i_cotizacion           float,
@i_tcotizacion          char(1)

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
@w_diff_mop_mpag        money,
@w_monto_div            money,
@w_valor_saldo_minimo   money,
@w_dividendo            int,
@w_inserta              char(1),
@w_moneda_op            smallint,
@w_fecha_ult_proceso    datetime,
@w_monto_cuotas         money,
@w_tipo_op              char(1),
@w_sp_name              descripcion,
@w_abd_tipo             char(3),
@w_concepto             varchar(12),
@w_beneficiario         varchar(255),
@w_codvalor             int,
@w_est_vigente          int,
@w_est_vencido          int,
@w_est_novigente        int,
@w_est_cancelado        int,
@w_est_castigado        int,
@w_est_diferido         int,
@w_est_anulado          int,
@w_op_estado            int,
@w_error                int,
@w_forma_pago           catalogo,
@w_toperacion           catalogo,
@w_est_condonado        tinyint,
@w_di_fecha_ini         datetime,
@w_di_fecha_ven         datetime,
@w_fecha_pago           datetime,
@w_fecha_cartera        datetime,
@w_parametro_int        catalogo,
@w_concepto_pagar       catalogo,
@w_rowcount             int,
@w_secuencial_prepago   int,
@w_gar_admisible         char(1),
@w_reestructuracion      char(1),
@w_calificacion          catalogo,
@w_gerente               smallint,
@w_banco                 cuenta,
@w_oficina_op            int,
@w_generar_causacion     char(1),
@w_monto_INT_pagar       money,
@w_concepto_deuda        catalogo                

/*INICIALIZAR VARIABLES*/      
select 
@w_inserta        = 'N',
@w_sp_name        = 'sp_saldos_minimos',
@w_est_vigente    = 1,
@w_est_vencido    = 2   


/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_condonado  = @w_est_condonado out


/*MONTO SALDO MINIMO*/
select @w_valor_saldo_minimo = pa_money
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'SALMIN'

if @@rowcount = 0 return 710076

if @w_valor_saldo_minimo <= 0 return 0


/*DATOS OPERACION*/
select 
@w_moneda_op          = op_moneda,
@w_fecha_ult_proceso  = op_fecha_ult_proceso,
@w_op_estado          = @i_op_estado,        ---op_estado,
@w_toperacion         = op_toperacion,
@w_gar_admisible      = op_gar_admisible,
@w_reestructuracion   = isnull(op_reestructuracion, ''),
@w_calificacion       = isnull(op_calificacion, 'A'),
@w_banco              = op_banco,
@w_oficina_op         = op_oficina,
@w_gerente            = op_oficial
from ca_operacion
where op_operacion  = @i_operacionca


/*DIVIDENDO MINIMO*/
select @w_dividendo = isnull(min(di_dividendo),0)
from   ca_dividendo
where  di_operacion = @i_operacionca   
and   (di_estado    = @w_est_vencido or di_estado   = @w_est_vigente)
   

if @w_dividendo = 0 return 0 


/* OPCION PARA CANCELACION DE LA OPERCION CON SALDOS MENORES AL MINIMO */
if @i_pago_cuota = 'N' begin

   select @w_forma_pago = pa_char
   from cobis..cl_parametro
   where pa_producto = 'CCA'
   and   pa_nemonico = 'FSAMIN'

   select @w_codvalor  = cp_codvalor
   from ca_producto
   where cp_producto = @w_forma_pago
   
 
   select @w_diff_mop_mpag = @i_monto_cancelacion - @i_monto_pago

   insert into ca_det_trn  with (rowlock) (
   dtr_secuencial,          dtr_operacion,          dtr_dividendo,
   dtr_concepto,            dtr_estado,             dtr_periodo,
   dtr_codvalor,            dtr_monto,              dtr_monto_mn,
   dtr_moneda,              dtr_cotizacion,         dtr_tcotizacion,
   dtr_afectacion,          dtr_cuenta,             dtr_beneficiario,
   dtr_monto_cont)                                  
   values (
   @i_secuencial_pag,       @i_operacionca,         0,
   @w_forma_pago,           @w_op_estado,           0,
   @w_codvalor,             @w_diff_mop_mpag,       round(@w_diff_mop_mpag*@i_cotizacion,@i_num_dec_n),
   @w_moneda_op,            1,                      'N',
   'D',                     '',                     'PAGO PARA CANCELAR OPERACION CON SALDO MINIMO',
   0)

   if @@error <> 0 return 710001
   
   
   -- INSERTAR EL REGISTRO DE LAS FORMAS DE PAGO PARA ca_abono_rubro
   insert into ca_abono_rubro  with (rowlock)(
   ar_fecha_pag,    ar_secuencial,     ar_operacion,
   ar_dividendo,    ar_concepto,       ar_estado,
   ar_monto,        ar_monto_mn,       ar_moneda,
   ar_cotizacion,   ar_afectacion,     ar_tasa_pago,
   ar_dias_pagados)
   select 
   @s_date,         @i_secuencial_pag, @i_operacionca,
   dtr_dividendo,   @w_forma_pago,     dtr_estado,
   dtr_monto,       dtr_monto_mn,      dtr_moneda,
   dtr_cotizacion,  'D',               0,
   0
   from   ca_det_trn
   where  dtr_secuencial = @i_secuencial_pag    ---FORMA DE PAGO DEL CLIENTE
   and    dtr_operacion  = @i_operacionca
   and    dtr_concepto   = @w_forma_pago
   and    dtr_dividendo  = 0
   
   if @@error <> 0 return 710404
   
   return 0
   
end

/* OPCION PARA CANCELACION DE LA CUOTA CON SALDO MINIMO */
if @i_pago_cuota = 'S' begin

  ---VALIDAR SI LA FECHA DE PAGO ES ANTES DE LA FECHA DE VENCIETNO DE LA CUOTA
  ---NO SE PAGA CON SALDO MINIMO
  
  select @w_fecha_cartera = fc_fecha_cierre
  from cobis..ba_fecha_cierre
  where fc_producto = 7

  select @w_di_fecha_ini = di_fecha_ini,
         @w_di_fecha_ven = di_fecha_ven
  from ca_dividendo
  where di_operacion = @i_operacionca
  and di_dividendo   = @w_dividendo  

   select @w_fecha_pago = ab_fecha_pag
  from ca_abono
  where ab_operacion = @i_operacionca
  and ab_secuencial_ing = @i_secuencial_ing
  

  if  (@w_fecha_pago  < @w_di_fecha_ven ) 
  begin
    ---SI EL CONCEPTO ES INT NO SE PAGA CON SALDO MINIMO
    ---POR QUE SERIA UN INT SIN CAUSAR
    
  	select @w_parametro_int = pa_char
	from   cobis..cl_parametro
	where  pa_producto = 'CCA'
	and    pa_nemonico = 'INT'
	select @w_rowcount = @@rowcount
	set transaction isolation level read uncommitted
	
	if @w_rowcount = 0 
	   return 701059  

    select @w_concepto_pagar = am_concepto
    from ca_amortizacion, ca_concepto
    where am_operacion         = @i_operacionca
    and   am_dividendo         = @w_dividendo
    and   am_cuota - am_pagado > 0
    and   am_concepto          = co_concepto
    and   co_categoria         = 'I'	   
	
     
    select @w_generar_causacion = 'N'
    if @w_concepto_pagar =  @w_parametro_int
    begin
	    select @w_generar_causacion = 'S'
	    select @w_monto_INT_pagar = 0
	    select @w_monto_INT_pagar = isnull(sum(am_cuota - am_acumulado),0)
	    from ca_amortizacion, ca_concepto
	    where am_operacion         = @i_operacionca
	    and   am_dividendo         = @w_dividendo
	    and   am_cuota - am_pagado > 0
	    and   am_concepto          = co_concepto
	    and   co_categoria         = 'I'	   
	     
    end
  end
  ELSE
  begin
   if @w_op_estado = 9
      begin
      select @w_concepto_deuda = am_concepto
      from ca_amortizacion, ca_concepto
      where am_operacion         = @i_operacionca
      and   am_dividendo         = @w_dividendo
      and   am_cuota - am_pagado > 0
      and   am_concepto          = co_concepto

        ---VERIFICAR SI EXISTE CAUSACION EN SUSPENSO PARA LA CUOTA QUE GENERA EL SALDO MINIMO
        ---SINO EL ESTADO DEBERIA SER 1-VIGENTE POR QUE  
        ---TODA LA CAUSACION DE LA CUOTA YA SE HIZO EN 1-VIGENTE YA QUE LA OPERACION ENTRO EN SUSPENSO PERO 
        ---NO HA CAUSADO NADA EN ESTADO 9-SUSPENSO y EL SALDO MINIMO DEBE QUEDAR TAL COMO ESTA LA CAUSACION SINO 
        ---SE PRESENTAN DIFERENCIAS EN AL BOC
        if not exists (select 1 from ca_amortizacion
                       where am_operacion = @i_operacionca
                       and   am_concepto = 'INT'
                       and   am_estado = 9
                       and   am_dividendo = @w_dividendo
                       and   am_cuota     >  0)
                      begin
                         if @w_concepto_deuda = 'INT'
                            select @w_op_estado = am_estado
                            from ca_amortizacion
                            where am_operacion = @i_operacionca
                            and   am_concepto  = 'INT'
                            and   am_dividendo = @w_dividendo 
                            and   am_secuencia = 1                      
                      end  
      end
  end
  
   exec @w_error    = sp_consulta_cuota
   @i_operacionca   = @i_operacionca,
   @i_moneda        = @w_moneda_op,  
   @i_tipo_cobro    = 'P',
   @i_fecha_proceso = @w_fecha_ult_proceso,
   @i_nota_debito   = 'N',
   @i_mon_ext       = 'N',
   @i_dividendo     = @w_dividendo,
   @i_tipo_op       = 'D',
   @o_monto         = @w_monto out
      
   if @w_error <> 0 return @w_error

   if @w_monto > @w_valor_saldo_minimo return 0
   
   if not exists(select 1 from ca_dividendo 
   where di_operacion = @i_operacionca      
   and   di_dividendo = @w_dividendo + 1)
   return 0
   
   
   insert into ca_det_trn  with (rowlock) (
   dtr_secuencial,                dtr_operacion,             dtr_dividendo,
   dtr_concepto,                  dtr_estado,                dtr_periodo,
   dtr_monto,                     dtr_monto_mn,              dtr_codvalor,            
   dtr_moneda,                    dtr_cotizacion,            dtr_tcotizacion,
   dtr_afectacion,                dtr_cuenta,                dtr_beneficiario,
   dtr_monto_cont)                                           
   select                                                    
   @i_secuencial_pag,             @i_operacionca,            @w_dividendo,
   am_concepto,                   @w_op_estado,              0,
   am_cuota - am_pagado,          round((am_cuota - am_pagado)*@i_cotizacion,@i_num_dec_n),      co_codigo*1000 + @w_op_estado * 10,             
   @w_moneda_op,                  1,                         'N',
   'C',                           '',                        'PAGO PARA CANCELAR CUOTA CON SALDO MINIMO',
   0
   from ca_amortizacion, ca_concepto
   where am_operacion         = @i_operacionca
   and   am_dividendo         = @w_dividendo
   and   am_cuota - am_pagado > 0
   and   am_concepto          = co_concepto

   if @@error <> 0 return 710020 --710001
   
   select @w_concepto = pa_char
   from cobis..cl_parametro
   where pa_producto = 'CCA'
   and   pa_nemonico = 'FSAMIN'
   
   select @w_codvalor  = (co_codigo * 1000) + (@w_op_estado*10) + (0)
   from ca_concepto
   where co_concepto = @w_concepto
   
   
   insert into ca_det_trn  with (rowlock) (
   dtr_secuencial,          dtr_operacion,          dtr_dividendo,
   dtr_concepto,            dtr_estado,             dtr_periodo,
   dtr_codvalor,            dtr_monto,              dtr_monto_mn,
   dtr_moneda,              dtr_cotizacion,         dtr_tcotizacion,
   dtr_afectacion,          dtr_cuenta,             dtr_beneficiario,
   dtr_monto_cont)                                  
   values (
   @i_secuencial_pag,       @i_operacionca,         @w_dividendo + 1,
   @w_concepto,             @w_op_estado,           0,
   @w_codvalor,             -1*@w_monto,            round((-1*@w_monto)*@i_cotizacion,@i_num_dec_n),
   @w_moneda_op,            1,                      'N',
   'C',                     '',                     'CUENTA POR PAGAR SALDO MINIMO',
   0)
   
   if @@error <> 0 return 710030  --710001

   
   insert into ca_amortizacion (
   am_operacion,     am_dividendo,     am_concepto,
   am_estado,        am_periodo,       am_cuota,
   am_gracia,        am_pagado,        am_acumulado,
   am_secuencia)
   values(
   @i_operacionca,   @w_dividendo+1,   @w_concepto,
   @w_op_estado,     0,                @w_monto,
   0,                0,                @w_monto,
   1)
    
   if @@rowcount = 0 return 710040  ---710001
   
   
   /* CREAR EL RUBRO FNG EN CASO QUE NO EXISTA EN LA OPERACION */
   if not exists(select 1 from ca_rubro_op 
      where ro_operacion = @i_operacionca
      and   ro_concepto  = @w_concepto)  begin
      
      insert into ca_rubro_op(
      ro_operacion,             ro_concepto,                ro_tipo_rubro,
      ro_fpago,                 ro_prioridad,               ro_paga_mora,
      ro_provisiona,            ro_signo,                   ro_factor,
      ro_referencial,           ro_signo_reajuste,          ro_factor_reajuste,
      ro_referencial_reajuste,  ro_valor,                   ro_porcentaje,
      ro_gracia,                ro_porcentaje_aux,          ro_principal,
      ro_porcentaje_efa,        ro_concepto_asociado,       ro_garantia,
      ro_tipo_puntos,           ro_saldo_op,                ro_saldo_por_desem,
      ro_base_calculo,          ro_num_dec,                 ro_tipo_garantia,       
      ro_nro_garantia,          ro_porcentaje_cobertura,    ro_valor_garantia,
      ro_tperiodo,              ro_periodo,                 ro_saldo_insoluto,
      ro_porcentaje_cobrar,     ro_iva_siempre)
      select 
      @i_operacionca,           ru_concepto,                 ru_tipo_rubro,
      ru_fpago,                 ru_prioridad,                ru_paga_mora,
      'N',                      null,                        0,
      ru_referencial,           '+',                         0,
      null,                     0,                           0,
      0,                        0,                           'N',
      null,                     ru_concepto_asociado,        0,     
      null,                     'N',                         'N', 
      0.00,                     0,                           ru_tipo_garantia,   
      null,                     'N',                         'N',
      'M',                      1,                           'N',
      0,                        ru_iva_siempre
      from   ca_rubro
      where  ru_toperacion = @w_toperacion
      and    ru_moneda     = @w_moneda_op 
      and    ru_concepto   = @w_concepto
   
      if @@error <> 0 return 710050  --710001
   end

  
   update ca_amortizacion set
   am_estado    = @w_est_cancelado,
   am_pagado    = am_cuota,
   am_acumulado = am_cuota
   where am_operacion = @i_operacionca
   and   am_dividendo = @w_dividendo
   
   if @@error <> 0 return 710002

   update ca_dividendo set
   di_estado     = @w_est_cancelado,
   di_fecha_can  = @w_fecha_ult_proceso
   where di_operacion = @i_operacionca
   and   di_dividendo = @w_dividendo
   
   if @@error <> 0 return 710002
   
   if exists(select 1 from ca_dividendo 
      where di_operacion = @i_operacionca
      and   di_dividendo = @w_dividendo + 1
      and   di_estado    = @w_est_novigente) begin
      
      -- ACTIVAR LA CUOTA NO VIGENTE
      update ca_dividendo
      set    di_estado = @w_est_vigente
      where  di_operacion = @i_operacionca
      and    di_dividendo = @w_dividendo + 1
      and    di_estado    = @w_est_novigente
      
      if @@error <>0  return 710002
      
      update ca_amortizacion
      set    am_estado = @w_est_vigente
      from   ca_amortizacion 
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_dividendo + 1
      and    am_estado    = @w_est_novigente
      
      if @@error <>0 return 710002
      
     
      update ca_amortizacion with (rowlock) set   
      am_acumulado = am_cuota,
      am_estado    = @w_op_estado
      from ca_rubro_op
      where am_operacion  = ro_operacion
      and   am_concepto   = ro_concepto
      and   ro_provisiona = 'N'
      and   ro_tipo_rubro <> 'C'
      and   ro_operacion  = @i_operacionca
      and   am_dividendo  = @w_dividendo + 1
      
      if @@error <>0 return 710002
      
      insert into ca_transaccion_prv
      select
      tp_fecha_mov       = @s_date,
      tp_operacion       = @i_operacionca,
      tp_fecha_ref       = @w_fecha_ult_proceso,
      tp_secuencial_ref  = @i_secuencial_pag,
      tp_estado          = 'ING',
      tp_comprobante     = 0,
      tp_fecha_cont      = null,
      tp_dividendo       = am_dividendo,
      tp_concepto        = am_concepto,
      tp_codvalor        =(co_codigo * 1000) + (@w_op_estado * 10),
      tp_monto           = am_cuota,
      tp_secuencia       = am_secuencia,
      tp_ofi_oper        = @w_oficina_op,
      tp_monto_mn        = round(am_cuota*@i_cotizacion,@i_num_dec_n),
      tp_moneda          = @w_moneda_op,
      tp_cotizacion      = @i_cotizacion,
      tp_tcotizacion     = @i_tcotizacion,
	  tp_reestructuracion = @w_reestructuracion
      from ca_amortizacion, ca_rubro_op, ca_concepto
      where am_operacion = ro_operacion
      and   am_concepto  = ro_concepto
      and   am_concepto  = co_concepto 
      and   ro_provisiona = 'N'
      and   ro_tipo_rubro <> 'C'
      and   ro_operacion  = @i_operacionca
      and   am_dividendo  = @w_dividendo + 1
      and   am_cuota  >= 0.01    
      and   am_concepto   <> @w_concepto
	  and   am_concepto    not in (select ro_concepto 
                                  from   ca_rubro_op where ro_concepto_asociado in (select ro_concepto  from ca_rubro_op where ro_fpago  = 'M' and ro_operacion =@i_operacionca) 
								  and    ro_operacion = @i_operacionca
                                  union
                                  select ro_concepto 
                                  from   ca_rubro_op
                                  where  ro_fpago    = 'M'
                                  and    ro_operacion =@i_operacionca) --EVITAR CONSIDERAR LOS RUBROS MULTA Y LOS ASOCIADOS A LAS MULTAS
      
      if @@error <>0 return 710001
         
   end  -- ACTIVAR LA CUOTA NO VIGENTE
  
   
   if @w_generar_causacion = 'S' and @w_monto_INT_pagar > 0
   begin
    
	     

		   insert into ca_transaccion_prv with (rowlock)
               (
               tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
               tp_secuencial_ref,   tp_estado,           tp_dividendo,
               tp_concepto,         tp_codvalor,         tp_monto,
               tp_secuencia,        tp_comprobante,      tp_ofi_oper,
               tp_monto_mn,         tp_moneda,           tp_cotizacion,
               tp_tcotizacion,      tp_reestructuracion
               )
               select distinct
               @s_date,                  @i_operacionca,           @w_fecha_ult_proceso,
               @w_secuencial_prepago,   'ING',                     @w_dividendo,
               am_concepto,              co_codigo*1000 + @w_op_estado * 10, @w_monto_INT_pagar,
               1,                        0,                        @w_oficina_op,
               round(@w_monto_INT_pagar*@i_cotizacion,@i_num_dec_n), @w_moneda_op, @i_cotizacion,
               @i_tcotizacion,           @w_reestructuracion
               from ca_amortizacion, ca_concepto
			   where am_operacion         = @i_operacionca
			   and   am_dividendo         = @w_dividendo
			   and   am_concepto          = @w_parametro_int
			   and   am_concepto          = co_concepto
               
          if @@error <> 0
             return 708165     
                 		   

   	        
     end ---- saldo minimo de INT

   return 0
end

go





