/************************************************************************/
/*  Archivo:                        revgrup.sp                          */
/*  Stored procedure:               sp_reversa_grupal                   */
/*  Base de datos:                  cob_cartera                         */
/*  Producto:                       Cartera                             */
/************************************************************************/
/*                                  PROPOSITO                           */
/*  Realiza la busqueda de los pagos grupales mayores a una fecha       */
/*  para ejecutar su reversa grupal                                     */
/************************************************************************/ 
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reversa_grupal')
    drop proc sp_reversa_grupal
go

create proc sp_reversa_grupal
       @s_user                  login        = null,
       @s_term                  varchar(30)  = null,
       @s_srv                   varchar(30)  = null,  
       @s_date                  datetime     = null,
       @s_sesn                  int          = null,
       @s_ssn                   int          = null,
       @s_ofi                   smallint     = null,
       @s_rol		        smallint     = null,
       @i_banco                 cuenta,      --cuenta grupal padre
       @i_fecha                 datetime     --fecha de reversa
as
declare @w_sp_name              descripcion,
        @w_error                int,
        @w_operacionca          int,
        @w_secuencial_rev       int
     
select @w_sp_name = 'sp_reversa_grupal'

/* VALIDACIONES */

/* VERIFICAR EXISTENCIA DE OPERACION GRUPAL */
select @w_operacionca = op_operacion
from   ca_operacion                                                                                                                                                                                                                                    
where  op_banco = @i_banco    
                                                                                                                                                                                                                                                          
if @@rowcount = 0 return 701049

/* BUSCAR LOS PAGOS MAYORES A LA FECHA VALOR */
declare cursor_rev cursor for
select pg_secuencial_pago
from   ca_secuencial_pago_grupal
where  pg_operacion_pago   = @w_operacionca
and    pg_secuencial_pago >= 0
and    pg_fecha_ing       >= @i_fecha
and    pg_estado           = 'I'
order by pg_fecha_ing desc, pg_secuencial_pago desc
for read only
   
open  cursor_rev
fetch cursor_rev
into  @w_secuencial_rev

/* WHILE cursor_rev */
while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) 
   begin
      select @w_error = 71003
      goto ERROR
   end

   /* ATOMICIDAD POR TRANSACCION */
   begin tran
   
   /* APLICAR PROCESO DE REVERSA */
   exec @w_error           = sp_reversa_pago_grupal
        @s_user            = @s_user,
        @s_term            = @s_term,
        @s_srv             = @s_srv,  
        @s_date            = @s_date,
        @s_sesn            = @s_sesn,
        @s_ssn             = @s_ssn,
        @s_ofi             = @s_ofi,
        @s_rol             = @s_rol,
        @i_banco           = @i_banco,
        @i_secuencial_pago = @w_secuencial_rev --LPO @i_secuencial_pago

   if @w_error <> 0 
   begin
      close cursor_rev
      deallocate cursor_rev

      goto ERROR
   end

   /* ATOMICIDAD POR TRANSACCION */
   while @@trancount > 0 commit tran

   fetch cursor_rev
   into  @w_secuencial_rev

end /* WHILE cursor_rev */

close cursor_rev
deallocate cursor_rev
  

return 0
                                                                                                                                                                                                                                                      
ERROR:
while @@trancount > 0 rollback tran
                                                                                                                                                                                                                                                        
return @w_error
                                                                                                                                                                                                                                              
GO
