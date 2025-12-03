/************************************************************************/
/*      Archivo:                ca_sec_asegurado_univ.sp                */
/*      Stored procedure:       sp_sec_asegurado_univ                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Fecha de escritura:     Noviembre 2013                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/* crea universo de operaciones a las que se le debe incluir el         */ 
/* secuencial del asegurado en la tabla ca_seguros_det                  */ 
/************************************************************************/
/*                              CAMBIOS                                 */
/*  FECHA     AUTOR             RAZON                                   */
/*  14-12-14  Luis Guzman       Emisión Inicial - Req: 403              */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_sec_aseg_univ')
   drop proc sp_sec_aseg_univ
go

create proc sp_sec_aseg_univ

as
declare
   @w_operacion     int,   
   @w_sp_name       varchar(32),
   @w_error         int,
   @w_msg           varchar(255),
   @w_fecha_proceso datetime

set nocount on

select @w_sp_name = 'sp_sec_aseg_univ'

-- OBTIENE FECHA DE PROCESO
select @w_fecha_proceso = fc_fecha_cierre 
from cobis..ba_fecha_cierre
where fc_producto = 7

if @@rowcount = 0
begin
   select @w_msg = 'Error al leer fecha de proceso de cartera',
          @w_error = 801085
   goto ERROR
end

if not exists (select 1 from sysobjects where name = 'seguros_det_universo')
   create table seguros_det_universo(
   operacion  int,
   dividendos int,
   estado     char(1))

insert into seguros_det_universo
select 'operacion' = sed_operacion, COUNT(1) no_dividendos, estado = 'I'
from cob_cartera..ca_seguros,cob_cartera..ca_seguros_det
where se_sec_seguro      = sed_sec_seguro
and   se_tipo_seguro     in (1)
and   sed_dividendo      = 1
and   sed_tipo_asegurado = 2
and   sed_sec_asegurado is null
and   se_estado          <> 'C'
group by sed_operacion
having COUNT(sed_dividendo) > 1

if @@rowcount = 0
begin
   select @w_msg   = 'No se encontraron opeaciones para procesar',
          @w_error = 801085
   goto ERROR
end

-- crear tabla ca_venta_universo
if not exists (select 1 from sysobjects where name = 'ca_seguros_det_tmp_403')
   select * into cob_cartera..ca_seguros_det_tmp_403 from ca_seguros_det

while 1 = 1
begin
   
   select top 1 
   @w_operacion = operacion
   from seguros_det_universo
   where estado = 'I'
   
   if @@rowcount = 0 break      
   
   exec @w_error = sp_recons_seguros
   @i_operacion = @w_operacion

   if @@error <> 0      
   begin   
      select @w_msg = 'No se pudo ejecutar sp_sec_asegurado desde sp_sec_aseg_univ '+ cast(@w_error as varchar),
             @w_error = @w_error
      goto ERROR
   end     
   
   update seguros_det_universo set
   estado = 'P'
   where operacion = @w_operacion
   and   estado = 'I'
   
   if @@error <> 0
   begin
      select @w_msg = 'Error al actualizar #seguros_det_universo para estado procesado',
             @w_error = 708152
      goto ERROR
   end   

end

return 0

ERROR:

exec cob_cartera..sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = @w_error, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return @w_error
go
