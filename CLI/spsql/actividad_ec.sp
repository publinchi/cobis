/************************************************************************/
/*  Archivo:                         actividad_ec.sp                    */
/*  Stored procedure:                sp_actividad_ec                    */
/*  Base de datos:                   cobis                              */
/*  Producto:                        Clientes                           */
/*  Disenado por:                    JMEG                               */
/*  Fecha de escritura:              30-Abril-19                        */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                          PROPOSITO                                   */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      30/04/19         JMEG         Emision Inicial                   */
/*      28/05/19         ALD          Se agregan operaciones 'A' y 'B'  */
/*      25/06/20         FSAP         Estandarizacion de Clientes       */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
             from sysobjects 
            where name = 'sp_actividad_ec')
   drop proc sp_actividad_ec
go
CREATE PROCEDURE sp_actividad_ec (
        @s_ssn                  int         = null,
        @s_user                 login       = null,
        @s_term                 varchar(32) = null,
        @s_sesn                 int         = null,
        @s_culture              varchar(10) = null,
        @s_date                 datetime    = null,
        @s_srv                  varchar(30) = null,
        @s_lsrv                 varchar(30) = null,
        @s_rol                  smallint    = NULL,
        @s_org_err              char(1)     = NULL,
        @s_error                int         = NULL,
        @s_sev                  tinyint     = NULL,
        @s_msg                  descripcion = NULL,
        @s_org                  char(1)     = NULL,
        @s_ofi                  smallint    = NULL,
        @t_debug                char(1)     = 'N',
        @t_file                 varchar(14) = null,
        @t_from                 varchar(30) = null,
        @t_trn                  int         = null,
        @t_show_version         bit         = 0,     -- Mostrar la version del programa
        @i_operacion            char (1)    = null,  -- Opcion con la que se ejecuta el programa
        @i_modo                 tinyint     = null,  -- Modo de busqueda
        @i_tipo                 char (1)    = null,  -- Tipo de consulta
        @i_cuenta               smallint    = null,  -- Codigo secuencial de la cuenta
        @i_descripcion          descripcion = null,  -- Descripcion de la cuenta contable
        @i_categoria            char (1)    = null,  -- Categoria de la cuenta contable
        @i_estado               estado      = null,  -- Estado de la cuenta contable
        @i_codigo               catalogo    = null,
        @i_industria            catalogo    = null,
        @i_valor                varchar(65) = null,
        @i_codSubsector         catalogo    = null,
        @i_codSector            catalogo    = null,
        @i_homolog_pn           catalogo    = null,
        @i_homolog_pj           catalogo    = null

)
as
declare @w_sp_name       char (10),
        @w_sp_msg        varchar(132),
        @w_return        int,
        @w_siguiente     int,
        @w_cuenta        smallint,
        @w_descripcion   descripcion,
        @w_estado        estado,
        @w_categoria     char (1),
        @w_industria     catalogo,
        @v_descripcion   descripcion,
        @v_categoria     char (1),
        @v_estado        estado,
        @v_industria     catalogo,
        @w_codSubsector  catalogo,
        @v_codSubsector  catalogo,
        @w_tabla         smallint,
        @w_homolog_pn    catalogo,
        @w_homolog_pj    catalogo


/*  Inicializacion de Variables  */
select  @w_sp_name = 'sp_actividad_ec'

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/



/*  Modo de Debug  */
if @t_debug = 'S'
begin
    exec cobis..sp_begin_debug @t_file = @t_file
    select '**  Stored Procedure  **' = @w_sp_name,
        s_ssn           = @s_ssn,
        s_user          = @s_user,
        s_term          = @s_term,
        s_srv           = @s_srv,
        s_lsrv          = @s_lsrv,
        t_file          = @t_file,
        t_from          = @t_from,
        t_trn           = @t_trn,
        i_operacion     = @i_operacion,
        i_cuenta        = @i_cuenta,
        i_descripcion   = @i_descripcion,
        i_categoria     = @i_categoria,
        i_estado        = @i_estado,
        i_homolog_pn    = @i_homolog_pn,
        i_homolog_pj    = @i_homolog_pj
    exec cobis..sp_end_debug
end

/*  Insert  */
if @i_operacion = 'I'
begin

if @t_trn = 172056
begin

    if exists ( select ac_codigo  from cl_actividad_ec
         where ac_codigo = @i_codigo )
    begin
    /*  Ya existe cuenta  */
    exec cobis..sp_cerror
        @t_debug= @t_debug,
        @t_file = @t_file,
        @t_from = @w_sp_name,
        @i_num  = 1720271
    return 1
    end

    begin tran
    /* insertar los datos de entrada */
    insert into cl_actividad_ec(ac_codigo, ac_descripcion,
                                 ac_industria,ac_estado,ac_codSubsector,ac_homolog_pn,ac_homolog_pj)
                       values  (@i_codigo, @i_descripcion,
                                @i_industria,@i_estado,@i_codSubsector,@i_homolog_pn,@i_homolog_pj)
    if @@error <> 0
    begin
        /*  Error en creacion actividad economica  */
        exec cobis..sp_cerror
            @t_debug= @t_debug,
            @t_file = @t_file,
            @t_from = @w_sp_name,
            @i_num  = 1720290
        return 1
    end
    --
    /* inserta en el catalogo */
    if exists (select 1 from cl_tabla where tabla = 'cl_actividad_ec') --MNU 2012.11.10 Catálogo Segmento Cliente
    begin
       select @w_tabla = codigo
                         from cl_tabla
                         where tabla = 'cl_actividad_ec'

       insert into cl_catalogo (tabla, codigo, valor, estado)
       values (@w_tabla, @i_codigo, @i_descripcion, @i_estado)

       /*  Error en insercion  */
       if @@error <> 0
       begin
       exec cobis..sp_cerror
            @t_debug= @t_debug,
            @t_file = @t_file,
            @t_from = @w_sp_name,
            @i_num  = 1720272
        return 1
       end
    end

    --
    commit tran

    return 0

end
else
begin
    exec sp_cerror
       @t_debug  = @t_debug,
       @t_file   = @t_file,
       @t_from   = @w_sp_name,
       @i_num    = 1720075
       /*  'No corresponde codigo de transaccion' */
    return 1
end

end

/*  Update  */
if @i_operacion = 'U'
begin
    select @i_estado = ltrim(rtrim(@i_estado))
    if @i_estado is null
    begin
       exec cobis..sp_cerror
            @t_debug= @t_debug,
            @t_file = @t_file,
            @t_from = @w_sp_name,
            @i_num  = 1720291
        return 1
    end

    if @t_trn = 172057
    begin
        select  @w_descripcion  = ac_descripcion,
                --@w_industria    = ac_industria,
                @w_estado       = ac_estado,
                @w_codSubsector = ac_codSubsector,
                @w_homolog_pn   = ac_homolog_pn,
                @w_homolog_pj   = ac_homolog_pj
          from  cl_actividad_ec
         where  ac_codigo    = @i_codigo
            --and ac_industria = @i_industria

        if @@rowcount <> 1
        begin
            /*  Codigo no existe en catalogo  */
            exec cobis..sp_cerror
                @t_debug= @t_debug,
                @t_file = @t_file,
                @t_from = @w_sp_name,
                @i_num  = 1720143
            return 1
        end

        begin tran

        update  cl_actividad_ec
           set  ac_descripcion  = @i_descripcion,
            --ac_industria    = @i_industria,
            ac_estado        = @i_estado,
            ac_codSubsector  = @i_codSubsector,
            ac_homolog_pn    = @i_homolog_pn,
            ac_homolog_pj    = @i_homolog_pj
         where  ac_codigo    = @i_codigo
            --and ac_industria = @i_industria

        /*  Error en actualizacion   */
        if @@error <> 0
        begin
          exec cobis..sp_cerror
                @t_debug= @t_debug,
                @t_file = @t_file,
                @t_from = @w_sp_name,
                @i_num  = 1720291
           return 1
        end

        --
        /* actualizar en catalago */
        if exists (select 1 from cl_tabla where tabla = 'cl_actividad_ec') --MNU 2012.11.10 Catálogo Segmento Cliente
           begin
           select @w_tabla = codigo
                             from cl_tabla
                             where tabla = 'cl_actividad_ec'

           if exists (select 1 from cl_catalogo where tabla = @w_tabla and codigo = @i_codigo)
           begin
               update cl_catalogo
               set valor  = @i_descripcion,
                   estado = @i_estado
               where tabla = @w_tabla
               and codigo  = @i_codigo

               if @@error <> 0
               begin
                  exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file = @t_file,
                   @t_from = @w_sp_name,
                   @i_num  = 1720273
                  return 1
               end
           end
        end
        --
        commit tran
        return 0

    end
    else
    begin
        exec sp_cerror
           @t_debug  = @t_debug,
           @t_file   = @t_file,
           @t_from   = @w_sp_name,
           @i_num    = 1720075
           /*  'No corresponde codigo de transaccion' */
        return 1
    end
end

/*  Search  */
if @i_operacion = 'S'
 begin

    if @t_trn = 172058
    begin

         set rowcount 20
         if @i_modo = 0

        select 'CODIGO'       = ac_codigo,
               'DESCRIPCION'  = ac_descripcion,
               'ESTADO'       = ac_estado,
               'COD. SUBSECTOR ECO.'=ac_codSubsector,
               'SUBSECTOR ECO.' = (select d.valor from cobis..cl_tabla c,
                                                      cobis..cl_catalogo d
                                                      where f.ac_codSubsector = d.codigo
                                                      and c.tabla = 'cl_subsector_ec'
                                                      and c.codigo = d.tabla),
               'HOMOLOGACION EDV P.N.'= ac_homolog_pn,
               'HOMOLOGACION EDV P.J.'= ac_homolog_pj
        from cobis..cl_actividad_ec f,
             cobis..cl_tabla a,
             cobis..cl_catalogo b
        where ac_codigo = b.codigo
          and  a.tabla = 'cl_actividad_ec'
          and  a.codigo = b.tabla
		  and  (ac_codigo   = @i_codigo or @i_codigo is null)
          and (Upper(ac_descripcion)  like @i_descripcion +'%' or @i_descripcion is null) -- Inc 65485
        order by ac_codigo

         else
        if @i_modo = 1

        select 'CODIGO'      = ac_codigo,
               'DESCRIPCION' = ac_descripcion,
               'ESTADO'      = ac_estado,
               'COD. SUBSECTOR ECO.'=ac_codSubsector,
               'SUBSECTOR ECO.' = (select d.valor from cobis..cl_tabla c,
                                                      cobis..cl_catalogo d
                                                      where f.ac_codSubsector = d.codigo
                                                      and c.tabla = 'cl_subsector_ec'
                                                      and c.codigo = d.tabla),
               'HOMOLOGACION EDV P.N.'= ac_homolog_pn,
               'HOMOLOGACION EDV P.J.'= ac_homolog_pj
        from cobis..cl_actividad_ec f,
             cobis..cl_tabla a,
             cobis..cl_catalogo b
        where ac_codigo = b.codigo
          and  a.tabla = 'cl_actividad_ec'
          and  a.codigo = b.tabla
          and  ac_codigo > @i_codigo
              order by ac_codigo
         set rowcount 0
         return 0

    end
    else
    begin
        exec sp_cerror
           @t_debug  = @t_debug,
           @t_file   = @t_file,
           @t_from   = @w_sp_name,
           @i_num    = 1720075
           /*  'No corresponde codigo de transaccion' */
        return 1
    end
end

/* ** Query ** */
if @i_operacion = 'Q'
begin

    if @t_trn = 172058
    begin

         set rowcount 20
         if @i_modo = 0
        select 'CODIGO'      = ac_codigo,
               'VALOR' = ac_descripcion,
               'ESTADO'      = ac_estado,
               'COD. SUBSECTOR ECO.'=ac_codSubsector,
               'SUBSECTOR ECO.' = (select se_descripcion from cobis..cl_subsector_ec where se_codigo=@i_codSubsector)
        from cobis..cl_actividad_ec,
             cobis..cl_tabla a,
             cobis..cl_catalogo b
        where ac_codigo = b.codigo
          and  a.tabla = 'cl_actividad_ec'
          and  a.codigo = b.tabla
          and  ac_codSubsector = @i_codSubsector

         else
        if @i_modo = 1
        select 'CODIGO'      = ac_codigo,
               'VALOR' = ac_descripcion,
               'ESTADO'      = ac_estado,
               'COD. SUBSECTOR ECO.'=ac_codSubsector,
               'SUBSECTOR ECO.' = (select se_descripcion from cobis..cl_subsector_ec where se_codigo=@i_codSubsector)
        from cobis..cl_actividad_ec,
             cobis..cl_tabla a,
             cobis..cl_catalogo b
        where ac_codigo = b.codigo
          and a.tabla = 'cl_actividad_ec'
          and a.codigo = b.tabla
          and ac_codSubsector = @i_codSubsector
          and ac_codigo > @i_codigo
    --          and  ac_industria = @i_industria
         set rowcount 0
         return 0
    end
    else
    begin
        exec sp_cerror
           @t_debug  = @t_debug,
           @t_file   = @t_file,
           @t_from   = @w_sp_name,
           @i_num    = 1720075
           /*  'No corresponde codigo de transaccion' */
        return 1
    end
end

/* ** Query1 ** Dado un sector eco. y/o descripcion busca las actividades eco. */
if @i_operacion = 'Z'
begin
   if @t_trn = 172058
   begin

      set rowcount 20
      if @i_modo = 0
      begin
         select 'CODIGO'             = ac_codigo,
              'VALOR'        = ac_descripcion,
              'ESTADO'             = ac_estado,
              'COD. SUBSECTOR ECO.' = ac_codSubsector,
              'SUBSECTOR ECO.'      = d.se_descripcion,
			  'COD.  SECTOR ECO.'   = e.se_codigo
         from cobis..cl_actividad_ec c,cl_subsector_ec d, cl_sector_economico e,
              cobis..cl_tabla a,
              cobis..cl_catalogo b
        where e.se_codigo    = @i_codSector
          and d.se_codSector = e.se_codigo
          and d.se_codigo    = c.ac_codSubsector
          and (@i_valor =null or ac_descripcion like @i_valor )
          and c.ac_codigo    = b.codigo
          and a.tabla        = 'cl_actividad_ec'
          and a.codigo       = b.tabla
          if @@rowcount = 0
          begin
             exec sp_cerror
                 @t_debug    = @t_debug,
                 @t_file     = @t_file,
                 @t_from     = @w_sp_name,
                 @i_num      = 1720289
                 /* No existen registros */
             return 1
          end
       end
       else
       if @i_modo = 1
       begin
          select 'CODIGO'      = ac_codigo,
                 'VALOR' = ac_descripcion,
                 'ESTADO'      = ac_estado,
                 'COD. SUBSECTOR ECO.'=ac_codSubsector,
                 'SUBSECTOR ECO.'      = d.se_descripcion,
				 'COD.  SECTOR ECO.'   = e.se_codigo
          from cobis..cl_actividad_ec c,cl_subsector_ec d, cl_sector_economico e,
               cobis..cl_tabla a,
               cobis..cl_catalogo b
          where e.se_codigo    = @i_codSector
            and d.se_codSector = e.se_codigo
            and d.se_codigo    = c.ac_codSubsector
            and (@i_valor =null or ac_descripcion like @i_valor )
            and c.ac_codigo    = b.codigo
            and a.tabla = 'cl_actividad_ec'
            and a.codigo = b.tabla
            and ac_codigo > @i_codigo
            if @@rowcount = 0
            begin
               exec sp_cerror
                   @t_debug    = @t_debug,
                   @t_file     = @t_file,
                   @t_from     = @w_sp_name,
                   @i_num      = 1720289
                   /* No existen mas registros */
               return 1
            end
       end
        set rowcount 0
        return 0

   end
   else
   begin
       exec sp_cerror
          @t_debug  = @t_debug,
          @t_file   = @t_file,
          @t_from   = @w_sp_name,
          @i_num    = 1720075
          /*  'No corresponde codigo de transaccion' */
       return 1
   end
end

/* ** Help ** */
if @i_operacion = 'H'
begin
    if @t_trn = 172058
    begin
        if @i_tipo = 'A'
        begin
            set rowcount 20

            if @i_modo = 0
            begin
                select 'CODIGO'      = ac_codigo,
                       'DESCRIPCION' = ac_descripcion,
                       'ESTADO'      = ac_estado,
                       'COD. SUBSECTOR ECO.'=ac_codSubsector,
                       'SUBSECTOR ECO.' = (select se_descripcion from cobis..cl_subsector_ec where se_codigo=@i_codSubsector)
                from cobis..cl_actividad_ec,
                     cobis..cl_tabla a,
                     cobis..cl_catalogo b
                where ac_codSubsector = b.codigo
                and a.tabla = 'cl_subsector_ec'
                and a.codigo = b.tabla
                and ac_codSubsector = @i_codSubsector
                and ac_estado = 'V'
                order by ac_codigo ASC
            end
            if @i_modo = 1
            begin
                select 'CODIGO'      = ac_codigo,
                       'DESCIPCION'  = ac_descripcion,
                       'ESTADO'      = ac_estado,
                       'COD. SUBSECTOR ECO.'=ac_codSubsector,
                       'SUBSECTOR ECO.' = (select se_descripcion from cobis..cl_subsector_ec where se_codigo=@i_codSubsector)
                from cobis..cl_actividad_ec,
                     cobis..cl_tabla a,
                     cobis..cl_catalogo b
                where ac_codSubsector = b.codigo
                and a.tabla = 'cl_subsector_ec'
                and a.codigo = b.tabla
                  and ac_codSubsector = @i_codSubsector
                  and ac_estado = 'V'
                  and ac_codigo > @i_codigo
                order by ac_codigo ASC
            end
            set rowcount 0
            return 0
        end

        if @i_tipo = 'V'
        begin
            select ac_descripcion
            from cobis..cl_actividad_ec,
               cobis..cl_tabla a,
               cobis..cl_catalogo b
            where ac_codigo = b.codigo
                and a.tabla = 'cl_actividad_ec'
                and a.codigo = b.tabla
                and ac_codigo = @i_codigo
            and ac_estado = 'V'

            if @@rowcount = 0
            begin
                exec sp_cerror
                    @t_debug    = @t_debug,
                    @t_file     = @t_file,
                    @t_from     = @w_sp_name,
                    @i_num      = 1720059
                return 1
            end
            return 0
        end

        /*Daddo un sector y actividad ec. trae detalle*/
        if @i_tipo = 'W'
        begin
           select 'CODIGO'             = ac_codigo,
                  'DESCRIPCION'        = ac_descripcion,
                  'ESTADO'             = ac_estado,
                  'COD. SUBSECTOR ECO.' = ac_codSubsector,
                  'SUBSECTOR ECO.'      = d.se_descripcion
           from cobis..cl_actividad_ec c,cl_subsector_ec d, cl_sector_economico e,
                cobis..cl_tabla a,
                cobis..cl_catalogo b
           where e.se_codigo    = @i_codSector
             and c.ac_codigo    = @i_codigo
             and d.se_codSector = e.se_codigo
             and d.se_codigo    = c.ac_codSubsector
             and c.ac_codigo    = b.codigo
             and a.tabla        = 'cl_actividad_ec'
             and a.codigo       = b.tabla
              if @@rowcount = 0
                begin
                   exec sp_cerror
                       @t_debug    = @t_debug,
                       @t_file     = @t_file,
                       @t_from     = @w_sp_name,
                       @i_num      = 1720074
                   return 1
                end
            return 0
        end

        if @i_tipo = 'X'
        begin
            select ac_descripcion
                from cobis..cl_actividad_ec,
                cobis..cl_tabla a,
                cobis..cl_catalogo b
                where ac_codigo = b.codigo
                and a.tabla = 'cl_actividad_ec'
                and a.codigo = b.tabla
                and ac_codigo = @i_codigo

            if @@rowcount = 0
            begin
                exec sp_cerror
                    @t_debug    = @t_debug,
                    @t_file     = @t_file,
                    @t_from     = @w_sp_name,
                    @i_num      = 1720023
                return 1
            end
            return 0
        end


        /* UTILIZADO PARA CUENTAS CORRIENTES*/
        if @i_tipo = 'Y'
        begin
            set rowcount 20
            if @i_modo = 0
               begin
                  select ac_codigo,ac_descripcion
                  from cobis..cl_actividad_ec,
                  cobis..cl_tabla a,
                  cobis..cl_catalogo b
                  where ac_codigo = b.codigo
                  and a.tabla = 'cl_actividad_ec'
                  and a.codigo = b.tabla
                  and ac_estado = 'V'

            if @@rowcount = 0
                     begin
                        exec sp_cerror
                        @t_debug   = @t_debug,
                        @t_file    = @t_file,
                        @t_from    = @w_sp_name,
                        @i_num     = 1720059
                        return 1720059
                  end
               end
            else
              if @i_modo = 1
                 select ac_codigo,ac_descripcion
                 from cobis..cl_actividad_ec,
                 cobis..cl_tabla a,
                 cobis..cl_catalogo b
                 where ac_codigo = b.codigo
                 and a.tabla = 'cl_actividad_ec'
                 and a.codigo = b.tabla
                 and ac_codigo > @i_codigo
                 and ac_estado = 'V'
                 set rowcount 0
                 return 0
        end


        if @i_tipo = 'B'
        begin
            set rowcount 20
            if @i_modo = 0
               select 'CODIGO'      = ac_codigo,
                      'DESCRIPCION' = ac_descripcion,
                      'ESTADO'      = ac_estado,
                      'COD. SUBSECTOR ECO.'=ac_codSubsector,
                      'SUBSECTOR ECO.' = (select se_descripcion from cobis..cl_subsector_ec where se_codigo=@i_codSubsector)
                 from cobis..cl_actividad_ec,
                  cobis..cl_tabla a,
                  cobis..cl_catalogo b
                where ac_codigo = b.codigo
                 and a.tabla = 'cl_actividad_ec'
                 and a.codigo = b.tabla
                  and ac_codSubsector = @i_codSubsector
                  and upper(ac_descripcion) like upper(@i_valor)
            else
            if @i_modo = 1
            select 'CODIGO'      = ac_codigo,
                   'DESCRIPCION' = ac_descripcion,
                   'ESTADO'      = ac_estado,
                   'COD. SUBSECTOR ECO.'=ac_codSubsector,
                   'SUBSECTOR ECO.' = (select se_descripcion from cobis..cl_subsector_ec where se_codigo=@i_codSubsector)
               from cobis..cl_actividad_ec,
                cobis..cl_tabla a,
                cobis..cl_catalogo b
               where ac_codigo = b.codigo
                 and a.tabla = 'cl_actividad_ec'
                 and a.codigo = b.tabla
                 and ac_codSubsector = @i_codSubsector
				 and upper(ac_descripcion) like upper(@i_valor)
                 and ac_codigo > @i_codigo

            set rowcount 0
            return 0
        end
    end --
end
--operacion para mostrar  actividades economicas
if @i_operacion='A'
begin
  if @t_trn = 172059
  begin
  	select 'CODIGO'      = ac_codigo, 'DESCRIPCION' = ac_descripcion
  	from cobis..cl_actividad_ec,cobis..cl_subsector_ec
	where ac_codSubsector = @i_codSubsector
	and se_codigo=@i_codSubsector
  	order by se_codigo
return 0
  end
end

--operacion para mostrar subsectores
if @i_operacion='B'
begin
  if @t_trn = 172059
  begin
  	select 'CODIGO'      = a.se_codigo, 'DESCRIPCION' = a.se_descripcion
  	from cobis..cl_subsector_ec a, cobis..cl_sector_economico b
  	where a.se_codSector = @i_codSector
  	and b.se_codigo=@i_codSector
  	order by a.se_codigo
  	
	return 0
	end
end

else
begin
    exec sp_cerror
       @t_debug  = @t_debug,
       @t_file   = @t_file,
       @t_from   = @w_sp_name,
       @i_num    = 1720075
       /*  'No corresponde codigo de transaccion' */
    return 1
end

--GO
--sp_procxmode 'dbo.sp_actividad_ec', 'Unchained'
GO

