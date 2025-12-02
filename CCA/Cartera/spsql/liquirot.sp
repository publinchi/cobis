/************************************************************************/
/*      Archivo:                liquirot.sp                             */
/*      Stored procedure:       sp_dparcial_rotativos                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                          */
/*      Fecha de escritura:     Jul. 1997                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							                            */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Generacion de un desembolso parcial para la operacion indicada  */
/************************************************************************/
/*      FECHA          AUTOR          CAMBIO                            */
/*      JUL-2006    Elcira Pelaez      NR-296                           */
/*      JUN-2007    Elcira Pelaez      MANEJO INTERNER                  */
/*      Abr-04-2008 M.Roa              Adicion di_fecha_can en insert   */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dparcial_rotativos')
	drop proc sp_dparcial_rotativos
go

create proc sp_dparcial_rotativos
   @s_user                login,
   @i_operacionca         int,
   @i_dias_di             int,
   @i_num_cuotas          smallint,
   @i_dia_fijo            smallint
        
	  
as
declare @w_sp_name         descripcion,
	@w_error                int,
	@w_cuotas_mas           int,
	@w_dividendo            int,
	@w_di_fecha_ini         datetime,
	@w_di_fecha_ven         datetime,
	@w_canceladas           int,
	@w_total_cuotas         int,
	@w_fecha_ven_can        datetime,
	@w_div_can              int,
	@w_dias_cuota_can       int,
	@w_di_dividendo         int,
	@w_max_div              int,
	@w_mes                  smallint,
	@w_mes_ini              smallint,
	@w_dia                  smallint,
	@w_anio                 smallint,
	@w_dia_c                char(2),
	@w_mes_final            char(2),
	@w_rowcount_act         int
	

   
---- CARGAR VALORES INICIALES 
select @w_sp_name = 'sp_dparcial_rotativos'



begin
   ---- 14-SEP-2006 para desactivar el trigger de no permitir atualizacion
   ---              de las canceladas ya que en ente tipo de linea ('O')si  se debe permir
  --select @w_rowcount_act = sqlcontext.gettriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN', 'N')
--  EXEC sp_addextendedproperty
--         'CCA_TRIGGER','S',@level0type='Schema',@level0name=dbo,
--          @level1type='Table',@level1name=ca_amortizacion,
--          @level2type='Trigger',@level2name=tg_ca_amortizacion_can
  
  select @w_total_cuotas = @i_num_cuotas
  
   select @w_max_div = count(1)
   from ca_dividendo
   where di_operacion = @i_operacionca

   if @w_max_div  = @w_total_cuotas
   begin
  --No Se resta por que aun no hay  cuota acumulativa
    select @w_canceladas = count(1) 
    from ca_dividendo
    where  di_operacion = @i_operacionca
    and    di_estado = 3
   end
   else
   begin
      --Se resta uno para quitarla cuota acumulativa
        select @w_canceladas = count(1) -1
        from ca_dividendo
        where  di_operacion = @i_operacionca
        and    di_estado = 3
          
       if   @w_canceladas < 1
            select @w_canceladas = 1
            
   end   

  
  select  @w_cuotas_mas = @w_total_cuotas - @w_canceladas

   --Se insertan cuotas hasta el total de cuotas 

   select @w_di_fecha_ini =  di_fecha_ven
   from ca_dividendo
   where di_operacion = @i_operacionca
   and di_dividendo = @w_max_div
   
   --Se suma 1 para evitar duplicidad de la ultima cuota existente antes
   --de juntar las canceladas
   
   
   
   select @w_dividendo = @w_max_div + 1
   
   while @w_cuotas_mas < @w_total_cuotas 
   begin

         select @w_di_fecha_ven = dateadd(dd,@i_dias_di,@w_di_fecha_ini)
         select @w_mes_ini = datepart(mm,@w_di_fecha_ini)
         
         select @w_mes = datepart(mm,@w_di_fecha_ven),
                @w_dia = datepart(dd,@w_di_fecha_ven),
                @w_anio = datepart(yy,@w_di_fecha_ven)  
                
         if  @w_mes_ini = @w_mes  and datalength(convert(varchar,@i_dia_fijo) ) = 1
         begin
            
             select @w_di_fecha_ven = dateadd(mm,1,@w_di_fecha_ven)  
                           
             select @w_dia_c = '0'+ convert(varchar,@i_dia_fijo)

             select @w_mes = datepart(mm,@w_di_fecha_ven),
                    @w_dia = datepart(dd,@w_di_fecha_ven),
                    @w_anio = datepart(yy,@w_di_fecha_ven)  

              if  datalength(convert(varchar,@w_mes) ) = 1
                  select @w_mes_final = '0'+ convert(varchar,@w_mes)
               else
                  select @w_mes_final = convert(varchar,@w_mes)    
                  

              select @w_di_fecha_ven =  @w_mes_final + '/' +  @w_dia_c +  '/' + convert(char(4),@w_anio)                                             
             
         end
            
         if @w_dia > 30 
            begin            
               if @i_dia_fijo = 31 and @w_mes in (4,6,9,11)
                  select @i_dia_fijo = 30
               else
               begin
                 if @i_dia_fijo in (29,30,31 ) and @w_mes = 2
                    select @i_dia_fijo = 28
               end
   
               if  datalength(convert(varchar,@i_dia_fijo) ) = 1
                  select @w_dia_c = '0'+ convert(varchar,@i_dia_fijo)
               else
                  select @w_dia_c = convert(varchar,@i_dia_fijo)
      
      
               if  datalength(convert(varchar,@w_mes) ) = 1
                  select @w_mes_final = '0'+ convert(varchar,@w_mes)
               else
                  select @w_mes_final = convert(varchar,@w_mes)
                                    
               select @w_di_fecha_ven =  @w_mes_final + '/' +  @w_dia_c +  '/' + convert(char(4),@w_anio)
           end
           ELSE
           begin

              if  datalength(convert(varchar,@i_dia_fijo) ) = 1
                  select @w_dia_c = '0'+ convert(varchar,@i_dia_fijo)
               else
                  select @w_dia_c = convert(varchar,@i_dia_fijo)
      
      
               if  datalength(convert(varchar,@w_mes) ) = 1
                  select @w_mes_final = '0'+ convert(varchar,@w_mes)
               else
                  select @w_mes_final = convert(varchar,@w_mes)
                              
            
            select @w_di_fecha_ven =  @w_mes_final + '/' +  @w_dia_c +  '/' + convert(char(4),@w_anio)
            
           end     
         
         if exists (select 1 from ca_dividendo
                     where di_operacion = @i_operacionca
                     and di_fecha_ini = @w_di_fecha_ini)
                     begin
                        PRINT 'liquirot.sp FECHA YA EXISTE dividendo ' +  cast(@w_dividendo as varchar) +  ' di_fecha_ini ' + cast(@w_di_fecha_ini as varchar)
                        --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--                        EXEC sp_dropextendedproperty
--                              'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                              @level1type='Table',@level1name=ca_amortizacion,
--                              @level2type='Trigger',@level2name=tg_ca_amortizacion_can

                        return 703090
                     end

         if exists (select 1 from ca_dividendo
                     where di_operacion = @i_operacionca
                     and di_fecha_ven = @w_di_fecha_ven)
                     begin
                        PRINT 'liquirot.sp FECHA YA EXISTE  dividendo ' + cast(@w_dividendo as varchar) +  'di_fecha_ven' + cast(@w_di_fecha_ven as varchar)
                        --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--                        EXEC sp_dropextendedproperty
--                                'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                                  @level1type='Table',@level1name=ca_amortizacion,
--                                  @level2type='Trigger',@level2name=tg_ca_amortizacion_can

                        return 703068
                     end                     
                     
                     
         insert into ca_dividendo
               (di_operacion,    di_dividendo,   di_fecha_ini,
                di_fecha_ven,    di_de_capital,  di_de_interes,
                di_gracia,       di_gracia_disp, di_estado,
                di_dias_cuota,   di_intento,     di_prorroga,
                di_fecha_can)
         values(@i_operacionca,  @w_dividendo,   @w_di_fecha_ini,
                @w_di_fecha_ven, 'S',            'S',
                0,                0,              0,
                @i_dias_di,       0,             'N',
                '01/01/1900')

       if @@error <> 0
         begin
           -- select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--           EXEC sp_dropextendedproperty
--                  'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                  @level1type='Table',@level1name=ca_amortizacion,
--                  @level2type='Trigger',@level2name=tg_ca_amortizacion_can
            return 711043              
         end
                        
           
           --Se insertan tambien los rubros de la ca_amortizacion 
           --con valor en blanco par aser recalculados posteriormente

         insert into ca_amortizacion(
               am_operacion,am_dividendo,am_concepto,am_estado,am_periodo,
               am_cuota,am_gracia,am_pagado,am_acumulado,am_secuencia
               )
         select am_operacion,@w_dividendo,am_concepto,0,   am_periodo,
                0,          0,   0,         0,             am_secuencia
         from ca_amortizacion,
              ca_rubro_op
         where am_operacion = @i_operacionca   
         and   am_dividendo = @w_total_cuotas
         and   ro_operacion = am_operacion
         and   ro_concepto = am_concepto
         and   ro_tipo_rubro in ('C','I')
          
         if @@error <> 0
         begin
           --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--           EXEC sp_dropextendedproperty
--                  'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                  @level1type='Table',@level1name=ca_amortizacion,
--                  @level2type='Trigger',@level2name=tg_ca_amortizacion_can

           return 711044                
        end 

          --Se insertan los otros rubros que son fijos o regenerados 
          -- posteriormente como seguros y comisiones
         insert into ca_amortizacion(
               am_operacion,am_dividendo,am_concepto,am_estado,am_periodo,
               am_cuota,am_gracia,am_pagado,am_acumulado,am_secuencia
               )
         select am_operacion,@w_dividendo,am_concepto,0,   am_periodo,
                am_cuota,          0,   0, am_acumulado,   am_secuencia
         from ca_amortizacion,
              ca_rubro_op
         where am_operacion = @i_operacionca   
         and   am_dividendo = @w_total_cuotas
         and   ro_operacion = am_operacion
         and   ro_concepto = am_concepto
         and   ro_tipo_rubro in ('V','O','Q')
          
         if @@error <> 0
         begin
            --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--            EXEC sp_dropextendedproperty
--                  'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                  @level1type='Table',@level1name=ca_amortizacion,
--                  @level2type='Trigger',@level2name=tg_ca_amortizacion_can

           return 711044                
         end  

          select @w_di_fecha_ini = @w_di_fecha_ven,
                 @w_cuotas_mas = @w_cuotas_mas + 1,
                 @w_dividendo = @w_dividendo + 1
 
   end
   
   --actualizacion de las canceladas en la cuota Nro.1

  select @w_div_can = max(di_dividendo)
  from ca_dividendo
  where di_operacion = @i_operacionca
  and   di_estado = 3
  
  
  select @w_fecha_ven_can = di_fecha_ven
  from ca_dividendo
  where di_operacion = @i_operacionca
  and   di_dividendo = @w_div_can
  and di_estado = 3
  
  select @w_dias_cuota_can = sum(di_dias_cuota)
  from ca_dividendo
  where di_operacion = @i_operacionca
  and di_estado = 3

  ---SE agrupa todo lo cancelado en una cuota ficticia para
  -- Luego pasarlo a la cuotaNro.1
  
  
   insert into ca_amortizacion
   select am_operacion,
          -111,
          am_concepto, 
          am_estado,   
          am_periodo,
          sum(am_cuota),    
          sum(am_gracia),   
          sum(am_pagado),  
          sum(am_acumulado),
          am_secuencia
    from ca_amortizacion,
         ca_dividendo
   where am_operacion = @i_operacionca 
   and am_dividendo = di_dividendo
   and am_operacion = di_operacion
   and di_estado = 3
   group by  am_operacion,am_concepto,am_estado,am_periodo,am_secuencia
   
   if @@error <> 0
   begin
      --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--      EXEC sp_dropextendedproperty
--          'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--          @level1type='Table',@level1name=ca_amortizacion,
--          @level2type='Trigger',@level2name=tg_ca_amortizacion_can
      return 711045               
   end


   --Se eliminan las cuotas canceladas de ca_amortizacion
   

   delete ca_amortizacion
   from ca_amortizacion,
         ca_dividendo
   where am_operacion = @i_operacionca
   and am_dividendo = di_dividendo
   and am_operacion = di_operacion
   and di_estado = 3

   if @@error <> 0
   begin
      --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--      EXEC sp_dropextendedproperty
--          'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--          @level1type='Table',@level1name=ca_amortizacion,
--          @level2type='Trigger',@level2name=tg_ca_amortizacion_can

      return 711046              
   end
   

  --Se eliminan las cuotas canceladas de ca_dividendo
  delete ca_dividendo
  where di_operacion = @i_operacionca
  and   di_dividendo > 1
  and di_estado = 3

   if @@error <> 0
   begin
      --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--      EXEC sp_dropextendedproperty
--          'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--          @level1type='Table',@level1name=ca_amortizacion,
--          @level2type='Trigger',@level2name=tg_ca_amortizacion_can

      return 711047              
   end
  
  --Se actualizan la fecha de la gran cuota y los dias
  update  ca_dividendo
  set di_fecha_ven   = @w_fecha_ven_can,
      di_dias_cuota  = @w_dias_cuota_can,
      di_fecha_can   = @w_fecha_ven_can
  where di_operacion = @i_operacionca
  and   di_dividendo = 1
  and   di_estado = 3

   if @@error <> 0
   begin
      --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--      EXEC sp_dropextendedproperty
--          'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--          @level1type='Table',@level1name=ca_amortizacion,
--          @level2type='Trigger',@level2name=tg_ca_amortizacion_can

      return 711048
   end
  --- La cuota 1 del ca_amortizacion es la ficticia cargada anteriormente
  
  
  update  ca_amortizacion
  set am_dividendo = 1
  where am_operacion = @i_operacionca
  and   am_dividendo = -111

   if @@error <> 0
   begin
      --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--      EXEC sp_dropextendedproperty
--          'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--          @level1type='Table',@level1name=ca_amortizacion,
--          @level2type='Trigger',@level2name=tg_ca_amortizacion_can

      return 711049  
   end
  
  

   delete ca_dividendos_rot_tmp
   where dir_operacion =    @i_operacionca 
   and   dir_login     =    @s_user
  ---Actualizacion del Nro. de dividendo
  
   insert into   ca_dividendos_rot_tmp
   select @s_user,
          di_operacion,
          di_dividendo
   from ca_dividendo 
  where  di_operacion = @i_operacionca                  

   select @w_dividendo  = 1       
   
   declare
      cur_act_div cursor
      for 
          select dir_dividendo
          from   ca_dividendos_rot_tmp
          where dir_operacion =    @i_operacionca 
          and   dir_login     =    @s_user
      
          order  by dir_dividendo
      for read only
   
   open cur_act_div
   
   fetch cur_act_div
   into  @w_di_dividendo
   
   --while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin     
     
        update ca_dividendo
        set di_dividendo = @w_dividendo
        where di_operacion = @i_operacionca
        and di_dividendo = @w_di_dividendo

        if @@error <> 0
        begin
           --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--           EXEC sp_dropextendedproperty
--                    'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                      @level1type='Table',@level1name=ca_amortizacion,
--                      @level2type='Trigger',@level2name=tg_ca_amortizacion_can
           return 711051          
        end

        update ca_amortizacion
        set am_dividendo = @w_dividendo
        where am_operacion = @i_operacionca
        and am_dividendo = @w_di_dividendo

        if @@error <> 0
        begin
          --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--           EXEC sp_dropextendedproperty
--                  'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                  @level1type='Table',@level1name=ca_amortizacion,
--                  @level2type='Trigger',@level2name=tg_ca_amortizacion_can
           return 711052        
        end
        
        select @w_dividendo = @w_dividendo + 1
        
      fetch cur_act_div
      into  @w_di_dividendo
   end -- while cursor
   
   close cur_act_div
   deallocate cur_act_div
   
   --Actualizacion de la nueva fecha de vencimiento del credito
   
   select @w_di_fecha_ven =  max(di_fecha_ven)
   from ca_dividendo
   where di_operacion = @i_operacionca
   
   update ca_operacion
   set op_fecha_fin = @w_di_fecha_ven
   where op_operacion = @i_operacionca
   
   if @@error <> 0
   begin
      --select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--      EXEC sp_dropextendedproperty
--              'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--              @level1type='Table',@level1name=ca_amortizacion,
--              @level2type='Trigger',@level2name=tg_ca_amortizacion_can
      return 711053
   end
   
end --- Proceso general

---SEP-14-2006 EPB instruccion para activar el trigger si el proceso  no genera erro
---                si hay error, en cada return hablra un activar el trigger

--select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--    EXEC sp_dropextendedproperty
--          'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--          @level1type='Table',@level1name=ca_amortizacion,
--          @level2type='Trigger',@level2name=tg_ca_amortizacion_can


return 0


go




