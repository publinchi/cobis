/************************************************************************/
/*	Archivo:		proycaja.sp				*/
/*	Stored procedure:	sp_proyeccion_caja			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Xavier Maldoando                        */
/*	Fecha de escritura:	Ene. 2001 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".        						*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Insertar en la tabla ca_proyeccion_caja los valores calcualdos	*/
/*      dada una fecha de inicio y una fecha final                      */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*                                                                      */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_proyeccion_caja')
	drop proc sp_proyeccion_caja
go



if exists (select 1 from sysobjects where name = 'temp_diviamor')
   DROP TABLE temp_diviamor
go

if exists (select 1 from sysobjects where name = 'temp_fechaven')
   DROP TABLE temp_fechaven
go



create proc sp_proyeccion_caja
	@i_fecha_desde  		datetime, 
        @i_fecha_hasta                  datetime
as

declare @w_sp_name			descripcion,
	@w_operacionca			int,
	@w_moneda			smallint,
	@w_error			int,
        @w_num_dec                      tinyint,
        @w_op_moneda                    smallint,
        @w_fecha_vencimiento            datetime,
        @w_capital                      money,
        @w_interes                      money,
        @w_otros_valores                money
   
	

select @w_sp_name = 'sp_proyeccion_caja'


delete ca_proyeccion_caja
where pc_fecha_desde >= '01/01/1900'

select
di_fecha_ven,
op_moneda,
di_operacion,
di_dividendo,
am_concepto,
am_cuota,
am_pagado into temp_diviamor
from ca_dividendo,ca_amortizacion,ca_operacion
where di_fecha_ven >= @i_fecha_desde
and di_fecha_ven <= @i_fecha_hasta
and di_estado <> 3 
and di_operacion = am_operacion
and di_operacion = op_operacion
and am_operacion  = op_operacion
and di_dividendo = am_dividendo
group by di_fecha_ven,op_moneda,di_operacion,di_dividendo,am_concepto,am_cuota,am_pagado
order by di_fecha_ven,op_moneda


select distinct (di_fecha_ven),op_moneda into temp_fechaven
from ca_dividendo,ca_operacion
where di_fecha_ven >= @i_fecha_desde
and di_fecha_ven <= @i_fecha_hasta
and di_estado <> 3 
and op_operacion = di_operacion
order by di_fecha_ven


declare fecha_vencimiento cursor for 
        select di_fecha_ven,op_moneda
        from temp_fechaven
        for read only

        open fecha_vencimiento
             fetch fecha_vencimiento into 
             @w_fecha_vencimiento,@w_op_moneda

             while (@@fetch_status = 0)  begin  

             select @w_capital = isnull(sum(am_cuota - am_pagado),0)
               from temp_diviamor,ca_rubro_op
              where di_fecha_ven = @w_fecha_vencimiento
                and op_moneda    = @w_op_moneda
                and di_operacion = ro_operacion
                and am_concepto  = ro_concepto
                and ro_tipo_rubro = 'C'


             select @w_interes = isnull(sum(am_cuota - am_pagado),0)
               from temp_diviamor,ca_rubro_op
              where di_fecha_ven = @w_fecha_vencimiento
                and op_moneda    = @w_op_moneda
                and di_operacion = ro_operacion
                and am_concepto  = ro_concepto
                and ro_tipo_rubro = 'I'


             select @w_otros_valores = isnull(sum(am_cuota - am_pagado),0)
               from temp_diviamor,ca_rubro_op
              where di_fecha_ven = @w_fecha_vencimiento
                and op_moneda    = @w_op_moneda
                and di_operacion = ro_operacion
                and am_concepto  = ro_concepto
                and ro_tipo_rubro not in ('C','I')


             insert into ca_proyeccion_caja
               (pc_fecha_desde,        pc_fecha_hasta,     pc_modulo,
                pc_fecha_diaria,       pc_moneda,          pc_saldo_cap,
                pc_saldo_int,          pc_saldo_otros)
            values
               (@i_fecha_desde,        @i_fecha_hasta,     'CCA',
                @w_fecha_vencimiento,  @w_op_moneda,       @w_capital,
                @w_interes,            @w_otros_valores)

               if @@error != 0 
                  return 708165               

             fetch fecha_vencimiento into 
             @w_fecha_vencimiento,@w_op_moneda

            end -- END WHILE
        close fecha_vencimiento 
deallocate fecha_vencimiento

DROP TABLE temp_diviamor
DROP TABLE temp_fechaven

return 0

go
