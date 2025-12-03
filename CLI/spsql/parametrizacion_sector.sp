/************************************************************************/
/*  Archivo:                parametrizacion_sector.sp                   */
/*  Stored procedure:       sp_parametrizacion_sector                   */
/*  Producto:               Clientes                                    */
/*  Disenado por:           Bruno Duenas                                */
/*  Fecha de escritura:     08-11-2021                                  */
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
/*               PROPOSITO                                              */
/*   Este programa se utiliza para la parametrizacion de sector,        */
/*   subsector, actividad y subactividad                                */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA       AUTOR           RAZON                                   */
/*  08-11-2021  BDU             Emision inicial                         */
/************************************************************************/


use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go
if exists (select 1 from sysobjects where name = 'sp_parametrizacion_sector')
   drop proc sp_parametrizacion_sector
go

create proc sp_parametrizacion_sector (
    @s_culture                  varchar(10)     = 'NEUTRAL',
    @s_ssn                      int             = null,
    @s_sesn                     int             = null,
    @s_user                     login           = null,
    @s_term                     varchar(30)     = null,
    @s_date                     datetime        = null,
    @s_srv                      varchar(30)     = null,
    @s_lsrv                     varchar(30)     = null,
    @s_ofi                      smallint        = null,
    @s_rol                      smallint        = null,
    @s_org_err                  char(1)         = null,
    @s_error                    int             = null,
    @s_sev                      tinyint         = null,
    @s_msg                      descripcion     = null,
    @s_org                      char(1)         = null,
    @t_show_version             bit             = 0,    -- Mostrar la version del programa
    @t_debug                    char(1)         = 'N',
    @t_file                     varchar(10)     = null,
    @t_from                     varchar(32)     = null,
    @t_trn                      int             = null,
    @i_operacion                char(1),                -- Opcion con que se ejecuta el programa
    @i_tipo                     char(2)         = null,
    @i_descripcion              varchar(300)    = null,
    @i_estado                   char(1)         = null,
    @i_fuente_ingresos          varchar(10)     = null,
    @i_sensitiva                char(1)         = null,
    @i_codSector                varchar(10)     = null,
    @i_codActividad             varchar(10)     = null,
    @i_codSubSector             varchar(10)     = null,
    @i_codSubActividad          varchar(10)     = null
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_trn_dir               int,
        @w_error                 int,
        @w_valor_campo           varchar(30),
        @w_ttrn                  int
        
        
        
/* INICIAR VARIABLES DE TRABAJO  */
select @w_sp_name          = 'cobis..sp_parametrizacion_sector'
   
/* VALIDACIONES */

/* NUMERO DE TRANSACCION */
if @t_trn <>  172221
begin 
   /* Tipo de transaccion no corresponde */ 
   select @w_error = 1720275 
   goto ERROR_FIN
end
if(@i_operacion = 'Q')
begin
   if @i_tipo = 'S'
   begin
      select 'Codigo'          = se_codigo,
             'Descripcion'     = se_descripcion,
             'Estado'          = se_estado,
             'Fuente Ingresos' = se_codFuentIng
      from cl_sector_economico
   end
   if @i_tipo = 'SU'
   begin
      select 'Codigo'          = se_codigo,
             'Descripcion'     = se_descripcion,
             'Estado'          = se_estado,
             'Sector'          = se_codSector
      from cl_subsector_ec where se_codSector = @i_codSector
   end
   if @i_tipo = 'A'
   begin
      select 'Codigo'          = ac_codigo,
             'Descripcion'     = ac_descripcion,
             'Estado'          = ac_estado,
             'Sensitiva'       = ac_sensitiva,
             'SubSector'       = ac_codSubsector
      from cl_actividad_ec where ac_codSubsector = @i_codSubSector
   end
   if @i_tipo = 'SA'
   begin
      select 'Codigo'          = se_codigo,
             'Descripcion'     = se_descripcion,
             'Estado'          = se_estado,
             'Actividad'       = se_codActEc
      from cl_subactividad_ec where se_codActEc = @i_codActividad
   end
end

if(@i_operacion = 'I')
begin
   if @i_tipo = 'S'
   begin
      if exists(select 1 from cl_sector_economico where se_codigo = @i_codSector)
      begin
         select @w_error = 1720589
         goto ERROR_FIN
      end
      insert into cl_sector_economico([se_codigo],     [se_descripcion]
                                     ,[se_estado],     [se_codFuentIng])
                                values(@i_codSector,   @i_descripcion, 
                                       @i_estado,      @i_fuente_ingresos)
      if @@error != 0
      begin
         select @w_error = 1720581
         goto ERROR_FIN
      end
   end
   if @i_tipo = 'SU'
   begin
      if exists(select 1 from cl_subsector_ec where se_codigo = @i_codSubSector)
      begin
         select @w_error = 1720590
         goto ERROR_FIN
      end
      if not exists(select 1 from cl_sector_economico where se_codigo = @i_codSector)
      begin
         select @w_error = 1720276
         goto ERROR_FIN
      end
      if not exists(select 1 from cl_sector_economico where se_codigo = @i_codSector and se_estado = 'V')
      begin
         select @w_error = 1720593
         goto ERROR_FIN
      end
      insert into cl_subsector_ec([se_codigo],        [se_descripcion]
                                 ,[se_estado],        [se_codSector])
                            values(@i_codSubSector,   @i_descripcion, 
                                   @i_estado,         @i_codSector)
      if @@error != 0
      begin
         /* Error en creacion */
         select @w_error = 1720582
         goto ERROR_FIN
      end
   end
   if @i_tipo = 'A'
   begin
      if exists(select 1 from cl_actividad_ec where ac_codigo = @i_codActividad)
      begin
         select @w_error = 1720591
         goto ERROR_FIN
      end
      if not exists(select 1 from cl_subsector_ec where se_codigo = @i_codSubSector)
      begin
         select @w_error = 1720278
         goto ERROR_FIN
      end
      if not exists(select 1 from cl_subsector_ec where se_codigo = @i_codSubSector and se_estado = 'V')
      begin
         select @w_error = 1720594
         goto ERROR_FIN
      end
      insert into cl_actividad_ec([ac_codigo],     [ac_descripcion], [ac_sensitiva]
                                 ,[ac_estado],     [ac_codSubsector])
                            values(@i_codActividad,   @i_descripcion,   @i_sensitiva,
                                   @i_estado,      @i_codSubSector)
      if @@error != 0
      begin
         /* Error en creacion */
         select @w_error = 1720583
         goto ERROR_FIN
      end
   end
   if @i_tipo = 'SA'
   begin
      if exists(select 1 from cl_subactividad_ec where se_codigo = @i_codSubActividad)
      begin
         select @w_error = 1720592
         goto ERROR_FIN
      end
      if not exists(select 1 from cl_actividad_ec where ac_codigo = @i_codActividad)
      begin
         select @w_error = 1720135
         goto ERROR_FIN
      end
      if not exists(select 1 from cl_actividad_ec where ac_codigo = @i_codActividad and ac_estado = 'V')
      begin
         select @w_error = 1720595
         goto ERROR_FIN
      end
      insert into cl_subactividad_ec([se_codigo],          [se_descripcion], [se_codCaedge]
                                    ,[se_estado],          [se_codActEc])
                              values(@i_codSubActividad,   @i_descripcion,   @i_codActividad,
                                     @i_estado,            @i_codActividad)
      if @@error != 0
      begin
         /* Error en creacion */
         select @w_error = 1720584
         goto ERROR_FIN
      end
   end
end

if(@i_operacion = 'U')
begin
   if @i_tipo = 'S'
   begin
      if exists(select 1 from cl_subsector_ec where se_estado = 'V' and se_codSector = @i_codSector and @i_estado = 'C')
      begin
         select @w_error = 1720596
         goto ERROR_FIN
      end
      update cl_sector_economico set se_descripcion = isnull(@i_descripcion,se_descripcion), 
                                     se_estado      = isnull(@i_estado, se_estado),      
                                     se_codFuentIng = isnull(@i_fuente_ingresos, se_codFuentIng)
      where se_codigo = @i_codSector
      if @@error != 0
      begin
         /* Error en actualizacion */
         select @w_error = 1720585
         goto ERROR_FIN
      end
   end
   if @i_tipo = 'SU'
   begin
      if not exists(select 1 from cl_sector_economico where se_codigo = @i_codSector and se_estado = 'V')
      begin
         select @w_error = 1720593
         goto ERROR_FIN
      end
      if exists(select 1 from cl_actividad_ec where ac_estado = 'V' and ac_codSubsector = @i_codSubSector and @i_estado = 'C')
      begin
         select @w_error = 1720597
         goto ERROR_FIN
      end
      update cl_subsector_ec set se_descripcion = isnull(@i_descripcion, se_descripcion), 
                                 se_estado      = isnull(@i_estado, se_estado)
      where se_codigo    = @i_codSubSector
        and se_codSector = @i_codSector
      if @@error != 0
      begin
         /* Error en actualizacion */
         select @w_error = 1720586
         goto ERROR_FIN
      end
   end
   if @i_tipo = 'A'
   begin
      if not exists(select 1 from cl_subsector_ec where se_codigo = @i_codSubSector and se_estado = 'V')
      begin
         select @w_error = 1720594
         goto ERROR_FIN
      end
      if exists(select 1 from cl_subactividad_ec where se_estado = 'V' and se_codActEc = @i_codActividad and @i_estado = 'C')
      begin
         select @w_error = 1720598
         goto ERROR_FIN
      end
      update cl_actividad_ec set ac_descripcion  = isnull(@i_descripcion, ac_descripcion), 
                                 ac_estado       = isnull(@i_estado, ac_estado),      
                                 ac_sensitiva    = isnull(@i_sensitiva, ac_sensitiva)
      where ac_codigo       = @i_codActividad
        and ac_codSubsector = @i_codSubSector
      if @@error != 0
      begin
         /* Error en actualizacion */
         select @w_error = 1720587
         goto ERROR_FIN
      end
   end
   if @i_tipo = 'SA'
   begin
      if not exists(select 1 from cl_actividad_ec where ac_codigo = @i_codActividad and ac_estado = 'V')
      begin
         select @w_error = 1720595
         goto ERROR_FIN
      end
      update cl_subactividad_ec set se_descripcion = isnull(@i_descripcion, se_descripcion), 
                                    se_estado      = isnull(@i_estado, se_estado)
      where se_codigo   = @i_codSubActividad
        and se_codActEc = @i_codActividad
      if @@error != 0
      begin
         /* Error en actualizacion */
         select @w_error = 1720588
         goto ERROR_FIN
      end
   end
end

return 0 


ERROR_FIN:
   exec cobis..sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_msg      = @w_sp_msg,
            @i_num      = @w_error
            
   return @w_error

go
