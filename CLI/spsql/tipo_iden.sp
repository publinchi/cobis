/************************************************************************/
/*  Archivo:                         tipo_iden.sp                       */
/*  Stored procedure:                sp_tipo_iden                       */
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
/*      29/06/20         FSAP         Estandarizacion de Clientes       */
/************************************************************************/
use cobis
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select * from sysobjects where name = 'sp_tipo_iden')
   drop proc sp_tipo_iden
go
create procedure sp_tipo_iden(
   @s_ssn            int         = null,
   @s_user           login       = null,
   @s_term           varchar(32) = null,
   @s_date           datetime    = null,
   @s_sesn           int         = null,
   @s_culture        varchar(10) = null,
   @s_srv            varchar(30) = null,
   @s_lsrv           varchar(30) = null,
   @s_ofi            smallint    = null,
   @s_rol            smallint    = NULL,
   @s_org_err        char(1)     = NULL,
   @s_error          int         = NULL,
   @s_sev            tinyint     = NULL,
   @s_msg            descripcion = NULL,
   @s_org            char(1)     = NULL,
   @t_debug          char(1)     = 'N',
   @t_file           varchar(10) = null,
   @t_from           varchar(32) = null,
   @t_trn            int         = null,
   
   @t_show_version bit  = 0
   ,   --* Mostrar la version del programa
   @i_operacion      char(1),             -- Opcion con la que se ejecuta el programa
   @i_tipo           char(1)     = null,  -- Tipo de busqueda
   @i_modo           int         = null,  -- Modo de consulta
   @i_valor1         char(10)    = null,  -- Criterios de busqueda
   @i_valor2         char(10)    = null,  -- Criterios de busqueda
   @i_tabla          varchar(30) = null,  -- Identifica la tabla de catalogo a ser utilizada.  
   @i_codigo         char(4)     = null,  --EAN001
   @i_descripcion    varchar(60) = null,
   @i_mascara        varchar(20) = null,
   @i_tipoper        char(1)     = NULL,
   @i_provincia      char(1)     = 'N',  --Campo no se usa se mantiene por compatiblidad
   @i_aperrapida     char(1)     = NULL,
   @i_bloquea        char(1)     = 'N',  --Campo no se usa se mantiene por compatiblidad
   @i_nacionalidad   varchar(15) = NULL,
   @i_digito         char(1)     = NULL,
   @i_estado         char(1)     = NULL,
   @i_secuencial     int         = NULL,
   @i_tpersona       char(1)     = NULL,
   @i_desc_corta     varchar(5)  = NULL,
   @i_compuesto      char(1)     = NULL,
   @i_nro_compuesto  tinyint     = NULL,
   @i_adicional      tinyint     = NULL,
   @i_creacion       char(1)     = NULL,
   @i_habilitado_mis char(1)     = NULL,
   @i_habilitado_usu char(1)     = NULL,
   @i_prefijo        varchar(10) = NULL,
   @i_subfijo        varchar(10) = NULL,
   @i_codigo_id      varchar(10) = NULL,
   @i_valor          varchar(10) = NULL,
   @o_secuencial     int         = NULL out

)
as
declare @w_today   datetime,
  @w_sp_name       varchar(32),
  @w_sp_msg        varchar(132),
  @w_return        int,
  @w_cod_tabla     smallint,
  @w_cmdtransrv    descripcion,
  @w_num_nodos     smallint, 
  @w_contador      smallint,
  @w_nt_nombre     varchar(40),
  @w_clave         int,
  @w_titulo        descripcion,
  @w_siguiente     int,
  @o_tidenti       char(4),           --EAN001
  @o_nidenti       varchar(60),
  @o_mascara       varchar(20),
  @o_tpersona      char(1),
  @o_valprov       char(1),
  @o_aperapid      char(1),
  @o_bloquea       char(1),
  @o_nacional      varchar(15),
  @o_digito        char(1),
  --Variables para informacion actual
  @w_codigo         char(4),  
  @w_descripcion    varchar(60),
  @w_mascara        varchar(20),
  @w_tipoper        char(1),
  @w_aperrapida     char(1),
  @w_nacionalidad   varchar(15),
  @w_digito         char(1),
  @w_estado         char(1),
  @w_desc_corta     varchar(5),
  @w_compuesto      char(1),
  @w_nro_compuesto  tinyint,
  @w_adicional      tinyint,
  @w_creacion       char(1),
  @w_habilitado_mis char(1),
  @w_habilitado_usu char(1),
  @w_prefijo        varchar(10),
  @w_subfijo        varchar(10),
  --Variables para informacion anterior
  @v_codigo         char(4),  
  @v_descripcion    varchar(60),
  @v_mascara        varchar(20),
  @v_tipoper        char(1),
  @v_aperrapida     char(1),
  @v_nacionalidad   varchar(15),
  @v_digito         char(1),
  @v_estado         char(1),
  @v_desc_corta     varchar(5),
  @v_compuesto      char(1),
  @v_nro_compuesto  tinyint,
  @v_adicional      tinyint,
  @v_creacion       char(1),
  @v_habilitado_mis char(1),
  @v_habilitado_usu char(1),
  @v_prefijo        varchar(10),
  @v_subfijo        varchar(10)  



select @w_today = @s_date
select @w_sp_name = 'sp_tipo_iden'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

/*Consulta para catalogos */
if @t_trn not in(172048,172049,172050,172051)
begin
   exec sp_cerror
      @t_debug      = @t_debug,
      @t_file       = @t_file,
      @t_from       = @w_sp_name,
      @i_num        = 1720075
      /*  'No corresponde codigo de transaccion' */
   return 1
end


if @i_operacion = 'S' 
begin
  if @t_trn = 172050
  begin
    if @i_tipo='C'
    begin      
      if @i_modo=0
      begin
        set rowcount 20
        select 'SECUENCIAL'               = td_secuencial,
               'TIPO IDENTIFICACION'      = td_codigo,
               'NOMBRE TIPO IDENTIDAD'    = td_descripcion,
               'MASCARA'                  = td_mascara,
               'TIPO PERSONA'             = td_tipoper,               
               'PERMITIR APERTURA RAPIDA' = td_aperrapida,               
               'NACIONALIDAD'             = td_nacionalidad,
               'MANEJA DIGITO'            = td_digito,
               'ESTADO'                   = td_estado,
               'DESCRIPCION CORTA'        = td_desc_corta,
               'COMPUESTO'                = td_compuesto,
               'NRO CAMPOS COMPUESTOS'    = td_nro_compuesto,
               'CAMPO ADICIONAL'          = td_adicional,
               'PERMITE CREACION'         = td_creacion,
               'HABILITADO CLIENTES'      = td_habilitado_mis,
               'HABILITADO USUARIOS'      = td_habilitado_usu,
               'PREFIJO'                  = td_prefijo,
               'SUBFIJO'                  = td_subfijo
         from cl_tipo_documento
     where (td_codigo   = @i_codigo or @i_codigo is null)
          and (Upper(td_descripcion)  like @i_descripcion +'%' or @i_descripcion is null) -- Inc 65485
        order by td_secuencial

        if @@rowcount =0
        begin
          /* No existe tipos de identificacion*/
          exec cobis..sp_cerror 
                @t_debug= @t_debug,
                @t_file = @t_file,     
                @t_from = @w_sp_name,
                @i_num  = 1720323
           return 1
        end
      end --modo=0

      if @i_modo=1
      begin
        set rowcount 20
        select 'SECUENCIAL'               = td_secuencial,
               'TIPO IDENTIFICACION'      = td_codigo,
               'NOMBRE TIPO IDENTIDAD'    = td_descripcion,
               'MASCARA'                  = td_mascara,
               'TIPO PERSONA'             = td_tipoper,               
               'PERMITIR APERTURA RAPIDA' = td_aperrapida,               
               'NACIONALIDAD'             = td_nacionalidad,
               'MANEJA DIGITO'            = td_digito,
               'ESTADO'                   = td_estado,
               'DESCRIPCION CORTA'        = td_desc_corta,
               'COMPUESTO'                = td_compuesto,
               'NRO CAMPOS COMPUESTOS'    = td_nro_compuesto,
               'CAMPO ADICIONAL'          = td_adicional,
               'PERMITE CREACION'         = td_creacion,
               'HABILITADO CLIENTES'      = td_habilitado_mis,
               'HABILITADO USUARIOS'      = td_habilitado_usu,
               'PREFIJO'                  = td_prefijo,
               'SUBFIJO'                  = td_subfijo
         from cl_tipo_documento
        where td_secuencial > @i_secuencial
        order by td_secuencial

        if @@rowcount =0
        begin
          /* No existe tipos de identificacion*/
          exec cobis..sp_cerror 
                @t_debug= @t_debug,
                @t_file = @t_file,     
                @t_from = @w_sp_name,
                @i_num  = 1720323
          return 1
        end
      end --modo=1
    end  --@i_tipo='C'
  end -- trn 172050
   
  if @i_tipo='D'
  begin        
     select td_descripcion   
       from cl_tipo_documento
      where td_estado      = 'V'
        and td_secuencial  = @i_secuencial
     if @@rowcount =0
     begin
        /* No existe empresa*/
        exec cobis..sp_cerror 
             @t_debug= @t_debug,
             @t_file = @t_file,     
             @t_from = @w_sp_name,
             @i_num  = 1720323
        return 1
     end

     return 0
  end 


  if @i_tipo='B'
  begin  
     if @i_tipoper is not null
     begin
        select 'SECUENCIAL'               = td_secuencial,
               'TIPO IDENTIFICACION'      = td_codigo,
               'NOMBRE TIPO IDENTIDAD'    = td_descripcion,
               'MASCARA'                  = td_mascara,
               'TIPO PERSONA'             = td_tipoper,
               'VALIDA PROVINCIA'         = td_provincia,
               'PERMITIR APERTURA RAPIDA' = td_aperrapida,
               'BLOQUEA ENTE'             = td_bloquea,
               'NACIONALIDAD'             = td_nacionalidad,
               'MANEJA DIGITO'            = td_digito,
               'ESTADO'                   = td_estado,
        'COMPUESTO'               = td_compuesto,
        'No.COMPUESTO'            = td_nro_compuesto,
        'No.ADICIONAL'            = td_adicional,
        'CREACION'                = td_creacion,
        'HABILITADO MIS'          =td_habilitado_mis, 
        'HABILITADO USU'          =td_habilitado_usu, 
        'PREFIJO'                 =td_prefijo,
        'SUFIJO'                  =td_subfijo          
          from cl_tipo_documento
         where td_estado  = 'V'
           and td_codigo  = @i_codigo
           and td_tipoper = @i_tipoper
        if @@rowcount =0
        begin
           /* No existe Tipo de Identificacion*/
           exec cobis..sp_cerror 
                @t_debug= @t_debug,
                @t_file = @t_file,     
                @t_from = @w_sp_name,
                @i_num  = 1720323
           return 1
        end
        return 0
     end
     else
     begin
        select 'SECUENCIAL'               = td_secuencial,
               'TIPO IDENTIFICACION'      = td_codigo,
               'NOMBRE TIPO IDENTIDAD'    = td_descripcion,
               'MASCARA'                  = td_mascara,
               'TIPO PERSONA'             = td_tipoper,
               'VALIDA PROVINCIA'         = td_provincia,
               'PERMITIR APERTURA RAPIDA' = td_aperrapida,
               'BLOQUEA ENTE'             = td_bloquea,
               'NACIONALIDAD'             = td_nacionalidad,
               'MANEJA DIGITO'            = td_digito,
               'ESTADO'                   = td_estado,
               'COMPUESTO'               = td_compuesto,
               'No.COMPUESTO'            = td_nro_compuesto,
               'No.ADICIONAL'            = td_adicional,
               'CREACION'                = td_creacion,
               'HABILITADO MIS'          =td_habilitado_mis, 
               'HABILITADO USU'          =td_habilitado_usu, 
               'PREFIJO'                 =td_prefijo,
               'SUFIJO'                  =td_subfijo           
          from cl_tipo_documento
         where td_estado = 'V'
           and td_codigo = @i_codigo          
        if @@rowcount =0
        begin
           /* No existe Tipo de Identificacion*/
           exec cobis..sp_cerror 
                @t_debug= @t_debug,
                @t_file = @t_file,     
                @t_from = @w_sp_name,
                @i_num  = 1720323
           return 1
        end
        return 0
     end
  end 

  /* Busqueda por descripcion para catalogo tipo de documento */
  if @i_tipo='O'
  begin        
     select 'SECUENCIAL'               = td_secuencial,
            'TIPO IDENTIFICACION'      = td_codigo,
            'NOMBRE TIPO IDENTIDAD'    = td_descripcion,
            'MASCARA'                  = td_mascara,
            'TIPO PERSONA'             = td_tipoper,
            'VALIDA PROVINCIA'         = td_provincia,
            'PERMITIR APERTURA RAPIDA' = td_aperrapida,
            'BLOQUEA ENTE'             = td_bloquea,
            'NACIONALIDAD'             = td_nacionalidad,
            'MANEJA DIGITO'            = td_digito,
            'ESTADO'                   = td_estado
       from cl_tipo_documento
      where td_estado = 'V'
        and td_descripcion like @i_descripcion 
    
     if @@rowcount =0
     begin
        /* No existe empresa*/
        exec cobis..sp_cerror 
             @t_debug= @t_debug,
             @t_file = @t_file,     
             @t_from = @w_sp_name,
             @i_num  = 1720323
        return 1
     end

     return 0
  end--@i_tipo 'O'



  if @i_tipo='V'
  begin        
     select td_descripcion   
     from cl_tipo_documento
     where td_codigo = @i_codigo
     and   td_secuencial   = @i_secuencial
     and   td_estado     = 'V'
     
     
     if @@rowcount =0
     begin
        /* No existe empresa*/
        exec cobis..sp_cerror 
             @t_debug = @t_debug,
             @t_file  = @t_file,     
             @t_from  = @w_sp_name,
             @i_num   = 1720323
        return 1
     end

     return 0
  end 
  
  /* recupera descripcion corta de acuerdo a codigo*/
  if @i_tipo='Q'
  begin
  select 'DES. CORTA' = td_desc_corta,
         td_descripcion
       from cl_tipo_documento
      where td_codigo=@i_codigo
  end
  
  
end

If @i_operacion = 'I' 
begin
  if @t_trn = 172048
  begin
    
    if exists ( select td_codigo  from cl_tipo_documento
                 where td_codigo = @i_codigo )
    begin
       /*  Ya existe codigo para esa tabla  */
       exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 101104
       return 1
    end

    select @w_siguiente = isnull(max(td_secuencial),0) + 1
      from cobis..cl_tipo_documento
    if @@rowcount = 0
    begin
       /* No existe tabla */
       exec sp_cerror 
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 1720323 
       return 1
    end

    select @o_secuencial = @w_siguiente
   
    select @w_cod_tabla = codigo        
      from cl_tabla
     where tabla = 'cl_tipo_documento'
    if @@rowcount = 0
    begin
       /* No existe tabla */
       exec sp_cerror 
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 1720323 
       return 1
    end

    begin tran             
      insert into cl_tipo_documento
               (td_secuencial, td_codigo,         td_descripcion,
                td_mascara,    td_tipoper,        td_provincia,
                td_aperrapida, td_bloquea,        td_nacionalidad,
                td_digito,     td_estado,         td_desc_corta,
                td_compuesto,  td_nro_compuesto,  td_adicional,
                td_creacion,   td_habilitado_mis, td_habilitado_usu,
                td_prefijo,    td_subfijo)
         values(@w_siguiente,  @i_codigo,         @i_descripcion,
                @i_mascara,    @i_tipoper,        @i_provincia,
                @i_aperrapida, @i_bloquea,        @i_nacionalidad,
                @i_digito,     @i_estado,         @i_desc_corta,
                @i_compuesto,  @i_nro_compuesto,  @i_adicional,
                @i_creacion,   @i_habilitado_mis, @i_habilitado_usu,
                @i_prefijo,    @i_subfijo)

      if @@error != 0
      begin
         /* Error en creacion de catalogo */
         exec sp_cerror 
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 1720272
         return 1
      end

      insert into ts_tipo_documento
               (secuencia, tipo_transaccion, clase,          fecha,
                oficina_s, usuario,          terminal_s,     srv, 
                lsrv,      codigo,           descripcion,    mascara,
                tipooper,  aperrapida,       nacionalidad,   digito,
                estado,    desc_corta,       compuesto,      nro_compuesto,
                adicional, creacion,         habilitado_mis, habilitado_usu,
                prefijo,   subfijo, hora)
        values (@s_ssn,       172048,          'N',               @s_date,
                @s_ofi,       @s_user,       @s_term,           @s_srv,
                @s_lsrv,      @i_codigo,     @i_descripcion,    @i_mascara,    
                @i_tipoper,   @i_aperrapida, @i_nacionalidad,   @i_digito,     
                @i_estado,    @i_desc_corta, @i_compuesto,      @i_nro_compuesto,  
                @i_adicional, @i_creacion,   @i_habilitado_mis, @i_habilitado_usu,
                @i_prefijo,   @i_subfijo, getdate())

      if @@error != 0
      begin
        -- 'Error en creacion de transaccion de servicio'
        exec sp_cerror
             @t_debug    = @t_debug,
             @t_file     = @t_file,
             @t_from     = @w_sp_name,
             @i_num      = 1720049      
        return 1
      end
    commit tran       
    
  end --@t_trn
end  --@i_operacion


if @i_operacion = 'U' 
begin
   if @t_trn = 172049
   begin               
      select @w_codigo         = td_codigo,
             @w_descripcion    = td_descripcion,
             @w_mascara        = td_mascara,
             @w_tipoper        = td_tipoper,
             @w_aperrapida     = td_aperrapida,
             @w_nacionalidad   = td_nacionalidad,
             @w_digito         = td_digito,
             @w_estado         = td_estado,
             @w_desc_corta     = td_desc_corta,
             @w_compuesto      = td_compuesto,
             @w_nro_compuesto  = td_nro_compuesto,
             @w_adicional      = td_adicional,
             @w_creacion       = td_creacion,
             @w_habilitado_mis = td_habilitado_mis,
             @w_habilitado_usu = td_habilitado_usu,
             @w_prefijo        = td_prefijo,
             @w_subfijo        = td_subfijo
       from cl_tipo_documento
      where td_secuencial = @i_secuencial

      if @@rowcount != 1
      begin
         --No existe Tipo de Identificacion
         exec sp_cerror             
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 1720323
         return 1
      end

      --GUARDAR LOS DATOS ANTERIORES
      select @v_codigo         = @w_codigo,
             @v_descripcion    = @w_descripcion,
             @v_mascara        = @w_mascara,
             @v_tipoper        = @w_tipoper,
             @v_aperrapida     = @w_aperrapida,
             @v_nacionalidad   = @w_nacionalidad,
             @v_digito         = @w_digito,
             @v_estado         = @w_estado,
             @v_desc_corta     = @w_desc_corta,
             @v_compuesto      = @w_compuesto,
             @v_nro_compuesto  = @w_nro_compuesto,
             @v_adicional      = @w_adicional,
             @v_creacion       = @w_creacion,
             @v_habilitado_mis = @w_habilitado_mis,
             @v_habilitado_usu = @w_habilitado_usu,
             @v_prefijo        = @w_prefijo,
             @v_subfijo        = @w_subfijo

      if @w_codigo = @i_codigo
         select @w_codigo = null, @v_codigo = null
      else 
         select @w_codigo = @i_codigo

      if @w_descripcion = @i_descripcion
         select @w_descripcion = null, @v_descripcion = null
      else 
         select @w_descripcion = @i_descripcion

      if @w_mascara = @i_mascara
         select @w_mascara = null, @v_mascara = null
      else 
         select @w_mascara = @i_mascara

      if @w_tipoper = @i_tipoper
         select @w_tipoper = null, @v_tipoper = null
      else 
         select @w_tipoper = @i_tipoper

      if @w_aperrapida = @i_aperrapida
         select @w_aperrapida = null, @v_aperrapida = null
      else 
         select @w_aperrapida = @i_aperrapida

      if @w_nacionalidad = @i_nacionalidad
         select @w_nacionalidad = null, @v_nacionalidad = null
      else 
         select @w_nacionalidad = @i_nacionalidad

      if @w_digito = @i_digito
         select @w_digito = null, @v_digito = null
      else 
         select @w_digito = @i_digito

      if @w_estado = @i_estado
         select @w_estado = null, @v_estado = null
      else 
         select @w_estado = @i_estado

      if @w_desc_corta = @i_desc_corta
         select @w_desc_corta = null, @v_desc_corta = null
      else 
         select @w_desc_corta = @i_desc_corta

      if @w_compuesto = @i_compuesto
         select @w_compuesto = null, @v_compuesto = null
      else 
         select @w_compuesto = @i_compuesto

      if @w_nro_compuesto = @i_nro_compuesto
         select @w_nro_compuesto = null, @v_nro_compuesto = null
      else 
         select @w_nro_compuesto = @i_nro_compuesto

      if @w_adicional = @i_adicional
         select @w_adicional = null, @v_adicional = null
      else 
         select @w_adicional = @i_adicional

      if @w_creacion = @i_creacion
         select @w_creacion = null, @v_creacion = null
      else 
         select @w_creacion = @i_creacion

      if @w_habilitado_mis = @i_habilitado_mis
         select @w_habilitado_mis = null, @v_habilitado_mis = null
      else 
         select @w_habilitado_mis = @i_habilitado_mis

      if @w_habilitado_usu = @i_habilitado_usu
         select @w_habilitado_usu = null, @v_habilitado_usu = null
      else 
         select @w_habilitado_usu = @i_habilitado_usu

      if @w_prefijo = @i_prefijo
         select @w_prefijo = null, @v_prefijo = null
      else 
         select @w_prefijo = @i_prefijo

      if @w_subfijo = @i_subfijo
         select @w_subfijo = null, @v_subfijo = null
      else 
         select @w_subfijo = @i_subfijo

      begin tran
         update cl_tipo_documento
         set td_codigo         = @i_codigo,
             td_descripcion    = @i_descripcion,
             td_mascara        = @i_mascara,
             td_tipoper        = @i_tipoper,
             td_provincia      = @i_provincia,
             td_aperrapida     = @i_aperrapida,
             td_bloquea        = @i_bloquea,
             td_nacionalidad   = @i_nacionalidad,
             td_digito         = @i_digito,
             td_estado         = @i_estado,
             td_desc_corta     = @i_desc_corta,
             td_compuesto      = @i_compuesto,
             td_nro_compuesto  = @i_nro_compuesto,
             td_adicional      = @i_adicional,
             td_creacion       = @i_creacion,
             td_habilitado_mis = @i_habilitado_mis,
             td_habilitado_usu = @i_habilitado_usu,
             td_prefijo        = @i_prefijo,
             td_subfijo        = @i_subfijo
         where td_secuencial = @i_secuencial
         
         if @@error <> 0
         begin
            /* Error en actualizacion de catalogo */
            exec sp_cerror 
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 1720273
            return 1
         end
         
         --Registro de informacion anterior
         insert into ts_tipo_documento
               (secuencia, tipo_transaccion, clase,          fecha,
                oficina_s, usuario,          terminal_s,     srv, 
                lsrv,      codigo,           descripcion,    mascara,
                tipooper,  aperrapida,       nacionalidad,   digito,
                estado,    desc_corta,       compuesto,      nro_compuesto,
                adicional, creacion,         habilitado_mis, habilitado_usu,
                prefijo,   subfijo, hora)
        values (@s_ssn,       172048,          'P',               @s_date,
                @s_ofi,       @s_user,       @s_term,           @s_srv,
                @s_lsrv,      @v_codigo,     @v_descripcion,    @v_mascara,    
                @v_tipoper,   @v_aperrapida, @v_nacionalidad,   @v_digito,     
                @v_estado,    @v_desc_corta, @v_compuesto,      @v_nro_compuesto,  
                @v_adicional, @v_creacion,   @v_habilitado_mis, @v_habilitado_usu,
                @v_prefijo,   @v_subfijo, getdate())

         if @@error <> 0
         begin
           -- 'Error en creacion de transaccion de servicio'
           exec sp_cerror
                @t_debug    = @t_debug,
                @t_file     = @t_file,
                @t_from     = @w_sp_name,
                @i_num      = 1720049      
           return 1
         end

         --Registro de informacion actual
         insert into ts_tipo_documento
                  (secuencia, tipo_transaccion, clase,          fecha,
                   oficina_s, usuario,          terminal_s,     srv, 
                   lsrv,      codigo,           descripcion,    mascara,
                   tipooper,  aperrapida,       nacionalidad,   digito,
                   estado,    desc_corta,       compuesto,      nro_compuesto,
                   adicional, creacion,         habilitado_mis, habilitado_usu,
                   prefijo,   subfijo,hora)
           values (@s_ssn,       172048,          'A',               @s_date,
                   @s_ofi,       @s_user,       @s_term,           @s_srv,
                   @s_lsrv,      @w_codigo,     @w_descripcion,    @w_mascara,    
                   @w_tipoper,   @w_aperrapida, @w_nacionalidad,   @w_digito,     
                   @w_estado,    @w_desc_corta, @w_compuesto,      @w_nro_compuesto,  
                   @w_adicional, @w_creacion,   @w_habilitado_mis, @w_habilitado_usu,
                   @w_prefijo,   @w_subfijo,  getdate())
         
         if @@error <> 0
         begin
           -- 'Error en creacion de transaccion de servicio'
           exec sp_cerror
                @t_debug    = @t_debug,
                @t_file     = @t_file,
                @t_from     = @w_sp_name,
                @i_num      = 1720049      
           return 1
         end
      commit tran 
   end --@t_trn
end  --@i_operacion


if @t_trn = 172051
begin
   if @i_operacion = 'H' 
   begin     
   set rowcount 20
         if @i_tipo = 'B' 
         begin
        select 'TIPO ID.'                 = td_codigo,
                   'NOMBRE TIPO ID.'          = td_descripcion,
                   'MASCARA'                  = td_mascara,
                   'TIPO PERSONA'             = td_tipoper,
                   'VALIDA PROVINCIA'         = td_provincia,
                   'PERMITIR APERTURA RAPIDA' = td_aperrapida,
                   'BLOQUEA ENTE'             = td_bloquea,
                   'NACIONALIDAD'             = td_nacionalidad,
                   'MANEJA DIGITO'            = td_digito
              from cl_tipo_documento
            where td_tipoper = isnull(@i_tpersona, td_tipoper )
              and td_estado  = 'V'
              and td_codigo  <> 'SP'
              and td_codigo  <> 'SC'
        and td_descripcion like @i_valor
        and (td_codigo  > isnull(@i_codigo_id,'') or isnull(@i_codigo_id, '') is null)
            order by td_codigo
      
         end
         else    
            select 'TIPO ID.'                 = td_codigo,
                   'NOMBRE TIPO ID.'          = td_descripcion,
                   'MASCARA'                  = td_mascara,
                   'TIPO PERSONA'             = td_tipoper,
                   'VALIDA PROVINCIA'         = td_provincia,
                   'PERMITIR APERTURA RAPIDA' = td_aperrapida,
                   'BLOQUEA ENTE'             = td_bloquea,
                   'NACIONALIDAD'             = td_nacionalidad,
                   'MANEJA DIGITO'            = td_digito
              from cl_tipo_documento
             where td_tipoper = isnull(@i_tpersona, td_tipoper )
               and td_estado  = 'V'
               and td_codigo  <> 'SP'
               and td_codigo  <> 'SC'
         --and (td_codigo  > @i_codigo_id or @i_codigo_id = null)
               and (td_codigo  > isnull(@i_codigo_id,'') or isnull(@i_codigo_id, '') is null)
             order by td_codigo
   set rowcount 0      
   end  --@i_operacion

   if @i_operacion = 'A' 
   begin
      select 'TIPO ID.'                 = td_codigo,
             'NOMBRE TIPO ID.'          = td_descripcion,
             'MASCARA'                  = td_mascara,
             'TIPO PERSONA'             = td_tipoper,
             'VALIDA PROVINCIA'         = td_provincia,
             'PERMITIR APERTURA RAPIDA' = td_aperrapida,
             'BLOQUEA ENTE'             = td_bloquea,
             'NACIONALIDAD'             = td_nacionalidad,
             'MANEJA DIGITO'            = td_digito
        from cl_tipo_documento
       where td_tipoper    = @i_tpersona
         and td_aperrapida = @i_aperrapida
         and td_estado     = 'V'
       order by td_codigo
   end  --@i_operacion

   if @i_operacion = 'M' 
   begin
      select 'TIPO ID.'                 = td_codigo,
             'NOMBRE TIPO ID.'          = td_descripcion,
             'MASCARA'                  = td_mascara,
             'TIPO PERSONA'             = td_tipoper,
             'VALIDA PROVINCIA'         = td_provincia,
             'PERMITIR APERTURA RAPIDA' = td_aperrapida,
             'BLOQUEA ENTE'             = td_bloquea,
             'NACIONALIDAD'             = td_nacionalidad,
             'MANEJA DIGITO'            = td_digito
        from cl_tipo_documento
       where td_tipoper = @i_tpersona
         and td_estado  = 'V'
       order by td_codigo
   end  --@i_operacion

   if @i_operacion = 'J' 
   begin
      select 'TIPO ID.'                 = td_codigo,
             'NOMBRE TIPO ID.'          = td_descripcion,
             'MASCARA'                  = td_mascara,
             'TIPO PERSONA'             = td_tipoper,
             'VALIDA PROVINCIA'         = td_provincia,
             'PERMITIR APERTURA RAPIDA' = td_aperrapida,
             'BLOQUEA ENTE'             = td_bloquea,
             'NACIONALIDAD'             = td_nacionalidad,
             'MANEJA DIGITO'            = td_digito
        from cl_tipo_documento
       where td_estado  = 'V'
         and td_codigo <> 'SP'
         and td_codigo <> 'SC'
       order by td_codigo
   end  --@i_operacion

   if @i_operacion = 'P'  --Planilla
   begin

      if @i_tipo = 'A'  
      begin
         select 'TIPO ID.'                 = td_codigo,
                'NOMBRE TIPO ID.'          = td_descripcion,
                'MASCARA'                  = td_mascara,
                'TIPO PERSONA'             = td_tipoper,
                'VALIDA PROVINCIA'         = td_provincia,
                'PERMITIR APERTURA RAPIDA' = td_aperrapida,
                'BLOQUEA ENTE'             = td_bloquea,
                'NACIONALIDAD'             = td_nacionalidad,
                'MANEJA DIGITO'            = td_digito
           from cl_tipo_documento
          where td_tipoper     = @i_tpersona
            and (td_aperrapida = @i_aperrapida or td_codigo='P')
            and td_estado      = 'V'
          order by td_codigo
      end

      if @i_tipo='V'
      begin        
         select 'SECUENCIAL'               = td_secuencial,
                'TIPO IDENTIFICACI¢N'      = td_codigo,
                'NOMBRE TIPO IDENTIDAD'    = td_descripcion,
                'MASCARA'                  = td_mascara,
                'TIPO PERSONA'             = td_tipoper,
                'VALIDA PROVINCIA'         = td_provincia,
                'PERMITIR APERTURA RAPIDA' = td_aperrapida,
                'BLOQUEA ENTE'             = td_bloquea,
                'NACIONALIDAD'             = td_nacionalidad,
                'MANEJA DIGITO'            = td_digito,
                'ESTADO'                   = td_estado
           from cl_tipo_documento
          where td_estado = 'V'
            and td_codigo = @i_codigo
         if @@rowcount =0
         begin
            /* No existe Tipo de Identificacion */
            exec cobis..sp_cerror 
                 @t_debug= @t_debug,
                 @t_file = @t_file,     
                 @t_from = @w_sp_name,
                 @i_num  = 1720323
            return 1
         end
         return 0
      end 
   end  --@i_operacion
end --@t_trn
return 0
GO
--sp_procxmode 'dbo.sp_tipo_iden', 'Unchained'
GO


