/******************************************************************************************/
/* Este programa Reversa los pagos de una operacion hasta una fecha dada  MAR-22-2005     */
/* Defecto No. 2443                                                                       */
/******************************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_reversa_pagos_operacion')
   drop proc sp_reversa_pagos_operacion
go

create proc sp_reversa_pagos_operacion 

as
declare
@w_banco             cuenta,
@w_operacion         int,   
@w_registros         int,
@w_error             int,
@w_fecha_cierre      datetime,
@w_fecha_pag         datetime,
@w_sec_ing           int


select @w_registros   = 0
 

select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

exec  sp_restaurar
  	   @i_banco		= '726013520166628'


-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select op_operacion,
       op_banco,
       ab_fecha_pag,
       ab_secuencial_ing
       
 from ca_abono,ca_operacion
where ab_operacion = 759303
and ab_operacion = op_operacion
and ab_secuencial_pag >= 111
order by ab_secuencial_pag desc


open cursor_operacion

fetch cursor_operacion
into  @w_operacion,
      @w_banco,
      @w_fecha_pag,
      @w_sec_ing
      

while @@fetch_status = 0
begin
   
--   PRINT 'va sec %1!'+@w_sec_ing
          
         exec @w_error = sp_fecha_valor
            @s_date              = @w_fecha_cierre,
            @s_lsrv	     	      = 'PRODUCCION',
            @s_ofi               = 9000,
            @s_sesn              = 1,
            @s_ssn               = 1,
            @s_srv               = 'CONSOLA',
            @s_term              = 'CONSOLA',
            @s_user              = 'script',
            @i_fecha_valor      	= '03/17/2004',
            @i_banco		         = @w_banco,
            @i_operacion         = 'F',   --(F)Fecha Valor (R)Reversa
            @i_observacion       = 'FECHA VALOR POR  GENERACION INCORRECTA',
            @i_en_linea          = 'N'
            if @w_error <> 0
             PRINT 'salip de fechaval.sp  Error banco ' + cast(@w_banco as varchar) + ' sec va ' + cast(@w_sec_ing as varchar) + ' ERROR ' + cast(@w_error as varchar)
            
            
         exec  @w_error = sp_eliminar_pagos 
            @s_ssn             = 1,
            @s_srv             = 'PRODUCCION',
            @s_date            = @w_fecha_cierre,
            @s_user            = 'script',
            @s_term            = 'CONSOLA',
            @s_corr            = 'N',
            @s_ssn_corr        = 1,
            @s_ofi             = 9000,
            @t_rty             = 'N',
            @t_debug           = 'N',
            @t_file         	 = 'N',
            @i_banco		       = @w_banco,
            @i_operacion		 = 'D',
            @i_secuencial_ing	 = @w_sec_ing,
            @i_en_linea        = 'N'
            if @w_error <> 0
             PRINT ' salio de elimpag.sp Error banco ' + cast(@w_banco as varchar) + ' sec va ' + cast(@w_sec_ing as varchar) + ' ERROR ' + cast(@w_error as varchar)
            
           
   select @w_registros = @w_registros +1
           

   fetch cursor_operacion
   into  @w_operacion,
         @w_banco,
         @w_fecha_pag,
         @w_sec_ing


end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

print 'careversapagospas.sp Finalizo  = ' + cast(@w_registros as varchar)

return 0
go
