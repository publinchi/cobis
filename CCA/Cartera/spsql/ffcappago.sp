/************************************************************************/
/*      Archivo:                ffcappago.sp                            */
/*      Stored procedure:       sp_ffinanciero_cappago                  */
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
/*      Cálculo de la Capacidad del Pago del Cliente                    */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*     20AGO19         Adriana Giler    Cálculo de Cuota Francesa       */
/************************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_ffinanciero_cappago')
    drop proc sp_ffinanciero_cappago
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_ffinanciero_cappago
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
   @i_banco            cuenta,
   @i_plazo            smallint     = null
)
as declare
   @w_return                int,
   @w_sp_name               varchar(32),
   @w_fec_proceso           datetime,
   @w_error                 int,
   @w_fecha                 varchar(50),
   @w_cliente               int,
   @w_monto                 money,
   @w_plazo                 smallint,
   @w_plazo_f               smallint,   
   @w_operacion             int,   
   @w_utilidad_fam          money,  
   @w_cuota                 money,   
   @w_gen_cuota             char(1),
   @w_capacidad             money
   
   
if @t_trn <> 77525
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
   
if @i_opcion = 'G' -- Generar calculo de la capacidad de pago
begin
    --Obtener el cliente del prestamo
    select @w_cliente               = isnull(op_cliente,0),
           @w_monto                 = isnull(op_monto,0),
           @w_cuota                 = isnull(op_cuota,0),
           @w_plazo                 = isnull(op_plazo,0),
           @w_operacion             = op_operacion,
           @w_gen_cuota             = 'N'
    from ca_operacion
    where op_banco = @i_banco
    
    if @w_cliente = 0
    begin
       select @w_error =  171096
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
    
    select @w_plazo_f = isnull(fc_plazo,0)
    from ca_ffinanciero_cappago
    where fc_banco = @i_banco
    
    --PQU if @w_plazo_f <> @w_plazo and isnull(@w_plazo_f,0) > 0
    --PQU   select @w_plazo = @w_plazo_f    
        
    if isnull(@i_plazo,0) = 0
        select @i_plazo = @w_plazo
        
    if isnull(@i_plazo,0) > 0
        select @w_gen_cuota = 'S',
               @w_plazo = @i_plazo
 
    if @w_gen_cuota = 'S'
    begin    
        exec @w_error = sp_ffinanciero_cfrancesa
             @i_operacion = @w_operacion,
             @i_plazo     = @w_plazo,
             @o_cuota     = @w_cuota out
             
        if (@w_error <> 0)
            goto ERROR
    end 
        
    --Obtener el valor de Utilidad Familiar
    select @w_utilidad_fam = (isnull(fr_monto ,0) / 2), 
           @w_capacidad    = case when (@w_utilidad_fam is null or @w_utilidad_fam = 0) then 0 else  (@w_cuota * 100) / @w_utilidad_fam end
    from ca_ffinanciero_resultado
    where fr_banco = @i_banco
    and   fr_item  = 'Utilidad de la unidad familiar'
    
    if @@rowcount = 0
    begin
       select @w_error =  171096
       goto ERROR
    end
    
    if @w_capacidad > 100
    begin
        select @w_monto,       
               @w_plazo,       
               @w_cuota,       
               @w_utilidad_fam,
               @w_capacidad  
    
        select @w_error = 725074
        return @w_error
        --goto ERROR 
        
    end
    
    
    --Insertando datos generados --
    delete ca_ffinanciero_cappago
    where fc_banco = @i_banco 
    
    if @@error != 0 
    begin
        select @w_error = 107064
        goto ERROR
    end    
    
    insert ca_ffinanciero_cappago values (@i_banco, @w_monto, @w_plazo, @w_cuota, @w_utilidad_fam, @w_capacidad)
    if @@error != 0
    begin
        select @w_error = 103076
        goto ERROR
    end
      
--Devolviendo resultados
    select fc_monto,       
           fc_plazo,       
           fc_cuota,       
           fc_utilidad_fam,
           fc_cap_pago  
    from ca_ffinanciero_cappago
    where fc_banco = @i_banco 
end


if @i_opcion = 'C' -- Consultar datos del balance
begin
    select fc_monto,       
           fc_plazo,       
           fc_cuota,       
           fc_utilidad_fam,
           fc_cap_pago  
    from ca_ffinanciero_cappago
    where fc_banco = @i_banco 
    
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