/************************************************************************/
/*      Archivo:                ca_des_camlinfin.sp                     */
/*      Stored procedure:       sp_des_camlinfin                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               COBIS-CARTERA                           */
/*      Disenado por:           Luis Guzman                             */
/*      Fecha de escritura:     16-Ene-15                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes  exclusivos  para el  Ecuador  de la   */
/*      'NCR CORPORATION'.                                              */
/*      Su  uso no autorizado  queda expresamente  prohibido asi como   */
/*      cualquier   alteracion  o  agregado  hecho por  alguno de sus   */
/*      usuarios   sin el debido  consentimiento  por  escrito  de la   */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este programa realiza el desembolo del cambio de linea para las */
/*      operaciones devueltas por finagro.                              */
/****************************************************************************/
/*                              MODIFICACIONES                              */
/*      FECHA           AUTOR      RAZON                                    */
/*  2015-04-13    Julian Mendigaña Se elimina obligatoriedad de co          */
/*                                 mision FAG                               */
/*  01/06/2015    Acelis           INC 1187 NR 479                          */
/*  AGO.2015      Julian MC        ATSK-1060.                               */  
/*                                 Se generan dos archivos para reportar los*/
/*                                 Mensaje, uno para el usuario final y otro*/
/*                                 para soporte tecnico.                    */
/****************************************************************************/

use cob_cartera
go

SET ANSI_NULLS ON
GO

if exists (select 1 from sysobjects where name = 'sp_des_camlinfin')
   drop proc sp_des_camlinfin
go
---JUL.30.2015
create proc sp_des_camlinfin
@i_param1 datetime    -- Fecha de proceso

as
declare
   @w_sp_name            varchar(32),
   @w_msg                varchar(250),
   @w_error              int,
   @w_fecha              datetime,   
   @w_operacionca        int,
   @w_banco              cuenta,
   @w_secuencial_tran    int,
   @w_sec_desembolso     int,
   @w_comfagd            catalogo,
   @w_ivacomfagd         catalogo,
   @w_parametro_freverso varchar(10),
   @w_forma_desembolso   varchar(10),
   @w_codigo_valor       smallint,  
   @w_nue_linea          catalogo,
   @w_debitos            money,
   @w_creditos           money,
   @w_monto_comision     money,
   @w_iva_comision       money,
   @w_us_finagro         login,
   @w_us_finagro1        login,
   @w_us_finagro2        login,   
   @w_fecha_cartera      datetime,
   @w_sec_dm_desembolso  smallint,
   @w_numero_desembolsos smallint

set nocount on   

/*INICIALIZA VARIABLES*/
select @w_sp_name         = 'sp_des_camlinfin',
       @w_fecha           =  @i_param1,
       @w_secuencial_tran =  null,
       @w_error           =  708153,
	   @w_operacionca     =  null

/* EVALUA PARAMETROS GENERALES */

/*FECHA DE CIERRE DE CARTERA*/
select @w_fecha_cartera = fc_fecha_cierre 
from cobis..ba_fecha_cierre 
where fc_producto = 7

if @@rowcount = 0 or @w_fecha_cartera is null
begin
  select @w_msg    = 'NO EXISTE FECHA CIERRE DE CARTERA'
  select @w_us_finagro  = @w_us_finagro2              
  goto ERRORFIN
end

--NOMBRE DE USUARIO QUE SE GUARDA EN LA ca_errorlog
select @w_us_finagro1 = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'USLIFI'

select @w_us_finagro2 = @w_us_finagro1 + '_USR'
select @w_us_finagro  = @w_us_finagro1

if @@rowcount = 0 or @w_us_finagro is null
begin
  select @w_msg    = 'NO EXISTE PARAMETRO NOMBRE DE USUARIO PARA CAMBIO DE LINEA FINAGRO',
         @w_error = 708153
  select @w_us_finagro  = @w_us_finagro2          
  goto ERRORFIN
end

----SI NO HAY DATOS CARGADOS SIMPLEMENTE GENERE UN ERROR
if not exists ( select 1 from ca_proc_cam_linea_finagro)
begin
  select @w_msg = 'NO SE HA CARGADO DATOS EN LA TABLA DE TRABAJO'
  goto ERRORFIN
end


--COMISION FAG AL DESEMBOLSO
select @w_comfagd = pa_char 
from cobis..cl_parametro 
where pa_nemonico = 'CMFAGD'
and pa_producto   = 'CCA'

if @@rowcount = 0 or @w_comfagd is null
begin
  select @w_msg    = 'NO EXISTE PARAMETRO PARA COMISION FAG AL DESEMBOLSO',
         @w_error = 708153
  select @w_us_finagro  = @w_us_finagro2            
  goto ERRORFIN
end

--IVA COMISION FAG AL DESEMBOLSO
select @w_ivacomfagd = pa_char 
from cobis..cl_parametro 
where pa_nemonico = 'IVFAGD'
and pa_producto   = 'CCA'

if @@rowcount = 0 or @w_ivacomfagd is null
begin
  select @w_msg    = 'NO EXISTE PARAMETRO PARA IVA COMISION FAG AL DESEMBOLSO',
         @w_error = 708153
  select @w_us_finagro = @w_us_finagro2                     
  goto ERRORFIN
end

---FORMA REVERSO DE PAGOS PARA CAMBIO DE LINEA FINAGRO
select @w_parametro_freverso = pa_char
from cobis..cl_parametro
where pa_nemonico = 'FREVER'
and   pa_producto = 'CCA'

if @@rowcount = 0 or @w_parametro_freverso is null
begin
  select @w_msg    = 'NO EXISTE FORMA DE REVERSO PARA CAMBIO DE LINEA FINAGRO',
         @w_error = 708153
  select @w_us_finagro  = @w_us_finagro2                     
  goto ERRORFIN
end

/*CREA TEMPORAL DE OPERACIONES A DESEMBOLSAR*/
select pc_banco_cobis Banco, Operacion = 0, Estado = 'I' 
into #desembolso_finagro
from cob_cartera..ca_proc_cam_linea_finagro
where pc_fecha_proc    = @w_fecha
and   pc_estado        <> 'P'
and   pc_reverso_pagos = 1
and   pc_reverso_desem = 1
and   pc_retirar_gar   = 1
and   pc_cambio_linea  = 1
and   pc_desembolso    = 0

if @@rowcount = 0
begin
   print 'NO SE ENCONTRO REGISTRO PARA PROCESAR DESEMBOLSO DE CAMBIO DE LINEA'
   return 0
end

update #desembolso_finagro set
Operacion = op_operacion
from cob_cartera..ca_operacion, #desembolso_finagro
where op_banco = Banco

if @@error <> 0
begin
   select @w_msg   = 'ERROR, AL ACTUALIZAR LA OPERACION DE CARTERA EN TABLA TEMPORAL',
          @w_error = 708152
   goto ERRORFIN
end

while 1 = 1
begin
       
   select top 1 
   @w_operacionca = Operacion,
   @w_banco       = Banco
   from #desembolso_finagro
   where Estado = 'I'  

   if @@rowcount = 0
      break
      
   begin tran   
   
   print 'PROCESANDO OPERACION: ' + cast(@w_operacionca as varchar)

   /* OBTIENE SECUENCIAL PARA GRABAR HISTORICOS Y LA NUEVA TRANSACCION DE DESEMBOLSO*/
   exec @w_secuencial_tran = cob_cartera..sp_gen_sec
        @i_operacion       = @w_operacionca

   if @w_secuencial_tran is null
   begin
      select @w_msg   = 'ERROR, NO SE ENCONTRO SECUENCIAL PARA LA TRANSACCION',
             @w_error =  708150
      goto ERROR
   end

   /* OBTENER RESPALDO DEL DESEMBOLSO */
   exec @w_error  = cob_cartera..sp_historial
        @i_operacionca = @w_operacionca,
        @i_secuencial  = @w_secuencial_tran

   if @w_error <> 0
   begin
      select @w_msg   = 'ERROR, NO FUE POSIBLE GUARDAR EL RESPALDO DE LA TRANSACCION',
             @w_error = 708154
      goto ERROR
   end

   /* OBTIENE EL MAXIMO SECUENCIAL DE TRANSACCION DE DESEMBOLSO PARA ASEGURAR QUE ES EL REVERSO DEL CAMBIO DE LINEA*/
   select @w_sec_desembolso = max(tr_secuencial)   
   from cob_cartera..ca_transaccion
   where tr_operacion = @w_operacionca      
   and   tr_tran      = 'DES'
   and   tr_estado    = 'RV'
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg   = 'ERROR, NO FUE POSIBLE OBTENER EL MAXIMO SECUENCIAL DE TRANSACCION DE DESEMBOLSO',
             @w_error = 708154
      goto ERROR
   end

   /* GUARDA COPIA DE LA TRANSACCION DE DESEMBOLSO DEL CAMBIO DE LINEA */
   select * 
   into #transaccion_des
   from cob_cartera..ca_transaccion
   where tr_operacion  = @w_operacionca
   and   tr_secuencial = @w_sec_desembolso
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg   = 'ERROR, NO FUE POSIBLE GUARDAR COPIA DE LA TRANSACCION DE DESEMBOLSO',
             @w_error = 708154
      goto ERROR
   end
   
   /* GUARDA COPIA DEL DETALLE DE LA TRANSACCION DE DESEMBOLSO DEL CAMBIO DE LINEA */
   select b.* 
   into #dtrtransaccion_des
   from cob_cartera..ca_transaccion a, cob_cartera..ca_det_trn b
   where tr_operacion  = @w_operacionca
   and   tr_operacion  = dtr_operacion
   and   tr_tran       = 'DES'   
   and   tr_secuencial = @w_sec_desembolso
   and   tr_secuencial = dtr_secuencial
   and   tr_estado     = 'RV'
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg   = 'ERROR, NO FUE POSIBLE GUARDAR COPIA DEL DETALLE DE LA TRANSACCION DE DESEMBOLSO',
             @w_error = 708154
      goto ERROR
   end

   
   /* GUARDA COPIA DEL REGISTRO DE DESEMBOLSO */
   select *
   into #ca_desembolso
   from cob_cartera..ca_desembolso
   where dm_operacion  = @w_operacionca
   and   dm_secuencial = @w_sec_desembolso
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg   = 'ERROR, NO FUE POSIBLE GUARDAR COPIA DEL REGISTRO DE DESEMBOLSO',
             @w_error = 708154
      goto ERROR
   end

   
   /* ACTUALIZA EL ESTADO DEL DESEMBOLSO ANTERIOR */
   update  cob_cartera..ca_desembolso
   set   dm_estado = 'RV'
   where dm_operacion  = @w_operacionca
   and   dm_secuencial = @w_sec_desembolso
   
   if @@error <> 0
   begin
      select @w_msg   = 'ERROR, NO FUE POSIBLE ACTUALIZAR ESTADO DEL DESEMBOLSO A REVERSADO',
             @w_error = 708154
      goto ERROR
   end
      
   /* SELECCIONA LA NUEVA LINEA DE OPERACION */
   select @w_nue_linea = op_toperacion
   from cob_cartera..ca_operacion
   where op_operacion = @w_operacionca
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg   = 'ERROR, NO SE ENCONTRO LA NUEVA LINEA DE OPERACION',
             @w_error = 708154
      select @w_us_finagro  = @w_us_finagro2             
      goto ERROR
   end

   /* SELECCIONA CODIGO VALOR DE LA NUEVA FORMA DE PAGO */
   select @w_codigo_valor = cp_codvalor
   from ca_producto
   where cp_producto = @w_parametro_freverso
   and   cp_desembolso = 'S' 
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg   = 'ERROR, NO SE ENCONTRO CODIGO VALOR DE LA NUEVA FORMA DE PAGO',
             @w_error = 708154
      goto ERROR
   end
   /*CANTIDAD DE DESEMBOLSOS */
   select @w_numero_desembolsos = count(1)
   from cob_cartera..ca_desembolso
   where dm_operacion  = @w_operacionca
   and   dm_secuencial = @w_sec_desembolso   

   /* SELECCIONA FORMA DE PAGO ACTUAL */
   select @w_forma_desembolso = dm_producto,
          @w_sec_dm_desembolso = dm_desembolso
   from ca_desembolso
   where dm_operacion   = @w_operacionca
   and   dm_secuencial  = @w_sec_desembolso

   
   if @@ROWCOUNT = 0
   begin
      select @w_msg   = 'ERROR, NO SE ENCONTRO FORMA DE PAGO ACTUAL',
             @w_error = 708154
      select @w_us_finagro  = @w_us_finagro2                   
      goto ERROR
   end

   /* SELECCIONA EL MONTO DE LA COMISION */
   select @w_monto_comision = isnull(dtr_monto,0)
   from #dtrtransaccion_des
   where dtr_concepto = @w_comfagd


   /* SELECCIONA EL MONTO DEL IVA COMISION */
   select @w_iva_comision = isnull(dtr_monto,0)
   from #dtrtransaccion_des
   where dtr_concepto = @w_ivacomfagd

   /*ACTUALIZA LOS DATOS DE CABECERA PARA EL NUEVO DESEMBOLSO*/
   update #transaccion_des set
   tr_secuencial  = @w_secuencial_tran,
   tr_toperacion  = @w_nue_linea,
   tr_observacion = 'CAMBIO LINEA DE FINAGRO A OTRA',
   tr_comprobante = 0,
   tr_usuario     = @w_us_finagro,
   tr_fecha_mov   = @w_fecha_cartera,
   tr_estado      = 'ING',
   tr_fecha_real  = getdate()   
   
   if @@ERROR <> 0
   begin
      select @w_msg   = 'ERROR, ACTUALIZANDO LOS DATOS DE CABECERA PARA EL NUEVO DESEMBOLSO',
             @w_error = 708154
      goto ERROR
   end

   /*ACTUALIZA EL SECUENCIAL DEL DETALLE DE LA TRANSACCION CON EL SECUENCIAL DE RESPALDO*/
   update #dtrtransaccion_des set
   dtr_secuencial = @w_secuencial_tran
   
   if @@ERROR <> 0
   begin
      select @w_msg   = 'ERROR, ACTUALIZANDO EL SECUENCIAL DEL DETALLE DE LA TRANSACCION CON EL SECUENCIAL DE RESPALDO',
             @w_error = 708154
      goto ERROR
   end

   /*ACTUALIZA LOS DATOS DE DETALLE PARA EL NUEVO DESEMBOLSO*/
   update #dtrtransaccion_des set
   dtr_concepto = @w_parametro_freverso,
   dtr_codvalor = @w_codigo_valor,
   dtr_monto    = dtr_monto    + (isnull(@w_monto_comision,0) + isnull(@w_iva_comision,0)),
   dtr_monto_mn = dtr_monto_mn + (isnull(@w_monto_comision,0) + isnull(@w_iva_comision,0))
   where dtr_concepto = @w_forma_desembolso
   
   if @@ERROR <> 0
   begin
      select @w_msg   = 'ERROR, ACTUALIZANDO LOS DATOS DE DETALLE PARA EL NUEVO DESEMBOLSO',
             @w_error = 708154
      goto ERROR
   end
   
   if @w_numero_desembolsos > 1
   begin
      update #dtrtransaccion_des set
      dtr_concepto = @w_parametro_freverso,
      dtr_codvalor = @w_codigo_valor
      from #dtrtransaccion_des,
           ca_producto
      where dtr_concepto = cp_producto
      and   cp_desembolso = 'S'
      and   dtr_concepto <> @w_forma_desembolso
      
      if @@ERROR <> 0
      begin
         select @w_msg   = 'ERROR, ACTUALIZANDO LOS DATOS DE DETALLE PARA EL NUEVO DESEMBOLSO OOTR SEC.',
                @w_error = 708154
         goto ERROR
      end
   end
      

   /*ACTUALIZA LOS DATOS DEL NUEVO DESEMBOLSO*/
   update #ca_desembolso set
   dm_secuencial = @w_secuencial_tran,
   dm_producto   = @w_parametro_freverso,
   dm_usuario    = @w_us_finagro,
   dm_monto_mds  = dm_monto_mds + (isnull(@w_monto_comision,0) + isnull(@w_iva_comision,0)),
   dm_monto_mop  = dm_monto_mop + (isnull(@w_monto_comision,0) + isnull(@w_iva_comision,0)),
   dm_monto_mn   = dm_monto_mn  + (isnull(@w_monto_comision,0) + isnull(@w_iva_comision,0)),
   dm_fecha     =  @w_fecha_cartera,
   dm_concepto  = 'CAMBIO LINEA DE FINAGRO A OTRA'
   where dm_producto   = @w_forma_desembolso
   and   dm_desembolso = @w_sec_dm_desembolso
   
   if @@ERROR <> 0
   begin
      select @w_msg   = 'ERROR, ACTUALIZANDO LOS DATOS DEL NUEVO DESEMBOLSO PRIMER SECUENCIAL',
             @w_error = 708154
      goto ERROR
   end
   
   if @w_numero_desembolsos > 1
   begin
     ---HAY QUE ACTUALIZAR  LOS OTROS REGISTROS PERO SIN VALROES POR QUE SINO SE ALTERA
     ---EL REGSITRO Y NO CUADRARIA
      /*ACTUALIZA LOS DATOS DEL NUEVO DESEMBOLSO*/
      update #ca_desembolso set
      dm_secuencial = @w_secuencial_tran,
      dm_producto   = @w_parametro_freverso,
      dm_usuario    = @w_us_finagro,
      dm_fecha     =  @w_fecha_cartera,
      dm_concepto  = 'CAMBIO LINEA DE FINAGRO A OTRA'
      where dm_producto   <> @w_parametro_freverso
      and   dm_desembolso <> @w_sec_dm_desembolso
      
      if @@ERROR <> 0
      begin
         select @w_msg   = 'ERROR, ACTUALIZANDO LOS DATOS DEL NUEVO DESEMBOLSO OTRO SECUENCAIL ',
                @w_error = 708154
         goto ERROR
      end
     
   end

   /* ELIMINA RUBROS DE COMISION YA QUE ESTOS VALORES FUERON AÑADIDOS A LA NUEVA FORMA DE DESEMBOLSO */
   delete from #dtrtransaccion_des
   where dtr_concepto in (@w_comfagd,@w_ivacomfagd)
   
   if @@ERROR <> 0
   begin
      select @w_msg   = 'ERROR, ELIMINAR RUBROS DE COMISION',
             @w_error = 708154
      goto ERROR
   end
   
   /* VALIDA DEBITOS Y CREDITOS */
   select @w_debitos = isnull(sum(dtr_monto),0)
   from #dtrtransaccion_des
   where dtr_afectacion = 'D'
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg   = 'ERROR, NO SE ENCONTRO DEBITOS DEL DESEMBOLSO',
             @w_error = 708154
      goto ERROR
   end

   select @w_creditos = isnull(sum(dtr_monto),0)
   from #dtrtransaccion_des
   where dtr_afectacion = 'C'
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg   = 'ERROR, NO SE ENCONTRO CREDITOS DEL DESEMBOLSO',
             @w_error = 708154
      goto ERROR
   end
   
   if @w_debitos <> @w_creditos
   begin
      select @w_msg   = 'DEBITOS Y CREDITOS NO CUADRAN, FAVOR VALIDAR',
             @w_error = 708154
      goto ERROR
   end

   update cob_cartera..ca_proc_cam_linea_finagro set
   pc_monto_comision = isnull(@w_monto_comision,0),
   pc_iva_comision   = isnull(@w_iva_comision,0)   
   where pc_banco_cobis = @w_banco   
   and   pc_fecha_proc  = @w_fecha
   
   if @@ERROR <> 0
   begin
      select @w_msg   = 'ERROR, ACTUALIZANDO MONTOS DE COMISION',
             @w_error = 708154
      goto ERROR
   end
   
   insert into cob_cartera..ca_transaccion
   select * from #transaccion_des

   if @@error <> 0
   begin
      select @w_msg   = 'ERROR AL INSERTAR TRANSACCION DE DESEMBOLSO PARA CAMBIO LINEA FINAGRO',
             @w_error = 708154
      goto ERROR
   end
   
   insert into cob_cartera..ca_det_trn
   select * from #dtrtransaccion_des

   if @@error <> 0
   begin
      select @w_msg   = 'ERROR AL INSERTAR DETALLE DE TRANSACCION DE DESEMBOLSO PARA CAMBIO LINEA FINAGRO',
             @w_error = 708154
      goto ERROR
   end

   insert into cob_cartera..ca_desembolso
   select * from #ca_desembolso

   if @@error <> 0
   begin
      select @w_msg   = 'ERROR AL INSERTAR REGISTRO DE DESEMBOLSO PARA CAMBIO LINEA FINAGRO',
             @w_error = 708154
      goto ERROR
   end

   drop table #transaccion_des
   drop table #dtrtransaccion_des   
   drop table #ca_desembolso

   update #desembolso_finagro set
   Estado = 'P'   
   where Operacion = @w_operacionca
   
   if @@ERROR <> 0
   begin
      select @w_msg   = 'ERROR, ACTUALIZANDO ESTADO EN DESEMBOLSO FINAGRO A P',
             @w_error = 708154
      goto ERROR
   end

   select @w_error = 0
   goto SIGUIENTE

   ERROR:
      begin
      
         if @@TRANCOUNT > 0 
            rollback tran
            
         if @w_msg is null 
         begin
            select @w_msg = mensaje
            from cobis..cl_errores
            where numero = @w_error
         end

         PRINT  'Error: ' + cast ( @w_msg as varchar)
         exec sp_errorlog 
         @i_fecha     = @w_fecha,
         @i_error     = @w_error,
         @i_usuario   = @w_us_finagro,
         @i_tran      = 7999,
         @i_tran_name = @w_sp_name,
         @i_cuenta    = @w_operacionca,
         @i_descripcion = @w_msg,
         @i_anexo       = @w_msg,
         @i_rollback  = 'N'       
         
         select @w_us_finagro = @w_us_finagro1  
         
         update ca_proc_cam_linea_finagro  
         set pc_estado = 'E',
               pc_desembolso = '0'            
         where pc_banco_cobis = @w_banco
         and   pc_fecha_proc = @w_fecha 
         
         update #desembolso_finagro set
         Estado = 'P'   
         where Operacion = @w_operacionca

      end --FINALIZA SENTENSIA DE ERROR

   SIGUIENTE:   
   if @w_error = 0
   begin
      if @@TRANCOUNT > 0 
         commit tran 
         
      update ca_proc_cam_linea_finagro  
      set pc_desembolso  = '1',
            pc_estado    = 'I'
      where pc_banco_cobis = @w_banco
      and   pc_fecha_proc  = @w_fecha
   end

   select @w_error = 708153

end --while

return 0

ERRORFIN:
   PRINT  @w_msg
   exec sp_errorlog 
   @i_fecha     = @w_fecha,
   @i_error     = @w_error,
   @i_usuario   = @w_us_finagro,
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = ' ',
   @i_descripcion = @w_msg,
   @i_anexo       = @w_msg,
   @i_rollback  = 'N'         

   exec sp_err_camlinfin @i_param1,'NULL'   --RQ500 ATSK-1060

   return 1

go
