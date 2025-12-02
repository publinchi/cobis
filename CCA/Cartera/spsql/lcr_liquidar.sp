
/************************************************************************/
/*  Nombre Fisico:          lcr_liquida.sp                              */
/*  Nombre Logico:          sp_lcr_liquidar                             */
/*  base de datos:          cob_cartera                                 */
/*  producto:               credito                                     */
/*  disenado por:           Andy Gonzalez                               */
/*  fecha de documentacion: Noviembre 2018                              */
/************************************************************************/
/*          importante                                                  */
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
/*          proposito                                                   */
/*             Liquidar la operacion  de la LCR                         */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*   FECHA                  AUTOR                  RAZON                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion	*/
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_lcr_liquidar')
	drop proc sp_lcr_liquidar
go

create proc sp_lcr_liquidar(
@s_ofi            int          = null,
@s_term           varchar (30) = null,
@s_user           login        = null,
@s_srv            varchar(64)  = null,
@s_ssn            int          = null,
@s_sesn           int          = null,
@s_date           datetime     = null,
@i_banco          cuenta,
@i_renovar        char(1)      = 'N',
@i_cuota_balon    int 

)as declare 
@w_operacionca               int,          
@w_oficina                   int,                               
@w_moneda                    int,                
@w_op_tipo_amortizacion      varchar(64),
@w_op_monto                  money,           
@w_op_monto_aprobado         money,     
@w_tramite                   int,                               
@w_toperacion                catalogo,          
@w_fecha_ult_proceso         datetime,  
@w_oficial                   int,             
@w_calificacion              catalogo,        
@w_tasa_equivalente          char(1),
@w_error                     int, 
@w_est_cancelado             int,  
@w_est_suspenso              int,   
@w_est_vigente               int ,
@w_secuencial                int,
@w_sec_liq                   int,
@w_msg                       varchar(255),
@w_gar_admisible             char(1),
@w_dm_producto               catalogo,
@w_dm_cuenta                 cuenta,
@w_dm_beneficiario           descripcion,
@w_moneda_n                  tinyint,
@w_dm_moneda                 tinyint,
@w_dm_desembolso             int,
@w_dm_monto_mds              money,
@w_dm_cotizacion_mds         float,
@w_dm_tcotizacion_mds        char(1),
@w_dm_cotizacion_mop         float,
@w_dm_tcotizacion_mop        char(1),
@w_dm_monto_mn               money,
@w_dm_monto_mop              money,
@w_ro_concepto               catalogo,
@w_ro_valor_mn               money,
@w_ro_tipo_rubro             char(1),
@w_estado_op                 tinyint,
@w_codvalor                  int,
@w_num_dec                   tinyint,
@w_num_dec_mn                tinyint,
@w_instrumento               int, 
@w_prod_cobis                int ,
@w_num_secuencial            int,     
@w_cliente                   int,
@w_num_orden                 int ,      
@o_msg                       varchar(255),
@w_tipo_garantia             int,            
@w_ro_fpago                  catalogo, 
@w_ro_valor                  money,
@w_afectacion                char(1),
@w_subtipo                   int,  
@w_categoria                 catalogo ,
@w_pagado                    char(1), 
@w_banco                     cuenta,
@w_ro_porcentaje             float ,
@w_sector                    catalogo,
@w_num_renovacion            int



/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_vigente    = @w_est_vigente   out


select 
@w_operacionca            = op_operacion,
@w_oficina                = op_oficina,
@w_moneda                 = op_moneda,
@w_op_tipo_amortizacion   = op_tipo_amortizacion,
@w_op_monto               = op_monto,
@w_op_monto_aprobado      = op_monto_aprobado,
@w_tramite                = op_tramite, 
@w_toperacion             = op_toperacion,
@w_fecha_ult_proceso      = op_fecha_ult_proceso,
@w_oficial                = op_oficial,
@w_calificacion           = op_calificacion,
@w_tasa_equivalente       = op_usar_tequivalente
from   ca_operacion
where  op_banco = @i_banco


exec @w_error = sp_decimales
@i_moneda      = @w_moneda ,
@o_decimales   = @w_num_dec out


-- DETERMINAR EL SECUENCIAL DE DESEMBOLSO A APLICAR
select @w_secuencial  = isnull(min(dm_secuencial),0)
from   ca_desembolso
where  dm_operacion  = @w_operacionca
and    dm_estado     = 'NA'

if @w_secuencial <= 0 or @w_secuencial is null begin
  select 
  @w_error = 701121,
  @w_msg   = 'ERROR: NO EXISTEN DETALLES DE DESEMBOLSO'
  goto ERROR
end


-- GENERACION DEL NUMERO DE RECIBO DE LIQUIDACION

exec @w_error = sp_numero_recibo
@i_tipo    = 'L',
@i_oficina = @s_ofi,
@o_numero  = @w_sec_liq out

if @w_error <> 0 begin
   select @w_error = @w_error
   goto ERROR
end


insert into ca_transaccion(
tr_secuencial,        tr_fecha_mov,        tr_toperacion,
tr_moneda,            tr_operacion,        tr_tran,
tr_en_linea,          tr_banco,            tr_dias_calc,
tr_ofi_oper,          tr_ofi_usu,          tr_usuario,
tr_terminal,          tr_fecha_ref,        tr_secuencial_ref,
tr_estado,            tr_gerente,          tr_gar_admisible,
tr_reestructuracion,  tr_calificacion,
tr_observacion,       tr_fecha_cont,       tr_comprobante)
values(
@w_secuencial,        @s_date,             @w_toperacion,
@w_moneda,            @w_operacionca,      'DES',
'S',                  @i_banco,            isnull(@w_sec_liq,0),
@w_oficina,           @s_ofi,              @s_user,
@s_term,              @w_fecha_ult_proceso,      0,
'ING',                @w_oficial,          isnull(@w_gar_admisible,''),
'N',                  isnull(@w_calificacion,''),
'DESEMBOLSO B2C',     @s_date,             0)

if @@error <> 0 begin
   select @w_error = 710001
   goto ERROR
end


-- INSERCION DEL DETALLE CONTABLE PARA LAS FORMAS DE PAGO
declare cursor_desembolso cursor
for select 
dm_desembolso,    dm_producto,          dm_cuenta,
dm_beneficiario,  dm_monto_mds,
dm_moneda,        dm_cotizacion_mds,    dm_tcotizacion_mds,
dm_monto_mn,      dm_cotizacion_mop,    dm_tcotizacion_mop,
dm_monto_mop,     dm_cheque,            dm_cod_banco,
dm_pagado
from   ca_desembolso
where  dm_secuencial = @w_secuencial
and    dm_operacion  = @w_operacionca
order  by dm_desembolso
for read only

open cursor_desembolso

   fetch cursor_desembolso into  
   @w_dm_desembolso,   @w_dm_producto,       @w_dm_cuenta,
   @w_dm_beneficiario, @w_dm_monto_mds,
   @w_dm_moneda,       @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
   @w_dm_monto_mn,     @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
   @w_dm_monto_mop,    @w_instrumento,       @w_subtipo,
   @w_pagado

   while @@fetch_status = 0 begin
      if (@@fetch_status = -1) begin
         close cursor_desembolso
         deallocate cursor_desembolso
         select @w_error = 710004
         goto ERROR
      end
   
      select 
      @w_prod_cobis     = isnull(cp_pcobis,0),
      @w_categoria      = cp_categoria,
      @w_codvalor       = cp_codvalor
      from   ca_producto
      where  cp_producto = @w_dm_producto
      
      if @@rowcount <> 1 begin
         close cursor_desembolso
         deallocate cursor_desembolso
         select @w_error = 701150
         goto ERROR
      end  
   
--    INSERCION DEL DETALLE DE LA TRANSACCION
      insert ca_det_trn(
      dtr_secuencial,    dtr_operacion,           dtr_dividendo,        dtr_concepto,
      dtr_estado,        dtr_periodo,             dtr_codvalor,         dtr_monto,
      dtr_monto_mn,      dtr_moneda,              dtr_cotizacion,       dtr_tcotizacion,
      dtr_afectacion,    dtr_cuenta,              dtr_beneficiario,     dtr_monto_cont)
      values(
      @w_secuencial,     @w_operacionca,          @w_dm_desembolso,     @w_dm_producto,
      1,                 0,                       @w_codvalor,          @w_dm_monto_mds,
      0,                 @w_dm_moneda,            0,                   'N',
      'C',               isnull(@w_dm_cuenta,''), isnull(@w_dm_beneficiario,''),   0
      )
      
      if @@error <> 0  begin
         close cursor_desembolso
         deallocate cursor_desembolso
         select @w_error = 710001
         goto ERROR
      end

      if @w_prod_cobis <> 0 and ( @w_pagado = 'N' or @w_pagado is null) begin
  
         exec @w_error = sp_afect_prod_cobis
         @s_user               = @s_user,
         @s_date               = @s_date,
         @s_ssn                = @s_ssn,
         @s_sesn               = @s_sesn,
         @s_term               = @s_term,
         @s_srv                = @s_srv,
         @s_ofi                = @s_ofi,
         @i_fecha              = @w_fecha_ult_proceso,
         @i_cuenta             = @w_dm_cuenta,
         @i_producto           = @w_dm_producto,
         @i_monto              = @w_dm_monto_mn,
         @i_mon                = @w_dm_moneda,  /* ELA FEB/2002 */
         @i_beneficiario       = @w_dm_beneficiario,
         @i_monto_mpg          = @w_dm_monto_mds,
         @i_monto_mop          = @w_dm_monto_mop,
         @i_monto_mn           = @w_dm_monto_mn,
         @i_cotizacion_mop     = @w_dm_cotizacion_mop,
         @i_tcotizacion_mop    = @w_dm_tcotizacion_mop,
         @i_cotizacion_mpg     = @w_dm_cotizacion_mds,
         @i_tcotizacion_mpg    = @w_dm_tcotizacion_mds,
         @i_operacion_renovada = @w_operacionca,
         @i_alt                = @w_operacionca,
         @i_instrumento        = @w_instrumento,
         @i_subtipo            = @w_subtipo,
         @i_pagado             = @w_pagado,
         @i_dm_desembolso      = @w_dm_desembolso,
         @i_sec_tran_cca       = @w_secuencial,         -- FCP Interfaz Ahorros
         @o_num_renovacion     = @w_num_renovacion out,
         @o_secuencial         = @w_num_secuencial out
      
         if @w_error <> 0 begin
            close cursor_desembolso
            deallocate cursor_desembolso
            select @w_error = @w_error
            goto ERROR
         end
		 
 
         update ca_desembolso with (rowlock)
         set dm_idlote       = @w_num_secuencial
         where dm_desembolso = @w_dm_desembolso
         and   dm_operacion  = @w_operacionca
         
         if @@rowcount = 0 begin
            close cursor_desembolso
            deallocate cursor_desembolso
            select @w_error = 701121
            goto ERROR
         end
      end
      

--LPO CDIG No usar sp_genera_orden porque Cajas no la usa INICIO
/*
      if @w_dm_producto = 'EFMN' begin
      
         exec @w_error  = cob_interface..sp_genera_orden
         @s_date         = @s_date,             --> Fecha de proceso
         @s_user         = @s_user,             --> Usuario
         @i_ofi          = @s_ofi,
         @i_operacion    = 'I',                 --> Operacion ('I' -> Insercion, 'A' Anulación)
         @i_causa        = '003',               --> Causal de Egreso(cc_causa_oe)
         @i_ente         = @w_cliente,          --> Cod ente,
         @i_valor        = @w_dm_monto_mn,
         @i_tipo         = 'P',
         @i_idorden      = null,                --> Cód Orden cuando operación 'A',
         @i_ref1         = 0,                   --> Ref. Númerica no oblicatoria
         @i_ref2         = 0 ,                  --> Ref. Númerica no oblicatoria
         @i_ref3         = @w_banco,            --> Ref. AlfaNúmerica no oblicatoria
         @i_interfaz     ='N',                  --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve cód error
         @o_idorden      = @w_num_orden out     --> Devuelve cód orden de pago/cobro generada - Operación 'I'
         
         if @w_error <> 0 begin
            select @w_error = @w_error
            goto ERROR
         end
             
         update ca_desembolso with (rowlock)
         set dm_pagado = 'I',
         dm_orden_caja  = @w_num_orden
         where dm_operacion = @w_operacionca
         and   dm_producto  = 'EFMN'
	 
         if @@error <> 0 begin
            select @o_msg = 'lcr_liquidar.sp Error en actualizacion ca_desembolso '
            select @w_error = 710305
            goto ERROR
         end
      end  
*/
--LPO CDIG No usar sp_genera_orden porque Cajas no la usa FIN
      
      fetch cursor_desembolso into  
      @w_dm_desembolso,   @w_dm_producto,       @w_dm_cuenta,
      @w_dm_beneficiario, @w_dm_monto_mds,
      @w_dm_moneda,       @w_dm_cotizacion_mds, @w_dm_tcotizacion_mds,
      @w_dm_monto_mn,     @w_dm_cotizacion_mop, @w_dm_tcotizacion_mop,
      @w_dm_monto_mop,    @w_instrumento,       @w_subtipo,
      @w_pagado
   end
close cursor_desembolso
deallocate cursor_desembolso


update ca_desembolso with (rowlock) set 
dm_estado          = 'A'
where  dm_secuencial = @w_secuencial
and    dm_operacion  = @w_operacionca


-- INSERCION DEL DETALLE CONTABLE PARA LOS RUBROS AFECTADOS

declare cursor_rubro cursor for 
select ro_concepto,convert(float,ro_valor),ro_tipo_rubro,ro_fpago, ro_porcentaje
from   ca_rubro_op
where  ro_operacion = @w_operacionca
and    ( (ro_fpago  in ('L','A') and @i_renovar = 'N') or (ro_tipo_rubro = 'C') )
and    ro_tipo_rubro <> 'I'  
and    ro_valor > 0
order  by ro_concepto
for read only
open cursor_rubro

   fetch cursor_rubro into  
   @w_ro_concepto, @w_ro_valor, @w_ro_tipo_rubro, @w_ro_fpago, @w_ro_porcentaje

   while @@fetch_status = 0 begin
      if (@@fetch_status = -1) begin
           close cursor_rubro
           deallocate cursor_rubro
           select @w_error = 710004
           goto ERROR
      end
    
      select @w_tipo_garantia = 0  --NO ADMISIBLE
      
      if @w_ro_fpago = 'A' begin
 
         update ca_amortizacion with (rowlock) set    
	     am_pagado = am_cuota,
         am_estado = @w_est_cancelado
         from   ca_rubro_op
         where  am_operacion  = @w_operacionca
         and    am_dividendo = 1
         and    ro_operacion  = @w_operacionca
         and    am_concepto   = ro_concepto
         and    ro_tipo_rubro <> 'I'
         and    ro_fpago      = 'A'
      
         if @@error <> 0 begin
             close cursor_rubro
             deallocate cursor_rubro
             select @o_msg = '8 -  Estado : ' + cast(@w_est_cancelado as varchar) + ' Ope Real : ' + cast(@w_operacionca as varchar) + ' - ' + 'Error en actualizacion de ca_amortizacion'
             select @w_error = 7100028
             goto ERROR
         end
      
      
         select @w_ro_valor =  am_cuota
         from   ca_amortizacion
         where  am_operacion  = @w_operacionca
         and    am_dividendo = 1
         and    am_concepto     = @w_ro_concepto
      end
      
      -- SE ASUME QUE UNA OPERACION NUEVA NO TIENE ASIGNADA GARANTIA
      -- OBTENCION DE CODIGO VALOR DEL RUBRO

      select @w_codvalor = co_codigo * 1000  + 10  + 0 --@w_tipo_garantia
      from   ca_concepto
      where  co_concepto = @w_ro_concepto
      
      if @@rowcount <> 1 begin
          close cursor_rubro
          deallocate cursor_rubro
          select @w_error = 701151
          goto ERROR
      end
      
      select @w_ro_valor_mn = 0
	 
      select @w_ro_valor = round(@w_ro_valor,@w_num_dec)

      if @w_ro_tipo_rubro = 'C'
         select @w_afectacion = 'D'
      else
         select @w_afectacion = 'C'
       
      -- INSERCION DEL DETALLE DE LA TRANSACCION
 
      insert ca_det_trn (
      dtr_secuencial,    dtr_operacion,       dtr_dividendo,        dtr_concepto,
      dtr_estado,        dtr_periodo,         dtr_codvalor,         dtr_monto,
      dtr_monto_mn,      dtr_moneda,          dtr_cotizacion,       dtr_tcotizacion,
      dtr_afectacion,    dtr_cuenta,          dtr_beneficiario,     dtr_monto_cont)
      values(
      @w_secuencial,     @w_operacionca,      @i_cuota_balon,       @w_ro_concepto,
      1,                 0,                   @w_codvalor,          @w_ro_valor,
      0,                 @w_moneda,           0,                    0,
      @w_afectacion,     '',                  '',                   0)
      
      if @@error <> 0 begin
          close cursor_rubro
          deallocate cursor_rubro
          select @w_error = 710001
          goto ERROR
      end

      fetch cursor_rubro
      into @w_ro_concepto, @w_ro_valor, @w_ro_tipo_rubro, @w_ro_fpago, @w_ro_porcentaje
   end
close cursor_rubro
deallocate cursor_rubro



/*PARA INTERES ANTICIPADO*/
if exists (select 1
           from   ca_rubro_op_tmp
           where  rot_operacion = @w_operacionca 
           and    rot_tipo_rubro = 'I'
           and    rot_fpago = 'A')
begin      --- INSERCION DE LOS DETALLES CORRESPONDIENTES A LOS INTERESES PERIODICOS ANTICIPADOS
   insert into ca_det_trn (
   dtr_secuencial,        dtr_operacion,        dtr_dividendo,
   dtr_concepto,          dtr_estado,           dtr_periodo,
   dtr_codvalor,          dtr_monto,            dtr_monto_mn,
   dtr_moneda,            dtr_cotizacion,       dtr_tcotizacion,
   dtr_afectacion,        dtr_cuenta,           dtr_beneficiario,
   dtr_monto_cont)
   select @w_secuencial,  @w_operacionca,       @i_cuota_balon,
   amt_concepto,          1,                    0,
   co_codigo*1000+10+0,   amt_cuota,            round(amt_cuota*@w_dm_cotizacion_mop,@w_num_dec_mn),
   @w_moneda,             @w_dm_cotizacion_mop, 'C',
   'C',                    '',                   'REGISTRO INTERESES ANTICIPADOS',
   0
   from   ca_amortizacion_tmp, ca_concepto ,ca_rubro_op_tmp
   where  amt_operacion = @w_operacionca
   and    amt_dividendo = 1
   and    amt_concepto  = co_concepto
   and    rot_operacion = @w_operacionca
   and    rot_concepto  = amt_concepto
   and    rot_tipo_rubro= 'I'
   and    rot_fpago     = 'A'

   if @@error <> 0 begin
      select @w_error = 710001
      goto ERROR
   end

   update ca_amortizacion_tmp with (rowlock) set    
   amt_pagado    = amt_cuota,
   amt_estado    = @w_est_cancelado,
   amt_acumulado = 0 --amt_cuota
   from   ca_rubro_op_tmp
   where  amt_operacion = @w_operacionca
   and    amt_dividendo = 1
   and    rot_operacion = @w_operacionca
   and    amt_concepto  = rot_concepto
   and    rot_tipo_rubro = 'I'
   and    rot_fpago      = 'A'

   if @@error <> 0 begin
      select @o_msg =  '10 - Op Ficticio : ' + cast(@w_operacionca as varchar) + ' - ' + 'Error en Actualizacion de ca_amortizacion_tmp por @w_operacionca'
      select @w_error = 7100210
      goto ERROR
   end
end 


--INSERTAR TASAS EN CA_TASAS
declare cursor_rubro cursor for 
select ro_concepto
from   ca_rubro_op
where  ro_operacion   = @w_operacionca
and    ro_tipo_rubro  = 'I'
for read only
open cursor_rubro

   fetch cursor_rubro
   into  @w_ro_concepto

   while @@fetch_status = 0 begin
      if (@@fetch_status = -1) begin
  	    close cursor_rubro
  	    deallocate cursor_rubro
  	    select @w_error = 710004
  	    goto ERROR
      end
      
      exec @w_error = sp_consulta_tasas
      @i_operacionca = @w_operacionca,
      @i_dividendo   = 1,
      @i_concepto    = @w_ro_concepto,
      @i_sector      = @w_sector,
      @i_fecha       = @w_fecha_ult_proceso,
      @i_equivalente = @w_tasa_equivalente,
      @o_tasa        = @w_ro_porcentaje out
      
      if @w_error <> 0 begin
         close cursor_rubro
         deallocate cursor_rubro
         select @w_error =  @w_error
         goto ERROR
      end

      fetch cursor_rubro
      into @w_ro_concepto
   end
close cursor_rubro
deallocate cursor_rubro


 /*SE ACTUALIZA AL CLIENTE COMO CLIENTE*/
update cobis..cl_ente with (rowlock)
set en_cliente  = 'S'
where en_ente  = @w_cliente
if @@error <> 0 begin
   select @w_error = 710001
   goto ERROR
end



ERROR:
return @w_error
go

