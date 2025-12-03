/************************************************************************/
/*      Archivo:                crear_contragarantias_interface.sp      */
/*      Stored procedure:       sp_crear_contragarantias_interface      */
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
if exists (select 1 from sysobjects where name = 'sp_crear_contragarantias_interface')
   drop proc sp_crear_contragarantias_interface 
go

create proc sp_crear_contragarantias_interface(
   @i_cuenta        char(16),
   @i_operacion     char(4),
   @o_existe        int          = null out,
   @o_cliente       int          = null out,
   @o_banca         int          = null out,
   @o_nombre        varchar(254) = null out,
   @o_ofl           int          = null out,
   @o_descdir_ec    varchar(254) = null out,
   @o_oficina       int          = null out,
   @o_telefono      char(12)     = null out
   
   
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
        
select @w_sp_name      =  'sp_crear_contragarantias_interface'

if exists(select 1 from cobis..cl_producto where pd_producto = 3)
begin
    if @i_operacion = 'V'
        select @o_existe = 1
        from  cob_cuentas..cc_ctacte
        where cc_cta_banco = @i_cuenta
        and   cc_estado    = 'C'
    if @i_operacion = 'S'
        select  @o_cliente    = cc_cliente,
                @o_banca      = en_banca,
                @o_nombre     = en_nomlar,
                @o_ofl        = en_oficial,
                @o_descdir_ec = cc_descripcion_ec,
                @o_oficina    = cc_oficina,
                @o_telefono   = cc_telefono
        from cob_cuentas..cc_ctacte, cobis..cl_ente
        Where en_ente    = cc_cliente
        and cc_cta_banco = @i_cuenta
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

