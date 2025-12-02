

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_carga_conciliacion')
   drop proc sp_carga_conciliacion
go

create proc sp_carga_conciliacion
   @s_user                      varchar(14),
   @s_ssn                      	int,
   @s_sesn                      int,
   @s_date                      datetime,
   @t_debug     				char(1)     	= 	'N',
   @t_file      				varchar(10) 	= 	null, 
   @i_ssn						int				=   null,   
   @i_referencia				varchar(29)		= 	null,
   @i_corresponsal				varchar(255)	= 	null,
   @i_fecha_pago				datetime		= 	null,   
   @i_monto						money			= 	null,
   @i_nombre_archivo			varchar(255)	=   null,
   @i_operacion					char(1),
   @i_cliente					int				=   null,
   @i_tipo_cliente				char(1)			= 	null,
   @i_fecha_desde				datetime		=   null,
   @i_fecha_hasta				datetime		= 	null,
   @i_tipo						char(1)			= 	null,
   @i_no_conciliacion			varchar(2)		= 	null,
   @i_estado_conciliacion		char(1)			=   null,
   @o_ssn						int 			out
as

	declare
	@w_sp_name			varchar(30),
	@w_no_enviados		int,
	@w_no_recibidos		int,
	--@w_no_procesados	int,
	@w_conciliados		int,
	@w_error			int,
	@w_fecha_pro_orig	datetime
	
	
select @w_sp_name = 'cob_cartera..sp_carga_conciliacion'
select @w_fecha_pro_orig = fp_fecha from cobis..ba_fecha_proceso
--Insercion en tabla temporal   
if @i_operacion = 'T'
begin
	
	
	if  @i_referencia is not null and @i_monto is not null and @i_nombre_archivo is not null and @i_corresponsal is not null and @i_fecha_pago is not null 
	begin
		
		if @i_ssn is null
		begin
			delete ca_archivo_conciliacion_tmp
			 where ac_login = @s_user
		       and ac_ssn = @s_ssn
			   
			insert into ca_archivo_conciliacion_tmp (ac_login, ac_ssn, ac_monto, ac_referencia, ac_corresponsal, ac_fecha_pago, ac_fecha_carga, ac_nombre_archivo)
			values(@s_user, @s_ssn,  @i_monto, @i_referencia, @i_corresponsal, @i_fecha_pago, @w_fecha_pro_orig, @i_nombre_archivo)
			
			select @o_ssn = @s_ssn
		end
		else
		begin
			insert into ca_archivo_conciliacion_tmp (ac_login, ac_ssn, ac_monto, ac_referencia, ac_corresponsal, ac_fecha_pago, ac_fecha_carga, ac_nombre_archivo)
			values(@s_user, @i_ssn,  @i_monto, @i_referencia, @i_corresponsal, @i_fecha_pago, @w_fecha_pro_orig, @i_nombre_archivo)
			
			select @o_ssn = @i_ssn
		end
		return 0
		
	end
	else
	begin
		select @w_error = 724635
		goto ERROR_PROCESO
	end

	
end

--Borrar Archivo
if @i_operacion = 'D'
begin
	delete ca_archivo_conciliacion_tmp
	 where ac_login = @s_user
	   and ac_ssn = @s_ssn

end

--Carga Archivo
if @i_operacion = 'C'
begin
	--Registros en archivo y no en tabla
	insert into ca_corresponsal_trn (
	co_corresponsal, co_tipo, co_codigo_interno, co_fecha_proceso, co_fecha_valor,   
	co_referencia, co_moneda, co_monto, co_status_srv,  
	co_estado, co_error_id, co_error_msg,  co_concil_est, co_concil_motivo,
	co_concil_user, co_concil_fecha, co_concil_obs, co_archivo_fecha_corte,
	co_archivo_carga_usuario)
	select ac_corresponsal,
		   substring(ac_referencia, 14, 1), 
		   convert(int,substring(ac_referencia, 7, 7)),
		   null, --Fecha en que se disparo el servicio (null)
		   ac_fecha_pago, --Fecha del archivo
		   ac_referencia, 
		   null,
		   convert(money, (substring(ac_referencia, 21, 6) +'.' + substring(ac_referencia, 27, 2))), 
		   '',
		   'I', 
		   null, 
		   null, 
		   'N', 
		   'NE',
		   null, 
		   null,
		   null,
		   @w_fecha_pro_orig,
		   @s_user
	  from ca_archivo_conciliacion_tmp
	 where ac_ssn 			= @i_ssn
	   and ac_referencia	not in (select co_referencia 
	                                  from ca_corresponsal_trn 
									 where co_corresponsal = ac_corresponsal
									   and co_referencia is not null)
	
	select @w_no_enviados = @@rowcount
	
	--Registro en archivo y tabla
	update ca_corresponsal_trn
	   set co_concil_est			= 'S',
		   co_archivo_fecha_corte	= @w_fecha_pro_orig,
		   co_archivo_carga_usuario = ac_login,
		   co_concil_user			= ac_login,
		   co_concil_fecha 			= ac_fecha_carga
	  from ca_corresponsal_trn inner join ca_archivo_conciliacion_tmp
	    on co_referencia 		= ac_referencia
	 where ac_ssn				= @i_ssn
	   and ac_login				= @s_user
	   and co_concil_est        is null
	   --and co_estado			in ('P', 'E')
       and co_corresponsal 		= ac_corresponsal   
	   
	select @w_conciliados = @@rowcount
	
	   
	--Registros en tabla y no en archivo
	update ca_corresponsal_trn
	   set co_concil_est			= 'N',
		   co_archivo_fecha_corte	= @w_fecha_pro_orig,
           co_concil_motivo			= 'NR',	
           co_archivo_carga_usuario = @s_user		   
	  from ca_corresponsal_trn 
	 where co_concil_est        is null
	   
	select @w_no_recibidos = @@rowcount
	
	delete ca_archivo_conciliacion_tmp
	 where ac_login = @s_user
	   and ac_ssn = @i_ssn
	
	if (@w_no_enviados is null and @w_conciliados is null and @w_no_recibidos is null)
		or (@w_no_enviados = 0 and @w_conciliados = 0 and @w_no_recibidos = 0)
	begin
		select @w_error = 724634
		goto ERROR_PROCESO
	end
	
	
end

--Busqueda de Parametro
if @i_operacion = 'Q'
begin
	
	
	select ct.co_tipo, o.op_nombre, ct.co_fecha_valor, ct.co_monto, 
		   ct.co_estado, ct.co_concil_est, ct.co_concil_motivo, ct.co_concil_fecha, 
		   ct.co_concil_user, ct.co_concil_obs, ct.co_referencia
      from cob_cartera..ca_corresponsal_trn ct 
inner join cob_cartera..ca_operacion o
		on ct.co_codigo_interno = o.op_operacion
 left join cobis..cl_ente e
        on o.op_cliente 		= e.en_ente
 left join cobis..cl_grupo g
        on o.op_cliente			= g.gr_grupo
	  where (ct.co_monto 		 		= @i_monto 					or  @i_monto 				is null)
		and (ct.co_tipo  		 		= @i_tipo  					or 	@i_tipo  				is null)
		and (ct.co_concil_motivo 		= @i_no_conciliacion		or  @i_no_conciliacion 		is null)
		and (ct.co_concil_est 			= @i_estado_conciliacion	or  @i_estado_conciliacion	is null)
		and (@i_cliente					is null 	or (e.en_ente 	= @i_cliente		and (@i_tipo_cliente	= 'P' or @i_tipo_cliente = 'C'))  
											        or (g.gr_grupo  = @i_cliente		and (@i_tipo_cliente	= 'S' or @i_tipo_cliente = 'G')))
		and (datediff(dd,ct.co_archivo_fecha_corte, @i_fecha_desde) > 0			or 	@i_fecha_desde is null)
		and (datediff(dd,ct.co_archivo_fecha_corte, @i_fecha_hasta) < 0			or  @i_fecha_hasta is null)
		and ct.co_tipo <> 'G'
   union
   select ct.co_tipo, g.gr_nombre, ct.co_fecha_valor, ct.co_monto, 
		   ct.co_estado, ct.co_concil_est, ct.co_concil_motivo, ct.co_concil_fecha, 
		   ct.co_concil_user, ct.co_concil_obs, ct.co_referencia
      from cob_cartera..ca_corresponsal_trn ct 
 inner join cobis..cl_grupo g
        on ct.co_codigo_interno			= g.gr_grupo
	  where (ct.co_monto 		 		= @i_monto 					or  @i_monto 				is null)
		and (ct.co_tipo  		 		= @i_tipo  					or 	@i_tipo  				is null)
		and (ct.co_concil_motivo 		= @i_no_conciliacion		or  @i_no_conciliacion 		is null)
		and (ct.co_concil_est 			= @i_estado_conciliacion	or  @i_estado_conciliacion	is null)
		and (@i_cliente					is null 	or (g.gr_grupo  = @i_cliente		and (@i_tipo_cliente	= 'S' or @i_tipo_cliente = 'G')))
		and (datediff(dd,ct.co_archivo_fecha_corte, @i_fecha_desde) > 0			or 	@i_fecha_desde is null)
		and (datediff(dd,ct.co_archivo_fecha_corte, @i_fecha_hasta) < 0			or  @i_fecha_hasta is null)
		and ct.co_tipo not in ('P', 'I')
   order by ct.co_tipo, o.op_nombre
   
   
   
			 
						 
end						 
return 0  


ERROR_PROCESO:
    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = @w_error
    return @w_error

go

