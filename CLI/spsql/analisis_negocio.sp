/************************************************************************/
/*   Archivo:             analisis_negocio.sp                           */
/*   Stored procedure:    sp_analisis_negocio                           */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            CLIENTES                                      */
/*   Disenado por:        ALD                                           */
/*   Fecha de escritura:  30-Abril-2019                                 */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                     PROPOSITO                                        */
/*   Se realizan todas las operaciones relacionadas al analisis_negocio */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 30/Abril/2019            ALD        Version Inicial Te Creemos       */
/* 12/Agosto/2019           JSDV       Se agregan dos parametros de     */
/*                                     entrada i_ctas_por_cobrar y      */
/*                                     i_ctas_por_pagar_largo_plazo     */
/*                                     Se modifican las operaciones     */
/*                                     I,U,S  para tomar los param      */
/* 25/Junio/2020            FSAP       Estandarizacion clientes         */
/* 01/Febrero/2023          BDU        Nuevos campos ENL                */
/* 24/Marzo/2023            BDU        Select default para deudas       */
/* 09/Septiembre/2023       BDU        R214440-Sincronizacion automatica*/
/* 20/Octubre/2023          BDU        R217831-Ajuste validacion error  */
/* 16/Enero/2024            DMO        R221949:Se añade @i_operacion 'B'*/
/* 22/Enero/2024            BDU        R224055-Validar oficina app      */
/************************************************************************/

use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
             from sysobjects 
            where name = 'sp_analisis_negocio')
   drop proc sp_analisis_negocio 
go

create procedure sp_analisis_negocio(
@s_ssn                                       int         = 0, 
@s_srv                                       varchar(30) = null,
@s_date                                      datetime    = null, 
@s_user                                      login       = null, 
@s_ofi                                       int         = 0,
@t_debug                                     char(1)     = 'N',
@t_file                                      varchar(10) = null, 
@t_trn                                       int         = 0, 
@t_show_version                              bit         = 0,    -- Mostrar la versión del programa
@i_operacion                                 char(1), 
@i_cliente                                   int         = 0,
@i_codigo_negocio                            int         = 0,
@i_ventas_prom_mes                           money       = null,
@i_compras_prom_mes                          money       = null,
@i_renta_neg                                 money       = null,
@i_transporte_neg                            money       = null , 
@i_personal_neg                              money       = null,
@i_impuestos_neg                             money       = null,
@i_electrica_neg                             money       = null,
@i_agua_neg                                  money       = null,
@i_telefono_neg                              money       = null,
@i_otros_neg                                 money       = null, 
@i_inventario                                int         = 0,
@i_inversion_neg                             money       = null,
@i_frecuencia_inv                            varchar(10) = null,
@i_presta                                    char(1)     = null,
@i_frecuencia_cobro                          varchar(10) = null,
@i_debe_prestamo                             char(1)     = null,
@i_cuota_pago                                money       = null,
@i_frecuencia_pago                           varchar(10) = null,
@i_disponible                                money       = null,
@i_ganancia_neg                              money       = null,
@i_frecuencia_utilidad                       varchar(10) = null,
@i_capacidad_pago_mes                        money       = null,
@i_producto                                  varchar(60) = null,
@i_porcentaje_venta_regs                     float       = null,
@i_valor_vivienda                            money       = null,
@i_valor_negocio                             money       = null,
@i_valor_vehiculo                            money       = null,
@i_valor_mobiliario                          money       = null,                   
@i_valor_otros                               money       = null,
@i_ingresos_extra                            char(1)     = null,
@i_monto_extra                               money       = null,
@i_origen_extra                              varchar(20) = null,
@i_gastos_alimentacion                       money       = null,
@i_gastos_renta_viv                          money       = null,
@i_gastos_energia_elec                       money       = null,
@i_gastos_agua                               money       = null,
@i_gastos_telefono                           money       = null,
@i_gastos_tv                                 money       = null,
@i_gastos_salud                              money       = null,
@i_gastos_transporte                         money       = null, 
@i_gastos_educacion                          money       = null,
@i_gastos_gas                                money       = null,
@i_gastos_vestido                            money       = null,
@i_gastos_otros                              money       = null,
-- Se agregan por historia - CLI-S273446-TEC Estados Financieros del Cliente
@i_ctas_por_cobrar                           money       = null,
@i_ctas_por_pagar_largo_plazo                money       = null,
-- Se agregar por historia - ORI-S769940-ENL-Cambios en análisis del Negocio en WEB
@i_bienes_inmuebles_negocio                  money       = null,
@i_vehiculo_negocio                          money       = null,
@i_deudas_buro_corto_plazo                   money       = null,
@i_deudas_buro_largo_plazo                   money       = null,
@i_cuota_buro                                money       = null,
@i_deudas_enl_corto_plazo                    money       = null,
@i_deudas_enl_largo_plazo                    money       = null,
@i_cuota_enl                                 money       = null,
@i_ajuste_largo_plazo                        money       = null
)
as 
--DECLARACION DE VARIABLES PARA OPERACION INTERNA
declare @w_mensaje       varchar(80),
        @w_today         datetime,       -- fecha del dia 
        @w_return        int,            -- valor que retorna 
        @w_sp_name       varchar(32),    -- descripcion del stored procedure
        @w_sp_msg        varchar(132),
        @w_fecha_proceso datetime,
        --@w_neg_cliente   int,
        @w_existe_cliente bit,
        @w_existe_analisis  bit ,
        @w_existe_cat_oe  bit ,
        @w_existe_cat_frec  bit, 
        @w_ventas_prom_mes money, 
        @w_compras_prom_mes money, 
        @w_renta_neg money, 
        @w_transporte_neg money, 
        @w_personal_neg money, 
        @w_impuestos_neg money, 
        @w_electrica_neg money, 
        @w_agua_neg money, 
        @w_telefono_neg money, 
        @w_otros_neg money, 
        @w_inventario int, 
        @w_inversion_neg money, 
        @w_frecuencia_inv varchar(10), 
        @w_presta char(1), 
        @w_frecuencia_cobro varchar(10), 
        @w_debe_prestamo char(1), 
        @w_cuota_pago money, 
        @w_frecuencia_pago varchar(10), 
        @w_disponible money, 
        @w_ganancia_neg money, 
        @w_frecuencia_utilidad varchar(10), 
        @w_capacidad_pago_mes money, 
        @w_producto varchar(60), 
        @w_porcentaje_venta_regs float, 
        @w_valor_vivienda money, 
        @w_valor_negocio money, 
        @w_valor_vehiculo money, 
        @w_valor_mobiliario money, 
        @w_valor_otros money, 
        @w_ingresos_extra char(1), 
        @w_monto_extra money, 
        @w_origen_extra varchar(20), 
        @w_gastos_alimentacion money, 
        @w_gastos_renta_viv money, 
        @w_gastos_energia_elec money, 
        @w_gastos_agua money, 
        @w_gastos_telefono money, 
        @w_gastos_tv money, 
        @w_gastos_salud money, 
        @w_gastos_transporte money, 
        @w_gastos_educacion money, 
        @w_gastos_gas money, 
        @w_gastos_vestido money, 
        @w_gastos_otros money,
        @w_ctas_por_cobrar money, 
        @w_ctas_por_pagar_largo_plazo money,
        @w_transaccion int,
        @w_num              int,
        @w_param            int, 
        @w_diff             int,
        @w_date             datetime,
        @w_bloqueo          char(1),
        @w_buro_cuota       money,
        @w_buro_largo       money,
        @w_buro_corto       money,
        @w_enl_cuota        money,
        @w_enl_largo        money,
        @w_enl_corto        money,
        -- Se agregar por historia - ORI-S769940-ENL-Cambios en análisis del Negocio en WEB
        @w_bienes_inmuebles_negocio   money,
        @w_vehiculo_negocio           money,
        @w_deudas_buro_corto_plazo    money,
        @w_deudas_buro_largo_plazo    money,
        @w_cuota_buro                 money,
        @w_deudas_enl_corto_plazo     money,
        @w_deudas_enl_largo_plazo     money,
        @w_cuota_enl                  money,
        @w_ajuste_largo_plazo         money,
        -- R214440-Sincronizacion automatica
        @w_sincroniza      char(1),
        @w_error           int,
        @w_ofi_app         smallint

select @w_today = getdate() 
select @w_sp_name = 'sp_analisis_negocio' 

-------------- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
     
     
select @w_fecha_proceso = fp_fecha 
  from cobis..ba_fecha_proceso

select @w_existe_cliente = 1 
  from cl_ente 
 where en_ente = @i_cliente 

select @w_existe_analisis = 1 
  from cl_analisis_negocio 
 where an_cliente_id = @i_cliente

select @w_existe_cat_oe = count (1) 
  from cl_catalogo 
 where codigo = @i_origen_extra

select @w_transaccion = tn_trn_code 
  from cobis..cl_ttransaccion 
 where tn_descripcion = 'ANALISIS NEGOCIO ENTE'

--EVALUACION DEL TIPO DE TRANSACCION 
if (@t_trn <> 172083 and @i_operacion = 'I') or  --insert 
   (@t_trn <> 172100 and @i_operacion = 'U') or  --update
   (@t_trn <> 172101 and @i_operacion = 'S')     --search
begin 
   /* Tipo de transaccion no corresponde */ 
   exec cobis..sp_cerror 
        @t_debug = @t_debug, 
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1720275
   return 1
end
if @i_operacion in ('I', 'U')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   if @i_cliente is not null and @i_cliente <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_cliente
      if @w_bloqueo = 'S'
      begin
         exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720604
         return 1720604
      end
   end 
end
--TIPO DE TRANSACCION INSERT 
if @i_operacion = 'I'
begin 
  --Comienza conjunto de validaciones 
  if @i_codigo_negocio is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  
  if @i_ventas_prom_mes is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_compras_prom_mes is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_renta_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_transporte_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_personal_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_impuestos_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_electrica_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_agua_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_telefono_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_otros_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_inventario is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_inversion_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_frecuencia_inv is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end

   select @w_existe_cat_frec = count(1) 
   from cl_catalogo x inner join cl_tabla y on x.tabla = y.codigo
   where x.codigo = @i_frecuencia_inv
   and y.tabla = 'cl_frecuencia'

  if @w_existe_cat_frec = 0
  begin 
    /* NoExisteCatalogoFrecuencia */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720295
    return 1
  end
  if @i_presta is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_presta = 'S' and @i_frecuencia_cobro is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end

   select @w_existe_cat_frec = count(1) 
   from cl_catalogo x inner join cl_tabla y on x.tabla = y.codigo
   where x.codigo = @i_frecuencia_cobro
   and y.tabla = 'cl_frecuencia'
   
   if @i_presta = 'S' and @w_existe_cat_frec = 0
  begin 
    /* NoExisteCatalogoFrecuencia */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720295
    return 1
  end
  if @i_debe_prestamo is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_cuota_pago is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_debe_prestamo = 'S' and @i_frecuencia_pago is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
   select @w_existe_cat_frec = count(1) 
   from cl_catalogo x inner join cl_tabla y on x.tabla = y.codigo
   where x.codigo = @i_frecuencia_pago
   and y.tabla = 'cl_frecuencia'

   if @i_debe_prestamo = 'S' and @w_existe_cat_frec = 0
  begin 
    /* NoExisteCatalogoFrecuencia */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720295
    return 1
  end
  if @i_disponible is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_ganancia_neg is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_frecuencia_utilidad is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
   
   select @w_existe_cat_frec = count(1) 
   from cl_catalogo x inner join cl_tabla y on x.tabla = y.codigo
   where x.codigo = @i_frecuencia_utilidad
   and y.tabla = 'cl_frecuencia'

  if @w_existe_cat_frec = 0
  begin 
    /* NoExisteCatalogoFrecuencia */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720295
    return 1
  end
  if @i_capacidad_pago_mes is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_producto is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_porcentaje_venta_regs is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_valor_vivienda is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_valor_negocio is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_valor_vehiculo is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_valor_mobiliario is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_valor_otros is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_ingresos_extra is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_ingresos_extra = 'S' and @i_monto_extra is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_ingresos_extra = 'S' and @i_origen_extra is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  select @w_existe_cat_oe = count (1) from cl_catalogo where codigo = @i_origen_extra
  if @i_ingresos_extra = 'S' and @w_existe_cat_oe = 0
  begin 
    /* No existe catalogo de origen ingreso extra */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720296
    return 1
  end
  if @i_gastos_alimentacion is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_renta_viv is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_energia_elec is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_agua is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_telefono is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_tv is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_salud is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_transporte is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_educacion is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_gas is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_gastos_vestido is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end 
  if @i_gastos_otros is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_bienes_inmuebles_negocio is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_vehiculo_negocio is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_deudas_buro_corto_plazo is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_deudas_buro_largo_plazo is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_cuota_buro is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_deudas_enl_corto_plazo is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_deudas_enl_largo_plazo is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_cuota_enl is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end
  if @i_ajuste_largo_plazo is null
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720294
    return 1
  end

  --Posterior a las validaciones de los parametros de entrada procedemos a registrar la transaccion
  begin tran
  
    --Insert dentro de tabla cl_analisis_negocio
    INSERT INTO cl_analisis_negocio (
      [an_cliente_id], [an_negocio_codigo], [an_ventas_prom_mes], [an_compras_prom_mes], [an_renta_neg]
    , [an_transporte_neg], [an_personal_neg], [an_impuestos_neg], [an_electrica_neg], [an_agua_neg], [an_telefono_neg]
    , [an_otros_neg], [an_inventario], [an_inversion_neg], [an_frecuencia_inv], [an_presta], [an_frecuencia_cobro]
    , [an_debe_prestamo], [an_cuota_pago], [an_frecuencia_pago], [an_disponible], [an_ganancia_neg], [an_frecuencia_util]
    , [an_capacidad_pago_mes], [an_producto], [an_porcentaje_venta_regs], [an_valor_vivienda], [an_valor_negocio], [an_valor_vehiculo]
    , [an_valor_mobiliario], [an_valor_otros], [an_ingresos_extra], [an_monto_extra], [an_origen_extra], [an_gastos_alimentos]
    , [an_gastos_renta_viv], [an_gastos_energia_elect], [an_gastos_agua], [an_gastos_telefono], [an_gastos_tv]
    , [an_gastos_salud], [an_gastos_transp], [an_gastos_educ], [an_gastos_gas], [an_gastos_vestido], [an_gastos_otros]
    , [an_ctas_por_cobrar], [an_ctas_por_pagar_largo_plazo], an_ajuste_deuda, an_valor_vehiculo2, an_valor_vivienda2,
       an_deuda_corto_buro,  an_deuda_largo_buro, an_cuota_pago_buro, an_deuda_corto_enlace, an_deuda_largo_enlace, 
       an_cuota_pago_enlace)
    
    VALUES (@i_cliente, @i_codigo_negocio, @i_ventas_prom_mes, @i_compras_prom_mes, @i_renta_neg
    , @i_transporte_neg, @i_personal_neg, @i_impuestos_neg, @i_electrica_neg, @i_agua_neg, @i_telefono_neg
    , @i_otros_neg, @i_inventario, @i_inversion_neg, @i_frecuencia_inv, @i_presta, @i_frecuencia_cobro
    , @i_debe_prestamo, @i_cuota_pago, @i_frecuencia_pago, @i_disponible, @i_ganancia_neg, @i_frecuencia_utilidad
    , @i_capacidad_pago_mes, @i_producto, @i_porcentaje_venta_regs,@i_valor_vivienda, @i_valor_negocio, @i_valor_vehiculo
    , @i_valor_mobiliario, @i_valor_otros, @i_ingresos_extra, @i_monto_extra, @i_origen_extra, @i_gastos_alimentacion
    , @i_gastos_renta_viv, @i_gastos_energia_elec, @i_gastos_agua, @i_gastos_telefono, @i_gastos_tv
    , @i_gastos_salud, @i_gastos_transporte, @i_gastos_educacion, @i_gastos_gas, @i_gastos_vestido, @i_gastos_otros
    , @i_ctas_por_cobrar, @i_ajuste_largo_plazo, @i_ctas_por_pagar_largo_plazo, @i_vehiculo_negocio, @i_bienes_inmuebles_negocio,
      @i_deudas_buro_corto_plazo, @i_deudas_buro_largo_plazo, @i_cuota_buro, @i_deudas_enl_corto_plazo, @i_deudas_enl_largo_plazo,
      @i_cuota_enl)
    
    if @@rowcount = 0 
         begin 
            /* 'No fue posible registrar la operación' */ 
            exec cobis..sp_cerror 
                 @t_debug = @t_debug, 
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name, 
                 @i_num   = 1720297 
            rollback tran
      --return 1720297 
         end 

    insert into ts_analisis_negocio (an_tipo_transaccion, an_clase, an_secuencial, an_tabla, an_operacion, an_cliente_id
      , an_negocio_codigo, an_ventas_prom_mes, an_compras_prom_mes, an_renta_neg, an_transporte_neg, an_personal_neg
      , an_impuestos_neg, an_electrica_neg, an_agua_neg, an_telefono_neg, an_otros_neg, an_inventario
      , an_inversion_neg, an_presta, an_frecuencia_cobro, an_debe_prestamo, an_cuota_pago, an_frecuencia_pago
      , an_disponible, an_ganancia_neg, an_frecuencia_util, an_capacidad_pago_mes, an_producto, an_porcentaje_venta_regs
      , an_valor_vivienda, an_valor_negocio, an_valor_vehiculo, an_valor_mobiliario, an_valor_otros, an_ingresos_extra
      , an_monto_extra, an_origen_extra, an_gastos_alimentos, an_gastos_renta_viv, an_gastos_energia_elect, an_gastos_agua
      , an_gastos_telefono, an_gastos_tv, an_gastos_salud, an_gastos_transp, an_gastos_educ, an_gastos_gas
      , an_gastos_vestido, an_gastos_otros, an_ctas_por_cobrar, an_frecuencia_inv, [an_ctas_por_pagar_largo_plazo], 
        an_ajuste_deuda, an_valor_vehiculo2, an_valor_vivienda2,
        an_deuda_corto_buro,  an_deuda_largo_buro, an_cuota_pago_buro, an_deuda_corto_enlace, an_deuda_largo_enlace, 
        an_cuota_pago_enlace)
    values (@t_trn, 'N', isnull(@s_ssn, 1), 'cl_analisis_negocio', @i_operacion, @i_cliente
      , @i_codigo_negocio, @i_ventas_prom_mes, @i_compras_prom_mes, @i_renta_neg, @i_transporte_neg, @i_personal_neg
      , @i_impuestos_neg, @i_electrica_neg, @i_agua_neg, @i_telefono_neg, @i_otros_neg, @i_inventario
      , @i_inversion_neg, @i_presta, @i_frecuencia_cobro, @i_debe_prestamo, @i_cuota_pago, @i_frecuencia_pago
      , @i_disponible, @i_ganancia_neg, @i_frecuencia_utilidad, @i_capacidad_pago_mes, @i_producto, @i_porcentaje_venta_regs
      , @i_valor_vivienda, @i_valor_negocio, @i_valor_vehiculo, @i_valor_mobiliario, @i_valor_otros, @i_ingresos_extra
      , @i_monto_extra, @i_origen_extra, @i_gastos_alimentacion, @i_gastos_renta_viv, @i_gastos_energia_elec, @i_gastos_agua
      , @i_gastos_telefono, @i_gastos_tv, @i_gastos_salud, @i_gastos_transporte, @i_gastos_educacion, @i_gastos_gas
      , @i_gastos_vestido, @i_gastos_otros, @i_ctas_por_cobrar, @i_frecuencia_inv,  @i_ajuste_largo_plazo, @i_ctas_por_pagar_largo_plazo, 
        @i_vehiculo_negocio, @i_bienes_inmuebles_negocio,
        @i_deudas_buro_corto_plazo, @i_deudas_buro_largo_plazo, @i_cuota_buro, @i_deudas_enl_corto_plazo, @i_deudas_enl_largo_plazo,
        @i_cuota_enl)

     if @@rowcount = 0 
         begin 
            -- 'No fue posible registrar la operación' 
            exec cobis..sp_cerror 
                 @t_debug = @t_debug, 
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name, 
                 @i_num   = 1720297 
            rollback tran
      --return 1720297 
         end 

  commit tran
end

--TIPO DE TRANSACCION UPDATE  
if @i_operacion = 'U'
begin 
    --Comienza conjunto de validaciones 
  if @w_existe_cliente is null 
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720298
    return 1
  end

  /*Validaciones de catalogos*/
  select @w_existe_cat_frec = count (*) from cl_catalogo where codigo = @i_frecuencia_inv
  if @w_existe_cat_frec = 0
  begin 
    /* NoExisteCatalogoFrecuencia */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720295
    return 1
  end
  
   select @w_existe_cat_frec = count(1) 
   from cl_catalogo x inner join cl_tabla y on x.tabla = y.codigo
   where x.codigo = @i_frecuencia_cobro
   and y.tabla = 'cl_frecuencia'

  if @i_presta = 'S' and @w_existe_cat_frec = 0
  begin 
    /* NoExisteCatalogoFrecuencia */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720295
    return 1
  end
  
   select @w_existe_cat_frec = count(1) 
   from cl_catalogo x inner join cl_tabla y on x.tabla = y.codigo
   where x.codigo = @i_frecuencia_pago
   and y.tabla = 'cl_frecuencia'

  if @i_debe_prestamo = 'S' and @w_existe_cat_frec = 0
  begin 
    /* NoExisteCatalogoFrecuencia */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720295
    return 1
  end
  select @w_existe_cat_frec = count(1)
   from cl_catalogo x inner join cl_tabla y on x.tabla = y.codigo
   where x.codigo = @i_frecuencia_utilidad
   and y.tabla = 'cl_frecuencia'
  if @w_existe_cat_frec = 0
  begin 
    /* NoExisteCatalogoFrecuencia */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720295
    return 1
  end
  
  select @w_ventas_prom_mes = an_ventas_prom_mes 
    , @w_compras_prom_mes = an_compras_prom_mes 
    , @w_renta_neg = an_renta_neg 
    , @w_transporte_neg = an_transporte_neg 
    , @w_personal_neg = an_personal_neg 
    , @w_impuestos_neg = an_impuestos_neg 
    , @w_electrica_neg = an_electrica_neg 
    , @w_agua_neg = an_agua_neg 
    , @w_telefono_neg = an_telefono_neg 
    , @w_otros_neg = an_otros_neg 
    , @w_inventario = an_inventario 
    , @w_inversion_neg = an_inversion_neg 
    , @w_frecuencia_inv = an_frecuencia_inv 
    , @w_presta = an_presta 
    , @w_frecuencia_cobro = an_frecuencia_cobro 
    , @w_debe_prestamo = an_debe_prestamo 
    , @w_cuota_pago = an_cuota_pago 
    , @w_frecuencia_pago = an_frecuencia_pago 
    , @w_disponible = an_disponible 
    , @w_ganancia_neg = an_ganancia_neg 
    , @w_frecuencia_utilidad = an_frecuencia_util 
    , @w_capacidad_pago_mes = an_capacidad_pago_mes 
    , @w_producto = an_producto 
    , @w_porcentaje_venta_regs = an_porcentaje_venta_regs 
    , @w_valor_vivienda = an_valor_vivienda 
    , @w_valor_negocio = an_valor_negocio 
    , @w_valor_vehiculo = an_valor_vehiculo 
    , @w_valor_mobiliario = an_valor_mobiliario 
    , @w_valor_otros = an_valor_otros 
    , @w_ingresos_extra = an_ingresos_extra 
    , @w_monto_extra = an_monto_extra 
    , @w_origen_extra = an_origen_extra 
    , @w_gastos_alimentacion = an_gastos_alimentos 
    , @w_gastos_renta_viv = an_gastos_renta_viv 
    , @w_gastos_energia_elec = an_gastos_energia_elect 
    , @w_gastos_agua = an_gastos_agua 
    , @w_gastos_telefono = an_gastos_telefono 
    , @w_gastos_tv = an_gastos_tv 
    , @w_gastos_salud = an_gastos_salud 
    , @w_gastos_transporte = an_gastos_transp 
    , @w_gastos_educacion = an_gastos_educ 
    , @w_gastos_gas = an_gastos_gas 
    , @w_gastos_vestido = an_gastos_vestido 
    , @w_gastos_otros = an_gastos_otros 
    , @w_ctas_por_cobrar = an_ctas_por_cobrar
    , @w_ctas_por_pagar_largo_plazo = an_ctas_por_pagar_largo_plazo,
      @w_bienes_inmuebles_negocio   = an_valor_vivienda2,
      @w_vehiculo_negocio           = an_valor_vehiculo2,
      @w_deudas_buro_corto_plazo    = an_deuda_corto_buro,
      @w_deudas_buro_largo_plazo    = an_deuda_largo_buro,
      @w_cuota_buro                 = an_cuota_pago_buro,
      @w_deudas_enl_corto_plazo     = an_deuda_corto_enlace,
      @w_deudas_enl_largo_plazo     = an_deuda_corto_enlace,
      @w_cuota_enl                  = an_cuota_pago_enlace,
      @w_ajuste_largo_plazo         = an_ctas_por_pagar_largo_plazo     
      
      
  from cl_analisis_negocio
  where an_cliente_id = @i_cliente
  and an_negocio_codigo = @i_codigo_negocio
  
  /*Comienzo de transacciones*/
  begin tran 

        insert into ts_analisis_negocio (an_tipo_transaccion, an_clase, an_secuencial, an_tabla, an_operacion, an_cliente_id
      , an_negocio_codigo, an_ventas_prom_mes, an_compras_prom_mes, an_renta_neg, an_transporte_neg, an_personal_neg
      , an_impuestos_neg, an_electrica_neg, an_agua_neg, an_telefono_neg, an_otros_neg, an_inventario
      , an_inversion_neg, an_presta, an_frecuencia_cobro, an_debe_prestamo, an_cuota_pago, an_frecuencia_pago
      , an_disponible, an_ganancia_neg, an_frecuencia_util, an_capacidad_pago_mes, an_producto, an_porcentaje_venta_regs
      , an_valor_vivienda, an_valor_negocio, an_valor_vehiculo, an_valor_mobiliario, an_valor_otros, an_ingresos_extra
      , an_monto_extra, an_origen_extra, an_gastos_alimentos, an_gastos_renta_viv, an_gastos_energia_elect, an_gastos_agua
      , an_gastos_telefono, an_gastos_tv, an_gastos_salud, an_gastos_transp, an_gastos_educ, an_gastos_gas
      , an_gastos_vestido, an_gastos_otros, an_ctas_por_cobrar, an_frecuencia_inv, [an_ctas_por_pagar_largo_plazo], 
        an_ajuste_deuda, an_valor_vehiculo2, an_valor_vivienda2,
        an_deuda_corto_buro,  an_deuda_largo_buro, an_cuota_pago_buro, an_deuda_corto_enlace, an_deuda_largo_enlace, 
        an_cuota_pago_enlace)
    values (@t_trn, 'P', isnull(@s_ssn, 1), 'cl_analisis_negocio', @i_operacion, @i_cliente
      , @i_codigo_negocio, @w_ventas_prom_mes, @w_compras_prom_mes, @w_renta_neg, @w_transporte_neg, @w_personal_neg
      , @w_impuestos_neg, @w_electrica_neg, @w_agua_neg, @w_telefono_neg, @w_otros_neg, @w_inventario
      , @w_inversion_neg, @w_presta, @w_frecuencia_cobro, @w_debe_prestamo, @w_cuota_pago, @w_frecuencia_pago
      , @w_disponible, @w_ganancia_neg, @w_frecuencia_utilidad, @w_capacidad_pago_mes, @w_producto, @w_porcentaje_venta_regs
      , @w_valor_vivienda, @w_valor_negocio, @w_valor_vehiculo, @w_valor_mobiliario, @w_valor_otros, @w_ingresos_extra
      , @w_monto_extra, @w_origen_extra, @w_gastos_alimentacion, @w_gastos_renta_viv, @w_gastos_energia_elec, @w_gastos_agua
      , @w_gastos_telefono, @w_gastos_tv, @w_gastos_salud, @w_gastos_transporte, @w_gastos_educacion, @w_gastos_gas
      , @w_gastos_vestido, @w_gastos_otros, @w_ctas_por_cobrar, @w_frecuencia_inv, @w_ajuste_largo_plazo, @w_ctas_por_pagar_largo_plazo, 
        @w_vehiculo_negocio, @w_bienes_inmuebles_negocio,
        @w_deudas_buro_corto_plazo, @w_deudas_buro_largo_plazo, @w_cuota_buro, @w_deudas_enl_corto_plazo, @w_deudas_enl_largo_plazo,
        @w_cuota_enl)

    if @@rowcount = 0 
         begin 
            -- 'No fue posible registrar la operación' 
            exec cobis..sp_cerror 
                 @t_debug = @t_debug, 
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name, 
                 @i_num   = 1720297 
            rollback tran
      --return 1720297 
         end 

    update cl_analisis_negocio set an_ventas_prom_mes = coalesce(@i_ventas_prom_mes, an_ventas_prom_mes)
                  , an_compras_prom_mes               = coalesce(@i_compras_prom_mes, an_compras_prom_mes)
                  , an_renta_neg                      = coalesce(@i_renta_neg, an_renta_neg)
                  , an_transporte_neg                 = coalesce(@i_transporte_neg, an_transporte_neg )
                  , an_personal_neg                   = coalesce(@i_personal_neg, an_personal_neg)
                  , an_impuestos_neg                  = coalesce(@i_impuestos_neg, an_impuestos_neg)
                  , an_electrica_neg                  = coalesce(@i_electrica_neg, an_electrica_neg )
                  , an_agua_neg                       = coalesce(@i_agua_neg,an_agua_neg)
                  , an_telefono_neg                   = coalesce(@i_telefono_neg, an_telefono_neg)
                  , an_otros_neg                      = coalesce(@i_otros_neg,an_otros_neg)
                  , an_inventario                     = coalesce(@i_inventario,an_inventario)
                  , an_inversion_neg                  = coalesce(@i_inversion_neg, an_inversion_neg)
                  , an_frecuencia_inv                 = coalesce(@i_frecuencia_inv, an_frecuencia_inv)
                  , an_presta                         = coalesce(@i_presta, an_presta)
                  , an_frecuencia_cobro               = coalesce(@i_frecuencia_cobro, an_frecuencia_cobro)
                  , an_debe_prestamo                  = coalesce(@i_debe_prestamo, an_debe_prestamo)
                  , an_cuota_pago                     = coalesce(@i_cuota_pago, an_cuota_pago)
                  , an_frecuencia_pago                = coalesce(@i_frecuencia_pago, an_frecuencia_pago)
                  , an_disponible                     = coalesce(@i_disponible, an_disponible )
                  , an_ganancia_neg                   = coalesce(@i_ganancia_neg, an_ganancia_neg )
                  , an_frecuencia_util                = coalesce(@i_frecuencia_utilidad, an_frecuencia_util)
                  , an_capacidad_pago_mes             = coalesce(@i_capacidad_pago_mes, an_capacidad_pago_mes)
                  , an_producto                       = coalesce(@i_producto, an_producto)
                  , an_porcentaje_venta_regs          = coalesce(@i_porcentaje_venta_regs, an_porcentaje_venta_regs )
                  , an_valor_vivienda                 = coalesce(@i_valor_vivienda, an_valor_vivienda)
                  , an_valor_negocio                  = coalesce(@i_valor_negocio, an_valor_negocio)
                  , an_valor_vehiculo                 = coalesce(@i_valor_vehiculo, an_valor_vehiculo)
                  , an_valor_mobiliario               = coalesce(@i_valor_mobiliario, an_valor_mobiliario)
                  , an_valor_otros                    = coalesce(@i_valor_otros, an_valor_otros)
                  , an_ingresos_extra                 = coalesce(@i_ingresos_extra, an_ingresos_extra )
                  , an_monto_extra                    = coalesce(@i_monto_extra, an_monto_extra)
                  , an_origen_extra                   = coalesce(@i_origen_extra, an_origen_extra)
                  , an_gastos_alimentos               = coalesce(@i_gastos_alimentacion, an_gastos_alimentos )
                  , an_gastos_renta_viv               = coalesce(@i_gastos_renta_viv, an_gastos_renta_viv)
                  , an_gastos_energia_elect           = coalesce(@i_gastos_energia_elec, an_gastos_energia_elect)
                  , an_gastos_agua                    = coalesce(@i_gastos_agua, an_gastos_agua)
                  , an_gastos_telefono                = coalesce(@i_gastos_telefono, an_gastos_telefono)
                  , an_gastos_tv                      = coalesce(@i_gastos_tv, an_gastos_tv)
                  , an_gastos_salud                   = coalesce(@i_gastos_salud, an_gastos_salud)
                  , an_gastos_transp                  = coalesce(@i_gastos_transporte, an_gastos_transp)
                  , an_gastos_educ                    = coalesce(@i_gastos_educacion, an_gastos_educ)
                  , an_gastos_gas                     = coalesce(@i_gastos_gas, an_gastos_gas)
                  , an_gastos_vestido                 = coalesce(@i_gastos_vestido, an_gastos_vestido)
                  , an_gastos_otros                   = coalesce(@i_gastos_otros, an_gastos_otros)
                  , an_ctas_por_cobrar                = coalesce(@i_ctas_por_cobrar, an_ctas_por_cobrar)
                  , an_ctas_por_pagar_largo_plazo     = coalesce(@i_ajuste_largo_plazo, an_ctas_por_pagar_largo_plazo)
                  , an_ajuste_deuda                   = coalesce(@i_ctas_por_pagar_largo_plazo, an_ajuste_deuda),
                  an_valor_vehiculo2                  = coalesce(@i_vehiculo_negocio, an_valor_vehiculo2   ), 
                  an_valor_vivienda2                  = coalesce(@i_bienes_inmuebles_negocio,an_valor_vivienda2),
                  an_deuda_corto_buro                 = coalesce(@i_deudas_buro_corto_plazo,an_deuda_corto_buro),  
                  an_deuda_largo_buro                 = coalesce(@i_deudas_buro_largo_plazo,an_deuda_largo_buro), 
                  an_cuota_pago_buro                  = coalesce(@i_cuota_buro,an_cuota_pago_buro), 
                  an_deuda_corto_enlace               = coalesce(@i_deudas_enl_corto_plazo,an_deuda_corto_enlace), 
                  an_deuda_largo_enlace               = coalesce(@i_deudas_enl_largo_plazo,an_deuda_largo_enlace), 
                  an_cuota_pago_enlace                = coalesce(@i_cuota_enl,an_cuota_pago_enlace)
                  where an_cliente_id = @i_cliente
                  and an_negocio_codigo = @i_codigo_negocio
    
    if @@rowcount = 0 
         begin 
            /* 'No fue posible actualizar la operación' */ 
            exec cobis..sp_cerror 
                 @t_debug = @t_debug, 
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name, 
                 @i_num   = 1720297 
            rollback tran
      --return 1720297 
         end 
    
    insert into ts_analisis_negocio (an_tipo_transaccion, an_clase, an_secuencial, an_tabla, an_operacion, an_cliente_id
      , an_negocio_codigo, an_ventas_prom_mes, an_compras_prom_mes, an_renta_neg, an_transporte_neg, an_personal_neg
      , an_impuestos_neg, an_electrica_neg, an_agua_neg, an_telefono_neg, an_otros_neg, an_inventario
      , an_inversion_neg, an_presta, an_frecuencia_cobro, an_debe_prestamo, an_cuota_pago, an_frecuencia_pago
      , an_disponible, an_ganancia_neg, an_frecuencia_util, an_capacidad_pago_mes, an_producto, an_porcentaje_venta_regs
      , an_valor_vivienda, an_valor_negocio, an_valor_vehiculo, an_valor_mobiliario, an_valor_otros, an_ingresos_extra
      , an_monto_extra, an_origen_extra, an_gastos_alimentos, an_gastos_renta_viv, an_gastos_energia_elect, an_gastos_agua
      , an_gastos_telefono, an_gastos_tv, an_gastos_salud, an_gastos_transp, an_gastos_educ, an_gastos_gas
      , an_gastos_vestido, an_gastos_otros, an_ctas_por_cobrar, an_frecuencia_inv, [an_ctas_por_pagar_largo_plazo], 
        an_ajuste_deuda, an_valor_vehiculo2, an_valor_vivienda2,
        an_deuda_corto_buro,  an_deuda_largo_buro, an_cuota_pago_buro, an_deuda_corto_enlace, an_deuda_largo_enlace, 
        an_cuota_pago_enlace)
    values (@t_trn, 'A', isnull(@s_ssn, 1), 'cl_analisis_negocio', @i_operacion, @i_cliente
      , @i_codigo_negocio, @i_ventas_prom_mes, @i_compras_prom_mes, @i_renta_neg, @i_transporte_neg, @i_personal_neg
      , @i_impuestos_neg, @i_electrica_neg, @i_agua_neg, @i_telefono_neg, @i_otros_neg, @i_inventario
      , @i_inversion_neg, @i_presta, @i_frecuencia_cobro, @i_debe_prestamo, @i_cuota_pago, @i_frecuencia_pago
      , @i_disponible, @i_ganancia_neg, @i_frecuencia_utilidad, @i_capacidad_pago_mes, @i_producto, @i_porcentaje_venta_regs
      , @i_valor_vivienda, @i_valor_negocio, @i_valor_vehiculo, @i_valor_mobiliario, @i_valor_otros, @i_ingresos_extra
      , @i_monto_extra, @i_origen_extra, @i_gastos_alimentacion, @i_gastos_renta_viv, @i_gastos_energia_elec, @i_gastos_agua
      , @i_gastos_telefono, @i_gastos_tv, @i_gastos_salud, @i_gastos_transporte, @i_gastos_educacion, @i_gastos_gas
      , @i_gastos_vestido, @i_gastos_otros, @i_ctas_por_cobrar, @i_frecuencia_inv, @i_ajuste_largo_plazo, @i_ctas_por_pagar_largo_plazo, 
        @i_vehiculo_negocio, @i_bienes_inmuebles_negocio,
        @i_deudas_buro_corto_plazo, @i_deudas_buro_largo_plazo, @i_cuota_buro, @i_deudas_enl_corto_plazo, @i_deudas_enl_largo_plazo,
        @i_cuota_enl)

     if @@rowcount = 0 
         begin 
            -- 'No fue posible registrar la operación'  
            exec cobis..sp_cerror 
                 @t_debug = @t_debug, 
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name, 
                 @i_num   = 1720297 
            rollback tran
      --return 1720297 
         end 
         
  commit tran 
end

--
if @i_operacion = 'S'
begin 
--  print 'tipo de operacion search' 
    --Comienza conjunto de validaciones 
  if @w_existe_cliente is null 
  begin 
    /* Parametro vacio */ 
    exec cobis..sp_cerror 
      @t_debug = @t_debug, 
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1720298
    return 1
  end
  --Obtener deudad de enlace
  exec cob_credito..sp_deudas_cli 
       @i_cliente = @i_cliente,
       @o_deuda_corto_plazo     = @w_enl_corto out,
       @o_deuda_largo_plazo     = @w_enl_largo out,
       @o_cuota_mensual         = @w_enl_cuota out
  --Obtener deudas de buro
  select  top 1 
          @w_buro_corto = saldo_corto_plazo,
          @w_buro_cuota = saldo_cuota,
          @w_buro_largo = saldo_largo_plazo
  from cob_credito..ts_creditbureau
  where ente = @i_cliente
  order by fecha desc 
  
  if exists(select 1 from cobis..cl_analisis_negocio 
  where an_cliente_id = @i_cliente 
  and an_negocio_codigo =  @i_codigo_negocio)
  begin
     select [an_ventas_prom_mes],
            [an_compras_prom_mes],
            [an_renta_neg],
            [an_transporte_neg],
            [an_personal_neg],
            [an_impuestos_neg],
            [an_electrica_neg], 
            [an_agua_neg],
            [an_telefono_neg],
            [an_otros_neg],
            [an_inventario],
            [an_inversion_neg],
            [an_frecuencia_inv],
            [an_presta],
            [an_frecuencia_cobro],
            [an_debe_prestamo],
            [an_cuota_pago],
            [an_frecuencia_pago], 
            [an_disponible],
            [an_ganancia_neg],
            [an_frecuencia_util],
            [an_capacidad_pago_mes],
            [an_producto], 
            [an_porcentaje_venta_regs],
            [an_valor_vivienda],
            [an_valor_negocio],
            [an_valor_vehiculo],
            [an_valor_mobiliario],
            [an_valor_otros],
            [an_ingresos_extra],
            [an_monto_extra],
            [an_origen_extra],
            [an_gastos_alimentos], 
            [an_gastos_renta_viv],
            [an_gastos_energia_elect],
            [an_gastos_agua],
            [an_gastos_telefono],
            [an_gastos_tv],
            [an_gastos_salud],
            [an_gastos_transp],
            [an_gastos_educ],
            [an_gastos_gas],
            [an_gastos_vestido], 
            [an_gastos_otros],
            [an_ctas_por_cobrar],
            [an_ajuste_deuda],
            an_valor_vehiculo2,
            an_valor_vivienda2,
            isnull(@w_enl_cuota , 0),
            isnull(@w_buro_cuota, 0),   
            isnull(@w_buro_largo, 0),
            isnull(@w_buro_corto, 0),  
            isnull(@w_enl_corto , 0),
            an_ctas_por_pagar_largo_plazo,
            isnull(@w_enl_largo, 0),
            'S'
     from cobis..cl_analisis_negocio 
     where an_cliente_id = @i_cliente 
     and an_negocio_codigo =  @i_codigo_negocio
  end
  else
  begin
     select null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            isnull(@w_enl_cuota , 0),
            isnull(@w_buro_cuota, 0),   
            isnull(@w_buro_largo, 0),
            isnull(@w_buro_corto, 0),  
            isnull(@w_enl_corto , 0),
            null,
            isnull(@w_enl_largo, 0),
            'N'
  end
  

end

--Actualizacion de buro en datos de analisis de negocio
if @i_operacion = 'B'
begin
  select  top 1 
          @w_buro_corto = saldo_corto_plazo,
          @w_buro_cuota = saldo_cuota,
          @w_buro_largo = saldo_largo_plazo
  from cob_credito..ts_creditbureau
  where ente = @i_cliente
  order by fecha desc 
  
  select  
  @w_buro_corto = isnull(@w_buro_corto, 0),
  @w_buro_cuota = isnull(@w_buro_cuota, 0),
  @w_buro_largo = isnull(@w_buro_largo, 0)
  
  
  begin tran
  insert into ts_analisis_negocio (an_tipo_transaccion, an_clase, an_secuencial, an_tabla, an_operacion, an_cliente_id
      , an_negocio_codigo, an_ventas_prom_mes, an_compras_prom_mes, an_renta_neg, an_transporte_neg, an_personal_neg
      , an_impuestos_neg, an_electrica_neg, an_agua_neg, an_telefono_neg, an_otros_neg, an_inventario
      , an_inversion_neg, an_presta, an_frecuencia_cobro, an_debe_prestamo, an_cuota_pago, an_frecuencia_pago
      , an_disponible, an_ganancia_neg, an_frecuencia_util, an_capacidad_pago_mes, an_producto, an_porcentaje_venta_regs
      , an_valor_vivienda, an_valor_negocio, an_valor_vehiculo, an_valor_mobiliario, an_valor_otros, an_ingresos_extra
      , an_monto_extra, an_origen_extra, an_gastos_alimentos, an_gastos_renta_viv, an_gastos_energia_elect, an_gastos_agua
      , an_gastos_telefono, an_gastos_tv, an_gastos_salud, an_gastos_transp, an_gastos_educ, an_gastos_gas
      , an_gastos_vestido, an_gastos_otros, an_ctas_por_cobrar, an_frecuencia_inv, [an_ctas_por_pagar_largo_plazo], 
        an_ajuste_deuda, an_valor_vehiculo2, an_valor_vivienda2,
        an_deuda_corto_buro,  an_deuda_largo_buro, an_cuota_pago_buro, an_deuda_corto_enlace, an_deuda_largo_enlace, 
        an_cuota_pago_enlace)
   select @t_trn, 'P', isnull(@s_ssn, 1), 'cl_analisis_negocio', @i_operacion, an_cliente_id
      , an_negocio_codigo, an_ventas_prom_mes, an_compras_prom_mes, an_renta_neg, an_transporte_neg, an_personal_neg
      , an_impuestos_neg, an_electrica_neg, an_agua_neg, an_telefono_neg, an_otros_neg, an_inventario
      , an_inversion_neg, an_presta, an_frecuencia_cobro, an_debe_prestamo, an_cuota_pago, an_frecuencia_pago
      , an_disponible, an_ganancia_neg, an_frecuencia_util, an_capacidad_pago_mes, an_producto, an_porcentaje_venta_regs
      , an_valor_vivienda, an_valor_negocio, an_valor_vehiculo, an_valor_mobiliario, an_valor_otros, an_ingresos_extra
      , an_monto_extra, an_origen_extra, an_gastos_alimentos, an_gastos_renta_viv, an_gastos_energia_elect, an_gastos_agua
      , an_gastos_telefono, an_gastos_tv, an_gastos_salud, an_gastos_transp, an_gastos_educ, an_gastos_gas
      , an_gastos_vestido, an_gastos_otros, an_ctas_por_cobrar, an_frecuencia_inv, [an_ctas_por_pagar_largo_plazo], 
        an_ajuste_deuda, an_valor_vehiculo2, an_valor_vivienda2,
        @w_buro_corto,  @w_buro_largo, @w_buro_cuota, an_deuda_corto_enlace, an_deuda_largo_enlace, 
        an_cuota_pago_enlace
    from cobis..cl_analisis_negocio
    where an_negocio_codigo = @i_codigo_negocio
    and an_cliente_id = @i_cliente

    if @@error <> 0
    begin 
        -- 'No fue posible registrar la operación' 
        exec cobis..sp_cerror 
                @t_debug = @t_debug, 
                @t_file  = @t_file, 
                @t_from  = @w_sp_name, 
                @i_num   = 1720297 
        rollback tran
    end
  
  update cobis..cl_analisis_negocio
  set   an_cuota_pago_buro  = @w_buro_cuota,
        an_deuda_corto_buro = @w_buro_corto,
        an_deuda_largo_buro = @w_buro_largo
  where an_negocio_codigo = @i_codigo_negocio
  and an_cliente_id = @i_cliente
  
  if @@error <> 0
  begin 
     /* 'No fue posible actualizar la operación' */ 
     exec cobis..sp_cerror 
          @t_debug = @t_debug, 
          @t_file  = @t_file, 
          @t_from  = @w_sp_name, 
          @i_num   = 1720297 
     rollback tran
  end
  
  insert into ts_analisis_negocio (an_tipo_transaccion, an_clase, an_secuencial, an_tabla, an_operacion, an_cliente_id
      , an_negocio_codigo, an_ventas_prom_mes, an_compras_prom_mes, an_renta_neg, an_transporte_neg, an_personal_neg
      , an_impuestos_neg, an_electrica_neg, an_agua_neg, an_telefono_neg, an_otros_neg, an_inventario
      , an_inversion_neg, an_presta, an_frecuencia_cobro, an_debe_prestamo, an_cuota_pago, an_frecuencia_pago
      , an_disponible, an_ganancia_neg, an_frecuencia_util, an_capacidad_pago_mes, an_producto, an_porcentaje_venta_regs
      , an_valor_vivienda, an_valor_negocio, an_valor_vehiculo, an_valor_mobiliario, an_valor_otros, an_ingresos_extra
      , an_monto_extra, an_origen_extra, an_gastos_alimentos, an_gastos_renta_viv, an_gastos_energia_elect, an_gastos_agua
      , an_gastos_telefono, an_gastos_tv, an_gastos_salud, an_gastos_transp, an_gastos_educ, an_gastos_gas
      , an_gastos_vestido, an_gastos_otros, an_ctas_por_cobrar, an_frecuencia_inv, [an_ctas_por_pagar_largo_plazo], 
        an_ajuste_deuda, an_valor_vehiculo2, an_valor_vivienda2,
        an_deuda_corto_buro,  an_deuda_largo_buro, an_cuota_pago_buro, an_deuda_corto_enlace, an_deuda_largo_enlace, 
        an_cuota_pago_enlace)
   select @t_trn, 'A', isnull(@s_ssn, 1), 'cl_analisis_negocio', @i_operacion, an_cliente_id
      , an_negocio_codigo, an_ventas_prom_mes, an_compras_prom_mes, an_renta_neg, an_transporte_neg, an_personal_neg
      , an_impuestos_neg, an_electrica_neg, an_agua_neg, an_telefono_neg, an_otros_neg, an_inventario
      , an_inversion_neg, an_presta, an_frecuencia_cobro, an_debe_prestamo, an_cuota_pago, an_frecuencia_pago
      , an_disponible, an_ganancia_neg, an_frecuencia_util, an_capacidad_pago_mes, an_producto, an_porcentaje_venta_regs
      , an_valor_vivienda, an_valor_negocio, an_valor_vehiculo, an_valor_mobiliario, an_valor_otros, an_ingresos_extra
      , an_monto_extra, an_origen_extra, an_gastos_alimentos, an_gastos_renta_viv, an_gastos_energia_elect, an_gastos_agua
      , an_gastos_telefono, an_gastos_tv, an_gastos_salud, an_gastos_transp, an_gastos_educ, an_gastos_gas
      , an_gastos_vestido, an_gastos_otros, an_ctas_por_cobrar, an_frecuencia_inv, [an_ctas_por_pagar_largo_plazo], 
        an_ajuste_deuda, an_valor_vehiculo2, an_valor_vivienda2,
        an_deuda_corto_buro,  an_deuda_largo_buro, an_cuota_pago_buro, an_deuda_corto_enlace, an_deuda_largo_enlace, 
        an_cuota_pago_enlace
    from cobis..cl_analisis_negocio
    where an_negocio_codigo = @i_codigo_negocio
    and an_cliente_id = @i_cliente
    
    
   if @@error <> 0 
   begin 
     /* 'No fue posible actualizar la operación' */ 
     exec cobis..sp_cerror 
          @t_debug = @t_debug, 
          @t_file  = @t_file, 
          @t_from  = @w_sp_name, 
          @i_num   = 1720297 
     rollback tran
     return 1720297 
   end
  
  commit tran
  
end


select @w_sincroniza = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'HASIAU'

select @w_ofi_app = pa_smallint 
from cobis.dbo.cl_parametro cp 
where cp.pa_nemonico = 'OFIAPP'
and cp.pa_producto = 'CRE'

--Proceso de sincronizacion Clientes
if @i_operacion in ('I', 'U') and @i_cliente is not null and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
begin
   exec @w_error = cob_sincroniza..sp_sinc_arch_json
      @i_opcion     = 'I',
      @i_cliente    = @i_cliente,
      @t_debug      = @t_debug
   if @w_error <> 0 and @w_error is not null
   begin 
     exec cobis..sp_cerror 
       @t_debug = @t_debug, 
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = @w_error
     return @w_error
   end
end

return 0
--FIN DEL PROCEDIMIENTO ALMACENADO
GO
