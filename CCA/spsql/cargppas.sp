/***********************************************************************/
/*	Archivo:             cargppas.sp                                   */
/*	Stored procedure:		sp_carga_prepagos_pasivas                      */
/*	Base de Datos:			cob_cartera                                    */
/*	Producto:			   Cartera	                                      */
/*	Disenado por:			Elcira Pelaez                                  */
/*	Fecha de Documentacion:         Dic-2002                            */
/***********************************************************************/
/*			                    IMPORTANTE		       		              */
/*	Este programa es parte de los paquetes bancarios propiedad de       */ 	
/*	'MACOSA'.                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier autorizacion o agregado hecho por alguno de sus           */
/*	usuario sin el debido consentimiento por escrito de la              */
/*	Presidencia Ejecutiva de MACOSA o su representante	                 */
/***********************************************************************/  
/*			                         PROPOSITO				                 */
/*	Este sp carga los prepagos pasivas por cobro juridico o por         */
/*      abono voluntario del cliente                                   */
/*      Este sp es ejecutado por un sqr desde cierre diario de cartera */
/***********************************************************************/
/*                         MODIFICACIONES                              */
/*  FECHA            AUTOR       		RAZON                           */
/*								                                               */
/*  ENE-03-2002    Luis Mayorga	  Dar funcionalidad al sp             */
/*  MAY-25-2006    Elcira Pelaez    Def. 6247 Todo valor en pesos      */
/*  OCT/17/2006    Elcira Pelaez    Def 6440  La fecha aplicar nace    */
/*                                  como la fecha de migracion para que*/
/*                                  el usuario la actualice            */
/***********************************************************************/
use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_carga_prepagos_pasivas')
   drop proc sp_carga_prepagos_pasivas
go


create proc sp_carga_prepagos_pasivas
@s_user            	login      = NULL,
@s_term			varchar(30)= NULL,
@s_ofi			smallint   = NULL,  
@i_operacion            smallint,
@i_fecha_proceso  	datetime
as declare 
   @w_error          		int,
   @w_return         		int,
   @w_sp_name        		descripcion,
   @w_cod_estado_jur 		tinyint,
   @w_cod_prepago_jur 		catalogo,
   @w_cod_prepago_vol 		catalogo,
   @w_op_tramite		int,
   @w_op_margen_redescuento 	float,
   @w_saldo_capital		float,
   @w_saldo_intereses		float,
   @w_identificacion		numero,
   @w_tasa_nom			float, 
   @w_di_fecha_ini 	datetime,
   @w_dias_interes		int,
   @w_secuencial		int,	
   @w_referencial		catalogo,
   @w_signo			char(1),
   @w_puntos			money,
   @w_fpago			char(1),
   @w_tasa_mercado		varchar(10),
   @w_valor_prepago		float,
   @w_valor_prepago_vol 	float,
   @w_op_cliente		int,
   @w_op_operacion		int,
   @w_puntos_c			varchar(5),
   @w_op_banco			cuenta,
   @w_op_sector			catalogo,
   @w_tasa_pactada		varchar(50),
   @w_op_codigo_externo 	cuenta,
   @w_op_nombre			descripcion,
   @w_av_operacion_activa 	int,
   @w_op_monto			money,
   @w_op_fecha_ini		datetime,
   @w_op_moneda			tinyint,
   @w_op_oficina		smallint,
   @w_op_toperacion		catalogo,
   @w_av_secuencial_pag 	int,
   @w_fecha_hasta		datetime,
   @w_div_ven                   smallint,
   @w_div_vig                   smallint,
   @w_saldo_cap                 money,
   @w_op_dias_anio              int,
   @w_op_base_calculo           char(1),
   @w_op_periodo_int            int,
   @w_op_tdividendo 		catalogo,
   @w_num_dec_tapl		tinyint,
   @w_forma_pago_int            catalogo,
   @w_valor_calc                money,
   @w_saldo_para_cuota          money,
   @w_num_dec                   smallint,
   @w_moneda_nac                smallint,
   @w_num_dec_mn                smallint,
   @w_int                       catalogo,
   @w_av_tipo_reduccion         char(1),
   @w_av_tipo_novedad           char(1),
   @w_codigo_prepago_gral       catalogo,
   @w_cod_precancelacion        catalogo,
   @w_prepago_desde_lavigente   catalogo,
   @w_av_abono_extraordinario   char(1),
   @w_cod_prepago_icr           catalogo,
   @w_tipo_aplicacion           char(1),
   @w_dias_cuota                int,
   @w_di_fecha_ven              datetime,
   @w_op_fecha_fin              datetime,
   @w_av_dividendo_vencido      int,
   @w_procesa                   char(1),
   @w_cotizacion_hoy            money,
   @w_op_fecha_ult_proceso      datetime,
   @w_valor_prepago_vol_mn      money,
   @w_valor_prepago_mn          money,
   @w_rowcount                  int



select  @w_int = pa_char
from     cobis..cl_parametro
where   pa_nemonico = 'INT'
and     pa_producto = 'CCA'
set transaction isolation level read uncommitted


select @w_cod_estado_jur = pa_tinyint
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'ESTCJP'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted
if @w_rowcount = 0 begin
   select @w_error = 710374 --Error  'NO SE HA DEFINIDO PARAMETRO GENERAL ESTCJP'
   goto  ERROR10
end


select @w_cod_prepago_jur = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CODPJU'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted
if @w_rowcount = 0 begin
   select @w_error = 710375 --Error  'NO SE HA DEFINIDO PARAMETRO GENERAL CODPJU '
   goto ERROR10
end

if not exists (select 1 from ca_estado where es_codigo = @w_cod_estado_jur) begin
      select @w_error = 710374  --Error 'NO SE HA DEFINIDO PARAMETRO GENERAL ESTCJP'
      goto ERROR10
end


select @w_cod_prepago_vol = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CODPVO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted
if @w_rowcount = 0 begin
   select @w_error = 710376 --Error  'NO SE HA DEFINIDO PARAMETRO GENERAL CODPVO'
   goto ERROR10
end


select @w_cod_precancelacion = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CODPRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted
if @w_rowcount = 0 begin
   select @w_error = 710376 --Error  'NO SE HA DEFINIDO PARAMETRO GENERAL CODPRE'
   goto ERROR10
end


select @w_cod_prepago_icr = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COPICR'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted
if @w_rowcount = 0 begin
   select @w_error = 710376 --Error  'NO SE HA DEFINIDO PARAMETRO GENERAL COPICR'
   goto ERROR10
end


select @w_procesa = 'N'


if exists (select 1 from ca_pasivas_cobro_juridico
           where pcj_fecha     = @i_fecha_proceso)
   select @w_procesa = 'S'



if @i_operacion = 0  and @w_procesa = 'S'
begin ---  CARGA PAGOS POR PREPAGO JURIDICO 

   if exists (select 1 from ca_prepagos_pasivas
              where pp_fecha_generacion = @i_fecha_proceso
              and pp_codigo_prepago = @w_cod_prepago_jur
              and pp_estado_registro = 'I') 
   begin
      delete ca_prepagos_pasivas
      where pp_fecha_generacion = @i_fecha_proceso
      and pp_codigo_prepago     = @w_cod_prepago_jur
      and pp_estado_registro = 'I'
   end



   declare cursor_prepagos_juridico cursor  
   for select isnull(op_tramite,0),    	op_cliente,           		op_banco,           op_codigo_externo,
           op_nombre,		        isnull(op_margen_redescuento,0),op_monto,           op_fecha_ini,
           op_moneda,		        op_oficina,           		op_toperacion,      op_sector,
           op_operacion,	   	  op_dias_anio,	   		op_base_calculo,    op_periodo_int,
           op_tdividendo,          op_fecha_ult_proceso
    from  ca_operacion,
          ca_pasivas_cobro_juridico
    where pcj_operacion = op_operacion
    and   op_grupo_fact =  @w_cod_estado_jur
    and   op_naturaleza = 'P'
    and   pcj_fecha     = @i_fecha_proceso  ---Sacar solo las del dia para no duplicarlas
    and   op_estado not in (3,6,0,99)
    for read only

    open cursor_prepagos_juridico 
    fetch cursor_prepagos_juridico into
          @w_op_tramite,          	@w_op_cliente,          	@w_op_banco,        @w_op_codigo_externo,
          @w_op_nombre,  	  	@w_op_margen_redescuento,       @w_op_monto,        @w_op_fecha_ini,
          @w_op_moneda,  	        @w_op_oficina,		        @w_op_toperacion,   @w_op_sector,
          @w_op_operacion,		@w_op_dias_anio,	        @w_op_base_calculo, @w_op_periodo_int,
          @w_op_tdividendo,   @w_op_fecha_ult_proceso

    --while @@fetch_status not in (-1,0) 
    while @@fetch_status = 0
    begin


    if @w_op_margen_redescuento <= 0 
    begin
       select @w_error = 710377 -- Error 'NO SE HA DEFINIDO MARGEN DE REDESCUENTO'
       goto ERROR
    end


     if @w_op_nombre is null or @w_op_nombre = ''
     begin
        select @w_op_nombre  =  'NO EXISTE DATO EN CA_OPERACION'
     end


     if @w_op_codigo_externo is null or @w_op_codigo_externo = ''
     begin
        select @w_op_codigo_externo  =  'NO EXISTE DATO EN CA_OPERACION'
     end

 


    --- MANEJO DE DECIMALES 
    exec @w_return = sp_decimales
    @i_moneda    = @w_op_moneda,
    @o_decimales = @w_num_dec out,
    @o_mon_nacional = @w_moneda_nac out,
    @o_dec_nacional = @w_num_dec_mn out

    if @w_return <> 0 begin
       select @w_error =  @w_return
       goto ERROR
    end


     -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
      if @w_op_moneda = @w_moneda_nac
         select @w_cotizacion_hoy = 1.0
      else
      begin
         exec sp_buscar_cotizacion
              @i_moneda     = @w_op_moneda,
              @i_fecha      = @w_fecha_hasta,
              @o_cotizacion = @w_cotizacion_hoy output
      end
         

    --- SALDO_CAPITAL 
    select @w_saldo_capital = 0

    select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
    from  ca_dividendo, ca_amortizacion, ca_rubro_op
    where ro_operacion  = @w_op_operacion
    and   ro_tipo_rubro = 'C'  --Capital
    and   am_operacion  = ro_operacion
    and   am_concepto   = ro_concepto
    and   di_operacion  = ro_operacion
    and   am_dividendo  = di_dividendo
    and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
    and   am_estado     <> 3  -- Cancelado


    select @w_saldo_capital = isnull((@w_saldo_capital * @w_op_margen_redescuento)/100,0)
    select @w_valor_prepago = isnull((@w_saldo_capital * @w_op_margen_redescuento)/100,0)
    
 


    --IDENTIFICACION 
    select @w_identificacion = en_ced_ruc
    from  cobis..cl_ente 
    where en_ente = @w_op_cliente
    set transaction isolation level read uncommitted
    
    
    if @w_identificacion = '' or @w_identificacion is null
    begin
      PRINT 'cargppas.sp error aquiiiiiiiiiii'
       select @w_error = 710377 -- Error 'NO SE HA DEFINIDO MARGEN DE REDESCUENTO'
       goto ERROR
    end



    ---SALDO_INTERES 
    select @w_saldo_intereses = 0

    -- TASA NOMINAL 
    select @w_tasa_nom        = ro_porcentaje,
           @w_forma_pago_int  = ro_fpago,
           @w_num_dec_tapl    = ro_num_dec,
 	   @w_referencial     = ro_referencial,
	   @w_signo           = ro_signo,
	   @w_puntos          = convert(money,ro_factor),
	   @w_fpago           = ro_fpago
    from  ca_rubro_op
    where ro_operacion = @w_op_operacion
    and   ro_concepto  = @w_int

   
    -- DIAS DE INTERESES 
    
    select @w_di_fecha_ini = null

    select @w_div_ven = isnull((min(di_dividendo)),0)
    from  ca_dividendo
    where di_operacion = @w_op_operacion
    and   di_estado = 2 --Vencido 
    if @w_div_ven > 0  
    begin
       select @w_di_fecha_ini = min(di_fecha_ini),
              @w_dias_cuota            = sum(di_dias_cuota)
       from   ca_dividendo
       where  di_operacion = @w_op_operacion
       and    di_estado = 1
       if @@rowcount = 0  begin
          select @w_error = 710378 
          goto ERROR
       end

    end
    else 
    begin
       select @w_di_fecha_ini = di_fecha_ini,
              @w_dias_cuota   = di_dias_cuota
       from  ca_dividendo
       where di_operacion = @w_op_operacion
       and   di_estado = 1 -----Vigente
    end

    select @w_dias_interes = 0
   

    exec sp_dias_cuota_360
         @i_fecha_ini = @w_di_fecha_ini,       
         @i_fecha_fin = @i_fecha_proceso,
         @o_dias      = @w_dias_interes out   
   


    if @w_dias_interes > @w_dias_cuota
       select @w_dias_interes = @w_dias_cuota

    
    if @w_dias_interes < 0   or  @w_dias_interes is null   ---validacion cuando tiene varias cuotas adelantadas, la fecha ini 
       select @w_dias_interes = 0                          ---del div.vigente es mayor que la fecha de proceso
 


    select @w_di_fecha_ven =  di_fecha_ven
    from ca_dividendo
    where di_operacion  = @w_op_operacion
    and   di_estado     = 1 -----Vigente
    if @@rowcount = 0
       select  @w_di_fecha_ven = @w_op_fecha_fin



    ---Si el credito esta vencido solo se pagara intereses hasta la fecha de vto.
    ---Si hay cuota vigente hasta el vto. de esta
    select @w_fecha_hasta = @i_fecha_proceso
    if @i_fecha_proceso > @w_di_fecha_ven
       select @w_fecha_hasta = @w_di_fecha_ven


    -- SECUENCIAL
    exec @w_secuencial = sp_gen_sec
    @i_operacion       =  -1

    --  FORMULA TASA 

    select @w_tasa_mercado = vd_referencia
    from  ca_valor_det
    where vd_tipo = @w_referencial  --ro_referencial
    and   vd_sector = @w_op_sector  ---op_Sector

    ---Convertir los puntos a char
    select @w_puntos_c  = convert(varchar(5),@w_puntos)

    ---Concatenar la tasa para mostrar segun solicitud
    select @w_tasa_mercado = rtrim(ltrim(@w_tasa_mercado))
    select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c 


    if @w_tasa_pactada is null or @w_tasa_pactada = ''
       select @w_tasa_pactada = 'NO EXISTE DATO'


       if @w_di_fecha_ini is null  begin
          select @w_error = 710378 
          goto ERROR
       end


    ----MAYO:2006 def 6247
    ----TODOS LOS VALORES EN PESOS
    select @w_saldo_capital = round(@w_saldo_capital * @w_cotizacion_hoy, 0)
    select @w_valor_prepago_mn = round(@w_valor_prepago * @w_cotizacion_hoy, 0)


    if @w_valor_prepago > 0 
    begin
       insert into ca_prepagos_pasivas( 
       pp_secuencial,               pp_oficina,                       pp_linea,
       pp_codigo_prepago,           pp_banco,                         pp_identificacion,  pp_nombre,                                        
       pp_llave_redescuento,        pp_tramite,                       pp_cliente,
       pp_valor_prepago ,           pp_saldo_capital ,                pp_monto_desembolso,
       pp_fecha_desemboslo,         pp_saldo_intereses ,              pp_fecha_generacion ,
       pp_estado_registro,          pp_estado_aplicar ,               pp_fecha_aplicar,
       pp_moneda,
       pp_tasa,                     pp_dias_de_interes ,              pp_fecha_int_desde,
       pp_fecha_int_hasta,          pp_formula_tasa,                  pp_secuencial_ing,
       pp_tipo_reduccion,           pp_tipo_novedad,                  pp_abono_extraordinario,
       pp_tipo_aplicacion,          pp_comentario,                    pp_causal_rechazo, 
       pp_sec_pagoactiva,           pp_cotizacion)
       values(
       @w_secuencial,               @w_op_oficina,                    @w_op_toperacion,
       @w_cod_prepago_jur,          @w_op_banco,                      @w_identificacion,  @w_op_nombre,
       @w_op_codigo_externo,        @w_op_tramite,                    @w_op_cliente,
       @w_valor_prepago_mn,          @w_saldo_capital,                 @w_op_monto,
       @w_op_fecha_ini,             @w_saldo_intereses,               @i_fecha_proceso,
       'I', 			               'N',                              '03/01/2004',
       @w_op_moneda,      
       @w_tasa_nom,                 @w_dias_interes,                  @w_di_fecha_ini, 
       @w_fecha_hasta,              @w_tasa_pactada,                  0,
       'N',                         'C',                              'N',
       'D',                         null,                              null, 
       0,                           @w_cotizacion_hoy)

       if @@error <> 0 
       begin
          select @w_error = 710378 --Error 'ERROR INSERTANDO REGISTRO PREPAGOS PASIVAS JURIDICOS'	       
          goto ERROR
       end
    end


    goto SIGUIENTE


    ERROR:
    exec sp_errorlog                                             
         @i_fecha       = @i_fecha_proceso,
         @i_error       = @w_error,
         @i_usuario     = @s_user,
         @i_tran        = 7000, 
         @i_tran_name   = @w_sp_name,
         @i_rollback    = 'N',  
         @i_cuenta      = @w_op_banco,
         @i_descripcion = 'GENERACION PREPAGOS PASIVAS COBRO JURIDICO'




    SIGUIENTE:
    fetch cursor_prepagos_juridico into
          @w_op_tramite,
          @w_op_cliente,
          @w_op_banco,
          @w_op_codigo_externo,
          @w_op_nombre,
          @w_op_margen_redescuento,
          @w_op_monto,
          @w_op_fecha_ini,
          @w_op_moneda,
          @w_op_oficina,
          @w_op_toperacion,
          @w_op_sector,
          @w_op_operacion,
	       @w_op_dias_anio,
	       @w_op_base_calculo,
          @w_op_periodo_int,
          @w_op_tdividendo,
          @w_op_fecha_ult_proceso

  end  ---Cursor  cursor_prepagos_juridico
  close cursor_prepagos_juridico
  deallocate cursor_prepagos_juridico

end ---  FIN CARGA PAGOS POR PREPAGO JURIDICO 




select @w_procesa = 'N'


--- CARGA PAGOS POR ABONO VOLUNTARIO

if exists (select 1 from ca_abonos_voluntarios
           where av_fecha_pago <= @i_fecha_proceso
           and   av_estado_registro = 'I')
   select @w_procesa = 'S'


if @i_operacion = 1  and @w_procesa = 'S'
begin 

   declare cursor_prepagos_voluntarios cursor
   for 

   select isnull(op_tramite,0),                 op_cliente,           op_banco,
             op_codigo_externo,                 op_nombre,            isnull(op_margen_redescuento,0),
             op_monto,                          op_fecha_ini,         op_moneda,
             op_oficina,                        op_toperacion,        op_sector,
             av_secuencial_pag,                 av_operacion_activa,  op_operacion,
	          av_tipo_reduccion,       	         av_tipo_novedad,      av_abono_extraordinario,
             op_fecha_fin,                      av_dividendo_vencido, op_fecha_ult_proceso
    from   ca_operacion,ca_abonos_voluntarios,ca_relacion_ptmo
    where   op_operacion =  rp_pasiva
    and    rp_activa    =  av_operacion_activa  
    and    op_naturaleza = 'P'
    and    op_tipo       = 'R'
    and    av_fecha_pago <=  @i_fecha_proceso
    and    av_estado_registro = 'I'
    and    op_estado not in (3,6,0,99)
    and    op_codigo_externo <> 'NO EXISTE'

    for read only

    open cursor_prepagos_voluntarios
    fetch cursor_prepagos_voluntarios into
           @w_op_tramite,                     @w_op_cliente,         @w_op_banco,
           @w_op_codigo_externo,              @w_op_nombre,          @w_op_margen_redescuento,
           @w_op_monto,                       @w_op_fecha_ini,       @w_op_moneda,
           @w_op_oficina,                     @w_op_toperacion,      @w_op_sector,
           @w_av_secuencial_pag,              @w_av_operacion_activa,@w_op_operacion,
           @w_av_tipo_reduccion,              @w_av_tipo_novedad,    @w_av_abono_extraordinario,
           @w_op_fecha_fin,                   @w_av_dividendo_vencido, @w_op_fecha_ult_proceso
    while (@@fetch_status = 0) 
    begin
    if (@@fetch_status = -1) begin
       print 'Error en Cursor prepagos voluntarios' 
    end 


    if @w_op_margen_redescuento <= 0 begin
       select @w_error = 710377 -- Error 'NO SE HA DEFINIDO MARGEN DE REDESCUENTO'
       goto ERROR1
    end


    --- MANEJO DE DECIMALES 
    exec @w_return = sp_decimales
    @i_moneda    = @w_op_moneda,
    @o_decimales = @w_num_dec out,
    @o_mon_nacional = @w_moneda_nac out,
    @o_dec_nacional = @w_num_dec_mn out

    if @w_return <> 0 begin
       select @w_error =  @w_return
       goto ERROR1
    end


     -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
      select @w_fecha_hasta = @i_fecha_proceso
      if @w_op_moneda = @w_moneda_nac
         select @w_cotizacion_hoy = 1.0
      else
      begin
         exec sp_buscar_cotizacion
              @i_moneda     = @w_op_moneda,
              @i_fecha      = @w_fecha_hasta,
              @o_cotizacion = @w_cotizacion_hoy output
      end    

    -- SALDO_CAPITAL 
    select @w_saldo_capital = 0

    select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
    from ca_dividendo, ca_amortizacion, ca_rubro_op
    where ro_operacion  = @w_op_operacion
    and   ro_tipo_rubro = 'C'  --Capital
    and   am_operacion  = ro_operacion
    and   am_concepto   = ro_concepto
    and   di_operacion  = ro_operacion
    and   am_dividendo  = di_dividendo
    and   di_estado     in (0,1,2)  -- No Vigente y Vigente, Vencido
    and   am_estado     <> 3  -- Cancelado

    select @w_saldo_capital = isnull((@w_saldo_capital * @w_op_margen_redescuento)/100,0)
    
   
    

    if @w_av_tipo_novedad in ('I','C')  --- Debe aplicar todo el valor asi en la activa se pague en vencidos
       select @w_valor_prepago_vol = isnull(sum(ar_monto),0)
       from  ca_abono_rubro
       where ar_operacion = @w_av_operacion_activa
       and   ar_secuencial = @w_av_secuencial_pag
       and   ar_concepto = 'CAP'
    else
       select @w_valor_prepago_vol = isnull(sum(ar_monto),0)
       from  ca_abono_rubro
       where ar_operacion = @w_av_operacion_activa
       and   ar_secuencial = @w_av_secuencial_pag
       and   ar_concepto = 'CAP'
       and   ar_dividendo  > @w_av_dividendo_vencido


    if @w_av_tipo_novedad = 'C'
       select @w_valor_prepago_vol = isnull((@w_saldo_capital * @w_op_margen_redescuento)/100,0)
    else
       select @w_valor_prepago_vol = isnull((@w_valor_prepago_vol * @w_op_margen_redescuento)/100,0)       

    select @w_tipo_aplicacion = ab_tipo_aplicacion
    from ca_abono
    where ab_operacion = @w_av_operacion_activa
    and   ab_secuencial_pag = @w_av_secuencial_pag

   
    select @w_saldo_intereses = 0

    --- DIAS DE INTERESES 
    select @w_di_fecha_ini = null

    select @w_div_ven = isnull((min(di_dividendo)),0)
    from  ca_dividendo
    where di_operacion = @w_op_operacion
    and   di_estado = 2 --Vencido 

    if @w_div_ven > 0  begin
       select @w_di_fecha_ini = min(di_fecha_ini),
              @w_dias_cuota   = sum(di_dias_cuota)
       from   ca_dividendo
       where  di_operacion = @w_op_operacion
       and    di_estado = 1
       if @@rowcount = 0  begin
          select @w_error = 710378 
          goto ERROR1
       end


   end
   else 
   begin
      select @w_di_fecha_ini = di_fecha_ini,
             @w_dias_cuota   = di_dias_cuota
      from  ca_dividendo
      where di_operacion = @w_op_operacion
      and   di_estado    = 1 -----Vigente
   end

   select @w_dias_interes = 0
    
   exec sp_dias_cuota_360
        @i_fecha_ini = @w_di_fecha_ini,
        @i_fecha_fin = @i_fecha_proceso,
        @o_dias      = @w_dias_interes out
   
   if @w_dias_interes > @w_dias_cuota
      select @w_dias_interes = @w_dias_cuota
   
  
    if @w_dias_interes < 0  or @w_dias_interes is null          ---validacion cuando tiene varias cuotas adelantadas, la fecha ini 
       select @w_dias_interes = 0        ---del div.vigente es mayor que la fecha de proceso



    select @w_di_fecha_ven =  di_fecha_ven
    from ca_dividendo
    where di_operacion  = @w_op_operacion
    and   di_estado     = 1 -----Vigente
    if @@rowcount = 0
       select  @w_di_fecha_ven = @w_op_fecha_fin

    ---Si el credito esta vencido solo se pagara intereses hasta la fecha de vto.
    ---Si hay cuota vigente hasta el vto. de esta

    select @w_fecha_hasta = @i_fecha_proceso
    if @i_fecha_proceso > @w_di_fecha_ven
       select @w_fecha_hasta = @w_di_fecha_ven

    --- SECUENCIAL
    exec @w_secuencial = sp_gen_sec
    @i_operacion       =  -1

    --- IDENTIFICACION 
    select @w_identificacion = en_ced_ruc
    from  cobis..cl_ente 
    where en_ente = @w_op_cliente
    set transaction isolation level read uncommitted


    if @w_identificacion = '' or @w_identificacion is null
    begin
       select @w_error = 710377 -- Error 'NO SE HA DEFINIDO MARGEN DE REDESCUENTO'
       goto ERROR1
    end



    ---  FORMULA TASA 
    select @w_referencial = ro_referencial,
	   @w_signo       = ro_signo,
	   @w_puntos      = convert(money,ro_factor),
	   @w_fpago       = ro_fpago,
      @w_tasa_nom = ro_porcentaje
    from  ca_rubro_op,ca_operacion
    where ro_operacion = @w_op_operacion
    and   ro_concepto  = 'INT'
    and   ro_operacion = op_operacion

    select @w_tasa_mercado = vd_referencia
    from  ca_valor_det
    where vd_tipo   = @w_referencial ---ro_referencial
    and   vd_sector = @w_op_sector   ---op_Sector

    ---Convertir los puntos a char
    select @w_puntos_c  = convert(varchar(5),@w_puntos)

    ---Concatenar la tasa para mostrar segun solicitud
    select @w_tasa_mercado = rtrim(ltrim(@w_tasa_mercado))
    select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c 

     if @w_av_tipo_novedad = 'C'  ---PRECANCELACION
        select @w_codigo_prepago_gral      = @w_cod_precancelacion,
               @w_prepago_desde_lavigente  = 'N'

     if @w_av_tipo_novedad = 'A'  ---PREPAGO PARCIAL
       select @w_codigo_prepago_gral       =  @w_cod_prepago_vol,
              @w_prepago_desde_lavigente   = 'S'



     if @w_av_tipo_novedad = 'I'  ---APLICACION ICR
       select @w_codigo_prepago_gral       =  @w_cod_prepago_icr,
              @w_prepago_desde_lavigente   = 'S'

         
       if @w_di_fecha_ini is null  begin
          select @w_error = 710378 
          goto ERROR1
       end
       
    ----MAYO:2006 def 6247
    ----TODOS LOS VALORES EN PESOS
    
    select @w_saldo_capital = round(@w_saldo_capital * @w_cotizacion_hoy,0)
    select @w_valor_prepago_vol_mn = round(@w_valor_prepago_vol * @w_cotizacion_hoy,0)
        
    if @w_valor_prepago_vol_mn > 0 begin 
      
       insert into ca_prepagos_pasivas( 
       pp_secuencial,               pp_oficina,               pp_linea,
       pp_codigo_prepago,           pp_banco,                 pp_identificacion,  pp_nombre,                                        
       pp_llave_redescuento,        pp_tramite,               pp_cliente,
       pp_valor_prepago ,           pp_saldo_capital ,        pp_monto_desembolso,
       pp_fecha_desemboslo,         pp_saldo_intereses ,      pp_fecha_generacion ,
       pp_estado_registro,          pp_estado_aplicar ,       pp_fecha_aplicar,
       pp_moneda,
       pp_tasa,                     pp_dias_de_interes ,      pp_fecha_int_desde,
       pp_fecha_int_hasta,          pp_formula_tasa ,         pp_secuencial_ing,
       pp_tipo_reduccion,           pp_tipo_novedad,          pp_abono_extraordinario,
       pp_tipo_aplicacion,          pp_comentario,            pp_causal_rechazo, 
       pp_sec_pagoactiva,           pp_cotizacion)
       values(
       @w_secuencial,               @w_op_oficina,            @w_op_toperacion,
       @w_codigo_prepago_gral,      @w_op_banco,              @w_identificacion,  @w_op_nombre,
       @w_op_codigo_externo,        @w_op_tramite,            @w_op_cliente,
       @w_valor_prepago_vol_mn,     @w_saldo_capital,         @w_op_monto,
       @w_op_fecha_ini,             @w_saldo_intereses,       @i_fecha_proceso,
       'I', 			               'N',                      '03/01/2004',
       @w_op_moneda,      
       @w_tasa_nom,                 @w_dias_interes,          @w_di_fecha_ini, 
       @w_fecha_hasta,              @w_tasa_pactada,          0,
       @w_av_tipo_reduccion,        @w_av_tipo_novedad,       @w_av_abono_extraordinario,
       @w_tipo_aplicacion,          null,                     null, 
       @w_av_secuencial_pag,        @w_cotizacion_hoy)

       if @@error <> 0  begin
          select @w_error = 710378 --Error 'ERROR INSERTANDO REGISTRO PREPAGOS PASIVAS JURIDICOS'	       
          goto ERROR1
       end
    end

    --- ACTUALIZAR LA TABLA ca_abonos_voluntarios 
    update ca_abonos_voluntarios
    set av_estado_registro = 'P'
    where av_operacion_activa = @w_av_operacion_activa
    and   av_estado_registro = 'I'
    and   av_secuencial_pag = @w_av_secuencial_pag
           
    goto SIGUIENTE1

    ERROR1:
    exec sp_errorlog                                             
         @i_fecha       = @i_fecha_proceso,
         @i_error       = @w_error,
         @i_usuario     = @s_user,
         @i_tran        = 7000, 
         @i_tran_name   = @w_sp_name,
         @i_rollback    = 'N',  
         @i_cuenta      = @w_op_banco,
         @i_descripcion = 'GENERACION PREPAGOS PASIVAS ABONOS VOLUNTARIOS'

    SIGUIENTE1:
    fetch cursor_prepagos_voluntarios into
          @w_op_tramite,
          @w_op_cliente,
          @w_op_banco,
          @w_op_codigo_externo,
          @w_op_nombre,
          @w_op_margen_redescuento,
          @w_op_monto,
          @w_op_fecha_ini,
          @w_op_moneda,
          @w_op_oficina,
          @w_op_toperacion,
          @w_op_sector,
          @w_av_secuencial_pag,
          @w_av_operacion_activa,
          @w_op_operacion,
          @w_av_tipo_reduccion,
          @w_av_tipo_novedad,
          @w_av_abono_extraordinario,
          @w_op_fecha_fin,
          @w_av_dividendo_vencido,
          @w_op_fecha_ult_proceso

end  ---Cursor  cursor_prepagos_voluntarios
close cursor_prepagos_voluntarios
deallocate cursor_prepagos_voluntarios

end --- FIN CARGA PAGOS POR ABONO VOLUNTARIO

return 0


ERROR10:
exec sp_errorlog                                             
     @i_fecha       = @i_fecha_proceso,
     @i_error       = @w_error,
     @i_usuario     = @s_user,
     @i_tran        = 7000, 
     @i_tran_name   = @w_sp_name,
     @i_rollback    = 'N',  
     @i_cuenta      = @w_op_banco,
     @i_descripcion = 'GENERACION PREPAGOS PASIVAS COBRO JURIDICO Y VOLUNTARIO'

return 0




                                                                                                                                           
go


