/********************************************************************/
/*    NOMBRE LOGICO: sp_dte                                         */
/*    NOMBRE FISICO: sp_dte.sp                                      */
/*    PRODUCTO: Teller                                              */
/*    Disenado por: Dario Sarango                                   */
/*    Fecha de escritura: 29-Mar-2023                               */
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
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                           PROPOSITO                              */
/*    Permite la consulta de DTE de tanque de datos                 */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  29-Mar-2023      D. Sarango       Emision Inicial               */
/*  11-Abr-2023      D. Sarango       FEC-S809474-ENL se ajusta     */
/*                                    select de DTEs                */
/*  01-May-2023      D. Sarango       TEL-S809030-ENL se ajusta     */
/*                                    tipos de datos                */
/*  22-May-2023      D. Sarango       TEL-S787905-ENL se ajusta     */
/*                                    campos en select principal    */
/*  25-Jul-2023      D. Sarango       TEL-S787905-ENL se ajusta     */
/*                                    campos en select principal    */
/*  20-Sep-2023      D. Sarango       FEC-B904197-ENL búsqueda por  */
/*                                    cod. de generacion            */
/*  05-Dic-2023      A. Quishpe       RM-220648 Agregar with(nolock)*/
/*  02-Ene-2024      D. Sarango       RM-221502 filtros por oficina */
/*                                    y snn, datos adicionales      */
/*  03-Ene-2024      D. Sarango       RM-221502 ajuste en consulta  */
/*                                    dtes anulados y orden         */
/*  04-Ene-2024      D. Sarango       RM-221502 ajuste en consulta  */
/*                                    por los diferentes canales    */
/*  04-Ene-2024      D. Sarango       RM-221502 Agregar with(nolock)*/
/********************************************************************/
use cob_externos
go

if object_id('sp_dte') is not null
begin
   drop procedure sp_dte
end
go

create proc sp_dte (
   @s_ssn               int            = null,
   @s_user              login          = null,
   @s_sesn              int            = null,
   @s_term              varchar(32)    = null,
   @s_date              datetime       = null,
   @s_srv               varchar(30)    = null,
   @s_lsrv              varchar(30)    = null,
   @s_rol               smallint       = null,
   @s_ofi               smallint       = null,
   @s_org_err           char(1)        = null,
   @s_error             int            = null,
   @s_sev               tinyint        = null,
   @s_msg               descripcion    = null,
   @s_org               char(1)        = null,
   @t_debug             char(1)        = 'N',
   @t_file              varchar(14)    = null,
   @t_from              varchar(32)    = null,
   @t_trn               int            = null,
   @t_show_version      bit = 0,
   @i_operacion         char(1),
   @i_cod_ope           varchar(20)    = null,
   @i_estado            varchar(10)    = null,
   @i_cli_id            varchar(20)    = null,
   @i_fecha_ini         datetime       = null,
   @i_fecha_fin         datetime       = null,
   @i_producto          int            = null,
   @i_num_fac           varchar(36)    = null,
   @i_secuencial        int            = null,
   @i_fecha_proceso     datetime       = null,
   @i_monto             money          = null,
   @i_cliente           varchar(50)    = null,
   @i_oficina           smallint       = null,
   @i_ssn               int            = null
)
as
declare
@w_sp_name      varchar(50),
@w_return       int

select @w_sp_name = 'sp_dte'

if @t_show_version = 1
begin
   print 'Stored Procedure Version 1.0.0.0' + @w_sp_name
   return 0
end

if @i_operacion = 'Q'
begin
   select dq_ssn,
          dq_fecha_proceso,
          dr_numero_doc,
          dr_nrc,
          dr_nombres,
          dq_nro_cod_operacion,
          dq_producto,
          (select valor
             from cobis..cl_catalogo
            where tabla = (select codigo
                             from cobis..cl_tabla
                            where tabla = 'cl_fac_tipo_documento')
              and codigo = di_tipo_dte),
          (select valor
             from cobis..cl_catalogo
            where tabla = (select codigo
                             from cobis..cl_tabla
                            where tabla = 'cl_estados_dte')
              and codigo = dq_estado),
          dq_estado,
          dq_descripcion_msg,
          dq_observaciones,
          dq_monto,
          di_cod_generacion,
          case dq_correccion when 'S' then 'SI' else 'NO' end,
          case dq_estado_correccion when 'R' then 'REVERSADO' else null end,
          dq_ssn_correccion
     from cob_externos..ex_dte_requerimiento  with (nolock),
          cob_externos..ex_dte_identificacion with (nolock),
          cob_externos..ex_dte_receptor       with (nolock)
    where convert(varchar, dq_fecha_proceso, 101) between @i_fecha_ini and @i_fecha_fin
      and (dr_cod_secuencial = dq_ssn or dr_cod_secuencial = dq_ssn_correccion)
      and di_cod_secuencial = dq_ssn
      and (@i_cod_ope   is null or dq_nro_cod_operacion  = @i_cod_ope)
      and (@i_producto  is null or di_tipo_dte           = @i_producto)
      and (
         @i_estado is null or (
            dq_estado = @i_estado or (
               @i_estado = 'A' and (
                  dq_estado = 'A' or dq_ssn_correccion in (
                     select principal.dq_ssn
                       from cob_externos..ex_dte_requerimiento as principal with (nolock)
                      where principal.dq_estado = 'A'
                  )
               )
            )
         )
      )
      and (@i_num_fac   is null or di_cod_generacion     = @i_num_fac)
      and (@i_monto     is null or dq_monto              = @i_monto)
      and (@i_cliente   is null or dr_numero_doc         = @i_cliente)
      and (@i_ssn       is null or dq_ssn                = @i_ssn
                                or dq_ssn_correccion     = @i_ssn)
      and (
         @i_oficina is null
         or
         exists (select 1 from cob_cartera..ca_abono ca with (nolock) where ca.ab_ssn = dq_ssn and (ca.ab_oficina = @i_oficina OR ca.ab_oficina is null))
      )
      order by
      case when dq_ssn_correccion is null then dq_ssn
      else dq_ssn_correccion end,
      dq_ssn asc

      if @@rowcount = 0
      begin
         exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from = @w_sp_name,
            @i_num  = 2609998

         return 2609998
      end
end

if @i_operacion = 'S'
begin
   -- IDENTIFICACION
   select di_version,
          (select valor
             from cobis..cl_catalogo
            where tabla = (select codigo
                             from cobis..cl_tabla
                            where tabla = 'cl_fac_ambiente_destino')
              and codigo = di_ambiente),
          di_tipo_dte,
          di_num_control,
          di_cod_generacion,
          di_tipo_modelo,
          di_tipo_operacion,
          di_tipo_contingencia,
          di_motivo_contin,
          di_fecha_emision,
          di_hora_emision,
          di_tipo_moneda
     from cob_externos..ex_dte_identificacion with (nolock)
    where di_cod_secuencial = @i_secuencial
      and di_fecha_proceso  = @i_fecha_proceso

   -- EMISOR
   select dm_nit,
          dm_nrc,
          dm_nombre,
          dm_cod_actividad,
          dm_desc_ctividad,
          dm_nombre_comercial,
          dm_tipo_establecimiento,
          'DIRECCION',
          dm_dir_departamento,
          dm_dir_municipio,
          dm_dir_complemento,
          dm_telefono,
          dm_correo,
          'codEstableMH'    = NULL,
          'codEstable'      = NULL,
          'codPuntoVentaMH' = NULL,
          'codPuntoVenta'   = NULL
     from cob_externos..ex_dte_emisor with (nolock)
    where dm_cod_secuencial = @i_secuencial
      and dm_fecha_proceso  = @i_fecha_proceso

   -- RECEPTOR
   select dr_tipo_doc,
          dr_numero_doc,
          dr_nrc,
          dr_nombres,
          dr_cod_actividad,
          dr_desc_ctividad,
          dr_nombre_comercial,
          'DIRECCION',
          dr_dir_departamento,
          dr_dir_municipio,
          dr_dir_complemento,
          dr_telefono,
          dr_correo
     from cob_externos..ex_dte_receptor with (nolock)
    where dr_cod_secuencial = @i_secuencial
      and dr_fecha_proceso  = @i_fecha_proceso

   --CUERPO
   select dd_num_item,
          dd_tipo_item,
          dd_num_documento,
          dd_cantidad,
          dd_codigo,
          dd_cod_tributo,
          dd_uni_medida,
          dd_descripcion,
          dd_precio_unitario,
          dd_descuento,
          dd_venta_nosujeta,
          dd_venta_exenta,
          dd_venta_gravada,
          dd_tributos,
          'ITEMS' = null,
          dd_psv,
          dd_no_gravado,
          dd_iva_item
     from cob_externos..ex_dte_detalle with (nolock)
    where dd_cod_secuencial = @i_secuencial
      and dd_fecha_proceso  = @i_fecha_proceso

   --EXTENSION
   select de_nombre_entrega,
          de_docu_entrega,
          de_nombre_recibe,
          de_docu_recibe,
          de_observacion
     from cob_externos..ex_dte_extension
    where de_cod_secuencial = @i_secuencial
      and de_fecha_proceso  = @i_fecha_proceso

   --APENDICE
   select da_campo,
          da_etiqueta,
          da_valor
     from cob_externos..ex_dte_apendice with (nolock)
    where da_cod_secuencial = @i_secuencial
      and da_fecha_proceso  = @i_fecha_proceso

   --VENTA TERCERO
   select dv_nit,
          dv_nombre
     from cob_externos..ex_dte_venta_tercero
    where dv_cod_secuencial = @i_secuencial
      and dv_fecha_proceso  = @i_fecha_proceso

   --DOCUMENTO RELACIONADO
   select dc_tipo_documento,
          dc_tipo_generacion,
          dc_num_documento,
          dc_fecha_emision
     from cob_externos..ex_dte_doc_relacionado
    where dc_cod_secuencial = @i_secuencial
      and dc_fecha_proceso  = @i_fecha_proceso
end

return 0
go
