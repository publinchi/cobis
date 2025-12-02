
use cob_cartera
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_op_1173')
   drop proc sp_cambio_estado_op_1173
go
---INC. 112725 MAY.07.2013
create proc sp_cambio_estado_op_1173(
   @s_user           login,
   @s_term           varchar(30),
   @s_date           datetime,
   @s_ofi            smallint,
   @i_banco          cuenta,
   @i_fecha_proceso  datetime,
   @i_estado_ini     int = null, 
   @i_estado_fin     int = null,
   @i_tipo_cambio    char(1),
   @i_front_end      char(1) = 'N',
   @i_en_linea       char(1),
   @o_msg            varchar(100) = null out  )

as
declare
   @w_error             int,
   @w_moneda            tinyint,
   @w_moneda_local      tinyint,
   @w_estado_actual     tinyint,
   @w_num_dec           smallint,
   @w_moneda_nac        smallint,
   @w_num_dec_mn        smallint,
   @w_toperacion        catalogo,
   @w_oficina           int,
   @w_operacionca       int,
   @w_gerente           int,
   @w_est_suspenso      tinyint,
   @w_edad              tinyint,
   @w_garantia          char(1), 
   @w_reestructuracion  char(1), 
   @w_calificacion      catalogo, 
   @w_est_castigado     tinyint,
   @w_est_anulado       tinyint,
   @w_fecha_ult_proceso datetime,
   @w_estado_op         tinyint

select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'


/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_castigado  = @w_est_castigado out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_suspenso   = @w_est_suspenso  out

if @w_error <> 0 return @w_error


-- DATOS DEL PRESTAMO
select 
@w_toperacion        = op_toperacion,
@w_moneda            = op_moneda,
@w_estado_actual     = op_estado,
@w_oficina           = op_oficina,
@w_operacionca       = op_operacion,
@w_gerente           = op_oficial,
@w_edad              = op_edad,
@w_garantia          = op_gar_admisible,    
@w_reestructuracion  = op_reestructuracion, 
@w_calificacion      = op_calificacion,     
@w_fecha_ult_proceso = op_fecha_ult_proceso
from   ca_operacion
where  op_banco      = @i_banco

-- MANEJO DE DECIMALES PARA LA MONEDA DE LA OPERACION
-- MANEJO DE DECIMALES
exec @w_error  = sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec out,
@o_mon_nacional = @w_moneda_nac out,
@o_dec_nacional = @w_num_dec_mn out



if @i_tipo_cambio = 'A' --CAMBIO AUTOMATICO
begin
   exec @w_error = sp_cambio_estado_automatico
   @s_user          = @s_user,
   @s_term          = @s_term,
   @s_date          = @s_date,
   @s_ofi           = @s_ofi,
   @i_toperacion    = @w_toperacion,
   @i_oficina       = @w_oficina,
   @i_banco         = @i_banco,
   @i_operacionca   = @w_operacionca,
   @i_moneda        = @w_moneda,
   @i_fecha_proceso = @i_fecha_proceso,
   @i_en_linea      = @i_en_linea,
   @i_gerente       = @w_gerente,
   @i_estado_ini    = @w_edad,
   @i_moneda_nac    = @w_moneda_nac
   
   if @w_error <> 0    return @w_error
   if  @@error <> 0 
   begin
      PRINT 'error ejecutando sp  sp_cambio_estado_automatico  @i_banco  ' + cast ( @i_banco as varchar)
      return 708201
   end

end


if @i_tipo_cambio = 'M' --CAMBIO MANUAL
begin
   exec @w_error = sp_cambio_estado_manual
   @s_user          = @s_user,
   @s_term          = @s_term,
   @s_date          = @s_date,
   @s_ofi           = @s_ofi,
   @i_toperacion    = @w_toperacion,
   @i_oficina       = @w_oficina,
   @i_banco         = @i_banco,
   @i_operacionca   = @w_operacionca,
   @i_moneda        = @w_moneda,
   @i_fecha_proceso = @i_fecha_proceso,
   @i_en_linea      = @i_en_linea,
   @i_gerente       = @w_gerente,
   @i_estado_ini    = @w_estado_actual,
   @i_estado_fin    = @i_estado_fin,
   @i_moneda_nac    = @w_moneda_nac
   
   if @w_error <> 0    return @w_error
   if  @@error <> 0 
   begin
      PRINT 'error ejecutando sp  sp_cambio_estado_manual  @i_banco  ' + cast ( @i_banco as varchar)
      return 708201
   end
         
end


if @i_tipo_cambio = 'S' begin

   exec @w_error = sp_cambio_estado_suspenso
   @s_user          = @s_user,
   @s_term          = @s_term,
   @s_date          = @s_date,
   @s_ofi           = @s_ofi,
   @i_toperacion    = @w_toperacion,
   @i_oficina       = @w_oficina,
   @i_banco         = @i_banco,
   @i_operacionca   = @w_operacionca,
   @i_moneda        = @w_moneda,
   @i_fecha_proceso = @i_fecha_proceso,
   @i_en_linea      = @i_en_linea,
   @i_gerente       = @w_gerente,
   @i_estado_ini    = @w_estado_actual,
   @i_estado_fin    = @i_estado_fin,
   @i_front_end     = @i_front_end,
   @i_moneda_nac    = @w_moneda_nac
   
   if @w_error <> 0 return @w_error
   
   if  @@error <> 0 
   begin
      PRINT 'error ejecutando sp  sp_cambio_estado_suspenso  @i_banco  ' + cast ( @i_banco as varchar)
      return 708201
   end
   
end


/* CASTIGO DE OPERACIONES */
if @i_tipo_cambio = 'C' begin

   exec @w_error = sp_transaccion_cas_1173
   @s_user          = @s_user,
   @s_term          = @s_term,
   @i_operacionca   = @w_operacionca,
   @o_msg           = @o_msg out
   
   if @w_error  <> 0 return @w_error

   if  @@error <> 0 
   begin
      PRINT 'error ejecutando sp  sp_transaccion_cas  @w_operacionca  ' + cast ( @w_operacionca as varchar)
      return 708201
   end   
   
end


if @i_estado_fin in (@w_est_castigado, @w_est_anulado, @w_est_suspenso)
begin
   update ca_operacion
   set    op_fecha_ult_mov = @w_fecha_ult_proceso
   where  op_operacion   = @w_operacionca
   
   if @@error <> 0 return 710001
   
   update ca_operacion_his
   set    oph_fecha_ult_mov = @w_fecha_ult_proceso
   where  oph_operacion   = @w_operacionca
   
   if @@error <> 0  return 710001
end

--PARA ASEGURAR LA CONSISTENCIA DE LOS DATOS
select  @w_estado_op = op_estado
from    ca_operacion
where op_operacion = @w_operacionca

if @w_estado_op <> 0  and @i_estado_fin <> @w_est_anulado
begin
   if not exists (select 1 from ca_dividendo
                  where di_operacion = @w_operacionca
                  and   di_estado in (1,2,3) 
                  )
    return  710578
                  
end

return 0

go

