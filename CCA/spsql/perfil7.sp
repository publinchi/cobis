/*perfil7.sp*************************************************************/
/*    Archivo:                perfil7.sp                                */
/*    Stored procedure:       sp_pf_ca01                                */
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
/*    de Contabilidad COBIS los valores que puede  tomar el  criterio   */
/*    contables de CONCEPTO (RUBRO)                                     */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pf_ca07')
   drop proc sp_pf_ca07
go
 

create proc sp_pf_ca07(
@i_criterio tinyint     = null,
@i_codigo   varchar(30) = null)

as

declare
@w_return         int,
@w_sp_name        varchar(32),
@w_tabla          smallint,
@w_codigo         varchar(30),
@w_criterio       tinyint

select @w_sp_name = 'sp_pf_ca07'


/* LA 1A VEZ ENVIA LAS ETIQUETAS QUE APARECERAN EN LOS CAMPOS DE LA FORMA */
if @i_criterio is null begin
   select 'Concepto'
end

select @w_criterio = isnull(@i_criterio, 0)
select @w_codigo   = isnull(@i_codigo, '')

/* TABLA TEMPORAL PARA LLENAR LOS DATOS DE TODOS LOS DATOS DEL F5 AL CARGAR LA PANTALLA */
create table #ca_catalogo(
ca_tabla       tinyint,
ca_codigo      varchar(30),
ca_descripcion descripcion)

/* RUBROS - CONCEPTO */
if @w_criterio <= 1 begin

   insert into #ca_catalogo
   select 1,  co_concepto, co_descripcion 
   from cob_cartera..ca_concepto
   order by co_concepto

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

