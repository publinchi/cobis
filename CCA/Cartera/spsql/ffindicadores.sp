/************************************************************************/
/*      Archivo:                ffindicadores.sp                        */
/*      Stored procedure:       sp_ffinanciero_indicadores              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     Agosto-2019                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Informacion de Indicadores Financieros                          */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ffinanciero_indicadores')
    drop proc sp_ffinanciero_indicadores
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_ffinanciero_indicadores
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
   @w_ctaxcob               money,
   @w_inventario            money,
   @w_ctaxpag_cplazo        money,
   @w_ctaxpag_lplazo        money,
   @w_activo_cir            money,
   @w_total_capital         money,
   @w_total_activo          money,
   @w_ventas                money,
   @w_compras               money,
   @w_utilidad_neg          money,
   @w_utilidad_fam          money,
   @w_rot_ctasxcob          money,
   @w_rot_inventario        money,
   @w_rot_ctasxpag          money,
   @w_ind_liquidez          money,
   @w_prb_acida             money,
   @w_cta_vta_diaria        money,
   @w_ventas_mes            money,
   @w_cap_pago              money,
   @w_pastot_cap            money,
   @w_pasfut_cap            money,
   @w_pres_acttotal         money,   
   @w_monto                 money,
   @w_cuota                 money,
   @w_plazo                 smallint,
   @w_cliente               int,
   @w_rollback              char(1)
   
      
if @t_trn <> 77530
begin        
   select @w_error = 151023
   goto ERROR
end

select @w_rollback = 'N'

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
    
     if not exists(select 1 from ca_ffinanciero_balance where fb_banco = @i_banco)
    begin
        exec @w_return = sp_ffinanciero_balance
             @t_trn      = 77529,
             @i_opcion   = 'G',
             @i_banco    = @i_banco,
             @i_retorno  = 'N'
        
        if @w_return != 0
        begin
            select @w_error = @w_return 
            goto ERROR
        end        
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
    delete ca_ffinanciero_indicadores
    where fi_banco = @i_banco
    
    if @@error != 0 
    begin
        select @w_error = 107064
        goto ERROR
    end
   
    select  @w_ctaxcob          = isnull(fb_ctaxcob,0),
            @w_inventario       = isnull(fb_inventario,0),
            @w_ctaxpag_cplazo   = isnull(fb_ctaxpag_cplazo,0),
            @w_ctaxpag_lplazo   = isnull(fb_ctaxpag_lplazo,0),
            @w_activo_cir       = isnull(fb_tot_act_cir,0),
            @w_total_capital    = isnull(fb_total_capital,0),
            @w_total_activo     = isnull(fb_total_activo,0)
    from ca_ffinanciero_balance
    where fb_banco = @i_banco
   
    select @w_ventas = isnull(fr_monto,0)
    from ca_ffinanciero_resultado 
    where fr_banco = @i_banco
    and fr_item    = 'Ventas'
    
    select  @w_compras = isnull(fr_monto,0)
    from ca_ffinanciero_resultado 
    where fr_banco = @i_banco
    and fr_item =  'Compras'
   
    select  @w_utilidad_fam = isnull(fr_monto,0)
    from ca_ffinanciero_resultado 
    where fr_banco = @i_banco
    and fr_item =  'Utilidad de la unidad familiar'
    
    select  @w_utilidad_neg = isnull(fr_monto,0)
    from ca_ffinanciero_resultado 
    where fr_banco = @i_banco
    and fr_item =  'Utilidad Negocio (B)'

    select @w_cuota = isnull(fc_cuota,0)
    from ca_ffinanciero_cappago
    where fc_banco = @i_banco
    
    select @w_monto = isnull(fc_monto,0) 
    from ca_ffinanciero_cappago
    where fc_banco = @i_banco
    
 
    if @w_ventas <> 0
        select @w_rot_ctasxcob   = (30 * @w_ctaxcob) / @w_ventas,
               @w_rot_ctasxpag   = (30 * @w_ctaxpag_cplazo) / @w_ventas,
               @w_cta_vta_diaria = (30 * @w_cuota) / @w_ventas,
               @w_ventas_mes     = @w_monto / @w_ventas 
                                   
    if @w_compras <> 0             
        select @w_rot_inventario = (30 * @w_inventario) / @w_compras
                                   
    if @w_ctaxpag_cplazo <> 0      
        select @w_ind_liquidez   = @w_activo_cir / @w_ctaxpag_cplazo,
               @w_prb_acida      = (@w_activo_cir - @w_inventario) / @w_ctaxpag_cplazo
                                   
    if @w_utilidad_fam <> 0        
        select @w_cap_pago       = @w_cuota  / @w_utilidad_fam
                                   
    if @w_total_capital <> 0       
        select @w_pastot_cap     = @w_ctaxpag_cplazo /  @w_total_capital,
               @w_pasfut_cap     = @w_ctaxpag_lplazo /  @w_total_capital
                                   
    if @w_total_activo <> 0        
        select @w_utilidad_neg   = @w_utilidad_neg / @w_total_activo,
               @w_pres_acttotal  = @w_monto / @w_total_activo
           
        
    --Insertando datos generados --
    delete ca_ffinanciero_indicadores
    where fi_banco = @i_banco 
    
    if @@error != 0 
    begin
        select @w_error = 107064
        goto ERROR
    end    
      
    select @w_error = 103076,
           @w_rollback = 'S'
   
    begin tran
        insert ca_ffinanciero_indicadores values (@i_banco, "Rotación cuentas por cobrar", isnull(@w_rot_ctasxcob,0),' ')
        if @@error != 0
            goto ERROR
      
        insert ca_ffinanciero_indicadores values (@i_banco, 'Rotación inventario días' , isnull(@w_rot_inventario,0),' ')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Rotación cuentas por pagar' , isnull(@w_rot_ctasxpag,0) ,' ')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Índice de liquidez' , isnull(@w_ind_liquidez,0) ,' ')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Prueba Ácida' , isnull(@w_prb_acida,0),' ')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Cuota/Ventas diarias' , isnull(@w_cta_vta_diaria,0)  , '< 3')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Crédito propuesto/Ventas mes', isnull(@w_ventas_mes,0), '< 1')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Capacidad de pago' , isnull(@w_cap_pago,0), '< 0.5')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Pasivo actual/ Capital (Total)' , isnull(@w_pastot_cap,0) ,' ')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Pasivo futuro/ Capital (Total)' , isnull(@w_pasfut_cap,0) ,' ')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Utilidad del negocio (Activos del negocio)', isnull(@w_utilidad_neg,0),' ')
        if @@error != 0
            goto ERROR
            
        insert ca_ffinanciero_indicadores values (@i_banco, 'Préstamo /Activos totales (Negocio)', isnull(@w_pres_acttotal,0),' ')
        if @@error != 0
            goto ERROR
        
    commit tran 
    select @w_rollback = 'N'
     
    --Devolviendo resultados
    if  @i_retorno = 'S'
    begin
        select 'Indicadores Financieros ' = fi_indicador, 
               'Resultado ' = fi_resultado, 
               'Politica ' = fi_politica
        from ca_ffinanciero_indicadores
        where fi_banco = @i_banco 
    end
  
end


if @i_opcion = 'C' -- Consultar datos del balance
begin
    select 'Indicadores Financieros ' = fi_indicador, 
           'Resultado ' = fi_resultado, 
           'Politica ' = fi_politica
    from ca_ffinanciero_indicadores
    where fi_banco = @i_banco 
    
    if @@rowcount = 0
    begin
        select @w_error = 101156
        goto ERROR 
    end    
end


return  0
        
ERROR:
if @w_rollback = 'S'
    rollback tran
    
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null, 
     @t_from  = @w_sp_name,
     @i_num   = @w_error,
	 @i_sev   = 0
    
return @w_error

go