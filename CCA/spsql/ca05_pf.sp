/************************************************************************/  
/*    Archivo:                ca05_pf.sp                                */  
/*    Stored procedure:       sp_ca05_pf                                */  
/*    Base de datos:          cob_cartera                               */  
/*    Producto:               Cartera                                   */  
/************************************************************************/  
/*                             IMPORTANTE                               */  
/*    Este programa es parte de los paquetes bancarios propiedad de     */  
/*    'COBISCORP'.                                                      */  
/*    Su uso no autorizado  queda  expresamente  prohibido asi como     */  
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus     */  
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la     */  
/*    Presidencia Ejecutiva de COBISCORP o su representante.            */  
/************************************************************************/  
/*                              PROPOSITO                               */  
/*    Despliega para las pantallas de perfiles contables en el modulo   */  
/*    de Contabilidad COBIS los valores que pueden tomar los criterios  */  
/*    contables de TIPO OPERACION                                       */  
/************************************************************************/  
/*                             MODIFICACION                             */  
/*    FECHA                 AUTOR                 RAZON                 */  
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ca05_pf')
   drop proc sp_ca05_pf
go                                                                          

create proc sp_ca05_pf(
@i_criterio tinyint     = null,
@i_codigo   varchar(30) = null)
as
declare
@w_return         int,
@w_sp_name        varchar(32),
@w_tabla          smallint,
@w_codigo         varchar(30),
@w_criterio       tinyint

select @w_sp_name = 'sp_ca05_pf'

/* LA 1A VEZ ENVIA LAS ETIQUETAS QUE APARECERAN EN LOS CAMPOS DE LA FORMA */
if @i_criterio is null begin
   select
   'Tipo Operacion',
   'Calificacion'
end

select @w_codigo   = isnull(@i_codigo, '')
select @w_criterio = isnull(@i_criterio, 0)

/* TABLA TEMPORAL PARA LLENAR LOS DATOS DE TODOS LOS DATOS DEL F5 AL CARGAR LA PANTALLA */
create table #ca_catalogo(
ca_tabla       tinyint,
ca_codigo      varchar(10),
ca_descripcion varchar(50))

/* Tipo Operacion */                                                                
if @w_criterio <= 1 begin
   select 1, cat.codigo, cat.valor
   from   cobis..cl_tabla tab, cobis..cl_catalogo cat
   where  tab.tabla  = 'ca_toperacion'
   and    tab.codigo = cat.tabla

   if @@error <> 0 return 710001
end

/*Calificacion de provision*/
if @w_criterio <= 2 begin
   insert into #ca_catalogo (ca_tabla, ca_codigo, ca_descripcion) values (2, 'A1', 'CALIFICACION A1')
   insert into #ca_catalogo (ca_tabla, ca_codigo, ca_descripcion) values (2, 'A2', 'CALIFICACION A2')
   insert into #ca_catalogo (ca_tabla, ca_codigo, ca_descripcion) values (2, 'B1', 'CALIFICACION B1')
   insert into #ca_catalogo (ca_tabla, ca_codigo, ca_descripcion) values (2, 'B2', 'CALIFICACION B2')
   insert into #ca_catalogo (ca_tabla, ca_codigo, ca_descripcion) values (2, 'B3', 'CALIFICACION B3')
   insert into #ca_catalogo (ca_tabla, ca_codigo, ca_descripcion) values (2, 'C1', 'CALIFICACION C1')
   insert into #ca_catalogo (ca_tabla, ca_codigo, ca_descripcion) values (2, 'C2', 'CALIFICACION C2')
   insert into #ca_catalogo (ca_tabla, ca_codigo, ca_descripcion) values (2, 'D',  'CALIFICACION D')
   insert into #ca_catalogo (ca_tabla, ca_codigo, ca_descripcion) values (2, 'E',  'CALIFICACION E')

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
