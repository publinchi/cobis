/************************************************************************/
/*   Nombre Fisico:        trasofi.sp                                   */
/*   Nombre Logico:        sp_traslado_ofic                             */
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
/*		Fecha			Autor					Razon					*/
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/  
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_traslado_ofic')
   drop proc sp_traslado_ofic
go

create proc sp_traslado_ofic
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
   @w_codvalor             int,
   @w_ro_fpago             char(1),
   @w_signo_extrae         int,
   @w_moneda_n             int,
   @w_error                int,
   @w_fecha_ult_proceso    datetime,
   @w_dividendo            int,
   @w_est_novigente        int,
   @w_est_suspenso         int,
   @w_estado_op            int

-- CARGAR VARIABLES DE TRABAJO
select @w_monto         = 0, 
       @w_observacion   = 'TRASLADO DE SALDOS POR ' + cast(@i_trn as varchar)
       
select @w_fecha_ult_proceso = op_fecha_ult_proceso,
       @w_estado_op         = op_estado
from   ca_operacion
where  op_operacion = @i_operacionca

exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_suspenso   = @w_est_suspenso  out
       
-- GENERAR DETALLE CON TODOS LOS CONCEPTOS
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
       having sum(am_acumulado - am_pagado) > 0.01
       UNION
       select am_concepto, am_estado, co_categoria, co_codigo, ro_fpago,
                  sum(am_acumulado - am_pagado), am_dividendo
       from   ca_amortizacion, ca_concepto, ca_rubro_op
       where  am_operacion = @i_operacionca
       and    am_estado    != 3
       and    co_concepto = am_concepto
       and    co_categoria not in ('C', 'M', 'I')
       --and    (am_estado in (1, 2, ) and ro_fpago != 'M' or am_estado in (0, 1, 2) and ro_fpago = 'M')
       and    ro_operacion = am_operacion
       and    ro_concepto  = am_concepto
       group  by am_concepto, am_estado, co_categoria, co_codigo, ro_fpago, am_dividendo
       having sum(am_acumulado - am_pagado) > 0.01
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
      
   select @w_codvalor_antes = @w_codvalor * 1000 + @w_am_estado * 10
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
   
   select @w_signo_extrae = -1
      
   insert into ca_det_trn
   (dtr_secuencial,    dtr_operacion,                dtr_dividendo,
    dtr_concepto,      dtr_estado,                   dtr_periodo,      
    dtr_codvalor,      dtr_monto,                    dtr_monto_mn,     
    dtr_moneda,        dtr_cotizacion,               dtr_tcotizacion,  
    dtr_afectacion,    dtr_cuenta,                   dtr_beneficiario, 
    dtr_monto_cont                                   
   )                                                 
   values                                            
   (@i_secuencial,     @i_operacionca,               @w_dividendo,
    @w_am_concepto,    @w_am_estado,                 0,                 
    @w_codvalor_antes, @w_signo_extrae * @w_monto,   @w_signo_extrae * @w_monto_mn,
    @i_moneda,         @w_cot_mn,                    'N',              
    'D',               isnull(@i_cuenta_antes,''),   '', 
    0                                                
   )                                                 
   
   if @@error <> 0
   begin
      PRINT 'traslado.sp  error insertando en ca_det_trn 1 '
      return 710001
   end
   
   insert into ca_det_trn
   (dtr_secuencial,       dtr_operacion,                  dtr_dividendo,
    dtr_concepto,         dtr_estado,                     dtr_periodo,      
    dtr_codvalor,         dtr_monto,                      dtr_monto_mn,     
    dtr_moneda,           dtr_cotizacion,                 dtr_tcotizacion,  
    dtr_afectacion,       dtr_cuenta,                     dtr_beneficiario, 
    dtr_monto_cont                                        
   )                                                      
   values                                                 
   (@i_secuencial,        @i_operacionca,                 @w_dividendo,
    @w_am_concepto,       @w_am_estado,                   0,                
    @w_codvalor_final,    @w_monto,                       @w_monto_mn,      
    @i_moneda,            @w_cot_mn,                      'N',               
    'D',                  isnull(@i_cuenta_final,''),     '',               
    0                     
   )
   
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


return 0

go
