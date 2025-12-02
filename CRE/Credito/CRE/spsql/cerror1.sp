/************************************************************************/
/*      Archivo:                cerror1.sp                              */
/*      Stored procedure:       sp_cerror1                              */
/*      Base de datos:          cobis                                   */
/*      Producto:               Cobis                                   */
/*      Disenado por:                                                   */
/*      Fecha de escritura:                                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad       */
/*   de COBISCorp.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado  hecho por alguno de sus           */
/*   usuarios sin el debido consentimiento por escrito de COBISCorp.    */
/*   Este programa esta protegido por la ley de derechos de autor       */
/*   y por las convenciones  internacionales   de  propiedad inte-      */
/*   lectual.    Su uso no  autorizado dara  derecho a COBISCorp para   */
/*   obtener ordenes  de secuestro o retencion y para  perseguir        */
/*   penalmente a los autores de cualquier infraccion.                  */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Invocacion al cobis..sp_cerror                                     */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*  FECHA         AUTOR           RAZON                                 */
/*  19/Sep/2016   J. Salazar      Migracion CobisCloud                  */
/************************************************************************/
use cobis
go
if exists (select
             1
           from   sysobjects
           where  name = 'sp_cerror1')
  drop proc sp_cerror1
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

create proc sp_cerror1
(
    @s_ssn           int          = null,
    @s_user          login        = null,
    @s_sesn          int          = null,
    @s_term          varchar(30)  = null,
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
    @t_debug         char(1)      = 'N',
    @t_file          varchar(14)  = null,
    @t_from          varchar(32)  = null,
    @t_show_version  bit          = 0,
    @i_num           int,         
    @i_sev           int          = null,
    @i_msg           varchar(132) = null,
    @i_pit           char(1)      = 'N'
)
as
declare	@w_return  int,
        @w_sp_name varchar(30)
		
select @w_sp_name = 'sp_cerror1'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  print 'Stored Procedure = ' + @w_sp_name + 'Version = ' + '4.0.0.0'
  return 0
end

if @i_pit = 'N'
begin
  exec cobis..sp_cerror 
       @t_debug	= @t_debug,
       @t_file	= @t_file,
       @t_from	= @t_from,
       @i_num	= @i_num, 
       @i_sev	= @i_sev
end
--return @i_num

return 0
go

