/************************************************************************/
/*      Archivo:                miembro_grupo.sp                        */
/*      Stored procedure:       sp_miembro_grupo                        */
/*      Base de datos:          cobis                                   */
/*      Producto:               Clientes                                */
/*      Disenado por:           JMEG                                    */
/*      Fecha de escritura:     30-Abril-19                             */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial TOPAZ,          */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de TOPAZ TECHNOLOGIES S.L., sociedad constituida         */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   TOPAZ TECHNOLOGIES S.L. El incumplimiento de lo dispuesto          */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.”.             */

/************************************************************************/
/*                          PROPOSITO                                   */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*   FECHA           AUTOR     RAZON                                    */
/*   30/04/19        JMEG      Emision Inicial                          */
/*   18/05/20        MBA       Cambio nombre y compilacion BDD cobis    */
/*   12/06/20        FSAP      Estandarizacion de Clientes              */
/*   16/07/21        ACU       Validacion para no eliminar miembro      */
/*                             que sea presidente                       */
/*   03/07/21        ACA       Se elimina condición de actualización    */
/*   28/09/21        BDU       Se agrega consulta para servicio REST    */
/*   12/04/23        BDU       Se modifica operacion consulta REST      */
/*   03/05/23        BDU       Se comenta validacion miembros APP       */
/*   20/06/23        BDU       Validacion Presidente                    */
/*   24/07/23        BDU       Se deserta miembros en la cancelacion del*/
/*                             grupo R211803                            */
/*   09/09/23        BDU       R214440-Sincronizacion automatica        */
/*  03/10/23         EBA       Mejora control oficiales S911708-R216187 */
/*  01/12/23         BDU       R220651 Validacion operaciones vigentes  */
/*                             presidentes                              */
/*  18/12/23         BDU       R221684-Cambio registro TS               */
/*  22/01/24         BDU       R224055-Validar oficina app              */
/*  10/04/25         GRO       R264287-Fecha Actualizacion Junta Directiva*/
/************************************************************************/
use cobis
go

set ANSI_NULLS off
go

set QUOTED_IDENTIFIER off
go

if exists (select * from sysobjects where name = 'sp_miembro_grupo')
   drop proc sp_miembro_grupo
go

CREATE proc sp_miembro_grupo (
    @s_ssn                      int             = null,
    @s_sesn                     int             = null,
    @s_culture                  varchar(10)     = null,
    @s_user                     login           = null,
    @s_term                     varchar(30)     = null,
    @s_date                     datetime        = null,
    @s_srv                      varchar(30)     = null,
    @s_lsrv                     varchar(30)     = null,
    @s_ofi                      smallint        = null,
    @s_rol                      smallint        = NULL,
    @s_org_err                  char(1)         = NULL,
    @s_error                    int             = NULL,
    @s_sev                      tinyint         = NULL,
    @s_msg                      descripcion     = NULL,
    @s_org                      char(1)         = NULL,
    @t_show_version             bit             = 0,    -- Mostrar la version del programa
    @t_debug                    char(1)         = 'N',
    @t_file                     varchar(10)     = null,
    @t_from                     varchar(32)     = null,
    @t_trn                      int             = null,
	@i_operacion                char(1),                -- Opcion con que se ejecuta el programa
    @i_modo                     tinyint         = null, -- Modo de busqueda
    @i_tipo                     char(2)         = null, -- Tipo de consulta
    @i_filial                   tinyint         = null, -- Codigo de la filial
    @i_oficina                  smallint        = null, -- Codigo de la oficina
    @i_ente                     int             = null, -- Codigo del ente que forma parte del grupo
    @i_grupo                    int             = null, -- Codigo del grupo
    @i_usuario                  login           = null,
    @i_oficial                  int             = null, -- Codigo del oficial
    @i_fecha_asociacion         datetime        = null, -- Fecha de asociación del grupo--i_fecha_reg
    @i_rol                      catalogo        = null, -- Rol que desempeña el miembro de grupo
    @i_estado                   catalogo        = null, -- Estado del Grupo Economico
    @i_calif_interna            catalogo        = null, -- Calificacion Interna
    @i_fecha_desasociacion      datetime        = NULL, -- Fecha de desasociacion del grupo
    @i_cg_ahorro_voluntario     MONEY           = NULL,  -- ahorro voluntario nuevo campo
    @i_cg_lugar_reunion         VARCHAR(10)     = NULL,   -- nuevo campo lugar de reunion
    @i_cg_cuenta_individual     VARCHAR(45)     = NULL,
    @i_mantenimiento            int             = NULL,
    @i_tramite                  int             = NULL,
    @i_tipo_grupo               char(1)         = NULL,
    @i_ente_aux                 int             = NULL,
    @o_validacion_ahorros       int             = null out,
    @o_validacion_cartera       int             = null out,
    @o_mensaje                  varchar(255)    = null out,
    @o_resultado                int             = 0
)
as
declare @w_siguiente                int,
        @w_return                   int,
        @w_num_cl_gr                int,
        @w_contador                 int,
        @w_sp_name                  varchar(32),
        @w_sp_msg                   varchar(132),
        @w_error                    int,
        @w_ente                     int,
        @w_grupo                    int,
        @w_usuario                  login,
        @w_oficial                  int,
        @w_fecha_asociacion         datetime,
        @w_rol                      catalogo,
        @w_estado                   catalogo,
        @w_calif_interna            catalogo,
        @w_fecha_desasociacion      datetime,
        @v_ente                     int,
        @v_grupo                    int,
        @v_usuario                  login,
        @v_oficial                  int,
        @v_fecha_asociacion         datetime,
        @v_rol                      catalogo,
        @v_estado                   catalogo,
        @v_calif_interna            catalogo,
        @v_fecha_desasociacion      datetime,
        @v_cg_ahorro_voluntario     money,--nuevo campo ahorro voluntario
        @v_cg_lugar_reunion         varchar(10),-- nuevo campo lugar de reunion
        @w_tab_id_rol               int,
        @w_tab_id_calif             int,
        @w_tab_id_estado            int,
        @w_rol_desc                 descripcion,
        @w_estado_desc              descripcion,
        @w_calif_interna_desc       descripcion,
        @w_cliente_nomlar           varchar(254),
        @w_cg_ahorro_voluntario     money,--nuevo campo ahorro voluntario
        @w_cg_lugar_reunion         varchar(10),-- nuevo campo lugar de reunion
        @w_desc_direccion           varchar(254),
        @w_gr_tiene_ctain           char(1),
        @w_integrantes              int, --nuevo campo para validar numero de integrantes PXSG
        @cod_cli_presidente         int,--codigo de presidente
        @w_param_max_inte           int, --numero maximo de integrantes
        @w_calle                    as varchar(125),--para generar la dirección del grupo
        @w_casa                     as varchar (10),--para generar la dirección del grupo
        @w_descripcion              as varchar(125),--para generar la dirección del grupo
        @w_colonia                  as varchar(125),--para generar la dirección del grupo
        @w_municipio                as varchar(125),--para generar la dirección del grupo
        @w_estadoReu                as varchar(125),--para generar la dirección del grupo
        @w_num_meses_MESVCC         smallint,
        @w_fecha_proceso            datetime,
        @w_fecha_ini_param          datetime,
        @w_param_val_resp_min       int,
        @w_actualiza_movil          varchar(1),   
        @w_parm_ofi_movil           smallint,
        @w_fecha_desasociacion_aux  datetime,
        @w_validacion_ahorros       int,
        @w_validacion_cartera       int,
        @w_resultado                smallint,
        @w_tipo_relacion            int,
        @w_param_act                varchar(10),
        @w_codigo_tramite           int,
        @w_ssn                      int,
        @w_nomlar                   varchar(200),
        @w_msg                      varchar(300) = null,
        @w_rol_miembro              catalogo,
        --R216187 Validar que el oficial sea el mismo que del grupo
        @w_controlar_oficial        char(10),
        @w_oficial_ente             int,
        @w_oficial_grupo            int,
        -- R214440-Sincronizacion automatica
        @w_sincroniza               char(1),
        @w_cod_presi                int,
        @w_ofi_app                  smallint,
        --Quitar rp_ssn
        @w_cod_tramites             varchar(max)
        
select @w_sp_name = 'sp_miembro_grupo'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.2')
  print  @w_sp_msg
  return 0
end

if @t_trn != 172041
begin
    select @w_error = 1720075 -- TRANSACCION NO PERMITIDA
    goto ERROR
end

select @w_parm_ofi_movil = pa_smallint 
  from cobis..cl_parametro 
 where pa_producto = 'CRE' 
   and pa_nemonico = 'OFIAPP'

select @w_tab_id_rol = codigo 
  from cobis..cl_tabla 
 where tabla  = 'cl_rol_grupo'

 select @w_tipo_relacion = codigo 
  from cobis..cl_tabla 
 where tabla  = 'cl_vincula_grupo'

select @w_tab_id_calif = codigo 
  from cobis..cl_tabla 
 where tabla  = 'cl_calif_cliente'

select @w_tab_id_estado = codigo 
  from cobis..cl_tabla 
 where tabla = 'cl_estado_ambito'

-- Para opción S - modo 2(Individual) y 3 (Grupal)
select  @w_fecha_proceso    = fp_fecha   
  from cobis..ba_fecha_proceso

select @w_num_meses_MESVCC = pa_tinyint 
  from cobis..cl_parametro 
 where pa_producto = 'CRE' 
   and pa_nemonico = 'MESVCC'
   
select @w_controlar_oficial = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'CTROFG'
   
select @w_cod_presi = gr_representante
from cobis..cl_grupo
where gr_grupo = @i_grupo

select  @w_fecha_ini_param  = dateadd(mm, -1*@w_num_meses_MESVCC, @w_fecha_proceso)
select @w_nomlar = en_nomlar from cobis..cl_ente where en_ente = @i_ente
--Validaciones
if @i_operacion in ('I','D')
begin  --Inicio @i_operacion ('I','D')
   if exists (select (1) from cob_cartera..ca_operacion, cob_cartera..ca_estado, cob_credito..cr_tramite_grupal
               where op_estado = es_codigo
               and es_procesa = 'S'
               and op_cliente = @i_ente
               and op_operacion = tg_operacion
               and tg_grupo  <> @i_grupo) and @i_operacion = 'I'
   begin
      select @w_error = 1720611 --TIENE OPERACIONES PENDIENTES CON OTRO GRUPO
      goto ERROR
   end
   if exists (select (1) 
                from cob_cartera..ca_operacion, 
                     cob_cartera..ca_estado, 
                     cob_credito..cr_tramite_grupal
               where op_estado    = es_codigo
                 and es_procesa   = 'S'
                 and op_cliente   = @i_ente
                 and op_operacion = tg_operacion
                 and tg_grupo  = @i_grupo) 
                 and @i_operacion = 'D'
   begin
      select @w_error = 1720242 --TIENE OPERACIONES PENDIENTES EN ESTE GRUPO
      goto ERROR
   end
   
   -- INICIO DE DESASOCIACION
   /*
   if @i_tramite is null
   begin
   
      --Valida que no exista una solicitud en curso
      if exists (select 1 from cob_workflow..wf_inst_proceso
                 where io_campo_1 = @i_grupo
                 AND io_estado not in ('TER', 'CAN', 'SUS', 'ELI')
                 and io_campo_7 = 'S')
      begin       
         --print 'sp_mgp 1 Parametro ofi movil:' + convert(varchar(30),isnull(@w_parm_ofi_movil,0)) + '-oficina sesion:'+ convert(varchar(30),isnull(@s_ofi,0))
         if ( @s_ofi = @w_parm_ofi_movil)
         begin
            exec cobis..sp_grupo
                 @i_operacion       = 'M',
                 @i_grupo           = @i_grupo,
                 @t_trn             = 172036,
                 @o_actualiza_movil = @w_actualiza_movil OUTPUT
         --print 'sp_mb @w_actualiza_movil--' + @w_actualiza_movil + '--'
         if(@w_actualiza_movil = 'N')
         begin
            select @w_error = 1720236  --Error el grupo tiene un trámite en ejecución. 
            goto ERROR        
         end
      end
      else
      begin
         --print 'sp_mb -- Oficina Diferente a la de la movil'
         select @w_error = 1720236  --Error el grupo tiene un trámite en ejecución. 
         goto ERROR  
      end
   end
 
end
  */
/*No se va a validar debido a interfaz CAME*/
/*  
   if exists (select (1)
   from cobis..cl_cliente_grupo where cg_ente = @i_ente and cg_grupo = @i_grupo and cg_rol in ('P', 'T', 'S')) --Presidente, Tesorero y Secretario
   begin
      select @w_error = 149054 --MIEMBRO A MODIFICAR ES PARTE DE UNA DIRECTIVA EXISTENTE MODIFIQUE LOS MIEMBROS
      goto ERROR
   end
   */ 
   
end   --fin @i_operacion ('I','D')

/*No se va a validar debido a interfaz CAME*/

/*
if @i_rol in ('P', 'T', 'S') and @i_operacion in ('I', 'U')
begin
  if exists (select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_rol = @i_rol and @i_rol = 'P' AND @i_ente <> cg_ente and cg_estado = 'V') --Presidente
  begin
     select @w_error = 208914 --PRESIDENTE YA EXISTE EN EL GRUPO
     goto ERROR
  end

  if exists (select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_rol = @i_rol and @i_rol = 'T' AND @i_ente <> cg_ente and cg_estado = 'V') --Tesorero
  begin
     select @w_error = 208915 --TESORERO YA EXISTE EN EL GRUPO
     goto ERROR
  end
  
  if exists (select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_rol = @i_rol and @i_rol = 'S' AND @i_ente <> cg_ente and cg_estado = 'V') --Secretario
  begin
     select @w_error = 208935 --SECRETARIO YA EXISTE EN EL GRUPO
     goto ERROR
  end
end

if @i_rol in ('P', 'T') and @i_operacion in ('D')
begin
 if exists (select (1)
   from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_rol = 'P') --Presidente
   begin
      select @w_error = 208912 --DEBE DE EXISTIR UN SOLO PRESIDENTE
      goto ERROR
   end

   if exists (select (1)
   from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_rol = 'T') --Presidente
   begin
      select @w_error = 208913 --DEBE DE EXISTIR UN SOLO TESORERO
      goto ERROR
   end
end
*/

--Validación para que el oficial del grupo sea el mismo del integrante que se va a agregar o actualizar
if @i_operacion in ('I','U')
begin
   /*VALIDAR QUE EL GRUPO Y EL REPRESENTANTE PERTENEZCAN AL MISMO OFICIAL*/
   if @w_controlar_oficial = 'S'
   begin
      select @w_oficial_ente = en_oficial
        from cobis..cl_ente
       where en_ente = @i_ente

      select @w_oficial_grupo = gr_oficial
        from cobis..cl_grupo
       where gr_grupo = @i_grupo
      
      if @w_oficial_grupo <> @w_oficial_ente
      begin
         select @w_error = 1720650
         goto ERROR
      end     
   end
end

-- Insert --
if @i_operacion = 'I'
begin
     -- verificar que exista el grupo --
     if not exists (select 1 from cobis..cl_grupo where gr_grupo = @i_grupo)
     begin
        select @w_error = 1720052 -- No existe el grupo --
        goto ERROR
     end

    -- Verificacion que el ente existe
     if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente)
     begin
        select @w_error = 1720237 -- NO EXISTE EL MIEMBRO
        goto ERROR
     end
     
     -- Verificacion que el ente sea natural
     if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente and en_subtipo = 'P')
     begin
        select @w_error = 1720621 -- DEBE SER PERSONA NATURAL
        goto ERROR
     end

    --Verifica si existe el grupo y el ente
    if exists ( select 1 from cobis..cl_cliente_grupo where cg_ente = @i_ente and cg_grupo = @i_grupo and cg_fecha_desasociacion is null)
    begin
        select @w_error = 1720238 -- YA EXISTE EL MIEMBRO EN EL GRUPO
        goto ERROR
    end

    --Verifica si existe el miembro en otros grupos (no verifica desertores)
    if exists ( select 1 from cobis..cl_grupo, cobis..cl_cliente_grupo ccg  
                where gr_grupo = ccg.cg_grupo
                    and gr_tipo = @i_tipo_grupo
                    and cg_ente = @i_ente 
                    and cg_grupo != @i_grupo 
                    and (cg_fecha_desasociacion is null and cg_rol != 'D') --desertor
                    )
    begin
        select @w_error = 1720212 -- YA EXISTE EL MIEMBRO EN OTRO GRUPO --
        goto ERROR
    end
    
    --Validar rol
    if exists(select 1 from cobis.dbo.cl_cliente_grupo where cg_rol = 'P' and cg_estado = 'V' and @i_rol = 'P' and cg_grupo = @i_grupo)
    begin
       select @w_error = 1720665 -- validación presidente
       goto ERROR
    end
    
     --nuevas validaciones maximo 40--
    select @w_param_max_inte =pa_int 
      from cobis..cl_parametro 
     where pa_nemonico='MAXIGR' 
       AND pa_producto = 'CLI'
    
    select @w_integrantes  = count(cg_ente) from cobis..cl_cliente_grupo
    where cg_grupo = @i_grupo
    and cg_estado = 'V'
    
    if @w_integrantes  >= @w_param_max_inte
     begin
       select @w_error = 1720215 -- validación número de integrantes
        goto ERROR
     End

    --valida que solo un integrante tenga cg_lugar_reunion D o N--
    if exists ( select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_fecha_desasociacion is NULL AND cg_lugar_reunion IS NOT NULL AND @i_cg_lugar_reunion is NOT NULL)
    begin

        select @w_error = 1720239 -- YA EXISTE UN MIEMBRO CON LUGAR DE REUNION --
        goto ERROR
    end
  
  --Valida la fecha 
    if datediff(dd,@w_fecha_proceso,@i_fecha_asociacion) >0 or @i_fecha_asociacion is null
  begin
         SET @i_fecha_asociacion=@w_fecha_proceso
  end
   
    --actaliza  la fecha y el estado cuando la fecha es diferente de null--
    if exists ( select 1 from cobis..cl_cliente_grupo where cg_ente = @i_ente and cg_grupo = @i_grupo and cg_fecha_desasociacion is NOT null)
    begin
        update cobis..cl_cliente_grupo
        set cg_estado = 'V', cg_fecha_desasociacion=NULL,cg_ahorro_voluntario=@i_cg_ahorro_voluntario ,cg_lugar_reunion=@i_cg_lugar_reunion,
        cg_rol    = @i_rol
    where  cg_ente = @i_ente and cg_grupo = @i_grupo and cg_fecha_desasociacion is not null
    end
    else
    begin

        -- actualiza el grupo la fecha y el estado cuando la fecha es diferente de null
        --if exists ( select 1 from cobis..cl_cliente_grupo where cg_ente = @i_ente and cg_grupo != @i_grupo and cg_fecha_desasociacion is not null)
        --begin
        -- update cobis..cl_cliente_grupo
        -- set cg_estado ='V', cg_fecha_desasociacion=NULL, cg_grupo=@i_grupo,cg_ahorro_voluntario=@i_cg_ahorro_voluntario ,cg_lugar_reunion=@i_cg_lugar_reunion
        --where  cg_ente = @i_ente and cg_fecha_desasociacion is not null
        --end
    select @i_oficial = gr_oficial from cobis..cl_grupo where gr_grupo = @i_grupo

    /*Si el nuevo rol es P, T o S y si existe un registro con ese rol se debe modificar a M*/

    if exists (select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_rol = @i_rol and @i_rol in ('P','T','S'))
      begin
         -- Transaccion servicio - cl_cliente_grupo --
        insert into cobis..ts_cliente_grupo (secuencial, tipo_transaccion, clase,  --1
                                             srv,        lsrv,             ente,   --2
                                             grupo,      usuario,          terminal,--3
                                             oficial,    fecha_reg,        rol,     --4
                                             estado,     calif_interna,    fecha_desasociacion--5
                                             )
        values                              (@s_ssn,      172041,              'P',       --1
                                             @s_srv,      @s_lsrv,          @i_ente,   --2
                                             @i_grupo,    @s_user,          @s_term,   --3
                                             @i_oficial,  @i_fecha_asociacion, 'M', --4
                                             @i_estado,   @i_calif_interna, @i_fecha_desasociacion--5
                                             )
        -- Si no se puede insertar transaccion de servicio, error --
        if @@error != 0
        begin
            select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
            goto ERROR
        end
        
        update cobis..cl_cliente_grupo set cg_rol = 'M' where cg_grupo = @i_grupo and cg_rol = @i_rol and @i_rol in ('P','T','S')
        
        -- Si no se puede modificar, error --
        if @@rowcount = 0
        begin
          select @w_error = 1720246  --ERROR EN LA ACTUALIZACIÓN DEL MIEMBRO
          goto ERROR
        end
        
         -- Transaccion servicio - cl_cliente_grupo --
        insert into cobis..ts_cliente_grupo (secuencial, tipo_transaccion, clase,  --1
                                             srv,        lsrv,             ente,   --2
                                             grupo,      usuario,          terminal,--3
                                             oficial,    fecha_reg,        rol,     --4
                                             estado,     calif_interna,    fecha_desasociacion--5
                                             )
        values                              (@s_ssn,      172041,              'A',       --1
                                             @s_srv,      @s_lsrv,          @i_ente,   --2
                                             @i_grupo,    @s_user,          @s_term,   --3
                                             @i_oficial,  @i_fecha_asociacion, @i_rol, --4
                                             @i_estado,   @i_calif_interna, @i_fecha_desasociacion--5
                                             )
        -- Si no se puede insertar transaccion de servicio, error --
        if @@error != 0
        begin
            select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
            goto ERROR
        end
      end


        insert into cobis..cl_cliente_grupo (cg_ente,          cg_grupo,         cg_usuario,    --1
                                             cg_terminal,      cg_oficial,       cg_fecha_reg,  --2
                                             cg_rol,           cg_estado,        cg_calif_interna, --3
                                             cg_fecha_desasociacion, cg_ahorro_voluntario, cg_lugar_reunion--4                           --4
                                            )
        values                              (@i_ente,          @i_grupo,         @s_user,         --1
                                             @s_term,          @i_oficial,       @i_fecha_asociacion,--2
                                             @i_rol,           @i_estado,        @i_calif_interna,--3
                                             @i_fecha_desasociacion, @i_cg_ahorro_voluntario, @i_cg_lugar_reunion --4  --4
                                            )

        -- si no se puede insertar, error --
        if @@error != 0
        begin
            select @w_error = 1720241 -- ERROR EN INGRESO DEL MIEMBRO DE GRUPO
            goto ERROR
        end

        -- Transaccion servicio - cl_cliente_grupo --
        insert into cobis..ts_cliente_grupo (secuencial, tipo_transaccion, clase,  --1
                                             srv,        lsrv,             ente,   --2
                                             grupo,      usuario,          terminal,--3
                                             oficial,    fecha_reg,        rol,     --4
                                             estado,     calif_interna,    fecha_desasociacion--5
                                             )
        values                              (@s_ssn,      172041,              'N',       --1
                                             @s_srv,      @s_lsrv,          @i_ente,   --2
                                             @i_grupo,    @s_user,          @s_term,   --3
                                             @i_oficial,  @i_fecha_asociacion, @i_rol, --4
                                             @i_estado,   @i_calif_interna, @i_fecha_desasociacion--5
                                             )
        -- Si no se puede insertar transaccion de servicio, error --
        if @@error != 0
        begin
            select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
            goto ERROR
        end
    end -- caso contrario del update

  -- Para eliminar desde el movil
  --print 'sp_mgp 2 Parametro ofi movil:' + convert(varchar(30),isnull(@w_parm_ofi_movil,0)) + '-oficina sesion:'+ convert(varchar(30),isnull(@s_ofi,0))
    if ( @s_ofi = @w_parm_ofi_movil)
    begin
        exec cobis..sp_grupo
        @i_operacion       = 'M',
        @i_grupo           = @i_grupo,
        @t_trn             = 172036,   
        @o_actualiza_movil = @w_actualiza_movil OUTPUT
        
        if(@w_actualiza_movil = 'S')
        begin
            select @i_tramite = io_campo_3 from cob_workflow..wf_inst_proceso
          where io_campo_1 = @i_grupo
          and   io_estado  = 'EJE'    
               and io_campo_7 = 'S'     
        end
  end -- Fin para eliminar desde el movil
  
    --LGU-ini 22/ago/2017 AGREGAR CLIENTE A LA SOLICITUD
    if (@i_tramite is not null and @i_tramite <> 0) and exists(select 1 from cob_credito..cr_tramite 
                                                                        where tr_tramite = @i_tramite 
                                                                          and tr_estado  = 'N')
    begin
       if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite and tg_cliente = @i_ente)
       begin
           select @w_error = 2101002  -- REGISTRO YA EXISTE
           goto ERROR
       end
       insert into cob_credito..cr_tramite_grupal (
           tg_tramite,               tg_grupo,             tg_cliente,
           tg_monto,                 tg_grupal,            tg_operacion,
           tg_prestamo,                          
           tg_referencia_grupal,     tg_cuenta,            tg_cheque,
           tg_participa_ciclo,       tg_monto_aprobado,    tg_ahorro,
           tg_monto_max,             tg_bc_ln,             tg_incremento,
           tg_monto_ult_op,          tg_monto_max_calc,    tg_monto_min_calc,
           tg_destino,               tg_sector,            tg_monto_recomendado)
           select top 1
           tg_tramite,               tg_grupo,              @i_ente,
           0,                        'S',                   null,
           null,            
           tg_referencia_grupal,    null,                   null,
           'N',                     0,                      0,
           null,                    null,                   null,
           null,                    null,                   null,
           null,                    null,                   null
           from cob_credito..cr_tramite_grupal
           where tg_tramite = @i_tramite
           and   tg_participa_ciclo = 'S'
        
        -- Si no se puede insertar, error --
           if @@error != 0
           begin
              select @w_error = 263500 -- ERROR INGRESO DE REGISTRO
              goto ERROR
           end
        
        
        --Recuperar datos para insercion en las ts
            insert into cob_credito..ts_tramite_grupal                   
           (secuencial,             tipo_transaccion,      clase, 
            fecha,                  usuario,               terminal,           
            oficina,                tabla,                 lsrv, 
            srv,                    tramite,               grupo,                       
            cliente,                monto,                 grupal, 
            operacion,              prestamo,              referencia_grupal,
            cuenta,                 cheque,                participa_ciclo,
            monto_aprobado,         ahorro,                monto_max, 
            bc_ln,                  incremento,            monto_ult_op,
            monto_max_calc,         nueva_op,              monto_min_calc,
            conf_grupal,            destino,               sector, 
            monto_recomendado,      estado,                id_rechazo,
            descripcion_rechazo)        
            select top 1                   
            @s_ssn,                  21848,               'N',
            @s_date,                 @s_user,             @s_term,
            @s_ofi,                  'cr_tramite_grupal',          @s_lsrv,
            @s_srv,                  @i_tramite,          @i_grupo,
            tg_cliente,              0,                   'S',    
         (select op_operacion from cob_cartera..ca_operacion where op_tramite = @i_tramite),            
         tg_prestamo,             tg_referencia_grupal,
            tg_cuenta,               tg_cheque,           'N',
            0,                       0,   tg_monto_max, 
            null,                    null,                null,
            null,                    tg_nueva_op,         null,
            null,                    null,                null,
            null,                    null,                null,
            null 
            from cob_credito..cr_tramite_grupal
            where tg_tramite = @i_tramite
         --ERROR EN CREACION DE TRANSACCION DE SERVICIO
            if @@error <> 0 begin
               select @w_error = 1720049
               goto ERROR
            end
       
       if @@error <> 0
       begin
           select @w_error = 150000 -- ERROR EN INSERCION
           goto ERROR
       end
       end
       --LGU-fin AGREGAR CLIENTE A LA SOLICITUD

    select @w_gr_tiene_ctain = gr_tiene_ctain from cobis..cl_grupo where gr_grupo=@i_grupo
    IF ( @w_gr_tiene_ctain ='S')
    begin
        UPDATE cobis..cl_ente_aux   SET ea_cta_banco=@i_cg_cuenta_individual where ea_ente=@i_ente
    end

    --actualizar lugar de reunion cuando existe un lugar de reunion
    IF @i_cg_lugar_reunion is NOT NULL
    begin
       select  @w_calle        = di_calle,
            --@w_descripcion  = di_descripcion,
            --@w_casa         = di_casa,
            @w_colonia    = (select valor from cobis..cl_catalogo where codigo = di_parroquia
                                    and tabla = (select codigo from cobis..cl_tabla 
                                    where tabla = 'cl_parroquia')),
            @w_municipio    = (select valor from cobis..cl_catalogo where codigo = di_ciudad
                                    and tabla = (select codigo from cobis..cl_tabla 
                    where tabla = 'cl_ciudad')),
            @w_estadoReu    = (select valor from cobis..cl_catalogo where codigo = convert(varchar(10),di_provincia)
                                    and tabla = (select codigo from cobis..cl_tabla 
                                    where tabla = 'cl_provincia'))                  
       from cobis..cl_direccion where di_ente=@i_ente
              and di_tipo = @i_cg_lugar_reunion
       IF @@ROWCOUNT =0
       begin
            select @w_error = 1720243 -- ERROR: EL CLIENTE NO TIENE LA DIRECCIÓN
            goto ERROR
       end
    end
    ELSE
    begin
      
      SET @w_desc_direccion = ''

        IF(@w_calle is NOT NULL)
          SET @w_desc_direccion = ' CALLE '+@w_calle+', '

      IF(@w_colonia is NOT NULL)
          SET @w_desc_direccion = @w_desc_direccion + @w_colonia+', '

      IF(@w_municipio is NOT NULL)
          SET @w_desc_direccion = @w_desc_direccion + @w_municipio + ', '
            
            IF(@w_estadoReu is NOT NULL)
          SET @w_desc_direccion = @w_desc_direccion + @w_estadoReu
            

/*
            UPDATE cobis..cl_grupo
              SET gr_dir_reunion = @w_desc_direccion
                where gr_grupo = @i_grupo
*/
    end

    -- Actualizacion del grupo en el cliente
    update cobis..cl_ente set en_grupo = @i_grupo
    where  en_ente = @i_ente

--actualización en la cl_grupo cuando un miembro del grupo es presidente
   IF EXISTS (select 1 from cobis..cl_cliente_grupo where cg_grupo=@i_grupo and cg_rol='P')
   begin
   select @cod_cli_presidente=cg_ente from cobis..cl_cliente_grupo where cg_grupo=@i_grupo and cg_rol='P'
   
   UPDATE cobis..cl_grupo 
   SET gr_representante=@cod_cli_presidente,
       gr_fecha_modificacion=getdate()  --R264287
   where gr_grupo=@i_grupo

   end

end -- Fin Operacion I

if @i_operacion = 'U'
begin 

   -- verificar que exista el grupo --
   if not exists (select 1 from cobis..cl_grupo where gr_grupo = @i_grupo)
   begin
      select @w_error = 1720052 -- NO EXISTE GRUPO
      goto ERROR
   end
   
   --Verifica si existe el miembro en otros grupos (no verifica desertores)
   if exists ( select 1 from cobis..cl_grupo, cobis..cl_cliente_grupo ccg  
               where gr_grupo = ccg.cg_grupo
                   and gr_tipo = @i_tipo_grupo
                   and cg_ente = @i_ente 
                   and cg_grupo != @i_grupo 
                   and (cg_fecha_desasociacion is null and cg_rol != 'D') --desertor
                   )
   begin
       select @w_error = 1720212 -- YA EXISTE EL MIEMBRO EN OTRO GRUPO --
       goto ERROR
   end
      --Verifica que el miembro no tenga ya el rol de presidente
   /*
   if(@i_ente <> (select cg_ente from cl_cliente_grupo where cg_rol = 'P' and cg_grupo = @i_grupo))
   begin
      update cl_cliente_grupo set cg_rol = 'M' where cg_rol = 'P' and cg_grupo = @i_grupo
        if @@error != 0
        begin
           select @w_error = 1720246 -- ERROR EN LA ACTUALIZACION DEL MIEMBRO
           goto ERROR
        end
   end
   */
   
   set @i_fecha_asociacion = getdate()
   set @i_oficial = (select gr_oficial from cl_grupo where gr_grupo = @i_grupo)
   
   
   
   if @w_cod_presi is not null and ((@i_ente <> @w_cod_presi and @i_rol = 'P') or (@i_ente = @w_cod_presi and @i_rol <> 'P'))
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
   
   
   
   --Sino existe el miembro en el grupo lo agrega
   if not exists ( select 1 from cobis..cl_cliente_grupo where cg_ente = @i_ente and cg_grupo = @i_grupo)
   begin
      insert into cobis..cl_cliente_grupo (cg_ente,                cg_grupo,             cg_usuario,    --1
                                           cg_terminal,            cg_oficial,           cg_fecha_reg,  --2
                                           cg_rol,                 cg_estado,            cg_calif_interna, --3
                                           cg_fecha_desasociacion, cg_ahorro_voluntario, cg_lugar_reunion--4                           --4
                                            )
        values                              (@i_ente,                @i_grupo,                @s_user,         --1
                                             @s_term,                @i_oficial,              @i_fecha_asociacion,--2
                                             @i_rol,                 @i_estado,               @i_calif_interna,--3
                                             @i_fecha_desasociacion, @i_cg_ahorro_voluntario, @i_cg_lugar_reunion --4  --4
                                            )
      if @@error != 0
      begin
         select @w_error = 1720241 -- ERROR EN LA INSERCION DEL MIEMBRO
         goto ERROR
      end
      
       -- Transaccion servicio - cl_cliente_grupo --
      insert into cobis..ts_cliente_grupo (secuencial, tipo_transaccion, clase,  --1
                                            srv,        lsrv,             ente,   --2
                                            grupo,      usuario,          terminal,--3
                                            oficial,    fecha_reg,        rol,     --4 
                                            estado,     calif_interna,    fecha_desasociacion--5
                                            )
      values                               (@s_ssn,      172041,            'N',       --1
                                            @s_srv,      @s_lsrv,          @i_ente,   --2
                                            @i_grupo,    @s_user,          @s_term,   --3
                                            @i_oficial,  @v_fecha_asociacion, @i_rol, --4
                                            @i_estado,   @i_calif_interna, @i_fecha_desasociacion--5
                                            )
      -- Si no se puede insertar transaccion de servicio, error --
      if @@error != 0
      begin
         select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
         goto ERROR
      end
   
   end
      --Verifica si existe el grupo y el ente a modificar
   if not exists ( select 1 from cobis..cl_cliente_grupo where cg_ente = @i_ente and cg_grupo = @i_grupo)
   begin
      select @w_error = 1720244 -- NO EXISTE EL MIEMBRO EN EL GRUPO
      goto ERROR
   end
   
   select @w_param_act = pa_char from cl_parametro where pa_nemonico = 'NCMODI' and pa_producto = 'CLI'
   if @w_param_act = 'N'
   begin
      -- Prestamo vigente
      if exists ( select 1 from cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion
                  where tg_grupo = @i_grupo
                  and tg_cliente = @i_ente
                  and tg_operacion = op_operacion
                  and tg_monto   > 0
                  and op_estado  <>  3
                  )
      begin
           select @w_error = 1720622 -- TIENE OPERACIONES PENDIENTES
           goto VALIDAR_ERROR
      end
   end

    --valida que solo un integrante tenga  cg_lugar_reunion D o N--
   if exists ( select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_fecha_desasociacion is NULL and cg_lugar_reunion is NOT NULL and @i_cg_lugar_reunion is NOT NULL
   and cg_ente!=@i_ente)
   begin
       select @w_error = 1720239 -- YA EXISTE UN MIEMBRO CON LUGAR DE REUNION
       goto ERROR
   end

   --Valida la fecha 
   if datediff(dd,@w_fecha_proceso,@i_fecha_asociacion) >0 or @i_fecha_asociacion is null
   begin
      SET @i_fecha_asociacion=@w_fecha_proceso
   end 
   --Consulta de Datos
   select @w_ente                   = cg_ente,
          @w_grupo                  = cg_grupo,
          @w_usuario                = cg_usuario,
          @w_oficial                = cg_oficial,
          @w_fecha_asociacion       = cg_fecha_reg,
          @w_rol                    = cg_rol,
          @w_estado                 = cg_estado,
          @w_calif_interna          = cg_calif_interna,
          @w_fecha_desasociacion    = cg_fecha_desasociacion,
          @w_cg_ahorro_voluntario   = cg_ahorro_voluntario,
          @w_cg_lugar_reunion       = cg_lugar_reunion

   from  cobis..cl_cliente_grupo
   where cg_ente = @i_ente and cg_grupo = @i_grupo

   -- INI Guardar los datos anteriores que han cambiado --
   select @v_ente                 = @w_ente,
          @v_grupo                = @w_grupo,
          @v_usuario              = @w_usuario,
          @v_oficial              = @w_oficial,
          @v_fecha_asociacion     = @w_fecha_asociacion,
          @v_rol                  = @w_rol,
          @v_estado               = @w_estado,
          @v_calif_interna        = @w_calif_interna,
          @v_fecha_desasociacion  = @w_fecha_desasociacion,
          @v_cg_ahorro_voluntario = @w_cg_ahorro_voluntario,
          @v_cg_lugar_reunion     = @w_cg_lugar_reunion

   if @w_ente = @i_ente
        select @w_ente = null, @v_ente = null
   else
        select @w_ente = @i_ente

   if @w_grupo = @i_grupo
        select @w_grupo = null, @v_grupo = null
   else
        select @w_grupo = @i_grupo

   if @w_usuario = @i_usuario
        select @w_usuario = null, @v_usuario = null
   else
        select @w_usuario = @i_usuario

   if @w_oficial = @i_oficial
        select @w_oficial = null, @v_oficial = null
   else
        select @w_oficial = @i_oficial
        
   if @w_fecha_asociacion = @i_fecha_asociacion
        select @w_fecha_asociacion = null, @v_fecha_asociacion = null
   else
        select @w_fecha_asociacion = @i_fecha_asociacion

   if @w_rol = @i_rol
        select @w_rol = null, @v_rol = null
   else
        select @w_rol = @i_rol

   if @w_estado = @i_estado
        select @w_estado = null, @v_estado = null
   else
        select @w_estado = @i_estado

   if @w_calif_interna = @i_calif_interna
        select @w_calif_interna = null, @v_calif_interna = null
   else
        select @w_calif_interna = @i_calif_interna

   if @w_fecha_desasociacion = @i_fecha_desasociacion
        select @w_fecha_desasociacion = null, @v_fecha_desasociacion = null
   else
        select @w_fecha_desasociacion = @i_fecha_desasociacion

    -- Transaccion servicio - cl_cliente_grupo --
   insert into cobis..ts_cliente_grupo (secuencial, tipo_transaccion, clase,  --1
                                         srv,        lsrv,             ente,   --2
                                         grupo,      usuario,          terminal,--3
                                         oficial,    fecha_reg,        rol,     --4
                                         estado,     calif_interna,    fecha_desasociacion--5
                                         )
   values                              (@s_ssn,      172041,              'P',       --1
                                         @s_srv,      @s_lsrv,          @i_ente,   --2
                                         @i_grupo,    @s_user,          @s_term,   --3
                                         @v_oficial,  @v_fecha_asociacion, @v_rol, --4
                                         @v_estado,   @v_calif_interna, @v_fecha_desasociacion--5
                                         )
   -- Si no se puede insertar transaccion de servicio, error --
   if @@error != 0
   begin
      select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
      goto ERROR
   end
      --actualizar lugar de reunion cuando existe un lugar de reunion
   
   IF @i_cg_lugar_reunion is NOT NULL
   begin
      select  @w_calle        = di_calle,
            --@w_descripcion  = di_descripcion,
            --@w_casa         = di_casa,
            @w_colonia    = (select valor from cobis..cl_catalogo where codigo = di_parroquia
                                    and tabla = (select codigo from cobis..cl_tabla 
                      where tabla = 'cl_parroquia')),
            @w_municipio    = (select valor from cobis..cl_catalogo where codigo = di_ciudad
                                    and tabla = (select codigo from cobis..cl_tabla 
                                    where tabla = 'cl_ciudad')),
            @w_estadoReu    = (select valor from cobis..cl_catalogo where codigo = convert(varchar(10),di_provincia)
                                    and tabla = (select codigo from cobis..cl_tabla 
                                    where tabla = 'cl_provincia'))
      from cobis..cl_direccion where di_ente=@i_ente
              and di_tipo = @i_cg_lugar_reunion
      IF @@ROWCOUNT =0
      begin
         select @w_error = 1720243 -- ERROR: EL CLIENTE NO TIENE LA DIRECCIÓN
         goto ERROR
      end
   end
   ELSE
   begin
      SET @w_desc_direccion = ''

      IF(@w_calle is NOT NULL)
          SET @w_desc_direccion = ' CALLE '+@w_calle+', '

      IF(@w_colonia is NOT NULL)
          SET @w_desc_direccion = @w_desc_direccion + @w_colonia+', '

      IF(@w_municipio is NOT NULL)
          SET @w_desc_direccion = @w_desc_direccion + @w_municipio + ', '
            
      IF(@w_estadoReu is NOT NULL)
          SET @w_desc_direccion = @w_desc_direccion + @w_estadoReu
            /*
      UPDATE cobis..cl_grupo
      SET gr_dir_reunion = @w_desc_direccion
          where gr_grupo = @i_grupo
            */
   end
   

    -- Actualizacion de registros
  select   @w_fecha_desasociacion_aux = cg_fecha_desasociacion 
  from     cobis..cl_cliente_grupo
  where    cg_ente  = @i_ente 
  and      cg_grupo = @i_grupo
  
  --Prueba: Si desde la movil, se va a dar check despues de eliminar 
  --un integrante y este muestra un mensaje de error
  if(@w_fecha_desasociacion_aux is not null)
  begin
      select @i_estado = 'C'
  end

  /*Si el nuevo rol es P, T o S y si existe un registro con ese rol se debe modificar a M*/

  if exists (select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_rol = @i_rol and @i_rol in ('P','T','S'))
  begin
     update cobis..cl_cliente_grupo set cg_rol = 'M' where cg_grupo = @i_grupo and cg_rol = @i_rol 
     -- Si no se puede modificar, error --
     if @@rowcount = 0
     begin
       select @w_error = 1720246  --ERROR EN LA ACTUALIZACIÓN DEL MIEMBRO
       goto ERROR
     end
     
     insert into cobis..ts_cliente_grupo (secuencial, tipo_transaccion, clase,  --1
                                         srv,        lsrv,             ente,   --2
                                         grupo,      usuario,          terminal,--3
                                         oficial,    fecha_reg,        rol,     --4
                                         estado,     calif_interna,    fecha_desasociacion--5
                                         )
     values                              (@s_ssn,      172041,            'A',       --1
                                           @s_srv,      @s_lsrv,          @i_ente,   --2
                                           @i_grupo,    @s_user,          @s_term,   --3
                                           @i_oficial,  @i_fecha_asociacion, @i_rol, --4
                                           @i_estado,   @i_calif_interna, @i_fecha_desasociacion--5
                                           )
     -- Si no se puede insertar transaccion de servicio, error --
     if @@error != 0
     begin
        select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
        goto ERROR
     end
  end
  --Validacion de presidente solo se realiza en grupo solidario
  if exists(select 1 from cl_grupo where gr_grupo = @i_grupo and gr_tipo = 'S')
  begin
     if @i_rol not in ('P', 'D')
     begin
        if not exists (select 1 from cl_cliente_grupo where cg_grupo = @i_grupo and cg_rol = 'P' and cg_ente != @i_ente)
        begin
           select @w_error = 1720221  --DEBE EXISTIR UN PRESIDENTE
           goto ERROR
        end
     end
  end


  if @i_rol = 'D'
  begin
        update cobis..cl_cliente_grupo
    set  cg_rol                  = @i_rol,
         cg_estado               = 'C',
         cg_calif_interna        = @i_calif_interna,
         cg_ahorro_voluntario    = @i_cg_ahorro_voluntario,
         cg_lugar_reunion        = @i_cg_lugar_reunion,
         cg_fecha_reg            = @i_fecha_asociacion
    where  cg_ente = @i_ente and cg_grupo = @i_grupo

    -- Si no se puede modificar, error --
    if @@rowcount = 0
    begin
      select @w_error = 1720246  --ERROR EN LA ACTUALIZACIÓN DEL MIEMBRO
      goto ERROR
    end
    
    insert into cobis..ts_cliente_grupo (secuencial, tipo_transaccion, clase,  --1
                                         srv,        lsrv,             ente,   --2
                                         grupo,      usuario,          terminal,--3
                                         oficial,    fecha_reg,        rol,     --4
                                         estado,     calif_interna,    fecha_desasociacion--5
                                         )
    values                              (@s_ssn,      172041,            'A',       --1
                                          @s_srv,      @s_lsrv,          @i_ente,   --2
                                          @i_grupo,    @s_user,          @s_term,   --3
                                          @i_oficial,  @i_fecha_asociacion, @i_rol, --4
                                          'C',         @i_calif_interna, @i_fecha_desasociacion--5
                                          )
    -- Si no se puede insertar transaccion de servicio, error --
    if @@error != 0
    begin
       select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
       goto ERROR
    end
     
  end
  else
  begin
     if(@i_rol = 'P' or @i_mantenimiento = 1)
     begin
        set @cod_cli_presidente = (select gr_representante from cl_grupo where gr_grupo = @i_grupo)
        --Se actualiza el representante del grupo
        insert into cobis..ts_grupo  (secuencial,       tipo_transaccion,       clase,                 fecha,    --1
                                      terminal,         srv,                    lsrv,                            --2
                                      grupo,            nombre,                 representante,         compania, --3
                                      oficial,          fecha_registro,         fecha_modificacion,    ruc,      --4                      
                                      vinculacion,      tipo_vinculacion,       max_riesgo,            riesgo,   --5                      
                                      usuario,          reservado,              tipo_grupo,            estado,   --6                      
                                      dir_reunion,      dia_reunion,            hora_reunion,          comportamiento_pago,--7                      
                                      num_ciclo,        gar_liquida)
        select                        @s_ssn,           172038,                 'P',                   @s_date,   --1
                                      @s_term,          @s_srv,                 @s_lsrv,                          --2
                                      gr_grupo,         gr_nombre,              gr_representante,      gr_compania,  --3
                                      gr_oficial,       gr_fecha_registro,      getdate(),             gr_ruc,       --4
                                      gr_vinculacion,   gr_tipo_vinculacion,    gr_max_riesgo,         gr_riesgo,    --5
                                      gr_usuario,       gr_reservado,           gr_tipo_grupo,         gr_estado,    --6
                                      gr_dir_reunion,   gr_dia_reunion,         gr_hora_reunion,       gr_comportamiento_pago,--7
                                      gr_num_ciclo  ,   isnull(gr_gar_liquida,'S')                                                         --8
        from cl_grupo where gr_grupo = @i_grupo
                                     
        -- si no se puede insertar, error --
        if @@error != 0
        begin
            select @w_error = 1720049  --ERROR EN CREACION DE TRANSACCION DE SERVICIO
            goto ERROR      
        end
        update cobis..cl_grupo set gr_representante = @i_ente where gr_grupo = @i_grupo
         if @@error != 0
        begin
           select @w_error = 1720246 -- ERROR EN LA ACTUALIZACION DEL MIEMBRO
           goto ERROR
        end
        insert into cobis..ts_grupo  (secuencial,       tipo_transaccion,       clase,                 fecha,    --1
                                      terminal,         srv,                    lsrv,                            --2
                                      grupo,            nombre,                 representante,         compania, --3
                                      oficial,          fecha_registro,         fecha_modificacion,    ruc,      --4                      
                                      vinculacion,      tipo_vinculacion,       max_riesgo,            riesgo,   --5                      
                                      usuario,          reservado,              tipo_grupo,            estado,   --6                      
                                      dir_reunion,      dia_reunion,            hora_reunion,          comportamiento_pago,--7                      
                                      num_ciclo,        gar_liquida)
        select                        @s_ssn,           172038,                 'A',                   @s_date,   --1
                                      @s_term,          @s_srv,                 @s_lsrv,                          --2
                                      gr_grupo,         gr_nombre,              gr_representante,      gr_compania,  --3
                                      gr_oficial,       gr_fecha_registro,      getdate(),             gr_ruc,       --4
                                      gr_vinculacion,   gr_tipo_vinculacion,    gr_max_riesgo,         gr_riesgo,    --5
                                      gr_usuario,       gr_reservado,           gr_tipo_grupo,         gr_estado,    --6
                                      gr_dir_reunion,   gr_dia_reunion,         gr_hora_reunion,       gr_comportamiento_pago,--7
                                      gr_num_ciclo  ,   isnull(gr_gar_liquida,'S')                                                         --8
        from cl_grupo where gr_grupo = @i_grupo
                                     
        -- si no se puede insertar, error --
        if @@error != 0
        begin
            select @w_error = 1720049  --ERROR EN CREACION DE TRANSACCION DE SERVICIO
            goto ERROR      
        end
        --Se vuelve miembro normal el representante antiguo del grupo
        if(@i_ente <> @cod_cli_presidente)
        begin
           select @w_param_act = pa_char from cl_parametro where pa_nemonico = 'NCMODI' and pa_producto = 'CLI'
           if @w_param_act = 'N'
           begin
              -- Prestamo vigente
              if exists ( select 1 from cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion
                          where tg_grupo = @i_grupo
                          and tg_cliente = @cod_cli_presidente
                          and tg_operacion = op_operacion
                          and tg_monto   > 0
                          and op_estado  <>  3
                          )
              begin
                   select @w_nomlar = en_nomlar from cobis..cl_ente where en_ente = @cod_cli_presidente
                   select @w_error = 1720622 -- TIENE OPERACIONES PENDIENTES
                   goto VALIDAR_ERROR
              end
           end
           select @w_rol_miembro = pa_char from cobis..cl_parametro where pa_nemonico = 'ROINGR' and pa_producto = 'CLI'
           update cobis..cl_cliente_grupo
           set cg_rol                  = @w_rol_miembro,
               cg_estado               = 'V'
           where  cg_ente  = @cod_cli_presidente 
              and cg_grupo = @i_grupo
            if @@error != 0
            begin
               select @w_error = 1720246 -- ERROR ACTUALIZACION DE MIEMBRO
               goto ERROR
            end
            
            insert into cobis..ts_cliente_grupo (secuencial,   tipo_transaccion,    clase,  --1
                                                 srv,          lsrv,                ente,   --2
                                                 grupo,        usuario,             terminal,--3
                                                 oficial,      fecha_reg,           rol,     --4
                                                 estado,       calif_interna,       fecha_desasociacion--5
                                                 )
            values                              (@s_ssn,       172041,              'A',       --1
                                                 @s_srv,       @s_lsrv,             @cod_cli_presidente,   --2
                                                 @i_grupo,     @s_user,             @s_term,   --3
                                                 @i_oficial,   @i_fecha_asociacion, @i_rol, --4
                                                 'V',          @i_calif_interna,    getdate()--5
                                                 )          
            -- si no se puede insertar, error --
            if @@error != 0
            begin
                select @w_error = 1720049  --ERROR EN CREACION DE TRANSACCION DE SERVICIO
                goto ERROR      
            end
                    
                
        end
     end
     
     insert into cobis..ts_cliente_grupo (secuencial,   tipo_transaccion,    clase,  --1
                                          srv,          lsrv,                ente,   --2
                                          grupo,        usuario,             terminal,--3
                                          oficial,      fecha_reg,           rol,     --4
                                          estado,       calif_interna,       fecha_desasociacion--5
                                          )
     select                               @s_ssn,       172041,              'P',       --1
                                          @s_srv,       @s_lsrv,             cg_ente,   --2
                                          cg_grupo,     @s_user,             @s_term,   --3
                                          cg_oficial,   cg_fecha_reg,        cg_rol, --4
                                          cg_estado,    cg_calif_interna,    cg_fecha_desasociacion--5
     from cl_cliente_grupo where cg_grupo = @i_grupo                                   
     -- si no se puede insertar, error --
     if @@error != 0
     begin
         select @w_error = 1720049  --ERROR EN CREACION DE TRANSACCION DE SERVICIO
         goto ERROR      
     end
     update cobis..cl_cliente_grupo
     set cg_rol                  = @i_rol,
         cg_estado               = 'V',
         cg_fecha_desasociacion  = null,
         cg_calif_interna        = @i_calif_interna,
         cg_ahorro_voluntario    = @i_cg_ahorro_voluntario,
         cg_lugar_reunion        = @i_cg_lugar_reunion,
         cg_fecha_reg            = @i_fecha_asociacion
     where  cg_ente = @i_ente and cg_grupo = @i_grupo

     -- Si no se puede modificar, error --
     if @@error != 0
     begin
       select @w_error = 1720246  --ERROR EN LA ACTUALIZACIÓN DEL MIEMBRO
       goto ERROR
     end
     
     insert into cobis..ts_cliente_grupo (secuencial,   tipo_transaccion,    clase,  --1
                                          srv,          lsrv,                ente,   --2
                                          grupo,        usuario,             terminal,--3
                                          oficial,      fecha_reg,           rol,     --4
                                          estado,       calif_interna,       fecha_desasociacion--5
                                          )
     select                               @s_ssn,       172041,              'A',       --1
                                          @s_srv,       @s_lsrv,             cg_ente,   --2
                                          cg_grupo,     @s_user,             @s_term,   --3
                                          cg_oficial,   cg_fecha_reg,        cg_rol, --4
                                          cg_estado,    cg_calif_interna,    cg_fecha_desasociacion--5
     from cl_cliente_grupo where cg_grupo = @i_grupo                                   
     -- si no se puede insertar, error --
     if @@error != 0
     begin
         select @w_error = 1720049  --ERROR EN CREACION DE TRANSACCION DE SERVICIO
         goto ERROR      
     end
     
  end
  


    select @w_gr_tiene_ctain = gr_tiene_ctain from cobis..cl_grupo where gr_grupo=@i_grupo
     --PRINT ('-----------------------cuenta individual////@w_gr_tiene_ctain:')+ CONVERT(varchar(30),@w_gr_tiene_ctain)
     IF ( @w_gr_tiene_ctain ='S')
    begin
    UPDATE cobis..cl_ente_aux   SET ea_cta_banco=@i_cg_cuenta_individual where ea_ente=@i_ente
    end

    -- Transaccion servicio - cl_cliente_grupo --
    insert into cobis..ts_cliente_grupo (secuencial, tipo_transaccion, clase,  --1
                                         srv,        lsrv,             ente,   --2
                                         grupo,      usuario,          terminal,--3
                                         oficial,    fecha_reg,        rol,     --4
                                         estado,     calif_interna,    fecha_desasociacion--5
                                         )
    values                              (@s_ssn,      172041,              'A',       --1
                                         @s_srv,      @s_lsrv,          @i_ente,   --2
                                         @i_grupo,    @s_user,          @s_term,   --3
                                         @w_oficial,  @w_fecha_asociacion, @w_rol, --4
                                         @w_estado,   @w_calif_interna, @w_fecha_desasociacion--5
                                         )
    -- Si no se puede insertar transaccion de servicio, error --
    if @@error != 0
    begin
        exec cobis..sp_cerror
             @t_debug        = @t_debug,
             @t_file         = @t_file,
             @t_from         = @w_sp_name,
             @i_num          = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
        return 1
    end

    --actualización en la cl_grupo cuando un miembro del grupo es presidente
   IF EXISTS (select 1 from cobis..cl_cliente_grupo where cg_grupo=@i_grupo and cg_rol='P')
   begin
   select @cod_cli_presidente=cg_ente from cobis..cl_cliente_grupo where cg_grupo=@i_grupo and cg_rol='P'
   UPDATE cobis..cl_grupo 
   SET gr_representante=@cod_cli_presidente ,
       gr_fecha_modificacion=getdate()  --R264287
   where gr_grupo=@i_grupo
   
   end
end -- Fin Operacion U

if @i_operacion = 'D' -- Desasignar
begin 

      /*Validamos que se pueda vincular/desvincular AHORROS*/
   
  exec @w_return = cob_interface..sp_valida_vinc
    @s_ssn                  = @s_ssn,
    @s_user                 = @s_user,
    @s_term                 = @s_term,
    @s_sesn                 = @s_sesn,
    @s_culture              = @s_culture,
    @s_date                 = @s_date,
    @s_srv                  = @s_srv,
    @s_lsrv                 = @s_lsrv,
    @s_rol                  = @s_rol,
    @s_org_err              = @s_org_err,
    @s_error                = @s_error,
    @s_sev                  = @s_sev,
    @s_msg                  = @s_msg,
    @s_org                  = @s_org,
    @s_ofi                  = @s_ofi ,
    @t_debug                = 'N',
    @t_file                 = @t_file,
    @t_from                 = @t_from,
    @t_trn                  = 2239,
    @t_show_version         = 0,   
    @i_cod_grupo            = @i_grupo ,
    @i_cod_cliente          = @i_ente,
    @o_resultado            = @o_resultado out

    select @w_resultado = @o_resultado

    if (@w_resultado <> 0)

      begin
         exec cobis..sp_cerror
        /* No se puede desvincular el cliente */
         @t_debug= @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num   = @w_return
         return @w_return
       end

     -- verificar que exista el grupo --
     if not exists (select 1 from cobis..cl_grupo where gr_grupo = @i_grupo)
     begin
         select @w_error = 1720052 -- NO EXISTE GRUPO
         goto ERROR
     end

    --Verifica si existe el grupo y el ente a modificar
    if not exists ( select 1 from cobis..cl_cliente_grupo where cg_ente = @i_ente and cg_grupo = @i_grupo)
    begin
         select @w_error = 1720244 -- NO EXISTE EL MIEMBRO EN EL GRUPO A MODIFICAR
         goto ERROR
    end

   if exists (select 1 from cobis..cl_grupo where gr_grupo = @i_grupo and gr_representante = @i_ente)
   begin
      select @w_error = 1720527 --NO SE PUEDE ELIMINAR EL CLIENTE PRINCIPAL
      goto ERROR
   end

   if exists (select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_ente = @i_ente and cg_rol = 'T')
   begin
      select @w_error = 1720518 --EL CLIENTE ES TESORERO
      goto ERROR
   end

    --Consulta de Datos
    select @w_ente                = cg_ente,
           @w_grupo               = cg_grupo,
           @w_usuario             = cg_usuario,
           --@w_terminal          = cg_terminal,
           @w_oficial             = cg_oficial,
           @w_fecha_asociacion    = cg_fecha_reg,
           @w_rol                 = cg_rol,
           @w_estado              = cg_estado,
           @w_calif_interna       = cg_calif_interna,
           @w_fecha_desasociacion = cg_fecha_desasociacion
           --@w_tipo_relacion     = cg_tipo_relacion
    from  cobis..cl_cliente_grupo
    where cg_ente = @i_ente and cg_grupo = @i_grupo
    
    
      -- Operaciones pendientes
      if exists (select 1 from cob_credito..cr_tramite,
                               cob_credito..cr_tramite_grupal,
                               cob_workflow..wf_inst_proceso
                 where tr_tramite = tg_tramite
                 and io_campo_3 = tr_tramite
                 and io_estado not in ('TER', 'CAN')
                 and tg_participa_ciclo = 'S'
                 and tg_cliente = @i_ente)
      begin
         select @w_error = 1720623 -- TIENE OPERACIONES PENDIENTES
         goto VALIDAR_ERROR
      end
      
    if exists (select 1 from cob_cartera..ca_operacion
               where op_cliente = @i_ente
               and   op_estado  not in (0,99,3,6)
               and   op_grupal = 'S'
               and   op_operacion in (select tg_operacion 
                                      from cob_credito..cr_tramite_grupal 
                                      where tg_grupo = @i_grupo))
    begin
         select @w_error = 1720623 -- TIENE OPERACIONES PENDIENTES
         goto VALIDAR_ERROR
    end
  -- INICIO DE DESASOCIACION
    begin tran
      -- desasignar en ente del grupo --
        update cobis..cl_cliente_grupo
        set    cg_fecha_desasociacion = @s_date,
               cg_estado              = @i_estado
        from   cobis..cl_cliente_grupo
        where  cg_ente = @i_ente and cg_grupo = @i_grupo
        -- si no se puede desasignar, error --
        if @@rowcount != 1
        begin
             select @w_error = 1720248 -- ERROR EN DESASIGNACION DE GRUPO
             goto ERROR
        end
        select  @w_ssn= @s_ssn
        
        /* transaccion de servicio - antes */
        insert into cobis..ts_persona_prin (
        secuencia,             tipo_transaccion,          clase,                     fecha,                  usuario,
        terminal,              srv,                       lsrv,                      persona,                nombre,
        p_apellido,            s_apellido,                sexo,                      cedula,                 tipo_ced,
        pais,                  profesion,                 estado_civil,              actividad,              num_cargas,
        nivel_ing,             nivel_egr,                 tipo,                      filial,                 oficina,
        fecha_nac,             grupo,                     oficial,                   comentario,             retencion,
        fecha_mod,             fecha_expira,              ciudad_nac,                calif_cliente,          s_nombre, 
        c_apellido,            secuen_alterno,            tipo_vinculacion,          pais_nac,               provincia_nac,
        naturalizado,          forma_migratoria,          nro_extranjero,            calle_orig,             exterior_orig,
        estado_orig,           localidad,                 hora)
        select
        @w_ssn,                172003,                    'P',                        @s_date,                 @s_user,
        @s_term,               @s_srv,                    @s_lsrv,                    en_ente,                 en_nombre,
        p_p_apellido,          p_s_apellido,              p_sexo,                     en_ced_ruc,              en_tipo_ced,
        null,                  p_profesion,               p_estado_civil,             en_actividad,            null,
        null,                  en_grupo,                  en_subtipo,                 en_filial,               en_oficina,
        p_fecha_nac,           null,                      en_oficial,                 en_comentario,           null,
        null,                  en_fecha_mod,              p_ciudad_nac,               en_calif_cartera,        p_s_nombre,
        p_c_apellido,          en_ente,                   en_tipo_vinculacion,        en_pais_nac,             en_provincia_nac,
        en_naturalizado,       en_forma_migratoria,       en_nro_extranjero,          en_calle_orig,           en_exterior_orig,
        en_estado_orig,        en_localidad,              getdate()
        from cobis..cl_ente
        where en_ente = @i_ente

        update cobis..cl_ente
        set    en_grupo = null
        where  en_ente   = @i_ente
        and    en_grupo  = @i_grupo
        
        
        /* transaccion de servicio - despues */
        insert into cobis..ts_persona_prin (
        secuencia,             tipo_transaccion,          clase,                     fecha,                  usuario,
        terminal,              srv,                       lsrv,                      persona,                nombre,
        p_apellido,            s_apellido,                sexo,                      cedula,                 tipo_ced,
        pais,                  profesion,                 estado_civil,              actividad,              num_cargas,
        nivel_ing,             nivel_egr,                 tipo,                      filial,                 oficina,
        fecha_nac,             grupo,                     oficial,                   comentario,             retencion,
        fecha_mod,             fecha_expira,              ciudad_nac,                calif_cliente,          s_nombre, 
        c_apellido,            secuen_alterno,            tipo_vinculacion,          pais_nac,               provincia_nac,
        naturalizado,          forma_migratoria,          nro_extranjero,            calle_orig,             exterior_orig,
        estado_orig,           localidad,                 hora)
        select
        @w_ssn,                172003,                    'A',                        @s_date,                 @s_user,
        @s_term,               @s_srv,                    @s_lsrv,                    en_ente,                 en_nombre,
        p_p_apellido,          p_s_apellido,              p_sexo,                     en_ced_ruc,              en_tipo_ced,
        null,                  p_profesion,               p_estado_civil,             en_actividad,            null,
        null,                  en_grupo,                  en_subtipo,                 en_filial,               en_oficina,
        p_fecha_nac,           null,                      en_oficial,                 en_comentario,           null,
        null,                  en_fecha_mod,              p_ciudad_nac,               en_calif_cartera,        p_s_nombre,
        p_c_apellido,          en_ente,                   en_tipo_vinculacion,        en_pais_nac,             en_provincia_nac,
        en_naturalizado,       en_forma_migratoria,       en_nro_extranjero,          en_calle_orig,           en_exterior_orig,
        en_estado_orig,        en_localidad,              getdate()
        from cobis..cl_ente
        where en_ente = @i_ente
      
      
      select @w_cod_tramites = STRING_AGG(convert(varchar(max), tg_tramite),',')
      from cob_credito..cr_tramite_grupal
      where tg_cliente         = @i_ente 
      and   tg_participa_ciclo = 'N'
      and   tg_grupo           = @i_grupo
      
      
      insert into cob_credito..ts_tramite_grupal                   
     (secuencial,             tipo_transaccion,      clase, 
      fecha,                  usuario,               terminal,           
      oficina,                tabla,                 lsrv, 
      srv,                    tramite,               grupo,                       
      cliente,                monto,                 grupal, 
      operacion,              prestamo,              referencia_grupal,
      cuenta,                 cheque,                participa_ciclo,
      monto_aprobado,         ahorro,                monto_max, 
      bc_ln,                  incremento,            monto_ult_op,
      monto_max_calc,         nueva_op,              monto_min_calc,
      conf_grupal,            destino,               sector, 
      monto_recomendado,      estado,                id_rechazo,
      descripcion_rechazo)  
      select top 1                   
      @s_ssn,                  21846,               'B',
      @s_date,                 @s_user,             @s_term,
      @s_ofi,                  'cr_tramite_grupal', @s_lsrv,
      @s_srv,                  @w_codigo_tramite,   @i_grupo,
      tg_cliente,              tg_monto,            tg_grupal, 
      tg_operacion,            tg_prestamo,         tg_referencia_grupal,
      tg_cuenta,               tg_cheque,           tg_participa_ciclo,
      tg_monto_aprobado,       tg_ahorro,           tg_monto_max, 
      tg_bc_ln,                tg_incremento,       tg_monto_ult_op,
      tg_monto_max_calc,       tg_nueva_op,         tg_monto_min_calc,
      tg_conf_grupal,          tg_destino,          tg_sector, 
      tg_monto_recomendado,    tg_estado,           tg_id_rechazo,
      @w_cod_tramites 
      from cob_credito..cr_tramite_grupal with (nolock)
      where tg_cliente       = @i_ente 
      and tg_grupo           = @i_grupo
      and tg_participa_ciclo = 'N'
      
      --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      if @@error <> 0 begin
         select @w_error = 1720049
         goto ERROR
      end
      
      
      --Borrar de la solicitudes al ente
      declare cursor_cliente cursor read_only 
      for select tg_tramite  
      from cob_credito..cr_tramite_grupal with (nolock)
      where tg_cliente         = @i_ente 
      and   tg_participa_ciclo = 'N'
      and   tg_grupo           = @i_grupo
      
      open cursor_cliente
      fetch next from cursor_cliente into @w_codigo_tramite
      while @@fetch_status = 0
      begin
         delete cob_credito..cr_tramite_grupal
         where tg_tramite         = @w_codigo_tramite
         and   tg_cliente         = @i_ente
         and   tg_participa_ciclo = 'N'
         
         -- Si no se puede insertar transaccion de servicio, error --
         if @@error != 0
         begin
            close cursor_cliente
            deallocate cursor_cliente
            select @w_error = 1720431 -- ERROR EN ELIMINAR REGISTRO
            goto ERROR
         end
         
         fetch next from cursor_cliente into @w_codigo_tramite
      end
      close cursor_cliente
      deallocate cursor_cliente
      
      
      /* NO BORRAR SOLO SE DEJA COMENTADO PORQUE NO APLICA PARA ENLACE
      -- Para eliminar desde el movil
      --print 'sp_mgp 3 Parametro ofi movil:' + convert(varchar(30),isnull(@w_parm_ofi_movil,0)) + '-oficina sesion:'+ convert(varchar(30),isnull(@s_ofi,0))
        if ( @s_ofi = @w_parm_ofi_movil)
        begin 
            exec cobis..sp_grupo
            @i_operacion       = 'M',
            @i_grupo           = @i_grupo,
            @t_trn             = 172082,     
            @o_actualiza_movil = @w_actualiza_movil OUTPUT
            
            if(@w_actualiza_movil = 'S')
            begin
                select @i_tramite = io_campo_3 from cob_workflow..wf_inst_proceso
              where io_campo_1 = @i_grupo
              and   io_estado  = 'EJE'
           and io_campo_7 = 'S'
      
            end
        end -- Fin para eliminar desde el movil 
        */
      --LGU-ini 22/ago/2017 eliminar cliente de la solcitud
        if @i_tramite is not null
        begin
        exec @w_return = cob_credito..sp_grupal_monto
                @s_ssn       = @s_ssn ,
                @s_rol       = @s_rol ,
                @s_ofi       = @s_ofi ,
                @s_sesn      = @s_sesn ,
                @s_user      = @s_user ,
                @s_term      = @s_term ,
                @s_date      = @s_date ,
                @s_srv       = @s_srv ,
                @s_lsrv      = @s_lsrv ,
                @i_operacion = 'D',
                @i_tramite   = @i_tramite,
                @i_ente      = @i_ente
                
                if @w_return <> 0
                begin
                    select @w_error = 1720242 --
                    goto ERROR
                end
        --LGU-fin eliminar cliente de la solcitud
      if exists (select 1 from   cob_cartera..ca_garantia_liquida where gl_tramite = @i_tramite)
      begin
              /*Se agrega el codigo para la devolucion de la garantia liquida*/
              exec @w_return     = cob_custodia..sp_contabiliza_garantia
              @s_date            = @s_date,
              @s_user            = @s_user,
              @s_ofi             = @s_ofi ,
              @s_term            = @s_term,
              @i_operacion       = 'PD',
              @i_tramite         = @i_tramite,
              @i_ente            = @i_ente,
              @i_grupo           = @i_grupo
              if @@error != 0
              begin
                select @w_error = 1720249 -- ERROR EN LA ACTUALIZACION DEL REGISTRO
                goto ERROR
              end
      end
    
        end
        -- Transaccion servicio - ts_cliente_grupo --
        insert into cobis..ts_cliente_grupo (secuencial, tipo_transaccion, clase,  --1
                                             srv,        lsrv,             ente,   --2
                                             grupo,      usuario,          terminal,--3
                                             oficial,    fecha_reg,        rol,     --4
                                             estado,     calif_interna,    fecha_desasociacion--5
                                             )
        values                              (@s_ssn,      172041,           'B',       --1
                                             @s_srv,      @s_lsrv,          @i_ente,   --2
                                             @i_grupo,    @s_user,          @s_term,   --3
                                             @w_oficial,  @s_date,          @w_rol, --4
                                             @w_estado,   @w_calif_interna, @w_fecha_desasociacion--5
                                             )
        -- Si no se puede insertar transaccion de servicio, error --
        if @@error != 0
        begin
            select @w_error = 1720049 -- ERROR EN CREACION DE TRANSACCION DE SERVICIO
            goto ERROR
        end
    UPDATE cobis..cl_grupo --R264287
    SET gr_fecha_modificacion=getdate()  
    where gr_grupo=@i_grupo
	
		
    commit tran
end -- FIN OPCION D

if @i_operacion = 'S'
begin

    --set rowcount 20
    if @i_modo = 0
    begin
        select 'Ente'       = cg_ente,
               'Id_Grupo'   = cg_grupo,
               'Fecha_Aso'  = cg_fecha_reg,
               'Rol'        = cg_rol,
               'Estado'     = cg_estado,
               'Cal_Interna'= (ISNULL(p_calif_cliente,'')),
               'Fecha_Desasociacion' = cg_fecha_desasociacion,
               'Nombre_Cliente'      = en_nomlar,
               'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
               'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
               'Cal_Interna'         = (ISNULL(p_calif_cliente,'')),
               'Lugar_Reunion'       = cg_lugar_reunion,
               'Ahorro_Voluntario'   = cg_ahorro_voluntario,
               'Cuenta_Individual'   = (select ea_cta_banco from  cobis..cl_ente_aux where ea_ente=CG.cg_ente),
               'Resultado'           = isnull((select vd_resultado from cob_credito..cr_verifica_datos where vd_tramite = @i_tramite and vd_cliente = CG.cg_ente),0),
               'Nro Ciclo'         = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo 
                      and dc_cliente = en_ente),
         'NivelRiesgo'         = ea_nivel_riesgo
        from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN, cobis..cl_ente_aux EA
        where cg_ente  = en_ente
        and   en_ente = ea_ente
        and   cg_grupo = @i_grupo
        and   cg_fecha_desasociacion is null
        order by cg_ente
   end

   if @i_modo = 1
   begin
        select 'Ente'       = cg_ente,
               'Id_Grupo'   = cg_grupo,
               'Fecha_Aso'  = cg_fecha_reg,
               'Rol'        = cg_rol,
               'Estado'     = cg_estado,
               'Cal_Interna'= (ISNULL(p_calif_cliente,'')),
               'Fecha_Desasociacion' = cg_fecha_desasociacion,
               'Nombre_Cliente'      = en_nomlar,
               'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
               'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
               'Cal_Interna'         = (ISNULL(p_calif_cliente,'')),
               'Lugar_Reunion'       = cg_lugar_reunion,
               'Ahorro_Voluntario'   = cg_ahorro_voluntario,
               'Cuenta_Individual'   = (select ea_cta_banco from  cobis..cl_ente_aux where ea_ente=CG.cg_ente),
               'Resultado'           = isnull((select vd_resultado from cob_credito..cr_verifica_datos where vd_tramite = @i_tramite and vd_cliente = CG.cg_ente),0),
               'Nro Ciclo'           = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo 
                      and dc_cliente = en_ente) 
        from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN
        where cg_ente  = en_ente
        and   cg_grupo = @i_grupo
        and   cg_ente  > @i_ente
        and   cg_fecha_desasociacion is null
        order by cg_ente
   end

   if @i_modo = 2
   begin
       if exists (select 1 from cob_credito..cr_verifica_datos where vd_tramite = @i_tramite and vd_cliente = @i_ente)
         begin
               -- Deudor que no pertenezca a cr_verifica_datos
               select 'Ente'                = en_ente,
                      'Nombre_Cliente'      = en_nomlar,
                      'Resultado'           = 0
               from  cobis..cl_ente, cob_credito..cr_deudores
               where en_ente     = @i_ente
               and   de_tramite  = @i_tramite
           and   en_ente not in ( select vd_cliente from cob_credito..cr_verifica_datos)
               
               union -- Deudor que pertenezca a cr_verifica_datos
               select 'Ente'                = en_ente,
                      'Nombre_Cliente'      = en_nomlar,
                      'Resultado'           = isnull(vd_resultado,0)
               from  cobis..cl_ente EN, cob_credito..cr_deudores DE, cob_credito..cr_verifica_datos VD
               where en_ente    = @i_ente
               and   de_tramite = @i_tramite
               and   de_tramite = vd_tramite
               and   en_ente    = vd_cliente
           and   en_ente    = de_cliente
           and   (select max(vd_fecha) from cob_credito..cr_verifica_datos where vd_cliente =  VD.vd_cliente) < @w_fecha_ini_param
               
               union  -- Aval que no pertenece a cr_verifica_datos
               select 'Ente'                = en_ente,
                      'Nombre_Cliente'      = en_nomlar,
                      'Resultado'           = 0
               from  cob_credito..cr_tramite, cobis..cl_ente
               where tr_alianza  = en_ente
               and   tr_tramite  = @i_tramite
           and   tr_alianza not in ( select vd_cliente from cob_credito..cr_verifica_datos)
               
           union -- Aval  que pertenece a cr_verifica_datos
               select 'Ente'                = en_ente,
                      'Nombre_Cliente'      = en_nomlar,
                      'Resultado'           = isnull(vd_resultado,0)
               from  cob_credito..cr_tramite TR, cobis..cl_ente EN, cob_credito..cr_verifica_datos VD
               where tr_alianza  = en_ente
               and   tr_tramite  = @i_tramite
           and   tr_tramite  = vd_tramite
           and   (select max(vd_fecha) from cob_credito..cr_verifica_datos where vd_cliente =  TR.tr_alianza) < @w_fecha_ini_param                       
         end     
     else
         begin
               -- Deudor que no pertenezca a cr_verifica_datos
               select 'Ente'                = en_ente,
                      'Nombre_Cliente'      = en_nomlar,
                      'Resultado'           = 0
               from  cobis..cl_ente, cob_credito..cr_deudores
               where en_ente     = @i_ente
               and   de_tramite  = @i_tramite
           and   en_ente not in ( select vd_cliente from cob_credito..cr_verifica_datos)
               
               union -- Deudor que pertenezca a cr_verifica_datos
               select top 1 'Ente'          = en_ente,
                      'Nombre_Cliente'      = en_nomlar,
                      'Resultado'           = 0
               from  cobis..cl_ente EN, cob_credito..cr_deudores DE, cob_credito..cr_verifica_datos VD
               where en_ente    = @i_ente
               and   en_ente    = vd_cliente
           and   en_ente    = de_cliente
           and   (select max(vd_fecha) from cob_credito..cr_verifica_datos where vd_cliente =  VD.vd_cliente) < @w_fecha_ini_param
               
               union  -- Aval que no pertenece a cr_verifica_datos
               select 'Ente'                = en_ente,
                      'Nombre_Cliente'      = en_nomlar,
                      'Resultado'           = 0
               from  cob_credito..cr_tramite, cobis..cl_ente
               where tr_alianza  = en_ente
               and   tr_tramite  = @i_tramite
           and   tr_alianza not in ( select vd_cliente from cob_credito..cr_verifica_datos)
               
           union -- Aval  que pertenece a cr_verifica_datos
               select top 1 'Ente'          = en_ente,
                      'Nombre_Cliente'      = en_nomlar,
                      'Resultado'           = 0
               from  cob_credito..cr_tramite TR, cobis..cl_ente EN
               where tr_alianza  = en_ente
               and   tr_tramite  = @i_tramite
           and   (select max(vd_fecha) from cob_credito..cr_verifica_datos where vd_cliente =  TR.tr_alianza) < @w_fecha_ini_param       
         end

   end

    if @i_modo = 3
    begin
        select @w_param_val_resp_min = pa_tinyint 
          from cobis..cl_parametro 
         where pa_producto = 'CRE' 
           and pa_nemonico = 'RVDGR'

        select 'Ente'       = cg_ente,
               'Id_Grupo'   = cg_grupo,
               'Fecha_Aso'  = cg_fecha_reg,
               'Rol'        = cg_rol,
               'Estado'     = cg_estado,
               'Cal_Interna'= (ISNULL(p_calif_cliente,'')),
               'Fecha_Desasociacion' = cg_fecha_desasociacion,
               'Nombre_Cliente'      = en_nomlar,
               'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
               'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
               'Cal_Interna'         = (ISNULL(p_calif_cliente,'')),
               'Lugar_Reunion'       = cg_lugar_reunion,
               'Ahorro_Voluntario'   = cg_ahorro_voluntario,
               'Cuenta_Individual'   = (select ea_cta_banco from  cobis..cl_ente_aux where ea_ente=CG.cg_ente),
               'Resultado'           = isnull((select vd_resultado from cob_credito..cr_verifica_datos where vd_tramite = @i_tramite and vd_cliente = CG.cg_ente),0),
               'Nro Ciclo'           = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo 
                      and dc_cliente = en_ente)
        from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN, cob_credito..cr_tramite_grupal TG
        where CG.cg_ente NOT IN ( select vd_cliente from cob_credito..cr_verifica_datos)
        and   CG.cg_ente    = EN.en_ente
        and   CG.cg_grupo   = @i_grupo
        and   TG.tg_tramite = @i_tramite
        and   TG.tg_participa_ciclo = 'S'
        and   TG.tg_grupo   = CG.cg_grupo
        and   TG.tg_cliente = CG.cg_ente
        and   TG.tg_monto_aprobado  > 0   
        and   cg_fecha_desasociacion is null

        union

        select 'Ente'       = cg_ente,
               'Id_Grupo'   = cg_grupo,
               'Fecha_Aso'  = cg_fecha_reg,
               'Rol'        = cg_rol,
               'Estado'     = cg_estado,
               'Cal_Interna'= (ISNULL(p_calif_cliente,'')),
               'Fecha_Desasociacion' = cg_fecha_desasociacion,
               'Nombre_Cliente'      = en_nomlar,
               'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
               'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
               'Cal_Interna'         = (ISNULL(p_calif_cliente,'')),
               'Lugar_Reunion'       = cg_lugar_reunion,
               'Ahorro_Voluntario'   = cg_ahorro_voluntario,
               'Cuenta_Individual'   = (select ea_cta_banco from  cobis..cl_ente_aux where ea_ente=CG.cg_ente),
               'Resultado'           = isnull((select vd_resultado from cob_credito..cr_verifica_datos where vd_tramite = @i_tramite and vd_cliente = CG.cg_ente),0),
               'Nro Ciclo'           = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo 
                      and dc_cliente = en_ente)
        from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN, cob_credito..cr_verifica_datos, cob_credito..cr_tramite_grupal TG
        where cg_ente    = en_ente
        and   vd_cliente = en_ente
        and   cg_grupo   = @i_grupo
        and   TG.tg_tramite = @i_tramite
        and   TG.tg_participa_ciclo = 'S'
        and   TG.tg_grupo   = CG.cg_grupo
        and   TG.tg_cliente = CG.cg_ente
        and   TG.tg_monto_aprobado  > 0   
        and   cg_fecha_desasociacion is NULL
        --and   vd_fecha < @w_fecha_ini
        and   (select max(vd_fecha) from cob_credito..cr_verifica_datos where vd_cliente =  CG.cg_ente) < @w_fecha_ini_param

        union

        select 'Ente'       = cg_ente,
               'Id_Grupo'   = cg_grupo,
               'Fecha_Aso'  = cg_fecha_reg,
               'Rol'        = cg_rol,
               'Estado'     = cg_estado,
               'Cal_Interna'= (ISNULL(p_calif_cliente,'')),
               'Fecha_Desasociacion' = cg_fecha_desasociacion,
               'Nombre_Cliente'      = en_nomlar,
               'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
               'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
               'Cal_Interna'         = (ISNULL(p_calif_cliente,'')),
               'Lugar_Reunion'       = cg_lugar_reunion,
               'Ahorro_Voluntario'   = cg_ahorro_voluntario,
               'Cuenta_Individual'   = (select ea_cta_banco from  cobis..cl_ente_aux where ea_ente=CG.cg_ente),
               'Resultado'           = isnull((select vd_resultado from cob_credito..cr_verifica_datos where vd_tramite = @i_tramite and vd_cliente = CG.cg_ente),0),
               'Nro Ciclo'           = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo 
                      and dc_cliente = en_ente)
        from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN, cob_credito..cr_verifica_datos, cob_credito..cr_tramite_grupal TG
        where cg_ente      = en_ente
        and   vd_cliente   = en_ente
        and   cg_grupo     = @i_grupo
        and   TG.tg_tramite = @i_tramite
        and   TG.tg_participa_ciclo = 'S'
        and   TG.tg_grupo   = CG.cg_grupo
        and   TG.tg_cliente = CG.cg_ente
        and   TG.tg_monto_aprobado  > 0     
        and   cg_fecha_desasociacion is NULL
        --and   vd_fecha < @w_fecha_ini
        and   (select max(vd_fecha) from cob_credito..cr_verifica_datos where vd_cliente =  CG.cg_ente) >= @w_fecha_ini_param   
    and   vd_resultado < @w_param_val_resp_min 
   end
   
  if @i_modo = 4 -- Para reporte
   begin
        select 'Ente'       = cg_ente,
               'Id_Grupo'   = cg_grupo,
               'Fecha_Aso'  = cg_fecha_reg,
               'Rol'        = cg_rol,
               'Estado'     = cg_estado,
               'Cal_Interna'= (ISNULL(p_calif_cliente,'')),
               'Fecha_Desasociacion' = cg_fecha_desasociacion,
               'Nombre_Cliente'      = UPPER(isnull(en_nombre,''))+' '+UPPER(isnull(p_s_nombre,''))+' '+UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,'')),
               'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
               'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
               'Cal_Interna'         = (ISNULL(p_calif_cliente,'')),
               'Lugar_Reunion'       = cg_lugar_reunion,
               'Ahorro_Voluntario'   = cg_ahorro_voluntario,
               'Cuenta_Individual'   = (select ea_cta_banco from  cobis..cl_ente_aux where ea_ente=CG.cg_ente),
               'Resultado'           = isnull((select vd_resultado from cob_credito..cr_verifica_datos where vd_tramite = @i_tramite and vd_cliente = CG.cg_ente),0),
               'Nro Ciclo'         = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo 
                      and dc_cliente = en_ente)
        from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN, cob_credito..cr_tramite_grupal 
        where cg_ente    = en_ente
        and   cg_grupo   = @i_grupo
    and   tg_tramite = @i_tramite
    and   tg_cliente = en_ente
    and   tg_participa_ciclo = 'S'
    and   tg_monto > 0
        order by cg_ente
   end
   
    if @i_modo = 5  -- Integrantes que participen en el trámite
    begin
        select 'Ente'       = cg_ente,
               'Id_Grupo'   = cg_grupo,
               'Fecha_Aso'  = cg_fecha_reg,
               'Rol'        = cg_rol,
               'Estado'     = cg_estado,
               'Cal_Interna'= (ISNULL(p_calif_cliente,'')),
               'Fecha_Desasociacion' = cg_fecha_desasociacion,
               'Nombre_Cliente'      = en_nomlar,
               'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
               'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
               'Cal_Interna'         = (ISNULL(p_calif_cliente,'')),
               'Lugar_Reunion'       = cg_lugar_reunion,
               'Ahorro_Voluntario'   = cg_ahorro_voluntario,
               'Cuenta_Individual'   = (select ea_cta_banco from  cobis..cl_ente_aux where ea_ente=CG.cg_ente),
               'Resultado'           = isnull((select vd_resultado from cob_credito..cr_verifica_datos where vd_tramite = @i_tramite and vd_cliente = CG.cg_ente),0),
               'Nro Ciclo'         = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo 
                      and dc_cliente = en_ente)
        from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN, cob_credito..cr_tramite_grupal 
        where cg_ente    = en_ente
        and   cg_grupo   = @i_grupo
        and   tg_tramite = @i_tramite
        and   tg_cliente = en_ente
        and   tg_participa_ciclo = 'S'
        and   tg_monto > 0
        order by cg_ente
   end   
   if @i_modo = 6 
    begin
        set rowcount 20
        select 'Ente'       = cg_ente,
               'Id_Grupo'   = cg_grupo,
               'Fecha_Aso'  = cg_fecha_reg,
               'Rol'        = cg_rol,
               'Estado'     = cg_estado,
               'Cal_Interna'= (ISNULL(p_calif_cliente,'')),
               'Fecha_Desasociacion' = cg_fecha_desasociacion,
               'Nombre_Cliente'      = en_nomlar,
               'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
               'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
               'Cal_Interna'         = (ISNULL(p_calif_cliente,'')),
               'Lugar_Reunion'       = cg_lugar_reunion,
               'Oficial' = (select fu_nombre from cl_funcionario f, cc_oficial o where EN.en_oficial = o.oc_oficial and o.oc_funcionario = f.fu_funcionario),
               'Cuenta_Individual'   = (select ea_cta_banco from  cobis..cl_ente_aux where ea_ente=CG.cg_ente),
               'Resultado'           = (select gr_nombre from cobis..cl_grupo where gr_grupo = @i_grupo),
               'Nro Ciclo'         = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo 
                      and dc_cliente = en_ente),
               'NivelRiesgo'         = ea_nivel_riesgo,
               'Tipo_Relacion'       = (select valor from cobis..cl_catalogo where tabla =  @w_tipo_relacion and codigo = CG.cg_rol)
        from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN, cobis..cl_ente_aux EA
        where cg_ente  = en_ente
        and   en_ente = ea_ente
        and   cg_grupo = @i_grupo
        and   cg_ente > isnull(@i_ente_aux,0)
        order by cg_grupo, cg_ente
        set rowcount 0
   end
   if @i_modo = 7
     begin
      set rowcount 20
      select 'Ente' = cg_ente,
         'Id_Grupo' = cg_grupo,
         'Fecha_Aso' = cg_fecha_reg,
         'Rol' = cg_rol,
         'Estado' = cg_estado,
         'Cal_Interna'= (ISNULL(p_calif_cliente,'')),
         'Fecha_Desasociacion' = cg_fecha_desasociacion,
         'Nombre_Cliente' = en_nomlar,
         'Rol_Descrip' = (select valor from cobis..cl_catalogo where tabla = @w_tab_id_rol and codigo = CG.cg_rol),
         'Estado_Descrip' = (select valor from cobis..cl_catalogo where tabla = @w_tab_id_estado and codigo = CG.cg_estado),
         'Cal_Interna' = (ISNULL(p_calif_cliente,'')),
         'Lugar_Reunion' = cg_lugar_reunion,
         'Oficial' = (select fu_nombre from cl_funcionario f, cc_oficial o where EN.en_oficial = o.oc_oficial and o.oc_funcionario = f.fu_funcionario),
         'Cuenta_Individual' = (select ea_cta_banco from cobis..cl_ente_aux where ea_ente=CG.cg_ente),
         'Resultado' = gr_nombre,
         'Nro Ciclo' = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo
         and dc_cliente = en_ente),
         'NivelRiesgo' = ea_nivel_riesgo,
         'Tipo_Relacion' = (select valor from cobis..cl_catalogo where tabla = @w_tipo_relacion and codigo = CG.cg_rol)
         from cobis..cl_cliente_grupo CG, cobis..cl_ente EN, cobis..cl_ente_aux EA, cobis..cl_grupo
         where cg_ente = en_ente
         and en_ente = ea_ente
         and ((cg_grupo = @i_grupo and cg_ente > isnull(@i_ente_aux,0) and @i_tipo <> 'CL') or (cg_grupo in (select cg_grupo from cl_cliente_grupo where cg_ente = isnull(@i_ente,0)) and @i_tipo = 'CL' and cg_ente > isnull(@i_ente_aux,0) and cg_grupo >= @i_grupo) or (cg_grupo > @i_grupo and @i_tipo <> 'CL'))
         and gr_grupo = cg_grupo
         and gr_tipo           = @i_tipo_grupo
         and (gr_estado        = @i_estado     OR  @i_estado IS NULL)
         and (cg_rol           = @i_rol       OR @i_rol IS NULL)
      order by cg_grupo, cg_ente
      set rowcount 0
     end
     --Consulta REST
   if @i_modo = 8
   begin
      if @i_ente is null or @i_ente = 0
      begin
         select 'Ente'       = cg_ente,
                'Id_Grupo'   = cg_grupo,
                'Fecha_Aso'  = (select format (cg_fecha_reg, 'dd-MM-yyyy HH:mm:ss') as date),
                'Rol'        = cg_rol,
                'Estado'     = cg_estado,
                'Nombre_Cliente'      = en_nomlar,
                'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
                'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
                'Lugar_Reunion'       = cg_lugar_reunion,
                'Ahorro_Voluntario'   = cg_ahorro_voluntario,
                'Nro Ciclo'         = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo and dc_cliente = en_ente)
         from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN
         where cg_ente  = en_ente
         and   cg_grupo = @i_grupo
         and   cg_fecha_desasociacion is null
         order by cg_ente
         if @@rowcount = 0
         begin
            exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 1720019
            return 1
         end
   end
   else
   begin
         select 'Ente'       = cg_ente,
                'Id_Grupo'   = cg_grupo,
                'Fecha_Aso'  = (select format (cg_fecha_reg, 'dd-MM-yyyy HH:mm:ss') as date),
                'Rol'        = cg_rol,
                'Estado'     = cg_estado,
                'Nombre_Cliente'      = en_nomlar,
                'Rol_Descrip'         = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
                'Estado_Descrip'      = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
                'Lugar_Reunion'       = cg_lugar_reunion,
                'Ahorro_Voluntario'   = cg_ahorro_voluntario,
                'Nro Ciclo'         = (select count(dc_cliente) from cob_cartera..ca_det_ciclo where dc_grupo = @i_grupo and dc_cliente = en_ente)
         from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN
         where cg_ente  = en_ente
         and   cg_grupo = @i_grupo
         and   cg_ente  = @i_ente
         and   cg_fecha_desasociacion is null
         order by cg_ente
         if @@rowcount = 0
         begin
            exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 1720019
            return 1
         end
   end
       
   
       
   end
   
end -- FIN OPCION S

if @i_operacion = 'Q'
begin
    --Consulta de Datos
    select @w_ente                = cg_ente,
           @w_grupo               = cg_grupo,
           @w_fecha_asociacion    = cg_fecha_reg,
           @w_rol                 = cg_rol,
           @w_estado              = cg_estado,
           @w_calif_interna       = (ISNULL(p_calif_cliente,'')),
           @w_fecha_desasociacion = cg_fecha_desasociacion,
           @w_cliente_nomlar      = en_nomlar,
           @w_cg_ahorro_voluntario = cg_ahorro_voluntario,
           @w_cg_lugar_reunion     = cg_lugar_reunion,
           @w_rol_desc             = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_rol and codigo = CG.cg_rol),
           @w_estado_desc          = (select valor from cobis..cl_catalogo where tabla =  @w_tab_id_estado and codigo = CG.cg_estado),
           @w_calif_interna_desc   = (ISNULL(p_calif_cliente,''))
    from  cobis..cl_cliente_grupo CG, cobis..cl_ente EN
    where cg_ente  = en_ente
    and   cg_ente  = @i_ente
    and   cg_grupo = @i_grupo
    and   cg_fecha_desasociacion is null

    select 'Ente'       = @w_ente,
           'Id_Grupo'   = @w_grupo,
           'Fecha_Aso'  = @w_fecha_asociacion,
           'Rol'        = @w_rol,
           'Estado'     = @w_estado,
           'Cal_Interna'= @w_calif_interna,
           'Fecha_Desasociacion' = @w_fecha_desasociacion,
           'Nombre_Cliente'      = @w_cliente_nomlar,
           'Rol_Descrip'         = @w_rol_desc,
           'Estado_Descrip'      = @w_estado_desc,
           'Cal_Interna'         = @w_calif_interna_desc,
           'Ahorro_Voluntario'   = @w_cg_ahorro_voluntario,
           'Lugar_Reunion'       = @w_cg_lugar_reunion
end -- FIN OPCION Q
--Obtener la calificacion del cliente-
if @i_operacion = 'L'
begin
    --Consulta de Datos
    select @w_ente                = en_ente,
           @w_calif_interna   = (ISNULL(p_calif_cliente,''))
    from  cobis..cl_ente EN
    where  en_ente = @i_ente

    select 'Ente'       = @w_ente,
           'Cal_Interna'= @w_calif_interna
end -- FIN OPCION L



select @w_sincroniza = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'HASIAU'

select @w_ofi_app = pa_smallint 
from cobis.dbo.cl_parametro cp 
where cp.pa_nemonico = 'OFIAPP'
and cp.pa_producto = 'CRE'

--Proceso de sincronizacion Grupos
if @i_operacion in ('I','U','D') and @i_grupo is not null and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
begin
   exec @w_error = cob_sincroniza..sp_sinc_json_groups
      @i_opcion     = 'I',
      @i_grupo      = @i_grupo,
      @t_debug      = @t_debug
end

return 0

VALIDAR_ERROR:
   select @w_msg = cob_interface.dbo.fn_concatena_mensaje(@w_nomlar , @w_error, @s_culture)
   goto ERROR
   
ERROR:
    begin --Devolver mensaje de Error
        select @w_error
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_msg   = @w_msg,
             @i_num   = @w_error

        return @w_error
    end
go
