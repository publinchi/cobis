/************************************************************************/
/*      Archivo:                flujocaja_interface.sp                  */
/*      Stored procedure:       sp_flujocaja_interfase                  */
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
if exists (select 1 from sysobjects where name = 'sp_flujocaja_interfase')
   drop proc sp_flujocaja_interfase 
go

create proc sp_flujocaja_interfase(
    @i_oficina int,
    @o_saldo   money out 
)
as
declare @w_error         int, 
		@w_sp_name       varchar(100),
        @w_saldo         money,
		@w_msg     varchar(256)
if exists(select 1 from cobis..cl_producto where pd_producto = 10)
begin
    select @w_saldo = sum(sc_saldo)
    from cob_remesas..re_saldos_caja
    where  sc_moneda = 0
    and sc_oficina   = @i_oficina
    
    select @o_saldo = @w_saldo
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

