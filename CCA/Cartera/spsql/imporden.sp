/************************************************************************/
/*	Archivo: 		imporden.sp				*/
/*	Stored procedure: 	sp_imprimir_orden    	        	*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Francisco Yacelga 			*/
/*	Fecha de escritura: 	03/Dic./1997				*/
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
/*	Imprimir la orden de desembolso                      	        */
/************************************************************************/

use cob_cartera
go

set ansi_nulls off
go
 
if exists (select 1 from sysobjects where name = 'sp_imprimir_orden')
   drop proc sp_imprimir_orden
go

create proc sp_imprimir_orden(
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
   @i_formato_fecha     int         = null,
   @i_banco             cuenta      = null,
   @i_secuencial        int         = null
)

as
declare	
@w_sp_name	    varchar(32),
@w_return	    int,
@w_error            int,
@w_tipo             char(1),
@w_det_producto	    int,
@w_operacionca      int,
@w_moneda           tinyint,
@w_fecha_liq        varchar(15),
@w_cliente          int,
@w_nombre           varchar(60), 
@w_ced_ruc          varchar(15),
@w_telefono         varchar(15),
@w_num_liq          int,
@w_oficina          smallint,
@w_nro_recibo       varchar(10),
@w_secuencial       int,
@w_ref_exterior     cuenta,
@w_fec_embarque     varchar(15),
@w_fec_dex          varchar(15),
@w_num_deuda_ext    cuenta,
@w_num_comex        cuenta,
@w_rowcount         int

  
/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_imprimir_orden'

/* CABECERA DE LA ORDEN DE PAGO */
select 
@w_operacionca     = op_operacion,
@w_moneda          = op_moneda,
@w_fecha_liq       = substring(convert(varchar,op_fecha_liq,@i_formato_fecha),1,15),
@w_cliente         = op_cliente,
@w_ref_exterior    = op_ref_exterior,
@w_fec_embarque    = substring(convert(varchar,op_fecha_embarque,@i_formato_fecha),1,15),
@w_fec_dex         = substring(convert(varchar,op_fecha_dex,@i_formato_fecha),1,15),
@w_num_deuda_ext   = op_num_deuda_ext,
@w_num_comex       = op_num_comex
from ca_operacion 
where op_banco    = @i_banco

if @@rowcount = 0 begin
      select @w_error = 710026
      goto ERROR
end  

/*  Encuentra el Producto  */
select @w_tipo = pd_tipo
from cobis..cl_producto
where pd_producto = 7
set transaction isolation level read uncommitted

/*  Encuentra el Detalle de Producto  */
select 
@w_det_producto = dp_det_producto
from cobis..cl_det_producto
where dp_producto = 7
and dp_tipo   = @w_tipo
and dp_moneda = @w_moneda
and dp_cuenta = @i_banco
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 710026
   goto ERROR
end

/*Realizar la consulta de Informacion General de Cliente*/
select 
@w_ced_ruc   = isnull(cl_ced_ruc,p_pasaporte), 
@w_nombre    = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' 
               + rtrim(en_nombre),1,60)),
@w_telefono  = (select te_valor from cobis..cl_telefono where te_ente = CL.en_ente and te_tipo_telefono in ('T','C') and te_direccion = 1 and te_secuencial = 1 )
from cobis..cl_cliente,
cobis..cl_ente CL
where 
cl_det_producto   = @w_det_producto
and cl_rol        = 'D'
and cl_cliente    = @w_cliente
and en_ente       = cl_cliente                                         
set transaction isolation level read uncommitted

---PRINT 'imporden.sp i_secuencial %1!',@i_secuencial

if @i_secuencial is null begin
   select @w_secuencial = max(tr_secuencial)
   from ca_transaccion
   where tr_operacion = @w_operacionca
   and   tr_tran = 'DES'
end
else
   select @w_secuencial = @i_secuencial



select 
@w_num_liq = isnull(tr_dias_calc,-1),
@w_oficina = tr_ofi_usu
from ca_transaccion
where tr_secuencial = @w_secuencial
and tr_operacion = @w_operacionca
and tr_tran      = 'DES'

/** GENERACION DEL NUMERO DE RECIBO **/
exec @w_return = sp_numero_recibo
@i_tipo       = 'G',
@i_oficina    = @w_oficina,
@i_secuencial = @w_num_liq,
@o_recibo     = @w_nro_recibo out

if @w_return <> 0 begin
   select @w_error = @w_return
   goto ERROR
end

select @w_fecha_liq,
@w_cliente,
@w_nombre,
@w_ced_ruc,
@w_telefono,
@w_nro_recibo,
@w_ref_exterior,
@w_fec_embarque,
@w_fec_dex,
@w_num_deuda_ext,
@w_num_comex

/* DETALLE DEL DESEMBOLSO */

select
'No.'          = dm_desembolso,
'Oficina'      = SUBSTRING(of_nombre,1,40),
'Forma'        = substring(cp_descripcion,1,40),
'Referencia'   = substring(dm_cuenta,1,30),
'Moneda'       =  substring(mo_descripcion,1,30),
'Cotizacion'   = dm_cotizacion_mds,
'Monto'        = dm_monto_mds,
'Beneficiario' = dm_beneficiario
from ca_desembolso, cobis..cl_moneda, ca_producto,
cobis..cl_oficina
where dm_secuencial = @w_secuencial
and dm_operacion    = @w_operacionca
and dm_moneda       = mo_moneda
and dm_producto     = cp_producto 
and dm_oficina      = of_oficina
order by dm_desembolso

return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go