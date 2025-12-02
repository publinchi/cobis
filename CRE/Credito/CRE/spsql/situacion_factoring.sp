/************************************************************************/
/*  Archivo:                situacion_factoring.sp                      */
/*  Stored procedure:       sp_situacion_factoring                      */
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

if exists(select 1 from sysobjects where name ='sp_situacion_factoring')
    drop proc sp_situacion_factoring
go

create proc sp_situacion_factoring(
        @s_user               login = null,
        @s_ssn                int = null,
        @s_sesn               int = null,
        @s_date               datetime = null,
        @t_file               varchar(14) = null,
        @t_debug              char(1)  = 'N',
        @i_tramite            int = 0,
        @i_cliente            int = null,
        @i_cliente_sig        int = 0,
        @i_operacion          char(1) = null,
        @i_modo_c             char(2) = null,
        @i_en_tramite         char(1) = null,
        @i_modo               int = null,
        @i_usuario            login = null,
        @i_secuencia          int = null,
        @i_categoria          char(2) = null,
        @i_formato_fecha      int     = null,
        @i_tramite_d          int = null,
        @i_operacion_ban      cuenta = ' ',
        @i_tipo_deuda         char(1) = null,
        @i_vista_360	      char(1) = 'S',            -- INDICA SI LA CONSULTA VIENE DESDE LA VISTA 360 PARA NO ENVIAR CABECERAS
        @t_show_version       bit = 0 -- Mostrar la version del programa
    )
as

declare
   @w_sp_name		varchar(32),
   @w_fecha		datetime,
   @w_total             money,
   @w_registros         varchar(10),
   @w_total_registros   int,
   @w_total_cca         money,
   @w_total_cex         money,
   @w_total_visa        money,
   @w_total_sobre       money,
   @w_total_tram        money,
   @w_cliente           int,
   @w_calificacion      catalogo,
   @w_calificacion_peor catalogo,
   @w_est_castigado     tinyint,
   @w_est_judicial      tinyint,
   @w_tot_castigados    money,
   @w_tot_judicial      money,
   @w_convenio          cuenta,
   @w_def_moneda	 tinyint,
   @w_tabla_calif       int,			--Vivi
   @w_spid              smallint --OCU#

select 	@w_sp_name = 'sp_situacion_factoring'

if @t_show_version = 1
begin
    print 'Stored procedure sp_situacion_factoring, Version 4.0.0.3'
    return 0
end

-- Obtener secunecial
select @w_spid = @@spid

-- Cargo fecha de proceso
select @w_fecha = fp_fecha
from cobis..ba_fecha_proceso

select @i_tramite_d = isnull(@i_tramite_d,0)

if @i_vista_360 = 'S' --LA CONSULTA ES DESDE LA VISTA 360
begin
    if @i_operacion = 'S'
    begin
       --DEUDAS
      if @i_modo_c = 'D' or @i_modo_c  = 'T'
       begin
        --SOBREGIROS
         if @i_modo = 4       --Sobregiros
          begin
             select   'cliente' = sc_cliente, 'producto' = a.sd_producto,
                      'tipo' = a.sd_tipo_op, 'tipo_operacion' = a.sd_desc_tipo_op,
                      'cuenta' = a.sd_numero_operacion,  'linea' = a.sd_tarjeta_visa,
                      'tasa' = str(a.sd_tasa,12, 4),
                      'fecha_apt' = convert(char(10),a.sd_fecha_apr,@i_formato_fecha),
                      'fecha_vto' = convert(char(10),a.sd_fecha_vct,@i_formato_fecha),
                      'desc_moneda' =
                      (select mo_nemonico
                       from cobis..cl_moneda
                       where mo_moneda = a.sd_moneda),
                      'monto_ml' = a.sd_monto_ml,
                      'utilizado' = a.sd_val_utilizado, 'utilizado_ml' = a.sd_val_utilizado_ml,
                      'disponible' = a.sd_saldo_x_vencer,
                      'valor_excedido' = a.sd_saldo_vencido,
                      'dias_excedido' = a.sd_subtipo,
                      'moneda' = sd_moneda, 'nombre_cliente' = sc_nombre_cliente,
                      'riesgo_ml' = sd_monto_riesgo
             from cr_situacion_cliente,
                  cr_situacion_deudas a
             where sc_cliente     = a.sd_cliente
             and   a.sd_categoria = '07'
             and   sc_usuario     = @s_user
             and   sc_secuencia   = @s_sesn
             and   sc_tramite     = @i_tramite
             and   sc_usuario     = a.sd_usuario
             and   sc_secuencia   = a.sd_secuencia
             and   sc_tramite     = a.sd_tramite
             and   a.sd_tipo_deuda= @i_tipo_deuda
             and   a.sd_numero_operacion > @i_operacion_ban
             order by a.sd_numero_operacion, sc_cliente, a.sd_tipo_op
          end

          --  OPERACIONES DE PREFACTORING
          if @i_modo = 5
          begin
             select   'cliente' = sc_cliente, 'producto' = a.sd_producto,
                      'tipo_operacion' = a.sd_tipo_op, 'desc_tipo_op' = a.sd_desc_tipo_op,
                      'operacion' = a.sd_numero_operacion, 'linea' = a.sd_tarjeta_visa,
                      'tramite' = a.sd_tramite_d,
                      'fecha_apt' = convert(char(10),a.sd_fecha_apr,@i_formato_fecha),
                      'fecha_vto' = convert(char(10),a.sd_fecha_vct,@i_formato_fecha),
                      'desc_moneda' =
                      (select mo_nemonico
                       from cobis..cl_moneda
                       where mo_moneda = a.sd_moneda),
                      'monto' = a.sd_limite_credito, 'monto_ml' = a.sd_saldo_promedio,
                      'valor_vig' = a.sd_saldo_vencido,
                      'saldo' = a.sd_val_utilizado, 'saldo_ml' = a.sd_val_utilizado_ml,
                      'referencia' =  a.sd_beneficiario,
                      'fecha' =  convert( char(10), a.sd_prox_pag_int, @i_formato_fecha),
                      'tasa' = str(a.sd_tasa,12,4),
                      'estado' = a.sd_estado,
                      '','','','','','',''
             from cr_situacion_cliente,
                  cr_situacion_deudas a
             where sc_cliente     = a.sd_cliente
             and   a.sd_producto  = 'PREFAC'
             and   sc_usuario     = @s_user
             and   sc_secuencia   = @s_sesn
             and   sc_tramite     = @i_tramite
             and   sc_usuario     = a.sd_usuario
             and   sc_secuencia   = a.sd_secuencia
             and   sc_tramite     = a.sd_tramite
             and   a.sd_tipo_deuda= @i_tipo_deuda
             and   a.sd_tramite_d > @i_tramite_d
             order by a.sd_tramite_d

          end

          -- OTRAS OPERACIONES DE COMEXT 'CCE','STB','COB'
          if @i_modo = 6
          begin
             -- GRABA DATOS PARA CONSULTA
             select   'cliente' = sc_cliente, 'producto' = a.so_producto,
                      'tipo_operacion' = a.so_tipo_op, 'desc_tipo_op' = a.so_desc_tipo_op,
                      'operacion' = a.so_numero_operacion, 'tramite' = isnull(a.so_tramite_d, a.so_operacion),
                      'fecha_apt' = convert(char(10),a.so_fecha_apr,@i_formato_fecha),
                      'fecha_vto' = convert(char(10),a.so_fecha_vct,@i_formato_fecha),
                      'desc_moneda' = (select mo_nemonico
                       from cobis..cl_moneda
                       where mo_moneda = a.so_moneda),
                      'monto' = a.so_monto, 'monto_ml' = a.so_monto_ml,
                      'saldo' = a.so_saldo_x_vencer, 'saldo_ml' = a.so_saldo_vencido,
                      'fecha_embarque' = a.so_fechas_embarque, 'seguro' = a.so_aprobado,
                      'beneficiario' = a.so_beneficiario,'nombre_cliente' = sc_nombre_cliente
             from cr_situacion_cliente,
                  cr_situacion_otras a
             where sc_cliente     = a.so_cliente
             and   a.so_producto  = 'CEX'
             and   sc_usuario     = @s_user
             and   sc_secuencia   = @s_sesn
             and   sc_tramite     = @i_tramite
             and   sc_usuario     = a.so_usuario
             and   sc_secuencia   = a.so_secuencia
             and   sc_tramite     = a.so_tramite
             and   a.so_tipo_deuda= @i_tipo_deuda
             and   isnull(a.so_tramite_d, a.so_operacion) > @i_tramite_d
             order by isnull(a.so_tramite_d, a.so_operacion)
          end

          -- OPERACIONES DE FACTORING
          if @i_modo = 7
          begin
             -- GRABA DATOS PARA CONSULTA
             select   'cliente' = sc_cliente, 'producto' = a.so_producto,
                      'tipo_operacion' = a.so_tipo_op, 'desc_tipo_op' = a.so_desc_tipo_op,
                      'operacion' =  a.so_numero_operacion,
                      'linea' = a.so_tarjeta_visa,
                      'tramite' = a.so_tramite_d,
                      'fecha_apt' = convert(char(10),a.so_fecha_apr,@i_formato_fecha),
                      'fecha_vto' = convert(char(10),a.so_fecha_vct,@i_formato_fecha),
                      'desc_moneda' =
                      (select mo_nemonico
                       from cobis..cl_moneda
                       where mo_moneda = a.so_moneda),
                      'monto' = a.so_limite_credito, 'monto_ml' = a.so_saldo_promedio,
                      'valor_vig' =  a.so_saldo_vencido,
                      'saldo' = a.so_val_utilizado,
                      'saldo_ml' = a.so_val_utilizado_ml,
                      'tasa' = str( a.so_tasa, 12, 4),
                      'estado' = a.so_estado
             from cr_situacion_cliente,
                  cr_situacion_otras a
             where sc_cliente     = a.so_cliente
             and   a.so_producto  = 'FACTOR'
             and   sc_usuario     = @s_user
             and   sc_secuencia   = @s_sesn
             and   sc_tramite     = @i_tramite
             and   sc_usuario     = a.so_usuario
             and   sc_secuencia   = a.so_secuencia
             and   sc_tramite     = a.so_tramite
             and   a.so_tipo_deuda= @i_tipo_deuda
             and   a.so_tramite_d > @i_tramite_d
             order by a.so_tramite_d

          end
       end
    end --@i_operacion = 'S'
end --FIN LA CONSULTA SI ES DESDE LA VISTA 360

return 0

GO
