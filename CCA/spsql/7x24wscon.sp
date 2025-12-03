/************************************************************************/
/*   NOMBRE LOGICO:      7x24wscon.sp                                   */
/*   NOMBRE FISICO:      sp_7x24_ws_cca_consulta                        */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Kevin Rodríguez                                */
/*   FECHA DE ESCRITURA: Enero 2023                                     */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*  Procedimiento encargado de consultar el valor a pagar de un prés-   */
/*  tamo indiviudal o grupal desde un servicio web.                     */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA       AUTOR           RAZON                                  */ 
/* 19/12/2022    K. Rodríguez    Versión Inicial                        */
/*                                                                      */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_7x24_ws_cca_consulta')
   drop proc sp_7x24_ws_cca_consulta
go
create proc sp_7x24_ws_cca_consulta
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
@i_operacion          char(1),                 -- Q: Consulta saldo pago, P: Procesar pago,
@i_codigo_colector    smallint,                -- Código de Banco en Bancos.
@i_numero_cuenta      varchar(30)  = null,     -- Número de cuenta en Bancos
@i_referencia         varchar(30),             -- Número de referencia [Boleta]
@i_banco              varchar(30),             -- Número de operación de Cartera [Número largo]
@i_monto              money,
@i_fuera_linea        char(1),                 -- Indica Si el producto Cartera no está disponible
@o_amounttopay        money         = null out,
@o_status             varchar(255)  = null out, 
@o_reference          varchar(30)   = null out

         
as declare
@w_return           int,
@w_error		    int,
@w_sp_name          varchar(64),

@w_fecha_cierre     datetime,
@w_amounttopay      money,
@w_reference        varchar(30)
   
-- Información inicial
select @w_sp_name = 'sp_7x24_ws_cca_consulta'

--Validaciones
if @i_operacion <> 'Q'
begin
   select @w_return = 725244 -- Error, el identificativo de operación no corresponde a una consulta
   goto ERROR
end

-- Fecha de cierre de Cartera
select @w_fecha_cierre = convert(varchar(10),fc_fecha_cierre,101)
from   cobis..ba_fecha_cierre with (nolock)
where  fc_producto = 7

if @w_fecha_cierre in (select fc_fecha_proceso from ca_7x24_fcontrol) -- or @i_fuera_linea = 'N'
begin

   -- Programa de consultas de saldos/proceso de pagos
   exec @w_return = cob_cartera..sp_interfaz_pago_enl
   @s_ssn               = @s_ssn,
   @s_sesn              = @s_sesn,
   @s_ofi               = @s_ofi,
   @s_rol               = @s_rol,
   @s_user              = @s_user,
   @s_date              = @s_date,
   @s_term              = @s_term,
   @t_debug             = @t_debug,     
   @t_file              = @t_file,
   @t_from              = @t_from,
   @s_srv               = @s_srv,
   @s_lsrv              = @s_lsrv,
   @t_trn               = @t_trn,
   @s_format_date       = @s_format_date,   
   @s_ssn_branch        = @s_ssn_branch,
   @i_canal             = 3,                   -- Servicio Web
   @i_aplica_en_linea   = 'S',                 -- Servicio web aplica en línea
   @i_operacion         = @i_operacion,        --Q: Consulta saldo pago, P: Procesar pago
   @i_idcolector        = @i_codigo_colector,  --Codigo de Banco o colector en Bancos
   @i_numcuentacolector = @i_numero_cuenta,    --Numero de Cuenta en Bancos
   @i_idreferencia      = @i_referencia,       --Numero de referencia (Boleta)
   @i_reference         = @i_banco,            --Numero de operacion de Cartera - op_banco
   @i_amounttopay       = @i_monto,            --Monto a pagar,
   @i_fecha_pago        = @w_fecha_cierre,
   @i_fuera_linea       = @i_fuera_linea,
   @o_amounttopay       = @w_amounttopay       out,
   @o_reference         = @w_reference         out
   
   if @w_return <> 0
   begin
      select @w_error = @w_return
	  goto SALIR
   end
   
   select @o_amounttopay = @w_amounttopay,
          @o_reference   = @w_reference

end
else
begin
   select @w_error = 725245 -- Lo sentimos, nos encontramos en procesos operativos, vuelva a intentar en unos minutos
   goto ERROR
end
	

return 0

SALIR:
return @w_error  

ERROR:

exec cobis..sp_cerror
@t_debug='N',    
@t_file=null,
@t_from=@w_sp_name,   
@i_num = @w_error

return @w_error    

go
