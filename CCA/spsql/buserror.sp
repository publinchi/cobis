/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Anthony Zapata                          */
/*      Fecha de escritura:     Febrero 1999                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Buscar errores en modulo cartera de manera automatica           */
/************************************************************************/
/************************************************************************************************/
/* ERROR 1: 	CREDITO NO VIGENTE ANTES VIGENTE                   				*/
/* ERROR 2:   	OPERACION CON ESTADO CANCELADO Y TIENE DIVIDENDO CON ESTADO <> CANCELADO       	*/
/* ERROR 3:    	EXISTE MAS DE UN DIVIDENDO VIGENTE                   				*/
/* ERROR 4:    	FECHA DE PROCESO DE HISTORIAL DES SUPERIOR A FECHA DE DESEMBOLSO       		*/
/* ERROR 5:    	NO EXISTE LA TRANSACCION DES O HISTORICO PARA DESEMBOLSO          		*/  
/* ERROR 6:    	NO EXISTE LA TRANSACCION MIG O HISTORICO DE LA TRANSACCION - CREDITOS MIGRADOS  */
/* ERROR 7:    	MONTO APROBADO INFERIOR AL MONTO                   				*/
/* ERROR 8:    	DESEMBOLSOS APLICADOS QUE NO SE REFLEJAN EN EL MONTO             		*/
/* ERROR 9:    	OPERACION DEBERIA ESTAR CON ESTADO VIGENTE YA QUE FUE DESEMBOLSADA       	*/
/* ERROR 10:    NO ESTA DISTRIBUIDO TODO EL CAPITAL DESEMBOLSADO EN LA TABLA AMORTIZACION       */
/* ERROR 11:    CODIGO DE CIUDAD INEXISTENTE                      				*/
/* ERROR 12:    VALOR PAGADO MAYOR AL ACUMULADO                   				*/
/* ERROR 13:    VALOR ACUMULADO MAYOR AL PROYECTADO                  				*/
/* ERROR 14:    DIVIDENDO CON ESTADO CANCELADO PERO TIENE SALDO A PAGAR          		*/
/* ERROR 15:    NO CAUSO EL INTERES CONRRIENTE                      				*/
/* ERROR 16:    DIVIDENDO NO DEBERIA SER VIGENTE                   				*/
/* ERROR 17:    DIVIDENDO NO DEBERIA SER VENCIDO                   				*/
/* ERROR 18:    DIVIDENDO NO DEBERIA SER NO VIGENTE                   				*/
/* ERROR 19:    DIVIDENDO VIGENTE ANTES QUE UN CANCELADO                			*/
/* ERROR 20:    DIVIDENDO VIGENTE ANTES QUE UN VENCIDO                   			*/
/* ERROR 21:    DIVIDENDO NO VIGENTE ANTES QUE VENCIDOS O CANCELADOS POSTERIORES       		*/
/* ERROR 22:   	MONTO NO ES IGUAL A CAPITAL DISTRIBUIDO EN TABLA DE AMORTIZACION      		*/
/* ERROR 23:    OPERACION DESEMBOLSADA Y NO TIENE CUOTA VIGENTE               			*/
/* ERROR 24:    CUOTA VENCIDA Y NO COBRA MORA                      				*/
/* ERROR 25:    OPERACION CANCELADA PERO TIENE CUOTAS PENDIENTES POR PAGAR          		*/
/* ERROR 26:    NUMERO DE CUOTAS NO COINCIDE CON EL PLAZO               			*/
/* ERROR 27:    CUOTA DEBERIA ESTAR COMPLETAMENTE CAUSADA					*/
/************************************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_busca_errores')
   drop proc sp_busca_errores
go

create proc sp_busca_errores (
@i_procesa_todo      char(1)  = 'S',
@i_banco             cuenta   = null,
@i_error             tinyint  = null
)

as

create table #ca_operacion_aux (
op_operacion          int,
op_banco              cuenta,
op_estado             tinyint,
op_fecha_ult_proceso  datetime,
op_fecha_ini          datetime,
op_fecha_fin          datetime,
op_toperacion         catalogo,
op_cliente            int,
op_migrada            cuenta,
op_monto              money,
op_tipo               char(1),
op_plazo              smallint,
op_tplazo             char(10),
op_tdividendo         char(10),
op_periodo_int        smallint,
op_tipo_amortizacion  catalogo,
op_clausula_aplicada  char(1),
op_moneda	      tinyint
)

declare  
@w_registros          int,
@w_error              int,
@w_banco              cuenta,
@w_operacionca        int,
@w_estado             tinyint,
@w_fecha_ult_proc     datetime,
@w_fecha_ini          datetime,
@w_fecha_fin          datetime,
@w_toperacion         catalogo,
@w_op_migrada         cuenta,
@w_cliente            int,
@w_contador           int,
@w_hora               char(10),
@w_secuencial_ini     int,
@w_fecha_pro_his      datetime,
@w_fecha_liq          datetime,
@w_monto              money,
@w_total_desembolsos  money,
@w_por_error          char(1),
@w_secuencial_mig     int,
@w_acumulado          money,
@w_num_vigentes       int,
@w_tot_des            money,
@w_tot_cap            money,
@w_dividendo          int,
@w_saldo              money,
@w_num_dividendos     int,
@w_di_estado          int,
@w_di_fecha_ini       datetime,
@w_di_fecha_fin       datetime,
@w_ult_vencido        int,
@w_ult_cancel         int,
@w_min_novigente      int,
@w_vigente            int,
@w_est_novigente      int,
@w_est_vigente        int,
@w_est_vencido        int,
@w_est_cancelado      int,
@w_opcion_cap         char(1),
@w_cap                money,
@w_gracia_mora        int,
@w_mora               money,
@w_ts_porcentaje      float,
@w_tipo               char(1),
@w_proyectado         money,
@w_plazo              smallint,
@w_tplazo             char(10),
@w_tdividendo         char(10),
@w_periodo_int        smallint,
@w_tipo_amortizacion  catalogo,
@w_ms                 datetime,
@w_mc                 datetime,
@w_max                int,
@w_tt_tdividendo      smallint,
@w_tt_tplazo          smallint,
@w_num_dividendos_tot int,
@w_clausula_aplicada  char(1),
@w_moneda	      tinyint

select @w_por_error = 'N',
       @w_contador  = 0,
       @w_max       = 50

-- ESTADOS
select @w_est_novigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

select @w_est_vigente  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CANCELADO'




-- SELECCIONAR OPERACIONES A ANALIZAR
begin tran

insert into #ca_operacion_aux
select op_operacion,         op_banco,             op_estado,
     op_fecha_ult_proceso, op_fecha_ini,         op_fecha_fin,
     op_toperacion,        op_cliente,           op_migrada, 
     op_monto,             op_tipo,              op_plazo,
     op_tplazo,            op_tdividendo,        op_periodo_int,
     op_tipo_amortizacion, op_clausula_aplicada, op_moneda
from   ca_operacion, ca_estado
where  op_estado  = es_codigo
and    es_procesa = 'S'

commit

select @w_registros = @@rowcount

select @w_hora = convert(char(10), getdate(),8)

-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select op_operacion,         op_banco,             op_estado,
           op_fecha_ult_proceso, op_fecha_ini,         op_fecha_fin,
           op_toperacion,        op_cliente,           op_migrada, 
           op_monto,             op_tipo,              op_plazo,
           op_tplazo,            op_tdividendo,        op_periodo_int,
           op_tipo_amortizacion, op_clausula_aplicada, op_moneda
from #ca_operacion_aux
for read only

open cursor_operacion

fetch cursor_operacion
into  @w_operacionca,      @w_banco,             @w_estado,
      @w_fecha_ult_proc,   @w_fecha_ini,         @w_fecha_fin,
      @w_toperacion,       @w_cliente,           @w_op_migrada, 
      @w_monto,            @w_tipo,              @w_plazo,
      @w_tplazo,           @w_tdividendo,        @w_periodo_int,
      @w_tipo_amortizacion,@w_clausula_aplicada, @w_moneda
      
while @@fetch_status = 0
begin
 
   
   if @w_por_error ='N'
       select @i_error = null
   
   -- INICIALIZAR VARIABLES
   select   @w_secuencial_ini     = null,
            @w_fecha_pro_his      = null,
            @w_fecha_liq          = null,
            @w_total_desembolsos  = 0,
            @w_secuencial_mig     = null,
            @w_acumulado      = 0,
            @w_num_vigentes      = 0,
            @w_tot_des         = 0,
            @w_tot_cap            = 0,
            @w_ult_vencido        = 0,
            @w_ult_cancel         = 0,
            @w_min_novigente      = 0,
            @w_vigente            = 0,
            @w_cap                = 0,
            @w_mora         = 0,
            @w_gracia_mora        = 0,
            @w_num_dividendos     = 0,
            @w_num_dividendos_tot = 0
   
   select @w_num_dividendos = count(1)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado      = @w_est_cancelado
   
   select @w_num_dividendos_tot = count(1)
   from   ca_dividendo
   where  di_operacion = @w_operacionca

   -- ERROR 1: CREDITO NO VIGENTE ANTES VIGENTE
   if @i_error = 1 or @i_error is null
   begin
      if exists(select 1 from ca_operacion
                where  op_operacion = @w_operacionca
                and    op_estado    = @w_est_novigente  
                and    convert (varchar(10),op_operacion) <> op_banco)
      begin
         begin tran
         insert ca_errores_finales (ef_banco, ef_error, ef_descripcion)
         values(@w_banco,1,'CREDITO NO VIGENTE ANTES VIGENTE')
         commit
      end
      
      if @i_error = 1
         goto NEXTOPER
   end 
   
   -- ERROR 2: OPERACION CON ESTADO CANCELADO Y TIENE DIVIDENDO CON ESTADO <> CANCELADO
   if @i_error = 2 or @i_error is null
   begin
      if @w_estado = @w_est_cancelado
      begin
         if exists(select 1 from ca_dividendo 
                   where di_operacion = @w_operacionca
                   and di_estado     != @w_est_cancelado) 
         begin
            begin tran
            insert ca_errores_finales (ef_banco, ef_error, ef_descripcion)
            values(@w_banco,2,'OP. CON ESTADO CANCELADO Y TIENE DIV. CON ESTADO <> CANCELADO')
            commit
         end
      end
      
      if @i_error = 2
         goto NEXTOPER 
   end
   
   -- ERROR 3: EXISTE MAS DE UN DIVIDENDO VIGENTE
   if @i_error = 3 or @i_error is null
   begin
      select @w_num_vigentes = count(di_dividendo) 
      from   ca_dividendo 
      where  di_operacion = @w_operacionca
      and    di_estado    = @w_est_vigente 
      
      if @w_num_vigentes > 1
      begin
         begin tran
         insert ca_errores_finales (ef_banco, ef_error, ef_descripcion)
         values(@w_banco,3,'EXISTE MAS DE UN DIVIDENDO VIGENTE')
         commit
      end
      
      if @i_error = 3
         goto NEXTOPER
   end
   
   -- ERROR 4: FECHA DE PROCESO DE HISTORIAL DES INFERIOR A FECHA DE DESEMBOLSO
   -- ERROR 5: NO EXISTE TRANSACCION DES O HISTORICO PARA DESEMBOLSO
   if @i_error = 4 or @i_error is null
   begin
      if (@w_op_migrada is null) and (@w_estado <> @w_est_novigente)
      begin
         select @w_secuencial_ini = min(tr_secuencial)
         from   ca_transaccion
         where  tr_banco = @w_banco
         and    tr_tran  = 'DES'
         and    tr_estado not in ('ANU','RV')
         
         select @w_secuencial_ini = min(oph_secuencial)
         from   ca_operacion_his, ca_transaccion
         where  oph_operacion  = @w_operacionca
         and    oph_secuencial = @w_secuencial_ini
         and    tr_secuencial  = oph_secuencial
         and    tr_operacion   = @w_operacionca
         and    tr_estado not in ('ANU','RV')
         
         if @w_secuencial_ini is null
         begin
            begin tran
            insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
            values(@w_banco,5,'NO EXISTE TRANSACCION DES O HISTORICO PARA DESEMBOLSO')
            commit
         end
      end 
      
      if @i_error = 4 or @i_error = 5
         goto NEXTOPER 
   end

   
   -- ERROR 6: NO EXISTE LA TRANSACCION MIG O HISTORICO DE LA TRANSACCION - CREDITOS MIGRADOS
  /* 
   if @i_error = 6 or @i_error is null
   begin
      if @w_op_migrada is not null
      begin
         select @w_secuencial_mig = tr_secuencial
         from   ca_transaccion
         where  tr_banco = @w_banco
         and    tr_tran  = 'MIG'           
         
         if @@rowcount = 0
         begin
            begin tran
            insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
            values(@w_banco,6,'NO EXISTE LA TRANSACCION MIG O HISTORICO DE LA TRANSACCION - CREDITOS MIGRADOS')
            commit
         end
         ELSE
         begin
            if not exists (select 1 from ca_operacion_his
                           where oph_operacion  = @w_operacionca
                           and   oph_secuencial = @w_secuencial_mig)   
            begin
               begin tran
               insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
               values(@w_banco,6,'NO EXISTE LA TRANSACCION MIG O HISTORICO DE LA TRANSACCION - CREDITOS MIGRADOS')
               commit
            end           
         end
      end                 
      
      if @i_error = 6
         goto NEXTOPER 
   end*/
/*
   -- ERROR 7: MONTO APROBADO INFERIOR AL MONTO
   if (@i_error = 7 or @i_error is null) and @w_moneda <> 2
   begin
      if exists (select 1 from ca_operacion
                 where op_operacion      = @w_operacionca
                 and   op_monto_aprobado < op_monto)
      begin
         select @w_opcion_cap = op_opcion_cap
         from   ca_operacion
         where  op_operacion = @w_operacionca
         
         if @w_opcion_cap <> 'S'
         begin
            begin tran
            insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
            values(@w_banco,7,'MONTO APROBADO INFERIOR AL MONTO')
            commit
         end
      end
      
      if @i_error = 7
         goto NEXTOPER 
   end
   */
   
   -- ERROR 8: DESEMBOLSOS APLICADOS QUE NO SE REFLEJAN EN EL MONTO
   if @i_error = 8 or @i_error is null
   begin
      if @w_op_migrada is null
      begin
         select @w_total_desembolsos = sum(dm_monto_mop)
         from   ca_desembolso
         where  dm_operacion = @w_operacionca 
         and    dm_estado    = 'A'
         
         if @w_total_desembolsos > @w_monto
         begin
            begin tran
            insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
            values(@w_banco,8,'DESEMBOLSOS APLICADOS QUE NO SE REFLEJAN EN EL MONTO')
            commit
         end
      end
      
      if @i_error = 8
         goto NEXTOPER 
   end
   
   -- ERROR 9: OPERACION DEBERIA ESTAR CON ESTADO VIGENTE YA QUE FUE DESEMBOLSADA
   if @i_error = 9 or @i_error is null
   begin
      if @w_estado = @w_est_novigente
      begin
         if exists(select 1 from ca_desembolso
                   where dm_operacion = @w_operacionca
                   and   dm_estado   = 'A') 
         begin
            begin tran
            insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
            values(@w_banco,9,'OPERACION DEBERIA ESTAR CON ESTADO VIGENTE YA QUE FUE DESEMBOLSADA')
            commit
         end
      end
      
      if @i_error = 9
         goto NEXTOPER
   end 
   
   -- ERROR 11: CODIGO DE CIUDAD INEXISTENTE
   if @i_error = 11 or @i_error is null
   begin
      if exists (select 1 from ca_operacion
                 where op_operacion = @w_operacionca
                 and   op_ciudad not in (select ci_ciudad from cobis..cl_ciudad noholdlock))
      begin
         begin tran
         insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
         values(@w_banco,11,'CODIGO DE CIUDAD INEXISTENTE')
         commit
      end
      
      if @i_error = 11
         goto NEXTOPER 
   end
   
   -- ERROR 12: VALOR PAGADO MAYOR AL ACUMULADO
   if @i_error = 12 or @i_error is null
   begin
      if exists(select 1 from ca_amortizacion, ca_dividendo   
                where am_operacion = @w_operacionca
                and   am_pagado    > am_acumulado
                and   am_concepto <> 'INTANT'
                and   di_operacion = @w_operacionca
                and   di_dividendo = am_dividendo
                and   di_estado   in (@w_est_vencido,@w_est_cancelado) )
      begin
         begin tran
         insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
         values(@w_banco,12,'VALOR PAGADO MAYOR AL ACUMULADO')
         commit
      end
      
      if @i_error = 12
         goto NEXTOPER
   end
   
   -- ERROR 13: VALOR ACUMULADO MAYOR AL PROYECTADO
   if @i_error = 13 or @i_error is null
   begin
      if exists(select 1 from ca_amortizacion   
                where am_operacion = @w_operacionca
                and am_acumulado > am_cuota) 
      begin
         begin tran
         insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
         values(@w_banco,13,'VALOR ACUMULADO MAYOR AL PROYECTADO')
         commit
      end
      
      if @i_error = 13
         goto NEXTOPER
   end
   
   -- ERROR 14: DIVIDENDO CON ESTADO CANCELADO PERO TIENE SALDO A PAGAR EN DIV
   if @i_error = 14 or @i_error is null
   begin
      select @w_dividendo      = 0,
             @w_saldo          = 0,
             @w_dividendo      = 1
      
      while @w_dividendo <= @w_num_dividendos
      begin
         select @w_saldo = sum(am_acumulado + am_gracia - am_pagado)
         from   ca_amortizacion
         where  am_operacion = @w_operacionca
         and    am_dividendo   = @w_dividendo
         
         if @w_saldo <> 0
         begin
            select @w_saldo = sum(am_cuota + am_gracia - am_pagado)
            from   ca_amortizacion 
            where  am_operacion = @w_operacionca
            and    am_dividendo   = @w_dividendo
            
            if @w_saldo <> 0
            begin
               begin tran
               insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
               values(@w_banco,14,'DIV. CON ESTADO CANCELADO PERO TIENE SALDO A PAGAR EN DIV, ' + convert(char(4),@w_dividendo))
               commit
               select @w_dividendo = @w_dividendo + 1000
            end
         end
         
         select @w_dividendo = @w_dividendo + 1
      end
      
      if @i_error = 14
         goto NEXTOPER
   end
   
   -- DETERMINAR SI HAY DIV. QUE DEBERIAN ESTAR EN OTRO ESTADO
   select @w_dividendo = 0  --@w_ult_cancel
   
   while 1=1 begin
      set rowcount 1
      
      select @w_dividendo    = di_dividendo,
             @w_di_fecha_ini = di_fecha_ini,
             @w_di_fecha_fin = di_fecha_ven,
             @w_di_estado    = di_estado,
             @w_gracia_mora  = di_gracia_disp
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      and    di_dividendo   > @w_dividendo
      and    di_estado     != @w_est_novigente   
      
      if @@rowcount = 0
      begin
         set rowcount 0
         break
      end
      
      set rowcount 0

      -- ERROR 15: NO CAUSO EL INTERES CORRIENTE
      if @i_error = 15 or @i_error is null
      begin
         select @w_ts_porcentaje  = ts_porcentaje 
         from   ca_tasas
         where  ts_operacion = @w_operacionca
         and    ts_concepto in ('INT','INTANT')
         and    ts_dividendo <=  (select max(ts_dividendo)
                                  from   ca_tasas
                                  where  ts_operacion = @w_operacionca
                                  and    ts_concepto in ('INT','INTANT')
                                  and    ts_dividendo <= @w_dividendo )
         
         if @w_ts_porcentaje != 0 and @w_di_fecha_fin < @w_fecha_ult_proc
         begin
            select @w_proyectado = 0,
                   @w_acumulado = 0
            
            select @w_acumulado  = am_acumulado,
                   @w_proyectado = am_cuota
            from   ca_amortizacion
            where  am_operacion = @w_operacionca
            and    am_dividendo   = @w_dividendo
            and    am_concepto   in ('INT','INTANT')
            
            select @w_acumulado = isnull(@w_acumulado ,0)
            select @w_proyectado = isnull(@w_proyectado ,0)
            if @w_acumulado = 0  and @w_proyectado > 0
            begin
               --select @w_ts_porcentaje,@w_tipo,datepart(mm,@w_di_fecha_ini) ,datepart(mm,@w_fecha_ult_proc),@w_dividendo
               begin tran
               insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
               values(@w_banco,15,'NO CAUSO EL INTERES CONRRIENTE, ' + convert(char(4),@w_dividendo))
               commit
            end
         end
         
         if @i_error = 15
            GOTO NEXTOPER
      end
      
      -- ERROR 16: DIVIDENDO NO DEBERIA SER VIGENTE
      if @i_error = 16 or @i_error is null
      begin
         if @w_di_estado = @w_est_vigente
         begin
            if @w_di_fecha_fin < @w_fecha_ult_proc
            begin
               if not exists(select 1 from ca_errores_finales
                             where ef_banco = @w_banco
                             and   ef_error   = 16)
               begin
                  begin tran
                  insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
                  values(@w_banco,16,'DIVIDENDO NO DEBERIA SER VIGENTE, ' + convert(char(4),@w_dividendo))
                  commit
               end
            end
         end
         
         if @i_error = 16
            GOTO NEXTOPER
      end 
      
      -- ERROR 17: DIVIDENDO NO DEBERIA SER VENCIDO
      if @i_error = 17 or @i_error is null
      begin
         if @w_di_estado = @w_est_vencido and @w_clausula_aplicada <> 'S'
         begin
            if @w_di_fecha_fin > @w_fecha_ult_proc
            begin
               if not exists(select 1 from ca_errores_finales
                             where ef_banco = @w_banco
                             and ef_error = 17) 
               begin
                  begin tran
                  insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
                  values(@w_banco,17,'DIVIDENDO NO DEBERIA SER VENCIDO, ' + convert(char(4),@w_dividendo))
                  commit
               end
            end         
         end
         
         if @i_error = 17
            GOTO NEXTOPER
      end
      
      -- ERROR 18: DIVIDENDO NO DEBERIA SER NO VIGENTE
      if @i_error = 18 or @i_error is null
      begin
         if @w_di_estado = @w_est_novigente
         begin
            if @w_di_fecha_ini <= @w_fecha_ult_proc
            begin
               if not exists(select 1 from ca_errores_finales
                             where  ef_banco = @w_banco
                             and    ef_error = 18) 
               begin
                  begin tran
                  insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
                  values(@w_banco,18,'DIVIDENDO NO DEBERIA SER NO VIGENTE, ' + convert(char(4),@w_dividendo))
                  commit
               end
            end
         end
         
         if @i_error = 18
            GOTO NEXTOPER
      end
      
      -- ERROR 24: CUOTA VENCIDA Y NO COBRA MORA
      if @i_error = 24 or @i_error is null
      begin
         if @w_di_estado = @w_est_vencido and @w_gracia_mora = 0
         begin
            select @w_mora = sum(am_cuota + am_gracia)
            from   ca_amortizacion
            where  am_operacion = @w_operacionca
            and    am_dividendo = @w_dividendo
            and    am_concepto  = 'IMO'
            
            select @w_mora = isnull(@w_mora,0)
            
            if @w_mora <= 0 
            begin
               if exists(select 1 from ca_tasas
                         where ts_operacion      = @w_operacionca
                         and   ts_dividendo      = @w_dividendo
                         and   ts_concepto       = 'IMO'
                         and   ts_porcentaje_efa = 0)
                  select @w_por_error = 'N'
               else
               begin
                  if not exists(select 1 from ca_errores_finales
                                where  ef_banco = @w_banco
                                and    ef_error = 24)
                  begin
                     if exists(select 1 from ca_rubro_op 
                               where  ro_operacion = @w_operacionca
                               and    ro_tipo_rubro = 'IMO')
                     begin
                        begin tran
                        insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
                        values(@w_banco,24,'CUOTA VENCIDA Y NO COBRA MORA, ' + convert(char(4),@w_dividendo))
                        commit
                     end
                  end
               end
            end
         end
         
         if @i_error = 24
            GOTO NEXTOPER
      end
   end
   
   -- DETERMINAR ULTIMO DIVIDENDO CANCELADO
   select @w_ult_cancel = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado      = @w_est_cancelado
   
   -- DETERMINAR DIVIDENDO VIGENTE
   select @w_vigente = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vigente
   
   -- DETERMINAR ULTIMO DIVIDENDO VENCIDO
   select @w_ult_vencido = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado      = @w_est_vencido
   
   -- DETERMINAR EL PRIMER DIVIDENDO NO VIGENTE
   select @w_min_novigente = min(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado      = @w_est_novigente
   
   -- ERROR 19: DIVIDENDO VIGENTE ANTES QUE UN CANCELADO
   if @i_error = 19 or @i_error is null
   begin
      if @w_ult_cancel >= @w_vigente
      begin
         begin tran
         insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
         values(@w_banco,19,'DIVIDENDO VIGENTE ANTES QUE UN CANCELADO')
         commit
      end
      
      if @i_error = 19
         GOTO NEXTOPER
   end
   
   -- ERROR 20: DIVIDENDO VIGENTE ANTES QUE UN VENCIDO
   if @i_error = 20 or @i_error is null
   begin
      if @w_ult_vencido >= @w_vigente
      begin
         begin tran
         insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
         values(@w_banco,20,'DIVIDENDO VIGENTE ANTES QUE UN VENCIDO')
         commit
      end
      
      if @i_error = 20
         GOTO NEXTOPER
   end
   
   -- ERROR 21: DIVIDENDO NO VIGENTE ANTES QUE VENCIDOS O CANCELADOS POSTERIORES
   if @i_error = 21 or @i_error is null
   begin
      if @w_min_novigente <= @w_vigente
         or @w_min_novigente <= @w_ult_cancel
         or @w_min_novigente <= @w_ult_vencido
      begin
         begin tran
         insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
         values(@w_banco,21,'DIVIDENDO NO VIGENTE ANTES QUE VENCIDOS O CANCELADOS POSTERIORES')
         commit
      end
      
      if @i_error = 21
         GOTO NEXTOPER
   end
   
   -- ERROR 22:   MONTO NO ES IGUAL A CAPITAL DISTRIBUIDO EN TABLA DE AMORTIZACION
   if @i_error = 22 or @i_error is null
   begin
      select @w_cap = sum(am_cuota)
      from   ca_amortizacion
      where  am_operacion = @w_operacionca
      and    am_concepto  = 'CAP'
      
      if @w_monto <> @w_cap
      begin
         begin tran
         insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
         values(@w_banco,22,'MONTO NO ES IGUAL A CAPITAL DISTRIBUIDO EN TABLA DE AMORTIZACION')
         commit
      end
      
      if @i_error = 22
         GOTO NEXTOPER
   end 
   
   -- ERROR 23: OPERACION DESEMBOLSADA Y NO TIENE CUOTA VIGENTE
   if @i_error = 23 or @i_error is null
   begin
      if exists(select 1 from ca_dividendo
                where di_operacion = @w_operacionca
                and   di_estado    = @w_est_vigente)
         select @w_por_error = 'N'
      else
      begin
         if exists(select 1 from ca_dividendo
                   where di_operacion = @w_operacionca
                   and   di_estado    = @w_est_novigente)
         begin
            begin tran
            insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
            values(@w_banco,23,'OPERACION DESEMBOLSADA Y NO TIENE CUOTA VIGENTE')
            commit
         end
      end
      
      if @i_error = 23
         GOTO NEXTOPER
   end
   
    -- ERROR 27: CUOTA DEBERIA ESTAR COMPLETAMENTE CAUSADA				
   if (@i_error = 27 or @i_error is null)
   begin

      if exists (select 1 from ca_amortizacion, ca_dividendo
                 where di_operacion = @w_operacionca
                 and   di_estado    = @w_est_vigente
                 and   di_fecha_ven = @w_fecha_ult_proc
                 and   di_operacion = am_operacion
                 and   di_dividendo = am_dividendo
                 and   am_cuota    <> am_acumulado)
      begin

         begin tran
         insert ca_errores_finales (ef_banco,ef_error,ef_descripcion)
         values(@w_banco,27,'CUOTA DEBERIA ESTAR COMPLETAMENTE CAUSADA')
         commit
     
      end

      if @i_error = 27
         GOTO NEXTOPER

   end

   
   goto NEXTOPER
   
   ERROR:
   begin tran
   insert ca_errores_finales values('0',@w_error, 'Error Base')
   commit
   
   NEXTOPER:
   
   select @w_contador = @w_contador + 1
   
   if @w_contador % 500 = 0
   begin
      exec sp_reloj @w_contador, @w_mc, @w_mc out, @w_max   
   end
   
   fetch cursor_operacion
   into  @w_operacionca,      @w_banco,             @w_estado,
         @w_fecha_ult_proc,   @w_fecha_ini,         @w_fecha_fin,
         @w_toperacion,       @w_cliente,           @w_op_migrada, 
         @w_monto,            @w_tipo,              @w_plazo,
         @w_tplazo,           @w_tdividendo,        @w_periodo_int,
         @w_tipo_amortizacion,@w_clausula_aplicada, @w_moneda
end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

-- ERROR 25: OPERACION CANCELADA PERO TIENE CUOTAS PENDIENTES POR PAGAR
insert into ca_errores_finales
select op_banco, 25, 'OPERACION CANCELADA PERO TIENE CUOTAS PENDIENTES POR PAGAR'
from   ca_operacion, ca_dividendo, ca_amortizacion
where  op_estado    = 3
and    op_operacion = di_operacion
and    di_estado   != 3
and    di_operacion = am_operacion
and    di_dividendo = am_dividendo
group  by op_banco




go

