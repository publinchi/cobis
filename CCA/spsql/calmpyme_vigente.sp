/************************************************************************/
/*      Archivo:                calmpyme.sp                             */
/*      Stored procedure:       sp_calculo_mipymes_Vigente              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sandro Vallejo                          */
/*      Fecha de escritura:     Marzo 2008                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calculo de comision mipymes   a las cuotas en general pero solo */
/*      actualiza las NO VIGENTES                                       */
/*                              CAMBIOS                                 */
/************************************************************************/
/*  FECHA       AUTOR         RAZON                                     */
/*  Ene-2015    Elcira Pelaez Calulo MIPYMES cuotas adicionadas a tabla */
/*                                   por aumento de tasa                */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_calculo_mipymes_Vigente')
   drop proc sp_calculo_mipymes_Vigente
go

---INC. 118105 MAR.16.2015
create proc sp_calculo_mipymes_Vigente
@i_operacion            int,
@i_mipymes              catalogo,
@i_dividendo            int = 9999

as
declare
@w_sp_name              varchar(30),
@w_return               int,
@w_est_vigente          tinyint,
@w_est_novigente        tinyint,
@w_num_dec              smallint,
@w_moneda               smallint,
@w_fecha_liq            datetime,
@w_op_monto             money,
@w_di_dividendo         int,
@w_di_fecha_ven         datetime,
@w_di_estado            int,
@w_valor                money,
@w_valor_tmp            money,
@w_factor               float,
@w_asociado             catalogo,
@w_porcentaje           float,
@w_valor_asociado       money,
@w_mes_anualidad        int,
@w_cliente_nuevo        char(1),
@w_error                int,
@w_cliente              int,
@w_oficina_op           smallint,
@w_fecha_ult_p          smalldatetime,
@w_SMV                  money,
@w_monto_parametro      float,
@w_di_fecha_ini         smalldatetime,
@w_mensaje              varchar(255),
@w_porcentaje_asociado  float,
@w_msg                  mensaje,
@w_dividendo_anualidad  int,
@w_am_estado            int,
@w_op_estado            int,
@w_clase_cartera        catalogo,
@w_div_vigente          int,
@w_mes_actual           int,
@w_periodo_int          int

--- INICIALIZACION VARIABLES
select 
@w_sp_name        = 'sp_calculo_mipymes_Vigente',
@w_est_vigente    = 1,
@w_est_novigente  = 0,
@w_valor          = 0,
@w_porcentaje     = 0,
@w_valor_asociado = 0,
@w_asociado       = '',
@w_mes_anualidad  = 1

                                                                                                                                                                                                                                                              
select @w_SMV      = pa_money 
from   cobis..cl_parametro with (nolock)
where  pa_producto  = 'ADM'
and    pa_nemonico  = 'SMV'
                                                                                                                                                                                                                                
--- DATOS OPERACION 
select 
@w_fecha_liq     = op_fecha_liq,
@w_moneda        = op_moneda,
@w_cliente       = op_cliente,
@w_oficina_op    = op_oficina,
@w_fecha_ult_p   = op_fecha_ult_proceso,
@w_clase_cartera = op_clase,
@w_op_estado     = op_estado
from   ca_operacion
where  op_operacion    = @i_operacion
                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                      
---MONTO OPERACION
                                                                                                                                                                                                                                    
select @w_op_monto = sum(am_cuota - am_pagado)
from   ca_amortizacion, ca_rubro_op
where  am_operacion  = @i_operacion
and    ro_operacion  = am_operacion
and    ro_concepto   = am_concepto 
and    ro_tipo_rubro = 'C'
                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                         
--- OBTENER FACTOR DE CALCULO 
                                                                                                                                                                                                                        
select @w_factor = ro_porcentaje
from   ca_rubro_op
where  ro_operacion = @i_operacion
and    ro_concepto  = @i_mipymes


--- NUMERO DE DECIMALES 
exec @w_return = sp_decimales
@i_moneda      = @w_moneda,
@o_decimales   = @w_num_dec out
if @w_return <> 0 
   return  @w_return
                                                                                                                                                                                                                                                       
select @w_div_vigente = di_dividendo
from   ca_dividendo
where  di_operacion   = @i_operacion 
and    di_estado      = 1

if @@rowcount = 0 select @w_div_vigente = null
                                                                                                                                                                                                         
--- DETERMINAR PERIODICIDAD DE PAGO DE INTERESES EN LA OPERACION 
select @w_periodo_int = op_periodo_int * td_factor / 30
from ca_operacion, ca_tdividendo
where op_operacion = @i_operacion
and   op_tdividendo = td_tdividendo

if @@rowcount = 0 
   select @w_periodo_int = 1

select  @w_mes_anualidad = 1,
        @w_valor         = round((@w_op_monto * @w_periodo_int * @w_factor / 1200.0), @w_num_dec)

if @w_clase_cartera = 1 
  select @w_valor = 0

  
--- VERIFICAR SI EL RUBRO MIPYMES TIENE RUBRO ASOCIADO 
select 
@w_asociado             = ro_concepto,
@w_porcentaje_asociado  = ro_porcentaje
from   ca_rubro_op
where  ro_operacion         = @i_operacion
and    ro_concepto_asociado = @i_mipymes
                                                                                                                                                                                                              
if @@rowcount = 0 or @w_porcentaje_asociado is null select @w_porcentaje_asociado = 0, @w_asociado = ''

--- DETERMINAR PERIODICIDAD DE PAGO DE INTERESES EN LA OPERACION TEMPORAL 
                                                                                                                                                                            
select @w_periodo_int = op_periodo_int * td_factor / 30
from ca_operacion, ca_tdividendo
where op_operacion = @i_operacion
and   op_tdividendo = td_tdividendo

  if @@rowcount = 0 select @w_periodo_int = 1

---- CURSOR DE DIVIDENDOS
                                                                                                                                                                                                                           
declare cursor_dividendos_2 cursor for
select 
di_dividendo,   
di_fecha_ven,   
di_estado,
di_fecha_ini
from  ca_dividendo with (nolock)
where di_operacion  = @i_operacion
order by di_dividendo
for read only

open    cursor_dividendos_2

fetch   cursor_dividendos_2
into    
@w_di_dividendo, 
@w_di_fecha_ven, 
@w_di_estado, 
@w_di_fecha_ini

--- WHILE CURSOR PRINCIPAL 

  while @@fetch_status = 0  begin

  if (@@fetch_status = -1) return 708999

  select @w_mes_actual = (@w_di_dividendo-1) * @w_periodo_int + 1

  if @w_mes_actual = @w_mes_anualidad  
  begin
   
     --- ACTUALIZAR MES ANUALIDAD 
     select @w_mes_anualidad = @w_mes_anualidad + 12
     --- RECALCULAR VALOR DE MIPYMES SOBRE EL SALDO DE CAPITAL
     select @w_op_monto = sum(am_cuota - am_pagado)
     from   ca_amortizacion, ca_rubro_op
     where  am_operacion  = @i_operacion
     and    ro_operacion  = am_operacion
     and    am_dividendo >= @w_di_dividendo
     and    ro_concepto   = am_concepto 
     and    ro_tipo_rubro = 'C'
      
     select @w_valor  = round((@w_op_monto * @w_periodo_int * @w_factor / 1200.0), @w_num_dec)
     
     if @w_clase_cartera = 1 select @w_valor = 0
     
  end
   
  --- CALCULAR RUBRO MIPYMES 
  if exists (select 1 from ca_amortizacion  with (nolock)
  where  am_operacion = @i_operacion
  and    am_dividendo = @w_di_dividendo
  and    @w_di_estado = 0
  and    am_concepto  = @i_mipymes)
  begin
  
     update ca_amortizacion with (rowlock) 
     set    am_cuota     =  @w_valor 
     where  am_operacion = @i_operacion
     and    am_dividendo = @w_di_dividendo
     and    am_concepto  = @i_mipymes
     and    @w_di_estado = 0
     and    am_dividendo  > @i_dividendo
     and    @w_valor > 0
 
     if @@error <> 0 begin
        print 'calmipyme_vigente.sp Error Updating en ca_amortizacion'
        close cursor_dividendos_2
        deallocate cursor_dividendos_2
        return 710002
     end
      
  end else begin
  
     if (@w_valor >= 0.01 ) and ( @w_di_estado = 0) and (@w_di_dividendo > @i_dividendo)
     begin
        --- INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION 
        insert into ca_amortizacion with (rowlock) (
        am_operacion,   am_dividendo,   am_concepto,
        am_cuota,       am_gracia,      am_pagado,
        am_acumulado,   am_estado,      am_periodo,
        am_secuencia)
        values(
        @i_operacion,    @w_di_dividendo, @i_mipymes,
        @w_valor,        0,               0,
        0,               0,               0,
        1 )
    
        if (@@error <> 0) begin
            print 'calmipyme_vigente.sp Error Insertando en ca_amortizacion'
           close cursor_dividendos_2
           deallocate cursor_dividendos_2
           return 710001
        end
        
     end --si valor es mayor a cero
  end
  
  ---ACTUALIZAR RUBRO ASOCIADO A MIPYMES 
  select @w_valor_asociado = round((@w_valor * @w_porcentaje_asociado / 100.0), @w_num_dec)
  
  if exists (select 1 from  ca_amortizacion with (nolock)
  where am_operacion = @i_operacion
  and   am_dividendo = @w_di_dividendo
  and   am_concepto  = @w_asociado
  and   @w_di_estado = 0)
  and   @w_valor_asociado > 0
  begin
  
     update ca_amortizacion with (rowlock) set 
     am_cuota     = @w_valor_asociado,
     am_acumulado = 0
     where  am_operacion = @i_operacion
     and    am_dividendo = @w_di_dividendo
     and    am_concepto  = @w_asociado
     and    @w_di_estado = 0
     and    am_dividendo  > @i_dividendo
     and    @w_valor_asociado > 0                                                                                                                                                                                                                                                     
     if (@@error <> 0) begin
          print 'calmipyme_vigente.sp Error Updating en ca_amortizacion Asociado '
         close cursor_dividendos_2
         deallocate cursor_dividendos_2
         return 710002
     end
     
  end else begin
  
     if (@w_valor_asociado >= 0.01) and (@w_di_estado = 0) and (@w_di_dividendo > @i_dividendo)
     begin
     
       --- INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION 
        insert into ca_amortizacion with (rowlock) (
        am_operacion,   am_dividendo,   am_concepto,
        am_cuota,       am_gracia,      am_pagado,
        am_acumulado,   am_estado,      am_periodo,
        am_secuencia)
        values(
        @i_operacion,     @w_di_dividendo, @w_asociado,
        @w_valor_asociado,0,               0,
        0,                0,               0,
        1 )
        
        if @@error <> 0 begin
            print 'calmipyme_vigente.sp Error Insertando en ca_amortizacion Asociado'
            close cursor_dividendos_2
            deallocate cursor_dividendos_2
            return 710001
        end
     end
  end

  fetch   cursor_dividendos_2
  into    
  @w_di_dividendo, 
  @w_di_fecha_ven, 
  @w_di_estado, 
  @w_di_fecha_ini

end ---WHILE CURSOR

close cursor_dividendos_2
deallocate cursor_dividendos_2

                                                                                                                                                                                                                             
if (select count(1)
    from   ca_amortizacion
    where  am_operacion = @i_operacion
    and    am_concepto  in (@i_mipymes,@w_asociado)
    and    am_cuota < 0) > 0
begin
   PRINT 'calmipyme_vigente.sp Error , VAlor de Cuotas MIPYMES '
   return 710554
end


return 0
go
