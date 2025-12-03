/*************************************************************************/
/*   Archivo:            direccion_ts.sp                                 */
/*   Stored procedure:   sp_direccion_ts                                 */
/*   Base de datos:      cobis                                           */
/*   Producto:           Consolidador                                    */
/*   Disenado por:       WAVB                                            */
/*   Fecha de escritura: Jun/2020                                        */
/*************************************************************************/
/*                           IMPORTANTE                                  */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS', su uso no autorizado queda expresamente prohibido asi      */
/*   como cualquier alteracion o agregado hecho por alguno de sus        */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante.                  */
/*************************************************************************/
/*                            PROPOSITO                                  */
/*   Creacion de transacciones de servicio durante el proceso de update  */
/*   del manejo de direcciones                                           */
/*                                                                       */
/*               MODIFICACIONES                                          */
/*   FECHA          AUTOR          RAZON                                 */
/*   30/06/20       WAVB           Versión Inicial                       */
/*************************************************************************/
use cobis
go


set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
           from   sysobjects
           where  name = 'sp_direccion_ts')
  drop proc sp_direccion_ts
go


create proc sp_direccion_ts(
   @s_ssn                int, 
   @s_user               login        = null,
   @s_term               varchar(32)  = null,
   @s_date               datetime,
   @s_srv                varchar(30)  = null,
   @s_lsrv               varchar(30)  = null,
   @s_ofi                smallint     = NULL,
   @t_trn                int          = null,
   @t_show_version       bit          = 0,
   @i_ente               int          = null,
   @i_direccion          tinyint      = null
)
as
  declare
    @w_sp_name             varchar(32),
    @w_sp_msg              varchar(132)



select
  @w_sp_name = 'sp_direccion_ts'


---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end


--se almacena la informacion anterior a la actualizacion
insert into cobis..ts_direccion (
secuencial,         tipo_transaccion,       clase,               fecha,
usuario,            terminal,               srv,                 lsrv,
ente,               direccion,              descripcion,         sector,  
zona,               vigencia,               parroquia,           ciudad,
tipo,               oficina,                verificado,          barrio, 
provincia,          codpostal,              casa,                calle,
pais,               correspondencia,        alquilada,           cobro,
edificio,           departamento,           rural_urbano,        fact_serv_pu,
tipo_prop,          nombre_agencia,         fuente_verif,        fecha_ver,
hora,               reside,                 negocio,             referencias_dom,
otro_tipo,          localidad)
select   
secuencial         =   @s_ssn,        
tipo_transaccion   =   @t_trn,  
clase              =   'P',
fecha              =   @s_date,
usuario            =   @s_user,
terminal           =   @s_term,
srv                =   @s_srv,
lsrv               =   @s_lsrv,
ente               =   @i_ente,
direccion          =   @i_direccion,
descripcion        =   case when a.di_descripcion <> b.di_descripcion then a.di_descripcion else null end,
sector             =   case when a.di_sector <> b.di_sector then a.di_sector else null end,
zona               =   case when a.di_zona <> b.di_zona then a.di_zona else null end,
vigencia           =   case when a.di_vigencia <> b.di_vigencia then a.di_vigencia else null end,
parroquia          =   case when a.di_parroquia <> b.di_parroquia then a.di_parroquia else null end,
ciudad             =   case when a.di_ciudad <> b.di_ciudad then a.di_ciudad else null end,
tipo               =   case when a.di_tipo <> b.di_tipo then a.di_tipo else null end,
oficina            =   @s_ofi,
verificado         =   case when a.di_verificado <> b.di_verificado then a.di_verificado else null end,
barrio             =   case when a.di_barrio <> b.di_barrio then a.di_barrio else null end,
provincia          =   case when a.di_provincia <> b.di_provincia then a.di_provincia else null end,
codpostal          =   case when a.di_codpostal <> b.di_codpostal then a.di_codpostal else null end,
casa               =   case when a.di_casa <> b.di_casa then a.di_casa else null end,
calle              =   case when a.di_calle <> b.di_calle then a.di_calle else null end,
pais               =   case when a.di_pais <> b.di_pais then a.di_pais else null end,
correspondencia    =   case when a.di_correspondencia <> b.di_correspondencia then a.di_correspondencia else null end,
alquilada          =   case when a.di_alquilada <> b.di_alquilada then a.di_alquilada else null end,
cobro              =   case when a.di_cobro <> b.di_cobro then a.di_cobro else null end,
edificio           =   case when a.di_edificio <> b.di_edificio then a.di_edificio else null end,
departamento       =   case when a.di_departamento <> b.di_departamento then a.di_departamento else null end,
rural_urbano       =   case when a.di_rural_urbano <> b.di_rural_urbano then a.di_rural_urbano else null end,
fact_serv_pu       =   case when a.di_fact_serv_pu <> b.di_fact_serv_pu then a.di_fact_serv_pu else null end,
tipo_prop          =   case when a.di_tipo_prop <> b.di_tipo_prop then a.di_tipo_prop else null end,
nombre_agencia     =   case when a.di_nombre_agencia <> b.di_nombre_agencia then a.di_nombre_agencia else null end,
fuente_verif       =   case when a.di_fuente_verif <> b.di_fuente_verif then a.di_fuente_verif else null end,
fecha_ver          =   case a.di_verificado when 'S' then @s_date else null end,    
hora               =   getdate(),
reside             =   case when a.di_tiempo_reside <> b.di_tiempo_reside then a.di_tiempo_reside else null end,
negocio            =   case when a.di_negocio <> b.di_negocio then a.di_negocio else null end,
referencias_dom    =   case when a.di_referencias_dom <> b.di_referencias_dom then a.di_referencias_dom else null end,
otro_tipo          =   case when a.di_otro_tipo <> b.di_otro_tipo then a.di_otro_tipo else null end,
localidad          =   case when a.di_localidad <> b.di_localidad then a.di_localidad else null end
from  #tmp_clientes   a,   #tmp_clientes b
where a.di_ente    =   @i_ente
and a.di_direccion =   @i_direccion
and a.tipo         =   'A'
and a.di_ente      =   b.di_ente
and a.di_direccion =   b.di_direccion
and b.tipo         =   'D'


--se almacena la informacion posterior a la actualizacion

insert into cobis..ts_direccion (
secuencial,         tipo_transaccion,       clase,               fecha,
usuario,            terminal,               srv,                 lsrv,
ente,               direccion,              descripcion,         sector,  
zona,               vigencia,               parroquia,           ciudad,
tipo,               oficina,                verificado,          barrio, 
provincia,          codpostal,              casa,                calle,
pais,               correspondencia,        alquilada,           cobro,
edificio,           departamento,           rural_urbano,        fact_serv_pu,
tipo_prop,          nombre_agencia,         fuente_verif,        fecha_ver,
hora,               reside,                 negocio,             referencias_dom,
otro_tipo,          localidad)
select   
secuencial         =   @s_ssn,        
tipo_transaccion   =   @t_trn,  
clase              =   'A',
fecha              =   @s_date,
usuario            =   @s_user,
terminal           =   @s_term,
srv                =   @s_srv,
lsrv               =   @s_lsrv,
ente               =   @i_ente,
direccion          =   @i_direccion,
descripcion        =   case when a.di_descripcion <> b.di_descripcion then b.di_descripcion else null end,
sector             =   case when a.di_sector <> b.di_sector then b.di_sector else null end,
zona               =   case when a.di_zona <> b.di_zona then b.di_zona else null end,
vigencia           =   case when a.di_vigencia <> b.di_vigencia then b.di_vigencia else null end,
parroquia          =   case when a.di_parroquia <> b.di_parroquia then b.di_parroquia else null end,
ciudad             =   case when a.di_ciudad <> b.di_ciudad then b.di_ciudad else null end,
tipo               =   case when a.di_tipo <> b.di_tipo then b.di_tipo else null end,
oficina            =   @s_ofi,
verificado         =   case when a.di_verificado <> b.di_verificado then b.di_verificado else null end,
barrio             =   case when a.di_barrio <> b.di_barrio then b.di_barrio else null end,
provincia          =   case when a.di_provincia <> b.di_provincia then b.di_provincia else null end,
codpostal          =   case when a.di_codpostal <> b.di_codpostal then b.di_codpostal else null end,
casa               =   case when a.di_casa <> b.di_casa then b.di_casa else null end,
calle              =   case when a.di_calle <> b.di_calle then b.di_calle else null end,
pais               =   case when a.di_pais <> b.di_pais then b.di_pais else null end,
correspondencia    =   case when a.di_correspondencia <> b.di_correspondencia then b.di_correspondencia else null end,
alquilada          =   case when a.di_alquilada <> b.di_alquilada then b.di_alquilada else null end,
cobro              =   case when a.di_cobro <> b.di_cobro then b.di_cobro else null end,
edificio           =   case when a.di_edificio <> b.di_edificio then b.di_edificio else null end,
departamento       =   case when a.di_departamento <> b.di_departamento then b.di_departamento else null end,
rural_urbano       =   case when a.di_rural_urbano <> b.di_rural_urbano then b.di_rural_urbano else null end,
fact_serv_pu       =   case when a.di_fact_serv_pu <> b.di_fact_serv_pu then b.di_fact_serv_pu else null end,
tipo_prop          =   case when a.di_tipo_prop <> b.di_tipo_prop then b.di_tipo_prop else null end,
nombre_agencia     =   case when a.di_nombre_agencia <> b.di_nombre_agencia then b.di_nombre_agencia else null end,
fuente_verif       =   case when a.di_fuente_verif <> b.di_fuente_verif then b.di_fuente_verif else null end,
fecha_ver          =   case b.di_verificado when 'S' then @s_date else null end,    
hora               =   getdate(),
reside             =   case when a.di_tiempo_reside <> b.di_tiempo_reside then b.di_tiempo_reside else null end,
negocio            =   case when a.di_negocio <> b.di_negocio then b.di_negocio else null end,
referencias_dom    =   case when a.di_referencias_dom <> b.di_referencias_dom then b.di_referencias_dom else null end,
otro_tipo          =   case when a.di_otro_tipo <> b.di_otro_tipo then b.di_otro_tipo else null end,
localidad          =   case when a.di_localidad <> b.di_localidad then b.di_localidad else null end
from  #tmp_clientes   a,   #tmp_clientes b
where a.di_ente    =   @i_ente
and a.di_direccion =   @i_direccion
and a.tipo         =   'A'
and a.di_ente      =   b.di_ente
and a.di_direccion =   b.di_direccion
and b.tipo         =   'D'




insert into cobis..cl_actualiza (
ac_ente,           ac_fecha,           ac_tabla,
ac_campo,          ac_valor_ant,       ac_valor_nue,
ac_transaccion,    ac_secuencial1,     ac_secuencial2, 
ac_hora)
select
ac_ente            =   @i_ente,
ac_fecha           =   @s_date,
ac_tabla           =   'cobis..cl_direccion',
ac_campo           =   'di_descripcion',
ac_valor_ant       =   a.di_descripcion,
ac_valor_nue       =   b.di_descripcion,   
ac_transaccion     =   'U',
ac_secuencial1     =   @i_direccion,
ac_secuencial2     =   null,
ac_hora            =   getdate()
from  #tmp_clientes   a,   #tmp_clientes b
where a.di_ente    =   @i_ente
and a.di_direccion =   @i_direccion
and a.tipo         =   'A'
and a.di_ente      =   b.di_ente
and a.di_direccion =   b.di_direccion
and b.tipo         =   'D'
and a.di_descripcion <> b.di_descripcion

insert into cobis..cl_actualiza (
ac_ente,           ac_fecha,           ac_tabla,
ac_campo,          ac_valor_ant,       ac_valor_nue,
ac_transaccion,    ac_secuencial1,     ac_secuencial2, 
ac_hora)
select
ac_ente            =   @i_ente,
ac_fecha           =   @s_date,
ac_tabla           =   'cobis..cl_direccion',
ac_campo           =   'di_descripcion',
ac_valor_ant       =   a.di_zona,
ac_valor_nue       =   b.di_zona,   
ac_transaccion     =   'U',
ac_secuencial1     =   @i_direccion,
ac_secuencial2     =   null,
ac_hora            =   getdate()
from  #tmp_clientes   a,   #tmp_clientes b
where a.di_ente    =   @i_ente
and a.di_direccion =   @i_direccion
and a.tipo         =   'A'
and a.di_ente      =   b.di_ente
and a.di_direccion =   b.di_direccion
and b.tipo         =   'D'
and a.di_zona        <>   b.di_zona
	

go