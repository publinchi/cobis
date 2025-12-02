/************************************************************************/
/*   Archivo:             desercion_clientes.sp                         */
/*   Stored procedure:    desercion_clientes                            */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Credito                                       */
/*   Disenado por:        Bruno Duenas                                  */
/*   Fecha de escritura:  13-Abril-2023                                 */
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
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                     PROPOSITO                                        */
/*   Se realizan operacion relacionadas a clientes que han desertado    */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 13/Abril/2023            BDU                Emision Inicial          */
/* 21/Abril/2023            BDU               Se agrega acciones        */
/* 28/Abril/2023            BDU               Se corrige fecha desercion*/
/* 05/Mayo/2023             BDU               Se actualiza fecha        */
/************************************************************************/

use cob_credito
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
           from sysobjects 
           where name = 'desercion_clientes')
begin
   drop proc desercion_clientes
end   
go

create procedure desercion_clientes(
    @s_ssn                  int             = null,
    @s_sesn                 int             = null,
    @s_culture              varchar(10)     = null,
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
    @t_show_version         bit             = 0,
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  int             = null,
    @i_operacion            char(1)         = null,
    @i_fecha_ini            date            = null,
    @i_fecha_ven            date            = null,
    @i_oficina              catalogo        = null,
    @i_oficial              catalogo        = null,
    @i_ente                 int             = null,
    @i_fecha                datetime        = null,
    @i_causa                catalogo        = null,
    @i_severidad            catalogo        = null,
    @i_observacion          varchar(500)    = null,
    @i_id_registro          int             = null,
    @i_tipo                 char(1)         = null,
    @i_accion               varchar(500)    = null,
    @i_resultado            varchar(500)    = null,
    @i_id_accion            int             = null
)
as
declare @w_tiempo                   int,
        @w_sp_name                  varchar(32),
        @w_error                    int,
        @w_id                       int,
        @w_nombre_grupo             descripcion,
        @w_grupo                    int,
        @w_severidad                catalogo,
        @w_causa                    catalogo,
        @w_ciclo                    int,
        @w_id_max                   int,
        @w_id_diccionario           int,
        @w_id_accion                int,
        @w_ssn                      int

if @t_trn <> 21869
begin
    select @w_error = 1720075 -- TRANSACCION NO PERMITIDA
    goto ERROR
end

select @w_sp_name = 'cob_credito..desercion_clientes'
if @i_tipo = 'D'
begin
   if @i_operacion = 'S'
   begin
      --Campos nulos
      if @i_fecha_ini is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      if @i_fecha_ven is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      if @i_oficial is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      if @i_oficina is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      --Parametros
      select @w_tiempo = isnull(pa_smallint, 1)
      from cobis..cl_parametro
      where pa_nemonico = 'DBCRDE'
      and pa_producto   = 'CRE'
      --tabla temporal para almacenar las operaciones
      if (OBJECT_ID('tempdb.dbo.#tmp_operacion','U')) is not null
      begin
         drop table #tmp_operacion
      end
      
      create table #tmp_operacion (
         ente         int         null,
         nombre       descripcion null,
         grupo        int         null,
         nombre_grupo descripcion null,
         ciclo        int         null,
         calificacion catalogo    null,
         monto        money       null,
         fecha        date        null,
         operacion    cuenta      null,
         causa        catalogo    null,
         severidad    catalogo    null,
         oficial      int         null,
         oficina      int         null 
      )
      
      insert into #tmp_operacion(ente, operacion, nombre, calificacion, ciclo,
                                 monto, fecha, oficina,   oficial)
      SELECT en_ente, op_operacion, en_nomlar, en_calificacion, en_nro_ciclo,
             op_monto, dateadd(day, 1,op_fecha_fin), op_oficina, op_oficial
      from cobis.dbo.cl_ente en,
           cob_cartera.dbo.ca_operacion
      where op_cliente = en_ente
      and (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
      and op_estado not in (99,0,6)
      and (op_fecha_ini > @i_fecha_ven or op_fecha_fin <  @i_fecha_ini )
      and op_fecha_fin between dateadd(day, @w_tiempo * -1, @i_fecha_ini) and  @i_fecha_ini
      and op_operacion in (SELECT max(op_operacion) 
                           FROM cob_cartera.dbo.ca_operacion
                           where op_cliente = en.en_ente 
                           and (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
                           and op_estado not in (99,0,6)
                           and (op_fecha_ini > @i_fecha_ven or op_fecha_fin <  @i_fecha_ini )
                           and op_fecha_fin between dateadd(day, @w_tiempo * -1, @i_fecha_ini) and  @i_fecha_ini
                           and op_oficina = @i_oficina
                           and op_oficial = @i_oficial)
      and op_oficina = @i_oficina
      and op_oficial = @i_oficial
      order by en.en_ente desc
      
      select @w_id = min(ente) from #tmp_operacion
      --Ingreso de información extra 
      while @w_id is not null
      begin
         --Limpiar valores por cada cliente
         select @w_causa = null,
                @w_severidad = null,
                @w_grupo = null,
                @w_nombre_grupo = null
         --Info del grupo
         select @w_grupo = gr_grupo, 
                @w_nombre_grupo = gr_nombre 
                from cobis.dbo.cl_cliente_grupo,
                     cobis.dbo.cl_grupo
         where gr_grupo = cg_grupo 
         and cg_ente = @w_id
         
         --Info de desercion anterior (de existir)
         if exists(select 1 from cob_credito..cr_causa_desercion where cd_ente = @w_id)
         begin
            select @w_causa     = cd_causa,
                   @w_severidad = cd_severidad
            from cob_credito..cr_causa_desercion 
            where cd_ente = @w_id
            and cd_fecha = (select max(cd_fecha)
                            from cob_credito..cr_causa_desercion 
                            where cd_ente = @w_id)
         end
         
         
         update #tmp_operacion
         set grupo = @w_grupo,
             nombre_grupo = @w_nombre_grupo,
             severidad    = @w_severidad,
             causa        = @w_causa
         where ente = @w_id
         
         
         select @w_id = min(ente) from #tmp_operacion
         where ente > @w_id
      end
      
      
      select 'grupo'         = grupo,
             'nombre grupo'  = nombre_grupo,
             'ente'          = ente,
             'nombre'        = nombre,
             'calificacion'  = calificacion,
             'monto'         = monto,
             'ciclo'         = ciclo,
             'ult fecha des' = convert(varchar, fecha, 103),
             'causa'         = causa,
             'severidad'     = severidad
       from #tmp_operacion
       order by grupo desc, ente desc
      if @@rowcount = 0
      begin
         select @w_error = 1720250
         goto ERROR
      end
   end
end    

if @i_tipo = 'C'
begin
   if @i_operacion = 'S'
   begin
      if @i_fecha_ini is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      if @i_fecha_ven is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      if @i_ente is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      select 'id'            = cd_id,
             'fecha'         = convert(varchar, cd_fecha, 103),
             'causa'         = cd_causa,
             'observaciones' = cd_observacion,
             'severidad'     = cd_severidad,
             'Usu ingreso'   = cd_usuario_ingreso,
             'Usu mod'       = cd_usuario_modifica
       from cob_credito.dbo.cr_causa_desercion
       where cd_ente = @i_ente
       and cd_fecha between @i_fecha_ini and @i_fecha_ven
      if @@rowcount = 0
      begin
         select @w_error = 1720250
         goto ERROR
      end
   end
   
   if @i_operacion = 'I'
   begin
      if @i_fecha is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      if @i_ente is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      if @i_causa is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      if @i_severidad is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      if @i_observacion is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      select @w_id_max = isnull(max(cd_id), 0) + 1
      from cob_credito.dbo.cr_causa_desercion
      --Ingresar transaccion de servicio
      insert into cob_credito..ts_causa_desercion                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    id,                    ente,
         observacion,            causa,                 severidad,
         usuario_ingreso,        usuario_mod,           fecha_ingreso,
         fecha_modif)
      select                   
         @s_ssn,                  21869,                'N',
         @s_date,                 @s_user,              @s_term,
         @s_ofi,                  'cr_causa_desercion', @s_lsrv,
         @s_srv,                  @w_id_max,            @i_ente,
         @i_observacion,          @i_causa,             @i_severidad,
         @s_user,                 null,                 getdate(),
         null
        --ERROR EN CREACION DE TRANSACCION DE SERVICIO
       if @@error <> 0 begin
          select @w_error = 1720049
          goto ERROR
       end 
         
      insert into cob_credito.dbo.cr_causa_desercion(
                  cd_id,               cd_ente,            cd_fecha           
                 ,cd_observacion       ,cd_causa           ,cd_severidad       
                 ,cd_usuario_ingreso  ,cd_fecha_ingreso   ,cd_usuario_modifica
                 ,cd_fecha_modifica  
      )
      values(     @w_id_max,           @i_ente,            @i_fecha,
                  @i_observacion,      @i_causa,           @i_severidad,
                  @s_user,             getdate(),          null,
                  null
      )
      
      if @@error <> 0
      begin
         select @w_error = 603059
         goto ERROR
      end
      
   end
   
   if @i_operacion = 'U'
   begin
      if @i_id_registro is NULL
      begin
         select @w_error = 601001
         goto ERROR
      end
      insert into cob_credito..ts_causa_desercion                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    id,                    ente,
         observacion,            causa,                 severidad,
         usuario_ingreso,        usuario_mod,           fecha_ingreso,
         fecha_modif)
      select                   
         @s_ssn,                  21869,                'A',
         @s_date,                 @s_user,              @s_term,
         @s_ofi,                  'cr_causa_desercion', @s_lsrv,
         @s_srv,                  cd_id,                cd_ente,
         cd_observacion,          cd_causa,             cd_severidad,
         cd_usuario_ingreso,      cd_usuario_modifica,  cd_fecha_ingreso,
         cd_fecha_modifica
       from cob_credito.dbo.cr_causa_desercion
       where cd_id = @i_id_registro
        --ERROR EN CREACION DE TRANSACCION DE SERVICIO
       if @@error <> 0 begin
          select @w_error = 1720049
          goto ERROR
       end
       
       
      update cob_credito.dbo.cr_causa_desercion
      set cd_fecha            = isnull(@i_fecha, cd_fecha),    
          cd_observacion      = isnull(@i_observacion, cd_observacion), 
          cd_causa            = isnull(@i_causa, cd_causa),
          cd_severidad        = isnull(@i_severidad, cd_severidad),
          cd_usuario_modifica = @s_user,
          cd_fecha_modifica   = getdate()
      where cd_id = @i_id_registro
      if @@error <> 0 begin
          select @w_error = 708152
          goto ERROR
       end
      EXEC @w_ssn=ADMIN...rp_ssn
      insert into cob_credito..ts_causa_desercion                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    id,                    ente,
         observacion,            causa,                 severidad,
         usuario_ingreso,        usuario_mod,           fecha_ingreso,
         fecha_modif)
      select                   
         @w_ssn,                  21869,                'D',
         @s_date,                 @s_user,              @s_term,
         @s_ofi,                  'cr_causa_desercion', @s_lsrv,
         @s_srv,                  cd_id,                cd_ente,
         cd_observacion,          cd_causa,             cd_severidad,
         cd_usuario_ingreso,      cd_usuario_modifica,  cd_fecha_ingreso,
         cd_fecha_modifica
       from cob_credito.dbo.cr_causa_desercion
       where cd_id = @i_id_registro
        --ERROR EN CREACION DE TRANSACCION DE SERVICIO
       if @@error <> 0 begin
          select @w_error = 1720049
          goto ERROR
       end    
      if @@error <> 0
      begin
         select @w_error = 601162
         goto ERROR
      end
   end
   
   if @i_operacion = 'C' --Obetener criticidad de la causa
   begin
      select @w_id_diccionario = dfg_functionality_id 
      from cob_fpm.dbo.fp_dicfunctionalitygroup 
      where dcp_name_idfk = 'Causa Criticidad'
      if @@rowcount = 0
      begin
         select @w_error = 6900010 --No esta parametrizado el diccionario
         goto ERROR
      end
      
      select 'Valor' = uf_value  
      from cob_fpm.dbo.fp_unitfunctionalityvalues 
      where bp_product_id_fk ='LCRE' 
      and dc_fields_id_fk = (select dc_fields_id
                             from cob_fpm.dbo.fp_dictionaryfields fd 
                             where dc_name = 'Criticidad'
                             and dfg_functionality_idfk = @w_id_diccionario)
      and registryid = (
      select registryid  
      from cob_fpm.dbo.fp_unitfunctionalityvalues 
      where bp_product_id_fk ='LCRE'
      and dc_fields_id_fk = (select dc_fields_id
                             from cob_fpm.dbo.fp_dictionaryfields fd 
                             where dc_name = 'Causa'
                             and dfg_functionality_idfk = @w_id_diccionario)
      and uf_delete = 'N'
      and uf_value = @i_causa)
   end
end

if @i_tipo = 'A'
begin
   if @i_operacion = 'S'
   begin
      if @i_id_registro is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      select 'id'        = ad_id,
             'fecha'     = convert(varchar, ad_fecha, 103),
             'accion'    = ad_accion,
             'resultado' = ad_resultado,
             'usu ingre' = ad_usuario_ingreso,
             'usu modif' = ad_usuario_modif
      from cob_credito.dbo.cr_accion_desercion
      where ad_id_historial = @i_id_registro
      if @@rowcount = 0
      begin
         select @w_error = 1720250
         goto ERROR
      end
   end
   
   if @i_operacion = 'I'
   begin
      if @i_id_registro is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      if @i_accion is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      if @i_resultado is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      select @w_id_accion = isnull(max(ad_id), 0) + 1
      from cob_credito.dbo.cr_accion_desercion
      
      insert into cob_credito.dbo.cr_accion_desercion(
         ad_id, ad_id_historial, ad_fecha,
         ad_accion, ad_resultado, ad_usuario_ingreso
      )values(
         @w_id_accion, @i_id_registro, @i_fecha,
         @i_accion, @i_resultado, @s_user
      )
      if @@error <> 0
      begin
         select @w_error = 603059
         goto ERROR
      end
      insert into cob_credito..ts_accion_desercion                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    id,                    id_historico,
         accion,                 resultado,             usuario_ingreso,        
         usuario_mod,            fecha_ingreso,         fecha_modif)
      select                   
         @s_ssn,                  21869,                'N',
         @s_date,                 @s_user,              @s_term,
         @s_ofi,                  'cr_accion_desercion', @s_lsrv,
         @s_srv,                  ad_id,                ad_id_historial,
         ad_accion,               ad_resultado,         ad_usuario_ingreso,      
         ad_usuario_modif,        ad_fecha,             ad_fecha_modif
       from cob_credito.dbo.cr_accion_desercion
       where ad_id = @w_id_accion
        --ERROR EN CREACION DE TRANSACCION DE SERVICIO
       if @@error <> 0 begin
          select @w_error = 1720049
          goto ERROR
       end
       
   end
   
   if @i_operacion = 'U'
   begin
      if @i_id_accion is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      insert into cob_credito..ts_accion_desercion                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    id,                    id_historico,
         accion,                 resultado,             usuario_ingreso,        
         usuario_mod,            fecha_ingreso,         fecha_modif)
      select                   
         @s_ssn,                  21869,                'A',
         @s_date,                 @s_user,              @s_term,
         @s_ofi,                  'cr_accion_desercion', @s_lsrv,
         @s_srv,                  ad_id,                ad_id_historial,
         ad_accion,               ad_resultado,         ad_usuario_ingreso,      
         ad_usuario_modif,        ad_fecha,             ad_fecha_modif
       from cob_credito.dbo.cr_accion_desercion
       where ad_id = @i_id_accion
        --ERROR EN CREACION DE TRANSACCION DE SERVICIO
       if @@error <> 0 begin
          select @w_error = 1720049
          goto ERROR
       end
      update cob_credito.dbo.cr_accion_desercion
      set ad_accion        = isnull(@i_accion, ad_accion),
          ad_resultado     = isnull(@i_resultado, ad_resultado),
          ad_fecha         = @i_fecha,
          ad_fecha_modif   = getdate(),
          ad_usuario_modif = @s_user
      where ad_id = @i_id_accion
      if @@error <> 0
      begin
         select @w_error = 601162
         goto ERROR
      end
      
      insert into cob_credito..ts_accion_desercion                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    id,                    id_historico,
         accion,                 resultado,             usuario_ingreso,        
         usuario_mod,            fecha_ingreso,         fecha_modif)
      select                   
         @s_ssn,                  21869,                'D',
         @s_date,                 @s_user,              @s_term,
         @s_ofi,                  'cr_accion_desercion', @s_lsrv,
         @s_srv,                  ad_id,                ad_id_historial,
         ad_accion,               ad_resultado,         ad_usuario_ingreso,      
         ad_usuario_modif,        ad_fecha,             ad_fecha_modif
       from cob_credito.dbo.cr_accion_desercion
       where ad_id = @i_id_accion
        --ERROR EN CREACION DE TRANSACCION DE SERVICIO
       if @@error <> 0 begin
          select @w_error = 1720049
          goto ERROR
       end
      
   end
   
   if @i_operacion = 'D'
   begin
      if @i_id_accion is null
      begin
         select @w_error = 601001
         goto ERROR
      end
      
      insert into cob_credito..ts_accion_desercion                   
        (secuencial,             tipo_transaccion,      clase, 
         fecha,                  usuario,               terminal,           
         oficina,                tabla,                 lsrv, 
         srv,                    id,                    id_historico,
         accion,                 resultado,             usuario_ingreso,        
         usuario_mod,            fecha_ingreso,         fecha_modif)
      select                   
         @s_ssn,                  21869,                'E',
         @s_date,                 @s_user,              @s_term,
         @s_ofi,                  'cr_accion_desercion', @s_lsrv,
         @s_srv,                  ad_id,                ad_id_historial,
         ad_accion,               ad_resultado,         ad_usuario_ingreso,      
         ad_usuario_modif,        ad_fecha,             ad_fecha_modif
       from cob_credito.dbo.cr_accion_desercion
       where ad_id = @i_id_accion
        --ERROR EN CREACION DE TRANSACCION DE SERVICIO
       if @@error <> 0 begin
          select @w_error = 1720049
          goto ERROR
       end
      
      delete from cob_credito.dbo.cr_accion_desercion
      where ad_id = @i_id_accion
      if @@error <> 0
      begin
         select @w_error = 601164
         goto ERROR
      end
   end
end

return 0

ERROR:
   exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = @w_sp_name,
     @i_num   = @w_error
    return @w_error
    
go
