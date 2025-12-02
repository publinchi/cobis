/************************************************************************/
/*	Archivo: 		desdirec.sp				*/
/*	Stored procedure: 	sp_descuento_directo			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Francisco Yacelga 			*/
/*	Fecha de escritura: 	19/Nov/97				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA"							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Verificacion de la operacion del pago y la realizacion del pago */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR              RAZON                        */
/*      20/10/2021      G. Fernandez     Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_descuento_directo')
   drop proc sp_descuento_directo
go

create proc sp_descuento_directo (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint     = null,
   @t_rty               char(1)     = null,
   @t_debug          	char(1)     = 'N',
   @t_file         	varchar(14) = null,
   @t_trn		smallint    = null,     
   @i_banco		cuenta      = null,
   @i_operacion		char(1)     = null,
   @i_cliente      	int         = null,
   @i_compania          int         = null,
   @i_forma_pago        varchar(10) = null,
   @i_referencia        cuenta      = null,
   @i_valor             money       = null,
 @i_cheque              int         = null,/* ELA ENERO/2002 */
 @i_cod_banco           catalogo    = null /* ELA ENERO/2002 */


)
as
declare	@w_sp_name			varchar(32),
       	@w_return			int,
	@w_error        		int,
	@w_operacionca                  int,
        @w_secuencial                   int,
        @w_cuota_completa               char(1),
        @w_aceptar_anticipos            char(1),
        @w_tipo_reduccion               char(1),
        @w_tipo_cobro                   char(1),          
        @w_tipo_aplicacion              char(1),
        @w_moneda                       int,
        @w_moneda_nacional              tinyint,
        @w_moneda_op                    tinyint,
        @w_pcobis                       tinyint,
        @w_numero_recibo                int,
        /*  AUMENTO POR LA COTIZACION  */
        @w_monto_mpg                    money,
        @w_monto_mop                    money,
        @w_monto_mn                     money,
        @w_cot_moneda                   float,
        @w_cotizacion_mpg               float,
        @w_cotizacion_mop               float,
        @w_tcot_moneda                  char(1),
        @w_tcotizacion_mpg              char(1),
        @w_concepto                     varchar(30),
        @w_prioridad                    int,
        @w_existe                       int 

/*  Captura nombre de Stored Procedure  */

select	@w_sp_name = 'sp_descuento_directo'

select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

/* VERIFICACION DE LA OPERACION CON EL CLIENTE */

if @i_operacion = 'V' begin   
   select
   @w_operacionca = op_operacion
   from ca_operacion
   where  op_banco   = @i_banco
   and    op_cliente = @i_cliente
   and    op_estado <> 0

   if @@rowcount = 0 begin
       select @w_error = 710025
       goto ERROR
   end  

end


/* CONSULTA DEL DETALLE DEL PAGO */

if @i_operacion = 'T' begin
   begin tran
   
   /* VERIFICACION DE DATOS TRANSMITIDOS */
      
   if not exists (select 1 from cobis..cl_ente where en_ente = @i_cliente) begin
      select @w_error = 101042
      goto ERROR
   end

      /* PRODUCTO */
   select 
   @w_pcobis = cp_pcobis,
   @w_moneda = cp_moneda   
   from ca_producto 
   where cp_producto = @i_forma_pago
   
   if @@rowcount = 0 begin
      select @w_error = 708135
      goto ERROR
   end

      /* CUENTA */
if @w_pcobis = 3   begin 
  /* CUENTAS CORRIENTES  */
    exec @w_error = cob_interface..sp_verifica_cuenta_cte
                @i_operacion =  'VCTE3',
                @i_cuenta    =  @i_referencia,
                @i_cliente   =  @i_cliente,
                @i_moneda    =  @w_moneda,
                @o_existe    =  @w_existe out 
          if not exists(select @w_existe)begin
            select @w_error = 710020
            goto ERROR
          end
   /*if not exists 
    (select * 
     from   cob_cuentas..cc_ctacte
     where cc_cta_banco = @i_referencia 
     and   cc_cliente   = @i_cliente
     and   cc_moneda    = @w_moneda
     and   cc_estado    = 'A')  begin
         select @w_error = 710020
         goto ERROR
   end*/
   end 
   else begin
     if @w_pcobis = 4  begin 
         /*  CUENTAS DE AHORROS */
          exec @w_error = cob_interface..sp_verifica_cuenta_aho
                @i_operacion =  'VAHO3',
                @i_cuenta    =  @i_referencia,
                @i_cliente   =  @i_cliente,
                @i_moneda    =  @w_moneda,
                @o_existe    =  @w_existe out 
          if not exists(select @w_existe)begin
            select @w_error = 710020
            goto ERROR
          end
         /*if not exists     
            (select * 
             from   cob_ahorros..ah_cuenta
             where ah_cta_banco = @i_referencia
             and   ah_cliente   = @i_cliente
             and   ah_moneda    = @w_moneda
             and   ah_estado    = 'A')    begin
            select @w_error = 710020
            goto ERROR
         end*/
      end 
end

exec @w_secuencial = sp_gen_sec 
@i_operacion  = @w_operacionca
  

   select
   @w_operacionca        = op_operacion,
   @w_cuota_completa     = op_cuota_completa,
   @w_aceptar_anticipos  = op_aceptar_anticipos,
   @w_tipo_reduccion     = op_tipo_reduccion,
   @w_tipo_cobro         = op_tipo_cobro,
   @w_tipo_aplicacion    = op_tipo_aplicacion ,
   @w_moneda_op          = op_moneda 
   from ca_operacion
   where  op_banco   = @i_banco
   and    op_cliente = @i_cliente
   and    op_estado <> 0

   if @@rowcount = 0 begin
       select @w_error = 710025
       goto ERROR
   end  

   /** GENERACION DEL NUMERO DE RECIBO **/
   exec @w_return = sp_numero_recibo
   @i_tipo    = 'P',
   @i_oficina = @s_ofi,
   @o_numero  = @w_numero_recibo out

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

   /* INSERCION EN CA_ABONO */

   insert into ca_abono (
   ab_operacion,      ab_fecha_ing,          ab_fecha_pag,
   ab_cuota_completa, ab_aceptar_anticipos,  ab_tipo_reduccion,
   ab_tipo_cobro,     ab_dias_retencion_ini, ab_dias_retencion,
   ab_estado,         ab_secuencial_ing,     ab_secuencial_rpa,
   ab_secuencial_pag, ab_usuario,            ab_terminal,
   ab_tipo,           ab_oficina,            ab_tipo_aplicacion,
   ab_nro_recibo)

   values (
   @w_operacionca,    @s_date,              @s_date,
   @w_cuota_completa, @w_aceptar_anticipos, @w_tipo_reduccion,
   @w_tipo_cobro,     0,                    0,
   'ING',             @w_secuencial,        0,
   0,                 @s_user,              @s_term,
   'PAG',             @s_ofi,               @w_tipo_aplicacion,
   @w_numero_recibo)

   if @@rowcount = 0 begin
       select @w_error = 710001
       goto ERROR
   end  

   select @w_concepto = ' '
   while 1=1 begin
      set rowcount 1
      select
      @w_concepto  = ro_concepto,
      @w_prioridad = ro_prioridad
      from ca_rubro_op
      where ro_operacion = @w_operacionca
      and   ro_fpago    not in ('L','B')
      and   ro_concepto > @w_concepto

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end
     
      set rowcount 0
      insert into ca_abono_prioridad (
      ap_secuencial_ing, ap_operacion,ap_concepto, ap_prioridad) 
      values (
      @w_secuencial,@w_operacionca,@w_concepto,@w_prioridad)
   end

   exec @w_return = sp_conversion_moneda
   @s_date             = @s_date,
   @i_opcion           = 'L',
   @i_moneda_monto     = @w_moneda, 
   @i_moneda_resultado = @w_moneda_nacional, 
   @i_monto            = @i_valor,
   @o_monto_pesos      = @w_monto_mn out,  
   @o_tipo_cambio      = @w_cot_moneda out 

   if @w_return <> 0 begin
       select @w_error = 710001
       goto ERROR
   end

   exec @w_return = sp_conversion_moneda
   @s_date             = @s_date,
   @i_opcion           = 'L',
   @i_moneda_monto     = @w_moneda_nacional, 
   @i_moneda_resultado = @w_moneda_op, 
   @i_monto            = @w_monto_mn,
   @o_monto_resultado  = @w_monto_mop out, 
   @o_tipo_cambio      = @w_cotizacion_mop out

   if @w_return <> 0 begin
       select @w_error = 710001
       goto ERROR
   end


   /* INSERCION DE CA_ABONO_DET */

   insert into ca_abono_det (
   abd_secuencial_ing,  abd_operacion,    abd_tipo,
   abd_concepto,
   abd_cuenta,          abd_beneficiario, abd_monto_mpg,
   abd_monto_mop,       abd_monto_mn,     abd_cotizacion_mpg,
   abd_cotizacion_mop,  abd_moneda,       abd_tcotizacion_mpg,
   abd_tcotizacion_mop, abd_cheque,       abd_cod_banco,
   abd_solidario)                                             --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
   values (
   @w_secuencial,     @w_operacionca,      'PAG',
   @i_forma_pago,
   @i_referencia,     'DESCUENTO DIRECTO ' + convert(varchar,@i_compania),
   @i_valor,
   @w_monto_mop,       @w_monto_mn,       @w_cot_moneda,
   @w_cotizacion_mop,      @w_moneda,     'T',
   'T',    @i_cheque,   @i_cod_banco, /* ELA ENERO/2002 */
   'N'
)

   if @@rowcount = 0 begin
       select @w_error = 710001
       goto ERROR
   end  
 
   commit tran    
end


return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go

