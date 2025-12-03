/************************************************************************/
/*      Archivo:                sp_grupo_upd_masivo.sp                  */
/*      Stored procedure:       sp_grupo_upd_masivo                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           LGU                                     */
/*      Fecha de escritura:     May/2017                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes exclusivos para el Ecuador de la       */
/*      'NCR CORPORATION'.                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Mantenimiento de la tabla de control de pago masivo             */
/*      Mantenimiento de las tablas de la operacion grupal              */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/*    22/May/17             LGU              Emision Inicial            */
/************************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_grupo_upd_masivo')
    drop proc sp_grupo_upd_masivo
go
create proc sp_grupo_upd_masivo
        @i_param1            datetime = null,  -- fecha proceso
        @i_param2            varchar(10),      -- proceso a ejecutar S = actualizar sumar OP Padre // C actualizar control de pago
        @i_param3            varchar(10) = 'M', -- Opcion, solo para proceso CONTROL PAGO M = mantenimiento de control de pago
                                                -- I = crear control pago masivo, solo para pruebas
        @i_param4            cuenta   = null  -- prestamo grupal
as
declare
        @w_fecha_proceso         datetime,
        @w_opcion                varchar(10),
        @w_proceso               varchar(10),
        @w_banco                 cuenta,
        @w_sp_name               varchar(64),
        @w_return                int

   select @w_sp_name = 'sp_grupo_upd_masivo'

   select @w_fecha_proceso = convert(datetime, @i_param1, 101)
   select @w_banco  = @i_param4
   select @w_proceso= @i_param2
   select @w_opcion = @i_param3

   create table #tmp_grupal ( bco_grupal varchar(32))

   if @w_banco is not null
   begin
      insert into #tmp_grupal
      select tg_referencia_grupal
      from cob_credito..cr_tramite_grupal, ca_operacion, ca_estado
      where tg_referencia_grupal = @w_banco
      and tg_operacion = op_operacion
      and tg_monto > 0
      and convert(varchar, tg_operacion) <> tg_prestamo
      and op_estado  = es_codigo
	  and es_procesa = 'S'
   end
   else
   begin
      insert into #tmp_grupal
      select  distinct (tg_referencia_grupal )
      from cob_credito..cr_tramite_grupal, ca_operacion, ca_estado
      where tg_operacion = op_operacion
      and tg_monto > 0
      and convert(varchar, tg_operacion) <> tg_prestamo
      and op_estado  = es_codigo
	  and es_procesa = 'S'
   end

   select @w_banco = ''
   while 1=1
   begin
      set rowcount 1
      select @w_banco = bco_grupal
      from #tmp_grupal
      where bco_grupal >  @w_banco
      order by bco_grupal
      if @@rowcount = 0
      begin
         set rowcount 0
         break
      end
      set rowcount 0

      if @w_proceso = 'S' -- sumar padre
         exec @w_return = sp_actualiza_grupal
              @i_banco       = @w_banco,
              @i_desde_cca   = 'N'
      -- /////////////////////////////////////////////////////////////
      if @w_proceso = 'C' -- control pago
         exec @w_return = sp_grupo_control_pago
              @i_banco       = @w_banco,
              @i_opcion      = @w_opcion
      if @w_return <> 0
      begin
            exec sp_errorlog
            @i_fecha = @w_fecha_proceso,
            @i_error = @w_return,
            @i_usuario='consola',
            @i_tran   =7888,
            @i_tran_name=@w_sp_name,
            @i_cuenta= @w_banco,
            @i_rollback = 'S'
      end
   end -- while 1=1

return 0
go

