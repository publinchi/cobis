/************************************************************************/
/*      Archivo:                desempar.sp                             */
/*      Stored procedure:       sp_liquidacion_parcial                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           R Garces   		                */
/*      Fecha de escritura:     Jul. 1997                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Generacion de un desembolso parcial para la operacion indicada  */
/************************************************************************/
/*      FECHA          AUTOR          CAMBIO                            */
/*      ABR-2006    Elcira Pelaez      NR-296                           */
/*      NOV-2020    EMP-JJEC           Desembolsos Parciales            */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_liquidacion_parcial')
	drop proc sp_liquidacion_parcial
go

create proc sp_liquidacion_parcial
   @s_culture             varchar(10)  = 'NEUTRAL',  --Internacionalizacion
   @s_sesn                int          = null,
   @s_user                login        = null,
   @s_date                datetime     = null,
   @s_ofi                 int          = null,
   @s_term                varchar (30) = null,
   ---@i_opcion              tinyint,       
   @i_banco               cuenta       = null,
   @i_monto_des           money,
   @i_num_dec             smallint     = 0,
   @i_en_linea            char(1)      = 'S',
   @i_fecha_proceso       datetime,
   @i_concepto_cap        catalogo     = 'CAP',
   @i_operacionca         int,
   @i_sec_trn             int          = null
                                                                                                                                                                                                                                                           
as
                                                                                                                                                                                                                                                            
declare @w_sp_name              descripcion,
	@w_error                int,
        @w_tipo_producto        catalogo,
        @w_saldo                money,
        @w_di_dividendo         int,
        @w_cap                  money,
        @w_saldo_total          money,
        @w_valor_cuota          money,
        @w_max_cuota            int,
        @w_cuotas               int,
        @w_concepto_cap         catalogo,
        @w_capital_total        money,
        @w_pagado_vigente       money,
        @w_diff                 money,
        @w_total_distribuido    money,
        @w_plazo_restante       int,
        @w_dividendo_vig        int,
        @w_fecha_ini_div        datetime,
        @w_fecha_ven_div        datetime,
        @w_plazo_div_vig        int,
        @w_dias_desembolso      int,
        @w_fecha_inicio         datetime,
        @w_plazo                int,
        @w_return               int,
        @w_banco_tmp            cuenta,
        @w_nrows                int, 
        @w_sec_previo           int,
        @w_dividendo_act        int,
        @w_operacion_tmp        int,
        @w_dit_fecha_ven        datetime,
        @w_dit_dividendo        int,
        @w_moneda               smallint,
        @w_toperacion           catalogo,
        @w_rubro_previo         catalogo,
        @w_rot_operacion        int,
        @w_rot_concepto         catalogo,
        @w_rot_valor            money,
        @w_amt_concepto         catalogo,
        @w_amt_cuota            money,
        @w_amt_acumulado        money,
        @w_tipo_amortizacion    catalogo,
        @w_rot_fpago            char(1),
        @w_rot_tipo_rubro       char(1),
        @w_dm_cotizacion_mop    float,
        @w_dm_tcotizacion_mop   char(1),
        @w_dm_monto_mn          money,
        @w_dm_monto_mop         money,
        @w_codvalor             int,
        @w_rot_valor_mn          money,
        @w_num_dec              tinyint,
        @w_num_dec_mn           tinyint,
        @w_moneda_n             tinyint,
        @w_afectacion           char(1),
        @w_total_rot_valor      money,
        @w_banco                cuenta,
        @w_producto             catalogo,
        @w_cuenta               cuenta,
        @w_fecha_ult_proceso    datetime,
        @w_est_cancelado        tinyint

---- CARGAR VALORES INICIALES 
select @w_sp_name = 'sp_liquidacion_parcial'
                                                                                                                                                                                                                                                              
begin

   /* ESTADOS DE CARTERA */
   exec @w_error = sp_estados_cca
   @o_est_cancelado  = @w_est_cancelado out

   -- MANEJO DE DECIMALES
   exec @w_return = sp_decimales
        @i_moneda       = @w_moneda,
        @o_decimales    = @w_num_dec out,
        @o_mon_nacional = @w_moneda_n out,
        @o_dec_nacional = @w_num_dec_mn out
   
   if @w_return <> 0
      return @w_return

   select @w_dias_desembolso = pa_smallint
   from   cobis..cl_parametro
   where  pa_nemonico = 'DDP'
   and    pa_producto = 'CCA'

   select @w_concepto_cap  = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'CAP'
                                                                                                                                                                                                                                 
   if @i_monto_des <= 0
   begin
      PRINT 'desempar.sp el valor de desembolso parcial  es 0'
      return 0
   end

   set transaction isolation level read uncommitted
                                                                                                                                                                                                           
   --En esta opcion se actualiza la tabla de amortizacion para cualquier desembolso
   --parcial en el mismo tiempo inicialmente pactado
     
   select @w_banco     = op_banco,
          @w_moneda    = op_moneda,
          @w_fecha_ult_proceso = op_fecha_ult_proceso
   from   ca_operacion
   where  op_operacion = @i_operacionca
     and  op_estado in (1,2)
     
   if @@rowcount = 0
      return 701010 -- Operación no vigente, vencida , cancelada o castigada   

   -- Validar que la operacion se encuentre al dia
/*   if @w_fecha_ult_proceso <> @i_fecha_proceso
      return 724510 */

   -- ACTUALIZAR EL MONTO DEL PRESTAMO
   update ca_operacion
   set op_monto      = op_monto + @i_monto_des
   where op_operacion = @i_operacionca
   
   if @@error <> 0 
      return 711027 

   -- ACTUALIZAR EL VALOR DE BASE DE CALCULO PARA LOS RUBROS TIPO INTERES Y CALCULADOS      
   update ca_rubro_op
   set ro_base_calculo = ro_base_calculo + @i_monto_des
   where ro_operacion  = @i_operacionca
     and ro_tipo_rubro in ('Q','I','C')
     and isnull(ro_base_calculo,0) > 0

   if @@error <> 0 
      return 711028

   if @w_tipo_amortizacion <> 'MANUAL'
   begin

      -- TEMPORAL DESEMBOLSO PARCIAL
      select @w_banco_tmp     = opt_banco,
             @w_operacion_tmp = opt_operacion,
             @w_tipo_amortizacion = opt_tipo_amortizacion 
      from ca_operacion_tmp 
      where opt_anterior = @i_banco
        and opt_monto    = @i_monto_des
        
        if @@rowcount = 0
           return 701050

      -- CURSOR PARA ACTUALIZAR VALORES DE LOS RUBROS GENERADOS
      select @w_nrows = 1, 
             @w_rubro_previo = ''
      
      while (@w_nrows > 0) 
      begin 
         select top 1
            @w_rot_operacion            = rot_operacion,
            @w_rot_concepto             = rot_concepto,
            @w_rot_valor                = rot_valor,
            @w_rubro_previo             = rot_concepto,
            @w_rot_fpago                = rot_fpago,
            @w_rot_tipo_rubro           = rot_tipo_rubro
            from ca_rubro_op_tmp
            where rot_operacion = @w_operacion_tmp
              and rot_concepto  > @w_rubro_previo
            order by rot_concepto
      
         if @@rowcount = 0 break 
         
         if exists (select 1 from ca_rubro_op where ro_operacion = @i_operacionca and ro_concepto = @w_rot_concepto)
         begin
            -- ACTUALIZAR CA_RUBRO_OP   
            update ca_rubro_op
               set ro_valor = ro_valor + isnull(@w_rot_valor,0)
             where ro_operacion  = @i_operacionca
               and ro_concepto   = @w_rot_concepto
            
            if @@error <> 0 
               return 711028 --705071
         end
         else
         begin
            insert into ca_rubro_op
	    (ro_operacion,		ro_concepto,		ro_tipo_rubro,		ro_fpago,	ro_prioridad,           
	     ro_paga_mora,		ro_provisiona,		ro_signo,		ro_factor,	ro_referencial,         
	     ro_signo_reajuste,		ro_factor_reajuste,	ro_referencial_reajuste,ro_valor,	ro_porcentaje,          
	     ro_porcentaje_aux,		ro_gracia,		ro_concepto_asociado,	ro_redescuento,	ro_intermediacion,      
	     ro_principal,		ro_porcentaje_efa,	ro_garantia,		ro_tipo_puntos,	ro_saldo_op,            
	     ro_saldo_por_desem,	ro_base_calculo,	ro_num_dec,		ro_limite,	ro_iva_siempre,         
	     ro_monto_aprobado,		ro_porcentaje_cobrar,	ro_tipo_garantia,	ro_nro_garantia,ro_porcentaje_cobertura,
	     ro_valor_garantia,		ro_tperiodo,		ro_periodo,		ro_tabla,	ro_saldo_insoluto,      
	     ro_calcular_devolucion)
             select 
             @i_operacionca,		rot_concepto,		rot_tipo_rubro,		rot_fpago,	rot_prioridad,
             rot_paga_mora,		rot_provisiona,		rot_signo,		rot_factor,	rot_referencial,         
             rot_signo_reajuste,	rot_factor_reajuste,	rot_referencial_reajuste,rot_valor,	rot_porcentaje,          
             rot_porcentaje_aux,	rot_gracia,		rot_concepto_asociado,	rot_redescuento,	rot_intermediacion,      
             rot_principal,		rot_porcentaje_efa,	rot_garantia,		rot_tipo_puntos,	rot_saldo_op,            
             rot_saldo_por_desem,	rot_base_calculo,	rot_num_dec,		rot_limite,		rot_iva_siempre,         
	     rot_monto_aprobado,	rot_porcentaje_cobrar,	rot_tipo_garantia,	rot_nro_garantia,	rot_porcentaje_cobertura,
	     rot_valor_garantia,	rot_tperiodo,		rot_periodo,		rot_tabla,		rot_saldo_insoluto,      
	     rot_calcular_devolucion
	     from ca_rubro_op_tmp
	     where rot_operacion = @w_operacion_tmp
	       and rot_concepto  = @w_rot_concepto
	      
            if @@error <> 0 
               return 711021
         end		
      end -- While rubros
      
      -- CURSOR DE DIVIDENDOS TABLA TMP
      select @w_nrows = 1, 
             @w_sec_previo = 0
      
      while (@w_nrows > 0) 
      begin 
         select top 1
            @w_dit_dividendo  = dit_dividendo,
            @w_dit_fecha_ven  = dit_fecha_ven,               
            @w_sec_previo     = dit_dividendo
         from ca_dividendo_tmp
         where dit_operacion = @w_operacion_tmp
           and dit_dividendo > @w_sec_previo
         order by dit_dividendo
              
         if @@rowcount = 0 break 
      
         -- ACTUALIZAR CA_AMORTIZACION EN REGISTROS EXISTENTES
         select @w_dividendo_act = di_dividendo
         from ca_dividendo
         where di_operacion = @i_operacionca
           and di_fecha_ven = @w_dit_fecha_ven
      
         if isnull(@w_dividendo_act,0) > 0
         begin
      
            -- CURSOR DE AMORTIZACION TABLA TMP
            select @w_nrows = 1, 
                   @w_rubro_previo = ''
            
            while (@w_nrows > 0) 
            begin 
               select top 1
                  @w_amt_concepto  = amt_concepto,
                  @w_amt_cuota     = amt_cuota,
                  @w_amt_acumulado = amt_acumulado,
                  @w_rubro_previo  = amt_concepto
               from ca_amortizacion_tmp
               where amt_operacion = @w_operacion_tmp
                 and amt_dividendo = @w_dit_dividendo
                 and amt_concepto  > @w_rubro_previo
               order by amt_concepto
                    
               if @@rowcount = 0 break 
            
               if exists (select 1 from ca_amortizacion where am_operacion = @i_operacionca and am_dividendo = @w_dividendo_act and am_concepto = @w_amt_concepto)
               begin
                  update ca_amortizacion
                     set am_cuota = am_cuota + @w_amt_cuota,
                         am_acumulado = am_acumulado + @w_amt_acumulado
                   where am_operacion  = @i_operacionca
                     and am_dividendo  = @w_dividendo_act
                     and am_concepto   = @w_amt_concepto
                  
                  if @@error <> 0 
                     return 705072
               end
               else
               begin
                  -- INSERTA RUBRO NUEVO EN AMORTIZACION
                  insert into ca_amortizacion
                  select @i_operacionca, 
                         @w_dividendo_act,
                         amt_concepto,
                         amt_estado,
                         amt_periodo,
                         amt_cuota,
                         amt_gracia,
                         amt_pagado,
                         amt_acumulado,
                         amt_secuencia
                   from ca_amortizacion_tmp
                   where amt_operacion = @w_operacion_tmp
                     and amt_dividendo = @w_dit_dividendo
                     and amt_concepto  = @w_amt_concepto
            
                  if @@error <> 0 
                     return 703113
               end		
            end -- WHILE AMORTIZACION   
         end -- DIVIDENDO ACTUAL
      end -- WHILE DIVIDENDO
   end -- FIN DE TIPO TABLA   
   else -- MANUAL
   begin
     
     select @w_cuotas = count(1)
     from ca_dividendo
     where  di_operacion = @i_operacionca
     and    di_estado in (0, 1)
     
     select @w_max_cuota = max(di_dividendo)
     from ca_dividendo
     where  di_operacion = @i_operacionca
     
     select @w_valor_cuota = round(@i_monto_des / @w_cuotas, @i_num_dec)
    
     update ca_amortizacion
     set am_cuota = am_cuota + @w_valor_cuota,
         am_acumulado = am_acumulado + @w_valor_cuota
     from ca_amortizacion,
         ca_dividendo
     where am_operacion = @i_operacionca
     and   di_operacion = @i_operacionca
     and   am_dividendo = di_dividendo
     and   am_concepto =  @w_concepto_cap
     and   di_estado in (1,0)

     if @@error !=0  or @@rowcount = 0
        return 711030
 
      --Validar redondeo por diferencia 
      select @w_total_distribuido = @w_valor_cuota * @w_cuotas
      select @w_diff = round(@w_total_distribuido -@i_monto_des,@i_num_dec)

      if @w_diff <> 0
      begin
         ---PRINT 'desempar.sp valor cuota %1! @w_diff con utilizacion %2!',@w_valor_cuota,@w_diff
         update ca_amortizacion
         set am_cuota = am_cuota - @w_diff,
             am_acumulado = am_acumulado - @w_diff
         from ca_amortizacion
         where am_operacion = @i_operacionca
         and   am_concepto =  @w_concepto_cap
         and am_dividendo = @w_max_cuota

        if @@error !=0  or @@rowcount = 0
           return 711030
         
      end
   end	-- END MANUAL
   
   -- RECALCULO DE RUBROS SOBRE VALOR INSOLUTO
   if exists (select 1 from ca_amortizacion,ca_rubro_op
              where am_operacion = @i_operacionca
              and am_operacion = ro_operacion
              and am_concepto = ro_concepto
              and ro_saldo_insoluto = 'S'
              and am_estado != 3)
   begin           
     exec @w_error = sp_recalculo_seguros_sinsol
          @i_operacion = @i_operacionca
                                                                                                                                                                                                                                                           
     if @w_error != 0
         return @w_error
   end   

end
                                                                                                                                                                                                                                                              
return 0                                                                                                                                                                                                                                                        

go
