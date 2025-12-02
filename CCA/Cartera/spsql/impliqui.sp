/************************************************************************/
/*	Archivo: 		      impliqui.sp				*/
/*	Stored procedure: 	sp_imprimir_liquidacion    		*/
/*	Base de datos:  	   cob_cartera				*/
/*	Producto: 		      Cartera				        */
/*	Disenado por:  		Francisco Yacelga 		        */
/*	Fecha de escritura: 	03/Dic./1997				*/
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
/*	Imprimir la liquidacion del prestamo                     	*/
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_imprimir_liquidacion')
   drop proc sp_imprimir_liquidacion
go

create proc sp_imprimir_liquidacion(
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
   @i_operacion	        char(1)     = null,
   @i_formato_fecha     int         = null,
   @i_banco             cuenta      = null,
   @i_moneda            tinyint     = null,
   @i_rol               char(1)     = null,
   @i_secuencial        int         = null
)

as
declare	
@w_sp_name	    varchar(32),
@w_return	    int,
@w_error            int,
@w_tipo             char(1),
@w_det_producto	    int,
@w_op_anterior      cuenta,         
@w_operacionca      int,
@w_tramite          int,
@w_fecha_crea       VARCHAR(15),
@w_toperacion       catalogo,
@w_toperacion_desc  varchar(60),
@w_moneda           tinyint,
@w_moneda_desc      varchar(60),
@w_monto            money,
@w_monto_aprob      money,
@w_monto_desem      money,
@w_monto_retenido   money,
@w_tasa             float,
@w_recibo           int,
@w_oficina          smallint,
@w_nro_recibo       varchar(10),
@w_fecha_mov        varchar(15),
@w_secuencial       int,
@w_tasa_ef_anual    float,
@w_periodicidad_o   char(1),
@w_modalidad_o      char(1),
@w_int_ant          money,
@w_liquidacion      int,
@w_tasa_referencial             varchar(12), 
@w_signo_spread                 char(1),
@w_valor_spread                 float,
@w_modalidad                    char(1),
@w_valor_referencial            float,
@w_sector                       char(1),
@w_ref_exterior 		   cuenta,
@w_fec_embarque			varchar(15),
@w_fec_dex           	varchar(15),
@w_num_deuda_ext    		cuenta,
@w_num_comex    		   cuenta,
@w_op_direccion         tinyint,
@w_rowcount                     int

/* Captura nombre de Stored Procedure  */
select	@w_sp_name       = 'sp_imprimir_liquidacion',
        @i_formato_fecha = 103

/* CABECERA DE LA LIQUIDACION */
if @i_operacion = 'C'
begin
   select 
   @w_op_anterior      = op_anterior,
   @w_operacionca      = op_operacion,
   @w_tramite          = op_tramite,
   @w_fecha_crea       = substring(convert(varchar,op_fecha_ini,@i_formato_fecha),1,15),
   @w_toperacion       = op_toperacion,
   @w_toperacion_desc  = A.valor,
   @w_moneda           = op_moneda,
   @w_moneda_desc      = mo_descripcion,
   @w_monto            = op_monto,
   @w_monto_aprob      = op_monto_aprobado,
   @w_sector           = op_sector,
   @w_ref_exterior     = op_ref_exterior,
   @w_fec_embarque     = substring(convert(varchar,op_fecha_embarque,@i_formato_fecha),1,15),
   @w_fec_dex          = substring(convert(varchar,op_fecha_dex,@i_formato_fecha),1,15),
   @w_num_deuda_ext    = op_num_deuda_ext,
   @w_num_comex        = op_num_comex,
   @w_op_direccion     = op_direccion
   from ca_operacion, cobis..cl_catalogo A, cobis..cl_moneda
   where op_banco    = @i_banco
   and op_toperacion = A.codigo
   and op_moneda     = mo_moneda

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end  

   if @i_secuencial is null
   begin
      select @w_secuencial = max(dm_secuencial)
      from  ca_desembolso
      where dm_operacion = @w_operacionca
   end
   else
      select @w_secuencial = @i_secuencial
 
   select @w_liquidacion = min(dm_secuencial)
   from  ca_desembolso
   where dm_operacion = @w_operacionca

   select @w_monto_retenido = isnull(sum(ro_valor),0)
   from ca_rubro_op
   where ro_operacion = @w_operacionca 
   and   ro_fpago     = 'L'

   if @w_secuencial = @w_liquidacion
   begin
      /*SE COBRAN INTERESES ANTICIPADOS SOLO EN LA LIQUIDACION*/
      select @w_int_ant = sum(am_cuota)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion  = @w_operacionca
      and    am_dividendo  = 1
      and    ro_operacion  = @w_operacionca
      and    ro_concepto   = am_concepto
      and    ro_tipo_rubro = 'I'
      and    ro_fpago      = 'A'

      select @w_monto_retenido = @w_monto_retenido + isnull(@w_int_ant,0)
   end

   select @w_monto_desem = isnull(sum(dm_monto_mop),0)
   from ca_desembolso
   where dm_operacion = @w_operacionca
   and  dm_secuencial = @w_secuencial

   select @w_tasa = isnull(sum(ro_porcentaje) ,0)
   from ca_rubro_op
   where ro_operacion  =  @w_operacionca
   and   ro_tipo_rubro =  'I'
   and   ro_fpago      in ('P','A')

   select @w_tasa_referencial = ro_referencial,
          @w_signo_spread = ro_signo,
          @w_valor_spread = ro_factor,
          @w_modalidad    = ro_fpago,
          @w_valor_referencial = ro_porcentaje_aux
   from ca_rubro_op
   where ro_operacion  =  @w_operacionca
   and   ro_tipo_rubro =  'I'
   and   ro_fpago      in ('P','A')

   select @w_tasa_referencial = vd_referencia from ca_valor_det
   where vd_tipo = @w_tasa_referencial
   and vd_sector = @w_sector
   
   select @w_recibo=-1

   select 
   @w_recibo  = isnull(tr_dias_calc,-1),
   @w_oficina = tr_ofi_usu
   from ca_transaccion
   where tr_operacion = @w_operacionca
   and tr_tran        = 'DES'
   and tr_secuencial  = @w_secuencial

   /** GENERACION DEL NUMERO DE RECIBO **/
   exec @w_return = sp_numero_recibo
   @i_tipo       = 'G',
   @i_oficina    = @w_oficina,
   @i_secuencial = @w_recibo,
   @o_recibo     = @w_nro_recibo out

   if @w_return != 0
   begin
       select @w_error = @w_return
       goto ERROR
   end

   /*TASA EN EFECTIVO ANUAL*/
   exec @w_return = sp_control_tasa
   @i_operacionca = @w_operacionca,
   @i_temporales  = 'N',
   @i_ibc         = 'N',
   @o_tasa_total_efe = @w_tasa_ef_anual  output

   if @w_return != 0 return @w_return
 
   select
   @w_op_anterior,
   @w_operacionca,
   @w_tramite,
   @w_fecha_crea,
   @w_toperacion,
   @w_toperacion_desc,
   @w_moneda,
   @w_moneda_desc,
   @w_monto,
   @w_monto_aprob,
   @w_monto_desem,
   @w_monto_retenido,
   @w_tasa,
   @w_nro_recibo,
   @w_tasa_ef_anual,
   @w_tasa_referencial,
   @w_valor_referencial,
   @w_valor_spread,
   @w_signo_spread,
   @w_modalidad, 
   @w_ref_exterior, 
   @w_fec_embarque,
   @w_fec_dex,
   @w_num_deuda_ext,
   @w_num_comex

   /* RUBROS */
   select 
   'Rubro'    = co_descripcion, 
   'Monto'    = ro_valor
   from ca_rubro_op, ca_concepto
   where
   ro_operacion    = @w_operacionca 
   and ro_concepto = co_concepto
   and (ro_fpago ='L' or ro_tipo_rubro ='C')
   order by ro_tipo_rubro, ro_concepto

   /* DETALLE DEL DESEMBOLSO */

   select
   'No.'          = dm_desembolso,
   'Forma'        = substring(cp_descripcion,1,40),
   'Moneda'       = substring(mo_descripcion,1,3),
   'Monto'        = dm_monto_mds,
   'Cotizacion'   = dm_cotizacion_mds,
   'Referencia'   = dm_cuenta,
   'Beneficiario' = substring(dm_beneficiario,1,50)
   from ca_desembolso, cobis..cl_moneda, ca_producto
   where dm_secuencial = @w_secuencial
   and dm_operacion    = @w_operacionca
   and dm_moneda       = mo_moneda
   and dm_producto     = cp_producto 
   order by dm_desembolso
end

/* DEUDORES DE LA OPERACION */
if @i_operacion = 'D'
begin
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
   and	dp_moneda = @i_moneda
   and	dp_cuenta = @i_banco
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 
   begin
       select @w_error = 710023
       goto ERROR
   end

   select @w_op_direccion = op_direccion
   from ca_operacion
   where op_banco = @i_banco
   
   /*Realizar la consulta de Informacion General de Cliente*/
   select 
   'Rol'       = cl_rol,
   'Codigo'    = cl_cliente,
   'DDI/NIT'   = cl_ced_ruc,
   'Pasaporte' = p_pasaporte, 
   'Nombre'    = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' 
                 + rtrim(en_nombre),1,60)),
   'Telefono'  = (select te_valor from cobis..cl_telefono where te_ente = CL.en_ente and te_direccion = @w_op_direccion), 
   'Direccion' = (select di_descripcion from cobis..cl_direccion where di_ente = CL.en_ente and di_direccion = @w_op_direccion) 
   from cobis..cl_cliente,
   cobis..cl_ente CL   
   where 
   cl_det_producto   = @w_det_producto
   and cl_rol        = @i_rol
   and en_ente       = cl_cliente                                                                        
   order by cl_rol desc
   set transaction isolation level read uncommitted
end

/* CONSULTA DE LA LIQUIDACION O DESEMBOLSOS PARCIALES */
if @i_operacion = 'Q'
begin
   select 
   'SECUENCIAL'  = tr_secuencial,
   'FECHA'       = substring(convert(varchar,tr_fecha_mov,@i_formato_fecha),1,15),
   'Nro. RECIBO' = isnull(tr_dias_calc,-1),
   'OFICINA '    = tr_ofi_usu
   from ca_transaccion
   where tr_secuencial > @i_secuencial
   and tr_banco = @i_banco
   and tr_tran        = 'DES'
   and tr_estado != 'RV'
end

return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go

