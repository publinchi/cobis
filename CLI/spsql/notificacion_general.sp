/************************************************************************/
/*  Archivo:                notificacion_general.sp                     */
/*  Stored procedure:       sp_notificacion_general                     */
/*  Base de Datos:          cobis                                       */
/*  Producto:               Clientes                                    */
/*  Disenado por:           JMEG                                        */
/*  Fecha de escritura:     30-Abril-19                                 */
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
/*          PROPOSITO                                                   */
/* Permite realizar el mantenimiento de los dispositivos mÃ³viles,      */
/* Insertar, actualizar, eliminar y consultar                           */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      30/04/19         JMEG         Emision Inicial                   */
/*      25/06/20         FSAP         Estandarizacion clientes          */
/************************************************************************/

use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
             from sysobjects 
            where name = 'sp_notificacion_general')
   drop proc sp_notificacion_general 
go

create proc sp_notificacion_general (
   @s_ssn             int         = null,
   @s_user            login       = null,
   @s_term            varchar(32) = null,
   @s_date            datetime    = null,
   @s_sesn            int         = null,
   @s_culture         varchar(10) = null,
   @s_srv             varchar(30) = null,
   @s_lsrv            varchar(30) = null,
   @s_ofi             smallint    = null,
   @s_rol             smallint    = null,
   @s_org_err         char(1)     = null,
   @s_error           int         = null,
   @s_sev             tinyint     = null,
   @s_msg             descripcion = null,
   @s_org             char(1)     = null,
   @t_debug           char(1)     = 'N',
   @t_file            varchar(10) = null,
   @t_from            varchar(32) = null,
   @t_trn             int         = null,
   @t_show_version    bit         = 0,
   @i_operacion       char(1),
   @i_mensaje        varchar(1000)= null,
   @i_correo          varchar(60) = null,
   @i_asunto          varchar(255)= null,
   @i_origen          char(1)     = null,
   @i_tramite         int         = null   
   
)as
declare 
   @w_ts_name         varchar(32),
   @w_num_error       int,
   @w_sp_name         varchar(32),
   @w_sp_msg          varchar(132),
   @w_codigo          int,
   @w_mensaje         varchar(1000),
   @w_correo          varchar(60),
   @w_asunto          varchar(255)
   
select @w_sp_name = 'sp_notificacion_general'

-------------- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
     

if @i_operacion = 'I'
begin
    begin tran
    exec @w_num_error = cobis..sp_cseqnos
        @t_debug     = @t_debug,
        @t_file      = @t_file,
        @t_from      = @w_sp_name,
        @i_tabla     = 'cl_notificacion_general',
        @o_siguiente = @w_codigo out
        

        if @w_num_error <> 0
        begin
            select @w_num_error = 1720280 --NO EXISTE TABLA EN TABLA DE SECUENCIALES
            goto errores
        end
    
    --Inserto notificacion
    if exists (select 1 from cl_notificacion_general where ng_codigo = @w_codigo)
  begin
   select @w_num_error = 1720292 --Error al insertar Notificación General 
   goto errores
  end
    insert into cobis..cl_notificacion_general(
      ng_codigo,    ng_mensaje,     ng_correo,      ng_asunto,
      ng_origen,      ng_tramite)
    values(
      @w_codigo,      @i_mensaje,         @i_correo,      @i_asunto,
      @i_origen,      @i_tramite)
    if @@error <> 0
  begin
   select @w_num_error = 1720292 --Error al insertar Notificación General 
   goto errores
  end
 
    --Inserto registro de estado
    if exists (select 1 from cl_ns_generales_estado where nge_codigo = @w_codigo)
  begin
   select @w_num_error = 1720293 --Error al insertar estado de Notificación General 
   goto errores
  end
    
    insert into cobis..cl_ns_generales_estado(
      nge_codigo,   nge_estado)
    values(
      @w_codigo,      'P') --P = Pendiente
    if @@error <> 0
  begin
   select @w_num_error = 1720293 --Error al insertar estado de Notificación General 
   goto errores
  end
    
    commit tran
  
    goto fin
end

--Control errores
errores:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_num_error
   return @w_num_error
fin:
   return 0

go

