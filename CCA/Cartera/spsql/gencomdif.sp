use cob_cartera
go

set ansi_nulls off
go

set quoted_identifier off
go

if exists (select 1 from sysobjects where name = 'sp_genera_comisiones_diferidas' and type = 'P')
    drop procedure sp_genera_comisiones_diferidas
go

create procedure sp_genera_comisiones_diferidas
/************************************************************************/
/*  Archivo:              genera_comisiones_diferidas.sp                */
/*  Stored procedure:     sp_genera_comisiones_diferidas                */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         Ricardo Rincón                               */
/*  Fecha de escritura:   04/Ago/2021                                   */
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
/*  Calcular y almacenar las comisiones diferidas                       */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  04/Ago/2021   Ricardo Rincón  Emision Inicial                       */
/*  23/Ago/2021   Ricardo Rincón  Se borran tablas temporales de        */
/*                                la operacion en curso y se añade      */
/*                                distinct en consulta de rubros        */
/*  10/Sep/2021   Ricardo Rincón  Modificaciones en tabla temporal de   */
/*                                amortización original                 */
/*  16/May/2022   Guisela Fernandez  Actualización de proceso de genera-*/
/*                                  ción de comición de rubros diferidos*/
/*  20/May/2022   Guisela Fernandez  Validación i_param2 en null        */
/*  17/Jun/2022   Guisela Fernandez  Se aumenta campos en la actualiza  */
/*                                   ción de ca_operacion               */
/*  11/Ago/2022   Guisela Fernandez  R191712 Campo de fecha_pri_cuot a 0*/
/*                                   y parametro para control reproceso */
/*  15/Sep/2022   Guisela Fernandez  R193593 Actualización de campos    */
/*                                   cuando periodo_cap <> periodo_int  */
/*  23/Sep/2022   Kevin Rodriguex    R192940 Setear Base cálculo Comer- */
/*                                   a la operación tmp                 */
/************************************************************************/
(
	@t_show_version		bit 			= 0,
	@t_debug			char(1) 		= 'S',
	
	@s_culture			varchar(10) 	= 'NEUTRAL',
	
	@i_sarta			int 			= null,
	@i_batch			int 			= null,
	@i_secuencial		int 			= null,
	@i_corrida			int 			= null,
	@i_intento			int 			= null,
	
	@i_param1			datetime 		= null,	-- Fecha de proceso
	@i_param2			cuenta			= null, -- Número de operacion
	@i_param3			char(1)			= 'N'  -- Parámetro de reproceso S/N
	
) as

declare
	@w_sp_name			varchar(30)		= null,
	
	@w_error 			int 			= 0,
	@w_msg 				varchar(255)	= null,
	@w_return			int 			= 0,
	
	@w_fecha_proceso	datetime 		= null,
	
	@w_op_banco 		cuenta 			= null, 	-- operación
	@w_op_operacion  	int 			= null, 	-- operación
	@w_op_valor_cat 	float			= null, 	-- TIR
	@w_op_monto 		money			= null, 	-- monto del desembolso
	@w_op_tplazo 		varchar(10)		= null, 	-- tipo de plazo
	@w_op_plazo 		smallint		= null, 	-- plazo
	@w_op_tdividendo 	varchar(10)		= null, 	-- tipo de dividendo
	@w_op_periodo_cap 	smallint		= null, 	-- periodo del capital
	@w_op_periodo_int 	smallint		= null, 	-- periodo del interés
	@w_op_fecha_ini 	datetime		= null, 	-- fecha inicial del préstamo
	@w_op_fecha_fin 	datetime		= null, 	-- fecha final del préstamo
	
	@w_tasa 			float 			= null,
	@w_dias_gracia 		smallint 		= null,
	
	@s_user 			login 			= 'operador',
	@s_term 			varchar(30) 	= 'consola',
	@s_sesn 			int 			= 1,
	
	@w_saldo 			money 			= 1,
	
	@w_ro_concepto 		varchar(10)		= null, 	-- rubro
	@w_ro_valor 		money			= null, 	-- monto del rubro
	@w_valor_diferido 	money			= null, 		-- monto definitivo para cálculo de tabla de amortización (@w_op_monto - @w_ro_valor)
	
	@w_crd_cuota_sum	money			= null, 	-- sumatoria de los valores del rubro
	@w_crd_cuota		money			= null, 	-- valor del rubro actual por dividendo
	@w_crd_dividendo    int 			= NULL, 		-- dividendo
	@w_cat              float,
	@w_cat1             float,
	@w_tir              float,
	@w_tea              float,
	@w_banco 		    cuenta 			= null
	
-- captura el nombre del store procedure
select @w_sp_name   = 'sp_genera_comisiones_diferidas'

-- versionamiento del Programa
if @t_show_version = 1
begin
    print	@w_sp_name + ': Stored Procedure = '+ @w_sp_name + 'Version = ' + '1.0.0'
    return 0
end


--GFP 
IF @i_param2 = 'NULL'
  SELECT @i_param2 = null

select @w_fecha_proceso = @i_param1,
       @w_banco         = @i_param2

-- si la fecha de proceso viene nula, se consulta
if @w_fecha_proceso is null
begin
	select @w_fecha_proceso = fc_fecha_cierre
	from cobis..ba_fecha_cierre
	where fc_producto = 7  -- 7 para Cartera
end

-- Se crea tabla temporal #ca_operaciones_con_rubros_diferidos_tmp
create table #ca_operaciones_con_rubros_diferidos_tmp (
	ord_banco 			cuenta, 		-- número del préstamo
	ord_operacion  		int, 			-- operación
	ord_valor_cat 		float, 			-- tasa de interés
	ord_monto 			money, 			-- monto del desembolso
	ord_tplazo 			varchar(10), 	-- tipo de plazo
	ord_plazo 			smallint, 		-- plazo
	ord_tdividendo 		varchar(10), 	-- tipo de dividendo
	ord_periodo_cap 	smallint, 		-- periodo del capital
	ord_periodo_int 	smallint, 		-- periodo del interés
	ord_fecha_ini 		datetime, 		-- fecha inicial del préstamo
	ord_fecha_fin 		datetime 		-- fecha final del préstamo
)

-- Se crea tabla temporal #ca_rubtos_diferidos_por_operacion_tmp
create table #ca_rubtos_diferidos_por_operacion_tmp (
	rdo_operacion  		int, 			-- operación
	rdo_concepto 		varchar(10), 	-- rubro
	rdo_ro_valor 		money 			-- monto del rubro
)

-- Se crea tabla temporal #ca_rubro_op_base
create table #ca_rubro_op_base (
	ro_operacion 	int,
	amb_concepto 	varchar(10),
	amb_dividendo 	smallint,
	amb_cuota 		money
)

-- Se crea tabla temporal #ca_amortizacion_base
create table #ca_amortizacion_base (
	amb_operacion 	int,
	amb_concepto 	varchar(10),
	amb_dividendo 	smallint,
	amb_cuota 		money
)

-- Se crea tabla temporal #ca_dividendo_base
create table #ca_dividendo_base (
	dib_fecha_ini 	smalldatetime,
	dib_fecha_ven 	smalldatetime,
	dib_operacion 	int,
	dib_dividendo 	smallint
)

-- se consultan las operaciones que tienen rubros diferidos y se insertan en la tabla #ca_operaciones_con_rubros_diferidos_tmp
insert into #ca_operaciones_con_rubros_diferidos_tmp (
	ord_banco,
	ord_operacion,
	ord_valor_cat,
	ord_monto,
	ord_tplazo,
	ord_plazo,
	ord_tdividendo,
	ord_periodo_cap,
	ord_periodo_int,
	ord_fecha_ini,
	ord_fecha_fin
) 	select distinct 
		op_banco,
		op_operacion,
		op_valor_cat,
		op_monto,
		op_tplazo,
		op_plazo,
		op_tdividendo,
		op_periodo_cap,
		op_periodo_int,
		op_fecha_ini,
		op_fecha_fin
	from ca_transaccion,
	ca_det_trn,
	ca_operacion,
	ca_rubro_op
	where tr_secuencial = dtr_secuencial
	AND   (op_banco = @w_banco OR @w_banco IS NULL)
	and tr_operacion 	= dtr_operacion
	and tr_operacion 	= op_operacion
	and dtr_operacion 	= ro_operacion
	and dtr_concepto 	= ro_concepto
	and tr_tran 		= 'DES' 			-- DES para desembolso
	and tr_estado 		!= 'RV' 			-- diferente de reversado
	and tr_fecha_mov 	= @w_fecha_proceso 	-- fecha de movimiento
	and ro_limite 		= 'S' 				-- rubros diferidos

if @@error != 0 
	goto ERROR3

--GFP Validación de reproceso
if  exists(select 1 from ca_control_rubros_diferidos where crd_operacion in (select ord_operacion from #ca_operaciones_con_rubros_diferidos_tmp)) 
           and @i_param3 = 'N' 
begin
   select @w_error = 725184 
   goto ERROR3
end

-- se consultan los rubros diferidos para cada operación y se insertan en la tabla #ca_rubtos_diferidos_por_operacion_tmp
insert into #ca_rubtos_diferidos_por_operacion_tmp (
	rdo_operacion,
	rdo_concepto,
	rdo_ro_valor
) 	select  distinct
		ro_operacion,
		ro_concepto,
		ro_valor
	from ca_transaccion,
	ca_det_trn,
	ca_operacion,
	ca_rubro_op
	where tr_secuencial = dtr_secuencial
	AND   (op_banco = @w_banco OR @w_banco IS NULL)
	and tr_operacion 	= dtr_operacion
	and tr_operacion 	= op_operacion
	and dtr_operacion 	= ro_operacion
	and dtr_concepto 	= ro_concepto
	and tr_tran 		= 'DES' 			-- DES para desembolso
	and tr_estado 		!= 'RV' 			-- diferente de reversado
	and tr_fecha_mov 	= @w_fecha_proceso 	-- fecha de movimiento
	and ro_limite 		= 'S' 				-- rubros diferidos

if @@error != 0 
	goto ERROR3
	
-- se eliminan las operaciones coincidentes de laa tabla ca_control_rubros_diferidos
delete ca_control_rubros_diferidos where crd_operacion in (select ord_operacion from #ca_operaciones_con_rubros_diferidos_tmp)

-- se crea una cursor a partir de las operaciones que tienen rubros diferidos de la tabla #ca_operaciones_con_rubros_diferidos_tmp
declare operaciones cursor 
for select 
	ord_banco,
	ord_operacion,
	ord_valor_cat,
	ord_monto,
	ord_tplazo,
	ord_plazo,
	ord_tdividendo,
	ord_periodo_cap,
	ord_periodo_int,
	ord_fecha_ini,
	ord_fecha_fin
from #ca_operaciones_con_rubros_diferidos_tmp

open operaciones

fetch next from operaciones into
	@w_op_banco,
	@w_op_operacion,
	@w_op_valor_cat,
	@w_op_monto,
	@w_op_tplazo,
	@w_op_plazo,
	@w_op_tdividendo,
	@w_op_periodo_cap,
	@w_op_periodo_int,
	@w_op_fecha_ini,
	@w_op_fecha_fin

while (@@fetch_status = 0)
begin
	begin TRAN
	
	
	-- se crea un cursor para los rubros diferidos de cada operación a partir de la tabla ca_rubtos_diferidos_por_operacion_tmp
	declare rubros_diferidos cursor 
	for select 
		rdo_concepto,
		rdo_ro_valor
	from #ca_rubtos_diferidos_por_operacion_tmp
	where rdo_operacion = @w_op_operacion
	
	open rubros_diferidos

	fetch next from rubros_diferidos into
		@w_ro_concepto,
		@w_ro_valor
	
	while (@@fetch_status = 0)
	BEGIN
	
	  SELECT @w_tasa = @w_op_valor_cat
	
	  select @w_dias_gracia = di_gracia
	  from   ca_dividendo
	  where  di_operacion = @w_op_operacion
	  and    di_dividendo = 1
	
	  -- se borran tablas temporales
	  exec @w_error = sp_borrar_tmp
	       @s_user 	    = @s_user,
		   @s_sesn 	    = @s_sesn,
		   @s_term 	    = @s_term,
		   @i_banco     = @w_op_banco
	
	  if @w_error != 0 
		goto ERROR1
	
	  -- pasa los datos de la operación original a tablas temporales
	  exec @w_error = sp_pasotmp
		   @s_user            = @s_user,
		   @s_term            = @s_term,
		   @i_banco           = @w_op_banco,
		   @i_operacionca     = 'S',
		   @i_dividendo       = 'N',
		   @i_amortizacion    = 'N',
		   @i_cuota_adicional = 'S',
		   @i_rubro_op        = 'S',
		   @i_valores         = 'N',
		   @i_acciones        = 'N'
	
	  if @w_error != 0 
		goto ERROR1	
			
	  -- Actualiza los datos de la operación original en la tabla temporal de operaciones
	  update ca_operacion_tmp
	  set opt_tipo_amortizacion = 'FRANCESA',
	      opt_cuota             = 0.00,
		  opt_dia_fijo          = 0,
          opt_evitar_feriados   = 'N',
		  opt_fecha_pri_cuot    = null,	  --GFP 11/Ago/2022 Se setea a null para que el calculo de la tir lo realice como periodica
		  opt_base_calculo      ='E'      -- KDR 23/09/2022 Siempre tomar base calculo Comercial
	  where  opt_operacion      = @w_op_operacion
	
	  if @@error != 0 
	  begin
		select @w_error = 705022
		goto ERROR1
	  end
	  
	  --R193593 Actualiza periodo_cap cuando los periodos de int y cap con diferentes y periodo_cap > periodo_int
	  if @w_op_periodo_cap > @w_op_periodo_int 
	  begin
	     update ca_operacion_tmp
	     set opt_periodo_cap       = opt_periodo_int
	     where  opt_operacion      = @w_op_operacion
		 
		 if @@error != 0 
	     begin
		    select @w_error = 705022
		    goto ERROR1
	     end
	  end 

	  -- se genera la tabla de amortización con el rubro diferido actual
	  exec @w_error = sp_gentabla
	       @i_operacionca 			= @w_op_operacion,
		   @i_tabla_nueva 			= 'S',
		   @i_dias_gracia 			= @w_dias_gracia,
		   @i_actualiza_rubros 	= 'N', -- Para que respete la tasa de la ca_rubro_op
		   @i_crear_op 			= 'N', -- No se usa
		   @i_control_tasa 		= 'N', -- No se usa en esta version, es para controlar tasa maxima IBC
		   @i_periodo 				= @w_op_tdividendo
	
	  if @w_error != 0 
		goto ERROR1
		
      TRUNCATE TABLE #ca_amortizacion_base
        	
	  insert into #ca_amortizacion_base
	  select 
	      amt_operacion,
		  amt_concepto,
		  amt_dividendo,
		  amt_cuota
	  from ca_amortizacion_tmp
	  where amt_operacion = @w_op_operacion
	  
	  TRUNCATE TABLE #ca_dividendo_base
	  
	  insert into #ca_dividendo_base
	  select 
		  dit_fecha_ini,
		  dit_fecha_ven,
		  dit_operacion,
		  dit_dividendo
	  from ca_dividendo_tmp
	  where dit_operacion = @w_op_operacion
      	
      delete ca_rubro_op_tmp
      where  rot_operacion = @w_op_operacion
      AND    rot_tipo_rubro NOT IN ('C','I','M')
      AND    rot_concepto <> @w_ro_concepto

      if @@error != 0
      begin
         select @w_error = 710003
         goto ERROR1
      end                            
	    			
	  EXEC @w_error	= sp_tir
		   @i_banco	= @w_op_banco, 
		   @i_temporales = 'S',
		   @o_cat		= @w_cat1 OUTPUT , 
		   @o_tir		= @w_tir  OUTPUT,
		   @o_tea		= @w_tea OUTPUT
		 
	  if @w_error != 0
         goto ERROR1
   
	  -- se obtiene el monto de capital definitivo para crear una tabla de amortización temporal
	  select @w_valor_diferido = @w_op_monto - @w_ro_valor

	  -- actualiza los datos de la operación original en la tabla temporal de operaciones
	  update ca_operacion_tmp
	  set opt_monto             = @w_valor_diferido,  -- saldo
	   	  opt_monto_aprobado    = @w_valor_diferido,  -- saldo
		  opt_tipo_amortizacion = 'FRANCESA',
		  --opt_cuota           = 0.00,               -- No se envia la cuota para mantener la misma cuota
		  opt_dia_fijo          = 0,
          opt_evitar_feriados   = 'N',
		  opt_fecha_pri_cuot    = null,	              --GFP 11/Ago/2022 Se setea a null para que el calculo de la tir lo realice como periodica
		  opt_base_calculo      ='E'                  -- KDR 23/09/2022 Siempre tomar base calculo Comercial
	  where  opt_operacion      = @w_op_operacion
		
	  if @@error != 0 
      begin
	     select @w_error = 705022
		 goto ERROR1
      end

	  --R193593 Actualiza periodo_cap cuando los periodos de int y cap con diferentes y periodo_cap > periodo_int	
	  if @w_op_periodo_cap > @w_op_periodo_int
	  begin
	     update ca_operacion_tmp
	     set opt_periodo_cap       = opt_periodo_int
	     where  opt_operacion      = @w_op_operacion
		 
		 if @@error != 0 
	     begin
		    select @w_error = 705022
		    goto ERROR1
	     end
	  end 
		
	  -- actualiza los datos de la operación original del capital en la tabla temporal de rubros
	  update ca_rubro_op_tmp
	  set    rot_valor 		 = @w_valor_diferido
	  where  rot_operacion 	 = @w_op_operacion
	  AND    rot_tipo_rubro  = 'C'
	  AND    rot_fpago 		 = 'P'
		
	  if @@error != 0 
		begin
		  select @w_error = 705022
		  goto ERROR1
		END
       
	  -- actualiza los datos de la operación original del interés en la tabla temporal de rubros
	  update ca_rubro_op_tmp
	  set    rot_porcentaje 	 = @w_tir,
	         rot_porcentaje_aux  = @w_tir
	  where  rot_operacion 	     = @w_op_operacion
	  AND    rot_tipo_rubro 	 = 'I'
	  AND    rot_fpago 		     = 'P'
		
	  if @@error != 0 
		begin
		  select @w_error = 705022
		  goto ERROR1
		END
		
	  -- se genera la tabla de amortización con el rubro diferido actual
	  exec @w_error = sp_gentabla
			@i_operacionca 			= @w_op_operacion,
			@i_tabla_nueva 			= 'S',
			@i_dias_gracia 			= @w_dias_gracia,
			@i_actualiza_rubros 	= 'N', -- Para que respete la tasa de la ca_rubro_op
			@i_crear_op 			= 'N', -- No se usa
			@i_control_tasa 		= 'N', -- No se usa en esta version, es para controlar tasa maxima IBC
			@i_periodo 				= @w_op_tdividendo

	  if @w_error != 0 
			goto ERROR1

	  insert into ca_control_rubros_diferidos (
			crd_operacion,
			crd_concepto,
			crd_dividendo,
			crd_fecha_ini,
			crd_fecha_ven,
			crd_cuota,
			crd_acumulado
		) 	select 
				@w_op_operacion,
				@w_ro_concepto,
				amb_dividendo,
				(select top 1 di_fecha_ini from ca_dividendo where di_operacion = @w_op_operacion and di_dividendo = amb_dividendo), --GFP 11/Ago/2022 Para obtener fechas reales de los dividendos
				(select top 1 di_fecha_ven from ca_dividendo where di_operacion = @w_op_operacion and di_dividendo = amb_dividendo), --GFP 11/Ago/2022 Para obtener fechas reales de los dividendos
				(select top 1 amt_cuota from ca_amortizacion_tmp where amt_operacion = @w_op_operacion and amt_concepto = 'INT' and amt_dividendo = amb_dividendo) - amb_cuota,
				0
			from #ca_amortizacion_base
			where amb_operacion = @w_op_operacion
			and amb_concepto = 'INT'
			
	  if @@error != 0 
			goto ERROR1
			
	  -- Se actualiza última cuota si la sumatoria de crd_cuota no da exactamente igual al monto del rubro
	  select @w_crd_cuota_sum = sum(crd_cuota) 
	  from ca_control_rubros_diferidos 
	  where crd_operacion  = @w_op_operacion
	  and crd_concepto 	   = @w_ro_concepto
		
	  if @w_crd_cuota_sum != @w_ro_valor
		begin
			select top 1
				@w_crd_dividendo = crd_dividendo,  
				@w_crd_cuota = crd_cuota
				from ca_control_rubros_diferidos 
				where crd_operacion  = @w_op_operacion
				and crd_concepto 	 = @w_ro_concepto
				order by crd_dividendo desc
			
			select @w_crd_cuota = @w_crd_cuota + @w_ro_valor - @w_crd_cuota_sum
			
			update ca_control_rubros_diferidos 
			set crd_cuota = @w_crd_cuota 
			where crd_dividendo  = @w_crd_dividendo
			and crd_operacion 	 = @w_op_operacion 
			and crd_concepto 	 = @w_ro_concepto
			
			if @@error != 0 
				goto ERROR1
		end
		
		fetch next from rubros_diferidos into
			@w_ro_concepto,
			@w_ro_valor
	end
	
	close rubros_diferidos
	deallocate rubros_diferidos
	
	-- se borran tablas temporales
	exec @w_error 	= sp_borrar_tmp
		@s_user 	= @s_user,
		@s_sesn 	= @s_sesn,
		@s_term 	= @s_term,
		@i_banco 	= @w_op_banco
	
	if @w_error != 0 
		goto ERROR2
	
	commit tran
	
	fetch next from operaciones into
		@w_op_banco,
		@w_op_operacion,
		@w_op_valor_cat,
		@w_op_monto,
		@w_op_tplazo,
		@w_op_plazo,
		@w_op_tdividendo,
		@w_op_periodo_cap,
		@w_op_periodo_int,
		@w_op_fecha_ini,
		@w_op_fecha_fin
end

close operaciones
deallocate operaciones

return 0

ERROR1:
--print 'se produjo un error cuando se recorria cursor rubros_diferidos'

close rubros_diferidos
deallocate rubros_diferidos

goto ERROR2

ERROR2:
--print 'se produjo un error cuando se recorria cursor operaciones'

close operaciones
deallocate operaciones

rollback tran

-- se borran tablas temporales
exec @w_return 	= sp_borrar_tmp
	@s_user 	= @s_user,
	@s_sesn 	= @s_sesn,
	@s_term 	= @s_term,
	@i_banco 	= @w_op_banco
	
if @w_return != 0 
begin
   select @w_error = @w_return
   goto ERROR3
end

ERROR3:

exec sp_errorlog
    @i_fecha       = @w_fecha_proceso, 
    @i_error       = @w_error, 
    @i_usuario     = null,
    @i_tran        = 0, 
    @i_tran_name   = @w_sp_name, 
    @i_rollback    = 'N',
    @i_cuenta      = @w_op_banco

exec cobis..sp_cerror
	@t_debug = 'N',
	@t_file  = '',
	@t_from  = @w_sp_name,
	@i_num   = @w_error

return @w_error

go
