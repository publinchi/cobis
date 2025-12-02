/************************************************************************/
/*   Archivo:              contrmor.sp                                  */
/*   Stored procedure:     sp_control_tasa_mora                         */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Christian De la Cruz                         */
/*   Fecha de escritura:   27/Mayo/98                                   */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                                PROPOSITO                             */
/*   Controla si la tasa total de interes por mora a cobrarse,sea       */
/*      la menor de entre: el doble del interes corriente del prestamo, */
/*      la tasa maxima de mora, y la pactada con el cliente             */
/*                             CAMBIOS                                  */
/*      FECHA                  AUTOR                 CAMBIO             */
/*      sep-04-2001            EPB                   Personalizacion BT */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_control_tasa_mora')
   drop proc sp_control_tasa_mora
go

create proc sp_control_tasa_mora
   @i_operacionca       int,
   @i_fecha             datetime,
   @i_dividendo         int = null,
   @i_parametro_mora    catalogo,
   @i_codigo_tmm        catalogo,
   @i_codigo_tmmex      catalogo,
   @i_moneda_nacional   smallint,
   @i_moneda_uvr        smallint,
   @i_periodo_anual     char(1),
   @o_nueva_tasa        float output
as
declare
   @w_sp_name           descripcion,
   @w_return            int,
   @w_porcentaje        float,
   @w_forma_pago        char(1),
   @w_modalidad         char(1),
   @w_periodicidad      char(1),
   @w_tasa_efe_anual    float,
   @w_tmm_valor         float,
   @w_tasa_int_efa      float,
   @w_dias_anio         smallint,
   @w_base_calculo      char(1),
   @w_valor_aplicar     catalogo,
   @w_sector            catalogo,
   @w_tasa_referencial  varchar(10),
   @w_concepto_tmm      varchar(10),
   @w_fecha_ult_proc    datetime,
   @w_tmm_efa           float,
   @w_secuencial        int,
   @w_signo             char(1),
   @w_factor            float,
   @w_clase             char(1),
   @w_tasa_base         catalogo,
   @w_referencial       catalogo,
   @w_secuencial_ref    int,
   @w_valor             float,
   @w_modalidad_tmm     char(1),
   @w_periodicidad_tmm  char(1),
   @w_tasa_mora_efa     float,
   @w_tasa_menor        float,
   @w_factor_distr      float,
   @w_tasa_efa          float,
   @w_ts_porcentaje     float,
   @w_porcentaje_efa    float,
   @w_calcular_antes    char(1),
   @w_operacionca       int,
   @w_di_fecha_ven      datetime,
   @w_num_dec_tapl      tinyint,
   @w_moneda            int,
   @w_tipo_tasa         char(1),
   @w_tipo_puntos_op    char(1),
   @w_tipo_puntos_def   char(1),
   @w_tipopuntos        char(1),
   @w_tasa_efe_aux      float,
   @w_max_secuencial    int,
   @w_tasa_aplicar      catalogo,
   @w_ts_referencial    catalogo,
   @w_fecha             datetime,
   @w_valor_tasa_ref     float,
   @w_fecha_tasaref      datetime,
   @w_ts_tasa_ref        catalogo


-- Captura nombre de Stored Procedure
select @w_sp_name = 'sp_control_tasa_mora'
select @w_tasa_mora_efa = 0
select @w_tasa_int_efa = 0,
       @w_num_dec_tapl = null

-- PERIODICIDAD ORIGEN DE LA OPERACION ES LA PERIODICIDAD ORIGEN DE LOS RUBROS EXISTENTES
select @w_periodicidad   = op_tdividendo,
       @w_dias_anio      = op_dias_anio,
       @w_base_calculo   = op_base_calculo,
       @w_sector         = op_sector,
       @w_fecha_ult_proc = op_fecha_ult_proceso,
       @w_moneda         = op_moneda
from   ca_operacion
where  op_operacion = @i_operacionca

-- PARA EL RUBRO IMO
select @w_tasa_aplicar    = ro_referencial
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_concepto  = @i_parametro_mora

select @w_clase          = va_clase,
       @w_ts_referencial = va_tipo
from   ca_valor
where  va_tipo = @w_tasa_aplicar


if @w_clase = 'V'
   select @w_ts_referencial = @w_tasa_aplicar

-- JCQ 06/16/2003 No aplica s¡ la tasa a aplicar es la misma TMM

-- CODIGO TMM Y CODIGO TMMEX
if (@w_moneda = @i_moneda_nacional) or (@w_moneda = @i_moneda_uvr)
   select @w_concepto_tmm = @i_codigo_tmm
else
   select @w_concepto_tmm = @i_codigo_tmmex

if @@rowcount = 0
begin
   return 710093   
end


-- PARAMETRIZACION DE LA TMM
select @w_signo             = vd_signo_default,
       @w_factor            = vd_valor_default
from   ca_valor, ca_valor_det
where  va_tipo   = @w_concepto_tmm
and    vd_tipo   = @w_concepto_tmm
and    vd_sector = @w_sector

-- OBTENER PERIODICIDAD Y MODALIDAD DE TMM
select @w_modalidad_tmm    = tv_modalidad,
       @w_periodicidad_tmm = tv_periodicidad,
       @w_tipo_tasa        = tv_tipo_tasa
from   ca_tasa_valor
where  tv_nombre_tasa= @w_concepto_tmm
and    tv_estado     = 'V'

if @@rowcount = 0 
   return 701178

-- OBTENER LA MAXIMA FECHA A LA QUE SE HA INGRESADO UN REGISTRO DE TASA

select @w_fecha = max(vr_fecha_vig)
from   ca_valor_referencial
where  vr_tipo       = @w_concepto_tmm
and    vr_fecha_vig <= @i_fecha

-- OBTENER EL VALOR DE LA TMM EN EFECTIVO ANUAL
select @w_tmm_valor = vr_valor
from   ca_valor_referencial
where  vr_tipo       = @w_concepto_tmm
and    vr_fecha_vig  =  @w_fecha
and    vr_secuencial = (select max(vr_secuencial)
                        from ca_valor_referencial
                        where vr_tipo       =  @w_concepto_tmm
                        and   vr_fecha_vig  =  @w_fecha)

if @@rowcount = 0
begin
   PRINT 'contrmor.sp sale por error  @w_concepto_tmm' + @w_concepto_tmm + '@i_fecha' + cast(@i_fecha as varchar)
   return 710093           
end                    

--VALORES PARA LOS NUEVOS CAMPOS DE CA_TASAS
select @w_valor_tasa_ref = @w_tmm_valor,
       @w_fecha_tasaref  = @w_fecha,
       @w_ts_tasa_ref    = @w_concepto_tmm

-- SI LA TASA REFERENCIAL DE MORA ESTA EN EFECTIVO ANUAL
if @w_tipo_tasa = 'E' 
   select @w_tmm_efa = @w_tmm_valor

-- CONVERION DE LA TASA MAXIMA DE MORA A EFECTIVO ANUAL
if @w_tipo_tasa = 'N'
begin 
   exec @w_return =  sp_conversion_tasas_int
        @i_dias_anio      = @w_dias_anio,
        @i_base_calculo   = @w_base_calculo,
        @i_periodo_o      = @w_periodicidad_tmm,
        @i_modalidad_o    = @w_modalidad_tmm,
        @i_num_periodo_o  = 1,
        @i_tasa_o         = @w_tmm_valor,
        @i_periodo_d      = @i_periodo_anual,
        @i_modalidad_d    = 'V', --VENCIDA
        @i_num_periodo_d  = 1,
        @o_tasa_d         = @w_tmm_efa output  ---Tasa Efectiva Anual de TMM
end

select @o_nueva_tasa = 0

-- VERIFICACION DE EXISTENCIA DE TASAS DE MORA EN CA_TASAS SE SACA LA TASA MAXIMA
if exists (select 1 
           from  ca_rubro_op, ca_tasas
           where ro_operacion = @i_operacionca
           and   ro_tipo_rubro= 'M'
           and   ro_fpago     = 'P'
           and   ts_operacion = @i_operacionca
           and   ts_concepto  = ro_concepto
           and   ts_fecha    <= @i_fecha)  
begin
   select @w_max_secuencial = max(ts_secuencial)
   from   ca_tasas
   where  ts_operacion  = @i_operacionca
   and    ts_dividendo  = @i_dividendo
   and    ts_concepto   = @i_parametro_mora
   
   select @w_tasa_mora_efa = ts_porcentaje_efa
   from   ca_tasas
   where  ts_operacion  = @i_operacionca
   and    ts_dividendo  = @i_dividendo
   and    ts_concepto   = @i_parametro_mora
   and    ts_secuencial = @w_max_secuencial
end

-- SI LA TASA DE MORA DE LA OPERACION ES MAYOR QUE LA TMM
if @w_tasa_mora_efa > @w_tmm_efa 
begin
   exec @w_return =  sp_conversion_tasas_int
        @i_dias_anio      = @w_dias_anio,
        @i_base_calculo   = @w_base_calculo,
        @i_periodo_o      = @i_periodo_anual,
        @i_modalidad_o    = 'V',
        @i_num_periodo_o  = 1,
        @i_tasa_o         = @w_tmm_efa,
        @i_periodo_d      = @w_periodicidad,
        @i_modalidad_d    = 'V',
        @i_num_periodo_d  = 1,
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_ts_porcentaje output
   
   if @w_return <> 0
      return @w_return
   
   --- INSERCION DE LA NUEVA TASA DE MORA
   
   exec @w_secuencial = sp_gen_sec
       @i_operacion  = @i_operacionca
   
   insert into ca_tasas
         (ts_operacion,      ts_dividendo,     ts_fecha,
          ts_concepto,       ts_porcentaje,    ts_secuencial,
          ts_porcentaje_efa, ts_referencial,   ts_signo,
          ts_factor, ts_valor_referencial, ts_fecha_referencial,
          ts_tasa_ref 
          ) 
   values(
          @i_operacionca,    @i_dividendo, @i_fecha,
          @i_parametro_mora, @w_ts_porcentaje, @w_secuencial,
          @w_tmm_efa,    @w_concepto_tmm,  @w_signo,
          @w_factor, @w_valor_tasa_ref ,  @w_fecha_tasaref,
          @w_ts_tasa_ref
          )
   
   if @@error != 0
      return 703122                  
   
   -- ACTUALIZAR TABLA RUBROS
   update ca_rubro_op
   set    ro_porcentaje     = @w_ts_porcentaje,
          ro_porcentaje_efa = @w_tmm_efa
   where  ro_operacion = @i_operacionca 
   and    ro_concepto  = @i_parametro_mora
   
   select @o_nueva_tasa = @w_tmm_efa
end

return 0

go


