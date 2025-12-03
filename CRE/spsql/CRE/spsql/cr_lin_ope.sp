/************************************************************************/
/*  Archivo:                cr_lin_ope.sp                               */
/*  Stored procedure:       sp_lin_ope_moneda                           */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               COBIS                           			*/
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Proceso para la construccion de lineas de credito                   */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  04/05/21		  PQU		 	Integracion  ingreso solicitud      */
/*									credito	GFI                         */
/* **********************************************************************/

USE cob_credito
go

IF OBJECT_ID ('dbo.sp_lin_ope_moneda') IS NOT NULL
	DROP PROCEDURE dbo.sp_lin_ope_moneda
GO

CREATE PROCEDURE sp_lin_ope_moneda (
	@s_culture           varchar(10)  = 'NEUTRAL',
	@s_ssn 		int      = null,
	@s_user		login    = null,
	@s_sesn		int    = null,
	@s_term		descripcion = null,
	@s_date		datetime = null,
	@s_srv		varchar(30)  = null,
	@s_lsrv		varchar(30) = null,
	@s_rol		smallint = null,
	@s_ofi		smallint  = null,
	@s_org_err	char(1) = null,
	@s_error	int = null,
	@s_sev		tinyint = null,
	@s_msg		descripcion = null,
	@s_org		char(1) = null,
	@t_rty		char(1)  = null,
	@t_trn		smallint = null,
	@t_debug	char(1)  = 'N',
	@t_file		varchar(14) = null,
	@t_from		varchar(30) = null,
    @t_show_version       bit = 0, -- Mostrar la version del programa
	@i_operacion	char(1)  = null,
	@i_linea	int  = null,
	@i_num_banco	cuenta = null,
	@i_toperacion	catalogo  = null,
	@i_producto	catalogo  = null,
	@i_moneda       tinyint  = null,
	@i_monto        decimal(35,10) = null, --money  = null,
	@i_utilizado	decimal(35,10) = null, --money  = null,
	@i_tplazo       catalogo  = null,
	@i_plazos       smallint = null,
	@i_tramite      int = null,
	@i_condicion_especial varchar(255) = null,
    @i_bandera      char(1) = null 	,
    @i_prorroga     char(1) = null ,
    @i_tbase        varchar(10) = null, --Personalizaci¢n Banco Atlantic
    @i_dplazo       int = null,   --Personalizaci¢n Banco Atlantic
    @i_signo        char(1)     = null,   --Personalizaci¢n Banco Atlantic
    @i_valor        float = null,   --Personalizaci¢n Banco Atlantic,
    @i_modo         int = null,
    @i_porcentaje   float = null,
    @i_opcion       int = null,
    @i_linea_banco  cuenta = null,
	@i_proposito_op catalogo = null,		--Vivi,
	@i_tasa_minima  float    = null,
  	@i_pr_motivo    catalogo = null,
  	@i_monto_linea  money    = null

)
as
declare
@w_spid               smallint,  --OGU 01/08/2012
@w_today              datetime,     /* fecha del dia */
@w_return             int,          /* valor que retorna */
@w_sp_name            varchar(32),  /* nombre stored proc*/
@w_existe             tinyint,      /* existe el registro*/
@w_linea              int,
@w_toperacion         catalogo,
@w_desc_toperacion    descripcion,
@w_producto           catalogo,
@w_moneda             tinyint,
@w_desc_moneda	      descripcion,
@w_monto              decimal(35,10), --money,
@w_utilizado          decimal(35,10), --money,
@w_monto_total	      money,
@w_monto_distr	      money,
@w_tplazo             catalogo,
@w_plazos             smallint,
@w_condicion_especial varchar (255),
@w_desc_tplazo        descripcion,
@w_factor	      smallint,
@w_moneda_df	      tinyint,	-- moneda default
@w_monto_linea	      money,
@w_moneda_linea	      tinyint,
@w_montomn	      money,
@w_monto_ant	      money,
@w_fecha	      datetime,
@w_tbase	      varchar(10) , --Personalizaci¢n Banco Atlantic
@w_dplazo	      int,   --Personalizaci¢n Banco Atlantic
@w_signo	      char(1)  ,   --Personalizaci¢n Banco Atlantic
@w_valor              float,    --Personalizaci¢n Banco Atlantic
@w_porcentaje         float,
@w_facilidad          char(1),
@w_tramite            int,
@w_excsob             catalogo,
@w_proposito	      catalogo,		--Vivi
@w_tasa_calc          float,             --Vivi
@w_sector             catalogo,
@w_ind                int,
@w_factor_aux         int,
@w_tasa_minima        float,
@w_sobregiros         catalogo,
@w_tipo_t             char(1),   --I.4499 Libor CVA Sep-03-07
@w_numero             int,       --I.4499 Libor CVA Sep-03-07
@w_tipo               catalogo,   --I.4499 Libor CVA Sep-03-07
@w_sum_monto_dist     money,
@w_sum_monto_lin      money,
@w_por_utilizar       money,
@w_moneda_local		    tinyint,
@w_cotizacion            float,
@w_ocotizacion            float   ,
@w_ocot_usd               float  ,
@w_mensaje_error          varchar(255)

select @w_spid = @@spid	--OGU 01/08/2012
---- VERSIONAMIENTO DEL PROGRAMA ----
if @t_show_version = 1
begin
    print 'Stored procedure sp_lin_ope_moneda, Version 4.0.0.2'
    return 0
end
-------------------------------------

select @w_today = @s_date
select @w_sp_name = 'sp_lin_ope_moneda'
select @w_sobregiros = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SBR'
and pa_producto = 'CRE'

 select @i_linea = li_numero
      from cr_linea
      where li_tramite = @i_tramite


if @i_linea is null and @i_tramite is not null
   begin
      select @i_linea = li_numero
      from	cr_linea
      where li_tramite = @i_tramite

	end

/* Debug */
/*********/
if @t_debug = 'S'
begin
	exec cobis..sp_begin_debug @t_file = @t_file
	select '/** Stored Procedure **/ ' = @w_sp_name,
	s_ssn			  = @s_ssn,
	s_user			  = @s_user,
	s_sesn			  = @s_sesn,
	s_term			  = @s_term,
	s_date			  = @s_date,
	s_srv			  = @s_srv,
	s_lsrv			  = @s_lsrv,
	s_rol			  = @s_rol,
	s_ofi			  = @s_ofi,
	s_org_err		  = @s_org_err,
	s_error			  = @s_error,
	s_sev			  = @s_sev,
	s_msg			  = @s_msg,
	s_org			  = @s_org,
	t_trn			  = @t_trn,
	t_file			  = @t_file,
	t_from			  = @t_from,
	i_operacion		  = @i_operacion,
	i_linea			  = @i_linea,
	i_toperacion		  = @i_toperacion,
	i_producto		  = @i_producto,
	i_moneda		  = @i_moneda,
	i_monto			  = @i_monto,
	i_utilizado		  = @i_utilizado,
	i_tplazo 		  = @i_tplazo,
	i_plazos		  = @i_plazos,
	i_condicion_especial      = @i_condicion_especial
	exec cobis..sp_end_debug
end
/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn != 21023 and @i_operacion = 'I') or
(@t_trn != 21123 and (@i_operacion = 'U' or @i_operacion = 'A')) or
(@t_trn != 21223 and @i_operacion = 'D') or
(@t_trn != 21423 and @i_operacion = 'S') or
(@t_trn != 21623 and @i_operacion = 'T') or
(@t_trn != 21523 and @i_operacion = 'Q')
begin
/* tipo de transaccion no corresponde */
exec cobis..sp_cerror
@t_debug = @t_debug,
@t_file  = @t_file,
@t_from  = @w_sp_name,
@i_num   = 2101006
return 1
end

/* cupo total de la linea */ --MDA 05-ene-98
-- traer la moneda default
select @w_moneda_df = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'MLOCR'
and    pa_producto = 'CRE'
if @@rowcount = 0
begin
  /*Registro no existe */
  exec cobis..sp_cerror
  @t_debug = @t_debug,
  @t_file  = @t_file,
  @t_from  = @w_sp_name,
  @i_num   = 2101005
  return 1
end

--INI SNU: Validacion de ingreso
if @w_sobregiros = @i_toperacion and @i_producto != 'CTE'
begin
   /*Registro no existe */
   exec cobis..sp_cerror
        @t_debug  =  @t_debug,
        @t_file   =  @t_file,
        @t_from   =  @w_sp_name,
        @i_num    =  2110336
   return 2110336
end
--FIN SNU

-- mdi controlar que el plazo en dias no supere el limite de smallint ya que en tramites el campo es smallint y presenta aritmetic overflow
-- plazo en dias aprox 89 a¤os
if @i_dplazo > 32767
begin
   /*Registro no existe */
   exec cobis..sp_cerror
        @t_debug  =  @t_debug,
        @t_file   =  @t_file,
        @t_from   =  @w_sp_name,
        @i_num    =  2110337
   return 2110337
end



--VERIFICAR SI EXISTE LINEA DE CREDITO OP. DE CARTERA (llamada desde fdesembolso)
if @i_operacion = 'T' and @i_opcion =  1 and @i_producto = 'CCA'
begin
   select @i_linea_banco = op_lin_credito,
          @i_tramite     = op_tramite
     from cob_cartera..ca_operacion
    where op_banco = @i_num_banco

   if @i_linea_banco is null
      return 0
end


/* Chequeo de Existencias */
/**************************/

if @i_operacion != 'S'
begin
	select
	@w_linea = om_linea,
	@w_toperacion = om_toperacion,
	@w_desc_toperacion = to_descripcion,
	@w_producto = om_producto,
	@w_moneda = om_moneda,
	@w_desc_moneda = mo_descripcion,
	@w_monto = om_monto,
	@w_utilizado = om_utilizado,
	@w_tplazo = om_tplazo,
	@w_desc_tplazo = pe_descripcion,
	@w_plazos = om_plazos,
	@w_condicion_especial = om_condicion_especial
	from cob_credito..cr_lin_ope_moneda
	     INNER JOIN cr_toperacion ON (om_toperacion = to_toperacion)
             LEFT OUTER JOIN cr_periodo ON (om_tplazo = pe_periodo)
	     INNER JOIN cobis..cl_moneda ON (om_moneda = mo_moneda)
	where om_linea = @i_linea and
	      om_toperacion  = @i_toperacion and
	      om_producto    = @i_producto   and
	      om_moneda      = @i_moneda 

	if @@rowcount > 0
		select @w_existe = 1
	else
		select @w_existe = 0
--Conseguir lo utilizado realmente
	if @w_existe = 1 and @i_linea < 0
	    select @w_utilizado = om_utilizado
   	      from cob_credito..cr_lin_ope_moneda
	     where om_linea = (-1 * @i_linea) and
	           om_toperacion = @i_toperacion and
	           om_producto   = @i_producto and
	           om_moneda     = @i_moneda
--verificar utilizado de tramites en proceso de aprobacion
    if @i_linea < 0
    begin
        select @w_por_utilizar = tr_monto
        from cob_credito..cr_lin_ope_moneda, cob_credito..cr_tramite
        where om_linea     = tr_linea_credito
        and om_toperacion = tr_toperacion
        and om_moneda = tr_moneda
        and om_producto = tr_producto
        and om_linea = (-1 * @i_linea)
    end

end
if @i_valor = 0
   select @i_valor = null



/* VALIDACION DE CAMPOS NULOS           */
--VALIDACION DE CUPO TOTAL DE LA LINEA
--VALIDACION DEL PRODUCTO MONEDA
--VALIDACION POR MONTO UTILIZADO
/****************************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
	if @i_linea   is NULL or
	   @i_toperacion   is NULL or
	   @i_producto     is NULL or
	   @i_moneda       is NULL
	begin
	  /* Campos NOT NULL con valores nulos */
	  exec cobis..sp_cerror
	  @t_debug = @t_debug,
	  @t_file  = @t_file,
	  @t_from  = @w_sp_name,
	  @i_num   = 2101001
	  return  1
	end

	select @i_linea = li_numero
      from cr_linea
      where li_tramite = @i_tramite

    -- traer el monto y moneda de la linea
    if @i_linea > 0
     select @w_monto_linea = li_monto,
            @w_moneda_linea = li_moneda
     from   cr_linea
     where  li_numero = @i_linea
    /*PQU integracion
    else
     select @w_monto_linea = pr_monto,
            @w_moneda_linea = pr_moneda
     from   cr_prorroga
     where  pr_tramite = @i_tramite*/

   /* toperacion vs moneda */
   if @i_producto = 'CCA'
   begin
	if not exists (select * from cob_cartera..ca_default_toperacion
			where dt_toperacion = @i_toperacion
			and   dt_moneda = @i_moneda)
	begin
	   /* No existe el tipo de operacion con la moneda indicada */
	   exec cobis..sp_cerror
	   @t_debug = @t_debug,
	   @t_file  = @t_file,
	   @t_from  = @w_sp_name,
	   @i_num   = 2101034
	   return 1
	end
   end


--I.4499 Libor CVA Sep-03-07
   	if @i_tramite != 0
   	BEGIN
		-- Permite obtener el sector y tipo de tramite
	       	select @w_sector = tr_sector, @w_tipo_t = tr_tipo
		from cr_tramite where tr_tramite = @i_tramite

                select @w_tipo = @i_toperacion

    		if @w_tipo_t in ('O','R','F','E','L','P')
   		begin
        		if @w_tipo_t  in ('O','R','F','E')
        		begin
            		    -- Obtener el tipo de operacion prendaria
		            select @w_tipo = dt_toperacion
		            from   cob_cartera..ca_default_toperacion, cob_credito..cr_corresp_sib
		            where  dt_toperacion = @w_tipo
		            and    tabla         = 'T106'
		            --PQU integración and    codigo        = dt_familia
		            and    @i_producto   = 'CCA'
		            if @@rowcount != 0
		            begin

               			-- Valida permite o no reajuste
   	     			if exists( select 1 from cob_cartera..ca_valor, cob_cartera..ca_valor_det
   	            				where va_tipo          = @i_tbase
   	            				and   vd_tipo          = va_tipo
						and   vd_sector        = @w_sector
						--PQU integración and   vd_aplica_ajuste = 'S' 
						)
				begin
				       exec cobis..sp_cerror
	   					@t_debug = @t_debug,
	   					@t_file  = @t_file,
	   					@t_from  = @w_sp_name,
	   					@i_num   = 2110338
	   			       return 2110338
				end
            		    end
        		end

       			if @w_tipo_t  in ('L','P')
       			begin
			     if @w_tipo_t  = 'L'
	     		     	select @w_tipo  = li_tipo  from cr_linea   where li_tramite = @i_tramite
                             else
			     begin
				 select @w_numero = tr_linea_credito from cr_tramite where tr_tramite = @i_tramite
	     		         select @w_tipo  = li_tipo  from cr_linea   where li_numero = @w_numero
			     end
		             -- Obtener el tipo de operacion prendaria
             			select @w_tipo = codigo
             			from cob_credito..cr_corresp_sib
             			where tabla  = 'T110'
             			and   codigo = @w_tipo
             			if @@rowcount != 0
             			begin
   	     			     -- Valida permite o no reajuste
   	     			    if exists( select 1 from cob_cartera..ca_valor, cob_cartera..ca_valor_det
   	            				where va_tipo          = @i_tbase
   	            				and   vd_tipo          = va_tipo
						and   vd_sector        = @w_sector
						--PQU integración and   vd_aplica_ajuste = 'S' 
						)
				    begin
				       exec cobis..sp_cerror
	   					@t_debug = @t_debug,
	   					@t_file  = @t_file,
	   					@t_from  = @w_sp_name,
	   					@i_num   = 2110338
	   			      return 2110338
				    end
           			end
       			end  --if @i_tipo_t  in ('L','P')
        	end--if @w_tipo_t in ('O','R','F','E','L','P')
	END--  if @i_tramite != 0
	--F.4499 Libor CVA Sep-03-07


/* Obtengo la fecha de proces */
select @w_fecha = fp_fecha
from cobis..ba_fecha_proceso
/* Lleno una tabla temporal con la cotizacion de las monedas */
   insert into cr_cotiz3_tmp
   (spid, moneda, cotizacion)
   select distinct
   @w_spid, a.ct_moneda, a.ct_valor
   from   cr_lin_ope_moneda,cb_cotizaciones a
   where (ct_moneda = om_moneda or ct_moneda = @i_moneda or ct_moneda = @w_moneda_linea)
   and ct_fecha = (select max(b.ct_fecha)
	  	    from cb_cotizaciones b
			    where
			        b.ct_moneda = a.ct_moneda
			    and b.ct_fecha <= @w_fecha)

   -- insertar un registro para la moneda local
   if not exists (select 1 from cr_cotiz3_tmp
	       where moneda = @w_moneda_df)
   insert into cr_cotiz3_tmp (spid,moneda, cotizacion)
   values (@w_spid, @w_moneda_df, 1)

   select @w_montomn = sum(isnull(om_monto * cotizacion,0))
   from cr_lin_ope_moneda, cr_cotiz3_tmp
   where om_linea = @i_linea
   and moneda = om_moneda
   and spid = @w_spid

   select @w_montomn = isnull(@w_montomn, 0)

   /*LGU INI SPRINT 16 BUG 23083*/
   select @w_monto_linea = isnull(@i_monto_linea, @w_monto_linea)
   /*LGU FIN SPRINT 16 BUG 23083*/

   if @w_moneda_linea != @w_moneda_df
      select @w_monto_linea = @w_monto_linea * cotizacion
      from   cr_cotiz3_tmp
      where  moneda = @w_moneda_linea
      and spid = @w_spid

   select @w_monto = isnull(@w_monto, 0)

   if @w_monto > 0
      select @w_monto_ant = @w_monto * cotizacion
      from cr_cotiz3_tmp
      where moneda = @i_moneda
      and spid = @w_spid
   else select @w_monto_ant = 0

   -- poner el monto del producto en moneda local
   if @i_moneda != @w_moneda_df
      select @w_monto_distr = @i_monto * cotizacion
      from   cr_cotiz3_tmp
      where  moneda = @i_moneda
      and spid = @w_spid
   else
      select @w_monto_distr = @i_monto

--   REQ : Cre_007 : No controlar que la suma de las facilidades superen
--   el monto de la linea, controlar que el monto de la facilidad no supere
--   el monto de la linea
--   select @w_monto_distr = @w_monto_distr + @w_montomn  - @w_monto_ant
   -- hacer la comparaccion

   if @w_monto_linea < @w_monto_distr
   begin
      -- Monto distribuido excede elcupo total de la Linea
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101035
      return 1
   end
   -- validacion de que una modificacion del monto distribuido no sea menor
   -- al monto utilizado

   if @i_operacion = 'U' and @w_existe = 1
   begin
      select @w_monto = isnull(@w_monto, 0)
      select @w_utilizado = isnull(@w_utilizado, 0)
      select @i_monto = isnull(@i_monto, 0)
      if (@i_monto != @w_monto) and  (@i_monto < @w_utilizado) and
         (@i_toperacion != @w_sobregiros or  ( @i_toperacion = @w_sobregiros and (@i_pr_motivo not in ('DISM', 'REDI','AUMT','REAU') ) ) )
      begin
         -- Monto distribuido menor que el monto utilizado
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2101036
         return 1
      end

	-- EVALUACION CON DISTRIBUCION DE LA LINEA

	if @i_monto > @w_monto_linea
	begin
	   -- ERROR: Existen distribuciones que superan
	   -- el monto total de la L¡nea de Crédito
           exec cobis..sp_cerror
             	@t_debug = @t_debug,
             	@t_file  = @t_file,
             	@t_from  = @w_sp_name,
             	@i_num   = 2110339
	   return 2110339
	end

   end
end
/* Insercion del registro */
/**************************/
if @i_operacion = 'I'
begin
   if @w_existe = 1
   begin
      /* Registro ya existe */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101002
      return 1
   end
   select @i_utilizado = isnull(@i_utilizado,0)

	select @w_tipo_t = tr_tipo from cr_tramite  where tr_tramite = @i_tramite
	if @w_tipo_t ='P'
		select @i_linea = li_numero * -1
		from cr_linea
		where li_tramite = @i_tramite
	  else
		select @i_linea = li_numero
		from cr_linea
		where li_tramite = @i_tramite

   begin tran
      insert into cr_lin_ope_moneda(
	om_linea,	om_toperacion,	om_producto,	om_moneda,
	om_monto,	om_utilizado,	om_tplazo,	om_plazos,
	om_condicion_especial--,
	--PQU integración  om_tbase,	om_dplazo,	om_signo,	om_valor,
      --PQU integración   om_porcentaje,	om_proposito_op, om_tasa_minima 
         )	--Vivi
      values (
	@i_linea,	@i_toperacion,	@i_producto,	@i_moneda,
	@i_monto,	@i_utilizado,	@i_tplazo, 	@i_plazos,
	@i_condicion_especial--,
	--PQU integración @i_tbase,	@i_dplazo,	@i_signo,	@i_valor,
    --PQU integración     @i_porcentaje,	@i_proposito_op, @i_tasa_minima
    )	--Vivi
	if @@error != 0
	begin
	   /* Error en insercion de registro */
	   exec cobis..sp_cerror
	   @t_debug = @t_debug,
	   @t_file  = @t_file,
	   @t_from  = @w_sp_name,
	   @i_num   = 2103001
	   return 1
	end
	/* Transaccion de Servicio */
	/***************************/
	insert into ts_lin_ope_moneda
	values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cr_lin_ope_moneda',
		@s_lsrv,@s_srv,@i_linea,@i_toperacion,@i_producto, @i_moneda,
		@i_monto,@i_utilizado,@i_tplazo,@i_plazos,NULL,null ) --PQU integración se añade los nulls
	if @@error != 0
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
end
/* Actualizacion del registro */
/******************************/
if @i_operacion = 'U'
begin
   if @w_existe = 0
   begin
      exec cobis..sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 2101005
      /* No existe linea  */
      return 1
   end
   else
   begin
	select @w_tipo_t = tr_tipo from cr_tramite  where tr_tramite = @i_tramite
	if @w_tipo_t ='P'
	begin
		select @i_linea = li_numero * -1
		from cr_linea
		where li_tramite = @i_tramite
	end
	else
	begin
		select @i_linea = li_numero
		from cr_linea
		where li_tramite = @i_tramite
	 end
      begin tran
         update cob_credito..cr_lin_ope_moneda
            set
            om_monto      = @i_monto,
            om_condicion_especial = @i_condicion_especial,
            om_tplazo      = @i_tplazo,
            om_plazos      = @i_plazos
        where om_linea       = @i_linea and
              om_toperacion  = @i_toperacion and
              om_producto    = @i_producto   and
              om_moneda      = @i_moneda

      if @@error != 0
      begin
         /* Error en actualizacion de registro */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2105001
         return 1
      end
      /* Transaccion de Servicio */
      /***************************/
      insert into ts_lin_ope_moneda
      values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cr_lin_ope_moneda',@s_lsrv,@s_srv,
              @w_linea, @w_toperacion,@w_producto,@w_moneda, @w_monto,@w_utilizado,@i_tplazo,@i_plazos,NULL,NULL ) --PQU integración  se añade nulls
      if @@error != 0
      begin
         /* Error en insercion de transaccion de servicio */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2103003
         return 1
      end
      /* Transaccion de Servicio */
      /***************************/
      insert into ts_lin_ope_moneda
         values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cr_lin_ope_moneda',@s_lsrv,@s_srv,
                  @i_linea, @i_toperacion,@i_producto, @i_moneda,@i_monto, @i_utilizado,@i_tplazo,@i_plazos, NULL,null) --PQU integración se añade nulls
      if @@error != 0
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
   end
end
/* Eliminacion de registros */
/****************************/
if @i_operacion = 'D'
begin
   /* no se esta chequeando existencia pues en este caso
      desde el front-end se puede disparar la eliminacion
      de un registro que no existe y eso no es un error */

   --if @w_existe = 1
  -- begin

		select @w_tipo_t = tr_tipo from cr_tramite  where tr_tramite = @i_tramite
		if @w_tipo_t ='P'
		begin
			select @i_linea = li_numero * -1
			from cr_linea
			where li_tramite = @i_tramite
		end
		else
		begin
			select @i_linea = li_numero
			from cr_linea
			where li_tramite = @i_tramite
		end

       if @w_utilizado > 0
         begin
            /* No se puede eliminar por que hay monto utilizado*/
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2101038
            return 1
         end
        if  @w_por_utilizar > 0
         begin
            /* No se puede eliminar por que hay monto utilizado*/
            exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2101038
            return 1
         end
   --end
   begin tran
      delete cob_credito..cr_lin_ope_moneda
      where  om_linea       = @i_linea      and
             om_toperacion  = @i_toperacion and
             om_producto    = @i_producto   and
             om_moneda      = @i_moneda
      if @@error != 0
      begin
         /*Error en eliminacion de registro */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2107001
         return 1
      end
      /* Transaccion de Servicio */
      /***************************/
      insert into ts_lin_ope_moneda
      values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cr_lin_ope_moneda',@s_lsrv,@s_srv,
              @w_linea, @w_toperacion,@w_producto, @w_moneda,@w_monto,@w_utilizado,@i_tplazo,@i_plazos, NULL,NULL) --se añade nulls
      if @@error != 0
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
end
/**** Search ****/
/****************/
if @i_operacion = 'S'
begin

   select @w_tipo_t = tr_tipo from cr_tramite  where tr_tramite = @i_tramite
    /*PQU integracion
    if @w_tipo_t = 'P'
		select @w_fecha = pr_fecha_inicio
		from cob_credito..cr_prorroga
		where pr_tramite = @i_tramite
	else*/
		/* Obtengo la fecha de inicio de la línea */
		select @w_fecha = li_fecha_inicio
		from cob_credito..cr_linea
		where li_numero = @i_linea

   /* Lleno una tabla temporal con la cotizacion de las monedas */
   if exists (select 1 from cr_cotiz3_tmp where spid = @w_spid)
		delete cr_cotiz3_tmp where spid = @w_spid

   /* Lleno una tabla temporal con la cotizacion de las monedas */
   insert into cr_cotiz3_tmp
   (spid, moneda, cotizacion)
    select  @w_spid, a.ct_moneda, a.ct_valor
    from cob_conta..cb_cotizacion a
    INNER JOIN cr_lin_ope_moneda 
    ON (a.ct_moneda = om_moneda)
    INNER JOIN ( select ct_empresa, ct_moneda, max(ct_fecha) as ct_fecha
                 from cob_conta..cb_cotizacion
                 where ct_empresa = 1
                 and ct_fecha <= @w_fecha
                 group by ct_empresa,ct_moneda  
               ) b
    ON (a.ct_empresa = b.ct_empresa 
        and a.ct_moneda = b.ct_moneda 
        and a.ct_fecha = b.ct_fecha)


   -- insertar un registro para la moneda local
   if not exists (select 1 from cr_cotiz3_tmp
	       where moneda = @w_moneda_df and spid = @w_spid )
   insert into cr_cotiz3_tmp (spid,moneda, cotizacion)
   values (@w_spid, @w_moneda_df, 1)


   --
select @w_moneda_local = pa_tinyint
	from cobis..cl_parametro
	where pa_producto = 'ADM'
	and pa_nemonico = 'MLO'

	if exists(select 1 FROM  cr_lin_ope_moneda, cr_toperacion, cr_cotiz3_tmp
      WHERE ( om_linea = @i_linea) and
            ( om_toperacion = to_toperacion) and
            om_moneda = moneda
            and spid = @w_spid)
	BEGIN
	  select distinct @w_moneda = om_moneda  FROM  cr_lin_ope_moneda, cr_toperacion, cr_cotiz3_tmp
      WHERE ( om_linea = @i_linea) and
            ( om_toperacion = to_toperacion) and
            om_moneda = moneda
            and spid = @w_spid

		if (@w_moneda = @w_moneda_local)
		BEGIN
			select @w_cotizacion = 1
		END 
	END
	ELSE
	BEGIN
		select @w_cotizacion = 1
	END
   --IOR si regresa y cambia monto controlar que cada distribucion no exceda el total aprobado
   	select @w_tipo_t = tr_tipo from cr_tramite  where tr_tramite = @i_tramite
    if @w_tipo_t = 'L'
    begin
        select @w_sum_monto_lin = isnull(li_monto * cotizacion,0)
        from cr_linea, cr_cotiz3_tmp
        where li_numero = @i_linea
        and moneda = li_moneda
        and spid = @w_spid

    end
    /*PQU integracion
    else --prorroga
    begin
        select @w_sum_monto_lin = isnull(pr_monto * cotizacion,0)
        from cr_prorroga, cr_cotiz3_tmp
        where pr_tramite = @i_tramite
        and moneda = pr_moneda
        and spid = @w_spid
    end
    */

   select @i_toperacion = isnull(@i_toperacion , ' ')
   select @i_producto = isnull(@i_producto , ' ')
   if @i_bandera = 'S'
   begin
      select @i_linea = li_numero
      from cr_linea
      where li_tramite = @i_tramite
   end

   if @i_num_banco is not null
   begin
      select @i_linea = li_numero
      from cr_linea
      where li_num_banco = @i_num_banco
   end

   --Personalizcion banco Atlantic
   -- Obtiene la condici¢n especial de una l¡nea
   if @i_modo = 1
   begin
      select @w_condicion_especial = om_condicion_especial
      from cr_lin_ope_moneda
      where om_linea = @i_linea
      and om_toperacion = @i_toperacion

      select @w_condicion_especial
      return 0
   end

/** OBTIENE SECTOR DEL TRAMITE **/
   select @w_sector = tr_sector
     from cr_tramite
    where tr_tramite = @i_tramite

      /** OBTIENE SECTOR DEL TRAMITE **/
      if @w_sector is null
        select @w_sector = tr_sector
          from cr_tramite, cr_linea
         where tr_tramite = li_tramite
           and li_numero  = abs(@i_linea)

/* PQU integración 
   set rowcount 1

   -- OBTIENE PRIMER REGISTRO 
  
   select @w_ind = id
     from sublimite_tmp  --OCU#
    where id >= 0
      and tasa_base is not null
      and spid = @w_spid --OCU#
   order by id

   While @w_ind > 0
   begin
        -- OBTIENE DATOS DEL SUBLIMITE  
        select @w_toperacion = toperacion,
               @w_producto   = producto,
	       @w_tbase      = tasa_base,
               @w_porcentaje = tasa_fija,
               @w_valor      = spread,
               @w_factor_aux = factor,
               @w_moneda     = moneda
          from sublimite_tmp --OCU#
         where id   = @w_ind
         and   spid = @w_spid --OCU#

        select @w_tasa_calc = 0.0

        --OBTIENE EL VALOR DE LA TASA BASE 
        exec @w_return = cob_cartera..sp_valor
             @i_operacion   = 'H',
             @i_tipoh       = 'B',
             @i_tipo        = @w_tbase,
             @i_sector      = @w_sector,
             @i_credito     = 'S',
             @o_tasa        = @w_tasa_calc out

        if @w_return != 0
           select @w_tasa_calc = 0

        -- ACTUALIZA TASA TOTAL 
        if @w_porcentaje = 0 or @w_porcentaje is null
        begin
            update sublimite_tmp --OCU#
               set tasa_total = isnull( @w_tasa_calc , 0) + ( @w_valor * @w_factor_aux)
             where id   = @w_ind
             and   spid = @w_spid --OCU#
        end

        -- OBTIENE SIGUIENTE REGISTRO 
        select @w_ind = id
          from sublimite_tmp --OCU#
         where id > @w_ind
           and tasa_base is not null
           and spid  = @w_spid --OCU#
         order by id

        if @@rowcount = 0
           select @w_ind = 0
   end
   

   set rowcount 0
   
   */--fin PQU

   /** DEVUELDE DATOS AL FRONT-END **/
      SELECT DISTINCT
            'Operacion' = om_toperacion,
            'Producto' = om_producto,
            'Moneda' =om_moneda,
            'Monto' = om_monto,
            'Utilizado' = isnull(om_utilizado,0),
            'Condicion Especial' = om_condicion_especial,
            'Desc_Operacion' = to_descripcion,
            'Desc_Moneda' = mo_descripcion,
            'Desc_Producto'  = pd_descripcion,
            'Riesgo' = pl_riesgo,
            'Desc_Riesgo' = cobis..cl_catalogo.valor
      FROM  cob_credito..cr_lin_ope_moneda,            
            cobis..cl_moneda,
            cob_credito..cr_toperacion,
            cobis..cl_producto,
            cobis..cl_tabla,
            cobis..cl_catalogo,
            cob_credito..cr_productos_linea
      WHERE ( om_linea =  @i_linea) and
            ( om_toperacion = to_toperacion) and     
           (mo_moneda      = om_moneda) and         
           (pd_abreviatura = om_producto ) AND
           cobis..cl_tabla.tabla='fp_riesgos_licre' AND
           cobis..cl_tabla.codigo=cobis..cl_catalogo.tabla AND 
           cob_credito..cr_productos_linea.pl_producto=cob_credito..cr_toperacion.to_toperacion and
           cobis..cl_catalogo.codigo = cob_credito..cr_productos_linea.pl_riesgo

       --delete cr_cotiz3_tmp where spid = @w_spid
end

/* Consulta opcion QUERY */
/*************************/
if @i_operacion = 'Q'
begin
   if @w_existe = 1
   begin
      select @w_factor = pe_factor
      from cr_periodo
      where pe_periodo =  @w_tplazo
      select @w_linea,
             @w_toperacion,
             @w_desc_toperacion,
             @w_producto,
             @w_moneda,
             @w_desc_moneda,
             @w_monto,
             @w_utilizado,
             @w_tplazo,
             @w_desc_tplazo,
             @w_plazos,
             @w_condicion_especial,
             @w_factor ,
	     @w_tbase,--14
	     @w_dplazo,
	     @w_signo,
	     @w_valor,
             @w_porcentaje,
	     @w_proposito,	--Vivi
	     @w_tasa_minima

   end
else
   begin
      return 0
   end
end

/* ACTUALIZACION DEL UTILIZADO DE LOS SUBLIMITES */
/*************************************************/
if @i_operacion = 'A'
begin
   if exists ( select 1
  	        from cob_credito..cr_lin_ope_moneda
   	       where om_linea = @i_linea )
   begin
        insert into xx_tmp --OCU#
		select @w_spid, --OCU#
		       toperacion     = om_toperacion,
         	       producto	      = om_producto,
                       --PQU integración proposito_op   = om_proposito_op,
                       moneda         = om_moneda,
                       utilizado      =	om_utilizado
        --into #xx --OCU#
        from cr_lin_ope_moneda
       where om_linea = abs(@i_linea)

      update cr_lin_ope_moneda
         set om_utilizado = utilizado
        from xx_tmp --OCU#
       where om_linea        = @i_linea
         and om_toperacion   = toperacion
         and om_producto     = producto
         --and om_proposito_op = proposito_op
         and om_moneda       = moneda
         and spid            = @w_spid --OCU#

    if @@error != 0
      begin
         /* Error en actualizacion de registro */
         exec cobis..sp_cerror
              @t_debug  =  @t_debug,
              @t_file   =  @t_file,
              @t_from   =  @w_sp_name,
              @i_num    =  2105001
         return 1
      end

     /*PQU integracion
      update cr_prorroga
         set pr_utilizado = li_utilizado
        from cr_linea
       where pr_tramite = @i_tramite
         and pr_numero  = li_numero

    if @@error != 0
      begin
         -- Error en actualizacion de registro 
         exec cobis..sp_cerror
              @t_debug  =  @t_debug,
              @t_file   =  @t_file,
              @t_from   =  @w_sp_name,
              @i_num    =  2105001
         return 1
      END
      */

   end
   else
   begin
         /*Registro no existe */
         exec cobis..sp_cerror
              @t_debug  =  @t_debug,
              @t_file   =  @t_file,
              @t_from   =  @w_sp_name,
              @i_num    =  2101005
         return 1
   end

end

/* Consulta opcion SEARCH de Facilidades */
/*****************************************/
if @i_operacion = 'T'
begin
   if @i_opcion = 0
   begin
       SELECT @w_producto = to_producto FROM cr_toperacion
       WHERE to_toperacion = @i_toperacion

       SELECT --PQU integración om_proposito_op, 
           cat.valor
         FROM cr_lin_ope_moneda, cobis..cl_tabla tab,
              cobis..cl_catalogo cat, cr_linea
         WHERE om_linea = li_numero
         and li_num_banco = @i_num_banco
         and om_moneda = @i_moneda
         and om_producto = @w_producto
         and om_toperacion = @i_toperacion
         and tab.tabla = 'cr_proposito_linea'
         and tab.codigo = cat.tabla
         --PQU integración and cat.codigo = om_proposito_op
   end
   if @i_opcion = 1
   begin
      select @w_tramite    = tr_tramite,
             @w_toperacion = tr_toperacion
      from   cr_tramite
      where  tr_numero_op_banco = @i_num_banco

      select @w_monto     = om_monto,
             @w_utilizado = om_utilizado
      from   cr_lin_ope_moneda, cr_linea
      where  om_linea      = li_numero
      and    om_toperacion = @w_toperacion
      and    om_producto   = @i_producto
      and    li_num_banco  = @i_linea_banco

     -- print 'Linea: %1! Monto: %2! utilizado: %3!  @i_monto: %4!', @i_linea_banco,
     --        @w_monto, @w_utilizado, @i_monto

      if @i_monto > isnull(@w_monto,0) - isnull(@w_utilizado,0)
         begin
           return -1   -- Demasiado grande 2107012
         end
      return 0
   end
   else
   begin
      if @i_modo = 1
      begin
         select @w_existe = count(om_linea)
         from cr_lin_ope_moneda, cr_linea
         where om_linea = li_numero
         and li_num_banco = @i_num_banco
         and om_toperacion = @i_toperacion
         --and om_producto = @i_producto
         and om_moneda = @i_moneda


         if @w_existe >= 1
            select @w_facilidad = 'S'
         else
            select @w_facilidad = 'N'

         select @w_facilidad

      end
      else
      begin
         SELECT distinct
	       'Moneda' = om_moneda,
	       'Monto       ' = sum(om_monto),
               'Utilizado   ' =sum(om_utilizado)
         FROM cr_lin_ope_moneda
         WHERE ( om_linea = @i_linea)
         GROUP BY om_moneda
      end
   end
end
--delete cr_cotiz3_tmp where spid = @w_spid

--OCU#
delete xx_tmp        where spid = @w_spid
--PQU integracion delete sublimite_tmp where spid = @w_spid

return 0

GO

