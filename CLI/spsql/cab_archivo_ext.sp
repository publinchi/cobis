use cobis
go

IF OBJECT_ID ('dbo.sp_cab_archivo_ext') IS NOT NULL
	DROP PROCEDURE dbo.sp_cab_archivo_ext
GO

create procedure sp_cab_archivo_ext(
                @s_ssn				int          = null,
                @s_user				login        = null,
                @s_term				varchar(32)  = null,
                @s_date			    datetime     = null,
                @s_srv				varchar(30)  = null,
                @s_lsrv				varchar(30)  = null,
                @s_rol				smallint     = NULL,
                @s_ofi				smallint     = NULL,
                @s_org_err			char(1)      = NULL,
                @s_error			int          = NULL,
                @s_sev				tinyint      = NULL,
                @s_msg				descripcion  = NULL,
                @s_org				char(1)      = NULL,
				@s_culture			varchar(10)  = 'NEUTRAL',
                @t_trn				int          = NULL,
                @t_debug			char (1)     = 'N',
                @t_file				varchar(14)  = null,
                @t_from				varchar(30)  = null,
                @t_show_version     bit          = 0,
                @i_operacion		char(1),
				@i_secuencial		int          = null,       
				@i_nombre			varchar(255) = null,
				@i_descripcion		varchar(255) = null,
				@i_tipo_archivo		catalogo     = null,
				@i_fecha_carga		datetime     = null,
				@i_modo             tinyint      = null,
				@o_secuencial		int          = 0
)
as
declare         @w_sp_name			varchar (30),
                @w_sp_msg			varchar(132),
                @w_null				int,
                @w_fecha_ini		datetime,
				@w_nombre			varchar(255),
				@w_descripcion		varchar(255),
				@w_tipo_archivo		catalogo,
				@w_fecha_carga		datetime


/* Captura nombre de stored procedure*/
select  @w_sp_name = 'sp_cab_archivo_ext'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/




---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out

/*  Inserción Archivo   */
if (@i_operacion ='I') 
begin
if (@t_trn = 172169)
begin

		if exists (select 1 from cobis..cl_archivo_externos_cab where ae_nombre_archivo = @i_nombre or ae_descripcion = @i_descripcion)
		begin
			 /*  Nombre o la descripcion ingresados ya existen */
                        exec cobis..sp_cerror
                                @t_debug= @t_debug,
                                @t_file = @t_file,
								@s_culture   = @s_culture,
                                @t_from = @w_sp_name,
                                @i_num  = 1720460
             return 1
		end
               
				exec cobis..sp_cseqnos
                     @t_debug     = 'N',
                     @t_file      = '',
                     @t_from      = @w_sp_name,
                     @i_tabla     = 'cl_archivo_externos_cab',
                     @o_siguiente = @o_secuencial out

		

				insert into cobis..cl_archivo_externos_cab
				(ae_id_secuencial   	, ae_nombre_archivo     , ae_descripcion,
				 ae_tipo_archivo	, ae_fecha_carga						) 
				 values
				(@o_secuencial 		, @i_nombre     		, @i_descripcion,
				 @i_tipo_archivo    , getdate()								)

         
                if (@@error <> 0)
                begin
                        /*  Error en inserción de formato de archivo */
              exec cobis..sp_cerror
                                @t_debug= @t_debug,
                                @t_file = @t_file,
								@s_culture   = @s_culture,
                                @t_from = @w_sp_name,
                                @i_num  = 1720447
                        return 1
                end

        return 0
end
else
begin
		/*  No corresponde codigo de transaccion' */
        exec sp_cerror
           @t_debug      = @t_debug,
           @t_file       = @t_file,
		   @s_culture   = @s_culture,
           @t_from       = @w_sp_name,
           @i_num        = 1720075
        return 1
end
end





if (@i_operacion = 'S')
begin
    if (@t_trn = 172170)
    begin
	/* Información Completa */
	    if (@i_modo = 0)
	    begin

		 select  
			'Codigo'           = ae_id_secuencial, 
			'Nombre'           = ae_nombre_archivo,
			'Descripcion'      = ae_descripcion,
			'Tipo'             = ae_tipo_archivo, 
			'Fecha de carga'   = ae_fecha_carga
          from  cobis..cl_archivo_externos_cab
		  order by ae_id_secuencial
              
          if (@@rowcount = 0)
          begin
          /*  No hay formatos de archivos disponibles */
              exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file = @t_file,
				   @s_culture = @s_culture,
                   @t_from = @w_sp_name,
                   @i_num  = 1720448
              return 1
          end
	end
	/* Información Básica */
	    if (@i_modo = 1)
	    begin

		 select   
			'Codigo'           = ae_id_secuencial, 
			'Nombre'           = ae_nombre_archivo,
			'Descripcion'      = ae_descripcion
          from  cobis..cl_archivo_externos_cab
		  order by ae_id_secuencial
              
          if (@@rowcount = 0)
          begin
          /*  No hay formatos de archivos disponibles */
              exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file = @t_file,
				   @s_culture = @s_culture,
                   @t_from = @w_sp_name,
                   @i_num  = 1720448
              return 1
          end
	 end

     return 0

  end
  else
  begin
  /*  No corresponde codigo de transaccion' */
	  exec sp_cerror
           @t_debug      = @t_debug,
           @t_file       = @t_file,
		   @s_culture   = @s_culture,
           @t_from       = @w_sp_name,
           @i_num        = 1720075
      return 1
  end
end





if (@i_operacion = 'U')
begin
	if (@t_trn = 172171)
	begin

		 if (@i_secuencial IS NULL)
		 begin
	     /*  No se ingresó la cabecera del archivo */
             exec cobis..sp_cerror
                  @t_debug= @t_debug,
                  @t_file = @t_file,
			      @s_culture   = @s_culture,
                  @t_from = @w_sp_name,
                  @i_num  = 1720452
             return 1
		 end

		if exists (select 1 from cobis..cl_archivo_externos_cab where (ae_nombre_archivo = @i_nombre or ae_descripcion = @i_descripcion) and ae_id_secuencial <> @i_secuencial )
		begin
			 /*  Nombre o la descripcion ingresados ya existen */
                        exec cobis..sp_cerror
                                @t_debug= @t_debug,
                                @t_file = @t_file,
								@s_culture   = @s_culture,
                                @t_from = @w_sp_name,
                                @i_num  = 1720460
             return 1
		end

		 select
		 @w_nombre            = ae_nombre_archivo,
		 @w_descripcion       = ae_descripcion,
		 @w_tipo_archivo      = ae_tipo_archivo,
		 @w_fecha_carga       = ae_fecha_carga
		 FROM cobis..cl_archivo_externos_cab
		 where ae_id_secuencial = @i_secuencial

		  if (@@rowcount = 0)
          begin
          /*  No existe este formato de archivo  */
              exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file = @t_file,
				   @s_culture   = @s_culture,
                   @t_from = @w_sp_name,
                   @i_num  = 1720450
              return 1
          end

		  update cobis..cl_archivo_externos_cab
		  set
		  ae_nombre_archivo   = ISNULL(@i_nombre,@w_nombre),
		  ae_descripcion      = ISNULL(@i_descripcion,@w_descripcion),
	      ae_tipo_archivo     = ISNULL(@i_tipo_archivo,@w_tipo_archivo),
		  ae_fecha_carga      = ISNULL(@i_fecha_carga,@w_fecha_carga)
		  where
		  ae_id_secuencial = @i_secuencial

		  if (@@error <> 0)
          begin
          /*  Error al actualizar formato de archivo */
              exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file = @t_file,
				   @s_culture   = @s_culture,
                   @t_from = @w_sp_name,
    @i_num  = 1720449
              return 1
          end

		  return 0 
	end
	else
	begin
    /*  No corresponde codigo de transaccion' */
		exec sp_cerror
             @t_debug      = @t_debug,
             @t_file       = @t_file,
		     @s_culture   = @s_culture,
             @t_from       = @w_sp_name,
             @i_num        = 1720075
        return 1
	end
end





if (@i_operacion = 'D')
begin
	

if (@t_trn = 172172)
  begin         
				if (@i_secuencial IS NULL)
				begin
					/*  No se ingresó la cabecera del archivo */

                        exec cobis..sp_cerror
                                @t_debug= @t_debug,
                                @t_file = @t_file,
								@s_culture   = @s_culture,
                                @t_from = @w_sp_name,
                                @i_num  = 1720452
                        return 1
				end
				
		 if ( not exists (select 1 from cobis..cl_archivo_externos_cab where ae_id_secuencial = @i_secuencial) )
		 begin
          /*  No existe este formato de archivo  */
              exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file = @t_file,
				   @s_culture  = @s_culture,
                   @t_from = @w_sp_name,
                   @i_num  = 1720450
              return 1
         end
		 
		 /* guardar los datos anteriores */
		 select
         @w_nombre            = ae_nombre_archivo,
		 @w_descripcion       = ae_descripcion,
		 @w_tipo_archivo      = ae_tipo_archivo,
		 @w_fecha_carga       = ae_fecha_carga
		 FROM cobis..cl_archivo_externos_cab
		 where ae_id_secuencial = @i_secuencial
		 
		 /* si no existe datos anteriores, error  */
         if @@rowcount = 0
         begin
         /*  No existe relacion  */
			 exec cobis..sp_cerror
			  @t_debug= @t_debug,
			  @t_file = @t_file,
			  @t_from = @w_sp_name,
			  @i_num  = 1720300
			 return 1
         end

	   begin tran
	   
		 delete cl_archivo_externos_cab
		 where  ae_id_secuencial = @i_secuencial
		 
		 /* si no se puede borrar, error */
		 if @@error <> 0
         begin
        /*  No existe cabecera  */
			 exec cobis..sp_cerror
			  @t_debug= @t_debug,
			  @t_file = @t_file,
			  @t_from = @w_sp_name,
			  @i_num  = 1720303
			 return 1
         end
		 
		 /* Borrar en cascada los detalles de la cabecera */
         delete cl_archivo_externos_det
         where  aed_secuencial_cabecera = @i_tipo_archivo
		 
		 /* si no se puede borrar, error */
         if @@error <> 0
         begin
			 exec cobis..sp_cerror
			  @t_debug= @t_debug,
			  @t_file = @t_file,
			  @t_from = @w_sp_name,
			  @i_num  = 1720204
			 return 1
         end
	  commit tran
      return 0
  end
else
  begin
	    exec sp_cerror
           @t_debug      = @t_debug,
           @t_file       = @t_file,
		   @s_culture   = @s_culture,
           @t_from       = @w_sp_name,
           @i_num        = 1720075
           /*  'No corresponde codigo de transaccion' */
        return 1
  end
end



/*  Query  */
if (@i_operacion = 'Q')
begin

if (@t_trn = 172173)
begin

        select  
			'Codigo'           = ae_id_secuencial, 
			'Nombre'           = ae_nombre_archivo,
			'Descripcion'      = ae_descripcion,
			'Tipo'             = ae_tipo_archivo, 
			'Fecha de carga'   = ae_fecha_carga
          from  cobis..cl_archivo_externos_cab
		  where ae_id_secuencial = ISNULL(@i_secuencial,ae_id_secuencial)
		  order by ae_id_secuencial
                
       if (@@rowcount = 0)
       begin
         /*  No existe instancia de relacion  */
         exec cobis..sp_cerror
                 @t_debug= @t_debug,
                 @t_file = @t_file,
				 @s_culture   = @s_culture,
                 @t_from = @w_sp_name,
                 @i_num  = 1720448
         return 1
       end

      return 0

end
else
begin
        exec sp_cerror
           @t_debug      = @t_debug,
           @t_file       = @t_file,
		   @s_culture   = @s_culture,
           @t_from       = @w_sp_name,
           @i_num        = 1720075
        /*  'No corresponde codigo de transaccion' */
        return 1
end

end


GO

