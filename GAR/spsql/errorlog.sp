/*************************************************************************/
/*   Archivo:              errorlog.sp                                   */
/*   Stored procedure:     sp_errorlog                                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_errorlog') IS NOT NULL
    DROP PROCEDURE dbo.sp_errorlog
go
create proc dbo.sp_errorlog

        @i_fecha                datetime,

        @i_error                int,

        @i_usuario              login,

        @i_tran                 int,

        @i_tran_name            descripcion,

        @i_rollback             char(1),

        @i_cuenta               cuenta       = NULL, 

        @i_descripcion          varchar(255) = NULL

as

declare @w_aux                  int,

        @w_err_msg              varchar(255)



select @w_aux = @@trancount



while @@trancount > 0 rollback



select @w_err_msg = mensaje

  from cobis..cl_errores

 where numero = @i_error 



select @i_descripcion = ISNULL(@i_descripcion,''),

       @i_tran_name   = ISNULL(@i_tran_name,  ''),

       @w_err_msg     = ISNULL(@w_err_msg,    '')



select @w_err_msg = @i_descripcion +' '+ @i_tran_name +' '+ @w_err_msg



insert cu_errorlog (

   er_fecha_proc, er_error, er_usuario, er_tran, er_cuenta,er_descripcion)

values(

   @i_fecha,      @i_error, @i_usuario, @i_tran, @i_cuenta,@w_err_msg)



while @@trancount < @w_aux begin tran



return 0
go