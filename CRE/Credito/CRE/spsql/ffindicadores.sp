/******************************************************************/
/*  Archivo:                ffindicadores.sp                      */
/*  Stored procedure:       sp_ffinanciero_indicadores            */
/*  Base de datos:          cob_credito                           */
/*  Producto:               Crédito                               */
/*  Disenado por:           Adriana Giler                         */
/*  Fecha de escritura:     Agosto-2019                           */
/******************************************************************/
/*                     IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios que son      */
/*  comercializados por empresas del Grupo Empresarial Cobiscorp, */
/*  representantes exclusivos para comercializar los productos y  */
/*  licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida*/
/*  y regida por las Leyes de la República de España y las        */
/*  correspondientes de la Unión Europea. Su copia, reproducción, */
/*  alteración en cualquier sentido, ingeniería reversa,          */
/*  almacenamiento o cualquier uso no autorizado por cualquiera   */
/*  de los usuarios o personas que hayan accedido al presente     */
/*  sitio, queda expresamente prohibido; sin el debido            */
/*  consentimiento por escrito, de parte de los representantes de */
/*  COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto */
/*  en el presente texto, causará violaciones relacionadas con la */
/*  propiedad intelectual y la confidencialidad de la información */
/*  tratada; y por lo tanto, derivará en acciones legales civiles */
/*  y penales en contra del infractor según corresponda.”.        */
/******************************************************************/
/*                         PROPOSITO                              */
/*  Informacion de Indicadores Financieros.                       */
/******************************************************************/
/*                       MODIFICACIONES                           */
/*     FECHA           AUTOR                RAZON                 */
/*  22/Jun/2021    Patricio Mora        Ajustes para GFI          */
/*  05/Abr/2022    Dilan Morales        Ajustes para Lineas       */
/*  21/Jul/2022    Bueno Duenas        Se reemplaza prueba acida  */
/*                                     por indice de endeudamiento*/
/*  28/Dic/2022    Dilan Morales       R221944: Se acopla indices */
/*                                     para ENL                   */
/*  15/Ene/2024   Dilan Morales        R221949:Se añade @i_cliente*/
/******************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_ffinanciero_indicadores')
    drop proc sp_ffinanciero_indicadores
go

create proc sp_ffinanciero_indicadores
(  
            @s_ssn                   int          = null,
            @s_sesn                  int          = null,
            @s_srv                   varchar(30)  = null,
            @s_lsrv                  varchar(30)  = null,
            @s_user                  login        = null,
            @s_date                  datetime     = null,
            @s_ofi                   int          = null,
            @s_rol                   tinyint      = null,
            @s_org                   char(1)      = null,
            @s_term                  varchar(30)  = null,
            @t_trn                   int          = 0,
            @i_retorno               char(1)      = 'S',
            @i_opcion                char(1),
            @i_banco                 cuenta,
            @i_cliente               int          = null
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
            @w_total_pasivo          money,
            @w_patrimonio            money,
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
            @w_solvencia             money,
            @w_endeudamiento         money,
            @w_margen_utilidad       money,
            @w_cap_trabajo           money,
            @w_monto                 money,
            @w_cuota                 money,
            @w_plazo                 smallint,
            @w_cliente               int,
            @w_rollback              char(1),
            @w_id_indicadores        smallint,
            @w_indicador_1           varchar(140),
            @w_indicador_2           varchar(140),
            @w_indicador_3           varchar(140),
            @w_indicador_4           varchar(140),
            @w_indicador_5           varchar(140),
            @w_indicador_6           varchar(140),
            @w_indicador_7           varchar(140),
            @w_indicador_8           varchar(140),
            @w_indicador_9           varchar(140),
            @w_indicador_10          varchar(140),
            @w_indicador_11          varchar(140),
            @w_indicador_12          varchar(140),
            @w_indicador_13          varchar(140),
            @w_linea                 char(1),
            @w_tramite               int,
            @w_saldo_vigente         money,
            @w_indice_endeudamiento  float
            
   
select @w_rollback = 'N'

select @w_sp_name = 'sp_ffinanciero_indicadores'

--Obtener Fecha de Proceso
select @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso


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
       select @w_error =  2101008
       goto ERROR
    end
 
    if not exists (select 1 from cobis..cl_analisis_negocio where an_cliente_id = @w_cliente)
    begin
        select @w_error = 2101008
        goto ERROR 
    end
    
     if not exists(select 1 from cr_ffinanciero_balance where fb_banco = @i_banco)
    begin
        exec @w_return = sp_ffinanciero_balance
             @t_trn      = 77529,
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
    delete cr_ffinanciero_indicadores
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
            @w_total_activo     = isnull(fb_total_activo,0),
            @w_total_pasivo     = isnull(fb_total_pasivo,0),
            @w_patrimonio       = isnull(fb_patrimonio, 0)
    from cr_ffinanciero_balance
    where fb_banco = @i_banco
   
    select @w_ventas = isnull(fr_monto,0)
    from cr_ffinanciero_resultado 
    where fr_banco = @i_banco
    and fr_item    = 'Ventas'
    
    select  @w_compras = isnull(fr_monto,0)
    from cr_ffinanciero_resultado 
    where fr_banco = @i_banco
    and fr_item =  'Compras'
   
    select  @w_utilidad_fam = isnull(fr_monto,0)
    from cr_ffinanciero_resultado 
    where fr_banco = @i_banco
    and fr_item =  'Utilidad de la unidad familiar'
    
    select  @w_utilidad_neg = isnull(fr_monto,0)
    from cr_ffinanciero_resultado 
    where fr_banco = @i_banco
    and fr_item =  'Utilidad Negocio (B)'

    select @w_cuota = isnull(fc_cuota,0)
    from cr_ffinanciero_cappago
    where fc_banco = @i_banco
    
    select @w_monto = isnull(fc_monto,0) 
    from cr_ffinanciero_cappago
    where fc_banco = @i_banco
    
    if @w_total_pasivo <> 0
        set @w_solvencia = @w_total_activo/@w_total_pasivo
    
    if(@w_patrimonio <> 0)
        set @w_endeudamiento = (@w_total_pasivo / @w_patrimonio) * 100

    if(@w_ventas <> 0)
        set @w_margen_utilidad  = (@w_utilidad_fam / @w_ventas) * 100
    
    set @w_cap_trabajo = @w_activo_cir - @w_ctaxpag_cplazo
    
    
    --CALCULO Endeudamiento de Patrimonio
    select @w_cliente = op_cliente
    from    cob_cartera..ca_operacion
    where   op_banco = @i_banco
    
    if @w_cliente = null
      select  @w_cliente = li_cliente
      from    cob_credito..cr_linea
      where   li_num_banco = @i_banco
    
    
    select @w_saldo_vigente = sum(isnull(am_cuota, 0) - isnull(am_pagado,0) + isnull(am_gracia, 0))
    from   cob_cartera..ca_amortizacion
    where  am_operacion in (select op_operacion 
                            from cob_cartera..ca_operacion 
                            where op_estado not in (99,0, 6, 3) 
                            and op_cliente = @w_cliente 
                            and op_banco != @i_banco)
    
    select @w_indice_endeudamiento = (((isnull(fb_total_pasivo, 0) + isnull(fc_monto, 0)) - isnull(@w_saldo_vigente, 0)) / isnull(fb_patrimonio, 1)) * 100
    from cob_credito..cr_ffinanciero_balance, cob_credito..cr_ffinanciero_cappago
    where fb_banco = fc_banco
    and fc_banco = @i_banco

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
        select @w_cap_pago       = @w_utilidad_fam / @w_cuota  
                                   
    if @w_total_capital <> 0       
        select @w_pastot_cap     = @w_ctaxpag_cplazo /  @w_total_capital,
               @w_pasfut_cap     = @w_ctaxpag_lplazo /  @w_total_capital
                                   
    if @w_total_activo <> 0        
        select @w_utilidad_neg   = @w_utilidad_neg / @w_total_activo,
               @w_pres_acttotal  = @w_monto / @w_total_activo
           
    --Insertando datos generados --
    delete cr_ffinanciero_indicadores
    where fi_banco = @i_banco 
    
    if @@error != 0 
    begin
        select @w_error = 107064
        goto ERROR
    end    
      
    select @w_error = 103076,
           @w_rollback = 'S'
   
    if not exists (select 1 from cobis..cl_tabla where tabla = 'cre_indicadores_financieros')
     begin
        select @w_error = 2101008
        goto ERROR 
     end  
    else
     begin    
      select @w_id_indicadores = codigo
      from cobis..cl_tabla
      where tabla = 'cre_indicadores_financieros'
     end
    
    select @w_indicador_1  = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '1'
    select @w_indicador_2  = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '2'
    select @w_indicador_3  = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '3'
    select @w_indicador_4  = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '4'
    select @w_indicador_5  = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '5'
    select @w_indicador_6  = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '6'
    select @w_indicador_7  = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '7'
    select @w_indicador_8  = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '8'
    select @w_indicador_9  = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '9'
    select @w_indicador_10 = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '10'
    select @w_indicador_11 = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '11'
    select @w_indicador_12 = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '12'
    select @w_indicador_13 = valor from cobis..cl_catalogo where tabla = @w_id_indicadores and codigo = '13'
   
    begin tran
        /*insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_1, isnull(@w_rot_ctasxcob,0),' ')--Rotación Cuentas por Cobrar(Version anterior)
        if @@error != 0
            goto ERROR*/
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_1, isnull(@w_cap_trabajo,0),' ')--Capital de Trabajo(Version ENL)
        if @@error != 0
            goto ERROR
      
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_2, isnull(@w_rot_inventario,0),' ')
        if @@error != 0
            goto ERROR
            
        /*insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_3, isnull(@w_rot_ctasxpag,0) ,' ') --Índice de Liquidez(Version anterior)
        if @@error != 0
            goto ERROR
        */
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_3, isnull(@w_solvencia,0) ,'>= 1.5') --Solvencia(Version ENL)
        if @@error != 0
            goto ERROR
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_4, isnull(@w_ind_liquidez,0) ,'>= 2.0')
        if @@error != 0
            goto ERROR
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_5, isnull(@w_indice_endeudamiento,0),' ') -- Indice endudamiento reemplaza a prueba acida
        if @@error != 0
            goto ERROR
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_6, isnull(@w_cta_vta_diaria,0)  , '<= 3.0')
        if @@error != 0
            goto ERROR
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_7, isnull(@w_ventas_mes,0), '<= 2.5')
        if @@error != 0
            goto ERROR
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_8, isnull(@w_cap_pago,0), '>= 1.5')
        if @@error != 0
            goto ERROR
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_9, isnull(@w_pastot_cap,0) ,' ')
        if @@error != 0
            goto ERROR
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_10, isnull(@w_pasfut_cap,0) ,'<= 4.0')
        if @@error != 0
            goto ERROR
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_11, isnull(@w_utilidad_neg,0),' ')
        if @@error != 0
            goto ERROR
            
        /*insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_12, isnull(@w_pres_acttotal,0),' ')--Préstamo/Activos Totales (Negocio)(Version ENL)
        if @@error != 0
            goto ERROR*/
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_12, isnull(@w_endeudamiento,0),'<= 50%')--Endeudamiento(Version ENL)
        if @@error != 0
            goto ERROR          
            
        insert cr_ffinanciero_indicadores values (@i_banco, @w_indicador_13, isnull(@w_margen_utilidad ,0),' ')
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
        from cr_ffinanciero_indicadores
        where fi_banco = @i_banco 
    end
  
end

if @i_opcion = 'C' -- Consultar datos del balance
begin
    select 'Indicadores Financieros ' = fi_indicador, 
           'Resultado ' = fi_resultado, 
           'Politica ' = fi_politica
    from cr_ffinanciero_indicadores
    where fi_banco = @i_banco 
    if @@rowcount = 0
    begin
        select @w_error = 2101008
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
