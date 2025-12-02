/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                interfdatacred_srv.sp                   */
/*      Procedimiento:          sp_interfaz_datcredito_srv              */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     10 de Jul 2019                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante           */
/*                              PROPOSITO                               */
/*      Procedimiento que genera los datos requeridos para la Interfaz  */
/*      de consulta datos credito.                                      */
/*                                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*                                                                      */
/*  10/07/2019       Adriana Giler              Emision Inciial         */
/*  22/01/2020       Armando Miramón          Eliminar códigos de error */
/*                                          si no encuentra información */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_interfaz_datcredito_srv')
   drop proc sp_interfaz_datcredito_srv
go

create proc sp_interfaz_datcredito_srv
@s_date           datetime    = null,
@s_user           login       = null,
@s_term           varchar(30) = null,
@s_ofi            smallint    = null,
@s_ssn            int         = null,
@s_srv            varchar(30) = null,
@t_trn            int,
@t_debug          char(1)      = 'N',
@t_file           varchar(14)  = null,
@i_grupo          int         =  null,
@i_cliente        int         =  null,
@i_banco          cuenta      =  null,
@i_detallado      char(1)     = 'N'


as 

declare  @w_sp_name                 varchar(30),
         @w_error                   int,
         @w_return                  int,
         @w_opcion                  char(1),
         @w_est_cancelado           tinyint,
         @w_est_suspenso            tinyint,
         @w_est_diferido            tinyint,
         @w_est_vigente             tinyint,
         @w_est_vencido             tinyint,
         @w_est_novigente           tinyint,
         @w_est_credito             tinyint,
         @w_est_anulado             tinyint,
         @w_ref_grupal              cuenta,
         @w_bco_padre               cuenta,
         @w_ope_padre               int,
         @w_operacion               int
   
-- CAPTURA NOMBRE DE STORED PROCEDURE
select @w_sp_name = 'sp_interfaz_datcredito_srv'
select @w_error = null
  
if  @t_trn <> 77508
begin
    exec cobis..sp_cerror
             @t_from  = @w_sp_name,
             @i_num   = 151023,
             @i_sev   = 0
    return 151023      --Tipo de transaccion no corresponde 
end


if @i_grupo is null and @i_banco is null and @i_cliente is null
begin
    exec cobis..sp_cerror
             @t_from  = @w_sp_name,
             @i_num   = 601250,
             @i_sev   = 0
    return 601250
end


create table #oper_cliente
(
 oc_operacion    int,
 oc_toperacion   catalogo,
 oc_ref_grupal   cuenta
)

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
     @o_est_cancelado  = @w_est_cancelado out,
     @o_est_suspenso   = @w_est_suspenso  out,
     @o_est_diferido   = @w_est_diferido  out,
     @o_est_vigente    = @w_est_vigente   out,
     @o_est_vencido    = @w_est_vencido   out,
     @o_est_novigente  = @w_est_novigente out,
     @o_est_credito    = @w_est_credito   out,
     @o_est_anulado    = @w_est_anulado   out

     
If isnull(@i_banco,'') > '' 
begin
    select @w_operacion = op_operacion
    from ca_operacion
    where op_banco = @i_banco
     and  ((op_estado not In (@w_est_novigente, @w_est_credito, @w_est_anulado)
            and isnull(op_ref_grupal,'') = '')
      or (op_estado = @w_est_novigente
          and isnull(op_ref_grupal,'')> ''))

    if @@rowcount = 0
    begin
        /*
        exec cobis..sp_cerror
             @t_from  = @w_sp_name,
             @i_num   = 171096,
             @i_sev   = 0
        return 171096  --No existen datos para consulta
        */
        return 0
    end
end

If isnull(@i_banco,'')  = ''
begin
    if isnull(@i_grupo,0) > 0 
    begin
        select @w_operacion = max(op_operacion)
        from ca_operacion
        where op_grupo = @i_grupo
          and op_ref_grupal is null
          and isnull(op_estado_hijas, 'I') != 'E'
          and op_estado not In (@w_est_novigente, @w_est_credito, @w_est_anulado)
    end
    else
    begin
        if isnull(@i_cliente,0) > 0
        begin
            --Primero la busco como cliente padre            
            select @w_operacion = max(op_operacion)
            from ca_operacion z
            where op_cliente = @i_cliente
            and isnull(op_estado_hijas, 'I') != 'E' 
            and op_estado not In (@w_est_novigente, @w_est_credito, @w_est_anulado)
            
  
            if isnull(@w_operacion,0) = 0 --busco como hija opercion padre
            begin
                select @w_operacion = max(z.op_operacion)
                from ca_operacion z, ca_operacion h
                where h.op_cliente = @i_cliente
                and   z.op_banco = h.op_ref_grupal
                and   z.op_estado not In (@w_est_novigente, @w_est_credito, @w_est_anulado)
                and   h.op_estado  = @w_est_novigente                   
            end
        end
    end
end

if isnull(@w_operacion,0) = 0
begin
    /*
    exec cobis..sp_cerror
         @t_from  = @w_sp_name,
         @i_num   = 171096,
         @i_sev   = 0
    return 171096  --No existen datos para consulta
    */
    return 0
end 

--Si es operacion Hija, obtener el banco padre y actualizar saldos
if exists (select 1 from ca_operacion
           where op_operacion = @w_operacion 
           and   isnull(op_ref_grupal,'') > '')           
           
begin
    select @i_detallado = 'N'   --No aplilca detallado
    
    select @w_bco_padre = op_ref_grupal
    from ca_operacion
    where op_operacion = @w_operacion 
    
    --Actualizo dividendos y amortizacion de hija
    if exists (select 1 from ca_det_ciclo where dc_operacion = @w_operacion and dc_tciclo != 'I' )
    begin
        exec @w_return =  sp_actualiza_hijas 
             @i_banco = @w_bco_padre
             
        if @w_return != 0 
        begin
            exec cobis..sp_cerror
                 @t_from  = @w_sp_name,
                 @i_num   = @w_return,
                 @i_sev   = 0
            return @w_return
        end
    end
end    
else
begin
    select @w_bco_padre  = op_banco
    from ca_operacion
    where op_operacion = @w_operacion
end
  
select @w_ref_grupal = op_banco
from ca_operacion
where op_operacion = @w_operacion

--Obtener datos para el Reporte    
if isnull(@i_cliente,0) = 0
begin
    select  'CreditoId'             = op_banco,
            'ClienteId'             = op_cliente, 
            'ProductoCredito'       = op_toperacion,  
            'CreditoReferencia'     = (select op_ref_grupal from ca_operacion
                                       where op_operacion = b.op_operacion),  
            'Monto'                 = op_monto,   
            'Plazo'                 = op_plazo,       
            'Frecuencia'            = op_tplazo,      
            'CuotaActual'           = isnull((select di_dividendo 
					      from   ca_dividendo where di_estado = 1
                                              and    di_operacion =  b.op_operacion),0),
                                      /*isnull((select sum(am_cuota  - am_pagado)           
                                      from ca_amortizacion inner join dbo.ca_dividendo
                                      on am_operacion = di_operacion and am_dividendo = di_dividendo 
                                      and di_estado not in (@w_est_cancelado,@w_est_novigente)            
                                      where am_operacion = b.op_operacion
                                      group by am_operacion),0),*/
                                      
            'PagosPuntuales'        = isnull((select count(di_operacion)                   
                                      from  ca_dividendo 
                                      where di_operacion =  b.op_operacion
                                      and di_estado = @w_est_cancelado),0),
                                      
            'SaldoVigente'          = isnull((select sum(am_cuota  - am_pagado)            
                                      from ca_amortizacion inner join dbo.ca_dividendo
                                      on am_operacion = di_operacion 
                                      and am_dividendo = di_dividendo                
                                      and di_estado = @w_est_vigente
                                      where am_operacion = b.op_operacion),0),
                                      
            'SaldoVencido'          = isnull((select sum(am_cuota - am_pagado)   
                                      from ca_amortizacion inner join ca_dividendo
                                      on am_operacion = di_operacion 
                                      and am_dividendo = di_dividendo 
                                      and di_estado = @w_est_vencido
                                      where am_operacion = b.op_operacion ),0),
                                      
            'SaldoLiquidacion'      = isnull((select sum(am_acumulado - am_pagado)   
                                      from ca_amortizacion inner join ca_dividendo
                                      on am_operacion = di_operacion 
                                      and am_dividendo = di_dividendo 
                                      and di_estado != @w_est_cancelado
                                      where am_operacion = b.op_operacion ),0),
                                      
            'FechaInicio'           = convert(varchar,op_fecha_ini,101),
            'FechaFin'              = convert(varchar,op_fecha_fin,101),
            'FechaUltimoPago'       = convert(varchar,isnull((select max(tr_fecha_ref)
                                              from ca_transaccion
                                              where tr_banco = @w_bco_padre
                                              and tr_tran = 'PAG' 
                                              and tr_estado <> 'RV'), '01/01/1900'),101),
            'Estado'                = op_estado
    from ca_operacion b
    where op_operacion = @w_operacion
       or op_operacion in (select op_operacion 
                           from ca_operacion, ca_det_ciclo
                           where op_ref_grupal = @w_ref_grupal
                             and op_operacion = dc_operacion
                             and dc_tciclo = 'I'
                             and (op_cliente = @i_cliente
                                or  isnull(@i_cliente,0)=0)
                             and @i_detallado = 'S')

    if @@error != 0
    begin
        exec cobis..sp_cerror
             @t_from  = @w_sp_name,
             @i_num   = 70170,
             @i_sev   = 0
        return 70170   --ERROR: AL GENERAR DATOS DEL REPORTE     
    end
end
else
begin  --Consulta por cliente
    insert #oper_cliente
    select @w_operacion, op_toperacion, isnull(op_ref_grupal, op_banco)
    from ca_operacion
    where op_operacion = @w_operacion
    
    --inserto operaciones de otros productos
    while 1=1
    begin
        set rowcount 1 
        
        select @w_operacion = 0
        
        select @w_operacion = max(op_operacion)
        from ca_operacion
        where op_estado not In (@w_est_novigente, @w_est_credito, @w_est_anulado)
          and op_cliente = @i_cliente
          and op_toperacion not in (select oc_toperacion
                                    from #oper_cliente)
       
        if isnull(@w_operacion,0)= 0
            break
            
        insert #oper_cliente
        select @w_operacion, op_toperacion, isnull(op_ref_grupal, op_banco)
        from ca_operacion
        where op_operacion = @w_operacion
    end
     set rowcount 0
     
    select  'CreditoId'             = op_banco,
            'ClienteId'             = op_cliente, 
            'ProductoCredito'       = op_toperacion,  
            'CreditoReferencia'     = (select op_ref_grupal from ca_operacion
                                       where op_operacion = b.op_operacion),  
            'Monto'                 = op_monto,   
            'Plazo'                 = op_plazo,       
            'Frecuencia'            = op_tplazo,      
            'CuotaActual'           = isnull((select di_dividendo 
					      from   ca_dividendo where di_estado = 1
                                              and di_operacion =  b.op_operacion),0),
                                      /*isnull((select sum(am_cuota  - am_pagado)           
                                      from ca_amortizacion inner join dbo.ca_dividendo
                                      on am_operacion = di_operacion and am_dividendo = di_dividendo 
                                      and di_estado not in (@w_est_cancelado,@w_est_novigente)            
                                      where am_operacion = b.op_operacion
                                      group by am_operacion),0),*/
                                      
            'PagosPuntuales'        = isnull((select count(di_operacion)                   
                                      from  ca_dividendo 
                                      where di_operacion =  b.op_operacion
                                      and di_estado = @w_est_cancelado),0),
                                      
            'SaldoVigente'          = isnull((select sum(am_cuota  - am_pagado)            
                                      from ca_amortizacion inner join dbo.ca_dividendo
                                      on am_operacion = di_operacion 
                                      and am_dividendo = di_dividendo                
                                      and di_estado = @w_est_vigente
                                      where am_operacion = b.op_operacion),0),
                                      
            'SaldoVencido'          = isnull((select sum(am_cuota - am_pagado)   
                                      from ca_amortizacion inner join ca_dividendo
                                      on am_operacion = di_operacion 
                                      and am_dividendo = di_dividendo 
                                      and di_estado = @w_est_vencido
                                      where am_operacion = b.op_operacion ),0),
                                      
            'SaldoLiquidacion'      = isnull((select sum(am_acumulado - am_pagado)   
                                      from ca_amortizacion inner join ca_dividendo
                                      on am_operacion = di_operacion 
                                      and am_dividendo = di_dividendo 
                                      and di_estado != @w_est_cancelado
                                      where am_operacion = b.op_operacion ),0),
                                      
            'FechaInicio'           = convert(varchar,op_fecha_ini,101),
            'FechaFin'              = convert(varchar,op_fecha_fin,101),
            'FechaUltimoPago'       = convert(varchar,isnull((select max(tr_fecha_ref)
                                              from ca_transaccion
                                              where tr_banco = c.oc_ref_grupal
                                              and tr_tran = 'PAG' 
                                              and tr_estado <> 'RV'), '01/01/1900'),101),
            'Estado'                = op_estado
    from ca_operacion b, #oper_cliente c
    where op_operacion = oc_operacion
    
    if @@error != 0
    begin
        exec cobis..sp_cerror
             @t_from  = @w_sp_name,
             @i_num   = 70170,
             @i_sev   = 0
        return 70170   --ERROR: AL GENERAR DATOS DEL REPORTE     
    end
end 
return 0

go
