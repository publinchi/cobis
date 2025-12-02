/************************************************************************/
/*	Archivo: 		qrdistri.sp				                            */
/*	Stored procedure: 	sp_qr_distribucion		                        */
/*	Base de datos:  	cob_cartera				                        */
/*	Producto: 		Credito y Cartera			                        */
/*	Disenado por:  		Sandra Ortiz			                        */
/*	Fecha de escritura: 	11-10-1994			                        */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/************************************************************************/  
/*				PROPOSITO				                                */
/*	Este programa ejecuta la consulta de operaciones de cartera	        */
/*	bajo ciertas condiciones de distribucion del credito.		        */
/************************************************************************/  
/*				MODIFICACIONES				                            */
/*	FECHA		AUTOR		RAZON				                        */
/*	11-10-1994	F. Espinosa	 Emision inicial			                */
/*  19-04-2022  K. Rodríguez Cambio catálogo destino finan. op          */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_qr_distribucion')
	drop proc sp_qr_distribucion
go

create proc sp_qr_distribucion (
		@i_operacion		char(1),
		@i_tipo			smallint = null
)
as
declare
@w_sp_name	varchar(32),	
@w_return	int,
@w_error        int

/*  Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_qr_distribucion'

if @i_operacion = 'Q' begin
   /* Consulta por tipo de Operacion */
   if @i_tipo = 1 begin
      select
      op_toperacion,
      descripcion = (select valor
                     from cobis..cl_catalogo x , cobis..cl_tabla y
                     where y.tabla = 'ca_toperacion'
                     and x.tabla = y.codigo
                     and x.codigo = o.op_toperacion),
      count (op_operacion)
      from   ca_operacion o
      group by op_toperacion
 
   end
   
   /* Consulta por destino del credito */
   if @i_tipo = 2 begin
      select
      op_ciudad,
      descripcion = ci_descripcion,
      count (op_operacion)
      from   ca_operacion,cobis..cl_ciudad
      where    op_ciudad  =  ci_ciudad 
      group by op_ciudad, ci_descripcion
   end

   /* Consulta por destino del credito */
   if @i_tipo = 3 
   begin
	select
        op_destino,
        descripcion = (select valor
                       from cobis..cl_catalogo x , cobis..cl_tabla y
                       where y.tabla = 'cr_objeto'
                       and x.tabla = y.codigo
                       and x.codigo = o.op_destino),
        count (op_operacion) 
        from   ca_operacion o
        group by op_destino
    end
end	       	

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go

