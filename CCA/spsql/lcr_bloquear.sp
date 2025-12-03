
/* ********************************************************************* */
/*      Archivo:                sp_lcr_bloquear.sp                     */
/*      Stored procedure:       sp_lcr_bloquear                        */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Disenado por:           Andy Gonzalez                            */
/*      Fecha de escritura:     01/10/2018                               */
/* ********************************************************************* */
/*                              IMPORTANTE                               */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      "MACOSA", representantes exclusivos para el Ecuador de la        */
/*      "NCR CORPORATION".                                               */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de sus          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de MACOSA o su representante.              */
/* ********************************************************************* */
/*                              PROPOSITO                                */
/*  Programa que maneja el mantenimientos de los Bloques LCR             */
/* ********************************************************************* */
USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_lcr_bloquear')
   drop proc sp_lcr_bloquear
go
create proc sp_lcr_bloquear

@s_user            login        = 'admuser',
@s_term            varchar(32)  = 'consola',
@s_date            datetime     = null ,
@s_ofi             int          = null,
@i_cliente         int          = null, 
@i_operacion       char(1),    -- I insercion  C consulta 
@i_bloqueo         char(1)      = null,    -- S si      N no 
@i_banco           cuenta
         

as

declare
@w_sp_name            varchar(32),
@w_fecha_proceso      datetime, 
@w_error              int , 
@w_commit             char(1) ,
@w_operacionca        int,
@w_est_vigente        int,
@w_est_vencido        int, 
@w_est_cancelado      int ,
@w_bloqueo            char(1),
@w_usuario_ult_mod    login ,
@w_fecha_ult_mod      datetime,
@w_registro           cuenta,
@w_utilizado          money ,
@w_msg                VARCHAR(255),
@w_fecha_des          datetime


declare @lcr_operacion table(
operacion       int          null,
cliente         int          null,
nombre          varchar(255) null,
registro        cuenta       null,
fecha_des       datetime     null,
fecha_fin       datetime     null,
cupo            money        null,
disponible      money        null,
bloqueo         char(1)      null,
usuario_ult_mod login        null,
fecha_ult_mod   datetime     null
)   

select 
@w_sp_name        = 'sp_lcr_bloquear',
@w_commit         = 'N' ,   
@w_fecha_proceso  = fp_fecha 
from cobis..ba_fecha_proceso    


select @w_fecha_proceso = isnull(@s_date, @w_fecha_proceso)




--estados cca
exec @w_error        = sp_estados_cca
@o_est_vigente       = @w_est_vigente    out,
@o_est_vencido       = @w_est_vencido    out,
@o_est_cancelado     = @w_est_cancelado  out  



--Fecha proceso
select @w_fecha_proceso =  fp_fecha
from cobis..ba_fecha_proceso


if @i_operacion = 'C' begin 

   select 
   @w_bloqueo         = 'N',
   @w_usuario_ult_mod = ''
   
   
   insert into @lcr_operacion
   select top 1
   operacion      = op_operacion,
   cliente        = op_cliente,
   nombre         = op_nombre,
   registro       =  convert(varchar, null),
   fecha_des      = null,
   fecha_fin      = op_fecha_fin,
   cupo           = op_monto_aprobado,
   disponible     = convert( money,0),
   bloqueo        = 'N',
   usuario_ult_mod= convert(varchar,null),
   fecha_ult_mod  = convert(datetime,null) 
   from ca_operacion 
   where op_toperacion = 'REVOLVENTE'
   and   op_banco        = @i_banco
   and @w_fecha_proceso between op_fecha_ini and op_fecha_fin 
   order by  op_operacion  

   if @@error <> 0 begin
      select 
	  @w_error =@w_error,
	  @w_msg   = 'ERROR: AL INSERTAR LCR EN TEMPORAL'
      goto ERROR
   end
   
   select @w_fecha_des = min (tr_fecha_ref)
   from @lcr_operacion, ca_transaccion, ca_det_trn
   where tr_operacion = operacion
   and tr_operacion   = dtr_operacion 
   and tr_secuencial  = dtr_secuencial
   and tr_tran        = 'DES'
   and tr_estado      <> 'RV'
   and tr_secuencial  >  0
   and dtr_concepto   = 'CAP'
   
   update @lcr_operacion
   set fecha_des = @w_fecha_des   
      
   if not exists (select 1 from @lcr_operacion where cliente  = @i_cliente ) begin 
      select 
 	  @w_error =700001,
	  @w_msg   = 'ERROR:LA LCR NO SE ENCUENTRA DENTRO DE LA FECHA DE VIGENCIA O NO EXISTE'
      goto ERROR
   end 
   
	  
   select @w_registro = isnull(max(rb_registro_id), 0)  
   from cob_credito..cr_b2c_registro,  @lcr_operacion
   where  rb_cliente = cliente
   
   select @w_utilizado = sum(am_cuota-am_pagado )
   from  ca_amortizacion ,   @lcr_operacion
   where am_operacion = operacion   
   and am_concepto    = 'CAP'
   
   select 
   @w_bloqueo         = lb_bloqueo,  
   @w_usuario_ult_mod = lb_usuario_ult_mod,    
   @w_fecha_ult_mod   = lb_fecha_ult_mod
   from ca_lcr_bloqueo,  @lcr_operacion 
   where operacion  = lb_operacion
   
   update  @lcr_operacion set 
   disponible      = cupo-@w_utilizado,
   registro        = @w_registro,
   bloqueo         = @w_bloqueo  ,
   usuario_ult_mod = @w_usuario_ult_mod,
   fecha_ult_mod   = @w_fecha_ult_mod 
   
   if @@error <> 0 begin
      select 
      @w_error =@w_error,
      @w_msg   = 'ERROR: AL INSERTAR LCR EN TEMPORAL'
      goto ERROR
   end
	  
   
   select  
   'ID. CLIENTE'         =  cliente,      
   'NOMBRE'              =  nombre,
   'FECHA DE ACTIVACION' =  fecha_des,
   'VENCIMIENTO'         =  fecha_fin,
   'REGISTRO'            =  registro,
   'CUPO'                =  cupo,      
   'DISPONIBLE'          =  disponible,     
   'BLOQUEO'             =  bloqueo,        
   'USUARIO ULT. MOD.'   =  usuario_ult_mod,
   'FECHA ULT. MOD.'     =  fecha_ult_mod 
    from   @lcr_operacion 
   
   
end 


if @i_operacion = 'I' begin 

   
   select 
   @w_operacionca = op_operacion 
   from ca_operacion 
   where 
   op_banco = @i_banco
   
   if @@rowcount = 0 begin
     select @w_error  = 70121
     goto ERROR
   end
 
    --INICIO ATOMICIDAD
   if @@trancount = 0 begin  
     select @w_commit = 'S'
     begin tran 
   end
   
   if exists (select 1 from ca_lcr_bloqueo where lb_operacion = @w_operacionca )begin 
      
	  update ca_lcr_bloqueo  set 
	  lb_bloqueo          =  @i_bloqueo,
	  lb_fecha_ult_mod   =  @w_fecha_proceso,
	  lb_usuario_ult_mod =  @s_user
	  where lb_operacion =  @w_operacionca
	  
	  if @@error <> 0 begin
         select 
		 @w_error   =@w_error,
		 @w_msg     = 'ERROR: AL ACTUALIZAR TABLA DE BLOQUEO'
         goto ERROR
      end
	  
      insert into ca_lcr_bloqueo_ts
      select @w_fecha_proceso, getdate(), @s_ofi, @s_term, @s_user,*
      from   ca_lcr_bloqueo  with (NOLOCK)
      where  lb_operacion = convert(int,@w_operacionca) 
   
      if @@error <> 0 begin
         select 
         @w_error   =@w_error,
         @w_msg     = 'ERROR: EN LA INSERTAR TABLAS DE AUDITORIA'
      end
	   
   end else begin 
   
      insert into ca_lcr_bloqueo ( 
      lb_operacion,   lb_bloqueo,   lb_fecha_ult_mod, lb_usuario_ult_mod )  
      values (
      @w_operacionca, @i_bloqueo ,  @w_fecha_proceso, @s_user            )
	  
	  if @@error <> 0 begin
		 select 
		 @w_error   =@w_error,
		 @w_msg     = 'ERROR: EN LA INSERTAR TABLAS DE BLOQUEO'
         goto ERROR
      end
      
         -- TRANSACCION DE SERVICIO 
      insert into ca_lcr_bloqueo_ts
      select @w_fecha_proceso, getdate(), @s_ofi, @s_term, @s_user,*
      from   ca_lcr_bloqueo with (NOLOCK)
      where  lb_operacion = convert(int,@w_operacionca) 
   
      if @@error <> 0 begin
         select 
         @w_error   =@w_error,
         @w_msg     = 'ERROR: EN LA INSERTAR TABLAS DE AUDITORIA'
      end
	  
	  
   end 

   if @w_commit = 'S'begin 
     select @w_commit = 'N'
     commit tran    
   end 
   
end 


RETURN 0

ERROR:


if @w_commit = 'S'begin 
   select @w_commit = 'N'
   rollback tran    
end 

exec cobis..sp_cerror
	@t_from = @w_sp_name,
	@i_num  = @w_error,
	@i_msg  = @w_msg

return @w_error

go

