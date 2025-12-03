/************************************************************************/
/*  Archivo:                busca_doc.sp                                */
/*  Stored procedure:       sp_busca_doc                                */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_busca_doc' and type = 'P')
   drop proc sp_busca_doc
go

CREATE PROCEDURE sp_busca_doc(
   @i_tramite   INT         = null,
   @i_cliente   INT         = NULL,
   @i_grupo     INT         = NULL,
   @i_banco     VARCHAR(30) = NULL,
   @i_opcion    VARCHAR(1) ,
   @i_instancia INT         = null
)
AS

DECLARE
@w_instancia    INT,
@w_grupal       VARCHAR(10),
@w_operacionca  INT


--//////////////////////////////////////////////////////////////
-- CONSULTAR EL DOC
IF @i_opcion = 'D'
BEGIN
    SELECT 
        dd_tipo_doc, dd_extension, dd_cargado , dd_cliente, dd_grupo, 'documento' = 
        CASE tr_grupal 
        WHEN 'S' THEN (
            SELECT  valor  FROM cobis..cl_catalogo c, cobis..cl_tabla t
            WHERE t.tabla = 'cr_doc_digitalizado'
            AND c.tabla = t.codigo
            AND c.codigo = d.dd_tipo_doc)
        else 
            (SELECT  valor  FROM cobis..cl_catalogo c, cobis..cl_tabla t
            WHERE t.tabla = 'cr_doc_digitalizado_ind'
            AND c.tabla = t.codigo
            AND c.codigo = d.dd_tipo_doc)
        END 
    FROM cob_workflow..wf_inst_proceso,  cob_credito..cr_documento_digitalizado d, cob_credito..cr_tramite
    WHERE io_id_inst_proc = @i_instancia
    AND dd_cliente = @i_cliente
    AND io_id_inst_proc  = dd_inst_proceso
    AND io_campo_3       = tr_tramite
    AND dd_cargado       = 'S'


end

--//////////////////////////////////////////////////////////////
-- CONSULTAR EL DOC INDIVIDUALES
IF @i_opcion = 'P'
BEGIN
    SELECT 
        dd_tipo_doc, dd_extension, dd_cargado , dd_cliente, dd_grupo, 
        'documento' = (SELECT  valor  FROM cobis..cl_catalogo c, cobis..cl_tabla t
            WHERE t.tabla = 'cr_doc_digitalizado_ind'
            AND c.tabla = t.codigo
            AND c.codigo = d.dd_tipo_doc)
    FROM cob_credito..cr_documento_digitalizado d
    WHERE dd_inst_proceso = @i_instancia
    AND dd_cliente = @i_cliente
    AND dd_cargado = 'S'

end

--//////////////////////////////////////////////////////////////
-- CONSULTAR DOC DEL TRAMITE
IF @i_opcion = 'F'
BEGIN
    SELECT ri_codigo_tipo_doc, ri_nombre_doc, 'S', td_nombre_tipo_doc
    FROM cob_workflow..wf_req_inst, cob_workflow..wf_tipo_documento
    WHERE ri_id_inst_proc = @i_instancia
    AND td_codigo_tipo_doc = ri_codigo_tipo_doc
end



-- OPCION BUSCAR
--//////////////////////////////////////////////////////////////
IF @i_opcion = 'B'
BEGIN
    CREATE TABLE #tmp_resultado (
    grupal      VARCHAR(10) NULL,
    instancia   INT         NOT NULL,
    grupo       INT         NOT NULL,
    cliente     INT         NOT NULL,
    nombre      VARCHAR(90) NULL,
    prestamo    VARCHAR(30) NOT NULL,
    tramite_g   INT         NOT NULL)

    -- BUSCAR POR TRAMITE O POR PRESTAMO
    IF @i_tramite IS NOT NULL OR @i_banco IS NOT NULL
    BEGIN
        IF @i_banco IS NOT NULL
            SELECT
                @w_grupal      = tr_grupal,
                @w_operacionca = op_operacion,
                @i_tramite     = op_tramite
            FROM cob_credito..cr_tramite, cob_cartera..ca_operacion
            WHERE op_banco = @i_banco
            AND op_tramite   = tr_tramite
        ELSE
            IF @i_tramite IS NOT NULL
                SELECT
                    @w_grupal = tr_grupal,
                    @w_operacionca = op_operacion
                FROM cob_credito..cr_tramite, cob_cartera..ca_operacion
                WHERE tr_tramite = @i_tramite
                AND op_tramite   = tr_tramite

        IF @w_grupal  = 'S' -- GRUPAL
        BEGIN
            SELECT @w_instancia = io_id_inst_proc FROM cob_workflow..wf_inst_proceso
            WHERE io_campo_3 = @i_tramite

            INSERT INTO #tmp_resultado
            SELECT
                'es_grupal' = @w_grupal,
                'instancia' = @w_instancia ,
                'grupo'     = tg_grupo,
                'cliente'   = tg_cliente,
                'nombre'    = (SELECT en_nomlar FROM cobis..cl_ente WHERE en_ente = tg.tg_cliente),
                'prestamo'  = tg_prestamo,
                'tramite_g' = tg_tramite
            FROM cob_credito..cr_tramite_grupal tg
            WHERE tg_tramite = @i_tramite
            AND tg_monto > 0
        END
        IF @w_grupal  = 'N' -- INTERCICLO
        BEGIN
            SELECT @w_instancia = io_id_inst_proc FROM cob_workflow..wf_inst_proceso
            WHERE io_campo_3 = @i_tramite

            INSERT INTO #tmp_resultado
            SELECT
                'es_grupal' = @w_grupal,
                'instancia' = @w_instancia,
                'grupo'     = 0,
                'cliente'   = op_cliente,
                'nombre'    = (SELECT en_nomlar FROM cobis..cl_ente WHERE en_ente = o.op_cliente),
                'prestamo'  = op_banco,
                'tramite'   = op_tramite
            FROM cob_cartera..ca_operacion o
            WHERE op_tramite = @i_tramite
        END
        IF @w_grupal  IS NULL  -- INDIVIDUAL O PUEDE SER HIJA DE UN GRUPAL
        BEGIN

            IF EXISTS (SELECT 1 FROM cob_credito..cr_tramite_grupal WHERE tg_operacion = @w_operacionca) -- GRUPAL HIJA
            BEGIN
                SELECT @w_instancia = io_id_inst_proc
                FROM cob_credito..cr_tramite_grupal , cob_workflow..wf_inst_proceso
                WHERE tg_operacion = @w_operacionca
                AND   io_campo_3 = tg_tramite

                INSERT INTO #tmp_resultado
                SELECT
                    'es_grupal' = @w_grupal,
                    'instancia' = @w_instancia ,
                    'grupo'     = tg_grupo,
                    'cliente'   = tg_cliente,
                    'nombre'    = (SELECT en_nomlar FROM cobis..cl_ente WHERE en_ente = tg.tg_cliente),
                    'prestamo'  = tg_prestamo,
                    'tramite_g' = tg_tramite
                FROM cob_credito..cr_tramite_grupal tg
                WHERE tg_operacion = @w_operacionca
            END
            ELSE
            BEGIN
                SELECT @w_instancia = io_id_inst_proc FROM cob_workflow..wf_inst_proceso
                WHERE io_campo_3 = @i_tramite

                INSERT INTO #tmp_resultado
                SELECT
                    'es_grupal' = @w_grupal,
                    'instancia' = @w_instancia,
                    'grupo'     = 0,
                    'cliente'   = op_cliente,
                    'nombre'    = (SELECT en_nomlar FROM cobis..cl_ente WHERE en_ente = o.op_cliente),
                    'prestamo'  = op_banco,
                    'tramite'   = op_tramite
                FROM cob_cartera..ca_operacion o
                WHERE op_tramite = @i_tramite
            END
        END
    END

    /*IF @i_cliente IS NOT NULL AND @i_grupo is NULL
    BEGIN
        -- tramite de SOLO clientes
        SELECT
            'tramite'   = op_tramite ,
            'tramite_g' = 0,
            'operacion' = op_operacion,
            'instancia' = 0,
            'grupal'    = ''
            INTO #tmp_cliente
        FROM cob_credito..cr_tramite, cob_cartera..ca_operacion
        WHERE op_cliente = @i_cliente
        AND op_tramite = tr_tramite
        AND (tr_grupal = 'N' OR tr_grupal is NULL)

        -- identificar los tramites grupales
        UPDATE #tmp_cliente SET
            tramite_g = tg_tramite,
            grupal    = 'S'
        FROM cob_credito..cr_tramite_grupal
        WHERE tg_operacion = operacion

        -- identificar la instancia del GRUPAL
        UPDATE #tmp_cliente SET
            instancia = io_id_inst_proc
        FROM cob_workflow..wf_inst_proceso
        WHERE io_campo_3 = tramite_g
        AND tramite_g > 0 -- los grupales

        -- identificar la instancia del INDIVIDUAL
        UPDATE #tmp_cliente SET
            instancia = io_id_inst_proc
        FROM cob_workflow..wf_inst_proceso
        WHERE io_campo_3 = tramite
        AND tramite_g = 0 -- los individuales

        -- GRUPAL
        INSERT INTO #tmp_resultado
        SELECT
            'es_grupal' = grupal,
            'instancia' = instancia ,
            'grupo'     = tg_grupo,
            'cliente'   = tg_cliente,
            'nombre'    = (SELECT en_nomlar FROM cobis..cl_ente WHERE en_ente = tg.tg_cliente),
            'prestamo'  = tg_prestamo,
            'tramite_g' = tg_tramite
        FROM #tmp_cliente, cob_credito..cr_tramite_grupal tg
        WHERE  tg_tramite = tramite_g
        AND tg_monto > 0
        AND grupal = 'S'
        AND tg_cliente = @i_cliente

        UNION

        SELECT
            'es_grupal' = null,
            'instancia' = instancia,
            'grupo'     = 0,
            'cliente'   = op_cliente,
            'nombre'    = (SELECT en_nomlar FROM cobis..cl_ente WHERE en_ente = op.op_cliente),
            'prestamo' = op_banco,
            'tramite'  = op_tramite
        FROM cob_cartera..ca_operacion op,  #tmp_cliente
        WHERE op_tramite = tramite
        AND grupal <> 'S'
    END

    IF @i_grupo IS NOT NULL
    BEGIN
        -- tramite de SOLO grupos
        SELECT
            'tramite_g' = op_tramite
            INTO #tmp_tramite_grupal
        FROM cob_credito..cr_tramite, cob_cartera..ca_operacion
        WHERE op_cliente = @i_grupo
        AND op_tramite = tr_tramite
        AND tr_grupal  = 'S'

        -- operaciones hijas de las grupales
        SELECT DISTINCT
            'tramite'   = op_tramite ,
            'tramite_g' = tg_tramite,
            'operacion' = op_operacion,
            'instancia' = 0,
            'grupal'    = tg_grupal
            INTO #tmp_grupo
        FROM cob_credito..cr_tramite_grupal, #tmp_tramite_grupal, cob_cartera..ca_operacion
        WHERE tg_tramite = tramite_g
        AND tg_monto > 0
        AND op_operacion = tg_operacion

        -- identificar la instancia del GRUPAL
        UPDATE #tmp_grupo SET
            instancia = io_id_inst_proc
        FROM cob_workflow..wf_inst_proceso
        WHERE io_campo_3 = tramite_g
        AND grupal       = 'S'

        -- identificar la instancia del INDIVIDUAL-INTERCICLO
        UPDATE #tmp_grupo SET
            instancia = io_id_inst_proc
        FROM cob_workflow..wf_inst_proceso
        WHERE io_campo_3 = tramite
        AND grupal       = 'N'

        -- GRUPAL
        INSERT INTO #tmp_resultado
        SELECT
            'es_grupal' = grupal,
            'instancia' = instancia ,
            'grupo'     = tg_grupo,
            'cliente'   = tg_cliente,
            'nombre'    = (SELECT en_nomlar FROM cobis..cl_ente WHERE en_ente = tg.tg_cliente),
            'prestamo'  = tg_prestamo,
            'tramite_g' = tg_tramite
        FROM #tmp_grupo, cob_credito..cr_tramite_grupal tg
        WHERE  tg_tramite = tramite_g
        AND tg_monto > 0
        AND tg_grupo = @i_grupo
        AND tg_operacion = operacion
        AND tg_cliente = isnull(@i_cliente, tg_cliente)
        ORDER BY tg_tramite, nombre, prestamo
    END*/

    SELECT
        grupal    ,
        instancia ,
        grupo     ,
        cliente   ,
        nombre    ,
        prestamo  ,
        tramite_g
    FROM #tmp_resultado
    order by tramite_g, nombre, grupal, prestamo
    return 0
end

-- OPCION BUSCA DE CICLOS
--//////////////////////////////////////////////////////////////
if @i_opcion = 'C'
begin
    
    CREATE TABLE #tmp_resultado_ciclo (
        instancia   INT         not null,
        prestamo    varchar(30) not null,
        tramite_g   int         not null,
        ciclo       int not null,
        cicloDet    varchar(30))
    
    IF @i_grupo IS NOT NULL
    BEGIN
        
        -- GRUPAL
        INSERT INTO #tmp_resultado_ciclo
        SELECT
            'instancia' = io_id_inst_proc,
            'prestamo'  = ci_prestamo,
            'tramite_g' = tr_tramite,
            'ciclo'     = ci_ciclo,
            'cicloDet'  = 'Ciclo ' + convert(varchar,ci_ciclo)
        FROM cob_credito..cr_tramite, cob_cartera..ca_ciclo, cob_workflow..wf_inst_proceso 
        WHERE ci_grupo = @i_grupo
        AND ci_tramite = tr_tramite
        AND io_campo_3 = ci_tramite
        ORDER BY ci_ciclo, tr_tramite
        
        IF EXISTS(SELECT * FROM cob_workflow..wf_inst_proceso 
                WHERE io_campo_1 = @i_grupo AND io_estado = 'EJE')
        begin
            INSERT INTO #tmp_resultado_ciclo
            SELECT
                'instancia' = io_id_inst_proc,
                'prestamo'  = tr_numero_op_banco,
                'tramite_g' = tr_tramite,
                'ciclo'     = isnull((SELECT (max(ci_ciclo) + 1) from cob_cartera..ca_ciclo WHERE ci_grupo = io_campo_1),1),
                'cicloDet'  = isnull('Ciclo ' + ( SELECT convert(varchar,max(ci_ciclo)+1) from cob_cartera..ca_ciclo WHERE ci_grupo = io_campo_1),1)
            FROM cob_credito..cr_tramite, cob_workflow..wf_inst_proceso 
            WHERE io_campo_1 = @i_grupo
            AND io_campo_3 = tr_tramite
            AND io_estado = 'EJE'
            GROUP BY io_id_inst_proc, tr_numero_op_banco, tr_tramite, tr_tramite, io_campo_1
            ORDER BY io_id_inst_proc, tr_tramite
        end
    end

    SELECT distinct
        instancia ,
        prestamo  ,
        tramite_g ,
        ciclo ,
        cicloDet
    FROM #tmp_resultado_ciclo
    order by ciclo, tramite_g
    return 0
end
GO
