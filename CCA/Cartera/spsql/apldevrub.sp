/************************************************************************/
/*  Nombre Fisico:      apldevrub.sp                               		*/
/*  Nombre Logico:   	sp_aplica_devolucion_rubro                      */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:       Daniel Upegui                                   */
/*  Fecha de escritura: 24/Ago/2005                                     */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*  PROPOSITO                                                           */
/*  Este programa realiza  lo siguiente:                                */
/*      Aplicar la devoluci¢n de rubros pendientes                      */
/*      en la tabla ca_devolucion_rubro.                                */
/************************************************************************/
/*  MODIFICACIONES                                                      */
/*  FECHA          AUTOR             RAZON                              */
/*  25-Jul-2005    Daniel Upegui      Emision Inicial                   */
/*  10-MAr-2006    Elcira Pelaez      Def.6105 nullen dtr_cuenta        */
/*  23/abr/2010    Fdo Carvajal Interfaz Ahorros-CCA                    */
/*  17/abr/2023    Guisela Fernandez     S807925 Ingreso de campo de    */
/*                                      reestructuracion                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aplica_devolucion_rubro')
   drop proc sp_aplica_devolucion_rubro
go

create proc sp_aplica_devolucion_rubro (
   @s_user  login       = 'operdevr',
   @s_date  datetime    ,
   @s_term  varchar(30) = 'operdevr',
   @s_ssn   int         = 1,
   @s_sesn  int         = 1,
   @s_srv   varchar(30) = 'srv'
)
as
declare
   @w_sp_name              varchar(64),
   @w_error                int,
   @w_operacion            int,
   @w_formapago            catalogo,
   @w_drestado             char(3),
   @w_dr_referencia        cuenta,
   @w_monto                money,
   @w_montomn              money,
   @w_fecha_ult_proc       datetime,
   @w_secuencial           int,
   @w_toperacion           catalogo,
   @w_moneda               tinyint,
   @w_fecha_ini            datetime,
   @w_calificacion         catalogo, -- MCO 05/06/2023 Se cambio el tipo de dato de char(1) a catalogo
   @w_banco                cuenta,
   @w_op_gar_admisible     char(1),
   @w_concepto             catalogo,
   @w_codvalor             int,
   @w_codvalorfp           int,
   @w_cotizacion           money,
   @w_fecha_liq            datetime,
   @w_cuenta               cuenta,
   @w_sesion               int,
   @w_pcobis                tinyint,
   @w_oficina              int,
   @w_descripcion          descripcion,
   @w_reestructuracion     char(1)

select @w_sp_name = 'sp_aplica_devolucion_rubro'
select @w_secuencial = null

declare
   ca_devrubro cursor
   for select  dr_operacion,  dr_forma_pago, dr_monto,
               dr_concepto,   dr_estado,     isnull(dr_referencia,'')
       from    cob_cartera..ca_devolucion_rubro
       where   dr_estado  = 'ING'
   for update
   
open ca_devrubro

fetch ca_devrubro
into  @w_operacion,  @w_formapago, @w_monto,
      @w_concepto,   @w_drestado,  @w_dr_referencia

--while @@fetch_status not in (-1, 0)
while @@fetch_status = 0
begin
   
   select @w_fecha_ult_proc      = op_fecha_ult_proceso,
          @w_toperacion          = op_toperacion, 
          @w_moneda              = op_moneda, 
          @w_fecha_ini           = op_fecha_ini, 
          @w_calificacion        = isnull(op_calificacion, 'A'),
          @w_banco               = op_banco,
          @w_fecha_liq           = op_fecha_liq,
          @w_op_gar_admisible    = isnull(op_gar_admisible, 'N'),
          @w_oficina             = op_oficina,
		  @w_reestructuracion    = isnull(op_reestructuracion, 'N')
   from   cob_cartera..ca_operacion
   where  op_operacion = @w_operacion
   and    op_estado in (1,2)
   
   if @@rowcount = 0
   begin
      select @w_error = 701049
      goto ERROR_OPER
   end
   
   BEGIN TRAN
   exec @w_secuencial = sp_gen_sec
        @i_operacion  = @w_operacion
   COMMIT
   
   BEGIN TRAN
   
   exec @w_error  = sp_historial
        @i_operacionca  = @w_operacion,
        @i_secuencial   = @w_secuencial
      
   if @w_error != 0
   begin
      goto ERROR_OPER
   end
   
   select @w_sesion = @w_operacion * 100 + @w_secuencial
   
   insert into ca_transaccion
         (tr_secuencial,         tr_fecha_mov,        tr_toperacion,
          tr_moneda,             tr_operacion,        tr_tran,
          tr_en_linea,           tr_banco,            tr_dias_calc,
          tr_ofi_oper,           tr_ofi_usu,          tr_usuario,
          tr_terminal,           tr_fecha_ref,        tr_secuencial_ref,
          tr_estado,             tr_observacion,      tr_gerente,
          tr_gar_admisible,      tr_reestructuracion,      
          tr_calificacion,       tr_fecha_cont,       tr_comprobante)
   values(@w_secuencial,         @s_date,             @w_toperacion,
          @w_moneda,             @w_operacion,        'RCO',
          'N',                   @w_banco,            1,
          @w_oficina,            @w_oficina,          @s_user,
          @s_term,               @w_fecha_ult_proc,   0,
          'ING',                 'DEVOLUCION COMICIONES', 0,
          @w_op_gar_admisible,   @w_reestructuracion,     
          @w_calificacion,       @s_date,             0)
   
   if @@error != 0
   begin
      select @w_error = 708165
      goto ERROR_OPER
   end
   
   
   select @w_codvalor = co_codigo * 1000 + 30
   from   ca_concepto
   where  co_concepto    = @w_concepto

   if @@rowcount = 0
   begin
      select @w_error = 701145
      goto ERROR_OPER
   end
      
   
   If @w_moneda  <> 0
   begin
      select @w_cotizacion = ct_valor
      from   cob_conta..cb_cotizacion
      where  ct_moneda =  @w_moneda   
      and    ct_fecha =  @w_fecha_ini
   end
   ELSE
      select @w_cotizacion = 1
   
   select @w_montomn = round(@w_monto * @w_cotizacion,0)
   
   insert into ca_det_trn
         (dtr_secuencial, dtr_operacion,    dtr_dividendo,
          dtr_concepto,
          dtr_estado,     dtr_periodo,      dtr_codvalor,
          dtr_monto,      dtr_monto_mn,     dtr_moneda,
          dtr_cotizacion, dtr_tcotizacion,  dtr_afectacion,
          dtr_cuenta,     dtr_beneficiario, dtr_monto_cont)
   values(@w_secuencial,  @w_operacion,     1,
          @w_concepto,
          3,              1,                @w_codvalor,
          @w_monto,       @w_montomn,       @w_moneda,
          @w_cotizacion,  'N',              'D',
          '',             '',               0)
   
   if @@error != 0
   begin
      select @w_error = 708166
      goto ERROR_OPER
   end
   
   select @w_codvalorfp = cp_codvalor,
          @w_pcobis     = isnull(cp_pcobis,0)
   from   ca_producto
   where  cp_producto   = @w_formapago

   if @@rowcount = 0
   begin
      select @w_error = 701145
      goto ERROR_OPER
   end
      
   
   insert into ca_det_trn
         (dtr_secuencial,     dtr_operacion,    dtr_dividendo,
          dtr_concepto,
          dtr_estado,         dtr_periodo,      dtr_codvalor,
          dtr_monto,          dtr_monto_mn,     dtr_moneda,
          dtr_cotizacion,     dtr_tcotizacion,  dtr_afectacion,
          dtr_cuenta,         dtr_beneficiario, dtr_monto_cont)
   values(@w_secuencial,      @w_operacion,     1,
          @w_formapago,
          3,                  1,                @w_codvalorfp,
          @w_monto,           @w_montomn,       @w_moneda,
          @w_cotizacion,      'N',              'D',
          @w_dr_referencia,   '',               0)
   
   if @@error != 0
   begin
      return 708166
   end
   
   update ca_amortizacion
   set    am_cuota = am_pagado,
          am_acumulado = am_pagado
   where  am_operacion = @w_operacion
   and    am_concepto  = @w_concepto
   
   if exists(select 1
             from   ca_producto
             where  cp_producto = @w_formapago
             and    cp_pcobis   = 7) -- EL PRODUCTO ES CARTERA
      select @w_cuenta = @w_banco
   ELSE
      select @w_cuenta = @w_dr_referencia 
   
   -- AFECTACION A OTROS PRODUCTOS
   if @w_cuenta <> '' and @w_cuenta is not null and @w_pcobis > 0
   begin
      select @w_descripcion = 'DEVOLUCION DE COMISIONES DESDE CARTERA : ' + cast(@w_banco as varchar)
      exec @w_error = sp_afect_prod_cobis
           @s_ofi                = 9000,
           @s_user               = @s_user,
           @s_date               = @s_date,
           @s_ssn                = @w_sesion,
           @s_sesn               = @s_sesn,
           @s_term               = @s_term,
           @s_srv                = @s_srv,
           @i_fecha              = @w_fecha_liq,
           @i_cuenta             = @w_cuenta,
           @i_producto           = @w_formapago,
           @i_monto              = @w_monto,
           @i_mon                = @w_moneda,
           @i_beneficiario       = '',
           @i_monto_mpg          = @w_montomn,
           @i_monto_mop          = @w_montomn,
           @i_monto_mn           = @w_montomn,
           @i_cotizacion_mop     = @w_cotizacion,
           @i_tcotizacion_mop    = 'N',
           @i_cotizacion_mpg     = @w_cotizacion,
           @i_tcotizacion_mpg    = 'N',
           @i_operacionca        = @w_operacion,
           @i_operacion_renovada = -1,
           @i_alt                = @w_operacion,
           @i_descripcion        = @w_descripcion,
           @i_sec_tran_cca       = @w_secuencial,  -- FCP Interfaz Ahorros
           @o_num_renovacion     = 0
      
      if @w_error != 0
      begin
         goto ERROR_OPER
      end
   end
   update ca_devolucion_rubro --Cambia el estado del registro de ING a A
   set    dr_estado = 'A',
          dr_secuencial_tr = @w_secuencial
   where  CURRENT OF ca_devrubro
   
   COMMIT TRAN
   goto SIG_OPER
   
ERROR_OPER:
   
   while @@trancount>1 rollback
   
   exec sp_errorlog 
        @i_fecha     = @s_date,
        @i_error     = @w_error, 
        @i_usuario   = @s_user, 
        @i_tran      = 7999,
        @i_tran_name = @w_sp_name,
        @i_cuenta    = @w_banco,
        @i_rollback  = 'S'
   
SIG_OPER:   
   fetch ca_devrubro
   into  @w_operacion,  @w_formapago,  @w_monto,
         @w_concepto,   @w_drestado,   @w_dr_referencia
end -- while

close ca_devrubro
deallocate ca_devrubro

return 0
ERROR:
   while @@rowcount > 0 rollback
   
   exec sp_errorlog 
        @i_fecha     = @s_date,
        @i_error     = @w_error, 
        @i_usuario   = @s_user, 
        @i_tran      = 7999,
        @i_tran_name = @w_sp_name,
        @i_cuenta    = @w_banco,
        @i_rollback  = 'S'
   
   return 1 
go
