/************************************************************************/
/*   Nombre Fisico:       pagxreco.sp                                   */
/*   Nombre Logico:       sp_pagxreco                                   */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            cartera						               	*/
/*   Disenado por:        Luis Carlos Moreno C.			                */
/*   Fecha de escritura:  Noviembre/2011                                */
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
/*                           PROPOSITO                                  */
/*  Realizar el mantenimiento de la tabla ca_pago_recono (Pago por)     */
/*  reconocimiento de acuerdo al tipo de llamado:                       */
/*  - I : Inserta un nuevo reconocimiento.                              */
/*  - R : Reversa un reconocimiento.                                    */
/*  - C : Cancela un reconocimiento.                                    */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*  FECHA     AUTOR             RAZON                                   */
/*  22-11-11  L.Moreno          Emisión Inicial - Req: 293              */
/*  11-04-14  Liana Coto        Req424 Ajuste pagos recibidos de        */
/*                                     clientes con reconocimiento de   */
/*                                     de garantías con recuperación    */
/*  24-Feb-14  I.Berganza        Req: 397 - Reportes FGA                */
/*  22-Jun-15  Elcira Pealez     No permiri reconocimientos del 100%    */
/*  17-abr-23  Guisela Fernandez S807925 Ingreso de campo de            */
/*                               reestructuracion                       */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*  07/11/2023       K. Rodriguez     Actualiza valor despreciab        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pagxreco')
   drop proc sp_pagxreco
go

---AgO.03.2015

create procedure sp_pagxreco(
       @s_user              login = NULL,
       @s_term              varchar (30) = NULL,
       @s_date              datetime = NULL,
       @i_tipo_oper         char(1)='',
       @i_operacionca       int=NULL,
       @i_en_linea          char(1) = 'S',
       @i_oficina_orig      smallint=NULL,
       @i_monto_pago         money=NULL,
       @i_saldo_capital     money=NULL,
       @i_num_dec           smallint=NULL,
       @i_secuencial_pag    int=NULL,
       @i_dividendo         int = NULL,   --LC REQ424 11ABR2014
       @o_tiene_reco        char(1) = 'N' out,
       @o_porc_cubrim       float = null out,
       @o_vlr_rec_ini       money = null out,
       @o_vlr_x_amort       money = null out,
       @o_concepto_rec      char = 'N' out,
       @o_sobrante          money = null out
)

as

Declare @w_error            int,
        @w_tiene_recono     char(1),
        @w_concepto         catalogo,
        @w_secuencial_rec   int,
        @w_codvalor         int,
        @w_rec_vlr          money,
        @w_rec_vlr_amort    money,
        @w_rec_estado       char(1),
        @w_observacion      varchar(62),
        @w_porcentaje       float,
        @w_tipo_gar         varchar(30),
        @w_subtipo_gar      varchar(30),
        @w_3nivel_gar       varchar(255),
        @w_dtr_concepto     varchar(30),
        @w_concepto_rec_fng varchar(30),
        @w_concepto_rec_usa varchar(30),
        @w_tipo             varchar(64),
        @w_tip_sup          varchar(30),
        @w_fecha_cierre     datetime,
        @w_toperacion        catalogo,
        @w_moneda            smallint,
        @w_banco             cuenta,
        @w_oficina_op        int,
        @w_gerente           smallint,
        @w_gar_admisible     char(1),
        @w_reestructuracion  char(1),
        @w_calificacion      catalogo,
        @w_fecha_ref         datetime,
        @w_vlr_rev           money,
        @w_monto_real_cap    money,
        @w_vlr_x_amort       money,
        @w_tiene_reco_amort  char(1),
        @w_secuencial_retro  int,
        @w_saldo_rec         money,
        @w_vlr_despreciable  float,
        @w_div_pend          smallint,
        @w_est_vigente       tinyint,
        @w_est_no_vigente    tinyint,
        @w_est_vencido       tinyint,
        @w_monto_cap_ven     money,
        @w_est_fpago         char(1),
        @w_est_cat_fpago     char(1),
        @w_por_especial_fng  float,
        @w_concepto_COMFNG   catalogo,
        @w_concepto_IVAFNG   catalogo,
        @w_estado_op         smallint,
		  --LC REQ424 11ABR2014
		  @w_monto_pag_div     money,
		  @w_monto_inicial     money,
		  @w_sec_rpa_rec       int,
        @w_sec_rpa_pag       int,
        @w_ult_div_venc      int,
        @w_porc_tabla        money,  -- Req. 397 - Reportes FGA
        @w_tabla             int     -- Req. 397 - Reportes FGA

set nocount on
set ansi_warnings off

/************************************************************************/
/*                    INICIALIZACION DE VARIABLES                       */
/************************************************************************/
select @w_tiene_recono  = 'N',
       @w_concepto      = '',
       @w_observacion   = '',
       @w_tiene_reco_amort = 'N',
       @w_rec_vlr       = 0,
       @w_rec_vlr_amort = 0,
       @w_rec_estado    = '',
       @w_monto_cap_ven = 0,
       @w_div_pend      = 0,
       @w_por_especial_fng = 0

/************************************************************************/
/*                   LECTURA DE PARAMETROS GENERALES                    */
/************************************************************************/
select @w_concepto_rec_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'RECFNG'

select @w_concepto_rec_usa = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'RECUSA'

select @w_fecha_cierre = fc_fecha_cierre
from   cobis..ba_fecha_cierre with (nolock)
where  fc_producto = 7

select @w_por_especial_fng = pa_float
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'PORREC'

select @w_concepto_IVAFNG = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFNG'

select @w_concepto_COMFNG = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'





/************************************************************************/
/*                          ESTADOS DE CARTERA                          */
/************************************************************************/
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente    out,
@o_est_novigente  = @w_est_no_vigente out,
@o_est_vencido    = @w_est_vencido    out

/************************************************************************/
/*                   OBTIENE CONCEPTO DE LA OPERACION                   */
/************************************************************************/
--OBTIENE SECUENCIAL RPA DE LA OPERACION
select @w_secuencial_retro = tr_secuencial_ref
from   ca_transaccion with (nolock)
where  tr_operacion  = @i_operacionca
and    tr_tran       = 'PAG'
and    tr_secuencial = @i_secuencial_pag

--OBTIENE CONCEPTO DE LA OPERACION RPA
select @w_concepto = dtr_concepto
from   ca_det_trn with (nolock)
where  dtr_operacion  = @i_operacionca 
and    dtr_secuencial = @w_secuencial_retro
and    dtr_concepto  not like 'VAC_%'

/************************************************************************/
/*                 VALIDA EXISTENCIA DE RECONOCIMIENTO                  */
/************************************************************************/
/*VALIDA SI LA OPERACION YA TIENE UN PAGO POR RECONOCIMIENTO CON DEVOLUCION */
select @w_rec_vlr       = pr_vlr,
       @w_rec_vlr_amort = pr_vlr_amort,
       @w_rec_estado    = pr_estado
from   ca_pago_recono with (nolock)
where  pr_operacion = @i_operacionca
and    pr_estado   <> 'R'

if @@rowcount > 0
begin
   select @w_tiene_recono = 'S'
   select @w_tiene_reco_amort = 'S'
end

/* LEE DATOS DE LA OPERACION */
select @w_toperacion       = op_toperacion,
       @w_moneda           = op_moneda,
       @w_banco            = op_banco,
       @w_oficina_op       = op_oficina,
       @w_fecha_ref        = op_fecha_ult_proceso,
       @w_gerente          = op_oficial,
       @w_gar_admisible    = op_gar_admisible,
       @w_reestructuracion = isnull(op_reestructuracion, ''),
       @w_calificacion     = isnull(op_calificacion, 'A'),
       @w_estado_op        = op_estado
from   ca_operacion with (nolock)
where  op_operacion = @i_operacionca

-- Req. 397 Insercion en tabla temp #formas_rec para formas de pago por reconocimiento
select @w_tabla = codigo from cobis..cl_tabla where tabla = 'ca_fpago_reconocimiento'

select * 
into #formas_rec
from cobis..cl_catalogo 
where tabla = @w_tabla
and   estado = 'V'

if @i_tipo_oper = 'I' or @i_tipo_oper = 'P' or @i_tipo_oper = 'R'
begin

   /* VALIDA SI LA OPERACION YA TIENE UN PAGO POR RECONOCIMIENTO SIN DEVOLUCION */
   select @w_dtr_concepto = dtr_concepto,
          @w_sec_rpa_rec  = dtr_secuencial  --LC REQ424 11ABR2014
   from   ca_transaccion with (nolock),
          ca_det_trn with (nolock)
   where tr_operacion  = @i_operacionca
   and   tr_operacion  = dtr_operacion
   and   tr_secuencial = dtr_secuencial
   and   tr_secuencial > 0
   and   tr_tran       = 'RPA'
   and   tr_estado     <> 'RV'
   and   dtr_concepto  in (select codigo from #formas_rec) -- Req. 397 Extrayendo codigo de la tabla temporal
   if @@rowcount > 1
   begin
      select @w_tiene_recono = 'S'
      select @w_rec_estado   = 'A'
   end

   /* CALCULA VALOR DEL DESPRECIABLE */
   select @w_vlr_despreciable = 1.0 / power(10,  isnull((@i_num_dec + 2), 4))
end

/************************************************************************/
/*                  INGRESO DE PAGO POR RECONOCIMIENTO                  */
/************************************************************************/
if @i_tipo_oper = 'I'
begin

   /* SI EL CONCEPTO DEL PAGO CORRESPONDE A RECONOCIMIENTO FNG O USAID */
 -- Req. 397 Extrayendo codigo de la tabla temporal
   if @w_concepto in (select codigo from #formas_rec)
   begin
      if @w_tiene_recono = 'S' return 721328

      /* VALIDA QUE LA FORMA DE PAGO POR RECONOCIMIENTO EXISTA */
      select @w_est_fpago = cp_estado
      from cob_cartera..ca_producto with (nolock)
      where cp_producto = @w_concepto

      if @@rowcount = 0
         return 710416

      /* VALIDA QUE LA FORMA DE PAGO POR RECONOCIMIENTO ESTE VIGENTE */
      if @w_est_fpago <> 'V'
         return 722500

      /* VALIDA QUE LA FORMA DE PAGO POR RECONOCIMIENTO EXISTA EN EL CATALOGO DE FORMAS DE PAGO A CAPITAL */
      select @w_est_cat_fpago = c.estado
      from cobis..cl_tabla t with (nolock), 
           cobis..cl_catalogo c with (nolock)
      where c.tabla = t.codigo
      and   t.tabla = 'ca_pago_capital'
      and   c.valor = @w_concepto
      and   c.estado = 'V'

      if @@rowcount = 0
      begin
         --print '@w_concepto : ' +cast (@w_concepto as varchar)
         return 722502
      end
      /* VALIDA QUE LA FORMA DE PAGO POR RECONOCIMIENTO ESTE VIGENTE EN EL CATALOGO DE FORMAS DE PAGO A CAPITAL */
      if @w_est_cat_fpago <> 'V'
         return 722503

      /* BUSCA LA GARANTIA COLATERAL VIGENTE ASOCIADA A LA OPERACION */
      exec @w_error       = sp_bus_colateral
           @i_tipo        = 'V',--VIGENTE
           @i_banco       = @w_banco,
           @o_porcentaje  = @w_porcentaje out,
           @o_tipo_sup    = @w_tip_sup out,
           @o_tipo        = @w_tipo out,
           @o_tipo_gar    = @w_tipo_gar out,
           @o_subtipo_gar = @w_subtipo_gar out,
           @o_3nivel_gar  = @w_3nivel_gar out
      if @w_error <> 0 return @w_error

      ---NR 397
      ---Se definion en Reunion Con Bancamia el 22 de Junio 2015 (piso2) que hasta que no se defina la funcionalidad
      ---de reconocimiento del 100% se controle con este codigo de error
      if @w_porcentaje >= 100
         return 723910

      
      /* CANCELA LA GARANTIA ASOCIADA A LA OBLIGACION */
      exec @w_error       = sp_bus_colateral
           @i_tipo        = 'D',
           @i_banco       = @w_banco
      if @w_error <> 0
          return @w_error

      ---REVERSION DE LAS COMISIONES SI EL SISTEMA TIENE VALORES SIN GENERAR
      if exists (select 1 from ca_amortizacion
		where am_operacion = @i_operacionca
		and am_concepto = @w_concepto_COMFNG
		and am_estado <> 3
		and am_acumulado > 0)
		begin
             insert into ca_transaccion_prv with (rowlock)
			(
			tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
			tp_secuencial_ref,   tp_estado,           tp_dividendo,
			tp_concepto,         tp_codvalor,         tp_monto,
			tp_secuencia,        tp_comprobante,      tp_ofi_oper)
			select 
			@w_fecha_cierre,    @i_operacionca,       @w_fecha_ref,
			-999,              'ING',                 am_dividendo,
			am_concepto,        co_codigo * 1000 + @w_estado_op * 10 + 0, (am_acumulado - am_pagado)*-1,
			1,                   0,                   @w_oficina_op
			from ca_concepto,ca_amortizacion
			where co_concepto = @w_concepto_COMFNG
			and am_operacion = @i_operacionca
			and am_concepto = @w_concepto_COMFNG
			and am_concepto = co_concepto
			and am_estado <> 3
			and am_acumulado > 0
			
	        if @@error <> 0
	           return 708165		
        end
                
        if exists (select 1 from ca_amortizacion
		where am_operacion = @i_operacionca
		and am_concepto = @w_concepto_IVAFNG
		and am_estado <> 3
		and am_acumulado > 0)
		begin
             insert into ca_transaccion_prv with (rowlock)
			(
			tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
			tp_secuencial_ref,   tp_estado,           tp_dividendo,
			tp_concepto,         tp_codvalor,         tp_monto,
			tp_secuencia,        tp_comprobante,      tp_reestructuracion)
			select 
			@w_fecha_cierre,    @i_operacionca,     @w_fecha_ref,
			-999,              'ING',               am_dividendo,
			am_concepto,        co_codigo * 1000 + @w_estado_op * 10 + 0,(am_acumulado - am_pagado)*-1,
			1,                  0,                  @w_reestructuracion
			from ca_concepto,ca_amortizacion
			where co_concepto = @w_concepto_IVAFNG
			and am_operacion = @i_operacionca
			and am_concepto = @w_concepto_IVAFNG
			and am_concepto = co_concepto
			and am_estado <> 3
			and am_acumulado > 0
			
	        if @@error <> 0
	           return 708165		
        end
                 
      ---- FIN REVERSION                 
     
      select @w_observacion = 'PAGO POR RECONOCIMIENTO'

      /* OBTIENE VALOR REAL DEL PAGO */
      select @w_monto_real_cap = sum(dtr_monto)
      from   ca_det_trn with (nolock)
      where  dtr_operacion  = @i_operacionca 
      and    dtr_secuencial = @i_secuencial_pag
      and    dtr_concepto like 'VAC_%'

      select @w_ult_div_venc = 0

      /* OBTIENE EL VALOR A CAPITAL APLICADO A CUOTAS VENCIDAS Y EL ULTIMO DIVIDENDO VENCIDO PAGADO POR EL RECONOCIMIENTO */
      select @w_monto_cap_ven = isnull(sum(dtr_monto),0), @w_ult_div_venc = max(di_dividendo)
      from
      ca_det_trn with (nolock),
      ca_dividendo with (nolock)
      where  dtr_operacion  = @i_operacionca 
      and    dtr_secuencial = @i_secuencial_pag
      and    dtr_concepto = 'CAP'
      and    di_operacion = dtr_operacion
      and    di_dividendo = dtr_dividendo
      and    di_estado    = @w_est_vencido

      select @w_monto_cap_ven = isnull(@w_monto_cap_ven,0)

      /* BUSCA EN LA TABLA DE CORRESPONDENCIA T303 SI EL TIPO DE GARANTIA EXIGE RECUPERACION */
      -- Req. 397 Extrayendo limite superior de la tabla de correspondencia
      select @w_porc_tabla = limite_inf
      from cob_credito..cr_corresp_sib
      where tabla = 'T303'
      and   codigo = @w_tip_sup
      
      if @@rowcount = 0
         return 0            

      /* CALCULA VALOR PARA DIVIDIR EN CUOTAS FIJAS PARA AMORTIZAR CUOTAS VIGENTES */
      select @w_monto_cap_ven = @w_monto_real_cap - @w_monto_cap_ven

      /* BUSCA EN LA TABLA DE CORRESPONDENCIA T143 SI EL TIPO DE GARANTIA EXIGE RECUPERACION */
      /* SI NO EXIGE RECUPERACION RETORNA EN CASO CONTRARIO CONTINUA CON EL PROCESO */
      select @w_codvalor = limite_inf
      from cob_credito..cr_corresp_sib with (nolock)
      where tabla = 'T143'
      and   codigo = @w_tipo
 
      if @@rowcount = 0
         return 0
       -- Req. 397 Calcula el saldo capital y valida la variable @w_porc_tabla
      /* CALCULA EL VALOR QUE SE DEBERIA RECONOCER */
      select @i_saldo_capital = round(@i_saldo_capital * @w_porcentaje/100, @i_num_dec)
         
      if @w_porc_tabla is null
         select @i_saldo_capital = round(@i_saldo_capital * @w_porcentaje/100, @i_num_dec)
      else
         select @i_saldo_capital = round(@i_saldo_capital * @w_porc_tabla/100, @i_num_dec)
         

      -- Req. 397 condicion añadida para validar si los conceptos son iguales
      if @w_concepto = @w_concepto_rec_fng
      begin
         /* SI EL VALOR PAGADO ES DIFERENTE AL VALOR QUE SE DEBERIA RECONOCER */
         if @w_monto_real_cap <> @i_saldo_capital and @w_por_especial_fng = 0
         begin
            --PRINT 'SI EL PORCENTAJE SE PUEDE PARAMETRIZAR, POR FAVOR PONERLO EN EL PARAMETRO (PORREC) en Cartera'
            return 722224
         end
         if @w_por_especial_fng > 0 and @w_por_especial_fng  < 100
         begin
            ---PRINT '---poner el % de reconocimiento a la garnatia para posteriores pagos'
            update cob_credito..cr_gar_propuesta
		    set gp_porcentaje = @w_por_especial_fng
		    from cob_credito..cr_gar_propuesta with (nolock),
		         cob_custodia..cu_custodia with (nolock),
		         cob_cartera..ca_operacion with (nolock)
		    where op_operacion   = @i_operacionca
		    and op_tramite = gp_tramite
		    and cu_codigo_externo = gp_garantia
		    and cu_tipo  = @w_tipo
		    if @@error <> 0 
		    begin
		       --PRINT 'Error Registrando Nuevo procentaje de reconocimiento'
		       return 721329
		    end   
         end
      end
      /* GENERA SECUENCIAL PARA LA OPERACION */
      exec @w_secuencial_rec = sp_gen_sec
           @i_operacion      = @i_operacionca

      /* DIVIDENDOS PENDIENTES */
      select @w_div_pend = count(1) 
      from ca_dividendo with (nolock)
      where di_operacion = @i_operacionca 
      and   di_estado in (@w_est_no_vigente, @w_est_vigente)

      /* INSERTA RECONOCIMIENTO */
	  insert into ca_pago_recono (
			   pr_operacion,         pr_banco,         pr_trn,         pr_fecha,
               pr_fecha_ult_pago,    pr_vlr,           pr_vlr_amort,   pr_estado,
               pr_tipo_gar,          pr_subtipo_gar,   pr_3nivel_gar,  pr_vlr_calc_fijo,
               pr_div_pend,          pr_div_venc)
	  values                     (
			   @i_operacionca,       @w_banco,         @w_secuencial_rec, @w_fecha_cierre,
               '',                   @w_monto_real_cap,	   0,                'A',
               @w_tipo_gar,          @w_subtipo_gar,   @w_3nivel_gar,  isnull(@w_monto_cap_ven,0),
               isnull(@w_div_pend,0),isnull(@w_ult_div_venc,0))
	  
	  if @@error <> 0 return 721329

      if @w_error <> 0 return @w_error
      /* INSERTA CABECERA CONTABLE TRANSACCION REC */
	  insert into ca_transaccion(
             tr_fecha_mov,         tr_toperacion,     tr_moneda,
             tr_operacion,         tr_tran,           tr_secuencial,
             tr_en_linea,          tr_banco,          tr_dias_calc,
             tr_ofi_oper,          tr_ofi_usu,        tr_usuario,
             tr_terminal,          tr_fecha_ref,      tr_secuencial_ref,
             tr_estado,            tr_gerente,        tr_gar_admisible,
             tr_reestructuracion,  tr_calificacion,   tr_observacion,
             tr_fecha_cont,        tr_comprobante)
      values                    (
             @w_fecha_cierre,      @w_toperacion,     @w_moneda,
             @i_operacionca,       'REC',             @w_secuencial_rec,
             @i_en_linea,          @w_banco,          0,
             @w_oficina_op,        @i_oficina_orig,   @s_user,
             @s_term,              @w_fecha_ref,      isnull(@i_secuencial_pag,0),
             'ING',                @w_gerente,        isnull(@w_gar_admisible,''),
             @w_reestructuracion,  @w_calificacion,   @w_observacion,
             @s_date,              0)

	  if @@error <> 0 return 708165
	  
	  /* INSERTA DETALLE CONTABLE TRANSACCION REC */
	if @w_monto_real_cap > 0 begin

       insert into ca_det_trn(
 	   		   dtr_secuencial,     dtr_operacion,    dtr_dividendo,
 	   		   dtr_concepto,       dtr_estado,       dtr_periodo,
 	   		   dtr_codvalor,       dtr_monto,        dtr_monto_mn,
 	   		   dtr_moneda,         dtr_cotizacion,   dtr_tcotizacion,
 	   		   dtr_afectacion,     dtr_cuenta,       dtr_beneficiario,
 	   		   dtr_monto_cont)
       values                (
 	   		   @w_secuencial_rec,  @i_operacionca,   0,
 	   		   'CAP',      0,      0,                
 	   		   @w_codvalor,        @w_monto_real_cap,     @w_monto_real_cap,
 	   		   @w_moneda,          1,                0,
 	   		   'C',                '',               @w_observacion,
 	   		 @w_monto_real_cap)
       
       if @@error <> 0 return 710036 
    end
    
   end
end


/************************************************************************/
/*               PAGO DEL CLIENTE  AL RECONOCIMIENTO                    */
/************************************************************************/
if @i_tipo_oper = 'P'
begin

   /* SI LA OBLIGACION NO TIENE UN RECONOCIMIENTO POR AMORTIZAR */
   if @w_tiene_reco_amort = 'N' return 0

   /* SI EL CONCEPTO DE PAGO ES RECFNG = RECONOCIMIENTO FNG O RECUSAID = RECONOCIMIENTO USAID NO DEBE REALIZAR */
   /* AMORTIZACION DEL RECONOCIMIENTO */
   -- Req. 397 Extrayendo codigo de la tabla temporal
   if @w_concepto in (select codigo from #formas_rec)
      return 0

   /* CONSULTA EL TIPO DE GARANTIA ASOCIADA A LA OBLIGACION */
   exec @w_error  = sp_bus_colateral
   @i_tipo        = 'C',
   @i_banco       = @w_banco,
   @o_tipo_sup    = @w_tip_sup out,
   @o_tipo        = @w_tipo out
      
   if @w_error <> 0 return @w_error

   /* CALCULA EL VALOR PENDIENTE POR AMORTIZAR DEL RECONOCIMIENTO */
   select @w_vlr_x_amort = @w_rec_vlr - @w_rec_vlr_amort

   select @o_sobrante = 0

   /* SI EL VALOR DEL PAGO ES MAYOR QUE EL SALDO POR AMORTIZAR DEL RECONOCIMIENTO DEVUELVE EL SOBRANTE */
   if @i_monto_pago >= @w_vlr_x_amort
   begin
      select @o_sobrante = @i_monto_pago - @w_vlr_x_amort

      select @i_monto_pago = @w_vlr_x_amort
      select @w_rec_estado = 'C'
   end
   
   
   
   if @i_dividendo is not null ---- INICIO LC REQ424 11ABR2014
   begin
      select @w_sec_rpa_pag = ab_secuencial_pag 
      from   ca_abono 
      where  ab_operacion      = @i_operacionca 
      and    ab_secuencial_rpa = @w_sec_rpa_rec

      if @@rowcount = 0
        begin
	       --PRINT 'Error Buscando Abono por Reconocimiento'
		    return 710029
	     end 
      
      select @w_monto_pag_div = sum(dtr_monto)
      from   ca_det_trn 
      where  dtr_operacion    =  @i_operacionca
      and    dtr_secuencial   =  @w_sec_rpa_pag
      and    dtr_dividendo    <= @i_dividendo
      and    dtr_concepto     =  'CAP'

      if @@rowcount = 0
        begin
	      --PRINT 'Error Buscando Detalle Abono por Reconocimiento'
		   return 721330
	     end
      
     
      select @w_monto_inicial = @i_monto_pago
   
      if sum(@w_rec_vlr_amort + @i_monto_pago) > @w_monto_pag_div 
      begin
         select @i_monto_pago = sum(@w_monto_pag_div - @w_rec_vlr_amort)
         select @o_sobrante   = sum (@w_monto_inicial - @i_monto_pago)
      end
        
     
      
   end  --- FIN LC REQ424 11ABR2014
   
   select @w_saldo_rec = round(abs(@w_vlr_x_amort - @i_monto_pago), @i_num_dec)

   /* SI EL SALDO DEL RECONOCIMIENTO INCLUYENDO EL PAGO ES MENOR QUE EL DESPRECIABLE SE CANCELA EL RECONOCIMIENTO */
   if @w_saldo_rec <= @w_vlr_despreciable
      select @w_rec_estado = 'C'

   /* OBTIENE EL CODIGO VALOR ASOCIADO AL TIPO DE GARANTIA BUSCANDO EN LA TABLA DE CORRESPONDENCIA */
   select @w_codvalor = limite_sup
   from cob_credito..cr_corresp_sib with (nolock)
   where tabla = 'T143'
   and   codigo = @w_tipo
 
   if @@rowcount = 0
      return 701150 

   select @w_observacion = 'PAGO DEL CLIENTE AL RECONOCIMIENTO'

   /* ACTUALIZA EL RECONOCIMIENTO CON EL VALOR AMORTIZADO, EL ESTADO Y LA FECHA DE PAGO */
   update ca_pago_recono
   set pr_vlr_amort      = pr_vlr_amort + @i_monto_pago,
       pr_estado         = @w_rec_estado,
       pr_fecha_ult_pago = @w_fecha_cierre
   where pr_operacion = @i_operacionca
   and   pr_estado   <> 'R'

   if @@error <> 0 return 721332

   /* INSERTA DETALLE CONTABLE DEL PAGO DEL CLIENTE */
   if @i_monto_pago > 0 begin

      insert into ca_det_trn(
    		   dtr_secuencial,     dtr_operacion,    dtr_dividendo,
 	   		   dtr_concepto,       dtr_estado,       dtr_periodo,
 	   		   dtr_codvalor,       dtr_monto,        dtr_monto_mn,
 	   		   dtr_moneda,         dtr_cotizacion,   dtr_tcotizacion,
 	   		   dtr_afectacion,     dtr_cuenta,       dtr_beneficiario,
 	   		   dtr_monto_cont)
       values                (
 	   		   @i_secuencial_pag,  @i_operacionca,   0,
 	   		   'CAP',      0,      0,                
 	   		   @w_codvalor,        @i_monto_pago,     @i_monto_pago,
 	   		   @w_moneda,          1,                0,
 	   		   'C',                '',               @w_observacion,
 	   		   @i_monto_pago)
       
       if @@error <> 0 return 710036 
    end
end

/************************************************************************/
/*                    REVERSO DE PAGO O RECONOCIMIENTO                  */
/************************************************************************/

if @i_tipo_oper = 'R'
begin
	
    /* SI ES UN REVERSO DEL RECONOCIMIENTO */
    -- Req. 397 Extrayendo codigo de la tabla temporal
    if @w_concepto in (select codigo from #formas_rec)
    begin
       /* REVERSA LA CANCELACION DE LA GARANTIA ASOCIADA A LA OBLIGACION */
       exec @w_error       = sp_bus_colateral
            @i_tipo        = 'R',
            @i_banco       = @w_banco

       if @w_error <> 0 return @w_error

       /* SI NO EXISTE EL RECONOCIMIENTO RETORNA */
       if @w_tiene_recono = 'N'	return 0

       /* SI TIENE RECONOCIMIENTO Y TIENE UN VALOR AMORTIZADO POR EL CLIENTE */
       if @w_rec_vlr_amort > 0 return 722216

       /* REVERSA PAGO POR RECONOCIMIENTO */
       update ca_pago_recono
 	   set    pr_estado = 'R'
	   where  pr_operacion = @i_operacionca
       and    pr_estado = 'A'

       if @@error <> 0 return 721332
       
    end
   
    else begin 

       /* SI ES UN REVERSO DEL PAGO DEL CLIENTE */

       /* SI NO EXISTE EL RECONOCIMIENTO RETORNA */
       if @w_tiene_recono = 'N'	return 0

       /* CONSULTA EL TIPO DE GARANTIA ASOCIADA A LA OBLIGACION */
       exec @w_error  = sp_bus_colateral
            @i_tipo        = 'C',
            @i_banco       = @w_banco,
            @o_tipo_sup    = @w_tip_sup out,
            @o_tipo        = @w_tipo out
      
      if @w_error <> 0 return @w_error

      /* OBTIENE EL CODIGO VALOR ASOCIADO AL TIPO DE GARANTIA BUSCANDO EN LA TABLA DE CORRESPONDENCIA */
      select @w_codvalor = limite_sup
      from cob_credito..cr_corresp_sib with (nolock)
      where tabla = 'T143'
      and   codigo = @w_tipo
 
      if @@rowcount = 0
         return 701150 

       /* OBTIENE EL VALOR A REVERSAR */
       select @w_vlr_rev = isnull(sum(dtr_monto_mn),0)
       from ca_det_trn with (nolock)
       where dtr_operacion = @i_operacionca
       and   dtr_secuencial = @i_secuencial_pag
       and dtr_concepto = 'CAP'
       and dtr_codvalor = @w_codvalor

       if @@rowcount = 0 return 0

       if @w_vlr_rev <> 0
       begin
          /* SE REALIZA EL REVERSO DEL VALOR AMORTIZADO */
          update ca_pago_recono
          set pr_vlr_amort = pr_vlr_amort - @w_vlr_rev,
              pr_estado    = 'A'
          where pr_operacion = @i_operacionca
          and   pr_estado   <> 'R'

          if @@error <> 0 return 721332
       end
    end
end

/************************************************************************/
/*                    CONSULTA DE UN RECONOCIMIENTO                     */
/************************************************************************/
if @i_tipo_oper = 'Q'
begin
   select @o_tiene_reco = 'N',
          @o_porc_cubrim = 0,
          @o_vlr_rec_ini = 0,
          @o_vlr_x_amort = 0,
          @o_concepto_rec = 'N'

   /* SI EXISTE UN PAGO POR RECONOCIMIENTO VIGENTE */
   if exists (select 1 
   from ca_pago_recono with (nolock)
   where pr_operacion = @i_operacionca
   and   pr_estado    = 'A')
   begin
      exec @w_error       = sp_bus_colateral
           @i_tipo        = 'C',
           @i_banco       = @w_banco,
           @o_porcentaje  = @w_porcentaje out,
           @o_tipo        = @w_tipo out,
           @o_tipo_gar    = @w_tipo_gar out,
           @o_subtipo_gar = @w_subtipo_gar out,
           @o_3nivel_gar  = @w_3nivel_gar out
      
      if @w_error <> 0 return @w_error
      select @o_tiene_reco = 'S',
             @o_porc_cubrim = @w_porcentaje,
             @o_vlr_rec_ini = @w_rec_vlr,
             @o_vlr_x_amort = @w_rec_vlr - @w_rec_vlr_amort

      if @w_concepto in (select codigo from #formas_rec) -- Req. 397 Extrayendo codigo de la tabla temporal
         select @o_concepto_rec = 'S'

   end
end

/************************************************************************/
/*            CONSULTA DEL SALDO PENDIENTE POR AMORTIZAR                */
/************************************************************************/
if @i_tipo_oper = 'V'

begin
   select @o_vlr_rec_ini = 0,
          @o_vlr_x_amort = 0

   if exists (select 1 
   from ca_pago_recono with (nolock)
   where pr_operacion = @i_operacionca
   and   pr_estado    = 'A')
   begin
      select @o_vlr_rec_ini = @w_rec_vlr,
             @o_vlr_x_amort = @w_rec_vlr - @w_rec_vlr_amort
   end
end
return 0

go