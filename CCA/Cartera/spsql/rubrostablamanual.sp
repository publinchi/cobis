/************************************************************************/
/*      Archivo:                rubrospe.sp                             */
/*      Stored procedure:       sp_rubros_tabla_manual                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     mayo 2007                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Este sp calcula nuevamente el valor de los rubros que son sobre */
/*      los datos actualizados en la tabla de amortizacion MANUAL       */
/*      Esta programado unicamente los valores calculados sobre saldo   */
/************************************************************************/  
/*                              CAMBIOS                                 */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_rubros_tabla_manual')
   drop proc sp_rubros_tabla_manual
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_rubros_tabla_manual
@i_operacion	int = NULL

as
declare
@w_sp_name		         varchar(30),
@w_rot_concepto         catalogo,
@w_rot_porcentaje       float,
@w_moneda               smallint,
@w_num_dec_mn           smallint,
@w_num_dec              smallint,
@w_moneda_n             smallint,
@w_rot_saldo_op         char(1),
@w_rot_saldo_insoluto   char(1),
@w_valor_rubro          money,
@w_valor_iva            money,
@w_concepto_iva         catalogo,
@w_tasa_iva             float,
@w_dit_dividendo        int,
@w_saldo_cap            money,
@w_rubro_cap            catalogo

select   @w_sp_name           = 'sp_rubros_tabla_manual'


--- VALIDAR EXISTENCIA DE PERIDICIDAD 

--- DATOS OPERACION 
select @w_moneda      = opt_moneda
from ca_operacion_tmp
where opt_operacion	= @i_operacion

exec  sp_decimales
     @i_moneda       = @w_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_mn out
     
     
select @w_rubro_cap = rot_concepto
from ca_rubro_op_tmp
where rot_operacion = @i_operacion
and   rot_tipo_rubro = 'C'


declare cursor_rubros_tmanual 
 cursor for select
   rot_concepto,
   rot_porcentaje,
   isnull(rot_saldo_op,'N'),
   isnull(rot_saldo_insoluto,'N')
   from  ca_rubro_op_tmp, ca_concepto
   where rot_operacion = @i_operacion
   and   rot_concepto  = co_concepto
   and   co_categoria not in ('S','I','M','C') 
   and   rot_fpago     not in ('L','B')
   and   rot_concepto_asociado is null
for read only

open cursor_rubros_tmanual

fetch cursor_rubros_tmanual into
@w_rot_concepto,
@w_rot_porcentaje,
@w_rot_saldo_op,
@w_rot_saldo_insoluto

--while @@fetch_status not in (-1,0 )
while @@fetch_status = 0
begin 

        select @w_concepto_iva = rot_concepto,
               @w_tasa_iva     = rot_porcentaje
        from ca_rubro_op_tmp
        where rot_operacion = @i_operacion
        and   rot_concepto_asociado = @w_rot_concepto
        
        declare  cur_dividendos 
           cursor for select 
           dit_dividendo
           from ca_dividendo_tmp
           where dit_operacion = @i_operacion    
        for read only
        
        open cur_dividendos
        
        fetch  cur_dividendos  into
        @w_dit_dividendo
        
        --while @@fetch_status not in (-1,0)
        while @@fetch_status = 0
        begin
             
            if @w_rot_saldo_op = 'S'
            begin
               --TOMAR NUEVAMENTE EL SALDO ACTUAL DE LA TABLA TEMPORAL Y CALCULAR EL RUBRO
               select @w_saldo_cap = isnull(sum(amt_acumulado - amt_pagado),0)
               from ca_amortizacion_tmp
               where amt_operacion = @i_operacion
               and   amt_dividendo >= @w_dit_dividendo
               and   amt_concepto   = @w_rubro_cap
               
               select @w_valor_rubro = round(@w_saldo_cap * @w_rot_porcentaje / 100,@w_num_dec)
               
            end


           ---ACTUALIZACION TABLA DE AMORTIZACION TEMPORAL EN LAS CUOTAS QUE TENGA VALOR
            update ca_amortizacion_tmp
            set   amt_cuota      =  @w_valor_rubro,
                  amt_acumulado  = @w_valor_rubro
            where amt_operacion  = @i_operacion
            and   amt_dividendo  = @w_dit_dividendo
            and   amt_concepto   = @w_rot_concepto
            and   amt_cuota   > 0
                        
            if @@rowcount > 0  and  @w_concepto_iva is not null or @w_concepto_iva <> ''
            begin
               
               select @w_valor_iva  = round(@w_valor_rubro * @w_tasa_iva / 100,@w_num_dec)

               ---ACTUALIZACION TABLA DE AMORTIZACION TEMPORAL EN LAS CUOTAS QUE TENGA VALOR
               update ca_amortizacion_tmp
               set   amt_cuota      =  @w_valor_iva,
                     amt_acumulado  = @w_valor_iva
               where amt_operacion  = @i_operacion
               and   amt_dividendo  = @w_dit_dividendo
               and   amt_concepto   = @w_concepto_iva
               and   amt_cuota   > 0
               
            end   
            
            
 
                
               
            fetch cur_dividendos
            into
            @w_dit_dividendo
            
        end --cur_dividendos
        close cur_dividendos
        deallocate cur_dividendos    


    fetch   cursor_rubros_tmanual 
    into
    @w_rot_concepto,
    @w_rot_porcentaje,
    @w_rot_saldo_op,
    @w_rot_saldo_insoluto


end  --cursor_rubros_tmanual
close cursor_rubros_tmanual
deallocate cursor_rubros_tmanual



return 0
go
