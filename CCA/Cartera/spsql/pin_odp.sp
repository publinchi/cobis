use cob_cartera
go

set ansi_nulls off
go

set quoted_identifier off
go

if exists (select 1 from sysobjects where name = 'sp_pin_odp' and type = 'P')
    drop procedure sp_pin_odp
go

create procedure sp_pin_odp
/************************************************************************/
/*  Archivo:              pin_odp.sp                                    */
/*  Stored procedure:     sp_pin_odp                                    */
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
/*  Mantenimiento de PIN - ODP                                          */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  31/Ago/2021   Ricardo Rincón  Emision Inicial                       */
/*  30/Sep/2021   Kevin Rodríguez Envío param que identifica acción de  */
/*                                Ingreso/Bloqueo/Desbloqueo/Anulación  */
/*                                para la transacción de servicio       */
/*  05/Jul/2021   Kevin Rodríguez Ajuste filtro búsqueda i_operacion S  */
/*  15/Sep/2022   Kevin Rodríguez R193060 Instruc. with nolock a tabla  */
/*                                ca_operacion                          */
/************************************************************************/
(
	@s_user 			varchar(14) 	= null,
	@s_term 			varchar(30) 	= null,
	@s_date 			datetime 		= null,
	@s_sesn 			int 			= null,
	@s_ofi 				int 			= null,
	@t_trn 				int 			= null, 
	@t_debug 			char(1) 		= 'N',
	@t_file 			varchar(14) 	= null,
	@t_show_version 	bit 			= 0, 
	@i_operacion 		char(1) 		= null,
	@i_modo 			char(1) 		= null,
	@i_banco 			varchar(14) 	= null,
	@i_desembolso 		tinyint 		= null,
	@i_secuencial_des 	int 			= null,
	@i_secuencial_pin 	int 			= null
) as

declare
	@w_sp_name			varchar(30)		= null,
	@w_error 			int 			= 1,
	@w_fecha_ven 		datetime 		= null, -- fecha de vencimiento con los dias habiles especificados
	@w_dias_habiles 	int 			= null,
	@w_bandera_fv 		bit 			= 0,
	@w_longitud_pin 	int 			= null, -- valores enteros entre 1 y 9 (1-9)
	@w_pin 				int 			= null, -- el PIN debe tener una longitud maxima de 9 dígitos

	@w_operacion 		varchar(255) 	= null,
	@w_desembolso 		varchar(255) 	= null,
	@w_secuencial_des 	varchar(255) 	= null,
	@w_secuencial_pin 	varchar(255) 	= null,
	
	@w_valida_pin 		bit 			= null,
	
	@w_est_vigente          tinyint,
    @w_est_novigente        tinyint,
	 @w_est_credito         tinyint

-- captura el nombre del store procedure
select @w_sp_name   = 'sp_pin_odp'

-- versionamiento del Programa
if @t_show_version = 1
begin
    print	@w_sp_name + ': Stored Procedure = '+ @w_sp_name + ' Version = ' + '1.0.0'
    return 0
end

-- se valida que la transaccion corresponda con la operacion
if ((@t_trn != 77548 and @i_operacion = 'S') or -- consultar desembolsos
	(@t_trn != 77549 and @i_operacion = 'I') or -- generar nuevo pin
	(@t_trn != 77550 and @i_operacion = 'Q') or -- botón de editar pin
	(@t_trn != 77551 and @t_trn != 77552 and @t_trn != 77553 and @i_operacion = 'U')) -- bloquear, desbloquear, y anular
begin
	-- tipo de transaccion no corresponde
	select @w_error = 801077
	goto ERROR
end

-- ESTADOS DE CARTERA
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente  out,
@o_est_credito    = @w_est_credito  out

if @w_error <> 0 begin
   goto ERROR
end

select top 1 @w_operacion = cast(op_operacion as varchar) from ca_operacion where op_banco = @i_banco

select  @w_desembolso = cast(@i_desembolso as varchar),
		@w_secuencial_des = cast(@i_secuencial_des as varchar),
		@w_secuencial_pin = cast(@i_secuencial_pin as varchar)

if @i_operacion = 'S' -- se consultan los desembolsos que tengan categoria 'ORPA' y estado 'NA'
begin
	select 
		'Numero de desembolso'			= dm_desembolso,
		'Secuencial de desembolso'		= dm_secuencial,
		'Forma de desembolso'			= dm_producto,
		'Moneda de desembolso'			= dm_moneda,
		'Monto MOP'						= dm_monto_mop,
		'Monto MN'						= dm_monto_mn,
		'Banco' 						= cast(ba_codigo as varchar) + ' - ' + ba_nombre,
		'Numero de cuenta'				= dm_cuenta
	from cob_cartera..ca_desembolso 
	left join cob_cartera..ca_operacion with (nolock) on op_operacion = dm_operacion   -- KDR 15/09/2022 No bloqueo de tabla
	left join cob_cartera..ca_producto 	on cp_producto 	= dm_producto
	left join cob_bancos..ba_banco 		on ba_codigo 	= dm_cod_banco
	where dm_pagado = 'N'
	and op_estado in (@w_est_novigente, @w_est_vigente, @w_est_credito) 
	and cp_categoria = 'ORPA'
	and op_banco = @i_banco
	
	if @@rowcount = 0
	begin
		select @w_error = 725077 -- 'PRESTAMO NO TIENE ORDENES DE PAGO PENDIENTES'
		goto ERROR
	end
end

if @i_operacion = 'I' -- se genera un nuevo pin
begin
	if exists (select 1
		from ca_pin_odp
		left join ca_operacion 	on op_operacion = po_operacion
		where op_banco 					= @i_banco
		and po_desembolso 				= @i_desembolso
		and po_secuencial_desembolso 	= @i_secuencial_des
		and po_fecha_vencimiento 	   >= @s_date
		and po_estado 				   != 'A')
	begin
		select @w_error = 725078 -- 'FORMA DE DESEMBOLSO YA TIENE UN PIN ASOCIADO'
		goto ERROR
	end
			
	select top 1 @w_dias_habiles = pa_int from cobis..cl_parametro where pa_nemonico = 'DHVP' and pa_producto = 'CCA'
	
	if @w_dias_habiles is null
		select @w_dias_habiles = 3
	
	select 	@w_fecha_ven 	= dateadd(day, @w_dias_habiles, @s_date),
			@w_bandera_fv 	= 0
	
	-- bucle en la que se consultan los dias feriados para saber si lo es y si es así sumarle un día
	while @w_bandera_fv = 0
	begin
		if (exists(select 1 from cobis..cl_dias_feriados 
					 where df_ciudad = (select pa_int from cobis..cl_parametro where pa_nemonico = 'CIUN' and pa_producto = 'ADM')
					 and   df_fecha  = @w_fecha_ven))
		begin
			select @w_fecha_ven = dateadd(day, 1, @w_fecha_ven)
		end
		else select @w_bandera_fv = 1
	end
	
	select top 1 @w_longitud_pin = pa_int from cobis..cl_parametro where pa_nemonico = 'LPIND' and pa_producto = 'CCA'
	
	if @w_longitud_pin is null
		select @w_longitud_pin = 5
	
	-- se genera PIN nuevo 
	select @w_pin = floor(rand()*((power(10, @w_longitud_pin)-1)-(power(10, @w_longitud_pin-1)))+(power(10, @w_longitud_pin-1)))
	
	select @w_secuencial_pin = cast(isnull(max(po_secuencial_pin) + 1, 1) as varchar) from ca_pin_odp
	
	insert into ca_pin_odp (
		po_operacion,
		po_desembolso,
		po_secuencial_desembolso,
		po_secuencial_pin,
		po_pin,
		po_fecha_generacion,
		po_fecha_vencimiento,
		po_fecha_bloqueo,
		po_fecha_anulacion,
		po_estado  
	) values (
		cast(@w_operacion as int),
		@i_desembolso,
		@i_secuencial_des,
		cast(@w_secuencial_pin as int),
		@w_pin,
		@s_date,
		@w_fecha_ven,
		null,
		null,
		'N'
	)
	
	if @@error != 0 
	begin
		select @w_error = 725079 -- 'ERROR AL INSERTAR PIN GENERADO EN LA TABLA ca_pin_odp'
		goto ERROR
	end
	
	-- transaccion de servicio para la insercion del registro
	exec @w_error  = sp_tran_servicio
		@s_user      = @s_user,
		@s_date      = @s_date,
		@s_ofi       = @s_ofi,
		@s_term      = @s_term,
		@i_tabla     = 'ca_pin_odp',
		@i_clave1    = @w_operacion,
		@i_clave2    = @w_desembolso,
		@i_clave3    = @w_secuencial_des,
		@i_clave4    = @w_secuencial_pin,
		@i_clave5    = 'I'
	
	if @w_error != 0 
		goto ERROR
end

if @i_operacion = 'Q' -- cuando oprime el boton de editar o se requiere validar si existe PIN vigente
begin
	if @i_modo = 'V' -- modo 'V' para validar si existe algún PIN vigente para el desembolso
	begin
		select top 1
			@w_valida_pin = 1
		from ca_pin_odp
		left join ca_operacion 	on op_operacion = po_operacion
		where op_banco 					= @i_banco
		and po_desembolso 				= @i_desembolso
		and po_secuencial_desembolso 	= @i_secuencial_des
		and po_fecha_vencimiento 	   >= @s_date
		and po_estado 				   != 'A'
		
		if @w_valida_pin is null
			select @w_valida_pin = 0
		
		select 'PIN vigente' = @w_valida_pin
	end
	
	if @i_modo = 'C' -- modo 'C' para consultar el PIN vigente actual
	begin
		select top 1
			'Secuencial de PIN' 	= po_secuencial_pin,
			'Numero de PIN' 		= po_pin,
			'Fecha de vencimiento' 	= po_fecha_vencimiento,
			'Fecha de bloqueo' 		= po_fecha_bloqueo,
			'Estado' 				= po_estado
		from ca_pin_odp
		left join ca_operacion 	on op_operacion = po_operacion
		where op_banco 					= @i_banco
		and po_desembolso 				= @i_desembolso
		and po_secuencial_desembolso 	= @i_secuencial_des
		and po_fecha_vencimiento 	   >= @s_date
		and po_estado 				   != 'A'
	end
end

if @i_operacion = 'U' -- actualizar estado del PIN
begin
	if @i_modo = 'B' -- modo 'B' para bloquear el PIN seleccionado
	begin
		-- transaccion de servicio para la visualizacion antes del update del registro
		exec @w_error  = sp_tran_servicio
			@s_user      = @s_user,
			@s_date      = @s_date,
			@s_ofi       = @s_ofi,
			@s_term      = @s_term,
			@i_tabla     = 'ca_pin_odp',
			@i_clave1    = @w_operacion,
			@i_clave2    = @w_desembolso,
			@i_clave3    = @w_secuencial_des,
			@i_clave4    = @w_secuencial_pin,
			@i_clave5    = 'B'
		
		if @w_error != 0 
			goto ERROR
		
		update ca_pin_odp 
		set po_estado 			= 'B',
			po_fecha_bloqueo 	= @s_date
		where po_operacion 				= cast(@w_operacion as int)
		and po_desembolso 				= @i_desembolso
		and po_secuencial_desembolso 	= @i_secuencial_des
		and po_secuencial_pin 			= @i_secuencial_pin
		
		if @@error != 0 
		begin
			select @w_error = 725080 -- 'ERROR AL ACTUALIZAR ESTADO DEL PIN'
			goto ERROR
		end
		
		-- transaccion de servicio para la visualizacion despues del update del registro
		exec @w_error  = sp_tran_servicio
			@s_user      = @s_user,
			@s_date      = @s_date,
			@s_ofi       = @s_ofi,
			@s_term      = @s_term,
			@i_tabla     = 'ca_pin_odp',
			@i_clave1    = @w_operacion,
			@i_clave2    = @w_desembolso,
			@i_clave3    = @w_secuencial_des,
			@i_clave4    = @w_secuencial_pin,
			@i_clave5    = 'B'
		
		if @w_error != 0 
			goto ERROR
	end
	
	if @i_modo = 'D' -- modo 'D' para desbloquear el PIN seleccionado
	begin
		-- transaccion de servicio para la visualizacion antes del update del registro
		exec @w_error  = sp_tran_servicio
			@s_user      = @s_user,
			@s_date      = @s_date,
			@s_ofi       = @s_ofi,
			@s_term      = @s_term,
			@i_tabla     = 'ca_pin_odp',
			@i_clave1    = @w_operacion,
			@i_clave2    = @w_desembolso,
			@i_clave3    = @w_secuencial_des,
			@i_clave4    = @w_secuencial_pin,
			@i_clave5    = 'D'
		
		if @w_error != 0 
			goto ERROR
		
		update ca_pin_odp 
		set po_estado 			= 'N',
			po_fecha_bloqueo 	= null
		where po_operacion 				= cast(@w_operacion as int)
		and po_desembolso 				= @i_desembolso
		and po_secuencial_desembolso 	= @i_secuencial_des
		and po_secuencial_pin 			= @i_secuencial_pin
		
		if @@error != 0 
		begin
			select @w_error = 725080 -- 'ERROR AL ACTUALIZAR ESTADO DEL PIN'
			goto ERROR
		end
		
		-- transaccion de servicio para la visualizacion despues del update del registro
		exec @w_error  = sp_tran_servicio
			@s_user      = @s_user,
			@s_date      = @s_date,
			@s_ofi       = @s_ofi,
			@s_term      = @s_term,
			@i_tabla     = 'ca_pin_odp',
			@i_clave1    = @w_operacion,
			@i_clave2    = @w_desembolso,
			@i_clave3    = @w_secuencial_des,
			@i_clave4    = @w_secuencial_pin,
			@i_clave5    = 'D'
		
		if @w_error != 0 
			goto ERROR
	end
	
	if @i_modo = 'A' -- modo 'A' para anular el PIN seleccionado
	begin
		-- transaccion de servicio para la visualizacion antes del update del registro
		exec @w_error  = sp_tran_servicio
			@s_user      = @s_user,
			@s_date      = @s_date,
			@s_ofi       = @s_ofi,
			@s_term      = @s_term,
			@i_tabla     = 'ca_pin_odp',
			@i_clave1    = @w_operacion,
			@i_clave2    = @w_desembolso,
			@i_clave3    = @w_secuencial_des,
			@i_clave4    = @w_secuencial_pin,
			@i_clave5    = 'A'
		
		if @w_error != 0 
			goto ERROR
		
		update ca_pin_odp 
		set po_estado 			= 'A',
			po_fecha_anulacion 	= @s_date
		where po_operacion 				= cast(@w_operacion as int)
		and po_desembolso 				= @i_desembolso
		and po_secuencial_desembolso 	= @i_secuencial_des
		and po_secuencial_pin 			= @i_secuencial_pin
		
		if @@error != 0 
		begin
			select @w_error = 725080 -- 'ERROR AL ACTUALIZAR ESTADO DEL PIN'
			goto ERROR
		end
		
		-- transaccion de servicio para la visualizacion despues del update del registro
		exec @w_error  = sp_tran_servicio
			@s_user      = @s_user,
			@s_date      = @s_date,
			@s_ofi       = @s_ofi,
			@s_term      = @s_term,
			@i_tabla     = 'ca_pin_odp',
			@i_clave1    = @w_operacion,
			@i_clave2    = @w_desembolso,
			@i_clave3    = @w_secuencial_des,
			@i_clave4    = @w_secuencial_pin,
			@i_clave5    = 'A'
		
		if @w_error != 0 
			goto ERROR
	end
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
