/************************************************************************/
/*   Archivo:             buscacot.sp                                   */
/*   Stored procedure:    sp_buscar_cotizacion                          */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        Fabian Quintero                               */
/*   Fecha de escritura:  Ene. 98.                                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Unifica la forma de buscar una cotizacion en la tabla de           */
/*   cotizaciones                                                       */
/************************************************************************/
/*                              CAMBIOS                                 */
/*    FECHA          AUTOR             CAMBIOS                          */
/*  05/09/2023    G. Fernandez        Validaciones para la cotización   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_buscar_cotizacion')
    drop proc sp_buscar_cotizacion
go

create proc sp_buscar_cotizacion
                @i_moneda      int,
                @i_fecha       datetime,
                @o_cotizacion  float    out

as

declare @w_rowcount    int,
        @w_moneda_n    tinyint,
		@w_error       int

-- Codigo de moneda nacional
select @w_moneda_n = pa_tinyint 
from cobis..cl_parametro with (nolock)
where pa_producto = 'ADM' 
and pa_nemonico = 'CMNAC'

if @w_moneda_n is null
begin
   select @w_error = 725302 --Error no existe el parámetro general de moneda nacional
   return @w_error
end
   

begin
    select @o_cotizacion = convert(float,ct_valor)
    from   cob_conta..cb_cotizacion
    where  ct_moneda = @i_moneda
    and    ct_fecha  = @i_fecha
    select @w_rowcount = @@rowcount
    set transaction isolation level read uncommitted
  
    if @w_rowcount = 0
    begin
        select @o_cotizacion = convert(float,ct_valor)
        from   cob_conta..cb_cotizacion 
        noholdlock
        where  ct_moneda = @i_moneda
        and    ct_fecha  = (select max(ct_fecha) 
                            from   cob_conta..cb_cotizacion noholdlock
                            where  ct_moneda = @i_moneda
                            and    ct_fecha <= @i_fecha)
							
		if @@rowcount = 0
		begin
		   if (@i_moneda = @w_moneda_n)
		      select @o_cotizacion = 1
		   else
		   begin
              select @w_error = 725303 -- Error no existe cotización para la moneda y fecha de la operación
              return @w_error
           end
		   
		end
    end
end


go