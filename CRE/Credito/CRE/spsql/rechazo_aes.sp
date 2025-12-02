/************************************************************************/
/*  Archivo:                rechazo_aes.sp                              */
/*  Stored procedure:       sp_rechazo_aes                              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
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
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_rechazo_aes')
    drop proc sp_rechazo_aes
go

create proc sp_rechazo_aes (
/**** LC Req 368 26/08/2013****/
@s_ssn          int            = null,
@s_date         datetime       = null,
@s_user         login          = null,
@s_term         descripcion    = null,
@s_ofi          smallint       = null,
@s_lsrv         varchar(30)    = null,
@s_srv          varchar(30)    = null,
--@t_trn        int            = null,
@t_debug        char(1)        = 'N',
@t_file         varchar(14)    = null,
/**** LC Req 368 26/08/2013****/
@i_cliente      int            = null
)

as

declare
@w_tramite           int,
@w_secuencia         int,
@w_status            varchar(1),
@w_return            int,
@w_etapa             int,
@w_cont              int,
@w_tipo              char(1),
@w_causal            varchar(10),
@w_ssn               int,
@w_fecha             datetime,
@w_user              varchar(14),
@w_sp_name           varchar(30),   --LC Req 368 26/08/2013
@w_aux               varchar(200),
@w_error_aux         int,
@w_cliente           int,
@w_alianza           int,
@w_carga             int ,
@w_descripcion       varchar(200) ,
@w_alianza1          int,
@w_tipo_ced          varchar(2),
@w_en_ced_ruc        numero,
@w_numero            int,          -- li_numero,
@w_num_banco         cuenta,       -- li_num_banco,
@w_oficina           smallint,     -- li_oficina,
@w_grupo             int,          -- li_grupo,
@w_original          int,          -- li_original,
@w_fecha_aprob       datetime,     -- li_fecha_aprob,
@w_fecha_inicio      datetime,     -- li_fecha_inicio,
@w_fecha_vto         datetime,     -- li_fecha_vto,
@w_per_revision      catalogo,     -- li_per_revision,
@w_dias              smallint,     -- li_dias,
@w_condicion         varchar(255), -- li_condicion_especial,
@w_ultima_rev        datetime,     -- li_ult_rev,
@w_prox_rev          datetime,     -- li_prox_rev,
@w_usuario_rev       login,        -- li_usuario_rev,
@w_monto             money,        -- li_monto,
@w_moneda            tinyint,      -- li_moneda,
@w_utilizado         money,        -- isnull(li_utilizado,0),
@w_rotativa          char(1),      -- li_rotativa,
@w_clase             catalogo,     -- li_clase,
@w_admisible         money,        -- li_admisible,
@w_noadmis           money,        -- li_noadmis,
@w_estado            char(1),      -- li_estado,
@w_reservado_linea   money,        -- li_reservado,
@w_tipo_linea        char(1),      -- li_tipo,
@w_dias_vig          int,          -- li_dias_vig,
@w_num_desemb        int,          -- li_num_desemb,
@w_monto_sol         money,        -- tr_monto_solicitado,
@w_tipo_plazo        catalogo,     -- li_tipo_plazo,
@w_tipo_cuota        catalogo,     -- li_tipo_cuota,
@w_cuota_aproximada  money,        -- li_cuota_aproximada,
@w_migrado           varchar(16)   -- tr_migrado

select
@w_tramite     = 0,
@w_secuencia   = 0,
@w_status      = '',
@w_etapa       = 0,
@w_cont        = 0,
@w_tipo        = '',
@w_fecha       = getdate(),
@w_user        = 'crebatch',
@s_date        = isnull( @s_date, getdate())

select @w_sp_name = 'sp_rechazo_aes'  --LC Req 368 26/08/2013

--ciclo para rechazar tramites de un cliente de alianzas comerciales
-- CREACION DE TABLA TEMPORAL CON LA ESTRUCTURA DESEADA.
select
tr_tramite, tr_tipo, tr_oficina, tr_usuario, tr_fecha_crea, tr_oficial, tr_sector, tr_ciudad, tr_estado, tr_nivel_ap, tr_fecha_apr,
tr_usuario_apr, tr_truta, tr_secuencia, tr_numero_op, tr_numero_op_banco, tr_riesgo, tr_aprob_por, tr_nivel_por, tr_comite, tr_acta,
tr_proposito, tr_razon, tr_txt_razon, tr_efecto, tr_cliente, tr_nombre, tr_grupo, tr_fecha_inicio, tr_num_dias, tr_per_revision,
tr_condicion_especial, tr_linea_credito, tr_toperacion, tr_producto, tr_monto, tr_moneda, tr_periodo, tr_num_periodos, tr_destino,
tr_ciudad_destino, tr_cuenta_corriente, tr_renovacion, tr_rent_actual, tr_rent_solicitud, tr_rent_recomend,
tr_prod_actual, tr_prod_solicitud, tr_prod_recomend, tr_clase, tr_admisible, tr_noadmis, tr_relacionado, tr_pondera, tr_contabilizado,
tr_subtipo, tr_tipo_producto, tr_origen_bienes, tr_localizacion, tr_plan_inversion, tr_naturaleza, tr_tipo_financia, tr_sobrepasa,
tr_elegible, tr_forward, tr_emp_emisora, tr_num_acciones, tr_responsable, tr_negocio, tr_reestructuracion, tr_concepto_credito,
tr_aprob_gar, tr_cont_admisible, tr_mercado_objetivo, tr_tipo_productor, tr_valor_proyecto, tr_sindicado, tr_asociativo, tr_margen_redescuento,
tr_fecha_ap_ant, tr_llave_redes, tr_incentivo, tr_fecha_eleg, tr_op_redescuento, tr_fecha_redes, tr_solicitud, tr_montop, tr_monto_desembolsop,
tr_mercado, tr_dias_vig, tr_cod_actividad, tr_num_desemb, tr_carta_apr, tr_fecha_aprov, tr_fmax_redes, tr_f_prorroga, tr_nlegal_fi, tr_fechlimcum,
tr_validado, tr_sujcred, tr_fabrica, tr_callcenter, tr_apr_fabrica, tr_monto_solicitado, tr_tipo_plazo, tr_tipo_cuota, tr_plazo, tr_cuota_aproximada,
tr_fuente_recurso, tr_tipo_credito, tr_migrado, tr_estado_cont, tr_fecha_fija, tr_dia_pago, tr_tasa_reest, tr_motivo, tr_central, tr_alianza,
tr_autoriza_central, tr_devuelto_mir, tr_campana, ac_alianza, ac_ente, ac_estado, ac_fecha_asociacion, ac_fecha_desasociacion, ac_fecha_creacion,
ac_usuario_creador, ac_usuario_modifica,
op_operacion, op_banco, op_estado
into #tramite
from cob_credito..cr_tramite with (nolock), cobis..cl_alianza_cliente with (nolock), cob_cartera..ca_operacion with (nolock)
where tr_cliente = -1
and   tr_alianza = ac_alianza
and   tr_cliente = ac_ente
and   op_tramite = tr_tramite

if @@error <> 0
begin
  return 2103001 -- Error en insercion de registro
end


-- BUSCA LOS TRAMITES ORIGINALES, DE UNIFICACION/UTILIZACION, RESSTRUCTURACIONES, ETC.
insert into #tramite
select
tr_tramite, tr_tipo, tr_oficina, tr_usuario, tr_fecha_crea, tr_oficial, tr_sector, tr_ciudad, tr_estado, tr_nivel_ap, tr_fecha_apr,
tr_usuario_apr, tr_truta, tr_secuencia, tr_numero_op, tr_numero_op_banco, tr_riesgo, tr_aprob_por, tr_nivel_por, tr_comite, tr_acta,
tr_proposito, tr_razon, tr_txt_razon, tr_efecto, tr_cliente, tr_nombre, tr_grupo, tr_fecha_inicio, tr_num_dias, tr_per_revision,
tr_condicion_especial, tr_linea_credito, tr_toperacion, tr_producto, tr_monto, tr_moneda, tr_periodo, tr_num_periodos, tr_destino,
tr_ciudad_destino, tr_cuenta_corriente, tr_renovacion, tr_rent_actual, tr_rent_solicitud, tr_rent_recomend,
tr_prod_actual, tr_prod_solicitud, tr_prod_recomend, tr_clase, tr_admisible, tr_noadmis, tr_relacionado, tr_pondera, tr_contabilizado,
tr_subtipo, tr_tipo_producto, tr_origen_bienes, tr_localizacion, tr_plan_inversion, tr_naturaleza, tr_tipo_financia, tr_sobrepasa,
tr_elegible, tr_forward, tr_emp_emisora, tr_num_acciones, tr_responsable, tr_negocio, tr_reestructuracion, tr_concepto_credito,
tr_aprob_gar, tr_cont_admisible, tr_mercado_objetivo, tr_tipo_productor, tr_valor_proyecto, tr_sindicado, tr_asociativo, tr_margen_redescuento,
tr_fecha_ap_ant, tr_llave_redes, tr_incentivo, tr_fecha_eleg, tr_op_redescuento, tr_fecha_redes, tr_solicitud, tr_montop, tr_monto_desembolsop,
tr_mercado, tr_dias_vig, tr_cod_actividad, tr_num_desemb, tr_carta_apr, tr_fecha_aprov, tr_fmax_redes, tr_f_prorroga, tr_nlegal_fi, tr_fechlimcum,
tr_validado, tr_sujcred, tr_fabrica, tr_callcenter, tr_apr_fabrica, tr_monto_solicitado, tr_tipo_plazo, tr_tipo_cuota, tr_plazo, tr_cuota_aproximada,
tr_fuente_recurso, tr_tipo_credito, tr_migrado, tr_estado_cont, tr_fecha_fija, tr_dia_pago, tr_tasa_reest, tr_motivo, tr_central, tr_alianza,
tr_autoriza_central, tr_devuelto_mir, tr_campana, ac_alianza, ac_ente, ac_estado, ac_fecha_asociacion, ac_fecha_desasociacion, ac_fecha_creacion,
ac_usuario_creador, ac_usuario_modifica,
op_operacion, op_banco, op_estado
from cob_credito..cr_tramite with (nolock), cobis..cl_alianza_cliente with (nolock), cob_cartera..ca_operacion with (nolock)
where tr_cliente = @i_cliente
and   tr_estado  <> 'Z'
and   tr_alianza = ac_alianza
and   tr_cliente = ac_ente
and   op_tramite = tr_tramite
and   op_estado  in (0,99)

if @@error <> 0
begin
  return 2103001 -- Error en insercion de registro
end

-- BUSCA LOS TRAMITES DE CUPO QUE NO ESTAN EN ETAPA FINAL
insert into #tramite
select
tr_tramite, tr_tipo, tr_oficina, tr_usuario, tr_fecha_crea, tr_oficial, tr_sector, tr_ciudad, tr_estado, tr_nivel_ap, tr_fecha_apr,
tr_usuario_apr, tr_truta, tr_secuencia, tr_numero_op, tr_numero_op_banco, tr_riesgo, tr_aprob_por, tr_nivel_por, tr_comite, tr_acta,
tr_proposito, tr_razon, tr_txt_razon, tr_efecto, tr_cliente, tr_nombre, tr_grupo, tr_fecha_inicio, tr_num_dias, tr_per_revision,
tr_condicion_especial, tr_linea_credito, tr_toperacion, tr_producto, tr_monto, tr_moneda, tr_periodo, tr_num_periodos, tr_destino,
tr_ciudad_destino, tr_cuenta_corriente, tr_renovacion, tr_rent_actual, tr_rent_solicitud, tr_rent_recomend,
tr_prod_actual, tr_prod_solicitud, tr_prod_recomend, tr_clase, tr_admisible, tr_noadmis, tr_relacionado, tr_pondera, tr_contabilizado,
tr_subtipo, tr_tipo_producto, tr_origen_bienes, tr_localizacion, tr_plan_inversion, tr_naturaleza, tr_tipo_financia, tr_sobrepasa,
tr_elegible, tr_forward, tr_emp_emisora, tr_num_acciones, tr_responsable, tr_negocio, tr_reestructuracion, tr_concepto_credito,
tr_aprob_gar, tr_cont_admisible, tr_mercado_objetivo, tr_tipo_productor, tr_valor_proyecto, tr_sindicado, tr_asociativo, tr_margen_redescuento,
tr_fecha_ap_ant, tr_llave_redes, tr_incentivo, tr_fecha_eleg, tr_op_redescuento, tr_fecha_redes, tr_solicitud, tr_montop, tr_monto_desembolsop,
tr_mercado, tr_dias_vig, tr_cod_actividad, tr_num_desemb, tr_carta_apr, tr_fecha_aprov, tr_fmax_redes, tr_f_prorroga, tr_nlegal_fi, tr_fechlimcum,
tr_validado, tr_sujcred, tr_fabrica, tr_callcenter, tr_apr_fabrica, tr_monto_solicitado, tr_tipo_plazo, tr_tipo_cuota, tr_plazo, tr_cuota_aproximada,
tr_fuente_recurso, tr_tipo_credito, tr_migrado, tr_estado_cont, tr_fecha_fija, tr_dia_pago, tr_tasa_reest, tr_motivo, tr_central, tr_alianza,
tr_autoriza_central, tr_devuelto_mir, tr_campana, ac_alianza, ac_ente, ac_estado, ac_fecha_asociacion, ac_fecha_desasociacion, ac_fecha_creacion,
ac_usuario_creador, ac_usuario_modifica,
0, '0', 5
from cob_credito..cr_tramite with (nolock), cobis..cl_alianza_cliente with (nolock), cob_credito..cr_ruta_tramite with (nolock), cr_etapa
where tr_cliente = @i_cliente  -- 203194
and   tr_estado  <> 'Z'
and   tr_tipo    =  'C'
and   tr_tramite =  rt_tramite
and   rt_salida  is null
and   tr_alianza =  ac_alianza
and   tr_cliente =  ac_ente
and   rt_etapa   =  et_etapa
and   et_tipo    <> 'F'

if @@error <> 0
begin
  return 2103001 -- Error en insercion de registro
end


while 1=1
begin
   set rowcount 1

   select @w_tramite     = tr_tramite,
          @w_cliente     = tr_cliente,
          @w_alianza     = tr_alianza
   from #tramite

   if @@rowcount = 0
   begin
      set rowcount 0
      break
   end
   set rowcount 0

   select @w_tipo_ced = en_tipo_ced, @w_en_ced_ruc = en_ced_ruc from cobis..cl_ente where en_ente = @w_cliente

   delete #tramite where tr_tramite = @w_tramite

   exec @w_ssn = ADMIN...rp_ssn

   if @w_ssn is null begin
      -- insert into cr_errorlog values (getdate(), 21000, 'crebatch', 21000, 'ERROR RECHAZO MASIVO.', 'Error <No obtiene Numero @w_ssn> ' + cast(@w_tramite as varchar))
      select @w_descripcion = 'NO SE RECHAZO TRAMITE.' +  isnull( cast(@w_tramite as varchar),'') + ' CED: '+ isnull(@w_en_ced_ruc,'') + ' TIPO: ' + isnull( @w_tipo_ced ,'')
      exec cobis..sp_error_proc_masivos   -- select * from  cobis..ca_msv_error  where  me_tipo_proceso = 'E'  -- CED: 78567908 TIPO: CC
           @i_id_carga        = @w_carga,
           @i_id_alianza      = @w_alianza1,
           @i_referencia      = 'Reajuste',
           @i_tipo_proceso    = 'E',
           @i_procedimiento   = 'sp_rechazo_aes',
           @i_codigo_interno  = @w_cliente,
           @i_codigo_err      = 9999999,
           @i_descripcion     = @w_descripcion

      goto SIG
   end

   select @w_secuencia = max(rt_secuencia)
   from cr_ruta_tramite with (nolock)
   where rt_tramite = @w_tramite

   if @w_secuencia is null
   begin
      select @w_descripcion = 'NO SE RECHAZO TRAMITE..' +  isnull( cast(@w_tramite as varchar),'') + ' CED: '+ isnull(@w_en_ced_ruc,'') + ' TIPO: ' + isnull( @w_tipo_ced ,'')
      exec cobis..sp_error_proc_masivos   -- select * from  cobis..ca_msv_error  where  me_tipo_proceso = 'E'
           @i_id_carga        = @w_carga,
           @i_id_alianza      = @w_alianza1,
           @i_referencia      = 'Reajuste',
           @i_tipo_proceso    = 'E',
           @i_procedimiento   = 'sp_rechazo_aes',
           @i_codigo_interno  = @w_cliente,
           @i_codigo_err      = 9999999,
           @i_descripcion     = @w_descripcion

      goto SIG
   end

   select @w_etapa = rt_etapa, @w_tipo = tr_tipo
   from cr_ruta_tramite with (nolock), cr_tramite with (nolock)
   where rt_tramite   = @w_tramite
   and   rt_secuencia = @w_secuencia
   and   rt_tramite   = tr_tramite

   if @w_etapa is not null
   begin

       --insert into cob_credito..seguim values ( 1006, getdate(), @w_aux   )

       select @w_causal = '95'

       exec @w_return = sp_causal_rechazo_tramite
       @s_ssn       = @w_ssn,
       @t_trn       = 21760,
       @i_operacion = 'I',
       @i_requisito = @w_causal,
       @i_etapa     = @w_etapa,
       @i_tipo      = 'NEG',
       @i_tramite   = @w_tramite

       if @w_return <> 0
       begin
          select @w_descripcion = 'NO SE RECHAZO TRAMITE. ' +  isnull( cast(@w_tramite as varchar),'')+ ' CED: '+ isnull(@w_en_ced_ruc,'') + ' TIPO: ' + isnull( @w_tipo_ced ,'')
          exec cobis..sp_error_proc_masivos   -- select * from  cobis..ca_msv_error  where  me_tipo_proceso = 'E'
              @i_id_carga        = @w_carga,
              @i_id_alianza      = @w_alianza1,
              @i_referencia      = 'Reajuste',
              @i_tipo_proceso    = 'E',
              @i_procedimiento   = 'sp_rechazo_aes',
              @i_codigo_interno  = @w_cliente,
              @i_codigo_err      = 9999999,
              @i_descripcion     = @w_descripcion

          goto SIG
       end

       exec @w_return = sp_rechazo
       @s_user          = @w_user,
       @s_date          = @w_fecha,
       @s_ssn           = @w_ssn,
       @i_tramite       = @w_tramite,
       @i_observaciones = 'Rechazo Automatico Desasociacion Cliente de Alianza Comercial',
       @i_tipo_causal   = 'Z',
       @i_etapa_actual  = @w_etapa,
       @i_tipo_tramite  = @w_tipo

       if @w_return <> 0
       begin

          select @w_descripcion = ' NO SE RECHAZO TRAMITE. ' +  isnull( cast(@w_tramite as varchar),'')+ ' CED: '+ isnull(@w_en_ced_ruc,'') + ' TIPO: ' + isnull( @w_tipo_ced ,'')
          exec cobis..sp_error_proc_masivos   -- select * from  cobis..ca_msv_error  where  me_tipo_proceso = 'E'
              @i_id_carga        = @w_carga,
              @i_id_alianza      = @w_alianza1,
              @i_referencia      = 'Reajuste',
              @i_tipo_proceso    = 'E',
              @i_procedimiento   = 'sp_rechazo_aes',
              @i_codigo_interno  = @w_cliente,
              @i_codigo_err      = 9999999,
              @i_descripcion     = @w_descripcion

          goto SIG
       end

       update cob_cartera..ca_operacion with (rowlock) set
       op_estado = 6
       where op_tramite = @w_tramite

       if @w_return <> 0
       begin

          select @w_descripcion = 'NO SE RECHAZO TRAMITE ' +  isnull( cast(@w_tramite as varchar),'')+ ' CED: '+ isnull(@w_en_ced_ruc,'') + ' TIPO: ' + isnull( @w_tipo_ced ,'')
          exec cobis..sp_error_proc_masivos   -- select * from  cobis..ca_msv_error  where  me_tipo_proceso = 'E'
              @i_id_carga        = @w_carga,
              @i_id_alianza      = @w_alianza1,
              @i_referencia      = 'Reajuste',
              @i_tipo_proceso    = 'E',
              @i_procedimiento   = 'sp_rechazo_aes',
              @i_codigo_interno  = @w_cliente,
              @i_codigo_err      = 9999999,
              @i_descripcion     = @w_descripcion

          goto SIG
       end

       SIG:
       select @w_cont = @w_cont + 1
   end
   else
   begin

      select @w_descripcion = 'NO SE  RECHAZO TRAMITE. ' +  isnull( cast(@w_tramite as varchar),'')+ ' CED: '+ isnull(@w_en_ced_ruc,'') + ' TIPO: ' + isnull( @w_tipo_ced ,'')
      exec cobis..sp_error_proc_masivos   -- select * from  cobis..ca_msv_error  where  me_tipo_proceso = 'E'
           @i_id_carga        = @w_carga,
           @i_id_alianza      = @w_alianza1,
           @i_referencia      = 'Reajuste',
           @i_tipo_proceso    = 'E',
           @i_procedimiento   = 'sp_rechazo_aes',
           @i_codigo_interno  = @w_cliente,
           @i_codigo_err      = 9999999,
           @i_descripcion     = @w_descripcion
   end

   select @w_ssn = siguiente + 1 from cobis..cl_seqnos where bdatos = 'cobis' and tabla = 'cl_masivo'

   update cobis..cl_seqnos
   set siguiente = @w_ssn
   where bdatos = 'cobis'
   and tabla = 'cl_masivo'

   if @@error <> 0
   begin
     return 105001
   end

   /**** LC REQ 368 27/08/2013 ****/
   /* TRANSACCION DE SERVICIO REGISTRO  */
   insert into ts_tramite (
   secuencial,                           tipo_transaccion,                       clase,
   fecha,                                usuario,                                terminal,
   oficina,                              tabla,                                  lsrv,
   srv,                                  tramite,                             tipo,
   oficina_tr,                           usuario_tr,                             fecha_crea,
   oficial,                              sector,                                 ciudad,
   estado,                               nivel_ap,                               fecha_apr,
   usuario_apr,                          truta,                                  numero_op,
   numero_op_banco,                      proposito,                              razon,
   txt_razon,                            efecto,                                 cliente,
   grupo,                                fecha_inicio,                           num_dias,
   per_revision,                         condicion_especial,                     linea_credito,
   toperacion,                           producto,                               monto,
   moneda,                               periodo,                                num_periodos,
   destino,                              ciudad_destino,                         cuenta_corriente,
   renovacion,                           rent_actual,                            rent_solicitud,
   rent_recomend,                        prod_actual,                            prod_solicitud,
   prod_recomend,                        clasecca,                               admisible,
   noadmis,                              relacionado,                            pondera,
   tipo_producto,                        origen_bienes,                          localizacion,
   plan_inversion,                       naturaleza,                             tipo_financia,
   forward,                              elegible,                               emp_emisora,
   num_acciones,                         responsable,                            negocio,
   reestructuracion,                     concepto_credito,                       aprob_gar,
   mercado_objetivo,                     tipo_productor,                         valor_proyecto,
   sindicado,                            margen_redescuento,                     asociativo,
   incentivo,                            fecha_eleg,                             fecha_redes,
   solicitud,                            montop,                                 montodesembolsop,
   mercado,                              carta_apr,                              fecha_aprov,
   fmax_redes,                           f_prorroga,                             sujcred,
   fabrica,                              callcenter,                             apr_fabrica,
   monto_solicitado,                     tipo_plazo,                             tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito)
   select
   @w_ssn,                               21120,                                  'P',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite,                              tr_tipo,
   tr_oficina,                           tr_usuario,                              tr_fecha_crea,
   tr_oficial,                           tr_sector,                               tr_ciudad,
   tr_estado,                            tr_nivel_ap,                             tr_fecha_apr,
   tr_usuario_apr,                       tr_truta,                                tr_numero_op,
   tr_numero_op_banco,                   tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                  tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion,                        tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   --tr_num_acciones,                    tr_responsable,                          tr_negocio,
   tr_num_acciones,                      tr_responsable,                          tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,                         tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg,                           tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito
   from cr_tramite
   where tr_tramite = @w_tramite

   if @@error <> 0
   begin
      return 2103003 -- Error en insercion de transaccion de servicio
   end

   select @w_ssn = siguiente + 1 from cobis..cl_seqnos where bdatos = 'cobis' and tabla = 'cl_masivo'

   update cobis..cl_seqnos
   set siguiente = @w_ssn
   where bdatos = 'cobis'
   and tabla = 'cl_masivo'

   if @@error <> 0
   begin
     return 105001
   end

   /* TRANSACCION DE SERVICIO REGISTRO ACTUAL */
   insert into ts_tramite (
   secuencial,                           tipo_transaccion,                       clase,
   fecha,                                usuario,                                terminal,
   oficina,                              tabla,                                  lsrv,
   srv,                                  tramite,                                tipo,
   oficina_tr,                           usuario_tr,                             fecha_crea,
   oficial,                              sector,                                 ciudad,
   estado,                               nivel_ap,                               fecha_apr,
   usuario_apr,                          truta,                                  numero_op,
   numero_op_banco,                      proposito,                              razon,
   txt_razon,                            efecto,                                 cliente,
   grupo,                                fecha_inicio,                           num_dias,
   per_revision,                         condicion_especial,                     linea_credito,
   toperacion,                           producto,                               monto,
   moneda,                               periodo,                                num_periodos,
   destino,                              ciudad_destino,                         cuenta_corriente,
   renovacion,                           rent_actual,                            rent_solicitud,
   rent_recomend,                        prod_actual,                            prod_solicitud,
   prod_recomend,                        clasecca,                               admisible,
   noadmis,                              relacionado,                            pondera,
   tipo_producto,                        origen_bienes,                          localizacion,
   plan_inversion,                       naturaleza,                             tipo_financia,
   forward,                              elegible,                               emp_emisora,
   num_acciones,                         responsable,                            negocio,
   reestructuracion,                     concepto_credito,                       aprob_gar,
   mercado_objetivo,                     tipo_productor,                         valor_proyecto,
   sindicado,                            margen_redescuento,                     asociativo,
   incentivo,                            fecha_eleg,                             fecha_redes,
   solicitud,                            montop,                                 montodesembolsop,
   mercado,                              carta_apr,                              fecha_aprov,
   fmax_redes,                           f_prorroga,                             sujcred,
   fabrica,                              callcenter,                             apr_fabrica,
   monto_solicitado,                     tipo_plazo,                             tipo_cuota,
   plazo,                                cuota_aproximada,                       fuente_recurso,
   tipo_credito)
   select
   @w_ssn,                               21120,                                  'N',
   @s_date,                              @s_user,                                 @s_term,
   @s_ofi,                               'cr_tramite',                            @s_lsrv,
   @s_srv,                               tr_tramite,                              tr_tipo,
   tr_oficina,                           tr_usuario,                              tr_fecha_crea,
   tr_oficial,                           tr_sector,                               tr_ciudad,
   'Z',                                  tr_nivel_ap,                             tr_fecha_apr,
   tr_usuario_apr,                       tr_truta,                                tr_numero_op,
   tr_numero_op_banco,                   tr_proposito,                            tr_razon,
   tr_txt_razon,                         tr_efecto,                               tr_cliente,
   tr_grupo,                             tr_fecha_inicio,                         tr_num_dias,
   tr_per_revision,                      tr_condicion_especial,                   tr_linea_credito,
   tr_toperacion,                        tr_producto,                             tr_monto,
   tr_moneda,                            tr_periodo,                              tr_num_periodos,
   tr_destino,                           tr_ciudad_destino,                       tr_cuenta_corriente,
   tr_renovacion,                        tr_rent_actual,                          tr_rent_solicitud,
   tr_rent_recomend,                     tr_prod_actual,                          tr_prod_solicitud,
   tr_prod_recomend,                     tr_clase,                                tr_admisible,
   tr_noadmis,                           tr_relacionado,                          tr_pondera,
   tr_tipo_producto,                     tr_origen_bienes,                        tr_localizacion,
   tr_plan_inversion,                    tr_naturaleza,                           tr_tipo_financia,
   tr_forward,                           tr_elegible,                             tr_emp_emisora,
   --tr_num_acciones,                    tr_responsable,                          tr_negocio,
   tr_num_acciones,                      tr_responsable,                          tr_negocio,
   tr_reestructuracion,                  tr_concepto_credito,                     tr_aprob_gar,
   tr_mercado_objetivo,                  tr_tipo_productor,                       tr_valor_proyecto,
   tr_sindicado,                         tr_margen_redescuento,                   tr_asociativo,
   tr_incentivo,                         tr_fecha_eleg,                           tr_fecha_redes,
   tr_solicitud,                         tr_montop,                               tr_monto_desembolsop,
   tr_mercado,                           tr_carta_apr,                            tr_fecha_aprov,
   tr_fmax_redes,                        tr_f_prorroga,                           tr_sujcred,
   tr_fabrica,                           tr_callcenter,                           tr_apr_fabrica,
   tr_monto_solicitado,                  tr_tipo_plazo,                           tr_tipo_cuota,
   tr_plazo,                             tr_cuota_aproximada,                     tr_fuente_recurso,
   tr_tipo_credito
   from cr_tramite
   where tr_tramite = @w_tramite

   if @@error <> 0
   begin
      return 2103003 -- Error en insercion de transaccion de servicio
   end
   /**** FIN LC REQ 368 27/08/2013 ****/

end


/* SE TOMAN LOS CUPOS DE LA ALIANZA DEL CLIENTE, QUE ESTAN EN ETAPA FINAL Y SE ANULAN PARA QUE NO SE VUELVAN A UTILIZAR */
--INICIO ALCANCE AZU

select
tr_tramite,          li_numero,       li_num_banco,  li_oficina,            li_tramite,    li_cliente,            li_grupo,      li_original,
li_fecha_aprob,      li_fecha_inicio, li_fecha_vto,  li_per_revision,       li_dias,       li_condicion_especial, li_ult_rev,    li_prox_rev,
li_usuario_rev,      li_monto,        li_moneda,     isnull(li_utilizado,0) li_utilizado,  li_rotativa,   li_clase,      li_admisible,  li_noadmis,
li_estado,           li_reservado,    li_tipo,       li_dias_vig,           li_num_desemb, li_tipo_plazo,         li_tipo_cuota,
li_cuota_aproximada, tr_monto_solicitado,            tr_migrado
into #linea
from cob_credito..cr_tramite with (nolock), cobis..cl_alianza_cliente with (nolock), cob_credito..cr_ruta_tramite with (nolock), cr_etapa, cob_credito..cr_linea with (nolock)
where tr_cliente = @i_cliente
and   tr_estado  <> 'Z'
and   tr_tipo    =  'C'
and   tr_tramite =  rt_tramite
and   rt_salida  is null
and   tr_alianza =  ac_alianza
and   tr_cliente =  ac_ente
and   rt_etapa   =  et_etapa
and   et_tipo    = 'F'
and   tr_tramite = li_tramite
and   li_estado  <> 'A'

select @w_numero = 0

while 1=1
begin

   set rowcount 1

   select @w_numero  = li_numero,
          @w_tramite = tr_tramite,
          @w_cliente = li_cliente
   from #linea
   where li_numero > @w_numero
   order by li_numero

   if @@rowcount = 0
   begin
      set rowcount 0
      break
   end
   set rowcount 0

   select @w_tipo_ced = en_tipo_ced, @w_en_ced_ruc = en_ced_ruc from cobis..cl_ente with (nolock) where en_ente = @w_cliente

   /* INCIALIZACION DE VARIABLES */
   select
   @w_num_banco        = null,   @w_oficina          = null,   @w_tramite          = null,   @w_cliente          = null,   @w_grupo            = null,
   @w_original         = null,   @w_fecha_aprob      = null,   @w_fecha_inicio     = null,   @w_fecha_vto        = null,   @w_per_revision     = null,
   @w_dias             = null,   @w_condicion        = null,   @w_ultima_rev       = null,   @w_prox_rev         = null,   @w_usuario_rev      = null,
   @w_monto            = null,   @w_moneda           = null,   @w_utilizado        = null,   @w_rotativa         = null,   @w_clase            = null,
   @w_admisible        = null,   @w_noadmis          = null,   @w_estado           = null,   @w_reservado_linea  = null,   @w_tipo_linea       = null,
   @w_dias_vig         = null,   @w_num_desemb       = null,   @w_monto_sol        = null,   @w_tipo_plazo       = null,   @w_tipo_cuota       = null,
   @w_cuota_aproximada = null,   @w_migrado          = null


   /* LECTURA DE VARIABLES DE TRABAJO */
   select
   @w_numero           = li_numero,
   @w_num_banco        = li_num_banco,
   @w_oficina          = li_oficina,
   @w_tramite          = li_tramite,
   @w_cliente          = li_cliente,
   @w_grupo            = li_grupo,
   @w_original         = li_original,
   @w_fecha_aprob      = li_fecha_aprob,
   @w_fecha_inicio     = li_fecha_inicio,
   @w_fecha_vto        = li_fecha_vto,
   @w_per_revision     = li_per_revision,
   @w_dias             = li_dias,
   @w_condicion        = li_condicion_especial,
   @w_ultima_rev       = li_ult_rev,
   @w_prox_rev         = li_prox_rev,
   @w_usuario_rev      = li_usuario_rev,
   @w_monto            = li_monto,
   @w_moneda           = li_moneda,
   @w_utilizado        = isnull(li_utilizado,0),
   @w_rotativa         = li_rotativa,
   @w_clase            = li_clase,
   @w_admisible        = li_admisible,
   @w_noadmis          = li_noadmis,
   @w_estado           = li_estado,
   @w_reservado_linea  = li_reservado,
   @w_tipo_linea       = li_tipo,
   @w_dias_vig         = li_dias_vig,
   @w_num_desemb       = li_num_desemb,
   @w_monto_sol        = tr_monto_solicitado,
   @w_tipo_plazo       = li_tipo_plazo,
   @w_tipo_cuota       = li_tipo_cuota,
   @w_cuota_aproximada = li_cuota_aproximada,
   @w_migrado          = tr_migrado
   from   #linea
   where   li_numero = @w_numero

   delete #linea where li_tramite = @w_tramite

   select @w_ssn = siguiente + 1 from cobis..cl_seqnos with (nolock) where bdatos = 'cobis' and tabla = 'cl_masivo'

   update cobis..cl_seqnos with (rowlock)
   set siguiente = @w_ssn
   where bdatos = 'cobis'
   and tabla = 'cl_masivo'

   if @@error <> 0
   begin
     return 105001
   end

   /* TRANSACCION DE SERVICIO REGISTRO ANTERIOR **/
   insert into ts_linea (
   secuencial,   tipo_transaccion,   clase,
   fecha,        usuario,            terminal,
   oficina,      tabla,              srv,
   lsrv,         numero,             num_banco,
   ofic,         tramite,            cliente,
   grupo,        original,           fecha_aprob,
   fecha_inicio, per_revision,       fecha_vto,
   dias,         condicion_especial, ultima_rev,
   prox_rev,     usuario_rev,        monto,
   moneda,       utilizado,          rotativa,
   clase_cca,    admisible,          noadmis,
   estado,       reservado,          tipo )
   values (
   @w_ssn,       21026,              'P',
   @s_date,      @w_user,            @s_term,
   @s_ofi,       'cr_linea',         @s_srv,
   @s_lsrv,      @w_numero,          @w_num_banco,
   @w_oficina,   @w_tramite,         @w_cliente,
   @w_grupo,     @w_original,        @w_fecha_aprob,
   @w_fecha_inicio, @w_per_revision, @w_fecha_vto,
   @w_dias,      @w_condicion,       @w_ultima_rev,
   @w_prox_rev,  @w_usuario_rev,     @w_monto,
   @w_moneda,    @w_utilizado,       @w_rotativa,
   @w_clase,     @w_admisible,       @w_noadmis,
   @w_estado,    @w_reservado_linea, @w_tipo_linea )

   if @@error <> 0
   begin
      return 2103003 -- Error en insercion de transaccion de servicio
   end

   update cr_linea
   set li_estado = 'A'
   where li_numero = @w_numero

   if @@error <> 0
   begin
      select @w_descripcion = 'NO SE ANULO CUPO. ' +  isnull( cast(@w_tramite as varchar),'')+ ' CED: '+ isnull(@w_en_ced_ruc,'') + ' TIPO: ' + isnull( @w_tipo_ced ,'')
      exec cobis..sp_error_proc_masivos
           @i_id_carga        = @w_carga,
           @i_id_alianza      = @w_alianza1,
           @i_referencia      = 'Reajuste',
           @i_tipo_proceso    = 'E',
           @i_procedimiento   = 'sp_rechazo_aes',
           @i_codigo_interno  = @w_cliente,
           @i_codigo_err      = 9999999,
           @i_descripcion     = @w_descripcion

      break
   end

   select @w_ssn = siguiente + 1 from cobis..cl_seqnos with (nolock) where bdatos = 'cobis' and tabla = 'cl_masivo'

   update cobis..cl_seqnos with (rowlock)
   set siguiente = @w_ssn
   where bdatos = 'cobis'
   and tabla = 'cl_masivo'

   if @@error <> 0
   begin
     return 105001
   end

   /* TRANSACCION DE SERVICIO REGISTRO PORTERIOR**/
   insert into ts_linea (
   secuencial,   tipo_transaccion,   clase,
   fecha,        usuario,            terminal,
   oficina,      tabla,              srv,
   lsrv,         numero,             num_banco,
   ofic,         tramite,            cliente,
   grupo,        original,           fecha_aprob,
   fecha_inicio, per_revision,       fecha_vto,
   dias,         condicion_especial, ultima_rev,
   prox_rev,     usuario_rev,        monto,
   moneda,       utilizado,          rotativa,
   clase_cca,    admisible,          noadmis,
   estado,       reservado,          tipo )
   values (
   @w_ssn,       21026,              'A',
   @s_date,      @w_user,            @s_term,
   @s_ofi,       'cr_linea',         @s_srv,
   @s_lsrv,      @w_numero,          @w_num_banco,
   @w_oficina,   @w_tramite,         @w_cliente,
   @w_grupo,     @w_original,        @w_fecha_aprob,
   @w_fecha_inicio, @w_per_revision, @w_fecha_vto,
   @w_dias,      @w_condicion,       @w_ultima_rev,
   @w_prox_rev,  @w_usuario_rev,     @w_monto,
   @w_moneda,    @w_utilizado,       @w_rotativa,
   @w_clase,     @w_admisible,       @w_noadmis,
   'A',          @w_reservado_linea, @w_tipo_linea )

   if @@error <> 0
   begin
      return 2103003 -- Error en insercion de transaccion de servicio
   end
end
--FIN ALCANCE AZU

return 0
go
