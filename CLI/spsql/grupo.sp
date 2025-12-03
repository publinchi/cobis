/************************************************************************/
/*      Archivo:                sp_grupo.sp                             */
/*      Stored procedure:       sp_grupo                                */
/*      Base de datos:          cob_pac                                 */
/*      Producto:               Clientes                                */
/*      Disenado por:           JMEG                                    */
/*      Fecha de escritura:     30-Abril-19                             */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este programa procesa las transacciones del stored procedure    */
/*      Insercion de grupo                                              */
/*      Actualizacion de grupo                                          */
/* **********************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA        AUTOR      RAZON                                       */
/*  30/04/19     JMEG       Emision Inicial                             */
/*  18/05/20     MBA        Cambio nombre y compilacion BDD cobis       */
/*  17/06/20     FSAP       Estandarizacion de Clientes                 */
/*  07/01/21     MGB        Cambio variable hora_reunion a varchar      */
/*  23/03/21     COB        Cambio en validacion de mujeres             */
/*  07/05/21     COB        Elimina validacion del representante cliente*/
/*  14/07/21     ACU        Comenta validaciones de parentesco y conyuge*/
/*                          en operaciones I,U                          */
/*  07/05/21     COB        Se corrige la consulta de todos los grupos  */
/*  27/09/21     BDU        Se agrega consulta para servicio REST       */
/*  14/04/23     BDU        Se elimina validacion de oficina movil      */
/*  26/06/23     EBA        Se obtiene al valor del catalogo            */
/*                          cl_atencion_clientes para guardar la hora   */
/*                          del grupo                                   */
/*  24/07/23     BDU        Se deserta miembros en la cancelacion del   */
/*                          grupo  R211803                              */
/*  06/09/23     PJA        Ajuste validacion miembros B896538-R214742  */
/*  09/09/23     BDU        R214440-Sincronizacion automatica           */
/*  03/10/23     EBA        Mejora control oficiales   S911708-R216187  */
/*  12/10/23     BDU        Ajuste validacion oficial R217344           */
/*  09/11/23     BDU        Se optimiza operacion F                     */
/*  01/12/23     BDU        R220651-Validacion operaciones vigentes     */ 
/*                          presidentes                                 */
/*  18/12/23     BDU        R221684-Cambio registro TS                  */
/*  22/01/24     BDU        R224055-Validar oficina app                 */
/************************************************************************/

use cobis
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select * from sysobjects where name = 'sp_grupo')
   drop proc sp_grupo
go

create proc sp_grupo (
    @s_ssn                  int             = null,
    @s_user                 login           = null,
    @s_term                 varchar(30)     = null,
    @s_date                 datetime        = null,
    @s_srv                  varchar(30)     = null,
    @s_lsrv                 varchar(30)     = null,
    @s_ofi                  smallint        = null,
    @s_rol                  smallint        = NULL,
    @s_org_err              char(1)         = NULL,
    @s_error                int             = NULL,
    @s_sev                  tinyint         = NULL,
    @s_msg                  descripcion     = NULL,
    @s_org                  char(1)         = NULL,
    @t_show_version         bit             = 0,    -- Mostrar la version del programa
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  int             = null,
    @i_operacion            char(1),                -- Opcion con que se ejecuta el programa
    @i_modo                 tinyint         = null, -- Modo de busqueda
    @i_tipo                 char(2)         = null, -- Tipo de consulta
    @i_filial               tinyint         = null, -- Codigo de la filial
    @i_oficina              smallint        = null, -- Codigo de la oficina    
    @i_ente                 int             = null, -- Codigo del ente que forma parte del grupo
    @i_grupo                int             = null, -- Codigo del grupo
    @i_nombre               descripcion     = null, -- Nombre del grupo economico
    @i_representante        int             = null, -- Codigo del representante legal
    @i_compania             int             = null, -- Codigo de la compania
    @i_oficial              int             = null, -- Codigo del oficial encargado del grupo económico
    @i_fecha_registro       datetime        = null, -- Fecha de Registro del grupo
    @i_fecha_modificacion   datetime        = null, -- Fecha de Modificación del grupo 
    @i_ruc                  numero          = null, -- Numero del documento de identificacion
    @i_vinculacion          char(1)         = null, -- Codigo de vinculacion del representante al grupo
    @i_tipo_vinculacion     catalogo        = null, -- Codigo del tipo de vinculacion del representante al grupo
    @i_max_riesgo           money           = null,
    @i_riesgo               money           = null,
    @i_usuario              login           = null,
    @i_reservado            money           = null,
    @i_tipo_grupo           catalogo        = null,
    @i_estado               catalogo        = null, -- Estado del Grupo Economico
    @i_dir_reunion          varchar(125)    = null, -- Direccion de la reunion del grupo
    @i_dia_reunion          catalogo        = null, -- Dia de reunion del grupo
    @i_hora_reunion         varchar(10)     = null, -- Hora de la reunion de del grupo
    @i_comportamiento_pago  varchar(10)     = null, -- 
    @i_num_ciclo            int             = null, --
    @i_gr_tipo              char(1)         = null, -- campo gr_tipo en grupo   
    @i_gr_cta_grupal        VARCHAR(30)     = null, --campo  cuenta grupal
    @i_gr_sucursal          int             = null,
    @i_gr_titular1          int             = null, --campo cliente Titular1
    @i_gr_titular2          int             = NULL, --campo cliente Titular2
    @i_gr_lugar_reunion     char(10)        = null, --campo gr_lugar de Reunion
    @i_gr_tiene_ctagr       char(1)         = null, --campo tiene cuenta grupal
    @i_gr_tiene_ctain       char(1)         = null, --campo tiene cuenta individual
    @i_gr_gar_liquida       char(1)         = null, --campo tiene garatia liquida
    @i_desde_fe             char(1)         = 'N', --Indica que viene desde front end
    @i_rol                  catalogo        = null, -- rol para la consulta
    @o_actualiza_movil      char(1)         = null out,
    @o_grupo                int             = null out
                   
)
as
declare @w_siguiente            int,
        @w_return               int,
        @w_ente                 int,
        @w_num_cl_gr            int,
        @w_contador             int,
        @w_sp_name              varchar(32),
        @w_sp_msg               varchar(132),
        @w_error                int,    
        @w_grupo                int,
        @w_nombre               descripcion,
        @w_representante        int,
        @w_compania             int,
        @w_oficial              int,
        @w_fecha_registro       datetime,
        @w_fecha_modificacion   datetime,
        @w_ruc                  numero,
        @w_vinculacion          char(1),
        @w_tipo_vinculacion     catalogo,
        @w_max_riesgo           money,
        @w_riesgo               money,
        @w_usuario              login,
        @w_reservado            money,
        @w_tipo_grupo           catalogo,
        @w_estado               catalogo,
        @w_dir_reunion          varchar(125),
        @w_dia_reunion          catalogo,
        @w_hora_catalogo        varchar(64),
        @w_hora_reunion         datetime,
        @w_comportamiento_pago  varchar(10),
        @w_num_ciclo            int,
        @w_gr_tipo              char(1),
        @w_gr_cta_grupal        VARCHAR(30),
        @w_gr_sucursal          VARCHAR(30),
        @w_gr_titular1          int,
        @w_gr_titular2          int,
        @w_gr_lugar_reunion     char(10),      
        @w_gr_tiene_ctagr       char(1),      
        @w_gr_tiene_ctain       char(1),            
        @w_gr_gar_liquida       char(1),
        @w_ofi                  smallint,       
        @v_grupo                int,
        @v_nombre               descripcion,
        @v_representante        int,
        @v_compania             int,
        @v_oficial              int,
        @v_fecha_registro       datetime,
        @v_fecha_modificacion   datetime,
        @v_ruc                  numero,
        @v_vinculacion          char(1),
        @v_tipo_vinculacion     catalogo,
        @v_max_riesgo           money,
        @v_riesgo               money,
        @v_usuario              login,
        @v_reservado            money,
        @v_tipo_grupo           catalogo,
        @v_estado               catalogo,
        @v_dir_reunion          varchar(125),
        @v_dia_reunion          catalogo,
        @v_hora_reunion         datetime,
        @v_comportamiento_pago  varchar(10),
        @v_num_ciclo            int,
        @v_gr_tipo              char(1),
        @v_gr_cta_grupal        VARCHAR(30),
        @v_gr_sucursal          int,
        @v_gr_titular1          int,
        @v_gr_titular2          int,
        @v_gr_lugar_reunion     char(10),      
        @v_gr_tiene_ctagr       char(1),      
        @v_gr_tiene_ctain       char(1),
        @v_gr_gar_liquida       char(1),
        --validaciones numero de integrantes PXSG--
        @w_integrantes           INT,
        --validaciones numero de PXSG --
        @w_num_integrantes       INT ,
        @w_sum_parentesco        INT,
        @w_porcentaje            INT,
        @w_valor_nuevo           INT,
        --validacion de mujeres de PXSG--
        @w_num_sexo_feme         INT,
        --validaciones para conyuge PXSG--
        @w_cliente_gr            INT,
        --validaciones para tesorero y presidente--
        @numIntegrantesGrupo     INT,
        --parametros para validaciones de integrantes--
        @w_param_max_inte        INT,
        @w_param_min_inte        INT,
        @w_param_porc_parentesco FLOAT,
        @w_param_rel_cony        INT ,
        @w_param_porc_mujeres    FLOAT,
        --validacion para emprendedores-- 
        @w_sum_enprender         INT,
        @w_param_porc_emp        FLOAT,
        @w_msg                   varchar (200),
        @w_actualiza             varchar(1), --MTA
        @w_reunion               varchar(125),
            @w_actualiza_movil       varchar(1) = 'S',
        @w_parm_ofi_movil        smallint,
        @w_parm_etap_ingreso     varchar(30),
        @w_parm_etap_eliminar    varchar(30),
        @w_parm_etap_aprobacion  varchar(30),
        -- Variables para el caso CLI-S274230-TECGRP Traspaso de cartera: Actualización de oficial.
        @w_es_oficial             char(1) = 'N', -- Bandera para saber si el @i_oficial es igual al @w_oficial del grupo
        @w_cg_ente                int,
        @w_cg_grupo               int,
        @w_cg_usuario             login,
        @w_cg_oficial             int,
        @w_cg_fecha_asociacion    datetime,
        @w_cg_rol                 catalogo,
        @w_cg_estado              catalogo,
        @w_cg_calif_interna       catalogo,
        @w_cg_fecha_desasociacion datetime,
        @w_cg_ahorro_voluntario   money,
        @w_cg_lugar_reunion       varchar(10),
        -- Variables para el historico
        @v_cg_ente                int,
        @v_cg_grupo               int,
        @v_cg_usuario             login,
        @v_cg_oficial             int,
        @v_cg_fecha_asociacion    datetime,
        @v_cg_rol                 catalogo,
        @v_cg_estado              catalogo,
        @v_cg_calif_interna       catalogo,
        @v_cg_fecha_desasociacion datetime,
        @v_cg_ahorro_voluntario   money,
        @v_cg_lugar_reunion       varchar(10),
        @w_ente_aux               int,
        --R211803 Desertar a los miembros si el grupo se cancela
        @w_min_miembro            int,
        @w_ssn                    int,
        --R216187 Validar que el oficial sea el mismo que del grupo
        @w_controlar_oficial      char(10),
        @w_oficial_ente           int,
        @w_oficial_grupo          int,
        -- R214440-Sincronizacion automatica
        @w_sincroniza             char(1),
        @w_cod_presi              int,
        @w_ofi_app                smallint


--------------------------------------------------------------------------------------
select @w_sp_name   = 'sp_grupo',
       @w_actualiza = 'S'--MTA
   
---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

select @w_parm_ofi_movil = pa_smallint 
  from cobis..cl_parametro 
 where pa_producto = 'CRE'
   and pa_nemonico = 'OFIAPP'
   
select @w_parm_etap_ingreso = pa_char 
  from cobis..cl_parametro 
 where pa_nemonico = 'ETINGR' 
   and pa_producto = 'CRE'

select @w_parm_etap_eliminar = pa_char 
  from cobis..cl_parametro 
 where pa_nemonico = 'ETELIM' 
   and pa_producto = 'CRE'

select @w_parm_etap_aprobacion = pa_char 
  from cobis..cl_parametro 
 where pa_nemonico = 'ETAPRO' 
   and pa_producto = 'CRE'
   
select @w_controlar_oficial = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'CTROFG'

--EVALUACION DEL TIPO DE TRANSACCION 
if (@t_trn <> 172037 and @i_operacion = 'I') or
   (@t_trn <> 172038 and @i_operacion = 'U') or
   (@t_trn <> 172036 and @i_operacion = 'M') 
begin 
   /* Tipo de transaccion no corresponde */ 
   exec cobis..sp_cerror 
        @t_debug = @t_debug, 
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1720075
   return 1
end

-- Insert -- 
if @i_operacion = 'I'
begin
    if @t_trn = 172037
    begin
    -- Viene el front end como - 31/12/1969 19:00:00 por eso se cambia
    select @i_fecha_modificacion = getdate()
    select @i_fecha_registro = @i_fecha_modificacion
    
    -- Verificar que otro grupo no tenga el mismo nombre --
   /*  if exists (select 1 from cobis..cl_grupo where gr_nombre = @i_nombre)
    begin
        select @w_error = 208901 -- YA EXISTE EL NOMBRE DEL GRUPO
        goto ERROR
    end
   */
    -- Verificar que exista el oficial --
    if not exists (select 1
                     from cobis..cc_oficial 
                    where oc_oficial = @i_oficial) 
                      and @i_oficial != null
    begin
        select @w_error = 1720161 -- No existe oficial --
        goto ERROR
    end

    --Verifica si existe el miembro en otros grupos
    if exists ( select 1 from cobis..cl_grupo, cobis..cl_cliente_grupo ccg  
                where gr_grupo = ccg.cg_grupo
                    and gr_tipo = @i_gr_tipo
                    and cg_ente = @i_representante 
                    and (cg_fecha_desasociacion is null and cg_rol != 'D') --desertor
                    )
    begin
        select @w_error = 1720212 -- YA EXISTE EL MIEMBRO EN OTRO GRUPO --
        goto ERROR
    end
    --verifica que no tenga tramites pendientes en otro grupo
   if exists (select (1) from cob_cartera..ca_operacion, cob_cartera..ca_estado, cob_credito..cr_tramite_grupal
              where op_estado  = es_codigo
              and es_procesa   = 'S'
              and op_cliente   = @i_representante 
              and op_operacion = tg_operacion)
   begin
      select @w_error = 1720611 --TIENE OPERACIONES PENDIENTES CON OTRO GRUPO
      goto ERROR
   end
   
   /*VALIDAR QUE EL GRUPO Y EL REPRESENTANTE PERTENEZCAN AL MISMO OFICIAL*/
   if @w_controlar_oficial = 'S' and @i_representante is not null --Grupos en app puede crearse sin presidente
   begin
      select @w_oficial_ente = en_oficial
        from cobis..cl_ente
       where en_ente = @i_representante
      
      if @i_oficial <> @w_oficial_ente
      begin
         select @w_error = 1720650
         goto ERROR
      end     
   end
   
    -- Obtener un secuencial para el nuevo grupo --
    exec cobis..sp_cseqnos
    @t_debug        = @t_debug,
    @t_file         = @t_file,
    @t_from         = @t_from,
    @i_tabla        = 'cl_grupo',
    @o_siguiente    = @w_siguiente out
    -- Error con el secuencial
    if @w_siguiente = NULL
    begin
        select @w_error = 2101007 -- NO EXISTE TABLA EN TABLA DE SECUENCIALES
        goto ERROR           
    end
    
   -- seteo hora reunion
   if(@i_hora_reunion != null)
   begin
      select @w_hora_catalogo = trim(valor) from cl_catalogo cc 
                                           where tabla in (select codigo from cl_tabla ct 
                                                                        where tabla = 'cl_atencion_clientes')
                                             and codigo = @i_hora_reunion  
      select @w_hora_reunion = CONVERT(datetime, CONCAT('1900-01-01 ',@w_hora_catalogo))
   end
   
   -- insertar los datos de grupo --
    insert into cobis..cl_grupo (gr_grupo,       gr_nombre,          gr_representante,     gr_compania,    --1
                                 gr_oficial,     gr_fecha_registro,  gr_fecha_modificacion,gr_ruc,         --2  
                                 gr_vinculacion, gr_tipo_vinculacion,gr_max_riesgo,        gr_riesgo,      --3
                                 gr_usuario,     gr_reservado,       gr_tipo_grupo,        gr_estado,      --4
                                 gr_dir_reunion, gr_dia_reunion,     gr_hora_reunion,      gr_comportamiento_pago,  --5 
                                 gr_num_ciclo,   gr_tipo,            gr_cta_grupal,        gr_sucursal,
                                 gr_titular1,    gr_titular2,        gr_lugar_reunion,     gr_tiene_ctagr,
                                 gr_tiene_ctain,     gr_gar_liquida                                                     --6
                                 )
    values                       (@w_siguiente,   @i_nombre+' ' + CONVERT(varchar(10), @w_siguiente) , @i_representante,@i_compania,    --1
                                  @i_oficial,     @i_fecha_registro,  @i_fecha_modificacion,@i_ruc,         --2
                                  @i_vinculacion, @i_tipo_vinculacion,@i_max_riesgo,        @i_riesgo,      --3      
                                  @i_usuario,     @i_reservado,       @i_tipo_grupo,        @i_estado,      --4
                                  @i_dir_reunion, @i_dia_reunion,     @w_hora_reunion,      @i_comportamiento_pago,  --5 
                                  @i_num_ciclo,   @i_gr_tipo,         @i_gr_cta_grupal,     @i_gr_sucursal,
                                  @i_gr_titular1, @i_gr_titular2,     @i_gr_lugar_reunion,  @i_gr_tiene_ctagr,
                                  @i_gr_tiene_ctain, isnull(@i_gr_gar_liquida,'S')                                                  --6
                                 )                              
    -- si no se puede insertar, error --
    if @@error != 0
    begin
        select @w_error = 1720214 -- ERROR EN CREACION DE GRUPO
        goto ERROR 
    end
  --actualizo el lugar de reunion cuando lugar de reunion es igual OT
    if ( @i_gr_lugar_reunion ='OT')
    begin
    UPDATE cobis..cl_cliente_grupo
     SET cg_lugar_reunion = NULL
    where cg_grupo = @i_grupo
    end

    -- Transaccion servicio - cl_grupo --
    insert into cobis..ts_grupo  (secuencial,    tipo_transaccion,    clase,                 fecha,    --1
                                  terminal,      srv,                 lsrv,                            --2
                                  grupo,         nombre,              representante,         compania, --3
                                  oficial,       fecha_registro,      fecha_modificacion,    ruc,      --4                      
                                  vinculacion,   tipo_vinculacion,    max_riesgo,            riesgo,   --5                      
                                  usuario,       reservado,           tipo_grupo,            estado,   --6                      
                                  dir_reunion,   dia_reunion,         hora_reunion,          comportamiento_pago,--7                      
                                  num_ciclo,     gar_liquida)
    values                       (@s_ssn,        172037,              'N',                   @s_date,   --1
                                  @s_term,       @s_srv,              @s_lsrv,                           --2
                                  @w_siguiente,  @i_nombre+' ' + CONVERT(varchar(10), @w_siguiente) ,           @i_representante,      @i_compania,--3
                                  @i_oficial,    @i_fecha_registro,   @i_fecha_modificacion, @i_ruc,     --4
                                  @i_vinculacion,@i_tipo_vinculacion, @i_max_riesgo,         @i_riesgo,  --5
                                  @i_usuario,    @i_reservado,        @i_tipo_grupo,         @i_estado,  --6
                                  @i_dir_reunion,@i_dia_reunion,      @w_hora_reunion,       @i_comportamiento_pago,--7
                                  @i_num_ciclo,  isnull(@i_gr_gar_liquida,'S')                                                  --8
                                 )
    -- Si no se puede insertar transaccion de servicio, error --
    if @@error != 0
    begin
        select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
        goto ERROR
    end
    
    select @o_grupo = @w_siguiente
    select @o_grupo
            
    --INICIO DE VALIDACIONES--
    --nuevas validaciones maximo 40--
  select @numIntegrantesGrupo=count(cg_ente) from cobis..cl_cliente_grupo where cg_grupo=@i_grupo and cg_estado = 'V'
   if(@numIntegrantesGrupo<>0)
   begin
    select @w_param_max_inte =pa_int from cobis..cl_parametro where pa_nemonico='MAXIGR' and pa_producto = 'CLI'
    select @w_param_min_inte =pa_int from cobis..cl_parametro where pa_nemonico='MINIGR' and pa_producto = 'CLI'
    select @w_integrantes  = count(cg_ente) from cobis..cl_cliente_grupo
    where cg_grupo = @i_grupo
    and cg_estado = 'V'
 
    if @w_integrantes  > @w_param_max_inte or  @w_integrantes < @w_param_min_inte
     begin
       select @w_error = 1720215 -- validación número de integrantes
        goto ERROR
     End 
     
     
     --validacion parentesco--
     --se comenta validacion de parentesco hasta definirla con el banco - ACU
    /*
    select @w_param_porc_parentesco=pa_float from cobis..cl_parametro where pa_nemonico='PPGRU'  and pa_producto = 'CRE'
    select distinct @w_num_integrantes = count(cg_ente) 
    from cobis..cl_cliente_grupo 
    where cg_grupo = @i_grupo
    and cg_estado = 'V'
    select @w_sum_parentesco=count(DISTINCT in_ente_i) from cobis..cl_instancia
    where  in_relacion IN (select B.codigo from cobis..cl_tabla A, cobis..cl_catalogo B 
             where A.tabla in ('cl_parentesco_1er','cl_parentesco_2er') and A.codigo= B.tabla)
    and in_ente_i IN (select cg_ente from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_estado = 'V')
    and in_ente_d IN (select cg_ente from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_estado = 'V')
    if(@w_num_integrantes <>0)
    begin
    select @w_porcentaje = ((@w_sum_parentesco * 100)/@w_num_integrantes)

    select @w_valor_nuevo = @w_porcentaje
    end
    if @w_valor_nuevo > @w_param_porc_parentesco    -- parametro 40 porcentaje de parentesco en grupos
    begin
      select @w_error = 1720216  --Error en Porcentaje de Parentesco
      goto ERROR
    end
    */
    
    select @w_reunion = gr_dir_reunion from cobis..cl_grupo where gr_grupo = @i_grupo
    
    if ((@w_reunion IS NULL) or (@w_reunion = ' '))    -- Lugar de reunion
    begin
      select @w_error = 1720217  --POR FAVOR INGRESE EL LUGAR DE REUNION
      goto ERROR
    end
    
    --validacion de credito--
  /* if exists (select 1 from cobis..cl_cliente_grupo, cob_cartera..ca_operacion
   where cg_grupo = @i_grupo
   and cg_estado = 'V'
   and cg_ente = op_cliente
   and op_estado NOT IN (0,99,3))
   begin*/
  /*    select @w_error = 208918  --validacion de credito
      goto ERROR
   end
   */
    --Validación conyuge--
  /*
  select @w_param_rel_cony=pa_int from cobis..cl_parametro where pa_nemonico='RCONY'  and pa_producto = 'CRE' 
  
  select @w_cliente_gr= 0
  select top 1   @w_cliente_gr=cg_ente
  from cobis..cl_cliente_grupo
  where cg_grupo =@i_grupo
  and cg_estado = 'V'
  and cg_ente  > @w_cliente_gr 
  order by cg_ente ASC
  WHILE @@rowcount > 0
  begin
  if exists (select 1
  from cobis..cl_instancia
  where in_ente_i = @w_cliente_gr
  and in_relacion =@w_param_rel_cony -- parametro 'RCONY'
  and in_ente_d in (select cg_ente from cobis..cl_cliente_grupo where cg_grupo =@i_grupo and cg_estado = 'V'))
  begin
      -- PRINT'VALIDAR INTEGRANTES COMO CÓNYUGES ID DEL CLIENTE: '+ convert(VARCHAR(40),@w_cliente_gr)
    select @w_error = 1720218  --Validación conyuge--
 
    select  @w_msg= 'VALIDAR INTEGRANTES COMO CÓNYUGES: ID DEL CLIENTE '+convert(VARCHAR(40),@w_cliente_gr)
    
     exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = @w_error,
             @i_msg   = @w_msg
  end

  select top 1   @w_cliente_gr=cg_ente
  from cobis..cl_cliente_grupo
  where cg_grupo =@i_grupo
  and cg_estado = 'V'
  and cg_ente  > @w_cliente_gr 
  order by cg_ente ASC
  end--Fin While--
  */
    
   --validaciones de mujeres--
   select @w_param_porc_mujeres=pa_float from cobis..cl_parametro where pa_nemonico='PMGRU'  and pa_producto = 'CRE'
   select @w_integrantes = count(cg_ente) 
   from cobis..cl_cliente_grupo 
   where cg_grupo =@i_grupo 
   and cg_estado = 'V'
   select @w_num_sexo_feme = count(1) from cobis..cl_cliente_grupo, cobis..cl_ente
                        where en_ente = cg_ente
                        and p_sexo = 'F'    --genero femenino
                        and cg_grupo =@i_grupo
                        and cg_estado = 'V'                      
   if(@w_integrantes<>0) 
   begin
   select @w_valor_nuevo = ((@w_num_sexo_feme * 100)/@w_integrantes)
   end

   if @w_valor_nuevo < @w_param_porc_mujeres -- parametro de porcentaje de mujeres en grupos
   begin
     select @w_error = 1720219  --Error en Porcentaje de Parentesco
     goto ERROR
   end
  
   --Validacion Emprendedores--
   select @w_param_porc_emp=pa_float from cobis..cl_parametro where pa_nemonico='MAXEMP'  and pa_producto = 'CRE'
 
   select @w_integrantes = count(cg_ente) 
    from cobis..cl_cliente_grupo 
    where cg_grupo =@i_grupo 
    and cg_estado = 'V' 
  
   select @w_sum_enprender = count(nc_emprendedor) from cobis..cl_cliente_grupo, cobis..cl_negocio_cliente 
    where nc_ente = cg_ente 
    and cg_grupo =@i_grupo
    and cg_estado = 'V' 
    and nc_emprendedor ='S'
    and nc_estado_reg='V'
    
   if(@w_integrantes<>0) 
   begin
    select @w_porcentaje = ((@w_sum_enprender * 100)/@w_integrantes)
   end
   
   if @w_porcentaje > @w_param_porc_emp -- parametro de emprendedores en grupos
   begin
    select @w_error =1720220  --validación emprendedores
    goto ERROR
   end
   
   --Fin Validacion Emprendedores--
  
  --validaciones Presidente--
  select @numIntegrantesGrupo=count(cg_ente) from cobis..cl_cliente_grupo where cg_grupo=@i_grupo and cg_estado = 'V'
  if(@numIntegrantesGrupo<>0)
  begin
  if not exists (select 1 from cobis..cl_cliente_grupo 
                 where cg_rol    = 'P'
                   and cg_grupo  = @i_grupo 
                   and cg_estado = 'V')
  begin
  select @w_error =1720221  --Validación Tesorero
    goto ERROR
  end                               
  end

  --validaciones SECRETARIO--
  if(@numIntegrantesGrupo<>0)
  begin
      if not exists (select 1 from cobis..cl_cliente_grupo 
                   where cg_rol    = 'S'
                     and cg_grupo  = @i_grupo 
                     and cg_estado = 'V')
      begin
          select @w_error = 1720222  --Validación SECRETARIO
            goto ERROR
      end                               
  end   


---Validación Tesorero

  if(@numIntegrantesGrupo<>0)
  begin
  if not exists (select 1 from cobis..cl_cliente_grupo 
               where cg_rol    = 'T'
                 and cg_grupo  = @i_grupo 
                 and cg_estado = 'V')
  begin
    select @w_error = 1720223  --Validación Tesorero
    goto ERROR
  end                               
  end
 end
 end            
end -- Fin Operacion I

if @i_operacion = 'U'
begin
 if @t_trn = 172038
 begin
    -- Viene el front end como - 31/12/1969 19:00:00 por eso se cambia
    select @i_fecha_modificacion = getdate()
    
    -- verificar que exista el grupo --
    if not exists (select 1 from cobis..cl_grupo where gr_grupo = @i_grupo)
    begin
           select @w_error = 151029 -- NO EXISTE GRUPO
           goto ERROR
    end
    
    --Verificar que el oficial exista
    if not exists (select 1 from cobis..cc_oficial where oc_oficial = @i_oficial) and @i_oficial is not null
    begin
        select @w_error = 1720161  -- No existe oficial --
        goto ERROR
    end
    
   /*VALIDAR QUE EL GRUPO Y EL REPRESENTANTE PERTENEZCAN AL MISMO OFICIAL*/
   if @w_controlar_oficial = 'S' and @i_representante is not null --Grupos en app puede crearse sin presidente
   begin
      select @w_oficial_ente = en_oficial
        from cobis..cl_ente
       where en_ente = @i_representante

      if @i_oficial <> @w_oficial_ente
      begin
         select @w_error = 1720650
         goto ERROR
      end     
   end
    
    --Verifica si existe el miembro en otros grupos
    if exists ( select 1 from cobis..cl_grupo, cobis..cl_cliente_grupo ccg  
                where gr_grupo = ccg.cg_grupo
                    and gr_tipo = @i_gr_tipo
                    and gr_grupo <> @i_grupo
                    and cg_ente = @i_representante 
                    and (cg_fecha_desasociacion is null and cg_rol != 'D') --desertor
                    )
    begin
        select @w_error = 1720212 -- YA EXISTE EL MIEMBRO EN OTRO GRUPO --
        goto ERROR
    end
    
    select @w_cod_presi = gr_representante
    from cobis..cl_grupo
    where gr_grupo = @i_grupo
    
    if @i_representante <> @w_cod_presi and @w_cod_presi is not null
    begin
       --validacion que el presidente no tenga operaciones pendientes
      if exists (select 1 from cob_workflow.dbo.wf_inst_proceso with (nolock),
                               cob_cartera..ca_operacion with (nolock)
                 where io_campo_3 = op_tramite
                 and op_ref_grupal is null
                 and op_grupal = 'S'
                 and io_estado = 'EJE'
                 and op_estado = 99
                 and op_cliente = @w_cod_presi)
      begin
         select @w_error = 1720667 --TIENE OPERACIONES PENDIENTES
         goto ERROR
      end
    end
    
    if @i_estado in ('I', 'C')  --estado del grupo INACTIVO, CANCELADO
    begin
      --validacion que todos los miebros no tengas operaciones pendientes
      if exists (select (1) from cob_cartera..ca_operacion, cob_cartera..ca_estado
                            where op_estado = es_codigo
                              and es_procesa = 'S'
                              and op_cliente in (select distinct tg_cliente from cob_credito..cr_tramite_grupal where tg_grupo = @i_grupo))
      begin
         select @w_error = 1720235 --TIENE OPERACIONES PENDIENTES
         goto ERROR
      end
    end
    -- Consulta de datos del grupo
    select @w_grupo               = gr_grupo,
           @w_nombre              = gr_nombre,
           @w_representante       = gr_representante,
           @w_compania            = gr_compania,
           @w_oficial             = gr_oficial,
           @w_fecha_registro      = gr_fecha_registro,
           @w_fecha_modificacion  = gr_fecha_modificacion,
           @w_ruc                 = gr_ruc,
           @w_vinculacion         = gr_vinculacion,
           @w_tipo_vinculacion    = gr_tipo_vinculacion,
           @w_max_riesgo          = gr_max_riesgo,
           @w_riesgo              = gr_riesgo,
           @w_usuario             = gr_usuario,
           @w_reservado           = gr_reservado,
           @w_tipo_grupo          = gr_tipo_grupo,
           @w_estado              = gr_estado,
           @w_dir_reunion         = gr_dir_reunion,
           @w_dia_reunion         = gr_dia_reunion,
           @w_hora_reunion        = gr_hora_reunion,
           @w_comportamiento_pago = gr_comportamiento_pago,
           @w_num_ciclo           = gr_num_ciclo,
           @w_gr_tipo             = gr_tipo,
           @w_gr_cta_grupal       = gr_cta_grupal,
           @w_gr_sucursal         = gr_sucursal,
           @w_gr_titular1         = gr_titular1,
           @w_gr_titular2         = gr_titular2,
           @w_gr_lugar_reunion    = gr_lugar_reunion,
           @w_gr_tiene_ctagr      = gr_tiene_ctagr,
           @w_gr_tiene_ctain      = gr_tiene_ctain,
           @w_gr_gar_liquida      = isnull(gr_gar_liquida,'S')
           
    from   cobis..cl_grupo
    where  gr_grupo = @i_grupo
    
    -- INI Guardar los datos anteriores que han cambiado --
    select @v_grupo               = @w_grupo,
           @v_nombre              = @w_nombre,
           @v_representante       = @w_representante,
           @v_compania            = @w_compania,
           @v_oficial             = @w_oficial,
           @v_fecha_registro      = @w_fecha_registro,
           @v_fecha_modificacion  = @w_fecha_modificacion,
           @v_ruc                 = @w_ruc,
           @v_vinculacion         = @w_vinculacion,
           @v_tipo_vinculacion    = @w_tipo_vinculacion,
           @v_max_riesgo          = @w_max_riesgo,
           @v_riesgo              = @w_riesgo,
           @v_usuario             = @w_usuario,
           @v_reservado           = @w_reservado,
           @v_tipo_grupo          = @w_tipo_grupo,
           @v_estado              = @w_estado,
           @v_dir_reunion         = @w_dir_reunion,
           @v_dia_reunion         = @w_dia_reunion,
           @v_hora_reunion        = @w_hora_reunion,
           @v_comportamiento_pago = @w_comportamiento_pago,
           @v_num_ciclo           = @w_num_ciclo,
           @v_gr_tipo             = @w_gr_tipo,
           @v_gr_cta_grupal       = @w_gr_cta_grupal,
           @v_gr_sucursal         = @w_gr_sucursal,
           @v_gr_titular1         = @w_gr_titular1,
           @v_gr_titular2         = @w_gr_titular2,
           @v_gr_lugar_reunion    = @w_gr_lugar_reunion,
           @v_gr_tiene_ctagr      = @w_gr_tiene_ctagr,
           @v_gr_tiene_ctain      = @w_gr_tiene_ctain,
           @v_gr_gar_liquida      = isnull(@w_gr_gar_liquida,'S')
           
    -- Validacion para actualizar el oficial o no
    if @i_oficial = @w_oficial and @w_oficial is not null
        select @w_es_oficial = 'S'

    if @w_grupo = @i_grupo
        select @w_grupo = null, @v_grupo = null
    else
        select @w_grupo = @i_grupo

    if @w_nombre = @i_nombre
        select @w_nombre = null, @v_nombre = null
    else
        select @w_nombre = @i_nombre

    if @w_representante = @i_representante
        select @w_representante = null, @v_representante = null
    else
        select @w_representante = @i_representante

    if @w_compania = @i_compania
        select @w_compania = null, @v_compania = null
    else
        select @w_compania = @i_compania            
        
    if @w_oficial = @i_oficial
        select @w_oficial = null, @v_oficial = null
    else
        select @w_oficial = @i_oficial
        
    if @w_fecha_registro = @i_fecha_registro
        select @w_fecha_registro = null, @v_fecha_registro = null
    else
        select @w_fecha_registro = @i_fecha_registro        

    if @w_fecha_modificacion = @i_fecha_modificacion
        select @w_fecha_modificacion = null, @v_fecha_modificacion = null
    else
        select @w_fecha_modificacion = @i_fecha_modificacion

    if @w_ruc = @i_ruc
        select @w_ruc = null, @v_ruc = null
    else
        select @w_ruc = @i_ruc        

    if @w_vinculacion = @i_vinculacion
        select @w_vinculacion = null, @v_vinculacion = null
    else
        select @w_vinculacion = @i_vinculacion

    if @w_tipo_vinculacion = @i_tipo_vinculacion
        select @w_tipo_vinculacion = null, @i_tipo_vinculacion = null
    else
        select @w_tipo_vinculacion = @i_tipo_vinculacion
        
    if @w_max_riesgo = @i_max_riesgo
        select @w_max_riesgo = null, @v_max_riesgo = null
    else
        select @w_max_riesgo = @i_max_riesgo

    if @w_usuario = @i_usuario
        select @w_usuario = null, @v_usuario = null
    else
        select @w_usuario = @i_usuario    

    if @w_reservado = @i_reservado
        select @w_reservado = null, @v_reservado = null
    else
        select @w_reservado = @i_reservado

    if @w_tipo_grupo = @i_tipo_grupo
        select @w_tipo_grupo = null, @v_tipo_grupo = null
    else
        select @w_tipo_grupo = @i_tipo_grupo        
        
    if @w_estado = @i_estado
        select @w_estado = null, @v_estado = null
    else
        select @w_estado = @i_estado

    if @w_dir_reunion = @i_dir_reunion
        select @w_dir_reunion = null, @v_dir_reunion = null
    else
        select @w_dir_reunion = @i_dir_reunion
        
    if @w_dia_reunion = @i_dia_reunion
        select @w_dia_reunion = null, @v_dia_reunion = null
    else
        select @w_dia_reunion = @i_dia_reunion    
    if exists(select 1 from cl_grupo where gr_grupo = @i_grupo and gr_tipo = 'S')
    begin
    select @w_hora_catalogo = trim(valor) from cl_catalogo cc 
                                           where tabla in (select codigo from cl_tabla ct 
                                                                        where tabla = 'cl_atencion_clientes')
                                             and codigo = @i_hora_reunion
    if @w_hora_reunion = CONVERT(datetime, CONCAT('1900-01-01 ',@w_hora_catalogo))
        select @w_hora_reunion = null, @v_hora_reunion = null
    else
        select @w_hora_reunion = CONVERT(datetime, CONCAT('1900-01-01 ',@w_hora_catalogo))
    end

    if @w_comportamiento_pago = @i_comportamiento_pago
        select @w_comportamiento_pago = null, @i_comportamiento_pago = null
    else
        select @w_comportamiento_pago = @i_comportamiento_pago    

    if @w_num_ciclo = @i_num_ciclo
        select @w_num_ciclo = null, @i_num_ciclo = null
    else
        select @w_num_ciclo = @i_num_ciclo  
   
    
    if @w_gr_gar_liquida = @i_gr_gar_liquida
        select @w_gr_gar_liquida = null, @v_gr_gar_liquida = null
    else
        select @w_gr_gar_liquida = @i_gr_gar_liquida  

    -- FIN Guardar los datos anteriores que han cambiado --
    
    -- INI Transaccion servicio - cl_grupo --
    insert into cobis..ts_grupo  (secuencial,    tipo_transaccion,    clase,                 fecha,    --1
                                  terminal,      srv,                 lsrv,                            --2
                                  grupo,         nombre,              representante,         compania, --3
                                  oficial,       fecha_registro,      fecha_modificacion,    ruc,      --4                      
                                  vinculacion,   tipo_vinculacion,    max_riesgo,            riesgo,   --5                      
                                  usuario,       reservado,           tipo_grupo,            estado,   --6                      
                                  dir_reunion,   dia_reunion,         hora_reunion,          comportamiento_pago,--7                      
                                  num_ciclo,     gar_liquida)
    values                       (@s_ssn,        172038,                 'P',                   @s_date,   --1
                                  @s_term,       @s_srv,              @s_lsrv,                           --2
                                  @i_grupo,      @v_nombre,           @v_representante,      @v_compania,--3
                                  @v_oficial,    @v_fecha_registro,   @v_fecha_modificacion, @v_ruc,     --4
                                  @v_vinculacion,@v_tipo_vinculacion, @v_max_riesgo,         @v_riesgo,  --5
                                  @v_usuario,    @v_reservado,        @v_tipo_grupo,         @v_estado,  --6
                                  @v_dir_reunion,@v_dia_reunion,      @v_hora_reunion,       @v_comportamiento_pago,--7
                                  @v_num_ciclo  ,isnull(@v_gr_gar_liquida,'S')                                                         --8
                                 )
                                 
    -- si no se puede insertar, error --
    if @@error != 0
    begin
        select @w_error = 1720049  --ERROR EN CREACION DE TRANSACCION DE SERVICIO
        goto ERROR      
    end
    
    -- Modificar los datos anteriores -- 
    --Grupo Solidario
    if exists(select 1 from cl_grupo where gr_grupo = @i_grupo and gr_tipo = 'S')
    begin
       update cobis..cl_grupo
       set    gr_oficial            = isnull(@i_oficial, gr_oficial),
              gr_fecha_modificacion = isnull(@i_fecha_modificacion, gr_fecha_modificacion),
              gr_estado             = isnull(@i_estado, gr_estado),
              gr_dir_reunion        = isnull(@i_dir_reunion, gr_dir_reunion),
              gr_dia_reunion        = isnull(@i_dia_reunion, gr_dia_reunion),
              gr_hora_reunion       = CONVERT(datetime, CONCAT('1900-01-01 ',isnull(@w_hora_catalogo, '12:00'))),
              gr_tipo               = isnull(@i_gr_tipo, gr_tipo),
              gr_cta_grupal         = isnull(@i_gr_cta_grupal, gr_cta_grupal),
              gr_sucursal           = isnull(@i_gr_sucursal, gr_sucursal),
              gr_titular1           = isnull(@i_gr_titular1, gr_titular1),
              gr_titular2           = isnull(@i_gr_titular2, gr_titular2),
              gr_lugar_reunion      = isnull(@i_gr_lugar_reunion, gr_lugar_reunion),
              gr_tiene_ctagr        = isnull(@i_gr_tiene_ctagr, gr_tiene_ctagr),
              gr_tiene_ctain        = isnull(@i_gr_tiene_ctain, gr_tiene_ctain),
              gr_gar_liquida        = isnull(@i_gr_gar_liquida,'S')
              
              --gr_comportamiento_pago= @i_comportamiento_pago
              --gr_num_ciclo          = @i_num_ciclo
       where  gr_grupo = @i_grupo
    end
    else
    begin
       --Grupo Economico
       update cobis..cl_grupo
       set    gr_oficial             = isnull(@i_oficial, gr_oficial),
              gr_fecha_modificacion  = isnull(@i_fecha_modificacion,gr_fecha_modificacion), 
              gr_estado              = isnull(@i_estado, gr_estado),
              gr_tipo                = isnull(@i_gr_tipo, gr_tipo),
              gr_sucursal            = isnull(@i_gr_sucursal, gr_sucursal),
              gr_tipo_vinculacion    = isnull(@i_tipo_vinculacion, gr_tipo_vinculacion),
              gr_tipo_grupo          = isnull(@i_tipo_grupo, gr_tipo_grupo),
              gr_nombre              = isnull(@i_nombre, gr_nombre),
              gr_gar_liquida         = isnull(@i_gr_gar_liquida,'S')
       where  gr_grupo = @i_grupo
       
       select @o_grupo = @i_grupo
    end
    

    -- Si no se puede modificar, error --
    if @@rowcount = 0
    begin
        select @w_error = 105007  --ERROR EN ACTUALIZACION DE GRUPO
        goto ERROR
         
    end
    --actualizo el lugar de reunion cuando lugar de reunion es igual OT
    if ( @i_gr_lugar_reunion ='OT')
    begin
       UPDATE cobis..cl_cliente_grupo
       SET cg_lugar_reunion = NULL
       where cg_grupo = @i_grupo
    end
    
    -- Insert en ts_grupo
    insert into cobis..ts_grupo  (secuencial,    tipo_transaccion,    clase,                 fecha,    --1
                                  terminal,      srv,                 lsrv,                            --2
                                  grupo,         nombre,              representante,         compania, --3
                                  oficial,       fecha_registro,      fecha_modificacion,    ruc,      --4                      
                                  vinculacion,   tipo_vinculacion,    max_riesgo,            riesgo,   --5                      
                                  usuario,       reservado,           tipo_grupo,            estado,   --6                      
                                  dir_reunion,   dia_reunion,         hora_reunion,          comportamiento_pago,--7                      
                                  num_ciclo,     gar_liquida)
    values                       (@s_ssn,        172038,                 'A',                   @s_date,   --1
                                  @s_term,       @s_srv,              @s_lsrv,                           --2
                                  @i_grupo,      @w_nombre,           @w_representante,      @w_compania,--3
                                  @w_oficial,    @w_fecha_registro,   @w_fecha_modificacion, @w_ruc,     --4
                                  @w_vinculacion,@w_tipo_vinculacion, @w_max_riesgo,         @w_riesgo,  --5
                                  @w_usuario,    @w_reservado,        @w_tipo_grupo,         @w_estado,  --6
                                  @w_dir_reunion,@w_dia_reunion,      @w_hora_reunion,       @w_comportamiento_pago,--7
                                  @w_num_ciclo  ,isnull(@w_gr_gar_liquida,'S')                                                  --8
                                 )
    
    -- Si no se puede insertar, error --
    if @@error != 0
    begin
        select @w_error = 1720049  --ERROR EN CREACION DE TRANSACCION DE SERVICIO 
        goto ERROR
    end
    
    -- Inicio CLI-S274230-TECGRP Traspaso de cartera: Actualización de oficial.
    if @w_es_oficial = 'N'
    begin
        -- Consulta de Datos
        select  top 1 
                @w_cg_ente                  = cg_ente,
                @w_cg_grupo                 = cg_grupo,
                @w_cg_usuario               = cg_usuario,
                @w_cg_oficial               = cg_oficial,
                @w_cg_fecha_asociacion      = cg_fecha_reg,
                @w_cg_rol                   = cg_rol,
                @w_cg_estado                = cg_estado,
                @w_cg_calif_interna         = cg_calif_interna,
                @w_cg_fecha_desasociacion   = cg_fecha_desasociacion,
                @w_cg_ahorro_voluntario     = cg_ahorro_voluntario,
                @w_cg_lugar_reunion         = cg_lugar_reunion

        from  cobis..cl_cliente_grupo
        where cg_grupo = @i_grupo
        
        -- INI Guardar los datos anteriores que han cambiado --
        select @v_cg_ente                 = @w_cg_ente,
               @v_cg_grupo                = @w_cg_grupo,
               @v_cg_usuario              = @w_cg_usuario,
               @v_cg_oficial              = @w_cg_oficial,
               @v_cg_fecha_asociacion     = @w_cg_fecha_asociacion,
               @v_cg_rol                  = @w_cg_rol,
               @v_cg_estado               = @w_cg_estado,
               @v_cg_calif_interna        = @w_cg_calif_interna,
               @v_cg_fecha_desasociacion  = @w_cg_fecha_desasociacion,
               @v_cg_ahorro_voluntario    = @w_cg_ahorro_voluntario,
               @v_cg_lugar_reunion        = @w_cg_lugar_reunion
        
        begin tran -- inicio tran
            -- Transaccion servicio - cl_cliente_grupo --
            insert into cobis..ts_cliente_grupo (secuencial,    tipo_transaccion,       clase,                      --1
                                                 srv,           lsrv,                   ente,                       --2
                                                 grupo,         usuario,                terminal,                   --3
                                                 oficial,       fecha_reg,              rol,                        --4
                                                 estado,        calif_interna,          fecha_desasociacion         --5
                                                 )
            values                              (@s_ssn,        810,                    'P',                        --1
                                                 @s_srv,        @s_lsrv,                @v_cg_ente,                 --2
                                                 @i_grupo,      @s_user,                @s_term,                    --3
                                                 @v_cg_oficial, @v_cg_fecha_asociacion, @v_cg_rol,                  --4
                                                 @v_cg_estado,  @v_cg_calif_interna,    @v_cg_fecha_desasociacion   --5
                                                 )
                                                 
            -- Si no se puede insertar transaccion de servicio, error --
            if @@error != 0
            begin
                select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
                goto ERROR
            end
            
            -- Actualiza el oficial a todo los clientes que existan en el grupo
            select @w_ente_aux = 0
            while (1=1) begin 
                select top 1 @w_ente_aux = cg_ente 
                from cobis..cl_cliente_grupo
                where cg_ente > @w_ente_aux and cg_grupo = @i_grupo
                order by cg_ente asc
                    
                if @@rowcount = 0 break
                
                -- actualiza el oficial
                update cobis..cl_cliente_grupo
                set cg_oficial = @i_oficial
                where cg_ente = @w_ente_aux and cg_grupo = @i_grupo

                -- Si no se puede modificar, error --
                if @@error != 0
                begin
                    select @w_error = 1720246  --ERROR EN LA ACTUALIZACIÓN DEL MIEMBRO
                    goto ERROR
                end
            end 
            -- fin del while
            
            -- Transaccion servicio - cl_cliente_grupo --
            insert into cobis..ts_cliente_grupo (secuencial,    tipo_transaccion,       clase,                      --1
                                                 srv,           lsrv,                   ente,                       --2
                                                 grupo,         usuario,                terminal,                   --3
                                                 oficial,       fecha_reg,              rol,                        --4
                                                 estado,        calif_interna,          fecha_desasociacion         --5
                                                 )
            values                              (@s_ssn,        172041,                 'A',                        --1
                                                 @s_srv,        @s_lsrv,                @w_cg_ente,                 --2
                                                 @i_grupo,      @s_user,                @s_term,                    --3
                                                 @i_oficial,    @w_cg_fecha_asociacion, @w_cg_rol,                  --4
                                                 @w_cg_estado,  @w_cg_calif_interna,    @w_cg_fecha_desasociacion   --5
                                                 )
                                                 
            -- Si no se puede insertar transaccion de servicio, error --
            if @@error != 0
            begin
                select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
                goto ERROR
            end
        commit tran -- fin de la tran y commit
    end
    -- Fin de CLI-S274230-TECGRP Traspaso de cartera: Actualización de oficial.
    
    
    if(@i_desde_fe = 'N')
        begin
        --INICIO DE VALIDACIONES--
        --nuevas validaciones maximo 40--
      select @numIntegrantesGrupo=count(cg_ente) from cobis..cl_cliente_grupo where cg_grupo=@i_grupo and cg_estado = 'V'
       if(@numIntegrantesGrupo<>0)
       begin
        select @w_param_max_inte =pa_int from cobis..cl_parametro where pa_nemonico='MAXIGR' and pa_producto = 'CLI'
        select @w_param_min_inte =pa_int from cobis..cl_parametro where pa_nemonico='MINIGR' and pa_producto = 'CLI'
        select @w_integrantes  = count(cg_ente) from cobis..cl_cliente_grupo
        where cg_grupo = @i_grupo
        and cg_estado = 'V'      
         
         --validacion parentesco--
        /*
        select @w_param_porc_parentesco=pa_float from cobis..cl_parametro where pa_nemonico='PPGRU'  and pa_producto = 'CRE'
        select distinct @w_num_integrantes = count(cg_ente) 
        from cobis..cl_cliente_grupo 
        where cg_grupo = @i_grupo
        and cg_estado = 'V'
        select @w_sum_parentesco=count(DISTINCT in_ente_i) from cobis..cl_instancia
        where  in_relacion IN (select B.codigo from cobis..cl_tabla A, cobis..cl_catalogo B 
                 where A.tabla in ('cl_parentesco_1er','cl_parentesco_2er') and A.codigo= B.tabla)
        and in_ente_i IN (select cg_ente from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_estado = 'V')
        and in_ente_d IN (select cg_ente from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_estado = 'V')
        if(@w_num_integrantes <>0)
        begin
        select @w_porcentaje = ((@w_sum_parentesco * 100)/@w_num_integrantes)

        select @w_valor_nuevo = @w_porcentaje
        end
        if @w_valor_nuevo > @w_param_porc_parentesco    -- parametro 40 porcentaje de parentesco en grupos
        begin
        --PRINT'VALIDAR PARENTESCO DE INTEGRANTES.'+CONVERT(VARCHAR(30),@w_porcentaje)
          select @w_error = 1720216  --Error en Porcentaje de Parentesco
                  goto ERROR
        end
        */
        
        select @w_reunion = gr_dir_reunion from cobis..cl_grupo where gr_grupo = @i_grupo
        
        if exists(select 1 from cl_grupo where gr_grupo = @i_grupo and gr_tipo = 'S')
        begin
           if ((@w_reunion IS NULL) or (@w_reunion = ' '))    -- Lugar de reunion
           begin
           --PRINT'VALIDAR Lugar de Reunion.'+CONVERT(VARCHAR(30),@w_porcentaje)
             select @w_error = 1720217  --POR FAVOR INGRESE EL LUGAR DE REUNION
                     goto ERROR
           end
        end
        
        --validacion de credito--
       /* if exists (select 1 from cobis..cl_cliente_grupo, cob_cartera..ca_operacion
       where cg_grupo = @i_grupo
       and cg_estado = 'V'
       and cg_ente = op_cliente
       and op_estado NOT IN (0,99,3, 6))
       begin
       --PRINT'VALIDAR CRÉDITOS VIGENTES DE INTEGRANTES.'
          select @w_error = 208918  --validacion de credito
          goto ERROR
       end */
       
        --Validación conyuge--
      /*
      select @w_param_rel_cony=pa_int from cobis..cl_parametro where pa_nemonico='RCONY'  and pa_producto = 'CRE' 
      
      select @w_cliente_gr= 0
      select top 1   @w_cliente_gr=cg_ente
      from cobis..cl_cliente_grupo
      where cg_grupo =@i_grupo
      and cg_estado = 'V'
      and cg_ente  > @w_cliente_gr 
      order by cg_ente ASC
      WHILE @@rowcount > 0
      begin
      if exists (select 1
      from cobis..cl_instancia
      where in_ente_i = @w_cliente_gr
      and in_relacion =@w_param_rel_cony -- parametro 'RCONY'
      and in_ente_d in (select cg_ente from cobis..cl_cliente_grupo where cg_grupo =@i_grupo and cg_estado = 'V'))
      begin
      --PRINT'VALIDAR INTEGRANTES COMO CÓNYUGES ID DEL CLIENTE: '+ convert(VARCHAR(40),@w_cliente_gr)
        select @w_error = 1720218  --Validación conyuge--
        select  @w_msg= 'VALIDAR INTEGRANTES COMO CÓNYUGES: ID DEL CLIENTE  '+convert(VARCHAR(40),@w_cliente_gr)
                goto ERROR
      end

      select top 1   @w_cliente_gr=cg_ente
      from cobis..cl_cliente_grupo
      where cg_grupo =@i_grupo
      and cg_estado = 'V'
      and cg_ente  > @w_cliente_gr 
      order by cg_ente ASC
      end--Fin While--
      */

        /*
       --validaciones de mujeres--
       select @w_param_porc_mujeres=pa_float from cobis..cl_parametro where pa_nemonico='PMGRU'  and pa_producto = 'CRE'
       select @w_integrantes = count(cg_ente) 
       from cobis..cl_cliente_grupo 
       where cg_grupo =@i_grupo 
       and cg_estado = 'V'
       select @w_num_sexo_feme = count(1) from cobis..cl_cliente_grupo, cobis..cl_ente
                            where en_ente = cg_ente
                            and p_sexo = 'F'    --genero femenino
                            and cg_grupo =@i_grupo
                            and cg_estado = 'V'                      
       if(@w_integrantes<>0) 
       begin
       select @w_valor_nuevo = ((@w_num_sexo_feme * 100)/@w_integrantes)
       end

       if @w_valor_nuevo < @w_param_porc_mujeres -- parametro de porcentaje de mujeres en grupos
       begin
       --PRINT'VALIDAR NÚMERO DE MUJERES.'
         select @w_error = 1720219  --Error en Porcentaje de Parentesco
                 goto ERROR
       end
      
        --Validación de emprendedores--
       select @w_param_porc_emp=pa_float from cobis..cl_parametro where pa_nemonico='MAXEMP'  and pa_producto = 'CRE'
     
       select @w_integrantes = count(cg_ente) 
        from cobis..cl_cliente_grupo 
        where cg_grupo =@i_grupo 
        and cg_estado = 'V' 
       select @w_sum_enprender = count(nc_emprendedor) from cobis..cl_cliente_grupo, cobis..cl_negocio_cliente 
        where nc_ente = cg_ente 
        and cg_grupo =@i_grupo
        and cg_estado = 'V' 
        and nc_emprendedor ='S'
        and nc_estado_reg='V'
        
      if(@w_integrantes<>0) 
       begin
        select @w_porcentaje = ((@w_sum_enprender * 100)/@w_integrantes)
       end
       
       if @w_porcentaje > @w_param_porc_emp -- parametro emprededores en grupos
       begin
        select @w_error =1720220  --Validación emprendedor
                goto ERROR
       end
       
       --Fin Validación Emprendedores--
      */
      if exists(select 1 from cl_grupo where gr_grupo = @i_grupo and gr_tipo = 'S')
      begin
         --validaciones Presidente--
         
         select @numIntegrantesGrupo=count(cg_ente) from cobis..cl_cliente_grupo where cg_grupo=@i_grupo and cg_estado = 'V'
         if(@numIntegrantesGrupo<>0)
         begin
            if not exists (select 1 from cobis..cl_cliente_grupo 
                       where cg_rol    = 'P'
                       and   cg_grupo  = @i_grupo 
                       and   cg_estado ='V')
            begin
               select @w_error =1720221  --Validación Presidente
                   goto ERROR
            end                               
         end
      end
     
     end
    end
 end
 
 if @i_estado in ('I', 'C')  --estado del grupo INACTIVO, CANCELADO
    begin
      --Poner a todos los miembros del grupo como desertores
      select @w_min_miembro = min(cg_ente)
      from cobis.dbo.cl_cliente_grupo
      where cg_estado = 'V'
      and cg_grupo = @i_grupo
      
      while @w_min_miembro is not NULL
      begin
         exec @w_error = cobis..sp_miembro_grupo
            @s_ssn = @s_ssn,
            @t_trn = 172041,
            @i_operacion = 'U', 
            @i_ente = @w_min_miembro, 
            @i_grupo = @i_grupo, 
            @i_tipo_grupo = @i_tipo_grupo, 
            @i_rol = 'D'
         if @w_error <> 0
         begin
            goto ERROR
         end
         --siguiente miembro
         select @w_min_miembro = min(cg_ente)
         from cobis.dbo.cl_cliente_grupo
         where cg_estado = 'V'
         and cg_grupo = @i_grupo
         and cg_ente > @w_min_miembro
      end
    end
end -- Fin Operacion U

if @i_operacion = 'Q'
begin

    --Valida que no exista una solicitud en curso
    if exists (select 1 from cob_workflow..wf_inst_proceso
                where io_campo_1 = @i_grupo
                  and io_estado not in ('TER', 'CAN', 'SUS', 'ELI')
                  and io_campo_7='S')
    begin
        select @w_actualiza = 'N'
        if ( @s_ofi = @w_parm_ofi_movil)
        begin
            exec sp_grupo
            @i_operacion       = 'M',
            @i_grupo           = @i_grupo,
            @t_trn             = 172036,            
            @o_actualiza_movil = @w_actualiza_movil OUTPUT
        end
    end
    
    /*Motivo: en reimpresion esta saliendo ciclo 2 cuando el cliente tiene ciclo 1*/
    declare @w_num int
    select @w_num = 0
    if exists (select 1 from cob_cartera..ca_operacion--, cob_credito..cr_tramite_grupal
               where op_cliente  = @i_grupo
               and op_toperacion = 'GRUPAL'
               and op_estado IN (0,99))
    begin
        select @w_num = 1   
    end 
       -- Consulta de datos del grupo solidario
    select 'Id_Gupo'             = gr_grupo,
           'Nombre'              = gr_nombre,
           'Oficial'             = gr_oficial,
           'Nombre Oficial'      = f.fu_nombre,
           'Fecha_Registro'      = gr_fecha_registro,
           'Fecha_Modificacion'  = gr_fecha_modificacion,
           'Estado'              = gr_estado,
           'Dir_Reunion'         = gr_dir_reunion,
           'Dia_Reunion'         = gr_dia_reunion,
           'Hora_Reunion'        = convert(char(5),gr_hora_reunion,108),
           'Comportamiento_Pago' = gr_comportamiento_pago,
           'Num_Ciclo'           = isnull(gr_num_ciclo,0) + @w_num,
           'Cuenta_grupal'       = gr_cta_grupal,
           'Sucursal'            = gr_sucursal,--12
           'Tipo'                = gr_tipo,
           'Titular1_Codigo'     = gr_titular1,--14
           'Titular1_Nombre'     = (select en_nomlar from cobis..cl_ente where en_ente=gr.gr_titular1), 
           'Titular2_Codigo'     = gr_titular2,          
           'Titular2_Nombre'     = (select en_nomlar from cobis..cl_ente where en_ente=gr.gr_titular2),
           'Lugar_reunion'       = gr_lugar_reunion,
           'Tiene_Cta_Grupal'    = gr_tiene_ctagr,
           'Tiene_Cta_Individual'= gr_tiene_ctain,
           'Actualiza'           = @w_actualiza, --Valida si el grupo tiene una solicitud en curso para pantalla de Mant. de grupos,
           'Gar_liquida'         = isnull(gr_gar_liquida,'S'),
           'ActualizaMov'        = @w_actualiza_movil,   --Valida si el grupo tiene una solicitud en curso para el movil,
           'Representante'       = gr_representante,
           'Hora_R'              = RIGHT(Format(cast(gr_hora_reunion as datetime),'dd/MM/yyyy HH:mm:ss','en-us'),8), -- Devuelve solo la hora 
           'Clasificacion'       = gr_clasificacion, --Devuelve clasificacion crediticia
           'Tipo Grupo'          = gr_tipo_grupo,
           'Tipo Vinculacion'    = gr_tipo_vinculacion
       
    from cobis..cl_grupo gr 
    join cobis..cc_oficial o on gr.gr_oficial = o.oc_oficial
    join cobis..cl_funcionario f on f.fu_funcionario = o.oc_funcionario
    and  gr_grupo = @i_grupo

    
    if @@ROWCOUNT = 0
    begin
        select @w_error = 1720224 -- NO EXISTE EL GRUPO
        goto ERROR
    end
    
    
    
end -- Fin Operacion Q

if @i_operacion = 'S'
begin
    select @w_num = 0
    if exists (select 1 from cob_cartera..ca_operacion--, cob_credito..cr_tramite_grupal
               where op_cliente  = @i_grupo
               and op_toperacion = 'GRUPAL'
               and op_estado IN (0,99))
    begin
        select @w_num = 1   
    end 
      -- Consulta de datos del grupo solidario
   select 'Id_Gupo'              = gr_grupo,
          'Nombre'               = gr_nombre,
          'Oficial'              = gr_oficial,
          'Nombre Oficial'       = f.fu_nombre,
          'Fecha_Registro'       = (select format (gr_fecha_registro, 'dd-MM-yyyy HH:mm:ss') as date),
          'Fecha_Modificacion'   = (select format (gr_fecha_modificacion, 'dd-MM-yyyy HH:mm:ss') as date),
          'Estado'               = gr_estado,
          'Dir_Reunion'          = gr_dir_reunion,
          'Dia_Reunion'          = gr_dia_reunion,
          'Hora_Reunion'         = (select format (gr_hora_reunion, 'HH:mm:ss') as varchar), 
          'Num_Ciclo'            = isnull(gr_num_ciclo,0) + @w_num,
          'Sucursal'             = gr_sucursal,--12
          'Tipo'                 = gr_tipo,
          'Representante'        = gr_representante,
          'Nombre representante' = (select en_nomlar from cl_ente where en_ente = gr_representante)
      
   from cobis..cl_grupo gr 
   join cobis..cc_oficial o on gr.gr_oficial = o.oc_oficial
   join cobis..cl_funcionario f on f.fu_funcionario = o.oc_funcionario
   and  gr_grupo = @i_grupo and gr_tipo = @i_gr_tipo
   
   
   if @@rowcount = 0
   begin
       exec sp_cerror
       @t_debug    = @t_debug,
       @t_file     = @t_file,
       @t_from     = @w_sp_name,
       @i_num      = 1720019
       return 1
   end
   
   return 0
   
   
end -- Fin Operacion S

if @i_operacion = 'V' -- Validacion de miembros
begin 
        
        --validaciones Presidente--
        select @numIntegrantesGrupo=count(cg_ente) from cobis..cl_cliente_grupo where cg_grupo=@i_grupo and cg_estado = 'V'
        if(@numIntegrantesGrupo<>0)
        begin
            if not exists (select 1 from cobis..cl_cliente_grupo 
                         where cg_rol    = 'P'
                           and cg_grupo  = @i_grupo 
                           and cg_estado = 'V')
            begin
            select @w_error =1720221  --Validación Presidente
              goto ERROR
            end                               
        end
        
        --validaciones SECRETARIO--
        if(@numIntegrantesGrupo<>0)
        begin
            if not exists (select 1 from cobis..cl_cliente_grupo 
                         where cg_rol = 'S'
                                         and cg_grupo = @i_grupo and cg_estado='V')
            begin
                select @w_error = 1720222  --Validación SECRETARIO
                  goto ERROR
            end                               
        end  
        
        --Validación Tesorero        
        if(@numIntegrantesGrupo<>0)
        begin
            if not exists (select 1 from cobis..cl_cliente_grupo 
                         where cg_rol    = 'T'
                           and cg_grupo  = @i_grupo 
                           and cg_estado = 'V')
            begin
              select @w_error = 1720223  --Validación Tesorero
              goto ERROR
            end                               
        end
    
    
end--Fin operacion V


if @i_operacion = 'M' -- Validacion de miembros
begin
    set  @o_actualiza_movil = 'S'
    declare @w_cod_act_ing int , @w_cod_act_eli int, @w_cod_act_apro int, @w_cod_act_actual int, @w_id_proceso int, @w_tramite int
    
    select @w_cod_act_ing = ac_codigo_actividad from cob_workflow..wf_actividad where ac_nombre_actividad = @w_parm_etap_ingreso
    select @w_cod_act_eli = ac_codigo_actividad from cob_workflow..wf_actividad where ac_nombre_actividad = @w_parm_etap_eliminar
    select @w_cod_act_apro = ac_codigo_actividad from cob_workflow..wf_actividad where ac_nombre_actividad = @w_parm_etap_aprobacion
    
    select @w_id_proceso = io_id_inst_proc,
           @w_tramite    = io_campo_3
    from   cob_workflow..wf_inst_proceso
    where  io_campo_1 = @i_grupo
    and    io_estado in ('EJE')
       and io_campo_7 = 'S'
    
    
    if @@rowcount > 0
    begin
        if (@w_id_proceso is not null or @w_id_proceso > 0)
        begin
            
            select top 1 @w_cod_act_actual = ia_codigo_act 
              from cob_workflow..wf_inst_actividad
            where  ia_id_inst_proc = @w_id_proceso
            order by ia_id_inst_act desc
            
        
            if(@w_cod_act_actual != @w_cod_act_ing )
            begin 
                set @o_actualiza_movil = 'N' -- Si es N desde el movil indica No se puede cambiar este grupo mientras tenga un tramite
            end 
        end
    end
end

if @i_operacion = 'F'
begin
   select c.codigo, c.valor, t.tabla
   into #tmp_cat
   from cobis..cl_catalogo c, cobis..cl_tabla t 
   where c.tabla = t.codigo 
   and (t.tabla = 'cl_vincula_grupo'
   or t.tabla = 'cl_tipo_grupo'
   or t.tabla = 'cl_estado_ser'
   or t.tabla = 'cl_oficina')
   
   set rowcount 20
   
   select distinct 
      gr_grupo,
      gr_nombre,
      gr_representante,
      'representante' = en_nomlar,
      gr_fecha_registro,
      gr_tipo_vinculacion,
      'Vinculacion'  = (select valor from #tmp_cat where codigo = gr_tipo_vinculacion and tabla = 'cl_vincula_grupo'),
      gr_tipo_grupo,
      'Tipo_Grupo'   = (select valor from #tmp_cat where codigo = gr_tipo_grupo and tabla = 'cl_tipo_grupo'),
      'Estado_Grupo' = (select valor from #tmp_cat where codigo = gr_estado and tabla = 'cl_estado_ser'),
      gr_dir_reunion,
      gr_dia_reunion,
      CONVERT(varchar(5),gr_hora_reunion,14) as [HH:MM],
      gr_sucursal,
      'sucursal'     = (select valor from #tmp_cat where codigo =  gr_sucursal and tabla = 'cl_oficina'),
      (select case (select isnull(max(op_cliente),0) from cob_cartera..ca_operacion 
                    where op_cliente  = gr_grupo 
                    and op_toperacion = 'GRUPAL' 
                    and op_estado IN (0,99))
      when 0 then gr_num_ciclo
      else gr_num_ciclo + 1
     end),
     'Nombre Oficial' = fu_nombre
   from cobis..cl_grupo with (nolock)
   inner join cobis.dbo.cl_cliente_grupo with (nolock) on cg_grupo         = gr_grupo 
   inner join cobis.dbo.cl_ente with (nolock) on en_ente = gr_representante 
   inner join cobis.dbo.cc_oficial co with (nolock) on gr_oficial = co.oc_oficial
   inner join cobis.dbo.cl_funcionario cf with (nolock) on cf.fu_funcionario = co.oc_funcionario 
   where gr_tipo         = @i_tipo_grupo
   and (gr_estado        = @i_estado     OR  @i_estado IS NULL)
   and (cg_ente          = @i_ente       OR @i_ente IS NULL)
   and (cg_rol           = @i_rol       OR @i_rol IS NULL)
   and cg_grupo > isnull(@i_grupo,0)
   order by gr_grupo
   set rowcount 0
end --fin operación F

select @w_sincroniza = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'HASIAU'

select @w_ofi_app = pa_smallint 
from cobis.dbo.cl_parametro cp 
where cp.pa_nemonico = 'OFIAPP'
and cp.pa_producto = 'CRE'

--Proceso de sincronizacion Grupos
if @i_operacion in ('I','U') and @i_grupo is not null and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
begin
   exec @w_error = cob_sincroniza..sp_sinc_json_groups
      @i_opcion     = 'I',
      @i_grupo      = @i_grupo,
      @t_debug      = @t_debug
end

return 0
ERROR:
    begin --Devolver mensaje de Error
        if @i_desde_fe = 'N'
        begin
            exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_num   = @w_error
        end
        return @w_error
    end
go
