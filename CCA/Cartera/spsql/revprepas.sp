/****************************************************************************/
/*   Archivo:                 revprepas.sp                                  */
/*   Stored procedure:        sp_revisa_prepago_pasiva                      */
/*   Base de datos:           cob_cartera                                   */
/*   Producto:                Cartera                                       */
/*   Disenado por:            Sandra Mora R.                                */
/*   Fecha de escritura:      Dic.18 de 2006                                */
/****************************************************************************/
/*                           IMPORTANTE                                     */
/*   Este programa es parte de los paquetes bancarios propiedad de 'MACOSA'.*/                                                             
/*   Su uso no autorizado queda expresamente prohibido asi como cualquier   */ 
/*   alteracion o agregado hecho por alguno de sus usuarios sin el debido   */
/*   consentimiento por escrito de la Presidencia Ejecutiva de MACOSA o su  */
/*   representante.                                                         */
/****************************************************************************/
/*                           PROPOSITO                                      */
/*   Proceso batch que realiza la revisión de prepago para pasivas          */     
/****************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_revisa_prepago_pasiva')
   drop proc sp_revisa_prepago_pasiva
go

create proc sp_revisa_prepago_pasiva
   @i_fecha_proceso_ini      datetime, --Es la fecha de proceso del cierre anterior
   @i_fecha_proceso_fin      datetime, --Es la fecha de proceso del cierre
   @i_codigo_prepago         catalogo, --Char
   @i_secuencial             int,      --Seleccionado por el usuario en pantalla
   @i_banco_seg_piso         cuenta    --Char
as
declare
   @w_causal_rech_pago_act   varchar,
   @w_dias_fag_mora          int,
   @w_tr_operacion           int,
   @w_op_fecha_ult_proceso   datetime,
   @w_op_estado              tinyint,
   @w_op_base_calculo        char,
   @w_op_codigo_externo      cuenta,
   @w_op_cliente             int,
   @w_op_banco               cuenta,
   @w_ult_pag                int,
   @w_ult_ing                int,
   @w_fecha_vencimiento      datetime,
   @w_dias_vencidos_op       smallint,
   @w_op_operacion_pas       int,
   @w_op_estado_pas          tinyint,
   @w_op_banco_pas           cuenta
   
select @w_causal_rech_pago_act = pa_char
from 	cobis..cl_parametro
where 	pa_producto = 'CCA'
   and 	pa_nemonico = 'CRCHPA'

select @w_dias_fag_mora = pa_int
from 	cobis..cl_parametro
where 	pa_producto = 'CCA'
   and 	pa_nemonico = 'DIFAGM'

declare act_con_pago cursor for --SELECCIONA EL DIVIDENDO A AFECTAR
select distinct tr_operacion
from ca_transaccion
where tr_tran = 'PAG' 
   and tr_fecha_mov between @i_fecha_proceso_ini and @i_fecha_proceso_fin
for read only

open act_con_pago
fetch next from act_con_pago into
@w_tr_operacion   

   --while @@fetch_status not in (-1,0) 
   while @@fetch_status = 0
   begin
      select @w_op_fecha_ult_proceso = op_fecha_ult_proceso,
             @w_op_estado            = op_estado,
             @w_op_base_calculo      = op_base_calculo,
             @w_op_codigo_externo    = op_codigo_externo,
             @w_op_cliente           = op_cliente,
             @w_op_banco             = op_banco
      from   ca_operacion            
      where  op_operacion            = @w_tr_operacion
      
      select @w_ult_pag   = max(tr_secuencial) 
      from ca_transaccion 
      where tr_operacion  = @w_tr_operacion
         and tr_tran      = 'PAG'
         and tr_estado    <> 'RV'
      
      select @w_ult_ing = ab_secuencial_ing 
      from ca_abono 
      where  ab_secuencial_pag = @w_ult_pag 
         and ab_operacion      = @w_tr_operacion
      
      -- Se extrae la fecha de vencimiento de la cuota mas vencida
    
      select @w_fecha_vencimiento = min(di_fecha_ven) 
      from ca_dividendo
      where di_operacion = @w_tr_operacion
         and di_estado = 2
         
      if @w_fecha_vencimiento is null 
      begin
         select @w_fecha_vencimiento = @w_fecha_vencimiento
      end  
      else
      begin
        select @w_dias_vencidos_op = isnull(datediff(dd, @w_fecha_vencimiento, @i_fecha_proceso_fin), 0) --calcula días de vencimiento 
        if (@w_dias_vencidos_op < @w_dias_fag_mora) and (@w_op_codigo_externo > '3')
        begin
           select @w_op_operacion_pas = op_operacion,
                  @w_op_estado_pas    = op_estado,
                  @w_op_banco_pas     = op_banco
           from ca_operacion
           where op_cliente           = @w_op_cliente 
              and op_codigo_externo   = @w_op_codigo_externo 
              and op_naturaleza       = 'P'
           -- si la pasiva no esta cancelada
           if (@w_op_estado_pas <> 3) and exists(select 1 
                                                 from ca_prepagos_pasivas 
                                                 where pp_banco = @w_op_banco_pas
                                                    and pp_estado_registro = 'I' 
                                                    and pp_estado_aplicar <> 'S')
           begin
              update ca_prepagos_pasivas
              set    pp_estado_aplicar       = 'R',
                     pp_causal_rechazo       = convert(char,@w_causal_rech_pago_act),
                     pp_secuencial_ing       = @w_ult_ing
              where  pp_banco                = @w_op_banco_pas
              and    pp_estado_registro      = 'I'      -- Registro no procesado por el batch
              and    pp_estado_aplicar       <> 'S'
              and    pp_codigo_prepago       = @i_codigo_prepago
              and    pp_secuencial           = @i_secuencial -- Seleccionado por el usuario en pantalla
              and    substring(pp_linea,1,3) = @i_banco_seg_piso
                          
           print 'Actualizando operacion' + cast (@w_tr_operacion as varchar)
           end
        end
      end
      fetch next from act_con_pago into
         @w_tr_operacion
   end
close act_con_pago
deallocate act_con_pago
  
return 0
