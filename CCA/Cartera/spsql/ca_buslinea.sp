/************************************************************************/
/*   Archivo:             ca_buslinea.sp                                   */
/*   Stored procedure:    sp_bus_linea                                  */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Juan Bernardo Quinche                         */
/*   Fecha de escritura:  07/24/2008                                    */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Este programa ejecuta el consulta de las linea aprobadas para un   */
/*   un cliente.                                                        */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_bus_linea')
   drop proc sp_bus_linea
go

create proc sp_bus_linea (
   @i_cliente           int      = null,
   @i_li_num_bco        cuenta   = null,
   @i_formato_fecha     int      = null,
   @i_operacion         char(1)  = 'C',
   @i_tipo              char(1)  = 'O'  --letra O
)
as

declare
   @w_today             datetime,     /* fecha del dia */
   @w_sp_name           varchar(32),  /* nombre stored proc */
   @w_return		int,
   @w_error		int,
   @w_li_num_bco        cuenta,
   @w_fecha_vto         char(10),
   @w_ult_rev           char(10),
   @w_cliente           int,
   @w_nombre            descripcion,
   @w_grupo             int,
   @w_nom_grupo         descripcion,
   @w_tab_estcup        smallint,
   @w_tab_tipcup        smallint,
   @w_sp_fisico         cuenta,
   @w_numero            int,
   @w_num_banco         cuenta,
   @w_monto             money,
   @w_utilizado         money,
   @w_moneda            tinyint,
   @w_tramite           int,
   @w_estado            char(1)

select @w_sp_name   = 'sp_bus_linea'
select @w_sp_fisico = 'ca_buslinea.sp'

/* DETERMINAR SI CLIENTE PERTENECE A GRUPO */
select @w_grupo = en_grupo
from cobis..cl_ente
where en_ente = @i_cliente
set transaction isolation level read uncommitted

/* CODIGO DE TABLA DE ESTADOS DE CUPO */
select @w_tab_estcup = codigo
from cobis..cl_tabla
where tabla = 'cr_estado_cupo'
set transaction isolation level read uncommitted

/* CODIGO DE TABLA DE TIPOS DE CUPO */
select @w_tab_tipcup = codigo
from cobis..cl_tabla
where tabla = 'cr_tipo_cupo'
set transaction isolation level read uncommitted
if @i_operacion= 'C'   ---lineas x cliente
begin
    select li_num_banco,
           om_linea,
           om_monto,
           om_moneda,
           om_utilizado,
           li_tramite,
           li_fecha_vto,
           li_estado
    from  cob_credito..cr_linea, cob_credito..cr_lin_ope_moneda
    where li_cliente     = @i_cliente
          and   li_numero   = om_linea
          and   li_tipo     = @i_tipo       -- Cupo de sobregiro
          and   li_estado in ('V','B')
    if @@rowcount = 0
    begin
        select @w_error = 701065
        goto ERROR 
    end
end
return 0


ERROR:
exec cobis..sp_cerror
@t_debug  = 'N', 
@t_file   = null,
@t_from   = @w_sp_name,   
@i_num    = @w_error
--@i_cuenta = ' '

return @w_error

go
