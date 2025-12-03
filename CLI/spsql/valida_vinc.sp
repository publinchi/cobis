/************************************************************************/
/*      Archivo:                valida_vinc.sp                          */
/*      Stored procedure:       sp_valida_vinc                          */
/*      Base de datos:          cobis                                   */
/*      Producto:               Clientes                                */
/*      Disenado por:           C. Obando                               */
/*      Fecha de escritura:     28-Jun-2021                             */
/************************************************************************/
/*                             IMPORTANTE                               */
/*  Este programa es propiedad de "COBISCORP". Ha sido desarrollado     */
/*  bajo el ambiente operativo COBIS-sistema desarrollado por           */
/*  "COBISCORP S.A."-Ecuador                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Gerencia General de COBISCORP o su representante.                   */
/************************************************************************/
/*                              PROPOSITO                               */
/*          Este programa realiza la validacion con el sp               */
/*          cob_cartera..sp_eliminacion_integrante_grupo                */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      28/06/21        COB             Emision inicial                 */
/************************************************************************/
use cob_interface
go

set ANSI_nullS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
           from   sysobjects
           where  name = 'sp_valida_vinc')
   drop proc sp_valida_vinc
go

create proc sp_valida_vinc (
   @s_ssn                     int          = null,
   @s_user                    login        = null,
   @s_term                    varchar(32)  = null,
   @s_sesn                    int          = null,
   @s_ssn_branch              int          = null,
   @s_culture                 varchar(10)  = null,
   @s_date                    datetime     = null,
   @s_srv                     varchar(30)  = null,
   @s_lsrv                    varchar(30)  = null,
   @s_rol                     smallint     = null,
   @s_org_err                 char(1)      = null,
   @s_error                   int          = null,
   @s_sev                     tinyint      = null,
   @s_msg                     descripcion  = null,
   @s_org                     char(1)      = null,
   @s_ofi                     smallint     = null,
   @t_debug                   char(1)      = 'N',
   @t_file                    varchar(14)  = null,
   @t_from                    varchar(30)  = null,
   @t_trn                     int,
   @t_show_version            bit          = 0,
   @i_cod_grupo               int,
   @i_cod_cliente             int,
   @o_validacion_ahorros      int          = null out,
   @o_validacion_cartera      int          = null out,
   @o_mensaje                 varchar(255) = null out,
   @o_resultado               int          = 0    out
)

as
   declare 
   @w_return                  int,
   @w_sp_name                 varchar(100),
   @w_sp_msg                  varchar(100),
   @w_validacion_ahorros      int,
   @w_validacion_cartera      int

select @w_sp_name   = 'sp_valida_vinc'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end 

if @t_trn is null or @t_trn <> 2239
begin
   exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 151051
   return 151051
end

select @o_validacion_ahorros = 0

select @w_validacion_ahorros = 0

/*Validamos que se pueda vincular/desvincular CARTERA*/

exec @w_return =  cob_cartera..sp_eliminacion_integrante_grupo
   @i_grupo = @i_cod_grupo,
   @i_cliente = @i_cod_cliente,
   @o_retorno = @o_validacion_cartera output,
   @o_mensaje = @o_mensaje output

select @w_validacion_cartera = @o_validacion_cartera

if (@w_validacion_ahorros <> 0 or @w_validacion_cartera <> 0)
begin
   select @o_resultado = 1 

   exec cobis..sp_cerror
      @t_debug= @t_debug,
      @t_file   = @t_file,
      @t_from   = @w_sp_name,
      @i_num   = @w_return
   return @w_return
end

return 0

go
