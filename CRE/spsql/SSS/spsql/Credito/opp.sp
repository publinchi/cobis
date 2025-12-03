/************************************************************************/
/*  Archivo:                opp.sp                                      */
/*  Stored procedure:       sp_opp                                      */
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

if exists(select 1 from sysobjects where name ='sp_opp')
    drop proc sp_opp
go

create proc sp_opp(
   @i_fecha    datetime    = '',
   @i_report   varchar(64) = null
)
as
set ansi_warnings off
set ansi_nulls    off

declare
   @w_sp_name               varchar(32),
   @w_error                 int,
   @w_ente                  int,
   @w_fecha_ini_mes         datetime,
   @w_desc_direccion_princ  varchar(30),
   @w_telefono_fijo         varchar(10),
   @w_telefono_fijo2        varchar(10),
   @w_path                  varchar(250),
   @w_file                  varchar(250),
   @w_s_app                 varchar(250),
   @w_sqr                   varchar(250),
   @w_cmd                   varchar(250),
   @w_bd                    varchar(250),
   @w_tabla                 varchar(250),
   @w_fecha_arch            varchar(10),
   @w_comando               varchar(500),
   @w_destino               varchar(250),
   @w_errores               varchar(250),
   @w_path_s_app            varchar(250),
   @w_smlmv                 money

declare @fng1 table (
   ref_archi         varchar(10),
   nit_inter         varchar(20),
   cod_sucur         varchar(10),
   nomlar            varchar(40),
   tipo_id           varchar(4),
   num_id            varchar(16),
   fec_nac           varchar(8),
   gen_deudor        varchar(1),
   est_ci_deudor     varchar(2),
   nivel_estu        varchar(1),
   dir_deudor        varchar(60),
   tipo_id_rl        varchar(3),
   id_rl             char(1),
   nomlar_rl         varchar(40),
   munic_deudor      varchar(5),
   tel1_deudor       varchar(16),
   tel2_deudor       varchar(16),
   fax_deudor        varchar(16),
   email_deudor      varchar(30),
   ciiu              char(4),
   acti_total        numeric(12,0),
   pasi_total        numeric(12,0),
   ing_deudor        numeric(12,0),
   egr_deudor        numeric(12,0),
   cam_r1            varchar(1),
   cam_r2            varchar(1),
   ref_credito       varchar(18),
   num_pagare        varchar(18),
   cod_moneda        varchar(3),
   valor_monto       numeric(11,0),
   num_cup_rot       char(1),
   cam_r3            varchar(1),
   cam_r4            varchar(1),
   fec_desem         varchar(8),
   cod_plazo_o       tinyint, ---cambio
   plazo             tinyint, --- cambio
   cod_tasa_index    char(3),
   signo_puntos      varchar(1),
   puntos_tasa       numeric(5, 2),
   cod_perio_tasa    varchar(2),
   mod_tasa          varchar(1),
   per_amorti        varchar(3),
   calif_r_obli      varchar(2), ---cambio
   cam_r5            varchar(1),
   per_gra_capi      varchar(3),
   tipo_car          varchar(2),
   desti_credito     varchar(3),
   tipo_recur        varchar(1),
   val_redes         char(1),
   porc_redes        char(1),
   nit_enti_redes    char(1),
   cam_r6            varchar(1),
   cam_r7            varchar(1),
   cam_r8            varchar(1),
   cam_r9            varchar(1),
   val_gar_rea_af    numeric(12, 0),
   fec_val_gar_af    varchar(8),
   desc_gar_af       varchar(60),
   desc_ogar_af      varchar(60),
   cod_prod_gar      varchar(6),
   num_gar_fng       varchar(10),
   porc_cober        float,
   per_cobr_comi     varchar(2),
   nit_ecap          char(1),
   razsoci_ecap      varchar(40),
   cod_mun_ecap      char(1),
   dir_domi_ecap     varchar(60),
   tipo_id_rl_ecamp  varchar(3),
   id_rl_ecamp       char(1),
   nomlar_rl_ecamp   varchar(40),
   cap_susypag_antes char(1),
   cap_susypag       char(1),
   fec_cap           varchar(8),
   val_aval_inmu     char(1),
   dir_inmu          varchar(60),
   matri_inmu        varchar(18),
   cod_muni_inmu     char(1),
   val_subsidio      char(1),
   estrato           varchar(2),
   tipo_vivienda     char(1),
   porc_finan_vivi   varchar(2),
   cam_r10           varchar(1),
   cam_r11           varchar(1),
   val_finan         char(1),
   cam_r12           varchar(1),
   canon             char(1),
   t_ente            int )


select @w_sp_name = 'sp_opp'

select @w_fecha_ini_mes = dateadd(dd, 1 - datepart(dd, @i_fecha) , @i_fecha)

--- SALARIO MINIMO LEGAL
select @w_smlmv = pa_money
from cobis..cl_parametro
where pa_nemonico = 'SMLMV'


select
op_operacion,
op_tramite,
op_oficina,
op_migrada,
op_banco,
op_cliente,
op_fecha_liq,
op_plazo,
op_tplazo,
op_sector,
op_gracia_cap,
op_clase,
op_destino,
op_estado,
op_fecha_ult_proceso,
op_monto,
monto_smlv = (op_monto / @w_smlmv)
into #operaciones
from cob_cartera..ca_operacion with (nolock)
where op_fecha_liq =  @i_fecha
and   op_estado    not in (99, 0, 6)

if @@error <> 0
begin
   print 'ERROR EN INSERCION EN TEMPORAL DE OPERACIONES'
   return 1
end

delete #operaciones
where op_estado             = 3
and   op_fecha_ult_proceso <= @i_fecha

if @@error <> 0
begin
   print 'ERROR EN ELIMINACION EN TEMPORAL DE OPERACIONES'
   return 1
end

insert into  @fng1
select
   ref_archi         = 'RG'+ replace(convert(varchar, @i_fecha, 103),'/',''),
   nit_inter         = '9002150711',
   cod_sucur         = 'SBA52'+ convert(char(4), O.op_oficina),
   nomlar            = substring(en_nomlar, 0, 40),
   tipo_id           = (select codigo_sib
                        from cob_credito..cr_corresp_sib with (nolock)
                        where tabla  = 'T141'
                        and   codigo = E.en_tipo_ced     ),
   num_id            = en_ced_ruc,
   fec_nac           = replace(convert(varchar, p_fecha_nac, 103),'/',''),
   gen_deudor        = (select codigo_sib
                        from cob_credito..cr_corresp_sib with (nolock)
                        where tabla  = 'T84'
                        and   codigo = E.p_sexo          ),
   est_ci_deudor     = (select codigo_sib
                        from cob_credito..cr_corresp_sib with (nolock)
                        where tabla  = 'T85'
                        and   codigo = E.p_estado_civil  ),
   nivel_estu        = (select codigo_sib
                        from cob_credito..cr_corresp_sib with (nolock)
                        where tabla  = 'T86'
                        and   codigo = E.p_nivel_estudio ),
   dir_deudor        = ' ',
   tipo_id_rl        = ' ',
   id_rl             = ' ',
   nomlar_rl         = ' ',
   munic_deudor       = (select codigo_sib
                        from cob_credito..cr_corresp_sib with (nolock),cobis..cl_oficina
                        where tabla  = 'T140'
                        and codigo = of_ciudad
                        and   of_oficina = E.en_oficina),
   tel1_deudor       = ' ',
   tel2_deudor       = ' ',
   fax_deudor        = isnull((select min(te_valor)
                        from cobis..cl_telefono with (nolock)
                        where te_ente          = E.en_ente
                        and   te_tipo_telefono = 'F'      ),''),
   email_deudor      = isnull((select min(di_descripcion)
                        from cobis..cl_direccion with (nolock)
                        where di_ente      = E.en_ente
                        and   di_tipo      = '001'    ),''),
   ciiu              = isnull(substring(ltrim(rtrim(E.en_actividad)),1,4),'0000'),
   acti_total        = c_total_activos,
   pasi_total        = c_total_pasivos,
   ing_deudor        = p_nivel_ing,
   egr_deudor        = p_nivel_egr,
   cam_r1            = ' ',
   cam_r2            = ' ',
   ref_credito       = op_banco,
   num_pagare        = op_banco,
   cod_moneda        = (select codigo_sib
                        from cob_credito..cr_corresp_sib with (nolock)
                        where tabla   = 'T87'
                        and   codigo  = T.tr_moneda),
   valor_monto       = op_monto, ---Campo AD
   num_cup_rot       = ' ',
   cam_r3            = ' ',
   cam_r4            = ' ',
   fec_desem         = replace(convert(varchar, op_fecha_liq, 103),'/',''),
   cod_plazo_o       = 3, ---ESTE VALOR FIJO SE PIDO EN ORS 000347 egun ANEXO de esta ORS
   plazo             = op_plazo, ---No debe ser mayor a 36 meses para creditos EMP023
   cod_tasa_index    = '   ', ---ESte CAmpo debe ser 3 espacion en vacio segun INC.116164 Junio52014
   signo_puntos      = (select ro_signo                                         -- SENTIDO EN QUE SE APLICA EL SPREAD CON RESPECTO A LA TASA BASE
                        from cob_cartera..ca_rubro_op with (nolock)
                        where ro_operacion = O.op_operacion
                        and   ro_concepto  = 'INT'         ),
   puntos_tasa       = (select ro_porcentaje / 12.00                            -- SE ENVIA EL PORCENTAJE MENSUAL
                        from cob_cartera..ca_rubro_op with (nolock)
                        where ro_operacion = O.op_operacion
                        and   ro_concepto  = 'INT'         ),
   cod_perio_tasa    = 'M',                                                     -- GAL 27ABR2009 - CASO 173 - SE ENVIA SIEMPRE LA TASA EFECTIVA ANUAL
   mod_tasa          = (select tv_modalidad                                     -- MODALIDAD SEGUN REFERENCIAL DE LA TASA BASE
                        from cob_cartera..ca_rubro_op with (nolock),
                             cob_cartera..ca_valor_det with (nolock),
                             cob_cartera..ca_tasa_valor with (nolock)
                        where ro_operacion   = O.op_operacion
                        and   ro_concepto    = 'INT'
                        and   vd_tipo        = ro_referencial
                        and   vd_sector      = O.op_sector
                        and   tv_nombre_tasa = vd_referencia ),
   per_amorti        = (select codigo_sib
                        from cob_credito..cr_corresp_sib with (nolock)
                        where tabla  = 'T92'
                        and   codigo = O.op_tplazo      ),
   calif_r_obli      = 'A', ---- Solicitud ORS 347
   cam_r5            = ' ',
   per_gra_capi      = op_gracia_cap,                           -- VALOR ENTERO SEGUN OP_TPLAZO,
   tipo_car          = case when monto_smlv <= 25 then '04' else '01' end,
   desti_credito     = 'CT',  ---definicion de campo fijo ORS 000347 segun ANEXO de esta orden
   tipo_recur        = 'P',    -- SE DEJA ESTE VALOR POR DEFAULT SEGUN EL REQUERIMIENTO
   val_redes         = ' ',
   porc_redes        = ' ',
   nit_enti_redes    = ' ',
   cam_r6            = ' ',
   cam_r7            = ' ',
   cam_r8            = ' ',
   cam_r9            = ' ',
   val_gar_rea_af    = isnull((select sum(dj_total_bien)
                               from cr_microempresa with (nolock), cr_dec_jurada with (nolock)
                               where mi_tramite    = T.tr_tramite
                               and   dj_codigo_mic = mi_secuencial ), 0),
   fec_val_gar_af    = (select replace(convert(varchar, mi_fecha_inf, 103),'/','')
                        from cr_microempresa with (nolock)
                        where mi_tramite    = T.tr_tramite                         ),
   desc_gar_af       = dbo.detalle_declar_jur(T.tr_tramite),
   desc_ogar_af      = ' ',     -- VALOR POR DEFAULT CONFIRMADO BANCAMIA MBE 26/07/2008
   cod_prod_gar      = (select codigo_sib
                        from cob_credito..cr_corresp_sib with (nolock)
                        where tabla  = 'T98'
                        and   codigo = C.cu_tipo),
   num_gar_fng       = cu_num_dcto, ---Campo BI Codigo de la reserva
   porc_cober        = gp_porcentaje,
   per_cobr_comi     = 60,     -- GAL 29ABR2009 - CASO 173 - ANUAL ANTICIPADO SEGUN INSTRUCCIONES DE ANGELA RAMIREZ
   nit_ecap          = ' ',
   razsoci_ecap      = ' ',
   cod_mun_ecap      = ' ',
   dir_domi_ecap     = ' ',
   tipo_id_rl_ecamp  = ' ',
   id_rl_ecamp       = ' ',
   nomlar_rl_ecamp   = ' ',
   cap_susypag_antes = ' ',
   cap_susypag       = ' ',
   fec_cap           = ' ',
   val_aval_inmu     = ' ',
   dir_inmu          = ' ',
   matri_inmu        = ' ',
   cod_muni_inmu     = ' ',
   val_subsidio      = ' ',
   estrato           = ' ',
   tipo_vivienda     = ' ',
   porc_finan_vivi   = ' ',
   cam_r10           = ' ',
   cam_r11           = ' ',
   val_finan         = ' ',
   cam_r12           = ' ',
   canon             = ' ',
   t_ente            = en_ente     -- ESTE CAMPO NO HACE PARTE DEL REQUERIMIENTO SE UTILIZA PARA EL CURSOR MBE
from cob_custodia..cu_custodia C with (nolock),
     cob_custodia..cu_tipo_custodia TC with (nolock),
     cob_credito..cr_gar_propuesta GP with (nolock),
     cob_credito..cr_tramite T with (nolock),
     #operaciones O,
     cobis..cl_ente E with (nolock)
where gp_garantia          = cu_codigo_externo
and   tr_tramite           = gp_tramite
and   op_tramite           = tr_tramite
and   en_ente              = op_cliente
and   cu_tipo              = tc_tipo
and   tc_tipo_superior     = @i_report
and   gp_est_garantia      = 'V'
if @@error <> 0
begin
   print 'ERROR EN INSERCION DE VARIABLE TABLA DEL ANEXO 5'
   return 1
end


declare cur_opp cursor for
select distinct t_ente

from  @fng1

open cur_opp

fetch next from cur_opp into
   @w_ente

while @@fetch_status = 0
begin
   select @w_desc_direccion_princ = replace(
                                    replace(
                                    replace(
                                    replace(
                                    replace(
                                    replace(
                                    replace(
                                    replace(di_descripcion, ';',      ' '),
                                                            ',',      ' '),
                                                            '.',      ' '),
                                                            char(13), ' '),
                                                            char(10), ' '),
                                                            char(9),  ' '),
                                                            ':',      ' '),
                                                            '§',      ' ')
   from cobis..cl_direccion with (nolock)
   where di_ente      = @w_ente
   and   di_principal = 'S'


   set rowcount 1

   select @w_telefono_fijo = te_valor
   from cobis..cl_telefono with (nolock)
   where te_ente                 = @w_ente
   and   te_tipo_telefono       in ('D', 'X')
   and   rtrim(ltrim(te_valor)) <> '0000000'
   order by te_tipo_telefono, te_secuencial

   set rowcount 0


   set rowcount 1

   select @w_telefono_fijo2 = te_valor
   from cobis..cl_telefono with (nolock)
   where te_ente                 = @w_ente
   and   te_tipo_telefono       in ('D', 'X')
   and   rtrim(ltrim(te_valor)) <> '0000000'
   and   te_valor               <> @w_telefono_fijo
   order by te_tipo_telefono, te_secuencial

   set rowcount 0

   -- ACTUALIZA DIRECCION Y TELEFONOS DEL CLIENTE EN TMP
   update  @fng1 set
      tel1_deudor = isnull(rtrim(ltrim(@w_telefono_fijo)), ' '),
      tel2_deudor = isnull(rtrim(ltrim(@w_telefono_fijo2)), ' '),
      dir_deudor  = @w_desc_direccion_princ
   where t_ente = @w_ente

   if @@error <> 0
   begin
      print 'ERROR EN ACTUALIZACION DE VARIABLE TABLA DEL ANEXO 5'
      close cur_opp
      deallocate cur_opp
      return 1
   end



   fetch next from cur_opp into
      @w_ente
end  --While

close cur_opp
deallocate cur_opp
---Antes de Insertar se actaualizan los datos generales como


---EL PLAZO NO DEBE SER MAYOR A 36 PARA OPERACIONES
--- EMP023
if exists (select 1 from @fng1
           where cod_prod_gar = 'EPM023'
           and plazo > 36)
begin
  update  @fng1
  set plazo = 36
  where cod_prod_gar = 'EPM023'
  and plazo > 36
end


insert into cr_fng1_tmp
select
   ref_archi,         nit_inter,          cod_sucur,         -- 3
   nomlar,            tipo_id,            num_id,            -- 6
   fec_nac,           gen_deudor,         est_ci_deudor,     -- 9
   nivel_estu,        dir_deudor,         tipo_id_rl,        -- 12
   id_rl,             nomlar_rl,          munic_deudor,      -- 15
   tel1_deudor,       tel2_deudor,        fax_deudor,        -- 18
   email_deudor,      ciiu,               convert(varchar(15),acti_total),        -- 21
   pasi_total,        ing_deudor,         egr_deudor,        -- 24
   cam_r1,            cam_r2,             ref_credito,       -- 27
   num_pagare,        cod_moneda,         valor_monto,       -- 30
   num_cup_rot,       cam_r3,             cam_r4,            -- 33
   fec_desem,         cod_plazo_o,        plazo,             -- 36
   cod_tasa_index,    signo_puntos,       puntos_tasa,       -- 39
   cod_perio_tasa,    mod_tasa,           per_amorti,        -- 42
   calif_r_obli,      cam_r5,             per_gra_capi,      -- 45
   tipo_car,          desti_credito,      tipo_recur,        -- 48
   val_redes,         porc_redes,         nit_enti_redes,    -- 51
   cam_r6,            cam_r7,             cam_r8,            -- 54
   cam_r9,            val_gar_rea_af,     fec_val_gar_af,    -- 57
   desc_gar_af,       desc_ogar_af,       cod_prod_gar,      -- 60
   num_gar_fng,       porc_cober,         per_cobr_comi,     -- 63
   nit_ecap,          razsoci_ecap,       cod_mun_ecap,      -- 66
   dir_domi_ecap,     tipo_id_rl_ecamp,   id_rl_ecamp,       -- 69
   nomlar_rl_ecamp,   cap_susypag_antes,  cap_susypag,       -- 72
   fec_cap,           val_aval_inmu,      dir_inmu,          -- 75
   matri_inmu,        cod_muni_inmu,      val_subsidio,      -- 78
   estrato,           tipo_vivienda,      porc_finan_vivi,   -- 81
   cam_r10,           cam_r11,            val_finan,         -- 84
   cam_r12,           canon                                  -- 86
from @fng1

if @@error <> 0
begin
   print 'ERROR EN INSERCION EN TABLA TEMPORAL DEL ANEXO 5'
   return 1
end

---LOS ACTIVOS TOTALES SOLO DEBEN LLEVAR VALOR SI ES NIT
--- CASO CONTRARIO DEBEN IR VACIOS
update cr_fng1_tmp
set acti_total = ''
where tipo_id = 'CC'

select @w_path_s_app = pa_char
from cobis..cl_parametro with (nolock)
where pa_nemonico = 'S_APP'

select
   @w_sqr        = 'cob_custodia..sp_fng_5_ex',
   @w_file       = 'FNG5',
   @w_s_app      = @w_path_s_app + 's_app',
   @w_fecha_arch = convert(varchar, @i_fecha, 112)

select @w_path = ba_path_destino
from cobis..ba_batch with (nolock)
where ba_arch_fuente = @w_sqr

select
   @w_cmd      = @w_s_app + ' bcp -auto -login ',
   @w_bd       = 'cob_credito',
   @w_tabla    = 'cr_fng1_tmp',
   @w_destino  = @w_path + @w_file + '_' + @w_fecha_arch + '.csv',
   @w_errores  = @w_path + @w_file + '_' + @w_fecha_arch + '.err'

select
   @w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destino +
                ' -b5000 -c -e' + @w_errores + ' -t";" ' + '-config ' + @w_s_app + '.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0
begin
   print 'ERROR EN EJECUCION DE BCP'
   return @w_error
end


return 0
go
