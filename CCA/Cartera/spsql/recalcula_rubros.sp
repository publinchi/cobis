/************************************************************************/
/*      Archivo:                recalcula_rubros.sp                      */
/*      Stored procedure:       sp_recalcula_rubros                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Marzo 2008                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                           */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Recalculo de comision Mipymes, Comision FNG y Seguros deudores  */
/*      vencido                                                         */
/*                              CAMBIOS                                 */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_recalcula_rubros')
   drop proc sp_recalcula_rubros
go

---Incl 37962 Partiendo de la ver. 22

create proc sp_recalcula_rubros
    @i_operacionca          int,
    @i_dividendo            smallint,
    @i_concepto             catalogo,
    @i_fecha_proceso        smalldatetime = null

as
declare
@w_sp_name              varchar(30),
@w_return               int,
@w_est_vigente          tinyint,
@w_est_novigente        tinyint,
@w_num_dec              smallint,
@w_moneda               smallint,
@w_fecha_liq            datetime,
@w_op_monto             money,
@w_di_dividendo         int,
@w_di_fecha_ini         datetime,
@w_di_fecha_ven         datetime,
@w_di_estado            int,
@w_fecha_anual          datetime,
@w_fecha_anual_2        datetime,
@w_valor_rubro          money,
@w_factor_rubro         float,
@w_asociado             catalogo,
@w_porcentaje           float,
@w_valor_asociado       money,
@w_plazo_restante       int,
@w_fecha_ini            datetime,
@w_fecha_fin            datetime,
@w_saldo_capital        money,
@w_saldo_capital_ven    money,
@w_fpago_seg            char(1),
@w_nro_dias_ano         int,
@w_recalculo            int,
@w_repetir_cuota        char(1),
@w_mes_anualidad        int,
@w_error                int,
@w_fecha_ult_proceso    smalldatetime,
@w_ajuste_grac          money,
@w_gracia_org           money,
@w_gracia_nue           money,
@w_min_div_int          smallint,
@w_periodo_fng          tinyint,
@w_periodo_fag          tinyint,
@w_cod_gar_fag          catalogo,
@w_tdividendo           catalogo,
@w_freq_cobro           int,
@w_periodo_int          int,                                          -- REQ 175: PEQUEÑA EMPRESA
@w_est_vencido          tinyint,
@w_parametro_fng        catalogo,
@w_parametro_fag        catalogo,
@w_min_dividendo        int,
@w_dividendo            smallint,
@w_concepto             catalogo,
@w_cuota                money,
@w_fecha_hoy            datetime,
@w_codvalor             int,
@w_periodos             int,
@w_periodos_faltan      int,
@w_reversar             char(1),
@w_op_estado            smallint,
@w_dif_fng              money,
@w_dif_fag              money,
@w_tp_monto             money,
@w_tp_estado            catalogo,
@w_tp_montoRV           money,
@w_plazo                int,
@w_factor               int,
@w_mes_oper             int,
@w_fecha_fin_real       datetime,
@w_reajuste_com         int,
@w_tramite              int,
@w_porcentaje_resp      float,
@w_fecha_fin_habil      datetime,
@w_ciudad_nacional      int,
@w_siguiente_dia        datetime,
@w_es_habil             char(1),
@w_dia_semana           int,
@w_oficina_op			int


/** INICIALIZACION VARIABLES **/
select 
    @w_sp_name              = 'sp_recalcula_rubros',
    @w_est_vigente          = 1,
    @w_est_vencido          = 2,
    @w_est_novigente        = 0,
    @w_valor_rubro          = 0,
    @w_porcentaje           = 0,
    @w_valor_asociado       = 0,
    @w_asociado             = '',
    @w_plazo_restante       = 0,
    @w_nro_dias_ano         = 365,
    @w_repetir_cuota        = 'N',
    @w_mes_anualidad        = 0,
    @w_dif_fng              = 0,
    @w_tp_monto             = 0,
    @w_tp_montoRV           = 0,
    @w_reajuste_com         = 0
    
    

/*PARAMETRO DE LA GARANTIA DE FNG*/
select @w_parametro_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'

--- PARAMETRO DE LA GARANTIA DE FAG PERIODICA 
select @w_parametro_fag = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and pa_nemonico = 'CMFAGP'

/* PARAMETRO PERIODICIDAD COBRO FNG */
select @w_periodo_fng = pa_tinyint
  from cobis..cl_parametro 
 where pa_nemonico = 'PERFNG'
   and pa_producto = 'CCA'

--- PARAMETRO PERIODICIDAD COBRO FAG 
select @w_periodo_fag = pa_tinyint
  from cobis..cl_parametro 
 where pa_nemonico = 'PERFAG'
   and pa_producto = 'CCA'

--- CODIGO PADRE GARANTIA DE FAG 
select @w_cod_gar_fag = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and pa_nemonico = 'CODFAG'
    
/** DATOS OPERACION **/
select 
@w_fecha_liq         = op_fecha_liq,
@w_fecha_ini         = op_fecha_ini,
@w_fecha_fin         = op_fecha_fin,
@w_op_monto          = op_monto,
@w_moneda            = op_moneda,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_tdividendo        = op_tdividendo,
@w_periodo_int       = op_periodo_int,                                -- REQ 175: PEQUEÑA EMPRESA
@w_op_estado         = op_estado,
@w_tramite           = op_tramite,
@w_oficina_op        = op_oficina
from   ca_operacion
where  op_operacion = @i_operacionca

select @w_fecha_hoy = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

---LAS OPERACIONES CASTIGADAS NO DEBEN TENER TRASLADO DE COMISIONES PORQUE
---EL CASTIGO SE HIZO CON UNOS SALDOS QUE HAY QUE REESPETAR

if (@w_op_estado = 4 )and (@i_concepto = @w_parametro_fng)  
return 0

-- INI JAR REQ 197
/* FRECUENCIA DE COBRO DEPENDIENDO DEL TIPO DE DIVIDENDO */
select 
@w_freq_cobro  = td_factor / 30,
@w_periodo_int = @w_periodo_int * td_factor / 30                     -- REQ 175: PEQUEÑA EMPRESA
from ca_tdividendo
where td_tdividendo = @w_tdividendo
 
select @w_freq_cobro = @w_periodo_fng / @w_freq_cobro

select @w_periodos = td_factor / 30
  from ca_tdividendo
 where td_tdividendo = @w_tdividendo

 
-- FIN JAR REQ 197

/* VERIFICA SI EL RUBRO TIENE RUBRO ASOCIADO */
if exists (select 1
           from   ca_rubro_op
           where  ro_operacion         = @i_operacionca
           and    ro_concepto_asociado = @i_concepto)
begin
   select 
   @w_asociado   = ro_concepto,
   @w_porcentaje = ro_porcentaje
   from   ca_rubro_op
   where  ro_operacion         = @i_operacionca
   and    ro_concepto_asociado = @i_concepto
end


/* OBTENER LA FECHA DE VENCIMIENTO FINAL DESDE ca_dividendo */
select @w_fecha_fin = max(di_fecha_ven)
from  ca_dividendo
where di_operacion = @i_operacionca

      
/* NUMERO DE DECIMALES */
exec @w_return = sp_decimales
    @i_moneda      = @w_moneda,
    @o_decimales   = @w_num_dec out

if @w_return <> 0 return  @w_return


/* OBTENER FACTOR DE CALCULO DE LOS RUBROS */
select @w_factor_rubro = ro_porcentaje,
       @w_fpago_seg    = ro_fpago
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_concepto  = @i_concepto

if @w_fpago_seg = 'A'
   select @i_dividendo = @i_dividendo - 1
   

if @i_concepto in ('SEGDEUVEN','SEGDEUEM')
begin
   /* RECALCULAR VALOR DE SEGDEUVEN SOBRE EL SALDO DE CAPITAL */
   select @w_saldo_capital = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from   ca_amortizacion, ca_rubro_op
   where  am_operacion  = @i_operacionca
   and    ro_operacion  = am_operacion
   and    ro_concepto   = am_concepto 
   and    ro_tipo_rubro = 'C'

   select @w_valor_rubro = round((@w_saldo_capital * @w_factor_rubro * @w_periodo_int / 100.0), @w_num_dec)
   
   -- INI - 03/FEB/2011 - REQ 175: PEQUEÑA EMPRESA
   select @w_gracia_org = isnull(sum(am_gracia), 0)
   from ca_amortizacion
   where am_operacion = @i_operacionca
   and   am_dividendo = @i_dividendo + 1
   and   am_concepto  = @i_concepto
   and   am_cuota     > am_pagado

   if exists(
   select 1 from ca_dividendo
   where di_operacion  = @i_operacionca
   and   di_dividendo  = @i_dividendo + 1
   and   di_de_interes = 'N'             )
   begin
      select @w_ajuste_grac = @w_valor_rubro + @w_gracia_org 
      
      select @w_min_div_int = min(di_dividendo)
      from ca_dividendo
      where di_operacion  = @i_operacionca
      and   di_dividendo  > @i_dividendo + 1
      and   di_de_interes = 'S'
      
      update ca_amortizacion set 
      am_gracia = am_gracia + @w_ajuste_grac
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_min_div_int
      and    am_concepto  = @i_concepto

	  if (@@error <> 0) return 724401      -- ajmc
	  
      select @w_gracia_nue = -@w_valor_rubro
   end
   else
      select @w_gracia_nue = @w_gracia_org
   -- FIN - 03/FEB/2011 - REQ 175: PEQUEÑA EMPRESA
   
   update ca_amortizacion set 
   am_cuota     = @w_valor_rubro,
   am_acumulado = @w_valor_rubro,
   am_gracia    = @w_gracia_nue                          -- 03/FEB/2011 - REQ 175: PEQUEÑA EMPRESA
   where  am_operacion = @i_operacionca
   and    am_dividendo = @i_dividendo + 1
   and    am_concepto  = @i_concepto
   and    am_cuota     > am_pagado

   if (@@error <> 0) return 724401
end --FIN CONCEPTO SEGDEUVEN


if @i_concepto = 'MIPYMES'
begin
   /* RECALCULO DE MIPYMES SOLO SI AL VENCIMIENTO DE LA CUOTA, EL PRESTAMO CUMPLE UNA ANUALIDAD */
   if datediff(mm,@w_fecha_liq,@w_fecha_ult_proceso) in (12,24,36,48,60) begin
      exec @w_error          = sp_calculo_mipymes
      @i_operacion           = @i_operacionca,
      @i_desde_batch         = 'S',
      @i_dividendo_anualidad = 0
      
      if @w_error <> 0 
         return @w_error
   end
end --FIN CONCEPTO MIPYMES

---if (@i_concepto = @w_parametro_fng)   
  ---print 'recalcula_rubros.sp @i_concepto ' + CAST (@i_concepto as varchar) +  ' @w_freq_cobro:  ' + CAST (@w_freq_cobro as varchar)+  ' @i_dividendo:  ' + CAST (@i_dividendo as varchar)
   
if (@i_concepto = @w_parametro_fng)  
begin
   ---SI NO HAY CUOTAS VENCIDAS ANTES DE LA CUOTA DE LA ANUALIDAD
   ---NO SE RECALCULA AUN POR QUE NO HAY A DONE TRASLADARLA 
   if not exists (select 1 from ca_dividendo
                   where di_operacion = @i_operacionca
                    and di_dividendo < @i_dividendo
                    and di_estado    = @w_est_vencido)
   begin
      ---PRINT 'recalcula_rubros.sp entro y saldra por que no hay dividendo Vencido'
      return 0
   end                 
   
   --- RECALCULA SALDO DE CAPITAL PARA OBTENER NUEVO VALOR COMFNGANU EN LA SIGUIENTE ANUALIDAD 
   select @w_saldo_capital = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from   ca_amortizacion, ca_rubro_op
   where  am_operacion  = @i_operacionca
   and    ro_operacion  = am_operacion
   and    ro_concepto   = am_concepto 
   and    ro_tipo_rubro = 'C'
   
   --- DETERMINA SI EL CALCULO SE HACE SOBRE 12 MESES O SOBRE EL PLAZO RESTANTE INFERIOR A 12 MESES 
   --- OBTIENE DATOS DEL DIVIDENDO PARA CALCULAR PLAZO RESTANTE 
   select 
   @w_di_dividendo = di_dividendo,
   @w_di_fecha_ini = di_fecha_ini,
   @w_di_fecha_ven = di_fecha_ven,
   @w_di_estado    = di_estado
   from  ca_dividendo
   where di_operacion  = @i_operacionca
   and   di_dividendo  = @i_dividendo

   select @w_plazo_restante = datediff(mm,@w_di_fecha_ven,@w_fecha_fin)
   select @w_periodos_faltan = @w_plazo_restante / @w_periodos  ---PERIODOS REALES QUE FALTAN

   if @w_periodos_faltan >= @w_freq_cobro
   begin
       ---print 'recalcula_rubros.sp 0 @w_plazo_restante ' + CAST (@w_plazo_restante as varchar) + ' - @w_freq_cobro - ' + CAST (@w_freq_cobro as varchar)
       select @w_valor_rubro = round((@w_saldo_capital * @w_factor_rubro / 100.0), @w_num_dec)
   end
   else
   begin
       ---print 'recalcula_rubros.sp  else  @w_periodos_faltan ' + CAST (@w_periodos_faltan as varchar) + ' - @w_periodo_fng - ' + CAST (@w_periodo_fng as varchar)
       select @w_valor_rubro = round((((@w_saldo_capital * @w_factor_rubro / 100.0) / @w_periodo_fng) * @w_plazo_restante), @w_num_dec)
   end


   -- EL VALOR DEL RUBRO COMFNGANU SE TRASLADA AL DIVIDENDO MAS VENCIDO
   select 
   @w_min_dividendo   =  min(di_dividendo)
   from ca_dividendo
   where di_operacion = @i_operacionca
   and   di_estado    = @w_est_vencido

   if @w_min_dividendo is null
   begin
      return 0
   end
   ---print 'recalcula_rubros.sp entroo @i_concepto:  ' + CAST (@i_concepto as varchar) + '@w_min_dividendo : '  +  CAST (@w_min_dividendo as varchar) +  '@w_valor_rubro : '  + CAST (@w_valor_rubro as varchar)
     
   if exists (select 1 
              from   ca_amortizacion
              where  am_operacion = @i_operacionca
              and    am_dividendo = @w_min_dividendo
              and    am_concepto  = @w_parametro_fng)

   begin
   
      if @w_min_dividendo =  @i_dividendo
      begin
          ---CUANDO LA CUOTA VENCIDA ES LA UNICA Y ES DE LA ANUALIDAD
          ---NO SE RECALCULA POR QUE ES EL MISMO SALDO
	      return 0
      end

     if @w_min_dividendo <> @i_dividendo
      begin
          ---CUANDO LA CUOTA VENCIDA ES <> A LA DE LA ANUALIDAD
          ---SE SUMA EL VALOR AL QUE EXISTE EN EL MOMENTO
          
	      update ca_amortizacion with (rowlock) set 
	      am_cuota     =  am_cuota + @w_valor_rubro,
	      am_acumulado =  am_cuota + @w_valor_rubro 
	      where  am_operacion = @i_operacionca
	      and    am_dividendo = @w_min_dividendo 
	      and    am_concepto  = @w_parametro_fng   --'COMFNGANU'
	      and    am_estado    <>  3
	   
	      if @@error <> 0  return 724401
      end
   end
   else
   begin
      /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION */
      insert into ca_amortizacion with (rowlock)  (
      am_operacion,    am_dividendo,     am_concepto,
      am_cuota,        am_gracia,        am_pagado,
      am_acumulado,    am_estado,        am_periodo,
      am_secuencia)
      values(
      @i_operacionca,  @w_min_dividendo, @w_parametro_fng,
      @w_valor_rubro,  0,                0,
      @w_valor_rubro,  @w_op_estado,     0,
      1 )
   
      if @@error <> 0  return 710001
   end
  
   --- ACTUALIZA EL VALOR DEL RUBRO COMFNGANU DEL DIVIDENDO ANUALIDAD
   --- POR QUE SI EL VENCIDO ES EL MISMO 12 0 24 etc.  actaulizara los valores que ya estan Ok
   ---PRINT 'recalcula_rubros.sp va a actualizar valor en pagado'  + CAST (@w_min_dividendo as varchar) + ' @i_dividendo:  ' + CAST (@i_dividendo as varchar)
   
   if @w_min_dividendo <> @i_dividendo
   begin
	   update ca_amortizacion set 
	   am_cuota     = am_pagado,
	   am_acumulado = am_pagado
	   where  am_operacion = @i_operacionca
	   and    am_dividendo = @i_dividendo 
	   and    am_concepto  = @i_concepto
	   and    am_cuota     > am_pagado

       if (@@error <> 0) return 724401	   -- ajmc
   end
   
   ----SEP132011-VALIDACION DE LA TRANSACCION DE LA COMISION

    update ca_transaccion_prv
    set tp_dividendo = @w_min_dividendo,
        tp_fecha_ref = @i_fecha_proceso
    where tp_operacion   = @i_operacionca
    and   tp_dividendo    = @i_dividendo
    and   tp_concepto     = @i_concepto
    and   tp_estado       <> 'RV'
	and   tp_monto         >= 0.01
	and   tp_secuencial_ref >= 0 

    if (@@error <> 0) return 155009      -- ajmc
   
    select @w_tp_monto = 0
    select @w_tp_monto = sum(tp_monto),
           @w_tp_estado = tp_estado
    from ca_transaccion_prv
    where tp_operacion   = @i_operacionca
    and   tp_dividendo    = @w_min_dividendo
    and   tp_concepto     = @i_concepto
    and   tp_estado       <> 'RV'
	and   tp_monto         >= 0.01
	and   tp_secuencial_ref >= 0  
	group by tp_estado


	if  @w_valor_rubro <> @w_tp_monto and @w_tp_monto > 0
	begin
		
	   if @w_valor_rubro > @w_tp_monto 
	   begin
		   ---CONTABILIZAR LA DIFERENCIA
		   select  @w_dif_fng = 0
		   select  @w_dif_fng = @w_valor_rubro - @w_tp_monto 
		   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
		   from   ca_concepto
		   where  co_concepto    = @w_parametro_fng
		
		   if @w_tp_estado = 'CON'
			   begin
			   insert into ca_transaccion_prv with (rowlock)
			     (
			     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
			     tp_secuencial_ref,   tp_estado,           tp_dividendo,
			     tp_concepto,         tp_codvalor,         tp_monto,
			     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
			     values
			     (
			     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
			     0,                   'ING',               @w_min_dividendo,
			     @w_parametro_fng,    @w_codvalor,         @w_dif_fng,
			     1,                   0,                   @w_oficina_op)      
			   end  
			   else
			   begin
		   	     ---PRINT '---Solo se actauliza el valor que despues va a contabilizar CIMISION Y EXISTIA EN ING SE SUMA LA DIFERENCIA: '+ cast (@w_dif_fng as varchar)
		         update ca_transaccion_prv 
		         set tp_monto = tp_monto + @w_dif_fng
			     where tp_operacion    = @i_operacionca
			     and   tp_dividendo    = @w_min_dividendo
			     and   tp_concepto     = @i_concepto
			     and   tp_estado       = 'ING'
				 and   tp_monto         >= 0.01
				 and   tp_secuencial_ref >= 0 			   

	             if (@@error <> 0) return 155009      -- ajmc				 
			   end
			   
	     end ----valor causado hoy es mayor

	   if @w_valor_rubro < @w_tp_monto 
	   begin
		   
	       if @w_tp_estado = 'CON'
	       begin
		       ---CONTABILIZAR LA DIFERENCIA
			   select  @w_dif_fng = 0
			   select  @w_dif_fng =  @w_tp_monto - @w_valor_rubro
			   
			   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
			   from   ca_concepto
			   where  co_concepto    = @w_parametro_fng
			   
			   insert into ca_transaccion_prv with (rowlock)
			     (
			     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
			     tp_secuencial_ref,   tp_estado,           tp_dividendo,
			     tp_concepto,         tp_codvalor,         tp_monto,
			     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
			     values
			     (
			     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
			     -999,                'ING',               @i_dividendo,
			     @w_parametro_fng,    @w_codvalor,         -@w_dif_fng,
			     1,                   0,                   @w_oficina_op)      
                 if (@@error <> 0) return 710001      -- ajmc				 
		     end ---CON
		     else
		     begin ----ING
		         ---Solo se actauliza el valor que despues va a contabilizar
		         update ca_transaccion_prv 
		         set tp_monto = @w_valor_rubro
			     where tp_operacion    = @i_operacionca
			     and   tp_dividendo    = @w_min_dividendo
			     and   tp_concepto     = @i_concepto
			     and   tp_estado       = 'ING'
				 and   tp_monto         >= 0.01
				 and   tp_secuencial_ref >= 0 

                 if (@@error <> 0) return 155009      -- ajmc				 
             end ---ING
	     end ----valor calculado hoy es menor que el que ya esta contabilizado o listo para contabilizar
	   
	end  ---VAlores Diferencte
	else
	begin
	   if  @w_tp_monto = 0
	   begin
		   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
		   from   ca_concepto
		   where  co_concepto    = @w_parametro_fng
		
		   insert into ca_transaccion_prv with (rowlock)
		     (
		     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
		     tp_secuencial_ref,   tp_estado,           tp_dividendo,
		     tp_concepto,         tp_codvalor,         tp_monto,
		     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
		     values
		     (
		     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
		     0,                   'ING',               @w_min_dividendo,
		     @w_parametro_fng,    @w_codvalor,         @w_valor_rubro,
		     1,                   0,             	   @w_oficina_op)      
	   
	   end
	end
   ----SEP132011-VALIDACION DE LA TRANSACCION DE LA COMISION

   
			   
   --- SI EL RUBRO COMFNGANU TIENE RUBRO ASOCIADO SE HACE EL MISMO PROCEDOS 
   if @w_asociado is not null and @w_asociado <> ''
   begin
      select @w_valor_asociado = round((@w_valor_rubro * @w_porcentaje / 100.0), @w_num_dec)
      if exists (select 1 
                 from   ca_amortizacion
                 where  am_operacion = @i_operacionca
                 and    am_dividendo = @w_min_dividendo
                 and    am_concepto  = @w_asociado)
      begin
	      if @w_min_dividendo =  @i_dividendo
	      begin
	          ---CUANDO LA CUOTA VENCIDA ES LA UNICA Y ES DE LA ANUALIDAD
	          ---NO SE RECALULA POR QUE ES EL MISMO SALDO   
              return 0
	      end

	      if @w_min_dividendo <>  @i_dividendo
	      begin
	          ---CUANDO LA CUOTA VENCIDA ES <> A  LA ANUALIDAD
	          ---SE SUMA AL VALOR EXISTENTE 
	         update ca_amortizacion with (rowlock) set 
	         am_cuota     =  am_cuota + @w_valor_asociado,
	         am_acumulado =  am_cuota + @w_valor_asociado 
	         where  am_operacion = @i_operacionca
	         and    am_dividendo = @w_min_dividendo 
	         and    am_concepto  = @w_asociado
	         and    am_estado    <> 3
	      
	         if @@error <> 0  return 724401
	      end
      end
      else
      begin
         /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION */
         insert into ca_amortizacion with (rowlock)  (
         am_operacion,    am_dividendo,     am_concepto,
         am_cuota,        am_gracia,        am_pagado,
         am_acumulado,    am_estado,        am_periodo,
         am_secuencia)
         values(
         @i_operacionca,     @w_min_dividendo, @w_asociado,
         @w_valor_asociado,  0,                0,
         @w_valor_asociado,  @w_op_estado,     0,
         1 )
      
         if @@error <> 0  return 710001
      end
	      
      if @w_min_dividendo <> @i_dividendo
      begin
      
	      update ca_amortizacion set 
	      am_cuota     = am_pagado,
	      am_acumulado = am_pagado
	      where  am_operacion = @i_operacionca
	      and    am_dividendo = @w_di_dividendo
	      and    am_concepto  = @w_asociado
	      and    am_cuota     > am_pagado
	
	      if (@@error <> 0) return 724401
      end

	    ----SEP132011-VALIDACION DE LA TRANSACCION DE IVA DE LA COMISION
        update ca_transaccion_prv
	    set tp_dividendo = @w_min_dividendo,
	        tp_fecha_ref   = @i_fecha_proceso
	    where tp_operacion   = @i_operacionca
	    and   tp_dividendo    = @i_dividendo
	    and   tp_concepto     = @w_asociado
	    and   tp_estado       <> 'RV'
		and   tp_monto         >= 0.01
		and   tp_secuencial_ref >= 0 	    

	    if (@@error <> 0) return 155009      -- ajmc
	    
	    select @w_tp_monto = 0
	    select @w_tp_monto = sum(tp_monto),
	           @w_tp_estado = tp_estado
	    from ca_transaccion_prv
	    where tp_operacion   = @i_operacionca
	    and   tp_dividendo    = @w_min_dividendo
	    and   tp_concepto     = @w_asociado
	    and   tp_estado       <> 'RV'
		and   tp_monto         >= 0.01
		and   tp_secuencial_ref >= 0  
        group by tp_estado

         ---print 'recalcula_rubros.sp 	@w_valor_asociado <> @w_tp_monto ' + cast (@w_valor_asociado as varchar ) +  ' @w_tp_monto	 : ' + cast(@w_tp_monto	 as varchar)
        
		if  @w_valor_asociado <> @w_tp_monto and @w_tp_monto > 0
		begin
			
		   if @w_valor_asociado > @w_tp_monto 
		   begin
			   ---CONTABILIZAR LA DIFERENCIA
			   
			   select  @w_dif_fng = 0
			   select  @w_dif_fng = @w_valor_asociado - @w_tp_monto 
			   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
			   from   ca_concepto
			   where  co_concepto    = @w_asociado
			
			   if @w_tp_estado = 'CON'	   
			   begin
			   ---print 'recalcula_rubros entro a  insertar  asociado @w_dif_fng ' + cast (@w_dif_fng as varchar)
				   insert into ca_transaccion_prv with (rowlock)
				     (
				     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
				     tp_secuencial_ref,   tp_estado,           tp_dividendo,
				     tp_concepto,         tp_codvalor,         tp_monto,
				     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
				     values
				     (
				     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
				     0,                   'ING',               @w_min_dividendo,
				     @w_asociado,         @w_codvalor,         @w_dif_fng,
				     1,                   0,                   @w_oficina_op)      
			     end
			     else
			     begin
			        ---print 'recalcula_rubros entro a  SUMAR YA EXISTIA REGISTRO ING @w_dif_fng ' + cast (@w_dif_fng as varchar)
			         update ca_transaccion_prv 
			         set tp_monto = tp_monto + @w_dif_fng
				     where tp_operacion    = @i_operacionca
				     and   tp_dividendo    = @w_min_dividendo
				     and   tp_concepto     = @w_asociado
				     and   tp_estado       = 'ING'
					 and   tp_monto         >= 0.01
					 and   tp_secuencial_ref >= 0 
			     
	                 if (@@error <> 0) return 155009      -- ajmc			     
			     end
		   end ----valor causado hoy es mayor
	
		  ---print 'recalcula_rubros validando @w_valor_asociado < @w_tp_monto  ' + cast (@w_valor_asociado as varchar) + '  @w_tp_monto ' + cast (@w_tp_monto as varchar)
		  
		  if @w_valor_asociado < @w_tp_monto 
		   begin
			   if @w_tp_estado = 'CON'
		       begin
				   ---CONTABILIZAR LA DIFERENCIA
				   select  @w_dif_fng = 0
				   select  @w_dif_fng =  @w_tp_monto - @w_valor_asociado
				   
				   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
				   from   ca_concepto
				   where  co_concepto    = @w_asociado
				
				   ---print 'recalcula_rubros entro a  insertar  CON  asociado @w_dif_fng ' + cast (@w_dif_fng as varchar)
				   
				   insert into ca_transaccion_prv with (rowlock)
				     (
				     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
				     tp_secuencial_ref,   tp_estado,           tp_dividendo,
				     tp_concepto,         tp_codvalor,         tp_monto,
				     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
				     values
				     (
				     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
				     -999,                'ING',               @i_dividendo,
				     @w_asociado,         @w_codvalor,         -@w_dif_fng,
				     1,                   0,                   @w_oficina_op)      
			   end ----COND
			   else
			   begin ---ING
		         ---Solo se actauliza el valor que despues va a contabilizar
		         ---print 'recalcula_rubros entro a  update ING   asociado @w_valor_asociado ' + cast (@w_valor_asociado as varchar)
		         update ca_transaccion_prv 
		         set tp_monto = @w_valor_asociado
			     where tp_operacion    = @i_operacionca
			     and   tp_dividendo    = @w_min_dividendo
			     and   tp_concepto     = @w_asociado
			     and   tp_estado       = 'ING'
				 and   tp_monto         >= 0.01
				 and   tp_secuencial_ref >= 0 
			   
	             if (@@error <> 0) return 155009      -- ajmc			   
			   end ---ING 
		   end --- VAlor asociado mayor	   
		   
		end  ---VAlores Diferencte
		else
		begin
		   if  @w_tp_monto = 0
		   begin
		   
		   ---print 'recalcula_rubros entro a  tp_monto  0   asociado @w_valor_asociado ' + cast (@w_valor_asociado as varchar)
			   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
			   from   ca_concepto
			   where  co_concepto    = @w_asociado
			
			   insert into ca_transaccion_prv with (rowlock)
			     (
			     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
			     tp_secuencial_ref,   tp_estado,           tp_dividendo,
			     tp_concepto,         tp_codvalor,         tp_monto,
			     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
			     values
			     (
			     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
			     0,                   'ING',               @w_min_dividendo,
			     @w_asociado,         @w_codvalor,         @w_valor_asociado,
			     1,                   0,             	   @w_oficina_op)      
		   
		   end
		end
	   ----SEP132011-VALIDACION DE LA TRANSACCION DE LA COMISION

   end --FIN RUBRO ASOCIADO COMFNGANU
	      
end --FIN ANUALIDAD ANUALIDAD COMFNGANU

--ANUALIDAD ANUALIDAD COMFAGANU
if (@i_concepto = @w_parametro_fag)  
begin

   --- GARANTIA TIPO FAG 
   select tc_tipo as tipo 
   into #calfag
   from cob_custodia..cu_tipo_custodia
   where tc_tipo_superior = @w_cod_gar_fag

    --GARANTIA DEL CREDITO Y TIPO DE GARANTIA (PREVIA-AUTOMATICA)
   select @w_porcentaje_resp = gp_porcentaje
   from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta, 
        cob_credito..cr_tramite
   where gp_tramite  = @w_tramite
         and gp_garantia = cu_codigo_externo 
         and cu_estado  in ('P','F','V','X','C')
         and tr_tramite  = gp_tramite
         and cu_tipo    in (select tipo from #calfag) 

   ---SI NO HAY CUOTAS VENCIDAS ANTES DE LA CUOTA DE LA ANUALIDAD
   ---NO SE RECALCULA AUN POR QUE NO HAY A DONE TRASLADARLA 
   if not exists (select 1 from ca_dividendo
                   where di_operacion = @i_operacionca
                    and di_dividendo < @i_dividendo
                    and di_estado    = @w_est_vencido)
   begin
      ---PRINT 'recalcula_rubros.sp entro y saldra por que no hay dividendo Vencido'
      return 0
   end                 
   
   --- RECALCULA SALDO DE CAPITAL PARA OBTENER NUEVO VALOR COMFAGANU EN LA SIGUIENTE ANUALIDAD 
   select @w_saldo_capital = isnull(sum(am_cuota + am_gracia - am_pagado),0)
   from   ca_amortizacion, ca_rubro_op
   where  am_operacion  = @i_operacionca
   and    ro_operacion  = am_operacion
   and    am_dividendo >= @i_dividendo + 1
   and    ro_concepto   = am_concepto 
   and    ro_tipo_rubro = 'C'

   select @w_saldo_capital =  isnull((@w_saldo_capital * @w_porcentaje_resp)/100,0)  
   
   --- DETERMINA SI EL CALCULO SE HACE SOBRE 12 MESES O SOBRE EL PLAZO RESTANTE INFERIOR A 12 MESES 
   --- OBTIENE DATOS DEL DIVIDENDO PARA CALCULAR PLAZO RESTANTE 
   select 
   @w_di_dividendo = di_dividendo,
   @w_di_fecha_ini = di_fecha_ini,
   @w_di_fecha_ven = di_fecha_ven,
   @w_di_estado    = di_estado
   from  ca_dividendo
   where di_operacion  = @i_operacionca
   and   di_dividendo  = @i_dividendo

   select @w_plazo_restante = datediff(mm,@w_di_fecha_ven,@w_fecha_fin)
   select @w_periodos_faltan = @w_plazo_restante / @w_periodos  ---PERIODOS REALES QUE FALTAN

   --VALIDA SI SE TRATA DEL ULTIMO PERIODO
   if @w_periodos_faltan <= @w_periodo_fag begin

      --SE OBTIENE EL PLAZO, TIPO PLAZO Y SU RESPCTIVO FACTOR EN DIAS
      select @w_plazo  = op_plazo,
             @w_factor = td_factor
      from cob_cartera..ca_operacion, cob_cartera..ca_tdividendo
      where op_tplazo = td_tdividendo
      and   op_operacion = @i_operacionca
     
      --SE CONVIERTE EN MESES EL PLAZO
      select @w_mes_oper = (@w_plazo * @w_factor)/30 
      
      --SE CALCULA LOS MESES REALES DEL CREDITO        
      select @w_fecha_fin_real = dateadd(mm,@w_mes_oper,@w_fecha_ini)

      --VALIDA SI LA FECHA DE VENCIMIENTO REAL ES UN DIA FESTIVO
      select @w_fecha_fin_habil = @w_fecha_fin_real,
               @w_es_habil = 'N',
               @w_dia_semana = 0

      --OBTIENE EL SIGUIENTE DIA HABIL DESPUES DE LA FECHA DE VENCIMIENTO DE LA OPERACION
      --SE VALIDA CONTRA EL CATALOGO DE DIAS FERIADOS DE FINAGRO
      while @w_es_habil = 'N'
      begin
         exec @w_error = sp_dia_habil 
         @i_fecha  = @w_fecha_fin_habil,
         @i_ciudad = @w_ciudad_nacional,
         @o_fecha  = @w_siguiente_dia out

         select @w_dia_semana = datepart(dw,@w_siguiente_dia) 

         if @w_dia_semana = 1
            select @w_dia_semana = 7
         else
            select @w_dia_semana = @w_dia_semana - 1

         if exists(select 1 from cobis..cl_tabla t,cobis..cl_catalogo c
                     where t.tabla = 'ca_dias_feriados_fag'
                     and   c.tabla = t.codigo
                     and   c.codigo = @w_dia_semana
                     and   c.estado = 'V')
            select @w_fecha_fin_habil = dateadd(dd,1,@w_siguiente_dia)
         else
            select @w_es_habil = 'S'

      end

                
      --SE VALIDA QUE LA CANTIDAD DE MESES DE LA OPERACION SEA DIFERENTES A LOS MESES REALES CALCULADOS 
      if @w_fecha_fin > @w_fecha_fin_real
      begin
         if @w_fecha_fin > @w_siguiente_dia
         begin
            --SE CALCULA LA COMISION POR EL PERIODO DE DESFASE
            select @w_plazo_restante = @w_plazo_restante + 1 
            select @w_reajuste_com   = 1
         end
      end
   end --FIN COMISION DE DESEMBOLSO  

   if (@w_periodos_faltan >= @w_freq_cobro and @w_reajuste_com = 0) or (@w_fecha_fin_real < @w_periodo_fag)
   begin
       ---print 'recalcula_rubros.sp 0 @w_plazo_restante ' + CAST (@w_plazo_restante as varchar) + ' - @w_freq_cobro - ' + CAST (@w_freq_cobro as varchar)
       select @w_valor_rubro = round((@w_saldo_capital * @w_factor_rubro / 100.0), @w_num_dec)
   end
   else
   begin
       ---print 'recalcula_rubros.sp  else  @w_periodos_faltan ' + CAST (@w_periodos_faltan as varchar) + ' - @w_periodo_fag - ' + CAST (@w_periodo_fag as varchar)
       select @w_valor_rubro = round((((@w_saldo_capital * @w_factor_rubro / 100.0) / @w_periodo_fag) * @w_plazo_restante), @w_num_dec)
   end

   -- EL VALOR DEL RUBRO COMFAGANU SE TRASLADA AL DIVIDENDO MAS VENCIDO
   select 
   @w_min_dividendo   =  min(di_dividendo)
   from ca_dividendo
   where di_operacion = @i_operacionca
   and   di_estado    = @w_est_vencido

   if @w_min_dividendo is null
   begin
      return 0
   end
   ---print 'recalcula_rubros.sp entroo @i_concepto:  ' + CAST (@i_concepto as varchar) + '@w_min_dividendo : '  +  CAST (@w_min_dividendo as varchar) +  '@w_valor_rubro : '  + CAST (@w_valor_rubro as varchar)
     
   if exists (select 1 
              from   ca_amortizacion
              where  am_operacion = @i_operacionca
              and    am_dividendo = @w_min_dividendo
              and    am_concepto  = @w_parametro_fag)

   begin
   
      if @w_min_dividendo =  @i_dividendo
      begin
          ---CUANDO LA CUOTA VENCIDA ES LA UNICA Y ES DE LA ANUALIDAD
          ---NO SE RECALCULA POR QUE ES EL MISMO SALDO
	      return 0
      end

     if @w_min_dividendo <> @i_dividendo
      begin
          ---CUANDO LA CUOTA VENCIDA ES <> A LA DE LA ANUALIDAD
          ---SE SUMA EL VALOR AL QUE EXISTE EN EL MOMENTO
          
	      update ca_amortizacion with (rowlock) set 
	      am_cuota     =  am_cuota + @w_valor_rubro,
	      am_acumulado =  am_cuota + @w_valor_rubro 
	      where  am_operacion = @i_operacionca
	      and    am_dividendo = @w_min_dividendo 
	      and    am_concepto  = @w_parametro_fag   --'COMFAGANU'
	      and    am_estado    <>  3
	   
	      if @@error <> 0  return 724401
      end
   end
   else
   begin
      /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION */
      insert into ca_amortizacion with (rowlock)  (
      am_operacion,    am_dividendo,     am_concepto,
      am_cuota,        am_gracia,        am_pagado,
      am_acumulado,    am_estado,        am_periodo,
      am_secuencia)
      values(
      @i_operacionca,  @w_min_dividendo, @w_parametro_fag,
      @w_valor_rubro,  0,                0,
      @w_valor_rubro,  @w_op_estado,     0,
      1 )
   
      if @@error <> 0  return 710001
   end
  
   --- ACTUALIZA EL VALOR DEL RUBRO COMFAGANU DEL DIVIDENDO ANUALIDAD
   --- POR QUE SI EL VENCIDO ES EL MISMO 12 0 24 etc.  actaulizara los valores que ya estan Ok
   ---PRINT 'recalcula_rubros.sp va a actualizar valor en pagado'  + CAST (@w_min_dividendo as varchar) + ' @i_dividendo:  ' + CAST (@i_dividendo as varchar)
   
   if @w_min_dividendo <> @i_dividendo
   begin
	   update ca_amortizacion set 
	   am_cuota     = am_pagado,
	   am_acumulado = am_pagado
	   where  am_operacion = @i_operacionca
	   and    am_dividendo = @i_dividendo 
	   and    am_concepto  = @i_concepto
	   and    am_cuota     > am_pagado
	   
	   if (@@error <> 0) return 724401      -- ajmc	   
   end
   
   ----SEP132011-VALIDACION DE LA TRANSACCION DE LA COMISION

    update ca_transaccion_prv
    set tp_dividendo = @w_min_dividendo,
        tp_fecha_ref = @i_fecha_proceso
    where tp_operacion   = @i_operacionca
    and   tp_dividendo    = @i_dividendo
    and   tp_concepto     = @i_concepto
    and   tp_estado       <> 'RV'
	and   tp_monto         >= 0.01
	and   tp_secuencial_ref >= 0 

    if (@@error <> 0) return 155009      -- ajmc   
    
    select @w_tp_monto = 0
    select @w_tp_monto = sum(tp_monto),
           @w_tp_estado = tp_estado
    from ca_transaccion_prv
    where tp_operacion   = @i_operacionca
    and   tp_dividendo    = @w_min_dividendo
    and   tp_concepto     = @i_concepto
    and   tp_estado       <> 'RV'
	and   tp_monto         >= 0.01
	and   tp_secuencial_ref >= 0  
	group by tp_estado


	if  @w_valor_rubro <> @w_tp_monto and @w_tp_monto > 0
	begin
		
	   if @w_valor_rubro > @w_tp_monto 
	   begin
		   ---CONTABILIZAR LA DIFERENCIA
		   select  @w_dif_fag = 0
		   select  @w_dif_fag = @w_valor_rubro - @w_tp_monto 
		   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
		   from   ca_concepto
		   where  co_concepto    = @w_parametro_fag
		
		   if @w_tp_estado = 'CON'
			   begin
			   insert into ca_transaccion_prv with (rowlock)
			     (
			     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
			     tp_secuencial_ref,   tp_estado,           tp_dividendo,
			     tp_concepto,         tp_codvalor,         tp_monto,
			     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
			     values
			     (
			     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
			     0,                   'ING',               @w_min_dividendo,
			     @w_parametro_fag,    @w_codvalor,         @w_dif_fag,
			     1,                   0,                   @w_oficina_op)      
			   end  
			   else
			   begin
		   	     ---PRINT '---Solo se actauliza el valor que despues va a contabilizar CIMISION Y EXISTIA EN ING SE SUMA LA DIFERENCIA: '+ cast (@w_dif_fag as varchar)
		         update ca_transaccion_prv 
		         set tp_monto = tp_monto + @w_dif_fag
			     where tp_operacion    = @i_operacionca
			     and   tp_dividendo    = @w_min_dividendo
			     and   tp_concepto     = @i_concepto
			     and   tp_estado       = 'ING'
				 and   tp_monto         >= 0.01
				 and   tp_secuencial_ref >= 0 			   

	             if (@@error <> 0) return 155009      -- ajmc				 
			   end
			   
	     end ----valor causado hoy es mayor

	   if @w_valor_rubro < @w_tp_monto 
	   begin
		   
	       if @w_tp_estado = 'CON'
	       begin
		       ---CONTABILIZAR LA DIFERENCIA
			   select  @w_dif_fag = 0
			   select  @w_dif_fag =  @w_tp_monto - @w_valor_rubro
			   
			   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
			   from   ca_concepto
			   where  co_concepto    = @w_parametro_fag
			   
			   insert into ca_transaccion_prv with (rowlock)
			     (
			     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
			     tp_secuencial_ref,   tp_estado,           tp_dividendo,
			     tp_concepto,         tp_codvalor,         tp_monto,
			     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
			     values
			     (
			     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
			     -999,                'ING',               @i_dividendo,
			     @w_parametro_fag,    @w_codvalor,         -@w_dif_fag,
			     1,                   0,                   @w_oficina_op)      
		     end ---CON
		     else
		     begin ----ING
		         ---Solo se actauliza el valor que despues va a contabilizar
		         update ca_transaccion_prv 
		         set tp_monto = @w_valor_rubro
			     where tp_operacion    = @i_operacionca
			     and   tp_dividendo    = @w_min_dividendo
			     and   tp_concepto     = @i_concepto
			     and   tp_estado       = 'ING'
				 and   tp_monto         >= 0.01
				 and   tp_secuencial_ref >= 0 
				 
	             if (@@error <> 0) return 155009      -- ajmc				 
             end ---ING
	     end ----valor calculado hoy es menor que el que ya esta contabilizado o listo para contabilizar
	   
	end  ---Valores Diferentes
	else
	begin
	   if  @w_tp_monto = 0
	   begin
		   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
		   from   ca_concepto
		   where  co_concepto    = @w_parametro_fag
		
		   insert into ca_transaccion_prv with (rowlock)
		     (
		     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
		     tp_secuencial_ref,   tp_estado,           tp_dividendo,
		     tp_concepto,         tp_codvalor,         tp_monto,
		     tp_secuencia,        tp_comprobante,	   tp_ofi_oper)
		     values
		     (
		     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
		     0,                   'ING',               @w_min_dividendo,
		     @w_parametro_fag,    @w_codvalor,         @w_valor_rubro,
		     1,                   0,             	   @w_oficina_op)
	   
	   end
	end
   ----SEP132011-VALIDACION DE LA TRANSACCION DE LA COMISION

   
			   
   --- SI EL RUBRO COMFAGANU TIENE RUBRO ASOCIADO SE HACE EL MISMO PROCEDOS 
   if @w_asociado is not null and @w_asociado <> ''
   begin
      select @w_valor_asociado = round((@w_valor_rubro * @w_porcentaje / 100.0), @w_num_dec)
      if exists (select 1 
                 from   ca_amortizacion
                 where  am_operacion = @i_operacionca
                 and    am_dividendo = @w_min_dividendo
                 and    am_concepto  = @w_asociado)
      begin
	      if @w_min_dividendo =  @i_dividendo
	      begin
	          ---CUANDO LA CUOTA VENCIDA ES LA UNICA Y ES DE LA ANUALIDAD
	          ---NO SE RECALULA POR QUE ES EL MISMO SALDO   
              return 0
	      end

	      if @w_min_dividendo <>  @i_dividendo
	      begin
	          ---CUANDO LA CUOTA VENCIDA ES <> A  LA ANUALIDAD
	          ---SE SUMA AL VALOR EXISTENTE 
	         update ca_amortizacion with (rowlock) set 
	         am_cuota     =  am_cuota + @w_valor_asociado,
	         am_acumulado =  am_cuota + @w_valor_asociado 
	         where  am_operacion = @i_operacionca
	         and    am_dividendo = @w_min_dividendo 
	         and    am_concepto  = @w_asociado
	         and    am_estado    <> 3
	      
	         if @@error <> 0  return 724401
	      end
      end
      else
      begin
         /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION */
         insert into ca_amortizacion with (rowlock)  (
         am_operacion,    am_dividendo,     am_concepto,
         am_cuota,        am_gracia,        am_pagado,
         am_acumulado,    am_estado,        am_periodo,
         am_secuencia)
         values(
         @i_operacionca,     @w_min_dividendo, @w_asociado,
         @w_valor_asociado,  0,                0,
         @w_valor_asociado,  @w_op_estado,     0,
         1 )
      
         if @@error <> 0  return 710001
      end
	      
      if @w_min_dividendo <> @i_dividendo
      begin
      
	      update ca_amortizacion set 
	      am_cuota     = am_pagado,
	      am_acumulado = am_pagado
	      where  am_operacion = @i_operacionca
	      and    am_dividendo = @w_di_dividendo
	      and    am_concepto  = @w_asociado
	      and    am_cuota     > am_pagado
	
	      if (@@error <> 0) return 724401
      end

	    ----SEP132011-VALIDACION DE LA TRANSACCION DE IVA DE LA COMISION
        update ca_transaccion_prv
	    set tp_dividendo = @w_min_dividendo,
	        tp_fecha_ref   = @i_fecha_proceso
	    where tp_operacion   = @i_operacionca
	    and   tp_dividendo    = @i_dividendo
	    and   tp_concepto     = @w_asociado
	    and   tp_estado       <> 'RV'
		and   tp_monto         >= 0.01
		and   tp_secuencial_ref >= 0 	    

	    if (@@error <> 0) return 710001      -- ajmc	    
	    
	    select @w_tp_monto = 0
	    select @w_tp_monto = sum(tp_monto),
	           @w_tp_estado = tp_estado
	    from ca_transaccion_prv
	    where tp_operacion   = @i_operacionca
	    and   tp_dividendo    = @w_min_dividendo
	    and   tp_concepto     = @w_asociado
	    and   tp_estado       <> 'RV'
		and   tp_monto         >= 0.01
		and   tp_secuencial_ref >= 0  
        group by tp_estado

         ---print 'recalcula_rubros.sp 	@w_valor_asociado <> @w_tp_monto ' + cast (@w_valor_asociado as varchar ) +  ' @w_tp_monto	 : ' + cast(@w_tp_monto	 as varchar)
        
		if  @w_valor_asociado <> @w_tp_monto and @w_tp_monto > 0
		begin
			
		   if @w_valor_asociado > @w_tp_monto 
		   begin
			   ---CONTABILIZAR LA DIFERENCIA
			   
			   select  @w_dif_fag = 0
			   select  @w_dif_fag = @w_valor_asociado - @w_tp_monto 
			   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
			   from   ca_concepto
			   where  co_concepto    = @w_asociado
			
			   if @w_tp_estado = 'CON'	   
			   begin
			   ---print 'recalcula_rubros entro a  insertar  asociado @w_dif_fag ' + cast (@w_dif_fag as varchar)
				   insert into ca_transaccion_prv with (rowlock)
				     (
				     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
				     tp_secuencial_ref,   tp_estado,           tp_dividendo,
				     tp_concepto,         tp_codvalor,         tp_monto,
				     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
				     values
				     (
				     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
				     0,                   'ING',               @w_min_dividendo,
				     @w_asociado,         @w_codvalor,         @w_dif_fag,
				     1,                   0,                   @w_oficina_op)      
			     end
			     else
			     begin
			        ---print 'recalcula_rubros entro a  SUMAR YA EXISTIA REGISTRO ING @w_dif_fag ' + cast (@w_dif_fag as varchar)
			         update ca_transaccion_prv 
			         set tp_monto = tp_monto + @w_dif_fag
				     where tp_operacion    = @i_operacionca
				     and   tp_dividendo    = @w_min_dividendo
				     and   tp_concepto     = @w_asociado
				     and   tp_estado       = 'ING'
					 and   tp_monto         >= 0.01
					 and   tp_secuencial_ref >= 0 

	                 if (@@error <> 0) return 710001      -- ajmc			     
			     end
		   end ----valor causado hoy es mayor
	
		  ---print 'recalcula_rubros validando @w_valor_asociado < @w_tp_monto  ' + cast (@w_valor_asociado as varchar) + '  @w_tp_monto ' + cast (@w_tp_monto as varchar)
		  
		  if @w_valor_asociado < @w_tp_monto 
		   begin
			   if @w_tp_estado = 'CON'
		       begin
				   ---CONTABILIZAR LA DIFERENCIA
				   select  @w_dif_fag = 0
				   select  @w_dif_fag =  @w_tp_monto - @w_valor_asociado
				   
				   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
				   from   ca_concepto
				   where  co_concepto    = @w_asociado
				
				   ---print 'recalcula_rubros entro a  insertar  CON  asociado @w_dif_fag ' + cast (@w_dif_fag as varchar)
				   
				   insert into ca_transaccion_prv with (rowlock)
				     (
				     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
				     tp_secuencial_ref,   tp_estado,           tp_dividendo,
				     tp_concepto,         tp_codvalor,         tp_monto,
				     tp_secuencia,        tp_comprobante,      tp_ofi_oper)
				     values
				     (
				     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
				     -999,                'ING',               @i_dividendo,
				     @w_asociado,         @w_codvalor,         -@w_dif_fag,
				     1,                   0,                   @w_oficina_op)
			   end ----COND
			   else
			   begin ---ING
		         ---Solo se actauliza el valor que despues va a contabilizar
		         ---print 'recalcula_rubros entro a  update ING   asociado @w_valor_asociado ' + cast (@w_valor_asociado as varchar)
		         update ca_transaccion_prv 
		         set tp_monto = @w_valor_asociado
			     where tp_operacion    = @i_operacionca
			     and   tp_dividendo    = @w_min_dividendo
			     and   tp_concepto     = @w_asociado
			     and   tp_estado       = 'ING'
				 and   tp_monto         >= 0.01
				 and   tp_secuencial_ref >= 0 

	             if (@@error <> 0) return 710001      -- ajmc			   
			   end ---ING 
		   end --- VAlor asociado mayor	   
		   
		end  ---VAlores Diferencte
		else
		begin
		   if  @w_tp_monto = 0
		   begin
		   
		   ---print 'recalcula_rubros entro a  tp_monto  0   asociado @w_valor_asociado ' + cast (@w_valor_asociado as varchar)
			   select @w_codvalor = co_codigo * 1000 + @w_op_estado * 10 + 0
			   from   ca_concepto
			   where  co_concepto    = @w_asociado
			
			   insert into ca_transaccion_prv with (rowlock)
			     (
			     tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
			     tp_secuencial_ref,   tp_estado,           tp_dividendo,
			     tp_concepto,         tp_codvalor,         tp_monto,
			     tp_secuencia,        tp_comprobante,	   tp_ofi_oper)
			     values
			     (
			     @w_fecha_hoy,        @i_operacionca,      @i_fecha_proceso,
			     0,                   'ING',               @w_min_dividendo,
			     @w_asociado,         @w_codvalor,         @w_valor_asociado,
			     1,                   0,             	   @w_oficina_op)
		   
		   end
		end
	   ----SEP132011-VALIDACION DE LA TRANSACCION DE LA COMISION

   end --FIN RUBRO ASOCIADO COMFAGANU
	      
end --FIN ANUALIDAD ANUALIDAD COMFAGANU

return 0
go


