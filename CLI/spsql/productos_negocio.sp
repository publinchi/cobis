/************************************************************************/
/*    Archivo:              productos_negocio.sp                        */
/*    Stored procedure:     sp_productos_negocio                        */
/*    Base de datos:        cobis                                       */
/*    Producto:             Clientes                                    */
/*    Disenado por:         JMEG                                        */
/*    Fecha de escritura:   30-Abril-19                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Almacenar los productos que mas vende un cliente                    */
/*  para realizar el análisis de negocio                                */
/************************************************************************/
/*                    MODIFICACIONES                                    */
/*  FECHA           AUTOR           RAZON                               */
/*  30/04/19         JMEG         Emision Inicial                       */
/*  07/08/19         LGBC         Comentado de validacion               */
/*                                que no tiene sentido                  */
/*  12/06/20         FSAP         Estandarizacion de Clientes           */
/*  10/09/21         BDU          Correcion de validacion               */
/************************************************************************/

use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 
             from sysobjects 
            where name = 'sp_productos_negocio')
   drop proc sp_productos_negocio 
go

CREATE PROC sp_productos_negocio (
            @s_ssn              int      = 0, 
            @s_srv              varchar(30) = null,
            @s_date             datetime = null, 
            @s_user             login    = null, 
            @s_ofi              int      = 0,
            @t_debug            char(1)  = 'N',
            @t_file             varchar(10) = null, 
            @t_trn              int      = 0,
            @t_show_version     bit      = 0,    -- Mostrar la versión del programa
            @i_operacion        char(1), 
            @i_cliente          int,
            @i_cod_negocio      int,
            @i_producto         varchar(60) = null,
            @i_inventario_prod  int      = null,
            @i_ventas_prod      int      = null,
            @i_costo_compra     money    = null, 
            @i_precio_venta     money    = null,
            @i_secuencial       int      = null,
            @o_registro_id      int      = null output
)
AS
begin
DECLARE
            @w_sp_name varchar(20),
            @w_sp_msg  varchar(132),
            @w_cod_negocio int,
            @w_producto varchar(60),
            @w_inventario_prod int, 
            @w_ventas_prod int, 
            @w_costo_compra money, 
            @w_precio_venta money,
            @w_transaccion int,
            @w_num         int,
            @w_param       int, 
            @w_diff        int,
            @w_date        datetime,
            @w_bloqueo     char(1)
    
select @w_sp_name = 'sp_productos_negocio'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
    
select @w_transaccion = tn_trn_code 
  from cobis..cl_ttransaccion 
 where tn_descripcion = 'ANALISIS NEGOCIO ENTE'


--EVALUACION DEL TIPO DE TRANSACCION 
if (@t_trn <> 172084 and @i_operacion = 'I') or  --insert 
   (@t_trn <> 172097 and @i_operacion = 'U') or  --update
   (@t_trn <> 172098 and @i_operacion = 'D') or  --delete
   (@t_trn <> 172099 and @i_operacion = 'S')     --search
begin 
   /* Tipo de transaccion no corresponde */ 
   exec cobis..sp_cerror 
        @t_debug = @t_debug, 
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1720275
   return 1
end
if @i_operacion in ('I', 'U', 'D')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   if @i_cliente is not null and @i_cliente <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_cliente
      if @w_bloqueo = 'S'
      begin
         exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720604
         return 1
      end
   end 
end
--Valida si ya se registró información en analisis de negocio
if not exists (select 1 from cobis..cl_analisis_negocio
              where an_negocio_codigo = @i_cod_negocio and an_cliente_id = @i_cliente) and @i_operacion not in('S')
begin
/* Parametro vacio */
exec cobis..sp_cerror
   @t_from = @w_sp_name,
   @i_num = 1720554;

return 1
end

if @i_operacion = 'I'
begin
    
    if @i_producto is null
    begin 
        /* Parametro vacio */ 
        exec cobis..sp_cerror 
            @t_from  = @w_sp_name,
            @i_num   = 1720294
        return 1
    end
    if @i_inventario_prod is null
    begin 
        /* Parametro vacio */ 
        exec cobis..sp_cerror 
            @t_from  = @w_sp_name,
            @i_num   = 1720294
        return 1
    end
    if @i_ventas_prod is null
    begin 
        /* Parametro vacio */ 
        exec cobis..sp_cerror 
            @t_from  = @w_sp_name,
            @i_num   = 1720294
        return 1
    end
    if @i_costo_compra is null
    begin 
        /* Parametro vacio */ 
        exec cobis..sp_cerror 
            @t_from  = @w_sp_name,
            @i_num   = 1720294
        return 1
    end
    if @i_precio_venta is null
    begin 
        /* Parametro vacio */ 
        exec cobis..sp_cerror 
            @t_from  = @w_sp_name,
            @i_num   = 1720294
        return 1
    end

    --Se inserta la información en la base de datos
    insert into cl_productos_negocio (pn_cliente, pn_negocio_codigo, pn_producto, 
        pn_inventario_total, pn_ventas_total, pn_precio_compra, 
        pn_precio_venta) 
    values (@i_cliente, @i_cod_negocio, @i_producto, 
        @i_inventario_prod, @i_ventas_prod, @i_costo_compra, 
        @i_precio_venta);
        
    select @o_registro_id = @@IDENTITY;
    
    insert into ts_productos_negocio (pn_tipo_transaccion, pn_clase, pn_secuencial, pn_tabla
      , pn_operacion, pn_cliente_id, pn_negocio_codigo, pn_producto_codigo
      , pn_producto, pn_inventario_total, pn_ventas_total, pn_precio_compra
      , pn_precio_venta)
    values(@w_transaccion, 'N', isnull(@s_ssn, 1), 'cl_productos_negocio'
      , @i_operacion, @i_cliente, @i_cod_negocio, @o_registro_id
      , @i_producto, @i_inventario_prod, @i_ventas_prod, @i_costo_compra
      , @i_precio_venta)
      
end

if @i_operacion = 'U'
begin   
  select @w_cod_negocio = pn_negocio_codigo
    , @w_producto = pn_producto
    , @w_inventario_prod = pn_inventario_total
    , @w_ventas_prod = pn_ventas_total
    , @w_costo_compra = pn_precio_compra
    , @w_precio_venta = pn_precio_venta
  from cl_productos_negocio
  where pn_id = @i_secuencial and pn_cliente = @i_cliente
  
  insert into ts_productos_negocio (pn_tipo_transaccion, pn_clase, pn_secuencial, pn_tabla
    , pn_operacion, pn_cliente_id, pn_negocio_codigo, pn_producto_codigo
    , pn_producto, pn_inventario_total, pn_ventas_total, pn_precio_compra
    , pn_precio_venta)
  values(@w_transaccion, 'P', isnull(@s_ssn, 1), 'cl_productos_negocio'
    , @i_operacion, @i_cliente, @w_cod_negocio, @i_secuencial
    , @w_producto, @w_inventario_prod, @w_ventas_prod, @w_costo_compra
    , @w_precio_venta)
  
      update cl_productos_negocio set pn_producto = coalesce(@i_producto, pn_producto)
          , pn_inventario_total = coalesce(@i_inventario_prod, pn_inventario_total)
          , pn_ventas_total = coalesce(@i_ventas_prod, pn_ventas_total)
          , pn_precio_compra = coalesce(@i_costo_compra, pn_precio_compra)
          , pn_precio_venta = coalesce(@i_precio_venta, pn_precio_venta)
      where pn_id = @i_secuencial and pn_cliente = @i_cliente
  
  insert into ts_productos_negocio (pn_tipo_transaccion, pn_clase, pn_secuencial, pn_tabla
    , pn_operacion, pn_cliente_id, pn_negocio_codigo, pn_producto_codigo
    , pn_producto, pn_inventario_total, pn_ventas_total, pn_precio_compra
    , pn_precio_venta)
  values(@w_transaccion, 'A', isnull(@s_ssn, 1), 'cl_productos_negocio'
    , @i_operacion, @i_cliente, @w_cod_negocio, @i_secuencial
    , @i_producto, @i_inventario_prod, @i_ventas_prod, @i_costo_compra
    , @i_precio_venta)
  
end

if @i_operacion = 'D'
begin
  
  select @w_cod_negocio = pn_negocio_codigo
    , @w_producto = pn_producto
    , @w_inventario_prod = pn_inventario_total
    , @w_ventas_prod = pn_ventas_total
    , @w_costo_compra = pn_precio_compra
    , @w_precio_venta = pn_precio_venta
  from cl_productos_negocio
  where pn_id = @i_secuencial and pn_cliente = @i_cliente 
  
      delete cl_productos_negocio
      where pn_id = @i_secuencial and pn_cliente = @i_cliente
  
  insert into ts_productos_negocio (pn_tipo_transaccion, pn_clase, pn_secuencial, pn_tabla
    , pn_operacion, pn_cliente_id, pn_negocio_codigo, pn_producto_codigo
    , pn_producto, pn_inventario_total, pn_ventas_total, pn_precio_compra
    , pn_precio_venta)
  values(@w_transaccion, 'E', isnull(@s_ssn, 1), 'cl_productos_negocio'
    , @i_operacion, @i_cliente, @w_cod_negocio, @i_secuencial
    , @w_producto, @w_inventario_prod, @w_ventas_prod, @w_costo_compra
    , @w_precio_venta)
  
end

if @i_operacion = 'S'
begin
  select pn_id, pn_cliente, pn_producto, pn_inventario_total, 
      pn_ventas_total, pn_precio_compra, pn_precio_venta
  from cl_productos_negocio
  where pn_cliente = @i_cliente and pn_negocio_codigo = @i_cod_negocio 
end

return 0;
END