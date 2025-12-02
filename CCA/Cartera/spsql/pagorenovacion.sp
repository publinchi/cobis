/************************************************************************/
/*   Nombre Fisico:        pagorenovacion.sp                            */
/*   Nombre Logico:        sp_pago_renovacion                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Fabian Quintero                              */
/*   Fecha de escritura:   Junio 2006                                   */
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
/*   Procedimiento que realiza el pago a una obligación por renovación  */
/*   Este pago consiste en generar una transaccion PRN con los conceptos*/
/*   seleccionados en la renovacion y almacenados en la tabla           */
/*   cob_credito..cr_rub_renovar el valor pagado de estos rubros no debe*/
/*   superar el valor renopvado en la obligacion nueva                  */
/*   Junio-06-2007                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA            AUTOR         CAMBIO                           */
/*      OCT-28-2008      EPB           Cambios Bancamia                 */
/*    06/06/2023	 M. Cordova	  Cambio variable @w_op_calificacion_ant*/
/*								  de char(1) a catalogo					*/
/*    07/11/2023     K. Rodriguez Actualiza valor despreciab            */
/************************************************************************/

use cob_cartera
go

--- SECCION:SP no quitar esta seccion
--- SP: 
--- NRO: 3
--- PREFIJOERRORES: 7203
--- FINSECCION:SP no quitar esta seccion
--- SECCION:ERRORES no quitar esta seccion

declare
@w_ret int
exec @w_ret = sp_insertar_error 720301, 0, 'No se encontro el registro de detalle de conceptos a renovar'
exec @w_ret = sp_insertar_error 720302, 0, 'No se encontro información del tramite de renovación'
exec @w_ret = sp_insertar_error 720303, 0, 'Fecha de inicio de  la operacion nueva es diferente a la de ultimo proceso de la vieja REVISAR'
exec @w_ret = sp_insertar_error 720304, 0, 'Error creando la transaccion de pago de renovación'
exec @w_ret = sp_insertar_error 720305, 0, 'Error grave en ejecución de sp_decimales'
exec @w_ret = sp_insertar_error 720306, 0, 'El estado de la obligación no permite su renovación'
exec @w_ret = sp_insertar_error 720307, 0, 'Error en actualización del valor disponible de la garantia'
exec @w_ret = sp_insertar_error 720308, 0, 'Error en actualización del estado de agotada de la garantía'
exec @w_ret = sp_insertar_error 720309, 0, 'Error en llamada para utilización del cupo'
exec @w_ret = sp_insertar_error 720310, 0, 'Error preparando valores de la renovación'
exec @w_ret = sp_insertar_error 720311, 0, 'Error La cancelacion total no fue exitosa Revisar'
go

--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_pago_renovacion')
   drop proc sp_pago_renovacion
go

---Ver.12 Ago-06-2007

create proc sp_pago_renovacion
@s_sesn                 int,
@s_ssn                  int,
@s_user                 login,
@s_date                 datetime,
@s_ofi                  int,
@s_term                 varchar(30),
@i_tramite_ren          int,           -- N+MERO DE TR-MITE DE RENOVACIÓN (OBLIGACION NUEVA)
@i_operacion_ant        int,           -- NUMERO DE LA OBLIGACION QUE SE RENUEVA (OBLIGACION ANTERIOR)
@i_monto_renovado       money,
@i_fecha_ini_nueva      datetime,
@i_en_linea             char(1) = 'S'
as
declare
   @w_error                      int,
   @w_ar_usuario                 login,
   @w_op_operacion_ant           int,
   @w_op_estado_ant              smallint,
   @w_ar_concepto                catalogo,
   @w_ar_estado                  smallint,
   @w_ar_monto_pago              money,
   @w_monto_sobrante             money,
   
   @w_ro_fpago                   char(1),
   @w_ro_tipo_rubro              char(1),
   @w_co_categoria               catalogo,
   @w_co_codigo                  tinyint,
   @w_ar_estado_cuota            tinyint,
   
   @w_op_moneda_ant              smallint,
   @w_op_fecha_ult_proceso_ant   datetime,
   @w_op_toperacion_ant          catalogo,
   @w_op_banco_ant               cuenta,
   @w_op_oficina_ant             smallint,
   @w_op_gerente_ant             smallint,
   @w_op_gar_admisible_ant       char(1),
   @w_op_reestructuracion_ant    char(1),
   @w_op_calificacion_ant        catalogo,
   @w_op_tipo_ant                char(1),
   @w_op_tramite_ant             int,
   @w_op_lin_credito_ant         cuenta,
   @w_op_cliente_ant             int,
   @w_op_numero_comex_ant        cuenta,
   @w_modo_utilizacion           tinyint,
   @w_naturaleza                 char(1),
   
   @w_cotizacion                 float,
   @w_cotizacion_dia_sus         float,
   @w_fecha_suspenso             datetime,
   @w_di_dividendo               smallint,
   @w_di_estado                  smallint,
   @w_am_dividendo               smallint,
   @w_am_estado                  smallint,
   @w_am_cuota                   money,
   @w_am_acumulado               money,
   @w_am_pagado                  money,
   @w_am_secuencia               tinyint,
   
   @w_monto_aplicado             money,
   @w_monto_aplicado_cap         money,
   
   @w_num_dec_op                 tinyint,
   @w_moneda_mn                  tinyint,
   @w_num_dec_mn                 tinyint,
   @w_secuencial_pag             int,
   
   @w_monto_aplicado_cap_mn      money,
   @w_bandera_be                 char(1),
   @w_secuencial_ing             int,
   @w_cancela_dividendo          char,
   @w_saldo_div                  money,
   @w_vlr_despreciable           float,
   @w_saldo_cap_op_ant           money,
   @w_valores_rub_seleccionados  money,
   @w_va                         money,
   @w_diff                       money,
   @w_capitaliza                 char(1),
   @w_tipo_de_seleccion          char(1),
   @w_div_vigente                smallint,
   @w_saldo_cap                  money,
   @w_tiene_garantia             char(1)

begin
   select @w_monto_aplicado = 0.00,
          @w_diff           = 0.00,
          @w_tiene_garantia = 'N'

   select @w_op_operacion_ant          = op_operacion,
          @w_op_estado_ant             = op_estado,
          @w_op_moneda_ant             = op_moneda,
          @w_op_fecha_ult_proceso_ant  = op_fecha_ult_proceso,
          @w_op_toperacion_ant         = op_toperacion,
          @w_op_banco_ant              = op_banco,
          @w_op_gerente_ant            = op_oficial,
          @w_op_gar_admisible_ant      = isnull(op_gar_admisible, 'N'),
          @w_op_reestructuracion_ant   = isnull(op_reestructuracion, 'N'),
          @w_op_calificacion_ant       = isnull(op_calificacion, 'A'),
          @w_op_tipo_ant               = op_tipo,
          @w_op_tramite_ant            = op_tramite,
          @w_op_lin_credito_ant        = op_lin_credito,
          @w_op_cliente_ant            = op_cliente,
          @w_op_numero_comex_ant       = op_num_comex,
          @w_op_oficina_ant            = op_oficina,
          @w_tipo_de_seleccion         = or_aplicar
   from   ca_operacion, cob_credito..cr_op_renovar
   where  op_banco   = or_num_operacion
   and    or_tramite = @i_tramite_ren
   and    op_operacion = @i_operacion_ant
   
   if @@rowcount = 0
   begin
      select @w_error = 720302
      goto SALIDA_ERROR
   end

   
   select  @w_div_vigente = isnull(max(di_dividendo),0)
   from ca_dividendo 
   where di_operacion =  @i_operacion_ant
   and   di_estado = 1
   
   delete ca_abono_renovacion
   where  ar_tramite_ren = @i_tramite_ren
   
   exec @w_error = sp_saldo_operacion
        @i_operacion = @w_op_operacion_ant
   
   if @w_error != 0
   begin
      goto SALIDA_ERROR
   end
   
   exec @w_secuencial_ing = sp_gen_sec
        @i_operacion = @w_op_operacion_ant

   insert into ca_abono_renovacion
         (ar_tramite_ren,     ar_operacion,     ar_usuario,
          ar_fecha_gra,       ar_estado_reg,    ar_concepto,
          ar_estado,
          ar_monto_pago,
          ar_secuencial_ing,
          ar_fecha_hora_gra,
          ar_estado_cuota)
   select @i_tramite_ren,     @w_op_operacion_ant,  @s_user,
          @s_date,            'I',                  rr_concepto,
          rr_estado,
          (select isnull(sum(sot_saldo_acumulado), 0)
           from   ca_saldo_operacion_tmp
           where  sot_operacion        = @w_op_operacion_ant
           and    sot_estado_dividendo = r.rr_estado_cuota -- CONDICION DE RENOVACION
           and    sot_concepto         = r.rr_concepto     -- CONDICION DE RENOVACION
           and    (sot_estado_concepto  = r.rr_estado or r.rr_concepto = 'CAP') -- CONDICION DE RENOVACION
          ),
          @w_secuencial_ing,
          getdate(),
          rr_estado_cuota
   from   cob_credito..cr_rub_renovar r
   where  rr_tramite = @w_op_tramite_ant
   and    rr_tramite_re = @i_tramite_ren
   and    rr_estado is not null
   
   if @@error != 0 or @@rowcount = 0
   begin
      select @w_error = 720310
      goto SALIDA_ERROR
   end
   
   delete ca_abono_renovacion
   where  ar_tramite_ren = @i_tramite_ren
   and    ar_monto_pago = 0
   
   select @w_valores_rub_seleccionados = isnull(sum(abs(ar_monto_pago)),0)
   from   ca_abono_renovacion
   where  ar_tramite_ren = @i_tramite_ren
   
   if @w_valores_rub_seleccionados = 0
      return 0 -- NADA QUE RENOVAR

      
   select @w_ar_usuario = ar_usuario
   from   ca_abono_renovacion
   where  ar_tramite_ren = @i_tramite_ren
   
   if @@rowcount = 0
   begin
      select @w_error = 720301
      goto SALIDA_ERROR
   end
   
   if @w_op_estado_ant in (0, 3, 6)
   begin
      select @w_error = 720306
      goto SALIDA_ERROR
   end
   
   exec @w_error = sp_decimales
        @i_moneda       = @w_op_moneda_ant,
        @o_decimales    = @w_num_dec_op out,
        @o_mon_nacional = @w_moneda_mn  out,
        @o_dec_nacional = @w_num_dec_mn out
   
   if @@error != 0
   begin
      select @w_error = 720305
      goto SALIDA_ERROR
   end
   
   if @w_error != 0
      goto SALIDA_ERROR
   
   select @w_vlr_despreciable = 1.0 / power(10,  isnull((@w_num_dec_op + 2), 4))

   if @w_op_moneda_ant != @w_moneda_mn
   begin
      --VALIDAR QUE LAS FECHAS DE ULTIMO PROCESO DE LA VIEJA Y LA FECHA DE INICIO DE LA NUEVA SEAN LAS MISMAS
      --PARA QUE LA COTIZACION NO CAMBIEN Y LA APLICACION DEL PAGO SE HAGA POR EL VALOR CORRESPONDIENTE
      
      if @i_fecha_ini_nueva <> @w_op_fecha_ult_proceso_ant
      begin
         select @w_error = 720303
         goto SALIDA_ERROR
      end
      
      -- OBTENER LA COTIZACION DE LA FECHA DE PROCESO DE LA OBLIGACION
      exec sp_buscar_cotizacion
           @i_moneda     = @w_op_moneda_ant,
           @i_fecha      = @w_op_fecha_ult_proceso_ant,
           @o_cotizacion = @w_cotizacion out
      
      select @i_monto_renovado = @i_monto_renovado + 1.0 / @w_cotizacion
      

      if @w_op_estado_ant = 9 and @w_op_moneda_ant = 2 -- DETERMINAR LA FECHA Y COTIZACION DEL DIA DE LA SUSPENSION
      begin
         select @w_fecha_suspenso = null
         
         -- LOCALIZAR LA ULTIMA FECHA DE CAUSACION VIGENTE
         select @w_fecha_suspenso = isnull(max(tr_fecha_ref), @w_op_fecha_ult_proceso_ant)
         from   ca_transaccion
         where  tr_operacion = @w_op_operacion_ant
         and    tr_tran = 'SUA'
         and    tr_estado in ('CON', 'NCO')
         
         -- OBTENER LA COTIZACION DE ESE DIA
         exec sp_buscar_cotizacion
              @i_moneda     = @w_op_moneda_ant,
              @i_fecha      = @w_fecha_suspenso,
              @o_cotizacion = @w_cotizacion_dia_sus out
      end
   end
   ELSE
   begin
      select @w_cotizacion_dia_sus = 1,
             @w_cotizacion         = 1
   end
   
   exec @w_secuencial_pag = sp_gen_sec
        @i_operacion = @w_op_operacion_ant
   
   -- OBTENER RESPALDO ANTES DE LA APLICACION DEL PAGO con transaccion PRN
   exec @w_error  = sp_historial
        @i_operacionca  = @w_op_operacion_ant,
        @i_secuencial   = @w_secuencial_pag
   
   if @w_error != 0
   begin
      goto SALIDA_ERROR
   end


   ---SALDO PARA sp_aagotada debe ser antes de la aplicacion del pago
   --------------------------------------------------------------------
   select @w_saldo_cap_op_ant = @w_cotizacion * (sum(am_cuota - am_pagado))
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion  = @w_op_operacion_ant
   and    ro_tipo_rubro = 'C'
   and    am_operacion  = @w_op_operacion_ant
   and    am_estado <> 3
   and    am_concepto   = ro_concepto
   
   -- CREAR LA TRANSACCION DE PAGO
   insert into ca_transaccion
        (tr_secuencial,                tr_fecha_mov,                 tr_toperacion,
         tr_moneda,                    tr_operacion,                 tr_tran,
         tr_en_linea,                  tr_banco,                     tr_dias_calc,
         tr_ofi_oper,                  tr_ofi_usu,                   tr_usuario,
         tr_terminal,                  tr_fecha_ref,                 tr_secuencial_ref,
         tr_estado,                    tr_observacion,               tr_gerente,
         tr_comprobante,               tr_fecha_cont,                tr_gar_admisible,
         tr_reestructuracion,          tr_calificacion,              tr_fecha_real)
   values(@w_secuencial_pag,           @s_date,                      @w_op_toperacion_ant,
          @w_op_moneda_ant,            @w_op_operacion_ant,          'PRN',
          'N',                         @w_op_banco_ant,              0,
          @w_op_oficina_ant,           @s_ofi,                       @w_ar_usuario,
          @s_term,                     @w_op_fecha_ult_proceso_ant,  0,
          'ING',                       'RENOVACION DE OPERACION',    @w_op_gerente_ant,
          0,                           @s_date,                      @w_op_gar_admisible_ant,
          @w_op_reestructuracion_ant,  @w_op_calificacion_ant, getdate()
         )
   
   if @@error != 0
   begin
      select @w_error = 720304
      goto SALIDA_ERROR
   end
   
   update cob_credito..cr_op_renovar
   set    or_sec_prn = @w_secuencial_pag
   where  or_num_operacion = @w_op_banco_ant

   
   declare
      cur_secuencias cursor
      for select ar_usuario,  ar_concepto,   ar_estado,     ar_monto_pago,
                 ro_fpago,    ro_tipo_rubro, co_categoria,  co_codigo,
                 ar_estado_cuota
          from   ca_abono_renovacion, ca_rubro_op, ca_concepto
          where  ar_tramite_ren = @i_tramite_ren
          and    ar_estado     != 3
          and    ro_operacion = @w_op_operacion_ant
          and    ro_concepto = ar_concepto
          and    co_concepto = ar_concepto
          and    ar_estado_reg = 'I'
          order  by ar_estado_cuota desc
      for read only
   
   open cur_secuencias
   
   fetch cur_secuencias
   into  @w_ar_usuario, @w_ar_concepto,   @w_ar_estado,     @w_ar_monto_pago,
         @w_ro_fpago,   @w_ro_tipo_rubro, @w_co_categoria,  @w_co_codigo,
         @w_ar_estado_cuota
   
--   while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin
      select @w_monto_sobrante = @w_ar_monto_pago
      
      select @w_va = @w_monto_aplicado + @w_ar_monto_pago
      
      if  @w_va > @i_monto_renovado
      begin
         select @w_diff = @w_va - @i_monto_renovado
         select @w_monto_sobrante =   @w_ar_monto_pago -  @w_diff
      end
      
      -- CICLO POR LOS DIVIDENDOS Y CONCEPTOS DESDE EL MAS VENCIDO AL VIGENTE
      declare
         cur_dividendos cursor
         for select am_dividendo, am_estado, am_cuota, am_acumulado, am_pagado, am_secuencia
             from   ca_dividendo, ca_rubro_op, ca_concepto, ca_amortizacion
             where  di_operacion = @w_op_operacion_ant
             and    di_estado    = @w_ar_estado_cuota
             
             and    ro_operacion = @w_op_operacion_ant
             and    ro_concepto  = @w_ar_concepto
             and    co_concepto  = @w_ar_concepto
             
             and    am_operacion = @w_op_operacion_ant
             and   (
                    (    am_dividendo = di_dividendo + charindex (ro_fpago, 'A')
                     and not(co_categoria in ('S', 'A') and am_secuencia > 1)
                    )
                    or (co_categoria in ('S', 'A') and am_secuencia > 1 and am_dividendo = di_dividendo)
                   )
             and    am_concepto  = @w_ar_concepto
             and    (am_estado    = @w_ar_estado or am_concepto = 'CAP')
             order by am_dividendo, am_concepto, am_secuencia
         for read only
      
      open cur_dividendos
      
      fetch cur_dividendos
      into  @w_am_dividendo, @w_am_estado, @w_am_cuota, @w_am_acumulado, @w_am_pagado, @w_am_secuencia
      
      while @@fetch_status = 0
      begin
         -- VERIFICAR SI ES PAGABLE
         if   @w_am_acumulado > 0
         and  @w_am_pagado < @w_am_acumulado
         begin
            -- PAGAR

            if @w_monto_aplicado < @i_monto_renovado
            begin
               exec @w_error = sp_aplica_rubro_sec
                    @s_date                 = @s_date,
                    @i_operacion            = @w_op_operacion_ant,
                    @i_op_estado            = @w_op_estado_ant,
                    @i_secuencial_pag       = @w_secuencial_pag,
                    @i_dividendo            = @w_am_dividendo,
                    @i_concepto             = @w_ar_concepto,
                    @i_secuencia_am         = @w_am_secuencia,
                    @i_monto_a_aplicar      = @w_monto_sobrante,
                    @i_ro_tipo_rubro        = @w_ro_tipo_rubro,
                    @i_ro_fpago             = @w_ro_fpago,
                    @i_co_categoria         = @w_co_categoria,
                    @i_cotizacion           = @w_cotizacion,
                    @i_aplicar_anticipado   = 'N',
                    @i_num_dec              = @w_num_dec_op,
                    @i_moneda               = @w_op_moneda_ant,
                    @i_codvalor_cto         = @w_co_codigo,
                    @o_sobrante             = @w_monto_sobrante     OUT,
                    @o_monto_aplicado       = @w_monto_aplicado     OUT,
                    @o_monto_aplicado_cap   = @w_monto_aplicado_cap OUT
               
               if @w_error != 0
               begin
                  goto SALIDA_ERROR
               end
            end
            
         end
        
         fetch cur_dividendos
         into  @w_am_dividendo, @w_am_estado, @w_am_cuota, @w_am_acumulado, @w_am_pagado, @w_am_secuencia
      end
      
      close cur_dividendos
      deallocate cur_dividendos
      
      update ca_abono_renovacion
      set    ar_estado_reg   = 'P'
      where  ar_tramite_ren  = @i_tramite_ren
      and    ar_concepto     = @w_ar_concepto
      and    ar_estado       = @w_ar_estado
      and    ar_estado_cuota = @w_ar_estado_cuota
      
      fetch cur_secuencias
      into  @w_ar_usuario, @w_ar_concepto,   @w_ar_estado,     @w_ar_monto_pago,
            @w_ro_fpago,   @w_ro_tipo_rubro, @w_co_categoria,  @w_co_codigo,
            @w_ar_estado_cuota
   end
   
   close cur_secuencias
   deallocate cur_secuencias
   

   --- REVISAR EL ESTADO (SALDO) DE LA OBLIGACION
   select @w_cancela_dividendo = 'S'
   
   ---REVISION DE LA OPERACION PARA VER SI QUEDA CANCELADA
   select @w_saldo_cap = isnull(sum(am_cuota - am_pagado),0)
   from  ca_amortizacion
   where am_operacion = @w_op_operacion_ant
   and   am_concepto = 'CAP'

   if @w_saldo_cap > 0 and @w_div_vigente > 0
   begin
      declare
         cur_dividendo cursor
         for select di_dividendo, di_estado
             from   ca_dividendo
             where  di_operacion = @w_op_operacion_ant
             and    di_estado in (0, 1, 2)
             and    di_dividendo < @w_div_vigente
             order  by di_dividendo
         for read only
      
   end
   ELSE
   begin
      declare
         cur_dividendo cursor
         for select di_dividendo, di_estado
             from   ca_dividendo
             where  di_operacion = @w_op_operacion_ant
             and    di_estado in (0, 1, 2)
             order  by di_dividendo
         for read only
   end
   
   open cur_dividendo
   
   fetch cur_dividendo
   into  @w_di_dividendo, @w_di_estado
   
   while @@fetch_status = 0 and @w_cancela_dividendo = 'S'
   begin

      exec @w_error = sp_saldo_operacion
           @i_operacion = @w_op_operacion_ant,
           @i_dividendo = @w_di_dividendo
      
      if @w_error != 0
      begin
         close cur_dividendo
         deallocate cur_dividendo
         goto SALIDA_ERROR
      end
      
      select @w_saldo_div = isnull(sum(sot_saldo_acumulado), 0)
      from   ca_saldo_operacion_tmp
      where  sot_operacion = @w_op_operacion_ant
      
      if @w_saldo_div <= @w_vlr_despreciable
      begin
         update ca_amortizacion
         set    am_estado = 3
         from   ca_rubro_op
         where  ro_operacion = @w_op_operacion_ant
         and    am_operacion = @w_op_operacion_ant
         and    am_dividendo = @w_di_dividendo + charindex (ro_fpago, 'A')
         and    am_concepto  = ro_concepto
         
         update ca_dividendo
         set    di_estado    = 3,
                di_fecha_can = @w_op_fecha_ult_proceso_ant
         where  di_operacion = @w_op_operacion_ant
         and    di_dividendo = @w_di_dividendo
         
         update ca_dividendo
         set    di_estado = 1
         where  di_operacion = @w_op_operacion_ant
         and    di_dividendo = @w_di_dividendo + 1
         and    di_estado    = 0
      end
      ELSE
      begin
         select @w_cancela_dividendo = 'N'
      end
      
      fetch cur_dividendo
      into  @w_di_dividendo, @w_di_estado
   end
   
   close cur_dividendo
   deallocate cur_dividendo
  
   if exists(select 1
             from   ca_dividendo
             where  di_operacion = @w_op_operacion_ant
             and    di_estado in (1, 2, 0))
           select @w_cancela_dividendo = @w_cancela_dividendo
   ELSE
   begin
      
      update ca_operacion
      set    op_estado = 3,
             op_fecha_ult_mov = @s_date
      where  op_operacion = @w_op_operacion_ant

      insert into ca_activas_canceladas
             (can_operacion,        can_fecha_can,     can_usuario,       can_tipo,   
              can_fecha_hora)
      values (@w_op_operacion_ant,  @s_date,           @s_user,           @w_op_tipo_ant,    
              getdate() )
         
   end
   
   -- INTERFAZ CON CREDITO Y GARANTIAS
   if (@w_monto_aplicado_cap > 0 and @w_op_tramite_ant is not null)
   begin
      select @w_monto_aplicado_cap_mn = round(@w_monto_aplicado_cap * @w_cotizacion, @w_num_dec_mn)
      
      if @w_op_tipo_ant not in ('D','G','R')
      begin
         
         declare
            @w_cu_estado            char(1),
            @w_cu_agotada           char(1),
            @w_cu_abierta_cerrada   char(1),
            @w_cu_tipo_gar          varchar(64),
            @w_cu_contabilizar      char(1)
         
         select @w_cu_estado          = cu_estado,
                @w_cu_agotada         = cu_agotada,
                @w_cu_abierta_cerrada = cu_abierta_cerrada,
                @w_cu_tipo_gar        = cu_tipo
         from   cob_custodia..cu_custodia,
                cob_credito..cr_gar_propuesta
         where  gp_garantia = cu_codigo_externo 
         and    cu_agotada = 'S'
         and    gp_tramite = @w_op_tramite_ant
         
         if @@rowcount <> 0
         select @w_tiene_garantia = 'S'

         
         if @w_tiene_garantia = 'S'
         begin
                 select @w_cu_contabilizar = tc_contabilizar
                 from   cob_custodia..cu_tipo_custodia
                 where  tc_tipo = @w_cu_tipo_gar
                 
                 if (@w_cu_estado = 'V'
                    and @w_cu_agotada = 'S'
                    and @w_cu_abierta_cerrada = 'C'
                    and @w_cu_contabilizar = 'S')
                 begin

                 select @w_capitaliza = 'N'
                 if exists (select 1 from ca_acciones
                            where ac_operacion = @w_op_operacion_ant)
                            select @w_capitaliza = 'S'    ---NR 433
              
                    exec @w_error = cob_custodia..sp_agotada 
                         @s_ssn             = @s_ssn,
                         @s_date            = @s_date,
                         @s_user            = @s_user,
                         @s_term            = @s_term,
                         @s_ofi             = @s_ofi,
                         @t_trn             = 19911,
                         @t_debug           = 'N',
                         @t_file            = NULL,
                         @t_from            = NULL,
                         @i_operacion       = 'P',                       --- PAGO  'R' REVERSA DE PAGO
                         @i_monto           = @w_monto_aplicado_cap,     --- MONTO DEL PAGO
                         @i_monto_mn        = @w_monto_aplicado_cap_mn,  ---MONTO MONEDA NACIONAL
                         @i_moneda          = @w_op_moneda_ant,          --- MONEDA DEL PAGO
                         @i_saldo_cap_gar   = @w_saldo_cap_op_ant,       ---ANTES DE HACER EL PAGO
                         @i_tramite         = @w_op_tramite_ant,         --- TRAMITE 
                         @i_capitaliza      = @w_capitaliza              --- NR 433       
            
                    if @@error != 0 
                    begin
                       select @w_error = 720308
                       goto SALIDA_ERROR
                    end
            
                    if @w_error != 0
                    begin
                       goto SALIDA_ERROR
                    end
              end  ---@w_tiene_garantia 
              
                    
         end
      end -- Fin tipo de documento
      
      --ACTUALIZAR CUPO DE CREDITO
      
      if @w_op_lin_credito_ant is not null 
         select @w_modo_utilizacion = 0
      else
         select @w_modo_utilizacion = 1
      
      if @w_op_tipo_ant = 'R'           -- REDESCUENTO
         select @w_naturaleza = 'P'  -- PASIVA
      else
         select @w_naturaleza = 'A'  -- ACTIVA
      
      if @w_op_moneda_ant != 0
         select @w_monto_aplicado_cap =  @w_monto_aplicado_cap_mn
      
      if @w_op_lin_credito_ant is not null
      begin
         exec @w_error = cob_credito..sp_utilizacion
              @s_ofi         = @s_ofi,
              @s_sesn        = @s_sesn,
              @s_user        = @s_user,
              @s_term        = @s_term,
              @s_date        = @s_date,
              @t_trn         = 21888,
              @i_linea_banco = @w_op_lin_credito_ant,
              @i_producto    = 'CCA',
              @i_toperacion  = @w_op_toperacion_ant,
              @i_tipo        = 'R', -- (R)Pagos
              @i_moneda      = @w_op_moneda_ant,
              @i_monto       = @w_monto_aplicado_cap,
              @i_opcion      = @w_naturaleza,  -- LuisG
              @i_tramite     = @w_op_tramite_ant,  -- XSA
              @i_secuencial  = @w_secuencial_pag,  --XSA
              @i_opecca      = @w_op_operacion_ant,
              @i_cliente     = @w_op_cliente_ant,
              @i_fecha_valor = @s_date,
              @i_modo        = @w_modo_utilizacion,
              @i_numoper_cex = @w_op_numero_comex_ant ---EPB:oct-09-2001
         
         if @w_error != 0 
            return @w_error
      end
      
      if @i_en_linea = 'N'
         select @w_bandera_be = 'S'
      else
         select @w_bandera_be = 'N'
      
      exec @w_error = cob_custodia..sp_activar_garantia
           @i_opcion         = 'C',
           @i_tramite        = @w_op_tramite_ant,
           @i_reconocimiento = 'N',
           @i_modo           = 2,
           @i_operacion      = 'I',
           @s_date           = @s_date,
           @s_user           = @s_user,
           @s_term           = @s_term,
           @s_ofi            = @s_ofi,
           @i_bandera_be     = @w_bandera_be
      
      if @@error != 0 
      begin
         select @w_error = 720309
         goto SALIDA_ERROR
      end
      
      if @w_error != 0
      begin
         goto SALIDA_ERROR
      end 
   end
end
return 0

SALIDA_ERROR:
   return @w_error
go
