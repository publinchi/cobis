/******************************************************************/
/*  Archivo:            repestcta.sp                              */
/*  Stored procedure:   sp_reporte_estado_cuenta                  */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 19-Jul-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Generar la informaci¢n para el reporte de Estado de Cuenta */
/*     Grupal                                                     */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR           RAZON                      */
/*  19/Jul/19        Lorena Regalado   Genera informacion         */
/*                                     para reporte de Estado     */
/*                                     de cuenta                  */
/******************************************************************/


USE cob_cartera
go

IF OBJECT_ID ('dbo.sp_reporte_estado_cuenta') IS NOT NULL
	DROP PROCEDURE dbo.sp_reporte_estado_cuenta
GO

create proc sp_reporte_estado_cuenta
   @s_filial           int          = 1,
   @t_trn              int          = 77516,
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_banco            varchar(15),
   @i_tipo             char(1)             --'C'(Cabecera), 'D'(Detalle)

 
as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_monto                money,
   @w_cliente              int,
   @w_mensaje              varchar(255),
   @w_rol_act              varchar(10),
   @w_oficial              smallint,
   @w_plazo_op             smallint,
   @w_plazo                smallint,
   @w_tipo_seguro          varchar(10), 
   @w_monto_seguro         money, 
   @w_fecha_inicial        datetime,
   @w_fecha_desemb         datetime,
   @w_operacion            int,
   @w_cotizacion_hoy       money,
   @w_rowcount		   int,
   @w_moneda_nacional      tinyint,
   @w_num_dec              tinyint,
   @w_ssn                  int,
   @w_op_forma_pago        catalogo,
   @w_secuencial           int,
   @w_return               int,
   @w_commit               char(1),
   @w_monto_desembolso     money,
   @w_tipo_orden           catalogo,
   @w_banco                catalogo,
   @w_numero_acreditado    int,
   @w_fecha_ing            datetime,
   @w_tasa_anual_fija      varchar(10),
   @w_tasa_int             float,
   @w_nemonico_int         catalogo,
   @w_simbolo              varchar(10),
   @w_monto_moneda         varchar(20),
   @w_sucursal             varchar(30),
   @w_fecha_ini            datetime,
   @w_moneda               tinyint,
   @w_ciclo                smallint,
   @w_monto_pagar          money,
   @w_nombre_acreditado    varchar(30),
   @w_monto_pagar_moneda   varchar(30),
   @w_nro_cuenta           cuenta,
   @w_nro_credito          cuenta,
   @w_frecuencia           catalogo,
   @w_periodicidad_pago    varchar(30),
   @w_nemonico_cap         catalogo,
   @w_nemonico_ivaint      catalogo,
   @w_plazo_frecuencia     varchar(30),
   @w_promotor             varchar(30),
   @w_reca                 varchar(30),
   @w_tipo_operacion       catalogo,
   @w_tipo_tramite         catalogo,
   @w_desc_frecuencia      varchar(30),
   @w_nemonico_comdes      catalogo,
   @w_nemonico_ivacod      catalogo,
   @w_nemonico_imo         catalogo,
   @w_tabla_amor           money,
   @w_tasa_imo             float,
   @w_desc_filial          varchar(30),
   @w_fecha_emision        datetime,
   @w_fecha_corte          datetime,
   @w_saldo_insoluto       money,
   @w_int_ordinario        money,
   @w_monto_iva            money,
   @w_monto_otros_cargos   money,
   @w_monto_periodo_actual money,
   @w_destino              varchar(30),
   @w_periodo_liq          datetime,
   @w_com_apertura         varchar(20),
   @w_monto_com            varchar(30),
   @w_cat                  float,
   @w_cat_desc             varchar(30),
   @w_cargos_objetados     money,
   @w_desc_moneda          varchar(30),
   @w_pago_otros           money,
   @w_sec_pago             int,
   @w_pago_cap             money,
   @w_pago_int             money,
   @w_pago_ivaint          money,
   @w_pago_imo             money,
   @w_nemonico_cmo         catalogo,
   @w_credito_interc       money,
   @w_credito_came         money,
   @w_interes_came         money,
   @w_interes_interc       money,
   @w_ivainteres_total     money,
   @w_moratorios_total     money,
   @w_otros_total          money,
   @w_total_amortiza       money,
   @w_credito_interc_pag   money,
   @w_credito_came_pag     money,
   @w_interes_came_pag     money,
   @w_interes_interc_pag   money,
   @w_ivainteres_total_pag money,
   @w_otros_total_pag      money,
   @w_total_amortiza_pag   money,
   @w_cant_pagos           int,
   @w_cant_pagos_interc    int,
   @w_moratorios_total_pag money,
   @w_saldo_cred_interc    money,
   @w_saldo_int_interc     money,
   @w_saldo_cred_came      money,
   @w_saldo_int_came       money,
   @w_saldo_ivaint         money,
   @w_saldo_otros          money,
   @w_saldo_moratorios     money,
   @w_saldo_total          money,
   @w_folio                varchar(20)


--OBTIENE NEMONICO DEL INT
select @w_nemonico_int = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INT'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end


--OBTIENE NEMONICO DEL CAP
select @w_nemonico_cap = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CAP'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end


--OBTIENE NEMONICO DEL IVAINT
select @w_nemonico_ivaint = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'IVAINT'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end



--OBTIENE NEMONICO DEL COMDES
select @w_nemonico_comdes = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMDES'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end


--OBTIENE NEMONICO DEL IVACOMDES
select @w_nemonico_ivacod = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'IVACOD'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end


--OBTIENE NEMONICO DEL IMO
select @w_nemonico_imo = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'IMO'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end


--OBTIENE NEMONICO DEL CMO
select @w_nemonico_cmo = pa_char 
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'NCMO'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end


select @w_folio = ' '


if @i_banco is not NULL
begin

    if not exists (select 1 from cob_cartera..ca_operacion
                  where op_banco = @i_banco
	  	    and op_grupal = 'S'
                    and op_admin_individual = 'N'
		    and op_estado not in (0,99,3))
    begin
       select @w_error = 70203
       goto   ERROR
       --return @w_error
    end
end


-----------------------------------------------------------
--Operacion para devolver datos de la cabecera del reporte
-----------------------------------------------------------

if @i_tipo = 'C'    --Cabecera del Estado de Cuenta
begin


   --Filial
   select @w_desc_filial = fi_nombre from 
   cobis..cl_filial
   where fi_filial = @s_filial

   select 
           @w_operacion                 = op_operacion,
           @w_nro_cuenta    		= op_grupo,--PQ enviar número de grupo isnull(op_cuenta, 'NA'),
           @w_fecha_emision 		= (select fp_fecha from cobis..ba_fecha_proceso), --@s_date,
           @w_nombre_acreditado 	= isnull((select gr_nombre 
                              			from cobis..cl_grupo
                              			where gr_grupo  = x.op_grupo), 'NA'),
           @w_fecha_corte  		= (select fp_fecha from cobis..ba_fecha_proceso),
           @w_numero_acreditado        	= isnull(op_grupo, 0),
 	   @w_saldo_insoluto            = (select isnull(sum(am_cuota),0) + isnull(sum(am_gracia),0) - isnull(sum(am_pagado),0)
					    from cob_cartera..ca_amortizacion
        		                    where am_operacion = x.op_operacion),
           @w_fecha_ini                 = op_fecha_ini,                                        --Fecha del credito
           @w_monto_pagar               = isnull(op_monto,0),                                  --Monto a pagar Capital
           @w_monto                     = isnull(op_monto,0),                                  --Monto del Credito
	   @w_int_ordinario             = (select isnull(sum(am_cuota),0)
					    from cob_cartera..ca_amortizacion
        		                    where am_operacion = x.op_operacion
                                             and  am_concepto  = @w_nemonico_int),
           @w_tasa_int     		=  (select isnull(ro_porcentaje, 0) from cob_cartera..ca_rubro_op
                                 	    where  ro_operacion = x.op_operacion
                                 	     and   ro_concepto  = @w_nemonico_int),
           @w_monto_iva		        = isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               			  where am_operacion = x.op_operacion
		                                   and  am_concepto  = @w_nemonico_ivaint),0),  
           @w_tasa_imo                  = (select isnull(ro_porcentaje, 0) from cob_cartera..ca_rubro_op
                                 	    where  ro_operacion = x.op_operacion
                                 	     and   ro_concepto  = @w_nemonico_imo),
           @w_monto_otros_cargos        =  (select isnull(sum(am_cuota),0)
					    from cob_cartera..ca_amortizacion
        		                    where am_operacion = x.op_operacion
                                             and  am_concepto  not in (@w_nemonico_cap,@w_nemonico_int,@w_nemonico_ivaint)),
           @w_tabla_amor                = (select isnull(sum(am_cuota),0) 
					    from cob_cartera..ca_amortizacion
        		                    where am_operacion = x.op_operacion),
           @w_plazo        		= isnull(op_plazo, 0),
           @w_frecuencia   		= isnull(op_tdividendo,'NA'),
	   @w_monto_periodo_actual      = (select isnull(sum(am_cuota),0) + isnull(sum(am_gracia),0) - isnull(sum(am_pagado),0)
					    from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
        		                    where am_operacion = x.op_operacion
                                             and  di_operacion = x.op_operacion
                                             and  am_operacion = di_operacion
                                             and  am_dividendo = di_dividendo
                                             and  di_estado in (1,2)),
           @w_destino 			= (select b.valor from cobis..cl_tabla a, cobis..cl_catalogo b
					   where a.tabla = 'cr_destino'
   					    and   a.codigo = b.tabla
					    and   b.codigo = x.op_destino),
           @w_periodo_liq               = (select fp_fecha from cobis..ba_fecha_proceso), 
           @w_com_apertura              = 'No Aplica', 
           @w_monto_com                 = 'No aplica comisi¢n',
           @w_cat                       = op_valor_cat,
           @w_nro_credito  		= isnull(op_banco,'NA'),
           /*@w_monto_pagar  		= isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                              		  where am_operacion = x.op_operacion), 0),*/
           @w_promotor     		= isnull((select fu_nombre from cobis..cc_oficial, cobis..cl_funcionario
                              		  where oc_oficial = x.op_oficial
                              		   and  oc_funcionario = fu_funcionario), 'NA'),
           @w_tipo_operacion 		= isnull(op_toperacion, 'NA'),
           @w_moneda         		= isnull(op_moneda, 0),
 	   @w_sucursal       		= (select of_nombre from cobis..cl_oficina
                               		   where of_oficina = x.op_oficina),
           @w_tipo_tramite   		= isnull((select tr_tipo from cob_credito..cr_tramite where tr_tramite = x.op_tramite), 'NA')
    from cob_cartera..ca_operacion x
    where op_banco = @i_banco


   --Obtener la Descripcion de la Frecuencia
   if @w_plazo = 1
   begin
        execute sp_desc_frecuencia
        @i_tipo          =    'S',
        @i_tdividendo    =    @w_frecuencia,
        @o_frecuencia    =    @w_desc_frecuencia out
 
   end
   else
   begin
        execute sp_desc_frecuencia
        @i_tipo          =    'P',
        @i_tdividendo    =    @w_frecuencia,
        @o_frecuencia    =    @w_desc_frecuencia out
 
   end



    select @w_simbolo     = mo_simbolo,
           @w_desc_moneda = mo_descripcion 
    from cobis..cl_moneda
    where mo_moneda = @w_moneda


    select @w_plazo_frecuencia   = cast(@w_plazo as varchar) + ' ' + @w_desc_frecuencia
    select @w_cat_desc           = cast(@w_cat as varchar) + ' ' +  '%' + 'SIN IVA'
    select @w_cargos_objetados   = 0

  --Resumen del ultimo pago de amortizacion
  select  @w_sec_pago = max(ab_secuencial_pag)
  from cob_cartera..ca_abono
  where ab_operacion = @w_operacion
   and  ab_estado    not in ('NA','RV', 'E')

  select @w_sec_pago = isnull(@w_sec_pago,0)
  if @w_sec_pago > 0
  begin

	select @w_pago_cap = sum(dtr_monto) 
        from ca_transaccion, ca_det_trn x
	where tr_operacion = @w_operacion
	and   tr_tran      = 'PAG'
	and   tr_secuencial = @w_sec_pago
	and   tr_operacion = dtr_operacion
	and   tr_secuencial= dtr_secuencial
	and   dtr_concepto = @w_nemonico_cap

	select @w_pago_int = sum(dtr_monto) 
        from ca_transaccion, ca_det_trn x
	where tr_operacion = @w_operacion
	and   tr_tran      = 'PAG'
	and   tr_secuencial = @w_sec_pago
	and   tr_operacion = dtr_operacion
	and   tr_secuencial= dtr_secuencial
	and   dtr_concepto = @w_nemonico_int

	select @w_pago_ivaint = sum(dtr_monto) 
        from ca_transaccion, ca_det_trn x
	where tr_operacion = @w_operacion
	and   tr_tran      = 'PAG'
	and   tr_secuencial = @w_sec_pago
	and   tr_operacion = dtr_operacion
	and   tr_secuencial= dtr_secuencial
	and   dtr_concepto = @w_nemonico_ivaint

        select @w_pago_imo = sum(dtr_monto) 
        from ca_transaccion, ca_det_trn x
	where tr_operacion = @w_operacion
	and   tr_tran      = 'PAG'
	and   tr_secuencial = @w_sec_pago
	and   tr_operacion = dtr_operacion
	and   tr_secuencial= dtr_secuencial
	and   dtr_concepto = @w_nemonico_imo

        select @w_pago_otros = sum(dtr_monto) 
        from ca_transaccion, ca_det_trn x
	where tr_operacion = @w_operacion
	and   tr_tran      = 'PAG'
	and   tr_secuencial = @w_sec_pago
	and   tr_operacion = dtr_operacion
	and   tr_secuencial= dtr_secuencial
        and   dtr_concepto <> 'VAC0'
	and   dtr_concepto not in (@w_nemonico_cap,@w_nemonico_int, @w_nemonico_ivaint,@w_nemonico_imo)

     
  end

  --DEVUELVE DATOS DE LA CABECERA AL FE
  select                --1
           @w_nro_cuenta as 'NumeroCuenta',
           @w_fecha_emision as 'FechaEmision', 
           @w_nombre_acreditado as 'NombreAcreditado', 
           @w_fecha_corte as 'FechaCorte',
           @w_numero_acreditado as 'NumeroAcreditado', 
 	   @w_saldo_insoluto as 'SaldoInsoluto',   --Saldo Insoluto del Credito
           @w_fecha_ini as 'FechaCredito',        --Fecha de Credito
           @w_monto_pagar as 'MontoPagarCapital',      --Monto a Pagar Capital
           @w_monto       as 'MontoCredito',            --Monto del credito
	   @w_int_ordinario as 'InteresOrdinario',    --Interes Ordinario
           @w_tasa_int   as 'TasaInteresOrd',         --Tasa de interes Ordinario anual
           @w_monto_iva as 'Iva',        --IVA
           @w_tasa_imo as 'TasaInteresMoratorio',         --Tasa de interes moratorio
           @w_monto_otros_cargos as 'MontoOtrosCargos', --Monto Otros Cargos
           @w_tabla_amor as 'TotalAmortizacion',       --Total Amortizacion
           @w_plazo_frecuencia as 'Plazo', --Plazo
	   @w_monto_periodo_actual as 'MontoPagarPeriodo', --Monto a pagar del periodo
           @w_destino as 'Destino',              --Destino
           @w_periodo_liq as 'PeriodoLiquidacion',          --Periodo de Liquidacion
           @w_com_apertura as 'ComisionApetura',         --Comision por apertura
           @w_monto_com as 'MontoComision',            --Monto Comision
           @w_cat_desc as 'Cat',             --CAT
           @w_cargos_objetados as 'CargosObjetados',     --Cargos objetados
           @w_nro_credito as 'NroCredito',          
           @w_promotor as 'Promotor',             --Promotor
           isnull(@w_simbolo,'NA') as 'SimboloMoneda', 
           @w_tipo_operacion as 'TipoOperacion',       --Tipo de operacion
           isnull(@w_sucursal, 'NA') as 'Sucursal', --Sucursal
           @w_desc_moneda as 'DescMoneda',
           isnull(@w_pago_cap,0) as 'PagoCapital',     --Pagos a capital
           isnull(@w_pago_int,0) as 'PagoInteres',     --Pago a interes
           isnull(@w_pago_ivaint,0) as 'PagoIva',  --Pago Iva
           isnull(@w_pago_imo,0) as 'PagoInteresMoratorio',     --Pagos de interes moratorio
           isnull(@w_pago_otros,0) as 'PagoOtros'    --Pago Otros
          
           



end 

--------------------------------------
--Detalle de la tabla de amortizacion
--------------------------------------

if @i_tipo = 'D'
begin

if @i_banco is NULL
begin
      select @w_error = 70203
      goto ERROR

end
/**************************************************************************/
--GUARDA INFORMACION DE LOS INTERCICLOS RELACIONADOS A LA OPERACION GRUPAL
/**************************************************************************/

select op_operacion as op, di_dividendo as divi, di_fecha_ven as fechaven,

       (select case when x.di_dividendo = 1 then
	                              (select sum(am_cuota) from cob_cartera..ca_amortizacion
        		               where am_operacion = x.di_operacion
                        	        and  am_concepto  = @w_nemonico_cap)
                                      else
                                      (select sum(am_cuota) from cob_cartera..ca_amortizacion
        		               where am_operacion = x.di_operacion
                        	        and  am_concepto  = @w_nemonico_cap
                             		and  am_dividendo > x.di_dividendo - 1)
                                       end) as saldoInsoluto,

      (select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_int) as interes,

      isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_ivaint),0) as ivaint,  
             
       (select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_cap) as capital,
      (select isnull(sum(am_cuota),0) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_cmo) as cmo,       

      (select isnull(sum(am_cuota),0) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  in (select y.codigo from cobis..cl_tabla x, cobis..cl_catalogo y
						      where x.tabla = 'ca_rubros_moratorios'
						      and   x.codigo = y.tabla)) as moratorios, 

      (select sum(isnull(am_cuota,0)) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  not in (select b.codigo from cobis..cl_tabla a, cobis..cl_catalogo b
						      where a.tabla = 'ca_rubros_moratorios'
						      and   a.codigo = b.tabla)
                                and  am_concepto  not in (@w_nemonico_cap, @w_nemonico_int, @w_nemonico_ivaint, @w_nemonico_cmo)) as otros,

       (select sum(isnull(am_cuota,0)) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo) as total

into #interciclos
from cob_cartera..ca_det_ciclo, cob_cartera..ca_operacion a, cob_cartera..ca_dividendo x
where dc_referencia_grupal = @i_banco
and   dc_operacion = op_operacion              --estoy filtrando por cada op interciclo
and   op_estado not in (0, 99,3)
and   dc_tciclo = 'I'
and   op_operacion = di_operacion


/****************************************************************/
/*OBTIENE EL DETALLE DE LA TABLA DE AMORTIZACION POR CADA CUOTA */
/*SUMANDO A LO ANTERIOR LOS INTERCICLOS                         */
/****************************************************************/


select op_operacion,
       'Amortiza  '       as origen,
        di_estado as estadoDiv,
       (select case when x.di_estado in (0,1) then 'Por Vencer' else ' ' end ) as situacion, 
       di_dividendo as numpago,
       di_fecha_ven as fechaven,
       (select case when x.di_dividendo = 1 then
	                              (select sum(am_cuota) from cob_cartera..ca_amortizacion
        		               where am_operacion = x.di_operacion
                        	        and  am_concepto  = @w_nemonico_cap)
                                      else
                                      (select sum(am_cuota) from cob_cartera..ca_amortizacion
        		               where am_operacion = x.di_operacion
                        	        and  am_concepto  = @w_nemonico_cap
                             		and  am_dividendo > x.di_dividendo - 1)
                                       end) as saldoInsoluto,

	(select isnull(sum(saldoInsoluto),0) from #interciclos
         where fechaven = x.di_fecha_ven) as saldoInsolutoInterc,

        (select isnull(sum(capital),0) from #interciclos
         where fechaven = x.di_fecha_ven) as AmortizaInterc,

        isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_cap),0) as AmortizCame,

        isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_int),0) as InteresCame,

        (isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_int),0)  + 
        (select isnull(sum(interes),0) from #interciclos
         where fechaven = x.di_fecha_ven)) as InteresTotal,   --Interes Came + Interes Interciclo
        
        (isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_ivaint),0)  +  --Interes Came
        (select isnull(sum(ivaint),0) from #interciclos
         where fechaven = x.di_fecha_ven)) as IvaInteresTotal,   --InteresIva Came + InteresIva Interciclo


        (isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  = @w_nemonico_cmo),0) +
        (select isnull(sum(cmo),0) from #interciclos
         where fechaven = x.di_fecha_ven)) as CmoTotal,   --CMO Came + CMO Interciclo

        (isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  in (select y.codigo from cobis..cl_tabla x, cobis..cl_catalogo y
						      where x.tabla = 'ca_rubros_moratorios'
						      and   x.codigo = y.tabla)),0) +
        (select isnull(sum(moratorios),0) from #interciclos
         where fechaven = x.di_fecha_ven)) as Rubmoratorios,   

 
        (isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo
                                and  am_concepto  not in (select b.codigo from cobis..cl_tabla a, cobis..cl_catalogo b
						      where a.tabla = 'ca_rubros_moratorios'
						      and   a.codigo = b.tabla)
                                and  am_concepto  not in (@w_nemonico_cap,@w_nemonico_int,@w_nemonico_ivaint,@w_nemonico_cmo)),0) +
        (select isnull(sum(otros),0) from #interciclos
         where fechaven = x.di_fecha_ven)) as OtrosTotal,


        (isnull((select sum(am_cuota) from cob_cartera..ca_amortizacion
                               where am_operacion = x.di_operacion
                                and  am_dividendo = x.di_dividendo),0) +
        (select isnull(sum(total),0) from #interciclos
         where fechaven = x.di_fecha_ven)) as Total,


        ' '       as Esquema,
        @w_folio  as Folio,
        ' '  as Localidad,
        0    as SaldoPago
into #ValoresTabla
from  cob_cartera..ca_operacion a, cob_cartera..ca_dividendo x
where op_banco     = @i_banco
and   op_operacion = di_operacion


--select * from #ValoresTabla
/*************************************************************/
/*GUARDA LOS PAGOS APLICADOS A LAS OPERACIONES DE INTERCICLO */
/*************************************************************/

select op_operacion as op, di_dividendo as divi, di_fecha_ven as fechaven,

      (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_int) as interes,

      (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_ivaint) as ivaint,  
             
       (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_cap) as capital,

      (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_cmo) as cmo,       

      (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto in (select y.codigo from cobis..cl_tabla x, cobis..cl_catalogo y
						      where x.tabla = 'ca_rubros_moratorios'
						      and   x.codigo = y.tabla)) as moratorios, 

       (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   dtr_concepto  not in (select b.codigo from cobis..cl_tabla a, cobis..cl_catalogo b
				   where a.tabla = 'ca_rubros_moratorios'
				   and   a.codigo = b.tabla)
       and   tr_estado     <> 'RV'
       and   dtr_concepto not in (@w_nemonico_cap, @w_nemonico_int, @w_nemonico_ivaint, @w_nemonico_cmo)) as otros,

       (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV') as total

into #pagos_interciclos
from cob_cartera..ca_det_ciclo, cob_cartera..ca_operacion a, cob_cartera..ca_dividendo x
where dc_referencia_grupal = @i_banco
and   dc_operacion = op_operacion              --estoy filtrando por cada op interciclo
and   op_estado not in (0, 99,3)
and   dc_tciclo = 'I'
and   op_operacion = di_operacion


/****************************************/
--GENERA INFORMACION PAGOS MAS INTERCICLOS
/****************************************/
--Inserta primer bloque de los dividendos que no han tenido pagos
--Une luego segundo bloque de los dividendos con pagos.

insert #ValoresTabla
select op_operacion,
       'Pagos'        as origen,                      --Texto para orden en presentacion de datos
       di_estado as estadoDiv,

       (select case when x.di_estado = 2 then 'Pagado - Mora'
                    when x.di_estado = 3 then 'Pagado' else ' ' end ) as situacion, 
       
       di_dividendo as numpago,
       di_fecha_ven as fechaven,
       0 as saldoInsoluto,
       0 as saldoInsolutoInterc,

      (select isnull(sum(capital),0) from #pagos_interciclos
         where fechaven = x.di_fecha_ven) as AmortizaInterc,

      (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_cap) as AmortizCame,   

      (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_int) as InteresCame,

     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_int)  +     
      (select isnull(sum(interes),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as InteresTotal,   --Interes Came + Interes Interciclo

     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_ivaint) +
      (select isnull(sum(ivaint),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as IvaInteresTotal,   --InteresIva Came + InteresIva Interciclo


     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_cmo) +
      (select isnull(sum(cmo),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as CmoTotal,   --CMO Came + CMO Interciclo

     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  in (select y.codigo from cobis..cl_tabla x, cobis..cl_catalogo y
						      where x.tabla = 'ca_rubros_moratorios'
						      and   x.codigo = y.tabla)) +
      (select isnull(sum(moratorios),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as Rubmoratorios,   --Rubros Moratorios


     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_concepto <> 'VAC0'
       and   dtr_dividendo = x.di_dividendo
       and   dtr_concepto  not in (select b.codigo from cobis..cl_tabla a, cobis..cl_catalogo b
				   where a.tabla = 'ca_rubros_moratorios'
				   and   a.codigo = b.tabla)
       and   tr_estado     <> 'RV'
       and   dtr_concepto  not in (@w_nemonico_cap,@w_nemonico_int,@w_nemonico_ivaint,@w_nemonico_cmo)) +

     (select isnull(sum(otros),0) from #pagos_interciclos
      where fechaven = x.di_fecha_ven)) as OtrosTotal,


     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_concepto <> 'VAC0'
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV')    +

      (select isnull(sum(total),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as Total,

        ' ' as Esquema,
        ' '  as Folio,
        ' '  as Localidad,
        0    as SaldoPago
from  cob_cartera..ca_operacion a, cob_cartera..ca_dividendo x
where op_banco     = @i_banco
and   op_operacion = di_operacion
and   di_dividendo not in (select dtr_dividendo from ca_transaccion,ca_det_trn
                               where tr_operacion = a.op_operacion
                                and tr_tran = 'PAG' and tr_estado <> 'RV'
                                and tr_operacion = dtr_operacion
                                and tr_secuencial = dtr_secuencial)

UNION
select op_operacion,
       'Pagos'        as origen,
        di_estado     as estadoDiv,

       (select case when (x.di_estado = 2 and y.tr_fecha_ref > x.di_fecha_ven ) then 'Pagado - Mora' 
                    when (x.di_estado = 3 and y.tr_fecha_ref > x.di_fecha_ven ) then 'Pagado - Mora'
                    when (x.di_estado = 3 and y.tr_fecha_ref <= x.di_fecha_ven) then 'Pagado' 
                    else ' ' 
                    end ) as situacion, 

        
       di_dividendo as numpago,
       tr_fecha_ref as fechaven,       --Fecha del Pago
       0 as saldoInsoluto,
       0 as saldoInsolutoInterc,

      (select isnull(sum(capital),0) from #pagos_interciclos
         where fechaven = x.di_fecha_ven) as AmortizaInterc,

      (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_cap) as AmortizCame,

      (select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_int) as InteresCame,

     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_int)  +     
      (select isnull(sum(interes),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as InteresTotal,   --Interes Came + Interes Interciclo

     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_ivaint) +
      (select isnull(sum(ivaint),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as IvaInteresTotal,   --InteresIva Came + InteresIva Interciclo


     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  = @w_nemonico_cmo) +
      (select isnull(sum(cmo),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as CmoTotal,   --CMO Came + CMO Interciclo

     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV'
       and   dtr_concepto  in (select y.codigo from cobis..cl_tabla x, cobis..cl_catalogo y
						      where x.tabla = 'ca_rubros_moratorios'
						      and   x.codigo = y.tabla)) +
      (select isnull(sum(moratorios),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as Rubmoratorios,   --Rubros Moratorios


     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_concepto <> 'VAC0'
       and   dtr_dividendo = x.di_dividendo
       and   dtr_concepto  not in (select b.codigo from cobis..cl_tabla a, cobis..cl_catalogo b
				   where a.tabla = 'ca_rubros_moratorios'
				   and   a.codigo = b.tabla)
       and   tr_estado     <> 'RV'
       and   dtr_concepto  not in (@w_nemonico_cap,@w_nemonico_int,@w_nemonico_ivaint,@w_nemonico_cmo)) +

     (select isnull(sum(otros),0) from #pagos_interciclos
      where fechaven = x.di_fecha_ven)) as OtrosTotal,


     ((select isnull(sum(dtr_monto),0)
       from ca_transaccion, ca_det_trn z
      where tr_operacion = a.op_operacion
       and   tr_tran      = 'PAG'
       and   tr_operacion = dtr_operacion
       and   tr_secuencial = dtr_secuencial
       and   dtr_concepto <> 'VAC0'
       and   dtr_dividendo = x.di_dividendo
       and   tr_estado     <> 'RV')    +

      (select isnull(sum(total),0) from #pagos_interciclos
       where fechaven = x.di_fecha_ven)) as Total,

      (select case when m.cp_canal = 'OFI' then 'C'
       else 'B' end ) as Esquema,

        ' '  as Folio,
        ' '  as Localidad,
 
       ((select sum(amh_cuota + amh_gracia + amh_pagado)               --Historia antes del pago
        from cob_cartera..ca_amortizacion_his
        where amh_operacion = a.op_operacion
           and  amh_secuencial = y.tr_secuencial
           and  amh_dividendo = x.di_dividendo ) -

       (select isnull(sum(dtr_monto),0)                                  --MOnto del Pago
       from cob_cartera..ca_det_trn
       where dtr_operacion  = a.op_operacion
         and dtr_secuencial = y.tr_secuencial
         and dtr_dividendo  = x.di_dividendo )) as SaldoPago 


from  cob_cartera..ca_operacion a, cob_cartera..ca_dividendo x, ca_transaccion y, cob_cartera..ca_abono b, cob_cartera..ca_abono_det z, cob_cartera..ca_producto m
where op_banco     = @i_banco
and   op_operacion = di_operacion
and   tr_operacion = op_operacion
and   tr_tran = 'PAG'
and   tr_estado <> 'RV'
and   op_operacion = ab_operacion
and   ab_secuencial_pag = tr_secuencial
and   ab_operacion = abd_operacion
and   ab_secuencial_ing = abd_secuencial_ing
and   abd_concepto   = cp_producto
and   di_dividendo in (select dtr_dividendo from ca_transaccion,ca_det_trn
                               where tr_operacion = a.op_operacion
                                and tr_tran = 'PAG' and tr_estado <> 'RV'
                                and tr_operacion = dtr_operacion
                                and tr_secuencial = y.tr_secuencial
                                and tr_secuencial = dtr_secuencial)



/************************/
--DETALLE DEL REPORTE
/************************/
--DEVUELVE LOS VALORES DEL DETALLE DEL ESTADO DE CUENTA
select
op_operacion as 'Operacion',
origen       as 'Origen',
estadoDiv    as 'EstadoDividendo',
(select case when p.origen = 'Pagos' and situacion = 'Pagado - Mora' and p.SaldoPago > 0 then p.situacion + ' ' +'Saldo: ' + cast(p.SaldoPago as varchar)
                    else p.situacion end) as 'Situacion',
numpago        as 'NumPago',
fechaven       as 'FechaVenc',
saldoInsoluto  as 'SaldoInsolutoCreditoCame',
saldoInsolutoInterc as 'SaldoInsolutoInterc',
AmortizaInterc as 'AmortizaInterc',
AmortizCame    as 'AmortizaCame',
InteresCame    as 'InteresCame',
InteresTotal   as 'InteresTotal',
IvaInteresTotal as 'IvaInteresTotal',
CmoTotal as 'CmoTotal',
Rubmoratorios as 'RubMoratorios',
OtrosTotal as 'OtrosTotal',
Total as 'Total',
Esquema as 'Esquema',
Folio as 'Folio',
Localidad as 'Localidad'
into #ValoresTablaFinal
from #ValoresTabla p
--order by op_operacion,numpago, origen, fechaven


select 
Operacion,
Origen,
EstadoDividendo,
Situacion,
NumPago,
FechaVenc,
SaldoInsolutoCreditoCame,
SaldoInsolutoInterc,
AmortizaInterc,
AmortizaCame,
InteresCame,
InteresTotal,
IvaInteresTotal,
CmoTotal,
RubMoratorios,
OtrosTotal,
Total,
Esquema,
Folio,
Localidad  

from #ValoresTablaFinal
order by Operacion, NumPago, Origen, FechaVenc

/************************/
--RESUMEN DEL REPORTE
/************************/

select @w_credito_interc = isnull(sum(capital),0),
       @w_interes_interc = isnull(sum(interes),0)
from #interciclos


select @w_credito_came     = isnull(sum(AmortizCame),0),
       @w_interes_came     = isnull(sum(InteresCame),0),
       @w_ivainteres_total = isnull(sum(IvaInteresTotal),0),
       @w_moratorios_total = isnull(sum(Rubmoratorios),0),
       @w_otros_total      = isnull(sum(OtrosTotal),0),
       @w_moratorios_total = isnull(sum(Rubmoratorios),0),
       @w_total_amortiza   = isnull(sum(Total),0) 
from #ValoresTabla
where origen = 'Amortiza'

select @w_cant_pagos = count(*) 
from  cob_cartera..ca_operacion, cob_cartera..ca_transaccion
where op_banco     = @i_banco
 and  op_operacion = tr_operacion
 and  tr_tran      = 'PAG' 
 and  tr_tran      <> 'RV'

--VALORES PAGADOS

select @w_credito_interc_pag = isnull(sum(capital),0),
       @w_interes_interc_pag = isnull(sum(interes),0)
from #pagos_interciclos


select @w_credito_came_pag = isnull(sum(AmortizCame),0),
       @w_interes_came_pag = isnull(sum(InteresCame),0),
       @w_ivainteres_total_pag = isnull(sum(IvaInteresTotal),0),
       @w_otros_total_pag = isnull(sum(OtrosTotal),0),
       @w_moratorios_total_pag = isnull(sum(Rubmoratorios),0),
       @w_total_amortiza_pag = isnull(sum(Total),0) 
from #ValoresTabla
where situacion = 'Pagos'

select @w_cant_pagos_interc = count(*) 
from cob_cartera..ca_det_ciclo, cob_cartera..ca_operacion a, ca_transaccion
where dc_referencia_grupal = @i_banco
and   dc_operacion = op_operacion              
and   op_estado not in (0, 99,3)
and   dc_tciclo = 'I'
and   op_operacion = tr_operacion
and   tr_tran      = 'PAG'
and   tr_estado    <> 'RV'


--SALDOS

select @w_saldo_cred_interc = @w_credito_interc - @w_credito_interc_pag,
       @w_saldo_int_interc  = @w_interes_interc - @w_interes_interc_pag,
       @w_saldo_cred_came   = @w_credito_came   - @w_credito_came_pag,
       @w_saldo_int_came    = @w_interes_came - @w_interes_came_pag,
       @w_saldo_ivaint      = @w_ivainteres_total - @w_ivainteres_total_pag,
       @w_saldo_otros       = @w_otros_total - @w_otros_total_pag,
       @w_saldo_moratorios  = @w_moratorios_total - @w_moratorios_total_pag,
       @w_saldo_total       = @w_total_amortiza - @w_total_amortiza_pag
       

select 
       @w_credito_interc,       --1
       @w_credito_came,
       @w_interes_came,
       @w_interes_interc,
       @w_ivainteres_total,     --5
       @w_moratorios_total,
       @w_otros_total,
       @w_total_amortiza,
       @w_cant_pagos,
       @w_credito_interc_pag,  --10
       @w_credito_came_pag,
       @w_interes_came_pag,
       @w_interes_interc_pag,
       @w_ivainteres_total_pag,
       @w_moratorios_total_pag, --15
       @w_otros_total_pag,
       @w_total_amortiza_pag,
       @w_cant_pagos_interc,
       @w_saldo_cred_interc, 
       @w_saldo_int_interc,    --20
       @w_saldo_cred_came, 
       @w_saldo_int_came, 
       @w_saldo_ivaint, 
       @w_saldo_otros, 
       @w_saldo_moratorios,   --25
       @w_saldo_total      



       
end





return 0

ERROR:

   exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error,
    @i_msg    = @w_mensaje,
    @i_sev    = 0
   
     return @w_error
  

GO

