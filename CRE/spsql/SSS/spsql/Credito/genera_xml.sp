/************************************************************************/
/*      Archivo:                genera_xml.sp                           */
/*      Stored procedure:       sp_genera_xml                           */
/*      Base de datos:          cob_credito                             */
/*      Producto:               CREDITO                                 */
/*      Disenado por:           Jose Escobar                            */
/*      Fecha de escritura:     22-May-2019                             */
/************************************************************************/
/*                            IMPORTANTE                                */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de 'COBISCorp'.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                             PROPOSITO                                */
/*  Genera en dato XML para la sicronizaciOn                            */
/*                                                                      */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*    FECHA           AUTOR            RAZON                            */
/*  22/05/2019      José Escobar    Emisión Inicial                     */
/************************************************************************/
use cob_credito
go
if exists (select 1 from sysobjects where name = 'sp_genera_xml')
   drop proc sp_genera_xml
go
create proc sp_genera_xml (
    @i_operacion         char(1),
    @i_modo              char(1) = null,
    @i_inst_proc         int     = null,
    @i_tramite           int     = null,
    @i_cliente           int     = null--, --LPO CDIG Se comenta porque Cobis Language no soporta XML
--    @o_xml               XML     = null out --LPO CDIG Se comenta porque Cobis Language no soporta XML
)as

--LPO CDIG Se comenta porque Cobis Language no soporta XML INICIO
/*
declare @w_xml XML

if @i_operacion = 'I'
begin
    select @w_xml = (
        SELECT tag, parent,
               [individualApplication!1!valor],      --1

               [instProc!2!valor],                   --2
               [instProc!2!codigo!ELEMENT],          --3 io_id_inst_proc
               [instProc!2!fechaCrea!ELEMENT],       --4 io_fecha_crea
               [instProc!2!cliente!ELEMENT],         --5 @i_cliente
               [instProc!2!tramite!ELEMENT],         --6 io_campo_3
               [instProc!2!producto!ELEMENT],        --7 io_campo_4
               [instProc!2!refeencia!ELEMENT],       --8 io_codigo_alterno
               [instProc!2!usuario!ELEMENT],         --9 io_usuario_crea

               [tramite!3!valor],                    --10
               [tramite!3!codigo!ELEMENT],           --11 @i_tramite
               [tramite!3!tipo!ELEMENT],             --12 tr_tipo
               [tramite!3!oficina!ELEMENT],          --13 tr_oficina
               [tramite!3!fechaCrea!ELEMENT],        --14 tr_fecha_crea
               [tramite!3!oficial!ELEMENT],          --15 tr_oficial
               [tramite!3!sector!ELEMENT],           --16 tr_sector
               [tramite!3!estado!ELEMENT],           --17 tr_estado
               [tramite!3!cliente!ELEMENT],          --18 tr_cliente
               [tramite!3!fechaInicio!ELEMENT],      --19 tr_fecha_inicio
               [tramite!3!operacion!ELEMENT],        --20 tr_toperacion
               [tramite!3!producto!ELEMENT],         --21 tr_producto
               [tramite!3!monto!ELEMENT],            --22 tr_monto
               [tramite!3!moneda!ELEMENT],           --23 tr_moneda
               [tramite!3!destino!ELEMENT],          --24 tr_destino
               [tramite!3!plazo!ELEMENT],            --25 tr_plazo
               [tramite!3!fechaDispersion!ELEMENT],  --26 tr_fecha_dispersion
               [tramite!3!tplazo!ELEMENT],           --27 tr_tplazo

               [operacion!4!valor],                  --28
               [operacion!4!codigo!ELEMENT],         --29 op_operacion
               [operacion!4!banco!ELEMENT],          --30 op_banco
               [operacion!4!sector!ELEMENT],         --31 op_sector
               [operacion!4!toperacion!ELEMENT],     --32 op_toperacion
               [operacion!4!moneda!ELEMENT],         --33 op_moneda
               [operacion!4!monto!ELEMENT],          --34 op_monto
               [operacion!4!destino!ELEMENT],        --35 op_destino
               [operacion!4!tipoTabla!ELEMENT],      --36 op_tipo_amortizacion
               [operacion!4!plazo!ELEMENT],          --37 op_plazo
               [operacion!4!tplazo!ELEMENT],         --38 op_tplazo

               [cliente!5!valor],                    --39
               [cliente!5!ente!ELEMENT],             --40 en_ente
               [cliente!5!nomlar!ELEMENT],           --41 en_nomlar
               [cliente!5!tipoIdent!ELEMENT],        --42 en_tipo_ced
               [cliente!5!identificacion!ELEMENT]    --43 en_ced_ruc
        FROM  (
            SELECT 1 AS tag, NULL AS parent,
                   NULL AS [individualApplication!1!valor],      --1

                   NULL AS [instProc!2!valor],                   --2
                   NULL AS [instProc!2!codigo!ELEMENT],          --3 io_id_inst_proc
                   NULL AS [instProc!2!fechaCrea!ELEMENT],       --4 io_fecha_crea
                   NULL AS [instProc!2!cliente!ELEMENT],         --5 @i_cliente
                   NULL AS [instProc!2!tramite!ELEMENT],         --6 io_campo_3
                   NULL AS [instProc!2!producto!ELEMENT],        --7 io_campo_4
                   NULL AS [instProc!2!refeencia!ELEMENT],       --8 io_codigo_alterno
                   NULL AS [instProc!2!usuario!ELEMENT],         --9 io_usuario_crea

                   NULL AS [tramite!3!valor],                    --10
                   NULL AS [tramite!3!codigo!ELEMENT],           --11 @i_tramite
                   NULL AS [tramite!3!tipo!ELEMENT],             --12 tr_tipo
                   NULL AS [tramite!3!oficina!ELEMENT],          --13 tr_oficina
                   NULL AS [tramite!3!fechaCrea!ELEMENT],        --14 tr_fecha_crea
                   NULL AS [tramite!3!oficial!ELEMENT],          --15 tr_oficial
                   NULL AS [tramite!3!sector!ELEMENT],           --16 tr_sector
                   NULL AS [tramite!3!estado!ELEMENT],           --17 tr_estado
                   NULL AS [tramite!3!cliente!ELEMENT],          --18 tr_cliente
                   NULL AS [tramite!3!fechaInicio!ELEMENT],      --19 tr_fecha_inicio
                   NULL AS [tramite!3!operacion!ELEMENT],        --20 tr_toperacion
                   NULL AS [tramite!3!producto!ELEMENT],         --21 tr_producto
                   NULL AS [tramite!3!monto!ELEMENT],            --22 tr_monto
                   NULL AS [tramite!3!moneda!ELEMENT],           --23 tr_moneda
                   NULL AS [tramite!3!destino!ELEMENT],          --24 tr_destino
                   NULL AS [tramite!3!plazo!ELEMENT],            --25 tr_plazo
                   NULL AS [tramite!3!fechaDispersion!ELEMENT],  --26 tr_fecha_dispersion
                   NULL AS [tramite!3!tplazo!ELEMENT],           --27 tr_tplazo

                   NULL AS [operacion!4!valor],                  --28
                   NULL AS [operacion!4!codigo!ELEMENT],         --29 op_operacion
                   NULL AS [operacion!4!banco!ELEMENT],          --30 op_banco
                   NULL AS [operacion!4!sector!ELEMENT],         --31 op_sector
                   NULL AS [operacion!4!toperacion!ELEMENT],     --32 op_toperacion
                   NULL AS [operacion!4!moneda!ELEMENT],         --33 op_moneda
                   NULL AS [operacion!4!monto!ELEMENT],          --34 op_monto
                   NULL AS [operacion!4!destino!ELEMENT],        --35 op_destino
                   NULL AS [operacion!4!tipoTabla!ELEMENT],      --36 op_tipo_amortizacion
                   NULL AS [operacion!4!plazo!ELEMENT],          --37 op_plazo
                   NULL AS [operacion!4!tplazo!ELEMENT],         --38 op_tplazo

                   NULL AS [cliente!5!valor],                    --39
                   NULL AS [cliente!5!ente!ELEMENT],             --40 en_ente
                   NULL AS [cliente!5!nomlar!ELEMENT],           --41 en_nomlar
                   NULL AS [cliente!5!tipoIdent!ELEMENT],        --42 en_tipo_ced
                   NULL AS [cliente!5!identificacion!ELEMENT]    --43 en_ced_ruc
            UNION
            SELECT 2 AS tag, 1 AS parent,
                   NULL AS [individualApplication!1!valor],      --1

                   NULL              AS [instProc!2!valor],              --2
                   io_id_inst_proc   AS [instProc!2!codigo!ELEMENT],     --3 io_id_inst_proc
                   io_fecha_crea     AS [instProc!2!fechaCrea!ELEMENT],  --4 io_fecha_crea
                   @i_cliente        AS [instProc!2!cliente!ELEMENT],    --5 @i_cliente
                   io_campo_3        AS [instProc!2!tramite!ELEMENT],    --6 io_campo_3
                   io_campo_4        AS [instProc!2!producto!ELEMENT],   --7 io_campo_4
                   io_codigo_alterno AS [instProc!2!refeencia!ELEMENT],  --8 io_codigo_alterno
                   io_usuario_crea   AS [instProc!2!usuario!ELEMENT],    --9 io_usuario_crea

                   NULL AS [tramite!3!valor],                    --10
                   NULL AS [tramite!3!codigo!ELEMENT],           --11 @i_tramite
                   NULL AS [tramite!3!tipo!ELEMENT],             --12 tr_tipo
                   NULL AS [tramite!3!oficina!ELEMENT],          --13 tr_oficina
                   NULL AS [tramite!3!fechaCrea!ELEMENT],        --14 tr_fecha_crea
                   NULL AS [tramite!3!oficial!ELEMENT],          --15 tr_oficial
                   NULL AS [tramite!3!sector!ELEMENT],           --16 tr_sector
                   NULL AS [tramite!3!estado!ELEMENT],           --17 tr_estado
                   NULL AS [tramite!3!cliente!ELEMENT],          --18 tr_cliente
                   NULL AS [tramite!3!fechaInicio!ELEMENT],      --19 tr_fecha_inicio
                   NULL AS [tramite!3!operacion!ELEMENT],        --20 tr_toperacion
                   NULL AS [tramite!3!producto!ELEMENT],         --21 tr_producto
                   NULL AS [tramite!3!monto!ELEMENT],            --22 tr_monto
                   NULL AS [tramite!3!moneda!ELEMENT],           --23 tr_moneda
                   NULL AS [tramite!3!destino!ELEMENT],          --24 tr_destino
                   NULL AS [tramite!3!plazo!ELEMENT],            --25 tr_plazo
                   NULL AS [tramite!3!fechaDispersion!ELEMENT],  --26 tr_fecha_dispersion
                   NULL AS [tramite!3!tplazo!ELEMENT],           --27 tr_tplazo

                   NULL AS [operacion!4!valor],                  --28
                   NULL AS [operacion!4!codigo!ELEMENT],         --29 op_operacion
                   NULL AS [operacion!4!banco!ELEMENT],          --30 op_banco
                   NULL AS [operacion!4!sector!ELEMENT],         --31 op_sector
                   NULL AS [operacion!4!toperacion!ELEMENT],     --32 op_toperacion
                   NULL AS [operacion!4!moneda!ELEMENT],         --33 op_moneda
                   NULL AS [operacion!4!monto!ELEMENT],          --34 op_monto
                   NULL AS [operacion!4!destino!ELEMENT],        --35 op_destino
                   NULL AS [operacion!4!tipoTabla!ELEMENT],      --36 op_tipo_amortizacion
                   NULL AS [operacion!4!plazo!ELEMENT],          --37 op_plazo
                   NULL AS [operacion!4!tplazo!ELEMENT],         --38 op_tplazo

                   NULL AS [cliente!5!valor],                    --39
                   NULL AS [cliente!5!ente!ELEMENT],             --40 en_ente
                   NULL AS [cliente!5!nomlar!ELEMENT],           --41 en_nomlar
                   NULL AS [cliente!5!tipoIdent!ELEMENT],        --42 en_tipo_ced
                   NULL AS [cliente!5!identificacion!ELEMENT]    --43 en_ced_ruc
            FROM   cob_workflow..wf_inst_proceso
            WHERE  io_id_inst_proc = @i_inst_proc
            UNION
            SELECT 3 AS tag, 1 AS parent,
                   NULL AS [individualApplication!1!valor],       --1

                   NULL AS [instProc!2!valor],                   --2
                   NULL AS [instProc!2!codigo!ELEMENT],          --3 io_id_inst_proc
                   NULL AS [instProc!2!fechaCrea!ELEMENT],       --4 io_fecha_crea
                   NULL AS [instProc!2!cliente!ELEMENT],         --5 @i_cliente
                   NULL AS [instProc!2!tramite!ELEMENT],         --6 io_campo_3
                   NULL AS [instProc!2!producto!ELEMENT],        --7 io_campo_4
                   NULL AS [instProc!2!refeencia!ELEMENT],       --8 io_codigo_alterno
                   NULL AS [instProc!2!usuario!ELEMENT],         --9 io_usuario_crea

                   NULL AS [tramite!3!valor],                                  --10
                   @i_tramite      AS [tramite!3!codigo!ELEMENT],              --11 @i_tramite
                   tr_tipo         AS [tramite!3!tipo!ELEMENT],                --12 tr_tipo
                   tr_oficina      AS [tramite!3!oficina!ELEMENT],             --13 tr_oficina
                   tr_fecha_crea   AS [tramite!3!fechaCrea!ELEMENT],           --14 tr_fecha_crea
                   tr_oficial      AS [tramite!3!oficial!ELEMENT],             --15 tr_oficial
                   tr_sector       AS [tramite!3!sector!ELEMENT],              --16 tr_sector
                   tr_estado       AS [tramite!3!estado!ELEMENT],              --17 tr_estado
                   tr_cliente      AS [tramite!3!cliente!ELEMENT],             --18 tr_cliente
                   tr_fecha_inicio AS [tramite!3!fechaInicio!ELEMENT],         --19 tr_fecha_inicio
                   tr_toperacion   AS [tramite!3!operacion!ELEMENT],           --20 tr_toperacion
                   tr_producto     AS [tramite!3!producto!ELEMENT],            --21 tr_producto
                   tr_monto        AS [tramite!3!monto!ELEMENT],               --22 tr_monto
                   tr_moneda       AS [tramite!3!moneda!ELEMENT],              --23 tr_moneda
                   tr_destino      AS [tramite!3!destino!ELEMENT],             --24 tr_destino
                   tr_plazo        AS [tramite!3!plazo!ELEMENT],               --25 tr_plazo
                   tr_fecha_dispersion AS [tramite!3!fechaDispersion!ELEMENT], --26 tr_fecha_dispersion
                   tr_tplazo       AS [tramite!3!tplazo!ELEMENT],              --27 tr_tplazo

                   NULL AS [operacion!4!valor],                  --28
                   NULL AS [operacion!4!codigo!ELEMENT],         --29 op_operacion
                   NULL AS [operacion!4!banco!ELEMENT],          --30 op_banco
                   NULL AS [operacion!4!sector!ELEMENT],         --31 op_sector
                   NULL AS [operacion!4!toperacion!ELEMENT],     --32 op_toperacion
                   NULL AS [operacion!4!moneda!ELEMENT],         --33 op_moneda
                   NULL AS [operacion!4!monto!ELEMENT],          --34 op_monto
                   NULL AS [operacion!4!destino!ELEMENT],        --35 op_destino
                   NULL AS [operacion!4!tipoTabla!ELEMENT],      --36 op_tipo_amortizacion
                   NULL AS [operacion!4!plazo!ELEMENT],          --37 op_plazo
                   NULL AS [operacion!4!tplazo!ELEMENT],         --38 op_tplazo

                   NULL AS [cliente!5!valor],                    --39
                   NULL AS [cliente!5!ente!ELEMENT],             --40 en_ente
                   NULL AS [cliente!5!nomlar!ELEMENT],           --41 en_nomlar
                   NULL AS [cliente!5!tipoIdent!ELEMENT],        --42 en_tipo_ced
                   NULL AS [cliente!5!identificacion!ELEMENT]    --43 en_ced_ruc
            FROM   cob_credito..cr_tramite
            WHERE  tr_tramite = @i_tramite
            UNION
            SELECT 4 AS tag, 1 AS parent,
                   NULL AS [individualApplication!1!valor],      --1

                   NULL AS [instProc!2!valor],                   --2
                   NULL AS [instProc!2!codigo!ELEMENT],          --3 io_id_inst_proc
                   NULL AS [instProc!2!fechaCrea!ELEMENT],       --4 io_fecha_crea
                   NULL AS [instProc!2!cliente!ELEMENT],         --5 @i_cliente
                   NULL AS [instProc!2!tramite!ELEMENT],         --6 io_campo_3
                   NULL AS [instProc!2!producto!ELEMENT],        --7 io_campo_4
                   NULL AS [instProc!2!refeencia!ELEMENT],       --8 io_codigo_alterno
                   NULL AS [instProc!2!usuario!ELEMENT],         --9 io_usuario_crea

                   NULL AS [tramite!3!valor],                    --10
                   NULL AS [tramite!3!codigo!ELEMENT],           --11 @i_tramite
                   NULL AS [tramite!3!tipo!ELEMENT],             --12 tr_tipo
                   NULL AS [tramite!3!oficina!ELEMENT],          --13 tr_oficina
                   NULL AS [tramite!3!fechaCrea!ELEMENT],        --14 tr_fecha_crea
                   NULL AS [tramite!3!oficial!ELEMENT],          --15 tr_oficial
                   NULL AS [tramite!3!sector!ELEMENT],           --16 tr_sector
                   NULL AS [tramite!3!estado!ELEMENT],           --17 tr_estado
                   NULL AS [tramite!3!cliente!ELEMENT],          --18 tr_cliente
                   NULL AS [tramite!3!fechaInicio!ELEMENT],      --19 tr_fecha_inicio
                   NULL AS [tramite!3!operacion!ELEMENT],        --20 tr_toperacion
                   NULL AS [tramite!3!producto!ELEMENT],         --21 tr_producto
                   NULL AS [tramite!3!monto!ELEMENT],            --22 tr_monto
                   NULL AS [tramite!3!moneda!ELEMENT],           --23 tr_moneda
                   NULL AS [tramite!3!destino!ELEMENT],          --24 tr_destino
                   NULL AS [tramite!3!plazo!ELEMENT],            --25 tr_plazo
                   NULL AS [tramite!3!fechaDispersion!ELEMENT],  --26 tr_fecha_dispersion
                   NULL AS [tramite!3!tplazo!ELEMENT],           --27 tr_tplazo

                   NULL AS [operacion!4!valor],                             --28
                   op_operacion  AS [operacion!4!codigo!ELEMENT],           --29 op_operacion
                   op_banco      AS [operacion!4!banco!ELEMENT],            --30 op_banco
                   op_sector     AS [operacion!4!sector!ELEMENT],           --31 op_sector
                   op_toperacion AS [operacion!4!toperacion!ELEMENT],       --32 op_toperacion
                   op_moneda     AS [operacion!4!moneda!ELEMENT],           --33 op_moneda
                   op_monto      AS [operacion!4!monto!ELEMENT],            --34 op_monto
                   op_destino    AS [operacion!4!destino!ELEMENT],          --35 op_destino
                   op_tipo_amortizacion AS [operacion!4!tipoTabla!ELEMENT], --36 op_tipo_amortizacion
                   op_plazo      AS [operacion!4!plazo!ELEMENT],            --37 op_plazo
                   op_tplazo     AS [operacion!4!tplazo!ELEMENT],           --38 op_tplazo

                   NULL AS [cliente!5!valor],                    --39
                   NULL AS [cliente!5!ente!ELEMENT],             --40 en_ente
                   NULL AS [cliente!5!nomlar!ELEMENT],           --41 en_nomlar
                   NULL AS [cliente!5!tipoIdent!ELEMENT],        --42 en_tipo_ced
                   NULL AS [cliente!5!identificacion!ELEMENT]    --43 en_ced_ruc
            FROM   cob_cartera..ca_operacion
            WHERE  op_tramite = @i_tramite
            UNION
            SELECT 5 AS tag, 1 AS parent,
                   NULL AS [individualApplication!1!valor],      --1

                   NULL AS [instProc!2!valor],                   --2
                   NULL AS [instProc!2!codigo!ELEMENT],          --3 io_id_inst_proc
                   NULL AS [instProc!2!fechaCrea!ELEMENT],       --4 io_fecha_crea
                   NULL AS [instProc!2!cliente!ELEMENT],         --5 @i_cliente
                   NULL AS [instProc!2!tramite!ELEMENT],         --6 io_campo_3
                   NULL AS [instProc!2!producto!ELEMENT],        --7 io_campo_4
                   NULL AS [instProc!2!refeencia!ELEMENT],       --8 io_codigo_alterno
                   NULL AS [instProc!2!usuario!ELEMENT],         --9 io_usuario_crea

                   NULL AS [tramite!3!valor],                    --10
                   NULL AS [tramite!3!codigo!ELEMENT],           --11 @i_tramite
                   NULL AS [tramite!3!tipo!ELEMENT],             --12 tr_tipo
                   NULL AS [tramite!3!oficina!ELEMENT],          --13 tr_oficina
                   NULL AS [tramite!3!fechaCrea!ELEMENT],        --14 tr_fecha_crea
                   NULL AS [tramite!3!oficial!ELEMENT],          --15 tr_oficial
                   NULL AS [tramite!3!sector!ELEMENT],           --16 tr_sector
                   NULL AS [tramite!3!estado!ELEMENT],           --17 tr_estado
                   NULL AS [tramite!3!cliente!ELEMENT],          --18 tr_cliente
                   NULL AS [tramite!3!fechaInicio!ELEMENT],      --19 tr_fecha_inicio
                   NULL AS [tramite!3!operacion!ELEMENT],        --20 tr_toperacion
                   NULL AS [tramite!3!producto!ELEMENT],         --21 tr_producto
                   NULL AS [tramite!3!monto!ELEMENT],            --22 tr_monto
                   NULL AS [tramite!3!moneda!ELEMENT],           --23 tr_moneda
                   NULL AS [tramite!3!destino!ELEMENT],          --24 tr_destino
                   NULL AS [tramite!3!plazo!ELEMENT],            --25 tr_plazo
                   NULL AS [tramite!3!fechaDispersion!ELEMENT],  --26 tr_fecha_dispersion
                   NULL AS [tramite!3!tplazo!ELEMENT],           --27 tr_tplazo

                   NULL AS [operacion!4!valor],                  --28
                   NULL AS [operacion!4!codigo!ELEMENT],         --29 op_operacion
                   NULL AS [operacion!4!banco!ELEMENT],          --30 op_banco
                   NULL AS [operacion!4!sector!ELEMENT],         --31 op_sector
                   NULL AS [operacion!4!toperacion!ELEMENT],     --32 op_toperacion
                   NULL AS [operacion!4!moneda!ELEMENT],         --33 op_moneda
                   NULL AS [operacion!4!monto!ELEMENT],          --34 op_monto
                   NULL AS [operacion!4!destino!ELEMENT],        --35 op_destino
                   NULL AS [operacion!4!tipoTabla!ELEMENT],      --36 op_tipo_amortizacion
                   NULL AS [operacion!4!plazo!ELEMENT],          --37 op_plazo
                   NULL AS [operacion!4!tplazo!ELEMENT],         --38 op_tplazo

                   NULL        AS [cliente!5!valor],                  --39
                   en_ente     AS [cliente!5!ente!ELEMENT],           --40 en_ente
                   en_nomlar   AS [cliente!5!nomlar!ELEMENT],         --41 en_nomlar
                   en_tipo_ced AS [cliente!5!tipoIdent!ELEMENT],      --42 en_tipo_ced
                   en_ced_ruc  AS [cliente!5!identificacion!ELEMENT]  --43 en_ced_ruc
            FROM   cobis..cl_ente
            WHERE  en_ente = @i_cliente
    ) AS A FOR XML EXPLICIT )
    if @@error <> 0
    begin
        return 724625 -- ERROR: AL GENERAR ARCHIVO XML
    end

    set @o_xml = @w_xml
    return 0
end --@i_operacion = 'I'
*/
--LPO CDIG Se comenta porque Cobis Language no soporta XML FIN
RETURN 0
GO
