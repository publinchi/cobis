/************************************************************************/
/*	Archivo: 		impestad.sp				*/
/*	Stored procedure: 	sp_imp_estado_op			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Francisco Yacelga 			*/
/*	Fecha de escritura: 	15/Dic./1997				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Consulta para imprimir el estado de situacion de la operacion   */
/************************************************************************/

use cob_cartera
go

set ansi_nulls off
go
 
if exists (select 1 from sysobjects where name = 'sp_imp_estado_op')
   drop proc sp_imp_estado_op
go

create proc sp_imp_estado_op (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_rty               char(1)     = null,
   @t_debug          	char(1)     = 'N',
   @t_file         	varchar(14) = null,
   @t_trn		smallint    = null,  
   @i_operacion         char(1)     = null,
   @i_banco		cuenta      = null,
   @i_formato_fecha	int         = null
)
as
declare	@w_sp_name			varchar(32),
       	@w_return			int,
	@w_error        		int,
        @w_operacionca                  int,
        @w_tamanio                      int,
        @w_sec_ing                      int,
        @w_sec_pag                      int,
        @w_estado                       char(3),
        @w_tipo                         char(1),    
        @w_det_producto			int,
        @w_cliente                      int,
        @w_nombre                       varchar(60),
        @w_ced_ruc                      varchar(15),
        @w_toperacion_desc              varchar(100),
        @w_moneda                       tinyint,
        @w_moneda_desc                  varchar(30),
        @w_fecha_crea                   varchar(10),
        @w_rowcount                     int


/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_imp_estado_op'


/* CABECERA DE LA IMPRESION */
if @i_operacion = 'C'
begin
   select 
   @w_operacionca       = op_operacion ,
   @w_cliente           = op_cliente, 
   @w_toperacion_desc   = A.valor,
   @w_moneda            = op_moneda,
   @w_moneda_desc       = mo_descripcion,
   @w_fecha_crea        = op_fecha_ini
   from ca_operacion, cobis..cl_catalogo A, cobis..cl_moneda
   where op_banco    = @i_banco
   and op_toperacion = A.codigo
   and op_moneda     = mo_moneda

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end  

   /*DEUDOR*/
   /*  Encuentra el Producto  */
   select @w_tipo = pd_tipo
   from cobis..cl_producto
   where pd_producto = 7
   set transaction isolation level read uncommitted

   /*  Encuentra el Detalle de Producto  */
   select 
   @w_det_producto = dp_det_producto
   from	cobis..cl_det_producto
   where dp_producto = 7
   and	dp_tipo   = @w_tipo
   and	dp_moneda = @w_moneda
   and	dp_cuenta = @i_banco
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 
   begin
       select @w_error = 710023
       goto ERROR
   end

   /*Realizar la consulta de Informacion General de Cliente*/

   select 
   @w_ced_ruc  = isnull(cl_ced_ruc,p_pasaporte), 
   @w_nombre   = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' 
                 + rtrim(en_nombre),1,60))
   from cobis..cl_cliente,cobis..cl_ente
   where 
   cl_det_producto   = @w_det_producto
   and cl_rol        = 'D'
   and en_ente       = cl_cliente                                         
   and cl_cliente    = @w_cliente
   set transaction isolation level read uncommitted

   select
   @w_cliente,         @w_nombre,      @w_ced_ruc,
   @w_toperacion_desc, @w_moneda_desc, @w_fecha_crea
       
end

/*DETALLE DE LAS TRANSACCIONES */
if @i_operacion = 'D' 
begin     

set rowcount 100

   select 
   tr_secuencial,
   tr_dias_calc,
   tr_fecha_mov,
   (select isnull(tt_descripcion,null) from ca_tipo_trn where A.tr_tran = tt_codigo),   
   tr_moneda,
   dtr_dividendo,
   dtr_concepto,   
   isnull((select isnull(tt_descripcion,null) from ca_tipo_trn where A.tr_tran = tt_codigo and B.dtr_concepto = tt_codigo),(select cp_descripcion from ca_producto where B.dtr_concepto = cp_producto )),
   dtr_monto,
   dtr_moneda,
   dtr_cotizacion,
   dtr_cuenta
   from ca_transaccion A, ca_det_trn B   
   where tr_banco    = @i_banco
   and tr_secuencial = dtr_secuencial
   and tr_operacion  = dtr_operacion
end
 
return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go