/************************************************************************/
/*   NOMBRE LOGICO:      interfaz_pago_enl.sp                           */
/*   NOMBRE FISICO:      sp_interfaz_pago_enl                           */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Kevin Rodríguez                                */
/*   FECHA DE ESCRITURA: Diciembre 2022                                 */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*  Procedimiento encargado de ejecutar programa orquestador de proce-  */
/*  so de pagos para la versión de Enlace                               */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA       AUTOR           RAZON                                  */ 
/* 05/12/2022    K. Rodríguez    Versión Inicial                        */
/* 20/12/2022    K. Rodríguez    S749257 Manejo fuera de línea          */
/* 29/03/2023    K. Rodriguez    S803203 Genera mov. bancos pago grupal */
/* 10/07/2023    G. Fernandez    S857599 Ingresa registro de interfaz   */
/* 28/07/2023    G. Fernandez    S857741 Parametros de licitud          */
/* 04/08/2023    G. Fernandez    Validación de número de cuenta         */
/* 09/08/2023    G. Fernandez    Se incluye parametros de facturación   */
/* 18/08/2023    G. Fernandez    Error de fecha valor para consultas    */
/* 06/11/2023    K. Rodriguez    R218803 Correccion saldo OP            */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_interfaz_pago_enl')
   drop proc sp_interfaz_pago_enl
go
create proc sp_interfaz_pago_enl
@s_ssn                int           = null,
@s_sesn               int           = null,
@s_ofi                smallint      = null,
@s_rol                smallint      = null,
@s_user               login         = null,
@s_date               datetime      = null,
@s_term               descripcion   = null,
@t_debug              char(1)       = 'N',
@t_file               varchar(10)   = null,
@t_from               varchar(32)   = null,
@s_srv                varchar(30)   = null,
@s_lsrv               varchar(30)   = null,
@t_trn                int           = null,
@s_format_date        int           = null,   
@s_ssn_branch         int           = null, 
@i_aplica_en_linea    char(1)      = 'N',
@i_canal              catalogo,                -- 2: Batch, 3: Web service             
@i_operacion          char(1),                 -- Q: Consulta saldo pago, P: Procesar pago,
@i_idcolector         smallint,                -- Cï¿½digo de Banco en Bancos.
@i_numcuentacolector  varchar(30)  = null,     -- Nï¿½mero de cuenta en Bancos
@i_idreferencia       varchar(30),             -- Nï¿½mero de referencia [Boleta]
@i_reference          varchar(30),             -- Nï¿½mero de operaciï¿½n de Cartera [Nï¿½mero largo]
@i_amounttopay        money,
@i_fuera_linea        char(1)      = 'N',
@i_fecha_pago         datetime     = null,
@o_amounttopay        money        = null out,
@o_reference          varchar(30)  = null out,
-- Parámetros factura electrónica
@o_guid               varchar(36)  = null out,
@o_fecha_registro     varchar(10)  = null out,
@o_ssn                int          = null out,
@o_orquestador_fact   char(1)      = null out

         
as declare
@w_return               int,
@w_error		        int,
@w_sp_name              varchar(64),
@w_moneda_local         int,
@w_operacionca          int, 
@w_monto_total          money,       -- Monto total a pagar [En caso de OPs hijas la sumatoria de los montos pagados].
@w_monto_pago           money,       -- Monto a pagar por operacion
@w_monto_tot_pagado     money,       -- Monto total pagado [En caso de OPs hijas la sumatoria de los montos pagados].
@w_monto_pagado         money,     -- Monto pagado por operacion
@w_num_prestamo         varchar(30),
@w_num_boleta           varchar(30),
@w_tipo_operacion       char(1),
@w_num_tabla            int,
@w_cod_banco            int,
@w_cta_banco            varchar(20),
@w_f_pago               varchar(20),
@w_tramite              int,
@w_cont                 smallint,
@w_banco                varchar(30),
@w_canal                catalogo,
@w_reg_pago_grupal_hijo char(1),
@w_secuencial_ing       int,
@w_ssn                  int,
@w_est_vigente          smallint,
@w_est_novigente        smallint,
@w_est_credito          smallint,
@w_est_cancelado        smallint,
@w_est_anulado          smallint,
@w_fecha_ult_proc       datetime,
@w_fecha_cierre         datetime,
@w_saldo_anterior       money,
@w_tipo_cobro           char(1),
@w_tipo_reduccion       char(1),
@w_operaciongr          cuenta,
@w_saldo_proy           money,
@w_saldo_acum           money

declare 
@sec_ing_abn_op_hija    table (oper int, sec_ing int)

-- Informaciï¿½n inicial
select @w_sp_name              = 'sp_interfaz_pago_enl',
       @w_cont                 = 0,
	   @w_ssn                  = -1,
	   @w_num_prestamo         = @i_reference,
       @w_num_boleta           = @i_idreferencia,
	   @w_canal                = @i_canal,
	   @w_reg_pago_grupal_hijo = 'N'

-- Fecha de cierre de Cartera
select @w_fecha_cierre = convert(varchar(10),fc_fecha_cierre,101)
from   cobis..ba_fecha_cierre with (nolock)
where  fc_producto = 7

-- Estado de Cartera
exec @w_error = sp_estados_cca 
@o_est_novigente = @w_est_novigente out,
@o_est_cancelado = @w_est_cancelado out,
@o_est_credito   = @w_est_credito out,
@o_est_anulado   = @w_est_anulado out

if @w_error <> 0 GOTO ERROR

-- Moneda local
select @w_moneda_local = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'MLO'
and pa_producto = 'ADM'
set transaction isolation level read uncommitted


if not exists (select 1 from ca_operacion where op_banco = @i_reference)
begin
   select @w_error = 701013 -- No existe operación activa de cartera
   goto ERROR
end
else
   select @o_reference = @i_reference

if @i_operacion = 'P'
begin

   if @i_idcolector not in (select cu_banco 
                            from cob_bancos..ba_cuenta)
   begin
      select @w_error = 711101 -- El código de banco ingresado no existe
      goto ERROR  
   end

   select @w_cod_banco = @i_idcolector 
   
   select @w_num_tabla =  codigo from cobis..cl_tabla 
   where  tabla = 'ca_bco_fpago_canales_externos'
      
   select @w_f_pago =  valor
   from cobis..cl_catalogo
   where tabla = @w_num_tabla
   and   codigo = @i_idcolector
   and estado = 'V'   

   if @@rowcount = 0
   begin
      select @w_error = 725200 -- Error, no existe forma de pago por defecto para el colector
      goto ERROR
   end
   
   
   if @i_numcuentacolector is null or @i_numcuentacolector = ''
   begin
   
      select @w_num_tabla =  codigo from cobis..cl_tabla 
      where  tabla = 'ca_bco_cta_canales_externos'
         
      select @w_cta_banco =  valor
      from cobis..cl_catalogo
      where tabla = @w_num_tabla
      and   codigo = @i_idcolector
      and estado = 'V' 
	  
	  if @@rowcount = 0
	  begin
        select @w_error = 725199 -- Error, no existe cuenta bancaria por defecto para el colector
        goto ERROR
	  end
 
   end
   else
   begin  
      select @w_cta_banco = @i_numcuentacolector  
   end
   
   --Valida que el colector este registrado en bancos
   if @w_cta_banco not in (select cu_cta_banco 
                            from cob_bancos..ba_cuenta where cu_banco = @i_idcolector)
   begin
      select @w_error = 711102 -- El número de cuenta ingresado no existe
      goto ERROR  
   end
   
end

-- Tipo de operaciï¿½n [G: Grupal Padre, H: Grupal Hija, N: Individual]
exec @w_return = sp_tipo_operacion
@i_banco    = @w_num_prestamo,
@i_en_linea = 'N',
@o_tipo     = @w_tipo_operacion out

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end

SELECT * into #operaciones FROM ca_operacion WHERE 1=2

if @w_tipo_operacion in ('G')
begin

   select @w_tramite = op_tramite
   from ca_operacion
   where op_banco = @w_num_prestamo

   insert into #operaciones
   select ca_operacion.* 
   from ca_operacion, cob_credito..cr_tramite_grupal with (nolock) 
      where tg_tramite = @w_tramite
      and tg_operacion = op_operacion
      and tg_participa_ciclo = 'S'
	  and op_estado not in (@w_est_novigente, @w_est_cancelado, @w_est_credito, @w_est_anulado)
   
   if @@rowcount = 0
   begin
      select @w_error = 725219 -- Error, la operaciï¿½n padre no tiene operaciones hijas asociadas o estas no estï¿½n activas
      goto ERROR  
   end
   
   -- Saldo grupal antes del Pago
   exec @w_error = sp_pago_grupal_consulta_montos
   @i_canal          = '1', -- Cartera
   @i_banco          = @w_num_prestamo, 
   @i_operacion      = 'R',
   @o_total_liquidar = @w_saldo_anterior out
   
   if @w_error <> 0
   begin
      select @w_error = @w_error
      goto ERROR
   end
   
end
else
begin
   
   insert into #operaciones
   select ca_operacion.* 
   from ca_operacion
   where op_banco = @w_num_prestamo
   and op_estado not in (@w_est_novigente, @w_est_cancelado, @w_est_credito, @w_est_anulado)
   
   if @@rowcount = 0
   begin
      select @w_error = 701013 -- No existe operación activa de cartera
      goto ERROR  
   end
   
   select @w_operacionca    = op_operacion,
          @w_tipo_reduccion = op_tipo_reduccion,
          @w_tipo_cobro     = op_tipo_cobro
   from ca_operacion 
   where op_banco = @w_num_prestamo
   
   -- Saldo Operaciï¿½n antes del pago
   exec @w_error     = sp_calcula_saldo
   @i_operacion      = @w_operacionca,
   @i_tipo_pago      = @w_tipo_cobro,
   @i_tipo_reduccion = @w_tipo_reduccion,
   @o_saldo          = @w_saldo_anterior out
   
   if @@error <> 0
   begin
      select @w_error = 708201 -- ERROR. Retorno de ejecucion de Stored Procedure
      goto ERROR
   end 
   
end

if @i_operacion in ('P', 'Q')
begin

   select @w_cont = count(1) from #operaciones -- Si es Individual o Hija, este count deberï¿½a ser 1
	   
   if @i_operacion = 'P'
      begin tran
   	  
   while @w_cont > 0
   begin
   
      -- Datos de la operaciï¿½n
      select top 1
         @w_banco          = op_banco,
         @w_operacionca    = op_operacion,
	     @w_tramite        = op_tramite,
		 @w_fecha_ult_proc = op_fecha_ult_proceso, 
		 @w_tipo_cobro     = op_tipo_cobro
      from #operaciones
	  
      if @w_fecha_ult_proc < @w_fecha_cierre --and @i_fuera_linea = 'S'
      begin
         if @i_operacion = 'P' --Se valida la operacion para manejo de severidad de error 
			select @w_error = 725247 -- La fecha valor de la operación es menor a la fecha proceso. Por favor, acercarse a la institución para su revisión
		 else
			select @w_error = 725299 -- La fecha valor de la operación es menor a la fecha proceso. Por favor, acercarse a la institución para su revisión
         
		 goto ERROR
      end
		 
	  -- Si es pago, realizar fecha valor si la fecha de pago es diferente a fecha ultimo proceso
      if @i_operacion = 'P'
      begin

         if @i_fecha_pago <> @w_fecha_ult_proc
		 begin
            exec @w_return = sp_fecha_valor
            @s_ssn               = @s_ssn, 
            @s_date              = @s_date,
            @s_user              = @s_user,
            @s_term              = @s_term,
            @i_fecha_valor       = @i_fecha_pago,
            @i_banco             = @w_banco,
            @i_operacion         = 'F',
            @i_en_linea          = @i_aplica_en_linea
		    
            if  @w_return <> 0
            begin
               select @w_error = @w_return
               goto ERROR
            end
		 end
	  end
   	  
	  -- Monto pago del préstamo (Saldo exigible de cuotas completas donde el vencimientos de estas cuotas es menor o igual a fecha proceso)
      select @w_saldo_proy = isnull(sum((abs(am_cuota + am_gracia - am_pagado)+am_cuota + am_gracia - am_pagado)/2.0),0),
             @w_saldo_acum = isnull(sum((abs(am_acumulado + am_gracia - am_pagado)+am_acumulado + am_gracia - am_pagado)/2.0),0)
      from  ca_dividendo,
            ca_amortizacion,
            ca_rubro_op,
            ca_concepto
      where di_operacion = @w_operacionca
      and   di_operacion = am_operacion
      and   di_operacion = ro_operacion
      and   am_concepto  = ro_concepto
      and   (di_estado  = 2 or di_estado = 1 )
	  and   di_fecha_ven <= @w_fecha_cierre
      and   co_concepto  = am_concepto
      and   am_estado    <> 3
      and  ((am_dividendo = di_dividendo + charindex (ro_fpago, 'A') and not(co_categoria in ('S','A') and am_secuencia > 1))
            or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = di_dividendo))
			
      if @w_tipo_cobro = 'P'
	     select @w_monto_pago = @w_saldo_proy
	   
      if @w_tipo_cobro = 'A'
         select @w_monto_pago = @w_saldo_acum
      
	  select @w_monto_total = isnull(@w_monto_total, 0)  + isnull(@w_monto_pago, 0)

      if @i_operacion = 'P'
      begin
	  
	     if @w_tipo_operacion = 'G'
            select @w_reg_pago_grupal_hijo = 'S'	   
		
         exec @w_return = cob_cartera..sp_interfaz_pago
         @s_srv                  = @s_srv,
         @s_rol                  = @s_rol,      
         @s_ssn                  = @s_ssn,
         @s_user                 = @s_user,
         @s_date                 = @s_date ,
         @s_sesn                 = @s_sesn,
         @s_term                 = @s_term,
         @s_ofi                  = @s_ofi,
         @s_ssn_branch	         = @s_ssn_branch,		 
         @i_operacion            = 'P',
         @i_banco                = @w_banco,
         @i_monto                = @w_monto_pago,
         @i_moneda               = @w_moneda_local,
         @i_canal                = @w_canal,
         @i_aplica_en_linea      = 'S',
         @i_fecha_pago           = @i_fecha_pago,
         @i_forma_pago           = @w_f_pago,                
         @i_banco_pago           = @w_cod_banco, 
         @i_cta_banco_pago       = @w_cta_banco, 
         @i_formato_fecha        = @s_format_date,
         @i_id_referencia_inter  = @w_num_boleta,
         @i_referencia_pago      = @w_num_boleta,
         @i_observacion          = null,
		 @i_reg_pago_grupal_hijo = @w_reg_pago_grupal_hijo,
		 @o_secuencial_ing       = @w_secuencial_ing out,
		 --Parametros de facturacion
		 @o_guid             = @o_guid             out,
         @o_fecha_registro   = @o_fecha_registro   out,
         @o_ssn              = @o_ssn              out,
		 @o_orquestador_fact = @o_orquestador_fact out
	     
         if @w_return <> 0
         begin
            select @w_error = @w_return
			rollback tran
			goto ERROR_FR   -- No va a lA secciï¿½n ERROR para evitar ejecuciï¿½n de sp_cerror [sp_interfaz_pago ya lo hace] 
         end

		 -- Monto pagado
		 select @w_monto_pagado = sum(abd_monto_mpg)
		 from ca_abono_det
		 where abd_operacion = @w_operacionca
		 and abd_secuencial_ing = @w_secuencial_ing
		 and abd_tipo = 'PAG'

         select @w_monto_tot_pagado = isnull(@w_monto_tot_pagado, 0) + isnull(@w_monto_pagado, 0)
		 
		 insert into @sec_ing_abn_op_hija values(@w_operacionca, @w_secuencial_ing)
      end

	  -- Si es pago, Fecha valor a la fecha ult proceso en la que se encontraba.
      if @i_operacion = 'P'
      begin
         if @i_fecha_pago <> @w_fecha_ult_proc
		 begin
            exec @w_return = sp_fecha_valor
            @s_ssn               = @s_ssn, 
            @s_date              = @s_date,
            @s_user              = @s_user,
            @s_term              = @s_term,
            @i_fecha_valor       = @w_fecha_ult_proc,
            @i_banco             = @w_banco,
            @i_operacion         = 'F',
            @i_en_linea          = @i_aplica_en_linea
		    
            if  @w_return <> 0
            begin
               select @w_error = @w_return
               goto ERROR
            end
		 end
	  end	  
	  
      delete #operaciones where op_operacion=@w_operacionca
      set @w_cont = (select count(1) from #operaciones)
	  
   end
   
   if @i_operacion = 'P'
   begin
      if @w_monto_tot_pagado <> @w_monto_total or @w_monto_tot_pagado <> @i_amounttopay
      begin
         select @w_error = 725207 -- Error, el monto a pagar no coincide con el monto ingresado
         goto ERROR
      end
	  
      if @w_tipo_operacion = 'G'
      begin
	  
	     -- Registro de abono Padre (Solo informativo en ca_abono y ca_abono_det, Pago no se aplica)
         exec @w_error = sp_pago_grupal_reg_val_abono
         @s_srv                         = @s_srv, 
         @s_user                        = @s_user,
         @s_term                        = @s_term,
         @s_ofi                         = @s_ofi, 
         @s_ssn                         = @s_ssn, 
         @s_date                        = @s_date,
         @s_sesn                        = @s_sesn,
         @s_rol                         = @s_rol, 
         @i_operacion                   = 'I', -- Registro 
         @i_opcion                      = 1,   -- Op. Padre 
         @i_externo                     = 'N', 
         @i_ejecutar                    = 'S',
         @i_banco_grupal                = @w_num_prestamo, 
         @i_monto_grupal                = @w_monto_tot_pagado,
         @i_forma_pago                  = @w_f_pago,
         @i_fecha_pago                  = @i_fecha_pago, 
         @i_moneda                      = @w_moneda_local,
         @i_cod_banco                   = @w_cod_banco,          
         @i_cta_banco                   = @w_cta_banco,
         @i_ref_pago_beneficiario       = @w_num_boleta, 
         @i_pago_interfaz               = 'S',         
         @i_id_referencia_inter         = @w_num_boleta,      
         @i_descripcion                 = 'Pago desde colector',   
         @i_debug                       = 'N',
         @i_canal                       = 3,   
         @o_secuencial_ing_abono_grupal = @w_secuencial_ing out
         
         if @w_error <> 0
            goto ERROR
			
         -- Identificaciï¿½n de referencia de pago grupal en registros individuales de abonos de OPs hijos
	     update ca_abono
	     set ab_secuencial_ing_abono_grupal = @w_secuencial_ing
		 from @sec_ing_abn_op_hija
	     where oper  = ab_operacion
	     and sec_ing = ab_secuencial_ing
	     
	     if @@error != 0
         begin
            select @w_error = 710002 -- Error en la actualizacion del registro
		    goto ERROR
         end
		 
		 select @w_operaciongr = op_operacion
		 from ca_operacion
		 where op_banco = @w_num_prestamo
		 
		 --Ingreso a interfaz pagos
		 INSERT INTO cob_cartera..ca_intefaz_pago
         (
            ip_operacionca     , ip_sdate               , ip_sterm          , ip_ssn,
            ip_ssen            , ip_forma_pago          , ip_banco_pago     , ip_cta_banco_pago,
            ip_aplicar_en_linea, ip_id_referencia_origen, ip_sec_ing_cartera, ip_fecha_pago,
            ip_canal           , ip_monto               , ip_estado
         )
         VALUES
         (
            @w_operaciongr     , @s_date               , @s_term            , @s_ssn,
            @s_sesn             , @w_f_pago             , @w_cod_banco       , @w_cta_banco,
            'S'                 , @w_num_boleta         , @w_secuencial_ing  , @i_fecha_pago,
            3                   , @w_monto_tot_pagado   , 'N'
         )
		  
		 -- Verificar Ingreso de abono Padre y aplicaciï¿½n de abonos Hijos
         -- Generar Movimiento en bancos si es pago de categorï¿½a BCOR
         exec @w_error = sp_pago_grupal_reg_val_abono
         @s_srv                         = @s_srv, 
         @s_user                        = @s_user,
         @s_term                        = @s_term,
         @s_ofi                         = @s_ofi, 
         @s_rol                         = @s_rol, 
         @s_ssn                         = @s_ssn, 
         @s_date                        = @s_date,
         @s_sesn                        = @s_sesn,
         @i_operacion                   = 'V', 
         @i_opcion                      = 2, 
         @i_externo                     = 'N', 
         @i_banco_grupal                = @w_num_prestamo, 
         @i_monto_grupal                = @w_monto_tot_pagado, 
         @i_forma_pago                  = @w_f_pago,
         @i_secuencial_ing_abono_grupal = @w_secuencial_ing, 
         @i_fecha_pago                  = @i_fecha_pago, 
         @i_moneda                      = @w_moneda_local, 
         @i_debug                       = 'N'
         
         if @w_error <> 0
            goto ERROR
		 
	     --  Tanqueo de datos para factura electrï¿½nica del Pago
         exec @w_error = sp_tanqueo_fact_cartera
         @s_user             = @s_user,
         @s_date             = @s_date,
         @s_rol              = @s_rol,
         @s_term             = @s_term,
         @s_ofi              = @s_ofi,
         @s_ssn              = @s_ssn,
         @t_corr             = 'N',
         @t_ssn_corr         = null,
         @t_fecha_ssn_corr   = null,
         @i_ope_banco        = @w_num_prestamo,
         @i_secuencial_ing   = @w_secuencial_ing,
         @i_tipo_operacion   = @w_tipo_operacion,
         @i_saldo_anterior   = @w_saldo_anterior,
         @i_fecha_ing        = @i_fecha_pago,
         @i_externo          = 'N',
         @i_tipo_tran        = 'PAG',
         @i_operacion        = 'I',
         @o_guid             = @o_guid             out,
         @o_fecha_registro   = @o_fecha_registro   out,
         @o_ssn              = @o_ssn              out,
		 @o_orquestador_fact = @o_orquestador_fact out
         
         if @w_error <> 0
            goto ERROR	

	  end
	  
	  commit tran
   end
   
   select @o_amounttopay = @w_monto_total 
	
end
		
return 0

ERROR:

if @w_canal <> 2
begin
   exec cobis..sp_cerror
   @t_debug='N',    
   @t_file=null,
   @t_from=@w_sp_name,   
   @i_num = @w_error
end

ERROR_FR:
if @i_fuera_linea = 'S'
begin
   insert into ca_7x24_errores values(@s_date,         getdate(),     @s_user,        @s_term, 
                                      @s_sesn,         @i_operacion,  @i_idcolector,  @i_numcuentacolector, 
									  @i_idreferencia, @i_reference,  @i_amounttopay, @i_fecha_pago, 
									  @w_error) 
   -- return 0
   -- return @w_error 
end


return @w_error    

go
