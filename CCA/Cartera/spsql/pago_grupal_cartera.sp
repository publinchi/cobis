/********************************************************************/
/*   NOMBRE LOGICO:      pago_grupal_cartera.sp                     */
/*   NOMBRE FISICO:      sp_pago_grupal_cartera                     */
/*   BASE DE DATOS:      cob_cartera                                */
/*   PRODUCTO:           Cartera                                    */
/*   DISENADO POR:       Kevin Rodríguez                            */
/*   FECHA DE ESCRITURA: Abril 2023                                 */
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
/*   Programa que realiza la transacci�n de pago grupal desde el    */ 
/*   canal cartera                                                  */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  17-Abr-2023    K. Rodr�guez  (S785507)Emision Inicial           */
/*  28/07/2023     G. Fernandez   S857741 Parametros de licitud     */
/********************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_grupal_cartera')
   drop proc sp_pago_grupal_cartera
go

create proc sp_pago_grupal_cartera
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
@i_moneda                 int,
@i_fecha_pago             datetime,
@i_forma_pago             varchar(10),
@i_operaciones_montos     varchar(2000),      -- N�mero de Operaciones hijas(op_banco) y sus montos identificadas por un separador
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
@w_secuencial_interno    int,
@w_operacionca_padre     varchar(24)


-- Establecimiento de variables locales iniciales
select @w_sp_name   = 'sp_pago_grupal_cartera',
       @w_error     = 0
   
-- Datos de la operaci�n
select @w_operacionca_padre = op_operacion
from ca_operacion
where op_banco = @i_banco_grupal

if @@rowcount = 0
begin
   select @w_error = 701013 -- No existe operaci�n activa de cartera
   goto ERROR  
end

if @i_externo = 'S'
   begin tran

-- 1. Generar Secuencial par uso interno de la tabla de condiciones de pago grupal (ca_pago_grupal_tmp)
exec @w_error = sp_pago_grupal_reg_val_abono
@s_user               = @s_user,      
@s_date               = @s_date,      
@s_term               = @s_term,      
@s_ofi                = @s_ofi,      
@s_ssn                = @s_ssn,      
@s_sesn               = @s_sesn,      
@s_srv                = @s_srv,      
@i_operacion          = 'X',
@i_opcion             = 1,
@i_externo            = 'N',
@i_banco_grupal       = @i_banco_grupal,
@i_canal              = 1,               -- 1: CARTERA
@o_secuencial_interno = @w_secuencial_interno out

if @w_error <> 0
   goto ERROR


-- 2. Ingresar condiciones a tabla de condiciones de pago grupal (ca_pago_grupal_tmp)
exec @w_error = sp_pago_grupal_reg_val_abono
@s_user               = @s_user,      
@s_date               = @s_date,      
@s_term               = @s_term,      
@s_ofi                = @s_ofi,      
@s_ssn                = @s_ssn,      
@s_sesn               = @s_sesn,      
@s_srv                = @s_srv,      
@i_operacion          = 'X',
@i_opcion             = 2,
@i_externo            = 'N',
@i_banco_grupal       = @i_banco_grupal,
@i_fecha_pago         = @i_fecha_pago, 
@i_forma_pago         = @i_forma_pago, 
@i_secuencial_interno = @w_secuencial_interno, 
@i_operaciones_montos = @i_operaciones_montos,
@i_canal              = 1                -- 1: CARTERA

if @w_error <> 0
   goto ERROR


-- 3. Aplicaci�n de pago grupal
exec @w_error = sp_pago_grupal_orquestador
@s_user                  = @s_user,
@s_date                  = @s_date,
@s_term                  = @s_term,
@s_ofi                   = @s_ofi,
@s_ssn                   = @s_ssn,
@s_sesn                  = @s_sesn,
@s_srv                   = @s_srv,
@t_timeout               = @t_timeout,
@s_ssn_branch            = @s_ssn_branch,
@s_lsrv                  = @s_lsrv,
@s_rol                   = @s_rol,
@s_org                   = @s_org,
@t_ssn_corr              = @t_ssn_corr,
@t_debug                 = @t_debug,
@t_file                  = @t_file,
@t_from                  = @t_from,
@t_trn                   = @t_trn,
@i_externo               = 'N',
@i_canal                 = 1,
@i_moneda                = @i_moneda,
@i_banco_grupal          = @i_banco_grupal,
@i_monto_grupal          = @i_monto_grupal,
@i_secuencial_interno    = @w_secuencial_interno,
@i_cod_banco             = @i_cod_banco,          
@i_cta_banco             = @i_cta_banco,
@i_ref_pago_beneficiario = @i_ref_pago_beneficiario,
@i_retencion             = @i_retencion,
@i_descripcion           = @i_descripcion,
@i_ejecutar              = @i_ejecutar,
@i_debug                 = @i_debug,
@i_aplica_licitud        = 'S',
@o_guid                  = @o_guid             out,
@o_fecha_registro        = @o_fecha_registro   out,
@o_ssn_fact              = @o_ssn_fact         out,
@o_orquestador_fact      = @o_orquestador_fact out
 
if @w_error <> 0
   goto ERROR


if @i_externo = 'S'
   commit tran
   
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
