/************************************************************************/
/* Archivo            :    mover_op_cli.sp                              */
/* Stored procedure   :    sp_mover_op_cli                              */
/* Base de datos      :    cob_cartera                                  */
/* Producto           :    Cartera                                      */
/* Disenado por       :    RRB                                          */
/* Fecha de escritura :    2010-03-17                                   */
/************************************************************************/
/*                              IMPORTANTE                              */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* 'MACOSA', representantes exclusivos para el Ecuador de               */
/* AT&T GIS.                                                            */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier alteracion o agregado hecho por alguno de sus              */
/* usuarios sin el debido consentimiento por escrito de la              */
/* Presidencia Ejecutiva de MACOSA o su representante.                  */
/************************************************************************/
/*                               PROPOSITO                              */
/* Traslados de operaciones entre clientes                              */
/************************************************************************/
/*                            MODIFICACIONES                            */
/* FECHA       AUTOR                   RAZON                            */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_mover_op_cli')
  drop procedure sp_mover_op_cli
go

---INC. 115498 ABR.11.2014
create proc sp_mover_op_cli
as declare 
   @w_ident_origen  varchar(20),
   @w_ident_destino varchar(20),
   @w_banco         varchar(20),
   @w_clien_origen  int,
   @w_clien_destino int,
   @w_operacion     int,
   @w_tramite       int,
   @w_fecha_sb      datetime,
   @w_fecha_proceso datetime,
   @w_errortxt      varchar(100),
   @w_nombre_dest   varchar(254),
   @w_apellidos_hoy varchar(32),
   @w_nombre_hoy    varchar(254),
   @w_usuario       varchar(20),
   @w_path          varchar(250),
   @w_cmd           varchar(250),
   @w_s_app         varchar(250),
   @w_destino       varchar(250),
   @w_errores       varchar(250),
   @w_comando       varchar(250),
   @w_error         int,
   @w_err_up        varchar(250),
   @w_msg           varchar(100),
   @w_return        int,
   @w_subtipo       char(1),
   @w_grupo         int,
   @w_debug         char(1)

SET ANSI_WARNINGS OFF      
truncate table mover_masivo_op_cliente
select @w_err_up = ''
select @w_error  = 0
select @w_debug = 'N'

select @w_s_app   = pa_char from cobis..cl_parametro where pa_producto = 'ADM' and   pa_nemonico = 'S_APP'
select @w_path    = 'F:\VBatch\Cartera\Listados\'

select @w_cmd     = @w_s_app + 's_app bcp -auto -login cob_cartera..mover_masivo_op_cliente in '
select @w_destino = @w_path + 'mover_masivo_op_cliente' + '.txt', @w_errores  = @w_path + 'mover_masivo_op_cliente' + '.err'
select @w_comando = @w_cmd + @w_path + 'mover_masivo_op_cliente.txt -b5000 -c -e' + @w_errores + ' -t";" ' + '-config '+ @w_s_app + 's_app.ini'
exec   @w_error   = xp_cmdshell @w_comando
if @w_error <> 0 begin
   return 724537
end   

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
select @w_fecha_sb      = dateadd(dd, -datepart(dd,@w_fecha_proceso), @w_fecha_proceso) + 1

-- VALIDACION TIPO DE CAMBIO SOLICTADO

select tipo = mmc_accion, registros=count(1)
into #validacion
from mover_masivo_op_cliente
group by mmc_accion

-- Validar un solo tipo de actualizacion

if @@rowcount <> 2 begin
   select @w_error = 724537
   return @w_error
end

-- TRASLADO OPERATIVO -- 
        
while 1 = 1 begin -- Clientes

   -- Carga de variables
   
   set rowcount 1
   
   select @w_clien_origen = mmc_cliente,
          @w_ident_origen = mmc_ced_ruc,
          @w_usuario      = mcc_autoriza,
          @w_subtipo      = en_subtipo,
          @w_grupo        = mmc_grupo
   from mover_masivo_op_cliente, cobis..cl_ente
   where  isnull(substring(mmc_estado,1,1),'I') <> 'P'
   and    mmc_accion  = 'borrar'
   and    mmc_cliente = en_ente
   order by mmc_cliente
  
   if @@rowcount = 0 begin
      set rowcount 0
      break
   end

   set rowcount 0
   
   if @w_debug = 'S' begin
      print 'Cliente a Procesar: ' + cast(@w_clien_origen as varchar)
   end
   
   select @w_clien_destino = mmc_cliente, 
          @w_ident_destino = mmc_ced_ruc,
          @w_nombre_dest   = en_nomlar
   from cobis..cl_ente, mover_masivo_op_cliente
   where mmc_grupo      = @w_grupo
   and   en_ente        = mmc_cliente
   and   mmc_accion     = 'correcto'
        
   -- Validar que el cliente Exista
   
   if @w_clien_origen = 0 or @w_clien_destino = 0 begin
      select @w_errortxt = 'Error !!! por favor validar que el cliente origen y cliente destino existan'
      select @w_error = 1
      goto ERROR
   end

   -- Validar que la operacion exista
   
   if @w_operacion = 0 or @w_tramite = 0 begin
      select @w_errortxt = 'Error !!! por favor validar que la operacion exista o posea nuero de tramite'
      select @w_error = 1
      goto ERROR
   end
   
   -- Actualizar Detalle de Cliente y Producto
   
   select dp_prod=dp_det_producto
   into #detalles
   from cobis..cl_cliente, cobis..cl_det_producto
   where cl_cliente = @w_clien_origen
   and   cl_det_producto = dp_det_producto

   update cobis..cl_det_producto set
   dp_cliente_ec = @w_clien_destino
   from #detalles
   where dp_det_producto = dp_prod
   and   dp_cliente_ec   = @w_clien_origen
   
   if @@rowcount = 0 print 'Por favor verifique Detalle de Producto'
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 2, convert(varchar(20),dp_prod)
   from  #detalles, cobis..cl_det_producto
   where dp_det_producto = dp_prod 
   
   update cobis..cl_cliente set
   cl_cliente = @w_clien_destino
   where cl_cliente = @w_clien_origen
   
   if @@rowcount = 0 print 'Por favor verifique Detalle de Cliente'


   ---cob_credito..cr_aseg_microseguro
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 21, am_microseg
   from cob_credito..cr_aseg_microseguro
   where am_identificacion = @w_ident_origen
      
   if @@rowcount <> 0 
   begin

	   update cob_credito..cr_aseg_microseguro set
	   am_identificacion = @w_ident_destino,
	   am_nombre_comp    = @w_nombre_dest
	   where am_identificacion  = @w_ident_origen
        if @@rowcount <> 0 
	        print 'Actualiza cob_credito..cr_aseg_microseguro'
   end   
   
   --- cob_credito..cr_benefic_micro_aseg
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 21, bm_microseg
   from cob_credito..cr_benefic_micro_aseg
   where bm_identificacion = @w_ident_origen
      
   if @@rowcount <> 0 
   begin

	   update cob_credito..cr_benefic_micro_aseg set
	   bm_identificacion = @w_ident_destino,
	   bm_nombre_comp    = @w_nombre_dest
	   where bm_identificacion  = @w_ident_origen
        if @@rowcount <> 0 
	        print 'Actualiza cob_credito..cr_benefic_micro_aseg'
   end      
   
   --- cob_credito..cr_asegurados
   
    insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 21, as_secuencial_seguro
   from cob_credito..cr_asegurados
   where as_ced_ruc = @w_ident_origen
      
   if @@rowcount <> 0 
   begin
       ---sacar los paellidos aparte para esta actualizacion
         select  @w_apellidos_hoy  = p_p_apellido + ' ' + p_s_apellido,
               @w_nombre_hoy     = en_nombre
		 from cobis..cl_ente with (nolock)
		 where en_ced_ruc = @w_ident_destino ---ya se actualizo en cl_ente

	    update cob_credito..cr_asegurados set
	    as_ced_ruc      = @w_ident_destino,
	    as_apellidos    = @w_apellidos_hoy,
	    as_nombres      = @w_nombre_hoy
	    where as_ced_ruc  = @w_ident_origen
        if @@rowcount <> 0 
	        print 'Actualiza cob_credito..cr_asegurados'
	        
	    update cob_credito..cr_beneficiarios
	    set be_ced_ruc   = @w_ident_destino,
	        be_apellidos = @w_apellidos_hoy,
	        be_nombres   = @w_nombre_hoy
	    where be_ced_ruc  = @w_ident_origen
        if @@rowcount <> 0 
	        print 'Actualiza cob_credito..cr_asegurados'
	        
   end      
   
   -- Log 
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 21, convert(varchar(20),tr_tramite)
   from cob_credito..cr_tramite
   where tr_cliente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   print 'Inserto log y actualizara cr_tramite '
	      
	   update cob_credito..cr_tramite set
	   tr_cliente = @w_clien_destino,
	   tr_nombre  = @w_nombre_dest
	   where tr_cliente = @w_clien_origen
   end   
   
   --segmento
   if not exists (select 1 from cobis..cl_mercado_objetivo_cliente
                   where mo_ente = @w_clien_destino)
   begin
		update cobis..cl_mercado_objetivo_cliente
		set  mo_ente = @w_clien_destino
		where mo_ente   = @w_clien_origen
        if @@rowcount <> 0 
	        print 'Actualiza cobis..cl_mercado_objetivo_cliente'
		
	end
  --campanas
   update  cob_credito..cr_cliente_campana
   set cc_cliente = @w_clien_destino
   where cc_cliente = @w_clien_origen
   if @@rowcount <> 0 
       print 'Actualiza cob_credito..cr_cliente_campana'

   -- Deudores
   
   update cob_credito..cr_deudores set
   de_cliente = @w_clien_destino,
   de_ced_ruc = @w_ident_destino
   where de_cliente = @w_clien_origen
   if @@rowcount <> 0
       print 'Actualizo cr_eudores'

   -- Garantias
   -- Log 

   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 19, gp_garantia
   from  cob_credito..cr_gar_propuesta
   where gp_deudor = @w_clien_origen
   
   if @@rowcount <> 0 
   begin
	   update cob_credito..cr_gar_propuesta set
	   gp_deudor = @w_clien_destino
	   where gp_deudor = @w_clien_origen
	   if @@rowcount <> 0
	      print 'lleno Log Garantías Propuestas y actualizo'      
   end
   
         
   -- Actualizar Operacion

   -- Log 
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 7, op_banco
   from cob_cartera..ca_operacion
   where op_cliente = @w_clien_origen
   
   if @@rowcount = 0 
	   print 'Lleno Log' 
	
   select oph=op_operacion, sech=tr_secuencial
   into #historico
   from ca_operacion, ca_transaccion, ca_operacion_his
   where op_operacion  = oph_operacion
   and   tr_operacion  = oph_operacion
   and   tr_secuencial = oph_secuencial
   and   op_cliente    = @w_clien_origen
   
   update cob_cartera..ca_operacion set
   op_cliente = @w_clien_destino,
   op_nombre  = @w_nombre_dest
   where op_cliente = @w_clien_origen
   
   if @@rowcount = 0 print 'Por favor verifique Operacion' 
   
   update cob_cartera_his..ca_operacion set
   op_cliente = @w_clien_destino,
   op_nombre  = @w_nombre_dest
   where op_cliente = @w_clien_origen
   
   if @@rowcount = 0 print 'Por favor verifique Base Histórica de Operaciones '  
   
   update cob_cartera..ca_operacion_his set
   oph_cliente = @w_clien_destino,
   oph_nombre  = @w_nombre_dest
   from cob_cartera..ca_operacion_his , #historico
   where oph_operacion  = oph
   and   oph_secuencial = sech
   
   if @@rowcount = 0 print 'Por favor verifique Historicos de Operacion'
   
   -- Relacion Cliente
   update cobis..cl_instancia set 
   in_ente_i = @w_clien_destino
   where in_ente_i = @w_clien_origen 
   
   if @@rowcount = 0 print 'No hay dato en  cobis..cl_instancia i'
   
   update cobis..cl_instancia set 
   in_ente_d = @w_clien_destino
   where in_ente_d = @w_clien_origen
   
   if @@rowcount = 0 print 'No hay dato en  cobis..cl_instancia d'     
   
   ---Pasivas UPD
   --- Log  cob_ahorros_ah_cuenta
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 4, ah_cta_banco
   from cob_ahorros..ah_cuenta
   where ah_cliente = @w_clien_origen
   if @@rowcount <> 0 
   begin
   
	   update cob_ahorros..ah_cuenta
	   set ah_cliente = @w_clien_destino,
	       ah_ced_ruc = @w_ident_destino,
	       ah_nombre  = @w_nombre_dest
	   where ah_cliente = @w_clien_origen
	   
	   if @@rowcount <> 0 print 'actualizo cob_ahorros_ah_cuenta'     
  end
  
   --- cob_ahorros_ah_tran_monet
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 4, tm_cta_banco
   from  cob_ahorros..ah_tran_monet
   where tm_cliente = @w_clien_origen
   if @@rowcount <> 0 
   begin
    
    update cob_ahorros..ah_tran_monet
    set tm_cliente = @w_clien_destino
    where tm_cliente = @w_clien_origen
    if @@rowcount <> 0 print 'actualizo cob_ahorros_ah_tran_monet'     
    
   end
   
   --- cob_ahorros_ah_tran_servicio
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 4, ts_cta_banco
   from  cob_ahorros..ah_tran_servicio
   where ts_cliente = @w_clien_origen
   if @@rowcount <> 0 
   begin
    
    update cob_ahorros..ah_tran_servicio
    set ts_cliente = @w_clien_destino,
        ts_ced_ruc = @w_ident_destino
    where ts_cliente = @w_clien_origen
    if @@rowcount <> 0 print 'actualizo cob_ahorros_ah_tran_servicio'  

    end
    
  --- cob_ahorros_his..ah_his_servicio
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 4, hs_cta_banco
   from  cob_ahorros_his..ah_his_servicio,
         cob_ahorros..ah_cuenta
   where hs_cliente = @w_clien_origen
   and   hs_cta_banco = ah_cta_banco 
   and   hs_cliente   = ah_cliente
   if @@rowcount <> 0 
   begin
    
    update cob_ahorros_his..ah_his_servicio
    set hs_cliente = @w_clien_destino,
        hs_ced_ruc = @w_ident_destino
   from  cob_ahorros_his..ah_his_servicio,
         cob_ahorros..ah_cuenta
   where hs_cliente = @w_clien_origen
   and   hs_cta_banco = ah_cta_banco 
   and   hs_cliente   = ah_cliente
    if @@rowcount <> 0 print 'actualizo cob_ahorros_his..ah_his_servicio'  

    end
   
   --- cob_ahorros_his..ah_his_movimiento
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 4, hm_cta_banco
    from cob_ahorros..ah_cuenta,
         cob_ahorros_his..ah_his_movimiento
    where hm_cliente = @w_clien_origen
    and hm_cta_banco = ah_cta_banco
    and ah_cliente = hm_cliente
   if @@rowcount <> 0 
   begin
    
    update cob_ahorros_his..ah_his_movimiento
    set hm_cliente = @w_clien_destino
    from cob_ahorros..ah_cuenta,
         cob_ahorros_his..ah_his_movimiento
    where hm_cliente = @w_clien_origen
    and hm_cta_banco = ah_cta_banco
    and ah_cliente = hm_cliente
    if @@rowcount <> 0 print 'actualizo cob_ahorros_his..ah_his_movimiento'  

    end   
   
   
   ---cob_ahorros..ah_estado_cta
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 4, ec_cta_banco
   from  cob_ahorros..ah_estado_cta
   where ec_cliente  = @w_clien_origen
   if @@rowcount <> 0 
   begin
   update cob_ahorros..ah_estado_cta
   set ec_cliente = @w_clien_destino,
   	   ec_nombre  = @w_nombre_dest,
   	   ec_ced_ruc = @w_ident_destino
   where ec_cliente = @w_clien_origen
   if @@rowcount <> 0 print 'actualizo cob_ahorros_his..ah_estado_cta'
   
   end
   

   ---cob_ahorros..ah_tran_rechazos
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 4, tr_cta_banco
   from  cob_ahorros..ah_tran_rechazos
   where tr_cod_cliente  = @w_clien_origen
   if @@rowcount <> 0 
   begin
   update cob_ahorros..ah_tran_rechazos
   set tr_cod_cliente = @w_clien_destino,
   	   tr_nom_cliente  = @w_nombre_dest,
   	   tr_id_cliente = @w_ident_destino
   where tr_cod_cliente = @w_clien_origen
   if @@rowcount <> 0 print 'actualizo cob_ahorros_his..ah_tran_rechazos'
   
   end
   
   
   --cob_cuentas..cc_ctacte
   ----------------------------------------
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 3, cc_cta_banco
   from cob_cuentas..cc_ctacte
   where cc_cliente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_cuentas..cc_ctacte
	   set cc_cliente  = @w_clien_destino,
	       cc_ced_ruc  = @w_ident_destino,
	       cc_nombre   = @w_nombre_dest
	   where cc_cliente = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_cuentas..cc_ctacte'     
   end
   
   
   ---cob_remesas..re_relacion_cta_canal
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 10, rc_cuenta
   from cob_remesas..re_relacion_cta_canal
   where rc_cliente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_remesas..re_relacion_cta_canal
	   set rc_cliente  = @w_clien_destino
	   where rc_cliente = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_remesas..re_relacion_cta_canal'     
   end   
   
   ---cob_remesas..re_archivo_alianza
      insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 10, ar_archivo
   from cob_remesas..re_archivo_alianza
   where ar_cliente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_remesas..re_archivo_alianza
	   set ar_cliente        = @w_clien_destino,
	       ar_identificacion = @w_ident_destino
	   where ar_cliente = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_remesas..re_archivo_alianza'     
   end   

   
   ---cob_remesas..re_cabecera_transfer
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 10, ct_cuenta
   from cob_remesas..re_cabecera_transfer
   where ct_cliente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_remesas..re_cabecera_transfer
	   set ct_cliente        = @w_clien_destino,
	       ct_identificacion = @w_ident_destino
	   where ct_cliente = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_remesas..re_cabecera_transfer'     
   end  

   
   ---cob_remesas..re_detalle_transfer
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 10, dt_cuenta
   from cob_remesas..re_detalle_transfer
   where dt_cliente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_remesas..re_detalle_transfer
	   set dt_cliente        = @w_clien_destino,
	       dt_identificacion = @w_ident_destino
	   where dt_cliente = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_remesas..re_detalle_transfer'     
   end  
   

   ---cob_remesas..re_gmf_alianza
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 10, gm_cuenta
   from cob_remesas..re_gmf_alianza
   where gm_cliente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_remesas..re_gmf_alianza
	   set gm_cliente        = @w_clien_destino
	   where gm_cliente = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_remesas..re_gmf_alianza'     
   end  
   
   ---cob_remesas..re_orden_caja

   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 10, oc_idorden
   from cob_remesas..re_orden_caja
   where oc_cliente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_remesas..re_orden_caja
	   set oc_cliente = @w_clien_destino,
	       oc_numdoc  = @w_ident_destino
	   where oc_cliente = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_remesas..re_orden_caja'     
   end  
   
   ---pfijo

   
   --- cob_pfijo..pf_operacion
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 14, op_num_banco
   from cob_pfijo..pf_operacion
   where op_ente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_pfijo..pf_operacion
	   set op_ente         = @w_clien_destino,
	       op_ced_ruc      = @w_ident_destino,
	       op_descripcion  = @w_nombre_dest
	   where op_ente = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_pfijo..pf_operacion'     
   end
   
   ---- cob_pfijo..pf_det_pago

   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 14, dp_operacion
   from cob_pfijo..pf_det_pago
   where dp_ente = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_pfijo..pf_det_pago
	   set dp_ente         = @w_clien_destino
	   where dp_ente = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_pfijo..pf_det_pago'     
   end
   
   ----cob_pfijo..pf_det_pago_tmp
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 14, dt_operacion
   from cob_pfijo..pf_det_pago_tmp
   where dt_beneficiario = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_pfijo..pf_det_pago_tmp
	   set dt_beneficiario  = @w_clien_destino,
 	       dt_descripcion   = @w_nombre_dest
	   where dt_beneficiario = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_pfijo..pf_det_pago_tmp'     
   end 
   
   --- cob_pfijo..pf_mov_monet
   
  insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 14, mm_operacion
   from cob_pfijo..pf_mov_monet
   where mm_beneficiario = @w_clien_origen
      
   if @@rowcount <> 0 
   begin
	   update cob_pfijo..pf_mov_monet
	   set mm_beneficiario  = @w_clien_destino
	   where mm_beneficiario = @w_clien_origen       
	   if @@rowcount <> 0 print 'actualizo cob_pfijo..pf_mov_monet'     
   end 

   ---servicios bancarios
  --- se modifica por cedula por que el ente no se almacena real se pone un codigo
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 42, pn_cod_operacion
   from cob_sbancarios..sb_productos_neg
   where pn_id =  @w_ident_origen
   
   if @@rowcount <> 0 
   begin
	   update  cob_sbancarios..sb_productos_neg
	   set pn_beneficiario  = @w_nombre_dest,
	       pn_id            = @w_ident_destino
	   where pn_id =  @w_ident_origen
	   if @@rowcount <> 0 
	       print 'actualizo  cob_sbancarios..sb_productos_neg'
   end 
  
   
   --- cob_sbancarios..sb_operacion
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 42, op_trm
   from cob_sbancarios..sb_operacion
   where op_cod_cliente =  @w_clien_origen
   
   if @@rowcount <> 0 
   begin
	   update  cob_sbancarios..sb_operacion
	   set op_cod_cliente  = @w_clien_destino
	   where op_cod_cliente =  @w_clien_origen
	   if @@rowcount <> 0 
	       print 'actualizo  cob_sbancarios..sb_operacion'
   end

      
   ---- cob_sbancarios..sb_clientes
   
   
   insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 42, cl_id
   from cob_sbancarios..sb_clientes
   where cl_cod_cliente =  @w_clien_origen
   
   if @@rowcount <> 0 
   begin
	   update  cob_sbancarios..sb_clientes
	   set cl_cod_cliente = @w_clien_destino,
	       cl_id          = @w_ident_destino,
	       cl_nombre      = @w_nombre_dest
	   where cl_cod_cliente =  @w_clien_origen
	   if @@rowcount <> 0 
	       print 'actualizo  cob_sbancarios..sb_clientes'
   end
   
   --- cob_sbancarios..sb_gmf
   
     insert into cobis..cl_depu_log
   select @w_fecha_proceso, @w_usuario, @w_clien_origen, @w_clien_destino, 42, gm_cod_operacion
   from cob_sbancarios..sb_gmf
   where gm_cod_cliente =  @w_clien_origen
   
   if @@rowcount <> 0 
   begin
	   update  cob_sbancarios..sb_gmf
	   set gm_cod_cliente = @w_clien_destino
	   where gm_cod_cliente =  @w_clien_origen
	   if @@rowcount <> 0 
	       print 'actualizo  cob_sbancarios..sb_gmf'
   end
   
  ---Fin Pasivas
  ----------------------------------------------------
   
   -- Log de clientes a borrar 
   
   if not exists (select 1 from cobis..cl_depu_ente where den_ente = @w_clien_origen) begin
      insert into cobis..cl_depu_ente
      select
      en_ente,               en_nombre,         en_subtipo,            en_filial,               en_oficina,           en_ced_ruc,           en_fecha_crea,
      en_fecha_mod,          en_direccion,      en_referencia,         en_casilla,              en_casilla_def,       en_tipo_dp,           en_balance, 
      en_grupo,              en_pais,           en_oficial,            en_actividad,            en_retencion,         en_mala_referencia,   en_comentario,
      en_cont_malas,         s_tipo_soc_hecho,  en_tipo_ced,           en_sector,               en_referido,          en_nit,               en_doc_validado,
      en_rep_superban,       p_p_apellido,      p_s_apellido,          p_sexo,                  p_fecha_nac,          p_ciudad_nac,         p_lugar_doc,
      p_profesion,           p_pasaporte,       p_estado_civil,        p_num_cargas,            p_num_hijos,          p_nivel_ing,          p_nivel_egr,
      p_nivel_estudio,       p_tipo_persona,    p_tipo_vivienda,       p_calif_cliente,         p_personal,           p_propiedad,          p_trabajo,
      p_soc_hecho,           p_fecha_emision,   p_fecha_expira,        c_cap_suscrito,          en_asosciada,         c_posicion,           c_tipo_compania,
      c_rep_legal,           c_activo,          c_pasivo,              c_es_grupo,              c_capital_social,     c_reserva_legal,      c_fecha_const,
      en_nomlar,             c_plazo,           c_direccion_domicilio, c_fecha_inscrp,          c_fecha_aum_capital,  c_cap_pagado,         c_tipo_nit,
      c_tipo_soc,            c_total_activos,   c_num_empleados,       c_sigla,                 c_escritura,          c_notaria,            c_ciudad,
      c_fecha_exp,           c_fecha_vcto,      c_camara,              c_registro,              c_grado_soc,          c_fecha_registro,     c_fecha_modif,
      c_fecha_verif,         c_vigencia,        c_verificado,          c_funcionario,           en_situacion_cliente, en_patrimonio_tec,    en_fecha_patri_bruto,
      en_gran_contribuyente, en_calificacion,   en_reestructurado,     en_concurso_acreedores,  en_concordato,        en_vinculacion,       en_tipo_vinculacion,
      en_oficial_sup,        en_cliente,        en_preferen,           c_edad_laboral_promedio, c_empleados_ley_50,   en_exc_sipla,         en_exc_por2,
      en_digito,             p_depa_nac,        p_pais_emi,            p_depa_emi,              en_categoria,         en_emala_referencia,  en_banca,
      c_total_pasivos,       en_pensionado,     en_rep_sib,            en_max_riesgo,           en_riesgo,            en_mries_ant,         en_fmod_ries,
      en_user_ries,          en_reservado,      en_pas_finan,          en_fpas_finan,           en_fbalance,          en_relacint,          en_otringr,
      en_exento_cobro,       en_doctos_carpeta, en_oficina_prod,       en_accion,               en_procedencia,       en_fecha_negocio,     en_estrato,
      en_recurso_pub,        en_influencia,     en_persona_pub,        en_victima,              en_bancarizado
      from cobis..cl_ente
      where en_ente = @w_clien_origen
      
      insert into cobis..cl_depu_direccion (
      ddi_ente,        ddi_direccion,      ddi_descripcion,
      ddi_parroquia,   ddi_ciudad,         ddi_tipo,
      ddi_telefono,    ddi_sector,         ddi_zona,
      ddi_oficina,     ddi_fecha_registro, ddi_fecha_modificacion,
      ddi_vigencia,    ddi_verificado,     ddi_funcionario,
      ddi_fecha_ver,   ddi_principal,      ddi_barrio,
      ddi_provincia,   ddi_tienetel,       ddi_rural_urb,
      ddi_observacion)
      select 
      di_ente,          di_direccion,       di_descripcion,
      di_parroquia,     di_ciudad,          di_tipo,
      di_telefono,      di_sector,          di_zona,
      di_oficina,       di_fecha_registro,  di_fecha_modificacion,
      di_vigencia,      di_verificado,      di_funcionario,
      di_fecha_ver,     di_principal,       di_barrio,
      di_provincia,     di_tienetel,        di_rural_urb,
      di_observacion
      from cobis..cl_direccion
      where di_ente = @w_clien_origen

      insert into cobis..cl_depu_telefono
      select
      te_ente,          te_direccion, te_secuencial,     te_valor,
      te_tipo_telefono, te_prefijo,   te_fecha_registro, te_fecha_mod
      from cobis..cl_telefono
      where te_ente = @w_clien_origen
   end
   
   -- Eliminar Cliente
   exec @w_return = cobis..sp_elim_ente 
   @s_ssn     = 1,
   @s_user    = 'sa',
   @s_term    = 'term',
   @s_srv     = 'serv',
   @s_lsrv    = 'lserv',
   @t_trn     = 1248,
   @i_ente    = @w_clien_origen,
   @i_subtipo = @w_subtipo,
   @i_conta   = 'N'   
   
   if @w_return <> 0 begin
      select @w_errortxt = 'Error en Borrado de Cliente ' + convert(varchar(10),@w_return)
      select @w_error = 1
      goto ERROR
   end   
   
   update mover_masivo_op_cliente set
   mmc_estado = 'P'
   where  mmc_accion  = 'borrar'
   and    mmc_cliente = @w_clien_origen

   update mover_masivo_op_cliente set
   mmc_estado = 'P'
   where  mmc_accion  = 'correcto'
   and    mmc_cliente = @w_clien_destino
   
-- TRASLADO CONTABLE -- Siempre se ejecuta -- el procesp valida que tenga saldos, si no los tiene no realiza traslado.

   -- Carga de variables
   
   set rowcount 1
   select @w_clien_origen = mmc_cliente,
          @w_ident_origen = mmc_ced_ruc
   from mover_masivo_op_cliente
   where  isnull(substring(mmc_estado,1,1),'I') <> 'C'
   and    mmc_accion  = 'borrar'
   and    mmc_grupo = @w_grupo
   order by mmc_cliente
  
   if @@rowcount = 0 begin
      set rowcount 0
      break
   end
   
   set rowcount 0
   
   if @w_debug = 'S' begin
      print 'Cliente a Procesar Contabilidad: ' + cast(@w_clien_origen as varchar) 
   end
   
   select @w_clien_destino = mmc_cliente
   from mover_masivo_op_cliente
   where mmc_accion      = 'correcto'
   and   mmc_grupo       = @w_grupo
   
   if @w_debug = 'S' begin
      print 'Identificacion cliente origen'
      print @w_ident_origen
      print 'cliente destino'
      print @w_clien_destino
   end
   -- Traslado Contable
   update cob_conta_tercero..ct_sasiento set
   sa_ente = @w_clien_destino
   where sa_ente = @w_clien_origen
   
   if @@error <> 0 begin
      set rowcount 0
      select @w_error = 1
      GOTO ERROR
   end

   /*** TABLAS TRANSACCIONALES ***/

   update cob_conta_tercero..ct_sasiento set
   sa_ente = @w_clien_destino
   where sa_ente = @w_clien_origen
   
   if @@error <> 0 begin
      set rowcount 0
      select @w_errortxt = 'Error en cob_conta_historico..ct_sasiento'
      select @w_error = 1
      GOTO ERROR
   end
   
   update cob_conta..cb_retencion set
   re_ente = @w_clien_destino
   where re_ente = @w_clien_origen
   
   if @@error <> 0 begin
      select @w_errortxt = 'Error en cob_conta_historico..cb_retencion'
      set rowcount 0
      select @w_error = 1
      GOTO ERROR
   end
   
   if @w_debug = 'S' begin
      print 'cliente origen'
      print @w_clien_origen
      print 'cliente destino'
      print @w_clien_destino
   end
   
   select
   st_empresa,                      st_periodo,         st_corte,
   st_cuenta,                       st_oficina,         st_area,
   st_ente = @w_clien_destino,      st_saldo,           st_saldo_me,
   st_mov_debito,                   st_mov_credito,     st_mov_debito_me,
   st_mov_credito_me
   into #saldo_tercero
   from cob_conta_tercero..ct_saldo_tercero
   where st_ente in (@w_clien_origen, @w_clien_destino)
   
   if @@error <> 0 begin
      select @w_errortxt = 'Error en Generacion de trasalado Contable (Revisar ca_errorlog)'
      set rowcount 0
      select @w_error = 1
      GOTO ERROR
   end
   
   delete cob_conta_tercero..ct_saldo_tercero
   where st_ente in (@w_clien_origen, @w_clien_destino)

   if @@error <> 0 begin
      select @w_errortxt = 'Error en cob_conta_tercero..ct_saldo_tercero'
      set rowcount 0
      select @w_error = 1
      GOTO ERROR
   end

   insert into cob_conta_tercero..ct_saldo_tercero
   select
   st_empresa,                st_periodo,                st_corte,
   st_cuenta,                 st_oficina,                st_area,
   st_ente,                   sum(st_saldo),             sum(st_saldo_me),
   sum(st_mov_debito),        sum(st_mov_credito),       sum(st_mov_debito_me),
   sum(st_mov_credito_me)
   from #saldo_tercero
   group by st_empresa, st_periodo, st_corte, st_cuenta,
            st_oficina, st_area, st_ente

   if @@error <> 0 begin
      select @w_errortxt = 'Error en cob_conta_tercero..ct_saldo_tercero definitivo'
      set rowcount 0
      select @w_error = 1
      GOTO ERROR
   end

   /*** TABLAS HISTORICO ***/
   update cob_conta_tercero..ct_sasiento set
   sa_ente = @w_clien_destino
   where sa_ente = @w_clien_origen
   
   if @@error <> 0 begin
      set rowcount 0
      select @w_errortxt = 'Error en cob_conta_historico..ct_sasiento'
      select @w_error = 1
      GOTO ERROR
   end

   ERROR:
   if @w_error = 1 begin
      select 'ERROR: ', @w_errortxt
      
      update mover_masivo_op_cliente set
      mmc_estado = 'C'
      where  mmc_accion  = 'borrar'
      and    mmc_cliente = @w_clien_origen

      update mover_masivo_op_cliente set
      mmc_estado = 'C'
      where  mmc_accion  = 'correcto'
      and    mmc_cliente = @w_clien_destino
      
      return 1
   end
   
   update mover_masivo_op_cliente set
   mmc_estado = 'P ' + @w_errortxt
   where mmc_cliente = @w_clien_origen
   and   mmc_accion  = 'borrar'
   
   drop table #detalles
   drop table #historico
   drop table #saldo_tercero
end -- Contabilidad

return 0

go
