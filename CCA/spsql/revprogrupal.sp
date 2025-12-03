/************************************************************************/
/*  Archivo:                        revprogrupal.sp                     */
/*  Stored procedure:               sp_reversa_prorroga_grupal          */
/*  Base de datos:                  cob_cartera                         */
/*  Producto:                       Cartera                             */
/************************************************************************/
/*                                  PROPOSITO                           */
/*  Realiza la reversa de las prorrogas de un operacion grupal y        */
/*  sus operaciones interciclos                                         */
/************************************************************************/ 
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reversa_prorroga_grupal')
    drop proc sp_reversa_prorroga_grupal
go

create proc sp_reversa_prorroga_grupal
       @s_user                  login        = null,
       @s_term                  varchar(30)  = null,
       @s_srv                   varchar(30)  = null,  
       @s_date                  datetime     = null,
       @s_sesn                  int          = null,
       @s_ssn                   int          = null,
       @s_ofi                   smallint     = null,
       @s_rol		            smallint     = null,
       @i_banco                 cuenta,                  --cuenta grupal padre
       @i_secuencial_prorroga   int          = null,     --secuencial de la prorroga
       @i_secuencial_ing        int          = null
as
declare @w_sp_name              descripcion,
        @w_error                int,
        @w_operacionca          int,
        @w_estado               CHAR(1), --tinyint,
        @w_operacion_rev        int,
        @w_banco_rev            cuenta,
        @w_secuencial_ing       int,
        @w_secuencial_rev       int
     
select @w_sp_name = 'sp_reversa_prorroga_grupal'

/* VALIDACIONES */

/* VERIFICAR EXISTENCIA DE OPERACION GRUPAL */
select @w_operacionca       = op_operacion
from   ca_operacion                                                                                                                                                                                                                                    
where  op_banco = @i_banco    
                                                                                                                                                                                                                                                          
if @@rowcount = 0 return 701049

if @i_secuencial_prorroga is null
begin
   /* OBTENER EL SECUENCIAL DEL PAGO */
   select @i_secuencial_prorroga = pg_secuencial_prorroga
   from   ca_secuencial_prorroga_grupal
   where  pg_operacion_prorroga = @w_operacionca
   and    pg_operacion          = @w_operacionca
   and    pg_secuencial         = @i_secuencial_ing 
end

/* VERIFICAR ESTADO DE LA TRANSACCION DEL PAGO GRUPAL */
select @w_estado = pg_estado
from   ca_secuencial_prorroga_grupal
where  pg_operacion_prorroga   = @w_operacionca
and    pg_secuencial_prorroga  = @i_secuencial_prorroga

if @w_estado <> 'I' return 701191

/* ATOMICIDAD POR TRANSACCION */
begin tran

/* EJECUTAR EL PROCESO DE REVERSA DE LOS PAGOS ASOCIADOS */
declare cursor_reversa cursor for
select pg_operacion, pg_banco, pg_secuencial
from   ca_secuencial_prorroga_grupal
where  pg_operacion_prorroga   = @w_operacionca
and    pg_secuencial_prorroga  = @i_secuencial_prorroga
for read only
   
open  cursor_reversa
fetch cursor_reversa
into  @w_operacion_rev, @w_banco_rev, @w_secuencial_rev

/* WHILE cursor_reversa */
while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) 
   begin
      select @w_error = 71003
      goto ERROR
   end
   /* APLICAR PROCESO DE REVERSA */
   exec @w_error          = sp_fecha_valor
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @s_sesn           = @s_sesn,
        @s_ssn            = @s_ssn,
        @s_srv            = @s_srv,
        @s_term           = @s_term,
        @s_user           = @s_user,
        @t_trn            = 7049,
        @i_operacion      = 'R',
        @i_banco          = @w_banco_rev,
        @i_secuencial     = @w_secuencial_rev,
        @i_control_pinter = 'N',
        @i_observacion    = 'REVERSA PRORROGA GRUPAL'

   if @w_error <> 0 
   begin
      close cursor_reversa 
      deallocate cursor_reversa

      goto ERROR
   end

   /* ACTUALIZAR EL ESTADO DE LOS PAGOS */
   update ca_secuencial_prorroga_grupal
   set    pg_estado = 'R'
   where  pg_operacion_prorroga   = @w_operacionca
   and    pg_secuencial_prorroga  = @i_secuencial_prorroga
   and    pg_operacion            = @w_operacion_rev
   and    pg_secuencial           = @w_secuencial_rev

   if @@error <> 0 
   begin
      close cursor_reversa 
      deallocate cursor_reversa
  
      select @w_error = 710002
      goto ERROR
   end

   fetch cursor_reversa 
   into  @w_operacion_rev, @w_banco_rev, @w_secuencial_rev

end /* WHILE cursor_reversa */

close cursor_reversa
deallocate cursor_reversa


--AGC. 10SEP19. Actualizar hijas
exec @w_error = cob_cartera..sp_actualiza_hijas
     @i_banco = @i_banco

if @w_error <> 0 
   goto ERROR
  
/* ATOMICIDAD POR TRANSACCION */
while @@trancount > 0 commit tran

return 0
                                                                                                                                                                                                                                                      
ERROR:
while @@trancount > 0 rollback tran
                                                                                                                                                                                                                                                        
return @w_error
                                                                                                                                                                                                                                              
