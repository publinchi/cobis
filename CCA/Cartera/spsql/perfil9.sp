/*perfil9.sp*************************************************************/
/*    Archivo:                perfil9.sp                                */
/*    Stored procedure:       sp_pf_ca09                                */
/*    Base de datos:          cob_cartera                               */
/*    Producto:               Cartera                                   */
/************************************************************************/
/*                             IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    "COBISCORP".                                                      */
/*    Su uso no autorizado  queda  expresamente  prohibido asi como     */
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus     */
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la     */
/*    Presidencia Ejecutiva de COBISCORP o su representante.            */
/************************************************************************/
/*                              PROPOSITO                               */
/*    Despliega para las pantallas de perfiles contables en el modulo   */
/*    de Contabilidad COBIS los valores que pueden tomar los criterios  */
/*    contables de TIPO CUSTODIA                                       */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pf_ca09')
   drop proc sp_pf_ca09
go
 

create proc sp_pf_ca09(
@i_criterio tinyint     = null,
@i_codigo   varchar(30) = null)

as

declare
@w_return         int,
@w_sp_name        varchar(32),
@w_tabla          smallint,
@w_codigo         varchar(30),
@w_criterio       tinyint

select @w_sp_name = 'sp_pf_ca09'

/* LA 1A VEZ ENVIA LAS ETIQUETAS QUE APARECERAN EN LOS CAMPOS DE LA FORMA */
if @i_criterio is null begin
   select
   'Tipo Gar'
end

select @w_codigo   = isnull(@i_codigo, '')
select @w_criterio = isnull(@i_criterio, 0)

/* TABLA TEMPORAL PARA LLENAR LOS DATOS DE TODOS LOS DATOS DEL F5 AL CARGAR LA PANTALLA */
create table #ca_catalogo(
ca_tabla       tinyint,
ca_codigo      varchar(30),
ca_descripcion descripcion)


/* CUSTODIA */
if @w_criterio <= 1 begin

   insert into #ca_catalogo
   select 1, cat.codigo, cat.valor
   from   cobis..cl_tabla tab, cobis..cl_catalogo cat
   where  tab.tabla  = 'cu_clase_custodia'
   and    tab.codigo = cat.tabla

   if @@error <> 0 return 710001

end

/* RETORNA LOS DATOS AL FRONT-END */
select ca_tabla, ca_codigo, ca_descripcion
from   #ca_catalogo
where  ca_tabla   > @w_criterio
or    (ca_tabla  = @w_criterio and ca_codigo > @w_codigo)
order by ca_tabla, ca_codigo

return 0

go

