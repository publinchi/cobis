/*************************************************************************/
/*   Archivo:              validacion_cobertura_gar.sp                   */
/*   Stored procedure:     sp_validacion_cobertura_gar                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         Guisela Fernández                             */
/*   Fecha de escritura:   10/Diciembre/2021                             */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual. Su uso no  autorizado dara  derecho a  MACOSA para         */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*   Validar el valor de la garantias para la cobertura de prestamos     */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    10/12/2019          G. Fernandez             Emision inicial       */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
go

if exists (select 1 from sysobjects where name = 'sp_validacion_cobertura_gar')
   drop proc sp_validacion_cobertura_gar
go

create proc sp_validacion_cobertura_gar (
   @s_ssn                int        = null,
   @s_date               datetime   = null,
   @s_user               login      = null,
   @s_ofi                smallint   = null,
   @t_debug              char(1)    = 'N',
   @t_trn                int        = null,
   @i_operacion          char(1)    = 'V',
   @i_tramite            int,
   @i_garantia           varchar(64)
)
as

declare
@w_sp_name                  varchar(24),
@w_error		            int,
@w_valor_cobertura          float,
@w_total_valor_resp_gar     float,
@w_monto                    money,
@w_dif_valor_resp_gar       float

--Inicializacion de variables
select @w_sp_name              = 'sp_validacion_cobertura_gar',
       @w_dif_valor_resp_gar   = 0,
	   @w_monto                = 0,
	   @w_total_valor_resp_gar = 0


/* Codigos de Transacciones                                */
if (@t_trn <> 19793 and @i_operacion = 'V')  
begin
    /* tipo de transaccion no corresponde */
	select @w_error = 1901006
	goto error
end

--Obtenemos el valor de cobertura de la garantia
select @w_valor_cobertura = cu_valor_actual * (isnull(cu_porcentaje_cobertura,0)/100) 
from cu_custodia
where cu_codigo_externo = @i_garantia

--Sumatoria de los valores comprometidos de la garantia
SELECT @w_total_valor_resp_gar = sum(gp_valor_resp_garantia)
FROM cob_credito..cr_gar_propuesta,
     cob_custodia..cu_custodia
WHERE gp_garantia = cu_codigo_externo
  AND cu_estado = 'V'
  AND gp_garantia = @i_garantia

-- Obtenemos el monto del prestamo
SELECT @w_monto = tr_monto 
FROM cob_credito..cr_tramite
where tr_tramite =@i_tramite

--Se obtiene la diferencia del valor actual de cobertura que tiene disponible la garantia
select @w_dif_valor_resp_gar = isnull(@w_valor_cobertura,0) - isnull(@w_total_valor_resp_gar,0)

IF @w_dif_valor_resp_gar > 0
BEGIN
	--Validacion para verificar si la garantia tiene saldo para cubir el monto 
	if @w_dif_valor_resp_gar < @w_monto
	begin
		select @w_error = 190525 --La garantía no tiene cobertura disponible para el monto del préstamo
		goto error
	END
END 	
ELSE
BEGIN
	select @w_error = 190525 --La garantía no tiene cobertura disponible para el monto del préstamo
	goto error
END

return 0

error:    /* Rutina que dispara sp_cerror dado el codigo de error */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_from  = @w_sp_name,
    @i_num   = @w_error
    return @w_error
go
