/********************************************************************/
/*   NOMBRE LOGICO:      pago_grupal_orquestador.sp                 */
/*   NOMBRE FISICO:      sp_pago_grupal_orquestador                 */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Kevin Rodríguez                            */
/*   FECHA DE ESCRITURA: Febrero 2023                               */
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
/*   Programa que orquesta el proceso de pago grupal de acuerdo al  */ 
/*   canal                                                          */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  03-Feb-2023    K. Rodriguez     Emision Inicial                 */
/*  28/07/2023     G. Fernandez     S857741 Parametros de licitud   */
/*  15-Sep-2023    K. Rodriguez     R215360 Ajuste val. fecha valor */
/*                                  Operaciones hijas               */
/*  29/Sep/2023    K. Rodríguez     R216294 Valid. fecha de pago ATX*/
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_grupal_orquestador')
   drop proc sp_pago_grupal_orquestador
go

create proc sp_pago_grupal_orquestador
@s_user                   login,
@s_date                   datetime,
@s_term                   varchar(30),
@s_ofi                    smallint,
@s_ssn                    int,
@s_sesn                   int,
@s_srv                    varchar(30) = null,
@t_timeout                int         = null,
-- Parametros para licitud de fondos
@s_ssn_branch           int           = null,
@s_lsrv                 varchar(30)   = null,
@s_rol                  smallint      = null,
@s_org                  char(1)       = null,
@t_ssn_corr             int           = null,
@t_debug                char(1)       = 'N',
@t_file                 varchar(20)   = null,
@t_from                 descripcion   = null,
@t_trn                  int           = null,
-- Fin de parametros para licitud de fondos
@i_canal                  char(1),            -- 1: CARTERA, 2: BATCH, 3: SERVICIO WEB(BCOR), 4: ATX
@i_banco_grupal           cuenta,
@i_monto_grupal           money,
@i_secuencial_interno     int,
@i_moneda                 int,
@i_cod_banco              int         = null,
@i_cta_banco              cuenta      = '',         
@i_ref_pago_beneficiario  varchar(50) = null, -- N�mero de referencia/boleta (En tipo de pago BCOR o MOEL) o beneficiario   
@i_tipo_reduccion         char(1)     = null,
@i_tipo_cobro             char(1)     = null,
@i_retencion              tinyint     = null,
@i_cuota_completa         char(1)     = null,
@i_tipo_aplicacion        char(1)     = null,
@i_calcula_devolucion     char(1)     = null,
@i_pago_interfaz          char(1)     = 'N',
@i_id_referencia_inter    varchar(30) = null,
@i_descripcion            varchar(52) = '', 
@i_ejecutar               char(1)     = 'S',
@i_externo                char(1)     = 'N',
@i_debug                  char(1)     = 'N',
@i_aplica_licitud         char        = 'N',   --GFP Aplica licitud de fondos,
@o_secuencial_ing_grupal  int         = null out,
-- Parametros para licitud de fondos
@o_consep                 char(1)     = null out,
@o_ssn                    int         = null out,
@o_monto                  money       = null out,
-- Parametros para teller(ATX)
@o_monto_cap              money       = null out,
@o_monto_int              money       = null out,
@o_monto_imo              money       = null out,
@o_monto_otr              money       = null out,
@o_saldo_ant_capital      money       = null out,
@o_saldo_act_capital      money       = null out,
@o_saldo_act_interes      money       = null out,
-- Par�metros factura electr�nica
@o_guid                   varchar(36) = null out,
@o_fecha_registro         varchar(10) = null out,
@o_ssn_fact               int         = null out,
@o_orquestador_fact       char(1)     = null out

          
as
declare 
@w_sp_name               descripcion,
@w_error                 int,
@w_secuencial_ing        int,
@w_num_condicion_abonos  int,
@w_cont                  int,
@w_opcion                tinyint,
@w_banco                 cuenta,
@w_fpago                 varchar(10),
@w_monto                 money,
@w_tipo_op               char(1),
@w_fecha_ing             datetime,
@w_banco_padre           cuenta,
@w_monto_sumarizado      money,
@w_operacionca_padre     int,
@w_monto_padre           money,
@w_fecha_ing_padre       datetime,
@w_forma_pago            varchar(10),
@w_secuencial_ing_grupal int,
@w_retencion             tinyint,
@w_aplica_licitud        char(1),
@w_consep                char(1),
@w_ssn                   int,    
@w_monto_lic             money,   -- Monto(Licitud de fondos),
@w_efectivo_mn           money,   -- Valor de monto efectivo (canal 4 ATX)
@w_chq_mn                money,   -- Valor de monto en cheque (canal 4 ATX)
@w_fpago_general         varchar(10),
@w_categoria_pago        catalogo,
@w_saldo_anterior        money


-- Establecimiento de variables locales iniciales
select @w_sp_name   = 'sp_pago_grupal_orquestador',
       @w_error     = 0,
	   @w_retencion = @i_retencion 

if @t_ssn_corr is null
   select @t_ssn_corr = @s_ssn_branch
   
-- Datos de la operaci�n
select @w_operacionca_padre = op_operacion
from ca_operacion
where op_banco = @i_banco_grupal

if @@rowcount = 0
begin
   select @w_error = 701013 -- No existe operaci�n activa de cartera
   goto ERROR  
end

-- Saldo grupal antes del Pago
exec @w_error = sp_pago_grupal_consulta_montos
@i_canal          = '1', -- Cartera
@i_banco          = @i_banco_grupal, 
@i_operacion      = 'R',
@o_total_liquidar = @w_saldo_anterior out

if @w_error <> 0
begin
   select @w_error = @w_error
   goto ERROR
end

-- Validaciones y requisitos para canales
if @i_canal = 4 -- ATX
begin

   -- Validar que las operaciones hijas dentro del pago grupal esten al día
   if exists (select 1 from ca_operacion with (nolock), ca_abono_grupal_tmp with (nolock)
              where op_ref_grupal = @i_banco_grupal 
			  and op_banco = agt_banco_hijo
		      and op_fecha_ult_proceso <> @s_date
		      and op_estado not in (0,99,3,6)
			  and agt_secuencial = @i_secuencial_interno
			  and agt_monto > 0)
   begin
      select @w_error = 725305 -- Se encontraron operaciones con fecha valor menor a la fecha proceso. Favor validar con Back Office de Cartera.
      goto ERROR
   end

   -- Saldo de capital antes del abono
   select @o_saldo_ant_capital = sum(am_acumulado + am_gracia - am_pagado)
   from ca_operacion with (nolock), ca_amortizacion, ca_rubro_op
   where op_ref_grupal = @i_banco_grupal
   and   am_operacion  = op_operacion
   and   am_operacion  = ro_operacion
   and   am_concepto   = ro_concepto
   and   ro_tipo_rubro = 'C'
		   
   -- Identificacion si aplica licitud
   if @s_ssn_branch is null
      select @w_aplica_licitud = 'N'
   else
      select @w_aplica_licitud = 'S'
	  
   select @w_fpago_general = agt_fpago
   from ca_abono_grupal_tmp 
   where agt_banco_padre = @i_banco_grupal
   and agt_secuencial    = @i_secuencial_interno

   select @w_categoria_pago = cp_categoria 
   from ca_producto
   where cp_producto = @w_fpago_general
   and cp_moneda     = @i_moneda
	  
   if isnull(@w_categoria_pago, '') not in ('EFEC', 'CHBC')
   begin
      select @w_error = 725282 -- Error, no existe forma de pago o la forma de pago no es admitida para Teller
      goto ERROR
   end
	  
   if @w_categoria_pago = 'EFEC'
   begin
      select @w_efectivo_mn = @i_monto_grupal,
	         @w_retencion   = 0
   end	  
	  
   if @w_categoria_pago = 'CHBC'	
      select @w_chq_mn    = @i_monto_grupal,
	         @w_retencion = null             -- Cheque debe tomar la retenci�n parametrizada en la forma de pago.
	  
end
if @i_canal <> 4
begin
   select @w_aplica_licitud = @i_aplica_licitud
end

-- Validaci�n de las condiciones de los abonos hijos sean correctas.
select @w_fecha_ing = agt_fecha_ing,
	   @w_fpago     = agt_fpago
from ca_abono_grupal_tmp
where agt_banco_padre = @i_banco_grupal
and agt_secuencial    = @i_secuencial_interno
group by agt_fecha_ing, agt_fpago

if @@rowcount <> 1
begin
   select @w_error = 725257 -- ERROR, TABLA TEMPORAL DE SOLICITD DE PAGO GRUPAL VAC�A O CON INCONSISTENCIAS
   goto ERROR
end

	  
if exists (select 1 from ca_operacion with (nolock), ca_abono_grupal_tmp with (nolock)
           where op_ref_grupal = @i_banco_grupal
		   and op_banco = agt_banco_hijo
		   and op_fecha_ult_proceso <> @w_fecha_ing
		   and op_estado not in (0,99,3,6)
		   and agt_secuencial = @i_secuencial_interno
		   and agt_monto > 0)	   
begin
   select @w_error = 725286 -- ERROR, EXISTE UNA O VARIAS OPERACIONES CON FECHA VALOR
   goto ERROR
end

if @i_externo = 'S'
   begin tran

-- Creaci�n Tabla temporal
select agt_banco_hijo, agt_fpago, agt_monto, agt_fecha_ing, '' as 'agt_tipo' 
into #pagos_tmp 
from ca_abono_grupal_tmp where 1=2  

-- Sumatoria de montos a abonar de las operaciones Hijas
select @w_monto_sumarizado = sum(isnull(agt_monto, 0))
from ca_abono_grupal_tmp
where agt_banco_padre = @i_banco_grupal
and agt_secuencial    = @i_secuencial_interno

if @w_monto_sumarizado <> @i_monto_grupal or @w_monto_sumarizado <= 0
begin
   select @w_error = 725267 -- ERROR, EXISTE INCONSISTENCIA EN EL MONTO DEL ABONO GRUPAL
   goto ERROR
end
	   
-- Registros en tabla temporal de solicitud de pago grupal
insert into #pagos_tmp
select agt_banco_padre, agt_fpago, sum(agt_monto), agt_fecha_ing, 'G'
from ca_abono_grupal_tmp  
where agt_banco_padre = @i_banco_grupal
and agt_secuencial    = @i_secuencial_interno
group by agt_banco_padre, agt_fpago, agt_fecha_ing
union
select agt_banco_hijo, agt_fpago, agt_monto,agt_fecha_ing , 'H' 
from ca_abono_grupal_tmp 
where agt_banco_padre = @i_banco_grupal
and agt_secuencial    = @i_secuencial_interno
and agt_monto > 0

if @@rowcount = 0
begin
   select @w_error = 725257 -- ERROR, TABLA TEMPORAL DE SOLICITD DE PAGO GRUPAL VAC�A O CON INCOSISTENCIAS
   goto ERROR
end

select @w_cont = count(1) from #pagos_tmp

-- (1)REGISTRO Y/O APLICACI�N DE ABONOS (PADRE E HIJOS)  
while @w_cont > 0
begin

   -- Datos del abono
   select top 1
      @w_banco     = agt_banco_hijo,
      @w_fpago     = agt_fpago,
      @w_monto     = agt_monto,
	  @w_tipo_op   = agt_tipo,
	  @w_fecha_ing = agt_fecha_ing
   from #pagos_tmp
   
   select @w_opcion = case @w_tipo_op when 'G' then 1 when 'H' then 2 end
     
   -- Ingreso de abono Padre, registro y aplicaci�n abonos hijos
   exec @w_error = sp_pago_grupal_reg_val_abono
   @s_srv                         = @s_srv, 
   @s_user                        = @s_user,
   @s_term                        = @s_term,
   @s_ofi                         = @s_ofi, 
   @s_ssn                         = @s_ssn, 
   @s_date                        = @s_date,
   @s_sesn                        = @s_sesn,
   -- Parametros solo utilizados para licitud de fondos
   @s_ssn_branch                  = @s_ssn_branch,
   @s_lsrv                        = @s_lsrv,
   @s_rol                         = @s_rol,
   @s_org                         = @s_org,
   @t_ssn_corr                    = @t_ssn_corr,
   @t_debug                       = @t_debug,
   @t_file                        = @t_file,
   @t_from                        = @t_from,
   @t_trn                         = @t_trn,
   -- Fin de parametros solo utilizados para licitud de fondos  
   @i_operacion                   = 'I', 
   @i_opcion                      = @w_opcion, 
   @i_externo                     = 'N', 
   @i_ejecutar                    = @i_ejecutar,
   @i_banco_grupal                = @w_banco, 
   @i_monto_grupal                = @w_monto,
   @i_banco_hija                  = @w_banco, 
   @i_monto_hija                  = @w_monto,
   @i_secuencial_ing_abono_grupal = @w_secuencial_ing_grupal,
   @i_forma_pago                  = @w_fpago,
   @i_fecha_pago                  = @w_fecha_ing, 
   @i_moneda                      = @i_moneda,
   @i_cod_banco                   = @i_cod_banco,          
   @i_cta_banco                   = @i_cta_banco,
   @i_ref_pago_beneficiario       = @i_ref_pago_beneficiario, 
   @i_tipo_reduccion              = @i_tipo_reduccion,        
   @i_tipo_cobro                  = @i_tipo_cobro,
   @i_retencion                   = @w_retencion,   
   @i_cuota_completa              = @i_cuota_completa,      
   @i_tipo_aplicacion             = @i_tipo_aplicacion,      
   @i_calcula_devolucion          = @i_calcula_devolucion,   
   @i_pago_interfaz               = @i_pago_interfaz,         
   @i_id_referencia_inter         = @i_id_referencia_inter,   
   @i_aplica_licitud              = @w_aplica_licitud,        
   @i_descripcion                 = @i_descripcion,   
   @i_debug                       = @i_debug,
   @i_canal                       = @i_canal,   
   @o_secuencial_ing_abono_grupal = @w_secuencial_ing out,
   -- Parametros solo utilizados para licitud de fondos
   @o_consep                      = @o_consep out,
   @o_ssn                         = @o_ssn out,
   @o_monto                       = @o_monto out
   
   if @w_error <> 0
      goto ERROR
	  
   if @w_tipo_op = 'G' 
      select @w_forma_pago      = @w_fpago,
	         @w_banco_padre     = @w_banco, 
			 @w_monto_padre     = @w_monto,
			 @w_fecha_ing_padre = @w_fecha_ing,
	         @w_secuencial_ing_grupal =  @w_secuencial_ing
   else
   begin
      if @o_consep = 'S'
      select @w_consep   = @o_consep,
	         @w_ssn      = @o_ssn,   
	         @w_monto_lic = @o_monto 
   end 
   
   select @o_consep = null,
          @o_ssn    = null,
          @o_monto  = null
   
   delete #pagos_tmp where agt_banco_hijo = @w_banco
   set @w_cont = (select count(1) from #pagos_tmp)

end

drop table #pagos_tmp

select @o_secuencial_ing_grupal = @w_secuencial_ing_grupal

-- Valores de retorno para licitud de fondos.
select @o_consep = isnull(@w_consep, 'N'),
       @o_ssn    = @w_ssn,   
       @o_monto  = @w_monto_lic 

-- Verificar Ingreso de abono Padre y aplicaci�n de abonos Hijos
-- Generar Movimiento en bancos si es pago de categor�a BCOR
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
@i_banco_grupal                = @w_banco_padre, 
@i_monto_grupal                = @w_monto_padre, 
@i_forma_pago                  = @w_forma_pago,
@i_secuencial_ing_abono_grupal = @o_secuencial_ing_grupal, 
@i_fecha_pago                  = @w_fecha_ing_padre, 
@i_moneda                      = @i_moneda, 
@i_debug                       = 'N'

if @w_error <> 0
   goto ERROR
   
--  Tanqueo de datos para factura electr�nica del Pago
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
@i_ope_banco        = @w_banco_padre,
@i_secuencial_ing   = @o_secuencial_ing_grupal,
@i_tipo_operacion   = 'G', -- Grupal Padre
@i_saldo_anterior   = @w_saldo_anterior,
@i_fecha_ing        = @w_fecha_ing_padre,
@i_externo          = 'N',
@i_tipo_tran        = 'PAG',
@i_operacion        = 'I',
@o_guid             = @o_guid             out,
@o_fecha_registro   = @o_fecha_registro   out,
@o_ssn              = @o_ssn_fact         out,
@o_orquestador_fact = @o_orquestador_fact out

if @w_error <> 0
   goto ERROR
   
if @i_canal = 4 -- ATX
begin

   -- Saldo de capital despu�s del abono (actual)
   select @o_saldo_act_capital = sum(am_acumulado + am_gracia - am_pagado)
   from ca_operacion with (nolock), ca_amortizacion, ca_rubro_op
   where op_ref_grupal = @i_banco_grupal
   and   am_operacion  = op_operacion
   and   am_operacion  = ro_operacion
   and   am_concepto   = ro_concepto
   and   ro_tipo_rubro = 'C'
   
   -- Saldo de inter�s despu�s del abono (actual)
   select @o_saldo_act_interes = sum(am_acumulado + am_gracia - am_pagado)
   from ca_operacion with (nolock), ca_amortizacion, ca_rubro_op
   where op_ref_grupal = @i_banco_grupal
   and   am_operacion  = op_operacion
   and   am_operacion  = ro_operacion
   and   am_concepto   = ro_concepto
   and   ro_tipo_rubro = 'I'

   -- Consultar datos del pago para la boleta de impresi�n
   exec sp_consulta_abono_atx
   @s_sesn                    = @s_sesn,
   @s_ssn                     = @s_ssn,
   @s_user                    = @s_user,
   @s_date                    = @s_date,
   @s_ofi                     = @s_ofi,
   @s_term                    = @s_term,
   @s_srv                     = @s_srv,
   @i_secuencial_ing          = @w_secuencial_ing_grupal, -- Secuencial que identifica los abonos hijos (ab_secuencial_ing_abono_grupal)
   @i_operacionca             = @w_operacionca_padre,     -- N�mero de Operaci�n Padre.
   @i_en_linea                = 'S',
   @i_total                   = @i_monto_grupal,          -- Monto total (Sumatoria de montos de OPs. hijas)
   @o_monto_cap               = @o_monto_cap     out,
   @o_monto_int               = @o_monto_int     out,
   @o_monto_imo               = @o_monto_imo     out,
   @o_monto_otr               = @o_monto_otr     out
   
   if @@error != 0
      goto ERROR

   insert into ca_secuencial_atx (
   sa_operacion ,           sa_ssn_corr ,     sa_producto,                   sa_secuencial_cca,
   sa_secuencial_ssn,       sa_oficina,       sa_fecha_ing,                  sa_fecha_real,
   sa_estado,               sa_ejecutar,      sa_valor_efe,                  sa_valor_cheq,
   sa_error)
   values(@i_banco_grupal,  @t_ssn_corr,      @w_forma_pago,                 isnull(@o_secuencial_ing_grupal, 0),
   isnull(@s_ssn,0),        isnull(@s_ofi,0), isnull(@w_fecha_ing_padre,''), getdate(),
   'A',                     @i_ejecutar,      isnull(@w_efectivo_mn,0),      isnull(@w_chq_mn,0),  
   0)
   
   if @@error <> 0
   begin
      select @w_error = 710001 -- Error en insercion del registro
      goto ERROR
   end
   
end
   
if @i_externo = 'S'
   commit tran
   
return 0

ERROR:

if object_id ('dbo.#pagos_tmp') is not null
   drop table #pagos_tmp

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

if @i_canal = 4
begin

   if @o_secuencial_ing_grupal is null or exists (select 1 from ca_secuencial_atx 
                                                  where sa_operacion = @i_banco_grupal 
												  and sa_secuencial_cca = @o_secuencial_ing_grupal)
   begin
      select @o_secuencial_ing_grupal = isnull(min(sa_secuencial_cca), 0) -1
	  from ca_secuencial_atx with (nolock)
	  where sa_operacion = @i_banco_grupal
   end     
	
   begin tran

   insert into ca_secuencial_atx(
   sa_operacion ,          sa_ssn_corr ,     sa_producto,                   sa_secuencial_cca,
   sa_secuencial_ssn,      sa_oficina,       sa_fecha_ing,                  sa_fecha_real,
   sa_estado,              sa_ejecutar,      sa_valor_efe,                  sa_valor_cheq,
   sa_error)                                                                
   values(@i_banco_grupal, @t_ssn_corr,      @w_forma_pago,                 isnull(@o_secuencial_ing_grupal, 0),
   isnull(@s_ssn,0),       isnull(@s_ofi,0), isnull(@w_fecha_ing_padre,''), getdate(),
   'X',                    @i_ejecutar,      isnull(@w_efectivo_mn,0),      isnull(@w_chq_mn,0),
   @w_error)

   commit tran

end

return @w_error
go
