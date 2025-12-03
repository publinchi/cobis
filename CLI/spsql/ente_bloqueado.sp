/************************************************************************/
/*  Archivo:            cl_bloqueado.sp                                 */
/*  Stored procedure:   sp_ente_bloqueado                               */
/*  Base de datos:      cobis                                           */
/*  Producto:           Clientes                                        */
/*  Disenado por:       ALD                                             */
/*  Fecha de escritura: 30-Abril-2019                                   */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Este stored procedure procesa:                                      */
/*  Retorna a los modulos S(Si tiene informacion incompleta) o N(NO)    */
/*  tiene informacion incompleta, validando los casos dados por el BAC  */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA           AUTOR     RAZON                                     */
/* 30/Abril/2019    ALD       Versión Inicial Te Creemos                */
/* 16/Junio/2020    FSAP      Estandarizacion de Clientes               */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
           from   sysobjects
           where  name = 'sp_ente_bloqueado')
  drop proc sp_ente_bloqueado
go

create proc sp_ente_bloqueado
(
  @s_culture      varchar(10) = 'NEUTRAL',
  @s_ssn          int         = null,
  @s_user         login       = null,
  @s_term         varchar(30) = null,
  @s_date         datetime    = null,
  @s_srv          varchar(30) = null,
  @s_lsrv         varchar(30) = null,
  @s_ofi          smallint    = null,
  @s_rol          smallint    = null,
  @s_org_err      char(1)     = null,
  @s_error        int         = null,
  @s_sev          tinyint     = null,
  @s_msg          descripcion = null,
  @s_org          char(1)     = null,
  @t_debug        char(1)     = 'N',
  @t_file         varchar(10) = null,
  @t_from         varchar(32) = null,
  @t_trn          int         = null,
  @t_show_version bit         = 0,
  @i_operacion    char(1),
  @i_ente         int         = null,
  @i_ced_ruc      varchar(30) = null,
  @i_tipo_ced     char(2)     = null,
  @i_modo         tinyint     = 0,
  @o_retorno      char(1)     = null output,
  @o_bloqueado    char(1)     = null output,
  @o_malaref      char(1)     = null output,
  @o_lista        varchar(10) = null output,
  @o_mensaje      varchar(64) = null output,
  @o_restrictiva  char(1)     = null output,
  @i_canal        varchar(10) = '001',
  @i_tipo_id      varchar(10) = null,
  @i_numero_id    numero      = null,
  @i_pago_ext     char(1)     = 'N',
  @i_linea        char(1)     = 'S',

  /* campos cca 353 alianzas bancamia --AAMG*/
  @i_crea_ext     char(1)     = null,
  @o_msg_msv      varchar(255)= null out
)
as
  declare
    @w_today               datetime,
    @w_sp_name             varchar(32),
    @w_sp_msg              varchar(132),
    @w_return              int,
    @w_subtipo             char(1),
    @w_en_tipo_ced         char(2),
    @w_fec_nac             datetime,
    @w_en_ced_ruc          numero,
    @w_cont_val            smallint,
    @w_dep_nac             int,
    @w_ciudad_nac          int,
    @w_nomlar              varchar(254),
    @w_profesion           catalogo,
    @w_en_actividad        catalogo,
    @w_otros_ing           descripcion,
    @w_relacint            char(1),
    @w_fec_finan           datetime,
    @w_activos             money,
    @w_pasivos             money,
    @w_ingresos            money,
    @w_egresos             money,
    @w_patrimonio          money,
    @w_tipo_soc            catalogo,
    @w_rep_legal           int,
    @w_legal_ente          int,
    @w_subtipo_rl          char(1),
    @w_ced_ruc_rl          numero,
    @w_nomlar_rl           varchar(254),
    @w_asalariado          varchar(10),
    @w_ot_ing              int,
    @w_ot_ingop            int,
    @w_act_default         varchar(10),
    @w_ente                int,
    @w_fec_proceso         datetime,
    @w_conerror            char(1),
    @w_msg                 descripcion,
    @w_cliente             char(1),
    @w_ocupacion           varchar(10),
    @w_num_causa           int,
    @w_bloqueado           char(1),
    @w_malaref             char(1),
    @w_mensaje             varchar(64),
    @w_en_subtipo          char(1),
    @w_en_nombre           varchar(64),
    @w_en_sector           varchar(10),
    @w_p_sexo              char(1),
    @w_en_pais             smallint,
    @w_p_tipo_persona      varchar(10),
    @w_en_procedencia      varchar(10),
    @w_en_influencia       varchar(10),
    @w_en_relacint         char(1),
    @w_en_recurso_pub      char(1),
    @w_en_victima          char(1),
    @w_en_persona_pub      char(1),
    @w_en_tipo_vinculacion varchar(10),
    @w_en_asosciada        varchar(10),
    @w_en_fecha_negocio    datetime,
    @w_en_estrato          varchar(10),
    @w_p_depa_nac          varchar(10),
    @w_p_fecha_nac         datetime,
    @w_p_estado_civil      varchar(10),
    @w_p_p_apellido        varchar(16),
    @w_en_oficial          varchar(10),
    @w_en_casilla_def      varchar(10),
    @w_en_reestructurado   varchar(10),
    @w_c_tipo_soc          varchar(10),
    @w_lista               varchar(10),
    @w_estado              varchar(10),
    @w_in_fecha_ref        datetime,
    @w_origen              varchar(20),
    @w_existe_cliente      char(1),
    @w_restrictiva         varchar(12),
    @w_ms_restrictiva      varchar(12),
    @w_lista_restric       varchar(12),
    @w_tipo_mr             varchar(12),
    @w_parlista            varchar(12),
    @w_en_nomlar           varchar(64),
    @w_ref_mercado         varchar(3),
    @w_malasref            smallint,
    @w_cedulaente          varchar(20),
    @w_malasref1           smallint,
    @w_contador            smallint,
    @w_catced              smallint,
    @w_catnom              smallint,
    @w_categoria           smallint,
    @w_observacion         varchar(64),
    @w_catced1             smallint,
    @w_cruced              smallint,
    @w_catcedm             smallint,
    @w_tiene               int,
    @w_message             varchar(200)

select
  @w_sp_name = 'sp_ente_bloqueado'


---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
if @s_culture = 'NEUTRAL'
begin
   ---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
   exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
end
  --V16
  select @w_rep_legal = pa_smallint
    from cobis..cl_parametro with (nolock)
   where pa_producto = 'CLI'
     and pa_nemonico = 'RL5'

  --parametro SARLAFT - LISTAS RESTRICTIVAS
  select @w_lista_restric = pa_char
    from cobis..cl_parametro with (nolock)
   where pa_producto = 'CLI'
     and pa_nemonico = 'LRES'
     

  select
    @w_asalariado = '001000'
  select
    @w_ot_ing = 480000
  select
    @w_ot_ingop = 42
  select
    @w_act_default = '000000'
  select
    @w_ref_mercado = '999'

  select
    @w_today = getdate()

/*  ************************************* */
/*  Cruce en linea para documento trn dia */
  /*  ************************************* */
  if @i_operacion = 'F'
      or @i_operacion = 'V'
  begin
    if @i_ente > 0
    begin
      select
        @w_bloqueado = 'N',
        --en_tipo_dp , ojo se quita mientras se define por parte del banco los campos a validar
        @w_malaref = en_mala_referencia,
        @w_en_ced_ruc = en_ced_ruc,
        @w_en_nomlar = en_nomlar
      from   cobis..cl_ente with (nolock)
      where  en_ente = @i_ente
    end

    if @i_numero_id is not null
    begin
      select
        @w_bloqueado = 'N',
        --en_tipo_dp , ojo se quita mientras se define por parte del banco los campos a validar
        @w_malaref = en_mala_referencia,
        @w_en_ced_ruc = en_ced_ruc,
        @w_en_nomlar = en_nomlar
      from   cobis..cl_ente with (nolock)
      where  en_ced_ruc = @i_numero_id
    end
  end

  if @i_operacion = 'Z'
  begin
    if @i_ente > 0
    begin
      select
        @w_malaref = en_mala_referencia,
        @w_en_ced_ruc = en_ced_ruc,
        @w_en_nomlar = en_nomlar
      from   cobis..cl_ente with (nolock)
      where  en_ente = @i_ente
    end

    if @w_en_ced_ruc is not null
    begin
      select
        @w_catced = isnull(count(0),
                           0)
      from   cobis..cl_refinh
      where  in_ced_ruc = @w_en_ced_ruc

      select
        @w_catced1 = isnull(count(0),
                            0)
      from   cobis..cl_refinh
      where  in_categoria = @w_en_ced_ruc

      select
        @w_catcedm = isnull(count(0),
                            0)
      from   cobis..cl_mercado
      where  me_ced_ruc = @w_en_ced_ruc

      select
        @w_cruced = @w_catced + @w_catced1 + @w_catcedm
    
      if @w_cruced > 0
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720615 
        select
          @w_malaref = 'S'
        update cobis..cl_ente
        set    en_mala_referencia = @w_malaref,
               en_comentario = @w_message + ' nro id'
        where  en_ced_ruc = @w_en_ced_ruc
      end

      select
        @w_catnom = isnull(count(0),
                           0)
      from   cobis..cl_refinh
      where  in_nomlar = @w_en_nomlar

      if @w_cruced = 0
         and @w_catnom = 1
      begin
        select
          @w_parlista = pa_char
        from   cobis..cl_parametro
        where  pa_producto = 'CLI'
           and pa_nemonico = 'LNRES'

        select
          @w_observacion = in_observacion,
          @w_origen = in_origen
        from   cobis..cl_refinh
        where  in_nomlar = @w_en_nomlar

        select
          @w_categoria = isnull(count(0),
                                0)
        from   cobis..cl_manejo_sarlaft
        where  ms_restrictiva = @w_parlista
           and ms_origen      = @w_origen
           
        select @w_message = re_valor                                                                                                                                                                           
        from   cobis..cl_errores 
        inner join cobis..ad_error_i18n 
        on    (numero = pc_codigo_int                                                                                                                                                                                                                        
               and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
        where  numero = 1720616 

        if @w_categoria > 0
           and @w_observacion = @w_message
        begin
           select @w_message = re_valor                                                                                                                                                                           
           from   cobis..cl_errores 
           inner join cobis..ad_error_i18n 
           on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                  and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
           where  numero = 1720615
          select
            @w_malaref = 'N'
          update cobis..cl_ente
          set    en_mala_referencia = @w_malaref,
                 en_comentario = @w_message + ' nombre'
          where  en_nomlar = @w_en_nomlar
        end
      end

      if @w_cruced = 0
         and @w_catnom > 1
      begin --mas de una no restrictiva 
        select
          @w_parlista = pa_char
        from   cobis..cl_parametro
        where  pa_producto = 'CLI'
           and pa_nemonico = 'LNRES'

        select
          @w_observacion = in_observacion,
          @w_origen = in_origen
        from   cobis..cl_refinh
        where  in_nomlar = @w_en_nomlar

        select
          @w_categoria = isnull(count(0),
                                0)
        from   cobis..cl_manejo_sarlaft
        where  ms_restrictiva = @w_parlista
           and ms_origen      = @w_origen

        if @w_categoria > 0
        begin --@w_observacion    = 'CARGUE WORLD COMPLIANCE' begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720615
          select
            @w_malaref = 'N'
          update cobis..cl_ente
          set    en_mala_referencia = @w_malaref,
                 en_comentario = @w_message + ' nombre NOM2'
          where  en_nomlar = @w_en_nomlar
        end
      end --existe

      select
        @w_tiene = 0
      if exists(select
                  1
                from   cobis..cl_refinh
                where  in_ced_ruc = @w_en_ced_ruc)
        select
          @w_tiene = 1
      if exists(select
                  1
                from   cobis..cl_mercado
                where  me_ced_ruc = @w_en_ced_ruc)
        select
          @w_tiene = 1

      if @w_tiene = 0
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720615
        select
          @w_malaref = 'N'
        update cobis..cl_ente
        set    en_mala_referencia = @w_malaref,
               en_comentario = @w_message + ' nro id CED2'
        where  en_ced_ruc = @w_en_ced_ruc
      end
    end
    select
      @o_retorno = 'N'
  end --operacion Z

  if @i_operacion = 'F'
  begin
    select
      @w_mensaje = null,
      @w_msg = null,
      @w_lista = null

    if @t_trn <> 172025
    begin
      select
        @w_return = 1720075
      goto ERROR_FIN
    /*  'No corresponde codigo de transaccion' */

    end

    -- i wro
    if @i_canal is null
    begin
      select
        @w_return = 1720074
      goto ERROR_FIN
    /*  'No existe dato solicitado' */

    end
    -- f wro

    if @i_tipo_id is null
    begin
      select
        @w_return = 1720074
      goto ERROR_FIN
    /*  'No existe dato solicitado' */
    end

    -- 001 es el codigo de  --> SARLAFT-RESTRICTIVAS
    select
      @w_restrictiva = cl_catalogo.codigo --001
    from   cobis..cl_tabla with (nolock),
           cobis..cl_catalogo with (nolock)
    where  cl_tabla.tabla     = 'cl_sarlaf'
       and cl_catalogo.tabla  = cl_tabla.codigo
       and cl_catalogo.codigo = @w_lista_restric

    -- set rowcount 1
    select top 1
      @w_in_fecha_ref = convert (varchar(10), in_fecha_ref, 101),
      @w_origen = in_origen,
      @w_nomlar = isnull(in_nomlar,
                         isnull(in_nombre,
                                '')),
      @w_estado = in_estado
    from   cobis..cl_refinh with (nolock)
    where  in_ced_ruc = @i_numero_id
    order  by in_origen desc
    --set rowcount 0

    if @@rowcount = 0
    begin
      select top 1
        @w_in_fecha_ref = convert (varchar(10), in_fecha_ref, 101),
        @w_origen = in_origen,
        @w_nomlar = isnull(in_nomlar,
                           isnull(in_nombre,
                                  '')),
        @w_estado = in_estado
      from   cobis..cl_refinh with (nolock)
      where  in_otroid = @i_numero_id
      order  by in_origen desc
    end

    select
      @w_tipo_mr = ms_restrictiva
    from   cobis..cl_manejo_sarlaft with (nolock)
    where  ms_origen = @w_origen

    -- si existe en la lista y adicionalmente es RESTRICTIVA se ingresa el registro en la tabla cl_intentos_restrictivas
    if @w_lista_restric = @w_tipo_mr
    begin
      insert into cobis..cl_intentos_restrictivas
                  (ir_fecha_intento,ir_oficina,ir_tipo_documento,
                   ir_numero_documento
                   ,ir_nombre,
                   ir_origen,ir_estado,ir_fecha_lista,ir_canal)
      values      ( getdate(),@s_ofi,@i_tipo_id,@i_numero_id,@w_nomlar,
                    @w_origen,@w_estado,@w_in_fecha_ref,@i_canal )

      if @@rowcount <> 1
      begin
        select
          @w_return = 1720142
        goto ERROR_FIN
      /*  'error al insertar informacion de la transaccion' */

      end
    end

    --saca codigo del mensaje
    if @w_origen is not null
    begin
      select
        @w_msg = cl_catalogo.valor
      from   cl_catalogo with (nolock),
             cl_tabla with (nolock)
      where  cl_catalogo.codigo = @w_origen
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_tabla.tabla     = 'cl_mreqv'

      if @@rowcount <> 1
      begin
        select
          @w_return = 1720143
        goto ERROR_FIN

      end

      select
        @w_mensaje = cl_catalogo.valor
      from   cl_catalogo with (nolock),
             cl_tabla with (nolock)
      where  cl_catalogo.codigo = @w_msg
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_tabla.tabla     = 'cl_mrmsg'

      if @@rowcount <> 1
      begin
        select
          @w_return = 1720143 ----No existe parametro
        goto ERROR_FIN

      end

      if @w_lista_restric <> @w_tipo_mr
      begin
        select
          @w_return = 1720144  --Tipo de lista no restrictiva
        goto ERROR_FIN
      end

      if @w_lista_restric = @w_tipo_mr
      begin
        select
          @o_bloqueado = @w_bloqueado
        select
          @o_malaref = @w_malaref
        select
          @o_lista = @w_lista
        select
          @o_mensaje = @w_mensaje
        if @i_crea_ext is null
          select
            @o_mensaje
      end
    end
  end
  --fin wro operacion F

  if @i_operacion = 'V'
  begin
    select
      @w_mensaje = null,
      @w_msg = null,
      @w_lista = null,
      @i_ente = 0,
      @w_num_causa = ''

    if @t_trn <> 172025
    begin
       select @w_message = re_valor                                                                                                                                                                           
       from   cobis..cl_errores 
       inner join cobis..ad_error_i18n 
       on    (numero = pc_codigo_int                                                                                                                                                                                                                        
              and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
       where  numero = 1720121
      if @i_crea_ext is null
      begin
         
        select
          @w_mensaje = @w_message
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
        select
          @o_msg_msv = @w_message + ', ' + @w_sp_name
        select
          @w_return = 1720075
        return @w_return
      end
    end

    -- i wro
    if @i_canal is null
    begin
       select @w_message = re_valor                                                                                                                                                                           
       from   cobis..cl_errores 
       inner join cobis..ad_error_i18n 
       on    (numero = pc_codigo_int                                                                                                                                                                                                                        
              and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
       where  numero = 1720617
      if @i_crea_ext is null
      begin
        select
          @w_mensaje = @w_message
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
        select
          @o_msg_msv =  @w_message + ', ' + @w_sp_name
        select
          @w_return = 1720146
        return @w_return
      end
    end
    -- f wro

    if @i_tipo_id is null
    begin
       select @w_message = re_valor                                                                                                                                                                           
       from   cobis..cl_errores 
       inner join cobis..ad_error_i18n 
       on    (numero = pc_codigo_int                                                                                                                                                                                                                        
              and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
       where  numero = 1720618
      if @i_crea_ext is null
      begin
        select
          @w_mensaje = @w_message
        select
          @w_num_causa = 1
        -- @w_msg =  'TIPO DE IDENTIDAD DEL CLIENTE CON ERROR'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
        select
          @o_msg_msv =  @w_message +', ' + @w_sp_name
        select
          @w_return = 1720147
        return @w_return
      end
    end

    -- 001 es el codigo de  --> SARLAFT-RESTRICTIVAS
    select
      @w_restrictiva = cl_catalogo.codigo --001
    from   cobis..cl_tabla with (nolock),
           cobis..cl_catalogo with (nolock)
    where  cl_tabla.tabla     = 'cl_sarlaf'
       and cl_catalogo.tabla  = cl_tabla.codigo
       and cl_catalogo.codigo = @w_lista_restric

    --set rowcount 1
    select top 1
      @w_in_fecha_ref = convert (varchar(10), in_fecha_ref, 101),
      @w_origen = in_origen,
      @w_nomlar = isnull(in_nomlar,
                         isnull(in_nombre,
                                '')),
      @w_estado = in_estado
    from   cobis..cl_refinh with (nolock)
    where  in_ced_ruc = @i_numero_id
    order  by in_origen desc
    --set rowcount 0 

    if @@rowcount = 0
    begin
      select top 1
        @w_in_fecha_ref = convert (varchar(10), in_fecha_ref, 101),
        @w_origen = in_origen,
        @w_nomlar = isnull(in_nomlar,
                           isnull(in_nombre,
                                  '')),
        @w_estado = in_estado
      from   cobis..cl_refinh with (nolock)
      where  in_otroid = @i_numero_id
      order  by in_origen desc
    end

    select
      @w_tipo_mr = ms_restrictiva
    from   cobis..cl_manejo_sarlaft with (nolock)
    where  ms_origen = @w_origen

    select
      @o_restrictiva = 'N'

    -- si existe en la lista y adicionalmente es RESTRICTIVA se ingresa el registro en la tabla cl_intentos_restrictivas
    if @w_lista_restric = @w_tipo_mr
    begin
      insert into cobis..cl_intentos_restrictivas
                  (ir_fecha_intento,ir_oficina,ir_tipo_documento,
                   ir_numero_documento
                   ,ir_nombre,
                   ir_origen,ir_estado,ir_fecha_lista,ir_canal)
      values      ( getdate(),@s_ofi,@i_tipo_id,@i_numero_id,@w_nomlar,
                    @w_origen,@w_estado,@w_in_fecha_ref,@i_canal )

      if @@error <> 0
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720619
        if @i_crea_ext is null
        begin
          select
            @w_mensaje = @w_message
          select
            @o_retorno = 'S'
          goto REG_ERROR
        end
        else
        begin
          select
            @o_msg_msv =  @w_message + ', ' + @w_sp_name
          select
            @w_return = 1720148
          return @w_return
        end
      end

      select
        @o_restrictiva = 'S'
    end

    --saca codigo del mensaje
    if @w_origen is not null
    begin
      select
        @w_msg = cl_catalogo.valor
      from   cl_catalogo with (nolock),
             cl_tabla with (nolock)
      where  cl_catalogo.codigo = @w_origen
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_tabla.tabla     = 'cl_mreqv'

      if @@rowcount <> 1
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720143
        if @i_crea_ext is null
        begin
          select
            @w_mensaje = @w_message + ' <cl_mreqv>'
          select
            @o_retorno = 'S'
          goto REG_ERROR
        end
        else
        begin
          select
            @o_msg_msv = @w_message + ' <cl_mreqv>, ' +
                         @w_sp_name
          select
            @w_return = 1720143
          return @w_return
        end
      end

      select
        @w_mensaje = cl_catalogo.valor
      from   cl_catalogo with (nolock),
             cl_tabla with (nolock)
      where  cl_catalogo.codigo = @w_msg
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_tabla.tabla     = 'cl_mrmsg'

      if @@rowcount <> 1
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720143
        if @i_crea_ext is null
        begin
          select
            @w_mensaje =  @w_message + ' <cl_mrmsg>'
          select
            @o_retorno = 'S'
          goto REG_ERROR
        end
        else
        begin
          select
            @o_msg_msv = @w_message + ' <cl_mrmsg>, ' +
                         @w_sp_name
          select
            @w_return = 1720143
          return @w_return
        end
      end

      select
        @o_bloqueado = @w_bloqueado
      select
        @o_malaref = @w_malaref
      select
        @o_lista = @w_lista
      select
        @o_mensaje = @w_mensaje
      select
        @o_restrictiva = @o_restrictiva
      if @i_crea_ext is null
      begin
        select
          @o_mensaje
        select
          @o_restrictiva
      end
    end
  end
  --fin wro operacion V

  if @i_operacion = 'B'
  begin
    if @t_trn <> 172025
    begin
      select
        @w_return = 1720075
      goto ERROR_FIN

    end
    
    
    if (select pa_char 
          from cobis..cl_parametro
         where pa_producto='CLI' 
           AND pa_nemonico = 'VAREIN')='S'
    begin -- Validacion VAREIN - INI

      -- i wro
      if @i_canal is null
      begin
        select
          @w_return = 1720074
        goto ERROR_FIN
      /*  'No existe dato solicitado' */
      end
      -- f wro

      if @i_modo = 1
      begin
        select
          @w_bloqueado = 'N',
          --en_tipo_dp , ojo se quita mientras se define por parte del banco los campos a validar
          @w_malaref = en_mala_referencia,
          @w_en_ced_ruc = en_ced_ruc,
          @w_en_nomlar = en_nomlar
        from   cobis..cl_ente with (nolock)
        where  en_ced_ruc  = @i_ced_ruc
           and en_tipo_ced = @i_tipo_ced

        if @@rowcount <> 1
        begin
          select
            @w_return = 1720104--Cliente no existe
          goto ERROR_FIN

        end

      end
      else
      begin
        select
          @w_bloqueado = 'N',
          --en_tipo_dp , ojo se quita mientras se define por parte del banco los campos a validar
          @w_malaref = en_mala_referencia,
          @w_en_ced_ruc = en_ced_ruc,
          @w_en_nomlar = en_nomlar
        from   cobis..cl_ente with (nolock)
        where  en_ente = @i_ente

        if @@rowcount <> 1
        begin
          select
            @w_return = 1720104 --Cliente no existe
          goto ERROR_FIN

        end
      end

      -- 001 es el codigo de  --> SARLAFT-RESTRICTIVAS
      select
        @w_restrictiva = cl_catalogo.codigo --001
      from   cobis..cl_tabla with (nolock),
             cobis..cl_catalogo with (nolock)
      where  cl_tabla.tabla     = 'cl_sarlaf'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @w_lista_restric

      select
        @w_tipo_mr = ms_restrictiva
      from   cobis..cl_manejo_sarlaft with (nolock)
      where  ms_origen = @w_origen

      if @w_malaref = 'S'
      begin
        select
          @w_lista = ''

        select
          @w_lista = in_origen
        from   cobis..cl_refinh with (nolock)
        where  in_ced_ruc   = @w_en_ced_ruc
           and in_fecha_ref = (select
                                 max(in_fecha_ref)
                               from   cobis..cl_refinh
                               where  in_ced_ruc = @w_en_ced_ruc)
           and in_codigo    = (select
                                 max(in_codigo)
                               from   cobis..cl_refinh
                               where  in_ced_ruc = @w_en_ced_ruc)

        if @@rowcount < 1
        begin
          select
            @w_lista = in_origen
          from   cobis..cl_refinh with (nolock)
          where  in_nomlar    = @w_en_nomlar
             and in_fecha_ref = (select
                                   max(in_fecha_ref)
                                 from   cobis..cl_refinh
                                 where  in_nomlar = @w_en_nomlar)
             and in_codigo    = (select
                                   max(in_codigo)
                                 from   cobis..cl_refinh
                                 where  in_nomlar = @w_en_nomlar)
             and in_origen in
                 (select
                    ms_origen
                  from   cobis..cl_manejo_sarlaft
                  where  ms_restrictiva = @w_parlista)

          if @@rowcount < 1
          begin
            select
              @w_lista = @w_ref_mercado,
              @w_malaref = 'N'
            from   cobis..cl_mercado
            where  me_ced_ruc   = @w_en_ced_ruc
               and me_fecha_ref = (select
                                     max(me_fecha_ref)
                                   from   cobis..cl_mercado
                                   where  me_ced_ruc = @w_en_ced_ruc)
               and me_codigo    = (select
                                     max(me_codigo)
                                   from   cobis..cl_mercado
                                   where  me_ced_ruc = @w_en_ced_ruc)

            if @@rowcount < 1
            begin
              select
                @w_lista = @w_ref_mercado,
                @w_malaref = 'N'
              from   cobis..cl_mercado
              where  me_nomlar    = @w_en_nomlar
                 and me_fecha_ref = (select
                                       max(me_fecha_ref)
                                     from   cobis..cl_mercado
                                     where  me_nomlar = @w_en_nomlar)
                 and me_codigo    = (select
                                       max(me_codigo)
                                     from   cobis..cl_mercado
                                     where  me_nomlar = @w_en_nomlar)
            end -- mer1
          end -- mer2
        end
      end
      else
      begin
        select
          @w_lista = ''
      end

      if @w_lista <> ''
      begin
        select
          @w_msg = cl_catalogo.valor
        from   cl_catalogo with (nolock),
               cl_tabla with (nolock)
        where  cl_catalogo.codigo = @w_lista
           and cl_catalogo.tabla  = cl_tabla.codigo
           and cl_tabla.tabla     = 'cl_mreqv'

        if @@rowcount <> 1
        begin
          select
            @w_return = 1720143
          goto ERROR_FIN
        end
        select
          @w_mensaje = cl_catalogo.valor
        from   cl_catalogo with (nolock),
               cl_tabla with (nolock)
        where  cl_catalogo.codigo = @w_msg
           and cl_catalogo.tabla  = cl_tabla.codigo
           and cl_tabla.tabla     = 'cl_mrmsg'

        if @@rowcount <> 1
        begin
          select
            @w_return = 1720143
          goto ERROR_FIN
        end
      end -- ''
      if @i_pago_ext = 'N'
      begin
        select
          @o_bloqueado = @w_bloqueado
        select
          @o_malaref = @w_malaref
        select
          @o_lista = @w_lista
        select
          @o_mensaje = @w_mensaje
        if @i_crea_ext is null
        begin
          select
            @o_bloqueado
          select
            @o_malaref
          select
            @o_lista
          select
            @o_mensaje
        end
      end
    end -- Validacion VAREIN - FIN
  end

  ------------------------------------------------------------------------------------------------------------------------
  -----------JJMD SE GENERA LA MISMA OPCION 'B' EN LA OPCION 'G' PERO SIN LOS SELECTS PARA EL FRONT DE CREDITO -----------
  ------------------------------------------------------------------------------------------------------------------------
  if @i_operacion = 'G'
  begin
    if @t_trn <> 172025
    begin
      select
        @w_return = 1720075
      goto ERROR_FIN

    end

    -- i wro
    if @i_canal is null
    begin
      select
        @w_return = 1720074
      goto ERROR_FIN
    end
    -- f wro

    select
      @w_bloqueado = 'N',
      --en_tipo_dp , ojo se quita mientras se define por parte del banco los campos a validar
      @w_malaref = en_mala_referencia,
      @w_en_ced_ruc = en_ced_ruc,
      @w_en_nomlar = en_nomlar
    from   cobis..cl_ente with (nolock)
    where  en_ente = @i_ente
    if @@rowcount <> 1
    begin
      select
        @w_return = 1720104--Cliente no existe
      goto ERROR_FIN
    end

    -- 001 es el codigo de  --> SARLAFT-RESTRICTIVAS
    select
      @w_restrictiva = cl_catalogo.codigo --001
    from   cobis..cl_tabla with (nolock),
           cobis..cl_catalogo with (nolock)
    where  cl_tabla.tabla     = 'cl_sarlaf'
       and cl_catalogo.tabla  = cl_tabla.codigo
       and cl_catalogo.codigo = @w_lista_restric

    select
      @w_tipo_mr = ms_restrictiva
    from   cobis..cl_manejo_sarlaft with (nolock)
    where  ms_origen = @w_origen

    if @w_malaref = 'S'
    begin
      select
        @w_lista = ''

      select
        @w_lista = in_origen
      from   cobis..cl_refinh
      where  in_ced_ruc   = @w_en_ced_ruc
         and in_fecha_ref = (select
                               max(in_fecha_ref)
                             from   cobis..cl_refinh
                             where  in_ced_ruc = @w_en_ced_ruc)
         and in_codigo    = (select
                               max(in_codigo)
                             from   cobis..cl_refinh
                             where  in_ced_ruc = @w_en_ced_ruc)
      if @@rowcount < 1
      begin
        select
          @w_lista = in_origen
        from   cobis..cl_refinh
        where  in_nomlar    = @w_en_nomlar
           and in_fecha_ref = (select
                                 max(in_fecha_ref)
                               from   cobis..cl_refinh
                               where  in_nomlar = @w_en_nomlar)
           and in_codigo    = (select
                                 max(in_codigo)
                               from   cobis..cl_refinh
                               where  in_nomlar = @w_en_nomlar)
           and in_origen in
               (select
                  ms_origen
                from   cobis..cl_manejo_sarlaft
                where  ms_restrictiva = @w_parlista)

        if @@rowcount < 1
        begin
          select
            @w_lista = @w_ref_mercado,
            @w_malaref = 'N'
          from   cobis..cl_mercado
          where  me_ced_ruc   = @w_en_ced_ruc
             and me_fecha_ref = (select
                                   max(me_fecha_ref)
                                 from   cobis..cl_mercado
                                 where  me_ced_ruc = @w_en_ced_ruc)
             and me_codigo    = (select
                                   max(me_codigo)
                                 from   cobis..cl_mercado
                                 where  me_ced_ruc = @w_en_ced_ruc)

          if @@rowcount < 1
          begin
            select
              @w_lista = @w_ref_mercado,
              @w_malaref = 'N'
            from   cobis..cl_mercado
            where  me_nomlar    = @w_en_nomlar
               and me_fecha_ref = (select
                                     max(me_fecha_ref)
                                   from   cobis..cl_mercado
                                   where  me_nomlar = @w_en_nomlar)
               and me_codigo    = (select
                                     max(me_codigo)
                                   from   cobis..cl_mercado
                                   where  me_nomlar = @w_en_nomlar)
          end -- mer1
        end -- mer2
      end
    end
    else
    begin
      select
        @w_lista = ''
    end

    if @w_lista <> ''
    begin
      --saca codigo del mensaje
      select
        @w_msg = cl_catalogo.valor
      from   cl_catalogo with (nolock),
             cl_tabla with (nolock)
      where  cl_catalogo.codigo = @w_lista
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_tabla.tabla     = 'cl_mreqv'

      if @@rowcount <> 1
      begin
        select
          @w_return = 1720143
        goto ERROR_FIN

      end

      select
        @w_mensaje = cl_catalogo.valor
      from   cl_catalogo with (nolock),
             cl_tabla with (nolock)
      where  cl_catalogo.codigo = @w_msg
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_tabla.tabla     = 'cl_mrmsg'

      if @@rowcount <> 1
      begin
        select
          @w_return = 1720143
        goto ERROR_FIN

      end
    end -- ''

    select
      @o_bloqueado = @w_bloqueado
    select
      @o_malaref = @w_malaref
    select
      @o_lista = @w_lista
    select
      @o_mensaje = @w_mensaje
  --   select @o_bloqueado 
  --   select @o_malaref   
  --   select @o_lista     
  --   select @o_mensaje   

  end

  --Manejo bloqueo masivo  - inicio
  -- calificacion masiva
  if @i_operacion = 'M'
  begin
    if @t_trn <> 172025
    begin
      select
        @w_return = 1720075
      goto ERROR_FIN

    end

    exec @w_return = sp_ente_bloqueado_masivo
      @i_ente = @i_ente

    if @w_return <> 0
    begin
       select @w_message = re_valor                                                                                                                                                                           
       from   cobis..cl_errores 
       inner join cobis..ad_error_i18n 
       on    (numero = pc_codigo_int                                                                                                                                                                                                                        
              and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
       where  numero = 1720614
      if @i_crea_ext is null
      begin
        if @i_pago_ext = 'N'
           print @w_message
      end
      else
        select
          @o_msg_msv = @w_message + ' ID ' + @i_ente + ', ' +
                       @w_sp_name

      return @w_return
    end
  end
  --Manejo bloqueo masivo  - fin

  if @i_operacion = 'U'
  begin
    if @t_trn <> 172026
    begin
      select
        @w_return = 1720075
      goto ERROR_FIN
    end

    select
      @w_en_subtipo = en_subtipo,
      @w_en_tipo_ced = en_tipo_ced,
      @w_en_nombre = en_nombre,
      @w_en_ced_ruc = en_ced_ruc,
      @w_en_actividad = en_actividad,
      @w_en_sector = en_sector,
      @w_p_sexo = p_sexo,
      @w_en_pais = en_pais,
      @w_p_tipo_persona = p_tipo_persona,
      @w_en_procedencia = en_procedencia,
      @w_en_influencia = en_influencia,
      @w_en_subtipo = en_subtipo,
      @w_en_relacint = en_relacint,
      @w_en_recurso_pub = en_recurso_pub,
      @w_en_persona_pub = en_persona_pub,
      @w_en_tipo_vinculacion = en_tipo_vinculacion,
      @w_en_asosciada = en_asosciada,
      @w_en_fecha_negocio = en_fecha_negocio,
      @w_en_estrato = en_estrato,
      @w_p_depa_nac = p_depa_nac,
      @w_p_fecha_nac = p_fecha_nac,
      @w_p_estado_civil = p_estado_civil,
      @w_p_p_apellido = p_p_apellido,
      @w_en_oficial = en_oficial,
      @w_en_casilla_def = en_casilla_def,
      @w_en_reestructurado = en_reestructurado,
      @w_c_tipo_soc = c_tipo_soc,
      @w_en_victima = en_victima
    from   cobis..cl_ente with (nolock)
    where  en_ente = @i_ente

    if @@rowcount <> 1
    begin
      select
        @w_return = 1720104
      goto ERROR_FIN

    end

    select
      @o_retorno = 'N'

    if @w_en_tipo_ced is null
        or @w_en_tipo_ced = ' '
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 1
        -- @w_msg =  'TIPO DE IDENTIDAD DEL CLIENTE CON ERROR'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720147
        select
          @o_msg_msv = @w_message + ', ID ' +
                       @i_ente
                       +
                              ', ' +
                              @w_sp_name
        select
          @w_return = 1720147
        return @w_return
      end
    end

    if @w_en_nombre = '  '
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 2 -- @w_msg =  'FALTA EL NOMBRE  DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720149
        select
          @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720149
        return @w_return
      end
    end

    if @w_en_ced_ruc is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 3
        -- @w_msg =  'NO TIENE NUMERO DE DOCUMENTO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720150
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720150
        return @w_return
      end
    end
    if @w_en_actividad is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 4
        -- @w_msg =  'FALTA ACTIVIDAD ECONOMICA CIIU DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720059
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720059
        return @w_return
      end
    end

    if @w_en_sector is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 5 -- @w_msg =  'FALTA SECTOR ECONOMICO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720042
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720042
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_p_sexo is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 6 -- @w_msg =  'FALTA SEXO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720025
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720025
        return @w_return
      end
    end

    if exists (select
                 1
               from   cl_telefono
               where  te_ente = @i_ente)
    begin
      select
        @w_cont_val = 0
    end
    else
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 7 -- @w_msg =  'FALTA TELEFONO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720151
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720151
        return @w_return
      end
    end

    if @w_p_tipo_persona is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 8 -- @w_msg =  'FALTA TIPO PERSONA DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720058
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720058
        return @w_return
      end
    end

    if @w_en_procedencia is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 9 -- @w_msg =  'FALTA PROCEDENCIA DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720152
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720152
        return @w_return
      end
    end

    if @w_en_influencia is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 10 -- @w_msg =  'FALTA AREA DE INFLUENCIA DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720153
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720153
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_en_victima is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 11
        -- @w_msg = 'FALTA MARCACION VICTIMA HECHOS VIOLENTOS DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720074
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720074
        return @w_return
      end
    end

    if @w_en_relacint is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 12
        -- @w_msg =  'FALTA RELACION INTERNACIONAL DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720154
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720154
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_en_recurso_pub is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 13 -- @w_msg = 'FALTA MANEJO REC PUBLICOS DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720155
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720155
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_en_persona_pub is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 14
        -- @w_msg = 'FALTA MARCA PERSONA PUBLICA DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720153
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720153
        return @w_return
      end
    end

    if @w_en_tipo_vinculacion is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 15
        -- @w_msg = 'FALTA REL CON LA INSTITUCION DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720156
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720156
        return @w_return
      end
    end

    if @w_en_asosciada is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 16 -- @w_msg = 'FALTA REGIMEN FISCAL DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720157
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720157
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_en_fecha_negocio is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 17 -- @w_msg =  'FALTA FECHA NEGOCIO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
        select
          @o_msg_msv = 'FALTA FECHA NEGOCIO DEL CLIENTE ' + @i_ente + ', ' +
                       @w_sp_name         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720158
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720158
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_en_estrato is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 18 -- @w_msg =  'FALTA ESTRATO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720159
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720159
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_p_depa_nac is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 19
        -- @w_msg =  'FALTA DEPA EMISION DOCUMENTO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720160
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720160
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_p_fecha_nac is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 20 -- @w_msg =  'FALTA FECHA NACIMIENTO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720073
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720073
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_p_estado_civil is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 21 -- @w_msg =   'FALTA ESTADO CIVIL DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720057
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720057
        return @w_return
      end
    end

    if @w_en_subtipo = 'P'
       and @w_p_p_apellido is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 22 -- @w_msg =  'FALTA PRIMER APELLIDO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720153
        select  @o_msg_msv = @w_message + 'APE1' + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720153
        return @w_return
      end
    end

    if @w_en_oficial is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 23 -- @w_msg =  'FALTA OFICIAL DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720161
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720161
        return @w_return
      end
    end

    if @w_en_casilla_def is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 24 -- @w_msg =  'FALTA TIPO PRODUCTOR DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720162
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720162
        return @w_return
      end
    end

    if @w_en_reestructurado is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 25 -- @w_msg = 'FALTA EXENTO IMPUESTO DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720163
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720163
        return @w_return
      end
    end

    if @w_en_subtipo = 'C'
       and @w_c_tipo_soc is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 26
        -- @w_msg =  'FALTA TIPO SOCIEDAD DEL CLIENTE EMPRESA'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720163
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720163
        return @w_return
      end
    end

    if @w_en_pais is null
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 27
        -- @w_msg = 'FALTA PAIS NACIMIENTO/CREACION CLIENTE '
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720027
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720027
        return @w_return
      end
    end

    if exists (select
                 1
               from   cl_direccion
               where  di_ente = @i_ente)
    begin
      select
        @w_cont_val = 0
    end
    else
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 28 -- @w_msg =  'FALTA DIRECCION DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720079
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720079
        return @w_return
      end
    end

    if exists (select
                 1
               from   cl_origen_fondos
               where  of_ente = @i_ente)
    begin
      select
        @w_cont_val = 0
    end
    else
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 29 -- @w_msg =  'FALTA ORIGEN DE FONDOS DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720164
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720164
        return @w_return
      end
    end

    if exists (select
                 1
               from   cl_balance
               where  ba_cliente = @i_ente)
    begin
      select
        @w_cont_val = 0
    end
    else
    begin
      if @i_crea_ext is null
      begin
        select
          @w_num_causa = 30 -- @w_msg =  'FALTA BALANCE DEL CLIENTE'
        select
          @o_retorno = 'S'
        goto REG_ERROR
      end
      else
      begin
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720165
        select  @o_msg_msv = @w_message + ' ID: ' + @i_ente + ', ' + @w_sp_name
        select
          @w_return = 1720165
        return @w_return
      end
    end

    update cobis..cl_ente
    set    en_tipo_dp = @o_retorno
    where  en_ente = @i_ente
    delete cobis..cl_log_bloqueo_opt
    where  lb_ente = @i_ente

  end

  return 0

  ERROR_FIN:
  if @i_crea_ext is null
  begin
    if @i_pago_ext = 'N'
    begin
      if @i_linea = 'S'
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = @w_return
      end
    end
  end
  else
  begin
    select
      @w_msg = (select
                  mensaje
                from   cobis..cl_errores
                where  numero = @w_return)

    if @w_msg is null
         select @w_message = re_valor                                                                                                                                                                           
         from   cobis..cl_errores 
         inner join cobis..ad_error_i18n 
         on    (numero = pc_codigo_int                                                                                                                                                                                                                        
                and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
         where  numero = 1720620
    else
      select
        @o_msg_msv = @w_msg + ', ID: ' + cast(@i_ente as varchar) + ', ' +
                                 @w_sp_name
  end

  return @w_return

  REG_ERROR:
  update cobis..cl_ente
  set    en_tipo_dp = 'S'
  where  en_ente = @i_ente

  select
    @w_msg = cb_causa
  from   cl_causa_bloqueo
  where  cb_num_causa = @w_num_causa

  if not exists(select
                  1
                from   cl_log_bloqueo_opt
                where  lb_ente      = @i_ente
                   and lb_num_causa = @w_num_causa)
  begin
    insert cl_log_bloqueo_opt
    values (@i_ente,@w_num_causa,getdate())
  end

  return 0

go

