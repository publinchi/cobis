/************************************************************************/
/*      Archivo:                calmpyme.sp                             */
/*      Stored procedure:       sp_calculo_mipymes                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sandro Vallejo                          */
/*      Fecha de escritura:     Marzo 2008                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calculo de comision mipymes                                     */
/*                              CAMBIOS                                 */
/* Fecha             Autor            Modificacion                      */
/* Ene-09-2013       Luis Guzman      CCA 403 Comision Mipyme           */
/*                                    considerando todos los valores    */
/* Nov-10-2015       Andres Diab      CCA YYY Ajuste Calculo Factor tasa*/
/*                                    comision Mipyme           */  
/* 03/Jul/2020       Luis Ponce       CDIG Ajustes Migracion a Java     */
/************************************************************************/  

use cob_cartera
go

set ansi_warnings off
go

if exists(select 1 from sysobjects where name = 'sp_calculo_mipymes')
   drop proc sp_calculo_mipymes
go
---INC.110395 ABR.16.2013
create proc sp_calculo_mipymes
@i_operacion            int,
@i_desde_batch          char(1)  = 'N',
@i_dividendo_anualidad  int      = null,
@i_desplazamiento       char(1)  = 'N',
@i_cuota_desde          smallint = null

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
@w_di_fecha_ven         datetime,
@w_di_estado            int,
@w_valor                money,
@w_valor_tmp            money,
@w_factor               float,
@w_asociado             catalogo,
@w_porcentaje           float,
@w_valor_asociado       money,
@w_mes_anualidad        int,
@w_mipymes              varchar(10),
@w_cliente_nuevo        char(1),
@w_error                int,
@w_cliente              int,
@w_oficina_op           smallint,
@w_fecha_ult_p          smalldatetime,
@w_SMV                  money,
@w_monto_parametro      float,
@w_di_fecha_ini         smalldatetime,
@w_mensaje              varchar(255),
@w_porcentaje_asociado  float,
@w_msg                  mensaje,
@w_acumulado            money,
@w_dividendo_anualidad  int,
@w_am_estado            int,
@w_op_estado            int,
@w_clase_cartera        catalogo,
@w_div_vigente          int,
@w_mes_actual           int,
@w_periodo_int          int,
@w_gracia_prin          money,                              -- 02/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_gracia_asoc          money,                              -- 02/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_gracia_int           smallint,                           -- 01/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_valor_gr             money,                              -- 01/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_pagado               money,                              -- 01/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_cuota                money,                              -- 01/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_existe               char(1),                            -- 01/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_capitalizado         money,                              -- 18/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_saldo_cap            money,                              -- 18/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_dist_gracia          char(1),                            -- 18/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
@w_seguros              char(1),                            -- 366 - seguros
@w_tramite              int ,                                -- 366 - seguros
@w_monto_parametro_adi  float,                              -- ADI: REGISTRAR RESIDUO PARA LIMITES MATRIZ MYPMES, EJE SMLV
@w_fecha_vig            datetime,                            -- ADI: REGISTRAR VIGENCIA DE LIMITES MATRIZ MYPMES, EJE SMLV
@w_toperacion           catalogo,
@w_count                INT


/** INICIALIZACION VARIABLES **/
select 
@w_sp_name         = 'sp_calculo_mipymes',
@w_est_vigente     = 1,
@w_est_novigente   = 0,
@w_valor           = 0,
@w_porcentaje      = 0,
@w_valor_asociado  = 0,
@w_asociado        = '',
@w_mes_anualidad   = 1,
@w_seguros         = 'N',
@w_tramite         = 0



select @w_mipymes = pa_char 
from cobis..cl_parametro with (nolock)
where pa_producto  = 'CCA'
and   pa_nemonico  = 'MIPYME'

select @w_SMV      = pa_money 
from   cobis..cl_parametro with (nolock)
where  pa_producto  = 'ADM'
and    pa_nemonico  = 'SMV'

if @i_desde_batch = 'N' begin
   /** DATOS OPERACION **/
   select 
   @w_fecha_liq     = opt_fecha_liq,
   @w_moneda        = opt_moneda,
   @w_cliente       = opt_cliente,
   @w_oficina_op    = opt_oficina,
   @w_fecha_ult_p   = opt_fecha_ult_proceso,
   @w_clase_cartera = opt_clase,
   @w_op_estado     = opt_estado,
   @w_gracia_int    = opt_gracia_int,                       -- 01/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
   @w_dist_gracia   = opt_dist_gracia,                      -- 18/FEB/2011 - REQ 175 PEQUEÐA EMPRESA
   @w_tramite       = opt_tramite,
   @w_toperacion    = opt_toperacion
   from   ca_operacion_tmp
   where  opt_operacion    = @i_operacion
   
   if not exists (select 1 from ca_rubro where ru_toperacion = @w_toperacion and ru_concepto = @w_mipymes and ru_moneda = @w_moneda ) return 0
   
   -- 366 - seguros
   if exists (select 1 from cob_credito..cr_seguros_tramite where st_tramite = @w_tramite)
      select @w_seguros = 'S'
      
      --print 'calpyme.sp ' + cast(@w_tramite as varchar) +  ' - ' + @w_seguros
   
   -- REQ 175: PEQUEÐA EMPRESA - CALCULAR EL MONTO CAPITALIZADO
   select @w_capitalizado = isnull(sum(rot_base_calculo), 0)
   from   ca_rubro_op_tmp
   where  rot_operacion  = @i_operacion
   and    rot_tipo_rubro = 'C'

   if @i_desplazamiento = 'S' and @w_gracia_int > 0
   begin
      if @w_gracia_int - @i_cuota_desde + 1 > 0
         select @w_gracia_int = @w_gracia_int - @i_cuota_desde + 1
      else 
         select @w_gracia_int = 0
   end
   
   /*MONTO OPERACION*/
   select @w_op_monto = sum(amt_cuota - amt_pagado)
   from   ca_amortizacion_tmp, ca_rubro_op_tmp
   where  amt_operacion  = @i_operacion
   and    rot_operacion  = amt_operacion
   and    rot_concepto   = amt_concepto 
   and    rot_tipo_rubro = 'C'
   --print 'calpyme.sp antes 1' + cast(@w_op_monto as varchar) +  ' - ' + @w_seguros

   /* OBTENER FACTOR DE CALCULO */
   select @w_factor = rot_porcentaje
   from   ca_rubro_op_tmp
   where  rot_operacion = @i_operacion
   and    rot_concepto  = @w_mipymes

   if @i_desplazamiento = 'N' begin  --calculo inicial de la tabla de amortizacion
      if exists (select 1 from ca_operacion with (rowlock)
                  where op_cliente = @w_cliente
                    and op_estado  in (0,1,2,3,4,5,9,99)
                    and op_operacion <> @i_operacion)
         select @w_cliente_nuevo = 'R'     --R: Renovado
      else         
         select @w_cliente_nuevo = 'N'     --N: new
   
      if exists (select 1 from ca_estado where es_codigo = @w_op_estado and es_procesa = 'N') begin

         /*OBTENER EL FACTOR DE LA TASA MIPYMES POR PRIMERA VEZ*/ 
         select @w_monto_parametro = floor(@w_op_monto/@w_SMV)
         select @w_monto_parametro_adi = (@w_op_monto%@w_SMV)   -- HALLAR EL MODULO PARA IDENTIFICAR DECIMALES
          
         if @w_monto_parametro <= 1
            select @w_monto_parametro = @w_monto_parametro + 2   ---aseguramiento que este en el rango 0-4

         /* IDENTIFICAR SI ESTOY EN EL LIMITE SUPERIOR DE UN RANGO, DEL EJE SMLV, Y POR DECIMALES DEBE PASAR AL SIGUIENTE RANGO */
         select @w_fecha_vig = max(ma_fecha_vig)
         from ca_matriz with (nolock)
         where ma_matriz   = @w_mipymes
         and ma_fecha_vig <= @w_fecha_ult_p
         if @w_fecha_vig is null begin
            -- NO EXISTE UNA MATRIZ ' + @w_mipymes + ' PARAMETRIZADA A LA FECHA ' + convert(varchar,@w_fecha_ult_p,103)
            return 701188
         end

         if (@w_monto_parametro in (select convert(float,er_rango_hasta) from cob_cartera..ca_eje_rango 
	                                where er_matriz = @w_mipymes and er_eje = 2 and er_fecha_vig = @w_fecha_vig)
	         and @w_monto_parametro_adi <> 0)
            select @w_monto_parametro = @w_monto_parametro + 1
        
         select @w_factor = 0    
         if @w_monto_parametro > 0
         begin        
	         exec @w_error  = sp_matriz_valor
	         @i_matriz      = @w_mipymes,      
	         @i_fecha_vig   = @w_fecha_ult_p,  
	         @i_eje1        = @w_oficina_op,   
	         @i_eje2        = @w_monto_parametro,     
	         @i_eje3        = @w_cliente_nuevo,
	         @o_valor       = @w_factor out, 
	         @o_msg         = @w_msg    out 
	             
	         if @w_error <> 0  return @w_error      
         end
              
         select @w_factor = isnull(@w_factor,0)
         
         update ca_rubro_op_tmp with (rowlock) set
         rot_porcentaje =  @w_factor
         from   ca_rubro_op_tmp
         where  rot_operacion = @i_operacion
         and    rot_concepto  = @w_mipymes
         
         if (@@error <> 0) return 720501      
      end      
   end   

   if @w_seguros = 'S' begin
      select @w_op_monto = @w_op_monto - isnull(sum(sed_cuota_cap - sed_pago_cap),0)
      from   ca_seguros_det
      where  sed_operacion = @i_operacion  
      
      --print 'calpyme.sp despues 1' + cast(@w_op_monto as varchar) +  ' - ' + @w_seguros
          
   end    
   
   /* NUMERO DE DECIMALES */
   exec @w_return = sp_decimales
   @i_moneda      = @w_moneda,
   @o_decimales   = @w_num_dec out
   if @w_return <> 0 return  @w_return
   
   
   select @w_div_vigente = di_dividendo
   from   ca_dividendo
   where  di_operacion   = @i_operacion 
   and    di_estado      = 1
   
   if @@rowcount = 0 select @w_div_vigente = null

   /* VERIFICA SI VIENE DE ABONO EXTRAORDINARIO */
  
   if @w_div_vigente is not null begin

      select @w_periodo_int = op_periodo_int * td_factor / 30
      from ca_operacion, ca_tdividendo
      where op_operacion = @i_operacion
      and   op_tdividendo = td_tdividendo

      if @@rowcount = 0 select @w_periodo_int = 1

      select @w_mes_actual = (@i_cuota_desde - 1) * @w_periodo_int + 1
  
      select @w_mes_anualidad = 12 * ((@w_mes_actual - 1) / 12) - @w_mes_actual + 2      -- REQ 175: PEQUEÐA EMPRESA +2
      
      if @w_mes_anualidad <= 0
         select @w_mes_anualidad = @w_mes_anualidad + 12
            
      select @w_valor = am_cuota
      from ca_amortizacion
      where am_operacion = @i_operacion
      and   am_dividendo = @w_div_vigente
      and   am_concepto  = @w_mipymes

   end else begin
   
      /* DETERMINAR PERIODICIDAD DE PAGO DE INTERESES EN LA OPERACION TEMPORAL */
      select @w_periodo_int = opt_periodo_int * td_factor / 30
      from ca_operacion_tmp, ca_tdividendo
      where opt_operacion = @i_operacion
      and   opt_tdividendo = td_tdividendo

      if @@rowcount = 0 select @w_periodo_int = 1
      
      -- INI - REQ 175: PEQUEÐA EMPRESA
      if @i_desplazamiento = 'S' and @i_cuota_desde > 0
      begin
         select @w_mes_actual = (@i_cuota_desde - 1) * @w_periodo_int + 1
  
         select @w_mes_anualidad = 12 * ((@w_mes_actual - 1) / 12) - @w_mes_actual + 2       

         if @w_mes_anualidad <= 0                                                            
            select @w_mes_anualidad = @w_mes_anualidad + 12

         select @w_valor = am_cuota
         from ca_amortizacion
         where am_operacion = @i_operacion
         and   am_dividendo = @i_cuota_desde - 1
         and   am_concepto  = @w_mipymes
  
      end
      else
      begin
         select @w_mes_anualidad = 1

         select @w_valor = round((@w_op_monto * @w_periodo_int * @w_factor / 1200.0), @w_num_dec)         
      end               
      -- FIN - REQ 175: PEQUEÐA EMPRESA
   end
   
   if @w_clase_cartera = 1 select @w_valor = 0
      
   /* VERIFICAR SI EL RUBRO MIPYMES TIENE RUBRO ASOCIADO */ 
   select 
   @w_asociado             = rot_concepto,
   @w_porcentaje_asociado  = rot_porcentaje
   from   ca_rubro_op_tmp
   where  rot_operacion         = @i_operacion
   and    rot_concepto_asociado = @w_mipymes

   if @@rowcount = 0 or @w_porcentaje_asociado is null select @w_porcentaje_asociado = 0, @w_asociado = ''


   /* DETERMINAR PERIODICIDAD DE PAGO DE INTERESES EN LA OPERACION TEMPORAL */
   select @w_periodo_int = opt_periodo_int * td_factor / 30
   from ca_operacion_tmp, ca_tdividendo
   where opt_operacion = @i_operacion
   and   opt_tdividendo = td_tdividendo

   if @@rowcount = 0 select @w_periodo_int = 1
   
   select @w_gracia_prin = isnull(rot_gracia, 0)
   from ca_rubro_op_tmp
   where rot_operacion = @i_operacion
   and   rot_concepto  = @w_mipymes
   
   select @w_gracia_asoc = isnull(rot_gracia, 0)
   from ca_rubro_op_tmp
   where rot_operacion = @i_operacion
   and   rot_concepto  = @w_asociado

   /** CURSOR DE DIVIDENDOS **/
   declare cursor_dividendos_2 cursor for
   select 
   dit_dividendo,   dit_fecha_ven,   dit_estado,
   dit_fecha_ini
   from  ca_dividendo_tmp with (nolock)
   where dit_operacion  = @i_operacion
   order by dit_dividendo
   for read only
   
   open    cursor_dividendos_2
   
   fetch   cursor_dividendos_2
   into    
   @w_di_dividendo, @w_di_fecha_ven, @w_di_estado, 
   @w_di_fecha_ini
   
   /* WHILE CURSOR PRINCIPAL */
   while @@fetch_status = 0  begin
    
      if (@@fetch_status = -1) return 708999

      select @w_mes_actual = (@w_di_dividendo-1) * @w_periodo_int + 1

      if @w_mes_actual = @w_mes_anualidad  begin

         /* ACTUALIZAR MES ANUALIDAD */
         select @w_mes_anualidad = @w_mes_anualidad + 12
                           
         /* RECALCULAR VALOR DE MIPYMES SOBRE EL SALDO DE CAPITAL*/
         select @w_saldo_cap = sum(amt_cuota - amt_pagado)
         from   ca_amortizacion_tmp, ca_rubro_op_tmp
         where  amt_operacion  = @i_operacion
         and    rot_operacion  = amt_operacion
         and    amt_dividendo >= @w_di_dividendo
         and    rot_concepto   = amt_concepto 
         and    rot_tipo_rubro = 'C'
         --print 'calpyme.sp antes 2' + cast(@w_op_monto as varchar) +  ' - ' + @w_seguros
         if @w_seguros = 'S' begin
            select @w_saldo_cap = @w_saldo_cap - isnull(sum(sed_cuota_cap - sed_pago_cap),0)
            from   ca_seguros_det
            where  sed_operacion = @i_operacion 
            and    sed_dividendo >= @w_di_dividendo 
      
            --print 'calpyme.sp despues 2' + cast(@w_op_monto as varchar) +  ' - ' + @w_seguros          
          end 
		  
         if @w_saldo_cap < 0
            select @w_saldo_cap = 0
			
         -- REQ 175: PEQUEÐA EMPRESA
         if @w_dist_gracia = 'C' and @w_di_dividendo <= @w_gracia_int
            select @w_saldo_cap = @w_saldo_cap - isnull(@w_capitalizado, 0)
          
         select @w_valor  = round((@w_saldo_cap * @w_periodo_int * @w_factor / 1200.0), @w_num_dec)
         
         if @w_clase_cartera = 1 select @w_valor = 0
         
      end
       
      -- Determina el valor acumulado 
      --select @w_acumulado = case when @w_di_estado = @w_est_novigente then 0 else @w_valor end  --LPO CDIG Cambio de case por ir por Migracion a Java
      
      --LPO CDIG Cambio de case por ir por Migracion a Java INICIO
      IF @w_di_estado = @w_est_novigente
         select @w_acumulado = 0
      ELSE
         select @w_acumulado = @w_valor      
      --LPO CDIG Cambio de case por ir por Migracion a Java FIN
      
      
      -- INI - 01/FEB/2011 - REQ 175 - PEQUEÐA EMPRESA         
      select 
      @w_pagado = isnull(sum(amt_pagado), 0),      
      --@w_existe = case count(1) when 0 then 'N' else 'S' end  --LPO CDIG Cambio de case por ir por Migracion a Java      
      @w_count = count(1)  --LPO CDIG Cambio de case por ir por Migracion a Java
      from ca_amortizacion_tmp  with (nolock)
      where  amt_operacion = @i_operacion
      and    amt_dividendo = @w_di_dividendo
      and    amt_concepto  = @w_mipymes


      --LPO CDIG Cambio de case por ir por Migracion a Java INICIO
      IF @w_count = 0
         SELECT @w_existe = 'N'
      ELSE
         SELECT @w_existe = 'S'
      --LPO CDIG Cambio de case por ir por Migracion a Java FIN

         
      if @w_pagado > @w_valor
         select @w_cuota = @w_pagado
      else
         select @w_cuota = @w_valor
         
      if @w_di_dividendo <= @w_gracia_int
         select 
         @w_gracia_prin = @w_gracia_prin + isnull(@w_cuota, 0),
         @w_valor_gr    = @w_cuota * -1
      else
         select 
         @w_valor_gr    = @w_gracia_prin,
         @w_gracia_prin = 0
         
      -- FIN - 01/FEB/2011 - REQ 175 - PEQUEÐA EMPRESA

      if @w_existe = 'S'
      begin
      
         update ca_amortizacion_tmp with (rowlock) set 
         amt_cuota     = case when amt_pagado > @w_valor then amt_pagado else @w_valor end,
         amt_acumulado = case when amt_pagado > 0.00     then amt_pagado else @w_acumulado end,
         amt_gracia    = @w_valor_gr                                 -- 02/FEB/2011 - REQ 175: PEQUEÐA EMPRESA
         where  amt_operacion = @i_operacion
         and    amt_dividendo = @w_di_dividendo
         and    amt_concepto  = @w_mipymes
     
         if @@error <> 0 begin
            close cursor_dividendos_2
            deallocate cursor_dividendos_2
            return 710002
         end
          
      end else begin
      
         if @w_valor >= 0.01 begin
         
            /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP */
            insert into ca_amortizacion_tmp with (rowlock) (
            amt_operacion,   amt_dividendo,   amt_concepto,
            amt_cuota,       amt_gracia,      amt_pagado,
            amt_acumulado,   amt_estado,      amt_periodo,
            amt_secuencia)
            values(
            @i_operacion,    @w_di_dividendo, @w_mipymes,
            @w_valor,        @w_valor_gr,     0,                     -- 02/FEB/2011 - REQ 175: PEQUEÐA EMPRESA - @w_valor_gr
            @w_acumulado,    @w_di_estado,    0,
            1 )
        
            if (@@error <> 0) begin
               close cursor_dividendos_2
               deallocate cursor_dividendos_2
               return 710001
            end
            
         end --si valor es mayor a cero
      end
      
     
      /* ACTUALIZAR RUBRO ASOCIADO A MIPYMES */
      select @w_valor_asociado = round((@w_valor * @w_porcentaje_asociado / 100.0), @w_num_dec)
      --select @w_acumulado      = case when @w_di_estado = @w_est_novigente then 0 else @w_valor_asociado end  --LPO CDIG Cambio de case por ir por Migracion a Java
      
      --LPO CDIG Cambio de case por ir por Migracion a Java INICIO
      IF @w_di_estado = @w_est_novigente
         select @w_acumulado = 0
      ELSE
         select @w_acumulado = @w_valor_asociado
      --LPO CDIG Cambio de case por ir por Migracion a Java FIN
      
      
      
      -- INI - 01/FEB/2011 - REQ 175 - PEQUEÐA EMPRESA      
      if @w_di_dividendo <= @w_gracia_int
         select 
         @w_gracia_asoc = @w_gracia_asoc + isnull(@w_valor_asociado, 0),
         @w_valor_gr    = @w_valor_asociado * -1
      else
         select 
         @w_valor_gr    = @w_gracia_asoc,
         @w_gracia_asoc = 0
      -- FIN - 01/FEB/2011 - REQ 175 - PEQUEÐA EMPRESA
      
      if exists (select 1 from  ca_amortizacion_tmp with (nolock)
      where amt_operacion = @i_operacion
      and   amt_dividendo = @w_di_dividendo
      and   amt_concepto  = @w_asociado)
      begin
      
         update ca_amortizacion_tmp with (rowlock) set 
         amt_cuota     = @w_valor_asociado,
         amt_acumulado = @w_acumulado,
         amt_gracia    = @w_valor_gr
         where  amt_operacion = @i_operacion
         and    amt_dividendo = @w_di_dividendo
         and    amt_concepto  = @w_asociado
     
         if (@@error <> 0) begin
             close cursor_dividendos_2
             deallocate cursor_dividendos_2
             return 710002
         end
         
      end else begin
      
         if @w_valor_asociado >= 0.01 begin
         
            /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP */
            insert into ca_amortizacion_tmp with (rowlock) (
            amt_operacion,     amt_dividendo,   amt_concepto,
            amt_cuota,         amt_gracia,      amt_pagado,
            amt_acumulado,     amt_estado,      amt_periodo,
            amt_secuencia)
            values(
            @i_operacion,      @w_di_dividendo, @w_asociado,
            @w_valor_asociado, @w_valor_gr,     0,
            @w_acumulado,      @w_di_estado,    0,
            1 )
            
            if @@error <> 0 begin
                close cursor_dividendos_2
                deallocate cursor_dividendos_2
                return 710001
            end
         end
      end
         
      fetch   cursor_dividendos_2
      into    
      @w_di_dividendo, @w_di_fecha_ven, @w_di_estado, 
      @w_di_fecha_ini
   
   end /*WHILE CURSOR*/
   
   close cursor_dividendos_2
   deallocate cursor_dividendos_2
 
   return 0   
   
end

/*EXISTEN DIVIDENDOS VENCIDOS, SE DEBE RECALCULAR PARA LA ANUALIDAD SIGUIENE*/   
if @i_desde_batch = 'S' begin

   /** DATOS OPERACION **/
   select 
   @w_fecha_liq   = op_fecha_liq,
   @w_moneda      = op_moneda,
   @w_fecha_ult_p = op_fecha_ult_proceso,
   @w_op_estado   = op_estado,
   @w_clase_cartera = op_clase,
   @w_toperacion    = op_toperacion
   from   ca_operacion with (nolock)
   where  op_operacion = @i_operacion

  if not exists (select 1 from ca_rubro where ru_toperacion = @w_toperacion and ru_concepto = @w_mipymes and ru_moneda = @w_moneda ) return 0
  
   select @w_periodo_int = op_periodo_int * td_factor / 30
   from ca_operacion, ca_tdividendo
   where op_operacion = @i_operacion
   and   op_tdividendo = td_tdividendo

   if @@rowcount = 0 select @w_periodo_int = 1

   /* DETERMINAR LA PRIMERA CUOTA NO VIGENTE */
   select @w_dividendo_anualidad = di_dividendo
   from   ca_dividendo  with (nolock)
   where  di_operacion  = @i_operacion
   and    di_estado     in (0,1)
   and    di_fecha_ini  = @w_fecha_ult_p
   
   if @@rowcount = 0 return 0  -- si no existen cuotas no vigentes, salir
   
   /* DETERMINAR EL PORCENTAJE DE MIPYME */
   select @w_factor = ro_porcentaje
   from   ca_rubro_op with (nolock)
   where  ro_operacion = @i_operacion
   and    ro_concepto  = @w_mipymes
   
   if @@rowcount = 0 or @w_factor is null select @w_factor = 0

   
   /* NUMERO DE DECIMALES */
   exec @w_return = sp_decimales
   @i_moneda      = @w_moneda,
   @o_decimales   = @w_num_dec out
   
   if @w_return <> 0 return  @w_return
   
   /* VERIFICAR SI EL RUBRO MIPYMES TIENE RUBRO ASOCIADO */ 
   select 
   @w_asociado             = ro_concepto,
   @w_porcentaje_asociado  = ro_porcentaje
   from   ca_rubro_op
   where  ro_operacion         = @i_operacion
   and    ro_concepto_asociado = @w_mipymes

   if @@rowcount = 0 or @w_porcentaje_asociado is null select @w_porcentaje_asociado = 0, @w_asociado = ''
  

   /** CURSOR DE DIVIDENDOS **/
   declare cursor_dividendos_3 cursor for
   select 
   di_dividendo,     di_fecha_ven,        di_estado,
   di_fecha_ini
   from  ca_dividendo with (nolock)
   where di_operacion  = @i_operacion
   and   di_dividendo >= @w_dividendo_anualidad
   order by di_dividendo
   for read only
   
   open    cursor_dividendos_3
   
   fetch   cursor_dividendos_3
   into    @w_di_dividendo,  @w_di_fecha_ven,     @w_di_estado,   @w_di_fecha_ini
   
   /* WHILE CURSOR PRINCIPAL */
   while @@fetch_status = 0  begin
    
      if (@@fetch_status = -1) return 708999 

      select @w_mes_anualidad = datediff(mm,@w_fecha_liq,@w_di_fecha_ini)
      
      if @w_mes_anualidad in (12,24,36,48,60) begin
                   
         /* RECALCULAR VALOR DE MIPYMES SOBRE EL SALDO DE CAPITAL*/
         select @w_op_monto = isnull(sum(am_cuota - am_pagado),0)
         from   ca_amortizacion  with (nolock), ca_rubro_op  with (nolock)
         where  am_operacion  = @i_operacion
         and    ro_operacion  = am_operacion
         and    am_dividendo >= @w_di_dividendo
         and    ro_concepto   = am_concepto 
         and    ro_tipo_rubro = 'C'
         --print 'calpyme.sp antes 2' + cast(@w_op_monto as varchar) +  ' - ' + @w_seguros
         if @w_seguros = 'S' begin
            select @w_op_monto = @w_op_monto - isnull(sum(sed_cuota_cap - sed_pago_cap),0)
            from   ca_seguros_det
            where  sed_operacion = @i_operacion      
            and    sed_dividendo >= @w_di_dividendo
            
            --print 'calpyme.sp despues 2' + cast(@w_op_monto as varchar) +  ' - ' + @w_seguros
            
        end   
         
         select @w_valor     = round((@w_op_monto * @w_periodo_int * @w_factor / 1200.0), @w_num_dec)
         --print 'calpyme.sp despues Val 2' + cast(@w_valor as varchar) +  ' - ' + @w_seguros
         if @w_clase_cartera = 1 select @w_valor = 0

      end

      --select @w_acumulado = case when @w_di_estado = @w_est_novigente then 0 else @w_valor end  --LPO CDIG Cambio de case por ir por Migracion a Java
      
      --LPO CDIG Cambio de case por ir por Migracion a Java INCIO
      IF @w_di_estado = @w_est_novigente 
         select @w_acumulado = 0
      ELSE
         select @w_acumulado = @w_valor         
      --LPO CDIG Cambio de case por ir por Migracion a Java FIN
           
       
      /* CALCULAR RUBRO MIPYMES */
      if exists (select 1 from   ca_amortizacion  with (nolock)
      where  am_operacion = @i_operacion
      and    am_dividendo = @w_di_dividendo
      and    am_concepto  = @w_mipymes)
      begin
      
         update ca_amortizacion with (rowlock) set 
         am_cuota     = case when am_pagado > @w_valor     then am_pagado else @w_valor     end,
         am_acumulado = case when am_pagado > @w_acumulado then am_pagado else @w_acumulado end
         where  am_operacion = @i_operacion
         and    am_dividendo = @w_di_dividendo
         and    am_concepto  = @w_mipymes
     
         if @@error <> 0 begin
            close cursor_dividendos_3
            deallocate cursor_dividendos_3
            return 710002
         end
          
      end else begin
     
         if @w_valor >= 0.01 begin
         
            if @w_op_estado = 4 select @w_am_estado = 4
            else select @w_am_estado = @w_di_estado
         
            /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP */
            insert into ca_amortizacion with (rowlock) (
            am_operacion,    am_dividendo,    am_concepto,
            am_cuota,        am_gracia,       am_pagado,
            am_acumulado,    am_estado,       am_periodo,
            am_secuencia)
            values(
            @i_operacion,    @w_di_dividendo, @w_mipymes,
            @w_valor,        0,               0,
            @w_acumulado,    @w_am_estado,    0,
            1 )
        
            if (@@error <> 0) begin
               close cursor_dividendos_3
               deallocate cursor_dividendos_3
               return 710001
            end
            
         end --si valor es mayor a cero
      end
      
      
      /* VERIFICAR SI EL RUBRO MIPYMES TIENE RUBRO ASOCIADO */ 
   
      select @w_valor_asociado = round((@w_valor * @w_porcentaje_asociado / 100.0), @w_num_dec)
      --select @w_acumulado      = case when @w_di_estado = @w_est_novigente then 0 else @w_valor_asociado end  --LPO CDIG Cambio de case por ir por Migracion a Java
      
      --LPO CDIG Cambio de case por ir por Migracion a Java INICIO
      IF @w_di_estado = @w_est_novigente 
         select @w_acumulado = 0
      ELSE
         select @w_acumulado = @w_valor_asociado
      --LPO CDIG Cambio de case por ir por Migracion a Java FIN
      
      
     /* ACTUALIZAR RUBRO ASOCIADO A MIPYMES */
      if exists (select 1 from  ca_amortizacion with (nolock)
      where am_operacion = @i_operacion
      and   am_dividendo = @w_di_dividendo
      and   am_concepto  = @w_asociado)
      begin      
      
         update ca_amortizacion with (rowlock) set 
         am_cuota     = case when am_pagado > @w_valor_asociado then am_pagado else @w_valor_asociado end,
         am_acumulado = case when am_pagado > @w_acumulado      then am_pagado else @w_acumulado      end
         where  am_operacion = @i_operacion
         and    am_dividendo = @w_di_dividendo
         and    am_concepto  = @w_asociado
     
         if (@@error <> 0) begin
             close cursor_dividendos_3
             deallocate cursor_dividendos_3
             return 710002
         end
         
      end else begin
      
         if @w_valor_asociado >= 0.01 begin
         
            if @w_op_estado = 4 select @w_am_estado = 4
            else select @w_am_estado = @w_di_estado

            /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP */
            insert into ca_amortizacion  with (rowlock)(
            am_operacion,       am_dividendo,     am_concepto,
            am_cuota,           am_gracia,        am_pagado,
            am_acumulado,       am_estado,        am_periodo,
            am_secuencia)
            values(
            @i_operacion,       @w_di_dividendo,  @w_asociado,
            @w_valor_asociado,  0,                0,
            @w_acumulado,       @w_am_estado,     0,
            1 )
           
            if @@error <> 0 begin
                close cursor_dividendos_3
                deallocate cursor_dividendos_3
                return 710001
            end
         end
      end
   
      fetch   cursor_dividendos_3
      into    @w_di_dividendo,  @w_di_fecha_ven,     @w_di_estado,      @w_di_fecha_ini
   
   end /*WHILE CURSOR*/
   
   close cursor_dividendos_3
   deallocate cursor_dividendos_3
   
end


return 0
go


