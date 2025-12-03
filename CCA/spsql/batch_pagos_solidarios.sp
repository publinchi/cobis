/************************************************************************/
/*   Archivo:              batch_pagos_solidarios.sp                    */
/*   Stored procedure:     sp_batch_pagos_solidarios                    */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Guisela Fernandez                            */
/*   Fecha de escritura:   12/10/2021                                   */
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
/*  Identificacion de pagos solidarios por carga de archivo en proceso  */
/*  batch                                                               */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* 12/10/2021     G. Fernandez       Versión inicial                    */
/* 27/10/2021     FMP                Adición Campo Banco                */
/************************************************************************/

USE cob_cartera
GO

if exists(select 1 from sysobjects where name ='sp_batch_pagos_solidarios')
   drop proc sp_batch_pagos_solidarios
go

CREATE PROC sp_batch_pagos_solidarios
(
	@i_param1        DATETIME     = null         -- Fecha de proceso
)
as declare
	@w_sp_name             descripcion,
	@w_mensaje             descripcion,
	@w_return              int = 0,
	@w_total_registros     int,
	@w_contador            int,
	@w_numero              int,
	@w_comprobante         varchar(100),
	@w_error               INT,
	@w_sql                 varchar(255),
	@w_tipo_bcp            varchar(10), 
	@w_separador           varchar(1),
	@w_nombre_arch         varchar(255),
	@w_fecha_proceso       SMALLDATETIME,
	@w_directorio          varchar(255),
	@w_canal               varchar(10),   -- FMP 27/10/2021
	@w_banco               varchar(10)    -- FMP 27/10/2021
-- VARIABLES DE TRABAJO
SELECT @w_sp_name        = 'sp_batch_pagos_solidarios',
       @w_tipo_bcp       = 'in',
       @w_separador      = ',',
	    @w_directorio     = 'C:\cobis\Vbatch\cartera\listados' -- Directorio de ubicacion de archivos
		
-- DETERMINAR FECHA PROCESO 
select @w_fecha_proceso = fp_fecha
from   cobis..ba_fecha_proceso with (nolock)

select @w_fecha_proceso = isnull (@i_param1, @w_fecha_proceso)

--CREACION DE TABLA PARA CARGA DE DATOS
if exists (select 1 from sysobjects where name ='##ca_pagos_solidarios_tmp')
BEGIN
	DROP TABLE ##ca_pagos_solidarios_tmp
END 
    
create table ##ca_pagos_solidarios_tmp
( 
 idPago                    int            null,
 idCliente                 int            null,
 idPrestamo                cuenta         null,
 monto                     float          ,
 canal                     varchar(10)    null,  -- FMP 27/10/2021
 noComprobante             varchar(100)   null,
 banco                     varchar(10)    null,  -- FMP 27/10/2021
 error                     int            null,
 mensaje                   varchar(100)   null
)

select @w_sql = '##ca_pagos_solidarios_tmp'

-- RUTA Y NOMBRE DE ARCHIVO
select @w_nombre_arch = @w_directorio + '\gfi-pagos_solidarios-finca-' + convert(VARCHAR(24),@w_fecha_proceso,23)+ '.csv'

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

-- SE AGREGA CAMPO SECUENCIAL A LA TABLA TEMPORAL
Alter Table ##ca_pagos_solidarios_tmp Add secuencial Int Identity(1, 1)

--Obtencion de total de registros de la tabla temporal
select @w_total_registros   = count(idPrestamo) from ##ca_pagos_solidarios_tmp
select @w_error  = 0
set @w_contador  = 1

-- Ciclo para recorrer todos los registros de la tabla temporal
while @w_contador <= @w_total_registros 
begin
	select @w_numero      =  op_operacion,
	       @w_comprobante =  noComprobante,
           @w_canal       =  canal,  -- FMP 28/10/2021
           @w_banco       =  banco   -- FMP 28/10/2021
	from ##ca_pagos_solidarios_tmp, ca_operacion
	WHERE secuencial    = @w_contador
	  and idPrestamo    = op_banco
	  
   if @@rowcount = 0 
   begin
		select @w_error = 725054 --No existe la operación
		SELECT @w_mensaje = mensaje 
		FROM cobis..cl_errores 
		WHERE numero = @w_error
		
	   UPDATE ##ca_pagos_solidarios_tmp 
		set error   = @w_error,
		    mensaje = @w_mensaje
		where secuencial = @w_contador
   end
   else  -- if @@rowcount <> 0 
   begin
		-- Validacion de abonos de la operacion
		if  exists (select 1 from ca_abono_det where abd_operacion = @w_numero) and EXISTS (select 1 from ca_abono where ab_operacion = @w_numero)
		begin
			-- Validacion del campo beneficiario 
			if exists (select 1 from ca_abono_det where abd_operacion = @w_numero and abd_beneficiario = @w_comprobante)
			begin
            -- FMP 27/10/2021
				-- Validacion del campo forma de pago 
				if exists (select 1 from ca_abono_det where abd_operacion = @w_numero and abd_beneficiario = @w_comprobante and abd_concepto = @w_canal)
				begin
				   -- Validacion del campo banco 
				   if exists (select 1 from ca_abono_det where abd_operacion = @w_numero and abd_beneficiario = @w_comprobante and abd_concepto = @w_canal and abd_cod_banco = @w_banco )
				   begin
				      BEGIN TRAN
				      --Actualizacion de la tabla ca_abono_det
				      UPDATE ca_abono_det 
				      set abd_solidario = 'S'
				      where abd_operacion    = @w_numero 
				      and   abd_beneficiario = @w_comprobante
                      and   abd_concepto     = @w_canal  -- FMP 27/10/2021
                      and   abd_cod_banco    = @w_banco  -- FMP 27/10/2021
				
				      IF @@ERROR <> 0 OR @@ROWCOUNT = 0
				      BEGIN 
				         ROLLBACK
					
					      select @w_error = 705047 --Error en actualizacion ABONO DETALLE
					      SELECT @w_mensaje = mensaje 
					      FROM cobis..cl_errores 
					      WHERE numero = @w_error
					
					      UPDATE ##ca_pagos_solidarios_tmp 
					      set error   = @w_error,
		                   mensaje = @w_mensaje
					      where secuencial = @w_contador
				      END
				      else
                      begin				
					      COMMIT TRAN
					      UPDATE ##ca_pagos_solidarios_tmp 
					      set error   = 0,
					         mensaje = 'PROCESADO OK'
					      where secuencial = @w_contador
				      end
			      end  -- Validacion del campo banco 
			      else
			      BEGIN 
			        select @w_error = 711112 --'No coincide el código de banco'
		            SELECT @w_mensaje = mensaje 
		            FROM cobis..cl_errores 
		            WHERE numero = @w_error

				    UPDATE ##ca_pagos_solidarios_tmp 
				    set error   = @w_error,
		                mensaje = @w_mensaje
				    where secuencial = @w_contador
			      END


			   end  -- Validacion del campo forma de pago 
			   else
			   BEGIN 
			     select @w_error = 711111 --'No coincide la forma de pago'
		         SELECT @w_mensaje = mensaje 
		         FROM cobis..cl_errores 
		         WHERE numero = @w_error

				 UPDATE ##ca_pagos_solidarios_tmp 
				 set error   = @w_error,
		             mensaje = @w_mensaje
				 where secuencial = @w_contador
			   END
			end  -- Validacion del campo beneficiario
			else
			BEGIN 
			    select @w_error = 711109 --'No coincide el número de comprobante'
		        SELECT @w_mensaje = mensaje 
		        FROM cobis..cl_errores 
		        WHERE numero = @w_error

				UPDATE ##ca_pagos_solidarios_tmp 
				set error   = @w_error,
		            mensaje = @w_mensaje
				where secuencial = @w_contador
			END
		end -- Validacion de abonos de la operacion
		else
		begin
			select @w_error = 711110 --No existen detalles de abonos de la operación
		    SELECT @w_mensaje = mensaje 
		    FROM cobis..cl_errores 
		    WHERE numero = @w_error
			
			UPDATE ##ca_pagos_solidarios_tmp 
			set error   = @w_error,
		       mensaje = @w_mensaje
			where secuencial = @w_contador
		end
   end -- if @@rowcount <> 0  

   select @w_numero =0	
   set @w_contador = @w_contador+1
END  -- while @w_contador <= @w_total_registros 

ALTER TABLE ##ca_pagos_solidarios_tmp DROP COLUMN secuencial;

--Ingreso de datos al archivo de Salida
select  @w_sql          = '##ca_pagos_solidarios_tmp',
		@w_tipo_bcp     = 'out',
		@w_nombre_arch  = @w_directorio + '\gfi-pagos_solidarios-out-finca-' + convert(VARCHAR(24),@w_fecha_proceso,23)+ '.csv'

exec @w_return          = cobis..sp_bcp_archivos
	@i_sql              = @w_sql,           --select o nombre de tabla para generar archivo plano
	@i_tipo_bcp         = @w_tipo_bcp,      --tipo de bcp in,out,queryout
	@i_rut_nom_arch     = @w_nombre_arch,   --ruta y nombre de archivo
	@i_separador        = @w_separador   --separador

if @w_return != 0
BEGIN
select @w_mensaje = 'Error al llenar tabla temp bcp cobis..sp_bcp_archivos'
select @w_error   = 711106
GOTO ERROR
END	

DROP TABLE ##ca_pagos_solidarios_tmp

return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error 

DROP TABLE ##ca_pagos_solidarios_tmp

return @w_error
GO

