/********************************************************************/
/*   NOMBRE LOGICO:             sp_ffinanciero_balance              */
/*   NOMBRE FISICO:             ffbalance.sp                        */
/*   BASE DE DATOS:             cob_credito                         */
/*   PRODUCTO:                  Credito                             */
/*   DISENADO POR:              A. Giler                            */
/*   FECHA DE ESCRITURA:        Ago-2019                            */
/********************************************************************/
/*                         IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                         PROPOSITO                                */
/*  Informacion de Balance General                                  */
/********************************************************************/
/*                       MODIFICACIONES                             */
/*     FECHA           AUTOR               RAZON                    */
/*   22-Jun-2021        P. Mora         Ajustes para GFI            */
/*   05-Abr-2022        D. Morales      Ajustes para Lineas         */
/*   20-Jul-2022        B. Duenas       Ajuste de balances          */
/*   31-Ene-2023        P. Jarrin.      S769973-Analisis Financiero */
/*   16-Jun-2023        B. Duenas.      Validacion analisis negocio */
/*   24-Jul-2023        B. Duenas.      Sacar valores ult negocio   */
/*   22/Sep/2023        P. Jarrín       Ajuste signo B903813-R215336*/
/*   15/Ene/2024        D. Morales      R221949:Se añade @i_cliente */
/********************************************************************/

use cob_credito
go

if object_id ('sp_ffinanciero_balance') is not null
    drop procedure sp_ffinanciero_balance
go

create proc sp_ffinanciero_balance
(
            @s_ssn              int          = null,
            @s_sesn             int          = null,
            @s_srv              varchar(30)  = null,
            @s_lsrv             varchar(30)  = null,
            @s_user             login        = null,
            @s_date             datetime     = null,
            @s_ofi              int          = null,
            @s_rol              tinyint      = null,
            @s_org              char(1)      = null,
            @s_term             varchar(30)  = null,
            @t_trn              int          = 0,
            @i_retorno          char(1)      = 'S',
            @i_opcion           char(1),
            @i_banco            cuenta,
            @i_cliente          int          = null
)
as declare
            @w_return           int,
            @w_sp_name          varchar(32),
            @w_fec_proceso      datetime,
            @w_error            int,
            @w_fecha            varchar(50),
            @w_ventas           money,
            @w_compras          money,
            @w_utilidad_bruta   money,
            @w_gastos           money,
            @w_utilidad_neg     money,
            @w_otro_ing         money,
            @w_gtos_fami        money,
            @w_utilidad_fam     money,
            @w_cliente          int,
            @w_linea            char(1),
            @w_tramite          int,
            @w_nc_codigo        int,
            @w_ctaxpag_cplazo   money,
            @w_ctaxpag_lplazo   money
            

--Obtener Fecha de Proceso
select @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso

select @w_sp_name = 'sp_ffinanciero_balance'

if @i_opcion = 'G' -- Generar datos del balance
begin
    --Obtener el cliente del prestamo
    select @w_linea = substring(@i_banco,1,1)
    
    
    if(@w_linea = 'L')
    BEGIN
        select @w_tramite = cast(substring(@i_banco,2,100) as int)
        select @w_cliente = isnull(tr_cliente,0) from cob_credito..cr_tramite 
        where tr_tramite = @w_tramite
    END
    else
    begin
        select @w_cliente = isnull(op_cliente,0)
        from cob_cartera..ca_operacion
        where op_banco = @i_banco
    end

    select @w_cliente = isnull(@i_cliente, @w_cliente)
    
    if @w_cliente = 0
    begin
       select @w_error = 2101008
       goto ERROR
    end

    if not exists (select 1 from cobis..cl_analisis_negocio where an_cliente_id = @w_cliente)
    begin
        select @w_error = 2101008
        goto ERROR
    end

    if not exists(select 1 from cr_ffinanciero_resultado where fr_banco = @i_banco)
    begin
        exec @w_return = sp_ffinanciero_resultados
             @t_trn      = 77524,
             @i_opcion   = 'G',
             @i_banco    = @i_banco,
             @i_retorno  = 'N',
             @i_cliente  = @w_cliente

        if @w_return != 0
        begin
            select @w_error = @w_return
            goto ERROR
        end
    end

    --Insertando datos generados --
    delete cr_ffinanciero_balance
    where fb_banco = @i_banco

    if @@error != 0
    begin
        select @w_error = 107064
        goto ERROR
    end

    select  @w_utilidad_neg = fr_monto
    from cr_ffinanciero_resultado
    where fr_banco = @i_banco
    and fr_item =  'Utilidad Negocio (B)'

    select  @w_otro_ing = fr_monto
    from cr_ffinanciero_resultado
    where fr_banco = @i_banco
    and fr_item =  'Otros ingresos familiares (C)'

    select  @w_gtos_fami = fr_monto
    from cr_ffinanciero_resultado
    where fr_banco = @i_banco
    and fr_item =  'Gastos familiares (D)'

   --Deudas Buro, Enlace, Ajuste si existe otro análisis del negocio para el mismo cliente y de otro negocio encerar esos valores.
    select @w_nc_codigo = an_negocio_codigo 
    from cobis.dbo.ts_analisis_negocio
    where an_cliente_id = @w_cliente --id cliente
    and an_clase not in ('P')
    order by an_secuencial asc

    select @w_ctaxpag_cplazo = (isnull(an_deuda_corto_buro,0) + isnull(an_deuda_corto_enlace,0) + isnull(an_ajuste_deuda,0)),
           @w_ctaxpag_lplazo = (isnull(an_deuda_largo_buro,0) + isnull(an_deuda_largo_enlace,0) + isnull(an_ctas_por_pagar_largo_plazo,0))
      from cobis..cl_analisis_negocio, cobis..cl_negocio_cliente
     where an_cliente_id = @w_cliente
       and an_negocio_codigo = nc_codigo
       and an_negocio_codigo = @w_nc_codigo
       and nc_estado_reg = 'V'
    

    insert cr_ffinanciero_balance
    select @i_banco,                                                --fb_banco
           sum(isnull(an_disponible,0)),                            --fb_efectivo
           sum(isnull(an_ctas_por_cobrar,0)),                       --fb_ctaxcob
           convert(money,sum(isnull(an_inventario,0))),             --fb_inventario
           0,                                                       --fb_tot_act_cir

           sum(isnull(an_valor_vivienda,0) + isnull(an_valor_vivienda2,0)),--fb_terreno        
           sum(isnull(an_valor_negocio,0)  + isnull(an_valor_mobiliario,0)), --fb_local
           sum(isnull(an_valor_vehiculo,0) + isnull(an_valor_vehiculo2,0)),--fb_vehiculo
           0,--sum(isnull(an_valor_mobiliario,0)),                      --fb_mobiliario
           sum(isnull(an_valor_otros,0)),                           --fb_otros_bienes

           0,                                                       --fb_total_act_fijo
           0,                                                       --fb_total_activo

           isnull(@w_ctaxpag_cplazo, 0),--fb_ctaxpag_cplazo --BDU SE COMENTA CUOTA PAGO
           --0, 
           isnull(@w_ctaxpag_lplazo, 0),--fb_ctaxpag_lplazo
           0,                                                       --fb_total_pasivo

           0,                                                       --fb_patrimonio
           --sum(isnull(an_ventas_prom_mes,0)) - sum(isnull(an_compras_prom_mes,0)) - (sum(isnull(an_renta_neg,0)) + sum(isnull(an_transporte_neg,0)) + sum(isnull(an_personal_neg,0)) + sum(isnull(an_impuestos_neg,0)) + sum(isnull(an_electrica_neg,0))  + sum(isnull(an_agua_neg,0)) + sum(isnull(an_telefono_neg,0))  + sum(isnull(an_otros_neg,0))      + sum(isnull(an_cuota_pago,0))),     --fb_utilidad_neg BDU SE ENCERA
           0,
           --isnull(@w_otro_ing,0) - isnull(@w_gtos_fami,0),          --fb_utilidad_fam BDU SE ENCERA
           0,
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

    update cr_ffinanciero_balance
    set fb_tot_act_cir    = fb_efectivo + fb_ctaxcob + fb_inventario,
        fb_total_act_fijo = fb_terreno + fb_local + fb_vehiculo + fb_mobiliario + fb_otros_bienes,
       -- fb_total_activo   = fb_tot_act_cir + fb_total_act_fijo,
        fb_total_pasivo   = fb_ctaxpag_cplazo + fb_ctaxpag_lplazo
       -- fb_patrimonio     = fb_total_activo - fb_total_pasivo, -- - isnull(@w_utilidad_neg,0) - fb_utilidad_fam, BDU SE COMENTA RESTA DE UTIL NEG Y UTIL FAM
      --  fb_total_capital  = fb_patrimonio, -- + fb_utilidad_neg + fb_utilidad_fam, BDU SE COMENTA SUMA DE UTIL NEG Y UTIL FAM
      --  fb_total_pas_cap  = fb_total_pasivo + fb_total_capital
    where fb_banco = @i_banco

    update cr_ffinanciero_balance
    set fb_total_activo   = fb_tot_act_cir + fb_total_act_fijo
      --  fb_total_pasivo   = fb_ctaxpag_cplazo + fb_ctaxpag_lplazo,
      --  fb_patrimonio     = fb_total_activo - fb_total_pasivo - isnull(@w_utilidad_neg,0) - fb_utilidad_fam,
      --  fb_total_capital  = fb_patrimonio + fb_utilidad_neg + fb_utilidad_fam,
      --  fb_total_pas_cap  = fb_total_pasivo + fb_total_capital
    where fb_banco = @i_banco

    update cr_ffinanciero_balance
    set  fb_patrimonio     = fb_total_activo - fb_total_pasivo -- - isnull(@w_utilidad_neg,0) - fb_utilidad_fam, BDU SE COMENTA RESTA DE UTIL NEG Y UTIL FAM
       --  fb_total_capital  = fb_patrimonio, -- + fb_utilidad_neg + fb_utilidad_fam, BDU SE COMENTA SUMA DE UTIL NEG Y UTIL FAM
        -- fb_total_pas_cap  = fb_total_pasivo + fb_total_capital
    where fb_banco = @i_banco

    update cr_ffinanciero_balance
    set  fb_total_capital  = fb_patrimonio -- + fb_utilidad_neg + fb_utilidad_fam, BDU SE COMENTA SUMA DE UTIL NEG Y UTIL FAM
    where fb_banco = @i_banco


    update cr_ffinanciero_balance
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
        from cr_ffinanciero_balance
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
    from cr_ffinanciero_balance
    where fb_banco = @i_banco

    if @@rowcount = 0
    begin
        select @w_error = 2101008
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
