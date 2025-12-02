/************************************************************************/
/*      Archivo:                contacte.sp                             */
/*      Stored procedure:       sp_contabilidad_mge                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           MPoveda                                 */
/*      Fecha de escritura:     Agosto 2001                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Genera las combinaciones de valores para la parte variable de   */
/*      cuenta definida como MGE (Moneda;Tipo de Garantia;	        */
/*      Edad de Vencimiento)                                            */
/*      Transaccion: 7410						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_mge')
   drop proc sp_contabilidad_mge
go

create proc sp_contabilidad_mge
@i_criterio1	char(3)=null,
@i_criterio2	char(1)=null,
@i_criterio3	char(2)=null
as


create table #garantia (
garantia	char(1),
descripcion1	varchar(20)
)


insert #garantia
values
('A','ADMISIBLE')

insert #garantia
values
('H','HIPOTECARIA')

insert #garantia
values
('O','OTRAS GARANTIAS')

select @i_criterio1 = isnull(@i_criterio1,'-1'),
       @i_criterio2 = isnull(@i_criterio2,''),
       @i_criterio3 = isnull(@i_criterio3,'-1')

set rowcount 20

select 'Moneda' = mo_moneda,
       'Garantia' = garantia,
       'Estado' = es_codigo,
       'Descripcion' = mo_descripcion + '.' + descripcion1 + '.' + es_descripcion
from cobis..cl_moneda, #garantia, cob_cartera..ca_estado
where ((mo_moneda = convert(smallint,@i_criterio1) and garantia = @i_criterio2 and es_codigo > convert(smallint,@i_criterio3)) or
      (mo_moneda = convert(smallint,@i_criterio1) and garantia > @i_criterio2) or
      (mo_moneda > convert(smallint,@i_criterio1))) 
order by mo_moneda, garantia,es_codigo

set rowcount 0

return 0
go