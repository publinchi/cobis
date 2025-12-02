/************************************************************************/
/*      Archivo:                ctr_tflex.sp                            */
/*      Stored procedure:       sp_control_tflexible                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     Aug. 2014                               */
/*      Nro. procedure          10                                      */
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
/*      Administra el control de generación de tabla flexible           */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-08-20     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/*      2016-10-19     Jorge Salazar  Migracion Cobis Cloud             */
/************************************************************************/  

use cob_cartera
go

--- SECCION:ERRORES no quitar esta seccion
delete cobis..cl_errores where numero between 70010001 and 70010007
go
   insert into cobis..cl_errores values(70010001, 0, 'Inconsistencia de datos del cliente del trámite.')
   insert into cobis..cl_errores values(70010002, 0, 'Datos invalidos registrando los datos de control de tabla flexible.')
   insert into cobis..cl_errores values(70010003, 0, 'Error registrando los datos de control de tabla flexible (1).')
   insert into cobis..cl_errores values(70010004, 0, 'Error registrando los datos de control de tabla flexible (2).')
   insert into cobis..cl_errores values(70010005, 0, 'Error registrando los datos de control de tabla flexible (3).')
   insert into cobis..cl_errores values(70010006, 0, 'Error registrando los datos de control de tabla flexible (4).')
   insert into cobis..cl_errores values(70010007, 0, 'Error registrando los datos de control de tabla flexible (5).')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_control_tflexible')
   drop proc sp_control_tflexible
go

---NR000392
create proc sp_control_tflexible
   @s_user                 login       = null,
   @s_date                 datetime    = null,
   @s_term                 varchar(30) = null,
   @s_ofi                  smallint    = null,

   @i_debug                char(1)     = 'N',
   @i_accion               varchar(20), -- 'REGISTRAR', 'VERIF.VERSION'
   @i_operacion            int,
   @i_version_flujo        smallint    = null,
   @i_solicitud_tflex      char        = null,
   @i_solicitud_aplicada   char        = null,
   @i_fecha_aplicacion     datetime    = null,
   @o_resultado            int = 0 OUTPUT
as
declare
   @w_error                int,
   @w_tipo_id              catalogo,
   @w_numero_id            varchar(15),
   @w_version_flujo        smallint

begin
   if @i_accion = 'VERIF.VERSION'
   begin
      select @o_resultado = 0
      select @w_tipo_id       = ltrim(rtrim(en_tipo_ced)),
             @w_numero_id     = ltrim(rtrim(en_ced_ruc))
      from   ca_operacion with (nolock),
             cobis..cl_ente with (nolock)
      where  op_operacion  = @i_operacion
      and    en_ente       = op_cliente
      and    op_estado     in (0, 99)

      if @@rowcount = 0
      begin
         return 70010001
      end

      select @w_version_flujo = 0

      select @w_version_flujo = co_version
      from   cob_externos..ex_control_hra with (nolock)
      where  co_tipo_id = @w_tipo_id
      and    co_numero_id = @w_numero_id

      if exists(select 1
                from   ca_tabla_flexible_control with (nolock)
                where  tfc_operacion      = @i_operacion
                and    tfc_version_flujo  >= @w_version_flujo)
      begin
         select @o_resultado = 1
      end

      return 0
   end

   if @i_accion = 'REGISTRAR'
   begin
      select @i_solicitud_tflex     = isnull(@i_solicitud_tflex, tfc_solicitud_tflex),
             @i_solicitud_aplicada  = isnull(@i_solicitud_aplicada, tfc_solicitud_aplicada),
             @i_fecha_aplicacion    = isnull(@i_fecha_aplicacion, tfc_fecha_aplicacion)
      from   ca_tabla_flexible_control
      where  tfc_operacion = @i_operacion

      select @i_solicitud_tflex     = isnull(@i_solicitud_tflex, 'N'),
             @i_solicitud_aplicada  = isnull(@i_solicitud_aplicada, 'N'),
             @i_fecha_aplicacion    = isnull(@i_fecha_aplicacion, '02/24/2003')

      if @s_user                 is null
      or @s_date                 is null
      or @s_term                 is null
      or @s_ofi                  is null
         return 70010002

      -- GUARDAR VERSION ANTERIOR SI EXISTIERA
      insert into ca_tabla_flexible_control_ts
            (tfc_crud,                 tfc_date,               tfc_term,
             tfc_ofi,                  tfc_operacion,          tfc_version_flujo,
             tfc_timestamp,            tfc_user,               tfc_solicitud_tflex,
             tfc_solicitud_aplicada,   tfc_fecha_aplicacion)
      select 'D',                      @s_date,                @s_term,
             @s_ofi,                   tfc_operacion,          tfc_version_flujo,
             tfc_timestamp,            tfc_user,               tfc_solicitud_tflex,
             tfc_solicitud_aplicada,   tfc_fecha_aplicacion
      from   ca_tabla_flexible_control with (nolock)
      where  tfc_operacion = @i_operacion

      if @@error != 0
         return 70010007

      if exists(select 1
                from   ca_tabla_flexible_control with (nolock)
                where  tfc_operacion = @i_operacion)
      begin
         insert into ca_tabla_flexible_control_ts
               (tfc_crud,                 tfc_date,               tfc_term,
                tfc_ofi,                  tfc_operacion,
                tfc_version_flujo,
                tfc_timestamp,
                tfc_user,
                tfc_solicitud_tflex,
                tfc_solicitud_aplicada,
                tfc_fecha_aplicacion)
         select 'U',                      @s_date,                @s_term,
                @s_ofi,                   tfc_operacion,
                isnull(@i_version_flujo,      tfc_version_flujo),
                getdate(),
                isnull(@s_user,               tfc_user),
                isnull(@i_solicitud_tflex,    tfc_solicitud_tflex),
                isnull(@i_solicitud_aplicada, tfc_solicitud_aplicada),
                isnull(@i_fecha_aplicacion,   tfc_fecha_aplicacion)
         from   ca_tabla_flexible_control with (nolock)
         where  tfc_operacion = @i_operacion

         if @@error != 0
            return 70010003

         update ca_tabla_flexible_control
         set    tfc_version_flujo      = isnull(@i_version_flujo,      tfc_version_flujo),
                tfc_timestamp          = getdate(),
                tfc_user               = isnull(@s_user,               tfc_user),
                tfc_solicitud_tflex    = isnull(@i_solicitud_tflex,    tfc_solicitud_tflex),
                tfc_solicitud_aplicada = isnull(@i_solicitud_aplicada, tfc_solicitud_aplicada),
                tfc_fecha_aplicacion   = isnull(@i_fecha_aplicacion,   tfc_fecha_aplicacion)
         where  tfc_operacion = @i_operacion

         if @@error != 0
            return 70010004
      end
      ELSE
      begin
         insert into ca_tabla_flexible_control_ts
               (tfc_crud,                 tfc_date,               tfc_term,
                tfc_ofi,                  tfc_operacion,
                tfc_version_flujo,
                tfc_timestamp,
                tfc_user,
                tfc_solicitud_tflex,
                tfc_solicitud_aplicada,
                tfc_fecha_aplicacion)
         select 'C',                      @s_date,                @s_term,
                @s_ofi,                   @i_operacion,
                isnull(@i_version_flujo, 0),
                getdate(),
                @s_user,
                isnull(@i_solicitud_tflex, 'N'),
                isnull(@i_solicitud_aplicada, 'N'),
                isnull(@i_fecha_aplicacion, '02/24/2013')

         if @@error != 0
            return 70010005
      
         insert into ca_tabla_flexible_control
               (tfc_operacion,
                tfc_version_flujo,
                tfc_timestamp,
                tfc_user,
                tfc_solicitud_tflex,
                tfc_solicitud_aplicada,
                tfc_fecha_aplicacion)
         select @i_operacion,
                @i_version_flujo,
                getdate(),
                @s_user,
                @i_solicitud_tflex,
                @i_solicitud_aplicada,
                @i_fecha_aplicacion

         if @@error != 0
            return 70010006
      end
   end

   return 0
end
go

