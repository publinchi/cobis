/************************************************************************/
/*  Archivo:              sp_desembolsos_terceros.sp                    */
/*  Stored procedure:     sp_desembolsos_terceros                       */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             CARTERA                                       */
/*  Disenado por:         Juan Carlos Guzman                            */
/*  Fecha de escritura:   13/Dic/2022                                   */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                        PROPOSITO                                     */
/*   Generar un archivo con la identificacion de operaciones con        */
/*   desembolso con terceros                                            */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR              RAZON                              */
/*  13/Dic/2022   Juan Guzman        Emisión Inicial                    */
/*  30/Mar/2023   Guisela Fernandez  Ajuste de reproceso para no repetir*/
/*                                   información en la fecha de proceso */
/*  30/Nov/2023   Kevin Rodríguez    R220511 Hora y min nombre reporte  */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_desembolsos_terceros')
   drop proc sp_desembolsos_terceros
go

create procedure sp_desembolsos_terceros
(
   @t_debug        char(1)      = 'N',
   @s_culture      varchar(10)  = 'NEUTRAL',
   @i_param1       datetime     = null,         -- FECHA DE PROCESO
   @i_param2       char(1)      = 'N'           -- REPROCESO
)
as 

declare @w_sp_name            descripcion,
        @w_fecha_proc         datetime,
        @w_param_forma_des    varchar(20),
        @w_param_dias_token   int,
        @w_retorno_ej         int,
        @w_error              int,
        @w_mensaje            varchar(200),
        @w_sarta              int,
        @w_batch              int,
        @w_min_random         int,
        @w_max_random         int,
        @w_max_registros      int,
        @w_count              int,
        @w_id_des             int,
        @w_banco              varchar(20), 
        @w_sec_desembolso     int,
        @w_cliente            int,
        @w_monto_op           money,
        @w_monto_desembolso   money,
        @w_token              int,
        @w_fecha_vigencia     datetime,
        @w_separador          varchar(5),
        @w_path_destino       varchar(255),
        @w_nombre_arch        varchar(255),
        @w_sql                varchar(255),
        @w_tipo_bcp           varchar(10),
        @w_return             int,
        @w_reproceso          char(1),
        @w_cod_prod_cca       int,
        @w_hora               varchar(2),
        @w_min                varchar(2),
        @w_hor_min_arch       varchar(20),
        @w_charcero           varchar(16)

select @w_sp_name     = 'sp_desembolsos_terceros',
       @w_min_random  = 1000000,
       @w_max_random  = 2147483640,
       @w_fecha_proc  = @i_param1,
       @w_reproceso   = @i_param2

-- Hora y minuto de generación de reporte
select @w_hora      = substring(convert(varchar(8),getdate(), 108), 1, 2)
select @w_charcero  = replicate('0',2-len(ltrim(rtrim(@w_hora))))
select @w_hora      = @w_charcero + @w_hora
select @w_min       = substring(convert(varchar(8),getdate(), 108), 4, 2)
select @w_charcero  = replicate('0',2-len(ltrim(rtrim(@w_min))))
select @w_min       = @w_charcero + @w_min

select @w_hor_min_arch = @w_hora + @w_min

-- CULTURA
exec cobis..sp_ad_establece_cultura                                                                                                                                                                                                                         
   @o_culture = @s_culture out
   
-- Código de producto CCA
select @w_cod_prod_cca = pd_producto
from cobis..cl_producto
where pd_abreviatura = 'CCA'
   
-- Fecha de Proceso
if @w_fecha_proc is null
begin
   select @w_fecha_proc = fc_fecha_cierre 
   from cobis..ba_fecha_cierre
   where fc_producto = @w_cod_prod_cca
end

-- Información proceso batch
select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from cobis..ba_log,
     cobis..ba_batch
where ba_arch_fuente like '%cob_cartera..sp_desembolsos_terceros%'
and   lo_batch   = ba_batch
and   lo_estatus = 'E'
   
-- PARÁMETROS GENERALES
select @w_param_forma_des = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'FDESTE'
and    pa_producto = 'CCA'

if @@rowcount = 0
begin
   /* No se encuentra definido el parámetro general FDESTE de forma de desembolso */
   select @w_error  = 725209 
   goto ERROR
end

select @w_param_dias_token = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'DIVIGT'
and    pa_producto = 'CCA'

if @@rowcount = 0
begin
   /* No se encuentra definido el parámetro general DIVIGT para vigencia de token */
   select @w_error  = 725210 
   goto ERROR
end

-- Tabla temporal de Desembolsos
if exists (select 1 from sysobjects where name = '#ca_desembolsos_terceros')
   drop table #ca_desembolsos_terceros
   
if @@error != 0
begin
   /* Error al eliminar tabla temporal #ca_desembolsos_terceros */
   select @w_error  = 725211
   
   goto ERROR
end

create table #ca_desembolsos_terceros(
   dt_id            int           identity(1,1),
   dt_banco         varchar(15)   not null,
   dt_cliente       int           not null,
   dt_monto_op      money         not null,
   dt_monto_desem   money         not null
)

if @@error != 0
begin
   /* Error al crear tabla temporal #ca_desembolsos_terceros */
   select @w_error  = 725212
   goto ERROR
end

if (@w_reproceso = 'S')
begin
   insert into #ca_desembolsos_terceros
   select op_banco,
          op_cliente,
          op_monto,
   	      dtr_monto
   from ca_operacion with (nolock),
   	    ca_transaccion with (nolock),
   	    ca_det_trn with (nolock)
   where op_operacion  = tr_operacion
   and   tr_operacion  = dtr_operacion
   and   tr_secuencial = dtr_secuencial
   and   tr_tran       = 'DES'
   and   tr_fecha_mov  = @w_fecha_proc
   and   tr_estado     <> 'RV'
   and   dtr_concepto  = @w_param_forma_des
   order by op_oficina, op_oficial, op_grupo, op_cliente
end
else
begin
insert into #ca_desembolsos_terceros
   select op_banco,
          op_cliente,
          op_monto,
   	      dtr_monto
   from ca_operacion with (nolock),
   	    ca_transaccion with (nolock),
   	    ca_det_trn with (nolock)
   where op_operacion  = tr_operacion
   and   tr_operacion  = dtr_operacion
   and   tr_secuencial = dtr_secuencial
   and   tr_tran       = 'DES'
   and   tr_fecha_mov  = @w_fecha_proc
   and   tr_estado     <> 'RV'
   and   dtr_concepto  = @w_param_forma_des
   and   op_banco  NOT IN (select idt_banco from ca_integracion_desembolsos_terceros where idt_fecha_proceso = @w_fecha_proc )
   order by op_oficina, op_oficial, op_grupo, op_cliente
end

if @@error != 0
begin
   /* Error en inserción de datos en tabla temporal #ca_desembolsos_terceros */
   select @w_error  = 725213
   goto ERROR
end

select @w_max_registros = count(1)
from #ca_desembolsos_terceros

/* Se procede con la inserción de registros*/
   
if (@w_reproceso = 'S') 
begin
   delete from ca_integracion_desembolsos_terceros
   where idt_fecha_proceso = @w_fecha_proc
   
   if @@error != 0 
   begin
      /* Error en eliminacion tabla ca_integracion_desembolsos_terceros */
      select @w_error = 707084
      rollback tran
      goto ERROR
   end
end

select @w_count = 1,
       @w_fecha_vigencia = dateadd(dd, @w_param_dias_token, @w_fecha_proc)

begin tran
while @w_count <= @w_max_registros
begin
   select top 1
      @w_id_des           = dt_id,
      @w_banco            = dt_banco,
      @w_cliente          = dt_cliente,
      @w_monto_op         = dt_monto_op,
	  @w_monto_desembolso = dt_monto_desem
   from #ca_desembolsos_terceros
   where dt_id = @w_count
   
   select @w_token = floor(rand()*(@w_max_random-@w_min_random+1))+@w_min_random
      
   insert into ca_integracion_desembolsos_terceros(
      idt_banco,           idt_fecha_proceso,      idt_cliente,
      idt_monto_op,        idt_monto_desembolso,   idt_token,
      idt_fecha_vigencia)
   values(
      @w_banco,            @w_fecha_proc,          @w_cliente,
      @w_monto_op,         @w_monto_desembolso,    @w_token,
      @w_fecha_vigencia)
      
   if @@error != 0
   begin
      /* Error en inserción de registro en tabla de desembolsos por terceros */
      select @w_error  = 725214     
      rollback tran    
      goto ERROR
   end
   
   select @w_count = @w_count + 1
end

commit tran

-- Tabla temporal para registros que se exportarán por BCP OUT
if exists (select 1 from sysobjects where name = '##ca_registros_bcp_tmp')
   drop table ##ca_registros_bcp_tmp
   
if @@error != 0
begin
   /* Error al eliminar tabla temporal #ca_registros_bcp_tmp */
   select @w_error  = 725215 
   goto ERROR
end

create table ##ca_registros_bcp_tmp(
   rbt_id          int            identity(1,1),
   rbt_registro    varchar(1000)  null
)

if @@error != 0
begin
   /* Error al crear tabla temporal #ca_registros_bcp_tmp */
   select @w_error  = 725216
   
   goto ERROR
end

select @w_separador = ';'

-- Inserción de ncabezados del archivo
insert into ##ca_registros_bcp_tmp(rbt_registro)
values(concat('TOKEN', @w_separador, 'EFECTIVO', @w_separador, 'CREAR'))

if @@error != 0
begin
   /* Error al insertar registros en tabla temporal #ca_registros_bcp_tmp */
   select @w_error  = 725217
   
   goto ERROR
end

-- Inserción de los detalles del archivo
insert into ##ca_registros_bcp_tmp(rbt_registro)
select concat(
   idt_token, @w_separador,                                             --COL. A: Token
   char(39), replace(en_ced_ruc, '-', ''), @w_separador,                --COL. B: Num. dentificación del cliente
   en_tipo_ced, @w_separador,                                           --COL. C: Tipo identificación cliente
   '', @w_separador,                                                    --COL. D: Vacía
   '', @w_separador,                                                    --COL. E: Vacía
   op_nombre, @w_separador,                                             --COL. F: Nombre Cliente
   idt_monto_desembolso, @w_separador,                                  --COL. G: Monto Crédito
   char(39), op_banco, @w_separador,                                    --COL. H: Número de Prestamo
   convert(char(10),op_fecha_ini,112), @w_separador,                    --COL. I: Fecha Inicio
   convert(char(10),(dateadd(dd,3,op_fecha_ini)),112), @w_separador,    --COL. J: Fecha Inicio + 3 días
   ea_telef_recados                                                     --COL. K: Teléfono del cliente
)                                                                       
from ca_integracion_desembolsos_terceros,
     ca_operacion,
     cobis..cl_ente,
     cobis..cl_ente_aux, 
	 #ca_desembolsos_terceros
where idt_banco         = op_banco
and   idt_cliente       = en_ente
and   idt_cliente       = ea_ente
and   idt_fecha_proceso = @w_fecha_proc
and   dt_banco = idt_banco
   
if @@error != 0
begin
   /* Error al insertar registros en tabla temporal #ca_registros_bcp_tmp */
   select @w_error  = 725217  
   goto ERROR
end
select * from ##ca_registros_bcp_tmp

-- LLAMADO A BCP QUERYOUT

select @w_path_destino = ba_path_destino
from   cobis..ba_batch
where  ba_producto    = @w_cod_prod_cca
and    ba_arch_fuente = 'cob_cartera..sp_desembolsos_terceros'

select @w_tipo_bcp = 'queryout'

-- Nombre de archivo y ruta
select @w_nombre_arch = @w_path_destino + 'Desembolso_BAC_' + convert(char(8),@w_fecha_proc,112) + '-'+ @w_hor_min_arch + '.csv'

-- Sentencia sql para BCP
select @w_sql = 'select rbt_registro from cob_cartera..##ca_registros_bcp_tmp order by rbt_id'

exec @w_return       = cobis..sp_bcp_archivos
     @i_sql          = @w_sql,         --select o nombre de tabla para generar archivo plano
     @i_tipo_bcp     = @w_tipo_bcp,    --tipo de bcp in,out,queryout
     @i_rut_nom_arch = @w_nombre_arch, --ruta y nombre de archivo
     @i_separador    = @w_separador    --separador

if @w_return != 0
begin
   /* Error en proceso BCP de desembolsos por terceros */
   select @w_error  = 725218
   
   goto ERROR
end

drop table ##ca_registros_bcp_tmp
return 0

ERROR:
   select @w_mensaje = re_valor
   from cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int
      and re_cultura like '%'+@s_culture+'%')
   where numero = @w_error

   exec @w_retorno_ej = cobis..sp_ba_error_log
      @i_sarta   = @w_sarta,
      @i_batch   = @w_batch,
      @i_error   = @w_error,
      @i_detalle = @w_mensaje

   if @w_retorno_ej > 0
   begin
      return @w_retorno_ej
   end
   else
   begin
      return @w_error
   end

go
