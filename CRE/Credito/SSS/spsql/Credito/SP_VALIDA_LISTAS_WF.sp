
use cobis 
go
IF OBJECT_ID ('SP_VALIDA_LISTAS_WF') IS NOT NULL
	DROP PROCEDURE SP_VALIDA_LISTAS_WF
GO
create procedure SP_VALIDA_LISTAS_WF( 
         @s_ssn        int         = null,
	     @s_ofi        smallint,
	     @s_user       login,
         @s_date       datetime,
	     @s_srv		   varchar(30) = null,
	     @s_term	   descripcion = null,
	     @s_rol		   smallint    = null,
	     @s_lsrv	   varchar(30) = null,
	     @s_sesn	   int 	       = null,
	     @s_org		   char(1)     = NULL,
		 @s_org_err    int 	       = null,
         @s_error      int 	       = null,
         @s_sev        tinyint     = null,
         @s_msg        descripcion = null,
         @t_rty        char(1)     = null,
         @t_trn        int         = null,
         @t_debug      char(1)     = 'N',
         @t_file       varchar(14) = null,
         @t_from       varchar(30)  = null,
         --variables
		
		 @i_id_inst_proc int,    --codigo de instancia del proceso
		 @i_id_inst_act  int,    
	   	 @i_id_empresa   int, 
		 @o_id_resultado  smallint  out
) 
as 
declare @w_ofi            smallint, 
        @w_tramite        int,
	    @w_producto       varchar(10),
		@w_cuenta		  varchar(30),		
        @w_return         int,
        @w_sp_name        varchar(64),
        @w_est_novigente  int,
		@w_error          int


select @w_sp_name = 'SP_VALIDA_LISTAS_WF'
        
select  @w_return         = 0,
        @o_id_resultado   = 0,
        @w_est_novigente  = 0

/****** Consultar oficina y tramite ******/
select @w_ofi = io_oficina_inicio, 
       @w_tramite = io_campo_3 
from cob_workflow..wf_inst_proceso 
where io_id_inst_proc = @i_id_inst_proc 

select @w_cuenta = op_banco, @w_producto = 7--producto cartera
from cob_cartera..ca_operacion
where op_tramite = @w_tramite 

exec @w_return = cobis..sp_validacion_listas_externas 
     --@s_ofi     = @w_ofi, 
     @s_user    = @s_user , 
     @s_date    = @s_date, 
     @i_operacion = 'T',
	 @i_producto = @w_producto,
	 @i_cuenta   = @w_cuenta,
	 @i_proceso  = @i_id_inst_proc

IF @w_return <> 0 
    BEGIN 
        SELECT @o_id_resultado = 2 -- Error 
        exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_return
        return @w_return      
    END
    
select @o_id_resultado = 1 
return 0	

go

