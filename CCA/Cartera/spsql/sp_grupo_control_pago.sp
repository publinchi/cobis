/************************************************************************/
/*      Archivo:                sp_grupo_control_pago.sp                */
/*      Stored procedure:       sp_grupo_control_pago                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           LGU                                     */
/*      Fecha de escritura:     May/2017                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes exclusivos para el Ecuador de la       */
/*      'NCR CORPORATION'.                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Mantenimiento de la tabla de control de pago                    */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/*    22/May/17             LGU              Emision Inicial            */
/************************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_grupo_control_pago')
    drop proc sp_grupo_control_pago
go
create proc sp_grupo_control_pago
        @i_banco             cuenta = null,         --cuenta grupal padre
        @i_operacionca       int    = null,         --cuenta grupal hijo
        @i_dividendo         smallint = null, --Bandera en el cual indica si trabaja en tablas tmp o definitivas
        @i_pago_solidario    money = null,
        @i_garantia_liquida  money = null,
        @i_ahorro_voluntario money = null,
        @i_opcion            char(1)  -- I=Insert, U=update
as
declare @w_operacionca       int,
        @w_error             int,
        @w_sp_name           descripcion,
        @w_tipo_amortizacion catalogo,
        @w_monto             money,
        @w_sector            varchar(10),
        @w_subsegmento       varchar(10),
        @w_saldo             money,
        @w_cliente           int,
        @w_creditos          smallint,
        @w_estado_grupal     tinyint,
        @w_div               smallint,
        @w_fecha_ven         date,
        @w_dividendo         int,
        @w_min_fpago         datetime -- LGU: fecha de cancelacion del dividendo


--     where tg_referencia_grupal = @i_banco) and exists (select 1 from cob_credito..cr_tramite_grupal, ca_operacion
--     where tg_referencia_grupal = @i_banco
--     and tg_operacion = op_operacion
--     and tg_monto > 0
--     and op_estado <> 3)

   if @i_opcion in ('I', 'E', 'M')
   begin
      create table #TMP_dividendo (
         di_operacion   int,
         di_dividendo   int,
         div_padre      int,
         di_estado      int,
         tipo           char(1))

      --tramites grupales normales
      insert into #TMP_dividendo
      (di_operacion,     di_dividendo,  div_padre,                   di_estado,  tipo)
      select
      di_operacion,      di_dividendo,  'div_padre' = di_dividendo,  di_estado,  tg_grupal
      from cob_cartera..ca_dividendo, cob_credito..cr_tramite_grupal
      where tg_referencia_grupal = @i_banco     --papa
      and di_operacion = tg_operacion
      and tg_grupal = 'S'
      and convert(varchar, tg_operacion) <> tg_prestamo
      order by di_operacion, di_dividendo

      --tramites grupales emergentes o interciclos
      select H.op_operacion, di_dividendo, 'desplazar' = di_dividendo -1, tg_grupal
      into #tmp1
      from cob_cartera..ca_dividendo, cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion H, cob_cartera..ca_operacion P
      where tg_referencia_grupal = @i_banco     --papa
      and tg_referencia_grupal  = P.op_banco
      and di_operacion = P.op_operacion
      and tg_operacion = H.op_operacion
      and tg_grupal = 'N'
      and H.op_fecha_ini between di_fecha_ini and di_fecha_ven
      order by di_operacion, di_dividendo asc

      --duplicacion de fechas
      select top 1 @w_operacionca= op_operacion from #tmp1 where desplazar > 0 order by 1 asc
      while 1=1
      begin
        select @w_dividendo = max(di_dividendo) from #tmp1 where desplazar > 0 and op_operacion = @w_operacionca
        delete #tmp1 where desplazar > 0 and op_operacion = @w_operacionca and di_dividendo > 0 and di_dividendo < @w_dividendo

        select top 1 @w_operacionca = op_operacion from #tmp1 where desplazar > 0 and op_operacion > @w_operacionca
        if @@rowcount = 0
           break
      end

      select top 1 @w_operacionca = op_operacion from #tmp1
      group by op_operacion
      having count(op_operacion) > 1
      while 1=1
      begin
        select  @w_dividendo = max(di_dividendo) from #tmp1 where op_operacion = @w_operacionca
        delete #tmp1 where op_operacion = @w_operacionca and di_dividendo < @w_dividendo

        select top 1 @w_operacionca = op_operacion from #tmp1
        where op_operacion > @w_operacionca
        group by op_operacion
        having count(op_operacion) > 1
        if @@rowcount = 0
           break
      end

      insert into #TMP_dividendo
      (di_operacion,     di_dividendo,    div_padre,                                 di_estado,  tipo)
      select
       di_operacion,     d.di_dividendo, 'div_padre' = d.di_dividendo + desplazar,   di_estado,  'tipo' = 'N'
      from cob_cartera..ca_dividendo d, #tmp1 t
      where di_operacion = op_operacion
      order by di_operacion, di_dividendo

   end --if @i_opcion in ('I', 'E', 'M')


   select @w_operacionca       = op_operacion,
          @w_tipo_amortizacion = op_tipo_amortizacion,
          @w_monto             = op_monto,
          @w_sector            = op_sector,
          @w_cliente           = op_cliente
   from ca_operacion
   where op_banco = @i_banco

   if @i_opcion = 'I' -- CREAR CON LAS GRUPALES
   begin
      delete ca_control_pago where cp_referencia_grupal = @i_banco

      insert into ca_control_pago (
         cp_grupo             ,
         cp_operacion         ,
         cp_referencia_grupal ,
         cp_dividendo_grupal  ,
         cp_dividendo         ,
         cp_cuota_pactada     ,
         cp_saldo_pagar       ,
         cp_saldo_vencido     ,
         cp_pago              ,
         cp_ahorro            ,
         cp_extras            ,
         cp_pago_solidario    ,
         cp_gar_liquida_disp  ,
         cp_estado            )
      select
         (select op_cliente from ca_operacion where op_banco = @i_banco),
         di_operacion,
         @i_banco,
         div_padre,
         di_dividendo,
         (select op_cuota from ca_operacion where op_operacion = T.di_operacion),

         isnull((select sum(isnull(A.am_acumulado,0)+isnull(A.am_gracia,0) )
                                  from ca_amortizacion A
                                   WHERE  A.am_operacion = T.di_operacion
                                   and A.am_dividendo = T.di_dividendo),0),

         isnull((select sum(isnull(A.am_acumulado,0)+isnull(A.am_gracia,0)-isnull(A.am_pagado,0))
                                  from ca_amortizacion A, ca_dividendo D
                                   where A.am_operacion = T.di_operacion
                                   and A.am_dividendo = T.di_dividendo
                                   and A.am_operacion = D.di_operacion
                                   and A.am_dividendo = D.di_dividendo
                                   and D.di_estado    = 2   ),0),
         isnull((select sum(isnull(A.am_pagado,0))
                                  from ca_amortizacion A
                                   where A.am_operacion = T.di_operacion
                                   and A.am_dividendo = T.di_dividendo
                                   ),0),
         0,
         0,
         0,
         0,
         0
      from #TMP_dividendo T
      select @w_error = @@error
      if @w_error<> 0
         return 710001
   end  --if @i_opcion = 'I'

   if @i_opcion = 'E' -- CREAR CON LAS EMERGENTES
   begin
      return 0  --  se implementara despues
   end -- if @i_opcion = 'E' -- CREAR CON LAS EMERGENTES

   if @i_opcion = 'M' -- mantenimiento
   begin
      select @w_dividendo = di_dividendo
      from ca_dividendo
      where di_operacion = @w_operacionca -- padre
      and di_estado  = 1
      if @@rowcount = 0  -- no existe vigente, busco el maximo vencido
      begin
         select @w_dividendo = max(di_dividendo)
         from ca_dividendo
         where di_operacion = @w_operacionca -- padre
         and di_estado  = 2
         if @@rowcount = 0  -- no existe vencido, busco el minimo NO vigente
         begin
            select @w_dividendo = min(di_dividendo)
            from ca_dividendo
            where di_operacion = @w_operacionca -- padre
            and di_estado  = 0
            if @@rowcount = 0  -- no existe vigente, vencido,no vigente --> cancelado, no hago nada
            begin
               return 0
            end
         end
      end

      update ca_control_pago set
         cp_estado            = 0
      from #TMP_dividendo T
      where cp_operacion = di_operacion
      and cp_dividendo = div_padre
      and div_padre    between @w_dividendo -1 and  @w_dividendo  ---- para no actualziar todo
      and cp_referencia_grupal = @i_banco

      update ca_control_pago set
         cp_cuota_pactada     =   (select op_cuota from ca_operacion where op_operacion = T.di_operacion),
         cp_saldo_pagar       =   isnull((select sum(isnull(A.am_acumulado,0)+isnull(A.am_gracia,0) )
                                  from ca_amortizacion A
                                   WHERE  A.am_operacion = T.di_operacion
                                   and A.am_dividendo = T.di_dividendo),0),
         cp_saldo_vencido     =   isnull((select sum(isnull(A.am_acumulado,0)+isnull(A.am_gracia,0)-isnull(A.am_pagado,0))
                                  from ca_amortizacion A, ca_dividendo D
                                   where A.am_operacion = T.di_operacion
                                   and A.am_dividendo = T.di_dividendo
                                   and A.am_operacion = D.di_operacion
                                   and A.am_dividendo = D.di_dividendo
                                   and D.di_estado    = 2   ),0),
         cp_pago              =   isnull((select sum(isnull(A.am_pagado,0))
                                  from ca_amortizacion A
                                   where A.am_operacion = T.di_operacion
                                   and A.am_dividendo = T.di_dividendo
                                   ),0),
         cp_ahorro            = 0,
         cp_extras            = 0,
         cp_pago_solidario    = 0,
         cp_gar_liquida_disp  = 0,
         cp_estado            = 1
      from #TMP_dividendo T
      where cp_operacion = di_operacion
      and cp_dividendo = div_padre
      and div_padre    = @w_dividendo
      and cp_referencia_grupal = @i_banco

      if @@error <> 0
         return 710002

   end -- if @i_opcion = 'M' -- mantenimiento


   if @i_opcion = 'U' -- Pagos solidarios
   begin
      update ca_control_pago set
         cp_pago_solidario   = isnull(@i_pago_solidario,0),
         cp_ahorro           = isnull(@i_garantia_liquida,0),
         cp_gar_liquida_disp = isnull(@i_ahorro_voluntario,0)
      where cp_operacion       = @i_operacionca
      and cp_referencia_grupal = @i_banco
      and cp_dividendo_grupal  = @i_dividendo
      if @@error <> 0
         return 710002
   end -- if @i_opcion = 'P' -- Pago solidario


return 0
go

