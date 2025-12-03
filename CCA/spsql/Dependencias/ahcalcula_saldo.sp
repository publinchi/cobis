/************************************************************************/
/*      Archivo:                ahcalcula_saldo.sp                      */
/*      Stored procedure:       sp_ahcalcula_saldo                      */
/*      Producto:               cob_interface                           */
/*      Disenado por:           Jorge Baque H                           */
/*      Fecha de escritura:     DIC 27 2016                             */
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
/* DIC 27/2016             JBA              DESACOPLAMIENTO             */     
/************************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_ahcalcula_saldo')
   drop proc sp_ahcalcula_saldo 
go

create proc sp_ahcalcula_saldo  ( 
    @i_cuenta           varchar(24),
    @i_fecha            datetime,
    @o_saldo_para_girar money out,
    @o_saldo_contable   money  out
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)

select @w_sp_name      =  'sp_tramite'
if exists(select * from cobis..cl_producto where pd_producto = 4)
begin
    exec @w_error = cob_ahorros..sp_ahcalcula_saldo
    @i_cuenta           = @i_cuenta,
    @i_fecha            = @i_fecha,
    @o_saldo_para_girar = @o_saldo_para_girar out,
    @o_saldo_contable   = @o_saldo_contable  out
    if @w_error <> 0
		GOTO ERROR
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

