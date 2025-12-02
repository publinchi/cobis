/************************************************************************/
/*      Archivo:                fecha_habil.sp                          */
/*      Stored procedure:       sp_fecha_habil                          */
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
if exists (select 1 from sysobjects where name = 'sp_fecha_habil')
   drop proc sp_fecha_habil 
go

create proc sp_fecha_habil  ( 
    @i_fecha     datetime   = null,
    @i_oficina   int        = null,
    @i_efec_dia  varchar(3) = null,
    @i_finsemana varchar(3) = null,
    @w_dias_ret  int        = null,
    @o_fecha_sig datetime   = null out
    
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
        @w_return int,
		@w_msg     varchar(256)
select @w_sp_name      =  'sp_fecha_habil'
if exists(select * from cobis..cl_producto where pd_producto = 10)
begin
    exec @w_return = cob_remesas..sp_fecha_habil
    @i_fecha     = @i_fecha    
    ,@i_oficina   = @i_oficina  
    ,@i_efec_dia  = @i_efec_dia 
    ,@i_finsemana = @i_finsemana
    ,@w_dias_ret  = @w_dias_ret 
    ,@o_fecha_sig = @o_fecha_sig out
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

