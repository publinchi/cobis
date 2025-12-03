/************************************************************************/
/*   Archivo:              gen_ref_santander.sp                         */
/*   Stored procedure:     sp_gen_ref_santander                         */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raúl Altamirano Mendez                       */
/*   Fecha de escritura:   Noviembre 2017                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Generar los numeros de referencia para el procesamiento de los     */
/*   pagos referidos del Banco Santander                                */
/*                              CAMBIOS                                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_gen_ref_santander')
   drop proc sp_gen_ref_santander
go

create proc sp_gen_ref_santander(
	@i_tipo		   varchar(2),        --Tipo: GL(Garantia Liquida), PR(Precancelacion), PI(Prestamo Individual), PG(Prestamo Grupal)
	@i_referencia  int,               --Referencia: PG/GL (Numero - Codigo de Grupo), PI/PR(Numero de Operacion - Prestamo)
	@i_monto       money = null,      --Importe del Pago
	@i_fecha       datetime = null,   --Fecha de Vencimiento
	@o_referencia  varchar(40) out
)
as
declare @w_referencia_in  varchar(14),
        @w_referencia_out varchar(22),
        @w_fecha          varchar(10),
	    @w_monto          varchar(20),
		@w_error          int

select @w_referencia_in = @i_tipo + dbo.LlenarI(convert(varchar, @i_referencia), '0', 12),   --Referencia Inicial de 14 digitos
       @w_fecha = replace(convert(varchar(10), @i_fecha, 103), '/', ''),                   --Fecha de Vencimiento/ de la Gar/ Precancelacion de la Op.
       @w_monto = dbo.LlenarI(replace(convert(varchar(20), @i_monto), '.', ''), '0', 8)   --Monto de /Pago de la Gar/ Precancelacion de la Op.
	
select @o_referencia = ''
	
if @i_tipo in ('GL', 'PR')
begin
   exec @w_error = sp_dv_base22
   @i_input = @w_referencia_in,
   @i_monto = @w_monto,
   @i_fecha = @w_fecha,
   @o_output= @w_referencia_out out
   
   if @w_error != 0 return @w_error
end
else select @w_referencia_out = dbo.CalcularDigitoVerificadorOpenPay(@w_referencia_in)
   
select @o_referencia = @w_referencia_out

--select * from @w_tabla_calculo_importe
--select * from @w_tabla_factores
--select * from @w_tabla_referencia 
--select * from @w_tabla_valores
--select * from @w_tabla_valores_2
--select * from @w_tabla_valores_3

RETURN 0

go

