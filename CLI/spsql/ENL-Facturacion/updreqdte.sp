/* **************************************************************** */
/*   Archivo:          updreqdte.sp                                 */
/*   Stored procedure: sp_upd_requerimiento_DTE                     */
/*   Base de datos:    cob_externos                                 */
/*   Producto:         COBIS Externos                               */
/* **************************************************************** */
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
/*   y penales en contra del infractor según corresponda.".         */
/* **************************************************************** */
/*                            PROPOSITO                             */
/*   Este Stored Procedure permite actualizar el requerimiento con  */
/*   la respuesta enviada por ricoh al procesamiento de los archivos*/
/*   json: fe-ccf-v3, fe-fc-v1 y fe-nc-v3, anulacion_v2.            */      
/* **************************************************************** */
/*                         MODIFICACIONES                           */
/*   FECHA          AUTOR               RAZON                       */
/*   25-ABR-23      E.Carrion        Emision Inicial                */
/*   26-JUN-23      A.Quishpe        Se cambia a estado cobis G y E */
/*   29-ABR-24      A.Quishpe        Se aumenta longitud de sello re*/
/*   16-OCT-24      G. Chulde        RM 246721                      */
/* **************************************************************** */

use cob_externos
go

if exists (select * from sysobjects where id = object_id('sp_upd_requerimiento_DTE'))
   drop procedure sp_upd_requerimiento_DTE
go

create proc sp_upd_requerimiento_DTE (
    @s_ssn                int,
    @s_srv                varchar(30),
    @s_user               varchar(32),
    @s_term               varchar(32),
    @s_date               datetime,    
    @s_ofi                smallint,    
    @t_trn                int,    
    @i_version            tinyint      = null,
    @i_ambiente           char(2)      = null,
    @i_version_app        char(3)      = null,
    @i_estado             char(10),    
    @i_codigo_generacion  varchar(36)  = null,
    @i_sello_recibido     varchar(60)  = null,
    @i_fecha_proceso      varchar(20)  = null,
    @i_clasifica_msg      varchar(5)   = null,
    @i_codigo_msg         varchar(2)   = null,
    @i_descripcion_msg    varchar(150),
    @i_observaciones      varchar(1000) = null,
    @i_num_renvio         tinyint      = null,
	@i_num_impresion      tinyint      = null,
    @i_fecha_envio        datetime     = null,
    @i_cod_secuencial     int		   = null,
    @i_fecha_proc         datetime     = null	
)
as        

declare @w_sp_name            varchar(64),
        @w_cod_secuencial     int,
        @w_fecha_proc         datetime
        

-- Inicializo variables
SELECT @w_sp_name    = 'sp_upd_requerimiento_DTE'

-- Verificar codigos de transaccion
if @t_trn not in (172236)   
begin
   -- Transaccion no corresponde
   exec cobis..sp_cerror
      @t_from   = @w_sp_name,
      @i_num    = 190000
   return 190000
end

if @i_codigo_generacion is not null
begin
	SELECT @w_cod_secuencial = di_cod_secuencial, 
		   @w_fecha_proc     = di_fecha_proceso
	FROM ex_dte_identificacion
	WHERE di_cod_generacion  = @i_codigo_generacion
end
else
begin
	SELECT @w_cod_secuencial = @i_cod_secuencial, 
		   @w_fecha_proc     = @i_fecha_proc
		   
	SELECT @i_codigo_generacion = di_cod_generacion
	FROM ex_dte_identificacion
	WHERE di_cod_secuencial  = @i_cod_secuencial
end

if (@i_estado is not null and ltrim(rtrim(@i_estado)) = 'RECHAZADO')
    select @i_estado = 'E'
else if (ltrim(rtrim(@i_estado)) = 'PROCESADO')
    select @i_estado = 'G'

if @w_cod_secuencial is not null AND @w_fecha_proc is not null
BEGIN
    UPDATE  ex_dte_requerimiento
    SET dq_version              = @i_version,            
        dq_ambiente             = @i_ambiente,            
        dq_version_app          = @i_version_app,        
        dq_estado               = @i_estado,            
        dq_sello_recibido       = @i_sello_recibido,    
        dq_fecha_procesamiento  = @i_fecha_proceso,     
        dq_clasifica_msg        = @i_clasifica_msg,    
        dq_codigo_msg           = @i_codigo_msg,        
        dq_descripcion_msg      = @i_descripcion_msg,  
        dq_observaciones        = @i_observaciones,
        dq_num_reenvio          = isnull(@i_num_renvio, dq_num_reenvio),
        dq_fecha_envio          = isnull(@i_fecha_envio, dq_fecha_envio),
		dq_num_impresion        = isnull(@i_num_impresion + dq_num_impresion, dq_num_impresion )
    WHERE dq_ssn           = @w_cod_secuencial
      AND dq_fecha_proceso = @w_fecha_proc
	
	--Se inserta minuciosamente un registro de TS para posterior seguimiento y trasabilidad
    insert into cob_teller..re_tran_servicio_tel
	(
	ts_secuencial,     ts_cod_alterno, ts_tipo_transaccion, ts_terminal,       ts_origen,
	ts_correccion,     ts_filial,      ts_oficina,          ts_oficina_cta,    
	ts_tsfecha,        ts_hora,        ts_usuario,
	ts_observacion,    ts_estado,      ts_descripcion_ec
	)
	values
	(
	@s_ssn,             1,              172236,              @s_term,           'R',
	'N',                1,              @s_ofi,              @s_ofi,
	@s_date,            getdate(),      @s_user,
	@i_descripcion_msg, @i_estado,      @i_codigo_generacion
	)
	
END
ELSE
BEGIN
    exec cobis..sp_cerror
      @t_from   = @w_sp_name,
      @i_num    = 1720646
    return 1720646    
END                

return 0
go


