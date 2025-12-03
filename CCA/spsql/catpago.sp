/************************************************************************/
/*	Archivo:		catpago.sp				                            */
/*	Stored procedure:	sp_categoria_pago			                    */
/*	Base de datos:		cob_cartera				                        */
/*	Producto: 		Cartera					                            */
/*	Disenado por:  		Juan Sarzosa				                    */
/*	Fecha de escritura:	23/11/1995				                        */
/************************************************************************/
/*				IMPORTANTE				                                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	"MACOSA".							                                */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				PROPOSITO				                                */
/*	Este programa realiza la consulta de la tabla 			            */
/*	cl_forma de cobis.						                            */
/************************************************************************/  
/*			MODIFICACIONES					                            */
/*									                                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_categoria_pago')
	drop proc sp_categoria_pago
go

create proc sp_categoria_pago (@i_modo tinyint, 
                               @i_codigo varchar(10) = null)
as
declare 
@w_sp_name		descripcion,
@w_error		int,
@w_rowcount             int

/** CARGADO DE VARIABLES DE TRABAJO **/
select @w_sp_name = 'sp_categoria_pago'

if @i_modo = 0 begin
   select 
   'CODIGO' = codigo,
   'DESCRIPCION' =   valor
   from cobis..cl_catalogo
   where tabla  =  (select codigo from cobis..cl_tabla
                    where tabla = 'cl_cforma')
end

if @i_modo = 1 begin
   select 
   valor
   from cobis..cl_catalogo
   where tabla  =  (select codigo
   from cobis..cl_tabla
   where tabla = 'cl_cforma')
   and codigo = @i_codigo
end

if @i_modo = 2 begin
   select 
   'CODIGO' = codigo,
   'DESCRIPCION' =   valor
   from cobis..cl_catalogo
   where tabla  =  (select codigo from cobis..cl_tabla
                    where tabla = 'cl_canal')
end

if @i_modo = 3 begin
   select 
   valor
   from cobis..cl_catalogo
   where tabla  =  (select codigo
   from cobis..cl_tabla
   where tabla = 'cl_canal')
   and codigo = @i_codigo
end


return 0
go
