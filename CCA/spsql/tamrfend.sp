/************************************************************************/
/*      Archivo:                tamrfend.sp                             */
/*      Stored procedure:       sp_tamor_fend                           */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */      
/*      Fecha de escritura:     Ene  2003                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Genera la tabla de amortizacion proyectada para los creditos    */
/*      de vivienda, despues de generar el UVR para un a¤o si ‚ste no   */
/*	hab¡a sido generado ya.						*/
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      28/Ene/2003     M. Mari¤o         			        */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tamor_fend')
	drop proc sp_tamor_fend
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_tamor_fend
				(
@s_sesn              int         = null,
@s_date              datetime    = null,
@s_user              login       = null,
@s_term              descripcion = null,
@s_corr              char(1)     = null,
@s_ssn_corr          int         = null,
@s_ofi               smallint    = null,
@t_rty               char(1)     = null,
@t_debug             char(1)     = 'N',
@t_file              varchar(14) = null,
@t_trn		     smallint    = null,  
@i_operacion	     char(1)     = null,
@i_fecha_inicial	datetime,
@i_banco		cuenta = null)

as
declare 
	@w_error			int,
	@w_sp_name			descripcion,
	@w_moneda_uvr			int,
	@w_est_novigente		int,
	@w_est_vigente			int,
	@w_est_cancelado		int,
	@w_ano				int,
	@w_up_cotizacion		float,
	@w_ipc				float,
	@w_i				smallint,
	@w_date_ipc			datetime,
	@w_anoipc			int,
	@w_mes				int,
	@w_numdias			int,
	@w_uvr_inicial			float,
	@w_fecha_uvr			datetime,
	@w_fecha_final			datetime,
	@w_t				float,
	@w_expo				float,
	@w_parcial			float,
	@w_valor_final			float,
	@w_cu_banco			cuenta,
	@w_cu_operacion			int,
	@w_cu_toperacion		catalogo,
	@w_cu_moneda			int,
	@w_cu_cliente 			int,
	@w_cu_nombre			descripcion,
	@w_cu_dividendo			int,
	@w_cu_dias_cuota		int,
	@w_cu_fecha_ven			datetime,
	@w_cu_concepto			catalogo,
	@w_cu_cuota_total		float,
	@w_cu_dividendo_anterior	int,
	@w_val1				float,
	@w_val2				float,
	@w_val3				float,
	@w_val4				float,
	@w_val5				float,
	@w_val6				float,
	@w_val7				float,
	@w_cotiz			float,
	@w_fecha_dividendo		datetime,
	@w_suma				float,
	@w_cu_operacion_anterior	int,
	@w_hay_valor			catalogo,
	@w_dadiff		int



/*  NOMBRE DEL SP  */
select  @w_sp_name = 'sp_tamor_fend' 

if @i_operacion = 'I'
begin

  delete from ca_amortizacion_proyectada
  where ap_operacion >=0 


  /*SELECCIàN DEL CODIGO DE LA MONEDA*/
  select @w_moneda_uvr = pa_tinyint from cobis..cl_parametro    
  where pa_producto = 'CCA'
  and   pa_nemonico = 'MUVR'
  set transaction isolation level read uncommitted


  /*SELECCI…N DEL CODIGO DE LA TASA UVR INICIAL*/
  select @w_uvr_inicial = pa_float
  from cobis..cl_parametro    
  where pa_producto = 'CCA'
  and pa_nemonico = 'TUVR'
  set transaction isolation level read uncommitted


  /* ESTADOS PARA OPERACIONES*/

  select @w_est_vigente = isnull(es_codigo, 255)
  from   ca_estado
  where  rtrim(ltrim(es_descripcion)) = 'VIGENTE'

  select @w_est_cancelado  = isnull(es_codigo, 255)
  from   ca_estado
  where  rtrim(ltrim(es_descripcion)) = 'CANCELADO'

  select @w_est_novigente  = isnull(es_codigo, 255)
  from   ca_estado
  where  rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'


  select @w_ano = datepart(yy,@i_fecha_inicial)

  select @w_up_cotizacion = isnull(up_cotizacion, 0)
  from ca_uvr_proyectado
  where up_fecha = '02/02/' + convert(varchar(4),@w_ano)  -- revisa si ya se ha calculado el uvr 
							-- para el a¤o de la fecha 
							-- que ingresa
--print '@w_up_cotizacion %1!',@w_up_cotizacion


  if @w_up_cotizacion = 0 or @w_up_cotizacion is null
  begin


	if @w_uvr_inicial = 0 or @w_uvr_inicial is null
	begin
		select @w_error = 710390
   		goto ERROR
	end  

	
	delete from ca_uvr_proyectado	
   where up_fecha >= '01/01/1900'

	select @w_date_ipc = convert(datetime,'1/1/' + convert(varchar(4),@w_ano))

	select @w_fecha_uvr = '1/16/' + convert(varchar(4),@w_ano)

	select @w_fecha_final = '2/15/' + convert(varchar(4),@w_ano)

	
	select @w_i = 1
	while	@w_i < 13 
	begin	

--print '@w_fecha_uvr: %1!  @w_fecha_final: %2! ', @w_fecha_uvr, @w_fecha_final 

--print '@w_uvr_inicial %1! ', @w_uvr_inicial


		select  @w_ipc = isnull(vr_valor,0)
		from ca_valor_referencial
		where vr_tipo = 'IPCP'
		and vr_fecha_vig = convert(varchar(10),@w_date_ipc,101)	

--print 'IPC %1!', @w_ipc 

		if @w_ipc = 0 or @w_ipc is null
		begin
			select @w_error = 710388
		   	goto ERROR
		end 
		

		select @w_mes = @w_i		
	
		if @w_mes = 1	
			select @w_numdias = 31
		else if @w_mes = 2
		begin 
			if (@w_ano % 4) = 0
				select @w_numdias = 29
			else
				select @w_numdias = 28		
			
		end
		else if @w_mes = 3
			select @w_numdias = 31
		else if @w_mes = 4
			select @w_numdias = 30
		else if @w_mes = 5
			select @w_numdias = 31
		else if @w_mes = 6
			select @w_numdias = 30.
		else if @w_mes = 7
			select @w_numdias = 31
		else if @w_mes = 8
			select @w_numdias = 31
		else if @w_mes = 9
			select @w_numdias = 30
		else if @w_mes = 10
			select @w_numdias = 31
		else if @w_mes = 11
			select @w_numdias = 30
		else if @w_mes = 12
			select @w_numdias = 31



		select @w_t = 1

		while datediff(dd,convert(datetime,@w_fecha_uvr), convert(datetime,@w_fecha_final)) >= 0
		begin

--print '@w_fecha_uvr: %1!  @w_fecha_final: %2! ', @w_fecha_uvr, @w_fecha_final

			select @w_expo = @w_t / @w_numdias

--print '@w_t: %1! @w_numdias: %2! = @w_expo : %3!', @w_t, @w_numdias, @w_expo
  
			select @w_parcial  = POWER(1 + @w_ipc,@w_expo) 
			select @w_valor_final = @w_parcial * @w_uvr_inicial

--print ' @w_valor_final %1!', @w_valor_final		

			insert into ca_uvr_proyectado
			values (@w_fecha_uvr,@w_valor_final)

			select @w_t = @w_t + 1 		
	
			select @w_fecha_uvr = dateadd(dd,1,@w_fecha_uvr)
			

		end -- while datediff(dd,conv...

		select @w_uvr_inicial = @w_valor_final

		select @w_date_ipc = dateadd(mm,1,convert(datetime,@w_date_ipc)) 
		select @w_fecha_final = dateadd(mm,1,convert(datetime,@w_fecha_final)) 

		select @w_i = @w_i + 1
	

	end -- while @w_i < 13



  end --if @w_up_cotizacion = 0 or @w_up_cotizacion is null


  /*SE SELECCIONA TODAS LAS OPERACIàNES QUE ESTEN EN MONEDA UVR Y CLASE VIVIENDA */


  if @w_fecha_final is null
  begin
	select @w_fecha_final = max(up_fecha)
	from ca_uvr_proyectado

  end


  select 
  op_operacion =  op_operacion,
  op_banco = op_banco,
  op_toperacion = op_toperacion,	
  op_moneda = op_moneda,
  op_cliente = op_cliente,
  op_nombre =  op_nombre
  --into tmp_operacion_vi 
  into #ca_operacion_vivienda
  from   ca_operacion
  where (op_banco  = @i_banco or @i_banco is null)
  and    op_estado = @w_est_vigente
  and    op_clase  = '3'   --VIVIENDA
  and    op_moneda = @w_moneda_uvr



  declare cursor_operacion cursor for

  select
  op_operacion, op_banco,
  op_toperacion,op_moneda,op_cliente,op_nombre
  from 
  #ca_operacion_vivienda
  for read only

  --tmp_operacion_vi 

  open cursor_operacion

	fetch cursor_operacion into
	@w_cu_operacion,@w_cu_banco,@w_cu_toperacion,
	@w_cu_moneda, @w_cu_cliente, @w_cu_nombre

	select @w_cu_dividendo_anterior = -1 
	
	while @@fetch_status = 0 
	begin

--print '@w_cu_banco: %1!, @w_cu_operacion: %2! ,@w_cu_toperacion: %3!',	@w_cu_banco,@w_cu_operacion,@w_cu_toperacion
--print '@w_cu_moneda: %1!, @w_cu_cliente: %2!, @w_cu_nombre : %3!', @w_cu_moneda, @w_cu_cliente, @w_cu_nombre

		if @@fetch_status = -1 
		begin    
       			select @w_error = 708999
		        goto  ERROR
   		end   


		declare cursor_rubros cursor for
	        select di_dividendo,di_dias_cuota,di_fecha_ven,  
	        ro_concepto,sum(am_cuota+am_gracia-am_pagado) as cuota_total
	        from ca_rubro_op, ca_dividendo, ca_amortizacion
        	where ro_operacion = @w_cu_operacion 
	        and ro_operacion = di_operacion
        	and ro_operacion = am_operacion
          	and ro_concepto  = am_concepto
          	and di_dividendo = am_dividendo
          	and di_estado   != @w_est_cancelado
                and datediff(dd,di_fecha_ven,@w_fecha_final) >= 0   
        	group by di_dividendo,di_dias_cuota,di_fecha_ven,ro_concepto
                for read only

		open cursor_rubros
		
			fetch cursor_rubros into
			@w_cu_dividendo, @w_cu_dias_cuota, @w_cu_fecha_ven, @w_cu_concepto,
			@w_cu_cuota_total
			

			while @@fetch_status = 0 
			begin	
				
				if @@fetch_status = -1 
				begin    
       					select @w_error = 708999
				        goto  ERROR
   				end   

--print '@w_cu_dividendo:%1! ,@w_cu_dias_cuota:%2! ', @w_cu_dividendo, @w_cu_dias_cuota
--print '@w_cu_fecha_ven:%1! ,@w_cu_concepto:%2!', @w_cu_fecha_ven, @w_cu_concepto
--print '@w_cu_cuota_total: %1! ',@w_cu_cuota_total

				
				if @w_cu_dividendo_anterior != @w_cu_dividendo
				begin	


					/*Al cambiar de dividendo hace el c lculo de la cuota total y de la conversion a Moneda Nacional*/

					if @w_cu_dividendo_anterior != -1 
					begin
						select @w_val1 = isnull(ap_capital_val,0),
					       	@w_val2 = isnull(ap_interes_val,0),	
					       	@w_val3 = isnull(ap_mora_val,0),
					       	@w_val4 = isnull(ap_concepto4_val,0),	
					       	@w_val5 = isnull(ap_concepto5_val,0),
					       	@w_val6 = isnull(ap_concepto6_val,0),	
					       	@w_val7 = isnull(ap_concepto7_val,0),
					       	@w_fecha_dividendo = ap_fecha_vencimiento
						from ca_amortizacion_proyectada
						where ap_operacion = @w_cu_operacion_anterior and
						ap_cuota = @w_cu_dividendo_anterior
						
						select @w_suma = @w_val1+@w_val2+@w_val3+@w_val4+@w_val5+@w_val6+@w_val7
	
						select @w_cotiz = up_cotizacion 
						from ca_uvr_proyectado
						where up_fecha = @w_fecha_dividendo
					
						update ca_amortizacion_proyectada 
						set ap_valor_cuota = @w_suma,
						ap_valor_mn = @w_suma * @w_cotiz
						where ap_operacion = @w_cu_operacion_anterior and
						ap_cuota = @w_cu_dividendo_anterior		
					end

					if  @w_cu_concepto = 'CAP'
					begin
				 	  insert into ca_amortizacion_proyectada (ap_operacion,
				 	  ap_cuota,ap_dias_calculo,ap_fecha_vencimiento,ap_capital,
					  ap_capital_val)values (@w_cu_operacion,@w_cu_dividendo,
				  	  @w_cu_dias_cuota,@w_cu_fecha_ven,@w_cu_concepto,@w_cu_cuota_total)
					end 
					else if @w_cu_concepto = 'INT'
					begin
				 	  insert into ca_amortizacion_proyectada (ap_operacion,
				 	  ap_cuota,ap_dias_calculo,ap_fecha_vencimiento,ap_interes,
					  ap_interes_val)values (@w_cu_operacion,@w_cu_dividendo,
				  	  @w_cu_dias_cuota,@w_cu_fecha_ven,@w_cu_concepto,@w_cu_cuota_total)	
					end
					else if @w_cu_concepto = 'MOR'					
					begin
				 	  insert into ca_amortizacion_proyectada (ap_operacion,
				 	  ap_cuota,ap_dias_calculo,ap_fecha_vencimiento,ap_mora,
					  ap_mora_val) values (@w_cu_operacion,@w_cu_dividendo,
				  	  @w_cu_dias_cuota,@w_cu_fecha_ven,@w_cu_concepto,@w_cu_cuota_total)
					end
					else
					begin
   				 	  insert into ca_amortizacion_proyectada (ap_operacion,
				 	  ap_cuota,ap_dias_calculo,ap_fecha_vencimiento,ap_concepto4,
					  ap_concepto4_val) values (@w_cu_operacion,@w_cu_dividendo,
				  	  @w_cu_dias_cuota,@w_cu_fecha_ven,@w_cu_concepto,@w_cu_cuota_total)
					end


				end --if @w_cu_dividendo_anterior != @w_cu_dividendo
				else
				begin 


					if  @w_cu_concepto = 'CAP'
					begin
				 	  update ca_amortizacion_proyectada set ap_capital = @w_cu_concepto,
					  ap_capital_val = @w_cu_cuota_total where ap_operacion = @w_cu_operacion
					  and ap_cuota = @w_cu_dividendo
					end 
					else if @w_cu_concepto = 'INT'
					begin
				 	  update ca_amortizacion_proyectada set ap_interes = @w_cu_concepto,
					  ap_interes_val = @w_cu_cuota_total where ap_operacion = @w_cu_operacion
					  and ap_cuota = @w_cu_dividendo
					end
					else if @w_cu_concepto = 'MOR'					
					begin
				 	  update ca_amortizacion_proyectada set ap_mora = @w_cu_concepto,
					  ap_mora_val = @w_cu_cuota_total where ap_operacion = @w_cu_operacion
					  and ap_cuota = @w_cu_dividendo
					end
					else -- si es otro concepto
					begin
					  select @w_hay_valor = ap_concepto4
					  from ca_amortizacion_proyectada where ap_operacion = @w_cu_operacion
					  and ap_cuota = @w_cu_dividendo
					
					  if @w_hay_valor is null 
					  begin
 				 	    update ca_amortizacion_proyectada set ap_concepto4 = @w_cu_concepto,
					    ap_concepto4_val = @w_cu_cuota_total where ap_operacion = @w_cu_operacion
					    and ap_cuota = @w_cu_dividendo
					  end
					  else -- @w_hay_valor = null (concepto 4) 
					  begin
  					    select @w_hay_valor = ap_concepto5
	 				    from ca_amortizacion_proyectada where ap_operacion = @w_cu_operacion
					    and ap_cuota = @w_cu_dividendo
					
					    if @w_hay_valor is null 
					    begin
 				 	      update ca_amortizacion_proyectada set ap_concepto5 = @w_cu_concepto,
					      ap_concepto5_val = @w_cu_cuota_total where ap_operacion = @w_cu_operacion
					      and ap_cuota = @w_cu_dividendo					  	
					    end	
					    else -- @w_hay_valor = null (concepto 5) 
					    begin
  					      select @w_hay_valor = ap_concepto6
	 				      from ca_amortizacion_proyectada where ap_operacion = @w_cu_operacion
					      and ap_cuota = @w_cu_dividendo
					
					      if @w_hay_valor is null 
					      begin
 				 	        update ca_amortizacion_proyectada set ap_concepto6 = @w_cu_concepto,
					        ap_concepto6_val = @w_cu_cuota_total where ap_operacion = @w_cu_operacion
					        and ap_cuota = @w_cu_dividendo					  	
					      end	
					      else -- @w_hay_valor = null (concepto 6)  	
					      begin
  					        select @w_hay_valor = ap_concepto7
	 				        from ca_amortizacion_proyectada where ap_operacion = @w_cu_operacion
					        and ap_cuota = @w_cu_dividendo
					
					        if @w_hay_valor is null 
					        begin
 				 	          update ca_amortizacion_proyectada set ap_concepto7 = @w_cu_concepto,
					          ap_concepto7_val = @w_cu_cuota_total where ap_operacion = @w_cu_operacion
					          and ap_cuota = @w_cu_dividendo					  	
					        end	

					      end  -- @w_hay_valor = null (concepto 6) 	
					    
					    end -- @w_hay_valor = null (concepto 5) 

					  end -- @w_hay_valor = null (concepto 4) 

					end -- si es otro concepto
		


				end --if @w_cu_dividendo_anterior = @w_cu_dividendo

				select @w_cu_dividendo_anterior = @w_cu_dividendo
				select @w_cu_operacion_anterior = @w_cu_operacion


				fetch cursor_rubros into
				@w_cu_dividendo, @w_cu_dias_cuota,@w_cu_fecha_ven,@w_cu_concepto,
				@w_cu_cuota_total
				end ----while @@fetch_status = 0 cursor: cursor_rubros

			close cursor_rubros

			deallocate cursor_rubros


		fetch cursor_operacion into
		@w_cu_operacion,@w_cu_banco,@w_cu_toperacion,
		@w_cu_moneda, @w_cu_cliente, @w_cu_nombre


	end --while @@fetch_status = 0 cursor: cursor_operacion
	
	/*Calcula el valor de la cuota para el £ltimo registro del cursor*/


	select @w_val1 = isnull(ap_capital_val,0),
       	@w_val2 = isnull(ap_interes_val,0),	
      	@w_val3 = isnull(ap_mora_val,0),
       	@w_val4 = isnull(ap_concepto4_val,0),	
       	@w_val5 = isnull(ap_concepto5_val,0),
       	@w_val6 = isnull(ap_concepto6_val,0),	
       	@w_val7 = isnull(ap_concepto7_val,0),
       	@w_fecha_dividendo = ap_fecha_vencimiento
	from ca_amortizacion_proyectada
	where ap_operacion = @w_cu_operacion_anterior and
	ap_cuota = @w_cu_dividendo_anterior
						
	select @w_suma = @w_val1+@w_val2+@w_val3+@w_val4+@w_val5+@w_val6+@w_val7
	
	select @w_cotiz = up_cotizacion 
	from ca_uvr_proyectado
	where up_fecha = @w_fecha_dividendo
					
	update ca_amortizacion_proyectada 
	set ap_valor_cuota = @w_suma,
	ap_valor_mn = @w_suma * @w_cotiz
	where ap_operacion = @w_cu_operacion_anterior and
	ap_cuota = @w_cu_dividendo_anterior		


  close cursor_operacion

  deallocate cursor_operacion

/*  select ap_cuota, ap_dias_calculo, ap_fecha_vencimiento,
  ap_capital_val,ap_interes_val,ap_mora_val,ap_concepto4_val,
  ap_concepto5_val,ap_concepto6_val,ap_concepto7_val,
  ap_valor_cuota,ap_valor_mn
  from 
  ca_amortizacion_proyectada
  order by ap_cuota
 */

  select ap_cuota, ap_dias_calculo, ap_fecha_vencimiento,
  ap_capital_val,ap_interes_val,ap_mora_val,ap_concepto4_val,
  ap_concepto5_val,ap_concepto6_val,ap_concepto7_val,
  ap_valor_cuota,ap_valor_mn,op_nombre,op_monto_aprobado,
  op_monto,of_nombre , ci_descripcion,op_toperacion
  from ca_operacion, ca_amortizacion_proyectada,
  cobis..cl_oficina,cobis..cl_ciudad
  where op_operacion = ap_operacion
  and op_oficina = of_oficina  
  and of_filial = 1
  and ci_ciudad = of_ciudad 

  if @@rowcount = 0
  begin

	select @w_error = 710414
	goto  ERROR

  end


  
end -- if @i_operacion = 'I'

return 0

ERROR:

return @w_error

go

