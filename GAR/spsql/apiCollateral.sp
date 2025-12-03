use cob_custodia
go

IF OBJECT_ID ('dbo.sp_api_collateral') IS NOT NULL
	DROP PROCEDURE dbo.sp_api_collateral
GO

/************************************************************************************/
/*  Archivo:            apiCollateral.sp                                            */
/*  Stored procedure:   sp_api_collateral                                           */
/*  Base de datos:      cob_custodia                                                */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Humberto Pacheco                                            */
/*  Fecha de creaci贸n:  Ago-08-2019                                                 */
/************************************************************************************/
/*          IMPORTANTE                                                              */
/*  Este programa es propiedad de "COBISCORP". Ha sido desarrollado                 */
/*  bajo el ambiente operativo COBIS-sistema desarrollado por                       */
/*  "COBISCORP S.A."-Ecuador                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como                      */
/*  cualquier alteracion o agregado hecho por alguno de sus                         */
/*  usuarios sin el debido consentimiento por escrito de la                         */
/*  Gerencia General de COBISCORP o su representante.                               */
/************************************************************************************/
/*          PROPOSITO                                                               */
/*  Este procedimiento permite la ejecucion de los procedimientos almacenados para  */
/*  obtener la informacion de un cliente                                            */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                  RAZON                                  */
/*  2019-AGO-30       hpacheco               Emisi贸n Inicial                        */
/*  2020-MAR-05       lcabeza                actualizacion                          */
/*  2022-ENE-25       krodriguez             Cambio tipo de dato i_canton y w_canton*/
/************************************************************************************/


create proc sp_api_collateral (
    @s_ssn                              int          = NULL,
    @s_user                             varchar(14)  = NULL,
    @s_sesn                             int          = NULL,
    @s_term                             varchar(30)  = NULL,
    @s_date                             datetime     = NULL,
    @s_srv                              varchar(30)  = NULL,
    @s_lsrv                             varchar(30)  = NULL,
    @s_rol                              smallint     = NULL,
    @s_ofi                              smallint     = NULL,
    @s_org_err                          char(1)      = NULL,
    @s_error                            int          = NULL,
    @s_sev                              tinyint      = NULL,
    @s_msg                              varchar(64)  = NULL,
    @s_org                              char(1)      = NULL,
    @t_trn                              int          = NULL,
    @t_debug                            char(1)      = 'N',
    @t_file                             varchar(14)  = NULL,
    @t_corr                             char(1)      = 'N',
    @t_ssn_corr                         int          = NULL,
    @t_from                             varchar(32)  = NULL,
    @t_rty                              char(1)      = NULL,

    -- parametros de cabecera
    @i_Authorization                    varchar(100)    = NULL,     --headers.Authorization
    @i_x_request_id                     varchar(36)     = NULL,     --headers.x-request-id
    @i_x_financial_id                   varchar(25)     = NULL,     --headers.x-financial-id
    @i_x_end_user_login                 varchar(25)     = NULL,     --headers.x-end-user-login
    @i_x_end_user_request_date_time     varchar(25)     = NULL,     --headers.x-end-user-request-date-time
    @i_x_end_user_terminal              varchar(25)     = NULL,     --headers.x-end-user-terminal
    @i_x_end_user_last_logged_date_time varchar(25)     = NULL,     --headers.x-end-user-last-logged-date-time
    @i_x_jws_signature                  varchar(25)     = NULL,     --headers.x-jws-signature
   @i_x_reverse							varchar(25)     = NULL,     --headers.x-reverse
   @i_x_ssn_to_reverse			        varchar(25)     = NULL,     --headers.x-requestId-to-reverse

    -- parametros del servicio
    @i_operacion                        char(1)         = NULL,     -- operaci贸n
    @i_code                             varchar(64)     = NULL,     -- collateral.code
    @i_subsidiary                       tinyint         = NULL,     -- collateral.subsidiary.code
    @i_branch                           smallint        = NULL,     -- collateral.branch.code
    @i_type                             varchar(64)     = NULL,     -- collateral.type.code
    @i_status                           catalogo        = NULL,     -- collateral.status
    @i_entryDate                        datetime        = NULL,     -- collateral.entryDate
    @i_initialAmount                    money           = NULL,     -- collateral.initialAmount
    @i_actualAmount                     money           = NULL,     -- collateral.actualAmount
    @i_currency                         tinyint         = NULL,     -- collateral.currency.code
    @i_guarantor                        int             = NULL,     -- collateral.guarantor.code
    @i_instruction                      varchar(255)    = NULL,     -- collateral.instruction
    @i_description                      varchar(255)    = NULL,     -- collateral.description
    @i_inspect                          char(1)         = NULL,     -- collateral.inspect
    @i_reasonNotInspection              catalogo        = NULL,     -- collateral.reasonNotInspection.code
    @i_legalSufficiency                 char(1)         = NULL,     -- collateral.legalSufficiency
    @i_valueCollateralSource             catalogo    	= NULL,     	-- collateral.valueCollateralSource.code
    @i_bondedWarehouse                  smallint        = NULL,     -- collateral.bondedWarehouse.code
    @i_nextInspectionMonth              tinyint         = NULL,     -- collateral.nextInspectionMonth
    @i_issuanceDate                     datetime        = NULL,     -- collateral.issuanceDate
    @i_frequency                        catalogo        = NULL,     -- collateral.frequency.code
    @i_representativeDepositor          varchar(64)     = NULL,     -- collateral.representativeDepositor
    @i_determinePolicy                  char(1)         = NULL,     -- collateral.determinePolicy
    @i_withdrawalDocumentationDate      datetime        = NULL,     -- collateral.withdrawalDocumentationDate
    @i_returnDocumentationDate          datetime        = NULL,     -- collateral.returnDocumentationDate
    @i_isAdequate                       char(1)         = NULL,     -- collateral.isAdequate
    @i_fixedTerm                        varchar(30)     = NULL,     -- collateral.fixedTerm
    @i_accountingBranch                 smallint        = NULL,     -- collateral.accountingBranch.code
    @i_isShared                         char(1)         = NULL,     -- collateral.isShared
    @i_sharedValue                      money           = NULL,     -- collateral.sharedValue
    @i_expirationDate                   datetime        = NULL,     -- collateral.expirationDate
    @i_country                          smallint        = NULL,     -- collateral.country.code
    @i_province                         smallint        = NULL,     -- collateral.province.code
    @i_canton                           int             = NULL,     -- collateral.canton.code
    @i_percentageCoverage    float           = NULL,     -- collateral.percentageCoverage
    @i_customer_code                    int             = NULL,     -- collateral.collateralCustomers.code
    @i_initDate                         datetime        = NULL,     -- initDate
    @i_endDate                          datetime        = NULL,     -- endDate

    -- parametro de salida
    @o_code_collateral                   varchar(64)    = NULL out, -- collateral.code
    @o_fecha_proceso                     varchar(25)    = NULL out  -- fechaProceso
)as

declare @w_sp_name                      varchar(30),
        @w_error                        int,
        @w_code                         varchar(64),
        @w_subsidiary                   tinyint,
        @w_branch                       smallint,
        @w_type                         varchar(64),
        @w_status                       varchar(64),
        @w_sequentialNumber             int,
		@w_code_custodia                int,
		@w_type_custodia                varchar(64),
		@w_oficial                      smallint,
		@w_name                         varchar(160),
		@w_actualAmount                 money,
		@w_guarantor                    int,
		@w_instruction                  varchar(255),
		@w_description                  varchar(255),
		@w_inspect                      char(1),
		@w_reasonNotInspection          varchar(10),
		@w_legalSufficiency             char(1), 
		@w_valueCollateralSource        varchar(10),
		@w_bondedWarehouse              smallint,
		@w_nextInspectionMonth          tinyint,
		@w_representativeDepositor      varchar(255),
		@w_determinePolicy              char(1),
		@w_withdrawalDocumentationDate  datetime,
		@w_returnDocumentationDate      datetime,
		@w_fixedTerm                    varchar(30),
		@w_sharedValue                  money,
		@w_canton                       int,             -- KDR Cambio tipo de dato por compatibilidad con cobis..cl_ciudad

		@w_entryDate                    datetime,
		@w_initialAmount                money,
		@w_issuanceDate                 datetime,
		@w_percentageCoverage           float,
		@w_frequency                    catalogo,
		@w_isAdequate                   char(1),
		@w_accountingBranch             smallint,
		@w_isShared	                    char(1),
		@w_expirationDate               datetime,
		@w_country                      smallint,
		@w_province                     smallint,
		
		@w_proposal                     int, 
		@w_currency                     tinyint,
		@w_situation                    char(1),
		@w_ctaInspection                varchar(20),
		@w_judicialCollection           char(1),
		@w_collectCommission            char(1),
		@w_dpfCount                     varchar(30),
		@w_openClose                    char(1),
		@w_Owner                        varchar(64),
		@w_garmentAddress               varchar(64),
		@w_cityPrenda                   varchar(64),
		@w_telephonePrenda              varchar(64)

select @w_sp_name = 'sp_api_collateral'

SELECT @w_error = 0

/* ************************************* */
/* VALIDACI脫N DEL SERVICIO               */
/* ************************************* */

/*
validacion que la aplicacion exista mediante el API key que se enuentre registrado
exec @w_error=cobis..sp_api_validation
    @i_api_key                        = @i_x_api_key,
    @i_operation                      = 'A'

if @w_error != 0
    goto CIERRE

Validar que el x-request-id no este duplicado para el mismo codigo de la aplicacion
exec @w_error=cobis..sp_api_validation
    @i_x_request_id                   = @i_x_request_id,
    @i_operation                      = 'O'

if @w_error != 0
    goto CIERRE

SELECT @w_fecha_proceso                = GETDATE()*/

/* ************************************* */
/* OPERACIONES                           */
/* ************************************* */

/* Descripci贸n: Creaci贸n de garant铆a.
 * Operaci贸n: [POST] - /collateral
 */

if @i_operacion = 'I'
begin
    if @i_subsidiary is null or @i_branch is null or @i_type is null
    begin
        select @w_error = 1901001
        goto CIERRE
    end
    exec @w_error = cob_custodia..sp_custodia
        @s_user=@s_user,
        @s_term=@s_term,
        @s_ofi=@s_ofi,
        @s_ssn=@s_ssn,
        @s_date=@s_date,
        @t_trn=19090,
        @i_operacion='I',
        @i_filial=@i_subsidiary,
        @i_sucursal=@i_branch,
        @i_tipo=@i_type,
        @i_estado=@i_status,
        @i_fecha_ingreso=@i_entryDate,
        @i_valor_inicial=@i_initialAmount,
        @i_valor_actual=@i_actualAmount,
        @i_moneda=@i_currency,
        @i_garante=@i_guarantor,
        @i_instruccion=@i_instruction,
        @i_descripcion=@i_description,
        @i_inspeccionar=@i_inspect,
        @i_motivo_noinsp=@i_reasonNotInspection,
        @i_suficiencia_legal=@i_legalSufficiency,
        @i_almacenera=@i_bondedWarehouse,
        @i_mex_prx_inspec=@i_nextInspectionMonth,
        @i_fecha_const=@i_issuanceDate,
        @i_periodicidad=@i_frequency,
        @i_depositario=@i_representativeDepositor,
        @i_posee_poliza=@i_determinePolicy,
        @i_fecha_retiro=@i_withdrawalDocumentationDate,
        @i_fecha_devolucion=@i_returnDocumentationDate,
        @i_adecuada_noadec=@i_isAdequate,
        @i_plazo_fijo=@i_fixedTerm,
        @i_oficina_contabiliza=@i_accountingBranch,
        @i_compartida=@i_isShared,
        @i_valor_compartida=@i_sharedValue,
        @i_fecha_vencimiento=@i_expirationDate,
        @i_pais=@i_country,
        @i_provincia=@i_province,
        @i_porcentaje_valor=@i_percentageCoverage,
        @i_ente=@i_customer_code,
        @o_codigo_externo=@o_code_collateral out


    if @w_error != 0
        goto CIERRE
    
	select top 1 @w_code_custodia = cu.cu_custodia, @w_type_custodia=cu.cu_tipo from cob_custodia..cu_custodia cu
        where cu.cu_codigo_externo = @o_code_collateral

    select top 1 @w_oficial= en_oficial, @w_name=en_nombre FROM cobis..cl_ente WHERE en_ente = @i_customer_code
    
    exec @w_error = cob_custodia..sp_cliente_garantia
	   @s_ssn=@s_ssn,               
	   @s_date=@s_date              ,
	   @s_user=@s_user,              
	   @s_term=@s_term,               
	   @s_ofi=@s_ofi,                
	   @t_trn=19040,                 
	   @i_operacion='I',          
	   @i_filial=@i_subsidiary,             
	   @i_sucursal=@i_branch,           
	   @i_custodia=@w_code_custodia,           
	   @i_tipo_cust=@w_type_custodia,          
	   @i_ente=@i_customer_code,               
	   @i_principal='S',          
	   @i_oficial=@w_oficial,            
	   @i_nombre=@w_name      
	 
	 if @w_error != 0
        goto CIERRE 

    select @o_code_collateral+''
end
/* Descripci贸n: Consulta de garant铆a por el c贸digo.
 * Operaci贸n: [GET] - /collateral/{collateralId}
 */

if @i_operacion = 'Q'
begin
    select
        'code' = cu.cu_codigo_externo,
        'subsidiary' = cu_filial,
        'branch' = cu.cu_sucursal,
        'type' = cu.cu_tipo,
        'sequentialNumber'= cu.cu_custodia,
        'status' = cu.cu_estado,
        'entryDate' = cu.cu_fecha_ingreso,
        'initialAmount' = cu.cu_valor_inicial,
        'actualAmount' = cu.cu_valor_actual,
        'currency' = cu.cu_moneda,
        'guarantor' =cu.cu_garante,
        'instruction'=cu.cu_instruccion,
        'description'=cu.cu_descripcion,
        'inspect' = cu.cu_inspeccionar,
        'reasonNotInspection'=cu.cu_motivo_noinsp,
        'legalSufficiency' = cu.cu_suficiencia_legal,
        'valueCollateralSource' = cu_fuente_valor,
        'bondedWarehouse' =cu.cu_almacenera,
        'nextInspectionMonth'=cu.cu_mex_prx_inspec,
        'lastActivityDate' =cu.cu_fecha_modif,
        'issuanceDate' = cu.cu_fecha_const,
        'frecuency' = cu.cu_periodicidad,
        'representativeDepositor' = cu_depositario,
        'determinePolicy' = cu.cu_posee_poliza,
        'inspectionsNumber'=cu.cu_nro_inspecciones,
        'monthsPeriod'=cu.cu_intervalo,
        'withdrawalDocumentationDate'=cu.cu_fecha_retiro,
        'returnDocumentationDate'=cu.cu_fecha_devolucion,
        'issuanceUser' = cu.cu_usuario_crea,
        'modificationUser' = cu.cu_usuario_modifica,
        'lastInspectionDate'=cu.cu_fecha_insp,
        'isAdequate' =燾u.cu_adecuada_noadec,
        'fixedTerm'=cu.cu_plazo_fijo,
        'accountingBranch' =燾u.cu_oficina_contabiliza,
        'isShared' =燾u.cu_compartida,
        'sharedValue'= cu.cu_valor_compartida,
        'nextInspectionDate' = cu_fecha_prox_insp,
        'expirationDate' = cu_fecha_vencimiento,
        'country' =燾u.cu_pais,
        'province' =燾u.cu_provincia,
        'canton' = cu.cu_canton,
        'lastAppraisalDate'=cu.cu_fecha_avaluo,
        'percentageCoverage'=cu.cu_porcentaje_cobertura
    from cob_custodia..cu_custodia cu 
    where cu_codigo_externo= @i_code
    if @@rowcount = 0
    begin
        select @w_error = 141215
        goto CIERRE
    end
end

/* Descripci贸n: Consulta de garant铆as por el c贸digo COBIS de un cliente.
 * Operaci贸n: [GET] - /collateral/customers/{customerId}
 */

if @i_operacion = 'A'
begin
    select top 1 
		@w_branch = cu.cu_sucursal,
		@w_subsidiary = cu.cu_filial
	from cob_custodia..cu_custodia cu 
	inner join cob_custodia..cu_cliente_garantia cuc 
	on cu.cu_codigo_externo=cuc.cg_codigo_externo
	where cuc.cg_ente = @i_customer_code

	if @@rowcount = 0
    begin
        select @w_error = 141215
        goto CIERRE
    end
	
	exec @w_error = cob_custodia..sp_buscar_custodia
		@s_user=@s_user,
        @s_term=@s_term,
        @s_ofi=@s_ofi,
        @s_ssn=@s_ssn,
        @s_date=@s_date,
        @t_trn=19307,
		@i_operacion='C',
		@i_cliente=@i_customer_code,
		@i_modo=0,
		@i_filial=@w_subsidiary

	if @w_error != 0
        goto CIERRE
end

/* Descripci贸n: Consulta de garant铆as por diferentes par谩metros.
 * Operaci贸n: [GET] - /collateral
 */

if @i_operacion = 'S'
begin
    if @i_branch = null and @i_initDate = null and @i_endDate = null
    begin
        select @w_error = 171085
        goto CIERRE
    end

    if @i_branch is null
    begin
        select top 1 @w_subsidiary = cu.cu_filial from cob_custodia..cu_custodia cu 
		where cu.cu_sucursal=@s_ofi
        if @@rowcount = 0
        begin
            select @w_error = 141215
            goto CIERRE
        end
		
		exec @w_error = cob_custodia..sp_buscar_custodia
			@s_user=@s_user,
			@s_term=@s_term,
			@s_ofi=@s_ofi,
			@s_ssn=@s_ssn,
			@s_date=@s_date,
			@t_trn=19304,
			@i_operacion='S',
			@i_modo=0,
			@i_sucursal=@s_ofi,
			@i_filial=@w_subsidiary,
			@i_fecha_ingreso1 = @i_initDate,
			@i_fecha_ingreso2 = @i_endDate
			
		if @w_error != 0
			goto CIERRE
		
    end
    else
    begin
        select top 1 @w_subsidiary = cu.cu_filial from cob_custodia..cu_custodia cu 
		where cu.cu_sucursal=@i_branch
        if @@rowcount = 0
        begin
            select @w_error = 141215
            goto CIERRE
        end
		
		exec @w_error = cob_custodia..sp_buscar_custodia
			@s_user=@s_user,
			@s_term=@s_term,
			@s_ofi=@s_ofi,
			@s_ssn=@s_ssn,
			@s_date=@s_date,
			@t_trn=19304,
			@i_operacion='S',
			@i_modo=0,
			@i_sucursal=@i_branch,
			@i_filial=@w_subsidiary

		if @w_error != 0
			goto CIERRE
    end
end

/* Descripci贸n: Modificaci贸n de garant铆a.
 * Operaci贸n: [PATCH] - /collateral/{collateralId}
 */

 if @i_operacion = 'U'
begin
    select
        @w_code = cu.cu_codigo_externo,
        @w_subsidiary =cu.cu_filial,
        @w_branch =cu.cu_sucursal,
        @w_type = cu.cu_tipo,
        @w_sequentialNumber = cu.cu_custodia,
        @w_status = cu.cu_estado,
		@w_actualAmount = cu.cu_valor_actual,
		@w_guarantor = cu.cu_garante,
		@w_instruction = cu.cu_instruccion,
		@w_description = cu.cu_descripcion,
		@w_inspect = cu.cu_inspeccionar,
		@w_reasonNotInspection = cu.cu_motivo_noinsp,
		@w_legalSufficiency = cu.cu_suficiencia_legal,
		@w_valueCollateralSource = cu.cu_fuente_valor,
		@w_bondedWarehouse = cu.cu_almacenera,
		@w_nextInspectionMonth = cu.cu_mex_prx_inspec,
		@w_representativeDepositor = cu.cu_depositario,
		@w_determinePolicy = cu.cu_posee_poliza,
		@w_withdrawalDocumentationDate = cu.cu_fecha_retiro,
		@w_returnDocumentationDate = cu.cu_fecha_devolucion,
		@w_fixedTerm = cu.cu_plazo_fijo,
		@w_sharedValue = cu.cu_valor_compartida,
		@w_canton = cu.cu_canton,
        @w_entryDate=cu.cu_fecha_ingreso,
        @w_initialAmount=cu.cu_valor_inicial ,
        @w_issuanceDate=cu.cu_fecha_const,
        @w_percentageCoverage= cu.cu_porcentaje_valor,
	    @w_frequency=cu.cu_periodicidad,
	    @w_isAdequate= cu.cu_adecuada_noadec,
        @w_accountingBranch=cu.cu_oficina_contabiliza,
        @w_isShared=cu.cu_compartida,
        @w_sharedValue=cu.cu_valor_compartida,
        @w_expirationDate=cu.cu_fecha_vencimiento,
	    @w_country=cu.cu_pais,
	    @w_province=cu.cu_provincia,  
        @w_proposal=cu.cu_propuesta, 
		@w_currency=cu.cu_moneda,                     
		@w_situation=cu.cu_situacion,                    
		@w_ctaInspection=cu.cu_cta_inspeccion,                
		@w_judicialCollection=cu.cu_cobranza_judicial,           
		@w_collectCommission=cu.cu_cobrar_comision,           
		@w_dpfCount=cu.cu_cuenta_dpf,                    
		@w_openClose=cu.cu_abierta_cerrada,                   
		@w_Owner=cu.cu_propietario,                       
		@w_garmentAddress=cu.cu_direccion_prenda,              
		@w_cityPrenda=cu.cu_ciudad_prenda,                   
		@w_telephonePrenda=cu.cu_telefono_prenda             
	     
    from cob_custodia..cu_custodia cu
    where cu_codigo_externo= @i_code

    if @@rowcount = 0
    begin
        select @w_error = 141215
        goto CIERRE
    end

	 if @i_status is not null and @w_status is not null and @i_status != @w_status
        select @w_status = @i_status
     if @i_actualAmount is not null and @w_actualAmount is not null and @i_actualAmount != @w_actualAmount
        select @w_actualAmount = @i_actualAmount
     if @i_guarantor is not null and @w_guarantor is not null and @i_guarantor != @w_guarantor
        select @w_guarantor = @i_guarantor
     if @i_instruction is not null and @w_instruction is not null and @i_instruction != @w_instruction
        select @w_instruction = @i_instruction
     if @i_description is not null and @w_description is not null and @i_description != @w_description
        select @w_description = @i_description
     if @i_inspect is not null and @w_inspect is not null and @i_inspect != @w_inspect
        select @w_inspect = @i_inspect
     if @i_reasonNotInspection is not null and @w_reasonNotInspection is not null and @i_reasonNotInspection != @w_reasonNotInspection
        select @w_reasonNotInspection = @i_reasonNotInspection
	if @i_legalSufficiency is not null and @w_legalSufficiency is not null and @i_legalSufficiency != @w_legalSufficiency
        select @w_legalSufficiency = @i_legalSufficiency	
	if @i_valueCollateralSource is not null and @w_valueCollateralSource is not null and @i_valueCollateralSource != @w_valueCollateralSource
        select @w_valueCollateralSource = @i_valueCollateralSource
     if @i_bondedWarehouse is not null and @w_bondedWarehouse is not null and @i_bondedWarehouse != @w_bondedWarehouse
        select @w_bondedWarehouse = @i_bondedWarehouse
	if @i_nextInspectionMonth is not null and @w_nextInspectionMonth is not null and @i_nextInspectionMonth != @w_nextInspectionMonth
        select @w_nextInspectionMonth = @i_nextInspectionMonth
	if @i_representativeDepositor is not null and @w_representativeDepositor is not null and @i_representativeDepositor != @w_representativeDepositor
        select @w_representativeDepositor = @i_representativeDepositor
    if @i_determinePolicy is not null and @w_determinePolicy is not null and @i_determinePolicy != @w_determinePolicy
        select @w_determinePolicy = @i_determinePolicy
	if @i_withdrawalDocumentationDate is not null and @w_withdrawalDocumentationDate is not null and @i_withdrawalDocumentationDate != @w_withdrawalDocumentationDate
        select @w_withdrawalDocumentationDate = @i_withdrawalDocumentationDate
    if @i_returnDocumentationDate is not null and @w_returnDocumentationDate is not null and @i_returnDocumentationDate != @w_returnDocumentationDate
        select @w_returnDocumentationDate = @i_returnDocumentationDate
	if @i_fixedTerm is not null and @w_fixedTerm is not null and @i_fixedTerm != @w_fixedTerm
        select @w_fixedTerm = @i_fixedTerm
	if @i_sharedValue is not null and @w_sharedValue is not null and @i_sharedValue != @w_sharedValue
        select @w_sharedValue = @i_sharedValue
    if @i_canton is not null and @w_canton is not null and @i_canton != @w_canton
        select @w_canton = @i_canton

    if @i_entryDate is not null and @w_entryDate is not null and @i_entryDate != @w_entryDate
        select @w_entryDate = @i_entryDate
    if @i_initialAmount is not null and @w_initialAmount is not null and @i_initialAmount != @w_initialAmount
        select @w_initialAmount = @i_initialAmount
    if @i_issuanceDate is not null and @w_issuanceDate is not null and @i_issuanceDate != @w_issuanceDate
        select @w_issuanceDate = @i_issuanceDate
	if @i_percentageCoverage is not null and @w_percentageCoverage is not null and @i_percentageCoverage != @w_percentageCoverage
        select @w_percentageCoverage = @i_percentageCoverage
	if @i_frequency is not null and @w_frequency is not null and @i_frequency != @w_frequency
        select @w_frequency = @i_frequency
	if @i_isAdequate is not null and @w_isAdequate is not null and @i_isAdequate != @w_isAdequate
        select @w_isAdequate = @i_isAdequate
    if @i_accountingBranch is not null and @w_accountingBranch is not null and @i_accountingBranch != @w_accountingBranch
        select @w_accountingBranch = @i_accountingBranch
    if @i_isShared is not null and @w_isShared is not null and @i_isShared != @w_isShared
        select @w_isShared = @i_isShared
    if @i_sharedValue is not null and @w_sharedValue is not null and @i_sharedValue != @w_sharedValue
        select @w_sharedValue = @i_sharedValue
     if @i_expirationDate is not null and @w_expirationDate is not null and @i_expirationDate != @w_expirationDate
        select @w_expirationDate = @i_expirationDate
     if @i_country is not null and @w_country is not null and @i_country != @w_country
        select @w_country = @i_country
	if @i_province is not null and @w_province is not null and @i_province != @w_province
        select @w_province = @i_province
    if @i_currency is not null and @w_currency is not null and @i_currency != @w_currency
        select @w_currency = @i_currency

    exec @w_error = cob_custodia..sp_custodia
         @s_user=@s_user,
         @s_term=@s_term,
         @s_ofi=@s_ofi,
         @s_ssn=@s_ssn,
         @s_date=@s_date,
         @t_trn=19091,
         @i_operacion='U',
         @i_filial=@w_subsidiary,
         @i_sucursal=@w_branch,
         @i_tipo=@w_type,
         @i_custodia=@w_sequentialNumber,
         @i_estado=@w_status,
         @i_valor_actual=@w_actualAmount,
         @i_garante=@w_guarantor,
         @i_instruccion=@w_instruction,
         @i_descripcion=@w_description,
         @i_inspeccionar=@w_inspect,
         @i_motivo_noinsp=@w_reasonNotInspection,
		 @i_suficiencia_legal=@w_legalSufficiency,
         @i_fuente_valor=@w_valueCollateralSource,
         @i_almacenera=@w_bondedWarehouse,
         @i_mex_prx_inspec=@w_nextInspectionMonth,
         @i_depositario=@w_representativeDepositor,
         @i_posee_poliza=@w_determinePolicy,
         @i_parte = 1,
         @i_fecha_retiro=@w_withdrawalDocumentationDate,
         @i_fecha_devolucion=@w_returnDocumentationDate,
         @i_plazo_fijo=@w_fixedTerm,
         @i_valor_compartida=@w_sharedValue,
         @i_canton=@w_canton,
		 @i_fecha_ingreso=@w_entryDate,
		 @i_valor_inicial=@w_initialAmount,
		 @i_fecha_const=@w_issuanceDate,
		 @i_porcentaje_valor=@w_percentageCoverage,
		 @i_periodicidad = @w_frequency,
		 @i_adecuada_noadec=@w_isAdequate,
		 @i_oficina_contabiliza=@w_accountingBranch,
		 @i_compartida=@w_isShared,
		 @i_fecha_vencimiento=@w_expirationDate,
		 @i_pais=@w_country,
		 @i_provincia=@w_province,
		 @i_propuesta=@w_proposal, 
		 @i_moneda=@w_currency,
		 @i_situacion=@w_situation,
		 @i_cta_inspeccion=@w_ctaInspection,
		 @i_cobranza_judicial=@w_judicialCollection,
		 @i_cobrar_comision=@w_collectCommission,
		 @i_cuenta_dpf=@w_dpfCount,
		 @i_abierta_cerrada=@w_openClose,
		 @i_propietario=@w_Owner,
		 @i_direccion_prenda=@w_garmentAddress,
		 @i_ciudad_prenda=@w_cityPrenda,
		 @i_telefono_prenda=@w_telephonePrenda,
         @o_codigo_externo = @o_code_collateral out

    if @w_error != 0
        goto CIERRE

    set @o_code_collateral = @i_code

    select @o_code_collateral+''
end

/* Descripci贸n: Eliminaci贸n de garant铆a por el c贸digo.
 * Operaci贸n: [DELETE] - /collateral/{collateralId}
 */

if @i_operacion = 'D'
begin
    select
        @w_code = cu.cu_codigo_externo,
        @w_subsidiary = cu_filial,
        @w_branch = cu.cu_sucursal,
        @w_type = cu.cu_tipo,
        @w_sequentialNumber = cu.cu_custodia,
        @w_status = cu.cu_estado
    from cob_custodia..cu_custodia cu
    where cu_codigo_externo = @i_code

    if @@rowcount = 0
    begin
        select @w_error = 141215
        goto CIERRE
    end

    exec @w_error = cob_custodia..sp_custodia
        @s_user=@s_user,
        @s_term=@s_term,
        @s_ofi=@s_ofi,
        @s_ssn=@s_ssn,
        @s_date=@s_date,
        @t_trn=19092,
        @i_operacion='D',
        @i_filial=@w_subsidiary,
        @i_sucursal=@w_branch,
        @i_tipo=@w_type,
        @i_custodia=@w_sequentialNumber,
        @i_estado=@i_status

    if @w_error != 0
    begin
        select @w_error = 141215
        goto CIERRE
    end
end

--Creaci贸n de auditoria
/*exec cobis..sp_api_auditoria
     @i_x_request_id                     = @i_x_request_id,
     @i_x_financial_id                   = @i_x_financial_id,
     @i_x_end_user_login                 = @i_x_end_user_login,
     @i_x_end_user_request_date_time     = @i_x_end_user_request_date_time,
     @i_x_end_user_terminal              = @i_x_end_user_terminal,
     @i_x_end_user_last_logged_date_time = @i_x_end_user_last_logged_date_time,
     @i_x_api_key                        = @i_x_api_key,
     @i_fecha_inicio                     = @w_fecha_proceso,
     @i_api_sp_name                      = @w_sp_name,
     @i_api_sp_operation                 = @i_operacion ,
     @i_status                           = 'O'*/

/* ************************************* */
/* CIERRE                                */
/* ************************************* */

CIERRE:
-- Asignar fecha de proceso
Select @o_fecha_proceso = convert(varchar(10), fp_fecha,103) --+' '+ convert(varchar(10), fp_fecha,108)
from cobis..ba_fecha_proceso

if @w_error != 0
begin
   --Creacion de Auditoria
/*   exec cobis..sp_api_auditoria
        @i_x_request_id                     = @i_x_request_id,
        @i_x_financial_id                   = @i_x_financial_id,
        @i_x_end_user_login                 = @i_x_end_user_login,
        @i_x_end_user_request_date_time     = @i_x_end_user_request_date_time,
        @i_x_end_user_terminal              = @i_x_end_user_terminal,
        @i_x_end_user_last_logged_date_time = @i_x_end_user_last_logged_date_time,
        @i_x_api_key                        = @i_x_api_key,
        @i_fecha_inicio                     = @w_fecha_proceso,
        @i_api_sp_name                      = @w_sp_name,
        @i_status                           = 'F',
        @i_api_error_code                   = @w_error,
        @i_api_sp_operation                 = @i_operacion*/

   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return @w_error
end

return 0

GO

