/************************************************************************/
/*  Archivo:            narcos.sp                                       */
/*  Stored procedure:   sp_narcos_con                                   */
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
/*  Query de datos de narcos                                            */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*	26/01/2021	I.Yupa		CLI-S412373-PRD- Malas Referencias			*/
/************************************************************************/
use cobis
go
if exists (select * from sysobjects where name = 'sp_narcos_con')
   drop proc sp_narcos_con
go
create proc sp_narcos_con (
		@s_culture		  varchar(10)   = 'NEUTRAL',
		@s_ssn            int         = null,
		@s_user           login       = null,
		@s_term           varchar(30) = null,
		@s_date           datetime    = null,
		@s_srv            varchar(30) = null,
		@s_lsrv           varchar(30) = null,
		@s_ofi            smallint    = null,
		@s_rol            smallint 	= NULL,
		@s_org_err        char(1) 	= NULL,
		@s_error          int 		= NULL,
		@s_sev            tinyint 	= NULL,
		@s_msg            descripcion = NULL,
		@s_org            char(1) 	= NULL,
		@t_show_version   bit           = 0,     -- mostrar la version del programa
		@t_debug          char(1)     = 'N',
		@t_file           varchar(10) = null,
		@t_from           varchar(32) = null,
		@t_trn            int 	= null,
		@i_operacion      char(1),
		@i_modo			  tinyint   	= null,
		@i_tipo           char(1)   	= "N",
		@i_codigo         int 		= null,
		@i_nombre         varchar(40) = "%",
		@i_cedula         char(13) 	= "%",
		@i_pasaporte	  char(20) 	= null,
		@i_formato_fecha  tinyint   = 103
)
as
declare @w_today		datetime,
	@w_sp_name          varchar(32),
	@w_return           int,
	@w_codigo           int,
	@w_nombre           varchar(40),
	@w_cedula           char(13),
	@w_pasaporte        char(20),
	@w_narco	    	char(1),
	@w_sp_msg			varchar(132)
	
select @w_today = getdate()
select @w_sp_name = 'sp_narcos_con',
	   @w_sp_msg  = ''
	   

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
		
/* Search */
If @i_operacion = 'S' 
begin
     if @t_trn != 172193
     begin
	exec sp_cerror
	   @t_debug      = @t_debug,
	   @t_file       = @t_file,
	   @t_from       = @w_sp_name,
	   @i_num        = 1720417,
	   @s_culture    = @s_culture
	   /*  'No corresponde codigo de transaccion' */
	return 1
     end
     set rowcount 20
	if @i_tipo = 'C'
	begin
  	   if @i_modo = 0
	   begin
        	select   "2950" =  na_nombre, 
                	 "5135" =  na_cedula,
                	 "5115" =  na_pasaporte,
                	 "3084" =  na_nacionalidad,
                	 "5169" =  na_circular,
                	 "3145" =  convert(varchar, convert(datetime, na_fecha),@i_formato_fecha),
                	 "2945" =  na_provincia,
					 "5170" =  na_juzgado,
					 "5171" =  na_juicio,
					 "2934" =  na_narcos,
					 "tipo" = 'N',
					 "descripcionTipo" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = 'cl_tipo_mala_referencia') AND codigo = 'N')					 
         	from   cl_narcos
	 	where na_cedula like @i_cedula
		order by na_narcos,na_cedula, na_pasaporte
	    end
	   else
	    begin
  	      if @i_modo = 1
        	select   "2950" =  na_nombre, 
                	 "5135" =  na_cedula,
                	 "5115" = na_pasaporte,
                	 "3084" =  na_nacionalidad,
                	 "5169" =  na_circular,
                	 "3145" =  convert(varchar, convert(datetime, na_fecha),@i_formato_fecha),
                	 "2945" =  na_provincia,
					 "5170" =  na_juzgado,
					 "5171" =  na_juicio,
					 "2934" =  na_narcos,
					 "tipo" = 'N',
					 "descripcionTipo" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = 'cl_tipo_mala_referencia') AND codigo = 'N')					 
         	from   cl_narcos
	 	where na_cedula like @i_cedula 
		and na_narcos > @i_codigo
	 	order by na_narcos, na_cedula
	    end
	   end
	else
	  begin
  	     if @i_modo = 0
	       begin
        	select   "2950" =  na_nombre, 
                	 "5135" =  na_cedula,
                	 "5115" = na_pasaporte,
                	 "3084" =  na_nacionalidad,
                	 "5169" =  na_circular,
                	 "3145" =  convert(varchar, convert(datetime, na_fecha),@i_formato_fecha),
                	 "2945" =  na_provincia,
					 "5170" =  na_juzgado,
					 "5171" =  na_juicio,
					 "2934" =  na_narcos,
					 "tipo" = 'N',
					 "descripcionTipo" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = 'cl_tipo_mala_referencia') AND codigo = 'N')					 
         	from   cl_narcos
	 	where na_nombre like  @i_nombre
		order by  na_narcos, na_nombre
               end
	     else
  	      if @i_modo = 1
        	select   "2950" =  na_nombre, 
                	 "5135" =  na_cedula,
                	 "5115" = na_pasaporte,
                	 "3084" =  na_nacionalidad,
                	 "5169" =  na_circular,
                	 "3145" =  convert(varchar, convert(datetime, na_fecha),@i_formato_fecha),
                	 "2945" =  na_provincia,
					 "5170" =  na_juzgado,
					 "5171" =  na_juicio,
					 "2934" =  na_narcos,
					 "tipo" = 'N',
					 "descripcionTipo" = (SELECT valor FROM cl_catalogo WHERE tabla = (SELECT codigo FROM cl_tabla WHERE tabla = 'cl_tipo_mala_referencia') AND codigo = 'N')					 
         	from   cl_narcos
	 	where na_nombre like @i_nombre
		and na_narcos > @i_codigo
		order by na_narcos, na_nombre
	end
     set rowcount 0
     return 0
end
/** QUERY **/
/*Consulta para actualizar archivo de NARCOS*/
If @i_operacion = 'Q' 
begin
     if @t_trn != 172194
     begin
	exec sp_cerror
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
        	select   "2950" =  na_nombre, 
                	 "5135" =  na_cedula,
                	 "5115" = na_pasaporte,
                	 "3084" =  na_nacionalidad,
                	 "5169" =  na_circular,
                	 "3145" =  na_fecha,
                	 "2945" =  na_provincia,
			 "5170" =  na_juzgado,
			 "5171" =  na_juicio,
			 "2934" =  na_narcos
       	from   cl_narcos
 	where na_narcos = @i_codigo
       return 0
      end
end
/* Consultar si el cliente peretenece a narcotrÿfico */
If @i_operacion = 'E' 
begin
        if exists (select 1 from   cl_narcos
                   where na_cedula = @i_cedula)
        begin
             select @w_narco = 'S'
        end
        else
        begin
             select @w_narco = 'N'
        end
	select @w_narco 
return 0
end
go
