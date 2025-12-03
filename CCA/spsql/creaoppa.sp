/************************************************************************/
/*      Archivo:                creaoppa.sp                             */
/*      Stored procedure:       sp_crear_operacion_pas                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Christian De la Cruz 	  	        */
/*      Fecha de escritura:     Mar. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Crea una operacion de Cartera pasiva partiendo de una activa    */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crear_operacion_pas')
	drop proc sp_crear_operacion_pas
go
create proc sp_crear_operacion_pas
   @s_user					login        = null,
   @s_date              	datetime     = null,
   @s_term              	varchar(30)  = null,
   @i_tramite				int          = null,
   @i_cliente				int          = null,
   @i_nombre				descripcion  = null,
   @i_toperacion_pasiva 	catalogo     = null,
   @i_oficina				smallint     = null,
   @i_monto					money        = null,
   @i_monto_aprobado		money        = null,
   @i_formato_fecha     	int          = 101, 
   @i_no_banco 	        	char(1)      = null,
   @i_salida            	char(1)      = 'S',
   @i_crear_pasiva      	char(1)      = 'S',
   @i_toperacion_activa 	catalogo     = null,
   @i_operacion_activa  	int          = null,
   @o_banco             	cuenta       = null output
	  
as
declare 
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_operacionca	    int,
   @w_banco		        cuenta,
   @w_anterior		    cuenta ,
   @w_migrada		    cuenta,
   @w_tramite		    int,
   @w_cliente		    int,
   @w_nombre		    descripcion,
   @w_sector		    catalogo,
   @w_toperacion	    catalogo,
   @w_oficina		    smallint,
   @w_moneda		    tinyint,
   @w_comentario	    varchar(255),
   @w_oficial		    smallint,
   @w_fecha_ini		    datetime,
   @w_fecha_f		    varchar(10),
   @w_fecha_fin         datetime,
   @w_fecha_ult_proceso	datetime,
   @w_fecha_liq		    datetime,
   @w_fecha_reajuste	datetime,
   @w_monto		        money,
   @w_monto_aprobado 	money,
   @w_destino		    catalogo,
   @w_lin_credito	    cuenta,
   @w_ciudad		    int,
   @w_estado		    tinyint,
   @w_periodo_reajuste	smallint,
   @w_reajuste_especial	char(1),
   @w_tipo		        char(1),
   @w_forma_pago	    catalogo,
   @w_cuenta		    cuenta,
   @w_dias_anio		    smallint,
   @w_tipo_amortizacion	varchar(30),
   @w_cuota_completa 	char(1),
   @w_tipo_cobro	    char(1),
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
   @w_dia_pago  	    tinyint,
   @w_cuota_fija	    char(1),
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
   @w_cuota             float,
   @w_porcentaje        float,
   @w_periodo_crecimiento  smallint,
   @w_tasa_crecimiento  float,   
   @w_direccion         tinyint, 
   @w_clase_cartera     catalogo,
   @w_origen_fondos     catalogo,
   @w_banca             catalogo,
   @w_base_calculo       CHAR(1)  --LGU
   

/* CARGAR VALORES INICIALES */
select 
@w_sp_name = 'sp_crear_operacion_int',
@w_est_novigente = 0,
@w_est_credito   = 99

/* CALCULAR SECUENCIAL Y NUMERO DE BANCO */
if @i_no_banco = 'S' begin
   
   exec @w_operacionca = sp_gen_sec
        @i_operacion   = -1

   select @w_banco = convert(varchar(20),@w_operacionca)

end 
else begin

   exec @w_return = sp_numero_oper
   @s_date        = @s_date, 
   @i_oficina     = @i_oficina,
   @i_tramite     = @i_tramite,
   @o_operacion   = @w_operacionca out,
   @o_num_banco   = @w_banco out
   
   if @w_return != 0 return @w_return

end


/*TOMA DATOS DE LA OPERACION ACTIVA DE CA_OPERACION_TMP*/
select  
@w_anterior 		    = opt_anterior,
@w_migrada 		        = opt_migrada,
@w_sector 		        = opt_sector,
@w_toperacion 		    = opt_toperacion,		
@w_oficina 		        = opt_oficina,
@w_moneda 		        = opt_moneda,
@w_comentario 		    = opt_comentario,
@w_oficial 		        = opt_oficial,
@w_fecha_ini 		    = opt_fecha_ini,
@w_fecha_fin 		    = opt_fecha_fin,
@w_fecha_ult_proceso 	= opt_fecha_ult_proceso,
@w_fecha_liq 		    = opt_fecha_liq,
@w_fecha_reajuste 	    = opt_fecha_reajuste,
@w_monto 		        = opt_monto,
@w_monto_aprobado 	    = opt_monto_aprobado,
@w_destino 		        = opt_destino,
@w_lin_credito 		    = opt_lin_credito,
@w_ciudad 		        = opt_ciudad,
@w_estado 		        = opt_estado,
@w_periodo_reajuste 	= opt_periodo_reajuste,
@w_reajuste_especial 	= opt_reajuste_especial,	
@w_forma_pago 		    = opt_forma_pago,                         
@w_cuenta 		        = opt_cuenta,
@w_dias_anio 		    = opt_dias_anio,
@w_tipo_amortizacion 	= opt_tipo_amortizacion,
@w_cuota_completa 	    = opt_cuota_completa,
@w_tipo_cobro 		    = opt_tipo_cobro,
@w_tipo_reduccion 	    = opt_tipo_reduccion,
@w_tipo_aplicacion 	    = opt_tipo_aplicacion,
@w_aceptar_anticipos 	= opt_aceptar_anticipos,
@w_precancelacion 	    = opt_precancelacion,
@w_renovacion 		    = opt_renovacion,
@w_dist_gracia 		    = opt_dist_gracia,
@w_mes_gracia 		    = opt_mes_gracia,
@w_gracia_cap 		    = opt_gracia_cap,
@w_gracia_int 		    = opt_gracia_int,
@w_reajustable 		    = opt_reajustable,
@w_plazo 		        = opt_plazo,
@w_tplazo 		        = opt_tplazo,
@w_tdividendo 		    = opt_tdividendo,
@w_periodo_cap 		    = opt_periodo_cap,
@w_periodo_int 		    = opt_periodo_int,
@w_cuota 		        = opt_cuota,
@w_evitar_feriados      = opt_evitar_feriados,
@w_dia_pago             = opt_dia_fijo,
@w_periodo_crecimiento  = opt_periodo_crecimiento,
@w_tasa_crecimiento     = opt_tasa_crecimiento,   
@w_direccion            = opt_direccion,
@w_origen_fondos        = opt_origen_fondos,
@w_banca                = opt_banca,
@w_base_calculo         = opt_base_calculo --LGU
from ca_operacion_tmp
where opt_operacion     = @i_operacion_activa

if @i_tramite is null select @w_estado = @w_est_novigente
else select @w_estado = @w_est_credito

/*OBTENCION DE LOS DIAS DE MI DIVIDENDO PARA DIAS CLAUSULA*/
select @w_dias_dividendo = td_factor
from ca_tdividendo
where td_tdividendo = @w_tdividendo


exec @w_return = sp_consulta_clausula
@i_dias_dividendo = @w_dias_dividendo,
@o_dias_a_aplicar = @w_dias_aplicar out

if @w_return != 0 return @w_return

/*TIPO DE OPERACION PASIVA*/
select @w_tipo = dt_tipo
from ca_default_toperacion
where dt_toperacion = @i_toperacion_pasiva

select @w_clase_cartera = '1'    --COMERCIAL PARA OP. DE REDESCUENTO 
 
/* CREAR LA OPERACION TEMPORAL */
exec @w_return = sp_operacion_tmp
@i_operacion         = 'I',
@i_operacionca       = @w_operacionca,
@i_banco             = @w_banco,
@i_anterior          = @w_anterior,
@i_migrada           = @w_migrada,
@i_tramite           = @w_tramite,
@i_cliente           = @i_cliente,
@i_nombre            = @i_nombre,
@i_sector            = @w_sector,
@i_toperacion        = @i_toperacion_pasiva,
@i_oficina           = @w_oficina,
@i_moneda            = @w_moneda, 
@i_comentario        = @w_comentario,
@i_oficial           = @w_oficial,
@i_fecha_ini         = @w_fecha_ini,
@i_fecha_fin         = @w_fecha_ini,
@i_fecha_ult_proceso = @w_fecha_ini,
@i_fecha_liq         = @w_fecha_ini,
@i_fecha_reajuste    = @w_fecha_ini,
@i_monto             = @i_monto, 
@i_monto_aprobado    = @i_monto_aprobado,
@i_destino           = @w_destino,
@i_lin_credito       = @w_lin_credito,
@i_ciudad            = @w_ciudad,
@i_estado            = @w_estado,
@i_periodo_reajuste  = @w_periodo_reajuste,
@i_reajuste_especial = @w_reajuste_especial,
@i_tipo              = @w_tipo, --(Con Financiamiento)
@i_forma_pago        = @w_forma_pago,
@i_cuenta            = @w_cuenta,
@i_dias_anio         = @w_dias_anio, 
@i_tipo_amortizacion = @w_tipo_amortizacion,
@i_cuota_completa    = @w_cuota_completa,
@i_tipo_cobro        = @w_tipo_cobro,
@i_tipo_reduccion    = @w_tipo_reduccion,
@i_aceptar_anticipos = @w_aceptar_anticipos,
@i_precancelacion    = @w_precancelacion,
@i_tipo_aplicacion   = @w_tipo_aplicacion,
@i_tplazo            = @w_tplazo,
@i_plazo             = @w_plazo,
@i_tdividendo        = @w_tdividendo,
@i_periodo_cap       = @w_periodo_cap,
@i_periodo_int       = @w_periodo_int,
@i_dist_gracia       = @w_dist_gracia,
@i_gracia_cap        = @w_gracia_cap,
@i_gracia_int        = @w_gracia_int,
@i_dia_fijo          = @w_dia_pago,
@i_cuota             = 0,
@i_evitar_feriados   = @w_evitar_feriados,
@i_renovacion        = @w_renovacion,
@i_mes_gracia        = @w_mes_gracia,
@i_reajustable       = @w_reajustable,
@i_dias_clausula     = @w_dias_aplicar,
@i_periodo_crecimiento = @w_periodo_crecimiento,
@i_tasa_crecimiento   = @w_tasa_crecimiento,
@i_direccion          = @w_direccion, 
@i_clase_cartera      = @w_clase_cartera,
@i_origen_fondos      = @w_origen_fondos,
@i_banca			       = @w_banca,
@i_base_calculo       = @w_base_calculo  -- LGU

if @w_return != 0 return @w_return


/* CREAR LOS RUBROS TEMPORALES DE LA OPERACION */
exec @w_return = sp_gen_rubtmp
@i_crear_pasiva      = @i_crear_pasiva,
@i_toperacion_pasiva = @i_toperacion_pasiva,  
@i_operacion_activa  = @i_operacion_activa,
@i_operacionca       = @w_operacionca 

if @w_return != 0 return @w_return

/*AUMENTADO*/
/*CONTROLAR QUE SE HAYA CREADO EL RUBRO INTERES PARA LA INTERMEDIACION*/
if not exists ( select 1 from ca_rubro
                where ru_toperacion = @i_toperacion_pasiva
                and   ru_tipo_rubro = 'I'
                and   ru_provisiona = 'S')
   return 710118

/* GENERACION DE LA TABLA DE AMORTIZACION */

exec @w_return = sp_gentabla
@i_operacionca      = @w_operacionca,
@i_actualiza_rubros = 'S',
@i_tabla_nueva      = 'S',
@i_crear_op	    = 'S',
@o_fecha_fin        = @w_fecha_fin out
   
if @w_return != 0 
   return @w_return

/* ACTUALIZACION DE LA OPERACION */

if isnull(@w_periodo_reajuste,0) != 0 
   begin
   if @w_periodo_reajuste % @w_periodo_int = 0
      select @w_fecha_reajuste = dit_fecha_ven
      from   ca_dividendo_tmp
      where  dit_operacion = @w_operacionca
      and    dit_dividendo = @w_periodo_reajuste / @w_periodo_int
   else
      select @w_fecha_reajuste = 
      dateadd(dd,td_factor*@w_periodo_reajuste, @w_fecha_ini)
      from ca_tdividendo
      where td_tdividendo = @w_tdividendo
   end 
else
   select @w_fecha_reajuste = '01/01/1900'

update ca_operacion_tmp set 
opt_fecha_reajuste  = @w_fecha_reajuste
where opt_operacion = @w_operacionca

if @@error != 0
   return 710002

select @w_fecha_f  = convert(varchar(10),@w_fecha_fin,@i_formato_fecha)

select @o_banco = @w_banco

if @i_salida = 'S'
begin
   select @w_banco
   select @w_fecha_f
   select es_descripcion 
   from ca_estado where es_codigo = 0
   select @w_tipo 
end


return 0

go

