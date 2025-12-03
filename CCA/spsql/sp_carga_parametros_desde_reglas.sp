/************************************************************************/ 
/*    ARCHIVO:         sp_carga_parametros_desde_reglas.sp              */ 
/*    NOMBRE LOGICO:   sp_carga_parametros_desde_reglas                 */ 
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:    Johan Hernandez                                   */
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
/* 18/05/2021    J. Hernandez	 Versión Inicial                        */
/************************************************************************/ 

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_carga_parametros_desde_reglas')
   drop proc sp_carga_parametros_desde_reglas
go
create proc sp_carga_parametros_desde_reglas
 
as declare 
@w_code_rule        int,
@w_sp_name          varchar(64),
@w_error		    int,
@w_code_version     int

select @w_sp_name =  'sp_carga_parametros_desde_reglas'         

-- Regla GASTOS POR GESTION COBRANZA
 
select @w_code_rule = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'GAGECO'--'GASTOS POR GESTION COBRANZA'
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
				   
delete from cob_cartera..ca_param_cargos_gestion_cobranza

insert into cob_cartera..ca_param_cargos_gestion_cobranza
select cr1.cr_min_value as variable_1, --Rango Minimo Cuota
	   cr1.cr_max_value as variable_2, --Rango Maximo Cuota
	   cr2.cr_min_value as variable_3, --Rango Minimo Dias
	   cr2.cr_max_value as variable_4, --Rango Maximo Dias
	   cr3.cr_max_value as result_1    -- Valor 
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent 
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
where cr1.rv_id = @w_code_version
and cr1.cr_parent is NULL
and cr3.cr_is_last_son = 'true'

if (@@error <> 0) 
begin
    select @w_error = 725111 
    goto ERROR
end 




--Regla CALIFICACION Y PROVISION

 declare @w_regla_calprov table(
   variable_1     varchar(255), --clase cartera
   variable_2     varchar(255), --dias vencimiento min
   variable_3     varchar(255), --dias vencimiento max
   result_1       varchar(255), --provision
   result_2       varchar(255), --calificación provisión
   result_3       varchar(255), --provisión interés
   result_4       varchar(255)  --provisión capital
   unique nonclustered (variable_1,variable_2,variable_3)
)

select @w_code_rule = r.rl_id
from cob_pac..bpl_rule r, 
     cob_pac..bpl_rule_version v
where r.rl_acronym = 'CALPROV'--'CALIFICACION Y PROVISION'
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

delete from cob_cartera..ca_provision_tca      
 
insert into @w_regla_calprov	
select cr1.cr_max_value as variable_1, 
       cr2.cr_min_value as variable_2, 
	   cr2.cr_max_value as variable_3,
	   cr3.cr_max_value as result_1,
   	   cr4.cr_max_value as result_2,
   	   cr5.cr_max_value as result_3,
   	   cr6.cr_max_value as result_4
from  cob_pac..bpl_condition_rule cr1
inner join cob_pac..bpl_condition_rule cr2 on cr1.cr_id = cr2.cr_parent 
inner join cob_pac..bpl_condition_rule cr3 on cr2.cr_id = cr3.cr_parent
inner join cob_pac..bpl_condition_rule cr4 on cr3.cr_id = cr4.cr_parent
inner join cob_pac..bpl_condition_rule cr5 on cr4.cr_id = cr5.cr_parent
inner join cob_pac..bpl_condition_rule cr6 on cr5.cr_id = cr6.cr_parent
where cr1.rv_id = @w_code_version
and cr1.cr_parent is null
and cr3.cr_is_last_son = 'true'
and cr4.cr_is_last_son = 'true'  	  
and cr5.cr_is_last_son = 'true'  
and cr6.cr_is_last_son = 'true'

insert into cob_cartera..ca_provision_tca
select variable_1,
       cast(variable_2 as int),
	   cast(variable_3 as int),
	   result_2,
	   cast(result_1 as float), 
	   cast(result_3 as float),
	   cast(result_4 as float)  
from @w_regla_calprov


if (@@error <> 0) 
begin
    select @w_error = 725110 
    goto ERROR
end 

return 0

ERROR:
exec cobis..sp_cerror
@t_debug='N',    
@t_file=null,
@t_from=@w_sp_name,   
@i_num = @w_error

return @w_error   

go

