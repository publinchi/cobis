/************************************************************************/
/*      Archivo:                rep_hacienda_distrital.sp               */
/*      Stored procedure:       sp_rep_hacienda_distrital               */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Jul. 2008                               */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Genera datos para el reporte                                    */
/*      "Reporte Hacienda Distrital                                     */
/************************************************************************/
 
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_rep_hacienda_distrital')
   drop proc sp_rep_hacienda_distrital
go
 
 
create proc sp_rep_hacienda_distrital
    @t_debug      char(1)     = 'N',  
    @t_file       varchar(14) = null,
    @t_from       varchar(30) = null,
    @i_fecha_cie  datetime    = null,
    @i_linea      varchar(10) = null
 
as
 
declare @w_sp_name            varchar(32),
        @w_return             int,
        @w_error              int,
        @w_msg                varchar(60),
	@w_consecutivo        int,
        @w_est_vigente        tinyint,
	@w_est_vencido        tinyint,
	@w_est_cancelado      tinyint,
	@w_est_castigado      tinyint,
	@w_est_suspenso       tinyint,
        @w_pa_char_tdr        char(3),
        @w_pa_char_tdn        char(3),
        @w_operacionca        int,
        @w_op_cliente         int,
        @w_nom_programa       varchar(24),
        @w_en_tipo_ced        char(2),
        @w_des_tipo_ced       descripcion,
        @w_en_ced_ruc         numero,
        @w_op_nombre          descripcion,
        @w_op_banco           cuenta,
        @w_cod_estrato        varchar(10),
        @w_des_estrato        descripcion,
        @w_nom_linea          varchar(32),
        @w_p_fecha_nac        datetime,
        @w_p_ciudad_nac       int,
        @w_nom_actividad      varchar(32),
        @w_nom_ciudad_nac     descripcion,
        @w_tr_fecha_apr       datetime,
        @w_op_tplazo          catalogo,
        @w_op_plazo           smallint,
        @w_plazo_meses        smallint,
        @w_p_sexo             sexo,
        @w_des_sexo           descripcion,
        @w_op_toperacion      varchar(10),
        @w_dir_microempresa   varchar(254),
        @w_tel_microempresa   varchar(16),
        @w_op_ciudad          int,
        @w_cod_bar_mic        varchar(10),
        @w_op_oficina         smallint,
        @w_en_actividad       varchar(10),      
        @w_nom_ciudad         descripcion,
        @w_tas_nominal        float,
        @w_edad_deudor        int,
        @w_tot_activos        money,
        @w_can_tra_emp        int,
        @w_op_monto           money,
        @w_sal_capital        money,
        @w_en_estrato         varchar(10),
        @w_nom_oficina        varchar(64),
        @w_op_tramite         int,
        @w_des_bar_mic        varchar(64),
        @w_op_gracia_cap      smallint,
        @w_gan_per_mic        money, 
        @w_nom_sec_eco        descripcion,
        @w_destino            varchar(10),
        @w_des_oficina        varchar(64),
        @w_en_sector          varchar(10),
        @w_op_destino         varchar(10),
        @w_op_fecha_liq       datetime,
        @w_per_cuota          varchar(24),
        @w_op_sector          varchar(10),
        @w_op_banca           varchar(10),

        @w_meses_fecha        datetime,
        @w_fecha_cierre       datetime
        
 
 
/*
select @w_meses_fecha = datepart (mm, @w_fecha_cierre + 1)
 
if @w_meses_fecha = datepart (mm, @w_fecha_cierre)
begin
   print 'Mensaje de error, No es cierre de mes'   
   return 0
end 
 
if @w_fecha_cierre <> @i_fecha_cie 
begin
   print 'Mensaje de error, Parametro de fecha de cierre esta errada'   
   return 0
end
*/
 
/* ESTADO DE LAS OPERACIONES */
select @w_est_vigente = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'VIGENTE'
 
select @w_est_vencido = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'VENCIDO'
 
select @w_est_cancelado = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'CANCELADO'
 
select @w_est_castigado = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'CASTIGADO'
 
select @w_est_suspenso = es_codigo
from   ca_estado 
where  ltrim(rtrim(es_descripcion)) = 'SUSPENSO'
 
/* PARAMETROS DE TIPOS DE DIRECCION */
select @w_pa_char_tdr = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'TDR'
 
select @w_pa_char_tdn = pa_char
from   cobis..cl_parametro
where  ltrim(rtrim(pa_nemonico)) = 'TDN'
 
select @w_consecutivo = 0
 
/*CREACION DE TABLA TEMPORAL PARA EL REPORTE */
create table #rep_hacienda_distrital
(
tmp_consecutivo         int          null,  --Consecutivo de registro
tmp_nom_programa        descripcion  null,  --Nombre del programa de crédito (UBICAR ESTE CAMPO)
tmp_op_banco            cuenta       null,  --Número de la operación de crédito
tmp_op_nombre           varchar(100) null,  --Nombre completo del cliente
tmp_en_ced_ruc          varchar(32)  null,  --Número de identificación del cliente
tmp_dir_microempresa    varchar(254) null,  --Dirección de la microempresa
tmp_tel_microempresa    varchar(16)  null,  --Teléfono de la microempresa
tmp_cod_act_eco         catalogo     null,  --Código de la actividad económica del cliente
tmp_nom_act_eco         descripcion  null,  --Descripción de la actividad económica del cliente
tmp_op_monto            money        null,  --Monto del desembolso
tmp_op_tplazo           catalogo     null,  --Tipo de plazo de la operación
tmp_op_plazo            smallint     null,  --Plazo de la operación según el tipo de plazo
tmp_pla_meses           smallint     null,  --Plazo de la operación en meses
tmp_per_gra_cap         varchar(24)  null,  --Periodo de gracia para capital
tmp_per_cuota           varchar(24)  null,  --Periodicidad de la cuota
tmp_fec_liq             datetime     null,  --Fecha de liquidación de la operación
tmp_op_toperacion       varchar(14)  null,  --Código de la línea de crédito
tmp_nom_toperacion      varchar(32)  null,  --Descripción de la línea de crédito
tmp_cod_bar_mic         smallint     null,  --Código del barrio de la microempresa
tmp_des_bar_mic         descripcion  null,  --Descripción del barrio de la microempresa
tmp_cod_estrato         varchar(10)  null,  --Código del estrato del cliente
tmp_des_estrato         descripcion  null,  --Descripción del estrato del cliente
tmp_tot_activos         money        null,  --Total activos de la microempresa
tmp_gan_per_mic         money        null,  --Por resolver
tmp_cod_sec_eco         catalogo     null,  --Código del sector económico del cliente
tmp_nom_sec_eco         descripcion  null,  --Descripción del sector económico del cliente
tmp_can_tra_emp         int          null,  --Número de trabajadores de la microempresa
tmp_cod_destino         catalogo     null,  --Código destino del préstamo
tmp_des_destino         descripcion  null,  --Descripción del destino económico del préstamo
tmp_cod_ofi_pre         smallint     null,  --Código de la oficina de la operación
tmp_des_ofi_pre         descripcion  null   --Descripción de la oficina de la operación
)
 
/* CURSOR PARA LA LECTURA DE LAS OPERACIONES DE LA LINEA DE CREDITO HACIENDA DISTRITAL */
declare
cursor_hacienda_distrital cursor
	for select
          op_operacion,          op_banco,         op_cliente,       op_nombre,
          op_tplazo,             op_plazo,         op_monto,         op_oficina,
	 (select substring(of_nombre,1,20) from cobis..cl_oficina where of_oficina = op_oficina),
          op_gracia_cap,         op_fecha_liq,     op_toperacion,
          en_estrato,            op_tramite,       en_ced_ruc,       en_actividad,
          en_sector,             op_destino,       op_sector,        op_banca
	  from  cob_cartera..ca_operacion,
	        cobis..cl_ente
  	  where op_estado in (@w_est_vigente, @w_est_vencido, @w_est_castigado, @w_est_suspenso)
          and   op_toperacion = @i_linea
          and   en_ente       = op_cliente
          order by op_banco
 
for read only
open  cursor_hacienda_distrital
fetch cursor_hacienda_distrital
into  @w_operacionca,       @w_op_banco,            @w_op_cliente,           @w_op_nombre,
      @w_op_tplazo,         @w_op_plazo,            @w_op_monto,             @w_op_oficina,
      @w_nom_oficina,
      @w_op_gracia_cap,     @w_op_fecha_liq,        @w_op_toperacion,
      @w_en_estrato,        @w_op_tramite,          @w_en_ced_ruc,           @w_en_actividad,
      @w_en_sector,         @w_op_destino,          @w_op_sector,            @w_op_banca
 
while   @@fetch_status = 0
begin
    if (@@fetch_status = -1)
    begin
        close cursor_hacienda_distrital 
        deallocate  cursor_hacienda_distrital 
        return 710004   -- Error en la lectura del cursor
    end
            
    /* PROCESO PRINCIPAL */
    select @w_consecutivo = @w_consecutivo + 1
 
    select @w_nom_programa = c.valor 
            from   cobis..cl_catalogo c, cobis..cl_tabla t                              
            where  c.tabla = t.codigo
            and    t.tabla = 'cl_banca_cliente'
            --and    c.codigo = @w_op_sector
            and    c.codigo = @w_op_banca
    select @w_dir_microempresa = di_descripcion           --Dirección de la microempresa
    from   cobis..cl_direccion
           left outer join cobis..cl_telefono
           on  te_ente      = di_ente
           and te_direccion = di_direccion
    where di_ente      = @w_op_cliente
    and   di_direccion = @w_pa_char_tdn

    if  @w_dir_microempresa is null
        select @w_dir_microempresa = 'SIN DIRECCION DE MICROEMPRESA'

    select @w_tel_microempresa = te_valor               --Teléfono de la microempresa
    from   cobis..cl_direccion
           left outer join cobis..cl_telefono
           on  te_ente      = di_ente
           and te_direccion = di_direccion
    where di_ente      = @w_op_cliente
    and   di_direccion = @w_pa_char_tdn

    if  @w_tel_microempresa is null
        select @w_tel_microempresa = 'SIN TEL. MICROEMPRESA'
 
    select @w_nom_actividad = valor					--Nombre de la actividad económica del cliente
    from cobis..cl_tabla t,
         cobis..cl_catalogo c
    where t.tabla = 'cl_actividad'
    and   c.tabla = t.codigo
    and   c.codigo = @w_en_actividad

    if  @w_nom_actividad is null
        select @w_nom_actividad = 'SIN NOMBRE ACTIVIDAD ECONOMICA'
 
    select @w_plazo_meses = (@w_op_plazo * td_factor)/30	--Plazo en meses de la operación
    from cob_cartera..ca_tdividendo
    where td_tdividendo = @w_op_tplazo
    
    select @w_per_cuota = td_descripcion 
    from cob_cartera..ca_tdividendo
    where td_tdividendo = @w_op_tplazo
 
    select @w_nom_linea = valor	        					--Nombre de la linea de crédito
    from cobis..cl_tabla t,
         cobis..cl_catalogo c
    where t.tabla = 'ca_toperacion'
    and   c.tabla = t.codigo
    and   c.codigo = @w_op_toperacion
 
    select @w_cod_bar_mic = mi_barrio,
           @w_can_tra_emp = (mi_num_trabaj_remu + mi_num_trabaj_no_remu)
    from cob_credito..cr_microempresa
    where mi_tramite = @w_op_tramite

    if  @w_cod_bar_mic is null
        select @w_cod_bar_mic = 0

    if  @w_can_tra_emp is null
        select @w_can_tra_emp = 0

    select @w_des_bar_mic = valor					--Nombre del barrio de la microempresa
    from cobis..cl_tabla t,
         cobis..cl_catalogo c
    where t.tabla  = 'cl_parroquia'
    and   c.tabla  = t.codigo
    and   c.codigo = @w_cod_bar_mic
 
    if  @w_des_bar_mic is null
        select @w_des_bar_mic = 'NO ENCONTRADO'

    select @w_des_estrato = valor					--Descripción del estrato del cliente
    from cobis..cl_tabla t,
         cobis..cl_catalogo c
    where t.tabla = 'cl_estrato'
    and   c.tabla = t.codigo
    and   c.codigo = @w_en_estrato

    if  @w_des_estrato is null
        select @w_des_estrato = 'NO ENCONTRADO'

    select @w_tot_activos = sum(mi_total_eyb + mi_total_cxc + mi_total_mp + mi_total_pep + mi_total_pt + mi_total_af) --Total activos microempresa                                                          --Número trabajadores de la microempresa
    from cob_credito..cr_microempresa
    where mi_tramite = @w_op_tramite

    if @w_tot_activos is null
       select @w_tot_activos = 0
 
    select @w_gan_per_mic = 0						--AVERIGURAR DONDE SE OBTIENE
	
    select @w_nom_sec_eco = valor					--Nombre del sector económico del cliente
    from cobis..cl_tabla t,
         cobis..cl_catalogo c
    where t.tabla = 'cl_sectoreco'
    and   c.tabla = t.codigo
    and   c.codigo = @w_en_sector
   									   
    select @w_destino = valor						
    from cobis..cl_tabla t,
         cobis..cl_catalogo c
    where t.tabla = 'cr_objeto'
    and   c.tabla = t.codigo
    and   c.codigo = @w_op_destino
 
    select @w_des_oficina = valor					--Descripción de la oficina VERIFICAR CON CUAL DE LAS DOS TABLAS SE OBTIENE LA DESCRIPCION
    from cobis..cl_tabla t,                         --O MEJOR CUAL DE LAS DOS TABLAS DE CIUDADES ES LA CORRECTA
         cobis..cl_catalogo c
    where t.tabla = 'cl_oficina'
    and   c.tabla = t.codigo
    and   c.codigo = @w_op_oficina
 
/* INSERCION EN LA TABLA TEMPORAL POR VARIABLES */
insert into #rep_hacienda_distrital
(
tmp_consecutivo,
tmp_nom_programa,
tmp_op_banco,
tmp_op_nombre,
tmp_en_ced_ruc,
tmp_dir_microempresa,
tmp_tel_microempresa,
tmp_cod_act_eco,
tmp_nom_act_eco,
tmp_op_monto,
tmp_op_tplazo,
tmp_op_plazo,
tmp_pla_meses,
tmp_per_gra_cap,
tmp_per_cuota,
tmp_fec_liq,
tmp_op_toperacion,
tmp_nom_toperacion,
tmp_cod_bar_mic,
tmp_des_bar_mic,
tmp_cod_estrato,
tmp_des_estrato,
tmp_tot_activos,
tmp_gan_per_mic,
tmp_cod_sec_eco,
tmp_nom_sec_eco,
tmp_can_tra_emp,
tmp_cod_destino,
tmp_des_destino,
tmp_cod_ofi_pre,
tmp_des_ofi_pre
)
values
(
@w_consecutivo,
@w_nom_programa,
@w_op_banco,
@w_op_nombre,
@w_en_ced_ruc,
@w_dir_microempresa,
@w_tel_microempresa,
@w_en_actividad,
@w_nom_actividad,
@w_op_monto,
@w_op_tplazo,
@w_op_plazo,
@w_plazo_meses,
@w_op_gracia_cap,
@w_per_cuota,
@w_op_fecha_liq,
@w_op_toperacion,
@w_nom_linea,
@w_cod_bar_mic,
@w_des_bar_mic,
@w_cod_estrato,
@w_des_estrato,
@w_tot_activos,
@w_gan_per_mic,
@w_en_sector,
@w_nom_sec_eco,
@w_can_tra_emp,
@w_op_destino,
@w_destino,
@w_op_oficina,
@w_des_oficina
)
fetch cursor_hacienda_distrital
into  @w_operacionca,       @w_op_banco,            @w_op_cliente,           @w_op_nombre,
      @w_op_tplazo,         @w_op_plazo,            @w_op_monto,             @w_op_oficina,
      @w_nom_oficina,
      @w_op_gracia_cap,     @w_op_fecha_liq,        @w_op_toperacion,
      @w_en_estrato,        @w_op_tramite,          @w_en_ced_ruc,           @w_en_actividad,
      @w_en_sector,         @w_op_destino,          @w_op_sector,            @w_op_banca

end --while
   
close cursor_hacienda_distrital 
deallocate cursor_hacienda_distrital 
   
   
/*PARA MOSTRAR LA INFORMACION DE LA CONSULTA EN GRILLA O PARA REPORTE */
select
tmp_consecutivo,
tmp_nom_programa,
tmp_op_banco,
tmp_op_nombre,
tmp_en_ced_ruc,
tmp_dir_microempresa,
tmp_tel_microempresa,
tmp_cod_act_eco,
tmp_nom_act_eco,
tmp_op_monto,
tmp_op_tplazo,
tmp_op_plazo,
tmp_pla_meses,
tmp_per_gra_cap,
tmp_per_cuota,
tmp_fec_liq1 = convert(varchar(10),tmp_fec_liq,103),
tmp_op_toperacion,
tmp_nom_toperacion,
tmp_cod_bar_mic,
tmp_des_bar_mic,
tmp_cod_est_1 = isnull(tmp_cod_estrato,0),
tmp_des_estrato,
tmp_tot_activos,
tmp_gan_per_mic,
tmp_cod_sec_eco,
tmp_nom_sec_eco,
tmp_can_tra_emp,
tmp_cod_destino,
tmp_des_destino,
tmp_cod_ofi_pre,
tmp_des_ofi_pre
 
from #rep_hacienda_distrital
order by tmp_consecutivo
 
 
return 0
 
ERROR:
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   
return @w_error
 
 
go
 
