/************************************************************************/
/*      Archivo:                verifica_cuenta_aho.sp                  */
/*      Stored procedure:       sp_verifica_cuenta_aho                  */
/*      Producto:               cob_interface                           */
/*      Disenado por:           Jorge Baque H                           */
/*      Fecha de escritura:     DIC 29 2016                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      SP interface DE DESACOPLAMIENTO                                 */
/************************************************************************/
/*   FECHA                 AUTOR                RAZON                   */
/* DIC 29/2016             JBA              DESACOPLAMIENTO             */     
/************************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_verifica_cuenta_aho')
   drop proc sp_verifica_cuenta_aho 
go

create proc sp_verifica_cuenta_aho(
    @i_operacion varchar(5),
    @i_cuenta     cuenta       = null,
    @i_cliente    int          = null,
    @i_moneda     int          = null,
    @i_estado_cta varchar(5)   = null,
    @i_fecha      datetime     = null,
    @i_producto   int          = null,
    @o_ah_estado  varchar(5)   = null out,
    @o_ah_cliente int          = null out,
    @o_ah_nombre  varchar(254) = null out,
    @o_existe     int          = null out 
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
        
select @w_sp_name      =  'sp_verifica_cuenta_aho'
if exists(select 1 from cobis..cl_producto where pd_producto = 4)
begin
    if @i_operacion = 'VAHO'
    begin
        select @o_existe = 1,
               @o_ah_cliente = ah_cliente,
               @o_ah_nombre  = ah_nombre
        from   cob_ahorros..ah_cuenta
        where  ah_cta_banco  = substring(@i_cuenta,1,16)
        and    ah_estado  = 'A'
    end
    if @i_operacion = 'VAHO2'
    begin
        select @o_existe = 1 
        from   cob_ahorros..ah_cuenta
        where  ah_cta_banco = substring(@i_cuenta,1,16)
        and    ah_cliente   = @i_cliente
    end
    if @i_operacion = 'VAHO3'
    begin
        select 1
        from   cob_ahorros..ah_cuenta
        where  ah_cta_banco = substring(@i_cuenta,1,16)
        and    ah_cliente   = @i_cliente
        and    ah_moneda    = @i_moneda
        and    ah_estado    = 'A'
    end
    if @i_operacion = 'VAHO4'
    begin
       select @o_ah_estado = ah_estado
       from cob_ahorros..ah_cuenta
       where ah_cta_banco = @i_cuenta
    end
    if @i_operacion = 'VAHO5'
    begin
		if @i_estado_cta = 'T'
		begin
			insert into ca_ctas_no_relaciondas
			select @i_fecha ,getdate(),op_operacion,op_banco,op_cuenta,ah_estado,op_forma_pago,@i_producto
			from cob_cartera..ca_operacion with (nolock),
				 cob_ahorros..ah_cuenta with(nolock)
			where op_cliente  = ah_cliente
			and   op_cuenta   = ah_cta_banco
			and   ah_producto = @i_producto
			and   ah_estado in ('C','I')
			and   op_estado in (1,2,4,9)
		end
		else
		begin
			insert into ca_ctas_no_relaciondas
			select @i_fecha ,getdate(),op_operacion,op_banco,op_cuenta,ah_estado,op_forma_pago,@i_producto
			from cob_cartera..ca_operacion with (nolock),
				 cob_ahorros..ah_cuenta with(nolock)
			where op_cliente  = ah_cliente
			and   op_cuenta   = ah_cta_banco
			and   ah_producto = @i_producto
			and   ah_estado = @i_estado_cta
			and   op_estado in (1,2,4,9)
		end
    end
    end
else
begin
	select @w_error = 404000, @w_msg = 'PRODUCTO NO INSTALADO'
    GOTO ERROR
end
return 0
ERROR:
exec cobis..sp_cerror
@t_debug  = 'N',          
@t_file = null,
@t_from   = @w_sp_name,   
@i_num = @w_error,
@i_msg = @w_msg
return @w_error
go


