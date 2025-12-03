/***********************************************************************/
/*   Archivo:                    capagoan.sp                           */
/*   Stored procedure:           sp_pagos_anuales_int                  */
/*   Base de Datos:              cob_cartera                           */
/*   Producto:                   Cartera                               */
/*   Disenado por:               Elcira Pelaez                         */
/*   Fecha de Documentacion:     Ene-2003                              */
/***********************************************************************/
/*                                IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de     */    
/*   'MACOSA'.                                                         */
/*   Su uso no autorizado queda expresamente prohibido asi como        */
/*   cualquier autorizacion o agregado hecho por alguno de sus         */
/*   usuario sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante                */
/***********************************************************************/  
/*                                   PROPOSITO                         */
/*   Genera informacion necesaria para el reporte de pagos anuales     */
/*      por obligacion                                                 */
/***********************************************************************/  
/*                              MODIFICACIONES                         */
/*      Fecha           Nombre         Proposito                       */
/*      07/Feb/2003   Luis Mayorga    Dar funcionalidad al procedim.   */
/*      02/Sep/2003   Julio C Quintero Saldo en Pesos para Obligacio-  */
/*                                      nes en UVR. Ajuste Monto Desem-*/
/*                                      bolsado, Saldos Actual y Ante- */
/*                                      rior e Intereses Pagados.      */
/*      11/Jul/2004   Luis Mayorga   Modificaciones para certificad.   */
/*      10/Nov/2004     Luis Ponce      Cambios manejo UVR,monto,saldos*/
/*      05/Ene/2005     Luis Mayorga    Ingreso parametro de oficina   */
/*      20/Ene/2006     Elcira Pelaez    def-5785                      */
/*      17/Mar/2006     Elcira Pelaez    def-6138                      */
/*      12/Mar/2007     FGQ              def-7919                      */
/*      25/Oct/2007     EPB              Quitar el Indice Unico        */
/*                                       no compilo en Produccion      */
/***********************************************************************/  

use cob_cartera
go

if exists(select 1 from cob_cartera..sysobjects where name = 'sp_pagos_anuales_int')
   drop proc sp_pagos_anuales_int
go

if not exists(select 1
              from   sysindexes
              where  name = 'ca_informe_anual_pagos_1')
   create nonclustered index ca_informe_anual_pagos_1 on ca_informe_anual_pagos(pa_banco)
go


create proc sp_pagos_anuales_int
   @s_user            varchar(14),
   @i_proceso         int      = null,
   @i_fecha_proceso   datetime,
   @i_oficina         smallint = 0
as
declare 
   @w_des_ciudad              descripcion,
   @w_des_linea               descripcion,
   @w_op_nombre               descripcion,
   @w_des_oficina             descripcion,
   @w_des_moneda              descripcion,
   @w_sp_name                 varchar(30),
   @w_direccion_ofi           varchar(255),
   @w_tipo_certificado        varchar(15),
   @w_op_toperacion           catalogo,
   @w_op_clase                catalogo,
   @w_op_oficina              smallint,
   @w_op_moneda               tinyint,
   @w_moneda_local            tinyint,
   @w_moneda_uvr              tinyint,
   @w_op_banco                cuenta,
   @w_consecutivo             cuenta,
   @w_ced_ruc                 numero,
   @w_op_monto                money,
   @w_vlr_pagado_tconcepto    money,
   @w_vlr_pagado_tcon_1       money,
   @w_vlr_pagado_tcon_2       money,
   @w_vlr_pagado_interes      money,
   @w_vlr_pagado_int_1        money,
   @w_vlr_pagado_int_2        money,
   @w_vlr_pagado_interes1     money,
   @w_saldo_anio_anterior     money,
   @w_saldo_anio_actual       money,
   @w_op_cliente              int,
   @w_anio_solicitado         int,
   @w_anio_gravable           int,
   @w_op_tramite              int,
   @w_op_operacion            int,
   @w_op_ciudad               int,
   @w_secuencial              int,
   @w_error                   int,
   @w_fecha_gravablei         datetime,
   @w_fecha_gravablef         datetime,
   @w_fecha_anteriorf         datetime,
   @w_fecha_gravable          datetime,
   @w_fecha_prestamo          datetime,
   @w_cotizacion_hoy          money,
   @w_cotizacion_prest        money,
   @w_anio_anterior           smallint,
   @w_deducible               money,
   @w_valor_deducible         money,
   @w_op_fec_ult_proc         datetime,
   @w_op_monto_aprobado       money,
   @w_op_migrada              cuenta,
   @w_op_monto_grabado        money,
   @w_fecha_fin_anio_solic    varchar(10),
   @w_fecha_inicio            varchar(10),
   @w_fecha_saldo_anterior    varchar(10),
   @w_capit_pagado            money,
   @w_cap_pag_posterior       money,
   @w_fecha_uvr               datetime,
   @w_op_estado               smallint,
   --PARALELISMO
   @p_operacion_ini           int,
   @p_operacion_fin           int,
   @p_proceso                 int,
   @p_programa                catalogo,
   @p_total_oper              int,
   @p_estado                  char(1),
   @p_ult_update              datetime,
   @p_cont_operacion          int,
   @p_tiempo_update           int,
   @w_fecha_cierre               datetime


select @w_sp_name = 'sp_pagos_anuales_int'

select @p_programa      = 'pagosanu',
       @p_proceso       = @i_proceso, -- SOLO POR MANTENER EL ESTANDAR DEL NOMBRE DE VARIABLES DEL PARALELO
       @p_ult_update    = getdate(),
       @p_tiempo_update = 15

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

--- SACAR EL A¥O EN CURSO
select @w_anio_solicitado = datepart(yy,@i_fecha_proceso)

select @w_fecha_fin_anio_solic = '12/30/' + convert(char(4),@w_anio_solicitado) --LPO fecha de fin de anio del anio en curso.
select @w_fecha_inicio = '01/' + '01/' + convert(char(4),@w_anio_solicitado)

select @w_anio_anterior = datepart(yy,@i_fecha_proceso) - 1

select @w_fecha_saldo_anterior = '12/30/' + convert(char(4),@w_anio_anterior)

select @w_anio_gravable = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'AGRAVA'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

--- CONSULTA CODIGO DE MONEDA LOCAL 
select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'MLO'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted

--- CONSULTA CODIGO DE MONEDA UVR 
select  @w_moneda_uvr = pa_tinyint
from    cobis..cl_parametro
where   pa_nemonico = 'MUVR'
and     pa_producto = 'CCA'
set transaction isolation level read uncommitted

--- CONSULTA PARAMETRO DE MAXIMO DEDUCIBLE
select  @w_deducible = pa_money
from    cobis..cl_parametro
where   pa_nemonico = 'IDEDUC'
and     pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_fecha_uvr = pa_datetime
from   cobis..cl_parametro
where  pa_nemonico = 'FECUVR'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted


select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7
set transaction isolation level read uncommitted


if @i_oficina = 0
begin
   declare
      cursor_pagos_anuales cursor
      for select op_cliente,          op_banco,               op_tramite,
                 op_operacion,        op_toperacion,          op_moneda,
                 op_oficina,          op_ciudad,              op_fecha_liq,
                 op_nombre,           op_clase,               op_monto,
                 op_monto_aprobado,   op_fecha_ult_proceso,   op_migrada,
                 op_estado
          from   ca_operacion o
          where  op_operacion between @p_operacion_ini and @p_operacion_fin
          and    op_fecha_liq  <= @i_fecha_proceso
          and   (    op_estado in (1, 2, 4, 5, 9)
                 or (op_estado = 3  and op_fecha_ult_proceso between @w_fecha_inicio and @w_fecha_cierre)
                )
          and   op_tipo != 'R'
          and   not exists(select 1
                           from   ca_informe_anual_pagos--(index ca_informe_anual_pagos_1)
                           where  pa_banco = o.op_banco)
      for read only
end 
ELSE
begin
   declare
      cursor_pagos_anuales cursor
      for select op_cliente,        op_banco,               op_tramite,
                 op_operacion,      op_toperacion,          op_moneda,
                 op_oficina,        op_ciudad,              op_fecha_liq,
                 op_nombre,         op_clase,               op_monto,
                 op_monto_aprobado, op_fecha_ult_proceso,   op_migrada,
                 op_estado
          from   ca_operacion o
          where  op_operacion between @p_operacion_ini and @p_operacion_fin
          and    op_fecha_liq  <= @i_fecha_proceso
          and   (   op_estado in (1, 2, 4, 5, 9)
                 or (op_estado = 3  and op_fecha_ult_proceso between @w_fecha_inicio and  @w_fecha_cierre)
                )
          and   op_oficina = @i_oficina
          and   op_tipo != 'R'
          and   not exists(select 1
                           from   ca_informe_anual_pagos--(index ca_informe_anual_pagos_1)
                           where  pa_banco = o.op_banco)
      for read only
end

select @p_cont_operacion = 0

if @p_proceso is not null
begin
   BEGIN TRAN
   
   update ca_paralelo_tmp
   set    estado      = 'P',
          spid        = @@spid,
          hora        = getdate(),
          hostprocess = master..sysprocesses.hostprocess,
          procesados  = @p_cont_operacion
   from   master..sysprocesses
   where  programa                  = @p_programa
   and    proceso                   = @p_proceso
   and    master..sysprocesses.spid = @@spid
   
   COMMIT
end

open  cursor_pagos_anuales 
fetch cursor_pagos_anuales
into  @w_op_cliente,          @w_op_banco,         @w_op_tramite,
      @w_op_operacion,        @w_op_toperacion,    @w_op_moneda,
      @w_op_oficina,          @w_op_ciudad,        @w_fecha_prestamo,
      @w_op_nombre,           @w_op_clase,         @w_op_monto,
      @w_op_monto_aprobado,   @w_op_fec_ult_proc,  @w_op_migrada,
      @w_op_estado

--while (@@fetch_status not in (-1, 0) and (@p_estado = 'P'))
while (@@fetch_status = 0) and (@p_estado = 'P')
begin
   -- CONTROL DE EJECUCION DE PARALELISMO
   if @p_proceso is not null
   begin
      -- ACTUALIZAR EL NUMERO DE REGISTROS PROCESADOS
      select @p_cont_operacion = @p_cont_operacion + 1
      
      -- ACTUALIZAR EL PROCESO CADA MINUTO
      if datediff(ss, @p_ult_update, getdate()) > @p_tiempo_update 
      begin
         select @p_ult_update = getdate()
         
         BEGIN TRAN
         
         update ca_paralelo_tmp
         set    hora       = getdate(),
                procesados = @p_cont_operacion
         where  programa = @p_programa
         and    proceso  = @p_proceso
         
         -- AVERIGUAR EL ESTADO DEL PROCESO
         select @p_estado = estado
         from   ca_paralelo_tmp
         where  programa = @p_programa
         and    proceso = @p_proceso
         
         COMMIT
      end
   end
   
   --INICIALIZACION DE VARIABLES
   select @w_saldo_anio_actual    = 0,
          @w_vlr_pagado_tconcepto = 0,
          @w_vlr_pagado_interes   = 0,
          @w_vlr_pagado_interes1  = 0,
          @w_saldo_anio_anterior  = 0,
          @w_op_monto_grabado     = 0,
          @w_tipo_certificado     = '',
          @w_capit_pagado         = 0,
          @w_cap_pag_posterior    = 0
   
   if @w_op_estado = 3
   begin
      select @w_cap_pag_posterior = isnull(sum (dtr_monto),0) 
      from   cob_cartera_depuracion..ca_transaccion, cob_cartera_depuracion..ca_det_trn  --CAPITAL PAGADO POSTERIORMENTE AL 30 DE DICIEMBRE DEL A¤O SOLICITADO.  LPO
      where  tr_operacion  = @w_op_operacion
      and    tr_fecha_mov > @w_fecha_fin_anio_solic
      and    tr_tran       = 'PAG'
      and    tr_estado in ('CON', 'ING')
      and    dtr_operacion  = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_concepto  = 'CAP'
   end
   
   select @w_cap_pag_posterior = @w_cap_pag_posterior + isnull(sum (dtr_monto),0) 
   from   ca_transaccion, ca_det_trn  --CAPITAL PAGADO POSTERIORMENTE AL 30 DE DICIEMBRE DEL A¤O SOLICITADO.  LPO
   where  tr_operacion  = @w_op_operacion
   and    tr_fecha_mov > @w_fecha_fin_anio_solic
   and    tr_tran       = 'PAG'
   and    tr_estado in ('CON', 'ING')
   and    dtr_operacion  = tr_operacion
   and    dtr_secuencial = tr_secuencial
   and    dtr_concepto  = 'CAP'
   
   --SALDO_CAPITAL - SALDO ACTUAL LAM
   select @w_saldo_anio_actual = isnull((sum(am_cuota + am_gracia  - am_pagado) + abs(sum(am_cuota + am_gracia - am_pagado)))/2,0)
   from   ca_amortizacion, ca_concepto
   where  am_concepto = co_concepto
   and    co_categoria = 'C'
   and    am_operacion = @w_op_operacion
   and    am_estado   != 3
   
   if @w_saldo_anio_actual <= 0 
      select @w_saldo_anio_actual = 0 
   
   select @w_ced_ruc = en_ced_ruc
   from   cobis..cl_ente
   where  en_ente = @w_op_cliente
   set transaction isolation level read uncommitted
   
   --- GENERACION DEL NUMERO CONSECUTIVO 
   exec @w_secuencial = sp_gen_sec      
        @i_operacion  = @w_op_operacion
   
   select @w_consecutivo = ''
   
   exec sp_numero_recibo 
        @i_tipo         = 'I',
        @i_oficina      = @w_op_oficina, 
        @i_secuencial   = @w_secuencial,
        @o_recibo       = @w_consecutivo out
   
   ---DESCRIPCION DE OFICINA 
   select @w_des_oficina = of_nombre,
          @w_direccion_ofi = of_direccion
   from   cobis..cl_oficina
   where  of_oficina = @w_op_oficina
   set transaction isolation level read uncommitted
   
   ---DESCRIPCION DE CIUDAD 
   select @w_des_ciudad = ci_descripcion
   from   cobis..cl_ciudad
   where  ci_ciudad = @w_op_ciudad
   set transaction isolation level read uncommitted
   
   --- DESCRIPCION DE LINEA 
   select @w_des_linea = null
   
   select @w_des_linea = valor 
   from   cobis..cl_catalogo
   where  tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_toperacion')
   and    codigo  = @w_op_toperacion
   set transaction isolation level read uncommitted
   
   -- DESCRIPCION MONEDA 
   select @w_des_moneda = mo_descripcion
   from   cobis..cl_moneda
   where  mo_moneda = @w_op_moneda
   
   select @w_fecha_anteriorf = '12/' + '30/' + convert(char(4),@w_anio_solicitado-1)  
   select @w_fecha_gravablei = '01/' + '01/' + convert(char(4),@w_anio_solicitado) 
   select @w_fecha_gravablef = '12/' + '30/' + convert(char(4),@w_anio_solicitado)  
   
   --- VALOR PAGADO POR TODO CONCEPTO DEL ANIO ACTUAL
   if @w_anio_solicitado = 2004  --Anio de Migracion
   begin
      select @w_vlr_pagado_tcon_1 = isnull(sum(ar_monto_mn),0)
      from   ca_abono_rubro
      where  ar_operacion = @w_op_operacion
      and    ar_fecha_pag >= '01/01/2004'
      and    ar_fecha_pag < '03/01/2004'
      and    ar_afectacion = 'C'
      
      select @w_vlr_pagado_tcon_2 = isnull(sum(ar_monto * ar_cotizacion),0)
      from   ca_abono_rubro, ca_abono
      where  ar_operacion  = ab_operacion
      and    ar_secuencial = ab_secuencial_pag
      and    ab_operacion  = @w_op_operacion
      and    ab_fecha_pag >= '03/01/2004'
      and    ab_fecha_pag <= '12/30/2004'
      and    ab_estado = 'A'
      and    ar_afectacion = 'D'
      
      select @w_vlr_pagado_tconcepto = isnull(@w_vlr_pagado_tcon_1,0) + isnull(@w_vlr_pagado_tcon_2,0)
   end
   ELSE
   begin
      select @w_vlr_pagado_tconcepto = isnull(sum(ar_monto * ar_cotizacion),0)
      from   ca_abono_rubro, ca_abono
      where  ar_operacion  = ab_operacion
      and    ar_secuencial = ab_secuencial_pag
      and    ab_operacion  = @w_op_operacion
      and    ab_fecha_pag >= @w_fecha_gravablei
      and    ab_fecha_pag <= @w_fecha_gravablef
      and    ab_estado = 'A'
      and    ar_afectacion = 'D'
   end
   
   if @w_vlr_pagado_tconcepto is null or @w_vlr_pagado_tconcepto < 0
      select @w_vlr_pagado_tconcepto = 0
   
   if @w_anio_solicitado = 2004  --Anio de Migracion
   begin
      select @w_vlr_pagado_int_1 = isnull(sum(ar_monto),0)
      from   ca_abono_rubro, ca_concepto
      where  ar_operacion = @w_op_operacion
      and    ar_concepto   = co_concepto
      and    ar_fecha_pag >= '01/01/2004'
      and    ar_fecha_pag < '03/01/2004'
      and    co_categoria in ('I','M')
      
      select @w_vlr_pagado_int_2 = isnull(sum(ar_monto * ar_cotizacion),0)
      from   ca_abono_rubro, ca_abono, ca_concepto
      where  ar_operacion  = ab_operacion
      and    ar_secuencial = ab_secuencial_pag
      and    ab_operacion  = @w_op_operacion
      and    ar_concepto   = co_concepto
      and    ab_fecha_pag >= '03/01/2004'
      and    ab_fecha_pag <= '12/30/2004'
      and    ab_estado = 'A'
      and    co_categoria  in ('I','M')
      
      select @w_vlr_pagado_interes1 = isnull(@w_vlr_pagado_int_1, 0) + isnull(@w_vlr_pagado_int_2, 0)
   end
   ELSE
   begin
      select @w_vlr_pagado_interes1 = isnull(sum(ar_monto * ar_cotizacion),0)
      from   ca_abono_rubro, ca_abono, ca_concepto
      where  ar_operacion  = ab_operacion
      and    ar_secuencial = ab_secuencial_pag
      and    ab_operacion  = @w_op_operacion
      and    ar_concepto   = co_concepto
      and    ab_fecha_pag >= @w_fecha_gravablei
      and    ab_fecha_pag <= @w_fecha_gravablef
      and    ab_estado = 'A'
      and    co_categoria  in ('I','M')
   end
   
   if @w_vlr_pagado_interes1 is null or @w_vlr_pagado_interes1 < 0
      select @w_vlr_pagado_interes1 = 0
   
   if @w_anio_solicitado = 2004 
   begin
      select @w_saldo_anio_anterior = sfa_saldo_capital
      from   ca_saldos_fin_anio
      where  sfa_operacion      = @w_op_migrada
      and    sfa_fecha_proceso = '12/30/' + convert(char(4),@w_anio_anterior)
   end 
   else
   begin
      select @w_saldo_anio_anterior = sfa_saldo_capital
      from   ca_saldos_fin_anio
      where sfa_fecha_proceso = @w_fecha_anteriorf
      and   sfa_operacion     = @w_op_banco
   end
   
   if @w_saldo_anio_anterior <= 0 
      select @w_saldo_anio_anterior = 0 
   
   If @w_op_clase = '3' and @w_op_moneda = @w_moneda_local
   begin
      select @w_tipo_certificado = 'HIPOTECARIAS'
   end
   
   If @w_op_clase = '3'  and @w_op_moneda =  @w_moneda_uvr
   begin
      select @w_tipo_certificado = 'HIPOTECARIAS'
   end
   
   If @w_op_clase in ('1','2','4')
   begin
      select @w_tipo_certificado = 'CREDITO'
   end
   
   if @w_op_migrada is null
   begin
      select @w_op_monto_grabado = @w_op_monto
   end
   ELSE
   begin
      select @w_op_monto_grabado = @w_op_monto_aprobado
   end
   
   select @w_saldo_anio_actual = isnull((@w_saldo_anio_actual + @w_cap_pag_posterior),0) --LPO
   
   if @w_op_moneda  <> @w_moneda_local
   begin
      select @w_cotizacion_prest = 1
      exec sp_buscar_cotizacion
           @i_moneda     = @w_op_moneda,
           @i_fecha      = @w_fecha_prestamo, --Fecha del desembolso, LPO 10/Nov/2004
           @o_cotizacion = @w_cotizacion_prest output
      
      select @w_op_monto_grabado = round((@w_op_monto_grabado * @w_cotizacion_prest),0)
      
      if @w_op_estado = 3
         select @w_fecha_uvr = @w_op_fec_ult_proc
      
      select @w_cotizacion_prest = 1
      
      exec sp_buscar_cotizacion
           @i_moneda     = @w_op_moneda,
           @i_fecha      = @w_fecha_uvr,   --@w_fecha_fin_anio_solic, --Fecha fin de anio del anio en curso, LPO 10/Nov/2004
           @o_cotizacion = @w_cotizacion_prest output
      
      select @w_saldo_anio_actual = round((@w_saldo_anio_actual * @w_cotizacion_prest),0)
      
      -- Inicio LAM
      if datepart(yy,@w_fecha_prestamo) = datepart(yy,@i_fecha_proceso) 
      begin
         if @w_saldo_anio_actual < @w_op_monto_grabado --LPO 10/Nov/2004 --if @w_op_monto_grabado < @w_saldo_anio_actual
            select @w_vlr_pagado_interes = @w_vlr_pagado_tconcepto - (@w_op_monto_grabado - @w_saldo_anio_actual)
      end
      ELSE
      begin
         if @w_saldo_anio_actual > @w_op_monto_grabado
         begin
            select @w_vlr_pagado_interes = @w_vlr_pagado_tconcepto
         end    
         ELSE
         begin
            if @w_saldo_anio_anterior >= @w_op_monto_grabado --LPO 10/Nov/2004
            begin
               if @w_saldo_anio_actual < @w_op_monto_grabado
                  select @w_vlr_pagado_interes = @w_vlr_pagado_tconcepto - (@w_op_monto_grabado - @w_saldo_anio_actual) --LPO 11/10/2004 --(@w_saldo_anio_actual - @w_op_monto_grabado)
            end
            
            if @w_saldo_anio_anterior < @w_op_monto_grabado
            begin
               if @w_saldo_anio_actual < @w_op_monto_grabado
               begin
                  if @w_saldo_anio_anterior > @w_saldo_anio_actual
                     select @w_vlr_pagado_interes = @w_vlr_pagado_tconcepto - (@w_saldo_anio_anterior - @w_saldo_anio_actual) --LPO 11/10/2004 --(@w_saldo_anio_actual - @w_saldo_anio_anterior)                     
                  ELSE
                     select @w_vlr_pagado_interes = @w_vlr_pagado_tconcepto
               end
            end
         end 
      end
   end
   
   if @w_op_moneda  <> @w_moneda_local
      select @w_valor_deducible = @w_vlr_pagado_interes
   ELSE
      if @w_op_moneda = @w_moneda_local
         select @w_valor_deducible = @w_vlr_pagado_interes1
   
   if @w_valor_deducible > @w_deducible
      select @w_valor_deducible = @w_deducible
   
   if @w_valor_deducible < 0
      select @w_valor_deducible = 0
   
   BEGIN TRAN
   
   insert into ca_informe_anual_pagos
         (pa_cliente,               pa_tramite,             pa_consecutivo,            pa_tipo_certificado,
          pa_anio_gravable,         pa_oficina,             pa_des_ofi,                pa_ciudad,
          pa_direccion_ofi,         pa_nombre,              pa_ced_ruc,                pa_tipo_deudor,
          pa_anio_solicitado,       pa_banco,               pa_linea,                  pa_modalidad,
          pa_monto_desembolsado,    pa_saldo_anio_anterior, pa_saldo_anio_solicitado,  pa_valor_pagado_trubro,
          pa_valor_pagado_int,      pa_deducible,           pa_decreto)
   values(@w_op_cliente,            @w_op_tramite,          @w_consecutivo,            @w_tipo_certificado,
          @w_anio_gravable,         @w_op_oficina,          @w_des_oficina,            @w_des_ciudad,
          @w_direccion_ofi,         @w_op_nombre,           @w_ced_ruc,                'DEUDOR PRINCIPAL',
          @w_anio_solicitado,       @w_op_banco,            @w_des_linea,              @w_des_moneda,
          @w_op_monto_grabado,      @w_saldo_anio_anterior, @w_saldo_anio_actual,      @w_vlr_pagado_tconcepto,  
          @w_vlr_pagado_interes1,   @w_valor_deducible,     @w_deducible)
   
   if @@error <> 0
   begin
      select @w_error = 710409
      goto ERROR
   end
   
   while @@trancount > 0 COMMIT
   
   fetch cursor_pagos_anuales
   into  @w_op_cliente,          @w_op_banco,         @w_op_tramite,
         @w_op_operacion,        @w_op_toperacion,    @w_op_moneda,
         @w_op_oficina,          @w_op_ciudad,        @w_fecha_prestamo,
         @w_op_nombre,           @w_op_clase,         @w_op_monto,
         @w_op_monto_aprobado,   @w_op_fec_ult_proc,  @w_op_migrada,
         @w_op_estado
end ---CURSOR PAGOS ANUALES

close cursor_pagos_anuales
deallocate cursor_pagos_anuales

while @@trancount > 0 rollback tran

if @p_proceso is not null 
begin
   BEGIN TRAN
   
   update ca_paralelo_tmp
   set    estado = 'T',
          procesados = @p_cont_operacion
   where  programa = @p_programa
   and    proceso  = @p_proceso
   
   COMMIT
end       

return 0

ERROR:
while @@trancount > 0 ROLLBACK

insert into ca_errorlog
      (er_fecha_proc,      er_error,      er_usuario,
       er_tran,            er_cuenta,     er_descripcion,
       er_anexo)
values(@i_fecha_proceso,   @w_error,      @s_user,
       0,                  '',             'ERROR GENERANDO INFORMACION PARA REPORTE DE PAGOS ANUALES',
       ''
       ) 

return @w_error
go             
