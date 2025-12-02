/************************************************************************/
/*      Archivo:                calfng.sp                               */
/*      Stored procedure:       sp_calculo_fng                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Marzo 2008                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calculo de comision Fondo Nacional de Garantias en anualidad    */
/*                              CAMBIOS                                 */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*  07/Ene/2011      Johan Ardila       Req 197 - USAID, FAG, FNG       */
/*                                      Se modifica frecuencia de cobro */
/*                                      teniendo en cuenta periodicidad */
/*                                      de amortizacion                 */
/*  16/03/2012       Luis Moreno        REQ 293 - No recalcular comision*/
/*                                      FNG a las cuotas pendientes     */
/*                                      cuando la obligacion tiene      */
/*                                      reconocimiento                  */
/*  28/06/2011       Acelis             Req 272 - USAID, FAG, FNG       */
/*                                      Ajustar Tabla de Amortizac. de  */
/*                                      acuerdo a matriz COMFNGAUT      */
/*  03/02/2020       Luis Ponce         Ajustes Migracion Core Digital  */
/************************************************************************/
use cob_cartera
go

set ansi_warnings off
go

if object_id ('sp_calculo_fng') is not null
begin
   drop proc sp_calculo_fng
end
go
---INC.110395 ABR.16.2013
create proc sp_calculo_fng
@i_operacion      int,
@i_desde_abnextra char(1)  = 'N',
@i_cuota_abnextra smallint = null,
@i_parametro_fng  varchar(10) = null,
@i_parametro_fngd varchar(10) = null,
@i_parametro_fng_iva varchar(10) = null

as
declare
@w_sp_name              varchar(30),
@w_return               int,
@w_est_vigente          tinyint,
@w_est_vencido          tinyint,
@w_est_cancelado        tinyint,
@w_est_novigente        tinyint,
@w_est_credito          tinyint,
@w_num_dec              smallint,
@w_moneda               smallint,
@w_op_monto             money,
@w_di_dividendo         int,
@w_di_fecha_ini         datetime,
@w_di_fecha_ven         datetime,
@w_di_estado            int,
@w_valor                money,
@w_valor_no_vig         money,
@w_factor               float,
@w_asociado             catalogo,
@w_porcentaje           float,
@w_valor_asociado       money,
@w_plazo_restante       int,
@w_fecha_fin            datetime,
@w_tramite              int,
@w_periodo_fng          tinyint,    -- JAR REQ 197
@w_cod_gar_fng          catalogo,
@w_parametro_fng        catalogo,
@w_parametro_fng_tmp    catalogo,
@w_parametro_iva_fng    catalogo,
@w_SMV                  money,
@w_monto_parametro      float,
@w_fecha_ult_proceso    datetime,
@w_error                int,
@w_msg                  descripcion,
@w_parametro_fngd       catalogo,
@w_tdividendo           catalogo,      -- JAR REQ 197
@w_freq_cobro           int,           -- JAR REQ 197
@w_estado_op            int,
@w_max_div_reest        int,
@w_max_div_delete       int,
@w_capitalizado         money,         -- REQ 175: PEQUEÑA EMPRESA
@w_gracia_int           smallint,      -- REQ 175: PEQUEÑA EMPRESA
@w_dist_gracia          char(1),       -- REQ 175: PEQUEÑA EMPRESA
@w_saldo_cap            money,         -- REQ 175: PEQUEÑA EMPRESA
@w_div_despl            smallint,      -- REQ 175: PEQUEÑA EMPRESA
@w_periodo_int          smallint,      -- REQ 175: PEQUEÑA EMPRESA
@w_estado               char(1),       -- REQ 293: RECONOCIMIENTO FNG Y USAID
@w_tipo                 varchar(64),
@w_matriz               catalogo,
@w_seguros              char(1)

/** INICIALIZACION VARIABLES **/
select 
@w_sp_name        = 'sp_calculo_fng',
@w_valor          = 0,
@w_porcentaje     = 0,
@w_valor_asociado = 0,
@w_asociado       = '',
@w_plazo_restante = 0,
@w_seguros        = 'N'

-- INI JAR REQ 197 

/* ESTADOS DE CARTERA */
exec @w_error     = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out

/* PARAMETRO PERIODICIDAD COBRO FNG */
select @w_periodo_fng = pa_tinyint
  from cobis..cl_parametro 
 where pa_nemonico = 'PERFNG'
   and pa_producto = 'CCA'

if @@rowcount = 0 return 721312
-- FIN JAR REQ 197 
 
/*CODIGO PADRE GARANTIA DE FNG*/
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'

if @@rowcount = 0 return 721314

if @i_parametro_fng is null and @i_parametro_fngd is null and @i_parametro_fng_iva is null begin

   /*PARAMETRO DE LA GARANTIA DE FNG*/
   select @w_parametro_fng = pa_char
   from   cobis..cl_parametro with (nolock)
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'COMFNG'

   if @@rowcount = 0 return 721315

   select @w_parametro_iva_fng = pa_char
   from   cobis..cl_parametro with (nolock)
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'IVAFNG'

   if @@rowcount = 0 return 721316
   
   /*PARAMETRO DE LA GARANTIA DE FNGD*/
   select @w_parametro_fngd = pa_char
   from cobis..cl_parametro 
   where pa_nemonico = 'COFNGD'
   and   pa_producto = 'CCA'

   if @@rowcount = 0 return 721313

end
else begin
   select @w_parametro_fng     = @i_parametro_fng,
          @w_parametro_fngd    = @i_parametro_fngd,
          @w_parametro_iva_fng = @i_parametro_fng_iva
end

/*PARAMETRO SALARIO MINIMO VITAL VIGENTE*/
select @w_SMV      = pa_money 
from   cobis..cl_parametro with (nolock)
where  pa_producto  = 'ADM'
and    pa_nemonico  = 'SMV'

if @@rowcount = 0 return 721317

/** DATOS OPERACION **/
select 
@w_fecha_fin         = opt_fecha_fin,
@w_op_monto          = opt_monto,
@w_moneda            = opt_moneda,
@w_tramite           = opt_tramite,
@w_fecha_ult_proceso = opt_fecha_ult_proceso,
@w_tdividendo        = opt_tdividendo,          -- JAR REQ 197
@w_estado_op         = opt_estado,
@w_gracia_int        = opt_gracia_int,          -- REQ 175: PEQUEÑA EMPRESA
@w_dist_gracia       = opt_dist_gracia,         -- REQ 175: PEQUEÑA EMPRESA
@w_periodo_int       = opt_periodo_int          -- REQ 175: PEQUEÑA EMPRESA
from   ca_operacion_tmp
where  opt_operacion    = @i_operacion

if exists (select 1 from cob_credito..cr_seguros_tramite
           where st_tramite = @w_tramite)
           and @w_estado_op in (@w_est_novigente, @w_est_credito)
begin
   select @w_seguros = 'S'
   select @w_op_monto = tr_monto   -- Otra forma de obtener el monto sin seguros es tomar el @i_monto y restarle el valor total 
   from cob_credito..cr_tramite with (nolock) -- de los seguros, valor que se obtiene con el select que se realiza en la operacion C
   where tr_tramite = @w_tramite              -- del SP cob_credito..sp_seguros_tramite.               	
   
end  -- Fin Generar monto base de la operación Req. 366

-- INI - REQ 175: PEQUEÑA EMPRESA - CALCULAR EL MONTO CAPITALIZADO
select @w_capitalizado = isnull(sum(ro_base_calculo), 0)
from   ca_rubro_op
where  ro_operacion  = @i_operacion
and    ro_tipo_rubro = 'C'

if @i_desde_abnextra = 'S' and @w_gracia_int > 0 
begin
   if @w_gracia_int - @i_cuota_abnextra + 1 > 0
      select @w_gracia_int = @w_gracia_int - @i_cuota_abnextra + 1
   else 
      select @w_gracia_int = 0
end
-- FIN - REQ 175: PEQUEÑA EMPRESA - CALCULAR EL MONTO CAPITALIZADO

-- INI JAR REQ 197
/* FRECUENCIA DE COBRO DEPENDIENDO DEL TIPO DE DIVIDENDO */
select @w_freq_cobro = @w_periodo_int * td_factor / 30
  from ca_tdividendo
 where td_tdividendo = @w_tdividendo
 
select @w_freq_cobro = @w_periodo_fng / @w_freq_cobro
-- FIN JAR REQ 197

select tc_tipo as tipo into #calfng
from cob_custodia..cu_tipo_custodia
where  tc_tipo_superior  = @w_cod_gar_fng

select @w_estado = cu_estado,
	   @w_tipo = cu_tipo
from cob_custodia..cu_custodia, 
cob_credito..cr_gar_propuesta, 
cob_credito..cr_tramite
where gp_tramite  = @w_tramite
and gp_garantia = cu_codigo_externo 
and cu_estado   in ('P','F','V','X','C')
and tr_tramite  = gp_tramite
and cu_tipo in (select tipo from #calfng)

if @@rowcount = 0
begin   

   update ca_amortizacion_tmp with (rowlock) set 
   amt_cuota     = case when amt_pagado > 0 then amt_pagado else 0 end,
   amt_acumulado = case when amt_pagado > 0 then amt_pagado else 0 end,
   amt_gracia    = 0                                           -- 02/FEB/2011 - REQ 175: PEQUEÑA EMPRESA
   where  amt_operacion = @i_operacion
   and    amt_concepto  in (@w_parametro_fng,@w_parametro_iva_fng)
   if @@error <> 0
      return 724401
   else begin
      return 0
   end
end

select @w_matriz = codigo_sib
from cob_credito..cr_corresp_sib
where tabla = 'T130'
and codigo  = @w_tipo
if @@rowcount <> 0
	select @w_parametro_fng_tmp = @w_matriz 
else 
	select @w_parametro_fng_tmp = @w_parametro_fng

 
/* OBTENER LA FECHA DE VENCIMIENTO FINAL DESDE ca_dividendo_tmp, POR QUE EN ca_operacion_tmp AUN NO SE TIENE */
select @w_fecha_fin = max(dit_fecha_ven)
from  ca_dividendo_tmp
where dit_operacion = @i_operacion
      
/* NUMERO DE DECIMALES */
exec @w_return = sp_decimales
@i_moneda      = @w_moneda,
@o_decimales   = @w_num_dec out
if @w_return <> 0 return  @w_return


if @w_estado_op in (@w_est_novigente, @w_est_credito) begin -- Si la operacion es nueva consulta la Matriz

   /*CALCULO DE LA TASA */
      exec  cob_cartera..sp_retona_valor_en_smlv
	   @i_matriz         = @w_parametro_fng_tmp,
	   @i_monto          = @w_op_monto,
	   @i_smv            = @w_SMV,
	   @o_MontoEnSMLV    = @w_monto_parametro out

  	   if @w_monto_parametro  = -1
           select @w_monto_parametro = @w_op_monto / @w_SMV
		    
	 select @w_factor = 0  
     if @w_monto_parametro > 0
     begin     
	   exec @w_error  = sp_matriz_valor
	   @i_matriz      = @w_parametro_fng_tmp,      
	   @i_fecha_vig   = @w_fecha_ult_proceso,  
	   @i_eje1        = @w_monto_parametro,  
	   @o_valor       = @w_factor out, 
	   @o_msg         = @w_msg    out    
	         
	   if @w_error <> 0  return @w_error
	 end
   
   update ca_rubro_op set   
   ro_porcentaje      = @w_factor,
   ro_porcentaje_aux  = @w_factor,
   ro_base_calculo    = @w_op_monto
   where ro_operacion = @i_operacion
   and   ro_concepto  = @w_parametro_fng
   if @@error <> 0
      return 721318
   
   update ca_rubro_op_tmp set   
   rot_porcentaje      = @w_factor,
   rot_porcentaje_aux  = @w_factor,
   rot_base_calculo    = @w_op_monto
   where rot_operacion = @i_operacion
   and   rot_concepto  = @w_parametro_fng
   if @@error <> 0
      return 721319

   update ca_rubro_op set
   ro_porcentaje      = @w_factor,
   ro_porcentaje_aux  = @w_factor 
   where ro_operacion = @i_operacion
   and   ro_concepto  = @w_parametro_fngd
   if @@error <> 0
      return 721320

   update ca_rubro_op_tmp set
   rot_porcentaje      = @w_factor,
   rot_porcentaje_aux  = @w_factor
   where rot_operacion = @i_operacion
   and   rot_concepto  = @w_parametro_fngd
   if @@error <> 0
      return 721321
end
else begin
   select
   @w_max_div_reest  = max(di_dividendo),
   @w_max_div_delete = max(di_dividendo)
   from ca_dividendo
   where di_operacion = @i_operacion
   and   di_estado in (@w_est_vigente, @w_est_vencido) 

   select @w_factor = rot_porcentaje
   from ca_rubro_op_tmp 
   where rot_operacion = @i_operacion
   and   rot_concepto  = @w_parametro_fng

   if @@rowcount = 0
      return 721322
end

/* VERIFICAR SI EL RUBRO COMFNGANU TIENE RUBRO ASOCIADO */
if exists (
   select 1
   from   ca_rubro_op_tmp
   where  rot_operacion         = @i_operacion
   and    rot_concepto_asociado = @w_parametro_fng)
begin
   select 
   @w_asociado   = rot_concepto,
   @w_porcentaje = rot_porcentaje
   from   ca_rubro_op_tmp
   where  rot_operacion         = @i_operacion
   and    rot_concepto_asociado = @w_parametro_fng
end

/* VERIFICA SI VIENE DE ABONO EXTRAORDINARIO */
if @i_desde_abnextra = 'S'
   select @w_div_despl = @i_cuota_abnextra - 1                                -- REQ 175: PEQUEÑA EMPRESA
else
   select @w_div_despl = 0   
   

-- SI LA OPERACION TIENE COBRO EN CUOTA IMPAR (1/13/25 - PERIODICAD MENSUAL) SE DEBE RESPETAR LA CUOTA DE COBRO
if exists(
select 1 from ca_amortizacion 
where am_operacion       = @i_operacion 
and   (am_dividendo - 1) % @w_freq_cobro = 0
and   am_concepto       in (@w_parametro_fng, @w_parametro_iva_fng)
and   am_cuota           > 0                                       )
   select @w_div_despl = @w_div_despl - 1

/** CURSOR DE DIVIDENDOS **/
declare cursor_dividendos_1 cursor for 
select 
dit_dividendo,          dit_fecha_ini,       dit_fecha_ven,
dit_estado
from  ca_dividendo_tmp
where dit_operacion = @i_operacion
order by dit_dividendo
for read only

open    cursor_dividendos_1
fetch   cursor_dividendos_1
into    
@w_di_dividendo,        @w_di_fecha_ini,     @w_di_fecha_ven,
@w_di_estado

/* WHILE CURSOR PRINCIPAL */
while @@fetch_status = 0 begin

   if (@@fetch_status = -1) return 708999

   select @w_valor = 0

   /* DETERMINAR CAMBIO DE AÑO */
   if ((@w_di_dividendo + @w_div_despl ) % @w_freq_cobro) = 0  --LPO Ajustes Migracion Core Digital -- REQ 175: PEQUEÑA EMPRESA
   begin
      /* RECALCULAR VALOR DE COMFNGANU SOBRE EL SALDO DE CAPITAL*/
      select @w_saldo_cap = sum(amt_cuota - amt_pagado)
      from   ca_amortizacion_tmp, ca_rubro_op_tmp
      where  amt_operacion  = @i_operacion
      and    rot_operacion  = amt_operacion
      and    amt_dividendo >= @w_di_dividendo + 1
      and    rot_concepto   = amt_concepto 
      and    rot_tipo_rubro = 'C'
            
      -- REQ 175: PEQUEÑA EMPRESA
      if @w_dist_gracia = 'C' and @w_di_dividendo <= @w_gracia_int
         select @w_saldo_cap = @w_saldo_cap - isnull(@w_capitalizado, 0)

      /* DETERMINA SI EL CALCULO SE HACE PERIODICAMENTE (@w_periodo_fng en Meses) O */
      /* SOBRE EL PLAZO RESTANTE INFERIOR A (@w_periodo_fng en Meses) */
      select @w_plazo_restante = datediff(mm, @w_di_fecha_ven, @w_fecha_fin) * @w_freq_cobro / @w_periodo_fng 
          
      if @w_plazo_restante >= @w_freq_cobro begin -- JAR REQ 197 
         --print 'calfng.sp Valor: ' + 'DIV: ' + cast(@w_di_dividendo as varchar) + 'SALDO: ' + cast(@w_saldo_cap as varchar) + 'FACTOR: ' + cast(@w_factor as varchar) + '@w_num_dec: ' + cast(@w_num_dec as varchar)
         select @w_valor = round((@w_saldo_cap * @w_factor / 100.0), @w_num_dec)
      end 
      else begin
         --print 'calfng.sp Valor 2: ' + 'DIV: ' + cast(@w_di_dividendo as varchar) + 'SALDO: ' + cast(@w_saldo_cap as varchar) + 'FACTOR: ' + cast(@w_factor as varchar) + '@w_plazo_restante: ' + cast(@w_freq_cobro as varchar) + '@w_plazo_restante: ' + cast(@w_freq_cobro as varchar)           
         select @w_valor = round((((@w_saldo_cap * @w_factor / 100.0) / @w_freq_cobro) * @w_plazo_restante), @w_num_dec)
      end
      
      
      
   end
   else begin /*ASIGNACION DEL VALOR DE LA COMISION A CERO POR QUE NO ES ANUALIDAD*/
      if @i_desde_abnextra = 'S' begin
          select @i_desde_abnextra = 'N'
      end
      select @w_valor = 0
   end
   
   /* SI EL DIVIDENDO ESTA VIGENTE O NO VIGENTE */
   if @w_di_estado in (@w_est_vigente,@w_est_novigente) and @w_valor > 0 and @w_estado <> 'X' and @w_estado <> 'C'  begin
    
      if @w_di_estado = @w_est_vigente
         select @w_valor_no_vig = @w_valor
      else
         select @w_valor_no_vig = 0
         
      /* CALCULAR RUBRO COMFNGANU */
      if exists (
         select 1 
         from   ca_amortizacion_tmp
         where  amt_operacion = @i_operacion
         and    amt_dividendo = @w_di_dividendo
         and    amt_concepto  = @w_parametro_fng)
      begin
         update ca_amortizacion_tmp with (rowlock) set 
         amt_cuota     = @w_valor,
         amt_acumulado = @w_valor_no_vig,
         amt_gracia    = 0                                       -- 02/FEB/2011 - REQ 175: PEQUEÑA EMPRESA
         where  amt_operacion = @i_operacion
         and    amt_dividendo = @w_di_dividendo 
         and    amt_concepto  = @w_parametro_fng               -- JAR REQ 197

         if (@@error <> 0) begin
             close cursor_dividendos_1
             deallocate cursor_dividendos_1
             return 710001
         end         
      end
      else begin
         /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP */
         insert into ca_amortizacion_tmp with (rowlock)(
         amt_operacion,   amt_dividendo,   amt_concepto,
         amt_cuota,       amt_gracia,      amt_pagado,
         amt_acumulado,   amt_estado,      amt_periodo,
         amt_secuencia)
         values(
         @i_operacion,    @w_di_dividendo, @w_parametro_fng,
         @w_valor,        0,               0,
         @w_valor_no_vig, @w_di_estado,    0,
         1 )
      
         if (@@error <> 0) begin
             close cursor_dividendos_1
             deallocate cursor_dividendos_1
             return 710001
         end
      end
      
        /* SI EL RUBRO COMFNGANU TIENE RUBRO ASOCIADO */
      if @w_asociado is not null and @w_asociado <> '' begin
         select @w_valor_asociado = round((@w_valor * @w_porcentaje / 100.0), @w_num_dec)
         
         if @w_di_estado = @w_est_vigente
            select @w_valor_no_vig = @w_valor_asociado
         else
            select @w_valor_no_vig = 0         
            
         /* ACTUALIZAR RUBRO ASOCIADO A COMFNGANU */
         if exists (
            select 1 
            from   ca_amortizacion_tmp
            where  amt_operacion = @i_operacion
            and    amt_dividendo = @w_di_dividendo
            and    amt_concepto  = @w_asociado)
         begin
            update ca_amortizacion_tmp with (rowlock) set 
            amt_cuota     = @w_valor_asociado,
            amt_acumulado = @w_valor_no_vig,
            amt_gracia    = 0                                       -- 02/FEB/2011 - REQ 175: PEQUEÑA EMPRESA
            where  amt_operacion = @i_operacion
            and    amt_dividendo = @w_di_dividendo 
            and    amt_concepto  = @w_asociado

             if (@@error <> 0) begin
                 close cursor_dividendos_1
                 deallocate cursor_dividendos_1
                 return 710002
             end
         end
         else begin
            /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP */
            insert into ca_amortizacion_tmp with (rowlock)(
            amt_operacion,      amt_dividendo,   amt_concepto,
            amt_cuota,          amt_gracia,      amt_pagado,
            amt_acumulado,      amt_estado,      amt_periodo,
            amt_secuencia)
            values(
            @i_operacion,       @w_di_dividendo, @w_asociado,
            @w_valor_asociado,  0,               0,
            @w_valor_no_vig,    @w_di_estado,    0,
            1 )

             if (@@error <> 0) begin
                 close cursor_dividendos_1
                 deallocate cursor_dividendos_1
                 return 710001
             end
         end
      end
   end 
   else begin   
      /* Si no es Dividendo de anualidad lo deja en valores cero */
      update ca_amortizacion_tmp with (rowlock) set    
      amt_cuota     = 0,
      amt_acumulado = 0,
      amt_gracia    = 0                                       -- 02/FEB/2011 - REQ 175: PEQUEÑA EMPRESA
      where amt_operacion = @i_operacion
      and   amt_dividendo = @w_di_dividendo 
      and   amt_concepto  in (@w_parametro_fng,@w_parametro_iva_fng)
      and   amt_estado    <> 3
      
      if @@error <> 0 begin
         close cursor_dividendos_1
         deallocate cursor_dividendos_1
         return 710002
      end
   end

   fetch   cursor_dividendos_1
   into    
   @w_di_dividendo,        @w_di_fecha_ini,     @w_di_fecha_ven,
   @w_di_estado

end /*WHILE CURSOR RUBROS SFIJOS*/

close cursor_dividendos_1
deallocate cursor_dividendos_1

-- ACTUALIZA ULTIMO DIVIDENDO A CEROS SI ES ANUALIDAD SI CAE EN ANUALIDAD
update ca_amortizacion_tmp with (rowlock) set    
amt_cuota     = 0,
amt_acumulado = 0,
amt_gracia    = 0                                       -- 02/FEB/2011 - REQ 175: PEQUEÑA EMPRESA
where amt_operacion  = @i_operacion
and   amt_dividendo  = @w_di_dividendo 
and   amt_concepto  in (@w_parametro_fng,@w_parametro_iva_fng)
and   amt_estado    <> 3

if @w_estado_op > @w_est_novigente begin -- Si es regenracion de tabla
   delete ca_amortizacion_tmp
   where amt_operacion = @i_operacion
   and   amt_concepto  in (@w_parametro_fng,@w_parametro_iva_fng)
   and   amt_cuota     = 0
end

return 0
go
