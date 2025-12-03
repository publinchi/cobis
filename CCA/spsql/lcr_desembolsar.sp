/************************************************************************/
/*  archivo:                lcr_desembolsar.sp                          */
/*  stored procedure:       sp_lcr_desembolsar                          */
/*  base de datos:          cob_cartera                                 */
/*  producto:               credito                                     */
/*  disenado por:           Andy Gonzalez                               */
/*  fecha de documentacion: Noviembre 2018                              */
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
/*          proposito                                                   */
/*             Desembolso de la LCR                                     */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/*    14/Nov/2018           AGO              Emision Inicial            */
/************************************************************************/

use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_lcr_desembolsar')
	drop proc sp_lcr_desembolsar
go



create proc sp_lcr_desembolsar(
   @s_ssn              int           = null,
   @s_ofi              smallint,
   @s_user             login,
   @s_date             datetime,
   @s_srv              varchar(30)   = null,
   @s_term             descripcion   = null,
   @s_rol              smallint      = null,
   @s_lsrv             varchar(30)   = null,
   @s_sesn             int           = null,
   @s_org              char(1)       = null,
   @s_org_err          int           = null,
   @s_error            int           = null,
   @s_sev              tinyint       = null,
   @s_msg              descripcion   = null,
   @t_rty              char(1)       = null,
   @t_trn              int           = null,
   @t_debug            char(1)       = 'N',
   @t_file             varchar(14)   = null,
   @t_from             varchar(30)   = null,
   --OBLIGATORIOS PARA EL SERVICIO
   @i_canal            catalogo      = 'B2C',
   @i_banco            cuenta        ,
   @i_monto            money         ,
   @i_renovar          char(1)       = 'N',
   --NO OBLIGATORIOS SOLOPAPA PRUEBAS
   @i_forma_desembolso catalogo      = 'NC_BCO_MN',
   @i_cuenta           cuenta        = null ,    
   @i_en_linea         char(1)       = 'N',  
   @i_fecha_valor      datetime      = null,    --PARA PRUEBAS DE DESEMBOLSO
   --MENSAJE DE ERROR  
   @o_msg             varchar(255)    = null out

)as 
declare 
@w_msg            varchar(255),
@w_error          int,
@w_commit         char(1),
@w_est_cancelado  int,
@w_fecha_proceso  datetime,
@w_operacionca    int ,
@w_est_vencido    int ,
@w_est_vigente    int ,
@w_cliente        int,
@w_nombre         varchar(255),
@w_oficina        int,
@w_moneda         int ,
@w_resultado      varchar(24),
@w_fecha_inimax   datetime,
@w_fecha_ini      datetime,
@w_fecha_fin      datetime,
@w_sp_name        descripcion,
@w_fecha_valor    datetime,
@w_monto_aprobado money,
@w_monto_op       money,
@w_saldo_cap      money,
@w_max_dividendo  int,
@w_est_novigente  int ,
@w_valor_variable_regla     varchar(255),
@w_resultado_com            varchar(200),
@w_porcentaje_com           float,
@w_numdec        int ,
@w_desembolso    money,
@w_cuenta        cuenta ,
@w_id_canal      int,
@w_fecha_ult_proceso datetime,
@w_secuencial    int,
@w_desembolso_min  money,
@w_resultado_des  varchar(64),
@w_inst_proceso   int,
@w_tramite        int,
@w_max_fecha_can  datetime ,
@w_saldo_ini      money,
@w_estado         int,
@w_fecha_pri_cuot      datetime 


select 
@w_sp_name = 'sp_lcr_desembolsar',
@w_commit  = 'N'

exec sp_estados_cca 
@o_est_cancelado = @w_est_cancelado out ,
@o_est_vencido   = @w_est_vencido   out ,
@o_est_vigente   = @w_est_vigente   out ,
@o_est_novigente = @w_est_novigente out

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

--1.- Validacion de la operacion 
select 
@w_operacionca       = op_operacion, 
@w_monto_aprobado    = op_monto_aprobado,
@w_cliente           = op_cliente,
@w_nombre            = op_nombre,
@w_oficina           = op_oficina,
@w_moneda            = op_moneda,
@w_monto_op          = op_monto,
@w_fecha_ini         = op_fecha_ini,
@w_fecha_fin         = op_fecha_fin,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_tramite           = op_tramite ,
@w_estado            = op_estado
from ca_operacion 
where op_banco = @i_banco 

if @@rowcount = 0 begin 
   select  
   @w_msg  = 'ERROR:EL CLIENTE NO TIENE UNA LINEA DE CREDITO APROBADA ',
   @w_error= 70001
   goto ERROR_FIN
end 


if exists (select 1  from ca_lcr_bloqueo where lb_operacion = @w_operacionca and lb_bloqueo = 'S') begin 

   select  
   @w_msg  = 'ERROR:LA LCR SE ENCUENTRA BLOQUEADA',
   @w_error= 70002
   goto ERROR_FIN

end 

select @w_fecha_valor = case  @w_estado when @w_est_cancelado then @w_fecha_proceso else @w_fecha_ult_proceso end 

if  @w_estado = @w_est_cancelado select @w_fecha_valor = isnull(@i_fecha_valor ,@w_fecha_valor)

--DETERMINAR INSTANCIA DE PROCESO
select @w_inst_proceso = io_id_inst_proc
from   cob_workflow..wf_inst_proceso
where  io_campo_3 = @w_tramite


select @w_cuenta = ea_cta_banco
from cobis..cl_ente_aux 
where ea_ente  = @w_cliente

select @w_cuenta = isnull( @i_cuenta , @w_cuenta) 

select 
@w_id_canal            = co_id
from  ca_corresponsal 
where co_nombre        = @i_canal 
and   co_estado        = 'A'

exec @w_error = sp_decimales
@i_moneda      = @w_moneda ,
@o_decimales   = @w_numdec out

--2.- Validacion de fecha de Vigencia 
if (@w_fecha_valor < @w_fecha_ini or @w_fecha_valor >@w_fecha_fin )begin
   select  
   @w_msg  = 'ERROR:LA OPERACION NO SE ENCUENTRA DENTRO DE LA FECHA DE VIGENCIA',
   @w_error= 70002
   goto ERROR_FIN

end 



select @w_saldo_cap    = isnull(sum(am_acumulado -am_pagado ),0) 
from ca_amortizacion 
where am_operacion     = @w_operacionca
and   am_concepto      = 'CAP'

--3.- Validacion del monto aprobado
if (@w_saldo_cap + @i_monto > @w_monto_aprobado) begin 
   select  
   @w_msg  = 'ERROR:LA LINEA DE CREDITO DEL CLIENTE NO TIENE SALDO SUFICIENTE PARA CUBRIR LA PRESENTE UTILIZACION',
   @w_error= 70003
   goto ERROR_FIN
end 

--4.- Verificacion si el dividendo está vencido
if exists( select 1 from ca_dividendo where di_operacion = @w_operacionca and di_estado = @w_est_vencido) begin 
   select  
   @w_msg  = 'ERROR: LA LINEA DE CREDITO DEL CLIENTE NO TIENE SALDO SUFICIENTE PARA CUBRIR LA PRESENTE UTILIZACION',
   @w_error= 70004
   goto ERROR_FIN
end 

--5.- Controlsi hubo saldo vencido , posterior debió estar en saldo 0

select @w_max_fecha_can = isnull(max(di_fecha_can),'01/01/1900')
from ca_dividendo 
where di_operacion = @w_operacionca
and   di_estado    = @w_est_cancelado
and   di_fecha_can > di_fecha_ven


if (@w_max_fecha_can <> '01/01/1900')begin 


   --determinar saldo incial con que parte la cuota 
   select 
   @w_saldo_ini = sum(case tr_tran when 'DES' then dtr_monto else -1*dtr_monto end)
   from ca_transaccion, ca_det_trn
   where tr_operacion  = dtr_operacion 
   and   tr_secuencial = dtr_secuencial
   and   tr_fecha_ref  < @w_max_fecha_can
   and   tr_tran  in ('PAG', 'DES')
   and   dtr_concepto = 'CAP'
   and   tr_estado <> 'RV'
   and   tr_secuencial >0
   and   tr_operacion = @w_operacionca 

   select 
   fecha    = co_fecha_ini,
   saldo    =0
   into #saldos_inicial
   from cob_conta..cb_corte 
   where co_empresa = 1
   and co_fecha_ini between @w_max_fecha_can and @w_fecha_ult_proceso


    --determinar saldo incial con que parte la cuota 
   select 
   fechatr = tr_fecha_ref,
   monto = sum(case tr_tran when 'DES' then dtr_monto else -1*dtr_monto end)
   into #transacciones
   from ca_transaccion, ca_det_trn
   where tr_operacion  = dtr_operacion 
   and   tr_secuencial = dtr_secuencial
   and   tr_fecha_ref  between @w_max_fecha_can  and @w_fecha_ult_proceso
   and   tr_tran  in ('DES', 'PAG')
   and   tr_estado <> 'RV'
   and   tr_secuencial >0
   and   dtr_concepto = 'CAP'
   and   tr_operacion = @w_operacionca 
   group by tr_fecha_ref
   
   insert into #transacciones values (@w_max_fecha_can ,@w_saldo_ini) --REGISTRO PARA RESUMIR EL SALDO INICIAL 
   
   select 
   fecha    = fecha,
   saldo    = sum(saldo+monto)
   into #saldos_diarios 
   from #transacciones,#saldos_inicial
   where fecha >=fechatr
   group by fecha
   
   if not exists (select 1 from #saldos_diarios where saldo = 0) begin 
      
	  select  
      @w_msg  = 'ERROR: EXISTEN CUOTAS CON PAGO IMPUNTUAL, EL CLIENTE DEBE PAGAR LA TOTALIDAD DE LA LCR',
      @w_error= 70004
      goto ERROR_FIN
   
   end 
   
end 


--si es que hay desembolso a fecha valor, llevar el prestamo a esa fecha y desembolsar.

--1.-  Si está canceladdo -Actualizar el ca_operacion, ca_dividendo , ca_amortizacion a VIGENTE , caso contrario no 
--determinar la cuota balon
select @w_max_dividendo = max(di_dividendo) , @w_fecha_inimax = max(di_fecha_ini) 
from   ca_dividendo
where  di_operacion =@w_operacionca



if @w_inst_proceso is not null begin 

   --EJECUCION DE LA REGLA DE PORCENTAJE DE COMISION 
   select @w_valor_variable_regla = convert(varchar,@i_monto)   
   exec @w_error           = cob_cartera..sp_ejecutar_regla
   @s_ssn                  = @s_ssn,
   @s_ofi                  = @s_ofi,
   @s_user                 = @s_user,
   @s_date                 = @w_fecha_proceso,
   @s_srv                  = @s_srv,
   @s_term                 = @s_term,
   @s_rol                  = @s_rol,
   @s_lsrv                 = @s_lsrv,
   @s_sesn                 = @s_ssn,
   @i_regla                = 'LCRPORCOM', 
   @i_tipo_ejecucion       = 'REGLA', 
   @i_valor_variable_regla = @w_valor_variable_regla,	 
   @i_id_inst_proc         = @w_inst_proceso,
   @o_resultado1           = @w_resultado_com out
   
   if @w_error <> 0 begin 
      select 
      @w_msg  = 'ERROR: AL EJECUTAR LA REGLA DE COMISION' ,
      @w_error= 70005
      goto ERROR_FIN   
   end
   
   select @w_porcentaje_com = isnull(convert(float,@w_resultado_com),3.0)
   
   --REGLA DE MONTO MIN DE DESEMBOLSO
   
   --select @w_valor_variable_regla = convert(varchar,@w_cliente)   
   exec @w_error           = cob_cartera..sp_ejecutar_regla
   @s_ssn                  = @s_ssn,
   @s_ofi                  = @s_ofi,
   @s_user                 = @s_user,
   @s_date                 = @w_fecha_proceso,
   @s_srv                  = @s_srv,
   @s_term                 = @s_term,
   @s_rol                  = @s_rol,
   @s_lsrv                 = @s_lsrv,
   @s_sesn                 = @s_ssn,
   @i_regla                = 'LCRMMUTI', 
   @i_tipo_ejecucion       = 'WORKFLOW',	 
   @i_id_inst_proc         = @w_inst_proceso,
   @o_resultado1           = @w_resultado_des out
   
   if @w_error <> 0 begin 
      select 
      @w_msg  = 'ERROR: AL EJECUTAR LA REGLA DE MONTO MIN' ,
      @w_error= 70005
      goto ERROR_FIN   
   end
   select @w_desembolso_min = isnull(convert(money,@w_resultado_des),100)
   
end else begin
   select  
   @w_porcentaje_com = 3.0,
   @w_desembolso_min = 100

end   
   
  

--5.- VERIFICACION DE MONTO MIN DE DISPERSION 

if (@i_renovar = 'N' and @i_monto < @w_desembolso_min) begin 

   select  
   @w_msg  = 'ERROR:  EL MONTO A DISPERSAR DEBE SER SUPERIOR A: '+convert(varchar,@w_desembolso_min),
   @w_error= 70006
   goto ERROR_FIN
end 


--NUEVA TRANSACCION DE CUUOTAMIN GCM  
exec @w_secuencial  = sp_gen_sec
@i_operacion        = @w_operacionca

-- OBTENER RESPALDO ANTES DE la GCM
exec @w_error  = sp_historial
@i_operacionca  = @w_operacionca,
@i_secuencial   = @w_secuencial  


if @@trancount = 0 begin  
   select @w_commit = 'S'
   begin tran 
end  


if not exists ( select 1 from ca_transaccion where tr_tran= 'DES' and tr_estado <> 'RV' and tr_secuencial >0 and tr_operacion =@w_operacionca) begin 

   exec @w_error    = cob_cartera..sp_lcr_calc_corte
   @i_operacionca   = @w_operacionca,
   @i_fecha_proceso = @w_fecha_valor,
   @o_fecha_corte   = @w_fecha_pri_cuot out
   
   if @w_error <> 0  begin 
      select  
      @w_msg  = 'ERROR: AL GENERAR LA FECHA DE PRIMER VENCIMIENTO',
      @w_error= 70002
      goto ERROR_FIN
   end 


   update ca_operacion set 
   op_fecha_pri_cuot  =  @w_fecha_pri_cuot
   where op_operacion =  @w_operacionca  
   
   if @@error <> 0  begin 
      select  
      @w_msg  = 'ERROR: AL ACTUALIZAR LA FECHA DE PRIMER VENCIMIENTO ',
      @w_error= 70002
      goto ERROR_FIN
   end 
   
end 

--VALIDACIONES
if exists (select 1 from ca_operacion where op_operacion = @w_operacionca and op_estado = @w_est_cancelado) begin 
   
   update ca_operacion set 
   op_estado            = @w_est_vigente,
   op_fecha_ult_proceso = @w_fecha_valor  
   where op_operacion = @w_operacionca
   
   if @@error <> 0 begin 
      select 
      @w_msg  = 'ERROR: AL ACTUALIZAR ESTADO DE LA CA_OPERACION' ,
      @w_error= 70006
      goto ERROR_FIN   
   end 
   
   update ca_dividendo set 
   di_estado          =(case when @w_fecha_inimax > @w_fecha_valor then @w_est_novigente else @w_est_vigente end),
   di_fecha_can       = null  
   where di_operacion = @w_operacionca
   and di_dividendo   = @w_max_dividendo
   
   if @@error <> 0 begin 
      select 
      @w_msg  = 'ERROR: AL ACTUALIZAR ESTADO DE LA CA_DIVIDENDO' ,
      @w_error= 70007
      goto ERROR_FIN    
   end 
   
   update ca_amortizacion  set 
   am_estado           =(case when @w_fecha_inimax >= @w_fecha_valor then @w_est_novigente else @w_est_vigente end)  
   where am_operacion  = @w_operacionca
   and am_dividendo    = @w_max_dividendo
   and am_concepto     = 'CAP'
   
   if @@error <> 0 begin 
      select 
      @w_msg  = 'ERROR: AL ACTUALIZAR ESTADO DE LA CA_DIVIDENDO' ,
      @w_error= 70008
      goto ERROR_FIN   
   end 
      
end 


update ca_operacion set op_monto = op_monto + @i_monto where op_operacion = @w_operacionca

if @@error <> 0 begin 
   select 
   @w_msg  = 'ERROR: AL ACTUALIZAR EL MONTO DE LA OPERACION' ,
   @w_error= 70009
   goto ERROR_FIN   
end 

update ca_amortizacion set 
am_cuota           = am_cuota + @i_monto, 
am_acumulado       = am_acumulado + @i_monto
where am_operacion = @w_operacionca
and am_dividendo   = @w_max_dividendo
and am_concepto = 'CAP'

if @@error <> 0 begin 
   select 
   @w_msg  = 'ERROR: AL ACTUALIZAR LA TABAL DE AMORTIZACION' ,
   @w_error= 70010
   goto ERROR_FIN   
end 


update ca_rubro_op set 
ro_valor           = @i_monto
where ro_operacion = @w_operacionca
and ro_concepto    = 'CAP'

if @@error <> 0 begin 
   select 
   @w_msg  = 'ERROR: AL ACTUALIZAR LOS RUBRO CAPITAL DE LA OPERACION' ,
   @w_error= 70011
   goto ERROR_FIN   
end

update ca_rubro_op set 
ro_porcentaje      = @w_porcentaje_com,
ro_valor           = round(@i_monto*(@w_porcentaje_com/100) ,@w_numdec)
where ro_operacion = @w_operacionca
and ro_concepto    = 'COM'

if @@error <> 0 begin 
   select 
   @w_msg  = 'ERROR: AL ACTUALIZAR LOS RUBRO COMISION DE LA OPERACION' ,
   @w_error= 70012
   goto ERROR_FIN   
end

update ca_rubro_op set 
ro_valor           = round(@i_monto*(@w_porcentaje_com/100)*(ro_porcentaje/100) ,@w_numdec)
where ro_operacion = @w_operacionca
and ro_concepto    = 'IVA_COM'

if @@error <> 0 begin 
   select 
   @w_msg  = 'ERROR: AL ACTUALIZAR LOS RUBRO IVA_COM DE LA OPERACION' ,
   @w_error= 70013
   goto ERROR_FIN   
end

if @i_renovar = 'S' select @w_desembolso =  @i_monto
else begin  

   select @w_desembolso = @i_monto -isnull(sum(ro_valor) ,0)  
   from ca_rubro_op
   where ro_operacion = @w_operacionca
   and ro_concepto    in('COM','IVA_COM')
   
end 


exec @w_error     = sp_desembolso
@s_ofi            = @w_oficina,
@s_term           = @s_term,
@s_user           = @s_user,
@s_date           = @w_fecha_proceso,
@i_nom_producto   = 'CCA',
@i_producto       = @i_forma_desembolso, 
@i_cuenta         = @w_cuenta , 
@i_beneficiario   = @w_nombre,
@i_ente_benef     = @w_cliente,
@i_oficina_chg    = @w_oficina,
@i_banco_ficticio = @w_operacionca,
@i_banco_real     = @i_banco,
@i_fecha_liq      = @w_fecha_valor,
@i_monto_ds       = @w_desembolso,
@i_moneda_ds      = @w_moneda,
@i_tcotiz_ds      = 'COT',
@i_cotiz_ds       = 1.0,
@i_cotiz_op       = 1.0,
@i_tcotiz_op      = 'COT',
@i_moneda_op      = @w_moneda,
@i_operacion      = 'I',
@i_externo        = 'N'

if @w_error <> 0 begin
   select 
   @w_msg  = 'ERROR: AL DESEMBOLSAR LA OPERACION' ,
   @w_error= 70014
   print 'ERROR sp_desembolso'+convert(varchar,@w_error )
   print 'MONTO A DESEMBOLSAR:'+convert(varchar,isnull(@w_desembolso,-9999))
   goto ERROR_FIN
end


update ca_desembolso set
dm_secuencial      = @w_secuencial 
where dm_operacion = @w_operacionca
and dm_estado  = 'NA'

if @@error <> 0 begin
   select 
   @w_msg  = 'ERROR: AL ACTUALIZAR REGISTRO DE DESEMBOLSO LA OPERACION' ,
   @w_error= 700999
   goto ERROR_FIN
end



exec @w_error =sp_lcr_liquidar
@s_ofi            = @w_oficina,
@s_term           = @s_term,
@s_user           = @s_user,
@s_date           = @w_fecha_proceso,
@s_srv            = @s_srv ,         
@s_ssn            = @s_ssn ,         
@s_sesn           = @s_sesn,         
@i_banco          = @i_banco,
@i_renovar        = @i_renovar, 
@i_cuota_balon    = @w_max_dividendo       


if @w_error <> 0 begin
   select 
   @w_msg  = 'ERROR: AL LIQUIDAR  LA OPERACION' ,
   @w_error= 70015
   goto ERROR_FIN
end


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

if @i_en_linea = 'S' begin 
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg

end else begin 
   exec sp_errorlog 
   @i_fecha     = @s_date,
   @i_error     = @w_error,
   @i_usuario   = @s_user,
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = @i_banco,
   @i_rollback  = 'N',
   @i_descripcion = @w_msg
end   

select @o_msg = @w_msg
return @w_error   

go

