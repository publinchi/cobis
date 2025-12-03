/************************************************************************/
/*   Archivo:              impinttras.sp                                */
/*   Stored procedure:     sp_imprimir_inttras                          */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Fabian Quintero                              */
/*   Fecha de escritura:   2014-10-07                                   */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta para imprimir la tabla de amortizacion y en caso de la    */
/* simulacion  solamente es una opcion mas.                             */
/*                         MODIFICACIONES                               */
/*  FECHA      AUTOR      RAZON                                         */
/*  2014-10-07 Fabian Q.   Calculo de inttras para impresion            */
/************************************************************************/

use cob_cartera
go

if object_id('sp_imprimir_inttras') is not null
   drop proc sp_imprimir_inttras
go

create proc sp_imprimir_inttras
@i_operacion      int,
@i_user           login
as
declare
   @w_error             int,
   @w_fecha             datetime,
   @w_ult_dividendo     smallint,
   @w_di_dividendo      smallint,
   @w_di_estado         tinyint,
   @w_valor_disponible  money,
   @w_valor_conceptos   money,
   @w_inttras_cuota     money,
   @w_inttras_viene     money
begin
   select @w_fecha = getdate()

   delete tmp_tflexible_inttras
   where  tfi_user = @i_user

   -- ELIMINAR LOS DATOS DE LA OPERACION QUE TENGA MAS DE 15 MINUTOS DE HABERLO GENERADO
   select @w_ult_dividendo = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @i_operacion

   -- ELIMINAR LOS DATOS DE CUALQUIER OPERACION QUE TENGA MAS DE 12 HORAS DE HABERSE GENERADO
   delete tmp_tflexible_inttras
   where  tfi_hora < DATEADD(HOUR, -12, @w_fecha)

   select @w_inttras_viene = 0

   declare
      cur_dividendos cursor
      for select di_dividendo, di_estado
          from   ca_dividendo (nolock)
          where  di_operacion = @i_operacion
          order  by di_dividendo

   open cur_dividendos

   fetch cur_dividendos
   into  @w_di_dividendo, @w_di_estado

   while @@FETCH_STATUS = 0
   begin
      select @w_inttras_cuota = 0,
             @w_valor_disponible = 0

      -- CUANTO TIENE DISPONIBLE
      select @w_valor_disponible = dt_valor_disponible
      from   cob_credito..cr_disponibles_tramite
      where  dt_operacion_cca = @i_operacion
      and    dt_dividendo     = @w_di_dividendo

      if @w_di_estado in (0, 1)
      begin
         -- CONSULTAR CUANTO VALE LA CUOTA ACTUAL
         select @w_valor_conceptos = isnull(sum(am_cuota), 0) + isnull(@w_inttras_viene, 0)
         from   ca_amortizacion
                inner join ca_rubro_op on ro_operacion = @i_operacion and ro_concepto = am_concepto
         where  am_operacion = @i_operacion
         and    am_dividendo = @w_di_dividendo
         and    ro_tipo_rubro not in ('C', 'M')

         -- SI EL VALOR DE LOS CONCEPTOS (INCLUIDO EL TRASLADADO ANTERIOR) SUPERA EL DISPONIBLE ENTONCES HAY INTERES TRASLADADO
         if @w_valor_conceptos > @w_valor_disponible
            select @w_inttras_cuota = @w_valor_conceptos - @w_valor_disponible

         -- print 'actual: ' + convert(varchar, @w_di_dividendo) + '  ' + convert(varchar, @w_valor_conceptos) + ' ' + convert(varchar, @w_valor_disponible) + '  pendiente ' + convert(varchar, @w_inttras_cuota)
         
         select @w_inttras_cuota = isnull(@w_inttras_cuota, 0)

         if  @w_di_dividendo = @w_ult_dividendo
         begin
            select @w_valor_disponible = isnull(sum(am_cuota), 0) + @w_inttras_viene
            from   ca_amortizacion
            where  am_operacion = @i_operacion
            and    am_dividendo = @w_di_dividendo
         end

         insert into tmp_tflexible_inttras
               (tfi_user,  tfi_operacion,   tfi_dividendo,    tfi_hora,   tfi_inttras_cta,  tfi_vr_disponible)
         values(@i_user,   @i_operacion,    @w_di_dividendo,  @w_fecha,   @w_inttras_cuota, @w_valor_disponible)

         select @w_inttras_viene = @w_inttras_cuota
      end
      else
      begin
         insert into tmp_tflexible_inttras
                (tfi_user,  tfi_operacion,   tfi_dividendo,    tfi_hora,   tfi_inttras_cta,  tfi_vr_disponible)
         values (@i_user,   @i_operacion,    @w_di_dividendo,  @w_fecha,   0,                 @w_valor_disponible)
      end
      --
      fetch cur_dividendos
      into  @w_di_dividendo, @w_di_estado
   end

   close cur_dividendos
   deallocate cur_dividendos
   
   return 0
end
go

