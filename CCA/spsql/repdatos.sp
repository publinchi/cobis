/************************************************************************/
/*   NOMBRE LOGICO:      repdatos.sp                                    */
/*   NOMBRE FISICO:      sp_reporte_datos                               */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Adriana Giler                                  */
/*   FECHA DE ESCRITURA: 12 de Feb 2019                                 */
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
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                     PROPOSITO                                        */
/*    Reportes de Cartera                                               */
/************************************************************************/
/*                              CAMBIOS                                 */
/*                                                                      */
/*  29/04/2019    L. Gerardo Barron   Se agrega descripcion de producto */
/*  09/05/2019    L. Gerardo Barron   Se agrega opcion para estado de cuenta */
/*  23/07/2019    G. Guaman           Se agrega el nemonico para los SP */
/*  29/07/2019    J. Tomala           Se agrega Operacion S para la con_*/
/*                                    sulta de certificado de prevencion*/
/*  07/08/2019    G. Guaman           Se modifica operacion G de inner join */
/*  08/08/2019    J. Tomala           Operacion D se agrega columna para*/
/*                                    el codigo del tipo de operacion   */
/*  22/08/2019    G. Guaman           Se agrega id y descripcion de     */
/*                                    grupo en la opcion G              */
/*  22/08/2019    A. miramon          Se modifica la generación de      */
/*                                    estado de cuenta para diferenciar */
/*                                    credito grupal e individual       */
/*  18/10/2019    A. Martinez         Se modifica para generacion de rep*/
/*                                    AnexDataHolder ya que la info     */
/*                                    generada estaba de forma incorrecta*/
/*  06/12/2019    L.Gerardo Barron    Se modifica el sp para generar la referencia de pago*/
/*  23/12/2019    L.Gerardo Barron    Se modifica el sp por requerimiento de documentos y correccion*/
/*  05/01/2020    Gerardo Barron      correcciones del requerimiento de documentos*/
/*  08/01/2020    Gerardo Barron      correccion en la tabla de amortizacion para mostrar el SINCAPAC*/
/*  14/01/2020    Gerardo Barron      Se agrega seccion de Testigo en el Pagare*/
/*  28/02/2023    K. Rodriguez        S787837 Ajustes reporte de tabla  */
/*                                    de amortizacion                   */
/*  21/06/2023    G. Fernandez        S846544 Se elimina Join con estado*/
/*                                   de tablas para direccion de cliente*/
/*  04/09/2024    K. Rodriguez        R242440 Cambio valor tasa imo en  */
/*                                    Reporte de tabla amortizacion.    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reporte_datos')
   drop proc sp_reporte_datos
go

create proc sp_reporte_datos
@s_user           login       = null,
@s_term           varchar(30) = null,
@s_date           datetime    = null,
@s_ofi            smallint    = null,
@s_ssn            int         = null,
@s_sesn           int         = null,
@s_srv            varchar(30) = null,
@t_trn            int,
@t_debug          char(1)      = 'N',
@t_file           varchar(14)  = null,
@i_operacion      char(1),
@i_cliente        INT = null,
@i_cod_reporte    smallint,
@i_banco          varchar(20) = null,
@i_nemonico       varchar(10)  = null         --GG 23/07/2019

as 

declare  @w_sp_name                     varchar(30),
         @w_error                       int,
         @w_return                      int,
         @w_cod_clte_bco                int,            
         @w_plazoDomicilio              smallint,
         @w_numDiasFall                 smallint,        
         @w_numDiasInt                  smallint,         
         @w_numDiasMor                  smallint,         
         @w_intRedBienes                tinyint,       
         @w_diasFactBienes              smallint,     
         @w_diasCanAnt                  smallint,         
         @w_diasConsCancelacion         smallint, 
         @w_diasMinCancelacion          smallint, 
         @w_diasMinCancelacionL         varchar(100), 
         @w_diasSolInformacion          smallint, 
         @w_diasSolInformacionL         varchar(100),
         @w_diasQuejas                  smallint,         
         @w_NotQuejas                   varchar(100),          
         @w_diasRespQuejas              smallint,     
         @w_diasRespQuejasInt           smallint,  
         @w_diasRevQuejas               smallint,       
         @w_fono1Condusef               varchar(25),        
         @w_fono2Condusef               varchar(25),        
         @w_urlCondusef                 varchar(60),            
         @w_emlCondusef                 varchar(60),            
         @w_diasNotCamb                 smallint,       
         @w_diasNotCambL                varchar(100),       
         @w_urlBanco                    varchar(60),            
         @w_diasRechCamb                smallint,
         @w_cod_direc                   int,
         @w_domicilio                   varchar(200),        
         @w_provincia                   varchar(60),            
         @w_correoOficina               varchar(60), 
         @w_fono_banco                  varchar(60), 
         @w_nom_cliente                 varchar(100),           
         @w_nom_conyuge                 varchar(100),
         @w_ecivil                      varchar(10),
         @w_pie_pagina                  varchar(60),
         @w_entregaEfectivo             smallint,
         @w_inactivida_cta              smallint,
         @w_equivalencia_min            smallint,
         @w_fondo_proteccion            int,
         @w_fondo_proteccionL           varchar(100),
         @w_estado_cuenta               SMALLINT,
         @w_numero_operacion            int,
         @w_numero_cliente              int,
         @w_cat                         decimal(18,2),
         @w_tasa_ordinaria              decimal(18,2),
         @w_tasa_moratoria              decimal(18,2),
         @w_monto_credito               decimal(18,2),
         @w_monto_total                 decimal(18,2),
         @w_plazo_credito               int,
         @w_frecuencia_credito          varchar(20),
         @w_fecha_pago                  varchar(10),
         @w_dom_aclaraciones            varchar(300),
         @w_nombre_cliente              varchar(100),
         @w_obligado_1                  varchar(100),
         @w_obligado_2                  varchar(100),
         @w_tipo_operacion              varchar(150),
         @w_desc_operacion              varchar(50),
         @w_tipo_plazo_credito          catalogo,
         @w_dom_regional                varchar(100),
         @w_num_oficina                 int,
         @w_imo                         decimal(18,2),
         @w_imo_mensual                 decimal(18,2),
         @w_sucursal_provincia          varchar(50),
         @w_dom_cliente                 varchar(100),
         @w_comision                    decimal(18,2),
         @w_comision_iva                decimal(18,2),
         @w_gastos_originacion          decimal(18,2),
         @w_cliente_calle               varchar(50),
         @w_cliente_num_ext             varchar(50),
         @w_cliente_parroquia           varchar(50),
         @w_cliente_ciudad              varchar(50),
         @w_cliente_provincia           varchar(50),
         @w_cliente_codpostal           varchar(50),
         @w_fecha_ini_credito           datetime,
		 @w_fecha_liq_credito           datetime,
         @w_tipo_producto               varchar(100),
         @w_monto                       varchar(100),
         @w_per_administracion          varchar(100),
         @w_per_cobranza                varchar(100),
         @w_per_invest                  varchar(100),
         @w_c_anexo                     int,
         @w_monthlyInterestRateText     varchar(512),
         @w_totalAmountText             varchar(512),
         @w_filial                      int,
         @w_clarificationsPhone         varchar(100),
         @w_email                       varchar(100),
         @w_pagina_internet             varchar(100),
         @w_firma                       varchar(100),
         @w_cliente_nombre              varchar(50),
         @w_cliente_apellido_paterno    varchar(50),
         @w_cliente_apellido_materno    varchar(50),
         @w_cliente_telefono            varchar(30),
         @w_cliente_curp                varchar(15),
         @w_cliente_rfc                 varchar(15),
         @w_fecha_nac                   varchar(10),
         @w_nacionalidad                varchar(15),
         @w_nacionalidad_cod            int,
         @w_sexo_cod                    char(1),
         @w_genero                      varchar(15),
         @w_saldo_promedio              decimal(18,2),
         @w_mov_esperados               int,
         @w_ocupacion                   varchar(100),
         @w_trabaja_en                  varchar(100),
         @w_forma_migratoria            varchar(50),
         @w_numero_extranjero           varchar(50),
         @w_domicilio_origen            varchar(200),
         @w_rfc_origen                  varchar(15),
         @w_oficina_credito             int,
         @w_oficina_descrip_credito     varchar(100),
         @w_oficina_dir_credito         varchar(200),
         @w_regional_cod                int,
         @w_regional_descrip            varchar(200),
         @w_regional_dir                varchar(200),
         @w_nom_solidario1              varchar(200),
         @w_nom_solidario2              varchar(200),
         @w_profesion_cod               catalogo,
         @w_numero_referencia           varchar(24),
         @w_referencia_walmart          varchar(24),
         @w_fecha_concesion             varchar(15),
         @w_estado_credito              smallint,
         @w_estado_credito_nom          varchar(50),
         @w_fecha_vencimiento           varchar(50),
         @w_pago_liquidar               decimal(18,2),
         @w_cuota_actual                decimal(18,2),
         @w_saldo_vencido               decimal(18,2),
         @w_cap_no_vigente              decimal(18,2),
         @w_pago_minimo                 decimal(18,2),
         @w_oficina_telefono            varchar(20),
         @w_regional_telefono           varchar(20),
         @w_saldo                       decimal(18,2),
         @w_saldot                      decimal(18,2),
         @w_fecha                       datetime,
         @w_capital                     varchar(10),  --AMG 08/10/2019
         @w_interes                     varchar(10),  --AMG 08/10/2019
         @w_ivaInteres                  varchar(10),  --AMG 08/10/2019
         @w_imora                       varchar(10),  --AMG 08/10/2019
         @w_ivaImora                    varchar(10),  --AMG 08/10/2019
         @w_cmora                       varchar(10),  --AMG 08/10/2019
         @w_ivaCmora                    varchar(10),  --AMG 08/10/2019
         @w_comGco                      varchar(10),  --AMG 08/10/2019
         @w_ivaComGco                   varchar(10),  --AMG 08/10/2019
         @w_comPta                      varchar(10),  --AMG 08/10/2019
         @w_ivaComPta                   varchar(10),  --AMG 08/10/2019
         @w_serInc                      varchar(10),  --AMG 08/10/2019
         @w_ivaSerInc                   varchar(10),  --AMG 08/10/2019
         @w_datos_1                     varchar(400),
         @w_datos_2                     varchar(400),
         @w_rfc_banco                   varchar(20),
         @w_groupName                   varchar(30),  --GG 22/08/2019
         @w_groupNum                    int,          --GG 23/07/2019
         @w_tipoCredito                 char(1),      --AMG 08/10/2019
         @w_porcAhorro                  varchar(25) = 'N/A'   --AAMD 17/10/2019
	   , @w_cont2          		tinyint   			--LGBC 06/12/2019
	   , @w_cont3          		tinyint				--LGBC 06/12/2019
	   , @wi_referencia1   		varchar(17)		--LGBC 06/12/2019
       , @wi_referencia2   		varchar(17)		--LGBC 06/12/2019
	   , @w_paytel         		varchar(10)		--LGBC 06/12/2019
       , @w_wallmart       		varchar(10)		--LGBC 06/12/2019
       , @w_digito         		tinyint				--LGBC 06/12/2019
       , @w_referencia1    	varchar(24)		--LGBC 06/12/2019
       , @w_referencia2    	varchar(24)		--LGBC 06/12/2019
       , @w_referencia_tmp 	varchar(24)		--LGBC 06/12/2019
       , @w_num1           		int					--LGBC 06/12/2019		
       , @w_num2           		int					--LGBC 06/12/2019
       , @w_num3           		int					--LGBC 06/12/2019
       , @w_num4           		int					--LGBC 06/12/2019
       , @w_indice         		int					--LGBC 06/12/2019
       , @w_caracter       		char(1)			--LGBC 06/12/2019
       , @w_banco          		int					--LGBC 06/12/2019
       , @w_long           		tinyint				--LGBC 06/12/2019
       , @w_cadena         		varchar(10)		--LGBC 06/12/2019
       , @w_cont           		tinyint				--LGBC 06/12/2019
       , @w_dif            			tinyint				--LGBC 06/12/2019
       , @w_cont1          		tinyint				--LGBC 06/12/2019
       , @w_lref           			char(1)			--LGBC 06/12/2019
       , @w_cadena1        	varchar(11)		--LGBC 06/12/2019
	   , @w_tramite 				int					--LGBC 05/01/2020
	   , @w_num_conyuge 	int					--LGBC 05/01/2020
	   , @w_nombre_conyuge 	varchar(100)  --LGBC 05/01/2020
	   , @w_direccion_conyuge 		varchar(200)  --LGBC 05/01/2020
	   , @w_nombre_aval 	varchar(100)  --LGBC 14/01/2020
	   , @w_direccion_aval 		varchar(200)  --LGBC 14/01/2020
	   , @w_tipo_grupal         char(1)
	   , @w_tea                 decimal(18,2)
	   , @w_openingExpense      money
	   , @w_nom_cli_grup        varchar(160)
	   , @w_fecha_proceso       datetime
	   , @w_dif_imo_int         decimal(18,2)
	   
   
-- CAPTURA NOMBRE DE STORED PROCEDURE
select @w_sp_name = 'sp_reporte_datos'
select @w_error = null
  
if  @t_trn <> 7992
begin   
    select @w_error = 2101006
    goto ERROR
end

-- Fecha proceso
select @w_fecha_proceso = fp_fecha 
from cobis..ba_fecha_proceso

select @w_pie_pagina = ''
      ---INICIO---GG 23/07/2019
if exists(select 1 from cob_credito..cr_imp_documento where id_mnemonico = @i_nemonico AND id_toperacion = (select op_toperacion from cob_cartera..ca_operacion where op_banco = @i_banco))
begin
   select @w_pie_pagina = id_dato
     from cob_credito..cr_imp_documento 
    where id_mnemonico = @i_nemonico 
      AND id_toperacion =  (select op_toperacion from cob_cartera..ca_operacion where op_banco = @i_banco) 
end   ---FIN---GG 23/07/2019
    
if not exists(select 1 from cobis..cl_ente where en_ente = @i_cliente)
begin
    select @w_error = 101146
    goto ERROR
end

-- CODIGO MIS DEL BANCO COMO CLIENTE
select @w_cod_clte_bco = pa_int
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'CCFILI'

if @@rowcount = 0 
    select @w_error = 141140

-- NUMERO DE DIAS DE NOTIFICACION POR CAMBIO DOMICILIO
select @w_plazoDomicilio = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DNOTCD'

if @@rowcount <> 1 
    select @w_error = 141140

-- NUMERO DE DIAS DE NOTIFICACION POR FALLECIMIENTO
select @w_numDiasFall = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DNOFAL'

if @@rowcount <> 1 
    select @w_error = 141140

-- NUMERO DE DIAS DE CALCULO INTERES ORDINARIO
select @w_numDiasInt = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DCALIN'
 
if @@rowcount <> 1 
    select @w_error = 141140

-- NUMERO DE DIAS DE CALCULO INTERES MORATORIO
select @w_numDiasMor = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DCAMOR'
 
if @@rowcount <> 1 
    select @w_error = 141140

-- INTERES DE REDUCCION DE BIENES
select @w_intRedBienes = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INTRED'
 
if @@rowcount <> 1 
    select @w_error = 141140

-- PLAZO EN DIAS PARA ENTREGA DE FACTURA POR COMPRA DE BIENES
select @w_diasFactBienes = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DENTFA'

if @@rowcount <> 1 
    select @w_error = 141140

-- NRO. DIAS NOTIFICACION DE CANCELACION ANTICIPADA
select @w_diasCanAnt = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DCANAN'
 
if @@rowcount <> 1 
    select @w_error = 141140

-- NRO. DIAS PARA EMITIR CONSTANCIA DE CANCELACION ANTICIPADA
select @w_diasConsCancelacion = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DCONCA'

if @@rowcount <> 1 
    select @w_error = 141140

-- NRO. DIAS MINIMO DE VIGENTE UN CREDITO PARA CANCELARLO
select @w_diasMinCancelacion = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DMINCA'
 
if @@rowcount <> 1 
    select @w_error = 141140

-- NRO. DIAS PARA SOLICITAR INFORMACION CREDITO
select @w_diasSolInformacion = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DSOLIN'

if @@rowcount <> 1 
    select @w_error = 141140

-- NRO. DIAS PARA PRESENTACION DE QUEJAS POST ESTADOS DE CUENTAS
select @w_diasQuejas = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DQUEJA'

if @@rowcount <> 1 
    select @w_error = 141140

-- CORREO DE NOTIFICACION DE QUEJAS
select @w_NotQuejas = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CQUEJA'

if @@rowcount <> 1 
    select @w_error = 141140

-- NRO. DIAS PARA RESPUESTA DE QUEJAS NACIONAL
select @w_diasRespQuejas = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DRESQN'

if @@rowcount <> 1 
    select @w_error = 141140

-- NRO. DIAS PARA RESPUESTA DE QUEJAS INTERNACIONALES
select @w_diasRespQuejasInt = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DRESQI'

if @@rowcount <> 1 
    select @w_error = 141140

-- NRO. DIAS PARA CONSULTAR RESPUESTA QUEJA
select @w_diasRevQuejas = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DREVQU'

if @@rowcount <> 1 
    select @w_error = 141140

-- CONTACTO TELEFONO 1 CONDUSEF 
select @w_fono1Condusef = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FON1CD'
 
if @@rowcount <> 1 
    select @w_error = 141140

-- CONTACTO TELEFONO 2 CONDUSEF 
select @w_fono2Condusef = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FON2CD'

if @@rowcount <> 1 
    select @w_error = 141140


-- PAGINA INTERNET CONDUSEF 
select @w_urlCondusef = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'URLCD'

if @@rowcount <> 1 
    select @w_error = 141140

-- CORREO ELECTRONICO CONDUSEF 
select @w_emlCondusef = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'EMALCD'
 
if @@rowcount <> 1 
    select @w_error = 141140


-- NRO. DIAS PARA NOTIFICAR CAMBIOS CONTRATOS
select @w_diasNotCamb = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DCAMTR'
 
if @@rowcount <> 1 
    select @w_error = 141140


-- PAGINA INTERNET BANCO 
select @w_urlBanco = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'URLBCO'

if @@rowcount <> 1 
    select @w_error = 141140


-- NRO. DIAS PARA RECHAZO DE CAMBIOS EN CONTRATO
select @w_diasRechCamb = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DRECCA'
 
if @@rowcount <> 1 
    select @w_error = 141140
        
-- TIEMPO PARA ENTREGA DE EFECTIVO CUANDO CAJA NO TIENE FONDOS
select @w_entregaEfectivo = pa_smallint 
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'ENTEFE'
 
if @@rowcount <> 1 
    select @w_error = 141140    
    
-- VALOR EQUIVALENTE AL SALARIO MINIMO
select @w_equivalencia_min = pa_smallint 
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'EQUMIN'
 
if @@rowcount <> 1 
    select @w_error = 141140    

--TIEMPO EN AÃ‘O DE INACTIVIDAD DE CUENTA
select @w_inactivida_cta = pa_smallint 
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INACTA'
 
if @@rowcount <> 1 
    select @w_error = 141140        
    
--VALOR DEL FONDO DE PROTECCION
select @w_fondo_proteccion = pa_int 
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'FONPRO'
 
if @@rowcount <> 1 
    select @w_error = 141140            
    
--DIAS. ENTREGA ESTADO CUENTA
select @w_estado_cuenta = pa_smallint 
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'ESTCTA'
 
if @@rowcount <> 1 
    select @w_error = 141140     

    
if @w_error = 141140
    goto ERROR
    
select @w_domicilio  = di_descripcion,
       --@w_provincia  = pv_descripcion,
       @w_cod_direc  = di_direccion
from cobis..cl_direccion--, cobis..cl_ciudad, cobis..cl_provincia
where di_ente = @w_cod_clte_bco
and   di_tipo = 'RE'
and   di_direccion = (select max(di_direccion) from cobis..cl_direccion
                      where di_ente = @w_cod_clte_bco
                      and   di_tipo = 'RE')
--and   di_ciudad = ci_ciudad
--and   ci_provincia = pv_provincia
                       
select @w_correoOficina = di_descripcion
from cobis..cl_direccion
where di_ente = @w_cod_clte_bco
and   di_tipo = 'CE'
and   di_direccion = (select max(di_direccion) from cobis..cl_direccion
                      where di_ente = @w_cod_clte_bco
                      and   di_tipo = 'CE')                    
                    
select @w_fono_banco = te_valor
from cobis..cl_telefono
where te_ente = @w_cod_clte_bco 
  and te_direccion = @w_cod_direc
  and te_secuencial = (select max(te_secuencial) from cobis..cl_telefono
                       where te_ente = @w_cod_clte_bco  
                       and te_direccion = @w_cod_direc)
                       
select @w_pagina_internet = isnull(di_descripcion,'')
from cobis..cl_direccion
where di_ente = @w_cod_clte_bco
and   di_tipo = 'PE'
and   di_direccion = (select max(di_direccion) from cobis..cl_direccion
                      where di_ente = @w_cod_clte_bco
                      and   di_tipo = 'PE') 

-- Tipo de operación [G: Grupal Padre, H: Grupal Hija, N: Individual]
if exists (select 1 from ca_operacion
           where op_banco = @i_banco
		   and op_grupal = 'S'
		   and op_ref_grupal is null)
   select @w_tipo_grupal = 'G'			  
else if exists (select 1 from ca_operacion
           where op_banco = @i_banco
		   and op_grupal = 'S'
		   and op_ref_grupal is not null)
   select @w_tipo_grupal = 'H'
else
   select @w_tipo_grupal = 'N'
   
--Datos para reporte de NEGOCIOS SI 
if @i_operacion = 'B'   
Begin


    select @w_nom_cliente = en_nomlar,
           @w_ecivil      = p_estado_civil
    from cobis..cl_ente 
    where en_ente = @i_cliente
    
    if @w_ecivil in ('CA', 'UN')
    begin
        select @w_nom_conyuge = en_nomlar
        from cobis..cl_ente, cobis..cl_instancia
        where en_ente = in_ente_d
          and in_ente_i = @i_cliente
          and in_relacion = 209
    end
    
    exec @w_diasMinCancelacionL  = dbo.CantidadConLetra @Numero = @w_diasMinCancelacion
    exec @w_diasSolInformacionL  = dbo.CantidadConLetra @Numero = @w_diasSolInformacion
    exec @w_diasNotCambL         = dbo.CantidadConLetra @Numero = @w_diasNotCamb    
	
	--Se obtienen los datos del banco
	select @w_domicilio = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 1
	
	select @w_fono_banco = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 6
	
	select @w_correoOficina = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 4
	
	select @w_fono1Condusef = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 7
	
	select @w_fono2Condusef = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 8
    
   --Devolviendo Resultados
    select @w_plazoDomicilio,                   -- NUMERO DE DIAS DE NOTIFICACION POR CAMBIO DOMICILIO
           @w_numDiasFall,                      -- NUMERO DE DIAS DE NOTIFICACION POR FALLECIMIENTO
           @w_numDiasInt,                       -- NUMERO DE DIAS DE CALCULO INTERES ORDINARIO
           @w_numDiasMor,                       -- NUMERO DE DIAS DE CALCULO INTERES MORATORIO
           @w_intRedBienes,                     -- INTERES DE REDUCCION DE BIENES
           @w_diasFactBienes,                   -- PLAZO EN DIAS PARA ENTREGA DE FACTURA POR COMPRA DE BIENES
           @w_diasCanAnt,                       -- NRO. DIAS NOTIFICACION DE CANCELACION ANTICIPADA
           @w_diasConsCancelacion,              -- NRO. DIAS PARA EMITIR CONSTANCIA DE CANCELACION ANTICIPADA
           @w_diasMinCancelacionL,              -- NRO. DIAS MINIMO DE VIGENTE UN CREDITO PARA CANCELARLO (LETRAS)
           @w_diasSolInformacionL,              -- NRO. DIAS PARA SOLICITAR INFORMACION CREDITO (LETRAS)
           @w_diasQuejas,                       -- NRO. DIAS PARA PRESENTACION DE QUEJAS POST ESTADOS DE CUENTAS
           @w_NotQuejas,                        -- CORREO DE NOTIFICACION DE QUEJAS
           @w_diasRespQuejas,                   -- NRO. DIAS PARA RESPUESTA DE QUEJAS NACIONAL
           @w_diasRespQuejasInt,                -- NRO. DIAS PARA RESPUESTA DE QUEJAS INTERNACIONALES
           @w_diasRevQuejas,                    -- NRO. DIAS PARA CONSULTAR RESPUESTA QUEJA
           @w_fono1Condusef,                    -- CONTACTO TELEFONO 1 CONDUSEF 
           @w_fono2Condusef,                    -- CONTACTO TELEFONO 2 CONDUSEF 
           @w_urlCondusef,                      -- PAGINA INTERNET CONDUSEF 
           @w_emlCondusef,                      -- CORREO ELECTRONICO CONDUSEF 
           @w_diasNotCamb,                      -- NRO. DIAS PARA NOTIFICAR CAMBIOS CONTRATOS
           @w_urlBanco,                         -- PAGINA INTERNET BANCO 
           @w_diasRechCamb,                     -- NRO. DIAS PARA RECHAZO DE CAMBIOS EN CONTRATO
           @w_domicilio,                        -- DOMICILIO DEL BANCO
           @w_provincia,                        -- PROVINCIA DEL DOMICILIO DEL BANCO
           @w_fono_banco,                       -- TELEFONO DEL BANCO
           @w_correoOficina,                    -- CORREO DEL BANCO
           @w_nom_cliente,                      -- NOMBRE CLIENTE 
           @w_nom_conyuge,                      -- NOMBRE CONYUGE
           @w_pie_pagina,                       -- PIE DE PAGINA
           @w_diasNotCambL                      -- NRO. DIAS PARA NOTIFICAR CAMBIOS CONTRATOS LETRAS
End 


--Datos para reporte de CONTRATO DE DEPOSITO DE AHORRO 
if @i_operacion = 'C'   
Begin


    select @w_nom_cliente = en_nomlar
    from cobis..cl_ente 
    where en_ente = @i_cliente
    
    exec @w_fondo_proteccionL = dbo.CantidadConLetra @Numero = @w_fondo_proteccion
    
    Select @w_domicilio,                        -- DOMICILIO DEL BANCO
           @w_provincia,                        -- PROVINCIA DEL DOMICILIO DEL BANCO
           @w_urlBanco,                         -- PAGINA INTERNET BANCO
           @w_plazoDomicilio,                   -- NUMERO DE DIAS DE NOTIFICACION POR CAMBIO DOMICILIO
           @w_entregaEfectivo,                  -- DIAS PARA ENTREGA EFECTIVO CUANDO NO HAY FONDO EN CAJA   
           @w_numDiasInt,                       -- NUMERO DE DIAS DE CALCULO INTERES ORDINARIO
           @w_inactivida_cta,                   -- VALOR EQUIVALENTE AL SALARIO MINIMO
           @w_equivalencia_min,                 -- TIEMPO EN AÃ‘O DE INACTIVIDAD DE CUENTA
           @w_diasQuejas,                       -- NRO. DIAS PARA PRESENTACION DE QUEJAS POST ESTADOS DE CUENTAS
           @w_NotQuejas,                        -- CORREO DE NOTIFICACION DE QUEJAS
           @w_diasRespQuejas,                   -- NRO. DIAS PARA RESPUESTA DE QUEJAS NACIONAL
           @w_diasRespQuejasInt,                -- NRO. DIAS PARA RESPUESTA DE QUEJAS INTERNACIONALES
           @w_diasRevQuejas,                    -- NRO. DIAS PARA CONSULTAR RESPUESTA QUEJA
           @w_fono1Condusef,                    -- CONTACTO TELEFONO 1 CONDUSEF 
           @w_fono2Condusef,                    -- CONTACTO TELEFONO 2 CONDUSEF 
           @w_urlCondusef,                      -- PAGINA INTERNET CONDUSEF 
           @w_emlCondusef,                      -- CORREO ELECTRONICO CONDUSEF 
           @w_diasNotCamb,                      -- NRO. DIAS PARA NOTIFICAR CAMBIOS CONTRATOS
           @w_diasRechCamb,                     -- NRO. DIAS PARA RECHAZO DE CAMBIOS EN CONTRATO
           @w_diasCanAnt,                       -- NRO. DIAS NOTIFICACION DE CANCELACION ANTICIPADA
           @w_fondo_proteccionL,                -- VALOR DEL FONDO DE PROTECCION LETRAS
           @w_nom_cliente,                      -- NOMBRE CLIENTE
           @w_pie_pagina,                       -- PIE DE PAGINA
           @w_numDiasFall,                      -- NUMERO DE DIAS DE NOTIFICACION POR FALLECIMIENTO
           @w_estado_cuenta                     -- NRO. DE DIAS A TRANSCURRIR PARA SOLICITAR ESTADO DE CUENTA
End

--Datos para reporte de CARATULA DE OPERACION FINANCIERA
if @i_operacion = 'D'   
BEGIN


    --Se obtienen datos de ca_operacion
    select @w_numero_operacion = op_operacion
             , @w_numero_cliente = op_cliente
             , @w_tipo_operacion = op_toperacion
             , @w_cat = isnull(op_valor_cat,0)
             , @w_monto_credito = op_monto
             , @w_plazo_credito = op_plazo
             , @w_tipo_plazo_credito = op_tplazo
    from cob_cartera..ca_operacion
    where op_banco = @i_banco
    
    --Se obtiene el nombre completo del cliente
    select @w_nom_cliente = en_nombre + ' ' + p_p_apellido + ' ' +  p_s_apellido
             , @w_filial = isnull(en_filial,0)
    from cobis..cl_ente
    where en_ente = @w_numero_cliente
    
    --Se obtiene la descripcion de la frecuencia de pago
    select @w_frecuencia_credito = td_descripcion
    from cob_cartera..ca_tdividendo
    where td_tdividendo = @w_tipo_plazo_credito and td_estado = 'V'
    
    --Se obtiene el monto total a pagar
    select @w_monto_total = isnull(sum(am_cuota), 0)
    from cob_cartera..ca_amortizacion 
    where am_operacion = @w_numero_operacion
    
    --Se obtiene la fecha de pago
    select @w_fecha_pago = convert(varchar,di_fecha_ven,103)
    from cob_cartera..ca_dividendo
    where di_operacion = @w_numero_operacion and di_dividendo = 1
    
    --Se consulta la descripcion de la operacion
    select @w_desc_operacion = upper(b.valor)
    from cobis..cl_tabla as a
    inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_toperacion' and b.codigo = @w_tipo_operacion
    
    --Se obtiene la tasa ordinaria
    select @w_tasa_ordinaria = isnull(round(convert(decimal(18,2), sum(ro_porcentaje)) , 2), 0)
    from cob_cartera..ca_rubro_op, cob_cartera..ca_concepto
    where ro_operacion = @w_numero_operacion
    and ro_concepto = co_concepto
    and co_categoria = 'I'
	
	select @w_tasa_moratoria = isnull(round(convert(decimal(18,2), sum(ro_porcentaje)), 2), 0)
    from cob_cartera..ca_rubro_op, cob_cartera..ca_concepto
    where ro_operacion = @w_numero_operacion
    and ro_concepto = co_concepto
    and co_categoria = 'M'
	
	--Se obtienen los datos del banco
	select @w_dom_aclaraciones = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 1
	
	select @w_clarificationsPhone = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 2
	
	select @w_firma = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 3
	
	select @w_email = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 4
	
	select @w_pagina_internet = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 5
	
	--Se obtiene el RECA del documento
	select @w_pie_pagina = id_dato
    from cob_credito..cr_imp_documento 
    where id_mnemonico = 'COFTCR'
    AND id_toperacion =  (select op_toperacion from cob_cartera..ca_operacion where op_banco = @i_banco) 
    
    select @w_obligado_1 = ''
             , @w_obligado_2 = ''
    
    --Consulta final
    select "cat" = @w_cat
             , "ordinaryRate" = @w_tasa_ordinaria
             , "moratoriumRate" = @w_tasa_moratoria
             , "creditAmount" = @w_monto_credito
             , "totalAmount" = @w_monto_total
             , "creditFrequency" = cast(@w_plazo_credito as varchar) + ' ' + @w_frecuencia_credito
             , "paymentDate" = @w_fecha_pago
             , "clarificationsAddress" = @w_dom_aclaraciones
             , "reca" = @w_pie_pagina
             , "clientName" = @w_nom_cliente
             , "solidary1" = @w_obligado_1
             , "solidary2" = @w_obligado_2
             , "operationType" = @w_desc_operacion
             , "subsidiary" = @w_filial
             , "clarificationsPhone" = @w_clarificationsPhone
             , "email" = @w_email
             , "internetPage" = @w_pagina_internet
             , "firm" = @w_firma
             , "codOperationType" = @w_tipo_operacion
END

--Datos para reporte de TABLA DE AMORTIZACION y PAGARE
if @i_operacion = 'E'   
BEGIN


    --Se obtienen datos de ca_operacion
    select @w_numero_operacion = op_operacion
             , @w_numero_cliente = op_cliente
             , @w_tipo_operacion = op_toperacion
             , @w_monto_credito = op_monto
             , @w_plazo_credito = op_plazo
             , @w_tipo_plazo_credito = op_tdividendo
             , @w_num_oficina = op_oficina
             , @w_fecha_ini_credito = op_fecha_ini
			 , @w_tea = op_tasa_cap
    from cob_cartera..ca_operacion
    where op_banco = @i_banco
    
    --Se obtiene datos del cliente
    select @w_nom_cliente = en_nombre + ' ' + isnull(p_p_apellido, '') + ' ' +  isnull(p_s_apellido, '')
             --, @w_dom_cliente = di_calle + ' ' + cast(di_nro as varchar) + ' ' + pq_descripcion + ' ' + ci_descripcion + ' ' + pv_descripcion + ' C.P. ' + di_codpostal
			 , @w_dom_cliente = di_descripcion
             , @w_cliente_calle = di_calle
             , @w_cliente_num_ext = cast(di_nro as varchar)
             , @w_cliente_parroquia = pq_descripcion
             , @w_cliente_ciudad = ci_descripcion
             , @w_cliente_provincia = pv_descripcion
             , @w_cliente_codpostal = di_codpostal
             , @w_filial = isnull(en_filial,0)
    from cobis..cl_ente
    inner join cobis..cl_direccion on di_ente = en_ente and di_principal = 'S'
    inner join cobis..cl_parroquia on di_parroquia = pq_parroquia
    inner join cobis..cl_ciudad on pq_ciudad = ci_ciudad 
    inner join cobis..cl_provincia on ci_provincia = pv_provincia 
    where en_ente = @w_numero_cliente
    
    --Se obtiene el monto total a pagar
    select @w_monto_total = isnull(sum(am_cuota), 0)
    from cob_cartera..ca_amortizacion 
    where am_operacion = @w_numero_operacion
                                                      
    --Se obtiene la direccion de la regional
    select @w_dom_regional = isnull(of_direccion,'')
    from cobis..cl_oficina
    where of_subtipo = 'R' and of_oficina = @w_num_oficina
    
    --Se obtiene la tasa ordinaria
    select @w_tasa_ordinaria = isnull(round(convert(decimal(18,2), sum(ro_porcentaje)) , 2), 0)
    from cob_cartera..ca_rubro_op, cob_cartera..ca_concepto
    where ro_operacion = @w_numero_operacion
    and ro_concepto = co_concepto
    and co_categoria = 'I'
	
	select @w_imo = isnull(round(convert(decimal(18,2), sum(ro_porcentaje)), 2), 0)
    from cob_cartera..ca_rubro_op, cob_cartera..ca_concepto
    where ro_operacion = @w_numero_operacion
    and ro_concepto = co_concepto
    and co_categoria = 'M'
	
	-- Diferencia entre tasa IMO e INT
	select @w_dif_imo_int = isnull((@w_imo - @w_tasa_ordinaria), 0)
    
    select @w_comision = isnull(convert(decimal(18,2), sum(ro_valor)), 0)
    from cob_cartera..ca_rubro_op 
    where ro_operacion = @w_numero_operacion
    and ro_concepto = 'CO'
    
    select @w_comision_iva = isnull(convert(decimal(18,2), sum(ro_valor)), 0)
    from cob_cartera..ca_rubro_op 
    where ro_operacion = @w_numero_operacion
    and ro_concepto = 'IVA-C'
    
    select @w_imo_mensual = round(@w_imo / 12, 2)
    select @w_gastos_originacion = isnull(@w_comision,0) + isnull(@w_comision_iva,0)
	
	-- Gastos de apertura o contratación
	select @w_openingExpense = sum(ro_valor)
	from ca_rubro_op
    where ro_operacion = @w_numero_operacion
	and ro_fpago = 'L'
    
    --Se obtiene la provincia de la sucursal
    select @w_sucursal_provincia = pv_descripcion
    from cobis..cl_oficina
    inner join cobis..cl_ciudad on ci_ciudad = of_ciudad 
    inner join cobis..cl_provincia on ci_provincia = pv_provincia
    where of_oficina = @w_num_oficina
    
    --Se consulta la descripcion de la operacion
    select @w_desc_operacion = @w_tipo_operacion
    
    --Se obtiene la descripcion de la frecuencia de pago
    select @w_frecuencia_credito = td_descripcion
    from cob_cartera..ca_tdividendo
    where td_tdividendo = @w_tipo_plazo_credito and td_estado = 'V'

    --Se obtienen los montos en letra
    exec cob_cartera..sp_convert_numero_letra @Numero = @w_monto_total, @tipo = 1, @resultado = @w_totalAmountText out
    
    exec cob_cartera..sp_convert_numero_letra @Numero = @w_imo_mensual, @tipo = 2, @resultado = @w_monthlyInterestRateText out
	
	--Se obtiene el RECA del documento
	select @w_pie_pagina = id_dato
    from cob_credito..cr_imp_documento 
    where id_mnemonico = 'TAMORTCR'
    and id_toperacion =  (select op_toperacion from cob_cartera..ca_operacion where op_banco = @i_banco)
	
	--Se obtienen los datos del conyuge
	select @w_num_conyuge = in_ente_i 
	from cobis..cl_instancia where in_relacion = 1 and in_lado = 'D' 
	and in_ente_d = @w_numero_cliente
	
	select @w_nombre_conyuge = en_nombre + ' ' + p_p_apellido + ' ' +  p_s_apellido
	         , @w_direccion_conyuge = di_calle + ' ' + isnull(cast(di_nro as varchar),'') + ' ' + pq_descripcion + ' ' + ci_descripcion + ' ' + pv_descripcion + ' C.P. ' + di_codpostal
	from cobis..cl_ente
	inner join cobis..cl_direccion on di_ente = en_ente and di_principal = 'S' and di_tipo = 'RE'
    inner join cobis..cl_parroquia on di_parroquia = pq_parroquia and pq_estado = 'V'
    inner join cobis..cl_ciudad on pq_ciudad = ci_ciudad and ci_estado = 'V'
    inner join cobis..cl_provincia on ci_provincia = pv_provincia and pv_estado = 'V'
	where en_ente = @w_num_conyuge
	
	--Se obtienen los datos del aval
	select @w_nombre_aval = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_dato_aval' and b.codigo = 1
	
	select @w_direccion_aval = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_dato_aval' and b.codigo = 1
		
	-- Información variable cuando la operación es grupal
	if @w_tipo_grupal = 'G' 
	begin
	
       select @w_fecha_liq_credito = min(tr_fecha_mov)
	   from ca_operacion with (nolock), ca_transaccion with (nolock)
	   where op_ref_grupal = @i_banco	   
	   and tr_operacion = op_operacion
	   and tr_tran = 'DES'
	   and tr_estado <> 'RV'
	   
	   select @w_numero_cliente = gr_grupo, 
	          @w_nom_cli_grup = gr_nombre,
			  @w_dom_cliente  = gr_dir_reunion,
			  @w_cliente_parroquia = '',
			  @w_cliente_ciudad = '',
			  @w_cliente_calle = '',
			  @w_cliente_provincia = ''
	   from cobis..cl_grupo 
	   where gr_representante = @w_numero_cliente

	end
	else
	begin
	   select @w_fecha_liq_credito = tr_fecha_mov 
	   from ca_transaccion with (nolock)
	   where tr_operacion = @w_numero_operacion 
	   and tr_tran = 'DES'
	   and tr_estado <> 'RV'
	   
	   select @w_nom_cli_grup = @w_nom_cliente
	end
     
    --Consulta final 1
    select "clientName" = @w_nom_cliente
             , "totalAmount" = @w_monto_total
             , "totalAmountText" = @w_totalAmountText
             , "regionalAddress" = isnull(@w_dom_regional,'')
             , "monthlyInterestRate" = @w_imo_mensual
             , "monthlyInterestRateText" = @w_monthlyInterestRateText
             , "officeState" = @w_sucursal_provincia
             , "beginDateDay" = day(@w_fecha_ini_credito)
             , "beginDateMonth" = month(@w_fecha_ini_credito)
             , "beginDateYear" = year(@w_fecha_ini_credito)
             , "clientAddress" = @w_cliente_calle
             , "reca" = @w_pie_pagina
             , "creditNum" = @i_banco
             , "clientNum" = @w_numero_cliente
             , "operationType" = @w_desc_operacion
             , "cashRecieved" = @w_monto_credito - @w_gastos_originacion
             , "originationExpense" = @w_gastos_originacion
             , "creditAmount" = @w_monto_credito
             , "rate" = @w_tasa_ordinaria
             , "actualDate" = convert(varchar, isnull(@w_fecha_proceso, getdate()),103)
             , "frequency" = @w_plazo_credito
             , "period" = @w_frecuencia_credito
             , "address" = @w_dom_cliente
             , "colony" = @w_cliente_parroquia
             , "delegation" = @w_cliente_ciudad
             , "city" = @w_cliente_ciudad
             , "state" = @w_cliente_provincia
             , "subsidiary" = @w_filial
			 , "teaRate" = @w_tea
			 , "maratoriumRate" = @w_dif_imo_int
			 , "clientOrGroupName" = @w_nom_cli_grup
			 , "openingExpense" = isnull(@w_openingExpense, 0)
			 , "street" = isnull(@w_cliente_calle, '')
			 , "disbursementDate" = convert(varchar,@w_fecha_liq_credito,103)
             , "spouseName" = isnull(@w_nombre_conyuge,@w_nombre_aval)
			 , "spouseAddress" = isnull(@w_direccion_conyuge,@w_direccion_aval)
			 , "guaranteeName" = @w_nombre_aval
			 , "guaranteeAddress" = @w_direccion_aval
    
    --Se obtienen los dividentos del credito consulta final 2
    select operacion = di_operacion
             , dividendo = di_dividendo
             , cap_liquida = sum(am_cuota)
    into #liquida
    from cob_cartera..ca_dividendo as a inner join cob_cartera..ca_amortizacion as b
        on b.am_operacion = a.di_operacion and b.am_dividendo >= a.di_dividendo and am_concepto in (
            select b.valor
            from cobis..cl_tabla as a
            inner join cobis..cl_catalogo as b on a.codigo = b.tabla
            where a.tabla = 'ca_rubros_tamort_c')
    where a.di_operacion = @w_numero_operacion
    group by di_operacion, di_dividendo

    /*select NumeroDividendo = di_dividendo
             , FechaInicio = convert(char(10),a.di_fecha_ini,103)
             , FechaVencimiento = convert(char(10),a.di_fecha_ven,103)
             , Ahorro = 'N/A'
             , Cuota = sum(b.am_cuota)
             , Capital = sum(case when b.am_concepto in (w.rubro) then b.am_cuota else 0 end)
             , Interes = sum(case when b.am_concepto in (v.rubro) then b.am_cuota else 0 end)
             , Iva = sum(case when b.am_concepto in (x.rubro) then b.am_cuota else 0 end)
             , Seguros = sum(case when b.am_concepto in (y.rubro) then b.am_cuota else 0 end)
             , GastoSupervision = sum(case when b.am_concepto in (z.rubro) then b.am_cuota else 0 end)
             , Saldo = cap_liquida
    from cob_cartera..ca_dividendo as a inner join cob_cartera..ca_amortizacion as b
        on b.am_operacion = a.di_operacion and b.am_dividendo = a.di_dividendo left join #liquida as c
        on c.operacion = a.di_operacion and c.dividendo = di_dividendo
        LEFT JOIN (select e.valor rubro
                            from cobis..cl_tabla as d
                            inner join cobis..cl_catalogo as e on d.codigo = e.tabla
                            where d.tabla = 'ca_rubros_tamort_int') as v on v.rubro = b.am_concepto
        LEFT JOIN (select e.valor rubro
                            from cobis..cl_tabla as d
                            inner join cobis..cl_catalogo as e on d.codigo = e.tabla
                            where d.tabla = 'ca_rubros_tamort_c') as w on w.rubro = b.am_concepto
        LEFT JOIN (select e.valor rubro
                            from cobis..cl_tabla as d
                            inner join cobis..cl_catalogo as e on d.codigo = e.tabla
                            where d.tabla = 'ca_rubros_tamort_iva') as x on x.rubro = b.am_concepto
        LEFT JOIN (select e.valor rubro
                            from cobis..cl_tabla as d
                            inner join cobis..cl_catalogo as e on d.codigo = e.tabla
                            where d.tabla = 'ca_rubros_tamort_seg') as y on y.rubro = b.am_concepto
        LEFT JOIN (select e.valor rubro
                            from cobis..cl_tabla as d
                            inner join cobis..cl_catalogo as e on d.codigo = e.tabla
                            where d.tabla = 'ca_rubros_tamort_gtosup') as z on z.rubro = b.am_concepto
    where a.di_operacion = @w_numero_operacion
    group by a.di_dividendo, a.di_fecha_ini, a.di_fecha_ven, cap_liquida
    order by a.di_dividendo*/

    drop table #liquida
	
	if @w_tipo_grupal = 'G'
	begin
       exec @w_error = sp_qr_table_amortiza_grupal
       @s_date  = @s_date,
       @i_banco = @i_banco
       
       if @w_error <> 0
          goto ERROR
    end
	else
	begin
       exec @w_error = sp_qr_table_amortiza_web
       @s_date         = @s_date,
       @i_banco        = @i_banco,
	   @i_desde_reporte = 'S' -- Para no retornar resulset
       
       if @w_error <> 0
          goto ERROR
	end
	
	-- INICIO Ajustes estructura de amortización
	declare @w_tot_regs_divs int,
        @w_id_div  int,
        @w_num_div int,
        @w_fecha_ini datetime,
        @w_fecha_ven datetime,
        @w_max_id_rubs int,   
        @w_min_id_rubs int, 
        @w_tot_rubs int,
        @w_count_rubs int,
        @w_id_rub_tmp int,
        @w_cuota_tmp money,
        @w_cuota_cap money,
        @w_cuota_int_imo money,
        @w_cuota_iva money,
        @w_cuota_otros money,
        @w_cat_rubro varchar(10),
        @w_sql nvarchar(200),
        @w_sql_colum varchar(15),
        @w_sql_where VARCHAR(50),
        @w_sql_where_fechas VARCHAR(70),
        @w_SPID int

   SELECT @w_cuota_cap     = 0,
          @w_cuota_int_imo = 0,
          @w_cuota_iva     = 0,
          @w_cuota_otros   = 0,
          @w_count_rubs    = 1,  -- Contador rubros
		  @w_SPID          = @@spid
   
   if object_id ('tempdb..#amortiza_tmp', 'U') is not null
      drop table #amortiza_tmp
   
   create table #amortiza_tmp(
      at_id            int identity not null,
      at_spid          int,
      at_div           int,
      at_fecha_ini     datetime,
      at_fecha_ven     datetime
   )
 
   if object_id ('tempdb..#cuotas_repo', 'U') is not null
      drop table #cuotas_repo
   
   create table #cuotas_repo(
      cr_spid          int,
      cr_div           int,
	  cr_fecha_ini     datetime,
	  cr_fecha_ven     datetime,
      cr_cuota_cap     money,
      cr_cuota_int_imo money,
      cr_cuota_iva     money, 
      cr_cuota_otros   MONEY
   )
   
   insert into #amortiza_tmp
   select qat_pid, qat_dividendo, qat_fecha_ini, qat_fecha_ven
   from ca_qr_amortiza_tmp 
   where qat_pid = @w_SPID
   order by qat_dividendo
   
   -- Total de registros de dividendos(Puede no coincidir con el número de dividendos)
   select @w_tot_regs_divs = count(1)
   from ca_qr_amortiza_tmp 
   where qat_pid = @w_SPID
   
   -- Total de registros de rubros(Diferentes rubros de operación)
   select @w_tot_rubs = count(1)
   from ca_qr_rubro_tmp 
   where qrt_pid = @w_SPID
   
   -- Menor id y máximo id de los rubros de la operación
   select @w_min_id_rubs = min(qrt_id),
          @w_max_id_rubs = max(qrt_id)
   from ca_qr_rubro_tmp 
   where qrt_pid = @w_SPID

   if @w_min_id_rubs > @w_max_id_rubs
      PRINT 'ERROR'

   select top 1 
   @w_id_div    = at_id,
   @w_num_div   = at_div,
   @w_fecha_ini = at_fecha_ini,
   @w_fecha_ven = at_fecha_ven
   from #amortiza_tmp
   where at_spid = @w_SPID
   
   while @w_id_div <= @w_tot_regs_divs
   begin
  
      select @w_cuota_cap     = 0,
             @w_cuota_int_imo = 0,
             @w_cuota_iva     = 0,
             @w_cuota_otros   = 0,
             @w_count_rubs    = 1,
             @w_id_rub_tmp    = @w_min_id_rubs
      
      while @w_count_rubs <= @w_tot_rubs
      begin

         select @w_sql_colum = 'qat_rubro' + convert(varchar(10), @w_count_rubs),
                @w_sql_where = ' where qat_pid = ' +  convert(varchar(10), @w_SPID) + ' and qat_dividendo = ' + convert(varchar(10), @w_num_div),
                @w_sql_where_fechas = ' and qat_fecha_ini = ''' + convert(varchar(10), @w_fecha_ini, 27)  + ''' and qat_fecha_ven = ''' + convert(varchar(10), @w_fecha_ven, 27) + '''',
                @w_sql = 'select @w_sum_tmp = '+ @w_sql_colum +' from ca_qr_amortiza_tmp'+ @w_sql_where + @w_sql_where_fechas   
         
         execute sp_executesql @w_sql, N'@w_sum_tmp money output', @w_sum_tmp=@w_cuota_tmp output 
         
         -- Categoría de rubro del préstamo
         select @w_cat_rubro = co_categoria
         from ca_qr_rubro_tmp, ca_concepto, ca_categoria_rubro
         where qrt_pid = @w_SPID
         and qrt_id = @w_id_rub_tmp
         and qrt_rubro = co_concepto
         and co_categoria = cr_codigo
      
         if @w_cat_rubro = 'C'
            set @w_cuota_cap = @w_cuota_cap + isnull(@w_cuota_tmp, 0)
            
         if @w_cat_rubro in ('I', 'M')     
            set @w_cuota_int_imo = @w_cuota_int_imo +isnull(@w_cuota_tmp, 0)
            
         if @w_cat_rubro in ('A')     
            set @w_cuota_iva = @w_cuota_iva + isnull(@w_cuota_tmp, 0)
            
         if @w_cat_rubro NOT in ('I', 'M', 'C', 'A')     
            set @w_cuota_otros = @w_cuota_otros + isnull(@w_cuota_tmp, 0)
         
         select top 1 @w_id_rub_tmp = qrt_id 
         from ca_qr_rubro_tmp 
         where qrt_pid = @w_SPID 
         and qrt_id > @w_id_rub_tmp
         
         set @w_count_rubs = @w_count_rubs +1 
         
      end

      insert into #cuotas_repo values(@w_SPID, @w_num_div, @w_fecha_ini, @w_fecha_ven, @w_cuota_cap, @w_cuota_int_imo, @w_cuota_iva, @w_cuota_otros)
   
      -- Siguiente registro de dividendo   
      select top 1 
      @w_id_div    = at_id,
      @w_num_div   = at_div,
      @w_fecha_ini = at_fecha_ini,
      @w_fecha_ven = at_fecha_ven
      from #amortiza_tmp
      where at_spid = @w_SPID
      and at_id > @w_id_div
      
      IF @@rowcount = 0
         break
      
      set @w_tot_regs_divs = @w_tot_regs_divs +1
   
   end
   -- FIN Ajustes estructura de amortización

   select 
         NumeroDividendo = qat_dividendo
       , FechaInicio = convert(char(10),qat_fecha_ini,103)
       , FechaVencimiento = convert(char(10),qat_fecha_ven,103)
       , Ahorro = 'N/A'
       , Cuota = qat_cuota
       , Capital = isnull(cr_cuota_cap, 0)
       , Interes = isnull(cr_cuota_int_imo, 0)
       , Iva = isnull(cr_cuota_iva, 0)
       , Seguros = isnull(cr_cuota_otros, 0)
       , GastoSupervision = 0.0
       , Saldo = qat_saldo_cap
       , Estado = qat_estado
   from ca_qr_amortiza_tmp, #cuotas_repo  
   where qat_pid = @@spid
   and qat_pid = cr_spid
   and qat_dividendo = cr_div
   and qat_fecha_ini = cr_fecha_ini
   and qat_fecha_ven = cr_fecha_ven
   order by qat_dividendo
      
   --Se obtienen los avales consulta final 3
   select "solidaryName" = isnull(re.en_nombre,'') + ' ' + isnull(re.p_p_apellido,'') + ' ' + isnull(re.p_s_apellido,'')
   from cobis..cl_ente as re
   inner join cobis..cl_instancia on in_ente_d = re.en_ente 
   inner join cobis..cl_relacion on re_relacion = in_relacion
   inner join cobis..cl_ente as cl on cl.en_ente = in_ente_i   
   where cl.en_ente = @w_numero_cliente
    
END

--Datos para reporte de Anexo Comision
if @i_operacion = 'F'   
Begin


    select @w_nom_cliente = en_nomlar,
           @w_ecivil      = p_estado_civil
    from cobis..cl_ente 
    where en_ente = @i_cliente
    

    SELECT @w_c_anexo = codigo  FROM cobis..cl_tabla WHERE tabla = 'ca_anexo_comision'
    
    SELECT @w_tipo_producto = op_toperacion FROM cob_cartera..ca_operacion WHERE op_banco = @i_banco
    SELECT @w_monto = valor FROM cobis..cl_catalogo WHERE codigo = @w_tipo_producto +'-M'
    SELECT @w_per_administracion= valor FROM cobis..cl_catalogo WHERE codigo = @w_tipo_producto +'-A'
    SELECT @w_per_cobranza= valor FROM cobis..cl_catalogo WHERE codigo = @w_tipo_producto +'-C'
    SELECT @w_per_invest= valor FROM cobis..cl_catalogo WHERE codigo = @w_tipo_producto +'-I'   
    
	--Se obtiene la descripcion del producto
	select @w_tipo_producto = upper(b.valor)
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
	where a.tabla = 'ca_toperacion' and b.codigo = @w_tipo_producto
	
	--Se obtiene el RECA
	select @w_pie_pagina = id_dato
    from cob_credito..cr_imp_documento 
    where id_mnemonico = @i_nemonico 
    and id_toperacion =  (select op_toperacion from cob_cartera..ca_operacion where op_banco = @i_banco) 
    
   --Devolviendo Resultados
    select @w_pie_pagina,                       -- PIE DE PAGINA
           @w_tipo_producto,                    -- TIPO DE PRODUCTO
           @w_monto,                            -- VALORES DEL MONTO EN PORCENTAJE Y DINERO
           @w_per_administracion,               -- VALOR DE PERIOCIDAD EN FILA DE ADMINISTRACION
           @w_per_cobranza,                     -- VALOR DE PERIOCIDAD EN FILA DE GASTOS DE COBRANZA
           @w_per_invest                        -- VALOR DE PERIOCIDAD EN FILA DE GASTOS DE INVESTIGACION O FORMALIZACION
End

--Datos para reporte de Anexo de Informacion Financiera de Titular y Beneficiarios
if @i_operacion = 'G'   
BEGIN
    --Se obtienen datos de ca_operacion
    select @w_numero_operacion = op_operacion
             , @w_numero_cliente = op_cliente
             , @w_tipo_operacion = op_toperacion
             , @w_monto_credito = op_monto
             , @w_plazo_credito = op_plazo
             , @w_tipo_plazo_credito = op_tdividendo
             , @w_num_oficina = op_oficina
             , @w_fecha_ini_credito = op_fecha_ini
             , @w_oficina_credito = op_oficina
			 , @w_tramite = op_tramite
    from cob_cartera..ca_operacion
    where op_banco = @i_banco
    
    --Se vetifica si el credito es grupal o individual
    if exists(select 1 from cobis..cl_catalogo 
    where tabla = (select codigo from cobis..cl_tabla 
    where tabla = 'ca_grupal') and codigo = @w_tipo_operacion)
        select @w_tipoCredito = 'G'
    else
        select @w_tipoCredito = 'I'

    -- Se obtiene el % de ahorro previo sobre el monto del credito neto
    if @w_tipoCredito = 'G'
        begin
            select @w_porcAhorro = str((cc.ci_monto_ahorro/co.op_monto),18,2)
              from cob_cartera..ca_operacion co, cob_cartera..ca_ciclo cc
             where co.op_operacion = cc.ci_operacion
               and co.op_grupo = cc.ci_grupo
               and op_banco = @i_banco
        end
        
    ---INICIO---GG 7/08/2019
    --Se obtiene datos del cliente
        select  @w_nom_cliente = en_nomlar          
              , @w_cliente_nombre = en_nombre
              , @w_cliente_apellido_paterno = p_p_apellido
              , @w_cliente_apellido_materno = p_s_apellido
              , @w_filial = isnull(en_filial,0)
              , @w_cliente_curp = isnull(en_ced_ruc,'')
              , @w_cliente_rfc = isnull(en_rfc,'')
              , @w_fecha_nac = isnull(convert(varchar,p_fecha_nac,103),'')
              , @w_nacionalidad_cod = isnull(en_nacionalidad,0)
              , @w_sexo_cod = p_sexo
              , @w_profesion_cod = isnull(p_profesion,'')
          from  cobis..cl_ente 
         where  en_ente = @w_numero_cliente
        
        select  @w_dom_cliente = di_calle + ' ' + cast(di_nro as varchar) + ' ' + pq_descripcion + ' ' + ci_descripcion + ' ' + pv_descripcion + ' C.P. ' + di_codpostal
              , @w_cliente_parroquia = pq_descripcion
              , @w_cliente_ciudad = ci_descripcion
              , @w_cliente_provincia = pv_descripcion
          from  cobis..cl_ente
    inner join  cobis..cl_direccion on di_ente = en_ente and di_principal = 'S'
    inner join  cobis..cl_parroquia on di_parroquia = pq_parroquia and pq_estado = 'V'
    inner join  cobis..cl_ciudad on pq_ciudad = ci_ciudad and ci_estado = 'V'
    inner join  cobis..cl_provincia on ci_provincia = pv_provincia and pv_estado = 'V'
         where  en_ente = @w_numero_cliente
        
        select   @w_cliente_calle = di_calle
               , @w_cliente_num_ext = cast(di_nro as varchar)
               , @w_cliente_codpostal = di_codpostal
               , @w_cliente_telefono  = isnull(tel.te_valor,'SIN TELEFONO')
          from   cobis..cl_ente
    inner join   cobis..cl_direccion on di_ente = en_ente and di_principal = 'S'
     left join   cobis..cl_telefono as tel on tel.te_ente = di_ente and tel.te_direccion = di_direccion and tel.te_tipo_telefono = 'D'      
         where   en_ente = @w_numero_cliente
   ---INICIO---GG 7/08/2019   
    
    --Se obtiene el telefono del cliente
    select @w_cliente_telefono = isnull(te_valor,'')
    from cobis..cl_ente
    inner join cobis..cl_direccion on di_ente = en_ente
    inner join cobis..cl_telefono on te_ente = en_ente and te_direccion = di_direccion
    where en_ente = @w_numero_cliente and te_tipo_telefono = 'D'
    order by te_secuencial desc
    
    --Se consulta la descripcion de la nacionalidad
    if (@w_nacionalidad_cod = 484)
    begin
        select @w_nacionalidad = isnull(b.valor,'')
        from cobis..cl_tabla as a
        inner join cobis..cl_catalogo as b on b.tabla = a.codigo
        where a.tabla = 'cl_nacionalidad' and b.codigo = '1'
    end
    else
    begin
        select @w_nacionalidad = isnull(b.valor,'')
        from cobis..cl_tabla as a
        inner join cobis..cl_catalogo as b on b.tabla = a.codigo
        where a.tabla = 'cl_nacionalidad' and b.codigo = '2'
    end
    
    --Se obtiene el email del cliente
    select @w_email = isnull(di_descripcion,'')
    from cobis..cl_direccion
    where di_ente = @w_numero_cliente
    and   di_tipo = 'CE'
    and   di_direccion = (select max(di_direccion) from cobis..cl_direccion
                          where di_ente = @w_numero_cliente
                          and   di_tipo = 'CE')
    
    --Se obtiene la descripcion del sexo
    select @w_genero = isnull(b.valor,'')
    from cobis..cl_tabla as a
    inner join cobis..cl_catalogo as b on b.tabla = a.codigo
    where a.tabla = 'cl_sexo' and b.codigo = @w_sexo_cod
    
    --Se obtienen los gastos de originacion
	select @w_imo = isnull(round(convert(money, sum(ro_porcentaje*2)), 2), 0),
           @w_tasa_ordinaria = isnull(round(convert(money, sum(ro_porcentaje*2)), 2), 0)
    from cob_cartera..ca_rubro_op 
    where ro_operacion = @w_numero_operacion
    and ro_concepto = 'INT'

    select @w_comision = isnull(convert(decimal(18,2), sum(ro_valor)), 0)
    from cob_cartera..ca_rubro_op 
    where ro_operacion = @w_numero_operacion
    and ro_concepto = 'CO'
    
    select @w_comision_iva = isnull(convert(decimal(18,2), sum(ro_valor)), 0)
    from cob_cartera..ca_rubro_op 
    where ro_operacion = @w_numero_operacion
    and ro_concepto = 'IVA-C'

    
    select @w_gastos_originacion = isnull(@w_comision,0) + isnull(@w_comision_iva,0)
    
    --Se obtiene la descripcion de la frecuencia de pago
    select @w_frecuencia_credito = td_descripcion
    from cob_cartera..ca_tdividendo
    where td_tdividendo = @w_tipo_plazo_credito and td_estado = 'V'
    
    --Se obtiene la oficina del credito
    select @w_oficina_descrip_credito = isnull(of_nombre,'')
             , @w_oficina_dir_credito = isnull(of_direccion,'')
             , @w_regional_cod = of_regional
    from cobis..cl_oficina
    where of_oficina = @w_oficina_credito
    
    --Se obtiene la regional
    select @w_regional_dir = isnull(of_direccion,'')
    from cobis..cl_oficina
    where of_oficina = @w_regional_cod
    
    --Se obtienen los nombres de los solidarios
    select @w_nom_solidario1 = cony.en_nombre + ' ' + cony.p_p_apellido + ' ' +  cony.p_s_apellido
    from cobis..cl_ente as cli
    inner join cobis..cl_instancia as i on cli.en_ente = i.in_ente_d and i.in_relacion = 209
    inner join cobis..cl_ente as cony on i.in_ente_i = cony.en_ente
    where cli.en_ente = @w_numero_cliente 
    
    --Se obtiene el saldo promedio
	if (@w_plazo_credito > 0)
	begin
	   select @w_saldo_promedio = isnull(@w_monto_credito / @w_plazo_credito, 0)
	end 
	else
	   select @w_saldo_promedio = 0
    
    --Se obtienen los movimientos esperados
	select @w_mov_esperados = 0
	
	if (@w_tipo_plazo_credito = 'M')
	   select @w_mov_esperados = 2
	if (@w_tipo_plazo_credito = 'Q')
	   select @w_mov_esperados = 4
	if (@w_tipo_plazo_credito = 'C')
	   select @w_mov_esperados = 4
    if (@w_tipo_plazo_credito = 'W')
	   select @w_mov_esperados = 8	  
    
    --Se obtiene la profesion del cliente
    select @w_ocupacion = isnull(b.valor,'')
    from cobis..cl_tabla as a
    inner join cobis..cl_catalogo as b on b.tabla = a.codigo
    where a.tabla = 'cl_profesion' and b.codigo = @w_profesion_cod
    
    --Se obtienen los datos del extranjero
    select @w_forma_migratoria = isnull(en_forma_migratoria,'')
             , @w_numero_extranjero = isnull(en_nro_extranjero,'')
             , @w_domicilio_origen = isnull(en_calle_orig,'') + ' ' + isnull(en_exterior_orig,'')
             , @w_rfc_origen = isnull(en_rfc,'')
    from cobis..cl_ente
    where en_ente = @w_numero_cliente
    
    --Se obtiene la descripcion del producto
	select @w_tipo_operacion = upper(b.valor)
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
	where a.tabla = 'ca_toperacion' and b.codigo = @w_tipo_operacion
	
	 --Se obtiene la id y descripcion de grupo      --GG 23/07/2019
	SELECT @w_groupNum  = isnull(a.op_grupo,0),
	       @w_groupName  = isnull(b.gr_nombre,'')     
    FROM cob_cartera..ca_operacion a
    INNER JOIN cobis..cl_grupo b ON b.gr_grupo = a.op_grupo        
    WHERE a.op_banco = @i_banco
	
	--Se obtienen los datos del banco
	select @w_dom_aclaraciones = isnull(b.valor,'')
	from cobis..cl_tabla as a
	inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_doctos_data' and b.codigo = 1
    
    --Consulta final 1
    select clientCompleteName =isnull( @w_nom_cliente,'')
             , clientNumber = @w_numero_cliente
             , clientName = isnull(@w_cliente_nombre,'')
             , clientSurname = isnull(@w_cliente_apellido_paterno,'')
             , clientSecondSurname = isnull(@w_cliente_apellido_materno,'')
             , clientAddress = isnull(@w_dom_cliente,'')
             , clientPhone = isnull(@w_cliente_telefono, '')
             , clientCurp = isnull(@w_cliente_curp, '')
             , clientRfc = isnull(@w_cliente_rfc, '')
             , clientBirthDate = @w_fecha_nac
             , clientNationality = isnull(@w_nacionalidad, '')
             , clientEmail = isnull(@w_email, '')
             , clientGender = isnull(@w_genero, '')
             , expectedAverageBalance = @w_saldo_promedio
             , expectedMovements = @w_mov_esperados
             , profession = @w_ocupacion
             , worksOn = isnull(@w_trabaja_en,'')
             , migratoryForm = @w_forma_migratoria
             , foreignerNumber = @w_numero_extranjero
             , originAddress = @w_domicilio_origen
             , originRfc = @w_rfc_origen
             , openingDate = convert(varchar,@w_fecha_ini_credito,103)
             , creditNumber = @i_banco
             , requestedAmount = @w_monto_credito - @w_gastos_originacion
             , paymentFrequency = @w_frecuencia_credito
             , originationExpense = 0--@w_gastos_originacion
             , accountManagement = 0
             , moratoryInterest  = @w_tasa_ordinaria
             , officeName = @w_oficina_descrip_credito
             , corporateAddress = @w_dom_aclaraciones
             , regionalAddress = @w_regional_dir
             , officeAddress = @w_oficina_dir_credito
             , soldaryName1 = isnull(@w_nom_solidario1,'')
             , solidaryName2 = ''
             , reca = @w_pie_pagina
             , operationType = @w_tipo_operacion
             , groupName = isnull(@w_groupName,'')
             , groupNum  = isnull(@w_groupNum,0)
             , tipoCredito = @w_tipoCredito
             , porcAhorro = @w_porcAhorro
    --Consulta final 2
    IF  @w_tipoCredito = 'G'
        BEGIN
              select beneficiaryName = bs_nombres + ' ' + bs_apellido_paterno + ' ' + bs_apellido_materno
                         , beneficiaryPercent = bs_porcentaje
                         , beneficiaryBirthDate = convert(datetime, bs_fecha_nac, 103)
                         , beneficiaryPhone = isnull(bs_telefono,'')
                         , beneficiaryAddress = isnull(bs_direccion,'') + ' Col. ' + isnull(pq_descripcion,'') + ' ' + isnull(ci_descripcion,'')
                            + ' ' + isnull(pv_descripcion,'') + ' C.P. ' + isnull(bs_codpostal,'')
                from cobis..cl_beneficiario_seguro
                join cob_cartera.dbo.ca_operacion on op_operacion = bs_nro_operacion
                left join cobis..cl_parroquia on bs_parroquia = pq_parroquia
                left join cobis..cl_ciudad on bs_ciudad = ci_ciudad
                left join cobis..cl_provincia on bs_provincia = pv_provincia
                where op_ref_grupal = @i_banco
                and op_grupal = 'S'
                and op_cliente = @w_numero_cliente
                order by bs_nombres + ' ' + bs_apellido_paterno + ' ' + bs_apellido_materno
        END
    ELSE
        BEGIN
            select beneficiaryName = bs_nombres + ' ' + bs_apellido_paterno + ' ' + bs_apellido_materno
                 , beneficiaryPercent = bs_porcentaje
                 , beneficiaryBirthDate = convert(datetime, bs_fecha_nac, 103)
                 , beneficiaryPhone = isnull(bs_telefono,'')
                 , beneficiaryAddress = isnull(bs_direccion,'') + ' Col. ' + isnull(pq_descripcion,'') + ' ' + isnull(ci_descripcion,'')
                    + ' ' + isnull(pv_descripcion,'') + ' C.P. ' + isnull(bs_codpostal,'')
            from cobis..cl_beneficiario_seguro
            left join cobis..cl_parroquia on bs_parroquia = pq_parroquia
            left join cobis..cl_ciudad on bs_ciudad = ci_ciudad
            left join cobis..cl_provincia on bs_provincia = pv_provincia
            where bs_tramite = @w_tramite and bs_producto = 7
            order by bs_nombres + ' ' + bs_apellido_paterno + ' ' + bs_apellido_materno
        END
        
END

--Datos para reporte de Recibo de Pago
if @i_operacion = 'H'   
BEGIN
    --Se obtienen datos de ca_operacion
    select @w_numero_cliente = op_cliente
             , @w_tipo_operacion = op_toperacion
    from cob_cartera..ca_operacion
    where op_banco = @i_banco
    
    --Se obtiene datos del cliente
    select @w_nom_cliente = en_nombre + ' ' + p_p_apellido + ' ' +  p_s_apellido
    from cobis..cl_ente
    where en_ente = @w_numero_cliente
    
    --Se obtiene la descripcion del producto
    select @w_tipo_operacion = isnull(valor,'')
    from cobis..cl_catalogo 
    where tabla = 691 and codigo = @w_tipo_operacion
    
    --LGBC INICIO ---Se obtienen los numeros de referencia
	select @w_cont2 = 1,
		 @w_cont3 = 10
	select @w_cadena1 = isnull(substring(@wi_referencia1,7,10), substring(@wi_referencia2, 7, 11))
	--select @w_cadena1 = substring(@i_referencia,7,10)
	while @w_cont2 <= 10
	begin
		select @w_lref = substring(@w_cadena1,@w_cont2,1)
		if @w_lref <> '0'
		begin
			select @w_cadena1 = substring(@w_cadena1,@w_cont2,@w_cont3)
			break
		end
		select @w_cont2 = @w_cont2 +1
		select @w_cont3 = @w_cont3 - 1
	end
	select @i_banco = op_banco, 
		 @w_banco = op_operacion
	from cob_cartera..ca_operacion
	where op_operacion = convert(int,@w_cadena1)
	
	select @w_banco  = op_operacion
	from cob_cartera..ca_operacion, cobis..cl_ente
	where op_cliente = en_ente
	and op_banco = @i_banco
	if @@rowcount = 0
	begin
		exec cobis..sp_cerror
		  @t_from  = @w_sp_name,
		  @i_num   = 701025
		return 701025
	end
	
	-- Parametros de referencia
	select @w_paytel = pa_char
	from cobis..cl_parametro
	where pa_producto = 'ATX'
	and pa_nemonico = 'RPAYT'
	if @@rowcount = 0
	begin
		exec cobis..sp_cerror
		   @t_debug  = @t_debug,
		   @t_file   = @t_file,
		   @t_from   = @w_sp_name,
		   @i_num    = 201196
		return 201196
	end

	select @w_wallmart = pa_char
	from cobis..cl_parametro
	where pa_producto = 'ATX'
	and pa_nemonico = 'RWALL'
	if @@rowcount = 0
	begin
		exec cobis..sp_cerror
		   @t_debug  = @t_debug,
		   @t_file   = @t_file,
		   @t_from   = @w_sp_name,
		   @i_num    = 201196
		return 201196
	end
	
	--Generacion operacion en base a codigo interno de operacion
	select @w_long  = 10,
          @w_cont1 = 0,
          @w_cadena = null
          
	select @w_cont = len(convert(varchar, @w_banco)),
          @w_dif  = @w_long - @w_cont
          
	while (@w_cont1 < @w_dif)
	begin
		select @w_cadena = '0'+ isnull(@w_cadena,convert(VARCHAR,@w_banco))
		select @w_cont1 = @w_cont1 +1
	end
	
	-- Calculo del digito verificador

	-- Se construye la referencia
	select @w_referencia1 = @w_paytel + @i_banco
	-- Se invierte la referencia
	select @w_referencia_tmp = REVERSE(upper(rtrim(@w_referencia1)))

	--Se inicializan las variables para obtener el digito verificador
	select @w_num1 = 2, @w_num2 = 0, @w_indice = 0

	-- Se obtiene el digito verificador
	while @w_indice < LEN(@w_referencia_tmp)
	begin
		select @w_num3 = 0, @w_num4 = 0
		select @w_caracter = substring(@w_referencia_tmp, @w_indice + 1, 1)
		-- Se obtiene un digito referencial
		if @w_caracter = '0'
		   select @w_num3 = 0
		if @w_caracter in ('1', 'A', 'J')
		   select @w_num3 = 1
		if @w_caracter in ('2', 'B', 'K', 'S')
		   select @w_num3 = 2
		if @w_caracter in ('3', 'C', 'L', 'T')
		   select @w_num3 = 3
		if @w_caracter in ('4', 'D', 'M', 'U')
		   select @w_num3 = 4
		if @w_caracter in ('5', 'E', 'N', 'V')
		   select @w_num3 = 5
		if @w_caracter in ('6', 'F', 'O', 'W')
		   select @w_num3 = 6
		if @w_caracter in ('7', 'G', 'P', 'X')
		   select @w_num3 = 7
		if @w_caracter in ('8', 'H', 'Q', 'Y')
		   select @w_num3 = 8
		if @w_caracter in ('9', 'I', 'R', 'Z')
		   select @w_num3 = 9
		   
		-- Se generan calculos para obtener el digito verificador
		select @w_num4 = @w_num1 * @w_num3
		if @w_num4 > 9
			select @w_num4 = ((@w_num4/10) + @w_num4 + 10)
		select @w_num2 = @w_num2 + @w_num4
		if @w_num1 <> 2
			select @w_num1 = 2
		else
			select @w_num1 = 1

		-- Se incrementa el indice
		select @w_indice = @w_indice + 1
	end

	-- Se calcula el digito verificador
	select @w_digito = (((@w_num2/10) + 1) * 10 - @w_num2)
	if @w_digito = 10
		select @w_digito = 0

	select @w_numero_referencia = @w_referencia1 + convert(char(1), @w_digito),
			@w_referencia_walmart = @w_wallmart + @i_banco

	--LGBC FIN
    
    --Consulta final
    select CompleteClientName = @w_nom_cliente
             , OperationType = @w_tipo_operacion
             , BarCode = ''
             , WalmartBarCode = ''
             , PrintingDate = convert(varchar,getdate(),100)
             , ReferenceNumber = @w_numero_referencia
             , WalmartReference = @w_referencia_walmart
        
END

--Datos para reporte de Estado de Cuenta
if @i_operacion = 'I'   
BEGIN
    -- CONCEPTO RUBRO CAPITAL
    select @w_capital = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUCAP'
    
    -- CONCEPTO RUBRO INTERES
    select @w_interes = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUINT'
    
    -- CONCEPTO RUBRO IVA INTERES
    select @w_ivaInteres = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUIVIN'
    
    -- CONCEPTO RUBRO INTERES MORA
    select @w_imora = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUIVMO'
    
    -- CONCEPTO RUBRO IVA INTERES MORA
    select @w_ivaImora = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUIIMO'
    
    -- CONCEPTO RUBRO COMISION MORA
    select @w_cmora = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUCOMO'
    
    -- CONCEPTO RUBRO IVA COMISION MORA
    select @w_ivaCmora = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUICMO'
    
    -- CONCEPTO RUBRO COMISION GASTOS CONTRATADOS
    select @w_comGco = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUCGCO'
    
    -- CONCEPTO RUBRO IVA COMISION GASTOS CONTRATADOS
    select @w_ivaComGco = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUIGCO'
    
    -- CONCEPTO RUBRO COMISION PAGO TARDIO
    select @w_comPta = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUCPTA'
    
    -- CONCEPTO RUBRO IVA COMISION PAGO TARDIO
    select @w_ivaComPta = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUICPT'
    
    -- CONCEPTO RUBRO SERVICIO ASISTENCIA INCAPACIDAD
    select @w_serInc = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUSAIN'
    
    -- CONCEPTO RUBRO IVA SERVICIO ASISTENCIA INCAPACIDAD
    select @w_ivaSerInc = pa_char
    from   cobis..cl_parametro
    where  pa_producto = 'CCA'
    and    pa_nemonico = 'RUISIN'
    
    --Se obtienen datos de ca_operacion
    select @w_numero_operacion = op_operacion
             , @w_monto_credito = isnull(op_monto,0)
             , @w_fecha_concesion = isnull(convert(varchar(10),op_fecha_ini,103),'')
             , @w_cat = isnull(op_valor_cat,0)
             , @w_estado_credito = op_estado
             , @w_tipo_operacion = op_toperacion
             , @w_oficina_credito = op_oficina
             , @w_numero_cliente = op_cliente
    from cob_cartera..ca_operacion
    where op_banco = @i_banco
    
    --Se obtiene el nombre de la sucursal
    select @w_oficina_descrip_credito = isnull(of_nombre,'NO DEFINIDA')
             , @w_oficina_dir_credito = isnull(of_direccion,'SIN DIRECCION')
             , @w_oficina_telefono = 'SIN TELEFONO'
             , @w_regional_cod = isnull(of_regional,0)
    from cobis..cl_oficina where of_oficina = @w_oficina_credito and of_subtipo = 'O'
    
    --Se obtienen los datos de la regional
    select @w_regional_descrip = isnull(of_nombre,'NO DEFINIDA')
             , @w_regional_dir = isnull(of_direccion,'SIN DIRECCION')
             , @w_regional_telefono = 'SIN TELEFONO'
    from cobis..cl_oficina where of_oficina = @w_regional_cod and of_subtipo = 'R'
    
    --Se obtiene la descripcion del estado del credito
    select @w_estado_credito_nom = es_descripcion from cob_cartera..ca_estado where es_codigo = @w_estado_credito
    
    --Se obtienen los datos de la tasa de interes
    select @w_imo = isnull(round(convert(money, sum(ro_porcentaje*2)), 2), 0),
           @w_tasa_ordinaria = isnull(round(convert(decimal(18,2), sum(ro_porcentaje)) , 2), 0)
    from cob_cartera..ca_rubro_op 
    where ro_operacion = @w_numero_operacion
	and ro_concepto = 'INT'
    
    --Se obtiene la fecha de vencimiento
    select @w_fecha_vencimiento = convert(varchar,di_fecha_ven,103) from cob_cartera..ca_dividendo where di_operacion = @w_numero_operacion and di_dividendo = 1
    
    --Se obtiene el pago a liquidar
    select @w_pago_liquidar = isnull(convert(decimal(18,2), sum(am_cuota-am_pagado)), 0),
           @w_cuota_actual = isnull(convert(decimal(18,2), sum(am_cuota - am_pagado)), 0)
    from cob_cartera..ca_dividendo 
    inner join cob_cartera..ca_amortizacion on am_operacion = di_operacion and am_dividendo = di_dividendo  
    where am_operacion = @w_numero_operacion
	and di_estado = 1
    
	select @w_saldo_vencido = isnull(convert(decimal(18,2), sum(am_cuota - am_pagado)), 0)
    from cob_cartera..ca_dividendo 
    inner join cob_cartera..ca_amortizacion on am_operacion = di_operacion and am_dividendo = di_dividendo  
    where am_operacion = @w_numero_operacion
	and di_estado = 2
	
    --Se obtiene el capital no vigente
    select @w_cap_no_vigente = isnull(sum(am_cuota),0)
    from cob_cartera..ca_amortizacion 
    inner join cob_cartera..ca_dividendo on am_operacion = di_operacion and am_dividendo = di_dividendo
    where am_operacion = @w_numero_operacion and di_estado = 0 and am_concepto = 'CAP'
    
    --Se setea pago minimo y pago a liquidar
    select @w_pago_minimo = @w_cuota_actual + @w_saldo_vencido
    select @w_pago_liquidar = @w_cuota_actual + @w_saldo_vencido + @w_cap_no_vigente
    
    --Se consulta la descripcion de la operacion
    select @w_desc_operacion = upper(b.valor)
    from cobis..cl_tabla as a
    inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_toperacion' and b.codigo = @w_tipo_operacion
    
    select @w_datos_2 = coalesce(@w_datos_2, ' ') + ' ' + isnull(b.valor,'')
    from cobis..cl_tabla as a
    inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_edocta_data'
    
    select @w_datos_1 = isnull(b.valor,'')
    from cobis..cl_tabla as a
    inner join cobis..cl_catalogo as b on a.codigo = b.tabla
    where a.tabla = 'ca_edocta_data2'
    
    select @w_rfc_banco = isnull(en_rfc,'')
    from cobis..cl_ente where en_ente = @w_cod_clte_bco
    
    --Se vetifica si el credito es grupal o individual
    if exists(select 1 from cobis..cl_catalogo 
    where tabla = (select codigo from cobis..cl_tabla 
    where tabla = 'ca_grupal') and codigo = @w_tipo_operacion)
        select @w_tipoCredito = 'G'
    else
        select @w_tipoCredito = 'I'
    
    --Consulta final cabecera
    select Nombre = isnull(en_nombre,'')
             , ApellidoPaterno = isnull(p_p_apellido,'')
             , ApellidoMaterno = isnull(p_s_apellido,'')
             , Calle = isnull(di_calle,'')
             , NumeroExterior = isnull(cast(di_nro as varchar),'')
             , Colonia = isnull(pq_descripcion,'')
             , Ciudad = isnull(upper(ci_descripcion),'')
             , Localidad = isnull(upper(ci_descripcion),'')
             , Provincia = isnull(p.pv_descripcion,'')
             , Telefono = isnull(tel.te_valor,'SIN TELEFONO')
             , MontoCredito = @w_monto_credito
             , EstadoCredito = @w_estado_credito_nom
             , FechaConcesion = @w_fecha_concesion
             , CAT = @w_cat
             , TasaInteres = @w_tasa_ordinaria
             , InteresMoratorio = @w_imo
             , Sucursal = @w_oficina_descrip_credito
             , DireccionSucursal = @w_oficina_dir_credito
             , TelefonoSucursal = @w_oficina_telefono
             , DireccionRegional = @w_regional_dir
             , TelefonoRegional = @w_regional_telefono
             , SaldoVencido = isnull(@w_saldo_vencido, 0)
             , CuotaActual = isnull(@w_cuota_actual, 0)
             , PagoMinimo = isnull(@w_pago_minimo, 0)
             , PagoLiquidar = isnull(@w_pago_liquidar, 0)
             , FechaPagoCOF = isnull(@w_fecha_vencimiento,'')
             , TipoOperacion = @w_desc_operacion
             , Url1 = @w_pagina_internet
             , Url2 = @w_urlCondusef
             , Url3 = @w_urlBanco
             , Dato1 = @w_datos_1
             , Dato2= @w_datos_2
             , Rfc = @w_rfc_banco
             , TipoCredito = @w_tipoCredito
    from cobis..cl_ente as cl 
    left join cobis..cl_direccion on di_ente = en_ente and di_principal = 'S'
    left join cobis..cl_parroquia on pq_parroquia = di_parroquia and pq_estado = 'V'
    left join cobis..cl_ciudad on ci_ciudad = pq_ciudad AND ci_estado = 'V'
    left join cobis..cl_provincia as p on p.pv_provincia = ci_provincia  
    left join cobis..cl_telefono as tel on tel.te_ente = di_ente and tel.te_direccion = di_direccion and tel.te_tipo_telefono = 'D'
    where en_ente = @w_numero_cliente
    
    --Se obtiene el desgloce de rubros para el estado de cuenta
	select FechaMovimiento = fecha
		, Concepto = concepto
		, Pagos = pagos
		, Cargos = cargos
		, Capital = capital
		, Valor1 = valor1
		, Valor2 = valor2
		, Valor3 = valor3
		, IVA = iva
		, Seguro = seguros
		, GastoSupervision = gtosup
		, Saldo = sum(pagos + cargos) OVER (ORDER BY fila)
	from (select *
		, fila = ROW_NUMBER() OVER (ORDER BY fecha, orden) 
	from (--Se obtiene el monto del desembolso
	select operacion = di_operacion
		, fecha = min(di_fecha_ini)
		, concepto = 'Desembolso'
		, pagos = 0
		, cargos = sum(am_cuota)
		, capital = 0
		, valor1 = 0
		, valor2 = 0
		, valor3 = 0
		, iva = 0
		, seguros = 0
		, orden = 0
		, gtosup = 0
	from cob_cartera..ca_dividendo inner join cob_cartera..ca_amortizacion
		on am_operacion = di_operacion and am_dividendo = di_dividendo
	where am_operacion = @w_numero_operacion and am_concepto = @w_capital
	group by di_operacion
	union
	--Se obtiene el monto de interés
	select operacion = di_operacion
		, fecha = di_fecha_ini
		, concepto = 'Intereses'
		, pagos = 0
		, cargos = sum(am_cuota)
		, capital = 0
		, valor1 = 0
		, valor2 = 0
		, valor3 = sum(case when @w_tipoCredito = 'I' then (case when am_concepto in (@w_interes) 
					then am_cuota else 0 end) else 0 end)
		, iva = sum(case when am_concepto in (@w_ivaInteres, @w_ivaSerInc) 
					then am_cuota else 0 end)
		, seguros = sum(case when @w_tipoCredito = 'I' then (case when am_concepto in (@w_serInc) 
					then am_cuota else 0 end) else (case when am_concepto in (@w_interes, @w_serInc)
					then am_cuota else 0 end) end)
		, orden = 1
		, gtosup = 0
	from cob_cartera..ca_dividendo inner join cob_cartera..ca_amortizacion
		on am_operacion = di_operacion and am_dividendo = di_dividendo
	where am_operacion = @w_numero_operacion and am_concepto in (@w_interes, 
		@w_ivaInteres, @w_serInc, @w_ivaSerInc)
	group by di_operacion, di_fecha_ini
	union
	--Se obtiene el monto de cargos por mora
	select operacion = di_operacion
		, fecha = min(di_fecha_ini)
		, concepto = (case when @w_tipoCredito = 'I' then 'Cargo por mora'
					else 'Comisiones' end)
		, pagos = 0
		, cargos = sum(am_cuota)
		, capital = 0
		, valor1 = sum(case when @w_tipoCredito = 'I' then (case when am_concepto = @w_cmora 
				   then am_cuota else 0 end) else 0 end)
		, valor2 = sum(case when @w_tipoCredito = 'I' then (case when am_concepto = @w_imora 
				   then am_cuota else 0 end) else (case when am_concepto = @w_comPta
					then am_cuota else 0 end) end)
		, valor3 = sum(case when @w_tipoCredito = 'I' then 0 else (case when am_concepto = @w_comGco
				   then am_cuota else 0 end) end)
		, iva = sum(case when am_concepto in (@w_ivaImora, @w_ivaCmora, @w_ivaComGco, @w_ivaComPta) 
			then am_cuota else 0 end)
		, seguros = sum(case when @w_tipoCredito = 'I' then 0 else (case 
				   when am_concepto in (@w_cmora, @w_imora) then am_cuota else 0 end) end) 
		, orden = 2
		, gtosup = 0
	from cob_cartera..ca_dividendo inner join cob_cartera..ca_amortizacion
		on am_operacion = di_operacion and am_dividendo = di_dividendo
	where am_operacion = @w_numero_operacion and am_concepto in (@w_imora, @w_ivaImora, @w_cmora 
		, @w_ivaCmora, @w_comGco, @w_ivaComGco, @w_comPta, @w_ivaComPta)
	group by di_operacion, di_fecha_ini
	union
	--Se obtiene información de los pagos realizados
	select tr_operacion
		, fecha = tr_fecha_ref
		, concepto = 'Pagos'
		, pagos = sum(dtr_monto)*-1
		, cargos = 0
		, capital = sum(case when dtr_concepto = @w_capital then dtr_monto else 0 end)*-1
		, valor1 = sum(case when @w_tipoCredito = 'I' then (case when dtr_concepto = @w_cmora 
					then dtr_monto else 0 end) else 0 end)*-1
		, valor2 = sum(case when @w_tipoCredito = 'I' then (case when dtr_concepto = @w_imora 
					then dtr_monto else 0 end) else (case when dtr_concepto = @w_comPta
					then dtr_monto else 0 end) end)*-1 
		, valor3 = sum(case when @w_tipoCredito = 'I' then (case when dtr_concepto = @w_interes 
					then dtr_monto else 0 end) else (case when dtr_concepto = @w_comGco
				   then dtr_monto else 0 end) end)*-1 
		, iva = sum(case when dtr_concepto in (@w_ivaInteres, @w_ivaSerInc, @w_ivaImora, 
					@w_ivaCmora, @w_ivaComGco, @w_ivaComPta) then dtr_monto else 0 end)*-1
		, seguros = sum(case when @w_tipoCredito = 'I' then (case when dtr_concepto in (@w_serInc) 
					then dtr_monto else 0 end) else (case when dtr_concepto in (@w_interes, 
					@w_serInc, @w_cmora, @w_imora) then dtr_monto else 0 end) end)*-1
		, orden = 3 
		, gtosup = 0
	from cob_cartera..ca_transaccion inner join cob_cartera..ca_det_trn 
		on dtr_operacion = tr_operacion and dtr_secuencial = tr_secuencial inner join ca_abono 
		on ab_operacion = tr_operacion and ab_secuencial_pag = tr_secuencial inner join ca_abono_det 
		on abd_operacion = ab_operacion and ab_secuencial_ing = abd_secuencial_ing
	where tr_tran='PAG' and tr_estado <> 'RV' and dtr_dividendo > 0 and abd_tipo = 'PAG'
		and tr_operacion = @w_numero_operacion
	group by tr_operacion,tr_fecha_ref) as previo_cuenta) as estado_cuenta
    
END

-- JTO - INI 29/07/2019 CONSULTA DE DATOS DE CERTIFICADO DE PREVENCION SEGUROS Y BENEFICIARIOS
if @i_operacion = 'S'   
Begin
   SELECT
      'TIPO SEGURO' = b.so_tipo_seguro
   FROM cob_cartera..ca_operacion a
   INNER JOIN cob_cartera..ca_seguros_op b ON b.so_operacion = a.op_operacion
   WHERE a.op_banco = @i_banco
   
   SELECT
      'CODIGO CLIENTE'      = a.op_cliente,
      'NOMBRE CLIENTE'      = b.en_nombre + ' ' + b.p_s_nombre + ' ' + b.p_p_apellido + ' ' + b.p_s_apellido,
      'NOMBRE BENEFICIARIO' = c.bs_nombres + ' ' + c.bs_apellido_paterno + ' ' + c.bs_apellido_materno,
      'PORCENTAJE'          = c.bs_porcentaje,
      'FECHA VIG INICIAL'   = convert(varchar,(SELECT min(so_fecha_inicial) FROM cob_cartera..ca_seguros_op WHERE so_operacion = a.op_operacion),103),
      'FECHA VIG FINAL'     = convert(varchar,(SELECT max(so_fecha_fin) FROM cob_cartera..ca_seguros_op WHERE so_operacion = a.op_operacion),103)
   FROM cob_cartera..ca_operacion a
        INNER JOIN cobis..cl_ente b ON b.en_ente = a.op_cliente
        INNER JOIN cobis..cl_beneficiario_seguro c ON c.bs_tramite = a.op_tramite AND c.bs_producto = 7
   WHERE a.op_banco = @i_banco
End 
-- JTO - FIN 29/07/2019 CONSULTA DE DATOS DE CERTIFICADO DE PREVENCION SEGUROS Y BENEFICIARIOS

--Datos para reporte de Caratula dual
if @i_operacion = 'M'   
Begin


   SELECT
      'CODIGO GRUPO'      = isnull(a.op_grupo, 0),
      'NOMBRE CLIENTE'    = isnull(b.gr_nombre,''),
      'RECA'     		  = isnull(@w_pie_pagina,'')
   FROM cob_cartera..ca_operacion a
        INNER JOIN cobis..cl_grupo b ON b.gr_grupo = a.op_grupo        
   WHERE a.op_banco = @i_banco
END

return 0

ERROR:
exec @w_return = cobis..sp_cerror
@t_debug  = @t_debug,
@t_file   = @t_file,
@t_from   = @w_sp_name,
@i_num    = @w_error

return @w_error
go