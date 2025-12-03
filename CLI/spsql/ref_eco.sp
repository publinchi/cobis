/************************************************************************/
/*  Archivo:            ref_eco.sp                                      */
/*  Stored procedure:   sp_ref_eco                                      */
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
/*  Insercion de referencia economica                                   */
/*  Actualizacion de referencia economica                               */
/*  Borrado de referencia economica                                     */
/*  Busqueda de referencia economica  general y especifica              */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA           AUTOR           RAZON                               */
/*  31/03/95        Bco.Prestamos   Ingreso de nuevos campos            */
/*  17/04/97        Ivette Rojas    Aniadir Fecha de Verificacion       */
/*  22/Nov/2017     A.K.Rodriguez   Caso #89847                         */
/*  14/Set/2018     G.Romero        101644 Usuario que modifica         */
/*  27/04/2021      BDU             CREACION SP                         */
/*  03/08/21        ACA             Validación de duplicidad Nro Cuenta */
/*  16/09/2021      BDU             Corrección secuencial de referencia */
/************************************************************************/
use cobis

go

if exists (select 1 from sysobjects where name = 'sp_ref_eco')
   drop proc sp_ref_eco
   
go

create proc sp_ref_eco (
        @s_ssn              int             = null,
        @s_user             login           = null,
        @s_term             varchar(30)     = null,
        @s_date             datetime        = null,
        @s_srv              varchar(30)     = null,
        @s_lsrv             varchar(30)     = null,
        @s_ofi              smallint        = null,
        @s_rol              smallint        = null,
        @s_org_err          char(1)         = null,
        @s_error            int             = null,
        @s_sev              tinyint         = null,
        @s_msg              descripcion     = null,
        @s_org              char(1)         = null,
        @t_debug            char(1)         = 'N',
        @t_file             varchar(10)     = null,
        @t_from             varchar(32)     = null,
        @t_trn              int             = null,
        @i_operacion        char(1),
        @i_ente             int             = null,
        @i_tipo             char(1)         = null,
        @i_referencia       tinyint         = null,
        @i_banco            smallint        = null,
        @i_cuenta           varchar(30)     = null,
        @i_tipo_cifras      char(2)         = null,
        @i_numero_cifras    tinyint         = null,
        @i_calificacion     catalogo        = null,
        @i_observacion      varchar(254)    = null,
        @i_verificacion     char(1)         = 'S',
        @i_fecha_apertura   datetime        = null,
        @i_tipo_cta         catalogo        = null,
        @i_fecha_ver        datetime        = null,
        @i_estado_mon       char(1)         = null,
        @o_referencia_sec   tinyint         = null output
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
        @w_estado               char(1),
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
        @v_estado               char(1),
        @o_ente                 int,
        @o_cedruc               numero,
        @o_en_nombre            varchar(150),
        @o_referencia           tinyint,
        @o_tipo                 char(1),
        @o_desc_tipo            descripcion,
        @o_institucion          descripcion,
        @o_fecha_ingr_en_inst   datetime,
        @o_banco                int,
        @o_banco_nombre         descripcion,
        @o_cuenta               varchar(30),
        @o_banco_tar            int,
        @o_tarjeta_nombre       descripcion,
        @o_cuenta_tar           varchar(30),
        @o_calificacion         char(2),
        @o_desc_calif           descripcion,
        @o_tipo_cifras          char(2),
        @o_numero_cifras        tinyint,
        @o_desc_tipo_cifras     descripcion,
        @o_verificacion         char(1),
        @o_fecha_ver            datetime,
        @o_vigencia             char(1),
        @o_fecha_modificacion   datetime,
        @o_fecha_registro       datetime,
        @o_observacion          varchar(254),
        @o_funcionario          login,
        @o_bancof               smallint,
        @o_toperacion           char(1),
        @o_clase                descripcion,
        @o_fec_inicio           datetime,
        @o_fec_vencimiento      datetime,
        @o_estatus              char(1),
        @o_bancof_des           descripcion,
        @w_error                int,
        @o_fecha_apertura       datetime,
        @o_tipo_cta             catalogo

select @w_sp_name           =       'sp_ref_eco'
select @w_today             =       getdate(),
       @i_verificacion      =       'S',
       @i_fecha_ver         =       getdate()
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

   if exists (select 1 from cobis..cl_economica where ente = @i_ente AND banco = @i_banco AND cuenta = ltrim(rtrim(@i_cuenta)))
   begin
      exec sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720307

          /* 'Ya existe la referencia para este cliente'*/
      return 1
   end 

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
     @i_num      = 1720411

      /* 'No existe ente'*/

     return 1

   end

   /* verificar que exista el tipo de referencia (B: Bancaria, M: Monedero electrónico) */

     exec @w_return = cobis..sp_catalogo

      @t_debug   = @t_debug,
      @t_file    = @t_file,
      @t_from    = @w_sp_name,
      @i_tabla   = 'cl_rtipo',
      @i_operacion   = 'E',
      @i_codigo  = @i_tipo

    /* si no existe el tipo, error */

    if @w_return != 0

    begin

     exec sp_cerror

         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720512

          /* 'No existe tipo de referencia economica '*/

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

      if @i_tipo_cifras is not null
      begin
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
      end

     if not exists (select 1 from cob_bancos..ba_banco
                  where ba_codigo = @i_banco)

    begin

       exec sp_cerror
       @t_debug    = @t_debug,
       @t_file     = @t_file,
       @t_from     = @w_sp_name,
       @i_num      = 1720498
        /* 'Falta nombre del banco '*/
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
            @i_num      = 1720513
              /* 'Error en creacion de referencia '*/
            return 1
       end
           /* encontrar el nuevo secuencial para la referencia */
       select @o_siguiente = isnull(max(referencia), 0) + 1
       from cobis..cl_economica
       where ente = @i_ente
       
       select @o_referencia_sec = @o_siguiente
    
           /* insertar la nueva referencia */
       insert into cl_economica   (ente,               referencia,         tipo,
                                   tipo_cifras,        numero_cifras,      fecha_registro,
                                   fecha_modificacion, calificacion,       verificacion,
                                   vigencia,           observacion,        banco,
                                   cuenta,             tipo_cta,           fec_apertura,
                                   funcionario,        fecha_ver,          estado)
                           values (@i_ente,            @o_siguiente,       @i_tipo,
                                   @i_tipo_cifras,     @i_numero_cifras,   @w_today, --@i_fecha_apertura,
                                   @w_today,           @i_calificacion,    @i_verificacion,
                                   'S',                @i_observacion,     @i_banco,
                                   @i_cuenta,          @i_tipo_cta,        @i_fecha_apertura,
                                   @s_user,            @i_fecha_ver,       @i_estado_mon)
           /* si no se puede insertar, error */
       if @@error != 0
       begin
          exec sp_cerror
          @t_debug    = @t_debug,
          @t_file     = @t_file,
          @t_from     = @w_sp_name,
          @i_num      = 1720513
            /* 'Error en creacion de referencia economica'*/
          return 1
       end
       /* Transaccion servicios - cl_referencia */
       insert into ts_referencia  (secuencial,         tipo_transaccion,   clase,
                                   fecha,              usuario,            terminal,
                                   srv,                lsrv,               ente,
                                   referencia,         tipo,               tipo_cifras,
                                   numero_cifras,      calificacion,       verificacion,
                                   vigencia,           observacion,        fecha_registro,
                                   banco,              cuenta,             fecha_ver,
                                   estatus)
                           values (@s_ssn,             @t_trn,             'N',
                                   @s_date,            @s_user,            @s_term,
                                   @s_srv,             @s_lsrv,            @i_ente,
                                   @o_siguiente,       @i_tipo,            @i_tipo_cifras,
                                   @i_numero_cifras,   @i_calificacion,    @i_verificacion,
                                   'S',                @i_observacion,     getdate(),
                                   @i_banco,           @i_cuenta,          @i_fecha_ver,
                                   @i_estado_mon )
    
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
   if exists (select 1 from cobis..cl_economica where ente = @i_ente AND banco = @i_banco AND referencia <> @i_referencia AND cuenta = ltrim(rtrim(@i_cuenta)))
   begin
      exec sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720307

          /* 'Ya existe la referencia para este cliente'*/
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
    if @i_tipo_cifras is not null
    begin
      /*verificar que exista el tipo de cifras */
   
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
   end
   
   if not exists (select 1 from cob_bancos..ba_banco
                  where ba_codigo = @i_banco)
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
           @w_estado               = estado
   from cl_economica
   where ente = @i_ente and referencia = @i_referencia
   
    /* si no existe dato, error */
   
   if @@rowcount = 0
   begin
      exec sp_cerror
   
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720512
   
       /* 'No existe referencia '*/
   
      return 1
   
   end
   
   select  @v_banco = @w_banco,
           @v_cuenta               = @w_cuenta,
           @v_tipo_cifras          = @w_tipo_cifras,
           @v_numero_cifras        = @w_numero_cifras,
           @v_calificacion         = @w_calificacion,
           @v_observacion          = @w_observacion,
           @v_verificacion         = @w_verificacion,
           @v_fecha_ver            = @w_fecha_ver,
           @v_fecha_modificacion   = @w_fecha_modificacion,
           @v_vigencia             = @w_vigencia,
           @v_estado               = @w_estado

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
   
   if @w_estado = @i_estado_mon
      select @w_estado = null--, @v_estado = null
   else
      select @w_estado = @i_estado_mon

   begin tran
   
       /* modificar los datos actuales */
   
      update cl_economica
   
      set     banco               = @i_banco,
              tipo_cifras         = @i_tipo_cifras,
              numero_cifras       = @i_numero_cifras,
              calificacion        = @i_calificacion,
              verificacion        = @i_verificacion,
              fecha_ver           = @i_fecha_ver,
              fecha_modificacion  = @w_today,
              vigencia            = 'S',
              observacion         = @i_observacion,
              cuenta              = @i_cuenta,
              tipo_cta            = @i_tipo_cta,
              fec_apertura        = @i_fecha_apertura,
              estado              = @i_estado_mon,
              funcionario         = @s_user   --GRO 101644
      where  ente = @i_ente
      and    referencia = @i_referencia
   
          /* si no se puede modificar, error */
   
      if @@error != 0
   
      begin
   
         exec sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720515
           /* 'Error en actualizacion de referencia economica'*/
         return 1
      end
   
      /*if @i_verificacion = "S"
      begin
          update  cl_economica
          set verificacion = @i_verificacion,
              funcionario = @s_user
          where  ente = @i_ente
          and    referencia = @i_referencia
              --si no se puede modificar, error
   
          if @@error != 0
          begin
              exec sp_cerror
   
              @t_debug    = @t_debug,
              @t_file     = @t_file,
              @t_from     = @w_sp_name,
              @i_num      = 1720513
   
                -- 'Error en actualizacion de referencia economica'
   
              return 1
   
          end
   
      end
   
      */
   
      /* Transaccion servicios - cl_economica*/
          insert into ts_referencia      (secuencial,         tipo_transaccion,      clase,    fecha,
                                          usuario,            terminal,              srv,
                                          lsrv,               ente,                  referencia,
                                          tipo,               tipo_cifras,           numero_cifras,
                                          calificacion,       verificacion,          vigencia,
                                          observacion,        fecha_modificacion,    banco,
                                          fecha_ver,          cuenta,                estatus)
                                  values (@s_ssn,             @t_trn,                'P',      @s_date,
                                          @s_user,            @s_term,                @s_lsrv,
                                          @s_srv,             @i_ente,               @i_referencia,     
                                          @i_tipo,            @v_tipo_cifras,        @v_numero_cifras,   
                                          @v_calificacion,    @v_verificacion,       @v_vigencia,
                                          @v_observacion,     @v_fecha_modificacion, @v_banco, 
                                          @v_fecha_ver,       @v_cuenta,             @v_estado)
   
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
   
      /* Transaccion servicios - cl_economica */
   
      insert into ts_referencia   (secuencial,    tipo_transaccion,   clase,
                                  fecha,          usuario,            terminal,
                                  srv,            lsrv,               ente,
                                  referencia,     tipo,               tipo_cifras,
                                  numero_cifras,  calificacion,       verificacion,
                                  vigencia,       observacion,        banco,
                                  fecha_ver,      cuenta)
   
                          values (@s_ssn,             @t_trn,             'A',
                                  @s_date,            @s_user,            @s_term,
                                  @s_srv,             @s_lsrv,            @i_ente,
                                  @i_referencia,      @i_tipo,            @w_tipo_cifras,
                                  @w_numero_cifras,   @w_calificacion,    @i_verificacion,
                                  'S',                @w_observacion,     @w_banco,
                                  @i_fecha_ver,       @w_cuenta)
   
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
   
   select  @w_banco = banco,
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
       @w_estado               = estado
   from cl_economica
   where ente = @i_ente
   and referencia = @i_referencia
   
   /* si no existe referencia de economica, error */
   
   if @@rowcount = 0
   begin
      exec sp_cerror
   
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720512
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
              @i_num      = 1720514
             /* 'Error en disminucion de referencia '*/
      
          return 1
     
      end
   
      /* borrar la referencia */
   
      delete from cl_economica
      where ente = @i_ente
      and referencia = @i_referencia
   
      /* si no se puede borrar, error */
   
      if @@error != 0
      begin
   
         exec sp_cerror
      
             @t_debug    = @t_debug,
             @t_file     = @t_file,
             @t_from     = @w_sp_name,
             @i_num      = 1720517
      
             /* 'Error en eliminacion de referencia '*/
      
         return 1
   
      end
   
      /* 
      --modificar en uno la secuencia de referencias 
   
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
             @i_num      = 1720515
      
             -- 'Error en eliminacion de referencia '
         return 1
      end
   */
      /* Transaccion servicios - cl_referencia */
   
      insert into ts_referencia(secuencial,         tipo_transaccion,   clase,
                                fecha,              usuario,            terminal,
                                srv,                lsrv,               ente,
                                referencia,         tipo,               tipo_cifras,
                                numero_cifras,      calificacion,       verificacion,
                                vigencia,           observacion,        fecha_registro,
                                banco,              fecha_ver,          cuenta,
                                fecha_modificacion,  estatus)
                        values (@s_ssn,             @t_trn,             'B',
                                @s_date,            @s_user,            @s_term,
                                @s_srv,             @s_lsrv,            @i_ente,
                                @i_referencia,      @i_tipo,            @w_tipo_cifras,
                                @w_numero_cifras,   @w_calificacion,    @w_verificacion,
                                @w_vigencia,        @w_observacion,     @w_fecha_registro,
                                @w_banco,           @w_fecha_ver,       @w_cuenta,
                                @w_fecha_modificacion,  @w_estado)
   
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

if @i_operacion = 'G'
begin   
   
   if exists(select 1 from sysobjects where name = '#cl_referencias')
   begin
      drop table #cl_referencias
   end   
   --Se crea una tabla temporal para almacenar los datos de todas las referencias económicas del cliente
   create table #cl_referencias(
           referencia             tinyint,
           tipo                   char(1),
           ente                   int,
           institucion            int,
           nombreBan              varchar(128),
           tipoCuenta             char(4),
           cuenta                 varchar(30),
           fechaApertura          datetime,
           fechaVencimiento       datetime,
           numero_cifras          tinyint,
           tipo_cifras            char(2),
           calificacion           char(2),
           observacion            varchar(254),
           tipoOperacion          char(1),
           estado                 char(1),
           clase                  varchar(64),
           nombreReferencia       varchar(64),
           tarjeta                varchar(4),
           estadoMon              char(1)
   )
   
      ----Datos Referencia Bancaria-----------
   insert into #cl_referencias   select  referencia,    tipo,               ente,
                                         banco,         ba.ba_nombre,       tipo_cta,cuenta,        
                                         fec_apertura,  null,               numero_cifras,  
                                         tipo_cifras,   calificacion,       a.observacion, 
                                         null,          null,               null,
                                         "Descripcion tipo de referencia" = (select valor from cobis..cl_catalogo c, cobis..cl_tabla t                                                  
                                                                             where c.tabla = t.codigo 
                                                                             and c.codigo = tipo 
                                                                             and t.tabla = 'cl_rtipo'),
                                         null,          a.estado
   from cl_economica a join cob_bancos..ba_banco ba on ba.ba_codigo = a.banco    
   where a.ente = @i_ente 
   -------Datos Referencia Comercial--------
   union  select referencia,     tipo,              ente,                 
                 null,           institucion,       null,
                 null,           fecha_ingr_en,    null,
                 numero_cifras,  tipo_cifras,       calificacion,            
                 observacion,    null,              null,                      
                 null,           "Descripcion tipo de referencia" = (select valor from cobis..cl_catalogo c, cobis..cl_tabla t                                                  
                                                                     where c.tabla = t.codigo 
                                                                     and c.codigo = tipo 
                                                                     and t.tabla = 'cl_rtipo'),
                    null,             null
   from dbo.cl_comercial
   where ente = @i_ente
   -------Datos Referencia Financiera--------
   union select referencia,         treferencia,      cliente ,        institucion, 
                ba.ba_nombre,       null,             null,            fec_inicio,     
                fec_vencimiento,    numero_cifras,    tipo_cifras ,    calificacion,                
                observacion,        toperacion,       estatus,         tclase, 
                "Descripcion tipo de referencia" = (select valor from cobis..cl_catalogo c, cobis..cl_tabla t                                                  
                                                    where c.tabla = t.codigo 
                                                    and c.codigo = treferencia 
                                                    and t.tabla = 'cl_rtipo'),
                   null,            null
   from dbo.cl_financiera a join cob_bancos..ba_banco ba on ba.ba_codigo = a.institucion
   where a.cliente = @i_ente
   -------Datos Referencia Tarjeta--------
   union select referencia,        tipo,              ente,             null,
                                   "banco"  = (select c.valor from cl_tabla t, cl_catalogo c 
                                   where t.tabla = 'cl_tarjeta'
                                   and c.tabla = t.codigo
                                   and c.codigo = banco),
                                   null,              cuenta,           fecha_apertura,
                                   null,              numero_cifras,    tipo_cifras,
                                   calificacion,      observacion,       null,             
                                   null,            null,
                                   "Descripcion tipo de referencia" = (select valor from cobis..cl_catalogo c, cobis..cl_tabla t
                                                                       where c.tabla = t.codigo 
                                                                       and c.codigo = tipo 
                                                                       and t.tabla = 'cl_rtipo'),
                                   banco,           null
   from dbo.cl_tarjeta a where a.ente = @i_ente
   
   if @i_tipo = 'T'
   begin
      select  'Referencia'        = referencia,--1
              'Tipo Cuenta'       = tipoCuenta,--2
              'Tipo Cuenta T'     = nombreReferencia,--3
              'Tipo Referencia'   = tipo,
              'Fecha Vencimiento' = fechaVencimiento,--5
              'Observacion'       = observacion,--6
              'Tipo Cifras'       = tipo_cifras,
              'Tarjeta'           = tarjeta,
              'Calificacion'      = calificacion,
              'Nombre Referencia' = (select valor 
                                     from cl_tabla t, cl_catalogo c 
                                     where t.tabla = 'ba_tcuenta' 
                                     and t.codigo = c.tabla 
                                     and tipoCuenta = c.codigo),
              'Estado'            = estado,
              'Cuenta'            = cuenta,--12
              'Tipo Operacion'    = tipoOperacion,
              'Numero Cifras'     = numero_cifras,--14
              'Fecha Apertura'    = fechaApertura,--15
              'Clase'             = clase,
              'Cliente'           = ente,
              'Banco'             = institucion,--18
              'Nombre Banco'      = nombreBan--19
           
      from #cl_referencias
   end

   else

   begin
      select  'Cliente'           = ente,
              'Referencia'        = referencia,
              'Tipo Referencia'   = tipo,
              'Tipo Cifras'       = tipo_cifras,
              'Numero Cifras'     = numero_cifras,
              'Calificacion'      = calificacion,
              'Banco'             = institucion,
              'Tarjeta'           = tarjeta,
              'Cuenta'            = cuenta,
              'Tipo Cuenta'       = tipoCuenta,
              'Fecha Apertura'    = fechaApertura,
              'Nombre Banco'      = nombreBan,
              'Observacion'       = observacion,
              'Nombre Referencia' = nombreReferencia,
              'Fecha Vencimiento' = fechaVencimiento,
              'Tipo Operacion'    = tipoOperacion,
              'Estado'            = estado,
              'Clase'             = clase,
              'Estado Monedero'   = estadoMon
           
      from #cl_referencias
   end
   return 0
end

/** Query **/
if @i_operacion = 'S'
begin
/* DATOS DE REFERENCIA MONEDERO O BANCARIA */
   select  'REFERENCIA'          = referencia,    
           'CLIENTE'             = ente,
           'BANCO'               = banco,         
           'NOMBRE BANCO'        = ba.ba_nombre,       
           'TIPO DE CUENTA'      = tipo_cta,
           'NUMERO DE CUENTA'    = cuenta,                                  
           'FECHA APERTURA'      = (select FORMAT (fec_apertura, 'dd/MM/yyyy HH:mm:ss') as date),               
           'NUMERO CIFRAS'       = numero_cifras,  
           'TIPO CIFRAS'         = tipo_cifras,   
           'CALIFICACION'        = calificacion,    
           'ESTADO MONEDERO'     = estado,      
           'OBSERVACION'         = observacion
      from cl_economica a join cob_bancos..ba_banco ba on ba.ba_codigo = a.banco    
      where a.ente = @i_ente and tipo = @i_tipo
      
   if @@rowcount = 0
   begin
       exec sp_cerror
       @t_debug    = @t_debug,
       @t_file     = @t_file,
       @t_from     = @w_sp_name,
       @i_num      = 1720019
   end
   return 0
end

/* Datos completos de una referencia */

if @i_operacion = 'Q'
begin

   select @o_tipo=null
   
   select  @o_ente                 = re_ente,
           @o_cedruc               = en_ced_ruc,
           @o_en_nombre            = substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre),1,64),
           @o_referencia           = re_referencia,
           @o_tipo                 = re_tipo,
           @o_desc_tipo            = a.valor,
           @o_institucion          = substring(co_institucion,1,30),
           @o_fecha_ingr_en_inst   = co_fecha_ingr_en_inst,
           @o_banco                = ec_banco,
           @o_banco_nombre         = substring(ba_nombre,1,30),
           @o_cuenta               = ec_cuenta,
           @o_calificacion         = re_calificacion,
           @o_tipo_cifras          = re_tipo_cifras,
           @o_desc_tipo_cifras     = e.valor,
           @o_numero_cifras        = re_numero_cifras,
           @o_verificacion         = re_verificacion,
           @o_fecha_ver            = re_fecha_ver,
           @o_vigencia             = re_vigencia,
           @o_fecha_modificacion   = re_fecha_modificacion,
           @o_fecha_registro       = re_fecha_registro,
           @o_observacion          = re_observacion,
           @o_funcionario          = re_funcionario,
           @o_bancof               = fi_banco,
           @o_toperacion           = fi_toperacion,
           @o_clase                = fi_clase,
           @o_fec_inicio           = fi_fec_inicio,
           @o_fec_vencimiento      = fi_fec_vencimiento,
           @o_estatus              = fi_estatus,
           @o_tipo_cta             = ec_tipo_cta,
           @o_fecha_apertura       = ec_fec_apertura
   
   from   cl_referencia,       cl_ente,          cl_catalogo a,
          cl_tabla b,          cl_catalogo e,    cl_tabla f,
          cob_bancos..ba_banco
   
   where  re_ente = @i_ente
   and    en_ente = re_ente
   and    re_referencia = @i_referencia
   and    re_tipo = a.codigo
   and    a.tabla = b.codigo
   and    b.tabla = 'cl_rtipo'
   and    re_tipo_cifras = e.codigo
   and    e.tabla = f.codigo
   and    f.tabla = 'cl_tcifras'
   and    ec_banco = ba_codigo
   
   if @@rowcount = 0
   begin
     exec sp_cerror
       @t_debug    = @t_debug,
       @t_file     = @t_file,
       @t_from     = @w_sp_name,
       @i_num      = 1720512
   
         /*'No existe dato solicitado'*/
   
     return 1
   
     select @w_error = 1
   
   end
   
   if @o_calificacion != null
     begin
       select @o_desc_calif = valor
       from cl_catalogo
       where @o_calificacion = codigo
       and   tabla =   (select codigo from cl_tabla
                       where tabla = 'cl_posicion')
   
       if @@rowcount = 0
       begin
           exec sp_cerror
           @t_debug    = @t_debug,
           @t_file     = @t_file,
           @t_from     = @w_sp_name,
           @i_num      = 1720512
   
               /*'No existe dato solicitado'*/
   
           return 1
           select @w_error = 1
       end
     end
   
   if @o_tipo='F'
   begin
       select @o_bancof_des = substring(ba_nombre,1,30)
       from   cob_bancos..ba_banco
       where  @o_bancof = ba_codigo
   
       if @@rowcount = 0
       begin
           exec sp_cerror
           @t_debug    = @t_debug,
           @t_file     = @t_file,
           @t_from     = @w_sp_name,
           @i_num      = 1720512
   
                /*'No existe dato solicitado'*/
   
            return 1
       end
   end
   
   if @o_tipo='T'
   begin
       select  @o_banco_tar = ta_banco,
               @o_tarjeta_nombre= substring(g.valor,1,30),
               @o_cuenta_tar = ta_cuenta,
               @o_fecha_apertura = ta_fec_apertura
       from    cl_referencia, cl_ente,
               cl_catalogo g, cl_tabla h
       where  re_ente = @i_ente
       and    en_ente = re_ente
       and    re_referencia = @i_referencia
       and    convert(varchar(10),ta_banco) = g.codigo
       and    g.tabla = h.codigo
       and    h.tabla = 'cl_tarjeta'
   
       if @@rowcount = 0
       begin
           exec sp_cerror
               @t_debug    = @t_debug,
               @t_file     = @t_file,
               @t_from     = @w_sp_name,
               @i_num      = 1720512
   
               /*'No existe dato solicitado'*/
   
           return 1
       end
   end
   
   select  @o_ente,                                    @o_cedruc,          @o_en_nombre,
           @o_referencia,                              @o_tipo,            @o_desc_tipo,
           @o_institucion,                             convert(char(10),   @o_fecha_ingr_en_inst,103),@o_banco,
           @o_banco_nombre,                            @o_cuenta,          @o_banco_tar,
           @o_tarjeta_nombre,                          @o_cuenta_tar,      @o_calificacion,
           @o_desc_calif,                              @o_tipo_cifras,     @o_desc_tipo_cifras,
           @o_numero_cifras,                           @o_verificacion,    convert(char(10),@o_fecha_ver,103),
           @o_vigencia,                                convert(char(10),   @o_fecha_modificacion,103),
           convert(char(10),@o_fecha_registro,103),    @o_observacion,     @o_funcionario,
           @o_bancof,                                  @o_toperacion,      @o_clase,
           convert(char(10),@o_fec_inicio,103),        convert(char(10),   @o_fec_vencimiento,103),
           @o_estatus,@o_bancof_des,                   convert(char(10),   @o_fecha_apertura,103),
           @o_tipo_cta
   
   return 0   
   
end

go
