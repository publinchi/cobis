/************************************************************************/
/*	Nombre Fisico:		  reintant.sp				                    */
/*	Nombre Logico:	   	  sp_revisar_pago_ant	      	                */
/*	Base de datos:		  cob_cartera			 	                    */
/*	Producto: 		      Cartera					                    */
/*	Disenado por:  		  Elcira Pelaez Burbano			                */
/*	Fecha de escritura:	  Agosto/06/2001 				                */
/************************************************************************/
/*				                  IMPORTANTE				            */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/*				                 PROPOSITO				                */
/*	Procedimiento que revisa el abono si es de INTANT para hacer        */
/*      las respectivas modificaciones a la tabla de amortizacion       */
/*      y ca_amortizacion_ant.					                        */
/*      @i_modo = 1 (despues de aplicar el abono)			            */
/*                 Este modo revisa si se cancelo en dividendo vigente  */
/*                 lee inf. de ca_control_intant, si hay cancelacion    */
/*                 se hace la insercion total de la amortizacion por    */
/*                 el valor pendiente, y actualiza ca_amortizacion_ant  */
/*			                 MODIFICACIONES					            */
/*	FEB-14-2002		RRB	      Agregar campos al insert	                */
/*					               en ca_transaccion		            */
/************************************************************************/
/*			                 MODIFICACIONES					            */
/* MAR-17-2004    EPB         Actualizaciones para el BAC               */
/* Este sp ya no aplica para el BAC, decidieron que ya no se causara    */
/* a diario, por este motivo, se actualizaron lo sprocesos para generar */
/* en el mosmo pago una sola transaccion AMO por el valor pagado        */
/* este programa era llmado por el ingaboin.ps y por el abonoca, tambien*/
/* el de pagos no aplicados, todas estas llamadas se quitaron para      */
/* mejorar tiempos en cvista de no ser utilizado                        */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_revisar_pago_ant')
	drop proc sp_revisar_pago_ant
go

create proc sp_revisar_pago_ant
   @s_user  	        login,
   @s_term	        varchar(30),
   @s_date	        datetime,
   @s_ofi	        smallint,
   @i_operacionca      int,
   @i_secuencial_ing   int       = null,
   @i_secuencial_pag   int       = 0,
   @i_concepto         catalogo  = null,
   @i_modo             char(1)   = null,
   @i_dias_anio        int       = null,
   @i_monto            money     = null,
   @i_fecha_proceso    datetime  = null,
   @i_moneda           smallint  = null,
   @i_causacion        char(1)   = null,
   @i_toperacion       catalogo = null, 
   @i_banco            cuenta   = null, 
   @i_gerente          int      = null, 
   @i_gar_admisible    char(1)  = null,
   @i_tipo_pago        char(1)  = null,
   @i_oficina          int  = null

as declare
   @w_error             int,
   @w_return            int,
   @w_sp_name           descripcion,
   @w_vencido           money,
   @w_vigente           money,
   @w_monto_pag         money,
   @w_est_novigente     tinyint,
   @w_est_vigente       tinyint,
   @w_est_cancelado     tinyint,
   @w_est_vencido       tinyint,
   @w_dividendo_vig     int,
   @w_valor_calc        money,
   @w_am_secuencial     smallint,
   @w_num_dec           tinyint,
   @w_dias_recalcular   int,
   @w_secuencial_pag    int,
   @w_dtr_monto         money,
   @w_am_cuota          money,
   @w_am_acumulado      money,
   @w_tasa_intant       float,
   @w_dias_acumulados   int,
   @w_fecha_pago        datetime,
   @w_porcentaje_nom    float,
   @w_porcentaje_efa    float,
   @w_saldo_cap_ven     money,
   @w_monto_cap         money,
   @w_valor_proy_pagado money,
   @w_tasa_recalculo    float,
   @w_saldo_para_cuota  money,
   @w_dias_pagados      int,
   @w_dias_cuota        int,
   @w_dias_faltan       int,
   @w_am_secuencia      int,
   @w_dias_ant          int,
   @w_di_fecha_ini      datetime,
   @w_valor_pagado      money,
   @w_di_fecha_ven      datetime,
   @w_tasa_dia          float,
   @w_valor_cuota       money,
   @w_an_valor_pagado   money,
   @w_di_dias_cuota     int,
   @w_vencido1          money,
   @w_secuencial        int,
   @w_tipo_garantia     smallint,
   @w_codvalor          int,
   @w_estado            smallint,
   @w_valor_amortizar   money,
   @w_sobrante          money,
   @w_fin_amortizacion  char(1),
   @w_acumulado_total   money,
   @w_estado_op         smallint,
   @w_gar_admisible	char(1),   
   @w_reestructuracion	char(1),   
   @w_calificacion	catalogo,   
   @w_moneda_nac	smallint,  
   @w_num_dec_mn	smallint,  
   @w_monto_mn		money,     
   @w_cot_mn		money,     
   @w_valor_vencido_acum money,    
   @w_valor_traslado     money,	   
   @w_parametro_tramo    catalogo, 
   @w_concepto_tramo     catalogo, 
   @w_tipo               char(1)   


select  @w_sp_name        = 'sp_revisar_pago_ant',
@w_est_novigente    = 0,
@w_est_vigente      = 1,
@w_est_cancelado    = 3,
@w_est_vencido      = 2,
@w_am_secuencial    = 0,
@w_tipo_garantia    = 0,
@w_acumulado_total  = 0,
@w_vigente          = 0,
@w_monto_mn         = 0




/* MANEJO DE DECIMALES PARA LA MONEDA DE LA OPERACION */
exec @w_return  = sp_decimales
@i_moneda       = @i_moneda,
@o_decimales    = @w_num_dec out,
@o_mon_nacional = @w_moneda_nac out,
@o_dec_nacional = @w_num_dec_mn out

if @w_return <> 0 return @w_return


select 
   @w_porcentaje_nom = ro_porcentaje,
   @w_porcentaje_efa = ro_porcentaje_efa
from ca_rubro_op
where ro_operacion = @i_operacionca
and ro_concepto  = @i_concepto

select 
   @w_gar_admisible    = op_gar_admisible, 	
   @w_reestructuracion = op_reestructuracion,	
   @w_calificacion	    = op_calificacion 		
from ca_operacion
where op_operacion = @i_operacionca


select @w_tasa_recalculo = @w_porcentaje_nom


if @i_modo = '1'  begin

   select
      @w_secuencial_pag = con_secuencia_pag,
      @w_dividendo_vig = con_dividendo,
      @w_di_fecha_ini  = con_fecha_ini,
      @w_di_fecha_ven  = con_fecha_ven,
      @w_dtr_monto     = con_valor_pagado,
      @w_dias_cuota    = con_dias_cuota,
      @w_am_secuencial = con_am_sec
   from ca_control_intant
   where con_operacion = @i_operacionca
   and con_secuencia_pag = @i_secuencial_pag
   if @@rowcount > 0 begin

	---PRINT 'reintant.sp  encontro datos en la tabla ca_control_intant  valor' + @w_dtr_monto
 
      select @w_estado = di_estado
      from ca_dividendo
      where di_operacion = @i_operacionca
      and di_dividendo = @w_dividendo_vig

      if @i_gar_admisible = 'S'
      select @w_tipo_garantia = 1  --admisible



      if @w_estado = @w_est_cancelado   
      begin

         --GENERAR UN SOLO VALOR DE AMORTIZACION
      
         select @w_valor_amortizar = isnull(sum(am_cuota - am_acumulado),0)
         from ca_amortizacion
         where am_operacion = @i_operacionca
         and am_dividendo = @w_dividendo_vig
         and am_concepto = @i_concepto
         and am_secuencia = @w_am_secuencial
 

         exec @w_secuencial = sp_gen_sec
         @i_operacion  = @i_operacionca

         select @w_codvalor = co_codigo * 1000 + @w_est_cancelado * 10 + @w_tipo_garantia
         from  ca_concepto
         where co_concepto    = @i_concepto
         if @@rowcount = 0  return 710252


         insert into ca_transaccion (
            tr_secuencial,     tr_fecha_mov,  tr_toperacion,
            tr_moneda,         tr_operacion,  tr_tran,
            tr_en_linea,       tr_banco,      tr_dias_calc,
            tr_ofi_oper,       tr_ofi_usu,    tr_usuario,
            tr_terminal,       tr_fecha_ref,  tr_secuencial_ref,
            tr_estado,	       tr_gerente,    tr_gar_admisible,	
   	      tr_reestructuracion,tr_calificacion, tr_observacion, 	
   	      tr_fecha_cont,	    tr_comprobante)
        values (
            @w_secuencial,     @s_date,         @i_toperacion,
            @i_moneda,         @i_operacionca,    'AMO',
            'S',               @i_banco,        1,
            @i_oficina,        @s_ofi,          @s_user,
            @s_term,           @i_fecha_proceso,0,
            'ING',	          @i_gerente ,     isnull(@w_gar_admisible,''),	
          	 isnull(@w_reestructuracion,''),isnull(@w_calificacion,''),'',    	
         	 @s_date,	    0)
             if @@error != 0 
             return 708165



         --COTIZACION MONEDA 

         exec @w_return = sp_conversion_moneda
         @s_date             = @s_date,
         @i_opcion           = 'L',
         @i_moneda_monto     = @i_moneda,
         @i_moneda_resultado = @w_moneda_nac,
         @i_monto	     = @w_valor_amortizar,
         @i_fecha            = @i_fecha_proceso, 
         @o_monto_resultado  = @w_monto_mn out,
         @o_tipo_cambio      = @w_cot_mn out

         if @w_return  != 0 return @w_return 

        select @w_monto_mn = round(@w_monto_mn,@w_num_dec_mn) 

        insert into ca_det_trn (
        dtr_secuencial, dtr_operacion,    dtr_dividendo,
        dtr_concepto,
        dtr_estado,     dtr_periodo,      dtr_codvalor,
        dtr_monto,      dtr_monto_mn,     dtr_moneda,
        dtr_cotizacion, dtr_tcotizacion,  dtr_afectacion,
        dtr_cuenta,     dtr_beneficiario, dtr_monto_cont )
        values (
        @w_secuencial,  @i_operacionca,   0,
        @i_concepto,
        0,              0,                @w_codvalor,
        @w_valor_amortizar,   @w_monto_mn,          @i_moneda,   ---EPB:feb-21-2002
        @w_cot_mn,              'N',              'D',           ---EPB:feb-21-2002
        '',             '',               0 )
        if @@error != 0 return 708166


        update ca_amortizacion set
        am_acumulado  = am_cuota
        where  am_operacion = @i_operacionca
        and    am_dividendo = @w_dividendo_vig
        and    am_concepto  = @i_concepto
        and    am_secuencia = @w_am_secuencial
        if @@error != 0 
           return 705050


        if exists (select 1 from ca_amortizacion_ant
                   where an_operacion = @i_operacionca
                   and an_dividendo = @w_dividendo_vig
                   and an_estado = @w_est_vigente
                   and an_secuencial = @w_secuencial_pag
                   and an_secuencia = @w_am_secuencial)  
        begin
        update ca_amortizacion_ant
        set an_estado =  @w_est_cancelado,
            an_valor_amortizado = an_valor_pagado,
            an_dias_amortizados = an_dias_pagados 
        where an_operacion = @i_operacionca
        and an_dividendo  = @w_dividendo_vig
        and an_estado     = @w_est_vigente
        and an_secuencial = @w_secuencial_pag
        and an_secuencia  = @w_am_secuencial

        end --ACTUALIZAR ca_amortizacion_ant
        -- LA FECHA DE LA OPERACION SE ACTUALIZA
        ---update ca_operacion
        ---set op_fecha_ult_proceso = @w_di_fecha_ven
        ---where op_operacion = @i_operacionca

        select @w_estado_op = op_estado
        from ca_operacion
        where op_operacion = @i_operacionca
        if @w_estado_op = @w_est_cancelado begin

           update ca_amortizacion set 
           am_estado = @w_est_cancelado,
           am_acumulado = am_cuota,
           am_pagado  = am_cuota
           from ca_amortizacion
           where am_operacion = @i_operacionca
           and am_cuota > am_acumulado

        end

        return 0        
      end -- FIN GENERAR UN SOLO VALOR DE AMORTIZACION
      else 
      begin
	   select @w_saldo_cap_ven = sum(am_cuota )
	   from ca_amortizacion,
                ca_rubro_op
	   where  am_operacion = ro_operacion
           and    am_operacion   = @i_operacionca
           and    am_concepto    = ro_concepto
           and    am_dividendo   < @w_dividendo_vig
           and    ro_tipo_rubro = 'C'



           select @w_saldo_para_cuota  = (@i_monto - @w_saldo_cap_ven)


         select @w_dias_pagados = 0
         exec @w_return =  sp_dias_calculo
         @tasa        = @w_tasa_recalculo,
         @monto       = @w_saldo_para_cuota,
	      @interes     = @w_dtr_monto,
	      @dias_anio   = @i_dias_anio,
	      @dias        = @w_dias_pagados  output
         if @w_return  != 0 return @w_return 

         select @w_dias_pagados = isnull(@w_dias_pagados,0)
         if @w_dias_pagados = 0
            return 710277
	
        /****
        PRINT 'reintant.sp sale @w_saldo_para_cuota'+ @w_saldo_para_cuota
                                @w_tasa_recalculo' + @w_tasa_recalculo
                                @w_dtr_monto' + @w_dtr_monto
                                @w_dias_pagados' + @w_dias_pagados
        ****/

 
         insert into ca_amortizacion_ant (an_secuencial,   an_operacion,       an_dividendo,
         an_estado,           an_dias_pagados,    an_valor_pagado,
         an_dias_amortizados, an_valor_amortizado,an_fecha_pago,
         an_tasa_dia,         an_secuencia)
         values (@w_secuencial_pag,    @i_operacionca,     @w_dividendo_vig,
         1,       	          @w_dias_pagados ,       @w_dtr_monto,
         0,  		  0, 	  @i_fecha_proceso,
         @w_tasa_recalculo,   @w_am_secuencial)

         if @@error != 0 return 710246


         --VALIDAR SI PAGO TODO LO CALCULADO A LA TASA DEL DIA O SOLO UNA PARTE

          select @w_sobrante = isnull(am_cuota - am_pagado,0)
          from ca_amortizacion
          where am_operacion = @i_operacionca
          and   am_dividendo = @w_dividendo_vig
          and   am_concepto  = @i_concepto
          and   am_secuencia = @w_am_secuencial

          if @w_sobrante > 0 begin

            ---PRINT '(reintant.sp ) @w_sobrante'+@w_sobrante

          --SALDO DE CAPITAL EN LA CUOTA VIGENTE 


             exec @w_return =  sp_dias_calculo
                  @tasa        = @w_tasa_recalculo,
		            @monto       = @w_saldo_para_cuota, 
		            @interes     = @w_sobrante,
		            @dias_anio   = @i_dias_anio,
		            @dias        = @w_dias_faltan out
            if @w_return <> 0 begin
               return @w_return
               PRINT '(interesa.sp) error ejecutando sp_dias_calculo'
            end

               PRINT '(reintant.sp) entro a esta parte @w_dias_faltan'+ @w_dias_faltan

               select @w_dias_faltan = round(@w_dias_faltan,0)
 
               if @w_dias_faltan >= 1 begin
                  exec @w_return = sp_calc_intereses
                  @tasa      = @w_tasa_recalculo,
                  @monto     = @w_saldo_para_cuota,
                  @dias_anio = 360,
                  @num_dias  = @w_dias_faltan,
                  @causacion = 'L', 
                  @causacion_acum = 0, 
                  @intereses = @w_valor_calc out
                  if @w_return != 0 
                     return @w_return

                  select @w_valor_calc = round(@w_valor_calc,@w_num_dec)

                  if @w_valor_calc > 0 begin
                     -- ACTUALIZAR LA TABLA DE AMORTIZACION E INSERTAR UN NUEVO SECUENCIAL


                     update ca_amortizacion set
                     am_cuota  = am_pagado
                     where  am_operacion = @i_operacionca
                     and    am_dividendo = @w_dividendo_vig
                     and    am_concepto  = @i_concepto
                     and    am_secuencia = @w_am_secuencial
                     if @@error != 0 return 705050
                     

		     select @w_am_secuencial = isnull(max(am_secuencia),1)
		     from ca_amortizacion
		     where am_operacion = @i_operacionca
		     and   am_dividendo = @w_dividendo_vig
		     and   am_concepto  = @i_concepto
               

                     select @w_am_secuencial = @w_am_secuencial + 1
                     insert into ca_amortizacion values (@i_operacionca,@w_dividendo_vig,@i_concepto,
	   			              @w_est_vigente,0,@w_valor_calc,0,0,0,@w_am_secuencial)
                     if @@error != 0 begin
                        -- PRINT '(reintant.sp) error insertando en ca_amortizacion modo 1' 
                          return 710257
                      end

                  end

               end --dias >= 1 

          end
        -- FIN DE VALIDAR SI PAGO TODO LO CALCULADO A LA TASA DEL DIA O SOLO UNA PARTE

     end ---else

   delete ca_control_intant 
   where   con_operacion = @i_operacionca
   and    con_secuencia_pag = @i_secuencial_pag
   end --existe pago

   else begin

       --NO HAY PAGO REGISTRADO EN ca_control_intant  REVISAR SI OPERACION ESTA CANCELADA
        select @w_estado_op = op_estado,
               @w_tipo      = op_tipo
        from ca_operacion
        where op_operacion = @i_operacionca

       ---PRINT 'reintant.sp entro por el else para buscar operacion cancelada  @w_estado_op' + @w_estado_op

        if @w_estado_op = @w_est_cancelado 
        begin
           update ca_amortizacion set 
           am_estado = @w_est_cancelado,
           am_acumulado = am_cuota,
           am_pagado  = am_cuota
           from ca_amortizacion
           where am_operacion = @i_operacionca
           and am_cuota > am_acumulado

        if exists (select 1 from ca_amortizacion_ant
                   where an_operacion = @i_operacionca
                   and an_estado = @w_est_vigente
                   and an_dias_pagados > an_dias_amortizados) 
        begin

         select @w_valor_amortizar = sum(an_valor_pagado - an_valor_amortizado)
         from ca_amortizacion_ant
         where an_operacion = @i_operacionca
         and an_estado = @w_est_vigente
         and an_dias_pagados > an_dias_amortizados
          
        if @w_valor_amortizar > 0 
        begin  
         exec @w_secuencial = sp_gen_sec
         @i_operacion  = @i_operacionca

         select @w_codvalor = co_codigo * 1000 + @w_est_cancelado * 10 + @w_tipo_garantia
         from  ca_concepto
         where co_concepto    = @i_concepto
         if @@rowcount = 0  return 710252


         insert into ca_transaccion (
         tr_secuencial,     tr_fecha_mov,  tr_toperacion,
         tr_moneda,         tr_operacion,  tr_tran,
         tr_en_linea,       tr_banco,      tr_dias_calc,
         tr_ofi_oper,       tr_ofi_usu,    tr_usuario,
         tr_terminal,       tr_fecha_ref,  tr_secuencial_ref,
         tr_estado,	    tr_gerente,    tr_gar_admisible,	
         tr_reestructuracion , 		   tr_calificacion, 	
     	   tr_observacion,    tr_fecha_cont, tr_comprobante)
         values (
         @w_secuencial,     @s_date,         @i_toperacion,
         @i_moneda,         @i_operacionca,    'AMO',
         'S',               @i_banco,        1,
         @i_oficina,        @s_ofi,          @s_user,
         @s_term,           @i_fecha_proceso,0,
         'ING',	          @i_gerente ,     isnull(@w_gar_admisible,''),	
	 isnull(@w_reestructuracion,''),  isnull(@w_calificacion,''),	
	 '',		    @s_date,	     0)

         if @@error != 0 return 708165


        -- COTIZACION MONEDA *

         exec @w_return = sp_conversion_moneda
         @s_date             = @s_date,
         @i_opcion           = 'L',
         @i_moneda_monto     = @i_moneda,
         @i_moneda_resultado = @w_moneda_nac,
         @i_monto	     = @w_valor_amortizar,
         @i_fecha            = @i_fecha_proceso, 
         @o_monto_resultado  = @w_monto_mn out,
         @o_tipo_cambio      = @w_cot_mn out
         if @w_return != 0 
            return @w_return

        select @w_monto_mn = round(@w_monto_mn,@w_num_dec_mn)  

        insert into ca_det_trn (
        dtr_secuencial, dtr_operacion,    dtr_dividendo,
        dtr_concepto,
        dtr_estado,     dtr_periodo,      dtr_codvalor,
        dtr_monto,      dtr_monto_mn,     dtr_moneda,
        dtr_cotizacion, dtr_tcotizacion,  dtr_afectacion,
        dtr_cuenta,     dtr_beneficiario, dtr_monto_cont )
        values (
        @w_secuencial,  @i_operacionca,   0,
        @i_concepto,
        0,              0,                @w_codvalor,
        @w_valor_amortizar,   @w_monto_mn,          @i_moneda,   
        @w_cot_mn,              'N',              'D',           
        '',             '',               0 )
        if @@error != 0 return 708166
       end --insertar en ca_amortizacion AMO 
         
        update ca_amortizacion_ant
        set an_estado =  @w_est_cancelado,
            an_valor_amortizado = an_valor_pagado,
            an_dias_amortizados = an_dias_pagados 
         where an_operacion = @i_operacionca
           and an_estado = @w_est_vigente
           and an_dias_pagados > an_dias_amortizados
     
      end  -- Existe un registro pendiente por amortizar aun

       
    end  -- Estado Cancelado 
   end --  FIN NO HAY PAGO REGISTRADO EN ca_control_intant  REVISAR SI OPERACION ESTA CANCELADA

end -- FIN modo '1' 

set rowcount 0

return 0

go
