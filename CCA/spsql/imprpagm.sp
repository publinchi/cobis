/************************************************************************/
/*	Archivo: 		imprpagm.sp				*/
/*	Stored procedure: 	sp_imp_recibo_pago_masivo		*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Ricardo Reyes 				*/
/*	Fecha de escritura: 	03 19 2002				*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Consulta para imprimir el recibo pago masico moneda extranjera	*/
/*				MODIFICACIONES				*/
/*	Abr 29 2.002	Ricardo Reyes	Imprimir todas las formas pago 	*/
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/

use cob_cartera
go

set ansi_nulls off
go

/** TABLA CABECERA DEL RECIBO **/
if exists (select 1 from sysobjects where name = 'imp_recibo_pago_masivo_cab')
   drop table imp_recibo_pago_masivo_cab
go
create table imp_recibo_pago_masivo_cab(
re_opbanco  		cuenta 		null,
re_cliente		int 		null,
re_cliente_nomb		varchar(64) 	null,
re_ced_ruc		varchar(24) 	null,
re_toperacion		varchar(64) 	null,
re_moneda		varchar(24) 	null,
re_fechapag		datetime 	null,
re_num			int 		null,
re_estado		char(3)		null,
re_num_recibo		varchar(10)	null,
re_ref_exterior		varchar(20)	null,
re_fec_embarque		datetime	null,
re_fec_dex		datetime	null,
re_num_deuda_ext	varchar(15)	null,
re_num_comex		varchar(15)	null,
re_nominal_imo		float		null,
re_nominal_int		float		null,
re_saldo_capital	money		null,
re_referencia		varchar(64)	null,
re_signo		char(1)		null,
re_factor		float		null,
re_oficial		int		null,
re_gerente		varchar(64)	null
)
go

/** TABLA FORMAS DE PAGO **/
if exists (select 1 from sysobjects where name = 'imp_recibo_pago_masivo_pag')
   drop table imp_recibo_pago_masivo_pag
go
create table imp_recibo_pago_masivo_pag(
dr_opbanco		cuenta		null,
dr_tipo			catalogo	null,
dr_concepto		varchar(64)	null,
dr_cuenta		cuenta		null,
dr_moneda		varchar(24)	null,
dr_monto		money		null,
dr_cotizacion		money		null,
dr_monto_mop		money		null,
dr_descripcion		varchar(255)	null,
dr_num			int 		null
)
go

/** TABLA DETALLES DEL PAGO **/
if exists (select 1 from sysobjects where name = 'imp_recibo_pago_masivo_det')
   drop table imp_recibo_pago_masivo_det
go
create table imp_recibo_pago_masivo_det(
dr_opbanco		cuenta		null,
dr_tipo			varchar(3)	null,
dr_concepto		varchar(24)	null,
dr_cuenta		int		null,
dr_moneda		varchar(6)	null,
dr_monto		money		null,
dr_descripcion		varchar(6)	null,
dr_num			int 		null,
dr_fecha_ven		varchar(10)	null,
dr_fecha_ini		varchar(10)	null,
dr_dias			int		null,
dr_porcentaje		float		null,
dr_referencial		catalogo	null,
dr_monto_mn		money		null,
dr_dias_ult_pag		int		null,
dr_fecha_ult_pago	varchar(10)	null,
dr_cuota_pago		int		null,
)
go

if exists (select 1 from sysobjects where name = 'sp_imp_recibo_pago_masivo')
   drop proc sp_imp_recibo_pago_masivo
go


create proc sp_imp_recibo_pago_masivo (
   @i_fecha		datetime    = null,
   @i_banco		cuenta      = null
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
        @w_concepto_acc          	catalogo,
        @w_concepto_mfs          	catalogo,
        @w_concepto_fin          	catalogo,
        @w_fecha_pago                   varchar(10),
        @w_sec_recibo                   int, 
        @w_oficina                      smallint,
        @w_nro_recibo                   varchar(10),
	@w_ref_exterior 		cuenta,
	@w_fec_embarque			varchar(15),
	@w_fec_dex           		varchar(15),
	@w_num_deuda_ext    		cuenta,
	@w_num_comex    		cuenta,
        @w_tasa_nominal_int		float,
        @w_tasa_nominal_imo		float,
	@w_saldo_capital		money,
	@w_referencia			catalogo,
	@w_signo 			char(1),
        @w_factor 			float,
        @w_toperacion			catalogo,
	@w_oficial			int,
	@w_gerente			varchar(60),
        @w_porcentaje 			catalogo,
        @w_sec_pag_his			int,
        @w_fecha_pago_mora		datetime,
	@w_fecha_ultimo_pago_cap	datetime,
	@w_fecha_ultimo_pago_int	datetime,
	@w_fecha_ultimo_pago_imo	datetime,
	@w_secuencial_ing		int,
        @w_banco			cuenta,
   	@w_fp_tipo 			catalogo,
	@w_fp_descripcion 		varchar(64),
   	@w_fp_cuenta 			cuenta,
   	@w_fp_descripcion_mon 		varchar(24),
   	@w_fp_monto 			money,
   	@w_fp_cotizacion_mop 		money,
   	@w_fp_monto_mop 		money,
   	@w_fp_beneficiario 		varchar(64),
	@w_dr_opbanco			cuenta,
	@w_dr_tipo			varchar(3),
	@w_dr_concepto			varchar(24),
	@w_dr_cuenta			int,
	@w_dr_moneda			varchar(6), 
	@w_dr_monto			money,
	@w_dr_descripcion		varchar(6),
	@w_dr_fecha_ven			varchar(10),
	@w_dr_fecha_ini			varchar(10),
	@w_dr_dias			int,
	@w_dr_porcentaje		float,
	@w_dr_referencial		catalogo,
	@w_dr_monto_mn			money,
	@w_dr_dias_ult_pag		int,
	@w_dr_fecha_ult_pago		varchar(10),
	@w_dr_cuota_pago		money,
	@w_fecha_proceso		datetime,
	@w_anexo			varchar(255),
	@w_rowcount                     int

/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_imp_recibo_pago_masivo'

delete imp_recibo_pago_masivo_cab
where re_opbanco >= ''
delete imp_recibo_pago_masivo_det
where dr_opbanco >= ''
delete imp_recibo_pago_masivo_pag
where dr_opbanco >= ''

select  @w_fecha_proceso = fc_fecha_cierre
from    cobis..ba_fecha_cierre
where   fc_producto = 7

declare cur_abonos cursor for 
        select  op_banco,
		ab_secuencial_ing
        from    ca_operacion, ca_abono, ca_abono_det
        where   op_operacion = ab_operacion
	and 	abd_operacion = ab_operacion
	and     abd_secuencial_ing = ab_secuencial_ing
	and 	(op_banco = @i_banco or @i_banco is null)
	and	op_moneda <> 0
	and 	ab_estado = 'A'
	and 	ab_fecha_pag = @i_fecha
        for read only
--        and     abd_concepto in ('NDCC','NDAH') RRB: Se permiten todas las formas de pago

open cur_abonos 
fetch   cur_abonos
into	@w_banco,
        @w_secuencial_ing

while @@fetch_status = 0
begin  -- Del cursor

select @w_operacionca = op_operacion
from ca_operacion
where op_banco = @w_banco  

/* Cabecera del pago ***************************************************************************/

   select 
   @w_cliente           = op_cliente, 
   @w_toperacion_desc   = A.valor,
   @w_moneda            = op_moneda,
   @w_moneda_desc       = mo_descripcion,
   @w_ref_exterior      = op_ref_exterior,
   @w_fec_embarque      = substring(convert(varchar,op_fecha_embarque,102),1,15),
   @w_fec_dex           = substring(convert(varchar,op_fecha_dex,102),1,15),
   @w_num_deuda_ext     = op_num_deuda_ext,
   @w_num_comex         = op_num_comex,
   @w_toperacion	= op_toperacion,
   @w_oficial		= op_oficial
   from ca_operacion, cobis..cl_catalogo A, cobis..cl_moneda
   where op_banco    = @w_banco
   and op_toperacion = A.codigo
   and op_moneda     = mo_moneda

   if @@rowcount = 0
   begin
      select @w_anexo = 'Error en cargue de cabecera'
      select @w_error = 710026
      goto ERROR
   end  

   /*  Encuentra el Producto  */
       
   select @w_tipo = pd_tipo
   from cobis..cl_producto
   where pd_producto = 7
   set transaction isolation level read uncommitted

   print '@w_banco'+ @w_banco

   /*  Encuentra el Detalle de Producto  */
   select @w_det_producto = dp_det_producto
   from	cobis..cl_det_producto
   where dp_producto = 7
   and	dp_tipo   = @w_tipo
   and	dp_moneda = @w_moneda
   and	dp_cuenta = @w_banco
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
 
   if @w_rowcount = 0 
   begin
      select @w_anexo = 'Error al buscar detalle del producto cl_det_producto'
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

  /* Nobre del gerente asignado */
   select   
   @w_gerente  = fu_nombre + ' - ' + convert(varchar(4),@w_oficial)
   from cobis..cc_oficial, cobis..cl_funcionario, ca_operacion
   where op_oficial = oc_oficial
   and op_banco = @w_banco
   and oc_funcionario = fu_funcionario

  /* SECUENCIALES A LA OPERACION */
   select 
   @w_sec_ing    = ab_secuencial_ing,
   @w_sec_pag    = ab_secuencial_pag,
   @w_estado     = ab_estado,
   @w_fecha_pago = convert(varchar(10),ab_fecha_pag,102),
   @w_sec_recibo = ab_nro_recibo,
   @w_oficina    = ab_oficina
   from ca_abono
   where ab_operacion    = @w_operacionca
   and ab_secuencial_ing = @w_secuencial_ing  

   /** GENERACION DEL NUMERO DE RECIBO **/
   exec @w_return = sp_numero_recibo
   @i_tipo       = 'G',
   @i_oficina    = @w_oficina,
   @i_secuencial = @w_sec_recibo,
   @o_recibo     = @w_nro_recibo out
   if @w_return <> 0
   begin
       select @w_error = @w_return
       goto ERROR
   end

   /** Tasas **/
   select @w_tasa_nominal_imo = ts_porcentaje
   from ca_tasas, ca_rubro_op
   where ts_operacion = @w_operacionca
   and ts_operacion = ro_operacion
   and ts_concepto = ro_concepto
   and ts_referencial = ro_referencial
   and ts_concepto = 'IMO'

   select @w_tasa_nominal_int = ro_porcentaje,
	  @w_signo = ro_signo,
          @w_factor = ro_factor
   from ca_rubro_op
   where ro_operacion = @w_operacionca
   and ro_concepto = 'INT'

   /** Saldo de Capital **/

   select @w_sec_pag_his = ab_secuencial_pag
   from ca_abono
   where ab_operacion = @w_operacionca
   and ab_secuencial_ing = @w_secuencial_ing
   
   select @w_saldo_capital = sum(amh_acumulado - amh_pagado)
   from ca_amortizacion_his
   where amh_operacion = @w_operacionca
   and amh_concepto = 'CAP'
   and amh_secuencial = @w_sec_pag_his

   /** Tasa **/
   select @w_referencia = vd_referencia
   from ca_tasas, ca_valor_det, ca_operacion, ca_rubro_op
   where ts_operacion = @w_operacionca
   and op_operacion = @w_operacionca
   and ts_concepto = 'INT'
   and vd_tipo = ts_referencial
   and vd_sector = op_sector
   and ts_operacion = ro_operacion
   and ts_concepto = ro_concepto
   and ts_referencial = ro_referencial

   if @w_referencia is null
	select @w_referencia = ts_referencial + ' .'
	from ca_tasas, ca_operacion, ca_rubro_op
	where ts_operacion = @w_operacionca
   	and op_operacion = @w_operacionca
   	and ts_concepto = 'INT'
   	and ts_operacion = ro_operacion
   	and ts_concepto = ro_concepto
   	and ts_referencial = ro_referencial

   select @w_toperacion_desc = @w_toperacion_desc + ' - ' + @w_toperacion

   insert into imp_recibo_pago_masivo_cab values
   (
	@w_banco,
   	@w_cliente,         		@w_nombre,      	@w_ced_ruc,
   	@w_toperacion_desc, 		@w_moneda_desc, 	@w_fecha_pago,
   	@w_sec_pag,         		@w_estado,      	@w_nro_recibo,
   	@w_ref_exterior,    		@w_fec_embarque,	@w_fec_dex,
   	@w_num_deuda_ext,   		@w_num_comex,   	isnull(@w_tasa_nominal_imo,0),
   	isnull(@w_tasa_nominal_int,0),	isnull(@w_saldo_capital,0),	@w_referencia,
   	isnull(@w_signo,'+'), 		isnull(@w_factor,0),	@w_oficial,
   	@w_gerente
   )
   
   /* FORMA DE PAGO */

   select 
   @w_fp_tipo            = abd_tipo,
   @w_fp_descripcion     = substring(isnull((select co_descripcion from ca_concepto where co_concepto = A.abd_concepto),(select cp_descripcion from ca_producto where cp_producto = A.abd_concepto )),1,60),
   @w_fp_cuenta          = substring(isnull(abd_cuenta,' '),1,30), 
   @w_fp_descripcion_mon = mo_descripcion,
   @w_fp_monto           = abd_monto_mpg,
   @w_fp_cotizacion_mop  = abd_cotizacion_mop,
   @w_fp_monto_mop       = abd_monto_mop,
   @w_fp_beneficiario    = substring(isnull(abd_beneficiario,' '),1,25)
   from ca_abono_det A,        
        cobis..cl_moneda
   where abd_secuencial_ing = @w_sec_ing
   and   abd_operacion      = @w_operacionca    
   and abd_moneda           = mo_moneda
   order by abd_tipo

   insert into imp_recibo_pago_masivo_pag values 
   (
	@w_banco,
   	@w_fp_tipo,		@w_fp_descripcion,	@w_fp_cuenta,
   	@w_fp_descripcion_mon,	@w_fp_monto,		@w_fp_cotizacion_mop,
   	@w_fp_monto_mop,	@w_fp_beneficiario,	@w_sec_pag
   )

/* Detalle del pago ****************************************************************************/

/* SECUENCIALES A LA OPERACION */

   select @w_sec_pag_his = ab_secuencial_ing
   from ca_abono
   where ab_operacion = @w_operacionca
   and ab_secuencial_pag = @w_sec_pag

   select @w_fecha_pago_mora = ab_fecha_pag
   from ca_abono
   where ab_operacion    = @w_operacionca
   and ab_secuencial_ing = @w_sec_pag_his

   select @w_fecha_ultimo_pago_cap = max(ab_fecha_pag)
   from ca_abono, ca_det_trn
   where ab_operacion    = @w_operacionca
   and ab_operacion = dtr_operacion
   and dtr_secuencial = ab_secuencial_pag
   and ab_secuencial_ing < @w_sec_pag_his
   and ab_estado = 'A'
   --and ab_fecha_pag < @w_fecha_pago
   and dtr_concepto = 'CAP'

   select @w_fecha_ultimo_pago_int = max(ab_fecha_pag)
   from ca_abono, ca_det_trn, ca_dividendo
   where ab_operacion    = @w_operacionca
   and ab_operacion = dtr_operacion
   and dtr_secuencial = ab_secuencial_pag
   and dtr_dividendo = di_dividendo
   and dtr_operacion = di_operacion
   and ab_fecha_pag <= di_fecha_ven
   and ab_secuencial_ing < @w_sec_pag_his
   and ab_estado = 'A'
   --and ab_fecha_pag < @w_fecha_pago
   and dtr_concepto = 'INT'

   select @w_fecha_ultimo_pago_imo = max(ab_fecha_pag)
   from ca_abono, ca_det_trn, ca_dividendo
   where ab_operacion    = @w_operacionca
   and ab_operacion = dtr_operacion
   and dtr_secuencial = ab_secuencial_pag
   and dtr_dividendo = di_dividendo
   and dtr_operacion = di_operacion
   and ab_fecha_pag > di_fecha_ven
   and ab_secuencial_ing < @w_sec_pag_his
   and ab_estado = 'A'
   --and ab_fecha_pag < @w_fecha_pago
   and dtr_concepto = 'IMO'

   declare cursor_concepto cursor for 
	select 
	isnull(dtr_concepto,''),	
	isnull(dtr_dividendo,0),
	isnull(convert(varchar(6),datediff(dd,di_fecha_ven,@w_fecha_pago_mora)),'0'),
	isnull(dtr_monto,0),
	isnull(convert(varchar(6),datediff(dd,di_fecha_ini,@w_fecha_pago_mora)),'0'),
	convert(varchar(10),di_fecha_ven,102),
	convert(varchar(10),di_fecha_ini,102),
	isnull(datediff(dd,di_fecha_ini,di_fecha_ven),0),
	isnull((select ts_porcentaje from ca_tasas where ts_operacion = TR.dtr_operacion and ts_dividendo = TR.dtr_dividendo and ts_concepto = TR.dtr_concepto ),0),
    isnull((select ts_referencial from ca_tasas where ts_operacion = TR.dtr_operacion and ts_dividendo = TR.dtr_dividendo and ts_concepto = TR.dtr_concepto),''),
	isnull(dtr_monto_mn,0),
	am_cuota
   from ca_det_trn TR, ca_estado, ca_dividendo, ca_rubro_op, ca_amortizacion
   where dtr_secuencial = @w_sec_pag
   and  dtr_operacion   = di_operacion
   and  dtr_dividendo   = di_dividendo   
   and  dtr_operacion   = ro_operacion
   and  dtr_concepto    = ro_concepto   
   and  dtr_operacion   = @w_operacionca
   and  am_operacion    = @w_operacionca
   and  am_dividendo    = di_dividendo
   and  am_concepto     = dtr_concepto
   and  dtr_estado      = es_codigo
   and  dtr_concepto not like 'VAC%'
   order by di_dividendo
   for read only

   open cursor_concepto
   fetch cursor_concepto into 
   	@w_dr_concepto 		 ,
   	@w_dr_cuenta 		 ,
   	@w_dr_moneda 		 ,
   	@w_dr_monto 			 ,
   	@w_dr_descripcion		 ,
   	@w_dr_fecha_ven 		 ,
   	@w_dr_fecha_ini 		 ,
   	@w_dr_dias 			 ,
   	@w_dr_porcentaje 		 ,  
   	@w_dr_referencial 		 ,
   	@w_dr_monto_mn 		 ,
   	@w_dr_cuota_pago 		 

   while @@fetch_status = 0
   begin  -- Del cursor

	if @w_dr_concepto = 'CAP' begin
	select @w_dr_dias_ult_pag = isnull(datediff(dd,@w_dr_fecha_ven,@w_fecha_ultimo_pago_cap),0)
	select @w_dr_fecha_ult_pago = convert(varchar(10),@w_fecha_ultimo_pago_cap,102)
	select @w_dr_tipo = isnull(convert(varchar(6),datediff(dd,@w_fecha_ultimo_pago_cap,@w_fecha_pago)),'0')
	end
	if @w_dr_concepto = 'INT' begin
	select @w_dr_dias_ult_pag = isnull(datediff(dd,@w_dr_fecha_ven,@w_fecha_ultimo_pago_int),0)
	select @w_dr_fecha_ult_pago = convert(varchar(10),@w_fecha_ultimo_pago_int,102)
	select @w_dr_tipo = isnull(convert(varchar(6),datediff(dd,@w_fecha_ultimo_pago_int,@w_fecha_pago)),'0')
	end
	if @w_dr_concepto = 'IMO' begin
	select @w_dr_dias_ult_pag = isnull(datediff(dd,@w_dr_fecha_ven,@w_fecha_ultimo_pago_imo),0)
	select @w_dr_fecha_ult_pago = convert(varchar(10),@w_fecha_ultimo_pago_imo,102)
	select @w_dr_tipo = isnull(convert(varchar(6),datediff(dd,@w_fecha_ultimo_pago_imo,@w_fecha_pago)),'0')
	end

   	insert into imp_recibo_pago_masivo_det values
   	(
	@w_banco,		@w_dr_tipo,		@w_dr_concepto,
	@w_dr_cuenta,		@w_dr_moneda,		@w_dr_monto,
	@w_dr_descripcion,	@w_sec_pag,		@w_dr_fecha_ven,	
	@w_dr_fecha_ini,	@w_dr_dias,		@w_dr_porcentaje,	
	@w_dr_referencial,	@w_dr_monto_mn,		@w_dr_dias_ult_pag,	
	@w_dr_fecha_ult_pago,	@w_dr_cuota_pago
   	)
    
   fetch cursor_concepto into 
   	@w_dr_concepto 		 ,
   	@w_dr_cuenta 		 ,
   	@w_dr_moneda 		 ,
   	@w_dr_monto 			 ,
   	@w_dr_descripcion		 ,
   	@w_dr_fecha_ven 		 ,
   	@w_dr_fecha_ini 		 ,
   	@w_dr_dias 			 ,
   	@w_dr_porcentaje 		 ,  
   	@w_dr_referencial 		 ,
   	@w_dr_monto_mn 		 ,
   	@w_dr_cuota_pago 		 

   end   -- Del cursor
   close   cursor_concepto 
   deallocate cursor_concepto 

   goto SIGUIENTE

   ERROR:

	exec sp_errorlog 
        @i_fecha     = @w_fecha_proceso, 
        @i_error     = @w_error, 
        @i_usuario   = 'Consola',
        @i_tran      = 7000, 
        @i_tran_name = @w_sp_name, 
        @i_rollback  = 'N',
        @i_cuenta    = @w_banco, 
        @i_anexo     = @w_anexo

   SIGUIENTE:

fetch   cur_abonos
into	@w_banco,
        @w_secuencial_ing

end   -- Del cursor
close   cur_abonos
deallocate cur_abonos

return 0

go
