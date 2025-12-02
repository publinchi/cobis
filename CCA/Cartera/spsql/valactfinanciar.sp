/************************************************************************/
/*      Archivo:                valactfinanciar.sp                      */
/*      Stored procedure:       sp_validar_act_financiar                */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     May. 2014                               */
/*      Nro. procedure          6                                       */
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
/*      Valida el pago de capital por año, segun actividad a financiar, */
/*      durante la generación de la tabla de amortización               */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-05-13     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/************************************************************************/  

use cob_cartera
go

--- SECCION:ERRORES no quitar esta seccion
delete cobis..cl_errores where numero between 70006001 and 70006999
go
   insert into cobis..cl_errores values(70006001, 0, 'No cumple condiciones: Flujo no alcanza para cubrir el capital requerido en el primer anio.')
   insert into cobis..cl_errores values(70006002, 0, 'No cumple condiciones: Flujo no alcanza para cubrir el capital requerido en el segundo anio')
   insert into cobis..cl_errores values(70006003, 0, 'No cumple condiciones: Flujo no alcanza para cubrir el capital requerido en el tercer anio.')
   insert into cobis..cl_errores values(70006004, 0, 'No cumple condiciones: Flujo no alcanza para cubrir el capital requerido en el cuarto anio.')
   insert into cobis..cl_errores values(70006005, 0, 'No cumple condiciones: Flujo no alcanza para cubrir el capital requerido en el quinto anio.')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_validar_act_financiar')
   drop proc sp_validar_act_financiar
go

---NR000392
create proc sp_validar_act_financiar
   @i_debug             char(1) = 'N',
   @i_operacionca       int,
   @i_destino           catalogo,
   @i_anio              tinyint
as
declare
   @w_saldo_cap            float,
   @w_cap_distribuido      float,
   @w_porcent_distribuido  float,
   @w_porcent_limite       float
begin
   if @i_debug = 'S'
      print 'DESTINO = ' + @i_destino

   if @i_destino = ''
      return 0

   -- CALCULAR EL MONTO DEL CAPITAL TOTAL
   select @w_saldo_cap    = sum(rot_valor)
   from   ca_rubro_op_tmp
   where  rot_operacion  = @i_operacionca
   and    rot_tipo_rubro = 'C'
   and    rot_fpago      in ('P','A','T') -- PERIODICO VENCIDO 

   if exists(select 1
             from   cobis..cl_parametro with (nolock)
             where  pa_producto = 'CCA'
             and    pa_nemonico = 'FXCTRA'
             and    pa_char     = @i_destino) -- SE VALIDA EL CAPITAL POR DESTINO CAPITAL DE TRABAJO
   begin
      if @i_debug = 'S'
         print 'VALIDACIONES CAPITAL DE TRABAJO'

      select @w_cap_distribuido = isnull(sum(amt_cuota), 0)
      from   ca_amortizacion_tmp
      inner  join ca_rubro_op on amt_operacion = ro_operacion and amt_concepto = ro_concepto
      where  ro_operacion = @i_operacionca
      and    ro_tipo_rubro = 'C'
      and    ro_fpago      in ('P','A','T') -- PERIODICO VENCIDO 

      select @w_porcent_distribuido = (@w_cap_distribuido * 100.0)/ @w_saldo_cap

      if  @i_anio = 1
      begin
         select @w_porcent_limite = pa_float
         from   cobis..cl_parametro
         where  pa_producto = 'CCA'
         and    pa_nemonico = 'FXCTR1'

      if @i_debug = 'S'
         print 'PORCENTAJE VALIDACION AÑO ' + convert(varchar, @w_porcent_distribuido)
            +  ', PORCENTAJE Limite ' + convert(varchar, @w_porcent_limite)
         if @w_porcent_distribuido < @w_porcent_limite
         begin
            return 70006001 -- (CAPITAL DE TRABAJO) DISPONIBLES NO ALCANZAN PARA PAGAR EL MINIMO DE CAPITAL DEL PRIMER ANIO
         end
      end
   end
   else -- SE VALIDA EL CAPITAL POR DESTINO INVERSION
   begin
      select @w_cap_distribuido = isnull(sum(amt_cuota), 0)
      from   ca_amortizacion_tmp
      inner  join ca_rubro_op on amt_operacion = ro_operacion and amt_concepto = ro_concepto
      where  ro_operacion = @i_operacionca
      and    ro_tipo_rubro = 'C'
      and    ro_fpago      in ('P','A','T') -- PERIODICO VENCIDO 

      select @w_porcent_distribuido = (@w_cap_distribuido * 100.0)/ @w_saldo_cap

      if  @i_anio = 2
      and @w_porcent_distribuido < (select pa_float
                                   from   cobis..cl_parametro
                                   where  pa_producto = 'CCA'
                                   and    pa_nemonico = 'FXINV2')
         return 70006002 -- (INVERSION) DISPONIBLES NO ALCANZAN PARA PAGAR EL MINIMO DE CAPITAL DEL SEGUNDO ANIO

      if  @i_anio = 3
      and @w_porcent_distribuido < (select pa_float
                                   from   cobis..cl_parametro
                                   where  pa_producto = 'CCA'
                                   and    pa_nemonico = 'FXINV3')
         return 70006003 -- (INVERSION) DISPONIBLES NO ALCANZAN PARA PAGAR EL MINIMO DE CAPITAL DEL TERCER ANIO

      if  @i_anio = 4
      and @w_porcent_distribuido < (select pa_float
                                   from   cobis..cl_parametro
                                   where  pa_producto = 'CCA'
                                   and    pa_nemonico = 'FXINV4')
         return 70006004 -- (INVERSION) DISPONIBLES NO ALCANZAN PARA PAGAR EL MINIMO DE CAPITAL DEL CUARTO ANIO

      if  @i_anio = 5
      and @w_porcent_distribuido < (select pa_float
                                   from   cobis..cl_parametro
                                   where  pa_producto = 'CCA'
                                   and    pa_nemonico = 'FXINV5')
         return 70006005 -- (INVERSION) DISPONIBLES NO ALCANZAN PARA PAGAR EL MINIMO DE CAPITAL DEL QUINTO ANIO
   end

   return 0
end
go
