/************************************************************************/
/*  Archivo:                saldo_capital_concentracion.sp              */
/*  Stored procedure:       sp_saldo_capital_concentracion              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_saldo_capital_concentracion')
    drop proc sp_saldo_capital_concentracion
go

CREATE PROC sp_saldo_capital_concentracion
			@t_debug       	char(1)     = 'N',
			@t_file         	varchar(14) = null,
			@t_from         	varchar(30) = null,
            @s_rol              smallint 	= null,
            @i_grupal           CHAR(1)     = NULL,
            @i_tramite          INT,
            @i_microcredito     VARCHAR(30) = NULL,
            @i_tipo_persona     CHAR(1)     = NULL,
            @o_saldo_capital    MONEY       = NULL OUT,
            @o_nro_operaciones  INT         = NULL OUT

AS
DECLARE @w_sp_name       	varchar(32),
        @w_return        	INT,
        @w_error            INT,
        @w_retorno          INT,
        ---var variables	
        @w_asig_actividad 	      int,
        @w_valor_ant      	      varchar(255),
        @w_valor_nuevo    	      varchar(255),
        @w_actividad      	      catalogo,
        @w_codigo_proceso         INT,
        @w_version_proceso        INT,
        @w_deudor                 INT,
        @w_monto_tramite          MONEY,
        @w_operacion              INT,
        @w_relacion_conyugue      INT,
        @w_relacion_padrehijo     INT,
        @w_param_porc_descubierto FLOAT,
        @w_param_microcredito     VARCHAR(64),
        @w_param_liquida          VARCHAR(64),
        @w_param_hipotecaria      VARCHAR(64),
        @w_param_nivef            VARCHAR(64),
        @w_moneda_UDIS            INT,
        @w_param_capef            MONEY,
        @w_param_limite_no_grupal MONEY,
        @w_endeudamiento          MONEY,
        @w_tipo_persona           CHAR(1),
        @w_saldo_capital_conyugue  MONEY,
        @w_saldo_capital_padrehijo MONEY,
        @w_saldo_capital_cliente   MONEY,
        @w_valor_garantias         MONEY,
        @w_nro_operaciones         INT
        
       
SELECT @w_sp_name='sp_saldo_capital_concentracion'


--	Solicitante del crédito que estamos aprobando
--	Padres del Solicitante.
--	Hijos del Solicitante.
--  Cónyuge o Pareja del Solicitante.

SELECT @w_deudor = de_cliente,
@w_monto_tramite = tr_monto
FROM cob_credito..cr_deudores, cob_credito..cr_tramite
WHERE de_tramite = @i_tramite
AND de_tramite = tr_tramite

SELECT @w_operacion = op_operacion
FROM cob_cartera..ca_operacion
WHERE op_tramite = @i_tramite

SELECT @w_relacion_conyugue = pa_int 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'RCONY'
AND pa_producto = 'CRE'

SELECT @w_relacion_padrehijo = pa_int 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'RPAHI'
AND pa_producto = 'CRE'

SELECT @w_param_porc_descubierto = pa_float
FROM cobis..cl_parametro
WHERE pa_nemonico = 'PGLHI'
AND pa_producto = 'CRE'

SELECT @w_param_microcredito = pa_char 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'SUBTM'
AND pa_producto = 'CCA'

SELECT @w_param_liquida = pa_char 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'TGLIQ'
AND pa_producto = 'CRE'

SELECT @w_param_hipotecaria = pa_char 
FROM cobis..cl_parametro
WHERE pa_nemonico = 'TGHIP'
AND pa_producto = 'CRE'


SELECT @w_saldo_capital_conyugue = 0,
       @w_saldo_capital_padrehijo = 0,
       @w_nro_operaciones = 0


 IF @i_microcredito <> @w_param_microcredito
 BEGIN
    IF @i_tipo_persona = 'P'
    BEGIN
      SELECT @w_saldo_capital_cliente = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_cliente  = @w_deudor

      IF EXISTS(SELECT 1 FROM cobis..cl_instancia
             WHERE in_ente_i = @w_deudor
             AND in_relacion = @w_relacion_conyugue)
      SELECT @w_saldo_capital_conyugue = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_cliente IN (SELECT in_ente_d FROM cobis..cl_instancia
                         WHERE in_ente_i = @w_deudor
                         AND in_relacion = @w_relacion_conyugue)
                     
      IF EXISTS(SELECT 1 FROM cobis..cl_instancia
             WHERE in_ente_i = @w_deudor
             AND   in_relacion = @w_relacion_padrehijo)
      SELECT @w_saldo_capital_padrehijo = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_cliente IN (SELECT in_ente_d FROM cobis..cl_instancia
                         WHERE in_ente_i = @w_deudor
                         AND in_relacion = @w_relacion_padrehijo)
                         
                         
      IF EXISTS(SELECT 1 FROM cobis..cl_instancia
             WHERE  in_ente_d = @w_deudor
             AND    in_relacion = @w_relacion_padrehijo)
      SELECT @w_saldo_capital_padrehijo = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_cliente IN (SELECT in_ente_i FROM cobis..cl_instancia
                         WHERE in_ente_d = @w_deudor
                         AND in_relacion = @w_relacion_padrehijo)
                         
      SELECT @w_endeudamiento = @w_saldo_capital_cliente + @w_saldo_capital_conyugue + @w_saldo_capital_padrehijo + @w_monto_tramite
    END
    ELSE	-- tipo persona = 'C'
    BEGIN
      SELECT @w_saldo_capital_cliente = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_cliente  = @w_deudor
                               
      SELECT @w_endeudamiento = @w_saldo_capital_cliente  + @w_monto_tramite  
    END
   END -- <> MICRO
   
 IF @i_microcredito = @w_param_microcredito AND @i_grupal = 'N'
 BEGIN
    IF @i_tipo_persona = 'P'
    BEGIN
      SELECT @w_saldo_capital_cliente = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext 
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'N'
      AND op_cliente  = @w_deudor

      IF EXISTS(SELECT 1 FROM cobis..cl_instancia
             WHERE in_ente_i = @w_deudor
             AND in_relacion = @w_relacion_conyugue)
      SELECT @w_saldo_capital_conyugue = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext	
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'N'
      AND op_cliente IN (SELECT in_ente_d FROM cobis..cl_instancia
                         WHERE in_ente_i = @w_deudor
                         AND in_relacion = @w_relacion_conyugue)
                     
      IF EXISTS(SELECT 1 FROM cobis..cl_instancia
             WHERE in_ente_i = @w_deudor
             AND   in_relacion = @w_relacion_padrehijo)
      SELECT @w_saldo_capital_padrehijo = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'N'
      AND op_cliente IN (SELECT in_ente_d FROM cobis..cl_instancia
                         WHERE in_ente_i = @w_deudor
                         AND in_relacion = @w_relacion_padrehijo)
                         
                         
      IF EXISTS(SELECT 1 FROM cobis..cl_instancia
             WHERE  in_ente_d = @w_deudor
             AND    in_relacion = @w_relacion_padrehijo)
      SELECT @w_saldo_capital_padrehijo = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'N'
      AND op_cliente IN (SELECT in_ente_i FROM cobis..cl_instancia
                         WHERE in_ente_d = @w_deudor
                         AND in_relacion = @w_relacion_padrehijo)
                         
      SELECT @w_endeudamiento = @w_saldo_capital_cliente + @w_saldo_capital_conyugue + @w_saldo_capital_padrehijo + @w_monto_tramite
    END
    ELSE	-- tipo persona = 'C'
    BEGIN
      SELECT @w_saldo_capital_cliente = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'N'
      AND op_cliente  = @w_deudor
                               
      SELECT @w_endeudamiento = @w_saldo_capital_cliente  + @w_monto_tramite  
    END
   END -- = MICRO, grupal = 'N'
   
   IF @i_microcredito = @w_param_microcredito AND @i_grupal = 'S'
   BEGIN
    IF @i_tipo_persona = 'P'
    BEGIN
      SELECT @w_saldo_capital_cliente = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext 
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'S'
      AND op_cliente  IN (SELECT de_cliente FROM cob_credito..cr_deudores WHERE de_tramite = @i_tramite)

      IF EXISTS(SELECT 1 FROM cobis..cl_instancia
             WHERE in_ente_i = @w_deudor
             AND in_relacion = @w_relacion_conyugue)
      SELECT @w_saldo_capital_conyugue = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext	
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'S'
      AND op_cliente IN (SELECT in_ente_d FROM cobis..cl_instancia
                         WHERE in_ente_i IN (SELECT de_cliente FROM cob_credito..cr_deudores WHERE de_tramite = @i_tramite)
                         AND in_relacion = @w_relacion_conyugue)
                     
      IF EXISTS(SELECT 1 FROM cobis..cl_instancia
             WHERE in_ente_i IN (SELECT de_cliente FROM cob_credito..cr_deudores WHERE de_tramite = @i_tramite)
             AND   in_relacion = @w_relacion_padrehijo)
      SELECT @w_saldo_capital_padrehijo = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'S'
      AND op_cliente IN (SELECT in_ente_d FROM cobis..cl_instancia
                         WHERE in_ente_i IN (SELECT de_cliente FROM cob_credito..cr_deudores WHERE de_tramite = @i_tramite)
                         AND in_relacion = @w_relacion_padrehijo)
                         
                         
      IF EXISTS(SELECT 1 FROM cobis..cl_instancia
             WHERE  in_ente_d IN (SELECT de_cliente FROM cob_credito..cr_deudores WHERE de_tramite = @i_tramite)
             AND    in_relacion = @w_relacion_padrehijo)
      SELECT @w_saldo_capital_padrehijo = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'S'
      AND op_cliente IN (SELECT in_ente_i FROM cobis..cl_instancia
                         WHERE in_ente_d IN (SELECT de_cliente FROM cob_credito..cr_deudores WHERE de_tramite = @i_tramite)
                         AND in_relacion = @w_relacion_padrehijo)
                         
      SELECT @w_endeudamiento = @w_saldo_capital_cliente + @w_saldo_capital_conyugue + @w_saldo_capital_padrehijo + @w_monto_tramite
    END
    ELSE	-- tipo persona = 'C'
    BEGIN
      SELECT @w_saldo_capital_cliente = sum(am_acumulado - am_pagado + am_gracia)  
      FROM cob_cartera..ca_amortizacion, cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext
      WHERE am_operacion = op_operacion
      AND op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND am_concepto = 'CAP'
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'S'
      AND op_cliente IN (SELECT de_cliente FROM cob_credito..cr_deudores WHERE de_tramite = @i_tramite)
                               
      SELECT @w_endeudamiento = @w_saldo_capital_cliente  + @w_monto_tramite  
    END
      
      SELECT @w_nro_operaciones = count(1)  
      FROM  cob_cartera..ca_operacion, cob_cartera..ca_operacion_ext 
      WHERE op_estado IN (SELECT es_codigo FROM cob_cartera..ca_estado WHERE es_procesa = 'S')
      AND op_subtipo_linea = @i_microcredito
      AND oe_operacion = op_operacion
      AND oe_columna = 'op_grupal'
      AND oe_char = 'S'
      AND op_cliente IN (SELECT de_cliente FROM cob_credito..cr_deudores WHERE de_tramite = @i_tramite)
      
   END -- = MICRO, grupal = 'S'
   
       
    /**** Detalle de Garantías Líquidas***/
    SELECT @w_valor_garantias = sum(isnull(cu_valor_actual,0))
    FROM cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia, cob_custodia..cu_tipo_custodia,
    cob_credito..cr_deudores
    WHERE gp_tramite = @i_tramite
    AND gp_tramite = de_tramite
    AND de_cliente = @w_deudor
    AND gp_garantia = cu_codigo_externo
    AND cu_estado NOT IN ('C', 'A')
    AND cu_tipo = tc_tipo
    AND (tc_tipo_superior = @w_param_liquida OR tc_tipo_superior = @w_param_hipotecaria)
    
    /****** Monto Descubierto ******/
       
    SELECT @o_saldo_capital = @w_endeudamiento,
           @o_nro_operaciones = @w_nro_operaciones

return 0
ERROR:
    exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error
    return @w_error

GO
