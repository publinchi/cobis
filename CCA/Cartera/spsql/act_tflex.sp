/************************************************************************/
/*      Archivo:                act_tflex.sp                            */
/*      Stored procedure:       sp_actualizar_tflexible                 */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     May. 2014                               */
/*      Nro. procedure          8                                       */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Establece un préstamo con tabla de amortización Flexible        */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-08-20     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/*      2015-06-09     Luis Guzman    REQ 479 - Excluir Lineas          */
/*                                    Finagro de Tabla Flexible         */
/*      2016-10-18     Jorge Salazar  Migracion Cobis Cloud             */
/************************************************************************/  

use cob_cartera
go

--- SECCION:ERRORES no quitar esta seccion
delete cobis..cl_errores where numero between 70008001 and 70008005
go
insert into cobis..cl_errores values(70008001, 0, 'No se encuentra el numero de operacion o ya fue desembolsada.')
insert into cobis..cl_errores values(70008002, 0, 'El tramite no cuenta con flujo de disponibles. Se debe verificar la correcta carga del flujo.')
insert into cobis..cl_errores values(70008003, 0, 'Inconsistencia de datos del cliente del tramite.')
insert into cobis..cl_errores values(70008004, 0, 'No se realcula nueva tabla porque ya fue calculada una simulacion con esta version del flujo.')
insert into cobis..cl_errores values(70008005, 0, 'ESTA LINEA DE CREDITO NO PERMITE ASIGNACION DE PAGOS FLEXIBLES')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_actualizar_tflexible')
   drop proc sp_actualizar_tflexible
go

---NR000392
create proc sp_actualizar_tflexible
   @s_user              login       = null,
   @s_date              datetime    = null,
   @s_term              varchar(30) = null,
   @s_ofi               smallint    = null,
   @s_sesn              int         = null,

   @i_debug             char(1)     = 'N',
   @i_opcion            varchar(20),
   @i_banco             varchar(20), -- ESTE NUMERO DE BANCO SIEMPRE ES EL NÚMERO INTERNO DE OPERACION
   @i_fecha_liq         datetime    = null,
   @i_formato_fecha     smallint    = 103,
   @i_fecha_desde       datetime    = '2014-05-01',
   @i_dividendo_qr      int         = 0
as
declare
   @w_error                int,
   @w_op_tramite           int,
   @w_op_operacion         int,
   @w_resultado            int,
   @w_solicitud_tflex      char,
   @w_aplica_finagro       char(1),
   @w_linea_credito        catalogo



begin
   if @i_debug = 'S'
      print 'Msg'
   
   --LG Cuando la operacion ya fue desembolsada llega el numero grande
   if DATALENGTH(@i_banco) > 9
   begin
      
      select @w_op_operacion  = op_operacion,
             @i_banco         = op_banco
      from   ca_operacion with (nolock)
      where  op_banco = @i_banco
      and    op_estado in (0, 99)

      if @@rowcount = 0
      begin
         select @w_error = 70008001
         goto ERROR
      end
      
   end   
   else
   begin
      select @w_op_operacion  = op_operacion,
             @i_banco         = op_banco
      from   ca_operacion with (nolock)
      where  op_operacion = cast(@i_banco as int) 
      and    op_estado in (0, 99)

      if @@rowcount = 0
      begin
         select @w_error = 70008001
         goto ERROR
      end      
   end

   -- CONSULTAS DE DATOS GENERALES DEL PRESTAMO
   if @i_opcion = 'QROPER'
   begin
      exec @w_error = sp_qr_operacion
           @s_user              = @s_user,
           @s_date              = @s_date,
           @s_term              = @s_term,
           @s_ofi               = @s_ofi,
           @i_operacion       = 'Q',
           @i_formato_fecha   = @i_formato_fecha,
           @i_banco           = @i_banco

      if @w_error != 0
         goto ERROR

      return 0
   end

   -- INICIO DEL PROCESO DE GENERACION DE TABLA DE AMORTIZACION O SIMULACION
   if @i_opcion = 'FLEXIBLE.SI'
   begin
      BEGIN TRAN
      exec @w_error = sp_control_tflexible
           @s_user               = @s_user,
           @s_date               = @s_date,
           @s_term               = @s_term,
           @s_ofi                = @s_ofi,

           @i_debug              = @i_debug,
           @i_accion             = 'REGISTRAR',
           @i_solicitud_tflex    = 'S',
           @i_operacion          = @w_op_operacion
      
      if @w_error != 0
         goto ERROR
      
      COMMIT
      return 0
   end

   if @i_opcion = 'FLEXIBLE.NO'
   begin
      BEGIN TRAN
      exec @w_error = sp_control_tflexible
           @s_user               = @s_user,
           @s_date               = @s_date,
           @s_term               = @s_term,
           @s_ofi                = @s_ofi,

           @i_debug              = @i_debug,
           @i_accion             = 'REGISTRAR',
           @i_solicitud_tflex    = 'N',
           @i_operacion          = @w_op_operacion
      
      if @w_error != 0
         goto ERROR
      
      COMMIT
      return 0
   end

   -- CONSULTAS
   if @i_opcion = 'QRDECISION'
   begin
      select @w_solicitud_tflex = 'N'

      select @w_solicitud_tflex = tfc_solicitud_tflex
      from   ca_tabla_flexible_control with (nolock)
      where  tfc_operacion = @w_op_operacion

      select @w_solicitud_tflex

      return 0
   end

   if @i_opcion = 'QRSIMULACION'
   begin
      select convert(varchar, tf_fecha_ven, @i_formato_fecha),
             tf_concepto,
             tf_cuota
      from   cob_externos..ex_tabla_flexible with (nolock)
      where  tf_operacion = @w_op_operacion
      and    tf_dividendo = @i_dividendo_qr
      order  by tf_concepto

      return 0
   end

   if @i_opcion = 'QRAMORTIZACION'
   begin
      --LG Cuando la operacion ya fue desembolsada llega el numero grande
      if DATALENGTH(@i_banco) > 9
      begin
      
         select @w_op_operacion  = op_operacion
         from   ca_operacion with (nolock)
         where  op_banco = @i_banco
         and    op_estado in (0, 99)

         if @@rowcount = 0
         begin
            select @w_error = 70008001
            goto ERROR
         end
      
      end   
      else
      begin
         select @w_op_operacion  = op_operacion
         from   ca_operacion with (nolock)
         where  op_operacion = cast(@i_banco as int) 
         and    op_estado in (0, 99)

         if @@rowcount = 0
         begin
            select @w_error = 70008001
            goto ERROR
         end      
      end

      select convert(varchar, di_fecha_ven, @i_formato_fecha),
             am_concepto,
             am_cuota
      from   ca_dividendo with (nolock),
             ca_amortizacion with (nolock)
      where  di_operacion = @w_op_operacion
      and    di_dividendo = @i_dividendo_qr
      and    am_operacion = di_operacion
      and    am_dividendo = @i_dividendo_qr
      order  by am_concepto

      return 0
   end

   if @i_opcion = 'QRDISPONIBLES'
   begin
      --LG Cuando la operacion ya fue desembolsada llega el numero grande
      if DATALENGTH(@i_banco) > 9
      begin
      
         select @w_op_tramite  = op_tramite
         from   ca_operacion with (nolock)
         where  op_banco = @i_banco
         and    op_estado in (0, 99)

         if @@rowcount = 0
         begin
            select @w_error = 70008001
            goto ERROR
         end
      
      end   
      else
      begin
         select @w_op_tramite  = op_tramite
         from   ca_operacion with (nolock)
         where  op_operacion = cast(@i_banco as int) 
         and    op_estado in (0, 99)

         if @@rowcount = 0
         begin
            select @w_error = 70008001
            goto ERROR
         end      
      end

      if not exists(select 1
                    from   cob_credito..cr_disponibles_tramite with (nolock)
                    where  dt_tramite = @w_op_tramite)
      begin
         select @w_error = 70008002
         goto ERROR
      end

      set rowcount 10
      select convert(varchar, dt_fecha, @i_formato_fecha), dt_valor_disponible
      from   cob_credito..cr_disponibles_tramite with (nolock)
      where  dt_tramite = @w_op_tramite
      and    dt_fecha  > @i_fecha_desde
      order  by dt_fecha
      set rowcount 0

      return 0
   end

   -- LA SIGUIENTE PARTE DE LA RUTINA ES EL CÁLCULO DE LA TABLA DE AMORTIZACIÓN DEFINITIVA O SIMULACION
   if @i_opcion = 'APLICAR'
   begin
      select @w_solicitud_tflex = 'N'

      select @w_solicitud_tflex = tfc_solicitud_tflex
      from   ca_tabla_flexible_control with (nolock)
      where  tfc_operacion = @w_op_operacion
      
      if @w_solicitud_tflex = 'N'
      or exists(select 1
                from   ca_operacion with (nolock)
                where  op_operacion = @w_op_operacion
                and    op_tipo_amortizacion = 'FLEXIBLE')
      begin
         return 0
      end
   end
   
   BEGIN TRAN

   if @i_opcion = 'SIMULACION'
   begin
      select @w_resultado = 0

      exec @w_error = sp_control_tflexible
           @i_accion       = 'VERIF.VERSION',
           @i_operacion    = @w_op_operacion,
           @o_resultado    = @w_resultado OUTPUT
      
      if @w_resultado = 1
      begin
         COMMIT
         print 'Tabla ya calculada con la misma version de flujo'
         return 0
      end
   end

   if @i_opcion = 'APLICA_FINAGRO'
   begin      
      
      select @w_aplica_finagro= 'N'

      select @w_aplica_finagro =  pa_char
      from cobis..cl_parametro 
      where pa_nemonico = 'FIFLEX'
      and   pa_producto = 'CCA'
      
      select @w_linea_credito = op_toperacion
      from cob_cartera..ca_operacion 
      where op_operacion = @w_op_operacion

      if @w_linea_credito is null
      begin
           --print 'NO SE ENCONTRO LINEA DE CREDITO PARA LA OPERACION'           
           select @w_error = 70008001
           goto ERROR
      end        
      
      if exists (select top 1 1 from cob_credito..cr_corresp_sib s, cobis..cl_tabla t, cobis..cl_catalogo c        
                 where s.descripcion_sib = t.tabla
                 and   t.codigo            = c.tabla
                 and   s.tabla             = 'T301'
                 and   c.codigo            = @w_linea_credito
                 and   c.estado            = 'V')   
         and (@w_aplica_finagro   = 'N')

      begin

         --print 'ESTA LINEA DE CREDITO NO PERMITE ASIGNACION DE PAGOS FLEXIBLES'
         select @w_error = 70008005
         goto ERROR

      end
      else
      begin
         select @w_aplica_finagro = 'S'
      end

      select @w_aplica_finagro
      return 0
   end

   -- INICIO DEL PROCESO DE GENERACION DE TABLA DE AMORTIZACION O SIMULACION
   if not exists(select 1
                 from   ca_operacion_tmp with (nolock)
                 where  opt_banco = @i_banco)
   begin
      exec @w_error = sp_pasotmp
           @s_user              = @s_user,
           @s_term              = @s_term,
           @i_banco             = @i_banco,
           @i_operacionca       = 'S',
           @i_dividendo         = 'N',
           @i_amortizacion      = 'N',
           @i_cuota_adicional   = 'S',
           @i_rubro_op          = 'S',
           @i_relacion_ptmo     = 'S',
           @i_nomina            = 'S',
           @i_acciones          = 'S',
           @i_valores           = 'S'

      if @w_error != 0
      begin
         goto ERROR
      end
   end

   select @i_fecha_liq = isnull(@i_fecha_liq, @s_date)
   
   exec @w_error = sp_actualizar_tflexible_int
       @s_user        = @s_user,
       @s_date        = @s_date,
       @s_term        = @s_term,
       @s_ofi         = @s_ofi,
       @s_sesn        = @s_sesn,
       @i_debug       = 'N',
       @i_banco       = @i_banco,
       @i_fecha_liq   = @i_fecha_liq

   if @w_error != 0
      goto ERROR

   if @i_opcion = 'APLICAR'
   begin
      print 'Se aplico tabla de amortizacion flexible'
      while @@trancount > 0 COMMIT
   end
   
   if @i_opcion = 'SIMULACION'
   begin
      declare
         @w_tipo_id              catalogo,
         @w_numero_id            varchar(15),
         @w_version_flujo        smallint

      -- PARA REGISTRAR EN LA TABLA DE CONTROL
      select @w_tipo_id       = ltrim(rtrim(en_tipo_ced)),
             @w_numero_id     = ltrim(rtrim(en_ced_ruc))
      from   ca_operacion with (nolock),
             cobis..cl_ente with (nolock)
      where  op_banco = @i_banco
      and    en_ente = op_cliente
      and    op_estado in (0, 99)

      select @w_version_flujo = 0

      select @w_version_flujo = co_version
      from   cob_externos..ex_control_hra with (nolock)
      where  co_tipo_id = @w_tipo_id
      and    co_numero_id = @w_numero_id

      -- GUARDAR LOS DATOS DE LA TABLA GENERADA
      declare
         @tabla_amort table
            (ta_operacion        int,
             ta_dividendo        smallint,
             ta_fecha_ven        datetime,
             ta_concepto         catalogo,
             ta_cuota            money)
      
      insert into @tabla_amort
            (ta_operacion, ta_dividendo, ta_fecha_ven,
             ta_concepto,  ta_cuota)
      select amt_operacion, amt_dividendo, dit_fecha_ven,
             amt_concepto,  amt_cuota
      from   ca_dividendo_tmp with (nolock),
             ca_amortizacion_tmp with (nolock)
      where  dit_operacion = @w_op_operacion
      and    amt_operacion = dit_operacion
      and    amt_dividendo = dit_dividendo
      
      -- DESHACER LO ESCRITO
      while @@trancount > 0 ROLLBACK

      BEGIN TRAN
      -- GUARDAR LA TABLA GENERADA EN cob_externos
      delete cob_externos..ex_tabla_flexible with (rowlock)
      where  tf_operacion = @w_op_operacion

      insert into cob_externos..ex_tabla_flexible
            (tf_operacion, tf_dividendo, tf_fecha_ven,
             tf_concepto, tf_cuota)
      select ta_operacion, ta_dividendo, ta_fecha_ven,
             ta_concepto,  ta_cuota
      from   @tabla_amort

      exec @w_error = sp_control_tflexible
           @s_user               = @s_user,
           @s_date               = @s_date,
           @s_term               = @s_term,
           @s_ofi                = @s_ofi,

           @i_debug              = @i_debug,
           @i_accion             = 'REGISTRAR',
           @i_operacion          = @w_op_operacion,
           @i_version_flujo      = @w_version_flujo
      
      if @w_error != 0
         goto ERROR

      COMMIT
   end

   return 0
ERROR:
   while @@trancount > 0 ROLLBACK
   
   exec cobis..sp_cerror
        @t_debug   = 'N',
        @t_file    = null,
        @t_from    = sp_actualizar_tflexible,
        @i_num     = @w_error
   
   return @w_error
end
go

