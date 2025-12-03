/************************************************************************/
/*      Archivo:              dad_ente.sp                               */
/*      Stored procedure:     sp_dad_ente                               */
/*      Base de datos:        cobis                                     */
/*      Producto:               Clientes                                */
/*      Disenado por:           COB                                     */
/*      Fecha de escritura:     16-Marzo-21                             */
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
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*             Ejecutar inserciones, consultas, eliminaciones           */
/*           y actualizaciones de datos adicionales con cliente         */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA              AUTOR                  RAZON                 */
/*     16/03/21             COB        Emision Inicial                  */
/*     09/09/2023           BDU        R214440-Sincronizacion automatica*/
/*     20/10/2023           BDU        R217831-Ajuste validacion error  */
/*     22/01/2024           BDU        R224055-Validar oficina app      */
/************************************************************************/

use cobis
go

if object_id('sp_dad_ente') is not null
begin
    drop procedure sp_dad_ente
end
go

create proc sp_dad_ente (
        @s_ssn                int             = null,
        @s_user               login           = null,
        @s_term               varchar(30)     = null,
        @s_date               datetime        = null,
        @s_srv                varchar(30)     = null,
        @s_lsrv               varchar(30)     = null,
        @s_ofi                smallint        = null,
        @s_rol                smallint        = null,
        @s_org_err            char(1)         = null,
        @s_error              int             = null,
        @s_sev                tinyint         = null,
        @s_msg                descripcion     = null,
        @s_org                char(1)         = null,
        @t_debug              char(1)         = 'N',
        @t_file               varchar(10)     = null,
        @t_from               varchar(32)     = null,
        @t_trn                int             = null,
        @i_operacion          char(1),
        @i_ente               int             = null,
        @i_dato               smallint        = null,
        @i_descripcion        descripcion     = null,
        @i_tipodato           char(1)         = null,
        @i_valor              descripcion     = null,
        @i_tipoente           char(1)         = null,
        @i_sec_correccion     int             = null,
        @o_mensaje            int             = 0 out,
        @o_tipo_id            varchar(10)     = null out
)

as

declare @w_sp_name            varchar(32),
        @w_return             int,
        @w_siguiente          int,
        @w_cod_mail           smallint,
        @w_cod_dad            smallint,
        @w_valor              descripcion,
        @v_valor              descripcion,
        @w_tipo_iden          char(2),
        @w_mensaje_inf        varchar(255),
        @w_ced_ruc            varchar(15),
        @w_nombre             char(30),
        @w_p_apellido         varchar(30),
        @w_s_apellido         varchar(30),
        @w_tipo_cliente       char(1),
        @w_cont               int,
        -- R214440-Sincronizacion automatica
        @w_sincroniza      char(1),
        @w_error           int,
        @w_ofi_app         smallint


select @w_sp_name = 'sp_dad_ente'
select @o_mensaje = 0
create table #datos_adicionales_tmp(
  codigo       int ,
    descripcion  varchar(150),
    tipo_dato    varchar(150),
    valor        varchar(255) null,
    tipo_dato_id varchar(2),
    valor_desc   varchar(255) null,
    bdatos       varchar(255) null,
    bprocedure   varchar(255) null,
    catalogo     varchar(255) null
    )

if (@i_operacion = 'Q' and @t_trn <> 172183)
  or (@i_operacion = 'I' and @t_trn <> 172184) 
  or (@i_operacion = 'E' and @t_trn <> 172185)
  or (@i_operacion = 'U' and @t_trn <> 172186)
begin
  exec sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_num      = 1720417
  /*'Error en codigo de transaccion'*/
  return 1
end

if @i_operacion in ('U', 'I')
    select @i_descripcion = da_descripcion from cobis..cl_dato_adicion where da_codigo = @i_dato


/* inserta a un nuevo cliente los datos adicionales que sean obligatorios con sus valores por defecto*/


if @i_operacion = 'I'
begin 
   if @i_descripcion is null or @i_descripcion = ''
   begin
      exec sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720649
      /*ERROR DE PARAMETRIZACION DE PSEUDONIMO*/
      return 1
   end    

  if @t_trn = 172184
  begin

    /*Verifica que no exista el registro repetido*/
    IF EXISTS(SELECT 1 FROM cl_dadicion_ente WHERE de_ente = @i_ente AND de_dato =  @i_dato) 
    begin
      exec sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720469
      /*EL DATO ADICIONAL YA EXISTE*/
      return 1
    end

    BEGIN TRAN
      
      /*Insercion a la tabla*/
      INSERT INTO cl_dadicion_ente (de_ente, de_dato, de_descripcion, de_tipo_dato, de_valor) 
      VALUES (@i_ente, @i_dato, @i_descripcion, @i_tipodato, @i_valor)

      if @@error != 0
      begin
        exec sp_cerror
        @t_debug    = @t_debug,
        @t_file     = @t_file,
        @t_from     = @w_sp_name,
        @i_num      = 1720470
        /* 'ERROR AL AGREGAR A LA TABLA'*/
        return 1
      end

      insert into ts_dadicion_ente (secuencial, tipo_transaccion, clase, fecha,
                                    usuario, terminal, srv, lsrv,
                                    ente, dato, valor, sec_correccion)
      values(@s_ssn, @t_trn, 'I', @s_date,
            @s_user, @s_term,@s_srv, @s_lsrv, 
            @i_ente, @i_dato, @w_valor, @i_sec_correccion)

      if @@error != 0

      begin
        exec sp_cerror
          @t_debug        = @t_debug,
          @t_file         = @t_file,
          @t_from         = @w_sp_name,
          @i_num          = 1720471
          /* 'Error en creacion de transaccion de dato adicional'*/
        return  1
      end
      
    commit tran 
  end
end

/* Modifica el registro indicado de datos adicionales del cliente seleccionado*/

if @i_operacion = 'U'

begin

  if @t_trn = 172186 
  begin

    if not exists(select 1 from cl_dadicion_ente WHERE de_ente = @i_ente AND de_dato = @i_dato)
    begin 

      exec sp_cerror
        @t_debug    = @t_debug,
        @t_file     = @t_file,
        @t_from     = @w_sp_name,
        @i_num      = 1720472
        /* 'No existe dato solicitado'*/
       return 1
    end 

    BEGIN TRAN

      UPDATE cl_dadicion_ente SET de_valor = @i_valor WHERE de_ente = @i_ente AND de_dato = @i_dato
      if @@error != 0
      begin
        exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 1720473
          /* 'ERROR EN ACTUALIZACION DE DATO ADICIONA'*/
        return 1
      end

      insert into ts_dadicion_ente (secuencial, tipo_transaccion, clase, fecha,
                                    usuario, terminal, srv, lsrv,
                                    ente, dato, valor, sec_correccion)
      values(@s_ssn, @t_trn, 'U', @s_date,
            @s_user, @s_term,@s_srv, @s_lsrv, 
            @i_ente, @i_dato, @w_valor, @i_sec_correccion)
      
      if @@error != 0
      begin
        exec sp_cerror
          @t_debug        = @t_debug,
          @t_file         = @t_file,
          @t_from         = @w_sp_name,
          @i_num          = 1720471
        /* 'Error en creacion de transaccion de servicio'*/
        return  1
      end
    commit tran    
  end
end

/* Elimina el registro indicado de datos adicionales del cliente seleccionado*/
if @i_operacion = 'E'
begin
  if @t_trn = 172185

  begin
    if not exists (select 1 from cl_dadicion_ente WHERE de_ente = @i_ente AND de_dato = @i_dato)
    begin 
      exec sp_cerror
        @t_debug    = @t_debug,
        @t_file     = @t_file,
        @t_from     = @w_sp_name,
        @i_num      = 1720472
      /* 'No existe dato solicitado'*/
      return 1
    end 
    
    begin tran
      DELETE FROM cl_dadicion_ente WHERE de_ente = @i_ente AND de_dato = @i_dato
      if @@error != 0
      begin
        exec sp_cerror
          @t_debug    = @t_debug,
          @t_file     = @t_file,
          @t_from     = @w_sp_name,
          @i_num      = 1720474
        /* 'No se pudo eliminar el registro'*/
        return 1
      end
      
      insert into ts_dadicion_ente (secuencial, tipo_transaccion, clase, fecha,
                                    usuario, terminal, srv, lsrv,
                                    ente, dato, valor, sec_correccion)
      values(@s_ssn, @t_trn, 'E', @s_date,
            @s_user, @s_term,@s_srv, @s_lsrv, 
            @i_ente,  @i_dato, @w_valor, @i_sec_correccion)
      
      if @@error != 0
      begin
        exec sp_cerror
          @t_debug        = @t_debug,
          @t_file         = @t_file,
          @t_from         = @w_sp_name,
          @i_num          = 1720471
          /* 'Error en creacion de transaccion de servicio'*/
        return  1
      end
    commit tran    
  end
end

if @i_operacion in ('I','U','E')
begin
   select @w_tipo_cliente = en_subtipo from cl_ente where en_ente = @i_ente
   select @w_cont = count(*) 
   from cl_dato_adicion 
   where da_mandatorio = 'S' 
   and   da_tipo_ente  = @w_tipo_cliente
   and   da_codigo     not in (select de_dato 
                               from cl_dadicion_ente 
                               where de_ente = @i_ente)
   if @w_cont > 0
   begin
       select @o_mensaje = @w_cont
   end
end

/* consulta la informacion de los datos adicionales de un cliente seleccionado*/

if @i_operacion = 'Q'
begin
  if @t_trn = 172183
    begin
     SELECT "Codigo entidad" = de_ente,
            "Codigo dato" = de_dato,
            "Descripcion" = de_descripcion,
          "Tipo de dato" = de_tipo_dato,
            "Descripcion tipo de dato" = (select valor from cobis..cl_catalogo c, cobis..cl_tabla t where c.tabla = t.codigo and c.codigo = de_tipo_dato and t.tabla = 'cl_tipos_datos'),
            "Valor" = CASE de_tipo_dato
                    WHEN 'M' THEN  FORMAT(convert(numeric, de_valor), 'N')
                    ELSE de_valor
                END,
            "Catalogo"  = CASE de_tipo_dato
                WHEN 'A' THEN  (select c.valor from cobis..cl_catalogo c, cobis..cl_tabla t, cobis..cl_dato_adicion da where c.tabla = t.codigo and t.tabla = da.da_catalogo and da.da_codigo = de_dato and c.codigo = de_valor)        
                ELSE ''
            END
      FROM cobis..cl_dadicion_ente WHERE de_ente = @i_ente
      
      select @o_tipo_id = en_tipo_ced from cl_ente where en_ente = @i_ente
    /* if @@rowcount = 0
        begin
          exec sp_cerror  @t_debug    = @t_debug,
                @t_file     = @t_file,
                @t_from     = @w_sp_name,
                @i_num      = 1720475
             'No existe dato solicitado'
            return 1
        end*/
    end
end

select @w_sincroniza = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'HASIAU'

select @w_ofi_app = pa_smallint 
from cobis.dbo.cl_parametro cp 
where cp.pa_nemonico = 'OFIAPP'
and cp.pa_producto = 'CRE'

--Proceso de sincronizacion Clientes
if @i_operacion in ('I','U','E') and @i_ente is not null and @w_ofi_app <> @s_ofi
begin
   exec @w_error = cob_sincroniza..sp_sinc_arch_json
      @i_opcion     = 'I',
      @i_cliente    = @i_ente,
      @t_debug      = 'N'
   if @w_error <> 0 and @w_error is not null
   begin 
     exec cobis..sp_cerror 
       @t_debug = @t_debug, 
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = @w_error
     return @w_error
   end
end

return 0                                                                                                                   
go
