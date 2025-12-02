
/************************************************************************/
/*      Archivo:                opcancel.sp                             */
/*      Stored procedure:       sp_operaciones_canceladas               */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Marcelo Poveda,Hernan Redrovan          */
/*      Fecha de escritura:     Marzo. 2002                             */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Inicia la depuracion de las operaciones canceladas de la base de*/ 
/*      datos cob_cartera                                               */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      06/03/2002      H.Redrovan       Emision Inicial                */ 
/*      01/Abr/2005     E.Pelaez         Actualizaciones para le BAC    */
/*      22/01/21        P.Narvaez        optimizado para mysql          */
/************************************************************************/

use cob_cartera_his
go

set ansi_nulls off
go

if exists(select 1 from sysobjects where name = 'sp_operaciones_canceladas')
   drop proc sp_operaciones_canceladas
go


create proc sp_operaciones_canceladas (
   @i_fecha_ini            datetime,
   @i_fecha_fin            datetime
    
)

as 

declare 
   @w_operacion    int,
   @w_tabla        varchar(50),
   @w_siguiente    int,
   @w_return       int,
   @w_registros    int,
   @w_cantidad_pasadas INT


if @i_fecha_ini > @i_fecha_fin 
 begin
    print 'Fechas Inicio no puede ser mayor a Fecha Fin'
    return 1
 end


begin tran datos_iniciales


        select @w_cantidad_pasadas = count(op_operacion)
        from cob_cartera..ca_operacion
        where op_fecha_ult_proceso between @i_fecha_ini and @i_fecha_fin
        and op_estado = 3  --Estado Cancelado
        

       insert into ca_control_dep_canceladas
       (cdc_fecha_depuracion,
        cdc_fecha_pini,
        cdc_fecha_pfin,
        cdc_contidad_dep)
       values
       (getdate(), 
        @i_fecha_ini,
        @i_fecha_fin, 
        @w_cantidad_pasadas)
   
       if @@error <> 0 
        begin 
           rollback tran datos_iniciales
           print 'Error insertando en ca_control_dep_canceladas'
           return 1
        end


     print 'Borrando depurador...'
     delete from ca_depurador
     where operacion >= 0 

     print 'Cargando depurador...'
     insert into ca_depurador(operacion)
     select op_operacion
        from cob_cartera..ca_operacion
        where op_fecha_ult_proceso between @i_fecha_ini and @i_fecha_fin
        and op_estado = 3  --Estado Cancelado
        order by op_operacion
     if @@error <> 0 
     begin 
        rollback tran datos_iniciales
        print 'Error en la Carga de datos al depurador'
        return 1
     end

commit tran datos_iniciales

 -- Empieza proceso de depuracion propiamente dicho

  declare depuracion cursor
  for select operacion
      from ca_depurador
      order by operacion

  
    open depuracion
    fetch depuracion into
         @w_operacion

begin tran depuracion_proceso

    while (@@fetch_status = 0) 
     begin
          if (@@fetch_status = -1)
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

               -- CA_TRANSACCION.  sp_help ca_transaccion
             

                insert into cob_cartera_his..ca_transaccion
                select * from cob_cartera..ca_transaccion
                where tr_secuencial >= -10000000
                and tr_operacion = @w_operacion
                if @@error <> 0 
                begin
                   rollback tran depuracion_proceso
                   print 'Error en la Carga de datos de depuracion'
                   return 1
                end

                delete from cob_cartera..ca_transaccion
                where tr_secuencial >= -10000000
                and tr_operacion = @w_operacion
                if @@error <> 0 
                begin
                   rollback tran depuracion_proceso
                   print 'Error en la Carga de datos de depuracion'
                   return 1
                end

               insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
               values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
               if @@error <> 0 
                begin
                   rollback tran depuracion_proceso
                   print 'Error en la Carga de datos de depuracion'
                   return 1
                end


           
               -- CA_DET_TRN  sp_help ca_det_trn

               select @w_tabla = 'ca_det_trn'

               select @w_registros = count(*)
               from cob_cartera..ca_det_trn
               where dtr_secuencial   >= -10000000
               and   dtr_operacion    = @w_operacion
               if @@error <> 0 
                begin
                  rollback tran depuracion_proceso
                  print 'Error en la Carga de datos de depuracion'
                  return 1
                end
   
               insert into cob_cartera_his..ca_det_trn
               select * from cob_cartera..ca_det_trn  
               where dtr_secuencial   >= -10000000
               and   dtr_operacion    = @w_operacion

               if @@error <> 0 
                begin
                  rollback tran depuracion_proceso
                  print 'Error en la Carga de datos de depuracion'
                  return 1
                end

               delete from cob_cartera..ca_det_trn  
               where dtr_secuencial   >= -10000000
               and   dtr_operacion    = @w_operacion

               if @@error <> 0 
                begin
                  rollback tran depuracion_proceso
                  print 'Error en la Carga de datos de depuracion'
                  return 1
                end

               insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
               values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
               if @@error <> 0 
                begin
                   rollback tran depuracion_proceso
                   print 'Error en la Carga de datos de depuracion'
                   return 1
                end



        -- CA_OPERACION   sp_help ca_operacion

          select @w_tabla = 'ca_operacion'

          select @w_registros = count(*)
          from cob_cartera..ca_operacion
          where op_operacion   = @w_operacion     
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_operacion
          select * from cob_cartera..ca_operacion  
          where op_operacion   = @w_operacion     
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_operacion  
          where op_operacion   = @w_operacion     
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


        -- CA_AMORTIZACION sp_help ca_amortizacion

          select @w_tabla = 'ca_amortizacion'

          select @w_registros = count(*)
          from cob_cartera..ca_amortizacion
          where am_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_amortizacion
          select * from cob_cartera..ca_amortizacion  
          where am_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_amortizacion  
          where am_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end



        -- CA_RUBRO_OP  sp_help ca_rubro_op

          select @w_tabla = 'ca_rubro_op'

          select @w_registros = count(*)
          from cob_cartera..ca_rubro_op
          where ro_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_rubro_op
          select * from cob_cartera..ca_rubro_op  
          where ro_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_rubro_op  
          where ro_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


        -- CA_DIVIDENDO  sp_help ca_dividendo

          select @w_tabla = 'ca_dividendo'

          select @w_registros = count(*)
          from cob_cartera..ca_dividendo
          where di_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_dividendo
          select * from cob_cartera..ca_dividendo  
          where di_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_dividendo  
          where di_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


        -- CA_TASAS  sp_help ca_tasas

          select @w_tabla = 'ca_tasas'

          select @w_registros = count(*)
          from cob_cartera..ca_tasas
          where ts_operacion   = @w_operacion
          and ts_secuencial >= -10000000
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_tasas
          select * from cob_cartera..ca_tasas
          where ts_operacion   = @w_operacion
          and ts_secuencial >= -10000000
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_tasas
          where ts_operacion   = @w_operacion
          and ts_secuencial >= -10000000
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end



        -- CA_REAJUSTE  sp_help ca_reajuste

          select @w_tabla = 'ca_reajuste'

          select @w_registros = count(*)
          from cob_cartera..ca_reajuste
          where re_secuencial   >= -10000000
          and   re_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_reajuste
          select * from cob_cartera..ca_reajuste
          where re_secuencial   >= -10000000
          and   re_operacion   = @w_operacion

          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_reajuste
          where re_secuencial   >= -10000000
          and   re_operacion   = @w_operacion

          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end



        -- CA_REAJUSTE_DET  sp_help ca_reajuste_det

          select @w_tabla = 'ca_reajuste_det'

          select @w_registros = count(*)
          from cob_cartera..ca_reajuste_det
          where red_secuencial   >= -10000000
          and   red_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_reajuste_det
          select * from cob_cartera..ca_reajuste_det
          where red_secuencial   >= -10000000
          and   red_operacion   = @w_operacion

          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_reajuste_det
          where red_secuencial   >= -10000000
          and   red_operacion   = @w_operacion

          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


    

        -- CA_AMORTIZACION_ANT  sp_help ca_amortizacion_ant

          select @w_tabla = 'ca_amortizacion_ant'

          select @w_registros = count(*)
          from cob_cartera..ca_amortizacion_ant
          where an_secuencial   >= -10000000
          and   an_operacion    = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_amortizacion_ant
          select * from cob_cartera..ca_amortizacion_ant  
          where an_secuencial   >= -10000000
          and   an_operacion    = @w_operacion

          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_amortizacion_ant  
          where an_secuencial   >= -10000000
          and   an_operacion    = @w_operacion

          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


        -- CA_RELACION_PTMO  sp_help ca_relacion_ptmo

          select @w_tabla = 'ca_relacion_ptmo'

          select @w_registros = count(*)
          from cob_cartera..ca_relacion_ptmo
          where rp_activa      = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_relacion_ptmo
          select * from cob_cartera..ca_relacion_ptmo
          where rp_activa      = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_relacion_ptmo
          where rp_activa      = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


        -- CA_VALORES  sp_help ca_valores

          select @w_tabla = 'ca_valores'

          select @w_registros = count(*)
          from cob_cartera..ca_valores
          where va_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end 

         insert into cob_cartera_his..ca_valores
          select * from cob_cartera..ca_valores  
          where va_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_valores  
          where va_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end



        -- CA_ACCIONES  sp_help ca_acciones

          select @w_tabla = 'ca_acciones'

          select @w_registros = count(*)
          from cob_cartera..ca_acciones
          where ac_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_acciones
          select * from cob_cartera..ca_acciones  
          where ac_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_acciones  
          where ac_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end



        -- CA_CUOTA_ADICIONAL sp_help ca_cuota_adicional

          select @w_tabla = 'ca_cuota_adicional'

          select @w_registros = count(*)
          from cob_cartera..ca_cuota_adicional
          where ca_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_cuota_adicional
          select * from cob_cartera..ca_cuota_adicional
          where ca_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_cuota_adicional
          where ca_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end



        -- CA_ABONO  sp_help ca_abono

          select @w_tabla = 'ca_abono'

          select @w_registros = count(*)
          from cob_cartera..ca_abono
          where ab_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_abono
          select * from cob_cartera..ca_abono
          where ab_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_abono
          where ab_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


        -- CA_ABONO_DET   sp_help ca_abono_det

          select @w_tabla = 'ca_abono_det'

          select @w_registros = count(*)
          from cob_cartera..ca_abono_det
          where abd_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_abono_det
          select abd_secuencial_ing,
				abd_operacion,
				abd_tipo,
				abd_concepto,
				abd_cuenta,
				abd_beneficiario,
				abd_moneda,
				abd_monto_mpg,
				abd_monto_mop,
				abd_monto_mn,
				abd_cotizacion_mpg,
				abd_cotizacion_mop,
				abd_tcotizacion_mpg,
				abd_tcotizacion_mop,
				abd_cheque,
				abd_cod_banco,
				abd_inscripcion,
				abd_carga,
				abd_porcentaje_con,
				abd_secuencial_interfaces,
				abd_solidario,
				abd_descripcion,
				abd_sec_reverso_bancos
          from cob_cartera..ca_abono_det
          where abd_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_abono_det
          where abd_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

/*
        -- CA_TASAS_PIT   cob_cartera..sp_help ca_tasas_pit

          select @w_tabla = 'ca_tasas_pit'

          select @w_registros = count(*)
          from cob_cartera..ca_tasas_pit
          where tp_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_tasas_pit
          select * from cob_cartera..ca_tasas_pit
          where tp_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_tasas_pit
          where tp_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


        -- CA_DESEMBOLSO   cob_cartera..sp_help ca_desembolso

          select @w_tabla = 'ca_desembolso'

          select @w_registros = count(*)
          from cob_cartera..ca_desembolso
          where dm_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into cob_cartera_his..ca_abono_det
          select * from cob_cartera..ca_desembolso
          where dm_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_desembolso
          where dm_operacion   = @w_operacion
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log(operacion,copiado,eliminado,tabla,registros,referencia_accion)
          values(@w_operacion,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

*/

commit tran depuracion_proceso
--dump tran cob_cartera_his with truncate_only
      
      
       fetch depuracion into 
           @w_operacion

       
     end -- while

 
    close depuracion
    deallocate depuracion
    return 0

