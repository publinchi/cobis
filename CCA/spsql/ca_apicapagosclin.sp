/************************************************************************/
/*   Archivo:            ca_ApicaPagosCLin.sp                           */
/*   Stored procedure:   sp_aplica_pag_camblinfinagro                     */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       Elcira Pelaez Burbano                          */
/*   Fecha de escritura: Enero.2015                                     */
/************************************************************************/
/*                       IMPORTANTE                                     */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                       PROPOSITO                                      */
/*   Aplicacion Pagos por Recuados                                      */
/************************************************************************/
/*                          MODIFICACIONES                              */
/*      FECHA     AUTOR        RAZON                                    */
/*  AGO.2015      Julian MC    ATSK-1060.                               */  
/*                             Se generan dos archivos para reportar los*/
/*                             Mensaje, uno para el usuario final y otro*/
/*                             para soporte tecnico.                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aplica_pag_camblinfinagro')
   drop proc sp_aplica_pag_camblinfinagro
go
---AGO.05.2015
create proc sp_aplica_pag_camblinfinagro
@i_param1   datetime
as declare 
   @w_banco              cuenta,
   @w_fecha_pag          datetime,
   @w_fecha_cartera      datetime,
   @w_sp_name            varchar(64),
   @w_msg                varchar(255),
   @w_error              int,
   @w_fecha_ult_proceso  datetime,
   @w_op_moneda          smallint,
   @w_cotizacion_hoy     money,
   @w_moneda_nacional    tinyint,
   @w_ab_oficina         int,
   @w_operacionca        int,
   @w_new_fecha_ult_proc datetime,
   @w_rowcount           int,
   @w_secuencial_ing     int,
   @w_usuario            login,
   @w_usuario1           login,
   @w_usuario2           login,      
   @w_term               catalogo,
   @w_fecha              datetime,
   @w_registros          int
   
-- FECHA DE PROCESO

select @w_sp_name     = 'sp_aplica_pag_camblinfinagro',
       @w_msg         = 'NO',
       @w_term        = 'BATCH_CCA',
       @w_fecha       = @i_param1

select @w_usuario1 = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'USLIFI'
and   pa_producto = 'CCA'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_msg = 'ERROR NO SE HA DEFINIDO USUARIO PARA NEMONICO [USLIFI]'
   select @w_error  = 708174
   goto ERROR
end

select @w_usuario2 = @w_usuario1 + '_USR'
select @w_usuario  = @w_usuario1
	   
-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_msg = 'ERROR NO HAY MONEDA NACIONAL DEFINIDA'   
   select @w_error  = 708174
   select @w_usuario  = @w_usuario2   
   goto ERROR
end

----SI NO HAY DATOS CARGADOS SIMPLEMENTE GENERE UN ERROR
if not exists ( select 1 from ca_proc_cam_linea_finagro)
begin
  select @w_msg = 'ca_apicapagosclin.sp --> NO SE HA CARGADO DATOS EN LA TABLA ca_proc_cam_linea_finagro'
  goto ERROR_FINAL
end

select @w_fecha_cartera = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

select op_banco,op_operacion,op_fecha_ult_proceso,op_moneda,ab_oficina,ab_secuencial_ing,min(ab_fecha_pag) as fecha_pago, estado = 'A'
into #recaudos
from cob_cartera..ca_abono, 
     cob_cartera..ca_abono_det, 
     cob_cartera..ca_operacion,
     cob_cartera..ca_estado,
     cob_cartera..ca_proc_cam_linea_finagro
where ab_estado       = 'ING'
and ab_fecha_ing      >= op_fecha_ini
and ab_operacion      = abd_operacion
and ab_secuencial_ing = abd_secuencial_ing
and op_operacion      = ab_operacion
and op_estado         = es_codigo
and es_procesa        = 'S'
and pc_banco_cobis    = op_banco
and pc_fecha_proc     = @w_fecha
and pc_estado         not in('E','P')
and pc_reverso_pagos  = '1' 
and pc_reverso_desem  = '1' 
and pc_retirar_gar    = '1'
and pc_cambio_linea   = '1'
and pc_desembolso     = '1'

group by op_banco,op_operacion,op_fecha_ult_proceso,op_moneda,ab_oficina,ab_secuencial_ing

select @w_registros = count(1)
from #recaudos

if @w_registros = 0
begin
    PRINT ''
    PRINT ''
    PRINT 'NO HAY PAGOS PENDIENTES DE APLICACION PARA OPERACINES DE cob_cartera..ca_proc_cam_linea_finagro'
    PRINT ''
    PRINT ''    
    ---VALIDAR SI TODO SE MARCA COMO PROCESADOS
    update ca_proc_cam_linea_finagro 
    set pc_estado = 'P'
    where pc_reverso_pagos  = '1'
    and   pc_reverso_desem  = '1'
    and   pc_retirar_gar    = '1'
    and   pc_cambio_linea   = '1'
    and   pc_desembolso     = '1'
    and   pc_aplica_pagos   = '1'
    and   pc_estado <> 'E'

      if @@error <> 0  
      begin
         PRINT 'ERROR ACTUALIZACION ca_proc_cam_linea_finagro estado P'
         return 1
      end        
    
    return 0
end

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
   order by op_banco

   if @@rowcount = 0 break
   
   set rowcount 0
   
   PRINT 'ca_ApicaPagosCLin.sp va operacion  :'  + cast (@w_banco as varchar)
   
   if @w_fecha_ult_proceso  <> @w_fecha_pag  begin
      
      exec @w_error    = sp_fecha_valor 
      @s_user          = @w_usuario,        
      @i_fecha_valor   = @w_fecha_pag ,
      @s_term          = @w_term, 
      @s_date          = @w_fecha_cartera,
      @i_banco         = @w_banco,
      @i_operacion     = 'F',
      @i_en_linea      = 'N',
      @i_control_fecha = 'N',
      @i_debug         = 'N'
   
      if @w_error  <> 0 begin
         select @w_msg = 'ERROR EJECUCION FECHA VALOR RETROCESO, ABONOS MASIVOS'
         goto ERROR      
      end   
   end   

     if @w_op_moneda = @w_moneda_nacional begin
         select @w_cotizacion_hoy = 1.0
      end else begin
         exec sp_buscar_cotizacion
         @i_moneda     = @w_op_moneda,
         @i_fecha      = @w_fecha_cartera,
         @o_cotizacion = @w_cotizacion_hoy output
      end
   
   ---APLICAION DEL PAGO
      exec @w_error  = sp_abonos_batch
      @s_user          = @w_usuario,
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
         
     if @w_error  <> 0 begin
         PRINT 'Salio de ca_ApicaPagosCLin.sp  @w_error  :'  + cast (@w_error  as varchar)
         select @w_msg = 'ERROR REALIZANDO ABONOS'
         goto ERROR      
      end   
   
   select @w_new_fecha_ult_proc = op_fecha_ult_proceso
   from ca_operacion
   where op_banco = @w_banco
   
   ----EJECUTAR UNICAMENTE SI LA FECHA DE LA OPERACIONQUEDO ATRASADA
   if @w_new_fecha_ult_proc <> @w_fecha_cartera begin
	  exec @w_error    = sp_fecha_valor 
	  @s_user          = @w_usuario,        
	  @i_fecha_valor   = @w_fecha_cartera,
	  @s_term          = 'Terminal', 
	  @s_date          = @w_fecha_cartera,
	  @i_banco         = @w_banco,
	  @i_operacion     = 'F',
	  @i_en_linea      = 'N',
	  @i_control_fecha = 'N',
	  @i_debug         = 'N'
	   
	  if @w_error  <> 0 begin
	      select @w_msg = 'ERROR EJECUTANDO FECHA VALOR EN APLICACION DE PAGOS'
	      goto ERROR
	  end
   end
   
   update ca_proc_cam_linea_finagro 
   set pc_aplica_pagos = '1',
       pc_estado       = 'I'
   where pc_banco_cobis =   @w_banco  
   
    if @@error <> 0  begin
      select @w_msg = 'ERROR ACTUALIZACION TABLA DE TRABAJO'
      goto ERROR
    end     
      
   ERROR:
      if @w_msg <> 'NO'
      begin
         if @w_error is null or @w_error = 0
            select @w_error = 710001
               
         PRINT 'ca_ApicaPagosCLin.sp ENTRO A ERROR ' + cast(@w_error  as varchar) +  ' Obligacion: ' + cast (@w_banco as varchar)
		   exec sp_errorlog 
		   @i_fecha       = @w_fecha,
		   @i_error       = @w_error ,
		   @i_usuario     = @w_usuario,
		   @i_tran        = 710600,
		   @i_tran_name   = @w_sp_name,
		   @i_cuenta      = @w_banco,
		   @i_descripcion = @w_msg,
		   @i_rollback    = 'N'
		   
           select @w_usuario  = @w_usuario1
           
		   update ca_proc_cam_linea_finagro 
         set pc_aplica_pagos = '0',
             pc_estado       = 'E'
         where pc_banco_cobis =   @w_banco 
         
         if @@error <> 0  
           PRINT 'ERROR ACTUALIZACION ca_proc_cam_linea_finagro en el  ERROR ' + cast (@w_banco as varchar)		   
		   select @w_msg =  'NO'
      end

   update #recaudos
   set estado = 'V'
   where op_banco = @w_banco
   and   ab_secuencial_ing  = @w_secuencial_ing
    if @@error <> 0 
       PRINT  'ERROR ACTUALIZACION TEmporal #recaudos ' + cast (@w_banco as varchar)
   

end  ---while

set rowcount 0
---VALIDAR SI TODO SE MARCA COMO PROCESADOS
update ca_proc_cam_linea_finagro 
set pc_estado = 'P'
where pc_reverso_pagos  = '1'
and   pc_reverso_desem  = '1'
and   pc_retirar_gar    = '1'
and   pc_cambio_linea   = '1'
and   pc_desembolso     = '1'
and   pc_aplica_pagos   = '1'
and   pc_estado <> 'E'

if @@error <> 0  
begin
   PRINT 'ERROR ACTUALIZACION ca_proc_cam_linea_finagro en el goto ERROR'
   return 1
end   
        
set rowcount 0

ERROR_FINAL:
  begin
      print cast(@w_msg as varchar(225))
      exec sp_errorlog 
      @i_fecha       = @w_fecha,
      @i_error       = 7999, 
      @i_tran        = null,
      @i_usuario     = @w_usuario, 
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = '',
      @i_rollback    = 'N',
      @i_descripcion = @w_msg ,
      @i_anexo       = @w_msg
      return 0
   end

return 0

go






