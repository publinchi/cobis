use cob_cartera
go

IF OBJECT_ID ('dbo.sp_simular_pago_openpay') IS NOT NULL
	DROP PROCEDURE dbo.sp_simular_pago_openpay
GO

create proc sp_simular_pago_openpay
(
@i_param1  CHAR(1)     = 'G', -- G GRPAL, P GRUPAL, I  INDIVIDUAL , R  Referencia especifica
@i_param2  VARCHAR(64) = '',  -- referencia
@i_param3  int         = 0,   -- grupo operacion
@i_param4  int         = 0,   -- tramite
@i_param5  int         = 0,   -- Operacion para Individual
@i_param6  varchar(10) = null, -- fecha pago
@i_param7  varchar(15) = null, -- monto pago
@i_param8  catalogo    = 'SANTANDER', --corresponsal (forma de pago)
@i_param9  varchar(255)= null
)
as 
declare
@w_error             int,
@w_fecha_inicial     datetime,
@w_fecha_dia         datetime,
@w_sp_name           varchar(30),
@w_msg               varchar(255),
@w_fecha_proc        DATETIME, 
@w_op_grupal         INT, 
@w_fecha_pago        DATETIME, 
@w_tramite_gr        INT, 
@w_fecha_pro_orig    DATETIME, 
@w_grupo             INT, 
@w_est_vigente       int,
@w_est_vencido       int,
@w_moneda            TINYINT,
@w_descripcion       VARCHAR(255),
@w_num_dec           INT,
@w_tramite_grupal    int,
@i_operacion         CHAR(1) ,      -- G GRPAL, P GRUPAL, I  INDIVIDUAL , R  Referencia especifica
@i_referencia        VARCHAR(64), 
@i_grupo             int ,     -- grupo operacion
@i_tramite           int ,       -- tramite
@i_operacionca       int,
@i_monto             varchar(15),
@i_fecha             varchar(10),
@i_corresponsal      catalogo,
@i_archivo_pago      varchar(255),    
@w_secuencial        INT,
@w_co_corresponsal   varchar(64),
@w_co_tipo           char(2),
@w_co_codigo_interno int,
@w_co_fecha_proceso  datetime,
@w_co_fecha_valor    datetime, 
@w_co_referencia     varchar(64),
@w_co_moneda         tinyint, 
@w_co_monto          money,
@w_co_estado         char(2)


select
@i_operacion   = @i_param1,   -- G GRPAL, P GRUPAL, I  INDIVIDUAL , R  Referencia especifica
@i_referencia  = @i_param2, 
@i_grupo       = @i_param3, 
@i_tramite     = @i_param4, 
@i_operacionca = @i_param5,
@i_fecha       = @i_param6,
@i_monto       = @i_param7,
@i_corresponsal= @i_param8,  --Forma de Pago: OPEN_PAY, SANTANDER
@i_archivo_pago= @i_param9


select @w_sp_name = 'sp_simular_pago_openpay'


SELECT @w_fecha_proc = fp_fecha FROM cobis..ba_fecha_proceso

select @i_fecha = replace(isnull(@i_fecha, convert(varchar(10), @w_fecha_proc, 103)), '/', '')

exec @w_error   = sp_estados_cca
@o_est_vigente  = @w_est_vigente   OUT,
@o_est_vencido  = @w_est_vencido   OUT

if @w_error <> 0
begin 
   SELECT
   @w_error = 701103,
   @w_msg = 'Error !:No exite estado vencido'
   goto ERROR_FIN
end


--- NUMERO DE DECIMALES 
exec @w_error = sp_decimales
@i_moneda      = @w_moneda ,
@o_decimales   = @w_num_dec out

if @w_error <> 0
begin 
   SELECT 
   @w_error = 701103,
   @w_descripcion = 'Error !:No existe parametro para n+â-¦mero de decimales'
   goto ERROR_FIN
end

if @i_operacion = 'E' begin --Eliminar referencia
 
    if @i_tramite <> 0 begin
    
      select 
      @w_grupo = tg_grupo
      from cob_credito..cr_tramite_grupal 
      WHERE tg_tramite in (@i_tramite)
      
      
      SELECT 
      @w_op_grupal     = op_operacion
      FROM ca_operacion 
      WHERE op_tramite = @i_tramite      
     

      if exists (select 1 from ca_corresponsal_trn where co_codigo_interno = @w_op_grupal AND co_estado = 'I')
      begin 
      
         delete from ca_corresponsal_trn where co_codigo_interno = @w_op_grupal AND co_estado = 'I'
      
         if @w_error <> 0 begin
            select 
            @w_error = 701085,
            @w_msg  = 'NO SE ELIMINO EL REGISTRO PAGO CORRESPONSAL '
             
            goto ERROR_FIN
         end
      end
      else begin
  
         select 
         @w_error = 701085,
         @w_msg  = 'NO EXISTE REGISTRO DE TRAMITE GRUPAL O YA FUE PROCESADO '
             
         goto ERROR_FIN
      end    
   end
end  



if @i_operacion = 'R' begin
    
   --PRINT 'rerwerwererer' 
   if @i_referencia <> '' begin
   
      --if not exists (select 1 from ca_corresponsal_trn where co_referencia = @i_referencia AND co_estado = 'I')
      --BEGIN 
      
         EXECUTE @w_error = sp_pagos_corresponsal 
         @s_ssn          = 54538,
         @s_date         = @w_fecha_proc,
         @s_user         = 'usrbatch',
         @s_term         = 'consola',
         @s_ofi          =  1101,
         @s_srv          = 'CTSSSRV',
         @s_lsrv         = 'CTSSSRV',
         @s_rol          = 3,
         @i_operacion    = 'I',-- (B)atch, (S)ervicio, (C)onciliacion manual , (I) Insercion
         @i_referencia   = @i_referencia, -- no obligatorio para batch
         @i_corresponsal = @i_corresponsal, --'OPEN_PAY', -- no obligatorio para batch
         @i_moneda       = 0, -- obligatoria para el servicio
         @i_fecha_valor  = @w_fecha_proc, -- obligatoria para el servicio
         @i_status_srv   = NULL, -- obligatoria para el servicio
         @i_observacion  = 'ok ', -- obligatoria para la conciliacion
		 @i_monto_pago   = @i_monto, --monto del pago
		 @i_fecha_pago   = @i_fecha, --fecha de pago
		 @i_archivo_pago = @i_archivo_pago,
         @o_msg          = 'PRUEBA PAGO '
         
         if @w_error <> 0 begin
          select @w_error = 701085,
                 @w_msg  = 'NO SE INSERTO EL REGISTRO PAGO CORRESPONSAL '
          
          goto ERROR_FIN
         end
		 
      --end 
      
   end
   else begin
  
      select 
      @w_error = 701085,
      @w_msg  = 'NO SE INGRESO CODIGO DE REFERENCIA '
          
      goto ERROR_FIN
    end    
   
end


if @i_operacion = 'G' begin
   
   if @i_tramite <> 0 BEGIN
      
      SELECT @w_grupo = io_campo_1
      FROM cob_workflow..wf_inst_actividad, 
      cob_workflow..wf_inst_proceso
      WHERE ia_nombre_act LIKE '%ESPERA AUTOMATICA GAR LIQUIDA'
      AND ia_estado = 'ACT'
      AND ia_id_inst_proc = io_id_inst_proc
      AND io_estado = 'EJE'
      AND io_campo_3 = @i_tramite

      
      if @@rowcount = 0 BEGIN
         select 
         @w_error = 2101011,
         @w_msg = 'NO EXISTE TRAMITE INGRESADO PARA EL GRUPO: ' +  convert(varchar,@i_grupo)
         
         goto ERROR_FIN
      END
      
      select 
      @w_co_referencia =  dbo.CalcularDigitoVerificadorOpenPay ((REPLICATE('0', 6 - DATALENGTH(convert(VARCHAR,1123))) +  convert(VARCHAR,1123)) +
      (REPLICATE('0', 7 - DATALENGTH(convert(VARCHAR,gl_grupo ))) +  convert(VARCHAR,gl_grupo)) + 'G' +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,DAY(max(gl_fecha_vencimiento  ))))) +  convert(VARCHAR,DAY (max(gl_fecha_vencimiento  )))) +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,MONTH (max(gl_fecha_vencimiento  ))))) +  convert(VARCHAR,MONTH (max(gl_fecha_vencimiento  )))) +
      SUBSTRING ( convert(VARCHAR,YEAR (max(gl_fecha_vencimiento))) ,3 ,DATALENGTH(convert(VARCHAR,YEAR (max(gl_fecha_vencimiento  ))))) + 
      (REPLICATE('0', 8 - DATALENGTH(replace(convert(VARCHAR,abs(sum(gl_monto_garantia - isnull(gl_pag_valor, 0)))),'.','')))) + replace(convert(VARCHAR,abs(sum(gl_monto_garantia - isnull(gl_pag_valor,0)))),'.',''))
      from  ca_garantia_liquida, cob_workflow..wf_inst_actividad, cob_workflow..wf_inst_proceso
      WHERE ia_id_inst_proc = io_id_inst_proc
      AND io_campo_1 = gl_grupo
      AND gl_tramite = io_campo_3
      AND ia_nombre_act LIKE '%ESPERA AUTOMATICA GAR LIQUIDA'
      AND ia_estado = 'ACT'
      AND io_estado = 'EJE'      
      AND io_campo_1 = @w_grupo 
      and io_campo_3 = @i_tramite
      AND gl_monto_garantia > isnull(gl_pag_valor,0)
      GROUP BY gl_grupo
      
      if @@error <> 0 begin
          select @w_error = 701085,
                 @w_msg  = 'NO SE GENERO LA REFERENCIA DEL TRAMITE ' +  convert(VARCHAR ,@i_tramite)
          
          goto ERROR_FIN
      END
     
      if not exists (select 1 from ca_corresponsal_trn where co_referencia = @i_referencia AND co_estado = 'I')
      begin
      
         EXECUTE @w_error = sp_pagos_corresponsal 
         @s_ssn          = 54538,
         @s_date         = @w_fecha_proc,
         @s_user         = 'usrbatch',
         @s_term         = 'consola',
         @s_ofi          =  1101,
         @s_srv          = 'CTSSSRV',
         @s_lsrv         = 'CTSSSRV',
         @s_rol          = 3,
         @i_operacion    = 'I',-- (B)atch, (S)ervicio, (C)onciliacion manual
         @i_referencia   = @w_co_referencia, -- no obligatorio para batch
         @i_corresponsal = @i_corresponsal,  --'OPEN_PAY', -- no obligatorio para batch
         @i_moneda       = 0, -- obligatoria para el servicio
         @i_fecha_valor  = @w_fecha_proc, -- obligatoria para el servicio
         @i_status_srv   = NULL, -- obligatoria para el servicio
		 --@i_monto_pago   = @i_monto, --monto del pago
		 @i_fecha_pago   = @i_fecha, --fecha de pago
         @i_observacion  = 'Ok PAGO', -- obligatoria para la conciliacion
         @o_msg          = 'PAGO GARANTIA BATCH'
         
         if @@error <> 0 begin
             select @w_error = 701085,
                    @w_msg  = 'NO SE PROCESO EL REGISTRO' +  @w_co_referencia
             
             goto ERROR_FIN
         end
      end
   end
   else
   BEGIN
        
        
      INSERT INTO ca_corresponsal_trn (co_corresponsal, co_tipo, co_codigo_interno, co_fecha_proceso, co_fecha_valor, 
      co_referencia, co_moneda, co_monto, co_status_srv, co_estado, co_error_id, co_error_msg, 
      co_archivo_ref, co_archivo_fecha_corte, co_archivo_carga_usuario, co_concil_est, co_concil_motivo, co_concil_user,
      co_concil_fecha, co_concil_obs)
      select 
      @i_corresponsal, --'OPEN_PAY', 
      'G', 
      gl_grupo ,
      @w_fecha_proc,
      @w_fecha_proc,
      dbo.CalcularDigitoVerificadorOpenPay ((REPLICATE('0', 6 - DATALENGTH(convert(VARCHAR,1123))) +  convert(VARCHAR,1123)) +
      (REPLICATE('0', 7 - DATALENGTH(convert(VARCHAR,gl_grupo ))) +  convert(VARCHAR,gl_grupo)) + 'G' +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,DAY(max(gl_fecha_vencimiento  ))))) +  convert(VARCHAR,DAY (max(gl_fecha_vencimiento  )))) +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,MONTH (max(gl_fecha_vencimiento  ))))) +  convert(VARCHAR,MONTH (max(gl_fecha_vencimiento  )))) +
      SUBSTRING ( convert(VARCHAR,YEAR (max(gl_fecha_vencimiento))) ,3 ,DATALENGTH(convert(VARCHAR,YEAR (max(gl_fecha_vencimiento  ))))) + 
      (REPLICATE('0', 8 - DATALENGTH(replace(convert(VARCHAR,sum(gl_monto_garantia - isnull(gl_pag_valor, 0))),'.','')))) + replace(convert(VARCHAR,sum(gl_monto_garantia - isnull(gl_pag_valor,0))),'.','')),
      0,
      sum(gl_monto_garantia - isnull(gl_pag_valor,0)),
      'EJECUTADO',
      'I', 
      NULL, NULL, NULL, NULL, NULL, NULL, 
      NULL, NULL, NULL, NULL
      from  ca_garantia_liquida,
      cob_workflow..wf_inst_actividad, 
      cob_workflow..wf_inst_proceso
      WHERE ia_id_inst_proc = io_id_inst_proc
      AND io_campo_1 = gl_grupo
      AND gl_tramite = io_campo_3
      AND ia_nombre_act LIKE '%ESPERA AUTOMATICA GAR LIQUIDA'
      AND ia_estado = 'ACT'
      AND io_estado = 'EJE'      
      AND gl_monto_garantia > isnull(gl_pag_valor,0)
      GROUP BY gl_grupo
     

      if @@error <> 0 begin
          select @w_error = 701085,
                 @w_msg  = 'NO SE INSERTO EL REGISTRO'
          
          goto ERROR_FIN
      END
   
   end
end   

if @i_operacion = 'P' begin
   
   if @i_tramite <> 0 begin
      
      select 
      @w_grupo = tg_grupo
      from cob_credito..cr_tramite_grupal 
      WHERE tg_tramite in (@i_tramite)
      
      
      SELECT 
      @w_op_grupal     = op_operacion
      FROM ca_operacion 
      WHERE op_tramite = @i_tramite      
      
      
      INSERT INTO ca_corresponsal_trn (co_corresponsal, co_tipo, co_codigo_interno, co_fecha_proceso, 
      co_fecha_valor, co_referencia, co_moneda, co_monto, 
      co_status_srv, co_estado)
      select 
      @i_corresponsal, --'OPEN_PAY', 
      'P', 
      @w_op_grupal,
      @w_fecha_proc,
      @w_fecha_proc,
      dbo.CalcularDigitoVerificadorOpenPay ((REPLICATE('0', 6 - DATALENGTH(convert(VARCHAR,1123))) +  convert(VARCHAR,1123)) +
      (REPLICATE('0', 7 - DATALENGTH(convert(VARCHAR,@w_op_grupal))) +  convert(VARCHAR,@w_op_grupal)) + 'P' +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,DAY(max(di_fecha_ven))))) +  convert(VARCHAR,DAY (max(di_fecha_ven)))) +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,MONTH (max(di_fecha_ven))))) +  convert(VARCHAR,MONTH (max(di_fecha_ven)))) +
      SUBSTRING ( convert(VARCHAR,YEAR (max(di_fecha_ven))) ,3 ,DATALENGTH(convert(VARCHAR,YEAR (max(di_fecha_ven))))) + 
      (REPLICATE('0', 8 - DATALENGTH(replace(convert(VARCHAR,sum(am_cuota - am_pagado)),'.','')))) + replace(convert(VARCHAR,sum(am_cuota - am_pagado)),'.','')),
      0,
      sum(am_cuota - am_pagado),
      'EJECUTADO',
      'I'
      from  ca_operacion , ca_dividendo, ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo
      and   am_operacion = op_operacion 
      AND   op_toperacion = 'GRUPAL'
      AND   op_banco in (SELECT tg_prestamo FROM cob_credito..cr_tramite_grupal  WHERE  tg_grupo = @w_grupo AND tg_tramite = @i_tramite )
      and   (di_estado = @w_est_vencido or ( di_estado = @w_est_vigente and di_fecha_ven = @w_fecha_proc))

      if @@error <> 0 begin
          select @w_error = 701085,
                 @w_msg  = 'NO SE INSERTO EL REGISTRO'
          
          goto ERROR_FIN
      END
   
   end
   else
   begin
   
      IF OBJECT_ID ('#ca_corresponsal_trn_refe1') IS NOT NULL
      DROP TABLE #ca_corresponsal_trn_refe1

      
      select 
      --'OPEN_PAY'  AS co_corresponsal, 
	  @i_corresponsal AS co_corresponsal, 
      'P'         AS co_tipo,
      tg_grupo    AS co_grupo, 
      tg_tramite  AS co_tramite,
      max(di_fecha_ven) AS co_fecha_dividendo,
      0           AS co_codigo_interno,
      @w_fecha_proc AS co_fecha_proceso,
      @w_fecha_proc AS co_fecha_valor,
      ''          AS co_referencia,
      0           AS co_moneda,
      sum(am_cuota - am_pagado) AS co_monto,
      'EJECUTADO' AS co_status_srv ,
      'I'         AS co_estado
      INTO #ca_corresponsal_trn_refe1
      from  ca_operacion , ca_dividendo, ca_amortizacion,cob_credito..cr_tramite_grupal
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo
      and   am_operacion = op_operacion
      AND   tg_prestamo  = op_banco
      AND   op_toperacion = 'GRUPAL'
      and   (di_estado = @w_est_vencido or ( di_estado = @w_est_vigente and di_fecha_ven = @w_fecha_proc))
      GROUP BY tg_grupo,tg_tramite    
      
      
      update #ca_corresponsal_trn_refe1
      set co_codigo_interno = op_operacion,
      co_estado             = 'I'
      from ca_operacion, #ca_corresponsal_trn_refe1
      where op_tramite = co_tramite
      
      INSERT INTO ca_corresponsal_trn (co_corresponsal ,	co_tipo    ,	co_codigo_interno   ,	co_fecha_proceso   ,	co_fecha_valor  ,
      co_referencia ,	co_moneda  ,	co_monto ,	co_status_srv ,	co_estado)
      select 
      co_corresponsal, 
      co_tipo,
      co_codigo_interno,
      co_fecha_proceso,
      co_fecha_valor,
      dbo.CalcularDigitoVerificadorOpenPay ((REPLICATE('0', 6 - DATALENGTH(convert(VARCHAR,1123))) +  convert(VARCHAR,1123)) +
      (REPLICATE('0', 7 - DATALENGTH(convert(VARCHAR,co_codigo_interno))) +  convert(VARCHAR,co_codigo_interno )) + 'P' +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,DAY(co_fecha_dividendo)))) +  convert(VARCHAR,DAY (co_fecha_dividendo))) +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,MONTH (co_fecha_dividendo)))) +  convert(VARCHAR,MONTH (co_fecha_dividendo))) +
      SUBSTRING ( convert(VARCHAR,YEAR (co_fecha_dividendo)) ,3 ,DATALENGTH(convert(VARCHAR,YEAR (co_fecha_dividendo)))) + 
      (REPLICATE('0', 8 - DATALENGTH(replace(convert(VARCHAR,co_monto),'.','')))) + replace(convert(VARCHAR,co_monto),'.','')),
      0,
      co_monto,
      co_status_srv,
      co_estado
      from  #ca_corresponsal_trn_refe1
       
      if @@error <> 0 begin
          select @w_error = 701085,
                 @w_msg  = 'NO SE INSERTO EL REGISTRO'
          
          goto ERROR_FIN
      end
      
       
   end


end

if @i_operacion = 'I' begin
        
   if  @i_operacionca <> 0 begin
       
      INSERT INTO ca_corresponsal_trn (co_corresponsal, co_tipo, co_codigo_interno, co_fecha_proceso, 
      co_fecha_valor, co_referencia, co_moneda, co_monto, 
      co_status_srv, co_estado)
       select 
      @i_corresponsal, --'OPEN_PAY', 
      'I'       ,
      op_operacion, 
      @w_fecha_proc,
      @w_fecha_proc,
      dbo.CalcularDigitoVerificadorOpenPay ((REPLICATE('0', 6 - DATALENGTH(convert(VARCHAR,1123))) +  convert(VARCHAR,1123)) +
      (REPLICATE('0', 7 - DATALENGTH(convert(VARCHAR,op_operacion))) +  convert(VARCHAR,op_operacion)) + 'I' +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,DAY(max(di_fecha_ven))))) +  convert(VARCHAR,DAY (max(di_fecha_ven)))) +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,MONTH (max(di_fecha_ven))))) +  convert(VARCHAR,MONTH (max(di_fecha_ven)))) +
      SUBSTRING ( convert(VARCHAR,YEAR (max(di_fecha_ven))) ,3 ,DATALENGTH(convert(VARCHAR,YEAR (max(di_fecha_ven))))) + 
      (REPLICATE('0', 8 - DATALENGTH(replace(convert(VARCHAR,sum(am_cuota - am_pagado)),'.','')))) + replace(convert(VARCHAR,sum(am_cuota - am_pagado)),'.','')),
      0        ,
      sum(am_cuota - am_pagado),
      'EJECUTADO',
      'I'
      from  ca_operacion , ca_dividendo, ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo
      and   am_operacion = op_operacion
      AND   op_toperacion = 'INDIVIDUAL'
      and   op_operacion  = @i_operacionca
      and   (di_estado = @w_est_vencido or ( di_estado = @w_est_vigente and di_fecha_ven = @w_fecha_proc))
      GROUP BY op_operacion  
      
      if @@error <> 0 begin
          select @w_error = 701085,
                 @w_msg  = 'NO SE INSERTO EL REGISTRO'
          
          goto ERROR_FIN
      END 
      
   END
   ELSE
   BEGIN
   
   
      INSERT INTO ca_corresponsal_trn (co_corresponsal, co_tipo, co_codigo_interno, co_fecha_proceso, 
      co_fecha_valor, co_referencia, co_moneda, co_monto, 
      co_status_srv, co_estado)
      select 
      @i_corresponsal, --'OPEN_PAY', 
      'I'       ,
      op_operacion, 
      @w_fecha_proc,
      @w_fecha_proc,
      dbo.CalcularDigitoVerificadorOpenPay ((REPLICATE('0', 6 - DATALENGTH(convert(VARCHAR,1123))) +  convert(VARCHAR,1123)) +
      (REPLICATE('0', 7 - DATALENGTH(convert(VARCHAR,op_operacion))) +  convert(VARCHAR,op_operacion)) + 'I' +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,DAY(max(di_fecha_ven))))) +  convert(VARCHAR,DAY (max(di_fecha_ven)))) +
      (REPLICATE('0', 2 - DATALENGTH(convert(VARCHAR,MONTH (max(di_fecha_ven))))) +  convert(VARCHAR,MONTH (max(di_fecha_ven)))) +
      SUBSTRING ( convert(VARCHAR,YEAR (max(di_fecha_ven))) ,3 ,DATALENGTH(convert(VARCHAR,YEAR (max(di_fecha_ven))))) + 
      (REPLICATE('0', 8 - DATALENGTH(replace(convert(VARCHAR,sum(am_cuota - am_pagado)),'.','')))) + replace(convert(VARCHAR,sum(am_cuota - am_pagado)),'.','')),
      0        ,
      sum(am_cuota - am_pagado),
      'EJECUTADO',
      'I'
      from  ca_operacion , ca_dividendo, ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo
      and   am_operacion = op_operacion
      AND   op_toperacion = 'INDIVIDUAL'
      and   (di_estado = @w_est_vencido or ( di_estado = @w_est_vigente and di_fecha_ven = @w_fecha_proc))
      GROUP BY op_operacion    
      
      if @@error <> 0 begin
          select @w_error = 701085,
                 @w_msg  = 'NO SE INSERTO EL REGISTRO'
          
          goto ERROR_FIN
      END    
   
   end
   
     
end

RETURN 0

ERROR_FIN:       
--print 'Error!!!'+ convert(VARCHAR, @w_error)


exec sp_errorlog 
@i_fecha = @w_fecha_proc,
@i_error       = @w_error,
@i_usuario     = 'usrbatch',
@i_tran        = 7999,
@i_tran_name   = @w_sp_name,
@i_cuenta      = 'PAGO OPENPAY',
@i_descripcion = @w_msg, 
@i_rollback    = 'S'

return @w_error




GO

