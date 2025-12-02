/************************************************************************/
/*   Archivo:             inscamcalif.sp                                */
/*   Stored procedure:    sp_ins_tabla_cambio_calif                     */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        John Jairo Rend¢n Ot lvaro                    */
/*   Fecha de escritura:  Abril 21 / 2005                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Iniciar la tabla cob_cartera..ca_cambio_calificacion      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR              CAMBIOS                   */
/*      ULT:ACT:21ABR2005  JOHN JAIRO RENDON  VERSION INICIAL           */
/*      DIC-16-2005        FQ                 Notomar las canceladas de */
/*                                            otros meses               */
/*      FEB-21-2006        EP                 compara calificacion de la*/
/*                                            tabla ca_oepracion_hc     */
/*      JUL282006          EPB                antes de carga la tabla   */
/*                                            lo que exista con la misma*/
/*                                            fecha se carga en         */
/*                                          ca_cambio_calificacion_repro*/
/*      OCT-2006           ELcira                def 7261               */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ins_tabla_cambio_calif')
   drop proc sp_ins_tabla_cambio_calif
go

create proc sp_ins_tabla_cambio_calif
as
begin
   set rowcount 0
   set nocount on
   declare
      @w_fecha_trc   datetime,
      @w_fecha_hc    datetime,
      @w_registros   int,
      @w_error       int

   update ca_operacion
   set    op_calificacion = 'A'
   where  op_calificacion is null
   and    op_estado not in (0,3,4,99,98,6) 

   select @w_registros = @@rowcount, @w_error = @@error
   
   if @w_error = 0
   begin
      print 'Se actualizaron registros en cob_cartera..ca_operacion: ' + cast(@w_registros as varchar)
   end
   ELSE
   begin
      print 'Error actualizando en cob_cartera..ca_operacion: ' +  cast(@w_error as varchar)
      return @w_error
   end        
   
   set rowcount 1
   select @w_fecha_trc = do_fecha
   from   cob_credito..cr_dato_operacion
   where  do_tipo_reg = 'M'
   and    do_codigo_producto = 7
   set rowcount 0
   select @w_fecha_hc = dateadd(dd, -1, dateadd(mm, 1, dateadd(dd, 1, dateadd(dd, -datepart(dd, @w_fecha_trc), @w_fecha_trc))))
   
   
   ---6322 Antes de cargar la tabla se copia los datos iguales a la fecha en una
   ---tabla de copia  
   insert into ca_cambio_calificacion_repro
   select cc_fecha,              cc_operacion, cc_calificacion_anterior,
          cc_calificacion_nueva, cc_estado_hc, cc_estado_con,
          cc_estado_trc,         cc_estado_mae,getdate()
   from   ca_cambio_calificacion
   where cc_fecha = @w_fecha_trc

   delete ca_cambio_calificacion
   where  cc_fecha = @w_fecha_trc


   insert into ca_cambio_calificacion
         (cc_fecha,              cc_operacion, cc_calificacion_anterior,
          cc_calificacion_nueva, cc_estado_hc, cc_estado_con,
          cc_estado_trc,         cc_estado_mae)
   select @w_fecha_trc,          co_operacion, co_calif_ant,
          co_calif_final,       'I',          'I',
          'I',                  'I'
   from   cob_cartera..ca_operacion_hc, --(index ca_operacion_hc_1),
          cob_credito..cr_calificacion_op--(index cr_calificacion_op_Key)            
   where  co_producto = 7
   and    co_operacion = oh_operacion
   and    isnull(oh_calificacion,'A') <> co_calif_final  --EP:FEB212006
   and    co_fecha = @w_fecha_trc
   and    oh_fecha = @w_fecha_hc
   and    oh_estado not in (0,4,99,98,6)   -- SE INCLUYE. LAS CANCELADAS
   
   select @w_registros = @@rowcount, @w_error = @@error
   
   if @w_error = 0
   begin
      print 'Se insertaron  registros en cob_cartera..ca_cambio_calificacion:  '  +  cast(@w_registros as varchar)
      return 0
   end
   ELSE
   begin
      print 'Error insertando en cob_cartera..ca_cambio_calificacion: '  + cast(@w_error as varchar)
      return @w_error
   end        
end
go
