use cob_conta
go


if exists (select 1 from sysobjects where name = 'sp_simut')
   drop proc sp_simut
go

create proc sp_simut
(
  @t_show_version  bit         = 0,
  @i_param1       tinyint        , --empresa  
  @i_param2       datetime        , --empresa  
  -- parametros para registro del log de ejcucion
  @i_sarta         int         = null,
  @i_batch         int         = null,
  @i_secuencial    int         = null,
  @i_corrida       int         = null,
  @i_intento       int         = null
)
as
declare @w_return int,
        @w_estado_corte char(1),
        @w_area         tinyint,
        @w_descripcion  varchar(50),
        @w_oficina      smallint,
        @w_moneda       varchar(4), 
        @w_cuenta       varchar(1), 
        @w_saldo        money, 
        @w_saldome      money,
        @w_corte        int,
        @w_periodo      int,
        @w_detalle      int,
        @w_saldomn4     money,         
        @w_saldomn5     money,
        @w_tot_debito   money,
        @w_saldome4     money,
        @w_saldome5     money,
        @w_tot_credito  money,
        @w_tot_debito_me   money,
        @w_tot_credito_me  money,
        @w_totmn           money,
        @w_totme           money,
        @w_tcomprobante    int,
        @w_ctaproc         varchar(20),
        @w_ctaasoc         varchar(20)
        
        
        
   Select @w_corte   = co_corte,   
          @w_periodo = co_periodo 
   from cob_conta..cb_corte
   where co_empresa = @i_param1
   and co_fecha_ini <= @i_param2
   and co_fecha_fin >= @i_param2
  
   select @w_estado_corte = co_estado 
   from cob_conta..cb_corte
   where co_empresa = @i_param1
   and   co_periodo = @w_periodo
   and   co_corte   = @w_corte

   Select @w_area = isnull(pa_tinyint,31)  
   from cobis..cl_parametro
   where pa_nemonico = 'ARCU'
   and   pa_producto = 'CON'

   select @w_descripcion = 'CALCULO DE UTILIDAD PARA BALANCE DIARIO' 
   begin tran
   if @w_estado_corte = 'A'
   begin
   --A
         --primer select
         declare cur_simut cursor for
         Select 
         sa_oficina ,                 
         convert(varchar,cu_moneda)  ,
         substring(sa_cuenta,1,1)    ,
         sum(sa_saldo)                , 
         sum(sa_saldo_me)                       
         from  cb_cuenta, cb_saldo
         where sa_empresa = 1
         and   sa_periodo >= 0
         and   sa_corte >= 0
         and   sa_oficina >= 0
         and   sa_area >= 0
         and   sa_cuenta  = cu_cuenta
         and   cu_empresa  = 1
         and   (cu_cuenta like '4%' or cu_cuenta like '5%')
         and   cu_cuenta not in (select co_cuenta from cob_conta_super..sb_cuenta_ord
                                 where co_empresa = 1
                                 and   co_proceso = 28705)
         and   cu_movimiento = 'S'
         group by sa_oficina,cu_moneda,substring(sa_cuenta,1,1)
         
        for read only
         open cur_simut
         fetch cur_simut
         into @w_oficina, @w_moneda, @w_cuenta, @w_saldo, @w_saldome
         
         while @@FETCH_STATUS = 0  
         begin
            select @w_detalle = 0,                
                   @w_tot_debito = 0,
                   @w_tot_credito = 0,
                   @w_tot_debito_me = 0,
                   @w_tot_credito_me = 0                                
                
            if @w_cuenta = '4'
            begin
               set @w_saldomn4 = @w_saldo
               set @w_saldome4 = @w_saldome  
            end
            else
            begin
               if @w_cuenta = '5'
               begin
                  set @w_saldomn5 = @w_saldo
                  set @w_saldome5 = @w_saldome
               end
            end
  
            --Ingreso comprobante
            exec @w_return = sp_comprobt 
               @t_trn          = 6111,
               @i_automatico   = 6010,
               @i_operacion    = 'I',
               @i_modo         = 0,
               @i_empresa      = @i_param1,
               @i_oficina_orig = @w_oficina,
               @i_area_orig    = @w_area,
               @i_fecha_tran   = @i_param2, 
               @i_fecha_dig    = @i_param2,
               @i_fecha_mod    = @i_param2,
               @i_digitador    = 'sa',
               @i_descripcion  = @w_descripcion,
               @i_mayorizado   = 'N',
               @i_mayoriza     = 'N',
               @i_autorizado   = 'S',
               @i_autorizante  = 'sa',   
               @i_reversado    = 'N' ,
               @o_tcomprobante = @w_tcomprobante out
               
               if @w_return <> 0
               begin
                  goto Error
               end
         
               select   @w_ctaproc  = cp_cuenta,
                        @w_ctaasoc  = ca_cta_asoc
               from cb_cuenta_proceso, cb_cuenta_asociada
               where cp_empresa   = @i_param1
               and   cp_proceso   = 6010
               and   cp_oficina   >= 0
               and   cp_area      >= 0
               and   cp_cuenta    = ca_cuenta
               and   ca_empresa   = @i_param1
               and   ca_proceso   = cp_proceso
               and   ca_cuenta    = cp_cuenta
               and   ca_oficina   >= 0
               and   ca_area      >= 0
               and   ca_secuencial >= 0
               and   cp_condicion = @w_moneda
               and   cp_texto     = 'N'
                                 
               if @w_ctaproc <> '' and @w_ctaasoc <> ''                                            
               begin                  
                  set @w_totmn = round(@w_saldomn4, 2) + round(@w_saldomn5, 2)
                  set @w_totme = round(@w_saldome4, 2) + round(@w_saldome5, 2)                  
                  
                  if @w_totmn < 0
                  begin                       
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + @w_totmn,
                            @w_tot_credito   = @w_tot_credito + 0,
                            @w_tot_debito_me = @w_tot_debito_me + @w_totme,
                            @w_tot_credito_me= @w_tot_credito_me + 0
                
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaasoc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = 0,
                     @i_debito       = @w_totmn,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = 0,
                     @i_debito_me    = @w_totme,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'C', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error      
                        
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + 0,
                            @w_tot_credito   = @w_tot_credito + @w_totmn,
                            @w_tot_debito_me = @w_tot_debito_me + 0,
                            @w_tot_credito_me= @w_tot_credito_me + @w_totme
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaproc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = @w_totmn,
                     @i_debito       = 0,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = @w_totme,
                     @i_debito_me    = 0,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'V', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                  end      
                  
                  if @w_totmn > 0
                  begin          
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + @w_totmn,
                            @w_tot_credito   = @w_tot_credito + 0,
                            @w_tot_debito_me = @w_tot_debito_me + @w_totme,
                            @w_tot_credito_me= @w_tot_credito_me + 0
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaproc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = 0,
                     @i_debito       = @w_totmn,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = 0,
                     @i_debito_me    = @w_totme,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'C', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + 0,
                            @w_tot_credito   = @w_tot_credito + @w_totmn,
                            @w_tot_debito_me = @w_tot_debito_me + 0,
                            @w_tot_credito_me= @w_tot_credito_me + @w_totme
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaasoc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = @w_totmn,
                     @i_debito       = 0,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = @w_totme,
                     @i_debito_me    = 0,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'V', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                  end                   
               end
               
               exec @w_return = sp_compmig
                  @t_trn            = 6342,
                  @i_operacion      = 'I',
                  @i_empresa        = @i_param1,
                  @i_fecha_tran     = @i_param2,
                  @i_comprobante    = @w_tcomprobante,
                  @i_detalles       = @w_detalle,
                  @i_tot_debito     = @w_tot_debito,
                  @i_tot_credito    = @w_tot_credito,
                  @i_tot_debito_me  = @w_tot_debito_me,
                  @i_tot_credito_me = @w_tot_credito_me,
                  @i_mayorizar      = 'N',
                  @i_oficina_orig   = @w_oficina
                  
               if @w_return <> 0
                  goto Error

            fetch cur_simut
            into @w_oficina, @w_moneda, @w_cuenta, @w_saldo, @w_saldome   
         end --1 while
         close cur_simut
         deallocate cur_simut
         
         --segundo select
         declare cur_simut cursor for
         Select   sa_oficina                     ,
                  convert(varchar,cu_moneda)     ,
                  substring(sa_cuenta,1,1)       ,
                  sum(sa_saldo)    ,              
                  sum(sa_saldo_me)               
         from  cb_cuenta, cb_saldo
         where sa_empresa = 1
         and   sa_periodo >= 0
         and   sa_corte >= 0
         and   sa_oficina >= 0
         and   sa_area >= 0
         and   sa_cuenta  = cu_cuenta
         and   cu_empresa  = 1
         and   (cu_cuenta like '4%' or cu_cuenta like '5%')
         and   cu_cuenta in (select co_cuenta from cob_conta_super..sb_cuenta_ord
                                 where co_empresa = 1
                                 and   co_proceso = 28705)
         and   cu_movimiento = 'S'
         group by sa_oficina,cu_moneda,substring(sa_cuenta,1,1)
         
         for read only
         open cur_simut
         fetch cur_simut
         into @w_oficina, @w_moneda, @w_cuenta, @w_saldo, @w_saldome
         
         while @@FETCH_STATUS = 0  
         begin
            select @w_detalle = 0,                
                   @w_tot_debito = 0,
                   @w_tot_credito = 0,
                   @w_tot_debito_me = 0,
                   @w_tot_credito_me = 0
                
            if @w_cuenta = '4'
            begin
               set @w_saldomn4 = @w_saldo
               set @w_saldome4 = @w_saldome  
            end
            else
            begin
               if @w_cuenta = '5'
               begin
                  set @w_saldomn5 = @w_saldo
                  set @w_saldome5 = @w_saldome
               end
            end
  
            --Ingreso comprobante
            exec @w_return = sp_comprobt 
               @t_trn          = 6111,
               @i_automatico   = 6010,
               @i_operacion    = 'I',
               @i_modo         = 0,
               @i_empresa      = @i_param1,
               @i_oficina_orig = @w_oficina,
               @i_area_orig    = @w_area,
               @i_fecha_tran   = @i_param2, 
               @i_fecha_dig    = @i_param2,
               @i_fecha_mod    = @i_param2,
               @i_digitador    = 'sa',
               @i_descripcion  = @w_descripcion,
               @i_mayorizado   = 'N',
               @i_mayoriza     = 'N',
               @i_autorizado   = 'S',
               @i_autorizante  = 'sa',   
               @i_reversado    = 'N' ,
               @o_tcomprobante = @w_tcomprobante out
               
               if @w_return <> 0
               begin
                  goto Error
               end
         
               select  @w_ctaproc  = cp_cuenta,
                       @w_ctaasoc  = ca_cta_asoc
               from cb_cuenta_proceso, cb_cuenta_asociada
                                 where cp_empresa   = @i_param1
                                 and   cp_proceso   = 6010
                                 and   cp_oficina   >= 0
                                 and   cp_area      >= 0
                                 and   cp_cuenta    = ca_cuenta
                                 and   ca_empresa   = @i_param1
                                 and   ca_proceso   = cp_proceso
                                 and   ca_cuenta    = cp_cuenta
                                 and   ca_oficina   >= 0
                                 and   ca_area      >= 0
                                 and   ca_secuencial >= 0
                                 and   cp_condicion = @w_moneda
                                 and   cp_texto     = 'C'
                                 
               if @w_ctaproc <> '' and @w_ctaasoc <> ''                                            
               begin                  
                  set @w_totmn = round(@w_saldomn4, 2) + round(@w_saldomn5, 2)
                  set @w_totme = round(@w_saldome4, 2) + round(@w_saldome5, 2)                                              
                  
                  if @w_totmn < 0
                  begin                       
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + @w_totmn,
                            @w_tot_credito   = @w_tot_credito + 0,
                            @w_tot_debito_me = @w_tot_debito_me + @w_totme,
                            @w_tot_credito_me= @w_tot_credito_me + 0
                
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaasoc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = 0,
                     @i_debito       = @w_totmn,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = 0,
                     @i_debito_me    = @w_totme,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'C', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error      
                        
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + 0,
                            @w_tot_credito   = @w_tot_credito + @w_totmn,
                            @w_tot_debito_me = @w_tot_debito_me + 0,
                            @w_tot_credito_me= @w_tot_credito_me + @w_totme
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaproc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = @w_totmn,
                     @i_debito       = 0,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = @w_totme,
                     @i_debito_me    = 0,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'V', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                  end      
                  
                  if @w_totmn > 0
                  begin          
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + @w_totmn,
                            @w_tot_credito   = @w_tot_credito + 0,
                            @w_tot_debito_me = @w_tot_debito_me + @w_totme,
                            @w_tot_credito_me= @w_tot_credito_me + 0
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaproc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = 0,
                     @i_debito       = @w_totmn,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = 0,
                     @i_debito_me    = @w_totme,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'C', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + 0,
                            @w_tot_credito   = @w_tot_credito + @w_totmn,
                            @w_tot_debito_me = @w_tot_debito_me + 0,
                            @w_tot_credito_me= @w_tot_credito_me + @w_totme
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaasoc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = @w_totmn,
                     @i_debito       = 0,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = @w_totme,
                     @i_debito_me    = 0,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'V', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                  end                   
               end
               
               exec @w_return = sp_compmig
                  @t_trn            = 6342,
                  @i_operacion      = 'I',
                  @i_empresa        = @i_param1,
                  @i_fecha_tran     = @i_param2,
                  @i_comprobante    = @w_tcomprobante,
                  @i_detalles       = @w_detalle,
                  @i_tot_debito     = @w_tot_debito,
                  @i_tot_credito    = @w_tot_credito,
                  @i_tot_debito_me  = @w_tot_debito_me,
                  @i_tot_credito_me = @w_tot_credito_me,
                  @i_mayorizar      = 'N',
                  @i_oficina_orig   = @w_oficina
               if @w_return <> 0
                  goto Error

            fetch cur_simut
            into @w_oficina, @w_moneda, @w_cuenta, @w_saldo, @w_saldome   
         end --1 while
         close cur_simut
         deallocate cur_simut
   --A
   end
  else
  begin
    truncate table cb_hist_saldo_tmp
    if exists(Select 1 from sysindexes
               where name = 'i_empresa_cuenta1_tmp')
      drop index cb_hist_saldo_tmp.i_empresa_cuenta1_tmp
         
    insert into cb_hist_saldo_tmp
      select * from cob_conta_his..cb_hist_saldo
      where hi_empresa = @i_param1
      and   hi_periodo = @w_periodo
      and   hi_corte   = @w_corte
      
    if @@ERROR <> 0
    begin
         select @w_return = @@ERROR
         goto Error
    end
      
    CREATE NONCLUSTERED INDEX i_empresa_cuenta1_tmp
    ON cb_hist_saldo_tmp(hi_empresa,hi_periodo,hi_corte,hi_cuenta,hi_oficina,hi_area)
      
         --primer select
         declare cur_simut cursor for
         Select
         hi_oficina,                
         convert(varchar,cu_moneda),
         substring(hi_cuenta,1,1),  
         sum(hi_saldo),             
         sum(hi_saldo_me)                  
         from  cb_cuenta, cb_hist_saldo_tmp
         where hi_empresa = @i_param1
         and   hi_periodo >= 0
         and   hi_corte >= 0
         and   hi_cuenta  = cu_cuenta
         and   hi_oficina >= 0
         and   hi_area >= 0
         and   cu_empresa  = @i_param1
         and   (cu_cuenta like '4%' or cu_cuenta like '5%')
         and   cu_cuenta not in (select co_cuenta from cob_conta_super..sb_cuenta_ord
                                 where co_empresa = @i_param1
                                 and   co_proceso = 28705)
         and   cu_movimiento = 'S'
         group by hi_oficina,cu_moneda,substring(hi_cuenta,1,1)
         
         for read only
         open cur_simut
         fetch cur_simut
         into @w_oficina, @w_moneda, @w_cuenta, @w_saldo, @w_saldome
         
         while @@FETCH_STATUS = 0  
         begin
            select @w_detalle = 0,                
                   @w_tot_debito = 0,
                   @w_tot_credito = 0,
                   @w_tot_debito_me = 0,
                   @w_tot_credito_me = 0
                
            if @w_cuenta = '4'
            begin
               set @w_saldomn4 = @w_saldo
               set @w_saldome4 = @w_saldome  
            end
            else
            begin
               if @w_cuenta = '5'
               begin
                  set @w_saldomn5 = @w_saldo
                  set @w_saldome5 = @w_saldome
               end
            end
  
            --Ingreso comprobante
            exec @w_return = sp_comprobt 
               @t_trn          = 6111,
               @i_automatico   = 6010,
               @i_operacion    = 'I',
               @i_modo         = 0,
               @i_empresa      = @i_param1,
               @i_oficina_orig = @w_oficina,
               @i_area_orig    = @w_area,
               @i_fecha_tran   = @i_param2, 
               @i_fecha_dig    = @i_param2,
               @i_fecha_mod    = @i_param2,
               @i_digitador    = 'sa',
               @i_descripcion  = @w_descripcion,
               @i_mayorizado   = 'N',
               @i_mayoriza     = 'N',
               @i_autorizado   = 'S',
               @i_autorizante  = 'sa',   
               @i_reversado    = 'N' ,
               @o_tcomprobante = @w_tcomprobante out
               
               if @w_return <> 0
               begin
                  goto Error
               end
         
               select   @w_ctaproc  = cp_cuenta,
                        @w_ctaasoc  = ca_cta_asoc
               from cb_cuenta_proceso, cb_cuenta_asociada
                                 where cp_empresa   = @i_param1
                                 and   cp_proceso   = 6010
                                 and   cp_oficina   >= 0
                                 and   cp_area      >= 0
                                 and   cp_cuenta    = ca_cuenta
                                 and   ca_empresa   = @i_param1
                                 and   ca_proceso   = cp_proceso
                                 and   ca_cuenta    = cp_cuenta
                                 and   ca_oficina   >= 0
                                 and   ca_area      >= 0
                                 and   ca_secuencial >= 0
                                 and   cp_condicion = @w_moneda
                                 and   cp_texto     = 'N'
                                 
               if @w_ctaproc <> '' and @w_ctaasoc <> ''                                            
               begin                  
                  set @w_totmn = round(@w_saldomn4, 2) + round(@w_saldomn5, 2)
                  set @w_totme = round(@w_saldome4, 2) + round(@w_saldome5, 2)                                
                  
                  if @w_totmn < 0
                  begin                       
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + @w_totmn,
                            @w_tot_credito   = @w_tot_credito + 0,
                            @w_tot_debito_me = @w_tot_debito_me + @w_totme,
                            @w_tot_credito_me= @w_tot_credito_me + 0
                
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaasoc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = 0,
                     @i_debito       = @w_totmn,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = 0,
                     @i_debito_me    = @w_totme,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'C', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error      
                        
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + 0,
                            @w_tot_credito   = @w_tot_credito + @w_totmn,
                            @w_tot_debito_me = @w_tot_debito_me + 0,
                            @w_tot_credito_me= @w_tot_credito_me + @w_totme
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaproc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = @w_totmn,
                     @i_debito       = 0,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = @w_totme,
                     @i_debito_me    = 0,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'V', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                  end      
                  
                  if @w_totmn > 0
                  begin          
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + @w_totmn,
                            @w_tot_credito   = @w_tot_credito + 0,
                            @w_tot_debito_me = @w_tot_debito_me + @w_totme,
                            @w_tot_credito_me= @w_tot_credito_me + 0
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaproc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = 0,
                     @i_debito       = @w_totmn,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = 0,
                     @i_debito_me    = @w_totme,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'C', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + 0,
                            @w_tot_credito   = @w_tot_credito + @w_totmn,
                            @w_tot_debito_me = @w_tot_debito_me + 0,
                            @w_tot_credito_me= @w_tot_credito_me + @w_totme
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaasoc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = @w_totmn,
                     @i_debito       = 0,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = @w_totme,
                     @i_debito_me    = 0,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'V', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                  end                   
               end
               
               exec @w_return = sp_compmig
                  @t_trn            = 6342,
                  @i_operacion      = 'I',
                  @i_empresa        = @i_param1,
                  @i_fecha_tran     = @i_param2,
                  @i_comprobante    = @w_tcomprobante,
                  @i_detalles       = @w_detalle,
                  @i_tot_debito     = @w_tot_debito,
                  @i_tot_credito    = @w_tot_credito,
                  @i_tot_debito_me  = @w_tot_debito_me,
                  @i_tot_credito_me = @w_tot_credito_me,
                  @i_mayorizar      = 'N',
                  @i_oficina_orig   = @w_oficina
               if @w_return <> 0
                  goto Error

               
         fetch cur_simut
         into @w_oficina, @w_moneda, @w_cuenta, @w_saldo, @w_saldome   
         end --1 while
         close cur_simut
         deallocate cur_simut
         
         
         --segundo select
         declare cur_simut cursor for
         Select
         hi_oficina,                
         convert(varchar,cu_moneda),
         substring(hi_cuenta,1,1),  
         sum(hi_saldo),             
         sum(hi_saldo_me)                  
         from  cb_cuenta, cb_hist_saldo_tmp
         where hi_empresa = @i_param1
         and   hi_periodo >= 0
         and   hi_corte >= 0
         and   hi_cuenta  = cu_cuenta
         and   hi_oficina >= 0
         and   hi_area >= 0
         and   cu_empresa  = @i_param1
         and   (cu_cuenta like '4%' or cu_cuenta like '5%')
         and   cu_cuenta in (select co_cuenta from cob_conta_super..sb_cuenta_ord
                                 where co_empresa = @i_param1
                                 and   co_proceso = 28705)
         and   cu_movimiento = 'S'
         group by hi_oficina,cu_moneda,substring(hi_cuenta,1,1)
         
         for read only
         open cur_simut
         fetch cur_simut
         into @w_oficina, @w_moneda, @w_cuenta, @w_saldo, @w_saldome
         
         while @@FETCH_STATUS = 0  
         begin
            select @w_detalle = 0,                
                   @w_tot_debito = 0,
                   @w_tot_credito = 0,
                   @w_tot_debito_me = 0,
                   @w_tot_credito_me = 0
                
                
                
            if @w_cuenta = '4'
            begin
               set @w_saldomn4 = @w_saldo
               set @w_saldome4 = @w_saldome  
            end
            else
            begin
               if @w_cuenta = '5'
               begin
                  set @w_saldomn5 = @w_saldo
                  set @w_saldome5 = @w_saldome
               end
            end
  
            --Ingreso comprobante
            exec @w_return = sp_comprobt 
               @t_trn          = 6111,
               @i_automatico   = 6010,
               @i_operacion    = 'I',
               @i_modo         = 0,
               @i_empresa      = @i_param1,
               @i_oficina_orig = @w_oficina,
               @i_area_orig    = @w_area,
               @i_fecha_tran   = @i_param2, 
               @i_fecha_dig    = @i_param2,
               @i_fecha_mod    = @i_param2,
               @i_digitador    = 'sa',
               @i_descripcion  = @w_descripcion,
               @i_mayorizado   = 'N',
               @i_mayoriza     = 'N',
               @i_autorizado   = 'S',
               @i_autorizante  = 'sa',   
               @i_reversado    = 'N' ,
               @o_tcomprobante = @w_tcomprobante out
               
               if @w_return <> 0
               begin
                  goto Error
               end
         
               select 
                        @w_ctaproc  = cp_cuenta,
                        @w_ctaasoc  = ca_cta_asoc
               from cb_cuenta_proceso, cb_cuenta_asociada
                                 where cp_empresa   = @i_param1
                                 and   cp_proceso   = 6010
                                 and   cp_oficina   >= 0
                                 and   cp_area      >= 0
                                 and   cp_cuenta    = ca_cuenta
                                 and   ca_empresa   = @i_param1
                                 and   ca_proceso   = cp_proceso
                                 and   ca_cuenta    = cp_cuenta
                                 and   ca_oficina   >= 0
                                 and   ca_area      >= 0
                                 and   ca_secuencial >= 0
                                 and   cp_condicion = @w_moneda
                                 and   cp_texto     = 'C'
                                 
               if @w_ctaproc <> '' and @w_ctaasoc <> ''                                            
               begin                  
                  set @w_totmn = round(@w_saldomn4, 2) + round(@w_saldomn5, 2)
                  set @w_totme = round(@w_saldome4, 2) + round(@w_saldome5, 2)                                                    
                  
                  if @w_totmn < 0
                  begin                       
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + @w_totmn,
                            @w_tot_credito   = @w_tot_credito + 0,
                            @w_tot_debito_me = @w_tot_debito_me + @w_totme,
                            @w_tot_credito_me= @w_tot_credito_me + 0
                
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaasoc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = 0,
                     @i_debito       = @w_totmn,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = 0,
                     @i_debito_me    = @w_totme,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'C', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error      
                        
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + 0,
                            @w_tot_credito   = @w_tot_credito + @w_totmn,
                            @w_tot_debito_me = @w_tot_debito_me + 0,
                            @w_tot_credito_me= @w_tot_credito_me + @w_totme
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaproc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = @w_totmn,
                     @i_debito       = 0,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = @w_totme,
                     @i_debito_me    = 0,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'V', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                  end      
                  
                  if @w_totmn > 0
                  begin          
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + @w_totmn,
                            @w_tot_credito   = @w_tot_credito + 0,
                            @w_tot_debito_me = @w_tot_debito_me + @w_totme,
                            @w_tot_credito_me= @w_tot_credito_me + 0
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaproc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = 0,
                     @i_debito       = @w_totmn,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = 0,
                     @i_debito_me    = @w_totme,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'C', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                     select @w_detalle = @w_detalle + 1,
                            @w_tot_debito    = @w_tot_debito + 0,
                            @w_tot_credito   = @w_tot_credito + @w_totmn,
                            @w_tot_debito_me = @w_tot_debito_me + 0,
                            @w_tot_credito_me= @w_tot_credito_me + @w_totme
                            
                     exec @w_return = sp_asientot
                     @t_trn          = 6341,
                     @i_operacion    = 'I',
                     @i_modo         = 0,
                     @i_empresa      = @i_param1,
                     @i_fecha_tran   = @i_param2,
                     @i_comprobante  = @w_tcomprobante,
                     @i_asiento      = @w_detalle, 
                     @i_cuenta       = @w_ctaasoc,
                     @i_oficina_dest = @w_oficina,
                     @i_area_dest    = @w_area,
                     @i_credito      = @w_totmn,
                     @i_debito       = 0,
                     @i_concepto	    = @w_descripcion,
                     @i_credito_me   = @w_totme,
                     @i_debito_me    = 0,
                     @i_cotizacion   = 0, 
                     @i_tipo_doc     = 'V', 
                     @i_tipo_tran    = 'N',
                     @i_mayorizado   = 'N',                  
                     @i_oficina_orig = @w_oficina
                  
                     if @w_return <> 0
                        goto Error                  
                     
                  end                   
               end
               
                  exec @w_return = sp_compmig
                     @t_trn            = 6342,
                     @i_operacion      = 'I',
                     @i_empresa        = @i_param1,
                     @i_fecha_tran     = @i_param2,
                     @i_comprobante    = @w_tcomprobante,
                     @i_detalles       = @w_detalle,
                     @i_tot_debito     = @w_tot_debito,
                     @i_tot_credito    = @w_tot_credito,
                     @i_tot_debito_me  = @w_tot_debito_me,
                     @i_tot_credito_me = @w_tot_credito_me,
                     @i_mayorizar      = 'N',
                     @i_oficina_orig   = @w_oficina
         if @w_return <> 0
            goto Error

               
         fetch cur_simut
         into @w_oficina, @w_moneda, @w_cuenta, @w_saldo, @w_saldome   
         end --1 while
         
         close cur_simut
         deallocate cur_simut         
   end
  Commit Tran
  return 0
  
Error:
   rollback tran
   print 'ERROR EN LA EJECUCION SP SP_SIMUT ' + convert(varchar,@w_return)
   return @w_return
 go
 
 