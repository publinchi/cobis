/************************************************************************/
/*  Archivo:                         address_type.sp                    */
/*  Stored procedure:                sp_address_type                    */
/*  Base de datos:                   cobis                              */
/*  Producto:                        Clientes                           */
/*  Disenado por:                    JMEG                               */
/*  Fecha de escritura:              30-Abril-19                        */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                          PROPOSITO                                   */
/*  Marcar clientes como de ola invernal                                */
/*                                                                      */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*   FECHA           AUTOR        RAZON                                 */
/*   30/04/19        JMEG         Emision Inicial                       */
/*   18/05/20        MBA          Cambio nombre y compilacion BDD cobis */
/*   23/06/20        FSAP         Estandarizacion Clientes              */
/************************************************************************/
use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
           from   sysobjects
           where  name = 'sp_address_type')
           drop proc sp_address_type
go
CREATE PROCEDURE 	sp_address_type (
	@s_ssn		  	int = NULL,
	@s_user		  	login = NULL,
	@s_sesn		  	int = NULL,
	@s_term		  	varchar(30) = NULL,
	@s_date		  	datetime = NULL,
	@s_srv		  	varchar(30) = NULL,
	@s_lsrv		  	varchar(30) = NULL, 
	@s_rol		  	smallint = NULL,
	@s_ofi		  	smallint = NULL,
	@s_org_err  		char(1) = NULL,
	@s_error	  	int = NULL,
	@s_sev		  	tinyint = NULL,
	@s_msg		  	descripcion = NULL,
	@s_org		  	char(1) = NULL,
	@t_debug	  	char(1) = 'N',
	@t_file		  	varchar(14) = null,
	@t_from		  	varchar(32) = null,
	@t_trn		  	int =NULL,
  @t_show_version  bit = 0,
  @i_operacion	varchar(1) = null
)
as
declare @w_today	datetime,
	@w_sp_name	varchar(32),
  @w_sp_msg   varchar(132)

select @w_sp_name = 'sp_address_type'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

if (@t_trn <> 172054 and @i_operacion = 'H')
begin 
   /* Tipo de transaccion no corresponde */ 
   exec cobis..sp_cerror 
        @t_debug = @t_debug, 
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1720275
   return 1
end

/* ** Insert ** */
if @i_operacion = 'H'
begin
  if @t_trn = 172054
  begin
    select 
      'codigo'= cat.codigo,
      'valor'=cat.valor
    from cobis..cl_catalogo AS cat, cobis..cl_tabla AS tab 
      where tab.tabla = 'cl_tdireccion' 
      and cat.tabla = tab.codigo 
      and cat.codigo NOT IN('CE','SI', 'DE')
    return 0
    end
  
  else
  begin
    exec cobis..sp_cerror
      @t_debug	 = @t_debug,
      @t_file	 = @t_file,
      @t_from	 = @w_sp_name,
      @i_num	 = 1720075
      /*  'No corresponde codigo de transaccion' */
    return 1
  end
end


GO

