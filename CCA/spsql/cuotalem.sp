/******************************************************************/
/* Archivo:             cuotalem.sp                               */
/* Stored procedure:    sp_cuota_alemana                          */
/* Base de datos:       cob_cartera                               */
/* Producto:            Cartera                                   */
/* Disenado por:        Fabian de la Torre                        */
/* Fecha de escritura:  Jul. 1997                                 */
/******************************************************************/
/*                         IMPORTANTE                             */
/* Este programa es parte de los paquetes bancarios propiedad de  */
/* "COBISCORP".                                                   */
/* Su uso no autorizado queda expresamente prohibido asi como     */
/* cualquier alteracion o agregado hecho por alguno de sus        */
/* usuarios sin el debido consentimiento por escrito de la        */
/* Presidencia Ejecutiva de COBISCORP o su representante.         */
/******************************************************************/  
/*          PROPOSITO                                             */
/* Procedimiento  que calcula valor de la cuota de capital en el  */
/* sistema frances                                                */
/*    FECHA            AUTOR              CAMBIO	              */
/*    01-Jun-2022      G. Fernandez    Se comenta prints          */
/******************************************************************/
  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cuota_alemana')
   drop proc sp_cuota_alemana
go

create proc sp_cuota_alemana
@i_operacionca           int,
@i_monto_cap             money,
@i_gracia_cap            int,
@i_num_dec               int = 0,
@o_cuota                 money out
as
declare 
@w_sp_name           descripcion,
@w_return            int,
@w_error             int,
@w_num_dividendos    int,
@w_adicionales       money


/* CARGA DE VARIABLES INICIALES */
select @w_sp_name = 'sp_cuota_alemana'

/* CALCULAR NUMERO DE DIVIDENDOS DE CAPITAL */
select @w_num_dividendos = count(1)
from ca_dividendo_tmp
where dit_operacion  = @i_operacionca
and   dit_de_capital = 'S'
and   dit_dividendo  > @i_gracia_cap                                 -- REQ 175: PEQUEÑA EMPRESA

-- select @w_num_dividendos = @w_num_dividendos - @i_gracia_cap         REQ 175: PEQUEÑA EMPRESA

if @w_num_dividendos <= 0 begin
   --PRINT 'cuotalen.sp No se ha definido dividendo de CAP di_de_capital '
   select @w_error = 710005
   goto ERROR
end


/* CUOTAS ADICIONALES */
select 
@w_adicionales = isnull(sum(cat_cuota),0)
from ca_cuota_adicional_tmp, ca_dividendo_tmp                        -- REQ 175: PEQUEÑA EMPRESA
where cat_operacion  = @i_operacionca
and   dit_operacion  = cat_operacion
and   dit_dividendo  = cat_dividendo 


if @i_monto_cap <= 0 begin
   select @w_error = 710006
   goto ERROR
end

/* CALCULO DEL VALOR DE LA CUOTA */
select @o_cuota = round( (@i_monto_cap- @w_adicionales) / @w_num_dividendos,@i_num_dec)

return 0

ERROR:

return @w_error
 
go
