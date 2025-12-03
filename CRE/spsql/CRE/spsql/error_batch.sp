/************************************************************************/
/*  Archivo:                error_batch.sp                              */
/*  Stored procedure:       sp_error_batch                              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
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
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_error_batch')
    drop proc sp_error_batch
go

create proc sp_error_batch(

        @i_fecha                datetime,
        @i_error                int,
        @i_programa             varchar(32),
        @i_producto             tinyint = null,
        @i_operacion            cuenta = null, 
        @i_descripcion          varchar(200) = null        
)
as
declare 
@w_aux         int,
@w_err_msg     varchar(200)


select @w_aux = @@trancount

while @@trancount > 0 rollback

select @w_err_msg = mensaje
  from cobis..cl_errores
 where numero = @i_error 

select @w_err_msg     = isnull(@i_descripcion,@w_err_msg)

insert into cr_errorlog (
			er_fecha_proc,		er_error,			er_usuario, 
			er_tran,			er_cuenta,			er_descripcion )
values (	@i_fecha,			@i_error,			'batch',
			@i_producto,		@i_operacion,		@w_err_msg     )	
/*
insert into cr_errores_sib (
			es_programa,		es_descripcion,		es_error, 
			es_producto,		es_operacion,		es_fecha)
values	 (  @i_programa,		@w_err_msg,			@i_error, 
			@i_producto,		@i_operacion,		@i_fecha)
*/

while @@trancount < @w_aux begin tran

return

GO

