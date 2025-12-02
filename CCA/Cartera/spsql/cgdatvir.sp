/************************************************************************/
/*	Archivo:            cgdatvir.sp                                     */
/*	Stored procedure:   sp_carga_datos_virtual                          */
/*	Base de datos:      cob_cartera                                     */
/*	Producto:           Cartera                                         */
/*	Disenado por:       Xavier Maldonado                                */
/*	Fecha de escritura: Enero 2001                                      */
/************************************************************************/
/*				IMPORTANTE                                              */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	"MACOSA".                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier alteracion o agregado hecho por alguno de sus             */
/*	usuarios sin el debido consentimiento por escrito de la             */
/*	Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*				PROPOSITO                                               */
/*	Procedimiento que ingresa infromacion para consultarla por          */
/*	medio de banca virtual.                                             */
/************************************************************************/
/*				MODIFICACIONES                                          */
/*	FECHA		AUTOR	    	RAZON                                   */
/*  Abr-03-2008 Miguel Roa      Eliminación de creación de tablas en el */
/*                              SP                                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_carga_datos_virtual')
   drop proc sp_carga_datos_virtual
go

create proc sp_carga_datos_virtual(
            @i_banco             	cuenta   = null 
)

as

declare 
@w_error          	int,
@w_return         	int,
@w_sp_name        	descripcion,
@w_fecha_proceso        datetime,
@w_fecha_proceso_sal_pro  datetime,
@w_est_vigente    	tinyint,
@w_est_vencido    	tinyint,
@w_est_novigente 	tinyint,
@w_est_cancelado  	tinyint,
@w_est_credito    	tinyint,
@w_est_suspenso	  	tinyint,
@w_est_castigado  	tinyint,
@w_est_comext           tinyint,
@w_op_operacion         int,
@w_op_banco             cuenta,
@w_op_cliente           int,
@w_op_nombre            descripcion,
@w_op_toperacion        catalogo,
@w_op_moneda            tinyint,
@w_op_fecha_ini         datetime,
@w_op_fecha_fin         datetime,
@w_op_fecha_liq         datetime,
@w_op_monto             money,
@w_op_estado            int,
@w_op_cuota_completa    char(1),
@w_op_tipo_cobro        char(1),
@w_op_tipo_reduccion    char(1),
@w_op_aceptar_anticipos char(1),
@w_op_precancelacion    char(1),
@w_op_bvirtual          char(1),
@w_op_tplazo            catalogo,
@w_op_plazo             smallint 


/** CARGADO DE VARIABLES DE TRABAJO **/
/*************************************/
select 
@w_sp_name       = 'sp_carga_datos_virtual' 


/* SELECCION DE ESTADO */
/***********************/

select @w_est_novigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

select @w_est_vigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CANCELADO'

select @w_est_credito  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CREDITO'

select @w_est_suspenso  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'SUSPENSO'

select @w_est_comext  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'COMEXT'

select @w_est_castigado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CASTIGADO'



/* CARGA DE DATOS EN LA TABLA CA_TASA_VALOR_VIRTUAL*/
/***************************************************/
insert  into ca_tasa_valor_virtual
select * from ca_tasa_valor



/* CARGA DE DATOS EN LA TABLA CA_TDIVIDENDO_VIRTUAL*/
/***************************************************/
insert  into ca_tdividendo_virtual
select * from ca_tdividendo



/* CARGA DE DATOS EN LA TABLA CA_ESTADO_VIRTUAL*/
/***********************************************/
insert  into ca_estado_virtual
select * from ca_estado




/* CURSOR PARA LEER TODAS LAS OPERACIONES A PROCESAR */
/*****************************************************/

declare cursor_operacion cursor for
select 
op_operacion,      op_banco,          op_cliente,
op_nombre,         op_toperacion,     op_moneda,
op_fecha_ini,      op_fecha_fin,      op_fecha_liq,
op_monto,          op_estado,         op_cuota_completa,
op_tipo_cobro,     op_tipo_reduccion, op_aceptar_anticipos,
op_precancelacion, op_bvirtual,       op_tplazo,
op_plazo   
from  ca_operacion
where op_estado not in (@w_est_novigente, @w_est_cancelado, @w_est_credito,
                        @w_est_comext, @w_est_castigado)
and   op_bvirtual = 'S' 
for read only

open  cursor_operacion

fetch cursor_operacion into 
@w_op_operacion,      @w_op_banco,          @w_op_cliente,
@w_op_nombre,         @w_op_toperacion,     @w_op_moneda,
@w_op_fecha_ini,      @w_op_fecha_fin,      @w_op_fecha_liq, 
@w_op_monto,          @w_op_estado,         @w_op_cuota_completa,
@w_op_tipo_cobro,     @w_op_tipo_reduccion, @w_op_aceptar_anticipos,
@w_op_precancelacion, @w_op_bvirtual,       @w_op_tplazo,
@w_op_plazo

if (@@fetch_status != 0) begin
    close cursor_operacion
    return 710124
end

while (@@fetch_status = 0 ) begin 


 /* CARGA DE DATOS EN LA TABLA CA_OPERACION_VIRTUAL*/
 /***********************************************/

   insert  into ca_operacion_virtual
    values (@w_op_operacion,      @w_op_banco,          @w_op_cliente,
	    @w_op_nombre,         @w_op_toperacion,     @w_op_moneda,
	    @w_op_fecha_ini,      @w_op_fecha_fin,      @w_op_fecha_liq, 
	    @w_op_monto,          @w_op_estado,         @w_op_cuota_completa,
	    @w_op_tipo_cobro,     @w_op_tipo_reduccion, @w_op_aceptar_anticipos,
	    @w_op_precancelacion, @w_op_bvirtual,       @w_op_tplazo,
	    @w_op_plazo)


 /* CARGA DE DATOS EN LA TABLA CA_RUBRO_OP_VIRTUAL*/
 /***********************************************/

    insert into ca_rubro_op_virtual
    select ro_operacion,         ro_concepto,           ro_tipo_rubro,
           ro_fpago,             ro_prioridad,          ro_referencial,
           ro_valor,             ro_porcentaje,         ro_num_dec,
           ro_limite
      from ca_rubro_op
     where ro_operacion = @w_op_operacion



 /* CARGA DE DATOS EN LA TABLA CA_DIVIDENDO_VIRTUAL*/
 /***********************************************/

    insert into ca_dividendo_virtual
    select * from ca_dividendo
     where di_operacion = @w_op_operacion



 /* CARGA DE DATOS EN LA TABLA CA_AMORTIZACION_VIRTUAL*/
 /***********************************************/

    insert into ca_amortizacion_virtual
    select * from ca_amortizacion
     where am_operacion = @w_op_operacion


   fetch cursor_operacion into
   @w_op_operacion,      @w_op_banco,          @w_op_cliente,
   @w_op_nombre,         @w_op_toperacion,     @w_op_moneda,
   @w_op_fecha_ini,      @w_op_fecha_fin,      @w_op_fecha_liq, 
   @w_op_monto,          @w_op_estado,         @w_op_cuota_completa,
   @w_op_tipo_cobro,     @w_op_tipo_reduccion, @w_op_aceptar_anticipos,
   @w_op_precancelacion, @w_op_bvirtual,       @w_op_tplazo,
   @w_op_plazo

end /* cursor_operacion */

close cursor_operacion
deallocate cursor_operacion

set rowcount 0

return 0

go

