/************************************************************************/
/*      Archivo:                debmasiv.sp                             */
/*      Stored procedure:       sp_debito masivo                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Marcelo Poveda                          */
/*      Fecha de escritura:     Feb. 2001                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Procedimiento que realiza la afectacion a cuentas Corriente o   */
/*      de Ahorros en forma masiva                                      */
/************************************************************************/
/*  MODIFICACIONES                                                      */
/*  FECHA          AUTOR             RAZON                              */
/*   23/abr/2010   Fdo Carvajal Interfaz Ahorros-CCA                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_debito_masivo')
   drop proc sp_debito_masivo
go

create proc sp_debito_masivo
@s_ssn                  int,
@s_sesn                 int,
@s_srv                  varchar(30),                    
@s_ofi                  smallint,                       
@s_user                 login,
@s_term                 varchar(30),
@s_date                 datetime,
@i_en_linea             char(1) = 'N'
as 
declare
@w_sp_name              descripcion,
@w_error                int,
@w_return               int,
@w_ab_operacion         int,   
@w_ab_sec_rpa           int, -- FCP Interfaz Ahorros
@w_ab_cuota_completa    char(1),  
@w_ab_tipo_cobro        char(1),
@w_ab_secuencial_ing    int,
@w_ab_estado            char(1),
@w_abd_concepto         catalogo,   
@w_abd_cuenta           cuenta,         
@w_abd_moneda           smallint,
@w_abd_monto_mpg        money,
@w_abd_monto_mop        money,
@w_abd_cotizacion_mop   money,
@w_abd_cotizacion_mpg   money,
@w_abd_monto_mn         money,
@w_op_moneda            smallint,
@w_op_banco             cuenta,
@w_num_dec              tinyint,
@w_moneda_n             smallint,
@w_num_dec_n            tinyint,
@w_monto                money,
@w_monto_real           money,
@w_cot_moneda           money    

/** VARIABLES DE TRABAJO **/
select
@w_sp_name        = 'sp_debito_masivo'

select @s_date = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7


/** CURSOR DE NOTAS DE DEBITO **/
declare cursor_notas cursor for
select  
ab_operacion,   ab_cuota_completa,   ab_tipo_cobro,
abd_concepto,   abd_cuenta,          abd_moneda,
abd_monto_mpg,  ab_secuencial_ing,   ab_secuencial_rpa          -- FCP Interfaz Ahorros
from  ca_abono,   ca_abono_det,   ca_producto
where ab_secuencial_ing  = abd_secuencial_ing
and   ab_operacion       = abd_operacion
and   abd_concepto       = cp_producto
and   cp_categoria       in  ('NDAH','NDCC')
and   abd_tipo           = 'PAG' 
and   ab_fecha_ing       = @s_date
and   ab_estado          = 'ING'
for read only

open cursor_rubro

fetch   cursor_notas into
@w_ab_operacion,   @w_ab_cuota_completa,  @w_ab_tipo_cobro,
@w_abd_concepto,   @w_abd_cuenta,         @w_abd_moneda,
@w_abd_monto_mpg,  @w_ab_secuencial_ing,  @w_ab_sec_rpa         -- FCP Interfaz Ahorros

/** WHILE CURSOR PRINCIPAL **/
while @@fetch_status = 0 begin 
   if (@@fetch_status = -1) begin
      select @w_error = 708999 
      goto ERROR
   end

   /** INFORMACION DE OPERACION **/
   select @w_op_moneda = op_moneda,
   @w_op_banco         = op_banco
   from   ca_operacion
   where  op_operacion = @w_ab_operacion

   /** LECTURA DE DECIMALES **/
   exec @w_return = sp_decimales
   @i_moneda       = @w_op_moneda,
   @o_decimales    = @w_num_dec out,
   @o_mon_nacional = @w_moneda_n out,
   @o_dec_nacional = @w_num_dec_n out   

   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

   if @w_ab_cuota_completa = 'S' begin
      /** CONSULTAR EL MONTO TOTAL DE PAGO **/
      exec @w_return = sp_consulta_cuota
      @i_operacionca   = @w_ab_operacion,
      @i_moneda        = @w_op_moneda,
      @i_tipo_cobro    = @w_ab_tipo_cobro,
      @i_fecha_proceso = @s_date,
      @o_monto         = @w_monto out

      if @w_return != 0 begin
         select @w_error = @w_return
         goto ERROR
      end

      /** CONVERSION DEL MONTO CALCULADO A LA MONEDA DE PAGO Y DE OPERACION **/
      exec @w_return = sp_conversion_moneda
      @s_date             = @s_date,
      @i_opcion           = 'L',
      @i_moneda_monto     = @w_op_moneda,
      @i_moneda_resultado = @w_abd_moneda,
      @i_monto            = @w_monto,
      @o_monto_resultado  = @w_abd_monto_mpg out,
      @o_tipo_cambio      = @w_abd_cotizacion_mpg out

      if @w_return != 0 begin
         select @w_error = @w_return
         goto ERROR
      end
      
   end

   begin tran

   /** AFECTACION A OTROS PRODUCTOS **/
   exec @w_return = sp_afect_prod_cobis
   @s_ssn          = @s_ssn,
   @s_sesn         = @s_sesn,
   @s_srv          = @s_srv,
   @s_ofi          = @s_ofi,
   @i_fecha        = @s_date,
   @i_en_linea     = @i_en_linea,
   @i_cuenta       = @w_abd_cuenta,
   @i_producto     = @w_abd_concepto,
   @i_monto        = @w_abd_monto_mpg,
   @i_operacionca  = @w_ab_operacion,
   @i_alt          = @w_ab_operacion,
   @i_sec_tran_cca = @w_ab_sec_rpa,             -- FCP Interfaz Ahorros
   @o_monto_real   = @w_monto_real out

   if @w_return != 0
      select @w_ab_estado = 'E' 
   else
      select @w_ab_estado = 'P'

   if @w_monto_real < @w_abd_monto_mpg begin
      /** CONVERSION DEL MONTO CALCULADO A LA MONEDA DE OPERACION **/
      exec @w_return = sp_conversion_moneda
      @s_date             = @s_date,
      @i_opcion           = 'L',
      @i_moneda_monto     = @w_abd_moneda,
      @i_moneda_resultado = @w_op_moneda,
      @i_monto            = @w_monto_real,
      @o_monto_resultado  = @w_abd_monto_mop out,
      @o_tipo_cambio      = @w_abd_cotizacion_mpg out

      if @w_return != 0 begin
         select @w_error = @w_return
         goto ERROR
      end
 
      /** CONVERSION DEL MONTO CALCULADO A LA MONEDA LOCAL **/
      exec @w_return = sp_conversion_moneda
      @s_date             = @s_date,
      @i_opcion           = 'L',
      @i_moneda_monto     = @w_abd_moneda,
      @i_moneda_resultado = @w_moneda_n,
      @i_monto            = @w_monto_real,
      @o_monto_resultado  = @w_abd_monto_mn out,
      @o_tipo_cambio      = @w_abd_cotizacion_mop out

      if @w_return != 0 begin
         select @w_error = @w_return
         goto ERROR
      end

      /** ACTUALIZACION DEL DETALLE DE ABONO **/
      update ca_abono_det set 
      abd_monto_mpg            = @w_abd_monto_mpg,
      abd_monto_mop            = @w_abd_monto_mop,
      abd_cotizacion_mop       = @w_abd_cotizacion_mop,
      abd_cotizacion_mpg       = @w_abd_cotizacion_mpg,
      abd_monto_mn             = @w_abd_monto_mn
      where abd_secuencial_ing = @w_ab_secuencial_ing
      and   abd_operacion      = @w_ab_operacion
   end

   update ca_abono set
   ab_estado                = @w_ab_estado,
   ab_cuota_completa        = 'N'
   where ab_secuencial_ing  = @w_ab_secuencial_ing
   and   ab_operacion       = @w_ab_operacion

   commit tran
   goto SIGUIENTE

   ERROR:
   if @i_en_linea = 'S' begin
      exec cobis..sp_cerror
      @t_debug='N',
      @t_file=null,
      @t_from=@w_sp_name,
      @i_num = @w_error
      return @w_error
   end else begin 
      exec sp_errorlog
      @i_fecha          = @s_date,
      @i_error          = @w_error,
      @i_usuario        = @s_user,
      @i_tran           = 7999,
      @i_tran_name      = @w_sp_name,
      @i_cuenta         = @w_op_banco,
      @i_rollback       = 'S'
    
      while @@trancount > 0 
         rollback tran
      
      goto SIGUIENTE   
   end
   
   SIGUIENTE:
   fetch   cursor_notas into
   @w_ab_operacion,   @w_ab_cuota_completa,  @w_ab_tipo_cobro,
   @w_abd_concepto,   @w_abd_cuenta,         @w_abd_moneda,
   @w_abd_monto_mpg,  @w_ab_secuencial_ing,  @w_ab_sec_rpa              -- FCP Interfaz Ahorros
end

close cursor_notas
deallocate cursor_notas


return 0

go

