/******************************************************************************/
/*      Archivo:                interfaz_odp_finca_int.sp                     */
/*      Stored procedure:       sp_interfaz_odp_finca_int                     */
/*      Base de datos:          cob_cartera                                   */
/*      Producto:               Cartera                                       */
/*      Disenado por:           Juan Carlos Miranda                           */
/*      Fecha de escritura:     Nov. 2021                                     */
/******************************************************************************/
/*                                 IMPORTANTE                                 */
/* Este programa es parte de los paquetes bancarios propiedad de COBISCorp.   */
/* Su uso no autorizado queda expresamente prohibido asi como cualquier       */
/* alteracion o agregado hecho por alguno de usuarios sin el debido           */
/* consentimiento por escrito de la Presidencia Ejecutiva de COBISCorp        */
/* o su representante.                                                        */
/******************************************************************************/
/*                              PROPOSITO                                     */
/* Realizar un programa que permita validar forma de desembolso tipo 'ORPA',  */
/* consultar y reversar las msimas                                            */
/*                                                                            */
/******************************************************************************/
/*                              MODIFICACIONES                                */
/*  FECHA       VERSION        AUTOR                 RAZON                    */
/*  10/11/2021          Juan Carlos Miranda      Version Inicial              */
/*  29/11/2021          Guisela Fernández        Ingreso de validaciones para */
/*                                               errores                      */
/*  02/12/2021          Guisela Fernandez        Eliminación de validación de */
/*                                               tablas temporales antes de   */
/*                                               realizar el desembolso       */
/*  15/12/2021          Kevin Rodriguez          Liquidación/entrega desembol */
/*  23/06/2022          Kevin Rodríguez          Ajustes (sp_liquida)y pin-odp*/
/*  07/07/2022          Kevin Rodríguez          Ajustes desembol. y reversos */
/*  25/07/2022          Guisela Fernandez        Ajustes de parametro de sali-*/
/*                                               da para nombre_cliente       */
/*  03/08/2022          Kevin Rodríguez          Ajustes reverso mismo día    */
/*  28/09/2022          Kevin Rodríguez          R194456 Ajuste consulta DES  */
/******************************************************************************/

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_interfaz_odp_finca_int')
        drop proc sp_interfaz_odp_finca_int
go
create proc sp_interfaz_odp_finca_int   
        @s_user             login,
        @s_term             varchar(30) = null,
		@s_date             datetime    = NULL,
		@s_ssn              int         = null,
		@s_sesn             int         = null,		
		--@i_operacionca      int,              --NUMERO DE OPERACION
		@i_pin              int,                 --NUMERO DE PIN
		@i_banco_cor        catalogo,           
        @i_cuenta           cuenta,
        @i_operacion        char(1),
        @i_ced_ruc          varchar(30), 
        @i_num_trn_bco      varchar(10) = null,
		@i_auto_rever       varchar(10) = null,
		@o_monto            money        = null  out,  --MONTO DE DESEMBOLSO
		@o_nombre_cliente   varchar(50)  = null  out,  --NOMBRE DE CLIENTE
		@o_error            int          = null  out,  --CODIGO DE ERROR DE COBIS
		@o_mensaje          varchar(255) = null  out   --MENSAJE DE ERROR	
as
declare 
	    @w_return            INT,
	    @w_error             int,               
		@w_mensaje           varchar(255),
		@w_monto_ds          MONEY,
		@w_banco             cuenta ,
		@w_operacion         INT,
		@w_nombre_cliente    VARCHAR(25),
		@w_sec_desembolso    INT,
		@w_secuencial_act    INT,          -- KDR Nuevo secuencial cuando se aplica un reverso de Desembolso
		@w_oficina           int,  
		@w_nombre            VARCHAR(25),
        @w_s_nombre          VARCHAR(25),
        @w_p_apellido        VARCHAR(25),
	    @w_s_apellido        VARCHAR(25),
		@w_nombres           descripcion,
		@w_apellidos         descripcion,
        @w_cliente	         int,
        @w_est_novigente	 tinyint,
		@w_estado_op     	 tinyint,
        @w_pagado            char(1),
		@w_num_desembolso    tinyint,
		@w_desembolsos       int,
		@w_estado_pin        char(1),
		@w_fecha_vencim_pin  smalldatetime,
		@w_fecha_proceso     datetime,
		@w_fecha_liq         datetime,
		@w_cod_banco         int,
		@w_cuenta_banco      varchar(30),
		@w_beneficiario      varchar(160),
        @w_oficina_desem     smallint,
		@w_producto          catalogo,
        @w_causal            varchar(64),
        @w_monto_mds         money,
        @w_sec_banco         INT,           -- KDR Secuencial que retorna la interfaz Bancos       		
		@w_fecha_trn_bancos  datetime       -- KDR Fecha de registro de la transacción en Bancos
		
		select @w_error = 0,
               @w_mensaje = '',
               @w_monto_ds = 0,
			   @w_desembolsos  = 0
		
		-- Fecha proceso / cierre cartera
	    select @w_fecha_proceso = fc_fecha_cierre
        from   cobis..ba_fecha_cierre
        where  fc_producto = 7 
        
        exec @w_error = sp_estados_cca
				@o_est_novigente  = @w_est_novigente out

        if @w_error <> 0 
	       goto ERROR		

	    if @i_operacion = 'I'
		begin
		
			select @w_desembolsos = count(1) from ca_operacion, ca_desembolso, ca_pin_odp, ca_producto, cob_credito..cr_deudores
		 	where op_operacion = dm_operacion 
			and dm_operacion = po_operacion
			and dm_secuencial = po_secuencial_desembolso 
			and dm_desembolso = po_desembolso
			and op_tramite = de_tramite
			--and op_estado = 0 AND dm_estado = 'NA'		   
			and dm_cod_banco = @i_banco_cor
			and dm_cuenta = @i_cuenta
			and po_pin = @i_pin  
			and de_rol = 'D'
			and de_ced_ruc = @i_ced_ruc
			and dm_producto  = cp_producto
			and cp_categoria = 'ORPA'
			
			if @w_desembolsos = 0
			begin
			    select @w_error = 725118
		        select @w_mensaje = 'No existe desembolso con parametros enviados'
			    GOTO ERROR
			end
			
			else if @w_desembolsos = 1
		    begin 
		 	    select @w_operacion        = dm_operacion,
		 	           @w_banco            = op_banco,
					   @w_estado_op        = op_estado,
		 	           @w_oficina          = op_oficina,
					   @w_fecha_liq        = op_fecha_liq, 
		 	           @w_monto_ds         = dm_monto_mds,
		 	           @w_sec_desembolso   = dm_secuencial,
					   @w_num_desembolso   = dm_desembolso,
					   @w_cod_banco        = dm_cod_banco,
					   @w_cuenta_banco     = dm_cuenta,
					   @w_beneficiario     = dm_beneficiario,
					   @w_oficina_desem    = dm_oficina,
					   @w_producto         = dm_producto,
					   @w_monto_mds        = dm_monto_mds,
                       @w_pagado           = isnull(dm_pagado,'N'),
					   @w_estado_pin       = po_estado,
					   @w_fecha_vencim_pin = po_fecha_vencimiento 
		 	    from ca_operacion, ca_desembolso d, ca_pin_odp, cob_credito..cr_deudores
				where op_operacion = dm_operacion 
				and dm_operacion = po_operacion
				and dm_secuencial = po_secuencial_desembolso 
				and dm_desembolso = po_desembolso
				and op_tramite = de_tramite
				--and op_estado = 0 AND dm_estado = 'NA'	   
				and dm_cod_banco = @i_banco_cor
				and dm_cuenta = @i_cuenta   	   
				and po_pin = @i_pin
				and de_rol = 'D'
				and de_ced_ruc = @i_ced_ruc
						
			    if @w_error <> 0  goto ERROR
				
				if @w_estado_pin <> 'N' or @w_fecha_vencim_pin < @w_fecha_proceso
				begin
				    select @w_error = 725131 -- Error, el pin del desembolso no esta vigente, revisar estado y fecha de vencimiento del pin.
					goto ERROR
				end
				
				if @w_pagado = 'S'
				begin
					select @w_error = 725130 -- Error, la orden de desembolso ya ha sido pagada.
					goto ERROR
				end
					    
				if @w_estado_op = @w_est_novigente
				begin
				
				    exec @w_error      = sp_pasotmp
				    @s_term             = @s_term,
				    @s_user             = @s_user,
				    @i_banco            = @w_banco,
				    @i_operacionca      = 'S',
				    @i_dividendo        = 'S',
				    @i_amortizacion     = 'S',
				    @i_cuota_adicional  = 'S',
				    @i_rubro_op         = 'S',
				    @i_nomina           = 'S'   
				    
				    if @w_error <> 0  goto ERROR
				   
				    exec @w_error = cob_cartera..sp_liquida
                         @s_date			= @s_date,
					     @s_ofi				= @w_oficina,
					     @s_user			= @s_user,
					     @s_term			= @s_term,
					     @s_ssn				= @s_ssn,
					     @i_banco_ficticio 	= null, 
					     @i_banco_real		= @w_banco,
					     @i_carga			= 0,
					     @i_fecha_liq		= @w_fecha_liq, 
					     @i_prenotificacion	= 0,
					     @i_renovacion		= 'N',
						 @i_externo         = 'N',
		                 @i_desde_cartera   = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
					     @t_trn				= 7060,
					     @i_nom_producto   	= 'CCA',
					     @o_banco_generado	= '0'

				    if @w_error <> 0 goto ERROR 
				   
				    exec @w_error = sp_borrar_tmp
				    @s_sesn   = @s_ssn,
				    @s_user   = @s_user,
				    @s_term   = @s_term,
				    @i_banco  = @w_banco
				    
				    if @w_error <> 0  goto ERROR
				
				end
				
                -- Marcar como pagado el desembolso
				exec @w_error = cob_cartera..sp_desembolso
				@i_operacion      = 'U',
				@i_opcion         = 1,
				@i_banco_real     = @w_banco,
				@i_banco_ficticio = @w_banco,
				@i_secuencial     = @w_sec_desembolso,
				@i_desembolso     = @w_num_desembolso,
				@i_desde_cre      = 'N',
				@i_externo        = 'N',
				@i_pagado         = 'S',
				@s_ofi            = @w_oficina,
				@s_term           = @s_term,
				@s_user           = @s_user,
				@s_date           = @s_date
				
				if @w_error <> 0 
	                goto ERROR
				
				
				IF @w_oficina IS NOT NULL
		   		begin
		   			UPDATE ca_desembolso
		   			SET dm_idlote  = convert(INT, @i_num_trn_bco)
		   			WHERE dm_operacion = @w_operacion
		   			AND dm_secuencial = @w_sec_desembolso
		   			AND dm_estado = 'A'
		   		end
				                          	 
                select  @o_error          = isnull (@w_error,0),
		                @o_mensaje        = 'DESEMBOLSO EXITOSO'

                --  KDR	Incio Generación de la nota de débito en la cuenta bancaria
				select @w_causal = c.valor 
		        from cobis..cl_tabla t, cobis..cl_catalogo c
                where t.tabla = 'ca_fpago_causalbancos'
                and t.codigo = c.tabla
		        and c.estado = 'V'
                and c.codigo = @w_producto
				
				if @@rowcount = 0 or @w_causal is null
		        begin
		           select @w_error = 725139 -- Error, no existe causal para la forma de pago actual, revisar catálogo ca_fpago_causalbancos
		           goto ERROR
		        end
		
				exec @w_error = cob_bancos..sp_tran_general 
                @i_operacion     = 'I',
                @i_banco         = @w_cod_banco, 
                @i_cta_banco     = @w_cuenta_banco,
                @i_fecha         = @w_fecha_proceso,
                @i_tipo_tran     = 106,                -- Código de nota de débito  
                @i_causa         = @w_causal,     
                @i_documento     = @w_banco,                
                @i_concepto      = 'DESEMBOLSO ODP',
                @i_beneficiario  = @w_beneficiario,
                @i_valor         = @w_monto_mds,  
                @i_producto      = 7,
                @i_sec_monetario = @w_num_desembolso,
                @t_trn           = 171013,
                @i_ref_modulo2   = @w_oficina_desem,
                @s_user          = @s_user,
                @s_term          = @s_term,
                @s_ofi           = @w_oficina_desem,
                @s_ssn           = @s_ssn,
                @s_corr          = 'I',
                @s_date          = @s_date,
				@o_secuencial    = @w_sec_banco out
				
				if @w_error <> 0 
	               goto ERROR
				   
				-- KDR. Se actualiza secuencial en tabla de desembolso con el que se registra el cheque.
	            update ca_desembolso
                set dm_carga = @w_sec_banco
                where dm_operacion  = @w_operacion
                and   dm_producto   = @w_producto
                and   dm_secuencial = @w_sec_desembolso
			    
                if @@error != 0 
                begin
                   select @w_error = 710305
                   goto ERROR
                end 
				   
				-- KDR Fin Generación de la nota de débito en la cuenta bancaria
                					
		    end
		    else
		    begin 
		        select @w_error = 711091 --No se puede desembolsar con mas de una forma de desembolso asociado
			    goto ERROR	
		    end	
		end		
		
		if @i_operacion = 'R'
		BEGIN
							    
		    if exists(select 1 from ca_transaccion, ca_desembolso d, ca_pin_odp, ca_producto
					  where tr_operacion = dm_operacion 
					  and dm_operacion = po_operacion
					  and dm_secuencial = po_secuencial_desembolso 
					  and dm_desembolso = po_desembolso
					  and (tr_tran = 'DES' AND tr_estado <> 'RV') AND dm_estado = 'A'	    	   
					  and po_pin = @i_pin  
					  --and tr_fecha_mov = @s_date
					  and dm_idlote =  @i_auto_rever
					  and dm_producto = cp_producto
					  and cp_categoria = 'ORPA')
		    begin 					   
					   select @w_operacion = dm_operacion,
		 	                  @w_banco  = tr_banco,
		 	                  @w_oficina = tr_ofi_oper,
		 	                  @w_sec_desembolso = tr_secuencial,
                              @w_num_desembolso = dm_desembolso,
                              @w_producto       = dm_producto,
                              @w_cod_banco      = dm_cod_banco,
					          @w_cuenta_banco   = dm_cuenta,
					          @w_beneficiario     = dm_beneficiario,
					          @w_oficina_desem    = dm_oficina,
                              @w_monto_mds        = dm_monto_mds,
                              @w_sec_banco        = dm_carga							  
					   from ca_transaccion, ca_desembolso d, ca_pin_odp, ca_producto
					   where tr_operacion = dm_operacion 
					   and dm_operacion  = po_operacion
					   and dm_secuencial = po_secuencial_desembolso 
					   and dm_desembolso = po_desembolso
					   and (tr_tran = 'DES' AND tr_estado <> 'RV') AND dm_estado = 'A'	    	   
					   AND po_pin = @i_pin    
					   --and tr_fecha_mov = @s_date
					   AND dm_idlote =  @i_auto_rever
					   and dm_producto = cp_producto
					   and cp_categoria = 'ORPA'
					   

					   select @w_fecha_trn_bancos = tm_fecha
					   from cob_bancos..ba_tran_monet
					   where tm_secuencial = @w_sec_banco
					   and tm_banco        = @w_cod_banco
					   and tm_cta_banco    = @w_cuenta_banco
					      
					   -- SE REVERSA SOLO SI ES EL MISMO DÍA QUE SE REALIZÓ LA TRANSACCIÓN-
					   if @w_fecha_trn_bancos = @s_date
                       begin
					  		   					   			   
		   			       exec @w_error  =  sp_fecha_valor
						   @s_date            = @s_date,
						   @s_ofi			   = @w_oficina,
						   @s_user		       = @s_user,
						   @s_term			   = @s_term,
						   @s_ssn			   = @s_ssn,
						   @t_trn             = 7049,
						   @i_operacion       = 'R',
						   @i_banco           = @w_banco ,
						   --@i_fecha_valor     = '07/30/2020',
						   @i_en_linea        = 'S',
						   @i_secuencial      =  @w_sec_desembolso,
						   @o_secuencial_act  = @w_secuencial_act out
						   
						   if @w_error <> 0  goto ERROR
						   
						   -- Quitar marca de pagado el desembolso
				           exec @w_error = cob_cartera..sp_desembolso
				           @i_operacion      = 'U',
				           @i_opcion         = 1,
				           @i_banco_real     = @w_banco,
				           @i_banco_ficticio = @w_banco,
				           @i_secuencial     = @w_secuencial_act,  -- KDR Se actualiza registro de desembolso según nuevo secuencial generado al aplicar reverso.
				           @i_desembolso     = @w_num_desembolso,
				           @i_desde_cre      = 'N',
				           @i_externo        = 'N',
				           @i_pagado         = 'N',
				           @s_ofi            = @w_oficina,
				           @s_term           = @s_term,
				           @s_user           = @s_user,
				           @s_date           = @s_date
						   
						   if @w_error <> 0 
	                          goto ERROR
						      

						   select @w_causal = c.valor 
                           from cobis..cl_tabla t, cobis..cl_catalogo c
                           where t.tabla = 'ca_fpago_causalbancos'
                           and t.codigo = c.tabla
                           and c.estado = 'V'
                           and c.codigo = @w_producto
		                   
                           if @@rowcount = 0 or @w_causal is null
                           begin
                              select @w_error = 725139 -- Error, no existe causal para la forma de pago actual, revisar catálogo ca_fpago_causalbancos
                              goto ERROR
                           end
		                   
                           exec @w_error = cob_bancos..sp_tran_general
                           @i_operacion      = 'I',
                           @i_banco          = @w_cod_banco,
                           @i_cta_banco      = @w_cuenta_banco,
                           @i_fecha          = @w_fecha_proceso,
                           --@i_fecha_contable = @w_fecha_proceso,
                           @i_tipo_tran      = 106,             -- Código de nota de débito 
                           @i_causa          = @w_causal,       -- KDR Causal de la forma de pago
                           @i_documento      = @w_banco ,       --NRO  DE REFERENCIA BANCARIA INGRESADA
                           @i_concepto       = 'DESEMBOLSO ODP',
                           @i_beneficiario   = @w_beneficiario,
                           @i_valor          = @w_monto_mds,
                           @i_cheques        = 0,
                           @i_producto       = 7, --CARTERA
                           @i_desde_cca      = 'S',
                           --@i_ref_modulo     = @i_banco,
                           @i_modulo         = 7, --CARTERA
                           @i_ref_modulo2    = @w_oficina_desem,
                           @t_trn            = 171013,
                           @s_corr           = 'S',
                           @s_ssn_corr       = @w_sec_banco,
                           @s_user           = @s_user,
                           @s_ssn            = @s_ssn
						   
						   if @w_error <> 0 
	                          goto ERROR

                        end	-- FIN REVERSO
						else
						begin
                           select @w_error = 725171 -- Error, no se permite reversar la orden de pago en un día distinto a la fecha de entrega
                           goto ERROR
						end
						                          	                           	 
                        select  @o_error          = isnull (@w_error,0),
		                       @o_mensaje        = 'REVERSO DE DESEMBOLSO EXITOSO'           	 

		    end
		    else
		    begin 
				 	select @w_error = 141208
				    select @w_mensaje = 'No existen ordenes de pago a reversar'
					GOTO ERROR
		    end


		end		
		
		if @i_operacion = 'Q'
		begin
          if exists(SELECT 1 FROM ca_operacion, ca_desembolso, ca_pin_odp, cob_credito..cr_deudores
		 			   WHERE op_operacion = dm_operacion 
					   and dm_operacion = po_operacion
					   and dm_secuencial = po_secuencial_desembolso 
					   and dm_desembolso = po_desembolso
					   and op_tramite = de_tramite
					   --and op_estado = 0 AND dm_estado = 'NA'	 -- KDR Se comenta sección (para multiples formas de desembolso)	   
					   and dm_cod_banco = @i_banco_cor
					   and dm_cuenta = @i_cuenta   	   
					   and po_pin = @i_pin
					   and de_rol = 'D'
					   and de_ced_ruc = @i_ced_ruc)
		  begin 
		 	            select @w_operacion = dm_operacion,
		 	                   @w_banco  = op_banco,
		 	                   @w_monto_ds = dm_monto_mds,
							   @w_cliente  = op_cliente
		 	            from ca_operacion, ca_desembolso d, ca_pin_odp, cob_credito..cr_deudores
					    where op_operacion = dm_operacion 
					    and dm_operacion = po_operacion
					    and dm_secuencial = po_secuencial_desembolso 
						and dm_desembolso = po_desembolso
					    and op_tramite = de_tramite
					    --and op_estado = 0 AND dm_estado = 'NA'    -- KDR Se comenta sección (para multiples formas de desembolso)
					    and dm_cod_banco = @i_banco_cor
					    and dm_cuenta = @i_cuenta   	   
					    and po_pin = @i_pin
					    and de_rol = 'D'
					    and de_ced_ruc = @i_ced_ruc
						
						select @w_nombre         = en_nombre,
						       @w_s_nombre       = p_s_nombre,
							   @w_p_apellido     = p_p_apellido,
							   @w_s_apellido     = p_s_apellido
						FROM cobis..cl_ente 
						WHERE en_ente = @w_cliente and en_ced_ruc = @i_ced_ruc
					    		   			
		   			    exec @w_error = cob_cartera..sp_consulta_nombre
                             @i_banco = @w_banco,
                             @o_nombre_cliente = @w_nombre_cliente OUT
                            
                             if @w_error <> 0
	  					     begin
		                         GOTO ERROR
                          	 end
						 
						 select @w_nombres = ltrim(rtrim(isnull(ltrim(rtrim(@w_nombre)),'') + ' ' + isnull(ltrim(rtrim(@w_s_nombre)),''))),
						        @w_apellidos = ltrim(rtrim(isnull(ltrim(rtrim(@w_p_apellido)),'') + ' ' + isnull(ltrim(rtrim(@w_s_apellido)),'')))
						
                         select @o_monto          = @w_monto_ds, 
                                @o_nombre_cliente = @w_nombre_cliente + ' - ' + @w_nombres + ', ' + @w_apellidos
		                        --@o_error          = @w_error,
		                        --@o_mensaje        = @w_mensaje         	 

		  end
		 else
		  begin 
		 	select @w_error = 725118
		    select @w_mensaje = 'No existe desembolso con parametros enviados'
			GOTO ERROR
		  end

		   	
		end		
		
		

return 0


ERROR:
select @o_error   = @w_error,
       @o_mensaje = @w_mensaje 
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = '',
@i_num   = @w_error 

return @w_error
GO
