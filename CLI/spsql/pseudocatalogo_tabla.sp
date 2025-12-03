/*********************************************************************************/
/*  Archivo:                pseudocatalogo_tabla.sp                              */
/*  Stored procedure:       sp_pseudocatalogo_tabla                              */
/*  Base de datos:          cobis                                                */
/*  Producto:               Clientes                                             */
/*  Disenado por:           Diego Flores                                         */
/*  Fecha de escritura:     04-07-2019                                           */
/*********************************************************************************/
/*                                  IMPORTANTE                                   */
/*  Este programa es parte de los paquetes bancarios propiedad de "COBISCORP".   */
/*  Su uso no autorizado queda expresamente prohibido asi cualquier alteracion o */ 
/*  agregado hecho por alguno de sus usuarios sin el debido consentimiento por   */
/*  escrito de la Presidencia Ejecutiva de COBISCORP o su representante.         */
/*                                       PROPOSITO                               */
/*  Este programa envía una string como resultado.                               */
/*********************************************************************************/
/*                        MODIFICACIONES                                         */
/*  FECHA       AUTOR           RAZON                                            */
/*  20-01-2021  GCO             Estandarizacion de clientes                      */
/*  19-05-2023  BDU             Ajustes QUERY oficiales app                      */
/*  14-08-2023  PJA             B880052-R212958                                  */
/*********************************************************************************/


use cobis
GO
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
if exists (select * from sysobjects where name = 'sp_pseudocatalogo_tabla')
   drop proc sp_pseudocatalogo_tabla
go

create proc sp_pseudocatalogo_tabla (
   @s_ssn                int           = NULL,
   @s_user               login         = NULL,
   @s_sesn               int           = NULL,
   @s_term               varchar(32)   = NULL,
   @s_date               datetime      = NULL,
   @s_srv                varchar(30)   = NULL,
   @s_lsrv               varchar(30)   = NULL, 
   @s_rol                smallint      = NULL,
   @s_ofi                smallint      = NULL,
   @s_org_err            char(1)       = NULL,
   @s_error              int           = NULL,
   @s_sev                tinyint       = NULL,
   @s_msg                descripcion   = NULL,
   @s_org                char(1)       = NULL,
   @s_culture            varchar(10)   = 'NEUTRAL',    
   @t_debug              char(1)       = 'N',
   @t_file               varchar(14)   = null,
   @t_from               varchar(32)   = null,
   @t_show_version       bit           = 0,     -- mostrar la version del programa
   @t_trn                int           = NULL,
   @i_operacion          varchar(2),
   -- DATOS PSEUDOCATALOGO GENERICO
   @i_bdatos            varchar(30)     = null, -- Nombre base de datos
   @i_tabla             varchar(50)     = null, -- Nombre tabla
   @i_tablaDos          varchar(50)     = null, -- Nombre tabla donde se cruza
   @i_campo_clave       varchar(30)     = null, -- Codigo del pseudocatalogo
   @i_campo_valor       varchar(30)     = null, -- Valor del pseudocatalogo
   @i_cruzar_cat        char(1)         = 'N',  -- Indica si el select se cruza con el catalogo cobis
   @i_campo_vigente     varchar(30)     = null, -- Campo de vigencia
   @i_campo_adic1       varchar(30)     = null, -- Campo adicional 1
   @i_campo_adic2       varchar(30)     = null, -- Campo adicional 2
   @i_campo_fil1        varchar(30)     = null, -- Campo filtro 1
   @i_campo_val1        varchar(255)    = null, -- Valor filtro 1
   @i_campo_fil2        varchar(30)     = null, -- Campo filtro 2
   @i_campo_val2        varchar(255)    = null, -- Valor filtro 2
   @i_campo_colUno      varchar(30)     = null, -- Campo igualar 1
   @i_campo_colDos      varchar(30)     = null  -- Campo igualar 2
)
as
declare @w_today        datetime,
        @w_sp_name      varchar(32),
        @w_query        varchar(1000),
        @w_query_fil    varchar(255),
        @w_dtype        varchar(255),
        @w_sp_msg       varchar(132),
        @w_result       TINYINT,
        @w_sql          nvarchar(200),
        @w_rol_asesor   int,
        @w_ofi_asesor   int
   
select @w_sp_name = 'sp_pseudocatalogo_tabla'

--Sacar el rol del asesor movil
select @w_rol_asesor = ro_rol 
from cobis..ad_rol 
where ro_descripcion = 'ASESOR MOVIL'

/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end


--Validaciones Iniciales
if @t_trn <> 172141
begin
    exec cobis..sp_cerror
       --NO CORRESPONDE CODIGO DE TRANSACCION
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name,
       @s_culture = @s_culture,    
       @i_num   = 151051
    return 1
end

if @i_bdatos is null or @i_tabla is null or @i_campo_clave is null or @i_campo_valor is null
begin
    exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name,
       @s_culture = @s_culture,    
       @i_num   = 1720422 -- Error en parametros de ingreso
    return 1
end
if @i_tabla <> 'sysobjects'
begin
   set @w_sql = N'select @w_result = 1 from ' + @i_bdatos + N'..sysobjects where name = @i_tabla'
   exec sp_executesql @w_sql,N'@i_tabla nvarchar(30),@w_result tinyint OUTPUT',@i_tabla,@w_result OUTPUT
   IF @w_result is null
   BEGIN
       exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @s_culture = @s_culture,    
          @i_num   = 1720423 -- No existe la tabla solicitada
       return 1
   end
   else
   begin
       set @w_sql = NULL
       set @w_result = null
   end
   
   
   exec('declare @w_result tinyint; select @w_result = 1 from ' + @i_bdatos + '..syscolumns where id = object_id(''' + @i_bdatos + '..' + @i_tabla + ''') and name = ''' + @i_campo_clave + '''')
   if @@ROWCOUNT = 0 and @i_operacion = 'S'
   begin
       exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @s_culture = @s_culture,    
          @i_num   = 1720424 -- No existe el campo solicitado
       return 1
   end
   else
   begin
       set @w_result = null
   end
   
   
   exec('declare @w_result tinyint; select @w_result = 1 from ' + @i_bdatos + '..syscolumns where id = object_id(''' + @i_bdatos + '..' + @i_tabla + ''') and name = ''' + @i_campo_valor + '''')
   if @@ROWCOUNT = 0 and @i_operacion = 'S'
   begin
       exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @s_culture = @s_culture,   
        @i_num   = 1720424 -- No existe el campo solicitado
       return 1
   end
   else
   begin
       set @w_result = null
   end
   
   if @i_campo_vigente is not null
   begin
       exec('declare @w_result tinyint; select @w_result = 1 from ' + @i_bdatos + '..syscolumns where id = object_id(''' + @i_bdatos + '..' + @i_tabla + ''') and name = ''' + @i_campo_vigente + '''')
       if @@ROWCOUNT = 0 and @i_operacion = 'S'
       begin
           exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @s_culture = @s_culture,        
              @i_num   = 1720424 -- No existe el campo solicitado
           return 1
       end
       else
       begin
           set @w_result = null
       end
   end
   
   if @i_campo_adic1 is not null
   begin
       exec('declare @w_result tinyint; select @w_result = 1 from ' + @i_bdatos + '..syscolumns where id = object_id(''' + @i_bdatos + '..' + @i_tabla + ''') and name = ''' + @i_campo_adic1 + '''')
       if @@ROWCOUNT = 0 and @i_operacion = 'S'
       begin
           exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @s_culture = @s_culture,        
              @i_num   = 1720424 -- No existe el campo solicitado
           return 1
       end
       else
       begin
           set @w_result = null
       end
   end
   
   if @i_campo_adic2 is not null
   begin
       exec('declare @w_result tinyint; select @w_result = 1 from ' + @i_bdatos + '..syscolumns where id = object_id(''' + @i_bdatos + '..' + @i_tabla + ''') and name = ''' + @i_campo_adic2 + '''')
       if @@ROWCOUNT = 0 and @i_operacion = 'S'
       begin
           exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @s_culture = @s_culture,        
              @i_num   = 1720424 -- No existe el campo solicitado
           return 1
       end
       else
       begin
           set @w_result = null
       end
   end
   
   if @i_campo_fil1 is not null
   begin
       exec('declare @w_result tinyint; select @w_result = 1 from ' + @i_bdatos + '..syscolumns where id = object_id(''' + @i_bdatos + '..' + @i_tabla + ''') and name = ''' + @i_campo_fil1 + '''')
       if @@ROWCOUNT = 0 and @i_operacion = 'S'
       begin
           exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @s_culture = @s_culture,        
              @i_num   = 1720424 -- No existe el campo solicitado
           return 1
       end
       else
       begin
           set @w_result = null
       end
   end
   
   if @i_campo_fil2 is not null
   begin
       exec('declare @w_result tinyint; select @w_result = 1 from ' + @i_bdatos + '..syscolumns where id = object_id(''' + @i_bdatos + '..' + @i_tabla + ''') and name = ''' + @i_campo_fil2 + '''')
       if @@ROWCOUNT = 0 and @i_operacion = 'S'
       begin
           exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @s_culture = @s_culture,        
              @i_num   = 1720424 -- No existe el campo solicitado
           return 1
       end
       else
       begin
           set @w_result = null
       end
   end
end
if @i_operacion = 'S'
begin
    if @t_trn = 172141
    begin
        --Query dinamico
        set @w_query = 'select ''Clave'' = convert(varchar, p.' + @i_campo_clave + '), ''Valor'' = convert(varchar, p.' + @i_campo_valor + ')'
        if @i_campo_adic1 is not null
        begin
            set @w_query = @w_query + ', ''Adic1'' = ' + @i_campo_adic1
        end
        if @i_campo_adic2 is not null
        begin
            set @w_query = @w_query + ', ''Adic2'' = ' + @i_campo_adic2
        end
        set @w_query = @w_query + ' from ' + @i_bdatos + '..' + @i_tabla + ' p'
        --Se agregan tablas de cruce
        if @i_cruzar_cat = 'S'
        begin
            set @w_query = @w_query + ', cobis..cl_tabla t, cobis..cl_catalogo c'
        end
        --Se coloca los valores vigentes
        if @i_campo_vigente is not null
        begin
            set @w_query = @w_query + ' where ' + @i_campo_vigente + ' = ''V'''
        end
        --Se coloca el cruce de tablas
        if @i_cruzar_cat = 'S'
        begin
            if charindex('where', @w_query) <> 0
            begin
                set @w_query = @w_query + ' and t.tabla = ''' + @i_tabla + ''' and c.tabla = t.codigo and c.codigo = convert(varchar, p.' + @i_campo_clave + ')'
            end
            else
            begin
                set @w_query = @w_query + ' where t.tabla = ''' + @i_tabla + ''' and c.tabla = t.codigo and c.codigo = convert(varchar, p.' + @i_campo_clave + ')'
            end
        end
        --Se coloca el filtro 1
        if @i_campo_fil1 is not null
        begin
           if @i_tabla = 'sysobjects'
              select @w_dtype = 'varchar'
           else
           begin
              set @w_sql = N'select @w_dtype = t.name from ' + @i_bdatos + '..systypes t inner join ' + @i_bdatos + '..syscolumns c on t.usertype = c.usertype where c.id = object_id(''' + @i_bdatos + '..' + @i_tabla + ''') and c.name = ''' + @i_campo_fil1 + ''''
              exec sp_executesql @w_sql,N'@@i_bdatos nvarchar(30),@w_dtype varchar(10) OUTPUT',@i_bdatos,@w_dtype OUTPUT
           end
           if ((@w_dtype is not null) and (@w_dtype not in ('varchar', 'char', 'tinyint', 'smallint', 'int', 'catalogo', 'estado')))
           begin
               exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file,
                  @t_from  = @w_sp_name,
                  @s_culture = @s_culture,                
                  @i_num   = 1720425 -- Tipo de dato no valido para filtrar pseudocatalogo
               return 1
           end
           if charindex('where', @w_query) <> 0
           begin
               set @w_query = @w_query + ' and ' + @i_campo_fil1 + ' = '
               select @w_query_fil = (case when @w_dtype = 'varchar' or @w_dtype = 'char' then char(39) + @i_campo_val1 + char(39) else @i_campo_val1 end)
               set @w_query = @w_query + @w_query_fil
           end
           else
           begin
               select @w_query = @w_query + ' where ' + @i_campo_fil1 + ' = '
               select @w_query_fil = (case when @w_dtype = 'varchar' or @w_dtype = 'char' then char(39) + @i_campo_val1 + char(39) else @i_campo_val1 end)
               set @w_query = @w_query + @w_query_fil
           end
        end
        --Se coloca el filtro 2
        if @i_campo_fil2 is not null
        begin
           set @w_sql = N'select @w_dtype = t.name from ' + @i_bdatos + '..systypes t inner join ' + @i_bdatos + '..syscolumns c on t.usertype = c.usertype where c.id = object_id(''' + @i_bdatos + '..' + @i_tabla + ''') and c.name = ''' + @i_campo_fil2 + ''''
           exec sp_executesql @w_sql,N'@@i_bdatos nvarchar(30),@w_dtype varchar(10) OUTPUT',@i_bdatos,@w_dtype OUTPUT           
           if ((@w_dtype is not null) and (@w_dtype not in ('varchar', 'char', 'tinyint', 'smallint', 'int', 'catalogo', 'estado')))
           begin
               exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file,
                  @t_from  = @w_sp_name,
                  @s_culture = @s_culture,                
                  @i_num   = 1720425 -- Tipo de dato no valido para filtrar pseudocatalogo
               return 1
           end
           if charindex('where', @w_query) <> 0
           begin
               set @w_query = @w_query + ' and ' + @i_campo_fil2 + ' = '
               select @w_query_fil = (case when @w_dtype = 'varchar' or @w_dtype = 'char' or @w_dtype = 'catalogo' or @w_dtype = 'estado' then char(39) + @i_campo_val2 + char(39) else @i_campo_val2 end)
               set @w_query = @w_query + @w_query_fil
           end
           else
           begin
               select @w_query = @w_query + ' where ' + @i_campo_fil2 + ' = '
               select @w_query_fil = (case when @w_dtype = 'varchar' or @w_dtype = 'char' or @w_dtype = 'catalogo' or @w_dtype = 'estado' then char(39) + @i_campo_val2 + char(39) else @i_campo_val2 end)
               set @w_query = @w_query + @w_query_fil
           end
        end
        --Se agrega el ordenamiento del query final
        set @w_query = @w_query + ' order by convert(varchar,' + @i_campo_clave + ') asc'
        exec(@w_query)
        return 0
    end
end

--Consulta personalizada para dos tablas
if @i_operacion = 'T'
begin
   if @t_trn = 172141
   begin
      if not exists (select 1 from sysobjects where name = @i_tabla) or not exists (select 1 from sysobjects where name = @i_tablaDos)
      begin
         exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @s_culture = @s_culture,        
              @i_num   = 1720423 -- No existe tabla solicitada
           return 1
      end

      set @w_query = 'select ''Clave'' = ' + @i_campo_clave + ', ''Valor'' = ' + @i_campo_valor + ' from '+@i_tabla+', '+@i_tablaDos+' where '+@i_campo_colUno+' = '+@i_campo_colDos

      if @i_campo_fil1 is not null and @i_campo_val1 is not null
         set @w_query = @w_query + ' and '+@i_campo_fil1+' = '+@i_campo_val1

      if @i_campo_fil2 is not null and @i_campo_val2 is not null
         set @w_query = @w_query + ' and '+@i_campo_fil2+' = '+@i_campo_val2
      
      --Filtrar por la oficina del usuario logueado en el app
      if @s_rol = @w_rol_asesor and @i_tabla = 'cc_oficial'
      begin
         select @w_ofi_asesor = fu_oficina 
         from cobis.dbo.cl_funcionario fu 
         where fu.fu_login = @s_user
         set @w_query = @w_query + ' and fu_oficina = ' + convert(varchar(100), @w_ofi_asesor)
      end
      
      exec (@w_query)
   end
end

go
