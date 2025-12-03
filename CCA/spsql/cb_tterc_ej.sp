/************************************************************************/
/*      Archivo:                cb_tterc_ej.sp                            */
/*      Base de datos:          cob_conta                               */
/*      Producto: 	            Contabilidad                            */
/*      Fecha de escritura:     24/05/2017                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCORP", representantes exclusivos para el Ecuador de la    */
/*      "COBISCORP CORPORATION".                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Proceso de Transferencia de Terceros Contables. Genera el       */
/*      Proceso de Actualizacion de Terceros Contables generados        */
/*      de manera manual en el front end de Contabilidad                */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/************************************************************************/
use cob_conta
go

if object_id('sp_cb_tterc_ej') is not null
begin
  drop procedure sp_cb_tterc_ej
  if object_id('sp_cb_tterc_ej') is not null
  begin
    print 'FALLO BORRADO DE PROCEDIMIENTO sp_cb_tterc_ej'
  end
end
go
create proc sp_cb_tterc_ej(
  @t_show_version  bit         = 0,
  @i_param1       tinyint        , --empresa  
  -- parametros para registro del log de ejcucion
  @i_sarta         int         = null,
  @i_batch         int         = null,
  @i_secuencial    int         = null,
  @i_corrida       int         = null,
  @i_intento       int         = null
)
 as
  declare @w_error     int  

   exec @w_error = cob_conta..sp_trasterc
      @i_empresa   = @i_param1,
      @s_user     = 'sa'
   
   if @w_error <> 0
   begin
      print 'ERROR al momento de ejecutar cob_conta..sp_trasterc'         
      return @w_error
   end
   
return 0
go

