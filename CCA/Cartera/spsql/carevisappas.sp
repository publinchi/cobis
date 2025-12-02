/******************************************************************************************/
/* Este programa revisa los prepagos mal genrados en ca_prepagos_pasivas                  */
/******************************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_revisa_prepagos_tmp')
   drop table ca_revisa_prepagos_tmp
go

create table ca_revisa_prepagos_tmp
(
fecha_generacion    datetime null,
oper_activa         int      null,
oper_pasiva         int      null,
secuencial_prepago  int   null,
banco_pas           cuenta null,
estado_registro     char(1) null,
cliente             int  null,
valor_prepago       money  null

)

if exists (select * from sysobjects where name = 'ca_prepas_dobles')
   drop table ca_prepas_dobles
go

create table ca_prepas_dobles
(
banco_pas              cuenta null,
fecha                  datetime null,
valor_prepago          money null,
dias_int               int   null,
saldo_int              money null,
cuantos                int   null
)


if exists (select * from sysobjects where name = 'sp_revisa_prepagos')
   drop proc sp_revisa_prepagos
go

create proc sp_revisa_prepagos 

as
declare
@w_registros         int,
@w_error             int,
@w_fecha_cierre      datetime,
@w_fecha_generacion  datetime,
@w_oper_activa            int,
@w_oper_pasiva            int,       
@w_secuencial_prepago     int,
@w_banco_pas              cuenta,         
@w_estado_registro        char(1),   
@w_dias                   int,           
@w_valor_prepago          money ,
@w_fec                    datetime,
@w_con                   int,
@w_valor_int             money,
@w_cuantos               int



select @w_registros   = 0
 

select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

truncate table ca_revisa_prepagos_tmp
truncate table ca_prepas_dobles

insert into ca_revisa_prepagos_tmp
select pp_fecha_generacion,rp_activa,rp_pasiva,pp_secuencial,pp_banco,pp_estado_registro,
       pp_cliente , pp_valor_prepago
from ca_prepagos_pasivas,
    ca_operacion,
    ca_relacion_ptmo
where op_banco = pp_banco
and  op_operacion = rp_pasiva
and  pp_codigo_prepago = '11'
and  pp_estado_registro = 'I'


-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select  distinct banco_pas
        
 from ca_revisa_prepagos_tmp
 
open cursor_operacion

fetch cursor_operacion
into  
   @w_banco_pas

while @@fetch_status = 0
begin
   
   
   insert into ca_prepas_dobles
   select  @w_banco_pas,pp_fecha_generacion,pp_valor_prepago,pp_dias_de_interes,pp_saldo_intereses, count(1)
   from ca_prepagos_pasivas
   where pp_banco = @w_banco_pas
   and   pp_estado_registro = 'I'
   and   pp_codigo_prepago = '11'
   group by pp_fecha_generacion,pp_valor_prepago,pp_dias_de_interes,pp_saldo_intereses
   having count(1) > 1
 
   fetch cursor_operacion
   into  
   @w_banco_pas

end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion


--CURSOR PARA ELIMINAR LOS DOBLES

declare cursor_eli cursor
for select 

   banco_pas ,     
   fecha     ,     
   valor_prepago,  
   dias_int  ,     
   saldo_int ,     
   cuantos  - 1     
        
 from ca_prepas_dobles
 
open cursor_eli

fetch cursor_eli
into  
   @w_banco_pas,
   @w_fecha_generacion,
   @w_valor_prepago,
   @w_dias,
   @w_valor_int,
   @w_cuantos

while @@fetch_status = 0
begin
   
   set rowcount @w_cuantos
   
   delete ca_prepagos_pasivas
   from ca_prepas_dobles
   where  pp_banco = @w_banco_pas 
   and    pp_codigo_prepago = '11'
   and    pp_estado_registro = 'I'
   and    pp_fecha_generacion = @w_fecha_generacion
   and    pp_valor_prepago = @w_valor_prepago
   and    pp_saldo_intereses = @w_valor_int
   and    pp_dias_de_interes =  @w_dias
   
   set rowcount 0
 
 
   fetch cursor_eli
   into  
   @w_banco_pas,
   @w_fecha_generacion,
   @w_valor_prepago,
   @w_dias,
   @w_valor_int,
   @w_cuantos

end --while @@fetch_status = 0

close cursor_eli
deallocate cursor_eli


return 0
go

