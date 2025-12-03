/************************************************************************/
/*  Archivo:                traslada_tramite.sp                         */
/*  Stored procedure:       sp_traslada_tramite                         */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_traslada_tramite')
    drop proc sp_traslada_tramite
go

create  proc sp_traslada_tramite
@t_trn                  int          = null,
@t_debug                char(1)      = 'N',
@t_file                 varchar(10)  = null,
@i_operacion            char(1)      = null,    
@i_cliente           	int      = null,
@i_oficina_destino   	smallint = null,
@i_oficial_origen   	smallint = null,
@i_oficial_destino   	smallint = null

as
declare
@w_error                 int,
@w_sp_name               varchar(32),
@w_msg                   varchar(255),
@w_estacion              smallint

select @w_sp_name = 'sp_traslada_tramite'

if @t_debug = 'S' print '@i_operacion  ' +  cast(@i_operacion  as varchar)

if @i_operacion = 'F' --Trasladar Creditos
begin
   
   update cob_credito..cr_linea with (rowlock) 
   set li_oficina   = @i_oficina_destino
   where li_cliente = @i_cliente
   and li_estado  in ('V','D','B')
   
   if @@error <> 0 begin
      select @w_error = 2110387
      goto ERROR
   end
   
   update cob_credito..cr_tramite with (rowlock) 
   set tr_oficina   = isnull(@i_oficina_destino,0),
       tr_oficial   = isnull(@i_oficial_destino,0)
   from cob_credito..cr_tramite
   where tr_cliente = @i_cliente

   if @@error <> 0 begin
      select @w_error = 2110388
      goto ERROR
   end
   
end 
return 0

ERROR:

exec cobis..sp_cerror
@t_debug  = @t_debug,
@t_file   = @t_file,
@t_from   = @w_sp_name,
@i_num    = @w_error

return @w_error


GO
