/************************************************************************/
/*      Archivo:                act_tflexint.sp                         */
/*      Stored procedure:       sp_actualizar_tflexible_int             */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     May. 2014                               */
/*      Nro. procedure          9                                       */
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
/*      Establece un préstamo con tabla de amortización Flexible        */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-08-20     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/************************************************************************/  

use cob_cartera
go

--- SECCION:ERRORES no quitar esta seccion
--if not exists(select 1 from cobis..cl_errores where numero = 70009001)
--   insert into cobis..cl_errores values(70009001, 0, 'OCURRIÓ UN ERROR EN LA GENERACIÓN DE LA PORCION DE CAPITAL DEL PAGO FLEXIBLE')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_actualizar_tflexible_int')
   drop proc sp_actualizar_tflexible_int
go

---NR000392
create proc sp_actualizar_tflexible_int
   @s_user           login       = null,
   @s_date           datetime    = null,
   @s_term           varchar(30) = null,
   @s_ofi            smallint    = null,
   @s_sesn           int         = null,
   @i_debug          char(1)     = 'N',
   @i_banco          cuenta,
   @i_fecha_liq      datetime
as
declare
   @w_error                int,
   @w_operacion            int,
   @w_toperacion           catalogo,
   @w_moneda               smallint,
   @w_dia_fijo             smallint
begin
   if @i_debug = 'S'
      print 'Msg'

   select @w_toperacion = opt_toperacion, 
          @w_moneda     = opt_moneda,
          @w_dia_fijo   = isnull(opt_dia_fijo, datepart(DAY, @i_fecha_liq)),
          @w_operacion  = opt_operacion
   from   ca_operacion_tmp
   where  opt_banco = @i_banco

   delete ca_amortizacion_tmp where amt_operacion = @w_operacion
   delete ca_dividendo_tmp where dit_operacion = @w_operacion
   
   exec @w_error = sp_modificar_operacion_int
        @s_user                      = @s_user,
        @s_date                      = @s_date,
        @s_term                      = @s_term,
        @s_ofi                       = @s_ofi,   
        @s_sesn                      = @s_sesn,
        @i_calcular_tabla            = 'S',
        @i_banco                     = @i_banco,
        @i_toperacion                = @w_toperacion,
        @i_moneda                    = @w_moneda,
        @i_fecha_ini                 = @i_fecha_liq,
        @i_fecha_ult_proceso         = @i_fecha_liq,
        @i_fecha_liq                 = @i_fecha_liq,
        @i_dias_anio                 = 360,
        @i_tipo_amortizacion         = 'FLEXIBLE',
        @i_tplazo                    = 'D',
        @i_tdividendo                = 'Z',
        @i_periodo_cap               = 0,
        @i_periodo_int               = 0,
        @i_dist_gracia               = 'N',
        @i_gracia_cap                = 0,
        @i_gracia_int                = 0,
        @i_dia_fijo                  = @w_dia_fijo,
        @i_cuota                     = 0,
        @i_evitar_feriados           = 'S',
        @i_formato_fecha             = 101,
        @i_periodo_crecimiento       = 0,
        @i_tipo_crecimiento          = 'D', 
        @i_base_calculo              = 'E',     
        @i_ult_dia_habil             = 'N',    
        @i_recalcular                = 'N',       
        @i_causacion                 = 'L',     
        @i_mora_retroactiva          = 'S',
        @i_valida_param              = 'L',
        @i_simulacion_tflex          = 'S',
        @i_salida                    = 'N' 
   
   if @w_error != 0
      return @w_error

   exec @w_error = sp_pasodef
        @i_banco           = @i_banco,
        @i_operacionca     = 'S',
        @i_dividendo       = 'S',
        @i_amortizacion    = 'S',
        @i_cuota_adicional = 'S',
        @i_rubro_op        = 'S',
        @i_relacion_ptmo   = 'S',
        @i_nomina          = 'S',
        @i_acciones        = 'S',
        @i_valores         = 'S'
   
   if @w_error <> 0
   begin
      return @w_error
   end

   return 0
end
go


