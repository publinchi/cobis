/************************************************************************/
/*  Archivo:            ref_com.sp                                      */
/*  Stored procedure:   sp_ref_com                                      */
/*  Base de datos:      cobis                                           */
/*  Producto:           Clientes                                        */
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
/*              PROPOSITO                                               */
/*  Este programa procesa las transacciones del stored procedure        */
/*  Insercion de referencia comercial                                   */
/*  Actualizacion de referencia comercial                               */
/*  Borrado de referencia comercial                                     */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*  27/04/2021  BDU         CREACION SP                                 */
/*  16/09/2021  ACA         secuencial de referencia corregicción       */
/************************************************************************/

use cobis

go

if exists (select 1 from sysobjects where name = 'sp_ref_com')
   drop proc sp_ref_com
   
go

create proc sp_ref_com (

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
        @t_debug                char(1)         = 'N',
        @t_file                 varchar(10)     = null,
        @t_from                 varchar(32)     = null,
        @t_trn                  int             = null,
        @i_operacion            char(1),
        @i_ente                 int             = null,
        @i_referencia           tinyint         = null,
        @i_institucion          descripcion     = null,
        @i_fecha_ingr_en_inst   datetime        = null,
        @i_tipo_cifras          char(2)         = null,
        @i_numero_cifras        tinyint         = null,
        @i_calificacion         catalogo        = null,
        @i_observacion          varchar(254)    = null,
        @i_verificacion         char(1)         = 'S',
        @i_fecha_ver            datetime        = null,
        @o_secuencial           tinyint         = null   output)

as

declare @w_sp_name              varchar(32),
        @w_codigo               int,
        @w_return               int,
        @o_siguiente            tinyint,
        @w_institucion          descripcion,
        @w_fecha_ingr_en_inst   datetime,
        @w_tipo_cifras          char(2),
        @w_numero_cifras        tinyint,
        @w_fecha_registro       datetime,
        @w_fecha_modificacion   datetime,
        @w_fecha_ver            datetime,
        @w_verificacion         char(1),
        @w_calificacion         char(2),
        @w_vigencia             char(1),
        @w_observacion          varchar(254),
        @w_today                datetime,
        @w_num                  int,
        @w_param                int, 
        @w_diff                 int,
        @w_date                 datetime,
        @w_bloqueo              char(1),
        @v_institucion          descripcion,
        @v_fecha_ingr_en_inst   datetime,
        @v_tipo_cifras          char(2),
        @v_numero_cifras        tinyint,
        @v_fecha_registro       datetime,
        @v_fecha_modificacion   datetime,
        @v_fecha_ver            datetime,
        @v_verificacion         char(1),
        @v_calificacion         char(2),
        @v_vigencia             char(1),
        @v_observacion          varchar(254),
        @o_ente                 int,
        @o_cedruc               numero,
        @o_ennombre             descripcion,
        @o_institucion          descripcion,
        @o_fecha_ingr_en_inst   datetime,
        @o_tipo_cifras          char(2),
        @o_numero_cifras        tinyint,
        @o_fecha_registro       datetime,
        @o_fecha_modificacion   datetime,
        @o_fecha_ver            datetime,
        @o_verificacion         char(1),
        @o_calificacion         char(2),
        @o_observacion          varchar(254),
        @o_vigencia             char(1)

select @w_sp_name = 'sp_ref_com'
select @w_today = getdate(),

--144167 Siempre se verifica

@i_verificacion  = 'S',
@i_fecha_ver     = getdate()
if @i_operacion in ('I', 'U', 'D')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   if @i_ente is not null and @i_ente <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_ente
      if @w_bloqueo = 'S'
      begin
         exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720604
         return 1720604
      end
   end 
end
/** Insert **/

if @i_operacion = 'I'
begin

   /* Verificar que existe el ente */
   select @w_codigo = null
   from cl_ente
   where en_ente = @i_ente
   /* si no existe el ente, error */
   if @@rowcount = 0
   begin

      exec sp_cerror
         @t_debug   = @t_debug,
         @t_file        = @t_file,
         @t_from        = @w_sp_name,
         @i_num     = 1720079
      /* 'No existe ente'*/
      return 1
   end
   /* verificar que exista el tipo de referencia (C: comercial) */
   exec @w_return = cobis..sp_catalogo
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_tabla = 'cl_rtipo',
        @i_operacion = 'E',
        @i_codigo    = 'C'
   /* si no existe el tipo, error */
   if @w_return != 0
   begin
   
      exec sp_cerror
         @t_debug      = @t_debug,
         @t_file       = @t_file,
         @t_from       = @w_sp_name,
         @i_num        = 1720488
         /* 'No existe tipo de referencia comercial'*/
      return 1
   end
  /* verificar que exista el tipo de calificacion */
   
   exec @w_return = cobis..sp_catalogo
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_tabla = 'cl_posicion',
        @i_operacion = 'E',
        @i_codigo    = @i_calificacion
      /* si no existe el tipo, error */
   if @w_return != 0 and @i_calificacion != null
   begin
      exec sp_cerror
      @t_debug      = @t_debug,
      @t_file       = @t_file,
      @t_from       = @w_sp_name,
      @i_num        = 1720489
         /* 'No existe tipo de calificacion '*/
      return 1
   end
     /* verificar que exista el tipo de cifras */
   exec @w_return = cobis..sp_catalogo
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_tabla = 'cl_tcifras',
        @i_operacion = 'E',
        @i_codigo    = @i_tipo_cifras
      /* si no existe el tipo, error */
   if @w_return != 0
   begin
   
       exec sp_cerror
       @t_debug     = @t_debug,
       @t_file      = @t_file,
       @t_from      = @w_sp_name,
       @i_num       = 1720490
         /* 'No existe tipo de cifras'*/
       return 1
    end
   
    if @i_institucion = null
    begin
       exec sp_cerror
       @t_debug = @t_debug,
       @t_file      = @t_file,
       @t_from      = @w_sp_name,
       @i_num       = 1720491
         /* 'Falta nombre de la institucion '*/
       return 1
    end
   
   begin tran
        /* aumentar en uno el numero de referencias del ente */
      update cl_ente
      set en_referencia = isnull(en_referencia,0) + 1
      where en_ente = @i_ente
   
          /* si no se puede modificar, error */
   
      if @@error != 0
      begin
   
         exec sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720492
           /* 'Error en creacion de referencia '*/
         return 1
      end
          /* encontrar el nuevo secuencial para la referencia */
      select @o_siguiente = isnull(max(referencia),0) + 1
      from cl_comercial
      where ente = @i_ente
       /* insertar la nueva referencia */
      insert into cl_comercial(ente,                   referencia,         tipo,
                               tipo_cifras,            numero_cifras,      fecha_registro,
                               fecha_modificacion,     calificacion,       verificacion,
                               vigencia,               observacion,        institucion,
                               fecha_ingr_en,          funcionario,        fecha_ver)
                       values (@i_ente,                @o_siguiente,       'C',
                               @i_tipo_cifras,         @i_numero_cifras,   @w_today,
                               @w_today,               @i_calificacion,    @i_verificacion,
                               'S',                    @i_observacion,     @i_institucion,
                               @i_fecha_ingr_en_inst,  @s_user,            @i_fecha_ver)
   
          /* si no se puede insertar, error */
   
      if @@error != 0
      begin
         exec sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720492
           /* 'Error en creacion de referencia comercial'*/
         return 1
      end
   
      /* Transaccion servicios - cl_referencia */
   
      insert into ts_referencia  (secuencial,             tipo_transaccion,       clase,
                                  fecha,                  usuario,                terminal,
                                  srv,                    lsrv,                   ente,
                                  referencia,             tipo,                   tipo_cifras,
                                  numero_cifras,          calificacion,           verificacion,
                                  vigencia,               observacion,            fecha_registro,
                                  institucion,            fecha_ingr_en_inst,     fecha_ver)
                          values (@s_ssn,                 @t_trn,                 'N',
                                  @s_date,                @s_user,                @s_term,
                                  @s_srv,                 @s_lsrv,                @i_ente,
                                  @o_siguiente,           'C',                    @i_tipo_cifras,
                                  @i_numero_cifras,       @i_calificacion,        @i_verificacion,
                                  'S',                    @i_observacion,         getdate(),
                                  @i_institucion,         @i_fecha_ingr_en_inst,  @i_fecha_ver)
   
       /* si no se puede insertar, error */
   
      if @@error != 0
      begin

         exec sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720486
            /*'Error en creacion de transaccion de servicios'*/
         return 1
      end
   
   commit tran
   
   /* retornar el nuevo secuencial para la referencia */
   
   select @o_secuencial = @o_siguiente
   return 0
end

/** Update **/

if @i_operacion = 'U'
begin
   
     /* verificar que exista el tipo de referencia */
   exec @w_return = cobis..sp_catalogo
   
   @t_debug   = @t_debug,
   @t_file    = @t_file,
   @t_from    = @w_sp_name,
   @i_tabla   = 'cl_rtipo',
   @i_operacion   = 'E',
   @i_codigo  = 'C'

   if @w_return != 0
   begin
   exec sp_cerror
   
       @t_debug    = @t_debug,
       @t_file     = @t_file,
       @t_from     = @w_sp_name,
       @i_num      = 1720488
        /* 'No existe tipo de referencia '*/
       return 1
   end
   
    /* verificar que exista el tipo de calificacion */
   
   exec @w_return = cobis..sp_catalogo
   
    @t_debug   = @t_debug,
    @t_file    = @t_file,
    @t_from    = @w_sp_name,
    @i_tabla   = 'cl_posicion',
    @i_operacion   = 'E',
    @i_codigo  = @i_calificacion
   
   /* si no existe el tipo, error */
   
   if @w_return != 0 and @i_calificacion != null
   
   begin
   
      exec sp_cerror
   
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720489
   
       /* 'No existe tipo de calificacion '*/
   
      return 1
   
   end
   
   /* verificar que exista el tipo de cifras */
   exec @w_return = cobis..sp_catalogo
   @t_debug   = @t_debug,
   @t_file    = @t_file,
   @t_from    = @w_sp_name,
   @i_tabla   = 'cl_tcifras',
   @i_operacion   = 'E',
   @i_codigo  = @i_tipo_cifras
   
   /* si no existe el tipo, error */
   
   if @w_return != 0
   
   begin
   
    exec sp_cerror
   
        @t_debug    = @t_debug,
        @t_file     = @t_file,
        @t_from     = @w_sp_name,
        @i_num      = 1720490
   
         /* 'No existe tipo de cifras'*/
   
    return 1
   
    end
   
   
    if @i_institucion = null
   
   begin
   
    exec sp_cerror
   
        @t_debug    = @t_debug,
        @t_file     = @t_file,
        @t_from     = @w_sp_name,
        @i_num      = 1720491
   
         /* 'Falta nombre de la institucion '*/
   
    return 1
   
   end
   
    /* Control de campos a actualizar */
   
   select  @w_institucion          = institucion,
           @w_fecha_ingr_en_inst   = fecha_ingr_en,
           @w_tipo_cifras          = tipo_cifras,
           @w_numero_cifras        = numero_cifras,
           @w_calificacion         = calificacion,
           @w_observacion          = observacion,
           @w_verificacion         = verificacion,
           @w_fecha_ver            = fecha_ver,
           @w_fecha_modificacion   = fecha_modificacion,
           @w_vigencia             = vigencia
     from cl_comercial
    where ente = @i_ente
      and referencia = @i_referencia
   
    /* si no existe dato, error */
   
   if @@rowcount = 0
   
   begin
   
   exec sp_cerror
   
       @t_debug    = @t_debug,
       @t_file     = @t_file,
       @t_from     = @w_sp_name,
       @i_num      = 1720493
   
        /* 'No existe referencia '*/
   
       return 1
   
    end
   
   select  @v_institucion          = @w_institucion,
           @v_fecha_ingr_en_inst   = @w_fecha_ingr_en_inst,
           @v_tipo_cifras          = @w_tipo_cifras,
           @v_numero_cifras        = @w_numero_cifras,
           @v_calificacion         = @w_calificacion,
           @v_observacion          = @w_observacion,
           @v_verificacion         = @w_verificacion,
           @v_fecha_ver            = @w_fecha_ver,
           @v_fecha_modificacion   = @w_fecha_modificacion,
           @v_vigencia             = @w_vigencia
   
   if @w_institucion = @i_institucion
      select @w_institucion = null, @v_institucion = null
   else
      select @w_institucion = @i_institucion
   
   if @w_fecha_ingr_en_inst = @i_fecha_ingr_en_inst
      select @w_fecha_ingr_en_inst = null, @v_fecha_ingr_en_inst = null
   else
      select @w_fecha_ingr_en_inst = @i_fecha_ingr_en_inst
   
   if @w_tipo_cifras = @i_tipo_cifras
      select @w_tipo_cifras = null, @v_tipo_cifras = null
   else
      select @w_tipo_cifras = @i_tipo_cifras
   
   if @w_numero_cifras = @i_numero_cifras
      select @w_numero_cifras = null, @v_numero_cifras = null
   else
      select @w_numero_cifras = @i_numero_cifras
   
   if @w_calificacion = @i_calificacion
      select @w_calificacion = null, @v_calificacion = null
   else
      select @w_calificacion = @i_calificacion
   
   if @w_observacion = @i_observacion
      select @w_observacion = null, @v_observacion = null
   else
      select @w_observacion = @i_observacion
   
   if @w_verificacion = @i_verificacion
      select @w_verificacion = null--, @v_verificacion = null
   else
     select @w_verificacion = @i_verificacion
   
   if @w_fecha_ver  = @i_fecha_ver
      select @w_fecha_ver  = null--, @v_fecha_ver  = null
   else
     select @w_fecha_ver  = @i_fecha_ver
   
   
   
   begin tran
   
       /* modificar los datos actuales */
   
      update cl_comercial
   
      set institucion         = @i_institucion,
          tipo_cifras         = @i_tipo_cifras,
          numero_cifras       = @i_numero_cifras,
          calificacion        = @i_calificacion,
          verificacion        = @i_verificacion,
          fecha_ver           = @i_fecha_ver,
          fecha_modificacion  = @w_today,
          vigencia            = 'S',
          observacion         = @i_observacion,
          fecha_ingr_en  = @i_fecha_ingr_en_inst
      where  ente = @i_ente
      and    referencia = @i_referencia
   
          /* si no se puede modificar, error */
   
      if @@error != 0
   
      begin
   
          exec sp_cerror
          @t_debug    = @t_debug,
          @t_file     = @t_file,
          @t_from     = @w_sp_name,
          @i_num      = 1720494
   
            /* 'Error en actualizacion de referencia comercial'*/
   
          return 1
   
      end
   
      /*if @i_verificacion = "S"
   
      begin
   
          update  cl_comercial
          set     verificacion = @i_verificacion,
                  funcionario = @s_user
           where ente = @i_ente
             and referencia = @i_referencia
   
              /* si no se puede modificar, error */
   
          if @@error != 0
   
          begin
              exec sp_cerror
              @t_debug    = @t_debug,
              @t_file     = @t_file,
              @t_from     = @w_sp_name,
              @i_num      = 1720494
   
                /* 'Error en actualizacion de referencia comercial'*/
   
              return 1
          end
      end */
   
      /* Transaccion servicios - cl_comercial */
   
          insert into ts_referencia  (secuencial,         tipo_transaccion,   clase,
                                      fecha,              usuario,            terminal,
                                      srv,                lsrv,               ente,
                                      referencia,         tipo,               tipo_cifras,
                                      numero_cifras,      calificacion,       verificacion,
                                      vigencia,           observacion,        fecha_modificacion,
                                      institucion,        fecha_ver,          fecha_ingr_en_inst)
                              values (@s_ssn,             @t_trn,             'P',
                                      @s_date,            @s_user,            @s_term,
                                      @s_srv,             @s_lsrv,            @i_ente,
                                      @i_referencia,      'C',                @v_tipo_cifras,
                                      @v_numero_cifras,   @v_calificacion,    @v_verificacion,
                                      @v_vigencia,        @v_observacion,     @v_fecha_modificacion,
                                      @v_institucion,     @v_fecha_ver,       @v_fecha_ingr_en_inst)
   
          /* si no se puede insertar, error */
   
      if @@error != 0
      begin
   
         exec sp_cerror
   
           @t_debug    = @t_debug,
           @t_file     = @t_file,
           @t_from     = @w_sp_name,
           @i_num      = 1720486
   
           /* 'Error en creacion de transaccion de servicios'*/
   
         return 1
      end
   
      /* Transaccion servicios - cl_comercial */
   
       insert into ts_referencia (secuencial,             tipo_transaccion,   clase,
                                  fecha,                  usuario,            terminal,
                                  srv,                    lsrv,               ente,
                                  referencia,             tipo,               tipo_cifras,
                                  numero_cifras,          calificacion,       verificacion,
                                  vigencia,               observacion,        institucion,
                                  fecha_ver,              fecha_ingr_en_inst)
                          values (@s_ssn,                 @t_trn,             'A',
                                  @s_date,                @s_user,            @s_term,
                                  @s_srv,                 @s_lsrv,            @i_ente,
                                  @i_referencia,          'C',                @w_tipo_cifras,
                                  @w_numero_cifras,       @w_calificacion,    @i_verificacion,
                                  'S',                    @w_observacion,     @w_institucion,
                                  @i_fecha_ver,           @w_fecha_ingr_en_inst)
   
          /* si no se puede insertar, error */
      if @@error != 0
      begin
   
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 1720486
            /* 'Error en creacion de transaccion de servicios'*/
         return 1
      end
   commit tran
   return 0
end

/** Delete **/

if @i_operacion = 'D'
begin

    /* Captura de campos para transaccion de servicios */
   
   select  @w_institucion          = institucion,
           @w_fecha_ingr_en_inst   = fecha_ingr_en,
           @w_tipo_cifras          = tipo_cifras,
           @w_numero_cifras        = numero_cifras,
           @w_calificacion         = calificacion,
           @w_observacion          = observacion,
           @w_verificacion         = verificacion,
           @w_fecha_registro       = fecha_registro,
           @w_fecha_ver            = fecha_ver,
           @w_fecha_modificacion   = fecha_modificacion,
           @w_vigencia             = vigencia
   from cl_comercial
   where ente = @i_ente
   and referencia = @i_referencia
   
   /* si no existe referencia comercial, error */
   
   if @@rowcount = 0
   
   begin
   
      exec sp_cerror
      
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720493
      
        /* 'No existe referencia' */
      
      return 1
   
   end
   
   begin tran
   
    /* reducir en uno las referencias del ente */
   
      update cl_ente
   
         set en_referencia = en_referencia - 1
   
       where en_ente = @i_ente
   
      /* si no se puede modificar, error */
   
      if @@error != 0
   
      begin
   
         exec sp_cerror
         
             @t_debug    = @t_debug,
             @t_file     = @t_file,
             @t_from     = @w_sp_name,
             @i_num      = 1720495
         
            /* 'Error en disminucion de referencia '*/
         
         return 1
   
      end
   
      /* borrar la referencia */
   
      delete from cl_comercial
   
       where ente = @i_ente
   
         and referencia = @i_referencia
   
      /* si no se puede borrar, error */
   
      if @@error != 0
   
      begin
   
         exec sp_cerror
         
             @t_debug    = @t_debug,
             @t_file     = @t_file,
             @t_from     = @w_sp_name,
             @i_num      = 1720496
         
             /* 'Error en eliminacion de referencia '*/
         
         return 1
   
      end
   /*
     -- modificar en uno la secuencia de referencias 
   
      update cl_referencia
      set re_referencia = re_referencia - 1
      where re_ente = @i_ente
      and re_referencia > @i_referencia
      
       -- si no se puede modificar, error
       if @@error != 0
       begin
      
          exec sp_cerror
              @t_debug    = @t_debug,
              @t_file     = @t_file,
              @t_from     = @w_sp_name,
              @i_num      = 1720496
              -- 'Error en eliminacion de referencia '
          return 1
       end
    
    */
       /* Transaccion servicios - cl_referencia */
       insert into ts_referencia  (secuencial,         tipo_transaccion,   clase,
                                   fecha,              usuario,            terminal,
                                   srv,                lsrv,               ente,
                                   referencia,         tipo,               tipo_cifras,
                                   numero_cifras,      calificacion,       verificacion,
                                   vigencia,           observacion,        fecha_registro,
                                   institucion,        fecha_ver,          fecha_ingr_en_inst,
                                   fecha_modificacion)
                           values (@s_ssn,             @t_trn,             'B',
                                   @s_date,            @s_user,            @s_term,
                                   @s_srv,             @s_lsrv,            @i_ente,
                                   @i_referencia,      'C',                @w_tipo_cifras,
                                   @w_numero_cifras,   @w_calificacion,    @w_verificacion,
                                   @w_vigencia,        @w_observacion,     @w_fecha_registro,
                                   @w_institucion,     @w_fecha_ver,       @w_fecha_ingr_en_inst,
                                   @w_fecha_modificacion)
      
         /* si no se puede insertar, error */
       if @@error != 0
       begin
     
          exec sp_cerror
          @t_debug    = @t_debug,
          @t_file     = @t_file,
          @t_from     = @w_sp_name,
          @i_num      = 1720486
            /* 'Error en creacion de transaccion de servicios'*/
          return 1
       end
   commit tran
   return 0
   
end

if @i_operacion = 'S'
begin
   
   select
      ente,
      referencia,
      tipo,
      tipo_cifras,
      numero_cifras,
      fecha_ingr_en,
      calificacion,
      verificacion,
      observacion,
      institucion 
   from cl_comercial
   where ente = @i_ente
   
   return 0
end

go
