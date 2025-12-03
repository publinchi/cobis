/***********************************************************************/
/*   Archivo                 :   prepapas.sp                          */
/*   Stored procedure        :   sp_prepagos_pasivas                  */
/*   Base de Datos           :   cob_cartera                          */
/*   Producto                :   Cartera                              */
/*   Disenado por            :   Elcira Pelaez                        */
/*   Fecha de Documentacion  :       Dic-2002                         */
/**********************************************************************/
/*                            IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de    */    
/*   "MACOSA".                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como       */
/*   cualquier autorizacion o agregado hecho por alguno de sus        */
/*   usuario sin el debido consentimiento por escrito de la           */
/*   Presidencia Ejecutiva de MACOSA o su representante               */
/**********************************************************************/  
/*                              PROPOSITO                             */
/*   Este sp permite consultar los prepagos pasivos dependiendo       */
/*      del codigo enviado por pantalla FPREPAGP.FRM                  */
/**********************************************************************/  
/*                         MODIFICACIONES                             */
/*  FECHA            AUTOR             RAZON                          */
/*  Enero 3 de 2002  Luis Mayorga   Dar funcionalidad al sp           */
/*  NOTA: PARA AUMENTAR UNA COLUMNA AL SELECT DE RETORNO AL FRONT-ENT */
/*        DE DEBE DISMINUIR EL rowcount POR QUE EL MAPEADOR NO MOSTRAR*/
/*        LA INFORMACION QUE UDs. DESEA                               */
/*  FEB/14/2005    Elcira Pelaez     Nuevo Req. 200                   */
/*  MAY-25-2006    Elcira Pelaez      Def. 6247 Todo valor en pesos   */
/*  01/07/2006:    Ivan Jimenez       Para la corrección de este      */
/*                 defecto se pidio autorización del Ing.             */
/*                  Andrés Jiménez def 6789                           */
/*  OCT/19/2006    Elcira Pelaez    Def 6440                          */
/**********************************************************************/

use cob_cartera 
go

if exists (select 1 from sysobjects where name = 'sp_prepagos_pasivas')
   drop proc sp_prepagos_pasivas
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_prepagos_pasivas
@s_user              login = null,
@s_date              datetime = null,
@t_trn               int,
@i_fecha_proceso     datetime = null,
@i_codigo_prepago    catalogo = null,
@i_fecha             datetime = null,  
@i_banco_seg_piso    catalogo = null,
@i_formato_fecha     int = 101,
@i_secuencial        int = 0
  
as declare 
@w_error                int,
@w_return               int,
@w_sp_name              descripcion,
@w_saldo_intereses      float,
@w_dias_interes         int,
@w_op_operacion         int,
@w_pp_banco             cuenta,
@w_pp_fecha_aplicar     datetime,
@w_pp_fecha_int_desde   datetime,
@w_int                  catalogo,
@w_tasa_nom             float,
@w_tasa_equivalente     float,
@w_forma_pago_int       catalogo,
@w_valor_calc           money,
@w_pp_saldo_capital     money,
@w_num_dec              smallint,
@w_moneda_nac           smallint,
@w_num_dec_mn           smallint,
@w_op_dias_anio         int,
@w_op_base_calculo      char(1),
@w_op_periodo_int       int,
@w_op_tdividendo        catalogo,
@w_num_dec_tapl         tinyint,
@w_saldo_cap            money,
@w_op_monto             money,
@w_div_vig              int,
@w_op_moneda            smallint,
@w_saldo_intereses_vencido      money,
@w_valor_prepago                money,
@w_tipo_novedad                 char(1),
@w_base_capital_int             money,
@w_div_ven                      int,
@w_di_fecha_ini                 datetime,
@w_dias_cuota                   int,
@w_op_fecha_fin                 datetime,
@w_saldo_capital                money,
@w_op_margen_redescuento        float,
@w_pp_comentario                descripcion,
@w_pp_tasa                      float,
@w_pp_dias_de_interes           int,
@w_comentario                   descripcion,
@w_param_dias_ppas              smallint,
@w_dias_diff                    int,
@w_di_fecha_ven                 datetime,
@w_codigo_todas                 catalogo,
@w_pp_codigo_prepago            catalogo,
@w_pp_secuencial                int,
@w_pp_cotizacion                float


select @w_valor_calc         = 0,
       @w_valor_prepago      = 0,
       @w_base_capital_int   = 0,
       @w_sp_name            = 'sp_prepagos_pasivas',
       @w_comentario         = 'Rechazo automatico en la consulta programa prepapas.sp',
       @w_param_dias_ppas    = 0
       

select @w_int = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_param_dias_ppas = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DIPP'
set transaction isolation level read uncommitted

select @w_codigo_todas = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'TODCAU'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

if @i_codigo_prepago = @w_codigo_todas
   select @i_codigo_prepago = null

--SELECCION DE LOS REGISTROS CON CONDICION DE BUSQUEDA PARA FUTURAS APLICACIONES
if @i_secuencial = 0
begin
   declare
      cursor_prepagos_pasivas cursor
      for select pp_banco,             pp_fecha_aplicar,    pp_fecha_int_desde,
                 pp_saldo_capital,     pp_valor_prepago, ---Valor del prepago CAP
                 pp_tipo_novedad,      pp_comentario,       pp_tasa,
                 pp_dias_de_interes,   pp_codigo_prepago,   pp_secuencial,
                 pp_cotizacion
          from   ca_prepagos_pasivas
          where  (pp_codigo_prepago  = @i_codigo_prepago or @i_codigo_prepago is null)
          and    pp_fecha_generacion = @i_fecha
          and    pp_estado_aplicar   = 'N'
          and    pp_estado_registro  = 'I'  ---No estan procesados aun
          and    substring(pp_linea,1,3) = @i_banco_seg_piso 
      for read only
   
   open cursor_prepagos_pasivas
   
   fetch cursor_prepagos_pasivas
   into  @w_pp_banco,            @w_pp_fecha_aplicar, @w_pp_fecha_int_desde,
         @w_pp_saldo_capital,    @w_valor_prepago,
         @w_tipo_novedad,        @w_pp_comentario,    @w_pp_tasa,
         @w_pp_dias_de_interes,  @w_pp_codigo_prepago, @w_pp_secuencial,
         @w_pp_cotizacion
   
   while (@@fetch_status = 0) 
   begin
      if (@@fetch_status = -1) 
      begin
         print 'Error en Cursor prepagos pasivas' 
         select @w_error = 710379 -- Crear error
         goto ERROR
      end 
      
      --DECLARAR VARIABLES 
      
      select @w_dias_diff = 0,
             @w_op_operacion  = 0,
             @w_op_dias_anio  = 0,
             @w_op_base_calculo = 'E',
             @w_op_periodo_int  = 0,
             @w_op_tdividendo     = '',
             @w_op_monto        = 0,
             @w_op_moneda       = 0,
             @w_op_fecha_fin    = '01/01/1900',
             @w_op_margen_redescuento  = 100,
             @w_saldo_intereses_vencido = 0
      
      select @w_op_operacion          = op_operacion,
             @w_op_dias_anio            = op_dias_anio,
             @w_op_base_calculo         = op_base_calculo,
             @w_op_periodo_int          = op_periodo_int,
             @w_op_tdividendo          = op_tdividendo,
             @w_op_monto                = op_monto,
             @w_op_moneda               = op_moneda,
             @w_op_fecha_fin            = op_fecha_fin,
             @w_op_margen_redescuento   = op_margen_redescuento
      from   ca_operacion
      where  op_banco = @w_pp_banco
      
      if @w_op_fecha_fin <=  @w_pp_fecha_aplicar
      begin
         update ca_prepagos_pasivas
         set    pp_estado_aplicar = 'P' ,
                pp_comentario = @w_comentario,
                pp_causal_rechazo  = '1'  
         where  pp_banco = @w_pp_banco
         and    pp_fecha_generacion = @i_fecha
         and   pp_codigo_prepago    = @w_pp_codigo_prepago
         and   pp_secuencial        = @w_pp_secuencial
         
         fetch cursor_prepagos_pasivas
         into  @w_pp_banco,            @w_pp_fecha_aplicar, @w_pp_fecha_int_desde,
               @w_pp_saldo_capital,    @w_valor_prepago,
               @w_tipo_novedad,        @w_pp_comentario,    @w_pp_tasa,
               @w_pp_dias_de_interes,  @w_pp_codigo_prepago, @w_pp_secuencial,
               @w_pp_cotizacion
         CONTINUE
      end
      
      -- MANEJO DE DECIMALES 
      exec @w_return = sp_decimales
           @i_moneda    = @w_op_moneda,
           @o_decimales = @w_num_dec out,
           @o_mon_nacional = @w_moneda_nac out,
           @o_dec_nacional = @w_num_dec_mn out
      
      if @w_return <> 0
      begin
         select @w_error =  @w_return
         goto ERROR
      end
      
      select @w_tasa_nom        = ro_porcentaje,
             @w_forma_pago_int  = ro_fpago,
             @w_num_dec_tapl    = ro_num_dec
      from  ca_rubro_op
      where ro_operacion = @w_op_operacion
      and   ro_concepto  =  @w_int
      
      -- SALDO_INTERES 
      select @w_saldo_intereses = 0
      
      select @w_saldo_intereses_vencido = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from ca_dividendo, ca_amortizacion, ca_rubro_op
      where ro_operacion    = @w_op_operacion
      and   ro_tipo_rubro   = 'I'  -- Interes
      and   am_operacion    = ro_operacion
      and   am_concepto     = ro_concepto
      and   di_operacion    = ro_operacion
      and   am_dividendo    = di_dividendo
      and   di_estado       = 2  ---Vencido
      and   am_estado       <> 3  -- Cancelado
      
      if  @w_saldo_intereses_vencido > 0  and  @w_op_fecha_fin > @w_pp_fecha_aplicar
      begin
         update ca_prepagos_pasivas
         set   pp_estado_aplicar     = 'P' ,
               pp_comentario         = @w_comentario,
               pp_causal_rechazo     = '2'
         where pp_banco            = @w_pp_banco
         and   pp_fecha_generacion = @i_fecha
         and   pp_codigo_prepago   = @w_pp_codigo_prepago
         and   pp_secuencial        = @w_pp_secuencial         

         fetch cursor_prepagos_pasivas
         into  @w_pp_banco,            @w_pp_fecha_aplicar, @w_pp_fecha_int_desde,
               @w_pp_saldo_capital,    @w_valor_prepago,
               @w_tipo_novedad,        @w_pp_comentario,    @w_pp_tasa,
               @w_pp_dias_de_interes,  @w_pp_codigo_prepago,@w_pp_secuencial,
               @w_pp_cotizacion
         
         CONTINUE
      end
      
      --VALIDACION DE LA FECHA DE VENCIMIENTO CON RESPECTO A LA IMPRESION DEL F-127
      
      if @w_tipo_novedad  <> 'I'  --Icr No hace estas validaciones
      begin
         select @w_di_fecha_ven = di_fecha_ven
         from ca_dividendo
         where di_operacion =  @w_op_operacion
         and   di_estado = 1
         
         select @w_dias_diff = datediff(dd,@w_pp_fecha_aplicar,@w_di_fecha_ven)          
         if @w_dias_diff <= @w_param_dias_ppas and @w_pp_fecha_aplicar <> '03/01/2004'
         begin
            --SE RECHAZA EL REGISTRO POR LA CAUSAL 5
            
            update ca_prepagos_pasivas
            set    pp_estado_aplicar   = 'P' ,
                   pp_comentario       =  @w_comentario,
                   pp_causal_rechazo   = '5'
            where  pp_banco          = @w_pp_banco
            and    pp_codigo_prepago = @w_pp_codigo_prepago
            and    pp_fecha_aplicar  = @w_pp_fecha_aplicar
            and    substring(pp_linea,1,3) = @i_banco_seg_piso
            and   pp_secuencial        = @w_pp_secuencial
           
            
            fetch cursor_prepagos_pasivas
            into  @w_pp_banco,            @w_pp_fecha_aplicar, @w_pp_fecha_int_desde,
                  @w_pp_saldo_capital,    @w_valor_prepago,
                  @w_tipo_novedad,        @w_pp_comentario,    @w_pp_tasa,
                  @w_pp_dias_de_interes,  @w_pp_codigo_prepago,@w_pp_secuencial,
                  @w_pp_cotizacion
            
            CONTINUE
         end
      end
      
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
      ELSE
      begin
         select @w_di_fecha_ini = di_fecha_ini,
                @w_dias_cuota   = di_dias_cuota
         from   ca_dividendo
         where  di_operacion = @w_op_operacion
         and    di_estado = 1 -----Vigente
      end
      
      select @w_dias_interes = 0
 
      if @w_pp_fecha_aplicar <> '03/01/2004'
      begin
         exec sp_dias_cuota_360
              @i_fecha_ini = @w_di_fecha_ini,
              @i_fecha_fin = @w_pp_fecha_aplicar,
              @o_dias      = @w_dias_interes out
         
         if @w_dias_interes > @w_dias_cuota
            select @w_dias_interes = @w_dias_cuota
      end
      -- NUEVO SALDO  DE CAPITAL 
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
      
      if @w_saldo_capital <= 0 
      begin
         
         update ca_prepagos_pasivas
         set    pp_estado_aplicar = 'P' ,
                pp_comentario     = @w_comentario,
                pp_causal_rechazo = '3'
         where  pp_banco            = @w_pp_banco
         and    pp_fecha_generacion = @i_fecha
         and    pp_codigo_prepago   = @w_pp_codigo_prepago
         and    substring(pp_linea,1,3) = @i_banco_seg_piso
         and   pp_secuencial        = @w_pp_secuencial         
         
         fetch cursor_prepagos_pasivas
         into  @w_pp_banco,            @w_pp_fecha_aplicar, @w_pp_fecha_int_desde,
               @w_pp_saldo_capital,    @w_valor_prepago,
               @w_tipo_novedad,        @w_pp_comentario,    @w_pp_tasa,
               @w_pp_dias_de_interes,  @w_pp_codigo_prepago,@w_pp_secuencial,
               @w_pp_cotizacion
         
         CONTINUE
      end
      
      if @w_saldo_capital < @w_valor_prepago  and @w_op_moneda = @w_moneda_nac
      begin


         
         update ca_prepagos_pasivas
         set    pp_estado_aplicar  = 'P' ,
                pp_comentario      = @w_comentario,
                pp_causal_rechazo  = '6'
         where  pp_banco         = @w_pp_banco
         and    pp_fecha_generacion = @i_fecha
         and    pp_codigo_prepago   = @w_pp_codigo_prepago
         and    substring(pp_linea,1,3) = @i_banco_seg_piso
         and   pp_secuencial        = @w_pp_secuencial         
         
         fetch cursor_prepagos_pasivas
         into  @w_pp_banco,            @w_pp_fecha_aplicar, @w_pp_fecha_int_desde,
               @w_pp_saldo_capital,    @w_valor_prepago,
               @w_tipo_novedad,        @w_pp_comentario,    @w_pp_tasa,
               @w_pp_dias_de_interes,  @w_pp_codigo_prepago,@w_pp_secuencial,
               @w_pp_cotizacion
         
         CONTINUE
      end
      
      select @w_saldo_capital = isnull((@w_saldo_capital * @w_op_margen_redescuento)/100,0)
      if @w_tipo_novedad  = 'C'
         select @w_valor_prepago = isnull((@w_saldo_capital * @w_op_margen_redescuento)/100,0)
      
      -- RECALCULO DEL INTERES PARA TASA EQUIVALENTE A LOS DIAS TRANSACURRIDOS 
      
      select @w_div_vig = isnull((min(di_dividendo)),0)
      from  ca_dividendo
      where di_operacion = @w_op_operacion
      and   di_estado = 1 --Vigente
      
      select @w_tasa_equivalente = @w_tasa_nom
      if @w_div_vig > 0 
      begin
         if @w_forma_pago_int = 'P'
            select @w_forma_pago_int = 'V'
         else
            select @w_forma_pago_int = 'A'
         
         exec @w_return =  sp_conversion_tasas_int
              @i_dias_anio      = @w_op_dias_anio,
              @i_base_calculo   = @w_op_base_calculo,
              @i_periodo_o      = @w_op_tdividendo,
              @i_modalidad_o    = @w_forma_pago_int,
              @i_num_periodo_o  = @w_op_periodo_int,
              @i_tasa_o         = @w_tasa_nom, 
              @i_periodo_d      = 'D',
              @i_modalidad_d    = 'V',
              @i_num_periodo_d  = @w_dias_interes,
              @i_num_dec        = @w_num_dec_tapl,
              @o_tasa_d         = @w_tasa_equivalente output 
         
         if @w_return <> 0
         begin
            PRINT 'carppas.sp salio por error al ejecutar sp_conversion_tasas_int'
            select @w_error =  @w_return 
            goto ERROR
         end
         
         select @w_base_capital_int = @w_saldo_capital
         if @w_tipo_novedad  <> 'C'
             select @w_base_capital_int = @w_valor_prepago
         
         if @w_dias_interes > 0
         begin
            --CUANDO A UN PREPAGO SE LE ACTUALIZA LA TASA Y LOS DIAS EL CALCULO DE INTERESES SE HACE CON 
            --LOS DATOS ACTUALIZADOS, NO SE CALCULAN EN ESTE SP
            
            if @w_pp_comentario = 'Actualizada'
               select @w_tasa_equivalente = @w_pp_tasa,
                      @w_dias_interes     = @w_pp_dias_de_interes
            
            exec @w_return = sp_calc_intereses
                 @tasa      = @w_tasa_equivalente,
                 @monto     = @w_base_capital_int,
                 @dias_anio = 360,
                 @num_dias  = @w_dias_interes,
                 @causacion = 'L', 
                 @causacion_acum = 0, 
                 @intereses = @w_valor_calc out
            
            if @w_return <> 0  
            begin
               select @w_error =  @w_return 
               goto ERROR
            end
         end
         ELSE
         begin
            if @w_dias_interes < 0
            begin
               

               
               update ca_prepagos_pasivas
               set   pp_estado_aplicar = 'P',
                     pp_comentario = @w_comentario,
                     pp_causal_rechazo  = '4'
               where pp_banco = @w_pp_banco
               and   pp_fecha_generacion = @i_fecha
               and   pp_codigo_prepago   = @w_pp_codigo_prepago
               and   substring(pp_linea,1,3) = @i_banco_seg_piso
               and   pp_secuencial        = @w_pp_secuencial               
               
               fetch cursor_prepagos_pasivas
               into  @w_pp_banco,            @w_pp_fecha_aplicar, @w_pp_fecha_int_desde,
                     @w_pp_saldo_capital,    @w_valor_prepago,
                     @w_tipo_novedad,        @w_pp_comentario,    @w_pp_tasa,
                     @w_pp_dias_de_interes,  @w_pp_codigo_prepago,@w_pp_secuencial,
                     @w_pp_cotizacion
               
               CONTINUE       
            end
         end
         
         select @w_valor_calc = round(@w_valor_calc,@w_num_dec)
         select @w_saldo_intereses =   @w_valor_calc
         select @w_tasa_nom        =  isnull(@w_tasa_equivalente,0)
      end ---Calculos para la cuota vigente
      
      --- FIN RECALCULO DEL INTERES PARA TASA EQUIVALENTE A LOS DIAS TRANSACURRIDOS 
      update ca_prepagos_pasivas
      set  pp_saldo_intereses  = round(@w_saldo_intereses * @w_pp_cotizacion ,0),
           pp_saldo_capital    = round(@w_saldo_capital   * @w_pp_cotizacion,0),
           pp_fecha_int_desde  = @w_di_fecha_ini,
           pp_fecha_int_hasta  = @w_pp_fecha_aplicar,
           pp_dias_de_interes  = @w_dias_interes,
           pp_tasa             = @w_tasa_equivalente,
           pp_valor_prepago    = round(@w_valor_prepago,0)
      where pp_banco = @w_pp_banco
      and   pp_estado_aplicar = 'N'
      and   pp_estado_registro = 'I'
      and   pp_fecha_generacion = @i_fecha
      and   pp_codigo_prepago = @w_pp_codigo_prepago
      and   substring(pp_linea,1,3) = @i_banco_seg_piso 
      and   pp_secuencial           = @w_pp_secuencial      
      
      if @@error <> 0
      begin
         select @w_error = 710380 --Error 'ERROR ACTUALIZANDO REGISTRO PREPAGOS PASIVAS JURIDICOS'          
         goto ERROR
      end
      
      fetch cursor_prepagos_pasivas
      into  @w_pp_banco,            @w_pp_fecha_aplicar, @w_pp_fecha_int_desde,
            @w_pp_saldo_capital,    @w_valor_prepago,
            @w_tipo_novedad,        @w_pp_comentario,    @w_pp_tasa,
            @w_pp_dias_de_interes,  @w_pp_codigo_prepago,@w_pp_secuencial,
            @w_pp_cotizacion
   end  ---Cursor  cursor_prepagos_pasivas
   
   close cursor_prepagos_pasivas
   deallocate cursor_prepagos_pasivas
end --secuencial = 0


-- ENVIO DE DATOS AL FRONT-END 
  
   set rowcount 10
   select 
    'Oficina'             =  pp_oficina,
    'Llave Redesuento'    =  pp_llave_redescuento,
    'No. Obligacion'      =  pp_banco,
    'Beneficiario'        =  substring(pp_nombre,1,25),
    'Identificacion'      =  substring(pp_identificacion,1,18),
    'Saldo Capital'       =  pp_saldo_capital,
    'Fecha Int. desde'    =  convert (varchar(10), pp_fecha_int_desde,@i_formato_fecha),
    'Fecha Int. aplicar'  =  convert (varchar(10), pp_fecha_int_hasta,@i_formato_fecha),
    'Dias'                =  pp_dias_de_interes,
    'Formula Tasa'        =  substring(pp_formula_tasa,1,15),
    'Tasa'                =  pp_tasa,
    'Valor Capital'       =  pp_valor_prepago,
    'Valor Interes'       =  pp_saldo_intereses,
    'Valor Pago'          =  (pp_saldo_intereses + pp_valor_prepago),
    'Causal'              =  pp_codigo_prepago,
    'Sec'                 =  pp_secuencial,
    'Comentario'          =  substring(pp_comentario,1,15),
    'Cotizacion'          =  pp_cotizacion
   from ca_prepagos_pasivas
   where  pp_fecha_generacion     = @i_fecha
   and    (pp_codigo_prepago       = @i_codigo_prepago or @i_codigo_prepago is null)
   and    substring(pp_linea,1,3) = @i_banco_seg_piso 
   and    pp_secuencial           > @i_secuencial
   and    pp_estado_aplicar       = 'N' 
   and    pp_estado_registro      = 'I'
   order by pp_secuencial
   set rowcount 0
 
return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug  = 'N',    
   @t_file   =  null,
   @t_from   =  @w_sp_name,
   @i_num    =  @w_error
   return   @w_error


                                                                                                                                                                                                                                  
go
