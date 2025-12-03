/************************************************************************/
/*	Archivo:									dato_adicional.sp		*/
/*	Stored procedure:							sp_dato_adic			*/
/*	Base de datos:								cobis					*/
/*	Producto: 									Clientes				*/
/*	Disenado por:  								Alfonso Castro.			*/
/*	Fecha de escritura: 						16-Mar-2021				*/
/************************************************************************/
/*									IMPORTANTE							*/
/*	Este programa es parte de los paquetes bancarios propiedad de		*/
/*	"COBIS", representantes exclusivos para el Ecuador de la 			*/
/*	"NCR CORPORATION".													*/
/*	Su uso no autorizado queda expresamente prohibido asi como			*/
/*	cualquier alteracion o agregado hecho por alguno de sus				*/
/*	usuarios sin el debido consentimiento por escrito de la 			*/
/*	Presidencia Ejecutiva de COBIS o su representante.					*/
/*							ROPOSITO									*/
/*	Este programa procesa las transacciones del stored procedure		*/
/*	Insercion de referencia comercial									*/
/*	Actualizacion de referencia comercial								*/
/*	Borrado de referencia comercial		        						*/
/*	Busqueda de referencia comercial general y especifica           	*/	
/*								MODIFICACIONES							*/
/*	FECHA					AUTOR					RAZON				*/
/*  05/04/21 				ACA 				Creacion del sp			*/
/*	13/04/21				COB			Configuracion para seudocodigo 	*/ 
/************************************************************************/

use cobis
go

if object_id('sp_dato_adic') is not null
begin
	drop procedure sp_dato_adic
end

go

create proc sp_dato_adic (
   @s_ssn				int 			= 				null, 
   @s_user				login 			= 				null, 
   @s_term				varchar(30) 	= 				null, 
   @s_date				datetime 		= 				null, 
   @s_srv				varchar(30) 	= 				null, 
   @s_lsrv				varchar(30) 	= 				null, 
   @s_ofi		    	smallint 		= 				null, 
   @s_rol				smallint 		=	 			null, 
   @s_org_err			char(1)			= 				null, 
   @s_error				int 			= 				null, 
   @s_sev				tinyint			= 				null, 
   @s_msg				descripcion 	= 				null, 
   @s_org				char(1) 		= 				null, 
   @t_debug	    		char(1) 		= 				'N', 
   @t_file		    	varchar(10) 	= 				null,
   @t_from		    	varchar(32) 	= 				null,
   @t_trn		   		int 			= 				null,
   @i_operacion    		char(1),
   @i_codigo			smallint 		= 				NULL,
   @i_descripcion  		descripcion 	= 				NULL,
   @i_tipodato			CHAR(1) 		= 				NULL,
   @i_mandatorio 		CHAR(1) 		= 				NULL,
   @i_valor				descripcion 	= 				NULL,
   @i_tipoente			CHAR(1) 		= 				NULL,
   @i_catalogo 			varchar(30) 	= 				null,
   @i_bdatos			varchar(30) 	= 				null,
   @i_stored_procedure	varchar(50) 	= 				null
)

as

declare @w_today		datetime,
		@w_sp_name      varchar(32),
		@w_return       int,
		@w_siguiente 	int

select @w_sp_name = 'sp_dato_adic'

/* inserta el registro indicado de datos adicionales*/

if @i_operacion = 'I'

begin
   /* validación de catálogo de tipos de datos*/
   if not exists (select 1 
				  from   cobis..cl_catalogo c, cobis..cl_tabla t 
				  where t.tabla = 'cl_tipos_datos' 
				  and t.codigo 	= c.tabla 
				  and c.codigo 	= @i_tipodato)
   begin 
      /* No existe el tipo de dato */ 
      exec cobis..sp_cerror  
         @t_debug= @t_debug, 
         @t_file = @t_file, 
         @t_from = @w_sp_name,
         @i_num  = 1720466   
      return 1 
   end
   /*Validar catálogo Mandatorio*/
   if not exists (select 1 
				  from   cobis..cl_catalogo c, cobis..cl_tabla t 
		          where t.tabla = 'cl_mandatorio' 
				  and t.codigo 	= c.tabla 
				  and c.codigo 	= @i_mandatorio) 
   begin 
      /* No existe el valor mandatorio */ 
      exec cobis..sp_cerror  
         @t_debug	= @t_debug, 
         @t_file 	= @t_file, 
         @t_from 	= @w_sp_name,
         @i_num  	= 1720467   
      return 1 
   end
   /*Validar catálogo tipo cliente*/
   if not exists (select 1 
				  from   cobis..cl_catalogo c, cobis..cl_tabla t 
				  where t.tabla = 'cl_tipo_clientes' 
				  and t.codigo = c.tabla 
				  and c.codigo = @i_tipoente) 
   begin 
      /* No existe el tipo de cliente */ 
      exec cobis..sp_cerror
	       @t_debug	= @t_debug,
		   @t_file 	= @t_file, 
           @t_from 	= @w_sp_name,
           @i_num  	= 1720468   
      return 1 
   end
   /*Validar que no se repita el dato adicional*/
   if exists (select 1 
			  from cobis..cl_dato_adicion
		      where da_descripcion = @i_descripcion 
			  and da_tipo_ente = @i_tipoente) 
   begin 
   /* YA existe este dato adicional */ 
      exec cobis..sp_cerror  
	  	   @t_debug	= @t_debug, 
           @t_file 	= @t_file, 
           @t_from 	= @w_sp_name,
           @i_num  	= 1720469   
       return 1 
   end
   /* encontrar un nuevo secuencial para datos adicionales */
   exec sp_cseqnos
		@t_debug      = @t_debug,
		@t_file       = @t_file,
		@t_from       = @w_sp_name,
		@i_tabla      = 'cl_dato_adicion',
		@o_siguiente  = @w_siguiente out

   insert into cl_dato_adicion (da_codigo,		da_descripcion,	da_tipo_dato,    
								da_mandatorio,	da_valor,		da_tipo_ente,
								da_catalogo,	da_bdatos,		da_sprocedure) 
   values 					   (@w_siguiente,	@i_descripcion,	@i_tipodato,
								@i_mandatorio,	@i_valor,	@i_tipoente,
								@i_catalogo,	@i_bdatos,	@i_stored_procedure)
   
   if @@error != 0
   begin
      exec sp_cerror
		   @t_debug    = @t_debug,
		   @t_file     = @t_file,
		   @t_from     = @w_sp_name,
		   @i_num      = 1720462
		   /* 'Error en la creación dato adicional'*/
	  return 1
   end
end



/* Modifica el registro indicado de datos adicionales*/
if @i_operacion = 'U'
begin
   if exists (select 1 
			  from cobis..cl_dato_adicion
		      where da_descripcion = @i_descripcion 
			  and da_tipo_ente = @i_tipoente 
			  and da_codigo<>@i_codigo) 
   begin 
      /* YA existe este dato adicional */ 
      exec cobis..sp_cerror  
           @t_debug= @t_debug, 
           @t_file = @t_file, 
           @t_from = @w_sp_name,
           @i_num  = 1720469   
      return 1 
   end

   if exists (select 1 
			  from cl_dadicion_ente
		      where de_dato = @i_codigo)
   begin
      exec sp_cerror
		   @t_debug    = @t_debug,
		   @t_file     = @t_file,
		   @t_from     = @w_sp_name,
		   @i_num      = 1720481
		 /* 'El dato esta siendo usado en algun cliente'*/
      return 1
   end

   UPDATE cl_dato_adicion
   SET da_descripcion 	= @i_descripcion,
	   da_mandatorio  	= @i_mandatorio,
	   da_valor       	= @i_valor,
	   da_catalogo	   	= @i_catalogo,
	   da_tipo_ente   	= @i_tipoente,
	   da_tipo_dato   	= @i_tipodato,
	   da_bdatos	   	= @i_bdatos,
	   da_sprocedure  	= @i_stored_procedure
	WHERE da_codigo    	= @i_codigo
   
   if @@error != 0
   begin
      exec sp_cerror
		   @t_debug    = @t_debug,
		   @t_file     = @t_file,
		   @t_from     = @w_sp_name,
		   @i_num      = 1720463
		 /* 'Error en modificacion de dato adicional'*/
      return 1
   end
end

/* elimina el registro indicado de datos adicionales*/
if @i_operacion = 'D'
begin
   if exists (select 1 
			  from cl_dadicion_ente
		      where de_dato = @i_codigo)
   begin
      exec sp_cerror
		   @t_debug    = @t_debug,
		   @t_file     = @t_file,
		   @t_from     = @w_sp_name,
		   @i_num      = 1720480
		 /* 'El dato esta siendo usado en algun cliente'*/
      return 1
   end
   DELETE FROM cl_dato_adicion
   WHERE da_codigo = @i_codigo
end



/* consulta la informacion de datos adicionales*/
if @i_operacion = 'Q'

begin
   select	da_codigo,
			da_descripcion,
			da_tipo_dato,
			(select	valor
				from 	cobis..cl_catalogo c, cobis..cl_tabla t 
				where 	t.tabla = 'cl_tipos_datos' 
				and		t.codigo = c.tabla 
				and 	c.codigo = da_tipo_dato),
			da_mandatorio,
			(select 	valor 
				from 	cobis..cl_catalogo c, cobis..cl_tabla t 
				where 	t.tabla = 'cl_mandatorio' 
				and 	t.codigo = c.tabla 
				and 	c.codigo = da_mandatorio),
			da_valor,
			da_tipo_ente,
			(select 	valor 
				from 	cobis..cl_catalogo c, cobis..cl_tabla t 
				where 	t.tabla = 'cl_tipo_clientes' 
				and 	t.codigo = c.tabla 
				and 	c.codigo = da_tipo_ente),
			da_catalogo,
			da_bdatos,
			da_sprocedure,
			CASE da_tipo_dato
				WHEN 'A' THEN da_catalogo
				WHEN 'P' THEN da_bdatos + '..' + da_sprocedure				 
				ELSE ''
			END
   from   cl_dato_adicion
   
   if @@rowcount = 0
   begin
      exec cobis..sp_cerror
           @t_debug    = @t_debug,
		   @t_file     = @t_file,
		   @t_from     = @w_sp_name,
		   @i_num      = 1720464
		   /*  'No existe dato solicitado'*/
	  return 1
   end
end

if @i_operacion = 'S'
begin
   select	da_codigo,
			da_descripcion,
			da_tipo_dato,
			(select	valor
				from 	cobis..cl_catalogo c, cobis..cl_tabla t 
				where 	t.tabla = 'cl_tipos_datos' 
				and		t.codigo = c.tabla 
				and 	c.codigo = da_tipo_dato),
			da_mandatorio,
			(select 	valor 
				from 	cobis..cl_catalogo c, cobis..cl_tabla t 
				where 	t.tabla = 'cl_mandatorio' 
				and 	t.codigo = c.tabla 
				and 	c.codigo = da_mandatorio),
			da_valor,
			da_tipo_ente,
			(select 	valor 
				from 	cobis..cl_catalogo c, cobis..cl_tabla t 
				where 	t.tabla = 'cl_tipo_clientes' 
				and 	t.codigo = c.tabla 
				and 	c.codigo = da_tipo_ente),
			da_catalogo,
			da_bdatos,
			da_sprocedure,
			CASE da_tipo_dato
				WHEN 'A' THEN da_catalogo
				WHEN 'P' THEN da_bdatos + '..' + da_sprocedure				 
				ELSE ''
			END
   from   cl_dato_adicion
   where  da_codigo = @i_codigo
   
   if @@rowcount = 0
   begin
      exec cobis..sp_cerror
           @t_debug    = @t_debug,
		   @t_file     = @t_file,
		   @t_from     = @w_sp_name,
		   @i_num      = 1720464
		   /*  'No existe dato solicitado'*/
	  return 1
   end
end

go
