/************************************************************************/
/*	Archivo:		catrubro.sp				*/
/*	Stored procedure:	sp_categoria_rubro			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Juan Sarzosa				*/
/*	Fecha de escritura:	23/11/1995				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Este programa realiza la consulta de la tabla 			*/
/*	ca_categoria_rubro.						*/
/************************************************************************/  
/*			MODIFICACIONES					*/
/*									*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_categoria_rubro')
	drop proc sp_categoria_rubro
go

create proc sp_categoria_rubro (@i_modo tinyint, @i_codigo varchar = null)
as
declare 
@w_sp_name		descripcion,
@w_error		int

/** CARGADO DE VARIABLES DE TRABAJO **/
select @w_sp_name = 'sp_categoria_rubro'

if @i_modo = 0 begin
  select 
  'CODIGO' = cr_codigo,
  'DESCRIPCION' =   cr_descripcion
  from ca_categoria_rubro

  if @@rowcount = 0   begin
    select @w_error = 710026
    exec cobis..sp_cerror
    @t_debug     = 'N',
    @t_file      = null,
    @t_from      = @w_sp_name,
    @i_num       = @w_error
    return @w_error
  end
  else
  return 0
end

if @i_modo = 1 begin
  select 
  cr_descripcion
  from ca_categoria_rubro
  where cr_codigo = @i_codigo	

  if @@rowcount = 0 begin
    select @w_error = 710026
    exec cobis..sp_cerror
    @t_debug     = 'N',
    @t_file      = null,
    @t_from      = @w_sp_name,
    @i_num       = @w_error
    return @w_error
  end
  else
  return 0
end
go
