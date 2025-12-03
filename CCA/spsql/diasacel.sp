/************************************************************************/
/*      Archivo:                diasacel.sp                             */
/*      Stored procedure:       sp_dias_aceleratoria                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Juan Carlos Espinosa   			*/
/*      Fecha de escritura:     Abril. 1998                             */
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
/*	I: Ingreso de registro de dias aceleratoria			*/
/*	U: Actualizacion de registro de dias aceleratoria		*/
/*	S: Busqueda de registro de dias aceleratoria			*/
/*	Q: Consulta de registro de dias aceleratoria			*/
/*	D: Eliminacion de registro de dias aceleratoria			*/
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dias_aceleratoria')
    drop proc sp_dias_aceleratoria
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


create proc sp_dias_aceleratoria (
   @t_debug              char(1)  = 'N',
   @i_operacion          char(1),
   @i_dias_dividendo     int = NULL,
   @i_dias_aceleratoria  int = NULL,
   @o_dias_a_aplicar     int = NULL out
)
as

declare
   @w_error              int,
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_return             int

select @w_sp_name = 'sp_dias_aceleratoria'


if @i_operacion <> 'S' begin

    if exists(select 1 
              from cob_cartera..ca_dias_aceleratoria
              where da_dias_dividendo = @i_dias_dividendo)
       select @w_existe = 1

    else select @w_existe = 0

end


if @i_operacion = 'I' begin

    if @w_existe = 1 begin
        select @w_error   = 708151
        goto ERROR
    end

    insert into ca_dias_aceleratoria(
    da_dias_dividendo, da_dias_aceleratoria)
    values ( 
    @i_dias_dividendo, @i_dias_aceleratoria)

    if @@error <> 0 begin
       /* Error en insercion de registro */
       select @w_error   = 701155
       goto ERROR
    end

end


if @i_operacion = 'U' begin

   if @w_existe = 0 begin
      select @w_error   = 701156
      goto ERROR
   end


   update cob_cartera..ca_dias_aceleratoria set 
     da_dias_aceleratoria  = @i_dias_aceleratoria
   where da_dias_dividendo = @i_dias_dividendo

   if @@error <> 0 begin
      select @w_error   = 708152
      goto ERROR
   end

end


if @i_operacion = 'S' begin

   if @i_dias_dividendo is not NULL begin

      set rowcount 35 

      select 
      'Dias Cuota'             = da_dias_dividendo, 
      'Dias Aceleratoria'      = da_dias_aceleratoria
      from  ca_dias_aceleratoria
      where da_dias_dividendo = @i_dias_dividendo  
   
      set rowcount 0


   end 
   else begin 
      /*TODOS LOS REGISTROS O SIGUIENTES*/
      set rowcount 35 
   
      select 
      'Dias Cuota'             = da_dias_dividendo, 
      'Dias Aceleratoria'      = da_dias_aceleratoria
      from  ca_dias_aceleratoria
      order by da_dias_dividendo

   end
end



if @i_operacion = 'D' begin


   delete cob_cartera..ca_dias_aceleratoria
   where da_dias_dividendo = @i_dias_dividendo

   if @@error <> 0 begin
      select @w_error   = 710003 
      goto ERROR
   end

end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug = @t_debug,
@t_from  = @w_sp_name,
@i_num   = @w_error
return 1

go
