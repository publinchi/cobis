/************************************************************************/
/*   Archivo:             amglinea.sp                                   */
/*   Stored procedure:    sp_abonomas_linea                             */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez Burbano                         */
/*   Fecha de escritura:  Febrero-2007                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Cargar Informacion de Pagos Masivos Generales  enviados desde      */
/*   front-end                                                          */
/************************************************************************/
/*                             ACTUALIZACIONES                          */
/*                                                                      */
/*     FECHA              AUTOR            CAMBIO                       */
/*    20/10/2021       G. Fernandez      Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_abonomas_linea')
   drop proc sp_abonomas_linea
go
---INC.112973 JUN.18.201
create proc sp_abonomas_linea
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_ofi               smallint     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               smallint    = null,
   @i_operacion         char(1)     = null,
   @i_lote              int         = null,
   @i_banco             cuenta      = null,
   @i_fecha_pago        datetime    = null,
   @i_forma_pago        varchar(10) = null,
   @i_tipo_aplicacion   varchar(10) = null,
   @i_tipo_reduccion    varchar(10) = null,
   @i_monto             money       = null,
   @i_concepto          varchar(10) = null,
   @i_oficina           int         = null,
   @i_cuenta            cuenta      = null,
   @i_moneda            smallint    = 0,
   @i_ced_ruc           cuenta      = null,
   @i_oficina_desc      varchar(20) = null,
   @i_nacional_local    varchar(10) = null,
   @i_region            varchar(10) = null,
   @i_autorizacion      varchar(10) = null,
   @i_cod_banco         varchar(10) = null,   
   @i_fecha_proceso     datetime    = null,
   @i_comision_banco    money       = 0,
   @i_comision_canal    money       = 0, 
   @i_iva_comision      money       = 0
as declare
   @w_sp_name                  varchar(32),
   @w_return                   int,
   @w_error                    int,
   @w_operacionca              int,
   @w_secuencial_ing           int,
   @w_lote                     int,
   @w_forma_pago               varchar(10),
   @w_concepto                 varchar(10),
   @w_descripcion              varchar(255),
   @w_fecha_cargue             datetime,
   @w_fecha_pago               datetime,
   @w_estado                   char(1),
   @w_oficina                  int,
   @w_moneda                   int,
   @w_moneda_nacional          int,   
   @w_fpago_ndcc               catalogo,
   @w_fpago_ndaho              catalogo,
   @w_saldo_disponible         money,
   @w_estado_op                smallint,
   @w_msg                      varchar(134),
   @w_anexo                    varchar(255),
   @w_rowcount                 int,
   @w_cargados                 int,
   @w_crea_pagos               char(1),
   @w_numero_recibo            int,
   @w_cot_moneda               float,
   @w_monto_mop                money,
   @w_parametro_control        catalogo,
   @w_dias_retencion           smallint,
   @w_ab_dias_retencion        smallint,
   @w_fecha_proc_op            smalldatetime,
   @w_cuota_completa           char(1),
   @w_aceptar_anticipos        char(1),
   @w_monto_mn                 money,
   @w_cotizacion_hoy           float,
   @w_op_tipo                  catalogo,
   @w_secuencial               int,
   @w_fecha_proceso            smalldatetime,
   @w_tipo_cobro               catalogo,
   @w_prepago_desde_lavigente  char(1),
   @w_beneficiario             varchar(50),
   @w_saldo_exigible           money,
   @w_est_vigente              tinyint,
   @w_est_vencido              tinyint,
   @w_est_novigente            tinyint,
   @w_est_cancelado            tinyint,
   @w_est_credito              tinyint,
   @w_est_suspenso             tinyint,
   @w_est_castigado            tinyint,
   @w_est_anulado              tinyint,
   @w_porcentaje_iva           float,
   @w_dias_fecha_val           tinyint,
   @w_fecha_migracion          datetime,
   @w_num_dec_op               tinyint,
   @w_decimales_pago           float,
   @w_num_dec_n                money,
   @w_fecha_inicio             datetime,
   @w_pago_funcionario         catalogo,
   @w_pago_piat                catalogo,
   @w_pago_picr                catalogo,
   @w_cod_gar_fag	           varchar(10), --REQ 00212 PEQUEÑA EMPRESA
   @w_tipo_gar_act             varchar(10), --REQ 00212 PEQUEÑA EMPRESA
   @w_tramite		           int,	    --REQ 00212 PEQUEÑA EMPRESA
   @w_estado_cobranza          varchar(2)   --REQ 00212 PEQUEÑA EMPRESA


select @w_sp_name            = 'sp_abonomas_linea'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_credito    = @w_est_credito   out

--  VALIDACION EN CATALOGOS E INSERCION EN TABLA TEMPORAL

select @w_fecha_cargue = getdate()
select @w_fecha_pago   = convert(char(10),@i_fecha_pago,101)

select 
@w_error = 0, 
@w_cargados = 0,
@w_crea_pagos = 'N',
@w_operacionca  = 0,
@w_ab_dias_retencion = 0

-- Pagos Nomina
select @w_pago_funcionario = pa_char
from cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'PGNO'
set transaction isolation level read uncommitted

select @w_pago_piat = pa_char
from cobis..cl_parametro
where pa_nemonico = 'PIAT'
and   pa_producto = 'CCA'

select @w_pago_picr = pa_char
from cobis..cl_parametro
where pa_nemonico = 'PICR'
and   pa_producto = 'CCA'
       
--MONEDA LEGAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

--PARAMETRO IVA
select @w_porcentaje_iva = pa_float
from   cobis..cl_parametro
where  pa_producto = 'CTE'
and    pa_nemonico = 'PIVA'
set transaction isolation level read uncommitted

--PARAMETRO DIAS FECHA VALOR
select @w_dias_fecha_val = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DFVR'
set transaction isolation level read uncommitted

--LA FECHA DE INGRESO DEL PAGO DEBE SER LA FECHA DEL PRODUCTO DE CARTERA
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

--OBTENER CODIGO GARANTIA FAG REQ 00212 PEQUEÑA EMPRESA 

select @w_cod_gar_fag = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and pa_nemonico = 'CODFAG'

select tc_tipo as tipo 
into #calfag
from cob_custodia..cu_tipo_custodia
where tc_tipo_superior = @w_cod_gar_fag

select @w_cod_gar_fag = tipo
from #calfag 

-- Validar Cliente Operacion
if @i_ced_ruc is not null and @i_banco is not null and @i_banco <> '0' begin
   if not exists (select 1 from cobis..cl_ente, cob_cartera..ca_operacion
                  where op_cliente = en_ente
                  and   en_ced_ruc = @i_ced_ruc
                 )
   begin
   select @w_error =  708170
   goto ERROR
   end
end

-- Validar Estado Activo de la operacion
if @i_banco is not null and @i_banco <> '0' begin
   if not exists (select 1 from cob_cartera..ca_operacion
                  where op_banco = @i_banco
                  and   op_estado in (@w_est_vigente,   @w_est_vencido, 
                                     @w_est_castigado, @w_est_suspenso)
                 )
   begin
   select @w_error =  710025
   goto ERROR
   end
end

-- Validacion datos operacion --  Cuando se recibe solo identifiación
if @i_ced_ruc is not null and (@i_banco is null or @i_banco = '0') begin

   -- Validar Nro. de Operaciones del Cliente
   select @w_cargados = count(1) 
   from ca_operacion, cobis..cl_ente
   where op_cliente = en_ente
   and   op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_credito)
   and   en_ced_ruc = @i_ced_ruc
   
   if @w_cargados = 0 begin
      select @w_error =  711074
      goto ERROR
   end
   
   -- Si tiene una sola operacion            
   if @w_cargados = 1  
      select 
      @i_banco           = op_banco
      from ca_operacion, cobis..cl_ente
      where op_cliente = en_ente
      and   op_estado not in (@w_est_novigente,@w_est_cancelado,@w_est_anulado,@w_est_credito)
      and   en_ced_ruc = @i_ced_ruc
      
   -- Seleccionar la mas vencida o proxima a vencer
   else begin 

      select 
      operacion = di_operacion, 
      banco     = op_banco,
      dias_mora = datediff(dd, min(di_fecha_ven), @w_fecha_proceso)
      into #dias_mora
      from ca_dividendo, ca_operacion, cobis..cl_ente
      where di_estado    in (@w_est_vigente, @w_est_vencido)
      and   di_operacion = op_operacion
      and   op_cliente   = en_ente
      and   en_ced_ruc   = @i_ced_ruc
      group by di_operacion, op_banco
      order by abs(datediff(dd, min(di_fecha_ven), @w_fecha_proceso)) DESC
      
      set rowcount 1
      select @i_banco = banco, @w_saldo_exigible = sum(am_cuota - am_pagado) -- Cobro es proyectado
      from  #dias_mora, ca_amortizacion, ca_dividendo
      where operacion  = am_operacion
      and am_operacion = di_operacion
      and am_dividendo = di_dividendo
      and di_estado    in (@w_est_vigente, @w_est_vencido)
      group by banco
      set rowcount 0
      
      if @w_saldo_exigible < @i_monto begin -- No aplica si existe sobrante
         select @w_error =  711073
         goto ERROR
      end
   end

   if @w_error = 0 select @w_crea_pagos   = 'S'	
end

-- VALIDA QUE LA FORMA DE PAGO SEA PAGO DE NOMINA

if (@i_forma_pago = @w_pago_funcionario or @i_forma_pago = @w_pago_piat or @i_forma_pago = @w_pago_picr) and  @i_comision_banco = 1
   select @i_comision_banco  = 0
else
   if @i_banco is not null and @i_banco <> '0'
      select @i_tipo_aplicacion = op_tipo_aplicacion,
             @i_tipo_reduccion  = op_tipo_reduccion
      from   ca_operacion
      where  op_banco = @i_banco
       

if @i_banco is not null and @i_banco <> '0' begin
   select @w_beneficiario = 'Lote:' + rtrim(@i_lote),
          @w_operacionca               = op_operacion,
          @w_moneda                    = op_moneda,
          @w_estado_op                 = op_estado, 
          @w_tipo_cobro                = op_tipo_cobro,
          @i_oficina                   = op_oficina,
          @i_cuenta                    = isnull(@i_cuenta,op_cuenta),
          @w_cuota_completa            = op_cuota_completa,
          @w_aceptar_anticipos         = op_aceptar_anticipos,
          @w_prepago_desde_lavigente   = op_prepago_desde_lavigente,
          @w_fecha_proc_op             = op_fecha_ult_proceso,
          @w_op_tipo                   = op_tipo,
          @w_fecha_inicio              = op_fecha_liq,
          @w_tramite				   = op_tramite,
          @w_estado_cobranza           = op_estado_cobranza
   from   ca_operacion
   where  op_banco = @i_banco
   
   if @@rowcount = 0 begin
      select @w_error =  710025
      goto ERROR
   end else
      select @w_crea_pagos   = 'S'
end


         
select @w_secuencial_ing = 0
exec @w_secuencial_ing = sp_gen_sec
     @i_operacion  = @w_operacionca

select @w_forma_pago = cp_producto
from   ca_producto
where  cp_producto = @i_forma_pago

if @@rowcount = 0 begin
   select @w_error =  710416
   goto ERROR
end

--RESTRICCION PAGO A CREDITOS CON GARANTIA FAG Y EN COBRO JURIDICO REQ0212 PEQUEÑA EMPRESA
select @w_tipo_gar_act = cu_tipo 
from cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia
where gp_tramite = @w_tramite
and   gp_garantia = cu_codigo_externo
and   cu_tipo in (select tipo from #calfag)

if @w_tipo_gar_act = @w_cod_gar_fag and @w_estado_cobranza = 'CJ'
begin
    select @w_error = 724132
   goto ERROR
end

---VALIDACION DE EL ESTADO ACTUAL DE LA  OPERACION
if  @w_estado_op in (@w_est_anulado,@w_est_novigente,@w_est_cancelado) begin
    select @w_error =  708158
    goto ERROR
end
    
select @w_oficina = of_oficina
from   cobis..cl_oficina
where  of_oficina = @i_oficina
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error =  141035
   goto ERROR
end

if @i_tipo_aplicacion <> 'C'  and  @i_tipo_aplicacion <> 'D'  and  @i_tipo_aplicacion <> 'P' begin
   select @w_error =  710417
   goto ERROR
end

if @i_tipo_reduccion <> 'N'  and @i_tipo_reduccion <> 'T'  and @i_tipo_reduccion <> 'C' begin
   select @w_error =  710418
   goto ERROR
end

if @i_tipo_aplicacion = 'P' and @i_concepto is not null begin
   select @w_concepto = ro_concepto
   from   ca_rubro_op
   where  ro_operacion = @w_operacionca
   and    ro_concepto  = @i_concepto
   
   if @@rowcount = 0 begin
      select @w_error =  710419
      goto ERROR
   end
end

if @i_tipo_aplicacion = 'P' and @i_concepto is null begin
   select @w_error =  710420
   goto ERROR
end

if @i_monto <= 0 begin
   select @w_error =  710129
   goto ERROR
end

-- Validacion de valor de IvaComision cuando se recibe Comision
if abs((((@i_comision_banco + @i_comision_canal) * @w_porcentaje_iva) / 100) - @i_iva_comision) > 2 begin
   select @w_error = 724509
   goto ERROR
end

select @w_fecha_migracion = '01/01/1900'
select @w_fecha_migracion = tr_fecha_ref
from ca_transaccion
where tr_operacion = @w_operacionca
and   tr_tran = 'MIG'

if @w_fecha_pago < @w_fecha_migracion begin   
   if @@rowcount = 0 begin
      select @w_error =  724519
      goto ERROR
   end
end

if @w_fecha_pago < @w_fecha_inicio begin   
   if @@rowcount = 0 begin
      select @w_error =  724528
      goto ERROR
   end
end

-- Validacion pago en fecha posterior a la de proceso del modulo o inferior a N dias
if datediff(dd, @w_fecha_proceso , @w_fecha_pago) < (@w_dias_fecha_val * -1) or 
   datediff(dd, @w_fecha_proceso , @w_fecha_pago) > 0 begin
   select @w_error = 724517
   goto ERROR
end

--VALIDACION DE DECIMALES PARA LA MONEDA DE LA OPERACION
--SI LA MONEDA NACIONAL NO ACEPTA DECIMALES, NO SE RECIBEN PAGOS
--CON DECIMALES
exec sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec_op out,
@o_dec_nacional = @w_num_dec_n  out

select @w_decimales_pago  = @i_monto  - floor(@i_monto)

if @w_decimales_pago > 0 and @w_num_dec_n = 0 begin
   select @w_error = 710468 -- La moneda nacional no tiene decimales   
   goto ERROR
end

if @w_crea_pagos = 'S' begin

   EXEC @w_return = sp_validar_fecha
   @s_user                  = @s_user,
   @s_term                  = @s_term,
   @s_date                  = @s_date ,
   @s_ofi                   = @s_ofi,
   @i_operacionca           = @w_operacionca,
   @i_debug                 = 'N' 

   if @w_return <> 0 
   begin
      select @w_error = @w_return 
      goto ERROR
   end
   
   exec @w_secuencial = sp_gen_sec
   @i_operacion  = @w_operacionca

   exec @w_return = sp_numero_recibo
   @i_tipo    = 'P',
   @i_oficina = @s_ofi,
   @o_numero  = @w_numero_recibo out
      
   if @w_return <> 0 begin
      select @w_error =  @w_return
      goto ERROR
   end
                  
   if @w_moneda  =   @w_moneda_nacional  begin -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
      select @w_cotizacion_hoy = 1.0
      select @w_monto_mop = @i_monto,
             @w_monto_mn  = @i_monto
   end   
   ELSE begin
      exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda,
      @i_fecha      = @w_fecha_proc_op,
      @o_cotizacion = @w_cotizacion_hoy output

      select @w_monto_mop = ceiling(@i_monto*10000.0 / @w_cotizacion_hoy)/10000.0
   end
        
   if @i_forma_pago = 'ICR'
      select @i_tipo_aplicacion = 'A'
   
   -- INICIO 
   If exists (select 1 from ca_traslado_interes
              where ti_operacion = @w_operacionca
              and  ti_estado     = 'P')
      select @i_tipo_aplicacion = 'A'
   
   select @w_parametro_control =  pa_char 
   from   cobis..cl_parametro
   where  pa_nemonico = 'FPCHLO'
   and    pa_producto = 'CCA'
   set transaction isolation level read uncommitted
   
   if @w_op_tipo = 'O' and @w_forma_pago =  @w_parametro_control begin
      select @w_dias_retencion =  pa_smallint
      from   cobis..cl_parametro
      where  pa_nemonico = 'DCHLO'
      and    pa_producto = 'CCA'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted
      
      if @w_rowcount = 0 begin
         select  @w_dias_retencion = 0
         goto ERROR
      end
      
      select    @w_ab_dias_retencion  = isnull(@w_dias_retencion,0)
   end         
   
   -- INSERTAR EN ABONO

   BEGIN TRAN         

      insert into ca_abono
      (ab_secuencial_ing,     ab_secuencial_rpa,           ab_secuencial_pag,            
       ab_operacion,          ab_fecha_ing,                ab_fecha_pag,           
       ab_cuota_completa,     ab_aceptar_anticipos,        ab_tipo_reduccion,  
       ab_tipo_cobro,         ab_dias_retencion_ini,       ab_dias_retencion,
       ab_estado,             ab_usuario,                  ab_oficina,                   
       ab_terminal,           ab_tipo,                     ab_tipo_aplicacion,     
       ab_nro_recibo,         ab_tasa_prepago,             ab_dividendo,       
       ab_calcula_devolucion, ab_prepago_desde_lavigente)
      values(
       @w_secuencial,         0,                           0,                            
       @w_operacionca,        @w_fecha_proceso,            @w_fecha_pago,              
       @w_cuota_completa,     @w_aceptar_anticipos,        @i_tipo_reduccion,      
       @w_tipo_cobro,         @w_ab_dias_retencion,        @w_ab_dias_retencion,
       'ING',                 @s_user,                     @s_ofi,                   
       @s_term,               'PAG',                       @i_tipo_aplicacion,         
       @w_numero_recibo,      0.00,                        0,                      
       'N',                   @w_prepago_desde_lavigente)

      if @@rowcount = 0 begin
         select @w_error = 710232
         goto ERROR
      end
      
      -- INSERTAR EN ca_abono_det
      if @i_cuenta is null
         select @i_cuenta = ''
      if @t_debug='S'
         print 'Insertando en ca_abono_det'
     
      select @i_monto  = @i_monto + @i_comision_banco + @i_comision_canal + @i_iva_comision
      select @w_monto_mop = @i_monto, @w_monto_mn = @i_monto

      insert into ca_abono_det
      (abd_secuencial_ing,    abd_operacion,         abd_tipo,            
       abd_concepto ,         abd_cuenta,            abd_beneficiario,    
       abd_moneda,            abd_monto_mpg,         abd_monto_mop,         
       abd_monto_mn,          abd_cotizacion_mpg,    abd_cotizacion_mop,
       abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,          
       abd_cod_banco,         abd_inscripcion,       abd_carga,
	   abd_solidario)                                                       --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
      values(                                        
       @w_secuencial,         @w_operacionca,        'PAG',               
       @i_forma_pago,         isnull(@i_cuenta,'0'), @w_beneficiario,     
       @i_moneda,             @i_monto,              @w_monto_mop,          
       @w_monto_mn,           @w_cotizacion_hoy,     @w_cotizacion_hoy,
       'C',                    'C',                  null,                
       null,                  null,                  null,
	   'N')

      if @@rowcount = 0 begin
         select @w_error = 710233
         goto ERROR
      end
      
      -- Valores de Comisiones por recaudo
     
      if @i_comision_canal > 0 or @i_comision_banco > 0 or @i_iva_comision > 0 begin
         insert into ca_comision_recaudo
         values (@w_secuencial, @w_operacionca, @i_comision_banco, @i_comision_canal, @i_iva_comision)
         if @@rowcount = 0 begin
            select @w_error = 724508
            goto ERROR
         end
      end 
      
      if @i_concepto is not null begin
         insert into ca_abono_prioridad
         (ap_secuencial_ing, ap_operacion, ap_concepto, ap_prioridad)
         select @w_secuencial, @w_operacionca, ro_concepto, ro_prioridad
         from   ca_rubro_op
         where  ro_operacion = @w_operacionca
         and    ro_fpago not in ('L','B')
         
         if @@rowcount = 0 begin
            select @w_error = 710234
            goto ERROR
         end

         update ca_abono_prioridad
         set ap_prioridad = 0
         where ap_operacion      = @w_operacionca
         and   ap_secuencial_ing = @w_secuencial
         and  (ap_concepto       = @i_concepto or @i_concepto is null)
         
         if @@rowcount = 0 begin
            select @w_error = 710234
            goto ERROR
         end
         
      end

   COMMIT TRAN
end

ERROR:
if @w_error > 0 begin
   select @w_descripcion = mensaje + ' - ' + @w_beneficiario
   from cobis..cl_errores
   where numero = @w_error  
   
   select @w_secuencial_ing = 0
   select @w_anexo =  'SP --> sp_abonomas_linea ' + '' +  'LOTE NRO. ' + '' + convert(varchar(12),@i_lote) 
   
   insert into ca_errorlog
         (er_fecha_proc,      er_error,                        er_usuario,
          er_tran,            er_cuenta,                       er_descripcion,
          er_anexo)
   values(@w_fecha_cargue,    @w_error,                        @s_user,
          7269,               isnull(@i_banco,@i_ced_ruc),     @w_descripcion,
          @w_anexo
          ) 
end       
if @i_banco = '0' select @i_banco = null
insert into ca_abonos_masivos_generales
      (mg_lote,               mg_fecha_cargue,                 mg_nro_credito,
       mg_operacion,                                           
       mg_fecha_pago,         mg_forma_pago,                   mg_tipo_aplicacion,
       mg_tipo_reduccion,     mg_monto_pago,                   mg_prioridad_concepto,
       mg_oficina,            mg_fecha_proceso,                mg_estado,
       mg_cuenta,             mg_nro_control,                  mg_tipo_trn,
       mg_posicion_error,     mg_codigo_error,                 mg_descripcion_error,
       mg_secuencial_ing,     mg_moneda,                       mg_terminal,
       mg_usuario)
values(@i_lote,               @w_fecha_cargue,                 isnull(@i_banco,@i_ced_ruc) ,
       @w_operacionca,                                         
       @w_fecha_pago,         @i_forma_pago,                   @i_tipo_aplicacion,
       @i_tipo_reduccion,     @i_monto,                        @i_concepto,
       @i_oficina,            @i_fecha_proceso,                'I',
       @i_cuenta,             0,                               0,
       0,                     @w_error,                        @w_descripcion,
       @w_secuencial_ing,     @i_moneda,                       @s_term,
       @s_user)

return 0

go


