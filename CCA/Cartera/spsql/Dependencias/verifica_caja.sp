/************************************************************************/
/*      Archivo:                verifica_caja.sp                        */
/*      Stored procedure:       sp_verifica_caja                        */
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
if exists (select 1 from sysobjects where name = 'sp_verifica_caja')
   drop proc sp_verifica_caja 
go

create proc sp_verifica_caja  ( 
       @t_trn      smallint    = null,
       @s_user     login       = null,
       @s_ofi      smallint    = null,
       @s_srv      varchar(30) = null,
       @s_date     datetime    = null,
       @i_filial   smallint    = null,
       @i_ofi      smallint    = null,
       @i_mon      int         = null,
       @i_idcaja   int         = null
    
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)

select @w_sp_name      =  'sp_verifica_caja'
if exists(select * from cobis..cl_producto where pd_producto = 10)
begin
     exec @w_error = cob_remesas..sp_verifica_caja
     @t_trn      = @t_trn,          
     @s_user     = @s_user,
     @s_ofi      = @s_ofi,
     @s_srv      = @s_srv,
     @s_date     = @s_date,
     @i_filial   = @i_filial,
     @i_ofi      = @s_ofi,
     @i_mon      = @i_mon,
     @i_idcaja   = @i_idcaja
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


