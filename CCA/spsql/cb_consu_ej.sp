/************************************************************************/
/*      Archivo:                cb_consu_ej.sp                            */
/*      Base de datos:          cob_conta                               */
/*      Producto:		           Contabilidad                      	*/
/*      Disenado por:           Ignacio Yupa              */
/*      Fecha de escritura:	  24/05/2017                             */
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
/*      Este programa pasa los comprobantes y asientos de las tablas    */
/*      cb_scomprobante y cb_sasiento, a las tablas tanto temporales    */
/*      como definitivas de Contabilidad: cb_tcomprobante, cb_tasiento  */
/*      cb_comprobante y cb_asiento sumarizando por perfil.             */
/*      CONTABILIZACION AUTOMATICA OTROS MODULOS (SIN CONTABILIDAD)     */
/*      LOS COMPROBANTES                                                */
/*      RESUME LOS COMPROBANTES POR PERFIL                              */
/*      CODIGO DE PROGRAMA: 6084                                        */
/*	CODIGO DE PROGRAMA: 6084					*/
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      24/05/2017      Ignacio Yupa    Emision Inicial                 */
/************************************************************************/

use cob_conta
go

if object_id('sp_cb_consu_ej') is not null
begin
  drop procedure sp_cb_consu_ej
  if object_id('sp_cb_consu_ej') is not null
  begin
    print 'FALLO BORRADO DE PROCEDIMIENTO sp_cb_consu_ej'
  end
end
go
create proc sp_cb_consu_ej(
  @t_show_version  bit         = 0,
  @i_param1       tinyint        , --empresa
  @i_param2       datetime       , --fecha
  --@i_param3       descripcion    , --digitador
  @i_param3       tinyint        , --producto
  -- parametros para registro del log de ejcucion
  @i_sarta         int         = null,
  @i_batch         int         = null,
  @i_secuencial    int         = null,
  @i_corrida       int         = null,
  @i_intento       int         = null  
)
as
  declare  @w_error     int  

   exec @w_error = cob_conta..sp_valida_consu
      @i_empresa   = @i_param1,
      @i_fecha     = @i_param2,
      @i_digitador = 'sa',
      @i_producto  = @i_param3

   if @w_error <> 0
   begin        
      print 'ERROR al momento de ejecutar cob_conta..sp_valida_consu'   
      return @w_error
   end

return 0
go

