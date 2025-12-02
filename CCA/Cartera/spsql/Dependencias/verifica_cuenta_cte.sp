/************************************************************************/
/*      Archivo:                verifica_cuenta_cte.sp                  */
/*      Stored procedure:       sp_verifica_cuenta_cte                  */
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
if exists (select 1 from sysobjects where name = 'sp_verifica_cuenta_cte')
   drop proc sp_verifica_cuenta_cte 
go

create proc sp_verifica_cuenta_cte(
    @i_operacion varchar(5),
    @i_cuenta     cuenta       = null,
    @i_cliente    int          = null,
    @i_moneda     int          = null,
    @i_estado_cta varchar(5)   = null,
    @i_fecha      datetime     = null,
    @i_producto   int          = null,
    @o_cte_estado  varchar(5)   = null out,
    @o_cc_cliente int          = null out,
    @o_cc_nombre  varchar(254) = null out,
    @o_existe     int          = null out 
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
        @w_sql varchar(max),
		@w_msg     varchar(256)
select @w_sp_name      =  'sp_verifica_cuenta_cte'
if exists(select 1 from cobis..cl_producto where pd_producto = 3)
begin
    if @i_operacion = 'VCTE'
    begin
        select @o_existe = 1
        from   cob_cuentas..cc_ctacte
        where  cc_cta_banco  = substring(@i_cuenta,1,16)
        and    cc_estado  = 'A'
    end
    if @i_operacion = 'VCTE2'
    begin
        select @o_existe = 1 
        from   cob_cuentas..cc_ctacte
        where  cc_cta_banco = substring(@i_cuenta,1,16)
        and    cc_cliente   = @i_cliente
    end
    if @i_operacion = 'VCTE3'
    begin
        select 1
        from   cob_cuentas..cc_ctacte
        where  cc_cta_banco = substring(@i_cuenta,1,16)
        and    cc_cliente   = @i_cliente
        and    cc_moneda    = @i_moneda
        and    cc_estado    = 'A'
    end
    if @i_operacion = 'VCTE4'
    begin
       select @o_cte_estado = cc_estado
       from cob_cuentas..cc_ctacte
       where cc_cta_banco = @i_cuenta
    end
    if @i_operacion = 'VCTE5'
    begin
        insert into ca_ctas_no_relaciondas
			select @i_fecha ,getdate(),op_operacion,op_banco,op_cuenta,cc_estado,op_forma_pago,@i_producto
			from cob_cartera..ca_operacion with (nolock),
				 cob_cuentas..cc_ctacte with(nolock)
			where op_cliente  = cc_cliente
			and   op_cuenta   = cc_cta_banco
			and   cc_producto = @i_producto
			and   cc_estado = @i_estado_cta
			and   op_estado in (1,2,4,9)
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

