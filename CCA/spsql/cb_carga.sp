/************************************************************************/
/*      Archivo           :  cb_carga.sqr                               */
/*      Base de datos     :  cob_conta                                  */
/*      Producto          :  Contabilidad                               */
/*      Disenado por      :  Johanna Botero                             */
/*      Fecha de escritura:  Marzo 27 de 2003                           */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA", representantes exclusivos para el Ecuador de la       */
/*      "NCR CORPORATION".                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*     Carga de las tablas temporale cb_scomprobante_mig y              */
/*     cb_sasiento_mig a las tablas auxiliares.                         */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*      FECHA           AUTOR           RAZON                           */
/************************************************************************/
use cob_conta
go

if exists (select 1 from sysobjects where name = 'sp_cb_carga_ej')
   drop proc sp_cb_carga_ej
go

create proc sp_cb_carga_ej
(
  @t_show_version  bit         = 0,
  @i_param1       tinyint        , --empresa    
  -- parametros para registro del log de ejcucion
  @i_sarta         int         = null,
  @i_batch         int         = null,
  @i_secuencial    int         = null,
  @i_corrida       int         = null,
  @i_intento       int         = null
)
as declare @w_return int,
           @w_contador int,
           @w_archivo varchar(25),
           @w_conteo int,
           @w_cantidad int

exec @w_return = cob_conta..sp_paso_definitivas
   @i_empresa = @i_param1
   
   if @w_return <> 0
    return @w_return   

select @w_cantidad = count(1)
from cob_conta..cb_convivencia

if @w_cantidad = 0
begin
   print 'NO SE CARGO EL ARCHIVO APROPIADAMENTE'
   return 1
End

select
@w_conteo = count(1) 
from cob_conta..cb_erreres_batch
where eb_proceso = 'pasodef'

if @w_conteo > 0
   return 1
 else
  print 'EL ARCHIVO CONTIENE ERRORES. POR FAVOR VERIFIQUE EL LISTADO'

select @w_archivo = em_archivo    
from cob_conta..cb_estado_mig

select @w_contador = count(1)
from cob_conta..cb_control_carga
where cc_archivo = @w_archivo

if @w_contador = 0
begin
   print 'NO SE CARGO EL ARCHIVO CORRECTAMENTE, POR FAVOR VERIFIQUE (campos nulos en archivo)'
   return 1
End

return 0
go