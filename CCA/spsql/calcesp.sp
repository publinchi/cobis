/************************************************************************/
/*   Nombre Fisico         :        calcesp.sp                          */
/*   Nombre Logico     	   :        sp_calculo_especial                 */
/*   Base de datos         :        cob_cartera                         */
/*   Producto              :        Cartera                             */
/*   Disenado por          :        Fabian de la Torre                  */
/*   Fecha de escritura    :        Ene. 1998                           */
/************************************************************************/
/*                          IMPORTANTE                                  */
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
/*                          PROPOSITO                                   */
/*   Procedimiento que realiza el calculo diario especial de interes    */
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/*       FEB-14-2002             RRB         Agregar campos al insert   */
/*                                           en ca_transaccion          */
/*      MAR-07-2005            EPB         Insert tr_fecha_ref ok       */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calculo_especial')
   drop proc sp_calculo_especial
go

create proc sp_calculo_especial
   @s_user         login,
   @s_term       varchar(30),
   @s_date       datetime,
   @s_ofi       smallint,
   @i_en_linea       char(1),
   @i_toperacion    catalogo,
   @i_banco         cuenta,
   @i_operacionca     int,
   @i_moneda        smallint,
   @i_dias_anio     smallint,
   @i_sector        catalogo,
   @i_oficina       smallint,
   @i_fecha_liq     datetime,
   @i_fecha_ini     datetime,
   @i_fecha_proceso datetime

as declare 
   @w_secuencial     int,
   @w_error          int,
   @w_return         int,
   @w_sp_name        descripcion,
   @w_saldo_cap      money,
   @w_monto_mora     money,
   @w_dias_calc      tinyint,
   @w_valor_calc     float,
   @w_codvalor       int,
   @w_di_dividendo   int,
   @w_di_gracia_disp smallint,
   @w_di_fecha_ini   datetime, 
   @w_di_fecha_ven   datetime,
   @w_di_estado        tinyint,
   @w_di_gracia      smallint,
   @w_ro_concepto    catalogo,
   @w_ro_porcentaje  float,
   @w_ro_tipo_rubro  char(1),
   @w_ro_fpago       char(1),
   @w_ro_provisiona  char(1),
   @w_num_dec        tinyint,
   @w_est_novigente  tinyint, 
   @w_est_vigente    tinyint, 
   @w_est_vencido    tinyint, 
   @w_est_cancelado  tinyint, 
   @w_tr_estado      catalogo, 
   @w_crear_nuevo    char(1), 
   @w_am_cap_pagado  money,
   @w_am_cuota       money,
   @w_am_acumulado   float,
   @w_am_estado      tinyint,
   @w_am_secuencia   tinyint,
   @w_am_periodo     tinyint,
   @w_mas_gracia     smallint,
   @w_am_pagado      money,
   @w_afectaciones   int,
   @w_causacion      char(1), 
   @w_dias_int       int,     
   @w_tasa_equivalente char(1),
   @w_gerente        smallint,
   @w_moneda_nac     smallint,
   @w_num_dec_mn     smallint,
   @w_monto_mn       money,
   @w_cot_mn         money,
   @w_gar_admisible    char(1), 
   @w_reestructuracion    char(1), 
   @w_calificacion    catalogo,  
   @w_op_fecha_ult_proceso  datetime


--- VARIABLES DE TRABAJO 
select 
@w_sp_name        = 'sp_calculo_especial',
@w_est_novigente  = 0,
@w_est_vigente    = 1,
@w_est_vencido    = 2,
@w_est_cancelado  = 3


select @w_causacion        = op_causacion,
       @w_tasa_equivalente = op_usar_tequivalente,
       @w_gerente          = op_oficial,
       @w_gar_admisible    = op_gar_admisible,    
       @w_reestructuracion = op_reestructuracion,
       @w_calificacion      = op_calificacion,
       @w_op_fecha_ult_proceso = op_fecha_ult_proceso

from ca_operacion 
where op_operacion = @i_operacionca



--- MANEJO DE DECIMALES PARA LA MONEDA DE LA OPERACION 
--- ANEJO DE DECIMALES 
exec @w_return = sp_decimales
@i_moneda    = @i_moneda,
@o_decimales = @w_num_dec out,
@o_mon_nacional = @w_moneda_nac out,
@o_dec_nacional = @w_num_dec_mn out

if @w_return <> 0 return @w_return

--- DETERMINAR EL SALDO DE CAPITAL  
select @w_saldo_cap = sum(am_cuota + am_gracia - am_pagado)
from   ca_amortizacion, ca_rubro_op
where  ro_operacion  = @i_operacionca
and    am_operacion  = @i_operacionca
and    ro_concepto   = am_concepto
and    ro_tipo_rubro = 'C'   

--- DETERMINAR EL MAXIMO DIVIDENDO DE LA OPERACION 
select @w_di_dividendo = max(di_dividendo)
from   ca_dividendo
where  di_operacion    = @i_operacionca

--- PARA CONTABILIDAD 
--- VERIFICAR NECESIDAD DE CREAR NUEVAS TRANSACCIONES 

select @w_crear_nuevo = 'N' 

select @w_secuencial = max(tr_secuencial)
from ca_transaccion
where tr_operacion = @i_operacionca


select @w_secuencial = isnull(@w_secuencial, 0)

if not exists( select 1 from ca_transaccion
where tr_secuencial = @w_secuencial
and   tr_operacion  = @i_operacionca
and   tr_tran = 'PRV' )

   select @w_crear_nuevo = 'S' --existe una transaccion reversable

--- NUMERO DE DIAS DE CALCULO
select @w_dias_calc = 1

--- PARA CADA UNO DE LOS RUBROS .... 
declare cursor_rubro cursor for
select 
ro_concepto,   ro_porcentaje,  ro_tipo_rubro,
ro_provisiona, ro_fpago
from   ca_rubro_op
where  ro_operacion  = @i_operacionca
and    ro_fpago      in ('P')
and    ro_tipo_rubro in ('M')
and    ro_provisiona = 'S'
for read only

open    cursor_rubro
fetch   cursor_rubro into 
@w_ro_concepto,   @w_ro_porcentaje,  @w_ro_tipo_rubro,
@w_ro_provisiona, @w_ro_fpago

while   @@fetch_status = 0 
begin 

   if (@@fetch_status = -1) return 708999
   
   select 
   @w_valor_calc = 0,
   @w_am_secuencia = 0
 
   select @w_am_secuencia = max(am_secuencia)
   from   ca_amortizacion
   where  am_operacion    = @i_operacionca
   and    am_dividendo    = @w_di_dividendo
   and    am_concepto     = @w_ro_concepto
   and    am_periodo      = 0

   select @w_am_secuencia = isnull(@w_am_secuencia, 0)
   

   ---  VER EXISTENCIA DEL RUBRO DE MORA 
   if @w_am_secuencia = 0 
   begin
      
      insert ca_amortizacion ( 
      am_operacion,   am_dividendo,      am_concepto, 
      am_estado,      am_periodo,        am_cuota,
      am_gracia,      am_pagado,         am_acumulado,
      am_secuencia )
      values (
      @i_operacionca, @w_di_dividendo,   @w_ro_concepto,
      @w_est_vigente, 0,                 0,
      0,              0,                 0,
      1)

      if @@error != 0 return 703079

      select 
      @w_am_acumulado = 0,
      @w_am_cuota     = 0,
      @w_am_secuencia = 1,
      @w_am_periodo   = 0,
      @w_am_pagado    = 0

   end 
   else
   begin
      select
      @w_am_cuota     = am_cuota,
      @w_am_acumulado = am_acumulado,
      @w_am_pagado    = am_pagado,
      @w_am_estado    = am_estado,
      @w_am_periodo   = am_periodo
      from   ca_amortizacion
      where  am_operacion    = @i_operacionca
      and    am_dividendo    = @w_di_dividendo
      and    am_concepto     = @w_ro_concepto
      and    am_periodo      = 0
      and    am_secuencia    = @w_am_secuencia    
   end

   select @w_am_estado    = @w_est_vigente
            
   if (@w_saldo_cap != 0) 
   begin
 
      --- CONSULTAR TASA DE MORA POR RUBRO Y DIVIDENDO 
      exec  @w_return = sp_consulta_tasas
      @i_operacionca = @i_operacionca,
      @i_dividendo   = @w_di_dividendo,
      @i_concepto    = @w_ro_concepto,
      @i_sector      = @i_sector,
      @i_fecha       = @i_fecha_proceso,
      @i_equivalente = @w_tasa_equivalente,
      @o_tasa        = @w_ro_porcentaje out

      --RBU
      if @w_causacion = 'L'
         select @w_dias_int = @w_dias_calc
      else
          if @w_causacion = 'E'
             select @w_dias_int = @w_dias_calc - 1
      --Fin RBU                

      exec @w_return = sp_calc_intereses  
      @tasa      = @w_ro_porcentaje,
      @monto     = @w_saldo_cap,
      @dias_anio = @i_dias_anio,
      @num_dias  = @w_dias_int, 
      @causacion = @w_causacion,
      @intereses = @w_valor_calc out
     
      select @w_valor_calc   = round(@w_valor_calc,@w_num_dec)

   end
   
   select @w_valor_calc = isnull(@w_valor_calc, 0)

   --- CONTABILIDAD Y TABLA DE AMORTIZACION                           
   --- en caso de ser cero el valor calculado se debe de todas formas 
   --- actualizar el numero de dias de provision en el caso de moras  

   if @w_valor_calc <> 0 
   begin 

      select @w_codvalor = co_codigo * 1000 + @w_am_estado * 10
      from  ca_concepto
      where co_concepto    = @w_ro_concepto 

      --- VERIFICAR CREACION ACTUALIZACION REGISTRO DE PROVISION 

      if @w_crear_nuevo = 'N' 
      begin

         set rowcount 1

         select 
         @w_secuencial = tr_secuencial,
         @w_tr_estado  = tr_estado
         from ca_transaccion, ca_det_trn 
         where tr_secuencial = dtr_secuencial
         and   tr_operacion  = dtr_operacion
         and  tr_operacion  = @i_operacionca
         and  tr_tran       = 'PRV'
         and (tr_estado     = 'ING' or tr_estado  = 'CON' )
         and  dtr_dividendo = @w_di_dividendo
         and  dtr_codvalor  = @w_codvalor
         order by tr_secuencial desc -- RGA 02/20/1997

         select @w_afectaciones = @@rowcount

         set rowcount 0

         if @w_afectaciones = 0 select @w_crear_nuevo = 'S'
         else begin

            if exists (select 1 from ca_transaccion
            where tr_operacion  = @i_operacionca

            and   tr_secuencial > @w_secuencial 
            and   tr_tran      <> 'PRV')
             
               select @w_crear_nuevo = 'S' 

         end
      end
         
      --- ACTUALIZAR LA TABLA TRANSACCIONES 
      if @w_crear_nuevo = 'N' 
      begin

         update ca_transaccion set
         tr_dias_calc   = tr_dias_calc + @w_dias_calc,
         tr_estado      = 'ING',
         tr_fecha_mov   = @s_date,
         tr_fecha_ref   = @w_op_fecha_ult_proceso
         where tr_secuencial = @w_secuencial
           and tr_operacion  = @i_operacionca

         if @@error != 0 return 708165

         if @w_tr_estado = 'CON' 
         begin

           --- COTIZACION MONEDA 
            exec @w_return = sp_conversion_moneda
            @s_date             = @s_date,
            @i_opcion           = 'L',
            @i_moneda_monto   = @i_moneda,
            @i_moneda_resultado   = @w_moneda_nac,
            @i_monto      = @w_valor_calc,
            @i_fecha            = @i_fecha_proceso, 
            @o_monto_resultado   = @w_monto_mn out,
            @o_tipo_cambio      = @w_cot_mn out


            update ca_det_trn set
            dtr_monto             = @w_valor_calc,
            dtr_cotizacion        = @w_cot_mn,
            dtr_monto_mn          = @w_monto_mn
            where dtr_secuencial  = @w_secuencial
            and   dtr_operacion   = @i_operacionca
            and   dtr_codvalor    = @w_codvalor 

            if @@error != 0 
            return 708165

         end 
         else 
         begin

            update ca_det_trn set
            dtr_monto         = dtr_monto + @w_valor_calc,
            dtr_cotizacion    = 0,
            dtr_monto_mn      = 0
            where dtr_secuencial  = @w_secuencial
            and   dtr_operacion   = @i_operacionca
            and dtr_codvalor      = @w_codvalor

            if @@error != 0 return 708165

         end

      end 
      else 
      begin

         select @w_crear_nuevo = 'N'

         exec @w_secuencial = sp_gen_sec
              @i_operacion  = @i_operacionca
   
         
         insert into ca_transaccion (
         tr_secuencial,     tr_fecha_mov,  tr_toperacion,
         tr_moneda,         tr_operacion,  tr_tran,
         tr_en_linea,       tr_banco,      tr_dias_calc,
         tr_ofi_oper,       tr_ofi_usu,    tr_usuario,
         tr_terminal,       tr_fecha_ref,  tr_secuencial_ref,
         tr_estado,         tr_gerente,    tr_gar_admisible, 
         tr_reestructuracion,          tr_calificacion,    
         tr_observacion,    tr_fecha_cont, tr_comprobante)
         values (
         @w_secuencial,     @s_date,         @i_toperacion,   
         @i_moneda,         @i_operacionca,    'PRV',
         @i_en_linea,       @i_banco,        @w_dias_calc,
         @i_oficina,        @s_ofi,          @s_user,
         @s_term,           @w_op_fecha_ult_proceso,0,
         'ING',             @w_gerente ,     isnull(@w_gar_admisible,''), 
         isnull(@w_reestructuracion,''),     isnull(@w_calificacion,''),
         '',                @s_date,        0)

         if @@error != 0 
         return 708165
         
         insert into ca_det_trn (
         dtr_secuencial, dtr_operacion,     dtr_dividendo,
         dtr_concepto,
         dtr_estado,     dtr_periodo,      dtr_codvalor,
         dtr_monto,      dtr_monto_mn,     dtr_moneda,
         dtr_cotizacion, dtr_tcotizacion,  dtr_afectacion,
         dtr_cuenta,     dtr_beneficiario, dtr_monto_cont )
         values (
         @w_secuencial,  @i_operacionca,   @w_di_dividendo,
         @w_ro_concepto,
         @w_am_estado,   @w_am_periodo,    @w_codvalor,
         @w_valor_calc,  0,                @i_moneda,
         0,              'N',              'D',
         '',             '',               0 )
           
         if @@error != 0 return 708166

      end  --- fin crear nueva transaccion 
   end

      --- ACTUALIZAR CA_AMORTIZACION 
   if isnull(@w_valor_calc,0) <> 0 
   begin

      if @w_ro_tipo_rubro = 'M'
         select @w_am_cuota=round(@w_am_acumulado+@w_valor_calc,@w_num_dec)

      update ca_amortizacion set
      am_cuota      = @w_am_cuota,
      am_acumulado  = round(@w_valor_calc + am_acumulado,@w_num_dec)
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_di_dividendo
      and    am_concepto  = @w_ro_concepto
      and    am_secuencia = @w_am_secuencia
       
      if @@error != 0 return 705050

   end -- valor calculado <> 0 

   select @w_valor_calc = 0

   NEXTRUBRO:
   fetch   cursor_rubro into 
   @w_ro_concepto,   @w_ro_porcentaje,   @w_ro_tipo_rubro,
   @w_ro_provisiona, @w_ro_fpago

end ---WHILE CURSOR RUBROS

close cursor_rubro

deallocate cursor_rubro

set rowcount 0

return 0

go
