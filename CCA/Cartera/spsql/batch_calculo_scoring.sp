/************************************************************************/
/*   Archivo:              batch_calculo_scoring.sp                     */
/*   Stored procedure:     sp_batch_calculo_scoring                     */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Guisela Fernandez                            */
/*   Fecha de escritura:   18/08/2021                                   */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Almacenamiento en el maestro de operaciones de Cartera del cálculo  */
/*  interno de scoring  */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* 18/08/2021     G. Fernandez       Versión inicial                    */
/* 28/07/2022     G. Fernandez       Se actualiza mensajes para log y   */
/*                                   se elimina registro de cabecera   */
/************************************************************************/

USE cob_cartera
GO

if exists(select 1 from sysobjects where name ='sp_batch_calculo_scoring')
   drop proc sp_batch_calculo_scoring

go

CREATE PROC sp_batch_calculo_scoring
(
	@i_param1        DATETIME     = null ,                    -- Fecha de proceso
	@i_param2        varchar(255) = 'C:\cobis\Vbatch\cartera\listados' -- Directorio de ubicacion de archivos
)
as declare
	@w_sp_name           descripcion,
	@w_mensaje           descripcion,
	@w_return            int = 0,
	@w_count             int,
	@w_countb            int,
	@w_tipo              char(1),
	@w_numero            cuenta,
	@w_scoring           varchar(24),
	@w_error             INT,
	@w_sql               varchar(255),
	@w_tipo_bcp          varchar(10), 
	@w_separador         varchar(1),
	@w_nombre_arch       varchar(255),
	@w_banco			 cuenta,
	@w_operacion		 INT,
	@w_fecha_proceso     SMALLDATETIME,
	@w_num_oper_act      INT = 0,
	@w_scoring_int       INT,
	@w_cust_no           varchar(100)
	

-- VARIABLES DE TRABAJO
SELECT @w_sp_name        = 'sp_batch_calculo_scoring',
       @w_tipo_bcp       = 'in',
       @w_separador      = ','
		
-- DETERMINAR FECHA PROCESO 
select @w_fecha_proceso = fp_fecha
from   cobis..ba_fecha_proceso with (nolock)

select @w_fecha_proceso = isnull (@i_param1, @w_fecha_proceso)

--CREACION DE TABLA PARA CARGA DE DATOS
if exists (select 1 from sysobjects where name ='##ca_scoring_tmp')
BEGIN
	DROP TABLE ##ca_scoring_tmp
END 
    
create table ##ca_scoring_tmp
( 
 cust_no                    varchar(100)       null,
 bu_nm                      varchar(100)       null,
 acct_nm                    varchar(100)       null,
 gender                     varchar(100)       null,
 contact_no_1               varchar(100)       null,
 contact_no_2               varchar(100)       null,
 contact_no_3               varchar(100)       null,
 sector                     varchar(100)       null,
 product                    varchar(100)       null,
 prod_descript              varchar(100)       null,
 type_loan                  varchar(100)       null,
 group_id                   varchar(100)       null,
 loan_cycle                 varchar(100)       null,
 acct_no                    cuenta             null, -- número de prestamo
 term                       varchar(100)       null,
 disbursement_limit         varchar(100)       null,
 due_days                   varchar(100)       null,
 due_days_permonth          varchar(100)       null,
 month                      varchar(100)       null,
 total_payment              varchar(100)       null,
 cleared_bal                varchar(100)       null,
 mts                        varchar(100)       null,
 mss                        varchar(100)       null,
 loan_segment               varchar(100)       null,
 cust_segment               varchar(100)       null,
 restructured               varchar(100)       null,
 disb_dt                    varchar(100)       null,
 dob_dt                     varchar(100)       null,
 mat_dt                     varchar(100)       null,
 mnth_since_loan_open       varchar(100)       null,
 mnth_to_maturity           varchar(100)       null,
 age                        varchar(100)       null,
 loan_type                  varchar(100)       null,
 term_month                 varchar(100)       null,
 risk_category              varchar(100)       null,
 beh_score                  varchar(24)        null, -- valor de scoring
 recommended_loan           varchar(100)       null,
 recommended_term           varchar(100)       null,
 status                     varchar(100)       null,
 system_decision            varchar(100)       null
)

select @w_sql = '##ca_scoring_tmp'

-- CREACION DE TABLA PARA LOGS DE SALIDA
if exists (select 1 from sysobjects where name ='##ca_errores_scoring')
BEGIN
	DROP TABLE ##ca_errores_scoring
END 
    
create table ##ca_errores_scoring
( 
 es_secuencial        INT		  	IDENTITY(1,1) NOT NULL,      
 es_descripcion       VARCHAR(200)   null
)

-- RUTA Y NOMBRE DE ARCHIVO
select @w_nombre_arch = @i_param2 + 'gfi-scoring-finca-' + convert(VARCHAR(24),@w_fecha_proceso,23)+ '.csv'
print '@w_nombre_arch ' + @w_nombre_arch

--Llamada a proceso de lectura de archivo para llenar tabla
exec @w_return          = cobis..sp_bcp_archivos
     @i_sql             = @w_sql,           --select o nombre de tabla para generar archivo plano
     @i_tipo_bcp        = @w_tipo_bcp,      --tipo de bcp in,out,queryout
     @i_rut_nom_arch    = @w_nombre_arch,   --ruta y nombre de archivo
     @i_separador       = @w_separador   --separador
     --@i_nom_servidor   = @w_nom_servidor --nombre de servidor donde se procesa bcp

if @w_return != 0
BEGIN
  PRINT 'Error al llenar tabla temp bcp cobis..sp_bcp_archivos'
  select @w_error   = 711106
  goto ERROR
END

--Eliminación de registro de encabezado
if exists (select 1 from ##ca_scoring_tmp where UPPER(cust_no) = 'CUST_NO' )
BEGIN
   delete ##ca_scoring_tmp
   where UPPER(cust_no) = 'CUST_NO'
end

-- SE AGREGA CAMPO SECUENCIAL A LA TABLA TEMPORAL
Alter Table ##ca_scoring_tmp Add st_secuencial Int Identity(1, 1)

--Obtencion de total de registros de la tabla temporal
select @w_count  = count(acct_no) from ##ca_scoring_tmp
select @w_error  = 0
set @w_countb = 1
print '@w_count ' + convert(Varchar(24),@w_count)
-- Ciclo para recorrer todos los registros de la tabla temporal
while @w_countb <= @w_count
begin
	select @w_numero  =  acct_no,
	       @w_scoring =  beh_score,
		   @w_cust_no =  cust_no
	from ##ca_scoring_tmp
	WHERE st_secuencial = @w_countb
	
	
	-- Validación del número de la operación
	if not exists (select 1 from ca_operacion where op_banco = @w_numero)
	begin
		INSERT INTO ##ca_errores_scoring (es_descripcion) 
		VALUES ('En la fila ' + convert(VARCHAR(24), @w_countb +1) + '. Error en validación de número de la operación ' + convert(varchar(24),@w_numero) + 
		        ', ACCT_NO: ' + convert(varchar(24),@w_cust_no))
    	select @w_error   = 1
	end
	
	-- Validación del campo scoring, se valida que solo sean números
	IF (ISNUMERIC(@w_scoring) = 0)
	BEGIN 
		INSERT INTO ##ca_errores_scoring (es_descripcion) 
		VALUES ('En la fila ' + convert(VARCHAR(24), @w_countb +1) + '. Error en validación del valor de scoring ' +  convert(varchar(24),@w_scoring) + 
		        ' en la operación ' + convert(varchar(24),@w_numero) + ', ACCT_NO: ' + convert(varchar(24),@w_cust_no))
    	select @w_error   = 1
	END
	ELSE
	IF (convert(int,rtrim(ltrim(@w_scoring))) < 0)
	BEGIN 
		INSERT INTO ##ca_errores_scoring (es_descripcion) 
		VALUES ('En la fila ' + convert(VARCHAR(24), @w_countb) + '. Error en validación del valor de scoring ' +  convert(varchar(24),@w_scoring) + 
		        ' en la operación ' + convert(varchar(24),@w_numero) + ', ACCT_NO: ' + convert(varchar(24),@w_cust_no))
    	select @w_error   = 1
	END	
set @w_countb = @w_countb+1
END

IF (@w_error != 0)
BEGIN 
 	GOTO LOG_SALIDA
END

-- PROCESO DE ALMACENAMIENTO
select @w_error        = 0,
       @w_countb       = 1,
	   @w_num_oper_act = 0
       
select @w_count  = count(acct_no) from ##ca_scoring_tmp

while @w_countb <= @w_count
BEGIN

	BEGIN TRAN
	SELECT @w_banco   = acct_no,
	       @w_scoring_int = convert(int,rtrim(ltrim(beh_score)))
	FROM   ##ca_scoring_tmp
	WHERE  st_secuencial = @w_countb
	
	SELECT @w_operacion = op_operacion 
	FROM   ca_operacion 
	WHERE  op_banco = @w_banco
		
	-- LLamada a la transaccion de servicio para valores iniciales
	exec @w_error = sp_tran_servicio
     @s_user    = 'admuser',
     @s_date    = @w_fecha_proceso,
     @s_ofi     = 1,
     @s_term    = 'TERMX',
     @i_tabla   = 'ca_operacion',
     @i_clave1  = @w_operacion
    
    IF @w_error <> 0
    BEGIN
    	select @w_error = 710047 --Error en insercion de transaccion de servicio para la operacion
    	GOTO ERROR_ACTUALIZACION
    END
    
	-- Actualizacion de scoring en tabla ca_operacion
	UPDATE ca_operacion
	SET op_dias_clausula  = @w_scoring_int
	WHERE op_banco = @w_banco
	
	IF @@ERROR <> 0 OR @@ROWCOUNT = 0
    BEGIN 
       	select @w_error = 705076 -- Error al actualizar informacion de ca_operacion
       	GOTO ERROR_ACTUALIZACION
    END
       
	-- LLamada a la transaccion de servicio para nuevos valores
	exec @w_error = sp_tran_servicio
     @s_user    = 'admuser',
     @s_date    = @w_fecha_proceso,
     @s_ofi     = 1,
     @s_term    = 'TERMX',
     @i_tabla   = 'ca_operacion',
     @i_clave1  = @w_operacion

    IF @w_error <> 0
    BEGIN
    	select @w_error = 710047 --Error en insercion de transaccion de servicio para la operacion
    	GOTO ERROR_ACTUALIZACION
    END
    
    --Contador de operaciones actualizadas
    SELECT @w_num_oper_act = @w_num_oper_act +1
    
    COMMIT TRAN
    
	ERROR_ACTUALIZACION:
	BEGIN
		IF (@w_error <> 0)
		BEGIN
		  ROLLBACK
		  PRINT 'Error de actualizacion de registros'
		  SELECT @w_mensaje = mensaje FROM cobis..cl_errores 
		                              WHERE numero = @w_error
		  INSERT INTO ##ca_errores_scoring (es_descripcion) 
		  VALUES ('En la fila ' + convert(VARCHAR(24),@w_countb) + '. La operación '+ @w_banco + ' con scoring '+ convert(VARCHAR(24),@w_scoring_int) +' no pudo ser actualizada. Error: ' + convert(VARCHAR(24),@w_error)+ ' '+ @w_mensaje)
		END
	END

	SELECT @w_banco         = null
	SELECT @w_scoring_int   = 0
	SELECT @w_operacion     = 0
	SELECT @w_error         = 0
	SELECT @w_countb        = @w_countb+1
END

IF (@w_count <> @w_num_oper_act)
BEGIN
    INSERT INTO ##ca_errores_scoring (es_descripcion) VALUES ('La actualización de operaciones no cuadra con la cantidad de registros del archivo ')
    GOTO LOG_SALIDA
END
ELSE 
BEGIN

	INSERT INTO ##ca_errores_scoring (es_descripcion) VALUES ('Actualización exitosa!')
	GOTO LOG_SALIDA
END

LOG_SALIDA:
BEGIN

	select  @w_sql          = '##ca_errores_scoring',
			@w_tipo_bcp     = 'out',
			@w_nombre_arch  = @i_param2 + 'log-gfi-scoring-finca-' + convert(VARCHAR(24),@w_fecha_proceso,23)+ '.csv'
	
	exec @w_return          = cobis..sp_bcp_archivos
		@i_sql              = @w_sql,           --select o nombre de tabla para generar archivo plano
		@i_tipo_bcp         = @w_tipo_bcp,      --tipo de bcp in,out,queryout
		@i_rut_nom_arch     = @w_nombre_arch,   --ruta y nombre de archivo
		@i_separador        = @w_separador   --separador
		--@i_nom_servidor = @w_nom_servidor --nombre de servidor donde se procesa bcp

	if @w_return != 0
	BEGIN
	select @w_mensaje = 'Error al llenar tabla temp bcp cobis..sp_bcp_archivos'
	select @w_error   = 711106
	GOTO ERROR
	END
	
	
END

DROP TABLE ##ca_scoring_tmp
DROP TABLE ##ca_errores_scoring

return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error 

DROP TABLE ##ca_scoring_tmp
DROP TABLE ##ca_errores_scoring

return @w_error
GO
