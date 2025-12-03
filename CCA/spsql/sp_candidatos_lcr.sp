/************************************************************************/
/*  Archivo:                sp_candidatos_lcr.sp                        */
/*  Stored procedure:       sp_candidatos_lcr                           */
/*  Base de Datos:          cob_cartera                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           P. Ortiz                                    */
/*  Fecha de Documentacion: 15/Ago/2017                                 */
/************************************************************************/
/*          IMPORTANTE                                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA",representantes exclusivos para el Ecuador de la            */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de MACOSA o su representante                  */
/************************************************************************/
/*          PROPOSITO                                                   */
/* Permite actualizar un Prospecto a Cliente de forma automática        */
/* siempre que este cumpla con el ingreso de cada modulo                */
/************************************************************************/
/*          MODIFICACIONES                                              */
/*  FECHA       AUTOR                   RAZON                           */
/*  15/Ago/2017 P. Ortiz             Emision Inicial                    */
/*  23/Ago/2017 P. Ortiz             Corregir excepcion                 */
/*  06/Sep/2017 P. Ortiz             Agregar Conyuge y Listas Negras    */
/*  06/Sep/2017 P. Ortiz             Agregar Seccion Documentos Digit   */
/* **********************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_candidatos_lcr')
	drop proc sp_candidatos_lcr
go

create proc sp_candidatos_lcr (
   @s_ssn             int         = null,
   @s_user            login       = null,
   @s_term            varchar(32) = null,
   @s_date            datetime    = null,
   @s_sesn            int         = null,
   @s_culture         varchar(10) = null,
   @s_srv             varchar(30) = null,
   @s_lsrv            varchar(30) = null,
   @s_ofi             smallint    = null,
   @s_rol             smallint    = NULL,
   @s_org_err         char(1)     = NULL,
   @s_error           int         = NULL,
   @s_sev             tinyint     = NULL,
   @s_msg             descripcion = NULL,
   @s_org             char(1)     = NULL,
   @t_debug           char(1)     = 'N',
   @t_file            varchar(10) = null,
   @t_from            varchar(32) = null,
   @t_trn             int         = null,
   @t_show_version    bit         = 0,
   @i_operacion       char(1),
   @i_fecha_ing       datetime    = null,
   @i_grupo           int         = null,
   @i_cliente         int         = null,
   @i_periodicidad    varchar(10) = null,
   @i_accion          char(1)     = null,
   @i_asesor_reasig   int         = null,
   @i_descripcion     varchar(600)= null
)as
declare 
   @w_ts_name         varchar(32),
   @w_sp_name         varchar(32),
   @w_return          int,
   @w_error           int,
   @w_user            login,
   @w_oficina         int,
   @w_periodicidad    varchar(10),
   @w_accion          char(1),
   @w_subtipo         char(1),
   @w_asesor          login,
   @w_asesor_reasig   login,
   @w_asesor_ini      login,
   @w_fecha_proceso   datetime,
   @w_dias_post       smallint,
   @w_rol_sup         tinyint,
   @w_estado_jefe     char(1),
   @w_ofi_lcr         int,
   @w_ofi_gerente     int,
   @w_fecha_liq       datetime,
   @w_fecha_ven       datetime,
   @w_monto           money,
   @w_cliente         int,
   @w_toperacion      varchar(10),
   @w_moneda          tinyint,
   @w_destino         varchar(10),
   @w_ciudad          int,
   @w_tipo            char(1),
   @w_tramite_out     int,
   @w_inst_proc       int,
   @w_commit          char(1),
   @w_ced_ruc         varchar(30),
   @w_oficial         int


select @w_sp_name = 'sp_candidatos_lcr'

   -- Validar codigo de transacciones --
if ((@t_trn <> 1719 and @i_operacion = 'Q') or
    (@t_trn <> 1720 and @i_operacion = 'O') or
    (@t_trn <> 1721 and @i_operacion = 'U') or
    (@t_trn <> 1722 and @i_operacion = 'A'))
begin
   select @w_error = 151051 --Transaccion no permitida
   goto ERROR
end

/* OBTENCION DE DATA */
--Sacar oficina del asesor
select @w_oficina = fu_oficina from cobis..cl_funcionario where fu_login = @s_user
--Fecha Proceso
select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
--Dias para porsponer
select @w_dias_post = pa_smallint from cobis..cl_parametro where pa_nemonico = 'DPC' and pa_producto = 'CCA'
--Coordinardor
select @w_rol_sup = ro_rol from cobis..ad_rol where ro_descripcion = 'COORDINADOR'
--Oficina Defecto Pantalla de Autorizar Promocion LCR
select @w_ofi_lcr = pa_smallint from cobis..cl_parametro where pa_nemonico = 'OFILCR'

if @i_operacion = 'Q'
begin
	
	update cob_cartera..ca_lcr_candidatos set
		cc_promocion = null,
		cc_user      = null,
		cc_date      = null
	where datediff(dd,cc_date,@w_fecha_proceso) >= @w_dias_post
	
	if(@s_rol = @w_rol_sup)
	begin
		
		select 	@w_estado_jefe 	= fu_estado,
				@w_user 		= fu_login
		from cobis..cl_funcionario
		where fu_funcionario = (select fu_jefe from cobis..cl_funcionario 
									where fu_login = @s_user)
		
		if(@w_estado_jefe = 'V')
		begin
			select @w_user = null
		end
	end
	else
	begin
		select @w_user = @s_user
	end 
	
	select 'fechaIngreso'      = convert(varchar,cc_fecha_ing, 103),
			'fechaDispersion'    = convert(varchar,cc_fecha_liq, 103),
			'oficinaAsignadaId'  = cc_oficina,
			'oficinaAsignada'    = of_nombre,
			'grupoId'            = cc_grupo,
			'grupoNombre'        = gr_nombre,
			'enteId'             = cc_cliente,
			'enteNombre'         = isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'') + ' ' +  isnull(en_nombre,'') ,
			'asesorAsignadoId'   = fu_funcionario,
			'asesorAsignado'     = fu_nombre,
			'asesorReasignado'   = (select fu_funcionario from cobis..cl_funcionario where fu_login = cc_asesor_asig),
			'asesorReasignadoId' = (select fu_nombre from cobis..cl_funcionario where fu_login = cc_asesor_asig),
			'periodicidad'       = cc_periodicidad,
			'descripcion'        = cc_descripcion
	from cob_cartera..ca_lcr_candidatos, cobis..cl_grupo, cobis..cl_ente,
			cobis..cl_funcionario, cobis..cl_oficina
	where gr_grupo   = cc_grupo
	and   cc_cliente = en_ente
	and   fu_login   = cc_asesor
	and   of_oficina = cc_oficina
	and   cc_gerente = @w_user
	and   cc_promocion is null
	
end


--Catalogo de asesores
if @i_operacion = 'O'
begin
	
	select 	'codigo' 	= fu_funcionario,
			'nombre'	= fu_nombre,
			'login'		= fu_login,
			'oficina'	= fu_oficina,
			'estado'	= fu_estado
	from cobis..cl_funcionario, cobis..cc_oficial, cobis..ad_usuario_rol
	where fu_oficina = @w_oficina
	and   oc_funcionario = fu_funcionario
	and   fu_login = ur_login
	and   ur_rol in (select ro_rol from cobis..ad_rol where ro_descripcion in ('ASESOR MOVIL'))
	and   fu_estado  = 'V'
	
end


--Actualizar
if @i_operacion = 'U'
begin
	
	select	@w_asesor = fu_funcionario
	from cob_cartera..ca_lcr_candidatos, cobis..cl_funcionario
	where cc_fecha_ing = @i_fecha_ing
	and   cc_grupo     = @i_grupo
	and   cc_cliente   = @i_cliente
	and   cc_asesor    = fu_login
	
	if @i_asesor_reasig = @w_asesor
	begin
		select @w_error = 710606 --ERROR, NO SE PUEDE REASIGNAR CON EL ASESOR SUGERIDO
		goto ERROR
	end
	
	if @i_asesor_reasig = 0
		select @w_asesor_reasig = null
	else if @i_asesor_reasig is not null
		select @w_asesor_reasig = fu_login from cobis..cl_funcionario where fu_funcionario = @i_asesor_reasig
	
	update cob_cartera..ca_lcr_candidatos set
		cc_periodicidad = @i_periodicidad,
		cc_asesor_asig  = @w_asesor_reasig,
		cc_descripcion  = @i_descripcion
	where cc_fecha_ing = @i_fecha_ing
	and   cc_grupo     = @i_grupo
	and   cc_cliente   = @i_cliente
	
	if @@error <> 0
    begin
		select @w_error = 710601 --ERROR AL ACTUALIZAR!
		goto ERROR
    end
	
end

--Acciones (Autorizar, Descartar, Posponer)
if @i_operacion = 'A'
begin
	
	select	@w_accion 	  = cc_promocion,
			@w_asesor 		  = cc_asesor,
			@w_asesor_reasig = cc_asesor_asig,
			@w_periodicidad  = cc_periodicidad,
			@w_fecha_ven     = cc_fecha_liq
	from cob_cartera..ca_lcr_candidatos
	where cc_fecha_ing = @i_fecha_ing
	and   cc_grupo     = @i_grupo
	and   cc_cliente   = @i_cliente
	
	
	if @i_accion is not null
	    select @w_accion = @i_accion
	
	if(@i_accion = 'A')
	begin
		
		select @w_subtipo = en_subtipo from cobis..cl_ente 
		where en_ente = @i_cliente
		
		if @w_asesor_reasig is not null
			select @w_asesor_ini = @w_asesor_reasig
		else if @w_asesor is not null 
			select @w_asesor_ini = @w_asesor
		
		if (@w_asesor_ini is null)
		begin
			select @w_error = 710602 --Se debe definir Asesor para iniciar el flujo!
			goto ERROR
		end
		
		if (@w_periodicidad is null)
		begin
			select @w_error = 710603 --Se debe definir periodicidad para iniciar el flujo!
			goto ERROR
		end
		
		--Oficina asesor de Inicio
		select @w_oficina = fu_oficina from cobis..cl_funcionario 
		where fu_login = @w_asesor_ini
		
		--Oficina de Gerente logeado
		select @w_ofi_gerente = fu_oficina from cobis..cl_funcionario 
		where fu_login = @s_user
		
		if(@w_ofi_gerente <> @w_oficina)
		begin
			select @w_error = 710608 --La oficina del asesor es diferente a la de gerente, por favor regularice!
			goto ERROR
		end
		
		select @w_oficial = oc_oficial 
		from   cobis..cc_oficial, cobis..cl_funcionario
		where  oc_funcionario = fu_funcionario
		and    fu_login = @w_asesor_ini
		
		-- VALIDAR EXSITENCIA DE OFICIALES
		if not exists(select 1 from cobis..cc_oficial, cobis..cl_funcionario where oc_funcionario = fu_funcionario 
		     and oc_oficial = @w_oficial)
		begin
			select @w_error = 151091 -- NO EXISTE OFICIAL
			--select @w_msg = 'No existe oficial: ' + convert(varchar, @w_oficial)
			goto ERROR
		end
		
		if @@trancount = 0
		begin
			select @w_commit = 'S'
			begin tran
		end
		
		exec @w_error = cob_workflow..sp_inicia_proceso_wf 
		@t_trn = 73506,
		@i_login = @w_asesor_ini,
		@i_id_proceso = 5,
		@i_campo_1 = @i_cliente,
		@i_campo_3 = 0,
		@i_campo_4 = 'REVOLVENTE',
		@i_campo_5 = 0,
		@i_campo_6 = 0.00,
		@i_campo_7 = @w_subtipo,
		@i_ruteo = 'M',
		@i_id_empresa = 1,
		@i_ofi_inicio = @w_ofi_lcr,
		@i_canal = 0,
		@o_siguiente = @w_inst_proc out, -- LGU obtener la instancia de proceso
		@o_siguiente_alterno = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
		@s_srv = @s_srv,
		@s_user = @s_user,
		@s_term = @s_term,
		@s_ofi = @w_oficina,
		@s_rol = @s_rol,
		@s_ssn = @s_ssn,
		@s_lsrv = @s_lsrv,
		@s_date = @s_date,
		@s_sesn = @s_sesn,
		@s_org = @s_org,
		@s_culture = @s_culture
		
		if ((@@error <> 0) or (@w_error <> 0))
		begin
			goto ERROR
		end
		
		/* Informacion para crear el tramite */
		
		select @w_tipo = 'O'
		select @w_toperacion = 'REVOLVENTE'
		select @w_monto = 0.0
		select @w_destino = 1
		
		--Ciudad
		select @w_ciudad = of_ciudad from cobis..cl_oficina where of_oficina = @w_oficina
		--Moneda
		select @w_moneda = pa_tinyint from cobis..cl_parametro where pa_nemonico = 'CMNAC'
		
		--///////////////////////////////
		--CREA TRAMITE
		--///////////////////////////////
		begin try 
			print 'Antes de crear tramite'
			
			print 'INICIA PRINTS'
			Print '@w_tipo ' + convert(varchar,@w_tipo)
			Print '@w_oficina ' + convert(varchar,@w_oficina)
			Print '@w_fecha_ven ' + convert(varchar,@w_fecha_ven)
			Print '@w_asesor_ini ' + convert(varchar,@w_asesor_ini)
			Print '@w_oficial ' + convert(varchar,@w_oficial)
			Print '@w_ciudad ' + convert(varchar,@w_ciudad)
			Print '@w_toperacion ' + convert(varchar,@w_toperacion)
			Print '@w_monto ' + convert(varchar,@w_monto)
			Print '@w_moneda ' + convert(varchar,@w_moneda)
			Print '@w_destino ' + convert(varchar,@w_destino)
			Print '@i_cliente ' + convert(varchar,@i_cliente)
			Print '@w_periodicidad ' + convert(varchar,@w_periodicidad)
			Print '@s_user ' + convert(varchar,@s_user)
			Print '@s_ssn ' + convert(varchar,@s_ssn)
			Print '@w_fecha_proceso ' + convert(varchar,@w_fecha_proceso)
			Print '@s_sesn ' + convert(varchar,@s_sesn)
			print 'FINALIZA PRINTS'
			 
			exec @w_error = cob_credito..sp_tramite_cca 
				@i_tipo				= @w_tipo,
				@i_oficina_tr		= @w_oficina,
				@i_fecha_crea		= @w_fecha_ven,
				@i_oficial			= @w_oficial,
				@i_sector			= 'S',
				@i_ciudad			= @w_ciudad,
				@i_toperacion		= @w_toperacion,
				@i_producto			= 'CCA',
				@i_monto			   = @w_monto,
				@i_moneda			= @w_moneda,
				@i_destino			= @w_destino,
				@i_ciudad_destino	= @w_ciudad,
				@i_cliente			= @i_cliente,
				@i_tplazo_lcr		= @w_periodicidad,
				@i_operacion		= 'I',
				@o_tramite			= @w_tramite_out out,
				@s_user				= @s_user,
				@s_term				= @s_term,
				@s_ofi				= @s_ofi,
				@s_ssn				= @s_ssn,
				@s_lsrv				= @s_lsrv,
				@s_date				= @w_fecha_proceso
		
		end try
		begin catch 
		if @w_error <> 0 or @@error <> 0
		begin
			goto ERROR
		end
		end catch 
		
		-- POV-ini. generar el XML
		--Tramite
		update cob_workflow..wf_inst_proceso 
		set io_campo_3 = @w_tramite_out
		where io_id_inst_proc = @w_inst_proc
		
		select @w_inst_proc = io_id_inst_proc from cob_workflow..wf_inst_proceso where io_campo_3 = @w_tramite_out
		if @@rowcount = 0
		begin
		  select @w_error = 710601 -- ERROR EN ACTUALIZACION
		  --select @w_msg = 'No existe informacion para esa instancia de proceso'
		  goto ERROR
		end
		
		--Extraer ruc
		select @w_ced_ruc = en_ced_ruc from cobis..cl_ente where en_ente = @i_cliente
		
		if not exists (select 1 from cob_credito..cr_deudores where de_tramite = @w_tramite_out) 
		begin
			insert into cob_credito..cr_deudores
			select @w_tramite_out, @i_cliente, 'D', @w_ced_ruc, null, 'S'
			if @@error <> 0
			begin
			  select @w_error = 150000 -- ERROR EN INSERCION
			  goto ERROR
			end 
		end
		else
		begin
			update cob_credito..cr_deudores set 
			de_cliente = @w_cliente, 
			de_rol     = 'G',
			de_ced_ruc = null , 
			de_segvida = null, 
			de_cobro_cen = 'N'
			where de_tramite = @w_tramite_out
			if @@error <> 0
			begin
			  select @w_error = 710601 -- ERROR EN ACTUALIZACION
			  goto ERROR
			end
		end
		
		/* Rutear actividad */
		exec @w_error = cob_cartera..sp_ruteo_actividad_wf
		@s_ssn     		   =  @s_ssn, 
		@s_user            =  @w_user,
		@s_sesn            =  @s_sesn,
		@s_term            =  'consola',
		@s_date            =  @w_fecha_proceso,
		@s_srv             =  'srv',
		@s_lsrv            =  'lsrv',
		@s_ofi             =  @w_oficina,
		@i_tramite     	   =  @w_tramite_out,
		@i_param_etapa     =  'ETINGR',
		@i_pa_producto     =  'CRE'
		
		if ((@@error <> 0) or (@w_error <> 0))
		begin
		  goto ERROR
		end
		
		
		if @w_commit = 'S'
		begin
			commit tran  -- Fin atomicidad de la transaccion
			select @w_commit = 'N'
		end

	end
	
	if @i_accion = 'P'
	begin
		update cob_cartera..ca_lcr_candidatos set
			cc_descripcion = null
		where cc_fecha_ing = @i_fecha_ing
		and   cc_grupo     = @i_grupo
		and   cc_cliente   = @i_cliente
	end
	
	select @w_fecha_proceso = dateadd(mi, datepart(mi,getdate()),@w_fecha_proceso)
	select @w_fecha_proceso = dateadd(hh, datepart(hh,getdate()),@w_fecha_proceso)
	
	update cob_cartera..ca_lcr_candidatos set
		cc_promocion = @w_accion,
		cc_user 	 = @s_user,
		cc_date 	 = @w_fecha_proceso
	where cc_fecha_ing = @i_fecha_ing
	and   cc_grupo     = @i_grupo
	and   cc_cliente   = @i_cliente
	
	if @@error <> 0
	begin
		select @w_error = 710605 --ERROR AL ACTUALIZAR ACCION!
		goto ERROR
	end
	
	goto fin
end


goto fin
--Control errores
ERROR:
	if @w_commit = 'S'
	begin
		rollback tran
		select @w_commit = 'N'
	end
	
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return @w_error

fin:
   return 0

go

