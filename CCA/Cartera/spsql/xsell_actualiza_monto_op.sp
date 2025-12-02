/******************************************************************************/
/*   NOMBRE LOGICO:      xsell_actualiza_monto_op.sp                          */
/*   NOMBRE FISICO:      sp_xsell_actualiza_monto_op                          */
/*   BASE DE DATOS:      cob_cartera                                          */
/*   PRODUCTO:           Cartera                                              */
/*   DISENADO POR:       Juan Carlos Miranda                                  */
/*   FECHA DE ESCRITURA: Oct. 2021                                            */
/******************************************************************************/
/*                     IMPORTANTE                                             */
/*   Este programa es parte de los paquetes bancarios que son                 */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,            */
/*   representantes exclusivos para comercializar los productos y             */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida           */
/*   y regida por las Leyes de la República de España y las                   */
/*   correspondientes de la Unión Europea. Su copia, reproducción,            */
/*   alteración en cualquier sentido, ingeniería reversa,                     */
/*   almacenamiento o cualquier uso no autorizado por cualquiera              */
/*   de los usuarios o personas que hayan accedido al presente                */
/*   sitio, queda expresamente prohibido; sin el debido                       */
/*   consentimiento por escrito, de parte de los representantes de            */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto            */
/*   en el presente texto, causará violaciones relacionadas con la            */
/*   propiedad intelectual y la confidencialidad de la información            */
/*   tratada; y por lo tanto, derivará en acciones legales civiles            */
/*   y penales en contra del infractor según corresponda.                     */
/******************************************************************************/
/*                              PROPOSITO                                     */
/* Realizar un programa que permita recalcular el monto de rubros tipo        */
/* porcentaje y calculado                                                     */
/******************************************************************************/
/*                              MODIFICACIONES                                */
/*  FECHA       VERSION        AUTOR                 RAZON                    */
/*  12/10/2021          Juan Carlos Miranda   Version Inicial                 */
/*  10/03/2022          Kevin Rodriguez       Ajuste recalcular cuota e in-   */
/*                                            serción de manejo de rubs valor */
/*  18/10/2023          Kevin Rodiguez        R217473 Bandera para no recalc. */
/*                                            valor rubros Q i_recalc_rubs_enl*/
/*  25/10/2023          Kevin Rodiguez        R214406 Recalculo tasa INT      */
/*  14/02/2024          Kevin Rodiguez        R223955 Mantener fecha pri cuota*/
/******************************************************************************/

use cob_cartera
go
IF OBJECT_ID ('sp_xsell_actualiza_monto_op') IS NOT NULL
        drop proc sp_xsell_actualiza_monto_op
go
create proc sp_xsell_actualiza_monto_op
        @t_show_version     bit         = 0,    -- show the version of the stored procedure  
        @i_banco            VARCHAR(24), 
        @s_user             login,
        @s_term             varchar(30) = null,
        @s_ofi              smallint,  
        @s_date             datetime     = null,
        @i_monto_nuevo      money  = null,
        --@i_sector           catalogo     = null,
		@i_destino          catalogo     = null,
		@i_grupal           char(1)      = null,   -- KDR Para operaciones grupales.
		@i_tasa             float        = null,   -- KDR Actualización de tasa de préstamo
		@i_pasar_a_def		CHAR(1)		 = 'S',    -- AMP para cuando sea llamado XSELL
		@i_recalcular_rub   char(1)      = 'N',    -- KDR Bandera para recalcular valor de un Rubro Calculado
		@i_pasa_a_temporales	CHAR(1)  = 'S',
        @o_monto_calculado  money out
as
declare 
	    @w_return            int,
	 	@w_fecha_proceso     datetime,
		@w_banco             varchar(30),
		@w_operacionca       int,
		@w_n_rubros          int,
		@w_contador          int,
		@w_concepto          varchar(10),
		@w_financiado        CHAR (1),
		@w_monto             money,
		@w_monto_nuevo       money,
		@w_oficina           int,
		@w_n_rubros_eli      INT,
		@w_calcula_monto     CHAR(1),
		@w_calcula_destino   CHAR(1),
		@w_destino           catalogo,
        @w_grupo             int,
        @w_porcentaje        float,
		@w_valor			 money,
		@w_concepto_int      catalogo,
		@w_porcentaje_int    float,
		@w_factor_int        float,
		@w_signo_int         char(1),
		@w_referencial_int   catalogo,
		@w_valor_int         money,
		@w_val_ref_pizarra   float,
        @w_fecha_pri_cuota   datetime		
		
		if @t_show_version = 1
		begin
		   print 'Stored procedure sp_xsell_actualiza_monto_operacion, Version 4.0.0.0'
		   return 0
		end
		
		CREATE TABLE #rubros_eliminar
		(
		 id_num     int IDENTITY(1,1), 
		 concepto   varchar(10)
		)  
		
		CREATE TABLE #rubros_actualizar
		(
		 id_num     int IDENTITY(1,1), 
		 concepto   varchar(10),
		 financiado CHAR (1),
		 porcentaje float,
		 valor		money
		)		
		
		CREATE TABLE #ca_respaldo_rubros_ts
		(
		 rr_operacion            INT NOT NULL,
		 rr_user                 login,
	     rr_term                 varchar(30),
	     rr_ofi                  smallint,  
	     rr_date                 datetime,
		 rr_concepto             catalogo NOT NULL,
		 rr_tipo_rubro           CHAR (1) NOT NULL,
		 rr_fpago                CHAR (1) NOT NULL,
		 rr_prioridad            TINYINT NOT NULL,
		 rr_paga_mora            CHAR (1) NOT NULL,
		 rr_provisiona           CHAR (1) NOT NULL,
		 rr_signo                CHAR (1),
		 rr_factor               FLOAT,
	   	 rr_referencial          catalogo,
		 rr_valor                MONEY NOT NULL,
		 rr_porcentaje           FLOAT NOT NULL,
		 rr_signo_reajuste       CHAR (1),
		 rr_factor_reajuste      FLOAT,
		 rr_referencial_reajuste catalogo,
		 rr_base_calculo         MONEY,
		 rr_num_dec              TINYINT,
		 rr_financiado           CHAR (1),
		 rr_monto                money,
		 rr_monto_aprobado       money
		)
					
		
        select @w_operacionca = op_operacion,
               @w_oficina     = op_oficina,
               @w_monto       = op_monto,
               @w_destino     = op_destino,
               @w_grupo       = op_grupo
        FROM ca_operacion 
		WHERE op_banco =  @i_banco
        and op_estado  in (99)
        
        if @@rowcount = 0
        begin
           return 711101 -- El código de banco ingresado no existe
        end
			        
		--Se obtiene respaldo previo eliminacion
	    INSERT INTO #ca_respaldo_rubros_ts
		(rr_operacion, rr_concepto, rr_tipo_rubro, rr_fpago, rr_prioridad, 
		 rr_paga_mora, rr_provisiona, rr_signo, rr_factor, rr_referencial, rr_valor, rr_porcentaje,rr_signo_reajuste,
		 rr_factor_reajuste, rr_referencial_reajuste, rr_base_calculo, rr_num_dec, rr_financiado, rr_monto, rr_monto_aprobado)
		SELECT
		 ro_operacion, ro_concepto, ro_tipo_rubro, ro_fpago,  ro_prioridad, 
		 ro_paga_mora, ro_provisiona, ro_signo, ro_factor, ro_referencial, ro_valor,  ro_porcentaje, ro_signo_reajuste, 
		 ro_factor_reajuste, ro_referencial_reajuste, ro_base_calculo, ro_num_dec, ro_financiado,  op_monto, op_monto_aprobado  
		 FROM ca_rubro_op, ca_operacion
		 WHERE ro_operacion = op_operacion
		 AND op_operacion =  @w_operacionca 
		 and ro_tipo_rubro IN ('O','Q','V')
	 
	    IF @i_pasa_a_temporales = 'S'
	    begin 
           --creacion de temporales
           exec  @w_return     = sp_pasotmp
           @s_user            = @s_user,
           @s_term            = @s_term,
           @i_banco           = @i_banco,
           @i_operacionca     = 'S',
           @i_dividendo       = 'S',
           @i_amortizacion    = 'S',
           @i_cuota_adicional = 'S',
           @i_rubro_op        = 'S',
           @i_relacion_ptmo   = 'S',
           @i_nomina          = 'S',
           @i_acciones        = 'S',
           @i_valores         = 'S'
           
           if @w_return <> 0 
             return @w_return
		end

        -- Negociación del préstamos de tmp
        select @w_fecha_pri_cuota = opt_fecha_pri_cuot
		from ca_operacion_tmp 
		where opt_banco =  @i_banco
		and opt_estado  in (99)
		
		if @@rowcount = 0
		begin
		   return 711101 -- El código de banco ingresado no existe
		end
			 	 

		 if ((@i_monto_nuevo is not null and (@i_monto_nuevo <> @w_monto or @i_recalcular_rub = 'S')) 
		     or (@i_destino IS NOT null) 
			 or (@i_tasa is not null))
		 begin	      
		    
		     if (@i_monto_nuevo is null)
		     begin
		        select  @i_monto_nuevo = @w_monto
		     end
		
		     if (@i_destino IS null)
		     begin
		        select  @i_destino = @w_destino
		     end
			 
			 if (@i_tasa is not null and @i_tasa > 0)
			 begin
			 
			    select @w_concepto_int    = rot_concepto,
				       @w_porcentaje_int  = rot_porcentaje,
				       @w_factor_int      = rot_factor,
					   @w_signo_int       = rot_signo,
					   @w_referencial_int = rot_referencial,
					   @w_valor_int       = rot_valor
			    from ca_rubro_op_tmp
                where rot_operacion = @w_operacionca
				and  rot_tipo_rubro = 'I'
				
				-- Se obtiene el valor de la tasa referencial (pizarra) a partir del valor actual de la tasa de Interés
				if @w_signo_int = '+'
				begin
				   select @w_val_ref_pizarra = @w_porcentaje_int - @w_factor_int
				   select @w_factor_int = @i_tasa - @w_val_ref_pizarra
				end 
				
                if @w_signo_int = '-'
			    begin
				   select @w_val_ref_pizarra = @w_porcentaje_int + @w_factor_int
				   select @w_factor_int = @i_tasa + @w_val_ref_pizarra
				end 
				
				if @w_signo_int = '*'
			    begin
				   select @w_val_ref_pizarra = @w_porcentaje_int / @w_factor_int
				   select @w_factor_int = @i_tasa / @w_val_ref_pizarra
				end 
				
                if @w_signo_int = '/'
			    begin
				   select @w_val_ref_pizarra = @w_porcentaje_int * @w_factor_int
				   select @w_factor_int = @i_tasa * @w_val_ref_pizarra
				end 

				exec @w_return = sp_rubro_tmp 
                @s_user        = @s_user,
                @s_term        = @s_term,
                @s_date        = @s_date,
                @s_ofi         = @s_ofi,
                @i_operacion   = 'U',
                @i_operacionca = @w_operacionca,
                @i_concepto    = @w_concepto_int,
                @i_tipo_rubro  = 'I',
                @i_signo       = @w_signo_int,
                @i_factor      = @w_factor_int,
                @i_referencial = @w_referencial_int,
                @i_valor       = @w_valor_int,
                @i_porcentaje  = @i_tasa
				
				if @w_return <> 0 
				   return @w_return

			 end
		    
			 if exists(select 1 from ca_rubro_op where ro_operacion = @w_operacionca and ro_tipo_rubro IN ('O','Q','V'))
			 begin
			  
			  		 select @w_contador = 1
			  		        
					 select @w_n_rubros_eli = count(rr_concepto) from #ca_respaldo_rubros_ts where rr_operacion = @w_operacionca 
					 and rr_tipo_rubro IN ('O','Q','V') 
					 	  
					 INSERT INTO #rubros_eliminar
					 select rr_concepto
					 from #ca_respaldo_rubros_ts where rr_operacion = @w_operacionca 
					 and rr_tipo_rubro IN ('O','Q','V')
					 AND rr_financiado = 'S'
					 ORDER BY rr_concepto
					 
					 select TOP 1 @w_concepto = concepto
					 from  #rubros_eliminar
					 order by id_num  
					 
					 while @w_contador <= @w_n_rubros_eli
					 begin 
														  		   
					    --Se eliminar rubros
					    exec @w_return = sp_rubro_tmp
						@s_user = @s_user,
						@s_term = @s_term,
						@s_date = @s_date,
						@s_ofi =  @s_ofi,
						@i_banco  = @i_banco,
						@i_concepto = @w_concepto,
						@i_operacion = 'D'
						if @w_return <> 0 return @w_return
						
						if  @w_contador = @w_n_rubros_eli
					    break
							
					    select @w_contador = @w_contador + 1
					    		    
					    select @w_concepto = concepto
					    from  #rubros_eliminar
					    where id_num = @w_contador
					
					 end 
					 
					 -- KDR Se obtiene nuevo monto despues de eliminar rubros calculados
					 IF (@i_monto_nuevo = @w_monto) AND @i_recalcular_rub = 'S'
					 begin
					    SELECT @i_monto_nuevo = opt_monto FROM ca_operacion_tmp WHERE opt_banco = @i_banco 
					 end

			 end
				 
			    --Modificacion de operacion original
				exec @w_return = sp_modificar_operacion
				@s_user              = @s_user,
				@s_date              = @s_date,
				@s_ofi               = @s_ofi,
				@s_term              = @s_term,
				@i_calcular_tabla    = 'S', 
				@i_tabla_nueva       = 'S',
				@i_operacionca       = @w_operacionca,
				@i_banco             = @i_banco,
				@i_monto             = @i_monto_nuevo, 
			    @i_monto_aprobado    = @i_monto_nuevo,
			    @i_cuota             = 0,                 -- KDR Para recalcular cuota según nuevo monto
	            --@i_sector            = @i_sector,
				@i_destino           = @i_destino,
				@i_grupal            = @i_grupal,
				@i_tasa              = @i_tasa,
				@i_grupo             = @w_grupo,
				@i_fecha_pri_cuot    = @w_fecha_pri_cuota,
				@i_recalc_rubs_enl   = 'N'                -- KDR El recalculo de rubros ya se estan realizando en este programa.
				
				if @w_return != 0 
				  return @w_return

	         if exists(select 1 from #ca_respaldo_rubros_ts where rr_operacion = @w_operacionca and rr_tipo_rubro IN ('O','Q','V'))
			 begin
					  
					select @w_contador = 1
	       
					select @w_n_rubros = count(rr_concepto) from #ca_respaldo_rubros_ts where rr_operacion = @w_operacionca 
					and rr_tipo_rubro IN ('O','Q','V')
						  
					INSERT INTO #rubros_actualizar
					select rr_concepto,
						   rr_financiado,
                           rr_porcentaje,
						   rr_valor
					from #ca_respaldo_rubros_ts where rr_operacion = @w_operacionca 
					and rr_tipo_rubro IN ('O','Q','V')
					order by rr_concepto
					
					select @w_porcentaje = 0,
					       @w_valor = 0
	     
	                select TOP 1 @w_concepto = concepto,
					             @w_financiado = financiado,
                                 @w_porcentaje = porcentaje,
								 @w_valor = valor
					from  #rubros_actualizar
					order by id_num 
					
				    while @w_contador <= @w_n_rubros 
					begin 
														  		      
						 --Creacion de rubros
						EXEC @w_return = sp_rubro_tmp
						@s_user = @s_user,
						@s_term = @s_term,
						@s_ofi =  @w_oficina,
						@s_date = @s_date,
						@i_banco  = @i_banco,
						@i_operacion = 'I',
						@i_porcentaje = @w_porcentaje,
						@i_valor      = @w_valor,
						@i_concepto = @w_concepto
						
						if @w_return <> 0 
						  return @w_return
						  
						exec @w_return = sp_modificar_operacion
						@s_user              = @s_user,
						@s_date              = @s_date,
						@s_ofi               = @s_ofi,
						@s_term              = @s_term,
						@i_calcular_tabla    = 'S', 
						@i_tabla_nueva       = 'S',
						@i_regenera_rubro    = 'N',
						@i_cuota             = 0,                 -- KDR Para recalcular cuota según nuevo monto
					    @i_operacionca       = @w_operacionca,
					    @i_banco             = @i_banco,
						@i_grupo             = @w_grupo ,
						@i_grupal            = @i_grupal,
						@i_tasa              = @i_tasa,
						@i_fecha_pri_cuot    = @w_fecha_pri_cuota,
						@i_recalc_rubs_enl   = 'N'                -- KDR El recalculo de rubros ya se estan realizando en este programa.
					    
						if @w_return != 0 
						  return @w_return
					   	    		  
			                 
						if @w_financiado = 'S'
					    begin
							select @w_monto_nuevo = opt_monto from ca_operacion_tmp where opt_operacion = @w_operacionca     	
						end
							
						if  @w_contador = @w_n_rubros
						break
								
						select @w_contador = @w_contador + 1
						
						select @w_porcentaje = 0,
					           @w_valor = 0
							   
						select @w_concepto = concepto,
						       @w_financiado = financiado,
							   @w_porcentaje = porcentaje,
							   @w_valor = valor
						from  #rubros_actualizar
						where id_num = @w_contador
					
					end
			 end	
			  
		 end   
  		 		 
		 select @o_monto_calculado = isnull(@w_monto_nuevo,0)
	
	
	     IF @i_pasar_a_def = 'S'
	       BEGIN     
	         exec @w_return = sp_pasodef
                  @i_banco        = @i_banco,
                  @i_operacionca  = 'S',
                  @i_dividendo    = 'S',
                  @i_amortizacion = 'S',
                  @i_cuota_adicional = 'S',
                  @i_rubro_op     = 'S',
                  @i_relacion_ptmo = 'S',
                  @i_nomina       = 'S',
                  @i_acciones     = 'S',
                  @i_valores      = 'S'       
                  
             if @w_return != 0 
               return @w_return

             exec @w_return = sp_borrar_tmp
                  @s_user       = @s_user,
                  --@s_sesn     = @s_sesn,
                  @s_term       = @s_term,
                  @i_desde_cre  = 'N',
                  @i_banco      = @i_banco
                  
             if @w_return != 0 
               return @w_return
           END        

return 0
go

        
  