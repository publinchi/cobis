/************************************************************************/
/*  Archivo:                sp_valida_flujo_individual_wf.sp            */
/*  Stored procedure:       sp_valida_flujo_individual_wf               */
/*  Base de Datos:          cob_workflow                                */
/*  Producto:               Credito                                     */
/*  Disenado por:           Paúl Moreno                                 */
/*  Fecha de Documentacion: 17/Ene/2022                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Valida que un ciente no este en listas negras para originar         */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*   FECHA     AUTOR      RAZON                                         */
/*  17/01/2022 pmoreno   Emisión inicial                                */
/* **********************************************************************/

USE cob_workflow
go
IF OBJECT_ID ('dbo.sp_valida_flujo_individual_wf') IS NOT NULL
	DROP PROCEDURE dbo.sp_valida_flujo_individual_wf
GO

CREATE PROCEDURE sp_valida_flujo_individual_wf
(
    @s_ssn                int          = null,
    @s_user               varchar(30)  = null,
    @s_sesn               int          = null,
    @s_term               varchar(30)  = null,
    @s_date               datetime     = null,
    @s_srv                varchar(30)  = null,
    @s_lsrv               varchar(30)  = null,
    @s_ofi                smallint     = null,
    @t_trn                int          = null,
    @t_debug              char(1)      = 'N',
    @t_file               varchar(14)  = null,
    @t_from               varchar(30)  = null,
    @s_rol                smallint     = null,
    @s_org_err            char(1)      = null,
    @s_error              int          = null,
    @s_sev                tinyint      = null,
    @s_msg                descripcion  = null,
    @s_org                char(1)      = null,
    @t_show_version       bit          = 0, -- Mostrar la version del programa
    @t_rty                char(1)      = null,        
    @i_operacion          char(1)      = 'I',
    @i_login              NOMBRE       = null,
    @i_id_proceso         smallint     = null,
    @i_version            smallint     = null,
    @i_nombre_proceso     NOMBRE       = null,
    @i_id_actividad       int          = null,
    @i_campo_1            int          = null,
    @i_campo_2            varchar(255) = null,
    @i_campo_3            int          = null,
    @i_campo_4            varchar(10)  = null,
    @i_campo_5            int          = null,
    @i_campo_6            money        = null,  
    @i_campo_7            varchar(255) = null,
    @i_ruteo              char(1)      = 'M',
    @i_ofi_inicio         smallint     = null,
    @i_ofi_entrega        smallint     = null,
    @i_ofi_asignacion     smallint     = null,
    @i_id_inst_act_padre  int          = null,
    @i_comentario         varchar(255) = null,
    @i_id_usuario         int          = null,
    @i_id_rol             int          = null,
    @i_id_empresa         smallint     = null,
    @i_inst_padre         int          = null,
    @i_inst_inmediato     int          = null,
    @o_siguiente          int          = null out

)As 
declare @w_sp_name varchar(25),
		@w_return  int,
		@w_error   int,
		@w_ente    int
		
	select @w_sp_name = 'sp_valida_flujo_individual_wf'
	--PRINT 'Cliente:' + convert(VARCHAR,@i_campo_1)
	--PRINT 'Producto:' + convert(VARCHAR,@i_campo_4)
	if @i_campo_1 is not null 
	begin
		if @i_campo_4 is null
		begin
			if exists (select 1 from cobis..cl_ente where en_ente = @i_campo_1 and en_estado = 'S')
			begin
				select en_ente from cobis..cl_ente where en_ente = @i_campo_1 and en_estado = 'S'
			end
			else
			begin	
				select en_ente = 0
			end
		end
		else
		begin
			if exists (select 1 from cobis..cl_ente where en_ente = @i_campo_1 and en_estado = 'S')
			begin
				select @w_error  = 70011006
				goto ERROR
			end
		end 
     end                 
return 0

ERROR:
    begin --Devolver mensaje de Error

        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = @w_error
        return @w_error
    end
go
