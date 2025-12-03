/************************************************************************/
/*      Archivo:                ctasxcob.sp                             */
/*      Stored procedure:       sp_cuentas_por_cobrar                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Patricio Narvaez		        */
/*      Fecha de escritura:     Mar. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      MACOSA Su uso no autorizado queda expresamente prohibido asi como*/
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Crea una operacion de Cartera de un dividendo, paso a definitiva*/
/*      liquidacion, y cancelacion de esta operacion para Garantias     */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cuentas_por_cobrar')
	drop proc sp_cuentas_por_cobrar
go
create proc sp_cuentas_por_cobrar
   @s_ssn               int 		= null,
   @s_sesn              int 		= null,
   @s_date              datetime 	= null,
   @s_ofi               smallint 	= null,
   @s_user              login 		= null,
   @s_rol               smallint 	= null,
   @s_term              varchar(30) 	= null,
   @s_srv               varchar(30) 	= null,
   @s_lsrv              varchar(30) 	= null,
   @s_org               char(1)      	= null,   
   @i_sector		catalogo 	= null,
   @i_toperacion	catalogo 	= null,
   @i_moneda		tinyint 	= null,
   @i_monto		money 		= null,
   @i_formato_fecha     int 		= 101, 
   @i_cliente           int, 
   @i_oficial           smallint,
   @i_comentario        varchar(255),
   @i_ciudad            int,
   @i_forma_pago        catalogo,
   @i_cuenta_pago       cuenta,
   @i_oficina           smallint, 
   @i_destino           catalogo 	= null,
   @i_externo           char(1)  	= 'N',
   @i_forma_desembolso  catalogo 	= null, 
   @i_cuenta_desembolso cuenta,
   @o_banco             cuenta   	= null output
	  
as
declare 
   @w_sp_name           descripcion,
   @w_return            int,
   @w_operacionca	int,
   @w_banco		cuenta,
   @w_anterior		cuenta ,
   @w_migrada		cuenta,
   @w_tramite		int,
   @w_nombre		descripcion,
   @w_cedula            varchar(30),
   @w_sector		catalogo,
   @w_toperacion	catalogo,
   @w_oficina		smallint,
   @w_moneda		tinyint,
   @w_comentario	varchar(255),
   @w_fecha_ini		datetime,
   @w_fecha_f		varchar(10),
   @w_fecha_fin         datetime,
   @w_fecha_ult_proceso	datetime,
   @w_fecha_liq		datetime,
   @w_fecha_reajuste	datetime,
   @w_monto		money,
   @w_monto_aprobado 	money,
   @w_lin_credito	cuenta,
   @w_ciudad		int,
   @w_estado		tinyint,
   @w_periodo_reajuste	smallint,
   @w_reajuste_especial	char(1),
   @w_tipo		char(1),
   @w_forma_pago	catalogo,
   @w_cuenta		cuenta,
   @w_dias_anio		smallint,
   @w_tipo_amortizacion	varchar(30),
   @w_cuota_completa 	char(1),
   @w_tipo_cobro	char(1),
   @w_tipo_reduccion	char(1),
   @w_aceptar_anticipos	char(1),
   @w_precancelacion	char(1),
   @w_num_dec	        tinyint,
   @w_tplazo            catalogo,
   @w_plazo             smallint,
   @w_tdividendo        catalogo,
   @w_periodo_cap       smallint,
   @w_periodo_int       smallint,
   @w_gracia_cap        smallint,
   @w_gracia_int        smallint,
   @w_dist_gracia       char(1),
   @w_fecha_fija        char(1), 
   @w_dia_pago  	tinyint,
   @w_cuota_fija	char(1),
   @w_evitar_feriados   char(1),
   @w_tipo_producto     char(1),
   @w_renovacion        char(1),
   @w_mes_gracia        tinyint,
   @w_tipo_aplicacion   char(1),
   @w_reajustable       char(1),
   @w_est_novigente     tinyint,
   @w_est_credito       tinyint,
   @w_dias_dividendo    int,
   @w_dias_aplicar      int,
   @w_destino           catalogo

/* CARGAR VALORES INICIALES */
select 
@w_sp_name = 'sp_cuentas_por_cobrar'

select @w_estado = @w_est_novigente
/* OBTENER DATOS DE UN CLIENTE, DESTINO DE CREDITO Y OFICIAL */

select
@w_nombre = substring(p_p_apellido,1,16) + ' ' + p_s_apellido + ' ' +
                      substring(en_nombre,1,40),
@w_cedula = en_ced_ruc
from    cobis..cl_ente
where   en_ente    = @i_cliente
set transaction isolation level read uncommitted

/* TRANSMISION DEL DEUDOR DE LA OPERACION */


exec @w_return = sp_codeudor_tmp
@s_sesn       = @s_sesn,
@s_user       = @s_user,
@i_borrar     = 'S',
@i_secuencial = 1,
@i_titular    = @i_cliente,
@i_operacion  = 'A',
@i_codeudor   = @i_cliente,
@i_ced_ruc    = @w_cedula,
@i_rol        = 'D',
@i_externo    = 'N'

if @w_return != 0 return @w_return

if @i_destino is null
begin
   select @w_destino = pa_char
   from cobis..cl_parametro
   where pa_producto = 'CCA'
   and   pa_nemonico = 'DEST'
   set transaction isolation level read uncommitted
   end
else
   select @w_destino = @i_destino


/*CREACION DE LA OPERACION EN TEMPORALES*/
exec @w_return = sp_crear_operacion_int
@s_user              = @s_user,
@s_date              = @s_date,
@s_term              = @s_term,
@i_cliente           = @i_cliente,
@i_nombre            = @w_nombre,
@i_sector            = @i_sector,
@i_toperacion        = @i_toperacion,
@i_oficina           = @i_oficina,
@i_moneda            = @i_moneda,
@i_comentario        = @i_comentario,
@i_oficial           = @i_oficial,
@i_fecha_ini         = @s_date,
@i_monto             = @i_monto,
@i_monto_aprobado    = @i_monto,
@i_destino           = @w_destino,
@i_ciudad            = @i_ciudad,
@i_forma_pago        = @i_forma_pago,
@i_cuenta            = @i_cuenta_desembolso,
@i_formato_fecha     = 101,
@i_salida            = 'N',
@i_clase_cartera     = '2', 
@i_origen_fondos     = 'F3',
@o_banco             = @w_banco output

if @w_return != 0 return @w_return

/* CREACION DE LA OPERACION EN TABLAS DEFINITIVAS*/
exec @w_return = sp_operacion_def_int
@s_date      = @s_date,
@s_sesn      = @s_sesn,
@s_user      = @s_user,
@s_ofi       = @i_oficina,
@i_banco     = @w_banco,
@i_claseoper = 'A'

if @w_return != 0 return @w_return

/* Borrar la operacion temporal */
exec @w_return = sp_borrar_tmp_int 
@s_user   = @s_user, 
@s_term   = @s_term,
@s_sesn   = @s_sesn,
@i_banco  = @w_banco 

if @w_return != 0  return @w_return

/* LIQUIDACION DE LA OPERACION */

exec @w_return      = sp_liquidacion_rapida 
@s_ssn           = @s_ssn,
@s_sesn          = @s_sesn,
@s_srv           = @s_srv,
@s_lsrv          = @s_lsrv,
@s_user          = @s_user,
@s_date          = @s_date,
@s_ofi           = @i_oficina,
@s_rol           = @s_rol,
@s_org           = @s_org,
@s_term          = @s_term,
@i_banco         = @w_banco,
@i_producto      = @i_forma_desembolso,
@i_cuenta        = @i_cuenta_desembolso,
@i_beneficiario  = @w_nombre,
@i_monto_op      = @i_monto,
@i_moneda_op     = @i_moneda,
@i_formato_fecha = @i_formato_fecha ,
@i_externo       = @i_externo,
@i_afecta_credito= 'S',          
@o_banco_generado= @w_banco out  

if @w_return <> 0 return @w_return 

/* EJECUTAR LA CANCELACION DE LA OPERACION*/
exec @w_return =  sp_abono_otros_productos    
@s_sesn             = @s_sesn,
@s_user             = @s_user,
@s_date             = @s_date,
@s_ofi              = @i_oficina,
@s_term             = @s_term,
@i_fecha            = @s_date,
@i_banco            = @w_banco,
@i_cuenta           = @i_cuenta_pago,
@i_moneda	    = @i_moneda,
@i_monto            = @i_monto,
@i_cotizacion_mpg   = 1,
@i_cotizacion_mop   = 1,
@i_tcotizacion_mpg  = 'N',
@i_tcotizacion_mop  = 'N', 
@i_fpago            = @i_forma_pago,
@i_beneficiario     = null   

if @w_return <> 0 return @w_return 

/* BORRA LAS TABLAS TEMPORALES NUEVAMENTE POR EFECTO DE LA LIQUIDACION*/
exec @w_return = sp_borrar_tmp_int 
@s_user   = @s_user, 
@s_term   = @s_term,
@s_sesn   = @s_sesn,
@i_banco  = @w_banco 

if @w_return != 0  return @w_return

select @o_banco = @w_banco

return 0

go

