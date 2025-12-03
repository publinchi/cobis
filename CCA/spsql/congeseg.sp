/************************************************************************/
/*	 Nombre Fisico:		   congeseg.sp									*/
/*   Nombre Logico:        sp_congela_seguros                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Feb. 2006                                    */
/************************************************************************/
/*                              IMPORTANTE                              */
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
/*                              PROPOSITO                               */
/*   El propósito de este sp es  generar el PRV del seguro que paso     */
/*   a vencido  y  regenerar el seguro                                  */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*   Ago/22/2007   John Jairo Rendon  Optimizacion OPT_224              */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_congela_seguros')
   drop proc sp_congela_seguros
go

create proc sp_congela_seguros
            @s_user               login,
            @s_term               varchar(30),
            @s_date               datetime,
            @s_ofi                int,
            @i_fecha_proceso      datetime,
            @i_operacionca        int,
            @i_dividendo_vigente  smallint
as
declare
   @w_return          int,
   @w_concepto_seg    varchar(10),
   @w_fpago_seg       char(1),
   @w_valor_seg       float,
   @w_valor_seg_mn    float,
   @w_cotizacion_seg  float,
   @w_secuencial_prv  int,
   @w_insertar        char(1),
   @w_dividendo_seg   smallint,
   @w_codvalor_seg    int,
   @w_tipo_rubro      char(1),
   @w_banco           cuenta,
   @w_toperacion      catalogo,
   @w_moneda          smallint,
   @w_oficial         int,
   @w_oficina         int,
   @w_gar_admisible   char(1),
   @w_reestructuracion char(1),
   @w_calificacion     catalogo,
   @w_estado_act       smallint

select @w_banco             = op_banco,
       @w_toperacion        = op_toperacion,
       @w_moneda            = op_moneda,
       @w_oficial           = op_oficial,
       @w_oficina           = op_oficina,
       @w_gar_admisible     = isnull(op_gar_admisible,'N'),
       @w_reestructuracion  = isnull(op_reestructuracion,'N'),
       @w_calificacion      = isnull(op_calificacion,'A'),
       @w_estado_act        = op_estado
from   ca_operacion
where  op_operacion  = @i_operacionca

if @w_estado_act = 4
  return 0

if (select count(1)
           from   ca_rubro_op, ca_amortizacion,ca_concepto
           where  ro_concepto       = am_concepto
           and    ro_concepto       = co_concepto
           and    co_concepto       = am_concepto
           and    ro_operacion      = @i_operacionca
           and    ro_saldo_insoluto = 'S'
	   and    am_operacion      = @i_operacionca
           and    am_dividendo      = convert(smallint, @i_dividendo_vigente + 1)
           and    am_estado        != 3
           and    co_categoria      = 'S') > 0
begin ---PRINCIPAL 
   exec @w_return =  sp_recalculo_seguros_sinsol
        @i_operacion       = @i_operacionca,
        @i_dividendo_desde = @i_dividendo_vigente
   
   if @w_return != 0
      return @w_return
   
   select @w_insertar = 'S' -- PARA QUE INSERTE LA PRIMERA VEZ
   
   declare
      regenera_seg_feriados cursor
      for select ro_concepto, ro_fpago, ro_tipo_rubro
          from   ca_rubro_op, ca_concepto  --(prefetch 16)
          where  ro_operacion = @i_operacionca
          and    ro_tipo_rubro = 'Q'
          and    ro_provisiona = 'N'
          and    ro_fpago     <> 'L'
          and    co_concepto = ro_concepto
          and    (co_categoria = 'S' and ro_saldo_insoluto = 'S')
          union -- UNIR LOS CONCEPTOS DE IVA ASOACIADOS A ESTOS CONCEPTOS
          select ro_concepto, ro_fpago, ro_tipo_rubro
          from   ca_rubro_op, ca_concepto --(prefetch 16)
          where  ro_operacion = @i_operacionca
          and    ro_fpago     <> 'L'
          and    ro_concepto_asociado in (select ro_concepto
                                          from   ca_rubro_op, ca_concepto --(prefetch 16)
                                          where  ro_operacion = @i_operacionca
                                          and    ro_tipo_rubro = 'Q'
                                          and    ro_provisiona = 'N'
                                          and    ro_fpago     <> 'L'
                                          and    co_concepto = ro_concepto
                                          and    (co_categoria = 'S' and ro_saldo_insoluto = 'S')
                                         )
       for read only
   
   open regenera_seg_feriados
   
   fetch regenera_seg_feriados
   into  @w_concepto_seg, @w_fpago_seg, @w_tipo_rubro
   
   while @@fetch_status = 0
   begin

      select @w_valor_seg = 0
      
      if @w_fpago_seg = 'A'
         select @w_dividendo_seg = @i_dividendo_vigente + 1
      else
         select @w_dividendo_seg = @i_dividendo_vigente
      
      select @w_valor_seg = am_cuota - am_pagado
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_dividendo_seg
      and    am_concepto  = @w_concepto_seg
      
      if @w_valor_seg != 0 and  (@w_estado_act != 4) -- TIENE VALOR DE RUBRO ANTICIPADO
      begin
         -- CREAR LA 'CAUSACION'
         if @w_insertar = 'S'
         begin
            select @w_insertar = 'N' -- SOLO DEBE INSERTAR POR EL PRIMER CONCEPTO
            
            exec @w_secuencial_prv = sp_gen_sec
                 @i_operacion = @i_operacionca
            
            insert into ca_transaccion
                  (tr_secuencial,       tr_fecha_mov,     tr_toperacion,
                   tr_moneda,           tr_operacion,     tr_tran,
                   tr_en_linea,         tr_banco,         tr_dias_calc,
                   tr_ofi_oper,         tr_ofi_usu,       tr_usuario,
                   tr_terminal,         tr_fecha_ref,     tr_secuencial_ref,
                   tr_estado,           tr_observacion,   tr_gerente,
                   tr_comprobante,      tr_fecha_cont,    tr_gar_admisible,
                   tr_reestructuracion, tr_calificacion)
            values(@w_secuencial_prv,   @s_date,          @w_toperacion,
                   @w_moneda,           @i_operacionca,   'PRV',
                   'N',                 @w_banco,         0,
                   @w_oficina,          @w_oficina,       @s_user,
                   @s_term,             @i_fecha_proceso, -999,
                   'ING',               'CAUSACION DE SEGUROS ANTICIPADOS FER', @w_oficial,
                   0,                   @s_date,          @w_gar_admisible,
                   @w_reestructuracion, @w_calificacion)
            
            if @@error != 0
               return 703041
            
            exec @w_return = sp_historial
                 @i_operacionca = @i_operacionca,
                 @i_secuencial  = @w_secuencial_prv
            
            if @w_return != 0
               return @w_return
         end
         
         update ca_amortizacion
         set    am_estado = 2
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_dividendo_seg
         and    am_concepto = @w_concepto_seg
         
         if @w_moneda != 0
         begin
            exec sp_buscar_cotizacion
                 @i_moneda     = @w_moneda,
                 @i_fecha      = @i_fecha_proceso,
                 @o_cotizacion = @w_cotizacion_seg  out
            
            select @w_valor_seg_mn = round(@w_valor_seg * @w_cotizacion_seg, 2)
         end
         else
            select @w_valor_seg_mn = @w_valor_seg,
                   @w_cotizacion_seg = 1
         
         select @w_codvalor_seg = co_codigo * 1000+20
         from   ca_concepto
         where  co_concepto = @w_concepto_seg
         
         if (select count(1)
                   from   ca_det_trn
                   where  dtr_operacion  = @i_operacionca
                   and    dtr_secuencial = @w_secuencial_prv
                   and    dtr_codvalor   = @w_codvalor_seg) > 0
         begin -- ACTUALIZAR,
            update ca_det_trn
            set    dtr_monto      = dtr_monto + @w_valor_seg,
                   dtr_cotizacion = @w_cotizacion_seg,
                   dtr_monto_mn   = dtr_monto_mn + @w_valor_seg_mn
            where  dtr_operacion  = @i_operacionca
            and    dtr_secuencial = @w_secuencial_prv
            and    dtr_codvalor   = @w_codvalor_seg
            
            if @@error != 0
               return 705052
         end
         ELSE
         begin
            insert into ca_det_trn
                  (dtr_secuencial,    dtr_operacion,     dtr_dividendo,
                   dtr_concepto,      dtr_estado,        dtr_periodo,
                   dtr_codvalor,      dtr_monto,         dtr_monto_mn,
                   dtr_moneda,        dtr_cotizacion,    dtr_tcotizacion,
                   dtr_afectacion,    dtr_cuenta,        dtr_beneficiario,
                   dtr_monto_cont)
            values(@w_secuencial_prv, @i_operacionca,    @w_dividendo_seg,
                   @w_concepto_seg,   2,                 0,
                   @w_codvalor_seg,   @w_valor_seg,      @w_valor_seg_mn,
                   @w_moneda,         @w_cotizacion_seg, 'N',
                   'D',               '',                '',
                   0)
            
            if @@error != 0
               return 703115
         end
      end-- CONCEPTO DE SEGUROS
      
      fetch regenera_seg_feriados
      into  @w_concepto_seg, @w_fpago_seg, @w_tipo_rubro
   end
   
   close regenera_seg_feriados
   deallocate regenera_seg_feriados
end

return 0
go

