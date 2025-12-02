/************************************************************************/
/*  Archivo:                actividad_sincroniza.sp                     */
/*  Stored procedure:       sp_actividad_sincroniza                     */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_actividad_sincroniza' and type = 'P')
   drop proc sp_actividad_sincroniza
go


CREATE proc sp_actividad_sincroniza (
    @s_ssn                  int             = null,
    @s_sesn                 int             = null,
    @s_culture              varchar(10)     = null,
    @s_user                 login           = null,
    @s_term                 varchar(30)     = null,
    @s_date                 datetime        = null,
    @s_srv                  varchar(30)     = null,
    @s_lsrv                 varchar(30)     = null,
    @s_ofi                  smallint        = null,
    @s_rol                  smallint        = NULL,
    @s_org_err              char(1)         = NULL,
    @s_error                int             = NULL,
    @s_sev                  tinyint         = NULL,
    @s_msg                  descripcion     = NULL,
    @s_org                  char(1)         = NULL,
    @t_show_version         bit             = 0,    -- Mostrar la version del programa
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  smallint        = null,
    @i_operacion            char(1),
    @i_tramite              int             = null,
	@i_nombre_actividad     varchar(50)     = null,
	@i_sincroniza           char(1)         = null	
)
as
declare
    @w_siguiente                int,
    @w_return                   int,
    @w_num_cl_gr                int,
    @w_contador                 int,
    @w_sp_name                  varchar(32),
    @w_error                    int,
    @w_ente                     int,
    @w_respuestas               varchar(200),
    @w_resultado                int,
    @w_actualizar               char(1),	
	@w_toperacion               catalogo,
	@w_id_inst_proc             int,
	@w_nombre_actividad_up      varchar (50)
	

SELECT @w_nombre_actividad_up = UPPER(@i_nombre_actividad)
		
-------------------------------- VERSIONAMIENTO DE SP --------------------------------
if @t_show_version = 1
begin
    print 'Stored procedure sp_actividad_sincroniza, Version 1.0.0.0'
    return 0
end
--------------------------------------------------------------------------------------
select @w_sp_name = 'sp_actividad_sincroniza'

if @t_trn <> 2174
begin
    select @w_error = 151051 -- TRANSACCION NO PERMITIDA
    goto ERROR
end

select @w_id_inst_proc = isnull(io_id_inst_proc,0)
FROM cob_workflow..wf_inst_proceso
WHERE io_campo_3 = @i_tramite

SELECT @w_toperacion = op_toperacion
FROM cob_cartera..ca_operacion OP WHERE op_tramite = @i_tramite

if(@w_nombre_actividad_up NOT  LIKE  '%INGRES%')
begin 
    if(@w_toperacion = 'GRUPAL')
        SELECT @i_nombre_actividad = 'APLICAR CUESTIONARIO - GRP'
    
    if(@w_toperacion = 'INDIVIDUAL')
        SELECT @i_nombre_actividad = 'APLICAR CUESTIONARIO - IND'
end
	
if @i_operacion = 'I'
begin
    if not exists(select 1 from cr_tr_sincronizar where ti_tramite = @i_tramite and ti_seccion = @i_nombre_actividad)
	begin
        insert into cr_tr_sincronizar (ti_tramite,  ti_seccion,          ti_sincroniza) 
	    values                        (@i_tramite,  @i_nombre_actividad, NULL)	
	    
        if @@error <> 0
        begin
	        select @w_error = 2103001  --Error en insercion de registro
            goto ERROR
        end	
	end
	else
	begin
        if @@error <> 0
        begin
	        select @w_error = 2101002  --Registro ya existe
            goto ERROR
        end		
	end
end

if @i_operacion = 'U'
begin
		
    if exists(select 1 from cr_tr_sincronizar where  ti_tramite = @i_tramite and ti_seccion = @i_nombre_actividad)
	begin
        update cr_tr_sincronizar 
	    set    ti_sincroniza = @i_sincroniza
	    where  ti_tramite    = @i_tramite
	    and    ti_seccion    = @i_nombre_actividad	
        if @@error <> 0
        begin
	        select @w_error = 2103057  --Error en Actualizacion de Registro
            goto ERROR
        end			
	end
	else
	begin
        select @w_error = 2101005      --Registro No existe
        goto ERROR
	end
end

if @i_operacion = 'Q'
begin
    select 'sincroniza' = ti_sincroniza,
	       'seccion'    = ti_seccion
	from cob_credito..cr_tr_sincronizar
	where ti_tramite = @i_tramite
	and   ti_seccion = @i_nombre_actividad
end

return 0

ERROR:
    begin --Devuelve mensaje de Error
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = @w_error
        return @w_error
    end

GO
