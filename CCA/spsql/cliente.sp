/************************************************************************/
/*  Archivo:            cliente.sp                                      */
/*  Stored procedure:   sp_cliente                                      */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Credito y Cartera                               */
/*  Disenado por:       Sandra Ortiz                                    */
/*  Fecha de escritura: 07-07-1994                                      */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "COBISCORP".                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/  
/*              PROPOSITO                                               */
/*  Este programa mueve la informacion de las tablas temporales         */
/*  usadas para los clientes Deudor y Codeudores.                       */
/************************************************************************/  
/*              MODIFICACIONES                                          */
/*  FECHA       AUTOR       RAZON                                       */
/*  07-07-1994  S Ortiz     Emision inicial                             */
/*  01-06-2022  G. Fernandez     Se comenta prints                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cliente')

    drop proc sp_cliente
go
create proc sp_cliente (
    @t_debug        char(1)     = 'N',
    @t_file         varchar(10) = null,
    @t_from         varchar(32) = null,
    @s_date         datetime    = null,
    @i_usuario      login,
    @i_sesion       int,
    @i_oficina      smallint    = null,
    @i_producto     tinyint     = null,
    @i_tipo         char(1)     = null,
    @i_monto        money       = null,
    @i_moneda       tinyint     = null,
    @i_fecha        datetime    = null,
    @i_fecha_fin    datetime    = null,
    @i_banco        cuenta,     
    @i_operacion    char(1)     = null,
    @i_claseoper    cuenta      = 'A'
)
as

declare
@w_sp_name               varchar(30),
@w_return                int,
@w_siguiente             int,
@w_num_oficial           int,
@w_codeudores            tinyint,
@w_inicial               tinyint,
@w_rel_deudor            int,
@w_rel_codeudor          int,
@w_cod_banco             int,
@w_rol                   catalogo,
@w_titular               int,
@w_dias                  smallint,
@w_dp_det_producto       int,
@w_filial                tinyint,  
@w_cliente               int,      
@w_direccion             int,      
@w_oficina               smallint,
@w_tramite               int,
@w_rowcount              int 


/*  Captura nombre de Stored Procedure  */
select  @w_sp_name   = 'sp_cliente',
        @w_siguiente = 0

if @i_operacion = 'I' 
begin
   if not exists (select *
                  from ca_cliente_tmp
                  where   clt_user      = @i_usuario
                  and     clt_sesion    = @i_sesion)
      begin            
         --PRINT 'cliente.sp salioooooooooooo por aqui @i_usuario' + cast(@i_usuario as varchar) + '@i_sesion' + cast(@i_sesion as varchar)
         return 0     
      end

   exec cobis..sp_cseqnos
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = @w_sp_name,
   @i_tabla = 'cl_det_producto',
   @o_siguiente = @w_siguiente out

   select @w_num_oficial = fu_funcionario
   from cobis..cl_funcionario
   where fu_login = @i_usuario
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount != 1 
   begin
      --GFP se suprime print
      --PRINT 'error en sp_cliente @i_usuario %1!' + cast (@i_usuario as varchar)
     return 701051
   end

   ---  Creacion de Registro en cl_det_producto 
   select @w_dias = datediff(dd, opt_fecha_ini, @i_fecha_fin),
          @w_oficina   = opt_oficina,      
          @w_cliente   = opt_cliente,      
          @w_direccion = opt_direccion,
          @w_tramite   = isnull(opt_tramite,0)
   from ca_operacion_tmp
   where opt_banco = @i_banco


   if @w_tramite = 0
   begin
      select @w_cliente =  de_cliente
      from cob_credito..cr_deudores
      where de_tramite = @w_tramite
      and   de_rol     = 'D'
      
      --Borrar los deudores para dejar los definitivos
      --cargados en la tabla  ca_cliente_tmp
      delete  cob_credito..cr_deudores
      where de_tramite = @w_tramite
      
      insert into cob_credito..cr_deudores
      select @w_tramite,clt_cliente,    clt_rol, clt_ced_ruc,'S', 'N'
      from  ca_cliente_tmp
      where   clt_user      = @i_usuario
      and      clt_sesion    = @i_sesion
      and     clt_operacion = @i_claseoper
      
      if @@error != 0
         return 708154
      
   end

   select @w_filial = of_filial
   from cobis..cl_oficina
   where of_oficina = @w_oficina
   set transaction isolation level read uncommitted


   delete cobis..cl_cliente
   from cobis..cl_det_producto
   where cl_det_producto = dp_det_producto
   and dp_producto = 7
   and dp_cuenta = @i_banco

   delete from cobis..cl_det_producto 
   where  dp_cuenta   = @i_banco
   and    dp_producto = 7



   insert into cobis..cl_det_producto (
   dp_det_producto, dp_oficina,       dp_producto,
   dp_tipo,         dp_moneda,        dp_fecha, 
   dp_comentario,   dp_monto,         dp_cuenta,
   dp_estado_ser,   dp_autorizante,   dp_oficial_cta, 
   dp_tiempo,       dp_valor_inicial, dp_tipo_producto,
   dp_tprestamo,    dp_valor_promedio,dp_rol_cliente,
   dp_filial,       dp_cliente_ec,    dp_direccion_ec)   
   values (
   @w_siguiente,    @i_oficina,     @i_producto, 
   @i_tipo,         @i_moneda,      @i_fecha, 
   'OP. CARTERA CL',@i_monto,       @i_banco, 
   'V',             @w_num_oficial, @w_num_oficial,
   @w_dias,         0,              '0',
   0,               0,              'T',
   @w_filial,       @w_cliente,     1) ---@w_direccion)  

   if @@error != 0 
   begin
     --GFP se suprime print
     --PRINT 'cliente.sp  dp_cuenta ' + cast(@i_banco as varchar) + ' dp_det_producto '+ cast(@w_siguiente as varchar) + ' tipo '+  cast(@i_tipo as varchar)
     return 703027
   end
 

   /*  Creacion de Registros de Clientes  */

   insert into cobis..cl_cliente (
   cl_cliente,  cl_det_producto, cl_rol, cl_ced_ruc,  cl_fecha)
   select   
   clt_cliente, @w_siguiente,    clt_rol, clt_ced_ruc, @i_fecha
   from ca_cliente_tmp
   where   clt_user      = @i_usuario
   and     clt_sesion    = @i_sesion
   and     clt_operacion = @i_claseoper
  
   if @@error != 0 return 703028
 

   update cobis..cl_ente
   set en_cliente = 'S'
   where en_ente = @w_cliente

end


if @i_operacion = 'U' begin
   if not exists (select * 
                  from ca_cliente_tmp 
                  where   clt_user      = @i_usuario
                  and     clt_sesion    = @i_sesion)
      return 0

end

if @i_operacion = 'R' begin
   if not exists (select *
                  from ca_cliente_tmp
                  where   clt_user      = @i_usuario
                  and     clt_sesion    = @i_sesion)
      return 0

   select @w_dp_det_producto = dp_det_producto
   from cobis..cl_det_producto
   where  dp_cuenta   = @i_banco
   and    dp_producto = 7
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 return 701047

   delete from cobis..cl_cliente
   where cl_det_producto =  @w_dp_det_producto

   insert into cobis..cl_cliente (
   cl_cliente,  cl_det_producto,    cl_rol,  cl_ced_ruc, cl_fecha)
   select
   clt_cliente, @w_dp_det_producto, clt_rol, clt_ced_ruc, @s_date
   from    ca_cliente_tmp
   where   clt_user      = @i_usuario
   and     clt_sesion    = @i_sesion
   and     clt_operacion = @i_claseoper

   if @@error != 0 return 703028
end

return 0 

go
