use cob_cartera
go

set ansi_nulls off
go

set quoted_identifier off
go

if exists (select 1 from sysobjects where name = 'sp_estado_gestion_cobranza' and type = 'P')
    drop procedure sp_estado_gestion_cobranza
go

create procedure sp_estado_gestion_cobranza
/************************************************************************/
/*  Archivo:              estgestcob.sp                                 */
/*  Stored procedure:     sp_estado_gestion_cobranza                    */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         Ricardo Rincón                                */
/*  Fecha de escritura:   31/Ago/2021                                   */
/************************************************************************/
/*             IMPORTANTE                                               */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCorp.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCorp.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCorp para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  Mantenimiento de estados para la gestión de la cobranza             */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  14/Sep/2021   Ricardo Rincón  Emision Inicial                       */
/*  30/Sep/2021   Kevin Rodríguez Envío de params que identifica opera- */
/*                                ción y un antes/despues del transerv  */
/*  11/Ene/2022  Guisela Fernandez Se elimina el ingreso de nuevos      */
/*                         registros en ca_operacion_datos_adicionales, */
/*                                 solo se permite la actualizacion     */
/************************************************************************/
(
	@s_user 			varchar(14) 	= null,
	@s_term 			varchar(30) 	= null,
	@s_date 			datetime,
	@s_sesn 			int 			= null,
	@s_ofi 				int 			= null,
	
	@t_trn 				int 			= null, 
	@t_debug 			char(1) 		= 'N',
	@t_file 			varchar(14) 	= null,
	@t_show_version 	bit 			= 0,
	
	@i_operacion 		char(1) 		= null,
	@i_banco 			varchar(14) 	= null,
	@i_estado_ges_co 	catalogo 		= null,
	@i_aceptar_pagos 	char(1) 		= null,
	@i_opcion	 		smallint 		= 1
) as

declare
	@w_sp_name			varchar(30)		= null,
	@w_error 			int 			= 1,
	
	@w_operacion 		int 			= null

-- captura el nombre del store procedure
select @w_sp_name   = 'sp_estado_gestion_cobranza'

-- versionamiento del Programa
if @t_show_version = 1
begin
    print	@w_sp_name + ': Stored Procedure = '+ @w_sp_name + ' Version = ' + '1.0.0'
    return 0
end

-- se valida que la transaccion corresponda con la operacion
if 	@t_trn != null and 
	((@t_trn != 77556 and (@i_operacion = 'Q' or @i_operacion = 'V')) or -- consultar estados de gestion de cobranza
	(@t_trn != 77557 and @i_operacion = 'I') or -- crear nuevo estado de gestion de cobranza
	(@t_trn != 77558 and @i_operacion = 'U') or -- editar estado de gestion de cobranza
	(@t_trn != 77559 and @i_operacion = 'E'))   -- eliminar estado de gestion de cobranza
begin
	-- tipo de transaccion no corresponde
	select @w_error = 801077
	goto ERROR
end

select @w_operacion = op_operacion from ca_operacion where op_banco = @i_banco

if @i_operacion = 'Q' or @i_operacion = 'V' -- se consulta el estado de gestion de cobranza
begin
	if @i_opcion = 1
	begin
		select
			'Estado de Cobranza' 		= oda_estado_gestion_cobranza,
			'Descripcion del Estado' 	= (select top 1 c.valor 
										  from cobis..cl_catalogo as c 
										  left join cobis..cl_tabla as t on t.codigo = c.tabla 
										  where t.tabla = 'ca_estado_gestion_cobranza' 
										  --and c.estado  = 'V' 
										  and c.codigo  = oda_estado_gestion_cobranza),
			'Permite pagos' 			= oda_aceptar_pagos
		from ca_operacion_datos_adicionales 
		where oda_operacion = @w_operacion
		and oda_estado_gestion_cobranza is not null 
		and oda_aceptar_pagos 			is not null
		
		if @i_operacion = 'Q' and @@rowcount = 0
		begin
			select @w_error = 725087 -- 'OPERACION NO TIENE UN ESTADO DE GESTION DE COBRANZA'
			goto ERROR
		end
	end
	
	if @i_opcion = 2
	begin
		if not exists (select 1
					from cobis..cl_catalogo 
					where tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_pago_gestion_cobranza')
					and codigo = @i_estado_ges_co)
		begin
			select @w_error = 725088 -- 'NO EXISTE UN VALOR POR DEFECTO PARA EL ESTADO DE GESTIÓN DE COBRANZA'
			goto ERROR
		end
		else
		begin
			select
				'Estado de Cobranza' 		= ca.codigo,
				'Descripcion del Estado' 	= (select top 1 c.valor 
												from cobis..cl_catalogo as c 
												left join cobis..cl_tabla as t on t.codigo = c.tabla 
												where t.tabla = 'ca_estado_gestion_cobranza' 
												and c.estado  = 'V' 
												and c.codigo  = ca.codigo),
				'Permite pagos' 			= ca.valor
			from cobis..cl_catalogo as ca
			left join cobis..cl_tabla as ta on ta.codigo = ca.tabla
			where ta.tabla = 'ca_pago_gestion_cobranza'
			and ca.codigo = @i_estado_ges_co
		end
	end
end

if @i_operacion = 'I' -- se crea un nuevo estado de gestion de cobranza
begin
	if exists (select 1 
				from ca_operacion_datos_adicionales 
				where oda_operacion = @w_operacion 
				and oda_estado_gestion_cobranza is not null 
				and oda_aceptar_pagos 			is not null)
	begin
		select @w_error = 725083 -- 'OPERACION YA TIENE UN ESTADO DE GESTION DE COBRANZA'
		goto ERROR
	end
	
	begin tran
	if exists (select 1 
				from ca_operacion_datos_adicionales 
				where oda_operacion = @w_operacion 
				and oda_estado_gestion_cobranza is null 
				and oda_aceptar_pagos 			is null)
	begin
		update ca_operacion_datos_adicionales
		set oda_estado_gestion_cobranza = @i_estado_ges_co,
		oda_aceptar_pagos 				= @i_aceptar_pagos
		where oda_operacion = @w_operacion
		
		if @@error != 0 
		begin
			select @w_error = 725084 -- 'ERROR AL INSERTAR EL ESTADO DE GESTION DE COBRANZA'
			goto ERROR
		end
	end
	
	-- transaccion de servicio para la insercion del registro
	exec @w_error  = sp_tran_servicio
		@s_user      = @s_user,
		@s_date      = @s_date,
		@s_ofi       = @s_ofi,
		@s_term      = @s_term,
		@i_tabla     = 'ca_operacion_datos_adicionales',
		@i_clave1    = @w_operacion,
		@i_clave2    = 'I',
		@i_clave3    = 'D'
	
	if @w_error != 0 
		goto ERROR
	
	commit tran
end

if @i_operacion = 'U' -- se edita estado de gestion de cobranza
begin
	begin tran
	
	-- transaccion de servicio para la visualizacion antes del update del registro
	exec @w_error  = sp_tran_servicio
		@s_user      = @s_user,
		@s_date      = @s_date,
		@s_ofi       = @s_ofi,
		@s_term      = @s_term,
		@i_tabla     = 'ca_operacion_datos_adicionales',
		@i_clave1    = @w_operacion,
		@i_clave2    = 'U',
		@i_clave3    = 'A'
	
	if @w_error != 0 
		goto ERROR
		
	update ca_operacion_datos_adicionales
	set oda_estado_gestion_cobranza = @i_estado_ges_co,
	oda_aceptar_pagos 				= @i_aceptar_pagos
	where oda_operacion = @w_operacion
	
	if @@error != 0 
	begin
		select @w_error = 725085 -- 'ERROR AL ACTUALIZAR EL ESTADO DE GESTION DE COBRANZA'
		goto ERROR
	end
	
	-- transaccion de servicio para la visualizacion despues del update del registro
	exec @w_error  = sp_tran_servicio
		@s_user      = @s_user,
		@s_date      = @s_date,
		@s_ofi       = @s_ofi,
		@s_term      = @s_term,
		@i_tabla     = 'ca_operacion_datos_adicionales',
		@i_clave1    = @w_operacion,
		@i_clave2    = 'U',
		@i_clave3    = 'D'
	
	if @w_error != 0 
		goto ERROR
	
	commit tran
end

if @i_operacion = 'E' -- se elimina estado de gestion de cobranza
begin
	begin tran
	
	-- transaccion de servicio para la visualizacion antes del update del registro
	exec @w_error  = sp_tran_servicio
		@s_user      = @s_user,
		@s_date      = @s_date,
		@s_ofi       = @s_ofi,
		@s_term      = @s_term,
		@i_tabla     = 'ca_operacion_datos_adicionales',
		@i_clave1    = @w_operacion,
		@i_clave2    = 'D',
		@i_clave3    = 'A'
	
	if @w_error != 0 
		goto ERROR

	update ca_operacion_datos_adicionales
	set oda_estado_gestion_cobranza = null,
	oda_aceptar_pagos 				= null
	where oda_operacion = @w_operacion
	
	if @@error != 0 
	begin
		select @w_error = 725086 -- 'ERROR AL ELIMINAR EL ESTADO DE GESTION DE COBRANZA'
		goto ERROR
	end
	
	-- transaccion de servicio para la visualizacion despues del update del registro
	exec @w_error  = sp_tran_servicio
		@s_user      = @s_user,
		@s_date      = @s_date,
		@s_ofi       = @s_ofi,
		@s_term      = @s_term,
		@i_tabla     = 'ca_operacion_datos_adicionales',
		@i_clave1    = @w_operacion,
		@i_clave2    = 'D',
		@i_clave3    = 'D'
	
	if @w_error != 0 
		goto ERROR
	
	commit tran
end

return 0

ERROR:
exec cobis..sp_cerror 
	@t_debug = @t_debug, 
	@t_file = @t_file, 
	@t_from = @w_sp_name, 
	@i_num = @w_error
	
return @w_error

go
