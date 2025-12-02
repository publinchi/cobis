/************************************************************************/
/*      Archivo:                ffestresultado.sp                       */
/*      Stored procedure:       sp_ffinanciero_resultados               */
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
/*      Información de Datos de Estado de resultados                    */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ffinanciero_resultados')
    drop proc sp_ffinanciero_resultados
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_ffinanciero_resultados
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
   @i_opcion           char(1),
   @i_retorno          char(1)      = 'S',
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
   
      
if @t_trn <> 77524
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
    
    select @w_ventas         = sum(isnull(an_ventas_prom_mes,0)),        
           @w_compras        = sum(isnull(an_compras_prom_mes,0)),        
           @w_utilidad_bruta = @w_ventas - @w_compras ,      
           
           @w_gastos         = (sum(isnull(an_renta_neg,0))     + sum(isnull(an_transporte_neg,0)) + sum(isnull(an_personal_neg,0)) +
                                sum(isnull(an_impuestos_neg,0)) + sum(isnull(an_electrica_neg,0))  + sum(isnull(an_agua_neg,0)) + 
                                sum(isnull(an_telefono_neg,0))  + sum(isnull(an_otros_neg,0))      + sum(isnull(an_cuota_pago,0))),

           @w_utilidad_neg   = @w_utilidad_bruta - @w_gastos,
           @w_otro_ing       = sum(isnull(an_monto_extra,0)),
           
           @w_gtos_fami      = (sum(isnull(an_gastos_alimentos,0)) + sum(isnull(an_gastos_renta_viv,0)) + sum(isnull(an_gastos_energia_elect,0)) + 
                                sum(isnull(an_gastos_agua,0))      + sum(isnull(an_gastos_telefono,0))  + sum(isnull(an_gastos_tv,0))  + 
                                sum(isnull(an_gastos_salud,0))     + sum(isnull(an_gastos_transp,0))    + sum(isnull(an_gastos_educ,0)) + 
                                sum(isnull(an_gastos_gas,0))       + sum(isnull(an_gastos_vestido,0))   + sum(isnull(an_gastos_otros,0))),
           @w_utilidad_fam   = @w_utilidad_neg + @w_otro_ing - @w_gtos_fami 
    from cobis..cl_analisis_negocio, cobis..cl_negocio_cliente
    where an_cliente_id = @w_cliente
    and an_negocio_codigo = nc_codigo
    and nc_estado_reg = 'V'
    
    --Insertando datos generados --
    delete ca_ffinanciero_resultado
    where fr_banco = @i_banco 
    
    if @@error != 0 
    begin
        select @w_error = 107064
        goto ERROR
    end
    
    
    select @w_error = 103076
    
    insert ca_ffinanciero_resultado values (@i_banco, "+", "Ventas",  @w_ventas, --100)
    case when (@w_ventas is null or @w_ventas = 0) then 0 else 100 end)
    if @@error != 0
        goto ERROR

    insert ca_ffinanciero_resultado values (@i_banco, "-", "Compras",  @w_compras,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_compras /@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
    insert ca_ffinanciero_resultado values (@i_banco, "=", "Utilidad bruta (A)", @w_utilidad_bruta, 
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_utilidad_bruta/@w_ventas)*100 , 0) end)
    
    if @@error != 0
        goto ERROR
        
    insert ca_ffinanciero_resultado values (@i_banco, "-", "Gastos de Operación y deudas",  @w_gastos,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_gastos/@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
        
    insert ca_ffinanciero_resultado values (@i_banco, "=", "Utilidad Negocio (B)", @w_utilidad_neg,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_utilidad_neg/@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
        
    insert ca_ffinanciero_resultado values (@i_banco, "+", "Otros ingresos familiares (C)",  @w_otro_ing,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_otro_ing/@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
        
    insert ca_ffinanciero_resultado values (@i_banco, "-", "Gastos familiares (D)", @w_gtos_fami,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_gtos_fami/@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
        
    insert ca_ffinanciero_resultado values (@i_banco, "=", "Utilidad de la unidad familiar", @w_utilidad_fam,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_utilidad_fam/@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
      
--Devolviendo resultados
    if  @i_retorno = 'S'
    begin
        select fr_signo,                    
             fr_item,        
             fr_monto,       
             fr_porcentaje  
        from ca_ffinanciero_resultado
        where fr_banco = @i_banco 
    end
end


if @i_opcion = 'C' -- Consultar datos del balance
begin
    select fr_signo,                    
           fr_item,        
           fr_monto,       
           fr_porcentaje  
    from ca_ffinanciero_resultado
    where fr_banco = @i_banco 
    
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