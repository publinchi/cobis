/************************************************************************/
/*  Archivo:                sp_busca_diferimiento.sp                    */
/*  Stored procedure:       sp_busca_diferimiento                       */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Xsell                                       */
/*  Disenado por:           Bruno Duenas                                */
/*  Fecha de escritura:     01-08-2022                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa define si una operacion de difierimiento debe ser    */
/*   marcada                                                            */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA       AUTOR           RAZON                                   */
/*  01-08-2022  BDU             Emision inicial                         */
/************************************************************************/

use cob_credito
go
if exists (select 1 from sysobjects where name = 'sp_busca_diferimiento')
   drop proc sp_busca_diferimiento
go

create proc sp_busca_diferimiento (
       @s_ssn                     int,
       @s_sesn                    int           = null,
       @s_user                    login         = null,
       @s_term                    varchar(32)   = null,
       @s_date                    datetime,
       @s_srv                     varchar(30)   = null,
       @s_lsrv                    varchar(30)   = null,
       @s_ofi                     smallint      = null,
       @s_rol                     smallint      = null,
       @s_org_err                 char(1)       = null,
       @s_error                   int           = null,
       @s_sev                     tinyint       = null,
       @s_msg                     descripcion   = null,
       @s_org                     char(1)       = null,
       @s_culture                 varchar(10)   = 'NEUTRAL',
       @t_debug                   char(1)       = 'n',
       @t_file                    varchar(10)   = null,
       @t_from                    varchar(32)   = null,
       @t_trn                     int           = null,
       @t_show_version            bit           = 0,     -- versionamiento
       @i_banco                   cuenta        = null,
       @o_reestructurar           char(1)       = null out
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_error                 int,
        @w_operacion             int,
        @w_tramite               int,
        @w_fecha_actual          datetime,
        @w_param                 int,
        @w_oper_rel              cuenta
        
/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_credito..sp_busca_diferimiento'

/*VALIDACIONES*/
if @i_banco is null
begin
   return 601001
end


select @w_param = pa_int
from cobis..cl_parametro
where pa_nemonico = 'OPEREL'
and   pa_producto = 'CRE'

select @w_fecha_actual = getdate()
select @o_reestructurar = 'N'

declare  paso_cursor cursor read_only 
for
select tr_tramite 
from cob_cartera..ca_operacion, 
     cob_workflow..wf_inst_proceso,
     cob_credito..cr_tramite
where op_tramite       = io_campo_3
and   op_estado        in (99)
and   io_estado        in ('TER')
and   tr_tramite       = op_tramite
and   io_fecha_fin     between dateadd(month, -1, @w_fecha_actual) and @w_fecha_actual
and   io_campo_4       in (select CAT.codigo from cobis..cl_catalogo as CAT, 
                                                  cobis..cl_tabla as TAB
                           where TAB.codigo = CAT.tabla
                           and   TAB.tabla  = 'cr_flujo_reestructura')

open  paso_cursor fetch paso_cursor into  @w_tramite
while @@fetch_status = 0
begin
select @w_oper_rel = fpv_value
from   cob_fpm..fp_fieldsbyproductvalues
where  dc_fields_idfk  = @w_param
and    fpv_request     = @w_tramite

if convert(varchar, @w_oper_rel) = convert(varchar, @i_banco)
begin
   select @o_reestructurar = 'S'
   break
end

fetch next from paso_cursor into @w_tramite
end
close paso_cursor
deallocate paso_cursor


return 0

