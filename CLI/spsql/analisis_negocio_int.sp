/************************************************************************/
/*  Archivo:                analisis_negocio_int.sp                     */
/*  Stored procedure:       sp_analisis_negocio_int                     */
/*  Producto:               Clientes                                    */
/*  Disenado por:           Bruno Duenas                                */
/*  Fecha de escritura:     03-09-2021                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_analisis_negocio                        */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA       AUTOR           RAZON                                   */
/*  03-09-2021  BDU             Emision inicial                         */
/*  10-09-2021  ACA             Operacion S, validaciones negativos y 0 */
/************************************************************************/


use cob_interface
GO
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
if exists (select 1 from sysobjects where name = 'sp_analisis_negocio_int')
   drop proc sp_analisis_negocio_int
go

create proc sp_analisis_negocio_int (
@s_culture                                   varchar(10) = 'NEUTRAL',
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
@i_ctas_por_cobrar                           money       = null,
@i_ctas_por_pagar_largo_plazo                money       = null
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_oficial               int,
        @w_trn_dir               int,
        @w_error                 int,
        @w_operacion             char(1),
        @w_existente             bit,
        @w_init_msg_error        varchar(256),
        @w_valor_campo           varchar(30)
        
/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_analisis_negocio_int',
@w_operacion        = '',
@w_error            = 1720548

   
/* VALIDACIONES */

/* NUMERO DE TRANSACCION */
if @t_trn <> 172204 
begin 
   /* Tipo de transaccion no corresponde */ 
   select @w_error = 1720275 
   goto ERROR_FIN
end

/* CAMPOS REQUERIDOS */
if (@i_operacion in ('I','U'))
begin
   if isnull(@i_cliente,'') = '' and @i_cliente <> 0
   begin
	  select @w_valor_campo  = 'personSequential'
      goto VALIDAR_ERROR   
   end

   if isnull(@i_codigo_negocio,'') = '' and @i_codigo_negocio <> 0
   begin
	  select @w_valor_campo  = 'businessSequential'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_ventas_prom_mes,'') = '' and @i_ventas_prom_mes <> 0
   begin
	  select @w_valor_campo  = 'averageSales'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_compras_prom_mes,'') = '' and @i_compras_prom_mes <> 0
   begin
	  select @w_valor_campo  = 'averageAcquirement'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_renta_neg,'') = '' and @i_renta_neg <> 0
   begin
	  select @w_valor_campo  = 'rentExpenses'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_transporte_neg,'') = '' and @i_transporte_neg <> 0
   begin
	  select @w_valor_campo  = 'transportExpenses'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_personal_neg,'') = '' and @i_personal_neg <> 0
   begin
	  select @w_valor_campo  = 'personalExpenses'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_impuestos_neg,'') = '' and @i_impuestos_neg <> 0
   begin
	  select @w_valor_campo  = 'taxes'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_electrica_neg,'') = '' and @i_electrica_neg <> 0
   begin
	  select @w_valor_campo  = 'electricExpenses'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_agua_neg,'') = '' and @i_agua_neg <> 0
   begin
	  select @w_valor_campo  = 'waterExpenses'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_telefono_neg,'') = '' and @i_telefono_neg <> 0
   begin
	  select @w_valor_campo  = 'telephoneExpenses'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_otros_neg,'') = '' and @i_otros_neg <> 0
   begin
	  select @w_valor_campo  = 'othersExpenses'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_inventario,'') = '' and @i_inventario <> 0
   begin
	  select @w_valor_campo  = 'stockQtty'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_inversion_neg,'') = '' and @i_inversion_neg <> 0
   begin
	  select @w_valor_campo  = 'businessInvestment'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_frecuencia_inv,'') = '' 
   begin
	  select @w_valor_campo  = 'investmentFrequency'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_presta,'') = '' 
   begin
	  select @w_valor_campo  = 'lender'
      goto VALIDAR_ERROR   
   end
   
   if ((isnull(@i_ctas_por_cobrar,'') = '' and @i_ctas_por_cobrar <> 0) and @i_presta = 'S') 
   begin
	  select @w_valor_campo  = 'receivable'
      goto VALIDAR_ERROR   
   end
   
   if (isnull(@i_frecuencia_cobro,'') = '' and @i_presta = 'S') 
   begin
	  select @w_valor_campo  = 'frecuencyPayIn'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_debe_prestamo,'') = '' 
   begin
	  select @w_valor_campo  = 'debtLoan'
      goto VALIDAR_ERROR   
   end
   
   if (isnull(@i_ctas_por_pagar_largo_plazo,'') = '' and @i_ctas_por_pagar_largo_plazo <> 0 and @i_debe_prestamo = 'S') 
   begin
	  select @w_valor_campo  = 'payOutTerm'
      goto VALIDAR_ERROR   
   end
   
   if (isnull(@i_cuota_pago,'') = '' and @i_cuota_pago <> 0 and @i_debe_prestamo = 'S') 
   begin
	  select @w_valor_campo  = 'payQuota'
      goto VALIDAR_ERROR   
   end
   
   if (isnull(@i_frecuencia_pago,'') = '' and @i_debe_prestamo = 'S') 
   begin
	  select @w_valor_campo  = 'frecuencyPayOut'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_disponible,'') = '' and @i_disponible <> 0
   begin
	  select @w_valor_campo  = 'availableCash'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_ganancia_neg,'') = '' and @i_ganancia_neg <> 0
   begin
	  select @w_valor_campo  = 'profitDeal'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_frecuencia_utilidad,'') = 'utilityFrecuency' 
   begin
	  select @w_valor_campo  = ''
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_capacidad_pago_mes,'') = '' and @i_capacidad_pago_mes <> 0
   begin
	  select @w_valor_campo  = 'paymentCapacity'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_producto,'') = '' 
   begin
	  select @w_valor_campo  = 'product'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_porcentaje_venta_regs,'') = '' and @i_porcentaje_venta_regs <> 0
   begin
	  select @w_valor_campo  = 'salePercentage'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_valor_vivienda,'') = '' and @i_valor_vivienda <> 0
   begin
	  select @w_valor_campo  = 'residenceValue'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_valor_negocio,'') = '' and @i_valor_negocio <> 0
   begin
	  select @w_valor_campo  = 'businessValue'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_valor_vehiculo,'') = '' and @i_valor_vehiculo <> 0
   begin
	  select @w_valor_campo  = 'vehicleValue'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_valor_mobiliario,'') = '' and @i_valor_mobiliario <> 0
   begin
	  select @w_valor_campo  = 'appointmentsValues'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_valor_otros,'') = '' and @i_valor_otros <> 0
   begin
	  select @w_valor_campo  = 'otherValues'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_ingresos_extra,'') = ''
   begin
	  select @w_valor_campo  = 'extraIncome'
      goto VALIDAR_ERROR   
   end
   
   if (isnull(@i_monto_extra,'') = '' and @i_monto_extra <> 0 and @i_ingresos_extra = 'S')
   begin
	  select @w_valor_campo  = 'extraIncomeValue'
      goto VALIDAR_ERROR   
   end
   
   if (isnull(@i_origen_extra,'') = '' and @i_ingresos_extra = 'S')
   begin
	  select @w_valor_campo  = 'extraIncomeSource'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_alimentacion,'') = '' and @i_gastos_alimentacion <> 0
   begin
	  select @w_valor_campo  = 'feeding'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_renta_viv,'') = '' and @i_gastos_renta_viv <> 0
   begin
	  select @w_valor_campo  = 'residenceRent'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_energia_elec,'') = '' and @i_gastos_energia_elec <> 0
   begin
	  select @w_valor_campo  = 'electricalEnergy'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_agua,'') = '' and @i_gastos_agua <> 0
   begin
	  select @w_valor_campo  = 'waterService'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_telefono,'') = '' and @i_gastos_telefono <> 0
   begin
	  select @w_valor_campo  = 'telephoneService'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_tv,'') = '' and @i_gastos_tv <> 0
   begin
	  select @w_valor_campo  = 'tvService'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_salud,'') = '' and @i_gastos_salud <> 0
   begin
	  select @w_valor_campo  = 'health'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_transporte,'') = '' and @i_gastos_transporte <> 0
   begin
	  select @w_valor_campo  = 'familyTransport'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_educacion,'') = '' and @i_gastos_educacion <> 0
   begin
	  select @w_valor_campo  = 'education'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_gas,'') = '' and @i_gastos_gas <> 0
   begin
	  select @w_valor_campo  = 'gasService'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_vestido,'') = '' and @i_gastos_vestido <> 0
   begin
	  select @w_valor_campo  = 'clothing'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gastos_otros,'') = '' and @i_gastos_otros <> 0
   begin
	  select @w_valor_campo  = 'otherDebts'
      goto VALIDAR_ERROR   
   end
   /* CAMPOS NEGATIVOS */
   select @w_error = 1720556
   if (@i_cliente) < 0
   begin
      select @w_valor_campo = 'personSequential'
      goto VALIDAR_ERROR
   end

 if (@i_codigo_negocio) < 0
   begin
      select @w_valor_campo = 'businessSequential'
      goto VALIDAR_ERROR
   end
   if (@i_ventas_prom_mes) < 0
   begin
      select @w_valor_campo = 'averageSales'
      goto VALIDAR_ERROR
   end
   if (@i_compras_prom_mes) < 0
   begin
      select @w_valor_campo = 'averageAcquirement'
      goto VALIDAR_ERROR
   end
   if (@i_renta_neg) < 0
   begin
      select @w_valor_campo = 'rentExpenses'
      goto VALIDAR_ERROR
   end
   if (@i_transporte_neg) < 0
   begin
      select @w_valor_campo = 'transportExpenses'
      goto VALIDAR_ERROR
   end
   if (@i_personal_neg) < 0
   begin
      select @w_valor_campo = 'personalExpenses'
      goto VALIDAR_ERROR
   end
   if (@i_impuestos_neg) < 0
   begin
      select @w_valor_campo = 'taxes'
      goto VALIDAR_ERROR
   end
   if (@i_electrica_neg) < 0
   begin
      select @w_valor_campo = 'electricExpenses'
      goto VALIDAR_ERROR
   end
   if (@i_agua_neg) < 0
   begin
      select @w_valor_campo = 'waterExpenses'
      goto VALIDAR_ERROR
   end
   if (@i_telefono_neg) < 0
   begin
      select @w_valor_campo = 'telephoneExpenses'
      goto VALIDAR_ERROR
   end
   if (@i_otros_neg) < 0
   begin
      select @w_valor_campo = 'othersExpenses'
      goto VALIDAR_ERROR
   end
   if (@i_inventario) < 0
   begin
      select @w_valor_campo = 'stockQtty'
      goto VALIDAR_ERROR
   end
   if (@i_inversion_neg) < 0
   begin
      select @w_valor_campo = 'businessInvestment'
      goto VALIDAR_ERROR
   end
   if (((@i_ctas_por_cobrar) < 0) and @i_presta = 'S')
   begin
      select @w_valor_campo = 'receivable'
      goto VALIDAR_ERROR
   end
   if ((@i_ctas_por_pagar_largo_plazo) < 0 and @i_debe_prestamo = 'S')
   begin
      select @w_valor_campo = 'payOutTerm'
      goto VALIDAR_ERROR
   end
   if ((@i_cuota_pago) < 0 and @i_debe_prestamo = 'S')
   begin
      select @w_valor_campo = 'payQuota'
      goto VALIDAR_ERROR
   end
   if (@i_disponible) < 0
   begin
      select @w_valor_campo = 'availableCash'
      goto VALIDAR_ERROR
   end
   if (@i_ganancia_neg) < 0
   begin
      select @w_valor_campo = 'profitDeal'
      goto VALIDAR_ERROR
   end
   if (@i_capacidad_pago_mes) < 0
   begin
      select @w_valor_campo = 'paymentCapacity'
      goto VALIDAR_ERROR
   end
   if (@i_porcentaje_venta_regs) < 0
   begin
      select @w_valor_campo = 'salePercentage'
      goto VALIDAR_ERROR
   end
   if (@i_valor_vivienda) < 0
   begin
      select @w_valor_campo = 'residenceValue'
      goto VALIDAR_ERROR
   end
   if (@i_valor_negocio) < 0
   begin
      select @w_valor_campo = 'businessValue'
      goto VALIDAR_ERROR
   end
   if (@i_valor_vehiculo) < 0
   begin
      select @w_valor_campo = 'vehicleValue'
      goto VALIDAR_ERROR
   end
   if (@i_valor_mobiliario) < 0
   begin
      select @w_valor_campo = 'appointmentsValues'
      goto VALIDAR_ERROR
   end
   if (@i_valor_otros) < 0
   begin
      select @w_valor_campo = 'otherValues'
      goto VALIDAR_ERROR
   end
   if ((@i_monto_extra) < 0 and @i_ingresos_extra = 'S')
   begin
      select @w_valor_campo = 'extraIncomeValue'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_alimentacion) < 0
   begin
      select @w_valor_campo = 'feeding'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_renta_viv) < 0
   begin
      select @w_valor_campo = 'residenceRent'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_energia_elec) < 0
   begin
      select @w_valor_campo = 'electricalEnergy'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_agua) < 0
   begin
      select @w_valor_campo = 'waterService'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_telefono) < 0
   begin
      select @w_valor_campo = 'telephoneService'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_tv) < 0
   begin
      select @w_valor_campo = 'tvService'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_salud) < 0
   begin
      select @w_valor_campo = 'health'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_transporte) < 0
   begin
      select @w_valor_campo = 'familyTransport'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_educacion) < 0
   begin
      select @w_valor_campo = 'education'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_gas) < 0
   begin
      select @w_valor_campo = 'gasService'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_vestido) < 0
   begin
      select @w_valor_campo = 'clothing'
      goto VALIDAR_ERROR
   end
   if (@i_gastos_otros) < 0
   begin
      select @w_valor_campo = 'otherDebts'
      goto VALIDAR_ERROR
   end
   
   /* VALIDAR QUE EL CLIENTE EXISTA */
   
   if not exists(select 1 from cobis..cl_ente where en_ente = @i_cliente)
   begin
      select @w_error = 1720411 
	  goto ERROR_FIN 
   end   
   
   /* VALIDAR QUE EL NEGOCIO EXISTA */
   
   if not exists(select 1 from cobis..cl_negocio_cliente where nc_codigo = @i_codigo_negocio and nc_ente = @i_cliente)
   begin
      select @w_error = 1720285 
	  goto ERROR_FIN 
   end  

   /* VALIDAR QUE EL ANALISIS EXISTA */

   if @i_operacion = 'U' and not exists(select 1 from cobis..cl_analisis_negocio 
      where an_negocio_codigo = @i_codigo_negocio and an_cliente_id = @i_cliente)
   begin
      select @w_error = 1720554 
      goto ERROR_FIN 
   end
 
   -- VALIDACIONES DE CATALOGOS           
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_frecuencia', @i_valor = @i_frecuencia_inv          
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_frecuencia_inv         
	  select @w_error = 1720552 
	  goto VALIDAR_ERROR 
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_frecuencia', @i_valor = @i_frecuencia_cobro          
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_frecuencia_cobro         
	  select @w_error = 1720552 
	  goto VALIDAR_ERROR 
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_frecuencia', @i_valor = @i_frecuencia_pago          
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_frecuencia_pago         
	  select @w_error = 1720552 
	  goto VALIDAR_ERROR 
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_frecuencia', @i_valor = @i_frecuencia_utilidad          
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_frecuencia_utilidad         
	  select @w_error = 1720552 
	  goto VALIDAR_ERROR 
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_fuente_ingreso', @i_valor = @i_origen_extra          
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_origen_extra         
	  select @w_error = 1720552 
	  goto VALIDAR_ERROR 
   end


   /* FIN VALIDACIONES */
   if @i_operacion = 'I'
   begin
      set @t_trn = 172083
   end
   else if @i_operacion = 'U'
   begin
      set @t_trn = 172100
   end
   exec @w_error = cobis..sp_analisis_negocio
   @s_ssn                        = @s_ssn,       
   @s_srv                        = @s_srv,       
   @s_date                       = @s_date,       
   @s_user                       = @s_user,       
   @s_ofi                        = @s_ofi,       
   @t_debug                      = @t_debug,       
   @t_file                       = @t_file,       
   @t_trn                        = @t_trn,       
   @t_show_version               = @t_show_version,       
   @i_operacion                  = @i_operacion,       
   @i_cliente                    = @i_cliente,       
   @i_codigo_negocio             = @i_codigo_negocio,       
   @i_ventas_prom_mes            = @i_ventas_prom_mes,       
   @i_compras_prom_mes           = @i_compras_prom_mes,       
   @i_renta_neg                  = @i_renta_neg,       
   @i_transporte_neg             = @i_transporte_neg,       
   @i_personal_neg               = @i_personal_neg,       
   @i_impuestos_neg              = @i_impuestos_neg,       
   @i_electrica_neg              = @i_electrica_neg,       
   @i_agua_neg                   = @i_agua_neg,       
   @i_telefono_neg               = @i_telefono_neg,       
   @i_otros_neg                  = @i_otros_neg,       
   @i_inventario                 = @i_inventario,       
   @i_inversion_neg              = @i_inversion_neg,       
   @i_frecuencia_inv             = @i_frecuencia_inv,       
   @i_presta                     = @i_presta,       
   @i_frecuencia_cobro           = @i_frecuencia_cobro,       
   @i_debe_prestamo              = @i_debe_prestamo,       
   @i_cuota_pago                 = @i_cuota_pago,       
   @i_frecuencia_pago            = @i_frecuencia_pago,       
   @i_disponible                 = @i_disponible,       
   @i_ganancia_neg               = @i_ganancia_neg,       
   @i_frecuencia_utilidad        = @i_frecuencia_utilidad,       
   @i_capacidad_pago_mes         = @i_capacidad_pago_mes,       
   @i_producto                   = @i_producto,       
   @i_porcentaje_venta_regs      = @i_porcentaje_venta_regs,       
   @i_valor_vivienda             = @i_valor_vivienda,       
   @i_valor_negocio              = @i_valor_negocio,       
   @i_valor_vehiculo             = @i_valor_vehiculo,       
   @i_valor_mobiliario           = @i_valor_mobiliario,       
   @i_valor_otros                = @i_valor_otros,       
   @i_ingresos_extra             = @i_ingresos_extra,       
   @i_monto_extra                = @i_monto_extra,       
   @i_origen_extra               = @i_origen_extra,       
   @i_gastos_alimentacion        = @i_gastos_alimentacion,       
   @i_gastos_renta_viv           = @i_gastos_renta_viv,       
   @i_gastos_energia_elec        = @i_gastos_energia_elec,       
   @i_gastos_agua                = @i_gastos_agua,       
   @i_gastos_telefono            = @i_gastos_telefono,       
   @i_gastos_tv                  = @i_gastos_tv,       
   @i_gastos_salud               = @i_gastos_salud,       
   @i_gastos_transporte          = @i_gastos_transporte,       
   @i_gastos_educacion           = @i_gastos_educacion,       
   @i_gastos_gas                 = @i_gastos_gas,       
   @i_gastos_vestido             = @i_gastos_vestido,       
   @i_gastos_otros               = @i_gastos_otros,       
   @i_ctas_por_cobrar            = @i_ctas_por_cobrar,       
   @i_ctas_por_pagar_largo_plazo = @i_ctas_por_pagar_largo_plazo 

end -- fin validaciones insert and update
   
 

if (@i_operacion = 'S') 
begin
   if isnull(@i_cliente,'') = '' and @i_cliente <> 0
   begin
	  select @w_valor_campo  = 'personSequential'
      goto VALIDAR_ERROR   
   end

   if isnull(@i_codigo_negocio,'') = '' and @i_codigo_negocio <> 0
   begin
	  select @w_valor_campo  = 'businessSequential'
      goto VALIDAR_ERROR   
   end

   exec cobis..sp_analisis_negocio
   @t_trn = 172101,
   @i_operacion = @i_operacion,
   @i_cliente = @i_cliente,
   @i_codigo_negocio = @i_codigo_negocio

   if @@rowcount=0
   begin
      select @w_error = 1720289
	   goto ERROR_FIN
   end

   return 0
end
   
if @w_error <> 0
begin   
   goto ERROR_FIN 
end
return 0


VALIDAR_ERROR:
select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo , @w_error, @s_culture)
goto ERROR_FIN


ERROR_FIN:

exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_msg      = @w_sp_msg,
         @i_num      = @w_error
         
return @w_error

go
