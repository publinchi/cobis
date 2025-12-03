/************************************************************************/
/*   Archivo:              act_fhis.sp                                  */
/*   Stored procedure:     sp_act_fechas_ref                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         xxxxxxxxxx                                   */
/*   Fecha de escritura:   xxxxxxxxxx                                   */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   ACTUALIZAR FECHA tr_fecha_ref leer de la tabla ca_fechas_diff      */
/*   que se carga con bcp                                               */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_act_fechas_ref')
   drop proc sp_act_fechas_ref
go

create proc sp_act_fechas_ref 

as
declare
@w_banco           char(15),
@w_operacion       int,   
@w_registros       int,
@w_secuencial      int,
@w_tran            char(3),
@w_tr_fecha_ref    datetime,
@w_fecha_ult_proceso datetime

select @w_registros  = 0


declare cursor_operacion cursor
for 
select oper,
       sec
from   ca_fechas_diff
order by oper

open cursor_operacion

fetch cursor_operacion
into  @w_operacion,
      @w_secuencial

while @@fetch_status  = 0
begin
   select @w_fecha_ult_proceso = oph_fecha_ult_proceso
   from ca_operacion_his
   where oph_operacion = @w_operacion
   and   oph_secuencial = @w_secuencial
   if @@rowcount = 0
   begin
      select @w_fecha_ult_proceso = oph_fecha_ult_proceso
      from cob_cartera_his..ca_operacion_his
      where oph_operacion = @w_operacion
      and   oph_secuencial = @w_secuencial
      if @@rowcount = 0
      begin  ---LA TRANSACCION NO TIENE HISTORIA
         update ca_transaccion
         set tr_secuencial_ref = -999
         where tr_operacion = @w_operacion
         and   tr_secuencial =   @w_secuencial
      end
      else 
       begin ---LA TRANSACCION TIENE HOSTORIA PERO CON FECHAS DIFF
       begin tran
         select @w_registros = @w_registros + 1
         update ca_transaccion
         set tr_fecha_ref = @w_fecha_ult_proceso
         where tr_operacion = @w_operacion
         and   tr_secuencial =   @w_secuencial
       commit tran
       end
      
   end
   else
    begin  ---LA TRANSACCION TIENE HOSTORIA PERO CON FECHAS DIFF
      begin tran
      update ca_transaccion
      set tr_fecha_ref = @w_fecha_ult_proceso
      where tr_operacion = @w_operacion
      and   tr_secuencial =   @w_secuencial
     commit tran
    end
 
   
   fetch cursor_operacion
   into  @w_operacion,
         @w_secuencial
end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

RETURN 0
go

