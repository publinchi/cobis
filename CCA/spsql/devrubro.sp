/************************************************************************/
/*  Archivo:            devrubro.sp                                     */
/*  Stored procedure:   sp_devolucion_comisiones                        */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:        Daniel Upegui                                  */
/*  Fecha de escritura: 19/Ago/2005                                     */
/************************************************************************/
/*  IMPORTANTE                                                          */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA", representantes exclusivos para el Ecuador de              */
/*  AT&T GIS  .                                                         */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*  PROPOSITO                                                           */
/*  Este programa realiza  lo siguiente:                                */
/*      Mantener la tabla ca_devolucion_rubro                           */
/************************************************************************/
/*  MODIFICACIONES                                                      */
/*  FECHA          AUTOR             RAZON                              */
/*  19-Ago-2005    Daniel Upegui      Emision Inicial                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_devolucion_comisiones')
   drop proc sp_devolucion_comisiones
go

create proc sp_devolucion_comisiones (
   @i_accion      char(1)     = null,
   @i_banco       cuenta      = null,
   @i_forma_pago  catalogo    = null,
   @i_referencia  varchar(24) = null,
   @i_concepto    catalogo    = null,
   @i_valor       money       = null 
)
as
declare
   @w_sp_name        varchar(64),
   @w_error          int,
   @w_operacion      int,
   @w_mensaje        varchar(255)

begin
   select @w_sp_name = 'sp_devolucion_comisiones'
   
   -- LEER EL CAMPO OP_OPERACION
   
   select @w_operacion = op_operacion
   from   ca_operacion
   where  op_banco = @i_banco
   and    op_estado in (1,2)
   
   if @@rowcount = 0
   begin
      print 'La obligación no existe o no tiene el estado adecuado ()'
      return 0
   end
   
   if @i_accion = 'I'
   begin
      if exists(select 1
                from   ca_devolucion_rubro
                where  dr_operacion = @w_operacion
                and    dr_concepto  = @i_concepto)
      begin
         print 'El concepto ,  ya fue devuelto a la obligación'+ @i_concepto+ @i_banco
         return 0
      end
      
      BEGIN TRAN
      
      insert into ca_devolucion_rubro
            (dr_operacion,    dr_forma_pago,   dr_referencia,
             dr_concepto,     dr_monto ,       dr_estado,
             dr_secuencial_tr)
      values(@w_operacion,    @i_forma_pago,   @i_referencia,
             @i_concepto,     @i_valor,        'ING',
             0)
      
      if @@error != 0
      begin
         select @w_error = 2103020
         goto ERROR
      end
      
      COMMIT TRAN
   end
   
   if @i_accion = 'D'
   begin
      delete ca_devolucion_rubro
      where  dr_operacion = @w_operacion
      and    dr_estado  =   'ING'
      
      if @@error != 0 
      begin
         select @w_error = 710003
         goto ERROR
      end 
   end
   
   return 0
ERROR:    
      exec cobis..sp_cerror             
      @t_from  = @w_sp_name, 
      @i_num   = @w_error
   return @w_error
end
go
