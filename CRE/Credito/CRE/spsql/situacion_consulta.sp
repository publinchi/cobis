/************************************************************************/
/*  Archivo:                situacion_consulta.sp                       */
/*  Stored procedure:       sp_situacion_consulta                       */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
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
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_situacion_consulta')
    drop proc sp_situacion_consulta
go

create proc sp_situacion_consulta(
   @s_user               login       = null,
   @s_ssn                int         = null,
   @s_sesn               int         = null,
   @s_date               datetime    = null,
   @t_file               varchar(14) = null,
   @t_debug              char(1)     = 'N',
   @i_tramite            int         = 0,
   @i_operacion_i        int         = 0,
   @i_cliente            int         = null,
   @i_grupo              int         = null,
   @i_cliente_sig        int         = 0,
   @i_operacion          char(1)     = null,
   @i_modo_c             char(2)     = null,
   @i_en_tramite         char(1)     = null,
   @i_modo               int         = null,
   @i_operacion_ban      cuenta      = ' ',
   @i_cabecera           char(1)     = null,
   @i_retorna            char(1)     = null,
   @i_usuario            login       = null,
   @i_secuencia          int         = null,
   @i_categoria          char(2)     = null,
   @i_formato_fecha      int         = null,
   @i_tramite_d          int         = null,
   @i_tipo_deuda         char(1)     = null,
   @i_prendario          char(1)     = 'S',      -- Considera Prendarios
   @i_vista_360          char(1)     = 'N',      -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS
   @t_show_version       bit         = 0,        -- Mostrar la version del programa
   @o_total_deuda        money       = null out
)
as
declare
   @w_sp_name            varchar(32),
   @w_fecha              datetime,
   @w_total              money,
   @w_registros          varchar(10),
   @w_total_registros    int,
   @w_total_cca          money,
   @w_total_tram         money,
   @w_total_lin          money,
   @w_total_ling         money,
   @w_total_prefactor    money,
   @w_total_ind          money,
   @w_tabla_calif        int,
   @w_spid               smallint,
   @w_total_sob          money,
   @w_deuda_directa      money,
   @w_deuda_indirecta    money,
   @w_deuda_contingente  money,
   @w_linea              int,
   @w_monto_solicitado   money,
   @w_total_other        money

select @w_sp_name = 'sp_situacion_consulta'

if @t_show_version = 1
begin
   print 'Stored procedure sp_situacion_consulta, Version 4.0.0.3'
   return 0
end

--Obtengo numero de proceso
select @w_spid = @@spid

-- Cargo fecha de proceso
select @w_fecha = fp_fecha
from cobis..ba_fecha_proceso

select @i_tramite_d = isnull(@i_tramite_d,0)
---------------------------CONSULTA DESDE VISTA CONSOLIDADA----------------------------
if @i_vista_360 = 'S'
begin
   if @i_operacion = 'S'
   begin
      --Informacion de Clientes e Informacion de Afiliaciones a Global Net
      if @i_modo_c = 'C' or @i_modo_c = 'A'
      begin
         exec sp_situacion_cliente
            @s_user               = @s_user,
            @s_ssn                = @s_ssn,
            @s_sesn               = @s_sesn,
            @s_date               = @s_date,
            @i_tramite            = @i_tramite,
            @i_cliente            = @i_cliente,
            @i_cliente_sig        = @i_cliente_sig,
            @i_operacion          = @i_operacion,
            @i_modo_c             = @i_modo_c,
            @i_en_tramite         = @i_en_tramite,
            @i_modo               = @i_modo,
            @i_usuario            = @i_usuario,
            @i_secuencia          = @i_secuencia,
            @i_categoria          = @i_categoria,
            @i_formato_fecha      = @i_formato_fecha,
            @i_tramite_d          = @i_tramite_d,
            @i_operacion_ban      = @i_operacion_ban,
            @i_tipo_deuda         = @i_tipo_deuda
      end

      --Informacion de Inversiones
      if @i_modo_c = 'I' or @i_modo_c = 'T'
      begin
         if @i_modo = 1       --Cuenta Corrientes
         begin
            select
               'cliente'          = sc_cliente,
               'producto'   = a.si_producto,
               'desc_tipo_op'     = a.si_desc_tipo_op,
               'cuenta'           = a.si_numero_operacion,
               'tasa'             = str(a.si_tasa, 12, 4),
               'fecha_apt'        = convert(char(10),a.si_fecha_apt,@i_formato_fecha),
               'desc_moneda'      = (select mo_nemonico from cobis..cl_moneda where mo_moneda = a.si_moneda),
               'fecha_ult_mov'    = convert(char(10),a.si_fecha_ult_mov,@i_formato_fecha),
               'monto_pignorado'  = isnull( si_monto_prendado, 0),
               'limite_sobregiro' = isnull( si_valor_mercado, 0),
               'saldo'            = a.si_saldo,
               'saldo_ml'         = a.si_saldo_ml,
               'disponible'       = a.si_interes_acumulado,
               'disponible_ml'    = a.si_valor_mercado_ml,
               'canje'            = isnull(a.si_valor_garantia, 0),
               'protesto'         = isnull( si_operacion, 0),
               'estado'           = substring( a.si_desc_estado, 1, 64),
               'moneda'           = null,
               'rol'              = null,
               'retenciones'      = a.si_valor_garantia,
               'bloqueos'         = a.si_bloqueos,
               'nombre_cliente'   = sc_nombre_cliente
            from  cr_situacion_cliente,
                  cr_situacion_inversiones a
            where sc_cliente     = a.si_cliente
            and   a.si_producto  = 'CTE'
            and   sc_usuario     = @s_user
            and   sc_secuencia   = @s_sesn
            and   sc_tramite     = @i_tramite
            and   sc_usuario     = a.si_usuario
            and   sc_secuencia   = a.si_secuencia
            and   sc_tramite     = a.si_tramite
            and   a.si_numero_operacion > @i_operacion_ban
            order by a.si_numero_operacion
         end

         if @i_modo = 9       --CUENTAS de AHORROS
         begin
            select
               'cliente'          = sc_cliente,
               'producto'         = a.si_producto,
               'desc_tipo_op'     = a.si_desc_tipo_op,
               'cuenta'           = a.si_numero_operacion,
               'tasa'             = str( a.si_tasa, 12, 4),
               'fecha_apt'        = convert(char(10),a.si_fecha_apt,@i_formato_fecha),
               'desc_moneda'      = (select mo_nemonico from cobis..cl_moneda where mo_moneda = a.si_moneda),
               'fecha_ult_mov'    = convert(char(10),a.si_fecha_ult_mov,@i_formato_fecha),
               'monto_pignorado'  = isnull( si_monto_prendado, 0),
               'saldo'            = a.si_saldo,
               'saldo_ml'         = a.si_saldo_ml,
               'disponible'       = a.si_interes_acumulado,
               'disponible_ml'    =  a.si_valor_mercado,
               'canje'            = a.si_valor_garantia,
               'estado'           = substring( a.si_desc_estado, 1, 64),
               'moneda'           = null,
               'rol'              = null,
               'retenciones'      = a.si_valor_garantia,
               'bloqueos'         = a.si_bloqueos,
               'nombre_cliente'   = sc_nombre_cliente
            from  cr_situacion_cliente,
                  cr_situacion_inversiones a
            where sc_cliente     = a.si_cliente
            and   a.si_producto  = 'AHO'
            and   sc_usuario     = @s_user
            and   sc_secuencia   = @s_sesn
            and   sc_tramite     = @i_tramite
            and   sc_usuario     = a.si_usuario
            and   sc_secuencia   = a.si_secuencia
            and   sc_tramite     = a.si_tramite
            and   a.si_numero_operacion > @i_operacion_ban
            order by a.si_numero_operacion
         end

         if @i_modo = 2      --Plazo Fijo
         begin
             select
               'cliente'           = sc_cliente,
               'producto'          = a.si_producto,
               'desc_tipo_op'      = a.si_desc_tipo_op,
               'cuenta'            = a.si_numero_operacion,
               'fecha_apt'         = convert(char(10),a.si_fecha_apt,@i_formato_fecha),
               'fecha_fin'         = convert(char(10),a.si_fecha_vct,@i_formato_fecha),
               'desc_moneda'       = (select mo_nemonico from cobis..cl_moneda where mo_moneda = a.si_moneda),
               'tasa'              = str( a.si_tasa, 12, 4),
               'saldo'             = a.si_saldo,
               'saldo_ml'          = a.si_saldo_ml,
               'interes_acumulado' = a.si_interes_acumulado,
               'valor_pignorado'   = a.si_monto_prendado,
               'fecha_prox_p_int'  = convert(char(10),a.si_fecha_prox_p_int,@i_formato_fecha),
               'fecha_utl_p_int'   = convert(char(10),a.si_fecha_utl_p_int,@i_formato_fecha),
               'tipo_operacion'    = ' ',
               'moneda'            = null,
               'rol'               = null,
               'nombre_cliente' = sc_nombre_cliente
            from cr_situacion_cliente,
                 cr_situacion_inversiones a
            where sc_cliente     = a.si_cliente
            and   a.si_categoria = '02'
            and   a.si_producto  = 'PFI'
            and   sc_usuario     = @s_user
            and   sc_secuencia   = @s_sesn
            and   sc_tramite     = @i_tramite
            and   sc_usuario     = a.si_usuario
            and   sc_secuencia   = a.si_secuencia
            and   sc_tramite     = a.si_tramite
            and   a.si_numero_operacion > @i_operacion_ban
            order by a.si_numero_operacion asc
         end

         if @i_modo = 3  --Inversiones
         begin
            select
               'cliente'        = sc_cliente,
               'producto'       = a.si_producto,
               'desc_tipo_op'   = a.si_desc_tipo_op,
               'operacion'      = a.si_operacion,
               'fecha_apt'      = convert(char(10), a.si_fecha_apt,@i_formato_fecha),
               'fecha_ven'      = convert(char(10), a.si_fecha_vct,@i_formato_fecha),
               'desc_moneda'    = (select mo_nemonico from cobis..cl_moneda where mo_moneda = a.si_moneda),
               'tasa'           = str( a.si_tasa, 12, 4),
               'monto_ini'      = a.si_saldo,
               'monto_ini_ml'   = a.si_saldo_ml,
               'saldo_actual'   = a.si_saldo_promedio,
               'saldo_actual_ml'= a.si_valor_garantia,
               'interes_actual' = a.si_interes_acumulado,
               'interes_ven'    = a.si_valor_mercado,
               'fecha_renova'   = convert(char(10), a.si_fecha_ult_mov,@i_formato_fecha),
               'moneda'         = null,
               ' ',
               ' ',
               'nombre_cliente' = sc_nombre_cliente
            from cr_situacion_cliente,
                 cr_situacion_inversiones a
            where sc_cliente     = a.si_cliente
            and   a.si_categoria = @i_categoria --'03'
            and   sc_usuario     = @s_user
            and   sc_secuencia   = @s_sesn
            and   sc_tramite     = @i_tramite
            and   a.si_producto  <> 'PFI'
            and   sc_usuario     = a.si_usuario
            and   sc_secuencia   = a.si_secuencia
            and   sc_tramite     = a.si_tramite
            and   a.si_operacion > @i_operacion_i
            order by a.si_operacion

            set rowcount 0
         end

         if @i_modo = 4       --TARJETAS DE DEBITO
         begin
            select
               'cliente'        = sc_cliente,
               'producto'       = a.si_producto,
               'desc_tipo_op'   = a.si_desc_tipo_op,
               'cuenta'         = a.si_numero_operacion,
               'cupo_online'    = si_saldo_ml,
               'estado'         = substring( a.si_desc_estado, 1, 64),
               'fecha_apt'      = convert(char(10),a.si_fecha_apt,@i_formato_fecha),
         'creado_por'     = a.si_login,
               'nombre_cliente' = sc_nombre_cliente
            from  cr_situacion_cliente,
                  cr_situacion_inversiones a
            where sc_cliente     = a.si_cliente
            and   a.si_producto  = 'ATM'
            and   sc_usuario     = @s_user
            and   sc_secuencia   = @s_sesn
            and   sc_tramite     = @i_tramite
            and   sc_usuario     = a.si_usuario
            and   sc_secuencia   = a.si_secuencia
            and   sc_tramite     = a.si_tramite
            and   a.si_numero_operacion > @i_operacion_ban
            order by a.si_numero_operacion

            set rowcount 0
         end
      end

      --Informacion de Deudas
      if @i_modo_c = 'D' or @i_modo_c  = 'T'
      begin
         if @i_modo = 1       --Cartera
         begin
            insert into cr_deud1_tmp (
               spid,
               linea,
               estado_conta,
               estado,
               tasa,
               fecha_apt,
               fecha_vto,
               desc_moneda,
               monto_orig,
               saldo_vencido,
               saldo_cuota,
               subtotal,
               saldo_capital,
               saldo_total,
               saldo_ml,
               refinanciamiento,
               prox_fecha_pag_int,
               ult_fecha_pg,
               clasificacion,
               tipocar,
               valorcontrato,
               rol,
               nombre_cliente,
               restructuracion,
               fecha_cancelacion,
               refinanciado,
               calificacion )
            select
               @w_spid,
               a.sd_tarjeta_visa,
               a.sd_estado,
               a.sd_beneficiario,
               str(a.sd_tasa, 12, 4),
               convert(char(10),a.sd_fecha_apr,@i_formato_fecha),
               convert(char(10),a.sd_fecha_vct,@i_formato_fecha),
               (select mo_nemonico
               from cobis..cl_moneda
               where mo_moneda = a.sd_moneda),
               a.sd_monto_orig,
               a.sd_saldo_vencido,
               a.sd_saldo_promedio,
               isnull(a.sd_saldo_vencido, 0) + isnull( a.sd_saldo_promedio, 0),
               a.sd_total_cargos,
               a.sd_contrato_act, --saldo total --a.sd_saldo_x_vencer,
               a.sd_monto_ml,
               a.sd_subtipo,
               convert(char(10),a.sd_prox_pag_int,@i_formato_fecha),
               convert(char(10),a.sd_ult_fecha_pg,@i_formato_fecha),
               a.sd_calificacion,
               a.sd_tipoop_car,
               a.sd_monto_riesgo,
               a.sd_rol,
               sc_nombre_cliente,
               a.sd_restructuracion,
               a.sd_fecha_cancelacion,
               a.sd_refinanciamiento,
               a.sd_calificacion
            from cr_situacion_cliente,
               cr_situacion_deudas a
            where sc_cliente     = a.sd_cliente
            and   a.sd_producto  = 'CCA'
            and   sc_usuario     = @s_user
            and   sc_secuencia   = @s_sesn
            and   sc_tramite     = @i_tramite
            and   sc_usuario     = a.sd_usuario
            and   sc_secuencia   = a.sd_secuencia
            and   sc_tramite   = a.sd_tramite
            and   a.sd_tipo_deuda= @i_tipo_deuda
            order by sc_cliente, a.sd_categoria, a.sd_producto

            --IOR actualizar el codigo de estado de las operaciones
            UPDATE cr_deud1_tmp
            SET cod_estado = convert(varchar(10),es_codigo)
            FROM cob_cartera..ca_estado
            WHERE estado_conta = es_descripcion
            AND producto = 'CCA'
            AND spid     = @w_spid

            UPDATE cr_deud1_tmp
            SET cod_estado = CAT.codigo
            FROM cr_deud1_tmp DEU, cobis..cl_tabla TAB, cobis..cl_catalogo CAT
            WHERE DEU.estado_conta = CAT.valor
            AND TAB.tabla = 'ce_etapa'
            AND TAB.codigo = CAT.tabla
            AND producto = 'CEX'
            AND spid     = @w_spid

            select
               cliente,
               producto,
               tipo_operacion,
               desc_tipo_op,
               operacion,
               linea,
               tramite,
               fecha_apt,
               fecha_vto,
               desc_moneda,
               monto_orig,
               saldo_vencido,
               saldo_cuota,
               subtotal,
               saldo_capital,
               valorcontrato,
               saldo_total,
               saldo_ml,
               tasa,
               refinanciamiento,
               prox_fecha_pag_int,
               ult_fecha_pg,
               estado_conta,
               clasificacion,
               estado,
               tipocar,
               moneda,
               rol,
               cod_estado,
               nombre_cliente
            from cr_deud1_tmp
            where tramite   > @i_tramite_d
            and   spid      = @w_spid
            order by tramite

            set rowcount 0
         end

         if @i_modo = 2       --Comercio Exterior
         begin
            select
               'cliente'        = sd_cliente,
               'producto'       = a.sd_producto,
               'tipo_operacion' = a.sd_tipo_op,
               'desc_tipo_op'   = a.sd_desc_tipo_op,
               'operacion'      = a.sd_numero_operacion,
               'tipo_gar'       = a.sd_tipo_garantia,
               'desc_gar'       = a.sd_descrip_gar,
               'linea'          = a.sd_tarjeta_visa,
               'tramite'        = a.sd_tramite_d,
               'fecha_apt'      = convert(char(10),a.sd_fecha_apr,@i_formato_fecha),
               'fecha_vto'      = convert(char(10),a.sd_fecha_vct,@i_formato_fecha),
               'desc_moneda'    = (select mo_nemonico from cobis..cl_moneda where mo_moneda = a.sd_moneda),
               'monto'          = a.sd_monto,
               'monto_ml'       = a.sd_monto_ml,
               'saldo'          = a.sd_val_utilizado,
               'saldo_ml'       = a.sd_val_utilizado_ml,
               'clasificacion'  = a.sd_calificacion,
               'fecha_embarque' = a.sd_fechas_embarque,
               'seguro'         = a.sd_aprobado,
               'beneficiario'   = a.sd_beneficiario,
               'estado'         = a.sd_estado,
               'nombre_cliente' = sc_nombre_cliente,
               'valor_contrato' = sd_monto_riesgo
             from cr_situacion_cliente,
                  cr_situacion_deudas a
             where sc_cliente     = a.sd_cliente
             and   a.sd_producto  = 'CEX'
             and   sc_usuario     = @s_user
             and   sc_secuencia   = @s_sesn
             and   sc_tramite     = @i_tramite
             and   sc_usuario     = a.sd_usuario
             and   sc_secuencia   = a.sd_secuencia
             and   sc_tramite     = a.sd_tramite
             and   a.sd_tipo_deuda= @i_tipo_deuda
             and   a.sd_tramite_d > @i_tramite_d
             order by a.sd_tramite_d

            set rowcount 0
         end

         -- SOBREGIRO, OPERACION DE PREFACTORING Y OTRAS OPERACIONES DE COMEXT
         if @i_modo = 4 or  @i_modo = 5 or @i_modo = 6 or @i_modo = 7
         begin
            exec sp_situacion_factoring
               @s_user               = @s_user,
               @s_ssn                = @s_ssn,
               @s_sesn               = @s_sesn,
               @s_date               = @s_date,
               @i_tramite            = @i_tramite,
               @i_cliente            = @i_cliente,
               @i_cliente_sig        = @i_cliente_sig,
               @i_operacion          = @i_operacion,
               @i_modo_c             = @i_modo_c,
               @i_en_tramite         = @i_en_tramite,
               @i_modo               = @i_modo,
               @i_usuario            = @i_usuario,
               @i_secuencia          = @i_secuencia,
               @i_categoria          = @i_categoria,
               @i_formato_fecha      = @i_formato_fecha,
               @i_tramite_d          = @i_tramite_d,
               @i_operacion_ban      = @i_operacion_ban,
               @i_tipo_deuda         = @i_tipo_deuda,
               @i_vista_360          = 'S'
            return 0
         end
      end --if @i_modo_c = 'D' or @i_modo_c  = 'T' deudas

      --Informacion de Lineas
      if @i_modo_c = 'L' or @i_modo_c = 'T'
      begin
         select distinct
            'CLIENTE'                        = a.sl_cliente,
            'TRAMITE'                        = a.sl_tramite_d,
            'TIPO'                           = a.sl_tipo,
            'DESC_TIPO'                      = a.sl_desc_tipo,
            'No.LINEA/ No. CONTRATO DE OBRA' = a.sl_numero_op_banco,
            'FECHA INICIO'                   = convert(char(10),a.sl_fecha_apr,@i_formato_fecha),
            'FECHA VCTO./ ENTREGA'           = convert(char(10),a.sl_fecha_vct,@i_formato_fecha),
            'MONEDA'                         = (select mo_nemonico from cobis..cl_moneda where mo_moneda = a.sl_moneda),
            'LIMITE APROBADO/ VALOR CESION.' = a.sl_limite_credito,
            'UTILIZADO/ VALOR NOMINAL'       = isnull( a.sl_utilizado_ml, 0),
            'UTILIZADO ML/ VALOR NOMINAL ML' = isnull( a.sl_val_utilizado, 0),
            'DISPONIBLE'                     = isnull( a.sl_disponible, 0),
            'DISPONIBLE_ML'                  = isnull( a.sl_disponible_ml, 0),
            'TASA'                           = str(isnull( a.sl_tasa, 0),12, 4),
            'VALOR_CONTRATO'                 = isnull( a.sl_monto_riesgo, 0),
            'LIMITE PREFACTORING'            = isnull( a.sl_monto_factoring, 0),
            'PORCENTAJE CESIONADOO'          = isnull( a.sl_saldo_capital, 0),
            'EXCESO'                         = isnull( a.sl_execeso, 0),
            'EMISOR DEL DOCUMENTO'           = a.sl_emisor,
            'ESTADO'                         = a.sl_desc_estado,
            'TIPO DEUDA'                     = case a.sl_tramite_d
                                                  when 9999999 then ''
                                                  else (case @i_tipo_deuda
                                                           when 'D' then 'DIRECTA'
                                                           else 'INDIRECTA'
                                                        end)
                                               end,
            'NOMBRE'                         = sc_nombre_cliente
         from cr_situacion_cliente,
              cr_situacion_lineas a
         where sc_cliente_con  = a.sl_cliente_con
         and   sc_usuario      = @s_user
         and   sc_secuencia    = @s_sesn
         and   sc_tramite      = @i_tramite
         and   sc_usuario      = sl_usuario
         and   sc_secuencia    = a.sl_secuencia
         and   sc_tramite      = a.sl_tramite
         and   sl_tipo_deuda   = @i_tipo_deuda
         and   (a.sl_tramite_d > @i_tramite_d  or @i_tramite_d = 0)
         order by a.sl_tramite_d, a.sl_numero_op_banco

          set rowcount 0
       end

      --  GARANTIAS EN PRENDA,  GARANTIAS PROPIAS, POLIZAS
      if @i_modo_c = 'G' or @i_modo_c = 'GP' or @i_modo_c = 'P' or @i_modo_c = 'T'
      begin
         exec sp_situacion_gar
            @s_user               = @s_user,
            @s_ssn                = @s_ssn,
            @s_sesn               = @s_sesn,
            @s_date               = @s_date,
            @i_tramite            = @i_tramite,
            @i_cliente            = @i_cliente,
            @i_cliente_sig        = @i_cliente_sig,
            @i_operacion          = @i_operacion,
  @i_modo_c             = @i_modo_c,
            @i_en_tramite         = @i_en_tramite,
            @i_modo               = @i_modo,
            @i_usuario            = @i_usuario,
            @i_secuencia          = @i_secuencia,
            @i_categoria          = @i_categoria,
            @i_formato_fecha      = @i_formato_fecha,
            @i_tramite_d          = @i_tramite_d,
            @i_operacion_ban      = @i_operacion_ban,
            @i_tipo_deuda         = @i_tipo_deuda,
            @i_vista_360          = 'S'
         return 0
      end
   end --@i_operacion = 'S'

   if @i_operacion = 'C'
   begin
      if @i_prendario = 'S'  /** RIESGO NORMAL, CONSIDERA PRENDARIOS **/
      begin
         -- Total de la linea individual del cliente
         select @w_total_lin = (select sum(isnull( sl_monto_riesgo, 0)) from (select distinct  sl_numero_op_banco, sl_monto_riesgo
         from cr_situacion_lineas
         where (sl_cliente_con   = @i_cliente or (@i_grupo is not null and @i_cliente is null))
         and  sl_usuario         = @s_user
         and  sl_secuencia       = @s_sesn
         and  sl_tramite         = @i_tramite
         and  sl_tipo_con        in ( 'C', 'V')
         and  (sl_tipo_deuda     = @i_tipo_deuda or (@i_tipo_deuda = 'T' or @i_tipo_deuda is null ))
         and  sl_numero_op_banco <> ''            -- OGU 16-11-2015 Se descrimina las operaciones con valor vacío
         and  sl_numero_op_banco is not null      -- OGU 16-11-2015 Se descrimina las operaciones con valor NULL
         ) as cr_sitiuacion_lineas_unificada )

         -- Total de la linea del grupo del cual pertenece el cliente
         select @w_total_ling = sum(isnull( sl_disponible_ml, 0)) -- OGU 19-11-2015 Modificación cuadre de valores
         from cr_situacion_lineas
         where @i_grupo      is not null
         and  sl_tipo_con    = 'G'
         and  sl_usuario     = @s_user
         and  sl_secuencia   = @s_sesn
         and  sl_tramite     = @i_tramite
         and  sl_cliente_con is not null
         and  (sl_tipo_deuda = @i_tipo_deuda or (@i_tipo_deuda = 'T' or @i_tipo_deuda is null ))

         -- Total de la deuda Directa que mantengo en Cartera
         select @w_total_cca = sum(sd_monto_riesgo)
         from cr_situacion_deudas
         where (sd_cliente_con = @i_cliente or (@i_grupo is not null and @i_cliente is null))
         and   sd_usuario      = @s_user
         and   sd_secuencia    = @s_sesn
         and   sd_tramite      = @i_tramite
         and  (sd_tipo_deuda   = @i_tipo_deuda or (@i_tipo_deuda = 'T' or @i_tipo_deuda is null ))
         and   sd_producto     = 'CCA'
         and  (sd_tipo_deuda <> 'I')
         and  (sd_estado not in ('CREDITO', 'NO VIGENTE') or sd_estado is null )
         and   sd_numero_operacion <> ''        -- OGU 18-11-2015 Se descrimina las operaciones con valor vacío
         and   sd_numero_operacion is not null  -- OGU 18-11-2015 Se descrimina las operaciones con valor NULL

         -- Total de la sobregiros que mantengo con el cliente
         select @w_total_sob = sum(sd_monto_riesgo)
         from cr_situacion_deudas
         where (sd_cliente_con     = @i_cliente or (@i_grupo is not null and @i_cliente is null))
         and   sd_usuario          = @s_user
         and   sd_secuencia        = @s_sesn
         and   sd_tramite          = @i_tramite
         and  (sd_tipo_deuda       = @i_tipo_deuda or (@i_tipo_deuda = 'T' or @i_tipo_deuda is null ))
         and   sd_producto         = 'SOB'
         and  (sd_estado           != 'CREDITO' or sd_estado is null)
         and   sd_numero_operacion <> ''        -- OGU 18-11-2015 Se descrimina las operaciones con valor vacío
         and   sd_numero_operacion is not null  -- OGU 18-11-2015 Se descrimina las operaciones con valor NULL

         -- Total del tramites que mantengo en Cartera y Contingente de Comext
         select @w_total_tram = sum(sd_monto_riesgo)
         from cr_situacion_deudas
         where (sd_cliente_con = @i_cliente or (@i_grupo is not null and @i_cliente is null))
         and   sd_usuario   = @s_user
         and   sd_secuencia = @s_sesn
         and   sd_tramite   = @i_tramite
         and  (sd_tipo_deuda= @i_tipo_deuda or (@i_tipo_deuda = 'T' or @i_tipo_deuda is null ))
         --and  ((sd_tipo_op in ('CCI','CCD','GRA','GRB','STB', 'AVB', 'AVE') and sd_producto = 'CEX') or sd_producto = 'CCA')  RVI 25-02-2016  Banco FIE solo GRB
         and  ((sd_tipo_op = 'GRB' and sd_producto = 'CEX') or sd_producto = 'CCA')
         and  sd_estado in ('NO VIGENTE', 'CREDITO')

         -- Total de deudas indirectas que mantengo en Cartera

         if @i_cliente is not null
             select @w_total_ind = sum(sd_monto_riesgo)
             from cr_situacion_deudas
             where (sd_cliente_con = @i_cliente or (@i_grupo is not null and @i_cliente is null))
             and   sd_usuario   = @s_user
             and   sd_secuencia = @s_sesn
             and   sd_tramite   = @i_tramite
             and  (sd_tipo_deuda= 'I')
             and   sd_producto = 'CCA'
             and  (sd_estado NOT IN ('CREDITO', 'NO VIGENTE') or sd_estado is null )
      end

      select @w_total_lin = isnull(@w_total_lin,0) + isnull(@w_total_ling,0)

      -- Total de Contingentes que actualmente mantengo en Comext
      select @w_total_prefactor = sum(isnull( sd_monto_riesgo, 0))
      from cr_situacion_deudas
      where (sd_cliente_con = @i_cliente or (@i_grupo is not null and @i_cliente is null))
      and  sd_producto = 'CEX'
      and  sd_usuario   = @s_user
      and  sd_secuencia = @s_sesn
      and  sd_tramite   = @i_tramite
      and  (sd_tipo_deuda= @i_tipo_deuda or (@i_tipo_deuda = 'T' or @i_tipo_deuda is null ))
      and  (sd_estado not in ('CREDITO', 'NO VIGENTE') or sd_estado is null )

      -- Total de otros contingentes Comext        --FBO 20-04-2016
      select @w_total_other = sum(isnull( so_monto_ml, 0))
      from cr_situacion_otras
      where (so_cliente_con   = @i_cliente or (@i_grupo is not null and @i_cliente is null))
      and  so_producto = 'CEX'
      and  so_usuario         = @s_user
      and  so_secuencia       = @s_sesn
      and  so_tramite         = @i_tramite
      and  (so_tipo_deuda     = 'D')
      and  so_numero_operacion <> ''            --Se descrimina las operaciones con valor vacío
      and  so_numero_operacion is not null      --Se descrimina las operaciones con valor nulo

      select @w_deuda_directa = isnull(@w_total_cca,0) + isnull(@w_total_sob,0)
      select @w_deuda_indirecta = isnull(@w_total_ind,0)
      select @w_deuda_contingente = isnull(@w_total_prefactor,0)+ isnull(@w_total_lin,0) + isnull(@w_total_other, 0)

      -- RVI 25-02-2016 Nivel de Endeudamiento
      -- select @w_total = @w_deuda_directa + @w_deuda_indirecta +  @w_deuda_contingente
      select
         @w_linea            = tr_linea_credito,
         @w_monto_solicitado = tr_monto --tr_monto_solicitado
      from cob_credito..cr_tramite
      where tr_tramite = @i_tramite

      select @w_total = 0

      if @w_linea is not null -- Prestamos bajo linea
         select @w_total = @w_deuda_directa + @w_deuda_contingente + @w_deuda_indirecta
      else -- Prestamo sin linea
         select @w_total = @w_deuda_directa + @w_deuda_contingente + isnull(@w_monto_solicitado,0) + @w_deuda_indirecta

      --if @i_en_tramite = 'S'  --incluye tramites
         --select @w_total = @w_total + isnull(@w_total_tram,0)

      select  @o_total_deuda   = @w_total

      if @i_retorna = 'S'
          select  isnull(@w_total,0), isnull(@w_deuda_directa,0), isnull(@w_deuda_indirecta,0), isnull(@w_deuda_contingente,0), isnull(@w_total_prefactor,0)

   end --if @i_operacion = 'C'
end  --@i_vista_360 = 'S' FIN LA CONSULTA DESDE LA VISTA 360 ES NORMAL DESDE GESTION

delete cr_deud1_tmp    where spid = @w_spid

return 0

GO
