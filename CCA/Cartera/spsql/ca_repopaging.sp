/************************************************************************/
/*      Archivo:                ca_repopaging.sp                        */
/*      Stored procedure:       sp_reporte_pagos_ing_eventual           */
/*      Producto:               Cartera                                 */
/*      Disenado por:           ELci aPelaez Burbano                    */
/*      Fecha de escritura:     ENE.2012                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Genera planode pagosING                                         */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'ca_pagos_ing_eventual')
   drop table ca_pagos_ing_eventual

create table ca_pagos_ing_eventual (
fecha_pago                varchar(10)   null,
oficina                   varchar(24)   null,
cedula                    varchar(24)   null,
banco                     varchar(24)   null,
forma_pago                varchar(10)   null,
valor_pago                money         null

)
go

set ansi_warnings off
go

if exists (select * from sysobjects where name = 'sp_reporte_pagos_ing_eventual')
   drop proc sp_reporte_pagos_ing_eventual
go

create proc sp_reporte_pagos_ing_eventual
as
declare 
@w_sp_name            varchar(32),
@w_error              int,
@w_s_app              varchar(250),
@w_cmd                varchar(250),
@w_path               varchar(250),
@w_comando            varchar(500),
@w_batch              int,
@w_fecha              datetime,
@w_destino            varchar(255),
@w_errores            varchar(255),
@w_hora_arch     	  varchar(10)

truncate table ca_pagos_ing_eventual 


insert into ca_pagos_ing_eventual
select convert(varchar(10),ab_fecha_pag,101),op_oficina,en_ced_ruc,op_banco,abd_concepto,abd_monto_mop
from cob_cartera..ca_abono  with (nolock),
     cob_cartera..ca_abono_det with (nolock),
     cob_cartera..ca_operacion with (nolock),
     cobis..cl_ente  with (nolock),
     cobis..ba_fecha_cierre
where    op_operacion = ab_operacion
and ab_fecha_ing = fc_fecha_cierre
and fc_producto = 7
and ab_operacion = abd_operacion
and ab_secuencial_ing = abd_secuencial_ing
and op_cliente = en_ente
and ab_estado = 'ING'

select @w_fecha = getdate()

select @w_hora_arch = convert(varchar(2), datepart(dd,@w_fecha)) + '_' + convert(varchar(2), datepart(mm,@w_fecha)) + '_' + convert(varchar(4), datepart(yyyy, @w_fecha)) 

select @w_path = ba_path_destino 
from cobis..ba_batch 
where ba_arch_fuente = 'cob_cartera..sp_reporte_pagos_ing_eventual'

select @w_s_app = pa_char 
from cobis..cl_parametro 
where pa_producto = 'ADM' 
and pa_nemonico = 'S_APP'

----------------------------------------
--Generar Archivo Plano 
----------------------------------------
select @w_cmd = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_pagos_ing_eventual out '
select @w_destino  = @w_path + 'ca_pagos_ING' + '_' + @w_hora_arch + '.txt',
       @w_errores  = @w_path + 'ca_pagos_ING' + '_' + @w_hora_arch + '.err'
select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -e ' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec   @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   print 'Error Generando archivo de ca_pagos_ING'
   print @w_comando 
   return 1
end

                
return 0
   
go



