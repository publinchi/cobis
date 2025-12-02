

/************************************************************************/
/*  archivo:                lcr_renovar.sp                              */
/*  stored procedure:       sp_lcr_renovar                              */
/*  base de datos:          cob_cartera                                 */
/*  producto:               credito                                     */
/*  disenado por:           Andy Gonzalez                               */
/*  fecha de documentacion: Febrero 2019                                */
/************************************************************************/
/*          importante                                                  */
/*  este programa es parte de los paquetes bancarios propiedad de       */
/*  "macosa",representantes exclusivos para el ecuador de la            */
/*  at&t                                                                */
/*  su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  presidencia ejecutiva de macosa o su representante                  */
/************************************************************************/


use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_lcr_renovar')
	drop proc sp_lcr_renovar
go

  
create proc sp_lcr_renovar(
   @i_cliente       int,
   @i_banco         cuenta       = null,
   @i_msg_id        int          = null,
   @o_msg           varchar(200) = null output

)
as declare 
@w_fecha_proceso  datetime,
@w_commit         char(1),
@w_sp_name        varchar(100),
@w_error          int,
@w_msg            varchar(290),
@w_saldo          money,
@s_ssn            int, 
@s_user           login, 
@s_term           descripcion,
@s_date           datetime, 
@s_ofi            int,
@w_oficina        int,
@w_secuencial_ing int ,
@w_periodicidad   char(2),
@s_srv            varchar (30), 
@s_rol            int , 
@s_lsrv           varchar(30),
@s_sesn           int,
@w_operacionca    int,
@w_banco          cuenta ,
@w_cuenta         varchar(255),
@w_oficial        int,
@w_periodo_int    int,
@w_tdividendo     catalogo,
@w_factor         int,
@w_login          login,
@w_banco_nuevo    cuenta,
@w_tramite        int,
@w_est_cancelado  int,
@w_estado_proceso varchar(20),
@w_max_proc       int ,
@w_ciudad         int,
@w_monto_or      money ,
@w_num_renovacion int    



--INICIALIZACION DE VARIABLES 

select  @s_ssn  = convert(int,rand()*10000)

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso


exec sp_estados_cca 
@o_est_cancelado = @w_est_cancelado out 

select 
@s_user             ='usrbatch',
@s_srv              ='CTSSRV',
@s_term             ='batch-renovar',
@s_rol              = 3,
@s_lsrv             ='CTSSRV',
@w_sp_name          = 'sp_lcr_crearop_batch',
@s_sesn             = @s_ssn,
@s_date             = @w_fecha_proceso,
@w_commit           = 'N',
@w_saldo            = 0 ,
@w_tramite          = 0    




select  @w_max_proc = isnull(MAX(io_id_inst_proc),0) 
from cob_workflow..wf_inst_proceso 
where io_campo_4     = 'REVOLVENTE'
and   io_campo_1     = @i_cliente
and   io_codigo_proc = (select pa_tinyint FROM cobis..cl_parametro WHERE pa_nemonico = 'FLIREV' AND pa_producto = 'CCA')


--VERIFICA TRAMITE ASOC AL PRESTAMO 
select 
@w_tramite        = io_campo_3,
@w_estado_proceso = io_estado 
from   cob_workflow..wf_inst_proceso 
where io_id_inst_proc = @w_max_proc


--BUSCAR LA LCR A RENOVAR 

select
@w_operacionca      = op_operacion,
@w_banco            = op_banco,      --BANCO VIEJO
@w_oficina          = op_oficina,
@w_cuenta           = op_cuenta,
@w_oficial          = op_oficial ,
@w_periodo_int      = op_periodo_int, 
@w_tdividendo       = op_tdividendo ,
@w_ciudad           = op_ciudad ,
@w_monto_or         = op_monto              
from cob_cartera..ca_operacion
where op_toperacion = 'REVOLVENTE'
and op_cliente      = @i_cliente 
and op_banco        = @i_banco 
and @w_fecha_proceso between op_fecha_ini and op_fecha_fin

if @@rowcount = 0 begin 
   select 
   @w_error =700001,
   @w_msg   = 'ERROR: NO EXISTE LCR O NO SE ENCUENTRA EN VIGENCIA'
   GOTO ERROR_FIN 
end


--DETERMINAR LA PERIODICIDAD DE LA OPERACION ORIGINAL
select @w_factor  = td_factor
from   ca_tdividendo 
where  td_tdividendo = @w_tdividendo


--select @w_periodicidad = case when @w_factor*@w_periodo_int = 7   then 'W' 
--                              when @w_factor*@w_periodo_int = 14  then 'BW'
--							  when @w_factor*@w_periodo_int = 30  then 'M'
--                         else 'W' end							  

select @w_periodicidad = 'W'							  
if @w_factor*@w_periodo_int = 7
   select @w_periodicidad = 'W'
if @w_factor*@w_periodo_int = 14
   select @w_periodicidad = 'BW'
if @w_factor*@w_periodo_int = 30
   select @w_periodicidad = 'M'
   
--OFICIAL PARA LA CREACION DEL NUEVO LCR							 
select 
@w_login = fu_login
from cobis..cc_oficial,cobis..cl_funcionario
where oc_oficial = @w_oficial
and   oc_funcionario = fu_funcionario

if @@rowcount = 0 begin 
   select 
   @w_error =700003,
   @w_msg   = 'ERROR: NO EXISTE OFICIAL DE CREDITO ASOCIADO A LA LCR '
   GOTO ERROR_FIN 
end


--DETERMINAR EL SALDO           
select @w_saldo = case when isnull(sum(am_cuota- am_pagado),0) <0 then 0 else isnull(sum(am_cuota- am_pagado),0) end 
from  ca_amortizacion         
where am_operacion = @w_operacionca
and   am_estado    <> @w_est_cancelado

--INICIO ATOMICIDAD 
if @@trancount = 0 begin  
   select @w_commit = 'S'
   begin tran 
end


--MARCAR AL PRESTAMO VIEJO COMO RENOVABLE

update ca_operacion set 
op_renovacion  = 'S'
where op_banco = @w_banco 

if @@error <> 0 begin 
   select 
   @w_error = 70006,
   @w_msg   = 'ERROR: AL ACTUALIZAR LA LCR EN LA MARCA COMO RENOVABLE'
   GOTO ERROR_FIN 
end 



--CREAR LA LCR NUEVA  

EXEC @w_error = sp_lcr_crear
@s_ssn              = @s_ssn,
@s_ofi              = @w_oficina,
@s_user             = @w_login,
@s_sesn             = @s_ssn,
@s_term             = 'renovarlcr',
@s_date             = @w_fecha_proceso,
@i_cliente          = @i_cliente,     
@i_periodicidad     = @w_periodicidad,
@i_fecha_valor      = @w_fecha_proceso,
@i_renovar          = 'S',
@o_banco            = @w_banco_nuevo out  

if @w_error <> 0 begin
   select 
   @w_error = isnull(@w_error,70002),
   @w_msg   = 'ERROR: EL EJECUTAR PRECANCELACION LCR'
   GOTO ERROR_FIN                  
end     


--ACTUALIZAR AL BANCO NUEVO CON EL NUMERO DE TRAMITE NUEVO DE RENOVACION 
update ca_operacion set 
op_tramite     =  @w_tramite
where op_banco =  @w_banco_nuevo 

if @@error <> 0 begin 
   select 
   @w_error = 70008,
   @w_msg   = 'ERROR: AL ACTUALIZAR LA LCR CON EL NUEVO TRAMITE'
   GOTO ERROR_FIN 
end 

if @w_saldo > 0 begin
   --UTILIZACION POR EL VALOR DE RENOVACION QUE ES EL SALDO ANTERIOR
   exec @w_error= sp_lcr_desembolsar 
   @s_ssn              = @s_ssn,
   @s_ofi              = @w_oficina,
   @s_user             = @w_login,
   @s_sesn             = @s_ssn,
   @s_term             = @s_term,
   @s_srv              = 'renovarlcr',
   @s_date             = @w_fecha_proceso,
   @i_banco            = @w_banco_nuevo ,
   @i_forma_desembolso = 'RENOVACION',
   @i_cuenta           = @w_banco,
   @i_renovar          = 'S',   
   @i_monto            = @w_saldo,
   @o_msg              = @w_msg  out 
   
   if @w_error <> 0 begin 
      select  @w_msg  = isnull(@w_msg, 'ERROR EN LA EJECUCION DEL SP DE UTILIZACION' )
      select 
      @w_msg   = @w_msg,
      @w_error = @w_error 
      goto ERROR_FIN
      
   end 
end

if not exists ( select 1 from ca_operacion where op_banco = @w_banco and op_estado = @w_est_cancelado) begin
   select 
   @w_error = 70006,
   @w_msg   = 'ERROR: NO FUE POSIBLE CANCELAR LA OPERACION ANTERIOR '
   GOTO ERROR_FIN
end 


--ACTUALIZAR FECHA FIN  -1 ( PARA QUE NO SALGA EN LAS BUSQUEDAS )  OPERACION VIEJA
update ca_operacion set 
op_fecha_fin = dateadd(dd,-1,@w_fecha_proceso)
where op_operacion = @w_operacionca

if @@error <> 0 begin 
   select 
   @w_error = 70006,
   @w_msg   = 'ERROR: AL ACTUALIZAR FECHA FIN DE LA LCR'
   GOTO ERROR_FIN 
end  


if  @w_tramite  <> 0  and @w_estado_proceso = 'EJE' begin 
   --SACA DE LA ESTACION A LA SIGUIENTE ETAPA 
   exec @w_error=  sp_ejecuta_msg_ren_b2c
   @s_ssn             =  @s_ssn, 
   @s_user            =  @s_user,
   @s_sesn            =  @s_sesn,
   @s_term            =  @s_term,
   @s_date            =  @s_date,
   @s_srv             =  @s_srv,
   @s_lsrv            =  @s_lsrv,
   @s_ofi             =  @s_ofi,
   @i_cliente         = @i_cliente,      
   @i_banco           = @w_banco
   
   if @w_error <> 0 begin 
       select 
   	@w_msg   = 'ERROR Al MOVER A LA SIGUIENTE ESTACION' ,
   	@w_error =  @w_error 
   	goto ERROR_FIN
   end 

end 


--ACTUALIZAR AL BANCO NUEVO CON EL NUMERO DE TRAMITE NUEVO DE RENOVACION 

select @w_num_renovacion = isnull(op_num_renovacion,0)
from ca_operacion 
where op_banco = @w_banco 

update ca_operacion set 
op_oficina        =  @w_oficina,
op_oficial        =  @w_oficial,
op_ciudad         =  @w_ciudad ,
op_anterior       =  @w_banco,
op_num_renovacion =  @w_num_renovacion  +1
where op_banco =  @w_banco_nuevo 

if @@error <> 0 begin 
   select 
   @w_error = 70008,
   @w_msg   = 'ERROR: AL ACTUALIZAR LA LCR OFICIAL CIUDAD OFICINA '
   GOTO ERROR_FIN 
end 


insert into cob_credito..cr_op_renovar(
or_tramite        ,or_num_operacion     ,or_monto_original,  
or_saldo_original ,or_toperacion        ,or_login,
or_producto       ,or_finalizo_renovacion)
values(
@w_tramite       ,@w_banco            ,@w_monto_or,
@w_saldo         ,'REVOLVENTE'        ,@w_login,
'CARTERA','S')

if @@error <> 0 begin 
   select 
   @w_error = 70009,
   @w_msg   = 'ERROR: AL INSERTAR EN LA CR_OP_RENOVAR '
   GOTO ERROR_FIN 
end 



--FIN DE ATOMICIDAD 
if @w_commit = 'S'begin 
   select @w_commit = 'N'
   commit tran    
end 



return 0 

ERROR_FIN:

if @w_commit = 'S'begin 
   select @w_commit = 'N'
   rollback tran    
end 

exec cobis..sp_cerror
	@t_from = @w_sp_name,
	@i_num  = @w_error,
	@i_msg  = @w_msg

return @w_error
 