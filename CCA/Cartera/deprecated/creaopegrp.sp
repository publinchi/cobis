/************************************************************************/
/*      Archivo:                creaopegrp.sp                           */
/*      Stored procedure:       sp_crear_operacion_grp                  */
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
/*      Valida datos para la creacion de las operaciones hijas de la    */
/*      operacion grupal                                                */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*     15/04/2019       A. Giler        Operaciones Grupales            */
/*     29/04/2019   L. Gerardo Barron   Obtencion de datos de cliente   */
/*     05/06/2019       A. Giler        Nueva version Grupales          */
/*     18/10/2019      J.Calvillo       Rol desertor                    */
/*     08/04/2021      J.Hernández      Cambio temporal                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crear_operacion_grp')
    drop proc sp_crear_operacion_grp
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_crear_operacion_grp
   @s_user              login        = null,
   @s_sesn              int          = null,
   @s_ssn               int          = null,
   @s_date              datetime     = null,
   @s_term              varchar(30)  = null,
   @s_lsrv              varchar (30) = null,
   @s_ofi               smallint     = null,
   @t_trn               int          = null,      --7450   
   @i_opcion            char(1),                  --Q (Busca integrantes Grpo) 
   @i_cliente           int          = null,
   @i_operacion         int,
   @i_sec_hijas         varchar(200),
   @o_clte_err          int          = null out,
   @o_mensaje           varchar(100)  = null out
    

as
declare
   @w_sp_name                       descripcion,
   @w_return                        int,
   @w_error                         int,
   @w_msg                           mensaje,
   @w_secuencia                     int,
   @w_cliente                       int,
   @w_nombre                        descripcion,
   @w_sector                        catalogo,
   @w_toperacion                    catalogo,
   @w_oficina                       smallint,
   @w_moneda                        tinyint,
   @w_comentario                    varchar(255),
   @w_oficial                       smallint,
   @w_fecha_ini                     datetime,  
   @w_fecha_fin                     datetime,
   @w_fecha_ult_proceso             datetime,
   @w_fecha_liq                     datetime,
   @w_fecha_reajuste                datetime,
   @w_monto                         money,
   @w_monto_aprobado                money,
   @w_destino                       catalogo,
   @w_lin_credito                   cuenta,
   @w_ciudad                        smallint,
   @w_estado                        tinyint,
   @w_periodo_reajuste              smallint,
   @w_reajuste_especial             char(1),
   @w_tipo                          char(1),
   @w_forma_pago                    catalogo,
   @w_cuenta                        cuenta,
   @w_dias_anio                     smallint,
   @w_tipo_amortizacion             varchar(30),
   @w_cuota_completa                char(1),
   @w_tipo_cobro                    char(1),
   @w_tipo_reduccion                char(1),
   @w_aceptar_anticipos             char(1),
   @w_precancelacion                char(1),
   @w_num_dec                       tinyint,
   @w_tplazo                        catalogo,
   @w_plazo                         smallint,
   @w_tdividendo                    catalogo,
   @w_periodo_cap                   smallint,
   @w_periodo_int                   smallint,
   @w_tasa                          float,
   @w_gracia_cap                    smallint,
   @w_gracia_int                    smallint,
   @w_dist_gracia                   char(1),
   @w_tipo_cambio                   char(1),
   @w_fecha_fija                    char(1),
   @w_dia_pago                      tinyint,
   @w_cuota_fija                    char(1),
   @w_evitar_feriados               char(1),
   @w_tipo_producto                 char(1),
   @w_renovacion                    char(1),
   @w_mes_gracia                    tinyint,
   @w_tipo_aplicacion               char(1),
   @w_reajustable                   char(1),
   @w_est_novigente                 tinyint,
   @w_est_credito                   tinyint,
   @w_dias_dividendo                int,
   @w_dias_aplicar                  int,
   @w_periodo_crecimiento           smallint,
   @w_tipo_empresa                  catalogo ,
   @w_validacion                    catalogo ,
   @w_fondos_propios                char(1),
   @w_fec_embarque                  datetime,
   @w_fec_dex                       datetime,
   @w_ref_exterior                  cuenta,      
   @w_sujeta_nego                   char(1),     
   @w_ref_red                       varchar(24) ,
   @w_convierte_tasa                char(1),     
   @w_tasa_equivalente              char(1),
   @w_tipo_linea                    catalogo,   
   @w_num_deuda_ext                 cuenta ,
   @w_num_comex                     cuenta,
   @w_oper_pas_ext                  varchar(64),
   @w_promocion                     char(1),
   @w_grupo                         int,
   @w_clte_hija                     int,
   @w_acepta_ren                    char(1),
   @w_no_acepta                     char(1000),
   @w_emprendimiento                char(1),
   @w_banca                         catalogo,
   @w_tasa_crecimiento              float,
   @w_origen_fondos                 catalogo,   
   @w_operacion                     int,
   @w_banco                         cuenta,
   @w_banco_padre                   cuenta,
   @w_numero_reest                  int,
   @w_sal_min_cla_car               int,
   @w_sal_min_vig                   money,
   @w_base_calculo                  char(1),
   @w_ult_dia_habil                 char(1),
   @w_recalcular                    char(1),
   @w_prd_cobis                     tinyint,
   @w_tipo_redondeo                 tinyint,
   @w_causacion                     char(1),
   @w_subtipo_linea                 catalogo,
   @w_bvirtual                      char(1),
   @w_extracto                      char(1),
   @w_reestructuracion              char(1),
   @w_subtipo                       char(1),
   @w_naturaleza                    char(1),
   @w_pago_caja                     char(1),
   @w_nace_vencida                  char(1),
   @w_valor_rubro                   money,
   @w_calcula_devolucion            char(1),
   @w_concepto_interes              catalogo,
   @w_est_cancelado                 tinyint,
   @w_clase_cartera                 catalogo,
   @w_dias_gracia                   smallint,
   @w_tasa_referencial              catalogo,
   @w_porcentaje                    float,
   @w_modalidad                     char(1),
   @w_periodicidad                  char(1),
   @w_tasa_aplicar                  catalogo,
   @w_entidad_convenio              catalogo,
   @w_mora_retroactiva              char(1),
   @w_prepago_desde_lavigente       char(1),
   @w_rowcount                      int,
   @w_control_dia_pago              char(1),
   @w_pa_dimive                     tinyint,
   @w_pa_dimave                     tinyint,
   @w_tr_tipo                       char(1),
   @w_monto_seguros                 money,
   @w_default1                      varchar(50),
   @w_default2                      varchar(50),
   @w_secuencial                    int,
   @w_intentos                      int,
   @w_cnt_intentos                  int,
   @w_oper_hija                     int,
   @w_sesion                        int,
   @w_tramite                       int,
   @w_mensaje                       varchar(100),
   @w_val_ahorro_vol                int,
   @w_fecha_venc                    datetime,
   @w_monto_odp                     money,              --AGI TEC
   @w_tretiro_odp                   catalogo,           --AGI TEC
   @w_banco_odp                     catalogo,           --AGI TEC
   @w_lote_odp                      int,                --AGI TEC
   @w_odp_generada                  varchar(20),        --AGI TEC
   @w_convenio                      varchar(10),        --AGI TEC
   @w_fecha_odp                     datetime,           --AGI TEC
   @w_secuencia_odp                 int,                --AGI TEC
   @w_cuenta_aho_grupal             cuenta,             --AGI TEC
   @w_sec_hijas                     varchar(200),
   @w_bco_tec                       catalogo
           
select  @w_val_ahorro_vol = pa_int 
from cobis..cl_parametro 
where pa_nemonico = 'VAHVO' 
and pa_producto = 'CRE'


--JH Se comenta la variable @w_bco_tec debido a que no existe la columna ba_es_para_odis en la tabla ba_banco Cambio temporal
/*select @w_bco_tec  = ba_codigo
from cob_bancos..ba_banco 
where ba_es_para_odis = 'true'

if isnull(convert(INT, @w_bco_tec),0) = 0 
    select @w_bco_tec = 6 */
	
select @w_bco_tec = 6

select @w_intentos =0,
       @w_cnt_intentos = 1
 
select @w_intentos = pa_tinyint  
from cobis..cl_parametro
where pa_nemonico = 'INTHIJ'
  
if @i_opcion = 'B' -- Busqueda de grupo
begin
	--Se obtienen datos default 1
	select top 1 @w_default1 = b.codigo from cobis..cl_tabla as a
    inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'cl_sectoreco'
    
	--Se obtienen datos default 2
	select top 1 @w_default2 = b.codigo from cobis..cl_tabla as a
    inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'cl_actividad'
	
    --Consulta final
    select en_grupo
		    ,isnull(en_sector,@w_default1)
			,isnull(en_actividad,@w_default2)
    from cobis..cl_ente
    where en_ente = convert(int, @i_cliente)
    
    if @@rowcount = 0
    begin 
        print 'ERROR: CLIENTE NO EXISTE.'
        return 70183
    end
end  

if @i_opcion = 'Q' -- Busqueda de integrantes de grupos
begin
    
    select gr_grupo, gr_nombre 
    from cobis..cl_grupo
    where gr_representante = convert(int, @i_cliente)
    
    if @@rowcount = 0
    begin 
        print 'ERROR: CLIENTE NO PERTENECE A UN GRUPO.'
        return 70183
    end
    
    select 'Cliente'         = cg_ente ,
           'Nombre'          = substring(en_nomlar,1,100),
           'MontoSolicitado' = 0
    from cobis..cl_cliente_grupo, cobis..cl_ente
    where cg_grupo = convert(int, @w_grupo)
    and   cg_ente = en_ente
    and   cg_estado = 'V'
    order by cg_ente
    
    if @@rowcount = 0
    begin 
        print 'ERROR: EL GRUPO DE LA REFERENCIA NO EXISTE.'
        return 70183
    end
end  

if @i_opcion = 'I'   --Crear Operaciones GRUPALES
begin
    --Validando que existan hijas para crear
    if not exists(select 1 from ca_interf_hijas_tmp where iht_operacion = @i_operacion and iht_rol <> 'D')
    begin
        select @o_clte_err  = 0,
               @o_mensaje   = 'Error Operacion Padre no registra Hijas a crear'        
        return 725032  
    end
    
    --Que todos los clientes tengas valores en prestamo
    if exists(select 1 from ca_interf_hijas_tmp
             where (iht_monto is null or iht_monto = 0) and iht_rol <> 'D' )
    begin     
        select @o_clte_err  = 0,
               @o_mensaje   = 'Error Existen hijas con valor de cero para solicitud de prestamo'
        return 725033
    end
    
    --Que no existan hijos repetidos para la solicitud del padre.
    if exists (select count(1), iht_cliente from ca_interf_hijas_tmp
                where iht_operacion = @i_operacion
                group by iht_cliente
                having count(1) > 1)
    begin     
        select @o_clte_err  = 0,
               @o_mensaje   = 'Error Existen hijos con doble solicitud de prestamo'
        return 725034
    end
           
    --Creacion de operaciones hijas tomar datos del padre
    select
          @w_operacion         = op_operacion,
          @w_banco_padre       = op_banco,
          @w_sector            = op_sector,
          @w_toperacion        = op_toperacion,
          @w_tramite           = op_tramite,
          @w_oficina           = op_oficina,
          @w_moneda            = op_moneda,
          @w_oficial           = op_oficial,
          @w_fecha_ini         = op_fecha_ini,
          @w_lin_credito       = op_lin_credito,
          @w_ciudad            = op_ciudad,
          @w_forma_pago        = op_forma_pago,
          @w_cuenta            = op_cuenta,
          @w_dia_pago          = op_dia_fijo,
          @w_clase_cartera     = op_clase,
          @w_origen_fondos     = op_origen_fondos,
          @w_tipo_empresa      = op_tipo_empresa,  
          @w_validacion        = op_validacion,
          @w_fondos_propios    = op_fondos_propios, 
          @w_ref_red           = op_nro_red,
          @w_convierte_tasa    = op_convierte_tasa,
          @w_tasa_equivalente  = op_usar_tequivalente,
          @w_fec_embarque      = op_fecha_embarque,
          @w_fec_dex     = op_fecha_dex,
          @w_num_deuda_ext     = op_num_deuda_ext,
          @w_num_comex         = op_num_comex,
          @w_reestructuracion  = op_reestructuracion,
          @w_tipo_cambio       = op_tipo_cambio, 
          @w_numero_reest      = op_numero_reest,      
          @w_oper_pas_ext      = op_codigo_externo, 
          @w_banca             = op_banca,
          @w_promocion         = op_promocion,
          @w_acepta_ren        = op_acepta_ren,
          @w_no_acepta         = op_no_acepta,
          @w_emprendimiento    = op_emprendimiento,
          @w_plazo             = op_plazo,
          @w_tplazo            = op_tplazo,
          @w_tdividendo        = op_tdividendo,
          @w_periodo_cap       = op_periodo_cap,
          @w_periodo_int       = op_periodo_int,
          @w_grupo             = op_grupo
    from ca_operacion
    where op_operacion = @i_operacion
              
    select @w_dias_gracia = max(di_gracia_disp)
    from ca_dividendo
    where di_operacion = @w_operacion
      
    select @w_dias_gracia = isnull(@w_dias_gracia, 0)
    select @w_secuencia =  1
          
    select @w_tasa = null
          
    select @w_tasa = ro_porcentaje       
    from ca_rubro_op
    where ro_operacion = @w_operacion
    and   ro_concepto = 'INT'
     
    select @w_clte_hija = min(iht_cliente)
    from ca_interf_hijas_tmp
    where iht_operacion = @i_operacion      and
          iht_rol <> 'D'
    
    select @w_fecha_venc = di_fecha_ven
    from ca_dividendo
    where di_operacion  = @i_operacion 
    and  di_dividendo = 1
    
    select @w_tipo = case when iot_tipo_operacion = 'IN' then 'O'
                          when iot_tipo_operacion = 'RE' then 'R'
                          when iot_tipo_operacion = 'RF' then 'R'
                     end     
    from ca_interf_op_tmp 
    where iot_operacion = @i_operacion
    
    select @w_tipo    = 'O'  --AGC TCE.  Las hijas no se renovan, siempre se van como Original. Admin.Grupal
    
    --AGI. Elimina datos de tramite grupal si el padre las creo.
    delete cob_credito..cr_tramite_grupal
    where tg_referencia_grupal = @w_banco_padre
        
    select @w_sec_hijas = @i_sec_hijas
    while 1=1
    begin        
        --Obtener secuencial de la hija     
        select @w_secuencia = convert(int, substring(@i_sec_hijas, 1, charindex('|', @i_sec_hijas) - 1))
        --if (len(@i_sec_hijas) - len(replace(@i_sec_hijas, '|', ''))) / len('|') > 1
        if (((len(@i_sec_hijas) - len(replace(@i_sec_hijas, '|', ''))) / len('|')) > 1)
            select @w_sec_hijas = substring(@i_sec_hijas, charindex('|', @i_sec_hijas) + 1, len(@i_sec_hijas))
        else
            select @i_sec_hijas = ''
        
        select @i_sec_hijas = @w_sec_hijas
                        
        select @w_cliente = iht_cliente,
               @w_monto   = iht_monto,
               @w_nombre  = en_nomlar,
               @w_destino = iht_destino_eco,
               @w_sesion  = iht_sesn
        from  ca_interf_hijas_tmp, cobis..cl_ente
        where iht_operacion = @i_operacion
        and   iht_cliente  = @w_clte_hija
        and   iht_cliente = en_ente
      
        if @@rowcount = 0
            break
            
        select @s_ssn  = @w_secuencia,
               @s_sesn = @w_secuencia

        while 1=1
        begin      
            exec @w_return = sp_crear_operacion
                 @s_user              = @s_user,
                 @s_sesn              = @s_sesn,
                 @s_ssn               = @s_ssn,
                 @s_ofi               = @s_ofi ,
                 @s_date              = @s_date,
                 @s_term              = @s_term,
                 @i_cliente           = @w_cliente,
                 @i_nombre            = @w_nombre,
                 @i_sector            = @w_sector,
                 @i_toperacion        = @w_toperacion,
                 @i_oficina           = @w_oficina       ,
                 @i_moneda            = @w_moneda        ,
             @i_comentario        = @w_comentario    ,
                 @i_oficial           = @w_oficial       ,
                 @i_fecha_ini         = @w_fecha_ini     ,
                 @i_monto             = @w_monto         ,
                 @i_monto_aprobado    = @w_monto ,
                 @i_destino           = @w_destino       ,
                 @i_lin_credito       = @w_lin_credito   ,
                 @i_ciudad            = @w_ciudad        ,
                 @i_forma_pago        = @w_forma_pago    ,
                 @i_cuenta            = @w_cuenta        ,
                 @i_formato_fecha     = 101,
                 @i_dia_pago          = @w_dia_pago        ,
                 @i_clase_cartera     = @w_clase_cartera   ,
                 @i_origen_fondos     = @w_origen_fondos   ,
                 @i_tipo_empresa      = @w_tipo_empresa    ,
                 @i_validacion        = @w_validacion      ,
                 @i_fondos_propios    = @w_fondos_propios  ,
                 @i_ref_red           = @w_ref_red         ,
                 @i_convierte_tasa    = @w_convierte_tasa  ,
                 @i_tasa_equivalente  = @w_tasa_equivalente,
                 @i_fec_embarque      = @w_fec_embarque    ,
                 @i_fec_dex           = @w_fec_dex         ,
                 @i_num_deuda_ext     = @w_num_deuda_ext   ,
                 @i_num_comex         = @w_num_comex       ,
                 @i_reestructuracion  = @w_reestructuracion,
                 @i_tipo_cambio       = @w_tipo_cambio     ,
                 @i_numero_reest      = @w_numero_reest    ,
                 @i_oper_pas_ext      = @w_oper_pas_ext    ,
                 @i_en_linea          = 'N',
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
                 @i_ref_grupal        = @w_banco_padre,  
                 @i_grupo             = @w_grupo,
                 @i_fecha_ven_pc      = @w_fecha_venc,
                 @i_es_grupal         = 'N',
                 @i_grupal            = 'S',
                 @i_tasa              = @w_tasa,
                 @i_tipo              = @w_tipo,
                 @o_banco             = @w_banco out
                     
            if @w_return != 0 
            begin
                if @w_cnt_intentos = @w_intentos
                begin
                    select @o_clte_err  = @w_cliente,
                           @o_mensaje   = isnull(mensaje, 'Error creando Operacion Hija')
                    from cobis..cl_errores
                    where numero = @w_return                     
                    
                    return @w_return
                end
            end
            else
                break
            
            select @w_cnt_intentos = @w_cnt_intentos + 1   
        end  
        
        select @w_oper_hija         = opt_operacion,
               @w_cuenta_aho_grupal = opt_cuenta
        from ca_operacion_tmp
        where opt_banco = @w_banco

        -- Actualizo el estado de la hija a null
        update ca_operacion_tmp
        set opt_estado_hijas = null
        where opt_banco = @w_banco
        
        -- Insertar el tramite Grupal'
        insert cob_credito..cr_tramite_grupal
			   (tg_tramite,             tg_grupo,           tg_cliente,         tg_monto,       
                tg_grupal,              tg_operacion,       tg_prestamo,        tg_referencia_grupal,       
                tg_participa_ciclo,     tg_monto_aprobado,  tg_ahorro)
        values (                         
			    @w_tramite,         @w_grupo,           @w_cliente,         @w_monto,       
                'S',                @w_oper_hija,       @w_banco,           @w_banco_padre,                  
                'N',                @w_monto,           @w_val_ahorro_vol)
			   	                   
        if @@error <> 0
        begin
            select @o_clte_err = @w_cliente,
                   @o_mensaje  = 'Error. Insertando Tramite Grupal'
            return 2103001
        end
        
        --Validar que exista el seguro de la hija  '  
        if not exists(select 1 from ca_interf_hijas_tmp, ca_interf_seguros_tmp 
                  where iht_operacion = @i_operacion 
                    and iht_cliente = @w_cliente
                    and iht_sesn    = @w_sesion
                    and ist_cliente = iht_cliente
                    and iht_sesn    = ist_sesn)
        begin
            select @o_clte_err = @w_cliente,
                   @o_mensaje  = 'Error. Operacion Hija no registra seguro'
            return 725035
        end
        
        exec @w_error =  sp_seguros_grp
             @s_user              = @s_user,
             @s_sesn              = @s_sesn,
             @s_ssn               = @s_ssn,
             @s_ofi               = @s_ofi ,
             @s_date              = @s_date,
             @s_term              = @s_term,
             @i_opcion            = 'I',
             @i_cliente           = @w_cliente,       
             @i_oper_padre        = @i_operacion,
             @i_oper_hija         = @w_oper_hija,
             @i_sesion            = @w_sesion,
             @o_mensaje           = @w_mensaje out
             
        if @w_error != 0 
        begin
            select @o_clte_err = @w_cliente,
                   @o_mensaje  = @w_mensaje
            return 725037
        end
       
        --AGC 05JUL19 Ordenes de Pago'        
        select @w_monto_odp = iot_monto_desembolso,
               @w_tretiro_odp = case when iot_tipo_orden = 'I' then 'ODI'
                               else 'ODP'
                               end,
               @w_banco_odp  =  case when iot_tipo_orden = 'I' then @w_bco_tec
                               else (select ba_codigo from cob_bancos..ba_banco
                                     where ba_codigo = iot_banco  )
                               end,       
               @w_lote_odp   = iot_lote
        from ca_interf_ordenp_tmp
        where iot_operacion = @i_operacion
         and  iot_cliente   = @w_cliente
         
        exec @w_error =  cobis..sp_dispersion_retiro
            @s_user                   = @s_user,
            @s_ssn                    = @s_ssn,
            @s_lsrv                   = @s_lsrv,
            @s_date                   = @s_date,
            @s_ofi                    = @s_ofi,
            @t_trn                    = 2213,
            @i_operacion              =  'I' ,                  -- INSERCION DE FORMAS DE RETIRO
            @i_grupo                  = @w_grupo,               -- CODIGO DEL GRUPO SOLIDARIO
            @i_cliente                = @w_cliente,             -- CODIGO DEL CLIENTE INDIVIDUAL
            @i_car_operacion          = @i_operacion,           -- CODIGO INTERNO DE LA OPERACION DE CARTERA
            @i_forma_retiro           = @w_tretiro_odp,         -- FORMA DE RETIRO SELECCIONADA PARA EL CLIENTE. TIENE SOLO DOS OPCIONES = "ODI", "ODP"   (Retiro por Caja o por Banco corresponsal)
            @i_monto                  = @w_monto_odp,           -- MONTO DEFINIDO DEL RETIRO PARA EL CLIENTE
            @i_fecha_apl              = @s_date,                -- FECHA PROCESO
            @i_banco                  = @w_banco_odp,           -- SI LA FORMA ES "ODP" ENTONCES INDICAR EL CODIGO DEL BANCO CORRESPONSAL = cob_bancos..ba_banco.ba_codigo
            @i_lote                   = @w_lote_odp            -- CODIGO DE LOTE ENVIADO POR CAME PARA CON ESTE CODIGO CONSULTAR LUEGO LAS ODP'S)
                        
        if @w_error != 0 
        begin
            select @o_clte_err  = @w_cliente,
                   @o_mensaje   = isnull(mensaje, 'Error ejecutando cobis..sp_dispersion_retiro')
            from cobis..cl_errores
            where numero = @w_error 
            
            return @w_error 
        end
               
        --Pasar a Definitivas
        exec @w_error =  sp_operacion_def
        @i_banco = @w_banco,
        @s_date  = @s_date,
        @s_sesn  = @s_sesn,
        @s_user  = @s_user,
        @s_ofi   = @s_ofi
        
        if @w_error != 0 
        begin
            select @o_clte_err = @w_cliente,
                   @o_mensaje  = 'Error. Pasando Operacion Hija a Definitivas'
            return 725036
        end


        exec @w_error =  sp_borrar_tmp
        @i_banco  = @w_banco,
        @s_sesn   = @s_sesn,
        @s_user   = @s_user,
        @s_term   = @s_ofi
        
        if @w_error != 0 
        begin
            select @o_clte_err = @w_cliente,
                   @o_mensaje  = 'Error. Eliminado Temporales de Operacion Hija'
            return 725037
        end
        
        --Seguir con el siguiente hijos
        select @w_clte_hija = min(iht_cliente)
        from ca_interf_hijas_tmp
        where iht_operacion = @i_operacion
        and iht_cliente > @w_cliente 
        and iht_rol <> 'D'
        
        if @@rowcount = 0 or @w_clte_hija = @w_cliente 
            break
    end

    --Guardar en la tabla de Ciclos
    exec @w_return = sp_man_ciclo 
    @i_grupo                = @w_grupo,
    @i_modo                 = 'I',
    @i_grupal               = 'S',
    @i_ref_grupal           = @w_banco_padre,
    @i_tramite_grupal       = @w_tramite,
    @i_cuenta_aho_grupal    = @w_cuenta_aho_grupal
    
    if @w_return != 0
    begin
        select @o_clte_err  = @w_cliente,
               @o_mensaje   = isnull(mensaje, 'Error Ingresando Ciclo de Grupal')
        from cobis..cl_errores
        where numero = @w_return
        
        return @w_return
    end         
    
  /*  LRE S276526 03Sep2019 Se comenta llamada para el caso de administracion grupal
    --Actualizacion de Datos Grupales
    exec @w_return = sp_actualiza_grupal
    @i_banco      = @w_banco_padre,
    @i_desde_cca  = 'N'
     
    if @w_return != 0
    begin
        select @o_clte_err = @w_cliente,
               @o_mensaje  = 'Error: Actualizando datos de operaciones grupales'
        return 70206
    end 

   */        
    select @o_clte_err  = 0,
           @o_mensaje   = ''
end


return 0


GO


