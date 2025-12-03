/************************************************************************/
/*  Archivo:                    direccion_geo.sp                        */
/*  Stored procedure:           sp_direccion_geo                        */
/*  Base de datos:              cobis                                   */
/*  Producto:                   Clientes                                */
/*  Disenado por:               JMEG                                    */
/*  Fecha de escritura:         30-Abril-19                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                          PROPOSITO                                   */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*   FECHA          AUTOR       RAZON                                   */
/*   30/04/19       JMEG        Emision Inicial                         */
/*   22/06/20       FSAP        Estandarizacion de Clientes             */
/*   15/10/20       MBA         Uso de la variable @s_culture           */
/************************************************************************/
use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
             from sysobjects 
            where type = 'P'
              and name = 'sp_direccion_geo')
              
   drop proc sp_direccion_geo
go
create procedure sp_direccion_geo (
   @s_ssn                int           = NULL,
   @s_user               login         = NULL,
   @s_sesn               int           = NULL,
   @s_term               varchar(32)   = NULL,
   @s_date               datetime      = NULL,
   @s_srv                varchar(30)   = NULL,
   @s_lsrv               varchar(30)   = NULL, 
   @s_rol                smallint      = NULL,
   @s_ofi                smallint      = NULL,
   @s_org_err            char(1)       = NULL,
   @s_error              int           = NULL,
   @s_sev                tinyint       = NULL,
   @s_msg                descripcion   = NULL,
   @s_org                char(1)       = NULL,
   @s_culture            varchar(10)   = 'NEUTRAL',
   @t_debug              char(1)       = 'N',
   @t_file               varchar(14)   = null,
   @t_from               varchar(32)   = null,
   @t_trn                int           = NULL,
   @t_show_version       bit           = 0,
   @i_operacion          varchar(2),
   @i_ente               int           = null, -- Codigo cliente
   @i_direccion          tinyint       = null, -- Codigo de la direccion que se asigna al Cliente
   -- DATOS GEOREFERENCIACION
   @i_lat_coord          char(1)       = null,
   @i_lat_grados         tinyint       = null,
   @i_lat_minutos        tinyint       = null,
   @i_lat_segundos       float         = null,
   @i_lon_coord          char(1)       = null,
   @i_lon_grados         tinyint       = null,
   @i_lon_minutos        tinyint       = null,
   @i_lon_segundos       float         = null,
   @i_path_croquis       varchar(50)   = null,
   @i_tipo               varchar(10)   = 'DF', --DF  --Direcciones FA­sicas --RF  --Residencia Fiscal                                              
   @o_secuencial         int           = null out
)
as
declare @w_today    datetime,
   @w_sp_name            varchar(32),
   @w_sp_msg             varchar(132),
   @w_codigo             int,
   @w_ente               int,
   @w_direccion          tinyint,
   @v_ente               int,
   @v_direccion          tinyint, 
   -- TRABAJO DATOS GEOREFERENCIACION
   @w_lat_coord          char(1),
   @w_lat_grados         tinyint,
   @w_lat_minutos        tinyint,
   @w_lat_segundos       float,
   @w_lon_coord          char(1),
   @w_lon_grados         tinyint,
   @w_lon_minutos        tinyint,
   @w_lon_segundos       float,
   @w_path_croquis       varchar(50),
   -- VISTA DATOS GEOREFERENCIACION
   @v_lat_coord          char(1),
   @v_lat_grados         tinyint,
   @v_lat_minutos        tinyint,
   @v_lat_segundos       float,
   @v_lon_coord          char(1),
   @v_lon_grados         tinyint,
   @v_lon_minutos        tinyint,
   @v_lon_segundos       float,
   @v_path_croquis       varchar(50)
   -- FIN VISTA
 
select   
   @w_today   = @s_date,
   @w_sp_name = 'sp_direccion_geo'

   
-------------- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
		
-- OPERACION G
-- QUERY ESPECIFICO DE DATOS DE GEOREFERENCIACION
if @i_operacion='G'
   begin
      if @t_trn = 172046 
         begin
 -------------
         if  @i_tipo = 'DF'
		    begin
		    if @i_direccion = 0
		       begin
		       select 
                  'LAT. COORD'  = dg_lat_coord,
                  'LAT. GRADOS' = dg_lat_grad,
                  'LAT. MINUT'  = dg_lat_min,
                  'LAT. SEG'    = dg_lat_seg,
                  'LON. COORD'  = dg_long_coord,
                  'LON. GRAD'   = dg_long_grad,
                  'LON. MIN'    = dg_long_min,
                  'LON. SEG'    = dg_long_seg,
                  'CROQUIS'     = dg_path_croquis
               from cl_direccion_geo
               where dg_ente      = @i_ente
               and   dg_direccion = (select max(dg_direccion) 
			                         from cl_direccion_geo 
									 where dg_ente = @i_ente) 
               and   dg_tipo      = 'DF'	
		       end
		    else
		    begin
		       select 
                  'LAT. COORD'  = dg_lat_coord,
                  'LAT. GRADOS' = dg_lat_grad,
                  'LAT. MINUT'  = dg_lat_min,
                  'LAT. SEG'    = dg_lat_seg,
                  'LON. COORD'  = dg_long_coord,
                  'LON. GRAD'   = dg_long_grad,
                  'LON. MIN'    = dg_long_min,
                  'LON. SEG'    = dg_long_seg,
                  'CROQUIS'     = dg_path_croquis
               from cl_direccion_geo
               where dg_ente      = @i_ente
               and   dg_direccion = @i_direccion 
               and   dg_tipo      = 'DF'			

            if @@rowcount = 0
               begin
                 --NO EXISTE DATO SOLICITADO
                 exec sp_cerror
                    @t_debug = @t_debug,
                    @t_file  = @t_file,
                    @t_from  = @w_sp_name,
                    @i_num   = 1720074
                 return 1
               end
		   end
            
         end
          if @i_tipo = 'RF'
           begin
            select 
                  'LAT. COORD'  = dg_lat_coord,
                  'LAT. GRADOS' = dg_lat_grad,
                  'LAT. MINUT'  = dg_lat_min,
                  'LAT. SEG'    = dg_lat_seg,
                  'LON. COORD'  = dg_long_coord,
                  'LON. GRAD'   = dg_long_grad,
                  'LON. MIN'    = dg_long_min,
                  'LON. SEG'    = dg_long_seg,
                  'CROQUIS'     = dg_path_croquis
               from cl_direccion_geo
               where dg_ente      = @i_ente
               and   dg_direccion = @i_direccion
               and   dg_tipo      = 'RF'			
               
               if @@rowcount = 0
                  begin
                    --NO EXISTE DATO SOLICITADO
                    exec sp_cerror
                       @t_debug = @t_debug,
                       @t_file  = @t_file,
                       @t_from  = @w_sp_name,
                       @i_num   = 1720074
                    return 1
                  end
                end  
       -------------
         end
      else
         begin
            exec sp_cerror
               --NO CORRESPONDE CODIGO DE TRANSACCION
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 1720075
            return 1
         end
   end
else
-- INSERT Y UPDATE
if @i_operacion = 'I'
   begin
      if @t_trn = 172047 -- PENDIENTE
         begin
      if   @i_tipo = 'DF' 
		     begin
            -- VERIFICACION DE CLAVES FORANEAS       
            -- VERIFICACION SI EXISTE YA DATOS GEOR PARA LA DIRECCION ESPECIFICADA
            if exists(select 1 from cl_direccion_geo
                         where @i_ente      = dg_ente
                         and   @i_direccion = dg_direccion
                         and   @i_tipo      = 'DF')
               begin

                  -- CARGANDO LOS DATOS ANTERIORES DE LA GEOREFERENCIACION
                  select 
                     @w_lat_coord    = dg_lat_coord,
                     @w_lat_grados   = dg_lat_grad,
                     @w_lat_minutos  = dg_lat_min,
                     @w_lat_segundos = dg_lat_seg,
                     @w_lon_coord    = dg_long_coord,
                     @w_lon_grados   = dg_long_grad,
                     @w_lon_minutos  = dg_long_min,
                     @w_lon_segundos = dg_long_seg,
                     @w_path_croquis = dg_path_croquis
                  from  cl_direccion_geo
                  where dg_ente      = @i_ente
                  and   dg_direccion = @i_direccion
				  and   dg_tipo      = 'DF'

                  --GUARDANDO LOS DATOS ANTERIORES
                  select 
                     @v_lat_coord    = @w_lat_coord,
                     @v_lat_grados   = @w_lat_grados,
                     @v_lat_minutos  = @w_lat_minutos,
                     @v_lat_segundos = @w_lat_segundos,
                     @v_lon_coord    = @w_lon_coord,
                     @v_lon_grados   = @w_lon_grados,
                     @v_lon_minutos  = @w_lon_minutos,
                     @v_lon_segundos = @w_lon_segundos,
                     @v_path_croquis = @w_path_croquis

                  -- VERIFICANDO CAMBIOS EN LOS CAMPOS
                  if @w_lat_coord = @i_lat_coord
                    select @w_lat_coord = null, @v_lat_coord = null
                  else
                    select @w_lat_coord = @i_lat_coord

                  if @w_lat_grados = @i_lat_grados
                    select @w_lat_grados = null, @v_lat_grados = null
                  else
                    select @w_lat_grados = @i_lat_grados

                  if @w_lat_minutos = @i_lat_minutos
                    select @w_lat_minutos = null, @v_lat_minutos = null
                  else
                    select @w_lat_minutos = @i_lat_minutos

                  if @w_lat_segundos = @i_lat_segundos
                    select @w_lat_segundos = null, @v_lat_segundos = null
                  else
                    select @w_lat_segundos = @i_lat_segundos

                  if @w_lon_coord = @i_lon_coord
                    select @w_lon_coord = null, @v_lon_coord = null
                  else
                    select @w_lon_coord = @i_lon_coord

                  if @w_lon_grados = @i_lon_grados
                    select @w_lon_grados = null, @v_lon_grados = null
                  else
                    select @w_lon_grados = @i_lon_grados

                  if @w_lon_minutos = @i_lon_minutos
                    select @w_lon_minutos = null, @v_lon_minutos = null
                  else
                    select @w_lon_minutos = @i_lon_minutos

                  if @w_lon_segundos = @i_lon_segundos
                    select @w_lon_segundos = null, @v_lon_segundos = null
                  else
                    select @w_lon_segundos = @i_lon_segundos

                  if @w_path_croquis = @i_path_croquis
                    select @w_path_croquis = null, @v_path_croquis = null
                  else
                    select @w_path_croquis = @i_path_croquis

                  begin tran
                     --SE ACTUALIZAN LOS DATOS
                     update  cl_direccion_geo 
                        set dg_ente           = @i_ente,
                            dg_direccion      = @i_direccion,
                            dg_lat_coord      = @i_lat_coord,
                            dg_lat_grad       = @i_lat_grados, 
                            dg_lat_min        = @i_lat_minutos,   
                            dg_lat_seg        = @i_lat_segundos,     
                            dg_long_coord     = @i_lon_coord,
                            dg_long_grad      = @i_lon_grados,
                            dg_long_min       = @i_lon_minutos,
                            dg_long_seg       = @i_lon_segundos,
                            dg_path_croquis   = isnull(@i_path_croquis, dg_path_croquis)
                        where dg_ente       = @i_ente
                        and   dg_direccion  = @i_direccion
                        	and   dg_tipo       = 'DF'
                        
                       if @@error != 0
                          begin
                             exec sp_cerror
                                -- ERROR EN INGRESO DE DATOS DE GEOREFERENCIACION
                                @t_debug   = @t_debug,
                                @t_file      = @t_file,
                                @t_from      = @w_sp_name,
                                @i_num      = 1720269
                             return 1
                           end

                    -- TRANSACCION DE SERVICIOS DATOS PREVIOS
                    insert into ts_direccion_geo (
                       secuencia,       tipo_transaccion, clase,            fecha,
                       oficina_s,       usuario,          terminal_s,       srv, 
                       lsrv,            hora,             ente,             direccion,
                       latitud_coord,   latitud_grados,   latitud_minutos,  latitud_segundos,
                       longitud_coord,  longitud_grados,  longitud_minutos, longitud_segundos,
                       path_croquis)
                    values (
                       @s_ssn,          172047,            'P',               @s_date,
                       @s_ofi,          @s_user,          @s_term,          @s_srv, 
                       @s_lsrv,         getdate(),        @i_ente,          @i_direccion,
                       @v_lat_coord,    @v_lat_grados,    @v_lat_minutos,   @v_lat_segundos,
                       @v_lon_coord,    @v_lon_grados,    @v_lon_minutos,   @v_lon_segundos,
                       @v_path_croquis)
               
                    if @@error <> 0
                       begin
                          -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIO'
                          exec sp_cerror
                          @t_debug = @t_debug,
                          @t_file  = @t_file,
                          @t_from  = @w_sp_name,
                          @i_num   = 1720049
                       return 1
                    end

                    -- TRANSACCION DE SERVICIOS DATOS ACTUALIZADOS
                    insert into ts_direccion_geo (
                       secuencia,       tipo_transaccion, clase,            fecha,
                       oficina_s,       usuario,          terminal_s,       srv, 
                       lsrv,            hora,             ente,             direccion,
                       latitud_coord,   latitud_grados,   latitud_minutos,  latitud_segundos,
                       longitud_coord,  longitud_grados,  longitud_minutos, longitud_segundos,
                       path_croquis)
                    values (
                       @s_ssn,          172047,            'A',               @s_date,
                       @s_ofi,          @s_user,          @s_term,          @s_srv, 
                       @s_lsrv,         getdate(),        @i_ente,          @i_direccion,
                       @w_lat_coord,    @w_lat_grados,    @w_lat_minutos,   @w_lat_segundos,
                       @w_lon_coord,    @w_lon_grados,    @w_lon_minutos,   @w_lon_segundos,
                       @w_path_croquis)
               
                    if @@error <> 0
                       begin
                          -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIO'
                          exec sp_cerror
                          @t_debug = @t_debug,
                          @t_file  = @t_file,
                          @t_from  = @w_sp_name,
                          @i_num   = 1720049
                       return 1
                    end

                       
                  commit tran
                  return 0
               end
            else
               begin
                  begin tran
                     -- INSERT cl_direccion_geo
                     --secuencial
                     exec sp_cseqnos
                          @t_debug    = @t_debug,
                          @t_file     = @t_file,
                          @t_from     = @w_sp_name,
                          @i_tabla    = 'cl_direccion_geo',
                          @o_siguiente= @o_secuencial out

                     insert into cl_direccion_geo 
                        (dg_ente,        dg_direccion,    dg_lat_coord,  dg_lat_grad, 
                        dg_lat_min,     dg_lat_seg,      dg_long_coord, dg_long_grad,
                        dg_long_min,    dg_long_seg,     dg_path_croquis, dg_secuencial,
                         dg_tipo)
                     values(@i_ente,        @i_direccion,    @i_lat_coord,  @i_lat_grados, 
                        @i_lat_minutos, @i_lat_segundos, @i_lon_coord,  @i_lon_grados,
                        @i_lon_minutos, @i_lon_segundos, @i_path_croquis,@o_secuencial,
                         @i_tipo)

                     if @@error != 0
                        begin
                           -- PENDIENTE
                           exec sp_cerror
                              -- 'ERROR EN CREACION DE PROVINCIA'
                              @t_debug = @t_debug,
                              @t_file  = @t_file,
                              @t_from  = @w_sp_name,
                              @i_num   = 1720270
                           return 1
                        end           

                     -- TRANSACCION DE SERVICIO     
                     -- VERIFICAR QUE EXISTA DIRECCION
                     select @w_lat_coord    = dg_lat_coord,
                        @w_lat_grados   = dg_lat_grad,
                        @w_lat_minutos  = dg_lat_min,
                        @w_lat_segundos = dg_lat_seg,
                        @w_lon_coord    = dg_long_coord,
                        @w_lon_grados   = dg_long_grad,
                        @w_lon_minutos  = dg_long_min,
                        @w_lon_segundos = dg_long_seg,
                        @w_path_croquis = dg_path_croquis
                     from  cl_direccion_geo
                     where dg_ente         = @i_ente
                     and   dg_direccion    = @i_direccion        
                     and   dg_tipo         = 'DF'

                     -- TRANSACCION DE SERVICIO CON DATOS NUEVOS
                    insert into ts_direccion_geo (
                       secuencia,       tipo_transaccion, clase,            fecha,
                       oficina_s,       usuario,          terminal_s,       srv, 
                       lsrv,            hora,             ente,             direccion,
                       latitud_coord,   latitud_grados,   latitud_minutos,  latitud_segundos,
                       longitud_coord,  longitud_grados,  longitud_minutos, longitud_segundos,
                       path_croquis)
                    values (
                       @s_ssn,          172047,            'N',               @s_date,
                       @s_ofi,          @s_user,          @s_term,          @s_srv, 
                       @s_lsrv,         getdate(),        @i_ente,          @i_direccion,
                       @i_lat_coord,    @i_lat_grados,    @i_lat_minutos,   @i_lat_segundos,
                       @i_lon_coord,    @i_lon_grados,    @i_lon_minutos,   @i_lon_segundos,
                       @i_path_croquis)
               
                    if @@error <> 0
                       begin
                          -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIO'
                          exec sp_cerror
                          @t_debug = @t_debug,
                          @t_file  = @t_file,
                          @t_from  = @w_sp_name,
                          @i_num   = 1720049
                       return 1
                    end
                  commit tran
                  return 0
               end
         end
 
         if   @i_tipo = 'RF' 
           begin
             -- VERIFICACION DE CLAVES FORANEAS       
            -- VERIFICACION SI EXISTE YA DATOS GEOR PARA LA DIRECCION ESPECIFICADA
            if exists(select 1 from cl_direccion_geo
                         where @i_ente      = dg_ente
                         and   @i_direccion = dg_direccion
                         and   @i_tipo      = 'RF')
               begin

                  -- CARGANDO LOS DATOS ANTERIORES DE LA GEOREFERENCIACION
                  select 
                     @w_lat_coord    = dg_lat_coord,
                     @w_lat_grados   = dg_lat_grad,
                     @w_lat_minutos  = dg_lat_min,
                     @w_lat_segundos = dg_lat_seg,
                     @w_lon_coord    = dg_long_coord,
                     @w_lon_grados   = dg_long_grad,
                     @w_lon_minutos  = dg_long_min,
                     @w_lon_segundos = dg_long_seg,
                     @w_path_croquis = dg_path_croquis
                  from  cl_direccion_geo
                  where dg_ente      = @i_ente
                  and   dg_direccion = @i_direccion
				  and   dg_tipo      = 'RF'

                  --GUARDANDO LOS DATOS ANTERIORES
                  select 
                     @v_lat_coord    = @w_lat_coord,
                     @v_lat_grados   = @w_lat_grados,
                     @v_lat_minutos  = @w_lat_minutos,
                     @v_lat_segundos = @w_lat_segundos,
                     @v_lon_coord    = @w_lon_coord,
                     @v_lon_grados   = @w_lon_grados,
                     @v_lon_minutos  = @w_lon_minutos,
                     @v_lon_segundos = @w_lon_segundos,
                     @v_path_croquis = @w_path_croquis

                  -- VERIFICANDO CAMBIOS EN LOS CAMPOS
                  if @w_lat_coord = @i_lat_coord
                    select @w_lat_coord = null, @v_lat_coord = null
                  else
                    select @w_lat_coord = @i_lat_coord

                  if @w_lat_grados = @i_lat_grados
                    select @w_lat_grados = null, @v_lat_grados = null
                  else
                    select @w_lat_grados = @i_lat_grados

                  if @w_lat_minutos = @i_lat_minutos
                    select @w_lat_minutos = null, @v_lat_minutos = null
                  else
                    select @w_lat_minutos = @i_lat_minutos

                  if @w_lat_segundos = @i_lat_segundos
                    select @w_lat_segundos = null, @v_lat_segundos = null
                  else
                    select @w_lat_segundos = @i_lat_segundos

                  if @w_lon_coord = @i_lon_coord
                    select @w_lon_coord = null, @v_lon_coord = null
                  else
                    select @w_lon_coord = @i_lon_coord

                  if @w_lon_grados = @i_lon_grados
                    select @w_lon_grados = null, @v_lon_grados = null
                  else
                    select @w_lon_grados = @i_lon_grados

                  if @w_lon_minutos = @i_lon_minutos
                    select @w_lon_minutos = null, @v_lon_minutos = null
                  else
                    select @w_lon_minutos = @i_lon_minutos

                  if @w_lon_segundos = @i_lon_segundos
                    select @w_lon_segundos = null, @v_lon_segundos = null
                  else
                    select @w_lon_segundos = @i_lon_segundos

                  if @w_path_croquis = @i_path_croquis
                    select @w_path_croquis = null, @v_path_croquis = null
                  else
                    select @w_path_croquis = @i_path_croquis

                  begin tran
                     --SE ACTUALIZAN LOS DATOS
                     update  cl_direccion_geo 
                        set dg_ente           = @i_ente,
                            dg_direccion      = @i_direccion,
                            dg_lat_coord      = @i_lat_coord,
                            dg_lat_grad       = @i_lat_grados, 
                            dg_lat_min        = @i_lat_minutos,   
                            dg_lat_seg        = @i_lat_segundos,     
                            dg_long_coord     = @i_lon_coord,
                            dg_long_grad      = @i_lon_grados,
                            dg_long_min       = @i_lon_minutos,
                            dg_long_seg       = @i_lon_segundos,
                            dg_path_croquis   = isnull(@i_path_croquis, dg_path_croquis)
                        where dg_ente       = @i_ente
                        and   dg_direccion  = @i_direccion
                        and   dg_tipo       = 'RF'
                        
                       if @@error != 0
                          begin
                             exec sp_cerror
                                -- ERROR EN INGRESO DE DATOS DE GEOREFERENCIACION
                                @t_debug   = @t_debug,
                                @t_file      = @t_file,
                                @t_from      = @w_sp_name,
                                @i_num      = 1720269
                             return 1
                           end

                    -- TRANSACCION DE SERVICIOS DATOS PREVIOS
                    insert into ts_direccion_geo (
                       secuencia,       tipo_transaccion, clase,            fecha,
                       oficina_s,       usuario,          terminal_s,       srv, 
                       lsrv,            hora,             ente,             direccion,
                       latitud_coord,   latitud_grados,   latitud_minutos,  latitud_segundos,
                       longitud_coord,  longitud_grados,  longitud_minutos, longitud_segundos,
                       path_croquis)
                    values (
                       @s_ssn,          172047,            'P',               @s_date,
                       @s_ofi,          @s_user,          @s_term,          @s_srv, 
                       @s_lsrv,         getdate(),        @i_ente,          @i_direccion,
                       @v_lat_coord,    @v_lat_grados,    @v_lat_minutos,   @v_lat_segundos,
                       @v_lon_coord,    @v_lon_grados,    @v_lon_minutos,   @v_lon_segundos,
                       @v_path_croquis)
               
                    if @@error <> 0
                       begin
                          -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIO'
                          exec sp_cerror
                          @t_debug = @t_debug,
                          @t_file  = @t_file,
                          @t_from  = @w_sp_name,
                          @i_num   = 1720049
                       return 1
                    end

                    -- TRANSACCION DE SERVICIOS DATOS ACTUALIZADOS
                    insert into ts_direccion_geo (
                       secuencia,       tipo_transaccion, clase,            fecha,
                       oficina_s,       usuario,          terminal_s,       srv, 
                       lsrv,            hora,             ente,             direccion,
                       latitud_coord,   latitud_grados,   latitud_minutos,  latitud_segundos,
                       longitud_coord,  longitud_grados,  longitud_minutos, longitud_segundos,
                       path_croquis)
                    values (
                       @s_ssn,          172047,            'A',               @s_date,
                       @s_ofi,          @s_user,          @s_term,          @s_srv, 
                       @s_lsrv,         getdate(),        @i_ente,          @i_direccion,
                       @w_lat_coord,    @w_lat_grados,    @w_lat_minutos,   @w_lat_segundos,
                       @w_lon_coord,    @w_lon_grados,    @w_lon_minutos,   @w_lon_segundos,
                       @w_path_croquis)
               
                    if @@error <> 0
                       begin
                          -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIO'
                          exec sp_cerror
                          @t_debug = @t_debug,
                          @t_file  = @t_file,
                          @t_from  = @w_sp_name,
                          @i_num   = 1720049
                       return 1
                    end

                       
                  commit tran
                  return 0
               end
            else
               begin
                  begin tran
                     -- INSERT cl_direccion_geo
                     --secuencial
                     exec sp_cseqnos
                          @t_debug    = @t_debug,
                          @t_file     = @t_file,
                          @t_from     = @w_sp_name,
                          @i_tabla    = 'cl_direccion_geo',
                          @o_siguiente= @o_secuencial out

                     insert into cl_direccion_geo 
                        (dg_ente,        dg_direccion,    dg_lat_coord,  dg_lat_grad, 
                        dg_lat_min,     dg_lat_seg,      dg_long_coord, dg_long_grad,
                        dg_long_min,    dg_long_seg,     dg_path_croquis, dg_secuencial,
                        dg_tipo)
                     values(@i_ente,        @i_direccion,    @i_lat_coord,  @i_lat_grados, 
                        @i_lat_minutos, @i_lat_segundos, @i_lon_coord,  @i_lon_grados,
                        @i_lon_minutos, @i_lon_segundos, @i_path_croquis,@o_secuencial,
                        @i_tipo)

                     if @@error != 0
                        begin
                           -- PENDIENTE
                           exec sp_cerror
                              -- 'ERROR EN CREACION DE PROVINCIA'
                              @t_debug = @t_debug,
                              @t_file  = @t_file,
                              @t_from  = @w_sp_name,
                              @i_num   = 1720270
                           return 1
                        end           

                     -- TRANSACCION DE SERVICIO     
                     -- VERIFICAR QUE EXISTA DIRECCION
                     select @w_lat_coord    = dg_lat_coord,
                        @w_lat_grados   = dg_lat_grad,
                        @w_lat_minutos  = dg_lat_min,
                        @w_lat_segundos = dg_lat_seg,
                        @w_lon_coord    = dg_long_coord,
                        @w_lon_grados   = dg_long_grad,
                        @w_lon_minutos  = dg_long_min,
                        @w_lon_segundos = dg_long_seg,
                        @w_path_croquis = dg_path_croquis
                     from  cl_direccion_geo
                     where dg_ente         = @i_ente
                     and   dg_direccion    = @i_direccion        
                     and   dg_tipo         = 'RF'					 

                     -- TRANSACCION DE SERVICIO CON DATOS NUEVOS
                    insert into ts_direccion_geo (
                       secuencia,       tipo_transaccion, clase,            fecha,
                       oficina_s,       usuario,          terminal_s,       srv, 
                       lsrv,            hora,             ente,             direccion,
                       latitud_coord,   latitud_grados,   latitud_minutos,  latitud_segundos,
                       longitud_coord,  longitud_grados,  longitud_minutos, longitud_segundos,
                       path_croquis)
                    values (
                       @s_ssn,          172047,            'N',               @s_date,
                       @s_ofi,          @s_user,          @s_term,          @s_srv, 
                       @s_lsrv,         getdate(),        @i_ente,          @i_direccion,
                       @i_lat_coord,    @i_lat_grados,    @i_lat_minutos,   @i_lat_segundos,
                       @i_lon_coord,    @i_lon_grados,    @i_lon_minutos,   @i_lon_segundos,
                       @i_path_croquis)
               
                    if @@error <> 0
                       begin
                          -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIO'
                          exec sp_cerror
                          @t_debug = @t_debug,
                          @t_file  = @t_file,
                          @t_from  = @w_sp_name,
                          @i_num   = 1720049
                       return 1
                    end
                  commit tran
                  return 0
               end
             end 

         end
      else
         begin
            exec sp_cerror
               -- 'NO CORRESPONDE CODIGO DE TRANSACCION'
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 1720075
            return 1
         end
   end
else
 -- DELETE
if @i_operacion = 'D'
   begin
      if @t_trn = 172080 -- PENDIENTE
         begin
          if   @i_tipo = 'DF'
            begin 
            -- VERIFICACION DE CLAVES FORANEAS     
            begin tran
               delete from cl_direccion_geo
               where @i_ente      = dg_ente
               and   @i_direccion = dg_direccion
                and   dg_tipo      = 'DF'
            
               if @@error <> 0
                  begin
                     exec cobis..sp_cerror 
                        @t_debug= @t_debug,
                        @t_file = @t_file,
                        @t_from = @w_sp_name,
                        @i_num  = 1720204  
                     return 1
                  end
               
               -- VERIFICAR QUE EXISTA DIRECCION
               select @w_lat_coord    = dg_lat_coord,
                  @w_lat_grados   = dg_lat_grad,
                  @w_lat_minutos  = dg_lat_min,
                  @w_lat_segundos = dg_lat_seg,
                  @w_lon_coord    = dg_long_coord,
                  @w_lon_grados   = dg_long_grad,
                  @w_lon_minutos  = dg_long_min,
                  @w_lon_segundos = dg_long_seg,
                  @w_path_croquis = dg_path_croquis
               from  cl_direccion_geo, cl_direccion, cl_ente
               where dg_ente         = di_ente
               and   dg_direccion    = di_direccion
               and   di_ente         = en_ente
                and   dg_tipo         = 'DF'              
                              
               -- TRANSACCION DE SERVICIO - DIRECCION                
               insert into ts_direccion_geo (
                  secuencia,       tipo_transaccion, clase,            fecha,
                  oficina_s,       usuario,          terminal_s,       srv, 
                  lsrv,            hora,             ente,             direccion,
                  latitud_coord,   latitud_grados,   latitud_minutos,  latitud_segundos,
                  longitud_coord,  longitud_grados,  longitud_minutos, longitud_segundos,
                  path_croquis)
               values (
                  @s_ssn,          172080,            'B',               @s_date,
                  @s_ofi,          @s_user,          @s_term,          @s_srv, 
                  @s_lsrv,         getdate(),        @i_ente,          @i_direccion,
                  @w_lat_coord,    @w_lat_grados,    @w_lat_minutos,   @w_lat_segundos,
                  @w_lon_coord,    @w_lon_grados,    @w_lon_minutos,   @w_lon_segundos,
                  @w_path_croquis)
               
               if @@error <> 0
                  begin
                     -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIO'
                     exec sp_cerror
                        @t_debug = @t_debug,
                        @t_file  = @t_file,
                        @t_from  = @w_sp_name,
                        @i_num   = 1720049
                     return 1
                  end
            commit tran         
            return 0
         end
   end
 
            if   @i_tipo = 'RF' 
               begin
                  -- VERIFICACION DE CLAVES FORANEAS     
               begin tran
               delete from cl_direccion_geo
               where @i_ente      = dg_ente
               and   @i_direccion = dg_direccion
               and   dg_tipo      = 'RF'
            
               if @@error <> 0
                  begin
                     exec cobis..sp_cerror 
                        @t_debug= @t_debug,
                        @t_file = @t_file,
                        @t_from = @w_sp_name,
                        @i_num  = 1720204  
                     return 1
                  end
               
               -- VERIFICAR QUE EXISTA DIRECCION
               select @w_lat_coord    = dg_lat_coord,
                      @w_lat_grados   = dg_lat_grad,
                      @w_lat_minutos  = dg_lat_min,
                      @w_lat_segundos = dg_lat_seg,
                      @w_lon_coord    = dg_long_coord,
                      @w_lon_grados   = dg_long_grad,
                      @w_lon_minutos  = dg_long_min,
                      @w_lon_segundos = dg_long_seg,
                      @w_path_croquis = dg_path_croquis
               from  cl_direccion_geo, cl_direccion, cl_ente
               where dg_ente         = di_ente
               and   dg_direccion    = di_direccion
               and   di_ente         = en_ente
               and   dg_tipo         = 'RF'
                              
               -- TRANSACCION DE SERVICIO - DIRECCION                
               insert into ts_direccion_geo (
                  secuencia,       tipo_transaccion, clase,            fecha,
                  oficina_s,       usuario,          terminal_s,       srv, 
                  lsrv,            hora,             ente,             direccion,
                  latitud_coord,   latitud_grados,   latitud_minutos,  latitud_segundos,
                  longitud_coord,  longitud_grados,  longitud_minutos, longitud_segundos,
                  path_croquis)
               values (
                  @s_ssn,          172080,            'B',               @s_date,
                  @s_ofi,          @s_user,          @s_term,          @s_srv, 
                  @s_lsrv,         getdate(),        @i_ente,          @i_direccion,
                  @w_lat_coord,    @w_lat_grados,    @w_lat_minutos,   @w_lat_segundos,
                  @w_lon_coord,    @w_lon_grados,    @w_lon_minutos,   @w_lon_segundos,
                  @w_path_croquis)
               
               if @@error <> 0
                  begin
                     -- 'ERROR EN CREACION DE TRANSACCION DE SERVICIO'
                     exec sp_cerror
                        @t_debug = @t_debug,
                        @t_file  = @t_file,
                        @t_from  = @w_sp_name,
                        @i_num   = 1720049
                     return 1
                  end
            commit tran         
            return 0
         end
  

   end
else
   begin
      exec sp_cerror
         -- 'NO CORRESPONDE CODIGO DE TRANSACCION'
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_num      = 1720075,
		 @s_culture  = @s_culture
      return 1
   end

return 0

GO
