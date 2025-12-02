/************************************************************************/
/*  Archivo:                valida_grupo.sp                             */
/*  Stored procedure:       sp_valida_grupo                             */
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

if exists (select 1 from sysobjects where name = 'sp_valida_grupo' and type = 'P')
   drop proc sp_valida_grupo
go


create proc sp_valida_grupo (
    @t_show_version         bit         = 0,
    @t_trn                  smallint    = null,
    @i_operacion            char(1),            -- Opcion con que se ejecuta el programa 
    @i_grupo                int         = null  -- Codigo del grupo 
)
as
declare @w_sp_name            varchar(64),
        @w_actualiza        varchar(1) 

-------------------------------- VERSIONAMIENTO DE SP --------------------------------
if @t_show_version = 1
begin
    print 'Stored procedure sp_valida_grupo, Version 1.0.0.0'
    return 0
end
--------------------------------------------------------------------------------------
select @w_sp_name   = 'sp_valida_grupo',
       @w_actualiza = 'S'

--Consulta si un grupo esta atado a una solicitud en curso   
if @i_operacion = 'Q'
begin
    --Valida que no exista una solicitud en curso
    if exists (SELECT 1 FROM cob_workflow..wf_inst_proceso
                WHERE io_campo_1 = @i_grupo
                  AND io_estado not in ('TER', 'CAN', 'SUS', 'ELI'))
    begin
        select @w_actualiza = 'N'
    end
    select @w_actualiza  
end -- Fin Operacion Q

return 0

GO
