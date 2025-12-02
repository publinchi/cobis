/************************************************************************/
/*   Archivo:              fvalmas.sp                                   */
/*   Stored procedure:     sp_fval_masivo                               */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/************************************************************************/
/*              IMPORTANTE                                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA"                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*              PROPOSITO                                               */
/*   Este procedimiento permite dar mantenimiento a la tabla            */
/*   ca_fval_masivo. En esta tabla se almacena las operaciones que se   */
/*   aplicara fecha valor masivo                                        */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*      FECHA                 AUTOR                  RAZON              */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_fval_adelante')
           drop proc sp_fval_adelante
go


create proc sp_fval_adelante 
as
                                                                                                                                                                                                                                                            
declare
@w_estado          tinyint,
@w_estado_reg      char(1),
@w_sp_name         varchar(26),
@w_error           int,
@w_fecha_cierre    datetime,
@w_banco           cuenta,
@w_fecha_valor     datetime,
@w_secuencial_mig  int,
@w_op_operacion    int
                                                                                                                                                                                                                                                           
select @w_sp_name = 'sp_fval_adelante'

select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


while 1=1 begin

   set rowcount 1
   
   update  ca_fval_masivo set
   @w_banco      = fm_banco,
   @w_fecha_valor = fm_fecha_valor,
   fm_estado     = 'P'
   where fm_estado = 'I'
   
   if @@rowcount = 0 begin
      set rowcount 0
      break
   end 
   
   set rowcount 0

   print '...ejecutando..' + cast(@w_banco as varchar)
   waitfor delay '00:00:01'    --- quitar para esta noche
   

   exec @w_error   = sp_fecha_valor
   @s_date         = @w_fecha_cierre,
   @s_lsrv         = 'CONSOLA',
   @s_ofi          = 1,
   @s_ssn          = 1,
   @s_srv          = 'BATCH',
   @s_term         = 'CONSOLA',
   @s_user         = 'repro',
   @i_fecha_valor  = @w_fecha_valor,
   @i_banco        = @w_banco,
   @i_operacion    = 'F',  
   @i_observacion  = 'FECHA VALOR REPROCEO Enero 01-2010',
   @i_en_linea     = 'N'
                                                                                                                                                                                                                                                          
   if @w_error <> 0  goto ERROR
   
   /*EJECUTA HASTA LA FECHA DE PROCESO*/
   exec @w_error   = sp_fecha_valor    --quitar para esta noche
   @s_date         = @w_fecha_cierre,
   @s_lsrv         = 'CONSOLA',
   @s_ofi          = 1,
   @s_ssn          = 1,
   @s_srv          = 'BATCH',
   @s_term         = 'CONSOLA',
   @s_user         = 'repro',
   @i_fecha_valor  = @w_fecha_cierre,
   @i_banco        = @w_banco,
   @i_operacion    = 'F',  
   @i_observacion  = 'FECHA VALOR REPROCEO Enero 01-2010',
   @i_en_linea     = 'N'
                                                                                                                                                                                                                                                          
   if @w_error <> 0  goto ERROR 

   goto SIGUIENTE   
   
   ERROR:
   exec sp_errorlog 
   @i_fecha      = @w_fecha_cierre,
   @i_error      = @w_error, 
   @i_usuario    = 'repro',
   @i_tran       = 7999,
   @i_tran_name  = @w_sp_name,
   @i_cuenta     = @w_banco,
   @i_rollback   = 'S'

   update  ca_fval_masivo set
   fm_estado     = 'X'
   where fm_banco = @w_banco
                                                                                                                                                                                                                                                      
                                                                                                                                                                                                                                                          
   SIGUIENTE:
   
end 
                                                                                                                                                                                                                                                             
return 0
go
                                                                                                                                                                                                                                                      

                                                                                                                                                                                                                                                              

                                                                                                                                                                                                                                                              
