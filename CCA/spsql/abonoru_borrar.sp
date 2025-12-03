/************************************************************************/
/*   Nombre Fisico:        abonoru.sp                                   */
/*   Nombre Logico:        sp_abona_rubro_borrar                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         MPO                                          */
/*   Fecha de escritura:   Diciembre/1997                               */
/************************************************************************/
/*                           IMPORTANTE                                 */
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
/*   Procedimiento que realiza el abono de los rubros de Cartera.       */
/************************************************************************/  
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/*      FEB-2003                EPB           Personalizacion BAC       */
/*      JUL-2005                EPB           Defecto      4172         */
/*      10/OCT/2005    FDO CARVAJAL    DIFERIDOS REQ 389                */
/*    	JUN/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*      NOV/07/2023  Kevin Rodriguez  Actualiza valor despreciab        */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abona_rubro_borrar')
   drop proc sp_abona_rubro_borrar
go

create proc sp_abona_rubro_borrar
@s_ofi                  smallint,
@s_sesn                 int,
@s_user                 login,
@s_term                 varchar (30)    = NULL,
@s_date                 datetime        = NULL,
@i_secuencial_pag       int,            -- Secuencial del pago (PAG)
@i_operacionca          int,            -- Operacion a la que pertenece el rubro
@i_dividendo            smallint,       -- Dividendo al cual pertenece el rubro
@i_concepto             catalogo,       -- Rubro a abonar
@i_rubro_asoc           catalogo        = NULL,
@i_porcentaje           float           = NULL,
@i_monto_pago           money,          -- Monto Total del abono
@i_monto_prioridad      money,          -- Monto Total de la prioridad
@i_monto_rubro          money,          -- Monto del Rubro a Aplicar
@i_tipo_cobro           char(1),        -- Tipo de Cobro A, P, E
@i_en_linea             char(1)         = NULL,
@i_tipo_rubro           char(1)         = NULL,   
@i_fecha_pago           datetime        = NULL,
@i_condonacion          char(1)         = 'N',
@i_colchon              char(1)         = 'N',
@i_cotizacion           money           = NULL,
@i_tcotizacion          char(1)         = NULL,
@i_inicial_prioridad    float           = NULL,
@i_inicial_rubro        float           = NULL,
@i_extraordinario       tinyint         = 0,
@i_fpago                char(1),
@i_secuencial_ing       int             = NULL,
@i_di_estado            smallint        = NULL,
@i_dias_pagados         int             = NULL,
@i_tasa_pago            float           = NULL,
@i_cotizacion_dia_sus   float           = null, -- CUANDO LA OBLIGACION ESTA EN SUSPENSO Y ES DE MONEDA UVR
                                                -- SE USAN PARA SEPARAR EL VALOR DE CAUSACION SUSPENDIDA
                                                -- DE MORA E INTERES DE CUENTAS DE BALANCE
@i_en_gracia_int        char(1)         = 'N',
@o_sobrante_pago        money           = NULL   out,
@o_valor_aplicado       money           = NULL  out

as
declare 
   @w_error                 int,
   @w_pago                  money,
   @w_pago_rubro            money,
   @w_pago_rubro_mn         money,
   @w_monto_rubro           money,
   @w_codvalor              int,
   @w_codvalor_con1         int,
   @w_codvalor1             int,
   @w_am_pagado             money,
   @w_am_acumulado          float,
   @w_am_estado             tinyint,
   @w_am_periodo            tinyint,
   @w_am_secuencia          tinyint,
   @w_am_gracia             money,
   @w_am_cuota              money,
   @w_est_condonado         tinyint,
   @w_est_vigente           tinyint,
   @w_est_vencido           tinyint,
   @w_est_novigente         tinyint,
   @w_est_cancelado         tinyint,
   @w_op_moneda             smallint,
   @w_moneda_n              smallint,
   @w_toperacion            catalogo,
   @w_afectacion            char(1),
   @w_banco                 cuenta,
   @w_oficina_op            smallint,
   @w_dividendo             int,
   @w_dividendo_aux         int,
   @w_num_dec               tinyint,
   @w_int_ant               catalogo,
   @w_di_fecha_ini          datetime,
   @w_di_fecha_ven          datetime,
   @w_di_dias_cuota         int,
   @w_di_estado             tinyint,
   @w_pago_control          money,
   @w_am_acumulado1         money,
   @w_am_pagado1            money,
   @w_num_dec_n             smallint,
   @w_gerente               smallint, 
   @w_prepago_int           money,    
   @w_secuencial_prepago    int,      
   @w_prepago_int_mn        money,    
   @w_gar_admisible         char(1), 
   @w_reestructuracion      char(1), 
   @w_calificacion          catalogo, -- MCO 05/06/2023 Se cambio el tipo de dato de char(1) a catalogo
   @w_parametro_int         catalogo,
   @w_moneda_uvr            tinyint,
   @w_estado_op             tinyint,
   @w_est_suspenso          tinyint,
   @w_am_estado_ar          tinyint,
   @w_concepto_ar           catalogo,
   @w_afectacion_ar         char(1),
   @w_tipo_rubro            char(1),
   @w_codvalor4             int,
   @w_am_correccion_sus_mn  money,
   @w_am_correc_pag_sus_mn  money,
   @w_factor_vig            float,
   @w_valor_vig_mn          money,
   @w_correc_pag_sus        money,
   @w_codvalor_sus1         int,
   @w_parametro_mora        catalogo,
   @w_parametro_cap         catalogo,
   @w_vlr_despreciable      float,
   @w_tipo_cobro_org        char(1),
   @w_dividendo_max         smallint,
   @w_pago_todo             char(1),
   @w_sum                   money,
   @w_fecha_ult_proceso     datetime,
   @w_rowcount              int

select @w_valor_vig_mn = 0,
       @w_sum          = 0

if @i_cotizacion != 0
   select @w_factor_vig = @i_cotizacion_dia_sus / @i_cotizacion
else
   select @w_factor_vig = 1

-- PARAMETROS GENERAL
select @w_int_ant = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INTANT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0  
   return 710256

select @w_moneda_n = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount =  @@rowcount 
set transaction isolation level read uncommitted

if @w_rowcount = 0
   print 'abonoru.sp No existe parametro MLO'

-- MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
set transaction isolation level read uncommitted

select @w_est_novigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_vigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_condonado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CONDONADO'

select @w_est_cancelado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CANCELADO'

select @w_est_suspenso  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'SUSPENSO'


select @w_parametro_mora = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'IMO' ---Concepto MORA
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted


select @w_parametro_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
   return 701059

select @w_dividendo_max = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @i_operacionca

if @w_dividendo_max > @i_dividendo and @i_fpago = 'A'
   select @w_dividendo_aux = @i_dividendo + 1
else 
   select @w_dividendo_aux = @i_dividendo

-- INFORMACION DE OPERACION
select @w_op_moneda        = op_moneda,
       @w_toperacion       = op_toperacion,
       @w_banco            = op_banco,
       @w_oficina_op       = op_oficina,
       @w_gerente          = op_oficial,
       @w_gar_admisible    = op_gar_admisible,    
       @w_reestructuracion = op_reestructuracion,   
       @w_calificacion     = op_calificacion,       
       @w_estado_op        = op_estado,
       @w_fecha_ult_proceso = op_fecha_ult_proceso
from ca_operacion
where op_operacion  = @i_operacionca

if @@rowcount = 0 
   return 702535

-- LECTURA DE DECIMALES
exec @w_error = sp_decimales
     @i_moneda       = @w_op_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_n out

if @w_error != 0 
   return @w_error

select @w_num_dec  = isnull(@w_num_dec,0)

if @w_op_moneda = 2
   select @w_num_dec_n = 2
 
 
select @w_vlr_despreciable = 1.0 / power(10, (@w_num_dec + 2))

-- AFECTACION DE CUENTA PARA CADA CONCEPTO CANCELADO DEBE SER C
-- POR QUE LA AFECTACION DE LA FORMA DE PAGO ES D
select @w_afectacion = 'C' 

select @w_tipo_rubro = ro_tipo_rubro
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_concepto  = @i_concepto

-- SELECCION DE CODIGO VALOR PARA EL RUBRO
select @w_codvalor = co_codigo
from   ca_concepto
where  co_concepto = @i_concepto

if @@rowcount = 0 
   return 701151


-- Parametro general de Intereses

select @w_parametro_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 
    return  701059



select @w_parametro_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
set transaction isolation level read uncommitted


if @i_concepto = @w_int_ant
begin
   if  @i_di_estado = @w_est_vigente
   begin
      if exists (select 1
                 from   ca_valor_acumulado_antant
                 where  va_operacion      = @i_operacionca
                 and    va_secuencial_ing = @i_secuencial_ing
                 and    va_secuencia      = 1)
      begin
         select @w_codvalor = co_codigo
         from   ca_concepto
         where  co_concepto = @w_parametro_int
         
         if @@rowcount = 0 
            return 701151
         
         ---Borrar el registro 
         delete ca_valor_acumulado_antant
         where va_operacion = @i_operacionca
         and   va_secuencial_ing = @i_secuencial_ing
         and   va_secuencia      = 1
      end
   end
   
   if  @i_di_estado = @w_est_vencido
   begin
      select @w_codvalor = co_codigo
      from   ca_concepto
      where  co_concepto = @w_parametro_int
      
      if @@rowcount = 0 
         return 701151
   end
end

if abs(@i_monto_pago - @i_monto_rubro) < @w_vlr_despreciable
   select @i_monto_pago = @i_monto_rubro


if @i_condonacion = 'N' 
begin
   -- MONTO DE PAGO POR PRIORIDAD
   select @w_pago = @i_monto_prioridad * (@i_inicial_rubro / @i_inicial_prioridad)
   
   if @w_pago > @i_monto_rubro 
      select @w_pago = @i_monto_rubro
end 
ELSE
begin
   select @w_pago = @i_monto_pago
   if @w_pago > @i_monto_rubro 
      select @w_pago = @i_monto_rubro
   
end
-- RETORNO DE VALORES
if @i_extraordinario = 1 
   select @w_monto_rubro = @w_pago

select @o_sobrante_pago = @i_monto_pago - @w_pago


-- COMPROBAR QUE EL SOBRANTE SEA MAYOR A CERO
if @o_sobrante_pago < 0
   select @o_sobrante_pago = 0

-- APLICACION DEL PAGO POR SECUENCIA DE RUBRO
if @i_extraordinario <> 1
   declare
      secuencia_rubro cursor
      for select am_cuota,      am_acumulado,  am_pagado,
                 am_periodo,    am_estado,
                 am_secuencia,  am_gracia,     am_dividendo
          from   ca_amortizacion
          where  am_operacion   =  @i_operacionca
          --and    am_dividendo  >=  @i_dividendo
          and    am_dividendo   =  @w_dividendo_aux
          and    am_concepto    =  @i_concepto
          and    am_estado     !=  @w_est_cancelado
          order  by am_dividendo, am_secuencia
          for read only
else
   declare
      secuencia_rubro cursor
      for select am_cuota,       am_acumulado, am_pagado,
                 am_periodo,     am_estado,
                 am_secuencia,   am_gracia,    am_dividendo
          from   ca_amortizacion
          where  am_operacion   =  @i_operacionca
          and    am_dividendo   =  @i_dividendo  - 1
          and    am_concepto    =  @i_concepto
          order  by am_dividendo, am_secuencia
          for read only 

open secuencia_rubro

fetch secuencia_rubro
into  @w_am_cuota,      @w_am_acumulado,  @w_am_pagado,
      @w_am_periodo,    @w_am_estado,
      @w_am_secuencia,  @w_am_gracia,     @w_dividendo

while   @@fetch_status = 0 -- CA_AMORTIZACION
begin
   if (@@fetch_status = -1)
   begin
      print 'abonoru.sp abonoru.sp  error en lectura del cursor secuencia_rubro'
      return 710004
   end
   
   if @w_pago <= 0
   begin
      break  
   end
   
   if @i_en_gracia_int = 'S'
      select @w_am_gracia = 0
   
   if @i_extraordinario <> 1
   begin
      if (@i_fpago = 'A') and (@w_am_estado = @w_est_novigente)
         select @w_monto_rubro = @w_am_cuota + @w_am_gracia - @w_am_pagado
      ELSE
      begin
         if @i_tipo_cobro = 'A'
            select @w_monto_rubro = @w_am_acumulado + @w_am_gracia - @w_am_pagado 
         else
            select @w_monto_rubro = @w_am_cuota + @w_am_gracia - @w_am_pagado 
      end
   end
   
   if @w_monto_rubro >= 0
   begin 
      if (@w_pago >= @w_monto_rubro)  and  @i_extraordinario <> 1
         select @w_pago_rubro = @w_monto_rubro
      else 
         select @w_pago_rubro = @w_pago 
      
      if @w_tipo_rubro not in ('C', 'I')
      begin
         select @w_di_fecha_ven = di_fecha_ven,
                @w_di_estado    = di_estado
         from   ca_dividendo, ca_amortizacion
         where  di_operacion = @i_operacionca
         and    di_dividendo = @i_dividendo
         and    am_operacion = @i_operacionca
         and    am_dividendo = di_dividendo 
         and    am_concepto  = @i_concepto
      end
   
      select @w_pago = @w_pago - @w_pago_rubro --REBAJO PAGO
      
      select @w_pago_rubro_mn =  round(@w_pago_rubro * @i_cotizacion, @w_num_dec)
      select @w_pago_rubro    =  round(@w_pago_rubro,@w_num_dec)
      select @w_pago_rubro_mn =  round(@w_pago_rubro_mn,@w_num_dec_n) 
      
      if @i_extraordinario =  1
         select @w_am_estado = 1
      
      -- GENERACION DE LOS CODIGOS VALOR
      select @w_codvalor1     = (@w_codvalor * 1000) + (@w_am_estado * 10) + @w_am_periodo,
             @w_codvalor_con1 = (@w_codvalor * 1000) + (@w_am_estado * 10) + @w_est_condonado
      
      if @w_pago_rubro > 0 
      begin
         select @w_am_estado_ar    = @w_am_estado,
                @w_concepto_ar     = @i_concepto,
                @w_afectacion_ar   = @w_afectacion
         
         if exists(select 1 from ca_det_trn
                   where dtr_operacion  = @i_operacionca
                   and   dtr_secuencial = @i_secuencial_pag
                   and   dtr_dividendo  = @w_dividendo 
                   and   dtr_concepto   = @i_concepto
                   and   dtr_codvalor   = @w_codvalor1)   
         begin
            update ca_det_trn
            set    dtr_monto            = dtr_monto    + @w_pago_rubro,
                   dtr_monto_mn         = dtr_monto_mn + @w_pago_rubro_mn
            where dtr_operacion  = @i_operacionca
            and   dtr_secuencial = @i_secuencial_pag
            and   dtr_dividendo  = @w_dividendo 
            and   dtr_concepto   = @i_concepto
            and   dtr_codvalor   = @w_codvalor1
            
            if @@error != 0 return 708166
         end
         ELSE
         begin
            if @i_cotizacion_dia_sus is null   -- NO TIENE VALORES EN SUSPENSO
            or @w_tipo_rubro not in ('I', 'M') -- ES DISTINTO DE INTERES O MORA
            or @w_am_estado not in (1, 2)
            begin
               insert into ca_det_trn
                     (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                      dtr_concepto,       dtr_estado,     dtr_periodo,
                      dtr_codvalor,       dtr_monto,      dtr_monto_mn,
                      dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                      dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                      dtr_monto_cont)
               values(@i_secuencial_pag,  @i_operacionca, @w_dividendo,
                      @i_concepto,        @w_am_estado,   @w_am_periodo,
                      @w_codvalor1,       @w_pago_rubro,  @w_pago_rubro_mn,
                      @w_op_moneda,       @i_cotizacion,  @i_tcotizacion,
                      @w_afectacion,      '00000',        'CARTERA',
                      0.00)
               
               if @@error != 0
                  return 708166
            end
            ELSE
            begin
               select @w_valor_vig_mn = round(@w_factor_vig * @w_pago_rubro_mn, @w_num_dec_n)
               select @w_pago_rubro_mn = @w_pago_rubro_mn - @w_valor_vig_mn
               
               -- INSERTAR LA PARTE VIGENTE
               insert into ca_det_trn
                     (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                      dtr_concepto,       dtr_estado,     dtr_periodo,
                      dtr_codvalor,
                      dtr_monto,
                      dtr_monto_mn,
                      dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                      dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                      dtr_monto_cont)
               values(@i_secuencial_pag,  @i_operacionca, @w_dividendo,
                      @i_concepto,        @w_am_estado,   @w_am_periodo,
                      @w_codvalor1,
                      round(@w_valor_vig_mn/@i_cotizacion, @w_num_dec),
                      @w_valor_vig_mn,
                      @w_op_moneda,       @i_cotizacion,  @i_tcotizacion,
                      @w_afectacion,      '00000',        'CARTERA',
                      0.00)
               
               if @@error != 0
                  return 708166
               
               select @w_codvalor1 = (@w_codvalor * 1000) + (@w_est_suspenso * 10) + @w_am_periodo
               
               insert into ca_det_trn
                     (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                      dtr_concepto,       dtr_estado,     dtr_periodo,
                      dtr_codvalor,
                      dtr_monto,
                      dtr_monto_mn,
                      dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                      dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                      dtr_monto_cont)
               values(@i_secuencial_pag,  @i_operacionca, @w_dividendo,
                      @i_concepto,        @w_am_estado,   @w_am_periodo,
                      @w_codvalor1,
                      round(@w_pago_rubro_mn/@i_cotizacion, @w_num_dec),
                      @w_pago_rubro_mn,
                      @w_op_moneda,       @i_cotizacion,  @i_tcotizacion,
                      @w_afectacion,      '00000',        'CARTERA',
                      0.00)
               
               if @@error != 0
                  return 708166
               
               select @w_codvalor1 = (@w_codvalor * 1000) + (@w_am_estado * 10) + @w_am_periodo
            end
         end 
         
         -- GENERACION DE LA AFECTACION CONTABLE CASO CONDONACION
         if @i_condonacion = 'S'  and @i_colchon = 'N' 
         begin
            select @w_am_estado_ar    = @w_est_condonado,
                   @w_concepto_ar     = @i_concepto,
                   @w_afectacion_ar   = @w_afectacion
            
            if exists (select 1 from ca_det_trn
                       where dtr_operacion  = @i_operacionca
                       and   dtr_secuencial = @i_secuencial_pag
                       and   dtr_dividendo  = @w_dividendo 
                       and   dtr_concepto   = @i_concepto
                       and   dtr_codvalor   = @w_codvalor_con1)   
            begin
               update ca_det_trn
               set    dtr_monto    = dtr_monto    + @w_pago_rubro,
                      dtr_monto_mn = dtr_monto_mn + @w_pago_rubro_mn
               where dtr_operacion  = @i_operacionca
               and   dtr_secuencial = @i_secuencial_pag
               and   dtr_dividendo  = @w_dividendo 
               and   dtr_concepto   = @i_concepto
               and   dtr_codvalor   = @w_codvalor_con1
               
               if @@error != 0 return 708166
            end 
            ELSE 
            begin
               insert into ca_det_trn
                     (dtr_secuencial,   dtr_operacion, dtr_dividendo,
                      dtr_concepto,       dtr_estado,    dtr_periodo,
                      dtr_codvalor,       dtr_monto,     dtr_monto_mn,
                      dtr_moneda,         dtr_cotizacion,dtr_tcotizacion,
                      dtr_afectacion,     dtr_cuenta,    dtr_beneficiario,
                      dtr_monto_cont)
               values(@i_secuencial_pag, @i_operacionca,  @w_dividendo,
                      @i_concepto,       @w_est_condonado,@w_am_periodo,
                      @w_codvalor_con1,  @w_pago_rubro,   @w_pago_rubro_mn,
                      @w_op_moneda,      @i_cotizacion,   @i_tcotizacion,   
                      'D',              '00000',      'CARTERA',
                      0.00)
               
               if @@error != 0 return 708166
            end 
         end -- Condonacion
         
         -- Colchon
         if @i_colchon = 'S'  
         begin
            select @w_am_estado_ar    = @w_am_estado,
                   @w_concepto_ar     = 'COL',
                   @w_afectacion_ar   = 'D'
            
            select @w_codvalor4 = co_codigo * 1000  
            from  ca_concepto
            where co_concepto  = 'COL'
            
            insert into ca_det_trn
                  (dtr_secuencial,   dtr_operacion, dtr_dividendo,
                   dtr_concepto,       dtr_estado,    dtr_periodo,
                   dtr_codvalor,       dtr_monto,     dtr_monto_mn,
                   dtr_moneda,         dtr_cotizacion,dtr_tcotizacion,
                   dtr_afectacion,     dtr_cuenta,    dtr_beneficiario,
                   dtr_monto_cont)
            values(@i_secuencial_pag, @i_operacionca,  @w_dividendo,
                   'COL',              @w_am_estado,    @w_am_periodo,
                   @w_codvalor4,       @w_pago_rubro,   @w_pago_rubro_mn,
                   @w_op_moneda,       @i_cotizacion,   @i_tcotizacion,   
                   'D',              '00000',      'CARTERA',
                   0.00)
         end 
         -- Fin Colchon
         
         -- Alimentar tabla ca_abono_rubro
         insert into ca_abono_rubro
               (ar_fecha_pag,         ar_secuencial,              ar_operacion,                ar_dividendo,
                ar_concepto,          ar_estado,                  ar_monto,
                ar_monto_mn,          ar_moneda,                  ar_cotizacion,               ar_afectacion,
                ar_tasa_pago,         ar_dias_pagados)
         values(@s_date,             @i_secuencial_pag,      @i_operacionca,       @w_dividendo,
                @w_concepto_ar,      @w_am_estado_ar,        @w_pago_rubro,
                @w_pago_rubro_mn,    @w_op_moneda,           @i_cotizacion,         @w_afectacion_ar,
                @i_tasa_pago,        @i_dias_pagados)
      end  -- Fin de @w_pago_rubro > 0
      
      -- ACTUALIZAR LA AMORTIZACION DEL RUBRO
      
      if @i_extraordinario <> 1 
      begin  
         update ca_amortizacion
         set    am_pagado          = am_pagado + @w_pago_rubro
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_dividendo
         and    am_concepto  = @i_concepto
         and    am_secuencia = @w_am_secuencia
         
         if @@error ! = 0
         begin
            return 705050  
         end
      end
      ELSE
      begin
         if @i_extraordinario = 1 
         begin
            update ca_amortizacion ---Este update se hace solo para el valor del concepto CAP en la cuota Extra
            set    am_pagado          = am_pagado + @w_pago_rubro,
                   am_cuota           = am_cuota  + @w_pago_rubro,
                   am_acumulado       = am_acumulado + @w_pago_rubro
            where am_operacion = @i_operacionca
            and   am_dividendo = @w_dividendo 
            and   am_concepto  = @i_concepto
            and   am_secuencia = @w_am_secuencia
            
            if @@error ! = 0
            begin
               return 705050  
            end
         end 
      end
      
      if @i_tipo_cobro = 'P' and @i_tipo_rubro = 'I' and  @i_fpago != 'A'
      begin
         select  @w_prepago_int = isnull(sum(am_pagado - am_acumulado),0 )
         from ca_amortizacion 
         where am_operacion = @i_operacionca
         and   am_dividendo = @w_dividendo
         and   am_concepto  = @i_concepto
         and   am_secuencia = @w_am_secuencia
         and   am_estado    <> @w_est_cancelado
         
         if @w_prepago_int > 0
         begin
            exec @w_secuencial_prepago = sp_gen_sec
                 @i_operacion = @i_operacionca
            
            -- INSERCION DE CABECERA CONTABLE DE CARTERA
            insert into ca_transaccion
                  (tr_fecha_mov,  tr_toperacion,     tr_moneda,      
                   tr_operacion,  tr_tran,           tr_secuencial,
                   tr_en_linea,   tr_banco,          tr_dias_calc,
                   tr_ofi_oper,   tr_ofi_usu,        tr_usuario,
                   tr_terminal,   tr_fecha_ref,      tr_secuencial_ref, 
                   tr_estado,     tr_gerente,        tr_gar_admisible,   
                   tr_reestructuracion ,             tr_calificacion,
                   tr_observacion,   tr_fecha_cont,     tr_comprobante)
            values(@s_date,          @w_toperacion,      @w_op_moneda,
                   @i_operacionca,   'PRV',              @w_secuencial_prepago, 
                   @i_en_linea,      @w_banco,           0,
                   @w_oficina_op,    @s_ofi,             @s_user,
                   @s_term,          @w_fecha_ult_proceso,            -999,  
                   'ING',            @w_gerente,         isnull(@w_gar_admisible,''),   
                   isnull(@w_reestructuracion,''),       isnull(@w_calificacion,''),
                   'CAUSACION POR PAGO PROYECTADO',      @s_date,          0)   
            
            if @@error != 0
               return 708165 
            
            select @w_prepago_int_mn = round(@w_prepago_int * @i_cotizacion, @w_num_dec)
            select @w_prepago_int    =  round(@w_prepago_int,@w_num_dec)
            select @w_prepago_int_mn =  round(@w_prepago_int_mn,@w_num_dec_n)
            
            insert into ca_det_trn
                  (dtr_secuencial,        dtr_operacion,      dtr_dividendo,
                   dtr_concepto,          dtr_estado,         dtr_periodo,
                   dtr_codvalor,          dtr_monto,          dtr_monto_mn,
                   dtr_moneda,            dtr_cotizacion,     dtr_tcotizacion,
                   dtr_afectacion,        dtr_cuenta,         dtr_beneficiario,
                   dtr_monto_cont)
            values(@w_secuencial_prepago, @i_operacionca,     @w_dividendo,
                   @i_concepto,           @w_am_estado,       @w_am_periodo,
                   @w_codvalor1,          @w_prepago_int,     @w_prepago_int_mn,
                   @w_op_moneda,             @i_cotizacion,      @i_tcotizacion,
                   @w_afectacion,         '00000',            'CARTERA',
                   0.00)
            
            if @@error != 0
               return 708166

            --SOLO SE ACUMULA LO QUE SE PAGO PROYECTADAMENTE NO TODA LA CUOTA
            update ca_amortizacion 
            set am_acumulado =  am_acumulado + @w_prepago_int
            where am_operacion = @i_operacionca
            and   am_dividendo = @w_dividendo
            and   am_concepto  = @i_concepto
            and   am_secuencia = @w_am_secuencia
        
            select @w_pago_todo = 'N'
            select @w_sum = isnull(sum(am_cuota - am_pagado),0)
            from ca_amortizacion
            where am_operacion = @i_operacionca
            and   am_dividendo = @w_dividendo
            and   am_concepto  = @i_concepto
            and   am_secuencia = @w_am_secuencia
            if @w_sum = 0
               select @w_pago_todo = 'S'
            
           
         end
      end
      


      --XMA INI
      -- SI LA OPERACION ES EN UVR's AFECTAR EL VALOR DE CORRECCION EN SUSPENSO
      if @w_op_moneda = @w_moneda_uvr
      begin

         select @w_am_correccion_sus_mn = co_correccion_sus_mn,
                @w_am_correc_pag_sus_mn = co_correc_pag_sus_mn 
         from ca_correccion
         where co_operacion  = @i_operacionca
         and   co_dividendo  = @w_dividendo
         and   co_concepto   = @i_concepto


         select @w_correc_pag_sus = isnull(@w_am_correccion_sus_mn, 0) - isnull(@w_am_correc_pag_sus_mn,0)
         
         -- SI EXISTE VALOR EN SUSPENSO QUE SE PAGUE CONTABILIZARLO
         if (@w_correc_pag_sus > 0   and ((@w_am_estado = @w_est_suspenso and @i_concepto in (@w_parametro_int, @w_parametro_mora)) or (@i_concepto = @w_parametro_cap and @w_am_estado <> @w_est_suspenso)))
         and @w_codvalor = 10
         begin
            -- SI EL VALOR POR CONTABILIZAR ES MAYOR AL PAGADO CONTABILIZAR SOLO LO PAGADO
            if isnull(@w_pago_rubro_mn,0) < isnull(@w_correc_pag_sus,0)
               select @w_correc_pag_sus = @w_pago_rubro_mn
            
            select @w_codvalor_sus1 = (@w_codvalor * 1000) + (@w_estado_op * 10) + 9
            
            insert into ca_det_trn
                  (dtr_secuencial,        dtr_operacion,     dtr_dividendo,
                   dtr_concepto,          dtr_estado,        dtr_periodo,   
                   dtr_codvalor,          dtr_monto,         dtr_monto_mn,
                   dtr_moneda,            dtr_cotizacion,    dtr_tcotizacion,   
                   dtr_afectacion,        dtr_cuenta,        dtr_beneficiario,   
                   dtr_monto_cont)
            values(@i_secuencial_pag,     @i_operacionca,    @w_dividendo,
                   @i_concepto,           @w_am_estado,      @w_am_periodo,
                   @w_codvalor_sus1,      @w_correc_pag_sus, @w_correc_pag_sus,
                   @w_moneda_n,           1.0,               'N',     
                   @w_afectacion,         '00000',           'PAGO SUSP.CMO-CARTERA',
                   0.00)
            
            if @@error != 0
            begin
               print 'error...abonoru.sp'
               return 708166
            end
            
            -- cambio de los campos am_correccion_xxx a la nueva tabla ca_correccion
            if exists (select * from ca_amortizacion
                       where am_operacion = @i_operacionca
                       and   am_dividendo = @w_dividendo
                       and   am_concepto  = @i_concepto
                       and   am_secuencia = @w_am_secuencia)
            begin
               update ca_correccion
               set    co_correc_pag_sus_mn = isnull(co_correc_pag_sus_mn, 0) + @w_correc_pag_sus
               where  co_operacion = @i_operacionca
               and    co_dividendo = @w_dividendo
               and    co_concepto  = @i_concepto
               
               if @@error ! = 0
                  return 705050
            end--- if exists (select...
            -- fin cambio
         end 
      end  --XMA FIN SUSPENCION DE CAUSACION

      -- Cancelacion del rubro
      
      
      if @i_tipo_rubro <> 'M'
      begin
         
         ---PRINT 'abonoru.sp va a cancelar el rubro @w_dividendo %1! @i_concepto %2! @w_am_secuencia %3!',@w_dividendo,@i_concepto,@w_am_secuencia
         
         update ca_amortizacion
         set    am_estado = @w_est_cancelado
         where  am_cuota     = am_pagado
         and    am_operacion = @i_operacionca
         and    am_dividendo = @w_dividendo
         and    am_concepto  = @i_concepto
         and    am_secuencia = @w_am_secuencia
         
         if @@error ! = 0
            return 705050       ---2
      end


      
 
     if @i_tipo_rubro = 'I' and @w_estado_op <> @w_est_suspenso
      begin
         --SI ES VALOR PRESENTE,
         select @w_tipo_cobro_org = ab_tipo_cobro
         from ca_abono
         where ab_operacion = @i_operacionca
         and   ab_secuencial_ing = @i_secuencial_ing

         --SI EL MAXIMO DIVIDENDO ES 1 Y EL PAGO ES INT SE DEBE CANCELAR EL RUBRO CON EL PAGO EL VP
         --SOLO SI EL AUMULADO  ES IGUAL AL PAGADO
         
         if @w_tipo_cobro_org = 'E' and (@i_tipo_cobro = 'P' and  @w_pago_todo = 'S') or (@w_dividendo_max = 1)
         begin
            
            
            ---PRINT 'abonoru.sp va a cancelar el rubro %1! @w_tipo_cobro_org %2! @i_tipo_cobro %3!',@w_estado_op,@w_tipo_cobro_org,@i_tipo_cobro
            
            --EN VALOR PRESENTE AL PAGAR EL RUBRO DEBE QUEDAR CANCELADO
            update ca_amortizacion
            set    am_estado = @w_est_cancelado
            where  am_acumulado  = am_pagado
            and    am_operacion = @i_operacionca
            and    am_dividendo = @w_dividendo
            and    am_concepto  = @i_concepto
            and    am_secuencia = @w_am_secuencia
            and    am_estado    <> @w_est_cancelado
            

         end         
         if @@error ! = 0
            return 705050       ---2
      end
      

      update ca_amortizacion
      set    am_acumulado = am_cuota
      where  am_cuota     = am_pagado
      and    am_operacion = @i_operacionca
      and    am_dividendo = @w_dividendo
      and    am_concepto  = @i_concepto
      and    am_secuencia = @w_am_secuencia
      and    @i_tipo_rubro != 'I'
      
      if @@error ! = 0
         return 705050       ---3
      
      -- INTANT
      
      if @i_concepto = @w_int_ant
      begin
         select @w_di_fecha_ini  = di_fecha_ini,
                @w_di_fecha_ven  = di_fecha_ven,
                @w_di_dias_cuota = di_dias_cuota,
                @w_di_estado     = di_estado
         from   ca_dividendo
         where  di_operacion = @i_operacionca
         and    di_dividendo = @w_dividendo
         
         select @w_am_acumulado1 = am_acumulado,
                @w_am_pagado1    = am_pagado
         from   ca_amortizacion
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_dividendo
         and    am_concepto  = @i_concepto
         and    am_secuencia = @w_am_secuencia
         
         select @w_pago_control = 0
         
         if @w_am_pagado1  > @w_am_acumulado1  
            select @w_pago_control =  isnull(sum(@w_am_pagado1 - @w_am_acumulado1),0)
         
         if @w_di_estado in (@w_est_vigente,@w_est_novigente)  and @w_pago_rubro > 0
         begin
            if @w_pago_control > 0
            begin
               insert into ca_control_intant
                     (con_secuencia_pag, con_operacion,    con_dividendo,    con_fecha_ini,
                      con_fecha_ven,     con_valor_pagado, con_dias_cuota,   con_am_sec)
               values(@i_secuencial_pag, @i_operacionca,   @w_dividendo,     @w_di_fecha_ini,
                      @w_di_fecha_ven,   @w_pago_control,  @w_di_dias_cuota, @w_am_secuencia)
               
               if @@error ! = 0
                  return 710258
            end
         end -- ESTADO VALIDO
      end  -- FIN INTANT
   end --  Monto_Rubro
   
   fetch secuencia_rubro
   into  @w_am_cuota,      @w_am_acumulado,  @w_am_pagado,
         @w_am_periodo,    @w_am_estado,
         @w_am_secuencia,  @w_am_gracia,     @w_dividendo
end -- CA_AMORTIZACION

close secuencia_rubro
deallocate secuencia_rubro

return 0
                                                                                                                                                                       
go
