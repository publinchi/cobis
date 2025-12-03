/**********************************************************************/
/*  Archivo:                 control_empresas_rfe.sp                  */
/*  Stored procedure:        sp_control_empresas_rfe                  */
/*  Base de datos:           cobis                                    */
/*  Producto:                CLIENTES                                 */
/*  Disenado por:            N. Rosero                                */
/*  Fecha de escritura:      18-Jun-2020                              */
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
/*  Este programa procesa las transacciones de mantenimiento de las   */
/*  empresas donde un cliente con residencia fiscal, ejerce control,  */
/*  esta es información para FATCA.                                   */
/**********************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
             from sysobjects
            where name = 'sp_control_empresas_rfe')
  drop proc sp_control_empresas_rfe 
go

create proc sp_control_empresas_rfe (
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
       @i_compania                   int                           = null,
       @i_tipo_identificacion        varchar(10)                   = null, -- Codigo referencia
       @i_tipo_desc                  varchar(255)                  = null, -- Descripcion referencia
       @i_identificacion             varchar(255)                  = null,  -- Descripcion pais                 
       @i_tipo_control               varchar(255)                  = null,                      
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
        @w_ente                      int,
        @w_compania                  int,          
        @w_tipo_identificacion       int,         
        @w_identificacion            varchar(255),
        @w_vigencia                  char(1), 
        @w_tipo_control              varchar(255),   
        @w_verificacion              char(1),
        @v_vigencia                  char(1),             
        @v_verificacion              char(1),
        @v_tipo_control              varchar(255), 
        @w_sp_msg                    varchar(255),
        @w_ea_ejerce_control         char(1),
        @v_ea_ejerce_control         char(1),
        @w_count                     int,
        @w_subtipo		             char(1),
        @w_num                       int,
        @w_param                     int, 
        @w_diff                      int,
        @w_date                      datetime,
        @w_bloqueo                   char(1)
  
select @w_sp_name = 'sp_control_empresas_rfe'

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
   select @w_param         = pa_int      from cobis..cl_parametro where pa_nemonico = 'MVROC'  and pa_producto = 'CLI'
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

--INSERTA LA DIRECCION
if @i_operacion = 'I'
  begin
    --EVALUACION DEL TIPO DE TRANSACCION 
    if @t_trn <> 172044
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
    --print 'SE INSERTA LA DIRECCION'
    insert into cobis..cl_control_empresas_rfe--quitar ce_tipo_identificacion,       ce_identificacion,
           (ce_ente,                      ce_compania,                  ce_tipo_control,               ce_fecha_registro,            
		    ce_fecha_modificacion,        ce_vigencia,                  ce_verificacion,               ce_funcionario)
    values (@i_ente,                      @i_compania,                 @i_tipo_control,                @s_date,
        	@s_date,                      'S',                          'N',                           @s_user )
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
      
    --TRANSACCION SERVICIOS - cobis..ts_control_empresas_rfe
    insert into cobis..ts_control_empresas_rfe
           (secuencial,                   tipo_transaccion,             clase,                        fecha,
            usuario,                      terminal,                     srv,                          lsrv,
            ente,                         compania,                     tipo_control,                 vigencia, 
			verificacion)                               
    values (@s_ssn,                       @t_trn,                       'N',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @i_ente,                      @i_compania,                 @i_tipo_control,               'S',
			'N')
    if @@error <> 0
      begin
        --Error en creacion de transaccion de servicio
        exec cobis..sp_cerror
             @t_debug   = @t_debug,
             @t_file    = @t_file,
             @t_from    = @w_sp_name,
             @i_num     = 1720049
        return 1720049
      end
    
    select @w_subtipo=en_subtipo  
      from cobis..cl_ente_aux ,cobis..cl_ente 
     where ea_ente =en_ente 
       and ea_ente=@i_ente
	if  @w_subtipo = 'P'  
	  begin
	    select @w_ea_ejerce_control    = ea_ejerce_control      
          from cobis..cl_ente_aux 
         where ea_ente = @i_ente
        if @@rowcount = 0 
          begin
            if @i_batch = 'N'
              begin
               --ERROR NO EXISTEN REGISTROS
                exec cobis..sp_cerror
                     @t_debug   = @t_debug,
                     @t_file    = @t_file,
                     @t_from    = @w_sp_name,
                     @i_num     = 1720250
                return 1720250
              end
            else
              return 1720250
           end  
     
      select @v_ea_ejerce_control = @w_ea_ejerce_control 
      select @w_ea_ejerce_control = 'S'
       
      update cobis..cl_ente_aux 
         set ea_ejerce_control=@w_ea_ejerce_control
       where ea_ente   = @i_ente
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
    
      insert into ts_persona_sec
             (secuencia,                    tipo_transaccion,             clase,                        fecha,
              usuario,                      terminal,                     srv,                          lsrv,
              persona,                      ejerce_control )
      values (@s_ssn,                       @t_trn,                       'P',                          @s_date,
              @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
              @i_ente,                      @v_ea_ejerce_control )
      if @@error <> 0
        begin
          --Error en creacion de transaccion de servicio
          exec cobis..sp_cerror
               @t_debug   = @t_debug,
               @t_file    = @t_file,
               @t_from    = @w_sp_name,
               @i_num     = 1720049
          return 1720049
        end    
   
      insert into ts_persona_sec
             (secuencia,                    tipo_transaccion,             clase,                        fecha,
              usuario,                      terminal,                     srv,                          lsrv,
              persona,                      ejerce_control )
      values (@s_ssn,                       @t_trn,                       'A',                          @s_date,
              @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
              @i_ente,                      @w_ea_ejerce_control )
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
	 end
    commit tran     
  end


--ACTUALIZA LA DIRECCION
if @i_operacion = 'U'
  begin
    --EVALUACION DEL TIPO DE TRANSACCION 
    if @t_trn <> 172044 
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end

    select @w_tipo_control          =  ce_tipo_control,
           @w_vigencia              =  ce_vigencia,
           @w_verificacion          =  ce_verificacion
      from cobis..cl_control_empresas_rfe
     where ce_ente                  =  @i_ente
       and ce_compania              =  @i_compania
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
     
    select @v_tipo_control          =  @w_tipo_control,
           @v_vigencia              =  @w_vigencia,
           @v_verificacion          =  @w_verificacion  
    
    if @w_tipo_control = @i_tipo_control
      select @w_tipo_control = null, 
             @v_tipo_control = null
    else
      select @w_tipo_control = @i_tipo_control 

    if @w_vigencia = @i_vigencia
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
    update cobis..cl_control_empresas_rfe
       set ce_tipo_control         = @i_tipo_control,
            ce_fecha_modificacion   = @s_date,
            ce_vigencia             = @i_vigencia,
            ce_verificacion         = @i_verificacion      
      where ce_ente                 = @i_ente
        and ce_compania             = @i_compania 
    if @@error <> 0
      begin
        if @i_batch = 'N'
          begin
            --ERROR EN ACTUALIZACION DE Registro
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

    /* transaccion de servicio */
    insert into cobis..ts_control_empresas_rfe
           (secuencial,                   tipo_transaccion,             clase,                        fecha,
            usuario,                      terminal,                     srv,                          lsrv,
            ente,                         compania,                     tipo_control,                 vigencia,
			verificacion)                               
    values (@s_ssn,                       @t_trn,                       'P',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @i_ente,                      @i_compania,                  @v_tipo_control,              @v_vigencia,
			@v_verificacion)
    if @@error <> 0
      begin
        --Error en creacion de transaccion de servicio
        exec cobis..sp_cerror
             @t_debug   = @t_debug,
             @t_file    = @t_file,
             @t_from    = @w_sp_name,
             @i_num     = 1720049
        return 1720049
      end
          
    insert into cobis..ts_control_empresas_rfe
           (secuencial,                   tipo_transaccion,             clase,                        fecha,
            usuario,                      terminal,                     srv,                          lsrv,
            ente,                         compania,                     tipo_control,                 vigencia, 
			verificacion)                               
    values (@s_ssn,                       @t_trn,                       'A',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @i_ente,                      @i_compania,                  @w_tipo_control,              @w_vigencia, 
			@w_verificacion)
    if @@error <> 0
      begin
        --Error en creacion de transaccion de servicio
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
    if @t_trn <> 172044
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end
        
    select @w_ente                  =  ce_ente,
	       @w_compania              =  ce_compania,
           @w_tipo_control          =  ce_tipo_control,
           @w_vigencia              =  ce_vigencia,
           @w_verificacion          =  ce_verificacion
      from cobis..cl_control_empresas_rfe
     where ce_ente                  =  @i_ente
       and ce_compania              =  @i_compania
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
    delete cobis..cl_control_empresas_rfe 
     where ce_ente                  =  @i_ente
       and ce_compania              =  @i_compania
    if @@error <> 0
      begin
        if @i_batch = 'N'
          begin
            --ERROR EN ELIMINACION DEL REGISTRO
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

    insert into cobis..ts_control_empresas_rfe
           (secuencial,                   tipo_transaccion,             clase,                        fecha,
            usuario,                      terminal,                     srv,                          lsrv,
            ente,                         compania,                     tipo_control,                 vigencia,  
			verificacion)                               
    values (@s_ssn,                       @t_trn,                       'B',                          @s_date,
            @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
            @w_ente,                      @w_compania,                  @w_tipo_control,              @w_vigencia, 
			@w_verificacion)
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
 
    select @w_subtipo=en_subtipo  
      from cobis..cl_ente_aux ,cobis..cl_ente 
     where ea_ente =en_ente 
       and ea_ente=@i_ente
	if  @w_subtipo = 'P'  
	  begin
	    select @w_count=count(*) 
          from cobis..cl_control_empresas_rfe 
         where ce_ente                  =  @i_ente
        
      if @w_count=0
        begin
          select  @w_ea_ejerce_control    = ea_ejerce_control      
            from  cobis..cl_ente_aux 
           where  ea_ente   = @i_ente
          if @@rowcount = 0 
            begin
              if @i_batch = 'N'
                begin
                  --ERROR NO EXISTEN REGISTROS
                  exec cobis..sp_cerror
                       @t_debug   = @t_debug,
                       @t_file    = @t_file,
                       @t_from    = @w_sp_name,
                       @i_num     = 1720250
                  return 1720250
                end
              else
                return 1720250
            end  
            
        select @v_ea_ejerce_control = @w_ea_ejerce_control 
        select @w_ea_ejerce_control = 'N'
     
        update cobis..cl_ente_aux 
           set ea_ejerce_control=@w_ea_ejerce_control
         where ea_ente   = @i_ente
        if @@error <> 0
          begin
            if @i_batch = 'N'
              begin
                --ERROR EN ACTUALIZACION DE Registro
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
    
        insert into ts_persona_sec
               (secuencia,                    tipo_transaccion,             clase,                    fecha,
                usuario,                      terminal,                     srv,                      lsrv,
                persona,                      ejerce_control )
        values (@s_ssn,                       @t_trn,                       'P',                      @s_date,
                @s_user,                      @s_term,                      @s_srv,                   @s_lsrv,
                @i_ente,                      @v_ea_ejerce_control )
    
        if @@error <> 0
          begin
            --Error en creacion de transaccion de servicio
            exec cobis..sp_cerror
                 @t_debug   = @t_debug,
                 @t_file    = @t_file,
                 @t_from    = @w_sp_name,
                 @i_num     = 1720049
            return 1720049
          end    
   
        insert into ts_persona_sec
               (secuencia,                    tipo_transaccion,             clase,                        fecha,
                usuario,                      terminal,                     srv,                          lsrv,
                persona,                      ejerce_control)
        values (@s_ssn,                       @t_trn,                       'A',                          @s_date,
                @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
                @i_ente,                      @w_ea_ejerce_control)
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
      end	  
      commit tran 
      end 
  end

-- CONSULTA EMPRESAS CON RESIDENCIA FISCAL EXTRANJERA
if @i_operacion = 'S'
  begin
    --EVALUACION DEL TIPO DE TRANSACCION 
    if @t_trn <> 172044
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end
    
    select ce_ente,
           ce_compania,
           ce_tipo_control,
           ce_fecha_registro,
           ce_fecha_modificacion,
           ce_vigencia,
           ce_verificacion,
           ce_funcionario
      from cobis..cl_control_empresas_rfe
     where ce_ente                = @i_ente
         
  end

return 0
go