/************************************************************************/
/*  Archivo:                productos_negocio_int.sp                    */
/*  Stored procedure:       sp_productos_negocio_int                    */
/*  Producto:               Clientes                                    */
/*  Disenado por:           Bruno Duenas                                */
/*  Fecha de escritura:     03-09-2021                                  */
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
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_productos_negocio                       */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA       AUTOR           RAZON                                   */
/*  03-09-2021  BDU             Emision inicial                         */
/*  10-09-2021  ACA             Operacion S, validaciones negativos y 0 */
/*  01-04-2022  PJA             Se agrega Operacion D                   */
/************************************************************************/


use cob_interface
GO
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
if exists (select 1 from sysobjects where name = 'sp_productos_negocio_int')
   drop proc sp_productos_negocio_int
go

create proc sp_productos_negocio_int (
            @s_culture          varchar(10) = 'NEUTRAL',
            @s_ssn              int         = 0, 
            @s_srv              varchar(30) = null,
            @s_date             datetime    = null, 
            @s_user             login       = null, 
            @s_ofi              int         = 0,
            @t_debug            char(1)     = 'N',
            @t_file             varchar(10) = null, 
            @t_trn              int         = 0,
            @t_show_version     bit         = 0,    -- Mostrar la versión del programa
            @i_operacion        char(1), 
            @i_cliente          int,
            @i_cod_negocio      int,
            @i_producto         varchar(60) = null,
            @i_inventario_prod  int         = null,
            @i_ventas_prod      int         = null,
            @i_costo_compra     money       = null, 
            @i_precio_venta     money       = null,
            @i_secuencial       int         = null,
            @o_registro_id      int         = null output
       
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_oficial               int,
        @w_trn_dir               int,
        @w_error                 int,
        @w_operacion             char(1),
        @w_existente             bit,
        @w_init_msg_error        varchar(256),
        @w_valor_campo           varchar(30),
        @w_rows                  smallint
        
/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_productos_negocio_int',
@w_operacion        = '',
@w_error            = 1720548

   
/* VALIDACIONES */

/* NUMERO DE TRANSACCION */
if @t_trn <>  172205
begin 
   /* Tipo de transaccion no corresponde */ 
   select @w_error = 1720275 
   goto ERROR_FIN
end


if (@i_operacion in ('I','U','D'))
begin

   if isnull(@i_cliente,'') = '' and @i_cliente <> 0
   begin
      select @w_valor_campo  = 'personSequential'
      goto VALIDAR_ERROR
   end

	if (@i_cliente) < 0
	begin
	  select @w_valor_campo = 'personSequential'
	  goto VALIDAR_ERROR
	end
	
   if isnull(@i_cod_negocio,'') = '' and @i_cod_negocio <> 0
   begin
      select @w_valor_campo  = 'businessSequential'
      goto VALIDAR_ERROR
   end

	if (@i_cod_negocio) < 0
	begin
	  select @w_valor_campo = 'businessSequential'
	  goto VALIDAR_ERROR
	end
	
   if isnull(@i_secuencial,'') = '' and @i_secuencial <> 0 and @i_operacion in ('U','D')
   begin
      select @w_valor_campo  = 'productSequential'
      goto VALIDAR_ERROR
   end
 

	if (@i_secuencial) < 0 and @i_operacion in ('U','D')
	begin
	  select @w_valor_campo = 'productSequential'
	  goto VALIDAR_ERROR
	end

   
    if (@i_operacion in ('I','U'))
    begin
       if isnull(@i_producto,'') = ''
       begin
          select @w_valor_campo  = 'productName'
          goto VALIDAR_ERROR
       end

       if isnull(@i_ventas_prod,'') = '' and @i_ventas_prod <> 0
       begin
          select @w_valor_campo  = 'sales'
          goto VALIDAR_ERROR
       end

       if isnull(@i_inventario_prod,'') = '' and @i_inventario_prod <> 0
       begin
          select @w_valor_campo  = 'quantity'
          goto VALIDAR_ERROR
       end

       if isnull(@i_costo_compra,'') = '' and @i_costo_compra <> 0
       begin
          select @w_valor_campo  = 'purchaseValue'
          goto VALIDAR_ERROR
       end

       if isnull(@i_precio_venta,'') = '' and @i_precio_venta <> 0
       begin
          select @w_valor_campo  = 'retailValue'
          goto VALIDAR_ERROR
       end

		/* CAMPOS NEGATIVOS */
       if (@i_ventas_prod) < 0
       begin
          select @w_valor_campo = 'sales'
          goto VALIDAR_ERROR
       end
       if (@i_inventario_prod) < 0
       begin
          select @w_valor_campo = 'quantity'
          goto VALIDAR_ERROR
       end
       if (@i_costo_compra) < 0
       begin
          select @w_valor_campo = 'purchaseValue'
          goto VALIDAR_ERROR
       end
       if (@i_precio_venta) < 0
       begin
          select @w_valor_campo = 'retailValue'
          goto VALIDAR_ERROR
       end

    end -- Fin insert and update

   /* VALIDAR QUE EL CLIENTE EXISTA */

   if not exists(select 1 from cobis..cl_ente where en_ente = @i_cliente)
   begin
      select @w_error = 1720411 
      goto ERROR_FIN 
   end

   /* VALIDAR QUE EL NEGOCIO EXISTA */

   if not exists(select 1 from cobis..cl_negocio_cliente where nc_codigo = @i_cod_negocio and nc_ente = @i_cliente)
   begin
      select @w_error = 1720285 
      goto ERROR_FIN 
   end

   /* VALIDAR QUE EL PRODUCTO DE NEGOCIO EXISTA */

   if @i_operacion in('U','D') and not exists(select 1 from cobis..cl_productos_negocio where pn_id = @i_secuencial and pn_cliente = @i_cliente)
   begin
      select @w_error = 1720555 
      goto ERROR_FIN 
   end
 
   /* FIN VALIDACIONES */
   /* NOMBRE DE PRODUCTO A MAYUSCULAS */
   set @i_producto = upper(@i_producto)

   if      @i_operacion = 'I' select @t_trn = 172084
   else if @i_operacion = 'U' select @t_trn = 172097
   else if @i_operacion = 'D' select @t_trn = 172098
   
      exec @w_error = cobis..sp_productos_negocio
      @s_ssn                = @s_ssn,       
      @s_srv                = @s_srv,            
      @s_date               = @s_date,           
      @s_user               = @s_user,           
      @s_ofi                = @s_ofi,           
      @t_debug              = @t_debug,          
      @t_file               = @t_file,           
      @t_trn                = @t_trn,            
      @t_show_version       = @t_show_version,   
      @i_operacion          = @i_operacion,      
      @i_cliente            = @i_cliente,        
      @i_cod_negocio        = @i_cod_negocio,    
      @i_producto           = @i_producto,       
      @i_inventario_prod    = @i_inventario_prod,
      @i_ventas_prod        = @i_ventas_prod,    
      @i_costo_compra       = @i_costo_compra,   
      @i_precio_venta       = @i_precio_venta,   
      @i_secuencial         = @i_secuencial,     
      @o_registro_id        = @o_registro_id out    
   
   if @w_error <> 0 or @o_registro_id is null
   begin   
      goto ERROR_FIN 
   end
   return 0
end -- Fin insert and update and delete

if (@i_operacion = 'S')
begin
   /* CAMPOS REQUERIDOS */
   if isnull(@i_cliente,'') = '' and @i_cliente <> 0
   begin
      select @w_valor_campo  = 'personSequential' 
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_cod_negocio,'') = '' and @i_cod_negocio <> 0
   begin
      select @w_valor_campo  = 'businessSequential'
      goto VALIDAR_ERROR   
   end

   if not exists (select 1 from cobis..cl_productos_negocio where pn_cliente = @i_cliente and pn_negocio_codigo = @i_cod_negocio)
   begin
      select @w_error = 1720289
       goto ERROR_FIN
   end

   exec cobis..sp_productos_negocio
      @s_ssn          = @s_ssn, 
      @s_srv          = @s_srv,
      @s_date         = @s_date,
      @s_user         = @s_user, 
      @s_ofi          = @s_ofi,
      @t_debug        = @t_debug,
      @t_file         = @t_file, 
      @t_trn          = 172099,
      @i_operacion    = @i_operacion,
      @i_cliente      = @i_cliente,
      @i_cod_negocio = @i_cod_negocio

   return 0
end

VALIDAR_ERROR:
select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo , @w_error, @s_culture)
goto ERROR_FIN


ERROR_FIN:

exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_msg      = @w_sp_msg,
         @i_num      = @w_error
         
return @w_error

go
