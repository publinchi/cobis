/************************************************************************/
/*   Archivo:              camcasop.sp                                  */
/*   Stored procedure:     sp_cambio_estado_castigo                     */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Raul Altamirano Mendez                       */
/*   Fecha de escritura:   Dic-08-2016                                  */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Realiza el Traslado de los saldos generando transaccion de CASTIGO */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      DIC-07-2016    Raul Altamirano  Emision Inicial - Version MX    */
/*	JUN-28-2017	   Alcivar Chicaiza Insert en la tabla de malas referencias */
/*  DIC/21/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*  SEP/07/2022   K. Rodriguez  R193404 Ajuste det_trn por am_secuencia */
/*  ABR/17/2023   Guisela Fernandez     S807925 Ingreso de campo de     */
/*                                      reestructuracion                */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_castigo')
   drop proc sp_cambio_estado_castigo
go

SET ANSI_NULLS ON
GO


create proc sp_cambio_estado_castigo(
   @s_user                login,   
   @s_term                varchar(30),
   @i_operacionca         int,   
   @t_debug        		  char(1) = 'N',
   @t_file                varchar(14) = null,  
   @t_from                varchar(32) = null,
   @i_cotizacion          float,
   @i_tcotizacion         char(1) = 'N',
   @i_num_dec             tinyint,
   @o_msg                 varchar(100) = null out)

as 
declare
   @w_return               int,
   @w_secuencial           int,
   @w_error                int,
   @w_estado               int,
   @w_est_cancelado        tinyint,
   @w_est_novigente        tinyint,
   @w_est_castigado        tinyint,
   @w_fecha_proceso        datetime,
   @w_tramite              int,
   @w_moneda               tinyint,
   @w_toperacion           catalogo,
   @w_banco                cuenta,
   @w_oficina              int,
   @w_oficial              int,
   @w_cliente			   int,
   @w_fecha_ult_proceso    datetime,
   -- Variables para el ingreso de los datos a cobis..cl_refinh --
   @w_in_codigo            int,
   @w_in_documento         int,
   @w_in_ced_ruc           char(13),
   @w_in_origen            catalogo,
   @w_in_nombre            char(64),
   @w_in_fecha_ref         DATETIME, --char(10),
   @w_in_observacion       varchar(255),
   @w_in_fecha_mod         datetime,
   @w_in_subtipo           char(1),
   @w_in_p_p_apellido      varchar(16),
   @w_in_p_s_apellido      varchar(16),
   @w_in_tipo_ced          char(2),
   @w_in_usuario           login,
   @w_in_nomlar            char(64),
   @w_sp_name              varchar(30),
   @w_reestructuracion     char(1)

   

-- CARGAR VARIABLES DE TRABAJO
select @w_secuencial    = 0

--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out


select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7


select 
@w_toperacion        = op_toperacion,
@w_moneda            = op_moneda,
@w_banco             = op_banco,
@w_oficina           = op_oficina,
@w_oficial           = op_oficial,
@w_tramite           = op_tramite,
@w_estado            = op_estado,
@w_cliente			 = op_cliente,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_reestructuracion  = isnull(op_reestructuracion, 'N')
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount = 0                
   return 0
   
--- GENERAR LA TRANSACCION DE CASTIGO 
exec @w_secuencial =  sp_gen_sec
@i_operacion       = @i_operacionca

exec @w_error  = sp_historial
@i_operacionca  = @i_operacionca,
@i_secuencial   = @w_secuencial

if @w_error <> 0 
begin
   select @w_error = 724510, @o_msg = 'ERROR SACANDO HISTORICO' 
   goto ERROR_FIN
end



insert into ca_transaccion(
tr_secuencial,          tr_fecha_mov,                   tr_toperacion,
tr_moneda,              tr_operacion,                   tr_tran,
tr_en_linea,            tr_banco,                       tr_dias_calc,
tr_ofi_oper,            tr_ofi_usu,                     tr_usuario,
tr_terminal,            tr_fecha_ref,                   tr_secuencial_ref,
tr_estado,              tr_observacion,                 tr_gerente,
tr_gar_admisible,       tr_reestructuracion,            tr_calificacion,
tr_fecha_cont,          tr_comprobante)  
values(
@w_secuencial,          @w_fecha_proceso,               @w_toperacion,
@w_moneda,              @i_operacionca,                 'ETM',    --CAS
'N',                    @w_banco,                       0,
@w_oficina,             @w_oficina,                     @s_user,
@s_term,                @w_fecha_ult_proceso,           0,
'ING',                  'CASTIGO DE OPERACIONES',       @w_oficial,
'',                     @w_reestructuracion,            'E',
@w_fecha_proceso,       0)

if @@error <> 0 begin
   select @w_error = 708165, @o_msg = 'ERROR AL REGISTRAR LA TRANSACCION DE CASTIGO ' 
   goto ERROR_FIN
end


--- REGISTRAR VALORES QUE SALEN DE LOS ESTADOS INICIALES 
insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = min(am_dividendo),
dtr_concepto     = am_concepto,
dtr_estado       = case am_estado when @w_est_novigente then @w_estado else am_estado end,
dtr_periodo      = 0,
dtr_codvalor     = co_codigo * 1000 + case am_estado when @w_est_novigente then @w_estado else am_estado end * 10,
dtr_monto        = sum(am_acumulado - am_pagado) * -1,  
dtr_monto_mn     = round(((sum(am_acumulado - am_pagado) * -1)*@i_cotizacion),@i_num_dec),
dtr_moneda       = @w_moneda,
dtr_cotizacion   = @i_cotizacion,
dtr_tcotizacion  = @i_tcotizacion,
dtr_afectacion   = 'D',
dtr_cuenta       = '',
dtr_beneficiario = '',
dtr_monto_cont   = 0
from ca_amortizacion, ca_concepto
where am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado
and   co_concepto  = am_concepto
group by am_concepto, case am_estado when @w_est_novigente then @w_estado else am_estado end,
         co_codigo * 1000 + case am_estado when @w_est_novigente then @w_estado else am_estado end * 10
having sum(am_acumulado - am_pagado) > 0

if @@error <> 0  begin
   select @w_error = 708165, @o_msg = 'ERROR AL REGISTRAR DETALLES DE SALIDA'
   goto ERROR_FIN
end


--- REGISTRAR VALORES QUE SALEN DE LOS ESTADOS INICIALES 
insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = min(am_dividendo),
dtr_concepto     = am_concepto,
dtr_estado       = @w_est_castigado,
dtr_periodo      = 0,
dtr_codvalor     = co_codigo * 1000 + @w_est_castigado * 10,
dtr_monto        = sum(am_acumulado - am_pagado),  
dtr_monto_mn     = round(sum(am_acumulado - am_pagado)*@i_cotizacion,@i_num_dec),
dtr_moneda       = @w_moneda,
dtr_cotizacion   = @i_cotizacion,
dtr_tcotizacion  = @i_tcotizacion,
dtr_afectacion   = 'D',
dtr_cuenta       = '',
dtr_beneficiario = '',
dtr_monto_cont   = 0
from ca_amortizacion, ca_concepto
where am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado
and   co_concepto  = am_concepto
group by am_concepto, (co_codigo * 1000 + @w_est_castigado * 10)
having sum(am_acumulado - am_pagado) > 0

if @@error <> 0  begin
   select @w_error = 708165, @o_msg = 'ERROR AL REGISTRAR DETALLES DE SALIDA'
   goto ERROR_FIN
end

--- CAMBIAR DE ESTADO AL RUBRO DE LA OPERACION 
update ca_amortizacion set
am_estado = @w_est_castigado
where am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado

if @@error <> 0  begin
   select @w_error = 710003, @o_msg = 'ERROR AL ACTUALIZAR EL ESTADO DE LOS RUBROS DE LA OPERACION '
   goto ERROR_FIN
end

/* -- KDR 30/08/2021 Se comenta unificación de rubros para que muestre las saldos según respectivos períodos
--- UNIFICAR RUBROS INNECESARIAMENTE SEPARADOS 
select 
operacion = am_operacion, 
dividendo = am_dividendo, 
concepto  = am_concepto,
secuencia = min(am_secuencia),
cuota     = isnull(sum(am_cuota),     0.00),
gracia    = isnull(sum(am_gracia),    0.00),
acumulado = isnull(sum(am_acumulado), 0.00),
pagado    = isnull(sum(am_pagado),    0.00)
into #para_juntar
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_estado   <> @w_est_cancelado
group by am_operacion, am_dividendo, am_concepto, am_estado

if @@error <> 0  begin
   select @w_error = 710001, @o_msg = 'ERROR AL GENERAR TABLA DE TRABAJO para_juntar '
   goto ERROR_FIN
end
   
update ca_amortizacion set
am_cuota     = cuota,
am_gracia    = gracia,
am_acumulado = acumulado,
am_pagado    = pagado
from   #para_juntar
where  am_operacion = operacion
and    am_dividendo = dividendo
and    am_concepto  = concepto
and    am_secuencia = secuencia

if @@error <> 0  begin
   select @w_error = 708165, @o_msg = 'AL ACUALIZAR LOS SALDOS DE LOS RUBROS UNIFICADOS ' 
   goto ERROR_FIN
end
   
delete ca_amortizacion
from   #para_juntar
where  am_operacion  = operacion
and    am_dividendo  = dividendo
and    am_concepto   = concepto
and    am_secuencia  > secuencia
and    am_estado    <> @w_est_cancelado

if @@error <> 0  begin
   select @w_error = 710003, @o_msg = 'ERROR AL ELIMINAR REGISTROS UNIFICADOS' 
   goto ERROR_FIN
end
*/ -- FIN KDR KDR 30/08/2021

--- CAMBIAR EL ESTADO DE LA OPERACION A CASTIGO 
update ca_operacion set
op_estado        = @w_est_castigado,
op_fecha_ult_mov = @w_fecha_ult_proceso
where  op_operacion = @i_operacionca

if @@error <> 0  begin
   select @w_error = 710002, @o_msg = 'ERROR AL CAMBIAR EL ESTADO DE LA OPERACION ' 
   goto ERROR_FIN
end

---INSERTA EN LA TABLA DE MALAS REFERENCIAS

select
@w_in_origen = codigo
from   cobis..cl_catalogo
where  tabla = (select codigo
                from   cobis..cl_tabla
                where  tabla = 'cl_refinh')
and valor = 'CLIENTES CASTIGADOS'

if @@rowcount <> 1
begin
	select @w_error = 708192, @o_msg = 'NO EXISTE ORIGEN EN LA LISTA' 
	goto ERROR_FIN
end


select @w_in_ced_ruc 		= en_ced_ruc,
	   @w_in_nombre  		= en_nombre,
	   @w_in_subtipo 		= en_subtipo,
	   @w_in_p_p_apellido 	= p_p_apellido,
	   @w_in_p_s_apellido   = p_s_apellido,
       @w_in_tipo_ced       = 'CC'	   
	from cobis..cl_ente where en_ente = @w_cliente
	
	
if not exists (select 1 from cobis..cl_refinh where in_ced_ruc = @w_in_ced_ruc and in_origen = @w_in_origen)
begin
   select	
      @w_in_documento = 0,
	  --@w_in_fecha_ref = convert(varchar(10), @w_fecha_proceso, 101),
	  @w_in_fecha_ref = @w_fecha_proceso,
	  @w_in_observacion = 'INGRESO MALAS REFERENCIAS POR CASTIGO',
	  --@w_in_fecha_mod = convert(varchar(10), @w_fecha_proceso, 101),
	  @w_in_fecha_mod = @w_fecha_proceso,
	  @w_in_usuario   = @s_user,
	  @w_in_nomlar    = ltrim(isnull(ltrim(rtrim(@w_in_p_p_apellido)), '') + ' '
				           + isnull(ltrim(rtrim(@w_in_p_s_apellido)), '') + ' '
				           + isnull(ltrim(rtrim(@w_in_nombre)), ''))	

   exec @w_return  = cobis..sp_cseqnos
      @t_debug   = @t_debug,
	  @t_file    = @t_file,
	  @t_from    = @w_sp_name,
	  @i_tabla   = 'cl_refinh',
	  @o_siguiente = @w_in_codigo out
								

   insert into cobis..cl_refinh
   (in_codigo,in_documento,in_ced_ruc,in_nombre, in_fecha_ref,
	in_origen,in_observacion,in_fecha_mod,in_subtipo, in_p_p_apellido,
	in_p_s_apellido,in_tipo_ced,in_nomlar, in_usuario)
   values  
   (@w_in_codigo,@w_in_documento,@w_in_ced_ruc, @w_in_nombre,@w_in_fecha_ref,
	@w_in_origen,@w_in_observacion,@w_in_fecha_mod, @w_in_subtipo, @w_in_p_p_apellido,
	@w_in_p_s_apellido,@w_in_tipo_ced, @w_in_nomlar, @w_in_usuario)
	
   if @@rowcount = 0
   begin
      select @w_error = 701185, @o_msg = 'ERROR AL INSERTAR EL REGISRO DE MALAS REFERENCIAS' 
      goto ERROR_FIN
   end
end

---INSERTAR EN LA TABLA DE MALAS REFERENCIAS

-- ACTUALIZAR ESTADO DE LA GARANTIA
update cob_custodia..cu_custodia
set    cu_estado = 'K'
from   cob_credito..cr_gar_propuesta 
where  gp_tramite = @w_tramite
and    gp_garantia = cu_codigo_externo 
and    cu_valor_actual > 0

if @@error <> 0  begin
   select @w_error = 710003, @o_msg = 'ERROR AL CAMBIAR EL ESTADO DE LA GARANTIA ' 
   goto ERROR_FIN
end


return 0

ERROR_FIN:

return @w_error

go

