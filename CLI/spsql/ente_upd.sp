/************************************************************************/
/*  Archivo:            ente_upd.sp                                     */
/*  Stored procedure:   sp_ente_upd                                 */
/*  Base de datos:      cobis                                           */
/*   Producto:                CLIENTES                                   */
/*   Disenado por:  RIGG   				                                 */
/*   Fecha de escritura: 30-Abr-2019                                     */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*               MODIFICACIONES                                          */
/*   FECHA       	AUTOR                RAZON                           */
/*   30/Abr/2019   	RIGG	             Versión Inicial Te Creemos      */
/************************************************************************/

use cobis
go

if exists (select 1 from sysobjects where name = 'sp_ente_upd')
   drop proc sp_ente_upd
go


create proc  sp_ente_upd(
    @s_ssn              int             = null,
    @s_user             login           = null,
    @s_term             varchar(32)     = null,
    @s_date             datetime        = null,
    @s_srv              varchar(30)     = null,
    @s_lsrv             varchar(30)     = null,
    @s_ofi              smallint        = null,
    @s_rol              smallint        = null,
    @s_org_err          char(1)         = null,
    @s_error            int             = null,
    @s_sev              tinyint         = null,
    @s_msg              descripcion     = null,
    @s_org              char(1)         = null,
    @t_debug            char(1)         = 'N',
    @t_file             varchar(10)     = null,
    @t_from             varchar(32)     = null,
    @t_trn              smallint        = null,
    @i_operacion        char(1),                -- Opcion con la que se ejecuta el programa,
    @i_ente             int             = null, -- Codigo del ente
    @t_show_version     bit             = 0
)
as
declare @w_today                datetime,
        @w_sp_name              varchar(32),
        @w_return               int,
        @w_nombre               varchar(32),
        @w_p_s_nombre           varchar(20),
        @w_p_apellido           varchar(20),
        @w_s_apellido           varchar(20),
        @w_p_c_apellido         varchar(20),
        @w_en_nomlar            varchar(254),
        @w_en_ced_ruc           numero,
        @w_tipo_ced             char(4),
		@w_det_producto         int,
		@w_cuenta               cuenta,
		@w_producto             tinyint,
		@w_moneda               tinyint,
		@w_titularidad          char(1),
        @w_var_union		    char(3),
		@w_cont                 tinyint,
		@w_nomlar               varchar(254),
		@w_nombre_cta           varchar(254)

--VERSIONAMIENTO DE SP
if @t_show_version = 1
begin
    print 'Stored procedure sp_ente_upd, Version 4.0.0.1'
    return 0
end

select @w_today = @s_date
select @w_sp_name = 'sp_ente_upd'

if @i_operacion = 'U'
begin
    select @w_nombre           = en_nombre,
           @w_p_s_nombre       = p_s_nombre,
           @w_p_apellido       = p_p_apellido,
           @w_s_apellido       = p_s_apellido,
           @w_p_c_apellido     = p_c_apellido,
           @w_en_nomlar        = en_nomlar,
           @w_en_ced_ruc       = en_ced_ruc,
           @w_tipo_ced         = en_tipo_ced
      from cl_ente
     where en_ente = @i_ente

    if @@rowcount = 0
    begin
      exec sp_cerror
           @t_debug        = @t_debug,
           @t_file     = @t_file,
           @t_from     = @w_sp_name,
           @i_num      = 101043
           -- 'No existe cliente'
           return 1
    end
--MODULO DE CARTERA
     
	--Busqueda de Operaciones Grupales
	select distinct(tg_referencia_grupal), tg_tramite
	into #operaciones_grupales
	from cob_credito..cr_tramite_grupal
    where tg_grupo = @i_ente
	
    if exists (select 1 from cob_cartera..ca_operacion
                where op_cliente =  @i_ente and op_banco not in (select tg_referencia_grupal from #operaciones_grupales))
    begin
        update cob_cartera..ca_operacion
        set   op_nombre  =  @w_en_nomlar
        where op_cliente =  @i_ente
		and   op_banco   not in (select tg_referencia_grupal from #operaciones_grupales)
		 
        if @@error <> 0
        begin
            exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 605081
            --Error en actualizacion de persona
            return 1
        end
    end

--MODULO DE CREDITO
 if exists (select 1 from cob_credito..cr_deudores
                where de_cliente =  @i_ente and de_tramite not in (select tg_tramite from #operaciones_grupales))
    begin
        update cob_credito..cr_deudores
        set   de_ced_ruc =  @w_en_ced_ruc
        where de_cliente =  @i_ente
		and   de_tramite not in (select tg_tramite from #operaciones_grupales)
		
        if @@error <> 0
        begin
            exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 605081
            --Error en actualizacion de persona
            return 1
        end
    end

--MODULO DE COMEXT
--Ordenante
/*-- NO existe comex
if exists (select 1 from cob_comext..ce_operacion
                where op_ordenante =  @i_ente)
    begin
        update cob_comext..ce_operacion
           set op_ced_ruc  =  @w_en_ced_ruc
         where op_ordenante =  @i_ente
        if @@error <> 0
        begin
            exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 605081
            --Error en actualizacion de persona
            return 1
        end
    end
*/
--MODULO DE PLAZO FIJO
--No aplica para ENLACE
/*
if exists (select 1 from cob_pfijo..pf_operacion
                   where op_ente  =  @i_ente)
    begin
        update cob_pfijo..pf_operacion
           set op_ced_ruc     = @w_en_ced_ruc,
               op_descripcion = @w_en_nomlar
         where op_ente =  @i_ente
        if @@error <> 0
        begin
            exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 605081
            --Error en actualizacion de persona
            return 1
        end
     end
*/

--MODULO DE TESORERIA
/*if exists (select 1 from cob_tesoreria..te_operacion
                where op_cod_cliente =  @i_ente)
    begin
        update cob_tesoreria..te_operacion
           set op_nombre_cli  =  @w_en_nomlar
         where op_cod_cliente =  @i_ente
        if @@error <> 0
        begin
            exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 605081
            --Error en actualizacion de persona
            return 1
        end
   end

if exists (select 1 from cob_tesoreria..te_instituto_emisor
                where ie_cod_emisor =  @i_ente)
    begin
        update cob_tesoreria..te_instituto_emisor
           set ie_descripcion   =  @w_en_nomlar
         where ie_cod_emisor   =  @i_ente
        if @@error <> 0
        begin
            exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 605081
            --Error en actualizacion de persona
            return 1
        end
    end

if exists (select 1 from cob_tesoreria..te_institucion_financiera
                where if_cod_cliente =  @i_ente)
    begin
        update cob_tesoreria..te_institucion_financiera
           set if_nombre_inst  =  @w_en_nomlar
         where if_cod_cliente =  @i_ente
        if @@error <> 0
        begin
            exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 605081
            --Error en actualizacion de persona
            return 1
        end
    end*/

	--MODULO DE CUENTAS AHORROS Y CORRIENTES
	if exists (select 1 from cobis..cl_cliente,cobis..cl_det_producto
				where cl_det_producto = dp_det_producto
				and cl_cliente = @i_ente
				and dp_producto in (3,4)
				and cl_rol in ('T','C'))
	begin

		declare cliente_pasivas cursor
		for select  cl_det_producto,
					dp_cuenta,
					dp_producto,
					dp_moneda
		from cl_cliente,cl_det_producto
		where cl_det_producto = dp_det_producto
		and cl_cliente = @i_ente
		and cl_rol in ('T','C')
		for read only
		open cliente_pasivas
		fetch cliente_pasivas into
			@w_det_producto,
			@w_cuenta,
			@w_producto,
			@w_moneda

		while @@fetch_status = 0
		begin
		    select @w_cont = 0

			if @w_producto = 4
			begin
				select  @w_titularidad = ah_ctitularidad from cob_ahorros..ah_cuenta where ah_cta_banco = @w_cuenta and ah_moneda = @w_moneda
				if @w_titularidad = 'M'
					select @w_var_union = '(Y)'
				if @w_titularidad = 'I'
					select @w_var_union = '(O)'
				if @w_titularidad = 'S'
					select @w_var_union = ''

				--INICIO - Formar el nombre de la Cuenta
				declare obtener_nombre cursor
				for select  en_nomlar
				from cl_cliente, cl_ente
				where en_ente = cl_cliente
				and cl_det_producto = @w_det_producto
				order by cl_rol desc
				for read only
				open obtener_nombre
				fetch obtener_nombre into
					@w_nomlar

				while @@fetch_status = 0
				begin
					select @w_cont = @w_cont + 1
					if @w_cont = 1
						select @w_nombre_cta = @w_nomlar
					else
						select @w_nombre_cta = @w_nombre_cta + ' ' + @w_var_union + ' ' + @w_nomlar

					fetch obtener_nombre into
						@w_nomlar
				end --while @@fetch_status = 0

				close obtener_nombre
				deallocate obtener_nombre
				--FIN - Formar el nombre de la Cuenta

				-- Actualizar la C.I. del Titular de la Cuenta
				update cob_ahorros..ah_cuenta
				set ah_ced_ruc = @w_en_ced_ruc
				where ah_cta_banco = @w_cuenta
				and ah_moneda = @w_moneda
				and ah_cliente = @i_ente
				if @@error <> 0
				begin
					exec sp_cerror
						 @t_debug = @t_debug,
						 @t_file  = @t_file,
						 @t_from  = @w_sp_name,
						 @i_num   = 107355
					return 1
				end

				-- Actualizar el nombre de la Cuenta
				update cob_ahorros..ah_cuenta
				set ah_nombre = @w_nombre_cta
				where ah_cta_banco = @w_cuenta
				and ah_moneda = @w_moneda
				if @@error <> 0
				begin
					exec sp_cerror
						 @t_debug = @t_debug,
						 @t_file  = @t_file,
						 @t_from  = @w_sp_name,
						 @i_num   = 107355
					return 1
				end

			end
			else --if @w_producto = 3
			begin
				select @w_titularidad = cc_ctitularidad from cob_cuentas..cc_ctacte where cc_cta_banco = @w_cuenta and cc_moneda = @w_moneda
				if @w_titularidad = 'M'
					select @w_var_union = '(Y)'
				if @w_titularidad = 'I'
					select @w_var_union = '(O)'
				if @w_titularidad = 'S'
					select @w_var_union = ''

				--INICIO - Formar el nombre de la Cuenta
				declare obtener_nombre cursor
				for select  en_nomlar
				from cl_cliente, cl_ente
				where en_ente = cl_cliente
				and cl_det_producto = @w_det_producto
				order by cl_rol desc
				for read only
				open obtener_nombre
				fetch obtener_nombre into
					@w_nomlar

				while @@fetch_status = 0
				begin
					select @w_cont = @w_cont + 1
					if @w_cont = 1
						select @w_nombre_cta = @w_nomlar
					else
						select @w_nombre_cta = @w_nombre_cta + ' ' + @w_var_union + ' ' + @w_nomlar

					fetch obtener_nombre into
						@w_nomlar
				end --while @@fetch_status = 0

				close obtener_nombre
				deallocate obtener_nombre
				--FIN - Formar el nombre de la Cuenta

				-- Actualizar la C.I. del Titular de la Cuenta
				update cob_cuentas..cc_ctacte
				set cc_ced_ruc = @w_en_ced_ruc
				where cc_cta_banco = @w_cuenta
				and cc_moneda = @w_moneda
				and cc_cliente = @i_ente
				if @@error <> 0
				begin
					exec sp_cerror
						 @t_debug = @t_debug,
						 @t_file  = @t_file,
						 @t_from  = @w_sp_name,
						 @i_num   = 107356
					return 1
				end

				-- Actualizar el nombre de la Cuenta
				update cob_cuentas..cc_ctacte
				set cc_nombre = @w_nombre_cta
				where cc_cta_banco = @w_cuenta
				and cc_moneda = @w_moneda
				if @@error <> 0
				begin
					exec sp_cerror
						 @t_debug = @t_debug,
						 @t_file  = @t_file,
						 @t_from  = @w_sp_name,
						 @i_num   = 107356
					return 1
				end

			end -- FIN if @w_producto = 4

			--Actualizar la Cedula del Cliente
			update cl_cliente
			set cl_ced_ruc = @w_en_ced_ruc
			where cl_cliente = @i_ente
			if @@error <> 0
			begin
				exec sp_cerror
					 @t_debug = @t_debug,
					 @t_file  = @t_file,
					 @t_from  = @w_sp_name,
					 @i_num   = 605081
				return 1
			end

			fetch cliente_pasivas into
					@w_det_producto,
					@w_cuenta,
					@w_producto,
					@w_moneda

		end --while @@fetch_status = 0

		close cliente_pasivas
		deallocate cliente_pasivas

	end

end
return 0

go
