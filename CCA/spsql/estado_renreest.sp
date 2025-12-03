/****************************************************************************/
/*      Archivo           :  estado_renreest.sp                             */
/*      Base de datos     :  cob_cartera                                    */
/*      Producto          :  Cartera                                        */
/*      Disenado por      :  Ignacio Yupa                                   */
/*      Fecha de escritura:  06/Dic/2016                                    */
/****************************************************************************/
/*                              IMPORTANTE                                  */
/*    Esta aplicacion es parte de los paquetes bancarios propiedad          */
/*    de COBISCorp.                                                         */
/*    Su uso no    autorizado queda  expresamente   prohibido asi como      */
/*    cualquier    alteracion o  agregado  hecho por    alguno  de sus      */
/*    usuarios sin el debido consentimiento por   escrito de COBISCorp.     */
/*    Este programa esta protegido por la ley de   derechos de autor        */
/*    y por las    convenciones  internacionales   de  propiedad inte-      */
/*    lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para   */
/*    obtener ordenes  de secuestro o  retencion y para  perseguir          */
/*    penalmente a los autores de cualquier   infraccion.                   */
/****************************************************************************/
/*                              PROPOSITO                                   */
/*      Paso a historicos de las transacciones monetarias del dia           */
/****************************************************************************/
/*                            MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                               */
/*      06/Dic/2016     I. Yupa         Emision Inicial                     */ 
/*      06/Nov/2019     Luis Ponce      Quitar nace vencida en Renovaciones */
/****************************************************************************/

USE cob_cartera
GO

if object_id('sp_estado_renreest') is not null
begin
  drop procedure sp_estado_renreest 
  if object_id('sp_estado_renreest ') is not null
    print 'FAILED DROPPING PROCEDURE sp_estado_renreest '  
end

go
   
create procedure  sp_estado_renreest (   
   @s_date             datetime    = null,
   @t_show_version     bit         = 0,
   @i_operacion        char(1)     = null,
   @i_tipo             char(1)     = null,
   @i_banco_orig       cuenta      = null,
   @i_banco_nuevo      cuenta      = null,
   @i_operaciones      varchar(500)= null,
   @o_estado           tinyint     = 1 out
)

as declare 
   @w_sp_name              varchar(40),
   @w_return               int,
   @w_estado               tinyint,
   @w_tramite              cuenta,
   @w_est_vencido          tinyint,
   @w_operacion            int,
   @w_dias_mora            int,
   @w_est_cancelado        tinyint,
   @w_est_vigente          tinyint,
   @w_porcentaje           int,
   @w_param_capital        char(5),
   @w_param_mora           char(5),
   @w_param_int            char(5),
   @w_monto_intmo          money,
   @w_gracia_orig_cap      int,
   @w_gracia_cap           int,
   @w_gracia_int           int,
   @w_plazo_total          int,
   @w_monto_capital        money,
   @w_gracia_orig_int      int,
   @w_plazo_trans          int,
   @w_porcentaje_capital   int,
   @w_monto_nuevo          money,
   @w_error                int,
   @w_fecha_ult_proceso    datetime,

   @w_sc                   char(1),
   @w_k                    smallint,
   @w_banco                cuenta,
   @w_largo_trama          smallint,
   @w_nace_vencido         char(2)

select @w_sp_name = 'sp_estado_renreest'
           
exec @w_return   = sp_estados_cca 
@o_est_vencido   = @w_est_vencido   out,
@o_est_cancelado = @w_est_cancelado out,
@o_est_vigente   = @w_est_vigente   out
      
if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end

if @i_operacion = 'E'
begin
   --CAPTURA DE PARAMETROS
    --PORCENTAJE RENOVACION REESTRUCTURACION
   select @w_porcentaje = pa_int 
   from cobis..cl_parametro
   where pa_nemonico = 'PRERE'
   and pa_producto = 'CCA'
   
   if @w_porcentaje is null
   begin
      select @w_error = 724590
      goto ERROR
   end    
    
    --SIGLAS DE CAPITAL
   select @w_param_capital = pa_char 
   from cobis..cl_parametro
   where pa_nemonico = 'CAP'
   and pa_producto = 'CCA'
    
   if @w_param_capital is null 
   begin
      select @w_error = 710429
      goto ERROR
   end
    
    --RUBRO INTERES DE MORA
   select @w_param_mora = pa_char 
   from cobis..cl_parametro
   where pa_nemonico = 'IMO'
   and pa_producto = 'CCA'
   
   if @w_param_mora is null
   begin
      select @w_error = 724592
      goto ERROR
   end
    
    --RUBRO INTERES CORRIENTE
   select @w_param_int = pa_char 
   from cobis..cl_parametro
   where pa_nemonico = 'INT'
   and pa_producto = 'CCA'
   
   if @w_param_int is null
   begin
      select @w_error = 710428 --
      goto ERROR
   end
    
    --PORCENTAJE CAPITAL RENOVAR
   select @w_porcentaje_capital = pa_int 
   from cobis..cl_parametro
   where pa_nemonico = 'PCAPRE'
   and pa_producto = 'CCA'
   
   if @w_porcentaje_capital is null
   begin
      select @w_error = 724594
      goto ERROR
   end
    
    select @w_tramite   = op_tramite,
          @w_operacion = op_operacion,
          @w_estado    = op_estado 
   from ca_operacion
   where op_banco = @i_banco_orig
    
   if @i_tipo = 'E' --REESTRUCTURACION
   begin
      --MODALIDAD AMERICANA RES 
      if (select count(1)
         from ca_amortizacion
         where am_operacion = @w_operacion
         and am_concepto = @w_param_capital
         and (am_cuota + am_gracia) > 0) = 1
         
         select @w_estado = @w_est_vencido
   end
   
   if @i_tipo = 'R' --RENOVACION
   begin
      --MODALIDAD AMERICANA REN 
      if exists (select 1 from cob_credito..cr_op_renovar, ca_operacion 
                  where or_tramite = @w_tramite
                  and or_num_operacion = op_banco
                  and op_estado = @w_est_vencido  
                  and op_gracia_cap > 0 
                  and op_dist_gracia in ('S', 'N')
                  and op_gracia_cap = op_plazo - 1)
         select @w_estado = @w_est_vencido
      else
         select @w_estado = op_estado 
         from cob_credito..cr_op_renovar, ca_operacion 
         where or_tramite = @w_tramite
         and or_num_operacion = op_banco
         and op_estado != @w_est_cancelado
   end
    
   --LPO TEC SE COMENTA ESTA VALIDACION DE NACE VENCIDA PUES TEC NO HA DEFINIDO NINGÚN CONTROL EN RENOVACIONES
   /*if @w_estado = @w_est_vencido 
      select @o_estado = @w_est_vencido
   else
   begin      
      select @o_estado = @w_est_vigente
      
      --Validacion del 80%
      select  
      @w_plazo_total = (datediff(day,op_fecha_ini,op_fecha_fin)),
      @w_plazo_trans = (datediff(day,op_fecha_ini,op_fecha_ult_proceso)),
      @w_gracia_cap = op_gracia_cap, 
      @w_gracia_int = op_gracia_int,
      @w_monto_nuevo = op_monto        
      from  ca_operacion 
      where op_operacion = @w_operacion
   
      select 
      @w_monto_capital = sum(am_cuota + am_gracia - am_pagado)
      from  ca_dividendo, ca_amortizacion
      where di_operacion = @w_operacion
      and di_estado in (@w_est_vigente,@w_est_vencido)
      and am_operacion = @w_operacion
      and am_dividendo = di_dividendo
      and am_concepto = @w_param_capital
               
      select 
      @w_monto_intmo = sum(am_acumulado + am_gracia - am_pagado)
      from  ca_dividendo, ca_amortizacion
      where di_operacion = @w_operacion
      and di_estado in (@w_est_vigente,@w_est_vencido)
      and am_operacion = @w_operacion
      and am_dividendo = di_dividendo
      and am_concepto in (@w_param_int, @w_param_mora)
               
      if @w_monto_intmo > 0 or @w_monto_capital > 0
         select @o_estado = @w_est_vencido
      
      if @i_tipo = 'R'
      begin
         
         --SI NO HA TRANSCURRIDO UN PORCENTAJE X DEL PLAZO TOTAL DEL PRESTAMO
         if ((@w_plazo_total * @w_porcentaje)/100) < @w_plazo_trans
         begin                  
            select 
         @w_gracia_orig_cap = max(op_gracia_cap),
            @w_gracia_orig_int = max(op_gracia_int)            
            from cob_credito..cr_op_renovar, ca_operacion 
         where or_tramite = @w_tramite
         and   or_num_operacion = op_banco
         and   op_estado <> @w_est_cancelado
                  
         if @w_gracia_cap > @w_gracia_orig_cap or @w_gracia_int > @w_gracia_orig_int
            select @o_estado = @w_est_vencido
         end
         else  --SI HA TRANSCURRIDO UN PORCENTAJE X DEL PLAZO TOTAL DEL PRESTAMO
         begin
            if @w_monto_capital > ((@w_monto_nuevo * @w_porcentaje_capital)/100)
               select @o_estado = @w_est_vencido
         end
      
      end
   end
   */
   --LPO TEC FIN SE COMENTA ESTA VALIDACION DE NACE VENCIDA PUES TEC NO HA DEFINIDO NINGÚN CONTROL EN RENOVACIONES
end

if @i_operacion = 'M'
begin
   select  @w_tramite = op_tramite,
            @w_operacion = op_operacion,
            @w_fecha_ult_proceso = op_fecha_ult_proceso
   from ca_operacion
   where op_banco = @i_banco_orig

   if @i_tipo = 'E' --REESTRUCTURACION
   begin
      --DIAS DE MORA RES
      select @w_dias_mora = isnull(max(datediff(day,di_fecha_ven, @w_fecha_ult_proceso)),0)
      from ca_dividendo 
      where di_operacion = @w_operacion
      and di_estado = @w_est_vencido
   end
   if @i_tipo = 'R' --RENOVACION
   begin     
      --DIAS DE MORA REN    
      select @w_dias_mora = isnull(max(datediff(day,di_fecha_ven, op_fecha_ult_proceso)),0)
      from ca_dividendo, cob_credito..cr_op_renovar, ca_operacion
      where or_tramite = @w_tramite
      and   op_banco = or_num_operacion
      and op_estado <> @w_est_cancelado
      and di_operacion = op_operacion
      and di_estado = @w_est_vencido      
   end
   
   insert into ca_operacion_ext (oe_operacion, oe_columna, oe_int)
   values(@w_operacion, 'op_dias_mora', isnull(@w_dias_mora,0))
   
   if @@error <> 0
   begin
      select @w_error = 724595
      goto ERROR
   end
end

-- OPCION PARA EVALUAR SI UNA OPERACION DE RENOVACION NACE VENCIDA
if @i_operacion = 'R'
begin
   --CAPTURA DE PARAMETROS
   --PORCENTAJE RENOVACION REESTRUCTURACION
   select @w_porcentaje = pa_int 
   from   cobis..cl_parametro
   where  pa_nemonico = 'PRERE'
   and    pa_producto = 'CCA'
   
   if @w_porcentaje is null
   begin
       select @w_error = 724590
       goto ERROR
   end

   --SIGLAS DE CAPITAL
   select @w_param_capital = pa_char 
   from   cobis..cl_parametro
   where  pa_nemonico = 'CAP'
   and    pa_producto = 'CCA'
   
   if @w_param_capital is null 
   begin
       select @w_error = 710429
       goto ERROR
   end

   --RUBRO INTERES DE MORA
   select @w_param_mora = pa_char 
   from   cobis..cl_parametro
   where  pa_nemonico = 'IMO'
   and    pa_producto = 'CCA'
   
   if @w_param_mora is null
   begin
       select @w_error = 724592
       goto ERROR
   end
   
   --RUBRO INTERES CORRIENTE
   select @w_param_int = pa_char 
   from   cobis..cl_parametro
   where  pa_nemonico = 'INT'
   and    pa_producto = 'CCA'
   
   if @w_param_int is null
   begin
       select @w_error = 710428 --
       goto ERROR
   end
   --PORCENTAJE CAPITAL RENOVAR
   select @w_porcentaje_capital = pa_int 
   from   cobis..cl_parametro
   where  pa_nemonico = 'PCAPRE'
   and    pa_producto = 'CCA'
   
   if @w_porcentaje_capital is null
   begin
       select @w_error = 724594
       goto ERROR
   end
   
   select @w_tramite   = op_tramite,
          @w_operacion = op_operacion,
          @w_estado    = op_estado 
   from   ca_operacion
   where  op_banco = @i_banco_orig
   

   -- crear tabla temporal con las operaciones a renovar
   create table #ca_op_renovar_tmp (or_num_operacion cuenta)
   select @w_sc = ','
   select @w_largo_trama = len(@i_operaciones)
   select @w_k           = charindex (@w_sc, @i_operaciones)

   while @w_k > 0 
   begin
       select @w_banco       = substring(@i_operaciones, 1, @w_k - 1)
       select @i_operaciones = substring(@i_operaciones, @w_k+1, @w_largo_trama)
       select @w_k  = charindex (@w_sc, @i_operaciones)
       insert into #ca_op_renovar_tmp values (@w_banco)
   end 
   --fin creacion de temporal

   if @i_tipo = 'R' --RENOVACION
   begin
--LPO TEC SE COMENTA ESTA VALIDACION DE NACE VENCIDA PUES TEC NO HA DEFINIDO NINGÚN CONTROL EN RENOVACIONES
-- OPCION PARA EVALUAR SI UNA OPERACION DE RENOVACION NACE VENCIDA
/*       --MODALIDAD AMERICANA REN 
       if exists (select 1 from #ca_op_renovar_tmp, ca_operacion 
                   where or_num_operacion = op_banco
                   and   op_estado        = @w_est_vencido  
                   and   op_gracia_cap    > 0 
                   and   op_dist_gracia  in ('S', 'N')
                   and   op_gracia_cap    = op_plazo - 1)
           select @w_estado = @w_est_vencido
       else       
           select @w_estado = op_estado 
           from   #ca_op_renovar_tmp, ca_operacion 
           where  or_num_operacion = op_banco
           and    op_estado       != @w_est_cancelado
   end
   if @w_estado = @w_est_vencido 
       select @o_estado = @w_est_vencido
   else
   begin      
*/
--LPO TEC FIN SE COMENTA ESTA VALIDACION DE NACE VENCIDA PUES TEC NO HA DEFINIDO NINGÚN CONTROL EN RENOVACIONES
   
       select @o_estado = @w_est_vigente
   
--LPO TEC SE COMENTA ESTA VALIDACION DE NACE VENCIDA PUES TEC NO HA DEFINIDO NINGÚN CONTROL EN RENOVACIONES
/*       --Validacion del 80%
       select  
       @w_plazo_total = (datediff(day,op_fecha_ini,op_fecha_fin)),
       @w_plazo_trans = (datediff(day,op_fecha_ini,op_fecha_ult_proceso)),
       @w_gracia_cap = op_gracia_cap, 
       @w_gracia_int = op_gracia_int,
       @w_monto_nuevo = op_monto        
       from  ca_operacion 
       where op_operacion = @w_operacion
       
       select 
       @w_monto_capital = sum(am_cuota + am_gracia - am_pagado)
       from  ca_dividendo, ca_amortizacion
       where di_operacion = @w_operacion
       and di_estado in (@w_est_vigente,@w_est_vencido)
       and am_operacion = @w_operacion
       and am_dividendo = di_dividendo
       and am_concepto = @w_param_capital
       
       select 
       @w_monto_intmo = sum(am_acumulado + am_gracia - am_pagado)
       from  ca_dividendo, ca_amortizacion
       where di_operacion = @w_operacion
       and di_estado in (@w_est_vigente,@w_est_vencido)
       and am_operacion = @w_operacion
       and am_dividendo = di_dividendo
       and am_concepto in (@w_param_int, @w_param_mora)
       
       if @w_monto_intmo > 0 or @w_monto_capital > 0
           select @o_estado = @w_est_vencido
           
       if @i_tipo = 'R'
       begin
           --SI NO HA TRANSCURRIDO UN PORCENTAJE X DEL PLAZO TOTAL DEL PRESTAMO
           if ((@w_plazo_total * @w_porcentaje)/100) < @w_plazo_trans
           begin                  
               select  @w_gracia_orig_cap = max(op_gracia_cap),
                       @w_gracia_orig_int = max(op_gracia_int)            
               from    #ca_op_renovar_tmp, ca_operacion 
               where   or_num_operacion = op_banco
               and     op_estado       <> @w_est_cancelado
               
               if @w_gracia_cap > @w_gracia_orig_cap or @w_gracia_int > @w_gracia_orig_int
                   select @o_estado = @w_est_vencido
           end
           else  --SI HA TRANSCURRIDO UN PORCENTAJE X DEL PLAZO TOTAL DEL PRESTAMO
           begin
               if @w_monto_capital > ((@w_monto_nuevo * @w_porcentaje_capital)/100)
                   select @o_estado = @w_est_vencido
           end
       end
*/       
--LPO TEC FIN SE COMENTA ESTA VALIDACION DE NACE VENCIDA PUES TEC NO HA DEFINIDO NINGÚN CONTROL EN RENOVACIONES
   end
      
   select @w_nace_vencido = 'NO'
   
--LPO TEC SE COMENTA ESTA VALIDACION DE NACE VENCIDA PUES TEC NO HA DEFINIDO NINGÚN CONTROL EN RENOVACIONES
/*   if @o_estado = @w_est_vencido 
       select @w_nace_vencido = 'SI'
*/
--LPO TEC FIN SE COMENTA ESTA VALIDACION DE NACE VENCIDA PUES TEC NO HA DEFINIDO NINGÚN CONTROL EN RENOVACIONES
       
   select 'estado'       = @o_estado,
          'nace vencido' = @w_nace_vencido
   
end 


return 0

ERROR:
exec cobis..sp_cerror
@t_debug  = 'N',
@t_from   = @w_sp_name,
@i_num    = @w_error
        
return @w_error  

GO
