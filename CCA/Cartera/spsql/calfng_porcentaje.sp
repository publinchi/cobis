use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_calculo_fng_porcentaje')
   drop proc sp_calculo_fng_porcentaje
go

create proc sp_calculo_fng_porcentaje
@i_operacion      int,
@i_desde_abnextra char(1)  = 'N',
@i_cuota_abnextra smallint = null,
@i_regenerar      char(1)  = 'N',
@i_porcentaje     float    = 1.5

as
declare
@w_sp_name              varchar(30),
@w_return               int,
@w_est_vigente          tinyint,
@w_est_vencido          tinyint,
@w_est_cancelado        tinyint,
@w_est_novigente        tinyint,
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
@w_cod_gar_fng          catalogo,
@w_parametro_fng        catalogo,
@w_parametro_iva_fng    catalogo,
@w_dividendo_vig        int,
@w_estado               int,
@w_ult_dividendo        int,
@w_cuota                money,
@w_cuota_iva            money,
@w_dividendo            int,
@w_min_dividendo        int,
@w_SMV                  money,
@w_oficina              smallint,
@w_monto_parametro      float,
@w_fecha_ult_proceso    datetime,
@w_error                int,
@w_msg				    descripcion,
@w_parametro_fngd       catalogo

/** INICIALIZACION VARIABLES **/
select 
@w_sp_name        = 'sp_calculo_fng_regenerar',
@w_est_vigente    = 1,
@w_est_vencido    = 2,
@w_est_cancelado  = 3,
@w_est_novigente  = 0,
@w_valor          = 0,
@w_porcentaje     = 0,
@w_valor_asociado = 0,
@w_asociado       = '',
@w_plazo_restante = 0,
@w_mes_anualidad  = 1,
@w_dividendo_vig  = 0,
@w_estado         = 0

/*PARAMETRO DE LA GARANTIA DE FNGD*/
select @w_parametro_fngd = pa_char
from cobis..cl_parametro 
where pa_nemonico = 'COFNGD'
and   pa_producto = 'CCA'

/*CODIGO PADRE GARANTIA DE FNG*/
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'
set transaction isolation level read uncommitted

/*PARAMETRO DE LA GARANTIA DE FNG*/
select @w_parametro_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'

select @w_parametro_iva_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFNG'

/*PARAMETRO SALARIO MINIMO VITAL VIGENTE*/
select @w_SMV      = pa_money 
from   cobis..cl_parametro with (nolock)
where  pa_producto  = 'ADM'
and    pa_nemonico  = 'SMV'

/** DATOS OPERACION **/
select @w_fecha_fin         = opt_fecha_fin,
       @w_op_monto          = opt_monto,
       @w_moneda            = opt_moneda,
       @w_tramite           = opt_tramite,
       @w_estado            = opt_estado,
       @w_oficina           = opt_oficina,
       @w_fecha_ult_proceso = opt_fecha_ult_proceso
from   ca_operacion_tmp
where  opt_operacion    = @i_operacion

/* Dividendo Vigente */
if @w_estado <> 0 and @w_estado <> 2 
   select @w_dividendo_vig = di_dividendo
   from ca_dividendo
   where di_operacion = @i_operacion
   and   di_estado = 1

select tc_tipo as tipo into #calfng
from cob_custodia..cu_tipo_custodia
where  tc_tipo_superior  = @w_cod_gar_fng

if not exists (select 1 
           from cob_custodia..cu_custodia, 
           cob_credito..cr_gar_propuesta, 
           cob_credito..cr_tramite
           where gp_tramite  = @w_tramite
           and gp_garantia = cu_codigo_externo 
           and cu_estado   in ('P','F','V','X','C')
           and tr_tramite  = gp_tramite
           and cu_tipo in (select tipo from #calfng))
begin   

   update ca_amortizacion_tmp with (rowlock) set 
   amt_cuota     = case when amt_pagado > 0 then amt_pagado else 0 end,
   amt_acumulado = case when amt_pagado > 0 then amt_pagado else 0 end
   where  amt_operacion = @i_operacion
   and    amt_concepto  in (@w_parametro_fng,@w_parametro_iva_fng)
   if @@error <> 0
      return 724401
   else begin
      print 'sale por return 0 '
      return 0
   end 
end

/* OBTENER LA FECHA DE VENCIMIENTO FINAL DESDE ca_dividendo_tmp, POR QUE EN ca_operacion_tmp AUN NO SE TIENE */
select @w_fecha_fin = max(dit_fecha_ven)
from  ca_dividendo_tmp
where dit_operacion = @i_operacion
      
/* NUMERO DE DECIMALES */
exec @w_return = sp_decimales
@i_moneda      = @w_moneda,
@o_decimales   = @w_num_dec out
if @w_return != 0 return  @w_return

/*CALCULO DEL MONTO EN SMVV*/
select @w_monto_parametro  = @w_op_monto/@w_SMV

select @w_factor = @i_porcentaje

update ca_rubro_op
set   ro_porcentaje     = @w_factor,
      ro_porcentaje_aux = @w_factor
where ro_operacion  = @i_operacion
and   ro_concepto   = @w_parametro_fng
if @@error <> 0
   return 720002

update ca_rubro_op_tmp
set   rot_porcentaje     = @w_factor,
      rot_porcentaje_aux = @w_factor
where rot_operacion  = @i_operacion
and   rot_concepto   = @w_parametro_fng
if @@error <> 0
   return 720002
      

/* VALOR DE COMFNGANU */
select @w_valor       = round((@w_op_monto * @w_factor / 100.0), @w_num_dec)

/* VERIFICAR SI EL RUBRO COMFNGANU TIENE RUBRO ASOCIADO */
if exists (select 1
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
if @i_cuota_abnextra is not null 
   select @w_mes_anualidad = (12-(@i_cuota_abnextra % 12)) + 1
   
--/* UBICACION DEL fng */   
select @w_min_dividendo = min(am_dividendo)
from ca_amortizacion
where am_operacion =   @i_operacion
and   am_concepto  in (@w_parametro_fng,@w_parametro_iva_fng) 
and   am_cuota > 0 

if @w_min_dividendo = 13 begin
   select @w_mes_anualidad = 13
end   
else
   select @w_mes_anualidad = 12

select count(1) 
from  ca_dividendo_tmp
where dit_operacion = @i_operacion

/** CURSOR DE DIVIDENDOS **/
declare cursor_dividendos_1 cursor
for select dit_dividendo,
           dit_fecha_ini,
           dit_fecha_ven,
           dit_estado
from  ca_dividendo_tmp
where dit_operacion = @i_operacion
for read only

open    cursor_dividendos_1
fetch   cursor_dividendos_1
into    @w_di_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, @w_di_estado

/* WHILE CURSOR PRINCIPAL */
while @@fetch_status = 0
begin
   if (@@fetch_status = -1) return 708999

   select @w_valor = 0   
 
   /* DETERMINAR CAMBIO DE AÑO */
   if @w_di_dividendo = @w_mes_anualidad
   begin

      
   
      /* ACTUALIZAR MES ANUALIDAD */
      select @w_mes_anualidad = @w_mes_anualidad + 12

      /* RECALCULAR VALOR DE COMFNGANU SOBRE EL SALDO DE CAPITAL*/
      select @w_op_monto = sum(amt_cuota)
      from   ca_amortizacion_tmp, ca_rubro_op_tmp
      where  amt_operacion  = @i_operacion
      and    rot_operacion  = amt_operacion
      and    amt_dividendo >= @w_di_dividendo + 1
      and    rot_concepto   = amt_concepto 
      and    rot_tipo_rubro = 'C'
      
      /* DETERMINA SI EL CALCULO SE HACE SOBRE 12 MESES O SOBRE EL PLAZO RESTANTE INFERIOR A 12 MESES*/
      select @w_plazo_restante = datediff(mm,@w_di_fecha_ven,@w_fecha_fin)
      if @w_plazo_restante >= 12
      begin
         select @w_valor = round((@w_op_monto * @w_factor / 100.0), @w_num_dec)
      end
      else
      begin
         select @w_valor = round((((@w_op_monto * @w_factor / 100.0) / 12) * @w_plazo_restante), @w_num_dec)
      end

      print 'anualidad ' + cast(@w_di_dividendo as varchar) + ' - ' + cast(@w_valor as varchar)
   end
   else
   begin /*ASIGNACION DEL VALOR DE LA COMISION A CERO POR QUE NO ES ANUALIDAD*/
      if @i_desde_abnextra = 'S'
      begin
          select @i_desde_abnextra = 'N'
      end
      select @w_valor = 0
   end

   /* SI EL DIVIDENDO ESTA VIGENTE O NO VIGENTE */
   if @w_di_estado in (@w_est_vigente,@w_est_novigente) and @w_valor > 0
   begin
   
      if @w_di_estado = @w_est_vigente
         select @w_valor_no_vig = @w_valor
      else
         select @w_valor_no_vig = 0

      /* CALCULAR RUBRO COMFNGANU */
      if exists (select 1 
                 from   ca_amortizacion_tmp
                 where  amt_operacion = @i_operacion
                 and    amt_dividendo = @w_di_dividendo
                 and    amt_concepto  = @w_parametro_fng)
      begin

         update ca_amortizacion_tmp with (rowlock) set 
         amt_cuota     = @w_valor,
         amt_acumulado = case amt_estado when 3 then @w_valor else 0 end,
         amt_pagado    = case amt_estado when 3 then @w_valor else 0 end
         where  amt_operacion = @i_operacion
         and    amt_dividendo = @w_di_dividendo 
         and    amt_concepto  = 'COMFNGANU'

         if (@@error <> 0)
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
         values(@i_operacion,    @w_di_dividendo, @w_parametro_fng,
                @w_valor,        0,               0,
                @w_valor_no_vig ,@w_di_estado,    0,
                1 )
      
         if (@@error <> 0)
         begin
             close cursor_dividendos_1
             deallocate cursor_dividendos_1
             return 710001
         end
      end

      /* SI EL RUBRO COMFNGANU TIENE RUBRO ASOCIADO */
      if @w_asociado is not null and @w_asociado <> ''
      begin
         select @w_valor_asociado = round((@w_valor * @w_porcentaje / 100.0), @w_num_dec)
         
         if @w_di_estado = @w_est_vigente
            select @w_valor_no_vig = @w_valor_asociado
         else
            select @w_valor_no_vig = 0         
         
         /* ACTUALIZAR RUBRO ASOCIADO A COMFNGANU */
         if exists (select 1 
                    from   ca_amortizacion_tmp
                    where  amt_operacion = @i_operacion
                    and    amt_dividendo = @w_di_dividendo
                    and    amt_concepto  = @w_asociado)
         begin
         
            update ca_amortizacion_tmp with (rowlock) set 
            amt_cuota     = @w_valor_asociado,
            amt_acumulado = @w_valor_no_vig
            where  amt_operacion = @i_operacion
            and    amt_dividendo = @w_di_dividendo 
            and    amt_concepto  = @w_asociado

             if (@@error <> 0)
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

             if (@@error <> 0)
             begin
                 close cursor_dividendos_1
                 deallocate cursor_dividendos_1
                 return 710001
             end
         end
      end
   end 
   else begin   
      /* Si no es Dividendo de anualidad lo deja en valores cero */
      update ca_amortizacion_tmp with (rowlock)
      set    amt_cuota = 0,
             amt_acumulado = 0
      where  amt_operacion = @i_operacion
      and    amt_dividendo = @w_di_dividendo 
      and    amt_concepto  in (@w_parametro_fng,@w_parametro_iva_fng)
   end

   fetch   cursor_dividendos_1
   into    @w_di_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, @w_di_estado

end /*WHILE CURSOR RUBROS SFIJOS*/

close cursor_dividendos_1
deallocate cursor_dividendos_1


-- ACTUALIZA ULTIMO DIVIDENDO A CEROS SI ES ANUALIDAD SI CAE EN ANUALIDAD
update ca_amortizacion_tmp with (rowlock) set    
amt_cuota     = 0,
amt_acumulado = 0
where amt_operacion = @i_operacion
and   amt_dividendo = @w_di_dividendo 
and   amt_concepto  in (@w_parametro_fng,@w_parametro_iva_fng)

  
return 0
go
