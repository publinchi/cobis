/************************************************************************/
/*  Archivo:            tablafac.sp                                     */
/*  Stored procedure:   sp_tablafac                                     */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:                                                       */
/*  Fecha de escritura:                                                 */
/************************************************************************/
/*                             IMPORTANTE                               */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "Cobiscorp".                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de Cobiscorp o su representante.              */
/************************************************************************/  
/*                              PROPOSITO                               */
/*  Procedimiento  que gerera la tabla de amortizacion para las         */ 
/*  operaciones FACTORING                                               */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tablafac')
	drop proc sp_tablafac
go

create proc sp_tablafac
   @i_operacionca                  int
as
declare 
   @w_sp_name                      descripcion,
   @w_return                       int,
   @w_error                        int,
   @w_di_num_dias                  int,
   @w_dividendo                    int,
   @w_float                        float,
   @w_monto_cap                    money,
   @w_saldo_cap                    float,
   @w_valor_rubro                  money,
   @w_porcentaje                   float,
   @w_valor_calc                   money,
   @w_di_fecha_ini                 datetime,
   @w_di_fecha_ven                 datetime,
   @w_concepto                     catalogo,
   @w_estado                       tinyint,
   @w_tipo_rubro                   char(1),
   @w_fpago                        char(1),
   @w_de_capital                   char(1),
   @w_de_interes                   char(1),
   @w_factor                       tinyint,
   @w_provisiona                   char(1),
   @w_dias_anio                    smallint,
   @w_monto                        money,
   @w_opt_tramite                  int,
   @w_int                          float,
   @w_moneda                       int,  
   @w_num_dec                      int,  
   @w_saldo_operacion              char(1),
   @w_fecha_fin                    datetime,  
   @w_plazo_final                  int,
   @w_tasa_efa                     float,
   @w_causacion                    char(1),
   @w_tasa_dia                     float,
   @w_dias_int                     float,
   @w_valor_intant                 float

begin
   --- CARGA DE VARIABLES INICIALES 
   select @w_sp_name   = "sp_tablafac",
          @w_valor_intant  = 0.0
   
   --- DETERMINAR SI USA TASA EQUIVALENTE 
   select @w_dias_anio        = opt_dias_anio,
          @w_opt_tramite      = opt_tramite,
          @w_moneda           = opt_moneda, 
          @w_causacion        = opt_causacion
   from   ca_operacion_tmp
   where  opt_operacion  = @i_operacionca
   
   --- CALCULAR EL MONTO DEL CAPITAL TOTAL 
   select @w_saldo_cap = sum(rot_valor)
   from   ca_rubro_op_tmp
   where  rot_operacion  = @i_operacionca
   and    rot_tipo_rubro = 'C'
   and    rot_fpago      in ('P','A','T') -- PERIODICO VENCIDO O ANTICIPADO
   
   exec @w_return = sp_decimales
        @i_moneda      = @w_moneda,
        @o_decimales   = @w_num_dec out
   
   if @w_return != 0 
      return @w_return
   
   if exists (select 1 from ca_amortizacion_tmp
              where amt_operacion =  @i_operacionca)
   begin
      delete ca_amortizacion_tmp
      where  amt_operacion =  @i_operacionca
   end
   
   declare
      cursor_dividendo cursor
      for select dit_dividendo,  dit_fecha_ini,  dit_fecha_ven,
                 dit_de_capital, dit_de_interes, dit_estado,
                 dit_dias_cuota
          from   ca_dividendo_tmp
          where  dit_operacion  = @i_operacionca
      for read only
   
   open cursor_dividendo
   
   fetch cursor_dividendo
   into  @w_dividendo,  @w_di_fecha_ini, @w_di_fecha_ven,
         @w_de_capital, @w_de_interes,   @w_estado,
         @w_di_num_dias
   
   while @@fetch_status = 0 
   begin --WHILE CURSOR PRINCIPAL
      if (@@fetch_status = -1) 
      begin
         select @w_error = 710004
         goto ERROR
      end
      
      --- CURSOR DE RUBROS TABLA CA_RUBRO_OP_TMP 
      declare
         cursor_rubros cursor
         for select rot_concepto,   rot_tipo_rubro,      rot_fpago,
                    rot_provisiona, rot_porcentaje,      rot_valor,
                    rot_saldo_op,   rot_porcentaje_efa
             from   ca_rubro_op_tmp
             where  rot_operacion  = @i_operacionca
             and    rot_fpago      in ('P','A') 
             and    rot_tipo_rubro in ('C','I','V','O','Q') 
             order by rot_tipo_rubro desc
         for read only
      
      open  cursor_rubros

      fetch cursor_rubros
      into  @w_concepto,         @w_tipo_rubro, @w_fpago,
            @w_provisiona,       @w_int,        @w_valor_rubro,
            @w_saldo_operacion,  @w_tasa_efa
      
      while @@fetch_status = 0 
      begin ---WHILE CURSOR RUBROS
         if (@@fetch_status = -1) 
         begin
            select @w_error = 710004
            goto ERROR
         end
         
         select @w_porcentaje = @w_int
         
         -- RUBROS DE TIPO CAPITAL 
         if @w_tipo_rubro = 'C'
         begin
            select @w_valor_calc = sum(isnull(fa_valor,0))
            from   cob_credito..cr_facturas
            where  fa_dividendo =  @w_dividendo
            and    fa_tramite   = @w_opt_tramite
         end
         
         --- RUBROS DE TIPO INTERES 
         if @w_tipo_rubro = 'I'  
         begin    
            select @w_valor_intant = isnull(sum(fac_intant),0)
             from   ca_facturas
            where  fac_operacion = @i_operacionca
            and    fac_nro_dividendo =  @w_dividendo
            
            select @w_valor_calc = round(@w_valor_intant , @w_num_dec)
            
            declare
               @w_dias_tot       int,
               @w_da_dividendo   int,
               @w_da_dias_cuota  int
            
            select @w_dias_tot = sum(dit_dias_cuota)
            from   ca_dividendo_tmp
            where  dit_operacion = @i_operacionca
            and    dit_dividendo <= @w_dividendo
            
   
            declare
               cur_div_ant cursor
               for select dit_dividendo, dit_dias_cuota
                   from   ca_dividendo_tmp
                   where  dit_operacion = @i_operacionca
                   and    dit_dividendo <= @w_dividendo
                   order by dit_dividendo
               for read only
            
            open  cur_div_ant
            fetch cur_div_ant
            into  @w_da_dividendo, @w_da_dias_cuota
            
--            while (@@fetch_status not in (-1,0))
            while (@@fetch_status = 0)
            begin
               select @w_valor_calc = round(@w_valor_intant * (1.0 * @w_da_dias_cuota) / (@w_dias_tot*1.0), @w_num_dec)
               
               ---PRINT 'tablafac.sp @w_da_dias_cuota %1! @w_da_dividendo %2! @w_dias_tot %3! @w_valor_intant %4! @w_dividendo %5! @w_valor_calc %6!',@w_da_dias_cuota,@w_da_dividendo,@w_dias_tot,@w_valor_intant,@w_dividendo,@w_valor_calc
               
               if @w_valor_calc > 0
               begin
                  if exists(select 1
                            from   ca_amortizacion_tmp
                            where  amt_operacion = @i_operacionca
                            and    amt_dividendo = @w_da_dividendo
                            and    amt_concepto  = @w_concepto)
                  begin
                     update ca_amortizacion_tmp
                     set    amt_cuota = amt_cuota + @w_valor_calc
                     where  amt_operacion = @i_operacionca
                     and    amt_dividendo = @w_da_dividendo
                     and    amt_concepto  = @w_concepto
                  end
                  ELSE
                  begin
                     insert into ca_amortizacion_tmp
                           (amt_operacion,  amt_dividendo,     amt_concepto, 
                            amt_cuota,      amt_gracia,        amt_pagado,
                            amt_acumulado,  amt_estado,        amt_periodo,
                            amt_secuencia)
                     values(@i_operacionca, @w_da_dividendo,   @w_concepto,
                            @w_valor_calc,  0,                 0,
                            0,              @w_estado,         0,
                            1)
                  end
                  
                  if @@error != 0
                  begin
                     select @w_error = 710001
                   goto ERROR
                  end
               end
               
               select @w_dias_tot = @w_dias_tot - @w_da_dias_cuota,
                      @w_valor_intant = @w_valor_intant - @w_valor_calc
                      
                      ---PRINT 'tablafa.sp @w_dias_tot %1! @w_da_dias_cuota %2!',@w_dias_tot,@w_da_dias_cuota
               --
               fetch cur_div_ant
               into  @w_da_dividendo, @w_da_dias_cuota
            end
            close cur_div_ant
            deallocate cur_div_ant
            
            select @w_valor_calc = 0.0
         end
         
         -- RUBROS DE TIPO PORCENTAJE, VALOR 
         if @w_tipo_rubro in ('O','V')
         begin
            select @w_valor_calc = isnull(round (@w_valor_rubro,@w_num_dec),0) --pga
         end
         
         -- RUBROS CALCULADOS 
         if @w_tipo_rubro = 'Q'  and @w_saldo_operacion = 'S'  
         begin
            select @w_valor_rubro = @w_saldo_cap * @w_porcentaje/100
            select @w_valor_calc = round(@w_valor_rubro , @w_num_dec)
         end
         ELSE
         begin
            if @w_tipo_rubro = 'Q'   
            begin
               select @w_valor_calc = round(@w_valor_rubro , @w_num_dec)
            end 
         end
         
         ---SI EL RUBRO NO PROVISIONA, ACUMULADO = CUOTA 
         if @w_provisiona = 'S'
            select  @w_factor = 0
         else
            select  @w_factor = 1
         
         --- INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP 
         select @w_valor_calc = round(@w_valor_calc, @w_num_dec) 
         
         if @w_valor_calc > 0
         begin
            insert into ca_amortizacion_tmp
                  (amt_operacion, amt_dividendo,   amt_concepto, 
                   amt_cuota,     amt_gracia,      amt_pagado,
                   amt_acumulado, amt_estado,      amt_periodo,
                   amt_secuencia)
            values(@i_operacionca, @w_dividendo,  @w_concepto,
                   @w_valor_calc ,  0,   0,
                   @w_valor_calc*@w_factor,     @w_estado,     0,
                   1)
            
            if @@error != 0
            begin
               select @w_error = 710001
               goto ERROR
            end
         end
         
         fetch cursor_rubros
         into  @w_concepto,         @w_tipo_rubro, @w_fpago,
               @w_provisiona,       @w_int,        @w_valor_rubro,
               @w_saldo_operacion,  @w_tasa_efa
      end -- WHILE CURSOR RUBROS
      
      close cursor_rubros
      deallocate cursor_rubros
      
      fetch cursor_dividendo
      into  @w_dividendo,  @w_di_fecha_ini, @w_di_fecha_ven,
            @w_de_capital, @w_de_interes,   @w_estado,
            @w_di_num_dias
   end --- WHILE CURSOR DIVIDENDOS
   
   close cursor_dividendo
   deallocate cursor_dividendo
   
   ---FECHA VENCIMIENTO DE LA OPERACION
   select @w_fecha_fin = max(dit_fecha_ven)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacionca
   
   --- PLAZO DE LA OPERACION
   select @w_plazo_final = max(datediff(dd,dit_fecha_ini,dit_fecha_ven))
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacionca
   
   --- ACTUALIZACION  FECHA DE VENCIMIENTO y PLAZO DE LA OP 
   update ca_operacion_tmp
   set    opt_fecha_fin   = @w_fecha_fin,
          opt_plazo       = @w_plazo_final,
          opt_periodo_cap = @w_plazo_final,
          opt_periodo_int = @w_plazo_final,
          opt_reajustable = 'N',
          opt_periodo_reajuste = 0
   where opt_operacion = @i_operacionca
   
   if @@error != 0 
   begin
      select @w_error =   710002
      goto ERROR
   end
     
   return 0
ERROR:
   return @w_error
end
 
go

