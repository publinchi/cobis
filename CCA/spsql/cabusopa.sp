/************************************************************************/
/*  Archivo:            cabusopa.sp                                     */
/*  Stored procedure:   sp_buscar_op_act                                */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:       Gabriel Alvis                                   */
/*  Fecha de escritura: 21/Oct/2010                                     */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA'.                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Consulta de operaciones activas dado un codigo de cliente           */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA         AUTOR             RAZON                               */
/************************************************************************/

use cob_cartera
go

if object_id('sp_buscar_op_act') is not null
   drop proc sp_buscar_op_act
go

create proc sp_buscar_op_act
@t_debug          char(1)      = 'N',
@t_file           varchar(10)  = null,
@i_ente           int          = null,
@i_formato_fecha  tinyint      = 101
as

declare
@w_error                  int,
@w_sp_name                varchar(32)
   
-- CONDICIONES INICIALES
select 
@w_sp_name = 'sp_buscar_op_act',
@w_error   = 0

-- VALIDACION DE REQUISITOS
if @i_ente is null
begin
   select @w_error = 2101001
   goto ERROR
end

-- CONSULTA DE OPERACIONES ACTIVAS
select 

'Lin. Credito'    = op_toperacion,
'No. Operacion'   = op_banco,
'Monto Operacion' = op_monto,
'Cliente'         = op_nombre,
'Desembolso'      = convert(varchar(10), op_fecha_liq, @i_formato_fecha),
'Vencimiento'     = convert(varchar(10), op_fecha_fin, @i_formato_fecha),
'Ejecutivo'       = (select fu_nombre from cobis..cc_oficial, cobis..cl_funcionario where oc_oficial = op_oficial and fu_funcionario = oc_funcionario),
'Oficina'         = (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
'Cup. Credito'    = op_lin_credito,
'Op. Migrada'     = op_migrada,
'Op. Anterior'    = op_anterior,
'Estado'          = es_descripcion,
'Tramite'         = op_tramite
from ca_operacion (nolock), ca_estado
where op_cliente     = @i_ente
and   op_naturaleza  = 'A'             -- OPERACIONES DE NATURALEZA CONTABLE ACTIVA
and   op_tipo       <> 'G'             -- OPERACIONES NO FNG
and   op_estado      = es_codigo
and   es_procesa     = 'S'             -- OPERACIONES ACTIVAS (QUE PROCESAN)


return 0

ERROR:

exec cobis..sp_cerror
@t_debug  = @t_debug,
@t_file   = @t_file,
@t_from   = @w_sp_name,
@i_num    = @w_error

return 1
go
