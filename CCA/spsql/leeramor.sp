/************************************************************************/
/*Archivo                         :leeramor.sp                          */
/*Stored procedure                :sp_leer_amortizacion                 */
/*Base de datos                   :cob_cartera                          */
/*Producto                        : Cartera                             */
/*Disenado por                    :  RGA  FDLT                          */
/*Fecha de escritura              :Ene. 1998                            */
/************************************************************************/
/*                            IMPORTANTE                                */
/*Este programa es parte de los paquetes bancarios propiedad de         */
/*"MACOSA".                                                             */
/*Su uso no autorizado queda expresamente prohibido asi como            */
/*cualquier alteracion o agregado hecho por alguno de sus               */
/*usuarios sin el debido consentimiento por escrito de la               */
/*Presidencia Ejecutiva de MACOSA o su representante.                   */
/************************************************************************/  
/*                               PROPOSITO                              */
/*Lee la cadena descompuesta e inserta en ca_amortizacion_tmp           */
/*                       ACTUALIZACIONES                                */
/*      EPB:MAY-23-2002Los planes manuales no generan gracia            */
/*                              automatica                              */
/*  Abr-04-2008   M.Roa  Adicion del campo dit_fecha_can en insert      */
/*  Jun-11-2020   Luis Ponce     CDIG Ajuste obtencion de dias en fecha */
/************************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_leer_amortizacion')
drop proc sp_leer_amortizacion
go

create proc sp_leer_amortizacion
   @s_user         login,
   @s_sesn         int, 
   @i_operacionca  int,
   @i_fecha_ini    datetime,
   @i_dias_gracia  tinyint,
   @i_dias_anio    int,
   @i_formato_fecha int = 101,
   @i_reestructuracion char(1) = 'N' 
as

declare 
   @w_sp_name           descripcion,
   @w_error             int,
   @w_return            int,
   @w_fila              int,
   @w_columna           int,
   @w_dividendo         int,
   @w_dias_calc         int,
   @w_fecha_ini         datetime,
   @w_fecha_ven         datetime,
   @w_concepto          catalogo,
   @w_tipo_rubro        catalogo,
   @w_valor             varchar(255),
   @w_saldo_cap         money,
   @w_monto             money,
   @w_cuota             money,
   @w_gracia            money,
   @w_porcentaje        money,
   @w_tasa_int_eq       money,
   @w_aux               int,
   @w_provisiona        char(1),
   @w_factor            tinyint,
   @w_base_calculo      char(1),
   @w_recalcular        char(1),
   @w_periodo_int       int,
   @w_tdividendo        char(1),
   @w_dias_di           int,
   @w_fecha_pri_cuot    datetime,
   @w_pos_pipe          int,
   @w_fecha             varchar(12),
   @w_dias_char         varchar(10),
   @w_tipo              char(1),
   @w_moneda            int,
   @w_num_dec           int,
   @w_causacion         char(1),
   @w_dias_int          int,
   @w_tasa_equivalente  char(1),
   @w_di_fecha_ini_tmp  datetime,
   @w_di_fecha_ven_tmp  datetime,
   @w_dia_fijo          tinyint,
   @w_ult_dia_habil     char(1),
   @w_original          tinyint,
   @w_evitar_feriados   char(1),
   @w_prorroga          char(1),
   @w_contador_feriados  int,        
   @w_mora_retroactiva   char(1),    
   @w_toperacion         catalogo,   
   @w_dias_gracia_disp   int,        
   @w_ciudad             int,     
   @w_op_gracia_int      int,
   @w_gracia_dist        money,
   @w_op_dist_gracia     char,
   @w_dit_dividendo      int,
   @w_dit_dias_cuota     int,
   @w_parametro_segvida  catalogo,
   @w_concepto_iva_seguro catalogo,
   @w_valor_un_dia       money,
   @w_valor_final        money,
   @w_valor_iva_seg      money,
   @w_rot_concepto       catalogo,
   @w_rot_valor          money,
   @w_con_asociado       varchar(20),
   @w_cuota_asoc         float   

   
--  VARIABLES INICIALES 
select @w_sp_name          = 'sp_leer_amortizacion',
       @w_original         = 0,
       @w_valor_iva_seg    = 0,
       @w_rot_valor        = 0,
       @w_dias_gracia_disp = @i_dias_gracia  ---BAC ABR-04-2003


/* BORRAR CUALQUIER TABLA ANTERIOR */
delete ca_cuota_adicional_tmp 
where cat_operacion = @i_operacionca

if @@error != 0  return 710003

if @i_reestructuracion = 'N'
begin
   delete ca_amortizacion_tmp 
   where  amt_operacion = @i_operacionca

   if @@error != 0  return 710003

   delete ca_dividendo_tmp 
   where  dit_operacion = @i_operacionca

   if @@error != 0  return 710003
end
else begin
   delete ca_amortizacion_tmp
   where  amt_operacion = @i_operacionca
   and  amt_dividendo > 1

   if @@error != 0  return 710003

   delete ca_dividendo_tmp
   where  dit_operacion = @i_operacionca
   and  dit_dividendo > 1

   if @@error != 0  return 710003
end

select @w_base_calculo = opt_base_calculo,
@w_recalcular          = opt_recalcular_plazo,
@w_evitar_feriados     = opt_evitar_feriados,
@w_ult_dia_habil       = opt_dia_habil,
@w_dia_fijo            = opt_dia_fijo,
@w_periodo_int         = opt_periodo_int,
@w_tdividendo          = opt_tdividendo,
@w_fecha_pri_cuot      = opt_fecha_pri_cuot,
@w_tipo                = opt_tipo,
@w_moneda              = opt_moneda,
@w_causacion           = opt_causacion,
@w_tasa_equivalente    = opt_usar_tequivalente,
@w_toperacion          = opt_toperacion,
@w_ciudad              = opt_ciudad,
@w_op_gracia_int       = opt_gracia_int,
@w_op_dist_gracia      = opt_dist_gracia
from ca_operacion_tmp
where opt_operacion = @i_operacionca

---BAC ABR-04-2003
select
@w_mora_retroactiva = dt_mora_retroactiva,
@w_tasa_equivalente =  dt_usar_tequivalente 
from ca_default_toperacion
where dt_toperacion = @w_toperacion



/** MANEJO DE DECIMALES **/
exec @w_return = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out

if @w_evitar_feriados = 'S' and @w_recalcular = 'N'
   if exists(select 1 from ca_dividendo_original_tmp
             where dot_operacion = @i_operacionca)
      select @w_original = 1

   select @w_dias_di = @w_periodo_int * td_factor
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo

if @w_dias_di = 0
begin
   select @w_error = 710007
   goto ERROR
end

select @w_dividendo = 1,
       @w_fecha_ini = @i_fecha_ini

-- LAZO DE CARGA DE DATOS */
declare cursor_decodificador cursor
   for select dc_fila, dc_columna, dc_valor
       from   ca_decodificador
       where  dc_operacion  = @i_operacionca
       and    dc_user       = @s_user
       and    dc_sesn       = @s_sesn
       order  by dc_fila,dc_columna
       for read only

open cursor_decodificador

fetch cursor_decodificador into
@w_fila, @w_columna, @w_valor

while   @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) begin
      select @w_error = 710004
      goto ERROR
   end
      
   if @w_columna = 1 --COLUMNA FECHA
   begin
      select @w_pos_pipe = charindex('/',@w_valor) ----LPO CDIG
            
      if @w_pos_pipe > 0
      begin

         select @w_fecha = substring(@w_valor,1,@w_pos_pipe - 1)

                   
--         select @w_dias_char = substring(@w_valor,@w_pos_pipe+1, datalength(@w_valor)-@w_pos_pipe)
         select @w_dias_char = substring(@w_fecha,1, 3) --LPO CDIG
         --select @w_dias_calc = convert(int,@w_dias_char)
                  
      end
      
      select @w_dividendo = @w_fila,
             @w_fecha_ven = convert(datetime,@w_valor,@i_formato_fecha)

            
      if @w_tipo <> 'D'
         --select @w_fecha_ini = convert(datetime,@i_fecha_ini,@i_formato_fecha)
         select @w_fecha_ini = @i_fecha_ini
      
      
      if @w_evitar_feriados = 'S' and @w_recalcular = 'N' and @w_original = 0
      begin
         select @w_di_fecha_ini_tmp = isnull(@w_di_fecha_ini_tmp, 
                                             @w_fecha_ini),
                @w_di_fecha_ven_tmp = @w_fecha_ven
         
         if @w_dividendo > 1
         begin
            if @w_dividendo = 2 and @w_fecha_pri_cuot is not null
               select @w_di_fecha_ini_tmp = @w_fecha_pri_cuot
            else
            begin
               if @w_dia_fijo > 0
               begin
                  while datepart(dd, @w_di_fecha_ini_tmp) <> @w_dia_fijo
                  begin
                     if @w_ult_dia_habil = 'S'
                        select @w_di_fecha_ini_tmp = dateadd(dd, 1, @w_di_fecha_ini_tmp)
                     else
                        select @w_di_fecha_ini_tmp = dateadd(dd, -1, @w_di_fecha_ini_tmp)
                  end
               end
            end
         end
         
         if @w_dividendo = 1 and @w_fecha_pri_cuot is not null
            select @w_di_fecha_ven_tmp = @w_fecha_pri_cuot
         else
         begin
            if @w_dia_fijo > 0
            BEGIN
               while datepart(dd, @w_di_fecha_ven_tmp) <> @w_dia_fijo
               
               begin
                  if @w_ult_dia_habil = 'S'
                     select @w_di_fecha_ven_tmp = dateadd(dd, 1, @w_di_fecha_ven_tmp)
                  else
                     select @w_di_fecha_ven_tmp = dateadd(dd, -1, @w_di_fecha_ven_tmp)
               END
            end
         end
            
         insert into ca_dividendo_original_tmp
         values(@i_operacionca, @w_dividendo,@w_di_fecha_ini_tmp, @w_di_fecha_ven_tmp)
            
         if @@error <> 0
         begin
            PRINT 'leeramor.sp Error 710001  A'
            select @w_error = 710001
            goto ERROR
         end
            
      select @w_di_fecha_ini_tmp = @w_di_fecha_ven_tmp
      end
      
      if @i_reestructuracion = 'N' or (@i_reestructuracion = 'S' and @w_dividendo > 1)
      begin
         if exists (select 1 from ca_prorroga
                    where pr_operacion = @i_operacionca
                    and   pr_nro_cuota = @w_dividendo+@w_aux)
            select @w_prorroga = 'S'
         else
            select @w_prorroga = 'N'
         
         select @w_contador_feriados = 0,
                @i_dias_gracia       = @w_dias_gracia_disp
         
      if @w_evitar_feriados = 'S' and @w_mora_retroactiva = 'S'
      begin 
            exec sp_contador
                 @i_fecha_proceso = @w_fecha_ven,
                 @i_ciudad        = @w_ciudad,
                 @o_contador      = @w_contador_feriados out
            
            if @w_contador_feriados > 0 
               select @i_dias_gracia   = @i_dias_gracia + @w_contador_feriados
       end
      
         if @w_base_calculo = 'E'
         begin
            exec @w_error = sp_dias_cuota_360
            @i_fecha_ini = @i_fecha_ini,
            @i_fecha_fin = @w_fecha_ven,
            @o_dias      = @w_dias_calc out
 
            if @w_error != 0 goto ERROR

         end
         else
            select @w_dias_calc = datediff(dd,@i_fecha_ini,@w_fecha_ven)

         insert into ca_dividendo_tmp
               (dit_operacion,  dit_dividendo,            dit_fecha_ini,
                dit_fecha_ven,  dit_de_capital,           dit_de_interes,
                dit_gracia,     dit_gracia_disp,          dit_estado,    
                dit_dias_cuota, dit_prorroga,             dit_intento,
                dit_fecha_can)
         values(@i_operacionca,  @w_dividendo,            @i_fecha_ini,
                @w_fecha_ven,    'S',                     'S',
                @i_dias_gracia,  @w_dias_gracia_disp,     0,
                @w_dias_calc,    @w_prorroga,             0,
                convert(DATETIME,'01/01/1900')) --LPO CDIG Conversion por MySql
         
         if @@error <> 0
         begin
            PRINT 'leeramor.sp Error 710001  B'
            select @w_error = 710001
            goto ERROR
         end
      end
      
      insert into ca_cuota_adicional_tmp
            (cat_operacion,cat_dividendo,cat_cuota)
      values(@i_operacionca,   @w_dividendo,   0.0  )
      
      if @@error <> 0
      begin
         PRINT 'leeramor.sp Error 710001  C'
         select @w_error = 710001
         goto ERROR
      end
      
      if @w_tipo <> 'D'
         select @i_fecha_ini = @w_fecha_ven
   end
   
   if @w_columna = 2 --COLUMNA SALDO DE CAPITAL
   begin
      select @w_monto = convert(money, @w_valor)
   end
   
   if @w_columna > 2
   begin --COLUMNAS DE RUBROS
      select @w_cuota = convert(money, @w_valor)
      
      -- BUSCAR NOMBRE DEL RUBRO
      select @w_aux = @w_columna - 2

      set rowcount @w_aux
      
      select @w_concepto   = rot_concepto,
             @w_tipo_rubro = rot_tipo_rubro,
             @w_porcentaje = rot_porcentaje,
             @w_provisiona = rot_provisiona,
             @w_con_asociado = rot_concepto_asociado
      from   ca_rubro_op_tmp
      where  rot_operacion  = @i_operacionca
      and    rot_fpago      not in ('L', 'B')
      and    rot_tipo_rubro <> 'M'
      order  by rot_concepto
      
      set rowcount 0
      -- CALCULAR VALOR DE GRACIA PARA RUBROS TIPO 'I'
      select @w_gracia = 0
      
      if @w_tipo_rubro = 'I' 
      begin
         
         ---PRINT 'leeamor.sp tasa %1! @w_concepto %2! @w_tasa_equivalente %3!',@w_porcentaje,@w_concepto,@w_tasa_equivalente
         
      if @w_tasa_equivalente = 'S'
         begin
            select @w_tasa_int_eq = 0.00
            -- CALCULAR TASA EQUIVALENTE A DIAS CORRESPONDIENTES
            exec @w_return = sp_tasa_op
                 @i_operacionca = @i_operacionca,
                 @i_dividendo   = @w_dividendo,
                 @i_concepto    = @w_concepto,
                 @i_num_dias    = @w_dias_calc,
                 @o_tasa_o      = @w_tasa_int_eq out
            
            if @w_return != 0 
            begin
               select @w_error = @w_return
               goto ERROR
            end
            
            select @w_porcentaje = @w_tasa_int_eq
         end
         
         select @w_dias_int = @w_dias_calc
         
         ---PRINT 'leeramor.sp @w_porcentaje %1! @w_monto %2! @w_dias_int %3!',@w_porcentaje,@w_monto,@w_dias_int
         
         exec @w_return = sp_calc_intereses
              @tasa      = @w_porcentaje,
           @monto     = @w_monto,
              @dias_anio = 360,
              @num_dias  = @w_dias_int,
              @causacion = 'L',
              @intereses = @w_cuota out
         
         if @w_return !=0
         begin
            select @w_error = 708211
            goto ERROR
         end
         
         select @w_cuota = round(@w_cuota,@w_num_dec),
                @w_gracia = 0
         ---EPB:MAY-23-2002
      end
      else
      begin
         if @w_tipo_rubro = 'O' and @w_con_asociado is not null
         begin
             select @w_cuota_asoc = round((amt_cuota*@w_porcentaje/100.00),@w_num_dec)
               from ca_amortizacion_tmp
              where amt_operacion = @i_operacionca
                and amt_dividendo = @w_dividendo
                and amt_concepto  = @w_con_asociado
             
             select @w_cuota = isnull(@w_cuota_asoc, @w_cuota)
         end
         else
            select @w_cuota = convert(money, @w_valor)
      end
      
      -- SI EL RUBRO NO PROVISIONA, ENTONCES ACUMULADO = CUOTA
      if @w_provisiona = 'S'
         select @w_factor = 0
      else
         select @w_factor = 1 
      
      if @i_reestructuracion = 'N' or (@i_reestructuracion = 'S' and
                                       @w_dividendo > 1)
      begin

         -- INSERTAR CA_AMORTIZACION_TMP
         insert into ca_amortizacion_tmp
               (amt_operacion, amt_dividendo,   amt_concepto,
                amt_cuota,     amt_gracia,      amt_pagado,
                amt_acumulado, amt_estado,      amt_periodo,
                amt_secuencia)
         values(@i_operacionca,  @w_dividendo,  @w_concepto,
                @w_cuota,        @w_gracia,     0,
                @w_cuota*@w_factor,             0,             0,
                1 )
         
         if (@@error <> 0)
         begin
            PRINT 'leeramor.sp Error 710001  D'
            select @w_error = 710001
            goto ERROR
         end        
      end
   end  --COLUMNAS DE RUBROS
   
   fetch cursor_decodificador
   into  @w_fila,  @w_columna,  @w_valor
end --while

close cursor_decodificador
deallocate cursor_decodificador

delete ca_decodificador
where dc_operacion = @i_operacionca
and   dc_user      = @s_user
and   dc_sesn      = @s_sesn

if @@error <> 0 return 710003

update ca_operacion_tmp
set opt_tipo_amortizacion = 'MANUAL',
    opt_fecha_fin         = (select max(dit_fecha_ven) from ca_dividendo_tmp
                              where dit_operacion = @i_operacionca)
where opt_operacion = @i_operacionca
if @@error <> 0 return 710003

if @w_op_gracia_int > 0
begin
   select @w_concepto = rot_concepto
   from   ca_rubro_op_tmp
   where  rot_operacion  = @i_operacionca
   and    rot_tipo_rubro = 'I'
   
   update ca_amortizacion_tmp
   set    amt_gracia = -amt_cuota
   where  amt_operacion  = @i_operacionca
   and    amt_dividendo <= @w_op_gracia_int
   and    amt_concepto   = @w_concepto
   
   if @w_op_dist_gracia != 'M' -- SI X SIGNIFICA QUE ES PERIODO MUERTO
   begin
      select @w_gracia = -isnull(sum(amt_gracia), 0)
      from   ca_amortizacion_tmp
      where  amt_operacion = @i_operacionca
      and    amt_dividendo <= @w_op_gracia_int
      and    amt_concepto  = @w_concepto
      
      
      if @w_op_dist_gracia = 'N' -- PARA LA GRACIA EN LA PRIMERA CUOTA DE INTERES
      begin
         update ca_amortizacion_tmp
         set    amt_gracia = @w_gracia -- TODA LA GRACIA
         where  amt_operacion  = @i_operacionca
         and    amt_dividendo  = @w_op_gracia_int+1 -- EN ESTA CUOTA
         and    amt_concepto   = @w_concepto
      end
      
      if @w_op_dist_gracia = 'S' -- PARA LA GRACIA DISTRIBUIDA EN EL RESTO DE CUOTAS DE INTERES
      begin
         select @w_dividendo = max(dit_dividendo)
         from   ca_dividendo_tmp
         where  dit_operacion = @i_operacionca
         
         if @w_dividendo > @w_op_gracia_int
         begin
            select @w_gracia_dist = round(@w_gracia / (@w_dividendo - @w_op_gracia_int), @w_num_dec)
            
            update ca_amortizacion_tmp
            set    amt_gracia = @w_gracia_dist
            where  amt_operacion  = @i_operacionca
            and    amt_dividendo  > @w_op_gracia_int
            and    amt_concepto   = @w_concepto
            
            select @w_gracia_dist = sum(amt_gracia)
            from   ca_amortizacion_tmp
            where  amt_operacion = @i_operacionca
            and    amt_dividendo > @w_op_gracia_int
            and    amt_concepto  = @w_concepto
            
            if @w_gracia_dist != @w_gracia
            begin
               update ca_amortizacion_tmp
               set    amt_gracia = amt_gracia -(@w_gracia_dist-@w_gracia)
               where  amt_operacion  = @i_operacionca
               and    amt_dividendo  = @w_dividendo
               and    amt_concepto   = @w_concepto
            end
         end
      end
   end
end

--28:ENE:2005 EPB
--CURSOR PARA ACTAULIZAR RUBROS DE SEGUROS

--DIAS OR LOS CUALES SE SACO EL VALOR DEL RUBRO SEGURO
 select @w_dias_di = td_factor *  @w_periodo_int
 from   ca_tdividendo
 where  td_tdividendo = @w_tdividendo
 
 select @w_parametro_segvida = pa_char
 from cobis..cl_parametro
where pa_producto = 'CCA'
and pa_nemonico = 'FPRSVI'
set transaction isolation level read uncommitted

    
declare cursor_seguros cursor
   for select dit_dividendo,
              dit_dias_cuota
       from   ca_dividendo_tmp
       where  dit_operacion  = @i_operacionca
       order  by dit_dividendo
       for read only

open cursor_seguros

fetch cursor_seguros into
@w_dit_dividendo,
@w_dit_dias_cuota

while   @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) begin
      select @w_error = 710004
      PRINT 'leeramor.sp Error en cursor de seguros de Tablas Manuales'
      goto ERROR
   end
            ------------------------------------------
            ------------------------------------------
            ---CURSOR DE TABLA SE RUBROS TIPO SEGUROS
            declare cursor_rubro_seguros cursor
               for select rot_concepto,
                          rot_valor
                   from   ca_rubro_op_tmp,ca_concepto
                   where  rot_operacion  = @i_operacionca
                   and    rot_concepto = co_concepto
                   and    co_categoria = 'S'
                   and    co_concepto != @w_parametro_segvida
                   for read only
            
            open cursor_rubro_seguros
            
            fetch cursor_rubro_seguros into
            @w_rot_concepto,
            @w_rot_valor
            
            while   @@fetch_status = 0 
            begin 
               if (@@fetch_status = -1) begin
                  select @w_error = 710004
                  PRINT 'leeramor.sp Error en cursor de rubros seguros de Tablas Manuales'
                  goto ERROR
               end   
                  select @w_valor_un_dia =  0
                  select @w_valor_final =   0
                  select @w_valor_un_dia =  @w_rot_valor /@w_dias_di
                  select @w_valor_final =   round(@w_valor_un_dia *  @w_dit_dias_cuota,@w_num_dec)
                  
                  update ca_amortizacion_tmp
                  set    amt_cuota      = @w_valor_final,
                         amt_acumulado  = @w_valor_final
                  where  amt_operacion  = @i_operacionca
                  and    amt_dividendo  = @w_dit_dividendo
                  and    amt_concepto   = @w_rot_concepto
                  --PARA EL IVA
                  select @w_concepto_iva_seguro = rot_concepto,
                         @w_valor_iva_seg = rot_valor
                  from ca_rubro_op_tmp,ca_concepto
                  where rot_operacion = @i_operacionca
                  and rot_concepto_asociado = @w_rot_concepto
                  and co_categoria  = 'A'
                  if @@rowcount > 0
                     begin
                        select @w_valor_un_dia =  0
                        select @w_valor_final =   0
                        select @w_valor_un_dia =  @w_valor_iva_seg /@w_dias_di
                        select @w_valor_final =   round(@w_valor_un_dia *  @w_dit_dias_cuota,@w_num_dec)

                        update ca_amortizacion_tmp
                        set    amt_cuota      = @w_valor_final,
                               amt_acumulado  = @w_valor_final
                        where  amt_operacion  = @i_operacionca
                        and    amt_dividendo  = @w_dit_dividendo
                        and    amt_concepto   = @w_concepto_iva_seguro                        
                        
                        
      end

                  
                
                  fetch cursor_rubro_seguros
               into @w_rot_concepto,
                    @w_rot_valor

            end --while  cursor_rubro_seguros
            
            close cursor_rubro_seguros
            deallocate cursor_rubro_seguros
            -----------------------------------------
            -----------------------------------------
   


   fetch cursor_seguros
   into  @w_dit_dividendo,
         @w_dit_dias_cuota
end --while  cursor_seguros

close cursor_seguros
deallocate cursor_seguros
--28:ENE:2005 EPB
--CURSOR PARA ACTAULIZAR RUBROS DE SEGUROS
   



return 0


ERROR:
return @w_error  


GO

