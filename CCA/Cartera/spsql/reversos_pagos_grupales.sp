/************************************************************************/ 
/*    ARCHIVO:         reversos_pagos_grupales.sp                       */ 
/*    NOMBRE LOGICO:   sp_reversos_pagos_grupales                       */ 
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:    Johan Hernandez                                   */
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
/*  Permite realizar la consulta de los pagos grupales que han sido     */ 
/*  aplicados, por lo que realiza la consulta de la tabla               */
/*  ca_corresponsal_trn para luego actualizar el regitro.               */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 18/05/2021    J. Hernandez	 Versión Inicial                        */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reversos_pagos_grupales')
   drop proc sp_reversos_pagos_grupales
go
create proc sp_reversos_pagos_grupales
@s_user               login      = null,
@s_date               datetime   = null,
@s_sesn               int        = null,
@s_term               descripcion = null,
@t_trn                INT         = NULL,                
@i_operacion          char(1)     = null,
@i_banco              varchar(30) = null,
@i_estado			  char(1)     = 'P',
@i_secuencial         int         = 0
         
as declare
@w_return          int,
@w_op_operacion    int,
@w_error		   int,
@w_msg			   varchar(64),
@w_sp_name         varchar(64)


select @w_sp_name = 'sp_reversos_pagos_grupales'

if @i_operacion = 'Q'
begin
	select @w_op_operacion = op_operacion from ca_operacion
	where op_banco = @i_banco
    set rowcount 20
	select co_secuencial,     co_corresponsal,        co_tipo,
		   co_codigo_interno, co_fecha_proceso,       co_fecha_valor,
		   co_referencia,     co_moneda,              co_monto,
		   co_trn_id_corresp, co_accion,              co_estado,
		   co_login
	from ca_corresponsal_trn 
	where co_codigo_interno = @w_op_operacion
	and   co_referencia     = @i_banco
	and   co_estado         = @i_estado
	and   co_secuencial     > @i_secuencial
	and   co_accion        <> 'R'
	order by co_secuencial
	   
	if @@rowcount = 0
	begin
		select @w_error = 710023
		goto ERROR
	end
end

if @i_operacion = 'U'
begin
	UPDATE ca_corresponsal_trn
	SET co_accion          = 'R', 
		co_fecha_proceso = @s_date,
		co_estado          = 'I'
 	WHERE co_secuencial  = @i_secuencial
	and   co_referencia  = @i_banco
	and   co_estado      = @i_estado
	
	if @@rowcount = 0
	begin
		select @w_error = 708152
		goto ERROR
	end
end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug='N',    
@t_file=null,
@t_from=@w_sp_name,   
@i_num = @w_error

return @w_error    

go
