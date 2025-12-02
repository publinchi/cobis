/************************************************************************/
/*   Archivo:      valatxtp.sp                                          */
/*   Stored procedure:   sp_valor_atx_tmp                               */
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
/*   Enero 1998      Z.Bedon          Emision Inicial                   */
/*      Enero 2003      E.Pelaez         Los calculo almacenados   en   */
/*                                       ca_valor_atx sean los mismos   */
/*                                       mostrados por plataforma       */
/************************************************************************/
use cob_cartera
go

/* CREACION DE TABLAS DE TRABAJO */
CREATE TABLE #ca_amortizacion (
am_operacion         int      NOT NULL,
am_dividendo         smallint NOT NULL,
am_concepto          varchar (64) NOT NULL,
am_estado            tinyint  NOT NULL, 
am_periodo           tinyint  NOT NULL,              
am_cuota             money    NOT NULL,
am_gracia            money    NOT NULL,
am_pagado            money    NOT NULL,
am_acumulado         money    NOT NULL,	
am_secuencia         tinyint  NOT NULL
)

--CREATE UNIQUE NONCLUSTERED INDEX #ca_amortizacion_1 on #ca_amortizacion(am_operacion, am_dividendo, am_concepto, am_secuencia)
CREATE UNIQUE INDEX ca_amortizacion_1 on #ca_amortizacion(am_operacion, am_dividendo, am_concepto, am_secuencia)


CREATE TABLE #ca_dividendo (
di_operacion         int      NOT NULL,
di_dividendo         smallint NOT NULL,
di_fecha_ini         datetime NOT NULL,
di_fecha_ven         datetime NOT NULL,
di_de_capital        char(1)  NOT NULL,
di_de_interes        char(1)  NOT NULL,
di_gracia            smallint NOT NULL,
di_gracia_disp       smallint NOT NULL,
di_estado            tinyint  NOT NULL,
di_dias_cuota        int      NOT NULL,
di_intento	     tinyint  NOT NULL,
di_prorroga          char(1)  NOT NULL 	
)
--CREATE UNIQUE NONCLUSTERED INDEX #ca_dividendo_1 on #ca_dividendo(di_operacion,di_dividendo)
CREATE UNIQUE INDEX ca_dividendo_1 on #ca_dividendo(di_operacion,di_dividendo)


CREATE TABLE #ca_rubro_op (
ro_operacion                    int         NOT NULL,
ro_concepto                     varchar (64) NOT NULL,
ro_tipo_rubro                   char(1)     NOT NULL,
ro_fpago                        char(1)     NOT NULL,
ro_prioridad                    tinyint     NOT NULL,
ro_paga_mora                    char(1)     NOT NULL,
ro_provisiona                   char(1)     NOT NULL,
ro_signo                        char(1)     NULL,
ro_factor                       float       NULL,
ro_referencial                  varchar (64)NULL,
ro_signo_reajuste               char(1)     NULL,
ro_factor_reajuste              float       NULL,
ro_referencial_reajuste         varchar (64)    NULL,
ro_valor                        money       NOT NULL,
ro_porcentaje                   float       NOT NULL,
ro_porcentaje_aux               float       NOT NULL,
ro_gracia                       money       NULL,
ro_concepto_asociado            varchar (64)    NULL,
ro_redescuento                  float       NULL,
ro_intermediacion               float       NULL,
ro_principal                    char(1)     NOT NULL,
ro_porcentaje_efa               float       NULL,
ro_garantia                     money       NOT NULL,
ro_tipo_puntos                  char(1)     NULL,
ro_saldo_op                     char(1)     NULL,  
ro_saldo_por_desem              char(1)     NULL,  
ro_base_calculo                 money       NULL,  
ro_num_dec			tinyint     NULL,
ro_limite                       char(1)     NULL,
ro_iva_siempre			char(1)     NULL,
ro_monto_aprobado		char(1)	    NULL,
ro_porcentaje_cobrar		float 	    NULL,
ro_tipo_garantia                varchar(64) NULL,
ro_nro_garantia                 varchar (64)      NULL,
ro_porcentaje_cobertura         char(1)     NULL,
ro_valor_garantia               char(1)     NULL,
ro_tperiodo                     varchar (64)    NULL,
ro_periodo                      smallint    NULL,
ro_tabla                        varchar(30) NULL,
ro_saldo_insoluto               char(1)     NULL,
ro_calcular_devolucion          char(1)     NULL
)
--CREATE UNIQUE NONCLUSTERED INDEX #ca_rubro_op_1 on #ca_rubro_op(ro_operacion,ro_concepto)
CREATE UNIQUE INDEX ca_rubro_op_1 on #ca_rubro_op(ro_operacion,ro_concepto)


if exists (select * from sysobjects where name = 'sp_valor_atx_tmp')
   drop proc sp_valor_atx_tmp
go

create proc sp_valor_atx_tmp
@s_user              login       = null,
@s_term              varchar(30) = null,
@s_date              datetime    = null,
@s_sesn              int         = null,
@s_ofi               smallint    = null,
@t_debug             char(1)     = 'N',
@t_file              varchar(20) = null,
@i_ced_ruc           numero      = null,
@i_banco             cuenta      = null,
@i_desde_batch       char(1)     = 'N',
@i_moneda_local      int         = 0,
@i_decimales_op      tinyint     = 0,
@i_decimales_nal     tinyint     = 0,
@i_cotizacion_hoy    float       = null,
@i_operacionca       int         = null,
@i_nombre            descripcion = null,
@i_num_periodo_d     smallint    = null,
@i_periodo_d         catalogo    = null,
@i_dias_anio         smallint    = null,
@i_op_oficina        int         = null, 
@i_base_calculo      char(1)     = null,
@i_tipo_cobro        char(1)     = null,
@i_cod_cliente       int         = null,
@i_pago_caja         char(1)     = null,
@i_migrada           cuenta      = null,
@i_fecha_ult_proceso datetime    = null,
@i_op_estado         tinyint     = null,
@i_concepto_cap      catalogo    = null
as

declare
@w_sp_name           descripcion,
@w_return            int,
@w_fecha_hoy         datetime,
@w_banco             cuenta,
@w_monto             money,
@w_monto_max         money,
@w_moneda            tinyint,
@w_nombre            descripcion,
@w_operacionca       int,
@w_secuencial        int,
@w_fecha_ult_proceso datetime,
@w_est_vigente       tinyint,
@w_est_novigente     tinyint,
@w_est_vencido       tinyint,
@w_ced_ruc           numero,
@w_cod_cliente       int,
@w_tipo_cobro        char(1),
@w_vigente           money,
@w_vigente1          money,
@w_vigente2          money,
@w_vigente3          money,
@w_vencido           money,
@w_proyectado        money,
@w_proyectado1       money,
@w_proyectado2       money,
@w_proyectado3       money,
@w_pago_caja         char(1),
@w_valor_vencido     money,
@w_div_vigente       smallint,
@w_decimales_tasa    tinyint,
@w_moneda_op         smallint,
@w_di_fecha_ven      datetime,
@w_num_periodo_d     smallint,
@w_periodo_d         catalogo,
@w_dias_anio         smallint,
@w_cuota_cap         money,
@w_valor_int_cap     money,
@w_base_calculo      char(1),
@w_num_dec           tinyint,
@w_ro_porcentaje     float,
@w_dias              int,
@w_valor_futuro_int  money,
@w_vp_cobrar         money,
@w_tasa_prepago      float,
@w_vigente_otros     money,
@w_est_cancelado     smallint,
@w_moneda_local      smallint,
@w_cot_mn            money,
@w_lovigente         money,
@w_concepto_int      catalogo,
@w_ro_fpago          char(1),
@w_ms                datetime,
@w_ms_min            int,
@w_div_min_vencido   int,
@w_div_max_vencido   int,
@w_saldo_seg         money,
@w_migrada           cuenta,
@w_op_oficina        int,
@w_op_estado         tinyint

-- ESTE PROGRAMA NO SE USA, NI SE DEBE USAR, ESTA DESACTUALIZADO
return 0

select @w_ms_min = 8

--INICIALIZACION DE VARIABLES
select 
@w_sp_name       = 'sp_valor_atx_tmp',
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
@w_lovigente     = 0

--VALIDAR SI OPERACION ACEPTA PAGO POR CAJA
if @w_pago_caja = 'N' begin

   if exists(select 1 from ca_valor_atx
             where vx_banco = @i_banco)

      delete ca_valor_atx
      where  vx_banco = @i_banco

   return 0

end

if @i_desde_batch = 'N' begin

   delete ca_valor_atx
   where  vx_banco = @i_banco

   --LECTURA DATOS DE LA OPERACION
   select 
   @w_nombre            = op_nombre,
   @w_operacionca       = op_operacion,
   @w_cod_cliente       = op_cliente,
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
   @w_moneda_op         = op_moneda,
   @w_num_periodo_d     = op_periodo_int,
   @w_periodo_d         = op_tdividendo,
   @w_dias_anio         = op_dias_anio,
   @w_base_calculo      = op_base_calculo,
   @w_tipo_cobro        = op_tipo_cobro,
   @w_pago_caja         = op_pago_caja,
   @w_migrada           = isnull(op_migrada,op_banco),
   @w_op_oficina        = op_oficina,
   @w_op_estado         = op_estado
   from   ca_operacion
   where  op_banco  = @i_banco

   --DECIMALES
   exec sp_decimales
   @i_moneda    = @w_moneda_op, 
   @o_decimales = @w_num_dec out
   
   
   --CONSULTA CODIGO DE MONEDA LOCAL
   select @w_moneda_local = pa_tinyint
   from   cobis..cl_parametro
   where  pa_nemonico = 'MLO'
   AND    pa_producto = 'ADM'
   
   exec sp_buscar_cotizacion
   @i_moneda     = @w_moneda_op,
   @i_fecha      = @w_fecha_ult_proceso,
   @o_cotizacion = @i_cotizacion_hoy out
   
   exec sp_decimales
   @i_moneda = @w_moneda_local,
   @o_decimales = @i_decimales_nal

end else begin

   select 
   @w_num_dec           = @i_decimales_op,
   @w_moneda_local      = @i_moneda_local,
   @w_operacionca       = @i_operacionca,
   @w_nombre            = @i_nombre,
   @w_num_periodo_d     = @i_num_periodo_d,
   @w_periodo_d         = @i_periodo_d,
   @w_dias_anio         = @i_dias_anio,
   @w_op_oficina        = @i_op_oficina, 
   @w_base_calculo      = @i_base_calculo,
   @w_tipo_cobro        = @i_tipo_cobro,
   @w_cod_cliente       = @i_cod_cliente,
   @w_pago_caja         = @i_pago_caja,
   @w_migrada           = @i_migrada,
   @w_fecha_ult_proceso = @i_fecha_ult_proceso,
   @w_op_estado         = @i_op_estado

end
/*
exec sp_relojlca 'valoratx',1,'1','B'
*/

select 
@w_concepto_int = ro_concepto,
@w_ro_fpago     = ro_fpago
from   #ca_rubro_op
where  ro_operacion = @w_operacionca
and    ro_tipo_rubro = 'I'
and    ro_fpago in ('A', 'P')

--CEDULA DEL CLIENTE
select @w_ced_ruc = en_ced_ruc
from   cobis..cl_ente
where  en_ente = @w_cod_cliente

if @@rowcount = 0
   return  701025

--DATOS DE LOS DIVIDENDOS
select @w_div_vigente = isnull(di_dividendo,0)
from   #ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vigente

select @w_div_min_vencido = min(di_dividendo)
from   #ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vencido

select @w_div_max_vencido = max(di_dividendo)
from   #ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vencido

select @w_di_fecha_ven = di_fecha_ven
from   #ca_dividendo
where  di_operacion = @w_operacionca
and    di_dividendo = @w_div_vigente
and    di_estado    = @w_est_vigente

--VALORES VENCIDOS
select @w_vencido = isnull(sum(am_cuota - am_pagado),0)
from   #ca_rubro_op, #ca_dividendo, #ca_amortizacion
where  ro_operacion = @w_operacionca
and    di_operacion = ro_operacion
and    di_estado    = @w_est_vencido
and    am_operacion = di_operacion
and    am_dividendo = (di_dividendo + charindex (ro_fpago, 'A'))
and    am_concepto  = ro_concepto

if @w_tipo_cobro in ('P','A') begin

   select 
   @w_vigente1 = @w_vigente1 + isnull(sum(am_cuota     + am_gracia - am_pagado),0),
   @w_vigente2 = @w_vigente2 + isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   #ca_amortizacion, #ca_dividendo, #ca_rubro_op
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vigente
   and    am_operacion = @w_operacionca
   and    am_dividendo = di_dividendo + charindex (ro_fpago, 'A')
   and    am_concepto  = ro_concepto
   and    am_operacion = ro_operacion
 
   select @w_vigente3 = 0   

end else begin

   select @w_vigente1 = @w_vigente1 + isnull(sum(am_cuota     + am_gracia - am_pagado),0)
   from   #ca_amortizacion, #ca_dividendo, #ca_rubro_op
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vigente
   and    am_operacion = @w_operacionca
   and    am_dividendo = di_dividendo + charindex (ro_fpago, 'A')
   and    am_concepto  = ro_concepto
   and    am_operacion = ro_operacion
   and    ro_tipo_rubro <> 'I'
   
   select 
   @w_vigente2 = 0,
   @w_vigente3 = 0

end

if @w_tipo_cobro = 'P'
   select 
   @w_lovigente = isnull(@w_vigente1,0),
   @w_valor_vencido = isnull(@w_vencido,0)

if @w_tipo_cobro = 'A'
   select 
   @w_lovigente = isnull(@w_vigente2,0),
   @w_valor_vencido = isnull(@w_vencido,0)
/*
exec sp_relojlca 'valoratx',1,'2'
*/
if @w_tipo_cobro = 'E' begin

   select @w_valor_vencido = isnull(@w_vencido,0)

   if @w_di_fecha_ven > @w_fecha_ult_proceso   and @w_div_vigente > 0 begin
 
     

      if @w_ro_fpago = 'P' begin  --VENCIDOS

         select 
         @w_ro_porcentaje  = ro_porcentaje,
         @w_decimales_tasa = ro_num_dec
         from   #ca_rubro_op
         where  ro_operacion = @w_operacionca
         and    ro_concepto  = @w_concepto_int
         
         select @w_dias = datediff(dd, @w_fecha_ult_proceso, @w_di_fecha_ven)
	 /*
         exec sp_relojlca 'valoratx',1,'3'
	 */
         if @w_dias_anio = 360 begin

            exec sp_dias_cuota_360
            @i_fecha_ini = @w_fecha_ult_proceso,
            @i_fecha_fin = @w_di_fecha_ven,
            @o_dias      = @w_dias out

         end
	/*
        exec sp_relojlca 'valoratx',1,'4'
	*/
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
	 /* 
         exec sp_relojlca 'valoratx',1,'5'
	 */
         select @w_valor_futuro_int = isnull(sum(am_cuota + am_gracia - am_pagado) ,0)
         from   #ca_amortizacion 
         where  am_operacion = @w_operacionca
         and    am_dividendo = @w_div_vigente
         and    am_concepto  = @w_concepto_int
       
         select @w_cuota_cap  = isnull(am_cuota - am_pagado ,0)
         from   #ca_amortizacion, #ca_rubro_op 
         where  am_operacion  = @w_operacionca
         and    am_operacion  = ro_operacion
         and    am_concepto   = ro_concepto
         and    ro_tipo_rubro = 'C'
         and    am_dividendo  = @w_div_vigente
         
         select  @w_valor_int_cap = @w_valor_futuro_int + @w_cuota_cap
	 /*
         exec sp_relojlca 'valoratx',1,'6'
	 */
         exec @w_return      = sp_calculo_valor_presente
         @i_tasa_prepago     = @w_tasa_prepago,
         @i_valor_int_cap    = @w_valor_int_cap,
         @i_dias             = @w_dias,
         @i_valor_futuro_int = @w_valor_futuro_int,
         @i_numdec_op        = @w_num_dec,
         @o_monto            = @w_vp_cobrar  output
              
         select @w_vigente3 = @w_vp_cobrar
/*
exec sp_relojlca 'valoratx',1,'7'
*/

      end else begin --ANTICIPADOS

         select @w_vigente3 = isnull(sum(am_cuota + am_gracia - am_pagado),0)
         from   #ca_amortizacion
         where  am_operacion = @w_operacionca
         and    am_dividendo = @w_div_vigente + 1
         and    am_concepto  = @w_concepto_int

      end

   end else begin

     select @w_vigente3 = @w_vigente1 + isnull(sum(am_cuota + am_gracia - am_pagado),0)
     from   #ca_amortizacion, #ca_dividendo, #ca_rubro_op
     where  di_operacion = @w_operacionca
     and    di_estado    = @w_est_vigente
     and    am_operacion = @w_operacionca
     and    am_dividendo = di_dividendo + charindex (ro_fpago, 'A')
     and    am_concepto  = ro_concepto
     and    am_operacion = ro_operacion
     and    ro_tipo_rubro = 'I'

   end --FIN VP
   
   select @w_lovigente = @w_vigente3 + @w_vigente1

end
/*
exec sp_relojlca 'valoratx',1,'8'
*/
--CONSULTA SALDO DE CANCELACION
if @w_div_vigente > 0 

   exec @w_return       = sp_calcula_saldo_atx
   @i_operacion         = @w_operacionca,
   @i_tipo_pago         = @w_tipo_cobro,
   @i_num_periodo_d     = @w_num_periodo_d, 
   @i_periodo_d         = @w_periodo_d,
   @i_fecha_ult_proceso = @w_fecha_ult_proceso,
   @i_moneda            = @w_moneda,       
   @i_op_estado         = @w_op_estado,    
   @i_dias_anio         = @w_dias_anio,    
   @i_base_calculo      = @w_base_calculo, 
   @i_decimales_op      = @w_num_dec,
   @i_div_vigente       = @w_div_vigente,
   @i_di_fecha_ven      = @w_di_fecha_ven, 
   @i_concepto_cap      = @i_concepto_cap,
   @i_max_div_vencido   = @w_div_max_vencido,
   @i_max_div_vigente   = @w_div_vigente,
   @i_atx               = 'S',
   @o_saldo             = @w_monto_max out

else
   select @w_monto_max =  @w_valor_vencido
/*
exec sp_relojlca 'valoratx',1,'9'
*/
if @w_moneda_op <> @w_moneda_local begin

   --PASAR LOS VALORES A MONEDA NACIONAL
   select 
   @w_lovigente     = round(@w_lovigente * @i_cotizacion_hoy, @i_decimales_nal),
   @w_valor_vencido = round(sum((@w_valor_vencido * @i_cotizacion_hoy) ), @i_decimales_nal),
   @w_monto_max     = round(@w_monto_max * @i_cotizacion_hoy, @i_decimales_nal)

end 

select @w_monto = isnull(@w_lovigente + @w_valor_vencido,0)
/*
exec sp_relojlca 'valoratx',1,'10'
*/
--SOLO INSERTAR SI HAY VALORES  EN AL MENOS UNA VARIABLE
if @w_monto >= 0 and @w_valor_vencido >= 0  and  @w_monto_max > 0 begin -- INSERCION DE CA_VALOR_ATX

   begin tran

  --PASAR LOS VALORES A MONEDA NACIONAL


      insert into ca_valor_atx
            (vx_oficina,       vx_banco,      vx_ced_ruc,    vx_nombre,
             vx_monto,         vx_monto_max,  vx_moneda,
             vx_valor_vencido, vx_migrada)
      values(@w_op_oficina,    @i_banco,      @w_ced_ruc,    @w_nombre,
             @w_monto,         @w_monto_max,  @w_moneda_local,
             @w_valor_vencido, @w_migrada)
   
      if @@error != 0
         return 710308

   commit tran

end
/*
exec sp_relojlca 'valoratx',1,'11'
*/
return 0
go

