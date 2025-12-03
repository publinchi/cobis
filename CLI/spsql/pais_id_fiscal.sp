/**********************************************************************/
/*  Archivo:                 pais_id_fiscal.sp                        */
/*  Stored procedure:        sp_pais_id_fiscal                        */
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
/*  Este programa procesa las transacciones de mantenimiento de       */
/*  Identificación en los paíes fiscales de residencia, para el     */
/*  registro de información FATCA y CRS.                              */
/**********************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
             from sysobjects
            where name = 'sp_pais_id_fiscal')
  drop proc sp_pais_id_fiscal 
go

create proc sp_pais_id_fiscal (
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
       @i_ente                       int,
       @i_pais                       int                           = null, -- Codigo pais
       @i_tipo                       varchar(30)                   = null, -- Codigo referencia
       @i_identificacion             varchar(255)                  = null, -- Descripcion pais 
       @i_fecha_registro             datetime                      = null,            
       @i_fecha_modificacion         datetime                      = null,            
       @i_vigencia                   char(1)                       = null,             
       @i_verificacion               char(1)                       = null,             
       @i_funcionario                varchar(255)                  = null,
       @t_show_version               bit                           = 0,
       @i_batch                      char(1)                       = 'N'  
)
as 
declare @w_transaccion               int,
        @w_sp_name                   varchar(32),
        @w_codigo                    int,
        @w_error                     int,
        @w_return                    int,
        @w_identificacion            varchar(255),
        @v_identificacion            varchar(255),
        @w_sp_msg                    varchar(255),
        @w_vigencia                  char(1),             
        @w_verificacion              char(1),
        @v_vigencia                  char(1),             
        @v_verificacion              char(1),
        @w_tipo                      varchar(30),
        @v_tipo                      varchar(30),
        @w_di_ente                   int,
        @w_di_pais                   int,
        @w_di_sec                    tinyint,
        @w_num                       int,
        @w_param                     int, 
        @w_diff                      int,
        @w_date                      datetime,
        @w_bloqueo                   char(1)
  
select @w_sp_name = 'sp_pais_id_fiscal'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
  begin
    select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
    select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
    print  @w_sp_msg
    return 0
  end   

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
--INSERT
if @i_operacion = 'I'
  begin
    --EVALUACION DEL TIPO DE TRANSACCION 
    if @t_trn <> 172035
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end
   begin tran
    insert into cobis..cl_pais_id_fiscal
           (pf_ente,                      pf_pais,                      pf_tipo,                      pf_identificacion,
            pf_fecha_registro,            pf_fecha_modificacion,        pf_vigencia,                  pf_verificacion,
            pf_funcionario)
    values (@i_ente,                      @i_pais,                      @i_tipo,                      @i_identificacion,
            @s_date,                      @s_date,                      'S',                          'N',       
            @s_user)
    if @@error <> 0
      begin
        if @i_batch = 'N'
          begin
            --ERROR EN LA INSERSION DEL REGISTRO
            exec cobis..sp_cerror
                 @t_debug   = @t_debug,
                 @t_file    = @t_file,
                 @t_from    = @w_sp_name,
                 @i_num     = 1720046
            return 1720046
          end
        else
          return 1720046
      end

    --TRANSACCION SERVICIOS - cobis..cl_pais_id_fiscal
    insert into  cobis..ts_pais_id_fiscal
           (secuencial,                   tipo_transaccion,             operacion,                    fecha, 
            usuario,                      terminal,                     srv,                          lsrv,         
            ente,                         pais,                         tipo,                         identificacion,  
            vigencia,                     verificacion)
    values (@s_ssn,                       @t_trn,                       'I',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @i_ente,                      @i_pais,                      @i_tipo,                      @i_identificacion,
            'S',                          'N')
    if @@error <> 0
      begin
       --Error en creaci?n de transacci?n de servicio
         exec cobis..sp_cerror
           @t_debug   = @t_debug,
           @t_file    = @t_file,
           @t_from    = @w_sp_name,
           @i_num     = 1720049
        return 1720049
      end
	commit tran  
  end

--UPDATE
if @i_operacion = 'U'
  begin
    if @t_trn <> 172035
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end
  
    select @w_identificacion        =  pf_identificacion,
           @w_vigencia              =  pf_vigencia,
           @w_verificacion          =  pf_verificacion
      from cobis..cl_pais_id_fiscal
     where pf_ente = @i_ente
       and pf_pais = @i_pais
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
   
    select @v_tipo                   =  @w_tipo,
	       @v_identificacion         =  @w_identificacion,
           @v_vigencia               =  @w_vigencia,
           @v_verificacion           =  @w_verificacion
		   
	if @w_tipo =  @i_tipo
      select @w_tipo = null,  
             @v_tipo = null
    else
      select @w_tipo = @i_tipo	   
 
    if @w_identificacion =  @i_identificacion
      select @w_identificacion = null,  
             @v_identificacion = null
    else
      select @w_identificacion = @i_identificacion
    
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
    update cobis..cl_pais_id_fiscal
       set pf_tipo                  =  @i_tipo,
	       pf_identificacion        =  @i_identificacion,
           pf_vigencia              =  @i_vigencia,
           pf_verificacion          =  @i_verificacion
     where pf_ente=@i_ente
       and pf_pais=@i_pais 
    if @@error <> 0
       begin
         if @i_batch = 'N'
           begin
             --ERROR EN ACTUALIZACION DE REGISTRO
             exec cobis..sp_cerror
                  @t_debug   = @t_debug,
                  @t_file    = @t_file,
                  @t_from    = @w_sp_name,
                  @i_num     = 1720252
                
             return 1720252
           end
         else
           return 1720252
       end

    --Creaci? de transacci? de servicio
    insert into  cobis..ts_pais_id_fiscal
           (secuencial,                   tipo_transaccion,             operacion,                    fecha, 
            usuario,                      terminal,                     srv,                          lsrv,         
            tipo,                         identificacion,               vigencia,                     verificacion)
    values (@s_ssn,                       @t_trn,                       'P',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @v_tipo,                       @v_identificacion,            @v_vigencia,                  @v_verificacion )
    if @@error <> 0
      begin
        --Error en creaci?n de transacci?n de servicio
        exec cobis..sp_cerror
             @t_debug   = @t_debug,
             @t_file    = @t_file,
             @t_from    = @w_sp_name,
             @i_num     = 1720049
       
        return 1720049
      end
   
    insert into  cobis..ts_pais_id_fiscal
           (secuencial,                   tipo_transaccion,             operacion,                    fecha, 
            usuario,                      terminal,                     srv,                          lsrv,         
            tipo,                         identificacion,               vigencia,                     verificacion)
    values (@s_ssn,                       @t_trn,                       'A',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @w_tipo,                      @w_identificacion,            @w_vigencia,                  @w_verificacion)
    if @@error <> 0
      begin
        --Error en creaci?n de transacci?n de servicio
        exec cobis..sp_cerror
          @t_debug   = @t_debug,
          @t_file    = @t_file,
          @t_from    = @w_sp_name,
          @i_num     = 1720049
        
        return 1720049
      end
	 commit tran  
  end
   
-- DELETE
if @i_operacion = 'D'
  begin
    if @t_trn <> 172035
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end 
    begin tran 	
------------------------------------------
   declare deleteAddress cursor for
    select  df_ente,
            df_pais,
            df_sec       
      from cobis..cl_direccion_fiscal
     where df_ente = @i_ente
       and df_pais = @i_pais
       
	
    open deleteAddress 
	fetch deleteAddress 
	into @w_di_ente, 
		 @w_di_pais,
		 @w_di_sec 
	while @@fetch_status = 0
	begin

      exec @w_return       = cobis..sp_direccion_fiscal
           @s_ssn          = @s_ssn,
           @s_date         = @s_date,
           @i_operacion    = 'D',
           @t_trn          = 172001,
           @i_ente         = @w_di_ente,
           @i_pais         = @w_di_pais,
           @i_sec          = @w_di_sec
      if @w_return <> 0
        begin
		  close deleteAddress 
	      deallocate deleteAddress 
        --SI NO SE PUEDE BORRAR, ERROR
          exec cobis..sp_cerror
                 @t_debug   = @t_debug,
                 @t_file    = @t_file,
                 @t_from    = @w_sp_name,
                 @i_num     = 1720125
            return 1720125
        end
        fetch  deleteAddress
      	into @w_di_ente, 
		     @w_di_pais,
		     @w_di_sec  
   
    end 
	close deleteAddress 
	deallocate deleteAddress 
------------------------------------------------------------	
    select @w_identificacion        =  pf_identificacion,
           @w_vigencia              =  pf_vigencia,
           @w_verificacion          =  pf_verificacion
      from cobis..cl_pais_id_fiscal
     where pf_ente = @i_ente
       and pf_pais = @i_pais
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
   
    delete cobis..cl_pais_id_fiscal 
     where pf_ente = @i_ente
       and pf_pais = @i_pais
    if @@error <> 0
      begin
        if @i_batch = 'N'
          begin
            exec cobis..sp_cerror
                 @t_debug   = @t_debug,
                 @t_file    = @t_file,
                 @t_from    = @w_sp_name,
                 @i_num     = 1720253
            return 1720253
          end
        else
          return 1720253
      end

    insert into  cobis..ts_pais_id_fiscal
           (secuencial,                   tipo_transaccion,             operacion,                    fecha, 
            usuario,                      terminal,                     srv,                          lsrv,         
            identificacion,               vigencia,                     verificacion)
    values (@s_ssn,                       @t_trn,                       'B',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @w_identificacion,            @w_vigencia,                  @w_verificacion)
    if @@error <> 0
      begin
        --Error en creaci?n de transacci?n de servicio
        exec cobis..sp_cerror
          @t_debug   = @t_debug,
          @t_file    = @t_file,
          @t_from    = @w_sp_name,
          @i_num     = 1720049
        return 1720049
      end
	commit tran 
  end
    
-- CONSULTA 
if @i_operacion = 'S'
  begin
    --EVALUACION DEL TIPO DE TRANSACCION 
    if @t_trn <> 172035
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end
  
    select pf_ente,
           pf_pais,
           pf_tipo,
           pf_identificacion,
           pf_fecha_registro,
           pf_fecha_modificacion,
           pf_vigencia,
           pf_verificacion,
           pf_funcionario
      from cobis..cl_pais_id_fiscal
     where pf_ente = @i_ente
      
  end
 
return 0
go