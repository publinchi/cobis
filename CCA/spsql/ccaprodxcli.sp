/*************************************************************************/
/*   Archivo:              ccaprodxcli.sp                                */
/*   Stored procedure:     sp_cca_producto_x_cliente                     */
/*   Base de datos:        cob_cartera                                   */
/*   Producto:             Cartera                                       */
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
/*   Almacemamiento de la informacion de productos de cartera por        */
/*   clientes en la tabla de cob_interface.. in_cons_productos_cl        */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    10/12/2019          G. Fernandez             Emision inicial       */
/*                                                                       */
/*************************************************************************/

USE cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cca_producto_x_cliente ')
   drop proc sp_cca_producto_x_cliente 
go

create proc sp_cca_producto_x_cliente  (
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
@w_num_tramite              int,
@w_operacionca              int,
@w_toperacion               varchar(64),
@w_banco                    cuenta,
@w_moneda                   tinyint,
@w_estado                   varchar(30),
@w_rol_cliente              varchar(30),
@w_saldo_operacion          float,
@w_cod_producto             tinyint

select @w_sp_name          = 'sp_cca_producto_x_cliente',
       @w_saldo_operacion  = 0,
       @w_cod_producto     = 7


--Obtenemos los tramites asignados al cliente
SELECT @w_num_tramite = min(de_tramite) 
FROM cob_credito..cr_deudores
WHERE de_cliente = @i_cliente

if @w_num_tramite is null
begin
	return 0
end

if exists (select 1 from cob_interface.. in_cons_productos_cl where cp_cliente = @i_cliente 
																and cp_producto = @w_cod_producto )
begin
	delete cob_interface..in_cons_productos_cl where cp_cliente = @i_cliente 
	                                              and cp_producto = @w_cod_producto 
end
	
	
while @w_num_tramite is not null
BEGIN
    
	--Obtenemos dato de la operacion de cada tramite
	SELECT @w_operacionca = op_operacion,
           @w_toperacion  = op_toperacion,
           @w_banco       = op_banco,
           @w_moneda      = op_moneda,
           @w_estado      = es_descripcion		   
	FROM ca_operacion, ca_estado
	WHERE op_tramite = @w_num_tramite
	and op_estado not in (0,3,99) --no incluye operaciones en estado no vigente, cancelado y credito
	and op_estado = es_codigo
	
	if @@rowcount = 0
	begin
		goto SIGUIENTE
	end
	
	SELECT @w_rol_cliente = case when de_rol = 'D' then 'DEUDOR' else 'CODEUDOR' end
    FROM cob_credito..cr_deudores
    WHERE de_cliente = @i_cliente
	
	SELECT @w_saldo_operacion = sum(am_acumulado) - sum(am_pagado) 
	FROM ca_amortizacion
	WHERE am_operacion = @w_operacionca
	AND am_concepto = 'CAP'
	
	--Inserta registros de productos 
	begin tran
	INSERT INTO cob_interface..in_cons_productos_cl 
	(cp_cliente,      cp_producto,  cp_tipo_producto,    cp_numero_operacion, 
	 cp_cliente_rol,  cp_moneda,    cp_saldo_operacion,  cp_estado_operacion)
	VALUES 
	(@i_cliente,      @w_cod_producto,            @w_toperacion,       @w_banco, 
	@w_rol_cliente,   @w_moneda,    @w_saldo_operacion,  @w_estado)
	
	if @@error <> 0 
      begin
	     rollback
         select @w_error = 725133 --No se pudo ingresar los datos del producto
         goto ERROR
      end  
	
	commit tran
	
	--Consulta para ir al siguiente tramite del cliente
	SIGUIENTE:
	SELECT @w_num_tramite = min(de_tramite) 
    FROM cob_credito..cr_deudores
    WHERE de_cliente = @i_cliente
	 and  de_tramite > @w_num_tramite
	
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
