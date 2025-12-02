/************************************************************************/
/*  Archivo:            tipo_garantia_seudo.sp                          */
/*  Stored procedure:   sp_tipo_garantia_seudo                          */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Credito y Cartera                               */
/*  Disenado por:       VBR                                             */
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
/*  Este stored procedure recupera el seudocatalogo de las garantías.   */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*  20/12/2016  VBR         Emision Inicial                             */
/*  03/12/2016  JTO         Implementacion de funcionalidad             */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tipo_garantia_seudo')
    drop proc sp_tipo_garantia_seudo
go


create proc sp_tipo_garantia_seudo (
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
select  @w_sp_name = 'sp_tipo_garantia_seudo'

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

   select 'Codigo'      = substring(tc_tipo,1,10),
          'Descripcion' = substring(tc_descripcion,1,30)
   from cob_custodia..cu_tipo_custodia
   where upper(substring(tc_tipo,1,10)) > upper(isnull(@i_codigo,''))
   order by substring(tc_tipo,1,10) ASC

   set rowcount 0
   return 0
END
if @i_tipo = 'V' --consulta el registro por codigo
begin
   select 'Codigo'      = substring(tc_tipo,1,10),
          'Descripcion' = substring(tc_descripcion,1,30)
      from cob_custodia..cu_tipo_custodia
      where upper(substring(tc_descripcion,1,30)) > upper(isnull(@i_codigo,''))
      and upper(substring(tc_tipo,1,10)) like upper('%'+@i_codigo+'%')

   if @@rowcount =  0
   begin
     select @w_error = 701000  --No existe Tipo de Plazo
     goto ERROR
   end
END
if @i_tipo = 'S' --consulta los registros por la descripcion o nombre.
begin
   set rowcount @i_filas
   select 'Codigo'      = substring(tc_tipo,1,10),
          'Descripcion' = substring(tc_descripcion,1,30)
   from cob_custodia..cu_tipo_custodia
   where upper(substring(tc_tipo,1,10)) > upper(isnull(@i_codigo,''))
     and upper(substring(tc_descripcion,1,30)) like upper('%'+isnull(@i_descripcion,'')+'%')
   ORDER BY substring(tc_tipo,1,10) ASC

   set rowcount 0
   return 0
end
if @i_tipo = 'C' --consulta el numero de registros con o sin filtro.
begin
   select count(*) from cob_custodia..cu_tipo_custodia
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

