/***************************************************************/
/*   PROPOSITO                                                 */
/*   Manejo de transacciones por operacion.                    */
/*   T: Insercion de transaccion por operacion                 */
/*   U: Modificacion de transaccion por operacion              */
/*   D: Eliminacion de transaccion por operacion               */
/*   A: Consulta de transaccion por operacion                  */
/*   Q: Query de transaccion por operacion                     */
/***************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_trn_oper')
    drop proc sp_trn_oper
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_trn_oper
   @s_ssn                int           = null,
   @s_user               varchar(30)   = null,
   @s_sesn               int           = null,
   @s_term               varchar(30)   = null,
   @s_date               datetime      = null,
   @s_srv                varchar(30)   = null,
   @s_lsrv               varchar(30)   = null,
   @s_ofi                smallint      = null,
   @t_trn                int           = null,
   @t_debug              char(1)       = 'N',
   @t_file               varchar(14)   = null,
   @t_from               varchar(30)   = null,
   @s_rol                smallint      = null,
   @s_org_err            char(1)       = null,
   @s_error              int           = null,
   @s_sev                tinyint       = null,
   @s_msg                descripcion   = null,
   @s_org                char(1)       = null,
   @s_culture            varchar(10)   = 'NEUTRAL',
   @t_rty                char(1)       = null,
   @t_show_version       bit           = 0,
   @i_operacion          char(1)       = null,
   @i_toperacion         catalogo      = null,
   @i_tipo_trn           catalogo      = null,
   @i_toperacion_b       catalogo      = null,
   @i_tipo_trn_b         catalogo      = null,
   @i_perfil             catalogo      = null,
   @i_filial             int           = null
as

declare
   @w_sp_name           varchar(32),  /* nombre stored proc*/
   @w_existe            tinyint,      /* existe el registro*/
   @w_toperacion        catalogo,
   @w_tipo_trn          catalogo,
   @w_perfil            catalogo,
   @w_det_toperacion    varchar(64),
   @w_det_tipotrn       varchar(64),
   @w_det_perfil        varchar(64),
   @w_error             int,
   @w_tos_toperacion    catalogo,
   @w_tos_tipo_trn      catalogo,
   @w_tos_perfil        catalogo,
   @w_to_toperacion     catalogo,
   @w_to_tipo_trn       catalogo,
   @w_to_perfil         catalogo,
   @v_to_toperacion     catalogo,
   @v_to_tipo_trn       catalogo,   
   @v_to_perfil         catalogo

select @w_sp_name = 'sp_trn_oper'

-- Chequeo de Existencias
if @i_operacion <> 'S' and @i_operacion <> 'A'
begin
   select @w_toperacion = to_toperacion,
          @w_tipo_trn = to_tipo_trn,
          @w_perfil = to_perfil
   from   cob_cartera..ca_trn_oper
   where  to_toperacion = @i_toperacion 
   and    to_tipo_trn = @i_tipo_trn
   
   if @@rowcount > 0
      select @w_existe = 1
   else
      select @w_existe = 0
end

-- VALIDACION DE CAMPOS NULOS
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if @i_toperacion is NULL or @i_tipo_trn is NULL
    begin
       select @w_error = 708150
       goto ERROR
    end
end

-- INSERTAR
if @i_operacion = 'I'
begin
   if @w_existe = 1
   begin
      select @w_error = 708151
      goto ERROR
   end
   
   insert into ca_trn_oper
         (to_toperacion, to_tipo_trn, to_perfil)
   values(@i_toperacion, @i_tipo_trn, @i_perfil)
   
   if @@error <> 0
   begin
      select @w_error = 708154
      goto ERROR
   end
   
   ---Transaccion de servicio - Inserción de Trn Oper
   insert into cob_cartera..ca_trn_oper_ts
         (tos_fecha_proceso_ts,  tos_fecha_ts,     tos_usuario_ts,
          tos_oficina_ts,        tos_terminal_ts,  tos_tipo_transaccion_ts,
          tos_origen_ts,         tos_clase_ts,     tos_toperacion,
          tos_tipo_trn,          tos_perfil)
   values(@s_date,               getdate(),        @s_user,
          @s_ofi,                @s_term,          @t_trn,
          @s_org,                'N',              @i_toperacion,
          @i_tipo_trn,           @i_perfil)
   
   if @@error != 0
   begin
      exec cobis..sp_cerror
           @t_from   = @w_sp_name,
           @i_num    = 710047
      return 1
   end          
end

-- ACTUALIZACION
if @i_operacion = 'U'
begin
   if @w_existe = 0
   begin
      select @w_error = 708153
      goto ERROR
   end
   
   -- Seleccionar los nuevos datos
   select @w_to_toperacion = to_toperacion,
          @w_to_tipo_trn  = to_tipo_trn,
          @w_to_perfil    = to_perfil
   from   cob_cartera..ca_trn_oper
   where  to_toperacion = @i_toperacion 
   and    to_tipo_trn = @i_tipo_trn
   
   if @@rowcount = 0
   begin
      exec cobis..sp_cerror
           @t_from               = @w_sp_name,
           @i_num                = 710047
      return 1
   end
   
   /*
   select @v_to_toperacion  = @w_to_toperacion,
          @v_to_tipo_trn   = @w_to_tipo_trn,
          @v_to_perfil     = @w_to_perfil
   
   if @w_to_toperacion = @i_toperacion
      select @w_to_toperacion = null, @v_to_toperacion = null
   else
      select @w_to_toperacion = @i_toperacion
   
   if @w_to_tipo_trn = @i_tipo_trn
      select @w_to_tipo_trn = null, @v_to_tipo_trn = null
   else
      select @w_to_tipo_trn = @i_tipo_trn
   
   if @w_to_perfil = @i_perfil
      select @w_to_perfil = null, @v_to_perfil = null
   else
      select @w_to_perfil = @i_perfil
   */
   
   update cob_cartera..ca_trn_oper
   set    to_perfil = @i_perfil
   where  to_toperacion = @i_toperacion 
   and    to_tipo_trn = @i_tipo_trn
   
   if @@error <> 0
   begin
      select @w_error = 708152
      goto ERROR
   end
   
      ---Transaccion de servicio - Inserción de Trn Oper
   insert into cob_cartera..ca_trn_oper_ts
         (tos_fecha_proceso_ts,  tos_fecha_ts,     tos_usuario_ts,
          tos_oficina_ts,        tos_terminal_ts,  tos_tipo_transaccion_ts,
          tos_origen_ts,         tos_clase_ts,     tos_toperacion,
          tos_tipo_trn,          tos_perfil)
   values (@s_date,              getdate(),        @s_user,
           @s_ofi,               @s_term,          @t_trn,
           @s_org,               'P',              @w_to_toperacion,
           @w_to_tipo_trn,       @w_to_perfil)
   if @@error != 0
   begin
      exec cobis..sp_cerror
           @t_from   = @w_sp_name,
           @i_num    = 710047
      return 1
   end      
   
   ---Transaccion de servicio - Inserción de Trn Oper
   insert into cob_cartera..ca_trn_oper_ts
         (tos_fecha_proceso_ts,  tos_fecha_ts,     tos_usuario_ts,
          tos_oficina_ts,        tos_terminal_ts,  tos_tipo_transaccion_ts,
          tos_origen_ts,         tos_clase_ts,     tos_toperacion,
          tos_tipo_trn,          tos_perfil)
   values(@s_date,               getdate(),        @s_user,
          @s_ofi,                @s_term,          @t_trn,
          @s_org,                'A',              @i_toperacion,
          @i_tipo_trn,           @i_perfil)
   
   if @@error != 0
   begin
      exec cobis..sp_cerror
           @t_from   = @w_sp_name,
           @i_num    = 710047
      return 1
   end      
end

-- BORRADO
if @i_operacion = 'D'
begin
   if @w_existe = 0
   begin
      select @w_error = 708150
      goto ERROR
   end
   
   -- Valores para transaccion de servicio Trn Oper
   select @w_tos_toperacion   = to_toperacion,   
          @w_tos_tipo_trn   = to_tipo_trn,   
          @w_tos_perfil   = to_perfil   
   from   cob_cartera..ca_trn_oper
   where  to_toperacion = @i_toperacion 
   and    to_tipo_trn = @i_tipo_trn
   
   delete cob_cartera..ca_trn_oper
   where to_toperacion = @i_toperacion 
   and   to_tipo_trn = @i_tipo_trn
   
   if @@error <> 0
   begin
      select @w_error = 708155
      goto ERROR
   end
   
   ---Transaccion de servicio - Inserción de Trn Oper
   insert into cob_cartera..ca_trn_oper_ts
         (tos_fecha_proceso_ts,  tos_fecha_ts,     tos_usuario_ts,
          tos_oficina_ts,        tos_terminal_ts,  tos_tipo_transaccion_ts,
          tos_origen_ts,         tos_clase_ts,     tos_toperacion,
          tos_tipo_trn,          tos_perfil)
   values(@s_date,               getdate(),        @s_user,
          @s_ofi,                @s_term,          @t_trn,
          @s_org,                'B',              @w_tos_toperacion,
          @w_tos_tipo_trn,       @w_tos_perfil)
   
   if @@error != 0
   begin
      exec cobis..sp_cerror
           @t_from         = @w_sp_name,
           @i_num          = 710047
      return 1
   end
end

-- BUSQUEDA DE REGISTRO
if @i_operacion = 'A'
begin
   set rowcount 20 
   select 'Línea de Crédito' = to_toperacion,
          'Tipo Transacción' = to_tipo_trn,
          'Perfil'           = to_perfil
   from ca_trn_oper
   where (   to_toperacion > @i_toperacion 
          or (to_toperacion = @i_toperacion and to_tipo_trn > @i_tipo_trn)
          or @i_toperacion is null)
   and   (to_toperacion = @i_toperacion_b or @i_toperacion_b is null)
   and   (to_tipo_trn = @i_tipo_trn_b or @i_tipo_trn_b is null)
   order by to_toperacion, to_tipo_trn
end 

-- CONSULTA DE UN REGISTRO ESPECIFICO
if @i_operacion = 'Q'
begin
   select @w_toperacion = to_toperacion,
          @w_tipo_trn = to_tipo_trn,
          @w_perfil = to_perfil
   from   ca_trn_oper
   where  to_toperacion = @i_toperacion
   and    to_tipo_trn = @i_tipo_trn
   
   select @w_det_toperacion = Y.valor
   from   cobis..cl_tabla X, cobis..cl_catalogo Y
   where  X.tabla = 'ca_toperacion'
   and    Y.codigo = @i_toperacion
   and    X.codigo = Y.tabla
   set transaction isolation level read uncommitted
   
   select @w_det_tipotrn = tt_descripcion
   from   ca_tipo_trn     
   where  tt_codigo = @i_tipo_trn
   
   select @w_det_perfil = pe_descripcion
   from   cob_conta..cb_perfil
   where  pe_producto = 7
   and    pe_perfil = @i_perfil
   set transaction isolation level read uncommitted
   
   select @w_toperacion,
          @w_det_toperacion,
          @w_tipo_trn,
          @w_det_tipotrn,
          @w_perfil,
          @w_det_perfil 
end     

return 0


ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null,
     @t_from  = @w_sp_name,
     @i_num   = @w_error
return @w_error

go
