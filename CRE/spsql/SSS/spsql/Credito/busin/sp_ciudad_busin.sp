use cob_pac
go

if exists (select 1 from sysobjects where name = 'sp_ciudad_busin')
   drop procedure dbo.sp_ciudad_busin
go

create proc sp_ciudad_busin (
       @s_ssn                int           = null,
       @s_user               login         = null,
       @s_sesn               int           = null,
       @s_term               varchar(32)   = null,
       @s_date               datetime      = null,
       @s_srv                varchar(30)   = null,
       @s_lsrv               varchar(30)   = null,
       @s_rol                smallint      = null,
       @s_ofi                smallint      = null,
       @s_org_err            char(1)       = null,
       @s_error              int           = null,
       @s_sev                tinyint       = null,
       @s_msg                descripcion   = null,
       @s_org                char(1)       = null,
       @t_debug              char(1)       = 'N',
       @t_file               varchar(14)   = null,
       @t_from               varchar(32)   = null,
       @t_trn                smallint      = null,
       @t_show_version       bit           = 0,
       @i_operacion          varchar(2),
       @i_tipo               varchar(1)    = null,
       @i_modo               tinyint       = null,
       @i_ciudad             int           = null,
       @i_valorcat           catalogo      = null,
       @i_descripcion        descripcion   = null,
       @i_provincia          int           = null, --Cambio de smallint a int
       @i_pais               smallint      = null,
       @i_estado             estado        = null,
       @i_cod_bce            smallint      = null,
       @i_valor              descripcion   = null,
       @i_ciudad_alf         varchar(64)   = null,
       @i_canton             int           = null,
       @i_rowcount           tinyint       = 20
)
as

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF

declare @w_today              datetime,
        @w_sp_name            varchar(32),
        @w_codigo             int,
        @w_descripcion        descripcion,
        @w_provincia          int,
        @w_canton             int,                 --Cambio de smallint a int
        @w_estado             estado,
        @v_descripcion        descripcion,
        @v_provincia          int, --Cambio de smallint a int
        @v_canton             int,
        @v_estado             estado,
        @v_cod_bce            smallint,
        @w_cod_bce            smallint,
        @w_return             int,
        @w_codigo_c           varchar(10),
        @w_cod_pais           smallint,
        @w_ciudad             int,
        @w_longitud           int,
        @w_caracter           char(1),
        @w_pos                smallint,
        @w_valida             tinyint,
        @w_numerror           int,
        @w_ciudad_nacional    int,
        @w_msg                varchar(64),
        @w_pais               smallint

select @w_today    = @s_date
select @w_sp_name  = 'sp_ciudad_busin'
select @w_longitud = datalength(@i_valorcat),
       @w_pos = 1

if @t_show_version = 1
begin
   print 'Stored procedure, Version 4.0.0.1' + @w_sp_name
   return 0
end

-- Valida codigo de transaccion
if  (@t_trn != 588  or @i_operacion != 'I')
and (@t_trn != 589  or @i_operacion != 'U')
and (@t_trn != 1560  or @i_operacion != 'Q')
and (@t_trn != 1562  or @i_operacion != 'H')
and (@t_trn != 1561  or @i_operacion != 'S')
begin
   select @w_return  = 151051,
          @w_msg     = 'ERROR: CODIGO DE TRANSACCION NO CORRESPONDE'
   goto ERROR
end

select @w_ciudad_nacional = pa_smallint
from   cobis..cl_parametro
where  pa_nemonico = 'CFN'

if @i_valorcat is not null
begin
   while @w_longitud > @w_pos
   begin
      select @w_caracter = substring(@i_valorcat,@w_pos,1)
      if @w_caracter in ('0','1','2','3','4','5','6','7','8','9')
         select @w_valida = 1
      else
      begin
         select @w_valida = 0
         break
      end
      select @w_pos = @w_pos + 1
   end

   if @w_valida = 1
      select @w_ciudad = convert(int, @i_valorcat)
   else
   begin
      select @w_return  = 2110287,
             @w_msg     = 'ERROR: LA BUSQUEDA DEBE REALIZARSE POR EL CODIGO DEL DESTINO GEOGRAFICO'
      goto ERROR
   end
end

-- INSERT
if @i_operacion = 'I'
begin
   --Verifica Claves foraneas
   --Provincia
   select @w_codigo = null
   from   cobis..cl_provincia
   where  pv_provincia = @i_provincia

   if @@rowcount = 0
   begin
      select @w_return  = 2110149,
             @w_msg     = 'ERROR: NO EXISTE PROVINCIA'
      goto ERROR
   end

   -- CANTON
   select @w_codigo = null
   from   cobis..cl_canton
   where  ca_canton = @i_canton

   if @@rowcount = 0
   begin
      select @w_return  = 2110288,
             @w_msg     = 'ERROR: NO EXISTE CATON'
      goto ERROR
   end

   --VALIDACION DE DUPLICIDAD DE CIUDAD
   if exists (select ci_ciudad from cobis..cl_ciudad
              where  ci_ciudad  = @i_ciudad)
   begin
      select @w_return  = 2110150,
             @w_msg     = 'ERROR: NO EXISTE CIUDAD'
      goto ERROR
   end

   if @i_ciudad = @w_ciudad_nacional
   begin
      select @w_return  = 2110289,
             @w_msg     = 'ERROR: NO PUEDE CREAR CODIGO DE CIUDAD ES PARAMETRO GENERAL'
      goto ERROR
   end

   begin tran
      insert into cobis..cl_ciudad
             (ci_ciudad, ci_descripcion, ci_estado, ci_provincia,
              ci_pais,   ci_cod_remesas, ci_canton)
      values (@i_ciudad, @i_descripcion, 'V',       @i_provincia,
              @i_pais,   @i_cod_bce,     @i_canton)

      if @@error != 0
      begin
         select @w_return  = 2110290,
                @w_msg     = 'ERROR: EN CREACION DE CIUDAD'
         goto ERROR
      end

      --Transaccion de servicio - CIUDAD
      insert into cobis..ts_ciudad
             (secuencia, tipo_transaccion, clase,          fecha,
              oficina_s, usuario,          terminal_s,     srv,
              lsrv,      ciudad,           descripcion,    provincia,
              pais,      estado,           canton)
      values (@s_ssn,    588,              'N',            @s_date,
              @s_ofi,    @s_user,          @s_term,        @s_srv,
              @s_lsrv,   @i_ciudad,        @i_descripcion, @i_provincia,
              @i_pais,   'V',              @i_canton)

      if @@error != 0
      begin
         select @w_return  = 2110291,
                @w_msg     = 'ERROR: EN TRANSACCION DE SERVICIO'
         goto ERROR
      end
   commit tran

   --ACTUALIZACION DE LA LOS DATOS EN EL CATALOGO
   select @w_codigo_c = convert(varchar(10), @i_ciudad)
   exec @w_return = cobis..sp_catalogo
        @s_ssn             = @s_ssn,
        @s_user            = @s_user,
        @s_sesn            = @s_sesn,
        @s_term            = @s_term,
        @s_date            = @s_date,
        @s_srv             = @s_srv,
        @s_lsrv            = @s_lsrv,
        @s_rol             = @s_rol,
        @s_ofi             = @s_ofi,
        @s_org_err         = @s_org_err,
        @s_error           = @s_error,
        @s_sev             = @s_sev,
        @s_msg             = @s_msg,
        @s_org             = @s_org,
        @t_debug           = @t_debug,
        @t_file            = @t_file,
        @t_from            = @w_sp_name,
        @t_trn             = 584,
        @i_operacion       = 'I',
        @i_tabla           = 'cl_ciudad',
        @i_codigo          = @w_codigo_c,
        @i_descripcion     = @i_descripcion,
        @i_estado          = 'V'

   if @w_return != 0
   begin
      select @w_msg     = 'ERROR: EN TRANSACCION DE SERVICIO'
      goto ERROR
   end
end

--UPDATE
if @i_operacion = 'U'
begin
   --VERIFICACION DE CLAVES FORANEAS
   --PROVINCIA
   select @w_codigo = null
   from   cobis..cl_provincia
   where  pv_provincia = @i_provincia

   if @@rowcount = 0
   begin
      select @w_return  = 2110149,
             @w_msg     = 'ERROR: NO EXISTE PROVINCIA'
      goto ERROR
   end

   --CANTON
   select @w_codigo = null
   from   cobis..cl_canton
   where  ca_canton = @i_canton

   if @@rowcount = 0
   begin
      select @w_return  = 2110288,
             @w_msg     = 'ERROR: NO EXISTE CATON'
      goto ERROR
   end

   select @w_descripcion = ci_descripcion,
          @w_provincia   = ci_provincia,
          @w_estado      = ci_estado,
          @w_cod_bce     = ci_cod_remesas,
          @w_canton      = ci_canton
   from   cobis..cl_ciudad
   where  ci_ciudad = @i_ciudad

   select @v_descripcion = @w_descripcion
   select @v_provincia   = @w_provincia
   select @v_estado      = @w_estado
   select @v_cod_bce     = @w_cod_bce
   select @v_canton      = @w_canton

   if @w_descripcion = @i_descripcion
      select @w_descripcion = null, @v_descripcion = null
   else
      select @w_descripcion = @i_descripcion

   if @w_provincia = @i_provincia
      select @w_provincia = null, @v_provincia = null
   else
      select @w_provincia = @i_provincia

   if @w_cod_bce = @i_cod_bce
      select @w_cod_bce = null, @v_cod_bce = null
   else
      select @w_cod_bce = @i_cod_bce

   if @w_canton = @i_canton
      select @w_canton = null, @v_canton = null
   else
      select @w_canton = @i_canton

   if @w_estado = @i_estado
      select @w_estado = null, @v_estado = null
   else
   begin
      if @i_estado = 'C'
      begin
         if exists (select 1
                    from  cobis..cl_parroquia
                    where pq_ciudad = @i_ciudad
                    and   pq_estado = 'V')
         begin
            select @w_return  = 2110292,
                   @w_msg     = 'ERROR: EXISTE PARROQUIA VIGENTE'
            goto ERROR
         end
      end

      if @i_estado = 'V'
      begin
         if exists (select 1
                    from   cobis..cl_provincia
                    where  pv_provincia = @i_provincia
                    and    pv_estado    = 'C')
         begin
            select @w_return  = 2110293,
                   @w_msg     = 'ERROR: NO PROVINCIA VIGENTE'
            goto ERROR
         end
      end
      select @w_estado = @i_estado --Inc65758
   end

   begin tran
      update cobis..cl_ciudad
      set    ci_descripcion  = @i_descripcion,
             ci_provincia    = @i_provincia,
             ci_estado       = @i_estado,
             ci_cod_remesas  = @i_cod_bce,
             ci_canton       = @i_canton
      where  ci_ciudad = @i_ciudad

      if @@error != 0
      begin
         select @w_return  = 2110294,
                @w_msg     = 'ERROR: EN ACTUALIZACION DE CIUDAD'
         goto ERROR
      end

      --TRANSACCION SERVICIOS - CIUDAD
      insert into cobis..ts_ciudad
             (secuencia, tipo_transaccion, clase,          fecha,
              oficina_s, usuario,          terminal_s,     srv,
              lsrv,      ciudad,           descripcion,    provincia,
              estado,    canton)
      values (@s_ssn,    589,              'P',            @s_date,
              @s_ofi,    @s_user,          @s_term,        @s_srv,
              @s_lsrv,   @i_ciudad,        @v_descripcion, @v_provincia,
              @v_estado, @v_canton)

      if @@error != 0
      begin
         select @w_return  = 2110291,
                @w_msg     = 'ERROR: EN CREACION DE TRANSACCION DE SERVICIOS'
         goto ERROR
      end

      insert into cobis..ts_ciudad
             (secuencia, tipo_transaccion, clase,          fecha,
              oficina_s, usuario,          terminal_s,     srv,
              lsrv,      ciudad,           descripcion,    provincia,
              estado,    canton)
      values (@s_ssn,    589,              'A',            @s_date,
              @s_ofi,    @s_user,          @s_term,        @s_srv,
              @s_lsrv,   @i_ciudad,        @w_descripcion, @w_provincia,
              @w_estado, @w_canton)

      if @@error != 0
      begin
         select @w_return  = 2110291,
                @w_msg     = 'ERROR: EN CREACION DE TRANSACCION DE SERVICIOS'
         goto ERROR
      end
   commit tran

   --ACTUALIZACION DE LA LOS DATOS EN EL CATALOGO
   select @w_codigo_c = convert(varchar(10), @i_ciudad)
   exec @w_return = cobis..sp_catalogo
        @s_ssn             = @s_ssn,
        @s_user            = @s_user,
        @s_sesn            = @s_sesn,
        @s_term            = @s_term,
        @s_date            = @s_date,
        @s_srv             = @s_srv,
        @s_lsrv            = @s_lsrv,
        @s_rol             = @s_rol,
        @s_ofi             = @s_ofi,
        @s_org_err         = @s_org_err,
        @s_error           = @s_error,
        @s_sev             = @s_sev,
        @s_msg             = @s_msg,
        @s_org             = @s_org,
        @t_debug           = @t_debug,
        @t_file            = @t_file,
        @t_from            = @w_sp_name,
        @t_trn             = 585,
        @i_operacion       = 'U',
        @i_tabla           = 'cl_ciudad',
        @i_codigo          = @w_codigo_c,
        @i_descripcion     = @i_descripcion,
        @i_estado          = @i_estado

   if @w_return != 0
      return @w_return

end

--SEARCH
if @i_operacion = 'S'
begin
   set rowcount 20
   select 'Codigo'         = ci_ciudad,
          'Distrito'       = substring(ci_descripcion,1, 40),
          'Cod. Provincia' = ci_provincia,
          'Provincia'      = substring(pv_descripcion,1, 20),
          'Cod. Pais'      = pv_pais,
          'Pais'           = substring(pa_descripcion,1, 20),
          'Cod. Canton'    = ci_canton,
          'Canton'         = substring(ca_descripcion,1, 20),
          'Cod.Remesas'    = ci_cod_remesas,
          'Estado'         = ci_estado
   from   cobis..cl_ciudad, cobis..cl_provincia, cobis..cl_pais, cobis..cl_canton
   where  pv_provincia            =    ci_provincia
   and    pa_pais                 =    pv_pais
   and    ci_canton               =    ca_canton
   and    ((ci_ciudad             =    @i_ciudad           or @i_ciudad is null) and @i_modo = 0) or (ci_ciudad > @i_ciudad and @i_modo = 1)
   and    (Upper(ci_descripcion)  like @i_descripcion +'%' or @i_descripcion is null)
   order  by ci_ciudad

   if @@rowcount = 0
   begin
      select @w_return  = 101000,
             @w_msg     = 'ERROR: NO EXISTE DATO EN CATALOGO'
      goto ERROR
   end
   set rowcount 0
end

-- Query
if @i_operacion = 'Q'
begin
   set rowcount 20
   select 'Codigo'          = ci_ciudad,
          'Distrito'        = ci_descripcion,
          'Cod. Provincia'  = ci_provincia,
          'Provincia'       = pv_descripcion,
          'Cod. Canton'     = ci_canton,
          'Canton'          = substring(ca_descripcion,1, 20),
          'Cod.Remesas'     = ci_cod_remesas
   from   cobis..cl_ciudad,
          cobis..cl_provincia,
          cobis..cl_canton
   where  pv_provincia = ci_provincia
   and    ci_canton    = ca_canton
   and    ci_estado    = 'V'
   and    ((ci_ciudad  > @i_ciudad and  @i_modo = 1) or @i_modo = 0)
   order  by ci_ciudad

   set rowcount 0
end

--------
-- HELP
--------
if @i_operacion = 'H'
begin
   if @i_tipo = 'A'
   begin
      set rowcount 20
      if @i_modo = 0
         select 'Cod.'   = ci_ciudad,
                'Nombre' = ci_descripcion,
                'Pais'   = pa_descripcion
         from   cobis..cl_ciudad,
                cobis..cl_provincia,
                cobis..cl_pais
         where ci_provincia           = pv_provincia
         and   pv_pais                = pa_pais
         and   ci_estado              = 'V'
         and   (ci_ciudad             = @i_ciudad              or @i_ciudad      is null)
         and   (Upper(ci_descripcion) like @i_descripcion +'%' or @i_descripcion is null)
         order by ci_ciudad asc
      else
         if @i_modo = 1
            select 'Cod.'  = ci_ciudad,
                   'Nombre'= ci_descripcion,
                   'Pais'  = pa_descripcion
            from   cobis..cl_ciudad,
                   cobis..cl_provincia,
                   cobis..cl_pais
            where  ci_provincia            = pv_provincia
            and    pv_pais                 = pa_pais
            and    ci_estado               = 'V'
            and    (ci_ciudad              > @i_ciudad              or @i_ciudad      is null)
            and    (ci_ciudad              = @w_ciudad              or @w_ciudad      is null)
            and    (Upper(ci_descripcion)  like @i_descripcion +'%' or @i_descripcion is null)
            order by ci_ciudad asc

      set rowcount 0
   end -- @i_tipo = 'A'
   else
   begin
      if @i_tipo = 'V'
      begin
         select ci_descripcion
         from   cobis..cl_ciudad c
         where  (ci_provincia = @i_provincia or @i_provincia is null)
         and    ci_ciudad     = @i_ciudad
         and    ci_estado     = 'V'

         if @@rowcount = 0
         begin
            select @w_return  = 101000,
                   @w_msg     = 'ERROR: NO EXISTE DATO EN CATALOGO'
            goto ERROR
         end
      end
      else if @i_tipo = 'B'
      begin
            set rowcount 20
            select 'Cod.Canton'     = ci_canton,
                   'Nombre Canton'  = ca_descripcion,
                   'Cod. Provincia' = pv_provincia,
                   'Nombre Prov.'   = pv_descripcion,
                   'Cod. Pais'      = pa_pais,
                   'Nombre Pais'    = pa_descripcion
            from   cobis..cl_ciudad, cobis..cl_provincia, cobis..cl_pais, cobis..cl_canton
            where  ci_provincia      = pv_provincia
            and    pv_pais           = pa_pais
            and    ci_canton         = ca_canton
            and    (ci_provincia     = @i_provincia or @i_provincia is null)
            and    ci_estado         = 'V'
            and    ci_descripcion like isnull(@i_valor,ci_descripcion)
            and    ((ci_descripcion  > @i_ciudad_alf and  @i_modo = 1) or @i_modo = 0)
            order by ci_descripcion

            set rowcount 0
      end -- @i_tipo = 'B'
      else if @i_tipo = 'S'
      begin
         set rowcount @i_rowcount
         select 'Cod.'   = ci_ciudad,
                'Nombre' = ci_descripcion,
                'Pais'   = pa_descripcion
         from   cobis..cl_ciudad, cobis..cl_provincia, cobis..cl_pais
         where  ci_provincia               = pv_provincia
         and    pv_pais                    = pa_pais
         and    pv_provincia               = @i_provincia
         and    ((ci_ciudad                > @i_ciudad          and @i_modo = 1)   or ((ci_ciudad = @i_ciudad or @i_ciudad is null) and @i_modo = 0))
         and    (Upper(ci_descripcion)  like @i_descripcion +'%' or @i_descripcion is null)
         and    ci_estado                  = 'V'

         set rowcount 0
      end -- @i_tipo = 'S'
      else if @i_tipo = 'E'
      begin
         select ci_descripcion
         from   cobis..cl_ciudad
         where  ci_ciudad    = @i_ciudad
         and    ci_provincia = @i_provincia
         and    ci_estado    = 'V'

         if @@rowcount = 0
         begin
            select @w_return  = 2110171,
                   @w_msg     = 'ERROR: CIUDAD NO PERTENECE A LA PROVINCIA'
            goto ERROR
         end
      end -- @i_tipo = 'E'
      else if @i_tipo = 'N'
      begin
         --VALIDACION DE PARAMETRO GENERAL DEL PAIS
         --ADU: 20051214
         select @w_cod_pais = pa_smallint
         from cobis..cl_parametro
         where pa_nemonico='CP' and pa_producto='ADM'

         if (@w_cod_pais is null)
         begin
            select @w_return  = 2110295,
                   @w_msg     = 'ERROR: NO EXISTE PARAMETRO DE CODIGO DE PAIS (CP)'
            goto ERROR
         end

         set rowcount 20
         select 'Cod.'   = ci_ciudad,
                'Nombre' = ci_descripcion,
                'Pais'   = pa_descripcion
         from cobis..cl_ciudad,
              cobis..cl_provincia,
              cobis..cl_pais
         where ci_provincia = pv_provincia
         and   pv_pais      = pa_pais
         and   ci_estado    = 'V'
         and   pa_pais      = @w_cod_pais
         and   ((ci_ciudad  > @i_ciudad   and @i_modo = 1) or @i_modo = 0)
         order by ci_ciudad
         set rowcount 0
      end -- @i_tipo = 'N'
      else if @i_tipo = 'W'
      begin
         --VALIDACION DE PARAMETRO GENERAL DEL PAIS
         select @w_cod_pais = pa_smallint
         from   cobis..cl_parametro
         where  pa_nemonico='CP' and pa_producto='ADM'

         if (@w_cod_pais is null)
         begin
            select @w_return  = 2110295,
                   @w_msg     = 'ERROR: NO EXISTE PARAMETRO DE CODIGO DE PAIS (CP)'
            goto ERROR
         end

         select ci_descripcion
         from   cobis..cl_ciudad
         where  ci_ciudad = @i_ciudad
         and    ci_estado = 'V'
         and    ci_pais   = @w_cod_pais

         if @@rowcount = 0
         begin
            select @w_return  = 101000,
                   @w_msg     = 'ERROR: NO EXISTE DATO EN CATALOGO'
            goto ERROR
         end
      end -- @i_tipo = 'W'
      else if @i_tipo = 'R'  --NUEVA VALIDACION DE F5 GENERAL DEL CANTON
      begin
         set rowcount 20

         select 'Cod.Canton'     = ci_canton,
                'Nombre Canton'  = ca_descripcion,
                'Cod. Provincia' = pv_provincia,
                'Nombre Prov.'   = pv_descripcion,
                'Cod. Pais'      = pa_pais,
                'Nombre Pais'    = pa_descripcion
         from   cobis..cl_ciudad,
                cobis..cl_provincia,
                cobis..cl_pais,
                cobis..cl_canton
         where  ci_provincia    = @i_provincia
         and    pv_provincia    = ci_provincia
         and    pa_pais         = ci_pais
         and    ci_canton       = ca_canton
         and    ci_estado       = 'V'
         and    ((ci_ciudad        > @i_ciudad and @i_modo = 1) or @i_modo = 0)
         order by ci_ciudad

         if @@rowcount = 0
         begin
            select @w_return  = 151121,
                   @w_msg     = 'ERROR: NO EXISTE DATO SOLICITADO'
            goto ERROR
         end
         set rowcount 0
      end         --FIN VALIDACION DE F5 GENERAL DEL CANTON
      else if @i_tipo = 'Q' /*Busqueda de ciudades por descripcion*/
      begin
         /*Controla mensajes de error*/
         if @i_ciudad_alf is null
            select @w_numerror = 101000
         else
            select @w_numerror = 151121

         set rowcount 20
         select 'Cod. Ciudad'       = ci_ciudad,
                'Nombre Ciudad'     = ci_descripcion,
                'Cod. Provincia'    = pv_provincia,
                'Nombre Prov.'      = pv_descripcion,
                'Cod. Pais'         = pa_pais,
                'Nombre Pais'       = pa_descripcion
         from   cobis..cl_ciudad,
                cobis..cl_provincia,
                cobis..cl_pais
         where  ci_provincia = pv_provincia
         and    pv_pais      = pa_pais
         and    pv_pais      = @i_pais
         and    (pv_provincia = @i_provincia or  @i_provincia is null or @i_provincia=0 )
         and    ci_estado    = 'V'
         and    (ci_descripcion like @i_valor or @i_valor is null)
         and    (ci_ciudad > convert(int,@i_ciudad_alf) or @i_ciudad_alf is null)
         order by ci_ciudad

         if @@rowcount = 0
         begin
            select @w_return  = @w_numerror,
                   @w_msg     = 'ERROR: NO EXISTE DATO EN CATALOGO'
            goto ERROR
         end
         set rowcount 0
      end -- @i_tipo = 'Q'
      else if @i_tipo = 'O' --Originador
      begin
         if @i_modo = 0
         begin
            set rowcount @i_rowcount
            set @w_pais = @i_pais

            if @w_pais is null
            begin
               select @w_pais = pa_smallint from cobis..cl_parametro where pa_nemonico = 'CP' and pa_producto = 'ADM'
            end

            select 'CODIGO'  = ci_ciudad,
                   'DETALLE' = ci_descripcion
            from   cobis..cl_ciudad
            where  ci_pais   = @w_pais
            and    ci_provincia = @i_provincia
            and    ci_estado    = 'V'

            set rowcount 0
         end
      end --@i_tipo = 'O'

   end
end --@i_operacion = 'H'
return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_return
   return @w_return

go
