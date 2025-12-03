/************************************************************************/
/*  Archivo:                solicitud_credito_int.sp                    */
/*  Stored procedure:       sp_solicitud_credito_int                    */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Mieles                                 */
/*  Fecha de Documentacion: 31/08/2021                                  */
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
/*  31/08/2021       jmieles        Emision Inicial                     */
/*  24/09/2021       jmieles        Ajustes para REF/RES/REN            */
/* 23/03/2022        wlopez         Mejora, control de creacion         */
/*                                  de instancias de proceso            */
/* 24/03/2022        pmoreno        Envio fecha_crea a sp validacion    */
/* 04/04/2022        pquezada       Cambio en envío de codigo oficina   */
/* 26/04/2022        dmorales       Se omite campos en operacion U      */
/* 27/04/2022        dmorales      Se valida actualizacion contr_estado */
/* 27/06/2022        bduenas       Se agrega valor default al or_base en*/
/*                                 llamado a sp_operaciones_renovar_int */
/*  29/06/2022       bduenas        Se corrige validacion de fecha vto  */
/*  20/07/2022       bduenas        Se convierte montos a moneda operac-*/
/*                                     ion                              */
/* 11/11/2022        dmorales    R196611 Se añade validacion para update*/
/*                                desde DFA                             */
/* **********************************************************************/

use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_solicitud_credito_int')
   drop procedure sp_solicitud_credito_int
go

CREATE proc sp_solicitud_credito_int 
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
            @i_tipo_flujo              varchar(10)      = null,  
            @i_operacion               char(1)          = null,
            @i_tramite                 int              = null,
            @i_truta                   tinyint          = null,
            @i_oficina_tr              smallint         = null,
            @i_usuario_tr              login            = null,
            @i_fecha_crea              datetime         = null,
            @i_oficial                 smallint         = null,
            @i_sector                  catalogo         = null,
            @i_ciudad                  int              = null,
            @i_estado                  char(1)          = null,
            @i_numero_op_banco         cuenta           = null,
            @i_cuota                   money            = null,
            @i_frec_pago               catalogo         = null,
            @i_moneda_solicitada       tinyint          = null,
            @i_provincia               int              = null,
            @i_monto_solicitado        money            = null,
            @i_monto_desembolso        money            = null,
            @i_pplazo                  smallint         = null,
            @i_tplazo                  catalogo         = null,
            @i_proposito               catalogo         = null,
            @i_razon                   catalogo         = null,
            @i_txt_razon               varchar(255)     = null,
            @i_efecto                  catalogo         = null,
            /* campos para lineas de credito */
            @i_cliente                 int              = null,
            @i_grupo                   int              = null,
            @i_fecha_inicio            datetime         = null,
            @i_num_dias                smallint         = 0,
            @i_per_revision            catalogo         = null,
            @i_condicion_especial      varchar(255)     = null,
            @i_rotativa                char(1)          = null,
            /* operaciones originales y renovaciones */
            @i_linea_credito           cuenta           = null,
            @i_toperacion              catalogo         = null,
            @i_producto                catalogo         = null,
            @i_monto                   money            = null,
            @i_moneda                  tinyint          = null,
            @i_destino                 catalogo         = null, --destino financiero
            @i_ciudad_destino          int            = null,
            -- solo para prestamos de cartera
            @i_cliente_cca             int              = null,
            @i_op_renovada             cuenta           = null,
            @i_deudor                  int              = null,
            -- reestructuraciones
            @i_op_reestructurar        cuenta           = null,
            @i_origen_fondo            catalogo         = null,         
            @i_plazo                   catalogo         = null,
            @i_ssn                     int              = null,
            --Financiamientos JSB 99-03-30
            @i_revolvente              char(1)          = null,
            @i_tipo_linea              varchar(10)      = null,
            @i_subtipo                 catalogo         = null,       
            @i_canal                   tinyint          = 0,           
            @i_id_inst_proc            int              = null,         
            @i_destino_descripcion     descripcion      = null,        
            @i_objeto                  catalogo         = null,        
            @i_actividad               catalogo         = null,         
            @i_descripcion_oficial     descripcion      = null,         
            @i_tipo_cartera            catalogo         = null,         
            @i_sector_cli              catalogo         = null,          
            @i_expromision             catalogo         = null,         
            @i_convenio                char(1)          = null,
            @i_codigo_cliente_empresa  varchar(10)      = null,
            @i_reprogramingObserv      varchar(255)     = null,        
            @i_motivo_uno              varchar(255)     = null,         
            @i_motivo_dos              varchar(255)     = null,         
            @i_motivo_rechazo          catalogo         = null,
            @i_valida_estado           char(1)          ='S',
            @i_numero_testimonio       varchar(50)      = null,
            @i_tamanio_empresa         varchar(5)       = null,
            @i_producto_fie            catalogo         = null,
            @i_num_viviendas           tinyint          = null,
            @i_tipo_calificacion       catalogo         = null,
            @i_tasa                    float            = null,
            @i_sub_actividad           catalogo         = null,
            @i_departamento            catalogo         = null,
            --CAMPOS AUMENTADOS EN INTEGRACION FIE 
            @i_actividad_destino       catalogo         = null,        
            @i_parroquia               catalogo         = null,         
            @i_canton                  catalogo         = null,         
            @i_barrio                  catalogo         = null,         
            @i_dia_fijo                smallint  = null,         
            @i_enterado                catalogo         = null,        
            @i_otros_ent               varchar(64)      = null,         
            -- Manejo de seguros                                         
            @i_seguro_basico           char(1)          = null,         
            @i_seguro_voluntario       char(1)          = null,          
            @i_tipo_seguro             catalogo         = null,          
            @o_tramite                 int              = null   out,
            @o_numero_proceso          varchar(255)     = null   out,
            @o_numero_proceso_largo    varchar(255)     = null   out

as
declare
   @w_error             int,
   @w_sp_name1          varchar(100),
   @w_secuencial        smallint,
   @w_codigo_proceso    int,
   @w_tipo              char(1),
   @w_process_id        varchar(5),
   @w_inst_proceso      int,
   @w_siguiente_alterno varchar(255),
   @w_tramite           int,
   @w_tipo_cliente      char(1),
   @w_num_op_banco      cuenta,
   @w_msg               varchar(255),
   @w_estado            char(1),
   @w_capitaliza        char(1),
   @w_monto_op_base     money,
   @w_operacionca       int,
   @w_tproducto         catalogo,
   @w_monto             money,
   @w_moneda            int,
   @w_return            int,
   @w_param_regularizar varchar(30),
   @w_actividad         varchar(30)
         
select @w_tipo_cliente = en_subtipo from cobis..cl_ente where en_ente = @i_cliente_cca    
select @w_sp_name1 = 'sp_solicitud_credito_int'
            
if @i_operacion <> 'I' and @i_operacion <> 'U'
begin
   select
      @w_error = 2110173
      --@w_msg    = 'Debe enviar una operacion valida.'
 
        goto ERROR
end

if @i_canal is null
begin
   select
      @w_error = 2110174
      --@w_msg    = 'Debe enviar un canal.'
 
        goto ERROR
end

   select @w_codigo_proceso = pr_codigo_proceso from cob_workflow..wf_proceso where pr_nemonico = @i_tipo_flujo
   
   if @@rowcount = 0
   begin
      select
      @w_error = 2110175
      --@w_msg    = 'Debe enviar un tipo de Flujo.'
 
        goto ERROR
   end
   
   select @w_secuencial = max(bph_codsequential ) from cob_fpm..fp_bankingproductshistory where bph_product_id = @i_toperacion
   
   if @@rowcount = 0
   begin
      select
      @w_error = 2110176
      --@w_msg    = 'Debe enviar el tipo de Operacion.'
 
        goto ERROR
   end
   
   select @w_process_id = pph_process_id  from cob_fpm..fp_processbyproducthistory where bph_codsequentialfk = @w_secuencial and pph_flow_id = @w_codigo_proceso
   
   if @@rowcount = 0
   begin
      select
      @w_error = 2110177
 
        goto ERROR
   end
   
   
   
   if @w_process_id in('ORI','REN','RES','REF')
   begin
      if @w_process_id = 'ORI'
      begin
         select @w_tipo = 'O'
      end
      
      if @w_process_id = 'REN'
      begin
         select @w_tipo = 'R'
      end
      
      if @w_process_id = 'RES'
      begin
         select @w_tipo = 'E'
      end
      
      if @w_process_id = 'REF'
      begin
         select @w_tipo = 'F'
      end
   end
   else
   begin
      select
      @w_error = 2110177
      --@w_msg    = 'No se encontro un proceso para el tipo de flujo y operacion enviada.'
 
        goto ERROR
   end
   
select @w_num_op_banco = null
   

if @w_tipo is not null and @w_tipo in('E')
begin
   select @w_tproducto = op_toperacion  from cob_cartera..ca_operacion where op_banco = @i_op_reestructurar
   if @i_toperacion != @w_tproducto 
   begin
      select @w_error = 2110137 --No se puede cambiar el tipo de producto de la operación a restructurar
      goto ERROR
   end
end


if(@w_tipo is not null and (@w_tipo in('R','E','F')))
   begin
      if (@i_op_renovada <> '' or @i_op_renovada is not null) or (@i_op_reestructurar <> '' or @i_op_reestructurar is not null)
         begin
            select @w_num_op_banco = @i_op_renovada
         end
      else
         begin
            select
            @w_error = 2110199
            --@w_msg    = 'Debe enviar una operación para reestructurar, renovar o refinanciar'
            goto ERROR
         end   
   end
   
if(@w_tipo is not null and (@w_tipo in('R','E','F')))
   begin
      if (@w_num_op_banco = '' or @w_num_op_banco is null)
      begin
            select @w_num_op_banco = @i_op_reestructurar
            if (@w_num_op_banco = '' or @w_num_op_banco is null)
            begin
               select
               @w_error = 2110199
               --@w_msg    = 'Debe enviar una operación para reestructurar, renovar o refinanciar'
               goto ERROR
            end
      end
   end

select @i_moneda = isnull(@i_moneda,0)
  
--Validaciones del monto en base al capitaliza
if(@w_tipo is not null and (@w_tipo in('R','E','F'))) and @i_operacion = 'I'
begin
   select @w_capitaliza = 'N'
    
   select @w_operacionca = op_operacion,
          @w_moneda      = op_moneda
   from   cob_cartera..ca_operacion
   where  op_banco = @i_op_reestructurar

   if @w_capitaliza =  'N' --Solo capital
      select @w_monto_op_base =   sum (am_acumulado - am_pagado + am_gracia) -- Monto de la operaci¢n Base
      from   cob_cartera..ca_amortizacion , cob_cartera..ca_rubro_op
      where  am_operacion = @w_operacionca
      and    ro_operacion = am_operacion
      and    am_concepto  = ro_concepto
      and    ro_tipo_rubro = 'C'
   
   if @i_moneda <> @w_moneda
   begin
   
   exec @w_return = cob_credito..sp_conversion_moneda
        @s_date             = @s_date,
        @i_fecha_proceso    = @s_date,
        @i_moneda_monto     = @w_moneda,        --moneda operacion
        @i_moneda_resultado = @i_moneda,        --moneda que llega
        @i_monto            = @w_monto_op_base,               --monto entrada
        @o_monto_resultado  = @w_monto_op_base out,           --resultado de la conversion
        @o_monto_mn_resul   = null
   
   end
   
   
   if @i_monto < @w_monto_op_base
   begin
      select @w_error = 2110234 --El monto de la operacion no cubre el monto de la operacion a restrucutrar o renovar
      goto ERROR
   end 
end  

   
   select @w_sp_name1 = 'cob_interface..sp_valida_campos_credito'
   
    exec @w_error                   = @w_sp_name1  --cob_interface..sp_valida_campos_credito
         @s_ssn                     = @s_ssn,
         @s_user                    = @i_usuario_tr,--@s_user PMO
         @s_sesn                    = @s_sesn,
         @s_term                    = @s_term,
         @s_date                    = @s_date,
         @s_srv                     = @s_srv,
         @s_lsrv                    = @s_lsrv,
         @s_rol                     = @s_rol,
         @s_ofi                     = @i_oficina_tr, --PQU oficina del trámite @s_ofi,
         @s_org_err                 = @s_org_err,
         @s_error                   = @s_error,
         @s_sev                     = @s_sev,
         @s_msg                     = @s_msg,
         @s_org                     = @s_org,
         @t_rty                     = @t_rty,
         @t_trn                     = @t_trn,
         @t_debug                   = @t_debug,
         @t_file                    = @t_file,
         @t_from                    = @t_from,
         @i_oficina                 = @i_oficina_tr,
         @i_linea_credito           = @i_linea_credito,
         @i_sector                  = @i_sector,
         @i_destino_financiero      = @i_destino,
         @i_destino_econimico       = @i_actividad_destino,
         @i_origen_fondos           = @i_origen_fondo,
         @i_oficial                 = @i_oficial,
         @i_moneda                  = @i_moneda,
         @i_enterado                = @i_enterado,
         @i_provincia               = @i_provincia,
         @i_ciudad                  = @i_ciudad,
         @i_ciudad_destino          = @i_ciudad_destino,
         @i_deudor                  = @i_cliente_cca,
         @i_fecha_inicio            = @i_fecha_inicio,
         @i_fecha_crea              = @i_fecha_crea,
         @i_pplazo                  = @i_pplazo,
         @i_tplazo                  = @i_tplazo,
         @i_toperacion              = @i_toperacion,
         @i_canal                   = @i_canal
         
         if @w_error != 0
          begin
            --print '@w_error'+convert(varchar,@w_error)
            goto ERROR
          end

select @i_fecha_inicio  = cast(@i_fecha_inicio as date) --DMO SE OMITE HORA ENVIADA
select @i_fecha_crea    = cast(@i_fecha_crea as date) --DMO SE OMITE HORA ENVIADA
     
if @i_operacion = 'I'
begin
   if @i_tramite <> 0
   begin 
      select
      @w_error = 2110178
      --@w_msg    = 'No debe enviar numero de tramite para Crear.'
 
        goto ERROR
   end

   select @w_sp_name1 = 'cob_credito..sp_tramite'
   
      exec @w_error                 = @w_sp_name1  --cob_credito..sp_tramite
         @s_ssn                     = @s_ssn,
         @s_user                    = @i_usuario_tr,--@s_user PMO 
         @s_sesn                    = @s_sesn,
         @s_term                    = @s_term,
         @s_date                    = @s_date,
         @s_srv                     = @s_srv,
         @s_lsrv                    = @s_lsrv,
         @s_rol                     = @s_rol,
         @s_ofi                     = @i_oficina_tr, --PQU oficina del trámite @s_ofi,
         @s_org_err                 = @s_org_err,
         @s_error                   = @s_error,
         @s_sev                     = @s_sev,
         @s_msg                     = @s_msg,
         @s_org                     = @s_org,
         @t_rty                     = @t_rty,
         @t_trn                     = 21020,
         @t_debug                   = @t_debug,
         @t_file                    = @t_file,
         @t_from                    = @t_from,
         @i_operacion               = @i_operacion,
         @i_tramite                 = @i_tramite,
         @i_tipo                    = @w_tipo,
         @i_oficina_tr              = @i_oficina_tr,
         @i_usuario_tr              = @i_usuario_tr,
         @i_fecha_crea              = @i_fecha_crea,
         @i_oficial                 = @i_oficial,
         @i_sector                  = @i_sector,
         @i_ciudad                  = @i_ciudad,
         @i_estado                  = @i_estado,
         @i_numero_op_banco         = @i_numero_op_banco,
         @i_cuota                   = @i_cuota,
         @i_frec_pago               = @i_frec_pago,
         @i_moneda_solicitada       = @i_moneda_solicitada,
         @i_provincia               = @i_provincia,
         @i_monto_solicitado        = @i_monto_solicitado,
         @i_monto_desembolso        = @i_monto_desembolso,
         @i_pplazo                  = @i_pplazo,
         @i_tplazo                  = @i_tplazo,
         /* campos para tramites de garantias */
         @i_proposito               = @i_proposito,
         @i_razon                   = @i_razon,
         @i_txt_razon               = @i_txt_razon,
         @i_efecto                  = @i_efecto,
         /* campos para lineas de credito */
         @i_cliente                 = @i_cliente,
         @i_grupo                   = @i_grupo,
         @i_fecha_inicio            = @i_fecha_inicio,
         @i_num_dias                = @i_num_dias,
         @i_per_revision            = @i_per_revision,
         @i_condicion_especial      = @i_condicion_especial,
         @i_rotativa                = null,
         @i_destino_fondos          = null,
         @i_comision_tramite        = null,
         @i_subsidio                = null,
         @i_tasa_aplicar            = null,
         @i_tasa_efectiva           = null,
         @i_plazo_desembolso        = null,
         @i_forma_pago              = null,
         @i_plazo_vigencia          = null,
         @i_formalizacion           = null,
         @i_cuenta_corrientelc      = null,
         /* operaciones originales y renovaciones */
         @i_linea_credito           = @i_linea_credito,
         @i_toperacion              = @i_toperacion,
         @i_producto                = @i_producto,
         @i_monto                   = @i_monto,
         @i_moneda                  = @i_moneda,
         @i_periodo                 = null,
         @i_num_periodos            = null,
         @i_destino                 = @i_destino,
         @i_ciudad_destino          = @i_ciudad_destino,
         -- solo para prestamos de cartera
         @i_reajustable             = null,
         @i_per_reajuste            = null,
         @i_reajuste_especial       = null,
         @i_fecha_reajuste          = null,
         @i_cuota_completa          = null,
         @i_tipo_cobro              = null,
         @i_tipo_reduccion          = null,
         @i_aceptar_anticipos       = null,
         @i_precancelacion          = null,
         @i_tipo_aplicacion         = null,
         @i_renovable               = null,
         @i_fpago                   = null,
         @i_cuenta                  = null,
         -- generales               
         @i_renovacion              = null,
         @i_cliente_cca             = @i_cliente_cca,
         @i_op_renovada             = @i_op_renovada,
         @i_deudor                  = @i_deudor,
         -- reestructuracion
         @i_op_reestructurar        = @i_op_reestructurar,
         @i_sector_contable         = null,
         @i_origen_fondo            = @i_origen_fondo,
         @i_fondos_propios          = null,
         @i_plazo                   = @i_plazo,
         -- Financiamientos
         @i_revolvente              = @i_revolvente,
         @i_trm_tmp                 = null,
         @i_her_ssn                 = null,
         @i_causa                   = null,
         @i_contabiliza             = null,
         @i_tvisa                   = null,
         @i_migrada                 = null,
         @i_tipo_linea              = @i_tipo_linea,
         @i_plazo_dias_pago         = null,
         @i_tipo_prioridad          = null,
         @i_linea_credito_pas       = null,
         --Vivi
         @i_proposito_op            = null,
         @i_linea_cancelar          = null,
         @i_fecha_irenova           = null,
         @i_subtipo                 = @i_subtipo,                   
         @i_tipo_tarjeta            = null,              
         @i_motivo                  = null,                     
         @i_plazo_pro               = null,                 
         @i_fecha_valor             = null,                
         @i_estado_lin              = null,                 
         @i_tasa_asociada    = null,
         @i_tpreferencial           = null,
         @i_porcentaje_preferencial = null,
         @i_monto_preferencial      = null,
         @i_abono_ini               = null,
         @i_opcion_compra           = null,
         @i_beneficiario            = null,
         @i_financia                = null,
         @i_ult_tramite             = null,               
         @i_empleado                = null,                  
         @i_ssn                     = @i_ssn,
         @i_nombre_empleado         = null,
         @i_canal                   = @i_canal,
         @i_promotor                = null,
         @i_comision_pro  = null,
         @i_iniciador               = null,
         @i_entrevistador           = null,
         @i_vendedor                = null,
         @i_cuenta_vende            = null,
         @i_agencia_venta           = null,
         @i_aut_valor_aut           = null,
         @i_aut_abono_aut           = null,
         @i_canal_venta             = null,
         @i_referido                = null,
         @i_FIniciacion             = null,
         --Prestamos Gemelos
         @i_gemelo                  = null,
         @i_tasa_prest_orig         = null,
         @i_banco_padre             = null,
         @i_num_cuenta              = null,
         @i_prod_bancario           = null,
         --PCOELLO MANEJO DE PROMOCIONES
         @i_monto_promocion         = null,
         @i_saldo_promocion         = null,
         @i_tipo_promocion          = null,
         @i_cuota_promocion         = null,
         --SRO INI Factoring VERSION
         @i_destino_descripcion     = @i_destino_descripcion,        
         @i_expromision             = @i_expromision,
         @i_objeto                  = @i_objeto,
         @i_actividad               = @i_actividad,
         @i_descripcion_oficial     = @i_descripcion_oficial,
         @i_tipo_cartera            = @i_tipo_cartera,
         @i_sector_cli              = @i_sector_cli,
         @i_convenio                = @i_convenio,
         @i_codigo_cliente_empresa  = @i_codigo_cliente_empresa,
         @i_tipo_credito            = null,              
         @i_motivo_uno              = @i_motivo_uno,                 
         @i_motivo_dos              = @i_motivo_dos,                 
         @i_motivo_rechazo          = @i_motivo_rechazo,
         @i_tamanio_empresa         = @i_tamanio_empresa,
         @i_producto_fie            = @i_producto_fie,
         @i_num_viviendas           = @i_num_viviendas,
         @i_reprogramingObserv      = @i_reprogramingObserv,
         @i_sub_actividad           = null,
         @i_departamento            = @i_departamento,
         @i_credito_es              = null,
         @i_financiado              = null,
         @i_presupuesto             = null,
         @i_fecha_avaluo = null,
         @i_valor_comercial         = null,
         --SRO FIN Factoring VERSION
         --INTEGRACION FIE       
         @i_actividad_destino       = @i_actividad_destino,              
         @i_parroquia               = @i_parroquia,                  
         @i_canton                  = @i_canton,
         @i_barrio                  = @i_barrio,
         @i_toperacion_ori          = null,           
         @i_dia_fijo                = @i_dia_fijo,                   
         @i_enterado                = @i_enterado,                  
         @i_otros_ent               = @i_otros_ent,                 
         @i_seguro_basico           = @i_seguro_basico,              
         @i_seguro_voluntario       = @i_seguro_voluntario,          
         @i_tipo_seguro             = @i_tipo_seguro,               
         @o_tramite                 = @w_tramite              out
               
          if @w_error != 0
          begin
            --print '@w_error'+convert(varchar,@w_error)
            goto ERROR
                --rollback tran
            --return 1
          end

   select @w_inst_proceso = 0
   select @w_tipo_cliente = en_subtipo from cobis..cl_ente where en_ente = @i_cliente_cca
   
   select @w_sp_name1 = 'cob_workflow..sp_inicia_proceso_wf'
   
   exec @w_error                    = @w_sp_name1  --cob_workflow..sp_inicia_proceso_wf
         @s_ssn                     = @s_ssn,
         @s_user                    = @i_usuario_tr,--@s_user PMO
         @s_sesn                    = @s_sesn,
         @s_term                    = @s_term,
         @s_date                    = @s_date,
         @s_srv                     = @s_srv,
         @s_lsrv                    = @s_lsrv,
         @s_rol                     = @s_rol,
         @s_ofi                     = @i_oficina_tr, --PQU oficina del trámite @s_ofi,
         @s_culture                 = @s_culture,
         @i_login                   = @i_usuario_tr,
         @i_id_proceso              = @w_codigo_proceso,
         @i_campo_1                 = @i_cliente_cca,
         @i_campo_2                 = @w_num_op_banco,
         @i_campo_3                 = 0,
         @i_id_empresa              = 1,
         @i_campo_4                 = @i_toperacion,
         @i_campo_5                 = 0,
         @i_campo_6                 = 0.0,
         @i_campo_7                 = 'P',
         @i_tipo_cliente            = @w_tipo_cliente,
         @i_ruteo                   = 'M',
         @i_ofi_inicio              = 0,
         @t_trn                     = 73506,
         @i_canal                   = @i_canal,
         @o_siguiente               = @w_inst_proceso out,
         @o_siguiente_alterno       = @w_siguiente_alterno out
         
         if @w_error != 0
          begin
            --print '@w_error'+convert(varchar,@w_error)
            goto ERROR
                --rollback tran
            --return 1
          end
   
   select @w_sp_name1 = 'cob_workflow..sp_m_inst_proceso_wf'
   exec @w_error                    = @w_sp_name1  --cob_workflow..sp_m_inst_proceso_wf
         @s_ssn                     = @s_ssn,
         @s_user                    = @i_usuario_tr,--@s_user PMO
         @s_sesn                    = @s_sesn,
         @s_term                    = @s_term,
         @s_date                    = @s_date,
         @s_srv                     = @s_srv,
         @s_lsrv                    = @s_lsrv,
         @s_rol                     = @s_rol,
         @s_ofi                     = @i_oficina_tr, --PQU oficina del trámite @s_ofi,
         @i_login                   = @i_usuario_tr,--@s_user PMO
         @i_id_inst_proc            = @w_inst_proceso,
         @i_campo_1                 = @i_cliente_cca,
         @i_campo_3                 = @w_tramite,
         @i_id_empresa              = 1,
         @i_campo_4                 = @i_toperacion,
         @i_operacion               = 'U',
         @i_campo_5                 = 0,
         @i_campo_6                 = 0.0,
         @t_trn                     = 73506,
         @o_siguiente               = 0
          
          if @w_error != 0
          begin
            --print '@w_error'+convert(varchar,@w_error)
            goto ERROR
                --rollback tran
            --return 1
          end
          
   if(@w_tipo is not null and (@w_tipo in('R','E','F')))
   begin
       
      select @w_sp_name1 = 'cob_interface..sp_operaciones_renovar_int'
      exec @w_error                    = @w_sp_name1  --cob_interface..sp_operaciones_renovar_int
            @s_ssn                     = @s_ssn,
            @s_user                    = @i_usuario_tr,--@s_user PMO
            @s_sesn                    = @s_sesn,
            @s_term                    = @s_term,       
            @s_date                    = @s_date,
            @s_srv                     = @s_srv,
            @s_lsrv                    = @s_lsrv,
            @s_rol                     = @s_rol,
            @s_ofi                     = @i_oficina_tr, --PQU oficina del trámite @s_ofi,
            @s_org_err                 = @s_org_err,
            @s_error                   = @s_error,
            @s_sev                     = @s_sev,
            @s_msg                     = @s_msg,
            @s_org                     = @s_org,
            @t_rty                     = @t_rty,
            @t_trn                     = 21006,
            @t_debug                   = @t_debug,
            @t_file                    = @t_file,
            @t_from                    = @t_from,
            @t_show_version            = @t_show_version,          
            @s_culture                 = @s_culture,
            @i_operacion               = 'I',
            @i_tramite                 = @w_tramite,
            @i_num_operacion           = @w_num_op_banco,
            @i_producto                = 'CCA',
            @i_abono                   = 0,
            @i_moneda_abono            = 0,
            @i_toperacion              = '',
            @i_moneda_original         = 0,
            @i_capitaliza              = 'N',
            @i_op_base                 = 'S'
          
           if @w_error != 0
          begin
            --print '@w_error'+convert(varchar,@w_error)
            goto ERROR
                --rollback tran
            --return 1
          end
          
   end
          
   select @o_numero_proceso = io_id_inst_proc,
   @o_numero_proceso_largo = io_codigo_alterno, 
   @o_tramite = io_campo_3
   from cob_workflow..wf_inst_proceso
   where io_campo_3 = @w_tramite
   
      
end

if @i_operacion = 'U'
begin
   
   if @i_tramite = 0 or @i_tramite is null
   begin 
      select
      @w_error = 2110179
      ---@w_msg    = 'Debe enviar numero de tramite para Actualizar.'
 
        goto ERROR
   end
   
   select @w_estado = tr_estado from cob_credito..cr_tramite where tr_tramite = @i_tramite
   
   -- DMO Un trámite aprobado no puede ser actualizado 
   if( @w_estado  <> 'N')
   begin
        select
        @w_error = 2110395
        ---@w_msg    = 'Un trámite aprobado no puede ser actualizado.'
 
       goto ERROR
   end 
   
   
     
   if @i_tramite = 0 or @i_tramite is null
   begin 
		select
		@w_return = 2110179
      ---@w_msg    = 'Debe enviar numero de tramite para Actualizar.'
 
		goto ERROR
   end
   
   select @w_estado = tr_estado from cob_credito..cr_tramite where tr_tramite = @i_tramite
   
    -- DMO Un trámite aprobado no puede ser actualizado 
   if( @w_estado  <> 'N')
   begin
		select
		@w_return = 2110395
		---@w_msg    = 'Un trámite aprobado no puede ser actualizado.'
       goto ERROR
   end 
   
   
   --DMO SE VALIDA QUE SE ENCUENRE EN LA ETAPA CORRRECTA DE REGULARIZACION
   select @w_param_regularizar =  pa_char from cobis..cl_parametro with(nolock)
                                  where pa_nemonico = 'PMODFA'
								  
								  
	select @w_actividad =  ia_nombre_act from 
    cob_workflow..wf_inst_proceso with(nolock)
    inner join cob_workflow..wf_inst_actividad with(nolock)  on io_id_inst_proc = ia_id_inst_proc
    inner join cob_workflow..wf_actividad  with(nolock) on ia_codigo_act = ac_codigo_actividad
    where io_campo_3 = @i_tramite
    and ia_estado in ('ACT', 'INA')	  
    
	if( @w_param_regularizar is null or  isnull(@w_param_regularizar, '') != isnull(@w_actividad, ''))
	begin
	    select @w_return = 2110402
		---@w_msg    = 'Solo es posible modificar desde actividad de regularización'
       goto ERROR
	end
   
   select @w_sp_name1 = 'cob_credito..sp_tramite'
   
     exec @w_error                  = @w_sp_name1  --cob_credito..sp_tramite
         @s_ssn                     = @s_ssn,
         @s_user                    = @i_usuario_tr,--@s_user PMO
         @s_sesn                    = @s_sesn,
         @s_term                    = @s_term,
         @s_date                    = @s_date,
         @s_srv                     = @s_srv,
         @s_lsrv                    = @s_lsrv,
         @s_rol                     = @s_rol,
         @s_ofi                     = @i_oficina_tr, --PQU oficina del trámite @s_ofi,
         @s_org_err                 = @s_org_err,
         @s_error                   = @s_error,
         @s_sev                     = @s_sev,
         @s_msg                     = @s_msg,
         @s_org                     = @s_org,
         @t_rty                     = @t_rty,
         @t_trn                     = 21120,
         @t_debug                   = @t_debug,
         @t_file                    = @t_file,
         @t_from                    = @t_from,
         @i_operacion               = @i_operacion,
         @i_tramite                 = @i_tramite,
         @i_tipo                    = @w_tipo,
         @i_oficina_tr              = @i_oficina_tr,
         @i_usuario_tr              = @i_usuario_tr,
         @i_fecha_crea              = @i_fecha_crea,
         @i_oficial                 = @i_oficial,
         --@i_sector                  = @i_sector, DMO SECTOR NO SE PUEDE ACTUALIZAR
         @i_ciudad                  = @i_ciudad,
         @i_estado                  = @i_estado,
         @i_numero_op_banco         = @i_numero_op_banco,
         @i_cuota                   = @i_cuota,
         @i_frec_pago               = @i_frec_pago,
         @i_moneda_solicitada       = @i_moneda_solicitada,
         @i_provincia               = @i_provincia,
         @i_monto_solicitado        = @i_monto_solicitado,
         @i_monto_desembolso        = @i_monto_desembolso,
         @i_pplazo                  = @i_pplazo,
         @i_tplazo                  = @i_tplazo,
         /* campos para tramites de garantias */
         @i_proposito               = @i_proposito,
         @i_razon                   = @i_razon,
         @i_txt_razon               = @i_txt_razon,
         @i_efecto                  = @i_efecto,
         /* campos para lineas de credito */
         --@i_cliente                 = @i_cliente, DMO CLIENTE NO SE PUEDE ACTUALIZAR
         @i_grupo                   = @i_grupo,
         @i_fecha_inicio            = @i_fecha_inicio,
         @i_num_dias                = @i_num_dias,
         @i_per_revision            = @i_per_revision,
         @i_condicion_especial      = @i_condicion_especial,
         @i_rotativa                = null,
         @i_destino_fondos          = null,
         @i_comision_tramite        = null,
         @i_subsidio                = null,
         @i_tasa_aplicar            = null,
         @i_tasa_efectiva           = null,
         @i_plazo_desembolso        = null,
         @i_forma_pago              = null,
         @i_plazo_vigencia          = null,
         @i_formalizacion           = null,
         @i_cuenta_corrientelc      = null,
         /* operaciones originales y renovaciones */
         @i_linea_credito           = @i_linea_credito,
        -- @i_toperacion              = @i_toperacion, DMO TOPERACION NO SE PUEDE ACTUALIZAR
         --@i_producto                = @i_producto, DMO PRODUCTO NO SE PUEDE ACTUALIZAR
         @i_monto                   = @i_monto,
         @i_moneda                  = @i_moneda,
         @i_periodo                 = null,
         @i_num_periodos            = null,
         @i_destino                 = @i_destino,
         @i_ciudad_destino          = @i_ciudad_destino,
         -- solo para prestamos de cartera
         @i_reajustable             = null,
         @i_per_reajuste            = null,
         @i_reajuste_especial       = null,
         @i_fecha_reajuste          = null,
         @i_cuota_completa          = null,
         @i_tipo_cobro              = null,
         @i_tipo_reduccion          = null,
         @i_aceptar_anticipos       = null,
         @i_precancelacion          = null,
         @i_tipo_aplicacion         = null,
         @i_renovable               = null,
         @i_fpago                   = null,
         @i_cuenta                  = null,
         -- generales               
         @i_renovacion              = null,
         @i_cliente_cca             = @i_cliente_cca,
         @i_op_renovada             = @i_op_renovada,
         @i_deudor                  = @i_deudor,
         -- reestructuracion
         @i_op_reestructurar        = @i_op_reestructurar,
         @i_sector_contable         = null,
         @i_origen_fondo            = @i_origen_fondo,
         @i_fondos_propios          = null,
         @i_plazo                   = @i_plazo,
         -- Financiamientos
         @i_revolvente              = @i_revolvente,
         @i_trm_tmp                 = null,
         @i_her_ssn                 = null,
         @i_causa                   = null,
         @i_contabiliza             = null,
         @i_tvisa                   = null,
         @i_migrada                 = null,
         @i_tipo_linea              = @i_tipo_linea,
         @i_plazo_dias_pago         = null,
         @i_tipo_prioridad          = null,
         @i_linea_credito_pas       = null,
         --Vivi
         @i_proposito_op            = null,
         @i_linea_cancelar          = null,
         @i_fecha_irenova           = null,
         @i_subtipo                 = @i_subtipo,                   
         @i_tipo_tarjeta            = null,               
         @i_motivo                  = null,                    
         @i_plazo_pro               = null,                  
         @i_fecha_valor             = null,                
         @i_estado_lin              = null,                 
         @i_tasa_asociada           = null,
         @i_tpreferencial           = null,
         @i_porcentaje_preferencial = null,
         @i_monto_preferencial      = null,
         @i_abono_ini               = null,
         @i_opcion_compra           = null,
         @i_beneficiario            = null,
         @i_financia                = null,
         @i_ult_tramite             = null,              
         @i_empleado                = null,                  
         @i_ssn                     = @i_ssn,
         @i_nombre_empleado         = null,
         @i_canal                   = @i_canal,
         @i_promotor                = null,
         @i_comision_pro            = null,
         @i_iniciador               = null,
         @i_entrevistador           = null,
         @i_vendedor                = null,
         @i_cuenta_vende            = null,
         @i_agencia_venta           = null,
         @i_aut_valor_aut           = null,
         @i_aut_abono_aut           = null,
         @i_canal_venta             = null,
         @i_referido                = null,
         @i_FIniciacion             = null,
         --Prestamos Gemelos
         @i_gemelo                  = null,
         @i_tasa_prest_orig         = null,
         @i_banco_padre             = null,
         @i_num_cuenta              = null,
         @i_prod_bancario           = null,
         --PCOELLO MANEJO DE PROMOCIONES
         @i_monto_promocion         = null,
         @i_saldo_promocion         = null,
         @i_tipo_promocion          = null,
         @i_cuota_promocion         = null,
         --SRO INI Factoring VERSION
         @i_destino_descripcion     = @i_destino_descripcion,       
         @i_expromision             = @i_expromision,
         @i_objeto     = @i_objeto,
         @i_actividad               = @i_actividad,
         @i_descripcion_oficial     = @i_descripcion_oficial,
         @i_tipo_cartera            = @i_tipo_cartera,
         @i_sector_cli              = @i_sector_cli,
         @i_convenio                = @i_convenio,
         @i_codigo_cliente_empresa  = @i_codigo_cliente_empresa,
         @i_tipo_credito            = null,              
         @i_motivo_uno              = @i_motivo_uno,                 
         @i_motivo_dos              = @i_motivo_dos,                 
         @i_motivo_rechazo          = @i_motivo_rechazo,
         @i_tamanio_empresa         = @i_tamanio_empresa,
         @i_producto_fie            = @i_producto_fie,
         @i_num_viviendas           = @i_num_viviendas,
         @i_reprogramingObserv      = @i_reprogramingObserv,
         @i_sub_actividad           = null,
         @i_departamento            = @i_departamento,
         @i_credito_es              = null,
         @i_financiado              = null,
         @i_presupuesto             = null,
         @i_fecha_avaluo            = null,
         @i_valor_comercial         = null,
         --SRO FIN Factoring VERSION
         --INTEGRACION FIE       
         @i_actividad_destino       = @i_actividad_destino,            
         @i_parroquia               = @i_parroquia,                 
         @i_canton                  = @i_canton,
         @i_barrio                  = @i_barrio,
         @i_toperacion_ori          = null,             
         @i_dia_fijo                = @i_dia_fijo,                   
         @i_enterado                = @i_enterado,  
         @i_otros_ent               = @i_otros_ent,                  
         @i_seguro_basico           = @i_seguro_basico,             
         @i_seguro_voluntario       = @i_seguro_voluntario,       
         @i_tipo_seguro             = @i_tipo_seguro,                
         @o_tramite                 = @o_tramite              out
               
       if @w_error != 0
          begin
            --print '@w_error'+convert(varchar,@w_error)
                --rollback tran
            goto ERROR
          end
         
          select @o_numero_proceso = io_id_inst_proc,
            @o_numero_proceso_largo = io_codigo_alterno, 
            @o_tramite = io_campo_3
            from cob_workflow..wf_inst_proceso
            where io_campo_3 = @i_tramite
          
      
end


return 0

ERROR:
   --Devolver mensaje de Error
   if @i_canal in (0,1,3) --Frontend o batch o servicio rest
     begin
      exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name1,
         @i_num   = @w_error
      return @w_error
     end
    else
      return @w_error
GO
