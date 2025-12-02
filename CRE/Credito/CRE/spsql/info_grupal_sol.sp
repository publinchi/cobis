
use cob_credito
go
/************************************************************/
/*   ARCHIVO:         info_grupal_sol.sp                    */
/*   NOMBRE LOGICO:   sp_info_grupal_sol                    */
/*   PRODUCTO:        COBIS CREDITO                         */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*Consulta la informacion para la solicitud de un prestamo  */
/*grupal                                                    */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/* 28/JUN/2017     PRO                 Emision Inicial      */
/************************************************************/
if exists(select 1 from sysobjects where name = 'sp_info_grupal_sol')
   DROP proc sp_info_grupal_sol
go

create proc sp_info_grupal_sol (	
	@s_ssn       int         = null,
	@s_sesn      int         = null,
	@s_ofi       smallint    = null,
	@s_rol       smallint    = null,
	@s_user      login       = null,
	@s_date      datetime    = null,
	@s_term      descripcion = null,
	@t_debug     char(1)     = 'N',
	@t_file      varchar(10) = null,
	@t_from      varchar(32) = null,
	@t_trn       smallint	 = null,
	@s_srv       varchar(30) = null,
	@s_lsrv      varchar(30) = null,
	@i_modo      int         = null,
	@i_operacion char(1),
	@i_grupo     int         = null,
	@i_tramite   int         = null,
	@i_formato_fecha int	 = null
)
as
declare
	@w_sp_name 				varchar(20),
	@w_grupo 				int,
	@w_ente_anf 			int,
	@w_nom_ente_anf 		varchar(254),
	@w_lugar_reunion 		varchar(5),
	@w_ente_lugar_reunion 	varchar(5),
	@w_direccion_anf		varchar(254),
	@w_tipo_telefono		varchar(5),
	@w_tipo_telefono_cel	varchar(5),
	@w_telefono_anf			varchar(30),
	@w_telefono_cel_anf		varchar(30),
	@w_dia_reunion			varchar(10),
	@w_tplazo				varchar(10),
	@w_plazo				int,
	@w_parroquia			varchar(39),
	@w_ciudad				varchar(50),
	@w_direccion_oficina	varchar(100),
	@w_monto				money,
	@w_monto_letras			varchar(254),
	@w_moneda				smallint,
	@w_return				int,
	@w_cliente_monto		int,
	@w_monto_calcular		money,
	@w_desembolsado         char(1)


select @w_sp_name = 'sp_info_grupal_sol'

   CREATE TABLE #cr_monto_cliente_grupo(
	mc_tramite INT NOT NULL,
	mc_cliente INT NOT NULL,
	mc_monto   VARCHAR (254)
	)
	
if @i_formato_fecha is null
begin
	select @i_formato_fecha=103
end

if not exists (select 1 from cr_tramite where tr_tramite=@i_tramite)
begin
	exec cobis..sp_cerror
		 @t_debug = @t_debug,
		 @t_file  = @t_file,
		 @t_from  = @w_sp_name,
		 @i_num   = 2110316
	return 2110316
end

if not exists (select 1 from cr_tramite_grupal where tg_tramite=@i_tramite)
begin
	exec cobis..sp_cerror
		 @t_debug = @t_debug,
		 @t_file  = @t_file,
		 @t_from  = @w_sp_name,
		 @i_num   = 2110335
	return 2110335
end


select @w_grupo = tg_grupo
from cr_tramite_grupal 
where tg_tramite=@i_tramite


if @i_operacion='Q'
begin

	select	'OFICINA'		= 	tr_oficina,
			'DESC_OFICINA'	=	(select of_nombre from cobis..cl_oficina where of_oficina=tr.tr_oficina),
			'FECHA_SOL'		=	convert(varchar(10),tr_fecha_crea ,@i_formato_fecha),
			'ID_GRUPO'		=	@w_grupo,
			'MONTO'			=	tr_monto,
			
			'TIPO_PLAZO'	=	(select td_descripcion from cob_cartera..ca_default_toperacion op, cob_cartera..ca_tdividendo 
								where dt_tdividendo=td_tdividendo and op.dt_toperacion = tr.tr_toperacion),
			
			'PLAZO'			=	(select dt_plazo from cob_cartera..ca_default_toperacion where dt_toperacion = tr.tr_toperacion),
			
			'FECHA_DESEM'	=	convert(varchar(10),op_fecha_liq ,@i_formato_fecha),
			
			'FECHA_PRI_PAGO'=	(select convert(varchar(10),di_fecha_ven ,@i_formato_fecha) 
								 from cob_cartera..ca_dividendo 
								 where di_operacion = op.op_operacion and di_dividendo=1),
								 --where di_operacion = op_operacion and di_dividendo=1),
			
			'CICLO_TRAMITE' =    (select ci_ciclo FROM cob_cartera..ca_ciclo where ci_tramite = @i_tramite)
	from 	cr_tramite tr, 
			cob_cartera..ca_operacion op
	where tr_tramite = op_tramite
	  AND tr_tramite = @i_tramite	
	
	/*Se obtienen datos de Anfitrion*/
	select @w_dia_reunion	=	valor,
		   @w_lugar_reunion	=	gr_lugar_reunion
	from cobis..cl_grupo,cobis..cl_catalogo 
	where tabla in (select codigo 
					from cobis..cl_tabla 
					where tabla='ad_dia_semana') 
	and codigo=gr_dia_reunion
	and gr_grupo=@w_grupo
	
	select @w_ciudad=ci_descripcion
	from cobis..cl_ciudad, cr_tramite
	where tr_ciudad=ci_ciudad
	and tr_tramite=@i_tramite
	
	select @w_direccion_oficina	= of_direccion
	from cobis..cl_oficina, cr_tramite
	where tr_oficina=of_oficina
	and tr_tramite=@i_tramite
	
	select @w_monto=tr_monto,
			@w_moneda=tr_moneda
	from cr_tramite
	where tr_tramite=@i_tramite
	
	
	/*exec @w_return = cob_interfase..sp_numeros_letras 
	@i_dinero	=	@w_monto,
	@i_moneda	=	@w_moneda,
	@i_idioma	=	'E',
	@t_trn		=   29322,
	@o_texto	=	@w_monto_letras out*/
	
    SELECT @w_monto_letras ='prueba de letras'
	SELECT @w_return = 0
	
	if(@w_return <> 0)
	begin 
		exec cobis..sp_cerror
		 @t_debug = @t_debug,
		 @t_file  = @t_file,
		 @t_from  = @w_sp_name,
		 @i_num   = 2110317
		return 2110317
	end
	
	
	if (@w_lugar_reunion='DT')
	begin
		select 	@w_nom_ente_anf			=	(select UPPER(isnull(en.en_nombre,''))+' ' + UPPER(isnull(en.p_s_nombre,''))+' '+
	                                         UPPER(isnull(en.p_p_apellido,''))+' '+UPPER(isnull(en.p_s_apellido,''))),
				@w_ente_anf				=	en.en_ente,
				@w_ente_lugar_reunion	=	cg_lugar_reunion
				
		from 	cobis..cl_ente en, 
				cobis..cl_cliente_grupo
				
		where	en.en_ente=cg_ente 
		and 	cg_grupo=@w_grupo 
		and 	cg_lugar_reunion is not null
	
	
	/*Se obtiene la direccion del anfitrion*/
	
		if @w_ente_anf is not null
		begin
			select top 1 @w_direccion_anf	=	isnull((select ci_descripcion from cobis..cl_ciudad where ci_ciudad=di.di_ciudad),'')
										+ ' ', 
										--+isnull((select pq_descripcion from cobis..cl_parroquia where pq_parroquia=di.di_parroquia),'')
										--+' '
									   --	+isnull(di.di_calle,'')
									   --	+' '
									   --	+isnull(convert(varchar,di.di_nro),'')
									   --	+ ' '
									   --	+ isnull(convert(varchar,di.di_nro_interno),''),
				    @w_parroquia	=	(select pq_descripcion from cobis..cl_parroquia where pq_parroquia=di.di_parroquia)
			from cobis..cl_direccion di 
			where 	di_ente			=	@w_ente_anf
			and		di_tipo			=	@w_ente_lugar_reunion
			
			/*Se obtienen los telefonos*/
			select @w_tipo_telefono=pa_char
			from cobis..cl_parametro
			where pa_nemonico='TTD'
			
			select @w_tipo_telefono_cel=pa_char
			from cobis..cl_parametro
			where pa_nemonico='TTC'
			
			select @w_telefono_anf = te_valor
			from cobis..cl_telefono
			where te_ente=@w_ente_anf
			and		te_tipo_telefono=@w_tipo_telefono
			and		te_fecha_registro = (select max(te_fecha_registro) from cobis..cl_telefono
										where te_ente=@w_ente_anf
										and		te_tipo_telefono=@w_tipo_telefono) 
			
			select @w_telefono_cel_anf = te_valor
			from cobis..cl_telefono
			where te_ente=@w_ente_anf
			and		te_tipo_telefono=@w_tipo_telefono_cel
			and		te_fecha_registro = (select max(te_fecha_registro) from cobis..cl_telefono
										where te_ente=@w_ente_anf
										and		te_tipo_telefono=@w_tipo_telefono_cel) 
		end
	end
	else
	begin
		select 	@w_direccion_anf 	= 	gr_dir_reunion
		from cobis..cl_grupo
		where gr_grupo	=	@w_grupo
	end
	
	/*Query final */
	select 	'NOMBRE_ENTE'			=	@w_nom_ente_anf,
			'ENTE'					=	@w_ente_anf,
			'LUGAR_REUNION'			=	@w_lugar_reunion,
			'DIRRECCION REUNION'	=	@w_direccion_anf,
			'TELEFONO_REUNION'		=	@w_telefono_anf,
			'TELEFONO_CEL_REUN'		= 	@w_telefono_cel_anf,
			'DIA_REUNION'			=	@w_dia_reunion,
			'COLONIA'				= 	@w_parroquia,
			'CIUDAD'				=	@w_ciudad,
			'DIR_OFI'				=	@w_direccion_oficina,
			'MONTO_LETRAS'			=	@w_monto_letras,
			'APODERADO'		        =   (select pa_char from cobis..cl_parametro where pa_nemonico='NASOF' and pa_producto='CRE')	
end

if @i_operacion='S'
BEGIN
 
	select @w_monto=tr_monto,
			@w_moneda=tr_moneda
	from cr_tramite
	where tr_tramite=@i_tramite
	
	select @w_cliente_monto=0
	
	while(1=1)
	begin
		
		if(@w_cliente_monto=0)
		begin
			select top 1 @w_cliente_monto=tg_cliente
			from cr_tramite_grupal 
			where tg_tramite=@i_tramite 			
			order by tg_cliente
		end
		else
		begin
			select top 1 @w_cliente_monto=tg_cliente
			from cr_tramite_grupal 
			where tg_tramite=@i_tramite 
			and tg_cliente >@w_cliente_monto
			order by tg_cliente
			
			if(@@rowcount=0)
			begin
				break
			end
		end
		
		select @w_monto_calcular = tg_monto
		from cr_tramite_grupal 
		where tg_tramite=@i_tramite 
		and tg_cliente = @w_cliente_monto
		
	   /*	exec @w_return = cob_interfase..sp_numeros_letras 
		@i_dinero	=	@w_monto_calcular,
		@i_moneda	=	@w_moneda,
		@i_idioma	=	'E',
		@t_trn		=   29322,
		@o_texto	=	@w_monto_letras out*/
		
		    SELECT @w_monto_letras ='prueba de letras'
		    SELECT @w_return =0
		
		insert into #cr_monto_cliente_grupo
		select tg_tramite, 
				tg_cliente, 
				@w_monto_letras		
		from cr_tramite_grupal
		where tg_tramite=@i_tramite 
		and tg_cliente= @w_cliente_monto
		
		if(@w_return <> 0)
		begin 
			exec cobis..sp_cerror
			 @t_debug = @t_debug,
			 @t_file  = @t_file,
			 @t_from  = @w_sp_name,
			 @i_num   = 2110317
			return 2110317
		end
	end
	
 	
    if exists( select 1  from cob_cartera..ca_operacion where op_tramite = @i_tramite and op_estado NOT IN (0,99))
      select @w_desembolsado = 'S'
    else 
      select @w_desembolsado = 'N'

	/* Obtiene los montos de los creditos*/
	select 'CLIENTE'			=	tg_cliente, 
		   'MONTO SOLICITADO'	=	tg_monto_aprobado,
		   'MONTO APROBADO'		=	tg_monto,
		   'PORCENTAJE'			= 	(select convert(varchar(10),tr_porc_garantia) from cob_credito..cr_tramite where tr_tramite=@i_tramite),--(select round((tg_monto_aprobado*100)/tr_monto,4) from cr_tramite where tr_tramite=@i_tramite),
		   'CICLO'				=   case when @w_desembolsado = 'S' then isnull(en_nro_ciclo,0)
		   								 when @w_desembolsado = 'N' then isnull(en_nro_ciclo,0) + 1 end,   	                              
		   'NOM_CLI'			=	UPPER(isnull(en_nombre,''))+' '+UPPER(isnull(p_s_nombre,''))+' '+UPPER(isnull(p_p_apellido,''))+' '+UPPER(isnull(p_s_apellido,'')),
		   'MONTO_LET'			= 	mc_monto,
		   'CUENTA'				=   (select ea_cta_banco from cobis..cl_ente_aux where ea_ente=TG.tg_cliente),
		   'ROL'                =   cg_rol,
		   'AHORRO_VOLUNTARIO'  =   cg_ahorro_voluntario,
		   'CICLO_TRAMITE'      =   NULL
		   
	from cob_credito..cr_tramite_grupal TG,
	     cobis..cl_cliente_grupo CG,
	     cobis..cl_ente EN,
	     #cr_monto_cliente_grupo MC
	where TG.tg_tramite=	@i_tramite
	AND TG.tg_grupo    = CG.cg_grupo
	AND TG.tg_cliente  = CG.cg_ente
	AND CG.cg_ente     = EN.en_ente
	AND EN.en_ente     = MC.mc_cliente
	AND MC.mc_tramite  = TG.tg_tramite
	AND TG.tg_participa_ciclo = 'S'
	AND TG.tg_monto > 0
end

return 0
go
