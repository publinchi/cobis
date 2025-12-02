/*************************************************************************/
/*   Archivo:              cu_anulagar.sp                                */
/*   Stored procedure:     sp_cu_anula_garantia                          */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_cu_anula_garantia') IS NOT NULL
    DROP PROCEDURE dbo.sp_cu_anula_garantia
go
create procedure sp_cu_anula_garantia
	(
	@s_ssn                	int            	= null,
	@s_user               	login          	= null,
	@s_sesn               	int            	= null,
	@s_term               	varchar(30)    	= null,
	@s_date               	datetime       	= null,
	@s_srv                	varchar(30)    	= null,
	@s_lsrv               	varchar(30)    	= null,
	@s_rol                	smallint       	= NULL,
	@s_ofi                	smallint       	= NULL,
	@s_org_err            	char(1)        	= NULL,   
	@s_error              	int            	= NULL,
	@s_sev                	tinyint        	= NULL,
	@s_msg                	descripcion    	= NULL,
	@s_org                	char(1)        	= NULL,
	@t_rty                	char(1)        	= null,
	@t_trn                	smallint       	= null,
	@t_debug              	char(1)        	= 'N',
	@t_file               	varchar(14)    	= null,
	@t_from               	varchar(30)    	= null,
	@i_filial		int		= 1,
	@i_fecha_proceso	datetime	= null
	)
as



declare	@w_today		datetime,     /* fecha del dia */ 
	@w_return       	int,          /* valor que retorna */
   	@w_sp_name      	varchar(32),  /* nombre stored proc*/
   	@w_existe       	tinyint,      /* existe el registro*/
	@w_error              	int,
	@w_ssn                  int,
	@w_msj_err            	descripcion,    	
	@w_parameses		int,
	@w_tramite		int,
	@w_sucursal		smallint,
	@w_codigo_externo	varchar(64),
	@w_tipo			varchar(20),
	@w_moneda		tinyint,
	@w_custodia		int,
	@w_fecha_ingreso	datetime,
	@w_valor_inicial	money,
	@w_valor_actual		money,
	@w_descripcion		varchar(255),
	@w_abierta_cerrada	char(01),
	@w_oficina_contabiliza	smallint,
	@w_operacion		int,
	@w_estado		tinyint,
	@w_banco		cuenta,
	@w_filial		tinyint,
	@w_oficina	   	smallint,
	@w_ente 	   	int,
	@w_nombre 	   	varchar(100),
	@w_destipo	   	descripcion,
	@w_usuario_ingreso	descripcion,
	@w_des_estado		varchar(80),
	@w_transac		char(01),
	@w_fecha_anulada	datetime,
	@w_fecha_operacion	datetime,
	@w_fecha		datetime,
	@w_oficial		int,
	@w_nom_oficial		char(100)
	
select	@w_sp_name = 'sp_cu_anula_garantia'
	
truncate table cob_custodia..cu_tgar_anulada

truncate table cob_custodia..cu_tgar_operacion

create table #tmp_gar_anulada
	(
	ta_filial		tinyint		not null,
	ta_sucursal		smallint	not null,
	ta_tramite		int		not null,
	ta_oficina		smallint	not null,
	ta_ente			int		not null,
	ta_nombre		varchar(100)	not null,
	ta_custodia		int		not null,
	ta_tipo			descripcion	not null,
	ta_destipo		descripcion	not null,
	ta_fecha_ingreso	datetime	not null,
	ta_moneda		tinyint		not null,
	ta_oficial		int		null,
	ta_nom_oficial		char(100)	null,
	ta_valor_inicial	money		not null,
	ta_valor_actual		money		not null,
	ta_descripcion		varchar(255)	null,
	ta_usuario_ingreso	descripcion	not null,
	ta_codigo_externo	varchar(64)	not null,
	ta_estado		catalogo	not null,
	ta_abierta_cerrada	char(01)	null,
	ta_oficina_contabiliza	smallint	null
	)


--selecciono la cantidad de meses de la tabla parametros 
--para ejecutar el proceso de anulación de garantías 
select	@w_parameses = pa_tinyint
  from	cobis..cl_parametro
 where 	pa_producto = 'GAR' 
   and 	pa_nemonico = 'MEGP'


select	@w_fecha_anulada = max(isnull(ta_fecha_proceso, '01/01/1900'))
  from	cob_custodia..cu_tgar_anulada
 
select	@w_fecha_operacion = max(isnull(to_fecha_proceso, '01/01/1900'))
  from	cob_custodia..cu_tgar_operacion

if @w_fecha_anulada >= @w_fecha_operacion
	select	@w_fecha = @w_fecha_anulada
else
	select	@w_fecha = @w_fecha_operacion


if @i_fecha_proceso <= @w_fecha
 begin
 	select	@w_transac = 'N'
	select	@w_return  = 1
	select 	@w_error   = 999999
	select 	@w_msj_err = 'Fecha ya ha sido procesada (err:' + convert(varchar, @w_return) + ')'
	goto ERROR
 end


insert	into #tmp_gar_anulada
select	cu_filial 		as ta_filial,
	cu_sucursal 		as ta_sucursal,
	isnull(gp_tramite, 0) 	as ta_tramite,
	cu_oficina 		as ta_oficina,
	cg_ente 		as ta_ente,
	en_nomlar 		as ta_nombre,
	cu_custodia 		as ta_custodia,
	cu_tipo 		as ta_tipo,
	tc_descripcion 		as ta_destipo,
	cu_fecha_ingreso 	as ta_fecha_ingreso,
	cu_moneda 		as ta_moneda,
	cg_oficial 		as ta_oficial,
	isnull((
	select	fu_nombre
	  from	cobis..cl_funcionario fun
	 where	fun.fu_funcionario = cli.cg_oficial
	), '')			as ta_nom_oficial,
	cu_valor_inicial 	as ta_valor_inicial,
	cu_valor_actual 	as ta_valor_actual,
	cu_descripcion 		as ta_descripcion,
	cu_usuario_crea 	as ta_usuario_ingreso,
	cu_codigo_externo 	as ta_codigo_externo,
	cu_estado 		as ta_estado,
	cu_abierta_cerrada 	as ta_abierta_cerrada,
	cu_oficina_contabiliza 	as ta_oficina_contabiliza
  from	cob_custodia..cu_custodia
 inner	join cob_custodia..cu_cliente_garantia cli  on cg_custodia = cu_custodia
						and cg_codigo_externo = cu_codigo_externo
  left	join cob_credito..cr_gar_propuesta 	 on gp_garantia = cu_codigo_externo
						and gp_est_garantia = 'P'
 inner	join cobis..cl_ente	 		 on cg_ente = en_ente
 inner	join cob_custodia..cu_tipo_custodia	 on tc_tipo = cu_tipo
 where	cu_filial = @i_filial
   and	isnull(cu_fecha_ingreso, '') <> ''
   and	cu_estado = 'P'
   and	cu_tipo not in ('GARGPE')
   and	dateadd(mm, @w_parameses, cu_fecha_ingreso) <= @i_fecha_proceso


--declare c_garantia insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
declare c_garantia cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
select	ta_tramite,
	ta_sucursal,
	ta_codigo_externo,
	ta_tipo,
	ta_moneda,
	ta_custodia,
	ta_fecha_ingreso,
	ta_valor_inicial,
	ta_valor_actual,
	ta_descripcion,
	ta_abierta_cerrada,
	ta_oficina_contabiliza
  from	#tmp_gar_anulada
 order	by
	ta_tramite


open c_garantia

fetch c_garantia
into	@w_tramite,
	@w_sucursal,
	@w_codigo_externo,
	@w_tipo,
	@w_moneda,
	@w_custodia,
	@w_fecha_ingreso,
	@w_valor_inicial,
	@w_valor_actual,
	@w_descripcion,
	@w_abierta_cerrada,
	@w_oficina_contabiliza

--begin tran 
select	@w_transac = 'S'

while @@FETCH_STATUS != -1
 begin

	--Las garantías con tramite 0 se anulan directamente
	if @w_tramite = 0 
	 begin

            --LRC may.21.2008 Inicio
            if not exists (select 1
                             from cu_poliza
                            where po_codigo_externo = @w_codigo_externo
                              and po_estado_poliza  = 'V')
            begin
            --LRC may.21.2008 Fin

		exec @w_ssn = ADMIN...rp_ssn 1,2

		select	@w_tramite,
			@w_sucursal,
			@w_codigo_externo,
			@w_tipo,
			@w_moneda,
			@w_custodia,
			@w_fecha_ingreso,
			@w_valor_inicial,
			@w_valor_actual,
			--@w_descripcion,
			@w_abierta_cerrada,
			@w_oficina_contabiliza

		EXECUTE @w_return = cob_custodia..sp_custodia 
	      		@s_ssn                 = @w_ssn,
			@s_date                = @i_fecha_proceso,
      			@s_user                = @s_user,
	      		@s_sesn                = @s_sesn,
      			@s_term                = @s_term,
      			@s_ofi                 = @w_sucursal,
	      		@t_trn                 = 19091,
      			@i_operacion           = 'U',
      			@i_filial              = 1,
	      		@i_sucursal            = @w_sucursal,
      			@i_tipo                = @w_tipo,
      			@i_estado              = 'A',				--Anulaci½n de la Garant­a
	      		@i_moneda              = @w_moneda,
      			@i_custodia            = @w_custodia,
      			@i_parte               = 1,
	      		@i_fecha_ingreso       = @w_fecha_ingreso,
      			@i_valor_inicial       = @w_valor_inicial,
      			@i_valor_actual        = @w_valor_actual,
	      		@i_descripcion         = @w_descripcion,
      			@i_abierta_cerrada     = @w_abierta_cerrada,
      			@i_oficina_contabiliza = @w_oficina_contabiliza,
	      		@i_scoring	     = 'S'               

	    	if @w_return <> 0
    		 begin
    		     --LRC may.21.2008 Inicio
       		     --select @w_error = 999999
	       	     --select @w_msj_err = 'Error en llamada a sp_custodia [3] (err:' + convert(varchar, @w_return) + ')'
       		     --goto ERROR
       		     print 'Error en llamada sp_custodia [1]. Se inserta registro en tabla cu_tgar_operacion. Tramite ' + @w_tramite + '! Garantia ' + @w_codigo_externo + '!'
       		     goto SIGUIENTE
       		     --LRC may.21.2008 Fin
	    	 end 

                     --II CLMT 20150903
                     if exists (select 1 from cob_custodia..cu_tgar_anulada 
                                 where ta_tramite        = @w_tramite 
                                   and ta_codigo_externo = @w_codigo_externo
                               )
                        begin
                             print 'Registros duplicados y quedan fuera de anulacion ' + @w_tramite + '! ' + @w_codigo_externo + '!'
                             
                        end 
                     else
                       begin --FI CLMT 20150903	
				/* Adaptive Server has expanded all '*' elements in the following statement */ insert	into cob_custodia..cu_tgar_anulada
				select	@i_fecha_proceso,
					#tmp_gar_anulada.ta_filial, #tmp_gar_anulada.ta_sucursal, #tmp_gar_anulada.ta_tramite, #tmp_gar_anulada.ta_oficina, #tmp_gar_anulada.ta_ente, #tmp_gar_anulada.ta_nombre, #tmp_gar_anulada.ta_custodia, #tmp_gar_anulada.ta_tipo, #tmp_gar_anulada.ta_destipo, #tmp_gar_anulada.ta_fecha_ingreso, #tmp_gar_anulada.ta_moneda, #tmp_gar_anulada.ta_oficial, #tmp_gar_anulada.ta_nom_oficial, #tmp_gar_anulada.ta_valor_inicial, #tmp_gar_anulada.ta_valor_actual, #tmp_gar_anulada.ta_descripcion, #tmp_gar_anulada.ta_usuario_ingreso, #tmp_gar_anulada.ta_codigo_externo, #tmp_gar_anulada.ta_estado, #tmp_gar_anulada.ta_abierta_cerrada, #tmp_gar_anulada.ta_oficina_contabiliza                                                                               
				  from	#tmp_gar_anulada
				 where	ta_tramite        = @w_tramite
				   and	ta_codigo_externo = @w_codigo_externo
				   and	ta_custodia       = @w_custodia
	               end
	
            end --LRC may.21.2008 	
	 end
	else
	 begin
		--si las garantias con tramite <> 0 se verifica si la operacion está como 
		--anulada o cancelada para anular la garantía
		/*if exists (
			select	1
		 	  from	cob_cartera..ca_operacion
			 where	op_tramite = @w_tramite
			   and	op_estado in (3, 11)
			  )
		 begin*/
		 
		 if not exists(
		 	select	1
		 	  from	cob_credito..cr_gar_propuesta
		 	 inner	join cob_cartera..ca_operacion on op_tramite = gp_tramite
		 	 where	gp_garantia = @w_codigo_externo
		 	   and	op_estado not in (3, 11)
		 	   ) and exists (	
			select	1
			  from	cob_cartera..ca_operacion
			 where	op_tramite = @w_tramite )
                 --LRC may.21.2008 Inicio
                           and not exists (select 1
                                            from cu_poliza
                                          where po_codigo_externo = @w_codigo_externo
                                            and po_estado_poliza  = 'V')
                 --LRC may.21.2008 Fin
			 
		  begin

			exec @w_ssn = ADMIN...rp_ssn 1,2

			EXECUTE @w_return = cob_custodia..sp_custodia 
		      		@s_ssn                 = @w_ssn,
				@s_date                = @i_fecha_proceso,
      				@s_user                = @s_user,
		      		@s_sesn                = @s_sesn,
      				@s_term                = @s_term,
      				@s_ofi                 = @w_sucursal,
	      			@t_trn                 = 19091,
	      			@i_operacion           = 'U',
      				@i_filial              = 1,
	      			@i_sucursal            = @w_sucursal,
      				@i_tipo                = @w_tipo,
	      			@i_estado              = 'A',				--Anulaci½n de la Garant­a
		      		@i_moneda              = @w_moneda,
      				@i_custodia            = @w_custodia,
      				@i_parte               = 1,
		      		@i_fecha_ingreso       = @w_fecha_ingreso,
      				@i_valor_inicial       = @w_valor_inicial,
      				@i_valor_actual        = @w_valor_actual,
	      			@i_descripcion         = @w_descripcion,
	      			@i_abierta_cerrada     = @w_abierta_cerrada,
      				@i_oficina_contabiliza = @w_oficina_contabiliza,
	      			@i_scoring	     = 'S' 
	      			
	      		if @w_return <> 0
	    		 begin
	    		        --LRC may.21.2008 Inicio
	       			--select @w_error = 999999
		       		--select @w_msj_err = 'Error en llamada a sp_custodia [3] (err:' + convert(varchar, @w_return) + ')'
	       			--goto ERROR
	       			print 'Error en llamada sp_custodia [2]. Se inserta registro en tabla cu_tgar_operacion. Tramite ' + @w_tramite + '! Garantia ' + @w_codigo_externo + '!'
	       			goto SIGUIENTE
	       			--LRC may.21.2008 Fin
		    	 end 


                     --II CLMT 20150903
                     if exists (select 1 from cob_custodia..cu_tgar_anulada 
                                 where ta_tramite        = @w_tramite 
                                   and ta_codigo_externo = @w_codigo_externo
                               )
                        begin
                             print 'Registros duplicados y quedan fuera de anulacion ' + @w_tramite + '! ' + @w_codigo_externo + '!'
                             
                        end 
                     else
                       begin	 --FI CLMT 20150903					
				/* Adaptive Server has expanded all '*' elements in the following statement */ insert	into cob_custodia..cu_tgar_anulada
				select	@i_fecha_proceso,
					#tmp_gar_anulada.ta_filial, #tmp_gar_anulada.ta_sucursal, #tmp_gar_anulada.ta_tramite, #tmp_gar_anulada.ta_oficina, #tmp_gar_anulada.ta_ente, #tmp_gar_anulada.ta_nombre, #tmp_gar_anulada.ta_custodia, #tmp_gar_anulada.ta_tipo, #tmp_gar_anulada.ta_destipo, #tmp_gar_anulada.ta_fecha_ingreso, #tmp_gar_anulada.ta_moneda, #tmp_gar_anulada.ta_oficial, #tmp_gar_anulada.ta_nom_oficial, #tmp_gar_anulada.ta_valor_inicial, #tmp_gar_anulada.ta_valor_actual, #tmp_gar_anulada.ta_descripcion, #tmp_gar_anulada.ta_usuario_ingreso, #tmp_gar_anulada.ta_codigo_externo, #tmp_gar_anulada.ta_estado, #tmp_gar_anulada.ta_abierta_cerrada, #tmp_gar_anulada.ta_oficina_contabiliza                                                                               
				  from	#tmp_gar_anulada
				 where	ta_tramite        = @w_tramite
				   and	ta_codigo_externo = @w_codigo_externo
				   and	ta_custodia       = @w_custodia
		       end
		
		 end
		else
		 begin
		 
SIGUIENTE:	--LRC May.21.2008
			if exists (
				select	1
			 	  from	cob_cartera..ca_operacion
				 where	op_tramite = @w_tramite
				  )
			 begin
				
				select	@w_operacion  = op_operacion,
					@w_estado     = op_estado,
					@w_banco      = op_banco,
					@w_des_estado = es_descripcion
				  from	cob_cartera..ca_operacion
				 inner	join cob_cartera..ca_estado on op_estado = es_codigo
				 where	op_tramite = @w_tramite

			 end
			else
			 begin
				select	@w_operacion  = 0,
					@w_estado     = 0,
					@w_banco      = '',
					@w_des_estado = '' 
			 end
			
			--Se procede a guardar los datos de la operación en la tabla que
			--registra las garantías en estado proceso y que mantienen una operación
			--diferente de anulada o cancelada

			select	@w_filial 	   = ta_filial,
				@w_oficina	   = ta_oficina,
				@w_ente 	   = ta_ente, 
				@w_nombre 	   = ta_nombre,
				@w_destipo	   = ta_destipo,
				@w_usuario_ingreso = ta_usuario_ingreso,
				@w_oficial	   = ta_oficial,
				@w_nom_oficial	   = ta_nom_oficial
			  from	#tmp_gar_anulada
			 where	ta_tramite        = @w_tramite
			   and	ta_codigo_externo = @w_codigo_externo

                        ---II: WVP[27/Ago/2015] validar duplicados 

                     if exists (select 1 from cu_tgar_operacion 
                                 where to_tramite = @w_tramite 
                                   and to_codigo_externo = @w_codigo_externo
                                   and to_operacion  = @w_operacion )

                         print 'Registros duplicados y quedan fuera ' + @w_tramite + '! ' + @w_codigo_externo + '! ' + @w_operacion + '!'

                     else

			insert	cu_tgar_operacion
				(
				to_fecha_proceso,
				to_filial,
				to_tramite,
				to_oficina,
				to_ente,
				to_nombre,
				to_custodia,
				to_tipo,
				to_destipo,
				to_fecha_ingreso,
				to_oficial,
				to_nom_oficial,
				to_valor_actual,
				to_descripcion,
				to_usuario_ingreso,
				to_codigo_externo,
				to_estado,
				to_des_estado,
				to_operacion,
				to_banco
				)
			values	(
				@i_fecha_proceso,
				@w_filial,
				@w_tramite,
				@w_oficina,
				@w_ente,
				@w_nombre,
				@w_custodia,
				@w_tipo,
				@w_destipo,
				@w_fecha_ingreso,
				@w_oficial,
				@w_nom_oficial,
				@w_valor_actual,
				@w_descripcion,
				@w_usuario_ingreso,
				@w_codigo_externo,
				@w_estado,
				@w_des_estado,
				@w_operacion,
				@w_banco
				)
		 end
		
	 end

	fetch c_garantia
	into	@w_tramite,
		@w_sucursal,
		@w_codigo_externo,
		@w_tipo,
		@w_moneda,
		@w_custodia,
		@w_fecha_ingreso,
		@w_valor_inicial,
		@w_valor_actual,
		@w_descripcion,
		@w_abierta_cerrada,
		@w_oficina_contabiliza


 end
close c_garantia
deallocate c_garantia

--commit tran 

return 0

ERROR:

   if @w_transac = 'S'
   	--rollback tran 

   exec cobis..sp_cerror
   @t_debug= 'N',    
   @t_file = NULL,
   @t_from = @w_sp_name,   
   @i_num  = @w_error,
   @i_msg  = @w_msj_err  

   return @w_error
go