/************************************************************************/
/*	Archivo:		consnota.sp				*/
/*	Stored procedure:	sp_consulta_notas			*/
/*	Disenado por:  		Elcira Pelaez				*/
/*	Fecha de escritura:	Oct-19-2001 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	Procedimiento que realiza  la generacion de notas debito        */
/*	automaticas a las operaciones con esta forma de pago            */
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*  								        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_notas')
   drop proc sp_consulta_notas
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_consulta_notas
@s_user		     	login = null,
@s_term		     	varchar(30) = null,
@s_ofi		     	smallint = null,
@i_fecha_proceso        datetime,
@i_cotizacion		money

as

declare 
@w_error          	int,
@w_return         	int,
@w_sp_name        	descripcion,
@w_aceptar_anticipos    char(1),
@w_tipo_reduccion       char(1),
@w_tipo_cobro           char(1),
@w_tipo_aplicacion      char(1),
@w_oficina              smallint,
@w_forma_pago           catalogo,
@w_cuenta               cuenta,
@w_est_novigente 	tinyint,
@w_est_cancelado  	tinyint,
@w_est_credito    	tinyint,
@w_est_suspenso	  	tinyint,
@w_est_castigado  	tinyint,
@w_est_anulado          tinyint,
@w_est_comext           tinyint,
@w_moneda_nacional      tinyint,
@w_toperacion 		catalogo,
@w_naturaleza           char(1),
@w_commit               char(1),
@w_banco                cuenta,
@w_operacionca          int,
@w_retencion            smallint,
@w_moneda_pag           smallint,
@w_div_vencidos         int,
@w_concepto		catalogo,
@w_secuencial		int,
@w_prioridad		int,
@w_dividendo		int,
@w_monto_peso		money,
@w_monto		money,
@w_cliente		int,
@w_nombre		descripcion


/** CARGADO DE VARIABLES DE TRABAJO **/
select 
@w_sp_name       = 'sp_consulta_notas',
@s_user          = isnull(@s_user, 'sa'),
@s_term          = isnull(@s_term, 'CONSOLA'),
@s_ofi           = isnull(@s_ofi , 900)


select @w_est_novigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

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

select @w_est_anulado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'ANULADO'

/* TABLA TEMPORAL */
create table #datos(
toperacion	catalogo	null,
banco		cuenta		null,
cliente		int		null,
nombre		descripcion	null,
forma		catalogo	null,
numcuenta	cuenta		null,
monto		money		null,
montomn		money		null
)

/*PARAMETROS GENERALES */
select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


/* CURSOR PARA LEER LAS OPERACIONES A PROCESAR */
declare cursor_operacion cursor for
select
op_banco,
op_operacion,
op_aceptar_anticipos,
op_tipo_reduccion,
op_tipo_cobro,
op_tipo_aplicacion,
op_oficina,
op_forma_pago,
op_cuenta,
cp_retencion,
cp_moneda,
di_dividendo,
op_cliente,
op_nombre,
op_toperacion
from   ca_operacion,ca_producto, ca_dividendo, ca_default_toperacion
where  op_forma_pago = cp_producto
and    cp_pago_aut = 'S'
and    op_cuenta is not null
and    op_estado not in (0,3,4,6,98,99)
and    op_moneda != 0
and    di_fecha_ven = @i_fecha_proceso
and    op_operacion = di_operacion
and    op_toperacion = dt_toperacion
and    dt_naturaleza = 'A'
order by op_toperacion, op_banco
for read only

open  cursor_operacion

fetch cursor_operacion into 
@w_banco,
@w_operacionca,
@w_aceptar_anticipos,
@w_tipo_reduccion,
@w_tipo_cobro,
@w_tipo_aplicacion,
@w_oficina,
@w_forma_pago,
@w_cuenta,
@w_retencion,
@w_moneda_pag,
@w_dividendo,
@w_cliente,
@w_nombre,
@w_toperacion

while @@fetch_status = 0 begin   

   /** SELECCIONAR EL MONTO A DEBITAR **/
   select  @w_monto_peso = round(sum(am_cuota + am_gracia - am_pagado) * @i_cotizacion, 0),
   @w_monto =  sum(am_cuota + am_gracia - am_pagado)
   from    ca_amortizacion
   where   am_operacion = @w_operacionca
   and     am_dividendo = @w_dividendo
   and     am_concepto in ('INT','INTANT')

   if @w_monto != 0
      insert into #datos (
      toperacion,	banco,		cliente,	nombre,
      forma,		numcuenta,	monto,
      montomn)
      values (
      @w_toperacion,	@w_banco,	@w_cliente,	@w_nombre,
      @w_forma_pago,	@w_cuenta,	@w_monto,
      @w_monto_peso)
  
fetch cursor_operacion into 
@w_banco,
@w_operacionca,
@w_aceptar_anticipos,
@w_tipo_reduccion,
@w_tipo_cobro,
@w_tipo_aplicacion,
@w_oficina,
@w_forma_pago,
@w_cuenta,
@w_retencion,
@w_moneda_pag,
@w_dividendo,
@w_cliente,
@w_nombre,
@w_toperacion

end /* cursor_operacion */


close cursor_operacion
deallocate cursor_operacion

select * from #datos

return 0
go

