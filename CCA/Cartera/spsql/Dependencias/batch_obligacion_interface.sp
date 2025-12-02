/************************************************************************/
/*      Archivo:                batch_obligacion_interface.sp           */
/*      Stored procedure:       sp_batch_obligacion_interfase           */
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
/* NOV/09/2020          Luis Ponce         No usar re_cuenta_contractual*/
/************************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_batch_obligacion_interfase')
   drop proc sp_batch_obligacion_interfase 
go

create proc sp_batch_obligacion_interfase(
   @i_op_cliente   int,
   @i_op_moneda    smallint,
   @o_cta_bancaria cuenta out
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
        
select @w_sp_name      =  'sp_batch_obligacion_interfase'

if exists(select 1 from cobis..cl_producto where pd_producto = 4 or pd_producto = 10)
begin
        select @o_cta_bancaria = ah_cta_banco
        from  cob_ahorros..ah_cuenta  with (nolock)
        where ah_cliente = @i_op_cliente
        and   ah_moneda  = @i_op_moneda
        and   ah_estado  in ('A','G') 
/*        and   ah_cta_banco not in (select cc_cta_banco 
                           from cob_remesas..re_cuenta_contractual  with (nolock) --LPO CIDG No usar re_cuenta_contractual porque Cajas no la usa
                           where cc_estado = 'A')
*/                           
        and   ah_cta_banco > '0'
        order by ah_cta_banco
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

