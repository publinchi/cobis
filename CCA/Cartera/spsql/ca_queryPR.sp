/***********************************************************************/
/*      Producto:                       Cartera                        */
/*      Disenado por:                   Elcira Pelaez                  */
/*      Fecha de Documentacion:         Feb-2013                       */
/*      Procedimiento                   ca_queryPR.sp                  */
/***********************************************************************/
/*                      IMPORTANTE                                     */
/*      Este programa es parte de los paquetes bancarios propiedad de  */
/*      'MACOSA',representantes exclusivos para el Ecuador de la       */
/*      AT&T                                                           */
/*      Su uso no autorizado queda expresamente prohibido asi como     */
/*      cualquier autorizacion o agregado hecho por alguno de sus      */
/*      usuario sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*      Este stored procedure genera informacion que deja caragada enla*/
/*      tabla    ca_operaciones_con_recono_tmp para futuros reprotes   */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/***********************************************************************/
use cob_cartera
go



if exists (select 1 from sysobjects where name = 'sp_query_Pag_Reconocimientos')
   drop proc sp_query_Pag_Reconocimientos
go

create proc sp_query_Pag_Reconocimientos 

as

declare
@w_error            int,
@w_sp_name          varchar(30),
@w_fecha_proc       varchar(10),
@w_fecha_proceso    datetime , 
@w_fecha_ini        datetime,
@w_parametro_fecha  datetime


truncate table ca_operaciones_con_recono_tmp

select 
@w_fecha_proceso = fc_fecha_cierre,
@w_fecha_ini     = dateadd(dd,1-datepart(dd,fc_fecha_cierre), fc_fecha_cierre)
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_parametro_fecha  = pa_datetime 
from cobis..cl_parametro
where pa_nemonico = 'PAGRCO'
and pa_producto = 'CCA'

select @w_fecha_ini
select @w_fecha_proceso

select op_operacion,op_banco,op_tramite
into #operaciones
from cob_cartera..ca_operacion with (nolock), 
     cob_cartera..ca_estado with (nolock)
where op_estado   = es_codigo
and  (es_procesa  = 'S' 
      or (op_estado= 3 and op_fecha_ult_proceso between @w_fecha_ini and @w_fecha_proceso)     
      or (op_estado= 3 and op_fecha_ult_proceso < @w_fecha_ini and op_fecha_ult_mov between @w_fecha_ini and @w_fecha_proceso )
     ) 

insert into ca_operaciones_con_recono_tmp
select op_banco,op_operacion,abd_concepto,ab_fecha_pag,abd_monto_mop,0,'N'
 from cob_cartera..ca_abono with (nolock),
      cob_cartera..ca_abono_det with (nolock),
      #operaciones
where abd_operacion = ab_operacion
and abd_secuencial_ing =ab_secuencial_ing
and abd_concepto  in (select c.codigo from cobis..cl_catalogo c
                      where c.tabla in (select codigo  from cobis..cl_tabla 
                                        where  tabla = 'ca_fpago_reconocimiento')
                  )
and ab_estado = 'A'
and op_operacion = ab_operacion
and ab_fecha_ing > @w_parametro_fecha  ---fecha inico de pagos recono


---Actualizar la tabla con los que han tenido pagos x reconocimiento y
---estan registrados en la tabla ca_pago_recono

update ca_operaciones_con_recono_tmp
set rt_valor_amort   = pr_vlr_amort,
    rt_pago_x_recono = 'S'
from ca_pago_recono,   
      ca_operaciones_con_recono_tmp 
where pr_operacion = rt_operacion
and   pr_estado <> 'R' ---reversos      


PRINT ''
PRINT 'Operaciones cargadas'
select count(1) from ca_operaciones_con_recono_tmp
PRINT ''



return 0

go


