/************************************************************************/
/*  Archivo:            rubroqry_seudo.sp                               */
/*  Stored procedure:   sp_rubro_qry_seudo                              */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Credito y Cartera                               */
/*  Disenado por:       TBA                                             */
/*  Fecha de escritura: 20/12/2016                                      */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Este stored procedure recupera el seudocatalogo de los conceptos.   */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*  20/12/2016  TBA         Emision Inicial                             */
/*  03/12/2016  JTO         Implementacion de funcionalidad             */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rubro_qry_seudo')
    drop proc sp_rubro_qry_seudo
go


create proc sp_rubro_qry_seudo (
        @t_show_version BIT          = 0,
        @i_tipo         char(1)      = NULL,
        @i_codigo       varchar(150) = null,
        @i_filas        int          = 80,
        @i_descripcion  varchar(150) = '',
        @i_tabla        varchar(30)  = null
)
as
declare
@w_sp_name  descripcion,
@w_error    int


/*  INICIALIZAR VARIABLES  */
select  @w_sp_name = 'sp_rubro_qry_seudo'

---- VERSIONAMIENTO DEL PROGRAMA ----
IF @t_show_version = 1
BEGIN
        PRINT 'Stored procedure ' + convert(varchar(30), @w_sp_name) + ' Version 1.0.0.0'
        RETURN 0
END
-------------------------------------
if @i_tipo = 'B' --consulta los registros sin filtro
begin
   set rowcount @i_filas

   select 'Codigo'      = co_concepto,
          'Descripcion' = co_descripcion
   from cob_cartera..ca_concepto
   where upper(co_concepto) > upper(isnull(@i_codigo,''))
   order by co_concepto ASC

   set rowcount 0
   return 0
END
if @i_tipo = 'V' --consulta el registro por codigo
begin
   select 'Codigo'      = co_concepto,
          'Descripcion' = co_descripcion
      from cob_cartera..ca_concepto
      where upper(co_descripcion) > upper(isnull(@i_codigo,''))
      and upper(co_concepto) like upper('%'+@i_codigo+'%')

   if @@rowcount =  0
   begin
     select @w_error = 701000  --No existe Tipo de Plazo
     goto ERROR
   end
END
if @i_tipo = 'S' --consulta los registros por la descripcion o nombre.
begin
   set rowcount @i_filas
   select 'Codigo'      = co_concepto,
          'Descripcion' = co_descripcion
   from cob_cartera..ca_concepto
   where upper(co_concepto) > upper(isnull(@i_codigo,''))
     and upper(co_descripcion) like upper('%'+isnull(@i_descripcion,'')+'%')
   ORDER BY co_concepto ASC

   set rowcount 0
   return 0
end
if @i_tipo = 'C' --consulta el numero de registros con o sin filtro.
begin
   select count(*) from cob_cartera..ca_concepto
end
return 0

ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null,
     @t_from  = @w_sp_name,
     @i_num   = @w_error

return @w_error

go

