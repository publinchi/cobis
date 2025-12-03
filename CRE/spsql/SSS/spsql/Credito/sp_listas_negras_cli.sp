/**************************************************************************/
/*  Archivo:                    sp_listas_negras_cli.sp                	  */
/*  Stored procedure:           sp_listas_negras_cli                      */
/*  Base de Datos:              cob_credito                               */
/*  Producto:                   Credito                                   */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada; y por lo tanto, derivará en acciones legales civiles        */
/*   y penales en contra del infractor según corresponda.”.               */
/**************************************************************************/
/*                          PROPOSITO                                     */
/*  Este stored procedure permite validar y rutear en la comprobacion de  */
/*  listas negras       					                              */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA          AUTOR                            RAZON                 */
/*  09/Nov/2021   Dilan Morales           implementacion                  */
/*  25/Abr/2022   Dilan Morales           Se corrige espacios en nombres  */
/*										  y apellidos					  */
/*  14/Nov/2023   Dilan/Bruno             R219332:Generar ID unico en     */
/*                                        copia                           */
/**************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_listas_negras_cli' and type = 'P' )
    drop proc sp_listas_negras_cli
go


create proc sp_listas_negras_cli
(
  		@s_ssn                int         = null,
        @s_user                   varchar(30) = null,
        @s_sesn                   int         = null,
        @s_term                   varchar(30) = null,
        @s_date                   datetime    = null,
        @s_srv                    varchar(30) = null,
        @s_lsrv                   varchar(30) = null,
        @s_rol                    smallint    = null,
        @s_ofi                    smallint    = null,
        @s_org_err                char(1)     = null,
        @s_error                  int         = null,
        @s_sev                    tinyint     = null,
        @s_msg                    descripcion = null,
        @s_org                    char(1)     = null,
        @t_rty                    char(1)     = null,
        @t_trn                    int         = null,
        @t_debug                  char(1)     = 'N',
        @t_file                   varchar(14) = null,
        @t_from                   varchar(30) = null,
        @i_id_inst_proc           int,                 -- codigo de instancia del proceso
        @i_id_inst_act            int,                 -- codigo de instancia de actividad
        @i_id_asig_act            int,                 -- codigo de asignacion de actividad
        @i_id_empresa             int,                 -- codigo de empresa
        @i_id_variable            smallint             -- codigo de variable
)
as
declare
        @w_sp_name          	  varchar (30),
        @w_error            	  int,
        @w_tramite          	  int,
  		@w_asig_actividad         int,
        @w_valor_ant              varchar(255),
        @w_valor_nuevo            varchar(255),
        @w_edad                   int,
        @w_grupo                  int,
        @w_count                  int,
        @w_ente                   int,
        @w_spid                   int,
        @w_vb_codigo_var_cli      int,
        @w_vb_codigo_var_cyg      int,
        @w_vb_codigo_var_gar      int,
        @w_return                 int,
        @w_code_rule              int,
        @w_version                int,
        @w_return_value           varchar(25),
        @w_return_code            int,
        @w_last_condition_parent  int,
        @w_valor                  varchar(255),
        @w_tramit_id              int,
        @w_id_integrante		  int,
        @w_nombre		  		  varchar(50),
        @w_tipo_documento		  varchar(50),
        @w_numero_documento		  varchar(50),
        @w_coincidencias_log	  int,
        @w_coincidencias_rfe	  int,
        @w_valor_rfe			  int,
        @w_max_fecha			  smalldatetime,
        @w_primer_nombre		  varchar(50),
		@w_segundo_nombre		  varchar(50),
		@w_primer_apellido		  varchar(50),
		@w_segundo_apellido		  varchar(50),
		@w_apellido_casado		  varchar(50),
		@w_nombres			  	  varchar(255),
		@w_apellidos			  varchar(255),
		@w_fecha_nacimiento       varchar(10),
		@w_user_name              varchar(50),
		@w_tipo_cliente		      char(1),
		@w_id_cobis               varchar(51)
    declare @w_tabla_usuarios as table(id				int,
								  primer_nombre 	varchar(50),
								  segundo_nombre 	varchar(50),
								  primer_apellido	varchar(50),
								  segundo_apellido	varchar(50),
								  apellido_casado  	varchar(50),
								  fecha_nacimiento	varchar(10),
								  tipo_documento	varchar(50),
								  numero_documento	varchar(50),
								  user_name			varchar(50),
								  accuracy			tinyint,
								  country			varchar(50),
								  tipo_cliente		char(1))


	select @w_coincidencias_rfe = 0

	insert into @w_tabla_usuarios exec cob_credito..sp_consulta_usuarios_cr @i_id_inst_proc = @i_id_inst_proc ,
																			@i_operacion	= 'Q'

	declare cur_integrantes cursor for select 	id ,				primer_nombre,		segundo_nombre,
												primer_apellido,	segundo_apellido,	apellido_casado,
												tipo_documento ,	numero_documento,   fecha_nacimiento,
                                                user_name,          tipo_cliente
	from  @w_tabla_usuarios


	open cur_integrantes
	fetch cur_integrantes
	into 	@w_id_integrante	,	@w_primer_nombre,		@w_segundo_nombre	,
			@w_primer_apellido,		@w_segundo_apellido	,	@w_apellido_casado	,
			@w_tipo_documento,		@w_numero_documento,    @w_fecha_nacimiento,
            @w_user_name,           @w_tipo_cliente


	while(@@fetch_status = 0)
	begin
        if(@w_user_name is null)
		begin
			select @w_user_name = @s_user
		end
		
		if(@w_primer_nombre is not null)
			select @w_nombres = trim(@w_primer_nombre)+ ' '
		if(@w_segundo_nombre is not null)
			select @w_nombres = isnull(@w_nombres, '') + trim(@w_segundo_nombre)


		if(@w_primer_apellido is not null)
			select @w_apellidos = trim(@w_primer_apellido)+ ' '
		if(@w_segundo_apellido is not null)
			select @w_apellidos = isnull(@w_apellidos, '') + trim(@w_segundo_apellido) + ' '
		if(@w_apellido_casado is not null)
			select @w_apellidos = isnull(@w_apellidos, '') + trim(@w_apellido_casado)

		select @w_nombres = trim(@w_nombres)
		select @w_apellidos = trim(@w_apellidos)

		SELECT @w_coincidencias_log =  count(*) FROM cobis..cl_listas_negras_log
		where 	ln_codigo_cliente = @w_id_integrante
				and ln_tipo_documento = @w_tipo_documento
				and ln_numero_documento = @w_numero_documento
				and ln_nro_proceso = @i_id_inst_proc
				and trim(isnull(ln_nombre,'')) = @w_nombres
				and trim(isnull(ln_apellido,'')) = @w_apellidos


		if(@w_coincidencias_log = 0)
		begin
            set @w_id_cobis = 'COBIS-' + CONVERT(VARCHAR, @w_id_integrante) + '-' + convert(varchar, @s_ssn) --Id verificacion generado

		    insert into  cobis..cl_listas_negras_log
			(ln_fecha_consulta, ln_usuario, ln_id_verificacion, ln_numero_coincidencias, ln_nombre, ln_apellido, ln_tipo_documento, ln_numero_documento, ln_fecha_nacimiento, ln_codigo_cliente, ln_nro_proceso)
			values
		    (getdate(), @w_user_name, @w_id_cobis, -4, @w_nombres , @w_apellidos, @w_tipo_documento, @w_numero_documento , @w_fecha_nacimiento, @w_id_integrante , @i_id_inst_proc)
			if @@error != 0
			begin
				/* Error en insercion de registro */
				select @w_error = 2110429
				goto ERROR
			end
            if not exists(select 1 from cobis..cl_listas_negras_rfe where ne_codigo_cliente = @w_id_integrante and ne_nro_proceso = @i_id_inst_proc)
			begin
				insert into cobis..cl_listas_negras_rfe
				(ne_id_verificacion, ne_coincidencia, ne_nombre, ne_apellido, ne_tipo_persona, ne_codigo_cliente, ne_nro_proceso, ne_justificacion, ne_estado_resolucion, ne_fecha_resolucion, ne_nro_aml)
				values
				(@w_id_cobis, -4, @w_nombres, @w_apellidos, @w_tipo_cliente, @w_id_integrante, @i_id_inst_proc, 'NO SE PUDO REALIZAR LA CONSULTA. POR FAVOR, CONSULTAR DE FORMA MANUAL.', null, getdate(), null)
				if @@error != 0
				begin
					/* Error en insercion de registro */
					select @w_error = 2110430
					goto ERROR
				end
			end
		end

		select @w_valor_rfe = count(*) from cobis..cl_listas_negras_rfe
		where ne_codigo_cliente in ( select id from @w_tabla_usuarios)
		and (ne_estado_resolucion = 'S' or ne_estado_resolucion is null)
		and ne_nro_proceso = @i_id_inst_proc
		and trim(isnull(ne_nombre,'')) = @w_nombres and trim(isnull(ne_apellido,'')) = @w_apellidos


		select @w_coincidencias_rfe = @w_coincidencias_rfe + @w_valor_rfe

		fetch cur_integrantes
		into 	@w_id_integrante	,	@w_primer_nombre,		@w_segundo_nombre	,
				@w_primer_apellido,		@w_segundo_apellido	,	@w_apellido_casado	,
				@w_tipo_documento,		@w_numero_documento,    @w_fecha_nacimiento,
                @w_user_name,           @w_tipo_cliente

	end
	close cur_integrantes
	deallocate cur_integrantes



	if(@w_coincidencias_rfe > 0 )
		select @w_valor_nuevo = 'S' --VARIABLE DE EN_ESTADO CUANDO  ESTA EN LISTAS NEGRAS
	else
		select @w_valor_nuevo = 'N' --VARIABLE DE EN_ESTADO CUANDO  NO ESTA EN LISTAS NEGRAS



    select @w_valor_ant    = isnull(va_valor_actual, 'N')
      from cob_workflow..wf_variable_actual
     where va_id_inst_proc = @i_id_inst_proc
       and va_codigo_var   = @i_id_variable

    if @@rowcount = 0
      insert into cob_workflow..wf_variable_actual
             (va_id_inst_proc, va_codigo_var,  va_valor_actual)
      values (@i_id_inst_proc, @i_id_variable, @w_valor_nuevo )
    else
      update cob_workflow..wf_variable_actual
         set va_valor_actual = @w_valor_nuevo
       where va_id_inst_proc = @i_id_inst_proc
         and va_codigo_var   = @i_id_variable

    if not exists(select 1 from cob_workflow..wf_mod_variable
                  where mv_id_inst_proc = @i_id_inst_proc and
                        mv_codigo_var   = @i_id_variable  and
                        mv_id_asig_act  = @i_id_asig_act)
    begin
       insert into cob_workflow..wf_mod_variable
              (mv_id_inst_proc, mv_codigo_var, mv_id_asig_act,
               mv_valor_anterior, mv_valor_nuevo, mv_fecha_mod)
       values (@i_id_inst_proc, @i_id_variable, @i_id_asig_act,
               @w_valor_ant, @w_valor_nuevo , getdate())
    end


return 0

ERROR:
   exec cobis..sp_cerror
   @t_debug    ='N',
   @t_file     ='',
   @t_from     =@w_sp_name,
   @i_num      = @w_error
   return @w_error

GO
