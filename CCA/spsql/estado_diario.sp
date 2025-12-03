/*********************************************************************/
/*   Archivo:            estado_diario.sp                            */
/*   Stored procedure:   sp_estado_diario_cartera                    */
/*********************************************************************/
/*                             IMPORTANTE                            */
/*   Este programa es parte de los paquetes bancarios propiedad de   */
/*   'MACOSA'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como      */
/*   cualquier alteracion o agregado hecho por alguno de sus         */
/*   usuarios sin el debido consentimiento por escrito de la         */
/*   Presidencia Ejecutiva de MACOSA o su representante.             */
/*********************************************************************/  
/*                             PROPOSITO                             */
/*   Reporte EN LINEA que resume el estado de la cartera.            */
/*********************************************************************/  
/*                           MODIFICACIONES                          */
/*  FECHA       AUTOR                         RAZON                  */
/* 29/MAY/2009  G. Alvis       Adicion de modos Historico y Tramites */
/*********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_estado_diario_cartera')
   drop proc sp_estado_diario_cartera
go


create proc sp_estado_diario_cartera
  @i_operacion         char(1),
  @i_modo              tinyint  = null,
  @i_zona              int      = null,
  @i_oficina           int      = null,
  @i_oficial           int      = null
as

declare
  @w_fecha_proceso     datetime,
  @w_error             int,
  @w_finmes_anterior   datetime,
  @w_ciudad_nacional   int,
  @w_sp_name           varchar(32),
  @w_msg               varchar(120),
  @w_estacion          smallint,
  @w_nom_ofi_master    descripcion,
  @w_alianza           int

     
  
/* CONTROL DE EJECUCION DE PROCESO */   
if exists (select 1 from cob_credito..cr_semaforo where se_proceso  = 1 and se_luz = 'ROJO') begin
   select 
   @w_error = 2108029,
   @w_msg   = '...Proceso Actualizacion en ejecucion!!!, por favor consultar en 5 minutos'
   
   goto ERROR   
end
   
/* DETERMINAR LA FECHA DE PROCESO DE CARTERA */
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre (nolock)
where  fc_producto = 7

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

         
/* CABECERAS */
if @i_operacion = 'C' begin

   if @i_modo = 0  begin   
   
      --> SI SE ENVIA EL CODIGO DE OFICIAL Y LA OFICINA SE RETORNAN SUS DESCRIPCIONES
      --> SI SE ENVIA SOLAMENTE LA OFICINA SE RETORNA SU DESCRIPCION Y LOS CODIGOS Y DESCRIPCIONES 
      --  DE LOS OFICIALES DE ESA OFICINA QUE TIENEN A SU CARGO CREDITOS 
      if @i_oficina is null begin
         print 'EL CODIGO DE LA OFICINA ES OBLIGATORIO'
         return 708150
      end
      
      /* DETERMINAR LA FECHA DEL FIN DE MES ANTERIOR */
      select @w_finmes_anterior = dateadd(dd, -datepart(dd, @w_fecha_proceso), @w_fecha_proceso)
      
      while exists(select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional and df_fecha = @w_finmes_anterior)
            select @w_finmes_anterior = dateadd(dd, -1, @w_finmes_anterior)   
      
      /*TABLA PARA REGISTRAR LOS OFICIALES QUE SE REPOTARAN AL FRONT END */   
      create table #oficiales(
      oficial   int not null)
      
      if @i_oficial is not null
      begin
         select @w_estacion       = es_estacion,
                @w_nom_ofi_master = fu_nombre
         from cob_credito..cr_estacion with (nolock),
              cobis..cc_oficial with (nolock),
              cobis..cl_funcionario with (nolock)
         where es_usuario     = fu_login
           and fu_funcionario = oc_funcionario
           and oc_oficial     = @i_oficial
         
         if exists (select 1                              --Si existe, este oficial es ejecutivo master
                    from cob_credito..cr_etapa_estacion
                    where ee_master = @w_estacion) and @w_estacion is not null
         begin
            select oc_oficial into #ofic_master            --Oficiales a cargo del Master
            from cob_credito..cr_etapa_estacion with (nolock),
                 cobis..cc_oficial with (nolock),
                 cobis..cl_funcionario with (nolock),
                 cob_credito..cr_estacion
            where ee_master      = @w_estacion
              and es_usuario     = fu_login
              and fu_funcionario = oc_funcionario
              and es_estacion     = ee_estacion
              
            insert into #oficiales
            select oc_oficial
            from #ofic_master --Oficiales del Master
            
      end
      else
      begin
         insert into #oficiales values(@i_oficial)
      end
      end else
      begin 
         select distinct op_oficial
         into  #oficiales_aux
         from  ca_operacion  (nolock)
         where op_oficina     = @i_oficina
         and   op_estado     in (0, 1, 2, 8, 9)  -- VIGENTES, VENCIDAS, DIFERIDAS Y EN SUSPENSO
         and   op_naturaleza  = 'A'              -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES DE NATURALEZA ACTIVA
         and   op_tipo       <> 'G'              -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES NO FNG
         if @@error <> 0 begin
            print 'ERROR EN PASO A TEMPORALES DE LOS OFICIALES_AUX (1)'
            return 703105
         end      
                 
         insert into #oficiales_aux 
         select distinct do_oficial
         from cob_conta_super..sb_dato_operacion  (nolock)
         where do_fecha              = @w_finmes_anterior
         and   do_aplicativo         = 7
         and   do_oficina            = @i_oficina
         and   do_estado_contable   in (1, 2)                        -- SIN CASTIGOS NI CANCELACIONES AL MOMENTO DEL CIERRE
         and   do_tipo_operacion   not in ('SOL_APRO', 'SLCCUPO')    -- EXCLUIR APROBADOS NO DESEMBOLSADOS Y CUPOS DE SICREDITO
         and   do_naturaleza         = '1'                           -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES DE NATURALEZA ACTIVA
         if @@error <> 0 begin
            print 'ERROR EN PASO A TEMPORALES DE LOS OFICIALES_AUX (2)'
            return 703105
         end      
         
         insert into #oficiales
         select distinct op_oficial
         from #oficiales_aux
         
         if @@error <> 0 begin
            print 'ERROR EN PASO A TEMPORALES DE LOS OFICIALES'
            return 703105
         end 
      end
      
      /* RETORNAR AL FRONT END EL NOMBRE DE LAS OFICINAS */
      select of_oficina, of_nombre
      from cobis..cl_oficina  (nolock)
      where of_oficina = @i_oficina
         
      /* RETORNAR AL FRONT END LOS NOMBRES DE LOS OFICIALES */
      select @i_oficina, oc_oficial, fu_nombre
      from cobis..cc_oficial (nolock), cobis..cl_funcionario (nolock), #oficiales
      where fu_funcionario = oc_funcionario 
      and   oc_oficial     = oficial
      order by oc_oficial
      
      /*RETORNAR AL FRONT END LA DESCRIPCION DEL EJECUTIVO MASTER*/
      select @w_nom_ofi_master
      
   end else begin
   
      --> SI SE ENVIA MODO 1 SE BUSCA LISTAR LAS OFICINAS DE UNA DETERMINADA ZONA
      if @i_zona is null begin
         print 'EL CODIGO DE LA ZONA ES OBLIGATORIO'
         return 708150
      end
   
      -- CONSULTA DE OFICINAS POR ZONA
      select distinct of_oficina
      from cobis..cl_oficina (nolock), ca_operacion (nolock)
      where of_zona        = @i_zona
      and   op_oficina     = of_oficina
      and   op_estado     in (0, 1, 2, 8, 9) -- VIGENTES, VENCIDAS, DIFERIDAS Y EN SUSPENSO
      and   op_naturaleza  = 'A'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES DE NATURALEZA ACTIVA
      and   op_tipo       <> 'G'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES NO FNG   
      order by of_oficina
   end

   return 0
end


/* HISTORICOS */
if @i_operacion = 'H' begin
   --> CONSULTA DEL ESTADO DE LA CARTERA A FIN DE MES PASADO
   --> LA CONSULTA SE PUEDE REALIZAR POR OFICIAL O POR OFICINA
   
   if @i_oficina is null begin
      print 'EL CODIGO DE LA OFICINA ES OBLIGATORIO'
      return 708150
   end
   
   /* DETERMINAR LA FECHA DEL FIN DE MES ANTERIOR */
   select @w_finmes_anterior = dateadd(dd, -datepart(dd, @w_fecha_proceso), @w_fecha_proceso)
   
   while exists(select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional and df_fecha = @w_finmes_anterior)
         select @w_finmes_anterior = dateadd(dd, -1, @w_finmes_anterior)   

   
   select 
   'Cod Oficial'          = do_oficial, 
   'Cant Prestamos'       = count(1), 
   'Saldo Total'          = sum(do_saldo_cap),
   'Cant Prest Mora 1-30' = sum(case when do_edad_mora between 1 and 30 then 1            else 0 end),
   'Monto Prest Mora 1-30'= sum(case when do_edad_mora between 1 and 30 then do_saldo_cap else 0 end),
   'Cant Prest Mora > 30' = sum(case when do_edad_mora > 30             then 1            else 0 end),
   'Monto Prest Mora > 30'= sum(case when do_edad_mora > 30             then do_saldo_cap else 0 end)
   from cob_conta_super..sb_dato_operacion (nolock)
   where do_fecha              = @w_finmes_anterior
   and   do_aplicativo         = 7
   and   do_oficina            = @i_oficina
   and   do_estado_contable   in (1, 2)                        -- SIN CASTIGOS NI CANCELACIONES AL MOMENTO DEL CIERRE
   and   do_tipo_operacion   not in ('SOL_APRO', 'SLCCUPO')    -- EXCLUIR APROBADOS NO DESEMBOLSADOS Y CUPOS DE SICREDITO
   and   do_naturaleza         = '1'                           -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES DE NATURALEZA ACTIVA
   and   do_oficial            = isnull(@i_oficial, do_oficial)
   group by do_oficial
   order by do_oficial

   return 0
   
end


/* CONSULTA DE CREDITOS APROBADOS NO DESEMBOLSADOS */
if @i_operacion = 'T' begin

   if @i_oficina is null begin
      print 'EL CODIGO DE LA OFICINA ES OBLIGATORIO'
      return 708150
   end

   --> CONSULTA DE LAS OPERACIONES QUE ESTAN APROBADAS PERO NO HAN SIDO DESEMBOLSADAS   
   if @i_oficial is not null  begin
   
      --> SI SE ENVIA EL OFICIAL SE ENTREGA SIEMPRE UN REGISTRO QUE INDICA LA CANTIDAD Y MONTO DE
      --  CREDITOS SUYOS QUE NO HAN SIDO DESEMBOLSADOS. SI NO TIENE CREDITOS PENDIENTES DE 
      --  DESEMBOLSO SE RETORNA 0
      select 
      'Oficial'              = @i_oficial,
      'Cant Prest No Desem'  = count(1),
      'Monto Prest No Desem' = sum(op_monto)
      from ca_operacion (nolock)
      where op_oficial     = @i_oficial
      and   op_oficina     = @i_oficina
      and   op_estado      = 0               -- NO VIGENTE
      and   op_naturaleza  = 'A'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES DE NATURALEZA ACTIVA
      and   op_tipo       <> 'G'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES NO FNG
      
   end else begin
   
      --> SI SE ENVIA LA OFICINA SE ENTREGA CANTIDAD Y MONTO DE LOS PRESTAMOS APROBADOS
      --  NO DESEMBOLSADOS AGRUPADOS POR OFICIAL. SOLO SE LISTAN LOS OFICIALES QUE TENGAN
      --  CREDITOS PENDIENTES DE DESEMBOLSO
      select 
      'Oficial'              = op_oficial,
      'Cant Prest No Desem'  = count(1),
      'Monto Prest No Desem' = sum(op_monto)
      from ca_operacion (nolock)
      where op_oficina     = @i_oficina
      and   op_estado      = 0               -- NO VIGENTE
      and   op_naturaleza  = 'A'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES DE NATURALEZA ACTIVA
      and   op_tipo       <> 'G'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES NO FNG
      group by op_oficial
   end
end


/* PROCESO */
if @i_operacion = 'P' begin

   --> CONSULTA DEL ESTADO DE LA CARTERA ACTIVA AL MOMENTO POR OFICIAL U OFICINA
   --> SE ADICIONAN A LA CONSULTA LOS OFICIALES QUE TUVIERON CARTERA ACTIVA A FIN DE MES PASADO
   create table #operaciones(
   operacion       int       not null,
   oficial         int       not null,
   fecha_ult_proc  datetime  not null,
   monto           money     not null,
   nueva           int       not null)
   
   select @w_finmes_anterior = dateadd(dd, -datepart(dd, @w_fecha_proceso), @w_fecha_proceso)
      
   if @i_oficial is not null
   begin
      select @w_estacion = es_estacion
      from cob_credito..cr_estacion with (nolock),
           cobis..cc_oficial with (nolock),
           cobis..cl_funcionario with (nolock)
      where es_usuario     = fu_login
        and fu_funcionario = oc_funcionario
        and oc_oficial     = @i_oficial


      if exists (select 1                              --Si existe, este oficial es ejecutivo master
                 from cob_credito..cr_etapa_estacion
                 where ee_master = @w_estacion) and @w_estacion is not null
      begin
         select oc_oficial into #ofi_master            --Oficiales a cargo del Master
         from cob_credito..cr_etapa_estacion with (nolock),
              cobis..cc_oficial with (nolock),
              cobis..cl_funcionario with (nolock),
              cob_credito..cr_estacion
         where ee_master      = @w_estacion
           and es_usuario     = fu_login
           and fu_funcionario = oc_funcionario
           and es_estacion     = ee_estacion

         insert into #operaciones
         select
         op_operacion,
         op_oficial,
         op_fecha_ult_proceso,
         op_monto,
         case when op_fecha_liq > @w_finmes_anterior then 1 else 0 end
         from ca_operacion (nolock)
         where op_oficial     in (select oc_oficial from #ofi_master) --Oficiales del Master
         and   op_oficina     = @i_oficina
         and   op_estado     in (1, 2, 8, 9)    -- VIGENTES, VENCIDAS, DIFERIDAS Y EN SUSPENSO
         and   op_naturaleza  = 'A'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES DE NATURALEZA ACTIVA
         and   op_tipo       <> 'G'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES NO FNG
         
         if @@error <> 0
         begin
            print 'ERROR EN PASO A TEMPORALES DE LAS OPERACIONES'
            return 703105
         end
      end
      else
      begin
         
         --> SI SE ENV-A EL OFICIAL SE ENTREGA EL ESTADO DE SU CARTERA ACTIVA
         --> SI NO SE TIENE NI SE TUVO CARTERA ACTIVA NO SE ENVIA INFORMACION A FRONTEND
         insert into #operaciones
         select 
         op_operacion, 
         op_oficial,
         op_fecha_ult_proceso,
         op_monto,
         case when op_fecha_liq > @w_finmes_anterior then 1 else 0 end
         from ca_operacion (nolock)
         where op_oficial     = @i_oficial
         and   op_oficina     = @i_oficina
         and   op_estado     in (1, 2, 8, 9)    -- VIGENTES, VENCIDAS, DIFERIDAS Y EN SUSPENSO
         and   op_naturaleza  = 'A'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES DE NATURALEZA ACTIVA
         and   op_tipo       <> 'G'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES NO FNG
      
         if @@error <> 0 begin
            print 'ERROR EN PASO A TEMPORALES DE LAS OPERACIONES'
            return 703105
         end
      end
   end
   else
   begin
      --> SI SE ENV-A OFICINA SE ENTREGA EL ESTADO DE LA CARTERA ACTIVA DE LA MISMA AGRUPADA POR OFICIAL      
      --> SI NO EXISTEN NI EXISTIERON PARA LA OFICINA OPERACIONES ACTIVAS NO SE RETORNA INFORMACION A FRONTEND
      insert into #operaciones
      select 
      op_operacion, 
      op_oficial,
      op_fecha_ult_proceso,
      op_monto,
      case when op_fecha_liq > @w_finmes_anterior then 1 else 0 end
      from ca_operacion (nolock)
      where op_oficina     = @i_oficina
      and   op_estado     in (1, 2, 8, 9)    -- VIGENTES, VENCIDAS, DIFERIDAS Y EN SUSPENSO
      and   op_naturaleza  = 'A'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES DE NATURALEZA ACTIVA
      and   op_tipo       <> 'G'             -- GAL 22/OCT/2009 - BANCAMIA PRODUCCION - CASO 1495 - REPORTE SOLO DEBE PRESENTAR OPERACIONES NO FNG     
         
      if @@error <> 0 begin
         print 'ERROR EN PASO A TEMPORALES DE LAS OPERACIONES'
         return 703105
      end
   end
   select
   operacion = operacion,
   oficial   = oficial,
   nueva     = nueva,
   monto     = monto,
   dias_mora = max(case when datediff(dd, di_fecha_ven, fecha_ult_proc) - di_gracia > 0 then datediff(dd, di_fecha_ven, fecha_ult_proc) else 0 end),  -- GAL 14/DIC/2009 - BANCAMIA PRODUCCCION - CASO 266 - GRACIA IMPACTA CALCULO DE DIAS MORA
   min_cuota = min(di_dividendo),
   max_cuota = max(di_dividendo)
   into #dias_mora
   from ca_dividendo (nolock), #operaciones
   where di_operacion = operacion
   and   di_estado   <> 3  
   group by operacion, oficial, nueva, monto
   
   if @@error <> 0 begin
      print 'ERROR EN PASO A TEMPORALES DE LOS DIAS MORA'
      return 703105
   end
   
   select
   sa_oficial            = oficial,
   sa_operacion          = operacion,
   sa_nueva              = nueva,
   sa_monto              = monto,
   sa_saldo              = am_saldo,
   sa_saldo_menor_30     = case when dias_mora between 1 and 30 then am_saldo else 0 end,
   sa_saldo_mayor_30     = case when dias_mora > 30             then am_saldo else 0 end
   into #saldos
   from ca_amortizacion_resumen (nolock), #dias_mora
   where am_operacion = operacion
 
   select
   oficial              = sa_oficial, 
   cartera_activa_nro   = count(1), 
   cartera_activa_monto = sum(sa_saldo),
   mora_menor_30        = sum(sa_saldo_menor_30),
   mora_mayor_30        = sum(sa_saldo_mayor_30),
   colocacion_nro       = sum(sa_nueva),
   colocacion_monto     = sum(case when sa_nueva <> 0 then sa_monto else 0 end) 
   from #saldos
   group by sa_oficial  
   order by sa_oficial

   --seleccion con alianzas
   select
   oficial              = sa_oficial, 
   cartera_activa_nro   = count(1), 
   cartera_activa_monto = sum(sa_saldo),
   mora_menor_30        = sum(sa_saldo_menor_30),
   mora_mayor_30        = sum(sa_saldo_mayor_30),
   colocacion_nro       = sum(sa_nueva),
   colocacion_monto     = sum(case when sa_nueva <> 0 then sa_monto else 0 end) 
   from #saldos, cob_credito..cr_tramite A
   where tr_numero_op = sa_operacion
   and tr_alianza is not null
   and tr_alianza in (select al_alianza from cobis..cl_alianza_cliente with (nolock),
                      cobis..cl_alianza   with (nolock)
   			where ac_ente    = A.tr_cliente
     			and ac_alianza = al_alianza
     			and al_estado  = 'V'
     			and ac_estado  = 'V')
   group by sa_oficial  
   order by sa_oficial

   --seleccion sin alianzas
   select
   oficial              = sa_oficial, 
   cartera_activa_nro   = count(1), 
   cartera_activa_monto = sum(sa_saldo),
   mora_menor_30        = sum(sa_saldo_menor_30),
   mora_mayor_30        = sum(sa_saldo_mayor_30),
   colocacion_nro       = sum(sa_nueva),
   colocacion_monto     = sum(case when sa_nueva <> 0 then sa_monto else 0 end) 
   from #saldos, cob_credito..cr_tramite A
   where tr_numero_op = sa_operacion
   and tr_alianza is null
   group by sa_oficial  
   order by sa_oficial
   
   
   return 0

end

return 0

ERROR:

exec cobis..sp_cerror
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return 1

go


/******

select
am_operacion = am_operacion,
am_saldo     = sum(am_cuota - am_pagado)
into ca_amortizacion_resumen
from ca_amortizacion, ca_dividendo
where am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   am_concepto  = 'CAP'
and   di_estado   <> 3
group by am_operacion

create unique  clustered index idx1 on ca_amortizacion_resumen(am_operacion)


*******/
