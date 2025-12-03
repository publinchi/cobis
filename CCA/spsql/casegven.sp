/************************************************************************/
/*      Nombre Fisico:          casegven.sp                             */
/*      Nombre Logico:          sp_seguro_op_vencidas                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     Ene. 2004                               */
/************************************************************************/
/*                              IMPORTANTE                              */
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
/*                              PROPOSITO                               */
/*      Recalculo de seguros para obligaciones vencidas                 */
/*      Este sp se ejecuta desde el sp_batch1                           */
/*                              PROPOSITO                               */
/*      FECHA          AUTOR             CAMBIO                         */
/*      junio-28-2005  ElciraPelaez      Acumular el seguro vencido en  */
/*                                       el secuencial 2                */
/*      mar 2006       fabian quintero   defecto 6109                   */
/*      Jun-05-2007    John Jairo Rendon Optimizacion                   */
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_seguro_op_vencidas')
   drop proc sp_seguro_op_vencidas
go

create proc  sp_seguro_op_vencidas
   @s_user                login,
   @s_term                varchar(30),
   @s_date                datetime,
   @s_ofi                 smallint,
   @i_en_linea            char(1),
   @i_toperacion          catalogo,
   @i_banco               cuenta,
   @i_operacionca         int,
   @i_moneda              smallint,
   @i_oficina             smallint,
   @i_fecha_proceso       datetime,
   @i_dias_interes        smallint,
   @i_tipo                char(1),
   @i_gerente             smallint,
   @i_cotizacion          float   = null,
   @i_moneda_nacional     tinyint  = 0,
   @i_num_dec             smallint = 0,
   @i_fecultpro           datetime = null,
   @i_gar_admisible       char(1)  = null,
   @i_reestructuracion    char(1)  = null,
   @i_calificacion        catalogo  = null,
   @i_moneda_uvr          tinyint  = 2,
   @i_fecha_prox_segven   datetime out
as
declare
   @w_error                   int,
   @w_ro_tipo_garantia        varchar(64),
   @w_ro_fpago                char(1),
   
   @w_nro_garantia            char(64),
   @w_seg_concepto            catalogo,            
   @w_porcentaje              float,   
   @w_categoria               char(10),
   @w_valor_base              money,
   @w_tasa_nom                float,
   @w_tabla_tasa              char(30),
   @w_fpago                   char(1),
   
   @w_maximo_dividendo        smallint,
   @w_estado_concepto         int,
   @w_secuencial_prv          int,
   
   @w_seg_max_sec             tinyint,
   @w_seg_codvalor            int,
   @w_seg_valor               money, -- SEGURO DEL PERIODO
   @w_seg_acumulado           money, -- SEGURO ACUMULADO
   @w_seg_acumulado_mn        float,
   @w_seguro_dia              float, -- IVA DE UN DIA
   @w_seguro_dia_mn           float,
   
   @w_iva_concepto            catalogo,
   @w_iva_porcentaje          float,
   @w_iva_max_sec             int,
   @w_iva_valor               float, -- VALOR SE IVA DEL PERIODO
   @w_iva_acumulado           float, -- IVA ACUMULADO
   @w_iva_acumulado_mn        float,
   @w_iva_codvalor            int,
   @w_iva_valor_dia           float, -- IVA DE UN DIA
   @w_iva_valor_dia_mn        float,
   
   
   @w_ejecutar                char(1),
   @w_saldo_insoluto          char(1),
   @w_fecha_anterior          datetime,
   
   @w_dias_cuota              int,
   @w_cotizacion_hoy          float,
   @w_cotizacion_manana       float,
   @w_pesos                   float,
   @w_num_dec_mn              smallint,
   @w_update                  char(1),
   @w_vlr_despreciable        float,
   @w_debe                    float
   
return 0

begin
  --EPB:21NOV2006 PARA QUE NO EJECUTE SI HAY ERROR   DE PAGO EN CAPITAL
  select @w_vlr_despreciable = 0
  select @w_vlr_despreciable = 1.0 / power(10,  isnull(@i_num_dec, 4))

  select @w_debe = isnull(sum(am_acumulado - am_pagado),0)
  from ca_amortizacion with (nolock)
  where am_operacion = @i_operacionca
  and am_concepto = 'CAP'
  and (am_acumulado - am_pagado ) > 0
  and am_estado = 3

  if @w_debe >  @w_vlr_despreciable
     return 711061
  --EPB:21NOV2006 PARA QUE NO EJECUTE SI HAY ERROR   DE PAGO EN CAPITAL
   
   if @i_fecha_proceso = 'mar 1 2004' and @i_fecha_prox_segven < 'mar 1 2004' -- FQ AUTOCORRECCION DE DATOS MIGRADOS
   begin
      update ca_operacion
      set    op_fecha_prox_segven = dateadd(dd, @i_dias_interes * ceiling(datediff(dd, op_fecha_fin, op_fecha_ult_proceso) * 1.0 / @i_dias_interes), op_fecha_fin)
      where  op_operacion = @i_operacionca
      
      select @i_fecha_prox_segven = op_fecha_prox_segven
      from   ca_operacion with (nolock)
      where  op_operacion = @i_operacionca
   end
   
   select @w_cotizacion_hoy = @i_cotizacion
   
   select @w_fecha_anterior = dateadd(dd, 1, @i_fecha_proceso)
   
   if @i_moneda = 0
      select @w_cotizacion_manana = 1,
             @w_num_dec_mn        = 0
   else
   begin
      select @w_num_dec_mn = 2
      
      exec sp_buscar_cotizacion
           @i_moneda     = @i_moneda,
           @i_fecha      = @w_fecha_anterior,
           @o_cotizacion = @w_cotizacion_manana output
   end
   
   select @w_cotizacion_manana = @w_cotizacion_hoy
   
   select @w_update = 'N'
   
   if @i_dias_interes = 1
      select @w_update = 'S'
   
   select @w_ejecutar  = 'S'
   
   select @w_dias_cuota = @i_dias_interes
     
   select @w_maximo_dividendo = 0
   
   select @w_maximo_dividendo = max(di_dividendo)
   from   ca_dividendo with (nolock)
   where  di_operacion = @i_operacionca
   
   if exists (select 1
              from ca_rubro_op with (nolock),ca_concepto with (nolock)
              where ro_operacion = @i_operacionca
              and   ro_concepto  = co_concepto
              and   co_categoria = 'S' )
   begin ---EXISTE SEGURO PARA CALCULAR AL VENCIMIENTO
   ---------------------------------------------
      ---CURSOR POR LOS RUBROS DEL TRAMITE  TIPO S= SEGUROS
      declare rubros cursor
         for select ro_concepto,          ro_porcentaje,
                    ro_saldo_insoluto,
                    co_categoria,         ro_tabla,
                    ro_fpago,             ro_valor,
                    ro_tipo_garantia,     ro_garantia
             from   ca_rubro_op with (nolock), ca_concepto with (nolock)
             where  ro_operacion      = @i_operacionca
             and    ro_concepto       = co_concepto
             and    co_categoria      = 'S' --SEGUROS
             order  by ro_tipo_rubro desc   --para que calcule primero los rubros tipo seguro, y luego el iva de los seguros
             for read only
      
      open rubros
      
      fetch rubros
      into  @w_seg_concepto,      @w_porcentaje,
            @w_saldo_insoluto,
            @w_categoria,         @w_tabla_tasa,
            @w_fpago,             @w_seg_valor,
            @w_ro_tipo_garantia,  @w_seg_acumulado_mn
      
      --while @@fetch_status not in (-1,0)
      while @@fetch_status = 0
      begin
         select @w_seg_max_sec = isnull(max(am_secuencia),0)
         from   ca_amortizacion with (nolock)
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_maximo_dividendo
         and    am_concepto  = @w_seg_concepto
         
         if @w_seg_max_sec = 0
         begin
             ---SE RETORN 0 POR QUE LA TABLA DE AMORTIZACION NO TIENE EL RUBRO
             close rubros
             deallocate rubros
             return 0  
         end
         
         -- DETERMINAR SI TIENE IVA
         select @w_iva_concepto     = ro_concepto,
                @w_iva_porcentaje   = ro_porcentaje,
                @w_iva_valor        = ro_valor,
                @w_iva_acumulado_mn = ro_garantia
         from   ca_rubro_op with (nolock)
         where  ro_operacion = @i_operacionca
         and    ro_concepto_asociado = @w_seg_concepto
         
         if @@rowcount = 0
         begin
            select @w_iva_concepto   = null,
                   @w_iva_valor      = 0,
                   @w_iva_max_sec    = null,
                   @w_iva_porcentaje = 0
         end
         ELSE
         begin
            select @w_iva_max_sec = max(am_secuencia)
            from ca_amortizacion with (nolock)
            where am_operacion = @i_operacionca
            and   am_dividendo = @w_maximo_dividendo 
            and   am_concepto  = @w_iva_concepto
         end
         
         ---SEGUROS
         if  @i_fecha_proceso  = @i_fecha_prox_segven -- RECALCULAR
         begin
            select @w_seg_acumulado = 0,
                   @w_seg_acumulado_mn = 0,
                   @w_iva_acumulado = 0,
                   @w_iva_acumulado_mn = 0
            
            if @i_tipo <> 'V' --CONVENIOS EL VALOR DEL RUBRO ES FIJO
            begin
               select @w_seg_valor = 0  
               
               exec @w_error = sp_rubro_calculado
                    @i_tipo             = 'Q',
                    @i_monto            = 0,
                    @i_concepto         = @w_seg_concepto,
                    @i_operacion        = @i_operacionca,
                    @i_porcentaje       = @w_porcentaje,
                    @i_usar_tmp         = 'N',
                    @i_valor_garantia   = 'S',
                    @i_tipo_garantia    = @w_ro_tipo_garantia,
                    @i_tabla_tasa       = @w_tabla_tasa,
                    @i_categoria_rubro  = 'S',
                    @i_fpago            = @w_fpago,
                    @i_saldo_insoluto   = @w_saldo_insoluto,
                    @o_tasa_calculo     = @w_porcentaje   out,
                    @o_nro_garantia     = @w_nro_garantia out,
                    @o_base_calculo     = @w_valor_base   out,
                    @o_valor_rubro      = @w_seg_valor    out
               
               if @w_error != 0
               begin
                   close rubros
                   deallocate rubros
                   return  @w_error
               end
               
               select @w_seg_valor = round(@w_seg_valor, @i_num_dec)
            end
            
            if @w_seg_valor > 0
            begin
               update cob_cartera..ca_rubro_op
               set    ro_base_calculo   = @w_valor_base,
                      ro_valor          = @w_seg_valor,
                      ro_nro_garantia   = @w_nro_garantia,
                      ro_porcentaje     = @w_porcentaje,
                      ro_porcentaje_aux = @w_porcentaje,
                      ro_garantia       = 0
               where  ro_operacion = @i_operacionca
               and    ro_concepto  = @w_seg_concepto
               
               if @@error != 0
                  return  703115
               
               select @w_estado_concepto = am_estado
               from   ca_amortizacion with (nolock)
               where  am_operacion = @i_operacionca
               and    am_dividendo = @w_maximo_dividendo 
               and    am_concepto  = @w_seg_concepto
               and    am_secuencia = @w_seg_max_sec
               
               -- PREPARA LA ca_amortizacion
               if @w_seg_max_sec = 1
               begin
                  insert into ca_amortizacion
                        (am_operacion,   am_dividendo,      am_concepto,
                         am_estado,      am_periodo,        am_cuota,
                         am_gracia,      am_pagado,         am_acumulado,
                         am_secuencia )
                  values(@i_operacionca,     @w_maximo_dividendo, @w_seg_concepto,
                         2,                  0,                   0,
                         0,                  0,                   0,
                         @w_seg_max_sec + 1)
                  
                  if @@error != 0 
                     return  703079
                  
                  select @w_seg_max_sec = @w_seg_max_sec + 1
               end
               
               if @w_iva_concepto is not null
               begin
                  select @w_iva_valor = round(@w_seg_valor * @w_iva_porcentaje / 100.0, @i_num_dec)
                  
                  if @w_iva_valor > 0
                  begin
                     update cob_cartera..ca_rubro_op
                     set    ro_valor        = @w_iva_valor,
                            ro_base_calculo = @w_seg_valor,
                            ro_garantia     = 0
                     where  ro_operacion = @i_operacionca
                     and    ro_concepto  = @w_iva_concepto
                     
                     if @w_iva_max_sec = 1
                     begin
                        insert into ca_amortizacion
                              (am_operacion,   am_dividendo,      am_concepto,
                               am_estado,      am_periodo,        am_cuota,
                               am_gracia,      am_pagado,         am_acumulado,
                               am_secuencia )
                        values(@i_operacionca,    @w_maximo_dividendo, @w_iva_concepto,
                               2,                 0,                   0,
                               0,                 0,                   0,
                               @w_iva_max_sec + 1)
                        
                        if @@error != 0 
                           return   703079
                        
                        select @w_iva_max_sec = @w_iva_max_sec + 1
                     end
                  end ---Iva
               end
            end ---Valor del seguro > 0
         end -- SI DEBE RECALCULAR
         ELSE 
         begin -- NO HUBO RECALCULO
            select @w_fecha_anterior = dateadd(dd, -@w_dias_cuota, @i_fecha_prox_segven)
            
            if @i_moneda != 0
               exec sp_buscar_cotizacion
                    @i_moneda     = @i_moneda,
                    @i_fecha      = @w_fecha_anterior,
                    @o_cotizacion = @w_cotizacion_hoy output
            else
               select @w_cotizacion_hoy = 1
            
            select @w_seg_max_sec = isnull(max(am_secuencia),0)
            from   ca_amortizacion with (nolock)
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_maximo_dividendo
            and    am_concepto  = @w_seg_concepto
            and    am_secuencia > 1
            
            select @w_seg_acumulado = isnull(sum(am_cuota),0)
            from   ca_amortizacion with (nolock)
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_maximo_dividendo
            and    am_concepto  = @w_seg_concepto
            and    am_secuencia > 1
            
            if @w_seg_max_sec = 0
            begin
               select @w_seg_max_sec = 2
               
               insert into ca_amortizacion
                     (am_operacion,   am_dividendo,      am_concepto,
                      am_estado,      am_periodo,        am_cuota,
                      am_gracia,      am_pagado,         am_acumulado,
                      am_secuencia )
               values(@i_operacionca,     @w_maximo_dividendo, @w_seg_concepto,
                      2,                  0,                   0,
                      0,                  0,                   0,
                      @w_seg_max_sec)
               
               if @@error != 0 
                  return  703079
            end
            
            if @w_iva_concepto is not null
            begin 
               select @w_iva_acumulado = isnull(sum(am_cuota),0)
               from   ca_amortizacion with (nolock)
               where  am_operacion = @i_operacionca
               and    am_dividendo = @w_maximo_dividendo
               and    am_concepto  = @w_iva_concepto
               and    am_secuencia > 1
               
               select @w_iva_max_sec = isnull(max(am_secuencia),0)
               from   ca_amortizacion with (nolock)
               where  am_operacion = @i_operacionca
               and    am_dividendo = @w_maximo_dividendo
               and    am_concepto  = @w_iva_concepto
               and    am_secuencia > 1
               
               if @w_iva_max_sec = 0
               begin
                  select @w_iva_max_sec = 2
                  insert into ca_amortizacion
                        (am_operacion,   am_dividendo,      am_concepto,
                         am_estado,      am_periodo,        am_cuota,
                         am_gracia,      am_pagado,         am_acumulado,
                         am_secuencia )
                  values(@i_operacionca,     @w_maximo_dividendo, @w_iva_concepto,
                         2,                  0,                   0,
                         0,                  0,                   0,
                         @w_iva_max_sec)
                  
                  if @@error != 0 
                     return  703079
               end
            end
         end
         
         select @w_seg_codvalor = co_codigo * 1000+20
         from   ca_concepto with (nolock)
         where  co_concepto = @w_seg_concepto
         
         if @w_iva_concepto is not null
         begin
            select @w_iva_codvalor = co_codigo * 1000+20
            from   ca_concepto with (nolock)
            where  co_concepto = @w_iva_concepto
         end
         
         select @w_seguro_dia = @w_seg_valor / @i_dias_interes
         
         select @w_seguro_dia = round(@w_seguro_dia, @i_num_dec)
         
         if  @i_fecha_proceso  = dateadd(dd, -1 , @i_fecha_prox_segven) -- ULTIMO DIA DE CAUSACION CON VALOR ANTERIOR
         begin
            
            select @w_seguro_dia    = @w_seg_valor - @w_seg_acumulado
            
            if @w_seguro_dia < 0
               select @w_seguro_dia = 0
               
         end
         
         select @w_pesos = @w_seguro_dia * @w_cotizacion_hoy
         select @w_seguro_dia = @w_pesos / @w_cotizacion_manana
         select @w_seguro_dia = round(@w_seguro_dia, @i_num_dec)
         
         select @w_seguro_dia_mn = round((@w_seguro_dia) * @w_cotizacion_manana, @w_num_dec_mn)
         --select @w_seguro_dia_mn =  @w_seguro_dia_mn - @w_seg_acumulado_mn
         
         if @w_seguro_dia_mn < 0
            select @w_seguro_dia_mn = 0
         
         if @w_iva_concepto is not null
         begin
            select @w_iva_valor_dia = @w_iva_valor / @i_dias_interes
            
            select @w_iva_valor_dia = round(@w_iva_valor_dia, @i_num_dec)
            
            if  @i_fecha_proceso  = dateadd(dd, -1 , @i_fecha_prox_segven) -- ULTIMO DIA DE CAUSACION CON VALOR ANTERIOR
            begin
               select @w_iva_valor_dia = @w_iva_valor - @w_iva_acumulado
               
               if @w_iva_valor_dia < 0
                  select @w_iva_valor_dia = 0
            end
            
            if (@w_iva_acumulado + @w_iva_valor_dia) > @w_iva_valor
            begin
               select @w_iva_valor_dia = @w_iva_valor - @w_iva_acumulado
            end
            
            select @w_pesos = @w_iva_valor_dia * @w_cotizacion_hoy
            select @w_iva_valor_dia = @w_pesos / @w_cotizacion_manana
            select @w_iva_valor_dia = round(@w_iva_valor_dia, @i_num_dec)
            
            select @w_iva_valor_dia_mn = round((@w_iva_valor_dia) * @w_cotizacion_manana, @w_num_dec_mn)
            --select @w_iva_valor_dia_mn = @w_iva_valor_dia_mn - @w_iva_acumulado_mn
            
            if @w_iva_valor_dia_mn < 0
               select @w_iva_valor_dia_mn = 0
         end
         
         if @w_seguro_dia > 0-- VALOR DEL SEGURO MAYOR QUE CERO
         begin
            if exists(select 1
                      from   ca_dividendo with (nolock)
                      where  di_operacion = @i_operacionca
                      and    di_dividendo = @w_maximo_dividendo
                      and    di_estado    = 3)
               return 708138 -- NO SE DEBEN ACTUALIZAR CUOTAS CANCELADAS
            
            -- ACUMULAR EN CA_AMORTIZACION SEGURO
            update ca_amortizacion
            set    am_cuota     = am_cuota + @w_seguro_dia,
                   am_acumulado = am_acumulado + @w_seguro_dia,
                   am_estado    = 2
            from   ca_amortizacion with (nolock)
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_maximo_dividendo
            and    am_concepto  = @w_seg_concepto
            and    (am_secuencia = @w_seg_max_sec ) and (am_secuencia > 1) --EPB Para que noactualice el que ya este en estado 3
            
            if @@error != 0
            begin
               return 705050
            end
            
            -- ACUMULAR EN CA_AMORTIZACION IVA
            if @w_iva_valor_dia > 0
            begin
               update ca_amortizacion
               set    am_cuota     = am_cuota + @w_iva_valor_dia,
                      am_acumulado = am_acumulado + @w_iva_valor_dia,
                      am_estado    = 2
               from   ca_amortizacion with (nolock)
               where  am_operacion = @i_operacionca
               and    am_dividendo = @w_maximo_dividendo
               and    am_concepto  = @w_iva_concepto
               and    am_secuencia = @w_iva_max_sec and (am_secuencia > 1) --EPB Para que noactualice el que ya este en estado 3
               
               if @@error != 0
               begin
                  return 705050
               end
            end
            
            -- DETERMINAR SI ACUMULA O INSERTA EN ca_det_trn
            if @w_ejecutar = 'S'
            begin
               select @w_error = 0
               
               exec @w_error = sp_valida_existencia_prv
                    @s_user              = @s_user,
                    @s_term              = @s_term,
                    @s_date              = @s_date,
                    @s_ofi               = @s_ofi ,
                    @i_en_linea          = 'N',
                    @i_operacionca       = @i_operacionca,
                    @i_fecha_proceso     = @i_fecultpro,
                    @i_tr_observacion    = 'CAUSACION DE SEGUROS VENCIDOS',
                    @i_gar_admisible     = @i_gar_admisible,
                    @i_reestructuracion  = @i_reestructuracion,
                    @i_calificacion      = @i_calificacion,
                    @i_toperacion        = @i_toperacion,
                    @i_moneda            = @i_moneda,
                    @i_oficina           = @i_oficina,
                    @i_banco             = @i_banco,
                    @i_gerente           = @i_gerente,
                    @i_moneda_uvr        = @i_moneda_uvr,
                    @o_secuencial        = @w_secuencial_prv  out
               
               if @w_error != 0
               begin
                  return @w_error
               end
               
               select @w_ejecutar = 'N'
            end
            
            if exists(select 1
                      from   ca_det_trn with (nolock)
                      where  dtr_operacion = @i_operacionca
                      and    dtr_secuencial = @w_secuencial_prv
                      and    dtr_codvalor   = @w_seg_codvalor
                      and    dtr_dividendo  = @w_seg_max_sec)
            begin
               update ca_det_trn
               set    dtr_monto      = dtr_monto    + @w_seguro_dia,
                      dtr_monto_mn   = dtr_monto_mn + @w_seguro_dia_mn
               where  dtr_operacion   = @i_operacionca
               and    dtr_secuencial  = @w_secuencial_prv
               and    dtr_codvalor    = @w_seg_codvalor
               and    dtr_dividendo   = @w_seg_max_sec
               
               if @@error != 0
               begin
                  return  703115
               end
            end        
            ELSE
            begin
               insert into ca_det_trn
                     (dtr_secuencial,    dtr_operacion,     dtr_dividendo,
                      dtr_concepto,      dtr_estado,        dtr_periodo,
                      dtr_codvalor,      dtr_monto,         dtr_monto_mn,
                      dtr_moneda,        dtr_cotizacion,    dtr_tcotizacion,
                      dtr_afectacion,    dtr_cuenta,        dtr_beneficiario,
                      dtr_monto_cont)
               values(@w_secuencial_prv, @i_operacionca,       @w_seg_max_sec,
                      @w_seg_concepto,   2,                    0,
                      @w_seg_codvalor,   @w_seguro_dia,        @w_seguro_dia_mn,
                      @i_moneda,         @w_cotizacion_manana, 'N',
                      'D',               '',                   '',
                       0)
               
               if @@error != 0
               begin
                  return  703115
               end
            end
            
            -- IVA
            if @w_iva_concepto is not null and @w_iva_valor_dia > 0
            begin
               if exists(select 1
                         from   ca_det_trn with (nolock)
                         where  dtr_operacion  = @i_operacionca
                         and    dtr_secuencial = @w_secuencial_prv
                         and    dtr_codvalor   = @w_iva_codvalor
                         and    dtr_dividendo  = @w_iva_max_sec)
               begin
                  update ca_det_trn
                  set    dtr_monto      = dtr_monto    + @w_iva_valor_dia,
                         dtr_monto_mn   = dtr_monto_mn + @w_iva_valor_dia_mn
                  where  dtr_operacion   = @i_operacionca
                  and    dtr_secuencial  = @w_secuencial_prv
                  and    dtr_codvalor    = @w_iva_codvalor
                  and    dtr_dividendo   = @w_iva_max_sec
                  
                  if @@error != 0
                  begin
                     return  703115
                  end
               end        
               ELSE
               begin
                  if @w_iva_valor_dia > 0
                  begin
                     insert into ca_det_trn
                           (dtr_secuencial,    dtr_operacion,     dtr_dividendo,
                            dtr_concepto,      dtr_estado,        dtr_periodo,
                            dtr_codvalor,      dtr_monto,         dtr_monto_mn,
                            dtr_moneda,        dtr_cotizacion,    dtr_tcotizacion,
                            dtr_afectacion,    dtr_cuenta,        dtr_beneficiario,
                            dtr_monto_cont)
                     values(@w_secuencial_prv, @i_operacionca,       @w_iva_max_sec,
                            @w_iva_concepto,   2,                    0,
                            @w_iva_codvalor,   @w_iva_valor_dia,     @w_iva_valor_dia_mn,
                            @i_moneda,         @w_cotizacion_manana, 'N',
                            'D',               '',                   '',
                             0)
                     
                     if @@error != 0
                     begin
                        return   
                     end
                 end
               end
            end
            -- IVA
            --EN EL CAMPO ro_garantia SE ALMACENA EL MISMO VALOR DE ca_det_trn DEL SEGURO EN MONEDA NACIONAL
            if @w_seguro_dia_mn > 0  or @w_iva_valor_dia_mn > 0
            begin
               update ca_rubro_op
               set    ro_garantia = ro_garantia + @w_seguro_dia_mn
               where  ro_operacion = @i_operacionca
               and    ro_concepto  = @w_seg_concepto
               
               update ca_rubro_op
               set    ro_garantia = ro_garantia + @w_iva_valor_dia_mn
               where  ro_operacion = @i_operacionca
               and    ro_concepto  = @w_iva_concepto
            end
         end -- VALOR DEL SEGURO MAYOR QUE CERO
         ---SIGUIENTE CONCEPTO
         fetch rubros
         into  @w_seg_concepto,      @w_porcentaje,
               @w_saldo_insoluto,
               @w_categoria,         @w_tabla_tasa,
               @w_fpago,             @w_seg_valor,
               @w_ro_tipo_garantia,  @w_seg_acumulado_mn
      end -- while
      
      close rubros
      deallocate rubros
   end ---EXISTE OPERACIONES CON SEGUROS Y ESTAN VENCIDOS
   
   if  @i_fecha_proceso  = @i_fecha_prox_segven
   begin
      update ca_operacion
      set    op_fecha_prox_segven = dateadd(dd, @w_dias_cuota, @i_fecha_prox_segven)
      where  op_operacion = @i_operacionca

      select @i_fecha_prox_segven = dateadd(dd, @w_dias_cuota, @i_fecha_prox_segven)
   end
   
   return 0
end
go


