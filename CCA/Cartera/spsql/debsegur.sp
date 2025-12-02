/******************************************************************/
/*  Archivo:            debsegur.sp                               */
/*  Stored procedure:   sp_debito_seguros                         */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 20-Jun-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Realiza Notas de debito a los seguros asociados a las      */
/*     operaciones hijas                                          */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR           RAZON                      */
/*  20/Jun/19        Lorena Regalado   Permite realizar las ND    */
/*                                     por el valor de los seguros*/
/*  19/Jul/19        Adriana Giler     Secuenciales de Transaccion*/
/*  30/Jul/19        Adriana Giler     Causales Debito Seguros    */
/*  31/Jul/19        Adriana Giler     Reverso de Debito Seguros  */
/*  02/AGO/19        Lorena Regalado   Se adiciona parametro      */
/*  16/DIC/19        Luis Ponce       Control Fondos Insuficientes*/
/*  13/Feb/20        Luis Ponce       Orden en Reversas Iva Seguro*/
/*  20/Feb/20        Luis Ponce       Orden DESC Reversa Iva Seguro*/
/*  01/Jun/22        Guisela Fernandez  Se comenta prints          */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_debito_seguros')
   drop proc sp_debito_seguros
go

create proc sp_debito_seguros
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
   @i_opcion           char(1)      = 'D',
   @i_secuencial_trn   int,             --Secuencial de la transaccion de DES
   @i_operacion        int,             --Secuencial de referencia con el que se grabo la informacion en tablas temporales
   @i_cta_grupal       cuenta,          --Cuenta de Ahorros grupal
   @i_moneda           tinyint,         --Moneda de la operacion
   @i_fecha_proceso    datetime,        --Fecha de Proceso
   @i_oficina          smallint,         --Oficina de la Operacion Grupal
   @i_es_interciclo    char(1)      = 'N',
   @i_op_interciclo    int          = null,
   @i_origen           char(1)      = null     --LRE 02AGO19   Para reversa de seguro por desembolso grupal



as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_monto                money,
   @w_cliente              int,
   @w_mensaje              varchar(255),
   @w_rol_act              varchar(10),
   @w_oficial              smallint,
   @w_plazo_op             smallint,
   @w_plazo                smallint,
   @w_tipo_seguro          varchar(10), 
   @w_monto_seguro         money, 
   @w_fecha_inicial        datetime,
   @w_fecha_desemb         datetime,
   @w_operacion            int,
   @w_cotizacion_hoy       money,
   @w_rowcount		       int,
   @w_moneda_nacional      tinyint,
   @w_num_dec              tinyint,
   @w_ssn                  int,
   @w_op_forma_pago        catalogo,
   @w_secuencial           int,
   @w_return               int,
   @w_porc_iva             float,
   @w_porc_iva2            float,
   @w_num_renovacion       int,
   @w_num_secuencial       int,
   @w_valor_sin_iva        money,
   @w_valor_sin_iva2       money,
   @w_valor_iva            money,
   @w_commit               char(1),
   @w_cod_alt              int,
   @w_sec_seguros          varchar(100),        --AGI 19JUL19   Secuenciales Seguros
   @w_causal               catalogo,            --AGI 30JUL19
   @w_causal_iva           catalogo,            --AGI 30JUL19
   @w_tseguro_iva          catalogo,            --AGI 30JUL19
   @w_causal_afectar       catalogo,            --AGI 31JUL19
   @w_monto_afectar        money,               --AGI 31JUL19
   @w_cont                 smallint             --AGI 31JUL19
      
select @w_commit = 'N'


-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 708174
   goto ERROR
end

-- NEMONICO DE LA FORMA DE PAGO
select @w_op_forma_pago = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'DEBCTA'

select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 708174
   goto ERROR
end

-- PORCENTAJE IVA
select @w_porc_iva = pa_float
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CTE'
and    pa_nemonico = 'PIVA'

select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 708174
   goto ERROR
end


select @w_porc_iva2 = 1 + (@w_porc_iva/100)


if @i_es_interciclo = 'N'
  select @w_cod_alt = @i_operacion
else
  select @w_cod_alt = @i_op_interciclo


if @i_opcion = 'D'  --Realizar Debitos
begin
    -- CURSOR DE SEGUROS
    if @i_es_interciclo = 'N'
        declare cursor_seguros cursor
        for 
        select distinct ts_causal,ts_causal_iva, so_tipo_seguro, sum(so_monto_seguro)
        from cob_cartera..ca_seguros_op, ca_tipo_seguro
        where (so_oper_padre  = @i_operacion
            or (so_operacion = @i_operacion and so_oper_padre = 0))
        and   (so_estado      is NULL  or so_estado <> 'A')
        and so_tipo_seguro = ts_tipo
        group by ts_causal,so_tipo_seguro,ts_causal_iva
        order by ts_causal,so_tipo_seguro,ts_causal_iva
    else
        declare cursor_seguros cursor
        for 
        select distinct ts_causal,ts_causal_iva,so_tipo_seguro, sum(so_monto_seguro)
        from cob_cartera..ca_seguros_op, ca_tipo_seguro
        where so_oper_padre  = @i_operacion
        and   so_operacion   = @i_op_interciclo
        and   so_estado      <> 'A'
        and so_tipo_seguro = ts_tipo
        group by ts_causal,so_tipo_seguro,ts_causal_iva
        order by ts_causal,so_tipo_seguro,ts_causal_iva

    for read only
                                                                                                                                                                                                                                           
    open  cursor_seguros
    fetch cursor_seguros into  @w_causal, @w_causal_iva,@w_tipo_seguro, @w_monto_seguro
                                                                                                                                                                                                          
    while @@fetch_status = 0
    begin
                                                                                                                                                                                                                                                             
        if (@@fetch_status = -1)
            return 710004

        -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
        if @i_moneda = @w_moneda_nacional 
        begin
            select @w_cotizacion_hoy = 1.0
        end 
        else 
        begin
            exec sp_buscar_cotizacion
            @i_moneda     = @i_moneda,
            @i_fecha      = @i_fecha_proceso,
            @o_cotizacion = @w_cotizacion_hoy output
        end

        -- DECIMALES DE LA MONEDA NACIONAL 
        exec @w_error   = sp_decimales
        @i_moneda       = @w_moneda_nacional,
        @o_decimales    = @w_num_dec out
                                                                                                                                                                                                                                                     
        if @w_error <> 0 goto ERROR

        --SEPARAR EL MONTO POR IVA DEL MONTO TOTAL DEL SEGURO
  
        if @w_monto_seguro > 0 
        begin
            select @w_valor_sin_iva = round((@w_monto_seguro/@w_porc_iva2), @w_num_dec)
            select @w_valor_iva     = @w_monto_seguro - @w_valor_sin_iva

            --NOTA DE DEBITO POR EL MONTO DEL SEGURO SIN IVA
            --INI AGI 19JUL19 Obtener el secuencial
            exec @w_cod_alt = sp_gen_sec
                 @i_operacion  = @i_operacion
                 
            --FIN AGI
            
            exec @w_return = cob_interface..sp_ahndc_automatica 
               @s_ssn          = @s_ssn,   
               @s_srv          = @s_srv,
               @s_ofi          = @i_oficina,
               @s_user         = @s_user,
               @t_trn          = 264,
               @i_cta          = @i_cta_grupal,
               @i_val          = @w_valor_sin_iva,  
               @i_cau          = @w_causal,
               @i_mon          = @i_moneda, 
               @i_fecha        = @i_fecha_proceso,               
               @t_corr         ='N',          --S/N dependiendo si es una reversa o no.                     
               @i_alt          = @w_cod_alt,
               @i_inmovi       = 'S',
               @i_activar_cta  = 'N',
               @i_is_batch     = 'N'
            
            if @w_return <> 0 
            BEGIN
               close cursor_seguros
               deallocate cursor_seguros
               select @w_error = @w_return
               goto ERROR               --LPO TEC error 251033 Fondos Insuficientes, Se adicionó en cob_interface..sp_ahndc_automatica el manejo de En linea o batch
            end
            
            if @i_es_interciclo = 'N'
            begin
                if not exists (select 1 from cob_cartera..ca_secuencial_seg_op 
                               where sso_oper_padre = @i_operacion and sso_tipo_seguro = @w_tipo_seguro)
                begin
                    insert into cob_cartera..ca_secuencial_seg_op values (
                    @i_fecha_proceso,  @i_operacion,  @w_tipo_seguro, @w_valor_sin_iva, NULL,  @s_ssn, NULL)

                    if @@rowcount = 0
                    begin
                        close cursor_seguros
                        deallocate cursor_seguros
                        select @w_error = 725043
                        goto ERROR
                    end
                end
                else
                begin
                    update cob_cartera..ca_secuencial_seg_op 
                    set sso_monto_seguro = @w_valor_sin_iva, 
                        sso_secuencial_nd_seg  = @s_ssn
                    where sso_oper_padre  = @i_operacion
                    and sso_tipo_seguro = @w_tipo_seguro
            
                    if @@rowcount = 0
                    begin
                        close cursor_seguros
                        deallocate cursor_seguros
                        select @w_error = 725044
                        goto ERROR
                    end
                end 
            end
            else  --Es interciclo
            begin
                if not exists (select 1 from cob_cartera..ca_secuencial_seg_op 
                               where sso_oper_padre = @i_op_interciclo and sso_tipo_seguro = @w_tipo_seguro)
                begin
                    insert into cob_cartera..ca_secuencial_seg_op values (
                                @i_fecha_proceso,  @i_op_interciclo,  @w_tipo_seguro, @w_valor_sin_iva, NULL,  @s_ssn, NULL)

                    if @@rowcount = 0
                    begin
                        close cursor_seguros
                        deallocate cursor_seguros
                        select @w_error = 725043
                        goto ERROR
                    end
                end
                else
                begin
                    update cob_cartera..ca_secuencial_seg_op 
                    set sso_monto_seguro = @w_valor_sin_iva, 
                        sso_secuencial_nd_seg  = @s_ssn
                    where sso_oper_padre  = @i_op_interciclo
                    and sso_tipo_seguro = @w_tipo_seguro
                
                    if @@rowcount = 0
                    begin
                        close cursor_seguros
                        deallocate cursor_seguros
                        select @w_error = 725044
                        goto ERROR
                    end
                end
            end
        
            --NOTA DE DEBITO POR EL MONTO DEL IVA
            --INI AGI 19JUL19 Obtener el secuencial
            exec @w_cod_alt = sp_gen_sec
                @i_operacion  = @i_operacion    
            --FIN AGI
            
            exec @w_return = cob_interface..sp_ahndc_automatica 
                 @s_ssn          = @s_ssn,   
                 @s_srv          = @s_srv,
                 @s_ofi          = @i_oficina,
                 @s_user         = @s_user,
                 @t_trn          = 264,
                 @i_cta          = @i_cta_grupal,
                 @i_val          = @w_valor_iva,  
                 @i_cau          = @w_causal_iva,
                 @i_mon          = @i_moneda, 
                 @i_fecha        = @i_fecha_proceso,               
                 @t_corr         = 'N',          --S/N dependiendo si es una reversa o no.                     
                 @i_alt          = @w_cod_alt,
                 @i_inmovi       = 'S',
                 @i_activar_cta  = 'N',
                 @i_is_batch     = 'N'
                              
            if @w_return <> 0 
            BEGIN
               IF @w_return <> 251033 --LPO TEC Fondos Insuficientes, Ahorros devuelve como error cuando la cuenta no tiene saldo disponible, se controla que
               BEGIN                  --cuando se trate de este caso no se lo tome como un error ya que en Ahorros cambiar el sp podria generar impacto en varias funcionalidades.                  
                  close cursor_seguros
                  deallocate cursor_seguros
                  select @w_error = @w_return
                  goto ERROR
               END
            end
            
            if @i_es_interciclo = 'N'
            begin
                if not exists (select 1 from cob_cartera..ca_secuencial_seg_op 
                               where sso_oper_padre = @i_operacion 
                               and sso_tipo_seguro = @w_tipo_seguro )
                begin
                    insert into cob_cartera..ca_secuencial_seg_op values (
                    @i_fecha_proceso,  @i_operacion,  @w_tipo_seguro, @w_valor_iva, NULL,  @s_ssn, NULL)

                    if @@rowcount = 0
                    begin
                        close cursor_seguros
                        deallocate cursor_seguros
                        select @w_error = 725043
                        goto ERROR
                    end
                end
                else
                begin
                    update cob_cartera..ca_secuencial_seg_op 
                    set sso_monto_seguro_iva = @w_valor_iva, 
                        sso_secuencial_nd_iva  = @s_ssn
                    where sso_oper_padre  = @i_operacion
                    and sso_tipo_seguro = @w_tipo_seguro
                
                    if @@rowcount = 0
                    begin
                        close cursor_seguros
                        deallocate cursor_seguros
                        select @w_error = 725044
                        goto ERROR
                    end
                end
            end
            else  --Es interciclo
            begin
                if not exists (select 1 from cob_cartera..ca_secuencial_seg_op 
                               where sso_oper_padre =  @i_op_interciclo
                               and sso_tipo_seguro = @w_tipo_seguro )
                 begin
                    insert into cob_cartera..ca_secuencial_seg_op values (
                    @i_fecha_proceso,  @i_op_interciclo,  @w_tipo_seguro, @w_valor_iva, NULL,  @s_ssn, NULL)

                    if @@rowcount = 0
                    begin
                       close cursor_seguros
                       deallocate cursor_seguros
                       select @w_error = 725043
                       goto ERROR
                    end
                end
                else
                begin
                    update cob_cartera..ca_secuencial_seg_op 
                    set sso_monto_seguro_iva = @w_valor_iva, 
                    sso_secuencial_nd_iva  = @s_ssn
                    where sso_oper_padre  = @i_op_interciclo
                    and sso_tipo_seguro = @w_tipo_seguro
                
                    if @@rowcount = 0
                    begin
                       close cursor_seguros
                       deallocate cursor_seguros
                       select @w_error = 725044
                       goto ERROR
                    end
                end --else
            end --else                       
        end
        --GFP se suprime print
        else
        /*
        begin
            print 'ERROR MONTO DE SEGURO ES MENOR O IGUAL A 0'
        end
        */

        fetch cursor_seguros into  @w_causal, @w_causal_iva, @w_tipo_seguro, @w_monto_seguro
                          
    end -- WHILE CURSOR PRINCIPAL                                                                                                                                                                                                                                                             
    close cursor_seguros
    deallocate cursor_seguros
end --  Opcion = 'D'


if @i_opcion = 'R'  --Reverso Debitos
begin
    declare cursor_reversos cursor
    for 
    select distinct ts_causal_rev, ts_causal_rev_iva, so_tipo_seguro, sum(so_monto_seguro)
    from cob_cartera..ca_seguros_op, ca_tipo_seguro
    where (so_oper_padre  = @i_operacion
        or (so_operacion = @i_operacion and so_oper_padre = 0))
    and   so_estado    =  'A'
    and so_tipo_seguro = ts_tipo
    group by ts_causal_rev,so_tipo_seguro, ts_causal_rev_iva
    order by ts_causal_rev DESC ,so_tipo_seguro, ts_causal_rev_iva --LPO TEC Se coloca en orden descendente para que en Pantalla muestre el orden inverso al que se ejecutó en el desembolso.
    for read only
                                                                                                                                                                                                                                           
    open  cursor_reversos
    fetch cursor_reversos into  @w_causal, @w_causal_iva, @w_tipo_seguro, @w_monto_seguro
                                                                                                                                                                                                          
    while @@fetch_status = 0
    begin                                                                                                                                                                                                                                                             
        if (@@fetch_status = -1)
            return 710004
        
        -- DECIMALES DE LA MONEDA NACIONAL 
        exec @w_error   = sp_decimales
        @i_moneda       = @w_moneda_nacional,
        @o_decimales    = @w_num_dec out
                                                                                                                                                                                                                                                     
        if @w_error <> 0 goto ERROR
        
        --SEPARAR EL MONTO POR IVA DEL MONTO TOTAL DEL SEGURO
        if @w_monto_seguro > 0 
        begin
            select @w_valor_sin_iva = round((@w_monto_seguro/@w_porc_iva2), @w_num_dec)
            select @w_valor_iva     = @w_monto_seguro - @w_valor_sin_iva
            select @w_cont = 1
                        
            while @w_cont <= 2  
            begin                        
                --Obtener el secuencial
               exec @w_cod_alt = sp_gen_sec
                    @i_operacion  = @i_operacion
            
                if @w_cont = 1  --Afectar Monto Iva  --LPO TEC Se invirtió el orden para que no de problemas en Ahorros, primero el IVA
                begin
                    select @w_causal_afectar = @w_causal_iva,
                           @w_monto_afectar  = @w_valor_iva
                end
                else        --Afectar monto sin IVA  --LPO TEC Se invirtió el orden para que no de problemas en Ahorros, segundo el valor del seuro sin el IVA
                begin                   
                    select @w_causal_afectar = @w_causal,
                           @w_monto_afectar  = @w_valor_sin_iva
                end
                
                --NOTA DE CREDITO POR EL MONTO 
                exec @w_return = cob_interface..sp_ahndc_automatica 
                   @s_ssn          = @s_ssn,   
                   @s_srv          = @s_srv,
                   @s_ofi          = @i_oficina,
                   @s_user         = @s_user,
                   @t_trn          = 253,
                   @i_cta          = @i_cta_grupal,
                   @i_val          = @w_monto_afectar,  
                   @i_cau          = @w_causal_afectar,
                   @i_mon          = @i_moneda, 
                   @i_fecha        = @i_fecha_proceso,               
                   @t_corr         ='N',          --S/N dependiendo si es una reversa o no.                     
                   @i_alt          = @w_cod_alt,
                   @i_inmovi       = 'S',
                   @i_activar_cta  = 'N',
                   @i_is_batch     = 'N'                    
                
                if @w_return <> 0
                BEGIN
                   IF @w_return <> 251033 --LPO TEC Fondos Insuficientes, Ahorros devuelve como error cuando la cuenta no tiene saldo disponible, se controla que
                   BEGIN                  --cuando se trate de este caso no se lo tome como un error ya que en Ahorros cambiar el sp podria generar impacto en varias funcionalidades.
                       close cursor_reversos
                       deallocate cursor_reversos
                       select @w_error = @w_return
                       goto ERROR
                    END
                end
                
                select @w_cont = @w_cont + 1                                
            end
        end
        fetch cursor_reversos into  @w_causal, @w_causal_iva, @w_tipo_seguro, @w_monto_seguro        
    end -- WHILE CURSOR PRINCIPAL                                                                                                                                                                                                                                                             
    close cursor_reversos
    deallocate cursor_reversos    
    
    --Actualizo el estado
    if @i_origen = 'G'    --Reversa de Desembolso Grupal
    begin

     if @i_es_interciclo = 'S'
     begin
       if exists (select 1 from cob_cartera..ca_seguros_op 
                  where so_operacion  = @i_operacion
                   and   so_estado = 'A')
       begin

           update cob_cartera..ca_seguros_op 
           set   so_estado = 'C'   --Reversado
           where so_operacion  = @i_operacion
           and   so_estado = 'A'
    
          if @@rowcount = 0
          begin
             select @w_error = 725044
             goto ERROR
          end
        end
     end
     else
     begin

         if exists (select 1 from cob_cartera..ca_seguros_op 
                  where so_oper_padre  = @i_operacion
                   and   so_estado = 'A')
         begin
             update cob_cartera..ca_seguros_op 
                    set   so_estado = 'C'   --Reversado
             where so_oper_padre  = @i_operacion
              and   so_estado = 'A'
    
            if @@rowcount = 0
            begin
               select @w_error = 725044
               goto ERROR
             end
          end

     end
    end
    else
    begin
        update cob_cartera..ca_seguros_op 
           set so_secuencial_trn = @w_secuencial, 
               so_estado = 'I'   --ingresado
        where so_operacion  = @i_operacion
        and   so_estado = 'A'
    
        if @@error = 0
        begin
           select @w_error = 725044
           goto ERROR
        end
    end
end

return 0

ERROR:
  if @w_commit = 'S'
   begin
        while @@trancount > 0 ROLLBACK TRAN
     return @w_error 
   end
   else
   begin  
     return @w_error
   end
   
go

