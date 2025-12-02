/************************************************************************/
/*   Archivo		:      admseg.sp            			*/
/*   Stored procedure	:      sp_administracion_seg          		*/
/*   Base de Datos	:      cob_cartera                    		*/
/*   Producto		:      Cartera                        		*/
/*   Disenado por	:      Xavier Maldonado               		*/
/*   Fecha de Documentacion:   03/Mar/2004                    		*/
/************************************************************************/
/*         IMPORTANTE                          				*/
/*   Este programa es parte de los paquetes bancarios propiedad de  	*/
/*   'MACOSA',representantes exclusivos para el Ecuador de la       	*/
/*   AT&T                            					*/
/*   Su uso no autorizado queda expresamente prohibido asi como     	*/
/*   cualquier autorizacion o agregado hecho por alguno de sus      	*/
/*   usuario sin el debido consentimiento por escrito de la         	*/
/*   Presidencia Ejecutiva de MACOSA o su representante          	*/
/************************************************************************/
/*         PROPOSITO                   					*/
/************************************************************************/
/*         MODIFICACIONES                   				*/
/*   FECHA      AUTOR         RAZON             			*/
/************************************************************************/
use cob_cartera
go 


if exists(select 1 from cob_cartera..sysobjects where name = 'sp_administracion_seg')
   drop proc sp_administracion_seg
go


/*Borrar tablas de trabajo*/
if exists(select 1 from cob_cartera..sysobjects where name = 'ca_seg_reporte_a')
   drop table ca_seg_reporte_a
go

create table ca_seg_reporte_a
(tr_ofi_oper_a		smallint, 
 dtr_concepto_a		catalogo, 
 valor_a		money
)
go

if exists(select * from cob_cartera..sysobjects where name = 'ca_seg_reporte_b')
   drop table ca_seg_reporte_b
go
create table ca_seg_reporte_b
(tr_ofi_oper_b		smallint, 
 dtr_concepto_b		catalogo, 
 valor_b		money
)
go


/*Borrar tablas de totales*/
if exists(select * from cob_cartera..sysobjects where name = 'ca_seg_total_a')
   drop table ca_seg_total_a
go
create table ca_seg_total_a
(dtr_concepto_ta	catalogo, 
 total_ta		money
)
go

if exists(select * from cob_cartera..sysobjects where name = 'ca_seg_total_b')
   drop table ca_seg_total_b
go
create table ca_seg_total_b
(dtr_concepto_tb	catalogo, 
 total_tb		money
)
go



create proc sp_administracion_seg (
        @i_fecha_ini          datetime,
        @i_fecha_fin          datetime
)
as
declare 
	@w_sp_name                varchar(20)

truncate table ca_seg_reporte_a
truncate table ca_seg_reporte_b
truncate table ca_seg_total_a
truncate table ca_seg_total_b


/*Para cargar las operaciones con rubro categoria S*/
insert into ca_seg_reporte_a
select tr_ofi_oper, dtr_concepto, sum(dtr_monto_mn)
from ca_transaccion,ca_det_trn
where tr_operacion  = dtr_operacion
and   tr_secuencial = dtr_secuencial
and   tr_tran       in ('PAG','DES')
and   tr_estado     = 'CON'
and   tr_fecha_mov  >= @i_fecha_ini
and   tr_fecha_mov  <=  @i_fecha_fin
and   dtr_concepto  in ( select co_concepto from ca_concepto where co_categoria = 'S')
group by tr_ofi_oper, dtr_concepto


/*Cargar las devoluciones*/
insert into ca_seg_reporte_b
select tr_ofi_oper, dtr_concepto, sum(dtr_monto_mn)
from ca_transaccion,ca_det_trn
where tr_operacion  = dtr_operacion
and   tr_secuencial = dtr_secuencial
and   tr_tran       = 'PAG'
and   tr_estado     = 'CON'
and tr_fecha_mov    >= @i_fecha_ini
and tr_fecha_mov    <=  @i_fecha_fin
and dtr_concepto    = 'DEVSEG'
group by tr_ofi_oper,dtr_concepto


/*Cargar totales*/
insert into ca_seg_total_a
select dtr_concepto_a, sum(valor_a)
from ca_seg_reporte_a
group by dtr_concepto_a

insert into ca_seg_total_b
select dtr_concepto_b, sum(valor_b)
from ca_seg_reporte_b
group by dtr_concepto_b

return 0  
go




