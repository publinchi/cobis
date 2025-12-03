/************************************************************************/
/*  Archivo:            ref_fin.sp                                      */
/*  Stored procedure:   sp_ref_fin                                      */
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
/*  Insercion de referencia de financiera                               */
/*  Actualizacion de referencia de financiera                           */
/*  Borrado de referencia de financiera                                 */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*  27/04/2021  BDU         CREACION SP                                 */
/*  16/09/2021  BDU         Corrección secuencial de referencia         */
/************************************************************************/
use cobis

go

if exists (select 1 from sysobjects where name = 'sp_ref_fin')
   drop proc sp_ref_fin

go

create proc sp_ref_fin (

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
    @i_treferencia          char(1)         = null,
    @i_banco                smallint        = null,
    @i_toperacion           char(1)         = null,
    @i_tclase               descripcion     = null,
    @i_tipo_cifras          catalogo        = null,
    @i_numero_cifras        tinyint         = null,
    @i_fec_inicio           datetime        = null,
    @i_fec_vencimiento      datetime        = null,
    @i_calificacion         catalogo        = null,
    @i_vigencia             char(1)         = null,
    @i_verificacion         char(1)         ='S',
    @i_fecha_ver            datetime        = null,
    @i_fecha_modificacion   datetime        = null,
    @i_observacion          varchar(254)    = null,
    @i_estatus              char(1)         = null,
    @o_referencia_sec       tinyint         = null output

)

as

declare @w_sp_name      varchar(32),

    @w_codigo               int,
    @w_return               int,
    @o_siguiente            tinyint,
    @w_banco                int,
    @w_toperacion           char(1),
    @w_tclase               descripcion,
    @w_tipo_cifras          catalogo,
    @w_numero_cifras        tinyint,
    @w_fec_inicio           datetime,
    @w_fec_vencimiento      datetime,
    @w_calificacion         catalogo,
    @w_vigencia             char(1),
    @w_verificacion         char(1),
    @w_fecha_ver            datetime,
    @w_fecha_modificacion   datetime,
    @w_observacion          varchar(254),
    @w_estatus              char(1),
    @w_today                datetime,
    @w_num                  int,
    @w_param                int, 
    @w_diff                 int,
    @w_date                 datetime,
    @w_bloqueo              char(1),
    @v_banco                int,
    @v_toperacion           char(1),
    @v_tclase               descripcion,
    @v_tipo_cifras          catalogo,
    @v_numero_cifras        tinyint,
    @v_fec_inicio           datetime,
    @v_fec_vencimiento      datetime,
    @v_calificacion         catalogo,
    @v_vigencia             char(1),
    @v_verificacion         char(1),
    @v_fecha_ver            datetime,
    @v_fecha_modificacion   datetime,
    @v_observacion          varchar(254),
    @v_estatus              char(1),
    @o_ente                 int,
    @o_referencia           tinyint,
    @o_tipo                 char(1),
    @o_banco                int,
    @o_toperacion           char(1),
    @o_tclase               descripcion,
    @o_tipo_cifras          catalogo,
    @o_numero_cifras        tinyint,
    @o_fec_inicio           datetime,
    @o_fec_vencimiento      datetime,
    @o_calificacion         catalogo,
    @o_vigencia             char(1),
    @o_verificacion         char(1),
    @o_fecha_ver            datetime,
    @o_fecha_modificacion   datetime,
    @o_observacion          varchar(254),
    @o_estatus              char(1)

select @w_sp_name = 'sp_ref_fin'
select @w_today = getdate() ,

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

    /* verificar que exista el tipo de referencia (F: de financiera) */

   exec @w_return      = cobis..sp_catalogo
        @t_debug       = @t_debug,
        @t_file        = @t_file,
        @t_from        = @w_sp_name,
        @i_tabla       = 'cl_rtipo',
        @i_operacion   = 'E',
        @i_codigo      = 'F'

     /* si no existe el tipo, error */

   if @w_return != 0
   begin
      exec sp_cerror
   
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720497
          /* 'No existe tipo de referencia financiera '*/
      return 1
   
   end
   
    /* verificar que exista el tipo de calificacion */
   
   exec @w_return      = cobis..sp_catalogo
        @t_debug       = @t_debug,
        @t_file        = @t_file,
        @t_from        = @w_sp_name,
        @i_tabla       = 'cl_posicion',
        @i_operacion   = 'E',
        @i_codigo      = @i_calificacion
   
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
   
   exec @w_return      = cobis..sp_catalogo
        @t_debug       = @t_debug,
        @t_file        = @t_file,
        @t_from        = @w_sp_name,
        @i_tabla       = 'cl_tcifras',
        @i_operacion   = 'E',
        @i_codigo      = @i_tipo_cifras
   
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
            @i_num      = 1720499

             /* 'Error en creacion de referencia '*/
         return 1
      end
          /* encontrar el nuevo secuencial para la referencia */
      select @o_siguiente = isnull(max(referencia), 0) + 1
      from cobis..cl_financiera
      where cliente = @i_ente
      
      select @o_referencia_sec = @o_siguiente
          /* insertar la nueva referencia */
      insert into cl_financiera   (cliente,           referencia,           treferencia,
                                  institucion,        toperacion,           tclase,
                                  tipo_cifras,        numero_cifras,        fec_inicio,
                                  fec_vencimiento,    calificacion,         vigencia,
                                  verificacion,       fecha_ver,            fecha_modificacion,
                                  observacion,        estatus,              fecha_registro,
                                  funcionario)
                          values (@i_ente,            @o_siguiente,         'F',
                                  @i_banco,           @i_toperacion,        @i_tclase,
                                  @i_tipo_cifras,     @i_numero_cifras,     @i_fec_inicio,
                                  @i_fec_vencimiento, @i_calificacion,      'S',
                                  @i_verificacion,    @i_fecha_ver,         @w_today,
                                  @i_observacion,     @i_estatus,           @w_today, 
                                  @s_user)
   
          /* si no se puede insertar, error */
      if @@error != 0
      begin

         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 1720499
      
            /* 'Error en creacion de referencia financiera'*/
         return 1
   
      end
      /* Transaccion servicios - cl_referencia */
   
      insert into ts_referencia
              (secuencial,        tipo_transaccion,   clase,
              fecha,              usuario,            terminal,
              srv,                lsrv,               ente,
              referencia,         tipo,               banco,
              toperacion,         tclase,             tipo_cifras,
              numero_cifras,      fec_inicio,         fec_vencimiento,
              calificacion,       vigencia,           verificacion,
              fecha_ver,          fecha_modificacion, observacion,
              estatus)
      values (@s_ssn,             @t_trn,             'N',
              @s_date,            @s_user,            @s_term,
              @s_srv,             @s_lsrv,            @i_ente,
              @o_siguiente,       'F',                @i_banco,
              @i_toperacion,      @i_tclase,          @i_tipo_cifras,
              @i_numero_cifras,   @i_fec_inicio,      @i_fec_vencimiento,
              @i_calificacion,    'S',                @i_verificacion,
              @i_fecha_ver,       @s_date,            @i_observacion,
              @i_estatus)
   
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
        @t_debug       = @t_debug,
        @t_file        = @t_file,
        @t_from        = @w_sp_name,
        @i_tabla       = 'cl_rtipo',
        @i_operacion   = 'E',
        @i_codigo      = 'F'
   
   if @w_return != 0
   
   begin
   
      exec sp_cerror
   
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720497
      
          /* 'No existe tipo de referencia '*/
      return 1
   end
    /*verificar que exista el tipo de calificacion */
   exec @w_return      = cobis..sp_catalogo
        @t_debug       = @t_debug,
        @t_file        = @t_file,
        @t_from        = @w_sp_name,
        @i_tabla       = 'cl_posicion',
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
   exec @w_return      = cobis..sp_catalogo
        @t_debug       = @t_debug,
        @t_file        = @t_file,
        @t_from        = @w_sp_name,
        @i_tabla       = 'cl_tcifras',
        @i_operacion   = 'E',
        @i_codigo      = @i_tipo_cifras
   
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
   
   select  @w_banco               = institucion,
           @w_toperacion          = toperacion,
           @w_tclase              = tclase,
           @w_tipo_cifras         = tipo_cifras,
           @w_numero_cifras       = numero_cifras,
           @w_fec_inicio          = fec_inicio,
           @w_fec_vencimiento     = fec_vencimiento,
           @w_calificacion        = calificacion,
           @w_vigencia            = verificacion,
           @w_fecha_ver           = fecha_ver,
           @w_fecha_modificacion  = fecha_modificacion,
           @w_observacion         = observacion,
           @w_estatus             = estatus
   from cl_financiera
   where cliente = @i_ente
         and referencia = @i_referencia
   
     /* si no existe dato, error */
   
   if @@rowcount = 0
   begin
   exec sp_cerror
       @t_debug    = @t_debug,
       @t_file     = @t_file,
       @t_from     = @w_sp_name,
       @i_num      = 1720500
        /* 'No existe referencia '*/
       return 1
    end
   
       select  @v_banco                = @w_banco,
               @v_toperacion           = @w_toperacion,
               @v_tclase               = @w_tclase,
               @v_tipo_cifras          = @w_tipo_cifras,
               @v_numero_cifras        = @w_numero_cifras,
               @v_fec_inicio           = @w_fec_inicio,
               @v_fec_vencimiento      = @w_fec_vencimiento,
               @v_calificacion         = @w_calificacion,
               @v_vigencia             = @w_verificacion,
               @v_fecha_ver            = @w_fecha_ver,
               @v_fecha_modificacion   = @w_fecha_modificacion,
               @v_observacion          = @w_observacion,
               @v_estatus              = @w_estatus
   
   if @w_banco = @i_banco
      select @w_banco = null, @v_banco = null
   else
      select @w_banco = @i_banco
   if @w_toperacion  = @i_operacion
      select @w_toperacion = null, @v_toperacion = null
   else
      select @w_toperacion = @i_operacion
   if @w_tclase = @i_tclase
      select @w_tclase = null, @v_tclase = null
   else
      select @w_tclase = @i_tclase
   if @w_tipo_cifras = @i_tipo_cifras
      select @w_tipo_cifras = null, @v_tipo_cifras = null
   else
      select @w_tipo_cifras = @i_tipo_cifras
   if @w_numero_cifras = @i_numero_cifras
      select @w_numero_cifras = null, @v_numero_cifras = null
   else
      select @w_numero_cifras = @i_numero_cifras
   if @w_fec_inicio = @i_fec_inicio
      select @w_fec_inicio = null, @v_fec_inicio = null
   else
      select @w_fec_inicio = @i_fec_inicio
   if @w_fec_vencimiento = @i_fec_vencimiento
      select @w_fec_vencimiento = null, @v_fec_vencimiento = null
   else
      select @w_fec_vencimiento = @i_fec_vencimiento
   if @w_calificacion = @i_calificacion
      select @w_calificacion = null, @v_calificacion = null
   else
      select @w_calificacion = @i_calificacion
   if @w_vigencia = @i_vigencia
      select @w_vigencia = null, @v_vigencia = null
   else
      select @w_vigencia = @i_vigencia
   if @w_verificacion = @i_verificacion
      select @w_verificacion = null--, @v_verificacion = null
   else
      select @w_verificacion = @i_verificacion
   if @w_fecha_ver = @i_fecha_ver
      select @w_fecha_ver = null--, @v_fecha_ver = null
   else
      select @w_fecha_ver = @i_fecha_ver
   if @w_fecha_modificacion = @i_fecha_modificacion
      select @w_fecha_modificacion = null, @v_fecha_modificacion = null
   else
      select @w_fecha_modificacion = @i_fecha_modificacion
   if @w_observacion = @i_observacion
      select @w_observacion = null, @v_observacion = null
   else
     select @w_observacion = @i_observacion
   if @w_estatus = @i_estatus
      select @w_estatus = null ,@v_estatus= null
   else
      select @w_estatus = @i_estatus
   
   begin tran
           /* modificar los datos actuales */
   
      update cl_financiera
      set     institucion         = @i_banco,
              toperacion          = @i_toperacion,
              tclase              = @i_tclase,
              tipo_cifras         = @i_tipo_cifras,
              numero_cifras       = @i_numero_cifras,
              fec_inicio          = @i_fec_inicio,
              fec_vencimiento     = @i_fec_vencimiento,
              calificacion        = @i_calificacion,
              vigencia            = 'S',
              verificacion        = @i_verificacion,
              fecha_ver           = @i_fecha_ver,
              fecha_modificacion  = @w_today,
              observacion         = @i_observacion,
              estatus             = @i_estatus
      where  cliente= @i_ente
      and    referencia = @i_referencia
          /* si no se puede modificar, error */
      if @@error != 0
      begin
         exec sp_cerror
   
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 1720501
            /* 'Error en actualizacion de referencia financiera'*/
         return 1
      end
   
      /*if @i_verificacion = "S"
   
      begin
   
          update  cl_financiera
          set verificacion = @i_verificacion, funcionario = @s_user
              where  cliente = @i_ente
              and    referencia = @i_referencia
   
              --si no se puede modificar, error
   
          if @@error != 0
   
          begin
   
              exec sp_cerror
   
              @t_debug    = @t_debug,
              @t_file     = @t_file,
              @t_from     = @w_sp_name,
              @i_num      = 105067
   
                --'Error en actualizacion de referencia financiera'
   
              return 1
   
          end
   
      end */
   
      /* Transaccion servicios - cl_financiera */
   
      insert into ts_referencia(secuencial,        tipo_transaccion,   clase,
                               fecha,              usuario,            terminal,
                               srv,                lsrv,               ente,
                               referencia,         tipo,               banco,
                               toperacion,         tclase,             tipo_cifras,
                               numero_cifras,      fec_inicio,         fec_vencimiento,
                               calificacion,       vigencia,           verificacion,
                               fecha_ver,          fecha_modificacion, observacion,
                               estatus)
                       values (@s_ssn,             @t_trn,             'P',
                               @s_date,            @s_user,            @s_term,
                               @s_srv,             @s_lsrv,            @i_ente,
                               @i_referencia,      'F',                @v_banco,
                               @v_toperacion,      @v_tclase,          @v_tipo_cifras,
                               @v_numero_cifras,   @v_fec_inicio,      @v_fec_vencimiento,
                               @v_calificacion,    @i_vigencia,        @v_verificacion, @v_fecha_ver,
                               @s_date,            @v_observacion,     @v_estatus)
   
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
      /* Transaccion servicios - cl_financiera */
      insert into ts_referencia(secuencial,        tipo_transaccion,   clase,
                               fecha,              usuario,            terminal,
                               srv,                lsrv,               ente,
                               referencia,         tipo,               banco,
                               toperacion,         tclase,             tipo_cifras,
                               numero_cifras,      fec_inicio,         fec_vencimiento,
                               calificacion,       vigencia,           verificacion,
                               fecha_ver,          fecha_modificacion, observacion,
                               estatus)
                       values (@s_ssn,             @t_trn,             'A',
                               @s_date,            @s_user,            @s_term,
                               @s_srv,             @s_lsrv,            @i_ente,
                               @i_referencia,      'F',                @w_banco,
                               @w_toperacion,      @w_tclase,          @w_tipo_cifras,
                               @w_numero_cifras,   @w_fec_inicio,      @w_fec_vencimiento,
                               @w_calificacion,    @i_vigencia,        @i_verificacion,
                               @i_fecha_ver,       @s_date,            @w_observacion,
                               @w_estatus)
   
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

/* QUERY */
if @i_operacion = 'S'
begin
/* DATOS DE REFERENCIA FINANCIERA */
   select  'REFERENCIA'          = referencia,    
           'CLIENTE'             = cliente,
           'BANCO'               = institucion,         
           'NOMBRE BANCO'        = ba.ba_nombre,       
           'TIPO DE OPERACION'   = toperacion,
           'TIPO DE CLASE'       = tclase, 
           'ESTADO'              = estatus,        
           'FECHA INICIO'        = (select format (fec_inicio, 'dd/MM/yyyy HH:mm:ss') as date),  
           'FECHA VENCIMIENTO'   = (select format (fec_vencimiento, 'dd/MM/yyyy HH:mm:ss') as date),          
           'NUMERO CIFRAS'       = numero_cifras,  
           'TIPO CIFRAS'         = tipo_cifras,   
           'CALIFICACION'        = calificacion,     
           'OBSERVACION'         = observacion
      from cl_financiera a join cob_bancos..ba_banco ba on ba.ba_codigo = a.institucion    
      where a.cliente = @i_ente and treferencia = @i_treferencia
      
   if @@rowcount = 0
   begin
       exec sp_cerror
       @t_debug    = @t_debug,
       @t_file     = @t_file,
       @t_from     = @w_sp_name,
       @i_num      = 1720019
       return 1
   end
   return 0
end

/** Delete **/

if @i_operacion = 'D'
begin
    /* Captura de campos para transaccion de servicios */
   
   select  @w_banco                = institucion,
           @w_toperacion           = toperacion,
           @w_tclase               = tclase,
           @w_tipo_cifras          = tipo_cifras,
           @w_numero_cifras        = numero_cifras,
           @w_fec_inicio           = fec_inicio,
           @w_fec_vencimiento      = fec_vencimiento,
           @w_calificacion         = calificacion,
           @w_vigencia             = verificacion,
           @w_fecha_ver            = fecha_ver,
           @w_fecha_modificacion   = fecha_modificacion,
           @w_observacion          = observacion,
           @w_estatus              = estatus
   
       from cl_financiera
       where cliente = @i_ente
      and referencia = @i_referencia
   
   /* si no existe referencia financiera, error */
   
   if @@rowcount = 0
   
   begin
   
   exec sp_cerror
   
      @t_debug  = @t_debug,
      @t_file   = @t_file,
      @t_from   = @w_sp_name,
      @i_num    = 1720500
   
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
             @i_num      = 1720502
            /* 'Error en disminucion de referencia '*/
         return 1
      end
   
      /* borrar la referencia */
   
      delete from cl_financiera
       where cliente = @i_ente
       and referencia = @i_referencia
   
      /* si no se puede borrar, error */
   
      if @@error != 0
      begin
   
         exec sp_cerror
      
             @t_debug    = @t_debug,
             @t_file     = @t_file,
             @t_from     = @w_sp_name,
             @i_num      = 1720503
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
             @i_num      = 1720505
      
           --  'Error en eliminacion de referencia '
      
         return 1
      end
      */
      /* Transaccion servicios - cl_referencia */
      insert into ts_referencia   (secuencial,        tipo_transaccion,   clase,
                                  fecha,              usuario,            terminal,
                                  srv,                lsrv,               ente,
                                  referencia,         tipo,               banco,
                                  toperacion,         tclase,             tipo_cifras,
                                  numero_cifras,      fec_inicio,         fec_vencimiento,
                                  calificacion,       vigencia,           verificacion,
                                  fecha_ver,          fecha_modificacion, observacion,
                                  estatus)
                          values (@s_ssn,             @t_trn,             'B',
                                  @s_date,            @s_user,            @s_term,
                                  @s_srv,             @s_lsrv,            @i_ente,
                                  @i_referencia,      'F',                @i_banco,
                                  @i_toperacion,      @i_tclase,          @i_tipo_cifras,
                                  @i_numero_cifras,   @i_fec_inicio,      @i_fec_vencimiento,
                                  @i_calificacion,    @i_vigencia,        @i_verificacion,
                                  @i_fecha_ver,       @s_date,            @i_observacion,
                                  @i_estatus)
   
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
