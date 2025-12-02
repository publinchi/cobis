/************************************************************************/
/*	Archivo:		caconcif.sp                             */
/*	Stored procedure:	sp_concilia_inf_bancoldex               */
/*	Base de datos:		cob_cartera                             */
/*	Producto: 		Credito y Cartera                       */
/*	Disenado por:  		Xavier Maldonado                        */
/*	Fecha de escritura:	Jul.2005                                */
/************************************************************************/
/*				IMPORTANTE                              */
/*	Este programa es parte de los paquetes bancarios propiedad de   */
/*	'MACOSA'.                                                       */
/*	Su uso no autorizado queda expresamente prohibido asi como      */
/*	cualquier alteracion o agregado hecho por alguno de sus         */
/*	usuarios sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*				PROPOSITO                               */
/*	Conciliacion de obligaciones COBIS e obligaciones BANCOLDEX     */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre      	Proposito                       */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_conci_dia_findeter_tmp')
   DROP TABLE ca_conci_dia_findeter_tmp
go

CREATE TABLE ca_conci_dia_findeter_tmp (
cdft_fecha_proceso        datetime          NULL,
cdft_num_oper_cobis       cuenta            NULL,
cdft_num_oper_findeter    cuenta            NULL,--op_codigo_externo
cdft_beneficiario         char(30)          NULL,
cdft_departamento         char(20)          NULL,
cdft_pagare               char(64)          NULL,
cdft_saldo_capital        money             NULL,
cdft_valor_capital        money             NULL,
cdft_fecha_desde          datetime          NULL,
cdft_fecha_hasta          datetime          NULL,
cdft_dias                 int          	    NULL,
cdft_modalida_pago        char(5)    	    NULL,
cdft_tasa_redes           char(20)    	    NULL,
cdft_tasa                 float       	    NULL,
cdft_valor_interes        money      	    NULL,
cdft_neto_pagar           money      	    NULL,
cdft_marcar_diff          char(1)           NULL,
cdft_no_conciliada        char(1)    	    NULL
)
go


if exists (select * from sysobjects where name = 'ca_diferencias_findeter_tmp')
   DROP TABLE ca_diferencias_findeter_tmp
go

CREATE TABLE ca_diferencias_findeter_tmp (
cf_beneficiario		char(30)	NULL,
cf_departamento		char(20)	NULL,
cf_pagare		char(64)	NULL,
pf_pagare		char(64)	NULL,
cf_fecha_desde		datetime	NULL,
cf_fecha_hasta		datetime	NULL,
cf_num_oper_findeter	cuenta		NULL,
pf_num_oper_findeter	cuenta		NULL,   
cf_saldo_capital	money		NULL,     
pf_saldo_capital	money		NULL,
cf_tasa			float		NULL,              
pf_tasa			float		NULL,
cf_dias			int		NULL,
pf_dias			int		NULL,
cf_valor_interes	money		NULL,
pf_valor_interes	money		NULL,
cf_valor_capital	money		NULL,
pf_valor_capital	money		NULL,
cf_tasa_redes		char(15)	NULL,        
pf_tasa_redes		char(15)	NULL
)
go


if exists (select * from sysobjects where name = 'sp_concilia_inf_findeter')
   drop proc sp_concilia_inf_findeter
go

create proc sp_concilia_inf_findeter
@i_fecha_proceso     	datetime = null

as

declare 
@w_error          	     int,
@w_return         	     int,
@w_sp_name        	     descripcion

/** CARGADO DE VARIABLES DE TRABAJO **/
/*************************************/
select @w_sp_name = 'sp_concilia_inf_findeter'


truncate table ca_conci_dia_findeter_tmp


/* INSERCION DE LA DATA EN TABLAS TEMPORALES EXISTEN EN COBIS Y NO EN FINDETER */
/*******************************************************************************/
Insert into ca_conci_dia_findeter_tmp
select
cf_fecha_proceso,       
cf_num_oper_cobis,      
cf_num_oper_findeter,   
cf_beneficiario,        
cf_departamento,        
cf_pagare,              
cf_saldo_capital,       
cf_valor_capital,       
cf_fecha_desde,         
cf_fecha_hasta,         
cf_dias,                
cf_modalida_pago,       
cf_tasa_redes,          
cf_tasa,                
cf_valor_interes,       
cf_neto_pagar,          
cf_marcar_diff,         
'C'                   --Existen en Cobis
from ca_conci_dia_findeter a
where not exists (select 1 from  ca_plano_dia_findeter
                  where a. cf_num_oper_findeter  = pf_num_oper_findeter )




/* ACTUALIZACION DE LA VARIABLE cdb_no_conciliada */
/**************************************************/
Update ca_conci_dia_findeter
set    cf_no_conciliada  =  'C'    ---C de existen en Cobis
From   ca_conci_dia_findeter, ca_conci_dia_findeter_tmp
Where  cf_num_oper_findeter = cdft_num_oper_findeter



/* INSERTAR EN LA MISMA TABLA LAS QUE LLEGARON EN EL PLANO Y NO TIENE COBIS EN LA TABLA CA_CONCI_DIA_FINDETER */
/**************************************************************************************************************/
insert into ca_conci_dia_findeter_tmp
select
@i_fecha_proceso,
'', 
pf_num_oper_findeter,   
pf_beneficiario,        
pf_departamento,        
pf_pagare,              
pf_saldo_capital,       
pf_valor_capital,       
pf_fecha_desde,       
pf_fecha_hasta,         
pf_dias,                
pf_modalida_pago,       
pf_tasa_redes,          
pf_tasa,                
pf_valor_interes,       
pf_neto_pagar,          
'',         
'P'  --Existen en plano
from ca_plano_dia_findeter a
where not exists (select 1 from  ca_conci_dia_findeter
                  where a.pf_num_oper_findeter  = cf_num_oper_findeter)


truncate table ca_diferencias_findeter_tmp

/* MACAR LAS DIFERENCIAS ENTRE LOS DOS PLANOS EN LA MISMA TABLA TEMPORAL */
/*************************************************************************/
insert into ca_diferencias_findeter_tmp
select
cf_beneficiario,
cf_departamento,
cf_pagare,
pf_pagare,
cf_fecha_desde,
cf_fecha_hasta,
cf_num_oper_findeter,
pf_num_oper_findeter,   
cf_saldo_capital,     
pf_saldo_capital,
cf_tasa,              
pf_tasa,
cf_dias,
pf_dias,
cf_valor_interes,
pf_valor_interes,
cf_valor_capital,
pf_valor_capital,
cf_tasa_redes,        
pf_tasa_redes
From  ca_conci_dia_findeter, ca_plano_dia_findeter
Where pf_num_oper_findeter  = cf_num_oper_findeter
And  (cf_saldo_capital     <> pf_saldo_capital  or 
      cf_tasa              <> pf_tasa           or
      cf_dias              <> pf_dias           or
      cf_valor_interes     <> pf_valor_interes  or
      cf_valor_capital     <> pf_valor_capital)  

return 0
go




