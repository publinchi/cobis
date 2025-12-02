/************************************************************************/
/*  Archivo:                        ppaggrup.sp                         */
/*  Stored procedure:               sp_prorratea_pago_grupal            */
/*  Base de datos:                  cob_cartera                         */
/*  Producto:                       Cartera                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                  PROPOSITO                           */
/*  Realiza la aplica prorrateo de pago grupal e interciclos            */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA               AUTOR                 RAZON                 */
/*      01/07/2019          Sandro Vallejo        Emision Inicial       */
/*      03/07/2019          Luis Ponce            Precancelaciones      */
/************************************************************************/

use cob_cartera
go

/* CREATE TABLE ca_secuencial_pago_grupal (
   pg_operacion_pago  int,
   pg_secuencial_pago int,
   pg_banco_pago      cuenta,
   pg_monto_total     money,
   pg_operacion       int,
   pg_secuencial_ing  int,
   pg_banco           cuenta, 
   pg_producto        catalogo,
   pg_moneda          tinyint,
   pg_monto_pago      money,
   pg_fecha_ing       datetime,
   pg_fecha_real      datetime,
   pg_estado          char(1))

   create unique index ca_secuencial_pago_grupal_1 on ca_secuencial_pago_grupal (pg_operacion_pago, pg_secuencial_pago)

   create unique index ca_secuencial_pago_grupal_2 on ca_secuencial_pago_grupal (pg_operacion, pg_secuencial_ing)
*/

if exists (select 1 from sysobjects where name = 'sp_prorratea_pago_grupal')
    drop proc sp_prorratea_pago_grupal
go

create proc sp_prorratea_pago_grupal
       @s_user                  login        = null,
       @s_term                  varchar(30)  = null,
       @s_srv                   varchar(30)  = null,  
       @s_date                  datetime     = null,
       @s_sesn                  int          = null,
       @s_ssn                   int          = null,
       @s_ofi                   smallint     = null,
       @s_rol                   smallint     = null,
       @i_banco                 cuenta,      --cuenta grupal padre
       @i_beneficiario          descripcion  = 'DB.AUT', 
       @i_monto_pago            money,       --monto de pago a aplicar
       @i_forma_pago            catalogo,    --forma de pago a aplicar
       @i_moneda_pago           smallint,    --moneda de pago a aplicar 
       @i_fecha_pago            datetime,    --fecha de pago a aplicar
       @i_referencia            descripcion, --detalle de pago a aplicar
       @i_dividendo             smallint     = NULL,
       @i_tipo_reduccion        char(1)      = NULL,
       @i_operacion             CHAR(1)      = NULL,
       @o_secuencial_ing        INT          = NULL OUT,
       @o_msg_matriz            varchar(255) = NULL OUT
as
declare @w_sp_name              descripcion,
        @w_error                int,
        @w_operaciongp          int,
        @w_operacionca          int,
        @w_moneda               smallint,
        @w_estado               tinyint,
        @w_fecha_liq            datetime,
        @w_fecha_ult_proceso    datetime,
        @w_secuencial_pago      int,
        @w_tipo_cobro           char(1),
        @w_monto_interciclo     money,
        @w_porcentaje           float,
        @w_op_ultima            int,
        @w_porcentaje_tot       float,
        @w_secuencial_ing       int,
        @w_banco                cuenta,
        @w_fecha_valor          datetime,
        @w_est_vigente          tinyint,
        @w_est_vencido          tinyint,
        @w_est_cancelado        tinyint,
        @w_est_novigente        tinyint,
        @w_vencido_grupal       money,
        @w_vencido_interciclo   money,
        @w_vigente_grupal       money,
        @w_vigente_interciclo   money,
        @w_monto_pago           money,
        @w_monto_aplicar        money,
        @w_ejecuta              INT,
        @w_toperacion           catalogo,
        @w_novigente_grupal     MONEY,
        @w_novigente_interciclo MONEY,
        @w_total_precancelar    MONEY,
        @w_msg_matriz           varchar(255),
        @w_di_fecha_ven         DATETIME,
        @w_tipo                 CHAR(1),
        @w_diferencia           money,
        @w_exigible             money
       
        
        
select @w_sp_name = 'sp_prorratea_pago_grupal'

/* ESTADOS DE CARTERA */
exec @w_error         = sp_estados_cca
     @o_est_vigente   = @w_est_vigente   out,
     @o_est_vencido   = @w_est_vencido   out,
     @o_est_cancelado = @w_est_cancelado out,
     @o_est_novigente = @w_est_novigente out
 
if @w_error <> 0 return 708201



/* VALIDACIONES */

/* VERIFICAR EXISTENCIA DE OPERACION GRUPAL */
select @w_operaciongp       = op_operacion,
       @w_moneda            = op_moneda,
       @w_estado            = op_estado,
       @w_fecha_liq         = op_fecha_liq,
       @w_fecha_ult_proceso = op_fecha_ult_proceso,
       @w_toperacion        = op_toperacion,
       @w_tipo_cobro        = op_tipo_cobro
from   ca_operacion                                                                                                                                                                                                                                    
where  op_banco = @i_banco    
                                                                                                                                                                                                                                                          
if @@rowcount = 0 return 701049

/*DETERMINAR EL TIPO DE COBRO DEL PRODUCTO*/
/*SELECT @w_tipo_cobro = dt_tipo_cobro  --LPO TEC Se deja el tipo de cobro desde la Operacion, no desde el Producto
from ca_default_toperacion
WHERE dt_toperacion = @w_toperacion
*/

/* VERIFICAR QUE LA MONEDA DEL PAGO CORRESPONDA A LA MONEDA DE LA OPERACION */
if @i_moneda_pago <> @w_moneda
   return 710085

/* VERIFICAR QUE LA FORMA DE PAGO EXISTA */
if not exists (select 1 from ca_producto
               where  cp_producto = @i_forma_pago)
   return 710416

/* VERIFICAR QUE LA FORMA DE PAGO SEA VALIDA PARA LA MONEDA */
if not exists (select 1 from ca_producto
               where  cp_producto = @i_forma_pago
               and    cp_moneda   = @i_moneda_pago)
   return 708188

/* VERIFICAR QUE EL ESTADO DE LA OPERACION PERMITA PAGOS */
if not exists (select 1 from ca_estado
               where  es_codigo      = @w_estado
               and    es_acepta_pago = 'S')
if @@rowcount = 0
   return 70186 

/* VERIFICAR SI EL PAGO ES A FECHA FUTURA */
if @i_fecha_pago > @w_fecha_ult_proceso
   return 724517 

/* CREAR TABLAS TEMPORALES */                                                                                                                                                                                                                                              
/* CREAR TABLA DE OPERACIONES INTERCICLOS */
create table #TMP_operaciones (
       operacion     int,
       banco         cuenta,
       fecha_proceso datetime,
       fecha_liq     datetime)

/* CREAR TABLA DE OPERACIONES QUE DEBEN EJECUTAR FECHA VALOR */
create table #TMP_fecha_valor (
       operacion     DATETIME,
       banco         cuenta,
       fecha_liq     DATETIME,
       fecha_proc    DATETIME)  --LPO TEC para regresar las operaciones a su fecha de ultimo proceso. 

/* CREAR TABLA DE PORCENTAJES INTERCICLOS VENCIDOS */
create table #TMP_porcentaje_vencido (
       operacion     int,
       --banco         cuenta,
       monto         money,
       porcentaje    float)

/* CREAR TABLA DE PORCENTAJES INTERCICLOS VIGENTES */
create table #TMP_porcentaje_vigente (
       operacion     int,
       --banco         cuenta,
       monto         money,
       porcentaje    float)

/* CREAR TABLA DE OPERACION Y MONTO A APLICAR */
create table #TMP_monto_pago (
       operacion       int,
       banco           cuenta,
       tipo            char(1),      --G=GRUPAL, I=INTERCICLO
       monto_vencido   money,
       monto_vigente   MONEY,
       monto_novigente MONEY)        --LPO TEC Saldo No Vigente, para precancelaciones

/* CREAR TABLA DE SALDOS NO VIGENTES DE LAS OP.GRUPAL E INTERCICLOS*/ --LPO TEC 
create table #TMP_saldos_novigente (
       operacion       INT,
       monto           MONEY) 

/* DETERMINAR LAS OPERACIONES INTERCICLOS */
insert into #TMP_operaciones
select op_operacion, op_banco, op_fecha_ult_proceso, op_fecha_liq
from   ca_operacion
where  op_operacion in (select dc_operacion from ca_det_ciclo where dc_referencia_grupal = @i_banco and dc_tciclo = 'I')   
order by op_operacion

/* ATOMICIDAD POR TRANSACCION */
begin tran

/* GENERAR SECUENCIAL DE PAGO */
exec @w_secuencial_pago = sp_gen_sec
     @i_operacion       = @w_operaciongp

/* VERIFICAR SI EL PAGO ES A FECHA ANTERIOR */
if @i_fecha_pago < @w_fecha_ult_proceso
   /* INSERTAR OPERACION GRUPAL */
   insert into #TMP_fecha_valor values(@w_operaciongp, @i_banco, @w_fecha_liq, @w_fecha_ult_proceso) --LPO TEC se adiciona fecha de ult proceso


/* VERIFICAR SI SE DEBE EJECUTAR EL FECHA VALOR DE OPERACIONES INTERCICLO */
insert into #TMP_fecha_valor 
select operacion, banco, fecha_liq, fecha_proceso --LPO TEC se adiciona fecha de ult proceso
from   #TMP_operaciones
where  fecha_proceso <> @i_fecha_pago

/* EJECUTAR EL PROCESO DE FECHA VALOR */
declare cursor_fecha_valor cursor for
select  banco, fecha_liq
from    #TMP_fecha_valor
for read only
   
open    cursor_fecha_valor
fetch   cursor_fecha_valor 
into    @w_banco, @w_fecha_liq
   
/* WHILE cursor_fecha_valor */
while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) 
   begin
      select @w_error = 71003
      goto ERROR
   end
  
   /* SI LA FECHA DE PAGO ES MENOR A LA DE DESEMBOLSO */
   if @i_fecha_pago < @w_fecha_liq
      select @w_fecha_valor = @w_fecha_liq
   else
      select @w_fecha_valor = @i_fecha_pago

   /* APLICAR PROCESO DE FECHA VALOR */
   exec @w_error        = sp_fecha_valor
        @s_date         = @s_date,
        @s_ofi          = @s_ofi,
        @s_sesn         = @s_sesn,
        @s_ssn          = @s_ssn,
        @s_srv          = @s_srv,
        @s_term         = @s_term,
        @s_user         = @s_user,
        @t_trn          = 7049,
        @i_operacion    = 'F',
        @i_banco        = @w_banco,
        @i_fecha_valor  = @w_fecha_valor,
        @i_observacion  = 'PAGO FECHA VALOR'

   if @w_error <> 0 
   begin
      close cursor_fecha_valor 
      deallocate cursor_fecha_valor

      goto ERROR
   end

   fetch   cursor_fecha_valor 
   into    @w_banco, @w_fecha_liq

end /* WHILE cursor_fecha_valor */

close cursor_fecha_valor
deallocate cursor_fecha_valor


/* INICIALIZAR MONTO DE PAGO */
select @w_monto_pago = @i_monto_pago

/*LPO TEC INICIALIZAR VARIABLES DE MONTOS */
select @w_vencido_grupal       = 0
select @w_vencido_interciclo   = 0
select @w_vigente_grupal       = 0
select @w_vigente_interciclo   = 0
select @w_novigente_grupal     = 0
select @w_novigente_interciclo = 0


/* INSERTAR OPERACIONES EN TABLA DE VALORES A APLICAR */
/* INSERTA OPERACION GRUPAL */
insert #TMP_monto_pago values (@w_operaciongp, @i_banco, 'G', 0 , 0, 0)


/* INSERTA OPERACIONES INTERGRUPALES */
insert #TMP_monto_pago
select operacion, banco, 'I', 0, 0, 0
from   #TMP_operaciones 
where  fecha_liq <= @i_fecha_pago
order by operacion


/* DETERMINAR EL MONTO VENCIDO DE LA OPERACION GRUPAL */
select @w_vencido_grupal = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
from   ca_amortizacion, ca_dividendo
where  di_operacion = am_operacion
and    di_dividendo = am_dividendo
and    di_operacion = @w_operaciongp
and    di_estado    = @w_est_vencido
and    am_estado   <> @w_est_cancelado

select @w_vencido_grupal = isnull(@w_vencido_grupal, 0)


/* VERIFICAR MONTO VENCIDO GRUPAL */
if @w_vencido_grupal > 0
begin
   if @w_vencido_grupal > @w_monto_pago
      select @w_monto_aplicar = @w_monto_pago
   else
      select @w_monto_aplicar = @w_vencido_grupal

   update #TMP_monto_pago set monto_vencido = @w_monto_aplicar
   where  banco = @i_banco

   /* DISMINUIR MONTO A PAGAR */
   select @w_monto_pago = @w_monto_pago - @w_monto_aplicar
end


/* SI EXISTE MONTO A APLICAR */
if @w_monto_pago > 0
begin
   /* DETERMINAR EL MONTO VENCIDO DE LAS OPERACIONES INTERCICLOS */
   select @w_vencido_interciclo = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
   from   ca_amortizacion, ca_dividendo
   where  di_operacion  = am_operacion
   and    di_dividendo  = am_dividendo
   and    di_operacion in (select operacion from #TMP_operaciones where fecha_liq <= @i_fecha_pago)
   and    di_estado     = @w_est_vencido
   and    am_estado    <> @w_est_cancelado

   select @w_vencido_interciclo = isnull(@w_vencido_interciclo, 0)

   /* VERIFICAR MONTO VENCIDO INTERCICLO */
   if @w_vencido_interciclo > 0
   begin
      /* DETERMINAR VALORES DE PORCENTAJES DE PAGO POR INTERCICLO VENCIDO */
      insert into #TMP_porcentaje_vencido
      select di_operacion, (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2,
             (((sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2 * 100.0) / @w_vencido_interciclo)
      from   ca_amortizacion, ca_dividendo
      where  di_operacion  = am_operacion
      and    di_dividendo  = am_dividendo
      and    di_operacion in (select operacion from #TMP_operaciones where fecha_liq <= @i_fecha_pago)
      and    di_estado     = @w_est_vencido
      and    am_estado    <> @w_est_cancelado
      group by di_operacion
      
      /* SI EL VALOR VENCIDO ES MAYOR MONTO DISTRIBUIR */
      if @w_vencido_interciclo > @w_monto_pago --LPO TEC @w_vencido_interciclo
      begin
         select @w_monto_aplicar = @w_monto_pago

         update #TMP_monto_pago set monto_vencido = round(((@w_monto_aplicar * porcentaje)/100.0), 2)  --LPO TEC /100.0
         from   #TMP_porcentaje_vencido A, #TMP_monto_pago B
         where  B.operacion = A.operacion

         /* VALIDAR NO SOBREPASAR EL MONTO DE DEUDA*/
         update #TMP_monto_pago set monto_vencido = monto
         from   #TMP_porcentaje_vencido A, #TMP_monto_pago B
         where  B.operacion       = A.operacion
         and    monto_vencido > monto

         --select @w_monto_aplicar = @w_vencido_interciclo --LPO TEC debe ser @w_monto_aplicar = @w_monto_pago
      end
      /* APLICAR LOS VALORES DE DEUDA */
      else
      begin
         update #TMP_monto_pago set monto_vencido = monto
         from   #TMP_porcentaje_vencido A, #TMP_monto_pago B
         where  B.operacion = A.operacion

         select @w_monto_aplicar = @w_vencido_interciclo
      end

      /* DISMINUIR MONTO A PAGAR */
      select @w_monto_pago = @w_monto_pago - @w_monto_aplicar
   end
end

/* SI EXISTE MONTO A APLICAR */
if @w_monto_pago > 0
begin
   /* DETERMINAR EL MONTO VIGENTE DE LA OPERACION GRUPAL */
   if @w_tipo_cobro = 'P' -- Paga los interes proyectados
      select @w_vigente_grupal = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
      from   ca_amortizacion, ca_dividendo
      where  di_operacion = am_operacion
      and    di_dividendo = am_dividendo
      and    di_operacion = @w_operaciongp
      and    di_estado    = @w_est_vigente
      and    am_estado   <> @w_est_cancelado
   else -- Paga los interes acumulados
      select @w_vigente_grupal = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
      from   ca_amortizacion, ca_dividendo
      where  di_operacion = am_operacion
      and    di_dividendo = am_dividendo
      and    di_operacion = @w_operaciongp
      and    di_estado    = @w_est_vigente
      and    am_estado   <> @w_est_cancelado

    select @w_vigente_grupal = isnull(@w_vigente_grupal, 0)

   /* VERIFICAR MONTO VIGENTE GRUPAL */
   if @w_vigente_grupal > 0
   begin
      if @w_vigente_grupal > @w_monto_pago
         select @w_monto_aplicar = @w_monto_pago
      else
         select @w_monto_aplicar = @w_vigente_grupal

      update #TMP_monto_pago set monto_vigente = @w_monto_aplicar
      where  banco = @i_banco

      /* DISMINUIR MONTO A PAGAR */
      select @w_monto_pago = @w_monto_pago - @w_monto_aplicar
   end
end

/* SI EXISTE MONTO A APLICAR */
if @w_monto_pago > 0
begin
   /* DETERMINAR EL MONTO VIGENTE DE LAS OPERACIONES INTERCICLOS */
   if @w_tipo_cobro = 'P' -- Paga los interes proyectados
      select @w_vigente_interciclo = (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2
      from   ca_amortizacion, ca_dividendo
      where  di_operacion  = am_operacion
      and    di_dividendo  = am_dividendo
      and    di_operacion in (select operacion from #TMP_operaciones where fecha_liq <= @i_fecha_pago)   
      and    di_estado     = @w_est_vigente
      and    am_estado    <> @w_est_cancelado
   else -- Paga los interes acumulados
      select @w_vigente_interciclo = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
      from   ca_amortizacion, ca_dividendo
      where  di_operacion  = am_operacion
      and    di_dividendo  = am_dividendo
      and    di_operacion in (select operacion from #TMP_operaciones where fecha_liq <= @i_fecha_pago)
      and    di_estado     = @w_est_vigente
      and    am_estado    <> @w_est_cancelado

   select @w_vigente_interciclo = isnull(@w_vigente_interciclo, 0)

   /* DETERMINAR VALORES DE PORCENTAJES DE PAGO POR INTERCICLO VIGENTE */
   if @w_vigente_interciclo > 0
   begin
      if @w_tipo_cobro = 'P' -- Paga los interes proyectados
         insert into #TMP_porcentaje_vigente
         select di_operacion, (sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2,
                (((sum(am_cuota + am_gracia - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2 * 100.0) / @w_vigente_interciclo)
         from   ca_amortizacion, ca_dividendo
         where  di_operacion  = am_operacion
         and    di_dividendo  = am_dividendo
         and    di_operacion in (select operacion from #TMP_operaciones where fecha_liq <= @i_fecha_pago)
         and    di_estado     = @w_est_vigente
         and    am_estado    <> @w_est_cancelado
         group by di_operacion
      else -- Paga los interes acumulados
         insert into #TMP_porcentaje_vigente
         select di_operacion, (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2,
                (((sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2 * 100.0) / @w_vigente_interciclo)
         from   ca_amortizacion, ca_dividendo
         where  di_operacion  = am_operacion
         and    di_dividendo  = am_dividendo
         and    di_operacion in (select operacion from #TMP_operaciones where fecha_liq <= @i_fecha_pago)
         and    di_estado     = @w_est_vigente
         and    am_estado    <> @w_est_cancelado
         group by di_operacion
         
      /* SI EL VALOR VENCIDO ES MAYOR MONTO DISTRIBUIR */
      if @w_vigente_interciclo > @w_monto_pago
      begin
      
         select @w_monto_aplicar = @w_monto_pago
   
         update #TMP_monto_pago set monto_vigente = round(((@w_monto_aplicar * porcentaje)/100.0), 2) --LPO TEC /100.0
         from   #TMP_porcentaje_vigente A, #TMP_monto_pago B
         where  B.operacion = A.operacion
         
         /* VALIDAR NO SOBREPASAR EL MONTO DE DEUDA*/
         update #TMP_monto_pago set monto_vigente = monto
         from   #TMP_porcentaje_vigente A, #TMP_monto_pago B
         where  B.operacion       = A.operacion
         and    monto_vigente > monto

         --select @w_monto_aplicar = @w_vigente_interciclo  --LPO TEC debe ser select @w_monto_aplicar = @w_monto_pago
      end
      /* APLICAR LOS VALORES DE DEUDA */
      else
      begin
         update #TMP_monto_pago set monto_vigente = monto
         from   #TMP_porcentaje_vigente A, #TMP_monto_pago B
         where  B.operacion = A.operacion

         select @w_monto_aplicar = @w_vigente_interciclo
      end

      /* DISMINUIR MONTO A PAGAR */
      select @w_monto_pago = @w_monto_pago - @w_monto_aplicar
   end
end

/* DETERMINAR EL MONTO NO VIGENTE DE LA OPERACION GRUPAL */
select @w_novigente_grupal = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
from   ca_amortizacion, ca_dividendo, ca_rubro_op
where  di_operacion = am_operacion
and    di_dividendo = am_dividendo
and    di_operacion = @w_operaciongp
and    di_estado    = @w_est_novigente
and    am_estado   <> @w_est_cancelado
and    di_operacion = ro_operacion
and    am_operacion = ro_operacion
and    ro_concepto  = am_concepto
and    ro_tipo_rubro = 'C'


/* DETERMINAR EL MONTO NO VIGENTE DE LAS OPERACIONES INTERCICLOS */
select @w_novigente_interciclo = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
   from   ca_amortizacion, ca_dividendo, ca_rubro_op
   where  di_operacion  = am_operacion
   and    di_dividendo  = am_dividendo
   and    di_operacion  IN (select operacion from #TMP_operaciones where fecha_liq <= @i_fecha_pago)
   and    di_estado     = @w_est_novigente
   and    am_estado     <> @w_est_cancelado
   and    di_operacion = ro_operacion
   and    am_operacion = ro_operacion
   and    ro_concepto  = am_concepto
   and    ro_tipo_rubro = 'C'
   

select @w_novigente_grupal  = isnull(@w_novigente_grupal,0)
select @w_novigente_interciclo = isnull(@w_novigente_interciclo,0)

select @w_vencido_grupal       = isnull(@w_vencido_grupal,0)
select @w_vencido_interciclo   = isnull(@w_vencido_interciclo,0)
select @w_vigente_grupal       = isnull(@w_vigente_grupal,0)
select @w_vigente_interciclo   = isnull(@w_vigente_interciclo,0)

select @w_total_precancelar = @w_vencido_grupal + @w_vencido_interciclo + @w_vigente_grupal + @w_vigente_interciclo + @w_novigente_grupal + @w_novigente_interciclo

--SELECT @w_monto_pago = round(@w_monto_pago ,2) --LPO Redondeo a 2 decimales

select @w_diferencia = @i_monto_pago - @w_total_precancelar

if abs(@w_diferencia) < 0.01
   select @w_total_precancelar = @i_monto_pago --@w_total_precancelar - abs(@w_diferencia)
 

/* --LPO TEC. NO ACEPTAR PAGOS EXTRAORDINARIOS, A MENOS QUE SEA UN PAGO PARA PRECANCELACION (CANCELACION TOTAL)*/
IF @w_monto_pago >= 0.01
BEGIN
   IF @i_monto_pago > @w_total_precancelar
   BEGIN
      select @w_error = 710115 --El monto de pago sobrepasa el saldo total
      goto ERROR
   END
   
   IF @i_monto_pago < @w_total_precancelar
   BEGIN
      select @w_error = 710109 --La forma de pago esta parametrizado para no aceptar pagos extraordinarios
      goto ERROR
   END
END


/* LPO TEC. ACTUALIZAR EN #TMP_monto_pago EL MONTO NO VIGENTE DE LA OPERACION GRUPAL */
IF @w_monto_pago >= 0.01 AND @i_monto_pago = @w_total_precancelar --Es una Precancelacion, entonces SI se considera lo No Vigente de la Op.Grupal y las Op.Interciclos para el Pago.
BEGIN
   update #TMP_monto_pago  --Saldo NO Vigente Grupal
   set monto_novigente = @w_novigente_grupal
   where tipo = 'G'
   
   INSERT INTO #TMP_saldos_novigente
   select di_operacion, (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado)))/2
   from   ca_amortizacion, ca_dividendo, ca_rubro_op
   where  di_operacion  = am_operacion
   and    di_dividendo  = am_dividendo
   and    di_operacion in (select operacion from #TMP_operaciones where fecha_liq <= @i_fecha_pago)
   and    di_estado     = @w_est_novigente
   and    am_estado    <> @w_est_cancelado
   and    di_operacion = ro_operacion
   and    am_operacion = ro_operacion
   and    ro_concepto  = am_concepto
   and    ro_tipo_rubro = 'C'  
   group by di_operacion

   update #TMP_monto_pago set monto_novigente = monto  ----Saldo NO Vigente de las Op.Interciclos
   from   #TMP_saldos_novigente A, #TMP_monto_pago B
   where  B.operacion = A.operacion
   
END

select @w_exigible = @w_vencido_grupal + @w_vencido_interciclo + @w_vigente_grupal + @w_vigente_interciclo

select @w_diferencia = @i_monto_pago - @w_exigible

if abs(@w_diferencia) < 0.01
   select @w_exigible = @i_monto_pago --@w_exigible - abs(@w_diferencia)


/* LPO TEC ES UN PAGO NORMAL (NO ES UNA PRECANCELACION)*/
IF @w_monto_pago < 0.01 AND @i_monto_pago <= @w_exigible  --(@w_vencido_grupal + @w_vencido_interciclo + @w_vigente_grupal + @w_vigente_interciclo)
BEGIN   
   update #TMP_monto_pago
   set monto_novigente = 0 --LPO TEC Si es un pago Normal NO se considera lo No Vigente de la Op.Grupal ni las Op.Interciclos para el Pago.
END

   
/* NO ACEPTAR PAGOS EXTRAORDINARIOS */
/*if @i_monto_pago > (@w_vencido_grupal + @w_vencido_interciclo + @w_vigente_grupal + @w_vigente_interciclo)
or @w_monto_pago > 0
begin
   select @w_error = 710109
   goto ERROR
end
*/

/* EJECUTAR EL PROCESO DE APLICACION DE PAGOS */
declare cursor_monto_aplicar cursor for
select  operacion, banco, tipo, round((monto_vencido + monto_vigente + monto_novigente),2)
from    #TMP_monto_pago --#TMP_fecha_valor
where   (monto_vencido + monto_vigente) > 0
order by tipo, banco
for read only
   
open    cursor_monto_aplicar
fetch   cursor_monto_aplicar
into    @w_operacionca, @w_banco, @w_tipo, @w_monto_aplicar
   
/* WHILE cursor_monto_aplicar */
while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) 
   begin
      select @w_error = 71003
      goto ERROR
   end

   /* APLICA PAGO */
   exec @w_error          = sp_pago_cartera
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_srv            = @s_srv,
        @s_date           = @s_date,
        @s_sesn           = @s_sesn,
        @s_ssn            = @s_ssn,
        @s_ofi            = @s_ofi,
        --@s_rol            = @s_rol,
        @i_banco          = @w_banco,
        @i_beneficiario   = @i_beneficiario, --'DB.AUT',
        @i_cuenta         = @i_referencia,
        @i_fecha_vig      = @i_fecha_pago,
        @i_ejecutar       = 'S',
        @i_en_linea       = 'S',
        @i_producto       = @i_forma_pago, 
        @i_monto_mpg      = @w_monto_aplicar,
        @i_moneda         = @i_moneda_pago,
        @i_dividendo      = @i_dividendo,
        @i_tipo_reduccion = @i_tipo_reduccion,
        @o_secuencial_ing = @w_secuencial_ing OUT,
        @o_msg_matriz     = @w_msg_matriz OUT

   if @w_error <> 0 
   BEGIN
      close cursor_monto_aplicar 
      deallocate cursor_monto_aplicar

      goto ERROR
   end
   
   IF @w_tipo = 'G'  --Para devolver siempre el secuencial de ingreso de la Op. Grupal (OP Padre)(para sp_abono_atx)
      SELECT @o_secuencial_ing = @w_secuencial_ing --@w_secuencial_ing --para sp_abono_atx
      
   SELECT @o_msg_matriz     = @w_msg_matriz     --para sp_abono_atx
   
   insert into ca_secuencial_pago_grupal (
   pg_operacion_pago, pg_secuencial_pago, pg_banco_pago,
   pg_monto_total,    pg_operacion,       pg_secuencial_ing,
   pg_banco,          pg_producto,        pg_moneda,
   pg_monto_pago,     pg_fecha_ing,       pg_fecha_real,
   pg_estado)
   values(
   @w_operaciongp,    @w_secuencial_pago, @i_banco,           
   @i_monto_pago,     @w_operacionca,     @w_secuencial_ing,
   @w_banco,          @i_forma_pago,      @i_moneda_pago, 
   @w_monto_aplicar,  @i_fecha_pago,      getdate(),
   'I')
   
   if @@error <> 0 
   begin
      select @w_error = 70206

      close cursor_monto_aplicar 
      deallocate cursor_monto_aplicar

      goto ERROR
   end

   fetch   cursor_monto_aplicar 
   into    @w_operacionca, @w_banco, @w_tipo, @w_monto_aplicar

end /* WHILE cursor_monto_aplicar */

close cursor_monto_aplicar
deallocate cursor_monto_aplicar


/*SI ES UNA PRECANCELACION VERIFICAR QUE TODAS LAS OPERACIONES INVOLUCRADAS HAYAN QUEDADO CANCELADAS*/
IF @i_monto_pago = @w_total_precancelar
BEGIN
   IF EXISTS (SELECT 1 FROM #TMP_monto_pago, ca_operacion WHERE op_banco = banco AND op_estado <> @w_est_cancelado)
   BEGIN   
      select @w_error = 720311 --Error La cancelacion total no fue exitosa Revisar
      goto ERROR
   END 
END


--LPO TEC TRAER LAS OPERACIONES A SU FECHA DE ULTIMO PROCESO
/* EJECUTAR EL PROCESO DE FECHA VALOR */
declare cursor_fecha_valor cursor for
select  banco, fecha_proc --LPO TEC se adiciona fecha de ult proceso
from    #TMP_fecha_valor
for read only
   
open    cursor_fecha_valor
fetch   cursor_fecha_valor 
into    @w_banco, @w_fecha_valor
   
/* WHILE cursor_fecha_valor */
while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) 
   begin
      select @w_error = 71003
      goto ERROR
   end
         
   /* APLICAR PROCESO DE FECHA VALOR */
   exec @w_error        = sp_fecha_valor
        @s_date         = @s_date,
        @s_ofi          = @s_ofi,
        @s_sesn         = @s_sesn,
        @s_ssn          = @s_ssn,
        @s_srv          = @s_srv,
        @s_term         = @s_term,
        @s_user         = @s_user,
        @t_trn          = 7049,
        @i_operacion    = 'F',
        @i_banco        = @w_banco,
        @i_fecha_valor  = @w_fecha_valor,
        @i_observacion  = 'PAGO FECHA VALOR'

   if @w_error <> 0 
   begin
      close cursor_fecha_valor 
      deallocate cursor_fecha_valor

      goto ERROR
   end

   fetch   cursor_fecha_valor 
   into    @w_banco, @w_fecha_valor

end /* WHILE cursor_fecha_valor */

  
/* ATOMICIDAD POR TRANSACCION */
commit tran

return 0
                                                                                                                                                                                                                                                      
ERROR:
while @@trancount > 0 rollback tran


return @w_error

GO
