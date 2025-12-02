/************************************************************************/
/*   Archivo:             abmagene.sp                                   */
/*   Stored procedure:    sp_abonos_masivos_generales                   */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Julio Cesar Quintero                          */
/*   Fecha de escritura:  Febrero-2003                                  */
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
/*   Cargar Informacion de Pagos Masivos Generales  a temporales        */
/*      Ubicar los datos en las tablas definitivas en estado ING        */
/*      LAS OPERACIONES MANEJADAS SON:                                  */
/*      'T'     Valida los datos de Tipo Catalogo antes de insertar en  */
/*              la Tabla Temporal  Inserta en                           */
/*              la Tabla Temporal (ca_abonos_masivos_generales)         */
/*      'S'     Genera Numero de Lote                                   */
/*      'Q'     Consulta Registros con Errores en el Cargue             */
/*                                                                      */
/************************************************************************/
/*                             ACTUALIZACIONES                          */
/*                                                                      */
/*     FECHA              AUTOR            CAMBIO                       */
/*    20/10/2021       G. Fernandez      Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/

use cob_cartera
go
  
if exists (select 1 from sysobjects where name = 'sp_abonos_masivos_generales')
   drop proc sp_abonos_masivos_generales
go

create proc sp_abonos_masivos_generales
   @s_ssn               int          = null,
   @s_date              datetime     = null,
   @s_user              login        = null,
   @s_term              descripcion  = null,
   @s_ofi               smallint     = null,
   @t_debug             char(1)      = 'N',
   @t_file              varchar(14)  = null,
   @t_trn               smallint     = null,
   @i_operacion         char(1)      = null,
   @i_lote              int          = null,
   @i_banco             cuenta       = null,
   @i_fecha_pago        datetime     = null,
   @i_forma_pago        varchar(10)  = null,
   @i_tipo_aplicacion   varchar(10)  = null,
   @i_tipo_reduccion    varchar(10)  = null,
   @i_monto             money        = null,
   @i_concepto          varchar(10)  = null,
   @i_oficina           int          = null,
   @i_secuencial        int          = null,
   @i_cuenta            cuenta       = null,
   @i_moneda            smallint     = 0,
   @i_nro_control       int          = null,
   @i_tipo_trn          smallint     = null,
   @i_posicion_error    int          = null,
   @i_codigo_error      int          = null,
   @i_descripcion_error varchar(255) = null,
   @i_secuencial_ing    int          = null,
   @i_valor_recaudo     money        = null,
   @i_valor_iva_recaudo money        = null,
   @i_ced_ruc           cuenta       = null,
   @i_oficina_desc      varchar(20)  = null,
   @i_nacional_local    varchar(10)  = null,
   @i_region            varchar(10)  = null,
   @i_autorizacion      varchar(10)  = null,
   @i_cod_banco         varchar(10)  = null,
   @i_siguiente         varchar(255) = '',
   @i_comision_banco    money        = 0,
   @i_comision_canal    money        = 0,
   @i_iva_comision      money        = 0,      
   @o_lote_gen          int          = null out
as
declare
   @w_sp_name                  varchar(32),
   @w_return                   int,
   @w_error                    int,
   @w_operacionca              int,
   @w_secuencial               int,
   @w_lote                     int,
   @w_forma_pago               varchar(10),
   @w_concepto                 varchar(10),
   @w_prioridad_concepto       varchar(10),
   @w_descripcion              varchar(255),
   @w_fecha_cargue             datetime,
   @w_fecha_pago               datetime,
   @w_estado                   char(1),
   @w_cuota_completa           char(1),
   @w_aceptar_anticipos        char(1),
   @w_tipo_cobro               char(1),
   @w_oficina                  int,
   @w_moneda                   int,
   @w_numero_recibo            int,
   @w_moneda_nacional          tinyint,
   @w_monto_mn                 money,
   @w_monto_mop                money,
   @w_cot_moneda               float,
   @w_cotizacion_hoy           float,
   @w_prioridad                int,
   @w_cuenta                   varchar(24),
   @w_moneda_op                tinyint,
   @w_pcobis                   tinyint,
   @w_monto_mpg                money,
   @w_cotizacion_mpg           float,
   @w_tcot_moneda              char(1),
   @w_tcotizacion_mpg          char(1),
   @w_validacion_campos        char(1),
   @w_posicion                 int,
   @w_tabla_pagos_pit          varchar(30),
   @w_base_datos               varchar(30),
   @w_dato_llave1              varchar(50),
   @w_dato_llave2              varchar(50),
   @w_cliente                  int,
   @w_fpago_ndcc               catalogo,
   @w_fpago_ndaho              catalogo,
   @w_fecha_proceso            datetime,
   @w_prepago_desde_lavigente  char(1),
   @w_reg_errores              int,
   @w_op_fecha_ult_proceso     datetime,
   @w_decimales_pago           float,
   @w_moneda_mn                smallint,
   @w_num_dec_op               int,
   @w_num_dec_n                smallint,
   @w_saldo_disponible         money,
   @w_estado_op                smallint,
   @w_ab_dias_retencion        smallint,
   @w_dias_retencion           smallint,
   @w_op_tipo                  char(1),
   @w_parametro_control        catalogo,
   @w_trancount                int,
   @w_msg                      varchar(134),
   @w_op_banco                 cuenta,
   @w_op_oficina               int,
   @w_estado_mg                char(1),
   @w_procesar                 char(1),
   @w_op_moneda                smallint,
   @w_cargados                 int,
   @w_rowcount                 int,
   @w_min_dividendo            smallint,
   @w_existe                   int

select @w_trancount = @@trancount

-- ELIMINAR CUALQUIER POSIBLE TRANSACCION PENDIENTE
select @w_sp_name     = 'sp_abonos_masivos_generales',
@w_validacion_campos  = 'N',
@w_tabla_pagos_pit    = 'ca_abonos_masivos_generales',
@w_base_datos         = 'cob_cartera',
@w_descripcion        = @i_descripcion_error,
@w_saldo_disponible   = 0,
@w_ab_dias_retencion  = 0,
@w_procesar           = 'S'

if @i_tipo_trn is null or @i_tipo_trn = 0
   select @i_tipo_trn    = 7002   --PAGOS DE CARTERA

--LA FECHA DE INGRESO DEL PAGO DEBE SER LA FECHA DEL PRODUCTO DE CARTERA
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

--MONEDA LEGAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

if @t_debug = 'S'
   PRINT ' Probando abmagene.sp ' + ' Operacion:  ' + cast(@i_operacion as varchar)
-- GENERACION DEL NUMERO DE LOTE - SECUENCIAL

if @i_operacion = 'S' begin
   BEGIN TRAN
   exec @w_lote = sp_gen_sec 
        @i_operacion  = -2
   
   select @o_lote_gen = @w_lote
   select @o_lote_gen
   while @@trancount > @w_trancount COMMIT
end -- Generacion Numero de Lote

if @i_operacion = 'L' begin
   BEGIN TRAN
   exec @w_lote = sp_gen_sec 
        @i_operacion  = -2
   
   select @o_lote_gen = @w_lote
   
   COMMIT TRAN
end -- Generacion Numero de Lote

--VALIDACION EN CATALOGOS E INSERCION EN TABLA TEMPORAL

if @s_term <> 'PIT' and @i_operacion = 'I' begin
   select @w_cargados = isnull(count(1),0)
   from ca_abonos_masivos_generales
   where mg_lote = @i_lote
   and   mg_codigo_error = 0
   and mg_secuencial_ing > 0
   
   PRINT 'Carga exitosa para el lote --> '+CAST(@i_lote AS VARCHAR)+' registrados  '+CAST(@w_cargados AS VARCHAR)+ '  Pagos en ING '   
end

if @i_operacion = 'T' begin
   
   if @s_term <> 'PIT' begin --Enviado desde front-end

      exec @w_error =  sp_abonomas_linea
      @s_ssn               = @s_ssn,
      @s_date              = @s_date,
      @s_user              = @s_user,
      @s_term              = @s_term,
      @s_ofi               = @s_ofi,
      @t_debug             = @t_debug,
      @t_file              = @t_file,
      @t_trn               = @t_trn,
      @i_operacion         = @i_operacion,
      @i_lote              = @i_lote,
      @i_banco             = @i_banco,
      @i_fecha_pago        = @i_fecha_pago,
      @i_forma_pago        = @i_forma_pago,
      @i_tipo_aplicacion   = @i_tipo_aplicacion,
      @i_tipo_reduccion    = @i_tipo_reduccion,
      @i_monto             = @i_monto,
      @i_concepto          = @i_concepto,
      @i_oficina           = @i_oficina,
      @i_cuenta            = @i_cuenta,
      @i_moneda            = @i_moneda,
      @i_ced_ruc           = @i_ced_ruc,
      @i_oficina_desc      = @i_oficina_desc,
      @i_nacional_local    = @i_nacional_local,
      @i_region            = @i_region,
      @i_autorizacion      = @i_autorizacion,
      @i_cod_banco         = @i_cod_banco,  
      @i_fecha_proceso     = @w_fecha_proceso,
      @i_comision_banco    = @i_comision_banco,
      @i_comision_canal    = @i_comision_canal,
      @i_iva_comision      = @i_iva_comision
      
      if @w_error != 0
         goto ERROR      
      return 0
   end
   
   select @w_fecha_cargue = getdate()
   select @w_fecha_pago   = convert(char(10),@i_fecha_pago,101)
   
   select @w_error = 0,
   @w_descripcion  = '',
   @w_operacionca  = 0,
   @w_posicion     = 0
   
   select @w_operacionca  = op_operacion,
   @w_cliente           = op_cliente,
   @w_moneda            = op_moneda,
   @w_op_oficina        = op_oficina,
   @w_estado_op         = op_estado --Def. 6387
   from   ca_operacion
   where  op_banco = @i_banco
   
   if @@rowcount = 0 begin ----LLAMAR SP RECHAZOSO
      select @w_error = 710025 --- Error de Inexistencia del Numero Obligacion 
      select @w_procesar = 'N'
      
      select @w_posicion = 1 
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      
      exec @w_secuencial = sp_gen_sec
           @i_operacion  = -2
      
      select @w_dato_llave2  = convert(varchar(24),@w_secuencial)
      
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @i_banco, ---Porque no se pudo sacar el w_operacionca,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
      
      if @w_return != 0 begin
         select @w_error =  @w_return
         goto ERROR
      end     
      goto ERROR
   end  
   
   --SECUENCIAL DE INGRESO PARA EL PAGO
   if @w_operacionca > 0 begin
      select @w_secuencial = 0
      exec @w_secuencial = sp_gen_sec
           @i_operacion  = @w_operacionca
      
      select @w_dato_llave1  = @i_banco 
      select @w_dato_llave2  = convert(varchar(24),@w_secuencial)
   end
   ELSE begin
      select @w_dato_llave1  = @i_banco
      select @w_dato_llave2  = convert(varchar(24),@w_secuencial)
   end
   
   select @w_forma_pago = cp_producto
   from   ca_producto
   where  cp_producto = @i_forma_pago
   
   if @@rowcount = 0 begin      
      select @w_posicion = 3
      select @w_error = 710416 --- Error de Inexistencia de Forma de Pago
      select @w_procesar = 'N'      
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
      
      if @w_return != 0 begin
         select @w_error =  @w_return
         goto ERROR
      end
      goto ERROR
   end
   
   ---VALIDACION DE EL ESTADO ACTUAL DE LA  OPERACION
   if  @w_estado_op in (6,0,3) begin
      select @w_error = 708158 --Validacion estado de la operacion
      select @w_posicion = 1 
      select @w_procesar = 'N'
      
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      goto ERROR
   end --FIN VALIDACION ESTADO OPERACION
   
   select @w_oficina = of_oficina
   from   cobis..cl_oficina
   where  of_oficina = @i_oficina
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0 or @i_oficina is null begin      
      --Para que rechazos lo pueda tomar
      select @i_oficina = @w_op_oficina
      
      select @w_posicion = 8
      select @w_error = 141035 -- Error de Inexistencia de Oficina
      select @w_procesar = 'N'     
      
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      goto ERROR
   end
   
   --VALIDACION DE DECIMALES PARA LA MONEDA DE LA OPERACION
   --SI LA MONEDA NACIONAL NO ACEPTA DECIMALES, NO SE RECIBEN PAGOS
   --CON DECIMALES
   exec sp_decimales
   @i_moneda       = @w_moneda,
   @o_decimales    = @w_num_dec_op out,
   @o_mon_nacional = @w_moneda_mn  out,
   @o_dec_nacional = @w_num_dec_n  out
   
   select @w_decimales_pago  = @i_monto  - floor(@i_monto)
   
   if @w_decimales_pago > 0 and @w_num_dec_n = 0 begin
      select @w_posicion = 6
      select @w_error = 710468 -- La moneda nacional no tiene decimales
      select @w_procesar = 'N'
      
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      
      goto ERROR
   end
        
   if @i_tipo_aplicacion <> 'C'  and  @i_tipo_aplicacion <> 'D'  and  @i_tipo_aplicacion <> 'P' begin
      
      select @w_posicion = 4
      select @w_error = 710417 --- Error de Inexistencia de Tipo Aplicacion
      select @w_procesar = 'N'
      
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd         = @w_base_datos,
      @i_nombre_tabla      = @w_tabla_pagos_pit,
      @i_dato_llave1       = @w_dato_llave1,
      @i_dato_llave2       = @w_dato_llave2,
      @i_posicion          = @w_posicion,
      @i_codigo_error      = @w_error,
      @i_descripcion_error = @w_descripcion,
      @i_tipo_transaccion  = @i_tipo_trn
      
      if @w_return != 0 begin
        select @w_error =  @w_return
        goto ERROR
      end
      goto ERROR
   end
   
   if @i_tipo_reduccion <> 'N'  and @i_tipo_reduccion <> 'T'  and @i_tipo_reduccion <> 'C' begin
      select @w_posicion = 5
      select @w_error = 710418 --- Error de Inexistencia de Tipo Reduccion
      select @w_procesar = 'N'
      
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
      
      if @w_return != 0 begin
         select @w_error =  @w_return
         goto ERROR
      end      
   end
   
   if @i_tipo_aplicacion = 'P' and @i_concepto is not null begin
      select @w_concepto = ro_concepto
      from   ca_rubro_op
      where  ro_operacion = @w_operacionca
      and    ro_concepto  = @i_concepto
      
      if @@rowcount = 0 begin
         select @w_posicion = 7
         select @w_error = 710419 --- Error de Inexistencia de Concepto por Operacion 
         select @w_procesar = 'N'
         
         select @w_descripcion= mensaje
         from   cobis..cl_errores
         where  numero = @w_error
         set transaction isolation level read uncommitted
         exec @w_return = cob_cartera..sp_campo_errado
         @i_nombre_bd           = @w_base_datos,
         @i_nombre_tabla        = @w_tabla_pagos_pit,
         @i_dato_llave1         = @w_dato_llave1,
         @i_dato_llave2         = @w_dato_llave2,
         @i_posicion            = @w_posicion,
         @i_codigo_error        = @w_error,
         @i_descripcion_error   = @w_descripcion,
         @i_tipo_transaccion    = @i_tipo_trn
         
         if @w_return != 0 begin
            select @w_error =  @w_return
            goto ERROR
         end
         
         goto ERROR
      end
   end
   
   if @i_tipo_aplicacion = 'P' and @i_concepto is null begin
      select @w_posicion = 7
      select @w_error = 710420 --  Error de Inexistencia de Concepto en Pago Proporcional
      
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      select @w_procesar = 'N'
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
      
      if @w_return != 0 begin
         select @w_error =  @w_return
         goto ERROR
      end
      goto ERROR
   end 
   
   if @i_monto <= 0  or @i_monto is null begin
      --Para que rechazos lo pueda tomar
      update ca_abonos_masivos_generales
      set mg_monto_pago = 0.1
      where mg_operacion = @w_operacionca
            
      select @w_posicion = 6
      select @w_error = 710129 -- Monto del pago en Cero 
      select @w_procesar = 'N'
      
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
      
      if @w_return != 0 begin
         select @w_error =  @w_return
         goto ERROR
      end
      goto ERROR
   end 
   
   ---VALIDACION CUENTA
   if @i_cuenta is not null  and  @i_cuenta <> '' and @w_forma_pago <> 'NDCCPIT' and @w_forma_pago <> 'NDCHPIT' begin
      select @w_fpago_ndcc =  pa_char
      from   cobis..cl_parametro
      where  pa_nemonico = 'NDCC'
      and    pa_producto = 'CCA'
      set transaction isolation level read uncommitted
      
      select @w_fpago_ndaho =  pa_char
      from   cobis..cl_parametro
      where  pa_nemonico = 'NDAHO'
      and    pa_producto = 'CCA'
      set transaction isolation level read uncommitted 
      
      if @w_forma_pago <> @w_fpago_ndcc and @w_forma_pago <> @w_fpago_ndaho begin
         select @w_posicion = 3
         select @w_error = 710344 --- No existe forma de pago 
         select @w_procesar = 'N'   
         
         select @w_descripcion= mensaje
         from   cobis..cl_errores
         where  numero = @w_error
         set transaction isolation level read uncommitted
         
         exec @w_return = cob_cartera..sp_campo_errado
         @i_nombre_bd           = @w_base_datos,
         @i_nombre_tabla        = @w_tabla_pagos_pit,
         @i_dato_llave1         = @w_dato_llave1,
         @i_dato_llave2         = @w_dato_llave2,
         @i_posicion            = @w_posicion,
         @i_codigo_error        = @w_error,
         @i_descripcion_error   = @w_descripcion,
         @i_tipo_transaccion    = @i_tipo_trn
         
         if @w_return != 0 begin
            select @w_error =  @w_return
            goto ERROR
         end
         goto ERROR
      end
      
      --INICIO DE VALIDACION DE LOS DATOS DE LA CUENTA CORRIENTE
      -----------------------------------------------------------
      if @w_forma_pago = @w_fpago_ndcc begin
         --- VALIDACION EXISTENCIA DE LA CUENTA  CORRIENTE ENVIADA
         /*if not exists (select 1 
                        from  cob_cuentas..cc_ctacte
                        where cc_cta_banco = substring(@i_cuenta,1,16)
         and   cc_estado  = 'A') */
         exec @w_error = cob_interface..sp_verifica_cuenta_cte
               @i_operacion = 'VCTE',
               @i_cuenta    = @i_cuenta,
               @o_existe    = @w_existe out
         if not exists(select @w_existe)
         begin
            select @w_posicion = 9
            select @w_error = 710020 --- Cuenta no existe
            select @w_procesar = 'N'
               
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            goto ERROR
         end
         
         ---------------------------------------------------------
         ---Validar el saldo de la obligacion para debitar o no
         ---------------------------------------------------------
         select @i_cuenta = substring(@i_cuenta,1,16)
         select @w_saldo_disponible = 0
         
         exec @w_return = cob_interface..sp_calcula_sin_impuesto
         @s_ofi         = @s_ofi,                 ---OFICINA QUE EJECUTA LA CONSULTA
         @i_pit         = 'S',                    ---INDICADOR PARA NO REALIZAR ROLLBACK
         @i_cta_banco   = @i_cuenta,              ---NUMERO DE CUENTA
         @i_tipo_cta    = 3,                      ---PRODUCTO DE LA CUENTA
         @i_fecha       = @s_date,                ---FECHA DE LA CONSULTA
         @i_causa       = '310',                  ---CAUSA DE DEBITO (para verificar si cobra IVA)
         @o_valor       = @w_saldo_disponible out ---VALOR PARA REALIZAR LA ND
         
         if @w_return != 0 begin
            select @w_error =  @w_return
            goto ERROR
         end
         
         --SI EL DISPONIBLE NO ALCANZA RECHAZAR EL PAGO
         if @i_monto > @w_saldo_disponible begin
            select @w_posicion = 9
            select @w_error = 701075 --- Fondos Insuficientes
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            
            goto ERROR
         end
         ----------------------------------------------------------------
         ---Fin de validar el saldo de la obligacion para debitar o no
         ----------------------------------------------------------------
      end
      --FIN DE VALIDACION DE LOS DATOS DE LA CUENTA CORRIENTE
      -------------------------------------------------------------------    
      --VALIDACION DATOS DE LA CUENTA DE AHORROS
      -------------------------------------------------------------------
      if @w_forma_pago  =  @w_fpago_ndaho begin
         --- EXISTENCIA DE LA CUENTA DE AHORROS 
         exec @w_error = cob_interface..sp_verifica_cuenta_aho
               @i_operacion = 'VAHO',
               @i_cuenta    = @i_cuenta,
               @o_existe    = @w_existe out
         if not exists(select @w_existe)
         
         /*if not exists(select 1
                       from   cob_ahorros..ah_cuenta
                       where ah_cta_banco  = substring(@i_cuenta,1,16)
         and   ah_estado  = 'A') */
         begin
            select @w_posicion = 9
            select @w_error = 710020 --- Cueta no existe
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted 
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            
            goto ERROR
         end
         
         ----------------------------------------------------------
         ---Validar el saldo de la obligacion para debitar o no
         ----------------------------------------------------------
         select @i_cuenta = substring(@i_cuenta,1,16)
         select @w_saldo_disponible = 0
         
         exec @w_return = cob_interface..sp_calcula_sin_impuesto
         @s_ofi         = @s_ofi,                  ---OFICINA QUE EJECUTA LA CONSULTA
         @i_pit         = 'S',                     ---INDICADOR PARA NO REALIZAR ROLLBACK
         @i_cta_banco   = @i_cuenta,               ---NUMERO DE CUENTA
         @i_tipo_cta    = 4,                       ---PRODUCTO DE LA CUENTA
         @i_fecha       = @s_date,                 ---FECHA DE LA CONSULTA
         @i_causa       = '311',                   ---CAUSA DE DEBITO (para verificar si cobra IVA)
         @o_valor       = @w_saldo_disponible out  ---VALOR PARA REALIZAR LA ND
         
         if @w_return != 0 begin
            select @w_error =  @w_return
            goto ERROR
         end
         
         --SI EL DISPONIBLE NO ALCANZA RECHAZAR EL PAGO
         if @i_monto > @w_saldo_disponible begin
            select @w_posicion = 9
            select @w_error = 701075 --- Fondos Insuficientes
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            goto ERROR
         end
         ---------------------------------------------------------------
         ---FIN Validar el saldo de la obligacion para debitar o no
         ---------------------------------------------------------------
      end
       ---FIN DE VALIDACION DATOS DE LA CUETNA DE AHORROS
       -----------------------------------------------------------------
   end ---Validacion de la cuenta
   
   ---7804 Unificar en esta misma operacion el insertar en la ca_abono y ca_abono_det
   -----------------------------------------------------------------------------------
   
   select @w_operacionca        = op_operacion,
   @w_cuota_completa            = op_cuota_completa,
   @w_aceptar_anticipos         = op_aceptar_anticipos,
   @w_tipo_cobro                = op_tipo_cobro,
   @w_prepago_desde_lavigente   = op_prepago_desde_lavigente,
   @w_op_fecha_ult_proceso      = op_fecha_ult_proceso,
   @w_op_tipo                   = op_tipo,
   @w_op_moneda                 = op_moneda
   from   ca_operacion
   where  op_banco = @i_banco

   
   exec @w_return = sp_numero_recibo
   @i_tipo    = 'P',
   @i_oficina = @s_ofi,
   @o_numero  = @w_numero_recibo out
      
   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end
            
   exec @w_return = sp_conversion_moneda
   @s_date             = @s_date,
   @i_opcion           = 'L',
   @i_moneda_monto     = @i_moneda,
   @i_moneda_resultado = @w_moneda_nacional,
   @i_monto            = @i_monto,
   @o_monto_resultado  = @w_monto_mn out,
   @o_tipo_cambio      = @w_cot_moneda out 
      
   if @w_return <> 0 begin
      select @w_error = 710001
      goto ERROR
   end
      
   if @w_op_moneda  =   @w_moneda_nacional begin-- DETERMINAR EL VALOR DE COTIZACION DEL DIA
      select @w_cotizacion_hoy = 1.0
      select @w_monto_mop = @i_monto
   end   
   ELSE begin
        
      exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda,
      @i_fecha      = @w_op_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion_hoy output
       
      select @w_monto_mop = ceiling(@i_monto*10000.0 / @w_cotizacion_hoy)/10000.0
   end
           
   if @i_forma_pago = 'ICR'
      select @i_tipo_aplicacion = 'A'
   
   If exists (select 1 from ca_traslado_interes
              where ti_operacion = @w_operacionca
              and  ti_estado     = 'P')
   begin
      select @i_tipo_aplicacion = 'A'
   end

   ---Si la forma de pago es la parametrizada por el usuario CHLOCAL
   ---y el credito es clase O rotativo, se debe colocar unos dias de retencion al 
   -- Pago apra que solo se aplique pasado este tiempo
   
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
      
      if @w_rowcount = 0
         select  @w_dias_retencion = 0
      
      select    @w_ab_dias_retencion  = @w_dias_retencion
   end         
     
   -- INSERTAR EN ca_abono

   BEGIN TRAN         
      if  @w_procesar  = 'S' begin
         if @t_debug='S'
            print 'Insertando en ca_abono'

            insert into ca_abono
            (ab_secuencial_ing, ab_secuencial_rpa,      ab_secuencial_pag,            ab_operacion,
            ab_fecha_ing,       ab_fecha_pag,           ab_cuota_completa,            ab_aceptar_anticipos,
            ab_tipo_reduccion,  ab_tipo_cobro,          ab_dias_retencion_ini,        ab_dias_retencion,
            ab_estado,          ab_usuario,             ab_oficina,                   ab_terminal,
            ab_tipo,            ab_tipo_aplicacion,     ab_nro_recibo,                ab_tasa_prepago,
            ab_dividendo,       ab_calcula_devolucion,  ab_prepago_desde_lavigente)
            values(@w_secuencial,       0,                      0,                            @w_operacionca,
            @w_fecha_proceso,   @w_fecha_pago,          @w_cuota_completa,            @w_aceptar_anticipos,
            @i_tipo_reduccion,  @w_tipo_cobro,          @w_ab_dias_retencion,         @w_ab_dias_retencion,
            'ING',              @s_user,                @w_oficina,                   @s_term,
            'PAG',              @i_tipo_aplicacion,     @w_numero_recibo,             0.00,
            0,                  'N',                    @w_prepago_desde_lavigente)
         
            if @@error != 0 begin            
               select @w_error = 710232
               select @w_posicion = 0
               select @w_procesar = 'N'
                
               select @w_descripcion= mensaje
               from   cobis..cl_errores
               where  numero = @w_error
               set transaction isolation level read uncommitted
                  
               exec @w_return = cob_cartera..sp_campo_errado
               @i_nombre_bd           = @w_base_datos,
               @i_nombre_tabla        = @w_tabla_pagos_pit,
               @i_dato_llave1         = @w_dato_llave1,
               @i_dato_llave2         = @w_dato_llave2,
               @i_posicion            = @w_posicion,
               @i_codigo_error        = @w_error,
               @i_descripcion_error   = @w_descripcion,
               @i_tipo_transaccion    = @i_tipo_trn
                  
               if @w_return != 0 begin
                  select @w_error =  @w_return
                  goto ERROR
               end
                  
               goto ERROR
            end
               
           
         -- INSERTAR EN ca_abono_det
         if @i_cuenta is null
            select @i_cuenta = ''
         if @t_debug='S'
            print 'Insertando en ca_abono_det'

         insert into ca_abono_det
         (abd_secuencial_ing,    abd_operacion,       abd_tipo,            abd_concepto ,
          abd_cuenta,            abd_beneficiario,    abd_moneda,          abd_monto_mpg,
          abd_monto_mop,         abd_monto_mn,        abd_cotizacion_mpg,  abd_cotizacion_mop,
          abd_tcotizacion_mpg,   abd_tcotizacion_mop, abd_cheque,          abd_cod_banco,
          abd_inscripcion,       abd_carga,           abd_solidario)                            --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
         values(@w_secuencial,         @w_operacionca,      'PAG',               @i_forma_pago,
         isnull(@i_cuenta,'0'), 'CONVIVENCIA',       @i_moneda,           @i_monto,
         @w_monto_mop,          @w_monto_mn,         @w_cot_moneda,       @w_cotizacion_hoy,
         'C',                   'C',                 null,                null,
         null,                  null,                'N')
   
         if @@error != 0 begin
            select @w_error = 710233
            select @w_posicion = 0
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            
            goto ERROR
         end
              
         -- INSERTAR EN ca_abono_prioridad
         if @t_debug='S'
            print 'Insertando en ca_abono_prioridad'
         
         insert into ca_abono_prioridad
         (ap_secuencial_ing, ap_operacion, ap_concepto, ap_prioridad)
         select @w_secuencial, @w_operacionca, ro_concepto, ro_prioridad
         from   ca_rubro_op
         where  ro_operacion = @w_operacionca
         and    ro_fpago not in ('L','B')
         
         if @@error != 0 begin
            select @w_error = 710234
            select @w_posicion = 0
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            
            goto ERROR
         end
            
         ---Si el pago es por concepto validar la prioridad para
         ---actualizarla 

         if @i_concepto is not null  begin
            update ca_abono_prioridad
            set ap_prioridad = 0
            where ap_operacion      = @w_operacionca
            and   ap_secuencial_ing = @w_secuencial
            and   ap_concepto       = @i_concepto
         end
   
         exec @w_error   = sp_registro_abono
         @s_user           = @s_user,
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_ofi            = @s_ofi,
         @s_sesn           = 1,
         @s_ssn            = @s_ssn,
         @i_secuencial_ing = @w_secuencial,
         @i_en_linea       = 'N',
         @i_fecha_proceso  = @w_fecha_proceso,
         @i_operacionca    = @w_operacionca,
         @i_banco          = @i_banco,
         @i_cotizacion     = @w_cotizacion_hoy
         
         if @w_error != 0 begin
           
            select @w_posicion = 0
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            
            goto ERROR
         end
      end ---error = 0
                
      if  @w_procesar = 'S'
         select @w_estado_mg = 'P'
      else
         select @w_estado_mg = 'E'
      if @t_debug='S'
         print 'Insertando en ca_abonos_masivos_generales'
		   
      insert into ca_abonos_masivos_generales
      (mg_lote,            mg_fecha_cargue,  mg_nro_credito,
      mg_operacion,
      mg_fecha_pago,      mg_forma_pago,    mg_tipo_aplicacion,
      mg_tipo_reduccion,  mg_monto_pago,    mg_prioridad_concepto,
      mg_oficina,         mg_fecha_proceso, mg_estado,
      mg_cuenta,          mg_nro_control,   mg_tipo_trn,
      mg_posicion_error,  mg_codigo_error,  mg_descripcion_error,
      mg_secuencial_ing,  mg_moneda,        mg_terminal,
      mg_usuario)
      values(@i_lote,            @w_fecha_cargue,   @i_banco,
      @w_operacionca,
      @w_fecha_pago,      @i_forma_pago,     @i_tipo_aplicacion,
      @i_tipo_reduccion,  @i_monto,          @i_concepto,
      @i_oficina,         @w_fecha_proceso,  @w_estado_mg,
      @i_cuenta,          @i_nro_control,    @i_tipo_trn,
      @w_posicion,        @w_error,          @w_descripcion,
      @w_secuencial,      @i_moneda,         @s_term,
      @s_user)
             
   COMMIT TRAN       
             
   -----------------------------------------------------------------------------------
end -- (T) Validacion de datos  

if @i_operacion = 'B' begin  /* modulo para BANCAMIA */
   --    PRINT 'ABMAGENE: ENTRO OPERACION B'
   if @t_debug = 'S'
      Print 'Iniciando proceso Bancamia'

   if @s_term <> 'PIT' begin --Enviado desde front-end
      if @t_debug = 'S'
         Print 'Llamando a sp_abonosmas'
      exec @w_error =  sp_abonomas_linea
      @s_ssn              = @s_ssn,
      @s_date             = @s_date,
      @s_user             = @s_user,
      @s_term             = @s_term,
      @s_ofi              = @s_ofi,
      @t_debug            = @t_debug,
      @t_file             = @t_file,
      @t_trn              = @t_trn,
      @i_operacion        = @i_operacion,
      @i_lote             = @i_lote,
      @i_banco            = @i_banco,
      @i_fecha_pago       = @i_fecha_pago,
      @i_forma_pago       = @i_forma_pago,
      @i_tipo_aplicacion  = @i_tipo_aplicacion,
      @i_tipo_reduccion   = @i_tipo_reduccion,
      @i_monto            = @i_monto,
      @i_concepto         = @i_concepto,
      @i_oficina          = @i_oficina,
      @i_cuenta           = @i_cuenta,
      @i_moneda           = @i_moneda,
      @i_fecha_proceso    = @w_fecha_proceso
         
      if @w_error != 0
         goto ERROR
      -- return 0
   end
   
   select @w_fecha_cargue = getdate()
   select @w_fecha_pago   = convert(char(10),@i_fecha_pago,101)
   
   select @w_error = 0,
   @w_descripcion  = '',
   @w_operacionca  = 0,
   @w_posicion     = 0
   
   select @w_operacionca       = op_operacion,
   @w_cliente           = op_cliente,
   @w_moneda            = op_moneda,
   @w_op_oficina        = op_oficina,
   @w_estado_op         = op_estado 
   from   ca_operacion
   where  op_banco = @i_banco
   
   if @@rowcount = 0 begin ----LLAMAR SP RECHAZOSO
      select @w_error = 710025 --- Error de Inexistencia del Numero Obligacion 
      select @w_procesar = 'N'
     
      select @w_posicion = 1 
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
     
      exec @w_secuencial = sp_gen_sec
           @i_operacion  = -2
     
      select @w_dato_llave2  = convert(varchar(24),@w_secuencial)
      
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @i_banco, ---Porque no se pudo sacar el w_operacionca,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
       
      if @w_return != 0 begin
          select @w_error =  @w_return
          goto ERROR
      end
	
      goto ERROR
   end  

   if @t_debug = 'S'
      Print 'Buscando Secuencial Ingreso de pago'

   -- SECUENCIAL DE INGRESO PARA EL PAGO
   if @w_operacionca > 0 begin
      select @w_secuencial = 0
      exec @w_secuencial = sp_gen_sec
            @i_operacion  = @w_operacionca
     
      select @w_dato_llave1  = @i_banco 
      select @w_dato_llave2  = convert(varchar(24),@w_secuencial)
   end
   ELSE begin
       select @w_dato_llave1  = @i_banco
       select @w_dato_llave2  = convert(varchar(24),@w_secuencial)
   end
   
   if @t_debug = 'S'
      Print 'Revisando forma de pago'   

   select @w_forma_pago = cp_producto
   from   ca_producto
   where  cp_producto = @i_forma_pago
   
   if @@rowcount = 0 begin
      select @w_posicion = 3
      select @w_error = 710416 --- Error de Inexistencia de Forma de Pago
      select @w_procesar = 'N'
     
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
      
      if @w_return != 0 begin
          select @w_error =  @w_return
          goto ERROR
      end
      goto ERROR

   end
   
   ---VALIDACION DE EL ESTADO ACTUAL DE LA  OPERACION
   if @t_debug  ='S'
      Print 'Validando estado de la operacion'

   if  @w_estado_op in (6,0,3) begin
      select @w_error = 709158 --Validacion estado de la operacion
      select @w_posicion = 1 
      select @w_procesar = 'N'
     
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
     
      if @w_return != 0 begin
         print 'regresando de rechazosos....'
         select @w_error =  @w_return
         goto ERROR
      end
      
      goto ERROR

   end --FIN VALIDACION ESTADO OPERACION
   
   select @w_oficina = of_oficina
   from   cobis..cl_oficina
   where  of_oficina = @i_oficina
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0 or @i_oficina is null begin
      --Para que rechazos lo pueda tomar
      select @i_oficina = @w_op_oficina
     
      select @w_posicion = 8
      select @w_error = 141035 -- Error de Inexistencia de Oficina
      select @w_procesar = 'N'
     
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted

      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
     
      if @w_return != 0  begin
         print 'regresando de rechazosos....2'
         select @w_error =  @w_return
         goto ERROR
      end
      print 'regresando de rechazosos....3' +cast(@i_oficina as varchar)
      goto ERROR
   end
   
   --VALIDACION DE DECIMALES PARA LA MONEDA DE LA OPERACION
   --SI LA MONEDA NACIONAL NO ACEPTA DECIMALES, NO SE RECIBEN PAGOS
   --CON DECIMALES
   exec sp_decimales
   @i_moneda       = @w_moneda,
   @o_decimales    = @w_num_dec_op out,
   @o_mon_nacional = @w_moneda_mn  out,
   @o_dec_nacional = @w_num_dec_n  out
   
   select @w_decimales_pago  = @i_monto  - floor(@i_monto)
   
   if @w_decimales_pago > 0 and @w_num_dec_n = 0 begin
      select @w_posicion = 6
      select @w_error = 710468 -- La moneda nacional no tiene decimales
      select @w_procesar = 'N'
     
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
     
      if @w_return != 0 begin
          select @w_error =  @w_return
          goto ERROR
      end
      goto ERROR
   end
   if @t_debug = 'S'
      Print 'Validando tipo de aplicacion'     
   if @i_tipo_aplicacion <> 'C'  and  @i_tipo_aplicacion <> 'D'  and  @i_tipo_aplicacion <> 'P' begin
     
      select @w_posicion = 4
      select @w_error = 710417 --- Error de Inexistencia de Tipo Aplicacion
      select @w_procesar = 'N'
     
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
     
      if @w_return != 0 begin
         select @w_error =  @w_return
         goto ERROR
      end

      goto ERROR
   end
   
   if @i_tipo_reduccion <> 'N'  and @i_tipo_reduccion <> 'T'  and @i_tipo_reduccion <> 'C' begin
      select @w_posicion = 5
      select @w_error = 710418 --- Error de Inexistencia de Tipo Reduccion
      select @w_procesar = 'N'
     
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
     
      if @w_return != 0 begin
         select @w_error =  @w_return
         goto ERROR
      end
      goto ERROR
   end
   
   if @i_tipo_aplicacion = 'P' and @i_concepto is not null begin
      select @w_concepto = ro_concepto
      from   ca_rubro_op
      where  ro_operacion = @w_operacionca
      and    ro_concepto  = @i_concepto
     
      if @@rowcount = 0 begin
         select @w_posicion = 7
         select @w_error = 710419 --- Error de Inexistencia de Concepto por Operacion 
         select @w_procesar = 'N'
       
         select @w_descripcion= mensaje
         from   cobis..cl_errores
         where  numero = @w_error
         set transaction isolation level read uncommitted
         exec @w_return = cob_cartera..sp_campo_errado
         @i_nombre_bd           = @w_base_datos,
         @i_nombre_tabla        = @w_tabla_pagos_pit,
         @i_dato_llave1         = @w_dato_llave1,
         @i_dato_llave2         = @w_dato_llave2,
         @i_posicion            = @w_posicion,
         @i_codigo_error        = @w_error,
         @i_descripcion_error   = @w_descripcion,
         @i_tipo_transaccion    = @i_tipo_trn
       
         if @w_return != 0 begin
            select @w_error =  @w_return
            goto ERROR
         end

         goto ERROR
      end
   end
   
   if @i_tipo_aplicacion = 'P' and @i_concepto is null begin
      select @w_posicion = 7
      select @w_error = 710420 --  Error de Inexistencia de Concepto en Pago Proporcional
     
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
      select @w_procesar = 'N'

      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
     
      if @w_return != 0 begin
          select @w_error =  @w_return
          goto ERROR
      end

      goto ERROR
   end 
   
   if @i_monto <= 0  or @i_monto is null begin

      --Para que rechazos lo pueda tomar
      update ca_abonos_masivos_generales
      set mg_monto_pago = 0.1
      where mg_operacion = @w_operacionca
     
      select @w_posicion = 6
      select @w_error = 710129 -- Monto del pago en Cero 
      select @w_procesar = 'N'
     
      select @w_descripcion= mensaje
      from   cobis..cl_errores
      where  numero = @w_error
      set transaction isolation level read uncommitted
     
      exec @w_return = cob_cartera..sp_campo_errado
      @i_nombre_bd           = @w_base_datos,
      @i_nombre_tabla        = @w_tabla_pagos_pit,
      @i_dato_llave1         = @w_dato_llave1,
      @i_dato_llave2         = @w_dato_llave2,
      @i_posicion            = @w_posicion,
      @i_codigo_error        = @w_error,
      @i_descripcion_error   = @w_descripcion,
      @i_tipo_transaccion    = @i_tipo_trn
     
      if @w_return != 0 begin
         select @w_error =  @w_return
         goto ERROR
      end

      goto ERROR
   end 
   
   ---VALIDACION CUENTA
   if @i_cuenta is not null  and  @i_cuenta <> '' and @w_forma_pago <> 'NDCCPIT' and @w_forma_pago <> 'NDCHPIT' begin
      select @w_fpago_ndcc =  pa_char
      from   cobis..cl_parametro
      where  pa_nemonico = 'NDCC'
      and    pa_producto = 'CCA'
      set transaction isolation level read uncommitted
     
      select @w_fpago_ndaho =  pa_char
      from   cobis..cl_parametro
      where  pa_nemonico = 'NDAHO'
      and    pa_producto = 'CCA'
      set transaction isolation level read uncommitted
     
      if @w_forma_pago <> @w_fpago_ndcc and @w_forma_pago <> @w_fpago_ndaho begin
         select @w_posicion = 3
         select @w_error = 710344 --- No existe forma de pago 
         select @w_procesar = 'N'   
       
         select @w_descripcion= mensaje
         from   cobis..cl_errores
         where  numero = @w_error
         set transaction isolation level read uncommitted
       
         exec @w_return = cob_cartera..sp_campo_errado
         @i_nombre_bd           = @w_base_datos,
         @i_nombre_tabla        = @w_tabla_pagos_pit,
         @i_dato_llave1         = @w_dato_llave1,
         @i_dato_llave2         = @w_dato_llave2,
         @i_posicion            = @w_posicion,
         @i_codigo_error        = @w_error,
         @i_descripcion_error   = @w_descripcion,
         @i_tipo_transaccion    = @i_tipo_trn
       
         if @w_return != 0 begin
            select @w_error =  @w_return
            goto ERROR
         end

         goto ERROR
      end
     
      --INICIO DE VALIDACION DE LOS DATOS DE LA CUENTA CORRIENTE
      --------------------------------------------------------------------------------------------------
      if @w_forma_pago = @w_fpago_ndcc begin
         --- VALIDACION EXISTENCIA DE LA CUENTA  CORRIENTE ENVIADA
         /*if not exists (select 1 
                        from  cob_cuentas..cc_ctacte
                        where cc_cta_banco = substring(@i_cuenta,1,16)
         and   cc_estado  = 'A') */
         exec @w_error = cob_interface..sp_verifica_cuenta_cte
               @i_operacion = 'VCTE',
               @i_cuenta    = @i_cuenta,
               @o_existe    = @w_existe out
         if not exists(select @w_existe)
         begin
            select @w_posicion = 9
            select @w_error = 710020 --- Cueta no existe
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
         
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
         
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            goto ERROR
         end
       
         ------------------------------------------------------------------------------------------
         ---Validar el saldo de la obligacion para debitar o no
         ------------------------------------------------------------------------------------------
		 select @i_cuenta = substring(@i_cuenta,1,16)
		 select @w_saldo_disponible = 0
       
         exec @w_return = cob_interface..sp_calcula_sin_impuesto
         @s_ofi         = @s_ofi,                     ---OFICINA QUE EJECUTA LA CONSULTA
         @i_pit         = 'S',                        ---INDICADOR PARA NO REALIZAR ROLLBACK
         @i_cta_banco   = @i_cuenta,                  ---NUMERO DE CUENTA
         @i_tipo_cta    = 3,                          ---PRODUCTO DE LA CUENTA
         @i_fecha       = @s_date,                    ---FECHA DE LA CONSULTA
         @i_causa       = '310',                      ---CAUSA DE DEBITO (para verificar si cobra IVA)
         @o_valor       = @w_saldo_disponible out     ---VALOR PARA REALIZAR LA ND
       
         if @w_return != 0 begin
            select @w_error =  @w_return
            goto ERROR
         end
       
         --SI EL DISPONIBLE NO ALCANZA RECHAZAR EL PAGO
         if @i_monto > @w_saldo_disponible begin
            select @w_posicion = 9
            select @w_error = 701075 --- Fondos Insuficientes
            select @w_procesar = 'N'
         
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
         
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
         
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
             
            goto ERROR
         end
         --------------------------------------------------------------------------------------------
         ---Fin de validar el saldo de la obligacion para debitar o no
         ---------------------------------------------------------------------------------------------
      end
      --FIN DE VALIDACION DE LOS DATOS DE LA CUENTA CORRIENTE
      -----------------------------------------------------------------------------------------------
     
      --VALIDACION DATOS DE LA CUENTA DE AHORROS
      -----------------------------------------------------------------------------------------------
      if 'S' = (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' and pa_producto = 'CCA')
      begin --inicio  existe validacion con cobis-ahorros
         if @w_forma_pago  =  @w_fpago_ndaho 
         begin
            --- EXISTENCIA DE LA CUENTA DE AHORROS 
            exec @w_error = cob_interface..sp_verifica_cuenta_aho
                  @i_operacion = 'VAHO',
                  @i_cuenta    = @i_cuenta,
                  @o_existe    = @w_existe out
            if not exists(select @w_existe)
              
            /*if not exists(select 1
                          from   cob_ahorros..ah_cuenta
                          where ah_cta_banco  = substring(@i_cuenta,1,16)
            and   ah_estado  = 'A') */
            begin
               select @w_posicion = 9
               select @w_error = 710020 --- Cueta no existe
               select @w_procesar = 'N'
            
               select @w_descripcion= mensaje
               from   cobis..cl_errores
               where  numero = @w_error
               set transaction isolation level read uncommitted 
            
               exec @w_return = cob_cartera..sp_campo_errado
               @i_nombre_bd           = @w_base_datos,
               @i_nombre_tabla        = @w_tabla_pagos_pit,
               @i_dato_llave1         = @w_dato_llave1,
               @i_dato_llave2         = @w_dato_llave2,
               @i_posicion            = @w_posicion,
               @i_codigo_error        = @w_error,
               @i_descripcion_error   = @w_descripcion,
               @i_tipo_transaccion    = @i_tipo_trn
            
               if @w_return != 0 
               begin
                  select @w_error =  @w_return
                  goto ERROR
               end
               goto ERROR
            end
          
            ------------------------------------------------------------------------------------------
            ---Validar el saldo de la obligacion para debitar o no
            ------------------------------------------------------------------------------------------
            select @i_cuenta = substring(@i_cuenta,1,16)
            select @w_saldo_disponible = 0
          
            exec @w_return = cob_interface..sp_calcula_sin_impuesto
            @s_ofi         = @s_ofi,                  ---OFICINA QUE EJECUTA LA CONSULTA
            @i_pit         = 'S',                     ---INDICADOR PARA NO REALIZAR ROLLBACK
            @i_cta_banco   = @i_cuenta,               ---NUMERO DE CUENTA
            @i_tipo_cta    = 4,                       ---PRODUCTO DE LA CUENTA
            @i_fecha       = @s_date,                 ---FECHA DE LA CONSULTA
            @i_causa       = '311',                   ---CAUSA DE DEBITO (para verificar si cobra IVA)
            @o_valor       = @w_saldo_disponible out  ---VALOR PARA REALIZAR LA ND
          
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
          
            --SI EL DISPONIBLE NO ALCANZA RECHAZAR EL PAGO
            if @i_monto > @w_saldo_disponible begin
               select @w_posicion = 9
               select @w_error = 701075 --- Fondos Insuficientes
               select @w_procesar = 'N'
            
               select @w_descripcion= mensaje
               from   cobis..cl_errores
               where  numero = @w_error
               set transaction isolation level read uncommitted
            
               exec @w_return = cob_cartera..sp_campo_errado
               @i_nombre_bd           = @w_base_datos,
               @i_nombre_tabla        = @w_tabla_pagos_pit,
               @i_dato_llave1         = @w_dato_llave1,
               @i_dato_llave2         = @w_dato_llave2,
               @i_posicion            = @w_posicion,
               @i_codigo_error        = @w_error,
               @i_descripcion_error   = @w_descripcion,
               @i_tipo_transaccion    = @i_tipo_trn
            
               if @w_return != 0 begin
                  select @w_error =  @w_return
                  goto ERROR
               end
               
               goto ERROR
            end
            ------------------------------------------------------------------------------------------
            ---FIN Validar el saldo de la obligacion para debitar o no
            ------------------------------------------------------------------------------------------
            FIN_INSERT:
         end
         ---FIN DE VALIDACION DATOS DE LA CUETNA DE AHORROS
         --------------------------------------------------------------------------------------------------
        end ---Validacion de la cuenta
      end --fin  existe validacion con cobis-ahorros
   ---7804 Unificar en esta misma operacion el insertar en la ca_abono y ca_abono_det
   -----------------------------------------------------------------------------------
   
   select @w_operacionca        = op_operacion,
   @w_cuota_completa            = op_cuota_completa,
   @w_aceptar_anticipos         = op_aceptar_anticipos,
   @w_tipo_cobro                = op_tipo_cobro,
   @w_prepago_desde_lavigente   = op_prepago_desde_lavigente,
   @w_op_fecha_ult_proceso      = op_fecha_ult_proceso,
   @w_op_tipo                   = op_tipo,
   @w_op_moneda                 = op_moneda
   from   ca_operacion
   where  op_banco = @i_banco

   
   exec @w_return = sp_numero_recibo
   @i_tipo    = 'P',
   --@i_oficina = @s_ofi,    Mroa: Determinar si la oficina de recibo es la de ejecucion o de la operacion
   @i_oficina = @i_oficina,
   @o_numero  = @w_numero_recibo out
     
   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end
          
   exec @w_return = sp_conversion_moneda
   @s_date             = @s_date,
   @i_opcion           = 'L',
   @i_moneda_monto     = @i_moneda,
   @i_moneda_resultado = @w_moneda_nacional,
   @i_monto            = @i_monto,
   @o_monto_resultado  = @w_monto_mn out,
   @o_tipo_cambio      = @w_cot_moneda out 
   
   if @w_return <> 0 begin
      select @w_error = 710001
      goto ERROR
   end
     
   if @w_op_moneda = @w_moneda_nacional  begin -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
      select @w_cotizacion_hoy = 1.0
      select @w_monto_mop = @i_monto
   end   
   ELSE begin        
      exec sp_buscar_cotizacion
      @i_moneda     = @w_moneda,
      @i_fecha      = @w_op_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion_hoy output
      
      select @w_monto_mop = ceiling(@i_monto*10000.0 / @w_cotizacion_hoy)/10000.0
   end
     
    
   if @i_forma_pago = 'ICR'
      select @i_tipo_aplicacion = 'A'
     
   --- INICIO REQ 379 IFJ 22/Nov/2005
   If exists (select 1 from ca_traslado_interes
              where ti_operacion = @w_operacionca
              and  ti_estado     = 'P')
   begin
       select @i_tipo_aplicacion = 'A'
   end

   ---Si la forma de pago es la parametrizada por el usuario CHLOCAL
   ---y el credito es clase O rotativo, se debe colocar unos dias de retencion al 
   -- Pago apra que solo se aplique pasado este tiempo
     
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
       
      if @w_rowcount = 0
         select  @w_dias_retencion = 0
       
      select    @w_ab_dias_retencion  = @w_dias_retencion
   end
       
   -- INSERTAR EN ca_abono

   BEGIN TRAN
        
      if  @w_procesar  = 'S' begin
         if @t_debug='S'
         PRINT 'ABMAGENE: INSERTANDO EN CA_ABONO @s_user ' + cast(@s_user as varchar)
         insert into ca_abono
         (ab_secuencial_ing, ab_secuencial_rpa,      ab_secuencial_pag,            ab_operacion,
         ab_fecha_ing,       ab_fecha_pag,           ab_cuota_completa,            ab_aceptar_anticipos,
         ab_tipo_reduccion,  ab_tipo_cobro,          ab_dias_retencion_ini,        ab_dias_retencion,
         ab_estado,          ab_usuario,             ab_oficina,                   ab_terminal,
         ab_tipo,            ab_tipo_aplicacion,     ab_nro_recibo,                ab_tasa_prepago,
         ab_dividendo,       ab_calcula_devolucion,  ab_prepago_desde_lavigente)
         values(@w_secuencial,      0,                      0,                            @w_operacionca,
         @w_fecha_proceso,   @w_fecha_pago,          @w_cuota_completa,            @w_aceptar_anticipos,
         @i_tipo_reduccion,  @w_tipo_cobro,          @w_ab_dias_retencion,         @w_ab_dias_retencion,
         'ING',              @s_user,                @w_oficina,                   @s_term,
         'PAG',              @i_tipo_aplicacion,     @w_numero_recibo,             0.00,
         0,                  'N',                    @w_prepago_desde_lavigente)
         
         if @@error != 0 begin  
            select @w_error = 710232
            select @w_posicion = 0
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            
            goto ERROR
         end
                      
          -- INSERTAR EN ca_abono_det
         if @i_cuenta is null
            select @i_cuenta = ''

         if @t_debug='S'
            print 'Insertando en ca_abono_det'

         insert into ca_abono_det
         (abd_secuencial_ing,   abd_operacion,       abd_tipo,            abd_concepto ,
         abd_cuenta,            abd_beneficiario,    abd_moneda,          abd_monto_mpg,
         abd_monto_mop,         abd_monto_mn,        abd_cotizacion_mpg,  abd_cotizacion_mop,
         abd_tcotizacion_mpg,   abd_tcotizacion_mop, abd_cheque,          abd_cod_banco,
         abd_inscripcion,       abd_carga,           abd_solidario)                            --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
         values(@w_secuencial,      @w_operacionca,      'PAG',               @i_forma_pago,
         isnull(@i_cuenta,'0'), 'CONVENIOS',         @i_moneda,           @i_monto,
         @w_monto_mop,          @w_monto_mn,         @w_cot_moneda,       @w_cotizacion_hoy,
         'C',                   'C',                 null,                null,
         null,                  null,                'N')
   
         if @@error != 0
         begin
            select @w_error = 710233
            select @w_posicion = 0
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0
            begin
               select @w_error =  @w_return
               goto ERROR
            end
             
            goto ERROR
         end
             
         -- INSERTAR EN ca_abono_prioridad
         if @t_debug='S'
            print 'Insertando en ca_abono_prioridad'
         
         insert into ca_abono_prioridad
         (ap_secuencial_ing, ap_operacion, ap_concepto, ap_prioridad)
         select @w_secuencial, @w_operacionca, ro_concepto, ro_prioridad
         from   ca_rubro_op
         where  ro_operacion = @w_operacionca
         and    ro_fpago not in ('L','B')
         
         if @@error != 0 begin
            select @w_error = 710234
            select @w_posicion = 0
            select @w_procesar = 'N'
            
            select @w_descripcion = mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            
            goto ERROR
         end

         ---Si el pago es por concepto validar la prioridad para
         ---actualizarla 
         
         if @i_concepto is not null begin
            update ca_abono_prioridad
            set ap_prioridad = 0
            where ap_operacion      = @w_operacionca
            and   ap_secuencial_ing = @w_secuencial
            and ap_concepto         = @i_concepto
         end
                        
         
         exec @w_error     = sp_registro_abono
         @s_user           = @s_user,
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_ofi            = @s_ofi,
         @s_sesn           = 1,
         @s_ssn            = @s_ssn,
         @i_secuencial_ing = @w_secuencial,
         @i_en_linea       = 'N',
         @i_fecha_proceso  = @w_fecha_proceso,
         @i_operacionca    = @w_operacionca,
         @i_cotizacion     = @w_cotizacion_hoy
         
         if @w_error != 0 begin
            select @w_posicion = 0
            select @w_procesar = 'N'
            
            select @w_descripcion= mensaje
            from   cobis..cl_errores
            where  numero = @w_error
            set transaction isolation level read uncommitted
            
            exec @w_return = cob_cartera..sp_campo_errado
            @i_nombre_bd           = @w_base_datos,
            @i_nombre_tabla        = @w_tabla_pagos_pit,
            @i_dato_llave1         = @w_dato_llave1,
            @i_dato_llave2         = @w_dato_llave2,
            @i_posicion            = @w_posicion,
            @i_codigo_error        = @w_error,
            @i_descripcion_error   = @w_descripcion,
            @i_tipo_transaccion    = @i_tipo_trn
            
            if @w_return != 0 begin
               select @w_error =  @w_return
               goto ERROR
            end
            
            goto ERROR
         end
      end ---error = 0
              
      if  @w_procesar = 'S'
          select @w_estado_mg = 'P'
      else
          select @w_estado_mg = 'E'

      if @t_debug='S'
         print 'Insertando en ca_abonos_masivos_generales'
   
      insert into ca_abonos_masivos_generales
      (mg_lote,           mg_fecha_cargue,  mg_nro_credito,
      mg_operacion,
      mg_fecha_pago,      mg_forma_pago,    mg_tipo_aplicacion,
      mg_tipo_reduccion,  mg_monto_pago,    mg_prioridad_concepto,
      mg_oficina,         mg_fecha_proceso, mg_estado,
      mg_cuenta,          mg_nro_control,   mg_tipo_trn,
      mg_posicion_error,  mg_codigo_error,  mg_descripcion_error,
      mg_secuencial_ing,  mg_moneda,        mg_terminal,
      mg_usuario)
      values(@i_lote,            @w_fecha_cargue,   @i_banco,
      @w_operacionca,
      @w_fecha_pago,      @i_forma_pago,     @i_tipo_aplicacion,
      @i_tipo_reduccion,  @i_monto,          @i_concepto,
      @i_oficina,         @w_fecha_proceso,  @w_estado_mg,
      @i_cuenta,          @i_nro_control,    @i_tipo_trn,
      @w_posicion,        @w_error,          @w_descripcion,
      @w_secuencial,      @i_moneda,         @s_term,
      @s_user)

      /*MRoa: ACTUALIZACION DE LOS RUBROS DE COMISION E IVA QUE SE DEBEN COBRAR EN EL PROCESO DE PAGO DE CONVENIOS*/
      --DETERMINACION DE LA CUOTA DONDE SE VA A EFECTUAR EL COBRO DE LA COMISION DE RECAUDO
      if exists(select 1 
                from ca_dividendo
                where di_operacion = @w_operacionca
                and   di_estado    = 1)
      begin
         select @w_min_dividendo = min(di_dividendo)
         from ca_dividendo
         where di_operacion = @w_operacionca
         and   di_estado = 1
      end
      else begin
         select @w_min_dividendo = min(di_dividendo)
         from ca_dividendo
         where di_operacion = @w_operacionca
         and   di_estado = 2
      end

      --ACTUALIZACION DEL VALOR COBRADO POR COMISION DE RECAUDO
      update ca_rubro_op
      set ro_valor = ro_valor + @i_valor_recaudo
      where ro_operacion = @w_operacionca
      and   ro_concepto  = 'CMRCGTECH'

      update ca_rubro_op
      set ro_valor = ro_valor + @i_valor_iva_recaudo
      where ro_operacion = @w_operacionca
      and   ro_concepto  = 'IVACOMGTCH'

      --ACTUALIZACION DEL VALOR COBRADO POR COMISION DE RECAUDO
      update ca_amortizacion
      set am_cuota     = am_cuota + @i_valor_recaudo,
          am_acumulado = am_acumulado + @i_valor_recaudo
      where am_operacion = @w_operacionca
      and   am_dividendo = @w_min_dividendo
      and   am_concepto  = 'CMRCGTECH'

      update ca_amortizacion
      set am_cuota     = am_cuota + @i_valor_iva_recaudo,
          am_acumulado = am_acumulado + @i_valor_iva_recaudo
      where am_operacion = @w_operacionca
      and   am_dividendo = @w_min_dividendo
      and   am_concepto  = 'IVACOMGTCH'
           
   COMMIT TRAN       
   -----------------------------------------------------------------------------------
end-- (T) Validacion de datos  -- BANCAMIA

-- CONSULTA DE REGISTROS CON ERROR EN EL CARGUE
if @i_operacion = 'Q' begin
   set rowcount 20
   select 
   'OBLIGACION/CLIENTE'              = mg_nro_credito,
   'COD.ERROR '                      = mg_codigo_error,
   'DESCRIPCION                    ' = mg_descripcion_error 
   from   ca_abonos_masivos_generales
   where  mg_codigo_error > 0
   and    mg_lote   = @i_lote
   and    mg_nro_credito > @i_siguiente 
   order by mg_nro_credito 
   set rowcount 0
end -- Consulta Registros con Error

return 0

ERROR:
while @@trancount > 0 ROLLBACK

if @s_term  = 'PIT' begin
   if @t_debug='S'
      print 'Insertando en ca_error_log'

   insert into ca_errorlog
   (er_fecha_proc,     er_error,      er_usuario,
   er_tran,            er_cuenta,     er_descripcion,
   er_anexo)
   values(@w_fecha_proceso,   @w_error,      @s_user,
   7269,               @i_banco,      @w_descripcion,
   convert(varchar(12),@i_lote)
   ) 
   
   while @@trancount < @w_trancount BEGIN TRAN
   return @w_error
end
ELSE begin   
   exec cobis..sp_cerror 
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg
     
   return @w_error
end
go

