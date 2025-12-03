/*************************************************************************/
/*   Archivo:              custodia.sp                                   */
/*   Stored procedure:     sp_custodia                                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
/*   Fecha de escritura:   Marzo 2019                                    */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  “Este programa es parte de los paquetes bancarios que son           */
/*  comercializados por empresas del Grupo Empresarial TOPAZ,           */
/*  representantes exclusivos para comercializar los productos          */
/*  y licencias de TOPAZ TECHNOLOGIES S.L., sociedad constituida y      */
/*  regida por las Leyes de la República de España y las                */
/*  correspondientes de la Unión Europea. Su copia, reproducción,       */
/*  alteración en cualquier sentido, ingeniería reversa, almacenamiento */
/*  o cualquier uso no autorizado por cualquiera de los usuarios o      */
/*  personas que hayan accedido al presente sitio, queda expresamente   */
/*  prohibido; sin el debido consentimiento por escrito, de parte       */
/*  de los representantes de TOPAZ TECHNOLOGIES S.L. El incumplimiento  */
/*  de lo dispuesto en el presente texto, causará violaciones           */
/*  relacionadas con la propiedad intelectual y la confidencialidad     */
/*  de la información tratada; y por lo tanto, derivará en acciones     */
/*  legales civiles y penales en contra del infractor según             */
/*  corresponda.”                                                       */ 
/*************************************************************************/
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR           RAZON                      */
/*    Marzo/2019                              emision inicial            */
/*                                                                       */
/*    28/06/2019              BSJ             Adecuaciones para          */
/*                                            garantias liquidas         */
/*    19/04/2021              KDR             Modificar validación       */
/*                                            código cliente null        */
/*    10/12/2021              GFP             Almacenamiento de          */
/*                                            porcentaje de cobertura    */
/*    25/03/2022              KDR             Simbolo moneda en resulset */
/*    29/05/2025              FRI             RM-262474 Validación       */
/*                                            variable sucursal          */
/*    27/06/2025              FRI             RM-273512 consulta garantia*/
/*************************************************************************/

USE cob_custodia
go
IF OBJECT_ID('dbo.sp_custodia') IS NOT NULL
    DROP PROCEDURE dbo.sp_custodia
go
create proc sp_custodia (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
 --@s_term               varchar(64) = null,
   @s_term 			  	 varchar(30) = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_filial             tinyint  = null,
   @i_sucursal           smallint  = null,
   @i_tipo               varchar(64)  = null,
   @i_custodia           int  = null,
   @i_propuesta          int  = null,
   @i_estado             catalogo  = null,
   @i_fecha_ingreso      datetime  = null,
   @i_valor_inicial      money  = null,
   @i_valor_actual       money  = null,
   @i_moneda             tinyint  = null,
   @i_garante            int  = null,
   @i_instruccion        varchar(255)  = null,
   @i_descripcion        varchar(255)  = null,
   @i_poliza             varchar( 20)  = null,
   @i_inspeccionar       char(  1)  = null,
   @i_motivo_noinsp      catalogo = null,
   @i_suficiencia_legal  char(1) = null,
   @i_fuente_valor       catalogo  = null,
   @i_situacion          char(  1)  = null,
   @i_almacenera         smallint  = null,
   @i_aseguradora        varchar( 20)  = null,
   @i_cta_inspeccion     ctacliente  = null,
   @i_direccion_prenda   descripcion  = null,
   @i_ciudad_prenda      descripcion  = null,
   @i_telefono_prenda    varchar( 20)  = null,
   @i_mex_prx_inspec     tinyint  = null,
   @i_fecha_modif        datetime  = null,
   @i_fecha_const        datetime  = null,
   @i_porcentaje_valor   float  = null,
   @i_formato_fecha      int = null,
   @i_periodicidad   	 catalogo = null,
   @i_depositario   	 varchar(255) = null,
   @i_posee_poliza	 char(1) = null,
   @i_custodia1          int = null,
   @i_custodia2          int = null,
   @i_custodia3          int = null,
   @i_fecha_ingreso1     datetime = null,
   @i_fecha_ingreso2     datetime = null,
   @i_fecha_ingreso3     datetime = null,
   @i_tipo1              varchar(64) = null,
   @i_cond1	         varchar(64) = null,
   @i_cond2		 varchar(64) = null,
   @i_cond3		 varchar(64) = null,
   @i_param1	         varchar(64) = null,
   @i_parte              tinyint = null,
   @i_cobranza_judicial	 char(1) = null,
   @i_fecha_retiro	 datetime = null,
   @i_fecha_devolucion   datetime = null,
   @i_estado_poliza      char(1)  = null,
   @i_cobrar_comision    char(1) = null,
   @i_codigo_compuesto	 varchar(64) = null,
   @i_compuesto          varchar(64) = null,
   @i_cuenta_dpf         varchar(30) = null,
   @i_cliente            int = null,
   @i_ente               int = null,
   @i_abierta_cerrada    char(1)     = null,
   @i_adecuada_noadec    char(1)     = null,
   @i_propietario        varchar(64) = null,
   @i_fsalida_colateral  datetime    = null,
   @i_fretorno_colateral datetime    = null,
   @i_eliminarcliente    char(1)     = null,
   @i_login              login       = null,
   @i_plazo_fijo         varchar(30) = null,
   @i_monto_pfijo        money       = null,
   @i_det_cliente        char(1)     = null,
   @i_oficina_contabiliza smallint   = null,
   @i_compartida         char(1)     = null,
   @i_valor_compartida   money       = null,
   @i_commit             char(1)     = 'S',  	 ---GCR
   @i_nombre             descripcion = null,     --MVI 10/10/97
   @i_origen             char(1)     = null,         ---- ame 09/sept/2004
   @i_fecha_vencimiento	 datetime    = null,     --VDA 07/19/2005
   @i_scoring            char(1)     = 'N',	 --TRugel 02/01/2008
   @i_sustitucion	     char(1)     = null,	 --FAndrade 08/04/2008
   @i_toperacion	     char(10)    = null,     --FAndrade 08/04/2008
   --II FAE 03/May/2012
   @i_pais		         smallint    = null,
   @i_provincia		     smallint    = null,
   @i_canton		     int          = null,   -- KDR Cambio tipo de dato por compatibilidad con cobis..cl_ciudad
   @i_grupal		     char(1)     = 'N',
   @i_agotada            char(1)     = null,
   @i_clase_custodia     char(1)     = null,
   --FI FAE 03/May/2012
   @o_custodia           int         = null out, --LRE 06/22/06
   @o_codigo_externo     varchar(64) = null out  --LRE 06/22/06
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_retorno            int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_sucursal_up        smallint,
   @w_tipo               varchar(64),
   @w_custodia           int,
   @w_propuesta          int,      -- no se utiliza, sirve para
   @w_num_inspecc        tinyint,  -- numero de inspecciones
   @w_estado             catalogo,
   @w_fecha_ingreso      datetime,
   @w_valor_inicial      money,
   @w_valor_actual       money,
   @w_moneda             tinyint,
   @w_garante            int,
   @w_instruccion        varchar(255),
   @w_descripcion        varchar(255),
   @w_poliza             varchar( 20),
   @w_inspeccionar       char(  1),
   @w_fuente_valor       catalogo,
   @w_situacion          char(  1),
   @w_almacenera         smallint,
   @w_aseguradora        varchar( 20),
   @w_cta_inspeccion     ctacliente,
   @w_direccion_prenda   varchar(64),
   @w_ciudad_prenda      varchar(64),
   @w_telefono_prenda    varchar( 20),
   @w_mex_prx_inspec     tinyint,
   @w_fecha_modif        datetime,
   @w_fecha_const        datetime,
   @w_porcentaje_valor   float,
   @w_suficiencia_legal  char(  1),
   @w_motivo_noinsp      catalogo,
   @w_des_est_custodia   varchar(64),
   @w_des_fuente_valor   varchar(64),
   @w_des_motivo_noinsp  varchar(64), 
   @w_des_inspeccionar   varchar(64),
   @w_des_tipo           varchar(20),
   @w_des_moneda         varchar(30),
   @w_periodicidad  	 catalogo,
   @w_des_periodicidad	 catalogo,
   @w_depositario    	 varchar(255),
   @w_estado_aux         catalogo,
   @w_posee_poliza	 char(1),
   @w_des_garante        varchar(64),
   @w_des_almacenera	 varchar(64),
   @w_des_aseguradora 	 varchar(64),
   @w_valor_intervalo    tinyint,
   @w_error		 int,
   @w_cobranza_judicial  char(1),
   @w_contabilizar       char(1),
   @w_fecha_retiro       datetime, 
   @w_fecha_devolucion   datetime,
   @w_fecha_modificacion datetime,
   @w_usuario_crea	 login,
   @w_usuario_modifica	 login,
   @w_estado_poliza      char(1),
   @w_des_estado_poliza  varchar(64),
   @w_cobrar_comision    char(1),
   @w_abr_cer            char(1),
   @w_status		 int,
   @w_perfil		 varchar(10),
   @w_abierta_aux        char(1),
   @w_valor_conta        money,
   @w_cuenta_dpf         varchar(30),
   @w_cliente            int,
   @w_des_cliente        varchar(64),
   @w_nro_cliente        tinyint,
   @w_ente               int,
   @w_codigo_externo     varchar(64),
   @w_abierta_cerrada    char(1),
   @w_riesgos            char(1),
   @w_adecuada_noadec    char(1),
   @w_oficial            varchar(64),
   @w_propietario        varchar(64),
   @w_fsalida_colateral  datetime,
   @w_fretorno_colateral datetime,
   @w_plazo_fijo         varchar(30),
   @w_monto_pfijo        money,
   @w_oficina            smallint,
   @w_oficina_contabiliza smallint,
   @w_des_oficina        varchar(64),
   @w_compartida         char(1),
   @w_valor_compartida   money,
   @w_fecha_avaluo       datetime,
   @w_fecha_reg          datetime,
   @w_fecha_prox_insp    datetime,
   @w_fecha_venc	 datetime,  -- VDA 07/19/2005
   @w_garantia_seguro    char(1),    -- LRE 06/08/06
   @w_tipo_cca           catalogo,
   @w_codval             int,
   @w_tabla_rec          smallint,
   @w_fecha_poliza	 varchar(10),	--CMI 29Ene2007
   @w_iva                float, ---GCR
   @w_riva               float, ---GCR
   @w_rfte               float, ---GCR
   @w_deprecia_linea	 char(1),  --FAndrade 08/04/2008
   @w_existe_tipo	     char(1),  --PSE 06/19/2009 
   --II FAE 04/May/2012
   @w_pais		         smallint,
   @w_provincia		     smallint,
   @w_canton		     int,          -- KDR Cambio tipo de dato por compatibilidad con cobis..cl_ciudad
   @w_desc_pais		     varchar(64),
   @w_desc_provincia	 varchar(64),
   @w_desc_canton	     varchar(64),
   --FI FAE 04/May/2012
   @w_porcentaje_cobertura float, --GFP 10/12/2021
   @w_simbolo_moneda     varchar(10)  -- KDR 25/03/2021
   

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_custodia'
select @w_garantia_seguro = 'N'
select @w_existe_tipo = 'S' --PSE 07/03/2009

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19090 and @i_operacion = 'I') or
   (@t_trn <> 19091 and @i_operacion = 'U') or
   (@t_trn <> 19092 and @i_operacion = 'D') or
   (@t_trn <> 19664 and @i_operacion = 'F') or
   (@t_trn <> 19095 and @i_operacion = 'Q')  
begin
    /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

/* Chequeo de Existencias */
/**************************/
if @i_operacion <> null or @i_operacion <> ''
begin
    if @i_periodicidad = '1' /* Mensual */
       select @w_valor_intervalo = 1, @w_num_inspecc = 12
    if @i_periodicidad = '2' /* Mensual */
       select @w_valor_intervalo = 2, @w_num_inspecc = 6
    if @i_periodicidad = '3' /* Trimestral */
       select @w_valor_intervalo = 3, @w_num_inspecc = 4
    if @i_periodicidad = '6' /* Semestral */
       select @w_valor_intervalo = 6, @w_num_inspecc = 2
    if @i_periodicidad = '12' /* Anual */
       select @w_valor_intervalo = 12, @w_num_inspecc = 1

    /* Si se trata del codigo compuesto, dividirlo */ 
    if @i_codigo_compuesto is not null 
    begin
           exec @w_return = sp_compuesto
		   @s_user	  = @s_user, --Miguel Aldaz 26/Feb/2015
		   @s_term 	  = @s_term, --Miguel Aldaz 26/Feb/2015	
           @t_trn = 19245,
           @i_operacion = 'Q',
           @i_compuesto = @i_codigo_compuesto,
           @o_filial    = @i_filial out,
           @o_sucursal  = @i_sucursal out,
           @o_tipo      = @i_tipo out,
           @o_custodia  = @i_custodia out
    end

    select
         @w_filial = cu_filial,
         @w_sucursal = cu_sucursal,
         @w_tipo = cu_tipo,
         @w_custodia = cu_custodia,
         @w_oficina  = cu_oficina,
         @w_propuesta = cu_propuesta,
         @w_estado = cu_estado,
         @w_motivo_noinsp = cu_motivo_noinsp, 
         @w_fecha_ingreso = convert(char(10),cu_fecha_ingreso,101),
         @w_valor_inicial = cu_valor_inicial,
         @w_valor_actual = cu_valor_actual,
         @w_moneda = cu_moneda,
         @w_garante = cu_garante,
         @w_instruccion = cu_instruccion,
         @w_descripcion = cu_descripcion,
         @w_poliza = cu_poliza,
         @w_inspeccionar = cu_inspeccionar,
         @w_motivo_noinsp = cu_motivo_noinsp,
         @w_suficiencia_legal = cu_suficiencia_legal,
         @w_fuente_valor = cu_fuente_valor,
         @w_situacion = cu_situacion,
         @w_almacenera = cu_almacenera,
         @w_aseguradora = cu_aseguradora,
         @w_cta_inspeccion = cu_cta_inspeccion,
         @w_direccion_prenda = cu_direccion_prenda,
         @w_ciudad_prenda = cu_ciudad_prenda,
         @w_telefono_prenda = cu_telefono_prenda,
         @w_mex_prx_inspec = cu_mex_prx_inspec,
         @w_fecha_modif = cu_fecha_modif,
         @w_fecha_const = cu_fecha_const,
         @w_porcentaje_valor = cu_porcentaje_valor,
	 @w_periodicidad = cu_periodicidad,
	 @w_depositario = cu_depositario,
	 @w_posee_poliza = cu_posee_poliza,
         @w_cobranza_judicial = cu_cobranza_judicial,
         @w_fecha_retiro = cu_fecha_retiro,
         @w_fecha_devolucion = cu_fecha_devolucion,
         @w_fecha_modificacion = cu_fecha_modificacion,
         @w_usuario_crea = cu_usuario_crea,
         @w_usuario_modifica = cu_usuario_modifica,
         @w_estado_poliza = cu_estado_poliza, 
         @w_cobrar_comision = cu_cobrar_comision,
         @w_cuenta_dpf = cu_cuenta_dpf,
         @w_abierta_cerrada = cu_abierta_cerrada,
         @w_adecuada_noadec = cu_adecuada_noadec,
         @w_codigo_externo  = cu_codigo_externo,
         @w_propietario     = cu_propietario,
         @w_plazo_fijo      = cu_plazo_fijo,
         @w_monto_pfijo     = cu_monto_pfijo,
         @w_oficina_contabiliza = cu_oficina_contabiliza,
         @w_compartida          = cu_compartida,
         @w_valor_compartida    = cu_valor_compartida,
         @w_fecha_avaluo        = (select max(in_fecha_insp) from cob_custodia..cu_inspeccion
		                   where in_codigo_externo = x.cu_codigo_externo),
         @w_fecha_reg           = cu_fecha_reg,
         @w_fecha_prox_insp     = cu_fecha_prox_insp,
	 @w_fecha_venc		= cu_fecha_vencimiento,   -- VDA 07/19/2005
         @w_tipo_cca            = cu_tipo_cca,
         --II 04/May/2012
         @w_pais		= cu_pais,
         @w_provincia		= cu_provincia,
         @w_canton		= cu_canton
         --FI 04/May/2012
    from cob_custodia..cu_custodia x
    where cu_filial = @i_filial and
          cu_sucursal = @i_sucursal and
          cu_tipo = @i_tipo and
          cu_custodia = @i_custodia 
         
    if @@rowcount > 0
       select @w_existe = 1
    else
       select @w_existe = 0

    --GFP 10/12/2021
	select @w_porcentaje_cobertura = tc_porcen_cobertura
	from cu_tipo_custodia
	where tc_tipo = @i_tipo
end

--print 'fecha avaluo: %1!', @w_fecha_avaluo

/* VALIDACION DE CAMPOS NULOS */
/******************************/
if @i_operacion = 'I' or @i_operacion = 'U'
begin
    if @i_filial = NULL or 
       @i_sucursal = NULL or 
       @i_tipo = NULL
    begin
        /* Campos NOT NULL con valores nulos */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901001
        return 1 
    end

/* Validacion valor inicial no puede ser 0   RGP110903 */

 
    if (@i_valor_inicial = 0 and @i_tipo <>'GARGPE') begin
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901019
        return 1 
     end


     if (@i_tipo='GARGPE' and @i_valor_inicial<> 0) begin
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1901020
        return 1 
     end
end

if @i_operacion = 'I' or @i_operacion = 'U' or @i_operacion = 'Q'
begin
	--PSE 06/19/2009, verifica la existencia del tipo de custodia en la tabla T42     
     	select @w_existe_tipo = 'S'
     	if @i_tipo is not null	--PSE 08/07/2009
     	begin
	     	if not exists (select 1 
	       		         from cob_credito..cr_corresp_sib 
	      		        where tabla = 'T42'
	        	          and codigo = @i_tipo) and @i_tipo not in ('GARGPE','910','920','930','940','950','960','970') 
			select @w_existe_tipo = 'N'      	
	end	
     	--PSE 06/19/2009
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
        @i_num   = 1901002
        return 1 
    end

    if @i_sustitucion = 'S'
     begin
     	select	@w_deprecia_linea = pa_char
     	  from	cobis..cl_parametro
     	 where	pa_nemonico = 'PDAL'
     	
     	if not @w_deprecia_linea = 'N'
	 begin
		/* Proceso de Depreciacion automÃ¡tica en lÃ­nea */
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 1909016
		return 1 
    	 end
    	
    	if not exists (select 1 
    		     from cobis..cl_tabla x,
    		     	  cobis..cl_catalogo y
    		    where x.tabla  = 'ca_sustitucion'
    		      and x.codigo = y.tabla
    		      and y.codigo = @i_toperacion
    		  )
	 begin
	 	/* Tipo de operaciÃ³n no aplica para sustituciÃ³n */
		exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file, 
		@t_from  = @w_sp_name,
		@i_num   = 1909017
		return 1 
	 end
     	
     end
    
    if @i_commit = 'S' ---GCR
    begin tran

         select @w_custodia = null
         select @w_custodia = se_actual+1 
         from cu_seqnos
         where se_filial = @i_filial
           and se_sucursal = @i_sucursal        
           and se_tipo_cust = @i_tipo

         if @w_custodia is null
         begin
            insert into cu_seqnos 
            values (@i_filial,@i_sucursal,@i_tipo,1)
            select @w_custodia = 1
         end 
         else
            update cu_seqnos
            set se_actual = se_actual + 1
            where se_filial = @i_filial
              and se_sucursal = @i_sucursal
              and se_tipo_cust = @i_tipo       
         
         if @i_periodicidad is not NULL
            select @w_fecha_prox_insp = dateadd(mm,@w_valor_intervalo,@s_date)

         if @i_estado = 'C'  --Estado Cancelado
         begin
             /* Registro ya existe */
             exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file, 
                  @t_from  = @w_sp_name,
                  @i_num   = 1903011
             return 1 
         end

         if @i_estado = 'A'  --Estado Anulado
         begin
             /* Registro ya existe */
             exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file, 
                  @t_from  = @w_sp_name,
                  @i_num   = 1903012
             return 1 
         end

	--II CMI 19May2006
	if @i_estado = 'V' and @i_suficiencia_legal = 'N'
         begin
             /* No se puede ingresar estado vigente sin suficiencia legal */
             exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file, 
                  @t_from  = @w_sp_name,
                  @i_num   = 1901021
             return 1 
         end

         -- CODIGO EXTERNO
        
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @w_custodia,
        @o_compuesto = @w_codigo_externo out

         select @w_contabilizar = tc_contabilizar
         from cu_tipo_custodia
         where tc_tipo = @i_tipo

         if @w_contabilizar = 'N' and @i_estado = 'C'
         begin
             /* Registro ya existe */
            exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file, 
                  @t_from  = @w_sp_name,
                  @i_num   = 1901002
                 return 1
         end

         insert into cu_custodia(
              cu_filial,
              cu_sucursal,
              cu_tipo,
              cu_custodia,
              cu_propuesta,
              cu_estado,
              cu_fecha_ingreso,
              cu_valor_inicial,
              cu_valor_actual,
              cu_moneda,
              cu_garante,
              cu_instruccion,
              cu_descripcion,
              cu_poliza,
              cu_inspeccionar,
              cu_motivo_noinsp,
              cu_suficiencia_legal,
              cu_fuente_valor,
              cu_situacion,
              cu_almacenera,
              cu_aseguradora,
              cu_cta_inspeccion,
              cu_direccion_prenda,
              cu_ciudad_prenda,
              cu_telefono_prenda,
              cu_mex_prx_inspec,
              --cu_fecha_modif,
              cu_fecha_const,
              cu_porcentaje_valor,
	      cu_periodicidad,
	      cu_depositario,
	      cu_posee_poliza,
              cu_nro_inspecciones,
	      cu_intervalo,
              cu_cobranza_judicial,
              cu_fecha_retiro,
              cu_fecha_devolucion,
              cu_fecha_modificacion,
              cu_usuario_crea,
              cu_usuario_modifica,
              cu_estado_poliza, 
              cu_cobrar_comision,
              cu_cuenta_dpf,
              cu_codigo_externo,
              cu_fecha_insp,  --LCA
              cu_abierta_cerrada,
              cu_adecuada_noadec,
              cu_propietario,
              --cu_fsalida_colateral,
              --cu_fretorno_colateral,
              cu_plazo_fijo,
              cu_monto_pfijo,
              cu_oficina,
              cu_oficina_contabiliza,
              cu_compartida,
              cu_valor_compartida,
              cu_fecha_reg,         -- Fecha de registro de la Garantia
              cu_fecha_prox_insp,   -- Fecha proxima inspeccion
	      cu_fecha_vencimiento, -- ) -- VDA 07/19/2005
	      --II FAE 03/May/2012
	      cu_pais,
	      cu_provincia,
	      cu_canton,
	      cu_agotada,
	      cu_clase_custodia,
	      --FI FAE 03/May/2012
		  cu_porcentaje_cobertura   --GFP 10/12/2021
	      )
         values (
              @i_filial,
              @i_sucursal,
              @i_tipo,
              @w_custodia,
              @i_propuesta,    -- @w_num_inspecc,
              @i_estado,
              @i_fecha_ingreso,
              @i_valor_inicial,
              @i_valor_inicial,
              @i_moneda,
              @i_garante,
              @i_instruccion,
              @i_descripcion,
              @i_poliza,
              @i_inspeccionar,
              @i_motivo_noinsp,
              @i_suficiencia_legal,
              @i_fuente_valor,
              @i_situacion,
              @i_almacenera,
              @i_aseguradora,
              @i_cta_inspeccion,
              @i_direccion_prenda,
              @i_ciudad_prenda,
              @i_telefono_prenda,
              @i_mex_prx_inspec,
              --@i_fecha_modif,
              @i_fecha_const,
              @i_porcentaje_valor,
	      @i_periodicidad,
	      @i_depositario,
	      @i_posee_poliza,
              0,
	      @w_valor_intervalo,
              @i_cobranza_judicial,
              @i_fecha_retiro,
              @i_fecha_devolucion,
              NULL,
              @s_user,
              NULL,
              @i_estado_poliza,
              @i_cobrar_comision,
              @i_cuenta_dpf,
              @w_codigo_externo,
              @s_date,           --LCA                          
              @i_abierta_cerrada,
              @i_adecuada_noadec,
              @i_propietario,
              --@i_fsalida_colateral,
              --@i_fretorno_colateral,
              @i_plazo_fijo,
              @i_monto_pfijo,
              @s_ofi,
              @i_oficina_contabiliza,
              @i_compartida,
              @i_valor_compartida,
              @s_date,
              @w_fecha_prox_insp,
	      @i_fecha_vencimiento,  --)  -- VDA 07/19/2005
	      --II FAE 03/May/2012
	      @i_pais,
	      @i_provincia,
	      @i_canton,
	      @i_agotada,
	      @i_clase_custodia,
	      --FI FAE 03/May/2012
		  @w_porcentaje_cobertura   --GFP 10/12/2021
	      )

         if @@error <> 0 
         begin
             /* Error en insercion de registro */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903001
             return 1 
         end
       
         if @i_estado = 'V' -- Vigente
         begin
             select @w_contabilizar = tc_contabilizar
             from cu_tipo_custodia
             where tc_tipo = @i_tipo

             if @w_contabilizar = 'S'
             begin       
                 --  TRANSACCION CONTABLE 
                 exec @w_return = sp_conta
                      @s_ssn  = @s_ssn,
                      @s_date = @s_date,
					  @s_user = @s_user, --Miguel Aldaz 26/Feb/2015
					  @s_term = @s_term, --Miguel Aldaz 26/Feb/2015	
					  @t_trn  = 19300,
         	          @i_operacion = 'I',
					  @i_filial = @i_filial,
					  @i_oficina_orig = @i_oficina_contabiliza,
					  @i_oficina_dest = @i_oficina_contabiliza,
					  @i_tipo = @i_tipo,
					  @i_moneda = @i_moneda,
					  @i_valor = @i_valor_inicial,
					  @i_operac = 'I',
					  @i_signo = 1,
                      @i_codigo_externo = @w_codigo_externo

                 if @w_return <> 0 
                 begin
                     return 1 
                 end 
             end
         end 
           
        /*** Transaccion de Servicio****/ 
        /*******************************/
         insert into ts_custodia
         values (@s_ssn,@t_trn,'N',@s_date,@s_user,@s_term,@s_ofi,'cu_custodia',
         @i_filial,
         @i_sucursal,
         @i_tipo,
         @w_custodia,
         @i_propuesta,
         @i_estado,
         @i_fecha_ingreso,
         @i_valor_inicial,
         @i_valor_actual,
         @i_moneda,
         @i_garante,
         @i_instruccion,
         @i_descripcion,
         @i_poliza,
         @i_inspeccionar,
         @i_motivo_noinsp,
         @i_suficiencia_legal,
         @i_fuente_valor,
         @i_situacion,
         @i_almacenera,
         @i_aseguradora,
         @i_cta_inspeccion,
         @i_direccion_prenda,
         @i_ciudad_prenda,
         @i_telefono_prenda,
         @i_mex_prx_inspec,
         @i_fecha_modif,
         @i_fecha_const,
         @i_porcentaje_valor,
	 @i_periodicidad,
         @i_depositario,
	 @i_posee_poliza,
	 null,
	 null,
	 @i_cobranza_judicial,
	 @i_fecha_retiro,
	 @i_fecha_devolucion,
         null,
         @s_user,
         null,
         @i_estado_poliza,
         @i_cobrar_comision,
         @i_cuenta_dpf,
         @i_abierta_cerrada,
         @i_adecuada_noadec,
         @i_propietario,
         --@i_fsalida_colateral,
         --@i_fretorno_colateral,
         @i_plazo_fijo,
         @i_monto_pfijo,
         @i_oficina_contabiliza,
         @i_compartida,
         @i_valor_compartida,
         @s_date,
         @w_fecha_prox_insp,   --)
         @i_pais,
	 @i_provincia,
	 @i_canton
	 )
	 --@i_fecha_vencimiento) -- VDA 07/19/2005


         if @@error <> 0 
         begin
             /*Error en insercion de transaccion de servicio*/ 
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
         end 
         select @o_custodia = @w_custodia,
                @o_codigo_externo = @w_codigo_externo
         select @w_custodia
         --PSE 06/19/2009
         select @w_existe_tipo

    if @i_commit = 'S' ---GCR
    commit tran 

    return 0
end


/* Actualizacion del registro */
/******************************/
if @i_operacion = 'U'
begin
    if @w_existe = 0
    begin
        /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
    end

    if (@i_estado = 'A' and @w_estado = 'P')
    begin
       --TRugel 03/31/08 No se deben anular garantÂ¡as propuestas con polizas vigentes
       if exists (select 1
                  from cu_poliza
                  where po_codigo_externo = @w_codigo_externo
                    and po_estado_poliza  = 'V')
       begin
          exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1909015		--Existe poliza vigente asociada a la Garantia
          return 1 
       end
    end

    if @i_scoring = 'N'			--TRugel 02/01/2008
    begin

       exec @w_retorno = sp_riesgos1           -- SE SACAN LOS RIESGOS
            @s_date           = @s_date,
			@s_user	       	  = @s_user, --Miguel Aldaz 26/Feb/2015
			@s_term 		  = @s_term, --Miguel Aldaz 26/Feb/2015				
            @t_trn            = 19604,
            @i_operacion      = 'Q',
            @i_codigo_externo = @w_codigo_externo,
            @o_riesgos        = @w_riesgos out

       if @w_retorno <> 0
       begin
          /* Error en consulta de registro */
          exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 1909002
          return 1 
       end
    end

    begin tran
         -- CODIGO EXTERNO
        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
        
           ---- ame 09/sept/2004
          if @i_valor_inicial <> @w_valor_inicial 
           begin  
              if @i_origen = 'G' and @w_estado = 'P' and exists (select * from cob_credito..cr_gar_propuesta
                                                                  where gp_garantia = @w_codigo_externo )
                 begin
                  
                 	 exec cobis..sp_cerror
         	              @t_debug = @t_debug,
         	              @t_file  = @t_file, 
         	              @t_from  = @w_sp_name,
         	              @i_num   = 1905005
         	         return 1
                 end
           end

        if @i_parte = 1 -- Informacion de la pantalla principal de garantia
        begin
           if @i_valor_inicial <> @w_valor_inicial 
           begin  
              -- Si ya existen transacciones, no cambiar el valor inicial
              if exists (select * from cu_transaccion
                       	 where tr_codigo_externo  =  @w_codigo_externo)
                 or exists (select * from cu_vencimiento
                            where ve_codigo_externo = @w_codigo_externo)
                 or @w_estado = 'V' 
              --No se puede cambiar el valor inicial
              begin
               	 exec cobis..sp_cerror
         	 @t_debug = @t_debug,
         	 @t_file  = @t_file, 
         	 @t_from  = @w_sp_name,
         	 @i_num   = 1905005
         	 return 1
              end
              else
                 select @i_valor_actual = @i_valor_inicial
           end 
           
           select @w_estado_aux = @w_estado, @w_abierta_aux = @w_abierta_cerrada

           if @i_periodicidad is not NULL AND @w_fecha_avaluo IS NOT NULL
              select @w_fecha_prox_insp = dateadd(mm,@w_valor_intervalo,@w_fecha_avaluo)

			-- FRI 262474 se realiza consulta de la sucursal 
			select @w_sucursal_up = cu_sucursal
			from cob_custodia..cu_custodia
			where cu_filial = @i_filial and
                 cu_oficina_contabiliza = @i_sucursal and
                 cu_tipo = @i_tipo and
                 cu_custodia = @i_custodia
			
			
           update cob_custodia..cu_custodia
           set 
              cu_propuesta     = @i_propuesta,
              cu_estado        = @i_estado,
              cu_fecha_ingreso = @i_fecha_ingreso,
              cu_valor_inicial = @i_valor_inicial,
              cu_valor_actual  = @i_valor_actual,
              cu_moneda        = @i_moneda,
              cu_garante       = @i_garante,
              cu_instruccion   = @i_instruccion,
              cu_descripcion   = @i_descripcion,
              cu_inspeccionar  = @i_inspeccionar,
              cu_motivo_noinsp = @i_motivo_noinsp,
              cu_suficiencia_legal = @i_suficiencia_legal,
              cu_fuente_valor   = @i_fuente_valor,
              cu_situacion      = @i_situacion,
              cu_cta_inspeccion = @i_cta_inspeccion,
              cu_mex_prx_inspec = @i_mex_prx_inspec,
              --cu_fecha_modif    = @i_fecha_modif,
              cu_fecha_const    = @i_fecha_const,
              cu_porcentaje_valor = @i_porcentaje_valor,
	      cu_periodicidad   = @i_periodicidad,
	      cu_depositario    = @i_depositario,
	      cu_intervalo      = @w_valor_intervalo,
              cu_cobranza_judicial = @i_cobranza_judicial,
              cu_fecha_retiro = @i_fecha_retiro,
              cu_fecha_devolucion = @i_fecha_devolucion,
              cu_fecha_modificacion = @s_date,
              cu_usuario_modifica = @s_user,
              cu_cobrar_comision = @i_cobrar_comision,
              cu_cuenta_dpf  = @i_cuenta_dpf,
              cu_abierta_cerrada = @i_abierta_cerrada,
              cu_adecuada_noadec = @i_adecuada_noadec,
              cu_propietario     = @i_propietario,
              --cu_fsalida_colateral = @i_fsalida_colateral,
              --cu_fretorno_colateral = @i_fretorno_colateral,
              cu_almacenera = @i_almacenera,
              cu_direccion_prenda = @i_direccion_prenda,
              cu_ciudad_prenda = @i_ciudad_prenda,
              cu_telefono_prenda = @i_telefono_prenda,
              cu_oficina_contabiliza = @i_oficina_contabiliza,
              cu_plazo_fijo = @i_plazo_fijo,
              cu_compartida = @i_compartida,
              cu_valor_compartida = @i_valor_compartida,
              cu_fecha_prox_insp  = @w_fecha_prox_insp,
	      cu_fecha_vencimiento = @i_fecha_vencimiento,
	      --II FAE 03/May/2012
	      cu_pais	   = @i_pais,
	      cu_provincia = @i_provincia,
	      cu_canton	   = @i_canton,
	      --FI FAE 03/May/2012
		  cu_porcentaje_cobertura = @w_porcentaje_cobertura   --GFP 10/12/2021
           where cu_filial = @i_filial and
                 cu_sucursal = @w_sucursal_up and -- FRI 262474 Se consulta por la sucursal real 
                 cu_tipo = @i_tipo and
                 cu_custodia = @i_custodia



          if (@w_abierta_aux <> @i_abierta_cerrada or
               @w_estado_aux  <> @i_estado)


               update cob_credito..cr_gar_propuesta
               set gp_est_garantia = @i_estado,
                   gp_abierta      = @w_abierta_aux --@i_abierta_cerrada
               where gp_garantia     = @w_codigo_externo
          

           if @i_eliminarcliente = 'S'
              delete cob_custodia..cu_cliente_garantia
              where cg_codigo_externo = @w_codigo_externo

           if ((@i_estado = 'A' and @w_estado_aux = 'V') or
               (@i_estado = 'A' and @w_estado_aux = 'C'))
           begin
               /* No se puede cambiar a una garantia Anulada */
               exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name,
                 @i_num   = 1905013
               return 1
           end

           if (@i_estado = 'A' and @w_estado_aux = 'P')
           begin
               exec @w_retorno = sp_cancela  --SE ANULA LA GARANTIA 
                 @s_ssn            = @s_ssn,   --LRC dic.29.2007
                 @t_trn            = 19624,
                 @s_date           = @s_date,
				 @s_user	       = @s_user, --Miguel Aldaz 26/Feb/2015
				 @s_term 		   = @s_term, --Miguel Aldaz 26/Feb/2015	
                 @i_operacion      = 'S',
                 @i_cancelacion_credito = 'S',
                 @i_codigo_externo = @w_codigo_externo

               if @w_retorno <> 0
               begin
                   /*  Error en consulta de registro */
                   exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file, 
                     @t_from  = @w_sp_name,
                     @i_num   = 1909002
                   return 1 
               end
           end

           if (@i_estado <> 'A' and @w_estado_aux = 'A')
           begin
               /* No se puede cambiar a una garantia Anulada */
               exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name,
                 @i_num   = 1905014
               return 1
           end

           if @i_estado <> 'C' and @w_estado = 'C'
           begin
              /* No se puede cambiar de estado una garantia Cancelada */
               exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name,
                 @i_num   = 1905012
               return 1
           end

           if @i_estado = 'C' and @w_estado = 'C'
           begin
              /* No se puede cancelar una garantia ya Cancelada */
               exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file, 
                 @t_from  = @w_sp_name,
                 @i_num   = 1905008
               return 1
           end

           /* LA CANCELACION DE LA GARANTIA HACE QUE SU VALOR SEA 0 */
           if @i_estado = 'C' and @w_estado <> 'C' 
           begin 
               if @w_estado = 'P'  -- ESTADO PROPUESTO
               begin
                  /*No se puede cancelar una garantia en estado de Propuesta */
                   exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file, 
                     @t_from  = @w_sp_name,
                     @i_num   = 1905007
                   return 1
               end     
        
               if @w_riesgos = 'S'
               begin
                  /* No se puede cancelar una garantia con Riesgos */
                   exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file, 
                     @t_from  = @w_sp_name,
                     @i_num   = 1905006
                   return 1
               end
               else  -- Sin riesgos
               begin
                   if exists (select * from cu_vencimiento
                              where ve_codigo_externo = @w_codigo_externo) 
                   begin
                      /* No se puede cancelar una garantia con Vencimientos */
                       exec cobis..sp_cerror
                         @t_debug = @t_debug,
                         @t_file  = @t_file, 
                         @t_from  = @w_sp_name,
                         @i_num   = 1907010
                       return 1
                   end

                   if exists (select * from cu_por_inspeccionar
                              where pi_codigo_externo = @w_codigo_externo)
                      delete cu_por_inspeccionar
                      where pi_codigo_externo = @w_codigo_externo

                   if @i_login is null
                      select @i_login = @s_user

                   exec @w_status = sp_transaccion
                     @s_ssn  = @s_ssn,
                     @s_ofi  = @s_ofi,
                     @s_date = @s_date,
					 @s_user = @s_user, --Miguel Aldaz 26/Feb/2015
					 @s_term = @s_term, --Miguel Aldaz 26/Feb/2015	
                     @t_trn  = 19000,
                     @i_operacion = 'I',
                     @i_filial = @i_filial,
                     @i_sucursal = @i_sucursal,
                     @i_tipo_cust = @i_tipo,
                     @i_custodia = @i_custodia,
                     @i_fecha_tran = @w_today,
                     @i_debcred =  'D', 
                     @i_valor = @w_valor_actual,
                     @i_descripcion = 'CANCELACION DE LA GARANTIA',
                     @i_usuario = @s_user,
                     @i_estado_aux = @w_estado_aux,
                     @i_cancelacion = 'S'

                   if @w_status <> 0 
                   begin
                      /* Error en actualizacion de registro */
                       exec cobis..sp_cerror
                         @t_debug = @t_debug,
                         @t_file  = @t_file, 
                         @t_from  = @w_sp_name,
                         @i_num   = 1901013
                       return 1 
                   end

                   select @w_des_est_custodia = A.valor
                   from cobis..cl_catalogo A,cobis..cl_tabla B
                   where B.codigo = A.tabla and
                         B.tabla = 'cu_est_custodia' and
                         A.codigo = @i_estado

                   select @i_estado,@w_des_est_custodia

                   select @w_contabilizar = tc_contabilizar
                   from cu_tipo_custodia
                   where tc_tipo = @i_tipo

                   --print 'Contabiliza %1!',@w_contabilizar
                   --print 'Estado gar %1!',@w_estado                  

                   if @w_contabilizar = 'S' and @w_estado <> 'P'
                   begin       

                       ---Evaluar si se trata de Garantias con 
                       ---Reclasificacion Contable
                       select @w_codval = 19

                       select @w_tabla_rec = codigo
                         from cobis..cl_tabla 
                        where tabla = 'cu_reclasifica'

                       if exists (select codigo
                                    from cobis..cl_catalogo
                                   where tabla = @w_tabla_rec
                                     and codigo = @w_tipo 
                                     and estado = 'V')
                       begin
                         if @w_tipo_cca = null --No existe ya la relacion
                           select @w_codval = 1
                         else
                           select @w_codval = 2 --Levanta la Relacion
                       end

                       --TRANSACCION CONTABLE 
                       exec @w_return = sp_conta
                         @s_date = @s_date,
						 @s_user = @s_user, --Miguel Aldaz 26/Feb/2015
						 @s_term = @s_term, --Miguel Aldaz 26/Feb/2015	
						 @t_trn = 19300,
						 @i_operacion = 'I',
						 @i_filial = @i_filial,
						 @i_oficina_orig = @i_oficina_contabiliza,
						 @i_oficina_dest = @i_oficina_contabiliza,
						 @i_tipo = @i_tipo,
						 @i_moneda = @i_moneda,
						 @i_valor = @w_valor_actual,
						 @i_operac = 'E',
						 @i_signo = 1,
                         @i_codval = @w_codval,
                         @i_tipo_cca = @w_tipo_cca,
                         @i_codigo_externo = @w_codigo_externo

                      if @w_return <> 0 
                      begin
                         /* Error en actualizacion de registro */
                          exec cobis..sp_cerror
                            @t_debug = @t_debug,
                            @t_file  = @t_file, 
                            @t_from  = @w_sp_name,
                            @i_num   = 1901012
                          return 1 
                      end

                      update cu_custodia
                      set cu_fecha_modif = @s_date
                      where cu_codigo_externo = @w_codigo_externo  
                   end
               end  -- Else sin riesgos
           end   -- cancelacion de garantia
     
           /* Cambio de propuesta a vigente */
           if @i_estado = 'V' and @w_estado = 'P' 
           begin
		--II CMI 19 May 2006  
	       if @i_suficiencia_legal = 'N'
               begin
                  /* No se puede cambiar a estado vigente sin suficiencia legal */
                  exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file, 
                  @t_from  = @w_sp_name,
                  @i_num   = 1901021
                  return 1 
               end
		--FI CMI 19 May 2006  

               select @w_contabilizar = tc_contabilizar
               from cu_tipo_custodia
               where tc_tipo = @i_tipo

               if @w_contabilizar = 'S'
               begin       
                   --TRANSACCION CONTABLE 
                   exec @w_return = sp_conta
                     @s_date = @s_date,
					 @s_user	= @s_user, --Miguel Aldaz 26/Feb/2015
					 @s_term = @s_term, --Miguel Aldaz 26/Feb/2015						 
					 @t_trn = 19300,
					 @i_operacion = 'I',
					 @i_filial = @i_filial,
					 @i_oficina_orig = @i_oficina_contabiliza,
					 @i_oficina_dest = @i_oficina_contabiliza,
					 @i_tipo = @i_tipo,
					 @i_moneda = @i_moneda,
					 @i_valor = @i_valor_actual,
					 @i_operac = 'I',
					 @i_signo = 1,
                     @i_codigo_externo = @w_codigo_externo

                   if @w_return <> 0 
                   begin
                      /*Error en actualizacion de registro */
                       exec cobis..sp_cerror
                         @t_debug = @t_debug,
                         @t_file  = @t_file, 
                         @t_from  = @w_sp_name,
                         @i_num   = 1901012
                       return 1 
                   end
               end
           end 

        /* Cambia de vigente a propuesta */
           if @i_estado = 'P' and @w_estado = 'V' 
           begin
               select @w_contabilizar = tc_contabilizar
               from cu_tipo_custodia
               where tc_tipo = @i_tipo

               if @w_contabilizar = 'S'
               begin
                  --TRANSACCION CONTABLE 
                   exec @w_return = sp_conta
                     @s_date = @s_date,
					 @s_user = @s_user, --Miguel Aldaz 26/Feb/2015
					 @s_term = @s_term, --Miguel Aldaz 26/Feb/2015	
               	     @t_trn = 19300,
         	         @i_operacion = 'I',
					 @i_filial = @i_filial,
					 @i_oficina_orig = @i_oficina_contabiliza,
					 @i_oficina_dest = @i_oficina_contabiliza,
					 @i_tipo = @i_tipo,
					 @i_moneda = @i_moneda,
					 @i_valor = @i_valor_actual,
					 @i_operac = 'D',
					 @i_signo = 1,
                     @i_codigo_externo = @w_codigo_externo

                   if @w_return <> 0 
                   begin
                      /* Error en actualizacion de registro */
                       exec cobis..sp_cerror
                         @t_debug = @t_debug,
                         @t_file  = @t_file, 
                         @t_from  = @w_sp_name,
                         @i_num   = 1901012
                       return 1 
                   end
               end
           end 
       end else  -- Informacion referente a las prendas
        
       update cob_custodia..cu_custodia
       set cu_posee_poliza = @i_posee_poliza,
           cu_fecha_modificacion = @w_today,
           cu_usuario_modifica = @s_user,
           cu_estado_poliza = @i_estado_poliza
       where cu_filial = @i_filial and
             cu_sucursal = @i_sucursal and
             cu_tipo = @i_tipo and
             cu_custodia = @i_custodia

       if @@error <> 0 
       begin
          /* Error en actualizacion de registro */
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1905001
             return 1 
       end

       /* Transaccion de Servicio */
       /***************************/
       insert into ts_custodia
       values (@s_ssn,@t_trn,'P',@s_date,@s_user,@s_term,@s_ofi,'cu_custodia',
         @w_filial,
         @w_sucursal,
         @w_tipo,
         @w_custodia,
         @w_propuesta,
         @w_estado,
         @w_fecha_ingreso,
         @w_valor_inicial,
         @w_valor_actual,
         @w_moneda,
         @w_garante,
         @w_instruccion,
         @w_descripcion,
         @w_poliza,
         @w_inspeccionar,
         @w_motivo_noinsp,
         @w_suficiencia_legal,
         @w_fuente_valor,
         @w_situacion,
         @w_almacenera,
         @w_aseguradora,
         @w_cta_inspeccion,
         @w_direccion_prenda,
         @w_ciudad_prenda,
         @w_telefono_prenda,
         @w_mex_prx_inspec,
         @w_fecha_modif,
         @w_fecha_const,
         @w_porcentaje_valor,
	 @w_periodicidad,
	 @w_depositario,
	 @w_posee_poliza, --U
	 null,
	 null,
	 @w_cobranza_judicial,
	 @w_fecha_retiro,
	 @w_fecha_devolucion,
         @w_fecha_modificacion,
         @w_usuario_crea,
         @w_usuario_modifica,
         @w_estado_poliza,
         @w_cobrar_comision,
         @w_cuenta_dpf,
         @w_abierta_cerrada,
         @w_adecuada_noadec,
         @w_propietario,
         --@w_fsalida_colateral,
         --@w_fretorno_colateral,
         @w_plazo_fijo,
         @w_monto_pfijo,
         @w_oficina_contabiliza,
         @w_compartida,
         @w_valor_compartida,
         @w_fecha_reg,
         @w_fecha_prox_insp, --)
         --II FAE 04/May/2012
         @w_pais,
         @w_provincia,
         @w_canton
         )
         --FI FAE 04/May/2012
	 --@i_fecha_vencimiento)  -- VDA 07/19/2005

       if @@error <> 0 
       begin
          /* Error en insercion de transaccion de servicio */
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
       end

       /* Transaccion de Servicio */
       /***************************/
       insert into ts_custodia
       values (@s_ssn,@t_trn,'A',@s_date,@s_user,@s_term,@s_ofi,'cu_custodia',
         @i_filial,
         @i_sucursal,
         @i_tipo,
         @i_custodia,
         @i_propuesta,
         @i_estado,
         @i_fecha_ingreso,
         @i_valor_inicial,
         @i_valor_actual,
         @i_moneda,
         @i_garante,
         @i_instruccion,
         @i_descripcion,
         @i_poliza,
         @i_inspeccionar,
         @i_motivo_noinsp,
         @i_suficiencia_legal,
         @i_fuente_valor,
         @i_situacion,
         @i_almacenera,
         @i_aseguradora,
         @i_cta_inspeccion,
         @i_direccion_prenda,
         @i_ciudad_prenda,
         @i_telefono_prenda,
         @i_mex_prx_inspec,
         @i_fecha_modif,
         @i_fecha_const,
         @i_porcentaje_valor,
	 @i_periodicidad,
	 @i_depositario,
	 @i_posee_poliza,
	 null,
	 null,
	 @i_cobranza_judicial,
	 @i_fecha_retiro,
	 @i_fecha_devolucion,
         @w_today,
         @w_usuario_crea,
         @s_user,
         @w_estado_poliza,
         @i_cobrar_comision,
         @i_cuenta_dpf,
         @i_abierta_cerrada,
         @i_adecuada_noadec,
         @i_propietario,
         --@i_fsalida_colateral,
         --@i_fretorno_colateral,
         @i_plazo_fijo,
         @i_monto_pfijo,
         @i_oficina_contabiliza,
         @i_compartida,
         @i_valor_compartida,
         @w_fecha_reg,
         @w_fecha_prox_insp, --)
         --II FAE 04/May/2012
         @i_pais,
         @i_provincia,
         @i_canton
         )
         --FI FAE 04/May/2012
	 --@i_fecha_vencimiento) -- VDA 07/19/2005

       if @@error <> 0 
       begin
          /* Error en insercion de transaccion de servicio */
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
       end
  
    commit tran
     
    --PSE 06/19/2009
    select @w_existe_tipo  

    return 0
end


/* Eliminacion de registros */
/****************************/
if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
       /* Registro a eliminar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1907002
        return 1 
    end

    exec sp_riesgos1           -- SE SACAN LOS RIESGOS
    @s_date           = @s_date,
	@s_user	       	  = @s_user, --Miguel Aldaz 26/Feb/2015
	@s_term 		  = @s_term, --Miguel Aldaz 26/Feb/2015	
    @t_trn            = 19604,
    @i_operacion      = 'Q',
    @i_codigo_externo = @w_codigo_externo,
    @o_riesgos        = @w_riesgos out
    
    if @w_riesgos = 'S'       -- EN CASO QUE EXISTAN RIESGOS
    begin
       select @w_error = 1907012
       goto error
    end

    if exists (select * from cu_inspeccion
               where in_tipo_cust = @i_tipo
                 and in_custodia  = @i_custodia)
    begin
       select @w_error = 1907006
       goto error
    end

    if exists (select * from cu_item_custodia
                where ic_tipo_cust = @i_tipo
                  and ic_custodia  = @i_custodia
                  and ic_valor_item <> '')
    begin
       select @w_error = 1907007
       goto error
    end

    if exists (select * from cu_recuperacion
                where re_tipo_cust = @i_tipo
                  and re_custodia  = @i_custodia)
    begin
       select @w_error = 1907008
       goto error
    end

    if exists (select * from cu_transaccion
                where tr_tipo_cust = @i_tipo
                  and tr_custodia  = @i_custodia)
    begin
       select @w_error = 1907009
       goto error
    end

    if exists (select * from cu_vencimiento
                where ve_tipo_cust = @i_tipo
                  and ve_custodia  = @i_custodia)
    begin
       select @w_error = 1907010
       goto error
    end

    if exists (select * from cu_por_inspeccionar
                where pi_tipo      = @i_tipo
                  and pi_custodia  = @i_custodia)
    begin
       select @w_error = 1907011
       goto error
    end

   /***** Integridad Referencial *****/
   /*****                        *****/
   -- CAMBIO EL ESTADO A (E)LIMINADO
   -- ****************************** 
   begin tran
       update cob_custodia..cu_custodia
       set    cu_estado   = @i_estado
       where cu_filial = @i_filial and
             cu_sucursal = @i_sucursal and
             cu_tipo = @i_tipo and
             cu_custodia = @i_custodia

       if @@error <> 0
       begin
          /*Error en eliminacion de registro */
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1907001
             return 1 
       end

       /* Transaccion de Servicio */
       /***************************/
       insert into ts_custodia
       values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_custodia',
         @w_filial,
         @w_sucursal,
         @w_tipo,
         @w_custodia,
         @w_propuesta,
         @w_estado,
         @w_fecha_ingreso,
         @w_valor_inicial,
         @w_valor_actual,
         @w_moneda,
         @w_garante,
         @w_instruccion,
         @w_descripcion,
         @w_poliza,
         @w_inspeccionar,
         @w_motivo_noinsp,
         @w_suficiencia_legal,
         @w_fuente_valor,
         @w_situacion,
         @w_almacenera,
         @w_aseguradora,
         @w_cta_inspeccion,
         @w_direccion_prenda,
         @w_ciudad_prenda,
         @w_telefono_prenda,
         @w_mex_prx_inspec,
         @w_fecha_modif,
         @w_fecha_const,
         @w_porcentaje_valor,
	 @w_periodicidad,
	 @w_depositario,
	 @w_posee_poliza, --D
	 null,
	 null,
	 @w_cobranza_judicial,
	 @w_fecha_retiro,
	 @w_fecha_devolucion,
         @w_fecha_modificacion,
         @w_usuario_crea,
         @w_usuario_modifica,
         @w_estado_poliza,
         @w_cobrar_comision,
         @w_cuenta_dpf,
         @w_abierta_cerrada,
         @w_adecuada_noadec,
         @w_propietario,
         --@w_fsalida_colateral,
         --@w_fretorno_colateral,
         @w_plazo_fijo,
         @w_monto_pfijo,
         @w_oficina_contabiliza,
         @w_compartida,
         @w_valor_compartida,
         @w_fecha_reg,
         @w_fecha_prox_insp, --)
         --II FAE 04/May/2012
         @w_pais,
         @w_provincia,
         @w_canton
         )
         --FI FAE 04/May/2012
	 --@i_fecha_vencimiento)  -- VDA 07/19/2005

       if @@error <> 0 
       begin
          /* Error en insercion de transaccion de servicio */
           exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1903003
             return 1 
       end

       delete cu_cliente_garantia
       where cg_filial    = @i_filial
         and cg_sucursal  = @i_sucursal
         and cg_tipo_cust = @i_tipo
         and cg_custodia  = @i_custodia
         
       delete cob_credito..cr_gar_propuesta
       where gp_garantia = @w_codigo_externo

       --LRE 08/Febrero/2007 Tabla de garantias por facilidad
       delete cob_credito..cr_gar_toperacion
       where gt_garantia = @w_codigo_externo


       delete cu_por_inspeccionar    
       where pi_filial    = @i_filial
         and pi_sucursal  = @i_sucursal
         and pi_tipo      = @i_tipo
         and pi_custodia  = @i_custodia

       delete cu_seqnos
       where se_filial    = @i_filial
         and se_sucursal  = @i_sucursal        
         and se_tipo_cust = @i_tipo
         and se_actual    = @i_custodia 

    commit tran
    return 0
end


/* Consulta opcion QUERY */
/*************************/
if @i_operacion = 'Q'
begin
    if @w_existe = 1
    begin
        /*
         if @w_estado = 'A'
         begin
            /* Error no se puede consultar garantia anulada */
             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1909003
             return 1
         end
       */

         select distinct @w_des_est_custodia = trim(A.valor)
         from cobis..cl_catalogo A,cobis..cl_tabla B
         where B.codigo = A.tabla and
               B.tabla = 'cu_est_custodia' and
               A.codigo = @w_estado

         select @w_des_fuente_valor = A.valor
         from cobis..cl_catalogo A,cobis..cl_tabla B
         where B.codigo = A.tabla and
               B.tabla = 'cu_fuente_valor' and
               A.codigo = @w_fuente_valor

         if @w_inspeccionar = 'N'
         begin
            select @w_des_inspeccionar = 'N'
            select @w_des_motivo_noinsp = A.valor
            from cobis..cl_catalogo A,cobis..cl_tabla B
            where B.codigo = A.tabla and
                  B.tabla = 'cu_motivo_noinspeccion' and
                  A.codigo = @w_motivo_noinsp
         end
         else
         begin
            select @w_des_periodicidad = A.valor
            from cobis..cl_catalogo A,cobis..cl_tabla B
            where B.codigo = A.tabla and
                  B.tabla = 'cu_des_periodicidad' and
                  A.codigo = @w_periodicidad 
         end
         select @w_des_tipo = tc_descripcion
         from cu_tipo_custodia
         where tc_tipo = @w_tipo  

         select @w_des_moneda      = mo_descripcion,
		        @w_simbolo_moneda  = mo_simbolo
         from cobis..cl_moneda
         where mo_moneda = @w_moneda
         
         select @w_des_garante = p_p_apellido + ' ' + p_s_apellido + ' ' + en_nombre
         from cobis..cl_ente
         where en_ente = @w_garante 
       
         
         select @w_cliente = cg_ente,
                @w_des_cliente = cg_nombre
         from cu_cliente_garantia
         where @w_filial = cg_filial
           and @w_sucursal = cg_sucursal
           and @w_tipo = cg_tipo_cust
           and @w_custodia = cg_custodia
           and cg_principal = 'S' -- (S)i

         
         select @w_oficial=convert(varchar(10),fu_funcionario)+'  '+fu_nombre
         from cobis..cc_oficial,cobis..cl_ente,cobis..cl_funcionario,
              cu_cliente_garantia
         where cg_filial      = @i_filial
           and cg_sucursal    = @i_sucursal
           and cg_tipo_cust   = @i_tipo
           and cg_custodia    = @i_custodia
           and cg_ente        = en_ente    
           and cg_principal   = 'S'        
           and en_oficial     = oc_oficial
           and oc_funcionario = fu_funcionario  

	 select @w_des_almacenera = al_nombre
         from cu_almacenera
	 where al_almacenera = @w_almacenera

         select @w_des_aseguradora = A.valor
         from cobis..cl_catalogo A,cobis..cl_tabla B
         where B.codigo = A.tabla and
               B.tabla = 'cu_aseguradora' and
               A.codigo = @w_aseguradora

         select @w_des_estado_poliza = A.valor
         from cobis..cl_catalogo A,cobis..cl_tabla B
         where B.codigo = A.tabla and
               A.codigo = @w_estado_poliza and           
               B.tabla = 'cu_estado_poliza' 

         select @w_des_oficina = of_nombre
         from cobis..cl_oficina
         where of_oficina = @w_oficina_contabiliza
           and of_filial  = @i_filial

         if @i_det_cliente is not null 
         select cg_ente,
                cg_nombre,
                cg_oficial,
                fu_nombre
         from cu_cliente_garantia,cobis..cc_oficial,cobis..cl_funcionario
         where cg_codigo_externo  = @w_codigo_externo
           and oc_oficial         = cg_oficial 
           and oc_funcionario     = fu_funcionario

	--II CMI 29Ene2007
	select @w_fecha_poliza = convert(varchar(10),po_fvigencia_fin, @i_formato_fecha),
	       @w_poliza = po_poliza
          from cob_custodia..cu_poliza
	 where po_codigo_externo = @w_codigo_externo
	group by po_codigo_externo, po_poliza, po_fvigencia_fin
	having po_poliza = max(po_poliza)
	--FI CMI 29Ene2007

	select	@w_desc_pais = pa_descripcion
	  from	cobis..cl_pais
	 where	pa_pais = @w_pais
	
	select	@w_desc_provincia = pv_descripcion
	  from	cobis..cl_provincia
	 where	pv_pais      = @w_pais
	   and	pv_provincia = @w_provincia
	
	/*select	@w_desc_canton = ca_descripcion
	  from	cobis..cl_canton
	 where	ca_provincia = @w_provincia
	   and	ca_canton    = @w_canton*/
	
	--Se agrega esta consulta porque se cambio canton por ciudad
	select @w_desc_canton = ci_descripcion
	from cobis..cl_ciudad
	where ci_provincia = @w_provincia
	and ci_ciudad = @w_canton
	
         select 
              @w_custodia,
              @w_tipo,
              @w_des_tipo,
              convert(char(10),@w_fecha_ingreso,@i_formato_fecha),
              @w_estado,
              @w_des_est_custodia,
              @w_descripcion,
              isnull(convert(varchar(20),@w_garante),NULL),
              @w_des_garante,
              @w_cta_inspeccion,     -- 10
              @w_fuente_valor,
              @w_des_fuente_valor,
              isnull(convert(varchar(20),@w_moneda),''),
              @w_des_moneda,
              @w_valor_inicial,
              @w_valor_actual,
              convert(char(10),@w_fecha_const,@i_formato_fecha),
              @w_instruccion,
              @w_inspeccionar,
              @w_suficiencia_legal,  -- 20
              @w_motivo_noinsp,
              @w_des_motivo_noinsp,
              @w_ciudad_prenda,
              @w_direccion_prenda,
              @w_telefono_prenda,
              isnull(convert(varchar(10),@w_almacenera),NULL),
	      @w_des_almacenera,
	      --@w_posee_poliza,
              convert(varchar(10),@w_fecha_avaluo,@i_formato_fecha),
	      @w_poliza,                  
              @w_aseguradora,        -- 30
 	      @w_des_aseguradora,
              @w_cobranza_judicial,
              convert(varchar(10),@w_fecha_retiro,@i_formato_fecha),
              convert(varchar(10),@w_fecha_devolucion,@i_formato_fecha),
              @w_estado_poliza,
              @w_des_estado_poliza,
              @w_cobrar_comision,
              @w_periodicidad,
              @w_des_periodicidad,
              @w_abr_cer,            -- 40
              @w_cuenta_dpf,
              convert(varchar(10),@w_cliente), -- KDR 19/04/2021 Se quita validación isnull
              @w_des_cliente,
              @w_abierta_cerrada,
              @w_adecuada_noadec,
              @w_oficial,   
              @w_propietario,
              @w_plazo_fijo,
              @w_monto_pfijo,
              @w_depositario,         -- 50      
              @w_oficina_contabiliza,
              @w_des_oficina,
              @w_compartida,
              @w_valor_compartida,
              @w_posee_poliza,
	      convert(char(10),@w_fecha_venc,@i_formato_fecha), -- VDA 07/19/2005
	      @w_pais,
	      @w_provincia,
	      @w_canton,
	      @w_desc_pais,
	      @w_desc_provincia,
	      @w_desc_canton,
		  @w_simbolo_moneda

	      --@w_garantia_seguro  

	      select @w_fecha_poliza
	      
	      --PSE 06/19/2009
	      select @w_existe_tipo
       return 0
    end
    else
        return 1 
end

if @i_operacion = 'F'
begin

   ---Porcentaje IVA
   select @w_iva = pa_float
     from cobis..cl_parametro
    where pa_nemonico = 'IVA'
      and pa_producto = 'GAR'

   ---Porcentaje Ret.IVA
   select @w_riva = pa_float
     from cobis..cl_parametro
    where pa_nemonico = 'RIVA'
      and pa_producto = 'GAR'

   ---Porcentaje Ret.Fuente
   select @w_rfte = pa_float
     from cobis..cl_parametro
    where pa_nemonico = 'RFTE'
      and pa_producto = 'GAR'

   select @w_today,
          @s_date,
          mo_descripcion,
	  mo_moneda,
          convert(varchar(10),@s_date,@i_formato_fecha), ---GCR
          isnull(@w_iva,0), ---GCR
          isnull(@w_riva,0), ---GCR
          isnull(@w_rfte,0) ---GCR
   from cobis..cl_moneda, cobis..cl_parametro
   where mo_moneda = pa_tinyint
   and pa_nemonico = 'MLOCR'
   and pa_producto = 'CRE'

end

return 0
error:    /* Rutina que dispara sp_cerror dado el codigo de error */

             exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = @w_error
             return 1
go
