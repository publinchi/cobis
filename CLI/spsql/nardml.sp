/************************************************************************/
/*  Archivo:            nardml.sp										*/
/*  Stored procedure:   sp_narcos_dml									*/
/*  Base de datos:      cobis                                           */
/*  Producto: 			Clientes                                        */
/*  Disenado por:  		Banco de Prestamos                              */
/*  Fecha de escritura: 03-Abr-1995                                     */
/************************************************************************/
/*              IMPORTANTE                                              */
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
/*  Este stored procedure procesa:                                      */
/*  Insert y Update de datos de Narcos                                 	*/
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*	26/01/2021	I.Yupa		CLI-S412373-PRD- Malas Referencias			*/
/************************************************************************/
use cobis
go
if exists (select * from sysobjects where name = 'sp_narcos_dml')
   drop proc sp_narcos_dml
go
create proc sp_narcos_dml (
			@s_culture		varchar(10)   = 'NEUTRAL',
			@s_ssn          int         = null,
			@s_user         login       = null,
			@s_term         varchar(30) = null,
			@s_date         datetime    = null,
			@s_srv          varchar(30) = null,
			@s_lsrv         varchar(30) = null,
			@s_ofi          smallint    = null,
			@s_rol          smallint 	= NULL,
			@s_org_err      char(1) 	= NULL,
			@s_error        int 		= NULL,
			@s_sev          tinyint 	= NULL,
			@s_msg          descripcion = NULL,
			@s_org          char(1) 	= NULL,
			@t_show_version	bit         = 0,    -- MOSTRAR LA VERSION DEL PROGRAMA
			@t_debug        char(1)     = 'N',
			@t_file         varchar(10) = null,
			@t_from         varchar(32) = null,
			@t_trn          int 	= null,
			@i_operacion    char(1),
			@i_modo			tinyint   	= null,
			@i_tipo         char(1)   	= "N",
			@i_nombre       varchar(40) = null,
			@i_cedula       char(13) 	= null,
			@i_pasaporte    char(20) 	= null,
			@i_nacionalidad	char(20) 	= null,
			@i_circular		char(12) 	= null,
			@i_fecha		char(12) 	= null,
			@i_provincia	char(15) 	= null,
			@i_juzgado		char(10) 	= null,
			@i_juicio		char(10) 	= null,
			@i_codigo		int 		= null
	)
	as
	declare @w_today            datetime,
			@w_sp_msg           varchar(132),
			@w_sp_name          varchar(32),
			@w_return           int,
			@w_nombre           varchar(40),
			@w_cedula           char(13),
			@w_pasaporte        char(20),
			@w_nacionalidad	    char(20),
			@w_circular	    char(12),
			@w_fecha     	    char(12),
			@w_provincia	    char(15),
			@w_juzgado	    char(10),
			@w_juicio	    char(10),
			@w_codigo	    int, 
			@v_nombre           varchar(40),
			@v_cedula           char(13),
			@v_pasaporte        char(20),
			@v_nacionalidad	    char(20),
			@v_circular	    char(12),
			@v_fecha     	    char(12),
			@v_provincia	    char(15),
			@v_juzgado	    char(10),
			@v_juicio	    char(10),
			@v_codigo	    int 

select @w_today = getdate()
select @w_sp_name = 'sp_narcos_dml'
	
	/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out

	/* Insert */
If @i_operacion = 'I' 
begin
	if exists (select 1 from cl_narcos where na_narcos = @i_codigo)
    begin
	  exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num	 = 1720476
        return  1 
   end
   begin tran
   if @t_trn = 172153
    begin
/* Insertar un nuevo registro */
     insert into cl_narcos (na_nombre, na_cedula, na_pasaporte,na_nacionalidad,			na_circular,na_fecha,na_provincia,na_juzgado,na_juicio,
			na_narcos)
     		values(@i_nombre, @i_cedula, @i_pasaporte,@i_nacionalidad,
			@i_circular,@i_fecha,@i_provincia,@i_juzgado,@i_juicio,
			@i_codigo)
/* Si no se puede insertar enviar error*/
if @@error !=0
  begin
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num	 	 = 1720436,
	   @s_culture    = @s_culture
        return  1 
   end
/*Transaccion de Servicio*/
     Insert into ts_narcos (secuencial, tipo_transaccion,clase,fecha,
        			usuario, terminal, srv, lsrv,nombre,cedula,
				pasaporte,nacionalidad,circular,fecha_na,
				provincia,juzgado,juicio,codigo)
		values( @s_ssn, @t_trn, 'N', @s_date, @s_user,@s_term,@s_srv,
			@s_lsrv,@i_nombre,@i_cedula,@i_pasaporte,@i_nacionalidad			,@i_circular,
      			@i_fecha, @i_provincia, @i_juzgado, @i_juicio,@i_codigo)
/* Si no puede insertar , enviar el error*/
	if @@error !=0
  	begin
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num	     = 1720437,
	   @s_culture    = @s_culture
        return  1 
   	end
   end
else 
     begin
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num        = 1720417,
	   @s_culture    = @s_culture
	   /*  'No corresponde codigo de transaccion' */
	return 1
     end
  commit tran
end
/* Update */
If @i_operacion = 'U'
begin
 if @t_trn != 172154
     begin
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num        = 1720417,
	   @s_culture    = @s_culture
	   /*  'No corresponde codigo de transaccion' */
	return 1
     end
  else
    begin
/* Seleccionar campos de la tabla */
	Select 
		@w_nombre  = na_nombre,
		@w_cedula  = na_cedula,
		@w_pasaporte = na_pasaporte,
		@w_nacionalidad = na_nacionalidad,
		@w_circular = na_circular,
		@w_fecha  = na_fecha,
		@w_provincia = na_provincia,
		@w_juzgado = na_juzgado,
		@w_juicio =na_juicio,
		@w_codigo =na_narcos
	from cl_narcos
	where na_narcos = @i_codigo
       if @@rowcount= 0
	begin
	/* No existe dato solicitado */
     	  exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num        = 1720438,
	   @s_culture    = @s_culture
	return 1
       end
	Select 
		@v_nombre = @w_nombre,
		@v_cedula  = @w_cedula,
		@v_pasaporte = @w_pasaporte,
		@v_nacionalidad = @w_nacionalidad,
		@v_circular = @w_circular,
		@v_fecha  = @w_fecha,
		@v_provincia = @w_provincia,
		@v_juzgado = @w_juzgado,
		@v_juicio = @w_juicio,
		@v_codigo = @w_codigo
	if @w_nombre = @i_nombre
	   select @w_nombre = null, @v_nombre = null
	else
	   select @w_nombre = @i_nombre
	if @w_cedula = @i_cedula
	   select @w_cedula = null, @v_cedula = null
	else
	   select @w_cedula = @i_cedula
	if @w_pasaporte = @i_pasaporte
	   select @w_pasaporte = null, @v_pasaporte = null
	else
	   select @w_pasaporte = @i_pasaporte
	if @w_nacionalidad = @i_nacionalidad
	   select @w_nacionalidad = null, @v_nacionalidad = null
	else
	   select @w_nacionalidad = @i_nacionalidad
	if @w_circular = @i_circular
	   select @w_circular = null, @v_circular = null
	else
	   select @w_circular = @i_circular
	if @w_fecha = @i_fecha
	   select @w_fecha = null, @v_fecha = null
	else
	   select @w_fecha = @i_fecha
	if @w_provincia = @i_provincia
	   select @w_provincia = null, @v_provincia = null
	else
	   select @w_provincia = @i_provincia
	if @w_juzgado = @i_juzgado
	   select @w_juzgado = null, @v_juzgado = null
	else
	   select @w_juzgado = @i_juzgado
	if @w_juicio = @i_juicio
	   select @w_juicio = null, @v_juicio = null
	else
	   select @w_juicio = @i_juicio
	if @w_codigo = @i_codigo
	   select @w_codigo = null, @v_codigo = null
	else
	   select @w_codigo = @i_codigo
begin tran
/* Actualizar el registro */
     update cl_narcos 
	set	na_nombre = @i_nombre,
		na_cedula = @i_cedula,
		na_pasaporte = @i_pasaporte,
		na_nacionalidad = @i_nacionalidad,
		na_circular = @i_circular,
		na_fecha = @i_fecha,
		na_provincia  = @i_provincia,
		na_juzgado = @i_juzgado,
		na_juicio  = @i_juicio,
		na_narcos = @i_codigo
      where na_narcos = @i_codigo
  if @@rowcount != 1
    begin
	/* Error en actualizacion de registro covinco*/
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num	 = 1720439,
	   @s_culture    = @s_culture
        return  1 
     end
/*transaccion de servicios (registro previo*/
     Insert into ts_narcos (secuencial, tipo_transaccion,clase,fecha,
        			usuario, terminal, srv, lsrv,nombre,cedula,
				pasaporte,nacionalidad,circular,fecha_na,
				provincia,juzgado,juicio,codigo)
		values( @s_ssn, @t_trn, 'P', @s_date, @s_user,@s_term,@s_srv,
			@s_lsrv,@v_nombre,@v_cedula,@v_pasaporte,@v_nacionalidad			,@v_circular,
      			@v_fecha, @v_provincia, @v_juzgado, @v_juicio,@i_codigo)
/* Si no puede insertar , enviar el error*/
  if @@error != 0
    begin
	/* Error en creacion de transaccion de servicios  covinco*/
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num	 = 1720437,
	   @s_culture    = @s_culture
        return  1 
     end
			     
/*transaccion de servicios (registro actual)*/
     Insert into ts_narcos (secuencial, tipo_transaccion,clase,fecha,
        			usuario, terminal, srv, lsrv,nombre,cedula,
				pasaporte,nacionalidad,circular,fecha_na,
				provincia,juzgado,juicio,codigo)
		values( @s_ssn, @t_trn, 'A', @s_date, @s_user,@s_term,@s_srv,
			@s_lsrv,@w_nombre,@w_cedula,@w_pasaporte,@w_nacionalidad			,@w_circular,
      			@w_fecha, @w_provincia, @w_juzgado, @w_juicio,@i_codigo)
/* Si no puede insertar , enviar el error*/
  if @@error != 0
    begin
	/* Error en creacion de transaccion de servicios  covinco*/
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num	 = 1720437,
	   @s_culture    = @s_culture
        return  1 
     end
commit tran
      return  0 
 end
end
/* Delete */
If @i_operacion = 'D'
begin
 if @t_trn = 172155
 begin
/* Valores para transaccion de Servicios*/
	Select 
		@w_nombre = na_nombre,
		@w_cedula = na_cedula,
		@w_pasaporte = na_pasaporte,
		@w_nacionalidad = na_nacionalidad,
		@w_circular = na_circular,
		@w_fecha = na_fecha,
		@w_provincia  = na_provincia,
		@w_juzgado = na_juzgado,
		@w_juicio  = na_juicio,
		@w_codigo = na_narcos
	from cl_narcos
	where na_narcos = @i_codigo
/* Si no existe registro a borrar, error */
  if @@rowcount = 0
    begin
	/* Error no existe registro  */
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num	     = 1720438,
	   @s_culture    = @s_culture
        return  1 
   end
 begin tran
/* Eliminar el registro */
     delete  from cl_narcos
      where na_narcos = @i_codigo
/* Si no se puede eliminar enviar error*/
    if @@error !=0
      begin
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num	 = 1720440,
	   @s_culture    = @s_culture
        return  1 
      end
		
/*transaccion de servicios (eliminacion )*/
     Insert into ts_narcos (secuencial, tipo_transaccion,clase,fecha,
        			usuario, terminal, srv, lsrv,nombre,cedula,
				pasaporte,nacionalidad,circular,fecha_na,
				provincia,juzgado,juicio,codigo)
		values( @s_ssn, @t_trn, 'B', @s_date, @s_user,@s_term,@s_srv,
			@s_lsrv,@w_nombre,@w_cedula,@w_pasaporte,@w_nacionalidad			,@w_circular,
      			@w_fecha, @w_provincia, @w_juzgado, @w_juicio,@i_codigo)
/* Si no puede insertar , enviar el error*/
	if @@error !=0
  	begin
		/*Error en creacion de transaccion de servicios */
		exec cobis..sp_cerror
	   	@t_debug      = @t_debug,
	   	@t_file       = @t_file,
	   	@t_from       = @w_sp_name,
	   	@i_num	 = 1720437,
	    @s_culture    = @s_culture
        	return  1 
   	end
     commit tran
 end
else
     begin
	exec cobis..sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num        = 1720417,
	   @s_culture    = @s_culture
	   /*  'No corresponde codigo de transaccion' */
	return 1
     end
end
go
