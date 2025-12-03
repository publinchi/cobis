/************************************************************************/
/*   NOMBRE LOGICO:      abonoru.sp                                     */
/*   NOMBRE FISICO:      sp_abona_rubro                                 */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       MPO                                            */
/*   FECHA DE ESCRITURA: Diciembre/1997                                 */
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
/*   Procedimiento que realiza el abono de los rubros de Cartera.       */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/*  OCT-2010         Elcira Pelaez    Transaccion RES y Diferidos NR059 */
/*  NOV-2014         Luis C. Moreno   CCA 436: Normalizacion de Cartera */
/*  05/12/2016        R. Sánchez            Modif. Apropiación          */
/*  27/03/2020       Luis Ponce       CDIG Ajustes migracion a Java     */
/*  25/06/2020       Luis Ponce       CDIG Multimoneda                  */
/*  DIC/02/2020   Patricio Narvaez  Causacion en moneda nacional        */
/* 13/01/2021         P.Narvaez    Rubros anticipados, CoreBase         */
/* 01/06/2022        K. Rodriguez  Ajustes condonaciones                */
/* 26/06/2021     Kevin Rodríguez  Actualización cabecera               */
/* 29/06/2021     Kevin Rodríguez  Genera detalle trn según estado rubro*/
/* 14/07/2022     Kevin Rodríguez  Excluir rubro cobranza de cancelación*/
/* 17/04/2023   Guisela Fernandez  S807925 Ingreso de campo             */
/*                                 reestructuracion                     */
/* 06/06/2023	 M. Cordova		  	Cambio variable @w_calificacion   	*/
/*									de char(1) a catalogo				*/
/* 07/11/2023   Kevin Rodriguez    Actualiza valor despreciab           */
/* 06/03/2025   Kevin Rodriguez    R256950(235424) Optimizac. bucle pago*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abona_rubro')
   drop proc sp_abona_rubro
go

create proc sp_abona_rubro
@s_ofi                  smallint,
@s_sesn                 int,
@s_user                 login,
@s_term                 varchar (30)    = NULL,
@s_date                 datetime        = NULL,
@i_secuencial_pag       int,            -- Secuencial del pago (PAG)
@i_operacionca          int,            -- Operacion a la que pertenece el rubro
@i_dividendo            smallint,       -- Dividendo al cual pertenece el rubro
@i_concepto             catalogo,       -- Rubro a abonar
@i_rubro_asoc           catalogo        = NULL,
@i_porcentaje           float           = NULL,
@i_monto_pago           money,          -- Monto Total del abono
@i_monto_prioridad      money,          -- Monto Total de la prioridad
@i_monto_rubro          money,          -- Monto del Rubro a Aplicar
@i_tipo_cobro           char(1),        -- Tipo de Cobro A, P, E
@i_en_linea             char(1)         = NULL,
@i_tipo_rubro           char(1)         = NULL,   
@i_fecha_pago           datetime        = NULL,
@i_condonacion          char(1)         = 'N',
@i_colchon              char(1)         = 'N',
@i_cotizacion           money           = NULL,
@i_tcotizacion          char(1)         = NULL,
@i_inicial_prioridad    float           = NULL,
@i_inicial_rubro        float           = NULL,
@i_extraordinario       tinyint         = 0,
@i_fpago                char(1),
@i_secuencial_ing       int             = NULL,
@i_di_estado            smallint        = NULL,
@i_dias_pagados         int             = NULL,
@i_tasa_pago            float           = NULL,
@i_cotizacion_dia_sus   float           = null, -- CUANDO LA OBLIGACION ESTA EN SUSPENSO Y ES DE MONEDA UVR
                                                -- SE USAN PARA SEPARAR EL VALOR DE CAUSACION SUSPENDIDA
                                                -- DE MORA E INTERES DE CUENTAS DE BALANCE
@i_en_gracia_int        char(1)         = 'N',
@i_aplicacion_concepto  char(1)         = 'N',
@o_sobrante_pago        money           = NULL   out,
@o_valor_aplicado       money           = NULL  out

as
declare 
   @w_error                int,
   @w_pago                 money,
   @w_pago_rubro           money,
   @w_pago_rubro_mn        money,
   @w_monto_rubro          money,
   @w_codvalor             int,
   @w_codvalor_con1        int,
   @w_codvalor1            int,
   @w_am_pagado            money,
   @w_am_acumulado         float,
   @w_am_estado            tinyint,
   @w_am_periodo           tinyint,
   @w_am_secuencia         tinyint,
   @w_am_gracia            money,
   @w_am_cuota             money,
   @w_est_condonado        tinyint,
   @w_est_vigente          tinyint,
   @w_est_vencido          tinyint,
   @w_est_novigente        tinyint,
   @w_est_cancelado        tinyint,
   @w_op_moneda            smallint,
   @w_moneda_n             smallint,
   @w_toperacion           catalogo,
   @w_afectacion           char(1),
   @w_banco                cuenta,
   @w_oficina_op           smallint,
   @w_dividendo            int,
   @w_dividendo_aux        int,
   @w_num_dec              tinyint,
   @w_di_fecha_ini         datetime,
   @w_di_dias_cuota        int,
   @w_pago_control         money,
   @w_am_acumulado1        money,
   @w_am_pagado1           money,
   @w_num_dec_n            smallint,
   @w_gerente              smallint,
   @w_prepago_int          money,
   @w_secuencial_prepago   int,
   @w_prepago_int_mn       money,
   @w_gar_admisible        char(1),
   @w_reestructuracion     char(1),
   @w_calificacion         catalogo, -- MCO 05/06/2023 Se cambio el tipo de dato de char(1) a catalogo
   @w_parametro_int        catalogo,
   @w_moneda_uvr           tinyint,
   @w_estado_op            tinyint,
   @w_est_suspenso         tinyint,
   @w_am_estado_ar         tinyint,
   @w_concepto_ar          catalogo,
   @w_afectacion_ar        char(1),
   @w_tipo_rubro           char(1),
   @w_codvalor4            int,
   @w_am_correccion_sus_mn money,
   @w_am_correc_pag_sus_mn money,
   @w_factor_vig           float,
   @w_valor_vig_mn         money,
   @w_correc_pag_sus       money,
   @w_codvalor_sus1        int,
   @w_parametro_mora       catalogo,
   @w_parametro_cap        catalogo,
   @w_vlr_despreciable     float,
   @w_tipo_cobro_org       char(1),
   @w_dividendo_max        smallint,
   @w_pago_todo            char(1),
   @w_sum                  money,
   @w_dif_am_acumulado     float,      -- FCP 10/OCT/2005 - REQ 389
   @w_fecha_ult_proceso    datetime,
   @w_rowcount_act         int,
   @w_op_naturaleza        char(1),
   @w_int_proyectado       money,
   @w_fecha_ult_causacion  datetime,
   @w_int_dias             money,
   @w_fecha_ven            datetime,
   @w_val_dia              float,
   @w_dias_prepago         int,
   @w_rowcount             int,
   @w_gracia_div           money,            -- REQ 175: PEQUEÑA EMPRESA
   @w_pend_causacion       money,            -- REQ 175: PEQUEÑA EMPRESA
   @w_causar_en_gr         money,            -- REQ 175: PEQUEÑA EMPRESA
   @w_xcausar_div          money,            -- REQ 175: PEQUEÑA EMPRESA
   @w_xcausar_div_mn       money,            -- REQ 175: PEQUEÑA EMPRESA
   @w_div_gr_acum          smallint,         -- REQ 175: PEQUEÑA EMPRESA
   @w_gracia_acum          money,            -- REQ 175: PEQUEÑA EMPRESA
   @w_causado_gr           money,             -- REQ 175: PEQUEÑA EMPRESA
   @w_est_castigado        tinyint,
   @w_es_pag_norm          smallint,         ---CCA 436
   @ctx_es_norm            int,              ---CCA 436
   @w_cont_sec_rub         int,
   @w_cont                 int


select @w_valor_vig_mn = 0,
       @w_sum          = 0,
       @ctx_es_norm    = 0


if @i_cotizacion <> 0
   select @w_factor_vig = isnull(@i_cotizacion_dia_sus,0) / @i_cotizacion --LPO CDIG Ajustes migracion a Java
else
   select @w_factor_vig = 1

-- PARAMETROS GENERAL
select @w_moneda_n = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount 
set transaction isolation level read uncommitted

if @w_rowcount = 0
   print 'abonoru.sp No existe parametro MLO'

-- MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'

--- ESTADOS DE CARTERA
exec  sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_novigente  = @w_est_novigente out ,
@o_est_condonado  = @w_est_condonado out

select @w_parametro_mora = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'IMO' ---Concepto MORA
and    pa_producto = 'CCA'

select @w_parametro_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 
   return 701059

--436 OBTIENE LA MARCA QUE INDICA QUE ES UN PAGO POR NORMALIZACION
select @w_es_pag_norm = tr_dias_calc
from ca_transaccion
where tr_operacion  = @i_operacionca
and   tr_secuencial = @i_secuencial_pag

-- ESTE VALOR SE COLOCA EN LOS PROGRAMAS DE NORMALIZACION
-- Y SE UTILIZA EN EL ABONORU.SP
if @w_es_pag_norm = -982
   select @ctx_es_norm = 1
else
   select @ctx_es_norm = 0

select @w_dividendo_max = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @i_operacionca

if @w_dividendo_max > @i_dividendo and @i_fpago = 'A'
   select @w_dividendo_aux = @i_dividendo + 1
else 
   select @w_dividendo_aux = @i_dividendo

-- INFORMACION DE OPERACION
select @w_op_moneda        = op_moneda,
       @w_toperacion       = op_toperacion,
       @w_banco            = op_banco,
       @w_oficina_op       = op_oficina,
       @w_gerente          = op_oficial,
       @w_gar_admisible    = op_gar_admisible,
       @w_reestructuracion = op_reestructuracion,
       @w_calificacion     = op_calificacion,
       @w_estado_op        = op_estado,
       @w_fecha_ult_proceso = op_fecha_ult_proceso,
       @w_op_naturaleza     = op_naturaleza,
       @w_fecha_ult_causacion = op_fecha_ult_causacion
from ca_operacion
where op_operacion  = @i_operacionca

if @@rowcount = 0 
   return 702535

-- LECTURA DE DECIMALES
exec @w_error = sp_decimales
     @i_moneda       = @w_op_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_n out

if @w_error <> 0 
   return @w_error

select @w_num_dec  = isnull(@w_num_dec,0)

if @w_op_moneda = 2
   select @w_num_dec_n = 2
 
--SELECT @w_num_dec = 2 --LPO QUITAR
 
select @w_vlr_despreciable = 1.0 / power(10, (@w_num_dec+2))
-- AFECTACION DE CUENTA PARA CADA CONCEPTO CANCELADO DEBE SER C
-- POR QUE LA AFECTACION DE LA FORMA DE PAGO ES D
select @w_afectacion = 'C' 

select @w_tipo_rubro = ro_tipo_rubro
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_concepto  = @i_concepto

if @w_tipo_rubro = 'C'
or exists(select c.codigo
          from   cobis..cl_tabla t, cobis..cl_catalogo c
          where  t.tabla = 'ca_rubros_no_diferidos'
          and    c.tabla = t.codigo
          and    c.estado = 'V'
          and    c.codigo = @i_concepto)
   select @ctx_es_norm = 0


-- SELECCION DE CODIGO VALOR PARA EL RUBRO
select @w_codvalor = co_codigo
from   ca_concepto
where  co_concepto = @i_concepto

if @@rowcount = 0 
   return 701151

-- PARAMETRO GENERAL DE INTERESES
select @w_parametro_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 
    return  701059

select @w_parametro_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'

if abs(@i_monto_pago - @i_monto_rubro) < @w_vlr_despreciable
   select @i_monto_pago = @i_monto_rubro

if @i_aplicacion_concepto = 'S'
begin
   select @w_pago = @i_monto_pago
   if @w_pago > @i_monto_rubro 
      select @w_pago = @i_monto_rubro
            
end
ELSE
begin
   if @i_condonacion = 'N' 
   begin
      -- MONTO DE PAGO POR PRIORIDAD
      
      select @w_pago = round(@i_monto_prioridad * (@i_inicial_rubro / @i_inicial_prioridad),@w_num_dec)
      
      if @w_pago > @i_monto_rubro 
         select @w_pago = @i_monto_rubro
   end 
   ELSE
   begin
      select @w_pago = @i_monto_pago
      if @w_pago > @i_monto_rubro 
         select @w_pago = @i_monto_rubro
      
   end
end


-- RETORNO DE VALORES
if @i_extraordinario = 1 
   select @w_monto_rubro = @w_pago

select @o_sobrante_pago = @i_monto_pago - @w_pago

-- COMPROBAR QUE EL SOBRANTE SEA MAYOR A CERO
if @o_sobrante_pago < 0
   select @o_sobrante_pago = 0


-- APLICACION DEL PAGO POR SECUENCIA DE RUBRO

-- PARA APLICAR EL MONTO EXTRAORDINARIO
if object_id('tempdb..#tmp_sec_rubro_abn_rub') is not null
   drop table #tmp_sec_rubro_abn_rub
   
create table #tmp_sec_rubro_abn_rub(
   am_id         int identity(1,1),
   am_cuota      money,      
   am_acumulado  money,  
   am_pagado     money,
   am_periodo    tinyint,    
   am_estado     tinyint,
   am_secuencia  tinyint,  
   am_gracia     money,     
   am_dividendo  smallint
)
   
if @i_extraordinario <> 1
   insert into #tmp_sec_rubro_abn_rub
   select am_cuota,      am_acumulado,  am_pagado,
          am_periodo,    am_estado,
          am_secuencia,  am_gracia,     am_dividendo
   from   ca_amortizacion with (nolock)
   where  am_operacion   =  @i_operacionca
   --between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir
   and    am_dividendo   between @i_dividendo and @w_dividendo_aux
   and    am_concepto    =  @i_concepto
   and    am_estado     <>  @w_est_cancelado
   --AND (am_cuota + am_gracia) <> am_pagado --LPO Excluir los rubros cancelados
   order  by am_dividendo, am_secuencia
else
   insert into #tmp_sec_rubro_abn_rub
   select am_cuota, am_acumulado, am_pagado,
          am_periodo,     am_estado,
          am_secuencia,   am_gracia,    am_dividendo
   from   ca_amortizacion with (nolock)
   where  am_operacion   =  @i_operacionca
   and    am_dividendo   =  @i_dividendo
   and    am_concepto    =  @i_concepto
   order  by am_dividendo, am_secuencia

select @w_cont_sec_rub = count(1) 
from #tmp_sec_rubro_abn_rub

select @w_cont = 1

while @w_cont <= @w_cont_sec_rub
begin

   select 
      @w_am_cuota     = am_cuota,      
      @w_am_acumulado = am_acumulado,  
      @w_am_pagado    = am_pagado,
      @w_am_periodo   = am_periodo,    
      @w_am_estado    = am_estado,
      @w_am_secuencia = am_secuencia,  
      @w_am_gracia    = am_gracia,     
      @w_dividendo    = am_dividendo
   from #tmp_sec_rubro_abn_rub
   where am_id = @w_cont
   
   
   if @w_pago <= 0
   begin
      break  
   end
   
   select @w_dif_am_acumulado  = @w_am_acumulado - @w_am_pagado  -- FCP 10/OCT/2005 - REQ 389
   
   -- if @i_en_gracia_int = 'S'                 REQ 175: PEQUEÑA EMPRESA
   --    select @w_am_gracia = 0                REQ 175: PEQUEÑA EMPRESA
   
   if @i_extraordinario <> 1
   begin
      if (@i_fpago = 'A') and (@w_am_estado = @w_est_novigente)
         select @w_monto_rubro = @w_am_cuota + @w_am_gracia - @w_am_pagado
      ELSE
      begin
         if @i_tipo_cobro = 'A'
            select @w_monto_rubro = @w_am_acumulado + @w_am_gracia - @w_am_pagado 
         else
            select @w_monto_rubro = @w_am_cuota + @w_am_gracia - @w_am_pagado 
      end
   end
   
   if @w_monto_rubro >= 0
   begin 
      if (@w_pago >= @w_monto_rubro)  and  @i_extraordinario <> 1
         select @w_pago_rubro = @w_monto_rubro
      else 
         select @w_pago_rubro = @w_pago

      select @w_pago = @w_pago - @w_pago_rubro --REBAJO PAGO
      
      select @w_pago_rubro_mn =  round(@w_pago_rubro * @i_cotizacion, @w_num_dec) --LPO CDIG Multimoneda
      select @w_pago_rubro    =  round(@w_pago_rubro,@w_num_dec)
      select @w_pago_rubro_mn =  round(@w_pago_rubro_mn,@w_num_dec_n) 

      ---MROA: ACTUALIZACION SALDO FONDO DE RECURSOS POR ABONO APLICADO A CAPITAL
      if @i_concepto = 'CAP' and @i_en_linea = 'S'
      begin
	     exec @w_error = cob_cartera..sp_fuen_recur 
         @s_date        = @s_date,
         @i_operacion   = 'F',
         @i_monto       = @w_pago_rubro,
         @i_opcion      = 'P',
         @i_reverso     = 'N',
         @i_operacionca = @i_operacionca,
         @i_secuencial  = @i_secuencial_pag,
         @i_dividendo   = @i_dividendo,
         @i_fecha_proc  = @w_fecha_ult_proceso
	  
          if @w_error <> 0
             return @w_error

      end

	  -- KDR Si es abn extraordinario, obtiene estado de la operación.
      if @i_extraordinario =  1
         if @w_am_estado = @w_est_cancelado
            SELECT @w_am_estado = @w_estado_op  		 		 
      
      if @w_am_estado = 0    ---normal cancelando cuota
      begin
         if @i_condonacion = 'S' and @i_concepto = 'CAP' and @w_estado_op = @w_est_suspenso        -- 13/ENE/2011 - REQ 089 - ACUERDOS DE PAGO
            select @w_am_estado = @w_est_vigente                                                   -- 13/ENE/2011 - PARA CONDONACION NO SE MANEJA CAPITAL EN SUSPENSO
         else
            select @w_am_estado = @w_estado_op
      end         
              
      -- GENERACION DE LOS CODIGOS VALOR
      select @w_codvalor1     = (@w_codvalor * 1000) + (@w_am_estado * 10) + @w_am_periodo,
             @w_codvalor_con1 = (@w_codvalor * 1000) + (@w_am_estado * 10) + @w_est_condonado
      
      -- SI SE TRATA DE UNA NORMALIZACION y EL ESTADO DEL CONCEPTO QUE SE PAGA ES SUSPENSO
      -- ENTONCES SE CAMBIA EL CODIGO VALOR PARA PODER CREAR LA CONSTITUCION DE DIFERIDOS
      if @ctx_es_norm = 1 and @w_am_estado = @w_est_suspenso
      begin
         select @w_codvalor1     = @w_codvalor1 * 10 + 2,
                @w_codvalor_con1 = @w_codvalor_con1 * 10 + 2
      end

      if @w_pago_rubro > 0 
      begin
         select @w_am_estado_ar    = @w_am_estado,
                @w_concepto_ar     = @i_concepto,
                @w_afectacion_ar   = @w_afectacion
         
         if exists(select 1 from ca_det_trn
                   where dtr_operacion  = @i_operacionca
                   and   dtr_secuencial = @i_secuencial_pag
                   and   dtr_dividendo  = @w_dividendo 
                   and   dtr_concepto   = @i_concepto
                   and   dtr_codvalor   = @w_codvalor1)   	  
         begin
            update ca_det_trn
            set    dtr_monto            = dtr_monto    + @w_pago_rubro,
                   dtr_monto_mn         = dtr_monto_mn + @w_pago_rubro_mn
            where dtr_operacion  = @i_operacionca
            and   dtr_secuencial = @i_secuencial_pag
            and   dtr_dividendo  = @w_dividendo 
            and   dtr_concepto   = @i_concepto
            and   dtr_codvalor   = @w_codvalor1
            
            if @@error <> 0 return 708166
         end
         ELSE
         begin
            if (@i_cotizacion_dia_sus is null   -- NO TIENE VALORES EN SUSPENSO
            or @w_tipo_rubro not in ('I', 'M') -- ES DISTINTO DE INTERES O MORA
            or @w_am_estado not in (1, 2))
			and @i_condonacion <> 'S'           -- KDR Si no es condonación [Condonación se registra con otro código valor] 
            begin
               insert into ca_det_trn
                     (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                      dtr_concepto,       dtr_estado,     dtr_periodo,
                      dtr_codvalor,       dtr_monto,      dtr_monto_mn,
                      dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                      dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                      dtr_monto_cont)
               values(@i_secuencial_pag,  @i_operacionca, @w_dividendo,
                      @i_concepto,        @w_am_estado,   @w_am_periodo,
                      @w_codvalor1,       @w_pago_rubro,  @w_pago_rubro_mn,
                      @w_op_moneda,       @i_cotizacion,  @i_tcotizacion,
                      @w_afectacion,      '00000',        'CARTERA',
                      0.00)
               
               if @@error <> 0
                  return 708166
            end
            ELSE
            begin
			
			   if @i_condonacion <> 'S'
			   begin
                  select @w_valor_vig_mn = round(@w_factor_vig * @w_pago_rubro_mn, @w_num_dec_n)
                  select @w_pago_rubro_mn = @w_pago_rubro_mn - @w_valor_vig_mn
                  
                  -- INSERTAR LA PARTE VIGENTE
                  insert into ca_det_trn
                        (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                         dtr_concepto,       dtr_estado,     dtr_periodo,
                         dtr_codvalor,
                         dtr_monto,
                         dtr_monto_mn,
                         dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                         dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                         dtr_monto_cont)
                  values(@i_secuencial_pag,  @i_operacionca, @w_dividendo,
                         @i_concepto,        @w_am_estado,   @w_am_periodo,
                         @w_codvalor1,
                         round(@w_valor_vig_mn/@i_cotizacion, @w_num_dec),
                         @w_valor_vig_mn,
                         @w_op_moneda,       @i_cotizacion,  @i_tcotizacion,
                         @w_afectacion,      '00000',        'CARTERA',
                         0.00)
                  
                  if @@error <> 0
                     return 708166
                  
                  select @w_codvalor1 = (@w_codvalor * 1000) + (@w_est_suspenso * 10) + @w_am_periodo
			      
                  insert into ca_det_trn
                        (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                         dtr_concepto,       dtr_estado,     dtr_periodo,
                         dtr_codvalor,
                         dtr_monto,
                         dtr_monto_mn,
                         dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                         dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                         dtr_monto_cont)
                  values(@i_secuencial_pag,  @i_operacionca, @w_dividendo,
                         @i_concepto,        @w_am_estado,   @w_am_periodo,
                         @w_codvalor1,
                         round(@w_pago_rubro_mn/@i_cotizacion, @w_num_dec),
                         @w_pago_rubro_mn,
                         @w_op_moneda,       @i_cotizacion,  @i_tcotizacion,
                         @w_afectacion,      '00000',        'CARTERA',
                         0.00)
                  
                  if @@error <> 0
                     return 708166
                  
                  select @w_codvalor1 = (@w_codvalor * 1000) + (@w_am_estado * 10) + @w_am_periodo
		       end
            end
         end 
         
         -- GENERACION DE LA AFECTACION CONTABLE CASO CONDONACION
         if @i_condonacion = 'S'  and @i_colchon = 'N' 
         begin
            select @w_am_estado_ar    = @w_est_condonado,
                   @w_concepto_ar     = @i_concepto,
                   @w_afectacion_ar   = @w_afectacion
            
            if exists (select 1 from ca_det_trn
                       where dtr_operacion  = @i_operacionca
                       and   dtr_secuencial = @i_secuencial_pag
                       and   dtr_dividendo  = @w_dividendo 
                       and   dtr_concepto   = @i_concepto
                       and   dtr_codvalor   = @w_codvalor_con1)   
            begin
               update ca_det_trn
               set    dtr_monto    = dtr_monto    + @w_pago_rubro,
                      dtr_monto_mn = dtr_monto_mn + @w_pago_rubro_mn
               where dtr_operacion  = @i_operacionca
               and   dtr_secuencial = @i_secuencial_pag
               and   dtr_dividendo  = @w_dividendo 
               and   dtr_concepto   = @i_concepto
               and   dtr_codvalor   = @w_codvalor_con1
               
               if @@error <> 0 return 708166
            end 
            ELSE 
            begin
               insert into ca_det_trn
                     (dtr_secuencial,   dtr_operacion, dtr_dividendo,
                      dtr_concepto,       dtr_estado,    dtr_periodo,
                      dtr_codvalor,       dtr_monto,     dtr_monto_mn,
                      dtr_moneda,         dtr_cotizacion,dtr_tcotizacion,
                      dtr_afectacion,     dtr_cuenta,    dtr_beneficiario,
                      dtr_monto_cont)
               values(@i_secuencial_pag, @i_operacionca,  @w_dividendo,
                      @i_concepto,       @w_est_condonado,@w_am_periodo,
                      @w_codvalor_con1,  @w_pago_rubro,   @w_pago_rubro_mn,
                      @w_op_moneda,      @i_cotizacion,   @i_tcotizacion,   
                      'C',              '00000',      'CARTERA',            -- KDR Afectación Crédito
                      0.00)
               
               if @@error <> 0 return 708166
            end 
         end -- Condonacion
         
         -- Colchon
         if @i_colchon = 'S'  
         begin
            select @w_am_estado_ar    = @w_am_estado,
                   @w_concepto_ar     = 'COL',
                   @w_afectacion_ar   = 'D'
            
            select @w_codvalor4 = co_codigo * 1000  
            from  ca_concepto
            where co_concepto  = 'COL'
            
            insert into ca_det_trn
                  (dtr_secuencial,   dtr_operacion, dtr_dividendo,
                   dtr_concepto,       dtr_estado,    dtr_periodo,
                   dtr_codvalor,       dtr_monto,     dtr_monto_mn,
                   dtr_moneda,         dtr_cotizacion,dtr_tcotizacion,
                   dtr_afectacion,     dtr_cuenta,    dtr_beneficiario,
                   dtr_monto_cont)
            values(@i_secuencial_pag, @i_operacionca,  @w_dividendo,
                   'COL',              @w_am_estado,    @w_am_periodo,
                   @w_codvalor4,       @w_pago_rubro,   @w_pago_rubro_mn,
                   @w_op_moneda,       @i_cotizacion,   @i_tcotizacion,   
                   'D',              '00000',      'CARTERA',
                   0.00)
         end 
         -- Fin Colchon
         
         -- ALIMENTAR TABLA CA_ABONO_RUBRO
         insert into ca_abono_rubro
               (ar_fecha_pag,         ar_secuencial,              ar_operacion,                ar_dividendo,
                ar_concepto,          ar_estado,                  ar_monto,
                ar_monto_mn,          ar_moneda,                  ar_cotizacion,               ar_afectacion,
                ar_tasa_pago,         ar_dias_pagados)
         values(@s_date,             @i_secuencial_pag,      @i_operacionca,       @w_dividendo,
                @w_concepto_ar,      @w_am_estado_ar,        @w_pago_rubro,
                @w_pago_rubro_mn,    @w_op_moneda,           @i_cotizacion,         @w_afectacion_ar,
                @i_tasa_pago,        @i_dias_pagados)
      
      end  -- Fin de @w_pago_rubro > 0
      
      -- ACTUALIZAR LA AMORTIZACION DEL RUBRO
      
      if @i_extraordinario <> 1 
      begin  
         update ca_amortizacion
         set    am_pagado    = am_pagado + @w_pago_rubro,
                am_acumulado = case when @i_fpago = 'A' and am_pagado + @w_pago_rubro > am_acumulado then am_pagado + @w_pago_rubro else am_acumulado end  --PNA
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_dividendo
         and    am_concepto  = @i_concepto
         and    am_secuencia = @w_am_secuencia
         
         if @@error <> 0
         begin
            return 705050  
         end
      end
      ELSE
      begin
         if @i_extraordinario = 1 
         begin
            if  @i_tipo_rubro = 'C'
            and exists(select 1
                      from   ca_dividendo
                      where  di_operacion = @i_operacionca
                      and    di_dividendo = @w_dividendo
                      and    di_estado    = 3)
            begin
               update ca_rubro_op
               set    ro_gracia = isnull(ro_gracia, 0) + isnull(@w_pago_rubro, 0)
               where  ro_operacion = @i_operacionca
               and    ro_concepto  = @i_concepto
            end
            ELSE
            begin
               update ca_amortizacion ---Este update se hace solo para el valor del concepto distintos de CAP en la cuota cancelada
               set    am_pagado          = am_pagado + @w_pago_rubro,
                      am_cuota           = am_cuota  + @w_pago_rubro,
                      am_acumulado       = am_acumulado + @w_pago_rubro
               where am_operacion = @i_operacionca
               and   am_dividendo = @w_dividendo
               and   am_concepto  = @i_concepto
               and   am_secuencia = @w_am_secuencia
               
               if @@error <> 0
               begin
                  return 705050
               end
            end
         end 
      end
      
      if @i_tipo_cobro = 'P' and @i_tipo_rubro in ('I','F','O') and  @i_fpago <> 'A'
      begin
         select 
         @w_prepago_int = isnull(sum(am_pagado - am_acumulado), 0),
         @w_gracia_div  = isnull(sum(am_gracia), 0)                              -- REQ 175: PEQUEÑA EMPRESA
         from ca_amortizacion 
         where am_operacion  = @i_operacionca
         and   am_dividendo  = @w_dividendo
         and   am_concepto   = @i_concepto
         and   am_secuencia  = @w_am_secuencia
         and   am_estado    <> @w_est_cancelado
		 
       
         if @w_prepago_int > 0
         begin
            -- INI - REQ 175: PEQUEÑA EMPRESA
            -- CAUSACION DE VALORES EN GRACIA PAGADOS POR ADELANTADO
            if @w_gracia_div > 0
            begin
               if @w_prepago_int < @w_gracia_div
                  select 
                  @w_causar_en_gr = @w_prepago_int,
                  @w_prepago_int  = 0
               else
                  select 
                  @w_causar_en_gr = @w_gracia_div,
                  @w_prepago_int  = @w_prepago_int - @w_gracia_div

               select @w_causado_gr = isnull(sum(am_acumulado), 0)
               from ca_amortizacion 
               where am_operacion   = @i_operacionca
               and   am_dividendo  <= @w_dividendo
               and   am_concepto    = @i_concepto
               and   am_secuencia   = @w_am_secuencia
               and   am_gracia      < 0
               
               select @w_gracia_acum = isnull(sum(am_gracia), 0)
               from ca_amortizacion 
               where am_operacion   = @i_operacionca
               and   am_dividendo  <= @w_dividendo
               and   am_concepto    = @i_concepto
               and   am_secuencia   = @w_am_secuencia
               and   am_gracia      > 0
               
               -- CAUSACION DE INTERES PENDIENTE POR GRACIA
               select @w_pend_causacion = @w_gracia_acum - @w_causado_gr
            
               if @w_pend_causacion > 0
               begin               
                  if @w_pend_causacion < @w_causar_en_gr
                     select @w_causar_en_gr = @w_pend_causacion
               
                  select @w_div_gr_acum = 0
                     
                  while 1=1
                  begin
                     select top 1
                     @w_div_gr_acum = am_dividendo,
                     @w_xcausar_div = am_cuota - am_acumulado
                     from ca_amortizacion
                     where am_operacion                         = @i_operacionca
                     and   am_dividendo                         > @w_div_gr_acum
                     and   am_concepto                          = @i_concepto
                     and   am_secuencia                         = @w_am_secuencia
                     and   am_gracia                            < 0
                     and   am_acumulado + am_gracia - am_pagado < 0
                     order by am_dividendo
                     
                     if @@rowcount = 0
                        break
                        
                     if @w_xcausar_div > @w_causar_en_gr
                        select 
                        @w_xcausar_div  = @w_causar_en_gr,
                        @w_causar_en_gr = 0
                     else
                        select 
                        @w_causar_en_gr = @w_causar_en_gr - @w_xcausar_div

                     select @w_xcausar_div_mn = round(@w_xcausar_div*@i_cotizacion, @w_num_dec_n)                     

                                          
                     --- PROVISION DEL VALOR PAGADO DE GRACIA
                     insert into ca_transaccion_prv with (rowlock)
                     (
                     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
                     tp_secuencial_ref,   tp_estado,           tp_dividendo,
                     tp_concepto,         tp_codvalor,         tp_monto,
                     tp_secuencia,        tp_comprobante,      tp_ofi_oper,
                     tp_monto_mn,         tp_moneda,           tp_cotizacion,
                     tp_tcotizacion,      tp_reestructuracion)
                     values
                     (
                     @s_date,             @i_operacionca,      @w_fecha_ult_proceso,
                     @i_secuencial_pag,   'ING',               @w_div_gr_acum,
                     @i_concepto,         @w_codvalor1,        @w_xcausar_div,
                     @w_am_secuencia,     0,                   @w_oficina_op,
                     @w_xcausar_div_mn,   @w_op_moneda,        @i_cotizacion,
                     @i_tcotizacion,      @w_reestructuracion
                     )          
                     
                     if @@error <> 0
                        return 708165     
                     
                     --SOLO SE ACUMULA LO QUE SE PAGO PROYECTADAMENTE NO TODA LA CUOTA
                     update ca_amortizacion 
                     set    am_acumulado =  am_acumulado + @w_xcausar_div
                     where  am_operacion = @i_operacionca
                     and    am_dividendo = @w_div_gr_acum
                     and    am_concepto  = @i_concepto
                     and    am_secuencia = @w_am_secuencia          
                     
                     if @@error <> 0
                        return 705050
                     if @w_causar_en_gr = 0
                        break
                  end
               end
            end
            -- FIN - REQ 175: PEQUEÑA EMPRESA
            
            if @w_prepago_int > 0
            begin
              
               --- Insertar en tabla de transacciones de PRV 
               select @w_prepago_int_mn = round(@w_prepago_int*@i_cotizacion, @w_num_dec_n)
                    
               insert into ca_transaccion_prv with (rowlock)
               (
               tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
               tp_secuencial_ref,   tp_estado,           tp_dividendo,
               tp_concepto,         tp_codvalor,         tp_monto,
               tp_secuencia,        tp_comprobante,      tp_ofi_oper,
               tp_monto_mn,         tp_moneda,           tp_cotizacion,
               tp_tcotizacion,      tp_reestructuracion
               )
               values
               (
               @s_date,             @i_operacionca,      @w_fecha_ult_proceso,
               @i_secuencial_pag,   'ING',               @w_dividendo,
               @i_concepto,         @w_codvalor1,        @w_prepago_int,
               @w_am_secuencia,     0,                   @w_oficina_op,
               @w_prepago_int_mn,   @w_op_moneda,        @i_cotizacion,
               @i_tcotizacion,      @w_reestructuracion
               )          
               
               if @@error <> 0
                  return 708165     
               
               --SOLO SE ACUMULA LO QUE SE PAGO PROYECTADAMENTE NO TODA LA CUOTA
               update ca_amortizacion 
               set    am_acumulado =  am_acumulado + @w_prepago_int
               where  am_operacion = @i_operacionca
               and    am_dividendo = @w_dividendo
               and    am_concepto  = @i_concepto
               and    am_secuencia = @w_am_secuencia
         
               select @w_pago_todo = 'N'
               select @w_sum = isnull(sum(am_cuota + am_gracia - am_pagado),0)
               from ca_amortizacion
               where am_operacion = @i_operacionca
               and   am_dividendo = @w_dividendo
               and   am_concepto  = @i_concepto
               and   am_secuencia = @w_am_secuencia
                         
               if @w_sum = 0
                  select @w_pago_todo = 'S'
               
               ---def 4767 BAC   
               ---ANALIZAR  QUE FECHA DE ULTIMA CAUSACION COLOCAR PARA LAS OEPRACIONES PASIVAS
               if @w_op_naturaleza = 'P'
               begin
                  select @w_int_proyectado = isnull(sum(am_cuota ),0)
                  from ca_amortizacion
                  where am_operacion = @i_operacionca
                  and   am_dividendo = @w_dividendo
                  and   am_concepto  = @i_concepto
                  and   am_secuencia = @w_am_secuencia
                  
                  select @w_int_dias = di_dias_cuota,
                        @w_fecha_ven = di_fecha_ven
                  from ca_dividendo
                  where di_operacion = @i_operacionca
                  and   di_dividendo = @w_dividendo
                  
                  select @w_val_dia = @w_int_proyectado / (@w_int_dias * 1.0)
                  
                  select @w_dias_prepago = ceiling(@w_prepago_int / @w_val_dia)
                  
                  if @w_dias_prepago <= 0
                    select @w_dias_prepago  = 1
                  
                  select @w_fecha_ult_causacion =    dateadd(dd,@w_dias_prepago,@w_fecha_ult_causacion)
                  
                  if @w_fecha_ult_causacion < @w_fecha_ven
                  begin
                     update ca_operacion
                     set    op_fecha_ult_causacion = @w_fecha_ult_causacion
                     where  op_operacion = @i_operacionca
                  end
               end   
               ---Fin def 8077 BAC   
            end
         end
      end
      
      --XMA INI
      -- SI LA OPERACION ES EN UVR's AFECTAR EL VALOR DE CORRECCION EN SUSPENSO
      if @w_op_moneda = @w_moneda_uvr
      begin
         select @w_am_correccion_sus_mn = co_correccion_sus_mn,
                @w_am_correc_pag_sus_mn = co_correc_pag_sus_mn 
         from   ca_correccion
         where  co_operacion  = @i_operacionca
         and    co_dividendo  = @w_dividendo
         and    co_concepto   = @i_concepto
         
         select @w_correc_pag_sus = isnull(@w_am_correccion_sus_mn, 0) - isnull(@w_am_correc_pag_sus_mn,0)
         
         -- SI EXISTE VALOR EN SUSPENSO QUE SE PAGUE CONTABILIZARLO
         if (@w_correc_pag_sus > 0   and ((@w_am_estado = @w_est_suspenso and @i_concepto in (@w_parametro_int, @w_parametro_mora)) or (@i_concepto = @w_parametro_cap and @w_am_estado <> @w_est_suspenso)))
         and @w_codvalor = 10
         begin
            -- SI EL VALOR POR CONTABILIZAR ES MAYOR AL PAGADO CONTABILIZAR SOLO LO PAGADO
            if isnull(@w_pago_rubro_mn,0) < isnull(@w_correc_pag_sus,0)
               select @w_correc_pag_sus = @w_pago_rubro_mn
            
            select @w_codvalor_sus1 = (@w_codvalor * 1000) + (@w_estado_op * 10) + 9

            insert into ca_det_trn
                  (dtr_secuencial,        dtr_operacion,     dtr_dividendo,
                   dtr_concepto,          dtr_estado,        dtr_periodo,
                   dtr_codvalor,          dtr_monto,         dtr_monto_mn,
                   dtr_moneda,            dtr_cotizacion,    dtr_tcotizacion,
                   dtr_afectacion,        dtr_cuenta,        dtr_beneficiario,
                   dtr_monto_cont)
            values(@i_secuencial_pag,     @i_operacionca,    @w_dividendo,
                   @i_concepto,           @w_am_estado,      @w_am_periodo,
                   @w_codvalor_sus1,      @w_correc_pag_sus, @w_correc_pag_sus,
                   @w_moneda_n,           1.0,               'N',     
                   @w_afectacion,         '00000',           'PAGO SUSP.CMO-CARTERA',
                   0.00)
            
            if @@error <> 0
            begin
               print 'error...abonoru.sp'
               return 708166
            end
            
            -- cambio de los campos am_correccion_xxx a la nueva tabla ca_correccion
            if exists (select 1 from ca_amortizacion
                       where am_operacion = @i_operacionca
                       and   am_dividendo = @w_dividendo
                       and   am_concepto  = @i_concepto
                       and   am_secuencia = @w_am_secuencia)
            begin
               update ca_correccion
               set    co_correc_pag_sus_mn = isnull(co_correc_pag_sus_mn, 0) + @w_correc_pag_sus
               where  co_operacion = @i_operacionca
               and    co_dividendo = @w_dividendo
               and    co_concepto  = @i_concepto
               
               if @@error <> 0
                  return 705050
            end--- if exists (select...
            -- fin cambio
         end 
      end  --XMA FIN SUSPENCION DE CAUSACION

      if @i_tipo_rubro not in ('I','F')
      begin
         update ca_amortizacion
         set am_acumulado = am_cuota                                -- REQ 175: PEQUEÑA EMPRESA
         where  am_cuota + am_gracia  = am_pagado                   -- REQ 175: PEQUEÑA EMPRESA
         and    am_operacion          = @i_operacionca
         and    am_dividendo          = @w_dividendo
         and    am_concepto           = @i_concepto
         and    am_secuencia          = @w_am_secuencia
         and    am_cuota             <> am_acumulado
         and    am_gracia            >= 0
         
         if @@error <> 0
            return 705050       ---3
      end


/*LPO Se comenta el update a cancelado del rubro */


      -- CANCELACION DEL RUBRO
      if @i_tipo_rubro <> 'M' and  @i_concepto not in (select c.codigo from cobis..cl_tabla t, cobis..cl_catalogo c  -- KDR Cargo Gestión Cobranza no debe Cancelarse, ya que puede acumularse un nuevo valor
                                                  WHERE t.tabla = 'ca_cargos_gestion_cobranza'
                                                  AND   t.codigo      = c.tabla
                                                  AND   c.estado      = 'V')
      begin
--       select @w_rowcount_act = sqlcontext.gettriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN', 'N')
--         EXEC sp_addextendedproperty
--              'CCA_TRIGGER','S',@level0type='Schema',@level0name=dbo,
--              @level1type='Table',@level1name=ca_amortizacion,
--              @level2type='Trigger',@level2name=tg_ca_amortizacion_can
         update ca_amortizacion
         set    am_estado            = @w_est_cancelado
         where  am_cuota + am_gracia = am_pagado                        -- REQ 175: PEQUEÑA EMPRESA
         and    am_operacion         = @i_operacionca
         and    am_dividendo         = @w_dividendo
         and    am_concepto          = @i_concepto
         and    am_secuencia         = @w_am_secuencia
         
         if @@error <> 0
         begin
--          select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--            EXEC sp_dropextendedproperty
--                 'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                 @level1type='Table',@level1name=ca_amortizacion,
--                 @level2type='Trigger',@level2name=tg_ca_amortizacion_can
            return 705050       ---2
         end
--       select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--         EXEC sp_dropextendedproperty
--              'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--              @level1type='Table',@level1name=ca_amortizacion,
--              @level2type='Trigger',@level2name=tg_ca_amortizacion_can
      end


     
      if @i_tipo_rubro = 'I' and @w_estado_op <> @w_est_suspenso
      begin
         --SI ES VALOR PRESENTE,
         select @w_tipo_cobro_org = ab_tipo_cobro
         from ca_abono
         where ab_operacion = @i_operacionca
         and   ab_secuencial_ing = @i_secuencial_ing
         
         --SI EL MAXIMO DIVIDENDO ES 1 Y EL PAGO ES INT SE DEBE CANCELAR EL RUBRO CON EL PAGO EL VP
         --SOLO SI EL AUMULADO  ES IGUAL AL PAGADO

/*LPO Se comenta el update a cancelado del rubro*/
         if @w_tipo_cobro_org = 'E' and (@i_tipo_cobro = 'P' and  @w_pago_todo = 'S') or (@w_dividendo_max = 1)
         begin
--           select @w_rowcount_act = sqlcontext.gettriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN', 'N')
--             EXEC sp_addextendedproperty
--                  'CCA_TRIGGER','S',@level0type='Schema',@level0name=dbo,
--                  @level1type='Table',@level1name=ca_amortizacion,
--                  @level2type='Trigger',@level2name=tg_ca_amortizacion_can

            --EN VALOR PRESENTE AL PAGAR EL RUBRO DEBE QUEDAR CANCELADO
            update ca_amortizacion
            set    am_estado = @w_est_cancelado
            where  am_acumulado  = am_pagado
            and    am_operacion = @i_operacionca
            and    am_dividendo = @w_dividendo
            and    am_concepto  = @i_concepto
            and    am_secuencia = @w_am_secuencia
            and    am_estado    <> @w_est_cancelado
            
            if @@error <> 0
            begin
--             select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--               EXEC sp_dropextendedproperty
--                    'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                    @level1type='Table',@level1name=ca_amortizacion,
--                    @level2type='Trigger',@level2name=tg_ca_amortizacion_can
               return 705050
            end
--          select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--            EXEC sp_dropextendedproperty
--                 'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--                 @level1type='Table',@level1name=ca_amortizacion,
--                 @level2type='Trigger',@level2name=tg_ca_amortizacion_can
         end         
      end
   end --  Monto_Rubro
   
   set @w_cont = @w_cont + 1
   
end -- CA_AMORTIZACION

return 0
go

