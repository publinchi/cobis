/************************************************************************/
/*   Archivo:                 det_archivo_ext.sp                        */
/*   Stored procedure:        sp_det_archivo_ext                        */
/*   Base de datos:           cobis                                     */
/*   Producto:                CLIENTES                                  */
/*   Disenado por:  DSH  				                                */
/*   Fecha de escritura: 14-Mar-2021                                    */
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
/*      insercion en cl_archivo_externos_det                            */
/*      borrado en cl_archivo_externos_det                              */
/*      query de detalles archivo externo en funcion de su codigo unico */
/************************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA       	AUTOR               RAZON                           */
/*   14/Mar/2021   	DSH	            Versión Inicial                     */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

IF OBJECT_ID ('dbo.sp_det_archivo_ext') IS NOT NULL
	DROP PROCEDURE dbo.sp_det_archivo_ext
GO

create procedure sp_det_archivo_ext(
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
				@i_cabecera_formato int          = null,       
				@i_secuencial	    tinyint      = null,
				@i_id_detalle  		tinyint      = null,
				@i_valor     		varchar(255) = null,
				@i_modo             int          = null,
				@o_secuencial       int          = 1
)
as
declare         @w_sp_name			varchar (30),
                @w_sp_msg			varchar(132),
                @w_null				int,
                @w_fecha_ini		datetime,
				@w_cabecera_formato int          = null,       
				@w_secuencial	    tinyint      = null,
				@w_id_detalle  		tinyint      = null,
				@w_valor     		varchar(255) = null,
				@w_modo             int          = null,
				@w_detalles         int          = null,
				@w_cambiador        int          = 1,
				@w_iterador         int          = 1


/* Captura nombre de stored procedure*/
select  @w_sp_name = 'sp_det_archivo_ext'
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




/*  Inserción Detalle Formato Archivo  */
if (@i_operacion ='I') 
begin
if (@t_trn = 172174)
begin

				IF @i_cabecera_formato IS NULL
				begin
				/*  No se ingresó la cabecera del archivo */
                exec cobis..sp_cerror
                 @t_debug= @t_debug,
                 @t_file = @t_file,
				 @s_culture = @s_culture,
                 @t_from = @w_sp_name,
                 @i_num  = 1720452
                return 1
		        end

				if exists (select 1 from cobis..cl_cab_formato_archivo WHERE cf_id_cab_archivo = @i_cabecera_formato)
			    begin
		
				exec cobis..sp_cseqnos
                     @t_debug     = 'N',
                     @t_file      = '',
                     @t_from      = @w_sp_name,
                     @i_tabla     = 'cl_archivo_externos_det',
                     @o_siguiente = @o_secuencial out

				 set @w_detalles = (select count(*)+1 from cobis..cl_archivo_externos_det where aed_secuencial_cabecera = @i_cabecera_formato)

				 insert into cobis..cl_archivo_externos_det
				 (aed_secuencial_cabecera	, aed_secuencial_registro	, aed_id_detalle,
				  aed_valor	) 
				 values
				 (@i_cabecera_formato 		, @w_detalles         		, @i_id_detalle,
				  @i_valor	)

                if (@@error <> 0)
      			begin
                        /*  Error en inserción de Detalle de archivo */
                        exec cobis..sp_cerror
                                @t_debug= @t_debug,
                                @t_file = @t_file,
								@s_culture   = @s_culture,
                                @t_from = @w_sp_name,
                                @i_num  = 1720453
                        return 1
                end

        return 0
		end
		else
		begin
		  /*  Esta cabecera de formato de archivos no existe */
                exec cobis..sp_cerror
                     @t_debug= @t_debug,
                     @t_file = @t_file,
					 @s_culture   = @s_culture,
                     @t_from = @w_sp_name,
                     @i_num  = 1720458
                return 1
		end
		
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
    if (@t_trn = 172175)
    begin
		if @i_cabecera_formato IS NULL
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

		select  
			'Id Cabecera'	= aed_secuencial_cabecera, 
			'Secuencial'	= aed_secuencial_registro,
			'Id Detalle'    = aed_id_detalle,
			'Valor'      	= aed_valor
        from  cobis..cl_archivo_externos_det
		where aed_secuencial_cabecera = @i_cabecera_formato
		order by aed_secuencial_registro
              
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
	if (@t_trn = 172176)
	begin

		if @i_cabecera_formato IS NULL
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

		 if @i_secuencial IS NULL
				begin
				/*  No se ingresó el secuencial del detalle del archivo */
                exec cobis..sp_cerror
                 @t_debug= @t_debug,
                 @t_file = @t_file,
				 @s_culture   = @s_culture,
                 @t_from = @w_sp_name,
                 @i_num  = 1720459
                return 1
		  end
		 

		 if exists (select 1 from cobis..cl_cab_formato_archivo WHERE cf_id_cab_archivo = @i_cabecera_formato)
	     begin


		 if exists (select 1 from cobis..cl_archivo_externos_det WHERE aed_secuencial_cabecera = @i_cabecera_formato and aed_secuencial_registro <> @i_secuencial)
		 begin
		        /*  No se ingresó el secuencial del detalle del archivo */
                exec cobis..sp_cerror
                 @t_debug= @t_debug,
                 @t_file = @t_file,
				 @s_culture   = @s_culture,
                 @t_from = @w_sp_name,
                 @i_num  = 1720461
                return 1
		 end



		 select
		 @w_valor         	= aed_valor
		 from cobis..cl_archivo_externos_det
		 where aed_secuencial_cabecera = @i_cabecera_formato 
		 and aed_secuencial_registro = @i_secuencial
	

		  if (@@rowcount = 0)
          begin
          /*  No existe este detalle de archivo  */
              exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file = @t_file,
				   @s_culture   = @s_culture,
                   @t_from = @w_sp_name,
                   @i_num  = 1720456
              return 1
          end

		

		  update cobis..cl_archivo_externos_det
		  set
		  aed_valor   = ISNULL(@i_valor,@w_valor)     
		  where
		  aed_secuencial_cabecera = @i_cabecera_formato
		  and
		  aed_secuencial_registro = @i_secuencial

		  if (@@error <> 0)
          begin
          /*  Error al actualizar detalle de archivo */
              exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file = @t_file,
				   @s_culture   = @s_culture,
                   @t_from = @w_sp_name,
       @i_num  = 1720455
              return 1
          end

		  return 0 
		  end
		  else
		  begin
		  /*  Esta cabecera de formato de archivos no existe */
                exec cobis..sp_cerror
                     @t_debug= @t_debug,
                     @t_file = @t_file,
					 @s_culture   = @s_culture,
                     @t_from = @w_sp_name,
                     @i_num  = 1720458
                return 1
		  end
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
	

if (@t_trn = 172177)
  begin         
				if @i_cabecera_formato IS NULL
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


				if @i_secuencial IS NULL
				begin
				/*  No se ingresó la cabecera del archivo */
                exec cobis..sp_cerror
                 @t_debug= @t_debug,
                 @t_file = @t_file,
				 @s_culture   = @s_culture,
                 @t_from = @w_sp_name,
                 @i_num  = 1720459
                return 1
		        end

				if exists (select 1 from cobis..cl_cab_formato_archivo WHERE cf_id_cab_archivo = @i_cabecera_formato)
				begin

				delete from cobis..cl_archivo_externos_det
				where 
				aed_secuencial_cabecera = @i_cabecera_formato
				and aed_secuencial_registro = @i_secuencial
				
				end

                if (@@error <> 0)
                begin
                        /*  Error al eliminar detalle archivo */
                        exec cobis..sp_cerror
                             @t_debug= @t_debug,
                             @t_file = @t_file,
						     @s_culture   = @s_culture,
                             @t_from = @w_sp_name,
                             @i_num  = 1720457
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

if (@t_trn = 172178)
begin

         select  
			'Id Cabecera'	= aed_secuencial_cabecera, 
			'Secuencial'	= aed_secuencial_registro,
			'Id Detalle'    = aed_id_detalle,
			'Valor'      	= aed_valor
         from  cobis..cl_archivo_externos_det
		 order by aed_secuencial_registro
                
       if (@@rowcount = 0)
       begin
         /*  No hay detalles de archivos disponibles para este formato  */
         exec cobis..sp_cerror
                 @t_debug= @t_debug,
                 @t_file = @t_file,
				 @s_culture   = @s_culture,
                 @t_from = @w_sp_name,
                 @i_num  = 1720454
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

