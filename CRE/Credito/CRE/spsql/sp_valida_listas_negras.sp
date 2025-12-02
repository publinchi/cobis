/**************************************************************************/
/*  Archivo:                    sp_valida_listas_negras.sp                */
/*  Stored procedure:           sp_valida_listas_negras                   */
/*  Base de Datos:              cob_credito                               */
/*  Producto:                   Credito                                   */
/**************************************************************************/
/*                          IMPORTANTE                                    */
/*  Este programa es parte de los paquetes bancarios propiedad de         */
/*  'COBISCORP'.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como            */
/*  cualquier autorizacion o agregado hecho por alguno de sus             */
/*  usuario sin el debido consentimiento por escrito de la                */
/*  Presidencia Ejecutiva de COBISCORP o su representante.                */
/**************************************************************************/
/*                          PROPOSITO                                     */
/*  Este stored procedure permite llamar servicio de  comprobacion de  	  */
/*  listas negras       					                              */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA          AUTOR                            RAZON                 */
/*  09/Nov/2021   Dilan Morales           implementacion                  */
/**************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_valida_listas_negras' and type = 'P')
    drop proc sp_valida_listas_negras
go


create proc sp_valida_listas_negras
(
  @s_ssn                int         = null,
  @s_user               varchar(30) = null,
  @s_sesn               int         = null,
  @s_term               varchar(30) = null,
  @s_date               datetime    = null,
  @s_srv                varchar(30) = null,
  @s_lsrv               varchar(30) = null,
  @s_rol                smallint    = null,
  @s_ofi                smallint    = null,
  @s_org_err            char(1)     = null,
  @s_error              int         = null,
  @s_sev                tinyint     = null,
  @s_msg                descripcion = null,
  @s_org                char(1)     = null,
  @t_rty                char(1)     = null,
  @t_trn                int         = null,
  @t_debug              char(1)     = 'N',
  @t_file               varchar(14) = null,
  @t_from               varchar(30) = null,
  @i_id_inst_proc       int			= null,     -- codigo de instancia del proceso
  @i_id_inst_act        int			= null,     --  odigo de instancia de actividad
  @i_id_asig_act        int			= null,     -- codigo de asignacion de actividad
  @i_id_empresa         int			= null,     -- codigo de empresa
  @i_id_variable        smallint	= null, 		-- codigo de variable,
  @o_id_resultado		smallint	out
)
as
declare
  @w_asig_actividad int,
  @w_valor_ant      varchar(1),
  @w_valor_nuevo     varchar(1),
  @w_tipo_cliente   varchar(1),
  @w_cliente        int

  select @o_id_resultado = 1


return 0

GO

