/********************************************************************/
/*   NOMBRE LOGICO:      pago_grupal_reg_val_abono.sp               */
/*   NOMBRE FISICO:      sp_pago_grupal_reg_val_abono               */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Kevin Rodríguez                            */
/*   FECHA DE ESCRITURA: Enero 2023                                 */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                           PROPOSITO                              */
/*   Programa que realiza el registro y validaci�n de un pago grupal*/ 
/*   I: Ingreso de registro/aplicaci�m del pago (Padre e hijos)     */
/*   V: Validaci�n de los registros de pagos (Padre e hijos)        */
/*   X: Obtener secuencial de Operaci�n (Padre)                     */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  30-Ene-2023    K. Rodr�guez     Emision Inicial                 */
/*  28/07/2023     G. Fernandez     S857741 Parametros de licitud   */
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_grupal_reg_val_abono')
   drop proc sp_pago_grupal_reg_val_abono
go

create proc sp_pago_grupal_reg_val_abono
@s_user                         login,
@s_date                         datetime,
@s_term                         varchar(30),
@s_ofi                          smallint,
@s_ssn                          int,
@s_sesn                         int,
@s_srv                          varchar(30) = null,
-- Parametros para licitud de fondos
@s_ssn_branch           int         = null,
@s_lsrv                 varchar(30) = null,
@s_rol                  smallint    = null,
@s_org                  char(1)     = null,
@t_ssn_corr             int         = null,
@t_debug                char(1)     = 'N',
@t_file                 varchar(20) = null,
@t_from                 descripcion = null,
@t_trn                  int         = null,
-- Fin Parametros para licitud de fondos
@i_operacion                    char(1),
@i_opcion                       tinyint,
@i_externo                      char(1)     = 'N',
@i_banco_grupal                 cuenta      = null,
@i_monto_grupal                 money       = null,
@i_forma_pago                   varchar(10) = null,
@i_secuencial_ing_abono_grupal  int         = null,
@i_secuencial_interno           int         = null, -- Secuencial previamente obtenido (@o_secuencial_interno)
@i_banco_hija                   cuenta      = null,
@i_monto_hija                   money       = null,
@i_fecha_pago                   datetime    = null,
@i_moneda                       int         = null,
@i_cod_banco                    int         = null,
@i_cta_banco                    cuenta      = '',
@i_ref_pago_beneficiario        varchar(50) = null, -- N�mero de referencia / boleta (En tipo de pago BCOR o MOEL) o beneficiario   
@i_tipo_reduccion               char(1)     = null,
@i_tipo_cobro                   char(1)     = null,
@i_retencion                    tinyint     = null,
@i_cuota_completa               char(1)     = null,
@i_tipo_aplicacion              char(1)     = null,
@i_calcula_devolucion           char(1)     = null,
@i_pago_interfaz                char(1)     = 'N',
@i_id_referencia_inter          varchar(30) = null,
@i_aplica_licitud               char(1)     = 'N',
@i_descripcion                  varchar(52) = '', 
@i_ejecutar                     char(1)     = 'S',
@i_debug                        char(1)     = 'N',
@i_canal                        char(1)     = 1,         -- 1: CARTERA, 2: BATCH, 3: SERVICIO WEB(BCOR), 4: ATX
@i_operaciones_montos           varchar(2000)= null,     -- N�mero de Operaciones hijas(op_banco) y sus montos identificadas por un separador
@o_secuencial_ing_abono_grupal  int         = null out,  -- Secuencial de ingreso de Abono Padre o Hijo
@o_secuencial_interno           int         = null out,  -- Secuencial para uso especifico de tabla de condiciones de abono
-- Parametros para licitud de fondos
@o_consep                       char(1)     = null out,
@o_ssn                          int         = null out,
@o_monto                        money       = null out

as
declare 
@w_sp_name                     descripcion,
@w_error                       int,
@w_banco_actual                cuenta,
@w_operacionca_actual          int,
@w_moneda_local                int,
@w_monto_actual                money,
@w_fecha_ult_proc_actual       datetime,
@w_retencion                   tinyint,
@w_secuencial_ing              int,
@w_secuencial_rpa              int,
@w_cotizacion                  float,
@w_reg_pago_grupal_padre       char(1),
@w_reg_pago_grupal_hijo        char(1),
@w_monto_pago_hijos            money,
@w_monto_pago_padre            money,
@w_ejecutar                    char(1),
@w_tipo_op                     char(1),
@w_tipo_reduccion              char(1), 
@w_tipo_cobro                  char(1),      
@w_cuota_completa              char(1),     
@w_tipo_aplicacion             char(1),     
@w_calcula_devolucion          char(1),
@w_separador                   char(1)


-- Establecimiento de variables locales iniciales
select @w_sp_name   = 'sp_pago_grupal_reg_val_abono',
       @w_error     = 0,
	   @w_separador = '|'
	   
-- Moneda local
select  @w_moneda_local = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'MLO'
and pa_producto = 'ADM'
set transaction isolation level read uncommitted

-- Validaci�n de par�metros y asignaci�in de variables locales
if @i_operacion = 'I'
begin
   if (@i_banco_grupal is null or @i_banco_grupal = '')
      and (@i_monto_grupal is null or @i_monto_grupal <= 0)
      and (@i_forma_pago is null or @i_forma_pago = '')
      and @i_opcion = 1
   begin
      select @w_error = 708150 -- Campo requerido esta con valor nulo
      goto ERROR
   end
   
   if (@i_banco_hija  is null or @i_banco_hija  = '')
      and (@i_monto_hija is null or @i_monto_hija <= 0)
      and (@i_forma_pago is null or @i_forma_pago = '')
	  and (@i_secuencial_ing_abono_grupal is null)
      and @i_opcion = 2
   begin
      select @w_error = 708150 -- Campo requerido esta con valor nulo
      goto ERROR
   end
   
   select @w_banco_actual = case @i_opcion when 1 then @i_banco_grupal when 2 then @i_banco_hija  end
end

if @i_operacion = 'V'
begin

   if (@i_banco_grupal is null or @i_banco_grupal = '')
      and (@i_monto_grupal is null or @i_monto_grupal <= 0)
      and (@i_forma_pago is null or @i_forma_pago = '')
	  and (@i_secuencial_ing_abono_grupal is null)
   begin
      select @w_error = 708150 -- Campo requerido esta con valor nulo
      goto ERROR
   end
   
   select @w_banco_actual = @i_banco_grupal
end

if @i_operacion = 'X'
begin

   if (@i_banco_grupal is null or @i_banco_grupal = '') and @i_opcion = 1
   begin
      select @w_error = 708150 -- Campo requerido esta con valor nulo
      goto ERROR
   end
   
   if (@i_banco_grupal is null or @i_banco_grupal = '')
      and (@i_secuencial_interno is null or @i_secuencial_interno < 0)
      and (@i_forma_pago is null or @i_forma_pago = '')
	  and (@i_fecha_pago is null or @i_fecha_pago = '')
	  and (@i_operaciones_montos is null or @i_operaciones_montos = '')
      and @i_opcion = 2
   begin
      select @w_error = 708150 -- Campo requerido esta con valor nulo
      goto ERROR
   end
   
   select @w_banco_actual = @i_banco_grupal

end

-- Datos de la operaci�n
select @i_ref_pago_beneficiario = isnull(@i_ref_pago_beneficiario, '')
   
select @w_operacionca_actual    = op_operacion,
       @w_fecha_ult_proc_actual = op_fecha_ult_proceso
from ca_operacion
where op_banco = @w_banco_actual

if @@rowcount = 0
begin
   select @w_error = 701013 -- No existe operaci�n activa de cartera
   goto ERROR
end

if @i_operacion = 'I' -- Ingreso/Aplicaci�n Abono
begin

   -- Valores para @i_opcion = 1 (Padre), @i_opcion = 2 (Hijo)
   select @w_reg_pago_grupal_padre = case @i_opcion when 1 then 'S' else 'N' end,
		  @w_reg_pago_grupal_hijo  = case @i_opcion when 1 then 'N' else 'S' end,
		  @w_ejecutar              = case @i_opcion when 1 then 'N' else @i_ejecutar end,
		  @w_monto_actual          = case @i_opcion when 1 then @i_monto_grupal when 2 then @i_monto_hija  end
   
   -- Negociaci�n del abono
   select @w_tipo_reduccion        = isnull(@i_tipo_reduccion, op_tipo_reduccion),
          @w_tipo_cobro            = isnull(@i_tipo_cobro, op_tipo_cobro),
		  @w_cuota_completa        = isnull(@i_cuota_completa,op_cuota_completa),
		  @w_tipo_aplicacion       = isnull(@i_tipo_aplicacion, op_tipo_aplicacion),
		  @w_calcula_devolucion    = isnull(@i_calcula_devolucion, op_calcula_devolucion)
   from ca_operacion
   where op_banco = @w_banco_actual
      
   -- Cotizaci�n de moneda de pago del d�a
   exec @w_error = cob_cartera..sp_consulta_divisas
   @t_trn               = 77541,
   @i_banco             = @w_banco_actual,
   @i_modulo            = 'CCA',
   @i_concepto          = 'PAG',
   @i_operacion         = 'C',
   @i_cot_contable      = 'S',
   @i_moneda_origen     = @i_moneda,
   @i_moneda_destino    = @w_moneda_local,
   @o_cotizacion        = @w_cotizacion out,
   @o_tipo_op           = @w_tipo_op out

   if @w_error <> 0
      goto ERROR
	  
   --Retencion
   select @w_retencion = isnull(@i_retencion, cp_retencion) 
   from cob_cartera..ca_producto
   where cp_producto = @i_forma_pago
   and cp_moneda = @i_moneda

   if @@rowcount <> 1
   begin
      select @w_error = 725100 -- LA FORMA DE PAGO NO POSEE UN VALOR DE RETENCI�N
      goto ERROR
   end

   if @i_externo = 'S'
      begin tran
   
   if @i_canal = 4 and @w_reg_pago_grupal_hijo = 'S' -- Abono grupal hijo [Toma en cuenta la licitud de fondos]
   begin
      
      exec @w_error = sp_pago_cartera
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date ,
      @s_sesn           = @s_sesn,
      @s_ofi            = @s_ofi,
      @s_ssn            = @s_ssn,
      @s_srv            = @s_srv,
      -- Parametros para licitud de fondos  
      @s_ssn_branch     = @s_ssn_branch,
      @s_lsrv           = @s_lsrv,
      @s_rol            = @s_rol,
      @s_org            = @s_org,
      @t_ssn_corr       = @t_ssn_corr,
      @t_debug          = @t_debug,
      @t_file           = @t_file,
      @t_from           = @t_from,
      @t_trn            = @t_trn,
      -- Fin Parametros para licitud de fondos
      @i_banco          = @w_banco_actual,
      @i_beneficiario   = @i_ref_pago_beneficiario,
      @i_fecha_vig      = @i_fecha_pago,
      @i_ejecutar       = @w_ejecutar,
      @i_en_linea       = 'S',
      @i_producto       = @i_forma_pago,
      @i_monto_mpg      = @w_monto_actual,
      @i_cuenta         = @i_cta_banco,
      @i_moneda         = @i_moneda,
      @i_dividendo      = 0,
      @i_tipo_reduccion = @w_tipo_reduccion,
	  @i_retencion      = @w_retencion,
      @i_aplica_licitud = @i_aplica_licitud,
	  @i_reg_pago_grupal_hijo  = @w_reg_pago_grupal_hijo,   -- Bandera Pr�stamo hijo, inserta en estructuras registra y aplica abono
      @o_secuencial_ing = @w_secuencial_ing out,
      -- Ingreso de parametros solo utilizados para licitud de fondos
      @o_consep         = @o_consep out,
      @o_ssn            = @o_ssn out,
      @o_monto          = @o_monto out

      if @w_error <> 0
         goto ERROR
			  
   end
   else
   begin

      -- Detalle de abono
      exec @w_error = cob_cartera..sp_ing_detabono
      @s_user               = @s_user,
      @s_term               = @s_term,
      @s_date               = @s_date,
      @s_sesn               = @s_sesn,
      @i_accion             = 'I',
      @i_encerar            = 'S', 
      @i_tipo               = 'PAG',
      @i_concepto           = @i_forma_pago,
      @i_monto_mpg          = @w_monto_actual,
      @i_monto_mop          = @w_monto_actual,
      @i_monto_mn           = @w_monto_actual,
      @i_banco              = @w_banco_actual,
      @i_cuenta             = @i_cta_banco,
      @i_cod_banco          = @i_cod_banco,   
      @i_moneda             = @i_moneda, 
      @i_beneficiario       = @i_ref_pago_beneficiario, -- N�mero de referencia o boleta
      @i_cotizacion_mpg     = @w_cotizacion,
      @i_cotizacion_mop     = @w_cotizacion,
      @i_tcotizacion_mpg    = @w_tipo_op,
      @i_tcotizacion_mop    = @w_tipo_op,
      @i_no_cheque          = 0,
      @i_inscripcion        = 0,
      @i_carga              = 0,
      @i_porcentaje         = 0.0,
      @i_descripcion        = @i_descripcion
      
      if @w_error <> 0
         goto ERROR
      
      -- Datos del abono (Cabecera)
      exec @w_error = cob_cartera..sp_ing_abono
      @s_srv                   = @s_srv, 
      @s_user                  = @s_user,
      @s_term                  = @s_term,
      @s_ofi                   = @s_ofi, 
      @s_rol                   = @s_rol, 
      @s_ssn                   = @s_ssn, 
      @s_date                  = @s_date,
      @s_sesn                  = @s_sesn,
	  @s_ssn_branch            = @s_ssn_branch,
      @i_accion                = 'I',
      @i_banco                 = @w_banco_actual,
      @i_tipo                  = 'PAG',
      @i_fecha_vig             = @i_fecha_pago,
      @i_ejecutar              = @w_ejecutar,         -- Registro de abono grupal no se debe aplicar
      @i_retencion             = @w_retencion, 
      @i_cuota_completa        = @w_cuota_completa,
      @i_anticipado            = 'S',
      @i_tipo_reduccion        = @w_tipo_reduccion,
      @i_proyectado            = @w_tipo_cobro,
      @i_tipo_aplicacion       = @w_tipo_aplicacion, 
      @i_prioridades           = '',                  -- Cuando se env�a en nulo o vacio el sistema respeta las prioridades actuales
      @i_calcula_devolucion    = @w_calcula_devolucion,
      @i_solo_capital          = 'N',
      @i_pago_interfaz         = @i_pago_interfaz,
      @i_id_referencia_inter   = @i_id_referencia_inter,
      @i_forma_pago            = @i_forma_pago,
      @i_cuenta                = @i_cta_banco,
      @i_cod_banco             = @i_cod_banco,
      @i_reg_pago_grupal_padre = @w_reg_pago_grupal_padre,  -- Bandera Pr�stamo padre no aplica pago, solo inserta en estructuras
      @i_reg_pago_grupal_hijo  = @w_reg_pago_grupal_hijo,   -- Bandera Pr�stamo hijo, inserta en estructuras registra y aplica abono
      @i_debug                 = @i_debug,
	  @i_aplica_licitud        = @i_aplica_licitud,
      @o_secuencial_ing        = @w_secuencial_ing out,
      @o_secuencial_rpa        = @w_secuencial_rpa out
	     
      if @w_error <> 0 
         goto ERROR
		 
   end
	 
   -- Secuencial de ingreso de abono (Padre o Hijo)
   select @o_secuencial_ing_abono_grupal = @w_secuencial_ing
		     
   if @i_opcion = 2 -- Condiciones Abono Operaci�n Hija
   begin	  
      -- Actualizaci�n de referencia de secuencial Padre
	  update ca_abono
	  set ab_secuencial_ing_abono_grupal = @i_secuencial_ing_abono_grupal
	  where ab_operacion     = @w_operacionca_actual
	  and ab_secuencial_ing  = @w_secuencial_ing
	  
	  if @@error != 0
      begin
         select @w_error = 710002 -- Error en la actualizacion del registro
		 goto ERROR
      end
   end
   
   if @i_externo = 'S'
      commit tran
   
end

if @i_operacion = 'V'
begin

   if @i_externo = 'S'
      begin tran
	  
   if @i_opcion = 2 -- Validaciones de registros de abonos en base a pr�stamo Padre 
   begin
   
	  if exists (select 1 from ca_abono 
	             where ab_operacion    = @w_operacionca_actual
				 and ab_secuencial_ing = @i_secuencial_ing_abono_grupal
				 and ab_estado = 'ING')
      begin
	  
         if exists (select 1 from ca_operacion, ca_abono
		            where op_ref_grupal = @w_banco_actual
					and op_operacion                   = ab_operacion
					and ab_secuencial_ing_abono_grupal = @i_secuencial_ing_abono_grupal
					and ab_estado                      <> 'A')
         begin
            select @w_error = 725259 -- ERROR, APLICACI�N DE PAGO GRUPAL INCOMPLETO
		    goto ERROR
		 end
		 else
		 begin
		 
            select @w_monto_pago_padre = sum(abd_monto_mn) 
			from ca_abono, ca_abono_det
			where ab_operacion = @w_operacionca_actual
			and ab_operacion = abd_operacion
			and ab_secuencial_ing = abd_secuencial_ing
			and ab_secuencial_ing = @i_secuencial_ing_abono_grupal
		 
            select @w_monto_pago_hijos = sum(abd_monto_mn)
			from ca_operacion, ca_abono, ca_abono_det
			where op_ref_grupal                = @w_banco_actual
			and op_operacion                   = ab_operacion
			and op_operacion                   = abd_operacion
			and ab_secuencial_ing              = abd_secuencial_ing
			and ab_secuencial_ing_abono_grupal = @i_secuencial_ing_abono_grupal
			and abd_tipo                       = 'PAG'
			and ab_estado                      = 'A'
			
            if (isnull (@w_monto_pago_hijos, 0) = isnull(@w_monto_pago_padre , 0))
            begin
			
               -- Actualizaci�n de estado abono secuencial Padre
	           update ca_abono
	           set ab_estado = 'A'
	           where ab_operacion     = @w_operacionca_actual
	           and ab_secuencial_ing  = @i_secuencial_ing_abono_grupal
	           
	           if @@error != 0
               begin
                  select @w_error = 710002 -- Error en la actualizacion del registro
		          goto ERROR
               end	
			   
			   -- Registro de movimiento en Bancos
               exec @w_error = sp_func_bancos_cca
               @s_date            = @s_date,
               @s_user            = @s_user,
               @s_term            = @s_term,
               @s_ssn             = @s_ssn,
               @s_ofi             = @s_ofi, 
               @i_operacion       = 'M',
               @i_opcion          = 1,
               @i_banco           = @w_banco_actual,
               @i_secuencial_ing  = @i_secuencial_ing_abono_grupal
			   
               if @w_error <> 0
                  goto ERROR	
			      
			end
            else			
			begin
              select @w_error = 725260 -- ERROR, REGISTRO DE PAGO GRUPAL INCORRECTO, POR FAVOR REVISE LAS CONDICIONES DE LOS ABONOS
		      goto ERROR	
			end

		 end
      end
      else
      begin
         select @w_error = 725258 -- ERROR, ABONO GRUPAL NO EXISTE O NO HA SIDO VALIDADO
		 goto ERROR
      end      
	  
   end
   
   if @i_externo = 'S'
      commit tran
end

if @i_operacion = 'X' -- Operaciones varias
begin

   if @i_externo = 'S'
      begin tran
	  
   if @i_opcion = 1 -- Generar secuencial pr�stamo [Uso interno, no pagos]
   begin
      exec @o_secuencial_interno = sp_gen_sec
      @i_operacion      = @w_operacionca_actual
   end
   
   if @i_opcion = 2 -- LLenar tabla de condiciones del pago Grupal
   begin
   
      if object_id ('dbo.#ops_montos_pag_grp') is not null
         drop table dbo.#ops_montos_pag_grp
      
      select ltrim(rtrim(substring(value,1,charindex('|', value)-1))) as Operacion, 
             convert(money, ltrim(rtrim(substring(value, charindex('|', value)+1, len(value))))) as Monto
             into #ops_montos_pag_grp 
      from string_split(@i_operaciones_montos,';')
	  
      insert into ca_abono_grupal_tmp
	  select  getdate(),     @s_user,         @s_term,   @s_sesn,               @s_ssn,    
              @i_fecha_pago, @i_banco_grupal, Operacion, @i_secuencial_interno, @i_forma_pago, 
              Monto
	  from #ops_montos_pag_grp 
	  
      if @@error <> 0
      begin
         select @w_error = 710001 -- Error en insercion del registro
         goto ERROR
      end
   
   end
   
   if @i_externo = 'S'
      commit tran
   
end
 
return 0

ERROR:

if @i_externo = 'S'
begin 

   /*while @@TRANCOUNT > 0 */
      rollback tran
   
   exec cobis..sp_cerror
   @t_debug = 'N',    
   @t_file  = null,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error
  
end

return @w_error
go
