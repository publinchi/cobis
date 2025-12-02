/************************************************************************/
/*  Archivo:              7x24reperr.sp                                 */
/*  Stored procedure:     sp_7x24_reporte_errores                       */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         William Lopez                                 */
/*  Fecha de escritura:   21/Dic/2022                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCORP.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCORP para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  Genera reporte de errores para fuera de linea de cartera            */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR                   RAZON                         */
/*  21/Dic/2022   William Lopez           Emision Inicial               */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_7x24_reporte_errores' and type = 'P')
    drop procedure sp_7x24_reporte_errores
go

create procedure sp_7x24_reporte_errores
(
   @i_sarta           int      = null,    
   @i_batch           int      = null,
   @i_secuencial      int      = null,
   @i_corrida         int      = null,
   @i_intento         int      = null,
   @i_fecha_proceso   datetime = null,
   @i_param1          datetime         --Fecha proceso
)
as 
declare
   @w_sp_name         varchar(65),    
   @w_return          int,
   @w_retorno_ej      int,
   @w_error           int,
   @w_fecha           datetime,
   @w_path_destino    varchar(255),
   @w_sql             varchar(255),
   @w_tipo_bcp        varchar(10), 
   @w_nom_servidor    varchar(100),
   @w_mensaje         varchar(1000),
   @w_archivo         varchar(255),
   @w_separador       varchar(2),
   @w_nombre_arch     varchar(255),
   @w_nombre_fuente   varchar(255),
   @w_extension       varchar(10),
   @w_charcero        varchar(16),
   @w_dia             varchar(2),
   @w_mes             varchar(2),
   @w_anio            varchar(4),
   @w_hora            varchar(2),
   @w_min             varchar(2),
   @w_fecha_hor_arch  varchar(20),
   @w_columnas        varchar(1000),
   @w_sarta           int,
   @w_batch           int,
   @w_fecha_cierre    datetime,
   @w_cod_prod_cca    int

select @w_sp_name      = 'sp_7x24_reporte_errores',
       @w_error        = 0,
       @w_return       = 0,
       @w_sql          = '',
       @w_path_destino = '',
       @w_mensaje      = '',
       @w_separador    = '|',
       @w_fecha        = @i_param1,
       @w_columnas     = '',
       @w_nombre_arch  = '',
       @w_nombre_fuente= 'err_fuera_linea',
       @w_extension    = 'txt',
       @w_tipo_bcp     = 'queryout',
       @w_nom_servidor = ''

select @w_dia       = convert(varchar(2),datepart(dd,@w_fecha))
select @w_charcero  = replicate('0',2-len(ltrim(rtrim(@w_dia))))
select @w_dia       = @w_charcero + @w_dia
select @w_mes       = convert(varchar(2),datepart(mm,@w_fecha))
select @w_charcero  = replicate('0',2-len(ltrim(rtrim(@w_mes))))
select @w_mes       = @w_charcero + @w_mes
select @w_anio      = convert(varchar(4),datepart(yy,@w_fecha))
select @w_hora      = substring(convert(varchar(8),getdate(), 108), 1, 2)
select @w_charcero  = replicate('0',2-len(ltrim(rtrim(@w_hora))))
select @w_hora      = @w_charcero + @w_hora
select @w_min       = substring(convert(varchar(8),getdate(), 108), 4, 2)
select @w_charcero  = replicate('0',2-len(ltrim(rtrim(@w_min))))
select @w_min       = @w_charcero + @w_min

select @w_fecha_hor_arch = @w_mes + @w_dia + @w_anio + @w_hora + @w_min

select @w_path_destino = ba_path_destino
from   cobis..ba_batch
where  ba_producto    = 7
and    ba_arch_fuente = 'cob_cartera..sp_7x24_reporte_errores'

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from   cobis..ba_log,
       cobis..ba_batch
where  ba_arch_fuente like '%sp_7x24_obtencion_saldos%'
and    lo_batch   = ba_batch
and    lo_estatus = 'E'

--parametro de nombre de servidor central
select @w_nom_servidor = isnull(pa_char,'')
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'SCVL'

-- Código de producto CCA
select @w_cod_prod_cca = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'CCA'
   
-- Fecha de Proceso
select @w_fecha_cierre = fc_fecha_cierre 
from   cobis..ba_fecha_cierre
where  fc_producto = @w_cod_prod_cca

if @w_fecha in (null,'')
   select @w_fecha = @w_fecha_cierre

if exists (select 1 from sysobjects where name = 'ca_rep_err_bcp_tmp') 
   drop table ca_rep_err_bcp_tmp

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al borrar tabla ca_rep_err_bcp_tmp',
          @w_return  = @w_error
   goto ERROR
end

create table ca_rep_err_bcp_tmp (
 re_secuencial  int identity,
 re_registro    varchar(2000) null
)

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al crear tabla ca_rep_err_bcp_tmp',
          @w_return  = @w_error
   goto ERROR
end

--Insercion de encabezados

select @w_columnas = 'FECHA_PROCESO' +@w_separador+ 'FECHA_REAL'   +@w_separador+ 'USUARIO'    +@w_separador+
                     'TERMINAL'      +@w_separador+ 'SESION'       +@w_separador+ 'TIPO_OPER'  +@w_separador+
                     'COD_COLECTOR'  +@w_separador+ 'NUM_CTA_BAN'  +@w_separador+ 'BOLETA'     +@w_separador+
                     'OP_CARTERA'    +@w_separador+ 'MONTO_PAGO'   +@w_separador+ 'FECHA_PAGO' +@w_separador+
                     'NUM_ERROR'

insert into ca_rep_err_bcp_tmp(
       re_registro
       )
values(
       @w_columnas
       )

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al insertar encabezados tabla ca_rep_err_bcp_tmp',
          @w_return  = @w_error
   goto ERROR
end

--Insercion detalle
insert into ca_rep_err_bcp_tmp(re_registro)
select concat(
       convert(varchar,er_fecha_proceso,101),@w_separador,  --FECHA_PROCESO
       convert(varchar,er_fecha_real,101),@w_separador,     --FECHA_REAL
       er_user,@w_separador,                                --USUARIO
       er_term,@w_separador,                                --TERMINAL
       convert(varchar,er_sesion),@w_separador,             --SESION
       er_operacion,@w_separador,                           --TIPO_OPER
       convert(varchar,er_idcolector),@w_separador,         --COD_COLECTOR
       er_numcuentacolector,@w_separador,                   --NUM_CTA_BAN
       er_idreferencia,@w_separador,                        --BOLETA
       er_reference,@w_separador,                           --OP_CARTERA
       convert(varchar,er_amounttopay),@w_separador,        --MONTO_PAGO
       convert(varchar,er_fecha_pago,101),@w_separador,     --FECHA_PAGO
       convert(varchar,er_num_error)                        --NUM_ERROR
             )
from   cob_cartera..ca_7x24_errores
where  er_fecha_proceso = @i_param1

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al insertar detalle tabla ca_rep_err_bcp_tmp',
          @w_return  = @w_error
   goto ERROR
end

--nombre de archivo y ruta
select @w_nombre_arch = @w_path_destino + @w_nombre_fuente + '_' + @w_fecha_hor_arch + '.' + @w_extension

--sentencia sql para BCP
select @w_sql = 'select re_registro from cob_cartera..ca_rep_err_bcp_tmp order by re_secuencial'

--Ejecucion de BCP
if exists(select 1 
          from   ca_rep_err_bcp_tmp)
begin

   exec @w_return       = cobis..sp_bcp_archivos
        @i_sql          = @w_sql,         --select o nombre de tabla para generar archivo plano
        @i_tipo_bcp     = @w_tipo_bcp,    --tipo de bcp in,out,queryout
        @i_rut_nom_arch = @w_nombre_arch, --ruta y nombre de archivo
        @i_separador    = @w_separador,   --separador
        @i_nom_servidor = @w_nom_servidor --nombre de servidor donde se procesa bcp
   
   if @w_return != 0
   begin
      select @w_mensaje = 'Error al generar bcp cobis..sp_bcp_archivos'
      goto ERROR
   end

end

return @w_return

ERROR:
   exec @w_retorno_ej = cobis..sp_ba_error_log
        @i_sarta      = @w_sarta,
        @i_batch      = @w_batch,
        @i_secuencial = @i_secuencial,
        @i_corrida    = @i_corrida,
        @i_intento    = @i_intento,
        @i_error      = @w_return,
        @i_detalle    = @w_mensaje       
      
   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_return
   end
go
