/*************************************************************************/
/*   Archivo:             genrtmp.sp                                     */
/*   Stored procedure:    sp_gen_rubtmp_cambioL                          */
/*   Base de datos:       cob_cartera                                    */
/*   Producto:            Cartera                                        */
/*   Disenado por:        e.pelaez                                       */
/*   Fecha de escritura:  oct-2008                                       */
/*************************************************************************/
/*                     IMPORTANTE                                        */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'MACOSA'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante.                 */
/*************************************************************************/  
/*                     PROPOSITO                                         */
/*   Crea los registros de la tabla ca_rubro_op_tmp para una             */
/*      operacion a partir de ca_rubro para cambio de linea              */
/*************************************************************************/  
/*                     MODIFICACIONES                                    */
/*   FECHA       AUTOR         RAZON                                     */                                                                         
/*************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_gen_rubtmp_cambioL')
   drop proc sp_gen_rubtmp_cambioL
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


create proc sp_gen_rubtmp_cambioL (
      @s_user                         login       = null,
      @s_date                         datetime    = null,
      @s_term                         varchar(30) = null,
      @s_ofi                          smallint    = null,
      @t_debug                        char(1)     = 'N',
      @t_file                         varchar(14) = null,
      @t_from                         varchar(30) = null,
      @i_operacionca                  int         = null,
      @i_toperacion                   char(19)    = null             
      
)
as
declare @w_sp_name                      descripcion,
        @w_operacionca                  int,
        @w_cliente                      int,
        @w_toperacion                   catalogo,
        @w_moneda                       tinyint,
        @w_fecha_ini                    datetime,
        @w_monto                        money,
        @w_ref_reajuste                 catalogo,
        @w_dias_anio                    smallint,
        @w_concepto                     catalogo,
        @w_porcentaje                   float,
        @w_prioridad                    tinyint,
        @w_paga_mora                    char(1),
        @w_fpago                        char(1),
        @w_tipo_rubro                   char(1),
        @w_provisiona                   char(1),
        @w_periodo                      tinyint,
        @w_referencial                  catalogo,
        @w_pit                          catalogo,
        @w_signo                        char(1),
        @w_factor                       float,
        @w_factor_reaj                  float,
        @w_signo_reaj                   char(1),
        @w_clase                        char(1),
        @w_valor_rubro                  money,
        @w_tipo_val                     catalogo,
        @w_signo_default                char(1),
        @w_tipo_puntos                  char(1),
        @w_valor_default                float,
        @w_decimales                    char(1),
        @w_num_dec                      tinyint,
        @w_sector                       catalogo,
        @w_error                        int,
        @w_vr_valor                     money, 
        @w_vr_valor_a                   money, 
        @w_secuencial_ref               int,
        @w_concepto_asociado            catalogo, 
        @w_principal                    char(1),
        @w_tcero                        varchar(10),
        @w_timbre                       catalogo,
        @w_redescuento                  float,
        @w_tipo                         char(1),
        @w_saldo_operacion              char(1),
        @w_saldo_por_desem              char(1),
        @w_signo_pit                    char(1),
        @w_spread_pit                   float,
        @w_tasa_pit                     catalogo,
        @w_clase_pit                    char(1),
        @w_porcentaje_pit               float,
        @w_num_dec_tapl                 tinyint,
        @w_rango_min                    money,
        @w_rango_max                    money,
        @w_limite                       char(1),
        @w_categoria_rubro              catalogo,
        @w_categoria_cliente            catalogo,
        @w_porcentaje_categoria         tinyint,
        @w_simulacion                   char(1),
        @w_spread_pit_a                 float,
        @w_num_dec_tapl_a               tinyint,
        @w_signo_reaj_a                 char(1),
        @w_concepto_a                   catalogo,
        @w_prioridad_a                  tinyint,
        @w_tipo_rubro_a                 char(1),
        @w_tipo_val_a                   catalogo,
        @w_paga_mora_a                  char(1),
        @w_tipo_puntos_a                char(1),
        @w_provisiona_a                 char(1),
        @w_fpago_a                      char(1),
        @w_periodo_a                    tinyint,
        @w_referencial_a                catalogo,
        @w_ref_reajuste_a               catalogo,
        @w_concepto_asociado_a          catalogo, 
        @w_principal_a                  char(1),
        @w_redescuento_a                float,
        @w_saldo_operacion_a            char(1),
        @w_saldo_por_desem_a            char(1),
        @w_pit_a                        catalogo,
        @w_limite_a                     char(1),
        @w_valor_rubro_asociado         money,
        @w_porcentaje_a                 float,
        @w_signo_a                      char(1),
        @w_tperiodo_a                   catalogo,
        @w_valor_rubro_a                money,
        @w_signo_pit_a                  char(1),
        @w_tasa_pit_a                   catalogo,
        @w_factor_a                     float,
        @w_clase_pit_a                  char(1),
        @w_factor_reaj_a                float,
        @w_clase_a                      char(1),
        @w_porcentaje_pit_a             float,
        @w_tramite                      int,
        @w_tipo_linea                   catalogo,
        @w_porcentaje_efa               float,
        @w_ciudad                       int,
        @w_iva_siempre                  char(1),
        @w_ciudad_iva                   int,
        @w_op_monto_aprobado            money,      
        @w_monto_aprobado               char(1),
        @w_porcentaje_cobrar            float,
        @w_valor_cliente                float,
        @w_parametro_timbac             varchar(30),
        @w_rubro_timbac                 catalogo,
        @w_valor_banco                  float,
        @w_parametro_fag                catalogo,
        @w_mensaje                      int,
        @w_tperiodo                     catalogo,
        @w_tipo_garantia                varchar(64),
        @w_valor_garantia               char(1), 
        @w_porcentaje_cobertura         char(1),
        @w_nro_garantia                 varchar(64),
        @w_op_tdividendo                catalogo,
        @w_tabla_tasa                   varchar(30),
        @w_base_calculo                 money,
        @w_saldo_insoluto               char(1),
        @w_porcentaje_cobrarc           float,
        @w_tasa_fija                    catalogo,
        @w_regimen_fiscal               catalogo,
        @w_cobra_timbre                 char(1),
        @w_calcular_devolucion          char(1),
        @w_fecha                        datetime,
        @w_exento                       char(1),
        @w_concepto_conta_iva           catalogo,
        @w_op_oficina                   int,
        @w_tipogar_hipo                 catalogo,
        @w_garhipo                      char(1),
        @w_cotizacion                   float,
        @w_moneda_local                 smallint,
        @w_fecha_ult_proceso            datetime,
        @w_rango                        tinyint,
        @w_dias_div                     int,
        @w_periodo_int                   smallint,
        @w_plazo_en_meses               int,
        @w_gracia_cap                   int,
        @w_gracia_cap_meses             int,
        @w_dias_plazo                   int,
        @w_plazo                        int,
        @w_op_tramite                   int,
        @w_tplazo                       catalogo,
        @w_rowcount                     int
      
        
select  @w_sp_name         = 'sp_gen_rubtmp_cambioL',
        @w_rango_min       = 0,
        @w_rango_max       = 0,
        @w_simulacion      = 'N',
        @w_porcentaje_efa  = 0


--- LECTURA DE LOS DATOS DE LA OPERACION 
select 
@w_operacionca          = op_operacion,
@w_cliente              = op_cliente,
@w_toperacion           = op_toperacion,
@w_moneda               = op_moneda,
@w_fecha_ini            = op_fecha_ini,
@w_monto                = op_monto,
@w_sector               = op_sector, 
@w_dias_anio            = op_dias_anio,
@w_tipo                 = op_tipo,
@w_tipo_linea           = op_tipo_linea,
@w_tramite              = op_tramite,
@w_ciudad               = op_ciudad,
@w_op_monto_aprobado    = op_monto_aprobado,
@w_op_tdividendo        = op_tdividendo,
@w_op_oficina           = op_oficina,
@w_fecha_ult_proceso    = op_fecha_ult_proceso,
@w_tplazo               = op_tplazo,
@w_plazo                = op_plazo,
@w_periodo_int          = op_periodo_int,
@w_op_tramite           = op_tramite,
@w_gracia_cap           = op_gracia_cap
from  ca_operacion
where op_operacion = @i_operacionca


---ACTUALIZACION DE TIPO DE DIVIDFENDO SEGUN LO DEFINIDO PARA LA OPERACION
---ESTO PARA LOS RUBROS CON PERIODICIDAD DIFERENTE A LA DE INTERES    
---CODIGO DEL RUBRO TIMBRE

select @w_timbre = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'TIMBRE'

select @w_rowcount = @@rowcount
if @w_rowcount = 0
   return 710120

select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro
WHERE  pa_nemonico = 'MLO'
AND    pa_producto = 'ADM'


---NUMERO DE DECIMALES
exec @w_error = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out

if @w_error != 0 
   return @w_error


-- DETERMINAR EL VALOR DE COTIZACION DEL DIA
if @w_moneda = @w_moneda_local
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
   @i_moneda     = @w_moneda,
   @i_fecha      = @w_fecha_ult_proceso,
   @o_cotizacion = @w_cotizacion output
end

update ca_rubro
set ru_tperiodo = @w_op_tdividendo
 from ca_rubro
where ru_toperacion = @w_toperacion
and ru_tperiodo is not null

---CODIGO DEL RUBRO COMISION FAG 
select @w_parametro_fag = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFAG'

select @w_rowcount = @@rowcount

if @w_rowcount = 0
   return  710370
 
---ELIMINAR LOS RUBROS A RECALCULAR
/*
delete ca_rubro_op
from ca_rubro,ca_rubro_op
where ru_toperacion      = 'SINCON2'
and ru_moneda            = 0
and ru_estado            = 'V'
and ru_crear_siempre     = 'S'
and ru_concepto_asociado is null
and ru_tipo_rubro  not in ('C','I','M')
and ro_operacion = @i_operacionca
and ro_concepto  = ru_concepto

delete ca_rubro_op
from ca_rubro,ca_rubro_op
where ru_toperacion      = 'SINCON2'
and ru_moneda            = 0
and ru_estado            = 'V'
and ru_crear_siempre     = 'S'
and ru_concepto_asociado is not null
and ru_tipo_rubro  not in ('C','I','M')
and ro_operacion = @i_operacionca
and ro_concepto = ru_concepto
*/

 
    
--- INSERCION DE LOS RUBROS DE LA OPERACION PARA RUBROS QUE NO TIENEN (RUBRO_ASOCIADO = NULL)
declare rubros_camlin cursor for
select  ru_concepto,         ru_prioridad,            ru_tipo_rubro,            ru_paga_mora,
        ru_provisiona,       ru_fpago,                ru_periodo,               ru_referencial,
        ru_reajuste,         ru_concepto_asociado,    ru_principal,             ru_redescuento,
        ru_saldo_op,         ru_saldo_por_desem,      ru_pit,                   ru_limite,
        ru_iva_siempre,      ru_monto_aprobado,       ru_porcentaje_cobrar,     ru_tperiodo,   
        ru_tipo_garantia,    ru_valor_garantia,       ru_porcentaje_cobertura,  ru_tabla,
        ru_saldo_insoluto,   ru_calcular_devolucion                             
from ca_rubro
where ru_toperacion      = @w_toperacion
and ru_moneda            = @w_moneda
and ru_estado            = 'V'
and ru_crear_siempre     = 'S'
and ru_concepto_asociado is null
and ru_tipo_rubro  not in ('C','I','M')
for read only

open rubros_camlin

fetch rubros_camlin into 
         @w_concepto,         @w_prioridad,            @w_tipo_rubro,           @w_paga_mora,
         @w_provisiona,       @w_fpago,                @w_periodo,              @w_referencial,  
         @w_ref_reajuste,     @w_concepto_asociado,    @w_principal,            @w_redescuento,
         @w_saldo_operacion,  @w_saldo_por_desem,      @w_pit,                  @w_limite,
         @w_iva_siempre,      @w_monto_aprobado,       @w_porcentaje_cobrar,    @w_tperiodo, 
         @w_tipo_garantia,    @w_valor_garantia,       @w_porcentaje_cobertura, @w_tabla_tasa,
         @w_saldo_insoluto,   @w_calcular_devolucion

while @@fetch_status  = 0
begin 
   ---INICIAR VARIABLES 
   select 
   @w_porcentaje     = 0,
   @w_valor_rubro    = 0,
   @w_vr_valor       = 0,
   @w_signo          = null,
   @w_factor         = 0,   
   @w_signo_reaj     = null,
   @w_factor_reaj    = 0,   
   @w_tipo_val       = null,  
   @w_clase          = null,
   @w_signo_pit      = null,
   @w_spread_pit     = 0,
   @w_tasa_pit       = null,
   @w_clase_pit      = null,
   @w_porcentaje_pit = 0,
   @w_num_dec_tapl   = null,
   @w_porcentaje_efa = 0

   select @w_categoria_rubro = co_categoria
   from ca_concepto
   where co_concepto = @w_concepto
   
      --PARA LAS OBLIGACIONES CON GARANTIA HIPOTECARIA EL VALOR DEL TIMBRE ES 0
   if @w_concepto = @w_timbre
   begin  
      select @w_limite = 'S',
             @w_garhipo = 'N'
      
      select @w_tipogar_hipo = pa_char
      from cobis..cl_parametro
      where pa_producto = 'CCA'
      and   pa_nemonico = 'GARHIP'

      if exists (select 1 
       from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia,cob_custodia..cu_tipo_custodia
      where cu_codigo_externo = gp_garantia
      and gp_tramite = @w_tramite
      and tc_tipo = cu_tipo
      and tc_tipo_superior = @w_tipogar_hipo )
      select @w_garhipo = 'S'
   end


   if not @w_pit is null and @w_pit != ''  
   begin
      select  
      @w_signo_pit    = isnull(vd_signo_default,' '),
      @w_spread_pit   = isnull(vd_valor_default,0),
      @w_tasa_pit     = vd_referencia,
      @w_clase_pit    = va_clase   
      from    ca_valor,ca_valor_det
      where   va_tipo   = @w_pit
      and     vd_tipo   = @w_pit
      and     vd_sector = @w_sector

      if @@rowcount = 0 and @w_tipo_rubro in('I') 
         return 721401

      ---DETERMINACION DEL MAXIMO SECUENCIAL PARA LA TASA ENCONTRADA 

      select @w_fecha = max(vr_fecha_vig)
      from   ca_valor_referencial 
      where  vr_tipo = @w_tasa_pit
      and    vr_fecha_vig <= @w_fecha_ini

      select @w_secuencial_ref = max(vr_secuencial)
      from   ca_valor_referencial 
      where  vr_tipo = @w_tasa_pit
      and    vr_fecha_vig = @w_fecha

      --- DETERMINACION DEL VALOR DE TASA A APLICAR 
      select @w_vr_valor = vr_valor
      from   ca_valor_referencial
      where  vr_tipo       = @w_tasa_pit
      and    vr_secuencial = @w_secuencial_ref 

      if @w_clase_pit = 'V' 
      begin
         if @w_tipo_rubro in ('I') 
            select  @w_porcentaje_pit = @w_spread_pit,
               @w_spread_pit = 0
      end
      else 
      begin
         if @w_tipo_rubro in ('I') 
         begin
            if @w_signo_pit = '+'
               select  @w_porcentaje_pit =  @w_vr_valor + @w_spread_pit
            if @w_signo_pit = '-' 
               select  @w_porcentaje_pit =  @w_vr_valor - @w_spread_pit
            if @w_signo_pit = '/' 
               select  @w_porcentaje_pit =  @w_vr_valor / @w_spread_pit
            if @w_signo_pit = '*' 
               select  @w_porcentaje_pit =  @w_vr_valor * @w_spread_pit
         end
      end
   end  --fin de pit 
   else
   begin
      --- DETERMINACION DE LA TASA A APLICAR 
      select  
      @w_signo        = isnull(vd_signo_default,' '),
      @w_factor       = isnull(vd_valor_default,0),
      @w_tipo_val     = vd_referencia,
      @w_tipo_puntos  = vd_tipo_puntos,
      @w_clase        = va_clase,
      @w_num_dec_tapl = vd_num_dec
      from    ca_valor,ca_valor_det
      where   va_tipo   = @w_referencial 
      and     vd_tipo   = @w_referencial
      and     vd_sector = @w_sector
      if @@rowcount = 0 and @w_tipo_rubro in('I','M') 
      begin
         print '(genrtmp.sp) 1. Parametrizar Tasas para rubro.. @w_sector' + cast(@w_referencial as varchar) + @w_sector
         return 721401
      end

      ---DETERMINACION DEL MAXIMO SECUENCIAL PARA LA TASA ENCONTRADA 
 
      if @w_clase <> 'V'
      begin
         select @w_fecha = max(vr_fecha_vig)
         from   ca_valor_referencial 
         where  vr_tipo = @w_tipo_val
         and    vr_fecha_vig <= @w_fecha_ini
   
         select @w_secuencial_ref = max(vr_secuencial)
         from   ca_valor_referencial 
         where  vr_tipo = @w_tipo_val
         and    vr_fecha_vig = @w_fecha
   
   
         --- DETERMINACION DEL VALOR DE TASA A APLICAR 
         select @w_vr_valor = vr_valor
         from   ca_valor_referencial
         where  vr_tipo       = @w_tipo_val
         and    vr_secuencial = @w_secuencial_ref 
      end
      else
         select @w_vr_valor =  @w_factor


      --- VALORES PARA RUBRO CALCULADOS  CON  TABLAS DE  RANGOS 
      if @w_tipo_rubro = 'Q' and @w_limite = 'S' 
      begin ---(4)

         ---NR 293
         ---CUANTOS DIAS TIENE UNA CUOTA DE INTERES
         select @w_dias_div = td_factor *  @w_periodo_int
         from   ca_tdividendo
         where  td_tdividendo = @w_op_tdividendo

         select @w_dias_plazo = td_factor 
         from   ca_tdividendo
         where  td_tdividendo = @w_tplazo
      
         select @w_plazo_en_meses = isnull((@w_plazo * @w_dias_plazo)/30,0)   
         
         select @w_gracia_cap_meses = 0
         if  @w_gracia_cap > 0
             select @w_gracia_cap_meses = isnull((@w_dias_div * @w_gracia_cap) / 30,0)       
         
         exec @w_error   = sp_rubros_limites_de_rangos 
         @i_monto_desembolsado    = @w_monto,
         @i_concepto              = @w_concepto,
         @i_tramite               = @w_op_tramite,
         @i_dias_div              = @w_dias_div,
         @i_plazo_en_meses        = @w_plazo_en_meses,
         @i_porcentaje_cobertura  = @w_porcentaje_cobertura,
         @i_valor_garantia        = @w_valor_garantia,
         @i_gracia_cap_meses      = @w_gracia_cap_meses,
         @i_tipo_garantia         = @w_tipo_garantia,
         @i_num_dec               = @w_num_dec,
         @i_op_monto_aprobado     = @w_op_monto_aprobado,
         @i_cotizacion            = @w_cotizacion,
         @i_tasa                  = @w_vr_valor,
         @i_parametro_timbre      = @w_timbre,
         @i_fecha_ini             = @w_fecha_ini,
         @o_tasa_calculo          = @w_porcentaje   out,
         @o_nro_garantia          = @w_nro_garantia out,
         @o_base_calculo          = @w_base_calculo out,
         @o_valor_rubro           = @w_valor_rubro  out
         
         if @w_error != 0 
            return @w_error
           
         select @w_valor_rubro = round(@w_valor_rubro,@w_num_dec)

         --Generacion del rubro TIMBAC
         if @w_porcentaje_cobrar <> 100  and @w_concepto = @w_timbre
         begin  --(1)
            select @w_porcentaje_cobrarc = 100 - @w_porcentaje_cobrar

            select @w_valor_cliente = (@w_valor_rubro * @w_porcentaje_cobrar)/100
            select @w_valor_banco   = (@w_valor_rubro - @w_valor_cliente)
            select @w_valor_rubro   = @w_valor_cliente   -- Lo que realmente se le cobra al cliente

            select @w_parametro_timbac = pa_char
            from cobis..cl_parametro 
            where pa_producto = 'CCA'
            and   pa_nemonico = 'TIMBAC'
            if    @@rowcount =  0 
                  return 710363

            select @w_rubro_timbac = co_concepto
            from ca_concepto
            where co_concepto = @w_parametro_timbac      
            if @@rowcount =  0 
               return  710364

            if @w_valor_banco is null
               select @w_valor_banco = 0

            insert into ca_rubro_op_tmp(
            rot_operacion,            rot_concepto,          rot_tipo_rubro,
            rot_fpago,                rot_prioridad,         rot_paga_mora,
            rot_provisiona,           rot_signo,             rot_factor,
            rot_referencial,          rot_signo_reajuste,    rot_factor_reajuste,
            rot_referencial_reajuste, rot_valor,             rot_porcentaje,
            rot_porcentaje_aux,       rot_gracia,            rot_concepto_asociado,
            rot_principal,            rot_porcentaje_efa,    rot_garantia,
            rot_tipo_puntos,          rot_saldo_op,          rot_saldo_por_desem,
            rot_num_dec,              rot_limite,            rot_monto_aprobado,
            rot_porcentaje_cobrar,    rot_base_calculo,      rot_tabla)
            values(
            @w_operacionca,           @w_rubro_timbac,       @w_tipo_rubro,
            'B',                      @w_prioridad,          @w_paga_mora,
            @w_provisiona,            @w_signo,              @w_factor,
            @w_referencial,           @w_signo_reaj,         @w_factor_reaj,
            @w_ref_reajuste,          @w_valor_banco,        @w_porcentaje,
            @w_porcentaje,            @w_porcentaje_efa,     @w_concepto_asociado,
            @w_principal,             0,                     0,
            @w_tipo_puntos,           @w_saldo_operacion,    @w_saldo_por_desem,
            @w_num_dec_tapl,          @w_limite,             @w_monto_aprobado,   
            @w_porcentaje_cobrarc,    @w_base_calculo,       @w_tabla_tasa)
         
            if @@error != 0
             begin
               close rubros_camlin
               deallocate rubros_camlin
               return 721406
            end          
            --SI EL BANCO ASUME EL TIMBRE, EL CLIENTE NO PAGA NADA
            select @w_valor_rubro = 0.0
         end   -----(1) Generacion del TIMBAC
      end  --  (4)FIN DE RANGOS
      else 
      begin  ---CALCULADOS SIN LIMITE
         if @w_tipo_rubro = 'Q' and @w_limite <> 'S' 
         begin
            --PRINT 'GENRTMP Llamando a sp_rubro_calculado: @i_concepto ' + CAST(@w_concepto AS VARCHAR)
            exec @w_error = sp_rubro_calculado 
            @i_tipo                = 'Q',
            @i_monto                 = 0,
            @i_concepto              = @w_concepto,
            @i_operacion             = @w_operacionca,
            @i_saldo_op              = @w_saldo_operacion,
            @i_saldo_por_desem       = @w_saldo_por_desem,
            @i_porcentaje            = @w_porcentaje,
            @i_monto_aprobado        = @w_monto_aprobado,
            @i_op_monto_aprobado     = @w_op_monto_aprobado,
            @i_porcentaje_cobertura  = @w_porcentaje_cobertura,
            @i_valor_garantia        = @w_valor_garantia,
            @i_tipo_garantia         = @w_tipo_garantia,
            @i_parametro_fag         = @w_parametro_fag,
            @i_tabla_tasa            = @w_tabla_tasa,
            @i_categoria_rubro       = @w_categoria_rubro,
            @i_fpago                 = @w_fpago,
            @i_saldo_insoluto        = @w_saldo_insoluto,
            @o_tasa_calculo          = @w_porcentaje out,
            @o_nro_garantia          = @w_nro_garantia out, 
            @o_base_calculo          = @w_base_calculo out,
            @o_valor_rubro           = @w_valor_rubro out

            if @w_error != 0 
               return @w_error

            select @w_valor_rubro = round(@w_valor_rubro,@w_num_dec)
         end
      end ---CALCULADOS SIN LIMITE
      
      if @w_tipo_rubro <> 'Q' and @w_limite = 'S' 
      begin
         PRINT 'genrtmp.sp rubro no calculado  y parametrizado con limite, debe ser programado' + @w_concepto
         return 721405
      end   




      if @w_clase = 'V'  --TASA VALOR
      begin

         if @w_tipo_rubro in ('O','Q') 
            select  @w_porcentaje     = @w_factor ,
               @w_factor         = 0,
                    @w_porcentaje_efa = @w_factor
         else
            select  @w_valor_rubro = round(@w_factor,@w_num_dec) ,
               @w_factor = 0
      end
      else                --TASA REFERENCIAL
      begin
         if @w_tipo_rubro in ('O','Q') 
         begin
            if @w_signo = '+'
               select  @w_porcentaje =  @w_vr_valor + @w_factor
            if @w_signo = '-' 
               select  @w_porcentaje =  @w_vr_valor - @w_factor
             if @w_signo = '/' 
               select  @w_porcentaje =  @w_vr_valor / @w_factor
             if @w_signo = '*' 
               select  @w_porcentaje =  @w_vr_valor * @w_factor
          
            --Esta tasa es la misma  nominal ya que no hay conversion de tasa
            select @w_porcentaje_efa = @w_porcentaje
            ---PRINT 'porcentaje_efa %1!',@w_porcentaje_efa
            
         end
         else 
         if @w_tipo_rubro in ('C','V') 
         begin
            if @w_signo = '+'
               select  @w_valor_rubro = round(@w_vr_valor+@w_factor,@w_num_dec)
            if @w_signo = '-'
               select  @w_valor_rubro = round(@w_vr_valor-@w_factor, @w_num_dec)
            if @w_signo = '/'
               select  @w_valor_rubro = round(@w_vr_valor/@w_factor, @w_num_dec)
            if @w_signo = '*'
               select  @w_valor_rubro = round(@w_vr_valor*@w_factor, @w_num_dec)
         end
      end

      
      select @w_redescuento = 0

  
      if @w_fpago = 'L' or @w_fpago = 'A' or @w_fpago = 'P' or @w_fpago = 'T'  
      begin
         if @w_tipo_rubro = 'I'
         begin
            select @w_valor_rubro = round(@w_porcentaje * @w_monto/100.0 +
                                    isnull(@w_valor_rubro,0), @w_num_dec)
         end

      end
   end  --DETERMINACION DE LA TASA A APLICAR 



   if @w_valor_rubro is null 
      select @w_valor_rubro = 0

 
   insert into ca_rubro_op_tmp 
   (
   rot_operacion,           rot_concepto,        rot_tipo_rubro,
   rot_fpago,               rot_prioridad,       rot_paga_mora,
   rot_provisiona,          rot_signo,           rot_factor,
   rot_referencial,         rot_signo_reajuste,  rot_factor_reajuste,
   rot_referencial_reajuste,rot_valor,           rot_porcentaje,
   rot_porcentaje_aux,      rot_gracia,          rot_concepto_asociado,
   rot_principal,           rot_porcentaje_efa,  rot_garantia,
   rot_tipo_puntos,         rot_saldo_op,        rot_saldo_por_desem, 
   rot_num_dec,             rot_limite,          rot_tipo_garantia,       
   rot_nro_garantia,        rot_porcentaje_cobertura,   rot_valor_garantia,
   rot_tperiodo,            rot_periodo,         rot_base_calculo,
   rot_tabla,               rot_porcentaje_cobrar,   rot_calcular_devolucion,
   rot_saldo_insoluto
   )
   values 
   (
   @w_operacionca,          @w_concepto,         @w_tipo_rubro,
   @w_fpago,                @w_prioridad,        @w_paga_mora,
   @w_provisiona,           @w_signo,            @w_factor,
   @w_referencial,          @w_signo_reaj,       @w_factor_reaj,
   @w_ref_reajuste,         @w_valor_rubro,      @w_porcentaje,
   @w_porcentaje,           @w_porcentaje_efa,   @w_concepto_asociado, 
   @w_principal,            0,                   0,
   @w_tipo_puntos,          @w_saldo_operacion,  @w_saldo_por_desem,
   @w_num_dec_tapl,         @w_limite,           @w_tipo_garantia,
   @w_nro_garantia,         @w_porcentaje_cobertura,   @w_valor_garantia,
   @w_tperiodo,             @w_periodo,          @w_base_calculo,
   @w_tabla_tasa,           @w_porcentaje_cobrar,   @w_calcular_devolucion,
   @w_saldo_insoluto
   )

   if @@error != 0 
   begin
     close rubros_camlin
     deallocate rubros_camlin
     return 721407
   end

   fetch rubros_camlin into 
         @w_concepto,         @w_prioridad,         @w_tipo_rubro,           @w_paga_mora,
         @w_provisiona,       @w_fpago,             @w_periodo,              @w_referencial,  
         @w_ref_reajuste,     @w_concepto_asociado, @w_principal,            @w_redescuento,
         @w_saldo_operacion,  @w_saldo_por_desem,   @w_pit,                  @w_limite,
         @w_iva_siempre,      @w_monto_aprobado,    @w_porcentaje_cobrar,    @w_tperiodo, 
         @w_tipo_garantia,    @w_valor_garantia,    @w_porcentaje_cobertura, @w_tabla_tasa,
         @w_saldo_insoluto,   @w_calcular_devolucion
end

close rubros_camlin
deallocate rubros_camlin




---INSERCION DE LOS RUBROS DE LA OPERACION PARA RUBRO ASOCIADO  <> NULL, POR LO GENERAL RUBRO IVA

declare rubros_asociados_camlin cursor for
select  ru_concepto,   ru_prioridad,          ru_tipo_rubro,   ru_paga_mora,
        ru_provisiona, ru_fpago,              ru_periodo,      ru_referencial,
        ru_reajuste,   ru_concepto_asociado,  ru_principal,    ru_redescuento,
        ru_saldo_op,   ru_saldo_por_desem,    ru_pit,          ru_limite,
        ru_iva_siempre, ru_tperiodo,          ru_saldo_insoluto
from ca_rubro
where ru_toperacion  = @w_toperacion
and ru_moneda        = @w_moneda
and ru_estado        = 'V'
and ru_crear_siempre = 'S'
and ru_concepto_asociado is not null
and ru_tipo_rubro  not in ('C','I','M')
for read only

open rubros_asociados_camlin

fetch rubros_asociados_camlin into 
        @w_concepto_a,         @w_prioridad_a,         @w_tipo_rubro_a, @w_paga_mora_a,
        @w_provisiona_a,       @w_fpago_a,             @w_periodo_a,    @w_referencial_a,
        @w_ref_reajuste_a,     @w_concepto_asociado_a, @w_principal_a,  @w_redescuento_a,
        @w_saldo_operacion_a,  @w_saldo_por_desem_a,   @w_pit_a,        @w_limite_a,
        @w_iva_siempre,        @w_tperiodo_a,          @w_saldo_insoluto

while @@fetch_status = 0
begin 
   ---INICIAR VARIABLES 
   select 
   @w_porcentaje_a     = 0,
   @w_valor_rubro_a    = 0,
   @w_vr_valor_a       = 0,
   @w_signo_a          = null,
   @w_factor_a         = 0,   
   @w_signo_reaj_a     = null,
   @w_factor_reaj_a    = 0,   
   @w_tipo_val_a       = null,  
   @w_clase_a          = null,
   @w_signo_pit_a      = null,
   @w_spread_pit_a     = 0,
   @w_tasa_pit_a       = null,
   @w_clase_pit_a      = null,
   @w_porcentaje_pit_a = 0,
   @w_num_dec_tapl_a   = null,
   @w_porcentaje_efa   = 0

   select @w_valor_rubro_asociado = rot_valor
   from ca_rubro_op_tmp
   where rot_operacion  = @w_operacionca
   and rot_concepto = @w_concepto_asociado_a

   --- DETERMINACION DE LA TASA A APLICAR 
   select  
   @w_signo_a       = isnull(vd_signo_default,' '),
   @w_factor_a      = isnull(vd_valor_default,0),
   @w_tipo_val_a    = vd_referencia,
   @w_tipo_puntos_a = vd_tipo_puntos,
   @w_clase_a       = va_clase,
   @w_num_dec_tapl_a  = vd_num_dec
   from    ca_valor,ca_valor_det
   where   va_tipo   = @w_referencial_a 
   and     vd_tipo   = @w_referencial_a
   and     vd_sector = @w_sector

   if @@rowcount = 0  
   begin
     close rubros_asociados_camlin
     deallocate rubros_asociados_camlin
     --print '(genrtmp.sp) concepto asociado. Parametrizar Tasa para rubro' + @w_referencial_a
     return 721404
   end

   select @w_valor_rubro_a = round(@w_factor_a * @w_valor_rubro_asociado / 100.0, @w_num_dec)

   if @w_tipo_rubro_a = 'O' and  @w_iva_siempre = 'S'  ---Paraemtro por LINEA y Modificable por operacion
   begin

      ---CONCEPTO CONTABLE QUE IDENTIFICA EL IVA PARA CONSULTAR SI EL CLIENTE ES EXENTO O NO
      select @w_concepto_conta_iva = pa_char
      from cobis..cl_parametro
      where pa_producto = 'CCA'
      and pa_nemonico  =  'CONIVA' 
      and  pa_producto = 'CCA'
   
      if @@rowcount = 0 
      begin
          close rubros_asociados_camlin
          deallocate rubros_asociados_camlin
          return 710449
      end
   
      exec @w_error  = cob_conta..sp_exenciu
      @s_date         = @s_date,
      @s_user         = @s_user,
      @s_term         = @s_term,
      @s_ofi          = @s_ofi,
      @t_trn          = 6251,
      @t_debug        = 'N',
      @i_operacion    = 'F',
      @i_empresa      = 1,
      @i_impuesto     = 'V',             ---Iva   T timbre
      @i_concepto     = @w_concepto_conta_iva,
      @i_debcred      = 'C',            ---Valor D'bito o Cr'dito
      @i_ente         = @w_cliente,     ---C�digo  COBIS del cliente
      @i_oforig_admin = @s_ofi,         ---C�digo COBIS de la oficina origen Admin
      @i_ofdest_admin = @w_op_oficina,  ---C�digo COBIS de la oficina destino Admin
      @i_producto     = 7,              ---Codigo del producto CARTERA
      @o_exento       = @w_exento  out

      if @w_error <> 0
      begin
          close rubros_asociados_camlin
          deallocate rubros_asociados_camlin
          return 710457
      end
   
      if @w_exento = 'S'
         select @w_valor_rubro_a = 0
   end  ---Validaciones  Iva

   if @w_valor_rubro_a is null
       select @w_valor_rubro_a = 0

   insert into ca_rubro_op_tmp (
   rot_operacion,            rot_concepto,         rot_tipo_rubro,
   rot_fpago,                rot_prioridad,        rot_paga_mora,
   rot_provisiona,           rot_signo,            rot_factor,
   rot_referencial,          rot_signo_reajuste,   rot_factor_reajuste,
   rot_referencial_reajuste, rot_valor,            rot_porcentaje,
   rot_porcentaje_aux,       rot_gracia,           rot_concepto_asociado,
   rot_principal,            rot_porcentaje_efa,   rot_garantia,
   rot_tipo_puntos,          rot_saldo_op,         rot_saldo_por_desem, 
   rot_base_calculo,         rot_num_dec,          rot_limite,
   rot_tperiodo,             rot_periodo,          rot_saldo_insoluto)
   values (                  
   @w_operacionca,           @w_concepto_a,        @w_tipo_rubro_a,
   @w_fpago_a,               @w_prioridad_a,       @w_paga_mora_a,
   @w_provisiona_a,          @w_signo_a,           0,
   @w_referencial_a,         @w_signo_reaj_a,      @w_factor_reaj_a,
   @w_ref_reajuste_a,        @w_valor_rubro_a,     @w_factor_a,
   @w_factor_a,              @w_factor_a,          @w_concepto_asociado_a, 
   @w_principal_a,           0,                    0,
   @w_tipo_puntos_a,         @w_saldo_operacion_a, @w_saldo_por_desem_a,
   @w_valor_rubro_asociado,  @w_num_dec_tapl_a,    @w_limite_a,
   @w_tperiodo_a,            @w_periodo_a,         @w_saldo_insoluto)
                             
   if @@error != 0 
   begin
    close rubros_asociados_camlin
    deallocate rubros_asociados_camlin
    return  721408
   end

  fetch rubros_asociados_camlin into    
          @w_concepto_a,         @w_prioridad_a,      @w_tipo_rubro_a,  
          @w_paga_mora_a,        @w_provisiona_a,     @w_fpago_a,          
          @w_periodo_a,          @w_referencial_a,    @w_ref_reajuste_a,   
          @w_concepto_asociado_a,@w_principal_a,      @w_redescuento_a,
          @w_saldo_operacion_a,  @w_saldo_por_desem_a,@w_pit_a,@w_limite_a,
          @w_iva_siempre,        @w_tperiodo_a,       @w_saldo_insoluto
end

close rubros_asociados_camlin
deallocate rubros_asociados_camlin


---UNA VEZ TERMINA DE INSERTAR EL CALCULO
---LLENA LAS DEFINITIVAS

-- JH Se agregan las columnas de la tabla 
insert into ca_rubro_op(
ro_operacion,              ro_concepto,              ro_tipo_rubro,
ro_fpago,                  ro_prioridad,             ro_paga_mora,
ro_provisiona,             ro_signo,                 ro_factor,
ro_referencial,            ro_signo_reajuste,        ro_factor_reajuste,
ro_referencial_reajuste,   ro_valor,                 ro_porcentaje,
ro_porcentaje_aux,         ro_gracia,                ro_concepto_asociado,
ro_redescuento,            ro_intermediacion,        ro_principal,
ro_porcentaje_efa,         ro_garantia,              ro_tipo_puntos,
ro_saldo_op,               ro_saldo_por_desem,       ro_base_calculo,
ro_num_dec,                ro_limite,                ro_iva_siempre,
ro_monto_aprobado,         ro_porcentaje_cobrar,     ro_tipo_garantia,
ro_nro_garantia,           ro_porcentaje_cobertura,  ro_valor_garantia,
ro_tperiodo,               ro_periodo,               ro_tabla,
ro_saldo_insoluto,         ro_calcular_devolucion
)
select 
rot_operacion,             rot_concepto,             rot_tipo_rubro,
rot_fpago,                 rot_prioridad,            rot_paga_mora,
rot_provisiona,            rot_signo,                rot_factor,
rot_referencial,           rot_signo_reajuste,       rot_factor_reajuste,
rot_referencial_reajuste,  rot_valor,                rot_porcentaje,
rot_porcentaje_aux,        rot_gracia,               rot_concepto_asociado,
rot_redescuento,           rot_intermediacion,       rot_principal,
rot_porcentaje_efa,        rot_garantia,             rot_tipo_puntos,
rot_saldo_op,              rot_saldo_por_desem,      rot_base_calculo,
rot_num_dec,               rot_limite,               rot_iva_siempre,
rot_monto_aprobado,        rot_porcentaje_cobrar,    rot_tipo_garantia,
rot_nro_garantia,          rot_porcentaje_cobertura, rot_valor_garantia,
rot_tperiodo,              rot_periodo,              rot_tabla,
rot_saldo_insoluto,        rot_calcular_devolucion
from ca_rubro_op_tmp
where rot_operacion =  @i_operacionca

----BORRAR LAS TEMPORALES POR QUE SE PASAN DSEPUES EN ct_up_tr.sp

delete ca_rubro_op_tmp
where rot_operacion =  @i_operacionca

return 0
go
