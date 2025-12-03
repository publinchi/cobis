/************************************************************************/
/*  Archivo:                valida_clientes_segdeuven.sp                */
/*  Stored procedure:       sp_valida_clientes_segdeuven                */
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

if exists (select 1 from sysobjects where name = 'sp_valida_clientes_segdeuven' and type = 'P')
   drop proc sp_valida_clientes_segdeuven
go


create proc sp_valida_clientes_segdeuven (  
@s_ssn                 int          = null,
@s_user                login        = null,
@s_sesn                int          = null,
@s_term                descripcion  = null,
@s_date                datetime     = null,
@s_srv                 varchar(30)  = null,
@s_lsrv                varchar(30)  = null,
@s_rol                 smallint     = null,
@s_ofi                 smallint     = null,
@s_org_err             char(1)      = null,
@s_error               int          = null,
@s_sev                 tinyint      = null,
@s_msg                 descripcion  = null,
@s_org                 char(1)      = null,
@t_rty                 char(1)      = null,
@t_trn                 smallint     = null,
@t_debug               char(1)      = 'N',
@t_file                varchar(14)  = null,
@t_from                varchar(30)  = null,
@i_cliente             int          = null
)  
  
as  
declare  
@w_sp_name             varchar(60),
@w_valor               varchar(1)

select @w_sp_name = 'SP_VALIDA_CLIENTES_SEGDEUVEN' 

select @w_valor = 'N'

if exists(select 1
          from cobis..cl_ente, cobis..cl_mercado
          where en_ente     = @i_cliente
          and   en_ced_ruc  = me_ced_ruc
          and   en_tipo_ced = me_tipo_ced
          and   me_estado   = '025')
begin
   print 'CLIENTE NO OBJETIVO PARA PRESTAMO'
   select @w_valor = 'S'
end

--Mapeo al FE
select @w_valor

return 0


GO
