/************************************************************************/
/*      Archivo:                abonocnb.sp                             */
/*      Stored procedure:       sp_pago_cext                            */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:                                                   */
/*      Fecha de escritura:     Ene. 2012                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Ingreso de abonos por Corresponsales no Bancarios y Reversas    */
/*      P: Insercion de abonos                                          */
/*      R: Reversas de Abonos                                           */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*  11/Sep/2014   Carlos Avendaño    R457 Fecha Valor para aplicar pago */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_cext')
   drop proc sp_pago_cext
go

create  proc sp_pago_cext
   @s_ssn                  int              = null, 
   @s_user                 login            = null,
   @s_term                 varchar(30)      = null,
   @s_date                 datetime         = null,
   @s_sesn                 int              = null,
   @s_ofi                  smallint         = null, 
   @s_rol                  smallint         = null,
   @s_org                  char(1)          = null,
   @s_srv                  varchar(30)      = null,
   @s_ssn_branch           int              = null,
   @t_debug                char(1)          = 'N',
   @t_file                 varchar(20)      = null,
   @t_from                 descripcion      = null,
   @t_corr                 char(1)          = 'N',
   @t_ssn_corr             int              = null,
   @t_trn                  smallint         = null, --se igualo a null
   @t_user                 login            = null,
   @t_term                 varchar(30)      = null,
   @t_srv                  varchar(30)      = null,
   @t_ofi                  smallint         = null,
   @t_rol                  smallint         = null,
   @t_rty                  char(1)          = NULL,
   @i_banco                cuenta,
   @i_beneficiario         descripcion,
   @i_tipo                 char(3)          = NULL,
   @i_fecha_vig            datetime         = NULL,
   @i_ejecutar             char(1)          = 'S',
   @i_retencion            smallint         = 0,
   @i_en_linea             char(1)          = 'S',
   @i_producto             varchar(10),     --  Aqui esta llegando la forma de pago 
   @i_monto_mpg            money            = 0,
   @i_monto                money            = 0,
   @i_monto_max            money            = 0,
   @i_cuenta               varchar(24),
   @i_moneda               tinyint,
   @i_efectivo_mn          money            = 0,
   @i_efectivo_me          money            = 0,
   @i_prop                 money            = 0,
   @i_plaz                 money            = 0,
   @i_nocaja               char(1)          = 'N',
   @i_nofactura            smallint         = 0, 
   @t_ejec                 char(1)          = 'N',
   @i_sld_caja             money            = 0,
   @i_idcierre             int              = 0,
   @i_filial               smallint         = 1,
   @i_idcaja               int              = 0,
   @i_fecha_valor_a        datetime         = null,
   @i_tipo_reduccion       char(1)          = 'N',
   @i_pago_ext             char(1)          = 'N',  /*op1*/
   @i_conciliacion         char(1)          = 'S',
   @o_alerta_cli           varchar(40)      = null out,
   @o_secuencial_ing       int              = null out,
   @o_sec_efectivo_mn      varchar(24)      = null out,
   @o_sec_efectivo_me      varchar(24)      = null out,
   @o_sec_trn              varchar(24)      = null out,
   @o_monto_cap            money            = null out,
   @o_monto_int            money            = null out,
   @o_monto_iva            money            = null out,
   @o_monto_mpy            money            = null out,
   @o_monto_imo            money            = null out,
   @o_monto_sgd            money            = null out,
   @o_monto_otr            money            = null out,
   @o_numcuotas_can        smallint         = null out,
   @o_numtot_cuotas        smallint         = null out,
   @o_tramite              int              = null out,
   @o_oficial              varchar(12)      = null out,
   @o_cedula               varchar(20)      = null out,
   @o_des_fuente           varchar(20)      = null out,
   @o_oficina              smallint         = null out,
   @o_error_ext            int              = null out,
   @o_retorno_ext          varchar(255)     = null out
   as
   declare
   
   @w_sp_name              descripcion,
   @w_fecha                datetime,
   @w_pago_atx             char(1),
   @w_secuencial_ing       int,
   @w_error                int,
   @w_efectivo             money,
   @w_factor               int,
   @w_signo                char(1),
   @w_estado               varchar(1),
   @w_operacionca          int,
   @w_cp_categoria_c       catalogo,
   @w_cp_categoria_e       catalogo,
   @w_dia_habil            char(1),
   @w_producto             catalogo,
   @w_ciudad_ofi           int,
   @w_fecha_ult_proceso    datetime,
   @w_moneda               tinyint,
   @w_decimales_pago       float,
   @w_moneda_op            smallint,
   @w_moneda_mn            smallint,
   @w_num_dec_op           int,
   @w_num_dec_n            smallint,
   @w_pago_caja            char(1),
   @w_secuencial_pag       int,
   @w_op_tipo              char(1),   
   @w_ente                 int,       
   @w_valida_ente          char(1),   
   @w_rowcount             int,
   @w_alerta_cli           varchar(40),
   @w_reloj1               int,
   @w_reloj2               int,
   @w_reloj3               int,
   @w_reloj4               int,
   @w_reloj5               int,
   @w_reloj6               int,
   @w_reloj7               int,
   @w_reloj8               int,
   @w_cuota                money,   -- JAR REQ 151
   @w_commit               char(1),  -- Mod 01
   @w_msg                  varchar(130),
   @w_fecha_cartera        datetime

   --NOMBRE DEL SP Y FECHA DE HOY 
   select @w_sp_name = 'sp_pago_cext'
   
   select @i_cuenta = '100100',
          @w_moneda = 0

   select @w_dia_habil = 'N' 
   select @w_commit    = 'N'  -- Mod 01
   
   select @w_fecha_cartera = fc_fecha_cierre from cobis..ba_fecha_cierre where fc_producto = 7
   -- CIUDAD DE LA OFICINA EN QUE ESTA RADICADO EL CREDITO 
   select 
   @w_ciudad_ofi        = of_ciudad,
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
   @w_moneda_op         = op_moneda,
   @w_pago_caja         = isnull(op_pago_caja,'S'),
   @w_operacionca       = op_operacion,
   @w_op_tipo           = op_tipo,    
   @w_ente              = op_cliente,
   @w_cuota             = op_cuota    -- JAR REQ 151  
   from ca_operacion, cobis..cl_oficina noholdlock
   where op_banco   = @i_banco
   and   op_oficina = of_oficina
   
   if @@rowcount = 0
   begin
      select 
      @w_msg = 'NO SE ENCONTRO OFICINA PARA LA OPERACION',
      @w_error = 701025
      goto ERROR
   end
   
   select @w_reloj1  = sum(@w_operacionca * 100 + 1)
   select @w_reloj2  = sum(@w_operacionca * 100 + 2)
   select @w_reloj3  = sum(@w_operacionca * 100 + 3)
   select @w_reloj4  = sum(@w_operacionca * 100 + 4)
   select @w_reloj5  = sum(@w_operacionca * 100 + 5)
   select @w_reloj6  = sum(@w_operacionca * 100 + 6)
   select @w_reloj7  = sum(@w_operacionca * 100 + 7)
   select @w_reloj8  = sum(@w_operacionca * 100 + 8)
   
   exec sp_reloj @w_reloj1
   
   select 
   @w_alerta_cli = (select case codigo
                    when 'NIN' then ''
                    else valor 
                    end
                    from   cobis..cl_catalogo 
                    where  tabla in (select codigo from cobis..cl_tabla where tabla = 'cl_accion_cliente')
                    and    codigo = X.en_accion)
   from   cobis..cl_ente X
   where  en_ente = @w_ente    
   
   select @o_alerta_cli = @w_alerta_cli

   -- DECIMALES DE LA OPERACION 
   exec @w_error   = sp_decimales
   @i_moneda       = @w_moneda_op,
   @o_decimales    = @w_num_dec_op out,
   @o_mon_nacional = @w_moneda_mn  out,
   @o_dec_nacional = @w_num_dec_n  out

   if @w_error <> 0
       goto ERROR 
 
   if @s_date < @w_fecha_ult_proceso and @t_corr = 'N' and @i_conciliacion = 'N'
   begin
      select 
      @w_msg = 'FECHA DE PAGO POSTERIOR A FECHA DE PROCESO',  
      @w_error = 708136
      goto ERROR
   end
  
   -- Determinar si la transaccion es ejecutada por el REENTRY del SAIP 
   if @t_user is not null 
   begin
      select
      @s_user = @t_user,
      @s_term = @t_term,
      @s_srv  = @t_srv,
      @s_ofi  = @t_ofi,
      @s_rol  = @t_rol
 end 
   
   exec sp_reloj @w_reloj2
   
   --Modo de correccion  
   if @t_corr = 'N' 
   begin
      select @w_factor = 1, 
      @w_signo = 'C', 
      @w_estado = null
   end 
   else 
   begin
      select @w_factor = -1,
      @w_signo = 'D', 
      @w_estado = 'R'
   end

   if @@trancount = 0
   begin
      select @w_commit = 'S'
      begin tran
   end
      
   if @t_corr = 'N' 
   begin
      if @i_efectivo_me <> 0 
      begin        
         select @w_decimales_pago  = @i_efectivo_me  - floor(@i_efectivo_me)
         
         if @w_decimales_pago > 0 and @w_num_dec_n = 0  
         begin
            select
            @w_msg = 'FORMA DE PAGO MAL PARAMETRIZADA',
            @w_error = 710468
            goto ERROR
         end

		 if @i_conciliacion = 'S' and @s_date < @w_fecha_ult_proceso
		 begin
		 
		    exec @w_error = sp_fecha_valor 
            @s_date              = @w_fecha_cartera,     -- @s_date, REQ 457 se cambia para aplicacion de pagos con fecha valor en conciliacion    
            @s_user              = @s_user,
            @s_term              = @s_term,
            @i_fecha_valor       = @s_date,
            @i_banco             = @i_banco,
            @i_operacion         = 'F',
            @i_en_linea          = 'S',
			@i_pago_ext          = @i_pago_ext 
	  
			if @@error <> 0 or @w_error <> 0 
            begin  
               select @w_msg   = upper(mensaje) 
               from cobis..cl_errores 
               where numero = @w_error   
               
               if @w_msg is null 
                  select @w_msg = 'ERROR EN FECHA VALOR DE TRANSACCION (sp_fecha_valor)'
               
               
               select @w_error = @@error
               
               if @w_error = 0 and @@ERROR = 0
			      select @w_error = 149099 --Se coloca error por defecto por errores generados por formato de fecha CAV 09/04/2014
               
               goto ERROR
            end
		 end
		 
		 
         exec @w_error = sp_pago_cartera
         @s_user           = @s_user,
         @s_term           = @s_term,
         @s_date           = @w_fecha_cartera,       -- @s_date, REQ 457 se cambia para aplicacion de pagos con fecha valor en conciliacion
         @s_sesn           = @s_sesn,
         @s_ofi            = @s_ofi ,
         @s_ssn            = @s_ssn,
         @s_srv            = @s_srv,
         @i_banco          = @i_banco,
         @i_beneficiario   = @i_beneficiario,
         @i_fecha_vig      = @s_date,                -- Fecha con la que registra el pago en la abono y abono_det
         @i_ejecutar       = 'S',
         @i_en_linea       = 'S',
         @i_producto       = @i_producto, 
         @i_monto_mpg      = @i_efectivo_me,
         @i_cuenta         = @i_cuenta,
         @i_moneda         = @i_moneda,
         @i_dividendo      = @i_nofactura, 
         @i_tipo_reduccion = @i_tipo_reduccion,
         @i_pago_ext       = @i_pago_ext,      /*modificacion CNB*/
         @o_secuencial_ing = @w_secuencial_ing out

         if @w_error <> 0 
         begin
            select 
            @w_msg = 'ERROR EN APLICACION DE PAGO (sp_pago_cartera)'          
            goto ERROR
         end             
         select @o_sec_efectivo_mn = convert(varchar,isnull(@w_secuencial_ing,0)) 
      end

      exec sp_reloj @w_reloj3
     
      /**********************************************/
      -- GYA BPT Requerimiento FO-002
      -- Se ejecuta el procedimiento para valorar la  nota y porcentaje de la operación.
      -- JAR REQ 151. Se cambia de ubicacion para que la validacion se haga
      -- Teniendo en cuenta el pago actual
      /**********************************************/
      exec @w_error = cob_cartera..sp_valop
      @i_banco          = @i_banco,
      @i_cliente        = @w_ente,
      @i_operacion      = 'V',
      @i_fecha_pro      = @s_date,
      @i_pago_ext       = @i_pago_ext,      /*modificacion CNB*/
      @i_cuota_ant      = @w_cuota,           -- JAR REQ 151
      @i_tipo_reduccion = @i_tipo_reduccion   -- JAR REQ 151
      
      if @w_error <> 0 
      begin
         select 
         @w_msg = 'ERROR EN VALIDACION DE CONTRA OFERTA (sp_valop)'          
         goto ERROR
      end

      -- INI JAR REQ 218 - ALERTAS CUPOS
      exec @w_error = cob_credito..sp_alertas
      @i_cliente = @w_ente,
      @i_pago_ext = @i_pago_ext      /*modificacion CNB*/
      
      if @w_error <> 0 
      begin
         select @w_msg   = upper(mensaje) from cobis..cl_errores where numero = @w_error
         if @w_msg is null 
            select @w_msg = 'ERROR EN VALIDACION DE ALERTAS (cob_credito..sp_alertas)'          
         goto ERROR
      end
      -- FIN JAR REQ 218
   
      --INSERTA PARA EFECTIVO
      insert into ca_secuencial_atx (
      sa_operacion ,      sa_ssn_corr ,     sa_producto,              sa_secuencial_cca,             
      sa_secuencial_ssn,  sa_oficina,       sa_fecha_ing,             sa_fecha_real,
      sa_estado,          sa_ejecutar,      sa_valor_efe,             sa_valor_cheq,
      sa_error)                                                       
      values(@i_banco,    @t_ssn_corr,      @i_producto,              @w_secuencial_ing,
      isnull(@s_ssn,0),   isnull(@s_ofi,0), isnull(@s_date,''),       getdate(),
      null,               @i_ejecutar,      isnull(@i_efectivo_me,0), isnull(0,0),
      0)
      
      select @o_sec_efectivo_me = isnull(@o_sec_efectivo_me,'0.00')
      select @o_sec_efectivo_mn = isnull(@o_sec_efectivo_mn,'0.00')
      
   end
   -- RETORNAR SECUENCIAL PARA EL RECIBO 
   select @o_sec_trn = convert(varchar,@s_ssn)
   
   exec sp_reloj @w_reloj4

   if @t_corr = 'S'  
   begin
         
      if not exists (select sa_secuencial_cca
                     from   cob_cartera..ca_secuencial_atx
                     where  sa_secuencial_ssn  = @t_ssn_corr
                     and    sa_fecha_ing = @s_date
                     and    sa_oficina   = isnull(@s_ofi,0)
                     and    sa_operacion = @i_banco
                     and    sa_estado = 'A')
      begin

         select @w_msg = upper(mensaje) from cobis..cl_errores where numero = 701025
         if @w_msg is null 
            select @w_msg = 'ERROR EN SECUENCIAL DE CARTERA (ca_secuencial_atx)'         
         select @w_error =  701025
         goto ERROR
      end               

      declare
         reversar_tran cursor
         for    select sa_secuencial_cca
                from   cob_cartera..ca_secuencial_atx
                where  sa_secuencial_ssn  = @t_ssn_corr
                and    sa_oficina         = isnull(@s_ofi,0)
                and    sa_operacion       = @i_banco
                and    sa_estado          = 'A'    --def 6657
                order  by sa_secuencial_ssn, sa_secuencial_cca desc
         for read only
      
      declare @w_secuencial int
      open reversar_tran
      fetch reversar_tran 
      into @w_secuencial

      while @@fetch_status = 0--not in (-1,0) -jpe 
      begin 
         select @w_secuencial_pag = ab_secuencial_pag
         from   ca_abono 
         where  ab_secuencial_ing = @w_secuencial
         and    ab_operacion      = @w_operacionca
		 
		 if @i_conciliacion = 'S' and @w_fecha_ult_proceso <> @w_fecha_cartera 
         begin
           exec @w_error    = sp_fecha_valor 
           @s_ssn           = @s_ssn,
           @s_srv           = @s_srv,
           @t_rty           = @t_rty,
           @s_user          = @s_user,
           @s_term          = @s_term,
           @s_date          = @s_date,
           @s_ofi           = @s_ofi,
           @i_es_atx        = 'S',  
           @i_banco         = @i_banco,
           @i_fecha_valor   = @w_fecha_cartera, 
           @i_en_linea      = @i_en_linea,
           @i_pago_ext      = @i_pago_ext,      /*modificacion CNB*/
           @i_operacion     = 'F'
                               
           if @@error <> 0 or @w_error <> 0 
           begin  

              select @w_msg   = upper(mensaje) 
              from cobis..cl_errores 
              where numero = @w_error   
           
              if @w_msg is null 
                 select @w_msg = 'ERROR EN FECHA VALOR DE TRANSACCION (sp_fecha_valor)'
           
           
              select @w_error = @@error
           
              if @w_error = 0 and @@ERROR = 0
		         select @w_error = 149099 --Se coloca error por defecto por errores generados por formato de fecha CAV 09/04/2014
           
              goto ERROR
		   end
		 end
		 
		 select 
         @w_fecha_ult_proceso = op_fecha_ult_proceso
         from ca_operacion, cobis..cl_oficina noholdlock
         where op_banco   = @i_banco
         and   op_oficina = of_oficina
		 
         if @w_secuencial_pag <> 0 and @w_fecha_cartera = @w_fecha_ult_proceso 
         begin
            exec @w_error    = sp_fecha_valor 
            @s_ssn           = @s_ssn,
            @s_srv           = @s_srv,
            @t_rty           = @t_rty,
            @s_user          = @s_user,
            @s_term          = @s_term,
            @s_date          = @s_date,
            @s_ofi           = @s_ofi,
            @i_es_atx        = 'S',  
            @i_banco         = @i_banco,
            @i_secuencial    = @w_secuencial_pag,
            @i_en_linea      = @i_en_linea,
            @i_pago_ext      = @i_pago_ext,      /*modificacion CNB*/
            @i_operacion     = 'R'
                                
            if @@error <> 0 or @w_error <> 0 
            begin  

               select @w_msg   = upper(mensaje) 
               from cobis..cl_errores 
               where numero = @w_error   
               
               if @w_msg is null 
                  select @w_msg = 'ERROR EN REVERSA DE TRANSACCION (sp_fecha_valor)'
               
               goto ERROR
            end                      

            update cob_cartera..ca_secuencial_atx  set    
            sa_estado = 'R'
            where  sa_operacion = @i_banco
            and    sa_secuencial_cca = @w_secuencial
            and    sa_ssn_corr  = @t_ssn_corr
            and    sa_oficina   = isnull(@s_ofi,0)            
         end 
         ELSE 
         begin

            exec @w_error    = sp_fecha_valor 
            @s_ssn           = @s_ssn,
            @s_srv           = @s_srv,
            @t_rty           = @t_rty,
            @s_user          = @s_user,
            @s_term          = @s_term,
            @s_date          = @s_date,
            @s_ofi           = @s_ofi,
            @i_es_atx        = 'S',  
            @i_banco         = @i_banco,
            @i_fecha_valor   = @w_fecha_cartera, 
            @i_en_linea      = @i_en_linea,
            @i_pago_ext      = @i_pago_ext,      /*modificacion CNB*/
            @i_operacion     = 'F'
                                
            if @@error <> 0 or @w_error <> 0 
            begin  

               select @w_msg   = upper(mensaje) 
               from cobis..cl_errores 
               where numero = @w_error   
               
               if @w_msg is null 
                  select @w_msg = 'ERROR EN FECHA VALOR DE TRANSACCION (sp_fecha_valor)'
               
               
               select @w_error = @@error
               
               if @w_error = 0 and @@ERROR = 0
			      select @w_error = 149099 --Se coloca error por defecto por errores generados por formato de fecha CAV 09/04/2014
               
               goto ERROR
            end                      
         
            exec @w_error     = sp_eliminar_pagos
            @s_ssn            = @s_ssn,
            @s_srv            = @s_srv,
            @s_date           = @s_date,
            @s_user           = @s_user,
            @s_term           = @s_term,
            @s_ofi            = @s_ofi,
            @t_trn            = 7036,
            @i_banco          = @i_banco,
            @i_operacion      = 'D',
            @i_secuencial_ing = @w_secuencial,
            @i_pago_ext       = @i_pago_ext,      /*modificacion CNB*/
            @i_en_linea       = @i_en_linea
            
            if @@error <> 0 or @w_error <> 0 
            begin
               select @w_msg   = upper(mensaje) 
               from cobis..cl_errores 
               where numero = @w_error
               if @w_msg is null 
                  select @w_msg = 'ERROR EN ELIMINACION DE PAGOS (sp_eliminar_pagos)'                   
               goto ERROR
            end
   
            update cob_cartera..ca_secuencial_atx set    
            sa_estado = 'E'
            where  sa_operacion = @i_banco
            and    sa_secuencial_cca = @w_secuencial
            and    sa_ssn_corr  = @t_ssn_corr
            and    sa_oficina   = isnull(@s_ofi,0)                        
         end

         if @i_conciliacion = 'S' and @w_fecha_ult_proceso < @w_fecha_cartera 
         begin
           exec @w_error    = sp_fecha_valor 
           @s_ssn           = @s_ssn,
           @s_srv           = @s_srv,
           @t_rty           = @t_rty,
           @s_user          = @s_user,
           @s_term          = @s_term,
           @s_date          = @s_date,
           @s_ofi           = @s_ofi,
           @i_es_atx        = 'S',  
           @i_banco         = @i_banco,
           @i_fecha_valor   = @w_fecha_cartera, 
           @i_en_linea      = @i_en_linea,
           @i_pago_ext      = @i_pago_ext,      /*modificacion CNB*/
           @i_operacion     = 'F'
                               
           if @@error <> 0 or @w_error <> 0 
           begin  

              select @w_msg   = upper(mensaje) 
              from cobis..cl_errores 
              where numero = @w_error   
           
              if @w_msg is null 
                 select @w_msg = 'ERROR EN FECHA VALOR DE TRANSACCION (sp_fecha_valor)'
           
           
              select @w_error = @@error
           
              if @w_error = 0 and @@ERROR = 0
		         select @w_error = 149099 --Se coloca error por defecto por errores generados por formato de fecha CAV 09/04/2014
           
              goto ERROR
		   end
        end 
         
         fetch reversar_tran into @w_secuencial  
      end
      
      close reversar_tran
      deallocate reversar_tran
   end
   
   exec sp_reloj @w_reloj5
   
   if @i_efectivo_me <> 0 
   begin
      select 
      @w_efectivo = @i_efectivo_me
   end
   
   exec sp_reloj @w_reloj6
   
   --- VALIDACION DE CLIENTE REQ 520 IFJ
   exec cobis..sp_ente_bloqueado
   @t_trn       = 175,
   @i_operacion = 'B',
  @i_ente      = @w_ente,
   @i_pago_ext  = @i_pago_ext,
   @o_retorno   = @w_valida_ente output
  
   exec sp_reloj @w_reloj7
   
   ---SACAR EL ESTADO DE LA TRANSACCIONES
   
   if @t_corr = 'N'  
   begin
      select @w_estado = ab_estado
      from   ca_abono
      where  ab_operacion = @w_operacionca
      and    ab_secuencial_ing =  @w_secuencial_ing
   
      if @@rowcount = 0
      begin
         select @w_msg   = upper(mensaje) from cobis..cl_errores where numero = 711020
         if @w_msg is null 
            select @w_msg = 'ERROR EN ACTUALIZACION DE ESTADO DE ABONO (ca_abono)'
         select @w_error =  711020
         goto ERROR
      end
      ELSE
      begin
         update cob_cartera..ca_secuencial_atx  set 
         sa_estado = 'A' -- Para el ATX estar en el modulo es estar aplicada
         where  sa_operacion = @i_banco
         and    sa_secuencial_cca = @w_secuencial_ing   
      end     
   end

   -- CONSULTAR LOS DATOS PARA RETORNAR RESUTADO DE APLICACION
   exec sp_consulta_abono_atx
   @s_sesn                    = @s_sesn,
   @s_ssn                     = @s_ssn,
   @s_user                    = @s_user,
   @s_date                    = @s_date,
   @s_ofi                     = @s_ofi,
   @s_term                    = @s_term,
   @s_srv                     = @s_srv,
   @i_secuencial_ing          = @w_secuencial_ing,       
   @i_operacionca             = @w_operacionca,
   @i_en_linea                = 'S',
   @i_total                   = @i_monto_mpg,
   @o_monto_cap               = @o_monto_cap     out,
   @o_monto_int               = @o_monto_int     out,
   @o_monto_iva               = @o_monto_iva     out,
   @o_monto_mpy               = @o_monto_mpy     out,
   @o_monto_imo               = @o_monto_imo     out,
   @o_monto_sgd               = @o_monto_sgd     out,
   @o_monto_otr               = @o_monto_otr     out,
   @o_numcuotas_can           = @o_numcuotas_can out,
   @o_numtot_cuotas  = @o_numtot_cuotas out,
   @o_tramite                 = @o_tramite       out,
   @o_oficial                 = @o_oficial       out,
   @o_cedula                  = @o_cedula        out,
   @o_des_fuente              = @o_des_fuente    out,
   @o_oficina                 = @o_oficina       out
   
   if @@error <> 0 
   begin
      select @w_msg = 'ERROR EN CONSULTA DE PAGO APLICADO (sp_consulta_abono_atx)',
      @w_error = 99999
      goto ERROR  
   end          
   exec sp_reloj @w_reloj8

   if @i_pago_ext = 'N'
   begin
      select 
      'results_submit_rpc',
      r_monto_cap     = @o_monto_cap,
      r_monto_int     = @o_monto_int,
      r_monto_iva     = @o_monto_iva,
      r_monto_mpy     = @o_monto_mpy,
      r_monto_imo     = @o_monto_imo,
      r_monto_sgd     = @o_monto_sgd,
      r_monto_otr     = @o_monto_otr,
      r_numcuotas_can = @o_numcuotas_can,
      r_numtot_cuotas = @o_numtot_cuotas,
      r_tramite       = @o_tramite,
      r_oficial       = @o_oficial,
      r_cedula        = @o_cedula,
      r_des_fuente    = @o_des_fuente,
      r_oficina       = @o_oficina
   end  
              
   if @w_commit = 'S'
   begin
      commit tran
      select @w_commit = 'N' 
   end

   if @t_corr = 'N' 
   begin
      select @o_error_ext   = 0               
      select @o_retorno_ext = 'PAGO APLICADO' 
   end
   
   if @t_corr = 'S'
   begin
      select @o_error_ext   = 0               
      select @o_retorno_ext = 'REVERSO APLICADO' 
   end

   return 0
   
ERROR:
   if @w_commit = 'S'
   begin
      select @w_commit = 'N'
      rollback tran
   end
   
   begin tran
   --SE INSERTA EN LA TABLA CA_secuencial_atx PARA FACILITAR LAS REVISIONES POSTERIORES
   exec @w_secuencial_ing = sp_gen_sec 
   @i_operacion = @w_operacionca
      
   insert into ca_secuencial_atx
   (
   sa_operacion ,      sa_ssn_corr ,   sa_producto,  sa_secuencial_cca ,             
   sa_secuencial_ssn,  sa_oficina,     sa_fecha_ing, sa_fecha_real,
   sa_estado,          sa_ejecutar,    sa_valor_efe, sa_valor_cheq,
   sa_error
   )
   values
   (
   @i_banco,           @t_ssn_corr,      @i_producto,               isnull(@w_secuencial_ing,0),
   isnull(@s_ssn,0),   isnull(@s_ofi,0), isnull(@s_date,''),        getdate(),
   'X',                @i_ejecutar,      isnull(@i_efectivo_me,0),  isnull(0,0),
   @w_error
   )    
       
   commit tran

   select 
   @o_error_ext   = @w_error,
   @o_retorno_ext = @w_msg 
   return 0


