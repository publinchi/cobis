/************************************************************************/
/*      Archivo:                modificar_suspencion.sp                 */
/*      Stored procedure:       sp_modificar_suspencion                 */
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
if exists (select 1 from sysobjects where name = 'sp_modificar_suspencion')
   drop proc sp_modificar_suspencion 
go

create proc sp_modificar_suspencion  ( 
       @t_trn              int          = null,
       @s_date             datetime     = null,
       @s_user             login        = null,
       @s_sesn             int          = null,
       @s_ssn              int          = null,
       @s_rol              tinyint      = null,
       @s_term             varchar (30) = null,
       @s_srv              varchar (30) = null,
       @s_lsrv             varchar (30) = null,
       @s_ofi              int          = null,
       @s_org              char(1)      = null,
       @i_localizacion     char(1)      = null,
       @i_final            char(1)      = null,
       @i_grupo1           varchar(254) = null
    
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
select @w_sp_name      =  'sp_modificar_suspencion'

/*
if exists(select * from cobis..cl_producto where pd_producto = 10)
begin
     exec @w_error = cob_sbancarios..sp_modificar_suspencion
          @t_trn              = @t_trn         
         ,@s_date             = @s_date        
         ,@s_user             = @s_user        
         ,@s_sesn             = @s_sesn        
         ,@s_ssn              = @s_ssn         
         ,@s_rol              = @s_rol         
         ,@s_term             = @s_term        
         ,@s_srv              = @s_srv         
         ,@s_lsrv             = @s_lsrv        
         ,@s_ofi              = @s_ofi         
         ,@s_org              = @s_org         
         ,@i_localizacion     = @i_localizacion
         ,@i_final            = @i_final       
         ,@i_grupo1           = @i_grupo1      
    if @w_error <> 0
		GOTO ERROR
end
else
begin
	select @w_error = 404000, @w_msg = 'PRODUCTO NO INSTALADO'
    GOTO ERROR
end
*/
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

