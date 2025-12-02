/************************************************************************/
/*   Nombre Fisico:        impliqmsv.sp                                 */
/*   Nombre Logico:        sp_imprimir_liquidacion_msv                  */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:   	   RRB                                          */
/*   Fecha de escritura:   03/Abr./2013                                 */
/************************************************************************/
/* IMPORTANTE                                                           */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                                PROPOSITO                             */
/*   Imprimir de froma masiva liquidaciones de prestamos                */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre         Proposito                        */
/*    19/04/2022    K. Rodríguez    Cambio catálogo destino finan. op   */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'tmp_rubros_op_msv')
   drop table tmp_rubros_op_msv
go


create table tmp_rubros_op_msv
(
ro_secuencia    int,
ro_concepto     catalogo,
co_descripcion  descripcion,
ro_valor        money,
spid            int
)-- lock datarows
go

if exists (select 1 from sysobjects where name = 'ca_liquida_msv')
   drop table cob_cartera..ca_liquida_msv
go

create table cob_cartera..ca_liquida_msv(
-- Cabecera
li_opbanco                cuenta        null,
li_regional               varchar(64)   null, 
li_dir_comercial          varchar(254)  null,
li_telef_comercial        varchar(16)   null,
li_ciudad_comercial       descripcion   null,
li_fecha_naci             datetime      null,
li_sexo                   sexo          null,
li_tipo_operacion         catalogo      null,
li_seguro_vida            char(3)       null, 
li_otros_seguros          char(3)       null,
li_recursos               catalogo      null,
li_margen_redes           float         null,
li_fecha_ult_pago         datetime      null,
li_valor_ult_pago         money         null,
li_tipo_productor         varchar(24)   null,
li_actividad              varchar(24)   null,
li_saldo_actual           money         null,
li_pactado                varchar(12)   null,
li_clase                  varchar(24)   null,
li_tipo_amortizacion      varchar(20)   null,
li_calificacion           catalogo       null,
li_cuota                  numeric       null,
li_provisiona             char(3)       null,
li_fec_calificacion       datetime      null,
li_aprobado_por           varchar(24)   null,
li_nomina                 char(3)       null,
li_monto_aprobado         money         null,
li_fecha_aprobacion       datetime      null,
li_matricula              descripcion   null,
li_escritura              descripcion   null,
li_notaria                descripcion   null,
li_tipo_garantia          descripcion   null,
li_des_garantia           varchar(255)  null,
li_vlr_avaluo             float         null,
li_fecha_avaluo           datetime      null,
li_ubicacion              catalogo      null,
li_mun_garantia           int           null,
li_perito_aval            descripcion   null,
li_dias_venc              int           null,
li_nom_estado             descripcion   null,
li_cuotas_vencidas        int           null,
li_cuotas_pagadas         int           null,
li_cuotas_pendientes      int           null,
li_estado_juridico        varchar(10)   null,
li_fec_est_juridico       datetime      null,
li_clausula_aplicada      char(1)       null,
li_fec_clausula           datetime      null,
li_reestructuracion       char(1)       null,
li_anterior               cuenta        null,
li_numero_reest           int           null,
li_oficina                smallint      null,
li_deudor_otras           char(3)       null,
li_tasa                   float         null,
li_tasa_referencial       varchar(12)   null,
li_nombre_oficina         descripcion   null,
li_banco                  cuenta        null,
li_nombre                 descripcion   null,
li_mod_obligacion         descripcion   null,
li_periodo_pago           descripcion   null,
li_gracia_int             smallint      null,
li_nom_estado1            descripcion   null,
li_monto                  money         null,
li_otorgamiento           datetime      null,
li_fecha_fin              varchar(10)   null,
li_destino                catalogo      null,
li_cedula                 varchar(30)   null,
li_ultimo_pago            datetime      null,
li_deudor                 varchar(255)  null,
li_codeudor               varchar(255)  null,
li_moneda_desc            varchar(64)   null,
li_moneda                 tinyint       null,
li_cliente                int           null,
li_fecha_proceso          datetime      null,
li_neto_cap               money         null,
li_neto_deduc             money         null,
-- Conceptos
li_num                    int           null,
li_grupo                  char(1)       null,
li_concepto               varchar(100)  null,
li_valor                  money         null,
-- Beneficiarios
li_moneda1                varchar(64)   null,
li_cotizacion             int           null,
li_cuenta                 cuenta        null,
li_beneficiario           varchar(100)  null,
li_cruze_reestrictivo     varchar(100)  null,
-- Cliente
li_rol                    char(3)       null,
li_cliente_bene           int           null,
li_cedula_bene            varchar(30)   null,
li_pasaporte              varchar(30)   null,
li_telefono               varchar(16)   null,
li_direccion              varchar(100)  null,
li_nombre_bene            varchar(100)  null,
li_nombre_pdf             varchar(255)  null,
li_correo                 varchar(100)  null,
li_direc_banco            varchar(100)  null,
li_ciudad_ofi             varchar(100)  null,
li_telef_ofi              varchar(20)   null,
li_alianza                varchar(20)   null,
li_des_alianza            varchar(100)  null
)
go

if exists (select 1 from sysobjects where name = 'tmp_plano_liq_msv')
   drop table tmp_plano_liq_msv
go
create table tmp_plano_liq_msv (cadena varchar(1000) not null)


if exists (select 1 from sysobjects where name = 'sp_imprimir_liquidacion_msv')
   drop proc sp_imprimir_liquidacion_msv
go

create proc sp_imprimir_liquidacion_msv

@i_param1         datetime    = null,
@i_param2         datetime    = null,
@i_param3         varchar(30) = null,
@i_param4         int         = null,
@i_param5         char(1)     = 'N'

as
declare
   @w_sp_name               varchar(32),
   @w_error                 int,
   @w_tipo                  char(1),
   @w_det_producto          int,
   @w_anterior              cuenta,  
   @w_tramite               int,
   @w_fecha_crea            varchar(15),
   @w_toperacion            catalogo,
   @w_toperacion_desc       varchar(100),
   @w_moneda                tinyint,
   @w_moneda_desc           varchar(64),
   @w_monto                 money,
   @w_monto_aprobado        money,
   @w_destino               catalogo,
   @w_destini_desc          varchar(60),
   @w_ciudad_desc           varchar(30),
   @w_oficina               smallint,
   @w_oficial               smallint,
   @w_oficial_desc          varchar(60),
   @w_lin_credito           cuenta,
   @w_plazo                 smallint,
   @w_tplazo                catalogo,
   @w_tipo_amortizacion     varchar(20),
   @w_tdividendo            catalogo,
   @w_periodo_cap           smallint,
   @w_periodo_int           smallint,
   @w_gracia                smallint,
   @w_gracia_cap            smallint,
   @w_gracia_int            smallint,
   @w_cuota                 float,
   @w_tipo_cobro            char(1),
   @w_tipo_aplicacion       char(1),
   @w_aceptar_anticipos     char(1),
   @w_tipo_reduccion        char(1),
   @w_precancelacion        char(1),
   @w_tasa                  float,
   @w_renovacion            char(1),
   @w_mes_gracia            tinyint,
   @w_operacionca           int,
   @w_rejustable            char(1),
   @w_periodo_reaj          int,
   @w_tasa_ef_anual         float,
   @w_fecha_fin             varchar(10),
   @w_fecha_arch            varchar(10),
   @w_dias_anio             int,
   @w_base_calculo          char(1),
   @w_tasa_referencial      varchar(12), 
   @w_signo_spread          char(1),
   @w_valor_spread          float,
   @w_modalidad             char(1),
   @w_pactado               varchar(12),
   @w_valor_referencial     float,
   @w_sector                char(1),
   @w_tabla                 smallint,
   @w_tabla2                smallint,
   @w_tipo_puntos           char(1),
   @w_ref_exterior          cuenta,
   @w_fec_embarque          varchar(15),
   @w_fec_dex               varchar(15),
   @w_num_deuda_ext         cuenta,
   @w_num_comex             cuenta,
   @w_secuencial_ref        int,
   @w_valor_base            float,     
   @w_monto_retenido        money,
   @w_parametro             varchar(64),
   @w_codigo_externo        cuenta,
   @w_secuencial            int,
   @w_liquidacion           int,
   @w_int_ant               money,
   @w_recibo                int,
   @w_con_seguros           int,
   @w_con_otros_seg         int,   
   @w_con_deudor            int,
   @w_dir_comercial         varchar(254),
   @w_tel_comercial         varchar(16),
   @w_fec_nacimiento        datetime,
   @w_sexo                  sexo,
   @w_ciudad_comercial      descripcion,
   @w_cliente               int,
   @w_recursos              catalogo,
   @w_fec_ult_pago          datetime,
   @w_vlr_ult_pago          money,
   @w_seguro_vida           char(3),
   @w_otros_seguros         char(3),
   @w_par_matricula         descripcion,
   @w_par_escritura         descripcion,
   @w_par_notaria           descripcion,
   @w_matricula             descripcion,
   @w_escritura             descripcion,
   @w_notaria               descripcion,
   @w_tipo_garantia         descripcion,
   @w_des_garantia          varchar(255),
   @w_vlr_avaluo            float,
   @w_fecha_avaluo          datetime,
   @w_mun_garantia          int,
   @w_ubicacion             catalogo,
   @w_perito_aval           descripcion,
   @w_nomina                char(3),
   @w_deudor_otras          char(3),
   @w_sum_provisiona        money,
   @w_provisiona            char(3),
   @w_tipo_productor        varchar(24),
   @w_actividad             varchar(24),
   @w_aprobado_por          varchar(24),
   @w_fecha_aprobacion      datetime,
   @w_tipo_linea            catalogo,
   @w_margen_redescuento    float,
   @w_clase         	    varchar(24),
   @w_calificacion          catalogo,
   @w_clausula_aplicada     char(1),
   @w_fec_clausula          datetime,
   @w_reestructuracion      char(1),
   @w_numero_reest          int,
   @w_dias_vencimiento      int,
   @w_estado                tinyint,
   @w_nro_recibo            varchar(10),
   @w_fec_calificacion      datetime,
   @w_cuotas_vencidas       int,
   @w_cuotas_pagadas        int,
   @w_cuotas_pendientes     int,
   @w_saldo_actual          money,
   @w_operacion             int, --- variables para Generacion de Otro si
   @w_dia_final             int,
   @w_mes_final             int,
   @w_ano_final             int,
   @w_maxsec_abono          int,
   @w_nom_banco             varchar(70),
   @w_dia_imp               int,
   @w_mes_imp               int,
   @w_ano_imp               int,
   @w_cedula                varchar(30),
   @w_nombre                descripcion,
   @w_nit                   varchar(30),
   @w_nombre_ofi            varchar(70),
   @w_nom_ciudad            varchar(50),
   @w_nombre_oficina        descripcion,
   @w_mod_obligacion        descripcion,
   @w_nom_estado            descripcion,
   @w_periodo_pago          descripcion,
   @w_regional              smallint,
   @w_otorgamiento          datetime,
   @w_ultimo_pago           datetime,
   @w_estado_juridico       varchar(10),
   @w_fec_est_juridico      datetime,
   @w_deudor                varchar(255),
   @w_codeudor              varchar(255),
   @w_des_regional          varchar(64),
   @w_cuota_int             money,
   @w_neto_cap              money,
   @w_neto_ded              money,
   @w_max_dividendo         int,
   @w_concepto_int_ant      catalogo,
   @w_concepto_segvida      catalogo,
   @w_cuota_seg             money,
   @w_fecha                 datetime,
   @w_codmoneda             tinyint,
   @w_num_dec               tinyint,
   @w_tipo_superior         catalogo,
   @w_codeudor_cur          varchar(255),
   @w_op_direccion          tinyint,
   @w_fecha_crear           datetime,
   @w_parametro_fag         catalogo,
   @w_cuota_fag             money,
   @w_iva_fag               money,
   @w_concepto_iva_fag      catalogo,
   @w_cap                   money,
   @w_rowcount              int,
   @w_rol                   char(1),
   @w_ent_convenio          catalogo,
   @w_mensaje				varchar(150), --CEH REQ264 PARA CHEQUES SIN CRUCE RESTRICTIVO
   @w_banco                 cuenta,
   @w_fecha_proceso         datetime,
   @w_proceso               int,
   --variables para bcp   
   @w_path_destino          varchar(100),
   @w_s_app                 varchar(50),
   @w_cmd                   varchar(255),   
   @w_comando               varchar(255),
   @w_nombre_archivo        varchar(255),  
   @w_anio                  varchar(4),
   @w_mes                   varchar(2),
   @w_dia                   varchar(2),
   @w_msg                   descripcion,
   @w_nemonico_alz          varchar(10),
   @w_pdf                   varchar(124),
   @w_p_apellido            varchar(16),
   @w_tipo_mail             catalogo,
   @w_mail                  descripcion,
   @w_dir_banco             varchar(255),
   @w_ciu_ofici             varchar(255),
   @w_tel_ofici             varchar(16),
   @w_filial                tinyint   ,
   @w_contador              int,
   @w_errores               varchar(255),
   --Variables FTP
   @w_passcryp               varchar(255),
   @w_login                  varchar(255),
   @w_password		         varchar(255),
   @w_FtpServer		         varchar(50),
   @w_tmpfile                varchar(100),
   @w_return                 int,
   @w_path_plano             varchar(255),
   @w_formato_fecha          int,
   @s_user                   varchar(30),
   @w_alianza                int,
   @w_desalianza             varchar(255),
   @w_envia_mail             descripcion,
   @w_mail_alianza           descripcion
  
if isnull(@i_param3,'T') = 'T' 
   select @i_param3 = null

if isnull(@i_param4,0) = 0
   select @i_param4 = null
   
       
delete tmp_rubros_op_msv where spid = @@spid
delete from cob_cartera..ca_liquida_msv
where li_opbanco >= ''

-- CAPTURA NOMBRE DE STORED PROCEDURE
select @w_sp_name = 'sp_imprimir_liquidacion_msv'

if exists (select 1 from sysobjects where name = 'tmp_plano_liq_msv')
   drop table tmp_plano_liq_msv

create table tmp_plano_liq_msv (cadena varchar(1000) not null)

select  @w_formato_fecha = 103,--@w_param6,
        @w_fecha_proceso = getdate(),
        @w_proceso       = 7969,
        @s_user          = 'sa'


-- CODIGO DEL INTERES ANTICIPADO
select @w_concepto_int_ant = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INTANT'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 710256
   goto ERROR
end

-- CODIGO DEL SEGURO DE VIDA
select @w_concepto_segvida = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'SEGURO'
select @w_rowcount = @@rowcount 
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 710256
   goto ERROR
end

/*CODIGO DEL RUBRO COMISION FAG */
select @w_parametro_fag = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFAG'
set transaction isolation level read uncommitted


-- CODIGO TIPO SUPERIOR DE LA GARANTIA HIPOTECARIA
select @w_tipo_superior = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'GARHIP'
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 1901014
   goto ERROR
end

select banco = op_banco, estado = 'I'
into #operaciones
from ca_operacion with (nolock), cob_credito..cr_tramite with (nolock)
where op_fecha_liq between @i_param1 and @i_param2
and   tr_tramite    = op_tramite
and  (tr_alianza    = @i_param4 or @i_param4 is null)
and   tr_alianza is not null
and   op_estado not in (0,3,99) 
and  (op_toperacion = @i_param3 or @i_param3 is null)

delete tmp_plano_liq_msv
where cadena >= ''

-- CABECERA DE LA IMPRESION
while 1 = 1 begin
   set rowcount 1
   

   select @w_banco = banco
   from #operaciones
   where estado = 'I'
   order by banco
   
   if @@rowcount = 0 begin
      break
   end
   
   set rowcount 0
     
   select @w_tabla = codigo
   from   cobis..cl_tabla
   where  tabla = 'ca_toperacion'
   
   select @w_anterior            = op_anterior,
          @w_tramite             = op_tramite,
          @w_cliente             = op_cliente,
          @w_fecha_crea          = substring(convert(varchar,op_fecha_ini,@w_formato_fecha),1,15),
          @w_toperacion          = op_toperacion,
          @w_moneda              = op_moneda,
          @w_moneda_desc         = mo_descripcion,
          @w_monto_aprobado      = op_monto_aprobado,
          @w_destino             = op_destino,
          @w_ciudad_desc         = ci_descripcion,
          @w_oficina             = op_oficina,
          @w_lin_credito         = op_lin_credito,
          @w_plazo               = op_plazo,
          @w_tplazo              = op_tplazo,
          @w_tipo_amortizacion   = op_tipo_amortizacion,
          @w_tdividendo          = op_tdividendo,
          @w_periodo_cap         = op_periodo_cap,
          @w_periodo_int         = op_periodo_int,
          @w_gracia              = isnull(di_gracia,0),
          @w_toperacion_desc     = A.valor,
          @w_gracia_cap          = op_gracia_cap,
          @w_gracia_int          = op_gracia_int,
          @w_cuota               = op_cuota,
          @w_tipo_cobro          = op_tipo_cobro,
          @w_mes_gracia          = op_mes_gracia,
          @w_operacionca         = op_operacion ,
          @w_fecha_fin           = substring(convert(varchar,op_fecha_fin,@w_formato_fecha),1,15),
          @w_tipo_linea          = op_tipo_linea,
          @w_margen_redescuento  = op_margen_redescuento,
          @w_clase               = op_clase,
          @w_calificacion        = op_calificacion,
          @w_clausula_aplicada   = op_clausula_aplicada,
          @w_fec_clausula        = op_fecha_ult_proceso,
          @w_reestructuracion    = op_reestructuracion,
          @w_numero_reest        = op_numero_reest,
          @w_dias_vencimiento    = op_edad,
          @w_estado              = op_estado,
          @w_nombre              = op_nombre,
          @w_otorgamiento        = isnull(op_fecha_ini,''),
          @w_op_direccion        = isnull(op_direccion,1),
          @w_ent_convenio        = op_entidad_convenio
   from   ca_operacion
                inner join cobis..cl_moneda on 
                       op_banco     = @w_banco
                       and op_moneda    = mo_moneda
                       and op_banco     = @w_banco
                       and op_moneda    = mo_moneda
                       inner join cobis..cl_ciudad on
                            op_ciudad    = ci_ciudad                                                        
                            inner join cobis..cl_catalogo A on
                                A.codigo = op_toperacion                                
                                   left outer join ca_dividendo on
                                   op_operacion  = di_operacion
                                   where tabla = @w_tabla
                                   and di_estado    = 1
   
   if @@rowcount = 0
   begin
      PRINT 'impdatop.sp operacion C'
      select @w_error = 710026
      goto ERROR
   end  
     exec sp_decimales
        @i_moneda    = @w_moneda, 
        @o_decimales = @w_num_dec out
        
   -- Validar Entidad Convenio
   
   if @w_ent_convenio is not null and @w_ent_convenio <> ' '
      select @w_nomina = 'Si'
   else
      select @w_nomina = 'No'
        
   -- Validacion de reestructuracion
   
   if @w_numero_reest > 0
      select @w_reestructuracion = 'N'
   else
      select @w_reestructuracion = 'S'
      
   -- validar tipo de amortizacion
   
   if @w_tipo_amortizacion = 'FRANCESA'
      select @w_tipo_amortizacion = 'CUOTA FIJA'
   else
      if @w_tipo_amortizacion = 'ALEMANA'
         select @w_tipo_amortizacion = 'CAPITAL FIJO'      
      else
         select @w_tipo_amortizacion = 'TABLA MANUAL'      
         
   -- Clase Cartera
   
   select @w_clase = rtrim(@w_clase) + ' - '  + b.valor
   from cobis..cl_tabla a, cobis..cl_catalogo b
   where b.tabla  = a.codigo
   and   b.codigo = @w_clase
   and   a.tabla  = 'cr_clase_cartera'
         
   -- MONTO DESEMBOLSADO SIN QUE ESTE AFECTADO POR LA CAPITALIZACION
   select @w_monto = ro_valor 
   from   ca_rubro_op
   where  ro_operacion = @w_operacionca
   and    ro_concepto = 'CAP'
   and    ro_tipo_rubro = 'C'
   
   select @w_cedula     = en_ced_ruc,
          @w_p_apellido = rtrim(p_p_apellido)
   from   cobis..cl_ente
   where  en_ente = @w_cliente
   set transaction isolation level read uncommitted
   
   select @w_nom_estado = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'ca_estado'
   and    b.codigo = a.tabla
   and    a.codigo = convert(varchar, @w_estado)
   set transaction isolation level read uncommitted
   
   select @w_periodo_pago = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'ca_tdividendo'
   and    b.codigo = a.tabla
   and    a.codigo = @w_tdividendo
   set transaction isolation level read uncommitted
   
   select @w_mod_obligacion = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'ca_toperacion'
   and    b.codigo = a.tabla
   and    a.codigo = @w_toperacion
   set transaction isolation level read uncommitted
   
   select @w_nombre_oficina = of_nombre,
          @w_regional = of_regional 
   from   cobis..cl_oficina
   where  of_oficina = @w_oficina
   set transaction isolation level read uncommitted
   
   select @w_des_regional = A.valor
   from   cobis..cl_catalogo A,cobis..cl_tabla B
   where  B.codigo = A.tabla
   and    B.tabla  = 'cl_oficina'
   and    A.codigo = convert(varchar(10),@w_regional)
   set transaction isolation level read uncommitted
   
   if @w_estado = 96
   begin
      select @w_estado_juridico = 'Juridico'
      
      select @w_fec_est_juridico = tr_fecha_mov 
      from   ca_transaccion
      where  tr_operacion = @w_operacionca 
   end
   ELSE
      select @w_estado_juridico = 'Normal'
   
 
      select @w_secuencial = max(dm_secuencial)
      from   ca_desembolso
      where  dm_operacion = @w_operacionca
  
   
   select @w_liquidacion = min(dm_secuencial)
   from   ca_desembolso
   where  dm_operacion = @w_operacionca
   
   select @w_monto_retenido = isnull(sum(ro_valor),0)
   from   ca_rubro_op
   where  ro_operacion = @w_operacionca 
   and    ro_fpago     = 'L'
   
   if @w_secuencial = @w_liquidacion
   begin
      -- SE COBRAN INTERESES ANTICIPADOS SOLO EN LA LIQUIDACION
      select @w_int_ant = sum(am_cuota)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion  = @w_operacionca
      and    am_dividendo  = 1
      and    ro_operacion  = @w_operacionca
      and    ro_concepto   = am_concepto
      and    ro_fpago      = 'A'
      
      select @w_monto_retenido = @w_monto_retenido + isnull(@w_int_ant,0)
   end
   
   select @w_dir_comercial = di_descripcion,
          @w_tel_comercial = te_valor 
  from   cobis..cl_telefono
          left outer join cobis..cl_direccion on 
                  di_direccion = te_direccion
                  and di_ente  = te_ente
                  where di_direccion  = @w_op_direccion
                  and   di_ente       = @w_cliente
   set transaction isolation level read uncommitted
   
   select @w_fec_nacimiento = p_fecha_nac,
          @w_sexo = p_sexo,
          @w_oficina = en_oficina 
   from   cobis..cl_ente
   where  en_ente = @w_cliente
   set transaction isolation level read uncommitted
   
   select @w_ciudad_comercial = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'cl_ciudad'
   and    b.codigo = a.tabla
   and    a.codigo = (select convert(varchar, di_ciudad)
                      from   cobis..cl_direccion 
                      where  di_ente      = @w_cliente
                      and    di_direccion = @w_op_direccion
                      group  by di_ciudad)
   set transaction isolation level read uncommitted
   
   select @w_tabla = codigo
   from   cobis..cl_tabla
   where  tabla = 'ca_toperacion'
   set transaction isolation level read uncommitted
   
   select @w_toperacion_desc = valor
   from   cobis..cl_catalogo
   where  tabla  = @w_tabla
   and    codigo = @w_toperacion
   set transaction isolation level read uncommitted
   
   select @w_tabla = codigo
   from   cobis..cl_tabla
   where  tabla = 'cr_objeto'
   set transaction isolation level read uncommitted
   
   select @w_destini_desc = valor
   from   cobis..cl_catalogo
   where  tabla = @w_tabla 
   and    codigo = @w_destino
   set transaction isolation level read uncommitted
   
   select @w_tplazo = td_descripcion 
   from   ca_tdividendo
   where  td_tdividendo = @w_tplazo
   
   select @w_tdividendo= td_descripcion 
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo
   
   select @w_tasa          = isnull(sum(ro_porcentaje_efa) ,0),
          @w_tasa_ef_anual = isnull(sum(ro_porcentaje_efa) ,0)
   from   ca_rubro_op
   where  ro_operacion  =  @w_operacionca
   and    ro_tipo_rubro =  'I'
   and    ro_fpago      in ('P','A')
   
   select @w_tasa_referencial = ro_referencial,
          @w_signo_spread = ro_signo,
          @w_valor_spread = ro_factor,
          @w_pactado      = ro_fpago,
          @w_valor_referencial = ro_porcentaje_aux,
          @w_tipo_puntos = ro_tipo_puntos
   from   ca_rubro_op
   where  ro_operacion  =  @w_operacionca
   and    ro_tipo_rubro =  'I'
   and    ro_fpago in ('P','A')
   
   
   -- Valida forma de pago de los intereses
   
   if @w_pactado = 'P'
      select @w_pactado = 'Vencido'
   else
      if @w_pactado = 'A'
         select @w_pactado = 'Anticipado'
      else
         select @w_pactado = 'No Definido'
   
   select @w_recibo = -1
   
   select @w_recibo = isnull(tr_dias_calc,-1),
          @w_oficina = tr_ofi_usu
   from   ca_transaccion
   where  tr_operacion = @w_operacionca
   and    tr_tran        = 'DES'
   and    tr_secuencial  = @w_secuencial
   
   -- GENERACION DEL NUMERO DE RECIBO
    exec @w_error = sp_numero_recibo
    @i_tipo       = 'G',
    @i_oficina    = @w_oficina,
    @i_secuencial = @w_recibo,
    @o_recibo     = @w_nro_recibo out
   
   if @w_error <> 0
   begin
       select @w_error = @w_error
       goto ERROR
   end
   
     exec sp_calcula_saldo
     @i_operacion = @w_operacionca,
     @i_tipo_pago = @w_tipo_cobro,
     @o_saldo     = @w_saldo_actual out        
   
   select @w_recursos = dt_categoria
   from   ca_default_toperacion
   where  dt_toperacion = @w_toperacion
   
   select @w_fec_ult_pago = max(tr_fecha_mov)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = dtr_operacion
   and    tr_operacion = @w_operacionca
   
   select @w_ultimo_pago = max(ab_fecha_ing)
   from   ca_abono
   where  ab_estado = 'A'
   and    ab_operacion = @w_operacionca
   
   select @w_con_seguros = count(*) 
   from   ca_concepto,ca_rubro_op
   where  co_concepto = ro_concepto
   and    co_categoria = 'S'
   and    co_concepto = @w_concepto_segvida
   and    ro_operacion = @w_operacionca
   
   if @w_con_seguros > 0
      select @w_seguro_vida = 'Si'
   else
      select @w_seguro_vida = 'No'
   
   select @w_con_otros_seg = count(*)
   from   ca_concepto, ca_rubro_op
   where  co_concepto = ro_concepto
   and    co_categoria = 'S'
   and   co_concepto <> @w_concepto_segvida
   and   ro_operacion = @w_operacionca
   
   if @w_con_otros_seg > 0
       select @w_otros_seguros = 'Si'
   else
       select @w_otros_seguros = 'No'
   
   select @w_cuotas_vencidas = count(*) from ca_dividendo
   where  di_estado = 2
   and    di_operacion = @w_operacionca 
   
   select @w_cuotas_pagadas = count(*) from ca_dividendo
   where  di_estado = 3
   and    di_operacion = @w_operacionca 
   
   select @w_cuotas_pendientes = count(*) from ca_dividendo
   where  di_estado <> 3
   and    di_operacion = @w_operacionca 
   
   -- PARA GARANTIA HIPOTECARIA
   select @w_tipo_garantia = cu_tipo,
          @w_des_garantia  = cu_descripcion,
          @w_vlr_avaluo    = cu_valor_inicial,
          @w_fecha_avaluo  = cu_fecha_insp,
          @w_mun_garantia  = cu_ciudad_prenda,
          @w_codigo_externo= cu_codigo_externo
   from   cob_custodia..cu_custodia,
          cob_credito..cr_gar_propuesta,
          cob_custodia..cu_tipo_custodia
   where  cu_codigo_externo = gp_garantia
   and    tc_tipo_superior = @w_tipo_superior --parametro GARHIP
   and    cu_estado = 'V'
   and    cu_tipo in (tc_tipo)
   and    gp_tramite = @w_tramite
   
--INI AGI.  Se comenta porque campo cu_ubicacion en la tabla cu_custodia   
/*   
   select @w_ubicacion = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'cu_ubicacion_doc'
   and    b.codigo = a.tabla
   and    a.codigo = (select cu_ubicacion
                      from   cob_custodia..cu_custodia
                      where  cu_codigo_externo = @w_codigo_externo)
   set transaction isolation level read uncommitted
 */--FIN AGI
 
   select @w_par_matricula = pa_char 
   from   cobis..cl_parametro
   where  pa_nemonico = 'MAINM' 
   and    pa_producto = 'GAR'
   set transaction isolation level read uncommitted
   
   select @w_matricula = ic_valor_item 
   from   cob_custodia..cu_item,
          cob_custodia..cu_item_custodia,
          cob_credito..cr_gar_propuesta
   where  it_item      = ic_item 
   and    gp_garantia  = ic_codigo_externo
   and    it_nombre    = @w_par_matricula --(parametro numero notaria)
   and    gp_tramite   = @w_tramite
   and    ic_tipo_cust = @w_tipo_garantia
   
   select @w_par_escritura = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'ESCRI'
   and    pa_producto = 'GAR'
   set transaction isolation level read uncommitted
   
   select @w_escritura = ic_valor_item 
   from   cob_custodia..cu_item, cob_custodia..cu_item_custodia,
          cob_credito..cr_gar_propuesta
   where  it_item       = ic_item
   and    gp_garantia   = ic_codigo_externo
   and    it_nombre     = @w_par_escritura --(PARAMETRO NUMERO NOTARIA)
   and    gp_tramite    = @w_tramite
   and    ic_tipo_cust  = @w_tipo_garantia
   
   select @w_par_notaria = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'NOTARI'
   and    pa_producto = 'GAR'
   set transaction isolation level read uncommitted
   
   select @w_notaria = ic_valor_item
   from   cob_custodia..cu_item,
          cob_custodia..cu_item_custodia,
          cob_credito..cr_gar_propuesta
   where  it_item       = ic_item 
   and    gp_garantia   = ic_codigo_externo
   and    it_nombre     = @w_par_notaria --PARAMETRO NUMERO NOTARIA
   and    gp_tramite    = @w_tramite
   and    ic_tipo_cust  = @w_tipo_garantia
   
   select @w_perito_aval = is_nombre
   from   cob_custodia..cu_inspeccion,
          cob_custodia..cu_inspector
   where  in_codigo_externo = @w_codigo_externo
   and    in_inspector =is_inspector
   and    in_fecha_insp = (select max(in_fecha_insp)
                           from   cob_custodia..cu_inspeccion
                           where  in_codigo_externo = @w_codigo_externo)
   
   select @w_con_deudor = count(1)
   from   cob_credito..cr_deudores
   where  de_cliente = @w_cliente
   
   if @w_con_deudor > 1 
      select @w_deudor_otras = 'Si'
   else
      select @w_deudor_otras = 'No'
   
   select @w_fec_calificacion = max(co_fecha)
   from   cob_credito..cr_calificacion_op
   where  co_operacion = @w_operacionca
   and    co_producto  = 7
   
   select @w_sum_provisiona = sum(co_prov_cap  + co_prov_int  + co_prov_ctasxcob +
                                  co_prova_cap + co_prova_int + co_prova_ctasxcob)
   from   cob_credito..cr_calificacion_op
   where  co_operacion = @w_operacionca
   and    co_producto  = 7
   
   if @w_sum_provisiona > 0 
      select @w_provisiona = 'Si'
   else
      select @w_provisiona = 'No'
   
   select @w_tipo_productor = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'tr_tipo_productor'
   and    b.codigo = a.tabla
   and    a.codigo = (select tr_tipo_productor
                      from   cob_credito..cr_tramite
                      where  tr_tramite = @w_tramite)
   set transaction isolation level read uncommitted
   
   select @w_actividad = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'tr_destino'
   and    b.codigo = a.tabla
   and    a.codigo = (select tr_destino
                      from   cob_credito..cr_tramite
                      where  tr_tramite = @w_tramite)
   set transaction isolation level read uncommitted
   
   select @w_aprobado_por = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'tr_comite'
   and    b.codigo = a.tabla
   and    a.codigo = (select tr_comite
                      from   cob_credito..cr_tramite
                      where  tr_tramite = @w_tramite)
   set transaction isolation level read uncommitted
   
   select @w_fecha_aprobacion = tr_fecha_apr
   from   cob_credito..cr_tramite 
   where  tr_tramite = @w_tramite
      
   -- TASA EN EFECTIVO ANUAL
    exec @w_error = sp_control_tasa
        @i_operacionca     = @w_operacionca,
        @i_temporales      = 'N',
        @i_ibc             = 'N',
        @o_tasa_total_efe  = @w_tasa_ef_anual  output
   
   if @w_error <> 0
   begin
      goto ERROR
   end
   
   select @w_deudor = '(' +convert(varchar(30),de_ced_ruc) + ' ) ' + case when en_subtipo = 'C' then en_nombre else substring(rtrim(en_nombre) + ' ' + rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido),1,30) end
   from   cob_credito..cr_deudores, cobis..cl_ente with (nolock)
   where  de_tramite= @w_tramite
   and    de_cliente = en_ente
      and    ltrim(rtrim(de_rol))  = 'D'


   if @w_tramite is null
   begin
      select @w_codeudor = 'NO TIENE'
   end
   else
   begin   
      select @w_codeudor = ''
      declare codeudores cursor
          for select  '(' + convert(varchar(30),de_ced_ruc) + ' ) ' + case when en_subtipo = 'C' then en_nombre else substring(rtrim(en_nombre) + ' ' + rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido),1,30) end
               from   cob_credito..cr_deudores, cobis..cl_ente with (nolock)
               where  de_tramite= @w_tramite
               and    de_cliente = en_ente
               and    ltrim(rtrim(de_rol))  <> 'D'
               for read only
               
       open codeudores
               
       fetch codeudores
       into  @w_codeudor_cur
            
       while @@fetch_status = 0 -- WHILE CURSOR CODEUDORES
       begin
          if (@@fetch_status = -1) 
          begin
              select @w_error = 710004
              goto ERROR
          end
          
          select @w_codeudor = @w_codeudor + ' >> ' + @w_codeudor_cur
                     
          fetch codeudores
          into  @w_codeudor_cur
       end -- WHILE CURSOR CODEUDORES
       
       close codeudores
       deallocate codeudores
       select @w_codeudor = substring(@w_codeudor,6,255)
   end
   
   --print 'hola8'
   if  @w_secuencial > @w_liquidacion
   begin
   
       --Unicamente el rubro CAPITAL
       insert into   tmp_rubros_op_msv
       select 0,
              ro_concepto,
              co_descripcion,
              dm_monto_mn,
              @@spid
       from   ca_desembolso, 
              ca_concepto,
              ca_rubro_op
       where  ro_operacion = @w_operacionca
       and    co_concepto   = ro_concepto
       and    ro_tipo_rubro = 'C'  
       and    ro_operacion = dm_operacion
       and    dm_secuencial = @w_secuencial
       order by ro_tipo_rubro, ro_concepto

       select @w_contador = 0
       update tmp_rubros_op_msv set
       @w_contador = @w_contador +1 , ro_secuencia = @w_contador
       where ro_secuencia >= 0

       select @w_neto_cap = isnull(sum(ro_valor),0) 
       from   tmp_rubros_op_msv
       where  ro_concepto = 'CAP'
       and   spid = @@spid
      
       select @w_neto_ded = isnull(sum(ro_valor),0) 
       from   tmp_rubros_op_msv
       where  ro_concepto <> 'CAP'
       and   spid = @@spid
    end
    else
    begin
        /*RUTINA PARA INCLUIR VALORES RENOVADOS*/
        declare @w_renovaciones money

        select @w_renovaciones = 0
        if exists(select 1
                  from ca_operacion,
                       cob_credito..cr_op_renovar
                  where op_operacion = @w_operacionca
                  and   or_tramite   = op_tramite)
        begin

           select @w_renovaciones = isnull(sum(or_saldo_original),0)
           from ca_operacion,
                cob_credito..cr_op_renovar
           where op_operacion = @w_operacionca
           and   or_tramite   = op_tramite

             if @w_renovaciones > 0
             begin
                 insert into   tmp_rubros_op_msv
                 (ro_concepto, co_descripcion, ro_valor, spid)
                 values
                 ('RENOVACION', 'Creditos  ', @w_renovaciones, @@spid)

                update tmp_rubros_op_msv
                 set ro_valor = ro_valor - @w_renovaciones
                 from ca_producto
                 where ro_concepto = cp_producto
             end
       end
       /*FIN RUTINA NUEVA PARA VALORES RENOVADOS */
      
       --Cambios por Credito Rotativo
       insert into tmp_rubros_op_msv
       select 0,
              dtr_concepto,
              co_descripcion,
              dtr_monto_mn,
              @@spid
       from ca_transaccion,
            ca_det_trn,
            ca_concepto
       where tr_operacion = @w_operacionca
       and tr_secuencial = @w_secuencial
       and tr_tran = 'DES'
       and tr_operacion = dtr_operacion
       and tr_secuencial = dtr_secuencial
       and dtr_concepto   = co_concepto
       and (dtr_concepto <> 'APERCRED' or dtr_estado <> 3)  --jpe
       and    dtr_codvalor <> 10099
       and    dtr_codvalor <> 10019
       and    dtr_codvalor <> 10370 
       and    dtr_codvalor <> 10990   
       order by dtr_concepto

       select @w_contador = 0
       update tmp_rubros_op_msv set
       @w_contador = @w_contador +1 , ro_secuencia = @w_contador
       where ro_secuencia >= 0

       if @@rowcount > 0 
       begin
           select @w_neto_cap = isnull(sum(ro_valor),0) 
           from   tmp_rubros_op_msv
           where  ro_concepto = 'CAP'
           and    spid = @@spid
                
           select @w_neto_ded = isnull(sum(t.ro_valor),0) 
           from   tmp_rubros_op_msv t,
                  ca_rubro_op c
           where  t.ro_concepto <> 'CAP'
           and    c.ro_concepto = t.ro_concepto
           and    ro_operacion = @w_operacionca
           and    spid = @@spid

           select @w_neto_ded = @w_neto_ded + @w_renovaciones		--Mroa: Valor neto despues de renovaciones

           update tmp_rubros_op_msv
           set ro_valor = ro_valor - @w_renovaciones
           from ca_producto
           where ro_concepto = cp_producto
       end 
    end  

   select @w_mensaje = 'Cheque de Gerencia marcado sin cruce restrictivo, no olvide levantar el sello antes de entregar el cheque.'

-- DEUDORES DE LA OPERACION
   select @w_cliente = op_cliente,
          @w_oficina = op_oficina,
          @w_oficial = op_oficial,
          @w_fecha_crear = op_fecha_ini,
          @w_monto_aprobado = op_monto,
          @w_op_direccion   = op_direccion
   from ca_operacion
   where op_banco = @w_banco
   
   if @w_op_direccion is null
      select @w_op_direccion = en_direccion
      from cobis..cl_ente
      where en_ente = @w_cliente
      set transaction isolation level read uncommitted
      
   select @w_filial = pa_tinyint 
   from cobis..cl_parametro
   where pa_nemonico = 'FILIAL'
   and   pa_producto = 'CRE'
   set transaction isolation level read uncommitted 
   
   select @w_dir_banco = fi_direccion 
   from cobis..cl_filial
   where   fi_filial = @w_filial      
   set transaction isolation level read uncommitted 
      
   select @w_tipo_mail = pa_char 
   from cobis..cl_parametro
   where pa_producto = 'MIS'
   and pa_nemonico = 'TDW'
   set transaction isolation level read uncommitted
   
   select @w_ciu_ofici   = ci_descripcion
   from cobis..cl_oficina, cobis..cl_ciudad
   where of_oficina = @w_oficina
   and   of_ciudad  = ci_ciudad
   set transaction isolation level read uncommitted   
   
   select @w_tel_ofici  = to_valor
   from cobis..cl_oficina, cobis..cl_telefono_of
   where of_oficina  = @w_oficina
   and   to_oficina  = of_oficina
   and   of_telefono = to_secuencial
   set transaction isolation level read uncommitted   
   
   -- ENCUENTRA EL PRODUCTO
   select @w_tipo = pd_tipo
   from   cobis..cl_producto
   where  pd_producto = 7
   set transaction isolation level read uncommitted

   -- ENCUENTRA EL DETALLE DE PRODUCTO
   select @w_det_producto = dp_det_producto
   from   cobis..cl_det_producto
   where  dp_producto = 7
   and    dp_tipo   = @w_tipo
   and    dp_moneda = @w_moneda
   and    dp_cuenta = @w_banco

   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0 
   begin
      --INSERTAR EL PRODUCTO PARA FUTURAS IMPRESIONES

      select @w_det_producto = cl_det_producto 
      from cobis..cl_cliente
      where cl_cliente = @w_cliente
      and cl_rol = 'D'

        insert into cobis..cl_det_producto (
         dp_det_producto,            dp_oficina,              dp_producto,
         dp_tipo,                    dp_moneda,               dp_fecha, 
         dp_comentario,              dp_monto,                dp_cuenta,
         dp_estado_ser,              dp_autorizante,          dp_oficial_cta, 
         dp_tiempo,                  dp_valor_inicial,        dp_tipo_producto,
         dp_tprestamo,               dp_valor_promedio,       dp_rol_cliente,
         dp_filial,                  dp_cliente_ec,           dp_direccion_ec)   
         values (                    
         @w_det_producto,            @w_oficina,  7, 
         'R',                        @w_moneda,               @w_fecha_crear, 
         'OPERACION ACTUALIZADA IMP',@w_monto_aprobado,       @w_banco, 
         'V',                        @w_oficial,              1,
         0,                          0,                       '0',
         0,                          0,                       'T',
         1,                          @w_cliente,              1)        
       
       update cobis..cl_ente
       set    en_cliente = 'S'
       where  en_ente = @w_cliente         

       if @@error <> 0 return 710002


   end
   
   if not exists (select 1 from cobis..cl_cliente
                  where cl_cliente = @w_cliente
                  and cl_det_producto = @w_det_producto)
   begin
      
      select @w_cedula = en_ced_ruc
      from cobis..cl_ente
      where en_ente = @w_cliente
      set transaction isolation level read uncommitted

      insert into cobis..cl_cliente (
      cl_cliente,cl_det_producto,cl_rol,cl_ced_ruc,cl_fecha)
      values
      (
       @w_cliente, @w_det_producto,'D',@w_cedula,@w_fecha_crear
      )
   end

   select @w_rol =   cl_rol
   from cobis..cl_cliente 
   where cl_cliente =  @w_cliente      
   and cl_det_producto = @w_det_producto 
   
   select top 1 * into #direccion
   from cobis..cl_direccion
   where di_ente = @w_cliente
   and   di_direccion = @w_op_direccion
   
   select top 1 * into #telefono
   from cobis..cl_telefono
   where te_ente = @w_cliente
   and   te_direccion = @w_op_direccion
   
   
   if (@w_rol is null ) or (@w_rol  = '')
   begin
		update  cobis..cl_cliente
		set cl_rol = 'D'
        where cl_cliente =  @w_cliente      
        and cl_det_producto = @w_det_producto 
   end

   select @w_desalianza   = '-',
          @w_nemonico_alz = null,
          @w_alianza      = null,
          @w_envia_mail   = null,
          @w_mail_alianza = null
   
   --BUSCA LA ALIANZA A LA CUAL PERTENECE EL CLIENTE
   select @w_alianza = al_alianza,
          @w_desalianza = isnull((al_nemonico + ' - ' + al_nom_alianza), '  '),
          @w_nemonico_alz = isnull(ltrim(rtrim(al_nemonico)),'  '),
          @w_envia_mail   = al_envia_mail,
          @w_mail_alianza = al_mail_alianza
   from cobis..cl_alianza_cliente with (nolock),
         cobis..cl_alianza         with (nolock)
   where ac_ente    = @w_cliente
     and ac_alianza = al_alianza
     and al_estado  = 'V'
     and ac_estado  = 'V'
     
   if @w_envia_mail = 'S'
   begin 
      select 
      @i_param5 = 'S',
      @w_mail   = ''
          
      if @w_mail_alianza = 'S'
      begin
         select top 1 @w_mail = di_descripcion 
         from   cobis..cl_alianza with (nolock), 
                cobis..cl_direccion with (nolock),
                cobis..cl_alianza_cliente with (nolock)
         where  al_ente     = di_ente
         and    ac_alianza  = al_alianza
         and    ac_ente     = @w_cliente 
         and    di_tipo     = @w_tipo_mail
         and    di_descripcion is not null
         order by di_direccion desc
         
         if @w_mail is null
         begin
            select 
            @w_error = 720010,
            @w_msg   = 'La alianza Debe tener un correo electronico'
            GOTO ERROR
         end
      end   
      else
      begin
         select @w_mail = isnull(di_descripcion,'')   
         from   cobis..cl_direccion 
         where  di_ente      = @w_cliente
         and    di_tipo      = @w_tipo_mail 
            
         if @w_mail is null
         begin
            select top 1 @w_mail = di_descripcion 
            from   cobis..cl_alianza, 
                   cobis..cl_direccion
            where  al_ente = di_ente
            and    di_tipo = @w_tipo_mail
            order by di_direccion desc
         
            if @w_mail is null
            begin
               select 
               @w_error = 720011,
               @w_msg   = 'No se tiene direccion de correo del cliente ni de la alianza'
               GOTO ERROR
            end
         end
      end
   end

   if (select count(*) from tmp_rubros_op_msv where ro_concepto = 'RENOVACION') = 0
      select @w_renovacion = 'N'
   else
      select @w_renovacion = 'S'

   -- Armar nombre PDF

   select @w_anio = convert(varchar(4),datepart(yyyy,@i_param2)),
          @w_mes = convert(varchar(2),datepart(mm,@i_param2)), 
          @w_dia = convert(varchar(2),datepart(dd,@i_param2))  

   select @w_fecha_arch  = (@w_anio + right('00' + @w_mes,2) + right('00'+ @w_dia,2))

   select @w_pdf = isnull(@w_nemonico_alz,'EMPTY') + '_LD_' + isnull(@w_p_apellido,'EMPTY')  + '_' + right(isnull(@w_cedula, 'EMPTY'),3) + right(isnull(rtrim(@w_banco), 'EMPTY'),3)+'_' + @w_fecha_arch + '.pdf'

   /********************DESEMBOLSO******************/
   insert into cob_cartera..ca_liquida_msv  
   select 
   li_opbanco            =       isnull (rtrim(@w_banco), ''),
   li_regional           =       isnull (@w_des_regional, ''),
   li_dir_comercial      =       isnull (SUBSTRING(@w_dir_comercial,1,100), ''),
   li_telef_comercial    =       isnull (@w_tel_comercial, ''),
   li_ciudad_comercial   =       isnull (SUBSTRING(@w_ciudad_comercial,1,50), ''),
   --li_fecha_naci         =       isnull (convert(varchar(12),@w_fec_nacimiento,101) ,''),
   li_fecha_naci         =       isnull (@w_fec_nacimiento,''),
   li_sexo               =       isnull (@w_sexo ,''),
   li_tipo_operacion     =       isnull (@w_tipo_linea, ''),
   li_seguro_vida        =       isnull (@w_seguro_vida, ''),
   li_otros_seguros      =       isnull (@w_otros_seguros, ''),
   li_recursos           =       isnull (@w_recursos, ''),
   li_margen_redes       =       isnull (convert(varchar(12),@w_margen_redescuento), ''),
   --li_fecha_ult_pago     =       isnull (convert(varchar(12),@w_fec_ult_pago,101), ''),
   li_fecha_ult_pago     =       isnull (@w_fec_ult_pago, ''),
   li_valor_ult_pago     =       isnull (convert(varchar(12),@w_vlr_ult_pago), ''),
   li_tipo_productor     =       isnull (@w_tipo_productor,  ''),
   li_actividad          =       isnull (@w_actividad, ''),
   li_saldo_actual       =       isnull (convert(varchar(12),@w_saldo_actual), ''),
   li_pactado            =       isnull (@w_pactado, ''),
   li_clase              =       isnull (@w_clase, ''),
   li_tipo_amortizacion  =       isnull (@w_tipo_amortizacion, ''),
   li_calificacion       =       isnull (@w_calificacion, ''),
   li_cuota              =       isnull (@w_cuota, ''),
   li_provisiona         =       isnull (@w_provisiona, ''),
   --li_fec_calificacion   =       isnull (convert(varchar(12),@w_fec_calificacion,101), ''),
   li_fec_calificacion   =       isnull (@w_fec_calificacion, ''),
   li_aprobado_por       =       isnull (@w_aprobado_por, ''),                                                                                                                                                                                                                                                                                                      
   li_nomina             =       isnull (@w_nomina, ''),                                                                                                                                                                                                                                                                                                            
   li_monto_aprobado     =       isnull (convert(varchar(12),@w_monto_aprobado), ''),
   --li_fecha_aprobacion   =       isnull (convert(varchar(12),@w_fecha_aprobacion,101), ''),
   li_fecha_aprobacion   =       isnull (@w_fecha_aprobacion, ''),
   li_matricula          =       isnull (@w_matricula, ''),
   li_escritura          =       isnull (@w_escritura, ''),
   li_notaria            =       isnull (@w_notaria, ''),
   li_tipo_garantia      =       isnull (@w_tipo_garantia, ''),                                                                                                                                                                                                                                                                                                     
   li_des_garantia       =       isnull (@w_des_garantia, ''),                                                                                                                                                                                                                                                                                                      
   li_vlr_avaluo         =       isnull (convert(varchar(12), @w_vlr_avaluo),''),                                                                                                                                                                                                                                                                                   
   --li_fecha_avaluo       =       isnull (convert(varchar(12), @w_fecha_avaluo,101), ''),                                                                                                                                                                                                                                                                
   li_fecha_avaluo       =       isnull (@w_fecha_avaluo, ''),                                                                                                                                                                                                                                                                
   li_ubicacion          =       isnull (@w_ubicacion, ''),                                                                                                                                                                                                                                                                                                         
   li_mun_garantia       =       isnull (convert(varchar(12),@w_mun_garantia), ''),                                                                                                                                                                                                                                                                                 
   li_perito_aval        =       isnull (@w_perito_aval, ''),                                                                                                                                                                                                                                                                                                       
   li_dias_venc          =       isnull ('0', ''),                                                                                                                                                                                                                                                                                                                  
   li_nom_estado         =       isnull (SUBSTRING(@w_nom_estado,1,20), ''),
   li_cuotas_vencidas    =       isnull (convert(varchar(3),@w_cuotas_vencidas), ''),                                                                                                                                                                                                                                                                               
   li_cuotas_pagadas     =       isnull (convert(varchar(3),@w_cuotas_pagadas), ''),                                                                                                                                                                                                                                                                                
   li_cuotas_pendientes  =       isnull (convert(varchar(3),@w_cuotas_pendientes), ''),                                                                                                                                                                                                                                                                             
   li_estado_juridico    =       isnull (@w_estado_juridico, ''),                                                                                                                                                                                                                                                                                                   
   --li_fec_est_juridico   =       isnull (convert(varchar(12),@w_fec_est_juridico,101), ''),                                                                                                                                                                                                                                                            
   li_fec_est_juridico   =       isnull (@w_fec_est_juridico, ''),                                                                                                                                                                                                                                                            
   li_clausula_aplicada  =       isnull (@w_clausula_aplicada, ''),                                                                                                                                                                                                                                                                                                 
   --li_fec_clausula       =       isnull (convert(varchar(12), @w_fec_clausula, 103), ''),                                                                                                                                                                                                                                                              
   li_fec_clausula       =       isnull (@w_fec_clausula, ''),                                                                                                                                                                                                                                                              
   li_reestructuracion   =       isnull (@w_reestructuracion, ''),                                                                                                                                                                                                                                                                                                 
   li_anterior           =       isnull (@w_anterior, ''),                                                                                                                                                                                                                                                                                                          
   li_numero_reest       =       isnull (convert(varchar(3),@w_numero_reest), ''),
   li_oficina            =       isnull (convert(varchar(5),@w_oficina), ''),
   li_deudor_otras       =       isnull (@w_deudor_otras, ''),
   li_tasa               =       isnull (convert(varchar(12),@w_tasa), ''),
   li_tasa_referencial   =       isnull (@w_tasa_referencial, ''),
   li_nombre_oficina     =       isnull (substring(@w_nombre_oficina,1,20), ''),
   li_banco              =       isnull (@w_banco, ''),
   li_nombre             =       isnull (substring(@w_nombre,1,50), ''),
   li_mod_obligacion     =       isnull (substring(@w_mod_obligacion,1,50), ''),
   li_periodo_pago       =       isnull (@w_periodo_pago, ''),
   li_gracia_int         =       isnull (convert(varchar(3),@w_gracia_int), ''),
   li_nom_estado1        =       isnull (@w_nom_estado, ''),
   li_monto              =       isnull (convert(varchar(12),@w_monto), ''),
   --li_otorgamiento       =       isnull (convert(varchar(12), @w_otorgamiento, 101), ''),
   li_otorgamiento       =       isnull (@w_otorgamiento, ''),
   --li_fecha_fin          =       isnull (convert(varchar(12),@w_fecha_fin,@w_formato_fecha), ''),
   li_fecha_fin          =       isnull (@w_fecha_fin, ''),
   li_destino            =       isnull (@w_destino, ''),
   li_cedula             =       isnull (@w_cedula, ''),
   li_ultimo_pago        =       isnull (@w_ultimo_pago, ''),
   li_deudor             =       isnull (@w_deudor, ''),
   li_codeudor           =       isnull (@w_codeudor, ''),
   li_moneda_desc        =       isnull (substring(@w_moneda_desc,1,30), ''),
   li_moneda             =       isnull (convert(varchar(1),@w_moneda), ''),
   li_cliente            =       isnull (convert(varchar(9),@w_cliente), ''),
   li_fecha_proceso      =       isnull (@w_fecha_proceso, ''),
   li_neto_cap           =       isnull (convert(varchar(12),@w_neto_cap), ''),
   li_neto_deduc         =       isnull (convert(varchar(12),@w_neto_ded), ''),
                                                                                                                                                                                                                                                                                                                                                              
   -- Conceptos          =       -- Conceptos
   li_num                =       isnull (convert(varchar(3),dm_desembolso), ''),
   li_grupo              =       'D',
   li_concepto           =       isnull (substring(cp_descripcion,1,40), ''),
   li_valor              =       isnull (case @w_renovacion when 'N' then convert(varchar(12),dm_monto_mds) else convert(varchar(12),dm_monto_mn) end, ''),
                                                                                                                                                                                                                                                                                                                                                     
   -- Beneficiarios      =       -- Beneficiarios                                                                                                                                                                                                                                                                                                            
   li_moneda1            =       isnull (substring(mo_descripcion,1,6), ''),
   li_cotizacion         =       isnull (convert(varchar(12),dm_cotizacion_mds), '0'),                                                                                                                                                                                                                                                                               
   li_cuenta             =       isnull (dm_cuenta, ''),                                                                                                                                                                                                                                                                                                            
   li_beneficiario       =       isnull (substring(dm_beneficiario,1,50), ''),                                                                                                                                                                                                                                                                                      
   li_cruze_reestrictivo =       isnull (case dm_cruce_restrictivo when 'N' then @w_mensaje else '' end, ''),                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                                                                                                              
   -- Cliente            =       -- Cliente                                                                                                                                                                                                                                                                                                                   
   li_rol                =       isnull (cl_rol, ''),                                                                                                                                                                                                                                                                                                               
   li_cliente            =       isnull (convert(varchar(12),cl_cliente), ''),                                                                                                                                                                                                                                                                                      
   li_cedula             =       isnull (SUBSTRING(cl_ced_ruc,1,13), ''),                                                                                                                                                                                                                                                                                           
   li_pasaporte          =       isnull (SUBSTRING(p_pasaporte,1,13), ''),                                                                                                                                                                                                                                                                                          
   li_telefono           =       isnull (te_valor, ''),                                                                                                                                                                                                                                                                                                             
   li_direccion          =       isnull (substring(di_descripcion,1,100), ''),                                                                                                                                                                                                                                                                                      
   li_nombre             =       isnull (case when en_subtipo = 'C' then en_nombre else ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre),1,60)) end , ''),                                                                                                                                                                   
   li_nombre_pdf         =       isnull (@w_pdf, ''),                                                                                                                                                                                                                                                                                                               
   li_correo             =       case when @i_param5 = 'S' then isnull (@w_mail, '')else '' end,                                                                                                                                                                                                                                                                                                              
   li_direc_banco        =       isnull (@w_dir_banco, ''),                                                                                                                                                                                                                                                                                                         
   li_ciudad_ofi         =       isnull (@w_ciu_ofici, ''),                                                                                                                                                                                                                                                                                                         
   li_telef_ofi          =       isnull (@w_tel_ofici, ''),
   li_alianza            =       isnull (@w_alianza,   ''),
   li_des_alianza        =       isnull (@w_desalianza, '-')
   from /*cob_cartera..tmp_rubros_op_msv, */
   cob_cartera..ca_operacion
         inner join  cob_cartera..ca_desembolso on
                 dm_operacion    = op_operacion
                 
                    inner join   cobis..cl_moneda on
                    dm_moneda       = mo_moneda
                    
                       inner join  cob_cartera..ca_producto on
                       dm_producto     = cp_producto 
                       
                       inner join  cobis..cl_det_producto on
                       dp_producto     = 7                          
                       and dp_cuenta = op_banco
                       
                          left outer join  cobis..cl_cliente on
                          dp_det_producto      = cl_det_producto
                          
                             left outer join  cobis..cl_ente on
                             cl_det_producto = @w_det_producto 
                             and en_ente     = cl_cliente
                             
                                left outer join #telefono on
                                en_ente = te_ente
                                and te_direccion  = @w_op_direccion
                                
                                   left outer join #direccion on
                                   cl_cliente = di_ente 
                                   and di_direccion  = @w_op_direccion
                                   

   where  dm_secuencial   = @w_secuencial
   and    dm_operacion    = @w_operacionca
   and    cl_rol          = 'D'
   order by dm_desembolso, cl_cliente

   
   /******************************RUBROS**********************/
   insert into cob_cartera..ca_liquida_msv 
   select 
   li_opbanco            =       isnull (rtrim(@w_banco), ''),
   li_regional           =       isnull (@w_des_regional, ''),
   li_dir_comercial      =       isnull (SUBSTRING(@w_dir_comercial,1,100), ''),
   li_telef_comercial    =       isnull (@w_tel_comercial, ''),
   li_ciudad_comercial   =       isnull (SUBSTRING(@w_ciudad_comercial,1,50), ''),
   li_fecha_naci         =       isnull (@w_fec_nacimiento,''),
   li_sexo               =       isnull (@w_sexo ,''),
   li_tipo_operacion     =       isnull (@w_tipo_linea, ''),
   li_seguro_vida        =       isnull (@w_seguro_vida, ''),
   li_otros_seguros      =       isnull (@w_otros_seguros, ''),
   li_recursos           =       isnull (@w_recursos, ''),
   li_margen_redes       =       isnull (convert(varchar(12),@w_margen_redescuento), ''),
   li_fecha_ult_pago     =       isnull (@w_fec_ult_pago, ''),
   li_valor_ult_pago     =       isnull (convert(varchar(12),@w_vlr_ult_pago), ''),
   li_tipo_productor     =       isnull (@w_tipo_productor,  ''),
   li_actividad          =       isnull (@w_actividad, ''),
   li_saldo_actual       =       isnull (convert(varchar(12),@w_saldo_actual), ''),
   li_pactado            =       isnull (@w_pactado, ''),
   li_clase              =       isnull (@w_clase, ''),
   li_tipo_amortizacion  =       isnull (@w_tipo_amortizacion, ''),
   li_calificacion       =       isnull (@w_calificacion, ''),
   li_cuota              =       isnull (@w_cuota, ''),
   li_provisiona         =       isnull (@w_provisiona, ''),
   li_fec_calificacion   =       isnull (@w_fec_calificacion, ''),
   li_aprobado_por       =       isnull (@w_aprobado_por, ''),                                                                                                                                                                                                                                                                                                      
   li_nomina             =       isnull (@w_nomina, ''),                                                                                                                                                                                                                                                                                                            
   li_monto_aprobado     =       isnull (convert(varchar(12),@w_monto_aprobado), ''),
   li_fecha_aprobacion   =       isnull (@w_fecha_aprobacion, ''),
   li_matricula          =       isnull (@w_matricula, ''),
   li_escritura          =       isnull (@w_escritura, ''),
   li_notaria            =       isnull (@w_notaria, ''),
   li_tipo_garantia      =       isnull (@w_tipo_garantia, ''),                                                                                                                                                                                                                                                                                                     
   li_des_garantia       =       isnull (@w_des_garantia, ''),                                                                                                                                                                                                                                                                                                      
   li_vlr_avaluo         =       isnull (convert(varchar(12), @w_vlr_avaluo),''),                                                                                                                                                                                                                                                                                   
   li_fecha_avaluo       =       isnull (@w_fecha_avaluo, ''),                                                                                                                                                                                                                                                                
   li_ubicacion          =       isnull (@w_ubicacion, ''),                                                                                                                                                                                                                                                                                                         
   li_mun_garantia       =       isnull (convert(varchar(12),@w_mun_garantia), ''),                                                                                                                                                                                                                                                                                 
   li_perito_aval        =       isnull (@w_perito_aval, ''),                                                                                                                                                                                                                                                                                                       
   li_dias_venc          =       isnull ('0', ''),                                                                                                                                                                                                                                                                                                                  
   li_nom_estado         =       isnull (SUBSTRING(@w_nom_estado,1,20), ''),
   li_cuotas_vencidas    =       isnull (convert(varchar(3),@w_cuotas_vencidas), ''),                                                                                                                                                                                                                                                                               
   li_cuotas_pagadas     =       isnull (convert(varchar(3),@w_cuotas_pagadas), ''),                                                                                                                                                                                                                                                                                
   li_cuotas_pendientes  =       isnull (convert(varchar(3),@w_cuotas_pendientes), ''),                                                                                                                                                                                                                                                                             
   li_estado_juridico    =       isnull (@w_estado_juridico, ''),                                                                                                                                                                                                                                                                                                   
   li_fec_est_juridico   =       isnull (@w_fec_est_juridico, ''),                                                                                                                                                                                                                                                            
   li_clausula_aplicada  =       isnull (@w_clausula_aplicada, ''),                                                                                                                                                                                                                                                                                                 
   li_fec_clausula       =       isnull (@w_fec_clausula, ''),                                                                                                                                                                                                                                                              
   li_reestructuracion   =       isnull (@w_reestructuracion, ''),                                                                                                                                                                                                                                                                                                 
   li_anterior           =       isnull (@w_anterior, ''),                                                                                                                                                                                                                                                                                                          
   li_numero_reest       =       isnull (convert(varchar(3),@w_numero_reest), ''),
   li_oficina            =       isnull (convert(varchar(5),@w_oficina), ''),
   li_deudor_otras       =       isnull (@w_deudor_otras, ''),
   li_tasa               =       isnull (convert(varchar(12),@w_tasa), ''),
   li_tasa_referencial   =       isnull (@w_tasa_referencial, ''),
   li_nombre_oficina     =       isnull (substring(@w_nombre_oficina,1,20), ''),
   li_banco              =       isnull (@w_banco, ''),
   li_nombre             =       isnull (substring(@w_nombre,1,50), ''),
   li_mod_obligacion     =       isnull (substring(@w_mod_obligacion,1,50), ''),
   li_periodo_pago       =       isnull (@w_periodo_pago, ''),
   li_gracia_int         =       isnull (convert(varchar(3),@w_gracia_int), ''),
   li_nom_estado1        =       isnull (@w_nom_estado, ''),
   li_monto              =       isnull (convert(varchar(12),@w_monto), ''),
   li_otorgamiento       =       isnull (@w_otorgamiento, ''),
   --li_fecha_fin          =       isnull (convert(varchar(12),@w_fecha_fin,@w_formato_fecha), ''),
   li_fecha_fin          =       isnull (@w_fecha_fin, ''),
   li_destino            =       isnull (@w_destino, ''),
   li_cedula             =       isnull (@w_cedula, ''),
   li_ultimo_pago        =       isnull (@w_ultimo_pago, ''),
   li_deudor             =       isnull (@w_deudor, ''),
   li_codeudor           =       isnull (@w_codeudor, ''),
   li_moneda_desc        =       isnull (substring(@w_moneda_desc,1,30), ''),
   li_moneda             =       isnull (convert(varchar(1),@w_moneda), ''),
   li_cliente            =       isnull (convert(varchar(9),@w_cliente), ''),
   li_fecha_proceso      =       isnull (@w_fecha_proceso, ''),
   li_neto_cap           =       isnull (convert(varchar(12),@w_neto_cap), ''),
   li_neto_deduc         =       isnull (convert(varchar(12),@w_neto_ded), ''),
                                                                                                                                                                                                                                                                                                                                                              
   -- Conceptos          =       -- Conceptos
   li_num                =       ro_secuencia ,
   li_grupo              =       'R',
   li_concepto           =       isnull (substring(ro_concepto, 1, 20), ''),
   li_valor              =       isnull (convert(varchar(12), ro_valor), ''),
                                                                                                                                                                                                                                                                                                                                                   
   -- Beneficiarios      =       -- Beneficiarios                                                                                                                                                                                                                                                                                                             
   li_moneda1            =       null, --isnull (substring(mo_descripcion,1,6), ''),
   li_cotizacion         =       0,                                                                                                                                                                                                                                                                             
   li_cuenta             =       null,                                                                                                                                                                                                                                                                                                            
   li_beneficiario       =       null,                                                                                                                                                                                                                                                                                      
   li_cruze_reestrictivo =       null,                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                                                                                                              
   -- Cliente            =       -- Cliente                                                                                                                                                                                                                                                                                                                   
   li_rol                =       isnull (cl_rol, ''),                                                                                                                                                                                                                                                                                                               
   li_cliente            =       isnull (convert(varchar(12),cl_cliente), ''),                                                                                                                                                                                                                                                                                      
   li_cedula             =       isnull (SUBSTRING(cl_ced_ruc,1,13), ''),                                                                                                                                                                                                                                                                                           
   li_pasaporte          =       isnull (SUBSTRING(p_pasaporte,1,13), ''),                                                                                                                                                                                                                                                                                          
   li_telefono           =       isnull (te_valor, ''),                                                                                                                                                                                                                                                                                                             
   li_direccion          =       isnull (substring(di_descripcion,1,100), ''),                                                                                                                                                                                                                                                                                      
   li_nombre             =       isnull (case when en_subtipo = 'C' then en_nombre else ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre),1,60)) end , ''),                                                                                                                                                                   
   li_nombre_pdf         =       isnull (@w_pdf, ''),                                                                                                                                                                                                                                                                                                               
   li_correo             =       case when @i_param5 = 'S' then isnull (@w_mail, '')else '' end,                                                                                                                                                                                                                                                                                                              
   li_direc_banco        =       isnull (@w_dir_banco, ''),                                                                                                                                                                                                                                                                                                         
   li_ciudad_ofi         =       isnull (@w_ciu_ofici, ''),                                                                                                                                                                                                                                                                                                         
   li_telef_ofi          =       isnull (@w_tel_ofici, ''),
   li_alianza            =       isnull (@w_alianza,   ''),
   li_des_alianza        =       isnull (@w_desalianza, '')
   from cob_cartera..tmp_rubros_op_msv, 
   cob_cartera..ca_operacion
         /*inner join  cob_cartera..ca_desembolso on
                 dm_operacion    = op_operacion*/
                 
                    inner join   cobis..cl_moneda on
                    op_moneda       = mo_moneda  -op_moneda
                    
                      /* inner join  cob_cartera..ca_producto on
                       dm_producto     = cp_producto */
                       
                       inner join  cobis..cl_det_producto on
                       dp_producto     = 7                          
                       and dp_cuenta = op_banco
                       
                          left outer join  cobis..cl_cliente on
                          dp_det_producto      = cl_det_producto
                          
                             left outer join  cobis..cl_ente on
                             cl_det_producto = @w_det_producto 
                             and en_ente     = cl_cliente
                             
                                left outer join #telefono on
                                en_ente = te_ente
                                and te_direccion  = @w_op_direccion
                                
                                   left outer join #direccion on
                                   cl_cliente = di_ente 
                                   and di_direccion  = @w_op_direccion
                                         

   where  /*dm_secuencial   = @w_secuencial
   and    */op_operacion    = @w_operacionca
   and    cl_rol          = 'D'
   order by  ro_concepto, cl_cliente

   drop table #direccion
   drop table #telefono
 
   update #operaciones 
   set estado = 'P'
   where banco = @w_banco 

   delete tmp_rubros_op_msv
   where  spid = @@spid   
   
end -- while
set rowcount 0

insert into tmp_plano_liq_msv (cadena) 
   select 
   -- Cabecera
   isnull(rtrim(li_opbanco),                                        ' ') + '|' +
   isnull(li_regional,                                              ' ') + '|' + isnull(SUBSTRING(li_dir_comercial,1,100),                          ' ') + '|' + isnull(li_telef_comercial,                                           ' ') + '|' + 
   isnull(SUBSTRING(li_ciudad_comercial,1,50),                      ' ') + '|' + isnull(convert(varchar(12),li_fecha_naci,@w_formato_fecha),        ' ') + '|' + isnull(li_sexo,                                                    ' ') + '|' + 
   isnull(li_tipo_operacion,                                        ' ') + '|' + isnull(li_seguro_vida,                                             ' ') + '|' + isnull(li_otros_seguros,                                           ' ') + '|' + 
   isnull(li_recursos,                                              ' ') + '|' + isnull(convert(varchar(12),li_margen_redes),                       ' ') + '|' + isnull(convert(varchar(12),li_fecha_ult_pago,@w_formato_fecha),      ' ') + '|' + 
   isnull(convert(varchar(12),li_valor_ult_pago),                   ' ') + '|' + isnull(li_tipo_productor,                                          ' ') + '|' + isnull(li_actividad ,                                               ' ') + '|' + 
   isnull(convert(varchar(12),li_saldo_actual),                     ' ') + '|' + isnull(li_pactado,                                                 ' ') + '|' + isnull(li_clase ,                                                   ' ') + '|' + 
   isnull(li_tipo_amortizacion,                                     ' ') + '|' + isnull(li_calificacion,                                            ' ') + '|' + isnull(convert(varchar(12),li_cuota),                              ' ') + '|' + 
   isnull(li_provisiona,                                            ' ') + '|' + isnull(convert(varchar(12),li_fec_calificacion,@w_formato_fecha),  ' ') + '|' + isnull(li_aprobado_por,                                            ' ') + '|' + 
   isnull(li_nomina,                                                ' ') + '|' + isnull(convert(varchar(12),li_monto_aprobado),                     ' ') + '|' + isnull(convert(varchar(12),li_fecha_aprobacion,@w_formato_fecha),  ' ') + '|' + 
   isnull(li_matricula,                                             ' ') + '|' + isnull(li_escritura,                                               ' ') + '|' + isnull(li_notaria,                                                 ' ') + '|' + 
   isnull(li_tipo_garantia,                                         ' ') + '|' + isnull(li_des_garantia,                                            ' ') + '|' + isnull(convert(varchar(12),li_vlr_avaluo ),                         ' ') + '|' + 
   isnull(convert(varchar(12),li_fecha_avaluo,@w_formato_fecha),    ' ') + '|' + isnull(li_ubicacion,                                               ' ') + '|' + isnull(convert(varchar(12),li_mun_garantia),                       ' ') + '|' + 
   isnull(li_perito_aval,                                           ' ') + '|' + isnull('0',                                                        ' ') + '|' + isnull(SUBSTRING(li_nom_estado,1,20),                              ' ') + '|' + 
   isnull(convert(varchar(3),li_cuotas_vencidas),                   ' ') + '|' + isnull(convert(varchar(3),li_cuotas_pagadas),                      ' ') + '|' + isnull(convert(varchar(3),li_cuotas_pendientes),                   ' ') + '|' + 
   isnull(li_estado_juridico,                                       ' ') + '|' + isnull(convert(varchar(12),li_fec_est_juridico,@w_formato_fecha),  ' ') + '|' + isnull(li_clausula_aplicada,                                       ' ') + '|' + 
   isnull(convert(varchar(12), li_fec_clausula, @w_formato_fecha),  ' ') + '|' + isnull(li_reestructuracion ,                                       ' ') + '|' + isnull(li_anterior ,                                                ' ') + '|' + 
   isnull(convert(varchar(3),li_numero_reest),                      ' ') + '|' + isnull(convert(varchar(5),li_oficina),                             ' ') + '|' + isnull(li_deudor_otras,                                            ' ') + '|' + 
   isnull(convert(varchar(12),li_tasa),                             ' ') + '|' + isnull(li_tasa_referencial ,                                       ' ') + '|' + isnull(substring(li_nombre_oficina,1,20),                          ' ') + '|' + 
   isnull(li_banco,                                                 ' ') + '|' + isnull(substring(li_nombre,1,50),                                  ' ') + '|' + isnull(substring(li_mod_obligacion,1,50),                          ' ') + '|' + 
   isnull(li_periodo_pago,                                          ' ') + '|' + isnull(convert(varchar(3),li_gracia_int),                          ' ') + '|' + isnull(li_nom_estado1,                                              ' ') + '|' + 
   isnull(convert(varchar(12),li_monto),                            ' ') + '|' + isnull(convert(varchar(12), li_otorgamiento, @w_formato_fecha),    ' ') + '|' + isnull(convert(varchar(12),li_fecha_fin,@w_formato_fecha),         ' ') + '|' + 
   isnull(li_destino,                                               ' ') + '|' + isnull(li_cedula,                                                  ' ') + '|' + isnull(convert(varchar(12),li_ultimo_pago,@w_formato_fecha),       ' ') + '|' + 
   isnull(li_deudor,                                                ' ') + '|' + isnull(li_codeudor,                                                ' ') + '|' + isnull(substring(li_moneda_desc,1,30),                             ' ') + '|' + 
   isnull(convert(varchar(1),li_moneda),                            ' ') + '|' + isnull(convert(varchar(9),li_cliente),                             ' ') + '|' + isnull(convert(varchar(12), li_fecha_proceso, @w_formato_fecha),   ' ') + '|' + 
   isnull(convert(varchar(12),li_neto_cap),                         ' ') + '|' + isnull(convert(varchar(12),li_neto_deduc),                         ' ') + '|' + 

   -- Conceptos
   isnull(convert(varchar(12),li_num),                              ' ') + '|' +  isnull(substring(li_grupo, 1, 2),                                 ' ') + '|' +  isnull(substring(li_concepto, 1, 20),                              ' ') + '|' + 
   isnull(convert(varchar(12), li_valor),                           ' ') + '|' +

   -- Beneficiarios
   
   isnull(substring(li_moneda1,1,6),                                ' ') + '|' +  isnull(convert(varchar(12),li_cotizacion),                        '0') + '|' +   isnull(li_cuenta,                                                ' ') + '|' +  
   isnull(substring(li_beneficiario,1,50),                          ' ') + '|' +  isnull(li_cruze_reestrictivo,' ') + '|' +

   -- Cliente
   isnull(li_rol,                                                   ' ') + '|' + isnull(convert(varchar(12),li_cliente),                            ' ') + '|' + isnull(SUBSTRING(li_cedula,1,13),                                 ' ') + '|' +
   isnull(SUBSTRING(li_pasaporte,1,13),                             ' ') + '|' + isnull(li_telefono,                                                ' ') + '|' + isnull(substring(li_direccion,1,100),                            ' ') + '|' +
   isnull(li_nombre,                                                ' ') + '|' + isnull(li_nombre_pdf,                                              ' ') + '|' + isnull(li_correo,                                                    ' ') + '|' + 
   isnull(li_direc_banco,                                           ' ') + '|' + isnull(li_ciudad_ofi,                                              ' ') + '|' + isnull(li_telef_ofi,                                               ' ') + '|' +
   isnull(li_alianza,                                               ' ') + '|' + isnull(li_des_alianza,                                             ' ') 

   from cob_cartera..ca_liquida_msv
   order by li_opbanco, li_concepto, li_cliente 

/* GENERACION ARCHIVO PLANO */
   Print '--> Path Archivo Resultante'

   select @w_path_destino = ba_path_destino
   from cobis..ba_batch
   where ba_batch = @w_proceso

   if @@rowcount = 0 Begin
      select @w_error = 720004,
      @w_msg = 'No Existe path_destino para el proceso : ' +  cast(@w_proceso as varchar)
      GOTO ERROR
   end 

   select @w_s_app = pa_char
   from cobis..cl_parametro
   where pa_producto = 'ADM'
   and   pa_nemonico = 'S_APP'
   
   if @@rowcount = 0 Begin
      select @w_error = 720014,
      @w_msg = 'NO EXISTE RUTA DEL S_APP'
      GOTO ERROR   
   end 

   select @w_path_plano = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'MIS'
   and    pa_nemonico = 'PATHEC'   

   -- Arma Nombre del Archivo
   print 'Generar el archivo plano LIQUIDACION_CARTERA_MSV_AAAAMMDD.txt !!!!! ' 

   select @w_nombre_archivo = @w_path_destino + 'LIQUIDACION_CARTERA_MSV_' + @w_fecha_arch + '.txt' 
   print @w_nombre_archivo

   select @w_cmd       =  'bcp "select cadena from cob_cartera..tmp_plano_liq_msv" queryout ' 
   select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t"|" -T -S'+ @@servername + ' -eLIQUIDACION_CARTERA_MSV.err' 
   --print @w_comando
   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 Begin
      select @w_msg = 'Error Generando BCP ' + @w_comando
      goto ERROR 
   end   



/* OBTIENE USUARIO PARA FTP EL CUAL SE INGRESA DESDE EL MODULO DE SEGURIDAD */
select @w_passcryp = up_password,
       @w_login  = up_login
from   cobis..ad_usuario_xp
where  up_equipo = 'F'

if @@rowcount = 0 begin
  print 'Error lectura Usuario Notificador de Correos '
  return 1
end

/* DESCIFRA PASSWORD */
exec @w_return = CIFRAR...xp_decifrar 
     @i_data = @w_passcryp,
     @o_data = @w_password out

if @w_return <> 0
begin
  print 'Error lectura Usuario Notificador de Correos '
  return 1
end 

/* OBTIENE DIRECCION DEL SERVIDOR FTP */
select @w_FtpServer = pa_char
from   cobis..cl_parametro
where  pa_producto = 'MIS'
and    pa_nemonico = 'FTPSRV'
if @@rowcount = 0 begin
  print 'Error lectura Servidor de Notificacion de Correos '
  return 1 
end

/* ELIMINA ARCHIVO INSTRUCCIONES FTP */
select @w_tmpfile = @w_path_destino + @s_user + '_' + 'fuente_ftp_liqui'

select @w_tmpfile

select @w_cmd = 'del ' + @w_tmpfile 
exec xp_cmdshell @w_cmd

/* CREA ARCHIVO INSTRUCCIONES FTP */
select @w_cmd = 'echo '  + @w_login +  '>> ' + @w_tmpfile 
exec xp_cmdshell @w_cmd

select @w_cmd = 'echo ' +  @w_password + '>> ' + @w_tmpfile 
exec xp_cmdshell @w_cmd

select @w_cmd = 'echo ' + 'cd tablas_liquidacion\a_procesar '  + ' >> ' + @w_tmpfile 
exec xp_cmdshell @w_cmd

select @w_cmd = 'echo ' + 'put  ' + @w_nombre_archivo + ' >> ' + @w_tmpfile 

exec xp_cmdshell @w_cmd

if @w_error <> 0 begin
   print 'ERROR Realizando Transferencia de Correo '
   return -1 
end 


select @w_cmd = 'echo ' + 'quit ' + '>> ' + @w_tmpfile 
exec xp_cmdshell @w_cmd
  
/* EJECUTA FTP */
select @w_cmd = 'ftp -s:' + @w_tmpfile + ' ' + @w_FtpServer
exec xp_cmdshell @w_cmd

if @@error <> 0  Begin
   print 'Error Transfiriendo Extracto a Notificador de Correos'
   return 1
end
  
select @w_cmd = 'del ' + @w_tmpfile 
exec xp_cmdshell @w_cmd


return 0

ERROR:
delete tmp_rubros_op_msv where spid = @@spid
print 'Error No Detectado'
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error
go

