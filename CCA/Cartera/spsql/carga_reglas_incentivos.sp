/************************************************************************/ 
/*    ARCHIVO:         carga_reglas_incentivos.sp                       */ 
/*    NOMBRE LOGICO:   sp_carga_reglas_incentivos                       */ 
/*   Base de datos:    cob_cartera                                      */
/*   Producto:         Cartera                                          */
/*   Disenado por:     Guisela Fernandez                                */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*Programa Creación y generación de reglas                              */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 08/12/2022    G. Fernandez	 Versión Inicial                        */
/************************************************************************/ 

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_carga_reglas_incentivos')
   drop proc sp_carga_reglas_incentivos
go
create proc sp_carga_reglas_incentivos
 
as declare 
@w_code_rule        int,
@w_sp_name          varchar(64),
@w_error		    int,
@w_code_version     int

select @w_sp_name =  'sp_carga_reglas_incentivos'         

-- Regla Indicador de Riesgo
 
select @w_code_rule = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'INDIRIESGO' --'Indicador de riesgo'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'

if @@rowcount <> 1
begin
	select @w_error = 725109 
      goto ERROR
end    

select @w_code_version = max(rv_id) 
from   cob_pac..bpl_rule_version 
where  rl_id           = @w_code_rule 
and    rv_status       = 'PRO'

begin tran
delete from cob_cartera..ca_incentivos_rangos_riesgo

insert into cob_cartera..ca_incentivos_rangos_riesgo
select cr1.cr_max_value as cargo,               --Cargo
	   cr2.cr_min_value as rango_inicial,       --Rango inicial
	   cr2.cr_max_value as rango_final,         --Rango final
	   cr3.cr_max_value as porcentaje_incentivo --Porcentaje 
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent 
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = @w_code_version
and cr1.cr_parent is NULL
and cr3.cr_is_last_son = 'true'

if (@@error <> 0) 
begin
    select @w_error = 725221 
    goto ERROR
end 


-- Regla Indicador de Cumplimiento
select @w_code_rule = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'INDCUMPLIM'--'Indicador de cumplimiento'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'

if @@rowcount <> 1
begin
	select @w_error = 725109 
      goto ERROR
end    

select @w_code_version = max(rv_id) 
from   cob_pac..bpl_rule_version 
where  rl_id           = @w_code_rule 
and    rv_status       = 'PRO'
				   
delete from cob_cartera..ca_incentivos_rangos_cumplimiento_cartera

insert into cob_cartera..ca_incentivos_rangos_cumplimiento_cartera
select cr1.cr_max_value as cargo,                              --Cargo
	   cr2.cr_min_value as rango_inicial,       --Rango inicial
	   cr2.cr_max_value as rango_final,          --Rango final
	   cr3.cr_max_value as porcentaje_incentivo                --Porcentaje 
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent 
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = @w_code_version
and cr1.cr_parent is NULL
and cr3.cr_is_last_son = 'true'

if (@@error <> 0) 
begin
    select @w_error = 725222 
    goto ERROR
end 


-- Regla Indicador de Clientes
select @w_code_rule = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'INDCLIENTE'--'Indicador de clientes'
and  r.rl_id          =  v.rl_id
and  v.rv_status      = 'PRO'

if @@rowcount <> 1
begin
	select @w_error = 725109 
      goto ERROR
end    

select @w_code_version = max(rv_id) 
from   cob_pac..bpl_rule_version 
where  rl_id           = @w_code_rule 
and    rv_status       = 'PRO'
				   
delete from cob_cartera..ca_incentivos_rangos_clientes

insert into cob_cartera..ca_incentivos_rangos_clientes
select cr1.cr_max_value as cargo,                              --Cargo
	   cr2.cr_min_value as rango_inicial,       --Rango inicial
	   cr2.cr_max_value as rango_final,          --Rango final
	   cr3.cr_max_value as porcentaje_incentivo                --Porcentaje 
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent 
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = @w_code_version
and cr1.cr_parent is NULL
and cr3.cr_is_last_son = 'true'

if (@@error <> 0) 
begin
    select @w_error = 725223 
    goto ERROR
end 

commit tran

return 0

ERROR:
while @@trancount > 0 ROLLBACK TRAN        
exec cobis..sp_cerror
@t_debug='N',    
@t_file=null,
@t_from=@w_sp_name,   
@i_num = @w_error

return @w_error   

go
