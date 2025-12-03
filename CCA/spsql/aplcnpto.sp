/************************************************************************/
/*   NOMBRE LOGICO:      sp_aplicacion_concepto                         */
/*   NOMBRE FISICO:      aplcnpto.sp                                    */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       MPO                                            */
/*   FECHA DE ESCRITURA: 15 de Abril 1997                               */
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
/*                              PROPOSITO                               */
/*      Aplica el abono. Este procedimiento considera la aplicaci¢n por */
/*      concepto.                                                       */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FEB-2003                EPB           Personalizacion BAC       */
/*      AGO-2006                EPB           NR568   BAC               */
/*      SEP 2006                FQ            Optimizacion 152          */
/*      NOV-2006                EPB           DEF. 7433   BAC           */
/*      NOV-22-2006             EPB           DEF. 7485   BAC           */
/*      NOV-24-2006             EPB           DEF. 7597   BAC           */
/*      MAR-16-2007             EPB           NR-537      BAC           */
/*      ABR-03-2007             EPB           Def-8083      BAC         */
/*      JUL-03-2007             EPB           Def-8546      BAC         */
/*      SEP-24-2007             EPB           Def-8686      BAC         */
/*      OCT-31-2007             EPB           Def-8966      BAC         */
/*      JUL-27-2010             EPB           Def-Antes de reestructurar*/
/*      05/12/2016          R. Sánchez            Modif. Apropiación    */
/*      16/08/2019       Luis Ponce           Pagos Grupales Te Creemos */
/*      05/12/2019       Luis Ponce           Cobro Indiv Acumulado,    */
/*                                            Proyectado Grupal         */
/*      31/03/2019       Luis Ponce           CDIG ABONO EXTRAORDINARIO */
/*  DIC/03/2020   Patricio Narvaez  Causacion en moneda nacional        */
/* 14/01/2021         P.Narvaez    Rubros anticipados, CoreBase         */
/* 13/04/2022     Kevin Rodríguez  Abono rubros en pag. extraordinario  */
/* 08/07/2022     K. Rodriguez     Respetar negociación en apl_concep  y*/
/*                                 permitir abono a rubros dif a CAP    */
/* 07/11/2023     K. Rodriguez     Actualiza valor despreciab           */
/* 14/11/2023     K. Rodriguez     R219105 Valid. cancel div por gracia */
/************************************************************************/
 
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aplicacion_concepto')
   drop proc sp_aplicacion_concepto
go

---Inc 26999  partiendo de la ver 11 Jul-28-2011

create proc sp_aplicacion_concepto
@s_sesn                  int        = NULL,
@s_user                  login      = NULL,
@s_term                  varchar(30)= NULL,
@s_date                  datetime   = NULL,
@s_ofi                   smallint   = NULL,
@i_secuencial_ing        int,
@i_secuencial_pag        int,
@i_fecha_proceso         datetime,
@i_operacionca           int,
@i_en_linea              char(1),
@i_tipo_reduccion        char(1),
@i_tipo_cobro            char(1),
@i_tipo_aplicacion       char(1),
@i_monto_pago            money,
@i_cotizacion            money,
@i_tcotizacion           char(1),
@i_num_dec               smallint,
@i_num_dec_n             smallint,
@i_saldo_capital         money      = null,
@i_solo_capital          char(1)    = null,
@i_porcta_dif            float = 0,         --Jeimar 20020313
@i_tipo_tabla            catalogo,
@i_cotizacion_dia_sus    float   = null,
@i_abono_extraordinario  char(1) = 'N',
@i_es_precancelacion     CHAR(1) = NULL, --LPO TEC NUEVA DEFINCION, EN UNA PRECANCELACION PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
@i_abn_rubs_completos    char(1) = 'N',   -- KDR, Para abonar todos los rubros ante un abono extraordinario.
@o_sobrante              money   = null out,
@o_cancelar              char(1) = null out
as
declare
   @w_error                int,
   @w_ap_prioridad         int,
   @w_est_cancelado        tinyint,
   @w_est_novigente        tinyint,
   @w_est_vigente          tinyint,
   @w_est_vencido          tinyint,
   @w_est_dividendo        tinyint,
   @w_max_dividendo        int,
   @w_di_dividendo         int,
   @w_di_fecha_ini         datetime,
   @w_di_fecha_ven         datetime,
   @w_monto_prioridad      money,
   @w_am_concepto          catalogo,
   @w_ro_tipo_rubro        char(1),
   @w_monto_rubro          money,
   @w_sobrante_pago        money,
   @w_sobrante_monto_pri   money,
   @w_salir_prioridad      char(1),
   @w_salir_dividendo      char(1),
   @w_salir_rubro          char(1),
   @w_monto_asoc           money,
   @w_rubro_asoc           catalogo,
   @w_porcentaje           float,
   @w_total_ven            money,
   @w_inicial_prioridad    float,
   @w_inicial_rubro        float,
   @w_inicial_rubro2       float,
   @w_aux                  tinyint,
   @w_div_vigente          smallint,
   @w_tipo                 char(1),
   @w_fpago                char(1),
   @w_banco                cuenta,
   @w_cancelar_div         char(1),
   @w_total_div            money,
   @w_monto_pago           money,
   @w_saldo_oper           money,
   @w_proporcion           float,
   @w_vlr_despreciable     float,
   @w_bandera_be           char(1), --Para enviar  a Garantias
   @w_tramite              int,
   @w_moneda               smallint,
   @w_menor_prioridad      smallint,
   @w_div_vigente_c        smallint,
   @w_est_div_vigente      int,
   @w_concepto_int         catalogo,
   @w_cuota_sec_1          money,
   @w_acum_sec_1           money,
   @w_pagsec_1             money,
   @w_cuota_sec_2          money,
   @w_acum_sec_2           money,
   @w_pagsec_2             money,
   @w_estado_sec2          tinyint,
   @w_max_sec              tinyint,
   @w_di_estado            tinyint,
   @w_ap_concepto          catalogo,
   @w_rowcount_act         int,
   @w_op_estado            tinyint,
   @w_iva_cj               catalogo,
   @w_iva                  float,
   @w_proporcional         char(1),
   @w_monto_analisis       money,
   @w_monto_mipyme         money,
   @w_monto_ivapyme        money,
   @w_ivamipymes           catalogo,
   @w_mipymes              catalogo,
   @w_concepto_CAP         catalogo,
   @w_concepto_MPrioridad  catalogo,
   @w_nro_cuotas_pendientes smallint,
   @w_cuota_cap_disponible  money,
   @w_cuota_INT_acum        money,
   @w_control               smallint,
   @w_div_max	            smallint,
   @w_codvalor              int,
   @w_intereses             money,
   @w_saldo_cap             money,
   @w_di_disa_cuota         smallint,
   @w_est_rubro             tinyint,
   @w_valor_pago            money,
   @w_tasa_int              float,
   @w_fecha_hoy             datetime,
   @w_oficina_op            INT,
   @w_tipo_cobro_op         CHAR(1),      --LPO TEC
   @w_gracia_int            smallint,
   @w_dist_gracia           char(1),
   @w_tipo_cobro_aux        CHAR(1),      --LPO TEC
   @w_toperacion            catalogo,
   @w_tipo_grupal           CHAR(1)       --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
   

select @w_concepto_CAP  =  pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CAP'
if @@rowcount = 0
   return 710256
      
if @i_solo_capital = 'S' or @i_abono_extraordinario = 'S' 
begin
select @w_concepto_MPrioridad =  @w_concepto_CAP
end
else
begin
	select @w_menor_prioridad = min(ap_prioridad)
	from   ca_abono_prioridad
	where  ap_operacion      = @i_operacionca
	and    ap_secuencial_ing = @i_secuencial_ing

	if (select count(1) from ca_abono_prioridad
        where ap_operacion      = @i_operacionca
        and   ap_secuencial_ing = @i_secuencial_ing
        and   ap_prioridad = 0) > 1
    begin
	   set rowcount 1
	   update ca_abono_prioridad with (rowlock)
	   set    ap_prioridad = -1
	   where  ap_operacion = @i_operacionca
	   and    ap_secuencial_ing = @i_secuencial_ing
	   and    ap_concepto <> @w_concepto_CAP
	   and    ap_prioridad = 0
	   set    rowcount 0
    end
	 	
	select @w_concepto_MPrioridad = ap_concepto
	from ca_abono_prioridad
	where ap_operacion = @i_operacionca
	and ap_secuencial_ing = @i_secuencial_ing
	and ap_prioridad = @w_menor_prioridad 
	
end

select @w_iva = pa_float
from  cobis..cl_parametro
where pa_nemonico = 'PIVA'
and pa_producto = 'CTE'
if @@rowcount = 0
   return 710256
     
-- PARAMETROS GENERALES
select @w_ivamipymes  =  pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'IVAMIP'
if @@rowcount = 0
   return 710256
   
select @w_mipymes  =  pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'MIPYME'
if @@rowcount = 0
   return 710256
 
-- INICIALIZACION DE VARIABLES 
select @w_est_cancelado = 3,
       @w_est_novigente        = 0,
       @w_est_vigente          = 1,
       @w_est_vencido          = 2,
       @w_salir_prioridad      = 'N',
       @w_salir_dividendo      = 'N',
       @w_salir_rubro          = 'N',
       @w_proporcion           = 0,
       @w_vlr_despreciable     = 0,
       @w_div_vigente_c        = 0,
       @w_monto_pago           = @i_monto_pago,
       @w_cuota_sec_1          = 0,
       @w_acum_sec_1           = 0,
       @w_pagsec_1             = 0,
       @w_cuota_sec_2          = 0,
       @w_acum_sec_2           = 0,
       @w_pagsec_2             = 0,
       @w_estado_sec2          = 0,
       @w_max_sec              = 1

-- SELECCIONAR EL TIPO DE OPERACION PARA CREDITO ROTATIVO 
select @w_tipo    	     = op_tipo,  
       @w_banco   	     = op_banco,
       @w_tramite 	     = op_tramite,
       @w_moneda  	     = op_moneda,
       @w_op_estado      = op_estado,
       @w_oficina_op     = op_oficina,
       @w_toperacion     = op_toperacion,
       @w_tipo_cobro_op  = op_tipo_cobro,  --LPO TEC
	   @w_gracia_int     = op_gracia_int,
	   @w_dist_gracia    = op_dist_gracia
from   ca_operacion
where  op_operacion  = @i_operacionca

/*
SELECT @w_tipo_cobro_op = dt_tipo_cobro  --LPO TEC Se deja el tipo de cobro desde la Operacion, no desde el Producto
from ca_default_toperacion
WHERE dt_toperacion = @w_toperacion
*/

--LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO:
/*DETERMINA EL TIPO DE OPERACION ((G)rupal, (I)nterciclo, I(N)dividual)*/
EXEC @w_error = sp_tipo_operacion
     @i_banco  = @w_banco,
     @o_tipo   = @w_tipo_grupal out

IF @w_error <> 0
   RETURN @w_error
--LPO TEC FIN NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO

select @w_vlr_despreciable = isnull(1.0 / power(10, (@i_num_dec + 2)),0)

-- SELECCION DEL DIVIDENDO VIGENTE

select @w_div_vigente = isnull(max(di_dividendo),0)
from   ca_dividendo
where  di_operacion   =  @i_operacionca
and    di_estado      = 1

if @w_div_vigente = 0
begin
   select @w_div_vigente = isnull(max(di_dividendo), -1)
   from   ca_dividendo
   where  di_operacion   = @i_operacionca
   and    di_estado      = 2
   
   if @w_div_vigente = -1
      return 708163
   
   --SI LA OPERACION ESTA TODA VENCIDA
   select @w_div_vigente_c = @w_div_vigente + 1
end
ELSE
   select @w_div_vigente_c = @w_div_vigente

---

--EPB:DIV-23-2004 CUANDO EL RUBRO INTERES ESTA EN MAS DE UN SECUENCIAL 
select @w_est_div_vigente = di_estado
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_dividendo = @w_div_vigente

select @w_concepto_int = ro_concepto
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_tipo_rubro = 'I'

if @@rowcount > 0
begin
   if  @w_est_div_vigente = 1
   begin
      --DATOS DE LA TABLA DE AMORTIZACION
      select @w_max_sec = max(am_secuencia)
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_div_vigente
      and    am_concepto = @w_concepto_int
      
      select @w_cuota_sec_1     = am_cuota,
             @w_acum_sec_1      = am_acumulado,
             @w_pagsec_1        = am_pagado
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_div_vigente
      and    am_secuencia = 1
      and    am_concepto = @w_concepto_int
      
      if @w_max_sec > 1
      begin
         select @w_cuota_sec_2 = am_cuota,
                @w_acum_sec_2  = am_acumulado,
                @w_pagsec_2    = am_pagado,
                @w_estado_sec2 = am_estado
         from   ca_amortizacion
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_div_vigente
         and    am_secuencia = 2
         and    am_concepto = @w_concepto_int
         
         if @w_cuota_sec_1 = 0 and @w_cuota_sec_2  > 0
         begin
            --SI SOLO UN SECUENCIAL TIENE VALOR, SE DEJA TODO EN EL 1
            update ca_amortizacion
            set am_cuota     =  @w_acum_sec_2,
                am_acumulado =  @w_acum_sec_2,
                am_pagado    =  @w_pagsec_2,
                am_estado    =  @w_estado_sec2
            where am_operacion = @i_operacionca
            and   am_dividendo = @w_div_vigente
            and   am_secuencia = 1
            and   am_concepto = @w_concepto_int
            
            --SE ELIMINA EL SEC 2
            delete  ca_amortizacion
            where am_operacion = @i_operacionca
            and   am_dividendo = @w_div_vigente
            and   am_secuencia = 2
            and   am_concepto = @w_concepto_int
         end
      end --existe uns secuencia 2
   end
end

---
--CUANDO LA CUOTA INICIAL INICIAL ES LA VIGENTE No.1  y la prioridad es 0 NO ESTABA ENTRANDO AL CURSOR
--POR QUE @w_div_vigente_c = 1
if @w_div_vigente = 1 and @w_menor_prioridad = 0
   select @w_div_vigente_c = @w_div_vigente_c + 1

/*REQ 177 BANCAMIA */
select @w_monto_analisis = 0   
select @w_monto_analisis = isnull(sum(am_cuota + am_gracia - am_pagado), 0)
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_dividendo = @w_di_dividendo
and    am_concepto in (@w_mipymes, @w_ivamipymes)
    
-- CURSOR POR PRIORIDADES DE PAGO 

if @i_solo_capital = 'S' begin
  declare
  prioridades cursor
  for select distinct  ap_prioridad,ap_concepto
      from   ca_abono_prioridad
      where  ap_secuencial_ing = @i_secuencial_ing
      and    ap_operacion      = @i_operacionca
      and    ap_concepto       = @w_concepto_CAP
      order  by ap_prioridad,ap_concepto
  for read only
  open prioridades
end
else begin
  declare
  prioridades cursor
  for select distinct  ap_prioridad,ap_concepto
      from   ca_abono_prioridad
      where  ap_secuencial_ing = @i_secuencial_ing
      and    ap_operacion      = @i_operacionca
      order  by ap_prioridad,ap_concepto
  for read only
  open prioridades
end

fetch prioridades 
into  @w_ap_prioridad,
      @w_ap_concepto

while @@fetch_status = 0 
begin
   if (@@fetch_status = -1) 
       return 708899
   
   --CURSOR POR DIVIDENDOS 
   if @w_menor_prioridad = 1
   begin
      declare
        dividendos cursor
         for select di_dividendo, di_fecha_ven, di_fecha_ini, di_estado
             from   ca_dividendo,
                    ca_amortizacion
             where  di_operacion  = @i_operacionca
             and    am_operacion  = @i_operacionca
             and    di_dividendo <= @w_div_vigente_c
             and    di_estado    <> @w_est_cancelado
             and    am_dividendo  = di_dividendo
             and    am_concepto   = @w_ap_concepto
             order  by di_dividendo
        for read only
      open dividendos
   end
   ELSE
   begin
      declare
         dividendos cursor
         for select di_dividendo, di_fecha_ven, di_fecha_ini, di_estado
             from   ca_dividendo,
                    ca_amortizacion
             where  di_operacion   = @i_operacionca
             and    am_operacion   = @i_operacionca
             and    di_dividendo  <= @w_div_vigente_c
             and    di_estado     <> @w_est_cancelado
             and    am_dividendo   = di_dividendo
             and    am_concepto    = @w_ap_concepto
             order  by di_dividendo
         for read only
      open dividendos
   end
   
   fetch dividendos
   into  @w_di_dividendo, @w_di_fecha_ven, @w_di_fecha_ini, @w_di_estado
   
   while @@fetch_status = 0 
   begin
      if (@@fetch_status = -1) 
         return 708899
            
      if @w_di_dividendo <= @w_div_vigente 
      begin
        select @w_inicial_prioridad = isnull(sum(am_acumulado),0)
         from   ca_amortizacion
         where  am_operacion      = @i_operacionca
         and    am_dividendo      = @w_di_dividendo
         and    am_concepto       = @w_ap_concepto
         and    am_estado        <> @w_est_cancelado
      end
      ELSE
      begin
         select @w_inicial_prioridad = isnull(sum(am_cuota),0)
         from   ca_amortizacion
         where  am_operacion      = @i_operacionca
         and    am_dividendo      = @w_di_dividendo
         and    am_concepto       = @w_ap_concepto
         and    am_estado        <> @w_est_cancelado
      end
      
      if @w_inicial_prioridad is null or  @w_inicial_prioridad = 0
         select @w_inicial_prioridad = 1.00  
      
--      IF @w_di_dividendo = @w_div_vigente  --LPO TEC  --LPO CDIG ABONO_XTRA
--         SELECT @w_tipo_cobro_aux = @w_tipo_cobro_op  --LPO CDIG ABONO_XTRA
--      ELSE                                            --LPO CDIG ABONO_XTRA
         SELECT @w_tipo_cobro_aux = @i_tipo_cobro
      
      --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO:         
      IF @w_di_dividendo = @w_div_vigente AND @w_tipo_grupal = 'G' AND @i_es_precancelacion = 'S'
         SELECT @w_tipo_cobro_aux = 'P' --Proyectado
      
      /* KDR 08/07/2021 No obligar a ser tipo cobro acumulado, se respeta valor actual de eseta variable
      IF @w_di_dividendo = @w_div_vigente AND @w_tipo_grupal IN ('I', 'N') AND @i_es_precancelacion = 'S'
         SELECT @w_tipo_cobro_aux = 'A' --Acumulado
	  */
      --LPO TEC FIN NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
      
      -- MONTO DE TODA LA PRIORIDAD DEL DIVIDENDO 
      exec @w_error = sp_monto_pago
           @i_operacionca    = @i_operacionca,
           @i_dividendo      = @w_di_dividendo,
           @i_dividendo_vig  = @w_div_vigente,
           @i_tipo_cobro     = @w_tipo_cobro_aux, --@i_tipo_cobro, LPO TEC
           @i_fecha_pago     = @i_fecha_proceso,
           @i_prioridad      = @w_ap_prioridad,
           @i_secuencial_ing = @i_secuencial_ing,
           @o_monto          = @w_monto_prioridad out
      
      if @w_error <> 0 
         return @w_error
         
     
      -- SI EL VALOR DE LA PRIORIDAD ES MAYOR AL VALOR DEL PAGO 
      -- ENTONCES EN EL VALOR DE LA PRIORIDAD SE PONE EL VALOR DEL PAGO 
      if @w_monto_prioridad >= @i_monto_pago
         select @w_monto_prioridad = @i_monto_pago
      
      -- SELECCION DE LOS RUBROS POR PRIORIDAD Y DIVIDENDO 
      declare
         rubros cursor
             for select am_concepto, ro_tipo_rubro, ro_fpago, 
                    sum(am_acumulado), sum(am_cuota) 
             from   ca_amortizacion,
                    ca_rubro_op
             where  am_operacion      = @i_operacionca
             and    am_dividendo      = @w_di_dividendo
             and    ro_operacion      = @i_operacionca
             and    am_concepto       = @w_ap_concepto
             and    ro_concepto       = @w_ap_concepto
             group  by am_concepto,ro_tipo_rubro,  ro_fpago
             order  by am_concepto,ro_tipo_rubro,  ro_fpago
         for read only 
      open rubros
     
      fetch rubros
      into  @w_am_concepto, @w_ro_tipo_rubro, @w_fpago, @w_inicial_rubro,
            @w_inicial_rubro2
      
      while @@fetch_status = 0
      begin
         if (@@fetch_status = -1) 
            return 789900

            /* KDR 08/07/2021 Se coemta para No limitar a abonar solo CAP cuando se cumplen estas condiciones
            if ( ltrim(rtrim(@w_am_concepto)) <> ltrim(rtrim(@w_concepto_MPrioridad))) and (ltrim(rtrim(@w_concepto_MPrioridad))  = @w_concepto_CAP ) and @i_abono_extraordinario = 'N'
            begin
               select  @i_tipo_aplicacion = 'P'
               close rubros
               deallocate rubros
               goto PROXIMO                               
            end
			*/

                        
         
         if @w_di_dividendo > @w_div_vigente 
            select @w_inicial_rubro = @w_inicial_rubro2

         /* En el calculo del Iva (Robro Anterior) no es posible realizar proporcionalidad por el valor sobrante */
         if @w_proporcional = '0' and @w_am_concepto = @w_mipymes begin
               close rubros
               deallocate rubros
               goto PROXIMO
         end            
                     
         select @w_proporcional = 'N'

         if @w_am_concepto = @w_ivamipymes and @i_monto_pago < @w_monto_analisis    --SE APLICA PROPORCIONALIDAD
            select @w_proporcional = 'S'            
         else begin            
            -- MONTO DEL RUBRO SELECCIONADO 
            exec @w_error = sp_monto_pago_rubro
                 @i_operacionca    = @i_operacionca,
                 @i_dividendo      = @w_di_dividendo,
                 @i_dividendo_vig  = @w_div_vigente,
                 @i_tipo_cobro     = @w_tipo_cobro_aux, --@i_tipo_cobro, LPO TEC
                 @i_fecha_pago     = @i_fecha_proceso,
                 @i_concepto       = @w_am_concepto,
                 @o_monto          = @w_monto_rubro out
            
            if @w_error <> 0 
               return @w_error
         end
         
         if (@w_monto_rubro <> 0 and @i_abono_extraordinario = 'N') or
            (@w_monto_rubro <> 0 and @i_abono_extraordinario = 'S' and (@w_di_dividendo <> @w_div_vigente or @i_abn_rubs_completos = 'S')) or
            (@w_monto_rubro <> 0 and @i_abono_extraordinario = 'S' and @w_di_dividendo = @w_div_vigente and
             @w_am_concepto = 'INT')
         begin
            --PARA PAGOS CON RUBRO PROPORCIONAL 

            if @w_am_concepto = @w_ivamipymes and @i_monto_pago < @w_monto_analisis    --SE APLICA PROPORCIONALIDAD
            begin
               select @w_monto_mipyme  = @i_monto_pago /(1+ @w_iva /100)
               select @w_monto_ivapyme = @w_monto_mipyme * @w_iva /100
               
               select @w_monto_rubro       = isnull(@w_monto_ivapyme,0),
                      @w_monto_prioridad   = isnull(@w_monto_ivapyme,0),
  	                  @w_inicial_prioridad = isnull(@w_monto_ivapyme,0)

  	           if @w_monto_mipyme > 1 and   @w_monto_ivapyme > 1      
                  select @w_proporcional = 'S'
               else begin
                  close rubros
                  deallocate rubros
                  select @w_proporcional = '0'
                  goto PROXIMO
               end
            
            end            
            else
            if @i_tipo_aplicacion = 'P' and @w_di_estado <> 2
            begin
               select @w_proporcion      = convert(float,@w_monto_rubro) / convert(float,@i_saldo_capital)
               select @w_monto_rubro     = round(@w_monto_pago * @w_proporcion, @i_num_dec)
               select @w_monto_prioridad = round(@w_monto_pago * @w_proporcion, @i_num_dec)
               
               if @w_monto_rubro > @i_monto_pago 
               begin
                  select @w_monto_rubro     = @i_monto_pago,
                         @w_monto_prioridad = @i_monto_pago
               end
            end
            
            ---PRINT 'aplcnpto Antesd de sp_abona_rubro @w_am_concepto  ' + CAST (@w_am_concepto as varchar)+'  @w_concepto_MPrioridad : '  + CAST (@w_concepto_MPrioridad as varchar)
            
            -- APLICACION DEL PAGO PARA EL RUBRO 
            exec @w_error = sp_abona_rubro
                 @s_ofi                = @s_ofi,
                 @s_sesn               = @s_sesn,
                 @s_user               = @s_user,
                 @s_term               = @s_term,
                 @s_date               = @s_date,
                 @i_secuencial_pag     = @i_secuencial_pag,
                 @i_operacionca        = @i_operacionca,
                 @i_dividendo          = @w_di_dividendo,
                 @i_concepto           = @w_am_concepto,
                 @i_monto_pago         = @i_monto_pago,
                 @i_monto_prioridad    = @w_monto_prioridad,
                 @i_monto_rubro        = @w_monto_rubro,
                 @i_tipo_cobro         = @w_tipo_cobro_aux, --@i_tipo_cobro, LPO TEC
                 @i_en_linea           = @i_en_linea,
                 @i_tipo_rubro         = @w_ro_tipo_rubro,
                 @i_fecha_pago         = @i_fecha_proceso,
                 @i_condonacion        = 'N',
                 @i_cotizacion         = @i_cotizacion,
                 @i_tcotizacion        = @i_tcotizacion,
                 @i_inicial_prioridad  = @w_inicial_prioridad,
                 @i_inicial_rubro      = @w_inicial_rubro,
                 @i_fpago              = @w_fpago, --'P'
                 @i_cotizacion_dia_sus = @i_cotizacion_dia_sus,
                 @i_aplicacion_concepto = 'S',
                 @o_sobrante_pago      = @i_monto_pago out
            
            if @w_error <> 0 
               return @w_error
            
            if @w_monto_prioridad <= 0
               select @w_salir_rubro = 'S'
            
            if @i_monto_pago <= 0
            begin
               select @w_salir_rubro     = 'S',
                      @w_salir_dividendo = 'S',
                      @w_salir_prioridad = 'S'
            end
         end -- Monto del Rubro 
         
         if @w_salir_rubro <> 'N'
         begin
            select @w_salir_rubro = 'N'
            break
         end
         
         fetch rubros
         into  @w_am_concepto,    @w_ro_tipo_rubro, @w_fpago, @w_inicial_rubro,
               @w_inicial_rubro2
      end -- CURSOR RUBROS 
      
      close rubros
      deallocate rubros
      
      -- VERIFICAR CANCELACION DEL DIVIDENDO 
      
      select @w_cancelar_div = 'N'
      
      --EPB
      if @i_tipo_cobro in ('A', 'E')
      begin
         select @w_total_div = isnull(sum(am_cuota+am_gracia-am_pagado),0)
         from   ca_amortizacion, ca_rubro_op,ca_concepto
         where  am_operacion = @i_operacionca
         and    ro_operacion = am_operacion
         and    ro_concepto  = am_concepto
         and    ro_concepto  = co_concepto
         and    am_estado   <> @w_est_cancelado
         and    (--between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir
                (    am_dividendo between @w_di_dividendo and @w_di_dividendo + charindex (ro_fpago, 'A')
                  and not(co_categoria in ('S','A') and am_secuencia > 1)
                 )
                 or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @w_di_dividendo)
                )
         
         if round(@w_total_div, @i_num_dec) <= @w_vlr_despreciable
            select @w_cancelar_div = 'S'
      end
      ELSE
      begin
         select @w_total_div=isnull(sum(am_cuota+am_gracia-am_pagado),0)
         from   ca_amortizacion, ca_rubro_op,ca_concepto
         where  am_operacion = @i_operacionca
         and    ro_operacion = am_operacion
         and    ro_concepto  = am_concepto
         and    ro_concepto  = co_concepto
         and    am_estado   <> @w_est_cancelado
         and   (--between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir
                (     am_dividendo between @w_di_dividendo and @w_di_dividendo + charindex (ro_fpago, 'A')
                 and not(co_categoria in ('S','A') and am_secuencia > 1)
                )
                or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @w_di_dividendo)
               )
         
         if round(@w_total_div, @i_num_dec) < @w_vlr_despreciable
            select @w_cancelar_div = 'S'
      end
      
      if @w_cancelar_div = 'S'  begin
	  
	      -- KDR Ini Validación temporal para no permitir pagos con tipo de aplicación por concepto cuando cancelan el dividendo, 
		  -- analizar y si es necesario replicar el manejo de gracia que realiza el sp_aplicacion_cuota, el cual realiza el  
		  -- devengamiento del valor de la gracia y acumula el valor de am_acumulado
          if @w_gracia_int > 0 and @w_dist_gracia <> 'C'
          begin  
		     
			  if exists(select 1
                        from ca_amortizacion, ca_rubro_op
                        where am_operacion  = @i_operacionca
                        and   am_dividendo  = @w_di_dividendo
                        and   am_gracia     < 0
                        and   am_cuota      > am_acumulado
                        and   ro_operacion  = am_operacion
                        and   ro_concepto   = am_concepto
                        and   ro_tipo_rubro = 'I')
              begin
			     select @w_error = 725308 -- NO SE PERMITE APLICACION POR CONCEPTO EN DIVIDENDOS CON GRACIA DE CAPITAL O INTERES.
                 return @w_error	
			  end
			 
          end	 
	      -- KDR Fin Validación temporal
      
         update ca_dividendo   set    
         di_estado = @w_est_cancelado,
         di_fecha_can = @i_fecha_proceso
         where  di_operacion = @i_operacionca
         and    di_dividendo = @w_di_dividendo

         if @@error <> 0 
         begin
            --PRINT 'aplcnpto.sp error actaulizando estado cuota ca_dividendo'
            return 710002         
         end
         
         update ca_amortizacion   set    
         am_estado = @w_est_cancelado
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_di_dividendo
        
         if @@error <> 0 
         begin
            --PRINT 'aplcnpto.sp error actaulizando estado cuota ca_amortizacion'
            return 710002         
         end

         
         update ca_dividendo
         set    di_estado = @w_est_vigente
         where  di_operacion = @i_operacionca
         and    di_dividendo = @w_di_dividendo + 1
         and    di_estado    = @w_est_novigente
         
         if @@error <> 0 
         begin
            --PRINT 'aplcnpto.sp error actualizando estado cuota siguiente  ca_dividendo'
            return 710002         
         end
         
         update ca_amortizacion
         set    am_estado = @w_est_vigente
         from   ca_amortizacion 
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_di_dividendo + 1
         and    am_estado    = @w_est_novigente
         
         if @@error <> 0 
         begin
            --PRINT 'aplcnpto.sp error actualizando estado cuota siguiente ca_amortizacion'
            return 710002         
         end
         
         update ca_amortizacion with (rowlock) set   
         am_acumulado = am_cuota,
         am_estado    = @w_op_estado
         from ca_rubro_op
         where am_operacion = ro_operacion
         and   am_concepto  = ro_concepto
         and   ro_provisiona = 'N'
         and   ro_tipo_rubro <> 'C'
         and   ro_operacion  = @i_operacionca
         and   am_dividendo  = @w_di_dividendo + 1
         and   am_estado     <> @w_est_cancelado
         
         if @@error <> 0 
         begin
            --PRINT 'aplcnpto.sp error actualizando acumulado cuota siguiente ca_amortizacion'
            return 710002         
         end
      end
      
      if @w_salir_dividendo <> 'N' 
      begin
         select @w_salir_dividendo = 'N'
         break
      end
      
      -- SI EL MONTO A PAGAR ES CERO, SALIR 
      if @i_monto_pago = 0.00 break
      
      fetch dividendos
      into  @w_di_dividendo, @w_di_fecha_ven, @w_di_fecha_ini, @w_di_estado
   end -- CURSOR DIVIDENDOS
   
   close dividendos
   deallocate dividendos

   if @w_salir_prioridad <> 'N'
   begin
      select @w_salir_prioridad = 'N'
      break
   end
   
   PROXIMO:
   
   if @i_tipo_aplicacion = 'P' break
      
   
   fetch prioridades 
   into @w_ap_prioridad,
        @w_ap_concepto
end -- CURSOR PRIORIDADES 

close prioridades
deallocate prioridades


-- CONTROL DE CANCELAMIENTO DE LA OPERACION 
select @w_max_dividendo = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @i_operacionca

if @w_tipo = 'D' --  FACTORING
begin
   select @w_total_ven = isnull(sum(am_cuota+am_gracia-am_pagado),0)
   from   ca_amortizacion, ca_rubro_op
   where  am_operacion = @i_operacionca
   and    am_operacion = ro_operacion
   and    am_concepto  = ro_concepto
   and    am_estado   <> @w_est_cancelado
end 
ELSE
begin
   if @i_tipo_cobro = 'P' -- PROYECTADO
      select @w_total_ven = isnull(sum(am_cuota+am_gracia-am_pagado),0)
      from   ca_amortizacion, ca_rubro_op, ca_concepto
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_max_dividendo
      and    am_operacion = ro_operacion
      and    am_concepto  = ro_concepto
      and    ro_concepto  = co_concepto
      and    am_estado   <> @w_est_cancelado
      and   (
             (     am_dividendo = @w_max_dividendo + charindex (ro_fpago, 'A')
              and not(co_categoria in ('S','A') and am_secuencia > 1)
             )
             or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @w_max_dividendo)
            )
   ELSE
      select @w_total_ven = isnull(sum(am_acumulado+am_gracia-am_pagado),0)
      from   ca_amortizacion, ca_rubro_op, ca_concepto
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_max_dividendo
      and    am_operacion = ro_operacion
      and    am_concepto  = ro_concepto
      and    ro_concepto  = co_concepto
      and    am_estado   <> @w_est_cancelado
      and   (
             (am_dividendo = @w_max_dividendo + charindex (ro_fpago, 'A')
              and not(co_categoria in ('S','A') and am_secuencia > 1)
             )
             or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @w_max_dividendo)
            )
end

select @w_total_ven = isnull(@w_total_ven,0)

if @w_total_ven <= @w_vlr_despreciable 
begin

   --GENERACION DE LA COMISION DIFERIDA
   exec @w_error     = sp_comision_diferida
   @s_date           = @s_date,
   @i_operacion      = 'A',
   @i_operacionca    = @i_operacionca,
   @i_secuencial_ref = @i_secuencial_pag,
   @i_num_dec        = @i_num_dec,
   @i_num_dec_n      = @i_num_dec_n,
   @i_cotizacion     = @i_cotizacion,
   @i_tcotizacion    = @i_tcotizacion 
   
   if @w_error <> 0  return 724589 
   
   update ca_operacion
   set    op_estado = @w_est_cancelado
   where  op_operacion = @i_operacionca
   
   update ca_dividendo
   set    di_estado    = @w_est_cancelado,
          di_fecha_can = @i_fecha_proceso
   where  di_operacion = @i_operacionca
   and    di_estado    <> @w_est_cancelado
   
   update ca_amortizacion
   set    am_estado = @w_est_cancelado
   from   ca_amortizacion
   where  am_operacion = @i_operacionca
   and    am_estado    <> @w_est_cancelado
   
   if @@error <> 0
   begin
      return 710002
   end
   
   select @o_sobrante = isnull(@i_monto_pago,0)
   
   if @i_en_linea = 'N'
      select @w_bandera_be = 'S'
   else
      select @w_bandera_be = 'N'
   
   exec @w_error = cob_custodia..sp_activar_garantia
        @i_opcion         = 'C',
        @i_tramite        = @w_tramite,
        @i_modo           = 2,
        @i_operacion      = 'I',
        @s_date           = @s_date,
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_ofi            = @s_ofi,
        @i_bandera_be     = @w_bandera_be
   
   if @w_error <> 0
   begin
      --PRINT 'aplncto.sp  salio por error de cob_custodia..sp_activar_garantia ' + CAST(@w_error AS VARCHAR)
      while @@trancount > 1
            rollback
      return @w_error
   end 
   
   --ACTUALIZA EL ESTADO DEL PRODUCTO EN CLIENTES
   update cobis..cl_det_producto 
   set    dp_estado_ser = 'C'
   where  dp_producto = 7 
   and    dp_cuenta = @w_banco 
end  -- FIN DE ELIMINAR TOTALMENTE LA OPERACION

-- KDR 08/07/2021 Retorna monto sobrante
select @o_sobrante = isnull(@i_monto_pago,0)


/* KDR 08/07/2021 Se comenta para No limitar a abonar solo CAP cuando se cumplen estas condiciones
ELSE
begin
   --  RETORNO DE VARIABLES
   select @o_sobrante = isnull(@i_monto_pago,0)
   ---SI EL SOBRANTE ES > 0 EL RECALCULO SE HACE EN abnextra.sp CON LA REGENERACION DE LA TABLA
   ---SEGUN SEA EL CASO
   
   if @o_sobrante > 0 and (ltrim(rtrim(@w_concepto_MPrioridad))  <> ltrim(rtrim(@w_concepto_CAP)) ) and @i_abono_extraordinario = 'N'
   begin
      --print 'aplcnpto.ps @w_concepto_MPrioridad ' + CAST (@w_concepto_MPrioridad as varchar)
      return  710462
   end
   
   else
   begin
      if @o_sobrante =  0 and (ltrim(rtrim(@w_concepto_MPrioridad)) =  ltrim(rtrim(@w_concepto_CAP)) )
      begin
         if not exists (select 1 from ca_dividendo where di_operacion = @i_operacionca and di_estado = @w_est_vencido) begin
            ---SOLO SI ES ABONO A CAPITAL RECALCULE CASO CONTRARIO PARA QUE
		    exec @w_error = sp_reajuste_interes
		         @s_user           = @s_user,
		         @s_term           = @s_term,
		         @s_date           = @s_date,
		         @s_ofi            = @s_ofi,
		         @i_operacionca    = @i_operacionca,
		         @i_fecha_proceso  = @i_fecha_proceso,
		         @i_banco          = @w_banco,
		         @i_en_linea       = @i_en_linea
		    
		    if @w_error <> 0 
		       return @w_error   
	     end
      end
   end 

   select @w_nro_cuotas_pendientes = count(1)
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_estado   in (1,0)

   if @w_nro_cuotas_pendientes <= 2
   begin
       ---HAY QUE  HACER UNPROCESO ESPECIAL POR QUE EL abnextra no se ejecuta para reduccion de 
       ---cuota o Tiempo si no hay mas de 2 cuotas para regenerar la tabla
       
       select @w_div_vigente = di_dividendo
       from ca_dividendo
       where di_operacion = @i_operacionca
       and di_estado = @w_est_vigente
       
       select @w_div_max = max(di_dividendo)
       from ca_dividendo
       where di_operacion = @i_operacionca
       
       select @w_control = @w_div_vigente
       
       while  (@w_control <= @w_div_max ) and (@o_sobrante >  0)
       begin

           select @w_cuota_cap_disponible = 0,
	              @w_cuota_INT_acum  = 0,
		          @w_intereses = 0,
		          @w_saldo_cap  = 0,
		          @w_valor_pago = 0       
          
           select @w_cuota_cap_disponible = isnull(sum(am_cuota - am_pagado),0)
	       from ca_amortizacion
	       where am_operacion = @i_operacionca	
	       and am_concepto = @w_concepto_CAP
	       and am_dividendo = @w_control

	       select @w_cuota_INT_acum = isnull(sum(am_acumulado),0)
	       from ca_amortizacion
	       where am_operacion = @i_operacionca	
	       and am_concepto = @w_concepto_int
	       and am_dividendo = @w_control	       
	       
	       if @o_sobrante <= @w_cuota_cap_disponible
	       begin
	          select @w_valor_pago = @o_sobrante
	          select @o_sobrante = 0
	          select @w_est_rubro = 3
	       end
	       ELSE
	       begin
	          if @w_control = @w_div_vigente
	             select @w_est_rubro = 1
	          else
	             select @w_est_rubro = 0
	          
	          
	          select @w_valor_pago = @w_cuota_cap_disponible
	          select @o_sobrante = @o_sobrante -  @w_cuota_cap_disponible
	       end
	       
	       ---PRINT 'aplcnpto.sp _cuota_cap_disponible ' + CAST (@w_cuota_cap_disponible  as varchar) + 'Div: ' + CAST (@w_control as varchar) + ' cuota_INT_acum: ' + CAST (@w_cuota_INT_acum as varchar)

	         select @w_codvalor = co_codigo * 1000 + 1 * 10 + 0
		     from   ca_concepto
		     where  co_concepto    = @w_concepto_CAP

             insert into ca_det_trn
                     (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                      dtr_concepto,       dtr_estado,     dtr_periodo,
                      dtr_codvalor,       dtr_monto,      dtr_monto_mn,
                      dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                      dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                      dtr_monto_cont)
               values(@i_secuencial_pag,  @i_operacionca, @w_control,
                      @w_concepto_CAP,             1,               0,
                      @w_codvalor,       @w_valor_pago,  
                       round(@w_valor_pago/@i_cotizacion, @i_num_dec_n),
                      @w_moneda,         @i_cotizacion,  @i_tcotizacion,
                      'C',             '00000',        'CARTERA',
                      0.00)
               
               if (@@error <> 0) 
               begin
                  --PRINT 'aplcnpto.sp Error insertando detalle de pago CAP'
                  return 708166
               end
               
               update ca_amortizacion
               set am_pagado = am_pagado + @w_valor_pago
               where am_operacion = @i_operacionca
               and am_dividendo = @w_control
               and am_concepto = @w_concepto_CAP

               if (@@error <> 0) 
               begin
                  --PRINT 'aplcnpto.sp Error actualizando  CAP en pago'
                  return 705050
               end

               if @w_cuota_INT_acum = 0
               begin
                   select @w_tasa_int = ro_porcentaje
                   from ca_rubro_op
                   where ro_operacion = @i_operacionca
                   and ro_concepto = @w_concepto_int

         		   select @w_saldo_cap = sum(am_cuota + am_gracia - am_pagado)
                   from   ca_dividendo, ca_amortizacion
                   where  di_operacion  = @i_operacionca
                   and    di_dividendo >= @w_control -- MEJOR
                   and    am_operacion  = @i_operacionca
                   and    am_dividendo  = di_dividendo
                   and    am_concepto   = @w_concepto_CAP
                   
                   select @w_di_disa_cuota = di_dias_cuota
                   from ca_dividendo
                   where di_operacion = @i_operacionca
                   and di_dividendo =  @w_control

                   select @w_intereses = (@w_tasa_int * @w_saldo_cap) / (100 * 360) * @w_di_disa_cuota 
                   select @w_intereses = round(@w_intereses,@i_num_dec) 

                   update ca_amortizacion
	               set am_cuota = @w_intereses
	               where am_operacion = @i_operacionca
	               and am_dividendo = @w_control
	               and am_concepto = @w_concepto_int
	
	               if (@@error <> 0) 
	               begin
	                  --PRINT 'aplcnpto.sp Error actualizando  ca_amortizacion INT en pago'
	                  return 705050
	               end
	             end

	       select @w_control = @w_control  + 1
       end
       
   end
 
end -- FIN KDR 08/07/2021 */


return 0

go

