/********************************************************************/
/*   NOMBRE LOGICO:             sp_ffinanciero_resultados           */
/*   NOMBRE FISICO:             ffinanciero_resultados.sp           */
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
/*   Información de Datos de Estado de resultados                   */
/********************************************************************/
/*                       MODIFICACIONES                             */
/*     FECHA           AUTOR                RAZON                   */
/*   22-Jun-2021        P. Mora         Ajustes para GFI            */
/*   05-Abr-2022        D. Morales      Ajustes para Lineas         */
/*   31-Ene-2023        P. Jarrin.      S769973-Analisis Financiero */
/*   16-Jun-2023        B. Duenas.      Validacion analisis negocio */
/*   24-Jul-2023        B. Duenas.      Sacar valores ult negocio   */
/*   22/Sep/2023        P. Jarrín       Ajuste signo B903813-R215336*/
/*   30/Nov/2023        B. Duenas       Se agrega no lock-R220601   */
/*   16/Ene/2024        D. Morales      R221949:Se añade @i_cliente */
/*                                      y se actualiza buro         */ 
/*   04/Jun/2024        D. Morales      R236017:Se corrige condición*/
/*                                      de datos de negocio         */ 
/********************************************************************/

use cob_credito
go

if object_id ('sp_ffinanciero_resultados') is not null
    drop procedure sp_ffinanciero_resultados
go

create proc sp_ffinanciero_resultados
(  
            @s_ssn                int          = null,
            @s_sesn               int          = null,
            @s_srv                varchar(30)  = null,
            @s_lsrv               varchar(30)  = null,
            @s_user               login        = null,
            @s_date               datetime     = null,
            @s_ofi                int          = null,
            @s_rol                tinyint      = null,
            @s_org                char(1)      = null,
            @s_term               varchar(30)  = null,
            @t_trn                int          = 0,
            @i_retorno            char(1)      = 'S',
            @i_opcion             char(1),
            @i_banco              cuenta,
            @i_cliente            int          = null
)
as declare
            @w_return             int,
            @w_sp_name            varchar(32),
            @w_fec_proceso        datetime,
            @w_error              int,
            @w_fecha              varchar(50),
            @w_ventas             money,
            @w_compras            money,
            @w_utilidad_bruta     money,
            @w_gastos             money,
            @w_utilidad_neg       money,
            @w_otro_ing           money,
            @w_gtos_fami          money,
            @w_utilidad_fam       money,
            @w_cliente            int,
            @w_linea              char(1),
            @w_tramite            int,
            @w_nc_codigo          int,
            @w_pago               money         

--Obtener Fecha de Proceso
select @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso

select @w_sp_name = 'sp_ffinanciero_resultados'
   
if @i_opcion = 'G' -- Generar datos del balance
begin
    --Obtener el cliente del prestamo
    
    
    select @w_linea = substring(@i_banco,1,1)
    
    
    if(@w_linea = 'L')
    BEGIN
        select @w_tramite = cast(substring(@i_banco,2,100) as int)
        
        select @w_cliente = isnull(tr_cliente,0) 
        from cob_credito..cr_tramite with (nolock)
        where tr_tramite = @w_tramite
    END
    else
    begin
        select @w_cliente = isnull(op_cliente,0)
        from cob_cartera..ca_operacion with (nolock)
        where op_banco = @i_banco
    end
    
    select @w_cliente = isnull(@i_cliente, @w_cliente)
    
    if @w_cliente = 0
    begin
       select @w_error = 2101008
       goto ERROR
    end
 
    if not exists (select 1 from cobis..cl_analisis_negocio with (nolock) where an_cliente_id = @w_cliente)
    begin
        select @w_error = 2101008
        goto ERROR 
    end
    
   --Deudas Buro, Enlace, Ajuste si existe otro análisis del negocio para el mismo cliente y de otro negocio encerar esos valores.   
    select @w_nc_codigo = an_negocio_codigo 
    from cobis.dbo.ts_analisis_negocio with (nolock)
    where an_cliente_id = @w_cliente --id cliente
    and an_clase not in ('P')
    order by an_secuencial asc
	
	if @w_nc_codigo is not null
	begin
		exec @w_error = cobis..sp_analisis_negocio
		@i_operacion                  = 'B',
		@i_cliente                    = @w_cliente,
		@i_codigo_negocio             = @w_nc_codigo,
		@s_ssn                        = @s_ssn,       
		@s_srv                        = @s_srv,       
		@s_date                       = @s_date,       
		@s_user                       = @s_user,       
		@s_ofi                        = @s_ofi,
		@t_trn                        = 172100
		
		if @w_error != 0 
		begin
			goto ERROR
		end
	end 

    select @w_pago = (isnull(an_cuota_pago_buro,0) + isnull(an_cuota_pago_enlace,0)  + isnull(an_cuota_pago,0))
      from cobis..cl_analisis_negocio with (nolock), 
           cobis..cl_negocio_cliente with (nolock)
     where an_cliente_id = @w_cliente
       and an_negocio_codigo = nc_codigo
       and an_negocio_codigo = @w_nc_codigo
	   and an_cliente_id = nc_ente
       and nc_estado_reg = 'V'
    
    select @w_gtos_fami      = (isnull(sum(isnull(an_gastos_alimentos,0)),0) + isnull(sum(isnull(an_gastos_renta_viv,0)),0) + isnull(sum(isnull(an_gastos_energia_elect,0)),0) + 
                                isnull(sum(isnull(an_gastos_agua,0)),0)      + isnull(sum(isnull(an_gastos_telefono,0)),0)  + isnull(sum(isnull(an_gastos_tv,0)),0)  + 
                                isnull(sum(isnull(an_gastos_salud,0)) ,0)    + isnull(sum(isnull(an_gastos_transp,0)),0)    + isnull(sum(isnull(an_gastos_educ,0)),0) + 
                                isnull(sum(isnull(an_gastos_gas,0)),0)       + isnull(sum(isnull(an_gastos_vestido,0)),0)   + isnull(sum(isnull(an_gastos_otros,0)),0))
    from cobis..cl_analisis_negocio with (nolock)
    where an_cliente_id = @w_cliente
    and an_negocio_codigo = @w_nc_codigo
    
    select @w_ventas         = isnull(sum(isnull(an_ventas_prom_mes,0)), 0),        
           @w_compras        = isnull(sum(isnull(an_compras_prom_mes,0)), 0),       
           @w_gastos         = (isnull(sum(isnull(an_renta_neg,0)),0)     + isnull(sum(isnull(an_transporte_neg,0)),0) + isnull(sum(isnull(an_personal_neg,0)),0) +
                                isnull(sum(isnull(an_impuestos_neg,0)),0) + isnull(sum(isnull(an_electrica_neg,0)),0)  + isnull(sum(isnull(an_agua_neg,0)),0) + 
                                isnull(sum(isnull(an_telefono_neg,0)),0)  + isnull(sum(isnull(an_otros_neg,0)),0)      + isnull(@w_pago, 0)),
           @w_otro_ing       = isnull(sum(isnull(an_monto_extra,0)) , 0)
    from cobis..cl_analisis_negocio with (nolock), 
         cobis..cl_negocio_cliente with (nolock)
    where an_cliente_id = @w_cliente
    and an_negocio_codigo = nc_codigo
	and an_cliente_id = nc_ente
    and nc_estado_reg = 'V'
	
	select @w_utilidad_bruta = isnull(@w_ventas , 0) - isnull(@w_compras, 0) ,
		   @w_utilidad_neg   = isnull(@w_utilidad_bruta, 0) - isnull(@w_gastos, 0)
	select @w_utilidad_fam   = isnull(@w_utilidad_neg,0) + isnull(@w_otro_ing , 0)- isnull(@w_gtos_fami, 0) 
    
    --Insertando datos generados --
    delete cob_credito..cr_ffinanciero_resultado
    where fr_banco = @i_banco 
    
    if @@error != 0 
    begin
        select @w_error = 107064
        goto ERROR
    end
   
    select @w_error = 103076
    
    insert into cob_credito..cr_ffinanciero_resultado (fr_banco, fr_signo, fr_item, fr_monto, fr_porcentaje) values (@i_banco, '+', 'Ventas',  @w_ventas,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else 100 end)
    if @@error != 0
        goto ERROR

    insert into cob_credito..cr_ffinanciero_resultado (fr_banco, fr_signo, fr_item, fr_monto, fr_porcentaje) values (@i_banco, '-', 'Compras',  @w_compras,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_compras /@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
    insert into cob_credito..cr_ffinanciero_resultado (fr_banco, fr_signo, fr_item, fr_monto, fr_porcentaje) values (@i_banco, '=', 'Utilidad bruta (A)', @w_utilidad_bruta, 
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_utilidad_bruta/@w_ventas)*100 , 0) end)
    
    if @@error != 0
        goto ERROR
        
    insert into cob_credito..cr_ffinanciero_resultado (fr_banco, fr_signo, fr_item, fr_monto, fr_porcentaje) values (@i_banco, '-', 'Gastos de Operación y deudas',  @w_gastos,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_gastos/@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
        
    insert into cob_credito..cr_ffinanciero_resultado (fr_banco, fr_signo, fr_item, fr_monto, fr_porcentaje) values (@i_banco, '=', 'Utilidad Negocio (B)', @w_utilidad_neg,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_utilidad_neg/@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
        
    insert into cob_credito..cr_ffinanciero_resultado (fr_banco, fr_signo, fr_item, fr_monto, fr_porcentaje) values (@i_banco, '+', 'Otros ingresos familiares (C)',  @w_otro_ing,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_otro_ing/@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
        
    insert into cob_credito..cr_ffinanciero_resultado (fr_banco, fr_signo, fr_item, fr_monto, fr_porcentaje) values (@i_banco, '-', 'Gastos familiares (D)', @w_gtos_fami,
    case when (@w_ventas is null or @w_ventas = 0) then 0 else isnull( (@w_gtos_fami/@w_ventas)*100 , 0) end)
    if @@error != 0
        goto ERROR
        
    insert into cob_credito..cr_ffinanciero_resultado (fr_banco, fr_signo, fr_item, fr_monto, fr_porcentaje) values (@i_banco, '=', 'Utilidad de la unidad familiar', @w_utilidad_fam,
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
        from cob_credito..cr_ffinanciero_resultado with (nolock)
        where fr_banco = @i_banco 
    end
end

if @i_opcion = 'C' -- Consultar datos del balance
begin
    select fr_signo,                    
           fr_item,        
           fr_monto,       
           fr_porcentaje  
    from cob_credito..cr_ffinanciero_resultado with (nolock)
    where fr_banco = @i_banco 
    
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
