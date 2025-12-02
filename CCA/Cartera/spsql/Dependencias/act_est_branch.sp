/************************************************************************/
/*      Archivo:                act_est_branch.sp                       */
/*      Stored procedure:       sp_act_est_branch                       */
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
if exists (select 1 from sysobjects where name = 'sp_act_est_branch')
   drop proc sp_act_est_branch 
go

create proc sp_act_est_branch  ( 
    @s_user         login       = null,
    @s_date         datetime    = null,
    @i_cliente      int         = null,
    @i_cuenta       int         = null,
    @i_accion       varchar(5)  = null,
    @i_descripcion  varchar(254)= null
    
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)

select @w_sp_name      =  'sp_act_est_branch'
if exists(select * from cobis..cl_producto where pd_producto = 10)
begin
/*
    exec @w_error = cob_remesas..sp_act_est_branch
            @s_user        = @s_user       
           ,@s_date        = @s_date       
           ,@i_cliente     = @i_cliente    
           ,@i_cuenta      = @i_cuenta     
           ,@i_accion      = @i_accion     
           ,@i_descripcion = @i_descripcion
    if @w_error <> 0
		GOTO ERROR
*/
select 1

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

