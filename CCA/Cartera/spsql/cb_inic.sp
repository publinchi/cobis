/************************************************************************/
/*      Archivo           :  cb_inic.sqr                               */
/*      Base de datos     :  cob_conta                                  */
/*      Producto          :  Contabilidad                               */
/*      Disenado por      :                                             */
/*      Fecha de escritura:  18/Oct/94                                  */
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
/*      Proceso de inicio de corte                                      */
/*                                                                      */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*      FECHA           AUTOR           RAZON                           */
/*      08/Nov/94     G. Jaramillo      Emision Inicial                 */
/************************************************************************/


use cob_conta
go

if exists (select 1 from sysobjects where name = 'sp_cb_inici_ej')
   drop proc sp_cb_inici_ej
go

create proc sp_cb_inici_ej
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
as
declare @w_return int,
        @w_periodo int,
        @w_mes     int,
        @w_dia     int,
        @w_anio    int,
        @w_fecha_ini datetime,
        @w_fecha_definitiva varchar(10)
        

   Select 
   @w_periodo    = co_periodo,  
   @w_fecha_ini  = co_fecha_ini
   From cb_corte
   Where co_empresa = @i_param1
  and co_estado = 'A'
  
/*
  exec @w_return = cobis..sp_datepart
      @i_fecha = @w_fecha_ini,
      @o_mes = @w_mes out,
      @o_dia = @w_dia out
      
   if @w_return <> 0
      return @w_return
*/      
   select @w_anio = @w_periodo + 1
   select @w_fecha_definitiva = convert(varchar,@w_mes) + '/' + convert(varchar,@w_dia)
   
  if @w_fecha_definitiva = '12/31'
     begin
         if exists(Select 1
                  From cb_periodo
                  Where pe_empresa = @i_param1
                  and pe_periodo = @w_anio)
         begin
            exec @w_return = sp_inicorte
                  @t_trn		= 6282,
                  @i_operacion   = 'U',
                  @i_empresa	= @i_param1
                  
            if @w_return <> 0
               return @w_return
         end
     end
  else
     begin
         exec @w_return = sp_inicorte
                  @t_trn		= 6282,
                  @i_operacion   = 'U',
                  @i_empresa	= @i_param1
                  
            if @w_return <> 0
               return @w_return
     
     end
  
   truncate table cb_tcomprobante   
   truncate table  cb_tasiento
   truncate table cb_tinterna
   truncate table  cb_posicion
   
return 0
go
  
