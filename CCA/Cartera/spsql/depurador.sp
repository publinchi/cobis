/************************************************************************/
/*      Archivo:                depurador.sp                            */
/*      Stored procedure:       sp_depurador                            */
/*      Base de datos:          cob_cartera_depuracion                  */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Marcelo Poveda, Hernan Redrovan         */
/*      Fecha de escritura:     Feb. 2002                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Inicia la depuracion de los historicos de la base de datos de   */ 
/*      cartera                                                         */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*     FECHA        AUTOR           RAZON                               */
/*   28/02/2002   H.Redrovan       Emision Inicial                      */ 
/*   09/AGO/2005  Elcira Pelaez    No manejar historia de la tabla de   */
/*                                 capitalizaziones ca_acciones         */
/************************************************************************/


/** NO SE USA EN ESTA VERSION */
--use cob_cartera_depuracion
--go

use cob_cartera
go


if exists(select 1 from sysobjects where name = 'sp_depurador')
   drop proc sp_depurador
go


create proc sp_depurador (
   
   @s_date              datetime     = null,
   @s_lsrv	     	varchar(30)  = null,
   @s_ofi               smallint     = null,
   @s_org		char(1)      = null,
   @s_rol		smallint     = null,
   @s_sesn              int          = null,
   @s_ssn               int          = null,
   @s_srv               varchar(30)  = null,
   @s_term              descripcion  = null,
   @s_user              login        = null,
   @t_rty               char(1)      = null,
   @t_debug          	char(1)      = 'N',
   @t_file         	varchar(14)  = null,
   @t_trn		smallint     = null,       
   @i_inicio            varchar(20),
   @i_fin               varchar(20),
   @i_usuario           varchar(15),
   @i_accion            char(1)
)

as 

declare 
   @w_operacion    int,
   @w_secuencial   int, 
   @w_tabla        varchar(50),
   @w_siguiente    int,
   @w_return       int,
   @w_registros    int

return 0

/* if @i_accion not in("T","H","t","h")
  begin
    print 'Tipo Estructura Invalida'
    return 1
  end

if @i_inicio > @i_fin 
 begin
    print 'Fecha Inicio no puede ser mayor a Fecha Fin'
    return 1
 end

dump tran cob_cartera_depuracion with truncate_only

begin tran datos_iniciales

    exec @w_return = cobis..sp_cseqnos 
      @i_tabla     = 'ca_siguiente',
      @o_siguiente = @w_siguiente out

 
    if @w_return <> 0 
     begin 
        rollback tran datos_iniciales
        print 'Error en la toma de numero de cobis..cl_seqnos'
        return 1
     end
    
    print 'Cargando accion_log...'


    insert into ca_accion_log(accion,   fecha,         usuario,
                             afectacion,tipo_depuracion)
    values(@w_siguiente, getdate(), @i_usuario,
          @i_accion,1)
    if @@error <> 0 
     begin 
        rollback tran datos_iniciales
        print 'Error en el registro de ca_accion_log'
        return 1
     end

     print 'Borrando depurador...'
     delete from ca_depurador 

     print 'Cargando depurador...'

     insert into ca_depurador
     select tr_operacion, tr_secuencial
        from cob_cartera..ca_transaccion
        where tr_fecha_mov between @i_inicio and @i_fin
        order by tr_operacion, tr_secuencial
     if @@error <> 0 
     begin 
        rollback tran datos_iniciales
        print 'Error en la Carga de datos al depurador'
        return 1
     end

    commit tran datos_iniciales

    /* Empieza proceso de depuracion propiamente dicho */

  declare depuracion cursor
  for select operacion, secuencial
      from ca_depurador
      order by operacion,secuencial
      for read only

    open depuracion
    fetch depuracion into
         @w_operacion,
         @w_secuencial

    begin tran depuracion_proceso
    while (@@fetch_status = 0) 
    begin
          if (@@fetch_status = -1)
           begin
              rollback tran depuracion_proceso
              print 'Error en Cursor'
              return 1
           end

          if @i_accion = 'T'
           begin         
                /* CA_TRANSACCION.  */
                select @w_tabla = 'ca_transaccion'

                select @w_registros = count(*)
                from cob_cartera..ca_transaccion
                where tr_operacion   = @w_operacion
                and   tr_secuencial  = @w_secuencial
 
                if @@error <> 0 
                begin
                   rollback tran depuracion_proceso
                   print 'Error en la Carga de datos de depuracion'
                   return 1
                end 
              
                insert into ca_transaccion
                select * from cob_cartera..ca_transaccion
                where tr_operacion   = @w_operacion
                and   tr_secuencial  = @w_secuencial

                if @@error <> 0 
                begin
                   rollback tran depuracion_proceso
                   print 'Error en la Carga de datos de depuracion'
                   return 1
                end

                delete from cob_cartera..ca_transaccion
                where tr_operacion   = @w_operacion
                and   tr_secuencial  = @w_secuencial
                if @@error <> 0 
                begin
                   rollback tran depuracion_proceso
                   print 'Error en la Carga de datos de depuracion'
                   return 1
                end
                               
               insert into ca_depurador_log
               values(@w_operacion,@w_secuencial,'S','S',@w_tabla,@w_registros,@w_siguiente)
                 
               if @@error <> 0 
                begin
                   rollback tran depuracion_proceso
                   print 'Error en la Carga de datos de depuracion'
                   return 1
                end
           
               /* CA_DET_TRN  */

               select @w_tabla = 'ca_det_trn'

               select @w_registros = count(*)
               from cob_cartera..ca_det_trn
               where dtr_operacion   = @w_operacion
               and   dtr_secuencial  = @w_secuencial

               if @@error <> 0 
                begin
                  rollback tran depuracion_proceso
                  print 'Error en la Carga de datos de depuracion'
                  return 1
                end
   
               insert into ca_det_trn
               select * from cob_cartera..ca_det_trn  
               where dtr_operacion   = @w_operacion
               and   dtr_secuencial  = @w_secuencial

                
               if @@error <> 0 
                begin
                  rollback tran depuracion_proceso
                  print 'Error en la Carga de datos de depuracion'
                  return 1
                end

               delete from cob_cartera..ca_det_trn  
               where dtr_operacion   = @w_operacion
               and   dtr_secuencial  = @w_secuencial
               if @@error <> 0 
                begin
                  rollback tran depuracion_proceso
                  print 'Error en la Carga de datos de depuracion'
                  return 1
                end

               insert into ca_depurador_log
               values(@w_operacion,@w_secuencial,'S','S',@w_tabla,@w_registros,@w_siguiente)
               if @@error <> 0 
                begin
                   rollback tran depuracion_proceso
                   print 'Error en la Carga de datos de depuracion'
                   return 1
                end
           end

          /* CA_OPERACION_HIS  */

          select @w_tabla = 'ca_operacion_his'

          select @w_registros = count(*)
          from cob_cartera..ca_operacion_his
          where oph_operacion   = @w_operacion
          and   oph_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_operacion_his
          select * from cob_cartera..ca_operacion_his  
          where oph_operacion   = @w_operacion
          and   oph_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_operacion_his  
          where oph_operacion   = @w_operacion
          and   oph_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log
          values(@w_operacion,@w_secuencial,'S','S',@w_tabla, @w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


          /* CA_RUBRO_OP_HIS */

          select @w_tabla = 'ca_rubro_op_his'

          select @w_registros = count(*)
          from cob_cartera..ca_rubro_op_his
          where roh_operacion   = @w_operacion
          and   roh_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_rubro_op_his
          select * from cob_cartera..ca_rubro_op_his  
          where roh_operacion   = @w_operacion
          and   roh_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_rubro_op_his  
          where roh_operacion   = @w_operacion
          and   roh_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log
          values(@w_operacion,@w_secuencial,'S','S',@w_tabla, @w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          /* CA_DIVIDENDO_HIS */

          select @w_tabla = 'ca_dividendo_his'

          select @w_registros = count(*)
          from cob_cartera..ca_dividendo_his
          where dih_operacion   = @w_operacion
          and   dih_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_dividendo_his
          select * from cob_cartera..ca_dividendo_his  
          where dih_operacion   = @w_operacion
          and   dih_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_dividendo_his  
          where dih_operacion   = @w_operacion
          and   dih_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log
          values(@w_operacion,@w_secuencial,'S','S',@w_tabla, @w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          /* CA_AMORTIZACION_HIS  */

          select @w_tabla = 'ca_amortizacion_his'

          select @w_registros = count(*)
          from cob_cartera..ca_amortizacion_his
          where amh_operacion   = @w_operacion
          and   amh_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_amortizacion_his
          select * from cob_cartera..ca_amortizacion_his  
          where amh_operacion   = @w_operacion
          and   amh_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_amortizacion_his  
          where amh_operacion   = @w_operacion
          and   amh_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log
          values(@w_operacion,@w_secuencial,'S','S',@w_tabla,@w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


          /* CA_AMORTIZACION_ANT_HIS */

          select @w_tabla = 'ca_amortizacion_ant_his'

          select @w_registros = count(*)
          from cob_cartera..ca_amortizacion_ant_his
          where anh_operacion   = @w_operacion
          and   anh_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_amortizacion_ant_his
          select * from cob_cartera..ca_amortizacion_ant_his  
          where anh_operacion   = @w_operacion
          and   anh_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_amortizacion_ant_his  
          where anh_operacion   = @w_operacion
          and   anh_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log
          values(@w_operacion,@w_secuencial,'S','S',@w_tabla, @w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          /* CA_RELACION_PTMO_HIS */

          select @w_tabla = 'ca_relacion_ptmo_his'

          select @w_registros = count(*)
          from cob_cartera..ca_relacion_ptmo_his
          where hpt_activa      = @w_operacion
          and   hpt_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_relacion_ptmo_his
          select * from cob_cartera..ca_relacion_ptmo_his  
          where hpt_activa      = @w_operacion
          and   hpt_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_relacion_ptmo_his  
          where hpt_activa      = @w_operacion
          and   hpt_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log
          values(@w_operacion,@w_secuencial,'S','S',@w_tabla, @w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


          /* CA_CUOTA_ADICIONAL_HIS */

          select @w_tabla = 'ca_cuota_adicional_his'

          select @w_registros = count(*)
          from cob_cartera..ca_cuota_adicional_his
          where cah_operacion   = @w_operacion
          and   cah_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_cuota_adicional_his
          select * from cob_cartera..ca_cuota_adicional_his  
          where cah_operacion   = @w_operacion
          and   cah_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_cuota_adicional_his  
          where cah_operacion   = @w_operacion
          and   cah_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          insert into ca_depurador_log
          values(@w_operacion,@w_secuencial,'S','S',@w_tabla, @w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


          select @w_tabla = 'ca_valores_his'

          select @w_registros = count(*)
          from cob_cartera..ca_valores_his
          where vah_operacion   = @w_operacion
          and   vah_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


          insert into ca_valores_his
          select * from cob_cartera..ca_valores_his  
          where vah_operacion   = @w_operacion
          and   vah_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

          delete from cob_cartera..ca_valores_his  
          where vah_operacion   = @w_operacion
          and   vah_secuencial  = @w_secuencial
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end


          insert into ca_depurador_log
          values(@w_operacion,@w_secuencial,'S','S',@w_tabla, @w_registros,@w_siguiente)
          if @@error <> 0 
           begin
              rollback tran depuracion_proceso
              print 'Error en la Carga de datos de depuracion'
              return 1
           end

        commit tran depuracion_proceso
        dump tran cob_cartera_depuracion with truncate_only 
      
        fetch depuracion into 
           @w_operacion,
           @w_secuencial
       
    end -- while

    close depuracion
    deallocate depuracion
    return 0 
*/

  
