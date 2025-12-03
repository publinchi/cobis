/************************************************************************/
/*	Archivo: 		negopma.sp				*/
/*	Stored procedure: 	sp_negociar_operacion_pm		*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Elcira Pelaez Burbano 			*/
/*	Fecha de escritura: 	Mayo -2001				*/
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
/*	Manejo de operaciones individuales en pagos Masivos             */
/*      Operaciones:							*/
/*      'Q'  esta operacion envia a frondt-end el pago de una operacion */
/*           y su detalle, las prioridades de pago y la negociacion     */
/*      'U'  esta operacion actualiza las tablas temporales con la      */
/*           negociaci¢n de la operacion especifica                     */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_negociar_operacion_pm')
   drop proc sp_negociar_operacion_pm
go

create proc sp_negociar_operacion_pm (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_ofi               smallint     = null,
   @t_debug          	char(1)     = 'N',
   @t_file         	varchar(14) = null,
   @t_trn		smallint    = null,     
   @i_banco		cuenta      = null,
   @i_operacion		char(1)     = null,
   @i_subtipo		char(1)     = null,
   @i_cliente      	int         = null,
   @i_compania          int         = null,
   @i_lote              int         = null,
   @i_cuotas            int         = null,
   @i_forma_pago        varchar(10) = null,
   @i_referencia        cuenta      = null,
   @i_valor             money       = null,
   @i_concepto           catalogo   = null,
   @i_valor_prioridad   int         = null,
   @i_secuencial_con    int         = null,
   @i_tipo_de_cobro	char(1)     = null,
   @i_anticipado	char(1)     = null,
   @i_tipo_reduccion	char(1)     = null,
   @i_tipo_aplicacion	char(1)     = null,
   @i_cuota_completa	char(1)     = null,
 @i_cheque              int         = null,/* ELA ENERO/2002 */
 @i_cod_banco           catalogo    = null /* ELA ENERO/2002 */
  --- @o_deuda_hoy         money       = null out

)
as
declare	@w_sp_name			varchar(32),
       	@w_return			int,
	@w_error        		int,
	@w_operacionca                  int,
	@w_moneda_op                    smallint,
	@w_moneda_nacional              smallint,
	@w_monto_mn                     money,
        @w_monto_mpg                    money,
        @w_monto_mop                    money,
        @w_cot_moneda                   float,
        @w_cotizacion_mpg               float,
        @w_cotizacion_mop               float,
        @w_tcot_moneda                  char(1),
        @w_tcotizacion_mpg              char(1),
	@w_tipo_de_cobro		char(1),
        @w_anticipado			char(1),
        @w_tipo_reduccion		char(1),
        @w_tipo_aplicacion		char(1),
        @w_cuota_completa		char(1),
        @w_saldo_pagar                  money,
      @w_toperacion 		catalogo,
      @w_banco 			cuenta,
      @w_moneda                 smallint,
      @w_oficial                int,
      @w_oficina                smallint,
      @w_monto_aprob            money,
      @w_monto                  money,
      @w_fecha_fin 		datetime,
      @w_cliente 		int,
      @w_nombre 		descripcion,
      @w_estado 		descripcion,
      @w_fecha_r 		catalogo,
      @w_tipo_cobro 		char(1),
      @w_acepta_ant 		char(1),
      @w_tipo_red 		char(1),
      @w_tipo_apli 		char(1),
      @w_cuota_comp 		char(1),
      @w_fecha_ult_pro 		datetime



/*  Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_negociar_operacion_pm'

select @w_operacionca = op_operacion,
@w_moneda_op   = op_moneda,
@w_fecha_ult_pro  = op_fecha_ult_proceso
from ca_operacion
where op_banco = @i_banco

if @@rowcount = 0 begin
   select @w_error = 701002
   goto ERROR
end




if @i_operacion = 'Q' begin
   if @i_subtipo = '0' begin
      /* DATOS DE LA CABECERA */
      select                                                       
      @w_toperacion = op_toperacion, 			---1
      @w_banco = op_banco,				---2
      @w_moneda = op_moneda,			---3
      @w_oficial = op_oficial,			---4
      @w_oficina = op_oficina,			---5
      @w_monto_aprob = convert(float,op_monto_aprobado),	---6
      @w_monto = convert(float,op_monto),		---7
      @w_fecha_fin = op_fecha_fin,				---8
      @w_cliente = op_cliente,				---9
      @w_nombre = op_nombre,				--10
      @w_estado = es_descripcion,				--11
      @w_fecha_r = '01/01/1900',				--12
      @w_tipo_cobro = op_tipo_cobro,				--13
      @w_acepta_ant = op_aceptar_anticipos,			--14
      @w_tipo_red = op_tipo_reduccion, 			--15
      @w_tipo_apli = op_tipo_aplicacion,			--16
      @w_cuota_comp = op_cuota_completa,  			--17
      @w_fecha_ult_pro = op_fecha_ult_proceso			--18
      from ca_operacion, 			--19
      ca_estado                                 
      where op_operacion = @w_operacionca                          
      and   es_codigo    = op_estado                 

      /*SALDO A PAGAR*/
      /***************/
      select @w_saldo_pagar = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from ca_amortizacion, ca_dividendo
      where di_operacion = @w_operacionca
      and di_estado in (1,2)
      and am_operacion = @w_operacionca
      and di_operacion = @w_operacionca
      and di_dividendo = am_dividendo


   select
      @w_toperacion,
      @w_banco,
      @w_moneda,  
      @w_oficial,
      @w_oficina,
      @w_monto_aprob,
      @w_monto,
      @w_fecha_fin,
      @w_cliente,
      @w_nombre,
      @w_estado,
      @w_fecha_r,
      @w_tipo_cobro,
      @w_acepta_ant,
      @w_tipo_red,
      @w_tipo_apli,
      @w_cuota_comp,
      @w_fecha_ult_pro,
      @w_saldo_pagar  ---19



      /* PRIORIDADES */
      select 
      ro_concepto, 
      co_descripcion,
      ro_prioridad
      from ca_rubro_op,
      ca_concepto
      where ro_operacion = @w_operacionca
      and   ro_concepto = co_concepto
      and   ro_fpago    not in ('L','B')
      order by ro_concepto
	
      /* DATOS DEL ABONO */
      select
      'Secuencial' 	     = abm_secuencial_ing,
      'Fecha Ing.'	     = convert(varchar(12),abm_fecha_ing,(108)),
      'Pag.Cuota Competa'  = abm_cuota_completa,
      'Acepta Anticipos'   = abm_aceptar_anticipos,
      'Tipo Reduccion'     = abm_tipo_reduccion,
      'Tipo Cobr'          = abm_tipo_cobro,
      'Estado'             = abm_estado,
      'Usuario'            = abm_usuario,
      'Ofi'                = abm_oficina,
      'Tipo'               = abm_tipo,
      'Tipo Aplicacion'    = abm_tipo_aplicacion
      from ca_abono_masivo
      where abm_lote = @i_lote
      and   abm_operacion = @w_operacionca

      /* DETALLES DEL ABONO */
      select
      'Secuencial'	      = abmd_secuencial_ing,
      'No. Operacion'       = abmd_operacion,
      'Tipo'                = abmd_tipo,
      'Forma de Pago'       = abmd_concepto,
      'No. Referencia'      = abmd_cuenta,
      'Moneda'              = abmd_moneda,
      'Valor a pagar'       = abmd_monto_mn
      from ca_abono_masivo,
      ca_abono_masivo_det
      where abm_operacion = abmd_operacion  
      and abm_secuencial_ing = abmd_secuencial_ing
      and abmd_operacion  = @w_operacionca
      and abm_lote        = @i_lote




   end /*subtipo 0 */
end /* operacion Q */

if @i_operacion = 'U' begin
   /*PRIORIDADES*/
   if @i_subtipo = '0' begin
      update ca_abono_masivo_prioridad
      set amp_prioridad = @i_valor_prioridad
      from ca_abono_masivo_prioridad,
      ca_abono_masivo
      where amp_operacion = abm_operacion
      and amp_secuencial_ing = abm_secuencial_ing
      and amp_operacion = @w_operacionca
      and abm_lote =  @i_lote
      and amp_concepto = @i_concepto
      
      if @@error != 0 begin
         select @w_error = 710241
         goto ERROR
      end  
   end /*subtipo 0 */

   /*CONDONACIONES*/
   if @i_subtipo = '1' begin
      select @w_moneda_nacional = pa_tinyint
      from cobis..cl_parametro
      where pa_producto = 'ADM'
      and   pa_nemonico = 'MLO'
      set transaction isolation level read uncommitted

      exec @w_return = sp_conversion_moneda
      @s_date             = @s_date,
      @i_opcion           = 'L',
      @i_moneda_monto     = @w_moneda_op, 
      @i_moneda_resultado = @w_moneda_nacional, 
      @i_monto            = @i_valor,
      @i_fecha            = @w_fecha_ult_pro,
      @o_monto_resultado  = @w_monto_mn out,  
      @o_tipo_cambio      = @w_cot_moneda out 

      if @w_return <> 0 begin
	 select @w_error = 710001
	 goto ERROR
      end

      --PRINT '@i_valor'+ @i_valor + '@w_monto_mn'+  @w_monto_mn + '@w_cot_moneda' + @w_cot_moneda
  
      insert into ca_abono_masivo_det (
      abmd_secuencial_ing,  abmd_operacion,    abmd_tipo,  abmd_concepto,
      abmd_cuenta,          abmd_beneficiario, abmd_monto_mpg,
      abmd_monto_mop,       abmd_monto_mn,     abmd_cotizacion_mpg,
      abmd_cotizacion_mop,  abmd_moneda,       abmd_tcotizacion_mpg,
      abmd_tcotizacion_mop, abmd_cheque,       abmd_cod_banco)
      values (
      @i_secuencial_con,    @w_operacionca,      'CON',  @i_concepto,
      '0',                  @i_referencia,       @i_valor,
      @i_valor,             @w_monto_mn,         @w_cot_moneda,
      @w_cot_moneda,        @w_moneda_op,        'N',  
      'N',                  @i_cheque,            @i_cod_banco)

      if @@error != 0 begin
	 select @w_error = 710224
	 goto ERROR
      end  
    
      /*******
      update ca_abono_masivo_det
      set abmd_monto_mpg  = abmd_monto_mpg - @i_valor,
      abmd_monto_mop  = abmd_monto_mop - @i_valor,
      abmd_monto_mn   = abmd_monto_mn  - @i_valor
      where abmd_operacion = @w_operacionca
      and abmd_secuencial_ing  = @i_secuencial_con
      and abmd_tipo     = 'PAG'
       
      if @@error != 0 begin
	 select @w_error = 710229
	 goto ERROR
      end
      *********/ --MPO  
   end /*subtipo 1 */

   if @i_subtipo = '2' begin
      select 
      @w_tipo_de_cobro      = abm_tipo_cobro,	    
      @w_anticipado         = abm_aceptar_anticipos,  
      @w_tipo_reduccion     = abm_tipo_reduccion,      
      @w_tipo_aplicacion    = abm_tipo_aplicacion,     
      @w_cuota_completa     = abm_cuota_completa      
      from ca_abono_masivo
      where abm_operacion = @w_operacionca
      and abm_lote      = @i_lote

      if @i_tipo_de_cobro is null
         select @i_tipo_de_cobro = @w_tipo_de_cobro

      if @i_anticipado is null
         select @i_anticipado = @w_anticipado

      if @i_tipo_reduccion is null
         select @i_tipo_reduccion  =   @w_tipo_reduccion

      if @i_tipo_aplicacion	is null
	 select @i_tipo_aplicacion =  @w_tipo_aplicacion

      if @i_cuota_completa is null 
         select @i_cuota_completa   = @w_cuota_completa
    

      update ca_abono_masivo    
      set abm_tipo_cobro     = @i_tipo_de_cobro,
      abm_aceptar_anticipos  = @i_anticipado,
      abm_tipo_reduccion     = @i_tipo_reduccion,
      abm_tipo_aplicacion    = @i_tipo_aplicacion,
      abm_cuota_completa     = @i_cuota_completa
      where abm_operacion = @w_operacionca
      and abm_lote      = @i_lote
      
      if @@error != 0 begin
         select @w_error = 710231
         goto ERROR
      end  
   end /*subtipo 2 */
end /*operacion U */

set rowcount 0

return 0

ERROR:
  exec cobis..sp_cerror
  @t_debug = 'N',
  @t_file  = null, 
  @t_from  = @w_sp_name,
  @i_num   = @w_error
  return @w_error 

go
