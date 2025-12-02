/************************************************************************/
/*   Archivo           :         aplicndc.sp                            */
/*   Stored procedure  :         sp_aplicar_notas_dc                    */
/*   Base de datos     :         cob_cartera                            */
/*   Producto          :          Cartera                               */
/*   Disenado por      :        Elcira Pelaez B.                        */
/*   Fecha de escritura:         Feb-28-2002                            */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Procedimiento para aplicar las notas DC en Ahorros o Ctes.         */
/************************************************************************/
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */ 
/*   23/abr/2010   Fdo Carvajal Interfaz Ahorros-CCA                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aplicar_notas_dc')
   drop proc sp_aplicar_notas_dc
go


create proc sp_aplicar_notas_dc
@s_sesn                 int         = null,
@s_user                 login       = null,
@s_term                 varchar(30) = null,
@s_date                 datetime    = null,
@s_ofi                  smallint    = null,
@s_srv                  varchar(30) = null,
@i_en_linea             char(1)     = 'N',
@i_fecha_proceso        datetime    

as
declare
@w_sp_name              varchar(30),
@w_return               int,
@w_in_secuencial_ing    int, 
@w_in_operacion         int,
@w_in_concepto          catalogo, 
@w_in_cuenta            cuenta, 
@w_in_moneda            tinyint,
@w_in_banco             cuenta,
@w_in_monto_aplicar     money,
@w_tran                 int,
@w_error                int,
@w_op_moneda            smallint,
@w_num_dec              smallint,
@w_moneda_n             smallint,
@w_valor_debitado       money,
@w_num_dec_n            smallint,
@w_ab_dias_retencion    int,
@w_forma_pago_pasiva    catalogo,
@w_moneda_nacional      tinyint,
@w_cotizacion_hoy       money,
@w_op_fecha_ult_proceso datetime,
@w_mensaje              varchar(100),   -- FCP Interfaz Ahorros
@w_registro             char(50)



--- INICIALIZAR VARIABLES 
select @w_sp_name = 'sp_aplicar_notas_dc'


-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

select @w_forma_pago_pasiva = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'PAGOPA'
set transaction isolation level read uncommitted

--CARGAR LA INFORMACION DE ABONOS
declare
   cursor_aplicar_ndc cursor
   for select in_secuencial,   in_operacion, in_banco,
              in_forma_pago,   in_cuenta,    in_moneda_pago,
              in_monto_aplicar --MONEDA NAL
       from   ca_interfaz_ndc
       where  in_fecha_proceso = @i_fecha_proceso
       and    in_estado = 'I'
       and    in_error is null
       order  by in_secuencial,in_operacion
       for read only

open cursor_aplicar_ndc

fetch cursor_aplicar_ndc
into  @w_in_secuencial_ing,   @w_in_operacion,  @w_in_banco,
      @w_in_concepto,         @w_in_cuenta,     @w_in_moneda,
      @w_in_monto_aplicar --MONEDA NAL

--while (@@fetch_status not in (-1,0))
while (@@fetch_status = 0)
    begin
   BEGIN TRAN --ATOMICIDAD POR REGISTRO
   
   select 
   @w_valor_debitado =  0, 
   @w_mensaje = null      -- FCP Interfaz Ahorros
   
   if @w_forma_pago_pasiva =  @w_in_concepto
      select @w_valor_debitado = @w_in_monto_aplicar
   
   select @w_op_moneda = op_moneda,
          @w_op_fecha_ult_proceso = op_fecha_ult_proceso
   from   ca_operacion
   where  op_operacion =  @w_in_operacion
   
   -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
   if @w_op_moneda = @w_moneda_nacional
      select @w_cotizacion_hoy = 1.0
   ELSE
   begin
      exec sp_buscar_cotizacion
           @i_moneda     = @w_op_moneda,
           @i_fecha      = @w_op_fecha_ult_proceso,
           @o_cotizacion = @w_cotizacion_hoy output
   end
   
   select @w_ab_dias_retencion = ab_dias_retencion
   from   ca_abono
   where  ab_operacion        = @w_in_operacion
   and    ab_secuencial_ing   = @w_in_secuencial_ing
   
   -- LECTURA DE DECIMALES
   exec @w_return = sp_decimales
        @i_moneda       = @w_op_moneda,
        @o_decimales    = @w_num_dec out,
        @o_mon_nacional = @w_moneda_n out,
        @o_dec_nacional = @w_num_dec_n out
   
   if @w_return != 0
   begin
      select @w_error =  @w_return
      goto ERROR_ABONO
   end
   
   if @w_forma_pago_pasiva  !=  @w_in_concepto ---EPB-sep-26
   begin
      -- GENERAR LA NOTA DEBITO A LA CUENTA
      exec @w_return = sp_afect_prod_cobis
      @s_user            = @s_user,
      @s_term            = @s_term,   
      @s_date            = @s_date,
      @s_ofi             = @s_ofi,
      @i_en_linea        = @i_en_linea,
      @i_fecha           = @i_fecha_proceso,
      @i_cuenta          = @w_in_cuenta,
      @i_producto        = @w_in_concepto,
      @i_monto           = @w_in_monto_aplicar,
      @i_mon             = @w_in_moneda,
      @i_operacionca     = @w_in_operacion,
      @i_sec_tran_cca    = @w_in_secuencial_ing,  -- FCP Interfaz Ahorros
      @i_alt             = @w_in_operacion,
      @o_monto_real      = @w_valor_debitado out
      
      if @w_return != 0
      begin
         select @w_error = @w_return
         
         -- DESHACE LA TRANSACCION
         while @@trancount > 0 ROLLBACK
         
         -- GRABAR EL ERROR
         begin tran
         
         update  ca_abono
         set     ab_estado = 'E'
         where   ab_operacion      = @w_in_operacion
         and     ab_secuencial_ing = @w_in_secuencial_ing

         select @w_registro = 'aplicndc.sp USUARIO:'  + ' ' +  @s_user   + ' ' +  @s_term  + '' +  'LINEA  = N'
   
         update ca_abono_det
         set abd_beneficiario = @w_registro
         where abd_secuencial_ing = @w_in_secuencial_ing
         and   abd_operacion      = @w_in_operacion
         
         
         update ca_interfaz_ndc
         set    in_error = @w_return
         where  in_operacion  = @w_in_operacion
         and    in_secuencial = @w_in_secuencial_ing
         
         commit
         
         goto ERROR_ABONO
      end
      
      -- CONVERSION DEL MONTO DEBITADO A LA MONEDA DE PAGO Y OPERACION
      
      if @w_in_monto_aplicar > @w_valor_debitado
      begin
         -- ACTUALIZAR EL DETALLE DE PAGO
         update ca_abono_det
         set    abd_monto_mn  = @w_valor_debitado,
                abd_monto_mpg = @w_valor_debitado,
                abd_monto_mop = round(@w_valor_debitado / abd_cotizacion_mop,@w_num_dec)
         where  abd_operacion      = @w_in_operacion
         and    abd_secuencial_ing = @w_in_secuencial_ing
         
         if @@error != 0
         begin
            select @w_tran  = 7999
            select @w_error = 708152
            
            -- DESHACE LA TRANSACCION
            while @@trancount > 0 ROLLBACK
            
            begin tran -- GRABAR EL ERROR
            
            update ca_interfaz_ndc
            set    in_error = @w_error
            where  in_secuencial   = @w_in_secuencial_ing
            and    in_operacion   = @w_in_operacion
            
            commit
            
            goto ERROR_ABONO
         end
      end  
   end ---EPB-sep-26
   
   update ca_abono
   set    ab_estado = 'P',
          ab_cuota_completa  = 'N'
   where  ab_operacion      = @w_in_operacion
   and    ab_secuencial_ing = @w_in_secuencial_ing
   
   
   -- APLICAR EN CARTERA EL ABONO
   
   exec @w_return = sp_registro_abono
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @i_secuencial_ing = @w_in_secuencial_ing,
        @i_en_linea       = 'N',
        @i_operacionca    = @w_in_operacion,
        @i_fecha_proceso  = @i_fecha_proceso,
        @i_cotizacion     = @w_cotizacion_hoy
   
   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR_ABONO
   end
    
   -- INICIO FCP Interfaz Ahorros
   update ca_secuencial_atx set 
   sa_secuencial_cca = ab_secuencial_rpa
   from ca_abono
   where ab_operacion      = @w_in_operacion
   and   ab_secuencial_ing = @w_in_secuencial_ing
   and   sa_operacion      = @w_in_banco
   and   sa_secuencial_cca = @w_in_secuencial_ing
   
   if @@error != 0
   begin
      select 
      @w_error   = 708152, 
      @w_mensaje = 'NO SE PUEDE ACTUALIZAR SECUENCIALES DE ATX' 
      goto ERROR_ABONO
   end 
   -- FIN FCP Interfaz Ahorros


   
   if @w_ab_dias_retencion <= 0
   begin
      -- APLICACION DEL PAGO
      
      exec @w_return = sp_cartera_abono
           @s_sesn           = @s_sesn,
           @s_user           = @s_user,
           @s_term           = @s_term,
           @s_date           = @s_date,
           @s_ofi            = @s_ofi,
           @i_secuencial_ing = @w_in_secuencial_ing,
           @i_en_linea       = 'N',
           @i_operacionca    = @w_in_operacion,
           @i_fecha_proceso  = @i_fecha_proceso,
           @i_cotizacion     = @w_cotizacion_hoy
      
      if @w_return != 0
      begin
         select @w_error = @w_return
         goto ERROR_ABONO
      end 
      else
      begin
   
         update ca_interfaz_ndc
         set    in_monto_aplicado = round(@w_valor_debitado,@w_num_dec_n),
                in_estado         = 'P'
         where  in_secuencial = @w_in_secuencial_ing
         and    in_operacion  = @w_in_operacion
   
        --cargadas paso numero 1 roceso notasdau.sp
         update ca_opercaion_ndaut
         set ona_proceso = 'aplicndc.sp',
             ona_numero_indicador  = 3     
         where ona_operacion = @w_in_operacion
         and   ona_fecha_proceso = @i_fecha_proceso      
   
         
      end
      -- ABONO APLICADO EN CARTERA
   end
   
   COMMIT TRAN -- ASEGURA LA TRANSACCION
   
   goto SIGUIENTE
   
   ERROR_ABONO:
   
   while @@trancount > 0 ROLLBACK
   
   BEGIN TRAN
   
   exec sp_errorlog
        @i_fecha       = @i_fecha_proceso,
        @i_error       = @w_error,
        @i_usuario     = @s_user,
        @i_tran        = 7000, 
        @i_tran_name   = @w_sp_name,
        @i_rollback    = 'N',
        @i_cuenta      = @w_in_banco,
        @i_descripcion = @w_mensaje,    -- FCP Interfaz Ahorros
        @i_anexo       = 'aplicndc.sp APLICANDO NOTAS DEBITO y CREDITO'
   
   COMMIT
   
   goto SIGUIENTE
   
   SIGUIENTE:
   fetch cursor_aplicar_ndc
   into  @w_in_secuencial_ing,   @w_in_operacion,  @w_in_banco,
         @w_in_concepto,         @w_in_cuenta,     @w_in_moneda,
         @w_in_monto_aplicar --MOMEDA NAL
end

close cursor_aplicar_ndc
deallocate cursor_aplicar_ndc
   
return 0
go
