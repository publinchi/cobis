/************************************************************************/
/*  Archivo:                grupal_xml.sp                               */
/*  Stored procedure:       sp_grupal_xml                               */
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

if exists(select 1 from sysobjects where name ='sp_grupal_xml')
    drop proc sp_grupal_xml
go

create proc sp_grupal_xml (
    @i_en_linea  CHAR (1)     = 'S',
    @t_file       varchar(14) = null,
    @t_debug      char(1)     = 'N',
    @i_origen     varchar(32) = '',
    @i_inst_proc  int         = NULL
)
as

/*LPO CDIG Se comenta porque Cobis Language no soporta XML INICIO
declare
    @w_tramite             INT,
    @w_tc_si_sincroniza    SMALLINT,
    @w_cod_entidad         VARCHAR(10),
    @w_max_si_sincroniza   INT,
    @w_fech_proc           DATETIME,
    @w_operacion           INT,
    @w_des_entidad         VARCHAR(64),
    @w_xml                 XML,
    @w_accion              VARCHAR(255),
    @w_observacion         VARCHAR(255),
    @w_error               INT,
    @w_sp_name             VARCHAR(32),
    @w_msg                 VARCHAR(100),
    @w_oficial             INT,
    @w_user                login,
    @w_grupo               INT,
    @w_gr_ente             INT

select @w_sp_name = 'sp_grupal_xml'

SET ROWCOUNT 0

--Datos de la Entidad -- Grupal
select @w_cod_entidad = 3
SELECT @w_cod_entidad = codigo,
       @w_des_entidad = valor
FROM cobis..cl_catalogo
WHERE tabla = ( SELECT codigo  FROM cobis..cl_tabla
                WHERE tabla = 'si_sincroniza') AND codigo = @w_cod_entidad

--Fecha de Proceso
SELECT @w_fech_proc = fp_fecha FROM cobis..ba_fecha_proceso

--Tramite
SELECT @w_tramite = io_campo_3 FROM cob_workflow..wf_inst_proceso WHERE io_id_inst_proc = @i_inst_proc
if @@rowcount = 0
begin
    select @w_error = 150000 -- ERROR EN INSERCION,
    select @w_msg = 'Solicitud Grupal: No existe informacion para esa instancia de proceso'
    goto ERROR
end

---Número de operacion y usuario
SELECT @w_operacion = op_operacion
FROM cob_cartera..ca_operacion OP WHERE op_tramite = @w_tramite

SELECT @w_user      = (SELECT fu_login from cobis..cl_funcionario, cobis..cc_oficial
                       WHERE oc_funcionario = fu_funcionario AND oc_oficial = TR.tr_oficial)
FROM cob_credito..cr_tramite TR
WHERE tr_tramite = @w_tramite

if @w_user is null
begin
    select @w_error = 150000 -- ERROR EN INSERCION,
    select @w_msg = 'No existe Oficial'
    goto ERROR
end

-- Comentarios
SELECT @w_accion = 'ACTUALIZAR'
-- Observaciones
declare @w_aa_id_asig_act int, @w_texto varchar(max) = ''
select @w_aa_id_asig_act = io_campo_2
from cob_workflow..wf_inst_proceso where io_id_inst_proc = @i_inst_proc

select DISTINCT @w_observacion = ol_texto
from cob_workflow..wf_observaciones OB, cob_workflow..wf_ob_lineas OL
where OB.ob_id_asig_act = OL.ol_id_asig_act
and ob_id_asig_act = @w_aa_id_asig_act
AND ol_observacion = (SELECT max(ol_observacion) FROM cob_workflow..wf_ob_lineas
where OB.ob_id_asig_act = ol_id_asig_act
and OB.ob_id_asig_act = @w_aa_id_asig_act)

SELECT @w_observacion = isnull(@w_observacion,'ACTUALIZAR INFORMACION') + isnull(@i_origen,'')

 create table #cr_tramite_grupal_miembros(
                   w_tg_monto	 	MONEY,
                   w_tg_monto_aprobado MONEY,
                   w_en_ente INT,
                   w_cg_nro_ciclo INT ,
                   w_tr_porc_garantia VARCHAR(20),
                   w_en_nomlar VARCHAR(254),
                   w_tg_participa_ciclo CHAR(1),
                   w_tg_monto_max money,
                   w_en_calificacion VARCHAR(10),
                   w_cg_rol VARCHAR(10),
                   w_cg_ahorro_voluntario MONEY,
                   w_en_nit VARCHAR(30),
                   w_tramite INT

				   )


 INSERT INTO  #cr_tramite_grupal_miembros
    SELECT 'amountRequestedOriginal' = tg_monto,
           'authorizedAmount'        = tg_monto_aprobado,
           'code'                    = en_ente,
           'cycleNumber'             = cg_nro_ciclo,
           'liquidGuarantee'         = convert(VARCHAR(20),((ISNULL(tr_porc_garantia,0))*tg_monto/100)),
           'name'                    = rtrim(en_nomlar),
           'participant'             = tg_participa_ciclo,
           'proposedMaximumAmount'   = tg_monto_max,
           'riskLevel'               = (ISNULL(en_calificacion,'')),
           'role'   = cg_rol,
           'voluntarySavings'        = cg_ahorro_voluntario,
           'rfc'                     = en_nit,
           'w_tramite'               =@w_tramite
            FROM cob_credito..cr_tramite_grupal TG,
                 cobis..cl_ente EN,
            	 cobis..cl_cliente_grupo CG,
            	 cob_credito..cr_tramite T
            WHERE
                TG.tg_cliente = EN.en_ente
            AND TG.tg_cliente = CG.cg_ente
            AND TG.tg_tramite = T.tr_tramite
            AND TG.tg_grupo  = CG.cg_grupo
            AND TG.tg_tramite = @w_tramite





SELECT  TOP 1 @w_grupo=tg_grupo FROM  cob_credito..cr_tramite_grupal WHERE tg_tramite =@w_tramite


SELECT @w_gr_ente=0
while 1=1 -- while para barrerse los clientes del grupo
begin
    select top 1
        @w_gr_ente = cg_ente
    from cobis..cl_cliente_grupo
    WHERE cg_grupo=@w_grupo
    and cg_ente > @w_gr_ente
    AND cg_estado='V' AND cg_fecha_desasociacion IS null
    order by cg_ente

    if @@rowcount = 0 BREAK --para salir del break



    IF NOT EXISTS (SELECT 1 FROM #cr_tramite_grupal_miembros WHERE w_en_ente=@w_gr_ente)
    BEGIN

     INSERT INTO #cr_tramite_grupal_miembros
       SELECT               w_tg_monto =  0,
              'authorizedAmount'        = 0,
              'code'                    = en_ente,
              'cycleNumber'             = cg_nro_ciclo,
              'liquidGuarantee'         = null,
              'name'                    = rtrim(en_nomlar),
              'participant'             = 'N',
              'proposedMaximumAmount'   = 0,
              'riskLevel'               = (ISNULL(en_calificacion,'')),
              'role'                    = cg_rol,
              'voluntarySavings'        = cg_ahorro_voluntario,
              'rfc'                     = en_nit,
              'w_tramite'               =@w_tramite
            FROM
                 cobis..cl_ente EN,
            	 cobis..cl_cliente_grupo CG
            WHERE
               EN.en_ente=CG.cg_ente
            AND EN.en_ente=@w_gr_ente
    END

END --end del while para barrerse los clientes del grupo


-- Inicio XML

    select @w_xml = (
    SELECT tag, parent,
                   [creditGroupApplicationSynchronizedData!1!valor],      --1
                   [creditGroupApplication!2!valor],                      --2
                   [creditGroupApplication!2!applicationDate!ELEMENT],    --3
                   [creditGroupApplication!2!applicationType!ELEMENT],    --4
                   [creditGroupApplication!2!groupAgreeRenew!ELEMENT],    --5
                   [creditGroupApplication!2!groupAmount!ELEMENT],        --6
                   [creditGroupApplication!2!groupCycle!ELEMENT],         --7
                   [creditGroupApplication!2!groupName!ELEMENT],          --8
                   [creditGroupApplication!2!groupNumber!ELEMENT],        --9
                   [creditGroupApplication!2!office!ELEMENT],             --10
                   [creditGroupApplication!2!officer!ELEMENT],            --11
                   [creditGroupApplication!2!processInstance!ELEMENT],    --12
                   [creditGroupApplication!2!promotion!ELEMENT],          --13
                   [creditGroupApplication!2!rate!ELEMENT],               --14
                   [creditGroupApplication!2!reasonNotAccepting!ELEMENT], --15
                   [creditGroupApplication!2!term!ELEMENT],               --16
                   [members!3!valor],                                     --17
                   [members!3!amountRequestedOriginal!ELEMENT],           --18
                   [members!3!authorizedAmount!ELEMENT],                  --19
                   [members!3!code!ELEMENT],                        --20
                   [members!3!cycleNumber!ELEMENT],                       --21
                   [members!3!liquidGuarantee!ELEMENT],                   --22
  [members!3!name!ELEMENT],                              --23
                   [members!3!participant!ELEMENT],                       --24
                   [members!3!proposedMaximumAmount!ELEMENT],             --25
                   [members!3!riskLevel!ELEMENT],                         --26
                   [members!3!role!ELEMENT],                              --27
                   [members!3!voluntarySavings!ELEMENT],                  --28
                   [members!3!rfc!ELEMENT]                                --29
    FROM
    (
SELECT 1 AS tag,
    NULL AS parent,
    NULL AS [creditGroupApplicationSynchronizedData!1!valor],      --1
    NULL AS [creditGroupApplication!2!valor],                      --2
    NULL AS [creditGroupApplication!2!applicationDate!ELEMENT],    --3
    NULL AS [creditGroupApplication!2!applicationType!ELEMENT],    --4
    NULL AS [creditGroupApplication!2!groupAgreeRenew!ELEMENT],    --5
    NULL AS [creditGroupApplication!2!groupAmount!ELEMENT],        --6
    NULL AS [creditGroupApplication!2!groupCycle!ELEMENT],         --7
    NULL AS [creditGroupApplication!2!groupName!ELEMENT],          --8
    NULL AS [creditGroupApplication!2!groupNumber!ELEMENT],        --9
    NULL AS [creditGroupApplication!2!office!ELEMENT],             --10
    NULL AS [creditGroupApplication!2!officer!ELEMENT],            --11
    NULL AS [creditGroupApplication!2!processInstance!ELEMENT],    --12
    NULL AS [creditGroupApplication!2!promotion!ELEMENT],          --13
    NULL AS [creditGroupApplication!2!rate!ELEMENT],               --14
    NULL AS [creditGroupApplication!2!reasonNotAccepting!ELEMENT], --15
    NULL AS [creditGroupApplication!2!term!ELEMENT],               --16
    NULL AS [members!3!valor],                                     --17
    NULL AS [members!3!amountRequestedOriginal!ELEMENT],           --18
    NULL AS [members!3!authorizedAmount!ELEMENT],                  --19
    NULL AS [members!3!code!ELEMENT],                              --20
    NULL AS [members!3!cycleNumber!ELEMENT],                       --21
    NULL AS [members!3!liquidGuarantee!ELEMENT],                   --22
    NULL AS [members!3!name!ELEMENT],                              --23
    NULL AS [members!3!participant!ELEMENT],                       --24
    NULL AS [members!3!proposedMaximumAmount!ELEMENT],             --25
    NULL AS [members!3!riskLevel!ELEMENT],                         --26
    NULL AS [members!3!role!ELEMENT],                              --27
    NULL AS [members!3!voluntarySavings!ELEMENT],                  --28
    NULL AS [members!3!rfc!ELEMENT]                                --29

UNION ALL
SELECT 2 AS tag,
    1 AS parent,
    NULL,                                                               --1
    NULL,                                                               --2
    'applicationDate'= (SELECT format(op_fecha_liq,'yyyy-MM-ddTHH:mm:ss.fffZ')),
    'applicationType'= op_toperacion,
    'groupAgreeRenew'= (CASE TR.tr_acepta_ren WHEN 'S' THEN 'true' ELSE 'false' END),
    'groupAmount'    = op_monto,
    'groupCycle'     = G.gr_num_ciclo,
    'groupName'      = G.gr_nombre,
    'groupNumber'    = G.gr_grupo,
    'office'         = (SELECT of_nombre FROM cobis..cl_oficina WHERE of_filial = 1 AND of_oficina = TR.tr_oficina),
    'officer'        = (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial
                               where oc_funcionario = fu_funcionario AND oc_oficial = TR.tr_oficial),
    'processInstance'= @i_inst_proc,
    'promotion'=(CASE TR.tr_promocion WHEN 'S' THEN 'true' ELSE 'false' END),
    'rate'=convert (VARCHAR(30),(SELECT ro_porcentaje FROM cob_cartera..ca_rubro_op
                                  WHERE  ro_operacion = OP.op_operacion
                       AND OP.op_tramite = TR.tr_tramite
                                  AND ro_concepto  = 'INT')),
    'reasonNotAccepting' = tr_no_acepta,
    'term'               = tr_plazo,
    NULL,--17
    NULL,--18
    NULL,--19
    NULL,--20
    NULL,--21
    NULL,--22
    NULL,--23
    NULL,--24
    NULL,--25
    NULL,--26
    NULL,--27
    NULL,--28
    NULL --29
    FROM cob_cartera..ca_operacion OP,cobis..cl_grupo G, cob_credito..cr_tramite TR
    where
    OP.op_tramite=TR.tr_tramite
    AND OP.op_cliente=G.gr_grupo
    AND TR.tr_tramite =@w_tramite
UNION ALL
SELECT 3 AS tag,
    2 AS parent,
    NULL, --1
    NULL, --2
    NULL, --3
    NULL, --4
    NULL, --5
    NULL, --6
    NULL, --7
    NULL, --8
    NULL, --9
    NULL, --10
    NULL, --11
    NULL, --12
    NULL, --13
    NULL, --14
    NULL, --15
    NULL, --16
    NULL, --17
    'amountRequestedOriginal' = w_tg_monto,
    'authorizedAmount'        = w_tg_monto_aprobado,
    'code'                    = w_en_ente,
    'cycleNumber'             = w_cg_nro_ciclo,
    'liquidGuarantee'         = convert(VARCHAR(20),((ISNULL(w_tr_porc_garantia,0))*w_tg_monto/100)),
    'name'                    = rtrim(w_en_nomlar),
      CASE
      WHEN w_tg_participa_ciclo ='S' THEN 'true'
      WHEN w_tg_participa_ciclo ='N' THEN 'false'
      END ,
    'proposedMaximumAmount'   = w_tg_monto_max,
    'riskLevel'               = (ISNULL(w_en_calificacion,'')),
    'role'                    = w_cg_rol,
    'voluntarySavings'        = w_cg_ahorro_voluntario,
    'rfc'                     = w_en_nit
FROM #cr_tramite_grupal_miembros
WHERE w_tramite = @w_tramite) AS A FOR XML EXPLICIT )


--Secuencial
SELECT @w_max_si_sincroniza = isnull((max(si_secuencial) + 1),1)
FROM   cob_sincroniza..si_sincroniza

-- Insert en si_sincroniza
INSERT INTO cob_sincroniza..si_sincroniza (si_secuencial,            si_cod_entidad, si_des_entidad,
                                           si_usuario,               si_estado,      si_fecha_ing,
                                           si_fecha_sin,             si_num_reg)
       VALUES                             (@w_max_si_sincroniza,     @w_cod_entidad, @w_des_entidad,
                                           @w_user      ,            'P',            @w_fech_proc,
                                           NULL,                     1)
if @@error <> 0
begin
    select @w_error = 15000 -- ERROR EN INSERCION
    goto ERROR
end


-- Insert en si_sincroniza_det
INSERT INTO cob_sincroniza..si_sincroniza_det (sid_secuencial,       sid_id_entidad, sid_id_1,
                                               sid_id_2,             sid_xml,        sid_accion,
                                               sid_observacion)
       VALUES                                 (@w_max_si_sincroniza, @i_inst_proc,   @w_tramite,
                                               @w_operacion,         @w_xml,         @w_accion,
                                               @w_observacion)
if @@error <> 0
begin
    select @w_error = 150000 -- ERROR EN INSERCION
    goto ERROR
end
return 0

ERROR:
	IF @i_en_linea = 'S'
    begin --Devolver mensaje de Error
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = @w_error,
    @i_msg   = @w_msg
        return @w_error
    END
    ELSE
        return @w_error
go
*/ --LPO CDIG Se comenta porque Cobis Language no soporta XML FIN

RETURN 0
GO
