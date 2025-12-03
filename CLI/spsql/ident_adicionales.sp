/************************************************************************/
/*  Archivo:            ident_adicionales.sp                            */
/*  Stored procedure:   sp_ident_adicionales                            */
/*  Base de datos:      cobis                                           */
/*  Producto:           Clientes                                        */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "COBIS", representantes exclusivos para el Ecuador de la            */
/*  "FINCA IMPACT".                                                     */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de COBIS o su representante.                  */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Este programa procesa las transacciones del stored procedure        */
/*  Insercion de referencia economica                                   */
/*  Actualizacion de referencia economica                               */
/*  Borrado de referencia economica                                     */
/*  Busqueda de referencia economica  general y especifica              */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA        AUTOR    RAZON                                         */
/*  02/08/21     COB      Se crea SP para identificaciones adicionales  */
/************************************************************************/
use cobis

go

if exists (select 1 from sysobjects where name = 'sp_ident_adicionales')
   drop proc sp_ident_adicionales
go

create proc sp_ident_adicionales (
   @s_ssn              int             = null,
   @s_user             login           = null,
   @s_term             varchar(30)     = null,
   @s_date             datetime        = null,
   @s_srv              varchar(30)     = null,
   @s_lsrv             varchar(30)     = null,
   @s_ofi              smallint        = null,
   @s_rol              smallint        = null,
   @s_org_err          char(1)         = null,
   @s_error            int             = null,
   @s_sev              tinyint         = null,
   @s_msg              descripcion     = null,
   @s_org              char(1)         = null,
   @t_debug            char(1)         = 'N',
   @t_file             varchar(10)     = null,
   @t_from             varchar(32)     = null,
   @t_trn              int             = null,
   @i_operacion        char(1),
   @i_ente             int,
   @i_tipo_iden        catalogo        = null,
   @i_nume_iden        varchar(20)     = null,
   @i_tipo_iden_a      catalogo        = null,
   @i_nume_iden_a      varchar(20)     = null
)

as
declare
@w_sp_name varchar(10),
@w_return int,
@w_num              int,
@w_param            int, 
@w_diff             int,
@w_date             datetime,
@w_bloqueo          char(1),
@w_nacionalidad     varchar(10),
@w_pais_local       int,
@w_tipo_cliente     char(1),
@w_pais             int

select @w_sp_name = 'sp_ident_adicionales', 
       @w_return  = 0
select @i_nume_iden = upper(@i_nume_iden)
if @i_operacion in ('I', 'U', 'D')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   if @i_ente is not null and @i_ente <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_ente
      if @w_bloqueo = 'S'
      begin
         exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720604
         return 1720604
      end
   end 
end

select @w_pais_local      = pa_smallint 
from cobis..cl_parametro 
where pa_nemonico = 'CP'    
and pa_producto = 'CLI'  -- PAIS DONDE ESTÁ EL BANCO

select @w_tipo_cliente = en_subtipo from cl_ente where en_ente = @i_ente

if @w_tipo_cliente = 'P'
begin
   select @w_pais = en_pais_nac from cl_ente where en_ente = @i_ente
end
else
begin
   select @w_pais = en_pais from cl_ente where en_ente = @i_ente
end   

if @w_pais_local <> @w_pais 
begin
   select @w_nacionalidad = 'E'
end
else
begin
   select @w_nacionalidad = 'N'
end

--VALIDACION DE ESTADO DE TIPO DE IDENTIFICACION TRIBUTARIA
if(select ti_estado from cl_tipo_identificacion
   where ti_codigo         = @i_tipo_iden 
   and   ti_tipo_documento = 'O' 
   and   ti_nacionalidad   = @w_nacionalidad 
   and   ti_tipo_cliente   = @w_tipo_cliente) != 'V'
begin
   exec sp_cerror
               @t_debug  = @t_debug,
               @t_file   = @t_file,
               @t_from   = @w_sp_name,
               @i_num    = 1720606
               return 1720606
end 

if @i_operacion = 'I'
begin
   if (select COUNT(*) from cl_ident_ente where ie_ente = @i_ente) >= (select pa_smallint from cl_parametro where pa_nemonico = 'NIAMP' and pa_producto = 'CLI')
   begin
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720535
      return 1720535
   end

   if exists (select 1 from cl_ident_ente where ie_tipo_doc = @i_tipo_iden and ie_ente = @i_ente)
   begin
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720546
      return 1720546
   end

   if exists (select 1 from cl_ident_ente where ie_tipo_doc = @i_tipo_iden and ie_numero = @i_nume_iden)
   begin
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720442
      return 1720442
   end

   begin tran

   insert into ts_identificaciones_adicionales (
      secuencial,              tipo_transaccion,               clase,
      fecha,                   usuario,                        terminal,                       
      srv,                     lsrv,                           ente,                    
      tipo_ident,              num_ident
   )
   values(
      @s_ssn,                  @t_trn,                         'I',
      getdate(),               @s_user,                        @s_term,
      @s_srv,                  @s_lsrv,                        @i_ente,
      @i_tipo_iden,            @i_nume_iden
   )

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 
   begin
      while @@trancount > 0 rollback
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720049
      return 1720049
   end

   insert into cl_ident_ente values (@i_ente, @i_tipo_iden, @i_nume_iden)
   if @@error <> 0
   begin
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720046
      return 1720046
   end

   commit tran
end

if @i_operacion = 'S'
begin
   select ie_ente, ie_tipo_doc,ie_numero from cl_ident_ente where ie_ente = @i_ente
end

if @i_operacion = 'U'
begin
   if exists (select 1 from cl_ident_ente where ie_tipo_doc = @i_tipo_iden and ie_ente = @i_ente and ie_tipo_doc <> @i_tipo_iden_a)
   begin
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720546
      return 1720546
   end

   if exists (select 1 from cl_ident_ente where ie_tipo_doc = @i_tipo_iden and ie_numero = @i_nume_iden and ie_ente <> @i_ente)
   begin
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720442
      return 1720442
   end

   begin tran

   --Registro de transaccion antes
   insert into ts_identificaciones_adicionales (
      secuencial,              tipo_transaccion,               clase,
      fecha,                   usuario,                        terminal,                       
      srv,                     lsrv,                           ente,                    
      tipo_ident,              num_ident
   )
   values(
      @s_ssn,                  @t_trn,                         'A',
      getdate(),               @s_user,                        @s_term,
      @s_srv,                  @s_lsrv,                        @i_ente,
      @i_tipo_iden_a,          @i_nume_iden_a
   )

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 
   begin
      while @@trancount > 0 rollback
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720049
      return 1720049
   end

   update cl_ident_ente 
   set ie_tipo_doc   = @i_tipo_iden, 
       ie_numero     = @i_nume_iden
   where ie_tipo_doc = @i_tipo_iden_a 
   and   ie_numero   = @i_nume_iden_a
   if @@error <> 0
   begin

      while @@trancount > 0 rollback
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720538
      return 1720538
   end

   --Registro de transaccion despues
   insert into ts_identificaciones_adicionales (
      secuencial,              tipo_transaccion,               clase,
      fecha,                   usuario,                        terminal,                       
      srv,                     lsrv,                           ente,                    
      tipo_ident,              num_ident
   )
   values(
      @s_ssn,                  @t_trn,                         'D',
      getdate(),               @s_user,                        @s_term,
      @s_srv,                  @s_lsrv,                        @i_ente,
      @i_tipo_iden,            @i_nume_iden
   )

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 
   begin
      while @@trancount > 0 rollback
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720049
      return 1720049
   end

   commit tran
end

if @i_operacion = 'D'
begin

   begin tran

   delete cl_ident_ente
   where ie_tipo_doc   = @i_tipo_iden
   and   ie_numero     = @i_nume_iden

   if @@error <> 0
   begin
      while @@trancount > 0 rollback

      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720474
      return 1720474
   end

   --Registro de transaccion despues
   insert into ts_identificaciones_adicionales (
      secuencial,              tipo_transaccion,               clase,
      fecha,                   usuario,                        terminal,                       
      srv,                     lsrv,                           ente,                    
      tipo_ident,              num_ident
   )
   values(
      @s_ssn,                  @t_trn,                         'E',
      getdate(),               @s_user,                        @s_term,
      @s_srv,                  @s_lsrv,                        @i_ente,
      @i_tipo_iden,            @i_nume_iden
   )

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 
   begin
      while @@trancount > 0 rollback
      exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720049
      return 1720049
   end

   commit tran
end

return 0

go
