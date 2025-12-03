/************************************************************************/
/*	Nombre Fisico:		Cadatrep.sp        								*/
/*	Nombre Logico:		sp_datos_reporte                        		*/
/*	Base de datos:		cob_cartera										*/
/*	Producto: 			Cartera											*/
/*	Disenado por:  		Jorge Latorre               					*/
/*	Fecha de escritura:	dic 12 2000  									*/
/************************************************************************/
/*				IMPORTANTE												*/
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/*				PROPOSITO												*/
/*	                                                                	*/ 
/*	I: poblar una tabla para estraccion de reportes                 	*/
/************************************************************************/
/*					MODIFICACIONES										*/
/*		Fecha			Autor					Razon					*/
/*    06/06/2023	 M. Cordova	Cambio variable @w_tr_calificacion_obligacion,*/
/*								de char(1) a catalogo 					*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_datos_reporte')
	drop proc sp_datos_reporte
go

create proc sp_datos_reporte(
        @i_fecha		datetime = null,
	@i_banco		cuenta	 = null,
	@i_operacion		int	 = null)
as
declare @w_sp_name		descripcion,
        @w_return		int,
        @w_error                int,
        @w_ente                 int,
        @w_nombre               descripcion, 
	@w_tr_numero_obligacion  cuenta,
        @w_tr_fecha_proceso       datetime,
        @w_tr_tipo_producto       catalogo,
        @w_tr_oficina_obligacion                         smallint,
        @w_tr_oficial		                         smallint,
        @w_tr_nombre                                     descripcion,
        @w_tr_frecuencia_int                             smallint,
        @w_tr_modalidad_int                              char(10), 
        @w_tr_frecuencia_cap                             smallint,
        @w_tr_valor_ini_obligacion                       money, 
        @w_tr_fecha_ini_obligacion                       datetime,
        @w_tr_calificacion_obligacion                     catalogo,
        @w_tr_clase_cartera                              catalogo,  
        @w_tr_reestructuracion                           char(1),
        @w_tr_estado_obligacion                          descripcion,
        @w_tr_numero_comex                               cuenta,
        @w_tr_numero_deuda_ext                            varchar(15),
        @w_tr_fecha_embarque                             datetime,
        @w_tr_fecha_dex                                  datetime,
        @w_tr_tipo_tasa                                  char(1),
        @w_tr_tasa                                       float,
        @w_tr_tasa_referencial                           float,
        @w_tr_spread                                     float,
        @w_tr_signo                                      char(1),
        @w_tr_tipo_identificacion                        char(2),
        @w_tr_identificacion                             numero, 
        @w_tr_saldo_cap                                  money,
        @w_tr_saldo_int                                  money,
        @w_tr_saldo_mora                                 money,
        @w_tr_saldo_otros                                money,
        @w_tr_valor_causado                              money,
        @w_tr_fecha_ult_pago                             datetime,
        @w_tr_valor_proximo_cuota        	         money,
        @w_tr_fecha_proximo_venc                         datetime,
        @w_tr_dias_vencimiento                           smallint,
        @w_tr_provision_cap                              money,
        @w_tr_provision_int                              money,
        @w_tr_provision_cxc                              money,
        @w_tr_valor_total_gar                            money,
        @w_tr_tipo_linea                                 catalogo,
        @w_op_periodo_int                                smallint,
        @w_op_tdividendo                                 catalogo,
        @w_op_periodo_cap                                smallint,
        @w_op_estado                                     tinyint,    
        @w_td_factor                                     smallint,
        @w_ro_fpago                                      char(1),
        @w_di_dividendo                                  smallint,
        @w_op_dias_anio                                  smallint, 
        @w_op_reajustable                                char(1),
        @w_interes_contingente                           money,
        @w_tr_clase_garantia                             varchar(15),
        @w_valor_seguro_vida                             money,
        @w_forma_pago                                    catalogo,
        @w_tr_cuenta_asociada                            cuenta,
        @w_tr_numero_migracion                           cuenta,
        @w_op_gar_admisible                              char(1),
	@w_saldo_seguro                                  money,
        @w_seguro                                        catalogo,
        @w_pcobis                                        smallint,
	@w_concepto_int					 catalogo,
	@w_op_cliente					 int,
	@w_est_vigente					 tinyint,
	@w_est_vencido					 tinyint,
	@w_op_tramite					 int,
	@w_tr_monto_desembolso				 money,
	@w_tr_fecha_fin					 datetime,
	@w_tr_plazo_total				 int,
	@w_tr_tipo_tabla				 catalogo,
	@w_tr_periodo_gracia_cap			 int,
	@w_tr_periodo_gracia_int			 int,
	@w_op_tplazo					 char(1),
	@w_op_plazo					 int,
	@w_op_tipo_amortizacion				 catalogo,
        @w_div_vencido                                   int,
        @w_dias_cap_ven                                  int,
	@w_moneda 					 tinyint,
	@w_tasa_efa  					 float,
	@w_valor_ult_pago     				 money,
	@w_ncuotas_ven         				 int,
	@w_ncuotas_pag         				 int,
	@w_ncuotas_pac         				 int,
	@w_destino              			 catalogo,
	@w_sec_ult_pago                                  int,
        @w_est_cancelado                                 int

	
       

/**  NOMBRE DEL SP Y FECHA DE HOY **/
select	@w_sp_name = 'sp_datos_reporte'

/** INICIALIZACION DE VARIABLES **/
select @w_di_dividendo = 0,
@w_tr_dias_vencimiento = 0

select @w_concepto_int = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_est_vigente = 1,
       @w_est_vencido = 2,
       @w_est_cancelado  = 3

/** DATOS DE LA OPERACION **/
select 
@w_tr_numero_obligacion        = op_banco,
@w_tr_tipo_producto            = op_toperacion, 
@w_tr_oficina_obligacion       = op_oficina, 
@w_tr_oficial                  = op_oficial, 
@w_tr_nombre                   = op_nombre, 
@w_op_periodo_int              = op_periodo_int, 
@w_op_tdividendo               = op_tdividendo,
@w_op_periodo_cap              = op_periodo_cap, 
@w_tr_valor_ini_obligacion     = op_monto,
@w_tr_fecha_ini_obligacion     = op_fecha_ini,
@w_tr_calificacion_obligacion  = op_calificacion, 
@w_tr_clase_cartera            = op_clase,
@w_tr_reestructuracion         = op_reestructuracion,
@w_op_estado 		       = op_estado,
@w_tr_numero_comex	       = op_ref_exterior,
@w_tr_numero_deuda_ext         = op_num_deuda_ext,
@w_tr_fecha_embarque           = op_fecha_embarque,
@w_tr_fecha_dex                = op_fecha_dex,
@w_tr_tipo_tasa                = op_reajustable,
@w_op_dias_anio                = op_dias_anio,
@w_tr_tipo_linea               = op_tipo_linea,
@w_op_gar_admisible            = op_gar_admisible,
@w_forma_pago                  = op_forma_pago,
@w_tr_cuenta_asociada          = op_cuenta,
@w_tr_numero_migracion         = op_migrada,
@w_op_cliente                  = op_cliente,
@w_op_tramite                  = op_tramite,
@w_tr_fecha_fin                = op_fecha_fin,
@w_op_tplazo                   = op_tplazo,
@w_op_plazo                    = op_plazo,
@w_op_tipo_amortizacion        = op_tipo_amortizacion,
@w_tr_periodo_gracia_cap       = op_gracia_cap,
@w_tr_periodo_gracia_int       = op_gracia_int,
@w_moneda                      = op_moneda,
@w_destino                     = op_destino
from  ca_operacion
where op_operacion = @i_operacion
 
-- calcular el periodo total de la obligacion
select @w_tr_plazo_total = td_factor * @w_op_plazo 
from  ca_tdividendo 
where td_tdividendo = @w_op_tplazo 

-- determinar tipo de cuota
if @w_op_tipo_amortizacion = 'FRANCESA'
   select @w_tr_tipo_tabla = 'FIJA'
else
   select @w_tr_tipo_tabla = 'VARIABLE'

-- consultar monto desembolso
select @w_tr_monto_desembolso = isnull(sum(dm_monto_mop),0)
from   ca_desembolso
where  dm_operacion = @i_operacion

-- calcular la frecuencia de intereses ok

select @w_tr_frecuencia_int = td_factor * @w_op_periodo_int 
from  ca_tdividendo 
where td_tdividendo = @w_op_tdividendo 

-- calcular la modalidad de intereses ok
  
select @w_ro_fpago = ro_fpago
from  ca_rubro_op 
where ro_operacion = @i_operacion 
and   ro_concepto =  @w_concepto_int         
        
if @w_ro_fpago = 'P'
   select @w_tr_modalidad_int = 'VENCIDA'

if @w_ro_fpago = 'A'
   select @w_tr_modalidad_int = 'ANTICIPADA'

-- calcular la frecuencia de CAPITAL ok
        
select @w_tr_frecuencia_cap = td_factor *  @w_op_periodo_cap
from   ca_tdividendo
where  td_tdividendo = @w_op_tdividendo
   
-- estado de la obligacion ok

select @w_tr_estado_obligacion  = es_descripcion 
from  ca_estado 
where es_codigo = @w_op_estado 

-- tasas ok
if ltrim(rtrim(@w_tr_tipo_tasa)) = 'S'
   select @w_tr_tasa_referencial = vd_valor_default,
   @w_tr_tasa = ro_porcentaje, 
   @w_tasa_efa = ro_porcentaje_efa,
   @w_tr_spread = ro_factor, 
   @w_tr_signo = ro_signo
   from ca_rubro_op, ca_valor_det  
   where ro_concepto = @w_concepto_int 
   and ro_operacion = @i_operacion 
   and ro_referencial = vd_tipo 		

if ltrim(rtrim(@w_tr_tipo_tasa)) = 'N'
   select @w_tr_tasa_referencial = vd_valor_default,
   @w_tr_tasa = ro_porcentaje, 
   @w_tasa_efa = ro_porcentaje_efa
   from ca_rubro_op, ca_valor_det  
   where ro_concepto = @w_concepto_int 
   and ro_operacion = @i_operacion
   and ro_referencial = vd_tipo 		
           
   select @w_tr_spread = null, 
   @w_tr_signo = null           
                     
-- informacion de clientes ok

select 
@w_tr_tipo_identificacion = en_tipo_ced,
@w_tr_identificacion =  en_ced_ruc
from cobis..cl_ente
where en_ente = @w_op_cliente
set transaction isolation level read uncommitted
        
-- SALDO DE CAPITAL
         
select @w_tr_saldo_cap = sum(am_cuota+am_gracia-am_pagado)
from   ca_amortizacion, ca_rubro_op
where  am_operacion     = @i_operacion
and    ro_operacion     = @i_operacion
and    am_operacion     = ro_operacion
and    am_concepto      = ro_concepto
and    ro_tipo_rubro    = 'C' -- CAPITALES   

                                      
-- SALDO DE intereses
           
select @w_tr_saldo_int = sum(am_acumulado+am_gracia-am_pagado)
from   ca_amortizacion, ca_rubro_op
where  am_operacion     = @i_operacion
and    ro_operacion     = @i_operacion
and    am_operacion     = ro_operacion
and    am_concepto      = ro_concepto
and    ro_tipo_rubro    = 'I' -- INTERESES

-- SALDO DE mora

select @w_tr_saldo_mora = sum(am_cuota+am_gracia-am_pagado)
from   ca_amortizacion, ca_rubro_op
where  am_operacion     = @i_operacion
and    ro_operacion     = @i_operacion
and    am_operacion     = ro_operacion
and    am_concepto      = ro_concepto
and    ro_tipo_rubro    = 'M' -- MORA   

-- SALDO otros
           
select @w_tr_saldo_otros = sum(am_cuota+am_gracia-am_pagado)
from   ca_amortizacion, ca_rubro_op
where  am_operacion     = @i_operacion
and    ro_operacion     = @i_operacion
and    am_operacion     = ro_operacion
and    am_concepto      = ro_concepto
and    ro_tipo_rubro    not in ('C','I','M') --OTROS CONCEPTOS


-- valor causado ok

select  
@w_tr_valor_causado =  round((ro_porcentaje * @w_tr_saldo_cap) / (100 * @w_op_dias_anio),2) 
from ca_rubro_op
where ro_operacion  = @i_operacion
and   ro_tipo_rubro = 'I'
  
-- fecha ultimo pago  y el valor pagado en este ok

select @w_sec_ult_pago = max(ab_secuencial_ing)
from ca_abono 
where ab_operacion = @i_operacion
and ab_estado = 'A'
and ab_secuencial_pag > 0


select @w_tr_fecha_ult_pago = ab_fecha_pag,
       @w_valor_ult_pago    = abd_monto_mop
from ca_abono,ca_abono_det
where ab_operacion = @i_operacion
and   ab_secuencial_ing = @w_sec_ult_pago
and ab_operacion = abd_operacion
and ab_secuencial_ing = ab_secuencial_ing


-- dividendos y fecha ok           
select @w_tr_dias_vencimiento = datediff(dd, di_fecha_ven, @i_fecha)
from ca_dividendo
where di_operacion = @i_operacion
and   di_estado    = @w_est_vencido
group by di_operacion, di_estado, di_fecha_ven, di_dividendo
having di_dividendo = min(di_dividendo)

select 
@w_di_dividendo = di_dividendo,
@w_tr_fecha_proximo_venc = di_fecha_ven
from ca_dividendo
where di_operacion = @i_operacion
and   di_estado = @w_est_vigente

if @w_di_dividendo != 0
   select @w_tr_valor_proximo_cuota = sum(am_cuota+am_gracia-am_pagado)
   from   ca_amortizacion
   where  am_operacion     = @i_operacion
   and    am_dividendo     = @w_di_dividendo
else
   select @w_tr_valor_proximo_cuota = 0


-- provision

select 
@w_tr_provision_cap = co_prov_cap,
@w_tr_provision_int = co_prov_int,
@w_tr_provision_cxc = co_prov_ctasxcob
from 
cob_credito..cr_calificacion_op
where co_producto  = 7 
and   co_operacion = @i_operacion

-- garantias

select @w_tr_valor_total_gar = isnull(sum(cu_valor_actual),0)
from 
cob_credito..cr_gar_propuesta,
cob_custodia..cu_custodia 
where gp_tramite = @w_op_tramite 
and   cu_codigo_externo = gp_garantia 

                    
if @w_op_gar_admisible = 'S'
   select @w_tr_clase_garantia = 'ADMISIBLE'
else  begin
   if @w_op_gar_admisible = 'N' 
      select @w_tr_clase_garantia = 'OTRAS GARANTIAS'
   else
      select @w_tr_clase_garantia = 'SIN ASOCIAR'
end 

select @w_interes_contingente = isnull(sum(am_cuota + am_gracia - am_pagado),0)
from ca_amortizacion
where am_operacion = @i_operacion
and   am_concepto  = @w_concepto_int
and   am_estado    = (select es_codigo from ca_estado
                      where es_descripcion = 'SUSPENSO')


-- Valor Seguro de Vida
select @w_valor_seguro_vida = isnull(sum(am_cuota + am_gracia - am_pagado),0)
from ca_amortizacion
where am_operacion = @i_operacion
and   am_concepto like 'SVID%'


-- capital vencido

/** CAPITAL VENCIDO **/

select @w_div_vencido = isnull(min(di_dividendo),0)
from ca_amortizacion, ca_rubro_op,ca_dividendo
where am_operacion = @i_operacion
and ro_operacion = @i_operacion
and am_operacion = di_operacion
and am_dividendo = di_dividendo
and am_cuota - am_pagado > 0   ---Que no este pagado
and di_estado    = 2
and ro_tipo_rubro= 'C'
and ro_concepto  = am_concepto


select @w_dias_cap_ven = 0
if @w_div_vencido > 0 begin

   select @w_dias_cap_ven = datediff(dd,di_fecha_ven,@i_fecha)
   from ca_dividendo
   where di_operacion = @i_operacion
   and di_dividendo = @w_div_vencido
   if @w_dias_cap_ven < 0
      select @w_dias_cap_ven = 0


end


-- Cuotas pactadas

   select @w_ncuotas_pac = count(di_dividendo)
    from ca_dividendo
   where di_operacion = @i_operacion

-- Cuotas pagadas

   select @w_ncuotas_pag = count(di_dividendo)
   from ca_dividendo
   where di_operacion = @i_operacion
   and di_estado = @w_est_cancelado


-- Cuotas pagadas

   select @w_ncuotas_ven = count(di_dividendo)
   from ca_dividendo
   where di_operacion = @i_operacion
   and di_estado = @w_est_vencido

-- insert en la tabla

insert ca_tabla_reporte 
values(
@w_tr_numero_obligacion,   @i_fecha,                   @w_tr_tipo_producto,
@w_tr_oficina_obligacion,  @w_tr_oficial,              @w_tr_nombre,
@w_tr_frecuencia_int,      @w_tr_modalidad_int,        @w_tr_frecuencia_cap,
@w_tr_valor_ini_obligacion,@w_tr_fecha_ini_obligacion, @w_tr_calificacion_obligacion,
@w_tr_clase_cartera,       @w_tr_reestructuracion,     @w_tr_estado_obligacion,
@w_tr_numero_comex,        @w_tr_numero_deuda_ext,     @w_tr_fecha_embarque,
@w_tr_fecha_dex,           @w_tr_tipo_tasa,            @w_tr_tasa,
@w_tr_tasa_referencial,    @w_tr_spread,               @w_tr_signo,
@w_tr_tipo_identificacion, @w_tr_identificacion,       @w_tr_saldo_cap,
@w_tr_saldo_int,           @w_tr_saldo_mora,           @w_tr_saldo_otros,
@w_tr_valor_causado,       @w_tr_fecha_ult_pago,       @w_tr_valor_proximo_cuota,
@w_tr_fecha_proximo_venc,  @w_tr_dias_vencimiento,     @w_tr_provision_cap,
@w_tr_provision_int,       @w_tr_provision_cxc,        @w_tr_valor_total_gar,
@w_interes_contingente,    @w_tr_clase_garantia,       @w_valor_seguro_vida,
@w_tr_cuenta_asociada,     @w_tr_numero_migracion,     @w_tr_monto_desembolso,
@w_tr_fecha_fin,	   @w_tr_plazo_total,	       @w_tr_tipo_tabla,
@w_tr_periodo_gracia_cap,  @w_tr_periodo_gracia_int,   @w_dias_cap_ven,
@w_moneda,		   @w_tasa_efa,		       @w_valor_ult_pago,
@w_op_cliente,		   @w_ncuotas_ven,             @w_ncuotas_pag,
@w_ncuotas_pac,            @w_destino
)
           
if @@error <> 0 begin
   select @w_error = 705068
   return @w_error         
end

return 0
go
