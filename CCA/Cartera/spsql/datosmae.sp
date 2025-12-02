/************************************************************************/
/*	Archivo: 		datosmae.sp				*/
/*	Stored procedure: 	sp_datos_maestro			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Francisco Yacelga 			*/
/*	Fecha de escritura: 	25/Nov./1997				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Consulta de los datos de una operacion de la tabla              */
/*      ca_maestro_operaciones						*/
/************************************************************************/
/*                            MODIFICACIONES                            */
/*  AUTOR                    FECHA                   RAZON              */
/*  Jennifer Velandia        Enero 2003                                 */
/*  Julio C Quintero         Febrero 2003           Adicion de Seguros  */
/*                                                  y otros Campos Soli-*/
/*                                                  tados por el BAC    */ 
/*  John Jairo Rendon        Junio 27 de 2005       Optimizacion        */   
/************************************************************************/ 

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_datos_maestro')
   drop proc sp_datos_maestro
go

create proc sp_datos_maestro (
   @i_fecha_proceso       datetime    = null,
   @i_banco               cuenta      = null,
   @i_formato_fecha       int         = null

)


/*@w_inicio = convert (varchar(10), li_fecha_inicio,@i_formato_fecha),*/

as
declare	@w_sp_name	       varchar(32),
@w_error                       int,
@w_fecha_de_proceso            varchar(10),
@w_producto                    smallint,
@w_tipo_de_producto            catalogo,
@w_moneda                      smallint,
@w_numero_de_operacion         int     ,
@w_numero_de_banco             cuenta  ,
@w_numero_migrada              cuenta  ,
@w_cliente                     int     ,
@w_nombre_cliente              descripcion,
@w_linea_credito               cuenta  ,
@w_oficina                     int     ,
@w_nombre_oficina              descripcion,
@w_oficial                     int     ,  
@w_nombre_oficial              descripcion,
@w_monto                       money   ,
@w_monto_desembolso            money   ,
@w_tasa                        float   ,
@w_tasa_efectiva               float   ,
@w_plazo_total                 int     ,
@w_modalidad_cobro_int         catalogo,
@w_fecha_inicio_op             varchar(10),
@w_fecha_ven_op                varchar(10),
@w_dias_vencido_op             smallint,
@w_fecha_fin_min_div_ven       varchar(10),
@w_reestructurada              catalogo,
@w_fecha_ult_reest             varchar(10),
@w_num_reestructuraciones      int     ,
@w_num_cuotas_pagadas          int     ,
@w_num_cuotas_pagadas_reest    int     ,
@w_destino_credito             catalogo,
@w_clase_cartera               catalogo,
@w_ciudad                      int     ,
@w_fecha_prox_vencimiento      varchar(10),
@w_saldo_cuota_prox_venc       money   ,
@w_saldo_capital_vigente       money   ,
@w_saldo_capital_vencido       money   ,
@w_saldo_interes_vigente       money   ,
@w_saldo_interes_vencido       money   ,
@w_saldo_interes_contingente   money   ,
@w_saldo_mora_vigente          money   ,
@w_saldo_mora_contingente      money   ,
@w_saldo_seguro_vida_vigente   money   ,
@w_saldo_seguro_vida_vencido   money   ,
@w_saldo_otros_vigente         money   ,
@w_saldo_otros_vencidos        money   ,
@w_estado_obligacion           descripcion,
@w_calificacion_obligacion     catalogo,
@w_frecuencia_pago_int         int     ,
@w_frecuencia_pago_cap         int     ,
@w_edad_vencimiento_cartera    int     ,
@w_fecha_ult_pago              varchar(10),
@w_valor_ult_pago              money   ,
@w_fecha_ult_pago_cap          varchar(10),
@w_valor_ult_pago_cap          money   ,
@w_valor_cuota_tabla           money   ,
@w_numero_cuotas_pactadas      int     ,
@w_numero_cuotas_vencidas      int     ,
@w_tipo_garantia               catalogo,
@w_descripcion_tipo_garantia   varchar(64),
@w_valor_total_garantias       float   ,
@w_fecha_castigo               varchar(10),
@w_numero_comex                cuenta  ,
@w_numero_deuda_externa        cuenta  ,
@w_fecha_embarque              varchar(10),
@w_fecha_dex                   varchar(10),
@w_tipo_tasa                   char(1),
@w_tasa_referencial            catalogo,
@w_signo                       char(1),
@w_factor                      float   ,
@w_tipo_identificacion         catalogo,
@w_numero_identificacion       cuenta  ,
@w_provision_cap               money   ,
@w_provision_int               money   ,
@w_provision_cxc               money   ,
@w_cuenta_asociada             cuenta  ,
@w_forma_de_pago               catalogo,
@w_tipo_tabla                  catalogo,
@w_periodo_gracia_cap          int     ,
@w_periodo_gracia_int          int     ,
@w_estado_cobranza             catalogo,
@w_descripcion_estado_cobranza descripcion,
@w_tasa_representativa_mercado money   ,
@w_reajustable                 char(1),
@w_descripcion_reajustable     descripcion,
@w_periodo_reajuste            smallint,
@w_fecha_prox_reajuste         varchar(10),
@w_actualizada_fecha_valor     catalogo,
@w_estado_registro             catalogo,
@w_fecha_ult_proceso           varchar(10),
@w_naturaleza_juridica         char    ,
@w_tipo_puntos                 char(1),
@w_garantia                    varchar(64),   
@w_des_clase_garantia          varchar(64),
@w_clase_garantia              char(1),
@w_valor_garantia              money,     
@w_cobertura_garantia          float,
@w_ente_propietario_gar        int,
@w_des_tipo_bien               varchar(64),
@w_naturaleza                  char(1),                  --jvc 
@w_des_naturaleza              descripcion,
@w_categoria_linea             descripcion,
@w_des_entidad_presta          descripcion,
@w_programa                    catalogo,
@w_des_programa                descripcion,
@w_desc_entidad                descripcion,
@w_tipo_linea                  catalogo,
@w_desc_tipo                   descripcion,
@w_desc_origen_fondos          descripcion,
@w_toperacion                  catalogo,
@w_tipo		               char(1),
@w_desc_destino		       descripcion,
-- JCQ 02/24/2003
@w_tiene_seg_vida              char(1),
@w_tiene_seg_vehiculo          char(1),
@w_tiene_seg_todor_maq         char(1),
@w_tiene_seg_rotura_maq        char(1),
@w_tiene_seg_vivienda          char(1),
@w_tiene_seg_extraprima        char(1),
@w_capitaliza                  char(1),
@w_icr                         char(1),
@w_condonacion_capital         money,
@w_condonacion_interes         money,
@w_provision_defecto           money,
@w_llave_redescuento           cuenta,
@w_ced_ruc_codeudor            cuenta,
@w_regional                    int,
@w_zona                        int,
@w_tipo_banca                  varchar(15),
@w_mercado_objetivo            varchar(30),
@w_tipo_productor              varchar(30),
@w_nombre_codeudor             varchar(35),
@w_aprobador                   login,
@w_codigo_sector		catalogo,
@w_op_operacion			int


/* Captura nombre de Stored Procedure  */
select	
@w_sp_name = 'sp_datos_maestro'

select @w_op_operacion = op_operacion
from ca_operacion
where op_banco = @i_banco

if @@rowcount = 0 begin
   select @w_error = 710022
   goto ERROR
end  

/* CHEQUEO QUE EXISTA LA OPERACION */

select 
@w_fecha_de_proceso            = 	mo_fecha_de_proceso,
@w_producto                    = 	mo_producto,
@w_tipo_de_producto            = 	mo_tipo_de_producto,
@w_moneda                      = 	mo_moneda,
@w_numero_de_operacion         = 	mo_numero_de_operacion,
@w_numero_de_banco             = 	mo_numero_de_banco,
@w_numero_migrada              = 	mo_numero_migrada,
@w_cliente                     = 	mo_cliente,
@w_nombre_cliente              = 	mo_nombre_cliente,
@w_linea_credito               = 	mo_cupo_credito,
@w_oficina                     = 	mo_oficina,
@w_nombre_oficina              = 	mo_nombre_oficina,
--@w_oficial                   = 	mo_oficial,
--@w_nombre_oficial            = 	mo_nombre_oficial,
@w_monto                       = 	mo_monto,
@w_monto_desembolso            = 	mo_monto_desembolso,
@w_tasa                        = 	mo_tasa,
@w_tasa_efectiva               = 	mo_tasa_efectiva,
@w_plazo_total                 = 	mo_plazo_total,
@w_modalidad_cobro_int         = 	mo_modalidad_cobro_int,
@w_fecha_inicio_op             = 	mo_fecha_inicio_op,
@w_fecha_ven_op                = 	mo_fecha_ven_op,
@w_dias_vencido_op             = 	mo_dias_vencido_op,
@w_fecha_fin_min_div_ven       = 	mo_fecha_fin_min_div_ven,
@w_reestructurada              = 	mo_reestructurada,
@w_fecha_ult_reest             = 	mo_fecha_ult_reest,
@w_num_reestructuraciones      = 	mo_num_reestructuraciones,
@w_num_cuotas_pagadas          = 	mo_num_cuotas_pagadas,
@w_num_cuotas_pagadas_reest    = 	mo_num_cuotas_pagadas_reest,
@w_destino_credito             = 	mo_destino_credito,
@w_clase_cartera               = 	mo_clase_cartera,
@w_ciudad                      = 	mo_ciudad,
@w_fecha_prox_vencimiento      = 	mo_fecha_prox_vencimiento,
@w_saldo_cuota_prox_venc       = 	mo_saldo_cuota_prox_venc,
@w_saldo_capital_vigente       = 	mo_saldo_capital_vigente,
@w_saldo_capital_vencido       = 	mo_saldo_capital_vencido,
@w_saldo_interes_vigente       = 	mo_saldo_interes_vigente,
@w_saldo_interes_vencido       = 	mo_saldo_interes_vencido,
@w_saldo_interes_contingente   = 	mo_saldo_interes_contingente,
@w_saldo_mora_vigente          = 	mo_saldo_mora_vigente,
@w_saldo_mora_contingente      = 	mo_saldo_mora_contingente,
@w_saldo_seguro_vida_vigente   = 	mo_saldo_seguro_vida_vigente,
@w_saldo_seguro_vida_vencido   = 	mo_saldo_seguro_vida_vencido,
@w_saldo_otros_vigente         = 	mo_saldo_otros_vigente,
@w_saldo_otros_vencidos        = 	mo_saldo_otros_vencidos,
@w_estado_obligacion           = 	mo_estado_obligacion,
@w_calificacion_obligacion     = 	mo_calificacion_obligacion,
@w_frecuencia_pago_int         = 	mo_frecuencia_pago_int,
@w_frecuencia_pago_cap         = 	mo_frecuencia_pago_cap,
@w_edad_vencimiento_cartera    = 	mo_edad_vencimiento_cartera,
@w_fecha_ult_pago              = 	mo_fecha_ult_pago,
@w_valor_ult_pago              = 	mo_valor_ult_pago,
@w_fecha_ult_pago_cap          = 	mo_fecha_ult_pago_cap,
@w_valor_ult_pago_cap          = 	mo_valor_ult_pago_cap,
@w_valor_cuota_tabla           = 	mo_valor_cuota_tabla,
@w_numero_cuotas_pactadas      = 	mo_numero_cuotas_pactadas,
@w_numero_cuotas_vencidas      = 	mo_numero_cuotas_vencidas,
@w_tipo_garantia               = 	mo_tipo_garantia,
@w_descripcion_tipo_garantia   = 	mo_descripcion_tipo_garantia,
@w_fecha_castigo               = 	mo_fecha_castigo,
@w_numero_comex                = 	mo_numero_comex,
@w_numero_deuda_externa        = 	mo_numero_deuda_externa,
@w_fecha_embarque              = 	mo_fecha_embarque,
@w_fecha_dex                   = 	mo_fecha_dex,
@w_tipo_tasa                   = 	mo_tipo_tasa,
@w_tasa_referencial            = 	mo_tasa_referencial,
@w_signo                       = 	mo_signo,
@w_factor                      = 	mo_factor,
@w_tipo_identificacion         = 	mo_tipo_identificacion,
@w_numero_identificacion       = 	mo_numero_identificacion,
@w_provision_cap               = 	mo_provision_cap,
@w_provision_int               = 	mo_provision_int,
@w_provision_cxc               = 	mo_provision_cxc,
@w_cuenta_asociada             = 	mo_cuenta_asociada,
@w_forma_de_pago               = 	mo_forma_de_pago,
@w_tipo_tabla                  = 	mo_tipo_tabla,
@w_periodo_gracia_cap          = 	mo_periodo_gracia_cap,
@w_periodo_gracia_int          = 	mo_periodo_gracia_int,
@w_estado_cobranza             = 	mo_estado_cobranza,
@w_descripcion_estado_cobranza = 	mo_descripcion_estado_cobranza,
@w_tasa_representativa_mercado = 	mo_tasa_representativa_mercado,
@w_reajustable                 = 	mo_reajustable,
@w_descripcion_reajustable     = 	mo_descripcion_reajustable,
@w_periodo_reajuste            = 	mo_periodo_reajuste,
@w_fecha_prox_reajuste         = 	mo_fecha_prox_reajuste,
@w_fecha_ult_proceso           = 	mo_fecha_ult_proceso,
@w_tipo_puntos                 = 	mo_tipo_puntos,
@w_clase_garantia              =	mo_clase_garantia,
@w_cobertura_garantia          =   	mo_cobertura_garantia,
@w_des_tipo_bien               =	mo_des_tipo_bien,
@w_tiene_seg_vida              =        mo_tiene_seg_vida,
@w_tiene_seg_vehiculo          =        mo_tiene_seg_vehiculo,
@w_tiene_seg_todor_maq         =        mo_tiene_seg_todor_maq,
@w_tiene_seg_rotura_maq        =        mo_tiene_seg_rotura_maq,
@w_tiene_seg_vivienda          =        mo_tiene_seg_vivienda,
@w_tiene_seg_extraprima        =        mo_tiene_seg_extraprima,
@w_capitaliza                  =        mo_capitaliza,
@w_icr                         =        mo_tiene_incentivo,
@w_condonacion_capital         =        mo_condonacion_capital,
@w_condonacion_interes         =        mo_condonacion_intereses,
@w_provision_defecto           =        mo_provision_defecto,
@w_llave_redescuento           =        mo_llave_redescuento,
@w_regional                    =        mo_regional,
@w_zona                        =        mo_zona,
@w_mercado_objetivo            =        mo_mercado_obj,
@w_tipo_productor              =        mo_tipo_productor,
@w_tipo_banca                  =        mo_tipo_banca,
@w_ced_ruc_codeudor            =        mo_ced_ruc_codeudor, 
@w_nombre_codeudor             =        mo_nombre_codeudor,
@w_aprobador                   =        mo_aprobador,
@w_codigo_sector	       =	mo_codigo_sector


from ca_maestro_operaciones
where mo_fecha_de_proceso =  convert(varchar(10),@i_fecha_proceso,101)
and   mo_numero_de_operacion = @w_op_operacion

if @@rowcount = 0 begin
   select @w_error = 710022
   goto ERROR
end  


/* JVC enero 2003 */
select
@w_naturaleza          = op_naturaleza,          
@w_tipo_linea          = op_tipo_linea,
@w_tipo                = op_tipo,
@w_programa            = op_subtipo_linea   

from ca_operacion 
where op_operacion = @w_numero_de_operacion 

if @w_naturaleza = 'A'
   select  @w_des_naturaleza = 'ACTIVA'
else   
    select  @w_des_naturaleza = 'PASIVA'

select @w_des_programa = ''

/*
select @w_des_programa = si_descripcion
from ca_subtipo_linea
where si_codigo  = @w_programa  */

/* JCQ 02/18/2003 Descripci½n del Programa de Credito en Tabla de Catalogos */

select @w_des_programa = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'ca_subtipo_linea'
and   X.codigo= Y.tabla
and   Y.codigo=   @w_programa
set transaction isolation level read uncommitted


select @w_desc_tipo = ''
select @w_desc_tipo = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla  = 'ca_tipo_prestamo'
and   X.codigo = Y.tabla
and   Y.codigo = @w_tipo    
set transaction isolation level read uncommitted
 
 
select @w_desc_origen_fondos = ''

select @w_categoria_linea = dt_categoria
from ca_default_toperacion --, ca_operacion
where dt_toperacion = @w_tipo_de_producto /* L­nea de Credito  JCQ 02/18/2003 */

select @w_desc_origen_fondos = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'ca_categoria_linea'
and   X.codigo= Y.tabla
and   Y.codigo= @w_categoria_linea
set transaction isolation level read uncommitted

    
select @w_des_entidad_presta = ''
select @w_des_entidad_presta = valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla
               where tabla  = 'ca_tipo_linea')
and   codigo = @w_tipo_linea   
set transaction isolation level read uncommitted

select @w_desc_destino = ''	    
select @w_desc_destino = valor
from cobis..cl_catalogo 
where tabla =(select codigo from cobis..cl_tabla 
	      where tabla = 'cr_destino')
and codigo    = @w_destino_credito
set transaction isolation level read uncommitted


/*ENVIO DE DATO AL FRONT-END */
       
select 
@w_fecha_de_proceso,		---1
@w_producto,			---2	
@w_tipo_de_producto,		---3
@w_moneda,			---4
@w_numero_de_operacion,		---5
@w_numero_de_banco,		---6
@w_numero_migrada,		---7
@w_cliente,			---8
@w_nombre_cliente,		---9
@w_linea_credito,		---10
@w_oficina,			---11
@w_nombre_oficina,		---12
@w_oficial,			---13
@w_nombre_oficial,		---14
@w_monto,			---15
@w_monto_desembolso,		---16
@w_tasa,			---17
@w_tasa_efectiva,		---18
@w_plazo_total,			---19
@w_modalidad_cobro_int,		---20
convert (varchar(10), @w_fecha_inicio_op,@i_formato_fecha),	---21
convert (varchar(10), @w_fecha_ven_op,@i_formato_fecha),	---22
@w_dias_vencido_op,		---23
@w_fecha_fin_min_div_ven,	---24
@w_reestructurada,		---25
convert (varchar(10), @w_fecha_ult_reest,@i_formato_fecha),	---26
@w_num_reestructuraciones,	---27
@w_num_cuotas_pagadas,		---28
@w_num_cuotas_pagadas_reest,	---29
@w_destino_credito,		---30
@w_clase_cartera,		---31
@w_ciudad,			---32	
@w_fecha_prox_vencimiento,	---33
@w_saldo_cuota_prox_venc,       ---34
@w_saldo_capital_vigente,	---35
@w_saldo_capital_vencido,	---36
@w_saldo_interes_vigente,       ---37
@w_saldo_interes_vencido,	---38
@w_saldo_interes_contingente,	---39
@w_saldo_mora_vigente,		---40
@w_saldo_mora_contingente,	---41
@w_saldo_seguro_vida_vigente,	---42
@w_saldo_seguro_vida_vencido,	---43
@w_saldo_otros_vigente,		---44
@w_saldo_otros_vencidos,	---45
@w_estado_obligacion,		---46
@w_calificacion_obligacion,	---47
@w_frecuencia_pago_int,		---48
@w_frecuencia_pago_cap,		---49
@w_edad_vencimiento_cartera,	---50
convert (varchar(10), @w_fecha_ult_pago,@i_formato_fecha),	---51
@w_valor_ult_pago,		---52
convert (varchar(10), @w_fecha_ult_pago_cap,@i_formato_fecha),	---53
@w_valor_ult_pago_cap,		---54
@w_valor_cuota_tabla,		---55
@w_numero_cuotas_pactadas,	---56
@w_numero_cuotas_vencidas,	---57
@w_tipo_garantia,		---58
@w_descripcion_tipo_garantia,	---59
@w_valor_total_garantias,	---60
convert (varchar(10), @w_fecha_castigo,@i_formato_fecha),	---61
@w_numero_comex,		---62	
@w_numero_deuda_externa,	---63
convert (varchar(10), @w_fecha_embarque,@i_formato_fecha),	---64
convert (varchar(10), @w_fecha_dex,@i_formato_fecha),	---65
@w_tipo_tasa,			---66
@w_tasa_referencial,		---67
@w_signo,			---68
@w_factor,			---69
@w_tipo_identificacion,		---70
@w_numero_identificacion,	---71
@w_provision_cap,		---72
@w_provision_int,		---73
@w_provision_cxc,		---74
@w_cuenta_asociada,		---75
@w_forma_de_pago,		---76
@w_tipo_tabla,			---77
@w_periodo_gracia_cap,		---78
@w_periodo_gracia_int,		---79
@w_estado_cobranza,		---80
@w_descripcion_estado_cobranza, ---81
@w_tasa_representativa_mercado,	---82
@w_reajustable,			---83
@w_descripcion_reajustable,	---84
@w_periodo_reajuste,		---85
convert (varchar(10), @w_fecha_prox_reajuste,@i_formato_fecha),	---86
@w_actualizada_fecha_valor,	---87
@w_estado_registro,		---88
convert (varchar(10), @w_fecha_ult_proceso,@i_formato_fecha),	---89
@w_naturaleza_juridica,		---90
@w_tipo_puntos,			---91	
@w_garantia,			---92
@w_des_clase_garantia,		---93
@w_clase_garantia,		---94
@w_valor_garantia,		---95
@w_cobertura_garantia,		---96
@w_ente_propietario_gar,	---97
@w_des_tipo_bien,		---98
@w_des_naturaleza,
@w_desc_tipo,                   --100
@w_desc_origen_fondos,
@w_des_entidad_presta,
@w_des_programa,
@w_desc_destino,                    --104
@w_tiene_seg_vida,              --105  JCQ 02/24/2003          
@w_tiene_seg_vehiculo,          --106
@w_tiene_seg_todor_maq,         --107
@w_tiene_seg_rotura_maq,        --108
@w_tiene_seg_vivienda,          --109
@w_tiene_seg_extraprima,        --110
@w_capitaliza,                  --111
@w_icr,                         --112
@w_condonacion_capital,         --113
@w_condonacion_interes,         --114
@w_provision_defecto,           --115
@w_llave_redescuento,           --116
@w_regional,                    --117
@w_zona,                        --118
@w_mercado_objetivo,            --119
@w_tipo_productor,              --120
@w_tipo_banca,                  --121
@w_ced_ruc_codeudor,            --122
@w_nombre_codeudor,             --123
@w_aprobador,                   --124
@w_codigo_sector		--125
	
    
return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error
                                                   
go
