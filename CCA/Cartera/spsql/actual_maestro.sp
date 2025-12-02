/************************************************************************/
/* Archivo:             actual_maestro.sp                               */
/* Stored procedure:    sp_actualiza_maestro                            */
/* Base de datos:       cob_cartera                                     */
/* Producto:            Cartera                                         */
/* Disenado por:        Ricardo Orjueja                                 */
/* Fecha de escritura:  28-Nov-2006                                     */
/************************************************************************/
/*                         IMPORTANTE                                   */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* 'MACOSA', representantes exclusivos para el Ecuador de la            */
/* 'NCR CORPORATION'.                                                   */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier alteracion o agregado hecho por alguno de sus              */
/* usuarios sin el debido consentimiento por escrito de la              */
/* Presidencia Ejecutiva de MACOSA o su representante.                  */
/*                         PROPOSITO                                    */
/* Proceso para administrar la tabla ca_operacion_total para ejecucion  */
/* de paralelismo del maestro de cartera.                               */
/************************************************************************/
/*                      MODIFICACIONES                                  */
/* FECHA          AUTOR       RAZON                                     */
/* 28/Nov/2006    R.Orjuela   Emision Inicial                           */
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_maestro')
   drop proc sp_actualiza_maestro
go

create proc sp_actualiza_maestro(
   @i_modo           smallint,
   @i_opcion         char(1)  = null,
   @i_fecha_ini      datetime = null,
   @i_fecha_fin      datetime = null
)
as
declare
   @w_sql             varchar(500),
   @w_fecha_sig       datetime,
   @w_fecha_proceso   datetime

-- CARGA TABLA DE TRABAJO CA_OPERACION_TOTAL
if @i_modo = 0
begin
   
   select @w_fecha_proceso = fc_fecha_cierre
   from cobis..ba_fecha_cierre 
   where fc_producto = 7
   
   delete ca_operacion_total WHERE opt_operacion >= 0
   
   insert into ca_operacion_total
   select @w_fecha_proceso, op_operacion, op_validacion, op_estado, op_tipo, null
   from   ca_operacion
   if @@error <> 0
   begin
      print 'Error En Insercion ca_operacion_total (0)'
      return @@error
   end

end

-- ACTUALIZA TABLA DE TRABAJO CA_OPERACION_TOTAL OPERACIONES A PROCESAR
if @i_modo = 1
begin
   -- Seleccionar TODAS
   if @i_opcion = 'N' 
   begin
      update ca_operacion_total
      set    opt_maestro = 'I'
      from   ca_operacion_total
      where  opt_estado in (1, 2, 4, 9)
      
      while @i_fecha_ini <= @i_fecha_fin
      begin
         select @w_fecha_sig = dateadd(ss,-1,(dateadd(dd,1,@i_fecha_ini)))
         
         select @w_sql = 'update ca_operacion_total set opt_maestro = "I" 
                          from cob_cartera..ca_transaccion, cob_cartera..ca_operacion_total
                          where opt_operacion = tr_operacion  and opt_estado in (3, 6, 99, 0)
                           and  tr_fecha_mov  between ' + convert(varchar,@i_fecha_ini) + '" and  "' + convert(varchar,@w_fecha_sig)  + '"
                           and  tr_tran is not null and  tr_ofi_usu > 0"'
         exec (@w_sql)
         if @@error <> 0
         begin
            print 'Error En Actualizacion ca_operacion_total (1)'
            return @@error
         end
         
         select @w_sql = 'update ca_operacion_total set opt_maestro = "I" 
                          from cob_cartera_depuracion..ca_transaccion, cob_cartera..ca_operacion_total
                          where opt_operacion = tr_operacion  and opt_estado in (3, 6, 99, 0)
                          and tr_fecha_mov between ' + convert(varchar,@i_fecha_ini) + '" and "' + convert(varchar,@w_fecha_sig)  + '"'
         exec (@w_sql)
         if @@error <> 0
         begin
            print 'Error En Actualizacion ca_operacion_total (2)'
            return @@error
         end
	
         select @i_fecha_ini = dateadd(dd,1,@i_fecha_ini)
      end
   end
   else
   -- Seleccionar SOLO ACTIVAS
   begin
      update ca_operacion_total
      set    opt_maestro = 'I'
      from   ca_operacion_total
      where  opt_estado in (1, 2, 4, 9)
      and    opt_tipo != 'R'

      while @i_fecha_ini <= @i_fecha_fin
      begin
         select @w_fecha_sig = dateadd(ss,-1,(dateadd(dd,1,@i_fecha_ini)))
         
         select @w_sql = 'update ca_operacion_total set opt_maestro = "I" 
                          from cob_cartera..ca_transaccion, cob_cartera..ca_operacion_total
                          where opt_operacion = tr_operacion  and opt_estado in (3, 6, 99, 0) and opt_tipo != "R"
                           and  tr_fecha_mov  between ' + convert(varchar,@i_fecha_ini) + '" and  "' + convert(varchar,@w_fecha_sig)  + '"and  tr_tran is not null and  tr_ofi_usu > 0"'
         exec (@w_sql)
         if @@error <> 0
         begin
            print 'Error En Actualizacion ca_operacion_total (3)'
            return @@error
         end
         
         -- SE INCLUYO:  and    opt_tipo != 'R' (MODULO DE OPTIMIZACION POR CONSULTA A FABIAN QUINTERO DIC 19/2006)
         select @w_sql = 'update ca_operacion_total set opt_maestro = "I" 
                          from cob_cartera_depuracion..ca_transaccion, cob_cartera..ca_operacion_total
                          where opt_operacion = tr_operacion  and opt_estado in (3, 6, 99, 0) and opt_tipo != "R"
                          and  tr_fecha_mov  between ' + convert(varchar,@i_fecha_ini) + '" and  "' + convert(varchar,@w_fecha_sig)  + '"'
         exec (@w_sql)
         if @@error <> 0
         begin
            print 'Error En Actualizacion ca_operacion_total (4)'
            return @@error
         end

         select @i_fecha_ini = dateadd(dd,1,@i_fecha_ini)
      end

   end
end
return 0
go

