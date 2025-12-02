/********************************************************************/
/*   NOMBRE LOGICO:      sp_rep_sabana_garantias                    */
/*   NOMBRE FISICO:      resabgar.sp                                */
/*   BASE DE DATOS:      cob_custodia                               */
/*   PRODUCTO:           Garantias                                  */
/*   DISENADO POR:       William Lopez                              */
/*   FECHA DE ESCRITURA: 06-Mar-2023                                */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Reporte detalle de las garantia activas                        */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   06-Mar-2023        WLO                Emision Inicial          */
/********************************************************************/
use cob_custodia
go

if exists(select 1 from sysobjects where name = 'sp_rep_sabana_garantias' and type = 'P')
    drop procedure sp_rep_sabana_garantias
go

create procedure sp_rep_sabana_garantias
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
   @w_extension         varchar(10),
   @w_charcero          varchar(16),
   @w_dia               varchar(2),
   @w_mes               varchar(2),
   @w_anio              varchar(4),
   @w_hora              varchar(2),
   @w_min               varchar(2),
   @w_seg               varchar(4),
   @w_fecha_hor_arch    varchar(20),
   @w_columnas          varchar(1000),
   @w_sarta             int,
   @w_batch             int,
   @w_fecha_cierre      datetime,
   @w_cod_prod_gar      int,
   @w_secuencial        int      = null,
   @w_corrida           int      = null,
   @w_intento           int      = null

select @w_sp_name           = 'sp_rep_sabana_garantias',
       @w_error             = 0,
       @w_return            = 0,
       @w_sql               = '',
       @w_path_destino      = '',
       @w_mensaje           = '',
       @w_mensaje_err       = null,
       @w_separador         = char(9),
       @w_fecha_proc        = @i_param1,
       @w_columnas          = '',
       @w_nombre_arch       = '',
       @w_nombre_fuente     = 'repoperativo_gar',
       @w_extension         = 'txt',
       @w_tipo_bcp          = 'queryout',
       @w_nom_servidor      = ''

-- Código de producto GAR
select @w_cod_prod_gar = pd_producto
from   cobis..cl_producto
where  pd_abreviatura = 'GAR'

-- Fecha de Proceso
select @w_fecha_cierre = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = @w_cod_prod_gar

if @w_fecha_proc in (null,'')
   select @w_fecha_proc = @w_fecha_cierre

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
select @w_seg       = substring(convert(varchar(8),getdate(), 108), 7, 1)
select @w_charcero  = replicate('0',2-len(ltrim(rtrim(@w_seg))))
select @w_seg       = @w_charcero + @w_seg

select @w_fecha_hor_arch = @w_anio + @w_mes + @w_dia +'_'+ @w_hora + @w_min + @w_seg

select @w_path_destino = ba_path_destino
from   cobis..ba_batch
where  ba_producto    = 19
and    ba_arch_fuente = 'cob_custodia..sp_rep_sabana_garantias'

select @w_sarta = lo_sarta,
       @w_batch = lo_batch
from   cobis..ba_log,
       cobis..ba_batch
where  ba_arch_fuente like '%sp_rep_sabana_garantias%'
and    lo_batch   = ba_batch
and    lo_estatus = 'E'

exec cobis..sp_ad_establece_cultura
   @o_culture = @s_culture out

--parametro de nombre de servidor central
select @w_nom_servidor = isnull(pa_char,'')
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'SCVL'

--Tabla de trabajo de garantias
if exists (select 1 from sysobjects where name = '##cu_rep_sab_gar') 
   drop table ##cu_rep_sab_gar

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al borrar tabla ##cu_rep_sab_gar',
          @w_return  = @w_error
   goto ERROR
end

create table ##cu_rep_sab_gar (
   re_secuencial  int identity,
   re_registro    varchar(5000) null   
)

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al crear tabla ##cu_rep_sab_gar',
          @w_return  = @w_error
   goto ERROR
end

--Insercion de encabezados
select @w_columnas = 'FILIAL'             +@w_separador+'SUCURSAL'             +@w_separador+'TIPO_DE_CUSTODIA'    +@w_separador+
                     'CODIGO_EXTERNO'     +@w_separador+'ESTADO_GAR'           +@w_separador+'FECHA_INGRESO'       +@w_separador+
                     'VALOR_INICIAL'      +@w_separador+'VALOR_ACTUAL'         +@w_separador+'MONEDA_GAR'          +@w_separador+
                     'CODIGO_ENTE_GARANTE'+@w_separador+'NOMBRE_GARANTE'       +@w_separador+'INSTRUCCION_GAR'     +@w_separador+
                     'DESCRIPCION_GAR'    +@w_separador+'POLIZA_GAR'           +@w_separador+'INSPECCIONAR_GAR'    +@w_separador+
                     'MOTIVO_NOINSP'      +@w_separador+'SUFICIENCIA_LEGAL'    +@w_separador+'FUENTE_VALOR'        +@w_separador+
                     'ALMACENERA_GAR'     +@w_separador+'ASEGURADORA_GAR'      +@w_separador+'DIRECCION_PRENDA'    +@w_separador+
                     'CIUDAD_PRENDA'      +@w_separador+'TELEFONO_PRENDA'      +@w_separador+'FECHA_MODIFICACION'  +@w_separador+
                     'FECHA_CONSTITUCION' +@w_separador+'PERIODICIDAD_GAR'     +@w_separador+'POSEE_POLIZA'        +@w_separador+
                     'NRO_INSPECCIONES'   +@w_separador+'INTERVALO_GAR'        +@w_separador+'COBRANZA_JUDICIAL'   +@w_separador+
                     'FECHA_RETIRO'       +@w_separador+'FECHA_DEVOLUCION'     +@w_separador+'FECHA_MODIFICACION'  +@w_separador+
                     'ESTADO_POLIZA'      +@w_separador+'CUENTA_DPF'           +@w_separador+'FECHA_INSP'          +@w_separador+
                     'ABIERTA_CERRADA'    +@w_separador+'ADECUADA_NOADEC'      +@w_separador+'PROPIETARIO_GAR'     +@w_separador+
                     'PLAZO_FIJO'         +@w_separador+'MONTO_PFIJO'          +@w_separador+'OFICINA_GAR'         +@w_separador+
                     'OFICINA_CONTABILIZA'+@w_separador+'COMPARTIDA_GAR'       +@w_separador+'VALOR_COMPARTIDA'    +@w_separador+
                     'FECHA_REGISTRO'     +@w_separador+'FECHA_PROX_INSPECCION'+@w_separador+'FECHA_VENCIMIENTO'   +@w_separador+
                     'PAIS_GAR'           +@w_separador+'PROVINCIA_GAR'        +@w_separador+'CANTON_GAR'          +@w_separador+
                     'FECHA_AVALUO'       +@w_separador+'UBICACION_GAR'        +@w_separador+'PORCENTAJE_COBERTURA'

insert into ##cu_rep_sab_gar(
       re_registro
       )
values(
       @w_columnas
       )

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al insertar encabezados tabla ##cu_rep_sab_gar',
          @w_return  = @w_error
   goto ERROR
end

--Insercion detalle
insert into ##cu_rep_sab_gar(re_registro)
select concat(
       convert(varchar,cu_filial),@w_separador,                --FILIAL
       convert(varchar,cu_sucursal),@w_separador,              --SUCURSAL
       cu_tipo,@w_separador,                                   --TIPO_DE_CUSTODIA
       cu_codigo_externo,@w_separador,                         --CODIGO_EXTERNO
       cu_estado,@w_separador,                                 --ESTADO_GAR
       convert(varchar,cu_fecha_ingreso,101),@w_separador,     --FECHA_INGRESO
       convert(varchar,cu_valor_inicial),@w_separador,         --VALOR_INICIAL
       convert(varchar,cu_valor_actual),@w_separador,          --VALOR_ACTUAL
       convert(varchar,cu_moneda),@w_separador,                --MONEDA_GAR
       convert(varchar,cu_garante),@w_separador,               --CODIGO_ENTE_GARANTE
      (select isnull(en_nombre,'')    + ' ' + 
              isnull(p_p_apellido,'') + ' ' + 
              isnull(p_s_apellido,'')
       from   cobis..cl_ente
       where  en_ente = cu_garante),@w_separador,              --NOMBRE_GARANTE
       cu_instruccion,@w_separador,                            --INSTRUCCION_GAR
       cu_descripcion,@w_separador,                            --DESCRIPCION_GAR
       cu_poliza,@w_separador,                                 --POLIZA_GAR
       cu_inspeccionar,@w_separador,                           --INSPECCIONAR_GAR
       cu_motivo_noinsp,@w_separador,                          --MOTIVO_NOINSP
       cu_suficiencia_legal,@w_separador,                      --SUFICIENCIA_LEGAL
       cu_fuente_valor,@w_separador,                           --FUENTE_VALOR
       convert(varchar,cu_almacenera),@w_separador,            --ALMACENERA_GAR
       cu_aseguradora,@w_separador,                            --ASEGURADORA_GAR
       cu_direccion_prenda,@w_separador,                       --DIRECCION_PRENDA
       cu_ciudad_prenda,@w_separador,                          --CIUDAD_PRENDA
       cu_telefono_prenda,@w_separador,                        --TELEFONO_PRENDA
       convert(varchar,cu_fecha_modif,101),@w_separador,       --FECHA_MODIFICACION
       convert(varchar,cu_fecha_const,101),@w_separador,       --FECHA_CONSTITUCION
       cu_periodicidad,@w_separador,                           --PERIODICIDAD_GAR
       cu_posee_poliza,@w_separador,                           --POSEE_POLIZA
       convert(varchar,cu_nro_inspecciones),@w_separador,      --NRO_INSPECCIONES
       convert(varchar,cu_intervalo),@w_separador,             --INTERVALO_GAR
       cu_cobranza_judicial,@w_separador,                      --COBRANZA_JUDICIAL
       convert(varchar,cu_fecha_retiro,101),@w_separador,      --FECHA_RETIRO
       convert(varchar,cu_fecha_devolucion,101),@w_separador,  --FECHA_DEVOLUCION
       convert(varchar,cu_fecha_modificacion,101),@w_separador,--FECHA_MODIFICACION
       cu_estado_poliza,@w_separador,                          --ESTADO_POLIZA
       cu_cuenta_dpf,@w_separador,                             --CUENTA_DPF
       convert(varchar,cu_fecha_insp,101),@w_separador,        --FECHA_INSP
       cu_abierta_cerrada,@w_separador,                        --ABIERTA_CERRADA
       cu_adecuada_noadec,@w_separador,                        --ADECUADA_NOADEC
       cu_propietario,@w_separador,                            --PROPIETARIO_GAR
       cu_plazo_fijo,@w_separador,                             --PLAZO_FIJO
       convert(varchar,cu_monto_pfijo),@w_separador,           --MONTO_PFIJO
       convert(varchar,cu_oficina),@w_separador,               --OFICINA_GAR       
       convert(varchar,cu_oficina_contabiliza),@w_separador,   --OFICINA_CONTABILIZA
       cu_compartida,@w_separador,                             --COMPARTIDA_GAR
       convert(varchar,cu_valor_compartida),@w_separador,      --VALOR_COMPARTIDA
       convert(varchar,cu_fecha_reg,101),@w_separador,         --FECHA_REGISTRO
       convert(varchar,cu_fecha_prox_insp,101),@w_separador,   --FECHA_PROX_INSPECCION
       convert(varchar,cu_fecha_vencimiento,101),@w_separador, --FECHA_VENCIMIENTO
       convert(varchar,cu_pais),@w_separador,                  --PAIS_GAR
       convert(varchar,cu_provincia),@w_separador,             --PROVINCIA_GAR
       convert(varchar,cu_canton),@w_separador,                --CANTON_GAR
       convert(varchar,cu_fecha_avaluo,101),@w_separador,      --FECHA_AVALUO
       cu_ubicacion,@w_separador,                              --UBICACION_GAR
       convert(varchar,cu_porcentaje_cobertura)                --PORCENTAJE_COBERTURA
             )
from   cu_custodia
where  cu_estado = 'V'

select @w_error = @@error
if @w_error != 0
begin
   select @w_mensaje = 'Error al insertar detalle tabla ##cu_rep_sab_gar',
          @w_return  = @w_error
   goto ERROR
end

--Creacion de reporte de garantias
if exists(select count(1)
          from   ##cu_rep_sab_gar
          having count(1) > 1
          )
begin
   --nombre de archivo de entrada y ruta
   select @w_nombre_arch = @w_path_destino + @w_nombre_fuente + '_' + @w_fecha_hor_arch + '.' + @w_extension

   --sentencia sql para BCP
   select @w_sql = 'select re_registro from ##cu_rep_sab_gar order by re_secuencial'
   
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
