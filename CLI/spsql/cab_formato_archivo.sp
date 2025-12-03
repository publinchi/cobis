/************************************************************************/
/*   Archivo:                 cab_formato_archivo.sp                    */
/*   Stored procedure:        sp_cab_formato_archivo                    */
/*   Base de datos:           cobis                                     */
/*   Producto:                CLIENTES                                  */
/*   Disenado por:  ADB   				                                */
/*   Fecha de escritura: 08-Feb-2021                                    */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Esta aplicacion es parte de los paquetes bancarios propiedad    */
/*      de COBIS S.A.                                                   */
/*      Su uso no  autorizado queda  expresamente prohibido asi como    */
/*      cualquier  alteracion  o agregado  hecho por  alguno  de sus    */
/*      usuarios sin el debido consentimiento por escrito de COBIS S.A  */
/*      Este programa esta protegido por la ley de derechos de autor    */
/*      y por las  convenciones  internacionales de  propiedad inte-    */
/*      lectual.  Su uso no  autorizado dara  derecho a  COBIS S.A para */
/*      obtener  ordenes de  secuestro o retencion y  para perseguir    */
/*      penalmente a los autores de cualquier infraccion.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este stored procedure procesa:                                  */
/*      insercion en cl_cab_formato_archivo                             */
/*      borrado en cl_cab_formato_archivo                               */
/*      query de formato archivo en funcion de su codigo unico          */
/************************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA       	AUTOR               RAZON                           */
/*   08/Feb/2020   	ADB	            Versión Inicial                     */
/*   17/Feb/2020    ADB             Prevención datos repetidos          */
/*   17/Feb/2020    ADB             Eliminar el Límitante en Selección  */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select * from sysobjects where name = 'sp_cab_formato_archivo')
        drop procedure sp_cab_formato_archivo
go
create procedure sp_cab_formato_archivo(
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
				@i_formato_archivo  int          = null,       
				@i_nombre			varchar(255) = null,
				@i_descripcion		varchar(255) = null,
				@i_tipo_archivo		catalogo     = null,
				@i_delimitado		char(1)      = null,
				@i_tipo_delimitador catalogo     = null,
				@i_otro_delimitador varchar(255) = null,
				@i_estado			catalogo     = null,
				@i_modo             int          = null,
				@o_formato_archivo  int          = 0
)
as
declare         @w_sp_name			varchar (30),
                @w_sp_msg			varchar(132),
                @w_null				int,
                @w_fecha_ini		datetime,
				@w_tipo_delimitador catalogo,
				@w_otro_delimitador varchar(255),
				@w_nombre			varchar(255),
				@w_descripcion		varchar(255),
				@w_tipo_archivo		catalogo,
				@w_delimitado		char(1),
				@w_estado			catalogo


/* Captura nombre de stored procedure*/
select  @w_sp_name = 'sp_cab_formato_archivo'
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




/*  Inserción Formato Archivo  */
if (@i_operacion ='I') 
begin
if (@t_trn = 172158)
begin
		if (@i_delimitado = 'N')
		begin
			SET @i_tipo_delimitador = null
			SET @i_otro_delimitador = null
		end
		
		if (@i_delimitado = 'S')
		begin
			if(@i_tipo_delimitador <> 'OTR')
			begin
				SET @i_otro_delimitador = null
			end
		end

		if exists (select 1 from cobis..cl_cab_formato_archivo where cf_nombre = @i_nombre or cf_descripcion = @i_descripcion)
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
                     @i_tabla     = 'cl_cab_formato_archivo',
                     @o_siguiente = @o_formato_archivo out

		

				insert into cobis..cl_cab_formato_archivo
				(cf_id_cab_archivo   , cf_nombre     , cf_descripcion,
				 cf_tipo_archivo     , cf_delimitado , cf_tipo_delimitador,
				 cf_otro_delimitador , cf_estado     , cf_numero_detalles) 
				 values
				 (@o_formato_archivo , @i_nombre     , @i_descripcion,
				  @i_tipo_archivo    , @i_delimitado , @i_tipo_delimitador,
				  @i_otro_delimitador, @i_estado     , 0
				 )

         
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
    if (@t_trn = 172159)
    begin
	/* Información Completa */
	    if (@i_modo = 0)
	    begin

		 select  
			'Codigo'           = cf_id_cab_archivo, 
			'Nombre'           = cf_nombre,
			'Descripcion'      = cf_descripcion,
			'Tipo'             = cf_tipo_archivo, 
			'Delimitado'       = cf_delimitado, 
			'Tipo Delimitador' = cf_tipo_delimitador,
			'Otro Delimitador' = cf_otro_delimitador, 
			'Estado'           = cf_estado
          from  cobis..cl_cab_formato_archivo
		  
              
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
			'Codigo'           = cf_id_cab_archivo, 
			'Nombre'           = cf_nombre,
			'Descripcion'      = cf_descripcion
          from  cobis..cl_cab_formato_archivo
		  
              
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
	if (@t_trn = 172160)
	begin

		 if (@i_formato_archivo IS NULL)
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

		if exists (select 1 from cobis..cl_cab_formato_archivo where (cf_nombre = @i_nombre or cf_descripcion = @i_descripcion) and cf_id_cab_archivo <> @i_formato_archivo )
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
		 @w_nombre            = cf_nombre,
		 @w_descripcion       = cf_descripcion,
		 @w_tipo_archivo      = cf_tipo_archivo,
		 @w_delimitado        = cf_delimitado,
		 @w_tipo_delimitador  = cf_tipo_delimitador,
		 @w_otro_delimitador  = cf_otro_delimitador,
		 @w_estado            = cf_estado
		 FROM cobis..cl_cab_formato_archivo
		 where cf_id_cab_archivo = @i_formato_archivo

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

		if (@i_delimitado = 'N')
		begin
			SET @i_tipo_delimitador = null
			SET @i_otro_delimitador = null
		end
		
		if (@i_delimitado = 'S')
		begin
			if(@i_tipo_delimitador <> 'OTR')
			begin
				SET @i_otro_delimitador = null
			end
		end


		  update cobis..cl_cab_formato_archivo
		  set
		  cf_nombre           = ISNULL(@i_nombre,@w_nombre),
		  cf_descripcion      = ISNULL(@i_descripcion,@w_descripcion),
	      cf_tipo_archivo     = ISNULL(@i_tipo_archivo,@w_tipo_archivo),
		  cf_delimitado       = ISNULL(@i_delimitado,@w_delimitado), 
	      cf_tipo_delimitador = ISNULL(@i_tipo_delimitador,@w_tipo_delimitador),
		  cf_otro_delimitador = ISNULL(@i_otro_delimitador,@w_otro_delimitador),
		  cf_estado           = ISNULL(@i_estado,@w_estado),
		  cf_numero_detalles  = (select COUNT(*) from cobis..cl_det_formato_archivo where df_id_cab_archivo = @i_formato_archivo)
		  where
		  cf_id_cab_archivo = @i_formato_archivo

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
	

if (@t_trn = 172161)
  begin         
				if (@i_formato_archivo IS NULL)
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
				
		 if ( not exists (select 1 from cobis..cl_cab_formato_archivo where cf_id_cab_archivo = @i_formato_archivo) )
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



				update cobis..cl_cab_formato_archivo 
				SET 
				cf_estado = 'E' 
				where 
				cf_id_cab_archivo = @i_formato_archivo 

                if (@@error <> 0)
                begin
                        /*  Error al eliminar formato archivo */
                        exec cobis..sp_cerror
                             @t_debug= @t_debug,
                             @t_file = @t_file,
						     @s_culture   = @s_culture,
                             @t_from = @w_sp_name,
                             @i_num  = 1720451
                        return 1
                end
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

if (@t_trn = 172162)
begin

        select  
			'Codigo' = cf_id_cab_archivo, 
			'Nombre' = cf_nombre        ,
			'Descripcion' = cf_descripcion,
			'Tipo' =     cf_tipo_archivo, 
			'Delimitado' = cf_delimitado, 
			'Tipo Delimitador' = cf_tipo_delimitador,
			'Otro Delimitador' = cf_otro_delimitador, 
			'Estado' = cf_estado
          from  cobis..cl_cab_formato_archivo
		  where cf_id_cab_archivo = ISNULL(@i_formato_archivo,cf_id_cab_archivo)
		  order by cf_id_cab_archivo
                
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
go