/************************************************************************/
/*   Archivo:              inter_pag_con_ws.sp                          */
/*   Stored procedure:     sp_inter_pag_con_ws                          */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Guisela Fernandez                            */
/*   Fecha de escritura:   26/10/2021                                   */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Proceso creado para realizar la consulta de pago por medio          */
/*  de un web service                                                   */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* 26/10/2021     J. Hernandez       Versión inicial                    */
/* 29/11/2021     G. Fernandez       Ingreso de parametro de llave      */
/* 02/12/2021     G. Fernandez       Actualización de nombre de         */
/*                                   para WS                            */
/* 07/12/2021     J. Hernandez       Ingreso de parametro de nombre     */
/*                                   de catalogo. Se modifica nombre    */
/*                                   Para que sea generico              */
/************************************************************************/

USE cob_cartera
GO

if exists(select 1 from sysobjects where name ='sp_inter_pag_con_ws')
   drop proc sp_inter_pag_con_ws
go

CREATE PROC sp_inter_pag_con_ws
(
	@s_srv                  varchar(30)   = null,
	@s_rol                  smallint      = null,      
	@s_ssn                  int           = null,
	@s_lsrv                 varchar(30)   = null,            
	@s_user                 login         = null,
	@s_date                 datetime      = null,
	@s_sesn                 int           = null,
	@s_term                 descripcion   = null,
	@t_trn                  INT           = null,
	@s_ofi                  smallint      = null,  
	@s_format_date          int           = null,
	@i_llave_conexion       varchar(255)  ,      -- Llave de conexión
	@i_id_prestamo          varchar(30)   ,      -- Id de Prestamo
	@i_nombre_agente        varchar(64)   = null,-- Nombre agente comercial
	@i_cod_sucursal_agente  varchar(64)   = null,-- Código sucursal agente comercial
	@i_fecha                varchar(10)   = null,-- Fecha
	@i_usuario              varchar(10)   = null,-- Usuario operador
	@i_num_transaccion      varchar(10)   = null,-- Número de transaccion
	@i_nom_catalogo         varchar(400)  ,      -- Nombre del Catalogo
	@o_nombre_cliente   	varchar(220)  = null OUT,
	@o_monto_pago   		money         = null OUT     
	
)
as DECLARE
@w_sp_name          varchar(64),
@w_error		    int,
@w_return           int,
@w_cod_cliente      int,
@w_nombre           varchar(255),
@w_p_nombre         varchar(255),
@w_s_nombre         varchar(255),
@w_p_apellido       varchar(64),
@w_s_apellido       varchar(64),
@w_resto_nombre     varchar(255),
@w_nombre_cliente   varchar(20),
@w_monto_pago       money,
@w_num              int,
@w_llave            varchar(255)

select @w_sp_name = 'sp_inter_pag_con_ws'

select @w_num =  codigo from cobis..cl_tabla 
where  tabla = @i_nom_catalogo

select @w_llave     =  valor
from cobis..cl_catalogo
where tabla = @w_num
and   codigo = 'LLAVE'

if @i_llave_conexion <> @w_llave
begin
    select @w_error = 725117 
    goto ERROR	
end


EXEC @w_return = cob_cartera..sp_interfaz_pago
@s_srv                  = @s_srv,
@s_rol                  = @s_rol,      
@s_ssn                  = @s_ssn,          
@s_user                 = @s_user,
@s_date                 = @s_date ,
@s_sesn                 = @s_sesn,
@s_term                 = @s_term,
@s_ofi                  = @s_ofi,              
@i_operacion            = 'Q',
@i_banco                = @i_id_prestamo,
@i_monto                = null,
@i_moneda               = null,
@i_canal                = 3,
@i_aplica_en_linea      = null,
@i_fecha_pago           = null,
@i_forma_pago           = null,             
@i_banco_pago           = null,
@i_cta_banco_pago       = null,
@i_formato_fecha        = @s_format_date,
@i_id_referencia_inter  = null,
@i_referencia_pago      = null,
--@i_debug                = 'S',
@o_total_pago           = @w_monto_pago out

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end	

exec @w_error = cob_cartera..sp_consulta_nombre
@i_banco = @i_id_prestamo,
@o_nombre_cliente = @w_nombre_cliente out

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end	

select @o_nombre_cliente = @w_nombre_cliente,
       @o_monto_pago     = @w_monto_pago
	   
	   
return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error 

return @w_error
GO
