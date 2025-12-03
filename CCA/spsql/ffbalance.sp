/************************************************************************/
/*      Archivo:                ffbalance.sp                            */
/*      Stored procedure:       sp_ffinanciero_balance                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     Agosto-2019                             */
/************************************************************************/
/*                         IMPORTANTE                                   */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Informacion de Balance General                                  */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ffinanciero_balance')
    drop proc sp_ffinanciero_balance
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_ffinanciero_balance
(
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @t_trn              int          = 0,
   @i_retorno          char(1)      = 'S',
   @i_opcion           char(1),
   @i_banco            cuenta
)
as declare
   @w_return                int,
   @w_sp_name               varchar(32),
   @w_fec_proceso           datetime,
   @w_error                 int,
   @w_fecha                 varchar(50),
   @w_ventas                money,
   @w_compras               money,
   @w_utilidad_bruta        money,
   @w_gastos                money,
   @w_utilidad_neg          money,
   @w_otro_ing              money,
   @w_gtos_fami             money,
   @w_utilidad_fam          money,
   @w_cliente               int

if @t_trn <> 77529
begin
   select @w_error = 151023
   goto ERROR
end


--Obtener Fecha de Proceso
select @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso

if not exists (select 1 from ca_operacion where op_banco = @i_banco)
begin
   select @w_error =  171096
   goto ERROR
end

if @i_opcion = 'G' -- Generar datos del balance
begin
    --Obtener el cliente del prestamo
    select @w_cliente = isnull(op_cliente,0)
    from ca_operacion
    where op_banco = @i_banco

    if @w_cliente = 0
    begin
       select @w_error =  171096
       goto ERROR
    end

    if not exists (select 1 from cobis..cl_analisis_negocio where an_cliente_id = @w_cliente)
    begin
        select @w_error = 101156
        goto ERROR
    end

    if not exists(select 1 from ca_ffinanciero_resultado where fr_banco = @i_banco)
    begin
        exec @w_return = sp_ffinanciero_resultados
             @t_trn      = 77524,
             @i_opcion   = 'G',
             @i_banco    = @i_banco,
             @i_retorno  = 'N'

        if @w_return != 0
        begin
            select @w_error = @w_return
            goto ERROR
        end
    end

    --Insertando datos generados --
    delete ca_ffinanciero_balance
    where fb_banco = @i_banco

    if @@error != 0
    begin
        select @w_error = 107064
        goto ERROR
    end

    select  @w_utilidad_neg = fr_monto
    from ca_ffinanciero_resultado
    where fr_banco = @i_banco
    and fr_item =  'Utilidad Negocio (B)'

    select  @w_otro_ing = fr_monto
    from ca_ffinanciero_resultado
    where fr_banco = @i_banco
    and fr_item =  'Otros ingresos familiares (C)'

    select  @w_gtos_fami = fr_monto
    from ca_ffinanciero_resultado
    where fr_banco = @i_banco
    and fr_item =  'Gastos familiares (D)'


    insert ca_ffinanciero_balance
    select @i_banco,                                                --fb_banco
           sum(isnull(an_disponible,0)),                            --fb_efectivo
           sum(isnull(an_ctas_por_cobrar,0)),                       --fb_ctaxcob
           convert(money,sum(isnull(an_inventario,0))),             --fb_inventario
           0,                                                       --fb_tot_act_cir

           sum(isnull(an_valor_vivienda,0)),                        --fb_terreno
           sum(isnull(an_valor_negocio,0)),                         --fb_local
           sum(isnull(an_valor_vehiculo,0)),                        --fb_vehiculo
           sum(isnull(an_valor_mobiliario,0)),                      --fb_mobiliario
           sum(isnull(an_valor_otros,0)),                           --fb_otros_bienes

           0,                                                       --fb_total_act_fijo
           0,                                                       --fb_total_activo

           sum(isnull(an_cuota_pago,0)),                            --fb_ctaxpag_cplazo
           sum(isnull(an_ctas_por_pagar_largo_plazo,0)),            --fb_ctaxpag_lplazo
           0,                                                       --fb_total_pasivo

           0,                                                       --fb_patrimonio
           sum(isnull(an_ventas_prom_mes,0)) - sum(isnull(an_compras_prom_mes,0)) - (sum(isnull(an_renta_neg,0))     + sum(isnull(an_transporte_neg,0)) + sum(isnull(an_personal_neg,0)) + sum(isnull(an_impuestos_neg,0)) + sum(isnull(an_electrica_neg,0))  + sum(isnull(an_agua_neg,0)) + 
           sum(isnull(an_telefono_neg,0))  + sum(isnull(an_otros_neg,0))      + sum(isnull(an_cuota_pago,0))),                         --fb_utilidad_neg
           isnull(@w_otro_ing,0) - isnull(@w_gtos_fami,0),          --fb_utilidad_fam
           0,                                                       --fb_total_capital
           0                                                        --fb_total_pas_cap
    from cobis..cl_analisis_negocio, cobis..cl_negocio_cliente
    where an_cliente_id = @w_cliente
    and an_negocio_codigo = nc_codigo
    and nc_estado_reg = 'V'

    if @@error != 0
    begin
        select @w_error = 103076
        goto ERROR
    end

    update ca_ffinanciero_balance
    set fb_tot_act_cir    = fb_efectivo + fb_ctaxcob + fb_inventario,
        fb_total_act_fijo = fb_terreno + fb_local + fb_vehiculo + fb_mobiliario + fb_otros_bienes,
        fb_total_activo   = fb_tot_act_cir + fb_total_act_fijo,
        fb_total_pasivo   = fb_ctaxpag_cplazo + fb_ctaxpag_lplazo,
        fb_patrimonio     = fb_total_activo - fb_total_pasivo - isnull(@w_utilidad_neg,0) - fb_utilidad_fam,
        fb_total_capital  = fb_patrimonio + fb_utilidad_neg + fb_utilidad_fam,
        fb_total_pas_cap  = fb_total_pasivo + fb_total_capital
    where fb_banco = @i_banco

    update ca_ffinanciero_balance
    set fb_total_activo   = fb_tot_act_cir + fb_total_act_fijo,
        fb_total_pasivo   = fb_ctaxpag_cplazo + fb_ctaxpag_lplazo,
        fb_patrimonio     = fb_total_activo - fb_total_pasivo - isnull(@w_utilidad_neg,0) - fb_utilidad_fam,
        fb_total_capital  = fb_patrimonio + fb_utilidad_neg + fb_utilidad_fam,
        fb_total_pas_cap  = fb_total_pasivo + fb_total_capital
    where fb_banco = @i_banco

    update ca_ffinanciero_balance
    set fb_patrimonio     = fb_total_activo - fb_total_pasivo - isnull(@w_utilidad_neg,0) - fb_utilidad_fam,
        fb_total_capital  = fb_patrimonio + fb_utilidad_neg + fb_utilidad_fam,
        fb_total_pas_cap  = fb_total_pasivo + fb_total_capital
    where fb_banco = @i_banco

    update ca_ffinanciero_balance
    set fb_total_capital  = fb_patrimonio + fb_utilidad_neg + fb_utilidad_fam,
        fb_total_pas_cap  = fb_total_pasivo + fb_total_capital
    where fb_banco = @i_banco


    update ca_ffinanciero_balance
    set fb_total_pas_cap  = fb_total_pasivo + fb_total_capital
    where fb_banco = @i_banco

    --Devolviendo resultados
    if @i_retorno = 'S'
    begin
        select fb_efectivo,
               fb_ctaxcob,
               fb_inventario,
               fb_tot_act_cir,
               fb_terreno,
               fb_local,
               fb_vehiculo,
               fb_mobiliario,
               fb_otros_bienes,
               fb_total_act_fijo,
               fb_total_activo,
               fb_ctaxpag_cplazo,
               fb_ctaxpag_lplazo,
               fb_total_pasivo,
               fb_patrimonio,
               fb_utilidad_neg,
               fb_utilidad_fam,
               fb_total_capital,
               fb_total_pas_cap
        from ca_ffinanciero_balance
        where fb_banco = @i_banco
    end
end


if @i_opcion = 'C' -- Consultar datos del balance
begin
    select fb_efectivo,
           fb_ctaxcob,
           fb_inventario,
           fb_tot_act_cir,
           fb_terreno,
           fb_local,
           fb_vehiculo,
           fb_mobiliario,
           fb_otros_bienes,
           fb_total_act_fijo,
           fb_total_activo,
           fb_ctaxpag_cplazo,
           fb_ctaxpag_lplazo,
           fb_total_pasivo,
           fb_patrimonio,
           fb_utilidad_neg,
           fb_utilidad_fam,
           fb_total_capital,
           fb_total_pas_cap
    from ca_ffinanciero_balance
    where fb_banco = @i_banco

    if @@rowcount = 0
    begin
        select @w_error = 101156
        goto ERROR
    end
end


return  0

ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null,
     @t_from  = @w_sp_name,
     @i_num   = @w_error,
     @i_sev   = 0

return @w_error

go