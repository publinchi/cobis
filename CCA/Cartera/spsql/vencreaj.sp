/************************************************************************/
/*   Archivo:              vencreaj.sp                                  */
/*   Stored procedure:     sp_vencimiento_reajuste                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Francisco Yacelga                            */
/*   Fecha de escritura:   27/Nov./1997                                 */
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
/*   Consulta Vencimientos / Reajustes Futuros                          */
/*                              CAMBIOS                                 */
/*   FECHA                   AUTOR                CAMBIO                */
/*      ago-31-2001             EPB                  Operaciones        */
/*      abr-20-2005          JOHN JAIRO RENDON       Ver.1 Optimizacion */
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_vencimiento_reajuste')
   drop proc sp_vencimiento_reajuste
go

create proc sp_vencimiento_reajuste(
   @s_ssn                  int         = null,
   @s_date                 datetime    = null,
   @s_user                 login       = null,
   @s_term                 descripcion = null,
   @s_corr                 char(1)     = null,
   @s_ssn_corr             int         = null,
   @s_ofi                  smallint    = null,
   @t_rty                  char(1)     = null,
   @t_debug                char(1)     = 'N',
   @t_file                 varchar(14) = null,
   @t_trn                  smallint    = null,
   @i_operacion            char(1)     = null,
   @i_formato_fecha        int         = 103, -- VB MIGSYB11.9.3
   @i_toperacion           catalogo    = null,
   @i_moneda               smallint    = null,
   @i_entidad_prestamista  catalogo    = null,
   @i_fecha_desde          datetime    = null,
   @i_fecha_hasta          datetime    = null,
   @i_impresion            char(1)     = 'N',
   @i_oficina              smallint    = 0,
   @i_dias_desde           int         = null,     -- Optimización #3 John Jairo Rendón
   @i_dias_hasta           int         = null,     -- Optimización #3 John Jairo Rendón
   @i_siguiente            int         = null
)

as
declare
   @sp_id		int,
   @w_sp_name        varchar(32),
   @w_return         int,
   @w_error          int,
   @w_fecha_hoy      datetime,
   @w_fecha_hoy_nw   varchar(10),
   @w_fecha_campo    smalldatetime	-- Optimización #2 John Jairo Rendón

select   @w_sp_name = 'sp_vencimiento_reajuste',
 	@sp_id = @@spid

if isnull(@i_oficina, 0) = 0
begin
   print 'Debe ingresar la oficina por la cual desea realizar la búsqueda'
   set rowcount 0
   select @w_error = 710244
   goto ERROR
end 
   if @i_impresion = 'N'
   begin
   
      if @i_operacion = '0' 
         PRINT 'MENSAJE INFORMATIVO:  Vencimiento Final de Operaciones entre ' + convert(varchar(10), @i_fecha_desde,103) + ' y ' + convert(varchar(10), @i_fecha_hasta, 103)
    
      if @i_operacion = '1' 
         PRINT 'MENSAJE INFORMATIVO:  Vencimiento de Cuotas entre ' + convert(varchar(10), @i_fecha_desde, 103) + ' y ' + convert(varchar(10), @i_fecha_hasta, 103)

      if @i_operacion = '2'
         PRINT 'MENSAJE INFORMATIVO:  Proximos Reajustes entre ' + convert(varchar(10), @i_fecha_desde, 103)+ ' y ' + convert(varchar(10), @i_fecha_hasta, 103)
   
      if @i_operacion = '3' 
         PRINT 'MENSAJE INFORMATIVO:  Obligaciones vencidas entre ' + convert(varchar(10), @i_dias_desde, 103) + ' y ' + convert(varchar(10), @i_dias_hasta, 103) + ' dias'

   end

   -- FECHA DE PROCESO
--   select @w_fecha_hoy =  convert(varchar(10),fc_fecha_cierre,103)
   select @w_fecha_hoy = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7

   if @i_operacion in ('0','1','2')
   begin
--      if convert(varchar(10),@i_fecha_desde,103)  < @w_fecha_hoy  
      if @i_fecha_desde < @w_fecha_hoy
      begin
         print 'La Fecha Desde debe ser mayor o igual a la fecha de proceso'
         set rowcount 0
         select @w_error = 710244
         goto ERROR
      end
   
--      if convert(varchar(10),@i_fecha_hasta,103)  < @w_fecha_hoy
      if @i_fecha_hasta < @w_fecha_hoy
      begin
         print 'La Fecha Hasta debe ser mayor o igual a la fecha de proceso'
         set rowcount 0
         select @w_error = 7102440
         goto ERROR
      end

      set rowcount 0

      delete
      from ca_vencimiento_reajuste_t1
      where sp_id = @sp_id
      and s_term = @s_term

      insert into ca_vencimiento_reajuste_t1
      select sp_id  = @sp_id,
             s_term = @s_term,
             op_operacion,
             op_toperacion,
             op_moneda,
             op_banco,   
             op_monto,
             op_cliente,
             op_nombre,
             op_fecha_ini,
             di_dividendo,
             di_fecha_ven,
             op_cuota,
             op_fecha_fin,
             op_fecha_reajuste,
             op_tipo_linea
      from   ca_operacion A,  ca_dividendo B --(index ca_dividendo_2) --(index ca_operacion_6)   -- Optimización #4 John Jairo Rendón
      where  op_oficina    = @i_oficina
      and    di_operacion   = op_operacion 
      and    di_estado      = 1
      and    op_estado in (1,2,4,5,7,8,9,10)

      set rowcount 20
      select 'Linea'               = op_toperacion,
             'Moneda'              = (select convert(varchar(2),mo_moneda) +'-'+ substring(mo_descripcion,1,18)
                                      from cobis..cl_moneda
                                      where mo_moneda = t.op_moneda),
             'Obligacion Cobis'    = op_banco,   
             'Monto Op'            = convert (float,op_monto),
             'Cliente'             = op_cliente,
             'Nombre'              = substring(op_nombre,1,50),
             'Fecha de Desembolso' = substring(convert(varchar,op_fecha_ini,@i_formato_fecha),1,10),
             'Cuota Vigente'       = di_dividendo,
             'Venc. cuota'         = substring(convert(varchar,di_fecha_ven,@i_formato_fecha),1,10),
             'Cuota Pactada'       = convert (float, op_cuota),   -- CAMBIADO POR OPTIMIZACION (LA ORA CONSULTA IGUAL NO ENTERGABA UN VALOR FIABLE)
             'Venc. Operacion'     = substring(convert(varchar,op_fecha_fin,@i_formato_fecha),1,10),
             'Proximo reajuste'    = substring(convert(varchar,op_fecha_reajuste,@i_formato_fecha),1,10),
             'Secuencial'          = op_operacion
      from   ca_vencimiento_reajuste_t1 t
      where  sp_id = @sp_id
      and    op_operacion > @i_siguiente
      and   (op_toperacion = @i_toperacion or @i_toperacion is null)
      and   (op_moneda     = @i_moneda     or @i_moneda     is null)
      and   (op_tipo_linea = @i_entidad_prestamista or @i_entidad_prestamista is null)
      and     ((@i_operacion = '0' and ((@i_fecha_desde is null or op_fecha_fin >= @i_fecha_desde) and (@i_fecha_hasta is null or op_fecha_fin <= @i_fecha_hasta)))    -- Optimización #4 John Jairo Rendón
            or (@i_operacion = '1' and ((@i_fecha_desde is null or di_fecha_ven >= @i_fecha_desde) and (@i_fecha_hasta is null or di_fecha_ven <= @i_fecha_hasta)))    -- Optimización #4 John Jairo Rendón
            or (@i_operacion = '2' and ((@i_fecha_desde is null or op_fecha_reajuste >= @i_fecha_desde) and (@i_fecha_hasta is null or op_fecha_reajuste <= @i_fecha_hasta)))    -- Optimización #4 John Jairo Rendón
            )
      order by op_operacion

      set rowcount 0

      delete
      from ca_vencimiento_reajuste_t1
      where sp_id = @sp_id
      and s_term = @s_term
   end 

   if @i_operacion = '3'
   begin
      if @i_oficina = 0
      begin
         select @w_error = 701102
         goto ERROR
      end

 ------------------RUTINA CAMBIADA PARA NO OBTENER INFORMACION DEL MAESTRO
      select @w_fecha_campo = max(mo_fecha_de_proceso)
      from   ca_maestro_operaciones --(index ca_maestro_operaciones_1)

      select @w_fecha_hoy_nw = convert(varchar(10),@w_fecha_campo, 101)
      select @w_fecha_hoy_nw

      select @i_dias_desde = isnull(@i_dias_desde, 0)
      
      set rowcount 0

      delete
      from ca_vencimiento_reajuste_t2
      where sp_id = @sp_id
      and s_term = @s_term

--      PRINT '@w_fecha_hoy_nw ' + CAST(@w_fecha_hoy_nw AS VARCHAR)
--      PRINT '@i_siguiente ' + CAST(@i_siguiente AS VARCHAR)
--      PRINT '@i_oficina ' + CAST(@i_oficina AS VARCHAR)

      insert into ca_vencimiento_reajuste_t2
      select sp_id  = @sp_id,
             s_term = @s_term,
             mo_numero_de_operacion,
             mo_tipo_de_producto,
             mo_moneda,
             mo_numero_de_banco,
             mo_monto_desembolso,
             mo_cliente,
             mo_nombre_cliente,
             mo_fecha_inicio_op,
             mo_numero_cuotas_vencidas,
             mo_fecha_prox_vencimiento,
             valor_vencido = isnull(mo_saldo_capital_vencido,0) + isnull(mo_saldo_interes_vencido,0) + isnull(mo_saldo_interes_contingente,0) + isnull(mo_saldo_mora_contingente,0)+ isnull(mo_saldo_seguro_vida_vencido,0) + isnull(mo_saldo_otros_vencidos,0),
             mo_fecha_ven_op,
             mo_dias_vencido_op,
             mo_fecha_de_proceso
      from   ca_maestro_operaciones, ca_operacion --(index ca_maestro_operaciones_1) (index ca_operacion_1)
      where  mo_fecha_de_proceso    = @w_fecha_hoy_nw
      and    mo_numero_de_operacion > @i_siguiente
      and    op_operacion           = mo_numero_de_operacion
      and    op_oficina             = @i_oficina 
      and    mo_estado_obligacion   not in ('NO VIGENTE','CREDITO','COMEX','ANULADO','CANCELADO')

 ------------------RUTINA CAMBIADA PARA NO OBTENER INFORMACION DEL MAESTRO

/* RUTINA ORIGINAL DEL SP 
      select @w_fecha_campo = fc_fecha_cierre
      from   cobis..ba_fecha_cierre
      where  fc_producto = 7

      select @w_fecha_hoy_nw = convert(varchar(10),@w_fecha_campo, 103)
      select @w_fecha_hoy_nw

      select @i_dias_desde = isnull(@i_dias_desde, 0)
      
      set rowcount 0

      delete
      from ca_vencimiento_reajuste_t2
      where sp_id = @sp_id
      and s_term = @s_term

      insert into ca_vencimiento_reajuste_t2
      select sp_id = @sp_id,
             s_term = @s_term,
             op_operacion,
             op_toperacion,
             op_moneda,
             op_banco,
             op_monto,
             op_cliente,
             op_nombre,
             op_fecha_liq,
             (select count(*)
              from ca_dividendo
              where di_operacion = op_operacion
              and   di_estado = 2),
             (select di_fecha_ven
              from ca_dividendo
              where di_operacion = op_operacion
              and   di_estado    = 1),
             (select isnull(sum(am_cuota + am_gracia + am_pagado),0)
              from ca_dividendo,
                   ca_amortizacion
              where di_operacion = op_operacion
              and   di_estado = 2
              and   am_operacion = di_operacion
              and   am_dividendo = di_dividendo),
              op_fecha_fin,
              (select isnull(datediff(dd,min(di_fecha_ven),op_fecha_ult_proceso),0)
               from ca_dividendo
               where di_operacion = op_operacion),
              op_fecha_ult_proceso
      from ca_operacion,
           ca_dividendo
      where op_estado            in (1,2,4,9)
      and   op_fecha_ult_proceso = @w_fecha_hoy_nw
      and   op_operacion         > @i_siguiente
      and   op_oficina           = @i_oficina
      and   di_operacion         = op_operacion
      and   di_estado            = 2
*/

--      PRINT '@sp_id ' + CAST(@sp_id AS VARCHAR)
--     PRINT '@s_term ' + CAST(@s_term AS VARCHAR)
      set rowcount 20
      select
--             'FECHA'               = '01/01/2008',
             'Linea'               = mo_tipo_de_producto,
             'Moneda'              = mo_moneda,
             'Obligacion Cobis'    = mo_numero_de_banco,
             'Monto Op'            = convert (float,mo_monto_desembolso),
             'Cliente'             = mo_cliente,
             'Nombre'              = substring(mo_nombre_cliente,1,50),
             'Fecha de Desembolso' = substring(convert(varchar,mo_fecha_inicio_op,@i_formato_fecha),1,10),
             'Cuotas Vencidas'     = mo_numero_cuotas_vencidas,
             'Prox. Vencimiento'   = substring(convert(varchar,mo_fecha_prox_vencimiento,@i_formato_fecha),1,10),
             'Valor Vencido'       = valor_vencido,
             'Venc. Operacion'     = substring(convert(varchar,mo_fecha_ven_op,@i_formato_fecha),1,10),
             'Dias Vencidos'       = mo_dias_vencido_op,
             'Secuencial'          = mo_numero_de_operacion
      from   ca_vencimiento_reajuste_t2
      where  sp_id                  = @sp_id
      and    mo_numero_de_operacion > @i_siguiente
      and   (mo_tipo_de_producto    = @i_toperacion or @i_toperacion is null)
      and   (mo_moneda = @i_moneda or @i_moneda is null)
      and   (mo_dias_vencido_op    >= @i_dias_desde)
      and   (mo_dias_vencido_op    <= @i_dias_hasta or @i_dias_hasta is null)
      order by mo_numero_de_operacion



      delete
      from ca_vencimiento_reajuste_t2
      where sp_id = @sp_id
      and s_term = @s_term
      
   end

set rowcount 0

return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go
