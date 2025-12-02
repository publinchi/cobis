/************************************************************************/
/*  Archivo:            conscli.sp                                      */
/*  Stored procedure:   sp_consulta_cliente                             */
/*  Base de datos:      cob_cartera                                     */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                            PROPOSITO                                 */
/*  Lista los prestamos de un cliente.                                  */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_cliente')
   drop proc sp_consulta_cliente
go

create proc sp_consulta_cliente
        @i_cliente           int         = null

as                           
declare 
@w_sp_name           varchar(32),
@w_est_novigente     tinyint,
@w_est_cancelado     tinyint,
@w_est_credito       tinyint,
@w_est_anulado       tinyint,
@w_error             int
   

select 
@w_sp_name = 'sp_consulta_cliente'
  
/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_credito    = @w_est_credito   out

if @w_error <> 0 return @w_error

insert into #operacion   
select
banco             = op_banco,
rol               = de_rol,
dias              = case when (datediff(dd,min(di_fecha_ven), op_fecha_ult_proceso)) < 0 then 0 else (datediff(dd,min(di_fecha_ven), op_fecha_ult_proceso)) end,
fecha_ven         = min(di_fecha_ven)
from ca_operacion, ca_dividendo, cob_credito..cr_deudores
where de_cliente     =  @i_cliente
and   di_operacion   =  op_operacion
and   op_tramite     =  de_tramite
and   op_estado not in (@w_est_novigente, @w_est_anulado,@w_est_credito,@w_est_cancelado)
and   di_estado not in (@w_est_cancelado)
group by op_banco,de_rol,op_fecha_ult_proceso
order by min(di_fecha_ven)

if @@error <> 0 return 710001
   
return 0

go               