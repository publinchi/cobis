/*************************************************************************/
/*   Archivo:              comprobantes_error_gar.sp                     */
/*   Stored procedure:     sp_custodia                                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         Kevin Rodríguez                               */
/*   Fecha de escritura:   Septiembre 2022                               */
/*************************************************************************/
/* IMPORTANTE                                                            */
/* Este programa es parte de los paquetes bancarios propiedad de         */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la         */
/* AT&T                                                                  */
/* Su uso no autorizado queda expresamente prohibido asi como            */
/* cualquier autorizacion o agregado hecho por alguno de sus             */
/* usuario sin el debido consentimiento por escrito de la                */
/* Presidencia Ejecutiva de COBISCORP o su representante                 */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*   ACTUALIZACION DE TRANSACCIONES CON ERRORES EN LA CONTABILIZACION    */
/*                                                                       */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA          AUTOR           RAZON                               */
/*    15/09/2022     K. Rodriguez    Emisión Inicial                     */
/*************************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_comprobantes_error_gar') IS NOT NULL
    DROP PROCEDURE dbo.sp_comprobantes_error_gar
go

create proc sp_comprobantes_error_gar (
   @i_param1    int,       -- Empresa
   @i_param2    datetime   -- Fecha 
)
as

declare @w_error        int,
        @w_msg          varchar(200),
        @w_err_update1  char(1),
        @w_sp_name      varchar(50),
        @w_min_fecha    datetime

select @w_msg = null,
       @w_err_update1 = 'N',
       @w_sp_name     = 'sp_comprobantes_error_gar'


select @w_min_fecha = min(co_fecha_ini)
from cob_conta..cb_corte
where co_estado in ('V', 'A')

update cu_tran_conta
set to_estado      = 'I',
    to_comprobante = 0
from cob_conta..cb_error_conaut
where to_fecha between @w_min_fecha and @i_param2
  and ec_empresa       = @i_param1 
  and ec_fecha_conta   = @i_param2 
  and ec_producto      = 19
  and ec_comprobante   = to_comprobante

if @@error <> 0
begin
   select @w_error = @@error,
          @w_msg = 'Error en actualización de comprobantes de error en tabla ca_tran_conta',
          @w_err_update1 = 'S'
end

if @w_err_update1 = 'S'
begin
   exec sp_errorlog
      @i_fecha       = @i_param2, 
      @i_error       = 0,
      @i_usuario     = 'ope_batch',
      @i_tran        = 0,
      @i_tran_name   = @w_sp_name,
      @i_rollback    = 'N',
      @i_descripcion = @w_msg

   return @w_error
end

return 0

go


