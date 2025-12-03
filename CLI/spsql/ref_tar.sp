/************************************************************************/
/*  Archivo:            ref_tar.sp                                      */
/*  Stored procedure:   sp_ref_tar                                      */
/*  Base de datos:      cobis                                           */
/*  Producto: Clientes                                                  */
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
/*  Insercion de referencia de tarjeta                                  */
/*  Actualizacion de referencia de tarjeta                              */
/*  Borrado de referencia de tarjeta                                    */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*  27/04/2021  BDU         CREACION SP                                 */
/*  16/09/2021  BDU         Corrección secuencial de referencia         */
/************************************************************************/
use cobis

go

if exists (select 1 from sysobjects where name = 'sp_ref_tar')
   drop proc sp_ref_tar
   
go

create proc sp_ref_tar (
        @s_ssn              int             = null,
        @s_user             login           = null,
        @s_term             varchar(30)     = null,
        @s_date             datetime        = null,
        @s_srv              varchar(30)     = null,
        @s_lsrv             varchar(30)     = null,
        @s_ofi              smallint        = null,
        @s_rol              smallint        = NULL,
        @s_org_err          char(1)         = NULL,
        @s_error            int             = NULL,
        @s_sev              tinyint         = NULL,
        @s_msg              descripcion     = NULL,
        @s_org              char(1)         = NULL,
        @t_debug            char(1)         = 'N',
        @t_file             varchar(10)     = null,
        @t_from             varchar(32)     = null,
        @t_trn              int             = null,
        @i_operacion        char(1),
        @i_ente             int             = null,
        @i_referencia       tinyint         = null,
        @i_banco            varchar(4)      = null,
        @i_cuenta           varchar(30)     = null,
        @i_tipo_cifras      char(2)         = null,
        @i_numero_cifras    tinyint         = null,
        @i_calificacion     catalogo        = null,
        @i_observacion      varchar(254)    = null,
        @i_verificacion     char(1)         = 'S' ,
        @i_fecha_apertura   datetime        = null,
        @i_fecha_ver        datetime        = null
)

as

declare @w_sp_name              varchar(32),
        @w_codigo               int,
        @w_return               int,
        @o_siguiente            tinyint,
        @w_banco                int,
        @w_cuenta               varchar(30),
        @w_tipo_cifras          char(2),
        @w_numero_cifras        tinyint,
        @w_fecha_registro       datetime,
        @w_fecha_modificacion   datetime,
        @w_fecha_ver            datetime,
        @w_verificacion         char(1),
        @w_calificacion         char(2),
        @w_vigencia             char(1),
        @w_observacion          varchar(254),
        @w_fecha_apertura       datetime,
        @w_today                datetime,
        @w_num                  int,
        @w_param                int, 
        @w_diff                 int,
        @w_date                 datetime,
        @w_bloqueo              char(1),
        @v_banco                int,
        @v_cuenta               varchar(30),
        @v_tipo_cifras          char(2),
        @v_numero_cifras        tinyint,
        @v_fecha_registro       datetime,
        @v_fecha_modificacion   datetime,
        @v_fecha_ver            datetime,
        @v_verificacion         char(1),
        @v_calificacion         char(2),
        @v_vigencia             char(1),
        @v_observacion          varchar(254),
        @v_fecha_apertura       datetime,
        @o_ente                 int,
        @o_cedruc               numero,
        @o_ennombre             descripcion,
        @o_banco                int,
        @o_banco_nombre         descripcion,
        @o_cuenta               varchar(30),
        @o_tipo_cifras          char(2),
        @o_numero_cifras        tinyint,
        @o_fecha_registro       datetime,
        @o_fecha_modificacion   datetime,
        @o_fecha_ver            datetime,
        @o_verificacion         char(1),
        @o_calificacion         char(2),
        @o_observacion          varchar(254),
        @o_vigencia             char(1),
        @o_fecha_apertura       datetime

select @w_sp_name = 'sp_ref_tar'
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
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720079
      /* 'No existe ente'*/
      return 1
   end
   /* verificar que exista el tipo de referencia (T: de tarjeta) */
   exec @w_return = cobis..sp_catalogo
     @t_debug   = @t_debug,
     @t_file    = @t_file,
     @t_from    = @w_sp_name,
     @i_tabla   = 'cl_rtipo',
     @i_operacion   = 'E',
     @i_codigo  = 'T'

    /* si no existe el tipo, error */
   if @w_return != 0
   begin
      exec sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720504
          /* 'No existe tipo de referencia de tarjeta'*/
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
   
  if not exists (select 1  from cl_tabla a,cl_catalogo b
                           where   a.tabla  = 'cl_tarjeta'
                           and     a.codigo = b.tabla
                           and     b.codigo = @i_banco)
   begin
      exec sp_cerror
          @t_debug    = @t_debug,
          @t_file     = @t_file,
          @t_from     = @w_sp_name,
          @i_num      = 1720498
           /* 'Falta nombre del banco '*/
      return 1
   end
   /*if not exists (select 1 from cl_tarjeta where ba_banco = @i_banco)
   begin
      exec sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 101144
      /* 'Falta nombre del banco '*/
      return 1
    end*/

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
            @i_num      = 1720505
            /* 'Error en creacion de referencia '*/
         return 1
      end
        /* encontrar el nuevo secuencial para la referencia */
      select @o_siguiente = isnull(max(referencia), 0) + 1
      from cobis..cl_tarjeta
      where ente = @i_ente
        /* insertar la nueva referencia */
      insert into cl_tarjeta (ente,                   referencia,         tipo,
                              tipo_cifras,            numero_cifras,      fecha_registro,
                              fecha_modificacion,     calificacion,       verificacion,
                              vigencia,               observacion,        banco,
                              cuenta,                 fecha_apertura,     funcionario,
                              fecha_ver)
                      values (@i_ente,                @o_siguiente,       'T',
                              @i_tipo_cifras,         @i_numero_cifras,   @w_today,
                              @w_today,               @i_calificacion,    @i_verificacion,
                              'S',                    @i_observacion,     @i_banco,
                              @i_cuenta,              @i_fecha_apertura,  @s_user,
                              @i_fecha_ver)
        /* si no se puede insertar, error */
      if @@error != 0
      begin
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 1720505
             /* 'Error en creacion de referencia de tarjeta'*/
         return 1
      end
      /* Transaccion servicios - cl_referencia */
      insert into ts_referencia  (secuencial,         tipo_transaccion,   clase,
                                  fecha,              usuario,            terminal,
                                  srv,                lsrv,               ente,
                                  referencia,         tipo,               tipo_cifras,
                                  numero_cifras,      calificacion,       verificacion,
                                  vigencia,           observacion,        fecha_registro,
                                  banco,              cuenta,             fecha_apert,
                                  fecha_ver)
                          values (@s_ssn,             @t_trn,             'N',
                                  @s_date,            @s_user,            @s_term,
                                  @s_srv,             @s_lsrv,            @i_ente,
                                  @o_siguiente,       'T',                @i_tipo_cifras,
                                  @i_numero_cifras,   @i_calificacion,    @i_verificacion,
                                  'S',                @i_observacion,     getdate(),
                                  @i_banco,           @i_cuenta,          @i_fecha_apertura,
                                  @i_fecha_ver)

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
   select @o_siguiente
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
     @i_codigo  = 'T'

    /* si no existe el tipo, error */
   if @w_return != 0
   begin
      exec sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720504
          /* 'No existe tipo de referencia de tarjeta'*/
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
   exec @w_return   = cobis..sp_catalogo
   @t_debug         = @t_debug,
   @t_file          = @t_file,
   @t_from          = @w_sp_name,
   @i_tabla         = 'cl_tcifras',
   @i_operacion     = 'E',
   @i_codigo        = @i_tipo_cifras
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

   if not exists (select 1  from cl_tabla a,cl_catalogo b
                   where   a.tabla  = 'cl_tarjeta'
                   and     a.codigo = b.tabla
                   and     b.codigo = @i_banco)
   begin
      exec sp_cerror
          @t_debug    = @t_debug,
          @t_file     = @t_file,
          @t_from     = @w_sp_name,
          @i_num      = 1720498
           /* 'Falta nombre del banco '*/
      return 1
   end
   /* Control de campos a actualizar */
   
   select  @w_banco                = banco,
           @w_cuenta               = cuenta,
           @w_tipo_cifras          = tipo_cifras,
           @w_numero_cifras        = numero_cifras,
           @w_calificacion         = calificacion,
           @w_observacion          = observacion,
           @w_verificacion         = verificacion,
           @w_fecha_ver            = fecha_ver,
           @w_fecha_modificacion   = fecha_modificacion,
           @w_vigencia             = vigencia,
           @w_fecha_apertura       = fecha_apertura
   from cl_tarjeta
   where ente = @i_ente
   and referencia = @i_referencia
   /* si no existe dato, error */
   if @@rowcount = 0
   begin
      exec sp_cerror
          @t_debug    = @t_debug,
          @t_file     = @t_file,
          @t_from     = @w_sp_name,
          @i_num      = 1720506
      
           /* 'No existe referencia '*/
      
      return 1
   end
   select  @v_banco = @w_banco,
           @v_cuenta = @w_cuenta,
           @v_tipo_cifras = @w_tipo_cifras,
           @v_numero_cifras = @w_numero_cifras,
           @v_calificacion = @w_calificacion,
           @v_observacion = @w_observacion,
           @v_verificacion = @w_verificacion,
           @v_fecha_ver = @w_fecha_ver,
           @v_fecha_modificacion = @w_fecha_modificacion,
           @v_vigencia = @w_vigencia,
           @v_fecha_apertura = @w_fecha_apertura
   
   if @w_banco = @i_banco
      select @w_banco = null, @v_banco = null
   else
      select @w_banco = @i_banco
   
   if @w_cuenta = @i_cuenta
      select @w_cuenta = null, @v_cuenta = null
   else
      select @w_cuenta = @i_cuenta
   
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
   
   if @w_fecha_ver = @i_fecha_ver
      select @w_fecha_ver = null--, @v_fecha_ver = null
   else
      select @w_fecha_ver = @i_fecha_ver
   
   if @w_fecha_apertura = @i_fecha_apertura
      select @w_fecha_apertura = null, @v_fecha_apertura = null
   else
      select @w_fecha_apertura = @i_fecha_apertura
   
   begin tran
          /* modificar los datos actuales */
     update cl_tarjeta
   
     set     banco               = @i_banco,
             tipo_cifras         = @i_tipo_cifras,
             numero_cifras       = @i_numero_cifras,
             calificacion        = @i_calificacion,
             verificacion        = 'N',
             fecha_ver           = @w_fecha_ver,
             fecha_modificacion  = @w_today,
             vigencia            = 'S',
             observacion         = @i_observacion,
             cuenta              = @i_cuenta,
             fecha_apertura      = @i_fecha_apertura
     where  ente = @i_ente
     and    referencia = @i_referencia
   
         /* si no se puede modificar, error */
   
     if @@error != 0
   
     begin
   
         exec sp_cerror
   
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720507
   
           /* 'Error en actualizacion de referencia de tarjeta'*/
   
         return 1
   
     end
   
     if @i_verificacion = 'S'
   
     begin
   
         update  cl_tarjeta
         set verificacion = @i_verificacion,
              funcionario = @s_user
              where  ente = @i_ente
           and referencia = @i_referencia
   
             /* si no se puede modificar, error */
   
         if @@error != 0
         begin
             exec sp_cerror
   
             @t_debug    = @t_debug,
             @t_file     = @t_file,
             @t_from     = @w_sp_name,
             @i_num      = 1720507
   
               /* 'Error en actualizacion de referencia tarjeta'*/
   
             return 1
   
         end
   
     end
   
     /* Transaccion servicios - cl_tarjeta */
   
         insert into ts_referencia  (secuencial,         tipo_transaccion,       clase,
                                     fecha,              usuario,                terminal,
                                     srv,                lsrv,                   ente,
                                     referencia,         tipo,                   tipo_cifras,
                                     numero_cifras,      calificacion,           verificacion,
                                     vigencia,           observacion,            fecha_modificacion,
                                     banco,              fecha_ver,              cuenta,
                                     fecha_apert)
                             values (@s_ssn,             @t_trn,                 'P',
                                     @s_date,            @s_user,                @s_term,
                                     @s_srv,             @s_lsrv,                @i_ente,
                                     @i_referencia,      'T',                    @v_tipo_cifras,
                                     @v_numero_cifras,   @v_calificacion,        @v_verificacion,
                                     @v_vigencia,        @v_observacion,         @v_fecha_modificacion,
                                     @v_banco,           @v_fecha_ver,           @v_cuenta,
                                     @v_fecha_apertura)
   
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
   
     /* Transaccion servicios - cl_tarjeta */
   
     insert into ts_referencia  (secuencial,         tipo_transaccion,   clase,
                                 fecha,              usuario,            terminal,
                                 srv,                lsrv,               ente,
                                 referencia,         tipo,               tipo_cifras,
                                 numero_cifras,      calificacion,       verificacion,
                                 vigencia,           observacion,        banco,
                                 fecha_ver,          cuenta,             fecha_apert)
                         values (@s_ssn,             @t_trn,             'A',
                                 @s_date,            @s_user,            @s_term,
                                 @s_srv,             @s_lsrv,            @i_ente,
                                 @i_referencia,      'T',                @w_tipo_cifras,
                                 @w_numero_cifras,   @w_calificacion,    @i_verificacion,
                                 'S',                @w_observacion,     @w_banco,
                                 @i_fecha_ver,       @w_cuenta,          @w_fecha_apertura)
   
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
   select  @w_banco                = banco,
           @w_cuenta               = cuenta,
           @w_tipo_cifras          = tipo_cifras,
           @w_numero_cifras        = numero_cifras,
           @w_calificacion         = calificacion,
           @w_observacion          = observacion,
           @w_verificacion         = verificacion,
           @w_fecha_registro       = fecha_registro,
           @w_fecha_ver            = fecha_ver,
           @w_fecha_modificacion   = fecha_modificacion,
           @w_vigencia             = vigencia,
           @w_fecha_apertura       = fecha_apertura
   from cl_tarjeta
   where ente = @i_ente
   and referencia = @i_referencia
   /* si no existe referencia de tarjeta, error */
   if @@rowcount = 0
   begin
      exec sp_cerror   
      @t_debug  = @t_debug,
      @t_file   = @t_file,
      @t_from   = @w_sp_name,
      @i_num    = 1720506
        /* 'No dato solicitado' */
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
             @i_num      = 1720510
            /* 'Error en disminucion de referencia '*/
         return 1
      end
      /* borrar la referencia */
      delete from cl_tarjeta
      where ente = @i_ente
      and referencia = @i_referencia
      /* si no se puede borrar, error */
      if @@error != 0
      begin
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 1720509
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
            @i_num      = 1720509
             --'Error en eliminacion de referencia '
         return 1
      end
      */
      
      /* Transaccion servicios - cl_referencia */
      insert into ts_referencia  (secuencial,             tipo_transaccion,   clase,
                                  fecha,                  usuario,            terminal,
                                  srv,                    lsrv,               ente,
                                  referencia,             tipo,               tipo_cifras,
                                  numero_cifras,          calificacion,       verificacion,
                                  vigencia,               observacion,        fecha_registro,
                                  banco,                  fecha_ver,          cuenta,
                                  fecha_modificacion,     fecha_apert)
                          values (@s_ssn,                 @t_trn,             'B',
                                  @s_date,                @s_user,            @s_term,
                                  @s_srv,                 @s_lsrv,            @i_ente,
                                  @i_referencia,          'T',                @w_tipo_cifras,
                                  @w_numero_cifras,       @w_calificacion,    @w_verificacion,
                                  @w_vigencia,            @w_observacion,     @w_fecha_registro,
                                  @w_banco,               @w_fecha_ver,       @w_cuenta,
                                  @w_fecha_modificacion,  @w_fecha_apertura)
      
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

go
