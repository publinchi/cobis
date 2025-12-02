/************************************************************************/
/*   Archivo:             ca_PagoComFinagro.sp                          */
/*   Stored procedure:    sp_pago_comision_finagro                       */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez Burbano                         */
/*   Fecha de escritura:  Ene.2015                                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/************************************************************************/
/*   Este proceso hace un pago a la operacion que se le cambio la linea */
/*   de FINGRO por otra , este pago va directo a CAPITAL                */
/*   con una forma de pago especial                                     */
/************************************************************************/
/*   AUTOR        FECHA        CAMBIO                                   */
/*   EPB          Enero.2015   Emision Inicial. NR 479 Bancamia         */
/*   Julian Mendi AGO.2015     ATSK-1060.                               */  
/*                             Se generan dos archivos para reportar los*/
/*                             Mensaje, uno para el usuario final y otro*/
/*                             para soporte tecnico.                    */
/*   G. Fernandez 20/10/2021             Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_pago_comision_finagro')
   drop proc sp_pago_comision_finagro
go

SET ANSI_NULLS ON
GO
---Jul.30.2015          
CREATE proc sp_pago_comision_finagro
  @i_param1   datetime
as declare              
   @w_usuario           login,
   @w_usuario1          login,
   @w_usuario2          login,      
   @w_term              catalogo,
   @w_error             int,
   @w_sp_name           varchar(64),
   @w_fecha             datetime,
   @w_sec_cons          int,
   @w_operacion         int,
   @w_banco             cuenta,
   @w_ofi               int,
   @w_fecha_cca         datetime,
   @w_msg               varchar(255),
   @w_linea_des         catalogo,
   @w_dt_naturaleza     char(1),
   @w_dt_tipo           char(1),
   @w_dt_tipo_linea     catalogo,
   @w_dt_subtipo_linea  catalogo,
   @w_fpago_devcomFAG   catalogo,
   @w_valorCom          money,
   @w_secuencial        int,
   @w_numero_recibo     int,
   @w_cuota_completa    char(1),
   @w_aceptar_anticipos char(1),
   @w_prep_desde_lavig  char(1),
   @w_fecha_ult_proceso datetime,
   @w_moneda            tinyint,
   @w_cotizacion_mpg    money,
   @w_cotizacion_hoy    money,
   @w_moneda_nacional   smallint,
   @w_oficina           smallint,
   @w_tipo_cobro        char(1),
   @w_sec_ing           int,
   @w_secuencial_new    int,
   @w_parametro_freverso catalogo
   
   
---USUARIO EXCLUSIVO PARA CAMBIO LINEA FINAGRO
select @w_usuario1 = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'USLIFI'
and   pa_producto = 'CCA'

select @w_usuario2 = @w_usuario1 + '_USR'
select @w_usuario  = @w_usuario1

select @w_fpago_devcomFAG = pa_char
from   cobis..cl_parametro 
where  pa_producto = 'CCA' 
and    pa_nemonico = 'DEVFAG'

---FORMA REVERSO DE PAGOS PARA CAMBIO DE LINEA 
---CON ESTA MISMA SE DEBEN VOLVER A APLICAR
select @w_parametro_freverso = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'FREVER'
and   pa_producto = 'CCA'

   
select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select 
@w_sp_name           = 'sp_pago_comision_finagro',
@w_fecha             = @i_param1,
@w_term              = 'BATCH_CCA',
@w_ofi               = 1,
@w_valorCom          = 0

----SI NO HAY DATOS CARGADOS SIMPLEMENTE GENERE UN ERROR
if not exists ( select 1 from ca_proc_cam_linea_finagro)
begin
  select @w_msg = 'ca_pagocomfiangro.sp --> NO SE HA CARGADO DATOS EN LA TABLA ca_proc_cam_linea_finagro'
  goto ERROR_FINAL
end

---TABLAS DE TRABAJO
truncate table ca_abono_rev_pag
truncate table sec_pago_rv

select op_operacion,
       op_banco,
       'valorCom'= sum(isnull(pc_monto_comision,0) + isnull(pc_iva_comision,0))
into #PAgoComisionFinagro   
from ca_proc_cam_linea_finagro,
     ca_operacion
where op_banco = pc_banco_cobis
and   pc_fecha_proc = @w_fecha
and   pc_reverso_pagos = '1' 
and   pc_reverso_desem = '1' 
and   pc_retirar_gar   = '1'
and   pc_cambio_linea  = '1'
and   pc_desembolso    = '1'
and   pc_aplica_pagos  =  '0'
and   pc_estado        <> 'P'
group by op_operacion,op_banco
order by op_operacion,op_banco
select @w_operacion = 0
while 1 = 1 
begin

      set rowcount 1

      select @w_operacion = op_operacion,
             @w_banco     = op_banco,
             @w_valorCom  =  isnull(valorCom,0)
      from #PAgoComisionFinagro
      where op_operacion > @w_operacion
      order by op_operacion

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0
      
      ---REGISTRO PAGO
      ---  LECTURA DE LA OPERACION VIGENTE 
      select 
      @w_moneda                  = op_moneda,
      @w_fecha_ult_proceso       = op_fecha_ult_proceso,
      @w_cuota_completa          = op_cuota_completa,
      @w_aceptar_anticipos       = op_aceptar_anticipos,
      @w_tipo_cobro              = op_tipo_cobro,
      @w_prep_desde_lavig        = op_prepago_desde_lavigente,
      @w_oficina                 = op_oficina
      from  ca_operacion, ca_estado
      where op_banco             = @w_banco
      and   op_estado            = es_codigo
      and   es_acepta_pago       = 'S'
      
      
      if @w_valorCom >  0 
      begin ---Si tiene Comision
      
         ---  DETERMINAR EL VALOR DE COTIZACION DEL DIA / MONEDA OPERACION 
         if @w_moneda = @w_moneda_nacional
            select @w_cotizacion_hoy = 1.0
         else begin
            exec sp_buscar_cotizacion
            @i_moneda     = @w_moneda,
            @i_fecha      = @w_fecha_ult_proceso,
            @o_cotizacion = @w_cotizacion_hoy output
         end
         
         ---  VALOR COTIZACION MONEDA DE PAGO 
         exec sp_buscar_cotizacion
         @i_moneda     = @w_moneda,
         @i_fecha      = @w_fecha_ult_proceso,
         @o_cotizacion = @w_cotizacion_mpg output
         
         ---  GENERAR EL SECUENCIAL DE INGRESO     
         exec @w_secuencial = sp_gen_sec
         @i_operacion       = @w_operacion
         
         if @w_secuencial  =  0  or @w_secuencial is null
          begin
            select @w_msg = 'ERROR GENERANDO SECUENCIAL PAGO ' + CAST( @w_banco AS VARCHAR)
            goto ERROR
         end
         
         
         ---GENERAL NRO. RECIBO
         exec @w_error  = sp_numero_recibo
         @i_tipo    = 'P',
         @i_oficina = @w_oficina,
         @o_numero  = @w_numero_recibo out
            
         if @w_error  <> 0 
          begin
            select @w_msg = 'ERROR GENERANDO SECUENCIAL DEL RECIBO DE PAGO ' + CAST( @w_secuencial AS VARCHAR)
            goto ERROR
         end
         
   
         ---  INSERCION DE CA_ABONO 
         insert into ca_abono 
         (
         ab_operacion,          ab_fecha_ing,          ab_fecha_pag,            
         ab_cuota_completa,     ab_aceptar_anticipos,  ab_tipo_reduccion,            
         ab_tipo_cobro,         ab_dias_retencion_ini, ab_dias_retencion,     
         ab_estado,             ab_secuencial_ing,     ab_secuencial_rpa,
         ab_secuencial_pag,     ab_usuario,            ab_terminal,             
         ab_tipo,               ab_oficina,            ab_tipo_aplicacion,           
         ab_nro_recibo,         ab_tasa_prepago,       ab_dividendo,          
         ab_prepago_desde_lavigente                                      
         )                                                               
         values                                                          
         (                                                               
         @w_operacion,          @w_fecha_ult_proceso,          @w_fecha_ult_proceso,            
         @w_cuota_completa,     @w_aceptar_anticipos,  'N',            
         @w_tipo_cobro,         0,                     0,                     
         'ING',                 @w_secuencial,         0,
         0,                     @w_usuario,            @w_term,                 
         'PAG',                 @w_oficina,            'C',           
         @w_numero_recibo,      0,                     0,          
         @w_prep_desde_lavig                    
         )                                             
         
         if @@error <> 0  begin
            select @w_msg = 'ERROR INSERTARNDO ABONO ' + CAST(  @w_banco AS VARCHAR)
            goto ERROR
         end
         
         ---  INSERCION DE CA_DET_ABONO                
         insert into ca_abono_det                      
         (                                             
         abd_secuencial_ing,    abd_operacion,         abd_tipo,                 
         abd_concepto,          abd_cuenta,            abd_beneficiario,             
         abd_monto_mpg,         abd_monto_mop,         abd_monto_mn,          
         abd_cotizacion_mpg,    abd_cotizacion_mop,    abd_moneda,
         abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,               
         abd_cod_banco,         abd_solidario                                      --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
         )                                             
         values                                        
         (                                             
         @w_secuencial,         @w_operacion,          'PAG',                    
         @w_fpago_devcomFAG,    '',                    'DEV. DE COMISION/IVA EN CAMBIO LINEA FIN',   
         @w_valorCom,           @w_valorCom,           @w_valorCom,          
         @w_cotizacion_mpg,     @w_cotizacion_hoy,     @w_moneda,
         'N',                   'N',                   0,                
         '',                    'N'
         )
         if @@error <> 0  begin
            select @w_msg = 'ERROR INSERTARNDO ABONO DETALLE ' + CAST( @w_banco AS VARCHAR)
            goto ERROR
         end
   
         ---  INSERTAR PRIORIDADES 
         insert into ca_abono_prioridad
         (ap_secuencial_ing, ap_operacion, ap_concepto, ap_prioridad)
         select @w_secuencial, @w_operacion, ro_concepto, ro_prioridad
         from   ca_rubro_op
         where  ro_operacion = @w_operacion
         and    ro_fpago not in ('L','B')
         
         if @@error <> 0  begin
            select @w_msg = 'ERROR INSERTANDO PRIORIDAD  ' + CAST( @w_banco AS VARCHAR)
            goto ERROR
         end
      
            
         --- PONER LA PRIORIDADES QUE TIENE 0 EN 1    
         update ca_abono_prioridad
         set ap_prioridad = 1
         where ap_operacion  = @w_operacion
         and ap_prioridad = 0
         if @@error <> 0  begin
            select @w_msg = 'ERROR MODIFICACION PRIORIDAD A 1  ' + CAST( @w_banco AS VARCHAR)
            goto ERROR
         end
         --- PONER LA PRIORIDAD 0 A CAPITAL PARA QUE SOLO PAGUE CAPITAL
          
         update ca_abono_prioridad
         set ap_prioridad = 0
         where ap_operacion  = @w_operacion
         and ap_concepto = 'CAP'
         if @@error <> 0  begin
            select @w_msg = 'ERROR MODIFICACION PRIORIDAD A 0  ' + CAST( @w_banco AS VARCHAR)
            goto ERROR
         end
      end ---ojoooooooooooo

   ---HABILITAR EL PAGO ESTABA EN RV
   
   if exists (select 1 from  ca_transaccion
              where tr_operacion = @w_operacion
              and tr_tran ='PAG'
              and tr_estado = 'RV'
              and tr_observacion like '%CAMBIO LINEA DE FINAGRO A OTRA%' )
   begin  ---Existian pagos y estan en RV
      insert into sec_pago_rv
      select tr_operacion, ab_secuencial_ing
       from ca_transaccion,ca_abono
      where tr_operacion  = @w_operacion
      and tr_tran ='PAG'
      and tr_estado = 'RV'
      and tr_observacion like '%CAMBIO LINEA DE FINAGRO A OTRA%'
      and ab_operacion = tr_operacion
      and ab_secuencial_pag = tr_secuencial
      
      if @@error <> 0  
      begin
         select @w_msg = 'ERROR INSERTANDO SECUENCIAL REVERSO ' 
         goto ERROR
      end      
      
 
      insert into ca_abono_rev_pag
      select 
      ab_secuencial_ing         ,ab_secuencial_rpa         ,ab_secuencial_pag         ,ab_operacion              ,
      ab_fecha_ing              ,ab_fecha_pag              ,ab_cuota_completa         ,ab_aceptar_anticipos      ,
      ab_tipo_reduccion         ,ab_tipo_cobro             ,ab_dias_retencion_ini     ,ab_dias_retencion         ,
      ab_estado                 ,ab_usuario                ,ab_oficina                ,ab_terminal               ,
      ab_tipo                   ,ab_tipo_aplicacion        ,ab_nro_recibo             ,ab_tasa_prepago           ,
      ab_dividendo              ,ab_calcula_devolucion     ,ab_prepago_desde_lavigente,ab_extraordinario
      from ca_abono
      where ab_operacion in (select pag_oper from sec_pago_rv)
      and  ab_secuencial_ing in (select sec_ing from sec_pago_rv)
      
      if @@error <> 0  
      begin
         select @w_msg = 'ERROR INSERTANDO ABONO REVERSO PAGO ' 
         goto ERROR
      end
      
      
      select @w_sec_ing = 0
      while 1 = 1 
      begin
               set rowcount 1
               select @w_sec_ing = ab_secuencial_ing
               from ca_abono_rev_pag
               where ab_secuencial_ing  > @w_sec_ing
               and   ab_operacion = @w_operacion
               order by  ab_secuencial_ing  asc
         
               if @@rowcount = 0 begin
                  set rowcount 0
                  break
               end
         
               set rowcount 0      

               ---  GENERAR EL SECUENCIAL DE INGRESO     
               exec @w_secuencial_new = sp_gen_sec
               @i_operacion       = @w_operacion
               
               if @w_secuencial_new  =  0  or @w_secuencial_new is null
                begin
                  select @w_msg = 'ERROR GENERANDO SECUENCIAL NUEVO PARA PAGO' + CAST( @w_banco AS VARCHAR)
                  goto ERROR
               end
               
               ----INSERTAR EL MISMO PAGO PERO MODIFICAR ALGUNOS DATOS
               insert into ca_abono 
               select 
               @w_secuencial_new,  0,                 0,     ab_operacion,
               ab_fecha_ing,       ab_fecha_pag,      ab_cuota_completa,     ab_aceptar_anticipos,
               ab_tipo_reduccion,  ab_tipo_cobro,     ab_dias_retencion_ini, ab_dias_retencion,
               'ING',              @w_usuario,        ab_oficina,            @w_term,
               ab_tipo,            ab_tipo_aplicacion,ab_nro_recibo,         ab_tasa_prepago,
               ab_dividendo,       ab_calcula_devolucion,  ab_prepago_desde_lavigente,    ab_extraordinario, NULL, NULL, NULL
               from ca_abono
               where ab_operacion = @w_operacion
               and   ab_secuencial_ing = @w_sec_ing
               and   ab_estado = 'RV'
               if @@error <> 0  
               begin
                  select @w_msg = 'ERROR REGISTRANDO NUEVAMENTE EL PAGO ' + CAST( @w_banco AS VARCHAR)
                  goto ERROR
               end
                           
               insert into ca_abono_det  
               select                     
               @w_secuencial_new,   abd_operacion,       abd_tipo,          @w_parametro_freverso,
               abd_cuenta,         'REAPLICADO POR CAMBIO DE LINEA FIN',abd_moneda,          
               abd_monto_mpg,      abd_monto_mop,      abd_monto_mn,        abd_cotizacion_mpg,
               abd_cotizacion_mop, abd_tcotizacion_mpg,abd_tcotizacion_mop, abd_cheque,          
               abd_cod_banco,      abd_inscripcion,    abd_carga,           abd_porcentaje_con,
			   abd_secuencial_interfaces, 'N', NULL, NULL                                               --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
               from ca_abono_det
               where abd_operacion = @w_operacion
               and   abd_secuencial_ing = @w_sec_ing
               if @@error <> 0  
               begin
                  select @w_msg = 'ERROR REGISTRANDO NUEVAMENTE EL DETALLE DEL PAGO ' + CAST( @w_banco AS VARCHAR)
                  goto ERROR
               end 

               insert into ca_abono_prioridad
               select 
               @w_secuencial_new, ap_operacion, ap_concepto, ap_prioridad
               from ca_abono_prioridad
               where ap_operacion = @w_operacion
               and   ap_secuencial_ing = @w_sec_ing
               if @@error <> 0  begin
                  select @w_msg = 'ERROR INSERTARNDO NUEVAMENTE LA PRIORIDAD ' + CAST( @w_banco AS VARCHAR)
                  goto ERROR
               end
      end  ---while de pagos que se revesaron
   end --Existian pagos y estan en RV
  
   goto SIGUIENTE
   
      ERROR:
         begin
            if @w_error is null or @w_error = 0
               select @w_error = 710001
            print ''
            print ''
            print  @w_msg
            print ''
            print ''
            
            exec sp_errorlog 
            @i_fecha       = @w_fecha,
            @i_error       = @w_error,
            @i_usuario     = @w_usuario,
            @i_tran        = 7999,
            @i_tran_name   = @w_sp_name,
            @i_cuenta      = @w_banco,
            @i_descripcion = @w_msg,
            @i_rollback    = 'N'

            select @w_error = 0
            select @w_usuario = @w_usuario1
        
            update ca_proc_cam_linea_finagro  
            set pc_estado = 'E',
                pc_aplica_pagos = '0'
            where pc_banco_cobis = @w_banco
            and   pc_fecha_proc = @w_fecha
            
            if @@error <> 0  begin
               select @w_msg = 'ERROR ACTUALIZANDO ca_proc_cam_linea_finagro estado E' + CAST(  @w_banco AS VARCHAR)
               goto ERROR_FIN
             end            
            
            goto SALIR
         end
   
   SIGUIENTE:           
      update ca_proc_cam_linea_finagro  
      set pc_aplica_pagos = '1',
          pc_estado = 'I'
      where pc_banco_cobis = @w_banco
      and   pc_fecha_proc = @w_fecha
      
      if @@error <> 0  begin
         select @w_msg = 'ERROR ACTUALIZANDO ca_proc_cam_linea_finagro estado I' + CAST(  @w_banco AS VARCHAR)
         goto ERROR_FIN
       end            
      
         
  SALIR:
  PRINT 'Va el Siguiente Registro para  Realizar pago'
end

if exists (select 1 from ca_proc_cam_linea_finagro , ca_opera_finagro where pc_banco_cobis    = of_pagare and of_procesado <> 'L' and  pc_estado <> 'E')
begin
	--VERIFICANDO QUE LA LINEA DESTINO NO SEA FINAGRO
	select banco_cobis = pc_banco_cobis
	into #lin_des
	from ca_proc_cam_linea_finagro , ca_opera_finagro
	where pc_banco_cobis    = of_pagare
	and   pc_estado         <> 'E'
	and   pc_linea_destino  in(select c.codigo from cob_credito..cr_corresp_sib s, 
	                                                cobis..cl_tabla t, 
	                                                cobis..cl_catalogo c  
							                   where s.descripcion_sib = t.tabla   and t.codigo            = c.tabla
							                   and s.tabla             = 'T301'    and c.estado            = 'V')

	--ACTUALIZANDO TABLA MAESTRA DE OPERACIONES FINAGRO CUANDO EXISTE UN CAMBIO DE LINEA DE FINAGRO A UNA NO FINAGRO
	update ca_opera_finagro
	set of_procesado = 'L'   --CAMBIO DE LINEA
	from ca_proc_cam_linea_finagro, 
		 ca_opera_finagro a
	where pc_banco_cobis  = a.of_pagare
	and   a.of_pagare     not in (select banco_cobis from #lin_des)
	and   pc_estado       <> 'E'
	
   if @@error <> 0  begin
      select @w_msg = 'ERROR ACTUALIZACION GENERAL ca_opera_finagro procesado L'
      goto ERROR_FIN
    end            
	
end

ERROR_FIN:
   begin
      if @w_error is null or @w_error = 0
         select @w_error = 710001
      print ''
      print ''
      print  @w_msg
      
      exec sp_errorlog 
      @i_fecha       = @w_fecha,
      @i_error       = @w_error,
      @i_usuario     = @w_usuario,
      @i_tran        = 7999,
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = '',
      @i_descripcion = @w_msg,
      @i_rollback    = 'N'
      select @w_error = 0

      ---Todos quedarian con Error en este punto hasta que se revise por que no hay comisiones
      update ca_proc_cam_linea_finagro  
      set pc_estado = 'E',
          pc_aplica_pagos = '0'
      where pc_aplica_pagos = '0'
      and   pc_fecha_proc = @w_fecha
      
      if @@error <> 0  begin
         select @w_msg = 'ERROR ACTUALIZANDO ca_proc_cam_linea_finagro estado E en ERROR_FIN'
         goto ERROR_FINAL
       end            
      
   end

ERROR_FINAL:
  begin
      print cast(@w_msg as varchar(225))
      exec sp_errorlog 
      @i_fecha       = @w_fecha,
      @i_error       = 7999, 
      @i_tran        = null,
      @i_usuario     = @w_usuario, 
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = '',
      @i_rollback    = 'N',
      @i_descripcion = @w_msg ,
      @i_anexo       = @w_msg
      return 0
   end


return 0
 
go
