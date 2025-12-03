/*************************************************************************/
/*   Archivo:              cu_procdepi.sp                                */
/*   Stored procedure:     sp_cu_proceso_depre_ini                       */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_cu_proceso_depre_ini') IS NOT NULL
    DROP PROCEDURE dbo.sp_cu_proceso_depre_ini
go
create proc sp_cu_proceso_depre_ini
	@i_fecha_proceso	datetime = null,
	@i_empresa		int	 = null,
	@i_operacion		char(01) = null,
	@s_user        login    = null,   --Miguel Aldaz 26/Feb/2015
	@s_term        varchar(30)   = null --Miguel Aldaz 26/Feb/2015
as

declare @w_fecha_ini	datetime,
	@w_fecha_fin	datetime,
	@w_operacion	varchar(10),
	@w_oficina	int,
	@w_sucursal	int,
	@w_tipo		varchar(64),
	@w_codigo_externo varchar(64),
	@w_fecha_tran	datetime,
	@w_fecha_insp	datetime,
	@w_fecha_ulti	datetime,
	@i_valor	money,
	@w_valor	money,
	@w_valor_inicial money,
	@w_valor_actual	money,
	@w_porcentaje	float,
	@w_porcentaje2	float,
	@w_porcentaje_ini	float,
	@w_dias		int,
	@w_seguro	char(1),
	@w_polizas	smallint,
	@i_total	money,
	@w_cont		int,
	@w_cont1	int,
	--
	@w_fecha_ini1	datetime,
	@w_fecha_fin1	datetime,
	@w_plazo	smallint,
	@w_tplazo	char(10),
	@w_plazo_seg	smallint,
	@w_tdividendo	char(10),
	@w_financia	char(1),
	@w_tdias	smallint,
	@w_meses	smallint,
	@w_poliza_ini	char(10),
	@w_poliza_fin	char(10),
	@w_custodia	int,
	@w_return	int,
	@w_msg		varchar(132),
	@w_sp_name	varchar(50),
	@w_vez		int,
	@w_registro	int,
	@w_periodicidad	int,
	@w_msj_error	char(100),
	@w_periodo	int,
	@w_max_periodo	int,
	@w_ssn		int

select	@w_sp_name = 'sp_cu_proceso_depre_ini'

select	@w_max_periodo = 4

select	@w_registro = 1

--declare garantias insensitive  cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
declare garantias cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
select	fecha_ini = convert(char(10), op_fecha_ini, 101), 
	fecha_fin = convert(char(10), op_fecha_fin, 101), 
	op_banco, 
	op_oficina, 
	cu_sucursal,
	cu_tipo, 
	cu_custodia,
	cu_codigo_externo,
	fecha_tran = convert(char(10), dateadd(mm, convert(int, tc_periodicidad), op_fecha_ini), 101),
	cu_fecha_insp = convert(char(10), cu_fecha_insp, 101),
	cu_valor_inicial, 
	cu_valor_actual, 
	tc_porcentaje,
	convert(int, tc_periodicidad),
	dp_dias,
	tiene_seguro = ( select 'S' from cob_cartera..ca_rubro_op where ro_concepto in ('SEGVEH','SEGFIN')
									and ro_operacion = o.op_operacion ),
	num_polizas = ( select count(*) from cob_custodia..cu_poliza where po_codigo_externo = c.cu_codigo_externo
									and po_estado_poliza = 'V' )
 from 	cob_custodia..cu_tipo_custodia, 
 	cob_custodia..cu_custodia c, 
 	cob_custodia..cu_dias_periodicidad, 
	cob_cartera..ca_operacion o
where 	isnull(tc_porcentaje,0) <> 0
  and 	tc_periodicidad         = dp_periodicidad
  and 	cu_filial               = @i_empresa
  and 	tc_tipo                 = cu_tipo
  and 	cu_estado               = 'V'
  and 	op_tramite in ( select gp_tramite from cob_credito..cr_gar_propuesta
                        where gp_garantia = c.cu_codigo_externo )
  and 	op_tipo in ('F', 'P')
  
  --and 	op_fecha_fin >= @i_fecha_proceso
  --and 	cu_codigo_externo = '501530000000005'

open garantias

fetch garantias 
into 	@w_fecha_ini, 
	@w_fecha_fin, 
	@w_operacion, 
	@w_oficina, 
	@w_sucursal,
	@w_tipo, 
	@w_custodia,
	@w_codigo_externo, 
	@w_fecha_tran, 
	@w_fecha_insp, 
	@w_valor_inicial, 
	@w_valor_actual, 
	@w_porcentaje, 
	@w_periodicidad,
	@w_dias,
	@w_seguro, 
	@w_polizas

while @@FETCH_STATUS <> -1
 begin
	select @w_periodo = 0
	
	select	@w_porcentaje_ini = @w_porcentaje
	
	if @w_fecha_ini < '05/01/2004'
		select 	@w_porcentaje = 10,
			@w_porcentaje_ini = 10

	select @i_valor = @w_valor_inicial * @w_porcentaje / 100

	select @i_total = @w_valor_inicial
	
	--print 'Primer @i_valor %1!', @i_valor
	
	select @w_vez = 1

	while 1 = 1
	 begin
		select @w_msj_error = ''
		select @w_valor = 0, @w_fecha_ulti = null

		if @w_fecha_ini > '04/30/2004'
		  begin
			select 	@w_valor = @i_total * dtc_porcentaje / 100,
				@w_porcentaje2 = dtc_porcentaje
			  from 	cu_custodia, 
			  	cu_dtipo_custodia
			 where 	cu_codigo_externo = @w_codigo_externo
			   and 	cu_tipo = dtc_tipo
			   --and 	dtc_anio = datediff(yy,cu_fecha_ingreso, @w_fecha_tran)
			   and 	dtc_anio = datediff(yy,@w_fecha_ini, @w_fecha_tran)

			if @@rowcount > 0
			 begin
			 	--print '@w_valor %1!, @w_porcentaje2 %2!', @w_valor, @w_porcentaje2
			 	
			 	select 	@i_valor = @w_valor
			 	
			 	if @w_vez = 1
			 		select	@w_porcentaje_ini = @w_porcentaje2 
			 end
			 	
			
			--print 'Segundo @i_valor %1!', @i_valor
		  end
		
		--select 'Primero'

		select @w_cont = datediff(dd, @i_fecha_proceso, @w_fecha_tran)
		select @w_periodo = datediff(yy, @w_fecha_ini, @w_fecha_tran)
		
		if @w_periodo > @w_max_periodo
			break

		if @w_cont > 0
		 begin
			--select @w_fecha_tran = convert(char(10),dateadd(dd, -@w_dias, @w_fecha_tran),101)
		     	select @w_fecha_tran = convert(char(10),dateadd(mm, -@w_periodicidad, @w_fecha_tran),101)
		     	--print 'Primero @w_fecha_tran %1!, Luego viene el break', @w_fecha_tran
		     	break
		 end

		select @i_total = @i_total - @i_valor

		--select @w_fecha_ulti = convert(char(10), dateadd(dd, @w_dias, @w_fecha_tran),101)
		select @w_fecha_ulti = convert(char(10), dateadd(mm, @w_periodicidad, @w_fecha_tran),101)
		--print 'Primero @w_fecha_ulti %1!', @w_fecha_ulti
		
/*		select	@i_fecha_proceso,
			@w_fecha_tran,
			@w_fecha_ulti,
			@w_cont,
			@i_valor
*/		
		if @i_operacion = 'I'
		 begin
/*		 	select 	@i_valor as valor_1,
		 		@w_fecha_ulti as fecha_ult,
		 		@w_valor_actual as valor_actual,
		 		@w_valor_inicial as valor_inicial
*/		 	
		 	exec @w_ssn = ADMIN...rp_ssn 1, 2
		 	
		 	begin tran 
		 	
		 	if @w_vez = 1
				exec @w_return = sp_transaccion
					@s_ssn = @w_ssn,
					@s_ofi = @w_oficina,
					@s_date = @i_fecha_proceso,
					@s_user	= @s_user, --Miguel Aldaz 26/Feb/2015
					@s_term = @s_term, --Miguel Aldaz 26/Feb/2015					
					@t_trn = 19000,
					@i_operacion = 'I',
					@i_filial = @i_empresa,
					@i_sucursal = @w_sucursal,
					@i_tipo_cust = @w_tipo,
					@i_custodia = @w_custodia,
					@i_fecha_tran = @w_fecha_tran,
					@i_debcred = 'D',
					@i_valor = @i_valor,
					@i_descripcion = 'DEPRECIACION AUTOMATICA INICIAL',
					@i_usuario = 'operadores',
					@i_cancelacion = 'N',
					@i_ind_depre = 1
			else
				exec @w_return = sp_transaccion
					@s_ssn = @w_ssn,
					@s_ofi = @w_oficina,
					@s_date = @i_fecha_proceso,
					@s_user	= @s_user, --Miguel Aldaz 26/Feb/2015
					@s_term = @s_term, --Miguel Aldaz 26/Feb/2015
					@t_trn = 19000,
					@i_operacion = 'I',
					@i_filial = @i_empresa,
					@i_sucursal = @w_sucursal,
					@i_tipo_cust = @w_tipo,
					@i_custodia = @w_custodia,
					@i_fecha_tran = @w_fecha_tran,
					@i_debcred = 'D',
					@i_valor = @i_valor,
					@i_descripcion = 'DEPRECIACION AUTOMATICA INICIAL',
					@i_usuario = 'operadores',
					@i_cancelacion = 'N'
					
			
			if @w_return <> 0
			 begin
				--select	@w_msg = '[' + @w_sp_name + '] ' + 'Error al ingresar la transacción'
				--goto error
				select @w_msj_error = 'No se registró la transacción'
				break
			 end
			
			--print 'Update @i_valor %1!', @i_valor
			
			update	cu_custodia
			   set	cu_fecha_insp = @w_fecha_tran,
			   	cu_fecha_prox_insp = @w_fecha_ulti
			 where	cu_codigo_externo = @w_codigo_externo
			 
			 --print 'Update @w_fecha_tran %1!, @w_fecha_ulti %2!', @w_fecha_tran, @w_fecha_ulti

			commit tran
		 end

		--select 'Segundo'

		select @w_cont = datediff(dd, @i_fecha_proceso, @w_fecha_ulti)

		if @w_cont > 0
		begin
			--select @w_fecha_tran = convert(char(10),dateadd(dd,-@w_dias,@w_fecha_ulti),101)
			select @w_fecha_tran = convert(char(10),dateadd(mm,-@w_periodicidad, @w_fecha_ulti),101)
			--print 'Segundo @w_fecha_tran %1!, Luego viene el break', @w_fecha_tran
		     	break
		end

		select @w_fecha_tran = convert(char(10),dateadd(mm, @w_periodicidad, @w_fecha_tran),101)
		--print 'Tercer @w_fecha_tran %1!', @w_fecha_tran
		
		select @i_valor = @i_total * @w_porcentaje / 100
		
		--print 'Tercer @i_valor %1!', @i_valor
		
		select @w_vez = @w_vez + 1
		
		/*		
		if @i_operacion = 'I'
		 begin
		 	select 	@i_valor as valor_2,
				@w_fecha_ulti as fecha_ult,
				@w_valor_actual as valor_actual,
		 		@w_valor_inicial as valor_inicial
		 		
			exec @w_return = sp_transaccion
				@s_ssn = 0,
				@s_ofi = @w_oficina,
				@t_trn = 19000,
				@i_operacion = 'I',
				@i_filial = @i_empresa,
				@i_sucursal = @w_sucursal,
				@i_tipo_cust = @w_tipo,
				@i_custodia = @w_custodia,
				@i_fecha_tran = @w_fecha_tran,
				@i_debcred = 'D',
				@i_valor = @i_valor,
				@i_descripcion = 'DEPRECIACION AUTOMATICA INICIAL',
				@i_usuario = 'operadores',
				@i_cancelacion = 'N'
		 end
		*/

	 end

/*********************/

	select 	@w_fecha_ini1 = convert(varchar(10),op_fecha_ini,101), 
		@w_fecha_fin1 = convert(varchar(10),op_fecha_fin,101),
		@w_plazo = case op_tplazo
			when 'A' then (op_plazo * 365)/30
			when 'B' then (op_plazo * 2)
			when 'D' then op_plazo / 30
			when 'S' then (op_plazo * 6)
			when 'T' then (op_plazo * 3)
			else op_plazo end,
		@w_plazo_seg = 0,
		@w_financia = 0,
		/*	Se comenta porque no existe la columna
			@w_plazo_seg = case op_tdividendo
			when 'A' then (op_plazo_seg * 365)/30
			when 'B' then (op_plazo_seg * 2)
			when 'D' then op_plazo_seg / 30
			when 'S' then (op_plazo_seg * 6)
			when 'T' then (op_plazo_seg * 3)
			else op_plazo_seg end,
		@w_financia = op_financiar_seg, */
		@w_meses    =  0 /*op_gracia_cap -> no existe en la tabla*/
	  from 	cob_cartera..ca_operacion
	 where 	op_banco = @w_operacion


	if @w_plazo > @w_plazo_seg
		select @w_meses = (@w_plazo - @w_plazo_seg)

	select 	@w_poliza_ini = convert(char(10),@w_fecha_ini1,101),
		@w_poliza_fin = convert(char(10),@w_fecha_fin1,101)

	if @w_financia = 'P'
		select @w_poliza_fin = convert(char(10),dateadd(mm,-@w_meses,@w_fecha_fin1),101) --hasta
	else
	 	select @w_poliza_ini = convert(char(10),dateadd(mm,@w_meses,@w_fecha_ini1),101) --desde


/*********************/

	if @w_fecha_ulti is not null
	 begin
	
		exec sp_poliza_depreciacion 
		@s_user	       		= @s_user, --Miguel Aldaz 26/Feb/2015
		@s_term 			= @s_term, --Miguel Aldaz 26/Feb/2015
		@t_trn		  = 19766,
		@i_operacion 	  = 'S', 
		@i_codigo_externo = @w_codigo_externo,
		@i_monto_endozo	  = @i_total,
		@i_fecha_endozo	  = @w_fecha_tran,
		@i_fendozo_fin	  = @w_fecha_ulti,
		@i_banco	  = @w_operacion


		insert into proc_garantias 
		values 	(
			@w_fecha_ini, 
			@w_fecha_fin, 
			@w_operacion, 
			@w_oficina, 
			@w_tipo, 
			@w_codigo_externo, 
			@w_valor_inicial, 
			@w_valor_actual, 
			@w_fecha_insp, 
			@w_fecha_tran, 
			@i_total, 
			@w_fecha_ulti,
			@w_porcentaje_ini, 
			@w_seguro, 
			@w_polizas, 
			@w_financia, 
			@w_poliza_ini, 
			@w_poliza_fin, 
			@w_meses,
			@w_periodo,
			@w_msj_error
			)
	 end
	
	select	@w_registro = @w_registro + 1
	
	--if @w_registro > 10
	--	break

	fetch garantias 
	into 	@w_fecha_ini, 
		@w_fecha_fin, 
		@w_operacion, 
		@w_oficina, 
		@w_sucursal,
		@w_tipo, 
		@w_custodia,
		@w_codigo_externo, 
		@w_fecha_tran, 
		@w_fecha_insp, 
		@w_valor_inicial, 
		@w_valor_actual, 
		@w_porcentaje, 
		@w_periodicidad,
		@w_dias,
		@w_seguro, 
		@w_polizas

end

close garantias
deallocate garantias

set rowcount 0

/*
select	fecha_ini = convert(char(10),fecha_ini,101), fecha_fin = convert(char(10),fecha_fin,101),
	operacion, oficina, tipo_gara, codigo_externo, valor_inicial, valor_actual,
	fecha_insp = convert(char(10),fecha_insp,101), fecha_nueva = convert(char(10),fecha_nueva,101),
	valor_nuevo, fecha_prox = convert(char(10),fecha_prox,101), porcentaje, tiene_seguro = isnull(tiene_seguro,'N'),
	num_polizas, financia, poliza_ini = convert(char(10),poliza_ini,101), poliza_fin = convert(char(10),poliza_fin,101), plazo
from proc_garantias*/
/*where plazo > 0
and tiene_seguro = 'S'*/

return 0

error:
	exec cobis..sp_cerror
	      @t_from  = @w_sp_name,
	      @i_num   = 99999,
	      @i_msg   = @w_msg
	
	rollback tran
	
    	return 1
go