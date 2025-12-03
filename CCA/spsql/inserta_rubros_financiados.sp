/******************************************************************************/
/*      Archivo:                inserta_rubros_financiados.sp                 */
/*      Stored procedure:       sp_inserta_rubros_financiados                 */
/*      Base de datos:          cob_cartera                                   */
/*      Producto:               Cartera                                       */
/*      Disenado por:           Guisela Fernandez                             */
/*      Fecha de escritura:     Feb. 2022                                     */
/******************************************************************************/
/* IMPORTANTE                                                                 */
/* Este programa es parte de los paquetes bancarios propiedad de              */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la              */
/* AT&T                                                                       */
/* Su uso no autorizado queda expresamente prohibido asi como                 */
/* cualquier autorizacion o agregado hecho por alguno de sus                  */
/* usuario sin el debido consentimiento por escrito de la                     */
/* Presidencia Ejecutiva de COBISCORP o su representante                      */
/******************************************************************************/
/*                              PROPOSITO                                     */
/* Programa que permita ingresar los rubros financiados en la creación        */
/* inicial de la operación                                                    */
/******************************************************************************/
/*                              MODIFICACIONES                                */
/*  FECHA               AUTOR                 RAZON                           */
/*  18/02/2022       Guisela Fernandez      Version Inicial                   */
/*  08/03/2022       Alfredo Monroy         Cálculo valor en rubros Porcentaje*/
/*                                          y valor fijo                      */
/*  22/03/2022       Kevin Rodríguez        Inclusión parámetro grupo         */
/*  30/05/2022       Guisela Fernandez      Validación para rubros vigentes   */
/******************************************************************************/

use cob_cartera
go
IF OBJECT_ID ('sp_inserta_rubros_financiados') IS NOT NULL
        drop proc sp_inserta_rubros_financiados
go
create proc sp_inserta_rubros_financiados
        @t_show_version     bit         = 0,    -- show the version of the stored procedure  
        @s_user             login,
        @s_term             varchar(30) = null,
        @s_ofi              smallint,  
        @s_date             datetime     = null,
		@i_operacionca      int,
        @i_toperacion       catalogo     = null,
        @i_moneda           tinyint      = null,
        @i_banco            cuenta,
        @i_grupo            int      		

as
declare 
	    @w_return            int,
		@w_n_rubros          int,
		@w_contador          int,
		@w_concepto          varchar(10),
		@w_financiado        CHAR (1),
		@w_oficina           int,
        @w_grupo             int,
        @w_monto		     money,
		@w_tipo_rubro		 catalogo,
		@w_referencial		 catalogo,
		@w_clase			 char(1),
		@w_sector 			 catalogo,
		@w_fecha_ult_proceso DATETIME,
		@w_signo_default     char(1),
		@w_valor_default     float,		
		@w_signo_maximo      char(1),
		@w_signo_minimo      char(1),
		@w_valor_maximo      float,
		@w_valor_minimo      float,   
		@w_referencia        varchar(255),
		@w_fecha_max         datetime,
		@w_v_valor_default   FLOAT,
		@w_valor_aplicar     FLOAT,
		@w_porcentaje		 FLOAT,
		@w_valor			 money
		
		if @t_show_version = 1
		begin
		   print 'Stored procedure sp_inserta_rubros_financiadoseracion, Version 4.0.0.0'
		   return 0
		end
		
		CREATE TABLE #rubros_actualizar
		(
		 id_num			int IDENTITY(1,1), 
		 concepto		catalogo,
		 tipo_rubro		catalogo,
		 referencial	catalogo,
		 financiado		CHAR (1)
		)		

    select @w_contador = 1
    
    INSERT INTO #rubros_actualizar
    select ru_concepto,
		   ru_tipo_rubro,
		   ru_referencial,
           ru_financiado  
    from ca_rubro 
    where ru_toperacion    = @i_toperacion
    and   ru_moneda        = @i_moneda
    and   ru_financiado    = 'S'
    and   ru_crear_siempre = 'S'
	and   ru_estado        = 'V'  --GFP 30/05/2022 Rubros en estado vigente
          
    select @w_n_rubros = count(1) from #rubros_actualizar 
        
    select TOP 1 @w_concepto = concepto,
				 @w_tipo_rubro = tipo_rubro,
				 @w_referencial = referencial,
                 @w_financiado = financiado  
    from  #rubros_actualizar
    order by id_num 
    
    while @w_contador <= @w_n_rubros 
    begin 
            
	    if @w_tipo_rubro in ('V','O')
		   BEGIN
		      SELECT @w_valor_aplicar = 0,
		             @w_valor_default = 0
		               
              select 
              @w_clase      = va_clase
              from ca_valor
              where va_tipo = @w_referencial
 
              if @@rowcount = 0
			     -- No existe Valor a Aplicar
			     return 701142
				  
			  if @w_tipo_rubro = 'V' and @w_clase = 'F'
			     -- La clase de la Tasa/Valor Aplicar debe ser valor
                 return 725143		

			  if @w_tipo_rubro = 'O' and @w_clase = 'V'
			     -- La clase del valor a aplicar debe ser factor
                 return 708128				 

           	  select 
			  @w_sector 			= opt_sector,
			  @w_fecha_ult_proceso 	= opt_fecha_ult_proceso
		      from ca_operacion_tmp
		      where opt_banco = @i_banco
		
              select 
              @w_signo_default = vd_signo_default,
              @w_valor_default = vd_valor_default,
              @w_signo_maximo  = vd_signo_maximo,
              @w_valor_maximo  = vd_valor_maximo,
              @w_signo_minimo  = vd_signo_minimo,
              @w_valor_minimo  = vd_valor_minimo,
              @w_referencia    = vd_referencia
              from ca_valor,ca_valor_det
              where va_tipo = @w_referencial
              and vd_tipo   = @w_referencial
              and vd_sector = @w_sector 
			  
			  if @@rowcount = 0
			     -- No existe Valores a Aplicar
			     return 710123
			  
			  if @w_referencia is not null and @w_tipo_rubro = 'O' 
				 begin
					select 
					@w_fecha_max = max(vr_fecha_vig)
					from ca_valor_referencial
					where vr_tipo = @w_referencia  --vr_tipo
					and   vr_fecha_vig <= @w_fecha_ult_proceso

					if @@rowcount = 0
					   -- No existe Tasa Referencial a la fecha
					   RETURN 701177
					   
					select 
					@w_v_valor_default = vr_valor
					from ca_valor_referencial z    
					where vr_tipo = @w_referencia
					and vr_secuencial = (select max(vr_secuencial)
										from ca_valor_referencial
										where vr_tipo = z.vr_tipo
										and   vr_fecha_vig = @w_fecha_max)		
					if @@rowcount = 0
					   -- No existe Tasa Referencial a la fecha
					   RETURN 701177
					   
					exec sp_calcula_valor 
                    @i_signo  	 = @w_signo_default,
					@i_base      = @w_v_valor_default,
					@i_factor    = @w_valor_default,
					@o_resultado = @w_valor_aplicar out
				 end
				 
			  if @w_tipo_rubro = 'O'
			     select @w_porcentaje = isnull(@w_valor_aplicar,0),
				        @w_valor     = NULL
			  else	
			     select @w_porcentaje = NULL,
				        @w_valor      = isnull(@w_valor_default,0)			  
		   END -- FIN DE RUBROS TIPO 'V' Y '0' 
		   
    	 --Creacion de rubros
    	EXEC @w_return = sp_rubro_tmp
    	@s_user 		= @s_user,
    	@s_term 		= @s_term,
    	@s_ofi 			=  @s_ofi,
    	@s_date 		= @s_date,
    	@i_banco 		= @i_banco,
    	@i_operacion 	= 'I',
		@i_valor  		= @w_valor,
		@i_porcentaje 	= @w_porcentaje,
    	@i_concepto 	= @w_concepto
    	
    	if @w_return <> 0 
    	  return @w_return
		
       	select @w_monto = opt_monto
		from ca_operacion_tmp
		where opt_banco = @i_banco
    	  
    	exec @w_return = sp_modificar_operacion
    	@s_user              = @s_user,
    	@s_date              = @s_date,
    	@s_ofi               = @s_ofi,
    	@s_term              = @s_term,
    	@i_calcular_tabla    = 'S', 
    	@i_tabla_nueva       = 'S',
    	@i_regenera_rubro    = 'N',
        @i_operacionca       = @i_operacionca,
        @i_banco             = @i_banco,
		@i_grupo             = @i_grupo,
		@i_cuota             = 0
        
    	if @w_return != 0 
    	  return @w_return
		  
		 select @w_monto = opt_monto
		from ca_operacion_tmp
		where opt_banco = @i_banco
			
    	if  @w_contador = @w_n_rubros
    	break
    			
    	select @w_contador = @w_contador + 1
    	  
    	select @w_concepto   = concepto,
    		   @w_tipo_rubro = tipo_rubro,
			   @w_referencial = referencial,
    	       @w_financiado = financiado  
    	from  #rubros_actualizar
    	where id_num = @w_contador
    
    end

return 0
go
