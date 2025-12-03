/*************************************************************************/
/*   Archivo:              linprodxcli.sp                                */
/*   Stored procedure:     sp_lin_producto_x_cliente                     */
/*   Base de datos:        cob_credito                                   */
/*   Producto:             Credito                                       */
/*   Disenado por:         Carlos Obando                                 */
/*   Fecha de escritura:   06 / Abril / 2022                             */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual. Su uso no  autorizado dara  derecho a  MACOSA para         */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                               PROPOSITO                               */
/*   Almacemamiento de la informacion de productos de garantia por       */
/*   clientes en la tabla de cob_interface..in_cons_productos_cl         */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    06/04/2022               COB                Emision inicial        */
/*************************************************************************/

USE cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_lin_producto_x_cliente')
   drop proc sp_lin_producto_x_cliente
go

create proc sp_lin_producto_x_cliente(
   @s_user               login       = null,
   @s_ofi                smallint    = null,
   @t_debug              char(1)     = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_cliente            int

)
as

declare
@w_sp_name                  varchar(24),
@w_error                    int,
@w_num_garantia             varchar(30),
@w_tipo_garantia            varchar(64),
@w_moneda                   tinyint,
@w_estado                   varchar(30),
@w_rol_cliente              varchar(30),
@w_cod_producto             tinyint,
@w_fecha_proceso            datetime

select @w_sp_name        = 'sp_lin_producto_x_cliente ',
       @w_cod_producto   = 21

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso


--Obtenemos el numero de tramite

if exists (select 1 from cob_interface..in_cons_productos_cl 
           where cp_cliente = @i_cliente and cp_producto = @w_cod_producto)
begin
   delete cob_interface..in_cons_productos_cl 
   where cp_cliente = @i_cliente and cp_producto = @w_cod_producto
end

INSERT INTO cob_interface..in_cons_productos_cl 
(cp_cliente,      cp_producto,     cp_tipo_producto,          cp_numero_operacion, 
 cp_cliente_rol,  cp_moneda,       cp_saldo_operacion,        cp_estado_operacion)
select 
 de_cliente,      @w_cod_producto, tr_toperacion,             li_num_banco, 
 c1.valor,          li_moneda,       (li_monto - li_utilizado), c2.valor
from cob_credito..cr_deudores, 
     cob_credito..cr_tramite,
     cob_credito..cr_linea,
     cobis..cl_tabla t1, 
	 cobis..cl_catalogo c1,
	 cobis..cl_tabla t2, 
	 cobis..cl_catalogo c2
where de_cliente = @i_cliente 
and de_tramite   = tr_tramite
and tr_tramite   = li_tramite
and tr_tipo      = 'L'
and li_estado    = 'V'
and @w_fecha_proceso between li_fecha_inicio and li_fecha_vto
and t1.codigo = c1.tabla
and t1.tabla = 'cr_rol_deudor'
and de_rol = c1.codigo
and t2.codigo = c2.tabla
and t2.tabla = 'cr_estado_linea'
and li_estado = c2.codigo

if @@error <> 0 
begin
   select @w_error = 1909032 --No se pudo ingresar los datos del producto de garantia
end  
   

return 0

ERROR:    /* Rutina que dispara sp_cerror dado el codigo de error */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = @w_error
return @w_error

go
