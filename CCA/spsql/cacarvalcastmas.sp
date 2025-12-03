/************************************************************************/
/*  Archivo:              cacarvalcastmas.sp                            */
/*  Stored procedure:     sp_carga_val_castigo_masivo                   */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         William Lopez                                 */
/*  Fecha de escritura:   17/Ene/2023                                   */
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
/*  Carga y validacion de operaciones de castigo masivo                 */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR                   RAZON                         */
/*  17/Ene/2023   William Lopez           Emision Inicial               */
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_carga_val_castigo_masivo' and type = 'P')
    drop procedure sp_carga_val_castigo_masivo
go

create procedure sp_carga_val_castigo_masivo
(
   @t_debug     char(1)      = 'N',
   @s_culture   varchar(10)  = 'NEUTRAL',
   @i_param1    datetime     --Fecha proceso
)
as 
declare
   @w_sp_name           varchar(65),    
   @w_return            int,
   @w_retorno_ej        int,
   @w_error             int,
   @w_fecha_proc        datetime,
   @w_path_destino      varchar(255),
   @w_sql               varchar(255),
   @w_tipo_bcp          varchar(10), 
   @w_nom_servidor      varchar(100),
   @w_mensaje           varchar(1000),
   @w_mensaje_err       varchar(255),
   @w_archivo           varchar(255),
   @w_separador         varchar(2),
   @w_nombre_arch       varchar(255),
   @w_nombre_fuente     varchar(255),
   @w_nombre_fuente_err varchar(255),
   @w_extension         varchar(10),
   @w_charcero          varchar(16),
   @w_dia               varchar(2),
   @w_mes               varchar(2),
   @w_anio              varchar(4),
   @w_hora              varchar(2),
   @w_min               varchar(2),
   @w_fecha_hor_arch    varchar(20),
   @w_columnas          varchar(1000),
   @w_sarta             int,
   @w_batch             int,
   @w_fecha_cierre      datetime,
   @w_cod_prod_cca      int,
   @w_secuencial        int      = null,
   @w_corrida           int      = null,
   @w_intento           int      = null,   
   @w_cm_fecha_proc     datetime,
   @w_cm_op_banco       cuenta,
   @w_cm_fecha_valor    datetime,
   @w_cm_secuencial     int,
   @w_est_vigente       smallint,
   @w_est_novigente     smallint,
   @w_est_credito       smallint,
   @w_est_cancelado     smallint,
   @w_est_anulado       smallint,
   @w_est_castigado     smallint,
   @w_est_vencido       smallint, 
   @w_op_operacion      int,
   @w_op_toperacion     catalogo,
   @w_op_cliente        int,
   @w_op_estado         tinyint,
   @w_op_fecha_ini      datetime,
   @w_op_fecha_ult_proc datetime,
   @w_di_fecha_ven      datetime,
   @w_num_dias_ven      int,
   @w_op_estado_fin     tinyint,
   @w_nom_columna       varchar(100)

select @w_sp_name           = 'sp_carga_val_castigo_masivo',
       @w_error             = 0,
       @w_return            = 0,
       @w_sql               = '',
       @w_path_destino      = '',
       @w_mensaje           = '',
       @w_mensaje_err       = null,
       @w_separador         = '|',
       @w_fecha_proc        = @i_param1,
       @w_columnas          = '',
       @w_nombre_arch       = '',
       @w_nombre_fuente     = 'castigo_masivo',
       @w_nombre_fuente_err = 'castigo_masivo_error',
       @w_extension         = 'csv',
       @w_tipo_bcp          = 'in',
       @w_nom_servidor      = ''

select @w_dia       = convert(varchar(2),datepart(dd,@w_fecha_proc))
select @w_charcero  = replicate('0',2-len(ltrim(rtrim(@w_dia))))
select @w_dia       = @w_charcero + @w_dia
select @w_mes       = convert(varchar(2),datepart(mm,@w_fecha_proc))
select @w_charcero  = replicate('0',2-len(ltrim(rtrim(@w_mes))))
select @w_mes       = @w_charcero + @w_mes
select @w_anio      = convert(varchar(4),datepart(yy,@w_fecha_proc))
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
and    ba_arch_fuente = 'cob_cartera..sp_carga_val_castigo_masivo'

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from   cobis..ba_log,
       cobis..ba_batch
where  ba_arch_fuente like '%sp_carga_val_castigo_masivo%'
and    lo_batch   = ba_batch
and    lo_estatus = 'E'

exec cobis..sp_ad_establece_cultura                                                                                                                                                                                                                         
   @o_culture = @s_culture out

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

if @w_fecha_proc in (null,'')
   select @w_fecha_proc = @w_fecha_cierre
   
--Estados de Cartera
exec @w_return = sp_estados_cca 
   @o_est_vigente   = @w_est_vigente   out, --1
   @o_est_novigente = @w_est_novigente out, --0
   @o_est_cancelado = @w_est_cancelado out, --3
   @o_est_credito   = @w_est_credito   out, --99
   @o_est_anulado   = @w_est_anulado   out, --6
   @o_est_castigado = @w_est_castigado out, --4
   @o_est_vencido   = @w_est_vencido   out  --2

select @w_error = @w_return
if @w_return != 0 or @@error != 0
begin

   exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = '',
      @t_from  = @w_sp_name,
      @i_num   = @w_return

   return @w_return
end   

--Tabla de trabajo de carga de archivo
if exists (select 1 from sysobjects where name = 'bcp_castigo_masivo_tmp') 
   drop table bcp_castigo_masivo_tmp

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al borrar tabla bcp_castigo_masivo_tmp',
          @w_return  = @w_error
   goto ERROR
end

create table bcp_castigo_masivo_tmp(
   cm_fecha_proc    datetime,
   cm_op_banco      cuenta,
   cm_fecha_valor   datetime
)
select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al crear tabla bcp_castigo_masivo_tmp',
          @w_return  = @w_error
   goto ERROR
end

--nombre de archivo de entrada y ruta
select @w_nombre_arch = @w_path_destino + @w_nombre_fuente + '.' + @w_extension

--sentencia sql para BCP
select @w_sql = 'cob_cartera..bcp_castigo_masivo_tmp'

--Ejecucion de BCP
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

--Se agrega campo secuencial a la tabla temporal de carga
alter table bcp_castigo_masivo_tmp
   add cm_secuencial int identity(1,1)
select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al crear campo cm_secuencial',
          @w_return  = @w_error
   goto ERROR
end

--Tabla de trabajo de errores
if exists (select 1 from sysobjects where name = '##ca_rep_err_carg_mas') 
   drop table ##ca_rep_err_carg_mas

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al borrar tabla ##ca_rep_err_carg_mas',
          @w_return  = @w_error
   goto ERROR
end

create table ##ca_rep_err_carg_mas (
   re_secuencial  int identity,
   re_registro    varchar(2000) null   
)

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al crear tabla ##ca_rep_err_carg_mas',
          @w_return  = @w_error
   goto ERROR
end

--Insercion de encabezados
select @w_columnas = 'Fila' +@w_separador+ 'Columna' +@w_separador+ 'Operacion' +@w_separador+ 'Descripcion_de_Error'

insert into ##ca_rep_err_carg_mas(
       re_registro
       )
values(
       @w_columnas
       )

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al insertar encabezados tabla ##ca_rep_err_carg_mas',
          @w_return  = @w_error
   goto ERROR
end

--Validacion
declare cur_val_carga_castigo_masivo cursor for 
   select cm_fecha_proc,      cm_op_banco,       cm_fecha_valor,      cm_secuencial
   from   bcp_castigo_masivo_tmp
   order by cm_secuencial

   open cur_val_carga_castigo_masivo   
   fetch next from cur_val_carga_castigo_masivo into
          @w_cm_fecha_proc,   @w_cm_op_banco,    @w_cm_fecha_valor,   @w_cm_secuencial

   while (@@fetch_status = 0)
   begin
      if (@@fetch_status = -1)
      begin
         select @w_error = 710004
         
         close cur_saldos_operaciones    
         deallocate cur_saldos_operaciones
         
         exec cobis..sp_cerror 
             @t_debug = 'N', 
             @t_file  = '', 
             @t_from  = @w_sp_name,
             @i_num   = @w_error
         
         return @w_error
      end
      
      --iniciar variables
      select @w_op_operacion      = null,
             @w_op_toperacion     = '',
             @w_op_cliente        = null,
             @w_op_estado         = null,
             @w_op_fecha_ini      = null,
             @w_op_fecha_ult_proc = null,
             @w_di_fecha_ven      = null,
             @w_num_dias_ven      = 0,
             @w_op_estado_fin     = null,
             @w_mensaje           = '',
             @w_mensaje_err       = ''
      
      --Obtener informacion de prestamo
      select @w_op_operacion        = op_operacion,
             @w_op_toperacion       = op_toperacion,
             @w_op_cliente          = op_cliente,
             @w_op_estado           = op_estado,
             @w_op_fecha_ini        = op_fecha_ini,
             @w_op_fecha_ult_proc   = op_fecha_ult_proceso
      from   cob_cartera..ca_operacion
      where  op_banco = @w_cm_op_banco
      if @@rowcount = 0
      begin
         select @w_error       = 725054,  --No existe la operación
                @w_nom_columna = 'NUMERO DE OPERACION',
                @w_mensaje     = 'No existe la operación'

         select @w_mensaje_err = re_valor
         from   cobis..cl_errores inner join cobis..ad_error_i18n 
                                  on (numero = pc_codigo_int
                                  and re_cultura like '%'+@s_culture+'%')
         where  numero = @w_error
         
         select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)
         
         --Insercion detalle
         insert into ##ca_rep_err_carg_mas(re_registro)
               values(
                      concat(
                      convert(varchar,@w_cm_secuencial),@w_separador,  --Fila
                      @w_nom_columna,@w_separador,                     --Columna       
                      @w_cm_op_banco,@w_separador,                     --Operación
                      @w_mensaje                                       --Descripcion_de_Error
                            )
                     )
         select @w_error = @@error
         if @w_error != 0
         begin
            select @w_mensaje = 'Error al insertar detalle tabla ##ca_rep_err_carg_mas',
                   @w_return  = @w_error

            close cur_saldos_operaciones    
            deallocate cur_saldos_operaciones

            goto ERROR
         end
         goto NEXT_LINE_CURSOR
      end

      --Validacion de estado de la operacion
      if @w_op_estado in (@w_est_novigente, @w_est_cancelado, @w_est_credito,@w_est_anulado,@w_est_castigado)
      begin
         select @w_error       = 725249, --PRESTAMO NO ESTA ACTIVO O YA ESTA CASTIGADO
                @w_nom_columna = 'NUMERO DE OPERACION',
                @w_mensaje     = 'PRESTAMO NO ESTA ACTIVO O YA ESTA CASTIGADO'
                
         select @w_mensaje_err = re_valor
         from   cobis..cl_errores inner join cobis..ad_error_i18n 
                                  on (numero = pc_codigo_int
                                  and re_cultura like '%'+@s_culture+'%')
         where  numero = @w_error
         
         select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)
         
         --Insercion detalle
         insert into ##ca_rep_err_carg_mas(re_registro)
               values(
                      concat(
                      convert(varchar,@w_cm_secuencial),@w_separador,  --Fila
                      @w_nom_columna,@w_separador,                     --Columna       
                      @w_cm_op_banco,@w_separador,                     --Operación
                      @w_mensaje                                       --Descripcion_de_Error
                            )
                     )
         select @w_error = @@error
         if @w_error != 0
         begin
            select @w_mensaje = 'Error al insertar detalle tabla ##ca_rep_err_carg_mas',
                   @w_return  = @w_error

            close cur_saldos_operaciones    
            deallocate cur_saldos_operaciones

            goto ERROR
         end
      end
      
      --Validacion de parametrizacion de estados manuales
      select @w_di_fecha_ven = di_fecha_ven
      from   cob_cartera..ca_dividendo
      where  di_operacion    = @w_op_operacion
      and    di_dividendo    = (select isnull(min(di_dividendo), 0)
                                from   cob_cartera..ca_dividendo
                                where  di_operacion  = @w_op_operacion
                                and    di_estado     = @w_est_vencido)
                                
      select @w_num_dias_ven = datediff(dd,@w_di_fecha_ven,@w_fecha_proc)

      select @w_num_dias_ven = isnull(@w_num_dias_ven,0)

      select @w_op_estado_fin  = em_estado_fin
      from   cob_cartera..ca_estados_man
      where  em_toperacion  = @w_op_toperacion
      and    em_tipo_cambio = 'M'
      and    em_estado_ini  = @w_op_estado
      and    em_dias_cont  <= @w_num_dias_ven
      and    em_dias_fin   >= @w_num_dias_ven
      and    em_estado_fin  = @w_est_castigado
      
      if @@rowcount = 0
      begin
         select @w_error       = 725250, --OPERACION NO CUMPLE CON PARAMETROS PARA CAMBIO DE ESTADO
                @w_nom_columna = 'NUMERO DE OPERACION',
                @w_mensaje     = 'OPERACION NO CUMPLE CON PARAMETROS PARA CAMBIO DE ESTADO'

         select @w_mensaje_err = re_valor
         from   cobis..cl_errores inner join cobis..ad_error_i18n 
                                  on (numero = pc_codigo_int
                                  and re_cultura like '%'+@s_culture+'%')
         where  numero = @w_error
         
         select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)
         
         --Insercion detalle
         insert into ##ca_rep_err_carg_mas(re_registro)
               values(
                      concat(
                      convert(varchar,@w_cm_secuencial),@w_separador,  --Fila
                      @w_nom_columna,@w_separador,                     --Columna       
                      @w_cm_op_banco,@w_separador,                     --Operación
                      @w_mensaje                                       --Descripcion_de_Error
                            )
                     )
         select @w_error = @@error
         if @w_error != 0
         begin
            select @w_mensaje = 'Error al insertar detalle tabla ##ca_rep_err_carg_mas',
                   @w_return  = @w_error

            close cur_saldos_operaciones    
            deallocate cur_saldos_operaciones

            goto ERROR
         end
      end
      
      --Validacion de fecha de proceso
      if @w_cm_fecha_proc != @w_fecha_proc
      begin
         select @w_error       = 725252, --NO COINCIDE LA FECHA DE PROCESO
                @w_nom_columna = 'FECHA DE PROCESO',
                @w_mensaje     = 'NO COINCIDE LA FECHA DE PROCESO'

         select @w_mensaje_err = re_valor
         from   cobis..cl_errores inner join cobis..ad_error_i18n 
                                  on (numero = pc_codigo_int
                                  and re_cultura like '%'+@s_culture+'%')
         where  numero = @w_error
         
         select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)
         
         --Insercion detalle
         insert into ##ca_rep_err_carg_mas(re_registro)
               values(
                      concat(
                      convert(varchar,@w_cm_secuencial),@w_separador,  --Fila
                      @w_nom_columna,@w_separador,                     --Columna       
                      @w_cm_op_banco,@w_separador,                     --Operación
                      @w_mensaje                                       --Descripcion_de_Error
                            )
                     )
         select @w_error = @@error
         if @w_error != 0
         begin
            select @w_mensaje = 'Error al insertar detalle tabla ##ca_rep_err_carg_mas',
                   @w_return  = @w_error

            close cur_saldos_operaciones    
            deallocate cur_saldos_operaciones

            goto ERROR
         end      
      end

      --Validacion de fecha valor
      if @w_cm_fecha_valor > @w_fecha_proc
      begin
         select @w_error       = 725253, --FECHA VALOR MAYOR A FECHA DE PROCESO
                @w_nom_columna = 'FECHA VALOR',
                @w_mensaje     = 'FECHA VALOR MAYOR A FECHA DE PROCESO'

         select @w_mensaje_err = re_valor
         from   cobis..cl_errores inner join cobis..ad_error_i18n 
                                  on (numero = pc_codigo_int
                                  and re_cultura like '%'+@s_culture+'%')
         where  numero = @w_error
         
         select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)
         
         --Insercion detalle
         insert into ##ca_rep_err_carg_mas(re_registro)
               values(
                      concat(
                      convert(varchar,@w_cm_secuencial),@w_separador,  --Fila
                      @w_nom_columna,@w_separador,                     --Columna       
                      @w_cm_op_banco,@w_separador,                     --Operación
                      @w_mensaje                                       --Descripcion_de_Error
                            )
                     )
         select @w_error = @@error
         if @w_error != 0
         begin
            select @w_mensaje = 'Error al insertar detalle tabla ##ca_rep_err_carg_mas',
                   @w_return  = @w_error

            close cur_saldos_operaciones    
            deallocate cur_saldos_operaciones

            goto ERROR
         end      
      end
      
      --Validacion de fecha inicio operacion
      if @w_cm_fecha_valor < @w_op_fecha_ini
      begin
         select @w_error       = 725255, --FECHA VALOR DEBE SER MAYOR QUE LA FECHA DE INICIO DE LA OPERACIÓN
                @w_nom_columna = 'FECHA VALOR',
                @w_mensaje     = 'FECHA VALOR DEBE SER MAYOR QUE LA FECHA DE INICIO DE LA OPERACIÓN'

         select @w_mensaje_err = re_valor
         from   cobis..cl_errores inner join cobis..ad_error_i18n 
                                  on (numero = pc_codigo_int
                                  and re_cultura like '%'+@s_culture+'%')
         where  numero = @w_error
         
         select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)
         
         --Insercion detalle
         insert into ##ca_rep_err_carg_mas(re_registro)
               values(
                      concat(
                      convert(varchar,@w_cm_secuencial),@w_separador,  --Fila
                      @w_nom_columna,@w_separador,                     --Columna       
                      @w_cm_op_banco,@w_separador,                     --Operación
                      @w_mensaje                                       --Descripcion_de_Error
                            )
                     )
         select @w_error = @@error
         if @w_error != 0
         begin
            select @w_mensaje = 'Error al insertar detalle tabla ##ca_rep_err_carg_mas',
                   @w_return  = @w_error

            close cur_saldos_operaciones    
            deallocate cur_saldos_operaciones

            goto ERROR
         end      
      end      

      NEXT_LINE_CURSOR:
         fetch next from cur_val_carga_castigo_masivo into
          @w_cm_fecha_proc,   @w_cm_op_banco,    @w_cm_fecha_valor,   @w_cm_secuencial
   end--fin de while

close cur_val_carga_castigo_masivo    
deallocate cur_val_carga_castigo_masivo

--Creacion de reporte de errores
if exists(select count(1)
          from   ##ca_rep_err_carg_mas
          having count(1) > 1 )
begin
   --nombre de archivo de entrada y ruta
   select @w_nombre_arch = @w_path_destino + @w_nombre_fuente_err + '.' + @w_extension
   select @w_tipo_bcp    = 'queryout'
   
   --sentencia sql para BCP
   select @w_sql = 'select re_registro from ##ca_rep_err_carg_mas order by re_secuencial'
   
   --Ejecucion de BCP
   exec @w_return       = cobis..sp_bcp_archivos
        @i_sql          = @w_sql,         --select o nombre de tabla para generar archivo plano
        @i_tipo_bcp     = @w_tipo_bcp,    --tipo de bcp in,out,queryout
        @i_rut_nom_arch = @w_nombre_arch, --ruta y nombre de archivo
        @i_separador    = @w_separador,   --separador
        @i_nom_servidor = @w_nom_servidor --nombre de servidor donde se procesa bcp
   
   if @w_return != 0
   begin
      select @w_mensaje = 'Error al generar bcp salida cobis..sp_bcp_archivos'
      goto ERROR
   end
end
else
begin
   --limpieza de registros de propio dia
   delete ca_cambio_estado_masivo
   where  cem_fecha_proceso = @w_fecha_proc
   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al borrar tabla ca_cambio_estado_masivo',
             @w_return  = @w_error
      goto ERROR
   end

   --llenar tabla definitiva
   insert into ca_cambio_estado_masivo(       
          cem_fecha_proceso,     cem_op_banco,          cem_fecha_valor,   cem_estado_inicial_op,
          cem_estado_final_op,   cem_estado_registro,   cem_fecha_real,    cem_codigo_error
          )
   select @w_fecha_proc,         cm_op_banco,           cm_fecha_valor,    op_estado,
          @w_est_castigado,      'I',                   getdate(),         null
   from   bcp_castigo_masivo_tmp,
          ca_operacion
   where  op_banco = cm_op_banco
   
   select @w_error = @@error
   if @w_error != 0
   begin
      select @w_mensaje = 'Error al insertar detalle tabla ca_cambio_estado_masivo',
             @w_return  = @w_error

      goto ERROR
   end   
end

return @w_return

ERROR:

   select @w_mensaje_err = re_valor
   from   cobis..cl_errores inner join cobis..ad_error_i18n 
                            on (numero = pc_codigo_int
                            and re_cultura like '%'+@s_culture+'%')
   where  numero = @w_error
   
   select @w_mensaje = isnull(@w_mensaje_err,@w_mensaje)

   exec @w_retorno_ej = cobis..sp_ba_error_log
        @i_sarta      = @w_sarta,
        @i_batch      = @w_batch,
        @i_secuencial = @w_secuencial,
        @i_corrida    = @w_corrida,
        @i_intento    = @w_intento,
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
