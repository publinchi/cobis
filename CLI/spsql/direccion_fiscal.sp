/*********************************************************************/
/*  Archivo:                 direccion_fiscal.sp                      */
/*  Stored procedure:        sp_direccion_fiscal                      */
/*  Base de datos:           cobis                                    */
/*  Producto:                CLIENTES                                 */
/*  Disenado por:            N. Rosero                                */
/*  Fecha de escritura:      16-Jun-2020                              */
/**********************************************************************/
/*                           IMPORTANTE                               */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad      */
/*  de COBISCorp.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como  */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus  */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp  */
/*  Este programa esta protegido por la ley de   derechos de autor    */
/*  y por las    convenciones  internacionales   de  propiedad inte-  */
/*  lectual.   Su uso no  autorizado dara  derecho a COBISCorp para   */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir      */
/*  penalmente a los autores de cualquier   infraccion.               */
/**********************************************************************/
/*                            PROPOSITO                               */
/*  Este programa procesa las transacciones de mantenimiento de di-   */
/*  recciones fiscales, para el registro de informacion FATCA y CRS.  */
/**********************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
             from sysobjects
            where name = 'sp_direccion_fiscal')
  drop proc sp_direccion_fiscal 
go

create proc sp_direccion_fiscal (
       @s_ssn                        int,
       @s_user                       login                         = null,
       @s_sesn                       int                           = null,
       @s_culture                    varchar(10)                   = null,
       @s_term                       varchar(32)                   = null,
       @s_date                       datetime,
       @s_srv                        varchar(30)                   = null,
       @s_lsrv                       varchar(30)                   = null,
       @s_ofi                        smallint                      = NULL,
       @s_rol                        smallint                      = NULL,
       @s_org_err                    char(1)                       = NULL,
       @s_error                      int                           = NULL,
       @s_sev                        tinyint                       = NULL,
       @s_msg                        descripcion                   = NULL,
       @s_org                        char(1)                       = NULL,
       @t_debug                      char(1)                       = 'N',
       @t_file                       varchar(10)                   = null,
       @t_from                       varchar(32)                   = null,
       @t_trn                        int                           = null,
       @i_operacion                  char(1),                      -- Opcion con la que se ejecuta el programa
       @i_ente                       int                           = null, -- Codigo secuencial del cliente
       @i_sec                        tinyint                       = null,
       @i_tipo                       varchar(10)                   = null,        -- Codigo referencia
       @i_pais                       int                           = null,-- Codigo pais
       @i_codigo_postal              varchar(30)                   = null,
       @i_provincia                  varchar(255)                  = null,
       @i_ciudad                     varchar(255)                  = null,     
       @i_calle_principal            varchar(255)                  = null,     
       @i_conjunto_edificio          varchar(255)                  = null,    
       @i_num_piso                   varchar(255)                  = null,     
       @i_oficina_departamento       varchar(255)                  = null,     
       @i_barrio                     varchar(255)                  = null,     
       @i_direccion_completa         varchar(255)                  = null,    
       @i_fecha_registro             datetime                      = null,            
       @i_fecha_modificacion         datetime                      = null,            
       @i_vigencia                   char(1)                       = null,             
       @i_verificacion               char(1)                       = null,             
       @i_funcionario                varchar(255)                  = null,
       @i_batch                      char(1)                       = 'N',
       @o_sec                        tinyint                       = null out,
       @t_show_version               bit                           = 0
)
as
declare @w_transaccion               int,
        @w_sp_name                   varchar(32),
        @w_codigo                    int,
        @w_error                     int,
        @w_return                    int,
        @w_codigo_postal             int,                 
        @w_provincia                 varchar(255),        
        @w_ciudad                    varchar(255),        
        @w_calle_principal           varchar(255),        
        @w_conjunto_edificio         varchar(255),        
        @w_num_piso                  varchar(255),        
        @w_oficina_departamento      varchar(255),        
        @w_barrio                    varchar(255),        
        @w_direccion_completa        varchar(255),        
        @w_vigencia                  char(1),             
        @w_verificacion              char(1),
        @v_vigencia                  char(1),             
        @v_verificacion              char(1),
        @v_codigo_postal             int,                 
        @v_provincia                 varchar(255),        
        @v_ciudad                    varchar(255),        
        @v_calle_principal           varchar(255),        
        @v_conjunto_edificio         varchar(255),        
        @v_num_piso                  varchar(255),        
        @v_oficina_departamento      varchar(255),        
        @v_barrio                    varchar(255),        
        @v_direccion_completa        varchar(255),        
        @w_sp_msg                    varchar(255),
        @w_sec                       tinyint     
  
select @w_sp_name = 'sp_direccion_fiscal'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
  begin
    select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
    select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
    print  @w_sp_msg
    return 0
  end

--INSERTA LA DIRECCION
if @i_operacion = 'I'
  begin
    --EVALUACION DEL TIPO DE TRANSACCION 
    if @t_trn <> 172001 
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end  

    select @w_sec  = count(1) + 1
      from cl_direccion_fiscal
     where df_ente = @i_ente 

    begin tran 
     
    insert into cobis..cl_direccion_fiscal
           (df_ente,                      df_sec,                       df_tipo,                      df_pais, 
            df_codigo_postal,             df_provincia,                 df_ciudad,                    df_calle_principal,
            df_conjunto_edificio,         df_num_piso,                  df_oficina_departamento,      df_barrio,
            df_direccion_completa,        df_fecha_registro,            df_fecha_modificacion,        df_vigencia,
            df_verificacion,              df_funcionario)
    values (@i_ente,                      @w_sec,                       @i_tipo,                      @i_pais,
            @i_codigo_postal,             @i_provincia,                 @i_ciudad,                    @i_calle_principal,
            @i_conjunto_edificio,         @i_num_piso,                  @i_oficina_departamento,      @i_barrio,
            @i_direccion_completa,        @s_date,                      @s_date,                      'S',
            'N',                          @s_user)
    if @@error <> 0
      begin
        if @i_batch = 'N'
          begin
            exec cobis..sp_cerror
               @t_debug   = @t_debug,
               @t_file    = @t_file,
               @t_from    = @w_sp_name,
               @i_num     = 1720046
               --ERROR EN LA INSERSION DEL REGISTRO
            return 1720046
          end
        else
          return 1720046
      end

    --TRANSACCION SERVICIOS - cobis..cl_direccion_fiscal
    insert into cobis..ts_direccion_fiscal
           (secuencial,                   tipo_transaccion,             clase,                        fecha,
            usuario,                      terminal,                     srv,                          lsrv,
            ente,                         sec_ente,                     tipo_direccion,               pais,
            codpostal,                    provincia,                    ciudad,                       calle_principal,
            con_edificio,                 num_piso,                     oficina_departamento,         barrio, 
            dir_completa,                 vigencia,                     verificacion)
    values (@s_ssn,                       @t_trn,                       'N',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @i_ente,                      @w_sec,                       @i_tipo,                      @i_pais,
            @i_codigo_postal,             @i_provincia,                 @i_ciudad,                    @i_calle_principal,
            @i_conjunto_edificio,         @i_num_piso,                  @i_oficina_departamento,      @i_barrio,            
            @i_direccion_completa,        'S',                          'N')
    if @@error <> 0
      begin
        --Error en creaci+Ýn de transacci+Ýn de servicio
        exec cobis..sp_cerror
             @t_debug   = @t_debug,
             @t_file    = @t_file,
             @t_from    = @w_sp_name,
             @i_num     = 1720049
        return 1720049
      end
    commit tran
    select @o_sec = @w_sec
  end

--ACTUALIZA LA DIRECCION
if @i_operacion = 'U'
  begin
    --EVALUACION DEL TIPO DE TRANSACCION 
    if @t_trn <> 172001
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end

    select @w_codigo_postal         =  df_codigo_postal,
           @w_provincia             =  df_provincia,
           @w_ciudad                =  df_ciudad,
           @w_calle_principal       =  df_calle_principal,
           @w_conjunto_edificio     =  df_conjunto_edificio,
           @w_num_piso              =  df_num_piso,
           @w_oficina_departamento  =  df_oficina_departamento,
           @w_barrio                =  df_barrio,
           @w_direccion_completa    =  df_direccion_completa,
           @w_vigencia              =  df_vigencia,
           @w_verificacion          =  df_verificacion
      from cobis..cl_direccion_fiscal
     where df_ente = @i_ente
       and df_pais = @i_pais
       and df_sec  = @i_sec
    if @@rowcount <> 1
      begin
        --ERROR NO EXISTEN REGISTROS
        exec cobis..sp_cerror
             @t_debug  = @t_debug,
             @t_file   = @t_file,
             @t_from   = @w_sp_name,
             @i_num    = 1720250
        
        return 1720250
      end
     
    select @v_codigo_postal         =  @w_codigo_postal,
           @v_provincia             =  @w_provincia,
           @v_ciudad                =  @w_ciudad, 
           @v_calle_principal       =  @w_calle_principal,
           @v_conjunto_edificio     =  @w_conjunto_edificio,
           @v_num_piso              =  @w_num_piso,
           @v_oficina_departamento  =  @w_oficina_departamento, 
           @v_barrio                =  @w_barrio,
           @v_direccion_completa    =  @w_direccion_completa,
           @v_vigencia              =  @w_vigencia,
           @v_verificacion          =  @w_verificacion  
    
    if @w_codigo_postal =  @i_codigo_postal
      select @w_codigo_postal = null,
             @v_codigo_postal = null
    else
      select @w_codigo_postal = @i_codigo_postal
    
    if @w_provincia =  @i_provincia
      select @w_provincia = null, 
             @v_provincia = null
    else
      select @w_provincia = @i_provincia
        
    if @w_ciudad =  @i_ciudad
      select @w_ciudad = null,
             @v_ciudad = null
    else
      select @w_ciudad = @i_ciudad

    if @w_calle_principal =  @i_calle_principal
      select @w_calle_principal = null,
             @v_calle_principal = null
    else
      select @w_calle_principal = @i_calle_principal

    if @w_conjunto_edificio  =  @i_conjunto_edificio 
      select @w_conjunto_edificio = null,
             @v_conjunto_edificio = null
    else
      select @w_conjunto_edificio = @i_conjunto_edificio 

    if @w_num_piso = @i_num_piso
      select  @w_num_piso = null,
              @v_num_piso = null
    else
      select  @w_num_piso = @i_num_piso

    if @w_oficina_departamento = @i_oficina_departamento
      select @w_oficina_departamento = null,
             @v_oficina_departamento = null
    else
      select @w_oficina_departamento = @i_oficina_departamento

    if @w_barrio = @i_barrio 
      select @w_barrio = null,
             @v_barrio = null
    else
      select @w_barrio = @i_barrio 

    if @w_direccion_completa = @i_direccion_completa
      select @w_direccion_completa = null,
             @v_direccion_completa = null
    else
      select @w_direccion_completa = @i_direccion_completa


    if @w_vigencia =  @i_vigencia
      select @w_vigencia = null, 
             @v_vigencia = null
    else
      select @w_vigencia = @i_vigencia 

    if @w_verificacion =  @i_verificacion
      select @w_verificacion = null, 
             @v_verificacion = null
    else
      select @w_verificacion = @i_verificacion      

    begin tran
    --print N'SE ACTUALIZA LA DIRECCION'
    update cobis..cl_direccion_fiscal
       set df_codigo_postal         = @i_codigo_postal,
           df_provincia             = @i_provincia,
           df_ciudad                = @i_ciudad, 
           df_calle_principal       = @i_calle_principal,
           df_conjunto_edificio     = @i_conjunto_edificio,
           df_num_piso              = @i_num_piso,
           df_oficina_departamento  = @i_oficina_departamento, 
           df_barrio                = @i_barrio,
           df_direccion_completa    = @i_direccion_completa,
           df_vigencia              = @i_vigencia,
           df_verificacion          = @i_verificacion      
     where df_ente                  = @i_ente
       and df_pais                  = @i_pais 
       and df_sec                   = @i_sec
    if @@error <> 0
      begin
        if @i_batch = 'N'
          begin
            --ERROR EN ACTUALIZACION DE DIRECCION
            exec cobis..sp_cerror
                 @t_debug   = @t_debug,
                 @t_file    = @t_file,
                 @t_from    = @w_sp_name,
                 @i_num     = 1720251

            return 1720251
          end
        else
          return 1720251
      end

    /* transaccion de servicio */
    insert into cobis..ts_direccion_fiscal
           (secuencial,                   tipo_transaccion,             clase,                        fecha,
            usuario,                      terminal,                     srv,                          lsrv,
            sec_ente,                     codpostal,                    provincia,                    ciudad,                       
            calle_principal,              con_edificio,                 num_piso,                     oficina_departamento,
            barrio,                       dir_completa,                 vigencia,                     verificacion)
    values (@s_ssn,                       @t_trn,                       'P',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @i_sec,                       @v_codigo_postal,             @v_provincia,                 @v_ciudad,
            @v_calle_principal,           @v_conjunto_edificio,         @v_num_piso,                  @v_oficina_departamento,
            @v_barrio,                    @v_direccion_completa,        @v_vigencia,                  @v_verificacion)
    if @@error <> 0
      begin
        --Error en creaci??e transacci??e servicio
        exec cobis..sp_cerror
             @t_debug   = @t_debug,
             @t_file    = @t_file,
             @t_from    = @w_sp_name,
             @i_num     = 1720049
        return 1720049
      end
      
    insert into cobis..ts_direccion_fiscal
           (secuencial,                   tipo_transaccion,             clase,                        fecha,
            usuario,                      terminal,                     srv,                          lsrv,
            sec_ente,                     codpostal,                    provincia,                    ciudad,
            calle_principal,              con_edificio,                 num_piso,                     oficina_departamento,         
            barrio,                       dir_completa,                 vigencia,                     verificacion)
    values (@s_ssn,                       @t_trn,                       'A',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @i_sec,                       @w_codigo_postal,             @w_provincia,                 @w_ciudad,                    
            @w_calle_principal,           @w_conjunto_edificio,         @w_num_piso,                  @w_oficina_departamento,
            @w_barrio,                    @w_direccion_completa,        @w_vigencia,                  @w_verificacion)
    if @@error <> 0
      begin
        --Error en creaci+Ýn de transacci+Ýn de servicio
        exec cobis..sp_cerror
             @t_debug   = @t_debug,
             @t_file    = @t_file,
             @t_from    = @w_sp_name,
             @i_num     = 1720049
        return 1720049
      end
   commit tran
  end


-- ELIMINA DIRECCION
if @i_operacion = 'D'
  begin
    --EVALUACION DEL TIPO DE TRANSACCION 
    if @t_trn <> 172001
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end
   
    if exists (select 1
                 from cobis..cl_direccion_geo
                where dg_ente      = @i_ente
                  and dg_direccion = @i_sec
                  and dg_tipo        = 'RF')
      begin
        -- ELIMINAR REGISTROS GEOREFERENCIACION
        exec @w_return = cobis..sp_direccion_geo
             @s_ssn          = @s_ssn,
             @s_date         = @s_date,
             @i_operacion    = 'D',
             @t_trn          = 1606,
             @i_ente         = @i_ente,
             @i_direccion    = @i_sec,
             @i_tipo         = 'RF'
        if @w_return <> 0
          begin
            --SI NO SE PUEDE BORRAR, ERROR
            exec cobis..sp_cerror 
                 @t_debug= @t_debug,
                 @t_file = @t_file,
                 @t_from = @w_sp_name,
                 @i_num  = 107056  
            return 1
          end
      end  
    
    select @w_codigo_postal         =  df_codigo_postal,
           @w_provincia             =  df_provincia,
           @w_ciudad                =  df_ciudad,
           @w_calle_principal       =  df_calle_principal,
           @w_conjunto_edificio     =  df_conjunto_edificio,
           @w_num_piso              =  df_num_piso,
           @w_oficina_departamento  =  df_oficina_departamento,
           @w_barrio                =  df_barrio,
           @w_direccion_completa    =  df_direccion_completa,
           @w_vigencia              =  df_vigencia,
           @w_verificacion          =  df_verificacion
      from cobis..cl_direccion_fiscal
     where df_ente = @i_ente
       and df_pais = @i_pais
       and df_sec  = @i_sec
    if @@rowcount <> 1
      begin
        --ERROR NO EXISTEN REGISTROS
        exec cobis..sp_cerror
             @t_debug  = @t_debug,
             @t_file   = @t_file,
             @t_from   = @w_sp_name,
             @i_num    = 1720250
        return 1720250
      end

    begin tran
    --print N'SE ELIMINA LA DIRECCION'
    
    delete cobis..cl_direccion_fiscal 
     where df_ente = @i_ente
       and df_pais = @i_pais
       and df_sec  = @i_sec
    if @@error <> 0
      begin
        if @i_batch = 'N'
          begin
            --ERROR EN ELIMINACION DE DIRECCION
            exec cobis..sp_cerror
                 @t_debug   = @t_debug,
                 @t_file    = @t_file,
                 @t_from    = @w_sp_name,
                 @i_num     = 1720125
            return 1720125
          end
        else
          return 1720125
      end

    insert into cobis..ts_direccion_fiscal
           (secuencial,               tipo_transaccion,              clase,                   fecha,
            usuario,                  terminal,                      srv,                     lsrv,
            sec_ente,                 codpostal,                     provincia,               ciudad,                  
            calle_principal,          con_edificio,                  num_piso,                oficina_departamento,    
            barrio,                   dir_completa,                  vigencia,                verificacion)
    values (@s_ssn,                   @t_trn,                        'B',                     @s_date,
            @s_user,                  @s_term,                       @s_srv,                  @s_lsrv,
            @i_sec,                   @w_codigo_postal,              @w_provincia,            @w_ciudad,               
            @w_calle_principal,       @w_conjunto_edificio,          @w_num_piso,             @w_oficina_departamento,                 
            @w_barrio,                @w_direccion_completa,         @w_vigencia,             @w_verificacion)
    if @@error <> 0
      begin
        --Error en creaci??e transacci??e servicio
        exec cobis..sp_cerror
             @t_debug   = @t_debug,
             @t_file    = @t_file,
             @t_from    = @w_sp_name,
             @i_num     = 1720049
        return 1720049
      end
    commit tran  
  end
    
-- CONSULTA DIRECCIONES 
if @i_operacion = 'S'
  begin
    --EVALUACION DEL TIPO DE TRANSACCION 
    if @t_trn <> 172001
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end

    select df_ente,
           df_tipo,
           df_pais,
           df_codigo_postal,
           df_provincia,
           df_ciudad,
           df_calle_principal,
           df_conjunto_edificio,
           df_num_piso,
           df_oficina_departamento,
           df_barrio,
           df_direccion_completa,
           (select dg_lat_seg from cobis..cl_direccion_geo where dg_ente = @i_ente and dg_direccion = df_sec),
           (select dg_long_seg from cobis..cl_direccion_geo where dg_ente = @i_ente and dg_direccion = df_sec),
           df_fecha_registro,
           df_fecha_modificacion,
           df_vigencia,
           df_verificacion,
           df_funcionario,
           df_sec
      from cobis..cl_direccion_fiscal
     where df_ente = @i_ente
       and df_pais = @i_pais
  end
 
return 0

go