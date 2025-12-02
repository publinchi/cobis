/***********************************************************************/
/*    Archivo:                          cr_conco.sp                    */
/*    Stored procedure:                 sp_concordato                  */
/*    Base de Datos:                    cob_credito                    */
/*    Disenado por:                     M. Davila                      */
/*    Producto:                         CONSOLIDADOR                   */
/*    Fecha de Documentacion:           29/Jun/1998                    */
/***********************************************************************/
/*                          IMPORTANTE                                 */
/*    Este programa es parte de los paquetes bancarios propiedad de    */
/*    'MACOSA',representantes exclusivos para el Ecuador de la         */
/*    AT&T                                                             */
/*    Su uso no autorizado queda expresamente prohibido asi como       */
/*    cualquier autorizacion o agregado hecho por alguno de sus        */
/*    usuario sin el debido consentimiento por escrito de la           */
/*    Presidencia Ejecutiva de MACOSA o su representante               */
/***********************************************************************/
/*                          PROPOSITO                                  */
/*    Este stored procedure nos permitirÿ modificar la                 */
/*    situaci½n de un cliente, y registrarlo en la tablas              */
/*      cr_concordato, cobis..cl_ente y cr_estados_concordato          */
/*                                                                     */
/***********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_concordato')
    drop proc sp_concordato
go
create proc sp_concordato (
   @s_date                 datetime    = null,
   @s_user                 login       = null,
   @s_ssn                  int         = null,
   @s_sesn                 int         = null,
   @s_term                 descripcion = null,
   @s_srv                  varchar(30) = null,
   @s_lsrv                 varchar(30) = null,
   @s_ofi                  smallint    = null,
   @i_operacion            char(1)     = null,
   @t_trn                  smallint    = null,
   @t_rty                  char(1)     = null,
   @i_cliente              int         = null,
   @i_situacion            catalogo    = null,
   @i_estado               catalogo    = null,
   @i_fecha                datetime    = null,
   @i_fecha_fin            datetime    = null,
   @i_cumplimiento         char(1)     = null,
   @i_modo                 tinyint     = null,
   @i_situacion_anterior   catalogo    = null,
   @i_acta_cas             catalogo    = null,
   @i_fecha_cas            datetime    = null,
   @i_causal               catalogo    = null,
   @i_user                 login       = null,
   @i_en_linea             char(1)     = 'S',
   @o_msg                  varchar(100)= null   out
)

as

declare
   @w_error             int,
   @w_sp_name           varchar(32),   /* NOMBRE STORED PROCEDURE */
   @w_existe            tinyint,
   @w_secuencial        int,
   @w_nombre            varchar(254),
   @w_situacion         catalogo,
   @w_desc_situacion    descripcion,
   @w_desc_estado       descripcion,
   @w_fecha             datetime,
   @w_fecha_fin         datetime,
   @w_cumplimiento      char(1),
   @w_estado            catalogo,
   @w_sitc              catalogo,
   @w_esth              catalogo,
   @w_esta              catalogo,
   @w_estado_ant        catalogo,
   @w_situac_ant        catalogo,
   @w_fini_ant          datetime,
   @w_ffin_ant          datetime,
   @w_rficod            catalogo,   --SBU situacion cliente
   @w_rfmcod            catalogo,
   @w_rfidesc           varchar(255),
   @w_rfmdesc           varchar(255),
   @w_refinh            char(1),
   @w_refmer            char(1),
   @w_sit_cli           catalogo,
   @w_acta_cas          catalogo,
   @w_fecha_cas         datetime,
   @w_causal            catalogo,
   @w_desc_causal       descripcion,
   @w_sitpc             varchar(30),
   @w_sitcs             varchar(30),
   @w_cn_situac_ant     catalogo,
   @w_cn_estado_ant     catalogo,
   @w_cn_fini_ant       datetime,
   @w_cn_ffin_ant       datetime,
   @w_cn_cumplimiento   char,
   @w_cn_situacant_ant  catalogo,
   @w_cn_fmodif_ant     datetime,
   @w_cn_acta_ant       catalogo,
   @w_cn_fcas_ant       datetime,
   @w_cn_causal         catalogo,
   @w_contador          int,
   @w_mensaje           varchar(255),
   @w_codigo_externo    varchar(64),
   @w_rowcount          int,
   @w_commit            char(1)


/* INICIAR VARIABLES DE TRABAJO */
select 
@w_sp_name = 'sp_concordato',
@w_existe  = 0,
@w_refinh  = 'N',
@w_refmer  = 'N',
@w_commit  = 'N'


/* SELECCION DE PARAMETROS */
select @w_sitc = pa_char
from cobis..cl_parametro
where pa_nemonico  = 'SITC'
and pa_producto    = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2101084, @o_msg = 'NO SE ENCUENTRA EL PARAMETRO GENERAL sitc DE CREDITO'
   goto ERRORFIN
end

select @w_esta = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ESTA'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2101084, @o_msg = 'NO SE ENCUENTRA EL PARAMETRO GENERAL esta DE CREDITO'
   goto ERRORFIN
end

select @w_esth = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ESTH'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2101084, @o_msg = 'NO SE ENCUENTRA EL PARAMETRO GENERAL esth DE CREDITO'
   goto ERRORFIN
end

select @w_sitpc = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SITPC'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2101084, @o_msg = 'NO SE ENCUENTRA EL PARAMETRO GENERAL sitpc DE CREDITO'
   goto ERRORFIN
end

/* SELECCION DE PARAMETROS */
select @w_sitcs = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SITCS'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2101084, @o_msg = 'NO SE ENCUENTRA EL PARAMETRO GENERAL sitcs DE CREDITO'
   goto ERRORFIN
end

/* CHEQUEO DE LA EXISTENCIA DE LOS CAMPOS */
if exists (select 1 from cr_concordato where cn_cliente = @i_cliente)
   select @w_existe = 1
else
   select @w_existe = 0


/* VERIFICAR SI SITUACION AMERITA GENERAR REFERENCIA INHIBITORIA */
select 
@w_rficod = codigo_sib,
@w_rfidesc = descripcion_sib
from cr_corresp_sib
where codigo = @i_situacion
and   tabla = 'T14'

if @@rowcount <> 0  select @w_refinh = 'S'



/* VERIFICAR SI SITUACION AMERITA GENERAR REFERENCIA DE MERCADO */
select 
@w_rfmcod = codigo_sib,
@w_rfmdesc = descripcion_sib
from cr_corresp_sib
where codigo = @i_situacion
and   tabla  = 'T15'

if @@rowcount <> 0  select @w_refmer = 'S'


return 0

ERRORFIN:

if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end

if @i_en_linea = 'S' begin
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @o_msg
end

return 1
go


