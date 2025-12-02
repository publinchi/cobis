/************************************************************************/
/*   Archivo:              copsolwf.sp                                  */
/*   Stored procedure:     sp_crear_oper_sol_wf                         */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raul Altamirano Mendez                       */
/*   Fecha de escritura:   Dic-29-2016                                  */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                             PROPOSITO                                */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA          AUTOR            CAMBIO                          */
/*   DIC-29-2016    Raul Altamirano  Emision Inicial - Version MX       */
/*   ABR-07-2017    Milton Custode   modificacion del credito grupal    */
/*   ABR-10-2017    Luis Ponce       Cambios Santander CREDITO GRUPAL   */
/*   JUL-18-2017    Ma. Jose Taco    Nueva variable para leer desde     */
/*                                   batch si es automatica o no        */
/*   SEP-13-2017    Jorge Salazar    Parametros de entrada              */
/*                                   @i_tdividendo, @i_periodo_cap      */
/*                                   @i_periodo_int                     */
/*   SEP-22-2017    Luis Ponce       Validar los montos del móvil       */
/*   JUN-05-2019    Luis Ponce       Operacion Padre Grupal TeCreemos   */
/*   JUL-02-2019    Adriana Giler    Operacion RefREn GrupalTeCreemos   */
/*   JUL-10-2019    Lorena Regalado  Operaciones de Interciclo          */
/*   OCT-18-2019    A. Miramon       Ajuste en calculo de CAT           */
/*   JUL-21-2021    Ricardo Rincon   se agrega @i_plazo a ejecucion     */
/*                                   de sp_tramite_cca                  */
/*   AGO-03-2021    Patricio Mora    ORI-S473510-GFI                    */  
/*   AGO-27-2021    Dilan Morales    Se agrega validación sector        */
/*   FEB-24-2021    Kevin Rodríguez  Se comenta calculo CAT (Cálculo ya */
/*                                   se lo hace en sp_operacion_def)    */  
/*   MAY-05-2022    Paulina Quezada  Cambio por rubros calculados       */
/*   NOV-24-2022    Dilan Morales    S736966: Se comenta logica para    */
/*                                   renovaciones                       */
/*   MAY-02-2023    Dilan Morales    S784843: Se añade condición        */
/*                                   @i_desde_web='N' para app móvil ENL*/
/*   MAY-18-2023    Dilan Morales    S784843: Se comenta sector por     */
/*                                  parametro y se obtiene el por defecto*/
/*   AGO-16-2023    Dilan Morales    R213355 - En @i_tdividendo se      */
/*                                   envia @i_tplazo                    */
/*   AGO-17-2023    Dilan Morales    R213355 - Se asigna valor a        */
/*                                   @w_fecha_fija                      */
/*  OCT-03-2023     Esteban Báez     Mejora control oficiales           */
/*                                   S911708-R216187                    */
/*   NOV-28-2023    Dilan Morales    R220193: Se asigna oficina con la  */
/*                                   de la op renovar                   */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crear_oper_sol_wf')
    drop proc sp_crear_oper_sol_wf
go

create proc sp_crear_oper_sol_wf(
   @s_srv                      varchar(30)    = null,
   @s_lsrv                     varchar(30)    = null,
   @s_ssn                      int            = null,
   @s_rol                      int            = null,
   @s_org                      char(1)        = null,
   @s_user                     login          = null,
   @s_term                     varchar(30)    = null,
   @s_date                     datetime       = null,
   @s_sesn                     int            = null,
   @s_ofi                      smallint       = null,
   ---------------------------------------
   @t_trn                      int            = null,
   @t_debug                    char(1)        = null,
   @t_file                     varchar(30)    = null,
   ---------------------------------------
   @i_tipo                     varchar(1)     = 'N',
   @i_anterior                 cuenta         = null,
   @i_migrada                  cuenta         = null,
   @i_tramite                  int            = null,
   @i_cliente                  int            = 0,
   @i_nombre                   descripcion    = null,
   @i_codeudor                 int            = 0,
   @i_sector                   catalogo       = null,
   @i_toperacion               catalogo       = null,
   @i_oficina                  smallint       = null,
   @i_moneda                   tinyint        = null,
   @i_comentario               varchar(255)   = null,
   @i_oficial                  smallint       = null,
   @i_fecha_ini                datetime       = null,     --PQU esta debería ser la fecha de desembolso
   @i_monto                    money          = null,
   @i_monto_aprobado           money          = null,
   @i_destino                  catalogo       = null,
   @i_lin_credito              cuenta         = null,
   @i_ciudad                   int            = null,
   @i_forma_pago               catalogo       = null,
   @i_cuenta                   cuenta         = null,
   @i_formato_fecha            int            = 101,
   @i_no_banco                 varchar(1)     = 'S',
   @i_clase_cartera            catalogo       = null,
   @i_origen_fondos            catalogo       = null,
   @i_fondos_propios           varchar(1)     = 'S',
   @i_ref_exterior             cuenta         = null,
   @i_sujeta_nego              varchar(1)     = 'N' ,
   @i_convierte_tasa           varchar(1)     = null,
   @i_tasa_equivalente         varchar(1)     = null,
   @i_fec_embarque             datetime       = null,
   @i_reestructuracion         varchar(1)     = null,
   @i_numero_reest             int            = null,
   @i_num_renovacion           int            = 0,
   @i_tipo_cambio              varchar(1)     = null,
   @i_grupal                   char(1)        = null,
   @i_es_grupal                char(1)        = null,     --LRE TEC 19/Jun/2019
   @i_en_linea                 varchar(1)     = 'S',
   @i_externo                  varchar(1)     = 'S',
   @i_desde_web                varchar(1)     = 'S',
   @i_banca                    catalogo       = null,
   @i_salida                   varchar(1)     = 'N',
   @i_promocion                char(1)        = 'N',      --LPO Santander
   @i_acepta_ren               char(1)        = null,     --LPO Santander
   @i_no_acepta                char(1000)     = null,     --LPO Santander
   @i_emprendimiento           char(1)        = null,     --LPO Santander
   @i_participa_ciclo          char(1)        = null,     --LPO Santander
   --@i_tg_monto_aprobado money     = null,       --LPO Santander
   @i_garantia                 float          = null,     --LPO Santander
   @i_ahorro                   money          = null,     --LPO Santander
   @i_monto_max                money          = null,     --LPO Santander
   @i_bc_ln                    char(10)       = null,     --LPO Santander
   @i_plazo                    int            = null,     --Santander -- tr_plazo
   @i_tplazo                   catalogo       = null,     --Santander -- tr_tipo_plazo
   @i_tdividendo               catalogo       = null,     --PQU enviar lo mismo que para el tplazo
   @i_periodo_cap              int            = null,
   @i_periodo_int              int            = null,
   @i_alianza                  int            = null,     --Santander -- tr_alianza
   @i_ciudad_destino           int            = null,     --Santander
   @i_experiencia_cli          char(1)        = null,     --Santander
   @i_monto_max_tr             money          = null,     --Santander
   @i_automatica               char(1)        = 'N',      --Santander
   @i_naturaleza               varchar(10)    = null,
   --PQU añadir el número de grupo, fecha de vencimiento primera cuota, tasa interés (valor), monto ahorro esperado
   @i_grupo                    int            = null,     --LPO TEC
   @i_fecha_ven_pc             datetime       = null,     --LPO TEC
   @i_tasa_grupal              float          = null,     --LPO TEC
   @i_monto_abono              money          = 0,        --AGI TEC
   @i_subtipo                  char(1)        = null,     --AGI TEC
   @i_clasificacion            varchar(10)    = null,     --AGI TEC
   @i_es_interciclo            char(1)        = null,     --LRE TEC Bandera para identificar operaciones de Interciclo
   @i_ref_grupal               cuenta         = null,     --LRE TEC 
   --PQU añadir secuencial temporal de creación de tablas temporales para luego actualizar esas tablas con el número de operación generado.--LPO: No aplica, el secuencial es en el sp que invoca a este.
   ---------------------------------------
   @o_banco                    cuenta         = null out,
   @o_operacion                int            = null out,
   @o_tramite                  int            = null out,
   @o_oficina                  int            = null out,
   @o_msg                      varchar(100)   = null out,
   @o_ciclo                    int            = null out,
   @o_fecha_creacion           varchar(10)    = null out
        
   --PQU aumentar un parámetro de salida de orden de pago. --LPO: No aplica la orden de pago va en el desembolso.
)
as
declare
   @w_sp_name                  varchar(64),
   @w_return                   int,
   @w_error                    int,
   @w_fecha_proceso            datetime,
   @w_operacion                int,
   @w_banco                    cuenta,
   @w_ced_ruc                  varchar(32),
   @w_ced_ruc_codeudor         varchar(32),
   @w_nombre                   varchar(60),
   @w_prod_cobis               smallint,
   @w_tramite                  int,
   @w_tplazo                   catalogo,
   @w_plazo                    smallint,
   @w_commit                   char(1),
   @w_ced_ruc_codeudor_gr      varchar(32),
   @w_miembros                 int,
   @w_cta_grupal               cuenta,
   @w_max_tramite              int,         -- LGU max tramite grupal
   @w_grupo_id                 int,         -- LGU id del grupo del interciclo
   @w_operacion_1              int,
   @w_periodo_reajuste         smallint,
   @w_reajuste_especial        char(1),
   @w_precancelacion           char(1),
   @w_tipo                     char(1),
   @w_cuota_completa           char(1),
   @w_tipo_reduccion           char(1),
   @w_aceptar_anticipos        char(1),
   @w_tdividendo               catalogo,
   @w_periodo_cap              smallint,
   @w_periodo_int              smallint,
   @w_gracia_cap               smallint,
   @w_gracia_int               smallint,
   @w_dist_gracia              char(1),
   @w_dias_anio                smallint,
   @w_tipo_amortizacion        varchar(30),
   @w_fecha_fija               char(1),
   @w_cuota_fija               char(1),
   @w_evitar_feriados          char(1),
   @w_renovacion               char(1),
   @w_mes_gracia               tinyint,
   @w_tipo_aplicacion          char(1),
   @w_tipo_cobro               char(1),
   @w_reajustable              char(1),
   @w_base_calculo             char(1),
   @w_ult_dia_habil            char(1),
   @w_recalcular               char(1),
   @w_prd_cobis                tinyint,
   @w_tipo_redondeo            tinyint,
   @w_causacion                char(1),
   @w_convierte_tasa           char(1),
   @w_tipo_linea               catalogo,
   @w_subtipo_linea            catalogo,
   @w_bvirtual                 char(1),
   @w_extracto                 char(1),
   @w_subtipo                  char(1),
   @w_naturaleza               char(1),
   @w_pago_caja                char(1),
   @w_nace_vencida             char(1),
   @w_calcula_devolucion       char(1),
   @w_dias_gracia              smallint,
   @w_entidad_convenio         catalogo,
   @w_mora_retroactiva         char(1),
   @w_prepago_desde_lavigente  char(1),
   @w_control_dia_pago         char(1),
   @w_sector                   catalogo,
   @w_clase_cartera            catalogo,
   @w_dia_pago                 tinyint,
   @w_ofi_def_app_movil        smallint,
   @w_monto_max                money,
   @w_monto_min                money,
   @w_porcentaje               float,
   @w_id_inst_proc             int,
   @w_id_inst_act              int,
   @w_id_empresa               int,
   @w_rule                     int,
   @w_rule_version             int,
   @w_retorno_val              varchar(255),
   @w_retorno_id               int,
   @w_variables                varchar(255),
   @w_result_values            varchar(255),
   @w_ciclo                    int,
   @w_fecha_creacion           datetime,
   @w_admin_indiv              char(1),        --LPO TEC
   @w_moneda_ori               tinyint,        --AGI TEC
   @w_monto_ori                money,          --AGI TEC
   @w_bancore                  cuenta,         --AGI TEC
   @w_saldo                    money,          --AGI TEC
   @w_banco_generado           cuenta,         --AGI TEC
   @w_operacionre              int,            --AGI TEC
   @w_estado_operacion         tinyint,        --AGI TEC 
   @w_fecha_ult_proceso        datetime,       --AGI TEC
   @w_estado_fin               tinyint,        --AGI TEC
   @w_num_dec                  tinyint,        --AGI TEC
   @w_moneda_n                 tinyint,        --AGI TEC
   @w_num_dec_mn               tinyint,        --AGI TEC
   @w_param_nd                 varchar(15),    --PQU
   @w_destino_tmp              varchar(10),
   @w_destino                  varchar(10),
   @w_product_category         int,
   @w_parent_node              varchar(10),
   --R216187 Validar que el oficial sea el mismo que del grupo
   @w_controlar_oficial        char(10),
   @w_oficial_grupo            int
     
-- PMO Destino de operación por defecto.
   select @w_destino_tmp = pa_char from cobis..cl_parametro
   where  pa_nemonico    = 'DEST'                    
   select @w_destino = isnull(@i_destino,@w_destino_tmp)

-- AMG 2019/10/18 - Calculo de CAT
declare 
   @w_cat float
   
-- MANEJO DE DECIMALES
exec @w_return = sp_decimales
     @i_moneda       = @i_moneda,
     @o_decimales    = @w_num_dec    out,
     @o_mon_nacional = @w_moneda_n   out,
     @o_dec_nacional = @w_num_dec_mn out

select @w_param_nd = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'DEBCTA'

--EBAEZ R216187-Control Oficiales
select @w_controlar_oficial = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'CTROFG'
   
----EBAEZ R216187-Control Oficiales
/*VALIDAR QUE EL GRUPO Y LA SOLICITUD TENGAN EL MISMO OFICIAL*/
if @w_controlar_oficial = 'S'
begin
   select @w_oficial_grupo = gr_oficial
     from cobis..cl_grupo
    where gr_grupo = @i_cliente
   if @w_oficial_grupo <> @i_oficial
   begin
      select @w_error = 725306
      goto ERROR_PROCESO
   end	  
end

/* DETERMINAR LOS VALORES POR DEFECTO PARA EL TIPO DE OPERACION */

select
@w_periodo_reajuste          = dt_periodo_reaj,
@w_reajuste_especial         = dt_reajuste_especial,
@w_precancelacion            = dt_precancelacion,
@w_tipo                      = dt_tipo,
@w_cuota_completa            = dt_cuota_completa,
@w_tipo_reduccion            = dt_tipo_reduccion,
@w_aceptar_anticipos         = dt_aceptar_anticipos,
--xma @w_tipo_reduccion     = dt_tipo_reduccion,
@w_tplazo                    = dt_tplazo,
@w_plazo                     = dt_plazo,
@w_tdividendo                = dt_tdividendo,
@w_periodo_cap               = dt_periodo_cap,
@w_periodo_int               = dt_periodo_int,
@w_gracia_cap                = dt_gracia_cap,
@w_gracia_int                = dt_gracia_int,
@w_dist_gracia               = dt_dist_gracia,
@w_dias_anio                 = dt_dias_anio,
@w_tipo_amortizacion         = dt_tipo_amortizacion,
@w_fecha_fija                = dt_fecha_fija,
@w_dia_pago                  = isnull(@i_num_renovacion, dt_dia_pago), --PQU añadi para que tome la variable de entrada
@w_cuota_fija                = dt_cuota_fija,
@w_evitar_feriados           = dt_evitar_feriados,
@w_renovacion                = dt_renovacion,
@w_mes_gracia                = dt_mes_gracia,
@w_tipo_aplicacion           = dt_tipo_aplicacion,
@w_tipo_cobro                = dt_tipo_cobro,
@w_reajustable               = dt_reajustable,
@w_base_calculo              = dt_base_calculo,
@w_ult_dia_habil             = dt_dia_habil,
@w_recalcular                = dt_recalcular_plazo,
@w_prd_cobis                 = dt_prd_cobis,
@w_tipo_redondeo             = dt_tipo_redondeo,
@w_causacion                 = dt_causacion,
@w_convierte_tasa            = isnull(dt_convertir_tasa, 'S'),
@w_tipo_linea                = dt_tipo_linea,
@w_subtipo_linea             = dt_subtipo_linea,
@w_bvirtual                  = dt_bvirtual,
@w_extracto                  = dt_extracto,
@w_naturaleza                = dt_naturaleza,
@w_pago_caja                 = dt_pago_caja,
@w_nace_vencida              = dt_nace_vencida,
@w_calcula_devolucion        = dt_calcula_devolucion,
@w_dias_gracia               = dt_dias_gracia,
@w_entidad_convenio          = dt_entidad_convenio,
@w_mora_retroactiva          = dt_mora_retroactiva,
@w_prepago_desde_lavigente   = isnull(dt_prepago_desde_lavigente,'N'),
@w_control_dia_pago          = dt_control_dia_pago,
@w_sector                    = dt_clase_sector,
@w_clase_cartera             = dt_clase_cartera

from ca_default_toperacion
where dt_toperacion = @i_toperacion
and   dt_moneda     = @i_moneda

if @@rowcount = 0 return 710072

--DMO en ENLACE no existe sector por defecto
/*if @i_sector is null
begin
	select @i_sector = pa_char from cobis..cl_parametro where pa_parametro = 'CODIGO PARA CARTERA MICROCREDITO'
end
*/

select
--@w_tplazo           = isnull(@i_tplazo, @w_tplazo),
--@w_plazo            = isnull(@i_plazo,  @w_plazo),
--@w_tasa_equivalente = isnull(@i_tasa_equivalente, 'N'),
--@w_tdividendo       = isnull(@i_tdividendo, @w_tdividendo),
@i_sector           = isnull(@i_sector,@w_sector),
@i_clase_cartera    = isnull(@i_clase_cartera,@w_clase_cartera)

--PRINT 'CARGAR VALORES INICIALES'
select @w_sp_name  = 'sp_crear_oper_sol_wf',
       @w_commit   = 'N'

--PRINT 'CONSULTAR FECHA DE PROCESO'
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

-- PRINT 'NUMERO DE OFICINA POR DEFECTO DEL APP MOVIL'
select @w_ofi_def_app_movil = pa_int from cobis..cl_parametro
where  pa_nemonico = 'MOBOFF'
and    pa_producto = 'ADM'

/* Valida el monto maximo y minimo para las operaciones */

select @w_monto_min = dt_monto_min,
       @w_monto_max = dt_monto_max
from   cob_cartera..ca_default_toperacion
where  dt_toperacion = @i_toperacion
and    dt_moneda     = @i_moneda

if((@i_oficina = @w_ofi_def_app_movil) OR (@s_ofi = @w_ofi_def_app_movil))
begin
    if isnull(@i_monto_aprobado, 0) > 0
    begin
       if @i_ref_grupal is not null
       begin
	       if isnull(@w_monto_min,0) > 0 or isnull(@w_monto_max,0) > 0
	       begin
	          if @i_monto_aprobado < @w_monto_min or @i_monto_aprobado > @w_monto_max
	          begin
	             select @w_error = 724609
	
	                exec cobis..sp_cerror
	                        @t_debug = @t_debug,
	                        @t_file  = @t_file,
	                        @t_from  = @w_sp_name,
	                        @i_num   = @w_error
	                GOTO ERROR_PROCESO
	          end
	       end
       end
    end
end

if(@i_oficina = @w_ofi_def_app_movil)
begin
    select @i_oficina = fu_oficina
    from   cobis..cl_funcionario, cobis..cc_oficial
    where  oc_oficial     = @i_oficial
    and    oc_funcionario = fu_funcionario
end

-- DMO S784843 
-- LÓGICA PARA APP MÓVIL ENL
if @i_desde_web = 'N'
begin
	
	select @i_oficina =  fu_oficina from cobis..cc_oficial
	inner join cobis..cl_funcionario on fu_funcionario = oc_funcionario
	where oc_oficial  = @i_oficial
	
	--DMO R220193
	if @i_tipo = 'R'
	begin
        select @i_oficina =  isnull(op_oficina, @i_oficina) from cob_cartera..ca_operacion where op_banco = @i_anterior
	end 
	
	select @i_ciudad 			= of_ciudad, 
		   @i_ciudad_destino 	= of_ciudad 
	from  cobis..cl_oficina where of_oficina  =  @i_oficina 
	
	select @i_no_acepta = pa_char from cobis..cl_parametro --origen de fondos
	where  pa_nemonico = 'ORIFON'
	and    pa_producto = 'CRE'
	
	--bp_parentnode tipo de producto
	select @w_parent_node  = bp_parentnode
    from cob_fpm..fp_bankingproducts
	where bp_product_id = @i_toperacion
	
	select @w_product_category = ntc_productcategory
	 from cob_fpm..fp_bankingproducts
	where bp_product_id = @w_parent_node
	
	select @i_sector = trim(ntc_mnemonic) from cob_fpm..fp_nodetypecategory 
	where ntc_productcategory_id = @w_product_category  
	and ntp_nodetype_idfk = 4
	
	if @i_sector is null
	begin
		--DMO sector ca_default_toperacion
		select @i_sector = @w_sector
	end
	
	if @i_sector is null
    begin
    /*Registro no existe */
      select @w_error = 2110426
      goto ERROR_PROCESO
    end
 
end


if @@trancount = 0
begin
   begin tran
   select @w_commit = 'S'
end

--PQU encontrar el i_cliente con el i_grupo, de manera que el i_cliente sea el presidente del grupo, rol: P
if @i_grupal = 'S' and @i_grupo is null and @i_cliente  is not null
    select @i_grupo = @i_cliente
   
if @i_grupal = 'S'
begin
   select @i_cliente = cg_ente
   from cobis..cl_cliente_grupo
   where cg_grupo  = @i_grupo
     and cg_rol    = 'P'
     and cg_estado = 'V'
    
select @w_grupo_id = cg_grupo
from   cobis..cl_cliente_grupo
where  cg_ente = @i_cliente
   and cg_fecha_desasociacion is null
end 

/*
-- LGU 17-abr-2017 control para crear un solo emergente por cliente
    if exists(select 1 from cobis..cl_tabla t, cobis..cl_catalogo c where t.tabla = 'ca_interciclo' and t.codigo = c.tabla and c.codigo = @i_toperacion)
    begin

        select
            @w_max_tramite = max(tg_tramite)
        from cob_credito..cr_tramite_grupal
        where tg_grupo = @w_grupo_id
        print '---> comentado el control para crear un emergente'

--      if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @w_max_tramite and tg_grupal = 'N' and tg_cliente = @i_cliente)
      if isnull(@w_max_tramite ,0) = 0
        begin
          --/ ERROR EN INSERCION DE REGisTRO - NO EXisTE OPERACION GRUPAL/
          select @w_error = 2103001
          goto ERROR_PROCESO
        end

    end    
-- LGU 17-abr-2017 control para crear un solo emergente por cliente
*/
--LPO TEC: FIN de Se comenta cÂ¢digo
--fin PQU comentar el cÂ¢digo

---------------------------------------------
--PRINT 'CONSULTAR INFORMACION DEL DEUDOR PRINCIPAL ' + CONVERT(VARCHAR, @i_cliente)
select
@w_ced_ruc = en_ced_ruc,
@w_nombre  = rtrim(isnull(p_p_apellido,''))+' '+rtrim(isnull(p_s_apellido,''))+' '+rtrim(isnull(en_nombre,''))
from  cobis..cl_ente
where en_ente = @i_cliente
--PRINT CONVERT(VARCHAR, @@rowcount)
set transaction isolation level read uncommitted

if @w_ced_ruc is null or @w_nombre is null
begin
--   PRINT CONVERT(VARCHAR, @@rowcount) + ' ' + @w_ced_ruc + ' ' + @w_nombre
   select @w_error = 710200  --No existe cliente solicitado
   goto ERROR_PROCESO
end

--PRINT 'REGISTRAR DEUDOR PRINCIPAL'
exec @w_return = sp_codeudor_tmp
@s_sesn        = @s_sesn,
@s_user        = @s_user,
@i_borrar      = 'S',
@i_secuencial  = 1,
@i_titular     = @i_cliente,
@i_operacion   = 'A',
@i_codeudor    = @i_cliente,
@i_ced_ruc     = @w_ced_ruc,
@i_rol         = 'D',
@i_externo     = 'N'

if @w_return != 0
begin
   select @w_error = @w_return
   goto ERROR_PROCESO
end

--PRINT 'VERIFICAR ENVIO DE CODEUDOR'
if isnull(@i_codeudor, 0) != 0
begin
--   PRINT 'CONSULTAR INFORMACION DEL CODEUDOR'
   select @w_ced_ruc_codeudor = en_ced_ruc
   from cobis..cl_ente
   where  en_ente = @i_codeudor
   set transaction isolation level read uncommitted

   if @w_ced_ruc_codeudor is null
   begin
      select @w_error = 710200  --No existe cliente solicitado
      goto ERROR_PROCESO
   end

--   PRINT 'REGISTRAR CODEUDOR'
   exec @w_return = sp_codeudor_tmp
   @s_sesn        = @s_sesn,
   @s_user        = @s_user,
   @i_borrar      = 'N',
   @i_secuencial  = 2,
   @i_titular     = @i_cliente,
   @i_operacion   = 'A',
   @i_codeudor    = @i_codeudor,
   @i_ced_ruc     = @w_ced_ruc_codeudor,
   @i_rol         = 'C',
   @i_externo     = 'N'

   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
end

if @i_grupal= 'S'  --PQU2 integración el monto se leerá del monto mínimo parametrizado para el producto
begin
    if(@i_automatica = 'N') --No ingresa por batch
    begin
       select @i_monto =  dt_monto_min
       from   cob_cartera..ca_default_toperacion
       where  dt_toperacion = @i_toperacion
       and    dt_moneda     = @i_moneda

       select @i_monto_aprobado = @i_monto
    end
end
select @i_monto_aprobado = @i_monto 
--fin PQU

select @i_forma_pago = @w_param_nd --PQU

--PRINT 'GENERAR TRAMITE DEBIDO A LA CREACION DIRECTA EN CCA (VERIFICAR AL FINAL)'
--PQU 05/05/2022 cambio orden por solicitud de cartera por rubros calculados

exec @w_return = cob_credito..sp_tramite_cca
@s_ssn               = @s_ssn,
@s_user              = @s_user,
@s_sesn              = @s_sesn,
@s_term              = @s_term,
@s_date              = @s_date,
@s_srv               = @s_srv,
@s_lsrv              = @s_lsrv,
@s_ofi               = @s_ofi,
@i_oficina_tr        = @i_oficina,
@i_fecha_crea        = @i_fecha_ini,
@i_oficial           = @i_oficial,
@i_sector            = @i_sector,
@i_banco             = @w_banco,
@i_linea_credito     = @i_lin_credito,
@i_toperacion        = @i_toperacion,
@i_producto          = 'CCA',
@i_tipo              = @i_tipo,
@i_monto             = @i_monto,
@i_moneda            = @i_moneda,
@i_periodo           = @i_tplazo,               --@w_tplazo,
@i_num_periodos      = @i_plazo,                --@w_plazo, 
@i_destino           = @w_destino,              
@i_ciudad_destino    = @i_ciudad_destino,       
--@i_renovacion        = @i_num_renovacion,     
@i_clase             = @i_clase_cartera,        
@i_cliente           = @i_cliente,              
@i_grupal            = @i_grupal,               
@i_grupo             = @i_grupo,                --PQU2 tiene que enviar a grabar el grupo
@i_promocion         = @i_promocion,            
@i_acepta_ren        = @i_acepta_ren,           
--@i_no_acepta         = @i_no_acepta,          
@i_emprendimiento    = @i_emprendimiento,       
@i_participa_ciclo   = @i_participa_ciclo,      
@i_monto_aprobado    = @i_monto_aprobado,       --@i_tg_monto_aprobado,
@i_garantia          = @i_garantia,             
@i_ahorro            = @i_ahorro,               
@i_monto_max         = @i_monto_max,            
@i_bc_ln             = @i_bc_ln,                
@i_plazo             = @i_plazo,                
@i_tplazo            = @i_tplazo,               
@i_alianza           = @i_alianza,              
@i_experiencia_cli   = @i_experiencia_cli,      --Santander
@i_monto_max_tr      = @i_monto_max_tr,         --Santander
@i_naturaleza        = @i_naturaleza,           
@i_origen_fondos     = @i_no_acepta,            --PQU Finca
@i_desde_crea_grupal = 'S',                     --PQU 
@o_tramite           = @w_tramite          out
if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR_PROCESO
end

--DMO Se asigna valor de fecha fija basado en el día de pago.
if(@w_dia_pago > 0)
begin
	select @w_fecha_fija   = 'S'
end
else
begin
	select @w_fecha_fija   = 'N',
	       @w_dia_pago     = 0
end

------------------------
--PRINT 'CREACION DE LA OPERACION'
exec @w_return = cob_cartera..sp_crear_operacion
--@s_ssn            = @s_ssn,
@s_user             = @s_user,
@s_sesn             = @s_sesn,
@s_term             = @s_term,
@s_date             = @s_date,
@s_ofi              = @s_ofi,
@i_anterior         = @i_anterior,
@i_tramite          = @w_tramite,          -- KDR 05/05/2022
@i_comentario       = @i_comentario,
@i_oficial          = @i_oficial,
@i_destino          = @w_destino,
@i_monto_aprobado   = @i_monto_aprobado,
@i_fondos_propios   = @i_fondos_propios,
@i_ciudad           = @i_ciudad,
@i_cliente          = @i_cliente,
@i_nombre           = @w_nombre,
@i_sector           = @i_sector,
@i_oficina          = @i_oficina,
@i_toperacion       = @i_toperacion,
@i_monto            = @i_monto,
@i_moneda           = @i_moneda,
@i_fecha_ini        = @i_fecha_ini,
@i_lin_credito      = @i_lin_credito,
@i_migrada          = @i_migrada,
@i_formato_fecha    = @i_formato_fecha,
@i_forma_pago       = @i_forma_pago,
@i_cuenta           = @i_cuenta,
@i_clase_cartera    = @i_clase_cartera,
--PQU Finca @i_origen_fondos  = @i_origen_fondos,
@i_sujeta_nego      = @i_sujeta_nego,   -- sujeta a negociacion
@i_ref_exterior     = @i_ref_exterior,  -- numero de referencia exterior
@i_convierte_tasa   = @i_convierte_tasa,
@i_tasa_equivalente = @i_tasa_equivalente,
@i_fec_embarque     = @i_fec_embarque,
--@i_num_comex      = @i_num_operacion_cex,
--@i_num_deuda_ext  = @i_comex,
@i_reestructuracion = @i_reestructuracion,
@i_tipo_cambio      = @i_tipo_cambio,
@i_grupal           = @i_grupal, 
@i_es_grupal        = @i_es_grupal,   --LRE TEC 19/JUN/2019
@i_promocion        = @i_promocion,
@i_acepta_ren       = @i_acepta_ren,
--PQU para Finca@i_no_acepta      = @i_no_acepta,
@i_origen_fondos    = @i_no_acepta,
@i_emprendimiento   = @i_emprendimiento,
@i_banca            = @i_banca,
@i_plazo            = @i_plazo,
@i_tplazo           = @i_tplazo,
@i_tdividendo       = @i_tplazo, --DMO Desde front solo se envía tipo de plazo
@i_periodo_cap      = @i_periodo_cap,
@i_periodo_int      = @i_periodo_int,
--PQU pasar fecha vencimiento primer dividendo, tasa interés, monto ahorro esperado
--LPO TEC Entonces se pasan los parámetros grupo, fecha ven primera cuota y tasa, el ahorro esperado no aplica.
@i_grupo            = @i_grupo,          --LPO TEC
@i_fecha_ven_pc     = @i_fecha_ven_pc,   --LPO TEC
@i_tasa_grupal      = @i_tasa_grupal,    --LPO TEC
@i_es_interciclo    = @i_es_interciclo,  --LRE TEC 10/Jul/2019
@i_ref_grupal       = @i_ref_grupal,     --LRE TEC 10/Jul/2019
@i_dia_pago         = @w_dia_pago,       --PQU Integración Finca
@i_fecha_fija       = @w_fecha_fija,
@i_no_banco         = @i_no_banco,       --PQU Integración Finca
@o_banco            = @w_banco output

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR_PROCESO
end

--PRINT 'OBTENER NUMERO DE OPERACION DESDE TEMPORAL'
select
@w_operacion    = opt_operacion,
@w_prod_cobis   = opt_prd_cobis,
@w_admin_indiv  = opt_admin_individual --LPO TEC
from   ca_operacion_tmp
where  opt_banco = @w_banco

if @@rowcount = 0
begin
   select @w_error = 701050  --No existe Operacion Temporal
   goto ERROR_PROCESO
end


--PQU 
select @w_banco = opt_banco
from   cob_cartera..ca_operacion_tmp
WHERE  opt_operacion = @w_operacion
--PRINT 'Banco paso de sp_tramite_cca ' + @w_banco
--PQU fin

update ca_operacion_tmp
set    opt_tramite = @w_tramite
where  opt_banco   = @w_banco

if @@error <> 0
begin
   select @w_error = 2103001
   goto ERROR_PROCESO
end

--PQU 05/05/2022
 
update cob_credito..cr_tramite_grupal
set tg_operacion         = @w_operacion,
    tg_prestamo          = @w_banco,
	tg_referencia_grupal = @w_banco
where tg_tramite         = @w_tramite	
--fin PQU 05/05/2022

--ACTUALIZACION DE LAS OFICINAS DEL WF EN CASO DE SEAN DEL APP MOVIL
/*update cob_workflow..wf_inst_proceso set 
io_oficina_inicio  = @i_oficina,
io_oficina_entrega = @i_oficina 
where io_campo_3    = @w_tramite

if @@error <> 0
begin
   select @w_error = 2103002
   goto ERROR_PROCESO
end
*/

--PRINT 'TRASLADO DE INFORMACION DESDE LAS TMP A DEFINITIVAS'
--PRINT 'Va a operación definitiva'
exec @w_return = sp_operacion_def
@s_date  = @s_date,
@s_sesn  = @s_sesn,
@s_user  = @s_user,
@s_ofi   = @s_ofi,
@i_banco = @w_banco,
@i_claseoper = @w_banco

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR_PROCESO
end

if isnull(@w_tramite, 0) > 0
begin
   update cob_credito..cr_tramite
   set    tr_numero_op = @w_operacion--,
          --tr_numero_op_banco = @w_banco
   where  tr_tramite   = @w_tramite

   if @@error <> 0
   begin
      select @w_error = 2103001
      goto ERROR_PROCESO
   end
--------------------------------------------

if not exists (select 1 from cob_credito..cr_deudores
               where de_tramite = @w_tramite)
begin
   --print 'ingreso informacion de los deudores'

    --PRINT 'REGISTRAR DEUDOR PRINCIPAL'
   exec @w_return = cob_credito..sp_deudores
         @s_date            = @s_date,
         @s_ssn             = @s_ssn ,
         @s_user            = @s_user,
         @s_term            = @s_term,
         @s_ofi             = @s_ofi ,
         @s_sesn            = @s_sesn,
         @t_trn             = 21013,
         @i_operacion       = 'I',
         @i_tramite         = @w_tramite,
         @i_cliente         = @i_cliente,
         @i_rol             = 'D',
         @i_ced_ruc         = @w_ced_ruc,
         @i_cobro_cen       = 'N'

   if @w_return != 0
   begin
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
    
   --Bandera que indica el tramite es grupal
   --PRINT 'sp_tramite_cca ACTUALIZO LA BANDERA DE GRUPAL ' + convert(varchar,@w_tramite) + '@i_banco ' + @w_banco
   if @i_grupal = 'S' and @w_admin_indiv = 'S' --LPO TEC
   begin
      update cob_credito..cr_deudores
      set de_rol = 'G'
      where de_tramite = @w_tramite
      
      if @@error <> 0
      begin
        select @w_error = 2103001
        goto ERROR_PROCESO
      end
   end   
end

------------------------------------------
end

--PRINT 'ELIMINACION DE LA INFORMACION EN TEMPORALES'
exec @w_return = sp_borrar_tmp
--@s_date   = @s_date,
@s_sesn   = @s_sesn,
@s_user   = @s_user,
--@s_ofi    = @s_ofi,
@s_term   = @s_term,
@i_banco  = @w_banco

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR_PROCESO
end

   -- AMG 2019/10/18 - Calculo de CAT
  /* PQU ESTO TEMPORALMENTE COMENTAR
   exec @w_return = sp_calculo_cat @i_banco = @w_banco, @o_cat = @w_cat out
   --PRINT 'cat: ' + convert(VARCHAR, @w_cat)

   if @w_return != 0
   begin 
      select @w_error = @w_return
      goto ERROR_PROCESO
   end
   */ --FIN PQU
-- LGU-FIN 2017-11-11


--DMO-S736966
--AGI. VALIDAR SI ES UNA RENOVACION
/*if @i_tipo = 'R'  and @i_grupal = 'S'
Begin

    --Obetener la operacion Padre a renovar
    select @w_bancore      = op_banco,
           @w_operacionre  = op_operacion,
           @w_moneda_ori   = op_moneda,
           @w_monto_ori    = op_monto
    from   ca_operacion 
    where  op_grupo = @i_grupo
    and    isnull(op_ref_grupal,'') = ''
    and    op_estado not in (3,0)  --No cancelada, ni no vigente
    and    op_estado_hijas = 'D'  --desembolsada
    and    op_operacion =(select max(op_operacion)
                          from   ca_operacion
                          where  op_grupo = @i_grupo
                          and    op_estado not in (3,0)
                          and    isnull(op_ref_grupal,'') = ''
                          and    op_estado_hijas = 'D' )
    if @@rowcount = 0
    begin
        select @w_error = 710113
        goto ERROR_PROCESO
    end
         
    select @w_saldo = 0         
    
    select @w_saldo = 0         
    
    --Obtener el saldo a la fecha
    exec @w_return =  sp_calcula_saldo
         @i_operacion  = @w_operacionre,
         @i_tipo_pago  = 'A',   --Acumulado
         @o_saldo      = @w_saldo out
        
    if @w_return <> 0
    begin
        select @w_error = @w_return
        goto ERROR_PROCESO
    end

    exec @w_return = cob_credito..sp_op_renovar
         @t_trn                = 21130,
         @s_date               = @s_date,
         @s_user               = @s_user, 
         @s_term               = @s_term,
         @s_ofi                = @s_ofi,
         @s_lsrv               = @s_lsrv,
         @s_srv                = @s_srv,
         @s_ssn                = @s_ssn,
         @i_operacion          = "I",
         @i_tramite            = @w_tramite, 
         @i_num_operacion      = @w_banco, 
         @i_abono              = @i_monto_abono,
         @i_moneda_abono       = @i_moneda,
         @i_monto_original     = @w_monto_ori,
         @i_saldo_original     = @w_saldo, 
         @i_moneda_original    = @w_moneda_ori,
         @i_toperacion         = @i_toperacion,         
         @i_producto           = "CCA"

    if @w_return <> 0
    begin
        select @w_error = @w_return
        goto ERROR_PROCESO
    end
 
    exec @w_return = cob_cartera..sp_ren_autoriza
         @s_date     = @s_date, 
         @s_term     = @s_term,
         @s_ofi      = @s_ofi,
         @i_tramite  = @w_tramite, 
         @i_usuario  = @s_user,
         @t_trn      = 7979
   
    if @w_return <> 0
    begin
        select @w_error = @w_return
        goto ERROR_PROCESO
    end

    update cob_credito..cr_tramite 
    set tr_estado = 'A',
        tr_subtipo  = @i_subtipo,
        tr_numero_op_banco = @w_banco
    where tr_tramite = @w_tramite
    if @@error <> 0
    begin
        select @w_error = @@error
        goto ERROR_PROCESO       
    end
    
    update cob_credito..cr_op_renovar 
    set or_operacion_original = @w_operacionre
    where or_tramite = @w_tramite
    if @@error <> 0
    begin
        select @w_error = @@error
        goto ERROR_PROCESO       
    end
    
    update ca_operacion
    set op_anterior = @w_bancore
    where op_banco  = @w_banco
    if @@error <> 0
    begin
        select @w_error = @@error
        goto ERROR_PROCESO       
    end
end*/
--FIN AGI

if @i_grupal = 'S'
begin
    --AGI 04JUL19  Actualizar clasificacion del grupo
    update cobis..cl_grupo
    set gr_clasificacion = @i_clasificacion
    where gr_grupo = @w_grupo_id
    --FIN AGI
    
   if @w_banco is null
   begin
      --print '1 - Banco : ' + isnull(@w_banco,'-999999999')
      print 'Error update TRAMITE_GRUPAL REF_GRUPAL'
      select @w_error = 7100021
      goto ERROR_PROCESO
   end

   select @w_cta_grupal = gr_cta_grupal
   from cobis..cl_grupo
   where gr_grupo = @w_grupo_id
    
   update cob_credito..cr_tramite_grupal
   set tg_referencia_grupal = @w_banco
   where tg_tramite = @w_tramite
     and tg_grupal  = 'S'

   update cob_credito..cr_tramite
   set tr_numero_op_banco = @w_banco
   where tr_tramite = @w_tramite

   /*KDR 24/02/2021 Se comenta asignación de cálculo del CAT.
    -- LGU-INI 2017-11-11
    -- CALCULAR EL CAT EN DEFINITIVAS
   update cob_cartera..ca_operacion set 
        op_valor_cat = @w_cat,
        op_cuenta = @w_cta_grupal
   where op_operacion = @w_operacion

   if @@error <> 0 begin
      select @w_error = 2103001
      goto ERROR_PROCESO
   end
   */ -- FIN KDR
   
end

/*KDR 24/02/2021 Se comenta asignación de cálculo del CAT.
else
begin
    -- LGU-INI 2017-11-11
    -- CALCULAR EL CAT EN DEFINITIVAS
    
       update cob_cartera..ca_operacion set 
            op_valor_cat = @w_cat
       where op_operacion = @w_operacion
    
       if @@error <> 0 begin
          select @w_error = 2103001
          goto ERROR_PROCESO
       end
    -- LGU-FIN 2017-11-11
end
*/ -- fin KDR

/* Ciclo del grupo */ 
select @w_ciclo = gr_num_ciclo from cobis..cl_grupo where gr_grupo = @i_cliente
/* Fecha de Creacion (Fecha Proceso) */ 


select @w_fecha_creacion = fp_fecha from cobis..ba_fecha_proceso

--PRINT 'ENVIO DE LOS NUMEROS DE OPERACION Y TRAMITE GENERADOS'
select
@o_banco           = @w_banco,
--PQU comentar
--LPO TEC Dejaremos igual por si se necesitan estos datos de salida.
@o_operacion       = @w_operacion,
@o_tramite         = @w_tramite,
@o_oficina         = @i_oficina,
@o_ciclo           = @w_ciclo + 1, --Se suma 1 al ciclo real
@o_fecha_creacion  = convert(varchar(10),@w_fecha_creacion,103)
--fin PQU comentar

---------------------------------------------

if @w_commit = 'S' begin
   commit tran
   select @w_commit = 'N'
end

return 0

ERROR_PROCESO:
--PRINT 'ERROR NUMERO ' + CONVERT(VARCHAR, @w_error)
if @w_commit = 'S'
   rollback tran
   --EBAEZ R216187-Control Oficiales
   exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = @w_error
    return @w_error
go
