/************************************************************************/
/*	Archivo:			mala_ref.sp										*/
/*	Stored procedure:	sp_mala_ref										*/
/*	Base de datos:		cobis											*/
/*	Producto:			M.I.S.  										*/
/*	Disenado por:		Carlos Rodriguez V.    							*/
/*	Fecha de escritura:	09-Abr-94         								*/
/************************************************************************/
/*				IMPORTANTE												*/
/*	Este programa es parte de los paquetes bancarios propiedad de		*/
/*	"MACOSA", representantes  exclusivos  para el  Ecuador  de la 		*/
/*	"NCR CORPORATION".													*/
/*	Su  uso no autorizado  queda expresamente  prohibido asi como		*/
/*	cualquier   alteracion  o  agregado  hecho por  alguno de sus		*/
/*	usuarios   sin el debido  consentimiento  por  escrito  de la 		*/
/*	Presidencia Ejecutiva de MACOSA o su representante.					*/
/*				PROPOSITO												*/
/*	Este programa procesa las transacciones del stored procedure		*/
/*      Insercion de malas referencias de un cliente                    */
/*      Borrado de malas referencias                                    */
/*	Busqueda de malas referencias     									*/
/*	Busqueda especifica de malas referencias     						*/
/*				MODIFICACIONES											*/
/*	FECHA		AUTOR		RAZON										*/
/*	                           	Emision Inicial							*/
/* 19/01/2021   IYUPA 			CLI-S412373-PRD- Malas Referencias		*/
/* 31/03/2021   ACA 			Eliminación validación en update		*/
/************************************************************************/
use cobis
go
if exists (select * from sysobjects where name = 'sp_mala_ref')
   drop proc sp_mala_ref
go

create proc sp_mala_ref (
       	@s_ssn			int = null,
       	@s_user			login = null,
       	@s_term			varchar(30) = null,
       	@s_date			datetime = null,
       	@s_srv			varchar(30) = null,
       	@s_lsrv			varchar(30) = null,
       	@s_ofi			smallint = null,
		@s_rol			smallint = NULL,
		@s_org_err		char(1) = NULL,
		@s_error		int = NULL,
		@s_sev			tinyint = NULL,
		@s_msg			descripcion = NULL,
		@s_org			char(1) = NULL,
       	@t_debug		char(1) = 'N',
       	@t_file			varchar(10) = null,
       	@t_from			varchar(32) = null,
       	@t_trn			int = null,
       	@i_operacion	char(1),
       	@i_modo			tinyint = null,
       	@i_tipo			char(1) = null,
       	@i_ente			int = null ,
       	@i_mala_ref		tinyint = null,
       	@i_treferencia  catalogo = null,
       	@i_ultima		tinyint = null,
		@i_observacion 	varchar(255) = null
)
as
declare @w_return       int,
		@w_codigo	int,
		@w_siguiente	smallint,
		@w_sp_name	varchar(32),
		@w_ente		int,
		@w_mala_ref	smallint,
		@w_treferencia  catalogo,
		@w_fecha_registro datetime,
		@w_today	datetime,
		@v_ente		int,
		@v_mala_ref	smallint,
		@v_treferencia  catalogo,
		@v_fecha_registro datetime,
		@o_ente		int,
		@o_mala_ref	smallint,
		@o_desc_mala_ref descripcion,
		@o_treferencia  catalogo,
		@o_fecha_registro datetime,
		@o_observacion varchar(255)
		
select @w_sp_name = 'sp_mala_ref'
select @w_today = getdate()
/* ** Insert ** */
if @i_operacion = 'I'
begin
if @t_trn = 172140
begin
   /* Verificar que exista el tipo de mala referencia en catalogo)*/
   exec @w_return = cobis..sp_catalogo
	@t_debug     = @t_debug,
	@t_file	     = @t_file,
	@t_from	     = @w_sp_name,
	@i_tabla     = 'cl_tmala_ref',
	@i_operacion = 'E',
	@i_codigo    = @i_treferencia
    /* si no existe error */
    if @w_return != 0
	begin
   	/*  No existe ....  */
     	  exec cobis..sp_cerror 
		@t_debug= @t_debug,
		@t_file	= @t_file,
		@t_from	= @w_sp_name,
		@i_num	= 1720410 
	   return 1
        end
  /* verificar que exista dato en CL_ENTE */
  select @w_codigo = en_ente
    from cl_ente
   where en_ente = @i_ente
  if @@rowcount = 0
  begin
	/*'No existe '*/
	exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720411
	return 1
  end
  if  exists ( select mr_ente from cl_mala_ref
	where mr_ente = @i_ente  
          and mr_treferencia = @i_treferencia )
  begin
	/*'Ya existe mala referencia '  */
	exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720412
	return 1
  end
  begin tran
     /* Encontrar un nuevo secuencial */
	select @w_siguiente = isnull(en_cont_malas,0) + 1
	  from cl_ente
	 where en_ente = @i_ente
	if @@error != 0 
		begin
			exec sp_cerror
				@t_debug	= @t_debug,
				@t_file		= @t_file,
				@t_from		= @w_sp_name,
				@i_num		= 1720413
			return 1
	  	end
     /* Insertar los datos de entrada */
     insert into cl_mala_ref (mr_ente, mr_mala_ref ,mr_treferencia, 
		   	      mr_fecha_registro,mr_observacion)
	  values (@i_ente, @w_siguiente, @i_treferencia,
		  @w_today,@i_observacion)
     /* Si no se puede insertar error */
     if @@error != 0
     begin
	/* 'Error en creacion '*/
	exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720414
	return 1
     end
     /* transaccion servicio - nuevo */
     insert into  ts_mala_ref (secuencial, tipo_transaccion, clase, fecha,
		usuario, terminal, srv, lsrv,
		ente,mala_ref,treferencia)
        values (@s_ssn, @t_trn, 'N', @s_date,
	        @s_user, @s_term, @s_srv, @s_lsrv,
	        @i_ente, @w_siguiente, @i_treferencia)
     /* Si no se puede insertar , error */
     if @@error != 0
     begin
	  /* 'Error en creacion de transaccion de servicios'*/
	  exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720415
	  return 1
     end
     update cl_ente
	set en_mala_referencia = 'S',
	    en_cont_malas = isnull(en_cont_malas,0) + 1
      where en_ente = @i_ente
     /* Si no se puede actualizar , error */
     if @@error != 0
     begin
	  /* 'Error en actualizacion del ente */
	  exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720416
	  return 1
     end
  commit tran
  /* Retornar el nuevo codigo  */
  select @w_siguiente
  return 0
end
else
begin
	exec sp_cerror
	   @t_debug	 = @t_debug,
	   @t_file	 = @t_file,
	   @t_from	 = @w_sp_name,
	   @i_num	 = 1720417
	   /*  'No corresponde codigo de transaccion' */
	return 1
end
end
/* **Update **/
if @i_operacion = 'U'
begin
if @t_trn = 172139 
begin
	
     begin tran
      update cl_mala_ref
      set mr_treferencia = @i_treferencia, 
	  mr_observacion = @i_observacion
      where mr_ente = @i_ente
	 and mr_mala_ref = @i_mala_ref
     /* si no se puede borrar, error */
     if @@error != 0
     begin
	/* Error en update ...*/
	exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720418
	return 1
     end
    /* Transaccion servicios - actualizaando */
      insert into ts_mala_ref (secuencial, tipo_transaccion, clase, fecha,
		              usuario, terminal, srv, lsrv,
			      ente,mala_ref,treferencia,fecha_registro
	                      )
      values (@s_ssn, @t_trn, 'B', @s_date,
	      @s_user, @s_term, @s_srv, @s_lsrv,
	      @w_ente, @w_mala_ref, @w_treferencia, @w_fecha_registro)
      /* error si no se puede insertar transaccion de servicio */
      if @@error != 0
      begin
	  /* Error en creacion de transaccion de servicio */
	  exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720415
	  return 1
      end
  commit tran
  return 0
end
else
begin
	exec sp_cerror
	   @t_debug	 = @t_debug,
	   @t_file	 = @t_file,
	   @t_from	 = @w_sp_name,
	   @i_num	 = 1720417
	   /*  'No corresponde codigo de transaccion' */
	return 1
end
end
/* ** Delete ** */
if @i_operacion = 'D'
begin
if @t_trn = 172137
begin
    /* Conservar valores para transaccion de servicios */
    select @w_ente = mr_ente,
	   @w_mala_ref = mr_mala_ref,
	   @w_treferencia = mr_treferencia,
	   @w_fecha_registro = mr_fecha_registro
      from cl_mala_ref
     where mr_ente = @i_ente
       and mr_mala_ref = @i_mala_ref
    /* si no existe registro a borrar, error */
    if @@rowcount = 0
    begin
      /* No existe ...*/
      exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720419
      return 1
    end
     begin tran      
	/* Si esta es la ultima mala referencia */
       if (select count(*) from cl_mala_ref where mr_ente = @i_ente) = 1
		begin 
			update	cl_ente
			   set  en_mala_referencia = 'N'
			 where  en_ente = @i_ente
		       /* si no se puede modificar, error */
		       if @@error != 0
			       begin
					exec sp_cerror
					  @t_debug	= @t_debug,
					  @t_file	= @t_file,
					  @t_from	= @w_sp_name,
					  @i_num	= 1720416
					  return 1
			       end
		end
      /* borrar ... */
      delete cl_mala_ref
       where mr_ente = @i_ente
	 and mr_mala_ref = @i_mala_ref
     /* si no se puede borrar, error */
     if @@error != 0
     begin
	/* Error en eliminacion ...*/
	exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720420
	return 1
     end
   
    /* Transaccion servicios - borrado */
      insert into ts_mala_ref (secuencial, tipo_transaccion, clase, fecha,
		              usuario, terminal, srv, lsrv,
			      ente,mala_ref,treferencia,fecha_registro
	                      )
      values (@s_ssn, @t_trn, 'B', @s_date,
	      @s_user, @s_term, @s_srv, @s_lsrv,
	      @w_ente, @w_mala_ref, @w_treferencia, @w_fecha_registro)
      /* error si no se puede insertar transaccion de servicio */
      if @@error != 0
      begin
	  /* Error en creacion de transaccion de servicio */
	  exec sp_cerror
		@t_debug	= @t_debug,
		@t_file		= @t_file,
		@t_from		= @w_sp_name,
		@i_num		= 1720415
	  return 1
      end
  commit tran
  return 0
end
else
begin
	exec sp_cerror
	   @t_debug	 = @t_debug,
	   @t_file	 = @t_file,
	   @t_from	 = @w_sp_name,
	   @i_num	 = 1720417
	   /*  'No corresponde codigo de transaccion' */
	return 1
end
end
/* ** Search** */
 if @i_operacion = 'S' 
 begin
if @t_trn = 172136
begin
     set rowcount 20
     if @i_modo = 0
	select  "5084" =  mr_mala_ref,
	        "3072" =  mr_treferencia,
	        "5167" =  substring(a.valor,1,30),
	        "5168" =  convert(char(10),mr_fecha_registro,103),
			mr_observacion
	from  cl_mala_ref, cl_catalogo a, cl_tabla b
        where mr_ente = @i_ente 
          and mr_treferencia = a.codigo 
          and a.tabla = b.codigo
	  and b.tabla = 'cl_tmala_ref'
     if @i_modo = 1
	select  "5084" =  mr_mala_ref,
	        "3072" =  mr_treferencia,
	        "5167" =  substring(a.valor,1,30),
	        "5168" =  convert(char(10),mr_fecha_registro,103)
	from  cl_mala_ref, cl_catalogo a, cl_tabla b
        where mr_ente = @i_ente 
	  and mr_mala_ref > @i_ultima
          and mr_treferencia = a.codigo 
          and a.tabla = b.codigo
	  and b.tabla = 'cl_tmala_ref'
     set rowcount 0
     return 0
end
else
begin
	exec sp_cerror
	   @t_debug	 = @t_debug,
	   @t_file	 = @t_file,
	   @t_from	 = @w_sp_name,
	   @i_num	 = 1720417
	   /*  'No corresponde codigo de transaccion' */
	return 1
end
end
/* ** Query especifico para cada sp ** */
if @i_operacion = "Q"
begin
if @t_trn = 172138
begin
	select @o_ente = mr_ente,
	       @o_mala_ref = mr_mala_ref,
	       @o_treferencia = mr_treferencia,
	       @o_desc_mala_ref = substring(a.valor,1,30),
	       @o_fecha_registro = mr_fecha_registro,
	       @o_observacion = mr_observacion
	from  cl_mala_ref, cl_catalogo a, cl_tabla b 
        where mr_ente = @i_ente 
	  and mr_mala_ref = @i_mala_ref
          and mr_treferencia = a.codigo 
          and a.tabla = b.codigo
	  and b.tabla = 'cl_tmala_ref'
  	if @@rowcount = 0
	  begin
		/*'No existe '*/
		exec sp_cerror
			@t_debug	= @t_debug,
			@t_file		= @t_file,
			@t_from		= @w_sp_name,
			@i_num		= 1720421
		return 1
	  end
	select @o_ente,
	       @o_mala_ref,
	       @o_treferencia,
	       @o_desc_mala_ref,
	       convert(char(10),@o_fecha_registro,103),
	       @o_observacion
	return 0
end
else
begin
	exec sp_cerror
	   @t_debug	 = @t_debug,
	   @t_file	 = @t_file,
	   @t_from	 = @w_sp_name,
	   @i_num	 = 1720417
	   /*  'No corresponde codigo de transaccion' */
	return 1
end
end
go
