
/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                repdatosbc.sp                           */
/*      Procedimiento:          sp_reporte_bc                           */
/*      Disenado por:           Geovanny Guaman                         */
/*      Fecha de escritura:     12 de Feb 2019                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante           */
/*                              PROPOSITO                               */
/*      Procedimiento que genera los datos requeridos en la generación  */
/*      de documentos impresos.                                         */
/*                                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*                                                                      */
/*  22/08/2019    G. Guaman           Se crea sp para nuevos productos  */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reporte_bc')
   drop proc sp_reporte_bc
go

create proc sp_reporte_bc
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
@i_cod_reporte    smallint= null,
@i_banco          varchar(20) = null,
@i_nemonico       varchar(10)  = null        

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
         @w_domicilio                   varchar(100),        
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
         @w_dom_aclaraciones            varchar(100),
         @w_nombre_cliente              varchar(100),
         @w_obligado_1                  varchar(100),
         @w_obligado_2                  varchar(100),
         @w_tipo_operacion              varchar(150),
         @w_desc_operacion              varchar(50),
         @w_tipo_plazo_credito          char(1),
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
         @w_no_reg                      int,
         @w_num_reg                     int,
         @w_saldo                       decimal(18,2),
         @w_saldot                      decimal(18,2),
         @w_fecha                       datetime,
         @w_concepto                    varchar(30),
         @w_pagos                       decimal(18,2),
         @w_cargos                      decimal(18,2),
         @w_capital                     decimal(18,2),
         @w_cmo                         decimal(18,2),
         @w_imor                        decimal(18,2),
         @w_interes                     decimal(18,2),
         @w_iva                         decimal(18,2),
         @w_seguros                     decimal(18,2),
         @w_pagost                      decimal(18,2),
         @w_cargost                     decimal(18,2),
         @w_capitalt                    decimal(18,2),
         @w_cmot                        decimal(18,2),
         @w_imot                        decimal(18,2),
         @w_interest                    decimal(18,2),
         @w_ivat                        decimal(18,2),
         @w_gtosup                      money,
         @w_gtosupt                     money,
         @w_segurost                    decimal(18,2),
         @w_datos_1                     varchar(400),
         @w_datos_2                     varchar(400),
         @w_rfc_banco                   varchar(20),
		 @w_groupName           		varchar(30), 
         @w_groupNum                    int,
		 @w_presiName                   varchar(400),
         @w_secreName                   varchar(400),
         @w_tesoName                    varchar(400),
		 @w_representative              varchar(400)
		 
         
   
-- CAPTURA NOMBRE DE STORED PROCEDURE
select @w_sp_name = 'sp_reporte_bc'
select @w_error = null
  
if  @t_trn <> 77539
begin   
    select @w_error = 2101006
    goto ERROR
end

select @w_pie_pagina = ''
      ---INICIO---GG 23/07/2019
if exists( SELECT TOP 1 1 from cob_credito..cr_imp_documento where id_mnemonico = @i_nemonico AND id_toperacion = (select op_toperacion from cob_cartera..ca_operacion where op_banco = @i_banco))
begin
   select top 1 @w_pie_pagina = id_dato
     from cob_credito..cr_imp_documento 
    where id_mnemonico = @i_nemonico 
      AND id_toperacion =  (select op_toperacion from cob_cartera..ca_operacion where op_banco = @i_banco) 
end   ---FIN---GG 23/07/2019
else
begin
    select @w_error = 721908
    goto ERROR
end
    
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
       @w_provincia  = pv_descripcion,
       @w_cod_direc  = di_direccion
from cobis..cl_direccion, cobis..cl_ciudad, cobis..cl_provincia
where di_ente = @w_cod_clte_bco
and   di_tipo = 'AE'
and   di_direccion = (select max(di_direccion) from cobis..cl_direccion
                      where di_ente = @w_cod_clte_bco
                      and   di_tipo = 'AE')
and   di_ciudad = ci_ciudad
and   ci_provincia = pv_provincia
                       
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
    
--Datos para reporte de Caratula dual
if @i_operacion = 'M'   
Begin

 --Se obtiene la id y descripcion de grupo     
	SELECT @w_groupNum  = isnull(a.op_grupo,0),
	       @w_groupName  = isnull(b.gr_nombre,'')     
    FROM cob_cartera..ca_operacion a
    INNER JOIN cobis..cl_grupo b ON b.gr_grupo = a.op_grupo        
    WHERE a.op_banco = @i_banco
	
	select @w_presiName = en_nombre + ' '+ p_p_apellido + ' '+ p_s_apellido 
	  from cobis..cl_ente, cobis..cl_cliente_grupo
	 where en_ente = cg_ente
	   and cg_rol = 'P'
	   and cg_grupo = @w_groupNum


	select @w_secreName = en_nombre + ' '+ p_p_apellido + ' '+ p_s_apellido 
	  from cobis..cl_ente, cobis..cl_cliente_grupo
	 where en_ente = cg_ente
	   and cg_rol = 'S'
	   and cg_grupo = @w_groupNum


	select @w_tesoName = en_nombre + ' '+ p_p_apellido + ' '+ p_s_apellido 
	  from cobis..cl_ente, cobis..cl_cliente_grupo
	 where en_ente = cg_ente
	   and cg_rol = 'T'
	   and cg_grupo = @w_groupNum

	SELECT @w_representative = fi_rep_nombre  
	FROM cobis..cl_filial

   SELECT
      'PRESIDENTE'      = isnull(@w_presiName, ''),
      'SECRETARIO'    = isnull(@w_secreName,''),
	  'TESORERO'      = isnull(@w_tesoName, ''),
      'REPRESETANTE'    = isnull(@w_representative,''),
      'RECA'     		  = isnull(@w_pie_pagina,'')
   
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
