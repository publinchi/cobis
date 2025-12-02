/************************************************************************/
/*  Archivo:                xml_cuestionario.sp                         */
/*  Stored procedure:       sp_xml_cuestionario                         */
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

if exists (select 1 from sysobjects where name = 'sp_xml_cuestionario' and type = 'P')
   drop proc sp_xml_cuestionario
go


create proc sp_xml_cuestionario (
    @i_inst_proc  int         = NULL
)
as
declare
    @w_tramite             INT,
    @w_cod_entidad         VARCHAR(10),
    @w_max_si_sincroniza   INT,
    @w_fecha_proceso       DATETIME,
    @w_des_entidad         VARCHAR(64),
    @w_accion              VARCHAR(255),
    @w_observacion         VARCHAR(255),
    @w_error               INT,
    @w_sp_name             VARCHAR(32),
    @w_msg                 VARCHAR(100),
    @w_user                login,
    @w_toperacion          catalogo,
    @w_cliente             int,
    @w_nombre_cl           varchar(64),
    @w_grupal              bit,
    @w_filas               int,
    @w_oficial             smallint,
    @w_oficial_superior    smallint

select @w_sp_name = 'sp_xml_cuestionario'

SET ROWCOUNT 0

--Fecha de Proceso
SELECT @w_fecha_proceso = fp_fecha FROM cobis..ba_fecha_proceso

print 'error 1'
--Tramite
SELECT @w_tramite = io_campo_3 FROM cob_workflow..wf_inst_proceso WHERE io_id_inst_proc = @i_inst_proc
if @@rowcount = 0
begin
    select @w_error = 150000 -- ERROR EN INSERCION,
    select @w_msg = 'No existe informacion para esa instancia de proceso'
    goto ERROR
end

IF EXISTS(SELECT 1 FROM cob_credito..cr_tramite WHERE tr_tramite = @w_tramite AND tr_grupal = 'S') -- GRUPAL
    SELECT @w_grupal = 1  -- GRUPAL
else
    SELECT @w_grupal = 0 -- INDIVIDUAL

---Número de operacion
print 'error 2'
SELECT @w_toperacion = op_toperacion,
       @w_oficial    = op_oficial,
       @w_cliente    = op_cliente,
       @w_nombre_cl  = op_nombre
FROM cob_cartera..ca_operacion OP WHERE op_tramite = @w_tramite

--Encuentro el oficial superior del oficial

SELECT @w_oficial_superior = oc_ofi_nsuperior
FROM cobis..cc_oficial, cobis..cl_funcionario
WHERE oc_funcionario = fu_funcionario
AND oc_oficial = @w_oficial


--Toma el login del coordinador superior
select @w_user = fu_login
from  cobis..cl_funcionario, cobis..cc_oficial
where oc_oficial = @w_oficial_superior
and oc_funcionario = fu_funcionario

if @w_user is null
begin
    select @w_error = 150000 -- ERROR EN INSERCION,
    select @w_msg = 'No existe Coordinador del Oficial'
    goto ERROR
end

-- Comentarios
SELECT @w_accion = 'INGRESAR'
-- Observaciones
declare @w_aa_id_asig_act int, @w_texto varchar(max) = ''
select @w_aa_id_asig_act = io_campo_5
from cob_workflow..wf_inst_proceso where io_id_inst_proc = @i_inst_proc

select @w_observacion = @w_observacion + ' ' + ol_texto
from cob_workflow..wf_observaciones OB, cob_workflow..wf_ob_lineas OL
where OB.ob_id_asig_act = OL.ol_id_asig_act
and ob_id_asig_act = @w_aa_id_asig_act

SELECT @w_observacion = isnull(@w_observacion,'INGRESAR CUESTIONARIO')

if(@w_toperacion = 'GRUPAL')
    select @w_cod_entidad = 6    --Datos de la Entidad -- Grupal

if(@w_toperacion = 'INDIVIDUAL')
    select @w_cod_entidad = 7    --Datos de la Entidad -- Individual

print 'error 3'
SELECT @w_des_entidad = valor
FROM cobis..cl_catalogo
WHERE tabla = ( SELECT codigo  FROM cobis..cl_tabla
                WHERE tabla = 'si_sincroniza') AND codigo = @w_cod_entidad

if @w_des_entidad is null
begin
    select @w_error = 150000 -- ERROR EN INSERCION,
    select @w_msg = 'Tipo de operacion no corresponde a GRUPAL/INDIVIDUAL'
    goto ERROR
end

--Secuencial
exec @w_error = cobis..sp_cseqnos @t_from = @w_sp_name , @i_tabla = 'si_sincroniza' , @o_siguiente = @w_max_si_sincroniza out
if @w_error <> 0
begin
    goto ERROR
end

create table #tmp_items_xml (
sec    int,
value  varchar(200),
numero int not null
)


create table #tmp_deudores (
cliente  int,
resultado  varchar(255),
nombre     varchar(300),
rol        char(1)
)

print 'error 4'

-- Insert en si_sincroniza
INSERT INTO cob_sincroniza..si_sincroniza (si_secuencial,            si_cod_entidad, si_des_entidad,
                                           si_usuario,               si_estado,      si_fecha_ing,
                                           si_fecha_sin,             si_num_reg)
       VALUES                             (@w_max_si_sincroniza,     @w_cod_entidad, @w_des_entidad,
                                           @w_user,                  'P',            @w_fecha_proceso,
                                           NULL,                     1)
if @@error <> 0
begin
    select @w_error = 150000 -- ERROR EN INSERCION
    select @w_msg = 'Insertar en si_sincroniza'
    goto ERROR
end

print 'error 5'
-- Insert en si_sincroniza_det
exec @w_error = sp_xml_cuestionario_det
    @i_fecha_proceso     = @w_fecha_proceso,
    @i_max_si_sincroniza = @w_max_si_sincroniza,
    @i_inst_proc         = @i_inst_proc,
    @i_tramite           = @w_tramite,
    @i_cliente           = @w_cliente,
    @i_nombre_cl         = @w_nombre_cl,
    @i_grupal            = @w_grupal,
    @i_accion            = @w_accion,
    @i_observacion       = @w_observacion,
    @o_filas             = @w_filas output

if @w_error <> 0
begin
    select @w_error = 150000 -- ERROR EN INSERCION,
    select @w_msg = 'Al ejecutra sp_xml_cuestionario_det'
    goto ERROR
end

if @w_filas<>0
    update cob_sincroniza..si_sincroniza set
    si_num_reg = @w_filas
    where si_secuencial = @w_max_si_sincroniza
else
    DELETE FROM  cob_sincroniza..si_sincroniza
    WHERE si_secuencial = @w_max_si_sincroniza

return 0

ERROR:
    begin --Devolver mensaje de Error
        exec cobis..sp_cerror
             @t_debug = 'N',
             @t_file  = 'S',
             @t_from  = @w_sp_name,
             @i_num   = @w_error,
             @i_msg   = @w_msg
        return @w_error
    end


GO
