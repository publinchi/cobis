/************************************************************************/
/*   Archivo            :        cancelsuspen.sp                        */
/*   Stored procedure   :        sp_cancela_suspenso                    */
/*   Base de datos      :        cob_cartera                            */
/*   Producto           :        Cartera                                */
/*   Disenado por                Ivan Jimenez                           */
/*   Fecha de escritura :        Agosto 2006                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                             PROPOSITO                                */
/*   Consulta para front end de renovaciones                            */
/************************************************************************/
/*                            MODIFICACIONES                            */ 
/*       Ago/24/2006    Ivan Jimenez      NREQ 537 proceso operativo de */
/*                                        renovaciones                  */
/*       ULT:ACT:MAY:02:2007                                            */
/*    20/10/2021       G. Fernandez      Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cancela_suspenso')
   drop proc sp_cancela_suspenso
go

create proc sp_cancela_suspenso (
   @s_sesn           int,
   @s_srv            varchar (30) = '',
   @s_ssn            int,
   @s_user           login,
   @s_date           datetime,
   @s_term           varchar(30), 
   @s_ofi            smallint    = null,
   @t_trn            int         = null,
   @i_operacion      char(1),
   @i_banco          cuenta      = null,
   @i_forma_pago     catalogo    = null,
   @i_referencia     cuenta      = null,
   @i_beneficierio   int         = null,
   @i_monto_pesos    money       = null,
   @i_cheque         int         = null,
   @i_cod_banco      smallint    = null
)
as
declare
   @w_sp_name        descripcion,
   @w_error          int,
   @w_mensaje        varchar(132),
   @w_op_operacion   int
   
select @w_sp_name = 'sp_cancela_suspenso'

if @i_operacion = 'Q' -- CONSULTA
begin
   if not exists (select 1
                  from ca_operacion
                  where op_banco = @i_banco)
   begin
      select @w_error = 721001
      goto ERROR
   end
   
   if not exists (select 1
                  from   cobis..cl_ente, ca_operacion 
                  where  op_banco = @i_banco
                  and    op_cliente = en_ente)
   begin
      select @w_error = 721002
      goto ERROR
   end
   
   select   @w_op_operacion = op_operacion
   from     ca_operacion
   where    op_banco = @i_banco
   
   -- Datos de Amortizacion
   select 'CUOTA'     = convert(varchar, am_dividendo),
          'CONCEPTO'  = am_concepto,
          'ESTADO'    = (select es_descripcion from ca_estado where es_codigo = B.am_estado),
          'SALDO'     = (am_acumulado - am_pagado)
   from  ca_amortizacion B
   where am_operacion = @w_op_operacion
   and   am_estado  = 9
   and   (am_acumulado - am_pagado) != 0
   union all
   select 'TOTAL',
          '',
          '',
          sum(am_acumulado - am_pagado)
   from  ca_amortizacion B
   where am_operacion = @w_op_operacion
   and   am_estado  = 9
   and   (am_acumulado - am_pagado) != 0
end

if @i_operacion = 'P' -- ACTUALIZA A ESTADO DE REGISTRO (I) INGRESADO
begin
   select @i_referencia = isnull(@i_referencia, '0')
   
   declare
      @w_op_fecha_ult_proceso datetime,
      @w_op_moneda            smallint,
      @w_cotizacion           float,
      @w_monto_mop            float,
      @w_moneda_nacional      smallint,
      @w_num_dec_mop          tinyint,
      @w_num_dec_mn           tinyint,
      @w_secuencial_ing       int
   
   select @w_op_operacion           = op_operacion,
          @w_op_fecha_ult_proceso   = op_fecha_ult_proceso,
          @w_op_moneda              = op_moneda
   from   ca_operacion
   where  op_banco = @i_banco
   and    op_estado in (1, 2, 4, 9)
   
   if @@rowcount = 0
   begin
      select @w_error = 721003
      goto   ERROR
   end
   
   exec @w_error = sp_buscar_cotizacion
        @i_moneda       = @w_op_moneda,
        @i_fecha        = @w_op_fecha_ult_proceso,
        @o_cotizacion   = @w_cotizacion   OUT
   
   if @w_error != 0 
   begin
      goto ERROR
   end
   
   exec @w_error = sp_decimales
        @i_moneda       = @w_op_moneda,
        @o_decimales    = @w_num_dec_mop     out,
        @o_mon_nacional = @w_moneda_nacional out,
        @o_dec_nacional = @w_num_dec_mn      out
   
   if @w_error != 0 
   begin
      goto ERROR
   end
   
   if @w_op_moneda != @w_moneda_nacional
   begin
      select @w_monto_mop = convert(float, @i_monto_pesos) / @w_cotizacion
      select @w_monto_mop = round(@w_monto_mop, @w_num_dec_mop)
   end
   ELSE
      select @w_monto_mop = @i_monto_pesos
   
   if @i_forma_pago is null
   or @i_monto_pesos is null
   begin
      select @w_error = 721006
      goto ERROR
   end
   
   
   BEGIN TRAN
   
   exec @w_secuencial_ing = sp_gen_sec
        @i_operacion = @w_op_operacion
   
   insert into ca_abono
         (ab_secuencial_ing,  ab_secuencial_rpa,      ab_secuencial_pag,
          ab_operacion,       ab_fecha_ing,           ab_fecha_pag,
          ab_cuota_completa,  ab_aceptar_anticipos,   ab_tipo_reduccion,
          ab_tipo_cobro,      ab_dias_retencion_ini,  ab_dias_retencion,
          ab_estado,          ab_usuario,             ab_oficina,
          ab_terminal,        ab_tipo,                ab_tipo_aplicacion,
          ab_nro_recibo,
          ab_tasa_prepago,    ab_dividendo,           ab_calcula_devolucion,
          ab_prepago_desde_lavigente)
   values(@w_secuencial_ing,  0,                      0,
          @w_op_operacion,    @s_date,                @w_op_fecha_ult_proceso,
          'N',                'N',                    'N',
          'A',                0,                      0,
          'ING',              @s_user,                @s_ofi,
          @s_term,            'PAG',                  'S',
          0,
          null,               null,                   null,
          null)
   
   if @@error != 0
   begin
      ROLLBACK
      select @w_error = 721004
      goto ERROR
   end
   
   --if @i_forma_pago = 'PDGTIA'
      --PRINT 'cancelsuspen.sp consecutivo para sidac @i_cheque %1!',@i_cheque
      
   insert into ca_abono_det
         (abd_secuencial_ing,       abd_operacion,                abd_tipo,
          abd_concepto,             abd_cuenta,                   abd_beneficiario,
          abd_moneda,               abd_monto_mpg,                abd_monto_mop,
          abd_monto_mn,             abd_cotizacion_mpg,           abd_cotizacion_mop,
          abd_tcotizacion_mpg,      abd_tcotizacion_mop,
          abd_cheque,               abd_cod_banco,                abd_inscripcion,
          abd_carga,                abd_solidario)                                  --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
   values(@w_secuencial_ing,        @w_op_operacion,              'PAG',
          @i_forma_pago,            @i_referencia,                '',
          @w_op_moneda,             @i_monto_pesos,               @w_monto_mop,
          @i_monto_pesos,           1,                            @w_cotizacion,
          'N',                      'N',
          @i_cheque,                     null,                         null,
          null,                     'N')
   
   if @@error != 0
   begin
      ROLLBACK
      select @w_error = 721005
      goto ERROR
   end
   
   exec @w_error =  sp_registro_abono
        @s_user            = @s_user,
        @s_srv             = @s_srv,
        @s_term            = @s_term,
        @s_date            = @s_date,
        @s_ofi             = @s_ofi,
        @s_sesn            = @s_sesn,
        @s_ssn             = @s_ssn,
        @i_operacionca     = @w_op_operacion,
        @i_secuencial_ing  = @w_secuencial_ing,
        @i_en_linea        = 'S',
        @i_fecha_proceso   = @s_date,
        @i_no_cheque       = @i_cheque,
        @i_cuenta          = @i_referencia,
        @i_mon             = 0,
        @i_dividendo       = 0,
        @i_cotizacion      = @w_cotizacion
    
   if @w_error != 0 
   begin
      ROLLBACK
      goto ERROR
   end
   
   -- Y LA EJECUCION DE ABONOCA
   exec @w_error = sp_cartera_abono
        @s_sesn           = @s_sesn,
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @s_ssn            = @s_ssn,
        @i_secuencial_ing = @w_secuencial_ing,
        @i_operacionca    = @w_op_operacion,
        @i_fecha_proceso  = @w_op_fecha_ult_proceso,
        @i_en_linea       = 'S',
        @i_solo_capital   = 'N',
        @i_no_cheque      = null,
        @i_cuenta         = null,
        @i_dividendo      = 0,
        @i_cotizacion     = @w_cotizacion
   
   if @w_error !=0 
   begin
      ROLLBACK
      goto ERROR
   end
   
   COMMIT TRAN
end

return 0
ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',    
        @t_file   =  null,
        @t_from   =  @w_sp_name,
        @i_num    =  @w_error,
        @i_msg    =  @w_mensaje
   return   @w_error
go

