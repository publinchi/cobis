/************************************************************************/
/*  Archivo:                estudiocredito.sp                           */
/*  Stored procedure:       sp_estudiocredito                           */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
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
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_estudiocredito')
    drop proc sp_estudiocredito
go

create proc sp_estudiocredito(
@s_user              login        = null,
@s_date              datetime     = null,
@s_ofi               smallint     = null,
@s_term              varchar(30)  = null,
@s_ssn               int          = null,
@i_ente              int          = null,
@i_cedruc            numero       = null,
@i_tipo              varchar(10)  = null,
@i_formato_f         tinyint      = 103,
@i_frontend          char(1)      = 'N',
@i_con_ente          char(1)      = 'S',
@o_descripcion       varchar(80)  = null out,
@o_ciudad            int          = null out,
@o_parroquia         smallint     = null out,
@o_provincia         smallint     = null out,
@o_pais              smallint     = null out,
@o_telefono          varchar(16)  = null out,
@o_desciudad         varchar(40)  = null out,
@o_desparroquia      varchar(40)  = null out,
@o_desprovincia      varchar(40)  = null out,
@o_despais           varchar(20)  = null out,
@o_tipoced           varchar(10)  = null out,
@o_cedruc            varchar(30)  = null out,
@o_ciudadexp         int          = null out,
@o_desciuexp         varchar(60)  = null out,
@o_fecha_exp         varchar(10)  = null out,
@o_fecha_nac         varchar(10)  = null out,
@o_tipodir           varchar(20)  = null out,
@o_nombre            varchar(20)  = null out,
@o_papellido         varchar(20)  = null out,
@o_sapellido         varchar(20)  = null out,
@o_ofiprod           smallint     = null out,
@o_tel_cel           varchar(16)  = null out,
@o_inddir            char(1)      = null out,
@o_ciudadnac         int          = null out,
@o_desciunac         varchar(60)  = null out,
@o_genero            sexo         = null out,
@o_ocupacion         varchar(10)  = null out,
@o_descocupa         varchar(20)  = null out,
@o_ecivil            varchar(10)  = null out,
@o_descecivil        varchar(20)  = null out,
@o_barrio            varchar(40)  = null out,
@o_tvivienda         varchar(10)  = null out,
@o_desctviv          varchar(20)  = null out,
@o_nivelest          varchar(10)  = null out,
@o_descnest          varchar(20)  = null out,
@o_fch_neg           varchar(20)  = null out,
@o_en_estrato        varchar(10)  = null out,
@o_p_num_cargas      int          = null out,
@o_coy_papellido     varchar(20)  = null out,
@o_coy_sapellido     varchar(20)  = null out,
@o_coy_nombres       varchar(20)  = null out,
@o_coy_tipoced       varchar(10)  = null out,
@o_coy_cedruc        varchar(30)  = null out,
@o_coy_ciudadexp     int          = null out,
@o_coy_desciuexp     varchar(60)  = null out,
@o_coy_fecha_exp     varchar(10)  = null out,
@o_coy_empresa       varchar(20)  = null out,
@o_coy_telefono      varchar(16)  = null out,
@o_coy_direccion     tinyint      = null out,
@o_coy_descripcion   varchar(80)  = null out,
@i_tramite           int          = null,
@o_profesion         catalogo     = null,
@i_intervalo_ini     int          = null,
@i_intervalo_fin     int          = null,
@i_tipo_reporte      varchar(5)   = null,
@i_codeudor          char(1)      = 'N',
@i_rango_ini         int          = null, -- Manejo de rangos para registros en reportes por VB
@i_rango_fin         int          = null,
@i_intervalo_ini_j   int          = null,
@i_intervalo_fin_j   int          = null,
@i_ssn               int          = null,
@i_banco             cuenta       = null,
@i_limpieza          char(1)      = 'N',
@w_tipo_norm         int          = null,  -- CCA 436
@o_alianza           varchar(255) = null out
)
as

declare
@w_sp_name              varchar(20),
@w_direccion            tinyint,
@w_descripcion          varchar(80),
@w_ciudad               int,
@w_parroquia            smallint,
@w_provincia            smallint,
@w_pais                 smallint,
@w_telefono             varchar(16),
@w_desciudad            varchar(40),
@w_desparroquia         varchar(40),
@w_desprovincia         varchar(40),
@w_despais    varchar(20),
@w_tipoced              varchar(10),
@w_cedruc               varchar(30),
@w_ciudadexp            int,
@w_desciuexp            varchar(60),
@w_fecha_exp            varchar(10),
@w_fecha_nac            varchar(10),
@w_fecha_nac_datetime   datetime, --JJMD Inc 1055
@w_tipodir              varchar(20),
@w_nombre               varchar(50), --varchar(20),
@w_papellido            varchar(20),
@w_sapellido            varchar(20),
@w_ofiprod              smallint,
@w_tel_cel              varchar(16),
@w_ciudadnac            int,
@w_desciunac            varchar(60),
@w_genero               sexo,
@w_ocupacion            varchar(10),
@w_descocupa            varchar(20),
@w_ecivil               varchar(10),
@w_descecivil           varchar(20),
@w_barrio               varchar(40),
@w_rural_urb            char(1),
@w_tvivienda            varchar(10),
@w_desctviv             varchar(20),
@w_nivelest             varchar(10),
@w_descnest             varchar(20),
@w_fch_neg              varchar(20),
@w_en_estrato           varchar(10),
@w_coy_papellido        varchar(20),
@w_coy_sapellido        varchar(20),
@w_coy_nombres          varchar(20),
@w_coy_tipoced          varchar(10),
@w_coy_cedruc           varchar(30),
@w_coy_ciudadexp        int,
@w_coy_desciuexp        varchar(60),
@w_coy_fecha_exp        varchar(10),
@w_coy_empresa          varchar(20),
@w_coy_telefono         varchar(16),
@w_coy_direccion        tinyint,
@w_coy_descripcion      varchar(80),
@w_p_num_cargas         int,
@w_hi_ente              int,
@w_profesion            catalogo,
@w_desc_profesion       descripcion,
/* Microempresa*/
@w_secuencial           int,
@w_descripcion_micro    descripcion,
@w_num_trabaj_remu      int ,
@w_num_trabaj_no_remu   int,
@w_experiencia_fecha    datetime,
@w_tipo_empresa         varchar(10),
@w_ciiu                 descripcion,
@w_actividad            descripcion,
@w_nombre_micro         descripcion,
@w_nit                  descripcion,
@w_direccion_micro      descripcion,
@w_barrio_micro         smallint,
@w_desc_barrio_micro    descripcion,
@w_mercado_que_atiende  descripcion,
@w_numero_empleados     int,
@w_tiempo_propie_negoc  int,
@w_experiencia          int,
@w_local                varchar(2),
@w_descr_local          varchar(10),
@w_nombre_arrendador    varchar(60),
@w_telefono_arrenda     varchar(16),
@w_refer_arrendador     descripcion,
@w_ciudad_micro         descripcion,
@w_des_depexp           varchar(64),
@w_des_paisexp          varchar(64),
@w_hijos                smallint,
@w_fondos               varchar(255),
@w_monto                varchar(24),
@w_plazo                smallint,
@w_t_plazo              varchar(10),
@w_cuota                varchar(24),
@w_des_tipo             varchar(64),
@w_trabajo              smallint,
@w_empresa              varchar(64),
@w_sueldo               money,
@w_fec_ingreso          varchar(10),
@w_cargo                varchar(64),
@w_contrato             varchar(64),
@w_dir_trabajo          varchar(100),
@w_ref_vienda           smallint,
@w_nom_vienda           varchar(64),
@w_tel_vienda           varchar(16),
@w_pa_vivienda          varchar(10),
@w_secuencial_finan     int,
@w_oi_valorcon          money,
@w_oi_valorhij          money,
@w_oi_valorpen          money,
@w_oi_valorarr          money,
@w_oi_valorint          money,
@w_oi_valorsue          money,
@w_oi_valorotr          money,
@w_tde                  varchar(10),
@w_tdr                  varchar(10),
@w_tdn                  varchar(10),
@w_telefono_emp         varchar(16),
@w_tipo_tramite         varchar(10),
@w_telefono_neg         varchar(16),
@w_cuenta               int,
@w_decimales            tinyint,
@w_mon_nacional         tinyint,
@w_cuenta_cred_rur      tinyint,
@w_en_recurso_pub       char(1),
@w_en_influencia        char(1),
@w_en_persona_pub       char(1),
@w_en_victima           char(1),
@w_en_relacint          char(1),
@w_operacion            int,
@w_pregunta1            varchar(255),
@w_pregunta2            varchar(255),
@w_pregunta3            varchar(255),
@w_pregunta4            varchar(255),
@w_pregunta5            varchar(255),
@w_departamento         int,
@w_desc_dep_micro       varchar(40),
@w_mercado              catalogo,
@w_operacion_res        int,
@w_tipo_t               varchar(2),
@w_error                int,
@w_banco                cuenta,
@w_fecha_fija           char(1),
@w_dia_pago             tinyint,
@w_tasa_reest           float,
@w_t_cuota              catalogo,
@w_op_reest             int,
@w_cod_direccion        int,
@w_tel_trabajo          varchar(14),
@w_fax_trabajo          varchar(14),
@w_edad                 tinyint,
@w_activoypasivos       varchar(3),
@w_ingresosyegresos     varchar(3),
@w_ingreso_familiar     money,
@w_ventas               money,
@w_ingresos             money,
@w_egresos              money,
@w_gasto_familiar       money,
@w_costo_venta          money,
@w_gasto_gral           money,
@w_oblig_empresa        money,
@w_microempresa_finan   int,
@w_sev                  tinyint,
@w_msg                  varchar(250),
@w_cta145               tinyint,
@w_desc145              descripcion,
@w_en_actividad         catalogo,
@w_tel_neg              varchar(15),
@w_dir_neg              varchar(60),
@w_barrio_neg           varchar(30),
@w_desciudad_neg        varchar(30),
@w_actividad_mo         varchar(10),
@w_des_actividad_mo     varchar(30),
@w_subtipo              char(1),
@w_re_relacion          int,
@w_cliente_rl           int,
@w_nombre_com_rl        varchar(200),
@w_cedula_rl            varchar(20),
@w_tipo_doc_rl          varchar(2),
@w_ciudad_exp_rl        varchar(30),
@w_dir_rl               varchar(100),
@w_ciudad_dir_rl        varchar(30),
@w_depto_dir_rl         varchar(30),
@w_plazo_dias           int,
@w_cuota_dias           int,
@w_div_cuota            smallint,
@w_padre                cuenta,
@w_tramite              int,
@w_lin_credito          cuenta,
@w_alianza              varchar(255)


select
@w_sp_name         = 'sp_datos_cliente',
@i_rango_ini       = isnull(@i_rango_ini,     0),
@i_rango_fin       = isnull(@i_rango_fin,     4),
@i_intervalo_ini   = isnull(@i_intervalo_ini, 0),
@i_intervalo_fin   = isnull(@i_intervalo_fin,12)

select @w_pa_vivienda = pa_char
from   cobis..cl_parametro
where  pa_producto = 'MIS'
and    pa_nemonico = 'TRA'


if @i_ente is null and @i_cedruc is null begin
   select @w_error = 101129, @w_msg = 'Codigo del ente o Numero de Documento es Requerido', @w_sev = 0
   goto ERROR_FIN
end

if @i_ente is null begin

   select @i_ente = en_ente
   from   cobis..cl_ente
   where  en_ced_ruc   = @i_cedruc

   if @@rowcount = 0  begin
      select @w_error = 101129, @w_msg = 'No existe el cliente indicado', @w_sev = 0
      goto ERROR_FIN
   end

end

select 
@w_alianza = convert(varchar(255), al_nemonico + ' - ' + al_nom_alianza)
from cr_tramite with (nolock), cobis..cl_alianza_cliente with (nolock), cobis..cl_alianza with (nolock)
where tr_tramite     = @i_tramite
and   tr_cliente     = ac_ente
and   ac_alianza     = al_alianza
and   al_estado      = 'V'
and   al_estado      = ac_estado

select @w_operacion   = op_operacion ,
       @w_lin_credito = op_lin_credito
from cob_cartera..ca_operacion 
where op_tramite = @i_tramite

if @i_con_ente = 'N' goto DIRECCION


/* REPORTE DE INFORMACION FINANCIERA */
if @i_tipo_reporte = 'INFF' begin

    if @i_rango_ini = 0 or @i_limpieza = 'S' begin

       delete rp_info_financiera with (rowlock)
       from rp_info_financiera with (index=rp_info_financiera_1)
       where usuario = @s_user
       --and   sesion  = @i_ssn -- limpiamos todos los registros del cliente

       if @i_limpieza = 'S' return 0

       select @i_ssn = @s_ssn

       declare @tmp_info_financiera table(
 item              int              null,
       codigo            int              null,
       Nivel             varchar(20)      null,
       DescN1            varchar (50)     null,
       Nivel2            varchar(50)      null,
       DescN2            varchar (50)     null,
       Nivel3            varchar(50)      null,
       DescN3            varchar (50)     null,
       Nivel4            varchar(50)      null,
       DescN4            varchar (50)     null,
       Sumatoria         char(1)          null,
       Descripcion       varchar(50)      null,
       Valor             varchar(50)      null,
       Total             varchar(50)      null,
       id                int          not null,
       t_dif_secuencial  int              null,
       t_dif_codigo_var  int              null
       )

       declare @tmp_detalleGrupos table (
       codigo            int              null,
       cuenta            varchar(80)      null,
       Descripcion       varchar(50)      null,
       Valor             varchar(50)      null,
       item              int              null,
       dif_secuencial    int              null
       )

       select
       @w_secuencial_finan   = mi_secuencial
       from cr_microempresa
       where mi_tramite = @i_tramite

       select @w_microempresa_finan = @w_secuencial_finan

       insert @tmp_info_financiera
       select
       'item ' = -1 ,
       'codigo'      = if_codigo,
       'Nivel 1'     = if_nivel1,
       'Desc. N1'    = (select valor from cobis..cl_catalogo
                        where tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_primer_nivel' )
                        and   codigo = F.if_nivel1),
       'Nivel 2'     = if_nivel2,
       'Desc. N2'    = (select valor from cobis..cl_catalogo
                        where tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_segundo_nivel' )
                        and   codigo = F.if_nivel2),
       'Nivel 3'     = if_nivel3,
       'Desc. N3'    = (select valor from cobis..cl_catalogo
                        where tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_tercer_nivel' )
                        and   codigo = F.if_nivel3),
       'Nivel 4'     = if_nivel4,
       'Desc. N4'    = (select valor from cobis..cl_catalogo
                        where tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_cuarto_nivel' )
                        and   codigo = F.if_nivel4),
       'Sumatoria'   = if_sumatoria,
       'Descripcion' = if_descripcion,
       'Valor'       = '',
       'Total'       = convert(varchar, if_total  ),
       0 ,
       0,
       0
       from cr_inf_financiera F
       where if_microempresa = @w_microempresa_finan
       and   if_tramite      = @i_tramite
       and   if_codigo  not in (150,160,170)
       order by if_codigo

       --Obteniendo el codigo de productos ruruales para cambiar el formato de la fecha en los reportes
       select @w_cuenta_cred_rur = pa_int
       from cobis..cl_parametro
       where  pa_nemonico = 'CCVAR'
       and    pa_producto = 'CRE'


       insert @tmp_info_financiera
       select
       'item ' = def_codigo ,
       codigo,
       Nivel,
       DescN1,
       Nivel2,
       DescN2,
       Nivel3,
       DescN3,
       Nivel4,
       DescN4,
       Sumatoria,
       'Descripcion' = def_descripcion,
       'Valor'       =  case v.dif_tipo
                        when 'M' then convert(varchar,v.dif_money)
                        when 'C' then (select case
                                       when e.def_tabla_catalogo  IS NULL
                                       then
                                           i.dif_cadena
                                       else
                                           (select c.valor
                                           from cobis..cl_tabla t, cobis..cl_catalogo c
                                          where t.codigo = c.tabla
                                           and   c.codigo = i.dif_cadena
                                           and   t.tabla  = e.def_tabla_catalogo)
                                       end
                                       from cr_det_est_financiero e,  cr_det_inf_financiera i
                                       where e.def_codigo  = i.dif_codigo_var
                                       and   e.def_est_fin = i.dif_inf_fin
                                       and   dif_inf_fin    = codigo --codigo cuenta
                                       and   dif_microempresa = @w_microempresa_finan --cod microempresa
                                       and   i.dif_codigo_var = v.dif_codigo_var
                                       and   i.dif_secuencial = v.dif_secuencial )
                        when 'F' then convert(varchar,v.dif_float)
                        when 'I' then convert(varchar,v.dif_entero)
                        else
                           case codigo--codigo de creditos ruruales para cambiar el formato de la fecha en los reportes
                               when @w_cuenta_cred_rur  then CONVERT(VARCHAR(20),v.dif_fecha, 106)
                               else convert(varchar,v.dif_fecha)
                           end

                        end,
       'Total'       = def_total ,
       item,
       dif_secuencial,
       dif_codigo_var
       from cr_det_inf_financiera v, cr_det_est_financiero , @tmp_info_financiera
       where dif_inf_fin    = codigo -- @i_codigoinf
       and def_codigo       = dif_codigo_var
       and dif_inf_fin      = def_est_fin
       and dif_microempresa = @w_microempresa_finan  -- @i_microempresa
       order by codigo, Nivel3, dif_secuencial, dif_codigo_var ASC

       delete @tmp_info_financiera
       where Total is null


       insert @tmp_detalleGrupos
       select codigo, Nivel, Descripcion, Valor, t_dif_codigo_var, t_dif_secuencial
       from @tmp_info_financiera
       order by codigo, Nivel, t_dif_secuencial, t_dif_codigo_var ASC

       --------------------------------------------
       insert rp_info_financiera with(rowlock)
       select
       @s_user,
       @i_ssn,
       item,
       codigo,
       Nivel,
       DescN1,
       isnull(Nivel2, '-'),
       isnull(DescN2, '-'),
       isnull(Nivel3, '-'),
       isnull(DescN3, '-'),
       isnull(Nivel4, '-'),
       isnull(DescN4, '-'),
       Sumatoria   ,
       Descripcion ,
       Valor,
       Total,
       0,
       t_dif_secuencial ,
       t_dif_codigo_var ,
       '', '',
       '', '',
       '', '',
       '', '',
       '', '',
       '', '',
       '', '',
       '', ''
       from @tmp_info_financiera
       order by codigo, Nivel, t_dif_secuencial, t_dif_codigo_var ASC


       update rp_info_financiera with (rowlock)
       set Nivel2 = Nivel,
       DescN2 = DescN1
       from rp_info_financiera with (index=rp_info_financiera_1)
       where usuario = @s_user
       and   sesion  = @i_ssn
       and   Nivel2  = '-'


       update rp_info_financiera with (rowlock)
       set  Nivel3 = Nivel2,
       DescN3 = DescN2
       from rp_info_financiera with (index=rp_info_financiera_1)
       where usuario = @s_user
       and   sesion  = @i_ssn
       and   Nivel3  = '-'


       update rp_info_financiera with (rowlock)
       set Nivel4 = Nivel3,
       DescN4 = DescN3
       from rp_info_financiera with (index=rp_info_financiera_1)
       where usuario = @s_user
       and   sesion  = @i_ssn
       and   Nivel4  = '-'

       delete @tmp_detalleGrupos
       where Descripcion is null
       and Valor = ''


       ---Ý declaramos las variables
       declare
       @codigo          int             ,
       @cuenta          varchar(80)     ,
       @Descripcion     varchar(50)     ,
       @Valor    varchar(50)     ,
       @item            int,
       @dif_secuencial  int,
       @ubicacion       int

       select @ubicacion = 1
       ---Ý declaramos un cursor llamado 'CURSORITO'. El select debe contener s¥lo los campos a utilizar.
       declare cur_items cursor for
       select
       codigo ,
       cuenta ,
       Descripcion ,
       Valor       ,
       item        ,
       dif_secuencial
       from @tmp_detalleGrupos

       open cur_items
       ---Ý Avanzamos un registro y cargamos en las variables los valores encontrados en el primer registro
       fetch next from cur_items
       into @codigo ,  @cuenta , @Descripcion , @Valor, @item , @dif_secuencial

       while @@fetch_status = 0
       begin
           if @ubicacion <>  @dif_secuencial
           begin
               select @ubicacion =@dif_secuencial
           end

           if  @item = 1 begin
               update rp_info_financiera with (rowlock)
               set Campo1 = @Descripcion,
                Valor1 = @Valor
               from rp_info_financiera with (index=rp_info_financiera_1)
               where usuario          = @s_user
               and   sesion           = @i_ssn
               and   codigo           = @codigo
               and   t_dif_secuencial = @ubicacion
               and   t_dif_codigo_var = 1
           end

           if  @item = 2  begin
               update rp_info_financiera with (rowlock)
               set Campo2 = @Descripcion,
                Valor2 = @Valor
               from rp_info_financiera with (index=rp_info_financiera_1)
               where usuario          = @s_user
               and   sesion           = @i_ssn
               and   codigo           = @codigo
               and   t_dif_secuencial = @ubicacion
               and   t_dif_codigo_var = 1
           end

           if  @item = 3  begin

               update rp_info_financiera with (rowlock)
               set Campo3 = @Descripcion,
                Valor3 = @Valor
               from rp_info_financiera with (index=rp_info_financiera_1)
               where usuario          = @s_user
               and   sesion           = @i_ssn
               and   codigo           = @codigo
               and   t_dif_secuencial = @ubicacion
               and   t_dif_codigo_var = 1
           end

           if  @item = 4  begin

               update rp_info_financiera with (rowlock)
               set Campo4 = @Descripcion,
                Valor4 = @Valor
               from rp_info_financiera with (index=rp_info_financiera_1)
               where usuario          = @s_user
               and   sesion           = @i_ssn
               and   codigo           = @codigo
               and   t_dif_secuencial = @ubicacion
               and   t_dif_codigo_var = 1
           end

           if  @item = 5  begin

               update rp_info_financiera with (rowlock)
               set Campo5 = @Descripcion,
                Valor5 = @Valor
               from rp_info_financiera with (index=rp_info_financiera_1)
               where usuario          = @s_user
               and   sesion           = @i_ssn
               and   codigo           = @codigo
               and   t_dif_secuencial = @ubicacion
               and   t_dif_codigo_var = 1
           end

           if  @item = 6 begin

               update rp_info_financiera with (rowlock)
               set Campo6 = @Descripcion,
                Valor6 = @Valor
               from rp_info_financiera with (index=rp_info_financiera_1)
               where usuario          = @s_user
               and   sesion           = @i_ssn
               and   codigo           = @codigo
               and   t_dif_secuencial = @ubicacion
               and   t_dif_codigo_var = 1
           end

           if  @item = 7 begin

               update rp_info_financiera with (rowlock)
               set Campo7 = @Descripcion,
                Valor7 = @Valor
               from rp_info_financiera with (index=rp_info_financiera_1)
               where usuario          = @s_user
               and   sesion           = @i_ssn
               and   codigo           = @codigo
               and   t_dif_secuencial = @ubicacion
           end

           if  @item = 8 begin

               update rp_info_financiera with (rowlock)
               set Campo8 = @Descripcion,
                Valor8 = @Valor
               from rp_info_financiera with (index=rp_info_financiera_1)
               where usuario          = @s_user
               and   sesion           = @i_ssn
               and   codigo           = @codigo
               and   t_dif_secuencial = @ubicacion
               and   t_dif_codigo_var = 1
           end

           -- Avanzamos otro registro
           fetch next from cur_items
           into @codigo ,  @cuenta , @Descripcion , @Valor, @item , @dif_secuencial
       end

       close cur_items
       deallocate cur_items

       insert into rp_info_financiera with (rowlock) (
       usuario,
       sesion,
       item,
       Nivel,
       codigo,
       DescN1,
       Campo1,
       Valor1,
       Nivel4,
       DescN4,
       t_dif_secuencial,
       t_dif_codigo_var
       )
       select
       usuario,
       sesion,
       1,
       Nivel,
       codigo,
       DescN1,
       'TOTAL',
       sum(cast(Valor as money)),
       'TOTAL',
       'TOTAL',
       max(t_dif_secuencial),
       max(t_dif_codigo_var)
       from rp_info_financiera with (index=rp_info_financiera_1)
       where usuario      = @s_user
       and   sesion       = @i_ssn
       and   Total        = 'S'
       and   codigo   not in (120, 130, 140)
       group by usuario, sesion, Nivel, codigo,DescN1


       insert into rp_info_financiera with (rowlock)(
       usuario,
       sesion,
       item,
       Nivel,
       codigo,
       DescN1,
       Campo1,
       Valor1,
       Nivel4,
       DescN4,
       t_dif_secuencial,
       t_dif_codigo_var
       )
       select
       usuario,
       sesion,
       1,
       Nivel,
       codigo,
       DescN1,
       'TOTAL',
       sum(cast(Valor as money)),
       'TOTAL',
       'TOTAL',
       max(t_dif_secuencial),
       max(t_dif_codigo_var)
       from rp_info_financiera with (index=rp_info_financiera_1)
       where usuario      = @s_user
       and   sesion       = @i_ssn
       and   codigo      in (120, 130, 140)
       and   item        in (5, 6)
       group by usuario, sesion, Nivel, codigo, DescN1

       insert into rp_info_financiera with (rowlock)(
       usuario,
       sesion,
       item,
       Nivel,
       codigo,
       DescN1,
       Campo1,
       Valor1,
       Nivel4,
       DescN4,
       t_dif_secuencial,
       t_dif_codigo_var
       )
       select
       usuario,
       sesion,
       1,
       Nivel,
       codigo,
       DescN1,
       'TOTAL',
       case
       when codigo=210 then (sum(cast(Valor as money))/7)*30
       else (sum(cast(Valor as money))/(select count(1)
                                     from rp_info_financiera with (index=rp_info_financiera_1)
                                     where usuario    = @s_user
                                     and   sesion     = @i_ssn
                                     and   codigo     = 200
                                     and   item       = 2       ))
       end,
       'TOTAL',
       'TOTAL',
       max(t_dif_secuencial),
       max(t_dif_codigo_var)
       from rp_info_financiera with (index=rp_info_financiera_1)
       where usuario    = @s_user
       and   sesion     = @i_ssn
       and   codigo    in (210, 200)
       and   item       = 2
       group by usuario, sesion, Nivel,codigo,DescN1

    end -- @i_rango_ini = 0

    select
    item,
    codigo,
    Nivel,
    DescN1,
    Nivel2,
    DescN2,
    Nivel3,
    case when  DescN3=' PROVEEDORES CORTO PLAZO' then 'PROVEEDORES'
    when  DescN3=' OBLIGACIONES FINANCIERA CP' then 'OBLIGACIONES FINANCIERAS'
    when  DescN3=' OTROS PASIVOS CP' then 'OTROS PASIVOS'
    else DescN3 end DescN3,
    Nivel4,
    case when  DescN4=' PROVEEDORES CORTO PLAZO' then 'PROVEEDORES'
    when  DescN4=' OBLIGACIONES FINANCIERA CP' then 'OBLIGACIONES FINANCIERAS'
    when  DescN4=' OTROS PASIVOS CP' then 'OTROS PASIVOS'
    else DescN4 end DescN4,
    Sumatoria,
    Descripcion,
    Valor,
    Total,
    id = ROW_NUMBER() OVER(ORDER BY Nivel, codigo,t_dif_secuencial, t_dif_codigo_var),
    t_dif_secuencial ,
    t_dif_codigo_var,
    Campo1,
    Valor1,
    Campo2,
    Valor2,
    Campo3,
    Valor3,
    Campo4,
    Valor4,
    Campo5,
    Valor5,
    Campo6,
    Valor6,
    Campo7,
    Valor7,
    Campo8,
    Valor8
    into #tabla
    from rp_info_financiera with (index=rp_info_financiera_1)
    where usuario    = @s_user
    and   sesion     = @i_ssn
    and   item       = 1
    order by Nivel, codigo, t_dif_secuencial, t_dif_codigo_var asc

    select *
    from #tabla
    where id between @i_rango_ini and @i_rango_fin
    order by Nivel, codigo,t_dif_secuencial, t_dif_codigo_var asc

    select count(item)
    from rp_info_financiera with (index=rp_info_financiera_1)
    where usuario    = @s_user
    and   sesion     = @i_ssn
    and   item       = 1

    if @i_rango_ini = 0 select @i_ssn

    return 0

end  -- reporte de informacion financiera




/* COSTO DE MERCADERIA VENDIDA */
if @i_tipo_reporte = 'CMV' begin

    if @i_intervalo_ini = 0 or @i_limpieza = 'S' begin

       delete rp_costo_merca_vendida with (rowlock)
       from rp_costo_merca_vendida with (index=rp_costo_merca_vendida_1)
       where usuario = @s_user

       if @i_limpieza = 'S' return 0

       select @i_ssn = @s_ssn

       select
       @w_secuencial_finan   = mi_secuencial
       from cr_microempresa
       where mi_tramite = @i_tramite

       select @w_microempresa_finan = @w_secuencial_finan

       insert rp_costo_merca_vendida with (rowlock)
       select
       @s_user,
       @i_ssn,
       ctd_secuencial ,
       ctd_cod_tipo ,
       ctd_microempresa,
       substring(ctd_item ,1,50),
       (select B.valor from cobis..cl_tabla A,
        cobis..cl_catalogo B
        where A.tabla = 'cr_unidades'
        and A.codigo = B.tabla
        and B.estado = 'V'
        and B.codigo = ctd_unidad
       ),
       ctd_cantidad,
       ctd_valor_unit,
       ctd_valor_total,
       ctd_precio,
       isnull(ct_costo_mercancia,0),
       substring(ct_producto,1,50),
       ct_ventas       ,
       ct_part_ventas  ,
       ct_costo        ,
       ct_costo_pond   ,
       ct_precio_unidad ,
       ct_unidad_prod ,
       ct_precio_venta ,
       ct_costo_var     ,
       ct_tipo_costo ,
       row_number() over(order by ctd_cod_tipo),
       case ct_tipo_costo
           when 'P'  then 'PRODUCTOR'
           when 'C'  then 'COMERCIAL'
           when 'N'  then 'CARNICERIA'
           else 'OTRO'
       end
       from cr_costo_tipo_detalle, cr_costo_tipo
       where ctd_cod_tipo     = ct_secuencial
       and   ct_microempresa  = ctd_microempresa
       and   ctd_microempresa = @w_microempresa_finan --17

    end -- @i_intervalo_ini = 0

    select *
    from rp_costo_merca_vendida with (index=rp_costo_merca_vendida_1)
    where usuario       = @s_user
    and   sesion        = @i_ssn
    and   id      between @i_intervalo_ini and @i_intervalo_fin


    if @i_intervalo_ini = 0  begin

       select count(t_tipo_costo)
       from rp_costo_merca_vendida with (index=rp_costo_merca_vendida_1)
       where usuario       = @s_user
       and   sesion        = @i_ssn

       select
       cm_prod_ventas,
       cm_prod_costo,
       cm_com_ventas,
       cm_com_costo,
       cm_carn_ventas,
       cm_carn_costo,
       cm_serv_ventas,
       cm_serv_costo
       from cr_costo_mercancia
       where cm_microempresa = @w_microempresa_finan

       select @i_ssn

       select @w_alianza

    end

   return 0

end


/* vinculacion y actualizacion persona natural */
if @i_tipo_reporte = 'VAP' begin

    --propiedad
    declare @tmp_bienes table
    (
    pr_propiedad        int,
    pr_descripcion      varchar(60),
    pr_valor            money,
    pr_tbien            varchar(6),
    pr_gravada          money,
    pr_gravamen_afavor  varchar(60),
    ciudad              varchar(60),
    pr_placa            varchar(60),
    pr_modelo           varchar(60),
    pr_marca            varchar(60),
    direccion           varchar(60)
    )

    declare @tmp_ingre_egres table
    (
    pl_balance       int null,
    pl_cuenta        int null,
    pl_valor         money null,
    ct_descripcion   varchar(30) null,
    ct_categoria     char(2) null
    )

    select @w_activoypasivos   = pa_char from cobis..cl_parametro
    where pa_nemonico = 'AYPD'
    and   pa_producto = 'MIS'

    if @@rowcount = 0 begin
        select @w_error = 2101084, @w_msg = 'NO EXISTE EL PARAMETRO GENERAL AYPD DEL MODULO MIS'
        goto ERROR_FIN
    end


    select @w_ingresosyegresos = pa_char from cobis..cl_parametro
    where pa_nemonico = 'IYED'
    and   pa_producto = 'MIS'

    if @@rowcount = 0 begin
        select @w_error = 2101084, @w_msg = 'NO EXISTE EL PARAMETRO GENERAL IYED DEL MODULO MIS'
        goto ERROR_FIN
    end


    insert @tmp_ingre_egres
    select
    pl_balance  ,
    pl_cuenta   ,
    isnull(pl_valor,0),
    ct_descripcion,
    ct_categoria
    from   cobis..cl_balance, cobis..cl_plan,   cobis..cl_cuenta
    where  ba_balance     = pl_balance
    and    ba_cliente     = pl_cliente
    and    ct_cuenta      = pl_cuenta
    and    ba_tbalance    = @w_activoypasivos
    and    ba_cliente     = @i_ente
    and    ba_fecha_corte = (select max(ba_fecha_corte)
                             from cobis..cl_balance with(nolock)
                             where ba_cliente  = @i_ente
                             and   ba_tbalance = @w_activoypasivos)

    if @@error <> 0 begin
       select @w_error = 2103001, @w_msg = 'ERROR EN LA INSERCION DE TABLA TEMPORAL', @w_sev = 0
       goto ERROR_FIN
    end

    select
    @w_secuencial_finan = mi_secuencial,
    @w_ventas           = isnull(mi_total_vtas,0),
    @w_ingreso_familiar = isnull(mi_total_ia,0),
    @w_gasto_familiar   =  isnull(mi_total_gf,0),
    @w_costo_venta      =  isnull(mi_total_costo, 0)
    from cob_credito..cr_microempresa with(nolock)
    where mi_tramite = @i_tramite

    select @w_oblig_empresa = isnull(sum(if_total), 0)
    from   cob_credito..cr_inf_financiera
    where  if_microempresa = @w_secuencial_finan
    and    if_codigo   = 260

    select @w_gasto_gral = isnull(sum(if_total), 0)
    from   cob_credito..cr_inf_financiera
    where  if_microempresa = @w_secuencial_finan
    and    if_codigo   in (250, 255, 240)


    select
    @w_ingresos = @w_ingreso_familiar + @w_ventas,
    @w_egresos  = @w_gasto_familiar + @w_costo_venta +  @w_gasto_gral + @w_oblig_empresa

    insert @tmp_ingre_egres
    select
    0,
    0,
    @w_ingresos,
    'TOTAL INGRESOS',
    'Z'

    if @@error <> 0 begin
       select @w_error = 2103001, @w_msg = 'ERROR EN LA INSERCION DE TABLA TEMPORAL', @w_sev = 0
       goto ERROR_FIN
    end

    --JJMD Sarlaft 012

    select @w_cta145 = pa_tinyint from
    cobis..cl_parametro where pa_nemonico = 'C145CC' and  pa_producto = 'CRE'

    select @w_desc145 = ct_descripcion from cobis..cl_cuenta with(nolock)
    where ct_cuenta = @w_cta145

    insert @tmp_ingre_egres
    select
    pl_balance  ,
    pl_cuenta   ,
    case ct_descripcion
        when @w_desc145 then (@w_ventas) --JJMD Sarlaft 012
        else isnull(pl_valor,0)
    end,
    ct_descripcion,
    ct_categoria
    from   cobis..cl_balance,
    cobis..cl_plan,
    cobis..cl_cuenta
    where  ba_balance = pl_balance
    and    ba_cliente = pl_cliente
    and    ct_cuenta  = pl_cuenta
    and    ba_tbalance = @w_ingresosyegresos
    and    ba_cliente = @i_ente
    and    ba_fecha_corte = (select max(ba_fecha_corte) from cobis..cl_balance with(nolock) where ba_cliente = @i_ente and    ba_tbalance = @w_ingresosyegresos)

    if @@error <> 0 begin
       select @w_error = 2103001, @w_msg = 'ERROR EN LA INSERCION DE TABLA TEMPORAL', @w_sev = 0
       goto ERROR_FIN
    end


    update @tmp_ingre_egres
    set pl_valor = @w_egresos
    where ct_categoria = 'E'

    if @@error <> 0 begin
       select @w_error = 2105001, @w_msg = 'ERROR AL OBTENER EL TOTAL DE EGRESOS', @w_sev = 0
       goto ERROR_FIN
    end


    insert @tmp_ingre_egres
    select
    0,
    0,
    sum(pl_valor),
    'TOTAL ACTIVOS',
    'A'
    from @tmp_ingre_egres
    where ct_categoria = 'A'

    if @@error <> 0 begin
       select @w_error = 2103001, @w_msg = 'ERROR EN LA INSERCION DE TABLA TEMPORAL', @w_sev = 0
       goto ERROR_FIN
    end

    --balance
    select
    pl_balance  ,
    pl_cuenta   ,
    pl_valor    ,
    ct_descripcion,
    ct_categoria
    from @tmp_ingre_egres


    insert @tmp_bienes
    select top 3
    isnull(pr_propiedad,0),
    substring(isnull(pr_descripcion,'NA'),1,49),
    isnull(pr_valor,0),
    isnull(pr_tbien,'NA'),
    isnull(pr_gravada,0),
    isnull(pr_gravamen_afavor,'NA'),
    'ciudad' = (select substring(isnull(ci_descripcion,'NA'),1,50)
                from cobis..cl_ciudad
                where ci_ciudad = X.pr_ciudad_inmueble),
    isnull(pr_placa,'NA'),
    isnull(pr_modelo,'NA'),
    isnull(pr_marca,'NA'),
    substring(isnull(pr_direccion_im,'NA'),1,50)
    from cobis..cl_propiedad X
    where pr_persona = @i_ente
    and pr_tbien = 'I'
    order by pr_propiedad desc

    if @@error <> 0 begin
       select @w_error = 2103001, @w_msg = 'ERROR EN LA INSERCION DE TABLA TEMPORAL', @w_sev = 0
       goto ERROR_FIN
    end


    insert @tmp_bienes
    select top 3
    isnull(pr_propiedad,0),
    isnull(substring(pr_descripcion,1,49),'NA'),
    isnull(pr_valor,0),
    isnull(pr_tbien,'NA'),
    isnull(pr_gravada,0),
    isnull(pr_gravamen_afavor,'NA'),
    'ciudad' = (select isnull(ci_descripcion,'NA')
                from cobis..cl_ciudad
                where ci_ciudad = X.pr_ciudad_inmueble),
    isnull(pr_placa,'NA'),
    isnull(pr_modelo,'NA'),
    isnull(pr_marca,'NA'),
    isnull(pr_direccion_im,'NA')
    from cobis..cl_propiedad X
    where pr_persona = @i_ente
    and pr_tbien = 'M'
    order by pr_propiedad desc

    if @@error <> 0 begin
       select @w_error = 2103001, @w_msg = 'ERROR EN LA INSERCION DE TABLA TEMPORAL', @w_sev = 0
       goto ERROR_FIN
    end


    insert @tmp_bienes
    select top 3
    isnull(pr_propiedad,0),
    isnull(substring(pr_descripcion,1,49),'NA'),
    isnull(pr_valor,0),
    'N',--isnull(pr_tbien,'NA'),
    isnull(pr_gravada,0),
    isnull(pr_gravamen_afavor,'NA'),
    'ciudad' = (select isnull(ci_descripcion,'NA')
                from cobis..cl_ciudad
                where ci_ciudad = X.pr_ciudad_inmueble),
    isnull(pr_placa,'NA'),
    isnull(pr_modelo,'NA'),
    isnull(pr_marca,'NA'),
    isnull(pr_direccion_im,'NA')
    from cobis..cl_propiedad X
    where pr_persona = @i_ente
    and pr_tbien = 'O'
    order by pr_propiedad desc

    if @@error <> 0 begin
       select @w_error = 2103001, @w_msg = 'ERROR EN LA INSERCION DE TABLA TEMPORAL', @w_sev = 0
       goto ERROR_FIN
    end


    select
    pr_propiedad,
    pr_descripcion,
    pr_valor,
    pr_tbien,
    pr_gravada,
    pr_gravamen_afavor,
   ciudad,
    pr_placa,
    pr_modelo,
    pr_marca,
    direccion
    from @tmp_bienes

    -- referencias
    select top 15
    substring(rp_nombre,1,50),
    substring(rp_p_apellido,1,50),
    substring(rp_s_apellido,1,50),
    substring(rp_direccion,1,50),
    rp_telefono_d,
    rp_telefono_e,
    'Parentesco' = (select c.valor
                    from cobis..cl_tabla t, cobis..cl_catalogo c
                    where t.tabla = 'cl_parentesco'
                    and t.codigo = c.tabla
                    and c.codigo = rp_parentesco),
    rp_referencia
    from cobis..cl_ref_personal
    where rp_persona = @i_ente

    --OTROSINGRESOS
    if @i_codeudor = 'S'
    begin
        declare @tmp_otros_ing table
        (
        tmp_secuencial smallint,
        tmp_cadena     descripcion,
        tmp_money      money
        )
        insert into @tmp_otros_ing
        select
        dif_secuencial,
        dif_cadena,
        dif_money
        from
        cr_det_inf_financiera with(nolock),
        cr_det_est_financiero with(nolock)
        where def_codigo       = dif_codigo_var
        and dif_inf_fin      = def_est_fin
        and dif_microempresa = @w_secuencial_finan
        and dif_inf_fin = 280
        and dif_tipo = 'M'
        order by dif_secuencial,
        dif_codigo_var

        update @tmp_otros_ing set tmp_cadena = dif_cadena
        from cr_det_inf_financiera
        where dif_microempresa = @w_secuencial_finan
        and dif_inf_fin = 280
        and dif_cadena is not null
        and   dif_secuencial = tmp_secuencial


        select  sum(isnull(tmp_money,0))
        from @tmp_otros_ing
        group by tmp_cadena

    end


    select
    'TIPO RELACION' = (select valor  from cobis..cl_catalogo a, cobis..cl_tabla b where b.tabla='cl_rel_inter' and a.codigo=ri_tipo_relacion and b.codigo=a.tabla),
    'ENTIDAD'       = ri_institucion,
    'No. PRODUCTO'  = ri_num_producto,
    'MONTO       '  = ri_monto,
    'MONEDA      '  = (select valor  from cobis..cl_catalogo a, cobis..cl_tabla b where b.tabla='cl_moneda' and a.codigo=ri_moneda and b.codigo=a.tabla),
    'CIUDAD      '  = ri_ciudad,
    'PAIS        '  = (select pa_descripcion from cobis..cl_pais where pa_pais = ri_pais),
    'TRAMITE     '  = @i_tramite
    from cobis..cl_relacion_inter
    where ri_ente  =  @i_ente


    select
    @w_en_recurso_pub= en_recurso_pub,
    @w_en_influencia = en_influencia,
    @w_en_persona_pub= en_persona_pub,
    @w_en_victima    = en_victima,
    @w_en_relacint   = en_relacint,
    @w_pregunta1     = '1.- Realiza usted operaciones en moneda extranjera?',
    @w_pregunta2     = '2.- Maneja recursos publicos?',
    @w_pregunta3     = '3.- Las decisiones de su cargo influyen en la politica o impactan en la sociedad?',
    @w_pregunta4     = '4.- La sociedad o los medios lo identifican como un personaje publico?',
    @w_pregunta5     = '5.- Ha sido victima de hechos violentos?'
    from   cobis..cl_ente X
    where  en_ente = @i_ente


    select
    @w_pregunta1,
    @w_en_relacint,
    @w_pregunta2,
    @w_en_recurso_pub,
    @w_pregunta3,
    @w_en_influencia,
    @w_pregunta4,
    @w_en_persona_pub,
    @w_pregunta5,
    @w_en_victima


    select top 1
    ag_fecha_captura_dom,
    (select fu_nombre
        from cobis..cl_funcionario,
        cobis..cc_oficial
        where fu_funcionario = oc_funcionario
        and oc_oficial = ag_ejecutivo_dom),
    ag_concepto_visita_dom
    from cr_agenda with(nolock)
    where ag_ente = @i_ente
    order by ag_fecha_captura_dom desc, ag_fecha_visita desc

    select top 1
    ag_fecha_captura_neg,
    (select fu_nombre
        from cobis..cl_funcionario,
        cobis..cc_oficial
        where fu_funcionario = oc_funcionario
        and oc_oficial = ag_ejecutivo_neg),
    ag_concepto_visita_neg
    from cr_agenda with(nolock)
    where ag_ente = @i_ente
    order by ag_fecha_captura_neg desc, ag_fecha_visita desc

    select @w_subtipo = en_subtipo
    from cobis..cl_ente
    where en_ente = @i_ente

    select @w_subtipo

    return 0
end
---------------vinculacion codeudor



--------------- vinculacion y actualizacion persona natural ini
if @i_tipo_reporte = 'VCO'
begin

    create table #tmp_ingre_egresc
    (
    pl_balance       int null,
    pl_cuenta        int null,
    pl_valor         money null,
    ct_descripcion   varchar(30) null,
    ct_categoria     char(2) null
    )

    insert #tmp_ingre_egresc
    select
    pl_balance  ,
    pl_cuenta   ,
    isnull(pl_valor,0),
    ct_descripcion,
    ct_categoria
    from   cobis..cl_balance,
       cobis..cl_plan,
       cobis..cl_cuenta
    where  ba_balance = pl_balance
    and    ba_cliente = pl_cliente
    and    ct_cuenta  = pl_cuenta
    and    ba_tbalance = '003'
    and    ba_cliente = @i_ente
    and    ba_fecha_corte = (select max(ba_fecha_corte) from cobis..cl_balance where ba_cliente = @i_ente and ba_tbalance = '003')

    insert #tmp_ingre_egresc
    select
    pl_balance  ,
    pl_cuenta   ,
    isnull(pl_valor,0),
    ct_descripcion,
    ct_categoria
    from   cobis..cl_balance,
       cobis..cl_plan,
       cobis..cl_cuenta
    where  ba_balance = pl_balance
    and    ba_cliente = pl_cliente
    and    ct_cuenta  = pl_cuenta
    and    ba_tbalance = '004'
    and    ba_cliente = @i_ente
    and    ba_fecha_corte = (select max(ba_fecha_corte) from cobis..cl_balance where ba_cliente = @i_ente and    ba_tbalance = '004')

    insert #tmp_ingre_egresc
    select 0,0, isnull(sum(pl_valor),0), 'TOTAL ACTIVOS', 'A'
    from #tmp_ingre_egresc
    where ct_categoria = 'A'

    --balance
    select    pl_balance  ,
    pl_cuenta   ,
    pl_valor    ,
    ct_descripcion,
    ct_categoria
    from #tmp_ingre_egresc

    --propiedad

    declare @tmp_bienesc table
    (
    pr_propiedad     int,
    pr_descripcion  varchar(60),
    pr_valor        money,
    pr_tbien         varchar(6),
    pr_gravada        money,
    pr_gravamen_afavor varchar(60),
    ciudad  varchar(60),
    pr_placa   varchar(60),
    pr_modelo   varchar(60),
    pr_marca    varchar(60),
    direccion varchar(60)
    )

    insert @tmp_bienes
    select top 3
    isnull(pr_propiedad,0),
    isnull(substring(pr_descripcion,1,49),'NA'),
    isnull(pr_valor,0),
    isnull(pr_tbien,'NA'),
    isnull(pr_gravada,0),
    isnull(pr_gravamen_afavor,'NA'),
    'ciudad' = (select isnull(ci_descripcion,'NA')
            from cobis..cl_ciudad
            where ci_ciudad = X.pr_ciudad_inmueble),
    isnull(pr_placa,'NA'),
    isnull(pr_modelo,'NA'),
    isnull(pr_marca,'NA'),
    isnull(pr_direccion_im,'NA')
    from cobis..cl_propiedad X
    where pr_persona = @i_ente
    and pr_tbien = 'I'
    order by pr_propiedad desc


    insert @tmp_bienes
    select top 3
    isnull(pr_propiedad,0),
    isnull(substring(pr_descripcion,1,49),'NA'),
    isnull(pr_valor,0),
    isnull(pr_tbien,'NA'),
    isnull(pr_gravada,0),
    isnull(pr_gravamen_afavor,'NA'),
    'ciudad' = (select isnull(ci_descripcion,'NA')
            from cobis..cl_ciudad
            where ci_ciudad = X.pr_ciudad_inmueble),
    isnull(pr_placa,'NA'),
    isnull(pr_modelo,'NA'),
    isnull(pr_marca,'NA'),
    isnull(pr_direccion_im,'NA')
    from cobis..cl_propiedad X
    where pr_persona = @i_ente
    and pr_tbien = 'M'
    order by pr_propiedad desc


    insert @tmp_bienes
    select top 3
    isnull(pr_propiedad,0),
    isnull(substring(pr_descripcion,1,49),'NA'),
    isnull(pr_valor,0),
    'N',--isnull(pr_tbien,'NA'),
    isnull(pr_gravada,0),
    isnull(pr_gravamen_afavor,'NA'),
    'ciudad' = (select isnull(ci_descripcion,'NA')
            from cobis..cl_ciudad
            where ci_ciudad = X.pr_ciudad_inmueble),
    isnull(pr_placa,'NA'),
  isnull(pr_modelo,'NA'),
    isnull(pr_marca,'NA'),
    isnull(pr_direccion_im,'NA')
    from cobis..cl_propiedad X
    where pr_persona = @i_ente
    and pr_tbien = 'O'
    order by pr_propiedad desc

    select * from @tmp_bienes

    -- referencias
    select top 10
    substring(rp_nombre,1,50),
    substring(rp_p_apellido,1,50),
    substring(rp_s_apellido,1,50),
    substring(rp_direccion,1,50),
    rp_telefono_d,
    rp_telefono_e,
    'Parentesco' = (select c.valor
                    from cobis..cl_tabla t,
                         cobis..cl_catalogo c
                    where t.tabla = 'cl_parentesco'
                    and t.codigo = c.tabla
                    and c.codigo = rp_parentesco),
    rp_referencia
    from cobis..cl_ref_personal
    where rp_persona = @i_ente

    --OTROSINGRESOS
    if @i_codeudor = 'S'
    begin
        select @w_oi_valorcon = oi_valor
        from   cobis..cl_otros_ingresos
        where  oi_cod_descripcion in ('CON')
        and    oi_ente = @i_ente

        select @w_oi_valorhij = oi_valor
        from   cobis..cl_otros_ingresos
        where  oi_cod_descripcion in ('HIJ')
        and    oi_ente = @i_ente

        select @w_oi_valorpen = oi_valor
        from   cobis..cl_otros_ingresos
        where  oi_cod_descripcion in ('PEN')
        and    oi_ente = @i_ente

        select @w_oi_valorarr = oi_valor
        from   cobis..cl_otros_ingresos
        where  oi_cod_descripcion in ('ARR')
        and    oi_ente = @i_ente

        select @w_oi_valorint = oi_valor
        from   cobis..cl_otros_ingresos
        where  oi_cod_descripcion in ('INT')
        and    oi_ente = @i_ente

        select @w_oi_valorsue = oi_valor
        from   cobis..cl_otros_ingresos
        where  oi_cod_descripcion in ('SUE')
        and    oi_ente = @i_ente

        select @w_oi_valorotr = oi_valor
        from   cobis..cl_otros_ingresos
        where  oi_cod_descripcion in ('OTR')
        and    oi_ente = @i_ente

        select isnull(@w_oi_valorcon,0),
        isnull(@w_oi_valorhij,0),
        isnull(@w_oi_valorpen,0),
        isnull(@w_oi_valorarr,0),
        isnull(@w_oi_valorint,0),
        isnull(@w_oi_valorsue,0),
        isnull(@w_oi_valorotr,0)
    end

    select
    'TIPO RELACION' = (select valor  from cobis..cl_catalogo a, cobis..cl_tabla b where b.tabla='cl_rel_inter' and a.codigo=ri_tipo_relacion and b.codigo=a.tabla),
    'ENTIDAD'       = ri_institucion,
    'No. PRODUCTO'  = ri_num_producto,
    'MONTO       '  = ri_monto,
    'MONEDA      '  = (select valor  from cobis..cl_catalogo a, cobis..cl_tabla b where b.tabla='cl_moneda' and a.codigo=ri_moneda and b.codigo=a.tabla),
    'CIUDAD      '  = ri_ciudad,
    'PAIS        '  = (select pa_descripcion from cobis..cl_pais where pa_pais = ri_pais),
    'TRAMITE     '  = @i_tramite
    from cobis..cl_relacion_inter
    where ri_ente  =  @i_ente

    select
    @w_en_recurso_pub= en_recurso_pub,
    @w_en_influencia = en_influencia,
    @w_en_persona_pub= en_persona_pub,
    @w_en_victima    = en_victima,
    @w_en_relacint   = en_relacint,
    @w_pregunta1     = '1.- Realiza usted operaciones en moneda extranjera?',
    @w_pregunta2     = '2.- Maneja recursos publicos?',
    @w_pregunta3     = '3.- Las decisiones de su cargo influyen en la politica o impactan en la sociedad?',
    @w_pregunta4     = '4.- La sociedad o los medios lo identifican como un personaje publico?',
    @w_pregunta5     = '5.- Ha sido victima de hechos violentos?'
    from   cobis..cl_ente X
    where  en_ente = @i_ente

    select
    @w_pregunta1,
    @w_en_relacint,
    @w_pregunta2,
    @w_en_recurso_pub,
    @w_pregunta3,
    @w_en_influencia,
    @w_pregunta4,
    @w_en_persona_pub,
    @w_pregunta5,
    @w_en_victima

    return 0


end

---------------  vinculacion y actualizacion persona natural fin

-------------declaracion jurada
if @i_tipo_reporte = 'DJU'
begin

    select @w_tdr = pa_char
    from   cobis..cl_parametro
    where  pa_nemonico = 'TDR'

    if @@rowcount = 0
    begin
        -- No existe parametro indicado
        if @@error <> 0 begin
            select @w_error = 2101084
            goto ERROR_FIN
        end
    end

    exec @w_error = cobis..sp_datos_cliente
    @i_tipo          = @w_tdr,
    @i_ente          = @i_ente,
    @o_descripcion   = @w_descripcion out


    if @@error <> 0 begin
       select @w_msg = 'Error en la ejecucion del sp_datos_cliente.', @w_sev = 0
       goto ERROR_FIN
    end

    select  @w_secuencial_finan   = mi_secuencial
    from cr_microempresa
    where mi_tramite = @i_tramite

    if @@rowcount = 0  begin   --OAUM: SE BUSCA LA OPERACION PADRE PARA OPERACIONES HIJA_FNG QUE NO MUESTRAN DEC. JURADA
    
       select @w_padre = ph_banco_padre 
       from cob_conta_super..sb_op_reest_padre_hija  
       where ph_banco_hija = @i_banco
       
       select @w_tramite = tr_tramite 
       from cob_credito..cr_tramite  
       where tr_numero_op_banco = @w_padre
       and tr_tipo = 'O'
       
       select  @w_secuencial_finan   = mi_secuencial
       from cr_microempresa
       where mi_tramite = @w_tramite 
    
    end
  
    if @w_secuencial_finan is null or @w_secuencial_finan  = 0
    begin
       ---SE busca el tramte del cupopor que la Utilizacion
       ---Tiene los datos realcioador
           
		select @w_tramite = tr_tramite 
		from cob_credito..cr_tramite,
		     cob_credito..cr_linea
		where tr_cliente = @i_ente
		and tr_tipo = 'C'
		and tr_tramite = li_tramite
		and li_num_banco = @w_lin_credito
		and tr_estado ='A'
		and li_numero = tr_linea_credito

	    select  @w_secuencial_finan   = mi_secuencial
        from cr_microempresa
        where mi_tramite = @w_tramite 
       
    end

    select @w_microempresa_finan = @w_secuencial_finan
    if     @i_intervalo_ini_j is null
            set @i_intervalo_ini_j = 0
    if     @i_intervalo_fin_j is null
            set @i_intervalo_fin_j = 8 --15

    declare @tmp_dec_jurada table
    (
    t_tipo_bien     int         null,
    t_tipo_activo   int         null,
    t_descripcion   varchar(80) null,
    t_total_bien    money       null,
    t_titulo        varchar(80) null,
    t_ente          int         null,
    t_i_tipo        varchar(10) null,
    t_ced_ruc       numero      null,
    t_nombre        varchar(50) null,
    t_papellido     varchar(50) null,
    t_sapellido     varchar(50) null,
    t_direccion     varchar(80) null,
    t_nombre2       varchar(60) null,
    t_tipo_id2      varchar(10) null,
    t_ced_ruc2      numero      null,
    t_desciuexp     varchar(40) null,
    t_desciuexp2     varchar(40) null,
    t_des_activo    varchar(24) null,
    t_cantidad      int         null,
    id              int         identity
    )

    insert @tmp_dec_jurada
    (t_tipo_bien ,
    t_tipo_activo,
    t_descripcion,
    t_total_bien,
    t_titulo,
    t_ente,
    t_i_tipo,
    t_ced_ruc,
    t_nombre,
    t_papellido,
    t_sapellido,
    t_direccion,
    t_nombre2,
    t_tipo_id2,
    t_ced_ruc2,
    t_desciuexp,
    t_desciuexp2,
    t_des_activo,
    t_cantidad)
    select
    dj_tipo_bien ,
    dj_tipo_activo ,
    dj_descripcion ,
    dj_total_bien ,
    case dj_tipo_bien
       when 1  then 'Tipo Activo:  BIENES DEL HOGAR  (Al 70% Del Valor Comercial) '
       when 2  then 'Tipo Activo:  ACTIVOS DEL NEGOCIO  (Al 70% Del Valor Comercial) '
       else 'OTRO'
    end,
    @i_ente,
    @w_tipoced   ,
    @w_cedruc    ,
    @w_nombre    ,
    @w_papellido ,
    @w_sapellido ,
    @w_descripcion,
    '',
    '',
    '',
    @w_desciuexp,
    '',
    (
     select c.valor
     from cobis..cl_tabla t,
     cobis..cl_catalogo c
     where t.tabla = 'cr_tipo_activo'
     and t.codigo = c.tabla
and c.codigo = X.dj_tipo_activo
    ),
    dj_cantidad
    from cr_dec_jurada X
    where dj_codigo_mic  = @w_microempresa_finan
    order by dj_secuencial


    select isnull(t_tipo_bien,0),
    isnull(t_tipo_activo,0),
    substring(ltrim(rtrim(t_descripcion)),1,49),
    isnull(t_total_bien,0),
    t_titulo,
    isnull(t_ente,0),
    t_i_tipo,
    t_ced_ruc,
    substring(t_nombre,1,50),
    substring(t_papellido,1,50),
    substring(t_sapellido,1,50),
    id,
    substring(t_direccion,1,50),
    substring(t_nombre2,1,49),
    t_tipo_id2,
    t_ced_ruc2,
    substring(t_desciuexp,1,49),
    substring(t_desciuexp2,1,49),
    substring(ltrim(rtrim(t_des_activo)),1,23),
    t_cantidad
    from @tmp_dec_jurada
    where id between @i_intervalo_ini_j and @i_intervalo_fin_j

    select count(1)
    from @tmp_dec_jurada

    select @w_subtipo = en_subtipo
    from cobis..cl_ente
    where en_ente = @i_ente

    select @w_subtipo

    return 0
end
-------------declaracion jurada fin

-------------Inicio 17/Mar/2009 JJMD reporte credito rural
if @i_tipo_reporte = 'RCR'
begin

    --Obteniendo el secuencial de la microempresa seg·n el trîmite.
    SELECT  @w_secuencial_finan   = mi_secuencial
    FROM cr_microempresa
    WHERE mi_tramite = @i_tramite

    --Obteniendo el n·mero de cuenta de productos rurales de la tabla de parîmetros generales
    SELECT @w_cuenta = pa_int
    FROM cobis..cl_parametro
    WHERE pa_nemonico = 'CCVAR'
    AND pa_producto = 'CRE'


    --Obteniendo la moneda nacional
    select @w_mon_nacional = pa_tinyint
    from cobis..cl_parametro
    where pa_producto = 'ADM'
    and   pa_nemonico = 'MLO'

    EXEC cob_cartera..sp_decimales
    @i_moneda = @w_mon_nacional,
    @o_decimales = @w_decimales out

    if @@error <> 0 begin
        select @w_error = 720305, @w_msg = 'Error grave en ejecucion de sp_decimales', @w_sev = 0
        goto ERROR_FIN
    end


    SELECT  distinct(i.dif_secuencial),
    --es igual a la celda -descripci¾n
    'ACTIVIDAD'  = (SELECT substring(dif_cadena,1,50) FROM cr_det_inf_financiera B
                        WHERE  B.dif_codigo_var = 2
                        AND    B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        ),
    --es el resultado de la operaci¾n de las celdas: ((valor venta*30)/ciclos actividad)
    'VENTASMES'  = round(isnull((SELECT dif_money FROM cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 16
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        ), 0), @w_decimales),
    --es igual a la celda ûciclos actividad
    'CICLO' = (SELECT dif_entero FROM cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 9
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        ),
    --es el resultado de la operaci¾n de la celdas: ((costo por unidad*producci¾n*30)/ciclos actividad)
    'COSTOMES' = round(isnull(((SELECT dif_money FROM   cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 13
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        )*(SELECT dif_entero FROM cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 10
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        )*30/(SELECT dif_entero FROM cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 9
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        )), 0), @w_decimales),
    --es igual a la celda û porcentaje de terminaci¾n
    'PORCTERMINADO' = (SELECT isnull(dif_entero,0) FROM cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 12
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        ),
    --es igual a la celda ûproducci¾n
    'QPROD' = (SELECT dif_entero FROM cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 10
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        ),
    'FECHAINICIO' = (SELECT CONVERT(VARCHAR(20),dif_fecha, 106)  FROM   cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 7
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        ),
    'FECHAFIN' = (SELECT CONVERT(VARCHAR(20),dif_fecha, 106)  FROM   cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 8
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        ),
    --es el resultado de la operaci¾n de las celdas: (costo por unidad*producci¾n*porcentaje de terminaci¾n)
    'ACTIVOS' = round(isnull((SELECT dif_money FROM cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 13
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        )*(SELECT dif_entero FROM cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 10
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        )*(SELECT convert(float,dif_entero)/convert(float,100) FROM cr_det_inf_financiera B
                        WHERE B.dif_codigo_var = 12
                        AND   B.dif_inf_fin = @w_cuenta
                        AND   B.dif_microempresa = @w_secuencial_finan
                        AND B.dif_secuencial = i.dif_secuencial
                        ), 0), @w_decimales)


    FROM  cr_det_est_financiero e,  cr_det_inf_financiera i
    WHERE e.def_codigo  = i.dif_codigo_var
    AND   e.def_est_fin = i.dif_inf_fin
    AND   e.def_est_fin = @w_cuenta
    AND   i.dif_microempresa = @w_secuencial_finan

    return 0
end




select
@w_tipoced            = en_tipo_ced,
@w_cedruc             = en_ced_ruc,
@w_nombre             = en_nombre,
@w_papellido          = p_p_apellido,
@w_sapellido          = p_s_apellido,
@w_ciudadexp          = p_lugar_doc,
@w_fecha_exp          = convert(varchar(10),p_fecha_emision,@i_formato_f),
@w_ofiprod            = en_oficina_prod,
@w_fecha_nac          = convert(varchar(10),p_fecha_nac,@i_formato_f),
@w_fecha_nac_datetime = p_fecha_nac, --JJMD Inc. 1055
@w_ciudadnac          = p_ciudad_nac,
@w_genero             = p_sexo,
@w_ocupacion          = en_concordato,
@w_ecivil             = p_estado_civil,
@w_tvivienda      = p_tipo_vivienda,
@w_nivelest           = p_nivel_estudio,
@w_fch_neg            = convert(varchar(20),en_fecha_negocio,@i_formato_f),
@w_en_estrato         = en_estrato,
@w_p_num_cargas       = p_num_cargas,
@w_profesion          = p_profesion,
@w_hijos              = p_num_hijos,
@w_en_recurso_pub     = en_recurso_pub,
@w_en_influencia      = en_influencia,
@w_en_persona_pub     = en_persona_pub,
@w_en_victima         = en_victima,
@w_en_relacint        = en_relacint,
@w_en_actividad       = en_actividad,
@w_subtipo            = en_subtipo
from   cobis..cl_ente X
where  en_ente = @i_ente

if @@rowcount = 0 begin
   select @w_error = 101129, @w_msg = 'No existe el cliente indicado', @w_sev = 0
   goto ERROR_FIN
end


/* BUCAR INFORMACION REPRESENTANTE LEGAL SI ES EL CASO DE JURIDICO */

if @w_subtipo = 'C' begin

   select @w_re_relacion = re_relacion
   from cobis..cl_relacion
   where re_descripcion like '%REPRESENTANTE LEGAL%'

   if @w_re_relacion is null begin
      select @w_error = 101129, @w_msg = 'No existe Codigo para Representante Legal en cl_relacion', @w_sev = 0
      goto ERROR_FIN
   end

   select @w_cliente_rl = in_ente_i
   from cobis..cl_instancia
   where in_relacion = @w_re_relacion
   and   in_lado     = 'I'
   and   in_ente_d   = @i_ente

   select @w_tdn = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'TDN'

   select
   @w_nombre_com_rl = en_nombre  + ' ' + p_p_apellido + ' ' + p_s_apellido,
   @w_cedula_rl     = en_ced_ruc,
   @w_tipo_doc_rl   = en_tipo_ced,
   @w_ciudad_exp_rl = (select ci_descripcion from cobis..cl_ciudad where ci_ciudad = x.p_lugar_doc)
   from cobis..cl_ente x
   where en_ente = @w_cliente_rl

   if @w_cliente_rl is null  begin
      select @w_error = 101129, @w_msg = 'No existe el Representante Legal ', @w_sev = 0
      goto ERROR_FIN
   end

   exec cobis..sp_datos_cliente
   @i_tipo          = @w_tdn,
   @i_ente          = @w_cliente_rl,
   @o_descripcion   = @w_dir_rl out,
   @o_desciudad     = @w_ciudad_dir_rl out,
   @o_desprovincia  = @w_depto_dir_rl out

end

/* BUSCAR LA DESCRIPCION DE LA OCUPACION DEL CLIENTE */
select @w_descocupa = c.valor
from   cobis..cl_catalogo c, cobis..cl_tabla t
where  c.tabla  = t.codigo
and    t.tabla  = 'cl_tipo_empleo'
and    c.codigo = @w_ocupacion

if @@rowcount = 0 select @w_descocupa = 'SIN DESCRIPCION'

/* BUSCAR LA DESCRIPCION DE LA OCUPACION DEL CLIENTE */
select @w_descecivil = c.valor
from   cobis..cl_catalogo c, cobis..cl_tabla t
where  c.tabla = t.codigo
and    t.tabla = 'cl_ecivil'
and    c.codigo = @w_ecivil

if @@rowcount = 0 select @w_descecivil  = 'SIN DESCRIPCION'

/* BUSCAR LA DESCRIPCION DEL TIPO DE VIVIDENDA */
select @w_desctviv =  c.valor
from   cobis..cl_catalogo c, cobis..cl_tabla t
where  c.tabla = t.codigo
and    t.tabla = 'cl_tipo_vivienda'
and    c.codigo = @w_tvivienda

if @@rowcount = 0 select @w_desctviv  = 'SIN DESCRIPCION'

/* BUSCAR LA DESCRIPCION DEL TIPO DE VIVIDENDA */
select @w_descnest = c.valor
from   cobis..cl_catalogo c, cobis..cl_tabla t
where  c.tabla = t.codigo
and    t.tabla = 'cl_nivel_estudio'
and    c.codigo = @w_nivelest

if @@rowcount = 0 select @w_descnest  = 'SIN DESCRIPCION'


/* BUSCAR LA DESCRIPCION DE LA PROFESION */
select @w_desc_profesion = c.valor
from   cobis..cl_catalogo c, cobis..cl_tabla t
where  c.tabla = t.codigo
and    t.tabla = 'cl_profesion'
and    c.codigo = @w_profesion

if @@rowcount = 0 select @w_desc_profesion  = 'SIN DESCRIPCION'

/* BUSCAR LA DESCRIPCION DE LA ACTIVIDAD */
select @w_ciiu = c.valor
from   cobis..cl_catalogo c, cobis..cl_tabla t
where  c.tabla = t.codigo
and    t.tabla = 'cl_actividad'
and    c.codigo = @w_en_actividad

if @@rowcount = 0 select @w_ciiu = 'SIN DESCRIPCION'

select @w_actividad_mo = mo_subtipo_mo
from cobis..cl_mercado_objetivo_cliente
where mo_ente = @i_ente

select @w_des_actividad_mo = b.valor
from cobis..cl_tabla a, cobis..cl_catalogo b
where a.tabla  = 'cl_subtipo_mercado'
and   a.codigo = b.tabla
and   b.codigo = @w_actividad_mo

if @@rowcount = 0 select @w_des_actividad_mo = 'SIN DESCRIPCION'

/* BUSCAR LA DESCRIPCION DEL TIPO DE DOCUMENTO */
select @w_des_tipo = c.valor
from   cobis..cl_catalogo c, cobis..cl_tabla t
where  c.tabla = t.codigo
and    t.tabla = 'cl_tipo_documento'
and    c.codigo = @w_tipoced

if @@rowcount = 0 select @w_des_tipo = 'SIN DESCRIPCION'


/* BUSCAR LA DESCRIPCION DE LA CIUDAD DEL EXPEDIENTE */
select @w_desciuexp = ci_descripcion
from cobis..cl_ciudad
where ci_ciudad = @w_ciudadexp

if @@rowcount = 0 select @w_desciuexp = 'SIN DESCRIPCION'

/* BUSCAR LA DESCRIPCION DE LA CIUDAD DE NACIMIENTO */
select @w_desciunac = ci_descripcion
from cobis..cl_ciudad
where ci_ciudad = @w_ciudadnac

if @@rowcount = 0 select @w_desciunac = 'SIN DESCRIPCION'

select
@w_des_depexp  = (select substring(pv_descripcion,1,49)
                  from cobis..cl_provincia
                  where pv_provincia = C.ci_provincia),
@w_des_paisexp = (select substring(pa_descripcion,1,49)
                  from cobis..cl_pais
                  where pa_pais = C.ci_pais)
from cobis..cl_ciudad C
where ci_ciudad = @w_ciudadnac

if @w_des_paisexp is null begin

   select
   @w_des_paisexp = (select substring(pa_descripcion,1,49)
                     from cobis..cl_pais
                     where pa_pais = E.en_pais)
   from cobis..cl_ente E
   where en_ente = @i_ente

end




/* INFORMACION DEL CONYUGE DEL CLIENTE */
select
@w_coy_papellido      = hi_papellido,
@w_coy_sapellido      = hi_sapellido,
@w_coy_nombres        = hi_nombre,
@w_hi_ente            = hi_ente,
@w_coy_tipoced        = hi_tipo_doc,
@w_coy_cedruc         = hi_documento,
@w_coy_ciudadexp      = ' ',
@w_coy_desciuexp      = ' ',
@w_coy_fecha_exp      = ' ',
@w_coy_empresa        = hi_empresa,
@w_coy_telefono       = hi_telefono,
@w_coy_direccion      = ' ',
@w_coy_descripcion    = ' '
from cobis..cl_hijos
where hi_ente = @i_ente
and   hi_tipo =  'C'

if @@rowcount <> 0 begin

    select
    @w_coy_ciudadexp = p_lugar_doc,
    @w_coy_desciuexp = (select ci_descripcion from cobis..cl_ciudad where ci_ciudad = X.p_lugar_doc),
    @w_coy_fecha_exp = convert(varchar(10),p_fecha_emision,@i_formato_f),
    @w_coy_direccion = en_direccion
    from   cobis..cl_ente X
    where en_ced_ruc = @w_coy_cedruc

end else begin

    select
    @w_coy_papellido         = ' ',
    @w_coy_sapellido         = ' ',
    @w_coy_nombres           = ' ',
    @w_hi_ente               = ' ',
    @w_coy_tipoced           = ' ',
    @w_coy_cedruc            = ' ',
    @w_coy_ciudadexp         = ' ',
    @w_coy_desciuexp         = ' ',
    @w_coy_fecha_exp         = ' ',
    @w_coy_empresa           = ' ',
    @w_coy_telefono          = ' ',
    @w_coy_direccion         = ' ',
    @w_coy_descripcion       = ' '
end



-----------Microempresa ini

select
@w_secuencial           = mi_secuencial,
@w_nit                  = isnull(mi_identificacion,0),
@w_nombre_micro         = substring(mi_nombre,1,49),
@w_descripcion_micro    = mi_descripcion,
@w_num_trabaj_remu      = isnull(mi_num_trabaj_remu,0),
@w_num_trabaj_no_remu   = isnull(mi_num_trabaj_no_remu,0),
@w_experiencia          = isnull(mi_experiencia,0),
@w_experiencia_fecha    = mi_experiencia_fecha,
@w_tiempo_propie_negoc  = datediff(mm, mi_antiguedad, getdate()),
@w_local                = mi_local,
@w_nombre_arrendador    = substring(mi_arrendador,1,50),
@w_telefono_arrenda     = mi_telefono,
@w_refer_arrendador     = mi_referencias,
@w_tipo_empresa         = mi_tipo_empresa,
@w_barrio_micro         = mi_barrio,
@w_ciudad_micro         = mi_ciudad,
@w_departamento         = mi_departamento
from cr_microempresa
where  mi_tramite  = @i_tramite

select
@w_numero_empleados = @w_num_trabaj_remu + @w_num_trabaj_no_remu ,
@w_actividad        = @w_desc_profesion

select @w_descr_local =  valor
from cobis..cl_catalogo c, cobis..cl_tabla t
where c.tabla = t.codigo
and t.tabla   = 'cr_tipo_local'
and c.codigo  = @w_local
and c.estado  ='V'


--ciudad, pais y depto de nacimiento

select @w_desc_barrio_micro = substring(pq_descripcion,1,49)
from cobis..cl_parroquia
where pq_parroquia = @w_barrio_micro
and   pq_ciudad    = @w_ciudad_micro

select @w_desc_dep_micro = substring(pv_descripcion,1,49)
from cobis..cl_provincia
where pv_provincia = @w_departamento


 --origen de fondos
select @w_fondos = of_origen_fondos
from cobis..cl_origen_fondos,
cobis..cl_ente
where of_ente = en_ente
and   of_ente = @i_ente

select @w_dir_trabajo   = substring(di_descripcion,1,70),
@w_cod_direccion = di_direccion
from cobis..cl_direccion
where di_ente      = @i_ente
and   di_tipo      = '003'

select @w_tel_trabajo = ltrim(rtrim(te_valor))
from cobis..cl_telefono, cobis..cl_tabla a, cobis..cl_catalogo b
where te_ente          = @i_ente
and   a.tabla          = 'cl_ttelefono'
and   a.codigo         = b.tabla
and   te_tipo_telefono = b.codigo
and   b.codigo         = 'D'

select @w_fax_trabajo = ltrim(rtrim(te_valor))
from cobis..cl_telefono, cobis..cl_tabla a, cobis..cl_catalogo b
where te_ente          = @i_ente
and   a.tabla          = 'cl_ttelefono'
and   a.codigo         = b.tabla
and   te_tipo_telefono = b.codigo
and   b.codigo         = 'F'


---Datos del arrendador del tipo de vivienda

select top 1
@w_ref_vienda = isnull(rp_referencia,0),
@w_nom_vienda = substring(rp_nombre,1,49),
@w_tel_vienda = rp_telefono_d
from cobis..cl_ref_personal
where rp_persona  = @i_ente
and rp_parentesco = @w_pa_vivienda
order by rp_referencia desc

--Datos del trabajo
select
@w_trabajo = max(tr_trabajo)
from cobis..cl_trabajo
where  tr_persona = @i_ente

select
@w_empresa = substring(tr_empresa,1,50),
@w_sueldo = isnull(tr_sueldo,0),
@w_fec_ingreso = convert(varchar(10),tr_fecha_ingreso,@i_formato_f),
@w_cargo = substring(tr_cargo,1,50),
@w_contrato = (select c.valor
               from cobis..cl_catalogo c,
               cobis..cl_tabla t
               where c.tabla = t.codigo
               and t.tabla = 'cl_tipo_contrato'
               and c.codigo = X.tr_tipo_empleo)
from cobis..cl_trabajo X
where  tr_persona = @i_ente
and tr_trabajo = @w_trabajo

select @w_tipo_tramite = tr_tipo_credito
from cob_credito..cr_tramite
where tr_tramite = @i_tramite
and tr_cliente = @i_ente


select
@w_monto      = tr_monto,
@w_t_plazo    = tr_tipo_plazo,
@w_plazo      = tr_plazo,
@w_cuota      = tr_cuota_aproximada,
@w_mercado    = tr_mercado,
@w_tipo_t     = tr_tipo,
@w_banco      = tr_numero_op_banco,
@w_tasa_reest = tr_tasa_reest,
@w_t_cuota    = tr_tipo_cuota,
@w_fecha_fija = tr_fecha_fija,
@w_dia_pago   = tr_dia_pago,
@w_tipo_norm  = tr_grupo           --436 NORMALIZACION DE CARTERA
from cob_credito..cr_tramite
where tr_tramite = @i_tramite

--436 NORMALIZACION DE CARTERA
if @w_tipo_t = 'M' and @w_tipo_norm = 1
   select @w_monto   = 0,                      --41
          @w_plazo   = 0,                      --42
          @w_t_plazo = '',                     --43
          @w_cuota   = '0'                     --44

if @i_tipo_reporte is null begin
   select @w_plazo_dias = @w_plazo * td_factor
   from   cob_cartera..ca_tdividendo
   where  td_tdividendo = @w_t_plazo

   select @w_cuota_dias = td_factor
   from   cob_cartera..ca_tdividendo
   where  td_tdividendo = @w_t_cuota
   
   /* SI EL CREDITO TIENE UNA SOLA CUOTA TOMO LA PRIMERA CUOTA, DE LO CONTRARIO LA SEGUNDA */
   if @w_plazo_dias = @w_cuota_dias begin
      select @w_div_cuota = 1
   end else begin
      select @w_div_cuota = 2
   end

   if @w_tipo_t='E' begin

       exec @w_error = cob_cartera..sp_reestructuracion_cca
       @s_user             = @s_user,
       @s_date    = @s_date,
       @s_ofi              = @s_ofi,
       @s_term             = @s_term,
       @i_bloquear_salida  = 'S',
       @i_paso             = 'S', --SIMULACION
       @i_banco            = @w_banco,
       @i_plazo            = @w_plazo,
       @i_pago             = 'N',
       @i_tasa             = @w_tasa_reest,
       @i_tplazo           = @w_t_plazo,
       @i_tdividendo       = @w_t_cuota,
       @i_fecha_fija_pago  = @w_fecha_fija,
       @i_dia_fijo         = @w_dia_pago

       if @w_error <> 0 begin

           exec cob_cartera..sp_reestructuracion_cca
           @s_user             = @s_user,
           @s_date             = @s_date,
           @s_ofi              = @s_ofi,
           @s_term             = @s_term,
           @i_paso             = 'T', --BORRA TEMPORALES
           @i_banco            = @w_banco

           select @w_msg = 'Error en elaboracion de la simulacion', @w_sev = 0
           goto ERROR_FIN

       end

       select @w_op_reest = op_operacion
       from cob_cartera..ca_operacion
       where op_banco = @w_banco

       select @w_cuota = sum(amt_cuota)
       from  cob_cartera..ca_amortizacion_tmp, cob_cartera..ca_rubro_op_tmp
       where amt_operacion = @w_op_reest
       and   amt_dividendo = @w_div_cuota
       and   amt_operacion = rot_operacion
       and   amt_concepto  = rot_concepto


       exec cob_cartera..sp_reestructuracion_cca
       @s_user             = @s_user,
       @s_date             = @s_date,
       @s_ofi              = @s_ofi,
       @s_term             = @s_term,
       @i_paso             = 'T', --BORRA TEMPORALES
       @i_banco            = @w_banco

   end
   else
   begin
      if @w_tipo_t = 'M' and @w_tipo_norm = 1       -- 436 NORMALIZACION DE CARTERA
         select @w_cuota = '0'
      else    
         select @w_cuota = sum(am_cuota)
         from  cob_cartera..ca_amortizacion with (nolock)
         where am_dividendo = @w_div_cuota
         and   am_operacion = @w_operacion        
   end
end

select @w_mercado_que_atiende = valor
from cobis..cl_catalogo c, cobis..cl_tabla t
where c.tabla  = t.codigo
and   t.tabla  = 'cl_mercado_objetivo'
and   c.codigo = @w_mercado
and   c.estado = 'V'


create table #referencias (
re_fecha_registro    datetime       null,
re_tipo              varchar(20)    null,
re_nombre            varchar(255)   null,
re_telefono1         char(16)       null,
re_telefono2         char(16)       null,
re_direccion         varchar(255)   null,
re_relacion          varchar(64)    null,
re_observacion       varchar(255)   null
)

insert into #referencias
(re_fecha_registro,re_tipo,re_nombre,re_telefono1,re_observacion)
select re_fecha_registro,(select valor from cobis..cl_tabla a, cobis..cl_catalogo b
where a.codigo=b.tabla
and a.tabla='cl_rtipo'
and b.codigo=re_tipo)
, case when re_tipo='C' then co_institucion
when re_tipo='B' then (select ba_descripcion from cobis..cl_banco_rem where ba_banco=ec_banco)
when re_tipo='F' then (select ba_descripcion from cobis..cl_banco_rem where ba_banco=fi_banco)
when re_tipo='T' then re_sucursal end
, re_telefono,re_observacion from cobis..cl_referencia
where re_ente=@i_ente
and re_vigencia='S'

insert into #referencias
(re_fecha_registro,re_tipo,re_nombre,re_telefono1,re_telefono2,re_direccion,re_relacion,re_observacion)
select rp_fecha_registro,'PERSONAL',rp_nombre+' '+rp_p_apellido+' '+rp_s_apellido,rp_telefono_d,rp_telefono_e,
rp_direccion,(select c.valor
              from cobis..cl_tabla t,
                   cobis..cl_catalogo c
              where t.tabla = 'cl_parentesco'
              and t.codigo = c.tabla
              and c.codigo = rp_parentesco),
rp_descripcion
from
cobis..cl_ref_personal
where rp_persona=@i_ente
and rp_vigencia='S'










DIRECCION:

select @w_tde = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'TDE'

exec cobis..sp_datos_cliente
@i_tipo          = @w_tde,
@i_ente          = @i_ente,
@o_telefono      = @w_telefono_emp out


select @w_tdr = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'TDR'

exec cobis..sp_datos_cliente
@i_tipo          = @w_tdr,
@i_ente          = @i_ente,
@o_descripcion   = @w_descripcion out,
@o_telefono      = @w_telefono out,
@o_desparroquia  = @w_desparroquia out,
@o_desprovincia  = @w_desprovincia out

select @w_tdn = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'TDN'

exec cobis..sp_datos_cliente
@i_tipo          = @w_tdn,
@i_ente          = @i_ente,
@o_descripcion   = @w_direccion_micro out,
@o_telefono      = @w_telefono_neg out,
@o_barrio        = @w_barrio_neg out,
@o_desciudad     = @w_desciudad_neg out

if @@rowcount = 0
    select @o_inddir = 'N'
else
    select @o_inddir = 'S'

select @w_dir_neg = @w_direccion_micro
select @w_tel_neg = @w_telefono_neg

if @o_inddir = 'S'
begin
    select
    @w_pais    = pa_pais,
    @w_despais = pa_descripcion
    from   cobis..cl_pais, cobis..cl_provincia
    where pv_provincia = @w_provincia
    and   pa_pais      = pv_pais


    select @w_tel_cel = rtrim(ltrim(te_prefijo)) + rtrim(ltrim(te_valor))
    from  cobis..cl_telefono
    where te_ente          = @i_ente
    and   te_tipo_telefono = 'C'

    if @w_rural_urb = 'U'
        select @w_barrio = pq_descripcion
        from   cobis..cl_parroquia
        where  pq_parroquia = @w_parroquia
end

if @i_frontend = 'S'
begin
    --Calcula la edad del asegurado
    select @w_edad = datediff(yy, @w_fecha_nac_datetime, @s_date)

    if datepart(mm,@s_date) < datepart(mm,@w_fecha_nac_datetime)
        select @w_edad = datepart(yy,@s_date) - datepart(yy,@w_fecha_nac_datetime) -1

    if datepart(mm,@s_date) = datepart(mm,@w_fecha_nac_datetime)
        if datepart(dd,@s_date) < datepart(dd,@w_fecha_nac_datetime)
            select @w_edad = datepart(yy,@s_date) - datepart(yy,@w_fecha_nac_datetime) -1

    --Datos del cliente
    select
    @w_tipoced,                               --1
    substring(@w_cedruc,1,30),                --2
    substring(@w_nombre,1,50),                --3
    substring(@w_papellido,1,45),             --4
    substring(@w_sapellido,1,45),             --5
    @w_ciudadexp,                             --6
    substring(@w_desciuexp,1,50),             --7
    @w_fecha_exp,                             --8
    @w_ofiprod,                               --9
    @w_fecha_nac,                            --10
    @w_ciudadnac,                            --11
    substring(@w_desciunac,1,30),            --12
    @w_genero,                               --13
    substring(@w_ocupacion,1,50),            --14
    substring(@w_descocupa,1,30),            --15
    substring(@w_ecivil,1,30),               --16
    substring(@w_descecivil,1,30),           --17
    substring(@w_tvivienda,1,30),            --18
    @w_desctviv,                             --19
    substring(@w_nivelest,1,30),             --20
    @w_descnest,                             --21
    @w_fch_neg,                              --22
    substring(@w_en_estrato,1,30),           --23
    @w_p_num_cargas,                         --24
    substring(@w_coy_papellido,1,45),        --25
    substring(@w_coy_sapellido,1,45),        --26
    substring(@w_coy_nombres,1,50),          --27
    @w_coy_tipoced  ,                        --28
    substring(@w_coy_cedruc,1,30),           --29
    @w_coy_ciudadexp,                        --30
    substring(@w_coy_desciuexp,1,30),        --31
    @w_coy_fecha_exp,                        --32
    substring(@w_coy_empresa,1,50),          --33
    @w_coy_telefono ,                        --34
    @w_coy_direccion ,                       --35
    substring(@w_coy_descripcion,1,50),      --36
    substring(@w_des_depexp,1,30),           --37
    substring(@w_des_paisexp,1,30),          --38
    @w_hijos,                                --39
    substring(@w_fondos,1,99),               --40
    @w_monto,                                --41
    @w_plazo,                                --42
    @w_t_plazo,                              --43
    @w_cuota,                                --44
    substring(@w_des_tipo,1,50),             --45
    substring(@w_empresa,1,50),              --46
    @w_sueldo,                               --47
    convert(varchar(10),@w_fec_ingreso,103), --48
    substring(@w_cargo,1,50),                --49
    substring(@w_contrato,1,50),             --50
    substring(@w_dir_trabajo,1,70),          --51
    @w_ref_vienda,                           --52
    substring(@w_nom_vienda,1,50),           --53
    @w_tel_vienda,                           --54
    substring(@w_tipo_tramite,1,30),         --55
    @w_tel_trabajo,                          --56
    @w_fax_trabajo,                          --57
    @w_edad,                                 --58
    @w_subtipo,                              --59   /* Juridica */
    substring(@w_des_actividad_mo,1,50),     --60   /* Juridica */
    substring(@w_nombre_com_rl,1,50),        --61   /* Juridica */
    substring(@w_cedula_rl,1,30),            --62   /* Juridica */
    @w_tipo_doc_rl,                          --63   /* Juridica */
    substring(@w_ciudad_exp_rl,1,30),        --64   /* Juridica */
    @w_dir_rl,                               --65   /* Juridica */
    substring(@w_ciudad_dir_rl,1,30),        --66   /* Juridica */
    @w_depto_dir_rl,                         --67   /* Juridica */
    @w_alianza                               --68   /* Alianzas Comerciales */


    --Datos Direccion
    select
    @w_tipodir,                               --1
    @w_pais,                                  --2
    substring(@w_despais,1,50),               --3
    @w_provincia,                             --4
    substring(@w_desprovincia,1,50),          --5
    @w_ciudad,                                --6
    substring(@w_desciudad,1,50),             --7
    @w_parroquia,                             --8
    substring(@w_desparroquia,1,50),          --9
    substring(@w_descripcion,1,50),           --10
    @w_telefono,                              --11
    @w_tel_cel,                               --12
    substring(@w_barrio,1,50),                --13
    @w_telefono_emp,                          --14
    @w_dir_neg,                               --15   /* Juridica */
    substring(@w_desciudad_neg,1,50),         --16   /* Juridica */
    @w_barrio_neg,                            --17   /* Juridica */
    @w_tel_neg                                --18   /* Juridica */

    --Microempresa
    select
    substring(@w_ciiu,1,50),                  --1
    substring(@w_actividad,1,50),             --2
    substring(@w_nombre_micro,1,50),          --3
    substring(@w_nit,1,50),                   --4
    substring(@w_direccion_micro,1,50),       --5
    @w_telefono_neg      ,                    --6
    substring(@w_desc_barrio_micro,1,50),     --7
    substring(@w_mercado_que_atiende,1,50),   --8
    @w_numero_empleados     ,                 --9
    @w_tiempo_propie_negoc  ,                 --10
    @w_experiencia          ,                 --11
    substring(@w_descr_local,1,50),           --12
    substring(@w_nombre_arrendador,1,50),     --13
    @w_telefono_arrenda      ,                --14
    substring(@w_refer_arrendador,1,50),      --15,
    substring(@w_desc_dep_micro,1,50)         --16

    select convert(varchar(10),re_fecha_registro,@i_formato_f),
    substring(re_tipo,1,50),
    substring(re_nombre,1,50),
    re_telefono1,
    re_telefono2,
    substring(re_direccion,1,50),
    substring(re_relacion,1,50),
    substring(re_observacion,1,50)
    from  #referencias
end
else
begin
    --Datos del cliente
    select
    @o_tipoced          = @w_tipoced,    --1
    @o_cedruc           = @w_cedruc,     --2
    @o_nombre           = @w_nombre,     --3
    @o_papellido        = @w_papellido,  --4
    @o_sapellido        = @w_sapellido,  --5
    @o_ciudadexp        = @w_ciudadexp,  --6
    @o_desciuexp        = @w_desciuexp,  --7
    @o_fecha_exp        = @w_fecha_exp,  --8
    @o_ofiprod          = @w_ofiprod,    --9
    @o_fecha_nac        = @w_fecha_nac,  --10
    @o_ciudadnac        = @w_ciudadnac,  --11
    @o_desciunac        = @w_desciunac,  --12
    @o_genero           = @w_genero,     --13
    @o_ocupacion        = @w_ocupacion,  --14
    @o_descocupa        = @w_descocupa,  --15
    @o_ecivil           = @w_ecivil,     --16
    @o_descecivil       = @w_descecivil, --17
    @o_tvivienda        = @w_tvivienda,  --18
    @o_desctviv         = @w_desctviv,   --19
    @o_nivelest         = @w_nivelest,   --20
    @o_descnest         = @w_descnest,   --21
    @o_fch_neg          = @w_fch_neg ,   --22
    @o_en_estrato       = @w_en_estrato,  --23
    @o_p_num_cargas     = @w_p_num_cargas, --24
    @o_coy_papellido    = @w_coy_papellido,    --25
    @o_coy_sapellido    = @w_coy_sapellido,    --26
    @o_coy_nombres      = @w_coy_nombres  ,    --27
    @o_coy_tipoced      = @w_coy_tipoced  ,    --28
    @o_coy_cedruc       = @w_coy_cedruc   ,    --29
    @o_coy_ciudadexp    = @w_coy_ciudadexp,    --30
    @o_coy_desciuexp    = @w_coy_desciuexp,    --31
    @o_coy_fecha_exp    = @w_coy_fecha_exp,    --32
    @o_coy_empresa      = @w_coy_empresa  ,    --33
    @o_coy_telefono     = @w_coy_telefono ,    --34
    @o_coy_direccion    = @w_coy_direccion ,   --35
    @o_coy_descripcion  = @w_coy_descripcion,  --36
    @o_profesion        = @w_profesion         --37


    --Datos Direccion
    select
    @o_tipodir      = @w_tipodir,      --1
    @o_pais         = @w_pais,         --2
    @o_despais      = @w_despais,      --3
    @o_provincia    = @w_provincia,    --4
    @o_desprovincia = @w_desprovincia, --5
    @o_ciudad       = @w_ciudad,       --6
    @o_desciudad    = @w_desciudad,    --7
    @o_parroquia    = @w_parroquia,    --8
    @o_desparroquia = @w_desparroquia, --9
    @o_descripcion  = @w_descripcion,  --10
    @o_telefono     = @w_telefono,     --11
    @o_tel_cel      = @w_tel_cel,      --12
    @o_barrio       = @w_barrio        --13

    --Microempresa
    select
    @w_ciiu              ,     --1
    @w_actividad         ,     --2
    @w_nombre_micro      ,     --3
    @w_nit               ,     --4
    substring(@w_direccion_micro,1,50)      ,     --5
    @w_telefono_neg      ,     --6
    @w_desc_barrio_micro ,     --7
    @w_mercado_que_atiende  ,  --8
    @w_numero_empleados     ,  --9
    @w_tiempo_propie_negoc  ,  --10
    @w_experiencia          ,  --11
    @w_descr_local          ,  --12
    @w_nombre_arrendador    ,  --13
    @w_telefono_arrenda      , --14
    substring(@w_refer_arrendador,1,50),           --15
    @w_desc_dep_micro          --16


    select
    re_fecha_registro,
    re_tipo,
    re_nombre,
    re_telefono1,
    re_telefono2,
    re_direccion,
    re_relacion
    from  #referencias

end

return 0

ERROR_FIN:

exec cobis..sp_cerror
@t_from  = @w_sp_name,
@i_num   = @w_error,
@i_msg   = @w_msg,
@i_sev   = @w_sev

return @w_error


GO

