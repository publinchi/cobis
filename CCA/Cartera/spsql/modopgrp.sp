/************************************************************************/
/*      Archivo:                modopgrp.sp                             */
/*      Stored procedure:       sp_modificar_operacion_grp              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Adriana Giler                           */
/*      Fecha de escritura:     Abril-2019                              */
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
/*      Valida datos para la modificaci+Ýn de las operaciones hijas de   */
/*      la operacion grupal                                             */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*     15/04/2019       A. Giler        Operaciones Grupales            */
/*     06/01/2022       G.Fernandez     Ingreso de nuevo parametro de   */
/*                                      grupo contable                  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_modificar_operacion_grp')
    drop proc sp_modificar_operacion_grp
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_modificar_operacion_grp
   @t_trn                      int          = null,                       --7451  
   @s_user                     login        = null,
   @s_sesn                     int          = null,
   @s_date                     datetime     = null,
   @s_term                     varchar(30)  = null,
   @s_ofi                      smallint     = null,
   @i_calcular_tabla           char(1)      = 'N',
   @i_tabla_nueva              char(1)      = 'S',
   @i_operacionca              int          = null,
   @i_banco                    cuenta       = null,
   @i_anterior                 cuenta       = null,
   @i_migrada                  cuenta       = null,
   @i_tramite                  int          = null,
   @i_cliente                  int          = null,
   @i_nombre                   descripcion  = null,
   @i_sector                   catalogo     = null,
   @i_toperacion               catalogo     = null,
   @i_oficina                  smallint     = null,
   @i_moneda                   smallint     = null,
   @i_comentario               varchar(255) = null,
   @i_en_linea                 char(1)      = null,
   @i_oficial                  smallint     = null,
   @i_fecha_ini                datetime     = null,
   @i_fecha_fin                datetime     = null,
   @i_fecha_liq                datetime     = null,
   @i_fecha_pri_cuot           datetime     = null,
   @i_fecha_reajuste           datetime     = null,
   @i_monto                    money        = null,
   @i_monto_aprobado           money        = null,
   @i_destino                  catalogo     = null,
   @i_lin_credito              cuenta       = null,
   @i_ciudad                   int          = null,
   @i_estado                   tinyint      = null,
   @i_periodo_reajuste         smallint     = null,
   @i_reajuste_especial        char(1)      = null,
   @i_tipo                     char(1)      = null,
   @i_forma_pago               catalogo     = null,
   @i_cuenta                   cuenta       = null,
   @i_dias_anio                smallint     = null,
   @i_tipo_amortizacion        varchar(10)  = null,
   @i_cuota_completa           char(1)      = null,
   @i_tipo_cobro               char(1)      = null,
   @i_tipo_reduccion           char(1)      = null,
   @i_aceptar_anticipos        char(1)      = null,
   @i_precancelacion           char(1)      = null,
   @i_operacion                char(1)      = null,
   @i_tipo_aplicacion          char(1)      = null,
   @i_tplazo                   catalogo     = null,
   @i_plazo                    int          = null,
   @i_tdividendo               catalogo     = null,
   @i_periodo_cap              int          = null,
   @i_periodo_int              int          = null,
   @i_dist_gracia              char(1)      = null,
   @i_gracia_cap               int          = null,
   @i_gracia_int               int          = null,
   @i_dia_fijo                 int          = null,
   @i_cuota                    money        = null,
   @i_evitar_feriados          char(1)      = null,
   @i_num_renovacion           int          = null,
   @i_renovacion               char(1)      = null,
   @i_mes_gracia               tinyint      = null,
   @i_formato_fecha            int          = 101,
   @i_upd_clientes             char(1)      = null,
   @i_dias_gracia              smallint     = null,
   @i_reajustable              char(1)      = null,
   @i_salida                   char(1)      = 'S',
   @i_dias_clausula            int          = null,
   @i_periodo_crecimiento      smallint     = null,
   @i_tasa_crecimiento         float        = null,
   @i_control_tasa             char(1)      = 'S',
   @i_direccion                tinyint      = null,
   @i_opcion_cap               char(1)      = null,
   @i_tasa_cap                 float        = null,
   @i_dividendo_cap            smallint     = null,
   @i_tipo_cap                 char(1)      = null,
   @i_clase_cartera            catalogo     = null,
   @i_origen_fondos            catalogo     = null,
   @i_tipo_crecimiento         char(1)      = null,
   @i_num_reest                int          = null,
   @i_base_calculo             char(1)      = null,
   @i_ult_dia_habil            char(1)      = null,
   @i_recalcular               char(1)      = null,
   @i_tasa_equivalente         char(1)      = null,
   @i_tipo_empresa             catalogo     = null,
   @i_validacion               catalogo     = null,
   @i_fondos_propios           char(1)      = null,
   @i_ref_exterior             cuenta       = null,
   @i_sujeta_nego              char(1)      = null,
   @i_ref_red                  varchar(24)  = null,
   @i_tipo_redondeo            tinyint      = null,
   @i_causacion                char(1)      = null,
   @i_tramite_ficticio         int          = null,
   @i_grupo_fact               int          = null,
   @i_convierte_tasa           char(1)      = null,
   @i_bvirtual                 char(1)      = null,
   @i_extracto                 char(1)      = null,
   @i_fec_embarque             datetime     = null,
   @i_fec_dex                  datetime     = null,
   @i_num_deuda_ext            cuenta       = null,
   @i_num_comex                cuenta       = null,
   @i_pago_caja                char(1)      = null,
   @i_nace_vencida             char(1)      = null,
   @i_calcula_devolucion       char(1)      = null,
   @i_oper_pas_ext             varchar(64)  = null,
   @i_reestructuracion         char(1)      = null,
   @i_mora_retroactiva         char(1)      = null,
   @i_prepago_desde_lavigente  char(1)      = null,
   @i_operacion_activa         int          = null,
   @i_actualiza_rubros         char(1)      = 'S',
   @i_valida_param             char(1)      = 'N',    --
   @i_signo                    char(1)      = null,
   @i_factor                   float        = null,
   @i_gracia_pend              char(1)      = 'N',      
   @i_divini_reg               smallint     = null,     
   @i_crea_ext                 char(1)      = null,
   @i_simulacion_tflex         char         = 'N',
   @i_grupal                   char(1)      = null,     
   @i_dia_pago                 int          = null,     
   @i_fecha_fija               char(1)      = 'S',      
   @i_tasa             		   float		= null, 	
   @i_grupo                    int          = 0,        
   @i_ref_grupal               cuenta       = null,     
   @i_es_grupal                char(1)      = 'N',      
   @i_fondeador                tinyint      = null,
   @i_cliente_1                varchar(200)  = null,
   @i_cliente_2                varchar(200)  = null,  
   @i_cliente_3                varchar(200)  = null,  
   @i_cliente_4                varchar(200)  = null,  
   @i_cliente_5                varchar(200)  = null,      
   @i_monto_1                  varchar(200)  = null,     
   @i_monto_2                  varchar(200)  = null,  
   @i_monto_3                  varchar(200)  = null,  
   @i_monto_4                  varchar(200)  = null,  
   @i_monto_5                  varchar(200)  = null,
   @i_monto_6                  varchar(200)  = null,
   @i_grupo_contable           catalogo      = null --GFP 06-01-2022
    

as
declare
   @w_sp_name           descripcion,
   @w_return            int,
   @w_error             int,
   @w_msg               mensaje,
   @w_contador          int,
   @w_pos               int,
   @w_secuencia         int,
   @w_cadena            varchar(200),
   @w_valor             varchar(15),
   @w_monto_op          money,
   @w_monto             money,
   @w_accion            char(1),
   @w_monto_hijas       money,
   @w_cliente           int,
   @w_ref_grupal        cuenta,
   @w_nombre            descripcion,
   @w_sector            catalogo,
   @w_toperacion        catalogo,
   @w_operacion         int,
   @w_banco             cuenta,
   
   
   
   @w_periodo_d                catalogo,
   @w_actualiza_rubros         char(1),
   @w_dias_dividendo           int,
   @w_dias_aplicar             int,
   @w_tipo                     char(1),
   @w_estado                   tinyint,
   @w_tasa_eq                  char(1),
   @w_cliente_ficticio         int,
   @w_dias_anio                int,
   @w_dias_prestamo            int,
   @w_estado_cancelado         tinyint,
   @w_estado_no_vigente        tinyint,
   @w_oficial_original         smallint,
   @w_nace_vencida             char(1),
   @w_tipo_linea               catalogo,
   @w_calcula_devolucion       char(1),
   @w_concepto_interes         catalogo,
   @w_concepto_cenrie          catalogo,
   @w_concepto_micseg          catalogo,
   @w_concepto_exequi          catalogo,
   @w_prueba_int               float,
   @w_estado_op                tinyint,
   @w_oficina                  int,
   @w_moneda                   int,
   @w_fecha_cartera            datetime,
   @w_dias_contr               int,
   @w_dias_hoy                 int,
   @w_llave_activa             cuenta,
   @w_activa                   int,
   @w_fecha_ult_proceso        datetime,
   @w_op_relacionada           int,
   @w_ciudad_nacional          int,
   @w_cod_entidad              catalogo,
   @w_bandera_valor            char(1),
   @w_estado_actual            smallint,
   @w_op_naturaleza            char(1),
   @w_rubros_basicos           int,
   @w_calcular_tabla_sv        char(1),
   @w_rowcount                 int,
   @w_control_dia_pago         char(1),
   @w_pa_dimive                tinyint,
   @w_pa_dimave                tinyint,
   @w_parametro_fag            catalogo,
   @w_valor_seguros            money,          -- Req. 366 Seguros
   @w_tramite                  int,
   @w_num_dias                 int,
   @w_tr_tipo                  char(1),
   @w_subtipo_linea            catalogo,        --LRE 06/ENE/2017
   @w_grupo                    int,
   @w_es_grupal                char(1) ,
   @w_fondeador                tinyint,      
   @w_tipo_amortizacion        varchar(10),
   @w_oficial                  int,
   @w_fecha_ini                datetime,
   @w_destino                  catalogo,
   @w_lin_credito              cuenta,
   @w_ciudad                   int,
   @w_forma_pago               catalogo,
   @w_dia_pago                 tinyint,
   @w_clase_cartera            catalogo,
   @w_origen_fondos            catalogo,
   @w_tipo_empresa             catalogo,
   @w_validacion               catalogo,
   @w_ref_red                  varchar(24),
   @w_convierte_tasa           char(1),
   @w_tasa_equivalente         char(1),
   @w_fec_embarque             datetime,
   @w_fec_dex                  datetime,
   @w_num_deuda_ext            cuenta,
   @w_num_comex                cuenta,
   @w_reestructuracion         char(1),
   @w_tipo_cambio              char(1), 
   @w_numero_reest             int,      
   @w_oper_pas_ext             cuenta, 
   @w_banca                    catalogo,
   @w_promocion                char(1),
   @w_acepta_ren               char(1),
   @w_no_acepta                varchar(100),
   @w_emprendimiento           char(1),
   @w_plazo                    smallint,
   @w_tplazo                   catalogo,
   @w_tdividendo               catalogo,
   @w_periodo_cap              smallint,
   @w_periodo_int              smallint,
   @w_cuenta                   cuenta,
   @w_fondos_propios           char(1),
   @w_tasa                     float,
   @w_dias_gracia              smallint,
   @w_operacionca              int
     
-- Tomando Datos del padre
select
      @w_sector            = opt_sector,
      @w_operacionca       = opt_operacion,
      @w_toperacion        = opt_toperacion,
      @w_oficina           = opt_oficina,
      @w_moneda            = opt_moneda,
      @w_oficial           = opt_oficial,
      @w_fecha_ini         = opt_fecha_ini,
      @w_destino           = opt_destino,
      @w_lin_credito       = opt_lin_credito,
      @w_ciudad            = opt_ciudad,
      @w_forma_pago        = opt_forma_pago,
      @w_cuenta            = opt_cuenta,
      @w_dia_pago          = opt_dia_fijo,
      @w_clase_cartera     = opt_clase,
      @w_origen_fondos     = opt_origen_fondos,
      @w_tipo_empresa      = opt_tipo_empresa,  
      @w_validacion        = opt_validacion,
      @w_fondos_propios    = opt_fondos_propios, 
      @w_ref_red           = opt_nro_red,
      @w_convierte_tasa    = opt_convierte_tasa,
      @w_tasa_equivalente  = opt_usar_tequivalente,
      @w_fec_embarque      = opt_fecha_embarque,
      @w_fec_dex           = opt_fecha_dex,
      @w_num_deuda_ext     = opt_num_deuda_ext,
      @w_num_comex         = opt_num_comex,
      @w_reestructuracion  = opt_reestructuracion,
      @w_tipo_cambio       = opt_tipo_cambio, 
      @w_numero_reest      = opt_numero_reest,      
      @w_oper_pas_ext      = opt_codigo_externo, 
      @w_banca             = opt_banca,
      @w_promocion         = opt_promocion,
      @w_acepta_ren        = opt_acepta_ren,
      @w_no_acepta         = opt_no_acepta,
      @w_emprendimiento    = opt_emprendimiento,
      @w_plazo             = opt_plazo,
      @w_tplazo            = opt_tplazo,
      @w_tdividendo        = opt_tdividendo,
      @w_periodo_cap       = opt_periodo_cap,
      @w_periodo_int       = opt_periodo_int      
from ca_operacion_tmp
where opt_banco = @i_ref_grupal
       
select @w_dias_gracia = max(dit_gracia_disp)
from ca_dividendo_tmp
where dit_operacion = @w_operacionca

select @w_dias_gracia = isnull(@w_dias_gracia, 0)
select @w_secuencia =  1
  
select @w_tasa = null
  
select @w_tasa = rot_porcentaje       
from ca_rubro_op_tmp
where rot_operacion = @w_operacionca
and   rot_concepto = 'INT'      

--Datos para modificacion
select 
    @i_operacionca             = opt_operacion,
    @i_banco                   = opt_banco,
    @i_anterior                = opt_anterior,
    @i_migrada                 = opt_migrada,
    @i_tramite                 = opt_tramite,
    @i_cliente                 = opt_cliente,
    @i_nombre                  = opt_nombre,
    @i_sector                  = opt_sector,
    @i_toperacion              = opt_toperacion,
    @i_oficina                 = opt_oficina          ,
    @i_moneda                  = opt_moneda           ,
    @i_comentario              = opt_comentario       ,
    @i_oficial                 = opt_oficial          ,
    @i_fecha_ini               = opt_fecha_ini        ,
    @i_fecha_fin               = opt_fecha_fin        ,
    @i_fecha_liq               = opt_fecha_liq        ,
    @i_fecha_pri_cuot          = opt_fecha_pri_cuot   ,
    @i_fecha_reajuste          = opt_fecha_reajuste   ,
    @i_monto                   = opt_monto            ,
    @i_monto_aprobado          = opt_monto_aprobado   ,
    @i_destino                 = opt_destino          ,
    @i_lin_credito             = opt_lin_credito      ,
    @i_ciudad                  = opt_ciudad             ,
    @i_estado                  = opt_estado             ,
    @i_periodo_reajuste        = opt_periodo_reajuste   ,
    @i_reajuste_especial       = opt_reajuste_especial  ,
    @i_tipo                    = opt_tipo               ,
    @i_forma_pago              = opt_forma_pago         ,
    @i_cuenta                  = opt_cuenta             ,
    @i_dias_anio               = opt_dias_anio          ,
    @i_tipo_amortizacion       = opt_tipo_amortizacion  ,
    @i_cuota_completa          = opt_cuota_completa     ,
    @i_tipo_cobro              = opt_tipo_cobro         ,
    @i_tipo_reduccion          = opt_tipo_reduccion     ,
    @i_aceptar_anticipos       = opt_aceptar_anticipos  ,
    @i_precancelacion          = opt_precancelacion     ,
    @i_operacion               = opt_operacion          ,
    @i_tipo_aplicacion         = opt_tipo_aplicacion    ,
    @i_tplazo                  = opt_tplazo             ,
    @i_plazo                   = opt_plazo              ,
    @i_tdividendo              = opt_tdividendo         ,
    @i_periodo_cap             = opt_periodo_cap        ,
    @i_periodo_int             = opt_periodo_int        ,
    @i_dist_gracia             = opt_dist_gracia        ,
    @i_gracia_cap              = opt_gracia_cap         ,
    @i_gracia_int              = opt_gracia_int         ,
    @i_dia_fijo                = opt_dia_fijo           ,
    @i_cuota                   = opt_cuota              ,
    @i_evitar_feriados         = opt_evitar_feriados    ,
    @i_num_renovacion          = opt_num_renovacion     ,
    @i_renovacion              = opt_renovacion         ,
    @i_mes_gracia              = opt_mes_gracia         ,
    @i_reajustable             = opt_reajustable        ,
    @i_dias_clausula           = opt_dias_clausula      ,
    @i_periodo_crecimiento     = opt_periodo_crecimiento,
    @i_tasa_crecimiento        = opt_tasa_crecimiento   ,
    @i_direccion               = opt_direccion          ,
    @i_opcion_cap              = opt_opcion_cap         ,
    @i_tasa_cap                = opt_tasa_cap           ,
    @i_dividendo_cap           = opt_dividendo_cap      ,
    @i_clase_cartera           = opt_clase          ,
    @i_origen_fondos           = opt_origen_fondos          ,
    @i_tipo_crecimiento        = opt_tipo_crecimiento       ,
    @i_num_reest               = opt_numero_reest           ,
    @i_base_calculo            = opt_base_calculo           ,
    @i_ult_dia_habil           = opt_dia_habil          ,
    @i_recalcular              = opt_recalcular_plazo             ,
    @i_tipo_empresa            = opt_tipo_empresa           ,
    @i_validacion              = opt_validacion             ,
    @i_fondos_propios          = opt_fondos_propios         ,
    @i_ref_exterior            = opt_ref_exterior           ,
    @i_sujeta_nego             = opt_sujeta_nego            ,
    @i_ref_red                 = opt_nro_red                ,
    @i_tipo_redondeo           = opt_tipo_redondeo          ,
    @i_causacion               = opt_causacion              ,
    @i_tramite_ficticio        = opt_tramite_ficticio       ,
    @i_grupo_fact              = opt_grupo_fact             ,
    @i_convierte_tasa          = opt_convierte_tasa         ,
    @i_bvirtual                = opt_bvirtual               ,
    @i_extracto                = opt_extracto               ,
    @i_fec_embarque            = opt_fecha_embarque           ,
    @i_fec_dex                 = opt_fecha_dex                ,
    @i_num_deuda_ext           = opt_num_deuda_ext          ,
    @i_num_comex               = opt_num_comex              ,
    @i_pago_caja               = opt_pago_caja              ,
    @i_nace_vencida            = opt_nace_vencida           ,
    @i_calcula_devolucion      = opt_calcula_devolucion     ,
    @i_oper_pas_ext            = opt_codigo_externo           ,
    @i_reestructuracion        = opt_reestructuracion       ,
    @i_mora_retroactiva        = opt_mora_retroactiva       ,
    @i_prepago_desde_lavigente = opt_prepago_desde_lavigente,
    @i_grupal                  = opt_grupal                 ,
    @i_dia_pago                = opt_dia_fijo               ,
    @i_grupo                   = opt_grupo                  ,
    @i_es_grupal               = 'N'                        ,
    @i_fondeador               = opt_fondeador           ,
    @i_tasa_equivalente        = opt_usar_tequivalente    
from ca_operacion_tmp
where opt_banco = @i_ref_grupal

 
--Creando temporal
create table ##clte_individual   
(
  secuencia  numeric identity,
  cliente    int     null,
  valor      money   null,
  banco      cuenta  null,
  operacion  int     null,
  accion     char(1) null
)
          
--Descomponer Cadena Clientes
select @w_contador = 1
while @w_contador <= 5
begin
    if @w_contador = 1 
      select @w_cadena = @i_cliente_1
    
    if @w_contador = 2
        select @w_cadena = @i_cliente_2
        
    if @w_contador = 3 
        select @w_cadena = @i_cliente_3
            
    if @w_contador = 4
        select @w_cadena = @i_cliente_4
                    
    if @w_contador = 5 
        select @w_cadena = @i_cliente_5
                        
    while @w_cadena > ''
    begin         
        select @w_pos = charindex('|', @w_cadena)
        if @w_pos = 0
            select @w_valor = ltrim(rtrim(@w_cadena))
        else    
            select @w_valor = ltrim(rtrim(substring(@w_cadena, 1, @w_pos -1)))
        
        
        if ltrim(rtrim(@w_cadena)) = ltrim(rtrim(@w_valor))
            select @w_cadena = '|'
        else
           select @w_cadena = substring(@w_cadena, @w_pos+1,len(@w_cadena))
        
        if @w_valor > '' and isnumeric(@w_valor) = 1
        begin
            insert ##clte_individual values (convert(int,@w_valor), 0,null,null, 'I')
        end
               
        if ltrim(rtrim(@w_cadena)) = '|'
            select @w_cadena = ''            
    end
    
    select @w_contador = @w_contador + 1
end

--Descomponer Cadena de Valores
select @w_contador  = 1,
       @w_secuencia = 1
while @w_contador <= 6
begin
    if @w_contador = 1 
      select @w_cadena = @i_monto_1
    
    if @w_contador = 2
        select @w_cadena = @i_monto_2
            
    if @w_contador = 3 
        select @w_cadena = @i_monto_3

    if @w_contador = 4
        select @w_cadena = @i_monto_4
        
    if @w_contador = 5 
        select @w_cadena = @i_monto_5
        
    if @w_contador = 6
        select @w_cadena = @i_monto_6
    
    while @w_cadena > ''
    begin      
        select @w_pos = charindex('|', @w_cadena)
        if @w_pos = 0
            select @w_valor = ltrim(rtrim(@w_cadena))
        else    
            select @w_valor = ltrim(rtrim(substring(@w_cadena, 1, @w_pos -1)))
        
        
        if ltrim(rtrim(@w_cadena)) = ltrim(rtrim(@w_valor))
            select @w_cadena = '|'
        else
           select @w_cadena = substring(@w_cadena, @w_pos+1,len(@w_cadena))
        
        if @w_valor > '' and isnumeric(@w_valor) = 1
        begin
            update ##clte_individual 
            set valor = convert(money, @w_valor)
            where secuencia = @w_secuencia
        end
               
        if ltrim(rtrim(@w_cadena)) = '|'
            select @w_cadena = ''            
            
        select @w_secuencia = @w_secuencia + 1
    end
    select @w_contador = @w_contador + 1
end


--Monto de los individuales no supere el valor del padre
select @w_monto_hijas = sum(valor) 
from ##clte_individual 

if @w_monto_hijas <> @w_monto_op
begin     
   
     print 'ERROR: SUMA DE MONTOS DE OPERACIONES INDIVIDUALES ES DIFERENTE AL MONTO DE LA OPERACION PADRE'
     return 70204
end

--Clientes individuales pertenezca al grupo indicado
if exists(select 1 from ##clte_individual
          where cliente not in (select cg_ente from cobis..cl_cliente_grupo
                                 where cg_grupo = @i_grupo))
begin     
    print 'ERROR: EXISTEN CLIENTES DE OPERACIONES HIJAS QUE NO PERTENECEN AL GRUPO '
    return 70205
end

--Clientes individuales pertenezca al grupo indicado
if exists(select 1 from ##clte_individual
          where cliente not in (select cg_ente from cobis..cl_cliente_grupo
                                 where cg_grupo = @i_grupo
                                   and cg_estado = 'V'))
begin     
    print 'ERROR: EXISTEN CLIENTES DE OPERACIONES HIJAS QUE ESTAN INACTIVAS EN EL GRUPO'
    return 70205
end


--Que todos los clientes tengas valores en prestamo
--Clientes individuales pertenezca al grupo indicado
if exists(select 1 from ##clte_individual
          where valor is null or valor = 0)
begin     
    print 'ERROR: EXISTEN CLIENTES QUE NO HAN ASIGNADO VALOR A LA OPERACION'
    return 70205
end

--Actualizo operacion, banco y estado de grupales
update ##clte_individual
set operacion = op_operacion,
    banco     = op_banco,
    accion    = 'U'
from ca_operacion, ##clte_individual 
where op_ref_grupal = @i_ref_grupal
and op_cliente = cliente

--Actualizar Clientes que se desasocian del grupo
insert ##clte_individual
select  op_cliente,
        op_monto,
        op_banco,
        op_operacion,
        'E'
from ca_operacion
where op_ref_grupal = @i_ref_grupal
and op_cliente not in (select cliente from ##clte_individual)

select @w_secuencia = 0
while 1=1
begin    
    select @w_secuencia = @w_secuencia + 1 
    
    select @w_cliente   = cliente,
           @w_monto     = valor,
           @w_nombre    = en_nomlar,
           @w_operacion = operacion,
           @w_banco     = banco,
           @w_accion    = accion
    from  ##clte_individual, cobis..cl_ente
    where cliente = en_ente 
    and   secuencia = @w_secuencia
  
    if @@rowcount = 0
        break

    if @w_accion = 'U'  or  @w_accion = 'E' 
    begin
        /* CREAR OPERACION TEMPORAL */
        exec @w_return = sp_borrar_tmp
        @i_banco  = @w_banco,
        @s_term   = @s_user,
        @s_user   = @s_user
        
        if @w_return <> 0 return @w_return
        
        exec @w_return = sp_crear_tmp
        @s_user        = @s_user,
        @s_term        = @s_term, 
        @i_banco       = @w_banco,
        @i_accion      = 'A'
        
        if @w_return <> 0 return @w_return
    end
               
    if @w_accion = 'U' 
    begin        
        select @w_ref_grupal = @i_ref_grupal,
               @w_grupo      = @i_grupo
               
        exec @w_return = sp_modificar_operacion             
             @s_user                      = @s_user,
             @s_sesn                      = @s_sesn,
             @s_date                      = @s_date,
             @s_term                      = @s_term,
             @s_ofi                       = @s_ofi,
             @i_calcular_tabla            = 'S',
             @i_tabla_nueva               = @i_tabla_nueva,
             @i_operacionca               = @w_operacion,
             @i_banco                     = @w_banco,
             @i_tramite                   = @i_tramite,
             @i_cliente                   = @w_cliente,
             @i_nombre                    = @w_nombre,
             @i_sector                    = @i_sector,
             @i_toperacion                = @i_toperacion,
             @i_oficina                   = @i_oficina,
             @i_moneda                    = @i_moneda,
             @i_comentario                = @i_comentario,
             @i_oficial                   = @i_oficial,
             @i_fecha_ini                 = @i_fecha_ini,
             @i_fecha_fin                 = @i_fecha_fin,
             @i_fecha_ult_proceso         = @i_fecha_ini,  ----@i_fecha_ult_proceso,
             @i_fecha_liq                 = @i_fecha_liq,
             @i_fecha_reajuste            = @i_fecha_reajuste,
             @i_monto                     = @w_monto,
             @i_monto_aprobado            = @w_monto,
             @i_destino                   = @i_destino,
             @i_lin_credito               = @i_lin_credito,
             @i_ciudad                    = @i_ciudad,
             @i_periodo_reajuste          = @i_periodo_reajuste,
             @i_reajuste_especial         = @i_reajuste_especial,
             @i_tipo                      = @i_tipo,
             @i_forma_pago                = @i_forma_pago,
             @i_cuenta                    = @i_cuenta,
             @i_dias_anio                 = @i_dias_anio,
             @i_tipo_amortizacion         = @i_tipo_amortizacion,
             @i_cuota_completa            = @i_cuota_completa,
             @i_tipo_cobro                = @i_tipo_cobro,
             @i_tipo_reduccion            = @i_tipo_reduccion,
             @i_aceptar_anticipos         = @i_aceptar_anticipos,
             @i_precancelacion            = @i_precancelacion,
             @i_tipo_aplicacion           = @i_tipo_aplicacion,
             @i_tplazo                    = @i_tplazo,
             @i_plazo                     = @i_plazo,
             @i_tdividendo                = @i_tdividendo,
             @i_periodo_cap               = @i_periodo_cap,
             @i_periodo_int               = @i_periodo_int,
             @i_dist_gracia               = @i_dist_gracia,
             @i_gracia_cap                = @i_gracia_cap,
             @i_gracia_int                = @i_gracia_int,
             @i_dia_fijo                  = @i_dia_fijo,
             @i_fecha_pri_cuot            = @i_fecha_pri_cuot,
             @i_evitar_feriados           = @i_evitar_feriados,
             @i_num_renovacion            = @i_num_renovacion,
             @i_renovacion                = @i_renovacion,
             @i_mes_gracia                = @i_mes_gracia,
             @i_formato_fecha             = @i_formato_fecha,
             @i_upd_clientes              = @i_upd_clientes,
             @i_dias_gracia               = @w_dias_gracia,
             @i_reajustable               = @i_reajustable,
             @i_dias_clausula             = @i_dias_clausula,
             @i_periodo_crecimiento       = @i_periodo_crecimiento,
             @i_tasa_crecimiento          = @i_tasa_crecimiento,
             @i_control_tasa              = @i_control_tasa,
             @i_direccion                 = @i_direccion,
             @i_opcion_cap                = @i_opcion_cap,
             @i_tasa_cap                  = @i_tasa_cap,
             @i_dividendo_cap             = @i_dividendo_cap,
             @i_tipo_cap                  = @i_tipo_cap,
             @i_tipo_crecimiento          = @i_tipo_crecimiento,
             @i_num_reest                 = @i_num_reest,
             @i_base_calculo              = @i_base_calculo,
             @i_ult_dia_habil             = @i_ult_dia_habil,
             @i_recalcular                = @i_recalcular,
             @i_clase_cartera             = @i_clase_cartera,
             @i_tipo_empresa              = @i_tipo_empresa,
             @i_validacion                = @i_validacion,
             @i_origen_fondos             = @i_origen_fondos,
             @i_fondos_propios            = @i_fondos_propios,
             @i_ref_exterior              = @i_ref_exterior,
             @i_sujeta_nego               = @i_sujeta_nego,
             @i_ref_red                   = @i_ref_red,
             @i_tipo_redondeo             = @i_tipo_redondeo,
             @i_causacion                 = @i_causacion,
             @i_tramite_ficticio          = @i_tramite_ficticio,
             @i_grupo_fact                = @i_grupo_fact,
             @i_convierte_tasa            = @i_convierte_tasa,
             @i_bvirtual                  = @i_bvirtual,
             @i_extracto                  = @i_extracto,
             @i_fec_embarque              = @i_fec_embarque,
             @i_fec_dex                   = @i_fec_dex,
             @i_num_deuda_ext             = @i_num_deuda_ext,
             @i_num_comex                 = @i_num_comex,
             @i_pago_caja                 = @i_pago_caja,
             @i_nace_vencida              = @i_nace_vencida,
             @i_calcula_devolucion        = @i_calcula_devolucion,
             @i_oper_pas_ext              = @i_oper_pas_ext,
             @i_reestructuracion          = @i_reestructuracion,
             @i_mora_retroactiva          = @i_mora_retroactiva,
             @i_prepago_desde_lavigente   = @i_prepago_desde_lavigente,
             @i_valida_param              = @i_valida_param,
             @i_tasa                      = @w_tasa,
             @i_grupal                    = @i_grupal,                 
             @i_dia_pago                  = @i_dia_pago,               
             @i_fecha_fija                = @i_fecha_fija,             
             @i_grupo                     = @w_grupo,                  
             @i_ref_grupal                = @w_ref_grupal,             
             @i_es_grupal                 = 'N',              
             @i_estado                    = 0 ,
             @i_fondeador                 = @i_fondeador,
             @i_grupo_contable            = @i_grupo_contable           --GFP 06-01-2022
             
        if @w_return != 0
           return @w_return     
           
        --Dejar la operacion en estado 3 cancelada
        update ca_operacion_tmp
        set opt_estado = 3
        where opt_banco = @w_banco  
        
        if @@error != 0
           return 1          
    end   
    
    if @w_accion = 'E'
    begin
        update ca_operacion_tmp
        set opt_ref_grupal = null,
            opt_grupo = 0
        where opt_banco = @w_banco  
        
        if @@error != 0
           return 1           
    end
    
    if @w_accion = 'I'
    begin
        exec @w_return = sp_crear_operacion
             @s_user              = @s_user,
             @s_sesn              = @s_sesn,
             @s_ofi               = @s_ofi ,
             @s_date              = @s_date,
             @s_term              = @s_term,
             @i_cliente           = @w_cliente,
             @i_nombre            = @w_nombre,
             @i_sector            = @w_sector,
             @i_toperacion        = @w_toperacion,
             @i_oficina           = @w_oficina        ,
             @i_moneda            = @w_moneda        ,
             @i_comentario        = 'CREACION OPERACION HIJA',
             @i_oficial           = @w_oficial       ,
             @i_fecha_ini         = @w_fecha_ini     ,
             @i_monto             = @w_monto         ,
             @i_monto_aprobado    = @w_monto ,
             @i_destino           = @w_destino       ,
             @i_lin_credito       = @w_lin_credito   ,
             @i_ciudad            = @w_ciudad        ,
             @i_forma_pago        = @w_forma_pago    ,
             @i_cuenta            = @w_cuenta        ,
             @i_dia_pago          = @w_dia_pago        ,
             @i_clase_cartera     = @w_clase_cartera   ,
             @i_origen_fondos     = @w_origen_fondos   ,
             @i_tipo_empresa      = @w_tipo_empresa    ,
             @i_validacion        = @w_validacion      ,
             @i_fondos_propios    = @w_fondos_propios  ,
             @i_ref_red           = @w_ref_red         ,
             @i_convierte_tasa    = @w_convierte_tasa  ,
             @i_fec_embarque      = @w_fec_embarque    ,
             @i_fec_dex           = @w_fec_dex         ,
             @i_num_deuda_ext     = @w_num_deuda_ext   ,
             @i_num_comex         = @w_num_comex       ,
             @i_reestructuracion  = @w_reestructuracion,
             @i_tipo_cambio       = @w_tipo_cambio     ,
             @i_numero_reest      = @w_numero_reest    ,
             @i_oper_pas_ext      = @w_oper_pas_ext    ,
             @i_en_linea          = @i_en_linea,
             @i_banca             = @w_banca         ,
             @i_promocion         = @w_promocion     , 
             @i_acepta_ren        = @w_acepta_ren    , 
             @i_no_acepta         = @w_no_acepta     , 
             @i_emprendimiento    = @w_emprendimiento, 
             @i_plazo             = @w_plazo         ,
             @i_tplazo            = @w_tplazo        ,
             @i_tdividendo        = @w_tdividendo    ,
             @i_periodo_cap       = @w_periodo_cap   ,
             @i_periodo_int       = @w_periodo_int   ,
             @i_grupo             = @i_grupo,                  
             @i_ref_grupal        = @i_ref_grupal,  
             @i_es_grupal         = 'N',
             @i_tasa              = @w_tasa,
			 @i_grupo_contable    = @i_grupo_contable           --GFP 06-01-2022
                 
        if @w_return != 0
           return @w_return
           
    end    
end


/* LRE S276526 Se comenta llamada por pues en TEC se usa Administracion Grupal
--Actualizaci+Ýn de Datos Grupales
exec @w_return = sp_actualiza_grupal
@i_banco      = @i_ref_grupal,
@i_desde_cca  = 'C'
 
if @w_return != 0
begin
    print 'ERROR: ACTUALIZANDO DATOS DE OPERACIONES GRUPALES'
    return 70206
end 

*/

   
return 0



go

