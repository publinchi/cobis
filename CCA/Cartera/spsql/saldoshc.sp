/************************************************************************/
/*   Archivo:              saldoshc.sp                                  */
/*   Stored procedure:     sp_saldos_hc                                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian Quintero                              */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Saldos de Cartera por diferentes conceptos para Herramienta de     */
/*   Cuadre Contable.  Tabla cob_ccontable..cco_boc.                    */
/*                            MODIFICACIONES                            */
/*      10/OCT/2005    FDO CARVAJAL    DIFERIDOS REQ 389                */
/*      17/FEB/2006    F.Q             TRASLADO DE INT REQ 379          */
/*      27/JUN/2006    Ivan Jimenez    Func. de renovaciones para       */
/*                                     registro cuenta 272035 REQ 498   */
/*      17/apr/2007    FQ              DEFECTO 8127                     */
/*      Jun/07/2007    EP              DEFECTO 8297  seleccionar est 0  */
/*                                     NR-293y 8297                     */
/*                                     para rubros fpago 'M' = IOC      */
/*      29/OCT/2010   Elcira Pelaez B. DIFERIDOS REQ 059                */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_saldos_hc')
   drop proc sp_saldos_hc
go

create proc sp_saldos_hc
@i_fecha      datetime,
@i_banco      cuenta = null,
@i_proceso    int    = null
as
declare
   @w_error          int,
   @w_cont           int,
   @w_operacionca    int,
   @w_op_banco       cuenta,
   @w_op_moneda      int,
   @w_op_cap_susxcor float,
   @w_op_estado      int,
   @w_op_suspendio   char(1),
   --
   @w_cotizacion     float,
   @w_concepto_int   catalogo,
   @w_concepto_cap   catalogo,
   --
   @w_op_moneda_ult  int,
   @w_sec_ult_sus    int,
   @w_num_dec        int,
   @w_otra_mon_nal   int,
   @w_toperacion     catalogo,
   @w_perfil         catalogo,
   @w_toperacion_ult catalogo,
   @w_fecha_proceso  datetime,
   --
   @w_otr_codigo     int,
   @w_otr_concepto   catalogo,
   @w_otr_fecha      datetime,
   @w_otr_valor      float,
   @w_otr_estado     int,
   @w_cotizacion_vig float,
   @w_fecha_suspenso datetime,
   
   @w_ro_concepto    catalogo,
   @w_ro_tipo_rubro  char(1),
   @w_num_dec_mn     tinyint,
   
   @w_op_migrada     cuenta,
   @w_op_naturaleza  char(1),
   
   @w_fecha_reg      datetime,
   @w_fecha_aux      datetime,
   @w_ciudad         int,
   
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

   select @p_programa      = 'saldoshc',
          @p_proceso       = @i_proceso, -- SOLO POR MANTENER EL ESTANDAR DEL NOMBRE DE VARIABLES DEL PARALELO
          @p_ult_update    = getdate(),
          @p_tiempo_update = 15
   
   -- SELECCIONAR LA FECHA DE PROCESO
   select @w_fecha_aux = dateadd(dd,1,@i_fecha)
   
   select @w_ciudad = pa_int 
   from   cobis..cl_parametro
   where  pa_nemonico = 'CIUN'
   and    pa_producto = 'ADM'
   
   exec cob_cartera..sp_dia_habil 
        @i_fecha  = @w_fecha_aux,
        @i_ciudad = @w_ciudad,
        @o_fecha  = @w_fecha_aux out
   
   if datepart(mm,@w_fecha_aux) <> datepart(mm,@i_fecha)
   begin 
      select @w_fecha_aux = convert(varchar(2),datepart(mm,@w_fecha_aux)) + '/01/' + convert(varchar(4),datepart(yy,@w_fecha_aux))
      select @w_fecha_reg = dateadd(dd,-1,@w_fecha_aux)
   end
   else
      select @w_fecha_reg = @i_fecha   
   
   --- PARALELISMO
   if @p_proceso is not null
   begin
      select @p_operacion_ini  = operacion_ini,
             @p_operacion_fin  = operacion_fin,
             @p_estado         = estado,
             @p_cont_operacion = isnull(procesados, @p_operacion_fin - @p_operacion_ini)
      from   ca_paralelo_tmp
      where  programa = @p_programa
      and    proceso  = @p_proceso
   end
   
   -- INICIO IFJ REQ 498
   delete tmp_cursor_operacion 
   from  tmp_cursor_operacion --(index tmp_cursor_operacion_1)
   where op_spid = @@spid
   -- FIN IFJ REQ 498

   select @w_cont = count(1)
   from   ca_paralelo_tmp
   where  programa = @p_programa
   and    proceso  = @p_proceso

   print 'Contador : ' + cast(@w_cont as varchar)
   
   
   select  @w_cont = 0,
           @w_error = 0,
           @w_op_moneda_ult = -1,
           @w_toperacion    = '-'
   
   -- ACTUALIZACION DE PARALELISMO
   if @i_banco is null
   begin
      insert into tmp_cursor_operacion --#ca_operacion  -- IFJ REQ 498   
      select @@spid, op_banco, op_operacion, op_moneda, -- IFJ REQ 498   
             isnull(op_cap_susxcor, 0),
             op_estado,
             op_toperacion,
             op_fecha_ult_proceso,
             op_suspendio,
             op_fecha_suspenso,
             op_migrada,
             op_naturaleza
      from   ca_operacion a
      where not exists (select 1 from ca_saldos_cartera
                        where sc_operacion = a.op_operacion)
      and  op_estado in (1, 2, 4, 9, 10, 100)                   -- REQ 379 IFJ 22/Nov/2005
      and  op_operacion between @p_operacion_ini and @p_operacion_fin
      
      select @p_cont_operacion = @@rowcount
   end
   ELSE
   begin
      select @p_estado = 'P'
      insert into tmp_cursor_operacion --#ca_operacion  -- IFJ REQ 498
      select @@spid, op_banco, op_operacion, op_moneda, -- IFJ REQ 498
             isnull(op_cap_susxcor, 0),
             op_estado,
             op_toperacion,
             op_fecha_ult_proceso,
             op_suspendio,
             op_fecha_suspenso,
             op_migrada,
             op_naturaleza
      from   ca_operacion
      where  op_banco = @i_banco
      and    op_estado in (1, 2, 4, 9, 10)
   end
   
   if @p_proceso is not null 
   begin
      begin tran
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
      commit tran
      
      select @p_estado = 'P'
   end
   
   -- Inicio IFJ REQ 498
   delete tmp_temp_sus 
   from  tmp_temp_sus  --(index tmp_temp_sus_1) 
   where sc_spid = @@spid
   -- Fin IFJ REQ 498

   print 'Numero de Operaciones : ' + cast(@p_cont_operacion as varchar)
   
   declare
      cur_op cursor
      for select op_banco,               op_operacion,      op_moneda,
                 op_cap_susxcor,         op_estado,         op_toperacion,
                 op_fecha_ult_proceso,   op_suspendio,      op_fecha_suspenso,
                 op_migrada,             op_naturaleza
          from   tmp_cursor_operacion --(index tmp_cursor_operacion_1) --#ca_operacion  -- IFJ REQ 498
          Where  op_spid = @@spid         -- IFJ REQ 498
          order  by op_moneda, op_toperacion
          for read only
   
   open cur_op
   
   fetch cur_op
   into  @w_op_banco,             @w_operacionca,       @w_op_moneda, 
         @w_op_cap_susxcor,       @w_op_estado,         @w_toperacion, 
         @w_fecha_proceso,        @w_op_suspendio,      @w_fecha_suspenso,
         @w_op_migrada,           @w_op_naturaleza
   
   while (@@fetch_status = 0) and (@p_estado = 'P')
   begin

      if @@fetch_status = -1
      begin
         close cur_op
         deallocate cur_op
         BREAK
      end

      -- CONTROL DE EJECUCION DE PARALELISMO
      if @p_proceso is not null
      begin
         -- ACTUALIZAR EL NUMERO DE REGISTROS PROCESADOS
         select @p_cont_operacion = @p_cont_operacion - 1
         
         -- ACTUALIZAR EL PROCESO CADA MINUTO
         if datediff(ss, @p_ult_update, getdate()) > @p_tiempo_update
         begin
            select @p_ult_update = getdate()
            begin tran
            update ca_paralelo_tmp
            set    hora   = getdate(),
                   procesados = @p_cont_operacion
            where  programa = @p_programa
            and    proceso = @p_proceso
            commit tran
            
            -- AVERIGUAR EL ESTADO DEL PROCESO
            select @p_estado = estado
            from   ca_paralelo_tmp
            where  programa = @p_programa
            and    proceso = @p_proceso
            
         end
      end
      
      select @w_concepto_int = ro_concepto
      from   ca_rubro_op
      where  ro_operacion = @w_operacionca
      and    ro_tipo_rubro = 'I'
      and    ro_fpago in ('A', 'P')
      
      if @w_op_moneda != 0
      begin
         select @w_cotizacion = ct_valor
         from   cob_conta..cb_cotizacion noholdlock
         where  ct_moneda = @w_op_moneda
         and    ct_fecha  = @w_fecha_proceso
         
         if @@rowcount = 0
         begin
            exec sp_buscar_cotizacion
                 @i_moneda     = @w_op_moneda,
                 @i_fecha      = @w_fecha_proceso,
                 @o_cotizacion = @w_cotizacion out
         end
         
         if @w_op_estado = 9 and @w_op_moneda = 2-- la obligacion esta suspendida
         begin
             -- OBTENER LA COTIZACION DE ESE DIA
             select @w_cotizacion_vig = ct_valor
             from   cob_conta..cb_cotizacion noholdlock
             where  ct_moneda = @w_op_moneda
             and    ct_fecha  = @w_fecha_suspenso
         end
         else
            select @w_cotizacion_vig = @w_cotizacion
      end
      ELSE
         select @w_cotizacion = 1,
                @w_cotizacion_vig = 1
      
      if @w_op_moneda = 0
         select @w_num_dec = 0
      else
         select @w_num_dec = 4
       
      if @w_op_moneda in (0, 2)
         select @w_otra_mon_nal = 0
      else
         select @w_otra_mon_nal = 1
      
      if @w_op_moneda = 2
         select @w_num_dec_mn = 2
      else
         select @w_num_dec_mn = 0
      
      if @w_toperacion != @w_toperacion_ult
      begin
         select @w_toperacion_ult = @w_toperacion
         
         select @w_perfil = to_perfil
         from   ca_trn_oper
         where  to_toperacion = @w_toperacion
         and    to_tipo_trn   = 'PAG'
         
         select @w_perfil = convert( char(10), 'BOC' + substring(@w_perfil, 4, 10))
      end
      
      select @w_concepto_cap = ro_concepto
      from   ca_rubro_op
      where  ro_operacion  = @w_operacionca
      and    ro_tipo_rubro = 'C'
      and    ro_fpago      = 'P'
      
      -- IFJ REQ 498
      If @i_banco is null
         BEGIN TRAN
      
      -- VALORES DE CAPITAL, INTERES Y MORA DE LA TABLA DE AMORTIZACION
      -- VALORES VIGENTES
      insert into ca_saldos_cartera
            (sc_fecha,      sc_banco,      sc_codvalor,
             sc_concepto,
             sc_valor,
             sc_valor_me,
             sc_estado,
             sc_perfil,     sc_estado_con, sc_operacion)
      select @w_fecha_reg,  @w_op_banco,   co_codigo*1000 + am_estado * 10,
             am_concepto,
             sum(round((am_acumulado - am_pagado + ((am_gracia+abs(am_gracia))/2)) * @w_cotizacion_vig, @w_num_dec_mn)),
             round(sum((am_acumulado - am_pagado + ((am_gracia+abs(am_gracia))/2)) * @w_otra_mon_nal), @w_num_dec),
             am_estado,
             @w_perfil,     'I',           @w_operacionca
      from   ca_rubro_op, ca_amortizacion, ca_concepto
      where  ro_operacion = @w_operacionca
      and    ro_tipo_rubro in ('I', 'M')
      and    co_concepto   = ro_concepto
      and    am_operacion  = ro_operacion
      and    am_concepto   = ro_concepto
      and    am_estado     in (1, 2, 4, 44)
      group by co_codigo*1000 + am_estado * 10, am_concepto, am_estado, co_concepto
      having sum(am_acumulado - am_pagado)>= 0
      
      -- CAPITAL
      insert into ca_saldos_cartera
            (sc_fecha,  sc_banco,  sc_codvalor,   sc_concepto,
             sc_valor,  sc_valor_me,   sc_estado,
             sc_perfil, sc_estado_con, sc_operacion)
      select @w_fecha_reg,
             @w_op_banco,
             co_codigo*1000 + am_estado * 10,
             am_concepto,
             sum(round((am_acumulado - am_pagado) * @w_cotizacion, @w_num_dec_mn)),
             round(sum( (am_acumulado - am_pagado) * @w_otra_mon_nal), @w_num_dec),
             am_estado,
             @w_perfil,
             'I',
             @w_operacionca
      from   ca_rubro_op, ca_amortizacion, ca_concepto
      where  ro_operacion = @w_operacionca
      and    ro_tipo_rubro = 'C'
      and    co_concepto = ro_concepto
      and    am_operacion = ro_operacion
      and    am_concepto  = ro_concepto
      group by co_codigo*1000 + am_estado * 10, am_concepto, am_estado
      having sum(am_acumulado - am_pagado)>= 0
      
      -- VALORES DIFERIDOS POR RENOVACION 
      /* INICIO FCP 10/OCT/2005 - REQ 389 */
      insert into ca_saldos_cartera
            (sc_fecha,  sc_banco,  sc_codvalor,   sc_concepto,
             sc_valor,  sc_valor_me,   sc_estado,
             sc_perfil, sc_estado_con, sc_operacion)
      select @w_fecha_reg,
             @w_op_banco,
             co_codigo*1000 + 80,
             co_concepto,
             sum(round( (dif_valor_total - dif_valor_pagado) * @w_cotizacion, @w_num_dec_mn)), 
             sum(round( (dif_valor_total - dif_valor_pagado) * @w_otra_mon_nal, @w_num_dec)),  
             8,
             @w_perfil,
             'I',
             @w_operacionca
      from   ca_diferidos, ca_concepto,ca_rubro_op
      where  dif_operacion = @w_operacionca
      and    ro_operacion  = @w_operacionca
      and    co_concepto   = ro_concepto
      and    ro_tipo_rubro = 'C'
      group  by co_codigo*1000 + 80, co_concepto
      
      -- FIN FCP 10/OCT/2005 - REQ 389
      
      /* INICIO COMENTO FCP 10/OCT/2005 - REQ 389
      from   ca_capitaliza, ca_concepto
      where  cp_operacion = @w_operacionca
      and    co_concepto = 'CAP'
      FIN COMENTO FCP 10/OCT/2005 - REQ 389 */
      
      if @w_op_estado = 9
      begin
         -- CAPITALIZACION SUSPENDIDA
         if @w_op_cap_susxcor != 0
         begin
            if @w_op_moneda in (0, 2)
               insert into ca_saldos_cartera
                     (sc_fecha,          sc_banco,      sc_codvalor,   sc_concepto,
                      sc_valor,          sc_valor_me,   sc_estado,
                      sc_perfil,         sc_estado_con, sc_operacion)
               values(@w_fecha_reg,      @w_op_banco,       10095,     'CAP',
                      @w_op_cap_susxcor, 0,             9,
                      @w_perfil,         'I',           @w_operacionca)
            else -- MONEDA DISTINTA DE PESOS o UVR
               insert into ca_saldos_cartera
                     (sc_fecha,          sc_banco,      sc_codvalor,   sc_concepto,
                      sc_valor,          sc_valor_me,   sc_estado,
                      sc_perfil,         sc_estado_con, sc_operacion)
               values(@w_fecha_reg,      @w_op_banco,       10095,     'CAP',
                      @w_op_cap_susxcor, round(@w_op_cap_susxcor * @w_cotizacion, @w_num_dec_mn),
                      9,
                      @w_perfil,         'I',           @w_operacionca)
            
         end
         
         -- VALOR DE CORR MON DE CAPITAL E INTERESES EN SUSPENSO
         insert into ca_saldos_cartera
               (sc_fecha,          sc_banco,          sc_codvalor,            sc_concepto,
                sc_valor,
                sc_valor_me,       sc_estado,         sc_perfil,              sc_estado_con, sc_operacion)
         select @w_fecha_reg,      @w_op_banco,       co_codigo*1000 + 99,    cto.co_concepto,
                sum(co_correccion_sus_mn-co_correc_pag_sus_mn),
                0,                 9,                 @w_perfil,              'I',           @w_operacionca
         from   ca_correccion corr, ca_concepto cto
         where  co_operacion = @w_operacionca
         and    cto.co_concepto in (@w_concepto_int, @w_concepto_cap)
         and    co_correccion_sus_mn != 0
         and    cto.co_concepto = corr.co_concepto
         group  by co_codigo*1000 + 99, cto.co_concepto
         
         select @w_sec_ult_sus = null
         
         select @w_sec_ult_sus = max(tr_secuencial)
         from   ca_transaccion, ca_operacion_his
         where  tr_operacion = @w_operacionca
         and    tr_tran     in ('SUA', 'SUM')
         and    tr_estado   in ('ING', 'NCO', 'CON')
         and    oph_operacion = @w_operacionca
         and    oph_secuencial = tr_secuencial
         and    oph_estado in (1, 2, 4, 10)
         
         if @w_sec_ult_sus is null
         begin
            select @w_sec_ult_sus = max(tr_secuencial)
            from   ca_transaccion, cob_cartera_his..ca_operacion_his
            where  tr_operacion = @w_operacionca
            and    tr_tran     in ('SUA', 'SUM')
            and    tr_estado   in ('ING', 'NCO', 'CON')
            and    oph_operacion = @w_operacionca
            and    oph_secuencial = tr_secuencial
            and    oph_estado in (1, 2, 4, 10)
         end
         
         if @w_sec_ult_sus is null -- PARA AJUSTE COMPLETO DE MIGRACION
         and @w_op_naturaleza = 'A' and @w_op_migrada is not null
            select @w_sec_ult_sus = -2
         
         insert into ca_saldos_cartera
               (sc_fecha,          sc_banco,          sc_codvalor,    sc_concepto,
                sc_valor,          sc_valor_me,    sc_estado,
                sc_perfil,         sc_estado_con,  sc_operacion)
         select @w_fecha_reg,      @w_op_banco,       dtr_codvalor+9, dtr_concepto,
                sum(dtr_monto_mn), 0,              9,
                @w_perfil,         'I',            @w_operacionca
         from   ca_transaccion, ca_det_trn, ca_concepto
         where  tr_operacion   = @w_operacionca
         and    tr_tran        = 'CMO'
         and    tr_estado      in ('ING', 'CON')
         and    tr_secuencial  > @w_sec_ult_sus
         and    co_categoria   = 'M'
         and    dtr_operacion  = tr_operacion
         and    dtr_secuencial = tr_secuencial
         and    dtr_concepto   = co_concepto
         group  by dtr_codvalor+9, dtr_concepto
         
         -- Inicio IFJ REQ 498
         delete tmp_temp_sus 
         from  tmp_temp_sus  --(index tmp_temp_sus_1) 
         where sc_spid      = @@spid 
         and   sc_operacion = @w_operacionca
         -- Fin IFJ REQ 498
         
         -- VALORES DE INTERES Y MORA SUSPENDIDA
         insert into tmp_temp_sus      --#temp_sus IFJ REQ 498
               (sc_spid,           sc_banco,       sc_codvalor,    sc_concepto,  -- IFJ REQ 498
                sc_valor,          sc_valor_me,    sc_estado,
                sc_perfil,         sc_estado_con,  sc_operacion)
         select @@spid,           @w_op_banco,     dtr_codvalor,   dtr_concepto,  -- IFJ REQ 498
                sum(dtr_monto_mn), 0,              9,
                @w_perfil,         'I',            @w_operacionca
         from   ca_transaccion, ca_det_trn, ca_concepto
         where  tr_operacion   = @w_operacionca
         and    tr_tran        = 'PRV'
         and    tr_estado      in ('ING', 'CON')
         and    tr_secuencial  > @w_sec_ult_sus
         and    co_categoria  in ('M', 'I')
         and    dtr_operacion  = tr_operacion
         and    dtr_secuencial = tr_secuencial
         and    dtr_concepto   = co_concepto
         and    (dtr_codvalor % 100) = 90
         group  by dtr_codvalor, dtr_concepto
         union
         select @@spid,            @w_op_banco,    dtr_codvalor,   dtr_concepto,  -- IFJ REQ 498
                -sum(dtr_monto_mn), 0,             9,
                @w_perfil,         'I',            @w_operacionca
         from   ca_transaccion, ca_det_trn, ca_concepto
         where  tr_operacion   = @w_operacionca
         and    tr_tran        = 'PAG'
         and    tr_estado      in ('ING', 'CON')
         and    tr_secuencial  > @w_sec_ult_sus
         and    co_categoria  in ('M', 'I')
         and    dtr_operacion  = tr_operacion
         and    dtr_secuencial = tr_secuencial
         and    dtr_concepto   = co_concepto
         and    (dtr_codvalor % 100) = 90
         group  by dtr_codvalor, dtr_concepto
         
         insert into ca_saldos_cartera
               (sc_fecha,          sc_banco,          sc_codvalor,      sc_concepto,
                sc_valor,          sc_valor_me,      sc_estado,
                sc_perfil,         sc_estado_con,    sc_operacion)
         select @w_fecha_reg,      sc_banco,          sc_codvalor,      sc_concepto,
                sum(sc_valor),     sum(sc_valor_me), sc_estado,
                sc_perfil,         sc_estado_con,    @w_operacionca
         from   tmp_temp_sus --(index tmp_temp_sus_1) -- #temp_sus IFJ REQ 498
         where  sc_spid = @@spid                    --  IFJ REQ 498
         group  by sc_banco,  sc_codvalor, sc_concepto,
                   sc_estado, sc_perfil,   sc_estado_con
      end
      
      -- LOS OTROS CONCEPTOS
      -- VALORES DE CAPITAL, INTERES Y MORA DE LA TABLA DE AMORTIZACION
      if @w_op_moneda != 2
      begin
         insert into ca_saldos_cartera
               (sc_fecha,  sc_banco,  sc_codvalor,   sc_concepto,
                sc_valor,  sc_valor_me,   sc_estado,
                sc_perfil, sc_estado_con, sc_operacion)
         select @w_fecha_reg,
                @w_op_banco,
                co_codigo*1000 + am_estado * 10,
                am_concepto,
                sum(round((am_acumulado - am_pagado) * @w_cotizacion, @w_num_dec_mn)),
                round(sum((am_acumulado - am_pagado) * @w_otra_mon_nal), @w_num_dec),
                am_estado,
                @w_perfil,
                'I',
                @w_operacionca
         from   ca_rubro_op, ca_amortizacion, ca_concepto, ca_dividendo
         where  ro_operacion = @w_operacionca
         and    ro_tipo_rubro not in ('C', 'I', 'M')
         and    co_concepto = ro_concepto
         and    am_operacion = ro_operacion
         and    am_concepto  = ro_concepto
         and    am_estado    in (0, 1, 2, 9, 4, 44)  ---REQ 379
         and    di_operacion = ro_operacion
         and    ( (ro_fpago = 'M' and di_estado  in (2, 1,0))
                or (ro_fpago = 'A' and di_estado = 2)
                or (ro_fpago = 'P' and di_estado = 2) -- DEFECTO 8127
                )
         and    (    (am_dividendo = di_dividendo + charindex('A', ro_fpago)
                      and not(co_categoria in ('S','A') and am_secuencia > 1)
                     )
                  or (am_dividendo = di_dividendo and co_categoria in ('S','A') and am_secuencia > 1)
                )
         group by co_codigo*1000 + am_estado * 10, am_concepto, am_estado
         having sum(am_acumulado - am_pagado) >= 0
         
         if exists (select 1 from ca_rubro_op
                    where ro_operacion = @w_operacionca
                    and   ro_concepto  = 'SEGVIDA'
                    and   ro_fpago     = 'P')
         begin
            insert into ca_saldos_cartera
                  (sc_fecha,  sc_banco,  sc_codvalor,   sc_concepto,
                   sc_valor,  sc_valor_me,   sc_estado,
                   sc_perfil, sc_estado_con, sc_operacion)
            select @w_fecha_reg,
                   @w_op_banco,
                   co_codigo*1000 + am_estado * 10,
                   am_concepto,
                   sum(round((am_acumulado - am_pagado) * @w_cotizacion, @w_num_dec_mn)),
                   round(sum((am_acumulado - am_pagado) * @w_otra_mon_nal), @w_num_dec),
                   am_estado,
                   @w_perfil,
                   'I',
                   @w_operacionca
            from   ca_rubro_op, ca_amortizacion, ca_concepto, ca_dividendo
            where  ro_operacion = @w_operacionca
            and    ro_tipo_rubro not in ('C', 'I', 'M')
            and    co_concepto = ro_concepto
            and    am_operacion = ro_operacion
            and    am_concepto  = ro_concepto
            and    am_estado    in (0, 1, 2, 9, 4, 44) ---REQ 379
            and    di_operacion = ro_operacion
            and    ro_fpago = 'P' and di_estado = 2
            and    ro_concepto = 'SEGVIDA'
            and    co_concepto  = am_concepto
            and    (    (am_dividendo = di_dividendo + charindex('A', ro_fpago)
                         and not(co_categoria in ('S','A') and am_secuencia > 1)
                        )
                     or (am_dividendo = di_dividendo and co_categoria in ('S','A') and am_secuencia > 1)
                   )
            group by co_codigo*1000 + am_estado * 10, am_concepto, am_estado
            having sum(am_acumulado - am_pagado) >= 0
         end
      end
      ELSE -- PARA UVR
      begin
         -- DISTINTOS DE Seguros (S), Comisiones (O), o Impuestos (A)
         insert into ca_saldos_cartera
               (sc_fecha,  sc_banco,  sc_codvalor,   sc_concepto,
                sc_valor,  sc_valor_me,   sc_estado,
                sc_perfil, sc_estado_con, sc_operacion)
         select @w_fecha_reg,
                @w_op_banco,
                co_codigo*1000 + am_estado * 10,
                am_concepto,
                sum(round((am_acumulado - am_pagado) * @w_cotizacion, @w_num_dec_mn)),
                round(sum((am_acumulado - am_pagado) * @w_otra_mon_nal), @w_num_dec),
                am_estado,
                @w_perfil,
                'I',
                @w_operacionca
         from   ca_rubro_op, ca_amortizacion, ca_concepto, ca_dividendo
         where  ro_operacion = @w_operacionca
         and    co_categoria not in ('C', 'I', 'M', 'S', 'O', 'A')
         and    co_concepto = ro_concepto
         and    am_operacion = ro_operacion
         and    am_concepto  = ro_concepto
         and    am_estado    in (0,1, 2, 9, 4, 44) ---REQ 379
         and    di_operacion = ro_operacion
         and    (  (ro_fpago = 'M' and di_estado in (2, 1, 0))
                or (ro_fpago = 'A' and di_estado = 2)
                or (ro_fpago = 'P' and di_estado = 2) -- DEFECTO 8127
                )
         and    co_concepto  = am_concepto
         and    (    (am_dividendo = di_dividendo + charindex('A', ro_fpago)
                      and not(co_categoria in ('S','A') and am_secuencia > 1)
                     )
                  or (am_dividendo = di_dividendo and co_categoria in ('S','A') and am_secuencia > 1)
                )
         group by co_codigo*1000 + am_estado * 10, am_concepto, am_estado
         having sum(am_acumulado - am_pagado) >= 0
         
         declare
            cur_otros cursor
            for select co_codigo*1000 + am_estado * 10,
                       am_concepto,
                       di_fecha_ven,
                       sum(am_acumulado - am_pagado),
                       am_estado
                from   ca_rubro_op, ca_amortizacion, ca_concepto, ca_dividendo
                where  ro_operacion = @w_operacionca
                and    co_categoria in ('S', 'O', 'A')
                and    co_concepto = ro_concepto
                and    am_operacion = ro_operacion
                and    am_concepto  = ro_concepto
                and    am_estado    in (2, 4, 44)
                and    di_operacion = ro_operacion
                and    ro_fpago in ('A', 'P')
                and    co_concepto  = am_concepto
                and    (    (am_dividendo = di_dividendo + charindex('A', ro_fpago)
                             and not(co_categoria in ('S','A') and am_secuencia > 1)
                            )
                         or (am_dividendo = di_dividendo and co_categoria in ('S','A') and am_secuencia > 1)
                       )
                group by co_codigo*1000 + am_estado * 10, am_concepto, di_fecha_ven, am_estado
                having sum(am_acumulado - am_pagado)>= 0
            for read only
         open cur_otros
         
         fetch cur_otros
         into  @w_otr_codigo, @w_otr_concepto, @w_otr_fecha, @w_otr_valor, @w_otr_estado
         
--         while (@@fetch_status not in (-1,0))
         while (@@fetch_status = 0)
         begin
            if exists(select 1 from ca_saldos_cartera
                      where  sc_operacion = @w_operacionca
                      and    sc_codvalor = @w_otr_codigo)
            begin
               update ca_saldos_cartera
               set    sc_valor    = sc_valor    + round(@w_otr_valor * @w_cotizacion, @w_num_dec_mn),
                      sc_valor_me = sc_valor_me + round(@w_otr_valor * @w_otra_mon_nal, @w_num_dec)
               where  sc_fecha     = @w_fecha_reg
               and    sc_operacion = @w_operacionca
               and    sc_codvalor  = @w_otr_codigo
            end
            ELSE
            begin
               insert into ca_saldos_cartera
                     (sc_fecha,  sc_banco,  sc_codvalor,   sc_concepto,
                      sc_valor,  sc_valor_me,   sc_estado,
                      sc_perfil, sc_estado_con, sc_operacion)
               select @w_fecha_reg,
                      @w_op_banco,
                      @w_otr_codigo,
                      @w_otr_concepto,
                      round(@w_otr_valor * @w_cotizacion, @w_num_dec_mn),
                      round(@w_otr_valor * @w_otra_mon_nal, @w_num_dec),
                      @w_otr_estado,
                      @w_perfil,
                      'I',
                      @w_operacionca
            end
            --
            fetch cur_otros
            into  @w_otr_codigo, @w_otr_concepto, @w_otr_fecha, @w_otr_valor, @w_otr_estado
         end
         
         close cur_otros
         deallocate cur_otros
         
         declare
            cCto cursor
            for  select ro_concepto, ro_tipo_rubro
                 from   ca_rubro_op
                 where  ro_operacion  = @w_operacionca
                 and    ro_tipo_rubro in ('C')
                 for read only
         
         open cCto
         
         fetch cCto
         into  @w_ro_concepto, @w_ro_tipo_rubro
         
--         while (@@fetch_status not in (-1,0))
         while (@@fetch_status = 0)
         begin
            select @w_otr_codigo = null
            
            if @w_ro_tipo_rubro = 'C'
            begin
               select @w_otr_codigo = sc_codvalor
               from   ca_saldos_cartera
               where  sc_fecha     = @w_fecha_reg
               and    sc_operacion = @w_operacionca
               and    sc_concepto  = @w_ro_concepto
               and    sc_estado   in (0, 1)
               
               if @w_otr_codigo is not null
               begin
                  select @w_otr_valor = sc_valor -- VALOR DE CORRECCION DE CAPITAL SUSPENDIDA
                  from   ca_saldos_cartera
                  where  sc_fecha     = @w_fecha_reg
                  and    sc_operacion = @w_operacionca
                  and    sc_concepto  = @w_ro_concepto
                  and    (sc_codvalor % 100) = 99
                  
                  if @@rowcount = 1
                  begin
                     update ca_saldos_cartera
                     set    sc_valor = sc_valor - @w_otr_valor
                     where  sc_fecha    = @w_fecha_reg
                     and    sc_operacion = @w_operacionca
                     and    sc_codvalor = @w_otr_codigo
                  end
               end
            end
            ---
            fetch cCto
            into  @w_ro_concepto, @w_ro_tipo_rubro
         end
         
         close cCto
         deallocate cCto
      end
      
      select @w_cont = @w_cont + 1
      
      -- Inicio IFJ REQ 498
      delete tmp_temp_sus 
      from  tmp_temp_sus  --(index tmp_temp_sus_1) 
      where sc_spid      = @@spid 
      and   sc_operacion = @w_operacionca
      
      if @i_banco is null
         COMMIT TRAN
      -- Fin IFJ REQ 498
      
      fetch cur_op
      into  @w_op_banco,       @w_operacionca,   @w_op_moneda,
            @w_op_cap_susxcor, @w_op_estado,     @w_toperacion,
            @w_fecha_proceso,  @w_op_suspendio,  @w_fecha_suspenso,
            @w_op_migrada,     @w_op_naturaleza
   end
   
   close cur_op
   deallocate cur_op
   
   if @p_proceso is not null
   begin
      begin tran
      update ca_paralelo_tmp
      set    estado = 'T',
             procesados = @p_cont_operacion
      where  programa = @p_programa
      and    proceso = @p_proceso
      commit tran
      
   end
   
   -- INICIO IFJ REQ 498
   delete tmp_cursor_operacion 
   from  tmp_cursor_operacion --(index tmp_cursor_operacion_1) 
   where op_spid = @@spid
   
   delete tmp_temp_sus
   from  tmp_temp_sus  --(index tmp_temp_sus_1)
   where sc_spid = @@spid
   -- FIN IFJ REQ 498
   
   return 0
end
go


