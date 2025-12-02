
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_fval_masivo_dobles')
   drop proc sp_fval_masivo_dobles
go

create proc sp_fval_masivo_dobles 

as
declare
   @w_estado         tinyint,
   @w_estado_reg     char(1),
   @w_sp_name        varchar(26),
   @w_error          int,
   @w_fecha_cierre   datetime,
   @w_banco          cuenta,
   @w_fecha_valor      datetime

select @w_sp_name = 'sp_fval_masivo_dobles'



   select @w_fecha_cierre = fc_fecha_cierre
   from cobis..ba_fecha_cierre
   where fc_producto = 7

   --Definir un cursor de las operaciones  a aplicar fecha valor

   declare cur_operacion cursor for
   select fm_banco, fm_fecha_valor
   from cob_cartera..ca_fval_masivo
   where fm_estado = 'I'
   for read only

   open cur_operacion
   fetch cur_operacion into @w_banco, @w_fecha_valor

   while @@fetch_status = 0
   begin
      print 'REVISADAS @w_banco '+ cast (@w_banco as varchar)
      exec @w_error = sp_fecha_valor
           @s_date        = @w_fecha_cierre,
           @s_lsrv	      = 'BATCH',
           @s_ofi         = 1,
           @s_ssn         = 1,
           @s_srv         = 'BATCH',
           @s_term        = 'CONSOLA',
           @s_user        = 'batch',
           @i_fecha_valor = @w_fecha_valor,
           @i_banco       = @w_banco,
           @i_operacion   = 'F',  
           @i_observacion = 'FECHA VALOR MASIVO',
           @i_en_linea    = 'N'


      if @w_error <> 0
      begin
         exec sp_errorlog 
              @i_fecha      = @w_fecha_cierre,
              @i_error      = @w_error, 
              @i_usuario    = 'batch',
              @i_tran       = 7999,
              @i_tran_name  = @w_sp_name,
              @i_cuenta     = @w_banco,
              @i_rollback   = 'S'
     
         while @@trancount > 0 rollback
 	 goto SIGUIENTE
      end

         update cob_cartera..ca_fval_masivo
	     set fm_estado = 'P'
	     where fm_banco = @w_banco

	     goto SIGUIENTE

       SIGUIENTE:
      fetch cur_operacion 
     into @w_banco, 
          @w_fecha_valor
    end --cursor


return 0


go

