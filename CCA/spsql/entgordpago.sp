/************************************************************************/
/*   Archivo:                 entgordpago.sp                            */
/*   Stored procedure:        sp_entrega_ordenes_pago_srv               */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Edison Cajas M.                           */
/*   Fecha de Documentacion:  Junio. 2019                               */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Entregar las ordenes de pago producto del desembolso de una        */
/*   operación.                                                         */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   26/Jun/2019   Edison Cajas. Emision Inicial                        */
/************************************************************************/

use cob_cartera
go

IF OBJECT_ID ('dbo.sp_entrega_ordenes_pago_srv') IS NOT NULL
	DROP PROCEDURE dbo.sp_entrega_ordenes_pago_srv
GO

create proc sp_entrega_ordenes_pago_srv
( 
    @i_grupo    numeric      = null,
	@i_banco    cuenta       = null,
	@i_lote     varchar(15)  = null,
	@t_trn      int          = null
)
as 

declare
   @w_sp_name     descripcion

SELECT @w_sp_name = 'sp_entrega_ordenes_pago_srv'

    if @t_trn <> 77507 
    begin
        print 'Transaccion no permitida'	
        return 151051
    end
	
if @i_banco is null --Encontrar el número del op_banco
begin	
   if @i_grupo is not null 
      select @i_banco = op_banco
	  from   cob_cartera..ca_operacion
	  where  op_grupo  = @i_grupo  and
	         op_grupal = 'S'       and 
		     op_ref_grupal is null and 
	         op_estado not in (0,3)	       
   
end 

if @i_banco is not null
   select 
         'Cliente'          = dr_cliente
         ,'MontoDesembolso' = dr_monto
         ,'TipoOrdenPago'   = dr_forma_retiro
         ,'Banco'           = dr_banco
         ,'Referencia'      = dr_codigo
         ,'Convenio'        = '' --dr_convenio
         ,'FechaEmision'    = dr_fecha_apl
         ,'Lote'            = dr_lote
   from  cobis..cl_dispersion_retiro, ca_operacion
   where dr_operacion = op_operacion
     and op_banco = @i_banco 
else
   select 
         'Cliente'          = dr_cliente
         ,'MontoDesembolso' = dr_monto
         ,'TipoOrdenPago'   = dr_forma_retiro
         ,'Banco'           = dr_banco
         ,'Referencia'      = dr_codigo
         ,'Convenio'        = '' --dr_convenio
         ,'FechaEmision'    = dr_fecha_apl
         ,'Lote'            = dr_lote
   from  cobis..cl_dispersion_retiro
   where dr_lote   = @i_lote
	 
return 0

GO

