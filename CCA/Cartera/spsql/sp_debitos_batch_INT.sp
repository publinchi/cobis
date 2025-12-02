/************************************************************************/
/*      Archivo:                sp_debitos_batch_INT.sp                 */
/*      Stored procedure:       sp_debitos_batch_INT                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sandro Vallejo                          */
/*      Fecha de escritura:     AGO 2020                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes exclusivos para el Ecuador de la       */
/*      'NCR CORPORATION'.                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Proceso Paralelo de debitos automáticos para operaciones        */
/*      de cartera, procesa por hilo                                    */
/************************************************************************/
/*                              MODIFICACIONES                          */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_debitos_batch_INT')
   drop proc sp_debitos_batch_INT
go
create procedure sp_debitos_batch_INT
(
 @s_user          varchar(14),
 @s_term          varchar(30),
 @s_date          datetime,
 @s_sesn          int,
 @s_ssn           int     = null,
 @i_fecha_proceso datetime,
 @i_tipo          char(1) = 'F',  -- 'I=Intento en Linea  F=En Batch
 @i_hilo          tinyint         -- numero de hilos a generar o hilo que debe procesar
)
as

declare
   @w_sp_name            descripcion,
   @w_error              int,
   @w_rollback           char(1),
   @w_cont               smallint,
   @w_detener_proceso    char(1),
   @w_operacionca        int,
   @w_fecha_ult_proceso  datetime,
   @w_banco              char(24),
   @w_sp_name_error      descripcion,
   @w_op_oficina         int,
   @w_op_moneda          tinyint,
   @w_fecha_pag          datetime,
   @w_num_dec            tinyint,
   @w_moneda_nacional    tinyint,
   @w_decimales_nacional tinyint,
   @w_rowcount           int,
   @w_cotizacion_hoy     money,
   @w_op_forma_pago      char(10),
   @w_op_cuenta          char(24),
   @w_tipo_grupal        char(1)

select 
@w_sp_name          = 'sp_debitos_batch_INT',
@w_detener_proceso  = 'N',
@w_error            = 0

/* CODIGO DE LA MONEDA LOCAL */
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

select @w_rowcount = @@rowcount
 
if @w_rowcount = 0 
begin
   select @w_error = 708174
   goto ERROR_BATCH
end

/* DECIMALES DE LA MONEDA NACIONAL */
exec @w_error   = sp_decimales
@i_moneda       = @w_moneda_nacional,
@o_decimales    = @w_num_dec out,
@o_dec_nacional = @w_decimales_nacional out
         
if @w_error <> 0 goto ERROR_BATCH

/* PROCESAR LAZO DE OPERACIONES */
while @w_detener_proceso = 'N' 
begin
   
   /* INICIALIZAR VARIABLES */
   select 
   @w_sp_name_error = 'sp_debitos_batch_INT',
   @w_rollback      = 'S',
   @w_error         = 0

   /* SELECCIONAR OPERACION */
   set rowcount 1

   select @w_operacionca = operacion
   from   ca_universo_debitos with (nolock)
   where  hilo     = @i_hilo 
   and   intentos < 2
   order by id 
      
   if @@rowcount = 0 
   begin
      set rowcount 0
      select @w_detener_proceso = 'S'--LPO Nuevo Esquema de Paralelismo
      break
   end
      
   set rowcount 0

   /* ATOMICIDAD DE UNIVERSO */
   BEGIN TRAN
   
   update ca_universo_debitos set 
   intentos = intentos + 1, 
   hilo     = 100 -- significa Procesado o procesando 
   where operacion = @w_operacionca 
   and   hilo      = @i_hilo 

   COMMIT TRAN
   
   /* PROCESAR OPERACION */
   select  
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
   @w_banco             = op_banco,
   @w_op_oficina        = op_oficina,
   @w_op_moneda         = op_moneda,
   @w_op_forma_pago     = op_forma_pago,
   @w_op_cuenta         = op_cuenta
   from  ca_operacion
   where op_operacion = @w_operacionca

   /* ATOMICIDAD POR OPERACION */
   BEGIN TRAN
   
   /* DETERMINAR SI LA OPERACION CORRESPONDE A INTERCICLO - GRUPAL - INDIVIDUAL */
   exec @w_error = sp_tipo_operacion
   @i_banco      = @w_banco,
   @o_tipo       = @w_tipo_grupal out

   if @w_error <> 0 goto ERROR
   
   /* DETERMINAR EL NUMERO DE DECIMALES CON QUE TRABAJAR */
   if @w_op_moneda = @w_moneda_nacional 
      select 
      @w_num_dec        = @w_decimales_nacional,
      @w_cotizacion_hoy = 1.0
   else 
   begin
      exec @w_error = sp_decimales
      @i_moneda     = @w_op_moneda,
      @o_decimales  = @w_num_dec out
         
      if @w_error <> 0 goto ERROR
      
      exec @w_error = sp_buscar_cotizacion
      @i_moneda     = @w_op_moneda,
      @i_fecha      = @i_fecha_proceso,
      @o_cotizacion = @w_cotizacion_hoy OUTPUT
      
      if @w_error <> 0 goto ERROR
   end

   /* Detectar si la Operaciones tiene Pagos de recaudo pendientes con fecha valor */
   select @w_fecha_pag = isnull(min(ab_fecha_pag), '12/31/2200')
   from   ca_abono with (nolock)
   where  ab_operacion  = @w_operacionca
   and    ab_estado    in ('ING', 'NA') 
   
   /* SI LA OPERACION TIENE PAGOS PENDIENTES Y ES I=Intento en Linea - CONTINUA CON SIGUIENTE OPERACION */
   if @i_tipo = 'I' and @w_fecha_pag < @w_fecha_ult_proceso 
      goto SIGUIENTE
   
   /* SI LA OPERACION ES I=Intento en Linea Y LA FECHA DE PROCESO ES DIFERENTE A LA DEL SISTEMA */
   /* CONTINUA CON SIGUIENTE OPERACION */   
   if @i_tipo = 'I' and @w_fecha_ult_proceso <> @i_fecha_proceso
      goto SIGUIENTE
   
   /* SI LA OPERACION TIENE PAGOS PENDIENTES Y ES F=En Batch */
   if @i_tipo = 'F' and @w_fecha_pag < @w_fecha_ult_proceso 
   begin 
      exec @s_ssn = ADMIN...rp_ssn   --LPO TEC sp_fecha_valor necesita el @s_ssn

      exec @w_error = sp_fecha_valor  
      @s_ssn               = @s_ssn, --LPO TEC sp_fecha_valor necesita el @s_ssn
      @s_date              = @s_date,
      @s_user              = @s_user,
      @s_term              = @s_term,
      @i_fecha_valor       = @w_fecha_pag,
      @i_banco             = @w_banco,
      @i_operacion         = 'F',
      @i_observacion       = 'Recaudo',
      @i_observacion_corto = 'Recaudo',
      @i_en_linea          = 'N'
      
      if @w_error <> 0 
      begin
         select 
         @w_sp_name_error = 'sp_fecha_valor',
         @w_rollback      = 'N'
         goto ERROR 
      end   

      /* ACTUALIZAR EL DATO DE LA FECHA DE PROCESO DE LA OPERACION */      
      select @w_fecha_ult_proceso = op_fecha_ult_proceso
      from  ca_operacion
      where op_operacion = @w_operacionca
   end         

   /* SI LA OPERACION ES F=En Batch Y LA FECHA DE PROCESO ES DIFERENTE A LA DEL SISTEMA */
   /* TRAER LA OPERACION HASTA LA FECHA DEL SISTEMA */   
   if @i_tipo = 'F' and @w_fecha_ult_proceso <> @i_fecha_proceso
   begin
      exec @s_ssn = ADMIN...rp_ssn   --LPO TEC sp_fecha_valor necesita el @s_ssn

      exec @w_error = sp_fecha_valor  
      @s_ssn               = @s_ssn, --LPO TEC sp_fecha_valor necesita el @s_ssn
      @s_date              = @s_date,
      @s_user              = @s_user,
      @s_term              = @s_term,
      @i_fecha_valor       = @i_fecha_proceso,
      @i_banco             = @w_banco,
      @i_operacion         = 'F',
      @i_observacion       = 'Recaudo',
      @i_observacion_corto = 'Recaudo',
      @i_en_linea          = 'N'
      
      if @w_error <> 0 
      begin
         select 
         @w_sp_name_error = 'sp_fecha_valor',
         @w_rollback      = 'N'
         goto ERROR 
      end   
   
      /* EL FECHA VALOR GENERA Y APLICA EL DEBITO */
      /* POR TANTO VA A LA SIGUIENTE OPERACION    */
      goto SIGUIENTE
      
   end

   /* GENERAR EL DEBITO AUTOMATICO */
   exec @w_error = sp_genera_afect_productos
   @s_user               = @s_user,
   @s_term               = @s_term,
   @s_ofi                = @w_op_oficina,
   @s_sesn               = @s_sesn,
   @s_date               = @s_date,
   @i_debug              = 'N',
   @i_fecha_proceso      = @i_fecha_proceso,
   @i_num_dec            = @w_num_dec,
   @i_cotizacion         = @w_cotizacion_hoy,
   @i_operacionca        = @w_operacionca,  
   @i_en_linea           = 'N',
   @i_forma_pago         = @w_op_forma_pago,
   @i_cuenta             = @w_op_cuenta,
   @i_tipo_grupal        = @w_tipo_grupal --LPO TEC Se envía el tipo porque cuando sea G solo debe crear el abono pero no realizar el pago.

   if @w_error <> 0 goto ERROR 

   /* DETERMINAR SI EXISTE DEBITOS POR APLICAR */
   if exists (select 1
              from   ca_abono with (nolock), ca_abono_det (nolock)
              where  ab_operacion      = @w_operacionca
	          and    ab_fecha_pag      = @i_fecha_proceso
	          and    ab_operacion      = abd_operacion
	          and    ab_secuencial_ing = abd_secuencial_ing
	          and    ab_cuota_completa = 'S'
              and    ab_estado        in ('ING','P','NA')
              AND    abd_beneficiario  = 'DB.AUT'
              AND    abd_monto_mpg     > 0)
   begin            
      exec @w_error = sp_abonos_batch
      @s_user          = @s_user,
      @s_term          = @s_term,
      @s_date          = @s_date,
      @s_ofi           = @w_op_oficina,
      @i_en_linea      = 'N',
      @i_fecha_proceso = @i_fecha_proceso,
      @i_operacionca   = @w_operacionca,
      @i_banco         = @w_banco,
      @i_pry_pago      = 'N',
      @i_cotizacion    = @w_cotizacion_hoy
      
      if @w_error <> 0 goto ERROR 
   end

   ERROR:
   if @w_error <> 0
      exec sp_errorlog 
      @i_fecha     = @s_date,
      @i_error     = @w_error,
      @i_usuario   = @s_user,
      @i_tran      = 7999,
      @i_tran_name = @w_sp_name_error,
      @i_cuenta    = @w_banco,
      @i_rollback  = @w_rollback

   SIGUIENTE:
      /* ATOMICIDAD POR OPERACION */
      while @@trancount > 0 COMMIT TRAN
      
      select @w_error = 0
   
end --@w_detener_proceso = 'N' 

ERROR_BATCH:
if @w_error <> 0
begin
   while @@trancount > 0 rollback tran
   
   exec sp_errorlog 
   @i_fecha     = @s_date,
   @i_error     = @w_error,
   @i_usuario   = @s_user,
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = @w_banco,
   @i_rollback  = 'S'
   
   return @w_error
end

return 0
go
