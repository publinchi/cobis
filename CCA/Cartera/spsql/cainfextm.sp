/************************************************************************/
/*Archivo               :    cainfextm.sp                               */
/*Stored procedure      :    sp_info_ext_mov                            */
/*Base de datos         :    cob_cartera                                */
/*Producto              :    Cartera                                    */
/*Disenado por          :    Sandra Lievano                             */
/*Fecha de escritura    :    Agosto 2 de 2007                           */
/************************************************************************/
/*                       IMPORTANTE                                     */
/*Este programa es parte de los paquetes bancarios propiedad de         */
/*'MACOSA'.                                                             */
/*Su uso no autorizado queda expresamente prohibido asi como            */
/*cualquier alteracion o agregado hecho por alguno de sus               */
/*usuarios sin el debido consentimiento por escrito de la               */
/*Presidencia Ejecutiva de MACOSA o su representante.                   */
/************************************************************************/
/*                       PROPOSITO                                      */
/* Generar informacion de los movimientos para el extracto de cartera   */ 
/*                                                                      */
/*                            MODIFICACIONES                            */
/*      FECHA             AUTOR                       RAZON             */
/*    02/08/2007          Sandra Lievano              Emision inicial   */
/************************************************************************/

use cob_cartera
go
-- /*
-- declare
-- @w_ret int
-- exec @w_ret = sp_insertar_error 723901, 0, 'Error Insertando detalle para credito rotativo'
-- go
-- --- FINSECCION:ERRORES no quitar esta seccion
-- */
-- 
if exists (select 1 from sysobjects where name = 'sp_info_ext_mov')
   drop proc sp_info_ext_mov
go

create proc sp_info_ext_mov
        @i_fecha_ini           datetime = null,
        @i_fecha_fin           datetime = null,
        @i_operacion           int = null,
        @i_modo                int = null


as
declare
   @w_sp_name                     descripcion,
   @w_error                       int,
   @w_obligacion                  cuenta,
   @w_obligacion_sin                  cuenta,
   @w_secuencial_tran             int,
   @w_secuencial_ref              int,
   @w_transaccion                 char(10),
   @w_concepto                    varchar(64),
   @w_capital                     money,
   @w_intereses                   money,
   @w_otros                       money,
   @w_cargos                      money,
   @w_abonos                      money,
   @w_estado                      char(10),
   @w_sec                         int,
   @w_total_transaccion           money,
   @w_tr_fecha_ref                datetime,
   @w_fecha_proceso               datetime,
   @w_producto                    tinyint,
   @w_contador                    tinyint



select @w_sec = 0


select @w_producto = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted 

select @w_fecha_proceso = fc_fecha_cierre 
from   cobis..ba_fecha_cierre
where  fc_producto = @w_producto

if @i_modo is null and (@i_operacion is null or @i_fecha_ini is null or @i_fecha_fin is null)
begin
  print 'Error en envio de parametros'
  return 1
end


if @i_modo is null
begin

declare movimientos cursor
   for select tr_banco, 
              tr_secuencial, 
              tr_secuencial_ref, 
              tr_tran, 
              tr_estado,
              tr_fecha_ref
   from ca_transaccion
   where tr_operacion = @i_operacion 
   and   tr_fecha_mov >= @i_fecha_ini
   and   tr_fecha_mov <= @i_fecha_fin
   and   tr_tran in ('DES', 'PAG', 'IOC')
   order by tr_secuencial

   for read only

open movimientos
      
fetch movimientos
into  @w_obligacion, 
      @w_secuencial_tran, 
      @w_secuencial_ref, 
      @w_transaccion, 
      @w_estado,
      @w_tr_fecha_ref

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin
   
   select @w_concepto           = '',
          @w_capital            = 0,
          @w_intereses          = 0,
          @w_otros              = 0,
          @w_cargos             = 0,
          @w_abonos             = 0,
          @w_total_transaccion  = 0
 
   select @w_sec = @w_sec + 1
   
   ---EL CONCEPTO ES LA DESCRIPCION DE LA TRANSACCION
   
   select @w_concepto = tt_descripcion
   from ca_tipo_trn
   where tt_codigo  = @w_transaccion
   
   if @w_estado = 'RV'
      select @w_concepto = 'REV'+ '_' + @w_concepto
 

   --VALORES  POR TRANSACCION y RUBRO DE TODAS LAS TRANSACCIONES

   -- CAPITAL
   select @w_capital = isnull(sum(dtr_monto_mn),0)
   from   ca_det_trn, 
          ca_concepto
   where dtr_operacion  = @i_operacion
   and   dtr_secuencial = @w_secuencial_tran
   and   dtr_concepto   = co_concepto
   and   co_categoria   = 'C'
   
   --CALCULO DE INTERESES
   select @w_intereses = isnull(sum(dtr_monto_mn),0)
   from   ca_det_trn, 
          ca_concepto
   where dtr_operacion  = @i_operacion
   and   dtr_secuencial = @w_secuencial_tran
   and   dtr_concepto   = co_concepto
   and   co_categoria   in ('I','M')
   
   --CALCULO DE OTROS 
   select @w_otros = isnull(sum(dtr_monto_mn),0)
   from   ca_det_trn, 
          ca_concepto
   where dtr_operacion  = @i_operacion
   and   dtr_secuencial = @w_secuencial_tran
   and   dtr_concepto   = co_concepto
   and   co_categoria  not in ('C','I','M')

  select @w_total_transaccion = @w_capital + @w_intereses + @w_otros

   
   -- INSERT EN LA TABLA SEGUN LA TRANSACCION Y EL ESTADO
   
   if @w_transaccion in ('DES','IOC') and @w_estado = 'RV'
   begin
     select  @w_capital   = @w_capital * -1,
             @w_intereses = @w_intereses * -1,
             @w_otros     = @w_otros * -1,
             @w_cargos    = @w_total_transaccion * -1,
             @w_abonos    = 0
   end
   
   if @w_transaccion in ('DES','IOC') and @w_estado <> 'RV'
   begin
        select @w_capital   = @w_capital,
               @w_intereses = @w_intereses,
               @w_otros     = @w_otros,
               @w_cargos    = @w_total_transaccion,
               @w_abonos    = 0      
   end

   if @w_transaccion = 'PAG' and @w_estado = 'RV'
      begin     
        select @w_capital   = @w_capital * -1,
               @w_intereses = @w_intereses * -1,
               @w_otros     = @w_otros * -1,
               @w_cargos    = 0,
               @w_abonos    = @w_total_transaccion * -1
      end
      
    if @w_transaccion = 'PAG' and @w_estado <> 'RV'         
       begin
         select @w_capital   = @w_capital,
                @w_intereses = @w_intereses,
                @w_otros     = @w_otros,
                @w_cargos    = 0,
                @w_abonos    = @w_total_transaccion      
        end

   
   insert into ca_mov_extracto
   values(2,                  @w_obligacion, @w_sec, 
          @w_secuencial_tran, @w_tr_fecha_ref,    @w_concepto, 
          @w_cargos,          @w_abonos,     @w_capital, 
          @w_intereses,       @w_otros  
         )
   
   if @@error <> 0 
   begin
     insert into ca_errorlog
            (er_fecha_proc,      er_error,      er_usuario,
             er_tran,            er_cuenta,     er_descripcion,
             er_anexo)
     values(@w_fecha_proceso,   723901,         'operador',
            7269,               @w_obligacion,   '',
            '') 
   end
  
             
   fetch movimientos
   into  @w_obligacion, 
         @w_secuencial_tran, 
         @w_secuencial_ref, 
         @w_transaccion, 
         @w_estado,
         @w_tr_fecha_ref
end

close movimientos
deallocate movimientos
end


if @i_modo = 0
begin


declare sin_detalle cursor
   for select ie_numero_obligacion
   from ca_info_extracto
   order by ie_numero_obligacion
   for read only

open sin_detalle
      
fetch sin_detalle
into  @w_obligacion_sin     

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin
  
   select @w_contador = 0



   set rowcount  1
   select @w_contador = 1
   from   ca_mov_extracto
   where  me_numero_obligacion = @w_obligacion_sin

   set rowcount  0

   if @w_contador = 0
   begin
   insert into ca_mov_extracto
   values(2,                  @w_obligacion_sin, null, 
          null, null,   'CREDITO NO PRESENTA MOVIMIENTOS PARA ESTE CORTE', 
          null,          null,     null, 
          null,      null 
         )
   
   if @@error <> 0 
   begin
     insert into ca_errorlog
            (er_fecha_proc,      er_error,      er_usuario,
             er_tran,            er_cuenta,     er_descripcion,
             er_anexo)
     values(@w_fecha_proceso,   723901,         'operador',
            7269,               @w_obligacion_sin,   '',
            '') 
   end
   end 

   fetch sin_detalle
   into  @w_obligacion_sin
end

close sin_detalle
deallocate sin_detalle

end   

return 0

go

                                                   