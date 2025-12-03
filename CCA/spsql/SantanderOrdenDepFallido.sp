/************************************************************************/
/*   Archivo:              SantanderOrdenDepFallido.sp                  */
/*   Stored procedure:     sp_santander_orden_dep_fallido		   	    */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Nolberto Vite		                        */
/*   Fecha de escritura:   06 Julio 2018                                */
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
/*   Registra dispersiones fallidas en el procesamiento del IEN, y      */
/*     luego sera utilizadas para realizar la acción correspondiente    */
/*                                                                      */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      06/07/2018     NVI             Emision Inicial                  */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_santander_orden_dep_fallido')
   drop proc sp_santander_orden_dep_fallido
go

create proc sp_santander_orden_dep_fallido
(
 @s_ssn				int = NULL,
 @s_user			login = NULL,
 @s_sesn			int = NULL,
 @s_term			varchar(30) = NULL,
 @s_date			datetime = NULL,
 @s_srv				varchar(30) = NULL,
 @s_lsrv			varchar(30) = NULL, 
 @s_rol				smallint = NULL,
 @s_ofi				smallint = NULL,
 @s_org_err			char(1) = NULL,
 @s_error			int = NULL,
 @s_sev				tinyint = NULL,
 @s_msg				descripcion = NULL,
 @s_org				char(1) = NULL,
 @t_debug			char(1) = 'N',
 @t_file			varchar(14) = null,
 @t_from			varchar(32) = null,
 @t_trn				int = null,
 @i_operacion		char(1),
 @i_modo			tinyint = null,
 @i_cliente		    int = null,
 @i_fecha_ini   	datetime = null,
 @i_fecha_fin		datetime = null,
 @i_cuenta			cuenta = null,
 @i_accion			int = null,
 @i_tipo			char(3) = null,
 @i_causa_rechazo	varchar(2) = null,
 @i_grupo		    int = null,
 @i_referencia		varchar(30) = null,
 @i_fecha 			datetime = null,
 @i_consecutivo		int = null,
 @i_linea		    int = null,
 @o_parametro		int = null out
)
as 

declare
@w_sp_name           varchar(32),
@w_nombre_cli        varchar(64),
@w_nombre_grup       varchar(64),
@w_codigo_buc		 int,
@w_causa_rechazo	 varchar(40),
@w_criterio			 int,
@w_fecha 			 datetime,
@w_cliente			 int,
@w_cuenta	         cuenta,
@w_tipo				 char(3),
@w_msg_error         varchar(255),
@w_error             int,
@w_referencia		 int,
@w_consecutivo		 int,
@w_linea			 int,
@w_banco	         cuenta,
@w_secuencial		 int,
@w_operacion		 int,
@w_concepto			 varchar(12),
@w_forma_pago	     varchar(12),
@w_oficina			 int,
@w_fecha_valor		 datetime,
@w_secuencial_ing	 int,
@w_commit			 char(1),
@w_monto			 money,
@w_dias_maximo		 tinyint,
@w_fecha_proceso 	 datetime,
@w_fecha_minima		 datetime,
@w_accion			 int,
@w_dias			     int

select @w_commit = 'N'

--tabla temporar para recopilas datos para la consulta
create table #resultado1(
	fecha_fallo			datetime	null,
	consecutivo			int 		null,
	linea				int 		null,
	cliente				int 		null,
	nombre				varchar(64) null,
	banco				cuenta 		null,
	buc					varchar(24) null,
	tipo				char(3) 	null,
	cuenta				cuenta 		null,
	causa_rechazo		varchar(40) null,
	grupo				int 		null,
	nombre_grupo		varchar(64) null,
	monto				money 		null,
	accion				char(1) 	null,
	fecha_accion		datetime 	null,
	usuario				varchar(24) null
)

select @w_dias_maximo = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'CCA'
and pa_nemonico = 'DPDES'

if @@rowcount = 0 begin
   select 
   --@w_error = 70194,
   @w_msg_error = 'No existen parametro de Días Máximo Reintento de Dispersión'         
   goto ERROR
end

select @w_fecha_proceso = fp_fecha 
from cobis..ba_fecha_proceso

if @@rowcount = 0 begin
   select 
   --@w_error = 70194,
   @w_msg_error = 'Error al obtener fecha proceso'         
   goto ERROR
end

--Registra de dispersiones fallidas 
if @i_operacion = 'I' 
begin
	select @w_referencia = convert(int, REPLACE(@i_referencia,'ABONO TUIIO',''))
	select @w_consecutivo = @w_referencia / 10000
	select @w_linea = @w_referencia % 10000
	select @w_fecha = convert(varchar(10),@i_fecha, 121)

	select			
	@w_cliente 	= sod_cliente,   		
	@w_cuenta 	= sod_cuenta,			
	@w_tipo 	= sod_tipo,
	@w_banco 	= sod_banco,
	@w_monto	= sod_monto
	from ca_santander_orden_deposito
	where sod_fecha = @w_fecha
	and sod_consecutivo = @w_consecutivo
	and sod_linea = @w_linea
	
	if @@rowcount = 0 begin
          select 
          --@w_error = 70194,
          @w_msg_error = 'No existen registros de Dispersiones fallidas'         
          goto ERROR
    end
	
    if exists(select 1 from ca_santander_orden_deposito_fallido where odf_fecha = @w_fecha and odf_cliente = @w_cliente and odf_linea =  @w_linea)
    begin
         select 
          @w_msg_error = 'Registro duplicado de Dispersiones fallidas'         
          goto ERROR
    end
	insert into ca_santander_orden_deposito_fallido(
	odf_fecha, 			odf_consecutivo, 	odf_linea,       	
	odf_cliente, 		odf_cuenta,   		odf_banco,
	odf_tipo,       	odf_monto,			odf_causa_rechazo,
	odf_accion,			odf_accion_fecha,   odf_accion_user
	) values(
	@w_fecha,  			@w_consecutivo,     @w_linea,
	@w_cliente,			@w_cuenta,    		@w_banco,
	@w_tipo,            @w_monto,			@i_causa_rechazo,	
	1,					null,				null)
	
	if @@error != 0 begin
       select 
	   --@w_error = 710001,
	   @w_msg_error = 'Error, no se pudo insertar registros'
       goto ERROR
    end
	   
end

--Buscar Registros de dispersiones rechazadas 
if @i_operacion = 'S' 
begin 
  select @w_criterio = 99
  
  if @i_cliente = 0 
	  select @i_cliente = null
  if @i_grupo = 0 
	  select @i_grupo = null
  if @i_accion = 0 
	  select @i_accion = null	  
  
  if @i_fecha_ini is not null AND @i_fecha_fin is not null select @w_criterio = 4
  if @i_grupo     is not null                         	 select @w_criterio = 3
  if @i_cuenta    is not null                         	 select @w_criterio = 2
  if @i_cliente   is not null                         	 select @w_criterio = 1
  
  if @w_criterio = 99 begin
      select 
	  @w_error = 9999,
	  @w_msg_error = 'Ingrese al menos un criterio de búsqueda: Rango de fechas, cliente o Nro de cuenta'
      goto ERROR	
  end
  
  if @w_criterio = 4 begin

	  if @i_fecha_ini > @i_fecha_fin begin
         select 
	     @w_error = 9999,
		 @w_msg_error = 'Fecha Desde es mayor a la Fecha Hasta'
         goto ERROR	
	  end
	  
	  select @w_dias = DATEDIFF(day,@i_fecha_ini, @i_fecha_fin)
	  
	  if @w_dias > 90 begin
         select 
	     @w_error = 9999,
		 @w_msg_error = 'El rango de búsqueda por fechas debe ser menor a 90 días'
         goto ERROR	
	  end

  end
    
  if @w_criterio = 1 begin	
      insert into #resultado1(
      fecha_fallo, 	 		consecutivo,		linea,	
      cliente,		 		nombre, 			banco,
      buc, 			 		tipo,				cuenta,
      causa_rechazo,  		grupo,				nombre_grupo,
      monto, 				accion,				fecha_accion,
      usuario)
      select 
      odf_fecha,   	 		odf_consecutivo,	odf_linea,
      odf_cliente,			'',					odf_banco,
      '',					odf_tipo,		 	odf_cuenta,
      odf_causa_rechazo,	0,					'',
      odf_monto,			odf_accion,			odf_accion_fecha,
      odf_accion_user
      from ca_santander_orden_deposito_fallido
      where odf_cliente = @i_cliente 
      
      if @@error != 0 begin
            select 
			@w_error = 9999,
            @w_msg_error = 'Error, no existe cliente'
            goto ERROR
         end
      
  end
  
  if @w_criterio = 2 begin
      insert into #resultado1(
      fecha_fallo, 	 		consecutivo,		linea,	
      cliente,		 		nombre, 			banco,
      buc, 			 		tipo,				cuenta,
      causa_rechazo,  		grupo,				nombre_grupo,
      monto, 				accion,				fecha_accion,
      usuario)
      select 
      odf_fecha,   	 		odf_consecutivo,	odf_linea,
      odf_cliente,		 	'',					odf_banco,
      '',				 	odf_tipo,		 	odf_cuenta,
      odf_causa_rechazo,	0,					'',
      odf_monto,			odf_accion,			odf_accion_fecha,
      odf_accion_user
      from ca_santander_orden_deposito_fallido
      where odf_cuenta = @i_cuenta 
      
      if @@error != 0 begin
            select 
			@w_error = 9999,
            @w_msg_error = 'Error, no existe cuenta'
            goto ERROR
         end
      
  end
  
  if @w_criterio = 3 begin
      insert into #resultado1(
      fecha_fallo, 	 		consecutivo,		linea,	
      cliente,		 		nombre, 			banco,
      buc, 			 		tipo,				cuenta,
      causa_rechazo,  		grupo,				nombre_grupo,
      monto, 				accion,				fecha_accion,
      usuario)
      select 
      odf_fecha,   	 		odf_consecutivo,	odf_linea,
      odf_cliente,		 	'',					odf_banco,
      '',				 	odf_tipo,		 	odf_cuenta,
      odf_causa_rechazo,	0,					'',
      odf_monto,			odf_accion,			odf_accion_fecha,
      odf_accion_user
      from ca_santander_orden_deposito_fallido
      where odf_cliente in (select cg_ente from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_fecha_desasociacion is null)
      	   
      if @@error != 0 begin
            select 
			@w_error = 9999,
            @w_msg_error = 'Error, no existe grupo'
            goto ERROR
         end
      
  end
  
  if @w_criterio = 4 begin
      insert into #resultado1(
      fecha_fallo, 	 		consecutivo,		linea,	
      cliente,		 		nombre, 			banco,
      buc, 			 		tipo,				cuenta,
      causa_rechazo,  		grupo,				nombre_grupo,
      monto, 				accion,				fecha_accion,
      usuario)
      select 
      odf_fecha,   	 		odf_consecutivo,	odf_linea,
      odf_cliente,		 	'',					odf_banco,
      '',				 	odf_tipo,		 	odf_cuenta,
      odf_causa_rechazo,	0,					'',
      odf_monto,			odf_accion,			odf_accion_fecha,
      odf_accion_user
      from ca_santander_orden_deposito_fallido
      where odf_fecha between @i_fecha_ini and @i_fecha_fin
      
      if @@error != 0 begin
            select 
            @w_error = 9999,
            @w_msg_error = 'Error, no existen registros con la rango de fecha ingresado'
            goto ERROR
         end
      
  end
  
  select * into #resultado2
  from #resultado1
  where tipo = isnull(@i_tipo,tipo)
  and accion = isnull(@i_accion,accion)
  and fecha_fallo >= isnull(@i_fecha_ini,fecha_fallo)
  and fecha_fallo <= isnull(@i_fecha_fin,fecha_fallo)
  and cliente = isnull(@i_cliente,cliente)
  and cuenta = isnull(@i_cuenta,cuenta)
  
  --Se obtiene nombre del clientes
  update #resultado2
  set nombre = en_nomlar
  from cobis..cl_ente
  where en_ente = cliente
  
  if @@error != 0 begin
      select 
      --@w_error = 708152,
      @w_msg_error = 'Error, no existen registros con la rango de fecha ingresado'
      goto ERROR
      end
  
  --Se obiene codigo BUC	
  update #resultado2
  set buc = en_banco
  from cobis..cl_ente
  where en_ente = cliente
  
  if @@error != 0 begin
      select 
      --@w_error = 708152,
      @w_msg_error = 'Error, no existen registros con la rango de fecha ingresado'
      goto ERROR
      end
   
  --Se obtiene nombre del grupo
   select
   gr_banco 		= odf_banco,
   gr_operacion	    = convert(varchar(30), ''),
   gr_grupo_id 	    = convert(int,0),
   gr_grupo_nom 	= convert(varchar(64), ''),
   gr_cliente		= odf_cliente,
   gr_tipo			= odf_tipo
   into #grupo
   from ca_santander_orden_deposito_fallido
   
   if @@error != 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'Error al cargar registro de grupos'
      goto ERROR
   end
   
   update #grupo set 
   gr_operacion = op_operacion
   from ca_operacion
   where op_banco = gr_banco
   
   if @@error != 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'Error al actualizar id de grupos'
      goto ERROR
   end
   
   --para garantias
   update #grupo set 
   gr_operacion = op_operacion
   from ca_operacion,#grupo
   where op_cliente = gr_cliente
   and gr_tipo = 'GAR'
   
   if @@error != 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'Error al actualizar id de grupos para garantias'
      goto ERROR
   end
  
   update #grupo set 
   gr_grupo_id = dc_grupo
   from ca_det_ciclo
   where dc_operacion = gr_operacion
   
   if @@error != 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'Error al actualizar id de grupos'
      goto ERROR
   end
   
   update #grupo set 
   gr_grupo_nom = gr_nombre
   from cobis..cl_grupo
   where gr_grupo = gr_grupo_id
   
   if @@error != 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'Error al actualziar registros de grupos'
      goto ERROR
   end
   
   update #resultado2 set 
   grupo = gr_grupo_id,
   nombre_grupo = gr_grupo_nom
   from #grupo
   where gr_banco = banco
  
  if @@error != 0 begin
      select 
      --@w_error = 708152,
      @w_msg_error = 'Error, no existen registros con la rango de fecha ingresado'
      goto ERROR
      end
  
  select 				
      'FECHA_FALLO' 	 = convert(varchar(10), fecha_fallo, 103),
      'CONSECUTIVO'	 = consecutivo,
      'LINEA'			 = linea,
      'CLIENTE' 		 = cliente,		
      'NOMBRE_CLIENTE' = nombre,
      'PRESTAMO'		 = banco,
      'BUC' 			 = buc,				
      'TIPO' 			 = tipo,			
      'CUENTA' 		 = cuenta,			
      'CAUSA_RECHAZO'  = causa_rechazo,	
      'GRUPO' 		 = grupo,		
      'NOMBRE_GRUPO' 	 = nombre_grupo,	
      'MONTO' 		 = monto,			
      'ACCION' 		 = accion,			
      'FECHA_ACCION' 	 = CONVERT(CHAR(19),CONVERT(DATETIME,fecha_accion,101),120),	
      'USUARIO' 		 = usuario			
  from #resultado2
  order by nombre

end

--Accion de cambiar a la mejor cuenta del cliente 
if @i_operacion = 'C'
begin

   select 
   @w_cliente = odf_cliente,
   @w_cuenta  = odf_cuenta,
   @w_accion  = odf_accion,
   @w_fecha  = odf_fecha
   from ca_santander_orden_deposito_fallido
   where odf_fecha 		= @i_fecha 
   and odf_consecutivo 	= @i_consecutivo 
   and odf_linea 		= @i_linea
   
   if @@rowcount = 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'No existen datos para para verificar el cambio de cuenta'         
      goto ERROR
   end
   
   if @w_accion != '1' begin
      select 
      @w_error = 9999,
      @w_msg_error = 'El registro ya tiene una acción'
      goto ERROR
   end
   
   select @w_fecha_minima = dateadd(DAY,-@w_dias_maximo,@w_fecha_proceso)
   
   if @w_fecha <= @w_fecha_minima begin
      select 
      @w_error = 9999,
      @w_msg_error = 'Se está re-intentando dispersar registros muy viejos'
      goto ERROR
   end
   
   if @i_cuenta = @w_cuenta begin
     select 
      @w_error = 9999,
      @w_msg_error = 'La cuenta selecionada es la misma que ya esta registrada'
      goto ERROR
   end
   
   update cobis..cl_ente_aux set 
   ea_cta_banco = @i_cuenta
   where ea_ente = @w_cliente 
   
   if @@error != 0 begin
      select 
      --@w_error = 710002,
      @w_msg_error = 'Error, no se pudeo cambiar de cuenta'
      goto ERROR
      end
	
   select @i_operacion = 'R'
end

--Accion de reinternar procesar la dispersion 
if @i_operacion = 'R' begin

   select 
   @w_cliente = odf_cliente,
   @w_cuenta  = odf_cuenta,
   @w_accion  = odf_accion,
   @w_fecha  = odf_fecha
   from ca_santander_orden_deposito_fallido
   where odf_fecha 		= @i_fecha 
   and odf_consecutivo 	= @i_consecutivo 
   and odf_linea 		= @i_linea
   
   if @@rowcount = 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'No existen datos para para verificar el cambio de cuenta'         
      goto ERROR
   end
   
   if @w_accion != '1' begin
      select 
      @w_error = 9999,
      @w_msg_error = 'El registro ya tiene una acción'
      goto ERROR
   end
   
   select @w_fecha_minima = dateadd(DAY,-@w_dias_maximo,@w_fecha_proceso)
   
   if @w_fecha <= @w_fecha_minima begin
      select 
      @w_error = 9999,
      @w_msg_error = 'Se está re-intentando dispersar registros muy viejos'
      goto ERROR
   end
   
   if @@rowcount = 0 begin
      select @w_commit = 'S'
      begin tran
   end

  
   insert into ca_santander_orden_deposito_resp( 
   sod_fecha       , 	sod_fecha_real,  	sod_consecutivo,	
   sod_linea       ,    sod_banco     ,  	sod_operacion  ,
   sod_secuencial  ,    sod_linea_dato,   	sod_tipo       ,
   sod_monto       ,    sod_cliente   ,   	sod_cuenta     ,
   sod_fecha_valor )
   select 	
   sod_fecha       , 	sod_fecha_real,  	sod_consecutivo,	
   sod_linea       ,    sod_banco     ,  	sod_operacion  ,
   sod_secuencial  ,    sod_linea_dato,   	sod_tipo       ,
   sod_monto       ,    sod_cliente   ,   	sod_cuenta     ,
   sod_fecha_valor 	
   from ca_santander_orden_deposito
   where sod_fecha 	   = @i_fecha 
   and sod_consecutivo = @i_consecutivo 
   and sod_linea 	   = @i_linea
   
   delete from ca_santander_orden_deposito 
   where sod_fecha 	   = @i_fecha 
   and sod_consecutivo = @i_consecutivo 
   and sod_linea 	   = @i_linea
   
   if @@error != 0 begin
      select 
      --@w_error = 710002,
      @w_msg_error = 'Error, no se pude eliminar registro para reintento de dispersion'
      goto ERROR
   end
   
   update ca_santander_orden_deposito_fallido set 
   odf_accion 		   = @i_accion,
   odf_accion_fecha    = @s_date +' '+ substring(convert(varchar(8), GETDATE(), 108),0,8), --substring(convert(varchar,@i_param1, 101),1,2)
   odf_accion_user	   = @s_user	
   where odf_fecha     = @i_fecha 
   and odf_consecutivo = @i_consecutivo 
   and odf_linea = @i_linea
   
   if @@error != 0 begin
      select 
      --@w_error = 710002,
      @w_msg_error = 'Error, no se pudo actualiar registro de accion'
      goto ERROR
   end
   
   if @w_commit = 'S' begin
      commit tran
	  select @w_commit = 'N'
   end
   
end

--Accion de cancelar la dispercion
if @i_operacion = 'P' 
begin

   if not exists(select 1 from ca_santander_orden_deposito where sod_fecha = @i_fecha and sod_consecutivo = @i_consecutivo and sod_linea = @i_linea) begin
		select 
	    @w_error = 9999,
	    @w_msg_error = 'No existe registro para Cancelar obligacion'
        goto ERROR
   end
   
   select 
   @w_tipo = sod_tipo
   from ca_santander_orden_deposito
   where sod_fecha 		= @i_fecha 
   and sod_consecutivo 	= @i_consecutivo 
   and sod_linea 		= @i_linea
   
   if @@rowcount = 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'No existe registro para Cancelar obligacion'         
      goto ERROR
   end   
   
   if @w_tipo != 'DES' begin
      select 
      @w_error = 9999,
      @w_msg_error = 'Error, ha seleccionado un registro diferente a Desembolso'         
      goto ERROR
   end   

   select 
   @w_banco		= sod_banco,
   @w_cuenta  	= sod_cuenta,
   @w_monto 	= sod_monto
   from ca_santander_orden_deposito
   where sod_fecha 		= @i_fecha 
   and sod_consecutivo 	= @i_consecutivo 
   and sod_linea 		= @i_linea
   
   if @@rowcount = 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'No existen datos para forma de pago'         
      goto ERROR
   end   
   
   select 
   @w_secuencial = max(tr_secuencial), 
   @w_operacion  = max(tr_operacion) 
   from ca_transaccion
   where tr_tran = 'DES'
   and tr_banco = @w_banco
   and tr_estado in('ING', 'CON')
   
   if @@rowcount = 0 begin
         select 
         @w_error = 9999,
         @w_msg_error = 'No existen datos para forma de pago'         
         goto ERROR
      end
   
   select 
   @w_concepto = rtrim(ltrim(dtr_concepto))
   from ca_det_trn
   where dtr_operacion = @w_operacion
   and dtr_secuencial = @w_secuencial
   and dtr_codvalor < 10000
   
   if @@rowcount = 0 begin
         select 
         @w_error = 9999,
         @w_msg_error = 'No existen datos para forma de pago'         
         goto ERROR
      end
   
   select 
   @w_forma_pago = rtrim(ltrim(cp_producto_reversa))
   from ca_producto
   where cp_producto = @w_concepto
   
   if @@rowcount = 0 begin
         select 
         @w_error = 9999,
         @w_msg_error = 'No existen datos para forma de pago'      
         goto ERROR
      end
   
   select 
   @w_oficina   	= op_oficina,
   @w_fecha_valor	= op_fecha_ini
   from ca_operacion
   where op_banco = @w_banco
   
   if @@rowcount = 0 begin
      select 
      @w_error = 9999,
      @w_msg_error = 'No existen datos para forma de pago'         
      goto ERROR
   end
   
   if @@trancount = 0 begin
      select @w_commit = 'S'
      begin tran
   end
   
   EXEC @w_error     = sp_pago_cartera_srv
   @s_user           = @s_user, 		--pantalla
   @s_term           = @s_term, 		--pantalla
   @s_date           = @s_date, 		--pantalla
   @s_ofi            = @w_oficina,  	--oficina de operacion ca_operacion campo op_oficina       
   @i_banco          = @w_banco,		--ca_santerder_orden_deposito_fallido , campo banco, agregar
   @i_fecha_valor    = @w_fecha_valor,  --ca_operacion, campo op_fecha_ini
   @i_forma_pago     = @w_forma_pago,	--proceso de arriba comentado
   @i_monto_pago     = @w_monto,		--ca_santerder_orden_deposito_fallido campo monto
   @i_cuenta         = @w_cuenta,       --ca_santerder_orden_deposito_fallido, campo cuenta
   @o_msg            = @w_msg_error out,
   @o_secuencial_ing = @w_secuencial_ing out
   
   if @w_error != 0 begin
      select 
      @w_error = 710002,
	  @w_msg_error = 'ERROR AL EJECUTAR EL PAGO: ' + convert(varchar,@w_banco)       
      goto ERROR
   end

   update ca_santander_orden_deposito_fallido set 
   odf_accion 		   = @i_accion,
   odf_accion_fecha    = @s_date +' '+ substring(convert(varchar(8), GETDATE(), 108),0,8),
   odf_accion_user	   = @s_user	
   where odf_fecha     = @i_fecha 
   and odf_consecutivo = @i_consecutivo 
   and odf_linea 	   = @i_linea
   
   if @@error != 0 begin
      select 
      @w_error = 710002,
      @w_msg_error = 'Error, no se pudo actualiar registro de accion'
      goto ERROR
   end

   if @w_commit = 'S' begin
      select @w_commit = 'N'
	  commit tran
   end
   
end

if @i_operacion = 'A' 
begin
   select @o_parametro = @w_dias_maximo
end

return 0

ERROR:

if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end

exec cobis..sp_cerror 
@t_from = @w_sp_name, 
@i_num = @w_error, 
@i_msg = @w_msg_error,
@i_sev = 0

return @w_error

go
