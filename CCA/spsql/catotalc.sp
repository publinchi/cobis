/************************************************************************/
/*	Archivo            :		catotalc.sp	                                 */
/*	Stored procedure   :	   sp_compara_hc_consolidador                   */
/*	Base de datos      :		cob_cartera	                                 */
/*	Producto           : 	Credito y Cartera                            */
/*	Disenado por       :  	Elcira Pelaez Burbano                        */
/*	Fecha de escritura :	   Jun 2004                                     */
/************************************************************************/
/*				                 IMPORTANTE                                 */
/*	Este programa es parte de los paquetes bancarios propiedad de        */
/*	"MACOSA"                                                             */
/*	Su uso no autorizado queda expresamente prohibido asi como	         */
/*	cualquier alteracion o agregado hecho por alguno de sus		         */
/*	usuarios sin el debido consentimiento por escrito de la 	            */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				               PROPOSITO                                    */
/*	Este proceso carga las siguientes tablas para revision de H.C Vs.    */
/*	consolidador:                                                        */
/*  ca_diff_hc_Vs_conso  --> Contiene las Operaciones que tiene diff.   */
/*                           de valores entre H.C Vs. Consolidador      */
/*  ca_siconso_nohc      --> Contiene las Operaciones que existen en el */
/*                           consolidador y no existen en la H.C        */
/*  ca_sihc_noconso      --> Contiene las Operaciones que existen en H.C*/
/*                           y no existen en el consolidaor             */
/*  ca_totales_hc_conso  --> Contiene los totales por concepto de H.C y */
/*                           Consolidaor                                */
/*  ca_cuadre_hc_conso_reporte  --> Esta tabla consolida todas las tabl.*/
/*                           anteriores para la generacion del reporte  */
/*                           a presentar a l usuario.                   */
/*                                                                      */
/*  Para el mejor manejo de la informacion se cargan dos tablas de traba*/
/*  fo una para la H.C llamada  ca_hcuadre y otra con los datos del cons*/
/*  solidador   ca_datooperacion_cuadre                                 */
/*  Estas tablas estan cargadas en Pesos                                */
/************************************************************************/  
/*	                     ACTUALIZACIONES                                 */
/*                                                                      */
/*  MAR-10-2007 REVISION ENERO 31  2007                                 */                               
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_compara_hc_consolidador')
	drop proc sp_compara_hc_consolidador
go

create proc sp_compara_hc_consolidador


as
declare 
   @w_siguiente_dia       datetime,
   @w_fecha_proceso       datetime,
   @w_cap                 money,
   @w_int                 money,
   @w_otro                money,
   @w_sus                 money,
   @w_cotizacion          float,
   @w_cotizacion_dolar    float,
   @w_fecha_cartera       datetime

   
 
            
-- FECHA DE REGISTRO DE CAMBIO DE CALIFICACION

set rowcount 1
select @w_fecha_proceso = do_fecha
from   cob_credito..cr_dato_operacion
where  do_tipo_reg = 'M'
and    do_codigo_producto = 7
set rowcount 0


delete  ca_datooperacion_cuadre WHERE banco >= ''
      
delete ca_hcuadre WHERE hc_banco >= ''

delete ca_totales_hc_conso
where com_fecha_proceso  = @w_fecha_proceso
     
delete ca_cuadre_hc_conso_reporte
where cua_fecha_proceso    = @w_fecha_proceso
and   cua_naturaleza = 'A'


delete ca_diff_hc_Vs_conso
where vd_fecha_proceso  = @w_fecha_proceso
                   
delete ca_siconso_nohc    
where sc_fecha_proceso = @w_fecha_proceso
                   
delete ca_sihc_noconso    
where sn_fecha_proceso = @w_fecha_proceso
                   
PRINT 'catotalc.sp Fin de borrado de tablas para la fecha'
     
--FECHA PARA SACAR LA COTIZACION SEGUN CREDITO

select @w_fecha_cartera = dateadd(dd, -datepart(dd, @w_fecha_proceso)+1, @w_fecha_proceso) -- QUEDA AL 1 DEL MES
select @w_siguiente_dia = dateadd(mm, 1, @w_fecha_cartera) -- QUEDA AL 1 DEL SIGUIENTE MES



exec sp_buscar_cotizacion
@i_moneda     = 2,
@i_fecha      = @w_siguiente_dia,
@o_cotizacion = @w_cotizacion output
            
PRINT 'catotalc.sp cotizacion utilizada para UVR' + cast(@w_cotizacion as varchar)
--SACAR DATOS DEL CONSOLIDADOR
------------------------------

exec sp_buscar_cotizacion
@i_moneda     = 1,
@i_fecha      = @w_siguiente_dia,
@o_cotizacion = @w_cotizacion_dolar output
            
PRINT 'catotalc.sp cotizacion utilizada para Dolar' + cast(@w_cotizacion_dolar as varchar)

--Inserta las de UVR
insert into ca_datooperacion_cuadre
select  
   @w_fecha_proceso,
   do_numero_operacion_banco,
   saldo_cap   = do_saldo_cap             * @w_cotizacion,
   saldo_int   = do_saldo_int             * @w_cotizacion,
   saldo_otros = do_saldo_otros           * @w_cotizacion,
   suspenso    = do_saldo_int_contingente * @w_cotizacion,
   do_moneda

from cob_credito..cr_dato_operacion
where do_fecha           = @w_fecha_proceso
and   do_tipo_reg        = 'M'
and   do_codigo_producto = 7
and   do_estado_contable  in (1,2) --canceladas y anuladas
and   do_moneda = 2

--Inserta la moneda 1

insert into ca_datooperacion_cuadre
select  
   @w_fecha_proceso,
   do_numero_operacion_banco,
   saldo_cap   = do_saldo_cap             * @w_cotizacion_dolar,
   saldo_int   = do_saldo_int             * @w_cotizacion_dolar,
   saldo_otros = do_saldo_otros           * @w_cotizacion_dolar,
   suspenso    = do_saldo_int_contingente * @w_cotizacion_dolar,
   do_moneda

from cob_credito..cr_dato_operacion
where do_fecha           = @w_fecha_proceso
and   do_tipo_reg        = 'M'
and   do_codigo_producto = 7
and   do_estado_contable  in (1,2) --canceladas y anuladas
and   do_moneda = 1


--Inserta las moneda 0

insert into ca_datooperacion_cuadre
select  
   @w_fecha_proceso,
   do_numero_operacion_banco,
   saldo_cap=do_saldo_cap,
   saldo_int=do_saldo_int,
   saldo_otros=do_saldo_otros,
   suspenso    = do_saldo_int_contingente * @w_cotizacion,   
   do_moneda
from cob_credito..cr_dato_operacion
where do_fecha           = @w_fecha_proceso
and   do_tipo_reg        = 'M'
and   do_codigo_producto = 7
and   do_estado_contable  in (1,2) --canceladas y anuladas,castigadas
and   do_moneda = 0


--Inserta todas las operaciones de la HC en la tabla de trabajo
insert into ca_hcuadre
select @w_fecha_proceso, sc_banco,0,0,0,0,0
from ca_saldos_cartera_mensual
where sc_fecha = @w_fecha_proceso
and   sc_perfil  = 'BOC_OA'
group by sc_banco

--Borrar las que estan castigadas que tambien son BOC_OA pero no estan en el consolidador

update ca_hcuadre
set hc_moneda = 77
from ca_operacion,ca_hcuadre
where  op_banco = hc_banco
and hc_fecha = @w_fecha_proceso
and op_estado = 4


delete ca_hcuadre
where hc_moneda = 77


--actualiza el campo de capital

select 'banco'= sc_banco,'val_cap'= sum(sc_valor)
into #hc_cap
from ca_saldos_cartera_mensual
where sc_fecha = @w_fecha_proceso
and   sc_perfil  = 'BOC_OA'
and   sc_codvalor in (10000, 10010, 10020, 10040, 10090)
group by sc_banco



update ca_hcuadre
set hc_saldo_cap = val_cap
from #hc_cap
where hc_banco = banco

--Fin act Cap

--act int-imo cxcintes

select 'banco'= sc_banco,'val_int'= sum(sc_valor)
into #hc_int_imo
from ca_saldos_cartera_mensual
where sc_fecha = @w_fecha_proceso
and   sc_perfil  = 'BOC_OA'
and   sc_concepto in ('INT', 'INTANT', 'IMO', 'CXCINTES')
and   sc_estado in (0, 1, 2, 4)
group by sc_banco


update ca_hcuadre
set hc_saldo_int = val_int
from #hc_int_imo
where hc_banco = banco

-- act otros 

select 'banco'= sc_banco,'val_otr'= sum(sc_valor)
into #hc_int_otr
from ca_saldos_cartera_mensual
where sc_fecha = @w_fecha_proceso
and   sc_perfil  = 'BOC_OA'
and    sc_concepto not in ('CAP', 'INT', 'INTANT', 'IMO', 'CXCINTES')
group by sc_banco


update ca_hcuadre
set hc_saldo_otros = val_otr
from #hc_int_otr
where hc_banco = banco

--fin act otros


---act suspensos

select 'banco'= sc_banco,'val_sus'= sum(sc_valor)
into #hc_int_sus
from ca_saldos_cartera_mensual
where sc_fecha = @w_fecha_proceso
and   sc_perfil  = 'BOC_OA'
and    sc_estado    = 9
and    sc_concepto in ('INT', 'INTANT', 'IMO', 'CXCINTES')
group by sc_banco


update ca_hcuadre
set hc_suspenso = val_sus
from #hc_int_sus
where hc_banco = banco

--Insertar totales para revision


insert into ca_totales_hc_conso
values (@w_fecha_proceso,7,0,0,0,0,0,0,0,0,0)

select @w_cap  = 0,
       @w_int  = 0,
       @w_otro = 0,
       @w_sus  = 0

select @w_cap  = isnull(sum(hc_saldo_cap),0),
       @w_int  = isnull(sum(hc_saldo_int),0),
       @w_otro = isnull(sum(hc_saldo_otros),0),
       @w_sus  = isnull(sum(hc_suspenso),0)
from ca_hcuadre
where hc_fecha = @w_fecha_proceso
 
update ca_totales_hc_conso
set com_capital_hc  =      @w_cap, 
    com_interes_hc  =      @w_int, 
    com_otros_hc    =      @w_otro,
    com_sus_hc      =      @w_sus 
where com_fecha_proceso = @w_fecha_proceso
and   com_producto      = 7


select @w_cap  = 0,
       @w_int  = 0,
       @w_otro = 0,
       @w_sus  = 0

select @w_cap  = isnull(sum(saldo_cap),0),
       @w_int  = isnull(sum(saldo_int),0),
       @w_otro = isnull(sum(saldo_otros),0),
       @w_sus  = isnull(sum(suspenso),0)
from ca_datooperacion_cuadre
where fecha = @w_fecha_proceso
 
update ca_totales_hc_conso
set com_capital_conso  =  @w_cap, 
    com_interes_conso  =  @w_int, 
    com_otros_conso    =  @w_otro,
    com_sus_conso      =  @w_sus 
where com_fecha_proceso = @w_fecha_proceso
and   com_producto      = 7

    
return 0

go      
