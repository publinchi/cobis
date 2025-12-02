/************************************************************************/
/*  Archivo:                operaciones_renovar_int.sp                  */
/*  Stored procedure:       sp_operaciones_renovar_int                  */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Mieles                                 */
/*  Fecha de Documentacion: 24/09/2021                                  */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_interface               */ 
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  24/09/2021       jmieles        Emision Inicial                     */
/*  15/06/2022       bduenas        Se agrega soporte a operacion 'U'   */
/*  27/06/22         bduenas        Se agrega campos a actualizar       */
/*  20/07/22         bduenas        Se convierte montos a moneda operac-*/
/*                                     ion                              */
/* **********************************************************************/

use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_operaciones_renovar_int')
   drop procedure sp_operaciones_renovar_int
go

CREATE proc sp_operaciones_renovar_int 
            @s_ssn                     int              = null,
            @s_user                    login            = null,
            @s_sesn                    int              = null,
            @s_term                    descripcion      = null,         
            @s_date                    datetime         = null,
            @s_srv                     varchar(30)      = null,
            @s_lsrv                    varchar(30)      = null,
            @s_rol                     smallint         = null,
            @s_ofi                     smallint         = null,
            @s_org_err                 char(1)          = null,
            @s_error                   int              = null,
            @s_sev                     tinyint          = null,
            @s_msg                     descripcion      = null,
            @s_org                     char(1)          = null,
            @t_rty                     char(1)          = null,
            @t_trn                     int              = null,
            @t_debug                   char(1)          = 'N',
            @t_file                    varchar(14)      = null,
            @t_from                    varchar(30)      = null,
            @t_show_version            bit              = 0,          
            @s_culture                 varchar(10)      = 'NEUTRAL',
            @i_operacion               char(1)          = null,
            @i_modo                    tinyint          = null,
            @i_tramite                 int              = null,
            @i_num_operacion           cuenta           = null,
            @i_producto                catalogo         = null,
            @i_abono                   money            = null,
            @i_moneda_abono            tinyint          = null,
            @i_monto_original          money            = null,
            @i_saldo_original          money            = null,
            @i_fecha_concesion         datetime         = null,
            @i_toperacion              catalogo         = null,
            @i_moneda_original         tinyint          = null,
            @i_aplicar                 char(1)          = 'S',
            @i_capitaliza              char(1)          = 'N',
            @i_saldo_renovar           money            = 0,
            @i_crea_ext                char(1)          = null,
            @i_tipo_tramite            char(1)          = null,
            @i_cliente                 int              = null,
            @i_numero_op_banco         cuenta           = null,
            @i_grupo                   catalogo         = null,
            @i_cuota_prorrogar         int              = null,
            @i_fecha_prorrogar         datetime         = null,
            @i_op_base                 CHAR(1)          = null,
            @o_msg_msv                 varchar(255)     = null out

as
        declare
            @w_error                    int,
            @w_sp_name1                 varchar(100),
            @w_sp_name                  varchar(100),
            @w_sum_operacion            money,
            @w_msg                      varchar(255) = null,
            @w_pais                     int,
            @w_cod_ofi_pais             int,
            @w_n_ope                    int,
            @w_valor_campo              varchar(30),
            @w_monto_op_base            money,
            @w_monto_op_base_temp       money,
            @w_operacionca              int,
            @w_monto_ca                 money,
            @w_banco                    int,
            @w_capitaliza               char(1),
            @w_moneda                   int,
            @w_moneda_2                 int,
            @w_return                   int
            
            select @w_sp_name = 'sp_operaciones_renovar_int'
            
            
            if @i_tramite = 0 or @i_tramite is null
                begin 
                    select
                    @w_error = 2110179
                    ---@w_msg    = 'Debe enviar numero de tramite para Actualizar.'
             
                    goto ERROR
                end
    
            if not exists(select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite)
                begin
                    select
                    @w_error = 2110182
                    --@w_msg    = 'El tramite no existe.'
             
                    goto ERROR
                end

            if not exists(select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite and tr_estado = 'N' )
                begin
                    select
                        @w_error = 2110183
                        --@w_msg    = 'No se puede modificar operaciones en un tramite aprobado'
                 
                        goto ERROR
                end

            if not exists(select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite and tr_estado = 'N' and tr_tipo in('R','E','F'))
                begin
                    select
                        @w_error = 2110184
                        --@w_msg    = 'El tramite no es tipo refinanciamiento, reestructuración y renovación.'
                 
                        goto ERROR
                end
            
            if not exists(select 1 from cob_cartera..ca_operacion where op_banco = @i_num_operacion)
                begin
                    select
                        @w_error = 2110185
                        --@w_msg    = 'La operación no existe'
                 
                        goto ERROR
                end

            if not exists(select 1 from cob_cartera..ca_operacion where op_banco = @i_num_operacion and op_estado not in (99,0,3,6))
                begin
                    select
                        @w_error = 2110186
                        --@w_msg    = 'La operación no esta en estado disponible.'
                 
                        goto ERROR
                end
                
            select @w_sum_operacion =  sum(am_acumulado + am_gracia - am_pagado) from cob_cartera..ca_amortizacion where am_operacion = (select op_operacion from cob_cartera..ca_operacion where op_banco = @i_num_operacion)
                
            if( @i_abono > @w_sum_operacion)
                begin
                    select
                        @w_error = 2110187
                        --@w_msg    = 'El abono no debe superar el valor de saldo de la operación.'
                 
                        goto ERROR
                end
            

        if(@i_capitaliza not in ('N','S','T')   )
            begin
                select
                    @w_error = 2110188
                    --@w_msg    = 'No ingreso un valor valido para Capitaliza'
             
                    goto ERROR
            end
            
            if(@i_op_base not in ('N','S')  )
                begin
                    select
                        @w_error = 2110189
                        --@w_msg    = 'No ingreso un valor valido para operación base.'
                 
                        goto ERROR
                end
            
if @i_operacion not in ('I', 'D', 'U')
begin
    select
        @w_error = 2110173
        --@w_msg    = 'Debe enviar una operacion valida.'
 
        goto ERROR
end


    
select @i_moneda_abono = isnull(@i_moneda_abono,0)

select @i_moneda_original = isnull(@i_moneda_original,0)



if exists(select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite and tr_tipo = 'E')    
begin
    select  @w_pais = pa_smallint from cobis..cl_parametro where pa_nemonico = 'CP' and pa_producto = 'ADM'
    select @w_cod_ofi_pais = pv_pais from cobis..cl_oficina, cobis..cl_ciudad, cobis..cl_provincia
            where of_oficina = @s_ofi
            and of_ciudad = ci_ciudad
            and ci_provincia = pv_provincia
    if (@w_pais = @w_cod_ofi_pais)
        begin
            select @w_n_ope = count(or_tramite) from   cob_credito..cr_op_renovar where or_tramite = @i_tramite 
            if(@w_n_ope > 0 and @i_operacion = 'I')--si tiene operacion que no deje insertar
                begin
                    select
                    @w_error = 2110197
                    --@w_msg    = 'El Tramite no puede tener dos operaciones base'
                    goto ERROR
                end
            if(@w_n_ope = 0 and @i_operacion = 'I' and @i_op_base <> 'S')--que se la base
                begin
                    select
                    @w_error = 2110198
                    --@w_msg    = 'La primera operacion en la reestructuracion debe ser la operación base'
                    goto ERROR
                end
        end
end

if @i_operacion in ('U', 'I')
begin
   -- Sacar monto de la nueva operacion
   select @w_monto_ca = op_monto, @w_moneda = op_moneda from cob_cartera..ca_operacion where op_banco = @i_num_operacion
   select @w_n_ope = count(or_tramite) from   cob_credito..cr_op_renovar where or_tramite = @i_tramite 

   if ( @w_n_ope > 1 and @i_operacion = 'U') or @i_operacion = 'I'
   begin
      --Sumar saldos de operaciones anteriores
      declare cursor_oper cursor read_only 
      for  select  or_capitaliza, or_num_operacion 
      from cob_credito..cr_op_renovar 
      where or_tramite = @i_tramite
      and or_num_operacion != @i_num_operacion
      
      open cursor_oper
      fetch next from cursor_oper into @w_capitaliza, @w_banco
      while @@fetch_status = 0
      begin
         select @w_operacionca = op_operacion,
                @w_moneda_2    = op_moneda
         from   cob_cartera..ca_operacion
         where  op_banco = @w_banco
         
         if @i_capitaliza =  'N' --Solo capital
            select @w_monto_op_base_temp =   sum (am_acumulado - am_pagado + am_gracia) -- Monto de la operaci¢n Base
            from   cob_cartera..ca_amortizacion , cob_cartera..ca_rubro_op
            where  am_operacion = @w_operacionca
            and    ro_operacion = am_operacion
            and    am_concepto  = ro_concepto
            and    ro_tipo_rubro = 'C'
         
         if @i_capitaliza =  'S' --Solo capital e interEs
            select @w_monto_op_base_temp =   sum (am_acumulado - am_pagado + am_gracia) -- Monto de la operaci¢n Base
            from   cob_cartera..ca_amortizacion , cob_cartera..ca_rubro_op
            where  am_operacion = @w_operacionca
            and    ro_operacion = am_operacion
            and    am_concepto  = ro_concepto
            and    ro_tipo_rubro in ('C','I')
         
         if @i_capitaliza =  'T' --Todo
            select @w_monto_op_base_temp =   sum (am_acumulado - am_pagado + am_gracia) -- Monto de la operaci¢n Base
            from   cob_cartera..ca_amortizacion
            where  am_operacion = @w_operacionca
            
            
         if @w_moneda_2 <> @w_moneda
         begin
         
         exec @w_return = cob_credito..sp_conversion_moneda
              @s_date             = @s_date,
              @i_fecha_proceso    = @s_date,
              @i_moneda_monto     = @w_moneda_2,              --moneda las cuotas
              @i_moneda_resultado = @w_moneda,        --moneda de la linea
              @i_monto            = @w_monto_op_base_temp,               --monto entrada
              @o_monto_resultado  = @w_monto_op_base_temp out,           --resultado de la conversion
              @o_monto_mn_resul   = null
         
         end
         
          select @w_monto_op_base += isnull(@w_monto_op_base_temp, 0)
            
            fetch next from cursor_oper into @w_capitaliza, @w_operacionca
         end
      close cursor_oper
      deallocate cursor_oper
      
   end
   
   select @w_operacionca = op_operacion
   from   cob_cartera..ca_operacion
   where  op_banco = @i_num_operacion
   
   if @i_capitaliza =  'N' --Solo capital
      select @w_monto_op_base_temp =   sum (am_acumulado - am_pagado + am_gracia) -- Monto de la operaci¢n Base
      from   cob_cartera..ca_amortizacion , cob_cartera..ca_rubro_op
      where  am_operacion = @w_operacionca
      and    ro_operacion = am_operacion
      and    am_concepto  = ro_concepto
      and    ro_tipo_rubro = 'C'
   
   if @i_capitaliza =  'S' --Solo capital e interEs
      select @w_monto_op_base_temp =   sum (am_acumulado - am_pagado + am_gracia) -- Monto de la operaci¢n Base
      from   cob_cartera..ca_amortizacion , cob_cartera..ca_rubro_op
      where  am_operacion = @w_operacionca
      and    ro_operacion = am_operacion
      and    am_concepto  = ro_concepto
      and    ro_tipo_rubro in ('C','I')
   
   if @i_capitaliza =  'T' --Todo
      select @w_monto_op_base_temp =   sum (am_acumulado - am_pagado + am_gracia) -- Monto de la operaci¢n Base
      from   cob_cartera..ca_amortizacion
      where  am_operacion = @w_operacionca
      
   select @w_monto_op_base += isnull(@w_monto_op_base_temp, 0)

   
   if @w_monto_ca < @w_monto_op_base
   begin
      select @w_error = 2110234
      goto ERROR
   end
      
end
--FIN Validaciones del monto
if @i_operacion = 'I'
begin
    
    select @w_n_ope = count(or_tramite) from   cob_credito..cr_op_renovar where or_tramite = @i_tramite and or_base = 'S'
                if(@w_n_ope > 0 and @i_op_base = 'S')--si tiene operacion que no deje insertar
                    begin
                        select
                        @w_error = 2110197
                        --@w_msg    = 'El Tramite no puede tener dos operaciones base'
                        goto ERROR
                    end
    
    select @w_sp_name1 = 'cob_credito..sp_op_renovar'
    
    exec @w_error                  = @w_sp_name1  --cob_credito..sp_op_renovar
            @s_ssn                     = @s_ssn,
            @s_user                    = @s_user,
            @s_sesn                    = @s_sesn,
            @s_term                    = @s_term,
            @s_date                    = @s_date,
            @s_srv                     = @s_srv,
            @s_lsrv                    = @s_lsrv,
            @s_rol                     = @s_rol,
            @s_ofi                     = @s_ofi,
            @t_trn                     = 21030,
            @i_tramite                 = @i_tramite,
            @i_num_operacion           = @i_num_operacion,
            @i_producto                = @i_producto,
            @i_abono                   = @i_abono,
            @i_moneda_abono            = @i_moneda_abono,
            @i_monto_original          = @i_monto_original,
            @i_saldo_original          = @i_saldo_original,
            @i_toperacion              = @i_toperacion,
            @i_moneda_original         = @i_moneda_original,
            @i_capitaliza              = @i_capitaliza,
            @i_op_base                 = @i_op_base,
            @i_operacion               ='I'
            
    if @w_error != 0
        begin
            --print '@w_error'+convert(varchar,@w_error)
            goto ERROR
        end
    

end


if @i_operacion = 'U'
begin
   select @w_sp_name1 = 'cob_credito..sp_op_renovar'
    if @i_abono is null
    begin
       select @w_error            = 1720548
       select @w_valor_campo  = 'payment'
       goto VALIDAR_ERROR
    end
    
    if @i_capitaliza is null
    begin
       select @w_error            = 1720548
       select @w_valor_campo  = 'renew_type'
       goto VALIDAR_ERROR
    end
    
    if @i_producto is null
    begin
       select @w_error            = 1720548
       select @w_valor_campo  = 'renew_producto'
       goto VALIDAR_ERROR
    end
    
    exec @w_error                  = @w_sp_name1  --cob_credito..sp_op_renovar
            @s_ssn                     = @s_ssn,
            @s_user                    = @s_user,
            @s_sesn                    = @s_sesn,
            @s_term                    = @s_term,
            @s_date                    = @s_date,
            @s_srv                     = @s_srv,
            @s_lsrv                    = @s_lsrv,
            @s_rol                     = @s_rol,
            @s_ofi                     = @s_ofi,
            @t_trn                     = 21030,
            @i_tramite                 = @i_tramite,
            @i_num_operacion           = @i_num_operacion,
            @i_producto                = @i_producto,
            @i_abono                   = @i_abono,
            @i_op_base                 = @i_op_base,
            @i_toperacion              = @i_toperacion,
            @i_monto_original          = @i_monto_original,
            @i_capitaliza              = @i_capitaliza,
            @i_operacion               = 'U'
                    
        if @w_error != 0
        begin
           --print '@w_error'+convert(varchar,@w_error)
           goto ERROR
        end
end


if @i_operacion = 'D'
begin
    select @w_sp_name1 = 'cob_credito..sp_op_renovar'
    
    exec @w_error                  = @w_sp_name1  --cob_credito..sp_op_renovar
            @s_ssn                     = @s_ssn,
            @s_user                    = @s_user,
            @s_sesn                    = @s_sesn,
            @s_term                    = @s_term,
            @s_date                    = @s_date,
            @s_srv                     = @s_srv,
            @s_lsrv                    = @s_lsrv,
            @s_rol                     = @s_rol,
            @s_ofi                     = @s_ofi,
            @t_trn                     = 21030,
            @i_tramite                 = @i_tramite,
            @i_num_operacion           = @i_num_operacion,
            @i_producto                = @i_producto,
            @i_abono                   = @i_abono,
            @i_moneda_abono            = @i_moneda_abono,
            @i_monto_original          = @i_monto_original,
            @i_saldo_original          = @i_saldo_original,
            @i_toperacion              = @i_toperacion,
            @i_moneda_original         = @i_moneda_original,
            @i_capitaliza              = @i_capitaliza,
            @i_op_base                 = @i_op_base,
            @i_operacion             ='D'
                    
        if @w_error != 0
             begin
                --print '@w_error'+convert(varchar,@w_error)
                goto ERROR
             end
end
             
        
return 0

VALIDAR_ERROR:
   select @w_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo , @w_error, @s_culture)
   goto ERROR

ERROR:
   --Devolver mensaje de Error

      exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @i_msg   = @w_msg,
         @t_from  = @w_sp_name,
         @i_num   = @w_error
      return @w_error
     

GO