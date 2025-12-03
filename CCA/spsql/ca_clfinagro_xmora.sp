/************************************************************************/
/*   Nombre Fisico:       ca_clfinagro_xmora.sp                         */
/*   Nombre Logico:    	  sp_cambio_lfinagro_xmora                      */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Elcira Pelaez Burbano                         */
/*   Fecha de escritura:  AGO.2015                                      */
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
/*   cambio de línea de crédito de Liena finagro sustitutiva a Linea    */
/*   finagro agropecuaria segun parametro de mora                       */
/************************************************************************/
/*   AUTOR               FECHA        CAMBIO                            */
/*   EPB                 AGO.2015   Emision Inicial. NR 500 finagro     */
/*                                    Bancamia                          */
/*   M.Cordova	 		06/06/2023	  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_lfinagro_xmora')
   drop proc sp_cambio_lfinagro_xmora
go
SET ANSI_NULLS ON
GO
---AGO.12.2015
CREATE proc sp_cambio_lfinagro_xmora
  @i_param1   datetime
as declare              
   @w_usuario           catalogo,
   @w_term              catalogo,
   @w_error             int,
   @w_sp_name           varchar(64),
   @w_fecha             datetime,
   @w_operacion         int,
   @w_banco             cuenta,
   @w_fecha_cca         datetime,
   @w_msg               varchar(255),
   @w_FINMOR            int,
   @w_saldo_CAP         money,
   @w_linOrigen         catalogo,
   @w_linea_destino     catalogo,
   @w_LFINMO            catalogo,
   @w_est_op            smallint,
   @w_moneda            smallint,
   @w_cliente           int,
   @w_min_div_ven       smallint,
   @w_min_fecha_ven     datetime,
   @w_fecha_ult_proceso datetime,
   @w_dias_mora         smallint,
   @w_dt_naturaleza    char(1),
   @w_dt_subtipo_linea catalogo,
   @w_dt_tipo_linea    catalogo,
   @w_dt_tipo          char(1),
   @w_secuencial       int,
   @w_observacion      char(62),
   @w_calificacion     catalogo,
   @w_gar_admisible    char(1),
   @w_gerente          smallint,
   @w_oficina          int
   
---USUARIO EXCLUSIVO PARA CAMBIO LINEA FINAGRO
select @w_usuario = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'USLIFI'
and   pa_producto = 'CCA'

select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select 
@w_sp_name           = 'sp_cambio_lfinagro_xmora',
@w_fecha             = @i_param1,
@w_term              = 'BATCH_CCA'

select @w_FINMOR = pa_int
from cobis..cl_parametro 
where pa_nemonico in ('FINMOR')
and pa_producto = 'CCA'
if @@rowcount = 0 
begin
   select @w_msg =  'NO SE HA DEFINIDO EN CARTERA EL PARAMETRO GENERAL [FINMOR]'
   goto ERROR_FINAL
end

select @w_LFINMO = pa_char
from cobis..cl_parametro 
where pa_nemonico in ('LFINMO')
and pa_producto = 'CCA'
if @@rowcount = 0 
begin
   select @w_msg  = 'NO SE HA DEFINIDO EN CARTERA EL PARAMETRO GENERAL [LFINMO]'
   goto ERROR_FINAL
end

---VALIDAR EXISTENCIA DE LA LINEA DESTINO EN LAS TABLAS DE FINAGRO
select @w_linea_destino = c.codigo
from cob_credito..cr_corresp_sib s, 
cobis..cl_tabla t, 
cobis..cl_catalogo c  
where s.descripcion_sib = t.tabla
and t.codigo            = c.tabla
and s.tabla             = 'T301'
and s.codigo_sib        = 'A'
and c.codigo            = @w_LFINMO
and c.estado            = 'V'
if @@rowcount = 0 
begin
   select @w_msg =  'NO SE ENCUENTRA LINEA DESTINO PARA CAMBIO DE LINEA FIANGRO x MORA EN T301'
   goto ERROR_FINAL
end
---VALIDAR LA PARAMETRIZACION EN CARTERA
if not exists (select 1 from ca_default_toperacion 
           where dt_toperacion =  @w_linea_destino 
           and dt_estado  = 'V')
begin
      select @w_msg = 'LA LINEA DESTINO SE ENCUENTRA EN ESTADO NO VIGENTE  - ' + @w_linea_destino 
      goto ERROR_FINAL
end

 
---SE CARGAN SOLO LAS OPERACIONES QUE TENGAN CUOTAS VENCIDAS PARA PROCESAR
select distinct op_operacion oper
into #oper_proceso
from cob_cartera..ca_operacion with (nolock),
     cob_cartera..ca_estado with (nolock),
     cob_cartera..ca_dividendo with (nolock)
where op_operacion = di_operacion
and   di_estado = 2
and op_estado = es_codigo 
and   es_procesa = 'S'
and   op_toperacion in (select c. codigo
                       from cob_credito..cr_corresp_sib s, 
                            cobis..cl_tabla t, 
                            cobis..cl_catalogo c  
                       where s.descripcion_sib = t.tabla
                       and t.codigo            = c.tabla
                       and s.tabla             = 'T301'
                       and s.codigo_sib        = 'S'
                       and c.estado = 'V')

select @w_operacion = 0
while 1= 1
begin
    set rowcount 1
    
    select @w_operacion = oper,
           @w_banco     = op_banco,
           @w_linOrigen = op_toperacion,
           @w_est_op    = op_estado,
           @w_cliente   = op_cliente,
           @w_fecha_ult_proceso = op_fecha_ult_proceso,
           @w_gerente       = op_oficial,
           @w_gar_admisible = op_gar_admisible,
           @w_calificacion  = op_calificacion,
           @w_moneda        = op_moneda,
           @w_oficina       = op_oficina
    from  ca_operacion with (nolock),
          #oper_proceso
    where oper = op_operacion
    and  oper >  @w_operacion
    order by oper 

    if @@rowcount = 0 
    begin
       break
      set rowcount 0
   end
            
   set rowcount 0
   select @w_error = 0

   ---ENCONTRAR LOS DIAS DE MORA
   select @w_min_div_ven   = min(di_dividendo),
          @w_min_fecha_ven = min(di_fecha_ven)
   from ca_dividendo with (nolock)
   where di_operacion = @w_operacion
   and di_estado = 2
   
   if @w_min_div_ven > 0
   begin
        select @w_dias_mora = datediff(dd,@w_min_fecha_ven,@w_fecha_ult_proceso)
        
        if @w_dias_mora >= @w_FINMOR
        begin
            --- OBTENER RESPALDO ANTES DEL CAMBIO DE ESTADO 
            exec @w_secuencial = sp_gen_sec
            @i_operacion       = @w_operacion
            
            if @w_secuencial  <= 0 
              begin
                  select @w_msg =  'ERROR , NO SE GENERO EL SECUENCIAL PARA HISTORICO DE TRANSACCION - CLF '
                  goto ERROR_SIG
              end            
            
            exec @w_error    = sp_historial
            @i_operacionca   = @w_operacion,
            @i_secuencial    = @w_secuencial
            if @w_error <> 0 
              begin
                  select @w_msg =  'ERROR , GENERANDO HISTORIA DE LA OPERACION:  '+ cast ( @w_banco as varchar)
                  goto ERROR_SIG
              end            
            
           ---DATOS DE LA LINEA DESTINO
            select 
            @w_dt_naturaleza    = dt_naturaleza, 
            @w_dt_tipo          = dt_tipo,       
            @w_dt_tipo_linea    = dt_tipo_linea, 
            @w_dt_subtipo_linea = dt_subtipo_linea 
            from ca_default_toperacion
            where dt_toperacion = @w_linea_destino

            --- ACTUALIZACION DE LOS DATOS DE LA OPERACION
            update ca_operacion
            set
            op_toperacion         = @w_linea_destino,
            op_tipo               = @w_dt_tipo,
            op_tipo_linea         = @w_dt_tipo_linea,
            op_subtipo_linea      = @w_dt_subtipo_linea,
            op_naturaleza         = @w_dt_naturaleza,
            op_codigo_externo     = null,
            op_margen_redescuento = 0
            where op_operacion = @w_operacion
            if @@error <> 0
            begin
               select @w_msg =  'ERROR ACTUALIZANDO ca_operacion :' + cast ( @w_banco as varchar)
               goto ERROR_SIG               
            end                               
            
           
            select @w_observacion = 'CAMBIO ENTRE LINEA FINAGRO ' +  @w_linOrigen + '  POR ' + @w_linea_destino
            select @w_saldo_CAP = 0
            select @w_saldo_CAP = isnull(sum(am_acumulado - am_pagado),0)
            from ca_amortizacion
            where am_operacion = @w_operacion
            and am_concepto = 'CAP'
            and am_estado <> 3
            
            -- PARTE CONTABLE 

            insert into ca_transaccion (
                   tr_secuencial,       tr_fecha_mov,       tr_toperacion,
                   tr_moneda,           tr_operacion,       tr_tran,
                   tr_en_linea,         tr_banco,           tr_dias_calc,
                   tr_ofi_oper,         tr_ofi_usu,         tr_usuario,
                   tr_terminal,         tr_fecha_ref,       tr_secuencial_ref,
                   tr_estado,           tr_observacion,     tr_gerente,
                   tr_comprobante,      tr_fecha_cont,      tr_gar_admisible,
                   tr_reestructuracion, tr_calificacion,    tr_fecha_real     )
            values (
                   @w_secuencial,       @w_fecha_cca,       @w_linea_destino,
                   @w_moneda,           @w_operacion,        'CLF',  
                   'N',                 @w_banco,           1,
                   @w_oficina,          @w_oficina,          @w_usuario,
                   @w_term,             @w_fecha_ult_proceso, 0,
                   'NCO',               @w_observacion,     @w_gerente,
                   0,                   '',                isnull(@w_gar_admisible,''),
                   'S',                 isnull(@w_calificacion,''), getdate()
                   )
               if @@error <> 0
               begin
                  select @w_msg =  'ERROR INSERTANDO  EN ca_transaccion LA TRANSACCION CLF: ' + cast ( @w_banco as varchar)
                  goto ERROR_SIG               
               end                               
         
               ---REGSITRO DEL DETALLE UNICAMENTE PRA EL REPROTE f127
               ---ESTE DETALLE NO ES CONTABILIZABLE
               if @w_saldo_CAP > 0
               begin
                  insert into ca_det_trn
                        (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                         dtr_concepto,       dtr_estado,     dtr_periodo,
                         dtr_codvalor,       dtr_monto,      dtr_monto_mn,
                         dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                         dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                         dtr_monto_cont)
                  values(@w_secuencial,      @w_operacion,   1,
                         'CAP',              @w_est_op,      0,
                         10010,              @w_saldo_CAP,    @w_saldo_CAP,
                         @w_moneda,          1,              'N',
                         'D',               '00000',         'CLF',
                         0.00)
                  
                  if @@error <> 0
                  begin
                     select @w_msg =  'ERROR INSERTANDO  DETALLE SOLO ca_det_trn PARA F127: ' + cast ( @w_banco as varchar)
                     goto ERROR_SIG               
                  end  
               end                             

           insert into ca_oper_cambio_linea_x_mora
          (cl_sec_tran,
           cl_banco,
           cl_ccliente,
           cl_linea_origen,
           cl_linea_destino,
           cl_estado,
           cl_fecha,
           cl_fecha_upd)
           values (
           @w_secuencial,
           @w_banco,
           @w_cliente,
           @w_linOrigen,
           @w_linea_destino,
           'I',  ---se ACTUALIZARA CUANDO SE ENVIE EL CORREO
           @w_fecha,
           @w_fecha)
           
           if @@error <> 0 
           begin
               select @w_msg =  'NO SE INSERTO DATOS EN LA TABLA ca_oper_cambio_linea_x_mora ' + cast ( @w_banco as varchar)
               goto ERROR_SIG
           end
           ---ALIMENTAR LA TALBA PARA REPORTE F126-F127
              exec @w_error = cob_cartera..sp_finagro 
              @i_fecha       = @w_fecha_cca,
              @i_banco       = @w_banco,
              @i_operacion   = 'L'   
              
              if @w_error <> 0 
              begin
                 select @w_msg =  'ERROR AL MODIFICAR DATOS POR CAMBIO DE LINEA FINAGRO'
                 goto ERROR_SIG
              end

           ---FIN ALIMENTAR DATOS PARA F126-F127
        end ---CUMPLE CON LOS DIAS DE MORA DEL PARAMTRO
     
        ---INSERTAR LA TRANSACCION DE CAMBIO DE LINEA 
   end ----CONB DIAS DE MORA 
   
   
   
   ---ENVIA AL SIGUIENTE REGSITRO
   goto SIGUIENTE   
   
   ERROR_SIG:
   begin
      if @w_error is null or @w_error = 0
         select @w_error = 7999
      exec sp_errorlog 
      @i_fecha       = @w_fecha_cca,
      @i_error       = @w_error,
      @i_usuario     = @w_usuario,
      @i_tran        = 7999,
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = @w_banco,
      @i_descripcion = @w_msg,
      @i_anexo       = @w_msg,
      @i_rollback    = 'N'
   
       SIGUIENTE:
       PRINT 'OPERACION QUE VA ' + cast ( @w_banco as varchar) +  ' DIAS MORA ' + cast ( @w_dias_mora as varchar) 
   end
   
                     
end ---while 1= 1

return 0

ERROR_FINAL:
  begin
      PRINT ''
      print  'LLEGO A INSERTAR ERROR ' +  @w_msg
      exec sp_errorlog 
      @i_fecha       = @w_fecha,
      @i_error       = 7999, 
      @i_tran        = null,
      @i_usuario     = @w_usuario, 
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = '',
      @i_rollback    = 'N',
      @i_descripcion = @w_msg,
      @i_anexo       = @w_msg
      return 0
   end

go
