/************************************************************************/
/*   NOMBRE LOGICO:      ingabono.sp                                    */
/*   NOMBRE FISICO:      sp_ing_abono                                   */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       R. Garces                                      */
/*   FECHA DE ESCRITURA: Feb. 1995                                      */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la Rep�blica de Espa�a y las             */
/*   correspondientes de la Uni�n Europea. Su copia, reproducci�n,      */
/*   alteraci�n en cualquier sentido, ingenier�a reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causar� violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la informaci�n      */
/*   tratada; y por lo tanto, derivar� en acciones legales civiles      */
/*   y penales en contra del infractor seg�n corresponda.               */
/************************************************************************/
/*                     PROPOSITO                                        */
/*   Ingreso de abonos                                                  */ 
/*   S: Seleccion de negociacion de abonos automaticos                  */
/*   Q: Consulta de negociacion de abonos automaticos                   */
/*   I: Insercion de abonos                                             */
/*   U: Actualizacion de negociacion de abonos automaticos              */
/*   D: Eliminacion de negociacion de abonos automaticos                */
/************************************************************************/
/*                     MODIFICACIONES                                   */
/*   FECHA        AUTOR          RAZON                                  */ 
/* 22/04/2022    G. Fernandez  Se corrige cierre de transaccion en error*/
/* 18/07/2022    G. Fernandez  Cambio de parametro id_referencia_inter  */
/*                             de int a varchar                         */
/* 01/02/2023    K. Rodriguez  S771317 Bandera para pago grupal         */
/* 28/07/2023    G. Fernandez  S857741 Parametros de licitud            */
/************************************************************************/

use cob_cartera
go



if exists (select 1 from sysobjects where name = 'sp_ing_abono')
   drop proc sp_ing_abono
go

create proc sp_ing_abono
   @s_user                 login = null,
   @s_term                 varchar(30)  = null,
   @s_srv                  varchar(30)  = null,  --LALG 21/09/2001
   @s_date                 datetime     = null,
   @s_sesn                 int          = null,
   @s_ssn                  int          = null,
   @s_ofi                  smallint     = null,
   @s_rol		 smallint       = null,  --Req 00212 25/05/2011	
   @s_ssn_branch           int          = null,
   @t_trn                  INT          = NULL, --LPO CDIG Cambio de Servicios a Blis      
   @i_accion               char(1),
   @i_banco                cuenta,
   @i_secuencial           int          = NULL,
   @i_tipo                 char(3)      = NULL,
   @i_fecha_vig            datetime     = NULL,
   @i_ejecutar             char(1)      = 'N',
   @i_retencion            smallint     = NULL,
   @i_cuota_completa       char(1)      = NULL,   
   @i_anticipado           char(1)      = NULL,   
   @i_tipo_reduccion       char(1)      = NULL, 
   @i_proyectado           char(1)      = NULL,
   @i_tipo_aplicacion      char(1)      = NULL,
   @i_prioridades          varchar(255) = NULL,
   @i_en_linea             char(1)      = 'S',
   @i_tasa_prepago         float        =  0.0,
   @i_verifica_tasas       char(1)      = null,
   @i_dividendo            smallint     = 0,
   @i_calcula_devolucion   char(1)      = NULL,
   @i_no_cheque            int          = NULL,     
   @i_cuenta               cuenta       = NULL,  
   @i_mon                  smallint     = NULL,
   @i_cod_banco            catalogo     = NULL,
   @i_beneficiario         varchar(50)  = NULL,
   @i_inscripcion          int          = null, 
   @i_carga                int          = null, 
   @i_cancela              char(1)      = NULL,
   @i_renovacion           char(1)      = NULL,
   @i_solo_capital         char(1)      = 'N',
   @i_valor_multa          money        = 0,
   @i_pago_interfaz        char(1)      = 'N',
   @i_id_referencia_inter  varchar(30)  = null,   --GFP 18/07/2022
   @i_canal_inter          int          = 0,
   @i_forma_pago           varchar(10)  = null,
   @i_reg_pago_grupal_padre char(1)     = 'N',   --KDR Bandera Inserci�n en estructuras de abono del pago pr�stamo Padre (no aplicaci�n de abono)
   @i_reg_pago_grupal_hijo char(1)      = 'N',   --KDR Bandera de abono de operaci�n Hija desde un pago grupal
   @i_debug                char(1)      = 'N',
   @i_aplica_licitud       char         = 'N',   --GFP Aplica licitud de fondos,
   @o_secuencial_ing       int          = NULL out,
   @o_secuencial_rpa       int          = null out,
   @o_error                int          = null out,
   -- Par�metros salida factura electr�nica
   @o_guid                 varchar(36)  = null out,
   @o_fecha_registro       varchar(10)  = null out,
   @o_ssn                  int          = null out,
   @o_orquestador_fact     char(1)      = null out
   
as
declare 
   @w_sp_name      descripcion,
   @w_return      int,
   @w_error       int,
   @w_tipo        char(1),
   @w_operacionca int,
   @w_acepta_pagos char


select @w_sp_name = 'sp_ing_abono'

select @w_operacionca = op_operacion
from ca_operacion
where op_banco = @i_banco

 --Valicaci�n si acepta pagos
    if exists (select 1 from ca_operacion_datos_adicionales where oda_operacion = @w_operacionca and oda_aceptar_pagos = 'N')
    begin
    	select @w_error = 725094,
		       @o_error = @w_error
        goto ERROR
    end	

begin tran

--- LLAMADA AL SP INTERNO DE ABONO
exec @w_return = sp_ing_abono_int
@s_user                 = @s_user,
@s_term                 = @s_term,
@s_date                 = @s_date,
@s_sesn                 = @s_sesn,
@s_ssn                  = @s_ssn,
@s_srv                  = @s_srv,   
@s_ofi                  = @s_ofi,
@s_rol		            = @s_rol,
@s_ssn_branch           = @s_ssn_branch,
@i_accion               = @i_accion,
@i_banco                = @i_banco,
@i_secuencial           = @i_secuencial,
@i_tipo                 = @i_tipo,
@i_fecha_vig            = @i_fecha_vig,
@i_ejecutar             = @i_ejecutar,
@i_retencion            = @i_retencion,
@i_cuota_completa       = @i_cuota_completa,   
@i_anticipado           = @i_anticipado,   
@i_tipo_reduccion       = @i_tipo_reduccion, 
@i_proyectado           = @i_proyectado,
@i_tipo_aplicacion      = @i_tipo_aplicacion,
@i_prioridades          = @i_prioridades,
@i_en_linea             = @i_en_linea,
@i_tasa_prepago         = @i_tasa_prepago,
@i_verifica_tasas       = @i_verifica_tasas,
@i_dividendo            = @i_dividendo,
@i_calcula_devolucion   = @i_calcula_devolucion,
@i_no_cheque            = @i_no_cheque,   
@i_cuenta               = @i_cuenta,      
@i_mon                  = @i_mon,       
@i_beneficiario         = @i_beneficiario,
@i_cod_banco            = @i_cod_banco,
@i_cancela              = @i_cancela,
@i_renovacion           = @i_renovacion,
@i_solo_capital         = @i_solo_capital,
@i_valor_multa          = @i_valor_multa ,
@i_pago_interfaz        = @i_pago_interfaz,       -- JH  Valor S o N si el pago es por interfaz de pagos
@i_id_referencia_inter  = @i_id_referencia_inter, -- JH  Id de Referencia que se env�a desde la interfaz
@i_canal_inter          = @i_canal_inter,         -- JH  Valor del canal enviado desde la interfaz
@i_forma_pago           = @i_forma_pago,          -- JH  Concepto de pago enviado desde la interfaz
@i_reg_pago_grupal_padre= @i_reg_pago_grupal_padre,
@i_reg_pago_grupal_hijo = @i_reg_pago_grupal_hijo,
@i_debug                = @i_debug,
@i_aplica_licitud       = @i_aplica_licitud,
@o_secuencial_ing       = @o_secuencial_ing out,
@o_secuencial_rpa       = @o_secuencial_rpa   out,
@o_guid                 = @o_guid             out,
@o_fecha_registro       = @o_fecha_registro   out,
@o_ssn                  = @o_ssn              out,
@o_orquestador_fact     = @o_orquestador_fact out

if @w_return !=0 
begin
   --PRINT 'ingabono.sp Error saliendo de ingaboin.sp'
   select @w_error = @w_return,
          @o_error = @w_error
   goto ERROR
end 

select @w_tipo = op_tipo,
       @w_operacionca = op_operacion
from ca_operacion
where op_banco = @i_banco



commit tran


return 0

ERROR:
while @@trancount > 0 
    rollback tran
if @i_canal_inter <> 2
begin 
   exec cobis..sp_cerror
   @t_debug = 'N',    
   @t_file  = null,
   @t_from  = @w_sp_name,   
   @i_num   = @w_error
end
   return @w_error
go
