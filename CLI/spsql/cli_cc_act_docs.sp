/**********************************************************************/
/*  Archivo           :   cli_cc_act_docs.sp                          */
/*  Stored procedure  :   sp_cli_cc_act_docs                          */
/*  Base de datos     :   cob_cuentas                                 */
/*  Producto:             CUENTAS CORRIENTES                          */
/*  Disenado por     :    FSAP                                        */
/*  Fecha de escritura:   15-Jun-2019                                 */
/**********************************************************************/
/*              IMPORTANTE                                            */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad      */
/*  de COBISCorp.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como  */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus  */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp  */
/*  Este programa esta protegido por la ley de   derechos de autor    */
/*  y por las    convenciones  internacionales   de  propiedad inte-  */
/*  lectual.   Su uso no  autorizado dara  derecho a COBISCorp para   */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir      */
/*  penalmente a los autores de cualquier   infraccion.               */
/**********************************************************************/
/*              PROPOSITO                                             */
/*  Permite actualizar los datos sensibles de cliente                 */
/**********************************************************************/
/*               MODIFICACIONES                                       */
/*   FECHA          AUTOR                RAZON                        */
/*   15/Jun/2020    FSAP      Versión Inicial Estandarizacion Clientes*/
/**********************************************************************/
use cob_cuentas
GO

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1
           from   sysobjects
           where  name = 'sp_cli_cc_act_docs')
           drop proc sp_cli_cc_act_docs
go

create proc sp_cli_cc_act_docs
(
  @s_ssn          int          = null,
  @s_user         login        = null,
  @s_term         varchar(30)  = null,
  @s_date         datetime     = null,
  @s_srv          varchar(30)  = null,
  @s_lsrv         varchar(30)  = null,
  @s_rol          smallint     = null,
  @s_org_err      char(1)      = null,
  @s_error        int          = null,
  @s_sev          tinyint      = null,
  @s_msg          descripcion  = null,
  @s_org          char(1)      = null,
  @t_debug        char (1)     = 'N',
  @t_file         varchar (14) = null,
  @t_from         varchar (30) = null,
  @t_trn          int          = null,
  @t_show_version bit          = 0,
  @i_operacion    char(1),
  @i_nombre_cta   varchar(254),
  @i_cuenta       cuenta,
  @i_moneda       tinyint,
  @i_ente         int, -- Codigo del ente
  @i_en_ced_ruc   numero
  
)
as
  declare @w_sp_name varchar (30),
          @w_sp_msg  varchar(130)

select @w_sp_name = 'sp_cli_cc_act_docs'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

-- Actualizar la C.I. del Titular de la Cuenta
update cob_cuentas..cc_ctacte
   set cc_ced_ruc   = @i_en_ced_ruc
 where cc_cta_banco = @i_cuenta
   and cc_moneda    = @i_moneda
   and cc_cliente   = @i_ente

if @@error <> 0
begin
  exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 1720080
  return 1
end

-- Actualizar el nombre de la Cuenta
update cob_cuentas..cc_ctacte
   set cc_nombre    = @i_nombre_cta
 where cc_cta_banco = @i_cuenta
   and cc_moneda    = @i_moneda

if @@error <> 0
begin
  exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file,
    @t_from  = @w_sp_name,
    @i_num   = 1720080
  return 1
end

return 0

go

