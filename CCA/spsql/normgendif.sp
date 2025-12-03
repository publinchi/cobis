/************************************************************************/
/*   Archivo:             normgendif.sp                                 */
/*   Stored procedure:    sp_norm_genera_diferidos                      */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Fabian Gregorio Quintero De La Espriella      */
/*   Fecha de escritura:  2014/11                                       */
/*   Nro. de SP        :  13                                            */
/************************************************************************/
/*            IMPORTANTE						                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Realiza la generacion de diferidos para normalizaciones nuevas     */
/************************************************************************/
/*            MODIFICACIONES                                            */
/*    FECHA       AUTOR       CAMBIO                                    */
/*   2014-11-05   F.Quintero  Req436:Normalizacion Cartera              */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_norm_genera_diferidos')
   drop proc sp_norm_genera_diferidos
go

create proc sp_norm_genera_diferidos
@s_date              datetime,
@i_tramite           int,
@i_cotizacion_dia    float,
@i_secuencial_des    int
as
declare
   @w_error          int,
   @w_op_estado      int,
   @w_op_operacion   int,
   @w_est_diferido   tinyint,
   @w_est_suspenso   tinyint,
   @w_est_castigado  tinyint
begin
   exec @w_error = sp_estados_cca
        @o_est_suspenso   = @w_est_suspenso    OUT,
        @o_est_diferido   = @w_est_diferido    OUT,
        @o_est_castigado  = @w_est_castigado   OUT

   if @w_error <> 0
      return @w_error

   select @w_op_operacion  = op_operacion,
          @w_op_estado     = op_estado
   from   ca_operacion
   where  op_tramite = @i_tramite

   if @@ROWCOUNT = 0
      return 70012001 -- LA NUEVA OPERACION NO SE ENCUENTRA

   if @w_op_estado <> 1
   begin
      return 70012002 -- ESTADO NO VALIDO DE LA OPERACION NUEVA
   end

   -- BUSCAR LAS TRASACCIONES DE PAGO
   select tr_operacion,                      -- LA OPERACION NORMALIZADA
          tr_secuencial = max(tr_secuencial) -- LA ULTIMA TRANSACCION DE PAGO
   into   #trans_pago
   from   cob_credito..cr_normalizacion,
          ca_operacion,
          ca_transaccion
   where  nm_tramite    = @i_tramite
   and    op_banco      = nm_operacion
   and    tr_operacion  = op_operacion
   and    tr_tran       = 'PAG' -- LA TRANSACCION CON LA QUE SE PAGO LA OBLIGACION
   and    tr_estado     = 'ING' -- Y ESTE RECIEN CREADA
   and    tr_fecha_mov  = @s_date -- DE ESTE MISO DIA
   group  by tr_operacion

   if not exists(select 1
                 from   #trans_pago)
   begin
      return 70012004-- NO HUBO PAGO PARA LAS OPERACIONES ANTERIORES
   end

   create table #diferidos
   (
      operacion      int,
      concepto       catalogo,
      total          money,
      pagado         money,
      codigo_valor   int
   )
       
   -- GUARDAR TEMPORALMENTE LOS DIFERIDOS; UNIFICANDOLOS EN LA OPERACION

   insert into #diferidos
   select operacion     = @w_op_operacion,
          concepto      = co_concepto,
          total         = isnull(sum(ar_monto),0),
          pagado        = 0.0,
          codigo_valor  = (co_codigo * 1000) + (@w_est_diferido * 10)
   from   #trans_pago,
          ca_abono_rubro,
          ca_concepto
   where  ar_operacion = tr_operacion
   and    ar_secuencial = tr_secuencial
   and    ar_estado     = @w_est_suspenso
   and    co_concepto   = ar_concepto
   and    co_categoria  <> 'C'
   and    ar_concepto not in (select c.codigo
                              from   cobis..cl_tabla t, cobis..cl_catalogo c
                              where  t.tabla = 'ca_rubros_no_diferidos'
                              and    c.tabla = t.codigo
                              and    c.estado = 'V')
   group by co_concepto, co_codigo

   -- SI YA TIENE DIFERIDOS
   if exists(select 1
             from   ca_diferidos
             where  dif_operacion = @w_op_operacion)
   begin -- UNIFICARLOS CON LOS QUE VIENEN DE LOAS PAGOS
      insert into #diferidos
            (operacion, concepto,      total,
             pagado,    codigo_valor)
      select dif_operacion,   dif_concepto,  dif_valor_total - dif_valor_pagado,
             0,         0
      from   ca_diferidos
      where  dif_operacion = @w_op_operacion

      delete ca_diferidos
      where  dif_operacion = @w_op_operacion
   end

   insert into ca_diferidos
         (dif_operacion,   dif_concepto,  dif_valor_total,     dif_valor_pagado)
   select operacion,       concepto,      sum(total-pagado),   0
   from   #diferidos
   group  by operacion, concepto

   /*
   -- CREAR EL REGISTRO CONTABLE EN EL DESEMBOLSO DE LOS DIFERIDOS QUE SE GENERARON
   insert ca_det_trn
         (dtr_secuencial,       dtr_operacion,       dtr_dividendo,
          dtr_concepto,         dtr_estado,          dtr_periodo,         
          dtr_codvalor,         dtr_monto,           dtr_monto_mn,        
          dtr_moneda,           dtr_cotizacion,      dtr_tcotizacion,     
          dtr_afectacion,       dtr_cuenta,          dtr_beneficiario,    
          dtr_monto_cont)
   select @i_secuencial_des,    @w_op_operacion,  1,
          concepto,             @w_est_diferido,     0,
          codigo_valor,         total,round(( total * @i_cotizacion_dia) ,0),
          0,                    @i_cotizacion_dia,    'N',
          'D',                  '',                   'TOTAL DIFERIDO',
          0
   from   #diferidos

   if @@error <> 0
   begin
      return 70012003 -- ERROR REGISTRANDO LOS DIFERIDOS
   end
   */
end
go


