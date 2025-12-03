/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Jose Rafael Molano                      */
/*      Fecha de escritura:     Agosto 2011                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*                                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      AGO-29-2012      LCM           Pagos por reconocimiento USAID   */
/*      24-02-14         I.Berganza    Req: 397 - Reportes FGA          */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_recfng_mas') 
drop proc sp_recfng_mas
go

---INC. 107748 feb.21.2013

create proc sp_recfng_mas (
   @i_param1      datetime
)

as 
declare 
@w_path       varchar(250),
@w_cmd        varchar(250),
@w_s_app      varchar(250),
@w_destino    varchar(250),
@w_errores    varchar(250),
@w_comando    varchar(250),
@w_error      int,
@w_err_up     varchar(250),
@w_operacion  int,
@w_banco      cuenta,
@w_vlr_pago   money,
@w_fecha_ING  datetime,
@w_sec_ing    int,
@w_cliente    int,
@w_cedula     cuenta,
@w_fecha_ope  datetime,
@w_fecha_pro  datetime,
@w_est_cob    catalogo,
@w_fecha       datetime,
@w_descripcion  varchar(60),
@w_anexo        varchar(255),
@w_cf_producto  catalogo,
@w_tramite       int --LCM - 293

select @w_fecha = @i_param1

-- Lectura de la tabla T303 Req. 397
select distinct codigo
into #cod_sib
from cob_credito..cr_corresp_sib
where tabla = 'T303'
      
-- CARGA DEL ARCHIVO ENTREGADO POR BANCAMIA

truncate table ca_recfng_mas
select 
@w_err_up    = '',
@w_operacion = 0
       
select @w_fecha_pro = @w_fecha

select @w_fecha_ING = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_s_app   = pa_char from cobis..cl_parametro where pa_producto = 'ADM' and   pa_nemonico = 'S_APP'
select @w_path    = 'F:\VBatch\Cartera\Listados\'

select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_recfng_mas in '
select @w_destino = @w_path + 'ca_recfng_mas' + '.txt', @w_errores  = @w_path + 'ca_recfng_mas' + '.err'
select @w_comando = @w_cmd + @w_path + 'ca_recfng_mas.txt -b5000 -c -e' + @w_errores + ' -t";" ' + '-config '+ @w_s_app + 's_app.ini'
exec   @w_error   = xp_cmdshell @w_comando
if @w_error <> 0 begin
   print 'Error Cargando Archivo de RECONOCIMIENTO FNG'
   goto ERROR2
end

while 1 = 1 begin
   set rowcount 1

   select 
   @w_cliente     = op_cliente,
   @w_banco       = cf_banco,
   @w_vlr_pago    = cf_pago,
   @w_operacion   = op_operacion,
   @w_est_cob     = isnull(op_estado_cobranza,''),
   @w_fecha_ope   = op_fecha_ult_proceso,
   @w_cf_producto = cf_producto,
   @w_tramite     = op_tramite
   from ca_recfng_mas, ca_operacion, cobis..cl_ente
   where op_operacion > @w_operacion
   and   op_banco     = cf_banco
   and   en_ente      = op_cliente
   and   op_estado in (1,2,4,9)
   order by op_operacion

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   set rowcount 0
   
   select 'Cliente: ', @w_cliente , ' - ' , 'Operacion: ', @w_banco
   
   print 'fecha pago @w_fecha_pro ' + cast (@w_fecha_pro as varchar)
   
   if @w_fecha_ope <>  @w_fecha_pro ---Poner la operacion al dia de pago  del reconocimiento @i_param
   begin
	    exec @w_error = sp_fecha_valor 
		@s_user              = 'sa',        
		@i_fecha_valor       = @w_fecha_pro,
		@s_term              = 'Terminal', 
		@s_date              = @w_fecha_ING,
		@i_banco             = @w_banco,
		@i_operacion         = 'F',
		@i_en_linea          = 'N',
		@i_control_fecha     = 'N',
		@i_debug             = 'N'

      if @w_error <> 0 begin
         Print 'Error Haciendo fecha valor A la fecha de reconocimiento' + cast(@w_banco as varchar)
         goto ERROR
      end

	   select @w_fecha_ope   = op_fecha_ult_proceso
	   from ca_recfng_mas, ca_operacion
	   where op_banco     = @w_banco
   end
   
   if @w_fecha_pro = @w_fecha_ope begin
   
      exec @w_sec_ing   = sp_gen_sec
      @i_operacion = @w_operacion

      begin tran
      -- Carga Pagos Operaciones

      select 
      abt_secuencial_ing           = @w_sec_ing,
      abt_secuencial_rpa           = 0,
      abt_secuencial_pag           = 0,
      abt_operacion                = op_operacion,
      abt_fecha_ing                = @w_fecha_ING,
      abt_fecha_pag                = @w_fecha_ope,
      abt_cuota_completa           = op_cuota_completa,
      abt_aceptar_anticipos        = op_aceptar_anticipos,
      abt_tipo_reduccion           = 'T',
      abt_tipo_cobro               = op_tipo_cobro,
      abt_dias_retencion_ini       = 0,
      abt_dias_retencion           = 0,
      abt_estado                   = 'ING',
      abt_usuario                  = 'sa',
      abt_oficina                  = op_oficina,
      abt_terminal                 = 'Terminal',
      abt_tipo                     = 'PAG',
      abt_tipo_aplicacion          = 'C',
      abt_nro_recibo               = 0,
      abt_tasa_prepago             = 0.00,
      abt_dividendo                = 0,
      abt_calcula_devolucion       = 'N',
      abt_prepago_desde_lavigente  = 'N',
      abt_extraordinario           = 'K' -- Solamente Afecta Capital 
      into #ab_pago
      from ca_operacion
      where op_banco = @w_banco
      and   op_estado not in (0,3,99,6)
      
      select
      abdt_secuencial_ing     = abt_secuencial_ing,
      abdt_operacion          = abt_operacion,
      abdt_tipo               = abt_tipo,
      abdt_concepto           = convert(varchar(30),''),
      abdt_cuenta             = @w_cliente,
      abdt_beneficiario       = '',
      abdt_moneda             = 0,
      abdt_monto_mpg          = @w_vlr_pago,
      abdt_monto_mop          = @w_vlr_pago,
      abdt_monto_mn           = @w_vlr_pago,
      abdt_cotizacion_mpg     = 1,
      abdt_cotizacion_mop     = 1,
      abdt_tcotizacion_mpg    = 'C',
      abdt_tcotizacion_mop    = 'C',
      abdt_cheque             = null,
      abdt_cod_banco          = @w_cf_producto, ---para la referencia del pago
      abdt_inscripcion        = 0,
      abdt_carga              = null,
      abdt_porcentaje_con     = null
      into #abd_pago
      from #ab_pago

      -- LCM - 293 - ACTUALIZA EL CONCEPTO DE PAGO DE ACUERDO AL TIPO DE GARANTIA
      update #abd_pago	
      set abdt_concepto = (select codigo_sib
	                       from cob_credito..cr_corresp_sib c
	                       where c.tabla = 'T303'
	                       and   c.codigo = tc_tipo_superior)
      from cob_custodia..cu_custodia with (nolock),
	       cob_credito..cr_gar_propuesta with (nolock),
		   cob_custodia..cu_tipo_custodia with (nolock)
      where gp_tramite = @w_tramite
	  and   gp_garantia  = cu_codigo_externo
	  and   cu_tipo      = tc_tipo
	  and   tc_tipo_superior in (select codigo from #cod_sib) -- Req. 397 Agregada lectura de la tabla #cod_sib

      if @@error <> 0
      begin
         Print 'Error al actualizar los conceptos de pago '
         rollback
         goto ERROR
      end
      
      insert into ca_abono
      select * from #ab_pago
      
      if @@rowcount = 0 begin
         Print 'Error al ingresar Abono ' + cast(@w_banco as varchar)
       rollback
       goto ERROR
      end
      
      insert into ca_abono_det
      select * from #abd_pago
      
      if @@rowcount = 0 begin
         Print 'Error al ingresar Detalle de Abono ' + cast(@w_banco as varchar)
         rollback
         goto ERROR
      end
      
      
      update ca_recfng_mas set
      cf_est_cob     = @w_est_cob	
      where cf_banco = @w_banco
      
      if @@rowcount = 0 begin
         Print 'Error al guardar estado de cobranza ' + cast(@w_banco as varchar)
         rollback
        goto ERROR
      end
      
      insert into cob_cartera..ca_abono_prioridad
      select @w_sec_ing, @w_operacion, ro_concepto, ro_prioridad
      from   ca_rubro_op
      where  ro_operacion = @w_operacion
      and    ro_fpago not in ('L','B')
      
      if @@rowcount = 0 begin
         Print 'Error actualizando ca_abono_prioridad' + cast(@w_banco as varchar)
         rollback
         goto ERROR
      end
      
      update ca_abono_prioridad
      set ap_prioridad = 0
      where ap_operacion = @w_operacion
      and   ap_secuencial_ing = @w_sec_ing
      and ap_concepto = 'CAP'

      drop table #ab_pago
      drop table #abd_pago
      
      commit tran
      ERROR:
			if @w_error > 0 
			begin
			   select @w_descripcion = mensaje
			   from cobis..cl_errores
			   where numero = @w_error  
		   
			   select @w_anexo =  'SP --> sp_recfng_mas '
			   
			   insert into ca_errorlog
			         (er_fecha_proc,      er_error,                        er_usuario,
			          er_tran,            er_cuenta,                       er_descripcion,
			          er_anexo)
			   values(@w_fecha ,         @w_error,                        'sa',
			          7269,              @w_banco,                       @w_descripcion,
			          @w_anexo
			          ) 
			end       
       

   end   
end
ERROR2:
return 0
go

