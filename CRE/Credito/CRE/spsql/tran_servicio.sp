/************************************************************************/
/*  Archivo:                tran_servicio.sp                            */
/*  Stored procedure:       sp_tran_servicio                            */
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

if exists(select 1 from sysobjects where name ='sp_tran_servicio')
    drop proc sp_tran_servicio
go

create proc sp_tran_servicio
@s_ssn                  int = null,
@s_date                 datetime,
@s_user                 login,
@s_ofi                  smallint,
@s_term                 varchar(30) = 'term',
@i_tabla                varchar(255),
@i_borrado              char(1) = 'N',
@i_clave1               varchar(255) = null,
@i_clave2               varchar(255) = null,
@i_clave3               varchar(255) = null,
@i_clave4               varchar(255) = null,
@i_clave5               varchar(255) = null,
@i_clave6               varchar(255) = null,
@i_clave7               varchar(255) = null,
@i_clave8               varchar(255) = null,
@i_clave9               varchar(255) = null,
@i_clave10              varchar(255) = null
as


declare @w_ssn int

if @s_ssn is null
   exec @w_ssn = ADMIN...rp_ssn
else
   select @w_ssn = @s_ssn

if @i_tabla = 'cr_micro_seguro'
begin
   if @i_clave1 is not null begin
      insert into ts_micro_seguro (
      ms_secuencial_ts,       ms_cod_alterno_ts,      ms_tipo_transaccion_ts,
      ms_clase_ts,            ms_fecha_ts,            ms_usuario_ts,         
      ms_terminal_ts,         ms_oficina_ts,          ms_tabla_ts,           
      ms_fecha_real_ts,
      ms_secuencial,          ms_tramite,             ms_plazo,              
      ms_director_ofic,       ms_vendedor,            ms_estado,             
      ms_fecha_ini,           ms_fecha_fin,           ms_fecha_envio,        
      ms_cliente_aseg,        ms_valor,               ms_pagado)
      select
      @w_ssn,                 0,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      st_secuencial_seguro,   st_tramite,             0,
      0,                      st_vendedor,            '',
      null,                   null,                   '',
      0,                      0,                      0
      from   cr_seguros_tramite
      where  st_secuencial_seguro = convert(int,@i_clave1)

      if @@error <> 0 return 2103003

   end else begin

      insert into ts_micro_seguro (
      ms_secuencial_ts,       ms_cod_alterno_ts,      ms_tipo_transaccion_ts,
      ms_clase_ts,            ms_fecha_ts,            ms_usuario_ts,         
      ms_terminal_ts,         ms_oficina_ts,          ms_tabla_ts,           
      ms_fecha_real_ts,
      ms_secuencial,          ms_tramite,             ms_plazo,              
      ms_director_ofic,       ms_vendedor,            ms_estado,             
      ms_fecha_ini,           ms_fecha_fin,           ms_fecha_envio,        
      ms_cliente_aseg,        ms_valor,               ms_pagado)
      select
      @w_ssn,                 0,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      st_secuencial_seguro,   st_tramite,             0,
      0,                      st_vendedor,            '',
      null,                   null,                   '',
      0,                      0,                      0
      from   cr_seguros_tramite
      where  st_tramite = convert(int,@i_clave2)
      
      if @@error <> 0 return 2103003   
   end
end


if @i_tabla = 'cr_aseg_microseguro'
begin
   if @i_clave2 is null begin
      insert into ts_aseg_microseguro (
      am_secuencial_ts,       am_cod_alterno_ts,      am_tipo_transaccion_ts, 
      am_clase_ts,            am_fecha_ts,            am_usuario_ts,          
      am_terminal_ts,         am_oficina_ts,          am_tabla_ts,            
      am_fecha_real_ts,       
      am_microseg,            am_secuencial,          am_tipo_iden,           
      am_tipo_aseg,           am_lugar_exp,           am_identificacion,      
      am_nombre_comp,         am_fecha_exp,           am_fecha_nac,           
   am_genero,              am_lugar_nac,           am_estado_civ,          
      am_ocupacion,           am_parentesco,          am_direccion,           
      am_derecho_acrec,       am_plan,                am_valor_plan,          
      am_telefono,            am_observaciones,       am_principal)
      select
      @w_ssn,                 1,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      as_secuencial_seguro,   as_sec_asegurado,       as_tipo_ced,           
      as_tipo_aseg,           as_lugar_exp,           as_ced_ruc,      
      as_apellidos + as_nombres, as_fecha_exp ,       as_fecha_nac,           
      as_sexo,                as_ciudad_nac,          as_estado_civil,
      as_ocupacion,           as_parentesco,          as_direccion,           
      null,                   as_plan,                null,
      as_telefono,            as_observaciones,       null
      from   cr_asegurados
      where  as_secuencial_seguro = convert(int, @i_clave1)
      
      if @@error <> 0 return 2103003
   end else begin
      insert into ts_aseg_microseguro (
      am_secuencial_ts,       am_cod_alterno_ts,      am_tipo_transaccion_ts, 
      am_clase_ts,            am_fecha_ts,            am_usuario_ts,          
      am_terminal_ts,         am_oficina_ts,          am_tabla_ts,            
      am_fecha_real_ts,       
      am_microseg,            am_secuencial,          am_tipo_iden,           
      am_tipo_aseg,           am_lugar_exp,           am_identificacion,      
      am_nombre_comp,         am_fecha_exp,           am_fecha_nac,           
      am_genero,              am_lugar_nac,           am_estado_civ,          
      am_ocupacion,           am_parentesco,          am_direccion,           
      am_derecho_acrec,       am_plan,                am_valor_plan,          
      am_telefono,            am_observaciones,       am_principal)
      select
      @w_ssn,                 1,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      as_secuencial_seguro,   as_sec_asegurado,       as_tipo_ced,           
      as_tipo_aseg,           as_lugar_exp,           as_ced_ruc,      
      as_apellidos + as_nombres, as_fecha_exp ,       as_fecha_nac,           
      as_sexo,                as_ciudad_nac,          as_estado_civil,
      as_ocupacion,           as_parentesco,          as_direccion,           
      null,                   as_plan,                null,
      as_telefono,            as_observaciones,       null
      from   cr_asegurados
      where  as_secuencial_seguro  = convert(int, @i_clave1)
      and    as_sec_asegurado      = convert(int, @i_clave2)
      
      if @@error <> 0 return 2103003
   end         
end

if @i_tabla = 'cr_benefic_micro_aseg' begin

   if @i_clave1 is not null and @i_clave2 is null and @i_clave3 is null begin

      insert into ts_benefic_micro_aseg(
      bm_secuencial_ts,       bm_cod_alterno_ts,      bm_tipo_transaccion_ts, 
      bm_clase_ts,            bm_fecha_ts,            bm_usuario_ts,          
      bm_terminal_ts,         bm_oficina_ts,          bm_tabla_ts,            
      bm_fecha_real_ts,       
      bm_microseg,            bm_asegurado,           bm_secuencial,          
      bm_tipo_iden,           bm_identificacion,      bm_nombre_comp,         
      bm_fecha_nac,           bm_genero,              bm_lugar_nac,           
      bm_estado_civ,          bm_ocupacion,           bm_parentesco,          
      bm_direccion,           bm_telefono,            bm_porcentaje)
      select
      @w_ssn,                 2,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,   @s_ofi,                 @i_tabla,
      getdate(),
      be_secuencial_seguro,   be_sec_asegurado,       be_sec_benefic,          
      be_tipo_ced,            be_ced_ruc,             isnull(be_nombres,'') + isnull(be_apellidos,''),
      be_fecha_nac,           be_sexo,                be_ciudad_nac,           
      be_estado_civil,        be_ocupacion,           be_parentesco,          
      be_direccion,           be_telefono,            be_porcentaje
      from   cr_beneficiarios
      where  be_secuencial_seguro = convert(int, @i_clave1)
      
      if @@error <> 0 return 2103003
   end 
   if @i_clave1 is not null and @i_clave2 is not null and @i_clave3 is null begin

      insert into ts_benefic_micro_aseg(
      bm_secuencial_ts,       bm_cod_alterno_ts,      bm_tipo_transaccion_ts, 
      bm_clase_ts,            bm_fecha_ts,            bm_usuario_ts,          
      bm_terminal_ts,         bm_oficina_ts,          bm_tabla_ts,            
      bm_fecha_real_ts,       
      bm_microseg,            bm_asegurado,           bm_secuencial,          
      bm_tipo_iden,           bm_identificacion,      bm_nombre_comp,         
      bm_fecha_nac,           bm_genero,              bm_lugar_nac,           
      bm_estado_civ,          bm_ocupacion,           bm_parentesco,          
      bm_direccion,           bm_telefono,            bm_porcentaje)
      select
      @w_ssn,                 2,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      be_secuencial_seguro,   be_sec_asegurado,       be_sec_benefic,          
      be_tipo_ced,            be_ced_ruc,             isnull(be_nombres,'') + isnull(be_apellidos,''),
      be_fecha_nac,           be_sexo,                be_ciudad_nac,           
      be_estado_civil,        be_ocupacion,           be_parentesco,          
      be_direccion,           be_telefono,            be_porcentaje
      from   cr_beneficiarios
      where  be_secuencial_seguro = convert(int, @i_clave1)
      and    be_sec_asegurado     = convert(int, @i_clave2)
      
      if @@error <> 0 return 2103003
    end

    if @i_clave1 is not null and @i_clave2 is not null and @i_clave3 is not null begin

      insert into ts_benefic_micro_aseg(
      bm_secuencial_ts,       bm_cod_alterno_ts,      bm_tipo_transaccion_ts, 
      bm_clase_ts,            bm_fecha_ts,            bm_usuario_ts,          
      bm_terminal_ts,         bm_oficina_ts,          bm_tabla_ts,            
      bm_fecha_real_ts,       
      bm_microseg,            bm_asegurado,           bm_secuencial,          
      bm_tipo_iden,           bm_identificacion,      bm_nombre_comp,         
      bm_fecha_nac,           bm_genero,              bm_lugar_nac,           
      bm_estado_civ,          bm_ocupacion,           bm_parentesco,          
      bm_direccion,           bm_telefono,            bm_porcentaje)
      select
      @w_ssn,                 2,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      be_secuencial_seguro,   be_sec_asegurado,       be_sec_benefic,          
      be_tipo_ced,            be_ced_ruc,             isnull(be_nombres,'') + isnull(be_apellidos,''),
      be_fecha_nac,           be_sexo,                be_ciudad_nac,           
      be_estado_civil,        be_ocupacion,           be_parentesco,          
      be_direccion,           be_telefono,            be_porcentaje
      from   cr_beneficiarios
      where  be_secuencial_seguro = convert(int, @i_clave1)
      and    be_sec_asegurado     = convert(int, @i_clave2)
      and    be_sec_benefic       = convert(int, @i_clave3)
      
      if @@error <> 0 return 2103003
   end
end 

if @i_tabla = 'cr_enfermedades' begin
   if @i_clave1 is not null and @i_clave2 is null and @i_clave3 is null begin
      insert into ts_enfermedades(
      en_secuencial_ts,       en_cod_alterno_ts,      en_tipo_transaccion_ts, 
      en_clase_ts,            en_fecha_ts,            en_usuario_ts,          
      en_terminal_ts,         en_oficina_ts,          en_tabla_ts,            
      en_fecha_real_ts,       
      en_microseg,            en_asegurado,           en_enfermedad)
      select
      @w_ssn,                 3,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      en_microseg,            en_asegurado,           en_enfermedad          
      from   cr_enfermedades
      where  en_microseg  = convert(int, @i_clave1)
   
      if @@error <> 0 return 2103003
   end
   
   if @i_clave1 is not null and @i_clave2 is not null and @i_clave3 is null begin
      insert into ts_enfermedades(
      en_secuencial_ts,       en_cod_alterno_ts,      en_tipo_transaccion_ts, 
      en_clase_ts,            en_fecha_ts,            en_usuario_ts,          
      en_terminal_ts,         en_oficina_ts,          en_tabla_ts,            
      en_fecha_real_ts,       
      en_microseg,            en_asegurado,           en_enfermedad)
      select
      @w_ssn,                 3,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      en_microseg,            en_asegurado,           en_enfermedad          
      from   cr_enfermedades
      where  en_microseg  = convert(int, @i_clave1)
      and    en_asegurado = convert(int, @i_clave2)
   
      if @@error <> 0 return 2103003
   end 
   if @i_clave1 is not null and @i_clave2 is not null and @i_clave3 is not null begin
      insert into ts_enfermedades(
      en_secuencial_ts,       en_cod_alterno_ts,      en_tipo_transaccion_ts, 
      en_clase_ts,            en_fecha_ts,            en_usuario_ts,          
      en_terminal_ts,         en_oficina_ts,          en_tabla_ts,            
      en_fecha_real_ts,       
      en_microseg,            en_asegurado,           en_enfermedad)
      select
      @w_ssn,                 3,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      en_microseg,            en_asegurado,           en_enfermedad          
      from   cr_enfermedades
      where  en_microseg   = convert(int, @i_clave1)
      and    en_asegurado  = convert(int, @i_clave2)
      and    en_enfermedad = @i_clave3
   
      if @@error <> 0 return 2103003   
   end
end

if @i_tabla = 'cr_campana_toperacion' --Req 209 Ceh Control Lineas de Credito Contraofertas
begin
      insert into ts_campana_toperacion (
      ct_secuencial_ts,       ct_cod_alterno_ts,      ct_tipo_transaccion_ts,
      ct_clase_ts,            ct_fecha_ts,            ct_usuario_ts,         
      ct_terminal_ts,         ct_oficina_ts,          ct_tabla_ts,           
      ct_fecha_real_ts,
      ct_operacion,           ct_campana,             ct_toperacion)
      select
      @w_ssn,                 4,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),
      @i_clave1,              convert(int,@i_clave2), ct_toperacion
      from   cr_campana_toperacion
      where  ct_campana = convert(int,@i_clave2)     
end

-- INI JAR REQ 230
if @i_tabla = 'cr_hono_mora'
begin   
   insert into ts_hono_mora(
      hm_secuencial_ts,       hm_cod_alterno_ts,      hm_tipo_transaccion_ts,
      hm_clase_ts,            hm_fecha_ts,            hm_usuario_ts,         
      hm_terminal_ts,         hm_oficina_ts,          hm_tabla_ts,           
      hm_fecha_real_ts,       hm_operacion_ts,        hm_codigo_ts,
      hm_estado_cobranza_ts,  hm_dia_inicial_ts,      hm_dia_final_ts,
      hm_anio_castigo_ts,     hm_tasa_cobrar_ts,      hm_tarifa_unica_ts)
   select
      @w_ssn,                 5,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),              @i_clave1,              hm_codigo,
      hm_estado_cobranza,     hm_dia_inicial,         hm_dia_final,
      hm_anio_castigo,        hm_tasa_cobrar,         hm_tarifa_unica   
     from cr_hono_mora
    where hm_codigo = convert(int,@i_clave2)
   
   if @@error <> 0 return 2103003
end 

if @i_tabla = 'cr_hono_abogado'
begin
   insert into ts_hono_abogado(
      ha_secuencial_ts,       ha_cod_alterno_ts,      ha_tipo_transaccion_ts,
      ha_clase_ts,            ha_fecha_ts,            ha_usuario_ts,
      ha_terminal_ts,         ha_oficina_ts,          ha_tabla_ts,
      ha_fecha_real_ts,       ha_operacion_ts,        ha_id_abogado_ts,
      ha_codigo_honorario_ts, ha_tasa_cobrar_ts,      ha_tarifa_unica_ts)
   select
      @w_ssn,                 6,                      22108,
      @i_borrado,             @s_date,                @s_user,
      @s_term,                @s_ofi,                 @i_tabla,
      getdate(),              @i_clave1,              ha_id_abogado,
      ha_codigo_honorario,    ha_tasa_cobrar,         ha_tarifa_unica
     from cr_hono_abogado
    where ha_id_abogado       = @i_clave2
      and ha_codigo_honorario = convert(int,@i_clave3)
   
   if @@error <> 0 return 2103003
end
-- FIN JAR REQ 230


return 0


GO
