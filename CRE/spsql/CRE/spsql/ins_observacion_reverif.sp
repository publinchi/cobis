/************************************************************************/
/*  Archivo:                ins_observacion_reverif.sp                  */
/*  Stored procedure:       sp_ins_observacion_reverif                  */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_ins_observacion_reverif')
    drop proc sp_ins_observacion_reverif
go

create proc sp_ins_observacion_reverif (
 	@s_ssn        	INT         = NULL,
	@s_ofi        	SMALLINT    = NULL,
	@s_user       	login       = NULL,
	@s_date       	DATETIME    = NULL,
	@s_srv		   	VARCHAR(30) = NULL,
	@s_term	   		descripcion = NULL,
	@s_rol		   	SMALLINT    = NULL,
	@s_lsrv	   		VARCHAR(30)	= NULL,
	@s_sesn	   		INT 	    = NULL,
	@s_org		   	CHAR(1)     = NULL,
	@s_org_err   	INT 	    = NULL,
	@s_error     	INT 	    = NULL,
	@s_sev        	TINYINT     = NULL,
	@s_msg        	descripcion = NULL,
	@t_rty        	CHAR(1)     = NULL,
	@t_trn        	INT         = NULL,
	@t_debug      	CHAR(1)     = 'N',
	@t_file       	VARCHAR(14) = NULL,
	@t_from       	VARCHAR(30) = NULL,
	--variables
	@i_id_inst_proc	INT,    			-- Codigo de instancia del proceso
	@i_id_inst_act 	INT			= NULL,	-- Codigo instancia de la atividad
	@i_id_empresa	INT			= NULL,	-- Codigo de la empresa
	@i_clientes		VARCHAR(255),		-- Lista de codigos de clientes con error en las reglas
	@i_tipo_regla	CHAR(1),			-- Tipo de regla con el cual no pasaron la regla (Incremento = I, Monto = M)
	@i_numero_linea	INT         = NULL  -- Numero de la linea del mensaje
)
AS
DECLARE	-- Variables de trabajo
		@w_codigo_categoria		INT,
		@w_asig_act				INT,
		@w_secuencial			INT,
		@w_usuario				VARCHAR(64),
		@w_descripcion			VARCHAR(255)

-- Seteo de variables
SELECT @w_codigo_categoria	=	pa_int	-- Codigo de la categoria de la observacion
FROM cobis..cl_parametro
WHERE pa_nemonico = 'OAA'

-- Consulta el numero de asigana actividad
SELECT	@w_asig_act   = CONVERT(INT, io_campo_2)
FROM cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc

-- Consulta Nombre del usuario
SELECT @w_usuario	=	fu_nombre
FROM cobis..cl_funcionario
WHERE fu_login = @s_user


SELECT TOP 1 @i_numero_linea = ob_numero FROM cob_workflow..wf_observaciones
WHERE ob_id_asig_act = @w_asig_act
order by ob_numero desc

if (@i_numero_linea IS NOT null)
begin
    SELECT @i_numero_linea = @i_numero_linea + 1 --aumento en uno el maximo
end
else
begin
    SELECT @i_numero_linea = 1
end



-- Tipo regla para segun esto setear el mensaje
IF @i_tipo_regla = 'I'
	SELECT @w_descripcion = 'ERROR: Los clientes ' + @i_clientes + '. No cumplen la regla de Incremento Grupal'
IF @i_tipo_regla = 'M'
	SELECT @w_descripcion = 'ERROR: Los clientes ' + @i_clientes + '. No cumplen la regla de montos mínimos y máximos Montos Grupales”'

-- Inserta observaciones y lineas
INSERT INTO cob_workflow..wf_observaciones
		(ob_id_asig_act,	ob_numero,	ob_fecha,	ob_categoria,
		ob_lineas,	ob_oficial,	ob_ejecutivo)
VALUES	(@w_asig_act, 		@i_numero_linea,	GETDATE(),	@w_codigo_categoria,
		1,			SUBSTRING(@s_user,1,1),	@w_usuario)

INSERT INTO cob_workflow..wf_ob_lineas
		(ol_id_asig_act,	ol_observacion,	ol_linea,	ol_texto)
VALUES	(@w_asig_act,		@i_numero_linea,	@i_numero_linea,			@w_descripcion)

RETURN 0
go

--
-- Procedures
--
SET ANSI_NULLS OFF
go
SET ANSI_NULLS ON
go
