/************************************************************************/
/*   Archivo:             qroper.sp                                     */
/*   Stored procedure:    sp_qr_operacion_int                           */
/*   Base de datos:       cob_interface                                 */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Guisela Fernandez                             */
/*   Fecha de escritura:  06/09/2021                                    */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Este programa ejecuta el query de operaciones de cartera           */
/*   llamado por el SP sp_operacion_qry. para servicio de consulta de   */
/*   Datos generales del prestamo                                       */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR             RAZON                          */
/* 06/09/2021      G. Fernandez        Emision Inicial                  */
/* 09/May/2022     B. Dueñas           Mejora Redmine #183492           */
/************************************************************************/

use cob_interface
go

if exists (select 1 from sysobjects where name = 'sp_qr_operacion_int')
   drop proc sp_qr_operacion_int
go

create proc sp_qr_operacion_int (
@s_user                  varchar(14),
@s_term                  varchar(30),
@s_date                  datetime,
@s_ofi                   smallint,
@t_trn                  INT       = NULL, --LPO CDIG Cambio de Servicios a Blis                  
@i_banco                cuenta  = null,
@i_formato_fecha        int     = null,
@i_operacion            char(1) = null,
@i_tramite              int     = null,
@i_cliente              int     = null
)
as
declare 
@w_sp_name             varchar(32),
@w_error               int

select
@w_sp_name = 'sp_qr_operacion_int'

if @i_banco is null and @i_tramite is null
begin
   --lanzar error que no se puede realizar la consulta
   select @w_error = 149077
   GOTO ERROR
end


if @i_banco is null
begin
   select  @i_banco = op_banco
   from  cob_cartera..ca_operacion
   where op_tramite = @i_tramite
end

if @i_cliente is not null
begin
   select  @i_banco = op_banco
   from    cob_cartera..ca_operacion
   where   op_ref_grupal = @i_banco
   and     op_cliente    = @i_cliente
end

if @i_banco is null
begin
   --NO SE ENCONTRO EL CREDITO/OPERACION
   select @w_error = 3107630
   GOTO ERROR
end

if @t_trn = 77554
begin
    exec cob_cartera..sp_qr_operacion
    @s_term           = @s_term ,
    @s_user           = @s_user,
    @s_date           = @s_date,
    @s_ofi            = @s_ofi,
    @t_trn            = 714500,
    @i_banco          = @i_banco ,
    @i_formato_fecha  = @i_formato_fecha
end
else
begin
    select @w_error = 725082
    GOTO ERROR
end
return 0
 
ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

GO
