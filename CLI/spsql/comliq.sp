/********************************************************************/
/*   NOMBRE LOGICO:         sp_liquidacion_dml                      */
/*   NOMBRE FISICO:         comliq.sp                              */
/*   BASE DE DATOS:         cobis                                   */
/*   PRODUCTO:              Clientes                                */
/*   DISENADO POR:          S. Ortiz                                */
/*   FECHA DE ESCRITURA:    12-May-1995                             */
/********************************************************************/
/*              IMPORTANTE                                              */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*              PROPOSITO                                               */
/*  Este stored procedure procesa:                                      */
/*  Insert y Update de datos de companias en liquidacion                */
/*  Query de nombre completo de persona                                 */
/********************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*   12-May-1995    S. Ortiz.     Emision Inicial                   */
/*   25-Ene-2021    I. Yupa.      CLI-S412373-PRD- Malas Referencias*/
/*   08-Jun-2023    P. Jarrin.    Ajuste - B846229                  */
/********************************************************************/

use cobis
go
if exists (select * from sysobjects where name = 'sp_liquidacion_dml')
   drop proc sp_liquidacion_dml
go

create proc sp_liquidacion_dml (
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
		@t_show_version	bit           = 0,    -- MOSTRAR LA VERSION DEL PROGRAMA
		@t_debug        char(1)     = 'N',
		@t_file         varchar(10) = null,
		@t_from         varchar(32) = null,
		@t_trn          int 	= null,
		@i_operacion    char(1),
		@i_modo			tinyint   	= null,
		@i_codigo		int 		= null,
		@i_nombre		descripcion = null,
		@i_tipo         char(1)   	= 'N',
		@i_problema		catalogo 	= null,
		@i_referencia	descripcion = null,
		@i_ced_ruc		numero 		= null,
		@i_fecha		datetime 	= null,
		@i_tipoRef      catalogo 	= null
)
as
declare @w_sp_name          varchar(32),
		@w_sp_msg           varchar(132),
	    @w_return           int,
	    @w_codigo	   		int,
	    @w_nombre	   		descripcion,
	    @w_tipo		   		catalogo,
	    @w_problema	   		catalogo,
	    @w_referencia		catalogo,
	    @w_ced_ruc	   		numero,
	    @w_fecha	   		datetime,
	    @w_siguiente		int,
	    @v_codigo	   		int,
	    @v_nombre	   		descripcion,
	    @v_tipo		   		catalogo,
	    @v_problema	   		catalogo,
	    @v_referencia		catalogo,
	    @v_ced_ruc	   		numero,
	    @v_fecha	   		datetime

select @w_sp_name = 'sp_liquidacion_dml',
	   @w_sp_msg        = ''

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
	 begin tran
	 if @t_trn = 172150
	 begin
		select	@w_siguiente = siguiente + 1
		from	cl_seqnos
		where	tabla = 'cl_com_liquidacion'
		
		/* Insertar un nuevo registro */
	     	insert into cl_com_liquidacion 
			(cl_codigo, cl_nombre, cl_tipo, cl_problema,
			 cl_referencia, cl_ced_ruc, cl_fecha,cl_tipo_ref)
		values 	(@w_siguiente, @i_nombre, @i_tipo, @i_problema,
			 @i_referencia, @i_ced_ruc, @i_fecha,@i_tipoRef)
		 /* Si no se puede insertar enviar error*/
		 if @@error !=0
		 begin
			exec cobis..sp_cerror
			   @t_debug      = @t_debug,
			   @t_file       = @t_file,
			   @t_from       = @w_sp_name,
			   @i_num	 	 = 1720436,
			   @s_culture 	 = @s_culture
		        
			   return  1 
		 end
		 
		 /*  Actualiza contador actual en seqnos  */
		 update	cl_seqnos
		 set	siguiente = @w_siguiente
		 where	tabla = 'cl_com_liquidacion'
		 
		 /*Transaccion de Servicio*/
		 insert into ts_cia_liquidacion 
			(secuencial, tipo_transaccion,clase,fecha,
		       	 usuario, terminal, srv, lsrv,
			 codigo, nombre, tipo, problema, 
			 referencia, ced_ruc, fecha_reg)
		 values	(@s_ssn, @t_trn, 'N', @s_date, @s_user,@s_term,@s_srv,
			 @s_lsrv,
			 @i_codigo, @i_nombre, @i_tipo, @i_problema, 
			 @i_referencia, @i_ced_ruc, @i_fecha)
		
		/* Si no puede insertar , enviar el error*/
		if @@error !=0
		begin
			exec cobis..sp_cerror
			   @t_debug      = @t_debug,
			   @t_file       = @t_file,
			   @t_from       = @w_sp_name,
			   @i_num	 	 = 1720437,
			   @s_culture 	 = @s_culture
		       
			   return  1 
		end
		commit tran
		select	@w_siguiente
	end
	else 
	begin
		exec cobis..sp_cerror
		   @t_debug      = @t_debug,
		   @t_file       = @t_file,
		   @t_from       = @w_sp_name,
		   @i_num        = 1720417,
		   @s_culture 	 = @s_culture
		   /*  'No corresponde codigo de transaccion' */
		return 1
        end
end
/* Update */
If @i_operacion = 'U'
begin
	if @t_trn != 172151
	begin
		exec cobis..sp_cerror
		   @t_debug      = @t_debug,
		   @t_file       = @t_file,
		   @t_from       = @w_sp_name,
		   @i_num        = 1720417,
		   @s_culture 	 = @s_culture
		   /*  'No corresponde codigo de transaccion' */
		return 1
	end
	/* Seleccionar campos de la tabla */
	Select	@w_codigo     = cl_codigo, 
		@w_nombre     = cl_nombre,         
		@w_tipo       = cl_tipo,  	  
		@w_problema   = cl_problema,  	  
		@w_referencia = cl_referencia,
		@w_ced_ruc    = cl_ced_ruc,
		@w_fecha      = cl_fecha
	from cl_com_liquidacion
	where cl_codigo = @i_codigo
	if @@rowcount= 0
	begin
		/* No existe dato solicitado */
		  exec cobis..sp_cerror
		   @t_debug      = @t_debug,
		   @t_file       = @t_file,
		   @t_from       = @w_sp_name,
		   @i_num        = 1720438,
		   @s_culture 	 = @s_culture
		return 1
        end
	Select  @v_codigo     = @w_codigo, 
		@v_ced_ruc    = @w_ced_ruc,
		@v_nombre     = @w_nombre,         
		@v_tipo       = @w_tipo,  	  
		@v_problema   = @w_problema,  	  
		@v_referencia = @w_referencia,
		@v_fecha      = @w_fecha
	if @w_codigo = @i_codigo
	   select @w_codigo = null, @v_codigo = null
	else
	   select @w_codigo = @i_codigo
	if @w_ced_ruc = @i_ced_ruc
	   select @w_ced_ruc = null, @v_ced_ruc = null
	else
	   select @w_ced_ruc = @i_ced_ruc
	if @w_nombre = @i_nombre
	   select @w_nombre = null, @v_nombre = null
	else
	   select @w_nombre = @i_nombre
	if @w_tipo = @i_tipo
	   select @w_tipo = null, @v_tipo = null
	else
	   select @w_tipo = @i_tipo
	if @w_problema = @i_problema
	   select @w_problema = null, @v_problema = null
	else
	   select @w_problema = @i_problema
	if @w_referencia = @i_referencia
	   select @w_referencia = null, @v_referencia = null
	else
	   select @w_referencia = @i_referencia
	if @w_fecha = @i_fecha
	   select @w_fecha = null, @v_fecha = null
	else
	   select @w_fecha = @i_fecha
	begin tran
	/* Actualizar el registro */
	update	cl_com_liquidacion 
	set	cl_codigo     = @i_codigo,
		cl_nombre     = @i_nombre,
		cl_tipo       = @i_tipo,
		cl_problema   = @i_problema,
		cl_referencia = @i_referencia,
		cl_ced_ruc    = @i_ced_ruc,
		cl_fecha      = @i_fecha
	where cl_codigo = @i_codigo
	  if @@rowcount != 1
	    begin
		/* Error en actualizacion de registro covinco*/
		exec cobis..sp_cerror
		   @t_debug      = @t_debug,
		   @t_file       = @t_file,
		   @t_from       = @w_sp_name,
		   @i_num	 	 = 1720439,
		   @s_culture 	 = @s_culture
	        return  1 
	     end
	
	/*transaccion de servicios (registro previo)*/
	insert into ts_cia_liquidacion 
		(secuencial, tipo_transaccion, clase, fecha,
		usuario, terminal, srv,lsrv, 
		codigo, nombre, tipo, problema, referencia,
		ced_ruc, fecha_reg)
	values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_srv,@s_lsrv,
	 	@v_codigo, @v_nombre, @v_tipo, @v_problema, @v_referencia,
		@v_ced_ruc, @v_fecha)
	if @@error != 0
	begin
		/* Error en creacion de transaccion de servicios  covinco*/
		exec cobis..sp_cerror
		   @t_debug      = @t_debug,
		   @t_file       = @t_file,
		   @t_from       = @w_sp_name,
		   @i_num	 	 = 1720437,
		   @s_culture 	 = @s_culture
	        return  1 
	end
	
	/*transaccion de servicios (registro actual)*/
	insert into ts_cia_liquidacion 
		(secuencial, tipo_transaccion, clase, fecha,
		usuario, terminal, srv,lsrv, 
		codigo, nombre, tipo, problema, referencia,
		ced_ruc, fecha_reg)
	values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_srv,@s_lsrv,
		@w_codigo, @w_nombre, @w_tipo, @w_problema, @w_referencia,
		@w_ced_ruc, @w_fecha)	
	  if @@error != 0
	    begin
		/* Error en creacion de transaccion de servicios  covinco*/
		exec cobis..sp_cerror
		   @t_debug      = @t_debug,
		   @t_file       = @t_file,
		   @t_from       = @w_sp_name,
		   @i_num	 	 = 1720437,
		   @s_culture 	 = @s_culture
	       
		   return  1 
	     end
	commit tran
	      return  0 
 end
/* Delete */
If @i_operacion = 'D'
begin
	if @t_trn = 172152
	begin
		Select	@w_codigo     = cl_codigo, 
			@w_nombre     = cl_nombre,         
			@w_tipo       = cl_tipo,  	  
			@w_problema   = cl_problema,  	  
			@w_referencia = cl_referencia,
			@w_ced_ruc    = cl_ced_ruc,
			@w_fecha      = cl_fecha
		from cl_com_liquidacion
		where cl_codigo = @i_codigo
	
		if @@rowcount= 0
		begin
			/* No existe dato solicitado */
			  exec cobis..sp_cerror
			   @t_debug      = @t_debug,
			   @t_file       = @t_file,
			   @t_from       = @w_sp_name,
			   @i_num        = 1720438,
			   @s_culture 	 = @s_culture
			return 1
	        end
	
		begin tran
		/* Eliminar el registro */
		delete  from cl_com_liquidacion
	      	where cl_codigo = @i_codigo
	
		/* Si no se puede eliminar enviar error*/
	    	if @@error !=0
	      	begin
			exec cobis..sp_cerror
			   @t_debug      = @t_debug,
			   @t_file       = @t_file,
			   @t_from       = @w_sp_name,
			   @i_num	 	 = 1720440,
			   @s_culture 	 = @s_culture
		        return  1 
	      	end
			
		/*transaccion de servicios (eliminacion )*/
		insert into ts_cia_liquidacion 
			(secuencial, tipo_transaccion, clase, fecha,
			usuario, terminal, srv,lsrv, 
			codigo, nombre, tipo, problema, referencia,
			ced_ruc, fecha_reg)
		values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_srv,
			@s_lsrv,
			@w_codigo, @w_nombre, @w_tipo, @w_problema, 
			@w_referencia, @w_ced_ruc, @w_fecha)
		if @@error !=0
	  	begin
			/*Error en creacion de transaccion de servicios */
			exec cobis..sp_cerror
			   	@t_debug      = @t_debug,
			   	@t_file       = @t_file,
			   	@t_from       = @w_sp_name,
			   	@i_num	 	  = 1720437,
			    @s_culture 	  = @s_culture
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
		   @s_culture 	 = @s_culture
		   /*  'No corresponde codigo de transaccion' */
		return 1
     end
end
go
