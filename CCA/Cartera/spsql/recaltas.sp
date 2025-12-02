/************************************************************************/
/*      Nombre Fisico:          recaltasvar.sp                          */
/*      Nombre Logico:          sp_reproceso_tasas_variables            */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira PElaez                           */
/*      Fecha de escritura:     dic. 2005                               */
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
/*      Este sp tiene como propósito  revisar  de los rubros  cargados  */
/*      en la tabla ca_rubros_recalculo  para generar  la diferencia    */
/*      de valores con respecto a la tasa del seguro que cambio en el   */
/*      2005  , esa diferencia entre valor con tasa anterior y valor    */
/*      con tasa nueva, debe ser cobrado como un IOC especial           */
/*      para cada seguro                                                */
/************************************************************************/  
/*			                  MODIFICACIONES				            */
/*	     FECHA		     AUTOR			          RAZON		            */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_reproceso_tasas_variables')
   drop proc sp_reproceso_tasas_variables
go

create proc sp_reproceso_tasas_variables
 @i_user    login,        
 @i_ofi     int,           
 @i_term    catalogo,
 @i_fecha_proceso datetime,
 @i_tipo       char(1)


as
declare
@w_sp_name		     varchar(30),
@w_ro_porcentaje    float,
@w_tasa_aplicar     catalogo,  
@w_ro_concepto      catalogo,
@w_num_dec          tinyint,
@w_num_dec_mn       smallint,
@w_div_vigente      int,
@w_re_nuevo_porcentaje  float,
@w_secuencial       int,
@w_monto_mn         money,
@w_monto_uvr        money,
@w_cotizacion       float,
@w_moneda_nacional  smallint,
@w_op_moneda        smallint,
@w_fecha_ult_proceso  datetime,
@w_reestructuracion   char(1),
@w_gar_admisible      char(1),
@w_calificacion       catalogo,
@w_gerente            int,
@w_toperacion         catalogo,
@w_oficina            int,
@w_concepto_ioc       catalogo,
@w_comentario         descripcion,
@w_codvalor           int,
@w_di_estado          int,
@w_re_operacion       int,
@w_diff               float,
@w_procesa            char(1),
@w_banco              cuenta,
@w_moneda_local       smallint,
@w_por_asociado       float,
@w_concepto_asociado  catalogo,
@w_valor_aso          money,
@w_base               money,
@w_valor_rubro        money,
@w_contador1          int,
@w_contador2          int



--- INICIALIZACION VARIABLES 
select @w_sp_name = 'sp_reproceso_tasas_variables',
       @w_concepto_ioc = '',
       @w_comentario = 'RECALCULO DE SEGUROS DE CUOTAS EN ESTADO 1,2,3'

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

--VALIDACION EXISTENCIA DE LA CREACION DE RUBROS

select @w_contador1 = count(1)
 from ca_rubros_recalculo

select @w_contador2 = count(1)
 from ca_rubros_recalculo,ca_concepto
where co_concepto = re_concepto_IOC

if @w_contador1 <> @w_contador2
begin
 PRINT '************************ ANTENCION ***********************************************'
 PRINT '************************ ANTENCION ***********************************************'
 PRINT '************************ ANTENCION ***********************************************'
 PRINT '************************ ANTENCION ***********************************************'
 PRINT 'No se han creado los Rubros en la tabla de Conceptos no se puede Iniciar el proceo'
 PRINT '**********************************************************************************'
 return 0
end


declare cursor_rubros_uno cursor for 
select  
re_operacion
from  ca_reproceso_seg_tmp
where  re_op_tipo = @i_tipo

for read only
open   cursor_rubros_uno
fetch cursor_rubros_uno into
@w_re_operacion

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin

     select @w_op_moneda           = op_moneda,
            @w_fecha_ult_proceso   = op_fecha_ult_proceso,
            @w_reestructuracion    = isnull(op_reestructuracion,'N'),
            @w_gar_admisible       = isnull(op_gar_admisible,'N'),
            @w_calificacion        = isnull(op_calificacion,'A'),
            @w_gerente             = op_oficial,
            @w_toperacion          = op_toperacion,
            @w_oficina             = op_oficina,
            @w_banco               = op_banco
     from ca_operacion
     where op_operacion =  @w_re_operacion


        exec  sp_decimales
        @i_moneda       = @w_op_moneda,
        @o_decimales    = @w_num_dec out,
        @o_mon_nacional = @w_moneda_local out,
        @o_dec_nacional = @w_num_dec_mn out
         
         --inicio cursor dos
         declare cursor_rubros_dos cursor for 
              select
              ro_concepto,
              ro_porcentaje,
              re_nuevo_porcentaje,
              re_concepto_IOC
             from ca_rubro_op,
                   ca_rubros_recalculo
              where ro_operacion = @w_re_operacion          
              and    ro_concepto = re_concepto

         for read only
         open   cursor_rubros_dos
         fetch cursor_rubros_dos into
               @w_ro_concepto,
               @w_ro_porcentaje,
               @w_re_nuevo_porcentaje ,
               @w_concepto_ioc
         
         --while @@fetch_status not in (-1,0)
         while @@fetch_status = 0
         begin
            
              PRINT 'recaltas.sp  @w_re_nuevo_porcentaje ,  @w_ro_porcentaje' + @w_re_nuevo_porcentaje + @w_ro_porcentaje
              
               if  @w_re_nuevo_porcentaje <>  @w_ro_porcentaje
               begin    ---(1)
                     ---Valor para las cuotas  CANCELADAS -VENCIDAS - VIGENTES
                     --La diferencia de este recalculo se coloca en la cuota VIGENTE  + 1 como un IOC
               
                    select  @w_diff = sum(round((am_cuota * @w_re_nuevo_porcentaje   /@w_ro_porcentaje) - am_cuota, @w_num_dec))
                    from ca_dividendo,
                     ca_amortizacion 
                    where di_operacion = @w_re_operacion
                    and di_fecha_ini > '01/03/2005'
                    and am_operacion = di_operacion
                    and am_dividendo = di_dividendo
                    and am_concepto=  @w_ro_concepto
                    and di_estado in (1,2,3)

                  
                  -- DETERMINAR EL VALOR DE COTIZACION DEL DIA 
                     if @w_op_moneda = @w_moneda_nacional
                     begin
                        select @w_cotizacion = 1.0
                        select @w_monto_uvr =  @w_diff
                        select @w_monto_mn  =  @w_diff
                     end
                     else
                     begin
                        exec sp_buscar_cotizacion
                                @i_moneda     = @w_op_moneda,
                                @i_fecha      = @w_fecha_ult_proceso,
                                @o_cotizacion = @w_cotizacion output
                  
                        select @w_monto_uvr = @w_diff  
                        select @w_monto_mn = isnull(round(@w_diff  * @w_cotizacion,0),0)
                     end
                     
                     select  @w_procesa = 'N'
                     select @w_div_vigente =  isnull(max(di_dividendo),0) + 1
                     from ca_dividendo 
                     where di_operacion =  @w_re_operacion
                     and di_estado = 1

                     if  @w_div_vigente > 1
                      begin
                         select  @w_procesa = 'S'
                      end
                      else
                      begin
                         select @w_div_vigente  =  isnull(max(di_dividendo),0) 
                         from ca_dividendo 
                         where di_operacion =  @w_re_operacion
                         and di_estado = 2
                         
                         if  @w_div_vigente <> 0
                             select  @w_procesa = 'S'
                                
                       end
         
                 PRINT 'recalas.sp @w_procesa  @w_diff' + @w_procesa + @w_diff
                 
                 if  @w_procesa = 'S' and @w_diff > 0
                  begin

                   --Insertar en la tabla  ca_otro_cargo, ca_amortizacion y ca_rubro_op
         
                     exec   @w_secuencial = sp_gen_sec
                             @i_operacion  = @w_re_operacion
            
                     exec  sp_historial
                          @i_operacionca = @w_re_operacion,
                          @i_secuencial  = @w_secuencial
            
                     insert into ca_otro_cargo
                            (oc_operacion,     oc_fecha,          oc_secuencial,
                             oc_concepto,      oc_monto,          oc_referencia,
                             oc_usuario,       oc_oficina,        oc_terminal,
                             oc_estado,        oc_div_desde,
                             oc_div_hasta,     oc_base_calculo,   oc_secuencial_cxp) 
                     values( @w_re_operacion,     @i_fecha_proceso,   @w_secuencial,
                             @w_concepto_ioc , @w_diff,      @w_comentario,
                             @i_user,         @i_ofi,             @i_term,
                             'A',             @w_div_vigente ,
                             @w_div_vigente ,    0,   @w_secuencial)
                       

                     insert into ca_rubro_op
                           (ro_operacion,            ro_concepto,        ro_tipo_rubro,
                            ro_fpago,                ro_prioridad,       ro_paga_mora,
                            ro_provisiona,           ro_signo,           ro_factor,
                            ro_referencial,          ro_signo_reajuste,  ro_factor_reajuste,
                            ro_referencial_reajuste, ro_valor,           ro_porcentaje,
                            ro_porcentaje_aux,       ro_gracia,          ro_concepto_asociado,
                            ro_principal,            ro_porcentaje_efa,  ro_garantia,
                            ro_saldo_op,             ro_saldo_por_desem, ro_base_calculo,
                            ro_num_dec)
                    values ( @w_re_operacion,          @w_concepto_ioc, 'M',
                            'A',                                       0,       'S',
                            'N',           '+',      0,
                            null,          '+',      0,
                            null,                    @w_diff,            @w_ro_porcentaje,
                            @w_re_nuevo_porcentaje,  0,                  null,
                            'N',                     @w_ro_porcentaje,   0,
                            'N',                     'N',                0,
                            @w_num_dec )
            
                        ---ca_amortizacion
            

                      
                      select @w_di_estado = di_estado
                      from ca_dividendo
                      where di_operacion =  @w_re_operacion
                      and di_dividendo = @w_div_vigente

                                  
                     insert into ca_amortizacion
                           (am_operacion,   am_dividendo,  am_concepto,
                            am_estado,      am_periodo,    am_cuota,
                            am_gracia,      am_pagado,     am_acumulado,
                            am_secuencia)
                     values(@w_re_operacion, @w_div_vigente, @w_concepto_ioc,
                            @w_di_estado,              0,             @w_diff,
                            0,              0,             @w_diff,
                            1)  


                  --insertar el detalle de la transacción
                    select @w_codvalor = (co_codigo * 1000) + (@w_di_estado * 10)
                     from   ca_concepto
                     where  co_concepto = @w_concepto_ioc
                     
                     insert into ca_det_trn
                           (dtr_secuencial, dtr_operacion,    dtr_dividendo,
                            dtr_concepto,
                            dtr_estado,     dtr_periodo,      dtr_codvalor,
                            dtr_monto,      dtr_monto_mn,     dtr_moneda,
                            dtr_cotizacion, dtr_tcotizacion,  dtr_afectacion,
                            dtr_cuenta,     dtr_beneficiario, dtr_monto_cont)
                     values(@w_secuencial,  @w_re_operacion,   @w_div_vigente, 
                            @w_concepto_ioc,
                            @w_di_estado,   0,                @w_codvalor,
                            @w_monto_uvr,   @w_monto_mn,         @w_op_moneda,
                            @w_cotizacion,  '',               'D',
                            '',             @w_comentario,    0)
               
                  ----insertar la transaccion
                  insert into ca_transaccion
                        (tr_secuencial,       tr_fecha_mov,         tr_toperacion,
                         tr_moneda,           tr_operacion,         tr_tran,
                         tr_en_linea,         tr_banco,             tr_dias_calc,
                         tr_ofi_oper,         tr_ofi_usu,           tr_usuario,        
                         tr_terminal,         tr_fecha_ref,         tr_secuencial_ref, 
                         tr_estado,           tr_gerente,           tr_gar_admisible,      
                         tr_reestructuracion, tr_calificacion,	  tr_observacion,      
                         tr_fecha_cont, 		tr_comprobante)
                  values(@w_secuencial,       @i_fecha_proceso,              @w_toperacion,
                         @w_op_moneda,        @w_re_operacion,       'IOC',
                         'S',                 @w_banco,             0,
                         @w_oficina,          @i_ofi,               @i_user,       
                         @i_term,             @w_fecha_ult_proceso, 0,             
                         'ING',               @w_gerente,           isnull(@w_gar_admisible,''),        
                         @w_reestructuracion, @w_calificacion,     @w_comentario, 
                         @i_fecha_proceso,   0)
               end  --procesa = S para cuotas 1,2,3
               

            --actualización de las cuotas no vigentes estado 0
             select  @w_div_vigente   = isnull(max(di_dividendo),0)
             from ca_dividendo
             where di_operacion = @w_re_operacion
             and di_estado = 1
      
             PRINT 'recaltas.sp actualizacion de la tabla de amortizacio @w_div_vigente' + @w_div_vigente
             if @w_div_vigente    > 0
             begin
                update ca_amortizacion  
                set am_cuota = round(am_cuota *  @w_re_nuevo_porcentaje   / @w_ro_porcentaje,0),
                    am_acumulado = round(am_cuota *  @w_re_nuevo_porcentaje   / @w_ro_porcentaje,0)
                from ca_amortizacion
                where am_operacion = @w_re_operacion
                and  am_concepto =  @w_ro_concepto
                and  am_estado = 0
                and am_pagado = 0
                and am_cuota != 0
                and am_dividendo >  @w_div_vigente  
                
                ------------------------------------------------------------------------------
                ---- SE INSERTA EN ESTA TABLA PARA QUE AL MOMENTO DE EJECUTAR EL BATCH
                ---- Y POR EFECTOS DE FECHA VALRO O REVERSO LA OEPRACION ESTA ATRAS
                ---  SE DEBE REPROCESAR NUEVAMENTE LAS CUOTAS NO VIGENTES PARA MANTENER LA
                --   CONSISTENCIA DE ESTAS CUOTAS CON LA NUEVA TASA DE SEGUROS
                ------------------------------------------------------------------------------


               insert into ca_reproceso_en_fecha_valor
               (
               rfv_operacion,
               rfv_fecha_reproceso,
               rfv_dividendo
               )
               values
               (
               @w_re_operacion,
               @i_fecha_proceso,
               @w_div_vigente
               )
                
                
                -------------------------------------------------------------------------------
                ------- FIN DE INSERTAR EN LA TABLA
                -------------------------------------------------------------------------------
                 
                set rowcount 1
                select @w_valor_rubro = am_cuota
                from ca_amortizacion
                where am_operacion = @w_re_operacion
                and  am_dividendo =  @w_div_vigente  + 1
                and am_concepto = @w_ro_concepto
                set rowcount 0
                
                update ca_rubro_op
                set ro_porcentaje = @w_re_nuevo_porcentaje,
                    ro_porcentaje_efa =  @w_re_nuevo_porcentaje, 
                    ro_porcentaje_aux = @w_re_nuevo_porcentaje,
                    ro_valor          = @w_valor_rubro

                where ro_operacion = @w_re_operacion
                and ro_concepto =  @w_ro_concepto
             
                
                select @w_concepto_asociado = ro_concepto,
                       @w_por_asociado      = ro_porcentaje
                from ca_rubro_op
                where ro_operacion = @w_re_operacion
                and ro_concepto_asociado = @w_ro_concepto
                
                if @@rowcount > 0 ---RECALCULAR LOS IVAS DEL RUBRO
                begin
                     

                     insert into ca_reproceso_asociados
                     select  am_operacion,am_dividendo,am_concepto,am_cuota,@w_concepto_asociado,0
                     from ca_amortizacion
                     where am_operacion = @w_re_operacion
                     and am_concepto = @w_ro_concepto
                     and  am_estado != 3
                     and am_pagado = 0
                     and am_dividendo >  @w_div_vigente
                     
                     update ca_reproceso_asociados
                     set valor_rubro_asociado = round(valor_rubro *  @w_por_asociado /100 ,@w_num_dec)
                     where operacion = @w_re_operacion
                     and rubro = @w_ro_concepto
                     and rubro_asociado = @w_concepto_asociado
                     
                     update ca_amortizacion  
                     set am_cuota = valor_rubro_asociado,
                         am_acumulado = valor_rubro_asociado
                     from ca_amortizacion,
                           ca_reproceso_asociados
                     where am_operacion = @w_re_operacion
                     and  am_concepto =  @w_concepto_asociado
                     and am_operacion = operacion
                     and am_dividendo = dividendo
                     and  am_concepto = rubro_asociado
                     
 

                     
                      set rowcount 1
                      select @w_valor_aso = valor_rubro_asociado,
                             @w_base      = valor_rubro
                      from  ca_reproceso_asociados
                      where operacion = @w_re_operacion
                      and   rubro = @w_ro_concepto
                      set rowcount 0
                      
                      update  ca_rubro_op
                      set ro_valor = @w_valor_aso,
                          ro_base_calculo = @w_base 
                      where ro_operacion = @w_re_operacion
                      and   ro_concepto = @w_concepto_asociado
                      
                      delete ca_reproceso_asociados
                      where operacion >= 0
                  
                end ---RECALCULAR LOS IVAS DEL RUBRO
             end  --fin act los vigentes
       
            End ---(1) si las tasas son diferentes

            select @w_concepto_ioc = ''  
           --cursor dos  
          fetch   cursor_rubros_dos into
          @w_ro_concepto,
          @w_ro_porcentaje,
          @w_re_nuevo_porcentaje ,
          @w_concepto_ioc
          
         end --WHILE CURSOR RUBROS
         close cursor_rubros_dos
         deallocate cursor_rubros_dos
 
  --cursor uno   
 fetch   cursor_rubros_uno into
 @w_re_operacion
 
end --WHILE CURSOR RUBROS
close cursor_rubros_uno
deallocate cursor_rubros_uno

return 0
go
