USE cob_interface
GO
/************************************************************/
/*   ARCHIVO:         sp_garantia_int.sp                    */
/*   NOMBRE LOGICO:   sp_garantia_int                       */
/*   PRODUCTO:        COBIS                                 */
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
/*Validar los datos ingresados para creación de garantías   */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/* 03/SEP/2021     EBA                 Emision Inicial      */
/************************************************************/

if exists (select 1 from sysobjects where name = 'sp_garantia_int')
   drop proc sp_garantia_int
go

CREATE PROCEDURE sp_garantia_int (
        @s_ssn                  int          = null,
        @s_date                 datetime     = null,
        @s_user                 login        = null,
        @s_term                 varchar(64)  = null,
        @s_ofi                  smallint     = null,
        @s_srv                  varchar(30)  = null,
        @s_rol                  smallint     = null,
        @s_sesn                 int          = null,
        @s_org                  char(1)      = null,
        @s_culture              varchar(10)  = null,
        @t_trn                  smallint     = null,
        @t_debug                char(1)      = 'N',
        @t_file                 varchar(14)  = null,
        @t_from                 varchar(30)  = null,
        @t_show_version         bit          = 0,
        @i_operacion            char(1)      = null,
        @i_filial               tinyint      = null,
        @i_sucursal             smallint     = null,
        @s_lsrv                 varchar(30)  = null,
        @i_tipo                 varchar(64)  = null,
        @i_custodia             int          = null,
        @i_estado               catalogo     = null,
        @i_fecha_ingreso        datetime     = null,
        @i_valor_inicial        money        = null,
        @i_valor_actual         money        = null,
        @i_moneda               tinyint      = null,
        @i_garante              int          = null,
        @i_instruccion          varchar(255) = null,
        @i_descripcion          varchar(255) = null,
        @i_inspeccionar         char(1)      = null,
        @i_motivo_noinsp        catalogo     = null,
        @i_fuente_valor         catalogo     = null,
        @i_almacenera           smallint     = null,
        @i_cta_inspeccion       varchar(20)   = null,
        @i_direccion_prenda     descripcion  = null,
        @i_ciudad_prenda        descripcion  = null,
        @i_telefono_prenda      varchar(20)  = null,
        @i_fecha_modif          datetime     = null,
        @i_fecha_const          datetime     = null,
        @i_formato_fecha        smallint     = null,
        @i_periodicidad         catalogo     = null,
        @i_depositario          varchar(255) = null,
        @i_posee_poliza         char(1)      = null,
        @i_parte                tinyint      = null,
        @i_cobranza_judicial    char(1)      = null,
        @i_estado_poliza        char(1)      = null,
        @i_num_hipoteca         varchar(10)  = null,
        @i_codigo_compuesto     varchar(64)  = null,
        @i_cuenta_dpf           varchar(30)  = null,
        @i_cliente              int          = null,
        @i_abierta_cerrada      char(1)      = null,
        @i_adecuada_noadec      char(1)      = null,
        @i_propietario          varchar(64)  = null,
        @i_eliminarcliente      char(1)      = null,
        @i_login                login        = null,
        @i_plazo_fijo           varchar(30)  = null,
        @i_det_cliente          char(1)      = null,
        @i_oficina_contabiliza  smallint     = null,
        @i_compartida           char(1)      = null,
        @i_valor_compartida     money        = null,
        @i_valor_real           money        = null,
        @i_ubicacion            catalogo     = null,
        @i_inscripcion          char(1)      = null,
        @i_sector               catalogo     = null,
        @i_vence_gar            datetime     = null,
        @i_ubicacion_f          varchar(64)  = null,
        @i_ssn                  int          = null,
        @i_mon_pfijo            tinyint      = null,
        @i_disponible           money        = null,
        @i_cuenta_hold          varchar(30)  = null,
        @i_utilizado            money        = null,
        @i_ente                 int          = null,
        @i_modo                 smallint     = null,
        @i_ciudad int = null,
        @i_fecha_ub_sal         datetime     = null,
        @i_fecha_ub_dev         datetime     = null,
        @i_descripcion_ub       varchar(255) = null,
        @i_cuenta_tipo          tinyint      = null,
        @i_mejoras_asegurar     money        = null,
        @i_nemonico_cob         catalogo     = null,
        @i_descripcion1         varchar(255) = null,
        @i_porcentaje_pignora   float        = null,
        @i_sujeta               char(1)      = null,
        @i_primario             char(1)      = null,
        @i_conyugue_ASFI        varchar(1)   = null,
        @i_categoria            char(2)      = null,
        @i_fecha_retiro         DATETIME     = null,
        @i_fecha_devolucion     DATETIME     = null,
        @i_fondo_garantia       VARCHAR(2)   = NULL,
        @i_valor_avaluo         MONEY        = NULL,
        @i_fecha_avaluo         DATETIME     = NULL,
        @i_cu_num_documento     VARCHAR(30)  = NULL,
        @i_suficiencia_legal    CHAR(1)      = NULL,
        @i_pais                 int          = NULL,
		@i_tramite              int          = NULL,
        @o_cod_externo          varchar(64)  = null out,
        @o_cod_custodia         int          = null out,
        @o_primario             char(1)      = null out,
        @o_mensaje              varchar(64)  = null out
)
as
declare @w_sp_name              varchar(32),
        @w_error                int,
		@w_return               int,
		@w_codigo_externo       varchar(64),
		@w_filial               tinyint,
        @w_sucursal             smallint,
		@w_tipo                 varchar(64),
		@w_cod_custodia         int,
		@w_nombre_lar           varchar(255),
		@w_cod_oficial          int


select @w_sp_name = 'sp_garantia_int',
       @w_error           = 0,
       @w_return          = 0,
	   @w_codigo_externo  = '',
	   @w_nombre_lar      = ''


--EJECUCION DE VALIDACIONES DE CAMPOS
--***********************************
select @i_abierta_cerrada   = UPPER(@i_abierta_cerrada)
select @i_suficiencia_legal = UPPER(@i_suficiencia_legal)
select @i_adecuada_noadec   = UPPER(@i_adecuada_noadec)
select @i_cobranza_judicial = UPPER(@i_cobranza_judicial)
select @i_fondo_garantia    = UPPER(@i_fondo_garantia)
select @i_inspeccionar      = UPPER(@i_inspeccionar)


--Validaciones
--Valida Filial
select @w_filial = fi_filial
from cobis..cl_filial
where fi_filial = @i_filial
if @w_filial = 0 or @w_filial is null
begin 
	select @w_error  = 2110235 -- No existe Filial
	goto ERROR
end
--Valida Garante
if @i_garante is not null and @i_garante <> 0
begin
	if not exists (select 1 from cobis..cl_ente where en_ente = @i_garante) 
	begin
		select @w_error = 2110236 --No existe Garante
		goto ERROR
	end
	if @i_garante = @i_cliente
	begin
		select @w_error = 2110237 --Garante no puede ser el mismo cliente
		goto ERROR
	end
end

--Valida Tramite
if @i_tramite is not null and @i_tramite <> 0
begin 
    if not exists (select 1 from cob_credito..cr_tramite 
           where tr_tramite = @i_tramite)
    begin
		select @w_error = 2110152
		goto ERROR
    end
end 


if @i_tipo <> 'GARGPE'
begin
		exec @w_return = cob_credito..sp_valida_garantia
			@i_oficina = @s_ofi,
			@i_tipo = @i_tipo,
			@i_valor_inicial = @i_valor_inicial,
			@i_moneda = @i_moneda,
			@i_abierta_cerrada = @i_abierta_cerrada,
			@i_fecha_avaluo = @i_fecha_avaluo,
			@i_fecha_const = @i_fecha_const,
			@i_nemonico_cob = @i_nemonico_cob,
			@i_suficiencia_legal = @i_suficiencia_legal,
			@i_adecuada_noadec = @i_adecuada_noadec,
			@i_cobranza_judicial = @i_cobranza_judicial,
			@i_fondo_garantia = @i_fondo_garantia,
			@i_inspeccionar = @i_inspeccionar,
			@i_motivo_noinsp = @i_motivo_noinsp,
			@i_periodicidad = @i_periodicidad,
			@i_pais = @i_pais,
			@i_almacenera = @i_almacenera
	
	select @w_error = @w_return
	if @w_return != 0
	begin
	goto ERROR
	end
	
	if @w_error = 0
	begin
		if @i_operacion = 'I'
		begin
			exec @w_return = cob_pac..sp_custodia_busin
				@s_srv                 = @s_srv,
				@s_user                = @s_user,
				@s_term                = @s_term,
				@s_ofi                 = @s_ofi,
				@s_rol                 = @s_rol,
				@s_ssn                 = @s_ssn,
				@s_lsrv                = @s_lsrv,
				@s_date                = @s_date,
				@s_sesn                = @s_sesn,
				@t_trn                 = 19090,
				@i_operacion           = 'I',
				@i_filial              = @i_filial,
				@i_sucursal            = @i_sucursal,
				@i_tipo                = @i_tipo,
				@i_estado              = @i_estado,
				@i_fecha_ingreso       = @i_fecha_ingreso,
				@i_valor_inicial       = @i_valor_inicial,
				@i_valor_actual        = @i_valor_actual,
				@i_valor_avaluo        = @i_valor_avaluo,
				@i_moneda              = @i_moneda,
				@i_descripcion         = @i_descripcion,
				@i_inspeccionar        = @i_inspeccionar,
				@i_motivo_noinsp       = @i_motivo_noinsp,
				@i_suficiencia_legal   = @i_suficiencia_legal,
				@i_fuente_valor        = @i_fuente_valor,
				@i_almacenera          = @i_almacenera,
				@i_direccion_prenda    = @i_direccion_prenda,
				@i_ciudad_prenda       = @i_ciudad_prenda,
				@i_telefono_prenda     = @i_telefono_prenda,
				@i_fecha_const         = @i_fecha_const,
				@i_periodicidad        = @i_periodicidad,
				@i_depositario         = @i_depositario,
				@i_posee_poliza        = @i_posee_poliza,
				@i_cobranza_judicial   = @i_cobranza_judicial,
				@i_abierta_cerrada     = @i_abierta_cerrada,
				@i_adecuada_noadec     = @i_adecuada_noadec,
				@i_oficina_contabiliza = @i_oficina_contabiliza,
				@i_compartida          = @i_compartida,
				@i_valor_compartida    = @i_valor_compartida,
				@i_cu_num_documento    = @i_cu_num_documento,
				@i_nemonico_cob        = @i_nemonico_cob,
				@i_fecha_avaluo        = @i_fecha_avaluo,
				@i_fondo_garantia      = @i_fondo_garantia,
				@i_cliente             = @i_cliente,
				@i_garante             = @i_garante,
				@o_cod_externo         = @w_codigo_externo out
				
			
			if @w_return != 0
			begin
			select @w_error  = @w_return
			goto ERROR
			end
			if @i_tramite is not null AND (@w_codigo_externo <> '')
			BEGIN
			exec @w_return = cob_credito..sp_gar_propuesta
			     @s_srv                 = @s_srv,
			     @s_user                = @s_user,
			     @s_term                = @s_term,
			     @s_ofi                 = @s_ofi,
			     @s_rol                 = @s_rol,
			     @s_ssn                 = @s_ssn,
			     @s_lsrv                = @s_lsrv,
			     @s_date                = @s_date,
			     @s_sesn                = @s_sesn,
			     @t_trn                 = 21028,
			     @i_operacion           = 'I',
			     @i_tramite             = @i_tramite,
			     @i_garantia            = @w_codigo_externo,
			     @i_estado              = @i_estado,
			     @i_clase               = @i_abierta_cerrada,
			     @i_deudor              = @i_cliente
				 
			   if @w_return != 0
			   begin
			       select @w_error = @w_return
			       goto ERROR
			   end
	
			end
			
			select @o_cod_externo = @w_codigo_externo
				
		end
		
		if @i_operacion = 'U'
		begin
			if @i_codigo_compuesto is not null and @i_codigo_compuesto <> ''
			begin
				select @w_filial       = cu_filial,
				       @w_sucursal     = cu_sucursal,
				       @w_tipo         = cu_tipo, 
				       @w_cod_custodia = cu_custodia 
				from   cob_custodia..cu_custodia 
				where  cu_codigo_externo = @i_codigo_compuesto
			end
			else
			begin
				select @w_error  = 2110181 --Error, garantía no existe
			    goto ERROR
			end
			exec @w_return = cob_pac..sp_custodia_busin
				@s_srv                 = @s_srv,
				@s_user                = @s_user,
				@s_term                = @s_term,
				@s_ofi                 = @s_ofi,
				@s_rol                 = @s_rol,
				@s_ssn                 = @s_ssn,
				@s_lsrv                = @s_lsrv,
				@s_date                = @s_date,
				@s_sesn                = @s_sesn,
				@t_trn                 = 19091,
				@i_operacion           = 'U',
				@i_filial              = @w_filial,
				@i_sucursal            = @w_sucursal,
				@i_tipo                = @w_tipo,
				@i_custodia            = @w_cod_custodia,
				@i_estado              = @i_estado,
				@i_fecha_ingreso       = @i_fecha_ingreso,
				@i_valor_inicial       = @i_valor_inicial,
				@i_valor_actual        = @i_valor_actual,
				@i_valor_avaluo        = @i_valor_avaluo,
				@i_moneda              = @i_moneda,
				@i_garante             = @i_garante,
				@i_instruccion         = @i_instruccion,
				@i_descripcion         = @i_descripcion,
				@i_inspeccionar        = @i_inspeccionar,
				@i_motivo_noinsp       = @i_motivo_noinsp,
				@i_suficiencia_legal   = @i_suficiencia_legal,
				@i_fuente_valor        = @i_fuente_valor,
				@i_almacenera          = @i_almacenera,
				@i_cta_inspeccion      = @i_cta_inspeccion,
				@i_direccion_prenda    = @i_direccion_prenda,
				@i_ciudad_prenda       = @i_ciudad_prenda,
				@i_telefono_prenda     = @i_telefono_prenda,
				@i_fecha_const         = @i_fecha_const,
				@i_periodicidad        = @i_periodicidad,
				@i_depositario         = @i_depositario,
				@i_posee_poliza        = @i_posee_poliza,
				@i_cobranza_judicial   = @i_cobranza_judicial,
				@i_fecha_retiro        = @i_fecha_retiro,
				@i_fecha_devolucion    = @i_fecha_devolucion,
				@i_cuenta_dpf          = @i_cuenta_dpf,
				@i_abierta_cerrada     = @i_abierta_cerrada,
				@i_adecuada_noadec     = @i_adecuada_noadec,
				@i_propietario         = @i_propietario,
				@i_plazo_fijo          = @i_plazo_fijo,
				@i_oficina_contabiliza = @i_oficina_contabiliza,
				@i_compartida          = @i_compartida,
				@i_valor_compartida    = @i_valor_compartida,
				@i_cu_num_documento    = @i_cu_num_documento,
				@i_nemonico_cob        = @i_nemonico_cob,
				@i_fecha_avaluo        = @i_fecha_avaluo,
				@i_fondo_garantia      = @i_fondo_garantia,
				@i_parte               = 1,
				@i_codigo_compuesto    = @i_codigo_compuesto
				
			
			if @w_return != 0
			begin
			    select @w_error = @w_return
			    goto ERROR
			end
				
		end
	end
end --fin tipo <> GARGPE

if @i_tipo = 'GARGPE' and @i_operacion = 'I'
begin
	exec @w_return = cob_pac..sp_custodia_busin
	     @s_srv                 = @s_srv,
         @s_user                = @s_user,
         @s_term                = @s_term,
         @s_ofi                 = @s_ofi,
         @s_rol                 = @s_rol,
         @s_ssn                 = @s_ssn,
         @s_lsrv                = @s_lsrv,
         @s_date                = @s_date,
         @s_sesn                = @s_sesn,
         @t_trn                 = 19090,
		 @i_operacion           = 'I',
	     @i_filial              = @i_filial,
		 @i_sucursal            = @i_sucursal,
         @i_tipo                = @i_tipo,
		 @i_estado              = @i_estado,
		 @i_garante             = @i_garante,
		 @i_cliente             = @i_cliente,
		 @i_valor_inicial       = 0,
		 @i_valor_actual        = 0,
		 @i_valor_avaluo        = 0,
		 @i_moneda              = 0,
		 @i_descripcion         = 'GARGPE',
		 @i_inspeccionar        = 'N',
         @i_suficiencia_legal   = 'O',
         @i_periodicidad        = 'N',
		 @i_cobranza_judicial   = 'N',
		 @i_abierta_cerrada     = @i_abierta_cerrada,
		 @i_adecuada_noadec     = 'O',
		 @i_oficina_contabiliza = @i_sucursal,
		 @i_compartida          = 'N',
		 @i_valor_compartida    = 0,
		 @i_fondo_garantia      = 'N',
		 @o_cod_externo         = @w_codigo_externo out
	
	if @w_return != 0
       begin
          select @w_error  = @w_return
          goto ERROR
       end
	if @i_tramite is not null AND (@w_codigo_externo <> '')
		BEGIN
			exec cob_credito..sp_gar_propuesta
			@s_srv                 = @s_srv,
			@s_user                = @s_user,
			@s_term                = @s_term,
			@s_ofi                 = @s_ofi,
			@s_rol                 = @s_rol,
			@s_ssn                 = @s_ssn,
			@s_lsrv                = @s_lsrv,
			@s_date                = @s_date,
			@s_sesn                = @s_sesn,
			@t_trn                 = 21028,
			@i_operacion           = 'I',
			@i_tramite             = @i_tramite,
			@i_garantia            = @w_codigo_externo,
			@i_estado              = @i_estado,
			@i_clase               = @i_abierta_cerrada,
			@i_deudor              = @i_cliente
			
		end
		select @o_cod_externo = @w_codigo_externo
end
if @i_tipo = 'GARGPE' and @i_operacion = 'U'
begin
    if @i_codigo_compuesto is not null and @i_codigo_compuesto <> ''
	begin
		select @w_filial       = cu_filial,
		       @w_sucursal     = cu_sucursal,
		       @w_tipo         = cu_tipo, 
		       @w_cod_custodia = cu_custodia 
		from   cob_custodia..cu_custodia 
		where  cu_codigo_externo = @i_codigo_compuesto
	end
	else
	begin
		select @w_error  = 2110181 --Error, garantía no existe
	    goto ERROR
	end
	
	exec @w_return = cob_pac..sp_custodia_busin
	     @s_srv                 = @s_srv,
         @s_user                = @s_user,
         @s_term                = @s_term,
         @s_ofi                 = @s_ofi,
         @s_rol                 = @s_rol,
         @s_ssn                 = @s_ssn,
         @s_lsrv                = @s_lsrv,
         @s_date                = @s_date,
         @s_sesn                = @s_sesn,
         @t_trn                 = 19091,
		 @i_operacion           = 'U',
	     @i_filial              = @w_filial,
		 @i_sucursal            = @w_sucursal,
         @i_tipo                = @w_tipo,
		 @i_custodia            = @w_cod_custodia,
		 @i_estado              = @i_estado,
		 @i_garante             = @i_garante,
		 @i_cliente             = @i_cliente,
		 @i_valor_inicial       = 0,
		 @i_valor_actual        = 0,
		 @i_valor_avaluo        = 0,
		 @i_moneda              = 0,
		 @i_descripcion         = 'GARGPE',
		 @i_inspeccionar        = 'N',
         @i_suficiencia_legal   = 'O',
         @i_periodicidad        = 'N',
		 @i_cobranza_judicial   = 'N',
		 @i_abierta_cerrada     = @i_abierta_cerrada,
		 @i_adecuada_noadec     = 'O',
		 @i_oficina_contabiliza = @w_sucursal,
		 @i_compartida          = 'N',
		 @i_valor_compartida    = 0,
		 @i_fondo_garantia      = 'N',
		 @i_parte               = 1

	
	if @w_return != 0
       begin
          select @w_error = @w_return
          goto ERROR
       end
	
	select @w_cod_oficial = en_oficial,
	       @w_nombre_lar = substring(en_nomlar,1,datalength(en_nomlar))	
    from   cobis..cl_ente
    where  en_ente  = @i_cliente
	   
	exec @w_return = cob_pac..sp_cliente_garantia_busin 
         @s_user                = @s_user,
         @s_term                = @s_term,
         @s_ofi                 = @s_ofi,
         @s_ssn                 = @s_ssn,
         @s_date                = @s_date,
		 @t_trn                 = 19040,
		 @i_filial              = @w_filial,
		 @i_sucursal            = @w_sucursal,
		 @i_custodia            = @w_cod_custodia,
		 @i_tipo_cust           = @w_tipo,
		 @i_ente                = @i_cliente,
		 @i_principal           = 'N',
		 @i_oficial             = @w_cod_oficial,
		 @i_nombre              = @w_nombre_lar,
		 @i_operacion           = 'I'
	
	if @w_return != 0
       begin
          select @w_error = @w_return
          goto ERROR
       end
		 
end

return 0

ERROR:    --Rutina que dispara sp_cerror dado el codigo de error
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return @w_error
GO

