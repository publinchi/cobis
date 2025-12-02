/************************************************************************/
/*  Archivo:              sp_comprobantes_error_cca.sp                  */
/*  Stored procedure:     sp_comprobantes_error_cca                     */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         Juan Carlos Guzman                            */
/*  Fecha de escritura:   15/Mar/2022                                   */
/************************************************************************/
/*             IMPORTANTE                                               */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCorp.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCorp.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCorp para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*   ACTUALIZACION DE TRANSACCIONES CON ERRORES EN LA CONTABILIZACION   */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA          AUTOR          RAZON                                 */
/*  15/Mar/2022    Juan Guzman    Emision Inicial                       */
/*  16/Jun/2022    Juan Guzman    Validación fechas de trans. con error */
/*                                en contabilización                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_comprobantes_error_cca' and type = 'P')
   drop procedure sp_comprobantes_error_cca
go

create procedure sp_comprobantes_error_cca
(
   @i_param1    int,       --Empresa
   @i_param2    datetime   --Fecha 
)
as

declare @w_error        int,
        @w_msg          varchar(200),
        @w_err_update1  char(1),
        @w_err_update2  char(1),
        @w_sp_name      varchar(50),
        @w_min_fecha    datetime

select @w_msg = null,
       @w_err_update1 = 'N',
       @w_err_update2 = 'N',
       @w_sp_name     = 'sp_comprobantes_error_cca'

select @w_min_fecha = min(co_fecha_ini)
from cob_conta..cb_corte
where co_estado in ('V', 'A')

update ca_transaccion
set tr_estado      = 'ING',
    tr_comprobante = 0
from cob_conta..cb_error_conaut
where tr_fecha_mov between @w_min_fecha and @i_param2
  and ec_empresa       = @i_param1 
  and ec_fecha_conta   = @i_param2 
  and ec_producto      = 7
  and ec_comprobante   = tr_comprobante

if @@error <> 0
begin
   select @w_error = @@error,
          @w_msg = 'Error en actualización de comprobantes de error en tabla ca_transaccion',
          @w_err_update1 = 'S'
end

update ca_transaccion_prv
set tp_estado      = 'ING',
    tp_comprobante = 0
from cob_conta..cb_error_conaut
where tp_fecha_mov between @w_min_fecha and @i_param2
  and ec_empresa       = @i_param1 
  and ec_fecha_conta   = @i_param2 
  and ec_producto      = 7
  and ec_comprobante   = tp_comprobante

if @@error <> 0
begin
   select @w_error = @@error,
          @w_err_update2 = 'S'

   if @w_msg is null
      select @w_msg = 'Error en actualización de comprobantes de error en tabla ca_transaccion_prv'
   else
      select @w_msg = @w_msg + ' y tabla ca_transaccion_prv'
end

if @w_err_update1 = 'S' or @w_err_update2 = 'S'
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
