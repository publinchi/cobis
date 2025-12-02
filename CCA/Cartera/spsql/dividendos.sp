use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dividendos')
   drop proc sp_dividendos
go

create proc sp_dividendos
@i_nro_procesos    int,
@i_tipo            varchar(10) = null
as
declare
   @w_oper_ini       int,
   @w_oper_fin       int,
   @w_total_oper     int,
   @w_contador       int,
   @w_proceso        int,
   @w_sqlstatus      int

begin

   select @i_tipo  = 'dividendos'

   begin tran
   create table #divid (operacion  int)
   commit
   
   begin tran
   delete ca_paralelo_tmp
   where programa = @i_tipo
   commit
   

select @w_oper_ini   = 0,
       @w_oper_fin   = 0,
       @w_total_oper = 0,
       @w_contador   = 0,
       @w_proceso    = 0

      
      -- SELECCION DE LOS REGISTROS A DISTRIBUIR EN PROCESOS
      insert into #divid
      select di_operacion
      from   cob_cartera..ca_dividendo
      where  di_operacion   >   0
      and    di_dias_cuota  <=  0
      
      select @w_total_oper = @@rowcount
      print 'Obligaciones a Procesar :'+ @w_total_oper
      
      select @w_total_oper = (@w_total_oper / @i_nro_procesos) + 1
      
      if @w_total_oper = 0
         select @w_total_oper = 1
      
      declare cur_oper cursor
         for select operacion
             from   #divid
             for read only

      open cur_oper
      
      fetch cur_oper
      into  @w_oper_ini
      select @w_sqlstatus = @@fetch_status
      
      select @w_oper_fin = @w_oper_ini
      
      while @w_sqlstatus != 2
      begin
         select @w_contador = @w_contador + 1
         --
         if @w_contador = @w_total_oper
         begin
            select @w_proceso = @w_proceso + 1

            begin tran
            
            insert into ca_paralelo_tmp
                  (programa, proceso,    estado, operacion_ini, operacion_fin)
            values(@i_tipo,  @w_proceso, 'C',    @w_oper_ini,   @w_oper_fin)

            commit
            
            begin tran

            update ca_dividendo
            set    di_dias_cuota = td_factor
            from   ca_tdividendo, ca_operacion, ca_dividendo, ca_paralelo_tmp
            where  op_operacion = di_operacion
            and    op_tdividendo = td_tdividendo
            and    di_operacion  between @w_oper_ini and @w_oper_fin

            update ca_paralelo_tmp
            set    estado   = 'T'
            where  programa = 'dividendos'
            and    proceso  = @w_proceso

            commit
            
            
            select @w_oper_ini = @w_oper_fin + 1
            select @w_contador = 0
         end
         --
         fetch cur_oper
         into  @w_oper_fin
         select @w_sqlstatus = @@fetch_status
      end
      
      select @w_proceso = @w_proceso + 1
      
      begin tran
      
      insert into ca_paralelo_tmp
            (programa, proceso,    estado, operacion_ini, operacion_fin)
      values(@i_tipo,  @w_proceso, 'C',    @w_oper_ini,   @w_oper_fin)
      
      commit

      begin tran

      update ca_dividendo
      set    di_dias_cuota = td_factor
      from   ca_tdividendo, ca_operacion, ca_dividendo, ca_paralelo_tmp
      where  op_operacion = di_operacion
      and    op_tdividendo = td_tdividendo
      and    di_operacion  between @w_oper_ini and @w_oper_fin

      update ca_paralelo_tmp
      set    estado   = 'T'
      where  programa = 'dividendos'
      and    proceso  = @w_proceso


      commit
            
      
      close cur_oper
      deallocate cur_oper
      
      return 0


end
   
return 0
go