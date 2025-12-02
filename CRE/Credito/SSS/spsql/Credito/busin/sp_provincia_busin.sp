/* **********************************************************************/
/*   Archivo:              sp_provincia_busin.sp                        */
/*   Stored procedure:     sp_provincia_busin                           */
/*   Base de datos:        cob_pac                                      */
/*      Producto:               Clientes                                */
/*      Disenado por:           JMV                                     */
/*      Fecha de escritura:     05-Octubre-21                           */
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
/* **********************************************************************/
/*                            PROPOSITO                                 */
/* **********************************************************************/
/*   Este stored procedure realiza el mantenimiento de catalogo de      */
/*   provincias                                                         */
/* **********************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      05/10/21         JMV      Modificacion tabla cl_depart_pais     */
/************************************************************************/
USE cob_pac
go

IF OBJECT_ID ('dbo.sp_provincia_busin') IS NOT NULL
    DROP PROCEDURE dbo.sp_provincia_busin
GO

create proc sp_provincia_busin (
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
   @t_debug              char(1)       = 'N',
   @t_file               varchar(14)   = null,
   @t_from               varchar(32)   = null,
   @t_trn                int           = NULL,
   @t_show_version       bit           = 0,
   @i_operacion          varchar(2),
   @i_modo               tinyint       = null,
   @i_tipo               varchar(1)    = null,
   @i_provincia          int           = null, -- Cambio de smallint a int
   @i_descripcion        descripcion   = null,
   @i_region_nat         varchar(2)    = null,
   @i_region_ope         varchar(3)    = null,
   @i_pais               smallint      = null,
   @i_estado             estado        = null,
   @i_central_transmit   varchar(1)    = null,
   @i_valor              descripcion   = null,
   @i_provinc_alf        varchar(64)   = null,
   @i_departamento       catalogo      = null,
   @i_rowcount           tinyint       = 20,
   @o_filas              tinyint       = null out
)
as
declare @w_today    datetime,
   @w_sp_name       varchar(32),
   @w_cambio        int,
   @w_codigo        int,
   @w_ciudad        int,
   @w_descripcion   descripcion,
   @w_region_nat    varchar(2),
   @w_region_ope    varchar(3),
   @w_pais          smallint,
   @w_estado        estado,
   @w_transaccion   int,
   @v_descripcion   descripcion,
   @v_region_nat    varchar(2),
   @v_region_ope    varchar(3),
   @v_pais          smallint,
   @v_estado        estado,
   @v_departamento  catalogo,
   @o_provincia     int, --Cambio de smallint a int
   @w_server_logico varchar(10),
   @w_num_nodos     smallint,
   @w_contador      smallint,
   @w_cmdtransrv    varchar(60),
   @w_nt_nombre     varchar(30),
   @w_clave         int,
   @w_return        int,
   @w_codigo_c      varchar(10),
   @w_departamento  catalogo,
   @w_numerror      int          --guarda num de errror

select
   @w_today   = @s_date,
   @w_sp_name = 'sp_provincia_busin',
   @o_filas   = 13

if @t_show_version = 1
begin
    print 'Stored procedure %1! Version 4.0.0.2 ' + @w_sp_name
    return 0
end


-- INSERT
if @i_operacion = 'I'
   begin
   if @t_trn = 1526
   begin

   -- VERIFICACION DE CLAVES FORANEAS

     -- REGION NATURAL
     select @w_codigo = null
     from  cobis..cl_catalogo c, cobis..cl_tabla t
     where c.codigo = @i_region_nat
     and   t.tabla = 'cl_region_nat'
     and   t.codigo = c.tabla

     if @@rowcount = 0
     begin
        exec cobis..sp_cerror
        -- 'NO EXISTE REGION NATURAL
           @t_debug   = @t_debug,
           @t_file      = @t_file,
           @t_from      = @w_sp_name,
           @i_num      = 101039
        return 1
     end

     -- REGION OPERATIVA
     select @w_codigo = null
     from  cobis..cl_catalogo c, cobis..cl_tabla t
     where c.codigo = @i_region_ope
     and   t.tabla = 'cl_region_ope'
     and   t.codigo = c.tabla

     if @@rowcount = 0
     begin
        exec cobis..sp_cerror
        -- 'NO EXISTE REGION OPERATIVA'
         @t_debug   = @t_debug,
         @t_file      = @t_file,
         @t_from      = @w_sp_name,
         @i_num      = 101040
        return 1
     end

     select @w_codigo = null
     from   cobis..cl_pais
     where  pa_pais = @i_pais

     if @@rowcount = 0
     begin
        exec cobis..sp_cerror
         -- 'NO EXISTE PAIS
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 101018
        return 1
     end

     -- DEPARTAMENTO
     select @w_codigo = null
     from  cobis..cl_depart_pais, cobis..cl_pais
     where dp_pais = pa_pais
     and   dp_pais = @i_pais
     and   dp_departamento = @i_departamento
     if @@rowcount = 0
      begin
         exec cobis..sp_cerror
         -- 'NO EXISTE EL DEPARTAMENTO'
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 101038
         return 1
      end

     -- PROVINCIA
     if exists (select pv_provincia  from cobis..cl_provincia
               where pv_provincia = @i_provincia )
     begin
        exec cobis..sp_cerror
         -- 'YA EXISTE PROVINCIA'
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 151073
        return 1
     end

     begin tran

     -- INSERT cobis..cl_provincia
     insert into cobis..cl_provincia (pv_provincia,   pv_descripcion,   pv_region_nat,
                               pv_region_ope,  pv_pais,          pv_estado,
                               pv_depart_pais)
                        values (@i_provincia,  @i_descripcion,   @i_region_nat,
                               @i_region_ope,  @i_pais,          'V',
                               @i_departamento)
     if @@error != 0
     begin
        exec cobis..sp_cerror
           -- 'ERROR EN CREACION DE PROVINCIA'
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 103043
        return 1
     end

     -- TRANSACCION SERVICIO - PROVINCIA
     insert into cobis..ts_provincia (
                    secuencia,    tipo_transaccion,      clase,        fecha,
                    oficina_s,    usuario,               terminal_s,   srv,
                    lsrv,         hora,                  provincia,    descripcion,
                    region_nat,   region_ope,            pais,         estado,
                    departamento)
            values (@s_ssn,       1526,                  'N',          @s_date,
                    @s_ofi,       @s_user,               @s_term,      @s_srv,
                    @s_lsrv,      getdate(),             @i_provincia, @i_descripcion,
                    @i_region_nat,@i_region_ope,         @i_pais,      'V',
                    @i_departamento)

     if @@error != 0
     begin
        exec cobis..sp_cerror
           -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIOS'
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 103005
        return 1
      end
     commit tran

     -- ACTUALIZACION DE LA LOS DATOS EN EL CATALOGO
     select @w_codigo_c = convert(varchar(10), @i_provincia)
        exec
           @w_return      = cobis..sp_catalogo
           @s_ssn         = @s_ssn,
           @s_user        = @s_user,
           @s_sesn        = @s_sesn,
           @s_term        = @s_term,
           @s_date        = @s_date,
           @s_srv         = @s_srv,
           @s_lsrv        = @s_lsrv,
           @s_rol         = @s_rol,
           @s_ofi         = @s_ofi,
           @s_org_err     = @s_org_err,
           @s_error       = @s_error,
           @s_sev         = @s_sev,
           @s_msg         = @s_msg,
           @s_org         = @s_org,
           @t_debug       = @t_debug,
           @t_file        = @t_file,
           @t_from        = @w_sp_name,
           @t_trn         = 584,
           @i_operacion   = 'I',
           @i_tabla       = 'cobis..cl_provincia',
           @i_codigo      = @w_codigo_c,
           @i_descripcion = @i_descripcion,
           @i_estado      = 'V'

           if @w_return != 0
           return @w_return

        return 0
        end
    else
       begin
          exec cobis..sp_cerror
             -- 'NO CORRESPONDE CODIGO DE TRANSACCION'
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 151051
          return 1
       end
   end

-- UPDATE
if @i_operacion = 'U'
   begin
      if @t_trn = 1527
         begin

           -- VERIFICACION DE CLAVES FORANEAS
           select @w_codigo = null
           from  cobis..cl_catalogo c, cobis..cl_tabla t
           where c.codigo = @i_region_nat
           and   t.tabla = 'cl_region_nat'
           and   t.codigo = c.tabla

           if @@rowcount = 0
           begin
              exec cobis..sp_cerror
              -- 'NO EXISTE REGION NATURAL'
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 101039
              return 1
           end

           select @w_codigo = null
           from  cobis..cl_catalogo c, cobis..cl_tabla t
           where c.codigo = @i_region_ope
           and   t.tabla = 'cl_region_ope'
           and   t.codigo = c.tabla

           if @@rowcount = 0
           begin
              exec cobis..sp_cerror
              -- 'NO EXISTE REGION OPERATIVA'
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 101040
              return 1
           end

           select @w_codigo = null
             from cobis..cl_pais
            where pa_pais = @i_pais
           if @@rowcount = 0
           begin
              exec cobis..sp_cerror
               -- 'NO EXISTE PAIS'
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 101018
              return 1
           end

           -- DEPARTAMENTO
           select @w_codigo = null
           from  cobis..cl_depart_pais, cobis..cl_pais
           where dp_pais = pa_pais
           and   dp_pais = @i_pais
           and   dp_departamento = @i_departamento
           if @@rowcount = 0
            begin
               exec cobis..sp_cerror
               -- 'NO EXISTE EL DEPARTAMENTO'
                  @t_debug = @t_debug,
                  @t_file  = @t_file,
                  @t_from  = @w_sp_name,
                  @i_num   = 101038
               return 1
            end

           select
              @w_descripcion  = pv_descripcion,
              @w_region_nat   = pv_region_nat,
              @w_region_ope   = pv_region_ope,
              @w_pais         = pv_pais,
              @w_departamento = pv_depart_pais,
              @w_estado       = pv_estado
           from cobis..cl_provincia
           where pv_provincia = @i_provincia

           select @v_descripcion  = @w_descripcion
           select @v_region_nat   = @w_region_nat
           select @v_region_ope   = @w_region_ope
           select @v_pais         = @w_pais
           select @v_departamento = @w_departamento
           select @v_estado       = @w_estado

           if @w_descripcion = @i_descripcion
              select @w_descripcion = null, @v_descripcion = null
           else
              select @w_descripcion = @i_descripcion
           if @w_region_nat = @i_region_nat
              select @w_region_nat = null, @v_region_nat = null
           else
              select @w_region_nat = @i_region_nat
           if @w_region_ope = @i_region_ope
              select @w_region_ope = null, @v_region_ope = null
           else
              select @w_region_ope =  @i_region_ope
           if @w_pais = @i_pais
              select @w_pais = null, @v_pais = null
           else
              --select @w_departamento = @i_departamento    --Inc65758
              select @w_pais = @i_pais
           if @w_departamento = @i_departamento
              select @w_departamento = null, @v_departamento = null
           else
              --select @w_pais = @i_pais                    --Inc65758
              select @w_departamento = @i_departamento
           if @w_estado = @i_estado
              select @w_estado = null, @v_estado = null
           else
           begin
            if @i_estado = 'C'
            begin
               if exists (
                  select *
                  from  cobis..cl_ciudad
                  where ci_provincia = @i_provincia
                    )
               begin
                  exec cobis..sp_cerror
                     -- EXISTE REFERENCIA EN CIUDAD
                     @t_debug = @t_debug,
                     @t_file  = @t_file,
                     @t_from  = @w_sp_name,
                     @i_num   = 101072
                  return 1
               end
            end
            --else
            --begin
               if exists (
                  select *
                  from  cobis..cl_pais
                  where pa_pais = @i_pais
                  and   pa_estado = 'C'
                    )
               begin
                  exec cobis..sp_cerror
                     -- PAIS NO VIGENTE
                     @t_debug = @t_debug,
                     @t_file  = @t_file,
                     @t_from  = @w_sp_name,
                     @i_num   = 101074
                  return 1
               end

               if exists (
                  select *
                  from  cobis..cl_depart_pais
                  where dp_departamento = @i_departamento
                  and   dp_estado = 'C'
                    )
               begin
                  exec cobis..sp_cerror
                     -- DEPARTAMENTO NO VIGENTE
                     @t_debug = @t_debug,
                     @t_file  = @t_file,
                     @t_from  = @w_sp_name,
                     @i_num   = 101075
                  return 1
               end
            --end

            select @w_estado = @i_estado
           end

           begin tran
              -- UPDATE PROVINCIA
              update cobis..cl_provincia
              set    pv_descripcion = @i_descripcion,
                pv_region_nat  = @i_region_nat,
                pv_region_ope  = @i_region_ope,
                pv_pais        = @i_pais,
                pv_depart_pais = @i_departamento,
                pv_estado      = @i_estado
              where  pv_provincia = @i_provincia

              if @@error != 0
                 begin
                    exec cobis..sp_cerror
                       -- 'ERROR EN ACTUALIZACION DE PROVINCIA'
                       @t_debug   = @t_debug,
                       @t_file      = @t_file,
                       @t_from      = @w_sp_name,
                       @i_num      = 105038
                    return 1
                  end

            -- TRANSACCION SERVICIOS - PROVINCIA
            insert into cobis..ts_provincia (
                    secuencia,    tipo_transaccion,      clase,        fecha,
                    oficina_s,    usuario,               terminal_s,   srv,
                    lsrv,         hora,                  provincia,    descripcion,
                    region_nat,   region_ope,            pais,         estado,
                    departamento)
            values (@s_ssn,       1526,                  'P',          @s_date,
                    @s_ofi,       @s_user,               @s_term,      @s_srv,
                    @s_lsrv,      getdate(),             @i_provincia, @v_descripcion,
                    @v_region_nat,@v_region_ope,         @v_pais,      @v_estado,
                    @v_departamento)

            if @@error != 0
               begin
                  exec cobis..sp_cerror
               -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIOS'
                     @t_debug   = @t_debug,
                     @t_file      = @t_file,
                     @t_from      = @w_sp_name,
                     @i_num      = 103005
                  return 1
               end

            insert into cobis..ts_provincia (
                    secuencia,    tipo_transaccion,      clase,        fecha,
                    oficina_s,    usuario,               terminal_s,   srv,
                    lsrv,         hora,                  provincia,    descripcion,
                    region_nat,   region_ope,            pais,         estado,
                    departamento)
            values (@s_ssn,       1526,                  'A',          @s_date,
                    @s_ofi,       @s_user,               @s_term,      @s_srv,
                    @s_lsrv,      getdate(),             @i_provincia, @w_descripcion,
                    @w_region_nat,@w_region_ope,         @w_pais,      @w_estado,
                    @w_departamento)

            if @@error != 0
            begin
               exec cobis..sp_cerror
                  -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIOS'
                  @t_debug   = @t_debug,
                  @t_file      = @t_file,
                  @t_from      = @w_sp_name,
                  @i_num      = 103005
               return 1
            end
           commit tran

           select @w_codigo_c = convert(varchar(10), @i_provincia)
              exec @w_return = cobis..sp_catalogo
                 @s_ssn           = @s_ssn,
                 @s_user          = @s_user,
                 @s_sesn          = @s_sesn,
                 @s_term          = @s_term,
                 @s_date          = @s_date,
                 @s_srv           = @s_srv,
                 @s_lsrv          = @s_lsrv,
                 @s_rol           = @s_rol,
                 @s_ofi           = @s_ofi,
                 @s_org_err       = @s_org_err,
                 @s_error         = @s_error,
                 @s_sev           = @s_sev,
                 @s_msg           = @s_msg,
                 @s_org           = @s_org,
                 @t_debug         = @t_debug,
                 @t_file          = @t_file,
                 @t_from          = @w_sp_name,
                 @t_trn           = 585,
                 @i_operacion     = 'U',
                 @i_tabla         = 'cobis..cl_provincia',
                 @i_codigo        = @w_codigo_c,
                 @i_descripcion   = @i_descripcion,
                 @i_estado        = @i_estado
              if @w_return != 0
                 return @w_return
                 return 0
         end
      else
         begin
            exec cobis..sp_cerror
               -- 'NO CORRESPONDE CODIGO DE TRANSACCION'
               @t_debug    = @t_debug,
               @t_file    = @t_file,
               @t_from    = @w_sp_name,
               @i_num    = 151051
            return 1
         end
end

-- SEARCH
if @i_operacion = 'S'
   begin
      if @t_trn = 1549
         begin
            set rowcount 20
            if @i_modo = 0
                select
                 'CODIGO'             = pv_provincia,
                 'PROVINCIA'          = substring(pv_descripcion,1,20),
                 'COD. REG. OP.'      = pv_region_ope,
                 'REGION OPERERATIVA' = (select substring(c.valor,1,20)
                                           from cobis..cl_tabla t, cobis..cl_catalogo c
                                          where t.codigo        = c.tabla
                                            and t.tabla         = 'cl_region_ope'
                                            and p.pv_region_ope = c.codigo),
                 'COD. REG. NAT.'     = pv_region_nat,
                 'REGION NATURAL'     = (select substring(c.valor,1,20)
               from cobis..cl_tabla t, cobis..cl_catalogo c
                                          where t.codigo        = c.tabla
                                            and t.tabla         = 'cl_region_nat'
                                            and p.pv_region_nat = c.codigo),
                 'COD. PAIS'          = pv_pais,
                 'PAIS'               = substring(pa_descripcion,1,20),
                 'ESTADO'             = pv_estado
              from  cobis..cl_provincia p,
                    cobis..cl_pais
              where pa_pais = pv_pais
                and (pv_provincia   = @i_provincia or @i_provincia is null)
                and (Upper(pv_descripcion)  like @i_descripcion +'%' or @i_descripcion is null)
              order by pv_provincia
            else
           if @i_modo = 1
               select
                 'CODIGO'             = pv_provincia,
                 'PROVINCIA'          = substring(pv_descripcion,1,20),
                 'COD. REG. OP.'      = pv_region_ope,
                 'REGION OPERERATIVA' = (select substring(c.valor,1,20)
                                           from cobis..cl_tabla t, cobis..cl_catalogo c
                                          where t.codigo        = c.tabla
                                            and t.tabla         = 'cl_region_ope'
                                            and p.pv_region_ope = c.codigo),
                 'COD. REG. NAT.'     = pv_region_nat,
                 'REGION NATURAL'     = (select substring(c.valor,1,20)
                                           from cobis..cl_tabla t, cobis..cl_catalogo c
                                          where t.codigo        = c.tabla
                                            and t.tabla         = 'cl_region_nat'
                                            and p.pv_region_nat = c.codigo),
                 'COD. PAIS'          = pv_pais,
                 'PAIS'               = substring(pa_descripcion,1,20),
                 'ESTADO'             = pv_estado
              from  cobis..cl_provincia p,
                    cobis..cl_pais
              where pa_pais = pv_pais
                and (Upper(pv_descripcion)  like @i_descripcion +'%' or @i_descripcion is null)
                and pv_provincia > @i_provincia
              order by pv_provincia

              if @@rowcount = 0
                 exec cobis..sp_cerror
                 -- 'NO EXISTE DATO EN CATALOGO'
                 @t_debug= @t_debug,
                 @t_file= @t_file,
                 @t_from= @w_sp_name,
                 @i_num= 101000
              set rowcount 0
              return 0
              end
      else
         begin
         exec cobis..sp_cerror
            --  'NO CORRESPONDE CODIGO DE TRANSACCION'
            @t_debug = @t_debug,
            @t_file = @t_file,
            @t_from = @w_sp_name,
            @i_num = 151051
         return 1
   end
end

-- QUERY
if @i_operacion = 'Q'
begin
   if @t_trn = 1548
      begin
         set rowcount 13
         if @i_modo = 0
            select
               'CODIGO'           = pv_provincia,
               'PROVINCIA'        = pv_descripcion,
               'COD. REG. OP.'    = pv_region_ope,
               'REGION OPERATIVA' = isnull((select valor
                                       from cobis..cl_tabla t, cobis..cl_catalogo c
                                       where t.codigo = c.tabla
           and   t.tabla = 'cl_region_ope'
                        and   c.codigo = p.pv_region_ope
                                       ) ,''),
               'COD. REG. NAT.'   = pv_region_nat,
               'REGION NATURAL'   = isnull((select valor
                                         from cobis..cl_tabla t, cobis..cl_catalogo c
                                         where t.codigo = c.tabla
                                         and   t.tabla = 'cl_region_nat'
                                         and   c.codigo = p.pv_region_nat
                                         ) ,''),
               'COD. PAIS'         = pv_pais,
               'PAIS'              = pa_descripcion,
               'COD. DEPARTAMENTO' = pv_depart_pais
               from cobis..cl_provincia p, cobis..cl_pais
               where pv_pais = pa_pais
               and   pv_estado = 'V'
               order  by pv_provincia
         else
         if @i_modo = 1
            select
               'CODIGO'           = pv_provincia,
               'PROVINCIA'        = pv_descripcion,
               'COD. REG. OP.'    = pv_region_ope,
               'REGION OPERATIVA' = isnull((select valor
                                       from cobis..cl_tabla t, cobis..cl_catalogo c
                                       where t.codigo = c.tabla
                                       and   t.tabla = 'cl_region_ope'
                                       and   c.codigo = p.pv_region_ope
                                       ) ,''),
               'COD. REG. NAT.'   = pv_region_nat,
               'REGION NATURAL'   = isnull((select valor
                                         from cobis..cl_tabla t, cobis..cl_catalogo c
                                         where t.codigo = c.tabla
                                         and   t.tabla = 'cl_region_nat'
                                         and   c.codigo = p.pv_region_nat
                                         ) ,''),
               'COD. PAIS'         = pv_pais,
               'PAIS'              = pa_descripcion,
               'COD. DEPARTAMENTO' = pv_depart_pais
               from cobis..cl_provincia p, cobis..cl_pais
               where pv_pais = pa_pais
               and   pv_estado = 'V'
               and   pv_provincia > @i_provincia
               order  by pv_provincia

            if @@rowcount = 0
               -- 'NO EXISTE DATO EN CATALOGO'
               exec cobis..sp_cerror
                  @t_debug   = @t_debug,
                  @t_file      = @t_file,
                  @t_from      = @w_sp_name,
                  @i_num      = 101000
                 set rowcount 0
                 return 0
            end
   else
      begin
         exec cobis..sp_cerror
            -- 'NO CORRESPONDE CODIGO DE TRANSACCION'
            @t_debug    = @t_debug,
            @t_file    = @t_file,
            @t_from    = @w_sp_name,
            @i_num    = 151051
         return 1
      end
   end

-- HELP
if @i_operacion = 'H'
begin
   if @t_trn = 1550
   begin
      if @i_tipo = 'A'
      begin
            set rowcount @i_rowcount
            if @i_modo = 0
            begin
               select
                  'COD.'             = pv_provincia,
                  'PROVINCIA'        = pv_descripcion,
                  'COD.PAIS'         = pa_pais,
                  'PAIS '            = pa_descripcion
                  from  cobis..cl_provincia, cobis..cl_pais
                  where pa_pais = pv_pais

                  and   pv_pais = @i_pais

                  and   pv_estado = 'V'
                  and (pv_provincia   = @i_provincia or @i_provincia is null)
                  and (Upper(pv_descripcion)  like @i_descripcion +'%' or @i_descripcion is null)
               order by pv_provincia
            end
            if @i_modo = 1
            begin
               select
                  'COD.'             = pv_provincia,
                  'PROVINCIA'        = pv_descripcion,
                  'COD.PAIS'         = pa_pais,
                  'PAIS '            = pa_descripcion
                  from  cobis..cl_provincia, cobis..cl_pais
                  where pa_pais = pv_pais
                  and   pv_pais = @i_pais
                  and  (pv_depart_pais = @i_departamento or @i_departamento is null)
                  and   pv_provincia > @i_provincia
                  and   pv_estado = 'V'
                  and (Upper(pv_descripcion)  like @i_descripcion +'%' or @i_descripcion is null)
               order by pv_provincia
            end
            --BES - 19092017 -- PARA FIE
            if @i_modo = 2
            begin
                select @i_pais = pa_smallint from cobis..cl_parametro where pa_nemonico='PAIS'
                select
                 'COD.'             = pv_provincia,
                 'PROVINCIA'        = pv_descripcion,
                 'COD.PAIS'         = pa_pais,
                 'PAIS '            = pa_descripcion
                from  cobis..cl_provincia, cobis..cl_pais
                where  pa_pais = pv_pais
                and  pv_pais = isnull(@i_pais, pv_pais)
                and  pv_estado = 'V'

            end
            set rowcount 0
            return 0
      end -- 'A'
      if @i_tipo = 'V'
      begin
         select pv_descripcion
            from  cobis..cl_provincia, cobis..cl_pais
            where pv_pais = pa_pais
            and   (pv_pais = @i_pais or @i_pais = null)
            and   (pv_depart_pais = @i_departamento or @i_departamento = null)
            and   pv_provincia = @i_provincia
            and   pv_estado = 'V'

         if @@rowcount = 0
            exec cobis..sp_cerror
               -- 'NO EXISTE DATO EN CATALOGO'
               @t_debug   = @t_debug,
               @t_file      = @t_file,
               @t_from      = @w_sp_name,
               @i_num      = 101000
         return 0
      end -- 'V'

      if @i_tipo = 'B' -- BUSQUEDA ALFABETICA
      begin
            set rowcount 20
            if @i_modo = 0
            begin
                  select
                     'COD.'             = pv_provincia,
                     'PROVINCIA'        = pv_descripcion,
                     'COD.PAIS'         = pa_pais,
                     'PAIS '            = pa_descripcion
                     from  cobis..cl_provincia, cobis..cl_pais
                     where pa_pais    = pv_pais
                     and   pv_pais = @i_pais
                     and   pv_depart_pais = @i_departamento
                     and   pv_estado    = 'V'
                     and   pv_descripcion like @i_valor
                     order by pv_descripcion
            end
            if @i_modo = 1
            begin
                  select
                     'COD.'             = pv_provincia,
                     'PROVINCIA'        = pv_descripcion,
                     'COD.PAIS'         = pa_pais,
                     'PAIS '            = pa_descripcion
                     from  cobis..cl_provincia, cobis..cl_pais
                     where pa_pais    = pv_pais
                     and   pv_pais = @i_pais
                     and   pv_depart_pais = @i_departamento
                     and   pv_estado    = 'V'
                     and   pv_descripcion > @i_provinc_alf
                     and   pv_descripcion like @i_valor
                     order by pv_descripcion

            end
            set rowcount 0
            return 0
      end -- 'B'

      -- CONSULTA CLIENTE POR COD PROVINCIA
      if @i_tipo = 'P'
      begin
         select pv_descripcion
         from  cobis..cl_provincia
         where pv_provincia = @i_provincia
         and   pv_pais        = @i_pais
         and   pv_depart_pais = @i_departamento
         and   pv_estado = 'V'

         if @@rowcount = 0
            exec cobis..sp_cerror
               -- 'NO EXISTE DATO EN CATALOGO'
               @t_debug   = @t_debug,
               @t_file      = @t_file,
               @t_from      = @w_sp_name,
               @i_num      = 101000
         return 0
      end -- 'P'
      -- FIN CONSULTA CLIENTE POR COD PROVINCIA

      /*Controla mensajes de error*/
      if @i_provinc_alf = null
         select @w_numerror = 101209
      else
         select @w_numerror = 151121

      /*Busqueda de provincias por descripcion*/
      if @i_tipo = 'Q'
      begin
            set rowcount 20
                select
                   'COD.'             = pv_provincia,
                   'PROVINCIA'        = pv_descripcion,
                   'COD.PAIS'         = pa_pais,
                   'PAIS '            = pa_descripcion
                   from  cobis..cl_provincia, cobis..cl_pais
                   where pa_pais    = pv_pais
                   and   pv_pais = @i_pais
                   and   pv_depart_pais = @i_departamento
                   and   pv_estado    = 'V'
                   and   (pv_descripcion like @i_valor or @i_valor=null)
                   and   (pv_provincia > convert(int,@i_provinc_alf) or @i_provinc_alf = null)
                   order by pv_provincia
                 if @@rowcount = 0
                 begin
                    exec cobis..sp_cerror
                      -- 'NO EXISTE DATO EN CATALOGO'
                      @t_debug   = @t_debug,
                      @t_file    = @t_file,
                      @t_from    = @w_sp_name,
                      @i_num     = @w_numerror
                    return 1
                 end
               set rowcount 0
            return 0
      end -- 'Q'

      if @i_tipo = 'O' --Originador
      begin
         set rowcount @i_rowcount
         set @w_pais = @i_pais

         if @w_pais is null
         begin
            select @w_pais = pa_smallint from cobis..cl_parametro where pa_nemonico = 'CP' and pa_producto = 'ADM'
         end

         if @i_modo = 0
         begin
            if exists ( select 1
                        from cobis..cl_catalogo C
                        inner join cobis..cl_tabla A on A.tabla = 'bcp_jerarquia_estructura_pais' and  C.tabla = A.codigo
                        where C.codigo = 'D' -- DEPARTAMENTO
                        and   C.valor  = 'S' )
            begin
               select 'CODIGO'  = pv_provincia,
                      'DETALLE' = pv_descripcion
              from   cobis..cl_provincia
               where  pv_depart_pais = @i_departamento
               and    pv_pais   = @w_pais
               and    pv_estado = 'V'
            end
            else
            begin
               select 'CODIGO'  = pv_provincia,
                      'DETALLE' = pv_descripcion
            from   cobis..cl_provincia
               where  pv_pais   = @w_pais
               and    pv_estado = 'V'
            end
         end -- @i_modo = 0
         set rowcount 0
         return 0
      end --@i_tipo = 'O'

   end -- @t_trn = 1550
   else
   begin
      exec cobis..sp_cerror
         -- 'NO CORRESPONDE CODIGO DE TRANSACCION'
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 151051
      return 1
   end
end -- @i_operacion = 'H'

GO
