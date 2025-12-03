/**************************************************************************/
/*  Archivo:                liberacion_listas.sp                          */
/*  Stored procedure:       sp_liberacion_listas                          */
/*  Producto:               Clientes                                      */
/*  Disenado por:           Bruno Duenas                                  */
/*  Fecha de escritura:     12-10-2021                                    */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada; y por lo tanto, derivará en acciones legales civiles        */
/*   y penales en contra del infractor según corresponda.                 */
/**************************************************************************/
/*               PROPOSITO                                                */
/*   Este programa se usa para consulta de coincidencias en listas negras */
/*    y su liberacion respectiva                                          */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA       AUTOR           RAZON                                     */
/*  12-10-2021  BDU             Emision inicial                           */
/*  19-07-2023  BDU             Ajustes query                             */
/*  19-09-2023  DMO             Se valida estado X para campo en_estado   */
/*  24-10-2023  BDU             Se agrega estado X para tiempo de validez */
/*  07-11-2023  DMO             R218833: Se añade validacion para app     */
/*  10-11-2023  BDU             R219133: Se corrige estados y operacion V */
/*  06-03-2023  BDU             R228486: Se corrige validación operacion C*/
/*  12-03-2023  BDU             R228486: Se corrige validación operacion C*/
/*                              cuando la consulta tiene 0 coincidencias  */
/*  29-05-2024  DMO             R233137: Se corrige validaciones          */
/**************************************************************************/


use cobis
GO
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
if exists (select 1 from sysobjects where name = 'sp_liberacion_listas')
   drop proc sp_liberacion_listas
go

create proc sp_liberacion_listas (
   @s_ssn                     int,
   @s_sesn                    int           = null,
   @s_user                    login         = null,
   @s_term                    varchar(32)   = null,
   @s_date                    datetime,
   @s_srv                     varchar(30)   = null,
   @s_lsrv                    varchar(30)   = null,
   @s_ofi                     smallint      = null,
   @s_rol                     smallint      = null,
   @s_org_err                 char(1)       = null,
   @s_error                   int           = null,
   @s_sev                     tinyint       = null,
   @s_msg                     descripcion   = null,
   @s_org                     char(1)       = null,
   @s_culture                 varchar(10)   = 'NEUTRAL',
   @t_debug                   char(1)       = 'n',
   @t_file                    varchar(10)   = null,
   @t_from                    varchar(32)   = null,
   @t_trn                     int           = null,
   @t_show_version            bit           = 0,     -- versionamiento
   @i_operacion               char(1),
   @i_nombres                 varchar(60)   = null,
   @i_apellidos               varchar(60)   = null,
   @i_ente                    int           = null,
   @i_tipo                    char(1)       = null,
   @i_id                      varchar(51)   = null, --Codigo id
   @i_aml                     varchar(20)   = null, --Codigo aml
   @i_justificacion           varchar(500)  = null, --Justificacion
   @i_estado                  catalogo      = null, --Estado proceso
   @i_numero_coincidencia     int           = null,
   @i_nro_proceso             int           = null,
   @i_cat_valor               char(2)       = null,
   @i_primer_nombre           varchar(100)  = null,
   @i_segundo_nombre          varchar(100)  = null,
   @i_primer_apellido         varchar(100)  = null,
   @i_segundo_apellido        varchar(100)  = null,
   @i_apellido_casada         varchar(100)  = null,
   @i_numero_iden             varchar(100)  = null,
   @i_tipo_iden               varchar(100)  = null,
   @i_num_verificacion        varchar(51)   = null,
   @i_is_app                  char(1)       = 'N',
   @o_ejecuta                 char(2)       = null output,
   @o_accuracy                tinyint       = null output,
   @o_pais_verifica           varchar(30)   = null output
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_oficial               int,
        @w_trn_dir               int,
        @w_error                 int,
        @w_operacion             char(1),
        @w_existente             bit,
        @w_init_msg_error        varchar(256),
        @w_valor_campo           varchar(30),
        @w_prospecto             char(1)       = 'P',
        @w_param                 int, 
        @w_diff                  int, 
        @w_date                  datetime,
        @w_existe                char(1)       = 'S',
        @w_bloqueo               char(1),
        @w_query                 varchar(1000),
        @w_num                   int,
        @w_p_nom                 varchar(100),
        @w_s_nom                 varchar(100),
        @w_p_ape                 varchar(100),
        @w_s_ape                 varchar(100),
        @w_c_ape                 varchar(100),
        @w_num_iden              varchar(100),
        @w_tipo_iden             varchar(100),
        @w_codigo_cliente        int,
        @w_tramite               int,
        @w_relacion_ca           tinyint,
        @w_doc_prin_mascara      varchar(30),
        @w_mascara               varchar(30),
        @w_pais_local            int,
        @w_pais_ente             int,
        @w_nacionalidad          varchar(10)
/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cobis..sp_liberacion_listas',
@w_operacion        = '',
@w_error            = 1720548



if @i_is_app = 'S'
begin
    select @w_pais_ente = en_pais from cobis..cl_ente where en_ente = @i_ente
    select @w_pais_local   = convert(varchar,pa_smallint) from cobis..cl_parametro where pa_nemonico = 'CP'  and pa_producto = 'CLI'
    
    if @w_pais_ente <> @w_pais_local
    begin
        select @w_nacionalidad = 'E'
    end
    else
    begin
        select @w_nacionalidad = 'N'
    end
    
    
    if @i_tipo_iden = 'DUI'  and charindex('-', @i_numero_iden) = 0
    begin
        --Tipo de identificación Principal
        select @w_mascara = ti_mascara
        from  cobis..cl_tipo_identificacion
        where ti_codigo = @i_tipo_iden
        and   ti_tipo_cliente = 'P'
        and   ti_tipo_documento = 'P'
        and   ti_nacionalidad   = @w_nacionalidad
        and   ti_estado = 'V'
        
        select @w_doc_prin_mascara = cobis.dbo.fn_parsea_identificacion (@i_numero_iden, @w_mascara)
        select @i_numero_iden = @w_doc_prin_mascara
    end
end

if @i_operacion = 'S'
begin

   set @w_query = 'declare cursor_cliente cursor read_only for select distinct ne_codigo_cliente from cl_listas_negras_rfe with (nolock)'
   if(@i_ente is not null)
   begin
      set @w_query += ' where ne_codigo_cliente = '+ convert(varchar, @i_ente)
   end
   else
   begin
      if(@i_nombres is not null or @i_apellidos is not null)
      begin
         set @w_query += ' where'

         if(@i_nombres is not null)
            set @w_query += ' ne_nombre like' + char(39) + '%' +@i_nombres  + '%'  +char(39)

         if(@i_apellidos is not null and @i_nombres is not null)
            set @w_query += ' and ne_apellido like' + char(39) + '%' + @i_apellidos + '%'  + char(39)

         else if (@i_apellidos is not null and @i_nombres is null)
            set @w_query += ' ne_apellido like' + char(39) + '%' + @i_apellidos + '%'  + char(39)
      end
   end

   exec(@w_query)
   if (OBJECT_ID('tempdb.dbo.#tmp_listas_grilla_c','U')) is not null
   begin
      drop table #tmp_listas_grilla_c
   end
   create table #tmp_listas_grilla_c
   (
      tmp_codigo_cliente int,
      tmp_nombre varchar(255),
      tmp_apellido varchar(255),
      tmp_coincidencia int,
      tmp_id_verificacion varchar(51),
      tmp_estado_resolucion char(1),
      tmp_nro_aml varchar(20),
      tmp_justificacion varchar(255),
      tmp_fecha_resolucion datetime
   )

   open cursor_cliente
   fetch next from cursor_cliente into @w_codigo_cliente
   while @@fetch_status = 0
   begin
      insert into #tmp_listas_grilla_c
      select top 1
            ne_codigo_cliente, ne_nombre,            ne_apellido,
            ne_coincidencia,   ne_id_verificacion,   ne_estado_resolucion, 
            ne_nro_aml,        ne_justificacion,     ne_fecha_resolucion
      from cl_listas_negras_rfe
      where ne_codigo_cliente = @w_codigo_cliente
      and (ne_estado_resolucion = 'S' or ne_estado_resolucion is null)
      and ne_fecha_resolucion = (select max(ne_fecha_resolucion) from cl_listas_negras_rfe where ne_codigo_cliente = @w_codigo_cliente)
      order by ne_fecha_resolucion desc
         
      fetch next from cursor_cliente into @w_codigo_cliente
   end

   close cursor_cliente
   deallocate cursor_cliente


   select  tmp_codigo_cliente, tmp_nombre,            tmp_apellido,
           tmp_coincidencia,   tmp_id_verificacion,   tmp_estado_resolucion, 
           tmp_nro_aml,        tmp_justificacion,     convert(varchar,tmp_fecha_resolucion,101) 
   from #tmp_listas_grilla_c
   
end

if @i_operacion = 'C'
begin
   select @o_accuracy      = pa_tinyint  from cobis..cl_parametro where pa_nemonico = 'PCLN'   and pa_producto = 'CLI'
   select @o_pais_verifica = pa_char     from cobis..cl_parametro where pa_nemonico = 'ABPAIS' and pa_producto = 'ADM'
   select @w_param         = isnull(pa_int, 0)      from cobis..cl_parametro where pa_nemonico = 'MVROC'  and pa_producto = 'CLI' --TIEMPO DE VALIDEZ REGISTRO
   select @o_ejecuta = 'NS' --NO EJECUTA Y GUARDA
   set @w_existe = 'N'
   if @i_ente is not null and @i_ente <> 0
   begin
      if exists(select 1 from cl_listas_negras_log
                         where ln_codigo_cliente = @i_ente )
      begin
      
         select top 1 @w_num = ln_numero_coincidencias,
                      @w_date = ln_fecha_consulta        
         from cl_listas_negras_log 
         where ln_codigo_cliente = @i_ente
         order by ln_fecha_consulta desc
         
         if @w_num >= 0
         begin
            set @w_existe = 'S'
            
            if(@w_num > 0) --está en RFE
            begin
               select top 1 @w_date    = ne_fecha_resolucion,
                            @w_bloqueo = ne_estado_resolucion
               from cl_listas_negras_rfe 
               where ne_codigo_cliente = @i_ente 
               order by ne_fecha_resolucion desc
            end
            
            set @w_bloqueo = isnull(@w_bloqueo, 'V')
            set @w_diff = datediff (day, @w_date, getdate())
         
         
         
            if  @w_diff > @w_param --Si supera el tiempo permitido consulta si o si
            begin
               select @o_ejecuta = 'SC' --SI EJECUTA Y COMPRUEBA
            end
            else
            begin
               if (@w_diff <= @w_param and @w_bloqueo in ('N','X') and @w_num > 0) --DESBLOQUEAR,DESBLOQUEAR CON EXCEPCIÓN (Estados permitidos) en RFE
                  or (@w_diff <= @w_param  and @w_num = 0 and @w_bloqueo in ('V')) --Consulta válida sin coincidencias
               begin
                  select @o_ejecuta = 'NS' --NO EJECUTA Y GUARDA
               end
               else
               begin
                  select @o_ejecuta = 'NN'--NO EJECUTA Y NO GUARDA
               end
            end
         end
      end
   end
   if @w_existe = 'N'
   begin
      select @o_ejecuta = 'SC' --SI EJECUTA Y COMPRUEBA
   end
end

if @i_operacion = 'V'
begin
   select @o_accuracy      = pa_tinyint  from cobis..cl_parametro where pa_nemonico = 'PCLN'   and pa_producto = 'CLI'
   select @o_pais_verifica = pa_char     from cobis..cl_parametro where pa_nemonico = 'ABPAIS' and pa_producto = 'ADM'
   select @w_param         = pa_int      from cobis..cl_parametro where pa_nemonico = 'MVROC'  and pa_producto = 'CLI'
   select @o_ejecuta = 'NS'
   
   if not exists(select 1 from cl_listas_negras_log
                 where ln_codigo_cliente = @i_ente ) --Nunca ha sido consultado en listas negras
   begin
      select @o_ejecuta = 'SC'
   end
   else
   begin
      if @i_tipo = 'P'
      begin
         select @w_p_nom     = en_nombre, 
                @w_tipo_iden = en_tipo_ced, 
                @w_num_iden  = en_ced_ruc, 
                @w_s_nom     = p_s_nombre, 
                @w_p_ape     = p_p_apellido, 
                @w_s_ape     = p_s_apellido, 
                @w_c_ape     = p_c_apellido 
         from cl_ente where en_ente = @i_ente
         
         if    isnull(@i_primer_nombre,'')   != isnull(@w_p_nom,'') or isnull(@i_segundo_nombre,'')   != isnull(@w_s_nom,'') 
            or isnull(@i_primer_apellido,'') != isnull(@w_p_ape,'') or isnull(@i_segundo_apellido,'') != isnull(@w_s_ape,'')
            or isnull(@i_apellido_casada,'') != isnull(@w_c_ape,'') or isnull(@i_numero_iden,'')      != isnull(@w_num_iden,'')
            or isnull(@i_tipo_iden,'')       != isnull(@w_tipo_iden,'')
         begin
            select @o_ejecuta = 'SC'
         end
      end
      else
      begin
         select @w_p_nom     = en_nombre, 
                @w_tipo_iden = en_tipo_ced, 
                @w_num_iden  = en_ced_ruc
         from cl_ente where en_ente = @i_ente
         
         if    @i_primer_nombre   != @w_p_nom  or @i_numero_iden != @w_num_iden
            or @i_tipo_iden       != @w_tipo_iden
         begin
            select @o_ejecuta = 'SC'
         end
      end
   end
end

if @i_operacion = 'I'
begin

   begin tran
   if not exists(select 1 from cl_listas_negras_rfe where ne_codigo_cliente = @i_ente and ne_nro_proceso = @i_nro_proceso)
   begin
      insert into cl_listas_negras_rfe (ne_id_verificacion,       ne_coincidencia,        ne_nombre,            ne_apellido,              ne_tipo_persona,
                                        ne_codigo_cliente,        ne_nro_proceso,         ne_justificacion,     ne_estado_resolucion,     ne_fecha_resolucion,
                                        ne_nro_aml)
      values                           (@i_id,                    @i_numero_coincidencia, @i_nombres,           @i_apellidos,             @i_tipo,
                                        @i_ente,                  @i_nro_proceso,         @i_justificacion,     @i_estado,                getDate(),
                                        @i_aml)
      
      --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      if @@error <> 0 begin
         select @w_error = 1720578
         goto ERROR_FIN
      end
      
      insert into ts_listas_negras (
               secuencial,              tipo_transaccion,               clase,
               fecha,                   usuario,                        terminal, 
               srv,                     lsrv,                           ne_id_verificacion,    
               ne_coincidencia,         ne_nombre,                      ne_apellido,         
               ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,     
               ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
               ne_nro_aml)
      values  (@s_ssn,                  @t_trn,                         'A',
               getdate(),               @s_user,                        @s_term,
               @s_srv,                  @s_lsrv,                        @i_id,
               @i_numero_coincidencia,  @i_nombres,                     @i_apellidos,
               @i_tipo,                 @i_ente,                        @i_nro_proceso,
               @i_justificacion,        @i_estado,                      getDate(),
               @i_aml)
      
      --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      if @@error <> 0 begin
         select @w_error = 1720049
         goto ERROR_FIN
   end
   end
   else
   begin
         --Registro antes del cambio
      insert into ts_listas_negras (
      secuencial,              tipo_transaccion,               clase,
      fecha,                   usuario,                        terminal,
      srv,                     lsrv,                           ne_id_verificacion,
      ne_coincidencia,         ne_nombre,                      ne_apellido,
      ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
      ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
      ne_nro_aml)
      select
      @s_ssn,                  @t_trn,                         'A',
      getdate(),               @s_user,                        @s_term,
      @s_srv,                  @s_lsrv,                        @i_id,
      ne_coincidencia,         ne_nombre,                      ne_apellido,
      ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
      ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
      ne_nro_aml
      from cl_listas_negras_rfe
      where ne_codigo_cliente = @i_ente
      --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      if @@error <> 0 begin
         select @w_error = 1720049
         goto ERROR_FIN
      end
      update cl_listas_negras_rfe set ne_justificacion     = @i_justificacion, 
                                      ne_coincidencia      = @i_numero_coincidencia, 
                                      ne_estado_resolucion = null, 
                                      ne_fecha_resolucion  = getdate(),
                                      ne_id_verificacion   = @i_id,
                                      ne_nombre            = @i_nombres,
                                      ne_apellido          = @i_apellidos
      where ne_codigo_cliente = @i_ente
      and ne_nro_proceso = @i_nro_proceso
      
      --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      if @@error <> 0 begin
         select @w_error = 1720578
         goto ERROR_FIN
      end
      
      --Registro despues del cambio
      insert into ts_listas_negras (
      secuencial,              tipo_transaccion,               clase,
      fecha,                   usuario,                        terminal,
      srv,                     lsrv,                           ne_id_verificacion,
      ne_coincidencia,         ne_nombre,                      ne_apellido,
      ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
      ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
      ne_nro_aml)
      select
      @s_ssn,                  @t_trn,                         'D',
      getdate(),               @s_user,                        @s_term,
      @s_srv,                  @s_lsrv,                        @i_id,
      ne_coincidencia,         ne_nombre,                      ne_apellido,
      ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
      ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
      ne_nro_aml
      from cl_listas_negras_rfe
      where ne_codigo_cliente = @i_ente
      --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      if @@error <> 0 begin
         select @w_error = 1720049
         goto ERROR_FIN
      end
      
   end

   

   if isnull(@i_ente ,'') <> ''
   begin
      

      --Registro al cambiar
      insert into ts_persona(
      secuencial,          tipo_transaccion,    clase,
      fecha,               usuario,             terminal,
      srv,                 lsrv,                persona,
      nombre,              p_apellido,          s_apellido,
      sexo,                cedula,              pasaporte,
      tipo_ced,            pais,                profesion,
      estado_civil,        actividad,           num_cargas,
      nivel_ing,           nivel_egr,           tipo,
      filial,              oficina,             casilla_def,
      tipo_dp,             fecha_nac,           grupo,
      oficial,             mala_referencia,     comentario,
      retencion,           fecha_mod,           fecha_emision,
      fecha_expira,        asosciada,           referido,
      sector,              ciudad_nac,          lugar_doc,
      nivel_estudio,       tipo_vivienda,       calif_cliente,
      doc_validado,        rep_superban,        vinculacion,
      tipo_vinculacion,    exc_sipla,           exc_por2,
      digito,              depa_nac,            pais_emi,
      depa_emi,            categoria,           pasivo,
      pensionado,          num_empleados,       pas_finan,
      fpas_finan,          ts_accion,           ts_estrato,
      ts_fecha_negocio,    ts_ofi_prod,         ts_procedencia,
      ts_num_hijos,        recur_pub,           influencia,
      pers_pub,            victima,             vigencia,
      oficial_asig,        num_hijos,           en_estado)
      select
      @s_ssn,              @t_trn,              'A',
      getdate(),           @s_user,             @s_term,
      @s_srv,              @s_lsrv,             @i_ente,
      en_nombre,           p_p_apellido,        p_s_apellido,
      p_sexo,              en_ced_ruc,          p_pasaporte,
      en_tipo_ced,         en_pais,             p_ocupacion,
      p_estado_civil,      en_actividad,        p_num_cargas,
      p_nivel_ing,         p_nivel_egr,         en_subtipo,
      en_filial,           en_oficina,          en_casilla_def,
      en_tipo_dp,          p_fecha_nac,         en_grupo,
      en_oficial,          en_mala_referencia,  en_comentario,
      en_retencion,        en_fecha_mod,        p_fecha_emision,
      p_fecha_expira,      en_asosciada,        en_referido,
      en_sector,           p_ciudad_nac,        p_lugar_doc,
      p_nivel_estudio,     p_tipo_vivienda,     en_calificacion,
      en_doc_validado,     en_rep_superban,     en_vinculacion,
      en_tipo_vinculacion, en_exc_sipla,        en_exc_por2,
      en_digito,           p_depa_nac,          p_pais_emi,
      p_depa_emi,          en_categoria,        c_pasivo,
      en_pensionado,       c_num_empleados,     en_pas_finan,
      en_fpas_finan,       en_accion,           en_estrato,
      en_fecha_negocio,    en_oficina_prod,     en_procedencia,
      p_num_hijos,         en_recurso_pub,      en_influencia,
      en_persona_pub,      en_victima,          c_vigencia,
      @s_ofi,              p_num_hijos,         en_estado
      from cl_ente
      where en_ente    = @i_ente
      
      --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      if @@error <> 0 begin
         select @w_error = 1720049
         goto ERROR_FIN
      end

   end

   commit tran

end

if @i_operacion = 'U'
begin
   if isnull(@i_id, '') = ''
   begin
      select @w_valor_campo  = '@i_id'
      goto VALIDAR_ERROR
   end

   if isnull(@i_justificacion, '') = ''
   begin
      select @w_valor_campo  = '@i_justificacion'
      goto VALIDAR_ERROR
   end

   if isnull(@i_estado, '') = ''
   begin
      select @w_valor_campo  = '@i_estado'
      goto VALIDAR_ERROR
   end

   if isnull(@i_ente, '') = ''
   begin
      select @w_valor_campo  = '@i_ente'
      goto VALIDAR_ERROR
   end

   begin tran
   
   --Registro antes del cambio
   insert into ts_listas_negras (
   secuencial,              tipo_transaccion,               clase,
   fecha,                   usuario,                        terminal,
   srv,                     lsrv,                           ne_id_verificacion,
   ne_coincidencia,         ne_nombre,                      ne_apellido,
   ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
   ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
   ne_nro_aml)
   select
   @s_ssn,                  @t_trn,                         'A',
   getdate(),               @s_user,                        @s_term,
   @s_srv,                  @s_lsrv,                        @i_id,
   ne_coincidencia,         ne_nombre,                      ne_apellido,
   ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
   ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
   ne_nro_aml
   from cl_listas_negras_rfe
   where ne_codigo_cliente = @i_ente
   and ne_estado_resolucion is null

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   --Creacion de tabla temporal para ts
   if (OBJECT_ID('tempdb.dbo.#tmp_listas_negras','U')) is not null
   begin
      drop table #tmp_listas_negras
   end
   create table #tmp_listas_negras
   (
       tmp_id varchar(51) null
   )

   insert into #tmp_listas_negras
   select ne_id_verificacion
   from cl_listas_negras_rfe
   where ne_codigo_cliente = @i_ente
   and (ne_estado_resolucion is null
   or ne_fecha_resolucion = (select max(ne_fecha_resolucion) from cl_listas_negras_rfe where ne_codigo_cliente = @i_ente)
   )

   update cl_listas_negras_rfe 
   set
   ne_nro_aml               = @i_aml,
   ne_justificacion         = @i_justificacion,
   ne_estado_resolucion     = @i_estado,
   ne_fecha_resolucion      = getdate()
   where ne_codigo_cliente = @i_ente
   and (ne_estado_resolucion is null
   or ne_fecha_resolucion = (select max(ne_fecha_resolucion) from cl_listas_negras_rfe where ne_codigo_cliente = @i_ente)
   )

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720579
      goto ERROR_FIN
   end

   --Registro despues del cambio
   insert into ts_listas_negras (
   secuencial,              tipo_transaccion,               clase,
   fecha,                   usuario,                        terminal,
   srv,                     lsrv,                           ne_id_verificacion,
   ne_coincidencia,         ne_nombre,                      ne_apellido,
   ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
   ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
   ne_nro_aml)
   select
   @s_ssn,                  @t_trn,                         'D',
   getdate(),               @s_user,                        @s_term,
   @s_srv,                  @s_lsrv,                        @i_id,
   ne_coincidencia,         ne_nombre,                      ne_apellido,
   ne_tipo_persona,         ne_codigo_cliente,              ne_nro_proceso,
   ne_justificacion,        ne_estado_resolucion,           ne_fecha_resolucion,
   ne_nro_aml
   from cl_listas_negras_rfe,
   #tmp_listas_negras
   where tmp_id = ne_id_verificacion
   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end

   if not isnull(@i_ente, '') = ''
   begin
   
      if(trim(@i_estado) = 'X') select @i_estado = 'N'
      
      --Registro antes del cambio
      insert into ts_persona(
      secuencial,          tipo_transaccion,    clase,
      fecha,               usuario,             terminal,
      srv,                 lsrv,                persona,
      nombre,              p_apellido,          s_apellido,
      sexo,                cedula,              pasaporte,
      tipo_ced,            pais,                profesion,
      estado_civil,        actividad,           num_cargas,
      nivel_ing,           nivel_egr,           tipo,
      filial,              oficina,             casilla_def,
      tipo_dp,             fecha_nac,           grupo,
      oficial,             mala_referencia,     comentario,
      retencion,           fecha_mod,           fecha_emision,
      fecha_expira,        asosciada,           referido,
      sector,              ciudad_nac,          lugar_doc,
      nivel_estudio,       tipo_vivienda,       calif_cliente,
      doc_validado,        rep_superban,        vinculacion,
      tipo_vinculacion,    exc_sipla,           exc_por2,
      digito,              depa_nac,            pais_emi,
      depa_emi,            categoria,           pasivo,
      pensionado,          num_empleados,       pas_finan,
      fpas_finan,          ts_accion,           ts_estrato,
      ts_fecha_negocio,    ts_ofi_prod,         ts_procedencia,
      ts_num_hijos,        recur_pub,           influencia,
      pers_pub,            victima,             vigencia,
      oficial_asig,        num_hijos,           en_estado)
      select
      @s_ssn,              @t_trn,              'A',
      getdate(),           @s_user,             @s_term,
      @s_srv,              @s_lsrv,             @i_ente,
      en_nombre,           p_p_apellido,        p_s_apellido,
      p_sexo,              en_ced_ruc,          p_pasaporte,
      en_tipo_ced,         en_pais,             p_ocupacion,
      p_estado_civil,      en_actividad,        p_num_cargas,
      p_nivel_ing,         p_nivel_egr,         en_subtipo,
      en_filial,           en_oficina,          en_casilla_def,
      en_tipo_dp,          p_fecha_nac,         en_grupo,
      en_oficial,          en_mala_referencia,  en_comentario,
      en_retencion,        en_fecha_mod,        p_fecha_emision,
      p_fecha_expira,      en_asosciada,        en_referido,
      en_sector,           p_ciudad_nac,        p_lugar_doc,
      p_nivel_estudio,     p_tipo_vivienda,     en_calificacion,
      en_doc_validado,     en_rep_superban,     en_vinculacion,
      en_tipo_vinculacion, en_exc_sipla,        en_exc_por2,
      en_digito,           p_depa_nac,          p_pais_emi,
      p_depa_emi,          en_categoria,        c_pasivo,
      en_pensionado,       c_num_empleados,     en_pas_finan,
      en_fpas_finan,       en_accion,           en_estrato,
      en_fecha_negocio,    en_oficina_prod,     en_procedencia,
      p_num_hijos,         en_recurso_pub,      en_influencia,
      en_persona_pub,      en_victima,          c_vigencia,
      @s_ofi,              p_num_hijos,         en_estado
      from cl_ente
      where en_ente    = @i_ente
      
      --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      if @@error <> 0 begin
         select @w_error = 1720049
         goto ERROR_FIN
      end

      update cl_ente 
      set
      en_estado = @i_estado,
      en_fecha_mod = getdate()
      where en_ente = @i_ente

      --Registro despues del cambio
      insert into ts_persona(
      secuencial,          tipo_transaccion,    clase,
      fecha,               usuario,             terminal,
      srv,                 lsrv,                persona,
      nombre,              p_apellido,          s_apellido,
      sexo,                cedula,              pasaporte,
      tipo_ced,            pais,                profesion,
      estado_civil,        actividad,           num_cargas,
      nivel_ing,           nivel_egr,           tipo,
      filial,              oficina,             casilla_def,
      tipo_dp,             fecha_nac,           grupo,
      oficial,             mala_referencia,     comentario,
      retencion,           fecha_mod,           fecha_emision,
      fecha_expira,        asosciada,           referido,
      sector,              ciudad_nac,          lugar_doc,
      nivel_estudio,       tipo_vivienda,       calif_cliente,
      doc_validado,        rep_superban,        vinculacion,
      tipo_vinculacion,    exc_sipla,           exc_por2,
      digito,              depa_nac,            pais_emi,
      depa_emi,            categoria,           pasivo,
      pensionado,          num_empleados,       pas_finan,
      fpas_finan,          ts_accion,           ts_estrato,
      ts_fecha_negocio,    ts_ofi_prod,         ts_procedencia,
      ts_num_hijos,        recur_pub,           influencia,
      pers_pub,            victima,             vigencia,
      oficial_asig,        num_hijos,           en_estado)
      select
      @s_ssn,              @t_trn,              'D',
      getdate(),           @s_user,             @s_term,
      @s_srv,              @s_lsrv,             @i_ente,
      en_nombre,           p_p_apellido,        p_s_apellido,
      p_sexo,              en_ced_ruc,          p_pasaporte,
      en_tipo_ced,         en_pais,             p_ocupacion,
      p_estado_civil,      en_actividad,        p_num_cargas,
      p_nivel_ing,         p_nivel_egr,         en_subtipo,
      en_filial,           en_oficina,          en_casilla_def,
      en_tipo_dp,          p_fecha_nac,         en_grupo,
      en_oficial,          en_mala_referencia,  en_comentario,
      en_retencion,        en_fecha_mod,        p_fecha_emision,
      p_fecha_expira,      en_asosciada,        en_referido,
      en_sector,           p_ciudad_nac,        p_lugar_doc,
      p_nivel_estudio,     p_tipo_vivienda,     en_calificacion,
      en_doc_validado,     en_rep_superban,     en_vinculacion,
      en_tipo_vinculacion, en_exc_sipla,        en_exc_por2,
      en_digito,           p_depa_nac,          p_pais_emi,
      p_depa_emi,          en_categoria,        c_pasivo,
      en_pensionado,       c_num_empleados,     en_pas_finan,
      en_fpas_finan,       en_accion,           en_estrato,
      en_fecha_negocio,    en_oficina_prod,     en_procedencia,
      p_num_hijos,         en_recurso_pub,      en_influencia,
      en_persona_pub,      en_victima,          c_vigencia,
      @s_ofi,              p_num_hijos,         en_estado
      from cl_ente
      where en_ente    = @i_ente
      
      --ERROR EN CREACION DE TRANSACCION DE SERVICIO
      if @@error <> 0 begin
         select @w_error = 1720049
         goto ERROR_FIN
      end

   end

   commit tran
end

if @i_operacion = 'Q'
begin
   if not isnull(@i_ente, '') = ''
   begin
      if exists(select 1 from cl_cliente where cl_cliente = @i_ente)
         select @w_prospecto = 'C'

      select en_nomlar,    en_subtipo, en_tipo_ced, 
             @w_prospecto, of_nombre,  en_ced_ruc
      from cl_ente, cl_oficina
      where en_ente = @i_ente
      and en_oficina = of_oficina
   end
   else
   begin --Cliente especifico cuando es flujo
      select concat(ne_nombre,' ' ,ne_apellido), ne_estado_resolucion, ne_nro_aml,
             ne_justificacion
      from cobis..cl_listas_negras_rfe 
      where ne_id_verificacion = @i_num_verificacion
   end
   
end

if @i_operacion = 'G' --Carga grilla
begin

   if isnull(@i_nro_proceso, '') = ''
   begin
      select @w_valor_campo  = '@i_nro_proceso'
      goto VALIDAR_ERROR
   end
   
   if (OBJECT_ID('tempdb.dbo.#tmp_listas_grilla','U')) is not null
   begin
      drop table #tmp_listas_grilla
   end
   create table #tmp_listas_grilla
   (
      tmp_id_verificacion   varchar(51)  null,
      tmp_ente              int          null,
      tmp_nomlar            varchar(254) null,
      tmp_tipo_ced          char(4)      null,
      tmp_ced_ruc           numero       null,
      tmp_coincidencia      int          null,
      tmp_estado_resolucion char(1)      null
   )
   
   if not exists( select 1 from cob_workflow..wf_inst_proceso, cob_credito..cr_tramite_grupal
                  where io_id_inst_proc = @i_nro_proceso
                  and   tg_tramite      = io_campo_3)
   begin
      --Persona Natural o Juridica
      select @w_tramite        = io_campo_3
      from cob_workflow..wf_inst_proceso
      where io_id_inst_proc = @i_nro_proceso

      select @w_relacion_ca = (select pa_tinyint from cobis..cl_parametro
                               where pa_nemonico = 'CONY' 
                               and   pa_producto = 'CLI')
      --TABLA TEMPORAL PARA SACAR LA LISTA DE PARTICIPANTES
      if (OBJECT_ID('tempdb.dbo.#tmp_listas_part','U')) is not null
      begin
         drop table #tmp_listas_part
      end
      create table #tmp_listas_part
      (
         tmp_id             int     null,
         tmp_representante  int     null,
         tmp_tipo_cliente   char(1) null
      )
      --SE AÑADE DEUDOR PRINCIPAL Y CODEUDORES
      insert into #tmp_listas_part
      (tmp_id, tmp_tipo_cliente, tmp_representante)
      select 
      en_ente, en_subtipo,       c_rep_legal
      from cobis..cl_ente ,cob_credito..cr_deudores 
      where de_tramite = @w_tramite and en_ente = de_cliente

      --SE AÑADE GARANTES                              
      insert into #tmp_listas_part
      (tmp_id, tmp_tipo_cliente)
      select 
      en_ente, en_subtipo   
      from cob_custodia..cu_custodia  , cob_credito..cr_gar_propuesta , cobis..cl_ente where  
      cu_codigo_externo = gp_garantia and gp_tramite = @w_tramite  and cu_garante is not null
      and  en_ente = cu_garante

      --AÑADE   A SUS REPRESENTANTES LEGALES
      insert into #tmp_listas_part
      (tmp_id, tmp_tipo_cliente, tmp_representante)
      select 
      en_ente, en_subtipo,       c_rep_legal
      from cobis..cl_ente
      where  en_ente in(select tmp_representante from #tmp_listas_part
                        where tmp_tipo_cliente = 'C')
   
      --SE AÑADE CONYUGES   
      insert into #tmp_listas_part
      (tmp_id, tmp_tipo_cliente)
      select 
      en_ente, en_subtipo
      from #tmp_listas_part, cobis..cl_instancia, cobis..cl_ente
      where tmp_id = in_ente_i and in_relacion = @w_relacion_ca and in_ente_d = en_ente

      declare cursor_cliente cursor read_only 
      for select distinct tmp_id 
      from #tmp_listas_part
      
      open cursor_cliente
      fetch next from cursor_cliente into @w_codigo_cliente
      while @@fetch_status = 0
      begin
         insert into #tmp_listas_grilla
         select top 1
             ne_id_verificacion,   en_ente,    en_nomlar, 
             en_tipo_ced,          en_ced_ruc, ne_coincidencia, 
             ne_estado_resolucion
         from cl_listas_negras_rfe, cl_ente
         where ne_codigo_cliente = @w_codigo_cliente
         and ne_codigo_cliente = en_ente
         and (ne_estado_resolucion = 'S' or ne_estado_resolucion is null)
		 and ne_nro_proceso = @i_nro_proceso
         order by ne_fecha_resolucion desc
         
         fetch next from cursor_cliente into @w_codigo_cliente
      end
      
      close cursor_cliente
      deallocate cursor_cliente

   end
   else
   begin
      --Grupo Solidario o Economico
      declare cursor_cliente cursor read_only 
      for select cg_ente
      from cob_workflow..wf_inst_proceso, 
      cl_cliente_grupo, 
      cob_credito..cr_tramite_grupal
      where io_id_inst_proc = @i_nro_proceso
      and io_campo_1 = cg_grupo
      and io_campo_3 = tg_tramite
      and tg_participa_ciclo = 'S'
      and tg_cliente = cg_ente

      open cursor_cliente
      fetch next from cursor_cliente into @w_codigo_cliente
      while @@fetch_status = 0
      begin
         insert into #tmp_listas_grilla
         select top 1
             ne_id_verificacion,   en_ente,    en_nomlar, 
             en_tipo_ced,          en_ced_ruc, ne_coincidencia, 
             ne_estado_resolucion
         from cl_listas_negras_rfe, cl_ente
         where ne_codigo_cliente = @w_codigo_cliente
         and ne_codigo_cliente = en_ente
         and (ne_estado_resolucion = 'S' or ne_estado_resolucion is null)
		 and ne_nro_proceso = @i_nro_proceso
         order by ne_fecha_resolucion desc
         
         fetch next from cursor_cliente into @w_codigo_cliente
      end

      close cursor_cliente
      deallocate cursor_cliente
   end
   select tmp_id_verificacion, tmp_ente,    tmp_nomlar,
             tmp_tipo_ced,        tmp_ced_ruc, tmp_coincidencia,
             tmp_estado_resolucion 
   from #tmp_listas_grilla
end

if @i_operacion = 'M' --Descripcion de mes
begin
   if isnull(@i_cat_valor, '') = ''
   begin
      select @w_valor_campo  = '@i_cat_valor'
      goto VALIDAR_ERROR
   end

   select td_descripcion
   from cob_cartera..ca_tdividendo
   where td_tdividendo = @i_cat_valor 
   and td_estado = 'V'

end

if @i_operacion = 'X' --Retornar monto aprobado y solicitado
begin
   if isnull(@i_nro_proceso, '') = ''
   begin
      select @w_valor_campo  = '@i_nro_proceso'
      goto VALIDAR_ERROR
   end

   select sum(tg_monto_aprobado),sum(tg_monto)
   from cob_credito..cr_tramite_grupal, 
   cob_workflow..wf_inst_proceso
   where io_id_inst_proc = @i_nro_proceso
   and io_campo_3        = tg_tramite

end

return 0

VALIDAR_ERROR:
   select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo , @w_error, @s_culture)
   goto ERROR_FIN

ERROR_FIN:

   while @@trancount > 0 rollback

   exec cobis..sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_msg      = @w_sp_msg,
            @i_num      = @w_error
            
   return @w_error

go
