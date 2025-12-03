/************************************************************************/
/*   Archivo:              sp_linea.sp                                  */
/*   Stored procedure:     sp_linea                                     */
/*   Base de datos:        cob_credito                                  */
/*   Producto:             Credito                                      */
/*   Disenado por:         Luis Ponce                                   */
/*   Fecha de escritura:   Julio 2020                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Realiza el ingreso, actualizacion y consulta y borrado de lineas de*/
/*   credito.                                                           */
/************************************************************************/
/*                                 MODIFICACIONES                       */
/*   FECHA           AUTOR                RAZON                         */
/*   20/Jul/2020     Luis Ponce           Emision Inicial               */
/*   16/Jun/2021     Carlos Veintemilla   Agregar operacion x           */
/************************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_linea')
	DROP PROCEDURE dbo.sp_linea
GO

create proc sp_linea (
  	@s_ssn			int = null,
  	@s_user			login = null,
  	@s_sesn			int = null,
    @s_term			varchar(30) = null,
    @s_date			datetime = null,
    @s_srv			varchar(30) = null,
    @s_lsrv			varchar(30) = null,
    @s_rol			smallint = NULL,
    @s_ofi			smallint = NULL,
    @s_org_err		char(1) = NULL,
    @s_error		int = NULL,
    @s_sev			tinyint = NULL,
    @s_msg			descripcion = NULL,
    @s_org			char(1) = NULL,
 	@t_debug    		char(1) = 'N',
	@t_rty			char(1)  = null,
	@t_file     		varchar(10) = null,
	@t_from     		varchar(32) = null,
	@t_trn	    		smallint = null,   
   	@i_operacion          	char(1)  = null,
    @i_numero		int = null,
	@i_num_banco		cuenta = null,
	@i_oficina		smallint = null,
	@i_tramite		int = null,
	@i_cliente		int = null,
	@i_grupo		int = null,
	@i_original		int = null,
	@i_fecha_aprob		datetime = null,
	@i_fecha_inicio		datetime = null,
	@i_per_revision		catalogo = null,
	@i_fecha_vto		datetime = null,
	@i_dias			smallint = null,
	@i_condicion_especial	varchar(255) = null,
	@i_monto		money = null,
	@i_moneda		tinyint = null,
	@i_rotativa		char(1) = null,
    @i_riesgo               money   = null,           --LRE 15/Sep/2006
	@i_lin_anterior		cuenta  = NULL,		  --LRE 08/Nov/2006  numero de linea anterior
	@i_toperacion       catalogo = NULL,
	@i_tplazo	        catalogo = NULL,
	@i_plazos	        SMALLINT = NULL,
	@i_naturaleza       catalogo = NULL,
	@i_sector           catalogo = NULL,
	@i_estado           catalogo = NULL,
    @o_numero	        INT      = NULL OUT,
    @o_li_num_banco     VARCHAR(32) = NULL OUT,
    @o_dias             INT         = NULL OUT,
    @o_fecha_vto        DATETIME    = NULL OUT   
	
)
as

declare
   @w_today             datetime,     /* fecha del dia */ 
   @w_return            int,          /* valor que retorna */
   @w_sp_name           varchar(32),  /* nombre stored proc*/
   @w_existe            tinyint,      /* existe el registro*/
   @w_numero		int,
   @w_num_banco		cuenta,
   @w_oficina		smallint,
   @w_desc_oficina	descripcion,
   @w_tramite		int,
   @w_cliente		int,
   @w_cli_nombre	varchar(128),
   @w_grupo	        int,
   @w_gru_nombre        descripcion,
   @w_original		int,
   @w_fecha_aprob	datetime,
   @w_fecha_inicio	datetime,
   @w_fecha_vto         datetime,
   @w_dias		smallint,
   @w_condicion         varchar(255),
   @w_segmento		catalogo,
   @w_per_revision	catalogo,
   @w_desc_per_revision	descripcion,
   @w_ultima_rev	datetime,
   @w_prox_rev		datetime,
   @w_usuario_rev	login,
   @w_nombre_rev	descripcion,
   @w_monto		money,		/* total monto */
   @w_utilizado		money,		/* total utilizado */
   @w_moneda		tinyint,
   @w_desc_moneda	descripcion,
   @w_rotativa		char(1), 
   @w_aux_monto 	money,		/* monto asignado por moneda */
   @w_aux_utiliz	money,		/* valor utilizado por moneda */
   @w_factor		smallint,	/* factor de conversi¢n a d¡as */
   @w_riesgo		money,
   @w_calificacion      char(1),
   @w_monto_flinea      money,
   @w_calif    		char(1),
   @w_ries     		money,
   @w_monto_utilizado_nofacttitul	money,		--II CMI 29Sept2006
   @w_monto_utilizado_facttitul		money,		--II CMI 29Sept2006
   @w_monto_utilizado_sob		money,		--II CMI 29Sept2006
   @w_monto_utilizado_op		money,		--II CMI 29Sept2006
   @w_monto_utilizado_visa		money,		--II CMI 29Sept2006
   @w_incluye_cuentas			char(1),	--II CMI 29Sept2006
   @w_incluye_visa			char(1),	--II CMI 29Sept2006
   @w_mensaje 				varchar(255),	--II CMI 29Sept2006	
   @w_lin_anterior			cuenta,		--LRE 08/Nov/2006
   @w_moneda_ant			tinyint,	--LRE 08/Nov/2006
   @w_lin_tramite_ant			int,		--LRE 09/Nov/2006
   @w_lin_anterior_int			int,		--LRE 09/Nov/2006
   @w_num_lin_banco			cuenta,         --LRE 30/Nov/2006
   @w_tra_renov                         int,            --LRE 18/Dic/2006
   @w_toperacion			catalogo,       --LRE 20/Dic/2006
   @w_producto				catalogo,       --LRE 20/Dic/2006
   @w_moneda_fac_ant			tinyint,        --LRE 20/Dic/2006
   @w_monto_fac_ant                     money,		--LRE 20/Dic/2006
   @w_tplazo				catalogo,	--LRE 20/Dic/2006
   @w_plazos				smallint, 	--LRE 20/Dic/2006
   @w_condicion_especial		varchar(255),   --LRE 20/Dic/2006
   @w_facilidad				char(1),        --LRE 20/Dic/2006
   @w_rotativa_fac_ant			char(1),	--LRE 20/Dic/2006
   @w_destino				catalogo,       --LRE 20/Dic/2006
   @w_cobertura   			int,		--LRE 20/Dic/2006
   @w_porc_entrada			float,		--LRE 20/Dic/2006
   @w_cartera_cheques			char(1),	--LRE 20/Dic/2006
   @w_utilizado_fac			money,		--LRE 20/Dic/2006
   @w_gp_tramite			int,			
   @w_gp_garantia			varchar(64),		
   @w_gp_clasificacion			char(1), 		
   @w_gp_exceso				char(1), 		
   @w_gp_monto_exceso			money,			
   @w_gp_abierta			char(1), 		
   @w_gp_deudor				int,			
   @w_gp_est_garantia			char(1),		
   @w_gp_facilidad			char(1), 		
   @w_gp_toperacion			varchar(10),
   @w_dias_facilidad			int,			--II CMI 29Sept2006

   @w_toperacion_veh			catalogo,		--II CMI 29Sept2006
   @w_ssn				int,
   @w_monto_utilizado_cartera_lp	money,			--II CMI 29Dic2006
   @w_monto_subfacilidad		MONEY,			--II CMI 23Ene2007
   @w_char_oficina	varchar(5),
   @w_secuencial	int,
   @w_char_secuencial	varchar(20),
   @w_prefijo		char(2),
   @w_li_num_banco    VARCHAR(32),
   @w_li_estado       VARCHAR(32),
   @i_reservado        MONEY,
	@i_producto	catalogo,
	@w_montos_distribucion MONEY,
	@w_siguiente   INT,
	@w_filial      INT,
	@w_li_naturaleza catalogo,
	@w_sector        catalogo,
	@w_subtipo       CHAR(1)

   
select @w_today = @s_date
select @w_sp_name = 'sp_linea'
select @w_prefijo = 'LC' --'CU' --'LC'


/********************************************************/
/*	DEBUG						*/


/***********************************************************/
/* Codigos de Transacciones                                */
/*
if (@t_trn <> 21026 and @i_operacion = 'I') or
   (@t_trn <> 21126 and @i_operacion = 'U') or
   (@t_trn <> 21226 and @i_operacion = 'D') or
   (@t_trn <> 21326 and @i_operacion = 'V') or
   (@t_trn <> 21326 and @i_operacion = 'S') or
   (@t_trn <> 21526 and @i_operacion = 'Q') or
   (@t_trn <> 21826 and @i_operacion = 'R') or 
   (@t_trn <> 21026 and @i_operacion = 'T') OR
   (@t_trn <> 21026 and @i_operacion = 'A')   

begin
--/ tipo de transaccion no corresponde --/

    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 2101006
    return 1 
end
*/

/*** VERIFICACION DE CAMPOS NULOS Y CALCULOS VARIOS ***/
If (@i_operacion = 'I') or
   (@i_operacion = 'U')
begin
   if (@i_tramite = null) or
      (@i_oficina = null) or
      (@i_cliente is null)
   begin
       --Campos NOT NULL con valores nulos 
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 2101001
        return 1 
   end

end


If (@i_operacion = 'I') or
   (@i_operacion = 'U') or
   (@i_operacion = 'R') OR
   (@i_operacion = 'A')
   
begin
   /* calcular numero de dias*/
   if @i_dias is null
   	  select @i_dias = datediff(dd, @i_fecha_inicio, @i_fecha_vto)
   /* calcular fecha de vencimiento */
   if @i_fecha_vto is null
   	  select @i_fecha_vto = dateadd(dd, @i_dias, @i_fecha_inicio)
   
   SELECT @o_dias = @i_dias
   SELECT @o_fecha_vto = @i_fecha_vto 
   
end

If (@i_operacion = 'U') or
   (@i_operacion = 'R') or
   (@i_operacion = 'D') or
   (@i_operacion = 'Q') or
   (@i_operacion = 'V') 
begin
   /** obtener el numero de linea dado el numero de tramite **/
   if @i_numero is null and @i_tramite is not null
		select @i_numero = li_numero
		from	cr_linea
		where	li_tramite = @i_tramite
    
	/** obtener el numero de linea, dado el numero de banco **/
	if @i_numero is null and @i_num_banco is not null and @i_num_banco <> ' '
		select @i_numero = li_numero
		from	cr_linea
		where	li_num_banco = @i_num_banco

end


/** OBTENER EL REGISTRO ACTUAL **/
If (@i_operacion = 'U') or
   (@i_operacion = 'R') or
   (@i_operacion = 'D') or
   (@i_operacion = 'Q') or
   (@i_operacion = 'V') or
   (@i_operacion = 'T') OR 
   (@i_operacion = 'S')
begin
	select	
	    @w_numero = li_numero,
		@w_num_banco = li_num_banco,
		@w_oficina = li_oficina,
		@w_tramite = li_tramite,
		@w_cliente = li_cliente,
		@w_fecha_aprob = li_fecha_aprob,
		@w_fecha_inicio = li_fecha_inicio,
        @w_fecha_vto = li_fecha_vto, --* (case li_fecha_vto 					--TRugel 04/02/08
		@w_dias = li_dias,
		@w_monto  = li_monto,
		@w_moneda = li_moneda,
		@w_utilizado = isnull(li_utilizado,0),
		@w_rotativa = li_rotativa,
        @w_li_estado = CASE li_estado WHEN 'V' THEN 'VIGENTE' ELSE ' ' END,
        @w_li_naturaleza = li_naturaleza,
        @w_sector = (SELECT tr_sector from	cr_tramite WHERE tr_tramite = L.li_tramite)
--*		@w_original = li_original,
--*		@w_per_revision = li_per_revision,
--*		@w_condicion = li_condicion_especial,
--*		@w_ultima_rev = li_ult_rev,
--*		@w_prox_rev = li_prox_rev,
--*		@w_usuario_rev = li_usuario_rev,
	from	cr_linea L
	where	li_numero = @i_numero --@i_cliente --* li_numero = @i_numero
    	if @@rowcount > 0
            select @w_existe = 1
    	else
            select @w_existe = 0
end

/*
--II CMI 29Sept2006 validar que el monto cubra todas las operaciones vigentes del cliente
If (@i_operacion = 'I') or
   (@i_operacion = 'U')
begin

	select  @w_monto_utilizado_nofacttitul = 0,
		@w_monto_utilizado_facttitul = 0,
		@w_monto_utilizado_sob = 0,
		@w_monto_utilizado_op = 0,
		@w_monto_utilizado_visa = 0,
		@w_monto_utilizado_cartera_lp = 0


	if @i_operacion = 'I'
		select @w_cliente = @i_cliente

	--Busca parametro para saber si ya esta desarrollada logica en que linea maneja cuentas y visa
	select @w_incluye_cuentas = pa_char
	from cobis..cl_parametro
	where pa_producto = 'CRE'
	and pa_nemonico = 'LCIC'

	select @w_incluye_visa = pa_char
	from cobis..cl_parametro
	where pa_producto = 'CRE'
	and pa_nemonico = 'LCIV'

       	if @i_lin_anterior is not null
	begin
--print 'entro a validar monto'
	--LRE 08/Nov/2006 Verificar monto Utilizado en caso de Renovaciones de Linea
		select @w_monto_utilizado_nofacttitul = isnull(sum(am_acumulado + am_gracia - am_pagado),0) --* - am_exponencial),0)
						from 	cob_cartera..ca_dividendo,
							cob_cartera..ca_rubro_op,
							cob_cartera..ca_amortizacion,
							cob_cartera..ca_operacion
						where	di_operacion = op_operacion
						and	di_estado   != 3
						and	am_operacion = op_operacion
						and	ro_operacion = op_operacion
						and	am_operacion = di_operacion
						and	am_dividendo = di_dividendo
				        	and	ro_operacion = am_operacion
						and	ro_concepto  = am_concepto 
					        and     ro_tipo_rubro= 'C'
				        	and     ro_concepto not in ('SEGVEH')
						and     op_toperacion <> 'FACTTITUL'
						and     op_cliente = @w_cliente
						and     op_estado in (1,2,8,4,6)
    						and     op_lin_credito = @i_lin_anterior

		select @w_monto_utilizado_facttitul = isnull(sum(am_acumulado + am_gracia - am_pagado),0) --* - am_exponencial),0)
						from 	cob_cartera..ca_dividendo,
							cob_cartera..ca_rubro_op,
							cob_cartera..ca_amortizacion,
							cob_cartera..ca_operacion
						where	di_operacion = op_operacion
						and	di_estado   != 3
						and	am_operacion = op_operacion
						and	ro_operacion = op_operacion
						and	am_operacion = di_operacion
						and	am_dividendo = di_dividendo
				        	and	ro_operacion = am_operacion
						and	ro_concepto  = am_concepto 
					        and     ro_tipo_rubro= 'C'
						and     op_toperacion = 'FACTTITUL'
						and     op_cliente = @w_cliente
						and     op_estado in (1,2,8,4,6)
    						and     op_lin_credito = @i_lin_anterior
        end
        else
	begin
		select @w_monto_utilizado_nofacttitul = isnull(sum(am_acumulado + am_gracia - am_pagado - am_exponencial),0)
						from 	cob_cartera..ca_dividendo,
							cob_cartera..ca_rubro_op,
							cob_cartera..ca_amortizacion,
							cob_cartera..ca_operacion
						where	di_operacion = op_operacion
						and	di_estado   != 3
						and	am_operacion = op_operacion
						and	ro_operacion = op_operacion
						and	am_operacion = di_operacion
						and	am_dividendo = di_dividendo
				        	and	ro_operacion = am_operacion
						and	ro_concepto  = am_concepto 
					        and     ro_tipo_rubro= 'C'
				        	and     ro_concepto not in ('SEGVEH')
						and     op_toperacion <> 'FACTTITUL'
						and     op_cliente = @w_cliente
						and 	datediff(dd,op_fecha_ini, op_fecha_fin) <= @w_dias_facilidad
						and     op_estado in (1,2,8,4,6)

		select @w_monto_utilizado_facttitul = isnull(sum(am_acumulado + am_gracia - am_pagado - am_exponencial),0)
						from 	cob_cartera..ca_dividendo,
							cob_cartera..ca_rubro_op,
							cob_cartera..ca_amortizacion,
							cob_cartera..ca_operacion
						where	di_operacion = op_operacion
						and	di_estado   != 3
						and	am_operacion = op_operacion
						and	ro_operacion = op_operacion
						and	am_operacion = di_operacion
						and	am_dividendo = di_dividendo
				        	and	ro_operacion = am_operacion
						and	ro_concepto  = am_concepto 
					        and     ro_tipo_rubro= 'C'
						and     op_toperacion = 'FACTTITUL'
						and     op_cliente = @w_cliente
						and 	datediff(dd,op_fecha_ini, op_fecha_fin) <= @w_dias_facilidad
						and     op_estado in (1,2,8,4,6)

		select @w_monto_utilizado_cartera_lp =  isnull(sum(isnull((select lo_valor_financiar
                                 					from cob_cartera..lea_operacion
                                 					where lo_operacion = y.op_operacion), y.op_monto)),0)
						from 	cob_cartera..ca_operacion y
						where	op_cliente = @w_cliente
						and     op_estado in (1,2,8,4,6)
						and 	datediff(dd,op_fecha_ini, op_fecha_fin) > @w_dias_facilidad

	--TANTO PARA LINEA NUEVA COMO PARA RENOVACION SE DEBE VALIDAR EL SALDO DEL RIESGO Y NO EL VALOR ORIGINAL
	--PORQUE LAS DE LARGO PLAZO YA PUEDEN SER REVOLVENTES


		select @w_monto_utilizado_nofacttitul = isnull(sum(am_acumulado + am_gracia - am_pagado),0) --* - am_exponencial),0)
						from 	cob_cartera..ca_dividendo,
							cob_cartera..ca_rubro_op,
							cob_cartera..ca_amortizacion,
							cob_cartera..ca_operacion
						where	di_operacion = op_operacion
						and	di_estado   != 3
						and	am_operacion = op_operacion
						and	ro_operacion = op_operacion
						and	am_operacion = di_operacion
						and	am_dividendo = di_dividendo
				        	and	ro_operacion = am_operacion
						and	ro_concepto  = am_concepto 
					        and     ro_tipo_rubro= 'C'
				        	and     ro_concepto not in ('SEGVEH')
						and     op_toperacion <> 'FACTTITUL'
						and     op_cliente = @w_cliente
						and     op_estado in (1,2,8,4,6)


		select @w_monto_utilizado_facttitul = isnull(sum(am_acumulado + am_gracia - am_pagado ),0) --*- am_exponencial),0)
						from 	cob_cartera..ca_dividendo,
							cob_cartera..ca_rubro_op,
							cob_cartera..ca_amortizacion,
							cob_cartera..ca_operacion
						where	di_operacion = op_operacion
						and	di_estado   != 3
						and	am_operacion = op_operacion
						and	ro_operacion = op_operacion
						and	am_operacion = di_operacion
						and	am_dividendo = di_dividendo
				        	and	ro_operacion = am_operacion
						and	ro_concepto  = am_concepto 
					        and     ro_tipo_rubro= 'C'
						and     op_toperacion = 'FACTTITUL'
						and     op_cliente = @w_cliente
						and     op_estado in (1,2,8,4,6)

	end --else


--print 'monto1: %1! monto2: %2! monto3:%3! monto4:%4!', @w_monto_utilizado_nofacttitul, @w_monto_utilizado_facttitul, @w_monto_utilizado_sob, @w_monto_utilizado_visa
*/

   select @w_monto_utilizado_op = 0 --@w_monto_utilizado_nofacttitul + @w_monto_utilizado_facttitul + @w_monto_utilizado_sob + @w_monto_utilizado_visa + @w_monto_utilizado_cartera_lp
--print 'monto utilizado op: %1!', @w_monto_utilizado_op
--end

   --FI CMI 29Sept2006



/**** Value ****/
/***************/
if @i_operacion = 'S'
begin
   
   select @w_subtipo = en_subtipo
   from   cobis..cl_ente
   WHERE en_ente = @i_cliente
       
   IF @w_subtipo = 'C'
      SELECT @w_cli_nombre = en_nombre
      from   cobis..cl_ente
      WHERE  en_ente = @i_cliente
   ELSE
      select @w_cli_nombre = rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre)
      from   cobis..cl_ente
      WHERE en_ente = @i_cliente
       	   
   SELECT 	
	   'Nro.Cupo' = li_num_banco,
	   'Secuencial Cupo' = li_numero,
       'Moneda' = li_moneda, --(SELECT mo_descripcion FROM cobis..cl_moneda WHERE mo_moneda = 0),
       'Monto ' = li_monto,       
	   'Oficina' = li_oficina,       
       'Cliente' = li_cliente,
       'Nombre' = @w_cli_nombre,
       'Fecha Aprobacion' = convert(char(10),li_fecha_aprob,103),
       'Fecha Vto.' = convert(char(10),li_fecha_vto,103),
       'Rotativa' = li_rotativa,        
       'Monto Utilizado' = li_utilizado,
       'Estado'   = li_estado,
       'Naturaleza' = li_naturaleza,
       'Sector'     = (SELECT tr_sector FROM cr_tramite WHERE tr_tramite = L.li_tramite)
--	   	'Tramite' = @w_tramite 
--        'Dias Cupo'  = @w_dias
        FROM cob_credito..cr_linea L
        WHERE li_cliente = @i_cliente
        
   RETURN 0
END

/*Obtener linea*/
If @i_operacion = 'X'
begin
	select 'ID'       = L.li_numero,
	       'LINEA'    = L.li_num_banco,
	       'MONTO'    = convert(varchar(15),OM.om_monto),
	       'UTILIZADO'= convert(varchar(15),isnull(OM.om_utilizado,0)),
		   'DISPONIBLE'= convert(varchar(15),(isnull(OM.om_monto,0)-isnull(OM.om_utilizado,0))) ,
		   'MONEDA' = OM.om_moneda,
		   'DESCRIPCION'=(select mo_descripcion
						from cobis..cl_moneda
						where mo_moneda = OM.om_moneda),
		   'PRODUCTO' = OM.om_toperacion
	from cob_credito..cr_linea L
	join cob_credito..cr_lin_ope_moneda OM on OM.om_linea = L.li_numero
	where L.li_cliente  = @i_cliente
	and L.li_estado= 'V'
	return 0
end


/**** Value ****/
/***************/
if @i_operacion = 'V'
begin

   if @w_existe = 1
   begin
        /* Retornar los datos */
	if @w_cliente IS NOT null 
	begin

	   select @w_cli_nombre = rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre)
	   from   cobis..cl_ente
       where  en_ente = @w_cliente
	   
	   SELECT 	
	   'Nro.Cupo' = @w_num_banco,
	   'Secuencial Cupo' = @w_numero,
	   'Oficina' = @w_oficina,
--	   	'Tramite' = @w_tramite 
       'Cliente' = @w_cliente,
       'Nombre' = @w_cli_nombre,
        'Fecha Aprobacion' = convert(char(10),@w_fecha_aprob,103),
        'Fecha Vto.' = convert(char(10),@w_fecha_vto,103),
--        'Dias Cupo'  = @w_dias
  		'Monto ' = @w_monto,
		
		'Moneda' = (SELECT mo_descripcion FROM cobis..cl_moneda WHERE mo_moneda = 0),
		'Monto Utilizado' = @w_utilizado,
	  	--'Rotativa' = @w_rotativa,
        'Estado'   = @w_li_estado,
        'Naturaleza' = @w_li_naturaleza,
        'Sector'     = @w_sector
        			
       end
       
       
       SELECT 
       'Secuencial Cupo' = om_linea,
       'Producto'        = om_producto,
       'Tipo Operacion'  = om_toperacion,
       'Moneda'          = (SELECT mo_descripcion FROM cobis..cl_moneda WHERE mo_moneda = 0),
       'Monto'           = isnull(om_monto,0),
       'Utilizado'       = isnull(om_utilizado,0),
       'Disponible'      = (isnull(om_monto,0) - isnull(om_utilizado,0)),
       'Plazo'          = om_tplazo,
       'Tipo Plazo'     = om_plazos,
       'Rotativa'       = om_rotativa
        FROM cob_credito..cr_lin_ope_moneda
        WHERE om_linea   =  @i_numero

        return 0
   end
   else
   begin
	/* Registro no existe */
	exec cobis..sp_cerror
       	@t_debug = @t_debug,
       	@t_file  = @t_file, 
       	@t_from  = @w_sp_name,
       	@i_num   = 2101005
       	return 1 
   end
end



/**** Insert ****/
/***************/
if @i_operacion = 'I'
begin
    /*PQU esto no corresponde porque ya se creó el trámite
	exec cobis..sp_cseqnos
	@t_debug = @t_debug,
	@t_file  = @t_file, 
	@t_from  = @w_sp_name,
	@i_tabla = 'cr_tramite',
	@o_siguiente = @i_tramite out */ --fin PQU

   SELECT @i_oficina = @s_ofi
   SELECT 	@i_grupo   = NULL
   SELECT 	@i_original = NULL
   SELECT 	@i_per_revision = NULL 
   SELECT 	@i_condicion_especial = NULL
   SELECT 	@w_monto_utilizado_op = 0	   

   begin TRAN
   
   	/* obtener el maximo n£mero de l¡na de cr‚dito */
   	exec cobis..sp_cseqnos
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_tabla = 'cr_linea',
		@o_siguiente = @o_numero out

	if @o_numero = NULL
	begin
	    	/* No existe tabla en tabla de secuenciales*/
	    	exec cobis..sp_cerror
	    	@t_debug = @t_debug,
	    	@t_file  = @t_file, 
	    	@t_from  = @w_sp_name,
	    	@i_num   = 2101007
	    	return 1 
	end
    
	SELECT @w_secuencial = @o_numero
    /*PQU comentar para que no se genere aqui el número largo  --NO BORRAR LO COMENTADO
	select @w_char_oficina = convert(varchar(5),@i_oficina)

	if @w_secuencial > 0
	begin
		select @w_secuencial = @w_secuencial + 1
	end
	else
	begin
		select @w_secuencial = 1
	end

	--*****  Formar el numero de banco de linea
	
	select @w_char_secuencial = convert(char(10),@w_secuencial)
    select @w_char_secuencial = stuff('00000000000',10,10,@w_char_secuencial)
	select reverse(substring(reverse(@w_char_secuencial),1,10))
	select @w_li_num_banco = @w_prefijo + @w_char_oficina + @w_char_secuencial 
	*/
    select @w_li_num_banco = convert(varchar, @w_secuencial)
	--Fin PQU

/*
	if @w_monto_utilizado_op > @i_monto
	begin
	    	-- Monto de operaciones del cliente mayor al cupo de linea
		select @w_mensaje = 'Monto de operaciones del cliente mayor al cupo de linea:  ' + convert(varchar(20), @w_monto_utilizado_op)
	    	exec cobis..sp_cerror
	    	@t_debug = @t_debug,
	    	@t_file  = @t_file, 
	    	@t_from  = @w_sp_name,
		@i_msg	 = @w_mensaje,
	    	@i_num   = 2101069,
		@i_sev   = 1		--TRugel 06/24/08
	    	return 1 

	end
*/


/*PQU esto no aplica porque el trámite ya se creó antes
INSERT INTO cr_tramite
select 
@i_tramite, 'L', @i_oficina, 'admuser', @i_fecha_inicio, tr_oficial, @i_sector ,tr_ciudad, 'A', tr_nivel_ap, @i_fecha_inicio, tr_usuario_apr,
tr_numero_op, tr_numero_op_banco, tr_riesgo, tr_aprob_por, tr_nivel_por, tr_comite, tr_acta, tr_proposito, tr_razon, tr_txt_razon, tr_efecto,
@i_cliente, tr_nombre, tr_grupo, @i_fecha_inicio, 360, tr_per_revision, tr_condicion_especial, @o_numero, 'PRI', --NULL, --tr_toperacion 
tr_producto, @i_monto, 0, tr_periodo , tr_num_periodos ,tr_destino ,tr_ciudad_destino ,tr_cuenta_corriente ,tr_renovacion ,tr_fecha_concesion,    tr_rent_actual ,
tr_rent_solicitud ,tr_rent_recomend ,tr_prod_actual ,tr_prod_solicitud ,tr_prod_recomend ,tr_clase ,tr_admisible ,tr_noadmis ,tr_relacionado ,
tr_pondera , tr_contabilizado , tr_subtipo ,tr_tipo_producto ,tr_origen_bienes ,tr_localizacion ,tr_plan_inversion , @i_naturaleza ,tr_tipo_financia ,
tr_sobrepasa ,tr_elegible ,tr_forward ,tr_emp_emisora ,tr_num_acciones ,tr_responsable ,tr_negocio ,tr_reestructuracion ,tr_concepto_credito ,tr_aprob_gar ,
tr_cont_admisible ,tr_mercado_objetivo ,tr_tipo_productor ,tr_valor_proyecto ,tr_sindicado ,tr_asociativo ,tr_margen_redescuento ,tr_fecha_ap_ant ,tr_llave_redes ,
tr_incentivo ,tr_fecha_eleg , tr_op_redescuento , tr_fecha_redes , tr_solicitud , tr_montop  ,tr_monto_desembolsop ,tr_mercado ,tr_dias_vig ,tr_cod_actividad ,
tr_num_desemb ,tr_carta_apr ,tr_fecha_aprov ,tr_fmax_redes ,tr_f_prorroga ,tr_nlegal_fi ,tr_fechlimcum ,tr_validado ,tr_sujcred ,tr_fabrica ,tr_callcenter ,
tr_apr_fabrica ,tr_monto_solicitado ,tr_tipo_plazo ,tr_tipo_cuota ,tr_plazo ,tr_cuota_aproximada ,tr_fuente_recurso ,tr_tipo_credito ,tr_migrado ,tr_estado_cont ,
tr_fecha_fija ,tr_dia_pago ,tr_tasa_reest ,tr_motivo ,tr_central ,tr_devuelto_mir ,tr_campana ,tr_alianza ,tr_autoriza_central ,tr_act_financiar ,tr_negado_mir ,
tr_num_devri ,tr_promocion ,tr_acepta_ren ,tr_no_acepta ,tr_emprendimiento ,tr_porc_garantia ,tr_grupal ,tr_experiencia ,tr_monto_max ,tr_monto_min ,
tr_fecha_dispersion ,tr_causa ,tr_fecha_irenova      ,tr_linea_cancelar ,tr_tasa_asociada ,tr_frec_pago ,tr_moneda_solicitada ,tr_provincia ,tr_monto_desembolso ,
tr_tplazo ,tr_cuota  ,tr_proposito_op ,tr_lin_comext ,tr_expromision ,tr_origen_fondos ,tr_sector_cli ,tr_truta ,tr_secuencia ,tr_sector_contable ,tr_enterado ,
tr_otros               ,tr_periodicidad_lcr
from cr_tramite
where tr_tramite = 14050



	if @@error <> 0
	BEGIN
PRINT ' entra error tramite'	
         -- Error en insercion de registro 
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103001
             return 1 
	end


insert into cr_deudores
select 
@i_tramite, @i_cliente, 'D',  de_ced_ruc,    de_segvida, 'N'
from cr_deudores
where de_tramite = 1400
*/ --Fin PQU

SELECT @o_li_num_banco = @w_li_num_banco

    --9001011914 1072
	insert into cr_linea
	(
	li_numero,
	li_num_banco,
	li_oficina,
	li_tramite,
	li_cliente,
	li_grupo,
	li_original,
	li_fecha_aprob,
	li_fecha_inicio,
	li_per_revision,
	li_fecha_vto,
	li_dias,
	li_condicion_especial,
	li_ult_rev,
	li_prox_rev,
	li_usuario_rev,
	li_monto,
	li_moneda,
	li_utilizado,		--II CMI 29Sept2006
	li_rotativa,
	li_estado,
	li_naturaleza)
	values
	(
	@o_numero,
	@w_li_num_banco, --*' ',
	@i_oficina,
	@i_tramite,
	@i_cliente,
	@i_grupo,
	@i_original,
	@i_fecha_inicio, --* null,
	@i_fecha_inicio,
	@i_per_revision,
	@i_fecha_vto,
	@i_dias,
	@i_condicion_especial,
	@i_fecha_inicio,
	@i_fecha_vto,--dateadd(dd,@w_factor,@i_fecha_inicio),
	@s_user,
	@i_monto,
	@i_moneda,
	@w_monto_utilizado_op,		--II CMI 29Sept2006
	@i_rotativa,
	@i_estado, --'V',
	@i_naturaleza) --*,
    
	if @@error <> 0
	begin
--print 'tra: %1! cli: %2! grupo: %3! orig: %4! linea: %5!', @i_tramite, @i_cliente, @i_grupo, @i_original, @o_numero
--print 'fecha ven: %1! dias: %2! monto: %3! moneda: %4! rot: %5!', @i_fecha_vto, @i_dias, @i_monto, @i_moneda, @i_rotativa
--print 'fecha ini: %1!', @i_fecha_inicio
         /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103001
             return 1 
	end

	/*** transaccion de servicio */
	--PQU quitar comentario porque se tiene que grabar la trx de servicio
	insert into ts_linea
	(
	secuencial,tipo_transaccion,clase,fecha,usuario,terminal,oficina,tabla,srv,lsrv,
      	numero,
      	num_banco,
      	ofic,
      	tramite,
      	cliente,
      	grupo,
      	original,
      	fecha_aprob,
      	fecha_inicio,
      	per_revision,
      	fecha_vto,
      	dias,
      	condicion_especial,
      	ultima_rev,
      	prox_rev,
      	usuario_rev,
	monto,
	moneda,
	utilizado,
	rotativa) 

	values
	(
	@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cr_linea',@s_srv,@s_lsrv,
      	@o_numero,  --PQU se cambia
      	' ',
      	@i_oficina,
      	@i_tramite,
      	@i_cliente,
      	@i_grupo,
      	@i_original,
      	null,
      	@i_fecha_inicio,
      	@i_per_revision,
      	@i_fecha_vto,
      	@i_dias,
      	@i_condicion_especial,
      	@i_fecha_inicio,
	dateadd(dd,@w_factor,@i_fecha_inicio),
	@s_user,
	@i_monto,
	@i_moneda,
	--null		IDCMI 29Sept2006
	@w_monto_utilizado_op,		--II CMI 29Sept2006
	@i_rotativa) 

	if @@error <> 0
	begin
	-- Error en insercion de transaccion de servicio
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1 	
	end


---  Creacion de Registro en cl_det_producto  

/*PQU esto no va, tiene que aprobarse para crearse el producto                                                                                                                                                                                                     
exec cobis..sp_cseqnos
@t_from      = @w_sp_name,
@i_tabla     = 'cl_det_producto',
@o_siguiente = @w_siguiente out

delete from cobis..cl_det_producto 
where  dp_cuenta   = @w_li_num_banco --@w_banco LPO DEMO PERU
and    dp_producto = 21

if @@error <> 0 
begin
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 710003
             return 1 
end
                                                                                                                                                                                                                                                           
select @w_filial = of_filial
from cobis..cl_oficina
where of_oficina = @i_oficina --@w_oficina 
                                                 
set transaction isolation level read uncommitted
                                                                                                                             
insert into cobis..cl_det_producto (
dp_det_producto, dp_oficina,       dp_producto,
dp_tipo,         dp_moneda,        dp_fecha, 
dp_comentario,   dp_monto,         dp_cuenta,
dp_estado_ser,   dp_autorizante,   dp_oficial_cta, 
dp_tiempo,       dp_valor_inicial, dp_tipo_producto,
dp_tprestamo,    dp_valor_promedio,dp_rol_cliente,
dp_filial,       dp_cliente_ec,    dp_direccion_ec)
                                                                                                                                                                                                           
values (
                                                                                                                                                                                                                                                      
@w_siguiente,    @i_oficina,         21, 
'R' ,            0,            @i_fecha_inicio, 
'LINEA DE CREDITO APROBADA',   @i_monto,       @w_li_num_banco,
'V',             3,            3,  --@w_num_oficial, @w_num_oficial,
@w_dias,         0,              '0',
0,               0,              'T',
@w_filial,       @i_cliente,     0) --@w_direccion)


	if @@error <> 0
	begin
         -- Error en insercion de registro 
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 710001
             return 1 
	end

*/


   commit tran
   select @o_numero
  /* Mapea al front end la linea */
   select li_num_banco
   from cr_linea
   where li_numero=@o_numero
   return 0 
end


--LPO DEMO PERU, DISTRIBUCION DE LA LINEA
 If @i_operacion = 'T'
begin
   /** obtener el registro actual **/
   if @w_existe = 0
   begin
	/* Registro a actualizar no existe */
	exec cobis..sp_cerror
       	@t_debug = @t_debug,
       	@t_file  = @t_file, 
       	@t_from  = @w_sp_name,
       	@i_num   = 2105002
       	return 1 
   end

   
--**************** LPO CONTROL PARA QUE NO SE SOBREPASE AL TOTAL DE LA LINEA
   
         
   BEGIN TRAN
   
   IF EXISTS (SELECT 1 FROM cr_lin_ope_moneda
              WHERE om_linea = @i_numero
                AND om_toperacion = @i_toperacion)
   BEGIN
      
      SELECT @w_montos_distribucion = 0
      
      SELECT @w_montos_distribucion = isnull (sum(om_monto),0)
      FROM cr_lin_ope_moneda
      WHERE om_linea = @i_numero
        AND om_toperacion <> @i_toperacion
      
      IF (@w_montos_distribucion + @i_monto) > @w_monto --
      BEGIN      
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2101035     --Monto distribuido excede el Total del Cupo
         return 1
      END      
             
      UPDATE cr_lin_ope_moneda
      SET om_monto    = @i_monto,
          om_tplazo   = @i_tplazo,
          om_plazos   = @i_plazos,
          om_rotativa = @i_rotativa
      WHERE om_linea  = @i_numero
        AND om_toperacion = @i_toperacion
        
      if @@error <> 0 
      begin
	     -- Error en insercion de registro
	     exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2103057
      end            
   END
   ELSE
   BEGIN  

      SELECT @w_montos_distribucion = 0
      
      SELECT @w_montos_distribucion = isnull (sum(om_monto),0)
      FROM cr_lin_ope_moneda
      WHERE om_linea = @i_numero
        --AND om_toperacion <> @i_toperacion
      
      IF (@w_montos_distribucion + @i_monto) > @w_monto --
      BEGIN      
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2101035     --Monto distribuido excede el Total del Cupo
         return 1
      END      
      
      --SELECT @i_toperacion = 'NEGOCIOS'
      SELECT @i_producto = 'CCA'
      --SELECT @i_tplazo  = 'M'
      --SELECT @i_plazos  = 12
      SELECT @i_condicion_especial = NULL
      SELECT @i_reservado = 0
      
      select	@w_numero = li_numero,
		@w_num_banco = li_num_banco,
		@w_oficina = li_oficina,
		@w_tramite = li_tramite,
		@w_cliente = li_cliente,
		@w_fecha_aprob = li_fecha_aprob,
		@w_fecha_inicio = li_fecha_inicio,
                @w_fecha_vto = li_fecha_vto, --* (case li_fecha_vto 					--TRugel 04/02/08
		@w_dias = li_dias,
		@w_monto  = li_monto,
		@w_moneda = li_moneda,
		@w_utilizado = isnull(li_utilizado,0),
		@w_rotativa = li_rotativa,
        @w_li_estado = CASE li_estado WHEN 'V' THEN 'VIGENTE' ELSE ' ' END
      --* @w_original = li_original,
      --* @w_per_revision = li_per_revision,
      --* @w_condicion = li_condicion_especial,
      --* @w_ultima_rev = li_ult_rev,
      --* @w_prox_rev = li_prox_rev,
      --* @w_usuario_rev = li_usuario_rev,
	  from	cr_linea
      where	li_numero = @i_numero --@o_numero --* li_numero = @i_numero
      
       
      insert into cr_lin_ope_moneda(
      om_linea,
	  om_toperacion,
      om_producto,
      om_moneda,
      om_monto,
      om_utilizado,
      om_tplazo,
      om_plazos,
      om_condicion_especial,
      om_reservado,
      om_moneda_ope,
      om_rotativa
      )
      
	  values (
	  @i_numero,
      @i_toperacion,
      @i_producto,
      @i_moneda,
      @i_monto, --Monto de cada una distribucion (de cada tipo de operacion)
      0, --@w_utilizado,
      @i_tplazo, 
      @i_plazos,
      @i_condicion_especial,
      @i_reservado,
      @i_moneda,
      @i_rotativa --Si es o No Rotativa cada distribucion
      )
   
      if @@error <> 0 
      begin
	     --Error en insercion de registro 
	     exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 2103001
         
	     return 1 
	  end
   END
   
   COMMIT TRAN
END




/** Update **/
/************/
/** ESTA TRANSACCION SE REALIZA UNICAMENTE ANTES DE LA APROBACION */
/*  DE LA LINEA DE CREDITO **/

 If @i_operacion = 'U'
begin
   --/ obtener el registro actual /
   if @w_existe = 0
   begin
	--/ Registro a actualizar no existe /
	exec cobis..sp_cerror
       	@t_debug = @t_debug,
       	@t_file  = @t_file, 
       	@t_from  = @w_sp_name,
       	@i_num   = 2105002
       	return 1 
   end

	--II CMI 29Sept2006
/*
	if @w_monto_utilizado_op > @i_monto
	begin
	    	--/ Monto de operaciones del cliente mayor al cupo de linea
		select @w_mensaje = 'Monto de operaciones del cliente mayor al cupo de linea:  ' + convert(varchar(20), @w_monto_utilizado_op)
	    	exec cobis..sp_cerror
	    	@t_debug = @t_debug,
	    	@t_file  = @t_file, 
	    	@t_from  = @w_sp_name,
		@i_msg	 = @w_mensaje,
	    	@i_num   = 2101069,
	        @i_sev   = 1		--TRugel 06/24/08	
	    	return 1 

	end

	--FI CMI 29Sept2006
*/

--print 'riesgo: %1! calif: %2! cliente: %3!', @w_riesgo, @w_calificacion, @i_cliente
--OJO revisar si esta opcion de update no se llama desde gestion, puesto que no debe actualizar el riesgo y la calificacion
   begin tran
	--/ actualizar el registro /
	update 	cr_linea
	set	
		li_oficina = @i_oficina,
		li_cliente = @i_cliente,
		li_grupo = @i_grupo,
		li_fecha_inicio = @i_fecha_inicio,
		li_per_revision = @i_per_revision,
		li_fecha_vto = @i_fecha_vto,
		li_dias = @i_dias,
		li_condicion_especial = @i_condicion_especial,
		li_ult_rev = @i_fecha_inicio,
		li_prox_rev = dateadd(dd, @w_factor, @i_fecha_inicio),
		li_usuario_rev = @s_user,
		li_monto = @i_monto,
		li_moneda = @i_moneda,
--      li_utilizado = @w_monto_utilizado_op,		--II CMI 29Sept2006
		li_rotativa = isnull(@i_rotativa, @w_rotativa)
	where 	li_numero = @i_numero
	if @@error <> 0 
         begin
         --/ Error en actualizacion de registro /
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
 @i_num   = 2105001
             return 1 
         end
	--/ transaccion de servicio registro actual /
	insert into ts_linea
	(
	secuencial,tipo_transaccion,clase,fecha,usuario,terminal,oficina,tabla,srv,lsrv,
      	numero,
      	num_banco,
      	ofic,
      	tramite,
      	cliente,
      	grupo,
      	original,
      	fecha_aprob,
      	fecha_inicio,
      	per_revision,
      	fecha_vto,
      	dias,
      	condicion_especial,
      	ultima_rev,
      	prox_rev,
      	usuario_rev,
	monto,
	moneda,
--  utilizado,
	rotativa)
	values
	(
	@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cr_linea',@s_srv,@s_lsrv,
      	@w_numero,
      	@w_num_banco,
      	@w_oficina,
      	@w_tramite,
      	@w_cliente,
      	@w_grupo,
      	@w_original,
      	@w_fecha_aprob,
      	@w_fecha_inicio,
      	@w_per_revision,
      	@w_fecha_vto,
      	@w_dias,
      	@w_condicion,
      	@w_ultima_rev,
	@w_prox_rev,
	@w_usuario_rev,
	@w_monto,
	@w_moneda,
	--@w_utilizado,			--ID CMI 29Sept2006
--    @w_monto_utilizado_op,		--II CMI 29Sept2006
	@w_rotativa) --*,

        if @@error <> 0 
        begin
         --/ Error en insercion de transaccion de servicio /
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1 
        end

	--/ transaccion de servicio registro aanterior /
	insert into ts_linea
	(
	secuencial,tipo_transaccion,clase,fecha,usuario,terminal,oficina,tabla,srv,lsrv,
      	numero,
      	num_banco,
      	ofic,
      	tramite,
      	cliente,
      	grupo,
      	original,
      	fecha_aprob,
      	fecha_inicio,
      	per_revision,
      	fecha_vto,
      	dias,
      	condicion_especial,
      	ultima_rev,
      	prox_rev,
      	usuario_rev,
	monto,
	moneda,
	utilizado,
	rotativa)

	values
	(
	@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cr_linea',@s_srv,@s_lsrv,
      	@w_numero,
      	@w_num_banco,
      	@i_oficina,
      	@w_tramite,
      	@i_cliente,
      	@i_grupo,
      	@i_original,
      	@w_fecha_aprob,
      	@i_fecha_inicio,
      	@i_per_revision,
      	@i_fecha_vto,
      	@i_dias,
      	@i_condicion_especial,
      	@i_fecha_inicio,
	dateadd(dd,@w_factor,@i_fecha_inicio),
	@s_user,
	@i_monto,
	@i_moneda,
	@w_utilizado,
	@i_rotativa)

        if @@error <> 0 
        begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1 
        end

   commit tran

        /* Mapea al front end la linea */
        select li_num_banco
        from cr_linea
        where li_numero=@i_numero

   return 0
end

/** Delete **/
/************/
/* Se puede eliminar una linea de credito, unicamente si no refleja utilizacion */

if @i_operacion = 'D'
begin
	if @w_existe = 0
	begin
		/* Registro a eliminar no existe */
	        exec cobis..sp_cerror
        	@t_debug = @t_debug,
        	@t_file  = @t_file, 
        	@t_from  = @w_sp_name,
        	@i_num   = 2107002
        	return 1 
	end

   /* Chequeo de utilizacion */
	If @w_utilizado > 0
	begin
         /* Linea con utilizacion */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2101038 --2107004
             return 2101038
	end

	begin tran
	/** eliminar **/
/*	delete 	cr_linea
	where 	li_numero = @i_numero
	if @@error <> 0 
         begin
         /* Error en eliminacion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
    @i_num   = 2107001
             return 1 
         end
*/

	/* eliminacion de cr_lin_ope_moneda */
	delete cr_lin_ope_moneda
	where om_linea = @i_numero
	if @@error <> 0 
         begin
         /* Error en eliminaci¢n de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2107001
             return 1 
         end

	/* transaccion de servicio registro eliminado **/
	insert into ts_linea
	(
	secuencial,tipo_transaccion,clase,fecha,usuario,terminal,oficina,tabla,srv,lsrv,
      	numero,
      	num_banco,
      	ofic,
      	tramite,
      	cliente,
      	grupo,
      	original,
      	fecha_aprob,
      	fecha_inicio,
      	per_revision,
      	fecha_vto,
      	dias,
      	condicion_especial,
      	ultima_rev,
      	prox_rev,
      	usuario_rev,
	monto,
	moneda,
	utilizado,
	rotativa	
	)
	values
	(
	@s_ssn,@t_trn,'D',@s_date,@s_user,@s_term,@s_ofi,'cr_linea',@s_srv,@s_lsrv,
      	@w_numero,
      	@w_num_banco,
      	@w_oficina,
      	@w_tramite,
      	@w_cliente,
      	@w_grupo,
      	@w_original,
      	@w_fecha_aprob,
      	@w_fecha_inicio,
      	@w_per_revision,
      	@w_fecha_vto,
      	@w_dias,
      	@w_condicion,
      	@w_ultima_rev,
	@w_prox_rev,
	@w_usuario_rev,
	@w_monto,
	@w_moneda,
	@w_utilizado,
	@w_rotativa
	)

        if @@error <> 0 
        begin
         /* Error en insercion de transaccion de servicio */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103003
             return 1 
        end

   commit tran
   return 0
end


/** Query **/
/***********/

If @i_operacion = 'Q'
begin
   /* verificar la existencia */
   if @w_existe = 0 
   begin
	/* Registro no existe */
	exec cobis..sp_cerror
       	@t_debug = @t_debug,
       	@t_file  = @t_file, 
       	@t_from  = @w_sp_name,
       	@i_num   = 2101005
       	return 1 
   end

	/* obtener datos que faltan */
	If @w_oficina <> null
                select @w_desc_oficina = substring(of_nombre,1,64)
		from	cobis..cl_oficina
		where	of_oficina = @w_oficina
	If @w_cliente <> null
		select 	@w_cli_nombre = rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre)
		from 	cobis..cl_ente
		where	en_ente = @w_cliente
	If @w_grupo <> null
                select  @w_gru_nombre = substring(gr_nombre,1,64)
		from	cobis..cl_grupo
		where	gr_grupo = @w_grupo
	If @w_usuario_rev <> null
                select  @w_nombre_rev = substring(fu_nombre,1,64)
		from	cobis..cl_funcionario
		where	fu_login = @w_usuario_rev
	If @w_per_revision <> null
		select @w_desc_per_revision = pe_descripcion
		from	cob_credito..cr_periodo
		where	pe_periodo = @w_per_revision
	If @w_moneda <> null
		select @w_desc_moneda = mo_descripcion
		from	cobis..cl_moneda
		where	mo_moneda = @w_moneda
        		

	/* desplegar los datos de la l¡nea */
	
	select	'Numero Interno' 	= @w_numero,
		'Numero de Linea' 	= @w_num_banco,
		'Oficina' 		= @w_oficina,
		'Nombre Oficina' 	= @w_desc_oficina,
		'Numero Tramite' 	= @w_tramite,
		'Cliente' 		= @w_cliente,
		'Nombre Cliente' 	= @w_cli_nombre,
		'Grupo' 		= @w_grupo,
		'Nombre Grupo' 		= @w_gru_nombre,
		'Linea Original' 	= @w_original,
		'Fecha Aprobacion' 	= @w_fecha_aprob,--convert(char(10),@w_fecha_aprob,103),
		'Fecha Inicio' 		= @w_fecha_inicio,--convert(char(10),@w_fecha_inicio,103),
		'Periodo Revision' 	= @w_per_revision,
		'Numero de Dias' 	= @w_dias,
		'Condiciones' 		= @w_condicion,
		'Ultima Revision' 	= convert(char(10),@w_ultima_rev,103),
		'Fecha Revision' 	= convert(char(10),@w_prox_rev,103),
		'Usuario Revision' 	= @w_usuario_rev,
		'Nombre Usuario' 	= @w_nombre_rev,
		'Fecha Vencimiento'	= @w_fecha_vto,--convert(char(10), @w_fecha_vto, 103),
		'Periodicidad'		= @w_desc_per_revision,
		'Monto'			= @w_monto,
		'Moneda'		= @w_moneda,
		'Desc. Moneda'		= @w_desc_moneda,
		'Utilizado'		= @w_utilizado,
		'Rotativa'		= @w_rotativa,
	        'Calificacion'		= @w_calif,		--II CMI 26Sept2006
                'Riesgo'		= @w_ries,		--II CMI 26Sept2006
		'Linea Anterior'	= @w_lin_anterior,	--LRE 08/Nov/2006
        'Naturaleza' = @w_li_naturaleza,
        'Sector'     = @w_sector

	return 0
end



/** fin **/



GO
