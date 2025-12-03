/************************************************************************/
/*	Archivo: 		qrpgvirb.sp		 		*/
/*	Stored procedure: 	sp_consulta_pago_virtual_batch		*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Xavier Maldonado       			*/
/*	Fecha de escritura: 	Enero 2001				*/
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
/*	Consulta de los datos a pagar por medio de banca virtual        */
/*      cuando el modulo se encuentra FUERA DE LINEA                    */
/*                                                                      */
/************************************************************************/  
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_pago_virtual_batch')
	drop proc sp_consulta_pago_virtual_batch
go

create proc sp_consulta_pago_virtual_batch (
        @s_user                  login       = null,
        @s_ofi                   smallint    = null,
        @s_date                  datetime    = null,
        @s_term                  varchar(30) = null,
        @i_banco                 cuenta      = null       
)
as

declare @w_sp_name		 descripcion,
        @w_return		 int,
        @w_error                 int,
        @w_ente                  int,
        @w_nombre                descripcion, 
        @w_fecha_ini             datetime,
        @w_cuota_cancelar        int,
        @w_total_apagar          money,
        @w_monto_minimo          money,
        @w_monto_maximo          money,
        @w_fecha_vencimiento     datetime,
        @w_tasa                  float,
        @w_modalidad             char(1),
        @w_cuotas_pendientes     int,
        @w_saldo_precancelacion  money,         
        @w_plazo_total           int,
        @w_estado_prestamo       descripcion,
        @w_negociacion           char(1),
        @w_ro_porcentaje         float,
        @w_ro_referencial        catalogo,
        @w_moda                  char(20), 
        @w_td_tdividendo         catalogo,
        @w_descripcion           descripcion,
        @w_td_estado             estado,
        @w_td_factor             smallint,
        @w_es_descripcion        descripcion,
        @w_di_dividendo          smallint,  
        @w_op_operacionca        int,
        @w_op_banco              cuenta,
        @w_op_cliente            int,
        @w_op_nombre             descripcion,
        @w_op_toperacion         catalogo,
        @w_op_moneda             tinyint,
        @w_op_fecha_ini          datetime,
        @w_op_fecha_fin          datetime,
        @w_op_fecha_liq          datetime,
        @w_op_monto              money,
        @w_op_tipo               char(1),
        @w_op_dias_anio          smallint,
        @w_op_tplazo             catalogo,
        @w_op_plazo              smallint,
        @w_op_tipo_cobro         char(1),
        @w_op_tipo_reduccion     char(1),
        @w_op_estado             tinyint,
        @w_op_cuota_completa     char(1),
        @w_op_precancelacion     char(1),
        @w_op_aceptar_anticipos  char(1),
        @w_op_bvirtual           char(1),
        @w_plazo_total_dias      int,
        @w_plazo_total_desc      varchar(16),
        @w_tasa_aplicada         float,
        @w_vigente               tinyint,
        @w_vencido               tinyint,
        @w_cancelado             tinyint,
        @w_precancelado          tinyint,
        @w_condonado             tinyint,
        @w_anulado               tinyint,
        @w_credito               tinyint,
        @w_contador              tinyint,
        @w_cuota                 money,
        @w_di_estado             tinyint,
        @w_parametro             money,
        @w_di_fecha_ven          datetime,
        @w_numero_cuota          varchar(10),
        @w_total_pago_cuota      money,
        @w_di_fecha_ini          datetime 
         
            

/*  Captura nombre de Stored Procedure  */

select @w_sp_name = 'sp_consulta_pago_virtual_batch'

select @w_op_operacionca       = op_operacion,
       @w_op_banco             = op_banco,
       @w_op_cliente           = op_cliente,
       @w_op_nombre            = op_nombre,
       @w_op_toperacion        = op_toperacion,
       @w_op_moneda            = op_moneda,
       @w_op_fecha_ini         = op_fecha_ini,
       @w_op_fecha_fin         = op_fecha_fin,
       @w_op_fecha_liq         = op_fecha_liq,
       @w_op_monto             = op_monto,
       @w_op_estado            = op_estado,
       @w_op_cuota_completa    = op_cuota_completa,
       @w_op_tipo_cobro        = op_tipo_cobro,
       @w_op_tipo_reduccion    = op_tipo_reduccion,
       @w_op_aceptar_anticipos = op_aceptar_anticipos,
       @w_op_precancelacion    = op_precancelacion,
       @w_op_bvirtual          = op_bvirtual,
       @w_op_tplazo            = op_tplazo,
       @w_op_plazo             = op_plazo
       from ca_operacion_virtual
where op_banco = @i_banco                

if @@rowcount = 0 begin
   return 705068
end


select @w_ro_porcentaje  = ro_porcentaje,
@w_ro_referencial = ro_referencial
from ca_rubro_op_virtual
where ro_operacion = @w_op_operacionca
and ro_concepto = 'INT'

/*MODALIDAD APLICADA*/
/********************/
select @w_modalidad = tv_modalidad 
from ca_tasa_valor_virtual  
where tv_nombre_tasa = @w_ro_referencial

if @w_modalidad = 'A'
   select @w_moda = 'ANTICIPADO'
else
   select @w_moda = 'VENCIDO'         


/*TASA APLICADA AL PRESTAMO*/
/***************************/

select @w_tasa_aplicada = @w_ro_porcentaje


/*PLAZO TOTAL DEL CREDITO*/
/*************************/

select 
@w_td_tdividendo = td_tdividendo,
@w_td_factor     = td_factor,
@w_descripcion   = td_descripcion 
from ca_tdividendo_virtual
where td_tdividendo = @w_op_tplazo


select @w_plazo_total_dias = @w_td_factor * @w_op_plazo

if @w_td_tdividendo = 'A'
   select @w_descripcion = 'A¥OS'
if @w_td_tdividendo = 'M'
   select @w_descripcion = 'MESES'
if @w_td_tdividendo = 'D'
   select @w_descripcion = 'DIAS'
if @w_td_tdividendo = 'S'
   select @w_descripcion = 'SEMESTRES'
if @w_td_tdividendo = 'B'
   select @w_descripcion = 'BIMESTRES'
if @w_td_tdividendo = 'T'
   select @w_descripcion = 'TRIMESTRES'
if @w_td_tdividendo = 'Q'
   select @w_descripcion = 'QUINCENAS'

select @w_plazo_total_desc = convert(varchar(10),@w_op_plazo) + "" + @w_descripcion



/*   CUOTAS PENDIENTES   */
/*************************/

select @w_vencido = es_codigo
from ca_estado_virtual
where es_descripcion = 'VENCIDO'

select @w_vigente = es_codigo
from ca_estado_virtual
where es_descripcion = 'VIGENTE'

select @w_cancelado = es_codigo
from ca_estado_virtual
where es_descripcion = 'CANCELADO'

select @w_precancelado = es_codigo
from ca_estado_virtual
where es_descripcion = 'PRECANCELADO'

select @w_anulado = es_codigo
from ca_estado_virtual
where es_descripcion = 'ANULADO'

select @w_condonado = es_codigo
from ca_estado_virtual
where es_descripcion = 'CONDONADO'

select @w_credito = es_codigo
from ca_estado_virtual
where es_descripcion = 'CREDITO'

select @w_cuotas_pendientes = count(*) 
from ca_dividendo_virtual
where di_operacion = @w_op_operacionca
and di_estado not in (@w_cancelado,@w_precancelado,@w_anulado,@w_condonado,@w_credito)


/*  ESTADO DEL PRESTAMO  */
/*************************/

select @w_estado_prestamo = es_descripcion
from ca_estado_virtual
where es_codigo = @w_op_estado

if @@rowcount = 0 begin
   return 710123
end

declare dividendo_pago cursor for
select di_estado,di_dividendo,di_fecha_ini,di_fecha_ven
from ca_dividendo_virtual,ca_estado_virtual
where di_operacion    = @w_op_operacionca
and di_estado       = es_codigo 
and es_procesa      = 'S'
and es_acepta_pago  = 'S'
for read only

open dividendo_pago

fetch dividendo_pago into @w_di_estado, @w_di_dividendo, @w_di_fecha_ini, @w_di_fecha_ven

if (@@fetch_status != 0) begin
   close dividendo_pago
   return 710124
end

while (@@fetch_status = 0) begin 

   /*   CUOTA A CANCELAR    */
   /*************************/
    
   select @w_contador = 1

   if @w_contador = 1 begin
      select @w_numero_cuota = convert(varchar(10),@w_di_dividendo) 
   end
   else begin
      select @w_numero_cuota = @w_numero_cuota + ';' + convert(varchar(10),@w_di_dividendo)
   end
 

   /* TOTAL A PAGAR POR CUOTA y FECHA VENCIMIENTO  */
   /************************************************/

   if @w_vigente = @w_di_estado begin  -- Suma todo lo vencido y lo vigente a la fecha
      select @w_cuota = isnull(sum(am_cuota),0)
      from ca_dividendo_virtual,ca_amortizacion_virtual,ca_rubro_op_virtual
      where am_operacion = ro_operacion
      and am_operacion = @w_op_operacionca
      and am_dividendo = di_dividendo
      and am_concepto  = ro_concepto
      and di_estado    = @w_vigente

      select @w_total_pago_cuota = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from ca_dividendo_virtual,ca_amortizacion_virtual,ca_rubro_op_virtual
      where am_operacion = ro_operacion
      and am_operacion = @w_op_operacionca
      and am_dividendo = di_dividendo
      and am_concepto = ro_concepto
      and di_estado   in (@w_vencido,@w_vigente)

      select @w_fecha_vencimiento = @w_di_fecha_ven
   end


   /*   SALDO PRECANCELACION  */
   /***************************/

   if @w_op_precancelacion = 'S' and @w_contador = 1
      select @w_saldo_precancelacion = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from ca_dividendo_virtual,ca_amortizacion_virtual,ca_rubro_op_virtual
      where am_operacion = ro_operacion
      and am_operacion = @w_op_operacionca
      and am_dividendo = di_dividendo
      and am_concepto = ro_concepto
      and di_estado  not in (@w_cancelado,@w_precancelado,@w_anulado,@w_condonado,@w_credito)
   else
      select @w_saldo_precancelacion = 0



   /*   MONTO MINIMO Y MAXIMO A PAGAR  */
   /*************************************/
   
   if @w_op_cuota_completa = 'S' and @w_op_aceptar_anticipos = 'S'
   begin
      select @w_monto_minimo = @w_cuota
      select @w_monto_maximo = @w_saldo_precancelacion
   end

   if @w_op_cuota_completa = 'S'  and    @w_op_aceptar_anticipos = 'N'
   begin
      select @w_monto_minimo = @w_cuota
      select @w_monto_maximo = @w_cuota
   end

   if @w_op_cuota_completa = 'N'  and    @w_op_aceptar_anticipos = 'S'
   begin
      select @w_parametro = 1000   --por ahora
      select @w_monto_minimo = @w_parametro
      select @w_monto_maximo = @w_saldo_precancelacion
   end

   if @w_op_cuota_completa = 'N'  and    @w_op_aceptar_anticipos = 'N'
   begin
      select @w_parametro = 1000   --por ahora
      select @w_monto_minimo = @w_parametro
      select @w_monto_maximo = @w_cuota
   end

   select @w_contador = @w_contador + 1


    fetch dividendo_pago into @w_di_estado, @w_di_dividendo, @w_di_fecha_ini, @w_di_fecha_ven
end
close dividendo_pago
deallocate dividendo_pago


select 
@w_tasa_aplicada,
@w_plazo_total_desc,
@w_op_fecha_ini,
@w_moda,
@w_numero_cuota,
@w_cuotas_pendientes,
@w_total_pago_cuota,
@w_fecha_vencimiento,  
@w_estado_prestamo,
@w_saldo_precancelacion,
@w_monto_minimo,
@w_monto_maximo,
@w_op_aceptar_anticipos       


return 0

go

