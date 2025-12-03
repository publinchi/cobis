/************************************************************************/ 
/*    ARCHIVO:         7x24_val_producto.sp                             */ 
/*    NOMBRE LOGICO:   sp_7x24_valida_producto                          */ 
/*   Base de datos:    cob_cartera                                      */
/*   Producto:         Cartera                                          */
/*   Disenado por:     Kevin Rodríguez                                  */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*  Procedimiento encargado de ejecutar programa orquestador de proce-  */
/*  so de pagos para la versión de Enlace                               */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA       AUTOR           RAZON                                  */ 
/* 19/12/2022    K. Rodríguez    Versión Inicial                        */
/*                                                                      */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_7x24_valida_producto')
   drop proc sp_7x24_valida_producto
go
create proc sp_7x24_valida_producto
@s_ssn                int           = null,
@s_sesn               int           = null,
@s_ofi                smallint      = null,
@s_rol                smallint      = null,
@s_user               login         = null,
@s_date               datetime      = null,
@s_term               descripcion   = null,
@t_debug              char(1)       = 'N',
@t_file               varchar(10)   = null,
@t_from               varchar(32)   = null,
@s_srv                varchar(30)   = null,
@s_lsrv               varchar(30)   = null,
@t_trn                int           = null,
@s_format_date        int           = null,   
@s_ssn_branch         int           = null,
@o_amounttopay        money         = null out,
@o_reference          varchar(30)   = null out,
@o_status             varchar(255)  = null out, 
@o_habilitado         char(1)       = 'N' out

         
as declare
@w_return           int,
@w_error		    int,
@w_sp_name          varchar(64),
@w_habilitado       char(1)


-- Información inicial
select @w_sp_name = 'sp_7x24_valida_producto'
	      
-- Estado de producto Cartera (Habilitado/Deshabilitado)
select @w_habilitado = pm_estado
from   cobis..cl_pro_moneda with (nolock)
where  pm_producto = 7

if @w_habilitado <> 'V'
begin
   select @w_error = 70208
   goto ERROR
end
else
   select @o_habilitado = 'S'
   
return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',    
@t_file=null,
@t_from=@w_sp_name,   
@i_num = @w_error

return @w_error    

go
