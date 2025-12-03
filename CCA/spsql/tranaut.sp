/************************************************************************/
/*      Archivo:                tranaut.sp                              */
/*      Stored procedure:       sp_trn_aut                              */
/*      Base de datos:          cob_cartera	                        */
/*      Producto:               Cartera                                 */
/*      Disenado por:           MPO                                     */
/*      Fecha de escritura:     24-Ene-1996                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Permite verificar si un usuario tiene autorizacion para         */
/*      cambio de valores en Rubros                                     */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      24/Ene/96       MPO             Emision Inicial                 */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_trn_aut')
   drop proc sp_trn_aut
go


create proc sp_trn_aut (
	@i_login        varchar(30) = null,
	@i_pass         varchar(30) = null,
	@i_num_trn      smallint = null
	
)
as

declare
@w_sp_name      varchar(32),
@w_return       int,
@w_error        int

select @w_sp_name = 'sp_trn_aut'

/*  Verificacion de claves de acceso */

if not exists(select 1 from cobis..ad_usuario
              where us_login = @i_login)
   begin
     select @w_error = 701153
     goto ERROR
   end                         

if not exists(select 1 from cobis..ad_usuario_rol,cobis..ad_tr_autorizada 
              where ur_login = @i_login
              and   ta_transaccion = @i_num_trn
              and   ta_rol = ur_rol) 
   begin
     select @w_error = 701154
     goto ERROR
   end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go
