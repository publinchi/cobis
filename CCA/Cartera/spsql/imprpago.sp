/************************************************************************/
/*   Archivo              :  imprpago.sp                                */
/*   Stored procedure     :  sp_imp_recibo_pago                         */
/*   Base de datos        :  cob_cartera                                */
/*   Producto             :  Cartera                                    */
/*   Disenado por         :  Francisco Yacelga                          */
/*   Fecha de escritura:  :  12/Dic./1997                               */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*   PROPOSITO                                                          */
/*   Consulta para imprimir el recibo de pago                           */
/************************************************************************/
/*   MODIFICACIONES                                                     */
/*   FECHA          AUTOR          CAMBIO                               */
/*   OCT-2005       Elcira Pelaez  Cambios para el BAC def.5134         */
/*   OCT-2006       Fabian Quintero Defecto 7304                        */
/*   OCT-2006       ELcira Pelaez   Defecto 7365                        */
/*   Feb-2007       Fabian Q        Defecto 7288                        */
/*   Ene-2012       Luis C. Moreno  Adición Saldo Rec a Saldo Capital   */
/*   Feb-2014       I.Berganza      Req: 397 - Reportes FGA             */
/*   Mar-2014       Liana Coto      Req 406. Seguro Deudores Empleados  */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_imp_recibo_pago')
   drop proc sp_imp_recibo_pago
go

create proc sp_imp_recibo_pago (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               smallint    = null, 
   @i_banco             cuenta      = null, 
   @i_operacion         char(1)     = null,
   @i_formato_fecha     int         = null,
   @i_sec_pag           int         = null,
   @i_secuencial        int         = 0,
   @i_usuario           catalogo    = null
)
as
declare
   @w_sp_name               varchar(32),
   @w_return                int,
   @w_error                 int,
   @w_operacionca           int,
   @w_tamanio               int,
   @w_sec_ing               int,
   @w_sec_pag               int,
   @w_tipo                  char(1),    
   @w_det_producto          int,
   @w_cliente               int,
   @w_ced_ruc               varchar(15),
   @w_toperacion_desc       varchar(100),
   @w_moneda                tinyint,
   @w_moneda_desc           varchar(30),
   @w_concepto_acc          catalogo,
   @w_concepto_mfs          catalogo,
   @w_concepto_fin          catalogo,
   @w_fecha_pago            varchar(10),
   @w_sec_recibo            int, 
   @w_oficina               smallint,
   @w_desOficina            varchar(64),
   @w_nro_recibo            varchar(10),
   @w_ref_exterior          cuenta,
   @w_tasa_nominal_int      float,
   @w_tasa_nominal_imo      float,
   @w_saldo_capital         money,
   @w_referencia            catalogo,
   @w_signo                 char(1),
   @w_factor                float,
   @w_toperacion            catalogo,
   @w_oficial               int,
   @w_gerente               varchar(60),
   @w_porcentaje            catalogo,
   @w_sec_pag_his           int,
   @w_fecha_pago_mora       datetime,
   @w_fecha_ultimo_pago     datetime,
   @w_cedula                varchar(30),
   @w_con_seguros           int,
   @w_seguro_vida           char(2),
   @w_con_otros_seg         int,
   @w_otros_seguros         char(2),
   @w_cuotas_vencidas       int,
   @w_vlr_vencido           money,
   @w_cuotas_pagadas        int,
   @w_cuotas_pendientes     int,
   @w_estado                tinyint,
   @w_estado_juridico       varchar(24),
   @w_fec_est_juridico      datetime,
   @w_saldo_actual          money,
   @w_saldo_cap             money,
   @w_saldo_mora            money,
   @w_saldo_venc            money,
   @w_capital_rubro         money,   
   @w_moneda_uvr            tinyint,
   @w_vlr_moneda            money,         
   @w_saldo_cap_uvr         money,
   @w_saldo_cap_pesos       money,
   @w_tipo_garantia         descripcion,   
   @w_des_garantia          varchar(255),
   @w_tasa_nominal          float,
   @w_tasa_vida             float,
   @w_tasa_todo_riesgo      float,
   @w_periodicidad          descripcion,
   @w_fec_ult_pago          datetime,
   @w_cuotas_anticipadas    int,
   @w_prox_pago             datetime,
   @w_tipo_operacion        descripcion,   
   @w_contador              int,
   @w_tmonto                money,   
   @w_tfecha                datetime,
   @w_desembolsos           varchar(255),
   @w_fecha_vence           datetime,
   @w_nombre                descripcion,            
   @w_tipo_amortizacion     varchar(15),
   @w_fecha_fin             datetime,
   @w_reestructuracion      char(6),
   @w_tdividendo            catalogo,
   @w_tramite               int,
   @w_estado_sec            char(3),
   @w_fcontador             float,
   @w_numero_reest          int,
   @w_cotizacion_uvr        float,
   @w_proxcapital           float,
   @w_proxinteres           float,   
   @w_proxseguros           float,
   @w_proxotros             float,
   @w_beneficiario          varchar(50),
   @w_tid                   char(5),
   @w_tdes                  varchar(64), 
   @w_tcuota                int, 
   @w_tdias                 int,
   @w_tfecini               datetime, 
   @w_tfecfin               datetime, 
   @w_tmontomon             money, 
   @w_tmontomn              money,
   @w_ttasa                 float,
   @w_tporcentaje           float,
   @w_monto                 money,
   @w_fecha_ini             datetime,
   @w_tconcepto             catalogo,
   @w_num_dec               tinyint,
   @w_max_divi_vig          smallint,
   @w_proxseguros_sgt       money,
   @w_proxseguros_ven       money,
   @w_proxinteres_ant       money,
   @w_proxotros_ven         money,
   @w_proxotros_sgt         money,
   @w_monto_mop             money,
   @w_cotizacion_pag        float,
   @w_ab_secuencial_ing     int,
   @w_fec_pago_ant          datetime,
   @w_secuencial            int,
   @w_contador_regs         int,
   @w_codigo_externo        cuenta,
   @w_margen_redescuento    float,
   @w_estado_op             int,
   @w_rowcount              int,
   @w_fec_pag               datetime,
   @w_monto_mpg             money,
   @w_div_cancelado         smallint,
   @w_secuencial_pag        smallint,
   @w_vlr_x_amort           money, --293 LCM
   @w_tiene_reco            char(1),--LCM - 293
   @w_recono                money,   --LCM - 293
   @w_sec_rpa_rec           int, --LCM - 293
   @w_sec_rpa_pag           int, --LCM - 293
   @w_monto_reconocer       money,--LCM - 293
   @w_vlr_calc_fijo         money,--LCM - 293
   @w_div_pend              money--LCM - 293


---- Captura nombre de Stored Procedure  
select @w_sp_name = 'sp_imp_recibo_pago'

select @w_operacionca = op_operacion,
       @w_moneda      = op_moneda,
       @w_estado_op   = op_estado
from ca_operacion
where op_banco = @i_banco  


if @w_estado_op = 3
begin
   if not exists (select 1 from ca_transaccion
                  where tr_banco = @i_banco)
   begin
--    PRINT 'ATENCION !!!  Operacion cancelada para que la impresion sea correcta,recuperar historicos'
    select @w_error = 701119
    goto ERROR
  end 
end

exec sp_decimales
   @i_moneda    = @w_moneda, 
   @o_decimales = @w_num_dec out


select @i_formato_fecha = 103

/* LCM - 293: CONSULTA LA TABLA DE RECONOCIMIENTO PARA VALIDAR SI LA OBLIGACION TIENE RECONOCIMIENTO */
select @w_vlr_calc_fijo        = 0,
       @w_div_pend             = 0

select @w_vlr_calc_fijo = isnull(pr_vlr_calc_fijo,0),
       @w_div_pend      = isnull(pr_div_pend,0),
       @w_vlr_x_amort   = pr_vlr - pr_vlr_amort
from ca_pago_recono with (nolock)
where pr_operacion = @w_operacionca
and   pr_estado = 'A'

if @@rowcount > 0
   select @w_tiene_reco = 'S'

/* CABECERA DE LA IMPRESION */
if @i_operacion = 'C'
begin

   delete from ca_consulta_rec_pago_tmp
   where usuario = @i_usuario

   select 
   @w_cliente            = op_cliente, 
   @w_operacionca        = op_operacion,
   @w_toperacion_desc    = A.valor,
   @w_moneda             = op_moneda,
   @w_moneda_desc        = mo_descripcion,
   @w_ref_exterior       = op_ref_exterior,
   @w_toperacion         = op_toperacion,
   @w_oficial            = op_oficial,
   @w_operacionca        = op_operacion,            
   @w_estado             = op_estado,
   @w_tipo_amortizacion  = op_tipo_amortizacion,
   --@w_fecha_fin          = convert(varchar(10),op_fecha_fin,103),
   @w_fecha_fin          = op_fecha_fin,
   @w_numero_reest       = op_numero_reest,
   @w_tdividendo         = op_tdividendo,
   @w_tramite            = op_tramite,
   @w_monto              = op_monto,
   @w_monto_mop          = op_monto_aprobado,
   @w_fecha_ini          = op_fecha_ini,
   @w_codigo_externo     = op_codigo_externo,
   @w_margen_redescuento = op_margen_redescuento

   from ca_operacion, cobis..cl_catalogo A, cobis..cl_moneda
   where op_banco    = @i_banco
   and op_toperacion = A.codigo
   and op_moneda     = mo_moneda

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end  

   select @w_monto_mop = ro_valor 
   from ca_rubro_op
   where ro_operacion  = @w_operacionca
   and   ro_concepto   = 'CAP'
   and   ro_tipo_rubro = 'C'

   select @w_max_divi_vig = max(di_dividendo)
   from ca_dividendo
   where di_operacion = @w_operacionca
   and   di_estado = 1


-- Inicio LAM 

   --  Encuentra el Producto  
   select @w_tipo = pd_tipo
   from cobis..cl_producto
   where pd_producto = 7
   set transaction isolation level read uncommitted

   --  Encuentra el Detalle de Producto  
   select @w_det_producto = dp_det_producto
   from   cobis..cl_det_producto
   where dp_producto  = 7
   and   dp_tipo      = @w_tipo
   and   dp_moneda    = @w_moneda
   and   dp_cuenta    = @i_banco
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 
   begin
      select @w_error = 710023
      goto ERROR
   end

   --Realizar la consulta de Informacion General del Cliente

   select @w_cedula   = isnull(cl_ced_ruc,p_pasaporte), 
          @w_nombre   = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' 
                      + rtrim(en_nombre),1,60))
   from  cobis..cl_cliente,cobis..cl_ente
   where cl_det_producto   = @w_det_producto
   and   cl_rol            = 'D'
   and   en_ente           = cl_cliente
   and   cl_cliente        = @w_cliente
   set transaction isolation level read uncommitted

   select @w_con_seguros = count(*) 
   from ca_concepto,ca_rubro_op
   where  co_concepto  = ro_concepto
   and    co_categoria = 'S'
   and    co_concepto  in (select a.codigo from cobis..cl_catalogo a, cobis..cl_tabla b where b.codigo = a.tabla and b.tabla = 'ca_rubros_seg_deu') -- = 'SEGDEUVEN' --'SEGVIDA'
   and    ro_operacion = @w_operacionca

   if @w_con_seguros >= 1 
       select @w_seguro_vida = 'Si'
   else
       select @w_seguro_vida = 'No'


   select @w_con_otros_seg = count(*) from ca_concepto,ca_rubro_op
   where co_concepto = ro_concepto
   and   co_categoria = 'S'
   and   co_concepto not in (select a.codigo from cobis..cl_catalogo a, cobis..cl_tabla b where b.codigo = a.tabla and b.tabla = 'ca_rubros_seg_deu')  --<> 'SEGDEUVEN' --'SEGVIDA'
   and   ro_operacion = @w_operacionca
   
   if @w_con_otros_seg >= 1 
       select @w_otros_seguros = 'Si'
   else
       select @w_otros_seguros = 'No'   


   select @w_cuotas_vencidas = count(*) from ca_dividendo
   where di_estado = 2
   and   di_operacion = @w_operacionca 


   select @w_vlr_vencido = isnull(sum(am_cuota - am_pagado + am_gracia),0)
   from ca_dividendo, ca_amortizacion
   where di_operacion = am_operacion
   and   am_dividendo = di_dividendo
   and   di_estado = 2
   and   di_operacion = @w_operacionca 
   
   
   select @w_cuotas_pagadas = count(*) from ca_dividendo
   where di_estado = 3
   and   di_operacion = @w_operacionca 

   select @w_cuotas_pendientes = count(*) from ca_dividendo
   where di_estado <> 3
   and   di_operacion = @w_operacionca 

   -- Ojo estado no es quemado     
   select 
   @w_fec_est_juridico = co_fecha_ingr,               
   @w_estado_juridico = (select c.valor
                         from   cobis..cl_catalogo c, cobis..cl_tabla t
                         where  c.tabla = t.codigo
                         and    t.tabla = 'cr_estado_cobranza'
                         and    c.codigo = X.co_estado)      
   from cob_cartera..ca_operacion, cob_credito..cr_cobranza X
   where co_cliente = op_cliente
   and op_operacion = @w_operacionca    
   
   if  @w_estado_juridico is null
      select @w_estado_juridico = 'NORMALIZADO'
      
      
   select @w_tipo_garantia = cu_tipo,
          @w_des_garantia  = cu_descripcion
   from  cob_custodia..cu_custodia,cob_credito..cr_gar_propuesta
   where cu_codigo_externo = gp_garantia
   and   gp_tramite = @w_tramite


   -- Tasas 
   select @w_tasa_nominal_imo = round(ts_porcentaje,4)
   from ca_tasas, ca_rubro_op
   where ts_operacion = @w_operacionca
   and ts_operacion = ro_operacion
   and ts_concepto = ro_concepto
   and ts_referencial = ro_referencial
   and ts_concepto = 'IMO'


   select @w_tasa_nominal_int = round(ro_porcentaje_efa,4)
   from ca_rubro_op
   where ro_operacion = @w_operacionca
   and ro_concepto = 'INT'

   select @w_tasa_vida = round(ro_porcentaje,4)
   from  ca_concepto,ca_rubro_op
   where co_concepto = ro_concepto
   and   co_categoria = 'S'
   and   co_concepto in (select a.codigo from cobis..cl_catalogo a, cobis..cl_tabla b where b.codigo = a.tabla and b.tabla = 'ca_rubros_seg_deu')  --= 'SEGDEUVEN' --'SEGVIDA'
   and   ro_operacion = @w_operacionca

   select @w_tasa_todo_riesgo = round(ro_porcentaje,4)
   from  ca_concepto,ca_rubro_op
   where co_concepto = ro_concepto
   and   co_categoria = 'S'
   and   co_concepto = 'SEGTORVIVI'
   and   ro_operacion = @w_operacionca

   select @w_periodicidad = td_descripcion 
   from  ca_tdividendo
   where td_tdividendo = @w_tdividendo


   select @w_fec_ult_pago = ab_fecha_pag
   from  ca_abono
   where ab_tipo = 'PAG'
   and   ab_operacion = @w_operacionca
   and   ab_estado = 'A'
   and   ab_secuencial_ing = @i_sec_pag 


   select @w_ab_secuencial_ing = max(ab_secuencial_ing)
   from  ca_abono
   where ab_tipo = 'PAG'
   and   ab_operacion = @w_operacionca
   and   ab_fecha_pag <= @w_fec_ult_pago 
   and   ab_estado = 'A'


--- FECHA PAGO ANTERIOR AL SECUENCIAL CONSULTADO
   select @w_fec_pago_ant = max(ab_fecha_pag)
   from  ca_abono
   where ab_tipo = 'PAG'
   and   ab_operacion = @w_operacionca
   and   ab_estado = 'A'
   and   ab_secuencial_ing < @i_sec_pag


   -- SECUENCIALES A LA OPERACION 

   select 
   @w_sec_ing    = ab_secuencial_ing,
   @w_sec_pag    = ab_secuencial_pag,
   @w_estado_sec = ab_estado,
   @w_fecha_pago = convert(varchar(10),ab_fecha_pag, @i_formato_fecha),
   @w_sec_recibo = ab_nro_recibo,
   @w_oficina    = ab_oficina
   from ca_abono
   where ab_operacion    = @w_operacionca
   and ab_secuencial_ing = @i_sec_pag  

   if isnull(@w_oficina,0) > 0 
   begin
      select @w_desOficina = of_nombre
      from  cobis..cl_oficina
      where of_oficina = @w_oficina
      set transaction isolation level read uncommitted
      end
   else
      select @w_desOficina = 'DESCONOCIDA' 

   /** GENERACION DEL NUMERO DE RECIBO **/
   exec @w_return = sp_numero_recibo
        @i_tipo       = 'G',
        @i_oficina    = @w_oficina,
        @i_secuencial = @w_sec_recibo,
        @o_recibo     = @w_nro_recibo out
   if @w_return <> 0
   begin
       select @w_error = @w_return
       goto ERROR
   end

   --SALDO CAPITAL

   select 
   @w_capital_rubro = isnull(sum(am_cuota + am_gracia - am_pagado),0) 
   from ca_concepto, ca_amortizacion 
   where co_concepto   = am_concepto 
   and   co_categoria  = 'C'
   and   am_operacion  = @w_operacionca

   select @w_capital_rubro = @w_capital_rubro + @w_vlr_x_amort

   select @w_fecha_pago     = convert(varchar(10),ab_fecha_pag, 103),
          @w_fec_pag        = ab_fecha_pag,
          @w_cotizacion_pag = abd_cotizacion_mpg   
   from ca_abono_det, ca_abono
   where abd_secuencial_ing = @w_sec_ing 
   and   abd_operacion      = @w_operacionca
   and ab_secuencial_ing    = abd_secuencial_ing
   and ab_operacion         = abd_operacion 
   and ab_estado            = 'A'
   and abd_tipo             in ('PAG','CON','SOB')
   order by abd_tipo


   exec @w_return = sp_conversion_moneda
        @s_date              = @w_fec_pag,
--        @s_date              = @w_fecha_pago,
        @i_opcion            = 'L',
        @i_moneda_monto      = @w_moneda,
        @i_moneda_resultado  = 0,
        @i_monto             = @w_capital_rubro,
        @i_fecha             = @w_fec_ult_pago,
        --@o_monto_resultado  = @w_saldo_cap out,
        @o_tipo_cambio       = @w_cotizacion_uvr out

   select @w_moneda_uvr = pa_tinyint
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'MUVR'
   set transaction isolation level read uncommitted

   if @w_moneda = @w_moneda_uvr 
   begin
      select @w_saldo_cap_uvr   = @w_capital_rubro
      select @w_saldo_cap_pesos = @w_capital_rubro * @w_cotizacion_uvr
   end
   else 
   begin
      select @w_saldo_cap_uvr = 0
      select @w_saldo_cap_pesos = @w_capital_rubro
   end 

   select @w_cuotas_anticipadas = count(*) 
   from  ca_dividendo
   where di_estado    = 3
   and   di_fecha_ven > @s_date
   and   di_operacion = @w_operacionca

   select @w_prox_pago = di_fecha_ven from ca_dividendo   
   where di_estado = 1
   and   di_operacion = @w_operacionca

   select @w_tipo_operacion = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'ca_toperacion'
   and    b.codigo = a.tabla
   and    a.codigo = convert(varchar(64),@w_toperacion)
   set transaction isolation level read uncommitted

   select @w_desembolsos = ' desembolso: ' + convert(varchar(10),@w_fecha_ini,103) + '& Monto: ' + convert(varchar(25),round(convert(float,@w_monto),@w_num_dec)) + '&'
      
   select @w_fecha_vence = min(di_fecha_ven) from ca_dividendo   
   where di_estado = 2
   and   di_operacion = @w_operacionca 

   if @w_numero_reest > 0 
      select @w_reestructuracion = 'Si'
   else
      select @w_reestructuracion = 'Nuevo'      

   if ltrim(rtrim(@w_tipo_amortizacion)) = 'ALEMANA'      
      select @w_tipo_amortizacion = 'CAPITAL FIJO'
   else
      if rtrim(ltrim(@w_tipo_amortizacion)) = 'FRANCESA'
         select @w_tipo_amortizacion = 'CUOTA FIJA'
      else
         select @w_tipo_amortizacion = 'PERSONALIZADA'
   
   --Capital PROXIMA CUOTA

   select @w_proxcapital = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from ca_dividendo, ca_amortizacion, ca_rubro_op
   where ro_operacion    = @w_operacionca
   and   ro_tipo_rubro   = 'C'  --Capital
   and   am_operacion    = ro_operacion
   and   am_concepto     = ro_concepto
   and   di_operacion    = ro_operacion
   and   am_dividendo    = di_dividendo
   and   am_dividendo    = di_dividendo
   and   di_estado       in(1,2)  -- Vencido

   if @w_tiene_reco = 'S'
   begin
      select @w_monto_reconocer = 0,
             @w_recono = 0

      if @w_div_pend > 0
         -- Obtener valor de cuota fija a reconocer por concepto de capital para el dividendo vigente
         select @w_monto_reconocer = round(isnull(@w_vlr_calc_fijo / @w_div_pend, 0),0)

      select @w_sec_rpa_rec = dtr_secuencial
      from
      ca_transaccion with (nolock),
      ca_det_trn with (nolock)
      where tr_operacion  = @w_operacionca
      and   tr_operacion  = dtr_operacion
      and   tr_secuencial = dtr_secuencial
      and   tr_secuencial > 0
      and   tr_tran       = 'RPA'
      and   tr_estado     <> 'RV'
      and   dtr_concepto  in (select c.codigo
                              from cobis..cl_tabla t, cobis..cl_catalogo c
                              where t.tabla = 'ca_fpago_reconocimiento'
                              and   t.codigo = c.tabla) -- Req. 397 Extrayendo codigo para las formas de pago por reconocimiento


      /* OBTIENE EL SECUENCIAL PAG DEL PAGO POR RECONOCIMIENTO */
      select @w_sec_rpa_pag = ab_secuencial_pag
      from ca_abono with (nolock)
      where ab_operacion = @w_operacionca
      and   ab_secuencial_rpa = @w_sec_rpa_rec

      if @w_sec_rpa_pag <> 0
      begin 
          select @w_recono = isnull(sum(am_cuota),0)
          from ca_det_trn with (nolock), ca_amortizacion with (nolock),ca_dividendo
          where di_operacion  = @w_operacionca
          and   am_operacion  = di_operacion
          and   am_dividendo  = di_dividendo
          and   di_estado     = 2
          and   am_dividendo  = dtr_dividendo
          and   dtr_secuencial = @w_sec_rpa_pag
          and   dtr_operacion = am_operacion
          and   dtr_concepto = 'CAP'
          and   am_concepto  = dtr_concepto
          and   dtr_monto <= am_cuota
      end
      /* Suma valor capital normal + Valor Capital Reconocimiento Dividendos Vencidos + Valor Cuota Fija Dividendo Vigente */
      select @w_proxcapital = @w_proxcapital + @w_recono + @w_monto_reconocer
   end

   --Interes VENCIDO Y VIGENTE, SEA ANTICIPADO O AL VENCIMIENTO
   select @w_proxinteres = 0

   select @w_proxinteres = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from ca_dividendo, ca_amortizacion, ca_rubro_op
   where ro_operacion    = @w_operacionca
   and   ro_tipo_rubro   in ('I','M')  
   and   am_operacion    = ro_operacion
   and   am_concepto     = ro_concepto
   and   di_operacion    = ro_operacion
   and   am_dividendo    = di_dividendo
   and   di_estado       in(1,2)  -- Vencido

   if exists (select 1 from ca_rubro_op
             where ro_operacion = @w_operacionca 
             and   ro_concepto  = 'INTANT')
   begin
      select @w_proxinteres_ant = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from ca_dividendo, ca_amortizacion, ca_rubro_op
      where ro_operacion    = @w_operacionca
      and   ro_tipo_rubro   = 'I'
      and   am_operacion    = ro_operacion
      and   am_concepto     = ro_concepto
      and   di_operacion    = ro_operacion
      and   am_dividendo    = di_dividendo
      and   am_dividendo    = @w_max_divi_vig + 1

      select @w_proxinteres = isnull(sum(@w_proxinteres + @w_proxinteres_ant),0)

      select @w_tasa_nominal_int = round(ro_porcentaje_efa,4)
      from ca_rubro_op
      where ro_operacion = @w_operacionca
      and ro_concepto = 'INTANT'
 
   end

   --Seguros
   select @w_proxseguros_ven = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from ca_dividendo, ca_amortizacion, ca_concepto
   where di_operacion    = @w_operacionca
   and   co_categoria    = 'S' 
   and   am_operacion    = di_operacion
   and   am_concepto     = co_concepto
   and   am_concepto     in (select a.codigo from cobis..cl_catalogo a, cobis..cl_tabla b where b.codigo = a.tabla and b.tabla = 'ca_rubros_seg_deu')  --= 'SEGDEUVEN' --'SEGVIDA'
   and   am_dividendo    = di_dividendo 
   and   di_estado       in(1,2)  -- Vencido

   select @w_proxseguros_sgt = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from ca_dividendo, ca_amortizacion, ca_concepto
   where di_operacion    = @w_operacionca
   and   co_categoria   = 'S' 
   and   am_operacion    = di_operacion
   and   am_concepto     = co_concepto
   and   am_concepto     in (select a.codigo from cobis..cl_catalogo a, cobis..cl_tabla b where b.codigo = a.tabla and b.tabla = 'ca_rubros_seg_deu')  --= 'SEGDEUVEN' --'SEGVIDA'
   and   am_dividendo    = di_dividendo 
   and   am_dividendo    = @w_max_divi_vig + 1

   select @w_proxseguros = isnull(sum(@w_proxseguros_ven ),0)

   --Otros
   select @w_proxotros_ven = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from ca_dividendo, ca_amortizacion, ca_concepto
   where di_operacion    = @w_operacionca
   and   co_categoria    not in ('S', 'C', 'M', 'I')
   and   am_operacion    = di_operacion
   and   am_concepto     = co_concepto 
   and   am_concepto     not in (select a.codigo from cobis..cl_catalogo a, cobis..cl_tabla b where b.tabla = 'ca_rubros_seg_deu') --<> 'SEGDEUVEN' --'SEGVIDA'
   and   am_dividendo    = di_dividendo 
   and   di_estado       in(1,2)  -- Vencido

   select @w_proxotros_sgt = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from ca_dividendo, ca_amortizacion, ca_concepto
   where di_operacion    = @w_operacionca
   and   co_categoria    not in ('S', 'C', 'M', 'I')
   and   am_operacion    = di_operacion
   and   am_concepto     = co_concepto 
   and   am_concepto     not in (select a.codigo from cobis..cl_catalogo a, cobis..cl_tabla b where b.codigo = a.tabla and b.tabla = 'ca_rubros_seg_deu')  --<> 'SEGDEUVEN' --'SEGVIDA'
   and   am_dividendo    = di_dividendo 
   and   am_dividendo    = @w_max_divi_vig + 1

   select @w_proxotros = isnull(sum(@w_proxotros_ven + @w_proxotros_sgt),0)

   ---SALDO ACTUAL
   select @w_saldo_actual = sum(am_cuota + am_gracia - am_pagado) 
   from ca_amortizacion
   where am_operacion = @w_operacionca

-- Fin LAM   

   select @w_secuencial = 1
   declare
   cursor_operacion cursor
   for select 'APL',
              --co_descripcion = case substring(convert(char(10),dtr_codvalor),4,2) 
              co_descripcion = case convert(char(10),ar_estado) 
                               when '1'  then ltrim(rtrim(co_descripcion)) + '-' + 'VIG'
                               when '2'  then ltrim(rtrim(co_descripcion)) + '-' + 'VEN'
                               when '9'  then ltrim(rtrim(co_descripcion)) + '-' + 'SUS'
                               when '4'  then ltrim(rtrim(co_descripcion)) + '-' + 'CAS'
                               when '0'  then ltrim(rtrim(co_descripcion)) + '-' + 'NOVIG'
                               else  co_descripcion
                               end,
              co_concepto, 
              ar_dividendo,  --dtr_dividendo, 
              di_dias_cuota,
              di_fecha_ini,
              di_fecha_ven,
              --convert(varchar(10),di_fecha_ini,103),
              --convert(varchar(10),di_fecha_ven,103),
              ar_monto,  --dtr_monto,
              ar_monto_mn --dtr_monto_mn
       from   ca_abono_rubro, ca_dividendo,ca_concepto
       where  ar_operacion = di_operacion
       and    ar_dividendo = di_dividendo
       and    ar_concepto  = co_concepto
       and    ar_operacion = @w_operacionca
       and    ar_secuencial= @w_sec_pag
       and    ar_monto > 0
       and    ar_estado <> 7 -- NO INCLUR CONCEPTOS DIFERIDOS
       order by ar_dividendo, co_descripcion 
   for read only
   
   open cursor_operacion
   fetch cursor_operacion
   into @w_tid, @w_tdes, @w_tconcepto, @w_tcuota, @w_tdias, @w_tfecini, @w_tfecfin, @w_tmontomon, @w_tmontomn

   while @@fetch_status = 0 
   begin   
      if @@fetch_status = -1 
      begin    
         select @w_error = 70899
         goto  ERROR
      end   
      select @w_ttasa = 0

      select @w_ttasa = ts_porcentaje
      from  ca_amortizacion, ca_tasas 
      where ts_operacion = am_operacion
      and   ts_dividendo = am_dividendo
      and   ts_concepto  = am_concepto
      and   ts_concepto  = @w_tconcepto
      and   am_operacion = @w_operacionca
      and   ts_dividendo = @w_tcuota
      if @@rowcount = 0
      begin
         if ltrim(rtrim(@w_tconcepto)) = 'CAP'
            select @w_ttasa = 0 
         else
            select @w_ttasa = ro_porcentaje
            from  ca_amortizacion, ca_rubro_op 
            where ro_operacion = @w_operacionca
            and am_operacion   = ro_operacion
            and am_concepto    = ro_concepto
            and ro_concepto    = @w_tconcepto
            and am_dividendo   <= @w_tcuota
      end 

      insert into ca_consulta_rec_pago_tmp
            (identifica,   secuencial, usuario,
             descripcion,  cuota,      dias,
             fecha_ini,    fecha_fin,  monto,
             monto_mn,     tasa)
      values(@w_tid,       @w_secuencial, @i_usuario,
             @w_tdes,      @w_tcuota,     @w_tdias,
             @w_tfecini,   @w_tfecfin,    @w_tmontomon,
             @w_tmontomn,  @w_ttasa)
      
      fetch cursor_operacion
      into @w_tid, @w_tdes, @w_tconcepto, @w_tcuota, @w_tdias, @w_tfecini, @w_tfecfin, @w_tmontomon, @w_tmontomn
      
      select @w_secuencial = @w_secuencial + 1
   end
   close cursor_operacion
   deallocate cursor_operacion

   -- Tabla para almacenar los valores para pagos por reconocimiento Req. 397
   select distinct limite_sup
   into #codvalor_rec
   from cob_credito..cr_corresp_sib
   where tabla = 'T143'

   --CURSOR RECONOCIMIENTO - LCM - 293
   declare
   cursor_reco cursor
   for select 'APL',
              'CAPITAL AMORT REC',
              dtr_monto,
              dtr_monto_mn
       from ca_det_trn
       where dtr_operacion = @w_operacionca
       and   dtr_secuencial = @w_sec_pag
       and   dtr_concepto = 'CAP'
       and   dtr_codvalor in (select limite_sup
                              from #codvalor_rec) -- Req. 397 lectura de limite superior
       order by dtr_monto

   for read only
   
   open cursor_reco
   fetch cursor_reco
   into @w_tid, @w_tdes, @w_tmontomon, @w_tmontomn

   while @@fetch_status = 0 
   begin   
      if @@fetch_status = -1
      begin    
         select @w_error = 70899
         goto  ERROR
      end  

      insert into ca_consulta_rec_pago_tmp
            (identifica,   secuencial, usuario,
             descripcion,  cuota,      dias,
             fecha_ini,    fecha_fin,  monto,
             monto_mn,     tasa)
      values(@w_tid,       @w_secuencial, @i_usuario,
             @w_tdes,      0,             0,
             @w_tfecini,   @w_tfecfin,    @w_tmontomon,
             @w_tmontomn,  0)
      
      fetch cursor_reco
      into @w_tid, @w_tdes, @w_tmontomon, @w_tmontomn
      
      select @w_secuencial = @w_secuencial + 1
   end
   close cursor_reco
   deallocate cursor_reco

   select @w_contador_regs = count(*) from ca_consulta_rec_pago_tmp
   where  usuario = @i_usuario
   
   
   /*SE OPTIENE EL MONTO PAGADO*/
   
   select 
   @w_monto_mpg = abd_monto_mpg
   from ca_abono_det left outer join ca_concepto on abd_concepto = co_concepto 
                     left outer join ca_producto on abd_concepto = cp_producto,
        ca_abono,
        cobis..cl_moneda
   where abd_secuencial_ing  = @w_sec_ing 
   and   abd_operacion       = @w_operacionca
   and   abd_moneda          = mo_moneda
   and   ab_secuencial_ing   = abd_secuencial_ing
   and   ab_operacion        = abd_operacion 
   and   abd_tipo in ('PAG')
   
 --- Datos que envía en arreglos  

   select @i_banco,
          SUBSTRING(@w_cedula,1,15),
          SUBSTRING(@w_nombre,1,100),
          SUBSTRING(@w_moneda_desc,1,40),
          SUBSTRING(@w_seguro_vida,1,2),
          SUBSTRING(@w_otros_seguros,1,2),
          @w_cuotas_vencidas,
          @w_vlr_vencido,
          @w_cuotas_pagadas,
          @w_cuotas_pendientes,         --10
          @w_estado_juridico,
          convert(varchar(10),@w_fec_est_juridico,@i_formato_fecha),
          round(convert(float,@w_saldo_cap_uvr),@w_num_dec),
          @w_saldo_cap_pesos,
          round(convert(float,@w_monto_mop),@w_num_dec),     --15
          SUBSTRING(@w_tipo_garantia,1,64),
          SUBSTRING(@w_des_garantia,1,255),
          @w_tasa_nominal_int,
          @w_tasa_vida,
          @w_tasa_todo_riesgo,         --20
          @w_periodicidad,
          convert(varchar(10),@w_fec_pago_ant,@i_formato_fecha),
          convert(varchar(10),@w_fec_ult_pago,@i_formato_fecha),
          @w_cuotas_anticipadas,
          SUBSTRING(@w_tipo_amortizacion,1,15),
          convert(varchar(10),@w_fecha_fin,@i_formato_fecha),
          SUBSTRING(@w_reestructuracion,1,6),
          convert(varchar(10),@w_prox_pago,@i_formato_fecha),
          @w_tipo_operacion,
          @w_desembolsos,         --30
          convert(varchar(10),@w_fecha_vence,@i_formato_fecha),
          @w_desOficina,
          isnull(@w_sec_recibo,0),
          isnull(@w_nro_recibo,'0001'),
          isnull(@w_sec_pag,0),
          isnull(@w_estado_sec,'NN'),
          @w_moneda,
          round(convert(float,@w_cotizacion_uvr),4),
          @w_proxcapital,
          @w_proxinteres,         -- 40   
          @w_proxseguros,
          @w_proxotros,
          @w_codigo_externo,
          @w_margen_redescuento,
          @w_monto_mpg             

   select @w_contador_regs

   set rowcount 20
   select identifica, 
          descripcion, 
          cuota,
          dias, 
          convert(varchar(10),fecha_ini,@i_formato_fecha), 
          convert(varchar(10),fecha_fin,@i_formato_fecha), 
          round(convert(float,monto),@w_num_dec), 
          monto_mn, 
          tasa,
          secuencial,
          usuario,
          @w_contador_regs
   from ca_consulta_rec_pago_tmp  
   -- from #tasa_interes_tmp
   where usuario = @i_usuario
   order by secuencial
   set rowcount 0 

   /* FORMA DE PAGO */

   select 
   abd_tipo,
   substring(isnull((select co_descripcion from ca_concepto where co_concepto = A.abd_concepto),(select cp_descripcion from ca_producto where cp_producto = A.abd_concepto )),1,60),
   substring(isnull(abd_cuenta,' '),1,30), 
   round(convert(float,abd_cotizacion_mop),4),  
   abd_monto_mpg,
   abd_cotizacion_mop,
   round(convert(float,abd_monto_mop),@w_num_dec),  
   abd_monto_mn,
   substring(isnull(abd_beneficiario,' '),1,25),
   convert(varchar(10),ab_fecha_pag,@i_formato_fecha)
   from ca_abono_det A,
        ca_abono,        
        cobis..cl_moneda
   where abd_secuencial_ing  = @w_sec_ing 
   and   abd_operacion       = @w_operacionca    
   and   abd_moneda          = mo_moneda
   and   ab_secuencial_ing   = abd_secuencial_ing
   and   ab_operacion        = abd_operacion 
   and   abd_tipo in ('PAG','CON','SOB')
   order by abd_tipo
end


if @i_operacion = 'L' 
begin 
   set rowcount 20
   select identifica, 
     descripcion, 
     cuota,
     dias, 
     convert(varchar(10),fecha_ini,@i_formato_fecha), 
     convert(varchar(10),fecha_fin,@i_formato_fecha), 
     round(convert(float,monto),@w_num_dec), 
        monto_mn, 
     tasa,
     secuencial,
     usuario
   from ca_consulta_rec_pago_tmp  
   -- from #tasa_interes_tmp 
   where secuencial > @i_secuencial
   and   usuario = @i_usuario   
   order by secuencial
   set rowcount 0
end



if @i_operacion = 'A' 
begin 

-- SECUENCIALES A LA OPERACION 
   select @w_fecha_pago  = ar_fecha_pag
   from ca_abono_rubro
   where ar_operacion    = @w_operacionca
   and ar_secuencial     = @w_sec_pag_his

   select
   co_concepto,
   ar_moneda,
   isnull(ar_monto, 0),        ---Monto en la moneda del pago (UVrs  o PESOS)
   SUBSTRING(isnull(co_descripcion,''),1,30),
   convert(varchar(10),di_fecha_ini,103),  ---Desde
   isnull(convert(varchar(6),datediff(dd,di_fecha_ini, @w_fecha_pago)),'0'), 
   isnull(ar_tasa_pago,0),  
   isnull(ar_monto_mn,0),                  ----Monto en pesos
   convert(varchar(10), @w_fecha_pago,103),  ---Hasta
   isnull(ar_dividendo,0),
   isnull(di_dias_cuota,0)  --- Este campo se utilizara en front-en si el anterior envia numeros negativos
   from ca_abono_rubro, ca_dividendo, ca_rubro_op, ca_amortizacion,ca_concepto
   where ar_secuencial = @i_sec_pag
   and  ar_operacion = di_operacion
   and  ar_dividendo = di_dividendo
   and  ar_operacion = ro_operacion
   and  ar_concepto = ro_concepto
   and  ar_operacion =  @w_operacionca
   and  am_operacion =  @w_operacionca
   and  am_dividendo = di_dividendo
   and  am_concepto = ar_concepto
   and  am_concepto  = co_concepto
   and  ro_concepto  = co_concepto
   and  ar_afectacion = 'C'
end


-- LISTADO DE PAGOS
if @i_operacion = 'Q'
begin 
   set rowcount 20
   
   select 'NUM. RECIBO'     = ab_nro_recibo,
          'SECUENCIAL ING'  = ab_secuencial_ing,
          'SECUENCIAL PAG'  = ab_secuencial_pag,
          'ESTADO'          = ab_estado,
          'FECHA PAGO'      = convert(varchar(10), ab_fecha_pag, @i_formato_fecha),
          'OFICIAL'         = ab_oficina
   from   ca_abono
   where  ab_operacion      = @w_operacionca
   and    ab_estado         = 'A'   
   and    ab_secuencial_ing > @i_secuencial
   order by ab_secuencial_ing
   
   
 set rowcount 0
 
end


return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

                                                                                              
go

