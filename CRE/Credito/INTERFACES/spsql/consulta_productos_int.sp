/************************************************************************/
/*  Archivo:                consulta_productos_int.sp                   */
/*  Stored procedure:       sp_consulta_productos_int                   */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Crédito                                     */
/*  Diseñado por:           Patricio Mora                               */
/*  Fecha de Documentacion: 20/Sep/2021                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Consulta todos los productos contratados por el cliente.            */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*     FECHA        AUTOR            RAZON                              */
/*  20/09/2021      pmora            Emision Inicial                    */
/*  21/01/2022      wlopez           ORI-S586466-GFI                    */
/*  07/04/2022      cobando          Se agrega consulta lineas          */
/************************************************************************/
use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_consulta_productos_int')
    drop proc sp_consulta_productos_int
go

create procedure sp_consulta_productos_int
    (
       @s_ssn                    int            = null,
       @s_user                   varchar(30)    = null,
       @s_sesn                   int            = null,
       @s_term                   varchar(30)    = null,
       @s_date                   datetime       = null,
       @s_srv                    varchar(30)    = null,
       @s_lsrv                   varchar(30)    = null,
       @s_rol                    smallint       = null,
       @s_ofi                    smallint       = null,
       @s_org_err                char(1)        = null,
       @s_error                  int            = null,
       @s_sev                    tinyint        = null,
       @s_msg                    descripcion    = null,
       @s_org                    char(1)        = null,
       @s_culture                varchar(10)    = null,
       @t_rty                    char(1)        = null,
       @t_trn                    int            = null,
       @t_debug                  char(1)        = 'N',
       @t_file                   varchar(14)    = null,
       @t_from                   varchar(30)    = null,
       @i_canal                  tinyint        = 0,            -- Canal: 0=Frontend  1=Batch   2=Workflow
       @i_cliente                int      
    )
as
declare
       @w_error                  int,
       @w_return                 int,
       @w_sp_name                varchar(32),
       @w_ente                   int,
       @w_tipo_producto          varchar(64),
       @w_numero_operacion       varchar(30),
       @w_cliente_rol            varchar(30),
       @w_moneda                 smallint,   
       @w_saldo_operacion        money,      
       @w_estado_operacion       varchar(30)

select @w_sp_name = 'sp_consulta_productos_int',
       @w_error   = 0

-- Cliente existe en la cl_ente
select @w_ente = en_ente
  from cobis..cl_ente
 where en_ente = @i_cliente
if @@rowcount = 0
 begin 
   select @w_error = 2110190
   goto ERROR
 end

--Llenar garantias por cliente
exec @w_return = cob_custodia..sp_gar_producto_x_cliente
     @i_cliente = @i_cliente

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   goto ERROR
end

--Llenar operaciones cartera por cliente
exec @w_return = cob_cartera..sp_cca_producto_x_cliente
     @i_cliente = @i_cliente

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   goto ERROR
end

--Llenar lineas por cliente
exec @w_return = cob_credito..sp_lin_producto_x_cliente
     @i_cliente = @i_cliente

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin
   goto ERROR
end

select 'tipo_producto'     = cp_tipo_producto,   
       'numero_operacion'  = cp_numero_operacion,
       'cliente_rol'       = cp_cliente_rol,     
       'moneda'            = cp_moneda,          
       'saldo_operacion'   = cp_saldo_operacion, 
       'estado_operacion'  = cp_estado_operacion
from cob_interface..in_cons_productos_cl
where cp_cliente = @i_cliente
if @@rowcount = 0
begin 
   select @w_error = 2110191
   goto ERROR
end

return 0

ERROR:
   --Devolver mensaje de Error
   if @i_canal in (0,1) --Frontend o batch
     begin
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = @w_error
      return @w_error
     end
   else
      return @w_error
    
go
