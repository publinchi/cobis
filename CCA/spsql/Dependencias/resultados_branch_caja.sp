/************************************************************************/
/*      Archivo:                resultados_branch_caja.sp               */
/*      Stored procedure:       sp_resultados_branch_caja               */
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
if exists (select 1 from sysobjects where name = 'sp_resultados_branch_caja')
   drop proc sp_resultados_branch_caja 
go

create proc sp_resultados_branch_caja  ( 
   @i_sldcaja     money       = null,
   @i_idcierre    int         = null,
   @i_ssn_host    int         = null,
   @i_alerta      char(1)     = null,
   @i_alerta_cli  varchar(40) = null
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
select @w_sp_name      =  'sp_resultados_branch_caja'
if exists(select * from cobis..cl_producto where pd_producto = 10)
begin
     exec cob_remesas..sp_resultados_branch_caja
           @i_sldcaja      = @i_sldcaja   
          ,@i_idcierre     = @i_idcierre  
          ,@i_ssn_host     = @i_ssn_host  
          ,@i_alerta       = @i_alerta    
          ,@i_alerta_cli   = @i_alerta_cli
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



