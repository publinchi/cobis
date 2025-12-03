
/*************************************************************/
/********** TOTALES  PAGOS DE CARTERA 10/19/2010    **********/
/*************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dpagosa_diario')
   drop proc sp_dpagosa_diario
go
---Ind.37475 partiendo de la version 1
create proc sp_dpagosa_diario
@i_param1     varchar(255),
@i_param2     varchar(255)

as declare

@w_s_app                        varchar(255),
@w_path                         varchar(255),
@w_destino                      varchar(255),
@w_errores                      varchar(255),
@w_cmd                          varchar(500),
@w_comando                      varchar(5000),
@w_batch                        int,
@w_error                        int,
@w_fecha_pagos                  datetime,
@w_hora_arch     		        varchar(4)

truncate table ca_dpagosa_diario

select
@w_fecha_pagos   = @i_param1,
@w_batch         = convert(int,@i_param2)

insert into ca_dpagosa_diario
select abd_concepto,sum(abd_monto_mn) 
from ca_abono, ca_abono_det
where ab_operacion  = abd_operacion
and   ab_secuencial_ing = abd_secuencial_ing
and   ab_estado = 'A'
and   ab_fecha_ing = @w_fecha_pagos 
group by abd_concepto

----------------------------------------
--Generar Archivo Plano
----------------------------------------
select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = @w_batch

select @w_hora_arch     = substring(convert(varchar,GetDate(),108),1,2) + substring(convert(varchar,GetDate(),108),4,2)
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_dpagosa_diario out '
select @w_destino  = @w_path + 'ca_dpagosa_diario' + replace(convert(varchar, @w_fecha_pagos, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.txt',
       @w_errores  = @w_path + 'ca_dpagosa_diario' + replace(convert(varchar, @w_fecha_pagos, 102), '.', '') + '_' + replace(convert(varchar, getdate(), 108), ':', '') + '.err'
select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"!" ' + '-config '+ @w_s_app + 's_app.ini'


print 'bcp_25_reest @w_comando ' + cast(@w_comando as varchar)

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error generando Archivo ca_dpagosa_diario'
   print @w_comando
   return 1
end

print 'FIN  getdate ' + convert (varchar(20), getdate() ,109)

return 0

