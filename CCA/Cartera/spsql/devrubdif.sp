use cob_cartera
go

set ansi_nulls off
go

set quoted_identifier off
go

if exists (select 1 from sysobjects where name = 'sp_devengamiento_rubros_diferidos' and type = 'P')
    drop procedure sp_devengamiento_rubros_diferidos
go

create procedure sp_devengamiento_rubros_diferidos
/************************************************************************/
/*  Archivo:              devengamiento_rubros_diferidos.sp             */
/*  Stored procedure:     sp_devengamiento_rubros_diferidos             */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         Ricardo Rincón                                */
/*  Fecha de escritura:   04/Ago/2021                                   */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  Permite realizar el devengamiento de los rubros diferidos           */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  18/Ago/2021   Ricardo Rincón  Emision Inicial                       */
/*  25/Mar/2022   G. Fernandez    Corrección de número decimanles para  */
/*                               el calculo de monto_mn                 */
/*  31/Ago/2022   G. Fernandez    R192715 Corrección en generación de   */
/*                                codvalor                              */
/*  17/abr/2023   G. Fernandez    S807925 Ingreso de campo de           */
/*                                reestructuracion                      */
/************************************************************************/
(
	@t_show_version			bit 			= 0,
	@t_debug				char(1) 		= 'S',
	
	@s_culture				varchar(10) 	= 'NEUTRAL',
	
	@i_sarta				int 			= null,
	@i_batch				int 			= null,
	@i_secuencial			int 			= null,
	@i_corrida				int 			= null,
	@i_intento				int 			= null,
	
	@i_param1				datetime 		= null	-- fecha de proceso
) as

declare
	@w_sp_name				varchar(30)		= null,
	
	@w_error 				int 			= 1,
	@w_msg 					varchar(255)	= null,
	@w_return				int 			= 0,
	
	@w_fecha_proceso		datetime 		= null,
	@w_fimc					datetime 		= null, -- fecha de inicio de mes corriente
	@w_ffmc					datetime 		= null, -- fecha de fin de mes corriente
	@w_fmma					datetime 		= null, -- fecha de fin de mes anterior
	
	@w_crd_operacion 		int 			= null,
	@w_crd_concepto 		varchar(10) 	= null,
	@w_crd_dividendo 		int 			= null,
	@w_crd_fecha_ini 		datetime 		= null,
	@w_crd_fecha_ven 		datetime 		= null,
	@w_crd_cuota 			money			= null,
	@w_crd_acumulado 		money			= null,
	
	@w_fid					datetime 		= null, -- fecha de inicio de devengamiento
	@w_ffd					datetime 		= null, -- fecha final de devengamiento
	@w_fdd 					float 			= null, -- factor diario
	@w_vd 					money 			= null, -- valor a devengar
	
	@w_codvalor 			int 			= null,
	@w_op_moneda 			smallint 		= null,
	@w_moneda_nacional 		smallint 		= null,
	@w_cotizacion_hoy 		money 			= null,
	@w_decimales_nacional 	tinyint 		= null,
	@w_reestructuracion     char(1)
	
-- captura el nombre del store procedure
select @w_sp_name   = 'sp_devengamiento_rubros_diferidos'

-- versionamiento del Programa
if @t_show_version = 1
begin
    print	@w_sp_name + ': Stored Procedure = '+ @w_sp_name + 'Version = ' + '1.0.0'
    return 0
end

select @w_fecha_proceso = @i_param1

-- si la fecha de proceso viene nula, se consulta
if @w_fecha_proceso is null
begin
	select @w_fecha_proceso = fc_fecha_cierre
	from cobis..ba_fecha_cierre
	where fc_producto = 7  -- 7 para Cartera
end

-- Se crea tabla temporal #rubros_tmp
create table #rubros_tmp (
	r_operacion  	int, 			-- operación
	r_concepto 		catalogo, 		-- rubro
	r_dividendo 	smallint, 		-- dividendo
	r_fecha_ini 	smalldatetime, 	-- fecha inicio de la cuota
	r_fecha_ven 	smalldatetime, 	-- fecha vencimiento de la cuota
	r_cuota 		money, 			-- cuota
	r_acumulado 	money 			-- acomulado
)

-- se obtienen las fechas de inicio de mes corriente, fin de mes corriente y fin de mes del anterior mes de la fecha de proceso
select 	@w_fimc = dateadd(month, datediff(month, -1, @w_fecha_proceso) - 1, 0),
		@w_ffmc = dateadd(month, datediff(month, -1, @w_fecha_proceso) - 0, -1),
		@w_fmma = dateadd(month, datediff(month, -1, @w_fecha_proceso) - 1, -1)

-- se consultan las operaciones que han tenido una precancelación o un cambio de estado a CASTIGADO durante el mes en curso de la fecha proceso
-- se obtienen los registros de la tabla ca_control_rubros_diferidos y se inserta en tabla temporal #rubros_tmp
insert into #rubros_tmp (
	r_operacion,
	r_concepto,
	r_dividendo,
	r_fecha_ini,
	r_fecha_ven,
	r_cuota,
	r_acumulado
) select 
	crd_operacion,
	crd_concepto,
	crd_dividendo,
	crd_fecha_ini,
	crd_fecha_ven,
	crd_cuota,
	crd_acumulado
from ca_control_rubros_diferidos
where crd_cuota 	!= crd_acumulado
and crd_operacion 	in (
	select distinct
		tr_operacion
	from ca_transaccion
	left join ca_operacion on op_operacion = tr_operacion
	where tr_tran 		= 'PAG' -- pagado
	and tr_estado 		!= 'RV' -- diferente de reversado
	and tr_fecha_mov 	> @w_fimc
	and tr_fecha_mov 	<= @w_ffmc
	and op_fecha_fin 	> tr_fecha_ref
	and op_estado 		= 3 -- cancelado
	and op_operacion in (select distinct crd_operacion from cob_cartera..ca_control_rubros_diferidos)
	union
	select distinct
		tr_operacion
	from cob_cartera..ca_transaccion
	left join ca_operacion on op_operacion = tr_operacion
	where tr_tran 		= 'ETM' -- ETM
	and tr_estado 		!= 'RV' -- diferente de reversado
	and tr_fecha_mov 	> @w_fimc
	and tr_fecha_mov 	<= @w_ffmc
	and op_estado 		= 4 -- castigado
	and op_operacion in (select distinct crd_operacion from cob_cartera..ca_control_rubros_diferidos)
)
order by crd_operacion, crd_concepto, crd_dividendo, crd_fecha_ini

if @@error != 0 
	goto ERROR2

declare rubros cursor 
for select 
	r_operacion,
	r_concepto,
	r_dividendo,
	r_fecha_ini,
	r_fecha_ven,
	r_cuota,
	r_acumulado
from #rubros_tmp

open rubros

fetch next from rubros into
	@w_crd_operacion,
	@w_crd_concepto,
	@w_crd_dividendo,
	@w_crd_fecha_ini,
	@w_crd_fecha_ven,
	@w_crd_cuota,
	@w_crd_acumulado

while (@@fetch_status = 0)
begin
	begin tran

	-- el valor a devengar será lo restante
	select @w_vd = @w_crd_cuota - @w_crd_acumulado
	
	if @w_crd_cuota >= (@w_crd_acumulado + @w_vd)
	begin
		-- se actualiza el acomulado de la cuota
		update ca_control_rubros_diferidos 
		set crd_acumulado 		= (@w_crd_acumulado + @w_vd)
		where crd_operacion 	= @w_crd_operacion
		and crd_concepto 		= @w_crd_concepto
		and crd_dividendo 		= @w_crd_dividendo
	
		if @@error != 0 
			goto ERROR1
	
		/* 
		 * INICIO - generación de transacción
		*/	  
		select @w_codvalor = 1000 * co_codigo + 10 --31/Ago/2022
		from   ca_concepto
		where  co_concepto = @w_crd_concepto
		
		select @w_op_moneda         = op_moneda,
		       @w_reestructuracion  = isnull(op_reestructuracion, 'N')
		from ca_operacion with (nolock)
		where op_operacion = @w_crd_operacion
		
		select @w_moneda_nacional = pa_tinyint
		from   cobis..cl_parametro with (nolock)
		where  pa_producto = 'ADM'
		and    pa_nemonico = 'MLO'
		
		if @w_op_moneda = @w_moneda_nacional 
		begin
			select @w_cotizacion_hoy = 1.0
		end 
		else 
		begin
			exec @w_error   = sp_buscar_cotizacion
				@i_moneda     = @w_op_moneda,
				@i_fecha      = @w_fecha_proceso,
				@o_cotizacion = @w_cotizacion_hoy output
			
			if @w_error != 0
				goto ERROR1
		end	
		-- control de numeros de decimales   
		exec @w_error   = sp_decimales         --GFP 25/Mar/2022
			@i_moneda       = @w_op_moneda,
			@o_decimales    = @w_decimales_nacional out,
			@o_dec_nacional = @w_decimales_nacional out
		
		if @w_error != 0
			goto ERROR1
		
		insert into ca_transaccion_prv with (rowlock) (
		tp_fecha_mov, 												tp_operacion, 				tp_fecha_ref,
		tp_secuencial_ref, 											tp_estado, 					tp_dividendo,
		tp_concepto, 												tp_codvalor, 				tp_monto,
		tp_secuencia, 												tp_comprobante, 			tp_ofi_oper,
		tp_monto_mn, 												tp_moneda, 					tp_cotizacion,
		tp_tcotizacion,                                             tp_reestructuracion)
		values (
		@w_fecha_proceso, 											(@w_crd_operacion * -1), 	@w_fecha_proceso,
		0, 															'ING', 						@w_crd_dividendo,
		@w_crd_concepto, 											@w_codvalor, 				@w_vd,
		1, 															0, 							(select top 1 op_oficina from ca_operacion where op_operacion = @w_crd_operacion),
		round(@w_vd * @w_cotizacion_hoy, @w_decimales_nacional), 	@w_op_moneda, 				@w_cotizacion_hoy,
		'N',                                                        @w_reestructuracion)
		
		if @@error != 0 
		begin
			select @w_error = 708165
			goto ERROR1
		end
		/* 
		 * FIN - generación de transacción
		*/
	end
	
	commit tran
	
	fetch next from rubros into
		@w_crd_operacion,
		@w_crd_concepto,
		@w_crd_dividendo,
		@w_crd_fecha_ini,
		@w_crd_fecha_ven,
		@w_crd_cuota,
		@w_crd_acumulado
end

close rubros
deallocate rubros

if exists(select 1 from #rubros_tmp)
begin
	truncate table #rubros_tmp
end

-- se obtienen los registros de la tabla ca_control_rubros_diferidos y se inserta en tabla temporal #rubros_tmp
insert into #rubros_tmp (
	r_operacion,
	r_concepto,
	r_dividendo,
	r_fecha_ini,
	r_fecha_ven,
	r_cuota,
	r_acumulado
) select 
	crd_operacion,
	crd_concepto,
	crd_dividendo,
	crd_fecha_ini,
	crd_fecha_ven,
	crd_cuota,
	crd_acumulado
from ca_control_rubros_diferidos
where crd_cuota != crd_acumulado
and (crd_fecha_ven <= @w_ffmc or (crd_fecha_ini < @w_ffmc and crd_fecha_ven > @w_ffmc))
order by crd_operacion, crd_concepto, crd_dividendo, crd_fecha_ini

if @@error != 0 
	goto ERROR2

-- se crea el cursor rubros
declare rubros cursor 
for select 
	r_operacion,
	r_concepto,
	r_dividendo,
	r_fecha_ini,
	r_fecha_ven,
	r_cuota,
	r_acumulado
from #rubros_tmp

open rubros

fetch next from rubros into
	@w_crd_operacion,
	@w_crd_concepto,
	@w_crd_dividendo,
	@w_crd_fecha_ini,
	@w_crd_fecha_ven,
	@w_crd_cuota,
	@w_crd_acumulado

while (@@fetch_status = 0)
begin
	begin tran
	
	-- se obtiene la fecha de inicio de devengamiento
	if @w_crd_fecha_ini < @w_fmma
		select @w_fid = @w_fmma
	else if @w_crd_fecha_ini >= @w_fmma
		select @w_fid = @w_crd_fecha_ini
	
	-- se obtiene la fecha final de devengamiento
	if @w_crd_fecha_ven < @w_ffmc
		select @w_ffd = @w_crd_fecha_ven
	else if @w_crd_fecha_ven >= @w_ffmc
		select @w_ffd = @w_ffmc
	
	-- cálculo del factor diario de devengamiento
	select @w_fdd = round((@w_crd_cuota * 1.0)/datediff(day, @w_crd_fecha_ini, @w_crd_fecha_ven), 2)
	
	-- cálculo del valor a devengar para cada cuota
	select @w_vd = @w_fdd * datediff(day, @w_fid, @w_ffd)
	
	-- si la fecha de vencimiento es igual a la fecha final de devengamiento, quiere decir que la cuota quedó vencida, por lo tanto 
	-- el valor a devengar será lo restante debido a que con la aproximación del factor diario de devengamiento no da el valor exacto del monto
	if @w_crd_fecha_ven = @w_ffd
		select @w_vd = @w_crd_cuota - @w_crd_acumulado
	
	if @w_crd_cuota >= (@w_crd_acumulado + @w_vd)
	begin
		-- se actualiza el acomulado de la cuota
		update ca_control_rubros_diferidos 
		set crd_acumulado 		= (@w_crd_acumulado + @w_vd)
		where crd_operacion 	= @w_crd_operacion
		and crd_concepto 		= @w_crd_concepto
		and crd_dividendo 		= @w_crd_dividendo
	
		if @@error != 0 
			goto ERROR1
	
		/* 
		 * INICIO - generación de transacción
		*/	  
		select @w_codvalor = 1000 * co_codigo + 10
		from   ca_concepto
		where  co_concepto = @w_crd_concepto
		
		select @w_op_moneda = op_moneda 
		from ca_operacion with (nolock)
		where op_operacion = @w_crd_operacion
		
		select @w_moneda_nacional = pa_tinyint
		from   cobis..cl_parametro with (nolock)
		where  pa_producto = 'ADM'
		and    pa_nemonico = 'MLO'
		
		if @w_op_moneda = @w_moneda_nacional 
		begin
			select @w_cotizacion_hoy = 1.0
		end 
		else 
		begin
			exec @w_error   = sp_buscar_cotizacion
				@i_moneda     = @w_op_moneda,
				@i_fecha      = @w_fecha_proceso,
				@o_cotizacion = @w_cotizacion_hoy output
			
			if @w_error != 0
				goto ERROR1
		end	
		-- control de numeros de decimales
		exec @w_error   = sp_decimales                   --GFP 25/Mar/2022
			@i_moneda       = @w_op_moneda,
			@o_decimales    = @w_decimales_nacional out,
			--@o_mon_nacional = @w_aux1    out,
			@o_dec_nacional = @w_decimales_nacional out
		
		if @w_error != 0
			goto ERROR1
		
		insert into ca_transaccion_prv with (rowlock) (
		tp_fecha_mov, 												tp_operacion, 				tp_fecha_ref,
		tp_secuencial_ref, 											tp_estado, 					tp_dividendo,
		tp_concepto, 												tp_codvalor, 				tp_monto,
		tp_secuencia, 												tp_comprobante, 			tp_ofi_oper,
		tp_monto_mn, 												tp_moneda, 					tp_cotizacion,
		tp_tcotizacion,                                             tp_reestructuracion)
		values (
		@w_fecha_proceso, 											(@w_crd_operacion * -1), 	@w_fecha_proceso,
		0, 															'ING', 						@w_crd_dividendo,
		@w_crd_concepto, 											@w_codvalor, 				@w_vd,
		1, 															0, 							(select top 1 op_oficina from ca_operacion where op_operacion = @w_crd_operacion),
		round(@w_vd * @w_cotizacion_hoy, @w_decimales_nacional), 	@w_op_moneda, 				@w_cotizacion_hoy,
		'N',                                                        @w_reestructuracion)
		
		if @@error != 0 
		begin
			select @w_error = 708165
			goto ERROR1
		end
		/* 
		 * FIN - generación de transacción
		*/
	end
	
	commit tran
	
	fetch next from rubros into
		@w_crd_operacion,
		@w_crd_concepto,
		@w_crd_dividendo,
		@w_crd_fecha_ini,
		@w_crd_fecha_ven,
		@w_crd_cuota,
		@w_crd_acumulado
end

close rubros
deallocate rubros

return 0

ERROR1:
print 'se produjo un error cuando se recorria el cursor rubros'

close rubros
deallocate rubros

rollback tran

ERROR2:
if @w_error = 0
	select @w_error = 1

exec cobis..sp_cerror
	@t_debug = 'N',
	@t_file  = '',
	@t_from  = @w_sp_name,
	@i_num   = @w_error

return @w_error
