/************************************************************************/
/*   NOMBRE LOGICO:      genrtmp.sp                                     */
/*   NOMBRE FISICO:      sp_gen_rubtmp                                  */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       R Garces                                       */
/*   FECHA DE ESCRITURA: Feb 95                                         */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                     PROPOSITO                                        */
/*   Crea los registros de la tabla ca_rubro_op_tmp para una            */
/*      operacion a partir de ca_rubro                                  */
/************************************************************************/
/*                     MODIFICACIONES                                   */
/*   FECHA       AUTOR         RAZON                                    */
/*   13/May/99   XSA(CONTEXT)   Manejo de los campos Saldo de           */
/*                     operacion y Saldo por desembol-                  */
/*                     sar para los rubros tipo calcu-                  */
/*                     lados.                                           */
/* 16/07/2001      Elcira Pelaez  se crea cursor rubros_asociados       */
/*                     para calculo de los rubros                       */
/*                     tipo porcentaje sobre un rubro                   */
/*                     asociado                                         */
/* 05/12/2002    Luis Mayorga   Cobra un porcentaje (Timbre) al         */
/*               usuario, el resto lo asume banco                       */
/* 10/nov/2005   Elcira Pelaez  Cambios para Documentos descontado BAC  */
/* 06/Jul/2006   Elcira Pelaez  Cambios para Credito Rotativo           */
/* NOV-02-20006  E.Pelaez       NR-126 Docmentos Descontados            */
/* 2008-03-25    M.Roa          Comentar @i_porcentaje_cobrar en        */
/*                              llamado sp_rubro_calculado              */
/* MAR-05-2011   Elcira Pelaez  Inc.17942 Busqueda de tasa para FNG     */
/* MAR-22-2017   Jorge Salazar  CGS-S112643                             */
/* MAR-11-2018   Jonatan Rueda  Reglas de Negocio para obtener tasa INT */
/* MAR-22-2018   Lorena Regalado Tasa IMO                               */
/* JUN-10-2019   Luis Ponce     Crear OP.Grupal Te Creemos              */
/* SEP-09-2019   Lorena Regalado Tasa Cero Operaciones Grupales TEC     */
/* ENE-06-2020   Luis Ponce      Correccion No Calculaba SINCAPAC       */
/* ABR-09-2020   Luis Ponce      CDIG Ajuste Creacion Operacion BANISTMO*/
/* OCT-21-2020   EMP-JJEC        Optimización Rubros calculados         */
/* NOV-05-2020   EMP-JJEC        Rubros financiados                     */
/* NOV-19-2020   EMP-JJEC        Control Tasa INT Maxima/Minima         */
/* NOV-27-2020   Luis Ponce      CDIG Correcion para Sintaxis Mysql     */
/* DIC-11-2020   Patricio Narvaez Incluir rubro FECI                    */
/* AGO-08-2021   Alfredo Monroy	 Se reutiliza columna ru_limite como    */
/*								 marca de rubro diferido (B.Finca)      */
/* NOV-15/2021   Kevin Rodríguez Se comenta validación por uso distinto */
/*                               de ru_limite                           */
/* FEB-21-2022	 Alfredo Monroy  Permitir que tome la tasa aplicar 		*/
/*								 parametrizada para la mora				*/
/* MAR-03-2022	 Alfredo Monroy  Rubros Valor que respete el valor de la*/
/*								 tasa a aplicar cuando sea tipo "V".	*/
/* 08/03/2022   Kevin Rodríguez  Ajuste Base Calculo a No financiados y */
/*                               validación rub financiado aplica desemb*/
/* 01/06/2022   Guisela Fernandez  Se comenta prints                    */
/* 01/06/2022   Guisela Fernandez  S841081 Se comenta codigo por error  */
/*                            de validacion de diferentes tipos de datos*/
/* 06/03/2025   Kevin Rodríguez  R256950(235424) Optimizaciones         */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_gen_rubtmp')
   drop proc sp_gen_rubtmp
go

create proc sp_gen_rubtmp (
   @s_user                         login       = null,
   @s_date                         datetime    = null,
   @s_term                         varchar(30) = null,
   @s_ofi                          smallint    = null,
   @s_rol                          smallint    = NULL,
   @t_debug                        char(1)     = 'N',
   @t_file                         varchar(14) = null,
   @t_from                         varchar(30) = null,
   @i_crear_pasiva                 char(1)     = 'N',
   @i_toperacion_pasiva            varchar(10)    = null,
   @i_operacion_activa             int         = null,
   @i_operacionca                  int         = null,
   @i_tramite_hijo                 int         = null,
   @i_tasa                         float       = null,  --JSA Santander
   --PQU incluir tasa 
   --LPO TEC Entonces se adiciona @i_tasa_grupal
   @i_tasa_grupal                  FLOAT       = NULL,  --LPO TEC
   @i_grupal                       char(1)     = NULL,  --LPO TEC
   @i_promocion                    char(1)     = 'N',
   @i_financiados                  char(1)     = 'N'
)
as declare
   @w_sp_name                      descripcion,
   @w_msg                          descripcion,
   @w_operacionca                  int,
   @w_cliente                      int,
   @w_toperacion                   varchar(10),
   @w_moneda                       tinyint,
   @w_fecha_ini                    datetime,
   @w_monto                        money,
   @w_ref_reajuste                 varchar(10),
   @w_dias_anio                    smallint,
   @w_concepto                     varchar(10),
   @w_porcentaje                   float,
   @w_prioridad                    tinyint,
   @w_paga_mora                    char(1),
   @w_fpago                        char(1),
   @w_tipo_rubro                   char(1),
   @w_provisiona                   char(1),
   @w_periodo                      tinyint,
   @w_referencial                  varchar(10), --varchar(10),
   @w_pit                          varchar(10),
   @w_signo                        char(1),
   @w_factor                       float,
   @w_factor_reaj                  float,
   @w_signo_reaj                   char(1),
   @w_clase                        char(1),
   @w_valor_rubro                  money,
   @w_tipo_val                     varchar(10),
   @w_signo_default                char(1),
   @w_tipo_puntos                  char(1),
   @w_valor_default                float,
   @w_decimales                    char(1),
   @w_num_dec                      tinyint,
   @w_sector                       catalogo, --varchar(10),
   @w_error                        int,
   @w_cap_principal                varchar(10),
   @w_vr_valor                     float,  --money,
   @w_vr_valor_a                   float,  --money,
   @w_secuencial_ref               int,
   @w_concepto_asociado            varchar(10),
   @w_principal                    char(1),
   @w_tcero                        varchar(10),
   @w_timbre                       varchar(10),
   @w_redescuento                  float,
   @w_tipo                         char(1),
   @w_capital_financiado           varchar(10),
   @w_saldo_operacion              char(1),
   @w_saldo_por_desem              char(1),
   @w_signo_pit                    char(1),
   @w_spread_pit                   float,
   @w_tasa_pit                     varchar(10),
   @w_clase_pit                    char(1),
   @w_porcentaje_pit               float,
   @w_num_dec_tapl                 tinyint,
   @w_limite                       char(1),
   @w_categoria_rubro              varchar(10),
   @w_categoria_cliente            varchar(10),
   @w_porcentaje_categoria         tinyint,
   @w_simulacion                   char(1),
   @w_spread_pit_a                 float,
   @w_num_dec_tapl_a tinyint,
   @w_signo_reaj_a                 char(1),
   @w_concepto_a                   varchar(10),
   @w_prioridad_a                  tinyint,
   @w_tipo_rubro_a                 char(1),
   @w_tipo_val_a                   varchar(10),
   @w_paga_mora_a                  char(1),
   @w_tipo_puntos_a                char(1),
   @w_provisiona_a                 char(1),
   @w_fpago_a                      char(1),
   @w_periodo_a                    tinyint,
   @w_referencial_a                varchar(10), --varchar(10),
   @w_ref_reajuste_a               varchar(10), --varchar(10),
   @w_concepto_asociado_a          varchar(10),
   @w_principal_a                  char(1),
   @w_redescuento_a                float,
   @w_saldo_operacion_a            char(1),
   @w_saldo_por_desem_a            char(1),
   @w_pit_a                        varchar(10),
   @w_limite_a                     char(1),
   @w_valor_rubro_asociado         money,
   @w_porcentaje_a                 float,
   @w_signo_a                      char(1),
   @w_tperiodo_a                   varchar(10),
   @w_valor_rubro_a                money,
   @w_signo_pit_a                  char(1),
   @w_tasa_pit_a                   varchar(10),
   @w_factor_a                     float,
   @w_clase_pit_a                  char(1),
   @w_factor_reaj_a                float,
   @w_clase_a                      char(1),
   @w_porcentaje_pit_a             float,
   @w_tramite                      int,
   @w_tipo_linea                   varchar(10),
   @w_porcentaje_efa               float,
   @w_iva_siempre                  char(1),
   @w_op_monto_aprobado            money,
   @w_monto_aprobado               char(1),
   @w_porcentaje_cobrar            float,
   @w_valor_cliente                float,
   @w_parametro_timbac             varchar(30),
   @w_rubro_timbac                 varchar(10),
   @w_valor_banco                  float,
   @w_parametro_fag                varchar(10),
   @w_mensaje                      int,
   @w_tperiodo                     varchar(10),
   @w_tipo_garantia                varchar(64),
   @w_valor_garantia               char(1),
   @w_porcentaje_cobertura         char(1),
   @w_nro_garantia                 varchar(64),
   @w_op_tdividendo                varchar(10),
   @w_tabla_tasa                   varchar(30),
   @w_base_calculo                 money,
   @w_saldo_insoluto               char(1),
   @w_porcentaje_cobrarc           float,
   @w_tasa_fija                    varchar(10),
   @w_regimen_fiscal               varchar(10),
   @w_cobra_timbre                 char(1),
   @w_calcular_devolucion          char(1),
   @w_fecha                        datetime,
   @w_exento                       char(1),
   @w_concepto_conta_iva           varchar(10),
   @w_op_oficina                   int,
   @w_tipogar_hipo                 varchar(10),
   @w_garhipo                      char(1),
   @w_cotizacion                   float,
   @w_moneda_local                 smallint,
   @w_fecha_ult_proceso            datetime,
   @w_rango                        tinyint,
   @w_dias_div                     int,
   @w_periodo_int                   smallint,
   @w_plazo_en_meses               int,
   @w_gracia_cap                   int,
   @w_gracia_cap_meses             int,
   @w_dias_plazo                   int,
   @w_plazo                        int,
   @w_tplazo                       varchar(10),
   @w_rowcount                     int,
   @w_clase_cartera                char(1),
   @w_parametro_fng                catalogo,
   @w_rubro_fng                    char(1),
   @w_cod_gar_fng                  catalogo,
   @w_pmipymes                     catalogo,
   @w_ivamipymes                   catalogo,
   @w_ivafng                       catalogo,
   @w_SMV                          money,
   @w_nro_creditos                 int,
   @w_cliente_nuevo                char(1),
   @w_monto_parametro              float,
   @w_factor_mipymes               float,
   @w_parametro_fng_des            catalogo,
   @w_parametro_fag_uni            catalogo,
   @w_parametro_fga_uni            catalogo,  --req343
   @w_parametro_fgu_uni            catalogo,
   @w_cod_gar_fgu                  catalogo,
      --REQ 402
   @w_parametro_fgu                varchar(10),
   @w_colateral                    catalogo,
   @w_garantia_sup                 varchar(10),
   @w_garantia                     varchar(10),
   @w_cod_garantia                 varchar(10),
   @w_rubro                        char(1),
   @w_tabla_rubro                  varchar(30),
   @w_concepto_des                 varchar(10),
   @w_concepto_per                 varchar(10),
   @w_iva_des                      varchar(10),
   @w_iva_per                      varchar(10),
   @w_cod_gar_fag                  catalogo,
   @w_cod_gar_fga                  catalogo,
   @w_garantia_genr                varchar(10),
   @w_grupal                       char(1),
   @w_variables		           varchar(64),
   @w_return_variable	           varchar(25),
   @w_return_results	           varchar(25),
   @w_last_condition_parent        varchar(10),
   @w_siglas_int                   catalogo,
   @w_siglas_imo                   catalogo,
   @w_ro_porcentaje                float,
   @w_siglas_com_adm               catalogo,   --LRE
   @w_siglas_com_pta               catalogo,   --LRE
   @w_valor_com_adm                float,      --LRE
   @w_es_grupal                    char(1),    --LRE
   @w_op_grupal                    char(1),    --LRE
   @w_ref_grupal                   catalogo,   --LRE
   @w_tasa_grupal                  float,      --LRE
   @w_operacion                    INT,        --LRE
   @w_regla_parametrizada          VARCHAR(30), --LPO DEMO BANISTMO
   @w_financiado                   char(1),
   @w_tasa_maxima                  float,
   @w_tasa_minima                  float,
   @w_porcentaje_int               float
   

select  @w_sp_name         = 'sp_gen_rubtmp',
        @w_simulacion      = 'N',
        @w_porcentaje_efa  = 0,
        @w_porcentaje_int  = 0

IF @i_grupal IS NULL  --LPO CDIG Ajustes Creacion de Operacion
   SELECT @i_grupal = 'N' 

create table #conceptos_gen (
codigo    varchar(10),
tipo_gar  varchar(64)
)

create table #rubros_gen (
garantia      varchar(10),
rre_concepto  varchar(64),
tipo_concepto varchar(10),
iva           varchar(5),
)

create table #colateral_genr(
tipo_sub   varchar(64) null
)

create table #garantias_operacion_genr(
w_tipo_garantia   varchar(64) null,
w_tipo            varchar(64) null,
estado            char(1),
w_garantia        varchar(64) null
)

--- LECTURA DE LOS DATOS DE LA OPERACION
select
@w_operacionca          = opt_operacion,
@w_cliente              = opt_cliente,
@w_toperacion           = opt_toperacion,
@w_moneda               = opt_moneda,
@w_fecha_ini            = opt_fecha_ini,
@w_monto                = opt_monto,
@w_sector               = opt_sector,
@w_dias_anio            = opt_dias_anio,
@w_tipo                 = opt_tipo,
@w_tipo_linea           = opt_tipo_linea,
@w_tramite              = opt_tramite,
@w_op_monto_aprobado    = opt_monto_aprobado,
@w_op_tdividendo        = opt_tdividendo,
@w_op_oficina           = opt_oficina,
@w_fecha_ult_proceso    = opt_fecha_ult_proceso,
@w_tplazo               = opt_tplazo,
@w_plazo                = opt_plazo,
@w_periodo_int          = opt_periodo_int,
@w_gracia_cap           = opt_gracia_cap,
@w_clase_cartera        = opt_clase,
@w_op_grupal            = opt_grupal,     --LRE
@w_ref_grupal           = opt_ref_grupal  --LRE
from  ca_operacion_tmp with(nolock)
where opt_operacion = @i_operacionca

if @w_rowcount = 0
   return 708153

--LRE 10Sep2019 Para el caso del desembolso no llega el @i_grupal
if @i_grupal is null
   if exists (select 1 from cob_cartera..ca_interf_op_tmp
              where iot_operacion = @i_operacionca)
   begin

      select @w_tasa_grupal = iot_tasa
      from cob_cartera..ca_interf_op_tmp
      where iot_operacion = @i_operacionca

      if @w_tasa_grupal is not null
      begin
         select @i_tasa_grupal = @w_tasa_grupal
         select @i_grupal = 'S'
      end
   end

--LRE 10Sep2019 Para Operaciones Grupales el porcentaje de comision viene en el @i_tasa_grupal, para operaciones hijas, tomar el porcentaje de los
--datos de la interface

if @w_op_grupal = 'S' and @w_ref_grupal is not null  --LRE Obtengo la tasa de comision para operaciones hijas
begin
   select @w_operacion = op_operacion
   from cob_cartera..ca_operacion
   where op_banco = @w_ref_grupal   --operacion padre

   if exists (select 1 from cob_cartera..ca_interf_op_tmp
           where iot_operacion = @w_operacion)
   begin

      select @w_tasa_grupal = iot_tasa
      from cob_cartera..ca_interf_op_tmp
      where iot_operacion = @w_operacion

      if @w_tasa_grupal is not null
      begin
         select @i_tasa_grupal = @w_tasa_grupal
         select @i_grupal = 'S'
      end
   end
end

/*CODIGO PADRE GARANTIA DE FNG*/
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION FNG
select @w_parametro_fng_des = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COFNGD'

/*PARAMETRO DE LA GARANTIA DE FGA*/
select @w_parametro_fga_uni = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFGA'

/*PARAMETRO DE LA GARANTIA DE FNG*/
select @w_parametro_fng = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'

/*PARAMETRO IVA DE LA GARANTIA DE FNG*/
select @w_ivafng = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFNG'

/*PARAMETRO COMISION MIPYMES */
select @w_pmipymes = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MIPYME'

/*PARAMETRO IVA COMISION MIPYMES */
select @w_ivamipymes = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAMIP'

/*PARAMETRO COMISION FAG UNI*/
select @w_parametro_fag_uni = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMUNI'

select @w_SMV      = pa_money
from   cobis..cl_parametro
where  pa_producto  = 'ADM'
and    pa_nemonico  = 'SMV'

/*PARAMETRO COMISION FGU UNI*/--REQ379
select @w_cod_gar_fgu = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'CODGAR'

select @w_parametro_fgu_uni = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMGAR'

/*PARAMETRO DE LA GARANTIA DE FGU REQ 379*/
select @w_parametro_fgu = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'COMGRP'

select @w_cod_gar_fga = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'CODFGA'

select @w_cod_gar_fag = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'CODfag'

select @w_monto_parametro  = @w_monto/@w_SMV

--LRE 22/Mar/2019 PARAMETROS DE NEMONICOS DE INT, IMO

select @w_siglas_int = pa_char from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico in ('INT')

select @w_siglas_imo = pa_char from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico in ('IMO')

--LRE 06Sep19 PARAMETROS RUBROS PRESTAMOS GRUPALES TEC
select @w_siglas_com_adm = pa_char from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico in ('COMGCO')

select @w_siglas_com_pta = pa_char from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico in ('COMPTA')


--FIN LRE 06Sep19 PARAMETROS RUBROS PRESTAMOS GRUPALES TEC
--GFP Se comenta por error de validacion de datos de diferentes tipos y la logica no aplica a ENLACE
/*
IF @w_clase_cartera <> 1
begin

   select @w_nro_creditos = count(1)
   from ca_operacion_tmp with(nolock)
   where opt_cliente = @w_cliente
   and opt_estado  in (0,1,2,3,4,5,9,99)

   if @w_nro_creditos = 1
      select @w_cliente_nuevo = 'N'     --N: new
   else
      select @w_cliente_nuevo = 'R'     --R: Renovado


   --CALCULO DE LA TASA MIPYMES

   --CALCULO DE LA TASA 
   exec  cob_cartera..sp_retona_valor_en_smlv
         @i_matriz       = @w_pmipymes,
         @i_monto        = @w_monto,
         @i_smv          = @w_SMV,
         @o_MontoEnSMLV  = @w_monto_parametro out

   if @w_monto_parametro  = -1
      select @w_monto_parametro = @w_monto / @w_SMV

   select @w_factor_mipymes = 0
   if @w_monto_parametro > 0
   begin
      exec @w_error     = sp_matriz_valor
           @i_matriz    = @w_pmipymes,
           @i_fecha_vig = @w_fecha_ult_proceso,
           @i_eje1      = @w_op_oficina,
           @i_eje2      = @w_monto_parametro,
           @i_eje3      = @w_cliente_nuevo,
           @o_valor     = @w_factor_mipymes out,
           @o_msg       = @w_msg    out

      if @w_error <> 0  return @w_error
   end

   select @w_factor_mipymes = isnull(@w_factor_mipymes,0)/100

end
*/
---ACTUALIZACION DE TIPO DE DIVIDENDO SEGUN LO DEFINIDO PARA LA OPERACION
---ESTO PARA LOS RUBROS CON PERIODICIDAD DIFERENTE A LA DE INTERES

---CODIGO DEL RUBRO TIMBRE
select @w_timbre = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'TIMBRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0
   return 710120

select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro
WHERE  pa_nemonico = 'MLO'
AND    pa_producto = 'ADM'


---NUMERO DE DECIMALES
exec @w_error = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out

if @w_error <> 0
   return @w_error


-- DETERMINAR EL VALOR DE COTIZACION DEL DIA
if @w_moneda = @w_moneda_local
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
   @i_moneda     = @w_moneda,
   @i_fecha      = @w_fecha_ult_proceso,
   @o_cotizacion = @w_cotizacion output
end

update ca_rubro
set ru_tperiodo = @w_op_tdividendo
from ca_rubro
where ru_toperacion = @w_toperacion
and ru_tperiodo is not null


---LEO EL CODIGO DE CAPITAL PRINCIPAL
select @w_cap_principal = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'

select @w_capital_financiado = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAPF'

---CODIGO DEL RUBRO COMISION FAG
select @w_parametro_fag = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFAG'
select @w_rowcount = @@rowcount

if @w_rowcount = 0
   return  710370

exec @w_error        = cob_cartera..sp_matriz_garantias
     @s_date         = @w_fecha_ult_proceso,
     @i_tramite      = @w_tramite,
     @i_tipo_periodo = 'P',
     @i_plazo        = @w_plazo,
     @i_tplazo       = @w_tplazo,
     @o_valor        = @w_factor out,
     @o_msg          = @w_msg out

if @w_error <> 0  return @w_error

if @i_financiados = 'S'
begin
   --- INSERCION DE LOS RUBROS DE LA OPERACION PARA RUBROS QUE NO TIENEN (RUBRO_ASOCIADO = NULL)
   declare rubros cursor for
   select  ru_concepto,            ru_prioridad,          ru_tipo_rubro,           ru_paga_mora,
           ru_provisiona,          ru_fpago,              ru_periodo,              ru_referencial,
           ru_reajuste,            ru_concepto_asociado,  ru_principal,            ru_redescuento,
           ru_saldo_op,            ru_saldo_por_desem,    ru_pit,                  ru_limite,
           ru_iva_siempre,         ru_monto_aprobado,     ru_porcentaje_cobrar,    ru_tperiodo,
           ru_tipo_garantia,       ru_valor_garantia,     ru_porcentaje_cobertura, ru_tabla,
           ru_saldo_insoluto,      ru_calcular_devolucion, ru_financiado,          ru_tasa_maxima,
           ru_tasa_minima
   from ca_rubro
   where ru_toperacion      = @w_toperacion
   and ru_moneda            = @w_moneda
   and ru_estado            = 'V'
   and ru_concepto_asociado is null
   and ru_financiado        = 'S'
   and ru_fpago             <> 'P'
   
   for read only
end
else
begin
   --- INSERCION DE LOS RUBROS DE LA OPERACION PARA RUBROS QUE NO TIENEN (RUBRO_ASOCIADO = NULL)
   declare rubros cursor for
   select  ru_concepto,            ru_prioridad,          ru_tipo_rubro,           ru_paga_mora,
           ru_provisiona,          ru_fpago,              ru_periodo,              ru_referencial,
           ru_reajuste,            ru_concepto_asociado,  ru_principal,            ru_redescuento,
           ru_saldo_op,            ru_saldo_por_desem,    ru_pit,                  ru_limite,
           ru_iva_siempre,         ru_monto_aprobado,     ru_porcentaje_cobrar,    ru_tperiodo,
           ru_tipo_garantia,       ru_valor_garantia,     ru_porcentaje_cobertura, ru_tabla,
           ru_saldo_insoluto,      ru_calcular_devolucion, ru_financiado,          ru_tasa_maxima,
           ru_tasa_minima
   from ca_rubro
   where ru_toperacion      = @w_toperacion
   and ru_moneda            = @w_moneda
   and ru_estado            = 'V'
   and ru_crear_siempre     = 'S'
   and ru_concepto_asociado is null
   and isnull(ru_financiado,'N') = 'N'
   
   for read only
end

open rubros

fetch rubros into
         @w_concepto,         @w_prioridad,         @w_tipo_rubro,           @w_paga_mora,
         @w_provisiona,       @w_fpago,             @w_periodo,              @w_referencial,
         @w_ref_reajuste,     @w_concepto_asociado, @w_principal,            @w_redescuento,
         @w_saldo_operacion,  @w_saldo_por_desem,   @w_pit,                  @w_limite,
         @w_iva_siempre,      @w_monto_aprobado,    @w_porcentaje_cobrar,    @w_tperiodo,
         @w_tipo_garantia,    @w_valor_garantia,    @w_porcentaje_cobertura, @w_tabla_tasa,
         @w_saldo_insoluto,   @w_calcular_devolucion, @w_financiado,         @w_tasa_maxima,
         @w_tasa_minima  

while (@@fetch_status  = 0)
begin

   if (@@fetch_status <> 0)
   begin
       close rubros
       deallocate rubros
       return 710124
   end

   ---INICIAR VARIABLES
   select
   @w_porcentaje     = 0,
   @w_valor_rubro    = 0,
   @w_vr_valor       = 0,
   @w_signo          = null,
   @w_factor         = 0,
   @w_signo_reaj     = null,
   @w_factor_reaj    = 0,
   @w_tipo_val       = null,
   @w_clase          = null,
   @w_signo_pit      = null,
   @w_spread_pit     = 0,
   @w_tasa_pit       = null,
   @w_clase_pit      = null,
   @w_porcentaje_pit = 0,
   @w_num_dec_tapl   = null,
   @w_porcentaje_efa = 0
   --GFP Se comenta por error de validacion de datos de diferentes tipos y la logica no aplica a ENLACE
   /*
   if @w_clase_cartera = 1 and (@w_concepto = @w_pmipymes or @w_concepto = @w_ivamipymes)  begin
      goto NEXT
   end
   */
   
   -- KDR Validación cuando el rubro es financiado y su forma de pago no es en el desembolso.
   if @w_financiado = 'S' and @w_fpago <> 'L'
   begin
	  select @w_error = 725149 -- Un rubro financiado debe tener como forma de aplicación EN EL DESEMBOLSO, revisar parametrización
      return @w_error
   end

    --LRE 06Sep19 Tasa Cero
   if (@w_concepto = @w_siglas_com_adm and @i_grupal = 'S'  and @w_tipo_rubro = 'Q')
   begin
      SELECT @w_porcentaje = @i_tasa_grupal
   end

   select @w_categoria_rubro = co_categoria
   from ca_concepto
   where co_concepto = @w_concepto

   --PARA LAS OBLIGACIONES CON GARANTIA HIPOTECARIA EL VALOR DEL TIMBRE ES 0
   if @w_concepto = @w_timbre
   begin
      select @w_limite = 'S',
             @w_garhipo = 'N'

      select @w_tipogar_hipo = pa_char
      from cobis..cl_parametro
      where pa_producto = 'CCA'
      and   pa_nemonico = 'GARHIP'

      if exists (select 1
                   from cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia,cob_custodia..cu_tipo_custodia
                  where cu_codigo_externo = gp_garantia
                    and gp_tramite = @w_tramite
                    and tc_tipo = cu_tipo
                    and tc_tipo_superior = @w_tipogar_hipo )
      select @w_garhipo = 'S'
   end

   if not @w_pit is null and @w_pit <> ''
   begin
      select
      @w_signo_pit    = isnull(vd_signo_default,' '),
      @w_spread_pit   = isnull(vd_valor_default,0),
      @w_tasa_pit     = vd_referencia,
      @w_clase_pit    = va_clase
      from    ca_valor,ca_valor_det
      where   va_tipo   = @w_pit
      and     vd_tipo   = @w_pit
      and     vd_sector = @w_sector

      if @@rowcount = 0 and @w_tipo_rubro in('I','F')
      begin
		 close rubros
         deallocate rubros
         return 721401
      end

      ---DETERMINACION DEL MAXIMO SECUENCIAL PARA LA TASA ENCONTRADA
      select @w_fecha = max(vr_fecha_vig)
      from   ca_valor_referencial
      where  vr_tipo = @w_tasa_pit
      and    vr_fecha_vig <= @w_fecha_ini

      select @w_secuencial_ref = max(vr_secuencial)
      from   ca_valor_referencial
      where  vr_tipo = @w_tasa_pit
      and    vr_fecha_vig = @w_fecha

      --- DETERMINACION DEL VALOR DE TASA A APLICAR
      select @w_vr_valor = vr_valor
      from   ca_valor_referencial
      where  vr_tipo       = @w_tasa_pit
      and    vr_secuencial = @w_secuencial_ref

      if @w_clase_pit = 'V'
      begin
         if @w_tipo_rubro in ('I','F')
            select  @w_porcentaje_pit = @w_spread_pit,
               @w_spread_pit = 0
      end
      else
      begin
         if @w_tipo_rubro in ('I','F')
         begin
            if @w_signo_pit = '+'
               select  @w_porcentaje_pit =  @w_vr_valor + @w_spread_pit
            if @w_signo_pit = '-'
               select  @w_porcentaje_pit =  @w_vr_valor - @w_spread_pit
            if @w_signo_pit = '/'
               select  @w_porcentaje_pit =  @w_vr_valor / @w_spread_pit
            if @w_signo_pit = '*'
               select  @w_porcentaje_pit =  @w_vr_valor * @w_spread_pit
         end
      end
   end  --fin de pit
   else
   begin
      --LRE 20/Mar/2019 excluir el rubro INT/IMO para obtener valores de Tasa a aplicar. Tasa de interes se obtiene a trav\82s de la regla
      if (@w_concepto not in (@w_siglas_int, @w_siglas_imo)
          and @i_grupal <> 'S')                              --LRE 06Sep19 Condicion para individuales en donde se asigna la tasa por la regla
      
      begin
         select
         @w_signo        = isnull(vd_signo_default,' '),
         @w_factor       = isnull(vd_valor_default,0),
         @w_tipo_val     = vd_referencia,
         @w_tipo_puntos  = vd_tipo_puntos,
         @w_clase        = va_clase,
         @w_num_dec_tapl = vd_num_dec
         from    ca_valor,ca_valor_det
         where   va_tipo   =  @w_referencial     --'T-IMO-COM'
         and     vd_tipo   =  @w_referencial     --'T-IMO-COM'
         and     vd_sector =  @w_sector          --'1'
         
         if @@rowcount = 0 and @w_tipo_rubro in('I','M','F')
         begin
            close rubros
            deallocate rubros
            return 721401
         end
      end    --LRE 
      else
      if (@w_concepto not in (@w_siglas_com_adm, @w_siglas_com_pta)  --LRE 06Sep19 Condicion para grupales en donde se asigna la tasa 
          and @i_grupal = 'S')                                       --de la comision de adm y pago tardio a partir de lo que llega de la interface
      begin
          select
          @w_signo        = isnull(vd_signo_default,' '),
          @w_factor       = isnull(vd_valor_default,0),
          @w_tipo_val     = vd_referencia,
          @w_tipo_puntos  = vd_tipo_puntos,
          @w_clase        = va_clase,
          @w_num_dec_tapl = vd_num_dec
          from    ca_valor,ca_valor_det
          where   va_tipo   =  @w_referencial     --'T-IMO-COM'
          and     vd_tipo   =  @w_referencial     --'T-IMO-COM'
          and     vd_sector =  @w_sector          --'1'
      
          if @@rowcount = 0 and @w_tipo_rubro in('I','M','F')
          begin
               close rubros
               deallocate rubros
               return 721401
          end    
      
      
      end
      --PQU Aqui colocar la tasa para el inter+s que viene en un par¯metro
      --LPO TEC Se colocar¯ el valor de la tasa grupal m¯s adelante, luego de la regla de tasas de OP.Individuales.
      
      --REQ 402
      select @w_colateral = pa_char
      from cobis..cl_parametro with (nolock)
      where pa_producto = 'GAR'
      and   pa_nemonico = 'GARESP'
      
      insert into #colateral_genr
      select tc_tipo
      from cob_custodia..cu_tipo_custodia
      where tc_tipo_superior = @w_colateral
      
      insert into #garantias_operacion_genr
      select d.tc_tipo_superior,
             d.tc_tipo,
             'I',
             a.cu_codigo_externo
      from cob_custodia..cu_custodia a, #colateral_genr b, cob_credito..cr_gar_propuesta c, cob_custodia..cu_tipo_custodia d
      Where a.cu_tipo = d.tc_tipo
      and   d.tc_tipo_superior = b.tipo_sub
      and   c.gp_tramite  = @w_tramite
      and   c.gp_garantia = a.cu_codigo_externo
      and   a.cu_estado  in ('V','F','P')
      
      select @w_garantia       = w_tipo,
             @w_garantia_sup   = w_tipo_garantia
      from #garantias_operacion_genr
      
      select @w_rubro = valor
      from  cobis..cl_tabla t, cobis..cl_catalogo c
      where t.tabla  = 'ca_conceptos_rubros'
      and   c.tabla  = t.codigo
      and   c.codigo = convert(bigint, @w_garantia)
      
      if @w_rubro = 'S' 
      begin
         select @w_tabla_rubro = 'ca_conceptos_rubros_' + cast(@w_garantia as varchar)
      
         insert into #conceptos_gen
         select
         codigo = c.codigo,
         tipo_gar = @w_garantia
         from cobis..cl_tabla t, cobis..cl_catalogo c
         where t.tabla  = @w_tabla_rubro
         and   c.tabla  = t.codigo
      
         /*COMISION DESEMBOLSO*/
         insert into #rubros_gen
         select tipo_gar, ru_concepto, 'DES', 'N'
         from cob_cartera..ca_rubro, #conceptos_gen
         where ru_fpago = 'L'
         and   codigo   = ru_concepto
         and   ru_concepto_asociado is null
         
         /*COMISION PERIODICO*/
         insert into #rubros_gen
         select tipo_gar, ru_concepto, 'PER', 'N'
         from cob_cartera..ca_rubro, #conceptos_gen
         where ru_fpago = 'P'
         and   codigo   = ru_concepto
         and   ru_concepto_asociado is null
         
         /*IVA DESEMBOLSO*/
         insert into #rubros_gen
         select tipo_gar, ru_concepto, 'DES', 'S'
         from cob_cartera..ca_rubro, #conceptos_gen
         where ru_fpago = 'L'
         and   codigo   = ru_concepto
         and   ru_concepto_asociado is not null
         
         /*IVA PERIODICO*/
         insert into #rubros_gen
         select tipo_gar, ru_concepto, 'PER', 'S'
         from cob_cartera..ca_rubro, #conceptos_gen
         where ru_fpago = 'P'
         and   codigo   = ru_concepto
         and   ru_concepto_asociado is not null
         
         --CAPTURA DE CONCEPTOS
         select @w_concepto_des = rre_concepto
         from #rubros_gen
         where tipo_concepto = 'DES'
         and iva = 'N'
         
         select @w_concepto_per = rre_concepto
         from #rubros_gen
         where tipo_concepto = 'PER'
         and iva = 'N'
         
         select @w_iva_des = rre_concepto
         from #rubros_gen
         where tipo_concepto = 'DES'
         and iva = 'S'
         
         select @w_iva_per = rre_concepto
         from #rubros_gen
         where tipo_concepto = 'PER'
         and iva = 'S'
         
         select @w_garantia_genr = garantia
         from   #rubros_gen
         where tipo_concepto = 'DES'
         and iva = 'N'
      end
      
      ---DETERMINACION DEL MAXIMO SECUENCIAL PARA LA TASA ENCONTRADA
      if @w_clase <> 'V'
      begin
      
         select @w_fecha = max(vr_fecha_vig)
         from   ca_valor_referencial
         where  vr_tipo = @w_tipo_val
         and    vr_fecha_vig <= @w_fecha_ini
      
         select @w_secuencial_ref = max(vr_secuencial)
         from   ca_valor_referencial
         where  vr_tipo = @w_tipo_val
         and    vr_fecha_vig = @w_fecha
      
      
         --- DETERMINACION DEL VALOR DE TASA A APLICAR
         select @w_vr_valor = vr_valor
         from   ca_valor_referencial
         where  vr_tipo       = @w_tipo_val
         and    vr_secuencial = @w_secuencial_ref
      end
      else
         select @w_vr_valor =  @w_factor
      
      if @w_concepto in (@w_parametro_fng,@w_parametro_fng_des, @w_concepto_des, @w_concepto_per) and @w_cod_gar_fng = @w_garantia_sup
      begin
         --CALCULO DE LA TASA  PARA LOS FNG ANUALES O DEL DESEMBOLSO
         exec cob_cartera..sp_retona_valor_en_smlv
              @i_matriz         = @w_parametro_fng,
              @i_monto          = @w_monto,
              @i_smv            = @w_SMV,
              @o_MontoEnSMLV    = @w_monto_parametro out
      
         if @w_monto_parametro  = -1
              select @w_monto_parametro = @w_monto / @w_SMV
      
         select @w_porcentaje = 0
      
         if @w_monto_parametro > 0
         begin
            exec @w_error     = sp_matriz_valor
                 @i_matriz    = @w_parametro_fng,
                 @i_fecha_vig = @w_fecha_ult_proceso,
                 @i_eje1      = @w_monto_parametro,
                 @o_valor     = @w_porcentaje out,
                 @o_msg       = @w_msg    out
      
            if @w_error <> 0  
            begin 
	              close rubros
               deallocate rubros
	              return @w_error
            end
         end
      
         select @w_vr_valor =   @w_porcentaje,
                @w_factor   =   @w_porcentaje
      end
      
      if @w_concepto in (@w_parametro_fag_uni, @w_concepto_des, @w_concepto_per) and @w_cod_gar_fag = @w_garantia_sup
      begin
      
         --CALCULO DE LA TASA PARA LAS FAG UNICAS
         exec @w_error        = cob_cartera..sp_matriz_garantias
              @s_date         = @w_fecha_ult_proceso,
              @i_tramite      = @w_tramite,
              @i_tipo_periodo = 'P',
              @i_plazo        = @w_plazo,
              @i_tplazo       = @w_tplazo,
              @o_valor        = @w_factor out,
              @o_msg          = @w_msg out
      
         select @w_vr_valor =   @w_factor,
                @w_factor   =   @w_factor
      
      end
      
      if @w_concepto in (@w_parametro_fga_uni, @w_concepto_des, @w_concepto_per) and @w_cod_gar_fga = @w_garantia_sup
      begin
         --CALCULO DE LA TASA PARA LAS FGA ANTIOQUIA
         exec @w_error   = cob_cartera..sp_matriz_garantias
              @s_date    = @w_fecha_ult_proceso,
              @i_tramite = @w_tramite,
              @o_valor   = @w_porcentaje out,
              @o_msg     = @w_msg out
      
         select @w_vr_valor =   @w_porcentaje,
                @w_factor   =   @w_porcentaje
      
      end
      
      if @w_concepto in (@w_parametro_fgu_uni, @w_parametro_fgu) and @w_cod_gar_fgu = @w_garantia_sup
      begin
      
         --CALCULO DE LA TASA PARA LAS FGU UNIFICADA REQ379
         exec @w_error   = cob_cartera..sp_matriz_garantias
              @s_date    = @w_fecha_ult_proceso,
              @i_tramite = @w_tramite,
              @o_valor   = @w_porcentaje out,
              @o_msg     = @w_msg out
      
      
         select @w_vr_valor =   @w_porcentaje,
                @w_factor   =   @w_porcentaje
      
      end

      ---AMP 20210811 SE REUTILIZA VARIABLE RO_LIMITE PARA MARCA DE COMISIONES DIFERIDAS BANCO FINCA
      ---AMP 20210811 SOLO QUEDA LA VALIDACION DE RUBROS CALCULADOS, NO APLICAN LIMITES
      if @w_tipo_rubro = 'Q'
         begin
      
            exec @w_error                 = sp_rubro_calculado
                 --@i_tipo                  = 'Q',
                 --@i_op_monto_aprobado     = @w_op_monto_aprobado,
                 --@i_categoria_rubro       = @w_categoria_rubro,
                 --@i_fpago                 = @w_fpago,
                 --@i_tabla_tasa            = @w_tabla_tasa,
                 --@i_parametro_fag         = @w_parametro_fag,
                 @i_monto                 = 0,
                 @i_concepto              = @w_concepto,
                 @i_operacion             = @w_operacionca,
                 @i_saldo_op              = @w_saldo_operacion,
                 @i_saldo_por_desem       = @w_saldo_por_desem,
                 @i_porcentaje            = @w_porcentaje,
                 @i_monto_aprobado        = @w_monto_aprobado,
                 @i_porcentaje_cobertura  = @w_porcentaje_cobertura,
                 @i_valor_garantia        = @w_valor_garantia,
                 @i_tipo_garantia         = @w_tipo_garantia,
                 @i_saldo_insoluto        = @w_saldo_insoluto,
                 @o_tasa_calculo          = @w_porcentaje out,
                 @o_nro_garantia          = @w_nro_garantia out,
                 @o_base_calculo          = @w_base_calculo out,
                 @o_valor_rubro           = @w_valor_rubro out
      
            if @w_error <> 0
	           begin
                 close rubros
                 deallocate rubros
	             return @w_error
               END
               
            select @w_valor_rubro = round(@w_valor_rubro,@w_num_dec)
         end
      
	  -- KDR 15/11/2021 Se comenta validación por uso distinto de w_limite en la versión Finca Impact.
      /*if @w_tipo_rubro <> 'Q' and @w_limite = 'S'
      begin
         PRINT 'genrtmp.sp rubro no calculado  y parametrizado con limite, debe ser programado' + cast(@w_concepto as varchar)
         close rubros
         deallocate rubros
         return 721405
      end*/
      
      if @w_tipo_rubro in('I','F')
      begin
         select
         @w_signo_reaj    = isnull(vd_signo_default,' '),
         @w_factor_reaj   = isnull(vd_valor_default,0)
         from    ca_valor,ca_valor_det
         where   va_tipo   = @w_ref_reajuste
         and     vd_tipo   = @w_ref_reajuste
         and     vd_sector = @w_sector
      end
      
      if @w_clase = 'V'  --TASA VALOR
      begin
      
         if @w_tipo_rubro in ('O','I','M','Q','F')
         begin
             if (@w_concepto not in (@w_siglas_com_adm, @w_siglas_com_pta)  --LRE 06Sep19 Condicion para grupales en donde se asigna la tasa 
                 and @i_grupal = 'S')                                       --de la comision de adm y pago tardio a partir de lo que llega de la interface
             begin
                 select  @w_porcentaje     = @w_factor, 
                         @w_factor         = 0,
                         @w_porcentaje_efa = @w_factor
             end
         end
         ELSE
            -- AMP 20220303 SI EL RUBRO TIENEN ASOCIADA UNA TASA A APLICAR TIPO VALOR, SE RESPETA
            if @w_concepto not in (@w_siglas_com_adm, @w_siglas_com_pta)
                select @w_valor_rubro = round(@w_factor,@w_num_dec) ,
                       @w_factor = 0
      end
      else                --TASA REFERENCIAL
      begin
         if @w_tipo_rubro in ('O','I','M','Q','F')
         begin

            --if @w_concepto in (@w_siglas_int) AND @i_grupal <> 'S' -- AMP 2022-02-21 VERSION BASE NO RESPETABA PARAMETRIZACION DE TASA APLICAR EN MORA
            if @w_concepto in (@w_siglas_int,@w_siglas_imo) AND @i_grupal <> 'S' -- LPO TEC Para que la regla de tasas s¥lo se aplique a OP. Invividuales.
            																	 -- AMP 2022-02-21 VERSION BASE NO RESPETABA PARAMETRIZACION DE TASA APLICAR EN MORA
            begin
               --JRU AQUI DEBE IR LA LLAMADA AL SP DE REGLAS
               select @w_variables = (SELECT opt_toperacion FROM ca_operacion_tmp with(nolock) WHERE opt_operacion = @i_operacionca) + '|' 
               			  + (SELECT convert(VARCHAR(25), opt_monto) FROM ca_operacion_tmp with(nolock) WHERE opt_operacion = @i_operacionca)+ '|' 
               			  + (SELECT p_calif_cliente FROM cobis..cl_ente 
               			   WHERE en_ente = (SELECT opt_cliente FROM ca_operacion_tmp with(nolock) WHERE opt_operacion = @i_operacionca)) + '|' 
               			  + (SELECT opt_reestructuracion FROM ca_operacion_tmp with(nolock) WHERE opt_operacion = @i_operacionca)
                            
                     
               --LPO DEMO BANITSMO (INICIO)
               SELECT @w_regla_parametrizada = NULL
               SELECT @w_regla_parametrizada = aiv_policyname from cob_fpm..fp_amountitemvalues
               WHERE bp_product_idfk = @w_toperacion --'VIVTCASA'
                 AND aiv_valuereference = @w_referencial --'TINT'
                 AND aiv_policyname <> ''
                 
               IF @w_regla_parametrizada IS NOT NULL
               begin
                  exec @w_error               = cob_pac..sp_rules_param_run
                          @s_rol                   = @s_rol,
                          @i_rule_mnemonic         = 'RTAO',
                          @i_var_values            = @w_variables,
                          @i_var_separator         = '|',
                          @o_return_variable       = @w_return_variable  OUT,
                          @o_return_results        = @w_return_results   OUT,
                          @o_last_condition_parent = @w_last_condition_parent OUT
                
                  if @w_error != 0 or @w_return_results = '0'
                  begin         
                     select @w_return_results = '0'
                     select @w_error =  2110104
                     return @w_error
                  end
                        
                  select  @w_return_results = convert(FLOAT,replace(@w_return_results,'|',''))
                  select  @w_porcentaje     = @w_return_results 
                                     
               end
               ELSE --LPO DEMO BANITSMO SI NO HAY REGLA PARAMETRIZADA EN FRONT END EN RUBROS DEL APF, ENTONCES SACAR DE TASA A APLICAR
               BEGIN
                  select
                  @w_signo        = isnull(vd_signo_default,' '),
                  @w_factor       = isnull(vd_valor_default,0),
                  @w_tipo_val     = vd_referencia,
                  @w_tipo_puntos  = vd_tipo_puntos,
                  @w_clase        = va_clase,
                  @w_num_dec_tapl = vd_num_dec
                  from    ca_valor,ca_valor_det
                  where   va_tipo   =  @w_referencial     --'T-IMO-COM'
                  and     vd_tipo   =  @w_referencial     --'T-IMO-COM'
                  and     vd_sector =  @w_sector          --'1'
                       
                  if @@rowcount = 0 and @w_tipo_rubro in('I','M','F')
                  begin
                     return 721401
                  end

                  ---DETERMINACION DEL MAXIMO SECUENCIAL PARA LA TASA ENCONTRADA
                  select @w_fecha = max(vr_fecha_vig)
                  from   ca_valor_referencial
                  where  vr_tipo = @w_tipo_val
                  and    vr_fecha_vig <= @w_fecha_ini

                  select @w_secuencial_ref = max(vr_secuencial)
                  from   ca_valor_referencial
                  where  vr_tipo = @w_tipo_val
                  and    vr_fecha_vig = @w_fecha

                  --- DETERMINACION DEL VALOR DE TASA A APLICAR
                  select @w_vr_valor = vr_valor
                  from   ca_valor_referencial
                  where  vr_tipo       = @w_tipo_val
                  and    vr_secuencial = @w_secuencial_ref
                  
                  if @w_clase = 'V'
                  begin
                     if @w_tipo_rubro in ('I','F','M') -- AMP 2022-02-21 VERSION BASE NO RESPETABA PARAMETRIZACION DE TASA APLICAR EN MORA
                        select  @w_porcentaje = @w_factor
                  end
                  else
                  begin
                     if @w_tipo_rubro in ('I','F','M') -- AMP 2022-02-21 VERSION BASE NO RESPETABA PARAMETRIZACION DE TASA APLICAR EN MORA
                     begin
                        if @w_signo = '+'
                           select  @w_porcentaje =  @w_vr_valor + @w_factor
                        if @w_signo = '-'
                           select  @w_porcentaje =  @w_vr_valor - @w_factor
                        if @w_signo = '/'
                           select  @w_porcentaje =  @w_vr_valor / @w_factor
                        if @w_signo = '*'
                           select  @w_porcentaje =  @w_vr_valor * @w_factor
                           
                        select @w_porcentaje_int = @w_porcentaje   
                     end
                  end                                        
               END
               --LPO DEMO BANITSMO (FIN)                
            end 
            --  JRU REGLA TASAS
            
            if (@w_concepto = @w_siglas_com_pta and @i_grupal = 'S')
               SELECT @w_porcentaje = isnull(@i_tasa_grupal, @i_tasa) * 2    --Doble de la Comision por administraci¾n
            
            --FIN LRE 06Sep19 Tasa Cero
            
            if (@w_concepto not in (@w_siglas_int, @w_siglas_imo)  --LRE 20/Mar/2019
                and @i_grupal <> 'S')                              --LRE 06Sep19 Condicion para individuales en donde se asigna la tasa por la regla
            begin
               if @w_signo = '+'
                  select  @w_porcentaje =  @w_vr_valor + @w_factor
               if @w_signo = '-'
                  select  @w_porcentaje =  @w_vr_valor - @w_factor
               if @w_signo = '/'
                  select  @w_porcentaje =  @w_vr_valor / @w_factor
               if @w_signo = '*'
                  select  @w_porcentaje =  @w_vr_valor * @w_factor
            end
            else
            if (@w_concepto not in (@w_siglas_com_adm, @w_siglas_com_pta)  --LRE 06Sep19 Condicion para grupales en donde se asigna la tasa 
                and @i_grupal = 'S')                                       --de la comision de adm y pago tardio a partir de lo que llega de la interface
            begin
               if @w_signo = '+'
                  select  @w_porcentaje =  @w_vr_valor + @w_factor
               if @w_signo = '-'
                  select  @w_porcentaje =  @w_vr_valor - @w_factor
               if @w_signo = '/'
                  select  @w_porcentaje =  @w_vr_valor / @w_factor
               if @w_signo = '*'
                  select  @w_porcentaje =  @w_vr_valor * @w_factor
            end
            
            if @w_tipo_rubro in ('I','F') and @i_promocion = 'S'
            begin
               select  @w_porcentaje = convert(float, cr_5.cr_max_value)
               from  cob_pac..bpl_rule r
               inner join cob_pac..bpl_rule_version   rv          on rv.rl_id = r.rl_id
                
               inner join cob_pac..bpl_condition_rule cr_1 on rv.rv_id = cr_1.rv_id and cr_1.cr_parent is null
               inner join cob_workflow..wf_variable v_1    on v_1.vb_codigo_variable = cr_1.vd_id 
                
               inner join cob_pac..bpl_condition_rule cr_2 on rv.rv_id = cr_2.rv_id and cr_2.cr_parent = cr_1.cr_id
               inner join cob_workflow..wf_variable v_2    on v_2.vb_codigo_variable = cr_2.vd_id 
                   
               inner join cob_pac..bpl_condition_rule cr_3 on rv.rv_id = cr_3.rv_id and cr_3.cr_parent = cr_2.cr_id
               inner join cob_workflow..wf_variable v_3    on v_3.vb_codigo_variable = cr_3.vd_id 
                
               inner join cob_pac..bpl_condition_rule cr_4 on rv.rv_id = cr_4.rv_id and cr_4.cr_parent = cr_3.cr_id
               inner join cob_workflow..wf_variable v_4    on v_4.vb_codigo_variable = cr_4.vd_id 
                
               inner join cob_pac..bpl_condition_rule cr_5 on rv.rv_id = cr_5.rv_id and cr_5.cr_parent = cr_4.cr_id
               inner join cob_workflow..wf_variable v_5    on v_5.vb_codigo_variable = cr_5.vd_id 
               where rl_acronym = 'TASA_GRP' and rv.rv_status = 'PRO'
               and   cr_1.cr_max_value = @i_promocion
            end
                   
            ---Esta tasa es la misma  nominal ya que no hay conversion de tasa
            select @w_porcentaje_efa = @w_porcentaje
         end -- if @w_tipo_rubro in ('O','I','M','Q','F')
         else
            if @w_tipo_rubro in ('C','V')
            begin
                 if @w_signo = '+'
                    select  @w_valor_rubro = round(@w_vr_valor+@w_factor,@w_num_dec)
                 if @w_signo = '-'
                    select  @w_valor_rubro = round(@w_vr_valor-@w_factor, @w_num_dec)
                 if @w_signo = '/'
                    select  @w_valor_rubro = round(@w_vr_valor/@w_factor, @w_num_dec)
                 if @w_signo = '*'
                    select  @w_valor_rubro = round(@w_vr_valor*@w_factor, @w_num_dec)
            end
      end
      
      select @w_redescuento = 0
      --JSA Santander
      if @w_tipo_rubro in ('I')  --and @w_concepto <> @w_siglas_int  AGI. Aplica la tasa de interes si es que se envia
      begin
          select @w_porcentaje = isnull(@i_tasa, @w_porcentaje)
      end
      
      --- CAPITAL PRINCIPAL
      if @w_tipo_rubro = 'C' and @w_concepto = @w_cap_principal
         select @w_valor_rubro = round(@w_monto,@w_num_dec)
      
      if @w_tipo_rubro = 'C' and @w_tipo = 'C' and @w_redescuento > 0
         select @w_valor_rubro = @w_monto*@w_redescuento/100.0
      
      --- CAPITAL FINACIADO
      if @w_tipo_rubro = 'C' and @w_concepto = @w_capital_financiado and @w_redescuento > 0
         select @w_valor_rubro = @w_monto*@w_redescuento/100.0
      
      if @w_fpago = 'L' or @w_fpago = 'A' or @w_fpago = 'P' or @w_fpago = 'T'
      begin
         if @w_tipo_rubro in ('O','I','F')
         begin
            select @w_valor_rubro = round(@w_porcentaje * @w_monto/100.0 + isnull(@w_valor_rubro,0), @w_num_dec)
         end
      end
   end  --DETERMINACION DE LA TASA A APLICAR

   if @w_valor_rubro is null or @w_tipo_rubro = 'M'
      select @w_valor_rubro = 0

   if @w_pmipymes = @w_concepto   --El calculo de la tasa se realiza basado en la matriz de parametrizacion
      select @w_porcentaje     = @w_factor_mipymes,
             @w_porcentaje_efa = @w_factor_mipymes
			 
    -- KDR Si el rubro no es financiado, no tiene base de cálculo.
	-- Si presenta inconvenientes relacionados a la base de calculo, Revisar validación de asignación de @w_base_calculo.
	if @w_financiado <> 'S'
	   select @w_base_calculo = null

   insert into ca_rubro_op_tmp
   (
   rot_operacion,           rot_concepto,        rot_tipo_rubro,
   rot_fpago,               rot_prioridad,       rot_paga_mora,
   rot_provisiona,          rot_signo,           rot_factor,
   rot_referencial,         rot_signo_reajuste,  rot_factor_reajuste,
   rot_referencial_reajuste,rot_valor,           rot_porcentaje,
   rot_porcentaje_aux,      rot_gracia,          rot_concepto_asociado,
   rot_principal,           rot_porcentaje_efa,  rot_garantia,
   rot_tipo_puntos,         rot_saldo_op,        rot_saldo_por_desem,
   rot_num_dec,             rot_limite,          rot_tipo_garantia,
   rot_nro_garantia,        rot_porcentaje_cobertura,   rot_valor_garantia,
   rot_tperiodo,            rot_periodo,         rot_base_calculo,
   rot_tabla,               rot_porcentaje_cobrar,   rot_calcular_devolucion,
   rot_saldo_insoluto,      rot_financiado,          rot_tasa_maxima,
   rot_tasa_minima
   )
   values
   (
   @w_operacionca,          @w_concepto,               @w_tipo_rubro,
   @w_fpago,                @w_prioridad,              @w_paga_mora,
   @w_provisiona,           @w_signo,                  @w_factor,
   @w_referencial,          @w_signo_reaj,             @w_factor_reaj,
   @w_ref_reajuste,         @w_valor_rubro,            @w_porcentaje,
   @w_porcentaje,           0,                         @w_concepto_asociado,
   @w_principal,            @w_porcentaje_efa,                         0,
   @w_tipo_puntos,          @w_saldo_operacion,        @w_saldo_por_desem,
   @w_num_dec_tapl,         @w_limite,                 @w_tipo_garantia,
   @w_nro_garantia,         @w_porcentaje_cobertura,   @w_valor_garantia,
   @w_tperiodo,             @w_periodo,                @w_base_calculo,
   @w_tabla_tasa,           @w_porcentaje_cobrar,      @w_calcular_devolucion,
   @w_saldo_insoluto,       @w_financiado,             @w_tasa_maxima,
   @w_tasa_minima
   )

   if @@error <> 0
   begin

     close rubros
     deallocate rubros
     return 721407
   end
   NEXT:
   fetch rubros into
         @w_concepto,         @w_prioridad,         @w_tipo_rubro,           @w_paga_mora,
         @w_provisiona,       @w_fpago,             @w_periodo,              @w_referencial,
         @w_ref_reajuste,     @w_concepto_asociado, @w_principal,            @w_redescuento,
         @w_saldo_operacion,  @w_saldo_por_desem,   @w_pit,                  @w_limite,
         @w_iva_siempre,      @w_monto_aprobado,    @w_porcentaje_cobrar,    @w_tperiodo,
         @w_tipo_garantia,    @w_valor_garantia,    @w_porcentaje_cobertura, @w_tabla_tasa,
         @w_saldo_insoluto,   @w_calcular_devolucion, @w_financiado,         @w_tasa_maxima,
         @w_tasa_minima
end

close rubros
deallocate rubros

-- AMP 2022-02-21 VERSION BASE NO RESPETABA PARAMETRIZACION DE TASA APLICAR EN MORA
/*
--LRE 22/Mar/2019 Asignar el doble de la tasa de interes como tasa IMO

if @i_financiados = 'N'
begin
   select @w_ro_porcentaje = rot_porcentaje
   from cob_cartera..ca_rubro_op_tmp
   where rot_operacion = @i_operacionca
   and   rot_concepto  = @w_siglas_int
   
   if @@rowcount = 0
   begin
      print '(genrtmp.sp) Tasa de Interes. No se obtiene tasa Rubro INT' + cast(@w_ro_porcentaje as varchar)
      return 701130
   end

   select @w_ro_porcentaje = @w_ro_porcentaje * 2

   update cob_cartera..ca_rubro_op_tmp 
      set rot_porcentaje = @w_ro_porcentaje
   where rot_operacion = @i_operacionca
   and   rot_concepto  = @w_siglas_imo

   if @@error <> 0 
   begin
      print '(genrtmp.sp) Tasa de Interes Mora. Erros al actualizar tasa Rubro IMO'
      return 710002
   end
end
*/


---ELIMINACION DE LOS RUBROS DE LA OPERACION PARA RUBRO ASOCIADO  <> NULL, POR LO GENERAL RUBRO IVA

--LPO CDIG Sintaxis Mysql una tabla no es soportada en una misma sentencia INICIO
/*
delete ca_rubro_op_tmp
where  rot_operacion = @i_operacionca
  and  rot_concepto_asociado in (select rot_concepto from ca_rubro_op_tmp where rot_operacion = @i_operacionca)
*/

CREATE TABLE #rubro_op_tmp
(
tmp_concepto VARCHAR(10) NULL
)
INSERT INTO #rubro_op_tmp (tmp_concepto)
SELECT rot_concepto from ca_rubro_op_tmp where rot_operacion = @i_operacionca

delete ca_rubro_op_tmp with (rowlock)
where  rot_operacion = @i_operacionca
  and  rot_concepto_asociado in (SELECT tmp_concepto FROM #rubro_op_tmp)

--LPO CDIG Sintaxis Mysql una tabla no es soportada en una misma sentencia FIN


---INSERCION DE LOS RUBROS DE LA OPERACION PARA RUBRO ASOCIADO  <> NULL, POR LO GENERAL RUBRO IVA
declare rubros_asociados cursor for
select  ru_concepto,   ru_prioridad,          ru_tipo_rubro,   ru_paga_mora,
        ru_provisiona, ru_fpago,              ru_periodo,      ru_referencial,
        ru_reajuste,   ru_concepto_asociado,  ru_principal,    ru_redescuento,
        ru_saldo_op,   ru_saldo_por_desem,    ru_pit,          ru_limite,
        ru_iva_siempre, ru_tperiodo,          ru_saldo_insoluto, ru_financiado,
        ru_tasa_maxima, ru_tasa_minima
from ca_rubro
where ru_toperacion  = @w_toperacion
and ru_moneda        = @w_moneda
and ru_estado        = 'V'
and ru_concepto_asociado is not null

for read only

open rubros_asociados

fetch rubros_asociados into
        @w_concepto_a,         @w_prioridad_a,         @w_tipo_rubro_a, @w_paga_mora_a,
        @w_provisiona_a,       @w_fpago_a,             @w_periodo_a,    @w_referencial_a,
        @w_ref_reajuste_a,     @w_concepto_asociado_a, @w_principal_a,  @w_redescuento_a,
        @w_saldo_operacion_a,  @w_saldo_por_desem_a,   @w_pit_a,        @w_limite_a,
        @w_iva_siempre,        @w_tperiodo_a,          @w_saldo_insoluto, @w_financiado,
        @w_tasa_maxima,        @w_tasa_minima

while @@fetch_status = 0
begin

   ---INICIAR VARIABLES
   select
   @w_porcentaje_a     = 0,
   @w_valor_rubro_a    = 0,
   @w_vr_valor_a       = 0,
   @w_signo_a          = null,
   @w_factor_a         = 0,
   @w_signo_reaj_a     = null,
   @w_factor_reaj_a    = 0,
   @w_tipo_val_a       = null,
   @w_clase_a          = null,
   @w_signo_pit_a      = null,
   @w_spread_pit_a     = 0,
   @w_tasa_pit_a       = null,
   @w_clase_pit_a      = null,
   @w_porcentaje_pit_a = 0,
   @w_num_dec_tapl_a   = null,
   @w_porcentaje_efa   = 0

   select @w_valor_rubro_asociado = rot_valor
   from ca_rubro_op_tmp with (nolock)
   where rot_operacion  = @w_operacionca
   and rot_concepto = @w_concepto_asociado_a

   if isnull(@w_valor_rubro_asociado,0) = 0
      goto NEXT2

   --- DETERMINACION DE LA TASA A APLICAR
   select
   @w_signo_a       = isnull(vd_signo_default,' '),
   @w_factor_a      = isnull(vd_valor_default,0),
   @w_tipo_val_a    = vd_referencia,
   @w_tipo_puntos_a = vd_tipo_puntos,
   @w_clase_a       = va_clase,
   @w_num_dec_tapl_a  = vd_num_dec
   from    ca_valor,ca_valor_det
   where   va_tipo   = @w_referencial_a
   and     vd_tipo   = @w_referencial_a
   and     vd_sector = @w_sector

   if @@rowcount = 0
   begin
     close rubros_asociados
     deallocate rubros_asociados
	 --GFP se suprime print
     --print '(genrtmp.sp) concepto asociado. Parametrizar Tasa para rubro' + cast(@w_referencial_a as varchar)
     return 721404
   end

   select @w_valor_rubro_a = round(@w_factor_a * @w_valor_rubro_asociado / 100.0, @w_num_dec)

   if @w_tipo_rubro_a = 'O' and  @w_iva_siempre = 'S'  ---Paraemtro por LINEA y Modificable por operacion
   begin
     ---CONCEPTO CONTABLE QUE IDENTIFICA EL IVA PARA CONSULTAR SI EL CLIENTE ES EXENTO O NO
      select @w_concepto_conta_iva = pa_char
      from cobis..cl_parametro
      where pa_producto = 'CCA'
      and pa_nemonico  =  'CONIVA'
      and  pa_producto = 'CCA'

      if @@rowcount = 0
      begin
          close rubros_asociados
          deallocate rubros_asociados
          return 710449
      end
  
      select @w_grupal = isnull(tr_grupal,'N'),
             @w_exento = 'S' 
	    from cob_credito..cr_tramite
       where tr_tramite = @w_tramite
      
      if (@w_grupal = 'N')
      begin
         exec @w_error        = cob_conta..sp_exenciu
              @s_date         = @s_date,
              @s_user         = @s_user,
              @s_term         = @s_term,
              @s_ofi          = @s_ofi,
              @t_trn          = 6251,
              @t_debug        = 'N',
              @i_operacion    = 'F',
              @i_empresa      = 1,
              @i_impuesto     = 'V',             ---Iva   T timbre
              @i_concepto     = @w_concepto_conta_iva,
              @i_debcred      = 'C',            ---Valor D'bito o Cr'dito
              @i_ente         = @w_cliente,     ---C+digo  COBIS del cliente
              @i_oforig_admin = @s_ofi,         ---C+digo COBIS de la oficina origen Admin
              @i_ofdest_admin = @w_op_oficina,  ---C+digo COBIS de la oficina destino Admin
              @i_producto     = 7,              ---Codigo del producto CARTERA
              @o_exento       = @w_exento  out
         
         if @w_error <> 0
         begin
            close rubros_asociados
            deallocate rubros_asociados
            return 710457
         end
      end
      if @w_exento = 'S'
         select @w_valor_rubro_a = 0
   end  ---Validaciones  Iva

   if @w_valor_rubro_a is null
      select @w_valor_rubro_a = 0

   insert into ca_rubro_op_tmp (
   rot_operacion,           rot_concepto,         rot_tipo_rubro,
   rot_fpago,               rot_prioridad,        rot_paga_mora,
   rot_provisiona,          rot_signo,            rot_factor,
   rot_referencial,         rot_signo_reajuste,   rot_factor_reajuste,
   rot_referencial_reajuste,rot_valor,            rot_porcentaje,
   rot_porcentaje_aux,      rot_gracia,           rot_concepto_asociado,
   rot_principal,           rot_porcentaje_efa,   rot_garantia,
   rot_tipo_puntos,         rot_saldo_op,         rot_saldo_por_desem,
   rot_base_calculo,        rot_num_dec,          rot_limite,
   rot_tperiodo,            rot_periodo,          rot_saldo_insoluto,
   rot_financiado,          rot_tasa_maxima,      rot_tasa_minima)
   values (
   @w_operacionca,          @w_concepto_a,        @w_tipo_rubro_a,
   @w_fpago_a,              @w_prioridad_a,       @w_paga_mora_a,
   @w_provisiona_a,         @w_signo_a,           0,
   @w_referencial_a,        @w_signo_reaj_a,      @w_factor_reaj_a,
   @w_ref_reajuste_a,       @w_valor_rubro_a,     @w_factor_a,
   @w_factor_a,             @w_factor_a,          @w_concepto_asociado_a,
   @w_principal_a,          0,                    0,
   @w_tipo_puntos_a,        @w_saldo_operacion_a, @w_saldo_por_desem_a,
   @w_valor_rubro_asociado, @w_num_dec_tapl_a,    @w_limite_a,
   @w_tperiodo_a,           @w_periodo_a,         @w_saldo_insoluto,
   @w_financiado,           @w_tasa_maxima,       @w_tasa_minima)

   if @@error <> 0
   begin
    close rubros_asociados
    deallocate rubros_asociados
    return  721408
   end
   NEXT2:
  fetch rubros_asociados into    @w_concepto_a,       @w_prioridad_a,    @w_tipo_rubro_a,  @w_paga_mora_a,
          @w_provisiona_a,       @w_fpago_a,          @w_periodo_a,
          @w_referencial_a,      @w_ref_reajuste_a,   @w_concepto_asociado_a,
          @w_principal_a,        @w_redescuento_a,
          @w_saldo_operacion_a,  @w_saldo_por_desem_a,@w_pit_a,@w_limite_a,
          @w_iva_siempre,        @w_tperiodo_a,       @w_saldo_insoluto,
          @w_financiado,         @w_tasa_maxima,      @w_tasa_minima
end

close rubros_asociados
deallocate rubros_asociados

/*CONTROL DE LA TASA IBC Y TASA MAX Y MIN ANTES DE CREAR LA OP*/
exec @w_error          = sp_rubro_control_ibc
     @i_operacionca    = @w_operacionca,
     @i_concepto       = @w_siglas_int,
     @i_porcentaje     = @w_porcentaje_int,
     @i_periodo_o      = null,
     @i_modalidad_o    = null,
     @i_num_periodo_o  = 1

if @w_error <> 0
   return @w_error
   
return 0

GO
