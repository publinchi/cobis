/************************************************************************/
/*	Archivo: 		qrbanvir.sp		 		*/
/*	Stored procedure: 	sp_consulta_banca_virtual		*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Marcelo Poveda       			*/
/*	Fecha de escritura: 	Mayo 2001				*/
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
/*      cuando el modulo se encuentra en LINEA                          */
/*                                                                      */
/************************************************************************/  
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_consulta_banca_virtual')
	drop proc sp_consulta_banca_virtual
go

create proc sp_consulta_banca_virtual 
        @i_banco                 cuenta      = null,
	@i_opcion		 char(1)     = null,
	@i_formato_fecha	 tinyint     = 101
as
declare
	@w_return 		int,
	@w_error		int,
	@w_bv_saldo_deudor	money,
	@w_bv_total_pagar	money,
	@w_bv_precancelar	char(1),
	@w_bv_cuota_completa	char(1),
	@w_bv_tipo_reduccion	char(1),
	@w_bv_aceptar_anticp	char(1),
	@w_bv_tipo_credito	catalogo,
	@w_bv_no_obligacion	cuenta,
	@w_bv_cliente		descripcion,
	@w_bv_fecha_consulta	datetime,
	@w_monto_minimo		money,
	@w_monto_maximo		money,
	@w_producto		tinyint,
	@w_en_linea		char(1),
	@w_estado		char(1),
	@w_sp_name		varchar(20)


/** INICIALIZACION VARIABLES **/
/******************************/
select @w_en_linea = 'N',
@w_sp_name = 'sp_consulta_banca_virtual'

/** DETERMINAR SI PRODUCTO ESTA EN LINEA **/
/*****************************************/
select @w_producto = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted

select @w_estado = pm_estado
from  cobis..cl_pro_moneda
where pm_producto = @w_producto
and   pm_moneda = 0
and   pm_tipo = 'R'
set transaction isolation level read uncommitted

if @w_estado = 'V' select @w_en_linea = 'S'

if @w_en_linea = 'S' begin
   exec @w_return = sp_datos_op_bv
   @i_banco = @i_banco

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end
end

if @i_opcion = 'G' begin
   select 
   'No. Obligacion:' = bv_no_obligacion,
   'Tipo de Credito:' = bv_tipo_credito,
   'Oficina:' = bv_oficina,
   'Fecha de Corte:' = convert(varchar(10),bv_fecha_consulta,@i_formato_fecha),
   'Fecha Ultimo Pago:' = convert(varchar(10),bv_fecha_ult_pago,@i_formato_fecha),
   'Valor Inicial:' = bv_monto_inicial,
   'Tasa Efectiva De Interes:' = bv_tef_int,
   'Tasa Efectiva de Mora:' = bv_tef_mora,
   'Cuota Actual:' = bv_div_actual,
   'Fecha Inicial:' = convert(varchar(10),bv_fecha_ini,@i_formato_fecha),
   'Fecha Final:' = convert(varchar(10),bv_fecha_fin,@i_formato_fecha),
   'Fecha Proximo Pago:' = convert(varchar(10),bv_fecha_prox_pago,@i_formato_fecha),
   'Valor a Pagar Fec. Prox. Pago:' = bv_valor_a_pagar,
   'Saldo Total:' = bv_saldo_deudor,
   'Saldo Capital:' = bv_saldo_cap,
   'Saldo de Intereses:' = bv_saldo_int,
   'Saldo de Intereses de Mora:' = bv_saldo_mora,
   'Saldo Otros Rubros:' = bv_saldo_otros
   from ca_dat_oper_bv_tmp
   where bv_no_obligacion = @i_banco
end


if @i_opcion = 'P' begin
   select 
   @w_bv_saldo_deudor	= bv_saldo_deudor,
   @w_bv_total_pagar	= bv_total_pagar,
   @w_bv_precancelar	= bv_precancelar,
   @w_bv_cuota_completa	= bv_cuota_completa,
   @w_bv_tipo_reduccion	= bv_tipo_reduccion,
   @w_bv_aceptar_anticp	= bv_aceptar_anticp,
   @w_bv_tipo_credito   = bv_tipo_credito,
   @w_bv_no_obligacion  = bv_no_obligacion,
   @w_bv_cliente        = bv_cliente,
   @w_bv_fecha_consulta = bv_fecha_consulta
   from ca_dat_oper_bv_tmp
   where bv_no_obligacion = @i_banco

   /*   MONTO MINIMO Y MAXIMO A PAGAR  */
   /*************************************/
   if @w_bv_precancelar = 'S' begin
      if @w_bv_aceptar_anticp = 'S' begin
         if @w_bv_cuota_completa = 'S' begin
            select @w_monto_minimo = @w_bv_total_pagar,
	    @w_monto_maximo = @w_bv_saldo_deudor
         end else begin
            select @w_monto_minimo = 1000,
            @w_monto_maximo = @w_bv_saldo_deudor
         end 
      end else begin
         if @w_bv_cuota_completa = 'S' begin
            select @w_monto_minimo = @w_bv_total_pagar,
	    @w_monto_maximo = @w_bv_total_pagar
         end else begin
            select @w_monto_minimo = 1000,
            @w_monto_maximo = @w_bv_total_pagar
         end 
      end
   end else begin
      select @w_bv_saldo_deudor = 0
      select @w_bv_aceptar_anticp = 'N'
      if @w_bv_cuota_completa = 'S' begin
         select @w_monto_minimo = @w_bv_total_pagar,
	 @w_monto_maximo = @w_bv_total_pagar
      end else begin
         select @w_monto_minimo = 1000,
         @w_monto_maximo = @w_bv_total_pagar
      end   
   end
   
   /** RETORNO DE INFORMACION **/
   /****************************/
   select 
   'Obligacion:'	      = @w_bv_no_obligacion,
   'Tipo de Credito:'     = @w_bv_tipo_credito,
   'Cliente:' 	          = @w_bv_cliente,
   'Fecha de Corte:'	  = convert(varchar(10),@w_bv_fecha_consulta,@i_formato_fecha),
   'Valor a Pagar Fecha de Corte:' = @w_bv_total_pagar,
   'Pago Total Deuda:'     = @w_bv_saldo_deudor,
   'Monto Minimo:'         = @w_monto_minimo,
   'Monto Maximo:'         = @w_monto_maximo,
   'Cuota Completa:'       = @w_bv_cuota_completa,
   'Acepta Precancelar:'   = @w_bv_precancelar,
   'Tipo Reduccion:'       = @w_bv_tipo_reduccion,
   'Acepta Anticipo:'      = @w_bv_aceptar_anticp
end


return 0

ERROR:
exec cobis..sp_cerror
@t_debug  = 'N',    
@t_file   =  null,
@t_from   =  @w_sp_name,   
@i_num    =  @w_error
return @w_error    

go

