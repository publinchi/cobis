/************************************************************************/
/*   Archivo:      valoratx.sp                                          */
/*   Stored procedure:   sp_valor_atx                                   */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:        Z.BEDON                                       */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Ingreso de abonos                                                  */ 
/*   S: Seleccion de negociacion de abonos automaticos                  */
/*   Q: Consulta de negociacion de abonos automaticos                   */
/*   I: Insercion de abonos                                             */
/*   U: Actualizacion de negociacion de abonos automaticos              */
/*   D: Eliminacion de negociacion de abonos automaticos                */
/************************************************************************/
/*            MODIFICACIONES                                            */
/*   FECHA      AUTOR      RAZON                                        */
/************************************************************************/
use cob_cartera
go



if exists (select 1 from sysobjects where name = 'sp_valor_atx')
   drop proc sp_valor_atx
go
---Inc.15896 Mayo 10 2011
create proc sp_valor_atx
   @s_user                login        = null,
   @s_term                varchar(30)  = null,
   @s_date                datetime     = null,
   @s_sesn                int          = null,
   @s_ofi                 smallint     = null,
   @t_debug               char(1)      = 'N',
   @t_file                varchar(20)  = null,
   @i_ced_ruc             numero       = null,
   @i_banco               cuenta       = null,
   @i_desde_batch         char(1)      = 'N',
   @i_moneda_local        int          = 0,
   @i_decimales_op        tinyint      = 0,
   @i_decimales_nal       tinyint      = 0,
   @i_cotizacion_hoy      float        = null,
   @i_operacionca         int          = null,
   @i_nombre              descripcion  = null,
   @i_num_periodo_d       smallint     = null,
   @i_periodo_d           catalogo     = null,
   @i_dias_anio           smallint     = null,
   @i_op_oficina          int          = null, 
   @i_base_calculo        char(1)      = null,
   @i_tipo_cobro          char(1)      = null,
   @i_cod_cliente         int          = null,
   @i_pago_caja           char(1)      = 'S',
   @i_migrada             cuenta       = null,
   @i_fecha_ult_proceso   datetime     = null,
   @i_op_estado           tinyint      = null,
   @i_op_estado_cobranza  catalogo     = null,
   @i_concepto_cap        catalogo     = 'CAP',
   @i_moneda              smallint     = 0,
   @i_op_monto            money        = null,
   @i_op_plazo            smallint     = null

as declare
   @w_sp_name             descripcion,
   @w_return              int,
   @w_fecha_hoy           datetime,
   @w_banco               cuenta,
   @w_monto               money,
   @w_monto_max           money,
   @w_nombre              descripcion,
   @w_operacionca         int,
   @w_secuencial          int,
   @w_fecha_ult_proceso   datetime,
   @w_est_vigente         tinyint,
   @w_est_novigente       tinyint,
   @w_est_vencido         tinyint,
   @w_ced_ruc             numero,
   @w_cod_cliente         int,
   @w_tipo_cobro          char(1),
   @w_vigente             money,
   @w_vigente1            money,
   @w_vigente2            money,
   @w_vigente3            money,
   @w_vencido             money,
   @w_proyectado          money,
   @w_proyectado1         money,
   @w_proyectado2         money,
   @w_proyectado3         money,
   @w_pago_caja           char(1),
   @w_valor_vencido       money,
   @w_div_vigente         smallint,
   @w_decimales_tasa      tinyint,
   @w_moneda_op           smallint,
   @w_di_fecha_ven        datetime,
   @w_num_periodo_d       smallint,
   @w_periodo_d           catalogo,
   @w_dias_anio           smallint,
   @w_cuota_cap           money,
   @w_valor_int_cap       money,
   @w_base_calculo        char(1),
   @w_num_dec             tinyint,
   @w_ro_porcentaje       float,
   @w_dias                int,
   @w_valor_futuro_int    money,
   @w_vp_cobrar           money,
   @w_tasa_prepago        float,
   @w_vigente_otros       money,
   @w_est_cancelado       smallint,
   @w_moneda_local        smallint,
   @w_cot_mn              money,
   @w_lovigente           money,
   @w_concepto_int        catalogo,
   @w_ro_fpago            char(1),
   @w_ms                  datetime,
   @w_ms_min              int,
   @w_saldo_seg           money,
   @w_migrada             cuenta,
   @w_op_oficina          int,
   @w_op_estado           tinyint,
   @w_div_vigente_1       smallint,
   @w_max_div_vigente     smallint,
   @w_max_div_vencido     smallint,
   @w_op_estado_cobranza  catalogo,
   @w_max_secuencia       int,
   @w_op_naturaleza       char(1),
   @w_op_monto            money,         --Monto Total Credito
   @w_op_plazo            smallint,      --No. total de cuotas
   @w_diasmora            int,           --Dias de mora       
   @w_min_div_vencido     smallint,      --Minimo dividendo vencido
   @w_cuotas_ven          smallint,      --No. cuotas vencidas
   @w_nota                tinyint,       --Nota interna de la operacion
   @w_debug               char(1),
   @w_monto_max_cap       money,
   @w_monto_max_otros     money

--INICIALIZACION DE VARIABLES
select 
@w_sp_name       = 'sp_valor_atx',
@w_fecha_hoy     = convert(varchar, @s_date, 101),
@w_est_vigente   = 1,
@w_est_novigente = 0,
@w_est_vencido   = 2,
@w_est_cancelado = 3,
@w_vigente1      = 0,
@w_vigente2      = 0,
@w_vigente3      = 0,
@w_vencido       = 0,
@w_valor_vencido = 0,
@w_proyectado1   = 0,
@w_proyectado2   = 0,
@w_proyectado3   = 0,
@w_lovigente     = 0,
@w_debug         = 'N',
@w_monto_max_cap = 0,
@w_monto_max_otros = 0



if @i_desde_batch = 'N' begin
   delete ca_valor_atx with (rowlock)
   where  vx_banco = @i_banco
   
   --LECTURA DATOS DE LA OPERACION
   select 
   @w_nombre             = op_nombre,
   @w_operacionca        = op_operacion,
   @w_cod_cliente        = op_cliente,
   @w_fecha_ult_proceso  = op_fecha_ult_proceso,
   @w_moneda_op          = op_moneda,
   @w_num_periodo_d      = op_periodo_int,
   @w_periodo_d          = op_tdividendo,
   @w_dias_anio          = op_dias_anio,
   @w_base_calculo       = op_base_calculo,
   @w_tipo_cobro         = op_tipo_cobro,
   @w_pago_caja          = op_pago_caja,
   @w_migrada            = isnull(op_migrada,op_banco),
   @w_op_oficina         = op_oficina,
   @w_op_estado          = op_estado,
   @w_op_estado_cobranza = op_estado_cobranza,
   @w_op_naturaleza      = op_naturaleza,
   @w_op_monto           = op_monto,
   @w_op_plazo           = op_plazo
   from   ca_operacion
   where  op_banco  = @i_banco

   if @w_op_naturaleza <> 'A'
      return 0
      
   --DECIMALES
   exec sp_decimales
   @i_moneda       = @w_moneda_op, 
   @o_decimales    = @w_num_dec out,
   @o_dec_nacional = @i_decimales_nal out
   
   --CONSULTA CODIGO DE MONEDA LOCAL
   select @w_moneda_local = pa_tinyint
   from   cobis..cl_parametro
   where  pa_nemonico = 'MLO'
   AND    pa_producto = 'ADM'
   
   exec sp_buscar_cotizacion
        @i_moneda     = @w_moneda_op,
        @i_fecha      = @w_fecha_ult_proceso,
        @o_cotizacion = @i_cotizacion_hoy out
end 
else begin

   delete ca_valor_atx with (rowlock)
   where  vx_banco = @i_banco

   select 
   @w_num_dec            = @i_decimales_op,
   @w_moneda_local       = @i_moneda_local,
   @w_operacionca        = @i_operacionca,
   @w_nombre             = @i_nombre,
   @w_num_periodo_d      = @i_num_periodo_d,
   @w_periodo_d          = @i_periodo_d,
   @w_dias_anio          = @i_dias_anio,
   @w_op_oficina         = @i_op_oficina, 
   @w_base_calculo       = @i_base_calculo,
   @w_tipo_cobro         = @i_tipo_cobro,
   @w_cod_cliente        = @i_cod_cliente,
   @w_pago_caja          = @i_pago_caja,
   @w_migrada            = @i_migrada,
   @w_fecha_ult_proceso  = @i_fecha_ult_proceso,
   @w_op_estado          = @i_op_estado,
   @w_op_estado_cobranza = @i_op_estado_cobranza,
   @w_moneda_op          = @i_moneda,
   @w_op_monto           = @i_op_monto,
   @w_op_plazo           = @i_op_plazo
end

select 
@w_concepto_int   = ro_concepto,
@w_ro_fpago       = ro_fpago,
@w_decimales_tasa = isnull(ro_num_dec,2),
@w_ro_porcentaje  = ro_porcentaje
from   ca_rubro_op with (nolock)
where  ro_operacion  = @w_operacionca
and    ro_tipo_rubro = 'I'
and    ro_fpago      in ('A', 'P')

--CEDULA DEL CLIENTE
select @w_ced_ruc = en_ced_ruc
from   cobis..cl_ente with (nolock)
where  en_ente = @w_cod_cliente

if @@rowcount = 0 return  701025

--DATOS DE LOS DIVIDENDOS
select 
@w_div_vigente  = di_dividendo,
@w_di_fecha_ven = di_fecha_ven
from   ca_dividendo with (nolock)
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vigente

--DIVIDENDO VIGENTE
select @w_div_vigente = isnull(@w_div_vigente,0)

--- SELECCION DE LA MAXIMA SECUENCIA DEL RUBRO  PARA VALOR PRESENTE
if @w_div_vigente > 0 begin
   
   select @w_max_secuencia = max(am_secuencia) 
   from   ca_amortizacion with (nolock)
   where  am_operacion = @w_operacionca
   and    am_dividendo = @w_div_vigente
   and    am_concepto  = 'INT'
   
   if @w_max_secuencia > 1
      select @w_tipo_cobro = 'A'
end

If exists(Select 1 from ca_traslado_interes with (nolock)
          Where ti_operacion = @w_operacionca
          And  ti_estado     = 'P')
begin
    select @w_tipo_cobro = 'A'
end

--DIVIDENDO VIGENTE + 1
select @w_div_vigente_1 = @w_div_vigente + 1

--MAXIMO DIVIDENDO VENCIDO

  select @w_max_div_vencido = isnull(max(di_dividendo), 0)
  from   ca_dividendo with (nolock)
  where  di_operacion = @w_operacionca
  and    di_estado    = @w_est_vencido

  if @w_div_vigente = 0
     select @w_max_div_vigente = @w_max_div_vencido
  else
     select @w_max_div_vigente = @w_div_vigente

--VALORES VENCIDOS PARA ANTES DEL VENCIMIENTO TOTAL
if @w_div_vigente > 0 begin
   select @w_vencido = isnull(sum(am_cuota + am_gracia - am_pagado),0) --isnull(sum(am_cuota - am_pagado),0)
   from   ca_rubro_op with (nolock), ca_dividendo with (nolock), ca_amortizacion with (nolock)
   where  ro_operacion = @w_operacionca
   and    di_operacion = ro_operacion
   and    di_estado    = @w_est_vencido
   and    am_operacion = di_operacion
   and    am_dividendo = (di_dividendo + charindex (ro_fpago, 'A'))
   and    am_concepto  = ro_concepto
   and    am_dividendo > 0
   and    am_estado   != @w_est_cancelado
   and    am_secuencia > 0

end
else begin
   --SI LA OBLIGACIONE STA TOTALMENTE VENCIDA, LOS VALORES SE SACAN COMPLETAMENTE
   select @w_vencido = isnull(sum(am_cuota + am_gracia - am_pagado),0) --isnull(sum(am_cuota - am_pagado),0)
   from   ca_rubro_op with (nolock), ca_dividendo with (nolock), ca_amortizacion with (nolock)
   where  ro_operacion = @w_operacionca
   and    di_operacion = ro_operacion
   and    di_estado    = @w_est_vencido
   and    am_operacion = di_operacion
   and    am_dividendo = di_dividendo 
   and    am_concepto  = ro_concepto
   and    am_estado   != @w_est_cancelado
   and    am_dividendo > 0
   and    am_secuencia > 0
end


if @w_tipo_cobro in ('P','A') begin
   select 
   @w_vigente1 = @w_vigente1 + isnull(sum((abs(am_cuota     + am_gracia - am_pagado)+am_cuota     + am_gracia - am_pagado)/2.0),0),
   @w_vigente2 = @w_vigente2 + isnull(sum((abs(am_acumulado + am_gracia - am_pagado)+am_acumulado + am_gracia - am_pagado)/2.0),0)
   from   ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vigente
   and    di_operacion = am_operacion 
   and    am_dividendo = di_dividendo + charindex (ro_fpago, 'A')
   and    am_concepto  = ro_concepto
   and    am_operacion = ro_operacion
   and    am_dividendo > 0
   and    am_secuencia > 0

   select @w_vigente3 = 0   

end 
else begin
   
   select @w_vigente1 = @w_vigente1 + isnull(sum(am_cuota     + am_gracia - am_pagado),0)
   from   ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
   where  di_operacion   = @w_operacionca
   and    di_estado      = @w_est_vigente
   and    di_operacion   = am_operacion
   and    am_dividendo   = di_dividendo + charindex (ro_fpago, 'A')
   and    am_concepto    = ro_concepto
   and    am_operacion   = ro_operacion
   and    ro_tipo_rubro <> 'I'
   and    am_dividendo   > 0
   and    am_secuencia   > 0

   select 
   @w_vigente2 = 0,
   @w_vigente3 = 0
   
end

if @w_tipo_cobro = 'P'
   select 
   @w_lovigente     = isnull(@w_vigente1,0),
   @w_valor_vencido = isnull(@w_vencido,0)

if @w_tipo_cobro = 'A'
   select 
   @w_lovigente     = isnull(@w_vigente2,0),
   @w_valor_vencido = isnull(@w_vencido,0)

if @w_tipo_cobro = 'E' begin

   select @w_valor_vencido = isnull(@w_vencido,0)

   select @w_valor_futuro_int = isnull(sum(am_cuota + am_gracia - am_pagado) ,0)
   from   ca_amortizacion  with (nolock)
   where  am_operacion = @w_operacionca
   and    am_dividendo = @w_div_vigente
   and    am_concepto  = @w_concepto_int
   and    am_estado   != @w_est_cancelado   
   and    am_secuencia > 0
       
   if @w_di_fecha_ven > @w_fecha_ult_proceso   and @w_div_vigente > 0  and @w_valor_futuro_int  > 0 begin
      if @w_ro_fpago = 'P' begin --VENCIDOS 

         select @w_dias = datediff(dd, @w_fecha_ult_proceso, @w_di_fecha_ven)

         if @w_dias_anio = 360 begin
            exec sp_dias_cuota_360
            @i_fecha_ini = @w_fecha_ult_proceso,
            @i_fecha_fin = @w_di_fecha_ven,
            @o_dias      = @w_dias out
         end

         --TASA EQUIVALENTE A LOS DIAS QUE FALTAN
         exec @w_return    = sp_conversion_tasas_int
         @i_dias_anio      = @w_dias_anio,
         @i_base_calculo   = @w_base_calculo,
         @i_periodo_o      = @w_periodo_d,
         @i_modalidad_o    = 'V',
         @i_num_periodo_o  = @w_num_periodo_d,
         @i_tasa_o         = @w_ro_porcentaje, 
         @i_periodo_d      = 'D',
         @i_modalidad_d    = 'A', --LA TASA EQUIVALENTE DEBE SER ANTICIPADA
         @i_num_periodo_d  = @w_dias,
         @i_num_dec        = @w_decimales_tasa,
         @o_tasa_d         = @w_tasa_prepago output
         
         if @w_return <> 0 
            return @w_return 
         
         select @w_cuota_cap  = isnull(am_cuota - am_pagado ,0)
         from   ca_amortizacion with (nolock), ca_rubro_op  with (nolock)
         where  am_operacion  = @w_operacionca
         and    am_dividendo  = @w_div_vigente
         and    ro_operacion  = am_operacion
         and    ro_concepto   = am_concepto
         and    ro_tipo_rubro = 'C'
         and    am_dividendo  > 0
         and    am_secuencia  > 0

         select  @w_valor_int_cap = @w_valor_futuro_int + @w_cuota_cap

         select @w_vp_cobrar = (@w_tasa_prepago * @w_valor_int_cap) / (100 * 360) * @w_dias
         select @w_vp_cobrar = round((@w_valor_futuro_int - @w_vp_cobrar),@w_num_dec)
         select @w_vigente3  = @w_vp_cobrar

      end 
      else begin --ANTICIPADOS
         
         select @w_vigente3 = isnull(sum(am_cuota + am_gracia - am_pagado),0)
         from   ca_amortizacion with (nolock)
         where  am_operacion = @w_operacionca
         and    am_dividendo = @w_div_vigente_1
         and    am_concepto  = @w_concepto_int  ---Intereses
         and    am_estado   != @w_est_cancelado
         and    am_secuencia > 0

      end
      select @w_lovigente = @w_vigente3 + @w_vigente1          

   end 
   else begin
      select @w_vigente3 = @w_vigente1 + isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_amortizacion with (nolock), ca_dividendo with (nolock), ca_rubro_op with (nolock)
      where  di_operacion  = @w_operacionca
      and    di_estado     = @w_est_vigente
      and    di_operacion  = am_operacion
      and    am_dividendo  = di_dividendo + charindex (ro_fpago, 'A')
      and    am_concepto   = ro_concepto
      and    am_operacion  = ro_operacion
      and    ro_tipo_rubro = 'I'
      and    am_estado   != @w_est_cancelado     
      and    am_dividendo  > 0
      and    am_secuencia  > 0
          
      select @w_lovigente = @w_vigente3 
        
   end --FIN VP
end

--MINIMO DIVIDENDO VENCIDO
select @w_min_div_vencido = min(di_dividendo)
from   cob_cartera..ca_dividendo with (nolock)
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vencido

select @w_min_div_vencido = isnull(@w_min_div_vencido,0)

--DIAS DE MORA
select @w_diasmora = datediff(dd,di_fecha_ven, @w_fecha_ult_proceso)
from   cob_cartera..ca_dividendo with (nolock)
where  di_operacion = @w_operacionca
and    di_dividendo = @w_min_div_vencido

select @w_diasmora = isnull(@w_diasmora,0)

--CUOTAS VENCIDAS
select 
@w_cuotas_ven  = count(di_dividendo)
from  ca_dividendo, ca_operacion 
where di_operacion = @w_operacionca
  and di_estado    = @w_est_vencido


--NOTA INTERNA
select @w_nota = ci_nota                                   
from   cob_credito..cr_califica_int_mod  with (nolock)           
where  ci_banco = @i_banco

--CONSULTA SALDO DE CANCELACION



select 
@w_monto_max_cap = isnull(sum(am_acumulado - am_pagado + am_gracia),0)
from  ca_operacion, ca_amortizacion,ca_rubro_op
where op_operacion = @w_operacionca
and am_operacion = op_operacion
and ro_operacion = am_operacion
and ro_concepto = am_concepto
and am_estado <> @w_est_cancelado
and ro_tipo_rubro = 'C'


select 
@w_monto_max_otros = isnull(sum(am_acumulado - am_pagado + am_gracia),0)
from  ca_operacion, ca_amortizacion,ca_rubro_op,ca_dividendo
where op_operacion = @w_operacionca
and am_operacion = op_operacion
and ro_operacion = am_operacion
and ro_concepto = am_concepto
and am_estado <> @w_est_cancelado
and ro_tipo_rubro <> 'C'
and di_operacion = am_operacion
and di_dividendo = am_dividendo
and di_dividendo <= @w_max_div_vigente

select @w_monto_max = isnull(@w_monto_max_cap,0) + isnull(@w_monto_max_otros,0)

/* INCLUIR CALCULO DE SALDO DE HONORARIOS */
exec @w_return    = sp_saldo_honorarios
@i_banco          = @i_banco,
@i_saldo_cap      = @w_monto_max,
@i_num_dec        = @w_num_dec,
@o_saldo_tot      = @w_monto_max out

if @w_return <> 0 
   return @w_return 

if @w_moneda_op <> @w_moneda_local begin
   select @w_monto = ceiling(  (@w_lovigente + @w_valor_vencido) * @i_cotizacion_hoy )
   
   --PASAR LOS VALORES A MONEDA NACIONAL
   select @w_lovigente     = ceiling(@w_lovigente * @i_cotizacion_hoy),
          @w_valor_vencido = ceiling(@w_valor_vencido * @i_cotizacion_hoy),
          @w_monto_max     = ceiling(@w_monto_max * @i_cotizacion_hoy)
end 
ELSE
   select @w_monto = isnull(@w_lovigente + @w_valor_vencido,0)

--SOLO INSERTAR SI HAY VALORES  EN AL MENOS UNA VARIABLE
if @w_monto >= 0 and @w_valor_vencido >= 0  and  @w_monto_max >= 0 begin -- INSERCION DE CA_VALOR_ATX

   select @w_nombre = substring(@w_nombre,1,35)

   insert into ca_valor_atx with (rowlock)
   (vx_oficina,             vx_banco,         vx_ced_ruc,    
    vx_nombre,              vx_monto,         vx_monto_max,  
    vx_moneda,              vx_valor_vencido, vx_migrada,    
    vx_estado_cobranza,     vx_monto_total,   vx_cuotas,     
    vx_ven_vigente,         vx_dias_mora,     vx_cuotas_ven, 
    vx_estado,              vx_nota)
   values                   
   (@w_op_oficina,          @i_banco,         convert(varchar(9),@w_ced_ruc),    
    @w_nombre,              @w_monto,         @w_monto_max,  
    @w_moneda_local,        @w_valor_vencido, @w_migrada,    
    @w_op_estado_cobranza,  @w_op_monto,      @w_op_plazo,   
    @w_di_fecha_ven,        @w_diasmora,      @w_cuotas_ven, 
    @w_op_estado,           @w_nota)
   
   if @@error != 0 
      return 710308
      
end

return 0
go

