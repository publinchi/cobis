/************************************************************************/
/*   Nombre Fisico:        cambperi.sp                                  */
/*   Nombre Logico:        sp_cambio_periodo                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*                             IMPORTANTE                               */
/*  Este programa es parte de los paquetes bancarios que son       		*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                               PROPOSITO                              */
/*      Nuevo periodo contable. Registra los valores pertenecientes     */
/*      al periodo anterior.                                            */
/*                              CAMBIOS                                 */
/*      FECHA         AUTOR         CAMBIO                              */
/*   FEB-14-2002      RRB           Agregar campos al insert            */
/*                                  en ca_transaccion                   */
/*   JUN-09-2010      EPB           Quitar Codigo Causacion Pasivas     */
/*   SEP-07-2022      KDR           R193404 Se comenta reg. de amort en */
/*                                  0 cuando el préstamo vencio en su   */
/*                                  totalidad                           */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*    18/08/2023     K. Rodriguez   Cambio período solo rubros vigentes */
/*                                  y vencidos                          */
/*    26/12/2023     K. Rodriguez   R222270 mantener pagado periodo ant.*/
/************************************************************************/ 
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_periodo')
   drop proc sp_cambio_periodo
go

create proc sp_cambio_periodo
(  @s_user             login,
   @s_term             varchar(30),
   @s_date             datetime,
   @s_ofi              smallint,
   @i_en_linea         char(1),
   @i_toperacion       catalogo,
   @i_banco            cuenta,
   @i_operacionca      int,
   @i_moneda           smallint,
   @i_oficina          smallint,
   @i_fecha_proceso    datetime
)

as
declare 
   @w_dividendo         int,
   @w_max_dividendo     int,
   @w_di_dividendo      int,
   @w_est_vigente       tinyint,
   @w_ro_concepto       catalogo,
   @w_am_estado         tinyint,
   @w_am_cuota          money,
   @w_am_acumulado      money,
   @w_am_pagado         money,
   @w_am_gracia         money,
   @w_am_cuota2         money,
   @w_am_pagado2        money,
   @w_am_gracia2        money,
   @w_am_secuencia      int,
   @w_secuencial        int,
   @w_return            int,
   @w_di_estado         tinyint,
   @w_est_vencido       tinyint,
   @w_est_suspenso      tinyint,
   @w_max_secuencia     int,
   @w_gerente           smallint,
   @w_gar_admisible     char(1), ---RRB:feb-14-2002 para ley 50
   @w_reestructuracion  char(1), ---RRB:feb-14-2002 para ley 50
   @w_calificacion      catalogo, ---RRB:feb-14-2002 para ley 50
   @w_fecha_ult_proceso datetime,
   @w_moneda_nacional   tinyint,
   @w_cotizacion        money,
   @w_op_moneda         tinyint,
   @w_est_cancelado     tinyint  --WLO_S676469


-- VARIABLES DE TRABAJO
select @w_dividendo = null

---ESTADOS DE LA CARTERA
exec @w_return   = sp_estados_cca
@o_est_vigente   = @w_est_vigente   out,
@o_est_vencido   = @w_est_vencido   out,
@o_est_suspenso  = @w_est_suspenso  out,
@o_est_cancelado = @w_est_cancelado out
--@o_est_castigado = @w_est_castigado out

if @w_return <> 0
   return @w_return


-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted


select @w_gerente           = op_oficial,
       @w_gar_admisible     = op_gar_admisible,    ---RRB:feb-14-2002 para ley 50
       @w_reestructuracion  = op_reestructuracion,   ---RRB:feb-14-2002 para ley 50
       @w_calificacion      = op_calificacion,      ---RRB:feb-14-2002 para ley 50
       @w_op_moneda         = op_moneda,
       @w_fecha_ult_proceso = op_fecha_ult_proceso
from   ca_operacion
where  op_operacion = @i_operacionca



/* DETERMINAR EL VALOR DE COTIZACION DEL DIA */
if @w_op_moneda = @w_moneda_nacional
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
        @i_moneda     = @w_op_moneda,
        @i_fecha      = @w_fecha_ult_proceso,
        @o_cotizacion = @w_cotizacion output
end

-- DETERMINAR DIVIDENDO VIGENTE
select @w_dividendo = di_dividendo
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_estado    = @w_est_vigente

select @w_max_dividendo = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @i_operacionca

select @w_dividendo = isnull(@w_dividendo,@w_max_dividendo+1)

if not exists (select 1
               from   ca_rubro_op, ca_dividendo, ca_amortizacion
               where  ro_operacion   = @i_operacionca
               and    ro_operacion   = di_operacion
               and    am_operacion   = ro_operacion
               and    am_estado      in (@w_est_vigente, @w_est_vencido)
               and    am_estado     <> @w_est_cancelado --WLO_S676469
               and    am_concepto    = ro_concepto
               and    am_dividendo   = di_dividendo
               and    am_periodo     = 0
               and    am_acumulado   > 0
               and    di_dividendo   <= @w_dividendo
               and    ro_provisiona  = 'S'
               and    ro_tipo_rubro <> 'M')
begin
   goto SALIR
end
   
-- INSERTAR TRANSACCION PARA MARCAR EL CAMBIO DE PERIODO
exec @w_secuencial = sp_gen_sec
     @i_operacion  = @i_operacionca

-- OBTENER RESPALDO ANTES DEL CAMBIO DE ESTADO
exec @w_return = sp_historial
     @i_operacionca    = @i_operacionca,
     @i_secuencial     = @w_secuencial

if @w_return != 0
   return @w_return

insert into ca_transaccion
      (tr_operacion,                    tr_secuencial,              tr_fecha_mov,
       tr_toperacion,
       tr_moneda,                       tr_tran,
       tr_en_linea,                     tr_banco,                   tr_dias_calc,
       tr_ofi_oper,                     tr_ofi_usu,                 tr_usuario,
       tr_terminal,                     tr_fecha_ref,               tr_secuencial_ref,
       tr_estado,                       tr_gerente,
       tr_gar_admisible,   ---RRB:feb-14-2002 para ley 50
       tr_reestructuracion,
       tr_calificacion,    ---RRB:feb-14-2002 para ley 50
       tr_observacion,                  tr_fecha_cont,              tr_comprobante)
values (@i_operacionca,                 @w_secuencial,              @s_date,
        @i_toperacion,
        @i_moneda,                      'CPC',
        @i_en_linea,                    @i_banco,                   1,
        @i_oficina,                     @s_ofi,                     @s_user,
        @s_term,                        @w_fecha_ult_proceso,           0,
        'ING',                          @w_gerente,
        isnull(@w_gar_admisible,''),   ---RRB:feb-14-2002 para ley 50
        isnull(@w_reestructuracion,''),
        isnull(@w_calificacion,''),   ---RRB:feb-14-2002 para ley 50
        '',                             @s_date,                    0)

if @@error != 0
   return 708165

-- INSERTAR REGISTROS CON PERIODO CERO PARA NUEVAS PROVISIONES
declare dividir cursor for 
   select di_dividendo, ro_concepto, am_estado, am_secuencia
   from   ca_rubro_op, ca_dividendo, ca_amortizacion
   where  ro_operacion   = @i_operacionca
   and    ro_operacion   = di_operacion
   and    am_operacion   = ro_operacion
   and    am_estado      in (@w_est_vigente, @w_est_vencido)
   and    am_estado     <> @w_est_cancelado --WLO_S676469
   and    am_concepto    = ro_concepto
   and    am_dividendo   = di_dividendo
   and    am_periodo     = 0
   and    am_acumulado   > 0
   and    di_dividendo   <= @w_dividendo
   and    ro_provisiona  = 'S'
   and    ro_tipo_rubro <> 'M'
   order  by di_dividendo, ro_concepto, am_estado, am_secuencia
   for read only

open dividir

fetch dividir
into  @w_di_dividendo, @w_ro_concepto, @w_am_estado, @w_am_secuencia

while @@fetch_status = 0
begin
   if (@@fetch_status = -1)
      return 710004
   
   --PRINT 'cambiperi.sp enel cursor de @w_di_dividendo ' + cast(@w_di_dividendo as varchar)
   
   select @w_di_estado = di_estado
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_dividendo = @w_di_dividendo
   
   select @w_am_cuota     = am_cuota,
          @w_am_acumulado = am_acumulado,
          @w_am_pagado    = am_pagado,
          @w_am_gracia    = am_gracia
   from   ca_amortizacion
   where  am_operacion = @i_operacionca
   and    am_dividendo = @w_di_dividendo
   and    am_concepto  = @w_ro_concepto
   and    am_estado    = @w_am_estado
   and    am_secuencia = @w_am_secuencia
   
   if @w_am_cuota       > @w_am_acumulado
      select @w_am_cuota2 = @w_am_cuota - @w_am_acumulado
   else
      select @w_am_cuota2 = @w_am_cuota
   
   if @w_am_pagado      > @w_am_acumulado
      select @w_am_pagado2 = @w_am_pagado - @w_am_acumulado
   else
      select @w_am_pagado2 = 0
   
   if @w_am_gracia      > @w_am_acumulado
      select @w_am_gracia2 = @w_am_gracia - @w_am_acumulado
   else
      select @w_am_gracia2 = @w_am_gracia
   
   select @w_am_cuota      = @w_am_cuota       - @w_am_cuota2
   select @w_am_pagado     = @w_am_pagado      - @w_am_pagado2
   select @w_am_gracia     = @w_am_gracia      - @w_am_gracia2
   
   update ca_amortizacion
   set    am_periodo = 1
   where  am_operacion = @i_operacionca
   and    am_dividendo = @w_di_dividendo
   and    am_concepto  = @w_ro_concepto
   and    am_estado    = @w_am_estado
   and    am_secuencia = @w_am_secuencia
   
   if @@error <> 0
      return 710002
   
   if (@w_am_cuota>0) or (@w_di_dividendo = @w_max_dividendo and
                          @w_di_estado = @w_est_vencido)
   begin
      if @w_am_cuota > 0
      begin
         update ca_amortizacion
         set    am_cuota  = @w_am_cuota,
                am_pagado = @w_am_pagado,
                am_gracia = @w_am_gracia
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_di_dividendo
         and    am_concepto  = @w_ro_concepto
         and    am_estado    = @w_am_estado
         and    am_secuencia = @w_am_secuencia
         
         if @@error <> 0
            return 710002
         
         insert into ca_amortizacion
               (am_operacion,      am_dividendo,      am_concepto,
                am_estado,         am_periodo,        am_cuota,
                am_gracia,         am_pagado,         am_acumulado,
                am_secuencia )
         values(@i_operacionca,    @w_di_dividendo,   @w_ro_concepto,
                @w_am_estado,      0,                 @w_am_cuota2,
                @w_am_gracia2,     0,                 0,
                @w_am_secuencia +1)
         
         if @@error <> 0
            return 710001
      end
	  /* KDR 29/08/2022 Si el último dividendo ya está vencido, ya no devenga INT Corriente.
      ELSE
      begin
         select @w_max_secuencia = max(am_secuencia)
         from ca_amortizacion
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_di_dividendo
         and    am_concepto  = @w_ro_concepto
         
         if @w_am_secuencia = @w_max_secuencia
         begin
            insert into ca_amortizacion
                  (am_operacion,      am_dividendo,      am_concepto,
                   am_estado,         am_periodo,        am_cuota,
                   am_gracia,         am_pagado,         am_acumulado,
                   am_secuencia )
            values(@i_operacionca,    @w_di_dividendo,   @w_ro_concepto,
                   @w_am_estado,      0,                  0,
                   0,                 0,                  0,
                   @w_am_secuencia+1)
            
            if @@error <> 0
               return 710001
         end
      end
	  */
   end
   
   SIGUIENTE:
   fetch dividir
   into  @w_di_dividendo, @w_ro_concepto, @w_am_estado, @w_am_secuencia
end --WHILE CURSOR DIVIDIR

close dividir
deallocate dividir

SALIR:
return 0

go
