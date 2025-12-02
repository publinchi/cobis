/************************************************************************/
/*   Nombre Fisico:       abonofac.sp                                   */
/*   Nombre Logico:    	  sp_abono_factoring                            */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Xavier Maldonado.                             */
/*   Fecha de escritura:  Nov. 2000                                     */
/************************************************************************/
/*                                 IMPORTANTE                           */
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
/*                                  PROPOSITO                           */
/*   Consulta para front end de pagos de factoring                      */
/************************************************************************/  
/*                              CAMBIOS                                 */
/*      FECHA            AUTOR       CAMBIO                             */
/*      FEB-14-2002      RRB         Agregar campos al insert           */
/*                                   en ca_transaccion                  */
/*      MAR-07-2005      EPB         Insert tr_fecha_ref ok             */
/*    	JUN/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abono_factoring')
   drop proc sp_abono_factoring
go

create proc sp_abono_factoring
(  @s_date            datetime = null,
   @s_user            login = null,
   @s_ofi             smallint = null,
   @s_term            varchar(30) = null,
   @s_sesn            int = null,
   @i_operacionca     int,
   @i_secuencial_ing  int,
   @i_fecha_proceso   datetime,
   @i_dividendo       smallint,
   @i_en_linea        char(1) = NULL
)
as
declare
   @w_return              int,
   @w_fecha_proceso       datetime,
   @w_debito              varchar(1),
   @w_credito             varchar(1),
   @w_est_cancelado       tinyint,
   @w_secuencial_rpa      int,
   @w_secuencial_pag      int,
   @w_tipo_cobro          varchar(1),
   @w_tipo_reduccion      varchar(1),
   @w_tipo                varchar(3),
   @w_tipo_aplicacion     varchar(1),
   @w_dividendo           smallint,
   @w_banco               cuenta,
   @w_toperacion          catalogo,
   @w_moneda_op           tinyint,
   @w_oficina_op          smallint,
   @w_tipo_op             varchar(1),
   @w_estado              tinyint,
   @w_fecha_ven           datetime,
   @w_fecha_ini           datetime,
   @w_di_estado           tinyint,
   @w_num_dec_op          tinyint,
   @w_moneda_mn           tinyint,
   @w_num_dec_mn          tinyint,
   @w_monto_mop           money,
   @w_monto_con           money,
   @w_cotizacion          money,
   @w_tcotizacion         varchar(1),
   @w_concepto            catalogo,
   @w_monto_rubro         money,
   @w_monto_prioridad     money,
   @w_inicial_rubro       money,
   @w_inicial_prioridad   money,
   @w_prioridad           int,
   @w_am_concepto         catalogo,
   @w_ro_tipo_rubro       varchar(1),
   @w_monto_asoc          money,
   @w_rubro_asoc          catalogo,
   @w_porcentaje          float,
   @w_abd_concepto        catalogo,
   @w_cp_codvalor         int,
   @w_abd_monto_mpg       money,
   @w_abd_monto_mn        money,
   @w_abd_moneda          tinyint,
   @w_abd_cotizacion_mpg  money,
   @w_abd_tcotizacion_mpg varchar(1),
   @w_abd_cuenta          cuenta,
   @w_abd_beneficiario    varchar(50),
   @w_div_vigente         int,
   @w_fpago               varchar(1),
   @w_gerente             smallint,
   @w_concepto_puente     catalogo,
   @w_gar_admisible       char(1), ---RRB:feb-14-2002 para ley 50
   @w_reestructuracion    char(1), ---RRB:feb-14-2002 para ley 50
   @w_calificacion        catalogo, ---RRB:feb-14-2002 para ley 50 ---> MCO 05/06/2023 Se cambio el tipo de dato de char(1) a catalogo
   --
   @w_dias_anio           int,
   @w_sector              catalogo,
   @w_fecha_liq           datetime,
   @w_fecha_u_proceso     datetime,
   @w_tdividendo          catalogo,
   @w_clausula            char,
   @w_base_calculo        catalogo,
   @w_dias_div            int,
   @w_causacion           varchar(1),
   @w_tipo_tabla          catalogo,
   @w_fecha_a_causar      datetime

-- INICIALIZACION DE VARIABLES
select @w_fecha_proceso = convert(varchar(10), @s_date, 101),
       @s_term          = isnull(@s_term, 'consola'),
       @w_debito        = 'D',
       @w_credito       = 'C'

select @w_est_cancelado = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CANCELADO'

select @w_div_vigente = @i_dividendo

--  DATOS DEL ABONO
select @w_secuencial_rpa  = ab_secuencial_rpa,
       @w_tipo_cobro      = ab_tipo_cobro,
       @w_tipo_reduccion  = ab_tipo_reduccion,
       @w_tipo            = ab_tipo,
       @w_tipo_aplicacion = ab_tipo_aplicacion,
       @w_dividendo       = ab_dividendo
from   ca_abono
where  ab_operacion      = @i_operacionca
and    ab_secuencial_ing = @i_secuencial_ing
and    ab_secuencial_rpa is not null

if @@rowcount = 0
   return 701119

-- DATOS DE CA_OPERACION
select @w_banco            = op_banco,
       @w_toperacion       = op_toperacion,
       @w_moneda_op        = op_moneda,
       @w_oficina_op       = op_oficina,
       @w_tipo_op          = op_tipo,
       @w_estado           = op_estado,
       @w_gerente          = op_oficial,
       @w_gar_admisible    = op_gar_admisible,       ---RRB:feb-14-2002 para ley 50
       @w_reestructuracion = op_reestructuracion,   ---RRB:feb-14-2002 para ley 50
       @w_calificacion     = op_calificacion,       ---RRB:feb-14-2002 para ley 50
       @w_dias_anio        = op_dias_anio,
       @w_sector           = op_sector,
       @w_fecha_liq        = op_fecha_liq,
       @w_fecha_ini        = op_fecha_ini,
       @w_fecha_u_proceso  = op_fecha_ult_proceso,
       @w_tdividendo       = op_tdividendo,
       @w_clausula         = op_clausula_aplicada,
       @w_base_calculo     = op_base_calculo,
       @w_causacion        = op_causacion,
       @w_tipo_tabla       = op_tipo_amortizacion,
       @w_dias_div         = op_periodo_int
from   ca_operacion 
where  op_operacion = @i_operacionca

if @@rowcount = 0
   return 701025

if @w_estado = @w_est_cancelado
   return 708158

---------------------------------*********
if @w_tipo_op = 'R' -- PASIVAS
begin
   if @w_tipo_tabla != 'MANUAL'
   begin
      select @w_dias_div = @w_dias_div * td_factor
      from   ca_tdividendo
      where  td_tdividendo = @w_tdividendo
   end
   else
      select @w_dias_div = max(di_dias_cuota)
      from   ca_dividendo
      where  di_operacion = @i_operacionca
      and    di_estado = 1
   
   select @w_return = 0,
          @w_fecha_a_causar = dateadd(dd, -1, @w_fecha_u_proceso)

-- SELECCIONAR LA COTIZACION Y EL TIPO DE COTIZACION
select @w_cotizacion  = abd_cotizacion_mop,
       @w_tcotizacion = abd_tcotizacion_mop
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca

   
   exec @w_return = sp_calculo_diario_int
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
        @i_oficina           = @s_ofi,
        @i_fecha_liq         = @w_fecha_liq,
        @i_fecha_ini         = @w_fecha_ini,
        @i_fecha_proceso     = @w_fecha_a_causar,
        @i_tdividendo        = @w_tdividendo,
        @i_clausula_aplicada = @w_clausula,
        @i_base_calculo      = @w_base_calculo,
        @i_dias_interes      = @w_dias_div,
        @i_causacion         = @w_causacion,
        @i_tipo              = @w_tipo_op,
        @i_gerente           = @w_gerente,
        @i_cotizacion        = @w_cotizacion
   
   if @w_return != 0
      return @w_return
end
-----------------------------------*******

select @w_concepto_puente = 'VAC' + convert(varchar(10),@w_moneda_op)

-- DATOS DEL DIVIDENDO
select @w_fecha_ven = di_fecha_ven,
       @w_fecha_ini = di_fecha_ini,
       @w_di_estado = di_estado
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_dividendo = @w_dividendo

if @@rowcount = 0
   return 701025

if @w_di_estado = @w_est_cancelado
   return 708158

-- MANEJO DE DECIMALES
exec @w_return = sp_decimales
     @i_moneda      = @w_moneda_op,
     @o_decimales   = @w_num_dec_op out
/*     @o_moneda_n    = @w_moneda_mn out, 
     @o_decimales_n = @w_num_dec_mn out   */

if @w_return != 0
   return @w_return 

-- CALCULAR EL MONTO DEL PAGO
select @w_monto_mop = sum(abd_monto_mop)
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca
and    abd_tipo in ('PAG','SOB')           --XSA

/* FQ - PILAS CON ESTO
select * from ca_abono_det

if @@rowcount = 0 return 710035 
*/

/* -- SELECCIONAR LA COTIZACION Y EL TIPO DE COTIZACION
select @w_cotizacion  = abd_cotizacion_mop,
       @w_tcotizacion = abd_tcotizacion_mop
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca */

if @@rowcount = 0
   return 710035 

if isnull(@w_monto_mop,0) <> 0 
begin
   exec @w_secuencial_pag = sp_gen_sec
        @i_operacion      = @i_operacionca
   
   -- OBTENER RESPALDO ANTES DE LA APLICACION DEL PAGO
   exec @w_return = sp_historial
        @i_operacionca = @i_operacionca,
        @i_secuencial  = @w_secuencial_pag
   
   if @@error != 0
      return @w_return
   
   -- INSERCION DE CABECERA CONTABLE DE CARTERA
   insert into ca_transaccion
         (tr_operacion,        tr_tran,          tr_secuencial,
          tr_fecha_mov,        tr_toperacion,    tr_moneda,
          tr_en_linea,         tr_banco,         tr_dias_calc,
          tr_ofi_oper,         tr_ofi_usu,       tr_usuario,
          tr_terminal,         tr_fecha_ref,     tr_secuencial_ref,
          tr_estado,           tr_gerente,       tr_gar_admisible,   ---RRB:feb-14-2002 para ley 50
          tr_reestructuracion, tr_calificacion,    ---RRB:feb-14-2002 para ley 50
          tr_observacion,      tr_fecha_cont,     tr_comprobante)
   values(@i_operacionca,      'PAG',            @w_secuencial_pag,
          @s_date,             @w_toperacion,    @w_moneda_op,
          @i_en_linea,         @w_banco,         0,
          @w_oficina_op,       @s_ofi,           @s_user,
          @s_term,             @w_fecha_u_proceso, @w_secuencial_rpa,
          'ING',               @w_gerente,       isnull(@w_gar_admisible,''),   ---RRB:feb-14-2002 para ley 50
          isnull(@w_reestructuracion,''),isnull(@w_calificacion,''),   ---RRB:feb-14-2002 para ley 50
          '',                  @s_date,        0)   
   
   if @@error != 0
      return 710001
   
   -- INSERCION DE CUENTA PUENTE PARA LA APLICACION DEL PAGO
   insert ca_det_trn
         (dtr_secuencial,    dtr_operacion,    dtr_dividendo,
          dtr_concepto,
          dtr_estado,        dtr_periodo,      dtr_codvalor,
          dtr_monto,         dtr_monto_mn,     dtr_moneda,
          dtr_cotizacion,    dtr_tcotizacion,  dtr_afectacion,
          dtr_cuenta,        dtr_beneficiario, dtr_monto_cont)
   select @w_secuencial_pag, dtr_operacion,    dtr_dividendo,
          dtr_concepto,
          dtr_estado,        dtr_periodo,      dtr_codvalor,
          dtr_monto,         dtr_monto_mn,     dtr_moneda,
          dtr_cotizacion,    dtr_tcotizacion,  @w_debito,
          dtr_cuenta,        dtr_beneficiario, dtr_monto_cont
   from   ca_det_trn
   where  dtr_secuencial = @w_secuencial_rpa
   and    dtr_operacion  = @i_operacionca
   and    dtr_concepto   = @w_concepto_puente
   
   if @@error != 0
      return 710001
end

--APLICACION DE CONDONACIONES
--SELECCIONO LOS RUBROS A CONDONAR DEL DIVIDENDO
declare cursor_condonaciones cursor
for select abd_concepto, abd_monto_mop, abd_cotizacion_mop,
           abd_tcotizacion_mop
    from   ca_abono_det
    where  abd_secuencial_ing = @i_secuencial_ing
    and    abd_operacion      = @i_operacionca
    and    abd_tipo = 'CON'
    for read only

open cursor_condonaciones

fetch cursor_condonaciones
into  @w_concepto,    @w_monto_con, @w_cotizacion,
      @w_tcotizacion

while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1)
      return 708999
   
   -- MONTO DEL RUBRO A CONDONAR
   exec @w_return = sp_monto_pago_rubro
        @i_operacionca   = @i_operacionca,
        @i_dividendo     = @w_dividendo,
        @i_tipo_cobro    = 'A',
        @i_fecha_pago    = @i_fecha_proceso,
        @i_concepto      = @w_concepto,
        @i_dividendo_vig = @w_div_vigente,
        @o_monto         = @w_monto_rubro out
   
   if @w_return != 0
      return @w_return
   
   PRINT 'abonofac.sp salio  de sp_monto_pago_rubro con  @w_monto_rubro ' + cast(@w_monto_rubro as varchar)
   
   select @w_fpago = ro_fpago from ca_rubro_op
   where  ro_operacion = @i_operacionca
   and    ro_concepto  = @w_concepto
   
   -- APLICACION DE LA CONDONACION
   exec @w_return = sp_abona_rubro
        @s_ofi             = @s_ofi,
        @s_sesn            = @s_sesn,
        @s_user            = @s_user,
        @s_date            = @s_date,
        @s_term            = @s_term,
        @i_secuencial_pag  = @w_secuencial_pag,
        @i_operacionca     = @i_operacionca,
        @i_dividendo       = @w_dividendo,
        @i_concepto        = @w_concepto,
        @i_monto_pago      = @w_monto_con,
        @i_monto_prioridad = @w_monto_rubro,
        @i_monto_rubro     =  @w_monto_rubro,
        @i_tipo_cobro      = 'A',
        @i_en_linea        = @i_en_linea,
        @i_fecha_pago      = @i_fecha_proceso,
/*        @i_fecha_ven       = @w_fecha_ven, */
        @i_condonacion     = 'S',
        @i_cotizacion      = @w_cotizacion,
        @i_tcotizacion     = @w_tcotizacion,
        @i_fpago           = @w_fpago,
        @o_sobrante_pago   = @w_monto_con out
   
   if (@w_return != 0)
      return @w_return
   
   if @w_monto_con > 0
      return 710090
   
   fetch cursor_condonaciones
   into  @w_concepto,    @w_monto_con, @w_cotizacion,
         @w_tcotizacion
end

close cursor_condonaciones
deallocate cursor_condonaciones
-- FIN DE APLICACION DE LA CONDONACION

-- MARCAR COMO APLICADO EL ABONO
update ca_abono 
set    ab_estado = 'A',
       ab_secuencial_pag = @w_secuencial_pag
where  ab_operacion      = @i_operacionca
and    ab_secuencial_ing = @i_secuencial_ing

if @@error != 0
   return 705048

-- SELECCIONAR EL MONTO DE APLICACION
select @w_monto_mop = isnull(sum(abd_monto_mop),0)
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca
and    abd_tipo in ('PAG','SOB')

-- APLICACION DEL PAGO
if @w_monto_mop <> 0 
begin  
   -- CURSOR DE RUBROS ORDENADOS POR SUS PRIORIDADES
   declare rubros cursor
   for select ro_prioridad, ro_concepto, ro_tipo_rubro, ro_fpago
       from   ca_rubro_op
       where  ro_operacion = @i_operacionca 
       and    (ro_tipo_rubro = @w_tipo_aplicacion or @w_tipo_aplicacion = 'D')
       order  by ro_prioridad, ro_concepto
       for read only

   open rubros
   fetch rubros
   into @w_prioridad, @w_am_concepto, @w_ro_tipo_rubro, @w_fpago
   
   while @@fetch_status = 0 
   begin
      if (@@fetch_status = -1)
         return 789900
      
      -- MONTO DE LA PRIORIDAD POR TIPO DE COBRO
      exec @w_return = sp_monto_pago
           @i_operacionca    = @i_operacionca,
           @i_dividendo      = @w_dividendo,
           @i_tipo_cobro     = 'A',
           @i_fecha_pago     = @i_fecha_proceso,
           @i_prioridad      = @w_prioridad,
           @i_secuencial_ing = @i_secuencial_ing,
           @i_dividendo_vig  = @w_div_vigente,
           @o_monto          = @w_monto_prioridad out
      
      if @w_return != 0
         return @w_return
      
      if @w_monto_prioridad <= 0  --nada que pagar en esta prioridad
      begin
         fetch rubros
         into  @w_prioridad, @w_am_concepto, @w_ro_tipo_rubro, @w_fpago
         continue
      end
      
      select @w_inicial_prioridad = @w_monto_prioridad
      
      -- NO SE PUEDE PAGAR UN VALOR MAYOR AL VALOR DEL PAGO
      if @w_monto_prioridad >= @w_monto_mop
         select @w_monto_prioridad = @w_monto_mop
      
      -- MONTO DEL RUBRO SELECCIONADO
      exec @w_return = sp_monto_pago_rubro
           @i_operacionca   = @i_operacionca,
           @i_dividendo     = @w_dividendo,
           @i_dividendo_vig = @w_div_vigente,
           @i_tipo_cobro    = 'A',
           @i_fecha_pago    = @i_fecha_proceso,
           @i_concepto      = @w_am_concepto,
           @o_monto         = @w_monto_rubro out,
           @o_monto_asoc    = @w_monto_asoc out,
           @o_rubro_asoc    = @w_rubro_asoc out,
           @o_porcentaje    = @w_porcentaje out
      
      if @w_return != 0
         return @w_return
      
      PRINT 'abonofac.sp salio  de sp_monto_pago_rubro con  @w_monto_rubro  ' + cast(@w_monto_rubro as varchar)
      
      if @w_monto_rubro <= 0
      begin
         fetch rubros
         into  @w_prioridad, @w_am_concepto, @w_ro_tipo_rubro, @w_fpago
         continue
      end
      
      select @w_inicial_rubro = @w_monto_rubro
      
      if @w_monto_prioridad  < @w_monto_rubro
         select @w_monto_rubro = @w_monto_prioridad
      
      if @w_monto_rubro <> 0 
      begin
         -- APLICACION DEL PAGO PARA EL RUBRO
         exec @w_return = sp_abona_rubro
              @s_ofi               = @s_ofi,
              @s_sesn              = @s_sesn,
              @s_user              = @s_user,
              @s_term              = @s_term,
              @s_date              = @s_date,
              @i_secuencial_pag    = @w_secuencial_pag,
              @i_operacionca       = @i_operacionca,
              @i_dividendo         = @w_dividendo,
              @i_concepto          = @w_am_concepto,
              @i_monto_pago        = @w_monto_mop,
              @i_monto_rubro       = @w_monto_rubro,
              @i_monto_prioridad   = @w_monto_prioridad,
/*              @i_monto_asoc        = @w_monto_asoc, */
              @i_rubro_asoc        = @w_rubro_asoc,
              @i_porcentaje        = @w_porcentaje,
              @i_tipo_cobro        = 'A',
              @i_en_linea          = @i_en_linea,
              @i_tipo_rubro        = @w_ro_tipo_rubro,
              @i_fecha_pago        = @i_fecha_proceso,
/*            @i_fecha_ini         = @w_fecha_ini,
              @i_fecha_ven         = @w_fecha_ven,   */
              @i_condonacion       = 'N',
              @i_cotizacion        = @w_cotizacion,
              @i_tcotizacion       = @w_tcotizacion,
              @i_inicial_prioridad = @w_inicial_prioridad,
              @i_inicial_rubro     = @w_inicial_rubro,
              @i_fpago             = @w_fpago,
              @o_sobrante_pago     = @w_monto_mop out
         
         if @w_return != 0
            return @w_return
      end -- FIN DE LA APLICACION DEL PAGO PARA EL RUBRO
      fetch rubros
      into  @w_prioridad, @w_am_concepto, @w_ro_tipo_rubro, @w_fpago
   end -- FIN DEL CURSOR DE RUBROS ORDENADOS POR PRIORIDADES
   
   close rubros
   deallocate rubros
end -- FIN APLICACION DEL PAGO

if @w_monto_mop > 0
   return 710091

-- VERIFICAR CANCELACION DEL DIVIDENDO
if ((select sum(round(am_cuota,@w_num_dec_op) + am_gracia - am_pagado)
     from   ca_amortizacion
     where  am_operacion = @i_operacionca
     and    am_dividendo = @w_dividendo)  < = 0)
begin
   update ca_dividendo
   set    di_estado    = @w_est_cancelado,
          di_fecha_can = @w_fecha_u_proceso
   where  di_operacion = @i_operacionca
   and    di_dividendo = @w_dividendo
end

-- VERIFICAR CANCELACION DE LA OPERACION
if (select sum(am_cuota) - sum(am_pagado)
    from   ca_amortizacion, ca_rubro_op
    where  am_operacion = @i_operacionca
    and    ro_operacion = @i_operacionca
    and    ro_operacion = am_operacion
    and    ro_tipo_rubro in ('C','M')
    and    am_concepto = ro_concepto) = 0.00
begin
   update ca_operacion
   set    op_estado    = @w_est_cancelado
   where  op_operacion = @i_operacionca 
end

/********************* XMA POR DEFINICION DEL BANCO
SOLO SE REGISTRARA CONTABLEMENTE LAS 'DEVOLUCIONES'

-- GENERACION DE LOS ASIENTOS POR DEVOLUCION DE INTERES ANTICIPADO
declare cursor_detalle cursor
for select abd_concepto,        isnull(cp_codvalor,0), abd_monto_mpg,
           abd_monto_mn,        abd_moneda,            abd_cotizacion_mpg,
           abd_tcotizacion_mpg, isnull(abd_cuenta,''), isnull(abd_beneficiario,'')
    from   ca_abono_det, ca_producto
    where  abd_secuencial_ing = @i_secuencial_ing
    and    abd_operacion      = @i_operacionca
    and    abd_tipo = 'DEV' 
    and    abd_concepto *= cp_producto
    for read only 

open cursor_detalle

fetch cursor_detalle
into  @w_abd_concepto,        @w_cp_codvalor, @w_abd_monto_mpg,
      @w_abd_monto_mn,        @w_abd_moneda,  @w_abd_cotizacion_mpg,
      @w_abd_tcotizacion_mpg, @w_abd_cuenta,  @w_abd_beneficiario

-- CURSOR PARA LOS DETALLES DE LAS FORMAS DE PAGO DE DEVOLUCION
while @@fetch_status = 0 
begin 
   if @@fetch_status = -1
      return 789900
   
   -- INSERCION DEL DETALLE DE LA TRANSACCION
   insert ca_det_trn
         (dtr_secuencial,            dtr_operacion,                  dtr_dividendo,
          dtr_concepto,
          dtr_estado,                dtr_periodo,                    dtr_codvalor,
          dtr_monto,                 dtr_monto_mn,                   dtr_moneda,
          dtr_cotizacion,            dtr_tcotizacion,                dtr_afectacion,
          dtr_cuenta,                dtr_beneficiario,               dtr_monto_cont)
   values(@w_secuencial_pag,         @i_operacionca,                 @w_dividendo,
          @w_abd_concepto,
          0,                         0,                              @w_cp_codvalor,
          @w_abd_monto_mpg,          @w_abd_monto_mn,                @w_abd_moneda,
          @w_abd_cotizacion_mpg,     @w_abd_tcotizacion_mpg,         @w_credito,
          isnull(@w_abd_cuenta, ''), isnull(@w_abd_beneficiario,''), 0)
   
   if @@error != 0
      return 710031
   
   fetch cursor_detalle
   into @w_abd_concepto,        @w_cp_codvalor, @w_abd_monto_mpg,
        @w_abd_monto_mn,        @w_abd_moneda,  @w_abd_cotizacion_mpg,
        @w_abd_tcotizacion_mpg, @w_abd_cuenta,  @w_abd_beneficiario 
end  -- FIN DEL CURSOR DETALLE DE DEVOLUCION

close cursor_detalle
deallocate cursor_detalle

-- FIN GENERACION DE ASIENTOS POR DEVOLUCION DE INTERES ANTICIPADO

**************************************************/

-- XMA INGRESO TRANSACCION POR DEVOLUCION POR PAGO ANTICIPADO
select @w_estado = di_estado
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_dividendo = @w_dividendo          

if @w_fecha_proceso < @w_fecha_ven  and @w_estado = @w_est_cancelado
begin
   exec @w_secuencial_pag = sp_gen_sec
        @i_operacion      = @i_operacionca
   
   -- OBTENER RESPALDO ANTES DE LA APLICACION DEL PAGO
   exec @w_return  = sp_historial
        @i_operacionca  = @i_operacionca,
        @i_secuencial   = @w_secuencial_pag
   
   if @@error != 0
      return @w_return  
   
   -- INSERCION DE CABECERA CONTABLE DE CARTERA
   insert into ca_transaccion
         (tr_operacion,        tr_tran,          tr_secuencial,
          tr_fecha_mov,        tr_toperacion,    tr_moneda,
          tr_en_linea,         tr_banco,         tr_dias_calc,
          tr_ofi_oper,         tr_ofi_usu,       tr_usuario,
          tr_terminal,         tr_fecha_ref,     tr_secuencial_ref,
          tr_estado,           tr_gerente,       tr_gar_admisible,   ---RRB:feb-14-2002 para ley 50
          tr_reestructuracion, tr_calificacion,     ---RRB:feb-14-2002 para ley 50
          tr_observacion,      tr_fecha_cont,    tr_comprobante)
   values(@i_operacionca,      'PAG',            @w_secuencial_pag,
          @s_date,             @w_toperacion,    @w_moneda_op,
          @i_en_linea,         @w_banco,         0,
          @w_oficina_op,       @s_ofi,           @s_user,
          @s_term,             @w_fecha_u_proceso, @w_secuencial_rpa,
          'ING',               @w_gerente,       isnull(@w_gar_admisible,''),   ---RRB:feb-14-2002 para ley 50
          isnull(@w_reestructuracion,''),isnull(@w_calificacion,''),   ---RRB:feb-14-2002 para ley 50
          '',		       @s_date,         0)
   
   if @@error != 0
      return 710001
   
   -- INSERCION DE CUENTA PUENTE PARA LA APLICACION DEL PAGO
   insert ca_det_trn
         (dtr_secuencial,    dtr_operacion,    dtr_dividendo,
          dtr_concepto,
          dtr_estado,        dtr_periodo,      dtr_codvalor,
          dtr_monto,         dtr_monto_mn,     dtr_moneda,
          dtr_cotizacion,    dtr_tcotizacion,  dtr_afectacion,
          dtr_cuenta,        dtr_beneficiario, dtr_monto_cont)
   select @w_secuencial_pag, dtr_operacion,    dtr_dividendo,
          dtr_concepto,
          dtr_estado,        dtr_periodo,      dtr_codvalor,
          dtr_monto,         dtr_monto_mn,     dtr_moneda,
          dtr_cotizacion,    dtr_tcotizacion,  @w_debito,
          dtr_cuenta,        dtr_beneficiario, dtr_monto_cont
   from   ca_det_trn
   where  dtr_secuencial = @w_secuencial_rpa
   and    dtr_operacion  = @i_operacionca
   and    dtr_concepto   = @w_concepto_puente
   
   if @@error != 0
      return 710001
end

return 0
go

