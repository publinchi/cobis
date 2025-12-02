/************************************************************************/
/*	Archivo:		pagonomi.sp        			*/
/*	Stored procedure:	sp_pago_nomina                          */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Angela Ramirez				*/
/*	Fecha de escritura:	jun  98 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*      Generacion del valor a pagar por concepto de nomina             */
/*      para un archivo en formato de descuentos directos       	*/
/************************************************************************/
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	26/jun/98      A. Ramirez         Emision Inicial               */
/*					  PERSONALIZACION B.ESTADO      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_nomina')
	drop proc sp_pago_nomina
go

create proc sp_pago_nomina
	@i_cedula		varchar(30) = NULL,
       	@i_valor		money       = NULL,
        @o_compania             int         = NULL out,
        @o_forma_pago           varchar(10) = NULL out,
        @o_referencia           cuenta      = NULL out,
        @o_cliente              int         = NULL out,      
        @o_operacion            cuenta      = NULL out,
        @o_valor_abono          money       = NULL out
as
declare @w_sp_name		descripcion,
        @w_operacionca          int,
        @w_banco                cuenta,
        @w_ente                 int,
        @w_por_abono		float,
        @w_forma_pago		catalogo,
        @w_vivienda		varchar(30),
        @w_return               int,
        @w_error                int,
        @w_rowcount             int


/*  NOMBRE DEL SP */
select	@w_sp_name = 'sp_pago_nomina'

/* OBTENER EL CODIGO DEL CLIENTE */
select
@w_ente = en_ente
from cobis..cl_ente
where en_ced_ruc = @i_cedula
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 710104	/*EL NUMERO DE CEDULO NO CORRESPODE A */
   goto ERROR			/*NINGUN CLIENTE		      */
end        

/*OBTENER PARAMETRO PARA TIPO DE PRESTAMO VIVIENDA*/
select @w_vivienda = pa_char
from cobis..cl_parametro
where pa_nemonico = 'VIV'
and pa_producto   = 'CCA'
set transaction isolation level read uncommitted

/*OBTENER EL NUMERO DE OPERACION PARA ESTE CLIENTE*/
select 
@w_operacionca = op_operacion,
@w_banco       = op_banco
from ca_operacion
where op_cliente    = @w_ente
and   op_toperacion = @w_vivienda

if @@rowcount = 0
begin
   select @w_error = 710022	/*NO EXISTE LA OPERACION*/
   goto ERROR
end        

/*OBTENER EL PORCENTAJE DE ABONO PARA CESANTIAS PARA ESTA OPERACION*/
select
@w_por_abono = dn_por_abono
from ca_definicion_nomina
where dn_operacion = @w_operacionca
and   dn_concepto  = '3'  /*QUEMADO PARA CONCEPTO CESANTIAS*/

if @@rowcount = 0
begin
   select @w_error = 710105    /*NO EXISTE REGISTRO PARA NOMINA*/
   goto ERROR
end    


/*RETORNO DE VALORES PARA DESCUENTOS DIRECTOS*/
select @o_compania    = 1
select @o_forma_pago  = 'FPNOM'
select @o_referencia  = 'FORMA DE PAGO PARA NOMINA'
select @o_cliente     = @w_ente
select @o_operacion   = @w_banco
select @o_valor_abono = (@i_valor * @w_por_abono)/100

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug = 'N',          @t_file = null,
   @t_from  = @w_sp_name,   @i_num  = @w_error
   return @w_error
go

