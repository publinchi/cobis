/************************************************************************/
/*   Archivo:           catrasga.sp                                     */
/*   Stored procedure:  sp_traslado_cambio_gar                          */
/*   Base de datos:     cob_cartera                                     */
/*   Producto:          Cartera                                         */
/*   Disenado por:      Elcira Pelaez Burbano                           */
/*   Fecha de escritura: Mayo 2006                                       */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */ 
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                               PROPOSITO                              */
/*   Realiza traslado de cartera por cierre definitivo de               */
/*      cambios de garantias                                            */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*     JUN-2006        E.Pelaez         DEF-6322 no borrar errores   de */
/*                                      cob_ccontable..cco_error_conaut */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_traslado_cambio_gar')
   drop proc sp_traslado_cambio_gar
go

create proc sp_traslado_cambio_gar
(  @s_user              login,
   @s_term              descripcion,
   @s_lsrv              varchar(30),
   @s_ofi               smallint,
   @s_rol               smallint,
   @s_date              datetime,
   @i_fecha_proceso     datetime,
   @i_debug             char(1) = 'N'
)

as
declare 
   @w_error                int,
   @w_sp_name              varchar(30),
   @w_tran                 varchar(10),
   @w_sec_ref              int,
   @w_cg_garantia_anterior        char(1),
   @w_reestructuracion     char(1),
   @w_param_calif          varchar(30),
   @w_tipo_gar_nueva       char(1),
   @w_secuencial_hfm       int,
   @w_est_novigente        smallint,
   @w_est_vigente          smallint,
   @w_est_cancelado        smallint,   
   @w_est_credito          smallint,
   @w_est_suspenso         smallint,
   @w_est_comext           smallint,
   @w_est_castigado        smallint,
   @w_est_anulado          smallint,
   @w_est_novedades        smallint,
   @w_moneda_nac           smallint,
   @w_commit               char(1),
   @w_dias                 int,
   @w_operacionca          int,
   @w_fecha_cierre         datetime,
   @w_banco                cuenta,
   @w_fecha_retro          datetime,
   @w_secuencial           int,
   @w_oficial              int,
   @w_oficina              int,
   @w_toperacion           catalogo,
   @w_moneda               smallint,
   @w_tramite              int,
   @w_tipo                 char(1),
   @w_prodcuto_cca         int,
   @w_fecha                datetime,
   @w_fecha_proceso        datetime,
   @w_causacion            char(1),
   @w_fecha_ult_proceso    datetime,
   @w_co_calif_antes       char(1),
   @w_descripcion          descripcion,
   @w_reproceso            char(1),
   @w_anexo                varchar(255),
   @w_fecha_hfm            datetime,
   @w_op_estado            smallint


-- Captura del nombre del Stored Procedure
select @w_sp_name    = 'sp_traslado_cambio_gar',
       @w_commit     = 'N'

delete ca_errorlog
where  er_fecha_proc = @s_date
and    er_descripcion like '%sp_traslado_cambio_gar%'

-- PARAMETROS GENERALES

select @i_debug = 'N'

select @w_param_calif = pa_char 
from   cobis..cl_parametro
where  pa_producto = 'CRE'   
and    pa_nemonico = 'CALIF'
set transaction isolation level read uncommitted

if @w_param_calif is null  
begin
   print 'Error en parametro CALIF/CRE'
   select @w_error =  2101084
   goto ERROR1
end

-- VALIDAR CI YA SE CERRO LA CALIFICACION EN CREDITO
if @w_param_calif <> 'F'
begin
   print 'Error en parametro @w_param_calif <> F '
   select @w_error =  710343
   goto ERROR1
end

select @w_moneda_nac = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

select @w_prodcuto_cca = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted

--FECHA DE PROCESO REAL DE CARTERA
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

-- FECHA DE REGISTRO DE CAMBIO DE CALIFICACION
set rowcount 1
select @w_fecha = do_fecha
from   cob_credito..cr_dato_operacion
where  do_tipo_reg = 'M'
and    do_codigo_producto = 7
set rowcount 0

if @w_fecha is null
begin
   print 'Error  no existe  Fecha cr_dato_operacion de credito '
   select @w_error =  2101084 
   goto ERROR1
end



select @w_fecha_hfm = dateadd(dd, -1, dateadd(mm, 1, dateadd(dd, 1, dateadd(dd, -datepart(dd, @w_fecha), @w_fecha))))

select @w_fecha_cierre = @w_fecha


delete ca_traslados WHERE top_operacion >= 0

insert into ca_traslados
select op_operacion,      op_banco,            op_toperacion,
       op_moneda,         op_oficina,          op_tramite,
       cg_garantia_anterior,  op_tipo,
       op_oficial,        op_reestructuracion, cg_garantia_nueva,
       op_causacion,      op_fecha_ult_proceso, op_estado
from   cob_cartera..ca_operacion,
       cob_cartera..ca_cambio_tipo_garantia
where  cg_fecha = @w_fecha
and    cg_operacion = op_operacion
and    op_estado not in (0, 4, 99, 98, 6)
and    cg_estado = 'I'


declare
   cursor_operacion_cgr cursor
   for select top_operacion,      top_banco,            top_toperacion,          
              top_moneda,         top_oficina,          top_tramite,
              tcg_garantia_anterior,  top_tipo,             
              top_oficial,        top_reestructuracion, tcg_garantia_nueva,
              top_causacion,      top_fecha_ult_proceso,top_estado
       from   ca_traslados
   for read only

open  cursor_operacion_cgr                                        
    
fetch cursor_operacion_cgr
into  @w_operacionca,    @w_banco,              @w_toperacion,          
      @w_moneda,         @w_oficina,            @w_tramite,
      @w_cg_garantia_anterior,  @w_tipo,         
      @w_oficial,        @w_reestructuracion,   @w_tipo_gar_nueva,
      @w_causacion,      @w_fecha_ult_proceso,  @w_op_estado

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin ---(4)
   select @w_anexo = ''
   
   if @w_cg_garantia_anterior in (null,'')
      select @w_cg_garantia_anterior = 'N'
   
   if @i_debug = 'S'
      PRINT 'catrasga.sp  @w_fecha_cierre que va ' + cast(@w_fecha_cierre as varchar) +  ' credito ' + cast(@w_banco as varchar)
   
   if @i_debug = 'S'
      PRINT 'catrasga.sp  @w_fecha de cr_calificacion_op va ' + cast(@w_fecha as varchar)
   
   ---VALIDAR SI SE EJECUTA EL PROCESO AL FIN DE MES O DIAS DESPUES DE ESTE
   
   select @w_reproceso = 'N'
   
   select  @w_dias = datediff(dd,@w_fecha,@w_fecha_proceso)
   
   if @w_dias  > 1
      select @w_reproceso = 'S'

   if @w_op_estado = 3
   begin
      if not exists (select 1 from ca_transaccion
                     where tr_operacion  = @w_operacionca)

                      exec  sp_restaurar
            	       @i_banco		= @w_banco,
            	       @i_en_linea   = 'N'                     
   end
   
   if  @w_reproceso = 'S'
   begin ---(2)
      -- SACAR TRANSACCION DE FIN DE MES PARA HACER EL TRASLADO EN ESTE PUNTO
      select @w_secuencial_hfm = isnull(max(tr_secuencial),0)
      from   ca_transaccion
      where  tr_estado     = 'NCO'    
      and    tr_operacion  = @w_operacionca
      and    tr_tran       = 'HFM' --Historico Fin Mes
      and    tr_fecha_ref  = @w_fecha_hfm   ---FECHA EN QUE SE GENERO LA TRANSACCION EN CARTERA
      
      if @w_secuencial_hfm <= 0 
      begin ---(1)
         if @i_debug = 'S'
            PRINT 'catrasga.sp  No encontro Historico Fine de Mes transaccion HFM'
         
         -- Se inserta un mensaje en ca_errorlog para identificar que operaciones no tiene HFM
         insert into ca_errorlog
         values (@i_fecha_proceso,710349,@s_user,7999,@w_banco,'No Existe Historico Fin de Mes', 'Se  restaura otro historico  inferior o = al cierre')
       
         select @w_fecha_retro = max(tr_fecha_ref)
         from  ca_transaccion
         where tr_estado      in  ('ING','CON','ANU')      
         and   tr_operacion   =  @w_operacionca
         and   tr_fecha_ref  <= @w_fecha_hfm
         and   tr_tran        in  ('PRV', 'EST','AMO','HFM') 
         and   tr_secuencial_ref <> -999  --RECONOCER PRV GENERADAS POR PAGOS
         
         select @w_secuencial_hfm = min(tr_secuencial)
         from  ca_transaccion
         where tr_estado      in  ('ING','CON','ANU')      
         and   tr_operacion   =  @w_operacionca
         and   tr_fecha_ref   = @w_fecha_retro
         and   tr_tran        in  ('PRV', 'EST','AMO','HFM') 
         and   tr_secuencial_ref <> -999  --RECONOCER PRV GENERADAS POR PAGOS
         
         if @w_secuencial_hfm is null 
         begin
            select @w_error = 701025
            goto ERROR
         end
      end  ---@w_secuencial_hfm <= 0  ---(1)
      
      if @i_debug = 'S'
         PRINT 'catrasga.sp @w_secuencial_hfm  encontrado ' + cast(@w_secuencial_hfm as varchar)
      
      -- VERIFICAR LA EXISTENCIA DEL HISTORICO
      if not exists (select 1
                     from   ca_operacion_his
                     where  oph_operacion = @w_operacionca     
                     and    oph_secuencial= @w_secuencial_hfm) 
      begin
         select @w_error = 710132,
                @w_anexo = 'sec_hfm = ' + convert(varchar, @w_secuencial_hfm)
                         + ' operacion ' + convert(varchar, @w_operacionca)+
                         + ' fecha_retro ' + convert(varchar, @w_fecha_retro)
         
         goto ERROR
      end  
   end ---reproceso = S ---(2)
   
   BEGIN TRAN --atomicidad por registro
   
   select @w_commit = 'S'
   
   if @w_secuencial_hfm > 0  and @w_reproceso = 'S'
   begin ---(3)
      --  APLICAR FECHA VALOR
      if @i_debug = 'S'
         PRINT 'catrasga.sp  Antes de  sp_fecha_valor '
      
      select @w_error = 0


        exec  sp_restaurar
        @i_banco      = @w_banco,
        @i_en_linea   = 'N'      
      
        exec @w_error = sp_fecha_valor
        @s_date              = @s_date,
        @s_lsrv	     	     = 'CONSOLA',
        @s_srv               = 'CONSOLA',
        @s_ofi               = @s_ofi,
        @s_rol		           = @s_rol,
        @s_sesn              = 1,
        @s_ssn               = 10,
        @s_term              = @s_term,
        @s_user              = @s_user,
        @i_fecha_valor       = @w_fecha_hfm, 
        @i_banco             = @w_banco,
        @i_secuencial_hfm    = @w_secuencial_hfm,        
        @i_operacion         = 'F',
        @i_en_linea          = 'N',
        @i_con_abonos        = 'N',
        @i_observacion       = 'FECHA VALOR POR CAMBIO GARANTIA',
        @i_susp_causacion    = 'S' --Para no ejecutar el batch sino que este seejecute despues
    
         if @@error <> 0 or @@trancount = 0 
         begin  
            PRINT 'catrasga.sp error ejecutando fechaval.sp.sp @@trancount ' + cast(@@trancount as varchar) + ' @@error ' + cast(@@error as varchar)  + ' oper '+ cast(@w_banco as varchar)
            select @w_error =  708152
            goto ERROR
         end 
                 
      
      if @w_error != 0 
      begin
         goto ERROR
      end
      
      if @i_debug = 'S'
         PRINT 'catrasga.sp  Despues de  sp_fecha_valor '    
   end  --  ---(3)  @w_secuencial_hfm > 0  y reproceso = S
   
   -- PROCESO PARA TRASLADAR
   if @i_debug = 'S'
      PRINT 'catrasga.sp  antes de  sp_transaccion_cambio_gar'    
   
   select @w_error = 0
   
   exec @w_error =  sp_transaccion_cambio_gar
        @s_user               = @s_user,
        @s_term               = @s_term,      
        @s_date               = @s_date,
        @s_ofi                = @s_ofi,
        @i_toperacion         = @w_toperacion,
        @i_oficina            = @w_oficina,
        @i_banco              = @w_banco,
        @i_operacionca        = @w_operacionca,
        @i_moneda             = @w_moneda,
        @i_fecha_proceso      = @w_fecha_hfm,
        @i_gerente            = @w_oficial,
        @i_moneda_nac         = @w_moneda_nac,
        @i_garantia           = @w_cg_garantia_anterior,
        @i_reestructuracion   = @w_reestructuracion,
        @i_garantia_final     = @w_tipo_gar_nueva,
        @i_garantia_antes     = @w_cg_garantia_anterior,
        @i_reproceso          = @w_reproceso
   
   
         if @@error <> 0  
         begin
            select @w_error =  708152
            goto ERROR
         end
         
         if @w_error  != 0 
         begin
            goto ERROR
         end

      if @i_debug = 'S'
      PRINT 'catrasga.sp  Despues de  sp_transaccion_cambio_gar'    
   
   
   -- actualiza ca_cambio_tipo_garantia
      update cob_cartera..ca_cambio_tipo_garantia
    	set cg_estado = 'P'
       from cob_cartera..ca_cambio_tipo_garantia
      where cg_fecha = @w_fecha
	   and cg_operacion = @w_operacionca

   if @i_debug = 'S'
      PRINT 'catrasga.sp  Despues de actualizar ca_cambio_tipo_garantia'    


      update cob_cartera..ca_operacion_hc
      set    oh_gar_admisible = @w_tipo_gar_nueva
      where  oh_fecha = @w_fecha
      and    oh_operacion = @w_operacionca
   
   if @i_debug = 'S'
      PRINT 'catrasga.sp  Despues de  actualizar ca_operacion_hc'    
      

      ---INSERCION EN LA TABLA PARA HACER FECHA VALOR MASIVO
      ---DEF 7042 Septiembre BAC
      
      delete ca_fval_masivo
      where fm_banco  = @w_banco
      and   fm_estado = 'I'
      ---SI EXISTE UN REGISTRO EN ESTADO I SE DEBE ELIMINAR ARA EVITAR DOBLE PROCESO 
      
      insert into ca_fval_masivo
      ( fm_banco,       fm_fecha_valor,   fm_usuario,
        fm_fecha_ing,   fm_terminal,      fm_estado )
      values
      ( @w_banco,       @w_fecha_proceso, @s_user,
       getdate(),       @s_term,          'I')         

      
   
   while @@trancount > 0 COMMIT TRAN     ---Fin de la transaccion
   
   select @w_commit = 'N'
   
   goto SIGUIENTE
   
   ERROR:
      while @@trancount > 0 ROLLBACK
      begin
         
         --- actualiza ca_cambio_calificacion
         update cob_cartera..ca_cambio_calificacion
      	set cc_estado_trc = 'E'
         from cob_cartera..ca_cambio_calificacion
         where cc_fecha = @w_fecha
      	and cc_operacion = @w_operacionca
         
         exec sp_errorlog
              @i_fecha       = @s_date,
              @i_error       = @w_error,
              @i_usuario     = @s_user,
              @i_tran        = 7000, 
              @i_tran_name   = @w_sp_name,
              @i_rollback    = 'S',  
              @i_cuenta      = @w_banco,
              @i_descripcion = '',
              @i_anexo       = @w_anexo
      end
      goto SIGUIENTE
   
   SIGUIENTE:
   
   fetch cursor_operacion_cgr
   into  @w_operacionca,    @w_banco,              @w_toperacion,          
         @w_moneda,         @w_oficina,            @w_tramite,
         @w_cg_garantia_anterior,  @w_tipo,         
         @w_oficial,        @w_reestructuracion,   @w_tipo_gar_nueva,
         @w_causacion,      @w_fecha_ult_proceso,  @w_op_estado
end -- cursor_operacion_cgr */   ---(4)

close cursor_operacion_cgr
deallocate cursor_operacion_cgr

while @@trancount > 0 ROLLBACK

return 0

ERROR1:
while @@trancount > 0 ROLLBACK

exec sp_errorlog
   @i_fecha       = @s_date,
   @i_error       = @w_error,
   @i_usuario     = @s_user,
   @i_tran        = 7000, 
   @i_tran_name   = @w_sp_name,
   @i_rollback    = 'S',  
   @i_cuenta      = @w_banco,
   @i_descripcion = '',
   @i_anexo       = @w_anexo

return 0
go
