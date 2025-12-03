/**************************************************************************/
/*   Archivo:                 ppasconp.sp                                 */
/*   Stored procedure:        sp_prepas_consolidacion_pas                 */
/*   Base de Datos:           cob_cartera                                 */
/*   Producto:                Cartera                                     */
/*   Disenado por:            Elcira Pelaez                               */
/*   Fecha de Documentacion:  Ene-2002                                    */
/**************************************************************************/
/*                             IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de        */    
/*   "MACOSA".                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como           */
/*   cualquier autorizacion o agregado hecho por alguno de sus            */
/*   usuario sin el debido consentimiento por escrito de la               */
/*   Presidencia Ejecutiva de MACOSA o su representante                   */
/**************************************************************************/  
/*                            PROPOSITO                                   */
/*   Este sp carga los prepagos pasivas por consolidacion de pasivos      */
/*      desde credito codigo de prepgao 24                                */
/**************************************************************************/
/*                         MODIFICACIONES                                 */
/*  FECHA          AUTOR             RAZON                                */
/*  MAY-25-2006    Elcira Pelaez    Def. 6247 Todo valor en pesos         */
/*  OCT/17/2006    Elcira Pelaez    Def 6440  La fecha aplicar nace       */
/*                                  como la fecha de migracion para que   */
/*                                  el usuario la actualice               */
/**************************************************************************/
use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_prepas_consolidacion_pas')
   drop proc sp_prepas_consolidacion_pas
go

create proc sp_prepas_consolidacion_pas
@s_sesn                   int        = NULL,
@s_user               login      = NULL,
@s_term         varchar(30)= NULL,
@s_date         datetime   = NULL,
@s_ofi         smallint   = NULL,  
@i_fecha_proceso     datetime,
@i_op_banco_pasiva      cuenta     

as declare 
   @w_error                int,
   @w_return               int,
   @w_sp_name              descripcion,
   @w_cod_prepago_consol    catalogo,
   @w_op_tramite      int,
   @w_op_margen_redescuento    float,
   @w_saldo_capital      float,
   @w_saldo_intereses      float,
   @w_identificacion      numero,
   @w_tasa_nom         float, 
   @w_di_fecha_ini    datetime,
   @w_dias_interes      int,
   @w_secuencial      int,   
   @w_referencial      catalogo,
   @w_signo         char(1),
   @w_puntos         float,
   @w_fpago         char(1),
   @w_tasa_mercado      varchar(10),
   @w_valor_prepago      float,
   @w_valor_prepago_vol    float,
   @w_op_cliente      int,
   @w_op_operacion      int,
   @w_puntos_c         varchar(5),
   @w_op_banco         cuenta,
   @w_op_sector         catalogo,
   @w_tasa_pactada      varchar(50),
   @w_op_codigo_externo    cuenta,
   @w_op_nombre         descripcion,
   @w_op_monto         money,
   @w_op_fecha_ini      datetime,
   @w_op_moneda         tinyint,
   @w_op_oficina      smallint,
   @w_op_toperacion      catalogo,
   @w_fecha_hasta      datetime,
   @w_op_fecha_ult_proceso      datetime,
   @w_div_ven                   smallint,
   @w_div_vig                   smallint,
   @w_dias_cuota                int,
   @w_cotizacion_hoy            float,
   @w_num_dec                   smallint,
   @w_moneda_nac                smallint,
   @w_num_dec_mn                smallint,
   @w_rowcount                  int



select @w_cod_prepago_consol = pa_char
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CODPCO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 710394 --Error  'NO SE HA DEFINIDO PARAMETRO GENERAL CODPCO '
   return @w_error
end


  select   
 @w_op_cliente             = op_cliente,
 @w_op_banco               = op_banco,
 @w_op_codigo_externo      = op_codigo_externo,
 @w_op_nombre              = op_nombre,
 @w_op_margen_redescuento  = isnull(op_margen_redescuento,0),
 @w_op_monto               = op_monto,
 @w_op_fecha_ini           = op_fecha_ini,
 @w_op_moneda              = op_moneda,
 @w_op_oficina             = op_oficina,
 @w_op_toperacion          = op_toperacion,
 @w_op_fecha_ult_proceso   = op_fecha_ult_proceso,
 @w_op_sector              = op_sector,
 @w_op_operacion           = op_operacion,
 @w_op_tramite             = op_tramite
 from  ca_operacion
 where  op_banco   = @i_op_banco_pasiva        
 and op_naturaleza = 'P'

    if @@rowcount = 0 begin
       select @w_error = 710391
       return @w_error
    end 



   --- MANEJO DE DECIMALES 
    exec @w_return = sp_decimales
    @i_moneda    = @w_op_moneda,
    @o_decimales = @w_num_dec out,
    @o_mon_nacional = @w_moneda_nac out,
    @o_dec_nacional = @w_num_dec_mn out

    if @w_return <> 0 begin
       select @w_error =  @w_return
       return @w_error
    end

     -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
      if @w_op_moneda = @w_moneda_nac
         select @w_cotizacion_hoy = 1.0
      else
      begin
         exec sp_buscar_cotizacion
              @i_moneda     = @w_op_moneda,
              @i_fecha      = @i_fecha_proceso,
              @o_cotizacion = @w_cotizacion_hoy output
      end





    if @w_op_margen_redescuento <= 0 
    begin
       select @w_error = 710377 -- Error 'NO SE HA DEFINIDO MARGEN DE REDESCUENTO'
       return @w_error
    end


    --- SALDO_CAPITAL 
    select @w_saldo_capital = 0

    select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
    from   ca_amortizacion, ca_rubro_op
    where ro_operacion  = @w_op_operacion
    and   ro_tipo_rubro = 'C'  --Capital
    and   am_operacion  = ro_operacion
    and   am_concepto   = ro_concepto
    and   am_estado     <> 3  -- Cancelado


    select @w_valor_prepago = isnull((@w_saldo_capital * @w_op_margen_redescuento)/100,0)
    if @w_valor_prepago <= 0 
       PRINT 'ppasconp.sp --> ATENCION!!! en valor del prepago es 0 no se genera registro  para prepago'

   
    ---SALDO_INTERES 
    select @w_saldo_intereses = 0

    select @w_saldo_intereses = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
    from  ca_dividendo, ca_amortizacion, ca_rubro_op
    where ro_operacion  = @w_op_operacion
    and   ro_tipo_rubro = 'I'  -- Interes
    and   am_operacion  = ro_operacion
    and   am_concepto   = ro_concepto
    and   di_operacion  = ro_operacion
    and   am_dividendo  = di_dividendo
    and   di_estado     in (1,2)  --  Vigente, Vencido
    and   am_estado     <> 3  -- Cancelado

    ---IDENTIFICACION
    select @w_identificacion = en_ced_ruc
    from  cobis..cl_ente 
    where en_ente = @w_op_cliente
    set transaction isolation level read uncommitted

    --- TASA NOMINAL 
    select @w_tasa_nom = ro_porcentaje
    from  ca_rubro_op
    where ro_operacion = @w_op_operacion
    and   ro_concepto  = 'INT'


       -- DIAS DE INTERESES
       select @w_dias_interes = 0
       

       select @w_div_ven = isnull((min(di_dividendo)),0)
       from   ca_dividendo
       where  di_operacion = @w_op_operacion
       and    di_estado = 2 --Vencido 
       
       if @w_div_ven > 0
       begin
          select @w_di_fecha_ini = min(di_fecha_ini),
                 @w_dias_cuota   = sum(di_dias_cuota)
          from   ca_dividendo
          where  di_operacion = @w_op_operacion
          and    di_estado in (1, 2) --Vencido y vigente
       end
       else
       begin
          select @w_di_fecha_ini = di_fecha_ini,
                 @w_dias_cuota   = di_dias_cuota
          from   ca_dividendo
          where  di_operacion = @w_op_operacion
          and    di_estado = 1 -----Vigente
       end
       
       select @w_dias_interes = 0
       
       exec sp_dias_cuota_360
            @i_fecha_ini = @w_di_fecha_ini,
            @i_fecha_fin = @w_op_fecha_ult_proceso,
            @o_dias      = @w_dias_interes out
       
       if @w_dias_interes > @w_dias_cuota
          select @w_dias_interes = @w_dias_cuota



    ---SECUENCIAL
    exec @w_secuencial = sp_gen_sec
    @i_operacion   = -1

    select @w_fecha_hasta = @w_op_fecha_ult_proceso

    --- FORMULA TASA 
    select @w_referencial = ro_referencial,
      @w_signo       = ro_signo,
      @w_puntos      = ro_factor,
      @w_fpago       = ro_fpago
    from  ca_rubro_op,ca_operacion
    where ro_operacion = @w_op_operacion
    and   ro_concepto  = 'INT'
    and   ro_operacion = op_operacion

    select @w_tasa_mercado = vd_referencia
    from  ca_valor_det
    where vd_tipo = @w_referencial  --ro_referencial
    and   vd_sector = @w_op_sector  ---op_Sector

    ---Convertir los puntos a char
    select @w_puntos_c  = substring(convert(varchar(50),@w_puntos),1,5)

    ---Concatenar la tasa para mostrar segun solicitud
    select @w_tasa_mercado = rtrim(ltrim(@w_tasa_mercado))
    select @w_tasa_pactada = @w_tasa_mercado + '' + @w_signo + '' + @w_puntos_c 

    if @w_valor_prepago > 0 begin

       if exists (select 1 from ca_prepagos_pasivas
          where pp_banco = @w_op_banco 
          and   pp_codigo_prepago   = @w_cod_prepago_consol
          and   pp_estado_registro  = 'I'
          and   pp_fecha_generacion = @i_fecha_proceso)
       begin
          delete ca_prepagos_pasivas
          where pp_banco = @w_op_banco 
          and   pp_codigo_prepago   = @w_cod_prepago_consol
          and   pp_estado_registro  = 'I'
          and   pp_fecha_generacion = @i_fecha_proceso
       end



       ----MAYO:2006 def 6247
       ----TODOS LOS VALORES EN PESOS
       
       select @w_saldo_capital = round(@w_saldo_capital * @w_cotizacion_hoy,@w_num_dec)
       select @w_valor_prepago = round(@w_valor_prepago * @w_cotizacion_hoy,@w_num_dec)
       select @w_saldo_intereses = round(@w_saldo_intereses * @w_cotizacion_hoy,@w_num_dec)

       

       insert into ca_prepagos_pasivas( 
       pp_secuencial,               pp_oficina,               pp_linea,
       pp_codigo_prepago,           pp_banco,                 pp_identificacion,  pp_nombre,                                        
       pp_llave_redescuento,        pp_tramite,               pp_cliente,
       pp_valor_prepago ,           pp_saldo_capital ,        pp_monto_desembolso,
       pp_fecha_desemboslo,         pp_saldo_intereses ,      pp_fecha_generacion ,
       pp_estado_registro,          pp_estado_aplicar ,       pp_fecha_aplicar,
       pp_moneda,
       pp_tasa,                     pp_dias_de_interes ,      pp_fecha_int_desde,
       pp_fecha_int_hasta,          pp_formula_tasa,          pp_secuencial_ing,
       pp_tipo_reduccion,           pp_tipo_novedad,          pp_abono_extraordinario,
       pp_tipo_aplicacion,          pp_comentario,            pp_causal_rechazo, 
       pp_sec_pagoactiva,           pp_cotizacion
       )
       values
       (
       @w_secuencial,               @w_op_oficina,            @w_op_toperacion,
       @w_cod_prepago_consol,       @w_op_banco,              @w_identificacion,  @w_op_nombre,
       @w_op_codigo_externo,        @w_op_tramite,            @w_op_cliente,
       @w_valor_prepago,            @w_saldo_capital,         @w_op_monto,
       @w_op_fecha_ini,             @w_saldo_intereses,       @i_fecha_proceso,
       'I',                         'N',                      '03/01/2004',
       @w_op_moneda,      
       @w_tasa_nom,                 @w_dias_interes,          @w_di_fecha_ini, 
       @w_fecha_hasta,              @w_tasa_pactada,           0,
       'N',                         'C' ,                     'N',
       'D',                         null,                       null,
       0,                           @w_cotizacion_hoy
       )
       if @@error <> 0 begin
          select @w_error = 710392
          return @w_error
       end
    end


return 0

go