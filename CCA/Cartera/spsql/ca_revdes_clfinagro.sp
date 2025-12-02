/************************************************************************/
/*   Archivo:             ca_revDES_clfinagro.sp                        */
/*   Stored procedure:    sp_reverso_des_cambiolfinagro                 */
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
/*   Hace fecha valor del desembolso a las operaciones que FINAGRO      */
/*   cargadas en una tabla  de nombre ca_proc_cam_linea_finagro         */
/*   Tambien retira la garantia de la operacion                         */
/*   AUTOR        FECHA        CAMBIO                                   */
/*   EPB          Enero.2015   Emision Inicial. NR 479 Bancamia         */
/*   Julian Mendi AGO.2015     ATSK-1060.                               */  
/*                             Se generan dos archivos para reportar los*/
/*                             Mensaje, uno para el usuario final y otro*/
/*                             para soporte tecnico.                    */
/************************************************************************/

/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_reverso_des_cambiolfinagro')
   drop proc sp_reverso_des_cambiolfinagro
go
SET ANSI_NULLS ON
GO
---Jul.30.2015
CREATE proc sp_reverso_des_cambiolfinagro
  @i_param1   datetime
as declare              
   @w_usuario           catalogo,
   @w_usuario1          login,
   @w_usuario2          login,      
   @w_term              catalogo,
   @w_error             int,
   @w_sp_name           varchar(64),
   @w_fecha             datetime,
   @w_sec_cons          int,
   @w_operacion         int,
   @w_banco             cuenta,
   @w_sec_des          int,
   @w_sec               int,
   @w_ofi               int,
   @w_fDES             catalogo,
   @w_foram_reversa_org  catalogo,
   @w_parametro_freverso catalogo,
   @w_fecha_cca          datetime,
   @w_msg                varchar(255),
   @w_fecha_des          datetime,
   @w_codValor           int,
   @w_fecha_ult_proceso  datetime,
   @w_garantia           cuenta
   
---USUARIO EXCLUSIVO PARA CAMBIO LINEA FINAGRO
select @w_usuario1 = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'USLIFI'
and   pa_producto = 'CCA'

select @w_usuario2 = @w_usuario1 + '_USR'
select @w_usuario  = @w_usuario1

---FORMA REVERSO DE PAGOS PARA CAMBIO DE LINEA
select @w_parametro_freverso = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'FREVER'
and   pa_producto = 'CCA'

select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select 
@w_sp_name           = 'sp_reverso_des_cambiolfinagro',
@w_fecha             = @i_param1,
@w_term              = 'BATCH_CCA',
@w_ofi               = 1

----SI NO HAY DATOS CARGADOS SIMPLEMENTE GENERE UN ERROR
if not exists ( select 1 from ca_proc_cam_linea_finagro)
begin
  select @w_msg = 'ca_revdes_clinfiangro.sp -> NO SE HA CARGADO DATOS EN LA TABLA ca_proc_cam_linea_finagro'
  goto ERROR_FINAL
end

---SELECCION DE LAS OPERACIONES A REVERSION DE PAGOS

create table  #rev_DES_cambinFINAgro (
 operacion       int    not null, 
 banco           cuenta not null,
 fecha_des       datetime not null,
 sec_des         int      not null
) 

---VALIDACION FORMA DE REVERSO QUE EXISTA PARAMETRIZADA
select @w_codValor = cp_codvalor
 from ca_producto
where cp_producto = @w_parametro_freverso
if @@rowcount = 0
begin
  select @w_msg = 'NO EXISTE FORMA DE REVERSO PARA CAMBIO DE LINEA FINAGRO'
  select @w_usuario  = @w_usuario2  
  goto ERROR
end

insert into #rev_DES_cambinFINAgro
select op_operacion,
       op_banco,
       tr_fecha_ref,
       tr_secuencial
from ca_proc_cam_linea_finagro,
     ca_operacion,
     ca_transaccion
where op_banco = pc_banco_cobis
and   pc_fecha_proc =   @w_fecha
and   tr_banco = op_banco
and   pc_estado <> 'P'
and   pc_reverso_pagos = 1 ---ya todos deben estar en 1
and   pc_reverso_desem = 0 ---todos los desembolsos que faltan
and   pc_retirar_gar   = 0
and   tr_tran = 'DES'
and   tr_estado <> 'RV'
and   tr_secuencial > 0
and   tr_usuario <> @w_usuario
if @@rowcount = 0
begin
  PRINT ''
  PRINT 'ATENCION NO HAY  DESEMBOLSOS PARA REVESAR SE PUEDE CONTINUAR '
  return 0
end
PRINT ''
PRINT 'DESEMBOLSOS A REVERSAR'
select * from #rev_DES_cambinFINAgro


select @w_operacion = 0
while 1 = 1 
begin

      set rowcount 1

      select @w_operacion = operacion,
             @w_banco     = banco,
             @w_fecha_des = fecha_des,
             @w_sec_des   = sec_des
      from #rev_DES_cambinFINAgro
      where operacion > @w_operacion
      order by operacion

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0
      ---Revisar la forma de pago para parametrizar la reversa con un reaplica
      select @w_fDES = dtr_concepto
       from ca_det_trn,ca_producto
      where dtr_operacion = @w_operacion
      and dtr_secuencial = @w_sec_des
      and dtr_concepto = cp_producto
      and cp_desembolso = 'S'
      

      exec @w_error = sp_fecha_valor 
      @s_date              = @w_fecha_cca,
      @s_user              = @w_usuario,
      @s_term              = @w_term,
      @i_fecha_valor       = @w_fecha_des,
      @i_banco             = @w_banco,
      @i_operacion         = 'F', ---F = FEcha_valor
      @i_observacion       = 'CAMBIO LINEA DE FINAGRO A OTRA',
      @i_en_linea          = 'N'
      
      if @w_error <> 0 
      begin
         select @w_msg = 'ERROR ENE FECHA VALOR DES, SEC,' + CAST( @w_sec_des AS VARCHAR)
         goto ERROR
      end                 
      ELSE
      begin
        select @w_fecha_ult_proceso = op_fecha_ult_proceso
        from ca_operacion
        where op_operacion = @w_operacion
      end
      
      if @w_fecha_ult_proceso = @w_fecha_des
      begin
         ---ACTAULIZAR LA TRANSACCION E INSERTAR LA TRN DE REVERSO
         insert into ca_transaccion(
         tr_secuencial,      tr_fecha_mov,    tr_toperacion,
         tr_moneda,          tr_operacion,    tr_tran,
         tr_en_linea,        tr_banco,        tr_dias_calc,
         tr_ofi_oper,        tr_ofi_usu,      tr_usuario,
         tr_terminal,        tr_fecha_ref,    tr_secuencial_ref,
         tr_estado,          tr_observacion,  tr_gerente,
         tr_calificacion,    tr_gar_admisible,tr_fecha_cont,
         tr_comprobante,     tr_reestructuracion,tr_fecha_real)
         select 
         -1 * tr_secuencial, @w_fecha_cca,    tr_toperacion,
         tr_moneda,          tr_operacion,    tr_tran, 
         tr_en_linea,        tr_banco,        tr_dias_calc,
         tr_ofi_oper,        tr_ofi_usu,      @w_usuario, 
         @w_term,            tr_fecha_ref,    tr_secuencial, 
         'ING',              'POR CAMBIO DE LINEA DE FINAGRO',  tr_gerente,
         tr_calificacion,    tr_gar_admisible,@w_fecha_cca,
         0,   tr_reestructuracion,   getdate()
         from   ca_transaccion 
         where  tr_operacion   = @w_operacion
         and    tr_secuencial  = @w_sec_des
         and    tr_tran        =  'DES'
         and    tr_estado      <>  'RV'
         
         if @@error <> 0  begin
            select @w_msg = 'ERROR INSERTARNDO TRANSACCION  DES, SEC,' + CAST( @w_sec_des AS VARCHAR)
            select @w_usuario  = @w_usuario2            
            goto ERROR
         end
         ---EL DETALLE DEL DESEMBOLSO
         insert into ca_det_trn (
         dtr_secuencial,      dtr_operacion,               dtr_dividendo,
         dtr_concepto,
         dtr_estado,          dtr_periodo,                 dtr_codvalor,
         dtr_monto,           dtr_monto_mn,                dtr_moneda,
         dtr_cotizacion,      dtr_tcotizacion,             dtr_afectacion,
         dtr_cuenta,          dtr_beneficiario,            dtr_monto_cont )
         select 
         -1*dtr_secuencial,   dtr_operacion,               dtr_dividendo,
         dtr_concepto,
         dtr_estado,          dtr_periodo,                 dtr_codvalor,
         dtr_monto,           dtr_monto_mn,                dtr_moneda,
         dtr_cotizacion,      isnull(dtr_tcotizacion,''),  dtr_afectacion,
         dtr_cuenta,          dtr_beneficiario,            0
         from   ca_det_trn
         where  dtr_operacion  = @w_operacion
         and    dtr_secuencial = @w_sec_des
         
         if @@error <> 0  begin
            select @w_msg = 'ERROR INSERTARNDO TRANSACCION  DES, SEC,' + CAST( @w_sec_des AS VARCHAR)
            select @w_usuario  = @w_usuario2            
            goto ERROR
         end
         
         update ca_det_trn
         set dtr_concepto = @w_parametro_freverso,
             dtr_codvalor = @w_codValor
         where  dtr_operacion  = @w_operacion
         and    dtr_secuencial = @w_sec_des *-1
         and    dtr_concepto   = @w_fDES
         if @@error <> 0  begin
            select @w_msg = 'ERROR INSERTARNDO DETALLE DE TRANSACCION' + CAST( @w_sec_des AS VARCHAR)
            select @w_usuario  = @w_usuario2            
            goto ERROR
         end
               
         update ca_transaccion
         set tr_estado = 'RV'
         where  tr_operacion  =  @w_operacion
         and    tr_secuencial = @w_sec_des
         and    tr_tran       =  'DES'
         and    tr_estado     <>  'RV'
   
         if @@error <> 0  begin
            select @w_msg = 'ERROR REVERSANDO TRANSACCION  DES, SEC,' + CAST( @w_sec_des AS VARCHAR)
            select @w_usuario  = @w_usuario2            
            goto ERROR
         end            
         
        ---RETIRAR LA GARANTIA
         select @w_garantia = gp_garantia
          from cob_custodia..cu_tipo_custodia,
               cob_custodia..cu_custodia,
               cob_credito..cr_gar_propuesta,
               ca_operacion
         where tc_descripcion like '%FAG%'
         and gp_tramite = op_tramite
         and op_banco = @w_banco
         and gp_garantia = cu_codigo_externo
         and tc_tipo = cu_tipo
         if @@rowcount <> 0
         begin   
              --- ACTUALIZA GARANTIA PROPUESTA 
               update cob_credito..cr_gar_propuesta
               set gp_est_garantia = 'A'
               where gp_garantia = @w_garantia
               if @@error <> 0  begin
                  select @w_msg = 'ERROR ACTUALIZANDO ESTADO DE GARANTIA ' + CAST(  @w_garantia AS VARCHAR)
                  select @w_usuario  = @w_usuario2                              
                  goto ERROR
               end            
               
            
               --- CANCELA GARANTIA
               update cob_custodia..cu_custodia
               set cu_fecha_modif        = @w_fecha_cca,
                   cu_fecha_modificacion = @w_fecha_cca,
                   cu_estado             = 'A'
               where cu_codigo_externo = @w_garantia
               if @@error <> 0  begin
                  select @w_msg = 'ERROR ACTUALIZANDO ESTADO DE GARANTIA EN CUSTODIA  ' + CAST(  @w_garantia AS VARCHAR)
                  select @w_usuario  = @w_usuario2                              
                  goto ERROR
               end                           
            
               --- ACTUALIZA OPERACION 
               update cob_cartera..ca_operacion
               set op_gar_admisible = 'N'
               where op_banco = @w_banco
               if @@error <> 0  begin
                  select @w_msg = 'ERROR ACTUALIZANDO OPERACION ' + CAST(  @w_banco  AS VARCHAR)
                  select @w_usuario  = @w_usuario2                                                
                  goto ERROR
               end                           
               
               ---REVISAR TABLA  DE RUBROS
               delete  ca_rubro_op
               where ro_operacion = @w_operacion
               and ro_concepto like '%FAG%'
               if @@error <> 0  begin
                  select @w_msg = 'ERROR DESIGNANDO RUBROS DE ' + CAST(  @w_banco  AS VARCHAR)
                  select @w_usuario  = @w_usuario2                                                                  
                  goto ERROR
               end                                          
               
               ---REVISAR TABLA  DE Amortizacion
               delete  ca_amortizacion
               where am_operacion = @w_operacion
               and am_concepto like '%FAG%'
               if @@error <> 0  begin
                  select @w_msg = 'ERROR DESIGNANDO RUBROS DE AMORTIZACION ' + CAST(  @w_banco  AS VARCHAR)
                  select @w_usuario  = @w_usuario2                    
                  goto ERROR
               end                
         end --RETIRAR GARANTIA
      end ---fechas OKKKK
      ELSE
      begin
         select @w_msg = ' ERROR OPERACION NO QUEDO A LA FECHA  ' + CAST(  @w_operacion  AS VARCHAR)
         select @w_usuario = @w_usuario2                             
         goto ERROR
      end
   
   goto SIGUIENTE
   
   ERROR:
      begin
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
             pc_reverso_desem = '0',
             pc_retirar_gar   = '0'
         where pc_banco_cobis = @w_banco
         and   pc_fecha_proc = @w_fecha
     
         if @@error <> 0  
            PRINT 'ERROR ACTUALIZACION ca_proc_cam_linea_finagro estado E  en el ERROR ' + cast (@w_banco as varchar)
 
                 
         goto SALIR
         
      end
   SIGUIENTE:
      update ca_proc_cam_linea_finagro  
      set pc_reverso_desem  = '1',
          pc_retirar_gar    = '1',
          pc_estado         = 'I'
      where pc_banco_cobis = @w_banco
      and   pc_fecha_proc = @w_fecha
      if @@error <> 0  
        PRINT 'ERROR ACTUALIZACION ca_proc_cam_linea_finagro estado I  en el  ERROR ' + cast (@w_banco as varchar)
      
      
  SALIR:
  PRINT 'Va el Siguiente Registro para  Realizar pago'
        
end
print ''
print ''
print ' REVISAR ESTADO DE LOS DESEMBOLSOS'  
print ''
select banco,tr_tran,tr_secuencial,tr_estado,tr_fecha_ref,op_fecha_ult_proceso
from #rev_DES_cambinFINAgro,
     ca_transaccion,ca_operacion
where tr_operacion  = operacion
and   tr_secuencial = sec_des
and   tr_tran       = 'DES'
and   tr_operacion = op_operacion

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
