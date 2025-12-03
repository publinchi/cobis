/********************************************************************/
/*   NOMBRE LOGICO:          sp_negocio_cliente                     */
/*   NOMBRE FISICO:          negocio_cliente.sp                     */
/*   Producto:               Clientes                               */
/*   Disenado por:           JMEG                                   */
/*   Fecha de escritura:     30-Abril-19                            */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                                  PROPOSITO                       */
/*   Este programa da mantenimiento a la tabla cl_negocio_cliente   */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*      FECHA           AUTOR           RAZON                       */
/*    30/04/19           JMEG      Emision Inicial                  */
/*    18/06/19           JMEG      REDMINE 119614                   */
/*    04/Jul/2019        RIGG      Cambiar campos num int y ext     */
/*    21/Ago/2019        RIGG      Se cambia loc cobis a localidad  */ 
/*    31/Ago/2019        RIGG      Fecha proceso no debe ser null   */
/*    04/Oct/2019        RIGG      Agregar campo nc_actividad_neg   */
/*    24/Jun/2020        FSAP      Estandarizacion de Clientes      */
/*    20/Ago/2021        ACU       Se cambia operacion al llamar    */
/*                                 direcciones para que se creen    */
/*                                 separadas, se elimina telefonos  */
/*    06/Sep/2021        ACA       Consulta de pais de direccion    */
/*    20/Mar/2023        OAL       S784824 Aumento para APP op I,U  */
/*    30/Jun/2023        EBA       S849151 se realiza la conversión */
/*                                 de los tipos de documento        */
/*                                 principal y tributario que       */
/*                                 vienen desde la app enbase a la  */
/*                                 máscara parametrizada.           */
/*    09/Sep/2023        BDU       R214440-Sincronizacion automatica*/
/*    22/Ene/2024        BDU       R224055-Validar oficina app      */
/*    09/Abr/2025        BDU       R251295-Ajustes data negocio     */
/********************************************************************/
use cobis
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 
             from sysobjects 
            where name = 'sp_negocio_cliente')
   drop proc sp_negocio_cliente 
go

create proc sp_negocio_cliente (
   @s_ssn             int          = null,
   @s_user            login        = null,
   @s_term            varchar(32)  = null,
   @s_date            datetime     = null,
   @s_sesn            int          = null,
   @s_culture         varchar(10)  = null,
   @s_srv             varchar(30)  = null,
   @s_lsrv            varchar(30)  = null,
   @s_ofi             smallint     = null,
   @s_rol             smallint     = NULL,
   @s_org_err         char(1)      = NULL,
   @s_error           int          = NULL,
   @s_sev             tinyint      = NULL,
   @s_msg             descripcion  = NULL,
   @s_org             char(1)      = NULL,
   @t_debug           char(1)      = 'N',
   @t_file            varchar(10)  = null,
   @t_from            varchar(32)  = null,
   @t_trn             int          = null,
   @t_show_version    bit          = 0,
   @i_operacion       char(1),     
   @i_codigo          int          = null,
   @i_ente            int          = null,
   @i_nc_tipo_id      char(4)      = null,
   @i_nc_num_id       varchar(30)  = null,
   @i_nombre          varchar(60)  = null,
   @i_giro            varchar(10)  = null,
   @i_fecha_apertura  datetime     = null,
   @i_calle           varchar(80)  = null,
   @i_nro             varchar(40)  = null,
   @i_colonia         varchar(10)  = null,
   @i_localidad       varchar(20)  = null,
   @i_municipio       varchar(10)  = null,
   @i_estado          varchar(10)  = null,
   @i_codpostal       varchar(30)  = null,
   @i_pais            varchar(10)  = null,
   @i_telefono        varchar(20)  = null,
   @i_actividad_ec    varchar(10)  = null,
   @i_tiempo_activida int          = null,
   @i_tiempo_dom_neg  int          = null,
   @i_emprendedor     char(1)      = null,
   @i_recurso         varchar(10)  = null,
   @i_ingreso_mensual money        = null,
   @i_tipo_local      varchar(10)  = null,
   @i_estado_reg      char(10)     = null,
   @i_destino_credito varchar(10)  = null,
   @o_codigo          int          = null  output,
   @o_telefono_id     int          = null  output,
   @i_sector          catalogo     = null,
   @i_subsector       catalogo     = null,
   @i_misma_dir       char(1)      = null,
   @i_nro_interno     varchar(40)  = null,
   @i_referencia_neg  varchar(225) = null,
   @i_rfc_neg         varchar(15)  = null,
   @i_dias_neg        varchar(20)  = null,
   @i_hora_ini        varchar(10)  = null,
   @i_hora_fin        varchar(10)  = null,
   @i_atiende         varchar(40)  = null,
   @i_empleados       smallint     = null,
   @i_actividad_neg   varchar(70)  = null,
   @i_sector_region   varchar(10)  = null,
   @i_zona            varchar(10)  = null,
   @i_desasociar_dir  char(1)      = 'N',
   @i_direccion       tinyint      = null,
   @i_is_app          char(1)      = 'N'


)as
declare 
   @w_ts_name            varchar(32),
   @w_num_error          int,
   @w_sp_name            varchar(32),
   @w_sp_msg             varchar(132),
   @w_codigo             int,
   @w_ente               int,
   @w_nombre             varchar(60),
   @w_giro               varchar(10),
   @w_fecha_apertura     datetime,
   @w_calle              varchar(80),
   @w_nro                varchar(40),
   @w_colonia            varchar(10),
   @w_localidad          varchar(20),
   @w_municipio          varchar(10),
   @w_estado             varchar(10),
   @w_codpostal          varchar(30),
   @w_pais               varchar(10),
   @w_telefono           varchar(20),
   @w_actividad_ec       varchar(10),
   @w_tiempo_activida    int,
   @w_tiempo_dom_neg     int,
   @w_emprendedor        char(1),
   @w_recurso            varchar(10),
   @w_ingreso_mensual    money,
   @w_tipo_local         varchar(10),
   @w_estado_reg         char(10),
   @w_param_emprede      int,          --variable de tiempo para ser emprendedor
   @w_diff_dias          int,
   @w_destino_credito    varchar(10),
   @w_direccion          int,
   @w_cod_area           int,
   @w_len                int,
   @w_secuencial         int,
   @w_telefono_aux       varchar(20),
   @w_telefono_id        int,
   @w_sector             catalogo,--agregar las columnas nuevas
   @w_subsector          catalogo,
   @w_misma_dir          char(1),
   @w_nro_interno        varchar(40),
   @w_referencia_neg     varchar(225),
   @w_rfc_neg            varchar(15),
   @w_dias_neg           varchar(20),
   @w_hora_ini           varchar(10),
   @w_hora_fin           varchar(10),
   @w_atiende            varchar(40),
   @w_empleados          smallint,
   @w_actividad_neg      varchar(70),
   @w_direccion_dml      tinyint,
   @w_fp_fecha           datetime,
   @w_sector_region      varchar(10),
   @w_zona               varchar(10),
   @w_num                int,
   @w_param              int, 
   @w_diff               int,
   @w_date               datetime,
   @w_bloqueo            char(1),
   @w_nacionalidad       varchar(10),
   @w_pais_local         int,
   @w_tipo_cliente       char(1),
   @w_mascara            varchar(30),
   @w_doc_trib_mascara   varchar(30),
   -- R214440-Sincronizacion automatica
   @w_sincroniza      char(1),
   @w_ofi_app         smallint
   
select @w_sp_name = 'sp_negocio_cliente'


---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
  
  
   -- Validar codigo de transacciones --
if ((@t_trn <> 172060 and @i_operacion = 'I') or
    (@t_trn <> 172061 and @i_operacion = 'U') or
    (@t_trn <> 172062 and @i_operacion = 'D') or
    (@t_trn <> 172063 and (@i_operacion = 'S' or @i_operacion = 'Q' or @i_operacion = 'H')))
begin
   select @w_num_error = 1720075 --Transaccion no permitida
   goto errores
end

select @i_nc_num_id = upper(isnull(@i_nc_num_id, ''))

if @i_operacion in ('I', 'U', 'D')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   if @i_ente is not null and @i_ente <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_ente
      if @w_bloqueo = 'S'
      begin
         select @w_num_error = 1720604
         goto errores
      end
   end 
end

select @w_pais_local      = pa_smallint 
from cobis..cl_parametro 
where pa_nemonico = 'CP'    
and pa_producto = 'CLI'  -- PAIS DONDE ESTÁ EL BANCO

if @w_pais_local <> @i_pais 
begin
   select @w_nacionalidad = 'E'
end
else
begin
   select @w_nacionalidad = 'N'
end

select @w_tipo_cliente = en_subtipo from cl_ente where en_ente = @i_ente
  
--VALIDACION DE ESTADO DE TIPO DE IDENTIFICACION TRIBUTARIA
if(select ti_estado from cl_tipo_identificacion
   where ti_codigo         = @i_nc_tipo_id 
   and   ti_tipo_documento = 'T' 
   and   ti_nacionalidad   = @w_nacionalidad 
   and   ti_tipo_cliente   = @w_tipo_cliente) != 'V'
begin
   select @w_num_error = 1720607
   goto errores
end 


--validacion para distinguir emprendedor
if @i_operacion in ('I', 'U')
begin
   select @w_param_emprede = pa_smallint 
     from cl_parametro 
    where pa_producto = 'CLI' 
      and pa_nemonico = 'NDEP'
   
   select @w_fp_fecha = fp_fecha from ba_fecha_proceso
   
   select @w_diff_dias =  datediff(mm, @i_fecha_apertura, @w_fp_fecha)
   if @w_diff_dias <= @w_param_emprede
      select @w_emprendedor = 'S'
   else
      select @w_emprendedor = 'N'
      
   --PARA APP Se deja valores quemados
   if @i_is_app = 'S' and @i_actividad_ec is not null
   begin
   
   
   
   
       select @i_subsector = ac_codSubsector, 
              @i_actividad_neg = ac_descripcion   
         from cobis..cl_actividad_ec
        where ac_codigo = @i_actividad_ec
        
        select @i_sector = se_codSector 
        from cobis.dbo.cl_subsector_ec
        where se_codigo = @i_subsector
		
        select @i_dias_neg = '1,2,3,4,5',
               @i_hora_ini = '07:00',
               @i_hora_fin = '21:00'
   end


end

if (@i_sector is not null)
-- obtener sector
begin
   select top 1 @w_sector = codigo from cobis..cl_catalogo 
   where codigo = @i_sector
     and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_sector_economico')
   
  if @@rowcount = 0
  begin
    select @w_num_error =  1720276 --no existe sector
    goto errores
  end 
end

if (@i_codpostal is not null)
-- obtener codigo postal
begin
  select top 1 @w_codpostal = cp_codigo from cobis..cl_codigo_postal 
   where cp_codigo = @i_codpostal

  if @@rowcount = 0
  begin
    select @w_num_error =  1720277 --no existe codigo postal
    goto errores
  end 
end

-- obtener subsector
if (@i_subsector is not null)
begin
  select top 1 @w_subsector = codigo from cobis..cl_catalogo
   where codigo = @i_subsector
     and tabla = (select codigo from cobis..cl_tabla where tabla like '%cl_subsector_ec%')
   
  if @@rowcount = 0
  begin
    select @w_num_error =  1720278 -- no existe subsector
    goto errores
  end 
end

--pais de la direccion
if(@i_direccion is not null and @i_pais is null)
begin
   select @i_pais = di_pais from cobis..cl_direccion where di_ente = @i_ente and di_direccion = @i_direccion
end

if (@i_misma_dir is not null and @i_misma_dir = 'S')
  begin
  -- obtener misma direccion de cliente
    select TOP 1 
    @w_ente= di_ente, 
    @i_pais = di_pais, 
    @i_codpostal = di_codpostal,
    @i_calle = di_calle, 
    @i_nro = di_casa, 
    @i_nro_interno = di_edificio,
    @i_colonia =  di_parroquia, 
    @i_localidad  = di_localidad ,    
    @i_municipio  =  di_ciudad  , 
    @i_estado = di_provincia ,
    @i_referencia_neg = di_referencias_dom  
    from cobis..cl_direccion 
    where di_ente = @i_ente
    AND di_tipo = 'RE'
    and di_vigencia = 'S'
    order by di_direccion desc
    if @@rowcount = 0
    begin
      select @w_num_error =  1720279 --NO EXISTE NEGOCIO DEL CLIENTE
      goto errores
    end 
  end
if @i_operacion = 'I'
begin
    
    begin tran
    exec @w_num_error = cobis..sp_cseqnos
   @t_debug     = @t_debug,
        @t_file      = @t_file,
        @t_from      = @w_sp_name,
        @i_tabla     = 'cl_negocio_cliente',
        @o_siguiente = @w_codigo out
        
    select @o_codigo = @w_codigo
       

        if @w_num_error <> 0
        begin
            select @w_num_error = 1720280 --NO EXISTE TABLA EN TABLA DE SECUENCIALES
            goto errores
        end
    
    
    if @i_fecha_apertura is null
    begin     
      select @w_fecha_apertura = fp_fecha 
      from cobis..ba_fecha_proceso
    end
    else
    begin
      select @w_fecha_apertura = @i_fecha_apertura
    end
    
    if @i_actividad_neg is null
    begin
       select @w_num_error = 1720281 --NO EXISTE TABLA EN TABLA DE SECUENCIALES
       goto errores
    end
    
    --Validación para guardar identificación principal y tributaria con máscara definida
    if @i_is_app = 'S'
    begin
        if @i_nc_tipo_id = 'NIT' and (@i_nc_num_id is not null and @i_nc_num_id <> '')
        begin
            --Tipo de identificación Tributaria
            select @w_mascara = ti_mascara
            from  cobis..cl_tipo_identificacion
            where ti_codigo = @i_nc_tipo_id
            and   ti_tipo_cliente = 'P'
            and   ti_tipo_documento = 'T'
            and   ti_nacionalidad   = @w_nacionalidad
            and   ti_estado = 'V'
            
            select @w_doc_trib_mascara = cobis.dbo.fn_parsea_identificacion (@i_nc_num_id, @w_mascara)
            select @i_nc_num_id = @w_doc_trib_mascara
        end
    end
    
    if((@i_nc_tipo_id is not null and @i_nc_tipo_id != '') and 
       (@i_nc_num_id is not null and @i_nc_num_id != ''))
    begin
       if exists(select 1 from cl_negocio_cliente where nc_tipo_id = @i_nc_tipo_id 
                                                 and nc_num_id = @i_nc_num_id)
       begin
          select @w_num_error = 1720487 --YA EXISTE UN NEGOCIO REGISTRADO CON LA MISMA IDENTIFICACIÓN Y NÚMERO
          goto errores
       end
    end
    
    insert into cl_negocio_cliente(
    nc_codigo,          nc_ente,            nc_nombre,         nc_giro,                nc_fecha_apertura,      nc_calle,
    nc_nro,             nc_colonia,         nc_localidad,      nc_municipio,           nc_estado,              nc_codpostal,
    nc_pais,            nc_telefono,        nc_actividad_ec,   nc_tiempo_actividad,    nc_tiempo_dom_neg,      nc_emprendedor,
    nc_recurso,         nc_ingreso_mensual, nc_tipo_local,     nc_estado_reg,          nc_destino_credito,
    nc_sector,          nc_subsector,       nc_misma_dir,      nc_nro_interno,         nc_referencia_neg,      nc_rfc_neg, 
    nc_dias_neg,        nc_hora_ini,        nc_hora_fin,       nc_atiende,             nc_empleados           ,nc_actividad_neg,
    nc_tipo_id,         nc_num_id,          nc_sector_region,  nc_zona)
    values(
    @w_codigo,          @i_ente,            @i_nombre,         @i_giro,                @w_fecha_apertura,      @i_calle,
    @i_nro,             @i_colonia,         @i_localidad,      @i_municipio,           @i_estado,              @i_codpostal,
    @i_pais,            @i_telefono,        @i_actividad_ec,   @i_tiempo_activida,     @i_tiempo_dom_neg,      @w_emprendedor,
    @i_recurso,         @i_ingreso_mensual, @i_tipo_local,     'V',                    @i_destino_credito,
    @i_sector,          @i_subsector,       @i_misma_dir,      @i_nro_interno,         @i_referencia_neg,      @i_rfc_neg, 
    @i_dias_neg,        @i_hora_ini,        @i_hora_fin,       @i_atiende,             @i_empleados           ,@i_actividad_neg,
    @i_nc_tipo_id,      @i_nc_num_id,       @i_sector_region,  @i_zona)
    if @@error <> 0
      begin   
         select @w_num_error = 1720282 --ERROR AL INSERTAR NEGOCIO DEL CLIENTE!
         goto errores
      end
    --agregar las columnas nuevas
    insert into ts_negocio_cliente(
    ts_secuencial,      ts_codigo,          ts_ente,            ts_nombre,            ts_giro,                ts_fecha_apertura,
    ts_calle,           ts_nro,             ts_colonia,         ts_localidad,         ts_municipio,           ts_estado,
    ts_codpostal,       ts_pais,            ts_telefono,        ts_actividad_ec,      ts_tiempo_actividad,    ts_tiempo_dom_neg,
    ts_emprendedor,     ts_recurso,         ts_ingreso_mensual, ts_tipo_local,        ts_usuario,             ts_oficina,
    ts_fecha_proceso,   ts_operacion,       ts_estado_reg,      ts_destino_credito,
    ts_sector,          ts_subsector,       ts_misma_dir,       ts_nro_interno,       ts_referencia_neg,      ts_rfc_neg,
    ts_dias_neg,        ts_hora_ini,        ts_hora_fin,        ts_atiende,           ts_empleados           ,ts_actividad_neg,
    ts_nc_tipo_id,      ts_nc_num_id)
    values (
    @s_sesn,            @w_codigo,          @i_ente,            @i_nombre,            @i_giro,                @w_fecha_apertura,     
    @i_calle,           @i_nro,             @i_colonia,         @i_localidad,         @i_municipio,           @i_estado,
    @i_codpostal,       @i_pais,            @i_telefono,        @i_actividad_ec,      @i_tiempo_activida,     @i_tiempo_dom_neg,
    @w_emprendedor,     @i_recurso,         @i_ingreso_mensual, @i_tipo_local,        @s_user,                @s_ofi,
    @s_date,            @i_operacion,       'V',                @i_destino_credito,
    @i_sector,          @i_subsector,       @i_misma_dir,       @i_nro_interno,       @i_referencia_neg,      @i_rfc_neg, 
    @i_dias_neg,        @i_hora_ini,        @i_hora_fin,        @i_atiende,           @i_empleados           ,@i_actividad_neg,
    @i_nc_tipo_id,      @i_nc_num_id)
    if @@error <> 0
      begin   
         select @w_num_error = 1720049 --ERROR AL REGISTRAR TRANSACCION DE SERVICIO
         goto errores
      end



    
    
    --begin
    
DECLARE @return_value int,
        @o_dire int
          --exec para insertar direccion 
        EXEC  @return_value = cobis..sp_direccion_dml
        @s_ssn                = @s_ssn,
        @s_date               = @s_date,
        @t_debug              = N'N',
        @t_trn                = 172016,
        @i_operacion          = N'N',
        @i_ente               = @i_ente,
        @i_descripcion        = N'NEGOCIO',
        @i_tipo               = N'AE',
        @i_parroquia          = @i_colonia,
        @i_verificado         = N'N',
        @i_principal          = N'N',
        @i_provincia          = @i_estado,
        @i_codpostal          = @i_codpostal,
        @i_define             = N'N',
        @i_calle              = @i_calle,
        @i_tiempo_reside      = @i_tiempo_activida,
        @i_pais               = @i_pais,
        @i_correspondencia    = N'N',
        @i_fact_serv_pu       = N'N',
        @i_ejecutar           = N'N',
        @t_show_version       = 0,
        @i_nro                = @i_nro,
        @i_nro_interno        = @i_nro_interno,
        @i_ci_poblacion       = 'POBLACION',
        @i_referencias_dom    = @i_referencia_neg,
        @i_localidad          = @i_localidad,
        @i_ciudad             = @i_municipio,
        @i_negocio            = @w_codigo,
        @i_zona               = @i_zona,
        @i_sector             = @i_sector_region,
        @i_direccion          = @i_direccion
        
        if @return_value <> 0
        begin
            ROLLBACK TRAN
        end
    
      
     commit tran 
    --end
  -- Actualizacion Automatica de Prospecto a Cliente
  exec cobis..sp_seccion_validar
    @i_ente     = @i_ente,
    @i_operacion  = 'V',
    @i_seccion    = '3', --3 es Negocios
    @i_completado   = 'S'
    
    goto fin
end

if @i_operacion = 'U'
begin
    select
        @w_codigo            = nc_codigo,
        @w_ente              = nc_ente,
        @w_nombre            = nc_nombre,
        @w_giro              = nc_giro,
        @w_fecha_apertura    = nc_fecha_apertura,
        @w_calle             = nc_calle,
        @w_nro               = nc_nro,         
        @w_colonia           = nc_colonia,
        @w_localidad         = nc_localidad,
        @w_municipio         = nc_municipio,     
        @w_estado            = nc_estado,
        @w_codpostal         = nc_codpostal,
        @w_pais              = nc_pais,
        @w_telefono          = nc_telefono,
        @w_actividad_ec      = nc_actividad_ec,
        @w_tiempo_activida   = nc_tiempo_actividad,
        @w_tiempo_dom_neg    = nc_tiempo_dom_neg,
        @w_recurso           = nc_recurso,
        @w_ingreso_mensual   = nc_ingreso_mensual,
        @w_tipo_local        = nc_tipo_local,
        @w_estado_reg        = nc_estado_reg,
        @w_destino_credito   = nc_destino_credito,
        @w_sector            = nc_sector,--agregar las columnas nuevas?
        @w_subsector         = nc_subsector,
        @w_misma_dir         = nc_misma_dir,
        @w_nro_interno       = nc_nro_interno,
        @w_referencia_neg    = nc_referencia_neg,
        @w_rfc_neg           = nc_rfc_neg,
        @w_dias_neg          = nc_dias_neg,
        @w_hora_ini          = nc_hora_ini,
        @w_hora_fin          = nc_hora_fin,
        @w_atiende           = nc_atiende,
        @w_empleados         = nc_empleados,
        @w_actividad_neg     = nc_actividad_neg,
        @w_sector_region     = nc_sector_region,
        @w_zona              = nc_zona
    from cl_negocio_cliente
    where nc_ente = @i_ente
  and nc_codigo = @i_codigo

    if @@rowcount = 0
      begin
         select @w_num_error =  1720285 --NO EXISTE NEGOCIO DEL CLIENTE
         goto errores
      end 
    
    begin tran
    
    
    if(@s_ofi = 9001) --Es el movil
    begin
      
      select TOP 1 @w_direccion = di_direccion from cobis..cl_direccion 
      where di_ente = @i_ente
      AND di_tipo = 'AE'
      
      
      select @w_len = len(@i_telefono)
      if @w_len > 9
      begin
         select @w_len = @w_len - 9
      end
      else
      begin
         select @w_len = 0
      end
      
      select @w_cod_area = substring(@i_telefono,0,@w_len)
      
      select @w_telefono_aux = RIGHT(@i_telefono, 10)--substring(@i_telefono,4,12)
      
      --PRINT @w_len
      --PRINT @w_cod_area
      --PRINT @i_telefono
      
      
      if exists(select 1 from cl_telefono where te_ente = @i_ente 
      and te_direccion = @w_direccion and te_tipo_telefono = 'D' and te_valor = @w_telefono_aux)
      begin
      select top 1 @w_secuencial = te_secuencial from cl_telefono where te_ente = @i_ente 
      and te_direccion = @w_direccion and te_tipo_telefono = 'D' and te_valor = @w_telefono_aux
    end
    else
    begin
      select top 1 @w_secuencial = te_secuencial from cl_telefono where te_ente = @i_ente 
      and te_direccion = @w_direccion and te_tipo_telefono = 'D'
    end
    
      
    end
    
    --agregar las columnas nuevas
    insert into ts_negocio_cliente(
    ts_secuencial,      ts_codigo,          ts_ente,            ts_nombre, ts_giro,                ts_fecha_apertura,
    ts_calle,           ts_nro,             ts_colonia,         ts_localidad,         ts_municipio,           ts_estado,
    ts_codpostal,       ts_pais,            ts_telefono,        ts_actividad_ec,      ts_tiempo_actividad,    ts_tiempo_dom_neg,
    ts_emprendedor,     ts_recurso,         ts_ingreso_mensual, ts_tipo_local,        ts_usuario,             ts_oficina,
    ts_fecha_proceso,   ts_operacion,       ts_estado_reg,      ts_destino_credito,
    ts_sector,          ts_subsector,       ts_misma_dir,       ts_nro_interno,       ts_referencia_neg,      ts_rfc_neg,
    ts_dias_neg,        ts_hora_ini,        ts_hora_fin,        ts_atiende,           ts_empleados           ,ts_actividad_neg,
    ts_nc_num_id,       ts_nc_tipo_id)
    values (
    @s_sesn,            @w_codigo,          @w_ente,            @w_nombre,            @w_giro,                @w_fecha_apertura,     
    @w_calle,           @w_nro,             @w_colonia,         @w_localidad,         @w_municipio,           @w_estado,
    @w_codpostal,       @w_pais,            @w_telefono,        @w_actividad_ec,      @w_tiempo_activida,     @w_tiempo_dom_neg,
    @w_emprendedor,     @w_recurso,         @w_ingreso_mensual, @w_tipo_local,        @s_user,                @s_ofi,
    @s_date,            'A',                @w_estado_reg,      @w_destino_credito,
    @w_sector,          @w_subsector,       @w_misma_dir,       @w_nro_interno,       @w_referencia_neg,      @w_rfc_neg, 
    @w_dias_neg,        @w_hora_ini,        @w_hora_fin,        @w_atiende,           @w_empleados           ,@i_actividad_neg,
    @i_nc_num_id,       @i_nc_tipo_id)       --A = Registro actual
    if @@error <> 0
      begin   
         select @w_num_error = 1720049 --ERROR AL REGISTRAR TRANSACCION DE SERVICIO
         goto errores
      end
      
    if @i_ente is not null
        select @w_ente = @i_ente
    
    if @i_nombre is not null
        select @w_nombre = @i_nombre
        
    if @i_giro is not null
        select @w_giro = @i_giro
    
    if @i_calle is not null
        select @w_calle = @i_calle
    
    if @i_nro is not null
        select @w_nro = @i_nro
        
    if @i_colonia is not null
        select @w_colonia = @i_colonia
    
    if @i_localidad is not null
        select @w_localidad = @i_localidad
        
    if @i_municipio is not null
        select @w_municipio = @i_municipio
        
    if @i_estado is not null
        select @w_estado = @i_estado

    if @i_codpostal is not null
        select @w_codpostal = @i_codpostal
        
    if @i_pais is not null
        select @w_pais = @i_pais
        
    if @i_telefono is not null
        select @w_telefono = @i_telefono

    if @i_actividad_ec is not null
        select @w_actividad_ec = @i_actividad_ec
        
    if @i_tiempo_activida is not null
        select @w_tiempo_activida = @i_tiempo_activida
        
    if @i_tiempo_dom_neg is not null
        select @w_tiempo_dom_neg = @i_tiempo_dom_neg
    
    if @i_recurso is not null
        select @w_recurso = @i_recurso
        
    if @i_ingreso_mensual is not null
        select @w_ingreso_mensual = @i_ingreso_mensual
        
    if @i_tipo_local is not null
        select @w_tipo_local = @i_tipo_local
        
    if @i_estado_reg is not null
        select @w_estado_reg = @i_estado_reg
        
    if @i_destino_credito is not null
        select @w_destino_credito = @i_destino_credito
                      
    if @i_sector is not null      
        select @w_sector = @i_sector                  
  
    if @i_subsector is not null
        select @w_subsector = @i_subsector    
 
    if @i_misma_dir is not null
        select @w_misma_dir = @i_misma_dir    
   
   if @i_nro_interno is not null
        select @w_nro_interno = @i_nro_interno

  if @i_nro_interno is null 
    select @w_nro_interno = ' '
   
   if @i_referencia_neg is not null
        select @w_referencia_neg = @i_referencia_neg    
   
   if @i_rfc_neg is not null
        select @w_rfc_neg = @i_rfc_neg    
   
   if @i_dias_neg is not null
        select @w_dias_neg = @i_dias_neg    
   
   if @i_hora_ini is not null
        select @w_hora_ini = @i_hora_ini    
   
   if @i_hora_fin is not null
        select @w_hora_fin = @i_hora_fin    
   
   if @i_atiende is not null
        select @w_atiende = @i_atiende    
   
   if @i_empleados is not null
        select @w_empleados = @i_empleados  

   if @i_actividad_neg is not null
        select @w_actividad_neg = @i_actividad_neg      

   if @i_sector_region is not null
        select @w_sector_region = @i_sector_region 

   if @i_zona is not null
        select @w_zona = @i_zona
        
        --Validación para guardar identificación principal y tributaria con máscara definida
    if @i_is_app = 'S'
    begin
        if @i_nc_tipo_id = 'NIT' and (@i_nc_num_id is not null and @i_nc_num_id <> '')
        begin
            --Tipo de identificación Tributaria
            select @w_mascara = ti_mascara
            from  cobis..cl_tipo_identificacion
            where ti_codigo = @i_nc_tipo_id
            and   ti_tipo_cliente = 'P'
            and   ti_tipo_documento = 'T'
            and   ti_nacionalidad   = @w_nacionalidad
            and   ti_estado = 'V'
            
            select @w_doc_trib_mascara = cobis.dbo.fn_parsea_identificacion (@i_nc_num_id, @w_mascara)
            select @i_nc_num_id = @w_doc_trib_mascara
        end
    end
	
    update cl_negocio_cliente
    set nc_ente               =      @w_ente,
        nc_nombre             =      @w_nombre,
        nc_giro               =      @w_giro,
        nc_num_id             =      @i_nc_num_id,
        nc_tipo_id            =      @i_nc_tipo_id,
        nc_fecha_apertura     =      @w_fecha_apertura,
        nc_calle              =      @w_calle,
        nc_nro                =      @w_nro,
        nc_colonia            =      @w_colonia,
        nc_localidad          =      @w_localidad,
        nc_municipio          =      @w_municipio,
        nc_estado             =      @w_estado,
        nc_codpostal          =      @w_codpostal,
        nc_pais               =      @w_pais,
        nc_telefono           =      @w_telefono,
        nc_actividad_ec       =      @w_actividad_ec,
        nc_tiempo_actividad   =      @w_tiempo_activida,
        nc_tiempo_dom_neg     =      @w_tiempo_dom_neg,
        nc_emprendedor        =      @w_emprendedor,
        nc_recurso            =      @w_recurso,
        nc_ingreso_mensual    =      @w_ingreso_mensual,
        nc_tipo_local         =      @w_tipo_local,
        nc_estado_reg         =      @w_estado_reg,
        nc_destino_credito    =      @w_destino_credito,
        nc_sector             =      @w_sector,
        nc_subsector          =      @w_subsector,
        nc_misma_dir          =      @w_misma_dir,
        nc_nro_interno        =      @w_nro_interno,
        nc_referencia_neg     =      @w_referencia_neg,
        nc_rfc_neg            =      @w_rfc_neg,
        nc_dias_neg           =      @w_dias_neg,
        nc_hora_ini           =      @w_hora_ini,
        nc_hora_fin           =      @w_hora_fin,
        nc_atiende            =      @w_atiende,
        nc_empleados          =      @w_empleados,
        nc_actividad_neg      =      @w_actividad_neg,
        nc_sector_region      =      @w_sector_region,
        nc_zona               =      @w_zona
    where nc_ente = @i_ente
    and nc_codigo = @i_codigo
      
      if @@error != 0
      begin
         select @w_num_error = 1720286 --ERROR AL ACTUALIZAR NEGOCIO DEL CLIENTE!
         goto errores
      end
    --agregar las columnas nuevas
    insert into ts_negocio_cliente(
    ts_secuencial,      ts_codigo,          ts_ente,           ts_nombre,             ts_giro,                ts_fecha_apertura,
    ts_calle,           ts_nro,             ts_colonia,        ts_localidad,          ts_municipio,           ts_estado,
    ts_codpostal,       ts_pais,            ts_telefono,       ts_actividad_ec,       ts_tiempo_actividad,    ts_tiempo_dom_neg,
    ts_emprendedor,     ts_recurso,         ts_ingreso_mensual,ts_tipo_local,         ts_usuario,             ts_oficina,
    ts_fecha_proceso,   ts_operacion,       ts_estado_reg,     ts_destino_credito,
    ts_sector,          ts_subsector,       ts_misma_dir,      ts_nro_interno,        ts_referencia_neg,      ts_rfc_neg, 
    ts_dias_neg,        ts_hora_ini,        ts_hora_fin,       ts_atiende,            ts_empleados           ,ts_actividad_neg,
    ts_nc_num_id,       ts_nc_tipo_id)
    values (
    @s_sesn,            @w_codigo,          @w_ente,            @w_nombre,            @w_giro,                @w_fecha_apertura,     
    @w_calle,           @w_nro,             @w_colonia,         @w_localidad,         @w_municipio,           @w_estado,
    @w_codpostal,       @w_pais,            @w_telefono,        @w_actividad_ec,      @w_tiempo_activida,     @w_tiempo_dom_neg,
    @w_emprendedor,     @w_recurso,         @w_ingreso_mensual, @w_tipo_local,        @s_user,                @s_ofi,
    @s_date,            'D',                @w_estado_reg,      @w_destino_credito, 
    @w_sector,          @w_subsector,       @w_misma_dir,       @w_nro_interno,       @w_referencia_neg,      @w_rfc_neg, 
    @w_dias_neg,        @w_hora_ini,        @w_hora_fin,        @w_atiende,           @w_empleados           ,@i_actividad_neg,
    @i_nc_num_id,       @i_nc_tipo_id)       --D = Registro modificado
    if @@error <> 0
      begin   
         select @w_num_error = 1720049 --ERROR AL REGISTRAR TRANSACCION DE SERVICIO
         goto errores
      end

    
    /**Antes de terminar la operacion hacemos el update de la tabla de direcciones la dirección modificada**/
  select @w_direccion_dml= isnull(di_direccion,0) from cobis..cl_direccion where di_negocio =  @i_codigo  and di_ente=@i_ente
 
    if @w_direccion_dml>0 
    begin
      EXEC  [cobis].[dbo].[sp_direccion_dml]
        @s_ssn                = @s_ssn,
        @s_date               = @s_date,
        @t_debug              = N'N',
        @t_trn                = 172019,
        @i_operacion          = N'N',
        @i_ente               = @i_ente,
        @i_descripcion        = N'NEGOCIO',
        @i_tipo               = N'AE',
        @i_parroquia          = @i_colonia,
        @i_verificado         = N'N',
        @i_principal          = N'N',
        @i_provincia          = @i_estado,
        @i_codpostal          = @i_codpostal,
        @i_define             = N'N',
        @i_calle              = @i_calle,
        @i_tiempo_reside      = @i_tiempo_activida,
        @i_pais               = @i_pais,
        @i_correspondencia    = N'N',
        @i_fact_serv_pu       = N'N',
        @i_ejecutar           = N'N',
        @t_show_version       = 0,
        @i_nro                = @i_nro,
        @i_nro_interno        = @i_nro_interno,
        @i_ci_poblacion       = 'POBLACION',
        @i_referencias_dom    = @i_referencia_neg,
        @i_localidad          = @i_localidad,
        @i_ciudad             = @i_municipio,
        @i_negocio            = @w_codigo,
        @i_direccion          = @i_direccion,
        @i_zona               = @w_zona,
        @i_sector             = @w_sector_region
        
        if @@error <> 0
        begin
            ROLLBACK TRAN
        end
    end
    commit tran
    
goto fin
end

if @i_operacion = 'D'
begin
    select (1) from cl_negocio_cliente where nc_codigo = @i_codigo
    if @@rowcount = 0
      begin
         select @w_num_error =  1720285 --NO EXISTE NEGOCIO DEL CLIENTE!
         goto errores
      end 
      begin tran
      select
        @w_codigo            = nc_codigo,
        @w_ente              = nc_ente,
        @w_nombre            = nc_nombre,
        @w_giro              = nc_giro,
        @w_fecha_apertura   = nc_fecha_apertura,
        @w_calle             = nc_calle,
        @w_nro               = nc_nro,         
        @w_colonia           = nc_colonia,
        @w_localidad         = nc_localidad,
        @w_municipio         = nc_municipio,     
        @w_estado            = nc_estado,
        @w_codpostal         = nc_codpostal,
        @w_pais              = nc_pais,
        @w_telefono          = nc_telefono,
        @w_actividad_ec      = nc_actividad_ec,
        @w_tiempo_activida   = nc_tiempo_actividad,
        @w_tiempo_dom_neg    = nc_tiempo_dom_neg,
        @w_emprendedor       = nc_emprendedor,
        @w_recurso           = nc_recurso,
        @w_ingreso_mensual   = nc_ingreso_mensual,
        @w_tipo_local        = nc_tipo_local,
        @w_estado_reg        = nc_estado_reg,
        @w_destino_credito   = nc_destino_credito, --agregar las columnas nuevas
        @w_sector            = nc_sector,
        @w_subsector         = nc_subsector,
        @w_misma_dir         = nc_misma_dir,
        @w_nro_interno       = nc_nro_interno,  
        @w_referencia_neg    = nc_referencia_neg,
        @w_rfc_neg           = nc_rfc_neg,
        @w_dias_neg          = nc_dias_neg,
        @w_hora_ini          = nc_hora_ini,
        @w_hora_fin          = nc_hora_fin,
        @w_atiende           = nc_atiende,
        @w_empleados         = nc_empleados,
        @w_actividad_neg     = nc_actividad_neg
        from cl_negocio_cliente
        where nc_codigo = @i_codigo
  
  if @@rowcount = 0
  begin
    select @w_num_error =  1720285 --NO EXISTE NEGOCIO DEL CLIENTE
    goto errores
  end 
    --agregar las columnas nuevas
    insert into ts_negocio_cliente(
    ts_secuencial,      ts_codigo,          ts_ente,           ts_nombre,             ts_giro,                ts_fecha_apertura,
    ts_calle,           ts_nro,             ts_colonia,        ts_localidad,          ts_municipio,           ts_estado,
    ts_codpostal,       ts_pais,            ts_telefono,       ts_actividad_ec,       ts_tiempo_actividad,    ts_tiempo_dom_neg,
    ts_emprendedor,     ts_recurso,         ts_ingreso_mensual,ts_tipo_local,         ts_usuario,             ts_oficina,
    ts_fecha_proceso,   ts_operacion,       ts_estado_reg,     ts_destino_credito,
    ts_sector,          ts_subsector,       ts_misma_dir,      ts_nro_interno,        ts_referencia_neg,      ts_rfc_neg, 
    ts_dias_neg,        ts_hora_ini,        ts_hora_fin,       ts_atiende,            ts_empleados           ,ts_actividad_neg,
    ts_nc_num_id,       ts_nc_tipo_id)
    values (
    @s_sesn,            @w_codigo,          @w_ente,            @w_nombre,            @w_giro,                @w_fecha_apertura,     
    @w_calle,           @w_nro,             @w_colonia,         @w_localidad,         @w_municipio,           @w_estado,
    @w_codpostal,       @w_pais,            @w_telefono,        @w_actividad_ec,      @w_tiempo_activida,     @w_tiempo_dom_neg,
    @w_emprendedor,     @w_recurso,         @w_ingreso_mensual, @w_tipo_local,        @s_user,                @s_ofi,
    @s_date,            'A',                @w_estado_reg,      @w_destino_credito, 
    @w_sector,          @w_subsector,       @w_misma_dir,       @w_nro_interno,       @w_referencia_neg,      @w_rfc_neg, 
    @w_dias_neg,        @w_hora_ini,        @w_hora_fin,        @w_atiende,           @w_empleados           ,@i_actividad_neg,
    @i_nc_num_id,       @i_nc_tipo_id)       --A = Registro actual
    if @@error <> 0
      begin   
         select @w_num_error = 1720049 --ERROR AL REGISTRAR TRANSACCION DE SERVICIO
         goto errores
      end
    select @w_estado_reg = 'E' 
  
    update cl_negocio_cliente
    set nc_estado_reg = 'E'     --estado eliminado
    where nc_codigo = @i_codigo
  
    if @@error <> 0
    begin
     select @w_num_error = 1720287 --ERROR AL ELIMINAR NEGOCIO DEL CLIENTE!
     goto errores
    end
    --agregar las columnas nuevas
    insert into ts_negocio_cliente(
    ts_secuencial,      ts_codigo,          ts_ente,           ts_nombre,             ts_giro,                ts_fecha_apertura,
    ts_calle,           ts_nro,             ts_colonia,        ts_localidad,          ts_municipio,           ts_estado,
    ts_codpostal,       ts_pais,            ts_telefono,       ts_actividad_ec,       ts_tiempo_actividad,    ts_tiempo_dom_neg,
    ts_emprendedor,     ts_recurso,         ts_ingreso_mensual,ts_tipo_local,         ts_usuario,             ts_oficina,
    ts_fecha_proceso,   ts_operacion,       ts_estado_reg,     ts_destino_credito,
    ts_sector,          ts_subsector,       ts_misma_dir,      ts_nro_interno,        ts_referencia_neg,      ts_rfc_neg, 
    ts_dias_neg,        ts_hora_ini,        ts_hora_fin,       ts_atiende,            ts_empleados           ,ts_actividad_neg,
    ts_nc_num_id,       ts_nc_tipo_id)
    values (
    @s_sesn,            @w_codigo,          @w_ente,            @w_nombre,            @w_giro,                @w_fecha_apertura,     
    @w_calle,           @w_nro,             @w_colonia,         @w_localidad,         @w_municipio,           @i_estado,
    @w_codpostal,       @w_pais,            @w_telefono,        @w_actividad_ec,      @w_tiempo_activida,     @w_tiempo_dom_neg,
    @w_emprendedor,     @w_recurso,         @w_ingreso_mensual, @w_tipo_local,        @s_user,                @s_ofi,
    @s_date,            'D',                @w_estado_reg,      @w_destino_credito,
    @w_sector,          @w_subsector,       @w_misma_dir,       @w_nro_interno,       @w_referencia_neg,      @w_rfc_neg, 
    @w_dias_neg,        @w_hora_ini,        @w_hora_fin,        @w_atiende,           @w_empleados           ,@i_actividad_neg,
    @i_nc_num_id,       @i_nc_tipo_id)       --D = Registro modificado
    if @@error <> 0
      begin   
         select @w_num_error = 1720049 --ERROR AL REGISTRAR TRANSACCION DE SERVICIO
         goto errores
      end

  
  /**Antes de terminar la operacion elimina de la tabla de de direcciones la dirección dada de alta en el negocio**/
  select @w_direccion_dml= isnull(di_direccion,0) from cobis..cl_direccion where di_negocio =  @i_codigo  and di_ente=@i_ente
  
  if @w_direccion_dml>0
    begin
    EXEC [cobis].[dbo].[sp_direccion_dml]
         @s_ssn                =@s_ssn,
         @s_user               =@s_user,
         @s_sesn               =@s_sesn,
         @s_culture            =@s_culture,
         @s_term               =@s_term,
         @s_date               =@s_date,
         @s_srv                =@s_srv,
         @s_lsrv               =@s_lsrv,
         @s_ofi                =@s_ofi,
         @s_rol                =@s_rol,
         @s_org_err            =@s_org_err,
         @s_error              =@s_error,
         @s_sev                =@s_sev,
         @s_msg                =@s_msg,
         @s_org                =@s_org,
         @t_debug              =@t_debug,
         @t_file               =@t_file,
         @t_from               =@t_from,
         @t_trn                =172021,
         @i_operacion          =N'N',            
         @i_ente               =@i_ente,
         @i_direccion          =@w_direccion_dml,
         @i_desasociar_dir     = 'S',
         @i_negocio            = @i_codigo
        
        if @@error <> 0
        begin
            ROLLBACK TRAN
        end
    end
    commit tran
  
goto fin
end

if @i_operacion = 'S'
begin

       select TOP 1 @w_direccion = di_direccion from cobis..cl_direccion 
      where di_ente = @i_ente
      AND di_tipo = 'AE'
    and di_vigencia = 'S'
      
      select TOP 1 @w_telefono_aux = te_valor, @w_telefono_id  = te_secuencial
      from cobis..cl_telefono where te_ente = @i_ente 
    AND te_direccion = @w_direccion
    AND te_tipo_telefono = 'D'
       
    IF(@w_telefono_aux IS NOT NULL)

      begin
    if( len(@w_telefono_aux)>9)
    begin
    select @w_len = len(@w_telefono_aux)
      select @w_len = @w_len - 9      
      
        select @w_len = len(@w_telefono_aux)
      select @w_len = @w_len - 9  
        select @w_cod_area = substring(@w_telefono_aux,0,@w_len)
      
      select @w_telefono_aux = RIGHT(@w_telefono_aux, 10)
      end
    end
    --set rowcount 20
    select 
        'codCliente'         =   nc_ente,
        'NomCliente'         =   en_nombre,
            'nombre'             =   nc_nombre,
        'Num Ident'          =   nc_num_id,
        'Tipo Ident'         =   nc_tipo_id,     
        'giro'               =   nc_giro,
        'fechaApertura'      =   convert(char(10), nc_fecha_apertura, 103),
        'despDestinoCred'    =   null,
        'calle'              =   nc_calle,
        'nro'                =   nc_nro,
        'colonia'            =   nc_colonia,
        'localidad'          =   nc_localidad,
        'municipio'          =   nc_municipio,     
        'codEstado'          =   nc_estado,
        'desEstado'          =   null,
        'codPostal'          =   nc_codpostal,
        'codPais'            =   nc_pais,
        'desPais'            =   null,
        'telefono'           =   isnull(nc_telefono, @w_telefono_aux),
        'codActividad'       =   nc_actividad_ec,
        'desActividad'       =   null,
        'timeActivi'         =   nc_tiempo_actividad,
        'timeDomNeg'         =   nc_tiempo_dom_neg,
        'emprendedor'        =   nc_emprendedor,
        'recurso'            =   nc_recurso,
        'ingMensual'         =   nc_ingreso_mensual,
        'tipoLocal'          =   nc_tipo_local,
        'codigo'             =   nc_codigo,
        'destinoCredito'     =   nc_destino_credito,
        'codTelefono'        =   @w_telefono_id, --agregar las columnas nuevas
        'sector'             =   nc_sector,
        'subsector'          =   nc_subsector,  
        'misma_dir'          =   nc_misma_dir,
        'nro_interno'        =   nc_nro_interno,  
        'referencia_neg'     =   nc_referencia_neg, 
        'rfc_neg'            =   nc_rfc_neg,
        'dias_neg'           =   nc_dias_neg, 
        'hora_ini'           =   nc_hora_ini, 
        'hora_fin'           =   nc_hora_fin, 
        'atiende'            =   nc_atiende,  
        'empleados'          =   nc_empleados,
        'DESC_LOCALIDAD'     =   lo.lo_desc_localidad,
        'LOCALIDAD_COBIS'    =   lo.lo_localidad,
        'actividadNegocio'   =   nc_actividad_neg,  -- a que se dedica el negocio  04/10/2019 RIGG
        'sector_region'      =   nc_sector_region,
        'zona'               =   nc_zona,
        'id direccion'       =   cd.di_direccion
    from cl_negocio_cliente n
      inner join cl_direccion cd on (cd.di_ente = nc_ente)
    inner join cl_ente on (en_ente = nc_ente)
    left join cobis..cl_localidad lo
              on     n.nc_localidad = lo.lo_localidad and n.nc_municipio = lo.lo_ciudad
    where nc_ente =  @i_ente
    and   nc_codigo > isnull(@i_codigo, 0)
    and   nc_codigo = cd.di_negocio
    and   cd.di_tipo in ('AE','RE')
    and   nc_estado_reg = 'V'
    goto fin
end

if @i_operacion = 'Q'
begin
    select  
        'codCliente'         = nc_ente,
        'NomCliente'         = en_nombre,
        'nombre'             = nc_nombre,
        'giro'               = nc_giro,
        'fechaApertura'      = convert(char(10), nc_fecha_apertura, 103),
        'despDestinoCred'    = null,
        'calle'              = nc_calle,
        'nro'                = nc_nro,
        'colonia'            = nc_colonia,
        'localidad'          = nc_localidad,
        'municipio'          = nc_municipio,     
        'codEstado'          = nc_estado,
        'desEstado'          = null,
        'codPostal'          = nc_codpostal,
        'codPais'            = nc_pais,
        'desPais'            = null,
        'telefono'           = nc_telefono,
        'codActividad'       = nc_actividad_ec,
        'desActividad'       = null,
        'timeActivi'         = nc_tiempo_actividad,
        'timeDomNeg'         = nc_tiempo_dom_neg,
        'emprendedor'        = nc_emprendedor,
        'recurso'            = nc_recurso,
        'ingMensual'         = nc_ingreso_mensual,
        'tipoLocal'          = nc_tipo_local,
        'codigo'             = nc_codigo,
        'destinoCredito'     = nc_destino_credito, --agregar las columnas nuevas
    'sector'       = nc_sector,
    'subsector'      = nc_subsector,  
    'misma_dir'      = nc_misma_dir,
    'nro_interno'      = nc_nro_interno,  
    'referencia_neg'   = nc_referencia_neg, 
    'rfc_neg'        = nc_rfc_neg,  
    'dias_neg'       = nc_dias_neg, 
    'hora_ini'       = nc_hora_ini,   
    'hora_fin'       = nc_hora_fin,   
    'atiende'      = nc_atiende,    
    'empleados'      = nc_empleados,
    'DESC_LOCALIDAD'    = lo.lo_desc_localidad,
    'LOCALIDAD_COBIS'    = lo.lo_localidad,
    'actividadNegocio'       = nc_actividad_neg  -- a que se dedica el negocio  04/10/2019 RIGG
    from cl_negocio_cliente n
    inner join cl_ente on (en_ente = nc_ente)
    left join cobis..cl_localidad lo
                                on     n.nc_localidad = lo.lo_localidad and n.nc_municipio = lo.lo_ciudad
    where nc_codigo = @i_codigo
    and nc_ente = @i_ente
    and   nc_estado_reg = 'V'
goto fin
END

if @i_operacion = 'H'
begin
    --POV Consulta Mismo que domicilio
     select
            'pais'              = di_pais, 
            'provincia'         = di_provincia, 
            'ciudad'            = di_ciudad, 
            'parroquia'         = di_parroquia, 
            'calle'             = di_calle, 
            'no_calle'          = di_casa, 
            'cod_posta'         = di_codpostal,
            'DESC_LOCALIDAD'    = lo.lo_desc_localidad,
            'LOCALIDAD_COBIS'   = lo.lo_localidad,
            'NRO_INTERNO'       = di_edificio,
            'REFERENCIA'        = di_descripcion,
            'zona'              = di_zona,
            'sector'            = di_sector          
     from cl_direccion di
   left join cobis..cl_localidad lo  on di.di_localidad = lo.lo_localidad and di.di_ciudad = lo.lo_ciudad
     where di_ente = @i_ente 
     AND di_tipo = 'RE'
   and di_vigencia = 'S'
      
     if @@rowcount=0
       begin
        select @w_num_error = 1720288 --Transaccion no permitida
       goto errores
     end
goto fin
end


if @i_operacion = 'C'
begin
    --Consulta negocios del cliente
  
  select nc_codigo, nc_nombre from cobis..cl_negocio_cliente where nc_ente = @i_ente
   
     if @@rowcount=0
       begin
      select @w_num_error = 1720289 --No existe registro
       goto errores
     end
goto fin
end

--Control errores
errores:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_num_error
   return @w_num_error
fin:

   select @w_sincroniza = pa_char
   from cobis..cl_parametro
   where pa_producto = 'CLI'
   and pa_nemonico = 'HASIAU'
   
   select @w_ofi_app = pa_smallint 
   from cobis.dbo.cl_parametro cp 
   where cp.pa_nemonico = 'OFIAPP'
   and cp.pa_producto = 'CRE'
   
   --Proceso de sincronizacion Clientes
   if @i_operacion in ('I','U','D') and @i_ente is not null and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
   begin
      exec @w_num_error = cob_sincroniza..sp_sinc_arch_json
         @i_opcion     = 'I',
         @i_cliente    = @i_ente,
         @t_debug      = @t_debug
         
      if @w_num_error <> 0
      begin
         goto errores
      end
   end
   return 0


GO

