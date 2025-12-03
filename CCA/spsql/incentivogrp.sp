/************************************************************************/
/*      Archivo:                incentivogrp.sp                         */
/*      Stored procedure:       sp_incentivos_grp                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     Julio-2019                              */
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
/*      Mantenimiento de Incentivo de Creditos Grupales                 */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*     22-Jul-19     Adriana Giler      Emision Inicial                 */
/*     16-DIC-19     Luis Ponce         Control Fondos Insuficientes    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_incentivos_grp')
    drop proc sp_incentivos_grp
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_incentivos_grp
   @s_user              login        = null,
   @s_sesn              int          = null,
   @s_ssn               int          = null,
   @s_srv               varchar(30)  = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   @s_ofi               smallint     = null,   
   @i_secuencial_trn    int          = null,
   @i_opcion            char(1),                 
   @i_operacion         int          = 0,
   @i_sesion            int          = 0,   
   @o_mensaje           varchar(500) = null out
    

as
declare
   @w_sp_name               descripcion,
   @w_return                int,
   @w_error                 int,
   @w_msg                   mensaje,
   @w_debito_cta            catalogo,
   @w_credito_cta           catalogo,
   @w_op_forma_pago         catalogo,
   @w_cta_grupal            cuenta,
   @w_cod_alt               int,
   @w_valor                 money,
   @w_afectacion            char(1),
   @w_causa                 catalogo,
   @w_saldo_disponiblef     money,
   @w_saldo_contable        money,
   @w_moneda                smallint,
   @w_trn_prod              int,
   @w_saldo_disponible      money,
   @w_moneda_nacional       tinyint,
   @w_cotizacion_hoy        money,
   @w_num_renovacion        int,
   @w_num_secuencial        int,
   @w_estado                char(1),
   @w_sec_incentivo         varchar(100),
   @w_ssn                   int
   
-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
if @@rowcount = 0 
begin
   select @w_error = 201196, 
          @w_msg = 'NO SE ENCUENTRA EL PARAMETRO: MLO' 
   goto ERROR
end

--Forma de pago Debito en Cuenta 
select @w_debito_cta = pa_char
from cobis..cl_parametro
where pa_nemonico = 'DEBCTA'
and pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 201196, 
          @w_msg = 'NO SE ENCUENTRA EL PARAMETRO: DEBCTA' 
   goto ERROR
end

--Forma de pago Credito en Cuenta 
select @w_credito_cta = pa_char
from cobis..cl_parametro
where pa_nemonico = 'NCRAHO'
and pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 201196, 
          @w_msg = 'NO SE ENCUENTRA EL PARAMETRO: NCRAHO' 
   goto ERROR
end
  
  
if @i_opcion = 'I' -- Ingreso de Incentivos
begin
    --Insert datos del Incentivo  
    insert ca_incentivos_grp (ig_oper_padre,    ig_tipo_operacion,  ig_causa,         
                              ig_monto,         ig_estado,          ig_usuario,       
                              ig_oficina,       ig_fecha )
    select
            iic_operacion,     iic_tipo_operacion, iic_causa, 
            iic_monto,          'I',                @s_user, 
            @s_ofi,             @s_date
    from  ca_interf_incentivo_tmp
    where iic_sesn  = @i_sesion
    
    if @@error != 0
    begin
        select @o_mensaje  = 'Error insertando Incentivo de Credito',
               @w_error  = 725061
        goto ERROR
    end
end

if @i_opcion in ('A', 'R')  -- Aplicación de Créditos o Reversos de Incentivos
begin
    if not exists (select 1 from ca_incentivos_grp where ig_oper_padre = @i_operacion)
        return 0
        
    select @w_estado  = 'I'
    
    if @i_opcion = 'R'  --Reversos    
        select @w_estado  = 'A'        
        
    select @w_cta_grupal     = op_cuenta,
           @w_cod_alt        = op_operacion,
           @w_moneda         = op_moneda
    from ca_operacion
    where op_operacion = @i_operacion

    
    declare cur_incentivo cursor
    for select  ig_monto,  ig_tipo_operacion, ig_causa
        from    cob_cartera..ca_incentivos_grp
        where  ig_oper_padre = @i_operacion
          and  ig_estado = @w_estado 
    for update
   
    open cur_incentivo

    fetch cur_incentivo
    into  @w_valor,  @w_afectacion, @w_causa
      
      
    while @@fetch_status = 0
    begin
        --Obtener el secuencial
       exec @w_cod_alt = sp_gen_sec
            @i_operacion  = @i_operacion          
                
        -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
        if @w_moneda = @w_moneda_nacional 
        begin
             select @w_cotizacion_hoy = 1.0
        end 
        else 
        begin
             exec sp_buscar_cotizacion
             @i_moneda     = @w_moneda,
             @i_fecha      = @s_date,
             @o_cotizacion = @w_cotizacion_hoy output
        end
        
        if @i_opcion = 'R'  --Reversos    
        begin
            if @w_afectacion = 'C'
                select @w_afectacion = 'D'                   
            else
                select @w_afectacion = 'C'
        end    
            
        if @w_afectacion = 'C'  -- notas de credito
            select @w_trn_prod = 253,
                   @w_op_forma_pago = @w_credito_cta
        else 
            select @w_trn_prod = 264,
                   @w_op_forma_pago = @w_debito_cta
       
       exec @w_error = cob_interface..sp_ahndc_automatica 
                   @s_ssn          = @s_ssn,   
                   @s_srv          = @s_srv,
                   @s_ofi          = @s_ofi,
                   @s_user         = @s_user,
                   @t_trn          = @w_trn_prod ,
                   @i_cta          = @w_cta_grupal,
                   @i_val          = @w_valor,  
                   @i_cau          = @w_causa,
                   @i_mon          = @w_moneda, 
                   @i_fecha        = @s_date,               
                   @t_corr         = 'N',          --S/N dependiendo si es una reversa o no.                     
                   @i_alt          = @w_cod_alt,
                   @i_inmovi       = 'S',
                   @i_activar_cta  = 'N',
                   @i_is_batch     = 'N'
                   
        if @w_error <> 0  
        BEGIN
           close cur_incentivo
           deallocate cur_incentivo           
           return @w_error   --LPO TEC error 251033 Fondos Insuficientes, Se adicion� en cob_interface..sp_ahndc_automatica el manejo de En linea o batch
        end  
        
        --ACTUALIZAR EL ESTADO DEL INCENTIVO
        update ca_incentivos_grp 
        set ig_estado = @i_opcion  --Aplicado/Reversado
        where  CURRENT OF cur_incentivo
        
        if @@error != 0
        begin
            close cur_incentivo
            deallocate cur_incentivo
            return 725064  
        end
        
        fetch cur_incentivo
        into  @w_valor,  @w_afectacion, @w_causa    
    end    
    close cur_incentivo
    deallocate cur_incentivo
end
    
return 0


ERROR:
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error
      
    return @w_error

go

