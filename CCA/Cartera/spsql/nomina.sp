/************************************************************************/
/*	Archivo:		nomina.sp        			*/
/*	Stored procedure:	sp_nomina                               */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Rodrigo Garces               		*/
/*	Fecha de escritura:	Abr  98 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA", representantes exclusivos para el Ecuador de la 	*/
/*	"NCR CORPORATION".						*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	                                                                */ 
/*	I: Insercion de nominas                                         */
/************************************************************************/
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	Abril 1998      A. Avila        Emision Inicial                 */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_nomina')
	drop proc sp_nomina
go

create proc sp_nomina
       	@i_banco		cuenta= NULL,
       	@i_dividendo		smallint= NULL,
        @i_concepto         	char(1)= NULL,
	@i_valor		money=0
as
declare @w_sp_name		descripcion,
        @w_operacionca          int,
	@w_return		int,
        @w_error                int


/*  NOMBRE DEL SP Y FECHA DE HOY */
select	@w_sp_name = 'sp_nomina'



/* INGRESO DEL REGISTRO DE NOMINA */

select 
@w_operacionca = op_operacion
from ca_operacion
where op_banco  = @i_banco    --PREGUNTAR ESTADO DE LA OPERACION
and   op_estado = 0        

if @@rowcount = 0
   begin
      select @w_error = 710022   
      goto ERROR
   end    

/* INSERCION DE CA_NOMINA */
begin tran

	insert into ca_nomina (
no_operacion,
no_dividendo,
no_concepto,
no_valor )
values (
@w_operacionca,
@i_dividendo,
@i_concepto,
@i_valor )

if @@error != 0 
begin
   select @w_error = 710090
   goto ERROR
end    


update ca_cuota_adicional
set ca_cuota=ca_cuota+no_valor
from ca_nomina,ca_cuota_adicional
where
ca_operacion = @w_operacionca and
no_operacion = ca_operacion and
ca_dividendo = no_dividendo and
ca_dividendo = @i_dividendo

if @@error != 0 
begin
   select @w_error = 710090
   goto ERROR
end    

commit tran

return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug='N',    @t_file=null,
   @t_from=@w_sp_name,   @i_num = @w_error
   return @w_error
go

