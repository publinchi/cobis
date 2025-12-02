/************************************************************************/
/*	Archivo:		consofi.sp        			*/
/*	Stored procedure:	sp_consulta_oficial                     */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Juan Sarzosa               		*/
/*	Fecha de escritura:	Ene  2 2000  				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA"							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	                                                                */ 
/*	S: Buscar el oficial asignado a un cliente                      */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_consulta_oficial')
	drop proc sp_consulta_oficial
go


create proc sp_consulta_oficial (
        @t_debug		char(1)     = 'N',
	@t_file			varchar(14) = null,
	@t_trn			smallint    = null,
       	@i_operacion            char(1)     = 'S',
        @i_codigo		char(10)    = null,
       	@i_nit 		        int         = null

)
as
declare  @w_sp_name varchar(32),
	 @w_rowcount   int
select @w_sp_name = 'sp_consulta_ref'


/* Search */
if @i_operacion = 'S' begin
   If @t_trn =7226    begin
      select en_oficial from cobis..cl_ente where en_ente = @i_nit
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted

      if @w_rowcount = 0      begin
	 exec cobis..sp_cerror
	      @t_debug	 = @t_debug,
	      @t_file	 = @t_file,
	      @t_from	 = @w_sp_name,
	      @i_num	 = 710200
 	    /* No Existe Cliente'*/
  	 return 1
      end
      return 0
   end
   else begin
      exec cobis.. sp_cerror
	      @t_debug	 = @t_debug,
	      @t_file	 = @t_file,
   	      @t_from	 = @w_sp_name,
     	      @i_num	 = 151051
	   /*  'No corresponde codigo de transaccion' */
   return 1
  end
end
go

