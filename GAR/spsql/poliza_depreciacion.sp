/*************************************************************************/
/*   Archivo:              poliza_depreciacion.sp                        */
/*   Stored procedure:     sp_poliza_depreciacion                        */
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
IF OBJECT_ID('dbo.sp_poliza_depreciacion') IS NOT NULL
    DROP PROCEDURE dbo.sp_poliza_depreciacion
go
create procedure sp_poliza_depreciacion
	(
	@s_ssn                int      = null,
	@s_date               datetime = null,
	@s_user               login    = null,
--	@s_term               varchar(64) = null, --Miguel Aldaz 26/Feb/2015
    @s_term 			  varchar(30) = null, --Miguel Aldaz 26/Feb/2015
	@s_ofi                smallint  = null,
	@t_rty                char(1)  = null,
   	@t_trn                smallint = null,
   	@t_debug              char(1)  = 'N',
   	@t_file               varchar(14) = null,
   	@t_from               varchar(30) = null,
   	@i_operacion          char(1)  = null,
   	@i_modo               smallint = null,
	@i_custodia	      int = null,
	@i_codigo_externo     varchar(64) = null,
	@i_tipo		      varchar(10) = null,
	@i_sucursal           smallint  = null,
	@i_filial             tinyint  = null,
	@i_monto_endozo       money  = null,
	@i_fecha_endozo       datetime  = null,
	@i_fendozo_fin        datetime  = null,
	@i_secuencial_pag     int 	  = null,
	@i_banco	      char(20) 	  = null,
	@o_poliza	      varchar(20) = null output,
	@o_poliza_ant	      varchar(20) = null output,
	@o_aseguradora	      varchar(20) = null output,
	@o_deprecia	      char(01) 	  = null output,
	@o_monto_poliza	      money	  = null output,
	@o_msg		      varchar(255) = null output	--Fandrade 25/06/2009
	)
as


declare @w_poliza		varchar(20),
	@w_poliza_ant		varchar(20),
	@w_poliza_sal		varchar(20),
	@w_aseguradora		varchar(20),
	@w_fvigencia_inicio	datetime,
	@w_fvigencia_fin	datetime,
	@w_moneda		tinyint,
	@w_monto_poliza		money,
	@w_monto_endozo		money,
	@w_fecha_endozo		datetime,
	@w_cobertura		catalogo,
	@w_estado_poliza	catalogo,
	@w_descripcion		descripcion,
	@w_fendozo_fin		datetime,
	@w_return		int,
	@w_comentario		varchar(250),
	@w_des_aseguradora	varchar(150),
	@w_sp_name		varchar(80),
	@w_ssn			int,
	@w_deprecia		char(01)


select	@w_sp_name = 'sp_poliza_depreciacion'

if (@t_trn <> 19766 and @i_operacion = 'I') or
   (@t_trn <> 19766 and @i_operacion = 'S') or
   (@t_trn <> 19766 and @i_operacion = 'A')
begin
   /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,

    @i_num   = 1901006
    return 1 
end

if @i_operacion = 'I'	--CreaciĂ³n de nueva poliza y cancelaciĂ³n de la anterior
 begin
	select	@w_poliza = max(po_poliza) 
	  from	cu_poliza
	 where	po_codigo_externo = @i_codigo_externo
	   and	po_estado_poliza  = 'V'

	if @w_poliza is null
	 begin
		return 0	--Retorno sin error para que no se caiga el proceso por una poliza
	 end

	select	@w_poliza_ant 	= @w_poliza,
		@w_poliza 	= @w_poliza + '*'


	select	@w_aseguradora		= po_aseguradora,
		@w_fvigencia_inicio 	= po_fvigencia_inicio,
		@w_fvigencia_fin 	    = po_fvigencia_fin,
		@w_moneda 		        = po_moneda,
		@w_monto_poliza 	= po_monto_poliza,
		@w_monto_endozo		= po_monto_endozo,
		@w_fecha_endozo 	= po_fecha_endozo,
		@w_cobertura 		= po_cobertura,
		@w_estado_poliza 	= po_estado_poliza,
		@w_descripcion 		= po_descripcion,
		@w_fendozo_fin 		= po_fendozo_fin
	  from	cu_poliza
	 where	po_codigo_externo 	= @i_codigo_externo
	   and	po_poliza  	  	= @w_poliza_ant

	--Controlar que el monto depreciado no sea mayor al valor de la poliza
	--si es asĂ­ no la cancela ni emite una nueva
	
	if @i_monto_endozo <= @w_monto_poliza
		select @w_deprecia = 'S'
	else
	 begin
		select @w_deprecia = 'N'
		select @o_msg      = 'Monto de endoso es mayor al monto de la pĂ³liza'	--Fandrade 25/06/2009
	 end

	--print 'Ingresa nueva pĂ³liza en base a la existente'

	--print 'PĂ³liza %1!, Aseguradora %2!, Filial %3!, Sucursal %4!, Custodia %5!, Tipo %6!', @w_poliza, @w_aseguradora, @i_filial, @i_sucursal, @i_custodia, @i_tipo
	
	if @w_deprecia = 'S'
	 begin
		exec @w_ssn = ADMIN...rp_ssn 1, 2

		exec @w_return = cob_custodia..sp_poliza
		@s_ssn			= @w_ssn,
		@s_date               	= @s_date,
		@s_ofi			= @s_ofi,
		@s_user	       		= @s_user,
		@s_term 			= @s_term, --Miguel Aldaz 26/Feb/2015		
		@t_trn			= 19101, 
		@i_operacion		= 'U',
		@i_filial 		= @i_filial,
		@i_sucursal 		= @i_sucursal,
		@i_tipo			= @i_tipo,
		@i_custodia		= @i_custodia,
		@i_aseguradora		= @w_aseguradora,
		@i_poliza		= @w_poliza,
		@i_fvigencia_inicio 	= @w_fvigencia_inicio,
		@i_fvigencia_fin	= @w_fvigencia_fin,
		@i_fendoso_ini		= @i_fecha_endozo,   --PQU integración se cambia i_fecha_endozo por @i_fendoso_ini
		@i_fendoso_fin		= @i_fendozo_fin,    --PQU integración se cambia i_fendoso_ini por i_fendoso_fin
		@i_moneda		= @w_moneda,
		@i_monto_poliza		= @w_monto_poliza,
		@i_monto_endoso		= @i_monto_endozo,  --PQU integración se cambia @i_monto_endoso por @i_monto_endoso
		@i_nemonico_cob		= @w_cobertura,     --PQU integracion, se cambia el i_cobertura por i_nemonico_cob
		@i_descripcion		= @w_descripcion,
		@i_estado_poliza	= 'V',
		@i_renovacion		= 'N',
		@i_externo		= 'S',	--Fandrade 25/06/2009 Controlar que se ejecuta por depreciaciĂ³n
		@o_poliza		= @w_poliza_sal output,
		@o_msg			= @o_msg output	--Fandrade 25/06/2009 Control de mensaje de error

		--Fandrade 25/06/2009 Si hay error retorna para que no se caiga
		if @w_return > 0
		 begin
			select	@o_deprecia    = 'N'
			return 0
		 end

		select	@o_poliza      = @w_poliza_sal,
			@o_poliza_ant  = @w_poliza_ant,
			@o_aseguradora = @w_aseguradora,
			@o_deprecia    = 'S',
			@o_monto_poliza= @w_monto_poliza

		--print 'Ingresa Estado de cancelado la pĂ³liza existente'

		exec @w_ssn = ADMIN...rp_ssn 1, 2

		exec @w_return = cob_custodia..sp_poliza
		@s_ssn			= @w_ssn,
		@s_date               	= @s_date,
		@s_ofi			= @s_ofi,
		@s_user	       		= @s_user,
		@s_term 			= @s_term, --Miguel Aldaz 26/Feb/2015		
		@t_trn			= 19101, 
		@i_operacion		= 'U',
		@i_filial 		= @i_filial,
		@i_sucursal 		= @i_sucursal,
		@i_tipo			= @i_tipo,
		@i_custodia		= @i_custodia,
		@i_aseguradora		= @w_aseguradora,
		@i_poliza		= @w_poliza_ant,
		@i_fvigencia_inicio 	= @w_fvigencia_inicio,
		@i_fvigencia_fin	= @w_fvigencia_fin,
		@i_fendoso_ini		= @w_fecha_endozo,  --PQU integracion
		@i_fendoso_fin		= @w_fendozo_fin,   --PQU integracion
		@i_moneda		= @w_moneda,
		@i_monto_poliza		= @w_monto_poliza,
		@i_monto_endoso		= @w_monto_endozo,  --PQU integracion
		@i_nemonico_cob		= @w_cobertura,     --PQU integracion
		@i_descripcion		= @w_descripcion,
		@i_estado_poliza	= 'C',
		@i_renovacion		= 'N',
		@i_externo		= 'S',		--Fandrade 25/06/2009 Controlar que se ejecuta por depreciaciĂ³n
		@o_msg			= @o_msg output	--Fandrade 25/06/2009 Control de mensaje de error

		--Fandrade 25/06/2009 Si hay error retorna para que no se caiga
		if @w_return > 0
		 begin
			select	@o_deprecia    = 'N'
			return 0
		 end
	 end
	else
	 begin
	 	select	@o_poliza_ant  = @w_poliza_ant,
			@o_aseguradora = @w_aseguradora,
			@o_deprecia    = 'N',
			@o_monto_poliza= @w_monto_poliza
	 end
 end

if @i_operacion = 'S'
 begin
 	
 	select	@w_aseguradora	    = po_aseguradora,
 		@w_des_aseguradora  = y.valor,
 		@w_poliza	    = po_poliza,
 		@w_fvigencia_inicio = po_fvigencia_inicio,
 		@w_fvigencia_fin    = po_fvigencia_fin,
 		@w_monto_poliza     = po_monto_poliza,
 		@w_fecha_endozo	    = po_fecha_endozo,
 		@w_fendozo_fin	    = po_fendozo_fin,
 		@w_monto_endozo	    = po_monto_endozo,
 		@w_descripcion	    = po_descripcion
 	  from	cu_poliza,
 	  	cobis..cl_tabla x,
 	  	cobis..cl_catalogo y
 	 where	x.codigo = y.tabla
 	   and	x.tabla  = 'cu_des_aseguradora'
 	   and  y.codigo = po_aseguradora
 	   and	po_codigo_externo = @i_codigo_externo
 	   and	po_estado_poliza  = 'V'
 	   and	po_fecha_endozo = (
				select	max(po_fecha_endozo)
				  from	cu_poliza
				 where	po_codigo_externo = @i_codigo_externo
				   and	po_estado_poliza  = 'V'
				  )
	
	if @@rowcount = 0
		select	@w_comentario = 'No existe pĂ³liza para esta garantĂ­a'
	else
	 begin
	
		if @i_monto_endozo = @w_monto_endozo
		 begin
			if @i_fecha_endozo = @w_fecha_endozo
			 begin
				if @i_fendozo_fin = @w_fendozo_fin
					select	@w_comentario = 'PĂ³liza OK'
				else
					select	@w_comentario = 'Fecha de fin de endozo diferente a la del proceso'
			 end
			else
				select	@w_comentario = 'Fecha de inicio de endozo diferente a la del proceso'
		 end
		else
			select	@w_comentario = 'Valor diferente al de la depreciaciĂ³n'
	 end
			
	insert	into cu_tpolizas_creadas
		(
		po_codigo_externo,
		po_aseguradora,
		po_descr_aseguradora,
		po_poliza,
		po_operacion,
		po_fvigencia_inicio,
		po_fvigencia_fin,
		po_monto_poliza,
		po_fecha_endozo,
		po_fendozo_fin,
		po_monto_endozo,
		po_descripcion,
		po_monto_depreciado,
		po_fendozo_ini_proc,
		po_fendozo_fin_proc,
 		po_comentario
 		)
 	values	(
		@i_codigo_externo,
		@w_aseguradora,
		@w_des_aseguradora,
		@w_poliza,
		@i_banco,
		@w_fvigencia_inicio,
		@w_fvigencia_fin,
		@w_monto_poliza,
		@w_fecha_endozo,
		@w_fendozo_fin,
		@w_monto_endozo,
 		@w_descripcion,
 		@i_monto_endozo,
 		@i_fecha_endozo,
 		@i_fendozo_fin,
 		@w_comentario
		)
 		
 end

if @i_operacion = 'C'	--CancelaciĂ³n de las pĂ³lizas
 begin
 		
-- 	declare	c_polizas insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
 	declare	c_polizas cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
 	select	po_poliza
	  from	cu_poliza
	 where	po_codigo_externo = @i_codigo_externo
	   and	po_estado_poliza  = 'V'
	
	open c_polizas
	
	fetch c_polizas 
	into @w_poliza
	
	while @@FETCH_STATUS <> -1
	 begin

		select	@w_aseguradora		= po_aseguradora,
			@w_fvigencia_inicio 	= po_fvigencia_inicio,
			@w_fvigencia_fin 	= po_fvigencia_fin,
			@w_moneda 		= po_moneda,
			@w_monto_poliza 	= po_monto_poliza,
			@w_monto_endozo		= po_monto_endozo,
			@w_fecha_endozo 	= po_fecha_endozo,
			@w_cobertura 		= po_cobertura,
			@w_estado_poliza 	= po_estado_poliza,
			@w_descripcion 		= po_descripcion,
			@w_fendozo_fin 		= po_fendozo_fin
		  from	cu_poliza
		 where	po_codigo_externo 	= @i_codigo_externo
		   and	po_poliza  	  	= @w_poliza


		exec @w_return = cob_custodia..sp_poliza
			@s_ssn               	= @s_ssn,
			@s_date               	= @s_date,
			@s_ofi			= @s_ofi,
   			@s_user	       		= @s_user,
			@s_term 			= @s_term, --Miguel Aldaz 26/Feb/2015
			@t_trn			= 19101, 
			@i_operacion		= 'U',
			@i_filial 		= @i_filial,
			@i_sucursal 		= @i_sucursal,
			@i_tipo			= @i_tipo,
			@i_custodia		= @i_custodia,
			@i_aseguradora		= @w_aseguradora,
			@i_poliza		= @w_poliza,
			@i_fvigencia_inicio 	= @w_fvigencia_inicio,
			@i_fvigencia_fin	= @w_fvigencia_fin,
			@i_fendoso_ini		= @w_fecha_endozo,  --PQU integracion
			@i_fendoso_fin		= @w_fendozo_fin,   --PQU integracion
			@i_moneda		= @w_moneda,
			@i_monto_poliza		= @w_monto_poliza,
			@i_monto_endoso		= @w_monto_endozo,  --PQU integracion
			@@i_nemonico_cob	= @w_cobertura,  --PQU integracion
			@i_descripcion		= @w_descripcion,
			@i_estado_poliza	= 'C',
			@i_renovacion		= 'N',
			@i_pago			= 1,
			@i_secuencial_pag	= @i_secuencial_pag

		if @w_return > 0
			return 0

		fetch c_polizas 
		 into @w_poliza
	 end 	
 end

if @i_operacion = 'R'	--Reverso de las pĂ³lizas
 begin
 		
 	declare	c_polizas insensitive cursor for /* HHO Mayo/2012    Migracion SYBASE 15 */
 	select	po_poliza
	  from	cu_poliza
	 where	po_codigo_externo = @i_codigo_externo
	   and	po_estado_poliza  = 'C'
	   and	po_secuencial_pag = @i_secuencial_pag
	
	open c_polizas
	
	fetch c_polizas 
	into @w_poliza
	
	while @@FETCH_STATUS <> -1
	 begin

		select	@w_aseguradora		= po_aseguradora,
			@w_fvigencia_inicio 	= po_fvigencia_inicio,
			@w_fvigencia_fin 	= po_fvigencia_fin,
			@w_moneda 		= po_moneda,
			@w_monto_poliza 	= po_monto_poliza,
			@w_monto_endozo		= po_monto_endozo,
			@w_fecha_endozo 	= po_fecha_endozo,
			@w_cobertura 		= po_cobertura,
			@w_estado_poliza 	= po_estado_poliza,
			@w_descripcion 		= po_descripcion,
			@w_fendozo_fin 		= po_fendozo_fin
		  from	cu_poliza
		 where	po_codigo_externo 	= @i_codigo_externo
		   and	po_poliza  	  	= @w_poliza

		exec @w_return = cob_custodia..sp_poliza
			@s_ssn              = @s_ssn,
			@s_date             = @s_date,
			@s_ofi				= @s_ofi,
   			@s_user	       		= @s_user,
			@s_term 			= @s_term, --Miguel Aldaz 26/Feb/2015
			@t_trn			= 19101, 
			@i_operacion		= 'U',
			@i_filial 		= @i_filial,
			@i_sucursal 		= @i_sucursal,
			@i_tipo			= @i_tipo,
			@i_custodia		= @i_custodia,
			@i_aseguradora		= @w_aseguradora,
			@i_poliza		= @w_poliza,
			@i_fvigencia_inicio 	= @w_fvigencia_inicio,
			@i_fvigencia_fin	= @w_fvigencia_fin,
			@i_fendoso_ini		= @w_fecha_endozo,  --PQU integracion
			@i_fendoso_fin		= @w_fendozo_fin,  --PQU integracion
			@i_moneda		= @w_moneda,
			@i_monto_poliza		= @w_monto_poliza,
			@i_monto_endoso		= @w_monto_endozo,  --PQU integracion
			@i_nemonico_cob		= @w_cobertura,     --PQU integracion
			@i_descripcion		= @w_descripcion,
			@i_estado_poliza	= 'V',
			@i_renovacion		= 'N',
			@i_pago			= 1
			--@i_secuencial_pag	= @i_secuencial_pag

		if @w_return > 0
			return 0

		fetch c_polizas 
		 into @w_poliza
	 end 	
 end
go