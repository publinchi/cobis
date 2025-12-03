/************************************************************************/
/*      Archivo:                errorlog.sp                             */
/*      Stored procedure:       sp_errorlog                             */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Juan Jose Lam                           */
/*      Fecha de documentacion: 24/Oct/94                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Este script crea los procedimientos para las inserciones        */
/*      de errores generados por los procesos batch                     */
/*                                                                      */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA      AUTOR              RAZON                             */
/*      24-Oct-94  Juan Lam           Creacion                          */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists ( select name  from sysobjects where name = 'sp_errorlog')
	drop proc sp_errorlog
go
create proc sp_errorlog
        @i_fecha                datetime,
        @i_error                int,
        @i_usuario              login,
        @i_tran                 int,
        @i_tran_name            descripcion,
        @i_rollback             char(1),
        @i_cuenta               cuenta=NULL, 
        @i_descripcion          varchar(255) = null,
	@i_anexo		varchar(255) = null
as
declare @w_aux                  int,
        @w_err_msg              varchar(255)

select @w_aux = @@trancount


if @i_rollback = 'S'
   while @@trancount > 0 rollback


select @w_err_msg = mensaje
from cobis..cl_errores with (nolock)
where numero = @i_error 
set transaction isolation level read uncommitted

select 
@i_descripcion = isnull(@i_descripcion,''),
@i_tran_name   = isnull(@i_tran_name,  ''),
@w_err_msg     = isnull(@w_err_msg,    ''),
@i_anexo       = isnull(@i_anexo,      '')

select @w_err_msg = @i_descripcion +' '+ @i_tran_name +' '+ @w_err_msg

insert ca_errorlog (
er_fecha_proc,	er_error,	er_usuario,
er_tran,	er_cuenta,	er_descripcion,
er_anexo)
values(
@i_fecha,	@i_error,	@i_usuario,
@i_tran,	@i_cuenta,	@w_err_msg,
@i_anexo)



if @i_rollback = 'S'
   while @@trancount < @w_aux begin tran

return
go







