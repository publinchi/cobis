/********************************************************************/
/*   NOMBRE LOGICO:         sp_pago_solidario                       */
/*   NOMBRE FISICO:         sp_pago_solidario.sp                    */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          D. Morales.                             */
/*   FECHA DE ESCRITURA:    19-Abr-2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
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
/*                     PROPOSITO                                    */
/*   Realizar operaciones sobre registros de pagos solidarios-grupal*/
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   19-Abr-2023        D. Morales.      Emision Inicial - S784515  */
/*   27-Jun-2023        D. Morales.      Se añade validación de     */
/*                                       estados para operación V   */
/*   06-Sep-2023        D. Morales.      Se añade condición para    */
/*                                       filtar en operacion V      */
/*   02-Abr-2024        D. Morales.      R229984:Se añade condiciones*/
/*                                       con @i_num_operacion       */
/*  28-Jun-2024         D. Morales       R238623: Optimizacion      */
/********************************************************************/
use cob_credito
go


if object_id ('dbo.sp_pago_solidario') is not null
    drop procedure dbo.sp_pago_solidario
go

create procedure sp_pago_solidario
(
    @t_show_version         bit             = 0, 
    @s_ssn                  int             = null, 
    @s_srv                  varchar(30)     = null, 
    @s_lsrv                 varchar(30)     = null, 
    @s_date                 datetime        = null, 
    @s_user                 login           = null, 
    @s_term                 descripcion     = null, 
    @s_corr                 char(1)         = null, 
    @s_ssn_corr             int             = null, 
    @s_ofi                  smallint        = null,
    @s_culture              varchar(10)     = null, 
    @t_rty                  char(1)         = null, 
    @t_trn                  int             = null, 
    @t_debug                char(1)         = 'n', 
    @t_file                 varchar(14)     = null, 
    @t_from                 varchar(30)     = null, 
    @i_operacion            char(1),
    @i_tramite_grupal       int             = null,
    @i_num_operacion        cuenta          = null,
    @i_num_pago_solidario   smallint        = null,
    @i_ente_beneficiario    int             = null,
    @i_ente_solidario       int             = null,
    @i_monto_solidario      money           = null,
    @i_formato_fecha        int             = 103
) as
declare
    @w_mensaje                  varchar(80), 
    @w_return                   int, /*  valor que retorna  */        
    @w_sp_name                  varchar(32), /*  descripcion del stored procedure */  
    @w_error                    int,
    @w_id_pago                  smallint,
    @w_ente_solidario           int,
    @w_monto_beneficiario       money,
    @w_suma_montos_solidarios   money,
    @w_num_operacion            cuenta, 
    @w_ente_beneficiario        int,
    @w_nomlar                   varchar(132),
    @w_id                       int,
    @w_max_id                   int
    
select @w_sp_name = 'sp_pago_solidario'

if (@t_show_version = 1)
begin
    select @w_mensaje = 'stored procedure sp_pago_solidario, version 1.0.0'
    return 0
end

if (@t_trn <> 21870)
begin
    /*  tipo de transaccion no corresponde  */
    select @w_error = 801077
    goto ERROR
end

if not exists(select 1 from cr_tramite_grupal where tg_tramite = @i_tramite_grupal)
begin
    select @w_error  = 2110335
    goto ERROR 
end


if @i_operacion = 'I'
begin

    if(@i_monto_solidario <= 0)
    begin
        select @w_error  = 2110133
        goto ERROR
    end
    
    if exists (select 1 from cr_pago_solidario 
                where ps_tramite_grupal = @i_tramite_grupal  
                and ps_num_operacion = @i_num_operacion
                and ps_ente_beneficiario = @i_ente_beneficiario
                and ps_ente_solidario = @i_ente_solidario)
    begin
        select @w_error  = 2110417
        goto ERROR
    end
    
    select @w_suma_montos_solidarios =  isnull(sum(isnull(ps_monto_solidario, 0)),0) 
    from cr_pago_solidario 
    where ps_tramite_grupal = @i_tramite_grupal 
    and ps_ente_beneficiario = @i_ente_beneficiario
    and ps_num_operacion = @i_num_operacion 
    
    
    select @w_suma_montos_solidarios = @w_suma_montos_solidarios + @i_monto_solidario
    
    select @w_monto_beneficiario =  ((isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                    from cob_cartera..ca_amortizacion
                                                    where ca.op_operacion = am_operacion
                                                    and am_concepto in ('INT', 'CAP')),0)) + 
                                    (isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                    from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                                    where am_operacion = di_operacion and
                                                    am_operacion = ca.op_operacion and
                                                    am_dividendo = di_dividendo and
                                                    am_concepto not in('CAP', 'INT') and
                                                    di_estado not in (0)),0)))
    from cob_cartera..ca_operacion ca
    where op_banco = @i_num_operacion
    
    if(@w_suma_montos_solidarios > @w_monto_beneficiario)
    begin
        select @w_error  = 2110418
        goto ERROR
    end
    
    
    select @w_id_pago = isnull(max(ps_pago_solidario),0) from cr_pago_solidario where ps_tramite_grupal = @i_tramite_grupal and ps_ente_beneficiario = @i_ente_beneficiario 
    select @w_id_pago = @w_id_pago  + 1
    
    insert into cr_pago_solidario
    (ps_tramite_grupal,     ps_num_operacion,   ps_pago_solidario,  ps_ente_beneficiario,   ps_ente_solidario,  ps_monto_solidario)
    values
    (@i_tramite_grupal ,    @i_num_operacion,   @w_id_pago,         @i_ente_beneficiario ,  @i_ente_solidario , @i_monto_solidario)
    
    if @@error <> 0
    begin
        select @w_error = 2110421
        goto ERROR
    end

    
end

if @i_operacion = 'U'
begin
    if(@i_monto_solidario <= 0) 
    begin
        select @w_error  = 2110133
        goto ERROR
    end 
    
    if not exists (select 1 from cr_pago_solidario 
                where ps_tramite_grupal = @i_tramite_grupal  
                and ps_num_operacion = @i_num_operacion
                and ps_ente_beneficiario = @i_ente_beneficiario
                and ps_pago_solidario   = @i_num_pago_solidario)
    begin
        select @w_error  = 2109107
        goto ERROR
    end
    
    select @w_suma_montos_solidarios =  isnull(sum(isnull(ps_monto_solidario, 0)),0) from cr_pago_solidario 
                                                                where ps_tramite_grupal = @i_tramite_grupal 
                                                                and ps_ente_beneficiario = @i_ente_beneficiario 
                                                                and ps_ente_solidario != @i_ente_solidario
                                                                and ps_num_operacion = @i_num_operacion
                                                                
    select @w_suma_montos_solidarios = @w_suma_montos_solidarios + @i_monto_solidario
    
    select @w_monto_beneficiario =  ((isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                    from cob_cartera..ca_amortizacion
                                                    where ca.op_operacion = am_operacion
                                                    and am_concepto in ('INT', 'CAP')),0)) + 
                                    (isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                    from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                                    where am_operacion = di_operacion and
                                                    am_operacion = ca.op_operacion and
                                                    am_dividendo = di_dividendo and
                                                    am_concepto not in('CAP', 'INT') and
                                                    di_estado not in (0)),0)))
    from cob_cartera..ca_operacion ca
    where op_banco = @i_num_operacion
    
    if(@w_suma_montos_solidarios > @w_monto_beneficiario)
    begin
        select @w_error  = 2110418
        goto ERROR
    end
    
    select @w_ente_solidario = ps_ente_solidario from cr_pago_solidario 
                                                 where ps_tramite_grupal = @i_tramite_grupal  
                                                 and ps_num_operacion = @i_num_operacion
                                                 and ps_ente_beneficiario = @i_ente_beneficiario
                                                 and ps_pago_solidario   = @i_num_pago_solidario
    
    
    
    if(@w_ente_solidario <> @i_ente_solidario)
    begin
        if exists (select 1 from cr_pago_solidario 
                where ps_tramite_grupal = @i_tramite_grupal  
                and ps_num_operacion = @i_num_operacion
                and ps_ente_beneficiario = @i_ente_beneficiario
                and ps_ente_solidario = @i_ente_solidario)
        begin
            select @w_error  = 2110417
            goto ERROR
        end
    end 
    
    update cr_pago_solidario
    set ps_monto_solidario  = @i_monto_solidario,
        ps_ente_solidario   = @i_ente_solidario  
    where ps_tramite_grupal = @i_tramite_grupal  
    and ps_ente_beneficiario= @i_ente_beneficiario
    and ps_pago_solidario   = @i_num_pago_solidario
    and ps_num_operacion    = @i_num_operacion  
    
    if @@error <> 0
    begin
        select @w_error = 2110422
        goto ERROR
    end

end

if @i_operacion = 'D'
begin
    delete cr_pago_solidario 
    where ps_tramite_grupal     = @i_tramite_grupal 
    and   ps_ente_beneficiario  = @i_ente_beneficiario
    and   ps_pago_solidario     = @i_num_pago_solidario
    and   ps_num_operacion      = @i_num_operacion
    
    if @@error <> 0
    begin
        select @w_error = 2110423
        goto ERROR
    end
end

if @i_operacion = 'Q'
begin
    select
    'tramite_grupal'        = ps_tramite_grupal,
    'num_operacion'         = ps_num_operacion,
    'num_pago_solidario'    = ps_pago_solidario, 
    'ente_beneficiario'     = ps_ente_beneficiario,
    'integrante_solidario'  = ps_ente_solidario,
    'monto_solidario'       = ps_monto_solidario
    from cr_pago_solidario 
    where ps_tramite_grupal     = @i_tramite_grupal 
    and   ps_ente_beneficiario  = @i_ente_beneficiario 
    and   ps_num_operacion      = @i_num_operacion
end


if @i_operacion = 'V'
begin
    if OBJECT_ID('tempdb..#valida_pagos') is not null
    begin
        drop table #valida_pagos
    end
    create table #valida_pagos(
        id                  int identity(1,1),
        cliente             int,
        banco               cuenta,
        pagos_solidarios    money,
        monto_deuda         money
    )
    
    insert into #valida_pagos
    (cliente, banco)
    select  op_cliente, op_banco
    from cob_credito..cr_op_renovar 
    inner join cob_cartera..ca_operacion  on or_num_operacion = op_ref_grupal
    inner join cob_credito..cr_tramite_grupal on tg_tramite  = or_tramite  and tg_cliente = op_cliente
    where or_tramite = @i_tramite_grupal 
    and tg_participa_ciclo = 'N'
    and op_estado not in (0, 3,9,66)
    and tg_cliente in (select ps_ente_beneficiario from cob_credito..cr_pago_solidario where ps_tramite_grupal = @i_tramite_grupal)
    
    update #valida_pagos
    set pagos_solidarios = (select isnull(sum(isnull(ps_monto_solidario, 0)),0) 
                           from cr_pago_solidario 
                           where ps_tramite_grupal = @i_tramite_grupal 
                           and ps_ente_beneficiario = cliente
                           and ps_num_operacion = banco )
    
    update #valida_pagos
    set monto_deuda = (select 
                            ((isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                from cob_cartera..ca_amortizacion
                                where ca.op_operacion = am_operacion
                                and am_concepto in ('INT', 'CAP')),0)) + 
                            (isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                where am_operacion = di_operacion and
                                am_operacion = ca.op_operacion and
                                am_dividendo = di_dividendo and
                                am_concepto not in('CAP', 'INT') and
                                di_estado not in (0)),0))) 
                            from cob_cartera..ca_operacion ca
                            where op_banco = banco)
                            
    select  @w_max_id = null,
            @w_id = null
    select @w_max_id = max(id) from #valida_pagos
    select @w_id = 1

    while  @w_id <= @w_max_id
    begin
    
        select  @w_suma_montos_solidarios   = null, 
                @w_monto_beneficiario       = null
        
        
        select  @w_suma_montos_solidarios   = pagos_solidarios, 
                @w_monto_beneficiario       = monto_deuda
        from #valida_pagos
        where id = @w_id
        
        
        
        if(@w_suma_montos_solidarios <> @w_monto_beneficiario)
        begin
            select @w_error = 2110424
            select @w_mensaje = 'Revisar pago solidario. Operacion:'+@w_num_operacion +', Saldo pendiente:' + cast((@w_monto_beneficiario - @w_suma_montos_solidarios) as varchar)
            goto ERROR
        end
        select @w_id = @w_id + 1
    end

end

return 0 
    
ERROR:

    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_msg   = @w_mensaje,
         @i_num   = @w_error
    return @w_error
go
