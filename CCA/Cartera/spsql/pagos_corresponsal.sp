
/************************************************************************/
/*    Base de datos:          cob_cartera                               */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Javier calderon                         */
/*      Fecha de escritura:     27/06/2017                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                         PROPOSITO                                    */
/*      Tiene como prop�sito procesar los pagos de los corresponsales   */
/*                        MOFICIACIONES                                 */
/* 27/11/2017         MTA                  Se aumenta la operacion a la */
/*                                         tabla del log de pagos       */
/* 02/04/2018         MTA                  Cambio de am_acumulado por   */
/*                                         am_cuota                     */
/* 24/07/2018         SRO                  Anulaci�n de Pagos           */
/* 01/06/2022         GFP                  Se comenta prints            */
/************************************************************************/  
use cob_cartera
go

IF OBJECT_ID ('dbo.sp_pagos_corresponsal') IS NOT NULL
    DROP PROCEDURE dbo.sp_pagos_corresponsal
GO

create proc sp_pagos_corresponsal
(
@s_ssn             int         = 1,
@s_sesn            int         = 1,
@s_date            datetime    = null,
@s_user            login       = 'usrbatch',
@s_term            varchar(30) = 'consola',
@s_ofi             smallint    = null,
@s_srv             varchar(30) = 'CTSSRV',
@s_lsrv            varchar(30) = 'CTSSRV',
@s_rol             smallint    = null,
@s_org             varchar(15) = null,
@s_culture         varchar(15) = null,
@i_operacion       CHAR(1),            -- (B)atch, (S)ervicio, (C)onciliacion manual
@i_referencia      VARCHAR(64) = NULL, -- no obligatorio para batch
@i_corresponsal    VARCHAR(64) = NULL, -- no obligatorio para batch
@i_moneda          int         = 0, -- obligatoria para el servicio
@i_fecha_valor     DATETIME    = NULL, -- obligatoria para el servicio
@i_status_srv      VARCHAR(64) = '', -- obligatoria para el servicio
@i_observacion     VARCHAR(255)= '', -- obligatoria para la conciliacion
@i_fecha_pago      varchar(8)  = NULL,
@i_monto_pago      varchar(14) = NULL,
@i_archivo_pago    varchar(255)= NULL,
@i_trn_id_corresp  varchar(25) = NULL,
@i_accion          char(1)   = NULL,
@i_en_linea        char(1) = 'N',
@i_externo         char(1)   = 'N', -- S cuando la invocaci�n viene desde un agente externo N(cuando la invocación es desde Cobis)
@i_co_linea        int   = null,--para guardar el numero de linea caundo viene por pagos masivo de la web
@i_pagos_masivos   CHAR(1)            = 'N',  -- Para ejecucion desde pantalla de pagos masivos
@o_msg             varchar(255) = null OUT, --No cambiar el orden, se da�a el SG
@i_token           varchar(255) = null, -- para validar token 
@i_ejecutar_fvalor char(1)     = 'S',               --parametro para no ejecutar fecha valor en el sp_pago_cartera_srv en proceso masivo por remediacion
@o_codigo_err      varchar(50) = null           out, --codigo del error esperado por el corresponsal
@o_mensaje_err    varchar(100) = null          out, --mensaje de error   
@o_monto_recibido  varchar(14) = null out,  --monto recibido
@o_mensaje_ticket varchar(125) = null out,  --mensaje para imprimir en el ticket del coresponsal
@o_cuenta          varchar(30) = null out,   -- referencia para registrar el pago
@o_codigo_pago     varchar(30) = null out,    -- codigo unico de cobis para identificar el pago 
@o_codigo_reversa  varchar(30) = null out
)
as 
declare
@w_error                   int,
@w_fecha_inicial           datetime,
@w_fecha_dia               datetime,
@w_banco                   cuenta,
@w_operacionca             int,
@w_fecha_ult_proceso       datetime,
@w_fecha_respuesta         datetime,
@w_cuenta                  cuenta,
@w_sp_name                 varchar(30),
@w_dividendo               INT,
@w_commit                  char(1),
@w_est_vigente             int,
@w_est_vencido             int,
@w_fecha_pago              datetime,
@w_tipo_pago               catalogo,
@w_secuencial              INT,
@w_tipo                    char(2),           
@w_codigo_interno          varchar(10), 
@w_porcentaje              FLOAT,      
@w_fecha_valor             datetime,          
@w_referencia              varchar(64),       
@w_moneda                  tinyint,           
@w_monto                   money ,            
@w_co_status_srv           varchar(24),    
@w_co_estado               char(1),        
@w_co_error_id             int,            
@w_co_error_msg            varchar(254),   
@w_num_dec                 int,
@w_descripcion             varchar(60),
@w_msg                     varchar(255),
@w_est                     char(2),
@w_forma_pago              catalogo,
@w_total_exigible          MONEY,
@w_total_pago              MONEY,
@w_diferencia              FLOAT,
@w_operacion_int           INT,
@w_banco_int               cuenta,
@w_monto_pago              MONEY,
@w_tramite                 int, 
@w_valor_inicial           money, 
@w_monto_aprobado          MONEY,
@w_tramite_grupal          INT,
@w_digito_verfi            CHAR(1),
@w_cadena                  VARCHAR(64),
@w_cadena_proce            VARCHAR(64),
@w_concil_est              CHAR(1),
@w_concil_motivo           CHAR(2),
@w_archivo_monto           MONEY,
@w_secuencial_ing          int,
@w_secuencial_pag          INT,
@w_sec_ing                 INT,
@w_concil_user             login, 
@w_concil_fecha            datetime,
@w_concil_obs              VARCHAR(255),
@w_estado_pag              CHAR(2),
@w_error_sp                char(1),
@w_monto_garantia          MONEY,
@w_gl_tramite              int,
@w_gl_grupo                int,
@w_gl_cliente              int,
@w_gl_monto_garantia       MONEY,
@w_gl_pag_valor            MONEY,
@w_gl_diferencia           MONEY,
@w_operacion_gar           CHAR(2),
@w_fecha_pro               DATETIME,
@w_total_exigible_fecha    money,
@w_valor_pagado_gar        money,
@w_monto_gar               money,
@w_oficina                 smallint,
@w_cliente                 int,
@w_usuario                 varchar(10),
@w_param_refopenpay        int,
@w_param_refsantander      int,
@w_long_ref                int,
@w_archivo_pag             varchar(64),
@w_param_refsantander_gar  int ,
@w_bandera                 int ,
@w_est_cancelado           int,
@w_ope                     int,
@w_ente                    int,
@w_ciudad_nacional         INT,
@w_formula                 int,
@w_saldo_exigible          money,
@w_saldo_precancelar       money,
@w_sensibilidad            float,
@w_tipo_formula_1          int,
@w_trn_id_corresp          varchar(8),
@w_accion                  char(1),
@w_estado                  char(1),
@w_secuencial_trn_rv       int,
@w_secuencial_trn          int,
@w_sp_val_corresponsal     varchar(50),
@w_id_corresponsal         varchar(10),
@w_estado_trn              char(1),
@w_token_validacion        varchar(255),
@w_limite_max              money,
@w_limite_min              money,
--@w_tipo_tran               char(2),
@w_monto_individual        money,
@w_tanquear                char(1),
@w_fecha_hoy               varchar(10), 
@w_fecha_ult_disper        datetime,
@w_hora_ult_dis            varchar(10),
@w_en_tanqueo              char(1),
@w_monto_tanqueo           money,
@w_min_dividendo           int,
@w_est_trn_reverso	       CHAR(1),
@w_est_corresponsal        char(1),
@w_rowcount                int,
@w_valor_vigente           money,
@w_saldo_cuota             money,
@w_saldo_mas_vencido       money,
@w_trancount               int,
@w_error_tmp               int,
@w_monto_seg               money,
@w_pagado_seg              char(1),
@w_fecha_liq               datetime,
@w_precancela_dias         int,
@w_diferencia_seguro 	   float,
@w_cad_tramite             varchar(100),
@w_sc_tramite              int,
@w_sc_grupo                int,
@w_sc_cliente              int,
@w_sc_monto_seguro		   money,
@w_sc_monto_pagado		   money,
@w_sc_diferencia           money,
@w_promo                   char(1),
@w_monto_seguro_basico     money,
@w_monto_gar_liquida       money,
@w_saldo_exigible_gl       money,
@w_error_id                int,
@w_dividendo_aux           int,
@w_total                   money,
@w_saldo                   money,
@w_precancelar_aux         money         


select @w_cuenta = ''

select @w_fecha_pro = fp_fecha 
from cobis..ba_fecha_proceso
  
select 
@w_sp_name         ='sp_pagos_corresponsal',
@s_date            = isnull(@s_date,@w_fecha_pro),
@w_forma_pago      = @i_corresponsal, --OPEN_PAY,BANCO SANTANDER
@w_commit          = 'N',
@w_error_sp        = '0',
@w_bandera         = 0,
@w_moneda          = isnull(@i_moneda, 0)


-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @@rowcount = 0 begin
   select @w_error = 101024
   goto ERROR_FIN
end


-- PARAMETRO SENSIBILIDAD PARA LIMITES EN DISTRIBUCION DE PAGOS 
select @w_sensibilidad = pa_float
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'SENSI'
and    pa_producto = 'CCA'

if @@rowcount = 0  select @w_sensibilidad = 0


exec @w_error   = sp_estados_cca
@o_est_vigente  = @w_est_vigente   OUT,
@o_est_vencido  = @w_est_vencido   OUT,
@o_est_cancelado= @w_est_cancelado  OUT

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
   @w_descripcion = 'Error !:No existe parametro para numero de decimales'
   goto ERROR_FIN
END


if @i_operacion = 'I' BEGIN    

   if @i_accion not in ('R','I') begin
      select 
	  @w_error = 70202,
      @w_msg = 'ERROR: ACCION NO PERMITIDA ' + @i_accion
      GOTO ERROR_FIN
   end 
 
   select 
   @o_monto_recibido = @i_monto_pago,
   @w_est            = 'I',
   @w_tanquear       = 'N' 

   if not exists (select 1 from ca_producto where cp_producto = @i_corresponsal )  begin
       select 
       @w_error = 70198,
       @o_msg = 'ERROR: CORRESPONSAL NO REGISTRADO COMO FORMA DE PAGO.'
       GOTO ERROR_FIN
    end
    
    select 
    @w_sp_val_corresponsal = co_sp_validacion_ref,
    @w_id_corresponsal     = co_id,
    @w_token_validacion    = co_token_validacion,
    @w_est_corresponsal    = co_estado
    from  ca_corresponsal 
    where co_nombre        = @i_corresponsal
	  
	if @@rowcount = 0 begin
       --select 
       --@w_error = 70209,
	   --@w_msg   = 'ERROR: EL CORRESPONSAL NO EST� REGISTRADO'
	   --GOTO ERROR_FIN
	   --SRO. Caso 111264 Error en reverso nota de d�bito
       select 
       @w_sp_val_corresponsal = null,
       @w_id_corresponsal     = 0,
       @w_token_validacion    = null,
       @w_est_corresponsal    = 'A'
	end

    if @w_token_validacion is not null  and (@i_token is null or @w_token_validacion <> @i_token) begin 
       select 
       @w_error = 70212,
       @w_msg   = 'ERROR: TOKEN NO COINCIDE'
       goto ERROR_FIN
    end
     
    if @i_accion = 'I' begin
       if @w_est_corresponsal <> 'A' begin
          select 
          @w_error = 70209,
     	  @w_msg   = 'ERROR: EL CORRESPONSAL NO EST� ACTIVO'
	      GOTO ERROR_FIN
       end
       
	   exec @w_error     = @w_sp_val_corresponsal
	   @i_referencia     = @i_referencia,   
	   @i_fecha_pago     = @i_fecha_pago,
	   @i_monto_pago     = @i_monto_pago,
	   @i_archivo_pago   = @i_archivo_pago,
	   @o_tipo           = @w_tipo           out,
	   @o_codigo_interno = @w_codigo_interno out,
	   @o_fecha_pago     = @w_fecha_valor    out,
	   @o_monto_pago     = @w_monto          out
	   
       if @w_error <> 0 begin
          select @w_msg = 'Error al ejecutar el sp_val_corresponsal'
          GOTO ERROR_FIN
	   end
       
       select  
       @w_limite_max = cl_limite_max,
       @w_limite_min = cl_limite_min
       from ca_corresponsal_limites 
       where cl_corresponsal_id = @w_id_corresponsal
       and cl_tipo_tran         = @w_tipo
       
       --SI NO EXISTE LAS ENTRADAS PARA EL CORRESPONSAL EN LA TABLA
       if @@rowcount = 0 
          select @w_limite_max = 99999999999, @w_limite_min = 0      
       else 
          select @w_tanquear = 'S'
 
       if @w_monto > @w_limite_max begin 
          select 
          @w_error = 70213,
          @w_msg   = 'ERROR: MONTO A PAGAR SUPERA EL LIMITE DEL CORRESPONSAL'
          goto ERROR_FIN
       end
      
       -- Validacion si la fecha de pago cae en dia feriado
       if exists (select 1 from cob_cartera..ca_det_ciclo, cob_cartera..ca_dividendo
	              where dc_operacion = di_operacion
		          and di_fecha_ven >= @w_fecha_valor
		          and di_estado = 1
		          and dc_grupo = @w_codigo_interno)
       begin
		  -- Si la fecha de vencimiento es mayor o igual a la fecha de pago
          while (exists (select 1 from cobis..cl_dias_feriados where df_fecha = @w_fecha_valor and df_ciudad = @w_ciudad_nacional))
	         select @w_fecha_valor = DATEADD (dd, -1, @w_fecha_valor)
       end else begin
		  -- Si la fecha de vencimiento es menor a la fecha de pago
          while (exists (select 1 from cobis..cl_dias_feriados where df_fecha = @w_fecha_valor and df_ciudad = @w_ciudad_nacional))
             select @w_fecha_valor = DATEADD (dd, 1, @w_fecha_valor)
	   end
       
       select @o_mensaje_ticket = 'SE HA PAGADO '+@i_monto_pago+' CORRESPONDIENTE A LA REFERENCIA '+@i_referencia
       select @o_cuenta = @i_referencia
       
       --solo se tanquea (Garantia Liquida, Cancelacion Grupal y Cancelacion Individual)
       if @w_tipo not in ('GL','CG','CI') 
          select @w_tanquear = 'N' 
                         
       --Validar si existe registro del pago en la tabla
       select @w_secuencial = co_secuencial
       from ca_corresponsal_trn
       where co_referencia = @i_referencia
       and co_estado       = 'I'
       and co_fecha_proceso= @w_fecha_pro
       --and co_fecha_valor  = @w_fecha_pro
         
       if @@rowcount = 0 or @w_tanquear = 'N' begin -- si no existe registro o SI no usa TANQUEO, entonces INSERTA 
         insert into ca_corresponsal_trn (
         co_corresponsal  , co_tipo        , co_codigo_interno , co_fecha_proceso      , co_fecha_valor,
         co_referencia    , co_moneda      , co_monto          , co_status_srv         , co_estado     ,
         co_error_id      , co_error_msg   , co_archivo_ref    , co_concil_est         , co_concil_motivo, 
         co_concil_user   , co_concil_fecha, co_concil_obs     , co_archivo_fecha_corte, co_archivo_carga_usuario,
         co_trn_id_corresp, co_accion      , co_fecha_real)
         values (
         @i_corresponsal,   @w_tipo         , @w_codigo_interno , @w_fecha_pro/*@s_date */        , @w_fecha_valor,
         @i_referencia  ,   @i_moneda       , @w_monto     , @i_status_srv   , @w_est        , 
         null           ,   @w_msg          , @i_archivo_pago   , null            , null          ,
         null           ,   null            , null              , null            , null          ,
         @i_trn_id_corresp, @i_accion       , getdate())

         -- si hay tanqueo, debe retornar la combinaci�n del secuencial de corresponsal_trn con el secuencial de tanqueo
         -- si no hay tanqueo, debe retornar el secuencial del corresponsal_trn
         select @o_codigo_pago =  co_secuencial
         from ca_corresponsal_trn 
         where co_trn_id_corresp = @i_trn_id_corresp 
         and   co_estado         = 'I'

         -- secuencial para retornar cuando hay tanqueo
         select @w_secuencial = co_secuencial
         from ca_corresponsal_trn
         where co_referencia = @i_referencia
         and co_estado       = 'I'
         and co_fecha_proceso= @w_fecha_pro
         --and co_fecha_valor  = @w_fecha_pro
      end 
      else begin -- si existe registro, entonces ACTUALIZA el monto, CUANDO SEA TANQUEO
         
         update ca_corresponsal_trn 
         set co_monto = co_monto + @w_monto
         where co_referencia = @i_referencia
         and co_estado       = 'I'
         and co_fecha_proceso= @w_fecha_pro
         if (@@error != 0) begin
            select 
			@w_error = 70216, 
			@w_msg   = 'ERROR AL ACTUALIZAR MONTO EN TANQUEO'
            goto ERROR_FIN
         end
      end

      if @w_tanquear = 'S' begin  --guardar en la tabla de tanqueo
         insert into ca_corresponsal_tanqueo (
         ct_secuencial_trn    ,ct_trn_id_corresp    ,ct_monto       ,ct_estado
         )
         values(
         @w_secuencial        ,@i_trn_id_corresp    ,@i_monto_pago  ,'I' 
         )

         select @o_codigo_pago = @o_codigo_pago +' '+ ct_secuencial
         from ca_corresponsal_tanqueo
         where ct_trn_id_corresp = @i_trn_id_corresp
      end

      -- Existe una tabla de errores por corresponsal que se consulta en ERROR_FIN, @w_error = 0 es para indicar ejecuci�n exitosa
      select @w_error = 0
      --goto ERROR_FIN se elimina para que pueda hacer pagos en linea
   end -- accion (I)ngresar    


   if @i_accion = 'R' begin
      
      select 
      @w_est_trn_reverso = 'I', 
      @w_en_tanqueo      = 'N'     

      select 
      @w_codigo_interno = co_codigo_interno,
      @w_monto          = co_monto,
      @w_fecha_valor    = co_fecha_valor,
      @i_referencia     = co_referencia,
      @w_est            = co_estado,
      @w_tipo           = co_tipo,
      @w_secuencial_trn = co_secuencial
      from ca_corresponsal_trn 
      where co_trn_id_corresp = isnull(@i_trn_id_corresp,'')
      and co_monto  = convert(money,isnull(@i_monto_pago,0))/100 --SRO. Caso #111264
	  and co_accion = 'I'

      select @w_rowcount = @@rowcount

      if @w_rowcount = 0 begin
         --VALIDAR SI EXISTE EN TANQUEO 
         select 
         @w_secuencial_trn = ct_secuencial_trn,
         @w_monto_tanqueo  = ct_monto,
         @w_est            = ct_estado
         from ca_corresponsal_tanqueo 
         where ct_trn_id_corresp = @i_trn_id_corresp
         
         if @@rowcount = 0 begin
            select 
            @w_est = 'E',
            @w_error = 70180,
            @w_msg = 'ERROR: Transacci�n con id de corresponsal: '+ @i_trn_id_corresp +' a reversar no existe.'
            GOTO ERROR_FIN
         end

         if @w_est = 'A' begin
            select 
            @w_error = 70215, --cambiar numero
            @w_msg   = 'ERROR: EL REGISTRO YA FUE REVERSADO ANTERIORMENTE'
            goto ERROR_FIN      
         end
         
         select @w_en_tanqueo = 'S' --existe en tanqueo

         select 
         @w_codigo_interno = co_codigo_interno,
         @w_monto          = co_monto,
         @w_fecha_valor    = co_fecha_valor,
         @i_referencia     = co_referencia,
         @w_est            = co_estado,
         @w_tipo           = co_tipo
         from ca_corresponsal_trn 
         where co_secuencial = @w_secuencial_trn
		 
      end
	  else if @w_rowcount > 1 begin
	     select 
         @w_est = 'E',
         @w_error = 70211,
         @w_msg = 'ERROR: Existe m�s de un registro con id de corresponsal: '+ @i_trn_id_corresp +' y monto: ' + convert(varchar,(convert(money,isnull(@i_monto_pago,0))/100))
         GOTO ERROR_FIN
	  end

      if @w_est = 'A' begin
         select 
         @w_error = 70215, --cambiar numero
         @w_msg   = 'ERROR: EL REGISTRO YA FUE REVERSADO ANTERIORMENTE'
         goto ERROR_FIN      
      end
      
      if @w_est = 'P' and @w_en_tanqueo = 'S' begin
         select 
         @w_error = 70215,
         @w_msg   = 'ERROR: NO SE PUEDE REVERSAR PARCIALMENTE UNA TRANSACCION YA APLICADA EN COBIS.'      
         goto ERROR_FIN      
      end

      if @w_est = 'P' and @i_externo = 'S' begin
         select 
         @w_error = 70215,
         @w_msg   = 'ERROR: NO SE PUEDE REVERSAR DESDE EL SERVICIO TRN YA APLICADA EN COBIS.'      
         goto ERROR_FIN      
      end

     
      if @w_en_tanqueo = 'S' begin
             
            --marca como anulado en la tabla de tanqueo
            update ca_corresponsal_tanqueo set 
            ct_estado = 'A'
            where ct_trn_id_corresp = @i_trn_id_corresp
            
         if @@error != 0 begin
                select 
			    @w_error = 70217, 
			    @w_msg   = 'ERROR AL ACTUALIZAR ESTADO EN TANQUEO'
               goto ERROR_FIN
            end

            --actualiza el monto en la tabla de transacciones
            update ca_corresponsal_trn
            set co_monto = co_monto - @w_monto_tanqueo
            where co_secuencial = @w_secuencial_trn

            --ingresa un registro de reversa en la tabla de tanqueo
            insert into ca_corresponsal_tanqueo (
            ct_secuencial_trn    ,ct_trn_id_corresp    ,ct_monto,   
            ct_estado)
            values(
            @w_secuencial_trn    ,@i_trn_id_corresp    ,-1*@w_monto_tanqueo,   
            'P')
            
		    if @@error != 0 begin
                select 
			    @w_error = 70218, 
			    @w_msg   = 'ERROR AL INGRESAR REVERSA EN TANQUEO'
               goto ERROR_FIN
            end
            
            select @o_codigo_reversa =  ct_secuencial_trn + ' ' +ct_secuencial 
            from ca_corresponsal_tanqueo 
            where ct_trn_id_corresp = @i_trn_id_corresp 
            and ct_estado = 'P' --registro del reverso
            
            -- si el monto de reversa es igual al monto de la tabla de transacciones, se deja en estado Anulado para que no se intente procesar el Pago
            if @w_monto = @w_monto_tanqueo begin
            
               update ca_corresponsal_trn
               set co_estado = 'A'
               where co_secuencial = @w_secuencial_trn
              
			   if (@@error != 0) begin
                  select 
			      @w_error = 70219, 
			      @w_msg   = 'ERROR AL ACTUALIZAR ESTADO EN TANQUEO'
                  goto ERROR_FIN
               end
            
            select 
            @w_est_trn_reverso = 'P',
            @w_en_tanqueo      = 'N'  -- porque es una reversa total
         end
         
      end else begin -- en reverso no esta en tanqueo

         if @w_est = 'I' BEGIN -- si el pago no fue procesado en COBIS

               -- MARCAR COMO ANULADO EL COMPROBANTE
               update ca_corresponsal_trn  set 
               co_estado = 'A'
               where co_trn_id_corresp = @i_trn_id_corresp

               if (@@error != 0) begin
                  select 
	   		   @w_error = 70220, 
	   		   @w_msg   = 'ERROR AL ACTUALIZAR ESTADO EN TANQUEO'
                  goto ERROR_FIN
               end    

            select @w_est_trn_reverso = 'P', @w_msg = null

         end --end reverso sin tanqueo
      end
         
         -- SI LA TRANSACCION NO SE TANQUEA GUARDA UN REGISTRO DE REVERSO EN ESTADO P o E.
         -- SI LA TRANSACCION SI SE TANQUEA, CUANDO SOLO SE HAN REVERSADO LOS SUBTOTALES EL ESTADO PERMANECE EN I. 
         -- SI YA SE HA REVERSADO TODOS LOS SUBTOTALES EL ESTADO ES DIFERENTE DE I Y SE GUARDA UN REGISTRO DE REVERSO EN ESTADO P o E.

      if @w_en_tanqueo = 'N' begin
      
         -- INGRESA EL REGISTRO DE REVERSA EN LA TABLA DE TRANSACCIONES
         INSERT INTO ca_corresponsal_trn (
         co_corresponsal  , co_tipo        , co_codigo_interno , co_fecha_proceso      , co_fecha_valor,
         co_referencia    , co_moneda      , co_monto          , co_status_srv         , co_estado     ,
         co_error_id      , co_error_msg   , co_archivo_ref    , co_concil_est         , co_concil_motivo, 
         co_concil_user   , co_concil_fecha, co_concil_obs     , co_archivo_fecha_corte, co_archivo_carga_usuario,
         co_trn_id_corresp, co_accion      , co_login          , co_terminal           , co_fecha_real)
         VALUES (
         @i_corresponsal,   @w_tipo         , @w_codigo_interno, @s_date     , @w_fecha_valor,
         @i_referencia  ,   @i_moneda       , @w_monto   ,       @i_status_srv   ,       @w_est_trn_reverso       , 
         NULL           ,   @w_msg          , @i_archivo_pago  , null            ,       NULL          ,
         NULL           ,   NULL            , NULL       ,       NULL            ,       NULL,
         @i_trn_id_corresp, @i_accion       , @s_user          , @s_term         ,getdate())
         if (@@error != 0) begin
            select 
			@w_error = 70220, 
			@w_msg   = 'ERROR AL INSERTAR LA TRANSACCION DEL CORRESPONSAL'
            goto ERROR_FIN
         end 
         
         select @o_codigo_reversa =  co_secuencial
         from ca_corresponsal_trn where 
         co_trn_id_corresp = @i_trn_id_corresp 
         and co_monto      = @w_monto
         and co_estado = 'P'
      
      end

         select 
         @o_cuenta         = @i_referencia,
         @o_monto_recibido = @w_monto,
         @o_mensaje_ticket = 'SE HA REVERSADO EXITOSAMENTE'
         
   end -- accion (R)Reversa
  

    
  -- LOS PAGOS GRUPALES SON ASINCRONICOS
   if @w_tipo in ('CG','PG') return 0
   
   select @i_operacion = 'C', @w_bandera = 1 


end -- end operacion  = 'I'



  
CREATE TABLE #prestamos_grupo(
operacion          int,
banco              cuenta,
oficina            SMALLINT, 
fecha_ult_proceso  datetime,
cliente            int
)

CREATE TABLE #pagos_grupales(
banco          cuenta,
operacion      int,
oficina        smallint,
cliente        int, 
monto_exigible MONEY,
monto_pago     MONEY  
)


CREATE TABLE #garantia_liquidas(
gl_tramite int,
gl_grupo   int,
gl_cliente int,
gl_monto_garantia MONEY,
gl_pag_valor  MONEY,
gl_diferencia MONEY
)    


CREATE TABLE #ca_corresponsal_trn(
co_secuencial            INT ,
co_corresponsal          VARCHAR(16) NULL,
co_tipo                  CHAR(2) NULL,
co_codigo_interno        INT NULL,
co_fecha_valor           DATETIME NULL,
co_moneda                INT NULL,
co_monto                 MONEY NULL,
co_concil_est            CHAR(1) NULL,
co_concil_motivo         CHAR(2) NULL,
co_referencia            VARCHAR(64) NULL,
co_archivo_pag           varchar(64) null,
co_accion                char(1),
co_trn_id_corresp        varchar(10),
co_fecha_real            datetime
)

CREATE TABLE #ca_corresponsal_pr(
co_id                    int identity,
co_secuencial            INT ,
co_corresponsal          VARCHAR(16) NULL,
co_tipo                  CHAR(2) NULL,
co_codigo_interno        INT NULL,
co_fecha_valor           DATETIME NULL,
co_moneda                INT NULL,
co_monto                 MONEY NULL,
co_concil_est            CHAR(1) NULL,
co_concil_motivo         CHAR(2) NULL,
co_referencia            VARCHAR(64) NULL,
co_archivo_pag           varchar(64) null,
co_accion                char(1),
co_trn_id_corresp        varchar(10),
co_fecha_real            datetime
)

CREATE TABLE #op_mas_vencidos(
prestamo           int,
oficina            SMALLINT, 
banco              cuenta,
cliente            INT,
div                INT
)

create table #numero_div(
dividendo    int)

create table #saldo_dividendo(
di_dividendo int, 
saldo        money)

----------
--BATCH
---------- 
if @i_operacion = 'B' 
begin
   --Inserta en la tabla temporal todos los registros que deben procesarse (Estado I)
   --GFP se suprime print
   --print 'Operacion B'
   INSERT INTO #ca_corresponsal_trn
   SELECT co_secuencial , co_corresponsal , co_tipo,  
   co_codigo_interno    , co_fecha_valor,   co_moneda,         --co_codigo_interno es la operacion
   co_monto             , co_concil_est,    co_concil_motivo,
   co_referencia        , co_archivo_ref,   co_accion,
   co_trn_id_corresp    , co_fecha_real
   FROM ca_corresponsal_trn
   where  co_estado  = 'I'
   --and isnull(co_fecha_real,@w_fecha_pro) <  dateadd(mi,-5,getdate()) 
   ORDER BY co_secuencial 
   
   
   if @@error <> 0
   begin
      select
      @w_msg   = 'ERROR AL INSERTAR REGISTROS EN #ca_corresponsal_trn',
      @w_error = 710001     
      
      goto ERROR_FIN 
   end
end

if @i_operacion = 'C' begin -- para conciliacion manual
 

   INSERT INTO #ca_corresponsal_trn
   SELECT co_secuencial , co_corresponsal , co_tipo,  
   co_codigo_interno    , co_fecha_valor,   co_moneda,         --co_codigo_interno es la operacion
   co_monto             , co_concil_est,    co_concil_motivo,
   co_referencia        , co_archivo_ref,   co_accion,
   co_trn_id_corresp    , co_fecha_real
   FROM ca_corresponsal_trn
   where co_referencia = @i_referencia 
   and co_estado = 'I'
  
   
    if @@error <> 0  begin
     select
     @w_msg   = 'ERROR AL INSERTAR REGISTROS EN #ca_corresponsal_trn',
     @w_error = 710001       
       
     goto ERROR_FIN
   end

  
end


--Insert desc reversos
insert into #ca_corresponsal_pr(
co_secuencial      , co_corresponsal, co_tipo         ,
co_codigo_interno  , co_fecha_valor , co_moneda       ,
co_monto           , co_concil_est  , co_concil_motivo,
co_referencia      , co_archivo_pag , co_accion       ,
co_trn_id_corresp  ) 
select
co_secuencial     , co_corresponsal , co_tipo,  
co_codigo_interno , co_fecha_valor  , co_moneda, 
co_monto          , co_concil_est   , co_concil_motivo,
co_referencia     , co_archivo_pag  , co_accion,
co_trn_id_corresp
from #ca_corresponsal_trn
where co_accion = 'R' 
order by co_fecha_valor desc, co_secuencial desc, co_trn_id_corresp desc --DCU. Reverso de Pagos

--GFP se suprime print
--print 'Insert desc reversos'

--Insert asc pagos
insert into #ca_corresponsal_pr(
co_secuencial      , co_corresponsal, co_tipo         ,
co_codigo_interno  , co_fecha_valor , co_moneda       ,
co_monto           , co_concil_est  , co_concil_motivo,
co_referencia      , co_archivo_pag , co_accion       ,
co_trn_id_corresp  ) 
select 
co_secuencial     , co_corresponsal , co_tipo,  
co_codigo_interno , co_fecha_valor  , co_moneda, 
co_monto          , co_concil_est   , co_concil_motivo,
co_referencia     , co_archivo_pag  , co_accion,
co_trn_id_corresp
from #ca_corresponsal_trn
where co_accion <> 'R' 
order by co_fecha_valor asc

--GFP se suprime print
--print'Insert asc pagos'

--EJECUTA LOS PAGOS REGISTRADOS EN LA TABLA #ca_corresponsal_trn
declare cursor_transacciones cursor for SELECT
co_secuencial     , co_corresponsal , co_tipo,  
co_codigo_interno , co_fecha_valor  , co_moneda, 
co_monto          , co_concil_est   , co_concil_motivo,
co_referencia     , co_archivo_pag  , co_accion,
co_trn_id_corresp
FROM #ca_corresponsal_pr
order by co_id
for read only

OPEN cursor_transacciones

fetch cursor_transacciones into 
@w_secuencial   , @w_forma_pago , @w_tipo,
@w_operacionca  , @w_fecha_valor, @w_moneda, 
@w_monto        , @w_concil_est,  @w_concil_motivo,
@w_referencia   , @w_archivo_pag, @w_accion,
@w_trn_id_corresp

while @@fetch_status = 0  begin

   select
   @w_msg = '',
   @w_est = 'P' 
      
   if @i_operacion = 'C' and @w_bandera = 0 begin  
       
      if (@w_concil_motivo = 'NR' and @w_tipo in ('PG','P')) select @w_tipo = 'RP'   --Reverso de Pago grupal 
      if (@w_concil_motivo = 'NR' and @w_tipo in ('PI','I')) select @w_tipo = 'RI'   --Reverso de Pago individual 
      if (@w_concil_motivo = 'NR' and @w_tipo in ('GL','G')) select @w_tipo = 'RG'   --Reverso de Pago de garantia  
      
   end
   
   if @w_accion = 'R' begin
      if @w_tipo = 'PG' select @w_tipo = 'RP'   --Reverso de Pago grupal 
      if @w_tipo = 'PI' select @w_tipo = 'RI'   --Reverso de Pago individual 
      if @w_tipo = 'GL' select @w_tipo = 'RG'   --Reverso de Pago de garantia  
      
      select 
      @w_secuencial_trn_rv = co_secuencial,
      @w_estado     = co_estado 
      from ca_corresponsal_trn 
      where co_trn_id_corresp = @w_trn_id_corresp 
      --and co_estado = 'P' --JH  
      and co_monto            = @w_monto
      
      if @@rowcount = 0 begin
         select
         @w_error = 701221, --710002, --> poner codigo error de existencia (no existe registro)
         @w_msg   = 'ERROR: NO EXISTE TRANSACCION A REVERSAR ID ' + @w_trn_id_corresp
       
         GOTO ERROR_CURSOR
      end
      
   end
   --para determinar si tiene o no tanqueo
   /*select @w_id_corresponsal = co_id
   from cob_cartera..ca_corresponsal
   where co_nombre = @w_forma_pago
   print 'PAGOS @w_id_corresponsal '+convert(varchar(10),@w_id_corresponsal)*/
   
  /******PAGO DE CANCELACIONES INDIVIDUALES **************/
   if @w_tipo = 'CI'  
   begin     
      select @w_tanquear = 'N'
      select 1 from ca_corresponsal_limites 
      where cl_corresponsal_id = @w_id_corresponsal
      and cl_tipo_tran         = @w_tipo
      --SI EXISTE LAS ENTRADAS PARA EL CORRESPONSAL EN LA TABLA
      if @@rowcount <> 0 select @w_tanquear = 'S'
      
	  --GFP se suprime print
      --print 'CANCELACION INDIVIDUAL @w_tanquear '+@w_tanquear
      select 
      @w_banco             = op_banco,      
      @w_operacionca       = op_operacion,
      @w_fecha_ult_proceso = op_fecha_ult_proceso,
      @w_oficina           = op_oficina,
      @w_cliente           = op_cliente
      from  ca_operacion 
      where op_operacion = @w_operacionca

      if @@rowcount = 0 
      begin
         select @w_ope = isnull(@w_operacionca,0) --MTA
         select 
         @w_error = 70197,
         @w_est = 'E',
         @w_msg = 'NO EXISTE PRESTAMO ' + @w_banco
         
         goto ERROR_CURSOR         
      end
      select @w_ente = @w_cliente --cliente que va a la tabla de ca_santander_log_pagos
      select @w_cuenta = isnull(ea_cta_banco, '')
      from cobis..cl_ente_aux 
      where ea_ente = @w_cliente
      
      if @@rowcount = 0 or @w_cuenta = '' 
      begin        
         select 
         @w_error = 2101011,
         @w_est = 'E',
         @w_msg = 'ERROR NO EXISTE CLIENTE O NO TIENE NUMERO DE CUENTA'      
         
         goto ERROR_CURSOR         
      end
           
      if @@trancount = 0 
      begin  
         select @w_commit = 'S'
      end
      
 ---Saldo para precancelar 
	  select @w_saldo_precancelar = isnull(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end),0)
	  from  ca_dividendo, ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo
      and   am_operacion =  @w_operacionca 
      and   di_estado <> @w_est_cancelado
	  
	  --GFP se suprime print
      --print '@w_saldo_precancelar '+  convert(varchar(10),@w_saldo_precancelar)
      --print '@w_monto '+  convert(varchar(10),@w_monto)

      if(@w_monto < @w_saldo_precancelar) begin
         if @w_tanquear = 'S' begin
             -- SE EJECUTA EL PAGO DESPUES DE LA HORA DEL PARAMETRO HUDDD
             select @w_fecha_hoy=  CONVERT(varchar(10), getdate(), 101)
             select @w_hora_ult_dis =  pa_char 
             from cobis..cl_parametro 
             WHERE pa_nemonico = 'HUDDD'

             select @w_fecha_ult_disper = convert(datetime,@w_fecha_hoy+' '+@w_hora_ult_dis)

             if getDate()>@w_fecha_ult_disper begin
			    --GFP se suprime print
                --print 'cambia a Estado PI para procesar el PAGO'
                select @w_tipo = 'PI' -- continua a la siguiente opcion y paga
            end 
            else begin
			    --GFP se suprime print
                --print 'no procesa el pago Individual'
                select @w_est = 'I'
                goto MARCAR
             end
         end else begin
             select
             @w_error = 210101,
             @w_msg = 'EL VALOR DE LA CANCELACION INDIVIDUAL NO CORRESPONDE AL VALOR PAGADO, SALDO PRECANCELAR: '   + convert(varchar, @w_saldo_precancelar)+' PAG: '+convert(varchar, @w_monto)+' TRAM: '+convert(varchar, @w_tramite_grupal),
             @w_est = 'E'
             goto ERROR_CURSOR --marca el registro con el estado, error y mensaje y luego ejecuta el siguiente registro
         end
      end else begin -- end monto es menor a valor precancelacion
	     --GFP se suprime print
         --print 'MONTO SUFICIENTE PARA REALIZAR EL PAGO'
         select @w_tipo = 'PI' -- continua a la siguiente opcion y paga
      end
   end 

   -- PAGO DE PRESTAMOS INDIVIDUALES --
   if @w_tipo ='PI'  
   begin 
   --GFP se suprime print   
   --print 'INGRESA A PAGO DE PRESTAMOS INDIVIDUALES ' 
      select 
      @w_banco             = op_banco,      
      @w_operacionca       = op_operacion,
      @w_fecha_ult_proceso = op_fecha_ult_proceso,
      @w_oficina           = op_oficina,
      @w_cliente           = op_cliente
      from  ca_operacion 
      where op_operacion = @w_operacionca

      if @@rowcount = 0 
      begin
         select @w_ope = isnull(@w_operacionca,0) --MTA
         select 
         @w_error = 70197,
         @w_est = 'E',
         @w_msg = 'NO EXISTE PRESTAMO ' + @w_banco
         
         goto ERROR_CURSOR         
      end
      select @w_ente = @w_cliente --cliente que va a la tabla de ca_santander_log_pagos
      select @w_cuenta = isnull(ea_cta_banco, '')
      from cobis..cl_ente_aux 
      where ea_ente = @w_cliente
      
      if @@rowcount = 0 or @w_cuenta = '' 
      begin        
         select 
         @w_error = 2101011,
         @w_est = 'E',
         @w_msg = 'ERROR NO EXISTE CLIENTE O NO TIENE NUMERO DE CUENTA'      
         
         goto ERROR_CURSOR         
      end
           
      if @@trancount = 0 
      begin  
         select @w_commit = 'S'
         begin tran
      end
      
      EXEC @w_error     = sp_pago_cartera_srv
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_ofi            = @w_oficina,         
      @i_banco          = @w_banco,
      @i_fecha_valor    = @w_fecha_valor,
      @i_forma_pago     = @w_forma_pago,
      @i_monto_pago     = @w_monto,
      @i_cuenta         = @w_cuenta,      --Cuenta Santander del Cliente
      @o_msg            = @w_msg out,
      @o_secuencial_ing = @w_secuencial_ing out
     
      if @w_error != 0 BEGIN
         select 
         @w_est = 'E',
         @w_msg = 'ERROR AL EJECUTAR EL PAGO: ' + convert(varchar,@w_operacionca)
         
         goto ERROR_CURSOR
      end
      
      INSERT INTO ca_corresponsal_det(
      cd_operacion        ,cd_banco       ,cd_sec_ing ,cd_referencia , cd_secuencial)
      VALUES (
      @w_operacionca,@w_banco,@w_secuencial_ing,@w_referencia,@w_secuencial )
       
      
      if @@error != 0 begin
         select
         @w_est = 'E',
         @w_msg   = 'ERROR AL CREAR DETALLE PAGO : ' + convert(varchar,@w_banco_int) + 'Secuencial ' + convert(varchar,@w_secuencial_ing)
        
         goto ERROR_CURSOR
      end 
      
      if @w_commit = 'S' begin  
         select @w_commit = 'N'
         commit tran
      end
      goto MARCAR                           
   end --- FIN PAGO DE PRESTAMOS INDIVIDUALES
     
   /***************PAGO DE GARANTIAS*********/
   if @w_tipo = 'GL' 
   begin   
      truncate table #garantia_liquidas       
     
      select @w_tanquear = 'N'

      select 1 from ca_corresponsal_limites 
      where cl_corresponsal_id = @w_id_corresponsal
      and cl_tipo_tran         = @w_tipo
      --SI EXISTE LAS ENTRADAS PARA EL CORRESPONSAL EN LA TABLA
      if @@rowcount <> 0 select @w_tanquear = 'S'

      select @w_tramite_grupal = max(gl_tramite) 
      from ca_garantia_liquida
      where gl_pag_estado  ='PC'
      and   gl_grupo = @w_operacionca
	        
      if @w_tramite_grupal = 0 
      begin
         select 
         @w_error = 2101019,
         @w_est = 'E',
         @w_msg = 'NO EXISTE VALORES POR COBRAR DE GAR LIQUIDA ' +  convert(varchar,@w_operacionca)
         goto ERROR_CURSOR
      end
    
      select @w_ente = @w_operacionca --nro grupo que va a la tabla de ca_santander_log_pagos en el campo cliente
      select
      @w_oficina = tr_oficina,
      @w_usuario = tr_usuario,
      @w_ope     = tr_numero_op --MTA
      from cob_credito..cr_tramite 
      where tr_tramite = @w_tramite_grupal
        
      if @@rowcount = 0 begin
          select 
          @w_error = 70194,
          @w_msg = 'NO EXISTE REGISTRO DEL TRAMITE GRUPAL.'
          
          goto ERROR_CURSOR
      end
        
      if @w_oficina = null begin
          select 
          @w_error = 70195,
          @w_msg = 'NO EXISTE OFICINA DEL TRAMITE INGRESADO PARA EL GRUPO: ' +  convert(varchar,@w_codigo_interno)
          
          goto ERROR_CURSOR
      end
        
      if @w_usuario = null begin
        select 
          @w_error = 70196,
          @w_msg = 'NO EXISTE OFICIAL DEL TRAMITE INGRESADO PARA EL GRUPO: ' +  convert(varchar,@w_codigo_interno)
          
          goto ERROR_CURSOR
      end 
       

      insert into #garantia_liquidas
      select
      gl_tramite,         gl_grupo,       gl_cliente,
      gl_monto_garantia,  gl_pag_valor,   (gl_monto_garantia - ISNULL(gl_pag_valor,0))
      from cob_cartera..ca_garantia_liquida
      where gl_tramite        = @w_tramite_grupal
      and   gl_monto_garantia > ISNULL(gl_pag_valor,0)
      
      if @@error <> 0 begin
         select 
         @w_error = 2101011,
         @w_est = 'E',
         @w_msg = 'NO EXISTE PRESTAMOS ASOCIADOS A LA GAR LIQ OPERACION GRUPAL:  ' + convert(varchar,@w_tramite_grupal)
                      
        
         goto ERROR_CURSOR
      end 
      
      --valor pendiente de pago de Garantia
      select @w_diferencia = sum(gl_diferencia)
      from   #garantia_liquidas
      where  gl_diferencia >0
      
      if @w_diferencia <> @w_monto begin
         if @w_tanquear = 'N' 
            select 
            @w_error = 210101,
            @w_msg = 'EL VALOR DE LA GARANTIA NO CORRESPONDE AL VALOR PAGADO, GAR: '   + convert(varchar, @w_diferencia)+' PAG: '+convert(varchar, @w_monto)+' TRAM: '+convert(varchar, @w_tramite_grupal),
            @w_est = 'E' 
         else begin
            select @w_est = 'I' --deja en estado I para procesar devolucion 
			--GFP se suprime print
            --print 'NO PROCESA PAGO DE GARANTIA , DEJA PENDIENTE PARA DEVOLUCION O REPROCESO' 
        end 
        goto ERROR_CURSOR
        
      end   
        
      if @@trancount = 0 begin  
         select @w_commit = 'S'
         begin tran
      end
           
      declare cursor_contabiliza_gar cursor for SELECT 
      gl_tramite,         gl_grupo,      gl_cliente,
      gl_monto_garantia , gl_pag_valor,  gl_diferencia
      FROM #garantia_liquidas
      where gl_diferencia > 0
      
      for read only
      
      OPEN cursor_contabiliza_gar
      
      fetch cursor_contabiliza_gar into @w_gl_tramite, @w_gl_grupo, @w_gl_cliente,@w_gl_monto_garantia,@w_gl_pag_valor , @w_gl_diferencia
      
      while @@fetch_status = 0  begin
       
         EXEC @w_error  = cob_custodia..sp_contabiliza_garantia
         @s_date           = @s_date ,
         @s_ofi            = @w_oficina,
         @s_user           = @s_user ,
         @s_term           = @s_term,     
         @i_operacion      = 'C',
         @i_monto          = @w_gl_diferencia,
         @i_en_linea       = 'N' ,   
         @i_ente           = @w_gl_cliente,
         @i_tramite        = @w_gl_tramite,
		 @i_forma_pago     = @w_forma_pago,
         @o_secuencial     = @w_secuencial_ing out
                
         if @w_error != 0 begin
           
            select             
            @w_est = 'E',
            @w_msg = 'ERROR AL EJECUTAR PROCESO DE CONTABILIZACION DE LA GARANTIA: ' + convert(varchar,@w_operacionca)
           
         
            close cursor_contabiliza_gar
            deallocate cursor_contabiliza_gar
            
            goto ERROR_CURSOR                         
         
         end 
         
         INSERT INTO ca_corresponsal_det(
         cd_operacion,   cd_banco,                           cd_sec_ing,         cd_referencia, cd_secuencial)
         VALUES (
         @w_gl_cliente,  convert(varchar,@w_gl_tramite),     @w_secuencial_ing  ,@w_referencia, @w_secuencial  )
          
         
         if @@error != 0 begin
            select
            @w_error          = 710001,      
            @w_est            = 'E',
            @w_msg            = 'ERROR AL CREAR DETALLE PAGO : ' + convert(varchar,@w_banco_int) + 'Secuencial ' + convert(varchar,@w_secuencial_ing)
        
            
            close cursor_contabiliza_gar
            deallocate cursor_contabiliza_gar
            goto ERROR_CURSOR
         end 
         
         fetch cursor_contabiliza_gar INTO @w_gl_tramite, @w_gl_grupo, @w_gl_cliente,@w_gl_monto_garantia,@w_gl_pag_valor , @w_gl_diferencia
      
      end -- end while         
            
      close cursor_contabiliza_gar
      deallocate cursor_contabiliza_gar
            
      --SACA EL TRAMITE DE LA ESTACION DE ESPERA      


    if exists (select 1 from cob_workflow..wf_inst_actividad,cob_workflow..wf_inst_proceso
         where ia_nombre_act like '%ESPERA AUTOMATICA GAR LIQUIDA'
         and ia_estado       = 'ACT'
         and ia_id_inst_proc = io_id_inst_proc
         and io_estado       = 'EJE'
         and io_campo_1      = @w_operacionca)begin
	  
      exec @w_error = sp_ruteo_actividad_wf  
      @s_ssn              =   @s_ssn, 
      @s_user            =    @w_usuario,
      @s_sesn            =    null,
      @s_term            =    @s_term,
      @s_date            =    @s_date,
      @s_srv             =    @s_srv,
      @s_lsrv            =    @s_lsrv,
      @s_ofi             =    @w_oficina,     
      @i_tramite          =   @w_tramite_grupal, 
      @i_param_etapa      =   'EAGARL'
         
      if @w_error != 0 begin
         select           
         @w_est = 'E',
         @w_msg = 'ERROR AL EJECUTAR PROCESO RUTEO DE ACTIVIDAD AUTOMATICA: ' + convert(varchar,@w_operacionca)
      
       
         goto ERROR_CURSOR 
      end
     end else begin 
    
      if @w_commit = 'S' begin  
          select @w_commit = 'N'
          commit tran
      end
      
	    select 
		@w_est = 'P',
		@w_msg = 'ALERTA NO EXISTE TRAMITE A PROCESAR EN EL WORKFLOW ' + convert(varchar,@w_operacionca)
                goto MARCAR 
     end 
      
      if @w_commit = 'S' begin  
          select @w_commit = 'N'
          commit tran
      end
      
      goto MARCAR 
                  
   end -- FIN PAGOS GARANTIA LIQUIDA

    /***************PAGO DE CANCELACIONES GRUPALES*********/
   if @w_tipo = 'CG' 
   BEGIN
      truncate table #prestamos_grupo
      select @w_tanquear = 'N'
      select 1 from ca_corresponsal_limites 
      where cl_corresponsal_id = @w_id_corresponsal
      and cl_tipo_tran         = @w_tipo
      --SI EXISTE LAS ENTRADAS PARA EL CORRESPONSAL EN LA TABLA
      if @@rowcount <> 0 select @w_tanquear = 'S'
 
      --GFP se suprime print
	  --print 'PAGO DE CANCELACION GRUPAL @w_tanquear '+@w_tanquear
      select 
      @w_tramite_grupal    = op_tramite,
      @w_oficina           = op_oficina,
      @w_ente              = op_cliente -- campo que va a la tabla ca_santander_log_pagos en el campo sl_ente
      from  ca_operacion 
      where op_operacion   = @w_operacionca

      if @@rowcount = 0 
      begin
         select @w_ope =  isnull(@w_operacionca,0)
         select 
         @w_error = 2101011,
         @w_est = 'E',
         @w_msg = 'NO EXISTE CODIGO INTERNO: ' +  convert(varchar,@w_operacionca)
     
         goto ERROR_CURSOR         
      end     
      
      INSERT INTO #prestamos_grupo
      SELECT op_operacion, op_banco,  op_oficina, op_fecha_ult_proceso, op_cliente     
      FROM cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion
      where tg_tramite = @w_tramite_grupal ----tramite grupal creado
      AND tg_operacion = op_operacion
      and op_estado <>  @w_est_cancelado
      
      if @@rowcount = 0 or @@error <> 0  
      begin      
         select 
         @w_error = 2101011,
         @w_est = 'E',
         @w_msg = 'NO EXISTE PRESTAMOS ASOCIADOS A LA  OPERACION GRUPAL: ' + convert(varchar,@w_tramite_grupal)
        
         goto ERROR_CURSOR         
      end

	  ---Saldo para precancelar 
	  select @w_saldo_precancelar = isnull(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end),0)
	  from  #prestamos_grupo, ca_dividendo, ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo
      and   am_operacion = operacion 
      and   di_estado <> @w_est_cancelado
	  
	  --GFP se suprime print
      --print 'PAGO CANCELACION GRUPAL @w_saldo_precancelar '+  convert(varchar(10),@w_saldo_precancelar)
      --print 'PAGO CANCELACION GRUPAL @w_monto '+  convert(varchar(10),@w_monto)
      
      if(@w_monto < @w_saldo_precancelar) begin
         if @w_tanquear = 'S' begin
             -- SE EJECUTA EL PAGO DESPUES DE LA HORA DEL PARAMETRO HUDDD
             select @w_fecha_hoy=  CONVERT(varchar(10), getdate(), 101)
             select @w_hora_ult_dis =  pa_char 
             from cobis..cl_parametro 
             WHERE pa_nemonico = 'HUDDD'

             select @w_fecha_ult_disper = convert(datetime,@w_fecha_hoy+' '+@w_hora_ult_dis)

             if getDate()>@w_fecha_ult_disper begin 
                set @w_tipo = 'PG' -- continua a la siguiente opcion y paga
				--GFP se suprime print
                --print 'cambia a PG y procede al pago grupal'
             end else begin
			    --GFP se suprime print
                --print 'no procesa el pago de Cancelacion Grupal'
                select @w_est = 'I'
                goto MARCAR
             end
         end else begin
             select
             @w_error = 210101,
             @w_msg = 'EL VALOR DE LA CANCELACION GRUPAL NO CORRESPONDE AL VALOR PAGADO, SALDO PRECANCELAR: '   + convert(varchar, @w_saldo_precancelar)+' PAG: '+convert(varchar, @w_monto)+' TRAM: '+convert(varchar, @w_tramite_grupal),
             @w_est = 'E'
             goto ERROR_CURSOR --marca el registro con el estado, error y mensaje y luego ejecuta el siguiente registro
        end
         
      end else begin -- end monto es menor a valor precancelacion
	     --GFP se suprime print
         --print 'MONTO SUFICIENTE PARA REALIZAR LA CANCELACION GRUPAL'
         select @w_tipo = 'PG' -- continua a la siguiente opcion y paga
      end
                        
   end  --fin tipo = CG (cancelacion Grupal)    

    /***************PAGO DE PRESTAMOS GRUPALES*********/
   if @w_tipo = 'PG' 
   begin
      truncate TABLE #prestamos_grupo
      truncate TABLE #pagos_grupales
      truncate table #op_mas_vencidos
      truncate table #numero_div
      truncate table #saldo_dividendo      
      

      select 
      @w_tramite_grupal    = op_tramite,
      @w_oficina           = op_oficina,
      @w_ente              = op_cliente, -- campo que va a la tabla ca_santander_log_pagos en el campo sl_ente
	  @w_banco             = op_banco -- campo del banco 
      from  ca_operacion 
      where op_operacion   = @w_operacionca

      if @@rowcount = 0 
      begin
         select @w_ope =  isnull(@w_operacionca,0)
         select 
         @w_error = 2101011,
         @w_est = 'E',
         @w_msg = 'NO EXISTE CODIGO INTERNO: ' +  convert(varchar,@w_operacionca)
     
         goto ERROR_CURSOR         
      end     
	
      INSERT INTO #prestamos_grupo
      SELECT op_operacion, op_banco,  op_oficina, op_fecha_ult_proceso, op_cliente     
      FROM ca_operacion 
	  WHERE op_grupal     ='S' 
	  AND   op_ref_grupal = @w_banco
      
	  
      if @@rowcount = 0 or @@error <> 0  
      begin      
         select 
         @w_error = 2101011,
         @w_est = 'E',
         @w_msg = 'NO EXISTE PRESTAMOS ASOCIADOS A LA  OPERACION GRUPAL: ' + convert(varchar,@w_tramite_grupal)
        
         goto ERROR_CURSOR         
      end
          
                   
      /* *********** LLEVAR A LA OPERCIONES A LA FECHA VALOR ******************/
      declare cursor_fecha_valor cursor for SELECT 
      banco
      FROM #prestamos_grupo
      where fecha_ult_proceso <> @w_fecha_valor
      for read only
      
      OPEN cursor_fecha_valor
      
      fetch cursor_fecha_valor into @w_banco
  
      while @@fetch_status = 0  begin
         
         select  
               @w_oficina = op_oficina             
         from ca_operacion 
         where op_banco = @w_banco
          
         --print 'ingresa a fecha valor :' + @w_banco
         exec @w_error = sp_fecha_valor 
         @s_date        = @s_date,
         @s_user        = @s_user,
         @s_term        = @s_term,
         @t_trn         = 7049,
         @i_fecha_mov   = @s_date,
         @i_fecha_valor = @w_fecha_valor,
         @i_banco       = @w_banco,
         @i_secuencial  = 1,
         @s_ofi         = @w_oficina,
         @i_operacion   = 'F'
         
         if @w_error != 0 
		   begin
            select 
            @w_est = 'E',
            @w_msg = 'ERROR AL EJECUTAR FECHA VALOR: Op Hija' + convert(varchar,@w_operacionca) + 'Fecha valor: '+convert(VARCHAR,@w_fecha_valor)+ 'Op Banco: '+convert(VARCHAR,@w_banco)
            
            
            close cursor_fecha_valor
            deallocate cursor_fecha_valor
            
            goto ERROR_CURSOR   
		 end
         
         fetch cursor_fecha_valor into @w_banco
      
      end
      
      close cursor_fecha_valor
      deallocate cursor_fecha_valor
      
      select 
      @w_valor_vigente = isnull(sum(am_cuota-am_pagado),0) * (1 + @w_sensibilidad),--Proyectado
      @w_saldo_cuota   = isnull(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end),0)
	  from  #prestamos_grupo, ca_dividendo, ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo
      and am_operacion = operacion 
      and   di_estado in (@w_est_vigente, @w_est_vencido)
      
      select 
      @w_saldo_exigible  = isnull(CEILING(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end)),0) 
	  from  #prestamos_grupo, ca_dividendo, ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo
      and am_operacion = operacion 
      and   (di_estado  = @w_est_vencido or ( di_estado  = @w_est_vigente and di_fecha_ven = @w_fecha_valor))
      
      INSERT INTO #op_mas_vencidos
      SELECT prestamo=di_operacion,oficina,banco, cliente,  div = isnull(min(di_dividendo),0)      
      FROM ca_dividendo , #prestamos_grupo 
      WHERE di_estado= @w_est_vencido
      AND di_operacion = operacion
      GROUP BY di_operacion, oficina,banco, cliente
     
      select 
      @w_saldo_mas_vencido  = isnull(CEILING(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end)),0) 
	  from  #op_mas_vencidos, ca_dividendo, ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo      
      and am_operacion = prestamo
      AND am_dividendo = div
      
      select @w_saldo_precancelar = isnull(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end),0)
	  from  #prestamos_grupo, ca_dividendo, ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo
      and   am_operacion = operacion 
      and   di_estado <> @w_est_cancelado
	  and   di_estado <> @w_est_vigente
	  
	  select @w_precancelar_aux =  isnull(sum(case when am_cuota + am_gracia>am_pagado then am_cuota + am_gracia - am_pagado else 0 end),0)
	  from  #prestamos_grupo,ca_dividendo, ca_amortizacion
	  where am_operacion = di_operacion
	  and   am_dividendo = di_dividendo
	  and   am_operacion = operacion
	  and   di_estado    = @w_est_vigente
	  
	  select @w_saldo_precancelar = @w_saldo_precancelar + @w_precancelar_aux
      
       --Ajuste para obetener los dividendos que deben tomarse en cuenta en el pago. En Base al proyectado de cada dividendo
      insert into #saldo_dividendo      
      select di_dividendo, saldo = sum(am_cuota - am_pagado)
      from   cob_cartera..ca_dividendo, cob_cartera..ca_amortizacion
      where am_operacion = di_operacion
      and   am_dividendo = di_dividendo      
      and   am_operacion in (select operacion from #prestamos_grupo)
      and   di_estado      <> @w_est_cancelado  
      group by di_dividendo  
          
      select 
      @w_dividendo_aux = 0,
      @w_total     = 0,
      @w_saldo     = 0
            
      while 1 = 1
      begin
          select top 1
          @w_dividendo_aux = di_dividendo,
          @w_saldo     = saldo
          from #saldo_dividendo
          where di_dividendo > @w_dividendo_aux
                 
          if @@rowcount = 0 break
                
          select @w_total = @w_total + @w_saldo
          
          insert into #numero_div values(@w_dividendo_aux)
          
          if @w_total>= @w_monto break      
      end
           
      select @w_formula = 6
      
      if @w_monto > @w_valor_vigente  and @w_monto < @w_saldo_precancelar select @w_formula = 5     
      if @w_monto > @w_saldo_cuota    and @w_monto <= @w_valor_vigente and @w_monto < @w_saldo_precancelar select @w_formula = 4
      if @w_monto > @w_saldo_cuota    and @w_monto <= @w_total and @w_monto < @w_saldo_precancelar select @w_formula = 3
      if @w_monto > @w_saldo_exigible and @w_monto <= @w_saldo_cuota  select @w_formula = 2
      if @w_monto <= @w_saldo_exigible select @w_formula = 1
      if @w_monto <= @w_saldo_mas_vencido * 1.1 select @w_formula = 0
      
      --print '@w_monto:' + convert(varchar,@w_monto)
      --print '@w_valor_vigente:' + convert(varchar,@w_valor_vigente)
      --print '@w_saldo_precancelar:' + convert(varchar,@w_saldo_precancelar)
      --print '@w_saldo_cuota:' + convert(varchar,@w_saldo_cuota)
      --print '@w_total:' + convert(varchar,@w_total)
      --print '@w_saldo_exigible:' + convert(varchar,@w_saldo_exigible)
      --print '@w_formula  '+ convert(VARCHAR,@w_formula)
      
      --Solo la cuota mas vencidos
      if @w_formula = 0  
      begin 
	              
         insert into #pagos_grupales
         select banco, prestamo, oficina, cliente, isnull(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end),0)
               , 0
         from  #op_mas_vencidos, ca_dividendo, ca_amortizacion
         where am_operacion = di_operacion
         and   am_dividendo = di_dividendo
         AND   am_dividendo = div        
         and   am_operacion = prestamo        
         group by banco, prestamo, oficina, cliente
	    
         if @@error <> 0 
         BEGIN
           select 
           @w_error = 2101011,
           @w_est = 'E',
           @w_msg = 'ERROR INSERTAR DETALLE DE PAGOS A PROCESAR OPERACION GRUPAL: ' + convert(varchar,@w_tramite_grupal)
                    
           goto ERROR_CURSOR
        end        
     END
      
      ---Exigible
      if @w_formula = 1  begin 
	              
        insert into #pagos_grupales
        select banco, operacion, oficina, cliente, isnull(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end),0)
               , 0
        from  #prestamos_grupo, ca_dividendo, ca_amortizacion
        where am_operacion = di_operacion
        and   am_dividendo = di_dividendo
      	and   am_operacion = operacion 
        and   (di_estado  = @w_est_vencido or ( di_estado  = @w_est_vigente and di_fecha_ven = @w_fecha_valor))
        group by banco, operacion, oficina, cliente
	    
	    if @@error <> 0 begin
          
           select 
           @w_error = 2101011,
           @w_est = 'E',
           @w_msg = 'ERROR INSERTAR DETALLE DE PAGOS A PROCESAR OPERACION GRUPAL: ' + convert(varchar,@w_tramite_grupal)
         
           
           goto ERROR_CURSOR
        end   
      end
      
      --Saldo Cuota
      if @w_formula = 2  begin 	              
        insert into #pagos_grupales
        select banco, operacion, oficina, cliente, isnull(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end),0)
               , 0
        from  #prestamos_grupo, ca_dividendo, ca_amortizacion
        where am_operacion = di_operacion
        and   am_dividendo = di_dividendo
      	and   am_operacion = operacion 
        and   di_estado in (@w_est_vigente, @w_est_vencido)
        group by banco, operacion, oficina, cliente
	    
	    if @@error <> 0 begin
          
           select 
           @w_error = 2101011,
           @w_est = 'E',
           @w_msg = 'ERROR INSERTAR DETALLE DE PAGOS A PROCESAR OPERACION GRUPAL: ' + convert(varchar,@w_tramite_grupal)
         
           
           goto ERROR_CURSOR
           
        end
	  end  
	  
	  if @w_formula = 3  begin 
	     
	    insert into #pagos_grupales
        select banco, operacion, oficina, cliente, sum(am_cuota-am_pagado), 0
        from  #prestamos_grupo, cob_cartera..ca_dividendo, cob_cartera..ca_amortizacion
        where am_operacion = di_operacion
        and   am_dividendo = di_dividendo
      	and   am_operacion = operacion 
        and   di_estado <> @w_est_cancelado
        and   di_dividendo in (select dividendo from #numero_div)
        group by banco, operacion, oficina, cliente
        
        if @@error <> 0 begin
          
           select 
           @w_error = 2101011,
           @w_est = 'E',
           @w_msg = 'ERROR INSERTAR DETALLE DE PAGOS A PROCESAR OPERACION GRUPAL: ' + convert(varchar,@w_tramite_grupal)
           goto ERROR_CURSOR           
        end
        
   	  end
    
      if @w_formula = 4  begin 
	              
        insert into #pagos_grupales
        select banco, operacion, oficina, cliente, sum(am_cuota-am_pagado), 0
        from  #prestamos_grupo, ca_dividendo, ca_amortizacion
        where am_operacion = di_operacion
        and   am_dividendo = di_dividendo
      	and   am_operacion = operacion 
        and   di_estado in (@w_est_vigente, @w_est_vencido)
        group by banco, operacion, oficina, cliente
	    
	    if @@error <> 0 begin
          
           select 
           @w_error = 2101011,
           @w_est = 'E',
           @w_msg = 'ERROR INSERTAR DETALLE DE PAGOS A PROCESAR OPERACION GRUPAL: ' + convert(varchar,@w_tramite_grupal)
         
           
           goto ERROR_CURSOR
           
        end
	  end 
    
      if @w_formula = 5  begin 
		 
        insert into #pagos_grupales
        select banco, operacion, oficina, cliente, sum(am_cuota-am_pagado), 0
        from  #prestamos_grupo, ca_dividendo, ca_amortizacion
        where am_operacion = di_operacion
        and   am_dividendo = di_dividendo
        and   am_operacion = operacion 
        and   di_estado <> @w_est_cancelado
        group by banco, operacion, oficina, cliente
	    
	    if @@error <> 0 begin
          
           select 
           @w_error = 2101011,
           @w_est = 'E',
           @w_msg = 'ERROR INSERTAR DETALLE DE PAGOS A PROCESAR OPERACION GRUPAL: ' + convert(varchar,@w_tramite_grupal)
                    
           goto ERROR_CURSOR
           
        end
		
		
	  end   
      
      --Precancelar
      if @w_formula = 6  begin 
		insert into #pagos_grupales
        select banco, operacion, oficina, cliente, isnull(sum(case when am_acumulado + am_gracia>am_pagado then am_acumulado + am_gracia - am_pagado else 0 end),0), 0
        from  #prestamos_grupo, ca_dividendo, ca_amortizacion
        where am_operacion = di_operacion
        and   am_dividendo = di_dividendo
        and   am_operacion = operacion 
        and   di_estado <> @w_est_cancelado
        group by banco, operacion, oficina, cliente
	    
	    if @@error <> 0 begin
          
           select 
           @w_error = 2101011,
           @w_est = 'E',
           @w_msg = 'ERROR INSERTAR DETALLE DE PAGOS A PROCESAR OPERACION GRUPAL: ' + convert(varchar,@w_tramite_grupal)
         
           
           goto ERROR_CURSOR
           
        end
		
		  
	  end     
  
      select @w_total_exigible = isnull(sum(monto_exigible),0)
      from #pagos_grupales
      
	  --print '@w_total_exigible: ' + convert(varchar,@w_total_exigible)
	  if(@w_total_exigible = 0)
	  begin           
           select 
           @w_error = 2101011,
           @w_est = 'E',
           @w_msg = 'ERROR: SE ESTA INTENTANDO PAGAR UN PRESTAMO QUE NO TIENE SALDO: '
		   
		   goto ERROR_CURSOR
	  end
	  
      select @w_porcentaje =(convert(float,@w_monto)  / convert(float,@w_total_exigible))
	      
      update #pagos_grupales set
      monto_pago = round((monto_exigible * @w_porcentaje), @w_num_dec) 
            
      select @w_total_pago = isnull(sum(monto_pago),0)
      from #pagos_grupales
  
      if exists(select 1 from #pagos_grupales where monto_pago <= 0)
	  begin
	      select 
           @w_error = 2101012,
           @w_est = 'E',
           @w_msg = 'ERROR: PAGOS CON MONTO 0'           
	 
		   goto ERROR_CURSOR
	  end

      -- CONTROL PARA EVITAR PERDIDA POR DECIMALES --
      select @w_diferencia = @w_total_pago - @w_monto
      if @w_diferencia != 0 begin
      
         SET ROWCOUNT 1
         
         update #pagos_grupales set
         monto_pago = monto_pago - @w_diferencia 
         where monto_pago > abs(@w_diferencia)

         if @@error != 0 begin
            select
            @w_error = 710002,
            @w_est   = 'E',
            @w_msg   = 'ERROR AL MARCAR ACTUALIZAR EL MONTO PAGO : ' + convert(varchar, @w_secuencial)
            SET ROWCOUNT 0     
          
             
            GOTO ERROR_CURSOR
         end
         
         SET ROWCOUNT 0         
         
      end               
      
      if @@trancount = 0 begin  
         select @w_commit = 'S'
         begin tran
      end
     

         
      declare cursor_pagos cursor for SELECT 
      banco,operacion, oficina, cliente, monto_pago
      FROM #pagos_grupales      
      for read only
      
      OPEN cursor_pagos
      
      fetch cursor_pagos into @w_banco_int, @w_operacion_int, @w_oficina, @w_cliente, @w_monto_pago
            
      while @@fetch_status = 0  begin

         select @w_cuenta = null
         
         select @w_cuenta = isnull(ea_cta_banco, '')
         from  cobis..cl_ente_aux 
         where ea_ente = @w_cliente
         
      
         EXEC @w_error     = sp_pago_cartera_srv
         @s_user           = @s_user,
         @s_term           = @s_term,
         @s_date           = @s_date,
         @s_ofi            = @w_oficina,         
         @i_banco          = @w_banco_int,
         @i_fecha_valor    = @w_fecha_valor,
         @i_forma_pago     = @w_forma_pago,
         @i_monto_pago     = @w_monto_pago,
         @i_cuenta         = @w_cuenta,      --Cuenta Santander del Cliente
         @i_ejecutar_fvalor= @i_ejecutar_fvalor , --parametro cuando se llama al sp_pago_cartera_srv no se ejecute la fecha valor y le traiga a las op a fecha actual
         @i_en_linea       = @i_en_linea,         
         @o_msg            = @w_msg out,
         @o_secuencial_ing = @w_secuencial_ing out
         
         if @w_error != 0 begin
            select 
            @w_est = 'E',
            @w_msg = 'ERROR AL EJECUTAR EL PAGO: ' + convert(varchar,@w_operacionca) + ' @w_banco_int: ' + @w_banco_int
            
            close cursor_pagos
            deallocate cursor_pagos
            goto ERROR_CURSOR
            
         end         
         
               
        INSERT INTO ca_corresponsal_det(
        cd_operacion        ,cd_banco       ,cd_sec_ing         ,cd_referencia  ,cd_secuencial)
        VALUES (
        @w_operacion_int    ,@w_banco_int  ,@w_secuencial_ing  ,@w_referencia   ,@w_secuencial )
         
         if @@error != 0 begin
            select
            @w_error = 710001,
            @w_est   = 'E',
            @w_msg   = 'ERROR AL CREAR DETALLE PAGO : ' + convert(varchar,@w_banco_int) + 'Secuencial Pag:' + convert(varchar,@w_secuencial_ing) +'Secuencial Corresp: '+convert(varchar,@w_secuencial)
            
            close cursor_pagos
            deallocate cursor_pagos
            
            goto ERROR_CURSOR
            
         end 
                
         fetch cursor_pagos into @w_banco_int, @w_operacion_int, @w_oficina, @w_cliente, @w_monto_pago
      end 
      
      if @w_commit = 'S' begin  
          select @w_commit = 'N'
          commit tran
      end  -- end cursor pagos
                  
      close cursor_pagos
      deallocate cursor_pagos
 
      GOTO MARCAR
                        
   end  --fin tipo = P     

   if @w_tipo = 'RG' begin  --Reverso de Garantias 

      if @@trancount = 0 begin  
         select @w_commit = 'S'
         begin tran
      end
     
      truncate TABLE #garantia_liquidas 
     
      select 
      @w_tramite_grupal    = max(tg_tramite)
      from  cob_credito..cr_tramite_grupal
      where tg_grupo   = @w_operacionca

      if @@rowcount = 0 BEGIN
         select 
		 @w_ente = @w_operacionca, --se envia el codigo del grupo
         @w_error = 2101011,
         @w_est = 'E',
         @w_msg = 'NO EXISTE TRAMITE INGRESADO PARA EL GRUPO: ' +  convert(varchar,@w_operacionca)
         
         
         goto ERROR_CURSOR
      END
      
      
       select
       @w_oficina = tr_oficina
       from cob_credito..cr_tramite 
       where tr_tramite = @w_tramite_grupal
        
      declare cursor_contabiliza_gar cursor for SELECT 
      cd_operacion,     convert(int,cd_banco),     cd_sec_ing
      FROM ca_corresponsal_det
      where cd_secuencial = @w_secuencial_trn_rv --@w_secuencial
      for read only

      OPEN cursor_contabiliza_gar
      
      fetch cursor_contabiliza_gar into @w_gl_cliente, @w_gl_tramite, @w_secuencial_ing
  
      while @@fetch_status = 0  begin
         
         SELECT @w_gl_diferencia = sum(dtr_monto)
         from ca_det_trn
         where dtr_operacion = -3  --codigo de las garantias
         and  dtr_secuencial = @w_secuencial_ing
            
         EXEC @w_error  = cob_custodia..sp_contabiliza_garantia
         @s_date           = @s_date,
         @s_ofi            = @w_oficina,
         @s_user           = @s_user,
         @s_term           = @s_term,     
         @i_operacion      = 'RC',
         @i_monto          = @w_diferencia,
         @i_en_linea       = 'N' ,   
         @i_ente           = @w_gl_cliente,
         @i_tramite        = @w_gl_tramite,
         @i_forma_pago     = @w_forma_pago
                
         if @w_error != 0 begin
           
            select             
            @w_est = 'E',
            @w_msg = 'ERROR AL EJECUTAR PROCESO DE CONTABILIZACION DE LA GARANTIA: ' + convert(varchar,@w_operacionca)
           
         
            close cursor_contabiliza_gar
            deallocate cursor_contabiliza_gar
            
            goto ERROR_CURSOR                         
         
         end 
         
        fetch cursor_contabiliza_gar INTO @w_gl_tramite, @w_gl_grupo, @w_gl_cliente,@w_gl_monto_garantia,@w_gl_pag_valor , @w_gl_diferencia
      
      end --while 
      
      close cursor_contabiliza_gar
      deallocate cursor_contabiliza_gar
      
      --Actualiza la transaccion reversada al estado a R 
      update ca_corresponsal_trn 
      set co_estado = 'R'
      where co_secuencial = @w_secuencial_trn_rv
      
      if @@error != 0 begin
         select 
         @w_error = 705032,
         @w_est   = 'E',
         @w_msg   = 'ERROR AL ACTUALIZAR LA TRANSACCION A REVERSAR : ' + convert(varchar,@w_secuencial_trn_rv)
         
         goto ERROR_CURSOR
      end
      
      if @w_commit = 'S' begin  
          select @w_commit = 'N'
          commit tran
      END  -- end cursor cursor_contabiliza_gar

      goto MARCAR 
   end
   
  

   if @w_tipo = 'RI' begin  --Reverso de Pagos Individuales        
      
      if @@trancount = 0 begin  
         select @w_commit = 'S'
         begin tran
      end
      
      Select
      @w_banco          = cd_banco,
      @w_operacionca    = cd_operacion,
      @w_secuencial_ing = cd_sec_ing 
      from ca_corresponsal_det
      where cd_secuencial = @w_secuencial_trn_rv --@w_secuencial
      
      if @@rowcount = 0  begin      
         select 
         @w_error = 2101011,           
         @w_est   = 'E',
         @w_msg   = 'NO EXISTE CODIGO INTERNO: ' +  convert(varchar,@w_operacionca)
         
         
         goto ERROR_CURSOR                         
      
      end 
      
      select 
      @w_oficina = op_oficina, 
             @w_ente    = op_cliente
      from ca_operacion 
      where op_operacion = @w_operacionca

      select @w_secuencial_pag = ab_secuencial_pag 
      FROM ca_abono 
      WHERE ab_secuencial_ing = @w_secuencial_ing
      and   ab_operacion      = @w_operacionca

      if @@rowcount = 0  begin
      
         select 
         @w_error = 2101011,           
         @w_est   = 'E',
         @w_msg   = 'NO PAGO APLICADO: ' +  convert(varchar,@w_operacionca)
        
         
         goto ERROR_CURSOR                         
      
      end 
      
      exec @w_error = cob_cartera..sp_fecha_valor 
      @i_banco       =@w_banco,
      @i_secuencial  =@w_secuencial_pag,
      @i_operacion   ='R',
      @i_observacion =@i_observacion,
      @i_fecha_mov   =@s_date,
      @t_trn         =7049,
      @s_srv         =@s_srv,
      @s_user        =@s_user,
      @s_term        =@s_term,
      @s_ofi         =@w_oficina,
      @s_date        =@s_date
      
      if @w_error != 0 begin
         select   
         @w_est            = 'E',         
         @w_msg            = 'ERROR AL EJECUTAR REVERSO DE LA OPERCION : ' + convert(varchar,@w_banco)
       

         goto ERROR_CURSOR
      end
      
      --Actualiza la transaccion reversada al estado a R 
      update ca_corresponsal_trn 
      set co_estado = 'R'
      where co_secuencial = @w_secuencial_trn_rv
      
      if @@error != 0 begin
         select 
         @w_error = 705032,
         @w_est   = 'E',
         @w_msg   = 'ERROR AL ACTUALIZAR LA TRANSACCION A REVERSAR : ' + convert(varchar,@w_secuencial_trn_rv)
         
         goto ERROR_CURSOR
      end
            
      if @w_commit = 'S' begin 
          select @w_commit = 'N'
          commit tran
      end      
    
      goto MARCAR     
   end --fin de RI

   
   if @w_tipo = 'RP' begin
       
      if @@trancount = 0 begin  
         select @w_commit = 'S'
         begin tran
      end
      
	  declare cursor_reversar_pago cursor for SELECT 
      cd_banco, cd_sec_ing ,cd_operacion        
      from ca_corresponsal_det
      where cd_referencia = @w_referencia
      and cd_secuencial = @w_secuencial_trn_rv --@w_secuencial
      for read only
      
      OPEN cursor_reversar_pago
      
      fetch cursor_reversar_pago into @w_banco, @w_sec_ing , @w_operacionca
	  
	  
      while @@fetch_status = 0  begin
		 
		 
         select 
         @w_oficina = op_oficina,
		 @w_ente    = op_cliente
         from ca_operacion 
         where op_operacion = @w_operacionca
      
         select 
         @w_secuencial_pag = ab_secuencial_pag,
         @w_estado_pag     = ab_estado 
         FROM ca_abono 
         WHERE ab_secuencial_ing = @w_sec_ing
         and  ab_operacion  = @w_operacionca
                 
         if @@rowcount = 0 begin
            select  
            @w_error = 2101011,
            @w_est   = 'E',            
            @w_msg   = 'NO EXISTE SECUENCIAL DE PAGO EN LA TABLA ca_abono op:' +  convert(varchar,@w_operacionca)
            
            
            close cursor_reversar_pago
            deallocate cursor_reversar_pago 
 
            goto ERROR_CURSOR
            
         end
         
         IF @w_estado_pag = 'RV' GOTO SIGUIENTE       
         
         exec @w_error = cob_cartera..sp_fecha_valor 
         @i_banco       = @w_banco,
         @i_secuencial  = @w_secuencial_pag,
         @i_operacion   = 'R',
         @i_observacion = @i_observacion,
         @i_fecha_mov   = @s_date,
         @t_trn         = 7049,
         @s_srv         = @s_srv,
         @s_user        = @s_user,
         @s_term        = @s_term,
         @s_ofi         = @w_oficina,
         @s_date        = @s_date,
         @i_en_linea    = 'N'
          
         if @w_error != 0 begin
            select 
            @w_est = 'E',
            @w_msg = 'ERROR AL EJECUTAR REVERSO DE LA OPERACION : ' + convert(varchar,@w_banco) + ' Error: ' + convert(varchar(10),@w_error)
            
            close cursor_reversar_pago
            deallocate cursor_reversar_pago
             
            goto ERROR_CURSOR
             
         end 
              
         SIGUIENTE:
         fetch cursor_reversar_pago into @w_banco, @w_sec_ing , @w_operacionca
         
      end --end while
      close cursor_reversar_pago
      deallocate cursor_reversar_pago
      
      --Actualiza la transaccion reversada al estado a R 
      update ca_corresponsal_trn 
      set co_estado = 'R'
      where co_secuencial = @w_secuencial_trn_rv
      
      if @@error != 0 begin
         select 
         @w_error = 705032,
         @w_est   = 'E',
         @w_msg   = 'ERROR AL ACTUALIZAR LA TRANSACCION A REVERSAR : ' + convert(varchar,@w_secuencial_trn_rv)
         
         goto ERROR_CURSOR
      end
      
      if @w_commit = 'S' begin  
          select @w_commit = 'N'
          commit tran
      end      

      --Regresar las operaciones a la fecha proceso
      declare cursor_reversar_fecha_valor cursor for SELECT 
      cd_banco, cd_sec_ing ,cd_operacion        
      from ca_corresponsal_det
      where cd_referencia = @w_referencia 
      and cd_secuencial = @w_secuencial_trn_rv
      for read only
      
      OPEN cursor_reversar_fecha_valor
      
      fetch cursor_reversar_fecha_valor into @w_banco, @w_sec_ing , @w_operacionca
      
      while @@fetch_status = 0  begin
      
         select 
		 @w_oficina = op_oficina,
		 @w_ente    = op_cliente,
         @w_fecha_ult_proceso = op_fecha_ult_proceso
         from ca_operacion 
         where op_operacion = @w_operacionca
      
         if @w_fecha_pro <= @w_fecha_ult_proceso 
         begin
         
            exec @w_error = cob_cartera..sp_fecha_valor 
            @s_date        = @w_fecha_pro,
            @s_user        = @s_user,
            @s_term        = @s_term,
            @t_trn         = 7049,
            @i_fecha_mov   = @w_fecha_pro,
            @i_fecha_valor = @w_fecha_pro,
            @i_banco       = @w_banco,
            @i_secuencial  = 1,
            @s_ofi         = @w_oficina,
            @i_operacion   = 'F'
             
            if @w_error != 0 begin
               select 
               @w_est = 'E',
               @w_msg = 'ERROR AL REGRESAR LA OPERACION A LA FECHA PROCESO : ' + convert(varchar,@w_banco) 
               
               close cursor_reversar_fecha_valor
               deallocate cursor_reversar_fecha_valor
                
               goto ERROR_CURSOR
                
            end 
         end
         
         --Aplicar los pagos que quedaron pendientes 
         exec @w_error = sp_abonos_batch
         @s_user          = @s_user,
         @s_term          = @s_term,
         @s_date          = @w_fecha_pro,
         @s_ofi           = @w_oficina,
         @i_en_linea      = 'N',
         @i_fecha_proceso = @w_fecha_pro,
         @i_operacionca   = @w_operacionca,
         @i_banco         = @w_banco,
         @i_pry_pago      = 'N',
         @i_cotizacion    = 1
         
         if @w_error <> 0 begin
            
            select 
            @w_est = 'E',
            @w_msg = 'ERROR AL APLICAR PAGOS PENDIENTES : ' + convert(varchar,@w_banco)          
            
            close cursor_reversar_fecha_valor
            deallocate cursor_reversar_fecha_valor
             
            goto ERROR_CURSOR

         end
              
         SIGUIENTE_FECHA_VALOR:
         fetch cursor_reversar_fecha_valor into @w_banco, @w_sec_ing , @w_operacionca
         
      end --end while
      close cursor_reversar_fecha_valor
      deallocate cursor_reversar_fecha_valor
    
   end -- FIN DE RP 
   
   MARCAR:
   

 
   if @i_operacion = 'C' and @w_bandera = 0 begin 
       
       SELECT 
       @w_concil_est   = 'S',
       @w_concil_user  = @s_user, 
       @w_concil_fecha = @s_date,
       @w_concil_obs   = @i_observacion
   
   END
   
   if @i_operacion = 'B' or @w_bandera = 1  begin 
       SELECT
       @w_concil_est   = NULL,
       @w_concil_user  = NULL,
       @w_concil_fecha = null,
       @w_concil_obs   = null
   end
   

   UPDATE ca_corresponsal_trn SET 
   co_estado           = @w_est,
   co_error_msg        = @w_msg ,
   co_error_id         = @w_error,
   co_concil_est       = isnull(@w_concil_est, co_concil_est),
   co_concil_user      = isnull(@w_concil_user, co_concil_user),
   co_concil_fecha     = isnull(@w_concil_fecha, co_concil_fecha),
   co_concil_obs       = isnull(@w_concil_obs, co_concil_obs)
   WHERE co_secuencial = @w_secuencial            
     
   if @@error != 0 begin
       select
       @w_error = 710002,
       @w_msg   = 'ERROR AL MARCAR COMO PROCESADO EL REGISTRO: ' + convert(varchar, @w_referencia)
       close cursor_transacciones
       deallocate cursor_transacciones
       
       GOTO ERROR_FIN
   end
   if @@error != 0 begin
       select
       @w_error = 710002,
       @w_msg   = 'ERROR AL MARCAR COMO PROCESADO EL REGISTRO: ' + convert(varchar, @w_referencia)
       close cursor_transacciones
       deallocate cursor_transacciones
       
       GOTO ERROR_FIN
   end
   
   GOTO SIGUIENTE_TRN
   ERROR_CURSOR:
    
   
   if @w_commit = 'S' begin
      select @w_commit = 'N'  
      rollback tran
   end
   
   UPDATE ca_corresponsal_trn SET 
   co_estado           = @w_est,
   co_error_msg        = @w_msg ,
   co_error_id         = @w_error
   WHERE co_secuencial = @w_secuencial
   
   if @@error != 0 begin
       select
       @w_error = 710002,
       @w_msg   = 'ERROR AL MARCAR COMO PROCESADO EL REGISTRO: ' + convert(varchar, @w_referencia)
       close cursor_transacciones
       deallocate cursor_transacciones
       
       GOTO ERROR_FIN
   end
   
   if @i_operacion = 'B' or @w_bandera = 1 
   begin 
      exec @w_secuencial = sp_gen_sec
      @i_operacion  = -5
      
      --Registro para Log pagos referenciados
      insert into ca_santander_log_pagos
      (sl_secuencial, sl_fecha_gen_orden, sl_banco, sl_cuenta,
       sl_monto_pag,  sl_referencia,      sl_archivo, 
       sl_tipo_error, sl_estado,          sl_mensaje_err, sl_ente)
      select 
      @w_secuencial  ,@w_fecha_pro   ,@w_ope,     @w_cuenta, 
      @w_monto       ,@w_referencia,  @w_archivo_pag, 
      'PR'           ,convert(varchar,@w_error) , @w_msg,@w_ente
      --Errores Cobis
    end 
    
    if @i_operacion = 'C' and @w_bandera = 0  begin
      
      close cursor_transacciones
      deallocate cursor_transacciones
      goto ERROR_FIN
    end 
   
      
   SIGUIENTE_TRN:
   fetch  cursor_transacciones into 
   @w_secuencial   , @w_forma_pago , @w_tipo  ,
   @w_operacionca  , @w_fecha_valor, @w_moneda, 
   @w_monto        , @w_concil_est,  @w_concil_motivo,
   @w_referencia   , @w_archivo_pag, @w_accion,
   @w_trn_id_corresp
   
end   
   
close cursor_transacciones
deallocate cursor_transacciones
   
if @i_externo = 'S'
   goto ERROR_FIN
   
return 0   
      
      
ERROR_FIN: 

if @w_commit = 'S' begin
  select @w_commit = 'N'  
  rollback tran
end      

select @o_msg = @w_msg

if @w_error is null or @w_error = 0 select @w_error = 1
   
if @i_en_linea = 'N' and (@i_operacion = 'B' or @w_bandera = 0 or @i_externo = 'S') begin 
      exec cob_cartera..sp_errorlog 
      @i_fecha       = @w_fecha_pro,
      @i_error       = @w_error,
      @i_usuario     = 'usrbatch',
      @i_tran        = 7999,
      @i_tran_name   = @w_sp_name,
      @i_cuenta      = '',
      @i_descripcion = @w_msg,
      @i_rollback    = 'N'
 
end else begin 
      exec cobis..sp_cerror 
      @t_from = @w_sp_name, 
      @i_num = @w_error, 
      @i_msg = @w_msg
end

if @i_externo = 'S' begin

   select   
   @o_codigo_err  = ce_error_codigo, --codigo del error esperado por el corresponsal
   @o_mensaje_err = ce_error_descripcion
   from ca_corresponsal_err
   where ce_corresponsal_id = @w_id_corresponsal
   and ce_error_cobis = @w_error

   if @@rowcount = 0 begin
      select 
      @o_codigo_err = @w_error,
      @o_mensaje_err = @w_msg
   end 
   
   return 0

end


return @w_error
GO