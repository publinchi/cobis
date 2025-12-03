/************************************************************************/
/*	Archivo:		valsaldo.sp				*/
/*	Stored procedure:	sp_validar_saldos			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Marcelo Poveda				*/
/*	Fecha de escritura:	Sep-2001				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la		*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Procedimiento para calcular los saldos migrados			*/
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/* **********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'comparar_cobis')
   drop table comparar_cobis 
go

create table comparar_cobis (
nit1		cuenta null,
nombre1		descripcion null,
banco1		cuenta null,
migrada1	cuenta null,
linea1		catalogo null,
saldocap1	money null,
saldoint1	money null,
saldoimo1	money null,
saldocont1	money null,
seguro1		money null
)
go


if exists (select 1 from sysobjects where name = 'sp_validar_saldos')
   drop proc sp_validar_saldos
go


create proc sp_validar_saldos
@i_oficina		int = null
as
declare
@w_cl_nit		cuenta,
@w_op_nombre		descripcion,
@w_op_migrada		cuenta,
@w_op_toperacion	catalogo,
@w_op_operacion		int,
@w_op_cliente		int,
@w_op_banco		cuenta,
@w_saldo_capital	money,
@w_saldo_int		money,
@w_saldo_mora		money,
@w_saldo_cont		money,
@w_saldo_seguro		money,
@w_digito		char(1)


select getdate()

delete comparar_cobis
where banco1 > ''

/** SELECCION DE OPERACIONES **/
declare cursor_operacion cursor for
select 
op_banco,
op_cliente,
op_toperacion,
op_nombre,
op_migrada,
op_operacion
from ca_operacion
where (op_oficina = @i_oficina or @i_oficina is null)
and   op_migrada is not null
and   op_operacion > 1000000
and   op_operacion <= 1002000
order by op_migrada
for read only

open cursor_operacion

fetch cursor_operacion into
@w_op_banco, @w_op_cliente, @w_op_toperacion, @w_op_nombre,
@w_op_migrada, @w_op_operacion

while @@fetch_status = 0 begin

   /** SELECCIONAR NIT DEL CLIENTE **/
   select @w_cl_nit = en_ced_ruc
   from   cobis..cl_ente
   where  en_ente = @w_op_cliente
   set transaction isolation level read uncommitted

   /** SALDO DE CAPITAL **/
   select @w_saldo_capital = sum(am_cuota - am_pagado)
   from   ca_amortizacion
   where  am_operacion     = @w_op_operacion
   and    am_concepto      = 'CAP'
   and    am_estado        != 3

   /** SALDO DE INTERES CORRIENTES**/
   select @w_saldo_int     = sum(am_acumulado - am_pagado)
   from   ca_amortizacion
   where  am_operacion     = @w_op_operacion
   and    am_concepto      = 'INT'
   and    am_estado        != 3
   and    am_estado        != 9


   /** SALDO DE INTERES CONTINGENTE**/
   select @w_saldo_cont     = sum(am_acumulado - am_pagado)
   from   ca_amortizacion
   where  am_operacion     = @w_op_operacion
   and    am_concepto      = 'INT'
   and    am_estado        = 9


   /** SALDO DE MORA **/
   select @w_saldo_mora    = sum(am_cuota - am_pagado)
   from   ca_amortizacion
   where  am_operacion     = @w_op_operacion
   and    am_concepto      = 'IMO'
   and    am_estado        != 3

   /** SALDO SEGUROS **/
   select @w_saldo_seguro  = sum(am_cuota - am_pagado)
   from   ca_amortizacion
   where  am_operacion     = @w_op_operacion
   and    am_concepto      in ('SVID', 'SVIDCV') 
   and    am_estado        != 3

   /** DIGITO VERIFICADOR **/
   --select @w_digito = substring(@w_cl_nit,)


   insert comparar_cobis
   (nit1,nombre1,banco1,migrada1,
    linea1,saldocap1,saldoint1,
    saldoimo1,saldocont1,seguro1)
   values
   (@w_cl_nit,@w_op_nombre,@w_op_banco,@w_op_migrada,
    @w_op_toperacion,isnull(@w_saldo_capital,0),isnull(@w_saldo_int,0),
    isnull(@w_saldo_mora,0),isnull(@w_saldo_cont,0),isnull(@w_saldo_seguro,0)) 

   fetch cursor_operacion into
   @w_op_banco, @w_op_cliente, @w_op_toperacion, @w_op_nombre,
   @w_op_migrada, @w_op_operacion
end
close cursor_operacion
deallocate cursor_operacion

select getdate()

return 0
go
