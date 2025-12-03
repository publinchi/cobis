/************************************************************************/
/*      Archivo:                genera_orden.sp                         */
/*      Stored procedure:       sp_genera_orden                         */
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
if exists (select 1 from sysobjects where name = 'sp_genera_orden')
   drop proc sp_genera_orden 
go

create proc sp_genera_orden ( 
   @s_date        datetime,
   @s_user        login,
   @s_ofi         smallint    = null,
   @i_ofi         smallint    = null,
   @i_operacion   char(1),
   @i_causa       varchar(10) = null,
   @i_ente        int         = 0,
   @i_cedruc      varchar(30) = null,
   @i_valor       money       = 0,
   @i_tipo        char(1)     = '', --'C' -> Orden de Cobro/Ingreso, 'P' -> Orden de Pago/Egreso
   @i_idorden     int         = 0, 
   @i_ref1        int         = 0,
   @i_ref2        int         = 0,
   @i_ref3        varchar(30) = '',
   @i_debug       char(1)     = 'N',
   @i_interfaz    char(1)     = 'N',
   @o_idorden     int         = null out,
   @o_pendiente   char(1)     = null out,
   @o_oficina     smallint    = null out,
   @o_valor       money       = null out
)
as
declare @w_error int, 
		@w_sp_name varchar(100),
		@w_msg     varchar(256)
select @w_sp_name      =  'sp_genera_orden'
if exists(select 1 from cobis..cl_producto where pd_producto = 10)
begin
    exec @w_error = cob_remesas..sp_genera_orden
                @s_date           = @s_date        
               ,@s_user           = @s_user   
			   ,@i_ofi            = @s_ofi     
               ,@i_operacion      = @i_operacion   
               ,@i_causa          = @i_causa       
               ,@i_ente           = @i_ente
			   ,@i_valor          = @i_valor			          
               ,@i_tipo           = @i_tipo        
               ,@i_idorden        = @i_idorden     
               ,@i_ref1           = @i_ref1        
               ,@i_ref2           = @i_ref2        
               ,@i_ref3           = @i_ref3        
               ,@i_interfaz       = @i_interfaz    
			   ,@o_idorden        = @o_idorden out 
    if @w_error != 0
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
