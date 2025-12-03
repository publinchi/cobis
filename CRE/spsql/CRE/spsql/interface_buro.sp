/************************************************************************/
/*  Archivo:                interface_buro.sp                           */
/*  Stored procedure:       sp_interface_buro                           */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
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
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_interface_buro')
    drop proc sp_interface_buro
go

create procedure sp_interface_buro (
   @s_ssn            int         = null,
   @s_user           login       = null,
   @s_term           varchar(32) = null,
   @s_date           datetime    = null,
   @s_sesn           int         = null,
   @s_culture        varchar(10) = null,
   @s_srv            varchar(30) = null,
   @s_lsrv           varchar(30) = null,
   @s_ofi            smallint    = null,
   @s_rol            smallint    = NULL,
   @s_org_err        char(1)     = NULL,
   @s_error          int         = NULL,
   @s_sev            tinyint     = NULL,
   @s_msg            descripcion = NULL,
   @s_org            char(1)     = NULL,
   @t_debug          char(1)     = 'N',
   @t_file           varchar(10) = null,
   @t_from           varchar(32) = null,
   @t_trn            smallint    = null,
   @t_show_version bit  = 0,   --* Mostrar la version del programa
   @i_operacion      char(1),             -- Opcion con la que se ejecuta el programa
   @i_tipo           char(1)     = null,  -- Tipo de busqueda
   @i_modo           int         = null,  -- Modo de consulta
   @i_ente			 int,
   @i_fecha          datetime    = null,
   @i_xml            VARBINARY(8000)   = null,
   @i_riesgo         int       = null,
   @i_folio          varchar(64) = null
)
as
begin
declare @w_today   datetime,
  @w_sp_name       varchar(32),
  @w_return        INT,
  @w_error_number  int


set @w_sp_name = 'sp_interface_buro'

--* VERSIONAMIENTO DEL PROGRAMA
  if @t_show_version = 1
  begin
    print 'Stored Procedure=sp_interface_buro Version=1.0.0'
    return 0
  end

if @i_operacion='Q'
begin

 select ib_cliente,
    ib_fecha,
    ib_xml,
    ib_riesgo,
	ib_folio
  from cr_interface_buro
  where ib_cliente = @i_ente

end --@i_operacion

If @i_operacion = 'I'
begin
	if exists(select 1 from cr_interface_buro
              where ib_cliente = @i_ente)
	begin
		 set @w_error_number = 351047
         goto ERROR
	end

	insert into cr_interface_buro (ib_cliente, ib_fecha, ib_xml, ib_riesgo, ib_folio)
	values (@i_ente, @i_fecha, @i_xml, @i_riesgo, @i_folio)

	if @@error <> 0
	begin
         set @w_error_number = 357043
         goto ERROR
     end

end  --@i_operacion


if @i_operacion = 'U'
begin

	update cr_interface_buro
		set ib_fecha = isnull(@i_fecha,ib_fecha),
		ib_xml = isnull(@i_xml,ib_xml),
		ib_riesgo = isnull(@i_riesgo,ib_riesgo),
		ib_folio  = isnull(@i_folio,ib_folio)
	where ib_cliente = @i_ente

	if @@error <> 0
	begin
         set @w_error_number = 708152
         goto ERROR
     end

end  --@i_operacion

return 0

ERROR:
    EXEC cobis..sp_cerror
        @t_from  = @w_sp_name,
        @i_num   = @w_error_number

    RETURN 1
end
go
