/************************************************************************/
/*  archivo:                lcr_crear.sp                                 */
/*  stored procedure:       sp_crear_lcr                                */
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
/*             Creacion de la Linea de Credito Revolvente               */
/* srojas        13-Nov-2018         Modificación llamada               */
/*                                   sp_ejecutar_reglas                 */
/*      OCT-18-2019    A. Miramon       Ajuste en calculo de CAT        */
/************************************************************************/

use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_lcr_crear')
	drop proc sp_lcr_crear
go


create proc sp_lcr_crear(
   @s_ssn            int           = null,
   @s_ofi            smallint,
   @s_user           login,
   @s_date           datetime,
   @s_srv            varchar(30)   = null,
   @s_term           descripcion   = null,
   @s_rol            smallint      = null,
   @s_lsrv           varchar(30)   = null,
   @s_sesn           int           = null,
   @s_org            char(1)       = null,
   @s_org_err        int           = null,
   @s_error          int           = null,
   @s_sev            tinyint       = null,
   @s_msg            descripcion   = null,
   @t_rty            char(1)       = null,
   @t_trn            int           = null,
   @t_debug          char(1)       = 'N',
   @t_file           varchar(14)   = null,
   @t_from           varchar(30)   = null,
   @i_en_linea       char(1)       = 'S',  
   ---Creacion  con instancia del proceso
   @i_id_inst_proc   int           = null,    
   ---Creacion  sin instancia del proceso
   @i_cliente        int           = null,    
   @i_periodicidad   catalogo      = null,  --Semanal,Bimensual,Mensual
   @i_fecha_valor    datetime      = null, 
   @i_monto_aprobado money         = null,
   @i_renovar        char(1)       = 'N', 
   --
   @o_id_resultado   smallint      = 1    out,
   @o_banco          cuenta        = null out  

)
as declare 
@w_monto_aprobado           money,
@w_cliente                  int,
@w_error                    int,
@w_oficial                  int,
@w_oficina		            int,
@w_fecha_proceso            datetime,
@w_tramite                  int,
@w_periodicidad             catalogo,
@w_nombre                   varchar(255),
@w_moneda                   int  = null,
@w_operacion                int,
@w_prod_cobis               varchar(50),
@w_sp_name                  varchar(50),
@w_ciudad                   int,
@w_plazo_lcr                int,
@w_fecha_valor              datetime,
@w_commit                   char(1),
@w_plazo                    int, 
@w_tplazo                   catalogo,
@w_tdividendo               catalogo,
@w_periodo_cap              int,
@w_periodo_int              int,
@w_msg                      varchar(64),
@w_est_cancelado            int,
@w_operacionca              int,
@w_ced_ruc                  descripcion,
@w_resultado_monto          varchar(200),
@w_cuenta                   cuenta,
@w_dia_pago                 int, 
@w_est_vigente              int,
@w_operacion_cliente        int,
@w_cat                      float,
@w_tasa_int                 varchar(20),
@w_interes                  float , 
@w_est_anulado              int                     


set rowcount 0

select 
@w_sp_name = 'sp_lcr_crear',
@w_commit  = 'N',
@s_sesn  = @s_ssn


exec sp_estados_cca @o_est_cancelado = @w_est_cancelado out,
                    @o_est_vigente   = @w_est_vigente   out,
					@o_est_anulado   = @w_est_anulado   out 

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

select @w_fecha_valor = isnull( @i_fecha_valor,@w_fecha_proceso)



--VALIDACION DE EXISTENCIA DE UNA LCR DENTRO DEL PERIODO

if exists (select 1 from ca_operacion where op_cliente = @i_cliente  and op_toperacion = 'REVOLVENTE' and @i_fecha_valor between op_fecha_ini and op_fecha_fin) and @i_renovar = 'N' begin 
   select  
   @w_msg  = 'ERROR: EL CLIENTE TIENE UNA LCR EN CURSO',
   @w_error= 70067
   goto ERROR_FIN
end 


--DATOS CON ISNTANCIA DE PROCESO
if @i_id_inst_proc is not null begin
    
	select    
    @w_cliente   = io_campo_1,
    @w_tramite   = io_campo_3
    from cob_workflow..wf_inst_proceso
    where io_id_inst_proc = @i_id_inst_proc
	
   if @w_tramite is not null begin
      select 
      @w_periodicidad = tr_periodicidad_lcr,
      @w_moneda       = tr_moneda,
	  @w_oficial      = tr_oficial,
      @w_oficina      = tr_oficina
      from cob_credito..cr_tramite
      where tr_tramite = @w_tramite
   end
   
   select @w_ciudad = of_ciudad from cobis..cl_oficina 
   where of_oficina = @w_oficina 
   
   
  --EJECUCION DE LA REGLA DE MONTOS 
   exec @w_error       = cob_cartera..sp_ejecutar_regla
   @s_ssn              = @s_ssn,
   @s_ofi              = @s_ofi,
   @s_user             = @s_user,
   @s_date             = @w_fecha_proceso,
   @s_srv              = @s_srv,
   @s_term             = @s_term,
   @s_rol              = @s_rol,
   @s_lsrv             = @s_lsrv,
   @s_sesn             =  @s_ssn,
   @i_regla            = 'LCRCUPINI',    
   @i_id_inst_proc     = @i_id_inst_proc,
   @o_resultado1       = @w_resultado_monto out  

   if @w_error <> 0 or @w_resultado_monto is null begin 
      select @w_msg = 'ERROR AL EJECUTAR REGLA DE MONTO INICIAL' 
      goto ERROR_FIN
   end 
   
   select @w_monto_aprobado = convert(money,isnull(@w_resultado_monto,'1500'))
   
   
   exec @w_error       = cob_cartera..sp_ejecutar_regla
   @s_ssn              = @s_ssn,
   @s_ofi              = @s_ofi,
   @s_user             = @s_user,
   @s_date             = @w_fecha_proceso,
   @s_srv              = @s_srv,
   @s_term             = @s_term,
   @s_rol              = @s_rol,
   @s_lsrv             = @s_lsrv,
   @s_sesn             =  @s_ssn,
   @i_regla            = 'LCRTINT',    
   @i_id_inst_proc     = @i_id_inst_proc,
   @o_resultado1       = @w_tasa_int out  

   if @w_error <> 0 begin
      select @w_msg = 'ERROR AL EJECUTAR REGLA DE TASA DE INTERES' 
      goto ERROR_FIN
   end 
   
   select @w_interes = convert(float,isnull(@w_tasa_int,'70'))

    
end else begin --DATOS SIN INSTANCIA DE PROCESO


   select top 1 
   @w_oficial          = op_oficial,
   @w_oficina          = op_oficina,
   @w_ciudad           = op_ciudad   
   from cob_cartera..ca_operacion
   where op_cliente = @i_cliente
   and op_estado not in ( @w_est_anulado)
   order by op_operacion   desc 
   
   if @@rowcount =  0 begin 
      select @w_msg = 'ERROR AL OBTENER DATOS DE OFICIAL OFICINA CIUDAD ' 
      goto ERROR_FIN
   end 
      
   select 
   @s_user = fu_login
   from cobis..cc_oficial,cobis..cl_funcionario
   where oc_oficial = @w_oficial
   and   oc_funcionario = fu_funcionario   
   
   if @@rowcount =  0 begin 
      select @w_msg = 'ERROR AL OBTENER DATOS DE LOGIN DEL OFICIAL ' 
      goto ERROR_FIN
   end 
   
   select 
   @w_cliente        = @i_cliente,
   @w_periodicidad   = @i_periodicidad,
   @w_moneda         = 0,
   @w_monto_aprobado = isnull(@i_monto_aprobado,1500),
   @w_interes        = 70
   
end


select 
@w_nombre      = en_nomlar,
@w_ced_ruc     = en_ced_ruc 
from cobis..cl_ente
where en_ente       = @w_cliente

select @w_cuenta = ea_cta_banco
from cobis..cl_ente_aux 
where ea_ente  = @w_cliente


--PRINT 'REGISTRAR DEUDOR PRINCIPAL'
exec @w_error = sp_codeudor_tmp
@s_sesn        = @s_sesn,
@s_user        = @s_user,
@i_borrar      = 'S',
@i_secuencial  = 1,
@i_titular     = @w_cliente,
@i_operacion   = 'A',
@i_codeudor    = @w_cliente,
@i_ced_ruc     = @w_ced_ruc,
@i_rol         = 'D',
@i_externo     = 'N'

if @w_error <> 0
begin
   select @w_msg = 'ERROR: AL REGISTRRA DEUDOR PRINCIPAL'
   goto ERROR_FIN
end

--VALOR POR DEFECTO --semanal 
select 
@w_plazo               =52,
@w_tplazo              ='W',
@w_tdividendo          ='W',
@w_periodo_cap         =1,
@w_periodo_int         =1,
@w_dia_pago            =2
   
if @w_periodicidad = 'BW' begin --BISEMANAL
   select 
   @w_plazo            =52,
   @w_tplazo           ='W',
   @w_tdividendo       ='W',
   @w_periodo_cap      =2,
   @w_periodo_int      =2,
   @w_dia_pago         =2
end 

if @w_periodicidad = 'M' begin --MENSUAL
   select 
   @w_plazo            =12,
   @w_tplazo           ='M',
   @w_tdividendo       ='M',
   @w_periodo_cap      =1,
   @w_periodo_int      =1,
   @w_dia_pago         =5
end 


exec @w_error = cob_cartera..sp_crear_operacion
@s_user             = @s_user,
@s_sesn             = @s_sesn,
@s_term             = @s_term,
@s_date             = @w_fecha_proceso,
@i_anterior         = null,
@i_comentario       = 'OPERACION CREADA DESDE WORKFLOW',
@i_oficial          = @w_oficial,
@i_destino          = '01',
@i_monto_aprobado   = @w_monto_aprobado,
@i_cliente          = @w_cliente,
@i_nombre           = @w_nombre,
@i_oficina          = @w_oficina,
@i_toperacion       = 'REVOLVENTE',
@i_monto            = 0.0, --Monto: CERO
@i_moneda           = @w_moneda,
@i_fecha_ini        = @w_fecha_valor,
@i_forma_pago       = 'ND_BCO_MN',
@i_cuenta           = @w_cuenta,
@i_ciudad           = @w_ciudad,
@i_reestructuracion = 'N',
@i_grupal           = 'N',
@i_promocion        = 'N',
@i_plazo            = @w_plazo,
@i_tplazo           = @w_tplazo,
@i_tdividendo       = @w_tdividendo,
@i_periodo_cap      = @w_periodo_cap,
@i_periodo_int      = @w_periodo_int,
@i_dia_pago         = @w_dia_pago,
@i_tasa             = @w_interes,
@o_banco            = @o_banco output

if @w_error <> 0 begin 
   select @w_msg = 'ERROR AL CREAR LA LCR EN TEMPORALES' 
   goto ERROR_FIN
end 



--PRINT 'OBTENER NUMERO DE OPERACION DESDE TEMPORAL'
if @@trancount = 0 begin  
   select @w_commit = 'S'
   begin tran 
end  


exec @w_error  = sp_operacion_def
@s_date         = @w_fecha_proceso,
@s_sesn         = @s_sesn,    
@s_user	        = @s_user,
@s_ofi 	        = @w_oficina,
@i_banco        = @o_banco

if @w_error  <> 0 begin 
   select @w_msg = 'ERROR AL PASAR LA LCR A DEFINITIVAS'
   goto ERROR_FIN
end    

-- AMG 2019/10/18 - Calculo de CAT
exec @w_error = sp_calculo_cat @i_banco = @o_banco, @o_cat = @w_cat out

if @w_error <> 0 select @w_cat = @w_interes

select @w_operacionca = op_operacion 
from ca_operacion 
where op_banco = @o_banco

update ca_operacion set 
op_estado    = @w_est_cancelado,
op_valor_cat = @w_cat
where op_operacion = @w_operacionca

if @@error <> 0 begin 
   select 
   @w_msg  = 'ERROR: AL ACTUALIZAR LA TABLA DE OPERACION DESPUES DEL DESEMBOLSO' ,
   @w_error= 70001
   goto ERROR_FIN   
end

update ca_dividendo set 
di_estado    = @w_est_cancelado, 
di_fecha_can = di_fecha_ini
where di_operacion = @w_operacionca

if @@error <> 0 begin 
   select 
   @w_msg  = 'ERROR: AL ACTUALIZAR LA TABLA DE DIVIDENDOS DESPUES DEL DESEMBOLSO' ,
   @w_error= 70001
   goto ERROR_FIN   
end


update ca_amortizacion set 
am_estado = @w_est_cancelado 
where am_operacion = @w_operacionca

if @@error <> 0 begin 
   select 
   @w_msg  = 'ERROR: AL ACTUALIZAR LA TABLA DE AMORTIZACION DESPUES DEL DESEMBOLSO' ,
   @w_error= 70001
   goto ERROR_FIN   
end


if @i_id_inst_proc is not null begin

   update ca_operacion  set 
   op_tramite = @w_tramite
   where op_operacion = @w_operacionca
   
   if @@error <> 0 begin 
      select 
      @w_msg  = 'ERROR: AL ACTUALIZAR EL NUMERO DE TRAMITE DE LA OPERACION' ,
      @w_error= 70001
      goto ERROR_FIN   
   end
   
end

if @w_commit = 'S'begin 
   select @w_commit = 'N'
   commit tran    
end 

exec @w_error  = sp_borrar_tmp
@i_banco  = @o_banco,      
@s_user   = @s_user,
@s_term   = @s_term

if @w_error  <> 0 begin 
   select @w_msg = 'ERROR AL BORRAR LA LCR DE TABLAS TEMPORALES'
   goto ERROR_FIN
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
   @i_fecha     = @w_fecha_proceso,
   @i_error     = @w_error,
   @i_usuario   = @s_user,
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = @o_banco,
   @i_rollback  = 'N'
   
end  

return @w_error

go 