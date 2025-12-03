/************************************************************************/
/*   Archivo:              cuotfran.sp                                  */
/*   Stored procedure:     sp_cuota_francesa                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   Jul. 1997                                    */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.                */
/************************************************************************/  
/*   PROPOSITO                                                          */
/*   Procedimiento  que calcula valor de la cuota en sistema frances    */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cuota_francesa')
   drop proc sp_cuota_francesa
go

create proc sp_cuota_francesa
   @i_operacionca          int,
   @i_monto_cap            money,
   @i_gracia_cap           int,
   @i_tasa_int             money,
   @i_fecha_ini            datetime,
   @i_dias_anio            int = 360,
   @i_num_dec              int = 0,
   @i_periodo_crecimiento  smallint = 0,
   @i_tasa_crecimiento     float = 0,
   @i_tipo_crecimiento     char(1),
   @i_opcion_cap           char(1),
   @i_causacion            char(1) = 'L', 
   @o_cuota                money out
as
declare 
   @w_error                int,
   @w_num_dividendos       int,
   @w_adicionales          money,
   @w_saldo_cap            money,
   @w_cuota                money,
   @w_adicional            money,
   @w_factor_i             float,
   @w_ro_porcentaje        float,
   @w_dias_int             int,
   @w_valor_calc           money,
   @w_periodo_cap          smallint,                                 -- REQ 175: PEQUEÑA EMPRESA
   @w_cuota_aux            money,
   @w_veces                int,
   @w_cont                 int,
   @w_dividendo            int,  
   @w_di_num_dias          int,
   @w_di_fecha_ini         datetime, 
   @w_di_fecha_ven         datetime,
   @w_de_capital           char(1),
   @w_dias_anio            int,
   @w_float                money,
   @w_residuo              money,
   @w_saldo_cap_ant        money,
   @w_tasa_asociado        float

select @w_tasa_asociado = isnull(sum(rot_porcentaje), 0 ) --TASA DE INTERES TOTAL
from   ca_rubro_op_tmp
where  rot_operacion  = @i_operacionca
and    rot_concepto_asociado in (select rot_concepto
                                 from   ca_rubro_op_tmp
                                 where  rot_operacion  = @i_operacionca
                                 and    rot_fpago     in ('P', 'A')
                                 and    rot_tipo_rubro = 'I')

--TASA DE INTERES TOTAL
if @w_tasa_asociado > 0
   select @i_tasa_int = @i_tasa_int * (1 + (@w_tasa_asociado / 100))

-- CALCULAR EL NUMERO DE DIVIDENDOS DE CAPITAL
select @w_num_dividendos = count(1)
from   ca_dividendo_tmp
where  dit_operacion  = @i_operacionca
and    dit_de_capital = 'S'
and    dit_dividendo  > @i_gracia_cap                                -- REQ 175: PEQUEÑA EMPRESA

select 
-- @w_num_dividendos = @w_num_dividendos - @i_gracia_cap,               REQ 175: PEQUEÑA EMPRESA
@w_cuota          = @i_monto_cap
       
if @w_num_dividendos <= 0 begin
   select @w_error = 710005
   goto ERROR
end

-- CUOTAS ADICIONALES
select @w_cuota = @w_cuota - sum(cat_cuota)
from   ca_cuota_adicional_tmp, ca_dividendo_tmp
where  dit_operacion = @i_operacionca
and    cat_operacion = @i_operacionca
and    cat_operacion = @i_operacionca
and    cat_dividendo = dit_dividendo


if @w_cuota <= 0 begin
   select @o_cuota = 0
   return 0
end

if @i_periodo_crecimiento = 0  begin

   select 
   @w_dias_int    = opt_periodo_int * td_factor,                        -- REQ 175: PEQUEÑA EMPRESA opt_periodo_int POR opt_periodo_cap
   @w_periodo_cap = opt_periodo_cap / opt_periodo_int                   -- REQ 175: PEQUEÑA EMPRESA
   from ca_operacion_tmp, ca_tdividendo
   where opt_operacion  = @i_operacionca
   and   opt_tdividendo =  td_tdividendo
   and   td_estado      = 'V'
   
   if @@rowcount = 0 select @w_dias_int = 30                         -- REQ 175: PEQUEÑA EMPRESA @w_dias_cap POR @w_dias_int

   -- CONTROL DE DIAS PARA ANIOS BISIESTOS   
   exec @w_error = sp_dias_anio
   @i_fecha     = @i_fecha_ini,
   @i_dias_anio = @i_dias_anio,
   @o_dias_anio = @i_dias_anio out   
   
   if @w_error != 0 return @w_error
  
   select @w_factor_i = (@i_tasa_int * @w_dias_int / (@i_dias_anio * 100.00))       -- REQ 175: PEQUEÑA EMPRESA - AJUSTE PARA PERIODICIDADES DIFERENTES A MENSUAL
   
   select @w_adicionales = sum(cat_cuota / power(1 + @w_factor_i, ceiling((cat_dividendo - @i_gracia_cap) / convert(float, @w_periodo_cap))))       -- REQ 175: PEQUEÑA EMPRESA - AJUSTE PARA CALCULO DE CUOTAS ADICIONALES CON GRACIA
   from   ca_cuota_adicional_tmp, ca_dividendo_tmp
   where  dit_operacion = @i_operacionca 
   and    cat_operacion = dit_operacion
   and    cat_dividendo = dit_dividendo   

   select @w_dias_int = sum(dit_dias_cuota) / @w_num_dividendos
   from   ca_dividendo_tmp
   where  dit_operacion  = @i_operacionca
   and    dit_de_capital = 'S' 
   and   (dit_dividendo  > isnull(@i_gracia_cap,1) or (@i_gracia_cap =0))   

   -- PRIMERA APROXIMACION DE LA CUOTA POR FORMULA 
   exec @w_error = sp_formula_francesa
   @i_operacionca         = @i_operacionca,
   @i_monto_cap           = @i_monto_cap,
   @i_tasa_int            = @i_tasa_int,
   @i_dias_anio           = @i_dias_anio,
   @i_num_dec             = @i_num_dec, 
   @i_dias_cap            = @w_dias_int,                             -- REQ 175: PEQUEÑA EMPRESA
   @i_adicionales         = @w_adicionales,
   @i_num_dividendos      = @w_num_dividendos,
   @i_periodo_crecimiento = @i_periodo_crecimiento,
   @i_tasa_crecimiento    = @i_tasa_crecimiento,
   @o_cuota               = @w_cuota out 

   if @w_error != 0 return @w_error
   
   --PRINT 'AMP sp_cuota_francesa sale sp_formula_francesa @w_cuota = ' + convert(VARCHAR(20),@w_cuota)
   
end else begin

   if @i_tipo_crecimiento = 'P' begin
      select @w_cuota = @i_monto_cap / @w_num_dividendos
      select @w_cuota = @w_cuota + @w_cuota * @i_tasa_crecimiento / 100
   end else begin
      select @w_cuota = @i_monto_cap / @w_num_dividendos 
   end
      
   select @w_cuota = @w_cuota  + @w_cuota / (@i_monto_cap / @i_tasa_crecimiento  * @w_num_dividendos / @i_periodo_crecimiento)
END

/* AMP - se debe habilitar este segmento

-- NUMERO DE AFINACIONES DE LA CUOTA
if @i_periodo_crecimiento = 0  
begin
   select @w_cuota_aux = @w_cuota
   select @w_veces = 0

   while @w_veces < 30 
   begin 
      select @w_saldo_cap = @i_monto_cap,
             @w_veces     = @w_veces + 1,
             @w_cont      = 0

      declare cursor_dividendo cursor for
      select  dit_dividendo, dit_fecha_ini, dit_fecha_ven, dit_de_capital, cat_cuota, dit_dias_cuota
      from    ca_dividendo_tmp, ca_cuota_adicional_tmp
      where   dit_operacion  = @i_operacionca
      and     cat_operacion  = @i_operacionca
      and     cat_operacion  = dit_operacion
      and     cat_dividendo  = dit_dividendo
      for read only
   
      open    cursor_dividendo
      fetch   cursor_dividendo 
      into    @w_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, @w_de_capital, @w_adicional, @w_di_num_dias
   
      -- WHILE cursor_dividendo
      while @@fetch_status = 0 
      begin 
         if (@@fetch_status = -1) return 710004
   
         select @w_cont = @w_cont + 1
         
         -- CONTROL DE DIAS PARA ANIOS BISIESTOS 
         exec @w_error = sp_dias_anio
         @i_fecha      = @w_di_fecha_ini,
         @i_dias_anio  = @i_dias_anio,
         @o_dias_anio  = @w_dias_anio out
        
         if @w_error != 0 return @w_error
   
         -- CALCULAR VALORES DE PAGO CON LA CUOTA ACTUAL 
         exec @w_error   = sp_calc_intereses -- DE UN DIA EXPONENCIAL
         @tasa           = @i_tasa_int,
         @monto          = @w_saldo_cap,
         @dias_anio      = @w_dias_anio,
         @num_dias       = @w_di_num_dias,
         @causacion      = 'L',
         @causacion_acum = 0,
         @intereses      = @w_float out
       
         if @w_error != 0 return @w_error
    
         select @w_saldo_cap = @w_saldo_cap - @w_adicional

         select @w_float = round(@w_float,@i_num_dec)

         if @w_de_capital = 'S' 
         begin

            if @w_cont > @i_gracia_cap 
               if @w_cuota_aux > @w_float
                  select @w_saldo_cap = @w_saldo_cap - (@w_cuota_aux - @w_float)

            select @w_cuota_aux = @w_cuota
         end 
   
         fetch   cursor_dividendo 
         into    @w_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, @w_de_capital, @w_adicional, @w_di_num_dias
      end --WHILE CURSOR DIVIDENDOS

      close cursor_dividendo
      deallocate cursor_dividendo

      -- APROXIMAR EL VALOR DE LA CUOTA 
      exec @w_error          = sp_formula_francesa
      @i_operacionca         = @i_operacionca,
      @i_monto_cap           = @w_saldo_cap,
      @i_tasa_int            = @i_tasa_int,
      @i_dias_anio           = @i_dias_anio,
      @i_num_dec             = @i_num_dec, 
      @i_dias_cap            = @w_dias_int,                             -- REQ 175: PEQUEÑA EMPRESA
      @i_adicionales         = @w_adicionales,
      @i_num_dividendos      = @w_num_dividendos,
      @i_periodo_crecimiento = @i_periodo_crecimiento,
      @i_tasa_crecimiento    = @i_tasa_crecimiento,
      @o_cuota               = @w_residuo out 
   
      if @w_error != 0 return @w_error
    
      select @w_residuo = @w_residuo - (@w_saldo_cap*@i_tasa_int*@w_dias_int/(100*@i_dias_anio))

      if abs(@w_residuo) < 0.02 
         break

      select @w_cuota     = @w_cuota + @w_residuo  
      select @w_cuota_aux = @w_cuota

      -- SI EL SALDO DE CAPITAL ES >= AL ANTERIOR ENTONCES SALIR 
      if abs(@w_saldo_cap) >= abs(@w_saldo_cap_ant) break 

      select @w_saldo_cap_ant = @w_saldo_cap
   end
end
*/

if @w_cuota < 0  select @w_cuota = 10000
   select @o_cuota = round(@w_cuota, @i_num_dec)
    
return 0

ERROR:

return @w_error
 
go
