/************************************************************************/
/*      Archivo:                cta_cobis_interface.sp                  */
/*      Stored procedure:       sp_cta_cobis_interfase                  */
/*      Producto:               cob_interface                           */
/*      Disenado por:           Jorge Baque H                           */
/*      Fecha de escritura:     ENE 04 2017                             */
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
/* ENE 04/2017             JBA              DESACOPLAMIENTO             */     
/* NOV/09/2020         Luis Ponce          No usar re_cuenta_contractual*/
/************************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_cta_cobis_interfase')
   drop proc sp_cta_cobis_interfase 
go

create proc sp_cta_cobis_interfase(
   @i_operacion       varchar(5),
   @i_producto        varchar(5),
   @i_cuenta          cuenta    = null,
   @i_prod_bancario   int       = null,
   @i_oficina         int       = null,
   @i_moneda          int       = null,
   @i_cliente         int       = null
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
        
select @w_sp_name      =  'sp_cta_cobis_interfase'


if exists(select 1 from cobis..cl_producto where pd_producto = @i_producto)--4 or pd_producto = 3 or pd_producto = 10)
begin
    if @i_operacion = 'op1'
    begin
    set rowcount 20
            select 
            'Cuenta' = ah_cta_banco,
            'Cliente' = ah_cliente,
            'Nombre'  = ah_nombre
            from  cob_ahorros..ah_cuenta with (nolock)
            where ah_cliente = @i_cliente
            and   ah_moneda  = @i_moneda
            and   ah_estado  in ('A','G')
/*            and   ah_cta_banco not in (select cc_cta_banco 
                                    from cob_remesas..re_cuenta_contractual --LPO CDIG No usar re_cuenta_contractual porque Cajas no la usa
                                    where cc_estado = 'A')
*/                                    
            and   ah_cta_banco > '0'
            and   ah_prod_banc <> @i_prod_bancario
            order by ah_cta_banco
    set rowcount 0  
    end
      
    if @i_operacion = 'op2'
    begin
        select 'CUENTA'      = cg_cuenta,
              'DESCRIPCION' = 'CHEQUE DE GERENCIA' 
        from cob_cuentas..cc_cta_gerencia
        where cg_oficina = @i_oficina
    end
	
    if @i_operacion = 'op3'
    begin 
    set rowcount 20
            select 
            'Cuenta' = cc_cta_banco,
            'Cliente' = cc_cliente,
            'Nombre'  = cc_nombre
            from  cob_cuentas..cc_ctacte 
            where cc_cliente = @i_cliente
            and   cc_moneda  = @i_moneda
            and   cc_estado  = 'A'
            and   cc_cta_banco > @i_cuenta
            order by cc_cta_banco
    set rowcount 0  
    end   
    
	if @i_operacion = 'op4'
		begin
		if exists 
		(select 1
		from   cob_ahorros..ah_cuenta with (nolock)
		where ah_cta_banco  = @i_cuenta 
		and   ah_cliente = @i_cliente
		and   ah_moneda  = @i_moneda
		and   ah_estado  = 'A'
/*		and   ah_cta_banco in (select cc_cta_banco 
		from cob_remesas..re_cuenta_contractual --LPO CDIG No usar re_cuenta_contractual porque Cajas no la usa
		where cc_estado = 'A')
*/		
		and   ah_prod_banc <> @i_prod_bancario)
		begin
			select @w_error = 724521
			goto ERROR
		end
	end 

	if @i_operacion = 'op5'
		begin 
		if not exists 
		(select 1
		from   cob_cuentas..cc_ctacte 
		where cc_cta_banco  = @i_cuenta 
		and   cc_cliente = @i_cliente
		and   cc_moneda  = @i_moneda
		and   cc_estado  = 'A') begin
			select @w_error = 710020
			goto ERROR
			end
		end 
        
    if @i_operacion = 'op6'
    begin
    if not exists 
		(select 1
		from   cob_ahorros..ah_cuenta with (nolock)
		where ah_cta_banco  = @i_cuenta 
		and   ah_cliente = @i_cliente
		and   ah_moneda  = @i_moneda
		and   ah_estado  in( 'A','G')
		and   ah_prod_banc <> @i_prod_bancario
		)
		begin
			print 'ERROR Cuenta Digitada ' + cast ( @i_cuenta as varchar) 
			select @w_error = 724553
			goto ERROR
		end
         
		if exists 
		(select 1
		from   cob_ahorros..ah_cuenta with (nolock)
		where ah_cta_banco  = @i_cuenta 
		and   ah_cliente = @i_cliente
		and   ah_moneda  = @i_moneda
		and   ah_estado  = 'A'
/*		and   ah_cta_banco in (select cc_cta_banco 
		from cob_remesas..re_cuenta_contractual --LPO CDIG No usar re_cuenta_contractual porque Cajas no la usa
		where cc_estado = 'A')
*/		
		and   ah_prod_banc <> @i_prod_bancario)
		begin
			select @w_error = 724521
			goto ERROR
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

