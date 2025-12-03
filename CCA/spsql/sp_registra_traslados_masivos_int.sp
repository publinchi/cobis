/************************************************************************/
/*   NOMBRE LOGICO:      sp_registra_traslados_masivos_int.sp	        */
/*   NOMBRE FISICO:      sp_registra_traslados_masivos_int              */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Kevin Rodriguez                                */
/*   FECHA DE ESCRITURA: Dic. 2023                                      */
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
/*  Realizar La inserción en la tabla ca_registra_traslados_masivos     */ 
/*  de los datos seleccionados tanto para el traslado de Oficina        */
/*  como de Oficial.                                                    */
/*  Registro de estados                                                 */
/*  I = Ingresado                                                       */
/*  A = Anulado   (Si ingresa duplicados el primer registro se anula)   */
/*  P = Procesado (Se ejecuta en el poseso batch de traslados)          */
/*  E = Error     (Genero un error en el proceso batch de traslados)    */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 20/12/2023    K. Rodríguez	 R220437 Versión Inicial                */
/************************************************************************/ 

USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_registra_traslados_masivos_int')
   drop proc sp_registra_traslados_masivos_int
go

CREATE PROC sp_registra_traslados_masivos_int

(
@s_rol                  smallint		= NULL,
@s_user                 login			= NULL,
@s_term                 varchar (30)	= NULL,
@s_date                 datetime		= NULL,

@i_cliente				INT				= NULL,
@i_banco				VARCHAR(24)		= NULL,
@i_tramite				INT				= NULL,
@i_oficina				SMALLINT		= NULL,
@i_moneda               TINYINT			= NULL,
@i_fecha_ini			DATETIME		= NULL,
@i_estado				TINYINT			= NULL,
@i_migrada				VARCHAR(24)		= NULL,
@i_tipo_registro	    VARCHAR(24)		= NULL,

@i_oficial_destino      INT		    	= NULL,
@i_oficina_destino      INT  			= NULL,
@i_operacion            CHAR(1)			= NULL,
@i_existe               CHAR(1)         = 'I',
@i_tipo_grupal          char(1)         = null,
@i_ref_grupal           varchar(24)     = null
)
as

DECLARE 
@w_error		          int,
@w_sec_traslado_oficina   int,
@w_sec_traslado_oficial   int

IF @i_operacion = 'O'
BEGIN

	SELECT @w_sec_traslado_oficial = rt_secuencial_traslado 
	FROM ca_registra_traslados_masivos
	WHERE	rt_tipo_registro		= @i_tipo_registro	-- Número de operación
	AND	  	rt_estado_registro      = @i_existe         -- Estado de registro
	AND     rt_fecha_traslado       = @s_date
	AND	  	rt_tipo_traslado		= @i_operacion      
	
	--GFP Si existe ya registros de la misma operacion se anula el registro ya ingresado
	if @w_sec_traslado_oficial is not null
	BEGIN
		update ca_registra_traslados_masivos
		set rt_estado_registro = 'A'
		where rt_secuencial_traslado = @w_sec_traslado_oficial
	END
		
	INSERT INTO ca_registra_traslados_masivos(
	rt_user         ,  rt_term         ,  rt_fecha_real     ,  rt_cliente        , 	rt_banco         ,    	
	rt_tramite      ,  rt_oficina      ,  rt_moneda         ,  rt_fecha_ini      , 	rt_estado        , 	
	rt_migrada      ,  rt_tipo_registro,  rt_estado_registro,  rt_oficial_destino, 	rt_fecha_traslado, 	
	rt_tipo_traslado,  rt_rol          ,  rt_tipo_grupal    ,  rt_ref_grupal)
	VALUES(
	@s_user         ,  @s_term         ,  getdate()         ,  @i_cliente        , 	@i_banco         ,  	-- KDR 21/10/2021 Nuevos campos user,term,fecha real
	@i_tramite      ,  @i_oficina      ,  @i_moneda         ,  @i_fecha_ini      , 	@i_estado        ,		
	@i_migrada      ,  @i_tipo_registro,  @i_existe         ,  @i_oficial_destino,  @s_date          , 	
	@i_operacion    ,  @s_rol          ,  @i_tipo_grupal    ,  @i_ref_grupal)
	
	if @@error <> 0 
	begin
		select 
			@w_error = 711081 -- Error. No se puede insertar el registro de traslado oficial
		goto ERROR
	end
END

IF @i_operacion = 'F'
BEGIN

	SELECT @w_sec_traslado_oficina = rt_secuencial_traslado
	FROM ca_registra_traslados_masivos
	WHERE	rt_tipo_registro		= @i_tipo_registro	-- Número de operación
	AND	  	rt_estado_registro      = @i_existe         -- Estado de registro
	AND     rt_fecha_traslado       = @s_date
	AND	  	rt_tipo_traslado		= @i_operacion
	
	--GFP Si existe ya registros de la misma operacion se anula el registro ya ingresado
    if @w_sec_traslado_oficina is not null
	BEGIN
		update ca_registra_traslados_masivos
		set rt_estado_registro = 'A' --ANULADO
		where rt_secuencial_traslado = @w_sec_traslado_oficina
	END
	
	--Ingresa registro de Oficina
	INSERT INTO ca_registra_traslados_masivos(
	rt_user         ,  rt_term          ,  rt_fecha_real     ,  rt_cliente        ,  rt_banco         ,    	
	rt_tramite      ,  rt_oficina       ,  rt_moneda         ,  rt_fecha_ini      ,  rt_estado        , 	
	rt_migrada      ,  rt_tipo_registro ,  rt_estado_registro,  rt_oficina_destino,  rt_fecha_traslado, 	
	rt_tipo_traslado,  rt_rol           ,  rt_tipo_grupal    ,  rt_ref_grupal)
	VALUES(
	@s_user         ,  @s_term          ,  getdate()         ,  @i_cliente        ,  @i_banco         ,      -- KDR 21/10/2021 Nuevos campos user,term,fecha real	
	@i_tramite      ,  @i_oficina       ,  @i_moneda         ,  @i_fecha_ini      ,  @i_estado        ,		
	@i_migrada      ,  @i_tipo_registro ,  @i_existe         ,  @i_oficina_destino,  @s_date          ,     
	@i_operacion    ,  @s_rol           ,  @i_tipo_grupal    ,  @i_ref_grupal)
	
	if @@error <> 0 
	begin
		select @w_error = 711082 -- Error. No se puede insertar el registro de traslado oficina
		goto ERROR
	end
	
	--Registro de oficial
	SELECT @w_sec_traslado_oficial = rt_secuencial_traslado
	FROM ca_registra_traslados_masivos
	WHERE	rt_tipo_registro		= @i_tipo_registro	-- Número de operación
	AND	  	rt_estado_registro      = @i_existe         -- Estado de registro
	AND     rt_fecha_traslado       = @s_date
	AND	  	rt_tipo_traslado		= 'O'
	
	--GFP Si existe ya registros de la misma operacion se anula el registro ya ingresado
    if @w_sec_traslado_oficial is not null
	BEGIN
		update ca_registra_traslados_masivos
		set rt_estado_registro = 'A' --ANULADO
		where rt_secuencial_traslado = @w_sec_traslado_oficial
	END
	
	--Ingresa registro de oficial
	INSERT INTO ca_registra_traslados_masivos(
	rt_user         ,  rt_term         ,  rt_fecha_real     ,  rt_cliente        , 	rt_banco         ,    	
	rt_tramite      ,  rt_oficina      ,  rt_moneda         ,  rt_fecha_ini      , 	rt_estado        , 	
	rt_migrada      ,  rt_tipo_registro,  rt_estado_registro,  rt_oficial_destino,  rt_fecha_traslado, 	
	rt_tipo_traslado,  rt_rol          ,  rt_tipo_grupal    ,  rt_ref_grupal)
	VALUES(            
	@s_user         ,  @s_term         ,  getdate()         ,  @i_cliente        ,  @i_banco         ,      -- KDR 21/10/2021 Nuevos campos user,term,fecha real	
	@i_tramite      ,  @i_oficina      ,  @i_moneda         ,  @i_fecha_ini      , 	@i_estado        ,		
	@i_migrada      ,  @i_tipo_registro,  @i_existe         ,  @i_oficial_destino,  @s_date          ,     
	'O'             ,  @s_rol          ,  @i_tipo_grupal    ,  @i_ref_grupal)
	  
	if @@error <> 0 
	begin
		select @w_error = 711082 -- Error. No se puede insertar el registro de traslado oficina
		goto ERROR
	end
	
END

RETURN 0

ERROR:
return @w_error
GO

