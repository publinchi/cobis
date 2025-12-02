/************************************************************************/
/*   Archivo:             ca_cambioLfinagro.sp                          */
/*   Stored procedure:    sp_cambio_lfinagro                             */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez Burbano                         */
/*   Fecha de escritura:  Ene.2015                                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/************************************************************************/
/*   Este proceso hace un cambio de linea de la operacion               */
/*   AUTOR        FECHA        CAMBIO                                   */
/*   EPB          Enero.2015   Emision Inicial. NR 479 Bancamia         */
/*   Julian Mendi AGO.2015     ATSK-1060.                               */  
/*                             Se generan dos archivos para reportar los*/
/*                             Mensaje, uno para el usuario final y otro*/
/*                             para soporte tecnico.                    */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_cambio_lfinagro')
   drop proc sp_cambio_lfinagro
go

SET ANSI_NULLS ON
GO
---Jul.28.2015          
CREATE proc sp_cambio_lfinagro
  @i_param1   datetime
as declare              
   @w_usuario           login,
   @w_usuario1          login,
   @w_usuario2          login,      
   @w_term              catalogo,
   @w_error             int,
   @w_sp_name           varchar(64),
   @w_fecha             datetime,
   @w_sec_cons          int,
   @w_operacion         int,
   @w_banco             cuenta,
   @w_ofi               int,
   @w_fecha_cca         datetime,
   @w_msg               varchar(255),
   @w_linea_des         catalogo,
   @w_dt_naturaleza     char(1),
   @w_dt_tipo           char(1),
   @w_dt_tipo_linea     catalogo,
   @w_dt_subtipo_linea  catalogo

   
---USUARIO EXCLUSIVO PARA CAMBIO LINEA FINAGRO
select @w_usuario1 = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'USLIFI'
and   pa_producto = 'CCA'

select @w_usuario2 = @w_usuario1 + '_USR'
select @w_usuario  = @w_usuario1

select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select 
@w_sp_name           = 'sp_cambio_lfinagro',
@w_fecha             = @i_param1,
@w_term              = 'BATCH_CCA',
@w_ofi               = 1

----SI NO HAY DATOS CARGADOS SIMPLEMENTE GENERE UN ERROR
if not exists ( select 1 from ca_proc_cam_linea_finagro)
begin
  select @w_msg = 'ca_cambiolfinagro.sp --> NO SE HA CARGADO DATOS EN LA TABLA ca_proc_cam_linea_finagro'
  goto ERROR_FINAL
end

select op_operacion,
       op_banco,
       pc_linea_destino 
into #CambioLineaFinagro       
from ca_proc_cam_linea_finagro,
     ca_operacion
where   op_banco = pc_banco_cobis
and   pc_fecha_proc =   @w_fecha
and   pc_estado <> 'P'
and   pc_reverso_pagos = '1' 
and   pc_reverso_desem = '1' 
and   pc_retirar_gar   = '1'
and   pc_cambio_linea  = '0'
if @@rowcount = 0
begin
  PRINT ''
  PRINT 'ATENCION NO HAY OPERACIONES PARA PROCESAR CAMBIO DE LINEA'
  return 0
end
PRINT ''
PRINT 'OPERACIONES PARA EL CAMBIO DE LINEA'
select * from #CambioLineaFinagro

select @w_operacion = 0
while 1 = 1 
begin

      set rowcount 1

      select @w_operacion = op_operacion,
             @w_banco     = op_banco,
             @w_linea_des = pc_linea_destino
      from #CambioLineaFinagro
      where op_operacion > @w_operacion
      order by op_operacion

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0
      
      -- SELECCION DE LOS DATOS DE LA LINEA DE CREDITO DESTINO
      select 
      @w_dt_naturaleza    = dt_naturaleza, 
      @w_dt_tipo          = dt_tipo,       
      @w_dt_tipo_linea    = dt_tipo_linea, 
      @w_dt_subtipo_linea = dt_subtipo_linea 
      from ca_default_toperacion
      where dt_toperacion = @w_linea_des
      
      --- ACTUALIZACION DE LOS DATOS DE LA OPERACION
      
      update ca_operacion
      set
      op_toperacion         = @w_linea_des,
      op_tipo               = @w_dt_tipo,
      op_tipo_linea         = @w_dt_tipo_linea,
      op_subtipo_linea      = @w_dt_subtipo_linea,
      op_naturaleza         = @w_dt_naturaleza,
      op_codigo_externo     = null,
      op_margen_redescuento = 0
      where op_operacion = @w_operacion

      if @@error <> 0  begin
         select @w_msg = 'ERROR ACTUALIZANDO LA OPERACION: ' + CAST(  @w_banco AS VARCHAR)
         select @w_usuario = @w_usuario2         
         goto ERROR
       end
       
      --- ACTUALIZACION llAVE REDESCUENTO

      update cob_cartera..ca_val_oper_finagro
      set    vo_estado    = 'X'
      where  vo_operacion = @w_banco
      
      if @@error <> 0  begin
         select @w_msg = 'ERROR ACTUALIZANDO LA LLAVE: ' + CAST(  @w_banco AS VARCHAR)
         select @w_usuario = @w_usuario2                  
         goto ERROR
      end
            
   goto SIGUIENTE
   
   ERROR:
      begin
         print ''
         print ''
         print  @w_msg
         print ''
         print ''
         exec sp_errorlog 
         @i_fecha       = @w_fecha,
         @i_error       = @w_error,
         @i_usuario     = @w_usuario,
         @i_tran        = 7999,
         @i_tran_name   = @w_sp_name,
         @i_cuenta      = @w_banco,
         @i_descripcion = @w_msg,
         @i_rollback    = 'N'

         select @w_error = 0
         select @w_usuario = @w_usuario1
      
         update ca_proc_cam_linea_finagro  
         set pc_estado = 'E',
             pc_cambio_linea = '0'
         where pc_banco_cobis = @w_banco
         and   pc_fecha_proc = @w_fecha
         
         if @@error <> 0 
          begin
            select @w_msg = 'ERROR actaulizando  estado E en ca_proc_cam_linea_finagro: ' + CAST(  @w_banco AS VARCHAR)
            goto SALIR
          end         
         
         goto SALIR
      end
   SIGUIENTE:

      update ca_proc_cam_linea_finagro  
      set pc_cambio_linea = '1',
          pc_estado = 'I'
      where pc_banco_cobis = @w_banco
      and   pc_fecha_proc = @w_fecha
      
      if @@error <> 0 
       begin
         select @w_msg = 'ERROR ACTUALIZANDO  estado I  en ca_proc_cam_linea_finagro: ' + CAST(  @w_banco AS VARCHAR)
         goto SALIR
       end       
            
      
  SALIR:
  PRINT 'Va el Siguiente Registro para  Cambio de LINEA'
        
end

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
