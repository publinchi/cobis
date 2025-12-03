/************************************************************************/
/*  Archivo:              sp_interfaz_pago_ws_enl.sp                    */
/*  Stored procedure:     sp_interfaz_pago_ws_enl                       */
/*  Base de datos:        cob_cartera                                 */
/*  Producto:             cartera                                       */
/*  Disenado por:         William Lopez                                 */
/*  Fecha de escritura:   07/Dic/2022                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCORP.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCORP para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  sp cascara para servicio rest de consulta y pago de operaciones     */
/*  de cartera                                                          */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  07/Dic/2022   WLO             Emision Inicial                       */
/*  20/Dic/2022   KDR             S749257 Param fuera linea y fecha pago*/
/*  19/Dic/2022   GFP             S717210 Se cambia de base             */
/*  12/Jul/2023   GFP             S846539 Omitir caracteres de numero de*/
/*                                la operación                          */
/*  09/Ago/2023   GFP             Se incluye parametros de facturación  */
/*  29/Ago/2023   GFP             Coreccion de num de caracteres en op  */
/************************************************************************/ 
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_interfaz_pago_ws_enl' and type = 'P')
    drop procedure sp_interfaz_pago_ws_enl
go

create procedure sp_interfaz_pago_ws_enl
(
   @s_ssn                 int           = null,
   @s_sesn                int           = null,
   @s_ofi                 smallint      = null,
   @s_rol                 smallint      = null,
   @s_user                login         = null,
   @s_date                datetime      = null,
   @s_term                descripcion   = null,
   @t_debug               char(1)       = 'N',
   @t_file                varchar(10)   = null,
   @t_from                varchar(32)   = null,
   @s_srv                 varchar(30)   = null,
   @s_lsrv                varchar(30)   = null,
   @t_trn                 int           = null,
   @s_format_date         int           = null,
   @s_ssn_branch          int           = null,
   @i_canal               catalogo      = '3' ,
   @i_aplica_en_linea     char(1)       = 'S' ,
   @i_operacion           char(1)       = null,--Q: Consulta saldo pago, P: Procesar pago
   @i_idcolector          int           = null,--Codigo de Banco o colector en Bancos
   @i_numcuentacolector   varchar(30)   = null,--Numero de Cuenta en Bancos
   @i_idreferencia        varchar(30)   = null,--Numero de referencia (Boleta)
   @i_reference           varchar(30)   = null,--Numero de operacion de Cartera - op_banco
   @i_amounttopay         money         = null,--Monto a pagar
   @i_fuera_linea         char(1)       = 'N',
   @i_fecha_pago          datetime      = null,
   @o_amounttopay         money         = null out,
   @o_reference           varchar(30)   = null out,
   @o_status              varchar(255)  = null out,
   -- Parámetros factura electrónica
   @o_guid               varchar(36)    = null out,
   @o_fecha_registro     varchar(10)    = null out,
   @o_ssn                int            = null out,
   @o_orquestador_fact   char(1)        = null out
)
as 
declare
   @w_sp_name           varchar(65),
   @w_return            int,
   @w_error             int,
   @w_banco             varchar(24),
   @w_amounttopay       money,
   @w_reference         varchar(30),
   @w_status            varchar(255)

select @w_sp_name         = 'sp_interfaz_pago_ws_enl',
       @w_error           = 0,
       @w_return          = 0,
       @w_amounttopay     = null,
       @w_reference       = null,
       @w_status          = ''

--Validación de número de operación con 11 caracteres
if (LEN(@i_reference) > 11)
   select @i_reference = SUBSTRING(@i_reference, LEN(@i_reference)-10,11)

--Validaciones
if ((@i_operacion <> 'Q') and (@i_operacion <> 'P'))
begin
   select @w_return = 2110173 --Debe enviar una operacion valida
   goto ERROR
end

if (@i_operacion is null) or (@i_idcolector is null) or (@i_idreferencia is null) or (@i_reference is null) or (@i_amounttopay is null) --campos obligatorios
begin
   select @w_return = 70125 --CAMPO REQUERIDO ESTA CON VALOR NULO
   goto ERROR
end

if (@i_operacion = 'P' ) and (@i_idcolector is null or @i_numcuentacolector is null) --campos obligatorios
begin
   select @w_return = 70125 --CAMPO REQUERIDO ESTA CON VALOR NULO
   goto ERROR
end

if (@i_amounttopay = 0 and @i_operacion = 'P')
begin
   select @w_return = 70182 --ERROR: EL MONTO DE PAGO NO ES VALIDO.
   goto ERROR
end

if (@i_amounttopay < 0 and @i_operacion = 'P')
begin
   select @w_return = 70185 --ERROR: EL MONTO DE PAGO DEBE SER POSITIVO.
   goto ERROR
end

if (@i_fecha_pago is null and @i_operacion = 'P')
begin
   select @w_return = 725251 -- Error, no se ha proporcionado una fecha de pago
   goto ERROR
end

--ejecucion de sp
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
   @i_canal             = @i_canal,
   @i_aplica_en_linea   = @i_aplica_en_linea,   
   @i_operacion         = @i_operacion,        --Q: Consulta saldo pago, P: Procesar pago
   @i_idcolector        = @i_idcolector,       --Codigo de Banco o colector en Bancos
   @i_numcuentacolector = @i_numcuentacolector,--Numero de Cuenta en Bancos
   @i_idreferencia      = @i_idreferencia,     --Numero de referencia (Boleta)
   @i_reference         = @i_reference,        --Numero de operacion de Cartera - op_banco
   @i_amounttopay       = @i_amounttopay,      --Monto a pagar
   @i_fuera_linea       = @i_fuera_linea,
   @i_fecha_pago        = @i_fecha_pago,
   @o_amounttopay       = @w_amounttopay       out,
   @o_reference         = @w_reference         out,
   @o_guid              = @o_guid              out,
   @o_fecha_registro    = @o_fecha_registro    out,
   @o_ssn               = @o_ssn               out,
   @o_orquestador_fact  = @o_orquestador_fact  out

if @w_return <> 0
begin
   goto SALIR
end

if (@i_operacion = 'Q' and @w_return = 0 and @w_reference is not null)
begin
      select @o_amounttopay = @w_amounttopay, --amountToPay
             @o_reference   = @w_reference    --reference     
end

if (@i_operacion = 'P' and @w_return = 0 and @w_reference is not null)
begin

   select @w_status = 'PAGADO'
   
   select @o_reference = @w_reference, --reference
          @o_status    = @w_status     --status

end

SALIR:
return @w_return

ERROR:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_return
   return @w_return
go
