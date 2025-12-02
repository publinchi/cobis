/*batch_obligaciones_msv.sp *********************************************/
/*   Archivo:             batch_obligaciones_msv.sp                     */
/*   Stored procedure:    sp_batch_obligaciones_msv                     */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        Ricardo Reyes                                 */
/*   Fecha de escritura:  Feb. 2013                                     */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Procedimiento que realiza la ejecucion del fin de dia de           */
/*   cartera.                                                           */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_batch_obligaciones_msv')
   drop proc sp_batch_obligaciones_msv
go

create proc sp_batch_obligaciones_msv
@i_param1              varchar(255)  = null,
@i_param2              varchar(255)  = null,
@i_param3              varchar(255)  = null,
@i_param4              varchar(255)  = null,   
@i_param5              varchar(255)  = null,  
@i_param6              varchar(255)  = null, -- RRB Transacciones masivas de cartera

@s_ssn               int         = null,
@s_sesn              int         = null,
@s_date              datetime    = null,
@s_ofi               smallint    = null,
@s_user              login       = null,
@s_rol               smallint    = null,
@s_org               char(1)     = null, 
@s_term              varchar(30) = null,
@s_srv               varchar(30) = null,
@s_lsrv              varchar(30) = null,
@i_banco             cuenta      = null,
@i_debug             char(1)     = 'N'   

as
declare
@w_return          int,
@w_oficina_central int,
@w_rowcount        int,
@w_cont            int,
@w_marcados        int,
@w_ctrl_fin        char(1),
@i_hijo            varchar(2), 
@i_sarta           int, 
@i_batch           int, 
@i_opcion          char(1), 
@i_bloque          int,
@i_tipo_tr         char(1),
@w_fecha_proceso   datetime,
@w_est_novigente   tinyint,
@w_hora_fin        varchar(5),
@w_reg_loop        tinyint,
@w_ciclo           char(1),
@w_hora_msv        varchar(5),
@w_min_fin         varchar(5),
@w_dato            int,
@w_id_carga        int,
@w_id_Alianza      int,
@w_descripcion     varchar(255),
@w_dato_retornado  varchar(20),
@w_max_sec         int,
@w_fecha_hoy       datetime,
@w_cont_whil       int

if @i_param1 is not null
   select 
   @i_hijo          = convert(varchar(2), rtrim(ltrim(@i_param1))),
   @i_sarta         = convert(int       , rtrim(ltrim(@i_param2))),
   @i_batch         = convert(int       , rtrim(ltrim(@i_param3))),
   @i_opcion        = convert(char(1)   , rtrim(ltrim(@i_param4))),
   @i_bloque        = convert(int       , rtrim(ltrim(@i_param5))),
   @i_tipo_tr       = convert(char(1)   , rtrim(ltrim(@i_param6))),
   @w_ciclo         = 'S',
   @w_descripcion   = 'Error No controlado Hijo: ' + @i_param1 + ' Sarta: ' + @i_param2 + ' Batch: ' + @i_param3

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

select @w_fecha_hoy = getdate()

-- Eliminacion cobis..ba_log 
delete cobis..ba_log where lo_sarta = @i_sarta and lo_batch = @i_batch and datediff(dd, lo_fecha_inicio, @w_fecha_hoy  ) = 0 and lo_intento > 1

exec @w_return = sp_estados_cca
@o_est_novigente  = @w_est_novigente out

if @i_opcion = 'G' begin  -- generar universo

   ---------- ELIMINACION DE ARHIVOS DE CARPETA OUTDIR ------------------------------------------------------------------
   if @i_hijo = '0' begin  -- Se ejecuta solo para el promer hijo

      exec @w_return = cobis..sp_elim_msv_outdir
      @i_sarta       = @i_sarta,
      @i_batch       = @i_batch,
      @o_descripcion = @w_descripcion  out


      if @w_return <> 0 begin
         exec cobis..sp_error_proc_masivos
         @i_id_carga        = @w_id_carga,      
         @i_id_alianza      = @w_id_Alianza,      
         @i_referencia      = 'No_Id', 
         @i_tipo_proceso    = 'C', 
         @i_procedimiento   = 'sp_batch_clientes_msv',
         @i_codigo_interno  = 0,       
         @i_codigo_err      = 999999,
         @i_descripcion     = @w_descripcion

      end
   end

   ---------- GENERAR UNIVERSO ------------------------------------------------------------------------------------------
   truncate table ca_universo_operaciones
     
   select @w_cont_whil = 1
   while @w_cont_whil <= 2 begin 

      if @w_cont_whil = 1 select  @i_tipo_tr = 'E' -- REAJUSTES
      if @w_cont_whil = 2 select  @i_tipo_tr = 'R' -- RENOVACIONES

      select @w_cont_whil = @w_cont_whil + 1

      -- DESEMBOLSOS
      select @w_max_sec = max(sb_secuencial)+1 from cobis..ba_sarta_batch where sb_sarta = @i_sarta

      select @w_reg_loop = 2
      while  @w_reg_loop < @w_max_sec begin
         insert into ca_universo_operaciones values (9999999, 0, 0, convert(char(1),@w_reg_loop) , 0, @i_tipo_tr)
         select @w_reg_loop = @w_reg_loop + 1
      end
   
   end 
          
   delete cobis..ba_ctrl_ciclico    
   where ctc_sarta = @i_sarta       
                                    
   insert into cobis..ba_ctrl_ciclico
   select sb_sarta,sb_batch, sb_secuencial, 'S', 'P'
   from cobis..ba_sarta_batch  with (nolock)
   where sb_sarta = @i_sarta        
   and   sb_batch = @i_batch        
                                    
   return 0
   
end

--- OPCION QUE SE EJECUTARA SOLO SI EL PROCESO ES EL BATCH MASIVO (NO PARA FECHA VALOR)   
if @i_opcion = 'B' begin  --procesos batch

   select @w_cont_whil = 1
   while @w_cont_whil <= 2 begin 

      if @w_cont_whil = 1 select  @i_tipo_tr = 'E' -- REAJUSTES
      if @w_cont_whil = 2 select  @i_tipo_tr = 'R' -- RENOVACIONES

      select @w_cont_whil = @w_cont_whil + 1

      select @w_cont = count(*)
      from ca_universo_operaciones with (nolock)
      where ub_estado   = @i_hijo
      and   ub_intentos < 2
      and   ub_tipo_tra = @i_tipo_tr
   
      select @w_cont = @i_bloque - @w_cont
   
      if @w_cont < 0 select @w_cont = @i_bloque

      if @w_cont > 0 begin
   
         set rowcount @w_cont
      
         update ca_universo_operaciones with (rowlock) set
         ub_estado = @i_hijo
         where ub_estado   = 'N'
         and   ub_intentos < 2  -- controlar que un préstamos se intente procesar 2 veces
         and   ub_dato     <> 9999999
         and   ub_tipo_tra = @i_tipo_tr
      
         if @@error <> 0 return 710001
      
         set rowcount 0
      
      end
   
      update cobis..ba_ctrl_ciclico with (rowlock) set
      ctc_estado = 'P'
      where ctc_sarta      = @i_sarta
      and   ctc_batch      = @i_batch
      and   ctc_secuencial = @i_hijo
   
      --- CONTROL DE TERMINACION DE PROCESO 
      if not exists(select 1 from ca_universo_operaciones with (nolock)
      where ub_estado   = @i_hijo
      and   ub_intentos < 2
      and   ub_tipo_tra = @i_tipo_tr) 
      begin
         update cobis..ba_ctrl_ciclico with (rowlock) set
         ctc_procesar = 'N'
         where ctc_sarta      = @i_sarta
         and   ctc_batch      = @i_batch
         and   ctc_secuencial = @i_hijo
      
         if @@error <> 0 return 710002  

      end
   end
end

--SET TRANSACTION ISOLATION LEVEL SNAPSHOT   


select @w_cont_whil = 1
while @w_cont_whil <= 2 begin 

   if @w_cont_whil = 1 select  @i_tipo_tr = 'E' -- REAJUSTES
   if @w_cont_whil = 2 select  @i_tipo_tr = 'R' -- RENOVACIONES

   select @w_cont_whil = @w_cont_whil + 1

   --- EJECUCION DEL PROCESO BATCH 
   exec @w_return = sp_batch_obligaciones_msv_1
   --@s_ssn           = @s_ssn,
   --@s_sesn          = @s_sesn,
   --@s_srv           = @s_srv,
   @s_lsrv          = 'lsrv',
   @s_user          = 'sa',              -- @s_user,
   @s_date          = @w_fecha_proceso,  -- '02/26/2013',  -- @s_date,
   @s_ofi           = 0,                 -- @s_ofi,
   @s_rol           = 125,
   --@s_org           = @s_org,
   @s_term          = 'term',
   @i_hijo          = @i_hijo,
   @i_debug         = @i_debug,
   @i_tipo_tr       = @i_tipo_tr,
   @i_fecha_proceso = @w_fecha_proceso,
   @i_bloque        = @i_bloque,
   @o_ciclo         = @w_ciclo       out,
   @o_id_carga      = @w_id_carga    out,
   @o_id_Alianza    = @w_id_Alianza  out,   
   @o_dato          = @w_dato        out

   if @@ERROR <> 0  or isnull(@w_return,00) <> 0 begin
      select                 
      @w_id_carga   = ISNULL(@w_id_carga,0),      
      @w_id_Alianza = ISNULL(@w_id_Alianza,0),
      @w_dato       = ISNULL(@w_dato,0)
      select @w_dato_retornado = CONVERT(varchar(20),@w_dato)

      if isnull( @w_return,0) <> 0 begin 
         select @w_descripcion   = 'Error: ' + 'Cod.Error:' + cast(isnull( @w_return,0) as varchar) +' Hijo:' + @i_param1 + ' Sarta: ' + @i_param2 + ' Batch: ' + @i_param3 + ' return:'+ convert( varchar(20), isnull( @w_return,0)) 
         select @w_descripcion = @w_descripcion + '. - ' + mensaje  from cobis..cl_errores where numero = @w_return
      end

      exec cobis..sp_error_proc_masivos
      @i_id_carga        = @w_id_carga,      
      @i_id_alianza      = @w_id_Alianza,      
      @i_referencia      = @w_dato_retornado,
      @i_tipo_proceso    = 'C', 
      @i_procedimiento   = 'sp_batch_obligacion_msv_1',   
      @i_codigo_interno  = 0,       
      @i_codigo_err      = 9999999,      
      @i_descripcion     = @w_descripcion
   
      --select @w_hora_fin = case when len(convert(varchar(2),datepart(hh,getdate()))) = 1 then '0' + convert(varchar(2),datepart(hh,getdate())) else  convert(varchar(2),datepart(hh,getdate())) end, 
      --       @w_min_fin  = case when len(convert(varchar(2),datepart(mi,getdate()))) = 1 then '0' + convert(varchar(2),datepart(mi,getdate())) else  convert(varchar(2),datepart(mi,getdate())-1) end
      
      if len(convert(varchar(2),datepart(hh,getdate()))) = 1
         select @w_hora_fin = '0' + convert(varchar(2),datepart(hh,getdate()))
      else
	 select @w_hora_fin = convert(varchar(2),datepart(hh,getdate())
  
      if len(convert(varchar(2),datepart(mi,getdate()))) = 1
	 select @w_min_fin = '0' + convert(varchar(2),datepart(mi,getdate()))
      else
         select @w_min_fin = convert(varchar(2),datepart(mi,getdate())-1)
          
      select @w_hora_msv  = @w_hora_fin + ':' + @w_min_fin
   
      update cobis..cl_parametro
      set pa_char = @w_hora_msv 
      where pa_nemonico = 'HFINMS'
      and   pa_producto = 'MIS'
   
      delete ca_universo_operaciones
      where ub_estado   = @i_hijo
      and   ub_tipo_tra = @i_tipo_tr

   end
end

if @i_opcion = 'B' begin -- Validacion para marcacion de todos los hilos como finalizados   
   if @w_ciclo = 'N' begin
      update cobis..ba_ctrl_ciclico with (rowlock) set
      ctc_estado = 'F'
      where ctc_sarta      = @i_sarta
      and   ctc_batch      = @i_batch
      and   ctc_secuencial = @i_hijo
      
      if @@error <> 0 return 710002  
   end

   exec cobis..sp_proc_masivos
   @i_param1 = @w_fecha_hoy,  --Fecha del Proceso
   @i_param2 = 'N'        ,   --Id Transaccion (T,C,N)
   @i_param3 = 'R'        ,   --Id Tipo Trans Si es tipo T (O,C,U,D,R,E) -- Si es Clientes NO APLICA
   @i_param4 = @w_id_carga    --Secuencial de Carga
end

return @w_return

go
