/************************************************************************/
/*	Archivo:             caborhfm.sp                                */
/*	Stored procedure:    sp_borra_hfm                               */
/*	Base de datos:       cob_cartera                                */
/*	Producto:            Cartera                                    */
/*	Disenado por:  	     EPB                                        */
/*	Fecha de escritura:  Julio 2004                                 */
/************************************************************************/
/*                            IMPORTANTE                                */
/*	Este programa es parte de los paquetes bancarios propiedad de   */
/*	'MACOSA'.                                                       */
/*	Su uso no autorizado queda expresamente prohibido asi como      */
/*	cualquier alteracion o agregado hecho por alguno de sus         */
/*	usuarios sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*	                           PROPOSITO                            */
/* Elimina de los historicos de las transacciones HFM y la transaccion  */
/* en estado RV de ca_transaccion                                       */
/* Los HFM borrados de esta tabla son los generados menores a la ultima */
/* fecha de cierre  que se saa automaticamente de credito               */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*      FECHA           AUTOR             RAZON                         */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_borra_hfm')
   drop proc sp_borra_hfm
go

create proc sp_borra_hfm
as
declare	
@w_sp_name			varchar(32),
@w_operacion 			int,
@w_secuencial   		int,
@w_error			      int,
@w_fecha             datetime,
@w_contador          int,
@w_tiempo            datetime


select	@w_sp_name   = 'sp_borra_hfm',
         @w_contador  = 0
  
  
-- FECHA DE CIERRE
set rowcount 1
select @w_fecha = max(do_fecha)
from   cob_credito..cr_dato_operacion
where  do_tipo_reg = 'M'
and    do_codigo_producto = 7
set rowcount 0

if @w_fecha is null
begin
   print 'Error  no existe  Fecha cr_dato_operacion de credito '
   select @w_error =  2101084 
end

   declare transaccion_hfm  cursor for
   select tr_operacion,
          tr_secuencial
   from ca_transaccion
   where tr_fecha_mov < @w_fecha
   and   tr_tran = 'HFM'
   and tr_ofi_usu > 0
   for read only

   open transaccion_hfm
   fetch transaccion_hfm into
   @w_operacion,
   @w_secuencial

      while (@@fetch_status = 0 ) begin

         if @@fetch_status = -1 
         begin 
            print 'caborhfm.sp -->  error en el cursor...transaccion_hfm .' 
            select @w_error = 70894
         end


  -- BORRADO DE HISTORICOS DE REVERSOS 
  
        select @w_contador = @w_contador + 1
        
        if @w_contador % 5000 = 0
        begin
           select @w_tiempo = getdate()
           PRINT 'Borradas  ' + cast(@w_contador as varchar) + ' tiempo '  + cast(@w_tiempo as varchar)
        end
       

        delete ca_amortizacion_his
        where amh_operacion =  @w_operacion
        and   amh_secuencial = @w_secuencial
        
        if @@error != 0 
        begin
           PRINT 'caborhfm.sp  ---> Error eliminando ca_amortizacion_his'
        end

        delete ca_amortizacion_ant_his
        where anh_operacion =  @w_operacion
        and   anh_secuencial = @w_secuencial
        
        if @@error != 0 
        begin
           PRINT 'caborhfm.sp  ---> Error eliminando ca_amortizacion_his'
        end

        delete ca_cuota_adicional_his
        where cah_operacion =  @w_operacion
        and   cah_secuencial = @w_secuencial
        
        if @@error != 0 
        begin
           PRINT 'caborhfm.sp  ---> Error eliminando ca_cuota_adicional_his'
        end

        delete ca_acciones_his
        where ach_operacion =  @w_operacion
        and   ach_secuencial = @w_secuencial

        if @@error != 0 
        begin
           PRINT 'caborhfm.sp  ---> Error eliminando ca_acciones_his'
        end

        delete ca_valores_his
        where vah_operacion =  @w_operacion
        and   vah_secuencial = @w_secuencial

        if @@error != 0 
        begin
           PRINT 'caborhfm.sp  ---> Error eliminando ca_valores_his'
        end

        delete ca_dividendo_his
        where dih_operacion =  @w_operacion
        and   dih_secuencial = @w_secuencial

        if @@error != 0 
        begin
           PRINT 'caborhfm.sp  ---> Error eliminando ca_dividendo_his'
        end

        delete ca_rubro_op_his
        where roh_operacion =  @w_operacion
        and   roh_secuencial = @w_secuencial

        if @@error != 0 
        begin
           PRINT 'caborhfm.sp  ---> Error eliminando ca_rubro_op_his'
        end



        if exists (select * from ca_correccion_his
 	           where coh_operacion = @w_operacion)
        begin
          	delete ca_correccion_his
           where coh_operacion =  @w_operacion
           and   coh_secuencial = @w_secuencial

           if @@error != 0 
           begin
              PRINT 'caborhfm.sp  ---> Error eliminando ca_correccion_his'
           end
        end
  
  
  fetch transaccion_hfm into
   @w_operacion,
   @w_secuencial

end

close transaccion_hfm
deallocate transaccion_hfm


delete ca_transaccion
where tr_fecha_mov < @w_fecha
and   tr_tran = 'HFM'
and tr_ofi_usu > 0

return 0
go
