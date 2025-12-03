/************************************************************************/
/*	Nombre Fisico: 		    pagosant.sp   		 		                */
/*	Nombre Logico: 			sp_pagos_por_amortizar      		        */
/*	Base de datos:  	   	cob_cartera				                    */
/*	Producto: 		      	Cartera					                    */
/*	Disenado por:  			Elcira Pelaez         			            */
/*	Fecha de escritura: 	julio/31/2001				                */
/************************************************************************/
/*				IMPORTANTE				                                */
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
/************************************************************************/  
/*				PROPOSITO				                                */
/*	Este sp da mantenimiento a la tabla ca_amortizacion_ant             */
/* Este sp se llama de liquida.sp liquidades.sp, pero el BAC decidio que*/
/* solo se genere una transaccion AMO en el mismo momento del pago  para*/
/* no causar diariamente esta                                           */
/************************************************************************/
/*					MODIFICACIONES										*/
/*		Fecha			Autor					Razon					*/
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/
/************************************************************************/  
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_pagos_por_amortizar')
	drop proc sp_pagos_por_amortizar
go
create proc sp_pagos_por_amortizar (
        @s_user              login,
        @s_ofi               int,
        @s_term              varchar(20),
        @s_date              datetime,
        @i_toperacion        catalogo,
        @i_reestructuracion  char(1),
        @i_gar_admisible     char(1),
        @i_calificacion      catalogo,
        @i_operacionca       int,
        @i_oficial           int,
        @i_moneda            smallint,
        @i_oficina           int,
        @i_operacion         char(1),
        @i_fecha_liq         datetime,
        @i_banco_real        cuenta,
        @i_concepto_intant   catalogo,
        @i_cotizacion        float
   
)
as

declare	@w_sp_name                      descripcion,
       	@w_return 	                    int,
       	@w_pagado_intant                money,
       	@w_pagado_intant_mn             money,
       	@w_secuencial_intant            int,
       	@w_codvalor_intant              int

select	@w_sp_name = 'sp_pagos_por_amortizar'

if @i_operacion = 'I' 
begin

    
    
    select @w_pagado_intant = isnull(sum(am_pagado),0)
    from ca_amortizacion
    where am_operacion = @i_operacionca
    and   am_concepto  = @i_concepto_intant


     exec @w_secuencial_intant = sp_gen_sec
        @i_operacion         = @i_operacionca

      select @w_codvalor_intant = (co_codigo * 1000) + (3 * 10) + 0
      from   ca_concepto
      where  co_concepto = @i_concepto_intant
      
      select @w_pagado_intant_mn =  round(@w_pagado_intant * @i_cotizacion,0)


      insert into ca_det_trn
            (dtr_secuencial,            dtr_operacion,       dtr_dividendo,
             dtr_concepto,              dtr_estado,          dtr_periodo,
             dtr_codvalor,              dtr_monto,           dtr_monto_mn,
             dtr_moneda,                dtr_cotizacion,      dtr_tcotizacion,
             dtr_afectacion,            dtr_cuenta,          dtr_beneficiario,
             dtr_monto_cont)
     values  (@w_secuencial_intant,     @i_operacionca,      1,
             @i_concepto_intant,                3,                   0,
             @w_codvalor_intant,        @w_pagado_intant,    @w_pagado_intant_mn,
             @i_moneda,                 @i_cotizacion,       'N',
             'D',                       '',                  '',
              0)
    if @@error != 0
    begin
       PRINT 'pagosant.sp Error insertando ca_det_trn INTERESE ANTICIPADDOs @w_pagado_intant' + cast(@w_pagado_intant as varchar) + '@w_pagado_intant_mn' + @w_pagado_intant_mn
       return 710001
    end


      -- INSERCION DE CABECERA CONTABLE DE CARTERA
      insert into ca_transaccion
           (tr_fecha_mov,         tr_toperacion,     tr_moneda,
            tr_operacion,         tr_tran,           tr_secuencial,
            tr_en_linea,          tr_banco,          tr_dias_calc,
            tr_ofi_oper,          tr_ofi_usu,        tr_usuario,
            tr_terminal,          tr_fecha_ref,      tr_secuencial_ref,
            tr_estado,            tr_gerente,        tr_gar_admisible,
            tr_reestructuracion,  tr_calificacion,   tr_observacion,
            tr_fecha_cont,        tr_comprobante)
      values(@s_date,             @i_toperacion,     @i_moneda,
             @i_operacionca,      'AMO',             @w_secuencial_intant,
             'N',                 @i_banco_real,     0,
             @i_oficina,          @s_ofi,            @s_user,
             @s_term,             @i_fecha_liq,      0,
             'ING',               @i_oficial,        isnull(@i_gar_admisible,''),
             isnull(@i_reestructuracion,''),isnull(@i_calificacion,''),'AMORTIZACION POR PAGO DE INTANT',
             @s_date,             0)
      
      if @@error != 0
         return 708165 
         
    --SE COLOCA COMO AMORTIZADO TODO EL VALOR PAGADO EN EL DESEMBOLSO
    update ca_amortizacion
    set am_acumulado = am_cuota
    where am_operacion = @i_operacionca
    and   am_concepto  = @i_concepto_intant
    and   am_pagado > 0

end -- Operacion I 



return 0

go

