
/******************************************************************/
/*  Archivo:            ejereglapar.sp                            */
/*  Stored procedure:   sp_ejecutar_regla_param                   */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Geovanny Guaman                           */
/*  Fecha de escritura: 14-Ago-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Manejo de reglas                                           */
/*   - Creacion de Seguros                                        */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  14/Ago/2019        Geovanny Guaman  Creacion sp ejecuta reglas*/
/******************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_ejecutar_regla_param')
   drop proc sp_ejecutar_regla_param
go 

create proc sp_ejecutar_regla_param
   @s_ssn                  int          = null,
   @s_date                 datetime     = null,
   @s_user                 login,
   @s_ofi                  smallint     = null,
   @t_trn                  int          = 77530,
   @i_opcion               char(1)		= null,
   @i_cliente              INT			= null,
   @i_monto_seguro         money        = null,
   @i_regla                varchar(60)  = null,
   @i_variables            varchar(150) = null,
   @i_separador            char(1)		= null,
   @i_tramite              int          = null,
   @i_operacion            int          = null,
   @i_fecha_vig_ini        datetime     = null,
   @i_fecha_vig_fin        datetime     = null,
   @i_categoria            catalogo     = null,    --tipo seguro 
   @i_folio                varchar(64)  = null,
   @i_secuencial_trn       int          = null,
   @i_formato_fecha        tinyint      = 103,
   @o_return_variableR      varchar(255) = null out,
   @o_return_resultsR       varchar(255) = null out,
   @o_last_condition_parentR  int			   out  
as declare
   @w_sp_name                varchar(30),
   @w_error                  int,
   @w_fecha_vig_ini          datetime,
   @w_fecha_vig_fin          datetime,
   @w_operacion              int,
   @w_frecuencia             varchar(10),
   @w_plazo                  int,
   @w_seguro_basico          varchar(30),
   @w_variables              varchar(150),
   @w_regla                  varchar(60),
   @w_return_variable        VARCHAR(25),
   @w_return_results         VARCHAR(25),
   @w_last_condition_parent  VARCHAR(10),
   @w_precio_mensual         money,
   @w_monto_seguro           money

 
if @i_opcion = 'S' or @i_opcion = 'C' -- Ingreso de Seguros
BEGIN
				if @i_categoria IS NULL
				begin
				   select @w_variables = @i_folio    + '|'            -- Frecuencia Plazo
									   + convert(VARCHAR,@i_monto_seguro)  -- Monto Rango
						 
				end
				else
				begin
				   select @w_variables = @i_folio    + '|'    -- Frecuencia Plazo
									   + @i_categoria     + '|'    -- Tipo SEGURO
									   + convert(VARCHAR,@i_operacion) -- Plazo
						
				end
   
			-- EJECUTO LA REGLA
			exec @w_error              = cob_pac..sp_rules_param_run
			  @s_rol                   = 3,
			  @i_rule_mnemonic         = @i_regla,
			  @i_var_values            = @w_variables,
			  @i_var_separator         = '|',
			  @o_return_variable       = @o_return_variableR  OUT,
			  @o_return_results        = @o_return_resultsR   OUT,
			  @o_last_condition_parent = @o_last_condition_parentR OUT
			-- EVALUO SI HUBO ERROR
			if @w_error <> 0
			begin
			   goto ERROR
			end
		  	-- GUARDO RESULTADO
		 	select @w_precio_mensual = convert(money, isnull(replace(@w_return_results,'|',''),0))
			--REALIZO EL CALCULO DE COSTO = PRECIO MENSUAL x PLAZO
			select @w_monto_seguro = isnull((@w_precio_mensual * @w_plazo),0)
			
		if @i_opcion = 'S'  -- Consulta de monto
			begin
			 select 'VARIABLE'  	= @w_return_variable,
					'RESULT'	  	= @w_return_results,
					'CONDICION'	= @w_last_condition_parent
					
			END
		if @i_opcion = 'C'  -- Consulta de monto
			BEGIN
			 select 'VARIABLE'  	 = @w_return_variable,
					'RESULT'	  	 = @w_return_results,
					'CONDICION'		 = @w_last_condition_parent,
					'MONTO SEGURO'	 = @w_monto_seguro,
					'PRECIO MENSUAL' = @w_precio_mensual
			end
end 

return 0

ERROR:
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error
   return @w_error
GO

