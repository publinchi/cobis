/************************************************************************/
/*      Archivo:                diasgrac.sp                             */
/*      Stored procedure:       sp_dias_gracia                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           P. Narvaez   			        */
/*      Fecha de escritura:     Ene 12. 1998                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*				PROPOSITO				*/
/*	U: Actualizacion de los dias de gracia de un dividendo de una   */
/*	   operacion	                                                */
/*	Q: Consulta de los dias de gracia de un dividendo de una op.    */
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dias_gracia')
    drop proc sp_dias_gracia
go

create proc sp_dias_gracia (
   @s_ofi                smallint,
   @s_date               datetime,
   @s_user               login,
   @s_term               varchar(30),
   @i_operacion          char(1),
   @i_banco              cuenta       = null,
   @i_dividendo          smallint     = null,
   @i_gracia             smallint     = null,
   @i_gracia_disp        smallint     = null
)
as

declare
   @w_error              int,
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_operacionca        int,
   @w_clave1             varchar(255),
   @w_clave2             varchar(255),
   @w_return             int,
   @w_max_dia_grac       int

select @w_sp_name = 'sp_dias_gracia'

/*EXTRAER EL CODIGO DE LA OPERACION*/

select  @w_operacionca = opt_operacion
from ca_operacion_tmp
where opt_banco = @i_banco

/* BUSQUEDA */
if @i_operacion = 'Q' begin
   select
   dit_gracia,
   dit_gracia_disp
   from ca_dividendo_tmp
   where dit_operacion = @w_operacionca
   and   dit_dividendo = @i_dividendo 

end


/* Actualizacion del registro */
if @i_operacion = 'U' begin

   /* AUMENTO 03/02/1999 */ 
   select @w_max_dia_grac = pa_int 
   from cobis..cl_parametro 
   where pa_producto = 'CCA' 
   and  pa_nemonico = 'MDG'
   set transaction isolation level read uncommitted

   if @w_max_dia_grac < @i_gracia  begin
      select @w_error = 701180
      goto ERROR
   end 

   begin tran

   select @w_clave1 = convert(varchar(255),@w_operacionca)
   select @w_clave2 = convert(varchar(255),@i_dividendo)
   
   exec @w_return = sp_tran_servicio
   @s_user    = @s_user,
   @s_date    = @s_date,
   @s_ofi     = @s_ofi,
   @s_term    = @s_term,
   @i_tabla   = 'ca_dividendo',
   @i_clave1  = @w_clave1,
   @i_clave2  = @w_clave2
   
   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end

   update ca_dividendo_tmp set 
   dit_gracia      = dit_gracia + @i_gracia,
   dit_gracia_disp = dit_gracia_disp + @i_gracia_disp
   where dit_operacion = @w_operacionca
   and   dit_dividendo = @i_dividendo
    
   if @@error <> 0 begin
      select @w_error   = 701156
      goto ERROR
   end

   commit tran
end


return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error
return 1

go
