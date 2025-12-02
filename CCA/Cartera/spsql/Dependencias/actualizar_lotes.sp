/************************************************************************/
/*      Archivo:                actualizar_lotes.sp                     */
/*      Stored procedure:       sp_actualizar_lotes                     */
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
if exists (select 1 from sysobjects where name = 'sp_actualizar_lotes')
   drop proc sp_actualizar_lotes 
go

create proc sp_actualizar_lotes  ( 
     @s_ssn         int          = null,
     @s_date        datetime     = null,
     @s_user        login        = null,
     @s_term        varchar(30)  = null,
     @s_ofi         smallint     = null,
     @s_lsrv        varchar(30)  = null,
     @s_srv         varchar(30)  = null,
     @t_trn         int          = null,
     @i_producto    int          = null,
     @i_instrumento int          = null,
     @i_causa_anul  varchar(5)   = null,
     @i_subtipo     int          = null,
     @i_grupo1      varchar(254) = null,
     @i_llamada_ext varchar(5)   = null
    
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)

select @w_sp_name      =  'sp_actualizar_lotes'
if exists(select * from cobis..cl_producto where pd_producto = 10) --cob_sbancarios? preguntar
begin
     exec @w_error = cob_sbancarios..sp_actualizar_lotes
          @s_ssn          = @s_ssn        
         ,@s_date         = @s_date       
         ,@s_user         = @s_user       
         ,@s_term         = @s_term       
         ,@s_ofi          = @s_ofi        
         ,@s_lsrv         = @s_lsrv       
         ,@s_srv          = @s_srv        
         ,@t_trn          = @t_trn        
         ,@i_producto     = @i_producto   
         ,@i_instrumento  = @i_instrumento
         ,@i_causa_anul   = @i_causa_anul 
         ,@i_subtipo      = @i_subtipo    
         ,@i_grupo1       = @i_grupo1     
         ,@i_llamada_ext  = @i_llamada_ext
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

