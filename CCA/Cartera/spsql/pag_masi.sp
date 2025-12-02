/************************************************************************/
/*   Archivo:            pag_masi.sp                                    */
/*   Stored procedure:   sp_pagos_masivos                               */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       RRB                                            */
/*   Fecha de escritura: Ago-2009                                       */
/************************************************************************/
/*                       IMPORTANTE                                     */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                       PROPOSITO                                      */
/*   Aplicacion Pagos por Recuados                                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pagos_masivos')
   drop proc sp_pagos_masivos
go
create proc sp_pagos_masivos
-- parametros del bacth
   @i_param1           varchar(255)  = null -- fecha proceso
-- parametros del bacth
as declare
   @w_banco              cuenta,
   @w_fecha_pag          datetime,
   @w_fecha_cartera      datetime,
   @w_sp_name            varchar(64),
   @w_descripcion        varchar(255),
   @w_return             int,
   @w_fecha_ult_proceso  datetime,
   @w_op_moneda          smallint,
   @w_cotizacion_hoy     money,
   @w_moneda_nacional    tinyint,
   @w_ab_oficina         int,
   @w_operacionca        int,
   @w_new_fecha_ult_proc datetime,
   @w_rowcount           int,
   @w_secuencial_ing     int,
   @w_dfval               smallint,
   @w_fecha_limite       datetime

-- FECHA DE PROCESO

select @w_sp_name     = 'sp_pagos_masivos',
       @w_descripcion = 'NO'

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_descripcion = 'Error no hay cotizacion par aplicar los pagos'
   select @w_return = 708174
   goto ERROR
end

select @w_fecha_cartera = convert(datetime, @i_param1, 101)

select @w_dfval = pa_smallint
 from cobis..cl_parametro
where pa_nemonico = 'DFVAL'
and pa_producto ='CCA'

if @w_dfval is null
   select @w_dfval = 0


select @w_fecha_limite = dateadd(dd,-@w_dfval,@w_fecha_cartera)

select @w_fecha_limite ,@w_fecha_cartera

select op_banco,op_operacion,op_fecha_ult_proceso,op_moneda,ab_oficina,ab_secuencial_ing, min(ab_fecha_pag) as fecha_pago, estado = 'A'
into #recaudos
from cob_cartera..ca_abono,
     cob_cartera..ca_abono_det,
     cob_cartera..ca_operacion,
     cob_cartera..ca_estado
where ab_estado       = 'ING'
and ab_fecha_ing      between @w_fecha_limite and  @w_fecha_cartera
and ab_operacion      = abd_operacion
and ab_secuencial_ing = abd_secuencial_ing
and op_operacion      = ab_operacion
and op_estado         = es_codigo
and es_procesa        = 'S'
group by op_banco,op_operacion,op_fecha_ult_proceso,op_moneda,ab_oficina,ab_secuencial_ing

while 1 = 1
begin
   set rowcount 1

   select
      @w_banco             = op_banco,
      @w_fecha_pag         = fecha_pago,
      @w_fecha_ult_proceso = op_fecha_ult_proceso,
      @w_op_moneda         = op_moneda,
      @w_ab_oficina        = ab_oficina,
      @w_operacionca       = op_operacion,
      @w_secuencial_ing    = ab_secuencial_ing
   from #recaudos
   where estado = 'A'
   order by op_banco, fecha_pago asc

   if @@rowcount = 0
   begin
      set rowcount 0
      break
   end

   set rowcount 0

   PRINT 'pag_masi.sp inicia --> BCO  :'  + cast (@w_banco as varchar) + ' OP: :'  + cast (@w_operacionca as varchar)

   if @w_fecha_ult_proceso  <> @w_fecha_pag  begin

      exec @w_return   = sp_fecha_valor
      @s_user          = 'sa',
      @i_fecha_valor   = @w_fecha_pag ,
      @s_term          = 'Terminal',
      @s_date          = @w_fecha_cartera,
      @i_banco         = @w_banco,
      @i_operacion     = 'F',
      @i_en_linea      = 'N',
      @i_control_fecha = 'N',
      @i_debug         = 'N'

      if @w_return <> 0 begin
         select @w_descripcion = 'Error ejecucion fecha valor retroceso, ABONOS MASIVOS'
         goto ERROR
      end
   end

   if @w_op_moneda = @w_moneda_nacional
   begin
       select @w_cotizacion_hoy = 1.0
   end
   else
   begin
       exec sp_buscar_cotizacion
       @i_moneda     = @w_op_moneda,
       @i_fecha      = @w_fecha_cartera,
       @o_cotizacion = @w_cotizacion_hoy output
    end

   ---APLICAION DEL PAGO
   exec @w_return = sp_abonos_batch
      @s_user          = 'sa',
      @s_term          = 'Terminal',
      @s_date          = @w_fecha_cartera,
      @s_ofi           = @w_ab_oficina,
      @i_en_linea      = 'N',
      @i_fecha_proceso = @w_fecha_cartera,
      @i_operacionca   = @w_operacionca,
      @i_banco         = @w_banco,
      @i_pry_pago      = 'N',
      @i_cotizacion    = @w_cotizacion_hoy,
      @i_secuencial_ing = @w_secuencial_ing

   if @w_return <> 0 begin
      PRINT 'Salio de pag_masi.sp  - sp_abonos_batch -> @w_return :'  + cast (@w_return as varchar)
      select @w_descripcion = 'Error ejecutando sp_abonos_batch'
      goto ERROR
   end

   ERROR:
      if @w_descripcion <> 'NO'
      begin
         PRINT 'pag_masi.sp ->  a error ' + cast(@w_return as varchar) +  ' Obligacion: ' + cast (@w_banco as varchar)
		   exec sp_errorlog
		   @i_fecha       = @w_fecha_cartera,
		   @i_error       = @w_return,
		   @i_usuario     = 'sa',
		   @i_tran        = 710600,
		   @i_tran_name   = @w_sp_name,
		   @i_cuenta      = @w_banco,
		   @i_descripcion = @w_descripcion,
		   @i_rollback    = 'S'

		   select @w_descripcion =  'NO'
      end

   update #recaudos
   set estado = 'V'
   where op_banco        = @w_banco
   and ab_secuencial_ing = @w_secuencial_ing
   and estado            = 'A'





end  ---while

set rowcount 0

--///////////////////////////////////////////////////////////
-- regresar a la fecha del sistema a las operaciones
select @w_operacionca = 0
while 1 = 1
begin
   set rowcount 1

   select
      @w_banco              = o.op_banco,
      @w_operacionca        = o.op_operacion,
      @w_new_fecha_ult_proc = o.op_fecha_ult_proceso
   from ca_operacion o, #recaudos
   where estado               = 'V' --- LOS PAGADOS
   and #recaudos.op_operacion = o.op_operacion
   and o.op_operacion         > @w_operacionca
   order by o.op_operacion

   if @@rowcount = 0
   begin
      set rowcount 0
      break
   end

   set rowcount 0

   PRINT 'pag_masi.sp regresando a fecha actual  BCO:'  + cast (@w_banco as varchar) + '   OP: '  + cast (@w_operacionca as varchar)

   ----EJECUTAR UNICAMENTE SI LA FECHA DE LA OPERACIONQUEDO ATRASADA
   if @w_new_fecha_ult_proc <> @w_fecha_cartera
   begin
	  exec @w_return   = sp_fecha_valor
	  @s_user          = 'sa',
	  @i_fecha_valor   = @w_fecha_cartera,
	  @s_term          = 'Terminal',
	  @s_date          = @w_fecha_cartera,
	  @i_banco         = @w_banco,
	  @i_operacion     = 'F',
	  @i_en_linea      = 'N',
	  @i_control_fecha = 'N',
	  @i_debug         = 'N'

	  if @w_return <> 0 begin
	      select @w_descripcion = 'Error ejecucion fecha valor hacia adelante, ABONOS MASIVOS'
		   exec sp_errorlog
		   @i_fecha       = @w_fecha_cartera,
		   @i_error       = @w_return,
		   @i_usuario     = 'sa',
		   @i_tran        = 710600,
		   @i_tran_name   = @w_sp_name,
		   @i_cuenta      = @w_banco,
		   @i_descripcion = @w_descripcion,
		   @i_rollback    = 'S'
	  end
   end
end -- while 1=1

set rowcount 0

return 0

go






