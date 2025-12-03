/************************************************************************/
/* Nombre Fisico:       trasint.sp                                      */
/* Nombre Logico:       sp_traslado_interes                             */
/* Base de datos:       cob_cartera                                     */
/* Producto:            Cartera                                         */
/* Disenado por:        Ivan Jimenez                                    */
/* Fecha de escritura:  09-Nov-2005                                     */
/************************************************************************/
/*                         IMPORTANTE                                   */
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
/*                         PROPOSITO                                    */
/* Proceso ejecutado desde el batch1.sp para realizar el traslado de    */
/* intereses corrientes                                                 */
/************************************************************************/
/*                      MODIFICACIONES                                  */
/* FECHA            AUTOR               RAZON                           */
/* 09/Nov/2005      I.Jimenez       Emision Inicial                     */
/* OCT-05-2006      E.Pelaez        def.7268 BAC                        */
/* NOV-02-2010      E.Pelaez        Quitar lo de Diferidos NR-059       */
/* FEB-18-2021      K. Rodríguez    Se comenta uso de concepto CXCINTES */
/* 06/06/2023	 	M. Cordova		Cambio variable @w_calificacion   	*/
/*									de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_ejecuta_traslado_int')
	drop proc sp_ejecuta_traslado_int
go


create proc sp_ejecuta_traslado_int
   @s_user               login,
   @s_term               varchar(30),
   @s_date               datetime,
   @s_ofi                smallint,
   @i_operacion	       int,
   @i_dividendo_vig      smallint,
   @i_banco              cuenta,
   @i_toperacion         catalogo,
   @i_moneda             smallint,
   @i_oficial            int,
   @i_oficina            int,
   @i_gar_admisible      char(1) = 'N',
   @i_reestructuracion   char(1) = 'N',
   @i_calificacion       catalogo = 'A',
   @i_en_linea           char(1) = 'N',
   @i_fecha_proceso      datetime

as
declare
   @w_dividendo_dest       smallint,
   @w_concepto             catalogo,
   @w_valor                money,
   @w_secuencial           int,
   @w_am_acumulado         money,
   @w_am_pagado            money,
   @w_am_estado            smallint,
   @w_transaccion          char(1),
   @w_parametro_cxcintes   catalogo,
   @w_concepto_traslado    catalogo,
   @w_secuencia            smallint,
   @w_sec_amor             smallint,
   @w_rowcount             int

---  INICIALIZACION DE VARIABLES
select @w_transaccion = 'N'

select @w_dividendo_dest = ti_cuota_dest
from   ca_traslado_interes
where  ti_operacion  = @i_operacion
and    ti_cuota_orig = @i_dividendo_vig

if @@rowcount = 0 
   return 0

select @w_parametro_cxcintes = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CXCINT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

/*  -- KDR Sección no aplica para la versión de Finca
if @w_rowcount = 0 
   return 711016

select @w_concepto_traslado  = co_concepto
from   ca_concepto,ca_rubro
where  co_concepto = @w_parametro_cxcintes
and    co_concepto = ru_concepto
and    ru_toperacion = @i_toperacion

if @@rowcount = 0 
   return 711017
*/ -- FIN KDR

exec @w_secuencial = sp_gen_sec
     @i_operacion  = @i_operacion

exec sp_historial
     @i_operacionca = @i_operacion,
     @i_secuencial  = @w_secuencial
  
declare
   cursor_traslado_cxcintes cursor
   for select (am_acumulado - am_pagado), am_estado, am_concepto,
              am_secuencia
       from   ca_amortizacion, 
              ca_rubro_op
       where ro_operacion  = @i_operacion
       and   ro_tipo_rubro = 'I'
       and   ro_fpago      = 'P'
       and   am_operacion  = ro_operacion
       and   am_dividendo  = @i_dividendo_vig
       and   am_concepto   = ro_concepto
       and   (am_acumulado - am_pagado) > 0
       and   am_estado != 3
   for read only

open cursor_traslado_cxcintes

fetch cursor_traslado_cxcintes
into  @w_valor, @w_am_estado, @w_concepto, @w_secuencia

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin
   if exists (select 1
              from   ca_rubro_op
              where  ro_operacion = @i_operacion
              and    ro_concepto    = @w_concepto_traslado)
   begin
      update ca_rubro_op
      set    ro_valor           = ro_valor + @w_valor
      where  ro_operacion = @i_operacion
      and    ro_concepto  = @w_concepto_traslado
      
      if @@rowcount = 0 or @@error != 0
          return 710002
   end
   ELSE
   begin
      insert into ca_rubro_op
            (ro_operacion,            ro_concepto,        ro_tipo_rubro,
             ro_fpago,                ro_prioridad,       ro_paga_mora,
             ro_provisiona,           ro_signo,           ro_factor,
             ro_referencial,          ro_signo_reajuste,  ro_factor_reajuste,
             ro_referencial_reajuste, ro_valor,           ro_porcentaje,
             ro_porcentaje_aux,       ro_gracia,          ro_concepto_asociado,
             ro_principal,            ro_porcentaje_efa,  ro_garantia,
             ro_saldo_op,             ro_saldo_por_desem, ro_base_calculo,
             ro_num_dec)
      select @i_operacion,            @w_concepto_traslado, ru_tipo_rubro,
             ru_fpago,                ru_prioridad,       ru_paga_mora,
             ru_provisiona,           '+',                0,
             ru_referencial,          '+',                0,
             null,                    @w_valor,           0,
             0,                       0,                  null,
             ru_principal,            0,                  0,
             'N',                     'N',                0,
             0
      from   ca_rubro       
      where  ru_toperacion  = @i_toperacion
      and    ru_moneda      = @i_moneda
      and    ru_concepto    = @w_concepto_traslado
      
      if @@rowcount = 0 or @@error != 0
      return 711021
   end
   
   if exists(select 1 from ca_amortizacion
             where am_operacion = @i_operacion
             and am_dividendo   = @w_dividendo_dest
             and am_concepto    = @w_concepto_traslado
             and am_estado      = @w_am_estado
             and am_secuencia   = @w_secuencia)
   begin
      update ca_amortizacion
      set    am_acumulado = am_acumulado + @w_valor,
             am_cuota     = am_cuota + @w_valor,
             am_estado    = @w_am_estado
      where  am_operacion = @i_operacion
      and    am_concepto  = @w_concepto_traslado
      and    am_dividendo = @w_dividendo_dest 
      and    am_estado    = @w_am_estado
      and    am_secuencia = @w_secuencia
      
      if @@error != 0 
      begin
--         PRINT 'ejtransint.sp actualizando ca_amortizacion'
         return 710257
      end
   end
   ELSE
   begin 
      select @w_sec_amor = 0
      
      select @w_sec_amor = isnull(max(am_secuencia),0)
      from   ca_amortizacion
      where  am_operacion = @i_operacion
      and    am_concepto  = @w_concepto_traslado
      and    am_dividendo = @w_dividendo_dest 
      
      select @w_sec_amor =  @w_sec_amor + 1
      
      insert ca_amortizacion
            (am_operacion,   am_dividendo,      am_concepto,
             am_estado,      am_periodo,        am_cuota,
             am_gracia,      am_pagado,         am_acumulado,
             am_secuencia )
      values(@i_operacion,  @w_dividendo_dest,   @w_concepto_traslado,
             @w_am_estado,   0,                 @w_valor,
             0,              0,                 @w_valor,
             @w_sec_amor)
      
      if @@error != 0 
      begin
--         PRINT 'ejtransint.sp insertando ca_amortizacion @w_sec_amor' + cast(@w_sec_amor as varchar) + ' @w_valor '+ cast(@w_valor as varchar) + ' @w_concepto_traslado ' + cast(@w_concepto_traslado as varchar)
         return 710257
      end
   end
   
   --	ACTUALIZAR LA TABLA CA_AMORTIZACION
   update ca_amortizacion
   set    am_pagado = am_cuota,
          am_estado    = 3
   where  am_operacion = @i_operacion
   and    am_concepto  = @w_concepto
   and    am_dividendo = @i_dividendo_vig
   and    am_estado    = @w_am_estado
   and    am_secuencia = @w_secuencia
   
   fetch cursor_traslado_cxcintes
   into  @w_valor, @w_am_estado, @w_concepto, @w_secuencia
end ---CURSOR PAGOS ANUALES

select @w_transaccion = 'S'
   
close cursor_traslado_cxcintes
deallocate cursor_traslado_cxcintes

if @w_transaccion = 'S'
begin
   insert into ca_transaccion
        (tr_secuencial,    tr_fecha_mov,        tr_toperacion,       tr_moneda,
         tr_operacion,     tr_tran,             tr_en_linea,         tr_banco,
         tr_dias_calc,     tr_ofi_oper,         tr_ofi_usu,          tr_usuario,
         tr_terminal,      tr_fecha_ref,        tr_secuencial_ref,   tr_estado,
         tr_observacion,   tr_gerente,          tr_comprobante,      tr_fecha_cont,
         tr_gar_admisible, tr_reestructuracion, tr_calificacion)
   values(@w_secuencial,    @s_date,              @i_toperacion,    @i_moneda,
          @i_operacion,     'TIC',                @i_en_linea,       @i_banco,
          0,                @i_oficina,           @i_oficina,       @s_user,
          @s_term,          @i_fecha_proceso,     -999,             'NCO',
          'TRASLADO DE INTERESES', @i_oficial, 0,         @s_date,
          @i_gar_admisible, @i_reestructuracion,          @i_calificacion)
   
   if @@error != 0
      return 708165
   
   update ca_traslado_interes
   set    ti_estado     = 'P',
          ti_monto      = @w_valor
   where  ti_operacion  = @i_operacion
   and    ti_cuota_orig = @i_dividendo_vig
end

return 0
                                                                 
go


