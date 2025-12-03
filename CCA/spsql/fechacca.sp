/************************************************************************/
/*	Archivo:		fechacca.sp        			*/
/*	Stored procedure:	sp_fecha_bcartera                       */
/*	Base de datos:		cobis    				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Xavier Maldonado               		*/
/*	Fecha de escritura:	Enero 2001  				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	                                                                */ 
/*	Obtener la fecha cierre				                */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_fecha_bcartera')
	drop proc sp_fecha_bcartera
go

create proc sp_fecha_bcartera(
  @s_ssn			int = null,
  @s_date			datetime = null,
  @s_user			login = null,
  @s_term			descripcion = null,
  @s_corr			char(1) = null,
  @s_ssn_corr		        int = null,     
  @s_ofi			smallint = null,
  @t_rty			char(1) = null, 
  @t_trn			smallint = 601,
  @t_debug		        char(1) = 'N',
  @t_file			varchar(14) = null,
  @t_from			varchar(30) = null,
  @i_operacion		        char(1),
  @i_fecha	        	datetime = null,
  @i_formato_fecha              int = null       
)

as 
declare
   @w_sp_name			varchar(30),
   @w_today			datetime,
   @w_date			datetime,
   @w_producto                  tinyint

   select @w_today = getdate()
   select @w_sp_name = 'sp_fecha_bcartera'

 

if (@t_trn <> 7230 and @i_operacion = 'U') or (@t_trn <> 7231 and @i_operacion = 'S')  begin

 exec cobis..sp_cerror
 @t_debug = @t_debug,
 @t_file  = @t_file,
 @t_from  = @w_sp_name,
 @i_num	  = 601077
 return 1
end


select @w_producto = pd_producto
  from cobis..cl_producto
  where pd_abreviatura = 'CCA'
  set transaction isolation level read uncommitted

		
if @i_operacion = 'U' begin
   begin tran

   select @w_date = convert(datetime,@i_fecha)
   exec ADMIN...rp_date_proc @i_fecha = @w_date

   update cobis..ba_fecha_cierre
   set fc_fecha_cierre = @i_fecha
   where fc_producto = @w_producto
   if @@error <> 0 begin
		
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file	 = @t_file,
    @t_from	 = @w_sp_name,
    @i_num	 = 805037
    return 1
   end
   commit tran
   return 0
end


if @i_operacion = 'S' begin
   select 
   convert(char(10),fc_fecha_cierre,@i_formato_fecha)
   from cobis..ba_fecha_cierre
   where fc_producto = @w_producto


   if @@rowcount = 0 begin	
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file	 = @t_file,
      @t_from	 = @w_sp_name,
      @i_num	 = 801085
      return 1
   end
   set rowcount 0
	
 return 0

end
 
go

















