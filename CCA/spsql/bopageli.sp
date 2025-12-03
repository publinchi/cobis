/************************************************************************/
/*   Archivo:             bopageli.sp                                   */
/*   Stored procedure:    sp_borra_pag_estado_e                         */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        EPB                                           */
/*   Fecha de escritura:  ENE-2002                                      */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                                PROPOSITO                             */
/*   Elimina los pagos que han quedado en estado E                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      OCT-2005       Elcira Pelaez  Cambios para el BAC               */
/************************************************************************/


use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_borra_pag_estado_e')
   drop proc sp_borra_pag_estado_e
go

create proc sp_borra_pag_estado_e 
as
declare   
@w_sp_name         varchar(32),
@w_operacionca                  int,
@w_secuencial_ing               int,
@w_registros                    int,
@w_secuencial_pag               int,
@w_no                           int


--- Captura nombre de Stored Procedure  
  select   @w_sp_name = 'sp_borra_pag_estado_e'



   select @w_registros = count(*)
   from ca_abono
   where ab_estado = 'E'
  


   select @w_registros = 0
   
   declare pago_eliminado  cursor for
   select 
   ab_operacion,
   ab_secuencial_ing,
   ab_secuencial_pag
   from ca_abono
   where ab_estado = 'E'
   and   ab_secuencial_pag = 0
   for read only

   open pago_eliminado
   fetch pago_eliminado into
   @w_operacionca,
   @w_secuencial_ing,
   @w_secuencial_pag

      while (@@fetch_status = 0 )
       begin

         if @@fetch_status = -1 
         begin    
            print 'bopageli.sp -->  error en el cursor...pago_eliminado .' 
         end





       if exists (select 1 from ca_transaccion,ca_abono
                  where tr_operacion = @w_operacionca
                  and  tr_secuencial = @w_secuencial_pag
                  and tr_tran = 'PAG')  
                  
                  select @w_no = 1
      else 
      begin

        delete ca_abono
        where ab_operacion =  @w_operacionca
        and   ab_secuencial_ing = @w_secuencial_ing
        and   ab_estado = 'E'
        if @@error != 0 
        begin
           PRINT 'bopageli.sp  ---> Error eliminando ca_abono en estado E'
        end

        delete ca_abono_det
        where abd_operacion =  @w_operacionca
        and   abd_secuencial_ing = @w_secuencial_ing
        if @@error != 0 
        begin
           PRINT 'bopageli.sp  ---> Error eliminando ca_abono_det'
        end

        delete ca_abono_prioridad
        where ap_operacion =  @w_operacionca
        and   ap_secuencial_ing = @w_secuencial_ing
        if @@error != 0 
        begin
           PRINT 'bopageli.sp  ---> Error eliminando ca_abono_prioridad'
        end        

        select @w_registros = @w_registros + 1
    end



  fetch pago_eliminado into
   @w_operacionca,
   @w_secuencial_ing,
   @w_secuencial_pag

end

close pago_eliminado
deallocate pago_eliminado



return 0

go


