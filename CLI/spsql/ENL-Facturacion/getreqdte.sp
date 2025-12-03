/* *****************************************************************/
/*   Archivo:          getreqdte.sp                                */
/*   Stored procedure: sp_get_requerimiento_DTE                    */
/*   Base de datos:    cob_externos                                */
/*   Producto:         COBIS Externos                              */
/* *****************************************************************/
/*                     IMPORTANTE                                  */
/*   Este programa es parte de los paquetes bancarios que son      */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp, */
/*   representantes exclusivos para comercializar los productos y  */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida*/
/*   y regida por las Leyes de la República de España y las        */
/*   correspondientes de la Unión Europea. Su copia, reproducción, */
/*   alteración en cualquier sentido, ingeniería reversa,          */
/*   almacenamiento o cualquier uso no autorizado por cualquiera   */
/*   de los usuarios o personas que hayan accedido al presente     */
/*   sitio, queda expresamente prohibido; sin el debido            */
/*   consentimiento por escrito, de parte de los representantes de */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto */
/*   en el presente texto, causará violaciones relacionadas con la */
/*   propiedad intelectual y la confidencialidad de la información */
/*   tratada; y por lo tanto, derivará en acciones legales civiles */
/*   y penales en contra del infractor según corresponda.”.        */
/* *****************************************************************/
/*                            PROPOSITO                            */
/*   Este Stored Procedure permite realizar la generacion de los   */
/*   archivos json: fe-ccf-v3, fe-fc-v1 y fe-nc-v3, anulacion_v2   */
/*   para ser enviados.                                            */
/*   al proveedor RICOH                                            */
/* *****************************************************************/
/*                         MODIFICACIONES                          */
/*   FECHA      AUTOR         RAZON                                */
/*   04-ABR-23  E.Carrion  Emision Inicial                         */
/*   30-JUN-23  A.Quishpe  Se modifica JSON de anulacion           */
/*   14-SEP-23  A.Quishpe  Se agrega un @o de retorno json         */
/*   08-NOV-23  D.Sarango  TEL-B932945-ENL Ajuste de validación en */
/*                         impresion de factura y tabulaciones     */
/*   01-AGO-24  A.Quishpe  RM241763 Se valida el estado antes de   */
/*                         enviar el DTE                           */
/* *****************************************************************/

use cob_externos
go

if exists (select * from sysobjects where id = object_id('sp_get_requerimiento_DTE'))
   drop procedure sp_get_requerimiento_DTE
go

create proc sp_get_requerimiento_DTE (
   @s_srv              varchar(30),
   @s_user             varchar(32),
   @s_term             varchar(32),
   @s_date             datetime,
   @s_rol              smallint      = 1,
   @s_error            int           = null,
   @s_msg              varchar(64)   = null,
   @s_org              char(1),
   @s_ofi              smallint,
   @t_trn              int,
   @i_cod_secuencial   int,
   @i_fecha_proc       datetime,
   @i_imprimir         char(1)       = 'S',
   @o_tipo_dte         char(2)              output,
   @o_json_dte         NVARCHAR(MAX)        output,
   @o_json_dte1        NVARCHAR(MAX) = null output
)
as

declare @w_sp_name               varchar(64),
        @w_tributo_cod           varchar(2),
        @w_tributo_desc          varchar(150),
        @w_tributo_valor         money,
        @w_tributos              varchar(150),
        @w_version               tinyint,
        @w_ambiente              varchar(5),
        @w_tipo_dte              varchar(2),
        @w_num_control           varchar(32),
        @w_cod_generacion        varchar(36),
        @w_tipo_modelo           tinyint,
        @w_tipo_operacion        tinyint,
        @w_tipo_contingencia     tinyint,
        @w_motivo_contin         varchar(5),
        @w_fecha_emision         varchar(12),
        @w_hora_emision          varchar(8),
        @w_tipo_moneda           varchar(3),
        @w_du_cod_generacion     varchar(36),
        @w_du_cod_generacionR    varchar(36),
        @w_do_nombre_responsa    varchar(100),
        @w_do_tip_doc_respons    varchar(2),
        @w_do_num_doc_respons    varchar(20),
        @w_do_nombre_solicita    varchar(100),
        @w_do_tip_doc_solicita   varchar(2),
        @w_do_num_doc_solicita   varchar(20),
        @w_do_tipo_anulacion     tinyint,
        @w_do_motivo_anulacion   varchar(250),
		@w_estado_actual         varchar(2)

-- Inicializo variables
select @w_sp_name  = 'sp_get_requerimiento_DTE',
       @w_tributos = null

-- Verificar codigos de transaccion
if @t_trn not in (172234)
begin
   -- Transaccion no corresponde
   exec cobis..sp_cerror
      @t_from   = @w_sp_name,
      @i_num    = 190000
   return 190000
end

if @i_fecha_proc is null
   select @i_fecha_proc = @s_date

select @w_version            = di_version,
       @w_ambiente           = di_ambiente,
      @w_tipo_dte            = di_tipo_dte,
      @w_num_control         = di_num_control,
      @w_cod_generacion      = di_cod_generacion,
      @w_tipo_modelo         = di_tipo_modelo,
      @w_tipo_operacion      = di_tipo_operacion,
      @w_tipo_contingencia   = di_tipo_contingencia,
      @w_motivo_contin       = di_motivo_contin,
      @w_fecha_emision       = di_fecha_emision,
      @w_hora_emision        = di_hora_emision,
      @w_tipo_moneda         = di_tipo_moneda
from ex_dte_identificacion
where di_cod_secuencial = @i_cod_secuencial
  and di_fecha_proceso  = @i_fecha_proc

-- Verificar codigos de tipo de documentos
if @w_tipo_dte not in ('01','03','05','20')
begin
   -- Tipo de documento no corresponde
   exec cobis..sp_cerror
      @t_from   = @w_sp_name,
      @i_num    = 1720644
   return 1720644
end

-- valida el estado antes de enviar
select @w_estado_actual = dq_estado
    from ex_dte_requerimiento
    where dq_ssn = @i_cod_secuencial
    and dq_fecha_proceso = @i_fecha_proc

if @w_estado_actual = 'G' or @w_estado_actual = 'V'
begin
    exec cobis..sp_cerror
    @t_from   = @w_sp_name,
	@i_msg  = 'DTE ha sido enviado anteriormente'
    return 0
end

if  @w_tipo_dte = '20'
begin
    select @w_du_cod_generacion  = du_cod_generacion,
           @w_du_cod_generacionR = du_codigo_generacionR
    from ex_dte_documento_anula
    where du_cod_secuencial = @i_cod_secuencial
    and du_fecha_proceso    = @i_fecha_proc
   
   select @w_do_nombre_responsa   = do_nombre_responsable,
          @w_do_tip_doc_respons   = do_tip_doc_responsable,
          @w_do_num_doc_respons   = do_num_doc_responsable,
          @w_do_nombre_solicita   = do_nombre_solicita,
          @w_do_tip_doc_solicita  = do_tip_doc_solicita,
          @w_do_num_doc_solicita  = do_num_doc_solicita,
          @w_do_tipo_anulacion    = do_tipo_anulacion,
          @w_do_motivo_anulacion  = do_motivo_anulacion
   from ex_dte_motivo_anula
   where do_cod_secuencial = @i_cod_secuencial
   and do_fecha_proceso    = @i_fecha_proc

end

if not exists (select 1 from ex_dte_apendice
                where da_cod_secuencial = @i_cod_secuencial
                  and da_fecha_proceso = @i_fecha_proc
                  and da_campo = '1MPR1M3')
begin
   if @i_imprimir is null
      select @i_imprimir = 'S'

   insert into ex_dte_apendice(da_cod_secuencial, da_fecha_proceso, da_campo, da_etiqueta, da_valor)
   values(@i_cod_secuencial,@i_fecha_proc, '1MPR1M3','1MPR1M3', @i_imprimir)
end

select @w_tributo_cod   = dt_tributo_codigo,
       @w_tributo_desc  = dt_tributo_descrip,
       @w_tributo_valor = dt_tributo_valor
 from ex_dte_total
where dt_cod_secuencial = @i_cod_secuencial
  and dt_fecha_proceso  = @i_fecha_proc

if @w_tributo_cod is not null
   set @w_tributos = (select  @w_tributo_cod as 'codigo',
                              @w_tributo_desc  as 'descripcion',
                              @w_tributo_valor as 'valor'
                      for JSON path, INCLUDE_NULL_VALUES)

if @w_tipo_dte = '05' --Nota de credito
begin
   set @o_json_dte = (select
      identificacion        = JSON_QUERY(
                           (select @w_version           as 'version',
                                 @w_ambiente            as 'ambiente',
                                 @w_tipo_dte            as 'tipoDte',
                                 @w_num_control         as 'numeroControl',
                                 @w_cod_generacion      as 'codigoGeneracion',
                                 @w_tipo_modelo         as 'tipoModelo',
                                 @w_tipo_operacion      as 'tipoOperacion',
                                 @w_tipo_contingencia   as 'tipoContingencia',
                                 @w_motivo_contin       as 'motivoContin',
                                 @w_fecha_emision       as 'fecEmi',
                                 @w_hora_emision        as 'horEmi',
                                 @w_tipo_moneda         as 'tipoMoneda'
                            for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           ),
      emisor               = JSON_QUERY(
                           (select dm_nit                  as 'nit',
                                 dm_nrc                    as 'nrc',
                                 dm_nombre                 as 'nombre',
                                 dm_cod_actividad          as 'codActividad',
                                 dm_desc_ctividad          as 'descActividad',
                                 dm_nombre_comercial       as 'nombreComercial',
                                 dm_tipo_establecimiento   as 'tipoEstablecimiento',
                                 dm_dir_departamento       as 'direccion.departamento',
                                 dm_dir_municipio          as 'direccion.municipio',
                                 dm_dir_complemento        as 'direccion.complemento',
                                 dm_telefono               as 'telefono',
                                 dm_correo                 as 'correo'
                            from ex_dte_emisor
                            where dm_cod_secuencial = @i_cod_secuencial
                              and dm_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           ),
      receptor            = JSON_QUERY(
                           (select dr_numero_doc         as 'nit',
                                   dr_nrc                as 'nrc',
                                   dr_nombres            as 'nombre',
                                   dr_cod_actividad      as 'codActividad',
                                   dr_desc_ctividad      as 'descActividad',
                                   dr_nombre_comercial   as 'nombreComercial',
                                   dr_dir_departamento   as 'direccion.departamento',
                                   dr_dir_municipio      as 'direccion.municipio',
                                   dr_dir_complemento    as 'direccion.complemento',
                                   dr_telefono           as 'telefono',
                                   dr_correo             as 'correo'
                            from ex_dte_receptor
                            where dr_cod_secuencial = @i_cod_secuencial
                              and dr_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           )
   for JSON path, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
   set @o_json_dte1 = (select
      cuerpoDocumento       = JSON_QUERY(
                           (select dd_num_item          as 'numItem',
                                   dd_tipo_item         as 'tipoItem',
                                   dd_num_documento     as 'numeroDocumento',
                                   dd_cantidad          as 'cantidad',
                                   dd_codigo            as 'codigo',
                                   null                 as 'codTributo',
                                   dd_uni_medida        as 'uniMedida',
                                   dd_descripcion       as 'descripcion',
                                   dd_precio_unitario   as 'precioUni',
                                   dd_descuento         as 'montoDescu',
                                   dd_venta_nosujeta    as 'ventaNoSuj',
                                   dd_venta_exenta      as 'ventaExenta',
                                   dd_venta_gravada     as 'ventaGravada',
                                   (case when dd_venta_gravada = 0 then null
                                    else JSON_QUERY('["'+ dd_tributos + '"]') end) as 'tributos'
                            from ex_dte_detalle
                            where dd_cod_secuencial = @i_cod_secuencial
                              and dd_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES)
                           ),
      resumen               = JSON_QUERY(
                           (select dt_total_nosujetas       as 'totalNoSuj',
                                 dt_total_exentas           as 'totalExenta',
                                 dt_total_gravadas          as 'totalGravada',
                                 dt_subtotal_ventas         as 'subTotalVentas',
                                 dt_desc_nosujetas          as 'descuNoSuj',
                                 dt_desc_exentas            as 'descuExenta',
                                 dt_desc_gravadas           as 'descuGravada',
                                 dt_total_descuento         as 'totalDescu',
                                 JSON_QUERY(@w_tributos)    as 'tributos',
                                 dt_subtotal                as 'subTotal',
                                 (case when dt_total_gravadas = 0 then 0
                                 else dt_iva_percibido end) as 'ivaPerci1',
                                 (case when dt_total_gravadas = 0 then 0
                                 else dt_iva_retenido end)  as 'ivaRete1',
                                 dt_rete_renta              as 'reteRenta',
                                 dt_monto_total_ope         as 'montoTotalOperacion',
                                 dt_total_letras            as 'totalLetras',
                                 dt_cond_operacion          as 'condicionOperacion'
                            from ex_dte_total      
                            where dt_cod_secuencial = @i_cod_secuencial
                              and dt_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           ),
      extension            = JSON_QUERY(
                           (select de_nombre_entrega   as 'nombEntrega',
                                 de_docu_entrega       as 'docuEntrega',
                                 de_nombre_recibe      as 'nombRecibe',
                                 de_docu_recibe        as 'docuRecibe',
                                 de_observacion        as 'observaciones'
                            from ex_dte_extension
                            where de_cod_secuencial = @i_cod_secuencial
                              and de_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           ),
      apendice            = JSON_QUERY(
                           (select da_campo    as 'campo',
                                 da_etiqueta   as 'etiqueta',
                                 da_valor      as 'valor'
                            from ex_dte_apendice
                            where da_cod_secuencial = @i_cod_secuencial
                              and da_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES)
                           ),
      ventaTercero         = null,
      documentoRelacionado   = JSON_QUERY(
                           (select dc_tipo_documento   as 'tipoDocumento',
                                 dc_tipo_generacion    as 'tipoGeneracion',
                                 dc_num_documento      as 'numeroDocumento',
                                 dc_fecha_emision      as 'fechaEmision'
                            from ex_dte_doc_relacionado
                            where dc_cod_secuencial = @i_cod_secuencial
                              and dc_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES)
                           )
   for JSON path, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
end
else   -- Factura o comprobante de credito fiscal
if @w_tipo_dte IN ('01','03')
begin
   set @o_json_dte = (select
      identificacion        = JSON_QUERY(
                           (select @w_version             as 'version',
                                   @w_ambiente            as 'ambiente',
                                   @w_tipo_dte            as 'tipoDte',
                                   @w_num_control         as 'numeroControl' ,
                                   @w_cod_generacion      as 'codigoGeneracion',
                                   @w_tipo_modelo         as 'tipoModelo',
                                   @w_tipo_operacion      as 'tipoOperacion',
                                   @w_tipo_contingencia   as 'tipoContingencia',
                                   @w_motivo_contin       as 'motivoContin',
                                   @w_fecha_emision       as 'fecEmi',
                                   @w_hora_emision        as 'horEmi',
                                   @w_tipo_moneda         as 'tipoMoneda'
                            for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           ),
      emisor               = JSON_QUERY(
                           (select dm_nit                    as 'nit',
                                   dm_nrc                    as 'nrc',
                                   dm_nombre                 as 'nombre',
                                   dm_cod_actividad          as 'codActividad',
                                   dm_desc_ctividad          as 'descActividad',
                                   dm_nombre_comercial       as 'nombreComercial',
                                   dm_tipo_establecimiento   as 'tipoEstablecimiento',
                                   dm_dir_departamento       as 'direccion.departamento',
                                   dm_dir_municipio          as 'direccion.municipio',
                                   dm_dir_complemento        as 'direccion.complemento',
                                   dm_telefono               as 'telefono',
                                   dm_correo                 as 'correo',
                                   null                      as 'codEstableMH',
                                   null                      as 'codEstable',
                                   null                      as 'codPuntoVentaMH',
                                   null                      as 'codPuntoVenta'
                            from ex_dte_emisor
                            where dm_cod_secuencial = @i_cod_secuencial
                              and dm_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           ),
      receptor            = JSON_QUERY(
                           case when @w_tipo_dte = '01' then
                              (select dr_tipo_doc         as 'tipoDocumento',
                                    dr_numero_doc         as 'numDocumento',
                                    dr_nrc                as 'nrc',
                                    dr_nombres            as 'nombre',
                                    dr_cod_actividad      as 'codActividad',
                                    dr_desc_ctividad      as 'descActividad',
                                    dr_dir_departamento   as 'direccion.departamento',
                                    dr_dir_municipio      as 'direccion.municipio',
                                    dr_dir_complemento    as 'direccion.complemento',
                                    dr_telefono           as 'telefono',
                                    dr_correo             as 'correo'
                               from ex_dte_receptor
                               where dr_cod_secuencial = @i_cod_secuencial
                                 and dr_fecha_proceso  = @i_fecha_proc
                               for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           else
                              (select dr_numero_doc       as 'nit', 
                                    dr_nrc                as 'nrc', 
                                    dr_nombres            as 'nombre', 
                                    dr_cod_actividad      as 'codActividad', 
                                    dr_desc_ctividad      as 'descActividad', 
                                    dr_nombre_comercial   as 'nombreComercial', 
                                    dr_dir_departamento   as 'direccion.departamento', 
                                    dr_dir_municipio      as 'direccion.municipio', 
                                    dr_dir_complemento    as 'direccion.complemento', 
                                    dr_telefono           as 'telefono', 
                                    dr_correo             as 'correo'
                              from ex_dte_receptor
                              where dr_cod_secuencial = @i_cod_secuencial
                                and dr_fecha_proceso  = @i_fecha_proc
                              for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           end
                        )
   for JSON path, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
   set @o_json_dte1 = (select
      cuerpoDocumento       = JSON_QUERY(
                           case when @w_tipo_dte = '01' then
                              (select dd_num_item        as 'numItem',
                                    dd_tipo_item         as 'tipoItem',
                                    dd_num_documento     as 'numeroDocumento',
                                    dd_cantidad          as 'cantidad',
                                    dd_codigo            as 'codigo',
                                    null                 as 'codTributo',
                                    dd_uni_medida        as 'uniMedida',
                                    dd_descripcion       as 'descripcion',
                                    dd_precio_unitario   as 'precioUni',
                                    dd_descuento         as 'montoDescu',
                                    dd_venta_nosujeta    as 'ventaNoSuj',
                                    dd_venta_exenta      as 'ventaExenta',
                                    dd_venta_gravada     as 'ventaGravada',
                                    (case when dd_venta_gravada = 0 then null
                                     else JSON_QUERY('["'+ dd_tributos + '"]') end) as 'tributos',
                                    dd_psv               as 'psv',
                                    dd_no_gravado        as 'noGravado',
                                    dd_iva_item          as 'ivaItem'
                               from ex_dte_detalle
                               where dd_cod_secuencial = @i_cod_secuencial
                                 and dd_fecha_proceso  = @i_fecha_proc
                               for JSON path, INCLUDE_NULL_VALUES)
                           when @w_tipo_dte = '03' then 
                              (select dd_num_item        as 'numItem',
                                    dd_tipo_item         as 'tipoItem',
                                    dd_num_documento     as 'numeroDocumento',
                                    dd_cantidad          as 'cantidad',
                                    dd_codigo            as 'codigo',
                                    null                 as 'codTributo',
                                    dd_uni_medida        as 'uniMedida',
                                    dd_descripcion       as 'descripcion',
                                    dd_precio_unitario   as 'precioUni',
                                    dd_descuento         as 'montoDescu',
                                    dd_venta_nosujeta    as 'ventaNoSuj',
                                    dd_venta_exenta      as 'ventaExenta',
                                    dd_venta_gravada     as 'ventaGravada',
                                    (case when dd_venta_gravada = 0 then null
                                     else JSON_QUERY('["'+ dd_tributos + '"]') end) as 'tributos',
                                    dd_psv               as 'psv',
                                    dd_no_gravado        as 'noGravado'
                               from ex_dte_detalle
                               where dd_cod_secuencial = @i_cod_secuencial
                                 and dd_fecha_proceso  = @i_fecha_proc
                               for JSON path, INCLUDE_NULL_VALUES)
                           end
      ),
      resumen               = JSON_QUERY(
                           case when @w_tipo_dte = '01' then -- Factura
                              (select dt_total_nosujetas           as 'totalNoSuj',
                                      dt_total_exentas             as 'totalExenta',
                                      dt_total_gravadas            as 'totalGravada',
                                      dt_subtotal_ventas           as 'subTotalVentas',
                                      dt_desc_nosujetas            as 'descuNoSuj',
                                      dt_desc_exentas              as 'descuExenta',
                                      dt_desc_gravadas             as 'descuGravada',
                                      dt_porc_descuento            as 'porcentajeDescuento',
                                      dt_total_descuento           as 'totalDescu',
                                      JSON_QUERY(@w_tributos)      as 'tributos',
                                      dt_subtotal                  as 'subTotal',
                                      (case when dt_total_gravadas = 0 then 0
                                       else dt_iva_retenido end)   as 'ivaRete1',
                                      dt_rete_renta                as 'reteRenta',
                                      dt_monto_total_ope           as 'montoTotalOperacion',
                                      dt_total_nogravado           as 'totalNoGravado',
                                      dt_total_pagar               as 'totalPagar',
                                      dt_total_letras              as 'totalLetras',
                                      dt_cond_operacion            as 'condicionOperacion',
                                      dt_total_iva                 as 'totalIva',
                                      null                         as 'pagos',
                                      null                         as 'numPagoElectronico',
                                      0.0                          as 'saldoFavor'
                               from ex_dte_total
                               where dt_cod_secuencial = @i_cod_secuencial
                                 and dt_fecha_proceso  = @i_fecha_proc
                               for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           when @w_tipo_dte = '03' then --Comprobante de credito fiscal
                              (select dt_total_nosujetas          as 'totalNoSuj',
                                      dt_total_exentas            as 'totalExenta',
                                      dt_total_gravadas           as 'totalGravada',
                                      dt_subtotal_ventas          as 'subTotalVentas',
                                      dt_desc_nosujetas           as 'descuNoSuj',
                                      dt_desc_exentas             as 'descuExenta',
                                      dt_desc_gravadas            as 'descuGravada',
                                      dt_porc_descuento           as 'porcentajeDescuento',
                                      dt_total_descuento          as 'totalDescu',
                                      JSON_QUERY(@w_tributos)     as 'tributos',
                                      dt_subtotal                 as 'subTotal',
                                      (case when dt_total_gravadas = 0 then 0
                                      else dt_iva_percibido end)  as 'ivaPerci1',
                                      (case when dt_total_gravadas = 0 then 0
                                      else dt_iva_retenido end)   as 'ivaRete1',
                                      dt_rete_renta               as 'reteRenta',
                                      dt_monto_total_ope          as 'montoTotalOperacion',
                                      dt_total_nogravado          as 'totalNoGravado',
                                      dt_total_pagar              as 'totalPagar',
                                      dt_total_letras             as 'totalLetras',
                                      dt_cond_operacion           as 'condicionOperacion',
                                      null                        as 'pagos',
                                      null                        as 'numPagoElectronico',
                                      0.0                         as 'saldoFavor'
                               from ex_dte_total      
                               where dt_cod_secuencial = @i_cod_secuencial
                                 and dt_fecha_proceso  = @i_fecha_proc
                               for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           end
      ),
      extension            = JSON_QUERY(
                           (select de_nombre_entrega   as 'nombEntrega',
                                   de_docu_entrega     as 'docuEntrega',
                                   de_nombre_recibe    as 'nombRecibe',
                                   de_docu_recibe      as 'docuRecibe',
                                   de_observacion      as 'observaciones',
                                   de_placa_vehiculo   as 'placaVehiculo'
                            from ex_dte_extension
                            where de_cod_secuencial = @i_cod_secuencial
                              and de_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           ),
      apendice            = JSON_QUERY(
                           (select da_campo      as 'campo',
                                   da_etiqueta   as 'etiqueta',
                                   da_valor      as 'valor'
                            from ex_dte_apendice
                            where da_cod_secuencial = @i_cod_secuencial
                              and da_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES)
                           ),
      ventaTercero         = JSON_QUERY(
                           (select dv_nit      as 'nit',
                                   dv_nombre   as 'nombre'
                            from ex_dte_venta_tercero
                            where dv_cod_secuencial = @i_cod_secuencial
                              and dv_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
                           ),
      documentoRelacionado   = JSON_QUERY(
                           (select dc_tipo_documento    as 'tipoDocumento',
                                   dc_tipo_generacion   as 'tipoGeneracion',
                                   dc_num_documento     as 'numeroDocumento',
                                   dc_fecha_emision     as 'fechaEmision'
                            from ex_dte_doc_relacionado
                            where dc_cod_secuencial = @i_cod_secuencial
                              and dc_fecha_proceso  = @i_fecha_proc
                            for JSON path, INCLUDE_NULL_VALUES)
                           ),
      otrosDocumentos         = null
   for JSON path, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
end
else   -- Anulacion
if @w_tipo_dte IN ('20')
begin
   set @o_json_dte = JSON_QUERY(
                        (select @w_ambiente              as 'ambiente',
                                @w_version               as 'version',
                                @w_fecha_emision         as 'fecAnula',
                                @w_hora_emision          as 'horAnula',
                                @w_cod_generacion        as 'codigoGeneracion',
                                @w_du_cod_generacion     as 'codigoGeneracionAnular',
                                @w_du_cod_generacionR    as 'codigoGeneracionR',
                                @w_do_nombre_responsa    as 'nombreResponsable',
                                @w_do_tip_doc_respons    as 'tipDocResponsable',
                                @w_do_num_doc_respons    as 'numDocResponsable',
                                @w_do_nombre_solicita    as 'nombreSolicita',
                                @w_do_tip_doc_solicita   as 'tipDocSolicita',
                                @w_do_num_doc_solicita   as 'numDocSolicita',
                                @w_do_tipo_anulacion     as 'tipoAnulacion',
                                @w_do_motivo_anulacion   as 'motivoAnulacion'
                        for JSON path, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER))
end

set @o_tipo_dte = @w_tipo_dte

return 0
go
