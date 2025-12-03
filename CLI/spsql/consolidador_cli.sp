/************************************************************************/
/*   Archivo:             consolidador_cli.sp                           */
/*   Stored procedure:    sp_consolidador_cli                           */
/*   Base de datos:       cob_externos                                  */
/*   Producto:            Clientes                                      */
/*   Disenado por:        ALD                                           */
/*   Fecha de escritura:  30-Abril-2019                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Esta aplicación es parte de los paquetes bancarios propiedad       */
/*   de COBISCorp.                                                      */
/*   Su uso no autorizado queda expresamente prohibido así como         */
/*   cualquier alteración o agregado  hecho por alguno de sus           */
/*   usuarios sin el debido consentimiento por escrito de COBISCorp.    */
/*   Este programa está protegido por la ley de derechos de autor       */
/*   y por las convenciones  internacionales   de  propiedad inte-      */
/*   lectual.    Su uso no  autorizado dará  derecho a COBISCorp para   */
/*   obtener ordenes  de secuestro o retención y para  perseguir        */
/*   penalmente a los autores de cualquier infracción.                  */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Extraccion de datos de Clientes para repositorio ex_dato_operacion */
/*   Abril 20 2012  Acelis  Repositorio Paquete 3   (Eliminar mensajes  */
/*   Agosto 18 2016 P. Romero   Se agrega paso de tabla cl_ente_aux     */
/*   ABR-2017       T. Baidal     CL_ENTE_AUX POR CL_ENTE_ADICIONAL     */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 30/Abril/2019            ALD              Versión Inicial Te Creemos */
/* 20/JUL/2010              FSAP             Estandarizacion clientes   */
/************************************************************************/

use cob_externos
go
 
set ansi_nulls off
go

set quoted_identifier off
go

if exists (select 1 from sysobjects where name = 'sp_consolidador_cli')
   drop proc sp_consolidador_cli
go

CREATE proc sp_consolidador_cli
   @i_param1    varchar(255)
   
as declare
   @w_error                 int,
   @w_sp_name               varchar(64),
   @w_fecha_proceso         smalldatetime,
   @w_msg                   varchar(64),
   @w_sig_habil             datetime,
   @w_ciudad                int,
   @w_fin_mes               char(1),
   @w_meses_activar         tinyint,
   @w_producto              smallint

SET ANSI_WARNINGS OFF

create table #clientes (ente int null)

/* CARGADO DE VARIABLES DE TRABAJO */
select 
@w_sp_name       = 'sp_consolidador_cli',
@w_fecha_proceso = convert(datetime,@i_param1)

select @w_producto = pd_producto 
from cobis..cl_producto 
where pd_descripcion = 'CLIENTES'
  

/*DETERMINAR LA FECHA DE PROCESO */
if @w_fecha_proceso is null begin
  select 
  @w_fecha_proceso = fc_fecha_cierre
  from cobis..ba_fecha_cierre
  where fc_producto = @w_producto
end

/* MESES PARA DESACTIVAR CLIENTE */
select @w_meses_activar = pa_smallint
from   cobis..cl_parametro 
where  pa_producto = 'CCA' 
and    pa_nemonico = 'MPIC' 


/* CIUDAD DE FERIADOS */
select @w_ciudad = pa_int
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'CIUN'

/* DETERMINAR SI HOY ES EL ULTIMO HABIL DEL MES */
select @w_sig_habil = dateadd(dd, 1, @w_fecha_proceso)

while exists (select 1
                from cobis..cl_dias_feriados
               where df_fecha = @w_sig_habil
                 and df_ciudad = @w_ciudad)
begin
   select @w_sig_habil = dateadd(dd, 1, @w_sig_habil)
end

if datepart(mm, @w_sig_habil) <> datepart(mm, @w_fecha_proceso)
  select @w_fin_mes = 'S'


/* ENTRAR BORRANDO TODA LA INFORMACION GENERADA POR CLIENTES EN COB_EXTERNOS */

truncate table cob_externos..ex_dato_cliente
truncate table cob_externos..ex_dato_direccion
truncate table cob_externos..ex_dato_telefono

truncate table cob_externos..ex_dato_sostenibilidad
truncate table cob_externos..ex_dato_educa_hijos
truncate table cob_externos..ex_dato_sostenibilidad_log
truncate table cob_externos..ex_dato_escolaridad_log
truncate table cob_externos..ex_forma_extractos

/* SELECCIONAR TABLAS MODIFICADAS */
if @w_fin_mes = 'S' begin -- Si es fin de mes paso todos los clientes
  insert into #clientes
  select en_ente 
  from cobis..cl_ente
  where convert(varchar(10),en_fecha_crea,101) <= @w_fecha_proceso
end
else 
begin
  insert into #clientes
  select en_ente 
  from cobis..cl_ente
  where convert(varchar(10),en_fecha_mod,101) = @w_fecha_proceso

  insert into #clientes 
  select distinct di_ente 
  from cobis..cl_direccion 
  where convert(varchar(10),di_fecha_modificacion,101) = @w_fecha_proceso
  and   di_ente not in (select ente from #clientes)

  insert into #clientes 
  select distinct te_ente 
  from cobis..cl_telefono
  where convert(varchar(10),te_fecha_mod,101) = @w_fecha_proceso
  and   te_ente not in (select ente from #clientes)

  insert into #clientes 
  select distinct hi_ente 
  from cobis..cl_hijos
  where convert(varchar(10),hi_fecha_modificacion,101) = @w_fecha_proceso
  and   hi_ente not in (select ente from #clientes)

  insert into #clientes 
  select distinct pr_persona
  from cobis..cl_propiedad
  where convert(varchar(10),pr_fecha_modificacion,101) = @w_fecha_proceso
  and   pr_persona not in (select ente from #clientes)

  insert into #clientes
  select distinct eh_cliente 
  from cobis..cl_educa_hijos
  where  convert(varchar(10),eh_fecha_modif,101) = @w_fecha_proceso
  and   eh_cliente  not in (select ente from #clientes) 

  insert into #clientes
  select distinct cs_cliente
  from cobis..cl_escolaridad_log
  where  convert(varchar(10),cs_fecha_actualizacion,101) = @w_fecha_proceso
  and   cs_cliente not in (select ente from #clientes) 

  insert into #clientes
  select distinct so_cliente
  from cobis..cl_sostenibilidad
  where  convert(varchar(10),so_fecha_modif,101) = @w_fecha_proceso
  and   so_cliente not in (select ente from #clientes) 

  insert into #clientes
  select distinct cs_cliente
  from cobis..cl_sostenibilidad_log
  where  convert(varchar(10),cs_fecha_actualizacion,101) = @w_fecha_proceso
  and   cs_cliente not in (select ente from #clientes)   
end   

/* CARGA DE OPERACIONES ACTIVAS */
select
dc_fecha             = @w_fecha_proceso,
dc_cliente           = en_ente,
dc_tipo_ced          = en_tipo_ced,
dc_ced_ruc           = en_ced_ruc,  
dc_nombre            = en_nombre,
dc_p_apellido        = p_p_apellido,
dc_s_apellido        = p_s_apellido,
dc_subtipo           = en_subtipo,
dc_oficina           = en_oficina,
dc_oficial           = en_oficial,
dc_sexo              = p_sexo,               
dc_actividad         = en_actividad,
dc_retencion         = en_retencion,
dc_sector            = en_sector,
dc_situacion_cliente = en_situacion_cliente,
dc_victima           = en_victima,
dc_exc_sipla         = en_exc_sipla,
dc_estado_civil      = p_estado_civil,
dc_nivel_ing         = p_nivel_ing,
dc_nivel_egr         = p_nivel_egr,
dc_fecha_ingreso     = en_fecha_crea,
dc_fecha_mod         = en_fecha_mod,
dc_fecha_nac         = case when en_subtipo = 'P' then p_fecha_nac else c_fecha_const end,
dc_ciudad_nac        = p_ciudad_nac,
dc_iden_conyuge      = convert(varchar(30),null),
dc_tipo_doc_cony     = convert(varchar(2 ),null),
dc_p_apellido_cony   = convert(varchar(16),null),
dc_s_apellido_cony   = convert(varchar(16),null),
dc_nombre_cony       = convert(varchar(40),null),
dc_estrato           = en_estrato,
dc_tipo_vivienda     = p_tipo_vivienda,
dc_pais              = en_pais,
dc_nivel_estudio     = p_nivel_estudio,
dc_num_carga         = p_num_cargas,
dc_PEP               = en_persona_pub,
dc_fecha_vinculacion = convert(datetime, null),
dc_hipoteca_viv      = convert(char(1),null),
dc_num_activas       = convert(smallint, null),               -- GAL 27/JUL/2010 - PASO A HISTORICOS DE MAESTRO DE CARTERA
dc_estado_cliente    = 'I',
dc_banca             = en_banca,
dc_segmento          = convert(varchar(10),null),
dc_subsegmento       = convert(varchar(10),null),
dc_actprincipal      = convert(varchar(10),null),
dc_actividad2        = convert(varchar(10),null),
dc_actividad3        = convert(varchar(10),null),
dc_bancarizado       = en_bancarizado,
dc_alto_riesgo       = en_alto_riesgo,
dc_fecha_riesgo      = en_fecha_riesgo,
dc_perf_tran         = (select ea_money from cobis..cl_ente_adicional where ea_ente=en_ente and ea_columna='en_perfil_transaccional'),
dc_riesgo            = (select ea_money from cobis..cl_ente_adicional where ea_ente=en_ente and ea_columna='en_riesgo'),
dc_nit               = en_nit,
dc_aplicativo        = @w_producto,
dc_origen            = null,
dc_fecha_proc        = @w_fecha_proceso
into #ente
from cobis..cl_ente, #clientes 
where en_ente = ente

/* Datos Conyugue */
update #ente set
dc_iden_conyuge      = hi_documento,
dc_tipo_doc_cony     = hi_tipo_doc,
dc_p_apellido_cony   = hi_papellido,
dc_s_apellido_cony   = hi_sapellido,
dc_nombre_cony       = hi_nombre 
from cobis..cl_hijos
where dc_cliente = hi_ente
and   hi_conyuge is not null


/* Datos Mercado Objetivo */
update #ente set
dc_segmento          = mo_segmento,
dc_subsegmento       = mo_subsegmento,
dc_actprincipal      = mo_actprincipal,
dc_actividad2        = mo_actividad2,
dc_actividad3        = mo_actividad3
from cobis..cl_mercado_objetivo_cliente
where dc_cliente = mo_ente

/* Fecha Vinculacion */
select ente  = dc_cliente,
       fecha = min(cl_fecha)
into #vinculacion 
from cobis..cl_cliente, #ente
where cl_cliente = dc_cliente
group by dc_cliente

update #ente set
dc_fecha_vinculacion = fecha
from #vinculacion
where ente = dc_cliente

/* Hipoteca */
select ente = dc_cliente
into #hipoteca
from cobis..cl_propiedad, #ente
where pr_persona            = dc_cliente
and   pr_matricula         is not null
and   pr_tipo_veh          is null
and   pr_gravamen_afavor   is not null
and   isnull(pr_gravada,0) > 0

update #ente set
dc_hipoteca_viv = 'S'
from #hipoteca
where ente = dc_cliente


-- INI - GAL 27/JUL/2010
if exists (select 1 from cobis..cl_producto where pd_producto=7)
begin 
  select 
  cliente = op_cliente,
  cant    = count(1)
  into #his
  from cob_cartera..ca_operacion
  where op_estado not in (6, 99)  -- NO EN ESTADO CREDITO Y ANULADO
  group by op_cliente

  insert into #his
  select 
  cliente = op_cliente,
  cant    = count(1)
  from cob_cartera_his..ca_operacion
  where op_estado not in (6, 99)  -- NO EN ESTADO CREDITO Y ANULADO
  group by op_cliente

  select 
  cliente = cliente,
  cant    = sum(cant) 
  into #his_tot
  from #his 
  group by cliente

  update #ente set
  dc_num_activas = cant
  from #his_tot
  where dc_cliente = cliente
  -- FIN - GAL 27/JUL/2010

  /* Cliente Activo - InActivo - Operaciones Cartera - req 144 */

  -- Todos aquellos que tengan operacion vigente son Activos
  update #ente set
  dc_estado_cliente = 'A'
  from cob_cartera..ca_operacion
  where dc_cliente = op_cliente
  and   op_estado not in (99, 3, 0, 6)

  -- Tomar operaciones que puedan generar Inactividad de los clientes que quedaron Inactivos.
  select cliente=dc_cliente, fecha=max(op_fecha_ult_proceso)
  into #cli_operacion_cancelada
  from cob_cartera..ca_operacion, #ente
  where dc_cliente = op_cliente
  and   op_estado = 3
  and   dc_estado_cliente = 'I'
  group by dc_cliente

  select @w_fecha_proceso
  select @w_meses_activar


  -- Defino si la fecha de cancelacion Activa al Cliente
  update #ente set
  dc_estado_cliente = 'A'
  from #cli_operacion_cancelada
  where dc_cliente = cliente
  and   dateadd(mm,@w_meses_activar,fecha) >= @w_fecha_proceso
end

/* CLIENTES */
insert into cob_externos..ex_dato_cliente
select * from #ente

if @@error <> 0 begin
   select 
   @w_error = 1720351, 
   @w_msg = 'Error en al Grabar en tabla cob_externos..ex_dato_cliente'
   goto ERROR
end

/* DIRECCIONES */
select 
dd_fecha                = @w_fecha_proceso,
dd_cliente              = di_ente,
dd_direccion            = di_direccion,
dd_descripcion          = di_descripcion,      
dd_ciudad               = di_ciudad,          
dd_tipo                 = di_tipo,
dd_fecha_ingreso        = di_fecha_registro,   
dd_fecha_modificacion   = di_fecha_modificacion, 
dd_principal            = di_principal,
dd_rural_urb            = di_rural_urb,
dd_provincia            = di_provincia,
dd_parroquia            = di_parroquia,
dd_aplicativo           = @w_producto,
dd_origen               = null,
dd_fecha_proc           = @w_fecha_proceso

into #direcciones
from cobis..cl_direccion, #clientes
where di_ente = ente

insert into cob_externos..ex_dato_direccion
select * from #direcciones

if @@error <> 0 begin
   select 
   @w_error = 1720352, 
   @w_msg = 'Error en al Grabar en tabla cob_externos..ex_dato_direccion'
   goto ERROR
end

/* TELEFONOS */
select 
dt_fecha                = @w_fecha_proceso,
dt_cliente              = te_ente,
dt_direccion            = te_direccion,
dt_secuencial           = te_secuencial,
dt_valor                = te_valor,
dt_tipo_telefono        = te_tipo_telefono,
dt_prefijo              = te_prefijo,
dt_fecha_ingreso        = te_fecha_registro,
dt_fecha_mod            = te_fecha_mod,
dt_tipo_operador        = te_tipo_operador,
dt_aplicativo           = @w_producto,
dt_origen               = null,
dt_fecha_proc           = @w_fecha_proceso
into #telefonos
from cobis..cl_telefono, #clientes
where te_ente = ente

insert into cob_externos..ex_dato_telefono
select * from #telefonos
if @@error <> 0 begin
  select 
  @w_error = 1720353, 
  @w_msg = 'Error en al Actualizar table cob_externos..ex_dato_telefono'
  goto ERROR
end

/* INSERCION PARA PASO DE DATOS DE SOSTENIBILIDAD */
insert into cob_externos..ex_dato_sostenibilidad
select cobis..cl_sostenibilidad.*,@w_producto 
from cobis..cl_sostenibilidad
where convert(varchar(10),so_fecha_modif,101) = @w_fecha_proceso

if @@error <> 0 begin
  select 
  @w_error = 1720354, 
  @w_msg = 'Error al Actualizar tabla cob_externos..ex_ dato_sostenibilidad'
  goto ERROR
end

insert into cob_externos..ex_dato_sostenibilidad_log
select cobis..cl_sostenibilidad_log.*,@w_producto 
from cobis..cl_sostenibilidad_log
where convert(varchar(10),cs_fecha_actualizacion,101) = @w_fecha_proceso

if @@error <> 0 begin
  select 
  @w_error = 1720355, 
  @w_msg = 'Error al Actualizar tabla cob_externos..ex_ dato_sostenibilidad_log'
  goto ERROR
end

insert into cob_externos..ex_dato_educa_hijos
select cobis..cl_educa_hijos.*,@w_producto
from cobis..cl_educa_hijos
where convert(varchar(10),eh_fecha_modif,101) = @w_fecha_proceso

if @@error <> 0 begin
  select 
  @w_error = 1720356, 
  @w_msg = 'Error al Actualizar tabla cob_externos..cob_externos..ex_ dato_educa_hijos'
  goto ERROR
end

insert into cob_externos..ex_dato_escolaridad_log
select cobis..cl_escolaridad_log.*,@w_producto
from cobis..cl_escolaridad_log
where convert(varchar(10),cs_fecha_actualizacion,101) = @w_fecha_proceso

if @@error <> 0 begin
  select 
  @w_error = 1720357, 
  @w_msg = 'Error al Actualizar tabla cob_externos..cob_externos..ex_ dato_escolaridad_log'
  goto ERROR
end

insert into cob_externos..ex_forma_extractos
select cobis..cl_forma_extractos.*,@w_producto
from cobis..cl_forma_extractos
where fe_fecha = @w_fecha_proceso

if @@error <> 0 begin
  select 
  @w_error = 1720358, 
  @w_msg = 'Error al Actualizar tabla cob_externos..cob_externos..ex_forma_extractos'
  goto ERROR
end

set ansi_warnings on
return 0

ERROR:

set ansi_warnings on
return @w_error

go
