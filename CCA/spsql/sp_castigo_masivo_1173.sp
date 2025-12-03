use cob_cartera
go

set ansi_warnings off
go

if exists(select 1 from sysobjects where name = 'sp_castigo_masivo_1173')
   drop proc sp_castigo_masivo_1173
go

create proc sp_castigo_masivo_1173
@s_user          varchar(30) = null,
@s_term          varchar(30) = null,
@s_date          datetime    = null,
@s_ofi           int         = null,
@i_banco         cuenta      = null,
@i_estado        int         = null,
@i_cliente       int         = null,
@i_acta          catalogo    = null,
@i_causal        catalogo    = null,
@i_fecha_proceso datetime    = null
as

declare
@w_error          int,
@w_fecha_proceso  datetime,
@w_msg            varchar(250),
@w_est_castigado  int,
@w_ssn            int
   
/*INCIAR VARIABLES DE TRABAJO */   
select 
@w_error  = 0

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_castigado  = @w_est_castigado out

    
if @i_estado = @w_est_castigado begin
   select 
   @w_error = 710001, 
   @w_msg = 'OPERACION YA CASTIGADA'
   goto ERROR1
end

exec @w_ssn = sp_gen_sec
     @i_operacion = -3

select @w_ssn = @w_ssn * -1
   
   /* SOLO PARA CASTIGOS MASIVOS, REGISTRAR EL CASTIGO EN COBRANZAS Y INGRESAR EL CLIENTE EN LA LISTA INHIBITORIA */
   if  not exists(select 1 from cob_credito..cr_concordato
                  where cn_cliente   = @i_cliente
                  and   cn_situacion = 'CAS')
   begin
      exec @w_error = cob_credito..sp_concordato 
      @s_date                 = @s_date,  
      @s_user                 = @s_user,
      @s_ssn                  = @w_ssn,
      @s_sesn                 = 1,
      @s_term                 = @s_term,
      @s_srv                  = 'CobisSrv',
      @s_lsrv                 = null,
      @s_ofi                  = @s_ofi,
      @i_operacion            = 'I',
      @t_trn                  = 7999,
      @t_rty                  = '',                
      @i_cliente              = @i_cliente,        
      @i_situacion            = 'CAS',             
      @i_estado               = null,              
      @i_fecha                = null,              
      @i_fecha_fin            = null,              
      @i_cumplimiento         = null,              
      @i_situacion_anterior   = null,              
      @i_acta_cas             = @i_acta,           
      @i_fecha_cas            = @i_fecha_proceso,  
      @i_causal               = @i_causal,
      @i_en_linea             = 'N',
      @o_msg                  = @w_msg out         
       
      if @w_error <> 0 goto ERROR1
      if  (@@error <> 0 )
      begin
          PRINT 'error ejecutando sp cob_credito..sp_concordato  para @w_cliente  ' + cast (@i_cliente as varchar)
	      select @w_error = 708201
	      goto ERROR1
      end
   end
     
   exec @w_error = sp_cambio_estado_op_1173
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_banco          = @i_banco,
   @i_fecha_proceso  = @i_fecha_proceso,
   @i_estado_ini     = @i_estado,
   @i_estado_fin     = @w_est_castigado,
   @i_tipo_cambio    = 'C',
   @i_front_end      = 'N',
   @i_en_linea       = 'N',
   @o_msg            = @w_msg out
   if @w_error <> 0 
      goto ERROR1
        
   update ca_castigo_masivo set    
   cm_estado = 'P'
   where  cm_banco = @i_banco
   
   
   ERROR1:
   begin
      select @w_msg = 'CASTIMAS : ' + @w_msg
      
      insert into ca_errorlog(
      er_fecha_proc, er_error,     er_usuario,
      er_tran,       er_cuenta,    er_descripcion,
      er_anexo)
      values (
      @s_date,      @w_error,     @s_user,
      0,            @i_banco,     @w_msg,
      '')
   end   
   
return 0

go


