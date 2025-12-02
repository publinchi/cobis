
/***********************************************************************  */
/*   Archivo:              pasohis.sp                                     */
/*   Stored procedure:     sp_pasohis                                     */
/*   Base de datos:        cob_cartera                                    */
/*   Producto:             Credito y Cartera                              */
/*   Disenado por:         Fabian de la Torre                             */
/*   Fecha de escritura:   FEB. 2018                                      */
/***********************************************************************  */
/*                               IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de        */
/*   'MACOSA'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como           */
/*   cualquier alteracion o agregado hecho por alguno de sus              */
/*   usuarios sin el debido consentimiento por escrito de la              */
/*   Presidencia Ejecutiva de MACOSA o su representante.                  */
/*                                PROPOSITO                               */
/*   Procedimiento que realiza el paso a historicos                       */
/***********************************************************************  */

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pasohis' and type = 'P')
   drop proc sp_pasohis
go

create proc sp_pasohis
as 

declare
@w_error                int,
@w_commit               char(1),
@w_week_backup          tinyint,
@w_fecha_proc           datetime,
@w_ciudad                 int,
@w_msg                   varchar(255),
@w_s_app                 varchar(255),
@w_path                  varchar(255),
@w_comando               varchar(1000),
@w_errores               varchar(255),
@w_cmd                   varchar(255),
@w_base                  varchar(255),
@w_tabla                  varchar(255)


select @w_week_backup = pa_tinyint 
from  cobis..cl_parametro
where pa_nemonico = 'SEMBK' --SEMANAS PARA BACKUP

select @w_fecha_proc = fp_fecha from cobis..ba_fecha_proceso 


select @w_ciudad = pa_smallint 
from  cobis..cl_parametro
where pa_nemonico = 'CFN'

if @@rowcount = 0 begin
   select 
   @w_error  = 609318,
   @w_msg    = 'ERROR: NO EXISTE PARAMETRO CFN'
   goto ERROR
end

--ESTE PROCESO NO SE EJECUTA SI EL DIA DE AYER NO ES FERIADO POR EL INICIO DE DIA DEL BATCH 
if not exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad and df_fecha = dateadd(dd,-1,@w_fecha_proc ))  return 0

--ESTO SE EJECUTA CADA N SEMANAS DE ACUERDO A LO QUE INDICA EL PARAMETRO 
if  (datepart (ww, @w_fecha_proc)%@w_week_backup)  <> 0  return 0 



insert into cob_cartera_his..ca_operacion_his         select * from cob_cartera..ca_operacion_his         if  @@error <> 0 begin select @w_error = 710003, @w_msg = '01'goto ERROR end 
insert into cob_cartera_his..ca_rubro_op_his          select * from cob_cartera..ca_rubro_op_his          if  @@error <> 0 begin select @w_error = 710003, @w_msg = '02'goto ERROR end
insert into cob_cartera_his..ca_dividendo_his         select * from cob_cartera..ca_dividendo_his         if  @@error <> 0 begin select @w_error = 710003, @w_msg = '03'goto ERROR end
insert into cob_cartera_his..ca_amortizacion_his      select * from cob_cartera..ca_amortizacion_his      if  @@error <> 0 begin select @w_error = 710003, @w_msg = '04'goto ERROR end
insert into cob_cartera_his..ca_correccion_his        select * from cob_cartera..ca_correccion_his        if  @@error <> 0 begin select @w_error = 710003, @w_msg = '05'goto ERROR end
insert into cob_cartera_his..ca_cuota_adicional_his   select * from cob_cartera..ca_cuota_adicional_his   if  @@error <> 0 begin select @w_error = 710003, @w_msg = '06'goto ERROR end
insert into cob_cartera_his..ca_valores_his           select * from cob_cartera..ca_valores_his           if  @@error <> 0 begin select @w_error = 710003, @w_msg = '07'goto ERROR end
insert into cob_cartera_his..ca_diferidos_his         select * from cob_cartera..ca_diferidos_his         if  @@error <> 0 begin select @w_error = 710003, @w_msg = '08'goto ERROR end
insert into cob_cartera_his..ca_facturas_his          select * from cob_cartera..ca_facturas_his          if  @@error <> 0 begin select @w_error = 710003, @w_msg = '09'goto ERROR end
insert into cob_cartera_his..ca_traslado_interes_his  select * from cob_cartera..ca_traslado_interes_his  if  @@error <> 0 begin select @w_error = 710003, @w_msg = '10'goto ERROR end
insert into cob_cartera_his..ca_comision_diferida_his select * from cob_cartera..ca_comision_diferida_his if  @@error <> 0 begin select @w_error = 710003, @w_msg = '11'goto ERROR end
insert into cob_cartera_his..ca_seguros_his           select * from cob_cartera..ca_seguros_his           if  @@error <> 0 begin select @w_error = 710003, @w_msg = '12'goto ERROR end
insert into cob_cartera_his..ca_seguros_det_his       select * from cob_cartera..ca_seguros_det_his       if  @@error <> 0 begin select @w_error = 710003, @w_msg = '13'goto ERROR end
insert into cob_cartera_his..ca_seguros_can_his       select * from cob_cartera..ca_seguros_can_his       if  @@error <> 0 begin select @w_error = 710003, @w_msg = '14'goto ERROR end
insert into cob_cartera_his..ca_operacion_ext_his     select * from cob_cartera..ca_operacion_ext_his     if  @@error <> 0 begin select @w_error = 710003, @w_msg = '15'goto ERROR end


truncate table ca_operacion_his         if  @@error <> 0 begin select @w_error = 710003,@w_msg = '30' goto ERROR end 
truncate table ca_rubro_op_his          if  @@error <> 0 begin select @w_error = 710003,@w_msg = '31' goto ERROR end
truncate table ca_dividendo_his         if  @@error <> 0 begin select @w_error = 710003,@w_msg = '32' goto ERROR end
truncate table ca_amortizacion_his      if  @@error <> 0 begin select @w_error = 710003,@w_msg = '33' goto ERROR end
truncate table ca_correccion_his        if  @@error <> 0 begin select @w_error = 710003,@w_msg = '34' goto ERROR end
truncate table ca_cuota_adicional_his   if  @@error <> 0 begin select @w_error = 710003,@w_msg = '35' goto ERROR end
truncate table ca_valores_his           if  @@error <> 0 begin select @w_error = 710003,@w_msg = '36' goto ERROR end
truncate table ca_diferidos_his         if  @@error <> 0 begin select @w_error = 710003,@w_msg = '37' goto ERROR end
truncate table ca_facturas_his          if  @@error <> 0 begin select @w_error = 710003,@w_msg = '38' goto ERROR end
truncate table ca_traslado_interes_his  if  @@error <> 0 begin select @w_error = 710003,@w_msg = '39' goto ERROR end
truncate table ca_comision_diferida_his if  @@error <> 0 begin select @w_error = 710003,@w_msg = '40' goto ERROR end
truncate table ca_seguros_his           if  @@error <> 0 begin select @w_error = 710003,@w_msg = '41' goto ERROR end
truncate table ca_seguros_det_his       if  @@error <> 0 begin select @w_error = 710003,@w_msg = '42' goto ERROR end
truncate table ca_seguros_can_his       if  @@error <> 0 begin select @w_error = 710003,@w_msg = '43' goto ERROR end
truncate table ca_operacion_ext_his     if  @@error <> 0 begin select @w_error = 710003,@w_msg = '44' goto ERROR end

    
return 0

ERROR:

exec cobis..sp_ba_error_log
    @t_trn           = 7221,
    @i_operacion     = 'I',
    @i_sarta         = 22, 
    @i_batch         = 7221,
    @i_fecha_proceso = @w_fecha_proc,
    @i_error         = @w_error,
    @i_detalle       = @w_msg


return @w_error
go