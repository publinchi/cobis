/************************************************************************/
/*	Archivo:		    concepto_seudo.sp                               */
/*	Stored procedure:	sp_concepto_seudo    		                    */
/*	Base de datos:		cob_cartera				                        */
/*	Producto: 		    Credito y Cartera                               */
/*	Disenado por:  		VBR                                             */
/*	Fecha de escritura:	13/12/2016				                        */
/************************************************************************/
/*				IMPORTANTE				                                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	"MACOSA".							                                */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				PROPOSITO			                        	        */
/*	Este stored procedure recupera el seudocatalogo de los conceptos.   */
/************************************************************************/
/*				MODIFICACIONES				                            */
/*	FECHA		AUTOR		RAZON				                        */
/*  13/12/2016  VBR     	Emision Inicial			                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_concepto_seudo')
	drop proc sp_concepto_seudo
go


create proc sp_concepto_seudo 
as
declare 
@w_sp_name	descripcion,
@w_error	int


/*  INICIALIZAR VARIABLES  */
select	@w_sp_name = 'sp_concepto_seudo'

/* Recupera valores del Seudocatalogo */
         select 'Codigo' = co_concepto,
         'Descripcion'   = co_descripcion
         from ca_concepto
         
         if @@rowcount = 0 begin
            select @w_error = 701000
            goto ERROR
         end
              
return 0

ERROR:
exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error

return @w_error 

go
         
         