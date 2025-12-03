/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Luis Carlos Moreno                      */
/*      Fecha de escritura:     Septiembre 2012                         */
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
/* Realizar pagos masivos de cartera a partir de la tabla de cuentas    */
/* de ahorros inactivas.                                                */
/************************************************************************/
/*                              CAMBIOS                                 */
/*  FECHA     AUTOR             RAZON                                   */
/*  24-09-12  L.Moreno          Emisión Inicial - Req: 341              */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_paginac_mas') 
drop proc sp_paginac_mas
go

create proc sp_paginac_mas
@i_param1        datetime

as 
declare 
@w_operacion    int,
@w_banco        cuenta,
@w_vlr_pago     money,
@w_sec_ing      int,
@w_cliente      int,
@w_ctabanco     cuenta,
@w_fecha_ope    datetime,
@w_fecha_pro    datetime,
@w_fecha        datetime,
@w_est_cob      catalogo,
@w_descripcion  varchar(60),
@w_fp_paginac   varchar(30),
@w_procesada    char(1),
@w_msg          varchar(100),
@w_sp_name      varchar(32),
@w_cuenta       int,
@w_oficina      int,
@w_valpagi      varchar(30)
     
select @w_sp_name   = 'sp_paginac_mas'

select @w_fecha = @i_param1

if @w_fecha is null
begin
  select @w_msg = 'Error, no se encuentra la fecha de ejecucion'
  goto ERROR2
end

-- OBTIENE FECHA DE PROCESO
select @w_fecha_pro = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

if @@rowcount = 0
begin
   select @w_msg = 'Error al leer fecha de proceso de cartera'
   goto ERROR2
end

-- CONSULTAR FORMA DE PAGO (PAGINAC)
select @w_fp_paginac = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and pa_nemonico = 'PAGINA'

if @@rowcount = 0
begin
   select @w_msg = 'Error al leer forma de pago para Cuentas Inactivas Parametro general: PAGINAC'
   goto ERROR2
end

-- CONSULTAR FORMA DE PAGO (PAGINAC)
select @w_valpagi = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and pa_nemonico = 'VAPAGI'

select @w_valpagi = isnull(@w_valpagi,'S')

if @w_valpagi = 'S'
begin
   -- VALIDA SI PREVIAMENTE EXISTEN PAGOS APLICADOS CON LA FORMA DE PAGO (PAGINA)
   if exists (select 1
              from
              cob_cartera..ca_abono with (nolock),
              cob_cartera..ca_abono_det with (nolock)
              where ab_estado = 'A'
              and   ab_fecha_ing = @w_fecha
              and   abd_operacion = ab_operacion
              and   abd_secuencial_ing = ab_secuencial_ing
              and   abd_concepto = @w_fp_paginac)
   begin
      select @w_msg = 'Error Proceso ya ejecutado para la fecha indicada'
      goto ERROR2
   end

   /* ELIMINA LOG DE PAGOS */
   delete ca_paginac
   where pi_fecha = @w_fecha

   if @@error <> 0
   begin
      select @w_msg = 'Error al eliminar registros tabla ca_paginac'
      goto ERROR2
   end
end

/* INICIALIZA VARIABLES DE TRABAJO*/
select @w_ctabanco = '',
       @w_msg = ''

/* CARGA TABLA TEMPORAL CON INFORMACION DE CLIENTES Y MAXIMO DIAS DE MORA */
select cc_cliente cliente, cc_ctabanco cuenta, max(cc_diasmora) dias
into #clientes
from cob_ahorros..ah_ctas_cancelar
where cc_fecha = @w_fecha
and   cc_procesado = 'S'
and   cc_exclusivo = 'C'
group by cc_cliente, cc_ctabanco
order by cc_cliente, cc_ctabanco

/* PROCESA PAGOS */
while 1 = 1 begin
   set rowcount 1

   select @w_descripcion = '',
          @w_procesada = 'I'

   /* OBTIENE DATOS DE LA OPERACION */
   select 
   @w_cliente     = cc_cliente,
   @w_ctabanco    = cc_ctabanco,
   @w_banco       = cc_operacion,
   @w_vlr_pago    = round(cc_saldado,0),
   @w_operacion   = op_operacion,
   @w_est_cob     = isnull(op_estado_cobranza,''),
   @w_fecha_ope   = op_fecha_ult_proceso,
   @w_cuenta      = cc_cuenta,
   @w_oficina     = cc_oficina
   from
   cob_ahorros..ah_ctas_cancelar with (nolock),
   ca_operacion with (nolock),
   #clientes
   where cc_ctabanco  > @w_ctabanco
   and   op_banco     = cc_operacion
   and   op_estado    in (1,2,4,9)
   and   cc_fecha     = @w_fecha
   and   cc_procesado = 'S'
   and   cc_exclusivo = 'C'
   and   cc_cliente   = cliente
   and   cc_diasmora  = dias
   and   cc_ctabanco  = cuenta
   order by cc_ctabanco

   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   set rowcount 0
  
   /* GENERA SECUENCIAL DE PAGO */
   exec @w_sec_ing   = sp_gen_sec
   @i_operacion = @w_operacion

   begin tran

   /* CREA CABECERA DEL ABONO */
   select 
   abt_secuencial_ing           = @w_sec_ing,
   abt_secuencial_rpa           = 0,
   abt_secuencial_pag           = 0,
   abt_operacion                = op_operacion,
   abt_fecha_ing                = @w_fecha_pro,
   abt_fecha_pag                = @w_fecha_pro,
   abt_cuota_completa           = op_cuota_completa,
   abt_aceptar_anticipos        = op_aceptar_anticipos,
   abt_tipo_reduccion           = 'N',
   abt_tipo_cobro               = op_tipo_cobro,
   abt_dias_retencion_ini       = 0,
   abt_dias_retencion           = 0,
   abt_estado                   = 'ING',
   abt_usuario                  = 'op_batch',
   abt_oficina                  = @w_oficina,
   abt_terminal                 = 'Terminal',
   abt_tipo                     = 'PAG',
   abt_tipo_aplicacion          = 'D',
   abt_nro_recibo               = 0,
   abt_tasa_prepago             = 0.00,
   abt_dividendo                = 0,
   abt_calcula_devolucion       = 'N',
   abt_prepago_desde_lavigente  = 'N',
   abt_extraordinario           = ''
   into #ab_pago
   from ca_operacion
   where op_banco = @w_banco
   and   op_estado not in (0,3,99,6)

   if @@rowcount = 0
   begin
      select @w_descripcion = 'Error al crear cabecera de Abono en tabla #ab_pago'
      goto ERROR
   end

   /* CREA DETALLE DEL ABONO */      
   select
   abdt_secuencial_ing     = abt_secuencial_ing,
   abdt_operacion          = abt_operacion,
   abdt_tipo               = abt_tipo,
   abdt_concepto           = @w_fp_paginac,
   abdt_cuenta             = @w_cliente,
   abdt_beneficiario       = 'PAGO CUENTAS INACTIVAS',
   abdt_moneda             = 0,
   abdt_monto_mpg          = @w_vlr_pago,
   abdt_monto_mop          = @w_vlr_pago,
   abdt_monto_mn           = @w_vlr_pago,
   abdt_cotizacion_mpg     = 1,
   abdt_cotizacion_mop     = 1,
   abdt_tcotizacion_mpg    = 'C',
   abdt_tcotizacion_mop    = 'C',
   abdt_cheque             = null,
   abdt_cod_banco          = '',
   abdt_inscripcion        = 0,
   abdt_carga              = null,
   abdt_porcentaje_con     = null
   into #abd_pago
   from #ab_pago

   if @@rowcount = 0
   begin
      select @w_descripcion = 'Error al crear detalle de Abono en tabla #abd_pago'
      goto ERROR
   end

   /* INSERTA EN LA TABLA DE CABECERA DE ABONOS */
   insert into ca_abono
   select * from #ab_pago
      
   if @@rowcount = 0 begin
      select @w_descripcion = 'Error al ingresar Abono'
      goto ERROR
   end
      
   /* INSERTA EN LA TABLA DE DETALLE DE ABONOS */
   insert into ca_abono_det
   select * from #abd_pago
      
   if @@rowcount = 0 begin
      select @w_descripcion = 'Error al ingresar Detalle de Abono'
      goto ERROR
   end
      
   /* ACTUALIZA EL ESTADO DE COBRANZA A NORMALIZADO */
   update cob_cartera..ca_operacion 
   set    op_estado_cobranza = 'NO'
   where  op_banco = @w_banco
      
   if @@rowcount = 0 begin
      select @w_descripcion = 'Error al actualizar estado de cobranza de la operacion'
      goto ERROR
   end
           
   /* INSERTA LA PRIORIDAD DEL ABONO */
   insert into cob_cartera..ca_abono_prioridad
   select @w_sec_ing, @w_operacion, ro_concepto, ro_prioridad
   from   ca_rubro_op
   where  ro_operacion = @w_operacion
   and    ro_fpago not in ('L','B')
      
   if @@rowcount = 0 begin
      select @w_descripcion = 'Error actualizando ca_abono_prioridad'
      goto ERROR
   end
      
   /* ELIMINA TABLAS TEMPORALES */
   drop table #ab_pago
   drop table #abd_pago
      
   commit tran

   ERROR:

      if @@trancount > 0
         rollback

	  if @w_descripcion <> ''
	     select @w_procesada = 'R'

      /* ALMACENA EL ESTADO DE COBRANZA DE LA OBLIGACION */
      insert into ca_paginac
      (pi_operacion,       pi_banco,           pi_ctabanco, pi_cuenta,
       pi_cliente,         pi_fecha,           pi_vlr,      pi_est_cob,
       pi_sec_ing,         pi_estado,          pi_error,
       pi_desc_error)
       values
      (@w_operacion,       @w_banco,           @w_ctabanco, @w_cuenta,
       @w_cliente,         @w_fecha,           @w_vlr_pago, @w_est_cob,
       @w_sec_ing,         @w_procesada,       0,
       @w_descripcion)
      
      if @@error <> 0
         print 'Error al crear registro de log ca_paginac ' + cast(@w_banco as varchar)  
end

return 0

ERROR2:

exec sp_errorlog 
@i_fecha       = @w_fecha_pro,
@i_error       = 722508, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return 722508
go