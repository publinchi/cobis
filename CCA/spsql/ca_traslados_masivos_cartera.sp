/************************************************************************/
/*   NOMBRE LOGICO:      ca_traslados_masivos_cartera.sp                */
/*   NOMBRE FISICO:      sp_traslados_masivos_cartera                   */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Guisela Fernandez, Johan Hernandez             */
/*   FECHA DE ESCRITURA:                                                */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*  Realizar La inserción en la tabla ca_traslados_cartera	de los      */ 
/*  datos seleccionados en el traslado de Oficina y de Oficial          */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 18/03/2021    G. Fernandez	 Versión Inicial                        */
/* 18/03/2021    J. Hernandez	 Versión Inicial                        */
/* 21/10/2021    K. Rodriguez    Se agrega campos adicionales a la tabla*/
/*                               ca_traslados_cartera                   */
/* 17/02/2022    G. Fernandez    Se corrige cierre de cursor GFP        */
/* 04/05/2022    G. Fernandez    Se elimina la consulta de operaciones  */
/*                               por criterio de busqueda               */
/* 17/05/2023    G. Fernandez    B831662 Se corrige el tipo en w_banco  */
/* 24/12/2023    K. Rodriguez    R220437 Ajustes para traslado OP Padres*/
/************************************************************************/ 

USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_traslados_masivos_cartera')
   drop proc sp_traslados_masivos_cartera
go

CREATE PROC sp_traslados_masivos_cartera
(
@s_user                 varchar(30)		= NULL,
@s_culture              varchar(10)  = 'NEUTRAL',
@s_date                 datetime		= NULL,

@i_operacion			CHAR(1)			= NULL,
@i_fecha_proceso		datetime		= NULL
)
as

DECLARE 
@w_estado_busqueda		CHAR(1)         ,
@w_error		        int             ,
@w_fecha_traslado		datetime		,
@w_cliente_busqueda		INT				,
@w_cliente				INT				,
@w_oficina      		INT				,
@w_oficina_origen		INT				,
@w_oficina_destino		INT				,
@w_secuencial_tras		INT				= NULL,
@w_oficial_destino		SMALLINT		,
@w_oficial_origen		SMALLINT		,

@w_banco				cuenta  		 ,
@w_tramite 				INT				 ,
@w_moneda				TINYINT			 ,
@w_fecha_ini			DATETIME		 ,
@w_migrada				VARCHAR(24)		 ,
@w_tipo_registro		VARCHAR(30)	     = NULL,
@w_existe       		CHAR(1)		     = NULL,
@w_tipo_traslado		CHAR(1)			 ,
@w_op_operacioncar      INT              ,
@w_procesado            CHAR(1)          = NULL,
@w_sp_name              varchar (32)  = 'sp_traslados_masivos_cartera',
@w_user                 login,
@w_term                 varchar(30),                
@w_fecha_real           datetime,
@w_rol                  int,
@w_tipo_grupal          char(1),
@w_ref_grupal           varchar(24),
@w_regs_traslado        int,
@w_cont                 int


IF @i_operacion = 'I'
begin

	if object_id('tempdb..#tmp_regs_traslado') is not null
       drop table #tmp_regs_traslado
	
    --Tabla temporal para obtener datos de la tabla registra_traslados_masivos
	select 
	rt_cliente			,rt_banco			,rt_tramite			,rt_oficina			,rt_moneda,
	rt_fecha_ini		,rt_estado			,rt_migrada			,rt_tipo_registro	,rt_estado_registro,
	rt_oficial_destino	,rt_fecha_traslado	,rt_tipo_traslado	,rt_oficina_destino ,rt_secuencial_traslado,
	rt_user             ,rt_term            ,rt_fecha_real      ,rt_rol             ,rt_tipo_grupal,
    rt_ref_grupal   
    into #tmp_regs_traslado	
	from   cob_cartera..ca_registra_traslados_masivos with (nolock)                                 
	where  	rt_estado_registro 			= 'I'
	and 	rt_fecha_traslado	= @i_fecha_proceso --debe ser la fecha actual
	
    select @w_cont = count(1) 
    from #tmp_regs_traslado
	
	while @w_cont > 0 
	begin
	
	    select top 1
        @w_cliente_busqueda = rt_cliente,
        @w_banco            = rt_banco,
        @w_tramite          = rt_tramite,
        @w_oficina          = rt_oficina,
        @w_moneda           = rt_moneda,
        @w_fecha_ini        = rt_fecha_ini,
        @w_estado_busqueda  = rt_estado,
        @w_migrada          = rt_migrada,
        @w_tipo_registro    = rt_tipo_registro,
        @w_existe           = rt_estado_registro,
		@w_oficial_destino  = rt_oficial_destino,
		@w_fecha_traslado   = rt_fecha_traslado,
		@w_tipo_traslado    = rt_tipo_traslado,
		@w_oficina_destino  = rt_oficina_destino,
		@w_secuencial_tras  = rt_secuencial_traslado,
		@w_user             = rt_user,
		@w_term             = rt_term,
		@w_fecha_real       = rt_fecha_real,
		@w_rol              = rt_rol,
		@w_tipo_grupal      = rt_tipo_grupal,
		@w_ref_grupal       = rt_ref_grupal
        from #tmp_regs_traslado
		where rt_estado_registro = 'I'
        order by rt_tipo_registro, rt_tipo_traslado
		
		if @@rowcount = 0
           break;		
	    
		BEGIN TRAN
		
		SELECT @w_cliente         = op_cliente, 
		       @w_oficina_origen   = op_oficina, 
			   @w_oficial_origen   = op_oficial ,  
			   @w_op_operacioncar  = op_operacion,
			   @w_banco            = op_banco
		FROM cob_cartera..ca_operacion with (nolock)
		WHERE op_banco = @w_tipo_registro
		
		if @@rowcount = 0 
	          begin
	          	select @w_error = 710022 -- No existe la operacion
	          	goto ERROR_LOG
	          end
		
		select @w_procesado     = NULL,
		       @w_regs_traslado = null
		
		select @w_procesado  = trc_estado 
		from cob_cartera..ca_traslados_cartera with (nolock)
		where trc_cliente       = @w_cliente
		and   trc_fecha_proceso = @w_fecha_traslado
		and   trc_operacion     = @w_op_operacioncar
		
        -- Número de registros de traslado por Préstamos y fecha
        -- (**Traslado de Oficina: genera 2 registros, 1 registro de traslado de oficina, y 1 registros de traslado de oficial)
        -- (++Traslado de Oficial: genera 1 registro, 1 registro de traslado de oficial)
        select @w_regs_traslado = count(1) 
        from ca_registra_traslados_masivos with (nolock)
        where rt_tipo_registro  = @w_banco 
        and rt_fecha_traslado	= @i_fecha_proceso
        and rt_estado_registro not in ('A') -- Anulado

		IF @w_procesado is not null and @w_procesado <> ''  --- Hay Datos
		BEGIN
		
            if @w_procesado = 'P'
            begin
               select @w_error = 711084 --Error. El registro ya fue procesado en traslado masivo
               goto ERROR_LOG
            end
		
			if @w_tipo_traslado = 'O'-- Traslado de oficial
			begin					
				if @w_regs_traslado < 2 -- Registro de Traslado de Oficial pertenece a un ++Traslado de Oficial
				begin
				
                    if @w_oficial_origen = @w_oficial_destino
					begin
						select @w_error = 711085 --Error. El oficial origen es igual al oficial destino
						goto ERROR_LOG
					end

                end

                update cob_cartera..ca_traslados_cartera
                set trc_oficial_destino = @w_oficial_destino,
                    trc_oficial_origen  = @w_oficial_origen,
                    trc_fecha_ingreso   = getdate()							
                where trc_cliente       = @w_cliente
                and   trc_fecha_proceso = @w_fecha_traslado
                and   trc_operacion     = @w_op_operacioncar
                
                if @@error <> 0 
                begin
                   select @w_error  = 708152 --Error al actualizar
                   goto ERROR_LOG
                end 
			end
			else -- Traslado de oficina
			begin
				if @w_oficina_origen = @w_oficina_destino 
				begin
					select @w_error = 711086 --Error. La oficina origen es igual a la oficina destino
					goto ERROR_LOG
				end
				else
				begin
					update cob_cartera..ca_traslados_cartera
					set trc_oficina_destino = @w_oficina_destino,
						trc_oficina_origen  = @w_oficina_origen,
						trc_fecha_ingreso   = getdate()
					where trc_cliente       = @w_cliente
					and	  trc_fecha_proceso = @w_fecha_traslado
					and   trc_operacion     = @w_op_operacioncar
						
					if @@error <> 0 begin
						select @w_error  = 708152 --Error al actualizar
						goto ERROR_LOG
					end
				end	
			end
		END
		else
		begin
			if @w_tipo_traslado = 'O'-- Traslado de oficial
			begin
				select @w_oficina_destino = @w_oficina_origen
				
                if @w_regs_traslado < 2 -- Registro de Traslado de Oficial pertenece a un ++Traslado de Oficial
				begin
				   if @w_oficial_origen = @w_oficial_destino
				   begin
				   	  select @w_error  = 711085
				   	  goto ERROR_LOG
				   end
				end
			end	
			else ---Traslado de oficina
			begin
				select @w_oficial_destino = @w_oficial_origen
				
				if @w_oficina_origen = @w_oficina_destino
				begin
					select @w_error  = 711086
					goto ERROR_LOG
				end
			end	
			
			insert into ca_traslados_cartera (
			trc_fecha_proceso		, trc_cliente			, trc_operacion			, trc_user,
			trc_oficina_origen		, trc_oficina_destino	, trc_estado			, trc_garantias,
			trc_credito				, trc_sidac				, trc_fecha_ingreso		, trc_secuencial_trn,
			trc_oficial_origen		, trc_oficial_destino	, trc_saldo_capital     , trc_term,
			trc_fecha_real)
			values(		
			@w_fecha_traslado		, @w_cliente			, @w_op_operacioncar, @w_user,
			@w_oficina_origen		, @w_oficina_destino	, 'I'				, 'N',
			'N'						, 'N'					, getdate()			, null,
			@w_oficial_origen		, @w_oficial_destino	, 0                 , @w_term,
			@w_fecha_real)
				
			if @@error <> 0 
			begin
				select  @w_error = 711083 --Error. No se puede insertar el registro de traslado masivo
				goto ERROR_LOG						
			END
		end

		update ca_registra_traslados_masivos
		set rt_estado_registro = 'P'
		where rt_secuencial_traslado = @w_secuencial_tras
		
        if @@error <> 0 
        begin
           select  @w_error = 725310 -- Error al actualizar tabla de registro de traslados masivos
           goto ERROR_LOG						
        end
		
		COMMIT TRAN
		
		goto SIGUIENTE
		
        ERROR_LOG:
        while @@trancount > 0 rollback tran
				
		-- Si fallá una OP hija o Padre, no trasladar ninguna Operación de la ref Grupal
		if @w_tipo_grupal in ('G', 'H')
		begin
		
		   -- Elimnar registros Padre o hijos ya insertados pertenecientes a la ref grupal
		   delete ca_traslados_cartera
		   from ca_operacion with (nolock)
           where (op_ref_grupal  = @w_ref_grupal or op_banco =  @w_ref_grupal)
		   and op_operacion      = trc_operacion
		   and trc_fecha_proceso = @w_fecha_traslado
		   
           if @@error <> 0 
           begin
		      insert into ca_errorlog (er_fecha_proc, er_error,  er_usuario, er_tran, er_cuenta, er_descripcion )
              values (@s_date, 725311, @s_user, 0, @w_ref_grupal, 'Error al eliminar registros de tabla de registro de traslados masivos')					
           end
		   
           update ca_registra_traslados_masivos with (rowlock) 
		   set rt_estado_registro = 'E'
		   where rt_ref_grupal   = @w_ref_grupal -- Se incluye a OP padre
		   and rt_fecha_traslado = @w_fecha_traslado
		   
           if @@error <> 0 
           begin
		      insert into ca_errorlog (er_fecha_proc, er_error,  er_usuario, er_tran, er_cuenta, er_descripcion )
              values (@s_date, 725310, @s_user, 0, @w_ref_grupal, 'Error al actualizar registros de tabla de registro de traslados masivos')			  
           end
		   
		   -- Para no procesar demás Operaciones de la referencia grupal
		   update #tmp_regs_traslado
		   set rt_estado_registro = 'E'
		   where rt_ref_grupal   = @w_ref_grupal
		   and rt_fecha_traslado = @w_fecha_traslado 
		
		end
		else -- No trasladar OP individual
		begin
		
		   update ca_registra_traslados_masivos with (rowlock) 
		   set rt_estado_registro = 'E'
		   where rt_secuencial_traslado = @w_secuencial_tras
		   
           if @@error <> 0 
           begin
              select  @w_error = 725310 -- Error al actualizar tabla de registro de traslados masivos
              goto ERROR						
           end
		
		end

        exec sp_errorlog 
        @i_fecha       = @i_fecha_proceso,
        @i_error       = @w_error, 
        @i_usuario     = @s_user, 
        @i_tran        = 7001,
        @i_tran_name   = @w_sp_name,
        @i_cuenta      = @w_tipo_registro,
        @i_rollback    = 'N'

		SIGUIENTE:
        delete #tmp_regs_traslado where rt_secuencial_traslado = @w_secuencial_tras
        set @w_cont = (select count(1) from #tmp_regs_traslado)
	
	END
	
END
	
RETURN 0

ERROR:

exec cobis..sp_cerror
   @t_debug   = 'N',
   @t_from    = @w_sp_name,
   @s_culture = @s_culture, 
   @i_num     = @w_error
return @w_error

GO
