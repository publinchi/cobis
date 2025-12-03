/************************************************************************/
/*   Archivo:              traslado.sp                                  */
/*   Stored procedure:     sp_trasladador                               */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez Burbano                        */
/*   Fecha de escritura:   28/08/2003                                   */
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
/*                                PROPOSITO                             */
/*   Traslada saldos por operacion y transaccion recibidos como         */
/*      parametros  de entrada                                          */
/************************************************************************/
/*                               CAMBIOS                                */  
/*   FEB-17-2006      EPB        TRASLADO DE INT REQ 379                */
/*   JUN 2006         FQ         Defecto 6531                           */
/*   MAY 2007         EPB        Defecto 8211 diferidos solo en SUA     */
/*   NOV 2010         EPB        NR-059 Diferidos                       */
/*   FEB-2021         KDR        Se comenta uso de concepto CXCINTES    */
/*   06/06/2023	 	M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/
/*   07/11/2023     K. Rodriguez     Actualiza valor despreciab         */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_trasladador')
   drop proc sp_trasladador
go

create proc sp_trasladador
   @s_user              login,
   @s_term              varchar(30),
   @s_date              datetime,
   @s_ofi               smallint,
   @i_trn               catalogo,
   @i_toperacion        catalogo,
   @i_oficina           smallint,
   @i_banco             cuenta,
   @i_operacionca       int,
   @i_moneda            tinyint,
   @i_fecha_proceso     datetime,
   @i_gerente           smallint,
   @i_moneda_nac        smallint,
   @i_garantia          char(1) = '',
   @i_reestructuracion  char(1) = '',
   @i_cuenta_final      char(20) = '',
   @i_cuenta_antes      char(20) = '',
   @i_estado_final      int  = null,
   @i_calificacion      catalogo = '',
   @i_estado_actual     int,
   @i_secuencial        int

as 
declare
   @w_am_concepto          catalogo,
   @w_monto                money,
   @w_monto_mn             money,
   @w_cot_mn               money,
   @w_am_acumulado         money,
   @w_observacion          varchar(255),
   @w_am_estado            tinyint,
   @w_categoria            catalogo,
   @w_codvalor_final       int,
   @w_codvalor_antes       int,
   @w_codvalor_trc         int,
   @w_codvalor             int,
   @w_co_codigo            int,
   @w_ro_fpago             char(1),
   @w_moneda_uvr           tinyint,
   @w_est_suspenso         int,
   @w_est_novigente        int,
   @w_co_monto             money,
   @w_co_concepto          catalogo,
   @w_estado               int,
   @w_moneda               int,
   @w_capitalizado_sus     money,
   @w_signo_extrae         int,
   @w_vlr_despreciable     float,
   @w_num_dec              int,
   @w_moneda_n             int,
   @w_num_dec_n            int,
   @w_error                int,
   @w_fecha_ult_proceso    datetime,
   @w_dividendo            int,
   @w_parametro_cxcintes   catalogo,   ---NR 379
   @w_concepto_traslado    catalogo,   ---NR 379
   @w_dif_concepto         catalogo,
   @w_dif_dividendo        int,
   @w_dif_valor_concepto   money,
   @w_dif_valor_pagado     money,
   @w_valor_pagar_dif      money,
   @w_cod_valor_dif        int,
   @w_rowcount             int,
   @w_estado_op            int

-- LECTURA DE DECIMALES
exec @w_error = sp_decimales
     @i_moneda       = @i_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_n out

if @w_error != 0 
   return @w_error


select @w_num_dec  = isnull(@w_num_dec,0)

select @w_vlr_despreciable = 1.0 / power(10, (@w_num_dec + 2))
   
-- CARGAR VARIABLES DE TRABAJO
select @w_monto         = 0, 
       @w_co_monto      = 0,
       @w_observacion   = 'TRASLADO DE SALDOS POR ' + cast(@i_trn as varchar)

-- CODIGO DE MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
   return 710076

select @w_parametro_cxcintes = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CXCINT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

/*  -- KDR Sección no aplica para la versión de Finca
if @w_rowcount = 0 
   return 711016

select @w_concepto_traslado  = co_concepto
from ca_concepto
where co_concepto = @w_parametro_cxcintes

if @@rowcount = 0 
   return 711017
*/ -- FIN KDR

select @w_moneda = @i_moneda

select @w_fecha_ult_proceso = op_fecha_ult_proceso,
       @w_estado_op         = op_estado
from   ca_operacion
where  op_operacion = @i_operacionca

exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_suspenso   = @w_est_suspenso  out

-- GENERAR DETALLE CON TODOS LOS CONCEPTOS
if @i_trn = 'SUA'
declare
   cursor_rubros_general cursor
   for select am_concepto, am_estado, co_categoria, co_codigo, ro_fpago,
              sum(am_acumulado - am_pagado), am_dividendo
       from   ca_amortizacion, ca_concepto, ca_rubro_op
       where  am_operacion = @i_operacionca
       and    co_concepto = am_concepto
       and    co_categoria in ('M', 'I')
       and    am_estado = @w_est_suspenso
       and    ro_operacion = am_operacion
       and    ro_concepto  = am_concepto
       group  by am_concepto, am_estado, co_categoria, co_codigo, ro_fpago, am_dividendo
       having sum(am_acumulado - am_pagado) > @w_vlr_despreciable
       UNION
       select am_concepto, am_estado, co_categoria, co_codigo, ro_fpago,
              sum(am_acumulado - am_pagado), am_dividendo
       from   ca_amortizacion, ca_concepto, ca_rubro_op
       where  am_operacion = @i_operacionca
       and    co_concepto = am_concepto
       and    am_estado    = @w_est_suspenso
       and    am_concepto  =  @w_concepto_traslado
       and    ro_operacion = am_operacion
       and    ro_concepto  = am_concepto
       group  by am_concepto, am_estado, co_categoria, co_codigo, ro_fpago, am_dividendo
       having sum(am_acumulado - am_pagado) > @w_vlr_despreciable       
   for read only
ELSE
declare
   cursor_rubros_general cursor
   for select am_concepto, am_estado, co_categoria, co_codigo, ro_fpago,
              sum(am_acumulado - am_pagado), am_dividendo
       from   ca_amortizacion, ca_concepto, ca_rubro_op
       where  am_operacion = @i_operacionca
       and    am_estado    != 3
       and    co_concepto = am_concepto
       and    co_categoria in ('C', 'M', 'I')
       and    ro_operacion = am_operacion
       and    ro_concepto  = am_concepto
       group  by am_concepto, am_estado, co_categoria, co_codigo, ro_fpago, am_dividendo
       having sum(am_acumulado - am_pagado) > @w_vlr_despreciable
       UNION
       select am_concepto, am_estado, co_categoria, co_codigo, ro_fpago,
                  sum(am_acumulado - am_pagado), am_dividendo
       from   ca_amortizacion, ca_concepto, ca_rubro_op
       where  am_operacion = @i_operacionca
       and    am_estado    != 3
       and    co_concepto = am_concepto
       and    co_categoria not in ('C', 'M', 'I')
       and    (am_estado in (1, 2) and ro_fpago != 'M' or am_estado in (0, 1, 2) and ro_fpago = 'M')
       and    ro_operacion = am_operacion
       and    ro_concepto  = am_concepto
       group  by am_concepto, am_estado, co_categoria, co_codigo, ro_fpago, am_dividendo
       having sum(am_acumulado - am_pagado) > @w_vlr_despreciable
   for read only

open cursor_rubros_general

fetch cursor_rubros_general
into  @w_am_concepto, @w_am_estado, @w_categoria, @w_codvalor, @w_ro_fpago, @w_monto, @w_dividendo

while   @@fetch_status = 0
begin
   if (@@fetch_status = -1)
   begin
      PRINT 'traslado.sp  no hay datos en el cursor @i_operacionca ' + cast(@i_operacionca as varchar)
      return 710004
   end
   
   if @w_am_estado = @w_est_novigente
      select @w_am_estado = @w_estado_op
      
   select @w_estado = @w_am_estado
   
   select @w_codvalor_antes = @w_codvalor * 1000 + @w_am_estado * 10
   
   if @i_trn in ('SUA')
   begin
      select @w_codvalor_final = @w_codvalor * 1000 +  10,
             @w_estado  = 1
      
      if @w_categoria = 'M'
         select @w_estado  = 2,
                @w_codvalor_final = @w_codvalor * 1000 +  20
   end
   else
      select @w_codvalor_final = @w_codvalor * 1000 + @w_am_estado * 10
  
      
      -- COTIZACION MONEDA
      exec @w_error = sp_conversion_moneda
           @s_date               = @i_fecha_proceso,
           @i_opcion             = 'L',
           @i_moneda_monto       = @i_moneda,
           @i_moneda_resultado   = @i_moneda_nac,
           @i_monto              = @w_monto,
           @i_fecha              = @i_fecha_proceso,
           @o_monto_resultado    = @w_monto_mn out,
           @o_tipo_cambio        = @w_cot_mn out
      
      if @w_error != 0
      begin
         PRINT 'traslado.sp  error de sp_conversion_moneda ' + cast(@w_error as varchar) + ' monto ' + cast(@w_monto as varchar) + ' monto_mn ' + cast(@w_monto_mn as varchar) + ' concepto ' +  cast(@w_am_concepto as varchar)
         return @w_error
      end
      
      ----SACANDO DE
      if @i_trn != 'CAS'
      begin
         if @i_trn = 'SUA'
            select @w_signo_extrae = 1 -- LA TRANSACCION SUA NO GRABA NEGATIVO EL VALOR QUE SACA (POR EL PERFIL)
         ELSE
            select @w_signo_extrae = -1
         
         insert into ca_det_trn
              (dtr_secuencial, dtr_operacion,    dtr_dividendo,
               dtr_concepto,
               dtr_estado,     dtr_periodo,      dtr_codvalor,
               dtr_monto,      dtr_monto_mn,     dtr_moneda,
               dtr_cotizacion, dtr_tcotizacion,  dtr_afectacion,
               dtr_cuenta,     dtr_beneficiario, dtr_monto_cont)
         values(@i_secuencial,  @i_operacionca,   @w_dividendo,
                @w_am_concepto,
                @w_am_estado,  0,                 @w_codvalor_antes,
                @w_signo_extrae * @w_monto,
                @w_signo_extrae * @w_monto_mn,
                @i_moneda,
                @w_cot_mn,     'N',              'D',
                isnull(@i_cuenta_antes,''),   '', 0)
         
         if @@error <> 0
         begin
            PRINT 'traslado.sp  error insertando en ca_det_trn 1 '
            return 710001
         end
      end
      
      ----CONTABILIZANDO EN
      insert into ca_det_trn
            (dtr_secuencial, dtr_operacion,    dtr_dividendo,
             dtr_concepto,
             dtr_estado,     dtr_periodo,      dtr_codvalor,
             dtr_monto,      dtr_monto_mn,     dtr_moneda,
             dtr_cotizacion, dtr_tcotizacion,  dtr_afectacion,
             dtr_cuenta,     dtr_beneficiario, dtr_monto_cont)
      values(@i_secuencial,  @i_operacionca,   @w_dividendo,
             @w_am_concepto,
             @w_estado,      0,                @w_codvalor_final,
             @w_monto,       @w_monto_mn,      @i_moneda,
             @w_cot_mn,     'N',               'D',
             isnull(@i_cuenta_final,''),       '',               0)
      
      if @@error <> 0
      begin
         PRINT 'traslado.sp  error insertando en ca_det_trn 2 '
         return 710001
      end
  
   fetch cursor_rubros_general
   into  @w_am_concepto, @w_am_estado, @w_categoria, @w_codvalor, @w_ro_fpago, @w_monto, @w_dividendo
end -- WHILE CURSOR

close cursor_rubros_general
deallocate cursor_rubros_general

-- REGISTRO DE VALORES EN SUSPENSO POR CORRECCION MONETARIA
if @w_moneda_uvr = @i_moneda and @i_estado_actual = @w_est_suspenso
begin
   declare
      cursor_suspenso cursor
      for select a.co_concepto,  b.co_codigo,  sum(co_correccion_sus_mn-co_correc_pag_sus_mn)
          from   ca_correccion a, ca_concepto b
          where  a.co_operacion = @i_operacionca
          and    a.co_concepto = b.co_concepto
          --and    b.co_categoria in ('C')
          group  by a.co_concepto,b.co_codigo
          having sum(co_correccion_sus_mn) != 0
          for read only

   open cursor_suspenso
   fetch cursor_suspenso
   into  @w_co_concepto, @w_co_codigo, @w_co_monto
   
   while   @@fetch_status = 0
   begin
      if (@@fetch_status = -1)
      begin
         PRINT 'traslado.sp  no hay datos en el cursor cursor_suspenso'
         return 710004
      end
      
      select @w_monto_mn = @w_co_monto

      select @w_estado = @w_est_suspenso
      select @w_codvalor_antes = @w_co_codigo * 1000 + @w_est_suspenso * 10 + 9
      
      if @i_trn = 'CAS'
         select @w_codvalor_final = @w_co_codigo * 1000 + @i_estado_final * 10 + 9, 
                @w_estado = @i_estado_final
      else
         select @w_codvalor_final = @w_co_codigo * 1000 + @w_est_suspenso * 10 + 9
      
      if @i_trn = 'SUA'
         select @w_signo_extrae = 1 -- LA TRANSACCION SUA NO GRABA NEGATIVO EL VALOR QUE SACA (POR EL PERFIL)
      ELSE
         select @w_signo_extrae = -1
      
      insert into ca_det_trn
            (dtr_secuencial,              dtr_operacion,    dtr_dividendo,
             dtr_concepto,
             dtr_estado,                  dtr_periodo,      dtr_codvalor,
             dtr_monto,                   dtr_monto_mn,     dtr_moneda,
             dtr_cotizacion,              dtr_tcotizacion,  dtr_afectacion,
             dtr_cuenta,                  dtr_beneficiario, dtr_monto_cont)
      values(@i_secuencial,               @i_operacionca,   0,
             @w_co_concepto,
             @w_est_suspenso,             0,                @w_codvalor_antes,
             @w_signo_extrae * @w_co_monto,  @w_signo_extrae * @w_monto_mn,     @i_moneda,
             1,                           'N',              'D',
             isnull(@i_cuenta_antes,''),   '', 0)
      
      if @@error <> 0
      begin
         PRINT 'traslado.sp  error insertando en ca_det_trn 3'
         return 710001
      end
      
      if @i_trn = 'TRC' and @w_co_concepto = 'CAP' -- PARA CAMBIO DE CALIFICACION DE OBLIGACIONES SUSPENDIDAS EN UVR
      begin
         select @w_codvalor_trc = @w_co_codigo * 1000 + 10
         insert into ca_det_trn
               (dtr_secuencial,              dtr_operacion,    dtr_dividendo,
                dtr_concepto,
                dtr_estado,                  dtr_periodo,      dtr_codvalor,
                dtr_monto,                   dtr_monto_mn,     dtr_moneda,
                dtr_cotizacion,              dtr_tcotizacion,  dtr_afectacion,
                dtr_cuenta,                  dtr_beneficiario, dtr_monto_cont)
         values(@i_secuencial,               @i_operacionca,   0,
                @w_co_concepto,
                @w_est_suspenso,             0,                @w_codvalor_trc,
                -@w_signo_extrae * @w_co_monto,  -@w_signo_extrae * @w_monto_mn,     @i_moneda,
                1,                           'N',              'D',
                isnull(@i_cuenta_antes,''),   '', 0)
         
         if @@error <> 0
         begin
            PRINT 'traslado.sp  error insertando en ca_det_trn 3.1 '
            return 710001
         end
      end
      
      select @w_signo_extrae = -@w_signo_extrae
      
      -- EL PERFIL SUA_OA SOLO UTILIZA UN CODIGO VALOR
      if @i_trn != 'SUA'
      begin
         insert into ca_det_trn
               (dtr_secuencial,              dtr_operacion,    dtr_dividendo,
                dtr_concepto,
                dtr_estado,                  dtr_periodo,      dtr_codvalor,
                dtr_monto,                   dtr_monto_mn,     dtr_moneda,
                dtr_cotizacion,              dtr_tcotizacion,  dtr_afectacion,
                dtr_cuenta,                  dtr_beneficiario, dtr_monto_cont)
         values(@i_secuencial,               @i_operacionca,   0,
                @w_co_concepto,
                @w_estado,                   0,                @w_codvalor_final,
                @w_co_monto,                 @w_monto_mn,      @i_moneda_nac,
                1,                           'N',              'D',
                isnull(@i_cuenta_final,''),  '',               0)
         
         if @@error <> 0
         begin
            PRINT 'traslado.sp  error insertando en ca_det_trn 4 '
            return 710001
         end
         
         if @i_trn = 'TRC' and @w_co_concepto = 'CAP' -- PARA CAMBIO DE CALIFICACION DE OBLIGACIONES SUSPENDIDAS EN UVR
         begin
            select @w_codvalor_trc = @w_co_codigo * 1000 + 10
            
            insert into ca_det_trn
                  (dtr_secuencial,              dtr_operacion,    dtr_dividendo,
                   dtr_concepto,
                   dtr_estado,                  dtr_periodo,      dtr_codvalor,
                   dtr_monto,                   dtr_monto_mn,     dtr_moneda,
                   dtr_cotizacion,              dtr_tcotizacion,  dtr_afectacion,
                   dtr_cuenta,                  dtr_beneficiario, dtr_monto_cont)
            values(@i_secuencial,               @i_operacionca,   0,
                   @w_co_concepto,
                   @w_estado,                   0,                @w_codvalor_trc,
                   -@w_co_monto,                -@w_monto_mn,     @i_moneda_nac,
                   1,                           'N',              'D',
                   isnull(@i_cuenta_final,''),  '',               0)
            
            if @@error <> 0
            begin
               PRINT 'traslado.sp  error insertando en ca_det_trn 4.1 '
               return 710001
            end
         end
      end
      
      fetch cursor_suspenso
      into  @w_co_concepto, @w_co_codigo, @w_co_monto
   end -- WHILE CURSOR
   close cursor_suspenso
   deallocate cursor_suspenso
   
   -- EXTRACCION DE LA CAPITALIZACION SUSPENDIDA
   select @w_capitalizado_sus = isnull(op_cap_susxcor, 0),
          @w_co_codigo        = co_codigo,
          @w_co_concepto      = co_concepto
   from   ca_operacion, ca_concepto
   where  op_operacion   = @i_operacionca
   and    co_categoria = 'C'
   
   if @w_capitalizado_sus != 0
   begin
      if @w_moneda = 0 or @i_moneda = @w_moneda_uvr
      begin
         select @w_co_monto = @w_capitalizado_sus,
                @w_monto_mn = @w_capitalizado_sus,
                @w_cot_mn   = 1,
                @w_moneda   = 0
      end
      ELSE
      begin
         select @w_moneda = @i_moneda
         select @w_co_monto = @w_capitalizado_sus
         -- COTIZACION MONEDA
         exec @w_error = sp_conversion_moneda
              @s_date               = @i_fecha_proceso,
              @i_opcion             = 'L',
              @i_moneda_monto       = @i_moneda,
              @i_moneda_resultado   = @i_moneda_nac,
              @i_monto              = @w_co_monto,
              @i_fecha              = @i_fecha_proceso,
              @o_monto_resultado    = @w_monto_mn out,
              @o_tipo_cambio        = @w_cot_mn out
         
         if @w_error != 0
         begin
            PRINT 'traslado.sp  error de sp_conversion_moneda ' + cast(@w_error as varchar) + ' monto ' + cast(@w_monto as varchar) + ' monto_mn ' + cast(@w_monto_mn as varchar) + ' concepto ' + cast(@w_am_concepto as varchar)
            return @w_error
         end
      end
      
      select @w_estado = @w_est_suspenso
      -- TERMINACION EN 5 DEL CODIGO VALOR ES LA CAPITALIZACION DE INTERESES SUSPENDIDA
      select @w_codvalor_antes = @w_co_codigo * 1000 + @w_est_suspenso * 10 + 5
      
      select @w_codvalor_final = @w_co_codigo * 1000 + @w_est_suspenso * 10 + 5
      
      -- SACAR DE LA CUENTA DE CAPITALIZACION SUSPENDIDA
      insert into ca_det_trn
            (dtr_secuencial,              dtr_operacion,    dtr_dividendo,
             dtr_concepto,
             dtr_estado,                  dtr_periodo,      dtr_codvalor,
             dtr_monto,                   dtr_monto_mn,     dtr_moneda,
             dtr_cotizacion,              dtr_tcotizacion,  dtr_afectacion,
             dtr_cuenta,                  dtr_beneficiario, dtr_monto_cont)
      values(@i_secuencial,               @i_operacionca,   0,
             @w_co_concepto,
             @w_est_suspenso,             0,                @w_codvalor_antes,
             -@w_co_monto,                -@w_monto_mn,     @w_moneda,
             @w_cot_mn,                   'N',              'D',
             isnull(@i_cuenta_antes,''),  '',               0)
      
      if @@error <> 0
      begin
         PRINT 'traslado.sp  error insertando en ca_det_trn 3 '
         return 710001
      end
      
      -- INGRESAR A LA CUENTA DE CAPITAL
      insert into ca_det_trn
            (dtr_secuencial,              dtr_operacion,    dtr_dividendo,
             dtr_concepto,
             dtr_estado,                  dtr_periodo,      dtr_codvalor,
             dtr_monto,                   dtr_monto_mn,     dtr_moneda,
             dtr_cotizacion,              dtr_tcotizacion,  dtr_afectacion,
             dtr_cuenta,                  dtr_beneficiario, dtr_monto_cont)
      values(@i_secuencial,               @i_operacionca,   0,
             @w_co_concepto,
             @w_estado,                   0,                @w_codvalor_final,
             @w_co_monto,                 @w_monto_mn,      @w_moneda,
             @w_cot_mn,                   'N',              'D',
             isnull(@i_cuenta_final,''),  '',               0)
      
      if @@error <> 0
      begin
         PRINT 'traslado.sp  error insertando en ca_det_trn 4 '
         return 710001
      end
   end
end  


insert into ca_transaccion
      (tr_secuencial,          tr_fecha_mov,                   tr_toperacion,
       tr_moneda,              tr_operacion,                   tr_tran,
       tr_en_linea,            tr_banco,                       tr_dias_calc,
       tr_ofi_oper,            tr_ofi_usu,                     tr_usuario,
       tr_terminal,            tr_fecha_ref,                   tr_secuencial_ref,
       tr_estado,              tr_observacion,                 tr_gerente,
       tr_gar_admisible,       tr_reestructuracion,            tr_calificacion,
       tr_fecha_cont,          tr_comprobante)  
values(@i_secuencial,          @s_date,                        @i_toperacion,
       @i_moneda,              @i_operacionca,                 @i_trn,
       'N',                    @i_banco,                       0,
       @i_oficina,             @i_oficina,                     @s_user,
       @s_term,                @w_fecha_ult_proceso,           0,
       'ING',                  @w_observacion,                 @i_gerente,
       isnull(@i_garantia,''), isnull(@i_reestructuracion,''), isnull(@i_calificacion,''),
       @i_fecha_proceso,       0)

if @@error != 0
begin
   return 708165
end

if @i_trn = 'SUA'
begin
   update ca_operacion
   set    op_cap_susxcor = 0
   where  op_operacion   = @i_operacionca
end

return 0

go
