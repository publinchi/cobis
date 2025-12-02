/************************************************************************/
/*      Archivo:                calusaid.sp                             */
/*      Stored procedure:       sp_calculo_usaid                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Johan Ardila                            */
/*      Fecha de escritura:     Dic 2010                                */
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
/*      Calculo de comision USAID de manera periodica                   */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*  15/Dic/2010      Johan Ardila       Emision Inicial                 */
/*  16/03/2012       Luis Moreno        REQ 293 - No recalcular comision*/
/*                                      FNG a las cuotas pendientes     */
/*                                      cuando la obligacion tiene      */
/*                                      reconocimiento                  */
/************************************************************************/
use cob_cartera
go

if object_id ('sp_calculo_usaid') is not null
begin
   drop proc sp_calculo_usaid
end
go

create proc sp_calculo_usaid
   @i_operacion            int,
   @i_desde_abnextra       char(1)  = 'N',
   @i_cuota_abnextra       smallint = null,
   @i_parametro_usaid        varchar(10) = null,
   @i_parametro_usaidd       varchar(10) = null,
   @i_parametro_usaid_iva    varchar(10) = null
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
   @w_mes_anualidad        int,
   @w_tramite              int,
   @w_periodo_usaid        tinyint,
   @w_cod_gar_usaid        catalogo,
   @w_par_usaid            catalogo,
   @w_par_iva_usaid        catalogo,
   @w_dividendo_vig        int,
   @w_estado               int,
   @w_ult_dividendo        int,
   @w_cuota                money,
   @w_cuota_iva            money,
   @w_dividendo            int,
   @w_min_dividendo        int,
   @w_max_dividendo        int,
   @w_control_divid        int,
   @w_SMV                  money,
   @w_oficina              smallint,
   @w_monto_parametro      float,
   @w_fecha_ult_proceso    datetime,
   @w_error                int,
   @w_msg				      descripcion,
   @w_par_usaid_des        catalogo,
   @w_tdividendo           catalogo,
   @w_freq_cobro           int,
   @w_porc_per             float,
   @w_porc_des             float,
   @w_estado_gar           char(1),        -- REQ 293: RECONOCIMIENTO FNG Y USAID
   @w_seguros              char(1)
   
/** INICIALIZACION VARIABLES **/
select 
   @w_sp_name        = 'sp_calculo_usaid',   
   @w_valor          = 0,
   @w_porcentaje     = 0,
   @w_valor_asociado = 0,
   @w_asociado       = '',
   @w_plazo_restante = 0,
   @w_mes_anualidad  = 1,
   @w_dividendo_vig  = 0,
   @w_estado         = 0,
   @w_control_divid  = 0,
   @w_seguros        = 'N'
   
/* ESTADOS DE CARTERA */
/* ESTADOS DE CARTERA */
exec @w_error     = sp_estados_cca
   @o_est_novigente  = @w_est_novigente out,
   @o_est_vigente    = @w_est_vigente   out,
   @o_est_vencido    = @w_est_vencido   out,
   @o_est_cancelado  = @w_est_cancelado out,
   @o_est_credito    = @w_est_credito   out

if @w_error <> 0  return @w_error

/* PARAMETRO PORCENTAJE COBRO USAID PERIODICO */
select @w_porc_per = pa_smallint/100.0
  from cobis..cl_parametro 
 where pa_nemonico = 'PRUSAP'
   and pa_producto = 'CCA'

/* PARAMETRO PERIODICIDAD COBRO USAID */
select @w_periodo_usaid = pa_tinyint
  from cobis..cl_parametro 
 where pa_nemonico = 'PERUSA'
   and pa_producto = 'CCA'

/* CODIGO PADRE GARANTIA DE USAID */
select @w_cod_gar_usaid = pa_char
  from cobis..cl_parametro with (nolock)
 where pa_producto = 'GAR'
   and pa_nemonico = 'CODUSA'
set transaction isolation level read uncommitted

if @i_parametro_usaid is null and @i_parametro_usaidd is null and @i_parametro_usaid_iva is null begin

   /* PARAMETRO DE LA GARANTIA DE USAID DESEMBOLSO */
   select @w_par_usaid_des = pa_char
   from cobis..cl_parametro 
   where pa_nemonico = 'CMUSAD'
   and pa_producto = 'CCA'


   /* PARAMETRO DE LA GARANTIA DE USAID PERIODICA */
   select @w_par_usaid = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CCA'
   and pa_nemonico = 'CMUSAP'

   /* IVA DE LA COMISION DE USAID PERIODICA */
   select @w_par_iva_usaid = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'CCA'
   and pa_nemonico = 'ICMUSA'
end
else begin
   select @w_par_usaid     = @i_parametro_usaid,
          @w_par_usaid_des = @i_parametro_usaidd,
          @w_par_iva_usaid = @i_parametro_usaid_iva
end

/* PARAMETRO SALARIO MINIMO VITAL VIGENTE */
select @w_SMV = pa_money 
  from cobis..cl_parametro with (nolock)
 where pa_producto = 'ADM'
   and pa_nemonico = 'SMV'

/** DATOS OPERACION **/
select @w_fecha_fin         = opt_fecha_fin,
       @w_op_monto          = opt_monto,
       @w_moneda            = opt_moneda,
       @w_tramite           = opt_tramite,
       @w_estado            = opt_estado,
       @w_oficina           = opt_oficina,
       @w_fecha_ult_proceso = opt_fecha_ult_proceso,
       @w_tdividendo        = opt_tdividendo   -- JAR REQ 197
  from ca_operacion_tmp
 where opt_operacion = @i_operacion
 
if exists (select 1 from cob_credito..cr_seguros_tramite
           where st_tramite = @w_tramite)
           and @w_estado in (@w_est_novigente, @w_est_credito)
begin
   select @w_seguros = 'S'
   select @w_op_monto = tr_monto   -- Otra forma de obtener el monto sin seguros es tomar el @i_monto y restarle el valor total 
   from cob_credito..cr_tramite with (nolock) -- de los seguros, valor que se obtiene con el select que se realiza en la operacion C
   where tr_tramite = @w_tramite              -- del SP cob_credito..sp_seguros_tramite.               	
   
end  -- Fin Generar monto base de la operación Req. 366
 
/* FRECUENCIA DE COBRO DEPENDIENDO DEL TIPO DE DIVIDENDO */
select @w_freq_cobro = td_factor / 30
  from ca_tdividendo
 where td_tdividendo = @w_tdividendo
 
select @w_freq_cobro = @w_periodo_usaid / @w_freq_cobro

/* DIVIDENDO VIGENTE */
if @w_estado not in (@w_est_novigente, @w_est_vencido)
begin 
   select @w_dividendo_vig = di_dividendo
     from ca_dividendo
    where di_operacion = @i_operacion
      and di_estado    = @w_est_vigente
end

/* GARANTIA TIPO USAID */
select tc_tipo as tipo 
  into #calusaid
  from cob_custodia..cu_tipo_custodia
 where tc_tipo_superior = @w_cod_gar_usaid

select @w_estado_gar = cu_estado 
from cob_custodia..cu_custodia, cob_credito..cr_gar_propuesta, 
cob_credito..cr_tramite
where gp_tramite  = @w_tramite
and gp_garantia = cu_codigo_externo 
and cu_estado  in ('P','F','V','X','C')
and tr_tramite  = gp_tramite
and cu_tipo    in (select tipo from #calusaid)

if @@rowcount = 0
begin   

   update ca_amortizacion_tmp with (rowlock) set 
      amt_cuota     = case when amt_pagado > 0 then amt_pagado else 0 end,
      amt_acumulado = case when amt_pagado > 0 then amt_pagado else 0 end,
      amt_gracia    = 0                                        -- PAQUETE 2 - REQ 212 BANCA RURAL - 28/JUL/2011
    where amt_operacion = @i_operacion
      and amt_concepto in (@w_par_usaid, @w_par_iva_usaid)
   
   if @@error <> 0 return 724401
   else return 0   
end

/* OBTENER LA FECHA DE VENCIMIENTO FINAL DESDE ca_dividendo_tmp, POR QUE EN ca_operacion_tmp AUN NO SE TIENE */
select @w_fecha_fin = max(dit_fecha_ven)
  from ca_dividendo_tmp
 where dit_operacion = @i_operacion
      
/* NUMERO DE DECIMALES */
exec @w_return = sp_decimales
   @i_moneda    = @w_moneda,
   @o_decimales = @w_num_dec out

if @w_return <> 0 return  @w_return

/* CALCULO DEL MONTO EN SMVV */
select @w_monto_parametro = @w_op_monto/@w_SMV

/* CALCULO DE LA TASA */               
exec @w_error  = sp_matriz_valor
   @i_matriz    = @w_par_usaid,      
   @i_fecha_vig = @w_fecha_ult_proceso,  
   @i_eje1      = @w_monto_parametro,  
   @o_valor     = @w_factor out, 
   @o_msg       = @w_msg    out 
      
if @w_error <> 0 return @w_error

update ca_rubro_op set   
   ro_porcentaje     = @w_factor,
   ro_porcentaje_aux = @w_factor,
   ro_base_calculo    = @w_op_monto
 where ro_operacion = @i_operacion
   and ro_concepto  = @w_par_usaid

if @@error <> 0 return 720002

update ca_rubro_op_tmp set   
   rot_porcentaje      = @w_factor,
   rot_porcentaje_aux  = @w_factor,
   rot_base_calculo    = @w_op_monto
 where rot_operacion = @i_operacion
   and rot_concepto  = @w_par_usaid

if @@error <> 0 return 720002

update ca_rubro_op set
   ro_porcentaje      = @w_factor,
   ro_porcentaje_aux  = @w_factor 
 where ro_operacion = @i_operacion
   and ro_concepto  = @w_par_usaid_des

if @@error <> 0 return 720002
         
update ca_rubro_op_tmp set
   rot_porcentaje      = @w_factor,
   rot_porcentaje_aux  = @w_factor
 where rot_operacion = @i_operacion
   and rot_concepto  = @w_par_usaid_des

if @@error <> 0 return 720002

/* VALOR DE COMUSASEM */
select @w_valor = round((@w_op_monto * @w_porc_per * @w_factor / 100.0), @w_num_dec)

/* VERIFICAR SI EL RUBRO COMUSASEM TIENE RUBRO ASOCIADO */
if exists (
   select 1
     from ca_rubro_op_tmp
    where rot_operacion         = @i_operacion
      and rot_concepto_asociado = @w_par_usaid)
begin
   select @w_asociado   = rot_concepto,
          @w_porcentaje = rot_porcentaje
     from ca_rubro_op_tmp
    where rot_operacion         = @i_operacion
      and rot_concepto_asociado = @w_par_usaid
end

/* VERIFICA SI VIENE DE ABONO EXTRAORDINARIO */
if @i_cuota_abnextra is not null
begin 
   select @w_mes_anualidad = (@w_freq_cobro -(@i_cuota_abnextra % @w_freq_cobro)) + 1
end
   
/* UBICACION DEL USAID */   
select @w_min_dividendo = min(amt_dividendo)
  from ca_amortizacion_tmp
 where amt_operacion = @i_operacion
   and amt_concepto in (@w_par_usaid, @w_par_iva_usaid) 
   and amt_cuota     > 0 

select @w_control_divid = count(1)
  from ca_dividendo
 where di_operacion = @i_operacion
   and di_estado   in (@w_est_vencido, @w_est_cancelado)

select @w_max_dividendo = max(amt_dividendo)
  from ca_amortizacion_tmp
 where amt_operacion  = @i_operacion
   and amt_concepto  in (@w_par_usaid, @w_par_iva_usaid) 
   and amt_dividendo <= @w_dividendo_vig 
   and amt_cuota      > 0 

if @w_min_dividendo = @w_freq_cobro + 1
begin
   select @w_mes_anualidad = @w_freq_cobro + 1,
          @w_control_divid = @w_control_divid + 1
end
else
   select @w_mes_anualidad = @w_freq_cobro

if @w_max_dividendo < @w_control_divid
begin
   select @w_mes_anualidad = @w_max_dividendo + @w_freq_cobro
end
   
/** CURSOR DE DIVIDENDOS **/ 
declare cursor_dividendos_1 cursor for
select dit_dividendo,   dit_fecha_ini,   dit_fecha_ven,
       dit_estado
  from ca_dividendo_tmp
 where dit_operacion = @i_operacion
for read only

open  cursor_dividendos_1
fetch cursor_dividendos_1
into  @w_di_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, 
      @w_di_estado

/* WHILE CURSOR PRINCIPAL */
while @@fetch_status = 0 
begin
   if (@@fetch_status = -1) return 708999

   select @w_valor = 0   
     
   /* DETERMINAR CAMBIO DE PERIODO */
--   print '@w_di_dividendo: ' + cast(@w_di_dividendo as varchar) + ' @w_control_divid: ' + cast(@w_control_divid as varchar) + ' @w_mes_anualidad: ' + cast(@w_mes_anualidad as varchar)
   if @w_di_dividendo + @w_control_divid = @w_mes_anualidad 
   begin
      --print 'dividendo : w_di_dividendo ' + cast(@w_di_dividendo as varchar) + ' - w_control_divid ' +  cast(@w_control_divid as varchar) + ' - w_mes_anualidad ' + cast(@w_mes_anualidad as varchar)

      /* ACTUALIZAR MES ANUALIDAD */
      select @w_mes_anualidad = @w_mes_anualidad + @w_freq_cobro

      /* RECALCULAR VALOR DE COMUSASEM SOBRE EL SALDO DE CAPITAL*/
      select @w_op_monto = sum(amt_cuota - amt_pagado)
        from ca_amortizacion_tmp, ca_rubro_op_tmp
       where amt_operacion  = @i_operacion
         and rot_operacion  = amt_operacion
         and amt_dividendo >= @w_di_dividendo + 1
         and rot_concepto   = amt_concepto 
         and rot_tipo_rubro = 'C'    

      /* DETERMINA SI EL CALCULO SE HACE PERIODICAMENTE (@w_periodo_usaid en Meses) O */
      /* SOBRE EL PLAZO RESTANTE INFERIOR A (@w_periodo_usaid en Meses) */
      select @w_plazo_restante = datediff(mm,@w_di_fecha_ven,@w_fecha_fin)

      if @w_plazo_restante >= @w_freq_cobro 
      begin
         select @w_valor = round((@w_op_monto * @w_porc_per * @w_factor / 100.0), @w_num_dec)
      end 
      else 
      begin
         select @w_valor = round((((@w_op_monto * @w_porc_per * @w_factor / 100.0) / @w_freq_cobro) * @w_plazo_restante), @w_num_dec)
      end
   end
   else 
   begin /* ASIGNACION DEL VALOR DE LA COMISION A CERO POR QUE NO ES ANUALIDAD */
      if @i_desde_abnextra = 'S' 
      begin
          select @i_desde_abnextra = 'N'
      end
      select @w_valor = 0
   end   

   /* SI EL DIVIDENDO ESTA VIGENTE O NO VIGENTE */
   if @w_di_estado in (@w_est_vigente,@w_est_novigente) and @w_valor > 0 and @w_estado_gar <> 'X' and @w_estado_gar <> 'C'
   begin    
      if @w_di_estado = @w_est_vigente
         select @w_valor_no_vig = @w_valor
      else
         select @w_valor_no_vig = 0

      /* CALCULAR RUBRO COMUSASEM */
      if exists (
         select 1 
           from ca_amortizacion_tmp
          where amt_operacion = @i_operacion
            and amt_dividendo = @w_di_dividendo
            and amt_concepto  = @w_par_usaid)
      begin
         update ca_amortizacion_tmp with (rowlock) set 
            amt_cuota     = @w_valor,
            amt_acumulado = @w_valor_no_vig,
            amt_gracia    = 0                                        -- PAQUETE 2 - REQ 212 BANCA RURAL - 28/JUL/2011
          where amt_operacion = @i_operacion
            and amt_dividendo = @w_di_dividendo 
            and amt_concepto  = @w_par_usaid

         if @@error <> 0
         begin
             close cursor_dividendos_1
             deallocate cursor_dividendos_1
             return 710001
         end
      end
      else 
      begin
         /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP */
         insert into ca_amortizacion_tmp with (rowlock)
               (amt_operacion,   amt_dividendo,   amt_concepto,
                amt_cuota,       amt_gracia,      amt_pagado,
                amt_acumulado,   amt_estado,      amt_periodo,
                amt_secuencia)
         values(@i_operacion,    @w_di_dividendo, @w_par_usaid,
                @w_valor,        0,               0,
                @w_valor_no_vig ,@w_di_estado,    0,
                1 )
      
         if @@error <> 0
         begin
             close cursor_dividendos_1
             deallocate cursor_dividendos_1
             return 710001
         end
      end
      
        /* SI EL RUBRO COMUSASEM TIENE RUBRO ASOCIADO */
      if @w_asociado is not null and @w_asociado <> '' 
      begin         
         select @w_valor_asociado = round((@w_valor * @w_porcentaje / 100.0), @w_num_dec)
         
         if @w_di_estado = @w_est_vigente
            select @w_valor_no_vig = @w_valor_asociado
         else
            select @w_valor_no_vig = 0         

         /* ACTUALIZAR RUBRO ASOCIADO A COMUSASEM */
         if exists (
            select 1 
              from ca_amortizacion_tmp
             where amt_operacion = @i_operacion
               and amt_dividendo = @w_di_dividendo
               and amt_concepto  = @w_asociado)
         begin
            update ca_amortizacion_tmp with (rowlock) set 
               amt_cuota     = @w_valor_asociado,
               amt_acumulado = @w_valor_no_vig,
               amt_gracia    = 0                                        -- PAQUETE 2 - REQ 212 BANCA RURAL - 28/JUL/2011
             where amt_operacion = @i_operacion
               and amt_dividendo = @w_di_dividendo 
               and amt_concepto  = @w_asociado

            if @@error <> 0
            begin
               close cursor_dividendos_1
               deallocate cursor_dividendos_1
               return 710001
            end
         end
         else 
         begin
            /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP */
            insert into ca_amortizacion_tmp with (rowlock)
                  (amt_operacion,   amt_dividendo,   amt_concepto,
                   amt_cuota,       amt_gracia,      amt_pagado,
                   amt_acumulado,   amt_estado,      amt_periodo,
                   amt_secuencia)
            values(@i_operacion,     @w_di_dividendo, @w_asociado,
                   @w_valor_asociado,0,               0,
                   @w_valor_no_vig,  @w_di_estado,    0,
                   1 )

            if @@error <> 0
            begin
               close cursor_dividendos_1
               deallocate cursor_dividendos_1
               return 710001
            end
         end
      end
   end -- if @w_di_estado
   else 
   begin   
      /* Si no es Dividendo de anualidad lo deja en valores cero */
      update ca_amortizacion_tmp with (rowlock) set    
         amt_cuota     = 0,
         amt_acumulado = 0,
         amt_gracia    = 0                                        -- PAQUETE 2 - REQ 212 BANCA RURAL - 28/JUL/2011
       where amt_operacion = @i_operacion
         and amt_dividendo = @w_di_dividendo 
         and amt_concepto in (@w_par_usaid, @w_par_iva_usaid)
   end

   fetch cursor_dividendos_1
   into  @w_di_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, @w_di_estado

end /* WHILE CURSOR RUBROS SFIJOS */

close cursor_dividendos_1
deallocate cursor_dividendos_1

-- ACTUALIZA ULTIMO DIVIDENDO A CEROS SI ES ANUALIDAD SI CAE EN ANUALIDAD
update ca_amortizacion_tmp with (rowlock) set
   amt_cuota     = 0,
   amt_acumulado = 0,
   amt_gracia    = 0                                        -- PAQUETE 2 - REQ 212 BANCA RURAL - 28/JUL/2011
 where amt_operacion = @i_operacion
   and amt_dividendo = @w_di_dividendo 
   and amt_concepto in (@w_par_usaid, @w_par_iva_usaid)
  
return 0
go
