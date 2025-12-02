/************************************************************************/
/*      Archivo:                contageo.sp                             */
/*      Stored procedure:       sp_contabilidad_geo                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Epelaez                                 */
/*      Fecha de escritura:     Mar. 2003                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Genera las combinaciones de valores para la parte variable de   */
/*      BUSQUEDA ENTIDAD PRESTAMISTA ORIGEN DE RECURSOS                 */
/*      Transaccioon: 	7418						                           */
/*      FECHA               AUTOR            CAMBIO                     */
/*      DIC-22-2006         EPB              DEF-7647                   */
/*      DIC-29-2006         FQ               DEF-7676                   */
/************************************************************************/

use cobis
go

if exists (select 1 from sysobjects where name = 'sp_contabilidad_geo')
   drop proc sp_contabilidad_geo
go

create proc sp_contabilidad_geo
   @i_criterio1	char(10)=null,
   @i_criterio2	char(10)=null
as

declare
   @w_criterio   varchar(50)
begin
   -- TABLAS TEMOPRALES TMP
   
   create table #entidad
   (entidad	char(10),
    descripcion_ent	varchar(45)
   )
   
   create table #origen
   (origen 	char(10),
    descripcion_org	varchar(45)
   )
   
   insert into #entidad
   select codigo,valor
   from   cobis..cl_catalogo
   where  tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_tipo_linea' )
   
   insert into #origen
   select codigo, valor
   from   cobis..cl_catalogo
   where  tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_categoria_linea' )
   
   select @w_criterio = rtrim(isnull(@i_criterio1,'')) + rtrim(isnull(@i_criterio2,''))
   select @w_criterio = isnull(@w_criterio, '')
   
   set rowcount 20
   
   select 'Entidad Prestamista' = entidad,
          'Origen de Recursos' = origen,
          'Descripcion' =  descripcion_ent + '.' + descripcion_org
   from  #entidad,#origen
   where rtrim(entidad) + rtrim(origen) > @w_criterio
   order by rtrim(entidad) + rtrim(origen)
   
   set rowcount 0
   
   return 0
end
go

