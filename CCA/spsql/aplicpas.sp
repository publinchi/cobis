/************************************************************************/
/*		Nombre Logico:			sp_aplica_prepagos_pasivas				*/
/*		Nombre Fisico:			aplicpas.sp								*/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     Sep - 2003                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios que son        */
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
/*      Aplica los prepagos de las pasivas FINAGRO                      */
/************************************************************************/
/*                             CAMBIOS                                  */
/*      FECHA           AUTOR      CAMBIO                               */
/*  ABR-25-2006         EPB        manejo coversion moneda en           */
/*                                 registro de ca_det_trn def 6387      */
/*  MAY-26-2006         EPB        Def. 6247 Todo valor en pesos        */
/*  NOV-09-2006         EPB        Defecto 7425 BAC                     */
/*  NON-22-2006         EPB        DEFECTO 7489 BAC                     */
/*  DIC-05-2006         FGQ        Incluir el llamado a                 */
/*                                 sp_valida_existencia_prv             */
/*  ENE-12-2007         EPB        DEFECTO 7737 BAC                     */
/*  ABR-13-2007         EPB        DEFECTO 4767 Revision Pasivas        */
/*  JUN/06/2023	 	M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*  NOV/07/2023     K. Rodriguez     Actualiza valor despreciab         */
/************************************************************************/

use cob_cartera

go

if exists (select 1 from sysobjects where name = 'sp_aplica_prepagos_pasivas')
   drop proc sp_aplica_prepagos_pasivas
go

create proc sp_aplica_prepagos_pasivas
   @s_sesn                int          = NULL,
   @s_user                login        = NULL,
   @s_term                varchar (30) = NULL,
   @s_date                datetime     = NULL,
   @s_ofi                 smallint     = NULL,
   @s_ssn                 int          = null,
   @s_srv                 varchar (30) = null,
   @s_lsrv                varchar (30) = null,
   @i_tipo_cobro          char(1),
   @i_secuencial_ing      int,
   @i_operacionca         int,
   @i_fecha_proceso       datetime,
   @i_secuencial_rpa      int          = 0,
   @i_en_linea            char(1)      = 'S',
   @i_cotizacion_dia_sus  float        = null,
   @i_en_gracia_int       char(1)      = 'N'
   

as

declare
   @w_error                 int,
   @w_num_dec_op            int,
   @w_banco                 cuenta,
   @w_activa                cuenta,
   @w_pasiva                cuenta,
   @w_moneda_op             smallint,
   @w_moneda_mn             smallint,
   @w_oficina_op            int,
   @w_tipo_aplicacion       char(1),
   @w_tipo_reduccion        char(1),
   @w_toperacion            catalogo,
   @w_secuencial_pag        int,
   @w_tcotizacion           char(1),
   @w_monto_sobrante        money,
   @w_div_vigente           int,
   @w_dias_anio             smallint,
   @w_base_calculo          char(1),
   @w_saldo_capital         money,
   @w_tipo_tabla            catalogo,
   @w_cliente               int,
   @w_tipo                  char(1),
   @w_tasa_prepago          float,
   @w_gerente               smallint,
   @w_estado                char(1),
   @w_monto_mpg             money,
   @w_concepto_int          catalogo,
   @w_moneda_local          smallint,
   @w_moneda_pago           smallint,
   @w_producto              int,
   @w_gar_admisible         char(1),
   @w_reestructuracion      char(1),
   @w_calificacion          catalogo, -- MCO 05/06/2023 Se cambio el tipo de dato de char(1) a catalogo
   @w_num_dec_n             smallint,
   @w_moneda_pag            smallint,
   @w_op_estado             tinyint,
   @w_tipo_novedad          char(1),
   @w_valor_interes         money,
   @w_valor_capital         money,
   @w_rubro_cap             catalogo,
   @w_fpago                 catalogo,
   @w_secuencial_prv        int,
   @w_genera_PRV            char(1),
   @w_abono_extraordinario  char(1),
   @w_valor_prv             money,
   @w_codvalor              int,
   @w_pp_moneda             smallint,
   @w_monto_mn              money,
   @w_cot_mn                money,
   @w_tasa_int              float,
   @w_recalcular_int        char(1),
   @w_pp_dias_de_interes    int,
   @w_estado_op             int,
   @w_nuevo_acumulado       money,
   @w_valor_calc            money,
   @w_generar_cuota         char(1),
   @w_nuevo_cuota           money,
   @w_di_dias_cuota         int,
   @w_am_cuota              money,
   @w_am_pagado             money,
   @w_vlr_despreciable      float,
   @w_am_estado_act         tinyint,
   @w_est_divvigente        int,
   @w_cancelar              char(1),
   @w_saldo_oper            money,
   @w_am_acumulado_ini      money,
   @w_op_fecha_fin          datetime,
   @w_op_fecha_ult_proceso  datetime,
   @w_nuevo_vigente         int,
   @w_valor_cap_op          money,
   @w_valor_int_mon_op      money,
   @w_pp_cotizacion         money,
   @w_rowcount_act            int,
   @w_op_fecha_ult_causacion datetime,
   @w_fecha_a_causar         datetime,
   @w_sector                 catalogo,
   @w_dias_div               int,
   @w_tdividendo             catalogo,
   @w_causacion              catalogo,
   @w_fecha_liq              datetime,
   @w_fecha_ini              datetime,
   @w_clausula               catalogo,
   @w_abd_cotizacion_mop     money,
   @w_rowcount               int 
   
   

  

-- CARGADO DE LOS PARAMETROS DE CARTERA
select @s_term              =  isnull(@s_term,'consola'),
       @w_generar_cuota = 'N',
       @w_am_cuota      = 0,
       @w_saldo_oper    = 0,
       @w_am_pagado     = 0,
       @w_nuevo_vigente = 0,
       @w_am_acumulado_ini  = 0


-- CODIGO DEL RUBRO CAPITAL
select @w_rubro_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
   return 710076

select @w_div_vigente = 0
select @w_div_vigente   = isnull(max(di_dividendo), 0)
from   ca_dividendo
where  di_operacion =  @i_operacionca
and    di_estado    =  1

if @w_div_vigente = 0
   return  701179

-- CODIGO DEL RUBRO INT
select @w_concepto_int = ro_concepto,
       @w_tasa_int     = ro_porcentaje
from   ca_rubro_op
where  ro_operacion  = @i_operacionca
and    ro_tipo_rubro = 'I'

-- DATOS DE CA_OPERACION
select @w_banco                   = op_banco,
       @w_toperacion              = op_toperacion,
       @w_moneda_op               = op_moneda,
       @w_oficina_op              = op_oficina,
       @w_dias_anio               = op_dias_anio,
       @w_base_calculo            = op_base_calculo,
       @w_tipo_tabla              = op_tipo_amortizacion,
       @w_cliente                 = op_cliente,
       @w_tipo                    = op_tipo,
       @w_gerente                 = op_oficial,
       @w_gar_admisible           = isnull(op_gar_admisible, 'N'),
       @w_reestructuracion        = op_reestructuracion,
       @w_calificacion            = isnull(op_calificacion, 'A'),
       @w_op_estado               = op_estado,
       @w_op_fecha_fin            = op_fecha_fin,
       @w_op_fecha_ult_proceso    = op_fecha_ult_proceso,
       @w_op_fecha_ult_causacion  = op_fecha_ult_causacion,
       @w_fecha_liq               = op_fecha_liq,
       @w_fecha_ini               = op_fecha_ini,
       @w_tdividendo              = op_tdividendo,
       @w_dias_div                = op_periodo_int,
       @w_causacion               = op_causacion,
       @w_clausula                = op_clausula_aplicada
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount = 0 
   return 701025

if @w_op_fecha_fin <= @w_op_fecha_ult_proceso or  @w_op_estado = 2
   return  710027

-- LECTURA DE DECIMALES
exec @w_error = sp_decimales
     @i_moneda       = @w_moneda_op,
     @o_decimales    = @w_num_dec_op out,
     @o_mon_nacional = @w_moneda_mn  out,
     @o_dec_nacional = @w_num_dec_n  out

if @w_error != 0 
   return  @w_error

select @w_vlr_despreciable = 1.0 / power(10, isnull((@w_num_dec_op +2), 4))

-- SELECCIONAR LA COTIZACION Y EL TIPO DE COTIZACION
select @w_tcotizacion        = abd_tcotizacion_mop,
       @w_fpago              = abd_concepto,
       @w_abd_cotizacion_mop = abd_cotizacion_mop
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca
and    abd_tipo           = 'PAG'

---SECUENCIAL DEL PAGO
exec @w_secuencial_pag = sp_gen_sec
     @i_operacion      = @i_operacionca

--CONSULTA CODIGO DE MONEDA LOCAL
SELECT @w_moneda_local = pa_tinyint
FROM   cobis..cl_parametro
WHERE  pa_nemonico = 'MLO'
AND    pa_producto = 'ADM'
set transaction isolation level read uncommitted

-- OBTENER RESPALDO ANTES DE LA APLICACION DEL PAGO
exec @w_error  = sp_historial
     @i_operacionca  = @i_operacionca,
     @i_secuencial   = @w_secuencial_pag

if @w_error != 0
   return @w_error

--- REVISION PASIVAS *****************************************************

      select  @w_fecha_a_causar = dateadd(dd, -1, @w_op_fecha_ult_proceso)
   
      if  @w_op_fecha_ult_causacion != @w_fecha_a_causar
      begin
         
         begin tran
         
         exec @w_error = sp_calculo_diario_int
              @s_user              = @s_user,
              @s_term              = @s_term,
              @s_date              = @s_date,
              @s_ofi               = @s_ofi,
              @i_en_linea          = 'N',
              @i_toperacion        = @w_toperacion,
              @i_banco             = @w_banco,
              @i_operacionca       = @i_operacionca,
              @i_moneda            = @w_moneda_op,
              @i_dias_anio         = @w_dias_anio,
              @i_sector            = @w_sector,
              @i_oficina           = @w_oficina_op,
              @i_fecha_liq         = @w_fecha_liq,
              @i_fecha_ini         = @w_fecha_ini,
              @i_fecha_proceso     = @w_fecha_a_causar,
              @i_tdividendo        = @w_tdividendo,
              @i_clausula_aplicada = @w_clausula,
              @i_base_calculo      = @w_base_calculo,
              @i_dias_interes      = @w_dias_div,
              @i_causacion         = @w_causacion,
              @i_tipo              = @w_tipo,
              @i_gerente           = @w_gerente,
              @i_cotizacion        = @w_abd_cotizacion_mop
               
         
         if @w_error != 0
         begin
            rollback tran
            return @w_error
         end
      commit tran
    end

--FIN REVISION PASIVAS ***************************************************
-- INSERCION DE CABECERA CONTABLE DE CARTERA
insert into ca_transaccion
     (tr_fecha_mov,         tr_toperacion,     tr_moneda,
      tr_operacion,         tr_tran,           tr_secuencial,
      tr_en_linea,          tr_banco,          tr_dias_calc,
      tr_ofi_oper,          tr_ofi_usu,        tr_usuario,
      tr_terminal,          tr_fecha_ref,      tr_secuencial_ref,
      tr_estado,            tr_gerente,        tr_gar_admisible,
      tr_reestructuracion,  tr_calificacion,   
      tr_observacion,
      tr_fecha_cont,        tr_comprobante)
values(@s_date,             @w_toperacion,     @w_moneda_op,
       @i_operacionca,      'PAG',             @w_secuencial_pag,
       @i_en_linea,         @w_banco,          0,
       @w_oficina_op,       @s_ofi,            @s_user,
       @s_term,             @w_op_fecha_ult_proceso,  @i_secuencial_rpa,
       'ING',               @w_gerente,        isnull(@w_gar_admisible,''),
       isnull(@w_reestructuracion,''),         isnull(@w_calificacion,''),
       'PREPAGO PASIVA',
       @s_date,             0)

if @@error != 0
   return 708165

-- INSERCION DE CUENTA PUENTE PARA LA APLICACION DEL PAGO
insert into ca_det_trn
         (dtr_secuencial,    dtr_operacion,  dtr_dividendo,
          dtr_concepto,      dtr_estado,     dtr_periodo,
          dtr_codvalor,      dtr_monto,      dtr_monto_mn,
          dtr_moneda,        dtr_cotizacion, dtr_tcotizacion,
          dtr_afectacion,    dtr_cuenta,     dtr_beneficiario,
          dtr_monto_cont)
select @w_secuencial_pag, @i_operacionca, dtr_dividendo,
          dtr_concepto,      dtr_estado,     dtr_periodo,
          dtr_codvalor,      dtr_monto,      dtr_monto_mn,
          dtr_moneda,        dtr_cotizacion, dtr_tcotizacion,
          'D',               dtr_cuenta,     dtr_beneficiario,
          dtr_monto_cont
from   ca_det_trn
where  dtr_secuencial = @i_secuencial_rpa 
and    dtr_operacion  = @i_operacionca
and    dtr_concepto like 'VAC_%'

if @@error != 0
   return 710036 


-- INSERTAR EL REGISTRO DE LAS FORMAS DE PAGO PARA ca_abono_rubro
insert into ca_abono_rubro
         (ar_fecha_pag,    ar_secuencial,     ar_operacion,
          ar_dividendo,    ar_concepto,       ar_estado,
          ar_monto,        ar_monto_mn,       ar_moneda,
          ar_cotizacion,   ar_afectacion,     ar_tasa_pago,
          ar_dias_pagados)
select @s_date,         @w_secuencial_pag, @i_operacionca,
          dtr_dividendo,   @w_fpago,          dtr_estado,
          dtr_monto,       dtr_monto_mn,      dtr_moneda,
          dtr_cotizacion,  'D',               0,
          0
from   ca_det_trn
where  dtr_secuencial = @i_secuencial_rpa    ---FORMA DE PAGO DEL CLIENTE
and    dtr_operacion  = @i_operacionca
and    dtr_afectacion = 'D'
   
if @@error != 0 
   return 710404

select @w_valor_interes         = pp_saldo_intereses,
       @w_valor_capital         = pp_valor_prepago, --esta en pesos
       @w_abono_extraordinario  = pp_abono_extraordinario,
       @w_tipo_novedad          = pp_tipo_novedad,
       @w_tipo_reduccion        = pp_tipo_reduccion,
       @w_tipo_aplicacion       = pp_tipo_aplicacion,
       @w_tasa_prepago          = pp_tasa,
       @w_pp_moneda             = pp_moneda,
       @w_pp_dias_de_interes    = pp_dias_de_interes,
       @w_pp_cotizacion         = isnull(pp_cotizacion,1)
from   ca_prepagos_pasivas
where  pp_banco          =  @w_banco
and    pp_secuencial_ing =  @i_secuencial_ing

if @@rowcount = 0
  return  710448


--Valor del interes esta en moneda local, 
--para actualizar la tabla de amortizacion debe sarse el valor en UVR

if @w_moneda_op = 2
begin
   select @w_valor_int_mon_op = @w_valor_interes / @w_pp_cotizacion
   select @w_valor_cap_op = @w_valor_capital / @w_pp_cotizacion
   
end   
else
begin
  select @w_valor_int_mon_op = @w_valor_interes 
  select @w_valor_cap_op = @w_valor_capital
end

select @w_saldo_capital = 0
select @w_saldo_capital = sum(am_cuota+am_gracia-am_pagado)
from   ca_amortizacion, ca_rubro_op
where  am_operacion  = @i_operacionca
and    ro_operacion  = @i_operacionca
and    am_concepto   = ro_concepto
and    ro_tipo_rubro = 'C' -- CAPITALES

if @w_valor_cap_op > @w_saldo_capital 
   return 710516


-- SELECCION DEL DIVIDENDO VIGENTE
select @w_recalcular_int = 'N'
select @w_div_vigente = 0
select @w_div_vigente   = di_dividendo,
       @w_di_dias_cuota = di_dias_cuota
from   ca_dividendo
where  di_operacion =  @i_operacionca
and    di_estado    =  1

if @@rowcount != 0  
begin
   
   select @w_am_estado_act  = 1
   
   select @w_am_acumulado_ini = isnull(sum(am_acumulado - am_pagado),0),
          @w_am_cuota     = isnull(sum(am_cuota),0),
          @w_am_pagado    = isnull(sum(am_pagado),0)
   from   ca_amortizacion
   where  am_operacion =  @i_operacionca
   and    am_dividendo =  @w_div_vigente
   and    am_concepto  =  @w_concepto_int
   
   if @w_am_estado_act = 3
      select @w_am_estado_act = 1
   
   ---SE COLOCA EN 0 EL ACUMULADO A LA FECHA Y DESPUES DE APLICAR EL PREPAGO SE CALCULA NUEVAMENTE
   update ca_amortizacion
   set    am_acumulado =  0,
          am_estado    =  @w_am_estado_act
   where  am_operacion  =  @i_operacionca
   and    am_dividendo  =  @w_div_vigente
   and    am_concepto   =  @w_concepto_int
   
   if @w_valor_interes > 0
   begin
      update ca_abono_prioridad
      set    ap_prioridad = 0
      where  ap_operacion       = @i_operacionca
      and    ap_secuencial_ing  = @i_secuencial_ing
      and    ap_concepto        = @w_concepto_int
      
      if @@rowcount = 0
         return 710419
      
      if @w_am_cuota  < @w_valor_int_mon_op + @w_am_pagado
      begin
         
         update ca_amortizacion
         set    am_acumulado =  @w_valor_int_mon_op + am_pagado,
                am_cuota = @w_valor_int_mon_op + am_pagado
         where am_operacion  =  @i_operacionca
         and   am_dividendo  =  @w_div_vigente
         and   am_concepto   =  @w_concepto_int
      end
      ELSE
      begin
         update ca_amortizacion
         set    am_acumulado =  @w_valor_int_mon_op + am_pagado
         where am_operacion  =  @i_operacionca
         and   am_dividendo  =  @w_div_vigente
         and   am_concepto   =  @w_concepto_int
      end    
      
      -- APLICACION DEL PAGO PARA EL RUBRO INTERES
      
      exec @w_error = sp_abona_rubro
           @s_ofi               = @s_ofi,
           @s_sesn              = @s_sesn,
           @s_user              = @s_user,
           @s_date              = @s_date,
           @s_term              = @s_term,
           @i_secuencial_pag    = @w_secuencial_pag,
           @i_operacionca       = @i_operacionca,
           @i_dividendo         = @w_div_vigente,
           @i_concepto          = @w_concepto_int,
           @i_monto_pago        = @w_valor_int_mon_op, --Este valor va en la moneda de la operacion
           @i_monto_prioridad   = @w_valor_int_mon_op,
           @i_monto_rubro       = @w_valor_int_mon_op,
           @i_tipo_cobro        = 'A',
           @i_fpago             = @w_fpago,
           @i_en_linea          = @i_en_linea,
           @i_fecha_pago        = @i_fecha_proceso,
           @i_cotizacion        = @w_pp_cotizacion,
           @i_tcotizacion       = @w_tcotizacion,
           @i_tipo_rubro        = 'I',
           @i_inicial_prioridad = @w_valor_interes,
           @i_inicial_rubro     = @w_valor_interes,
           @i_cotizacion_dia_sus = @i_cotizacion_dia_sus,
           @i_en_gracia_int      = @i_en_gracia_int,
           @o_sobrante_pago     = @w_monto_sobrante out
      
      if (@w_error != 0) 
         return @w_error
      

      
      ---DESPUES DE APLICAR EL INTERES DEL PREPGO, SE BORRAR LA PRIORIDAD PARA QUE
      ---TODO SE APLIQUE A CAP
      
      delete ca_abono_prioridad
      where  ap_operacion       = @i_operacionca
      and    ap_secuencial_ing  = @i_secuencial_ing
      and    ap_concepto        = @w_concepto_int
      
      if @@rowcount = 0
         return 710089
      
      update ca_abono_prioridad
      set    ap_prioridad = 0
      where  ap_operacion       = @i_operacionca
      and    ap_secuencial_ing  = @i_secuencial_ing
      and    ap_concepto        = @w_rubro_cap
      
      if @@rowcount = 0
         return 710419
   end --PAGO DE INTERESES
end --EXISTE DIVIDENDO VIGENTE

---APLICACION DEL CAPITAL SEGUN REGISTRO DEL ABONO DE LA ACTIVA

select @w_saldo_capital = sum(am_cuota+am_gracia-am_pagado)
from   ca_amortizacion, ca_rubro_op
where  am_operacion  = @i_operacionca
and    ro_operacion  = @i_operacionca
and    am_concepto   = ro_concepto
and    ro_tipo_rubro = 'C' -- CAPITALES

if @w_tipo_novedad = 'I'
   select @i_tipo_cobro = 'P'

if @w_tipo_novedad = 'C'
   select @w_tipo_reduccion = 'N',
          @w_abono_extraordinario = 'N',
          @w_cancelar     = 'S',
          @i_tipo_cobro   = 'A'
ELSE
   select @w_cancelar     = 'N',
          @i_tipo_cobro   = 'P'      

if @w_abono_extraordinario = 'N' 
   select @w_tipo_reduccion = 'N'

   
if @w_tipo_reduccion = 'N'
begin
   exec @w_error = sp_aplicacion_cuota_normal
        @s_sesn              = @s_sesn,
        @s_user              = @s_user,
        @s_term              = @s_term,
        @s_date              = @s_date,
        @s_ofi               = @s_ofi,
        @i_secuencial_ing    = @i_secuencial_ing,
        @i_secuencial_pag    = @w_secuencial_pag,
        @i_fecha_proceso     = @i_fecha_proceso,
        @i_operacionca       = @i_operacionca,
        @i_en_linea          = @i_en_linea,
        @i_tipo_reduccion    = 'N',
        @i_tipo_cobro        = @i_tipo_cobro,
        @i_monto_pago        = @w_valor_cap_op,  --Valor Prepago va en moneda de la operacion
        @i_cotizacion        = @w_pp_cotizacion,
        @i_tcotizacion       = @w_tcotizacion,
        @i_num_dec           = @w_num_dec_op,
        @i_saldo_capital     = @w_saldo_capital,
        @i_dias_anio         = @w_dias_anio,
        @i_base_calculo      = @w_base_calculo,
        @i_tipo              = @w_tipo,
        @i_aceptar_anticipos = 'S',
        @i_tasa_prepago      = @w_tasa_prepago,
        @i_saldo_oper        = @w_saldo_capital,
        @i_cancelar          = @w_cancelar, ---1
        @i_en_gracia_int     = @i_en_gracia_int,
        @i_prepago           = 'S',
        @o_sobrante          = @w_monto_sobrante out
   
   if @w_error != 0
      return @w_error

end  
ELSE 
begin
   exec @w_error = sp_aplicacion_concepto
        @s_sesn           = @s_sesn,
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @i_secuencial_ing = @i_secuencial_ing,
        @i_secuencial_pag = @w_secuencial_pag,
        @i_fecha_proceso  = @i_fecha_proceso,
        @i_operacionca    = @i_operacionca,
        @i_en_linea       = @i_en_linea,
        @i_tipo_reduccion = @w_tipo_reduccion,
        @i_tipo_aplicacion= 'C',
        @i_tipo_cobro     = @i_tipo_cobro,
        @i_monto_pago     = @w_valor_cap_op,
        @i_cotizacion     = @w_pp_cotizacion,
        @i_tcotizacion    = @w_tcotizacion,
        @i_num_dec        = @w_num_dec_op,
        @i_tipo_tabla     = @w_tipo_tabla,
/*        @i_en_gracia_int  = @i_en_gracia_int, */
        @o_sobrante       = @w_monto_sobrante out
   
   if @w_error != 0
      return @w_error     
   
   if @w_monto_sobrante > 0
   begin        
      select @w_div_vigente = di_dividendo
      from   ca_dividendo
      where  di_operacion =  @i_operacionca
      and    di_estado    =  1
      
      if @@rowcount = 0
         return 710090
      
      -- APLICACION DEL ABONO EXTRAORDINARIO
      
      
      exec @w_error = sp_abono_extraordinario
           @s_ssn             = @s_ssn,
           @s_sesn            = @s_sesn,
           @s_user            = @s_user,
           @s_term            = @s_term,
           @s_date            = @s_date,
           @s_ofi             = @s_ofi,
           @s_srv             = @s_srv,
           @s_lsrv            = @s_lsrv,
           @i_secuencial_ing  = @i_secuencial_ing,
           @i_secuencial_pag  = @w_secuencial_pag,
           @i_fecha_proceso   = @i_fecha_proceso,
           @i_operacion       = @i_operacionca,
           @i_en_linea        = @i_en_linea,
           @i_tipo_reduccion  = @w_tipo_reduccion,
           @i_tipo_aplicacion = @w_tipo_aplicacion,
           @i_monto_pago      = @w_monto_sobrante, 
           @i_cotizacion      = @w_pp_cotizacion,
           @i_tcotizacion     = @w_tcotizacion,
           @i_num_dec         = @w_num_dec_op,
           @i_dividendo       = @w_div_vigente,
           @i_tipo_tabla      = @w_tipo_tabla,
/*           @i_tipo_aplicacion = @w_tipo_aplicacion,  */
           @i_prepago         = 'S',
           @o_monto_sobrante  = @w_monto_sobrante out
      
      if @w_error != 0
         return @w_error
         
   end -- SOBRANTE
end

---VALIDAR CANCELACION CAPITAL
select @w_estado_op = op_estado
from   ca_operacion
where  op_operacion = @i_operacionca

select @w_saldo_capital = 0

select @w_saldo_capital = isnull(sum(am_cuota+am_gracia-am_pagado),0)
from   ca_amortizacion, ca_rubro_op
where  am_operacion  = @i_operacionca
and    ro_operacion  = @i_operacionca
and    am_concepto   = ro_concepto
and    ro_tipo_rubro = 'C' -- CAPITALES

if @w_saldo_capital = 0 and  @w_monto_sobrante < @w_vlr_despreciable and @w_estado_op != 3
begin   
   
   select @w_recalcular_int = 'N'
      
   update ca_operacion
   set    op_estado = 3
   where  op_operacion = @i_operacionca
   
   if @@error <> 0
      return 710002
   
   update ca_dividendo
   set    di_estado    = 3,
          di_fecha_can = @w_op_fecha_ult_proceso
   where  di_operacion = @i_operacionca
   and    di_estado != 3
   
   if @@error <> 0
     return 710002
   
   
   --DEF:7424:NOV:09:2006:EPB
   --select @w_rowcount_act = sqlcontext.gettriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN', 'N')
-- EXEC sp_addextendedproperty
--      'CCA_TRIGGER','S',@level0type='Schema',@level0name=dbo,
--       @level1type='Table',@level1name=ca_amortizacion,
--       @level2type='Trigger',@level2name=tg_ca_amortizacion_can

   update ca_amortizacion
   set    am_estado    = 3
   where  am_operacion = @i_operacionca
   and    am_estado != 3
   
   if @@error <> 0
   begin
     -- select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--   EXEC sp_dropextendedproperty
--        'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--        @level1type='Table',@level1name=ca_amortizacion,
--        @level2type='Trigger',@level2name=tg_ca_amortizacion_can
     return 710002
   end
  --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')   
--    EXEC sp_dropextendedproperty
--      'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--        @level1type='Table',@level1name=ca_amortizacion,
--        @level2type='Trigger',@level2name=tg_ca_amortizacion_can
    
end


if @w_monto_sobrante >= @w_vlr_despreciable
   return 710511

select @w_estado_op = op_estado
from   ca_operacion
where  op_operacion = @i_operacionca

--ANALIZAR SI HAY RECALCUO INTERESES DE CUOTA VIGENTE
--======================================================

if @w_estado_op != 3 
begin
   select  @w_recalcular_int = 'N'
   
   --SI ALMENOS QUEDA UN VIGENTE SE REGENERA LA TABLA
   select @w_nuevo_vigente = isnull(max(di_dividendo), 0)
   from ca_dividendo
   where di_operacion =  @i_operacionca  
   and   di_estado = 1

   if @w_nuevo_vigente = @w_div_vigente     ---EL PREPAGO SOLO FUE PARA UNA CUOTA
   begin
      select  @w_recalcular_int = 'S'        ---VALIDAR EL ESTADO DE LA CUOTA VIGENTE
      select @w_est_divvigente = di_estado
      from ca_dividendo
      where di_operacion = @i_operacionca
      and di_dividendo = @w_div_vigente

   -- MODIFICACION SOLO DE LA PARTE DE INTERES DESDE LA VIGENTE      
      if @w_est_divvigente = 1
      begin
         update ca_amortizacion
         set am_estado = 1
         where am_operacion = @i_operacionca
         and   am_dividendo = @w_div_vigente
         and   am_cuota > am_pagado
      end
   end

   if @w_recalcular_int = 'S'  
   begin   
      --SE SACA EL ACUMULADO HASTA LA FECHA POR LOS DIAS TRASCURRIDOS
      
      select @w_nuevo_acumulado = 0
      exec @w_error = sp_calc_intereses
           @tasa           = @w_tasa_int,
           @monto          = @w_saldo_capital,
           @dias_anio      = 360,
           @num_dias       = @w_pp_dias_de_interes,
           @causacion      = 'L', 
           @causacion_acum = 0, 
           @intereses      = @w_valor_calc out
      
      if @w_error != 0  
         return @w_error
   
      select @w_nuevo_acumulado = round(@w_valor_calc,@w_num_dec_op)
      
      update ca_amortizacion
      set    am_acumulado   =  @w_nuevo_acumulado,
             am_pagado      = 0
      where  am_operacion  =  @i_operacionca
      and    am_dividendo  =  @w_div_vigente
      and    am_concepto   =  @w_concepto_int
      

   end
   
   exec @w_error = sp_reajuste_interes 
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @i_operacionca    = @i_operacionca,   
        @i_fecha_proceso  = @i_fecha_proceso,
        @i_banco          = @w_banco,
        @i_en_linea       = @i_en_linea,
        @i_prepas         = 'S'  --DEFECTO 7489 BAC
   
   if @w_error != 0 
      return @w_error
end

-- MARCAR COMO APLICADO EL ABONO
update ca_abono
set    ab_estado         = 'A',
       ab_secuencial_pag = @w_secuencial_pag
where  ab_secuencial_ing = @i_secuencial_ing
and    ab_operacion      = @i_operacionca

if @@error != 0 
   return 705048


---INSERTAR VALORES DE:
---1. REVERSO DE CAUSACION A LA FECHA
---2. CAUSACION DEL INT PAGADO
---3. NUEVA CAUSACION POR RECALCULO EN CUOTA VIGENTE 
--- TODO LO ANTERIOR EN LA PRV DESPUES DEL PAGO GENERADA POR EL TRIGGER
select @w_codvalor = (co_codigo*1000) + (1*10) + 0
from   ca_concepto
where  co_concepto  = @w_concepto_int

--- REVERSION DE LA CAUSACION ACTUAL
---SECUENCIAL REVERSO CAUSACION HASTA LA FECHA

exec @w_error = sp_valida_existencia_prv
     @s_user                = @s_user,
     @s_term                = @s_term,
     @s_date                = @s_date,
     @s_ofi                 = @s_ofi,
     @i_en_linea            = @i_en_linea,
     @i_operacionca         = @i_operacionca,
     @i_fecha_proceso       = @w_op_fecha_ult_proceso,
     @i_tr_observacion      = 'PREPAGO PASIVA',
     @i_gar_admisible       = @w_gar_admisible,
     @i_reestructuracion    = @w_reestructuracion,
     @i_calificacion        = @w_calificacion,
     @i_toperacion          = @w_toperacion,
     @i_moneda              = @w_moneda_op,
     @i_oficina             = @w_oficina_op,
     @i_banco               = @w_banco,
     @i_gerente             = @w_gerente,
     @i_moneda_uvr          = 2,
     @i_tipo                = @w_tipo,
     @i_tran                = 'PRV',
     @i_secuencial_ref      = -999,
     @o_secuencial          = @w_secuencial_prv OUT

if @w_error != 0
begin
   PRINT 'No se genero transaccion PRV para el prepago'
   return @w_error
end
ELSE 
begin --Sec PRV
   ---1. REVERSO DE CAUSACION A LA FECHA
   
   select @w_monto_mn = 0
   exec @w_error =  sp_conversion_moneda
        @s_date             = @i_fecha_proceso, 
        @i_opcion           = 'L',
        @w_moneda_monto     = @w_moneda_op,
        @w_moneda_resultado = @w_moneda_local,
        @i_monto            = @w_am_acumulado_ini,
        @i_fecha            = @i_fecha_proceso, 
        @o_monto_resultado  = @w_monto_mn out,
        @o_tipo_cambio      = @w_cot_mn out
   
   if @w_error != 0 
      return  @w_error

   
   insert into ca_det_trn
         (dtr_secuencial,    dtr_operacion,    dtr_dividendo,
          dtr_concepto,
          dtr_estado,        dtr_periodo,      dtr_codvalor,
          dtr_monto,         dtr_monto_mn,     dtr_moneda,
          dtr_cotizacion,    dtr_tcotizacion,  dtr_afectacion,
          dtr_cuenta,        dtr_beneficiario, dtr_monto_cont)
   values(@w_secuencial_prv, @i_operacionca,   0,
          @w_concepto_int,
          1,                 0,                @w_codvalor,
          -@w_am_acumulado_ini,  -@w_monto_mn,     @w_pp_moneda,
          @w_cot_mn,         'N',              'D',
          '',                'REV DEL INT ACUMULADO A LA FECHA', 0)
   
   if @@error <> 0  
   begin
      PRINT 'Aplicpas.sp ca_Det_trn  Error @w_monto_mn ' + cast(@w_monto_mn as varchar)
      return  710001
   end
   ---2. REGISTRO DEL VALOR DEL INTERS QUE SE PAGA A FINAGRO
   
   
   select @w_monto_mn = 0
   exec @w_error =  sp_conversion_moneda
        @s_date             = @i_fecha_proceso,
        @i_opcion           = 'L',
        @w_moneda_monto     = @w_moneda_op,
        @w_moneda_resultado = @w_moneda_local,
        @i_monto            = @w_valor_interes,
        @i_fecha            = @i_fecha_proceso,
        @o_monto_resultado  = @w_monto_mn out,
        @o_tipo_cambio      = @w_cot_mn out
   
   if @w_error != 0 
      return  @w_error
   
   insert into ca_det_trn
         (dtr_secuencial,    dtr_operacion,    dtr_dividendo,
          dtr_concepto,
          dtr_estado,        dtr_periodo,      dtr_codvalor,
          dtr_monto,         dtr_monto_mn,     dtr_moneda,
          dtr_cotizacion,    dtr_tcotizacion,  dtr_afectacion,
          dtr_cuenta,        dtr_beneficiario, dtr_monto_cont)
   values(@w_secuencial_prv, @i_operacionca,   0, 
          @w_concepto_int,
          1,                 0,                @w_codvalor,
          @w_valor_interes,  @w_monto_mn,      @w_pp_moneda,
          @w_cot_mn,         'N',              'D',
          '',                'INT DEL PREPAGO',0)
   
   if @@error <> 0  
   begin
      PRINT 'Aplicpas.sp ca_Det_trn 1   Error @w_monto_mn ' + cast(@w_monto_mn as varchar)
      return  710001
   end
   
   
   if @w_nuevo_acumulado > 0 and @w_tipo_novedad != 'C'
   begin
      -- COTIZACION MONEDA
      select @w_monto_mn = 0
      exec @w_error =  sp_conversion_moneda
           @s_date             = @i_fecha_proceso,
           @i_opcion           = 'L',
           @w_moneda_monto     = @w_moneda_op,
           @w_moneda_resultado = @w_moneda_local,
           @i_monto            = @w_nuevo_acumulado,
           @i_fecha            = @i_fecha_proceso,
           @o_monto_resultado  = @w_monto_mn out,
           @o_tipo_cambio      = @w_cot_mn out
      
      if @w_error != 0 
         return  @w_error
      
      ---3. NUEVA CAUSACION POR RECALCULO EN CUOTA VIGENTE 
        
      insert into ca_det_trn
            (dtr_secuencial,     dtr_operacion,    dtr_dividendo,
             dtr_concepto,
             dtr_estado,         dtr_periodo,      dtr_codvalor,
             dtr_monto,          dtr_monto_mn,     dtr_moneda,
             dtr_cotizacion,     dtr_tcotizacion,  dtr_afectacion,
             dtr_cuenta,         dtr_beneficiario, dtr_monto_cont)
      values(@w_secuencial_prv,  @i_operacionca,   0,
             @w_concepto_int,
             1,                  0,                @w_codvalor,
             @w_nuevo_acumulado, @w_monto_mn,      @w_pp_moneda,
             @w_cot_mn,          'N',              'D',
             '',                 'NUEVO INT RECALCULO',               0)
      
      if @@error <> 0  
      begin
         PRINT 'Aplicpas.sp ca_Det_trn  2  Error @w_monto_mn ' + cast(@w_monto_mn as varchar) + ' @w_nuevo_acumulado ' +  + cast(@w_nuevo_acumulado as varchar)
         return  710001
      end
      
   end      
end --Sec PRV

---INSERTAR NUEVAMENTE EL RUBRO INT

insert into   ca_abono_prioridad
values (@i_secuencial_ing,@i_operacionca,@w_concepto_int ,0)


return 0

go
