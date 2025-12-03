/************************************************************************/
/*   Nombre Fisico:     tracalif.sp                                     */
/*   Nombre Logico:     sp_traslado_por_cierre_calif                    */
/*   Base de datos:     cob_cartera                                     */
/*   Producto:          Cartera                                         */
/*   Disenado por:      Elcira Pelaez Burbano                           */
/*   Fecha de escritura: Feb 1999                                       */
/************************************************************************/
/*                               IMPORTANTE                             */
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
/*                               PROPOSITO                              */
/*   Realiza traslado de cartera por cierre definitivo de               */
/*      calificacion y es ejecutado desde Credito el dia del cierre de  */
/*      lacalificacion                                                  */ 
/*      Ejecuta los siguietnes SP's:                                    */
/*      1. sp_fecha_valor_trc  (fecvatrc.sp)                            */
/*         Este reversa las transacciones mayore o iguales al sec retro */
/*         y los pagos si hay los deja en estado NA                     */
/*      2. sp_transaccion_trc (traslado.sp)                             */
/*         Este genera la transaccion TRC para la respectiva conta      */            
/************************************************************************/
/*                              MODIFICACIONES                          */
/*     EPB:ABR-10-2002   Cambio de la fecha cierre y sacar HFM          */
/*     EPB:MAY-30-2002   Manejo de fecha para reversos y ejecutar el    */
/*                       batch1.sp despues del TRC                      */
/*     EPB:ACT-21-2003   Actualizacion de Calificacion inical en        */
/*                       ca_operacion tomada de co_calif_final          */
/*     EPB:03MAY2004     Quitar actualizaciones maestro se pasan al     */
/*                       nuevo programa cr_actma.sqr                    */
/*     Luis Ponce                                                       */
/*     13-Sep-2004       Optimizacion                                   */
/*     FEB-2006        E.Pelaez         DEF-5968 llamar fechaval.sp     */
/*     JUN-2006        E.Pelaez         DEF-6322 no borrar errores   de */
/*                                      cob_ccontable..cco_error_conaut */
/*     SEP-2006        E.Pelaez         DEF-7042 BAC                    */
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_traslado_por_cierre_calif')
   drop proc sp_traslado_por_cierre_calif
go


create proc sp_traslado_por_cierre_calif
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
   @w_gar_admisible        char(1),
   @w_reestructuracion     char(1),
   @w_param_calif          varchar(30),
   @w_co_calif_final       catalogo,
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
   @w_co_calif_antes       catalogo,
   @w_descripcion          descripcion,
   @w_reproceso            char(1),
   @w_anexo                varchar(255),
   @w_fecha_hfm            datetime


-- Captura del nombre del Stored Procedure
select @w_sp_name    = 'sp_traslado_por_cierre_calif',
       @w_commit     = 'N',
       @i_debug      = 'S'

delete ca_errorlog
where  er_fecha_proc = @s_date
and    er_descripcion like '%sp_traslado_por_cierre_calif%'

-- PARAMETROS GENERALES

select @w_param_calif = pa_char 
from   cobis..cl_parametro
where  pa_producto = 'CRE' --LPO
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

select op_operacion,      op_banco,            op_toperacion,
       op_moneda,         op_oficina,          op_tramite,
       op_gar_admisible,  op_tipo,
       op_oficial,        op_reestructuracion, cc_calificacion_nueva,
       op_causacion,      op_fecha_ult_proceso, isnull(op_calificacion,'A') op_calificacion
into   #traslado
from   cob_cartera..ca_operacion,
       cob_cartera..ca_cambio_calificacion
where  cc_fecha = @w_fecha
and    cc_operacion = op_operacion
and    op_estado not in (0, 4, 99, 98, 6)
and    cc_estado_trc = 'I'

begin tran
delete cob_ccontable..cco_error_conaut
where ec_producto = 7
commit

declare
   cursor_operacion_trc cursor
   for select op_operacion,      op_banco,            op_toperacion,          
              op_moneda,         op_oficina,          op_tramite,
              op_gar_admisible,  op_tipo,             
              op_oficial,        op_reestructuracion, cc_calificacion_nueva,
              op_causacion,      op_fecha_ult_proceso, op_calificacion
       from   #traslado
   for read only

open  cursor_operacion_trc                                        
    
fetch cursor_operacion_trc
into  @w_operacionca,    @w_banco,              @w_toperacion,          
      @w_moneda,         @w_oficina,            @w_tramite,
      @w_gar_admisible,  @w_tipo,         
      @w_oficial,        @w_reestructuracion,   @w_co_calif_final,
      @w_causacion,      @w_fecha_ult_proceso,  @w_co_calif_antes

while @@fetch_status not in (-1,0)
begin ---(4)
   select @w_anexo = ''
   
   /*
   if exists(select 1 from ca_transaccion
             where  tr_estado = 'ING'
             and    tr_operacion = @w_operacionca)
   begin
      -- CREAR UN PROCESO PARA CONTABILIZAR TRANSACCIONES
      begin tran
      delete ca_paralelo_tmp
      where  programa = 'caconta'
      and    proceso = @w_operacionca
      
      insert into ca_paralelo_tmp
            (programa,  proceso,        estado, operacion_ini,    operacion_fin)
      values('caconta', @w_operacionca, 'P',    @w_operacionca,   @w_operacionca)
      commit
      
      exec @w_error = sp_caconta
           @i_filial    = 1,
           @i_fecha     = @w_fecha_proceso,
           @i_causacion = 'S',
           @i_proceso   = @w_operacionca
      
      if @w_error != 0
         goto ERROR
      
      exec @w_error = cob_conta..sp_sasiento_val
           @i_operacion      = 'V',
           @i_empresa        = 1,
           @i_producto       = 7
      
      if @w_error != 0
         goto ERROR
      
      exec @w_error = cob_cartera..sp_actualizacion_trn
           @i_fecha_proceso = @w_fecha_proceso
      
      if @w_error != 0
         goto ERROR
      
      -- NO HUBO ERROR EN EL PROCESO CONTABLE, SI PERSISTEN LAS TRANSACCIONES PENDIENTES
      if exists(select 1 from ca_transaccion
                where  tr_estado = 'ING'
                and    tr_operacion = @w_operacionca)
      begin
         select @w_error = 710485
         goto ERROR
      end
   end
   */
   if @w_gar_admisible in (null,'')
      select @w_gar_admisible = 'N'
   
   if @i_debug = 'S'
      PRINT 'trcalif.sp  @w_fecha_cierre que va ' + cast (@w_fecha_cierre as varchar)+ ' credito ' + cast (@w_banco as varchar)
   
   if @i_debug = 'S'
      PRINT 'trcalif.sp  @w_fecha de cr_calificacion_op va ' + cast (@w_fecha as varchar)
   
   ---VALIDAR SI SE EJECUTA EL PROCESO AL FIN DE MES O DIAS DESPUES DE ESTE
   
   select @w_reproceso = 'N'
   
   select  @w_dias = datediff(dd,@w_fecha,@w_fecha_proceso)
   
   if @w_dias  > 1
      select @w_reproceso = 'S'
   
   if  @w_reproceso = 'S'
   begin ---(2)
      -- SACAR TRANSACCION DE FIN DE MES PARA HACER EL TRASLADO EN ESTE PUNTO
      select @w_secuencial_hfm = isnull(max(tr_secuencial),0)
      from   ca_transaccion
      where  tr_estado     = 'NCO'  --LPO
      and    tr_operacion  = @w_operacionca
      and    tr_tran       = 'HFM' --Historico Fin Mes
      and    tr_fecha_ref  = @w_fecha_hfm   ---FECHA EN QUE SE GENERO LA TRANSACCION EN CARTERA
      
      if @w_secuencial_hfm <= 0 
      begin ---(1)
         if @i_debug = 'S'
            PRINT 'trcalif.sp  No encontro Historico Fine de Mes transaccion HFM'
         
         -- Se inserta un mensaje en ca_errorlog para identificar que operaciones no tiene HFM
         insert into ca_errorlog
         values (@i_fecha_proceso,710349,@s_user,7999,@w_banco,'No Existe Historico Fin de Mes', 'Se  restaura otro historico  inferior o = al cierre')
       
         select @w_fecha_retro = max(tr_fecha_ref)
         from  ca_transaccion
         where tr_estado      in  ('ING','CON','ANU')    --LPO
         and   tr_operacion   =  @w_operacionca
         and   tr_fecha_ref  <= @w_fecha_hfm
         and   tr_tran        in  ('PRV', 'EST', 'REJ','AMO','HFM') 
         and   tr_secuencial_ref <> -999  --RECONOCER PRV GENERADAS POR PAGOS
         
         select @w_secuencial_hfm = min(tr_secuencial)
         from  ca_transaccion
         where tr_estado      in  ('ING','CON','ANU')    --LPO
         and   tr_operacion   =  @w_operacionca
         and   tr_fecha_ref   = @w_fecha_retro
         and   tr_tran        in  ('PRV', 'EST', 'REJ','AMO','HFM') 
         and   tr_secuencial_ref <> -999  --RECONOCER PRV GENERADAS POR PAGOS
         
         if @w_secuencial_hfm is null 
         begin
            select @w_error = 701025
            goto ERROR
         end
      end  ---@w_secuencial_hfm <= 0  ---(1)
      
      if @i_debug = 'S'
         PRINT 'trcalif.sp @w_secuencial_hfm  encontrado ' + cast (@w_secuencial_hfm as varchar)
      
      -- VERIFICAR LA EXISTENCIA DEL HISTORICO
      if not exists (select 1
                     from   ca_operacion_his
                     where  oph_operacion = @w_operacionca   --LPO
                     and    oph_secuencial= @w_secuencial_hfm) 
      begin
         select @w_error = 710132,
                @w_anexo = 'sec_hfm = ' + convert(varchar, @w_secuencial_hfm)
                         + ' operacion ' + convert(varchar, @w_operacionca)+
                         + ' fecha_retro ' + convert(varchar, @w_fecha_retro)
         
         goto ERROR
      end  
   end ---reproceso = S ---(2)
   
   begin tran --atomicidad por registro
   
   select @w_commit = 'S'
   
   if @w_secuencial_hfm > 0  and @w_reproceso = 'S'
   begin ---(3)
      --  APLICAR FECHA VALOR
      if @i_debug = 'S'
         PRINT 'trcalif.sp  Antes de  sp_fecha_valor_trc'
      
      select @w_error = 0
      
      exec @w_error = sp_fecha_valor_trc
           @s_user            = @s_user,
           @s_term            = @s_term,
           @s_date            = @s_date,
           @s_ofi             = @s_ofi,
           @s_lsrv            = @s_lsrv,
           @s_rol             = @s_rol,
           @i_fecha_valor     = @w_fecha_hfm,
           @i_banco           = @w_banco,
           @i_secuencial_hfm  = @w_secuencial_hfm,
           @i_operacion       = 'F', 
           @i_observacion     = 'REVERSO DE TRANSACCION POR TRASLADO AL CIERRE DE CALIFICACION'
      
      if @w_error != 0 
      begin
         goto ERROR
      end
      
      if @i_debug = 'S'
         PRINT 'trcalif.sp  Despues de  sp_fecha_valor_trc'    
   end  --  ---(3)  @w_secuencial_hfm > 0  y reproceso = S
   
   -- PROCESO PARA TRASLADAR
   if @i_debug = 'S'
      PRINT 'trcalif.sp  antes de  sp_transaccion_trc'    
   
   select @w_error = 0
   
   exec @w_error =  sp_transaccion_trc
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
        @i_garantia           = @w_gar_admisible,
        @i_reestructuracion   = @w_reestructuracion,
        @i_calificacion_final = @w_co_calif_final,
        @i_calificacion_antes = @w_co_calif_antes,
        @i_reproceso          = @w_reproceso
   
   if @w_error  != 0 
   begin
      goto ERROR
   end

   -- actualiza ca_cambio_calificacion
   update cob_cartera..ca_cambio_calificacion
	set cc_estado_trc = 'P'
       from cob_cartera..ca_cambio_calificacion
      where cc_fecha = @w_fecha
	and cc_operacion = @w_operacionca

   if @i_debug = 'S'
      PRINT 'trcalif.sp  Despues de  sp_transaccion_trc'    
   commit tran     ---Fin de la transaccion
   
   select @w_commit = 'N'
   
   goto SIGUIENTE
   
   ERROR:
      if @w_error = 710485 -- ERROR DE TRANSACCIONES SIN CONTABILIZAR
      begin
         declare cur_transacciones cursor
            for select tr_secuencial, tr_tran, tr_fecha_mov
                from   ca_transaccion
                where  tr_estado    = 'ING'   --LPO
                and    tr_operacion = @w_operacionca
--                order  by tr_secuencial
                for read only
         declare
            @w_er_secuencial  int,
            @w_er_tran        catalogo,
            @w_er_fecha_mov   datetime
         
         open cur_transacciones
         
         fetch cur_transacciones
         into  @w_er_secuencial, @w_er_tran, @w_er_fecha_mov
         
         while (@@fetch_status = 0)
         begin
            select @w_anexo = 'transaccion : ' + convert(varchar, @w_er_secuencial)
                            + 'tipo transaccion : ' + @w_er_tran
                            + 'fecha : ' + convert(varchar, @w_er_fecha_mov)
            
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
            
            --
            fetch cur_transacciones
            into  @w_er_secuencial, @w_er_tran, @w_er_fecha_mov
         end
         
         close cur_transacciones
         deallocate cur_transacciones
      end
      ELSE -- OTROS ERRORES
      begin
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
   
   fetch cursor_operacion_trc
   into  @w_operacionca,    @w_banco,              @w_toperacion,          
         @w_moneda,         @w_oficina,            @w_tramite,
         @w_gar_admisible,  @w_tipo,         
         @w_oficial,        @w_reestructuracion,   @w_co_calif_final,
         @w_causacion,      @w_fecha_ult_proceso,  @w_co_calif_antes
end -- cursor_operacion_trc */   ---(4)

close cursor_operacion_trc
deallocate cursor_operacion_trc

return 0

ERROR1:

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
