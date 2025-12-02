/************************************************************************/
/*  Archivo:                trn_cj_pag_mora.sp                          */
/*  Stored procedure:       sp_trn_cj_pag_mora                          */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_trn_cj_pag_mora')
    drop proc sp_trn_cj_pag_mora
go

create proc sp_trn_cj_pag_mora(
@s_date            datetime    = null,
@s_user            login       = null,
@i_operacion       char(1)     = null,
@i_tramite         int         = null,
@i_banco           cuenta      = null,
@i_cca             char(1)     = 'N'
)
as

declare
@w_error                int,
@w_sp_name              varchar (50),
@w_cerror               char(1),
@w_msg                  varchar(100),
@w_commit               char(1),
@w_causal               catalogo,
@w_num_orden            int,           --NUMERO ORDEN GENERADA DESDE CAJAS
@w_saldo_a_pagar        money,
@w_saldo_ant            money,
@w_orden                int,
@w_cliente              int,
@w_banco                cuenta,
@w_estado_pag           catalogo,       --ESTADO DEL PAGO EN CAJAS
@w_tramite              int


select
@w_sp_name = 'sp_trn_cj_pag_mora',
@w_causal  = '055',
@w_cerror  = 'N',
@w_commit  = 'N'

if @i_banco is null begin --VIENE DE CARTERA
   select
   @w_cliente = tr_cliente,
   @w_banco   = tr_numero_op_banco,
   @w_tramite = tr_tramite
   from  cr_tramite
   where tr_tramite = @i_tramite
   
   if @@rowcount = 0
   begin
      select
      @w_error = 2103001,
      @w_msg   = 'ERROR AL OBTENER EL TRAMITE DE NORMALIZACION POR NUMERO DE TRAMITE'
      goto ERROR
   end
      
end else begin

   ---Sacar el maximo tramite primero porque pueden haber varias Normalizacion para la misma operacion
   select   @w_tramite = max(tr_tramite)
   from  cr_tramite
   where tr_tipo   = 'M' --NORMALIZACION
   and   tr_estado = 'A' --APLICADO
   and   tr_grupo  = 1   --HERRAMIENTA PRORROGA DE FECHA
   and   tr_numero_op_banco = @i_banco
   
   if @w_tramite is null
   begin
      select
      @w_error = 2103001,
      @w_msg   = 'ERROR AL OBTENER EL TRAMITE DE NORMALIZACION POR NUMERO DE OPERACION'
      goto ERROR
   end
       
   select
   @w_cliente = tr_cliente,
   @w_banco   = tr_numero_op_banco
   from  cr_tramite
   where tr_tramite = @w_tramite
   
   if @@rowcount = 0
   begin
      select
      @w_error = 2103001,
      @w_msg   = 'ERROR AL OBTENER EL CLIENTE'
      goto ERROR
   end

end

--------------------------------------------------------------------------------------------------
--OPERACION 'I'--> INSERTA LA TRANSACCION DE ABONO PARA NORMALIZACION PRORROGA DE FECHA
--------------------------------------------------------------------------------------------------

if @i_operacion = 'I'
begin

   if @@trancount = 0 begin
      begin tran
      select @w_commit  = 'S'
   end

select @w_saldo_a_pagar = 0
   --CONSULTO EL SALDO A PAGAR PARA GENERAR LA ORDEN DE PAGO
   exec @w_error =  cob_cartera..sp_pagomora
   @i_banco          = @w_banco,
   @i_opcion         = 'S',          --CONSULTA SALDOS RUBROS TIPO MORA
   @o_monto          = @w_saldo_a_pagar out

   if @w_error <> 0 goto ERROR
   
   if @w_saldo_a_pagar = 0 begin
      if @w_commit = 'S' begin
         commit tran
         select @w_commit = 'N'
      end
      return 0
   end
   
   /* SI EXISTE EL PAGO */
   select @w_estado_pag = ''

   select 
   @w_estado_pag = tc_estado,
   @w_saldo_ant  = tc_valor
   from   cob_credito..cr_tramite_cajas
   where  tc_tramite    = @w_tramite
   and    tc_causa      = @w_causal
   and    tc_pago_cobro = 'C'

   --SI EL VALOR DEL SALDO A PAGAR ES IGUAL A LA ORDEN INGRESADA NO REINGRESA ORDEN
   if @w_estado_pag = 'I' and @w_saldo_ant = @w_saldo_a_pagar begin
      print 'EXISTE ORDEN DE PAGO POR UN VALOR DE $'+convert(varchar, @w_saldo_a_pagar, 1)
      select @w_error = 2108025
      goto ERROR
   end

   --SI EXISTE EL PAGO Y ESTA INGRESADO ANULO EL PAGO
   if @w_estado_pag = 'I' begin
      exec @w_error = sp_trn_cj_pag_mora
      @s_date         = @s_date,
      @s_user         = @s_user,
      @i_operacion    = 'R',
      @i_tramite      = @w_tramite

      if @w_error <> 0 goto ERROR
   end

   --SI ESTA INGRESADO O EJECUTADO PERO CON UN SALDO GENERO LA ORDEN POR EL SALDO PENDIENTE DE PAGO
   exec @w_error    = cob_remesas..sp_genera_orden
   @s_date      = @s_date,             --> Fecha de proceso
   @s_user      = @s_user,             --> Usuario
   @i_operacion = 'I',                 --> Operacion ('I' -> Insercion, 'A' Anulacion)
   @i_causa     = @w_causal,           --> Causal de Egreso(cc_causa_oioe)
   @i_ente      = @w_cliente,          --> Cod ente,
   @i_valor     = @w_saldo_a_pagar,    --> Valor,
   @i_tipo      = 'C',                 --> 'C' -> Orden de Cobro/Ingreso, 'P' -> Orden de Pago/Egreso
   @i_idorden   = null,                --> Cod Orden cuando operacion 'A',
   @i_ref1      = @w_tramite ,         --> Ref. Numerica no oblicatoria
   @i_ref2      = @w_cliente ,         --> Ref. Numerica no oblicatoria
   @i_ref3      = '',                  --> Ref. AlfaNumerica no oblicatoria
   @i_interfaz  ='N',                  --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve cod error
   @o_idorden   = @w_num_orden out     --> Devuelve cod orden de pago/cobro generada - Operacion 'I'

   if @w_error <> 0 begin
      select @w_cerror = 'S'
      goto ERROR
   end else begin
      insert into cob_credito..cr_tramite_cajas (
      tc_tramite, tc_num_orden, tc_valor,
      tc_causa,   tc_estado,    tc_pago_cobro)
      values (
      @w_tramite, @w_num_orden, @w_saldo_a_pagar,
      @w_causal,  'I',          'C') --I:Ingresado C:Cobro

      if @@error <> 0
      begin
         select
         @w_error = 2103001,
         @w_msg   = 'ERROR AL INSERTAR EN cob_credito..cr_tramite_cajas'
         goto ERROR
      end
   end 

   if @w_commit = 'S'
   begin
      commit tran
      select @w_commit = 'N'
   end
   print 'SE HA INGRESADO UNA ORDEN DE PAGO POR UN VALOR DE $'+convert(varchar, @w_saldo_a_pagar, 1)
   if @i_cca = 'S'  --SE LLAMA DESDE CARTERA
      return 2108025
   else 
      return 0 
end

---------------------------------------------------------------------------------------------------------
--OPERACION 'R'--> SE RECHAZA EL TRAMITE O DE DEBE REINGRESAR EL PAGO POR EL NUEVO VALOR 
--ENTONCES SE ANULA LA TRANSACCION EN CAJAS Y EN CR_TRAMITE_CAJAS
----------------------------------------------------------------------------------------------------------
if @i_operacion = 'R'
begin
   select @w_orden = tc_num_orden
   from   cob_credito..cr_tramite_cajas
   where  tc_tramite    = @w_tramite
   and    tc_causa      = @w_causal
   and    tc_pago_cobro = 'C'
   and    tc_estado     = 'I'

   if @@rowcount = 0 return 0
      
   exec @w_error    = cob_remesas..sp_genera_orden
   @s_date           = @s_date,             --> Fecha de proceso
   @s_user           = @s_user,             --> Usuario
   @i_operacion      = 'A',                 --> Operacion ('I' -> Insercion, 'A' Anulacion)
   @i_causa          = @w_causal,           --> Causal de Ingreso(cc_causa_oioe)
   @i_ente           = @w_cliente,          --> Cod ente,
   @i_valor          = @w_saldo_a_pagar,    --> Valor,
   @i_tipo           = 'C',                 --> 'C' -> Orden de Cobro/Ingreso, 'P' -> Orden de Pago/Egreso
   @i_idorden        = @w_orden,            --> Cod Orden cuando operacion 'A',
   @i_ref1           = @w_tramite ,         --> Ref. Numerica no oblicatoria
   @i_ref2           = @w_cliente,          --> Ref. Numerica no oblicatoria
   @i_ref3           = '',                  --> Ref. AlfaNumerica no oblicatoria
   @i_interfaz       ='N',                  --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve cod error
   @o_idorden        = @w_num_orden out     --> Devuelve cod orden de pago/cobro generada - Operacion 'I'

   if @@error <> 0 or @w_error <> 0 begin
      select @w_cerror = 'S'
      goto ERROR
   end else begin
      update cob_credito..cr_tramite_cajas set
      tc_estado       = 'A' --A: Anulado
      where tc_tramite    = @w_tramite
      and   tc_num_orden  = @w_orden
      and   tc_causa      = @w_causal
      and   tc_pago_cobro = 'C' --C: Cobro
      and   tc_estado     = 'I' --I: Ingresado

      if @@error <>  0
      begin
         select
         @w_error = 2103001,
         @w_msg   = 'ERROR AL ACTUALIZAR TABLA cr_tramite_cajas'
         goto ERROR
      end
   end
end


return 0

ERROR:

select @w_error = isnull(@w_error, 708201)

if @w_commit = 'S'
begin
   rollback
   select @w_commit = 'N'
end

if @w_msg is null
begin
   select @w_msg = mensaje
   from cobis..cl_errores
   where numero = @w_error
end

--SI NO SE HA EJECUTADO EL SP_CERROR LO EJECUTO
if @w_cerror = 'N' begin
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg
end

return @w_error

GO
