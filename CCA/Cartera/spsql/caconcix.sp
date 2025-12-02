/************************************************************************/
/*	Archivo:		caconcix.sp                             */
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
/*	Genera obligaciones que reporta COBIS y no son reportados       */
/*      por BANCO DE SEGUNDO PISO                                       */
/*	Actualiza la tabla	ca_conci_dia_bancoldex campo 	cm_my   */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre      	Proposito                       */
/************************************************************************/  

use cob_cartera
go

set ansi_nulls off
go


if exists (select 1 from sysobjects where name = 'ca_opcobis_nobancoldex')
   DROP TABLE ca_opcobis_nobancoldex
go

CREATE TABLE ca_opcobis_nobancoldex (
cb_fecha_proceso                datetime          NULL,
cb_linea                        cuenta            NULL,
cb_num_oper_cobis               cuenta            NULL,
cb_num_oper_bancoldex     	cuenta            NULL,
cb_ciudad                       int               NULL,
cb_beneficiario                 char(30)          NULL,
cb_ref_externa                  cuenta            NULL,
cb_saldo_capital                money             NULL,
cb_tasa                         float       	  NULL,
cb_dias                         int          	  NULL,
cb_valor_interes                money             NULL,
cb_valor_capital                money             NULL,
cb_valor_mora                   money      	  NULL,
cb_neto_pagar                   money      	  NULL,
cb_oper_bancoldex_plano         cuenta            NULL
)
go


if exists (select * from sysobjects where name = 'ca_bancoldex_nocobis')
   DROP TABLE ca_bancoldex_nocobis
go

CREATE TABLE ca_bancoldex_nocobis (
bc_fecha_proceso                datetime          NULL,
bc_linea                        cuenta            NULL,
bc_num_oper_bancoldex     	cuenta            NULL,
bc_ciudad                       int               NULL,
bc_beneficiario                 char(30)          NULL,
bc_ref_externa                  cuenta            NULL,
bc_saldo_capital                money             NULL,
bc_tasa                         float       	  NULL,
bc_dias                         int          	  NULL,
bc_valor_interes                money      	  NULL,
bc_valor_capital                money             NULL,
bc_valor_mora                   money      	  NULL,
bc_neto_pagar                   money      	  NULL,
bc_oper_cobis                   cuenta            NULL
)
go


if exists (select 1 from sysobjects where name = 'ca_diferencias_tmp')
   DROP TABLE ca_diferencias_tmp
go
CREATE TABLE ca_diferencias_tmp (
cd_fecha_proceso                datetime          NULL,
cd_linea                        cuenta            NULL,
cd_num_oper_cobis               cuenta            NULL,
cd_num_oper_bancoldex           cuenta            NULL,
cd_ciudad                       int               NULL,
cd_beneficiario                 char(30)          NULL,
cd_ref_externa                  cuenta            NULL,
cd_saldo_capital_c              money             NULL,
cd_saldo_capital_b              money             NULL,
cd_tasa_c                       float             NULL,
cd_tasa_b                       float       	  NULL,
cd_dias_c                       int          	  NULL,
cd_dias_b                       int          	  NULL,
cd_valor_interes_c              money      	  NULL,
cd_valor_interes_b              money      	  NULL,
cd_valor_capital_c              money             NULL,
cd_valor_capital_b              money             NULL,
cd_valor_mora_c                 money      	  NULL,
cd_valor_mora_b                 money      	  NULL,
cd_neto_pagar                   money      	  NULL
)
go

if exists (select 1 from sysobjects where name = 'sp_concilia_inf_bancoldex')
   drop proc sp_concilia_inf_bancoldex
go

create proc sp_concilia_inf_bancoldex
@i_fecha_proceso     	datetime = null

as

declare 
@w_error          	     int,
@w_return         	     int,
@w_sp_name        	     descripcion


/** CARGADO DE VARIABLES DE TRABAJO **/
select @w_sp_name = 'sp_concilia_inf_bancoldex'

truncate table ca_opcobis_nobancoldex
truncate table ca_bancoldex_nocobis
truncate table ca_diferencias_tmp

/* ESTAN EN COBIS Y NO EN BANCOLDEX*/
/***********************************/
select 	cb_fecha_proceso,     cb_linea,             cb_num_oper_cobis,    
	cb_num_oper_bancoldex,cb_ciudad,            cb_beneficiario,      
	cb_ref_externa,       cb_saldo_capital,     cb_tasa,              
	cb_dias,              cb_valor_interes,     cb_valor_capital,     
	cb_valor_mora,        cb_neto_pagar,        'pb_num_oper_bancoldex' = convert(varchar(24),null)
into #ca_cobis
from ca_conci_dia_bancoldex  

update #ca_cobis  set
pb_num_oper_bancoldex = a.pb_num_oper_bancoldex
from ca_plano_dia_bancoldex a,#ca_cobis b
where a.pb_num_oper_bancoldex = b.cb_num_oper_bancoldex

insert into ca_opcobis_nobancoldex
select * from #ca_cobis
where pb_num_oper_bancoldex is null

/* ESTAN EN BANCOLDEX Y NO EN COBIS*/
/***********************************/
select 	'cb_fecha_proceso' = @i_fecha_proceso,     pb_linea,             pb_num_oper_bancoldex,    
	    pb_ciudad,            pb_beneficiario,      pb_ref_externa,       
        pb_saldo_capital,     pb_tasa,              pb_dias,            
        pb_valor_interes,     pb_valor_capital,     pb_valor_mora,      
        pb_neto_pagar,        'cb_num_oper_cobis'= convert(varchar(24),null)
INTO #ca_bancoldex
from ca_plano_dia_bancoldex

update #ca_bancoldex  set
cb_num_oper_cobis = a.cb_num_oper_bancoldex,
cb_fecha_proceso  = a.cb_fecha_proceso
from ca_conci_dia_bancoldex a,#ca_bancoldex b
where a.cb_num_oper_cobis = b.pb_num_oper_bancoldex

insert into ca_bancoldex_nocobis
select * from #ca_bancoldex
where cb_num_oper_cobis is null

--MACAR LAS DIFERENCIAS ENTRE LOS DOS PLANOS EN LA MISMA TABLA TEMPORAL
insert into ca_diferencias_tmp
select
cb_fecha_proceso,     
cb_linea,             
cb_num_oper_cobis,    
cb_num_oper_bancoldex,
cb_ciudad,            
cb_beneficiario,      
cb_ref_externa,       
cb_saldo_capital,  
pb_saldo_capital,   
cb_tasa,  
pb_tasa,            
cb_dias,  
pb_dias,            
cb_valor_interes,   
pb_valor_interes,  
cb_valor_capital, 
pb_valor_capital,    
cb_valor_mora,        
pb_valor_mora,
cb_neto_pagar   
from ca_conci_dia_bancoldex, ca_plano_dia_bancoldex  
where pb_num_oper_bancoldex  = cb_num_oper_bancoldex 
and  (cb_saldo_capital     <> pb_saldo_capital     or 
      cb_tasa              <> pb_tasa              or
      cb_dias              <> pb_dias              or
      cb_valor_interes     <> pb_valor_interes     or
      cb_valor_capital     <> pb_valor_capital     or
      cb_valor_mora        <> pb_valor_mora)


return 0
go


