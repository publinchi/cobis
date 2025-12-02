use cob_cartera
go

if exists(select 1 from sysobjects where name = 'ca_verificacion')
   drop table ca_verificacion
go

create table ca_verificacion
(
  ve_operacion          int,
  ve_saldo_cap_ini      money,
  ve_saldo_int_ini      money,
  ve_saldo_otros_ini    money,
  
  ve_nuevos_cap         money,
  ve_pagos_cap          money,
  ve_causacion_int      money,
  ve_pagos_int          money,
  ve_ing_otros          money,
  ve_pagos_otros        money,
  
  ve_saldo_cap_hoy      money,
  ve_saldo_int_hoy      money,
  ve_saldo_otros_hoy    money,
--  ve_fecha_ini          datetime,
--  ve_fecha_fin          datetime
  ve_cuadra             char(2)
)
go

create unique nonclustered index ca_verificacion_1 on ca_verificacion(ve_operacion)
go

--alter table ca_verificacion partition 200
go
--grant select on ca_verificacion to rol_consulta
go

if exists(select 1 from sysobjects where name = 'sp_verifica_hc')
   drop proc sp_verifica_hc
go

create proc sp_verifica_hc
@i_fecha_desde   datetime,
@i_fecha_hasta   datetime,
@i_operacion     int       =  null,
@i_revision      char(1)   = 'N',
@i_proceso       int       = null
as
declare
   @w_ve_operacion         int,
   @w_op_estado            smallint,
   @w_op_fecha_ult_proceso datetime,
   @w_op_moneda            smallint,
   @w_ve_saldo_cap_ini     money,
   @w_ve_saldo_int_ini     money,
   @w_ve_saldo_otros_ini   money,
   
   @w_ve_nuevos_cap        money,
   @w_ve_pagos_cap         money,
   @w_ve_causacion_int     money,
   @w_ve_pagos_int         money,
   @w_ve_ing_otros         money,
   @w_ve_pagos_otros       money,
   
   @w_ve_saldo_cap_hoy     money,
   @w_ve_saldo_int_hoy     money,
   @w_ve_saldo_otros_hoy   money,
   @w_ve_cuadra            char(2),
   
   @w_secuencial_his       int,
   @w_secuencial_ini       int,
   @w_secuencial_tran      int,
   
   @w_tr_tran              catalogo,
   @w_tr_fecha_mov         datetime,
   @w_dtr_codvalor         int,
   @w_dtr_concepto         catalogo,
   @w_dtr_monto_mn            money,
   @w_tr_estado            catalogo,
   @w_tr_secuencial        int,
   @w_dtr_monto_cont       money,
   
   @w_de_saldos_hc         char(1),
   @w_cotizacion           money,
   @w_dtr_monto            money,
   
   -- PARALELISMO
   @p_operacion_ini  int,
   @p_operacion_fin  int,
   @p_proceso        int,
   @p_programa       catalogo,
   @p_total_oper     int,
   @p_estado         char(1),
   @p_ult_update     datetime,
   @p_cont_operacion int,
   @p_tiempo_update  int

begin
   select @p_programa      = 'hcpasivas',
          @p_proceso       = @i_proceso, -- SOLO POR MANTENER EL ESTANDAR DEL NOMBRE DE VARIABLES DEL PARALELO
          @p_ult_update    = getdate(),
          @p_tiempo_update = 15,
          @p_estado        = 'P'
   
   if @p_proceso is not null
   begin
      select @p_operacion_ini  = operacion_ini,
             @p_operacion_fin  = operacion_fin,
             @p_estado         = estado,
             @p_cont_operacion = 0
      from   ca_paralelo_tmp
      where  programa = @p_programa
      and    proceso  = @p_proceso
      
      print 'hcpasivas  proceso'+ cast(@p_proceso as varchar) + 'oper ini' +  cast(@p_operacion_ini as varchar) + 'oper fin'+  cast(@p_operacion_fin as varchar) 
   end
   ELSE
      select @p_estado = 'P'
   
   select @w_de_saldos_hc = 'N'
   
   if exists(select 1
             from   ca_saldos_cartera_mensual
             where  sc_fecha = @i_fecha_hasta)
   begin
      select @w_de_saldos_hc = 'S'
      print 'LOS SALDOS FINALES SE EXTRAEN DE LA HC'
   end
   ELSE
   begin
      select @w_de_saldos_hc = 'N'
      print 'LOS SALDOS FINALES SE EXTRAEN DE LA SITUACION ACTUAL'
      select @i_fecha_hasta = 'jan 1 2010'
   end
   
   if @i_operacion is null
   begin
      if @i_revision = 'N'
      begin
         declare
            cur_operacion cursor
            for select op_operacion, op_estado, op_fecha_ult_proceso, op_moneda
                from   ca_operacion--(index ca_operacion_1)
                where  op_operacion between @p_operacion_ini and @p_operacion_fin
                and    op_naturaleza = 'P'
                and    op_estado  != 3
                order  by op_operacion
            for read only
         
         select @p_cont_operacion = 0
      end
      ELSE
      begin
         print '2a Revisión'
         declare
            cur_operacion cursor
            for select op_operacion, op_estado, op_fecha_ult_proceso, op_moneda
                from   ca_verificacion, ca_operacion--(index ca_operacion_1)
                where  op_operacion = ve_operacion
                and    op_naturaleza = 'P'
                and    op_estado    != 3
                order  by op_operacion
            for read only
      end
   end
   ELSE
   begin
      print 'Revisar' + @i_operacion
      declare
         cur_operacion cursor
         for select op_operacion, op_estado, op_fecha_ult_proceso, op_moneda
             from   ca_operacion o
             where  op_operacion = @i_operacion
             and    op_naturaleza = 'P'
             and    op_estado  != 3
         for read only
   end
   
   if @p_proceso is not null
   begin
      BEGIN TRAN
      
      update ca_paralelo_tmp
      set    estado     = 'P',
             spid       = @@spid,
             hora       = getdate(),
             hostprocess = master..sysprocesses.hostprocess,
             procesados  = @p_cont_operacion
      from   master..sysprocesses
      where  programa = @p_programa
      and    proceso  = @p_proceso
      and    master..sysprocesses.spid = @@spid
      
      COMMIT
   end
   
   open cur_operacion
   
   fetch cur_operacion
   into  @w_ve_operacion, @w_op_estado, @w_op_fecha_ult_proceso, @w_op_moneda
   
   --while @@fetch_status not in (-1,0) and @p_estado = 'P'
   while @@fetch_status = 0 and @p_estado = 'P'
   begin
      if @p_proceso is not null
      begin
         -- ACTUALIZAR EL NUMERO DE REGISTROS PROCESADOS
         select @p_cont_operacion = @p_cont_operacion + 1
         
         -- ACTUALIZAR EL PROCESO CADA 15 SEGUNDOS APROX.
         if datediff(ss, @p_ult_update, getdate()) > @p_tiempo_update
         begin
            select @p_ult_update = getdate()
            BEGIN TRAN
            
            update ca_paralelo_tmp
            set    hora   = getdate(),
                   procesados = @p_cont_operacion
            where  programa = @p_programa
            and    proceso = @p_proceso
            
            -- AVERIGUAR EL ESTADO DEL PROCESO
            select @p_estado = estado
            from   ca_paralelo_tmp
            where  programa = @p_programa
            and    proceso = @p_proceso
            
            COMMIT
         end
      end
      
      select @w_ve_saldo_cap_ini   = 0
      select @w_ve_saldo_int_ini   = 0
      select @w_ve_saldo_otros_ini = 0
      
      -- CUAL HISTORIA SIRVE?
      select @w_secuencial_ini = isnull(min(oph_secuencial), 99999999)
      from   ca_operacion_his
      where  oph_operacion = @w_ve_operacion
      
      select @w_secuencial_his = isnull(min(oph_secuencial), @w_secuencial_ini)
      from   cob_cartera_his..ca_operacion_his
      where  oph_operacion = @w_ve_operacion
      and    oph_secuencial < @w_secuencial_ini
      
      if @i_operacion is not null
         print 'cob_cartera, ' + cast(@w_secuencial_ini as varchar) + ' ' + ', cob_cartera_his '  + cast(@w_secuencial_his as varchar)
      
      if @w_secuencial_his < @w_secuencial_ini -- SE EXTRAE DE COB_CARTERA_HIS
         select @w_secuencial_tran = @w_secuencial_his
      else
         select @w_secuencial_tran = @w_secuencial_ini
      
      if not exists(select 1
                    from   ca_transaccion
                    where  tr_operacion = @w_ve_operacion
                    and    tr_secuencial = @w_secuencial_tran
                    and    tr_tran = 'DES')
      begin
         if @i_operacion is not null
            print 'secuencial_his' + cast(@w_secuencial_his as varchar)
         
         if @w_secuencial_his < @w_secuencial_ini -- SE EXTRAE DE COB_CARTERA_HIS
         begin
            -- EXTRAER LOS SALDOS DE CAPITAL DE LA COB_CARTERA_HIS
            if exists(select 1
                      from   ca_transaccion
                      where  tr_operacion  = @w_ve_operacion
                      and    tr_secuencial = @w_secuencial_ini
                      and    tr_estado     != 'RV')
            or exists(select 1
                      from   cob_cartera_his..ca_transaccion
                      where  tr_operacion  = @w_ve_operacion
                      and    tr_secuencial = @w_secuencial_ini
                      and    tr_estado     != 'RV')
            begin
               select @w_ve_saldo_cap_ini = isnull(sum(amh_acumulado - amh_pagado), 0)
               from   cob_cartera_his..ca_amortizacion_his
               where  amh_operacion = @w_ve_operacion
               and    amh_secuencial = @w_secuencial_his
               and    amh_concepto = 'CAP'
               
               -- EXTRAER LOS SALDOS DE INTERES DE LA COB_CARTERA_HIS
               select @w_ve_saldo_int_ini = isnull(sum(amh_acumulado - amh_pagado), 0)
               from   cob_cartera_his..ca_amortizacion_his
               where  amh_operacion = @w_ve_operacion
               and    amh_secuencial = @w_secuencial_his
               and    amh_concepto in ('INT', 'CXP_INTES', 'INTANT')
            end
            ELSE
               select @w_ve_saldo_cap_ini = 0,
                      @w_ve_saldo_int_ini = 0
            
            if @i_operacion is not null
               print '(HIS) INI_CAP ' + + cast(@w_ve_saldo_cap_ini as varchar) + ' INI_INT ' + cast(@w_ve_saldo_int_ini as varchar)
            
            -- EXTRAER LOS SALDOS DE OTROS CONCEPROS DE LA COB_CARTERA_HIS
            select @w_ve_saldo_otros_ini = isnull(sum(amh_acumulado - amh_pagado), 0)
            from   cob_cartera_his..ca_amortizacion_his
            where  amh_operacion = @w_ve_operacion
            and    amh_secuencial = @w_secuencial_his
            and    amh_concepto = 'IOCPASIVAS'
         end
         ELSE
         begin
            -- EXTRAER LOS SALDOS DE CAPITAL DE LA COB_CARTERA_HIS
            if exists(select 1
                      from   ca_transaccion
                      where  tr_operacion  = @w_ve_operacion
                      and    tr_secuencial = @w_secuencial_ini
                      and    tr_estado     != 'RV')
            or exists(select 1
                      from   cob_cartera_his..ca_transaccion
                      where  tr_operacion  = @w_ve_operacion
                      and    tr_secuencial = @w_secuencial_ini
                      and    tr_estado     != 'RV')
            begin
               select @w_ve_saldo_cap_ini = isnull(sum(amh_acumulado - amh_pagado), 0)
               from   ca_amortizacion_his
               where  amh_operacion = @w_ve_operacion
               and    amh_secuencial = @w_secuencial_ini
               and    amh_concepto = 'CAP'
               
               -- EXTRAER LOS SALDOS DE INTERES DE LA COB_CARTERA_HIS
               select @w_ve_saldo_int_ini = isnull(sum(amh_acumulado - amh_pagado), 0)
               from   ca_amortizacion_his
               where  amh_operacion = @w_ve_operacion
               and    amh_secuencial = @w_secuencial_ini
               and    amh_concepto in ('INT', 'CXP_INTES', 'INTANT')
            end
            ELSE
               select @w_ve_saldo_cap_ini = 0,
                      @w_ve_saldo_int_ini = 0
            
            if @i_operacion is not null
               print '(DEF) INI_CAP ' + cast(@w_ve_saldo_cap_ini as varchar) + ' INI_INT ' + cast(@w_ve_saldo_int_ini as varchar)
            
            -- EXTRAER LOS SALDOS DE OTROS CONCEPROS DE LA COB_CARTERA_HIS
            select @w_ve_saldo_otros_ini = isnull(sum(amh_acumulado - amh_pagado), 0)
            from   ca_amortizacion_his
            where  amh_operacion = @w_ve_operacion
            and    amh_secuencial = @w_secuencial_ini
            and    amh_concepto = 'IOCPASIVAS'
         end
      end
      -- FIN DEL SALDO INICIAL
      
      -- DETERMINAR AUMENTOS Y PAGOS
      select @w_ve_nuevos_cap    = 0,
             @w_ve_pagos_cap     = 0,
             @w_ve_causacion_int = 0,
             @w_ve_pagos_int     = 0,
             @w_ve_ing_otros     = 0,
             @w_ve_pagos_otros   = 0
      
      declare
         cur_tran cursor
         for select tr_tran,        tr_fecha_mov,     dtr_codvalor,
                    dtr_concepto,   dtr_monto_mn,     tr_estado,
                    tr_secuencial,  dtr_monto_cont,   dtr_monto
             from   ca_transaccion, ca_det_trn
             where  tr_operacion    = @w_ve_operacion
             and    tr_fecha_mov    >= @i_fecha_desde
             and    dtr_operacion   = @w_ve_operacion
             and    dtr_secuencial  = tr_secuencial
             and    tr_fecha_mov   <= @i_fecha_hasta
             --
             and    tr_secuencial  > 0
             and    tr_estado      not in ('RV', 'NCO')
             union all
             select tr_tran,        tr_fecha_mov,     dtr_codvalor,
                    dtr_concepto,   dtr_monto_mn,     tr_estado,
                    tr_secuencial,  dtr_monto_cont,   dtr_monto
             from   cob_cartera_his..ca_transaccion, cob_cartera_his..ca_det_trn
             where  tr_operacion    = @w_ve_operacion
             and    tr_fecha_mov    >= @i_fecha_desde
             and    dtr_operacion   = @w_ve_operacion
             and    dtr_secuencial  = tr_secuencial
             and    tr_fecha_mov   <= @i_fecha_hasta
             --
             and    tr_secuencial  > 0
             and    tr_estado      not in ('RV', 'NCO')
             order  by tr_secuencial, tr_tran
         for read only
      
      open cur_tran
      
      fetch cur_tran
      into  @w_tr_tran,       @w_tr_fecha_mov,        @w_dtr_codvalor,
            @w_dtr_concepto,  @w_dtr_monto_mn,        @w_tr_estado,
            @w_tr_secuencial, @w_dtr_monto_cont,      @w_dtr_monto
      
      --while @@fetch_status not in (-1,0)
      while @@fetch_status = 0
      begin
         if @w_tr_estado = 'RV'
         begin
            if exists(select 1
                      from   ca_transaccion
                      where  tr_operacion = @w_ve_operacion
                      and    tr_secuencial = -@w_tr_secuencial)
            and @w_tr_tran != 'PRV'
            begin
               select @w_dtr_monto_mn = @w_dtr_monto_cont
            end
            ELSE
            begin
               goto SIG_TRAN_x_RV
            end
         end
         
         if @w_tr_tran = 'REV'
         begin
            select @w_tr_tran = tr_tran
            from   ca_transaccion
            where  tr_operacion = @w_ve_operacion
            and    tr_secuencial = -@w_tr_secuencial
            
            if @@rowcount = 0
            begin
               select @w_tr_tran = tr_tran
               from   cob_cartera_his..ca_transaccion
               where  tr_operacion = @w_ve_operacion
               and    tr_secuencial = -@w_tr_secuencial
               
               if @@rowcount = 0
               begin
                  print 'ERROR GRAVE EN TRANSACCION REV ' + cast(@w_ve_operacion as varchar) + ', NO EXISTE LA ORIGINAL  ' + cast(@w_tr_secuencial as varchar)
                  goto SIG_TRAN_x_RV
               end
            end
            
            select @w_dtr_monto_mn = -@w_dtr_monto_mn
            select @w_dtr_monto = -@w_dtr_monto
         end
         
         -- AUMENTOS DE CAPITAL
         if @w_tr_tran in ('DES', 'CRC') -- DESEMBOLSO Y CAPITALIZACIONES
         begin
            if @w_dtr_codvalor in (10000, 10010, 10020)
            begin
               select @w_ve_nuevos_cap = @w_ve_nuevos_cap + @w_dtr_monto
               if @i_operacion is not null
                  print @w_tr_tran + '|' + cast(@w_tr_secuencial as varchar) + '|' + cast(@w_dtr_monto as varchar) + '|' + @w_tr_estado + '|' + cast(@w_dtr_codvalor as varchar)
            end
            
            if @w_tr_tran = 'CRC'
            and @w_dtr_codvalor in (21000,  21010,  21020,  21090,
                                    210001, 210101, 210201, 210901,
                                    57000, 57010, 57020, 57090,
                                    22000, 22010, 22020, 22090)
            begin
               --select @w_ve_pagos_int = @w_ve_pagos_int + @w_dtr_monto_mn
               select @w_ve_pagos_int = @w_ve_pagos_int + @w_dtr_monto
            end
         end
         
         -- AUMENTOS DE INTERES o MORA
         if @w_tr_tran = 'PRV' -- in ('PRV', 'CMO')
         begin
            -- INTERES
            if @w_dtr_codvalor in (21000,  21010,  21020,  21090,
                                   210001, 210101, 210201, 210901,
                                   57000, 57010, 57020, 57090,
                                   22000, 22010, 22020, 22090)
            begin
               --select @w_ve_causacion_int = @w_ve_causacion_int + @w_dtr_monto_mn
               select @w_ve_causacion_int = @w_ve_causacion_int + @w_dtr_monto
               if @i_operacion is not null
                  print @w_tr_tran + '|' + cast(@w_tr_secuencial as varchar) + '|' + cast(@w_dtr_monto as varchar) + '|' + @w_tr_estado + '|' + cast(@w_dtr_codvalor as varchar)
            end
         end
         
         -- AJUSTES DE INTERES
         if @w_tr_tran = 'AJP'
         begin
            -- INTERES
            if @w_dtr_codvalor in (21000,  21010,  21020,  21090,
                                   210001, 210101, 210201, 210901,
                                   57000, 57010, 57020, 57090,
                                   22000, 22010, 22020, 22090)
            begin
               --select @w_ve_causacion_int = @w_ve_causacion_int - @w_dtr_monto_mn
               select @w_ve_causacion_int = @w_ve_causacion_int - @w_dtr_monto
               if @i_operacion is not null
                  print @w_tr_tran + '|' + cast(@w_tr_secuencial as varchar) + '|' + cast(@w_dtr_monto as varchar) + '|' + @w_tr_estado + '|' + cast(@w_dtr_codvalor as varchar)
            end
         end
         
         if @w_tr_tran in ('IOC')
         begin
            if @w_dtr_concepto = 'IOCPASIVAS'
            begin
               select @w_ve_ing_otros = @w_ve_ing_otros + @w_dtr_monto
            end
            
            if @w_dtr_concepto = 'CXP_INTES'
            begin
               select @w_ve_causacion_int = @w_ve_causacion_int + @w_dtr_monto
               if @i_operacion is not null
                  print @w_tr_tran + '|' + cast(@w_tr_secuencial as varchar) + '|' + cast(@w_dtr_monto as varchar) + '|' + @w_tr_estado + '|' + cast(@w_dtr_codvalor as varchar)
            end
         end
         
         -- RECUPERACION
         if @w_tr_tran in ('PAG') -- DESEMBOLSO Y CAPITALIZACIONES
         begin
            -- DE CAPITAL
            if @w_dtr_codvalor in (10000, 10010, 10020)
            begin
               select @w_ve_pagos_cap = @w_ve_pagos_cap + @w_dtr_monto
               if @i_operacion is not null
                  print @w_tr_tran + '|' + cast(@w_tr_secuencial as varchar) + '|' + cast(@w_dtr_monto as varchar) + '|' + @w_tr_estado + '|' + cast(@w_dtr_codvalor as varchar)
            end
            -- CAUSACION EN EL PREPAGO
            if @w_dtr_codvalor in (21008, 21018, 21028, 21098)
            begin
               --select @w_ve_causacion_int = @w_ve_causacion_int + @w_dtr_monto_mn
               select @w_ve_causacion_int = @w_ve_causacion_int + @w_dtr_monto
            end
            
            -- INTERES
            if @w_dtr_codvalor in (21000,  21010,  21020,  21090,
                                   210001, 210101, 210201, 210901,
                                   57000, 57010, 57020, 57090,
                                   22000, 22010, 22020, 22090)
            begin
               --select @w_ve_pagos_int = @w_ve_pagos_int + @w_dtr_monto_mn
               select @w_ve_pagos_int = @w_ve_pagos_int + @w_dtr_monto
               if @i_operacion is not null
                  print @w_tr_tran + '|' + cast(@w_tr_secuencial as varchar) + '|' + cast(@w_dtr_monto as varchar) + '|' + @w_tr_estado + '|' + cast(@w_dtr_codvalor as varchar)
            end
            
            -- OTROS CONCEPTOS
            if @w_dtr_concepto = 'IOCPASIVAS'
            begin
               select @w_ve_pagos_otros = @w_ve_pagos_otros + @w_dtr_monto
            end
         end
         
SIG_TRAN_x_RV:
         --
         fetch cur_tran
         into  @w_tr_tran,       @w_tr_fecha_mov,        @w_dtr_codvalor,
               @w_dtr_concepto,  @w_dtr_monto_mn,        @w_tr_estado,
               @w_tr_secuencial, @w_dtr_monto_cont,      @w_dtr_monto
      end
      
      close cur_tran
      deallocate cur_tran
      
      -- AHORA EL ESTADO ACTUAL
      if @w_de_saldos_hc = 'S'
      begin
         -- DETERMINAR EL SALDO A LA FECHA HASTA
         select @w_ve_saldo_cap_hoy  = isnull(sum(sc_valor), 0)
         from   ca_saldos_cartera_mensual
         where  sc_operacion = @w_ve_operacion
         and    sc_concepto  = 'CAP'
         and    sc_fecha = @i_fecha_hasta
         
         select @w_ve_saldo_int_hoy = isnull(sum(sc_valor), 0)
         from   ca_saldos_cartera_mensual
         where  sc_operacion = @w_ve_operacion
         and    sc_concepto  in ('INT', 'CXP_INTES', 'INTANT')
         and    sc_fecha = @i_fecha_hasta
         
         select @w_ve_saldo_otros_hoy = isnull(sum(sc_valor), 0)
         from   ca_saldos_cartera_mensual
         where  sc_operacion = @w_ve_operacion
         and    sc_concepto  = 'IOCPASIVAS'
         and    sc_fecha = @i_fecha_hasta
      end
      ELSE
      begin
         if @w_op_moneda = 0
            select @w_cotizacion = 1
         else
         begin
            exec sp_buscar_cotizacion
                 @i_moneda       = @w_op_moneda,
                 @i_fecha        = @w_op_fecha_ult_proceso,
                 @o_cotizacion   = @w_cotizacion out
         end
         
         -- EXTRAER LOS SALDOS DE CAPITAL
         select @w_ve_saldo_cap_hoy = isnull(sum(am_acumulado - am_pagado), 0) ---* @w_cotizacion
         from   ca_amortizacion
         where  am_operacion = @w_ve_operacion
         and    am_concepto = 'CAP'
         
         -- EXTRAER LOS SALDOS DE INTERES
         select @w_ve_saldo_int_hoy = isnull(sum(am_acumulado - am_pagado), 0) --* @w_cotizacion
         from   ca_amortizacion
         where  am_operacion = @w_ve_operacion
         and    am_concepto in ('INT', 'CXP_INTES', 'INTANT')
         
         -- EXTRAER LOS SALDOS DE OTROS
         select @w_ve_saldo_otros_hoy = isnull(sum(am_acumulado - am_pagado), 0) --* @w_cotizacion
         from   ca_amortizacion
         where  am_operacion = @w_ve_operacion
         and    am_concepto = 'IOCPASIVAS'
         
         if @w_op_estado in (0, 6, 99)
         begin
            declare
               @w_sec_des  int
            
            select @w_sec_des = tr_secuencial
            from   ca_transaccion
            where  tr_operacion = @w_ve_operacion
            and    tr_tran      = 'DES'
            and    tr_estado   in ('ING', 'PVA', 'CON')
            
            if @@rowcount = 0
               select @w_ve_saldo_cap_hoy = 0,
                      @w_ve_saldo_int_hoy = 0,
                      @w_ve_saldo_otros_hoy = 0
         end
      end
      
      BEGIN TRAN
      
      if @i_revision = 'S' -- BORRAR EL ANTERIOR
      begin
         delete ca_verificacion
         where ve_operacion = @w_ve_operacion
      end
      
      if abs(@w_ve_saldo_cap_hoy   - (@w_ve_saldo_cap_ini   + @w_ve_nuevos_cap    - @w_ve_pagos_cap))>1
      or abs(@w_ve_saldo_int_hoy   - (@w_ve_saldo_int_ini   + @w_ve_causacion_int - @w_ve_pagos_int))>1
      or abs(@w_ve_saldo_otros_hoy - (@w_ve_saldo_otros_ini + @w_ve_ing_otros     - @w_ve_pagos_otros))>1
      begin
         select @w_ve_cuadra = 'NO'
      end
      ELSE
         select @w_ve_cuadra = 'SI'
      
      if @i_operacion is not null
         print '(WRT) INI_CAP      INI_INT '+ cast(@w_ve_saldo_cap_ini as varchar) +  cast(@w_ve_saldo_int_ini as varchar)
      
      insert into ca_verificacion
      values(@w_ve_operacion,
             @w_ve_saldo_cap_ini,
             @w_ve_saldo_int_ini,
             @w_ve_saldo_otros_ini,
             
             @w_ve_nuevos_cap,
             @w_ve_pagos_cap,
             @w_ve_causacion_int,
             @w_ve_pagos_int,
             @w_ve_ing_otros,
             @w_ve_pagos_otros,
             
             @w_ve_saldo_cap_hoy,
             @w_ve_saldo_int_hoy,
             @w_ve_saldo_otros_hoy,
             --@i_fecha_desde,
             --@i_fecha_hasta,
             @w_ve_cuadra)
      
      if @@error != 0
      begin
         while @@trancount > 0 ROLLBACK
         print 'operacion' + cast(@w_ve_operacion as varchar) + 'secuencial' + cast(@w_secuencial_ini as varchar)
      end
      
      COMMIT
      --
      fetch cur_operacion
      into  @w_ve_operacion, @w_op_estado, @w_op_fecha_ult_proceso, @w_op_moneda
   end
   
   close cur_operacion
   deallocate cur_operacion
   
   if @p_proceso is not null
   begin
      BEGIN TRAN
      
      update ca_paralelo_tmp
      set    estado = 'T'
      where  programa = @p_programa
      and    proceso = @p_proceso
      
      COMMIT
   end
   
   return 0
end
go

