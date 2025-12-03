/************************************************************************/
/*  Archivo:                busqueda_oficina_oficial.sp                 */
/*  Stored procedure:       sp_busqueda_oficina_oficial                 */
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

if exists (select 1 from sysobjects where name = 'sp_busqueda_oficina_oficial' and type = 'P')
   drop proc sp_busqueda_oficina_oficial
go

create proc sp_busqueda_oficina_oficial(
   @s_ssn           int          = null,
   @s_user          login        = null,
   @s_sesn          int          = null,
   @s_term          descripcion  = null,
   @s_date          datetime     = null,
   @s_srv           varchar(30)  = null,
   @s_lsrv          varchar(30)  = null,
   @s_rol           smallint     = null,
   @s_ofi           smallint     = null,
   @s_org_err       char(1)      = null,
   @s_error         int          = null,
   @s_sev           tinyint      = null,
   @s_msg           descripcion  = null,
   @s_org           char(1)      = null,
   @t_rty           char(1)      = null,
   @t_trn           smallint     = null,
   @t_debug         char(1)      = 'N',
   @t_file          varchar(14)  = null,
   @t_from          varchar(30)  = null,
   @i_operacion     char(1)      = 'Q',
   @i_login         varchar(14)  = null,
   @o_oficina       int          = null out  
)
as
  declare @w_codigo_oficina int

  select @w_codigo_oficina = fu_oficina
  from cobis..cl_funcionario
  where fu_login = @i_login
  
  
        
  select @o_oficina = @w_codigo_oficina
  

return 0

GO
