/************************************************************************/
/*   Archivo:             tmptran.sp                                    */
/*   Stored procedure:    sp_tmp_transaccion                            */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        Fabian Quintero                               */
/*   Fecha de escritura:  2004                                          */
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
/*   Preasigna el Numero de comprobante a las transacciones que se      */
/*   van a contabilizar                                                 */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'ca_operacion_proceso')
   drop table ca_operacion_proceso
go

/* FQ MEJORA FUTURA
create table ca_operacion_proceso
(
  op_operacion          int      not null,
  op_estado             tinyint  not null,
  op_fecha_ult_mov      datetime not null,
  op_fecha_ult_proceso  datetime not null,
  op_naturaleza         char(1)  not null,
  op_banco              cuenta   not null,
  op_validacion         catalogo not null,
  op_proceso_saldoshc   char(1)  not null,
  op_proceso_cacontac   char(1)  not null,
  op_proceso_datconso   char(1)  not null,
  op_proceso_maestro    char(1)  not null,
  op_proceso_findia     char(1)  not null
)
--lock datarows
*/
go
-----
if exists(select 1 from sysobjects where name = 'ca_tmp_transaccion')
   drop table ca_tmp_transaccion
go
create table ca_tmp_transaccion
(
  ttr_operacion   int not null,
  ttr_secuencial  int not null,
  ttr_fecha_mov   datetime not null,
  ttr_comprobante int not null
)
--lock datarows
--go

create unique clustered index ca_tmp_transaccion_1 on ca_tmp_transaccion(ttr_operacion, ttr_secuencial)
go

--sp_chgattribute ca_tmp_transaccion, "concurrency_opt_threshold", -1
--go

if exists(select 1 from sysobjects where name = 'sp_tmp_transaccion')
   drop proc sp_tmp_transaccion
go

-- FQ EN 12.5 LA TABLA DEBE ESTAR CREADA ANTES DE COMPILAR
/*
create table #tmp_fecha (tr_fecha_mov datetime not null, tr_numero int not null, tr_inicial int not null, tr_fecha_orig datetime not null)
*/

create proc sp_tmp_transaccion
@i_filial          tinyint,
@i_fecha_proc      datetime,
@i_causacion       char(1)  = 'N',
@i_reproceso       char(1)  = 'N',
@i_fecha_reproceso datetime = null,
@i_debug           char(1)  = 'N',
@i_opcion          char(1)  = 'T'
as
declare
   @w_error             int,
   @w_tr_operacion      int,
   @w_tr_secuencial     int,
   @w_tr_fecha_mov      datetime,
   @w_ttr_comprobante   int,
   @w_anexo             varchar(255),
   @w_ult_fecha         datetime,
   @w_cont_tran         int,
   @w_tr_numero         int,
   @w_tr_inicial        int,
   @w_registros_proc    int,
   @w_registros_oper    int,
   @w_intentos          int,
   
   @w_fecha_cerrada     datetime,
   @w_fecha_contable    datetime,
   @w_duplicaciones     int,
   @w_rc                int,
   @w_rep_fecha         datetime,
   @w_rep_comprobante   int,
   @w_rep_numero        int,
   @w_max_cbt_generado  int,
   
   @w_rep_operacion     int,
   @w_rep_secuencial    int,
   @w_primera_fecha_a   datetime
begin
   /* FQ MEJORA FUTURA
   if @i_opcion = 'O'
   begin
      select @w_registros_oper = -1,
             @w_intentos = 0
      
      select @w_registros_oper = count(1)
      from   ca_operacion
      
      --alter table ca_operacion_proceso unpartition
      
      drop index ca_operacion_proceso.ca_operacion_proceso_1
      
      while @w_registros_oper != @w_registros_proc and @w_intentos < 3
      begin
         select @w_intentos = @w_intentos + 1
         truncate table ca_operacion_proceso
         
         BEGIN TRAN
         insert into ca_operacion_proceso
               (op_operacion,          op_estado,           op_fecha_ult_mov,
                op_fecha_ult_proceso,
                op_naturaleza,
                op_banco,
                op_validacion,
                op_proceso_saldoshc,   op_proceso_cacontac, op_proceso_datconso, 
                op_proceso_maestro,    op_proceso_findia)
         select op_operacion,          op_estado,           isnull(op_fecha_ult_mov, 'jan 1 1971'),
                op_fecha_ult_proceso,
                isnull(op_naturaleza, 'A'),
                op_banco,
                isnull(op_validacion, 'NULO'),
                'N',                   'N',                 'N',
                'N',                   'N'
         from   ca_operacion
         COMMIT
         
         select @w_registros_proc = count(1)
         from   ca_operacion_proceso
      end
      
      --alter table ca_operacion_proceso partition 100
      
      create unique nonclustered index ca_operacion_proceso_1 on ca_operacion_proceso(op_operacion)
      
      --exec sp_recompile ca_operacion_proceso
      
      if @w_intentos = 3 and @w_registros_oper != @w_registros_proc
         raiserror 99999 "NO SE PUDO INGRESAR LOS REGISTROS A LA TABLA DE CONTROL"
      
      return 0
   end
   */
   BEGIN TRAN
   update ca_transaccion
   set    tr_estado = 'NCO'
   from   ca_transaccion, ca_tipo_trn
   where  tr_fecha_mov      <= @i_fecha_proc
   and    tr_estado          = 'ING'
   and    tr_tran           != 'PRV'
   and    tr_tran           != 'REV'
   and    tt_codigo          = tr_tran
   and    tt_contable        = 'N'
   and    tr_ofi_usu         > -1
   COMMIT
   
   BEGIN TRAN
   update ca_transaccion
   set    tr_estado = 'NCO'
   from   ca_transaccion, ca_tipo_trn
   where  tr_fecha_mov      <= @i_fecha_proc
   and    tr_estado          = 'ING'
   and    tt_codigo          = tr_tran
   and    tt_contable        = 'N'
   and    tr_ofi_usu         > -1
   COMMIT
   
   if @i_reproceso = 'S'
   begin
      BEGIN TRAN
      update ca_transaccion
      set    tr_estado = 'ING'
      where  tr_estado = 'PVA'
      COMMIT
      
      BEGIN TRAN
      delete cob_conta_tercero..ct_scomprobante_tmp
      where sc_fecha_tran >= @i_fecha_reproceso
      and   sc_producto = 7
      COMMIT
      
      BEGIN TRAN
      delete cob_conta_tercero..ct_sasiento_tmp
      where  sa_fecha_tran >= @i_fecha_reproceso
      and    sa_producto = 7
      COMMIT
   end

   select @w_ult_fecha = '01/01/1971',
          @w_ttr_comprobante = 0,
          @w_cont_tran       = 0
   
   -- NUEVO ESQUEMA
   -- PRIMERO SE INSERTA EN ca_tmp_transaccion TODAS LAS TRANSACCIONES QUE SE VAN A PROCESAR
   drop index ca_tmp_transaccion.ca_tmp_transaccion_1
   
   truncate table ca_tmp_transaccion
   
   if @i_causacion = 'N'
   begin
      insert into ca_tmp_transaccion
            (ttr_operacion,   ttr_secuencial, ttr_fecha_mov,
             ttr_comprobante)
      select tr_operacion,    tr_secuencial,  tr_fecha_mov,
             -1
      from   ca_transaccion
      where  tr_estado = 'ING'
      and    tr_fecha_mov  <= @i_fecha_proc
      and    tr_tran  not in ('PRV','CMO')
   end
   
   if @i_causacion = 'S'
   begin
      insert into ca_tmp_transaccion
            (ttr_operacion,   ttr_secuencial, ttr_fecha_mov,
             ttr_comprobante)
      select tr_operacion,    tr_secuencial,  tr_fecha_mov,
             -1
      from   ca_transaccion
      where  tr_estado = 'ING'
      and    tr_fecha_mov  <= @i_fecha_proc
   end
   
   if @i_causacion = 'T'
   begin
      insert into ca_tmp_transaccion
            (ttr_operacion,   ttr_secuencial, ttr_fecha_mov,
             ttr_comprobante)
      select tr_operacion,    tr_secuencial,  tr_fecha_mov,
             -1
      from   ca_transaccion
      where  tr_estado = 'ING'
      and    tr_fecha_mov  = @i_fecha_proc
      and    tr_tran       = 'TRC'
   end
   
   create unique clustered index ca_tmp_transaccion_1 on ca_tmp_transaccion(ttr_operacion, ttr_secuencial)
   
   -- SE BUSCA LA PRIMERA FECHA ABIERTA
   select @w_primera_fecha_a = null
   
   select @w_primera_fecha_a = min(co_fecha_ini)
   from   cob_conta..cb_corte
   where  co_empresa = 1
   and    co_estado in ('A', 'V')
   
   print 'primera fecha_abierta '+ cast(@w_primera_fecha_a as varchar)
   
   if @w_primera_fecha_a is not null
   begin
      -- SE ACTUALIZAN TODAS LAS FECHAS VIEJAS A LA PRIMERA FECHA ABIERTA
      BEGIN TRAN
      update ca_tmp_transaccion
      set    ttr_fecha_mov = @w_primera_fecha_a
      where  ttr_fecha_mov < @w_primera_fecha_a
      print 'actualización a primera fecha_abierta' + cast(@@rowcount as varchar)
      COMMIT
      
      -- SE ACTUALIZAN LAS DEMAS FECHAS SI TODAVIA EXISTIERAN FECHAS ERRADAS
      BEGIN TRAN
      update ca_tmp_transaccion
      set    ttr_fecha_mov = @w_primera_fecha_a
      from   ca_tmp_transaccion t
      where  not exists(select 1
                        from   cob_conta..cb_corte--(index cb_corte_Key_fecha)
                        where  co_fecha_ini = t.ttr_fecha_mov
                        and    co_estado in ('A', 'V')
                       )
      print 'segunda actualizacion a primera fecha_abierta' + cast(@@rowcount as varchar)
      COMMIT
   end
   -- HASTA AQUI TODAS LAS TRANSACCIONES TIENEN UNA FECHA ABIERTA ASIGNADA
   
   -- AHORA SE CORRE UN CURSOR PARA ASEGURAR LOS SECUENCIALES EN EL TOPE MAXIMO
   declare
      cur_ttr_fechas cursor
      for select distinct ttr_fecha_mov
          from ca_tmp_transaccion
      for read only
   
   open cur_ttr_fechas
   
   fetch cur_ttr_fechas
   into  @w_primera_fecha_a
   
   --while @@fetch_status not in (-1,0)

   while @@fetch_status = 0
   begin
      print 'procesando fecha' + cast(@w_primera_fecha_a as varchar)
      -- CON ESTO SE ASEGURA QUE VA A HABER REGISTRO DE FECHA
      BEGIN TRAN
      exec @w_error = cob_conta..sp_cseqcomp
           @i_tabla      = 'cb_scomprobante',
           @i_empresa    = @i_filial,
           @i_fecha      = @w_primera_fecha_a,
           @i_modulo     = 7,
           @i_modo       = 0, 
           @o_siguiente  = @w_max_cbt_generado out
      COMMIT
      
      -- SE BUSCA EL MAXIMO DE LA FECHA
      select @w_max_cbt_generado = isnull(max(sc_comprobante), 0)
      from   cob_conta_tercero..ct_scomprobante--(index ct_scomprobante_Key)
      where  sc_fecha_tran = @w_primera_fecha_a
      and    sc_producto = 7
      
      print 'maximo de fecha  -> ' + cast(@w_primera_fecha_a as varchar) + cast(@w_max_cbt_generado as varchar)
      
      -- EL REGISTRO DE LA FECHA SE ACTUALIZA AL MAXIMO
      select @w_max_cbt_generado = @w_max_cbt_generado + 1000
      BEGIN TRAN
      update cob_conta..cb_seqnos_comprobante
      set    sc_actual = @w_max_cbt_generado
      where  sc_fecha = @w_rep_fecha
      and    sc_modulo = 7
      and    sc_tabla  = 'cb_scomprobante'
      COMMIT
      
      print 'actualiza la fecha fecha  -> ' + cast(@w_primera_fecha_a as varchar) + ' ' + cast(@w_max_cbt_generado as varchar)
      -- AHORA SE HACE UN RECORRIDO SOBRE LAS TRANSACCIONES PARA ASIGNAR LOS COMPROBANTES
      declare
         cur_cbte cursor
         for select ttr_operacion, ttr_secuencial
             from   ca_tmp_transaccion
             where  ttr_fecha_mov = @w_primera_fecha_a
      
      open cur_cbte
      
      fetch cur_cbte
      into  @w_tr_operacion, @w_tr_secuencial
      
      -- ASIGNAR LOS COMPROBANTES
      BEGIN TRAN
      while @@fetch_status = 0
      begin
         select @w_max_cbt_generado = @w_max_cbt_generado + 1
         
         update ca_tmp_transaccion
         set    ttr_comprobante = @w_max_cbt_generado
         from   ca_tmp_transaccion
         where  ttr_operacion = @w_tr_operacion
         and    ttr_secuencial = @w_tr_secuencial
         
         fetch cur_cbte
         into  @w_tr_operacion, @w_tr_secuencial
      end
      COMMIT
      
      print 'se asigno hasta la fecha  ->'+ cast(@w_primera_fecha_a as varchar) + cast(@w_max_cbt_generado as varchar)
      
      -- ACTUALIZAR LA TABLA DE SECUENCIALES
      select @w_max_cbt_generado = @w_max_cbt_generado + 1000
      BEGIN TRAN
      update cob_conta..cb_seqnos_comprobante
      set    sc_actual = @w_max_cbt_generado
      where  sc_fecha = @w_rep_fecha
      and    sc_modulo = 7
      and    sc_tabla  = 'cb_scomprobante'
      COMMIT
      print 'comprobante final para la fecha  ->' + cast(@w_primera_fecha_a as varchar) + cast(@w_max_cbt_generado as varchar)
      
      close cur_cbte
      deallocate cur_cbte
      
      fetch cur_ttr_fechas
      into  @w_primera_fecha_a
   end
   
   close cur_ttr_fechas
   deallocate cur_ttr_fechas
   
   declare
      cur_repeticiones cursor
      for select ttr_fecha_mov, ttr_comprobante, count(1)
          from ca_tmp_transaccion
          group by ttr_fecha_mov, ttr_comprobante
          having count(1) >1
      for read only
   
   open cur_repeticiones
   
   fetch cur_repeticiones
   into  @w_rep_fecha,  @w_rep_comprobante,  @w_rep_numero
   
   --while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin
      BEGIN TRAN
      exec @w_error = cob_conta..sp_cseqcomp
           @i_tabla      = 'cb_scomprobante',
           @i_empresa    = @i_filial,
           @i_fecha      = @w_rep_fecha,
           @i_modulo     = 7,
           @i_modo       = 0, 
           @o_siguiente  = @w_max_cbt_generado out
      COMMIT      
      
      select @w_max_cbt_generado = isnull(max(ttr_comprobante), 0) + 1000
      from   ca_tmp_transaccion
      where  ttr_fecha_mov = @w_rep_fecha
      
      BEGIN TRAN
      update cob_conta..cb_seqnos_comprobante
      set    sc_actual = @w_max_cbt_generado
      where sc_fecha = @w_rep_fecha
      and   sc_modulo = 7
      and   sc_tabla  = 'cb_scomprobante'
      COMMIT
      
      declare
         cur_transacciones cursor
         for select ttr_operacion, ttr_secuencial
             from   ca_tmp_transaccion
             where  ttr_fecha_mov = @w_rep_fecha
             and    ttr_comprobante = @w_rep_comprobante
         for read only
      
      open cur_transacciones
      
      fetch cur_transacciones
      into  @w_rep_operacion, @w_rep_secuencial
      
      --while @@fetch_status not in (-1,0)
      while @@fetch_status = 0
      begin
         
         BEGIN TRAN
         update ca_tmp_transaccion
         set    ttr_comprobante = @w_max_cbt_generado
         from   ca_tmp_transaccion--(index ca_tmp_transaccion_1)
         where  ttr_operacion = @w_rep_operacion
         and    ttr_secuencial = @w_rep_secuencial
         COMMIT
         
         select @w_max_cbt_generado = @w_max_cbt_generado + 1
         
         fetch cur_transacciones
         into  @w_rep_operacion, @w_rep_secuencial
      end
      
      close cur_transacciones
      deallocate cur_transacciones
      
      BEGIN TRAN
      update cob_conta..cb_seqnos_comprobante
      set    sc_actual = @w_max_cbt_generado+1000
      where sc_fecha = @w_rep_fecha
      and   sc_modulo = 7
      and   sc_tabla  = 'cb_scomprobante'
      COMMIT
      
      fetch cur_repeticiones
      into  @w_rep_fecha,  @w_rep_comprobante,  @w_rep_numero
   end
   
   close cur_repeticiones
   deallocate cur_repeticiones
   
   declare
      cur_fecha_final cursor
      for select ttr_fecha_mov, max(ttr_comprobante)
          from   ca_tmp_transaccion
          group  by ttr_fecha_mov
      for read only
   
   open cur_fecha_final
   
   fetch cur_fecha_final
   into  @w_rep_fecha, @w_rep_comprobante
   
   --while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin
      BEGIN TRAN
      exec @w_error = cob_conta..sp_cseqcomp
           @i_tabla      = 'cb_scomprobante',
           @i_empresa    = @i_filial,
           @i_fecha      = @w_rep_fecha,
           @i_modulo     = 7,
           @i_modo       = 0, 
           @o_siguiente  = @w_max_cbt_generado out
      COMMIT
      
      BEGIN TRAN
      update cob_conta..cb_seqnos_comprobante
      set    sc_actual = @w_rep_comprobante + 1000
      where  sc_fecha = @w_rep_fecha
      and    sc_modulo = 7
      and    sc_tabla  = 'cb_scomprobante'
      COMMIT
      
      fetch cur_fecha_final
      into  @w_rep_fecha, @w_rep_comprobante
   end
   
   close cur_fecha_final
   deallocate cur_fecha_final
   print 'FIN'
   
   return 0
end
go
