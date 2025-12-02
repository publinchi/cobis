/************************************************************************/
/*      Archivo:                pagosfng.sp                    			*/
/*      Stored procedure:       sp_pagos_fng                            */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Jonnatan Peña                           */
/*      Fecha de escritura:     Mar. 2009                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCORP".                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Genera datos para el reporte                                    */
/*      "Pagos Realizados por por creditos cobiertos por el Fondo 		*/
/*       nacional de garantias (FNG) 									*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pagos_fng')
   drop proc sp_pagos_fng
go

create proc sp_pagos_fng (  
   @i_fecha    datetime = null
)
as

declare 
   @w_sp_name         varchar(32),
   @w_return          int,
   @w_error           int, 
   @w_msg             varchar(100),  
   @w_fecha_ini       datetime,
   @w_fecha_fin       datetime
                     

select @w_fecha_ini = dateadd(dd,1-datepart(dd,@i_fecha),@i_fecha)
select @w_fecha_fin = dateadd(mm, 1, dateadd(dd,-datepart(dd,@i_fecha),@i_fecha))

  
/*CREACION DE TABLA FIJA PARA EL REPORTE */
IF exists (SELECT  1 FROM sysobjects WHERE name = 'ca_pagos_fng')
   drop table ca_pagos_fng 

create table ca_pagos_fng
(
pf_num_operacion       varchar(24)   not null,
pf_nombre_cliente      varchar(255)  null,
pf_identificacion      varchar(30)   null,
pf_fecha_abono_fng     datetime      null,
pf_monto_op_fng        money         null,
pf_total_pagos_fng     money         null,
pf_saldos_fng 		   money         null
)

select @w_sp_name  = 'sp_pagos_fng' 


insert into ca_pagos_fng
select 
op_banco,             
op_nombre,                       
en_ced_ruc,
op_fecha_ini, 
op_monto,
total = sum(abd_monto_mn),
saldo = (op_monto - sum(abd_monto_mn))
from ca_operacion, cobis..cl_ente, ca_abono, ca_abono_det
where en_ente = op_cliente
and  op_operacion = ab_operacion
and  op_operacion = abd_operacion
and  abd_secuencial_ing = ab_secuencial_ing
and  ab_operacion = abd_operacion
and  op_tipo = 'G'
and  ab_estado = 'A'
and  ab_fecha_pag between @w_fecha_ini and @w_fecha_fin
group by abd_monto_mn, op_cliente, op_banco,
		 op_nombre, en_ced_ruc, op_fecha_ini, abd_monto_mn,
		 op_monto
 
		 
if @@error <> 0 begin                                                                   
   select                                                                         		 
   @w_error = 2103001,                                                            		 
   @w_msg   = 'ERROR AL INSERTAR LA INFORMACION DE PAGOS FNG'		 
   goto ERROR                                                                     		 
end                                                                               
            		 		 
return 0
		 
ERROR:

Exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null, 
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg

return @w_error   
go
          