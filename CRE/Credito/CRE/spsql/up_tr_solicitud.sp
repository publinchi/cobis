/************************************************************************/
/*  Archivo:                up_tr_solicitud.sp                          */
/*  Stored procedure:       sp_up_tr_solicitud                          */
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

if exists (select 1 from sysobjects where name = 'sp_up_tr_solicitud' and type = 'P')
   drop proc sp_up_tr_solicitud
go


create proc sp_up_tr_solicitud (
   @s_ssn                int           = null,
   @s_user               login         = null,
   @s_sesn               int           = null,
   @s_term               varchar(30)   = null,
   @s_date               datetime      = null,
   @s_srv                varchar(30)   = null,
   @s_lsrv               varchar(30)   = null,
   @s_ofi                smallint      = null,
   @t_trn                smallint      = 21020,
   @t_debug              char(1)       = 'N',
   @t_file               varchar(14)   = null,
   @t_from               varchar(30)   = NULL,
   @i_id_inst_proc       INT = NULL
  
)
as


declare
   @w_today           datetime,     -- FECHA DEL DIA
   @w_return          int,          -- VALOR QUE RETORNA
   @w_sp_name         varchar(32),  -- NOMBRE STORED PROC
   @w_tramite         int,
   @w_grupo           INT,
   @w_grupal          CHAR(1),
   @w_tramite_ant     INT,
   @w_tramite_ant_sol INT



select @w_sp_name = 'sp_up_tr_solicitud'

SELECT @w_grupal = io_campo_7,
       @w_tramite = io_campo_3
FROM cob_workflow..wf_inst_proceso
WHERE io_id_inst_proc = @i_id_inst_proc


if @w_grupal  = 'S'
BEGIN 
   SELECT @w_grupo = de_cliente FROM cob_credito..cr_deudores WHERE de_tramite = @w_tramite
   
   SELECT @w_tramite_ant = max(tg_tramite)
   FROM cob_cartera..ca_operacion, cob_credito..cr_tramite_grupal
   WHERE op_cliente IN (SELECT cg_ente FROM cobis..cl_cliente_grupo WHERE cg_grupo = @w_grupo) 
   AND op_estado NOT IN (3,0,99)
   AND op_banco = tg_prestamo
   AND tg_tramite <> @w_tramite
END
ELSE
  select @w_tramite_ant =max(tr_tramite)
  from cob_credito..cr_tramite, cob_cartera..ca_operacion
  where tr_tramite = op_tramite
  and op_estado not in (0,3,99)
  and op_cliente IN (SELECT de_cliente FROM cr_deudores WHERE de_tramite = @w_tramite AND de_rol = 'D')   

 IF EXISTS (SELECT 1 FROM cob_workflow..wf_inst_proceso WHERE io_campo_3 = @w_tramite AND io_estado <> 'TER')
 BEGIN 
    SELECT @w_tramite_ant_sol = ISNULL(io_campo_5,0)
    FROM cob_workflow..wf_inst_proceso 
    WHERE io_campo_3 = @w_tramite
    
    IF @w_tramite_ant_sol =  0
        UPDATE cob_workflow..wf_inst_proceso
        SET io_campo_5 = @w_tramite_ant        
        WHERE io_campo_3 = @w_tramite
  END    

RETURN 0

GO
