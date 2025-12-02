/************************************************************************/
/*      Archivo:                actsalfon.sp                            */
/*      Stored procedure:       sp_actualiza_saldo_fondo                */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Mayo 2008                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Actualiza el saldo de los fondos de recursos por desembolsos y  */
/*      abonos a capital, tanto para aplicaciones como para reversa     */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*      FECHA           AUTOR             RAZON                         */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_actualiza_saldo_fondo')
   drop proc sp_actualiza_saldo_fondo
go

create proc sp_actualiza_saldo_fondo
    @s_user             login   = null,
    @i_operacion        char(1) = null,
    @i_modo             char(1) = null,
    @i_operacionca      int     = null,
    @i_valor            money   = null

as

declare
    @w_sp_name              varchar(30),
    @w_return               int,
    @w_error                int,
    @w_rowcount             int,
    @w_banco                cuenta,
    @w_cliente              int,
    @w_oficial              smallint,
    @w_tramite              int,
    @w_valor                money,
    @w_fuente_recurso       varchar(10),
    @w_monto_prestamo       money,
    @w_op_naturaleza        char(1),
    @w_saldo                money,
    @w_monto                money,
    @w_utilizado            money,
    @w_tipo_fuente          char(1),
    @w_porcentaje_otorgado  float,
    @w_fecha_ult_proc       datetime, 
    @w_op_estado            tinyint

  

/* INICIALIZACION VARIABLES */
select
    @w_sp_name        = 'sp_actualiza_saldo_fondo'

/* OPCIONES DE PROCESO */
select  @w_op_naturaleza = op_naturaleza
from    cob_cartera..ca_operacion
where   op_operacion = @i_operacionca

if @w_op_naturaleza = 'A'
begin
   select
   @w_banco          = op_banco,
   @w_tramite        = op_tramite,
   @w_cliente        = op_cliente,
   @w_oficial        = op_oficial,
   @w_fuente_recurso = tr_fuente_recurso,  ---isnull(op_origen_fondos,1),    --isnull(tr_fuente_recurso,'1'),
   @w_monto_prestamo = op_monto, 
   @w_fecha_ult_proc = op_fecha_ult_proceso, 
   @w_op_estado      = op_estado
   from cob_cartera..ca_operacion, cob_credito..cr_tramite
   where op_operacion = @i_operacionca
   and op_tramite   = tr_tramite

   if @@rowcount = 0
   begin      
      -- INI JAR REQ 246
      if exists (select 1 from ca_op_reest_padre_hija 
                  where ph_op_hija = @i_operacionca)
      begin
         select @i_operacionca = @i_operacionca
      end
      else print 'No existe tramite para la operacion'
      -- INI JAR REQ 246            
      return 0
      --select @w_error = 701187  --No existe tramite para la operacion
      --return @w_error
   end
   else
   begin
      if not exists (select 1 from cob_credito..cr_fuente_recurso
                     where fr_fuente =  @w_fuente_recurso)
      begin
         print 'El codigo de la fuente de recurso no existe en tabla de parametrizacion ' +  @w_fuente_recurso
         return 0
      end

      if @w_fuente_recurso is null or @w_fuente_recurso = ''
      begin
         print 'Operacion no tiene fuente de recursos'
         return 0
      end

      --select @w_valor = case when @i_operacion = 'D' then @w_monto_prestamo else @i_valor end
      if @i_operacion = 'D'
         select @w_valor = @w_monto_prestamo
      else
         select @w_valor = @i_valor
		
      exec @w_error = cob_credito..sp_actualiza_resal_fuente
      @s_user             = @s_user,
      @i_fuente_recurso   = @w_fuente_recurso,
      @i_modo             = @i_modo,
      @i_valor            = @w_valor,
      @i_operacion        = @i_operacion,
      @i_tramite          = @w_tramite,
      @i_banco            = @w_banco

      if @@error <> 0 and @w_error <> 0 begin
          select @w_error = 710002 --Error en la actualizacion del registro
          return @w_error
      end
      
      /*
      else
      begin

            
         /* ACTUALIZACION DE SALDOS INTERFAZ PALM */
         execute @w_error = cob_palm..sp_interfaz_palm_pda2
         @s_user             = @s_user,
         @t_trn              = null,
         @i_modo             = @i_modo,
         @i_operacion        = @i_operacion,
         @i_banco            = @w_banco,
         @i_tramite          = @w_tramite,
         @i_cliente          = @w_cliente,
         @i_oficial          = @w_oficial,         
         @i_batch            = 'N',
         @i_operacionca      = @i_operacionca,   -- FCP numero interno dela operacion   
         @i_monto            = @w_valor,         -- FCP valor del pago o del desembolso
         @i_op_estado        = @w_op_estado,     -- FCP Estado de la operacion despues del Pago/desembolso. 
         @i_fecha_proceso    = @w_fecha_ult_proc -- FCP fecha de proceso del pago.
         if @w_error != 0
            return @w_error
      end
     */ 
   end
end


return 0
go