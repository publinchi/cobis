/***********************************************************************/
/*  Archivo:            incentivosgan.sp                               */
/*  Stored procedure:       sp_incentivos_ganancias                    */
/*  Base de Datos:          cob_cartera                                 */
/*  Producto:           cartera                                        */
/*  Disenado por:           Andy Gonzalez                              */
/*  Fecha de Documentacion:     Marzo del 2017                         */
/***********************************************************************/
/*          IMPORTANTE                                                 */
/*  Este programa es parte de los paquetes bancarios propiedad de      */ 
/*  "MACOSA",representantes exclusivos para el Ecuador de              */
/*  MACOSA                                                             */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier autorizacion o agregado hecho por alguno de sus          */
/*  usuario sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante                 */
/***********************************************************************/
/*          PROPOSITO                                                  */
/*  Proceso de generacion de incentivos y ganacias CAME                */
/*      estado Propuesto.                                              */ 
/*  Insert, Delete                                                     */
/*                                                                     */
/***********************************************************************/
/*          MODIFICACIONES                                             */
/*  FECHA       AUTOR           RAZON                                  */
/*  Marzo-2017   AGO            Inicial                                */
/*  05-Abr-2017  I. Yupa        Incentivos                             */
/*  05-Abr-2017  T. Baidal      Ganancias sp_aho_cta_grupal y refactor */
/*                              queries de incentivos.                 */
/*  09-May-2017   M. Custode     Validacion cuentas AHO                */
/***********************************************************************/
use cob_cartera
go

if exists (select * from sysobjects where name = 'sp_incentivos_ganancias')
drop proc sp_incentivos_ganancias
go

create proc sp_incentivos_ganancias (
@t_show_version         bit             = 0,  -- show the version of the stored procedure
@s_ssn                  int             = null,
@s_user                 login           = null,
@s_sesn                 int             = null,
@s_term                 varchar(30)     = null,
@s_date                 datetime        = null,
@s_srv                  varchar(30)     = null,
@s_lsrv                 varchar(30)     = null,
@s_rol                  smallint        = NULL,
@s_ofi                  smallint        = NULL,
@s_org_err              char(1)         = NULL,
@s_error                int             = NULL,
@s_sev                  tinyint         = NULL,
@s_msg                  descripcion     = NULL,
@s_org                  char(1)         = NULL,
@t_rty                  char(1)         = null,
@t_trn                  smallint        = null,
@t_debug                char(1)         = 'N',
@t_file                 varchar(14)     = null,
@t_from                 varchar(30)     = null,
@i_ente                int             = null,
@i_en_linea             char(1)   		= 'N',
@i_debug                char(1)   		= 'N',
@i_tipo_prestamo        char(1)
)

as
declare
@w_today                datetime,     /* fecha del dia */ 
@w_return               int,          /* valor que retorna */
@w_sp_name              varchar(32),  /* nombre stored proc*/
@w_existe               tinyint,      /* existe el registro*/
@w_ubicacion            varchar(10),
@w_porcentaje_inc       float,
@w_mon_int              MONEY,
@w_fecha_proceso		DATETIME,
--@w_tipo_ciclo			CHAR(1),
@w_con 					INT,
@w_cta_grp 				cuenta,
@w_op_moneda 			INT,
@w_operacionca 			INT,
@w_monto_inc			MONEY,
@w_secuencial_cr		INT,
@w_error				INT,
@w_msg					VARCHAR(64),
@w_commit				CHAR(1),
@w_procesa				CHAR(1),
@w_monto_ind			MONEY,
@w_cliente				INT,
@w_actual				FLOAT,
@w_anterior				FLOAT,
@w_secuencial			INT,
@w_ciclo_grupo          int,
@w_tramite              int,
@w_ahorro_grupo         money,
@w_ahorro_individual    money,
@w_proporcion           float,
@w_operacion_gr         int,
@w_operacion_emer       int,
@w_operacion_cli        int,
@w_int_nor_cli          money,
@w_int_eme_cli          money,
@w_monto_int_gan        money

if 'N' = (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' and pa_producto = 'CCA')
   return 0


--05-Abr-2017 Se maneja set rowcount 0 como paliativo debido a que cuando se ejecuta en el flujo toma rowcount 1
set rowcount 0

select @w_procesa = 'S'

--if @w_ciclo = 1 return 0
         --cantidad de dividendos que no se cancelaron puntualmente 

select @w_sp_name = 'sp_incentivos_ganancias'

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

if @i_tipo_prestamo = 'G'
begin
    --EJECUCION DE GANANCIAS POR RENDIMIENTO DE LA CUENTA DE AHORRO
    exec @w_error = cob_cartera..sp_aho_cta_grupal 
    @i_grupo = @i_ente
    
    if @w_error <> 0 or @@error <> 0 
    begin     
        if @@trancount = 0 select @w_commit = 'N'
        goto ERROR
    end
    	
    --OBTENER CICLO DEL GRUPO
    select @w_ciclo_grupo = isnull(max(ci_ciclo), 1)           
    from  cob_cartera..ca_ciclo
    where ci_grupo = @i_ente
		
	--OBTENER OPERACION,TRAMITE y CUENTA DEL GRUPO
    select
    @w_operacion_gr = ci_operacion,
    @w_tramite      = ci_tramite
    from cob_cartera..ca_ciclo
    where ci_grupo = @i_ente
    and ci_ciclo = @w_ciclo_grupo
		
	--OBTENER LA CUENTA Y MONEDA DEL PRESTAMO GRUPAL
    select @w_cta_grp = op_cuenta,
           @w_op_moneda = op_moneda
    from ca_operacion
    where op_operacion = @w_operacion_gr


	----------
	select @w_con = count(1)
	from ca_dividendo
	where di_operacion in (select dc_operacion from ca_det_ciclo
                           where dc_ciclo_grupo = @w_ciclo_grupo
                           and dc_grupo   = @i_ente
						   and dc_tciclo  = 'N')
	and di_fecha_ven <> di_fecha_can
	and di_fecha_can > di_fecha_ven
	and di_estado = 3
	group by di_operacion
	having count(1) >1
	select @w_con = isnull(@w_con, 0)
	
	create table #operaciones(operacion int null, cliente int, estado char(1) null)
	insert into #operaciones(operacion,cliente,estado)
	select tg_operacion, tg_cliente,'V'
	from cob_credito..cr_tramite_grupal
    where tg_tramite = @w_tramite
	
	--OBTENER SALDO DE LA CUENTA GRUPAL		
    select @w_ahorro_grupo = sum(ai_saldo_individual)
		from cob_ahorros..ah_ahorro_individual
        where ai_operacion in (select operacion from #operaciones)
	  
	if @w_con > 1 GOTO INCEN_SOBRETASA

	if @w_con = 0
	begin
      
        SELECT @w_porcentaje_inc = pa_float
        FROM cobis..cl_parametro
        WHERE pa_nemonico = 'PIPP'
        AND pa_producto = 'CCA' 
                               
	end
      
    if @w_con = 1
    begin
       SELECT @w_porcentaje_inc = pa_float
       FROM cobis..cl_parametro
       WHERE pa_nemonico = 'PICIP'
       AND pa_producto = 'CCA' 
    end
	
     --hay incentivos		   
	select @w_mon_int = sum(am_pagado) from ca_amortizacion
    where am_operacion in (select operacion from #operaciones)
    and am_concepto = 'INT'
    and am_estado = 3
      	 
    select @w_monto_inc = (@w_mon_int * @w_porcentaje_inc) / 100
	--procedemos a realizar la acreditacion a la cuenta grupal
    -- GENERAR LA NOTA CREDITO A LA CUENTA
	
	if (isnull(@w_monto_inc,0))=0
	begin
	    exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 710129
        return 1
	end
	
    exec @w_secuencial_cr = sp_gen_sec     
             @i_operacion = @w_operacion_gr
         
	if @w_secuencial_cr = 0
    begin
         select @w_error = 710225, @w_msg = 'ERROR AL GENERAR SECUENCIAL DE CREDITO GRUPAL'
         goto ERROR
    end  
        
	begin tran
	
    exec @w_error = sp_afect_prod_cobis
            @s_ssn          = @s_ssn,
            @s_user         = @s_user,
            @s_term         = @s_term,   
            @s_date         = @s_date,
            @s_ofi          = @s_ofi,
            @i_en_linea     = @i_en_linea,
            @i_debug        = @i_debug,
            @i_fecha        = @w_fecha_proceso,
            @i_cuenta       = @w_cta_grp,
            @i_producto     = 'NCAH',
            @i_monto        = @w_monto_inc,
            @i_mon          = @w_op_moneda,
            --@i_operacionca  = @i_operacionca,
            --@i_alt          = @i_operacionca,
            @i_sec_tran_cca = @w_secuencial_cr,
            @i_grupal       = 'I'		
               
    if @w_error <> 0 or @@error <> 0 begin    
       if @@trancount = 0 select @w_commit = 'N'
       goto ERROR
    end     
           
    commit tran
		   
	
    while (@w_procesa = 'S')
    begin
        select @w_monto_ind   = am_pagado,
               @w_operacionca = op_operacion,
               @w_cliente     = op_cliente
        from ca_operacion, ca_amortizacion
        where op_operacion = am_operacion
        and am_operacion in (select top 1 operacion from #operaciones where estado = 'V')
        and am_concepto = 'INT'

        group by am_pagado,op_operacion,op_cliente
        
        if @@ROWCOUNT = 0 
        begin
           select @w_procesa = 'N'
           break
        end		
		
		--OBTENER SALDO DE AHORRO INDIVIDUAL
        select @w_ahorro_individual = ai_saldo_individual
		from cob_ahorros..ah_ahorro_individual
        where ai_cliente = @w_cliente
        and ai_operacion = @w_operacionca
								 
		--OBTENER PROPORCION		
		select @w_proporcion = @w_ahorro_individual / @w_ahorro_grupo

        IF EXISTS (SELECT 1 FROM cob_ahorros..ah_ahorro_individual 
                 WHERE ai_cliente = @w_cliente 
                 AND ai_operacion = @w_operacionca
                 AND ai_cta_grupal = @w_cta_grp)
        BEGIN 

           UPDATE cob_ahorros..ah_ahorro_individual
           SET ai_incentivo = ai_incentivo + (@w_monto_inc * @w_proporcion)
           WHERE ai_cliente = @w_cliente 
           AND ai_operacion = @w_operacionca
           AND ai_cta_grupal = @w_cta_grp              
        END
        ELSE
        BEGIN
           INSERT INTO cob_ahorros..ah_ahorro_individual(ai_cta_grupal, ai_operacion, ai_cliente, ai_incentivo)
           VALUES (@w_cta_grp,@w_operacionca,@w_cliente,(@w_monto_inc * @w_proporcion))   	                          
        END 
             
        update #operaciones set estado = 'P'
        where operacion = @w_operacionca
    end --end while      

	
	INCEN_SOBRETASA:
	
	--**********************************************INCENTIVOS POR INTERCICLOS******************************************
	
	--OBTENER PORCENTAJE DE INTERES DE LA OPERACION DEL GRUPO
    SELECT @w_anterior = ro_porcentaje_efa 
    FROM ca_rubro_op 
    WHERE ro_operacion = @w_operacion_gr
    AND ro_concepto = 'INT'
	
	--INSERTAR INTERCICLO
	create table #interciclos(operacion int null, cliente int, estado char(1) null)
	insert into #interciclos(operacion,cliente, estado)
	select dc_operacion, dc_cliente, 'N'
	    from cob_cartera..ca_det_ciclo
        where dc_grupo = @i_ente
        and dc_ciclo_grupo = @w_ciclo_grupo
	    and dc_tciclo  = 'E'
		
	update #operaciones
	set estado = 'N'
	while exists(select 1 from #interciclos where estado = 'N')
	begin
        select top 1 @w_operacion_emer = operacion, @w_cliente = cliente
		from #interciclos
		where estado = 'N'
		
		select @w_operacion_cli = dc_operacion
	    from cob_cartera..ca_det_ciclo
        where dc_grupo = @i_ente
        and dc_ciclo_grupo = @w_ciclo_grupo
	    and dc_tciclo  = 'N'
		and dc_cliente = @w_cliente
		
	    --OBTENER PORCENTAJE DE INTERES DE LA OPERACION DEL CLIENTE
        SELECT @w_actual = ro_porcentaje_efa 
        FROM ca_rubro_op 
        WHERE ro_operacion = @w_operacion_emer
        AND ro_concepto = 'INT'
		
	    select @w_porcentaje_inc = @w_actual - @w_anterior
        
        if @w_porcentaje_inc > 0
        begin
            	   
	    	select @w_int_nor_cli = sum(am_pagado) 
	    	from ca_amortizacion, ca_rubro_op
            where am_operacion  = @w_operacion_cli
			  and am_estado     = 3   
			  and am_operacion  = ro_operacion
	          and am_concepto   = ro_concepto
			  and ro_tipo_rubro = 'I'
			  
	    	select @w_int_eme_cli = sum(am_pagado) 
	    	from ca_amortizacion, ca_rubro_op
            where am_operacion  = @w_operacion_emer
			  and am_estado     = 3   
			  and am_operacion  = ro_operacion
	          and am_concepto   = ro_concepto
			  and ro_tipo_rubro = 'I'
			  

			select @w_monto_int_gan = @w_int_eme_cli - @w_int_nor_cli
			
            select @w_monto_inc = (@w_monto_int_gan * @w_porcentaje_inc) / 100
            --procedemos a realizar la acreditacion a la cuenta grupal
            -- GENERAR LA NOTA CREDITO A LA CUENTA
            exec @w_secuencial_cr = sp_gen_sec     
                 @i_operacion = @w_operacion_gr
			
				 
	    	if @w_secuencial_cr = 0
            begin
                select @w_error = 710225, @w_msg = 'ERROR AL GENERAR SECUENCIAL DE CREDITO GRUPAL'
                goto ERROR
            end		
            
			begin tran
            
			exec @w_error = sp_afect_prod_cobis
            @s_ssn          = @s_ssn,
            @s_user         = @s_user,
            @s_term         = @s_term,   
            @s_date         = @s_date,
            @s_ofi          = @s_ofi,
            @i_en_linea     = @i_en_linea,
            @i_debug        = @i_debug,
            @i_fecha        = @w_fecha_proceso,
            @i_cuenta       = @w_cta_grp,
            @i_producto     = 'NCAH',
            @i_monto        = @w_monto_inc,
            @i_mon          = @w_op_moneda,
            --@i_operacionca  = @i_operacionca,
            --@i_alt          = @i_operacionca,
            @i_sec_tran_cca = @w_secuencial_cr,
            @i_grupal       = 'I'		
            
            if @w_error <> 0 or @@error <> 0 begin     
               if @@trancount = 0 select @w_commit = 'N'
               goto ERROR
            end     
            
            commit tran
			
			update #operaciones
			set estado = 'V'
			
			select @w_procesa = 'S'
            while exists (select top 1 operacion from #operaciones where estado = 'V')
            begin
			    select top 1 
				@w_operacionca = operacion,
			    @w_cliente     = cliente
			    from #operaciones where estado = 'V'
				
	    		--OBTENER SALDO DE AHORRO INDIVIDUAL
                select @w_ahorro_individual = ai_saldo_individual
	    		from cob_ahorros..ah_ahorro_individual
                where ai_cliente = @w_cliente
                and ai_operacion = @w_operacionca
									
	    		--OBTENER PROPORCION
	    		select @w_proporcion = @w_ahorro_individual / @w_ahorro_grupo
				IF EXISTS (SELECT 1 FROM cob_ahorros..ah_ahorro_individual 
                         WHERE ai_cliente = @w_cliente 
                         AND ai_operacion = @w_operacionca
                         AND ai_cta_grupal = @w_cta_grp)
                BEGIN 
                    UPDATE cob_ahorros..ah_ahorro_individual
                    SET ai_incentivo = ai_incentivo + (@w_monto_inc * @w_proporcion)
                    WHERE ai_cliente = @w_cliente 
                    AND ai_operacion = @w_operacionca
                    AND ai_cta_grupal = @w_cta_grp	  
                END
                ELSE
                BEGIN
                    INSERT INTO cob_ahorros..ah_ahorro_individual(ai_cta_grupal, ai_operacion, ai_cliente, ai_incentivo)
                    VALUES (@w_cta_grp,@w_operacionca,@w_cliente,(@w_monto_inc * @w_proporcion))   	                          
                END 
                   
                update #operaciones set estado = 'P'
                where operacion = @w_operacionca
            end --end while operaciones 
        end
		update #interciclos
		set estado = 'P'
		where operacion = @w_operacion_emer 
    end --end while interciclos
end
return 0     
ERROR:

if @w_commit = 'S' begin
   select @w_commit = 'N'
   rollback tran
end  

if @i_en_linea = 'S' begin
 
   exec cobis..sp_cerror 
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,  
   @i_msg   = @w_msg,
   @i_num   = @w_error
   
end else begin

   select @w_secuencial = isnull(@w_secuencial, 7999)

   exec sp_errorlog 
   @i_fecha       = @s_date,
   @i_error       = @w_error,
   @i_usuario     = @s_user,
   @i_tran        = @w_secuencial,
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = @w_cta_grp,
   @i_descripcion = @w_msg,
   @i_rollback    = 'N'   
   
end

return 0  -- para que el batch 1 no registre dos veces el mismo error
GO

