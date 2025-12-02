/******************************************************************/
/*  Archivo:                ffcappago.sp                          */
/*  Stored procedure:       sp_ffinanciero_cappago                */
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
/*  y penales en contra del infractor según corresponda.          */
/******************************************************************/
/*                         PROPOSITO                              */
/*  Cálculo de la Capacidad del Pago del Cliente.                 */
/******************************************************************/
/*                       MODIFICACIONES                           */
/*     FECHA           AUTOR                RAZON                 */
/*  20/Ago/2019    Adriana Giler    Cálculo de Cuota Francesa     */
/*  22/Jun/2021    Patricio Mora    Ajustes para GFI              */
/*  05/Abr/2022    Dilan Morales    Ajustes para Lineas           */
/*  26/Jul/2022    Bruno Duenas     Se comenta validacion         */
/*  21/Sep/2023    Patricia Jarrín  Ajuste Cuota B905323-R215789  */
/*  25/Oct/2023    Patricia Jarrín  Ajuste Cuota B926177-R218067  */
/*  10/Nov/2023    Dilan Morales    R219139:Se cambia tipo redondeo*/
/*  15/Ene/2024    Dilan Morales    R221949:Se añade @i_cliente   */
/******************************************************************/
use cob_credito
go

if object_id ('sp_ffinanciero_cappago') is not null
    drop procedure sp_ffinanciero_cappago
go

create proc sp_ffinanciero_cappago
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
            @i_plazo            smallint     = null,
            @i_opcion           char(1),
            @i_banco            cuenta,
            @i_cliente          int         = null
)
as declare
            @w_return           int,
            @w_sp_name          varchar(32),
            @w_fec_proceso      datetime,
            @w_error            int,
            @w_fecha            varchar(50),
            @w_cliente          int,
            @w_monto            money,
            @w_plazo            smallint,
            @w_plazo_f          smallint,   
            @w_operacion        int,   
            @w_utilidad_fam     money,  
            @w_cuota            money,   
            @w_gen_cuota        char(1),
            @w_capacidad        money,
            @w_unuf             int,
            @w_linea            char(1),
            @w_tramite          int,
            @w_tdividendo       varchar(10),
            @w_factor           float

--Obtener Fecha de Proceso
select @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso

select @w_sp_name = 'sp_ffinanciero_cappago'

--Obterner UNUF
select @w_unuf = pa_int 
from cobis..cl_parametro
where pa_nemonico = 'UNUF' 
   
if @i_opcion = 'G' -- Generar calculo de la capacidad de pago
begin
    --Obtener el cliente del prestamo
    
    select @w_linea = substring(@i_banco,1,1)
    
    
    if(@w_linea = 'L')
    BEGIN
        select @w_tramite = cast(substring(@i_banco,2,100) as int)
        select @w_cliente = isnull(tr_cliente,0) ,
               @w_monto      = isnull(tr_monto,0),
               @w_cuota      = isnull((tr_monto / tr_num_dias) * 30,0),
               @w_plazo      = isnull(tr_num_dias,0),
               @w_gen_cuota  = 'N'
        from cob_credito..cr_tramite 
        where tr_tramite = @w_tramite
    END
    else
    begin
        select @w_cliente    = isnull(op_cliente,0),
           @w_monto      = isnull(op_monto,0),
           @w_cuota      = (select sum(isnull(am_cuota,0)) from cob_cartera..ca_amortizacion where am_operacion = op_operacion and am_dividendo = 1),
           @w_plazo      = isnull(op_plazo,0),
           @w_operacion  = op_operacion,
           @w_gen_cuota  = 'N',
           @w_tdividendo = op_tdividendo
        from cob_cartera..ca_operacion
        where op_banco = @i_banco
    end
    
    
    select @w_cliente = isnull(@i_cliente, @w_cliente)
       
    if @w_cliente = 0
    begin
       select @w_error =  2101008
       goto ERROR
    end
    
  --  if not exists(select 1 from cr_ffinanciero_resultado where fr_banco = @i_banco)  BDU: SE COMENTA VALIDACION PARA QUE SIEMPRE CALCULE
  --  begin
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
  --  end
    
    select @w_plazo_f = isnull(fc_plazo,0)
    from cr_ffinanciero_cappago
    where fc_banco = @i_banco 
        
    if isnull(@i_plazo,0) = 0
        select @i_plazo = @w_plazo
        
    if isnull(@i_plazo,0) > 0
        select @w_gen_cuota = 'N',
               @w_plazo = @i_plazo
    
    if(@w_linea = 'L')
    BEGIN
        select @w_gen_cuota = 'N'
    END
    
    if @w_gen_cuota = 'S'
    begin    
        exec @w_error = sp_ffinanciero_cfrancesa
             @i_operacion = @w_operacion,
             @i_plazo     = @w_plazo,
             @o_cuota     = @w_cuota out
        if (@w_error <> 0)
            goto ERROR
    end 
        
    if(@w_linea <> 'L')
    begin       
        if @w_tdividendo <> 'M'
        begin 
             select @w_factor = td_factor 
              from cob_cartera..ca_tdividendo
             where td_tdividendo = @w_tdividendo

            select @w_factor = @w_factor / 30 
            select @w_cuota = @w_cuota / @w_factor
        end          
    end
    
    
    --Obtener el valor de Utilidad Familiar
    select @w_utilidad_fam = (isnull(fr_monto ,0) * @w_unuf/100), 
           @w_capacidad    = case when (@w_utilidad_fam is null or @w_utilidad_fam = 0) then 0 else  (@w_cuota * 100) / @w_utilidad_fam end
    from cr_ffinanciero_resultado
    where fr_banco = @i_banco
    and   fr_item  = 'Utilidad de la unidad familiar'
    
    if @@rowcount = 0
    begin
       select @w_error =  190005
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
    delete cr_ffinanciero_cappago
    where fc_banco = @i_banco 
    
    if @@error != 0 
    begin
        select @w_error = 107064
        goto ERROR
    end    
    
    insert cr_ffinanciero_cappago values (@i_banco, @w_monto, @w_plazo, @w_cuota, @w_utilidad_fam, @w_capacidad)
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
           round(fc_cap_pago, 2)  
    from cr_ffinanciero_cappago
    where fc_banco = @i_banco 
end

if @i_opcion = 'C' -- Consultar datos del balance
begin
    select fc_monto,       
           fc_plazo,       
           fc_cuota,       
           fc_utilidad_fam,
           fc_cap_pago  
    from cr_ffinanciero_cappago
    where fc_banco = @i_banco
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
