/*************************************************************************/
/*   Archivo:              garprodxcli.sp                                */
/*   Stored procedure:     sp_gar_producto_x_cliente                     */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         Guisela Fernández                             */
/*   Fecha de escritura:   14 / Diciembre / 2021                         */
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
/*                                   PROPOSITO                           */
/*   Almacemamiento de la informacion de productos de garantia por       */
/*   clientes en la tabla de cob_interface.. in_cons_productos_cl        */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    10/12/2019          G. Fernandez             Emision inicial       */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
go

if exists (select 1 from sysobjects where name = 'sp_gar_producto_x_cliente  ')
   drop proc sp_gar_producto_x_cliente  
go

create proc sp_gar_producto_x_cliente   (
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
@w_error		            int,
@w_num_garantia             varchar(30),
@w_tipo_garantia            varchar(64),
@w_moneda                   tinyint,
@w_estado                   varchar(30),
@w_rol_cliente              varchar(30),
@w_valor_actual             float,
@w_cod_producto             tinyint

select @w_sp_name        = 'sp_gar_producto_x_cliente ',
       @w_valor_actual   = 0,
       @w_cod_producto   = 19


--Obtenemos el numero de tramite

SELECT @w_num_garantia = min(cg_codigo_externo) 
FROM cob_custodia..cu_cliente_garantia
WHERE cg_ente = @i_cliente

if @w_num_garantia is null
begin
	return 0
end

if exists (select 1 from cob_interface.. in_cons_productos_cl 
                   where cp_cliente = @i_cliente and cp_producto = @w_cod_producto)
begin
	delete cob_interface.. in_cons_productos_cl 
	 where cp_cliente = @i_cliente and cp_producto = @w_cod_producto
end
	
while @w_num_garantia is not null
BEGIN

	--Obtenemos datos del producto de garantia
	SELECT @w_tipo_garantia  = tc_descripcion,
           @w_moneda         = cu_moneda,
           @w_estado         = eg_descripcion,
           @w_valor_actual   = cu_valor_actual		   
	FROM cob_custodia..cu_custodia, cu_tipo_custodia, cu_estados_garantia
	WHERE cu_codigo_externo = @w_num_garantia
	and cu_estado NOT IN ('C','P','A')
	and cu_tipo = tc_tipo
	AND cu_estado = eg_estado
	
	if @@rowcount = 0
	begin
		goto SIGUIENTE
	end
	
	SELECT @w_rol_cliente = case when cg_principal = 'S' then 'PRINCIPAL' else 'ALTERNANTE' end
    FROM cu_cliente_garantia
    WHERE cg_ente = @i_cliente

	--Inserta registros de productos 
	begin tran
	INSERT INTO cob_interface..in_cons_productos_cl 
	(cp_cliente,      cp_producto,  cp_tipo_producto,    cp_numero_operacion, 
	 cp_cliente_rol,  cp_moneda,    cp_saldo_operacion,  cp_estado_operacion)
	VALUES 
	(@i_cliente,      19,           @w_tipo_garantia,     @w_num_garantia, 
	@w_rol_cliente,   @w_moneda,    @w_valor_actual,  @w_estado)
	
	if @@error <> 0 
      begin
	     rollback
         select @w_error = 1909032 --No se pudo ingresar los datos del producto de garantia
      end  
	
	commit tran
	
	--Consulta para ir al siguiente tramite de cliente
	SIGUIENTE:
	SELECT @w_num_garantia = min(cg_codigo_externo) 
    FROM cob_custodia..cu_cliente_garantia
    WHERE cg_ente = @i_cliente
	 and  cg_codigo_externo > @w_num_garantia
	
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
