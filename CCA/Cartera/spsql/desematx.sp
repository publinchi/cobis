/************************************************************************/
/*   Archivo:              desematx.sp                         			*/
/*   Stored procedure:     sp_desembolso_atx      						*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Aldair Fortiche Lenes                        */
/*   Fecha de escritura:   Junio 2021                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Realiza consultas sobre desembolsos asignados a prestamos que no   */
/*   se encuentren aplicados para usos de integracion con teller		*/
/*                              CAMBIOS                                 */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*   FECHA        AUTOR                    RAZON                        */
/* 04/Jun/2021   Aldair Fortiche      Version inicial					*/
/* 09/Jun/2021   Aldair Fortiche      Se ordena logica en consultas, 	*/
/* 								      luego se agrega validaciones para */
/* 								      aplicar desembolso y reverso del  */
/* 								      desembolso 						*/
/* 17/Jun/2021   Aldair Fortiche      Se reubica un campo de resulset 	*/
/* 								      en consultas por peticion del     */
/* 								      equipo atx teller  				*/
/* 17/Jun/2021   Aldair Fortiche      renombrado de archivo fisico		*/
/* 								      por estandares			        */
/* 06/Seo/2021   Alfredo Monroy       Tomar categoria de ca_producto    */
/* 23/Sep/2021   Kevin Rodríguez     Consulta préstamos por otras iden- */   
/*                                   tificaciones de cliente            */
/* 15/12/2021    Kevin Rodríguez     Liquidación/entrega efectivo       */
/* 13/04/2022    Kevin Rodríguez     No manejo de atomicidad            */
/* 27/05/2022   Guisela Fernández    Validación para días permitidos de */
/*                                   desembolso                         */
/* 16/06/2022   Guisela Fernández    Cambio de código de error          */
/* 23/06/2022   Kevin Rodríguez      Ajustes liquidación (sp_liquida)   */
/* 07/07/2022   Kevin Rodríguez      Ajustes desembolso y reverso desemb*/
/* 19/08/2022   Kevin Rodríguez      R191952 Valida estado de op luego  */
/*                                   de liquidar                        */
/* 24/08/2022   Guisela Fernandez    R191952 Validación de estado no    */
/*                                   vigente en operaciones             */
/* 07/09/2022   Guisela Fernandez    R193078 Cambio de validación de es-*/
/*                                  tado de operaciones incluye vigentes*/
/* 25/08/2023   Guisela Fernandez    R213766 Reverso de ope. hijas solo */
/*                                   se actualiza el dm_pagado          */
/* 30/08/2023   Guisela Fernandez    R213766 Val. de estado op. padre   */ 
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_desembolso_atx')
   drop proc sp_desembolso_atx
go
CREATE proc sp_desembolso_atx
   @s_ssn               int         	= null,
   @s_culture           varchar(10)		= 'NEUTRAL', 
   @s_date              datetime   		= null,
   @s_srv              	varchar(30)   	= null,
   @s_user              login   		= null,
   @s_term              descripcion   	= null,
   @s_ofi              	smallint   		= null,
   @s_rol              	smallint   		= null,
   @s_lsrv              varchar(30)   	= null,
   @s_sesn              int   			= null,
   @s_org              	char(1)   		= null,
   @t_trn               int        		= null,
   @t_ssn_corr          int        		= null,
   @t_corr				char(1)	   		= 'N',
   @i_operacion         char(1),
   @i_cliente           int        		= null,
   @i_ced_ruc           varchar(30)    	= null,
   @i_tipo_ced          char(4)    		= null,
   @i_banco             cuenta     		= null,
   @i_operacionca       int        		= null,
   @i_transaccion       int        		= null,
   @i_num_desembolso    int        		= null,
   @i_fecha_liq			datetime   		= null,
   @i_externo           char(1)    		= 'S',
   @i_en_linea          char(1)    		= 'S',
   @i_observacion       varchar(255) 	= '',
   @o_sec_trn           int        		= null out
     
as declare
   @w_sp_name            varchar(30),
   @w_error              int,
   @w_est_novigente      tinyint,
   @w_est_cancelado      tinyint,
   @w_est_anulado        tinyint,
   @w_est_credito        tinyint,
   @w_est_vigente        tinyint,
   @w_fpago_efectivo     catalogo,
   @w_producto           catalogo,
   @w_secuencial         int,
   @w_secuencial_act     int,     -- KDR Nuevo secuencial generado cuando se aplica un reverso de Desembolso
   @w_operacion          int,
   @w_desembolsos		 int,
   @w_fecha_actual		 datetime,
   @w_pagado             char(1),
   @w_estado_op          tinyint,
   @w_operacionca        int,
   @w_num_desembolso     tinyint,
   @w_num_dias_dispersion int,
   @w_fecha_liq          datetime,
   @w_fecha_liq_max      datetime,
   @w_error_tmp          int,      -- KDR 19/18/2022 Código de error temporal para sp_liquida 
   @w_tipo_grupal        char(1),
   @w_estago_grupal      tinyint
   
select @w_sp_name        = 'sp_desembolso_atx'

if @t_trn <> 77545 
begin        
   select @w_error = 141018 --Error en codigo de transaccion
   goto ERROR
end

--jmorocho
if @t_ssn_corr is null 
   select @t_ssn_corr = @s_ssn
   
select 	@w_fecha_actual = fc_fecha_cierre
from   	cobis..ba_fecha_cierre
where  	fc_producto = 7
   
create table #operaciones_car (
	operacionca 	int,
	banco       	cuenta,
	nombre      	descripcion,
	ced_ruc     	numero,
	tipo_ced		descripcion,
	tipo_producto	varchar(140),
	fecha_liq       datetime)

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
				@o_est_novigente  = @w_est_novigente out,
				@o_est_cancelado  = @w_est_cancelado out,
				@o_est_anulado    = @w_est_anulado   out,
				@o_est_credito    = @w_est_credito   out,
				@o_est_vigente    = @w_est_vigente   out

if @w_error <> 0 
	goto ERROR
	
select @w_num_dias_dispersion = pa_int 
from cobis..cl_parametro
where pa_nemonico = 'DHFDD'
and    pa_producto = 'CRE'
set transaction isolation level read uncommitted

--DETERMINA EL TIPO DE OPERACION 
EXEC @w_error = sp_tipo_operacion
    @i_banco  = @i_banco,
    @o_tipo   = @w_tipo_grupal out

if @i_operacion = 'C' begin			
	if @i_cliente is not null
	begin
	   insert 	into #operaciones_car
	   select 	op.op_operacion, op.op_banco, op.op_nombre, en.en_ced_ruc, en.en_tipo_ced, b.valor, op.op_fecha_liq 
	   from   	cob_cartera..ca_operacion op,
				cobis..cl_ente en,
				cobis..cl_tabla a,
				cobis..cl_catalogo b	
	   	WHERE 	a.codigo = b.tabla
	   	AND		b.codigo = op.op_toperacion
		AND		op.op_cliente = en.en_ente
		AND 	a.tabla = 'ca_toperacion'
	    and    	en.en_ente = @i_cliente
		and     op.op_estado  not in (@w_est_cancelado,@w_est_anulado,@w_est_credito)  --GFP 07/09/2022
	
	   if @@rowcount = 0 
	   begin
	      select @w_error = 701013 --No existe operacion activa de cartera
	      goto ERROR
	   end
	end
	else if @i_ced_ruc is not null AND @i_tipo_ced is not null
	begin
		insert 	into #operaciones_car
	   	select 	op.op_operacion, op.op_banco, op.op_nombre, en.en_ced_ruc, en.en_tipo_ced, b.valor, op.op_fecha_liq
	   	from   	cob_cartera..ca_operacion op,
				cobis..cl_ente en,
				cobis..cl_tabla a,
				cobis..cl_catalogo b
	   	WHERE 	a.codigo = b.tabla
		AND		b.codigo = op.op_toperacion
		AND		op.op_cliente = en.en_ente
		AND 	a.tabla = 'ca_toperacion'
	   	and    	en.en_ced_ruc = @i_ced_ruc
	   	and		en.en_tipo_ced = @i_tipo_ced
		and     op.op_estado  not in (@w_est_cancelado,@w_est_anulado,@w_est_credito)   --GFP 07/09/2022

	   if @@rowcount = 0 
	   begin
	      insert 	into #operaciones_car
	      select 	op.op_operacion, op.op_banco, op.op_nombre, ien.ie_numero, ien.ie_tipo_doc, b.valor, op.op_fecha_liq
		     from   	cob_cartera..ca_operacion op,
					cobis..cl_ident_ente ien,
					cobis..cl_tabla a,
					cobis..cl_catalogo b
			 WHERE 	a.codigo = b.tabla
			 AND	b.codigo = op.op_toperacion
			 AND	op.op_cliente = ien.ie_ente
			 AND 	a.tabla = 'ca_toperacion'
			 and    ien.ie_numero = @i_ced_ruc
			 and	ien.ie_tipo_doc =  @i_tipo_ced
			 and    op.op_estado  not in (@w_est_cancelado,@w_est_anulado,@w_est_credito)   --GFP 07/09/2022
			 
			 if @@rowcount = 0 
	         begin	 
	            select @w_error = 701013 --No existe operacion activa de cartera
	            goto ERROR
	         end
	   end		
	
	   
	end
	else if @i_operacionca is not null
	begin
	   	insert 	into #operaciones_car
		select 	op.op_operacion, op.op_banco, op.op_nombre, en.en_ced_ruc, en.en_tipo_ced, b.valor, op.op_fecha_liq   
	   	from   	cob_cartera..ca_operacion op,
				cobis..cl_ente en,
				cobis..cl_tabla a,
				cobis..cl_catalogo b			
		WHERE 	a.codigo = b.tabla
		AND		b.codigo = op.op_toperacion
		AND		op.op_cliente = en.en_ente
		AND 	a.tabla = 'ca_toperacion'   
	   	and  	op.op_operacion = @i_operacionca
		and     op.op_estado not in (@w_est_cancelado,@w_est_anulado,@w_est_credito)   --GFP 07/09/2022
		
	   if @@rowcount = 0 
	   begin
	      select @w_error = 701013 --No existe operacion activa de cartera
	      goto ERROR
	   end
	end
	else if @i_banco is not null
	BEGIN
	
     	insert 	into #operaciones_car
		select 	op.op_operacion, op.op_banco, op.op_nombre, en.en_ced_ruc, en.en_tipo_ced, b.valor, op.op_fecha_liq   
	   	from   	cob_cartera..ca_operacion op,
				cobis..cl_ente en,
				cobis..cl_tabla a,
				cobis..cl_catalogo b			
		WHERE 	a.codigo = b.tabla
		AND		b.codigo = op.op_toperacion
		AND		op.op_cliente = en.en_ente
		AND 	a.tabla = 'ca_toperacion'   
	   	and    	op.op_banco = @i_banco
		and     op.op_estado not in (@w_est_cancelado,@w_est_anulado,@w_est_credito)   --GFP 07/09/2022
		
	   if @@rowcount = 0 
	   begin
	      select @w_error = 701013 --No existe operacion activa de cartera
	      goto ERROR
	   END
	end				
	
	select @w_fpago_efectivo = ''+@w_fpago_efectivo +'%' 
	
	if @i_cliente is not null or (@i_ced_ruc is not null AND @i_tipo_ced is not null)
	BEGIN
		select 		'Operacion' 		= opc.banco,
					'TipoDesembolso' 	= opc.tipo_producto,
		   			'Cliente'   		= opc.nombre, 
		   			'DNI'       		= opc.ced_ruc, 
		   			'TipoIdentificacion'= opc.tipo_ced,
		   			
		   			'Monto' 			= dm.dm_monto_mds, 
					'MonedaDesembolso'  = dm.dm_moneda, 
				   	'FPago'     		= dm.dm_producto,
				   	'Beneficiario' 		= dm.dm_concepto, 
				   	'FechaIngreso' 		= opc.fecha_liq,--dm.dm_fecha_ingreso, 
				   	'SecOperacion' 		= dm.dm_operacion,
				   	'Transaccion'  		= dm.dm_secuencial, 
				   	'SecDesembolso'		= dm.dm_desembolso		   			   
		   from 	ca_desembolso dm, 
		   			#operaciones_car opc		   			
		   where  	dm.dm_operacion = opc.operacionca		   
		   and    	dm.dm_estado    = 'NA' -- desembolso no aplicado		   			   
	END	
	
	if @i_operacionca is not null or @i_banco is not null
	BEGIN
		select 		@w_desembolsos = count(1) 
		from 		ca_desembolso dm, 
				 	#operaciones_car opc,
					ca_producto pr
		where 		dm.dm_operacion = opc.operacionca
		and 		(@i_operacionca is null or opc.operacionca = @i_operacionca)
		and    		(@i_banco is null or opc.banco = @i_banco)
		and         dm_producto  = cp_producto
		and         cp_categoria = 'EFEC'
		
		if @w_desembolsos > 1
		begin
			select @w_error = 711088 --Prestamo con mas de un desembolso asociado
			goto ERROR
		end
		ELSE IF @w_desembolsos = 1
		BEGIN
			select 	'Operacion' 		= opc.banco,
					'TipoDesembolso' 	= opc.tipo_producto,			
		   			'Cliente'   		= opc.nombre, 
		   			'DNI'       		= opc.ced_ruc, 
		   			'TipoIdentificacion'= opc.tipo_ced,		   			
		   			'Monto' 			= dm.dm_monto_mds, 
					'MonedaDesembolso'  = dm.dm_moneda, 
				   	'FPago'     		= dm.dm_producto,
				   	'Beneficiario' 		= dm.dm_concepto, 
				   	'FechaIngreso' 		= opc.fecha_liq,--dm.dm_fecha_ingreso, 
				   	'SecOperacion' 		= dm.dm_operacion,
				   	'Transaccion'  		= dm.dm_secuencial, 
				   	'SecDesembolso'		= dm.dm_desembolso		   			   
		   from 	ca_desembolso dm,
		            ca_producto cp,
		   			#operaciones_car opc
		   where  	dm.dm_operacion = opc.operacionca
		   and    	dm.dm_producto  = cp.cp_producto
		   AND      cp.cp_categoria = 'EFEC'
		   --and    	dm.dm_estado    = 'NA' -- desembolso no aplicado
           and      'N'             = isnull(dm_pagado, 'N')		   
		END
		ELSE
		BEGIN
			select @w_error = 725164 --Esta operación renueva o refinancia prestamo(s) aun no cancelado(s). Favor consultar el estado del Trámite
       		goto ERROR
		END 				
	END
end

if @i_operacion = 'A'
BEGIN	
	if @i_banco is not null
	begin
	
		if exists(	select 	1
					from 	ca_operacion
					where 	op_ref_grupal is null
					and 	op_grupal = 'S'
					AND 	op_banco = @i_banco)
		begin
			select @w_error = 725300 --No es posible ejecutar la accion porque el cliente es propietario de cuenta grupal.
			goto ERROR			
		end
		
		--Validacion para proyecto ENLACE, por manejo de la activacion padre
		 select op_estado from ca_operacion where op_banco = op_ref_grupal 
		 if (@w_tipo_grupal = 'H')
		 begin
		    select @w_estago_grupal = op_estado 
			from ca_operacion 
			where op_banco = (select op_ref_grupal 
			                  from ca_operacion 
							  where op_banco = @i_banco)
							  
			if (@w_estago_grupal <> @w_est_cancelado)
			begin
			   select @w_error = 725301 --Error la operación grupal no ha sido activada.
			   goto ERROR			
		    end
		 end
		
		--GFP 07/09/2022 Validación de operación en estado no vigente y vigente
		if exists ( select 1 from ca_operacion where op_banco = @i_banco and op_estado not in (@w_est_novigente,@w_est_vigente))	
	    begin
	       select @w_error = 701013 --No existe operacion activa de cartera
	       goto ERROR
	    end
		
		select 		@w_desembolsos = count(1) 
		from 		ca_producto pr, ca_desembolso dm 
		left join 	ca_operacion op
		on 			dm.dm_operacion = op.op_operacion
		where 		op.op_banco     = @i_banco
		and         dm.dm_producto  = pr.cp_producto
		and         pr.cp_categoria = 'EFEC'
		
		if @w_desembolsos = 0 
		begin
			select @w_error = 725162 -- Error no existe forma de desembolso
			goto ERROR
		end
		ELSE IF @w_desembolsos = 1
		BEGIN 
			/* Se valida la moneda entre la operacion y el desembolso asociado*/
			if EXISTS (	select 		1
						from 		ca_desembolso dm 
						left join 	ca_operacion op
						on 			dm.dm_operacion = op.op_operacion
						where 		op.op_banco = @i_banco
						and	  		op.op_moneda = dm.dm_moneda
						--and	  		dm.dm_estado = 'NA'
						)
			BEGIN
			
				select @w_pagado         = isnull(dm_pagado,'N'),
					   @w_estado_op      = op_estado,
					   @w_operacionca    = op_operacion,
					   @w_secuencial     = dm_secuencial,
					   @w_num_desembolso = dm_desembolso,
					   @w_fecha_liq      = op_fecha_liq
				from ca_desembolso, ca_operacion, ca_producto
				where op_banco   = @i_banco
				and dm_operacion = op_operacion
				and dm_producto  = cp_producto
		        and cp_categoria = 'EFEC'		
				
				
				if @w_pagado = 'S'
				begin
					select @w_error = 725130 -- Error, la orden de desembolso ya ha sido pagada.
					goto ERROR
				end
				
				if  @w_estado_op = @w_est_novigente
				begin
				
				   exec @w_error      = sp_pasotmp
			       @s_term             = @s_term,
			       @s_user             = @s_user,
			       @i_banco            = @i_banco,
			       @i_operacionca      = 'S',
			       @i_dividendo        = 'S',
			       @i_amortizacion     = 'S',
			       @i_cuota_adicional  = 'S',
			       @i_rubro_op         = 'S',
			       @i_nomina           = 'S'   
			       
		           if @w_error <> 0  
			          goto ERROR
				   
                   --GFP 27/05/2021 Validación de días permitidos para desembolsar
				   select @w_fecha_liq_max = dateadd(dd,@w_num_dias_dispersion ,op_fecha_liq)
				   from ca_operacion 
				   where  op_banco   = @i_banco
				   
                   if (@w_fecha_liq > @w_fecha_liq_max )
                   begin					  
				      select @w_error = 725159 --ERROR: SE HA EXCEDIDO LA CANTIDAD DE DIAS PERMITIDOS PARA DESEMBOLSAR EL PRESTAMO APROBADO
			          goto ERROR
			       end
  
				   exec @w_error = cob_cartera..sp_liquida
				   @i_banco_ficticio 	= @i_banco, 
				   @i_banco_real		= @i_banco,
				   @i_carga			    = 0,
				   @i_fecha_liq		    = @w_fecha_liq, --  KDR Fecha liquidación registrada en tabla maestra de préstamos,
				   @i_prenotificacion	= 0,
				   @i_renovacion		= 'N',
				   @t_trn				= 7060,
				   @i_nom_producto		= 'CCA',
				   @i_externo           = 'N',          -- KDR Para no Manejo de atomicidad
				   @i_desde_cartera     = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
				   @o_banco_generado	= '0',
				   @s_date				= @w_fecha_actual,
				   @s_ofi				= @s_ofi,
				   @s_user				= @s_user,
				   @s_term				= @s_term,
				   @s_ssn				= @s_ssn
					
				   if @w_error <> 0
	                  goto ERROR
					  
				   select @w_error_tmp = @w_error
					   
				   exec @w_error = sp_borrar_tmp
			       @s_sesn   = @s_ssn,
			       @s_user   = @s_user,
			       @s_term   = @s_term,
			       @i_banco  = @i_banco
			        
			       if @w_error <> 0  
			          goto ERROR
					  
				   -- KDR 19/08/2021 Valida si el proceso de liquidación no mando error, y no vigenteo la operación.
				   if @w_error_tmp = 0 and exists (select 1 from ca_operacion
				                                   where op_banco = @i_banco
												   and op_estado <> @w_est_vigente)
				   begin
				      select @w_error = 725185 -- Error al completar la transacción. No se estableció estado Vigente a operación.
					  goto ERROR
				   end
				  
				end
				
				-- Marcar como pagado el desembolso
				exec @w_error = cob_cartera..sp_desembolso
				@i_operacion      = 'U',
				@i_opcion         = 1,
				@i_banco_real     = @i_banco,
				@i_banco_ficticio = @i_banco,
				@i_secuencial     = @w_secuencial,
				@i_desembolso     = @w_num_desembolso,
				@i_desde_cre      = 'N',
				@i_externo        = 'N',
				@i_pagado         = 'S',
				@s_ofi            = @s_ofi,
				@s_term           = @s_term,
				@s_user           = @s_user,
				@s_date           = @s_date
				
				if @w_error <> 0 
	                goto ERROR

				
				/*
				insert into ca_secuencial_atx (
				   sa_operacion ,      sa_ssn_corr ,     sa_producto,              sa_secuencial_cca,             
				   sa_secuencial_ssn,  sa_oficina,       sa_fecha_ing,             sa_fecha_real,
				   sa_estado,          sa_ejecutar,      sa_valor_efe,             sa_valor_cheq,
				   sa_error) 
				   select               
				   banco,        @t_ssn_corr,        dm_producto,      @w_secuencial,
				   isnull(@s_ssn,0),         dm_oficina, isnull(@s_date,''),          getdate(),
				   'A',                'S',       dm_monto_mop,                  0,
				   0
				   */
	              
			END
			/*ELSE IF EXISTS (select 		1
							from 		ca_desembolso dm 
							left join 	ca_operacion op
							on 			dm.dm_operacion = op.op_operacion
							where 		op.op_banco = @i_banco
							and	  		op.op_moneda = dm.dm_moneda
							and	  		dm.dm_estado = 'A')
			BEGIN
				select @w_error = 711089 --El prestamo se encuentra con desembolso aplicado
				goto ERROR
			END*/
			ELSE
			BEGIN
				select @w_error = 711090 --No se puede desembolsar con una moneda diferente al prestamo creado
				goto ERROR
			END 
		END
		ELSE IF @w_desembolsos > 1
		begin
			select @w_error = 711091 --No se puede desembolsar con mas de una forma de desembolso asociado
			goto ERROR
		end				
	end
	else
	begin
		select @w_error = 711101 -- El código de banco ingresado no existe
		goto ERROR
	end
END

if @i_operacion = 'R'
BEGIN
	if @i_banco is not null
	begin
		if EXISTS (	select 		1 
					from 		ca_desembolso dm 
					left join 	ca_operacion op
					on 			dm.dm_operacion = op.op_operacion
					where 		op.op_banco = @i_banco
					AND			dm.dm_estado = 'A')
		BEGIN
			select 		@w_secuencial     = dm_secuencial,
			            @w_num_desembolso = dm_desembolso,
						@w_operacionca    = op_operacion
			from 		ca_producto pr, ca_desembolso dm 
			left join 	ca_operacion op
			on 			dm.dm_operacion = op.op_operacion
			where 		op.op_banco = @i_banco
			and         dm.dm_producto  = pr.cp_producto
		    and         pr.cp_categoria = 'EFEC'
			
           if @@rowcount = 0 
		   begin
			  select @w_error = 725162 -- Error no existe forma de desembolso
			  goto ERROR
		   end
			
			-- KDR Validacion para que los canales no puedan reversar si el desembolso ya ha sido revertido por otro canal
			if EXISTS ( SELECT 		1
						FROM 		ca_transaccion 
						LEFT JOIN 	ca_operacion
						ON  		tr_operacion = op_operacion
						WHERE 		op_banco = @i_banco
						AND 		tr_tran = 'DES'
						AND 		tr_estado <> 'RV'
						AND 		tr_secuencial = @w_secuencial
						AND 		tr_fecha_mov = @s_date)
			BEGIN
			
			   select @w_pagado = dm_pagado 
			   from ca_desembolso 
			   where dm_operacion  = @w_operacionca 
			   and  dm_secuencial = @w_secuencial
			   
			   if (@w_tipo_grupal = 'H' and @w_pagado = 'S')
			   begin
			      -- Quitar marca de pagado el desembolso
				  exec @w_error = cob_cartera..sp_desembolso
				  @i_operacion      = 'U',
				  @i_opcion         = 1,
				  @i_banco_real     = @i_banco,
				  @i_banco_ficticio = @i_banco,
				  @i_secuencial     = @w_secuencial,  
				  @i_desembolso     = @w_num_desembolso,
				  @i_desde_cre      = 'N',
				  @i_externo        = 'N',
				  @i_pagado         = 'N',
				  @s_ofi            = @s_ofi,
				  @s_term           = @s_term,
				  @s_user           = @s_user,
				  @s_date           = @s_date
				  
				  if @w_error <> 0 
		             goto ERROR
			   end
			   else
			   begin
			   
				  exec @w_error = cob_cartera..sp_fecha_valor 								
				  			@s_srv			= @s_srv,
				  			@s_user			= @s_user,
				  			@s_term			= @s_term,
				  			@s_ofi			= @s_ofi,
				  			@s_rol			= @s_rol,
				  			@s_ssn			= @s_ssn,
				  			@s_lsrv			= @s_lsrv,
				  			@s_date			= @s_date,
				  			@s_sesn			= @s_sesn,
				  			@s_org			= @s_org,
				  			@t_trn			= 7049,
				  			@i_banco		= @i_banco,
				  			@i_secuencial	= @w_secuencial,
				  			@i_operacion	= @i_operacion,
				  			@i_observacion	= @i_observacion,
	                          @o_secuencial_act = @w_secuencial_act out
				  				
				  if @w_error <> 0 
		                goto ERROR
				  
				  -- Quitar marca de pagado el desembolso
				  exec @w_error = cob_cartera..sp_desembolso
				  @i_operacion      = 'U',
				  @i_opcion         = 1,
				  @i_banco_real     = @i_banco,
				  @i_banco_ficticio = @i_banco,
				  @i_secuencial     = @w_secuencial_act,  -- KDR Se actualiza el registro de desembolso según nuevo secuencial.
				  @i_desembolso     = @w_num_desembolso,
				  @i_desde_cre      = 'N',
				  @i_externo        = 'N',
				  @i_pagado         = 'N',
				  @s_ofi            = @s_ofi,
				  @s_term           = @s_term,
				  @s_user           = @s_user,
				  @s_date           = @s_date
				  
				  if @w_error <> 0 
		             goto ERROR
					  
			   end
			END
			ELSE
			BEGIN
				select @w_error = 725158 -- Error, el desembolso ya fue reversado
			END					
		END
		ELSE
		BEGIN 
			select @w_error = 141133 --Estado no valido para reverso
			goto ERROR
		END
	end
	else
	begin
		select @w_error = 711101 -- El código de banco ingresado no existe
		goto ERROR
	end
END


return 0


ERROR:
   if @i_en_linea = 'S'
   begin
      --if @@trancount > 0 rollback tran -- KDR Se delega la atomicidad a programa superior.
       if @i_externo = 'S' 
       begin
        exec cobis..sp_cerror 
        @t_debug = 'N',
        @t_file  = '',  
        @t_from  = @w_sp_name,
        @s_culture = @s_culture,
        @i_num   = @w_error
      end
   END
   
   return @w_error
 

GO
