/************************************************************************/
/*	Archivo: 		imptrans.sp				*/
/*	Stored procedure: 	sp_imp_transaccion   		        */
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Francisco Yacelga 			*/
/*	Fecha de escritura: 	16/Dic./1997				*/
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
/*	Consulta de los datos de una transaccion                 	*/
/************************************************************************/

use cob_cartera
go
 
set ansi_nulls off
go

if exists (select 1 from sysobjects where name = 'sp_imp_transaccion')
   drop proc sp_imp_transaccion
go

create proc sp_imp_transaccion (
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
   @i_operacion		char(30)    = null,
   @i_formato_fecha	int         = null,
   @i_banco		cuenta      = null,
   @i_secuencial        int         = null
)

as
declare	@w_sp_name			varchar(32),
       	@w_return			int,
	@w_error        		int,
        @w_det_producto			int,
        @w_tipo                         char(1),
        @w_tramite			int,
        @w_usuario                      varchar(100),
        @w_terminal                     varchar(30), 
        @w_num_liq                      int, 
        @w_fecha                        varchar(15),
        @w_oficina                      varchar(30),
        @w_ciudad_trn                   varchar(30),
        @w_ttran_desc                   varchar(60),
        @w_toperacion                   varchar(60), 
        @w_moneda_trn                   varchar(30),  
        @w_secuencial                   int,
        @w_cliente                      int,
        @w_nombre                       varchar(30),    
        @w_ced_ruc                      varchar(15), 
        @w_moneda                       tinyint, 
        @w_moneda_op                    varchar(30), 
        @w_monto_op                     money,
        @w_fecha_crea                   varchar(15),
	@w_ref_exterior 		cuenta,
	@w_fec_embarque			varchar(15),
	@w_fec_dex           		varchar(15),
	@w_num_deuda_ext    		cuenta,
	@w_num_comex    		cuenta,
        @w_operacionca                  int,
        @w_rowcount                     int



/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_imp_transaccion'

/* CHEQUE DE EXISTA LA OPERACION */



if @i_operacion='C'
begin
   select    
   @w_usuario        = fu_nombre,
   @w_terminal       = tr_terminal,   
   @w_num_liq        = tr_dias_calc,
   @w_fecha          = convert(varchar,tr_fecha_mov,@i_formato_fecha),
   @w_oficina        = of_nombre,
   @w_ciudad_trn     = ci_descripcion,
   @w_ttran_desc     = tt_descripcion,
   @w_toperacion     = valor,
   @w_moneda_trn     = mo_descripcion,
   @w_secuencial     = tr_secuencial
   from ca_transaccion,ca_tipo_trn, cobis..cl_oficina,
   cobis..cl_ciudad, cobis..cl_moneda, cobis..cl_funcionario,
   cobis..cl_catalogo
   where tr_banco    = @i_banco
   and tt_codigo     = tr_tran
   and tr_ofi_usu    = of_oficina
   and of_ciudad     = ci_ciudad
   and fu_login      = tr_usuario
   and tr_moneda     = mo_moneda
   and tr_toperacion = codigo

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end 

   select 
   @w_cliente           = op_cliente, 
   @w_moneda            = op_moneda,
   @w_moneda_op         = mo_descripcion,
 --  @w_monto_op          = op_monto,
   @w_fecha_crea        = convert(varchar,op_fecha_ini,@i_formato_fecha),
   @w_ref_exterior      = op_ref_exterior,
   @w_fec_embarque      = substring(convert(varchar,op_fecha_embarque,@i_formato_fecha),1,15),
   @w_fec_dex           = substring(convert(varchar,op_fecha_dex,@i_formato_fecha),1,15),
   @w_num_deuda_ext     = op_num_deuda_ext,
   @w_num_comex         = op_num_comex,
   @w_operacionca       = op_operacion
   from ca_operacion,cobis..cl_moneda
   where op_banco    = @i_banco
   and op_moneda     = mo_moneda

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end  


   --** xma Valor desembolsado
/*
   select @w_monto_op = isnull(sum(am_liquida_mn),0) 
   from   ca_amortizacion
   where  am_operacion = @w_operacionca
*/

-- cambio de los campos am_correccion_xxx a la nueva tabla ca_correccion

   select @w_monto_op = isnull(sum(co_liquida_mn),0) 
   from   ca_correccion
   where  co_operacion = @w_operacionca
--fin 


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
   @w_usuario,    @w_terminal,        @w_num_liq,
   @w_fecha,      @w_oficina,         @w_ciudad_trn,
   @w_ttran_desc, @w_toperacion,      @w_moneda_trn,
   @w_secuencial, @w_cliente,         @w_nombre,
   @w_ced_ruc,    @w_moneda_op,       @w_monto_op,
   @w_fecha_crea, @w_ref_exterior,    @w_fec_embarque,
   @w_fec_dex,    @w_num_deuda_ext,   @w_num_comex
 
end

/* DETALLE DE LA TRANSACCION */

if @i_operacion = 'D' begin
   select
   'Forma de Pago'     = substring(isnull((select cp_descripcion from ca_producto where cp_producto = A.dtr_concepto),isnull((select co_descripcion from ca_concepto where co_concepto = A.dtr_concepto ),dtr_concepto)),1,60),
   'Monto'             = abs(dtr_monto),
   'Monto MN'          = abs(dtr_monto_mn),
   'Moneda'            = substring(mo_descripcion,1,6),
   'Cotizacion'        = dtr_cotizacion,
   'Cuenta '           = substring(dtr_cuenta,1,30),
   'Beneficiario'      = substring(dtr_beneficiario,1,50),
   'Estado'            = dtr_estado,
   'Periodo'           = dtr_periodo
   from  ca_det_trn A, cobis..cl_moneda
   where dtr_operacion  =  @i_secuencial   
   and dtr_moneda       =  mo_moneda   

end

return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go
