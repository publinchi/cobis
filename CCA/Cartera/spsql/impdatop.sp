/************************************************************************/
/*   Nombre Fisico:        impdatop.sp                                  */
/*   Nombre Logico:        sp_imprimir_datos_op                         */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:   	      Francisco Yacelga                         */
/*   Fecha de escritura:   02/Dic./1997                                 */
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
/*   Imprimir informacion general del prestamo                          */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre         Proposito                        */
/*      29/Ene/2003   Luis Mayorga    Generacion de nuevos campos(45)   */
/*                                    requeridos por banco agrario      */
/*      15/Jun/2004   Elcira Pelaez   Cursor para envio de datos de code*/
/*                                    udores                            */
/*      May 12 2006   Elcira Pelaez   Defecto        6452               */
/*      Jul 07 2006   Elcira Pelaez   Cambio RFP 296 c.Rotativo         */
/*      Jul 11 2006   Elcira Pelaez   def. 6836 incluye lode C.rotativo */
/*                                    no afecta produccion              */
/*      Ago 23 2006   Elcira Pelaez   def. 7064  BAC                    */
/*      Jul 04 2007   Elcira Pelaez   def. 8361-8431  BAC               */
/*      Dic 23 2014   Luis C. Moreno  CCA 436: Normalizacion de Cartera */
/*      Jun 1  2015   A. Celis        INC 1187 Cambio Linea Finagro     */
/*      19/Abr/2022   K. Rodríguez   Cambio catálogo destino finan. op  */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'tmp_rubros_op_i')
   drop table tmp_rubros_op_i
go

create table tmp_rubros_op_i
(
ro_concepto     catalogo,
co_descripcion  descripcion,
ro_valor        money,
spid            int
)-- lock datarows
go


if exists (select 1 from sysobjects where name = 'sp_imprimir_datos_op')
   drop proc sp_imprimir_datos_op
go

---INC. 117213.SEP.2014

create proc sp_imprimir_datos_op
@s_sesn           int         = null,
@s_date           datetime    = null,
@s_user           login       = null,
@s_term           descripcion = null,
@s_corr           char(1)     = null,
@s_ssn_corr       int         = null,
@s_ofi            smallint    = null,
@t_rty            char(1)     = null,
@t_debug          char(1)     = 'N',
@t_file           varchar(14) = null,
@t_trn            smallint    = null,  
@i_operacion      char(1)     = null,
@i_formato_fecha  int         = null,
@i_banco          cuenta      = null,
@i_moneda         tinyint     = null,
@i_secuencial     int    = null

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
   @w_mensaje				    varchar(150), ---CEH REQ264 PARA CHEQUES SIN CRUCE RESTRICTIVO
   @w_alianza               int,                                 -- REQ 353: Alianzas
   @w_desalianza            varchar(255),
   @w_concepto              varchar(10)

        
delete tmp_rubros_op_i where spid = @@spid
-- CAPTURA NOMBRE DE STORED PROCEDURE
select @w_sp_name = 'sp_imprimir_datos_op'

select  @i_formato_fecha = 101


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

-- CABECERA DE LA IMPRESION
if @i_operacion = 'C'
begin
   select @w_tabla = codigo
   from   cobis..cl_tabla
   where  tabla = 'ca_toperacion'
   
   select @w_anterior            = op_anterior,
          @w_tramite             = op_tramite,
          @w_cliente             = op_cliente,
          @w_fecha_crea          = substring(convert(varchar,op_fecha_ini,@i_formato_fecha),1,15),
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
          @w_fecha_fin           = substring(convert(varchar,op_fecha_fin,@i_formato_fecha),1,15),
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
          @w_otorgamiento        = op_fecha_ini,
          @w_op_direccion        = isnull(op_direccion,1),
          @w_ent_convenio        = op_entidad_convenio
   from   ca_operacion
                inner join cobis..cl_moneda on 
                       op_banco     = @i_banco
                       and op_moneda    = mo_moneda
                       and op_banco     = @i_banco
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
   
   select @w_cedula = en_ced_ruc
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
   
   if @i_secuencial is null
   begin
      select @w_secuencial = max(dm_secuencial)
      from   ca_desembolso
      where  dm_operacion = @w_operacionca
   end
   ELSE
      select @w_secuencial = @i_secuencial
   
   select @w_liquidacion = min(dm_secuencial)
   from   ca_desembolso
   where  dm_operacion = @w_operacionca
   and    dm_estado <> 'RV'
   
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
   
   if exists (select 1 from cob_credito..cr_seguros_tramite        -- Req. 366 Seguros
             where st_tramite = @w_tramite)
   begin

      select @w_tasa          = isnull(sum(ro_porcentaje_aux) ,0),
             @w_tasa_ef_anual = isnull(sum(ro_porcentaje_efa) ,0)
      from   ca_rubro_op
      where  ro_operacion  =  @w_operacionca
      and    ro_tipo_rubro =  'I'
      and    ro_fpago      in ('P','A')

   end
   else
   begin
               
      select @w_tasa          = isnull(sum(ro_porcentaje_efa) ,0),
             @w_tasa_ef_anual = isnull(sum(ro_porcentaje_efa) ,0)
      from   ca_rubro_op
      where  ro_operacion  =  @w_operacionca
      and    ro_tipo_rubro =  'I'
      and    ro_fpago      in ('P','A')
      
   end
   
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

   
   select @w_fecha = max(vr_fecha_vig)
   from   ca_valor_referencial
   where  vr_tipo     = @w_tasa_referencial 
   and    vr_fecha_vig <= @s_date
   
   select @w_secuencial_ref = max(vr_secuencial)
   from   ca_valor_referencial
   where  vr_tipo     = @w_tasa_referencial 
   and    vr_fecha_vig  = @w_fecha
   
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
 
--INI AGI. 22ABR19.  Se comenta porque no se encuentra el campo cu_ubicacion en la tabla cu_custodia
/* 
   select @w_ubicacion = valor 
   from   cobis..cl_catalogo a, cobis..cl_tabla b
   where  b.tabla = 'cu_ubicacion_doc'
   and    b.codigo = a.tabla
   and    a.codigo = (select cu_ubicacion
                      from   cob_custodia..cu_custodia
                      where  cu_codigo_externo = @w_codigo_externo)
   set transaction isolation level read uncommitted
*/ --FIN AGI

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
   
   -- TASA BASICA REFERENCIAL
   select @w_valor_base = vr_valor
   from   ca_valor_referencial
   where  vr_tipo      = @w_tasa_referencial
   and    vr_secuencial = @w_secuencial_ref
   
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

---EPB15JUN2004   CURSOR CODEUDORES
if @w_tramite = null
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
 ---EPB15JUN2004   CURSOR CODEUDORES           
end
   if  @w_secuencial > @w_liquidacion
   begin
       --Unicamente el rubro CAPITAL
       insert into   tmp_rubros_op_i
       select ro_concepto,
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

       select @w_neto_cap = isnull(sum(ro_valor),0) 
       from   tmp_rubros_op_i
       where  ro_concepto = 'CAP'
       and   spid = @@spid
      
       select @w_neto_ded = isnull(sum(ro_valor),0) 
       from   tmp_rubros_op_i
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
             
                 if exists(select 1 from cob_credito..cr_normalizacion
                           where nm_tramite = @w_tramite)
                    select @w_concepto = 'NORMALIZA'
                 else
                    select @w_concepto = 'RENOVACION'
                    
                 insert into   tmp_rubros_op_i
                 (ro_concepto, co_descripcion, ro_valor, spid)
                 values
                 (@w_concepto, 'Creditos  ', @w_renovaciones, @@spid)

                update tmp_rubros_op_i
                 set ro_valor = ro_valor - @w_renovaciones
                 from ca_producto
                 where ro_concepto = cp_producto
             end
       end
       /*FIN RUTINA NUEVA PARA VALORES RENOVADOS */
       
       
       --Cambios por Credito Rotativo
       insert into tmp_rubros_op_i
       select dtr_concepto,
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

       if @@rowcount > 0 
       begin
           select @w_neto_cap = isnull(sum(ro_valor),0) 
           from   tmp_rubros_op_i
           where  ro_concepto = 'CAP'
           and    spid = @@spid
                
           select @w_neto_ded = isnull(sum(t.ro_valor),0) 
           from   tmp_rubros_op_i t,
                  ca_rubro_op c
           where  t.ro_concepto <> 'CAP'
           and    c.ro_concepto = t.ro_concepto
           and    ro_operacion = @w_operacionca
           and    spid = @@spid

           select @w_neto_ded = @w_neto_ded + @w_renovaciones		--Mroa: Valor neto despues de renovaciones

           update tmp_rubros_op_i
           set ro_valor = ro_valor - @w_renovaciones
           from ca_producto
           where ro_concepto = cp_producto
       end 
    end  
    
   select @w_alianza = al_alianza,
          @w_desalianza = isnull((al_nemonico + ' - ' + al_nom_alianza), '  ')
    from cobis..cl_alianza_cliente with (nolock),
         cobis..cl_alianza         with (nolock)
   where ac_ente    = @w_cliente
     and ac_alianza = al_alianza
     and al_estado  = 'V'
     and ac_estado  = 'V'

   select @w_des_regional,
          SUBSTRING(@w_dir_comercial,1,100),
          @w_tel_comercial,
          SUBSTRING(@w_ciudad_comercial,1,50),
          convert(char(12),@w_fec_nacimiento,@i_formato_fecha),
          @w_sexo,
          @w_tipo_linea,
          @w_seguro_vida,
          @w_otros_seguros,
          @w_recursos,                     --10
          @w_margen_redescuento,
          convert(char(12),@w_fec_ult_pago,@i_formato_fecha),
          @w_vlr_ult_pago,
          @w_tipo_productor,
          @w_actividad,
          @w_saldo_actual,
          @w_pactado,  --@w_tipo_cobro,
          @w_clase,
          @w_tipo_amortizacion,
          @w_calificacion,                  --20
          @w_cuota,
          @w_provisiona,
          convert(char(12),@w_fec_calificacion,@i_formato_fecha),
          @w_aprobado_por,
          @w_nomina,
          @w_monto_aprobado,
          convert(char(12),@w_fecha_aprobacion,@i_formato_fecha),
          @w_matricula,
          @w_escritura,
          @w_notaria,                     --30
          @w_tipo_garantia,
          @w_des_garantia,
          @w_vlr_avaluo,
          @w_fecha_avaluo,
          @w_ubicacion,
          @w_mun_garantia,
          @w_perito_aval,
          0,   -- NO EXISTEN DIAS DE VENCIMIENTO EN EL DESEMBOLSO @W_DIAS_VENCIMIENTO,
          SUBSTRING(@w_nom_estado,1,20),
          @w_cuotas_vencidas,                  --40
          @w_cuotas_pagadas,
          @w_cuotas_pendientes,
          @w_estado_juridico,
          @w_fec_est_juridico,
          @w_clausula_aplicada,
          convert(char(12), @w_fec_clausula, @i_formato_fecha),
          @w_reestructuracion,
          @w_anterior,
          @w_numero_reest,
          @w_oficina,                     --50
          @w_deudor_otras,
          @w_tasa,
          @w_tasa_referencial,
          substring(@w_nombre_oficina,1,20),  --SPO Tamaño de acuerdo a la BD Access
          @i_banco,
          substring(@w_nombre,1,50),
          substring(@w_mod_obligacion,1,50),
          @w_periodo_pago,
          @w_gracia_int,
          @w_nom_estado,                  --60
          @w_monto,
          convert(char(12), @w_otorgamiento, @i_formato_fecha),
          convert(char(12),@w_fecha_fin,@i_formato_fecha),
          @w_destino,
          @w_cedula,
          @w_ultimo_pago,
          @w_deudor,
          @w_codeudor,
          substring(@w_moneda_desc,1,30),
          @w_moneda,                     --70
          @w_cliente,
          convert(char(12), getdate(), @i_formato_fecha),
          @w_neto_cap - @w_neto_ded,
          @w_desalianza
   

      select distinct
             'RUBRO'              = substring(ro_concepto, 1, 20),
             'VALOR'              = convert(float, ro_valor)
      from   tmp_rubros_op_i
      where  spid = @@spid   

-- CEH REQ264MENSAJE PARA CUANDO EL CHEQUE NO ESTE CRUZADO



   if exists(select 1 from ca_desembolso where dm_operacion = @w_operacionca and dm_secuencial   = @w_secuencial
                                               and dm_cruce_restrictivo = 'N')
   select @w_mensaje = 'Cheque de Gerencia marcado sin cruce restrictivo, no olvide levantar el sello antes de entregar el cheque.'                                                
   -- DETALLE DEL DESEMBOLSO
   /*Mroa: SI NO SE DETECTARON RENOVACIONES */
   if (select count(*) from tmp_rubros_op_i where ro_concepto in ('RENOVACION','NORMALIZA')) = 0
   begin
       select distinct
              'No.'          = dm_desembolso,
              'Forma'        = substring(cp_descripcion,1,40),
              'Moneda'       = substring(mo_descripcion,1,6),
              'Monto'        = dm_monto_mds,
              'Cotizacion'   = dm_cotizacion_mds,
              'Referencia'   = dm_cuenta,
              'Beneficiario' = substring(dm_beneficiario,1,50),
              'Cruce'        = @w_mensaje --CEH REQ264
       from   ca_desembolso, cobis..cl_moneda, ca_producto
       where  dm_secuencial   = @w_secuencial
       and    dm_operacion    = @w_operacionca
       and    dm_moneda       = mo_moneda
       and    dm_producto     = cp_producto 
       order by dm_desembolso
   end
   else
   begin

       select distinct
              'No.'          = dm_desembolso,
              'Forma'        = substring(cp_descripcion,1,40),
              'Moneda'       = substring(mo_descripcion,1,6),
              'Monto'        = dm_monto_mn,
              'Cotizacion'   = dm_cotizacion_mds,                               
              'Referencia'   = dm_cuenta,
              'Beneficiario' = substring(dm_beneficiario,1,50),
              'Cruce'        = @w_mensaje --CEH REQ264
       from   ca_desembolso, 
              ca_producto,
              cobis..cl_moneda
       where  dm_operacion  = @w_operacionca
       and    dm_producto   = cp_producto
       and    dm_secuencial = @w_secuencial
       and    mo_moneda     = dm_moneda
       order by dm_desembolso
   end

end

-- DEUDORES DE LA OPERACION
if @i_operacion = 'D'
begin
   select @w_cliente = op_cliente,
          @w_oficina = op_oficina,
          @w_oficial = op_oficial,
          @w_fecha_crear = op_fecha_ini,
          @w_monto_aprobado = op_monto,
          @w_op_direccion   = op_direccion,
          @w_moneda          = op_moneda
   from ca_operacion
   where op_banco = @i_banco
   
   if @w_op_direccion is null
      select @w_op_direccion = en_direccion
      from cobis..cl_ente
      where en_ente = @w_cliente
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
   and    dp_cuenta = @i_banco

   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted
   
   if @w_rowcount = 0 
   begin
      print '--INSERTAR EL PRODUCTO PARA FUTURAS IMPRESIONES'

 	     select @w_det_producto = 0
	     exec cobis..sp_cseqnos
	     @t_debug = @t_debug,
	     @t_file  = @t_file,
		  @t_from  = @w_sp_name,
		  @i_tabla = 'cl_det_producto',
		  @o_siguiente = @w_det_producto out

	   if @w_det_producto > 0
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
		  
		   if @@error <> 0 return 703028     
	     
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
         'OPERACION ACTUALIZADA IMP',@w_monto_aprobado,       @i_banco, 
         'V',                        @w_oficial,              1,
         0,                          0,                       '0',
         0,                          0,                       'T',
         1,                          @w_cliente,              1)  

          if @@error <> 0 return 703027
                 
          update cobis..cl_ente
          set    en_cliente = 'S'
          where  en_ente = @w_cliente         

          if @@error <> 0 return 710002
       end  

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
   
   if (@w_rol is null ) or (@w_rol  = '')
   begin
		update  cobis..cl_cliente
		set cl_rol = 'D'
        where cl_cliente =  @w_cliente      
        and cl_det_producto = @w_det_producto 
   end

   
   -- REALIZAR LA CONSULTA DE INFORMACION GENERAL DE CLIENTE OJO
   select 'Rol'       = cl_rol,
          'Codigo'    = cl_cliente,
          'DDI/NIT'   = SUBSTRING(cl_ced_ruc,1,13),--13 ES EL MAXIMO PERMITIDO POR LA BASE LOCAL Bdopera.mdb en la tabla clientes campo cl_ced_ruc
          'Pasaporte' = SUBSTRING(p_pasaporte,1,13), --13 ES EL MAXIMO PERMITIDO POR LA BASE LOCAL Bdopera.mdb en la tabla clientes campo cl_ced_ruc
          'Nombre'    = case when en_subtipo = 'C' then en_nombre else ltrim(substring(rtrim(p_p_apellido) + ' '
                        + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre),1,60)) end,
          'Telefono'  = te_valor,
          'Direccion' = substring(di_descripcion,1,100)
   from cobis..cl_cliente
                   inner join cobis..cl_ente on
                       cl_det_producto = @w_det_producto 
                       and en_ente     = cl_cliente
                       left outer join cobis..cl_telefono on
                                     en_ente = te_ente
                                     and te_direccion  = @w_op_direccion
                                   left outer join  cobis..cl_direccion on
                                         cl_cliente = di_ente 
                                         and di_direccion  = @w_op_direccion
                                   order by cl_rol desc
                                   set transaction isolation level read uncommitted
end

-- IMPRIMIR DATOS DE LA OPERACION EN ETAPA DE CREACION

-- CABECERA DE LA IMPRESION  DE TABLAS TEMPORALES
if @i_operacion = 'T'
begin
   select @w_tabla = 0
   
   select @w_tabla = codigo
   from   cobis..cl_tabla
   where  tabla = 'ca_toperacion'
   
   select @w_tabla2 = 0
   
   select @w_tabla2 = codigo
   from   cobis..cl_tabla
   where  tabla = 'cr_objeto'
   
   select @w_anterior          = opt_anterior,
          @w_tramite           = opt_tramite,
          @w_fecha_crea        = substring(convert(varchar,opt_fecha_ini, @i_formato_fecha),1,15),
          @w_toperacion        = opt_toperacion,
          @w_toperacion_desc   = A.valor,
          @w_moneda            = opt_moneda,
          @w_moneda_desc       = mo_descripcion,
          @w_monto             = opt_monto,
          @w_monto_aprobado    = opt_monto_aprobado,
          @w_destino           = opt_destino,
          @w_destini_desc      = B.valor,
          @w_ciudad_desc       = ci_descripcion,
          @w_oficina           = opt_oficina,
          @w_oficial           = opt_oficial,
          @w_oficial_desc      = fu_nombre,
          @w_lin_credito       = opt_lin_credito,
          @w_plazo             = opt_plazo,
          @w_tplazo            = opt_tplazo,
          @w_tipo_amortizacion = opt_tipo_amortizacion,
          @w_tdividendo        = opt_tdividendo,
          @w_periodo_cap       = opt_periodo_cap,
          @w_periodo_int       = opt_periodo_int,
          @w_gracia            = isnull(dit_gracia,0),
          @w_gracia_cap        = opt_gracia_cap,
          @w_gracia_int        = opt_gracia_int,
          @w_cuota             = opt_cuota,
          @w_tipo_cobro        = opt_tipo_cobro, 
          @w_tipo_aplicacion   = opt_tipo_aplicacion,
          @w_aceptar_anticipos = opt_aceptar_anticipos,
          @w_tipo_reduccion    = opt_tipo_reduccion,
          @w_precancelacion    = opt_precancelacion,
          @w_renovacion        = opt_renovacion,
          @w_mes_gracia        = opt_mes_gracia,
          @w_operacionca       = opt_operacion ,
          @w_rejustable        = opt_reajustable,
          @w_periodo_reaj      = opt_periodo_reajuste,
          @w_fecha_fin         = convert(varchar(10),opt_fecha_fin,101),
          @w_dias_anio         = opt_dias_anio,
          @w_base_calculo      = opt_base_calculo,
          @w_sector            = opt_sector,
          @w_ref_exterior      = opt_ref_exterior,
          @w_fec_embarque      = substring(convert(varchar,opt_fecha_embarque, @i_formato_fecha), 1, 15),
          @w_fec_dex           = substring(convert(varchar,opt_fecha_dex, @i_formato_fecha),1,15),
          @w_num_deuda_ext     = opt_num_deuda_ext,
          @w_num_comex         = opt_num_comex
   from   ca_operacion_tmp
                 inner join  cobis..cl_catalogo A on
                      opt_banco      = @i_banco
                      and    A.tabla = @w_tabla
                      and    A.codigo = opt_toperacion
                      inner join cobis..cl_moneda on 
                             opt_moneda     = mo_moneda              
                         inner join cobis..cl_ciudad on
                                opt_ciudad     = ci_ciudad
                              inner join cobis..cl_catalogo B on
                                    B.tabla = @w_tabla2
                                    and B.codigo = opt_destino
                                 inner join cobis..cl_funcionario on
                                        opt_oficial = fu_funcionario
                                    inner join ca_dividendo_tmp on
                                        opt_operacion = dit_operacion
                                        where dit_estado = 1
   
   if @@rowcount = 0
   begin
      PRINT 'impdatop.sp no hay datos para cabecera operacion T'
      select @w_error = 710026
      goto ERROR
   end  
   
   select @w_tplazo = td_descripcion 
   from   ca_tdividendo
   where  td_tdividendo = @w_tplazo
   
   select @w_tdividendo = td_descripcion 
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo
   
   if exists (select 1 from cob_credito..cr_seguros_tramite        -- Req. 366 Seguros
             where st_tramite = @w_tramite)
   begin
   
      select @w_tasa = sum(isnull(rot_porcentaje_aux,0))
      from   ca_rubro_op_tmp
      where  rot_operacion  = @w_operacionca
      and    rot_tipo_rubro = 'I'
      and    rot_fpago      in ('P', 'A')
   
   end
   else
   begin

      select @w_tasa = sum(isnull(rot_porcentaje_efa,0))
      from   ca_rubro_op_tmp
      where  rot_operacion  = @w_operacionca
      and    rot_tipo_rubro = 'I'
      and    rot_fpago      in ('P', 'A')
   
   end
   
   select @w_tasa_referencial = rot_referencial, 
          @w_signo_spread = rot_signo,
          @w_valor_spread = rot_factor,
          @w_modalidad    = rot_fpago,
          @w_valor_referencial = rot_porcentaje_aux
   from   ca_rubro_op_tmp
   where  rot_operacion  =  @w_operacionca
   and    rot_tipo_rubro =  'I'
   and    rot_fpago      in ('P','A')
   
   select @w_tasa_referencial = vd_referencia
   from   ca_valor_det
   where  vd_tipo = @w_tasa_referencial
   and    vd_sector = @w_sector
   
   select @w_anterior,          @w_tramite,           @w_fecha_crea,
          @w_toperacion,        @w_toperacion_desc,   @w_moneda,
          @w_moneda_desc,       @w_monto,             @w_monto_aprobado,
          @w_destino,           @w_destini_desc,      @w_ciudad_desc,
          @w_oficina,           @w_oficial,           @w_oficial_desc,
          @w_lin_credito,       @w_plazo,             @w_tplazo,
          @w_tipo_amortizacion, @w_tdividendo,        @w_periodo_cap,
          @w_periodo_int,       @w_gracia,            @w_gracia_cap,
          @w_gracia_int,        @w_cuota,             @w_tipo_cobro,
          @w_tipo_aplicacion,   @w_aceptar_anticipos, @w_tipo_reduccion,
          @w_tasa,              @w_rejustable,        @w_periodo_reaj,
          @w_mes_gracia,        @w_precancelacion,    @w_renovacion,
          @w_fecha_fin,         @w_dias_anio ,        @w_base_calculo,
          @w_tasa_referencial,  @w_valor_referencial, @w_valor_spread,
          @w_signo_spread,      @w_modalidad,         @w_ref_exterior,
          @w_fec_embarque,      @w_fec_dex,           @w_num_deuda_ext,
          @w_num_comex
end

-- DEUDORES DE LA OPERACION EN TABLAS TEMPORALES
if @i_operacion = 'S'
begin
   -- REALIZAR LA CONSULTA DE INFORMACION GENERAL DE CLIENTE
   select 'Rol'       = clt_rol,
          'Cliente'   = clt_cliente,
          'DDI/NIT'   = clt_ced_ruc,
          'Pasaporte' = p_pasaporte, 
          'Nombre'    = case when en_subtipo = 'C' then en_nombre else ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' '
                       + rtrim(en_nombre),1,60)) end,
          'Telefono'  = isnull(te_valor,''),
          'Direccion' = isnull(di_descripcion,'')
   from   ca_cliente_tmp
                    inner join cobis..cl_ente on
                       clt_user = @s_user
                       and clt_sesion = @s_sesn
                       and en_ente    = clt_cliente
                       left outer join cobis..cl_telefono on
                              en_ente = te_ente
                              and te_direccion = @w_op_direccion
                              and te_tipo_telefono in ('T', 'C')
                                    left outer join cobis..cl_direccion on
                                     clt_cliente = di_ente
                                     and di_direccion = @w_op_direccion
                              order by clt_rol desc
end

-- CONSULTA DE LA LIQUIDACION O DESEMBOLSOS PARCIALES

if @i_operacion = 'Q'
begin
   select 'SECUENCIAL'  = tr_secuencial,
          'FECHA'       = substring(convert(varchar, tr_fecha_mov, @i_formato_fecha), 1, 15),
          'Nro. RECIBO' = isnull(tr_dias_calc, -1),
          'OFICINA'     = tr_ofi_usu
   from   ca_transaccion
   where  tr_secuencial > @i_secuencial
   and    tr_banco = @i_banco
   and    tr_tran  = 'DES'
end

--GENERACION DE OTRO SI POR ABONO EXTRAORDINARIO
if @i_operacion =  'O'
begin
   select @w_cuota = 0
   
   select @w_operacion = op_operacion,
          @w_oficina   = op_oficina,
          @w_nombre    = substring(op_nombre,1,45),
          @w_cliente   = op_cliente,
          @w_codmoneda = op_moneda
   from   ca_operacion
   where  op_banco = @i_banco
   
   select @w_max_dividendo = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacion 
   
   select @w_dia_final = datepart(dd,di_fecha_ven),
          @w_mes_final = datepart(mm,di_fecha_ven),
          @w_ano_final = datepart(yy,di_fecha_ven)
   from   ca_dividendo
   where  di_operacion = @w_operacion 
   and    di_dividendo = @w_max_dividendo
   
   select @w_maxsec_abono = isnull(max(ab_secuencial_pag),0)
   from   ca_abono
   where  ab_operacion = @w_operacion
   and   ab_tipo_reduccion in ('T','C') --TIEMPO O CUOTA
   
   select @w_cuota = convert(float,sum(am_cuota + am_gracia - am_pagado))
   from   ca_amortizacion, ca_rubro_op 
   where  am_operacion = ro_operacion
   and    am_concepto    = ro_concepto
   and    ro_operacion   = @w_operacion
   and    ro_fpago       <> 'A'
   and    am_dividendo   = @w_max_dividendo
   
   if @w_maxsec_abono = 0 
   begin
      select @w_error = 710385
      goto ERROR
   end
   
   select @w_tipo_reduccion = ab_tipo_reduccion
   from   ca_abono
   where  ab_operacion = @w_operacion
   and    ab_secuencial_pag = @w_maxsec_abono
   
   select @w_nom_banco  = fi_nombre,
          @w_nit        = fi_ruc,
          @w_nombre_ofi = substring(of_nombre,1,20),
          @w_nom_ciudad = substring(ci_descripcion,1,20)
   from   cobis..cl_filial,
          cobis..cl_oficina,
          cobis..cl_ciudad
   where  fi_filial = 1
   and    fi_filial = of_filial
   and    of_oficina = @w_oficina
   and    ci_ciudad = of_ciudad
   set transaction isolation level read uncommitted

   select @w_dia_imp = datepart(dd,@s_date),
          @w_mes_imp = datepart(mm,@s_date),
          @w_ano_imp = datepart(yy,@s_date)
   
   select @w_cedula = en_ced_ruc
   from   cobis..cl_ente
   where  en_ente = @w_cliente
   set transaction isolation level read uncommitted
   
--ENVIO DE DATOS FRONT-END
   
   select @w_nom_banco,       --1
          @w_nit,             --2
          @w_oficina,         --3
          @w_nombre_ofi,      --4
          @w_nom_ciudad,      --5
          @w_tipo_reduccion,  --6
          @w_nombre,          --7
          @w_dia_final,       --8
          @w_mes_final,       --9
          @w_ano_final,       --10
          @w_cuota,           --11 
          @w_dia_imp,         --12
          @w_mes_imp,         --13
          @w_ano_imp,         --14
          @w_cedula,          --15
          @w_codmoneda        --16
end -- Operacion 'O'

delete tmp_rubros_op_i where spid = @@spid
return 0

ERROR:
delete tmp_rubros_op_i where spid = @@spid
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error
go

