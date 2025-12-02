/************************************************************************/
/*      Archivo:                verifica_tmps_defs.sp                   */
/*      Stored procedure:       sp_verifica_tmps_defs                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Kevin Rodríguez                         */
/*      Fecha de escritura:     Agosto 2022                             */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad       */
/*   de COBISCORP.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de COBISCORP.    */
/*   Este programa esta protegido por la ley de derechos de autor       */
/*   y por las convenciones  internacionales de propiedad intectual     */
/*   Su uso no autorizado dara derecho a COBISCORP para                 */
/*   obtener ordenes de secuestro o retencion y para perseguir          */
/*   penalmente a los autores de cualquier infraccion.                  */
/************************************************************************/  
/*                              PROPOSITO                               */
/*   Verifica que existan registros de las operaciones temporales o     */
/*   definitivas antes de hacer el intercambio de información           */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      Kevin Rodriguez     16/Ago/2022    R-191711 Emisión inicial     */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_verifica_tmps_defs')
	drop proc sp_verifica_tmps_defs
go
create proc sp_verifica_tmps_defs
@i_banco		    cuenta  = null,
@i_operacionca		char(1) = null,
@i_dividendo		char(1) = null,
@i_amortizacion		char(1) = null,
@i_rubro_op		    char(1) = null,
@i_opcion           char(1) = null  -- D: Tablas Definitivas, T: Tablas Temporales

as
declare 
@w_operacionca	int ,
@w_count_regs   int

select @w_count_regs = 0


-- Con opción T, comprueba la existencia de registros en las tablas temporales de Cartera,
-- y con opción D, comprueba la existencia de registros en las tablas definitivas de Cartera

if @i_opcion = 'D'
begin
   
   select 
   @w_operacionca = op_operacion
   from   ca_operacion
   where  op_banco = @i_banco 
   
   if @@ROWCOUNT = 0
      return 701049 -- No existe Operación

   if @i_operacionca = 'S' begin
   
      select @w_count_regs = count(1) from ca_operacion
      where  op_operacion = @w_operacionca
     
      if @w_count_regs = 0
         return 725174 -- La tabla ca_operacion no tiene registros para copiar a la tabla temporal
	  
      select @w_count_regs = count(1) from ca_operacion_datos_adicionales
      where  oda_operacion = @w_operacionca
     
      if @w_count_regs = 0
         return 725175 -- La tabla ca_operacion_datos_adicionales no tiene registros para copiar a la tabla temporal
   
   end
   
   
   if @i_dividendo = 'S' begin
   
      select @w_count_regs = count(1) from ca_dividendo
      where  di_operacion = @w_operacionca
	  
      if @w_count_regs = 0
         return 725176  -- La tabla ca_dividendo no tiene registros para copiar a la tabla temporal
   
   end
   
   if @i_amortizacion = 'S'
   begin
 
      select @w_count_regs = count(1) from ca_amortizacion
      where  am_operacion = @w_operacionca
	  
      if @w_count_regs = 0
         return 725177 -- La tabla ca_amortizacion no tiene registros para copiar a la tabla temporal

   end            
   
   if @i_rubro_op = 'S'
   begin
   
      select @w_count_regs = count(1) from ca_rubro_op
      where  ro_operacion = @w_operacionca
	  
      if @w_count_regs = 0
         return 725178 -- La tabla ca_rubro_op no tiene registros para copiar a la tabla temporal
   
   end

 
end

if @i_opcion = 'T'
begin

   select 
   @w_operacionca = opt_operacion
   from   ca_operacion_tmp
   where  opt_banco = @i_banco
   
   if @@ROWCOUNT = 0
   return 701050 -- No existe Operación Temporal

   if @i_operacionca = 'S' begin
   
      select @w_count_regs = count(1) from ca_operacion_tmp
      where  opt_operacion = @w_operacionca
     
      if @w_count_regs = 0
         return 725179 -- La tabla ca_operacion_tmp no tiene registros para copiar a la tabla definitiva
	  
      select @w_count_regs = count(1) from ca_operacion_datos_adicionales_tmp
      where  odt_operacion = @w_operacionca
     
      if @w_count_regs = 0
         return 725180 -- La tabla ca_operacion_datos_adicionales_tmp no tiene registros para copiar a la tabla definitiva
   
   end
   
   
   if @i_dividendo = 'S' begin
   
      select @w_count_regs = count(1) from ca_dividendo_tmp
      where  dit_operacion = @w_operacionca
	  
      if @w_count_regs = 0
         return 725181 -- La tabla ca_dividendo_tmp no tiene registros para copiar a la tabla definitiva
   
   end
   
   if @i_amortizacion = 'S'
   begin
 
      select @w_count_regs = count(1) from ca_amortizacion_tmp
      where  amt_operacion = @w_operacionca
	  
      if @w_count_regs = 0
         return 725182 -- La tabla ca_amortizacion_tmp no tiene registros para copiar a la tabla definitiva

   end            
   
   if @i_rubro_op = 'S'
   begin
   
      select @w_count_regs = count(1) from ca_rubro_op_tmp
      where  rot_operacion = @w_operacionca
	  
      if @w_count_regs = 0
         return 725183 -- La tabla ca_rubro_op_tmp no tiene registros para copiar a la tabla definitiva
   
   end

end

return 0

go

