/************************************************************************/
/*  Archivo:            catalogvalordet.sp                              */
/*  Stored procedure:   sp_catalog_valor_det                            */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Credito y Cartera                               */
/*  Disenado por:       Pedro Montenegro                                */
/*  Fecha de escritura: 01/11/2016                                      */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*              PROPOSITO                                               */
/*  Devuelve los registros de la tabla ca_valor_det para un combo tipo  */
/*  catalogo                                                            */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR            RAZON                                  */
/*  01/11/2016  Pedro Montenegro Emision inicial                        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_catalog_valor_det')
   drop proc sp_catalog_valor_det
go
create proc sp_catalog_valor_det (
@i_operacion         char(1),
@i_cant_reg          int = 20,
@i_siguiente         catalogo = ''
)
as

declare
@w_return             int,
@w_sp_name            varchar(32),
@w_error              int

/* Inicializacion de variables */
select @w_sp_name = 'sp_catalog_valor_det'
       
/* Chequeo de Existencias */
if @i_operacion = 'Q' begin
   if @i_cant_reg > 0
      set rowcount @i_cant_reg
   
   select distinct vd_tipo 
   from cob_cartera..ca_valor_det
   where vd_tipo > @i_siguiente

   if (@@error != 0)
   begin
      select @w_error  = 1909002
      goto ERROR
   end
end

return 0
ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error 
return @w_error 
go
