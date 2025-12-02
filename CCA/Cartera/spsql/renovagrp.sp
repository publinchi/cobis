/******************************************************************/
/*  Archivo:            renovagrp.sp                              */
/*  Stored procedure:   sp_renovacion_grupal                      */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Adriana Giler                            */
/*  Fecha de escritura: 15-Jul-2019                               */
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
/*   - Orquestacion de desembolso operaciones renovadas grupales  */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  15/Jul/19        Adriana Giler      Emision Inicial           */
/*  08/Nov/2019      Luis Ponce         sp_prorratea_pago_grupal  */
/*  24/Jun/2022      KDR                Nuevo parámetro sp_liquid */
/******************************************************************/

use cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_renovacion_grupal')
   drop proc sp_renovacion_grupal
go

create proc sp_renovacion_grupal
    @s_ssn                  int         = null,
    @s_sesn                 int         = null,
    @s_date                 datetime,
    @s_user                 login       = null,
    @s_term                 descripcion = null,
    @s_ofi                  smallint    = null,
    @s_srv	                varchar(30)  = null,
    @i_banco                cuenta
as
declare
   @w_sp_name                    varchar(32),
   @w_forma_pago                 catalogo,
   @w_fpago_renova               catalogo,
   @w_debito_cta                 catalogo,
   @w_credito_cta                catalogo,
   @w_subtipo_tramite            char(1),
   @w_p_int                      int,
   @w_p                          varchar(3),
   @w_prioridad                  varchar(255),
   @w_ope_cancelar              int,  
   @w_reduccion                  char(1), 
   @w_cobro                      char(1), 
   @w_ult_proceso                datetime, 
   @w_tipo_aplicacion            char(1), 
   @w_cta_cancelar               cuenta,
   @w_bco_cancelar               cuenta,    
   @w_fecha_ult_proc             datetime,
   @w_error                      int,
   @w_operacionca                int,
   @w_moneda                     tinyint,
   @w_tramite_nueva              int,
   @w_dividendo                  int,
   @w_banco_generado             cuenta,
   @w_op_moneda                  smallint,
   @w_tipo_cobro                 char(1),
   @w_tipo_reduccion             char(1),
   @w_cuota_completa             char(1),
   @w_banco_renovada             varchar(24),
   @w_est_cancelado              smallint,
   @w_est_suspenso               smallint,
   @w_est_castigado              smallint,
   @w_est_vencido                smallint,
   @w_est_vigente                smallint,   
   @w_estado_op_vieja            tinyint,
   @w_div_vigente                int,
   @w_estado_fin                     tinyint,
   @w_secuencial_ing             int,
   @w_fecha_ini_nueva            datetime,
   @w_num_renovaciones_ant       smallint,
   @w_commit                     char(1),
   @w_msg                        varchar(120),
   @w_monto_pago                 money,
   @w_datos_renovada             varchar(64),
   @w_clase                      varchar(10),
   @w_cliente                    int,
   @w_tipo_tramite               varchar(1),
   @w_oficial                    int,
   @w_secuencial                 int,
   @w_return                     int,
   @w_ult_tramite                int,         --Inc_7615
   @w_cl_cartera                 varchar(10), --Inc_7615
   @w_clase_nva                  varchar(10),  --Inc_7615   
   @w_estado_operacion           tinyint,
   @w_fecha_ult_proceso          datetime,
   @w_beneficiario               int,
   @w_nombre                     varchar(50),
   @w_op_fecha_ult_proceso       datetime,
   @w_cotizacion_hoy             float = 0,
   @w_num_dec_mn                 tinyint,
   @w_monto_pagado               money = 0,
   @w_monto_renovar_mn           money = 0,
   @w_operacionca_n              int,
   @w_desembolso                 int,
   @w_plazo_no_vigente           tinyint,
   @w_min_fecha_vig              datetime,
   @w_banco_fic                  cuenta,
   @w_valor_renovar              money,
   @w_cuenta_banco               cuenta,
   @w_fecha_ini                  datetime,
   @w_tgarantia_liquida          catalogo,
   @w_grupo                      int,
   @w_tramite                    int,
   @w_filial                     tinyint,
   @w_codigo_externo             varchar(64),
   @w_monto_base                 money,
   @w_msg_matriz                 varchar(255),
   @w_liquidar_interc            MONEY --LPO TEC
   
   
   
   
-- INICIALIZACION DE VARIABLES
select 
@w_sp_name   = 'sp_renovacion',
@w_commit    = 'N'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_castigado  = @w_est_castigado out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_vigente    = @w_est_vigente   out

-- Determinar la forma de pago de renovacion 
select @w_fpago_renova = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'FDESRE'

if @@rowcount = 0 
begin
   select @w_error = 201196, 
          @w_msg = 'NO SE ENCUENTRA EL PARAMETRO: FDESRE' 
   goto ERRORFIN
end

-- PARAMETRO GARANTIA LIQUIDA
select @w_tgarantia_liquida = pa_char
from cobis..cl_parametro
where pa_nemonico = 'GARLIQ'
and pa_producto = 'GAR'

if @@rowcount = 0 
begin
   select @w_error = 201196, 
          @w_msg = 'NO SE ENCUENTRA EL PARAMETRO: GARLIQ' 
   goto ERRORFIN
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
   goto ERRORFIN
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
   goto ERRORFIN
end

--- DATOS DE LA OPERACION NUEVA
select 
@w_tramite_nueva     = op_tramite,
@w_moneda            = op_moneda,
@w_fecha_ini_nueva   = op_fecha_liq,
@w_banco_renovada    = op_anterior,
@w_cliente           = op_cliente,
@w_nombre            = op_nombre,
@w_tipo_tramite      = tr_tipo,
@w_oficial           = tr_oficial,
@w_clase_nva         = op_clase, 
@w_estado_operacion  = op_estado,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_operacionca_n     = op_operacion,
@w_subtipo_tramite   = tr_subtipo,
@w_valor_renovar     = op_monto,
@w_cuenta_banco      = op_cuenta

from   ca_operacion, cob_credito..cr_tramite
where  op_banco   = @i_banco
and    op_tramite is not null
and    op_tramite = tr_tramite

if @@rowcount = 0 
begin
   select @w_error = 710559, 
          @w_msg = 'NO SE ENCUENTRA LA OPERACION: ' + @i_banco
   goto ERRORFIN
end

-- Validar si existen renovaciones pendientes
if not exists (select 1 
               from   ca_operacion,  cob_credito..cr_op_renovar
               where  op_banco   = or_num_operacion
               and    or_tramite = @w_tramite_nueva   
               and    or_finalizo_renovacion  = 'N'
              )
   return 0

if @@trancount = 0 
begin
   begin tran
   select @w_commit = 'S'
end

--- SELECCION DEL NUMERO MAXIMO DEL TRAMITE
if exists(select 1 from   cob_credito..cr_tramite 
where  tr_numero_op_banco = @i_banco
and    tr_subtipo in ('N', 'S', 'T')    --REFINANCIACION, SUBROGACION, OTROS SI;   ANTES ESTABA 'E'
and    tr_estado = 'A')
begin
    update ca_operacion 
    set    op_num_renovacion = isnull(op_num_renovacion, 0) + 1 --NUMERO DE RENOVACION
    where  op_banco          = @i_banco

    if @@error <> 0 
    begin
        select @w_error = 710002, 
               @w_msg = 'ERROR AL ACTUALIZAR EL NUMERO DE RENOVACIONES DEL PRESTAMO '   
        goto ERRORFIN          
    end
end

--ACTUALIZAR DIAS DE MORA
exec @w_error = sp_estado_renreest  
     @s_date             = @w_fecha_ult_proceso,          
     @i_operacion        = 'M',
     @i_tipo             = 'R',
     @i_banco_orig       = @i_banco

if @w_error <> 0 goto ERRORFIN  

--Generando Secuencial
exec @w_secuencial = sp_gen_sec
     @i_operacion  = @w_operacionca_n
            

--LAZO PARA DESEMBOLSAR LAS OPERACIONES A RENOVAR 
declare cur_renovacion cursor  for 
select op_banco,             op_operacion,          op_moneda,
       op_fecha_ult_proceso, op_estado,             or_saldo_original, 
       op_cliente,           rtrim(p_p_apellido)+' '+rtrim(p_s_apellido)+' '+rtrim(en_nombre),             op_fecha_ini,
       op_grupo,             op_tramite,            isnull(en_filial,1)
from   ca_operacion,  cob_credito..cr_op_renovar, cobis..cl_ente
where  op_banco   = or_num_operacion
and    or_tramite = @w_tramite_nueva
and    op_cliente = en_ente 
for read only
   
open cur_renovacion
   
fetch cur_renovacion into  
@w_banco_renovada,   @w_operacionca,       @w_moneda,
@w_fecha_ult_proc,   @w_estado_op_vieja,   @w_monto_pago,
@w_beneficiario,     @w_nombre,            @w_fecha_ini,
@w_grupo,            @w_tramite,           @w_filial
   
while @@fetch_status = 0   
begin
    if @w_fecha_ini_nueva <> @w_fecha_ult_proc 
    begin      
        select 
        @w_error = 720303, 
        @w_msg = 'LA FECHA DE ULTIMO PROCESO DE LA OPERACION ' + @w_banco_renovada + ' NO ES IGUAL A LA FECHA DE INICIO DE LA OPERACION NUEVA'
        goto ERROR1          
    end  

    if @w_estado_op_vieja in (@w_est_cancelado, @w_est_castigado) 
    begin
        select 
        @w_error = 720303, 
        @w_msg = 'EL ESTADO DE LA OPERACION ' + @w_banco_renovada + ' NO ADMITE RENOVACION'  
        goto ERROR1          
    end       
         
    update cob_credito..cr_op_renovar 
    set or_finalizo_renovacion  = 'S',
        or_sec_prn              = @w_secuencial_ing
    where  or_tramite       = @w_tramite_nueva
    and    or_num_operacion = @w_banco_renovada

    if @@error <> 0 begin
        select @w_error = 710002, @w_msg = 'ERROR AL MARCAR COMO FINALIZADA LA RENOVACION ' + @w_banco_renovada   
        goto ERROR1          
    end
   
    select @w_monto_renovar_mn = @w_monto_pago
    select @w_monto_pagado = @w_monto_pagado + @w_monto_pago
   
    if @w_moneda <> 0
    begin
        exec sp_buscar_cotizacion
             @i_moneda     = @w_moneda,
             @i_fecha      = @w_op_fecha_ult_proceso,
             @o_cotizacion = @w_cotizacion_hoy out

        if @w_cotizacion_hoy is null 
            select @w_cotizacion_hoy = 1

        select @w_monto_renovar_mn = round(@w_monto_pago *  @w_cotizacion_hoy, @w_num_dec_mn)      
        select @w_monto_pagado = @w_monto_pagado + @w_monto_renovar_mn
    end
    else
    begin         
        select @w_cotizacion_hoy = 1
    end
      
    --Validar Forma de Pago a Aplicar
    if @w_subtipo_tramite = 'N'   --RENOVACION
    Begin  --Antes de desmbolsar la renovación se debe debitar lo adeudado    
        select @w_ope_cancelar    = op_operacion,
               @w_cta_cancelar    = op_cuenta,
               @w_bco_cancelar    = op_banco,
               @w_reduccion       = op_tipo_reduccion,
               @w_cobro           = op_tipo_cobro,
               @w_ult_proceso     = op_fecha_ult_proceso,
               @w_tipo_aplicacion = op_tipo_aplicacion,
               @w_op_moneda       = op_moneda,
               @w_tipo_cobro      = op_tipo_cobro              
        from   ca_operacion
        where  op_operacion = (select or_operacion_original 
                               from cob_credito..cr_op_renovar 
                               where or_tramite = @w_tramite_nueva) 

        --Validar si la fecha de proceso de la operacion es igual a la fecha de ejecución
        if @w_ult_proceso <> @w_fecha_ult_proceso 
        begin
            select 
            @w_error = 720303, 
            @w_msg = 'LA FECHA DE ULTIMO PROCESO DE LA OPERACION ' + @w_bco_cancelar + ' NO ES IGUAL A LA FECHA DE INICIO DE LA OPERACION NUEVA'
            goto ERROR1  
        end
        
        
        --Obtener el saldo a la fecha           
        EXEC cob_cartera..sp_montos_pago_grupal
            @i_banco              = @w_bco_cancelar,
            @o_liquidar           = @w_monto_pago          OUT,
            @o_liquidar_interc    = @w_liquidar_interc     OUT  --LPO TEC
        
        SELECT @w_monto_pago = @w_monto_pago + @w_liquidar_interc --LPO TEC Total para precancelar de Grupal e Interciclos
        

        --LPO TEC Se comenta este llamado al sp_pago_cartera, porque en Grupales debe llamarse al sp_prorratea_pago_grupal
        /*
        exec @w_error         = sp_pago_cartera
            @s_user           = @s_user,
            @s_term           = @s_term,
            @s_srv            = @s_srv,
            @s_date           = @s_date,
            @s_sesn           = @s_sesn,
            @s_ssn            = @s_ssn,
            @s_ofi            = @s_ofi,
            @i_banco          = @w_bco_cancelar,
            @i_beneficiario   = 'DB.AUT',
            @i_cuenta         = @w_cta_cancelar,
            @i_fecha_vig      = @s_date,
            @i_ejecutar       = 'S',
            @i_en_linea       = 'S',
            @i_producto       = @w_debito_cta, 
            @i_monto_mpg      = @w_monto_pago,
            @i_moneda         = @w_moneda,
            @i_tipo_reduccion = @w_tipo_cobro,
            @o_secuencial_ing = @w_secuencial_ing OUT,
            @o_msg_matriz     = @w_msg_matriz OUT
            
        if @w_error <> 0 
        begin
        select @w_msg = 'ERROR EJECUTANDO EL sp_pago_cartera' 
                goto ERROR1 
        end
        */
        --LPO TEC FIN Se comenta este llamado al sp_pago_cartera, porque en Grupales debe llamarse al sp_prorratea_pago_grupal
             
        --LPO TEC Grupales debe llamarse al sp_prorratea_pago_grupal:
        EXEC @w_error   = sp_prorratea_pago_grupal
        @s_user         = @s_user,
        @s_term         = @s_term,
        @s_srv          = @s_srv,  
        @s_date         = @s_date,
        @s_sesn         = @s_sesn,
        @s_ssn          = @s_ssn,
        @s_ofi          = @s_ofi,
        @i_banco        = @w_bco_cancelar,
        @i_beneficiario = 'DEBITO RENOVACION GRUPAL',
        @i_monto_pago   = @w_monto_pago,
        @i_forma_pago   = @w_debito_cta, --'NDAH_FINAN',
        @i_moneda_pago  = @w_moneda,
        @i_fecha_pago   = @s_date,
        @i_referencia   = @w_cta_cancelar
        
        if @w_error <> 0 
        begin
        select @w_msg = 'ERROR EJECUTANDO EL sp_prorratea_pago_grupal' 
                goto ERROR1 
        END
        --LPO TEC FIN Grupales debe llamarse al sp_prorratea_pago_grupal
        
        --Hacer desembolso a traves de nota de credito
        select @w_forma_pago = @w_credito_cta
        select @w_monto_pago = @w_valor_renovar
        select @w_valor_renovar = 0
    end
    else   -- Es reestructuración 
    begin
        select @w_forma_pago = @w_fpago_renova,
               @w_bco_cancelar  = null
    end
 
    --DESEMBOLSAR NUEVA OPERACION
    exec @w_error     = sp_desembolso
        @s_ofi            = @s_ofi,
        @s_term           = @s_term,
        @s_user           = @s_user,
        @s_date           = @s_date,
        @i_nom_producto   = 'CCA',
        @i_producto       = @w_forma_pago,       
        @i_cuenta         = @w_cuenta_banco,           --Cuenta de Ahorros Grupal
        @i_beneficiario   = @w_nombre,
        @i_ente_benef     = @w_cliente,
        @i_oficina_chg    = @s_ofi,
        @i_banco_ficticio = @w_operacionca_n,
        @i_banco_real     = @i_banco,
        @i_fecha_liq      = @s_date,
        @i_monto_ds       = @w_monto_pago,
        @i_moneda_ds      = @w_moneda,
        @i_tcotiz_ds      = 'COT',
        @i_cotiz_ds       = 1.0,
        @i_cotiz_op       = 1.0,
        @i_tcotiz_op      = 'COT',
        @i_moneda_op      = @w_moneda,
        @i_operacion      = 'I',
        @i_externo        = 'N',
        @i_pasar_tmp      = 'S'
        
        if @w_error <> 0 
        begin
            exec @w_error = sp_borrar_tmp
                @s_sesn   = @s_sesn,
                @s_user   = @s_user,
                @s_term   = @s_term,
                @i_banco  = @i_banco
                
            select @w_msg = 'ERROR EJECUTANDO EL sp_desembolso' 
            goto ERROR1
        end        
                  
    goto SIGUIENTE
   
    ERROR1:

    close cur_renovacion
    deallocate cur_renovacion   
      
    goto ERRORFIN
      
    SIGUIENTE:

    fetch cur_renovacion 
    into  @w_banco_renovada,   @w_operacionca,       @w_moneda,
          @w_fecha_ult_proc,   @w_estado_op_vieja,   @w_monto_pago,
          @w_beneficiario,     @w_nombre,            @w_fecha_ini,
          @w_grupo,            @w_tramite,           @w_filial
end -- WHILE CURSOR
   
close cur_renovacion
deallocate cur_renovacion

if @w_valor_renovar > @w_monto_pagado
begin
    select @w_monto_pagado = @w_valor_renovar - @w_monto_pagado
    select @w_monto_renovar_mn = @w_monto_pagado
    select @w_forma_pago = @w_credito_cta
    
    if @w_moneda <> 0
    begin
        exec sp_buscar_cotizacion
             @i_moneda     = @w_moneda,
             @i_fecha      = @w_op_fecha_ult_proceso,
             @o_cotizacion = @w_cotizacion_hoy out

        if @w_cotizacion_hoy is null
            select @w_cotizacion_hoy = 1
           
        select @w_monto_renovar_mn = round(@w_monto_pago *  @w_cotizacion_hoy, @w_num_dec_mn)      
    end

     --DESEMBOLSAR NUEVA OPERACION
    exec @w_error     = sp_desembolso
        @s_ofi            = @s_ofi,
        @s_term           = @s_term,
        @s_user           = @s_user,
        @s_date           = @s_date,
        @i_nom_producto   = 'CCA',
        @i_producto       = @w_forma_pago,       
        @i_cuenta         = @w_cuenta_banco,           --Cuenta de Ahorros Grupal
        @i_beneficiario   = @w_nombre,
        @i_ente_benef     = @w_cliente,
        @i_oficina_chg    = @s_ofi,
        @i_banco_ficticio = @w_operacionca_n,
        @i_banco_real     = @i_banco,
        @i_fecha_liq      = @s_date,
        @i_monto_ds       = @w_monto_pago,
        @i_moneda_ds      = @w_moneda,
        @i_tcotiz_ds      = 'COT',
        @i_cotiz_ds       = 1.0,
        @i_cotiz_op       = 1.0,
        @i_tcotiz_op      = 'COT',
        @i_moneda_op      = @w_moneda,
        @i_operacion      = 'I',
        @i_externo        = 'N',
        @i_pasar_tmp      = 'S'
        
    if @w_error <> 0 
    begin
        exec @w_error = sp_borrar_tmp
             @s_sesn   = @s_sesn,
             @s_user   = @s_user,
             @s_term   = @s_term,
             @i_banco  = @i_banco
                
            select @w_msg = 'ERROR EJECUTANDO EL sp_desembolso' 
            goto ERRORFIN
    end        
           
end

select @w_num_renovaciones_ant = isnull(max(op_num_renovacion),0)
from   ca_operacion,  cob_credito..cr_op_renovar
where  op_banco   = or_num_operacion
and    or_tramite = @w_tramite_nueva

update ca_operacion 
set op_num_renovacion  = @w_num_renovaciones_ant + 1,
    op_calificacion    = 'A',
    op_oficial         = @w_oficial,
    op_numero_reest    = case when op_reestructuracion = 'S' then isnull(op_numero_reest,0) + 1 else op_numero_reest end
where  op_tramite  = @w_tramite_nueva 

if @@error <> 0 begin
   select @w_error = 710002, @w_msg = 'ERROR AL ACTUALIZAR EL NUMERO DE RENOVACIONES '  
   goto ERRORFIN
end

--LIQUIDA   
update ca_operacion_tmp 
set opt_estado = 0
where opt_banco = @i_banco
   
select @w_banco_fic =  convert(varchar,@w_operacionca_n) 


exec @w_error = sp_borrar_tmp
     @s_sesn   = @s_sesn,
     @s_user   = @s_user,
     @s_term   = @s_term,
     @i_banco  = @i_banco

if @w_error <> 0 begin
   select @w_sp_name = 'sp_borrar_tmp'
   goto ERRORFIN
end

exec @w_error      = sp_pasotmp
@s_user            = @s_user,
@s_term            = @s_term,
@i_banco           = @i_banco,
@i_operacionca     = 'S',
@i_dividendo       = 'S',
@i_amortizacion    = 'S',
@i_cuota_adicional = 'S',
@i_rubro_op        = 'S',
@i_relacion_ptmo   = 'S',
@i_nomina          = 'S',
@i_acciones        = 'S',
@i_valores         = 'S'

if @w_error <> 0 begin
   select @w_sp_name = 'sp_pasotmp'
   goto ERRORFIN
end

exec @w_return        = sp_liquida
    @s_sesn           = @s_sesn,
    @s_ssn            = @s_ssn,
    @s_date           = @s_date,
    @s_ofi            = @s_ofi,
    @s_term           = @s_term,
    @s_user           = @s_user,
    @i_banco_ficticio = @w_banco_fic,
    @i_banco_real     = @i_banco,
    @i_fecha_liq      = @s_date,    
    @i_externo        = 'N',
	@i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
    @i_es_renovacion  = 'S', 
    @o_banco_generado = @w_banco_generado out

if @w_return <> 0 begin
    select @w_error = @w_return, @w_msg = 'ERROR AL LIQUIDAR RENOVACION'  
    goto ERRORFIN
end

--GARANTIA LIQUIDA
select @w_monto_base = ci_monto_ahorro 
from  cob_cartera..ca_ciclo
where  ci_prestamo = @i_banco
  and  ci_grupo = @w_grupo

select @w_monto_base = isnull(@w_monto_base, 0)

if @w_monto_base > 0
begin
    --Creacion de la garantia liquida
    exec @w_error     = cob_custodia..sp_custodia_automatica
    @s_ssn            = @s_ssn,
    @s_date           = @s_date,
    @s_user           = @s_user,
    @s_term           = @s_term,
    @s_ofi            = @s_ofi,
    @t_trn            = 19090,
    @t_debug          = 'N',
    @i_operacion      = 'L',
    @i_tipo_custodia  = @w_tgarantia_liquida,
    @i_tramite        = @w_tramite,
    @i_valor_inicial  = @w_monto_base,
    @i_moneda         = @w_moneda,
    @i_garante        = @w_cliente,
    @i_fecha_ing      = @s_date,
    @i_cliente        = @w_cliente,
    @i_clase          = 'C',
    @i_filial         = @w_filial,
    @i_oficina        = @s_ofi,
    @i_ubicacion      = 'DEFAULT',
    @o_codigo_externo = @w_codigo_externo out

    if @w_error <> 0 begin
       select @w_sp_name = 'sp_custodia_automatica'     
        goto ERRORFIN
    end
end
else
begin
      print 'Cuenta Grupal no tiene Monto minimo de ahorro'
      select @w_error = 725047
      goto ERRORFIN

end

--VALIDACION ESTADOS DE CREACION
exec @w_error = sp_estado_renreest
    @s_date             = @w_fecha_ult_proceso,           
    @i_operacion        = 'E',
    @i_tipo             = 'R',
    @i_banco_orig       = @w_banco_generado,
    @o_estado           = @w_estado_fin out


if @w_error <> 0 goto ERRORFIN   

if @w_estado_fin <> @w_estado_operacion
begin
   exec @w_error = sp_cambio_estado_op
    @s_user           = @s_user,
    @s_term           = @s_term,
    @s_date           = @s_date,
    @s_ofi            = @s_ofi,
    @i_banco          = @w_banco_generado,
    @i_fecha_proceso  = @w_fecha_ult_proceso,
    @i_estado_ini     = @w_estado_operacion, 
    @i_estado_fin     = @w_estado_fin,
    @i_tipo_cambio    = 'M',
    @i_en_linea       = 'N'
    
    if @w_error <> 0 goto ERRORFIN  
end

if @w_commit = 'S' begin
   commit tran 
   select @w_commit = 'N'
end


return 0

ERRORFIN:

if @w_commit = 'S' begin
   rollback tran 
   select @w_commit = 'N'
end

return @w_error

GO
