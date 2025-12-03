/********************************************************************/
/*    NOMBRE LOGICO:         sp_tanqueo_fact_elec                   */
/*    NOMBRE FISICO:         sp_tanqueo_dte.sp                      */
/*    PRODUCTO:              Facturacion Electronica                */
/*    Disenado por:          Armando Quishpe                        */
/*    Fecha de escritura:    31-Marzo-2023                          */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.".         */
/********************************************************************/
/*                           PROPOSITO                              */
/* Sp que permite el tanque de datos que se utilizan en la          */
/* facturacion electronica                                          */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA              AUTOR              RAZON                     */
/*  31-Mar-2023      A. Quishpe       Emision Inicial               */
/*  25-AGO-2023      A. Quishpe       FEC-B889594-ENL Máscara NIT   */
/*  07-SEP-2023      A. Quishpe       RDM 214869 Manejo de transac  */
/*  04-DIC-2023      A. Quishpe       RDM 220648 Se mejora consultas*/
/*                                    a catalgos y control bloqueos */
/*  16-OCT-2024      G. Chulde        RM 246721                     */
/*  06-NOV-2024      G. Chulde        RM 248653 CC                  */
/********************************************************************/
use cob_externos
go

if exists (select * from sysobjects where name = 'sp_tanqueo_fact_elec')
   drop proc sp_tanqueo_fact_elec
go

create proc sp_tanqueo_fact_elec(
    @s_ssn                int         = null,
    @s_user               login       = null,
    @s_term               varchar(30) = null,
    @s_date               datetime    = null,
    @s_srv                varchar(30) = null,
    @s_lsrv               varchar(30) = null,
    @s_rol                smallint    = null,
    @s_ofi                smallint    = null,
    @s_org_err            char(1)     = null,
    @s_error              int         = null,
    @s_sev                tinyint     = null,
    @s_msg                descripcion = null,
    @s_org                char(1)     = null,
    @t_debug              char(1)     = 'N',
    @t_file               varchar(10) = null,
    @t_from               varchar(32) = null,
    @t_rty                char(1)     = 'N',
    @t_trn	    	      int,
	@t_show_version       bit         = 0,
	@i_operacion          char(1),
	--identificacion
	@i_ide_tipo_dte       varchar(30),
	-- receptor
	@i_rec_ente           int,
	-- cuerpo documento
	@i_det_registro1      varchar(max) = null,
	@i_det_registro2      varchar(max) = null,
	@i_det_registro3      varchar(max) = null,
	@i_det_registro4      varchar(max) = null,
	@i_det_registro5      varchar(max) = null,
	@i_det_registro6      varchar(max) = null,
	@i_det_registro7      varchar(max) = null,
	@i_det_registro8      varchar(max) = null,
	@i_det_registro9      varchar(max) = null,
	@i_det_registro10     varchar(max) = null,
	@i_det_registro11     varchar(max) = null,
	@i_det_registro12     varchar(max) = null,
	@i_det_registro13     varchar(max) = null,
	@i_det_registro14     varchar(max) = null,
	@i_det_registro15     varchar(max) = null,
	--apendice
	@i_ape_registro1      varchar(255) = null,
	@i_ape_registro2      varchar(255) = null,
	@i_ape_registro3      varchar(255) = null,
	@i_ape_registro4      varchar(255) = null,
	@i_ape_registro5      varchar(255) = null,
	@i_ape_registro6      varchar(255) = null,
	@i_ape_registro7      varchar(255) = null,
	@i_ape_registro8      varchar(255) = null,
	@i_ape_registro9      varchar(255) = null,
	@i_ape_registro10     varchar(255) = null,
	-- venta tercero
	@i_ven_tercero        char(1),
	@i_ven_ter_ente       int          = null,
	-- documento relacionado
	@t_corr               char(1)      = 'N',
	@t_ssn_corr           int          = null,
	@t_fecha_ssn_corr     datetime     = null,
	@t_guid_corr          varchar(36)  = null,
	-- REQUERIMIETO	
	@i_ope_banco          cuenta,
	@i_prd_cobis          tinyint,
	-- TRANSACCIONALIDAD
	@i_externo            char(1)      = 'N',
	 -- RETORNO
    @o_ssn                int out,
    @o_fecha_registro     datetime out,
	@o_guid               varchar(36) out,
	@o_ejecutar_orq       varchar(3) out
	
)
as
declare @w_return                      int,
        @w_sp_name                     varchar(32),
        -- IDENTIFICACION              
        @w_ide_version                 int,
        @w_ide_ambiente                varchar(2),
        @w_ide_numero_control          varchar(32),
        @w_ide_codigo_generacion       varchar(36),
        @w_ide_tipo_modelo             int = 1,
        @w_ide_tipo_operacion          int = 1,
        @w_ide_tipo_contingencia       int = null,
        @w_ide_motivo_contin           varchar(500)  = null,
        @w_ide_fec_emi                 varchar(10),
        @w_ide_hora_emi                varchar(8),
        @w_ide_tipo_moneda             varchar(3)    = 'USD',
        -- EMISOR                      
        @w_emi_nit                     varchar(30),
        @w_emi_nrc                     varchar(8),
        @w_emi_nombre                  varchar(250),
        @w_emi_cod_actividad           varchar(6),
        @w_emi_desc_actividad          varchar(150),
        @w_emi_nombre_comercial        varchar(150),
        @w_emi_tipo_establecimiento    varchar(2) = '01',
        --@w_emi_direccion               varchar(200),
        @w_emi_departamento            varchar(2),
        @w_emi_municipio               varchar(2),
        @w_emi_complemento             varchar(200),
        @w_emi_telefono                varchar(30),
        @w_emi_correo                  varchar(100),
        @w_emi_cod_estable_mh          varchar(4)    = null,
        @w_emi_cod_estable             varchar(4)    = null,
        @w_emi_punto_venta_mh          varchar(4)    = null,
        @w_emi_punto_venta             varchar(15)   = null,
        -- RECEPTOR                    
        @w_rec_tipo_documento	       char(2),
        @w_rec_num_documento	       varchar(20),
        @w_rec_nrc	                   varchar(8),
        @w_rec_nombre	               varchar(250),
        @w_rec_cod_actividad	       varchar(6),
        @w_rec_desc_actividad	       varchar(150),
        @w_rec_nombre_comercial	       varchar(150),
        --@w_rec_direccion	           varchar(200),
        @w_rec_departamento	           varchar(2),
        @w_rec_municipio	           varchar(2),
        @w_rec_complemento	           varchar(200),
        @w_rec_telefono	               varchar(30),
        @w_rec_correo	               varchar(100),
		-- CUERPO DOCUMENTO            
        --@w_det_num_item	               int,
        @w_det_tipo_item	           varchar(1)    = 2,
        @w_det_numero_documento	       varchar(36)   = null,
        @w_det_cantidad	               int           = 1,
        @w_det_codigo	               varchar(25),
        @w_det_cod_tributo	           varchar(2)    = null, --20 si es gravado,
        @w_det_uni_medida	           int           = 59,
        @w_det_descripcion	           varchar(max),
        @w_det_precio_uni	           money         = 0,
        @w_det_monto_descu	           money         = 0, -- validar null
        @w_det_venta_no_suj	           money         = 0,
        @w_det_venta_exenta	           money         = 0, -- similar a presio unitario
        @w_det_venta_gravada           money         = 0,
        @w_det_tributos	               varchar(2)    = null,
        @w_det_items	               varchar(2)    = null,
        @w_det_psv	                   money         = 0,
        @w_det_no_gravado	           money         = 0,
        @w_det_iva_item	               money         = 0,
		-- RESUMEN                     
        @w_res_total_no_suj            money         = 0,
        @w_res_total_exenta            money         = 0,
        @w_res_total_gravada	       money         = 0,
        @w_res_sub_total_ventas	       money         = 0,
        @w_res_descu_no_suj	           money         = 0,
        @w_res_descu_exenta	           money         = 0,
        @w_res_descu_gravada	       money         = 0,
        @w_res_porcentaje_descuento	   money         = 0,
        @w_res_total_descu	           money         = 0,
        @w_res_tributos                varchar(2),
        @w_res_codigo	               varchar,
        @w_res_descripcion	           varchar,
        @w_res_valor	               money         = 0,
        @w_res_sub_total	           money         = 0,
        @w_res_iva_perci_1	           money         = null,
        @w_res_iva_rete_1	           money         = 0,
        @w_res_rete_renta	           money         = 0,
        @w_res_monto_total_operacion   money         = 0,
        @w_res_total_no_gravado	       money         = 0,
        @w_res_total_pagar	           money         = 0,
        @w_res_total_letras	           varchar(200),
        @w_res_total_iva	           money         = 0,
        @w_res_saldo_favor	           money         = 0,
        @w_res_condicion_operacion	   int           = 1,
        --@w_res_pagos                 
        @w_res_pagos_codigo            varchar(2)    = null,
        @w_res_pagos_monto_pago        money         = null,
        @w_res_pagos_referencia        varchar(50)   = null,
        @w_res_pagos_plazo             varchar(2)    = null,
        @w_res_pagos_periodo           int           = null,
        @w_res_num_pago_electronico    varchar(100)  = null,
		-- EXTENSION                   
        @w_ext_nomb_entrega	           varchar(100),
        @w_ext_docu_entrega	           varchar(25),
        @w_ext_nomb_recibe	           varchar(100),
        @w_ext_docu_recibe	           varchar(25),
        @w_ext_observaciones	       varchar(max)  =  null,
		-- APENDICE                    
        @w_ape_campo	               varchar(25),
        @w_ape_etiqueta	               varchar(50),
        @w_ape_valor	               varchar(150),
		-- VENTA TERCERO               
        @w_ven_nit	                   varchar(14),
        @w_ven_nombre	               varchar(250),
		-- DOCUMENTO RELACIONADO       
        @w_doc_tipo_documento	       varchar(2)    = '03',
        @w_doc_tipo_generacion	       int           = 2,
        @w_doc_numero_documento	       varchar(36),
        @w_doc_fecha_emision	       varchar(10),
		-- OTROS DOCUMENTOS            
        @w_otros_documentos	           varchar(250),
		-- REQUERIMIENTOS
        @w_req_sello_recibido          varchar(50)   = null,
        @w_req_monto                   money, -- total pagar
        @w_req_estado                  varchar(10), --  catalogo I --> CUANDO SE ANULA PONER ESTADO PROCESO ANULACION (PA) registro origina y nuevo de reverso
        @w_req_num_reenvio             tinyint       = 0, -- 0
        @w_req_num_impresion           tinyint       = 0, -- 0
        --@w_req_fecha_envio             datetime      = null, -- null
        @w_req_fecha_procesamiento     varchar(20), -- getDate
        @w_req_clasifica_msg           varchar(5)    = null,-- null
        @w_req_codigo_msg              varchar(2)    = null,-- null
        @w_req_descripcion_msg         varchar(150)  = null,--null
        @w_req_observaciones           varchar(255)  = null,--null
        @w_req_version                 tinyint, -- version ide
        @w_req_ambiente                varchar(2), -- ambiente ide CAMBIAR A varchar 2
        @w_req_version_app             tinyint       = 0, --
        @w_req_usuario                 varchar(50)   = @s_user, -- s_user
        @w_req_terminal                varchar(50)   = @s_term, --s_term
        @w_req_correccion              char(1)       = @t_corr, -- N cuando es normal, S cuando es reverso
        @w_req_estado_correccion       char(1)       = null, -- null  si es reverso va a R y se actualiza a R el registro original - ademas actualizar el campo estado a INVALIDADO/SUSTITUIDO
        @w_req_ssn_correccion          int           = @t_ssn_corr, -- null
		@w_req_fecha_ssn_corr          datetime      = @t_fecha_ssn_corr, -- crear en la tabla
		-- ANULACION                   
		-- DOCUMENTO                   
		@w_anu_doc_tipo_dte            varchar(2),
        @w_anu_doc_codigo_generacion   varchar(36),
        @w_anu_doc_sello_recibido      varchar(255),
        @w_anu_doc_numero_control      varchar(31),
        @w_anu_doc_fec_emi             varchar(10),
        @w_anu_doc_monto_iva           money         = 0,
        @w_anu_doc_codigo_Generacion_r varchar(10)   = null,
        @w_anu_doc_tipo_documento      varchar(2),
        @w_anu_doc_num_documento       varchar(20),  
        @w_anu_doc_nombre              varchar(250),
        @w_anu_doc_telefono            varchar(30),
        @w_anu_doc_correo              varchar(100),
		-- MOTIVO
		@w_anu_mot_tipo_anulacion      int = 2,
        @w_anu_mot_motivo_anulacion    varchar(250),
        @w_anu_mot_nombre_responsable  varchar(100),
        @w_anu_mot_tip_doc_responsable varchar(2),
        @w_anu_mot_num_doc_responsable varchar(20),
        @w_anu_mot_nombre_solicita     varchar(100),
        @w_anu_mot_tip_doc_solicita    varchar(2),
        @w_anu_mot_num_doc_solicita    varchar(20),
		-- GENERALES
		@w_id_ente_enl                 int,
		@w_aux_registro                varchar(max),
		@w_contador                    int,
		@w_det_exento                  char(1),
		@w_param_ambiente              varchar(25),
		@w_aux_version                 varchar(3),
		@w_fecha_proceso               datetime,
		@w_aux_fecha_enviada           datetime, 
        @w_diferencia_tiempo           int = 0,
		@w_aux_ssn                     varchar(15),
		@w_tipo_ofi                    varchar(4),
		@w_ofi_matriz                  smallint,
		@w_mont_max                    money,
		@w_aux_ofi                     varchar(8),
		@w_aux_rec_tipo_docu           varchar(5),
		@w_aux_departamento            int           = null,
		@w_aux_municipio               int           = null,
		@w_aux_parroquia               int           = null,
		@w_parroquia                   varchar(100)  = null,
		@w_aux_direccion               varchar(200)  = null,
		@w_aux_cod_actividad           varchar(10)   = null,
		@w_aux_estado_orig             varchar(3)    = null,
		@w_aux_ejec_orq                varchar(3)    = 'S',
		@w_aux_seguro                  varchar(3)    = 'N',
		@w_aux_corr_orig               varchar(3)    = 'N',
		@w_aux_estado_corr_orig        varchar(3)    = null,
		@w_fecha_actual                datetime      = getdate(),
		@w_hora_deseada                TIME          = '23:59',
		@w_fecha_limite_nrc            datetime,
		@w_horas_diferencia            DECIMAL(10, 2),
		@w_dato_adicion_ncr            smallint,
        @w_dato_adicion_act_hac        smallint,
		@w_tanquear_invalidacion_ccf   char(1)       = 'N',
		@w_plazo_anula_fcf             int           = 90,
		@w_dato_adicion_nrc_j          smallint,
		@w_tipo_persona                char(1),
		@w_dato_adicion_nrc            smallint,
		@w_anio_control                smallint



select @w_sp_name = 'sp_tanqueo_fact_elec',
       @w_return  = 0

    ---- VERSIONAMIENTO DEL PROGRAMA ----
    if @t_show_version = 1
    begin
        print 'Stored procedure Version 5.0.0.2' + @w_sp_name
        return 0
    end
   
    /* Solo la transaccion tanqueo**/
    if @t_trn != 172230
    begin
        exec cobis..sp_cerror
            @t_from = @w_sp_name,
            @i_num  = 2609995,
            @i_sev  = 0
        return 2609995
    end
   
/*LOGICA NEGOCIO*/
if @i_operacion = 'I'
begin
    if @i_externo = 'S'
    begin tran /*si existd error enviar severidad 1  @@trancount > 0  rollback tran*/
    

        -- fecha proceso
        select @w_fecha_proceso = fp_fecha
        from cobis..ba_fecha_proceso
		
	    /*RECUPERACION DE DATOS INTERNOS*/
	    begin tran
	    select @w_anio_control = as_anio_control from cob_externos..ex_dte_anio_sec
	    
	    if @w_anio_control < datepart(yyyy,@w_fecha_proceso)
	    begin
	    	update cob_externos..ex_dte_anio_sec set 
	    	as_anio_control =  datepart(yyyy,@w_fecha_proceso),
	    	as_hora_upd		=  getdate()
	    	
			update cobis..cl_seqnos
	    		set siguiente = 0
	    		where tabla in ('ex_dte_identificacion_fcf', 'ex_dte_identificacion_ccf')
	    end
        commit tran
				
        -- PARAMETROS GENERALES
		
        select @w_id_ente_enl = pa_int from cobis..cl_parametro with (nolock)
        where pa_nemonico = 'EMIDTE' and pa_producto = 'CLI'
        
        select @w_dato_adicion_ncr = pa_smallint from cobis..cl_parametro with (nolock)
        where pa_nemonico = 'DADNRC' and pa_producto = 'CLI'
        
        select @w_dato_adicion_act_hac = pa_smallint from cobis..cl_parametro with (nolock)
        where pa_nemonico = 'DADACH' and pa_producto = 'CLI'
		
		select @w_dato_adicion_nrc_j = pa_smallint from cobis..cl_parametro with (nolock)
        where pa_nemonico = 'DANRCJ' and pa_producto = 'CLI'
		
		select @w_plazo_anula_fcf  = pa_int from cobis..cl_parametro with (nolock)
        where pa_nemonico = 'PANFCF' and pa_producto = 'CLI'
        
                
        if (@t_corr = 'S')
        begin
            if (@w_req_ssn_correccion is null and @t_guid_corr IS NOT null)
            begin
                select @w_req_ssn_correccion = di_cod_secuencial 
                from cob_externos..ex_dte_identificacion with (nolock)
                where di_cod_generacion = @t_guid_corr and di_fecha_proceso = @w_req_fecha_ssn_corr
        	end
            
            select @w_req_estado_correccion = 'R'
        	select @w_aux_fecha_enviada    = dq_fecha_envio,
                   @w_aux_estado_orig      = dq_estado,
        		   @w_aux_corr_orig        = dq_correccion,
        		   @w_aux_estado_corr_orig = dq_estado_correccion
            from cob_externos..ex_dte_requerimiento with (nolock)
            where dq_ssn = @w_req_ssn_correccion and dq_fecha_proceso = @w_req_fecha_ssn_corr
        	
        	-- SE VALIDA EL ESTADO DEL DTE ORIGINAL
        	if (@w_aux_estado_orig <> 'G' and @w_aux_corr_orig = 'N' and @w_aux_estado_corr_orig is null)
            begin
        	    select @w_aux_ejec_orq = 'N'
        		-- actualizar corre S y estado corr R 
        		update cob_externos..ex_dte_requerimiento
        		set dq_correccion        = @t_corr,
        		    dq_estado_correccion = @w_req_estado_correccion
        		where dq_ssn = @w_req_ssn_correccion and dq_fecha_proceso = @w_req_fecha_ssn_corr
        		
        		select @o_ejecutar_orq = @w_aux_ejec_orq,
        	           @w_return = 1720647 -- No se anula un DTE sino se ha generado
        		goto SALIR 
        	end
            else
        	begin
        	    select @w_aux_ejec_orq = 'S'
        	end
        	
        	if (@i_ide_tipo_dte = '03')
            begin
                select @w_fecha_limite_nrc = CAST(convert(varchar(10), DATEADD(DAY, 1, @w_aux_fecha_enviada), 120) AS datetime) + CAST(@w_hora_deseada AS datetime)
				if (@w_fecha_actual > @w_fecha_limite_nrc)
        	    begin
				    select @w_tanquear_invalidacion_ccf = 'N'
        	        select  @i_ide_tipo_dte    = '05',
        	                @w_req_correccion  = 'N'
        	    end
        		else
        		begin
				    select @w_tanquear_invalidacion_ccf = 'S'
        		end
        		
            end
            if (@i_ide_tipo_dte = '01')
            begin	
                select @w_diferencia_tiempo = datediff(DAY, @w_aux_fecha_enviada, @w_fecha_actual)
        	    if @w_diferencia_tiempo > @w_plazo_anula_fcf --dias
        	    begin
					select @w_return = 1720643 --Fuera de plazo para invalidar una factura consumidor final
					goto ERROR
        	    end
            end	
        end
        -- IDENTIFICACION	
        select @w_aux_version = case @i_ide_tipo_dte when '01' then 'FC' 
                                                     when '05' then 'NC'
        							                 when '03' then 'CCF' end
        --select @w_ide_version = valor from cobis..cl_catalogo where codigo = @w_aux_version
        --and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_fac_dte_version')
        select @w_ide_version = c.valor from cobis..cl_catalogo c, cobis..cl_tabla t
        where t.tabla = 'cl_fac_dte_version' and c.codigo = @w_aux_version and c.tabla = t.codigo 
        
        -- ambiente destino
        select @w_param_ambiente = case pa_char when 'TEST' then 'Modo Prueba'
                                                when 'PRD' then 'Modo Producción' end
        from cobis..cl_parametro with (nolock)
        where pa_nemonico = 'AMDEST' and pa_producto = 'CLI'
        
        --select @w_ide_ambiente = codigo from cobis..cl_catalogo where valor = @w_param_ambiente
        --and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_fac_ambiente_destino')
        select @w_ide_ambiente = c.codigo from cobis..cl_catalogo c, cobis..cl_tabla t 
        where t.tabla = 'cl_fac_ambiente_destino' and c.valor = @w_param_ambiente and c.tabla = t.codigo
        
		-- codigo generacion
        EXEC cob_externos..sp_guid_fe
            @o_guid = @w_ide_codigo_generacion OUT
        -- fecha generacion YYYY- MM-DD        
        select @w_ide_fec_emi = convert(varchar, @w_fecha_actual, 23) -- fecha proceso?
        -- hora generacion HH:MM:SS
        select @w_ide_hora_emi = convert(varchar,@w_fecha_actual,108)
            
        -- EMISOR
        -- nit, nombre, cod_actividad, nombre lar, cod direccion, cod provincia, cod ciudad
        select 
            @w_emi_nit              = en_nit,
            @w_emi_nombre           = en_nombre, 
            -- @w_aux_cod_actividad    = en_actividad, 
            @w_emi_nombre_comercial = en_nomlar,
			@w_tipo_persona         = en_subtipo -- Tipo persona [Natutal(P), Jurídica(C)]
        from cobis..cl_ente with (nolock)
        where en_ente  = @w_id_ente_enl
        -- nit sin guiones
		select @w_emi_nit = dbo.fn_get_numeros_fec(@w_emi_nit)
		-- nrc	  
	    -- Asignaci+on ID de dato adicional dependiendo de si el ente es Persona Natural o Jurídica
        select @w_dato_adicion_nrc = case when @w_tipo_persona = 'P' 
                                        then @w_dato_adicion_ncr 
                                        else @w_dato_adicion_nrc_j end
        --select TOP 1 @w_emi_nrc = ie_numero from cobis..cl_ident_ente where ie_ente = @w_id_ente_enl and ie_tipo_doc = 'NIT'
        select @w_emi_nrc = de_valor from cobis..cl_dadicion_ente with (nolock)
        where de_ente = @w_id_ente_enl and de_dato = @w_dato_adicion_nrc
        
        -- direccion
        select
            @w_aux_departamento = di_provincia,
            @w_aux_municipio    = di_ciudad,
            @w_aux_parroquia    = di_parroquia,
            @w_aux_direccion    = di_calle + ' y ' + di_casa + ', N° ' + di_numero_casa + ', ' + di_descripcion 
        from cobis..cl_direccion with (nolock)
        where di_principal = 'S' and di_ente = @w_id_ente_enl
        if @@rowcount = 0
        begin
            select
                @w_aux_departamento = di_provincia,
                @w_aux_municipio    = di_ciudad,
                @w_aux_parroquia    = di_parroquia,
                @w_aux_direccion    = di_calle + ' y ' + di_casa + ', N° ' + di_numero_casa + ', ' + di_descripcion 
            from cobis..cl_direccion with (nolock)
            where di_tipo <> 'CE' and di_ente = @w_id_ente_enl order by di_direccion desc
        end
        
        select @w_emi_departamento = dbo.fn_homologa_fec ('cl_provincia', @w_aux_departamento)
        select @w_emi_municipio =  SUBSTRING(dbo.fn_homologa_fec ('cl_ciudad', @w_aux_municipio),3,4)
        select @w_parroquia = pq_descripcion from cobis..cl_parroquia where pq_parroquia = @w_aux_parroquia

        select @w_emi_complemento = @w_aux_direccion + ', ' + isnull(@w_parroquia,'')
        
        -- telefono
        select @w_emi_telefono = te_valor from cobis..cl_telefono with (nolock)
        where te_tipo_telefono = 'D' and te_ente = @w_id_ente_enl
        if @@rowcount = 0 or @w_emi_telefono is null
        begin
            select @w_emi_telefono = te_valor from cobis..cl_telefono with (nolock)
            where te_ente = @w_id_ente_enl order by te_secuencial desc
        end
        -- correo
        select @w_emi_correo = di_descripcion from cobis..cl_direccion with (nolock)
        where di_ente = @w_id_ente_enl and di_tipo = 'CE'
        /* actividad economica de ENL*/
        -- select @w_emi_cod_actividad = dbo.fn_homologa_fec ('cl_subactividad_ec', @w_aux_cod_actividad)
        select @w_emi_cod_actividad = de_valor from cobis..cl_dadicion_ente with (nolock)
        where de_ente = @w_id_ente_enl and de_dato = @w_dato_adicion_act_hac
        
        --select @w_emi_desc_actividad = valor from cobis..cl_catalogo where codigo = @w_emi_cod_actividad -- TO DO: cambiar la forma de llamar
        --and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_actividad_mh')--cl_fac_codigo_actividad_econo
        select @w_emi_desc_actividad = c.valor from cobis..cl_catalogo c, cobis..cl_tabla t
        where c.codigo = @w_emi_cod_actividad AND t.tabla = 'cl_actividad_mh' and c.tabla = t.codigo
        
        -- RECEPTOR
        -- tipo doc, numero documento, nombre
        select @w_aux_cod_actividad  = null
        select 
            @w_aux_rec_tipo_docu  = en_tipo_ced, 
            @w_rec_num_documento  = case @i_ide_tipo_dte 
			                        when '01' then en_ced_ruc
									when '03' then en_nit
									when '05' then en_nit
									else null end,
            @w_rec_nombre         = en_nomlar,
            -- @w_aux_cod_actividad  = en_actividad,
            @w_ext_docu_recibe    = en_ced_ruc,
            @w_ext_nomb_recibe    = en_nomlar,
			@w_tipo_persona       = en_subtipo -- Tipo persona [Natutal(P), Jurídica(C)]
        from cobis..cl_ente with (nolock)
        where en_ente = @i_rec_ente
        -- tipo documento
        --select @w_rec_tipo_documento = codigo from cobis..cl_catalogo where valor = @w_aux_rec_tipo_docu 
        --and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_fac_tipo_doc_ident_recep')
		
		select @w_rec_tipo_documento = c.codigo from cobis..cl_tabla t, cobis..cl_catalogo c 
		where t.tabla = 'cl_fac_tipo_doc_ident_recep' and c.tabla = t.codigo 
		and c.valor = (select ca.valor from cobis..cl_tabla ta, cobis..cl_catalogo ca where ta.tabla = 'cl_tipo_doc_ident_recep_fec'
                        and ca.tabla = ta.codigo and ca.codigo = @w_aux_rec_tipo_docu)
				
        
        /*para CCF*/
		if @w_rec_num_documento is null
		begin
            select @w_return = 1720648
            goto ERROR
		end
		
        if (@i_ide_tipo_dte = '03' OR @i_ide_tipo_dte = '05')
        begin
            -- se elimina guion se re
        	select @w_rec_num_documento = dbo.fn_get_numeros_fec(@w_rec_num_documento)
            -- nrc			
		    -- Asignaci+on ID de dato adicional dependiendo de si el ente es Persona Natural o Jurídica
            select @w_dato_adicion_nrc = case when @w_tipo_persona = 'P' 
                                        then @w_dato_adicion_ncr 
                                        else @w_dato_adicion_nrc_j end
            -- select TOP 1 @w_rec_nrc = ie_numero from cobis..cl_ident_ente where ie_ente = @i_rec_ente and ie_tipo_doc = 'NRC'
        	select @w_rec_nrc = de_valor from cobis..cl_dadicion_ente with (nolock)
            where de_ente = @i_rec_ente and de_dato = @w_dato_adicion_nrc
        end
        
        -- direccion
        select @w_aux_departamento = null
        select @w_aux_municipio    = null
        select @w_aux_direccion    = null
        select
            @w_aux_departamento = di_provincia,
            @w_aux_municipio    = di_ciudad,
            @w_aux_parroquia    = di_parroquia,
            @w_aux_direccion    = di_calle + ' y ' + di_casa + ', N° ' + di_numero_casa + ', ' + di_descripcion 
        from cobis..cl_direccion with (nolock)
        where di_principal = 'S' and di_ente = @i_rec_ente
        if @@rowcount = 0
        begin
            select
                @w_aux_departamento = di_provincia,
                @w_aux_municipio    = di_ciudad,
                @w_aux_parroquia    = di_parroquia,
                @w_aux_direccion    = di_calle + ' y ' + di_casa + ', N° ' + di_numero_casa + ', ' + di_descripcion 
            from cobis..cl_direccion with (nolock)
            where di_tipo <> 'CE' and di_ente = @i_rec_ente order by di_direccion desc
        end
        
        -- homologacion depa, muni
        select @w_rec_departamento = dbo.fn_homologa_fec ('cl_provincia', @w_aux_departamento)
        select @w_rec_municipio = SUBSTRING(dbo.fn_homologa_fec ('cl_ciudad', @w_aux_municipio),3,4)
        select @w_parroquia = pq_descripcion from cobis..cl_parroquia where pq_parroquia = @w_aux_parroquia
        
        select @w_rec_complemento = @w_aux_direccion + ', ' + isnull(@w_parroquia,'')

        -- telefono
        select @w_rec_telefono = ea_telef_recados from cobis..cl_ente_aux with (nolock)
		where ea_ente = @i_rec_ente
		if @@rowcount = 0 or @w_rec_telefono is null
		begin
		    select @w_rec_telefono = te_valor from cobis..cl_telefono with (nolock)
            where te_tipo_telefono = 'D' and te_ente = @i_rec_ente
            if @@rowcount = 0 or @w_rec_telefono is null
            begin
                select @w_rec_telefono = te_valor from cobis..cl_telefono with (nolock)
                where te_ente = @i_rec_ente order by te_secuencial desc
            end
		end
        -- correo
        select @w_rec_correo = di_descripcion from cobis..cl_direccion with (nolock)
        where di_ente = @i_rec_ente and di_tipo = 'CE'
        /* actividad economica*/
        --select @w_rec_cod_actividad = dbo.fn_homologa_fec ('cl_subactividad_ec', @w_aux_cod_actividad)
        select @w_rec_cod_actividad = de_valor from cobis..cl_dadicion_ente with (nolock)
            where de_ente = @i_rec_ente and de_dato = @w_dato_adicion_act_hac

        if ((@i_ide_tipo_dte = '03' OR @i_ide_tipo_dte = '05') and (@w_rec_cod_actividad = null or @w_rec_cod_actividad = ''))
        begin
			select @w_return = 1720059  -- NO EXISTE ACTIVIDAD ECONOMICA
			goto ERROR
        end
        else if (@i_ide_tipo_dte = '01' and (@w_rec_cod_actividad = null or @w_rec_cod_actividad = ''))
        begin
            select @w_rec_cod_actividad = null,
        	       @w_rec_desc_actividad = null
        end
        else
        begin
            --select @w_rec_desc_actividad = valor from cobis..cl_catalogo where codigo = @w_rec_cod_actividad --TODO CMABIAR
            --and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_actividad_mh')--cl_fac_codigo_actividad_econo
            select @w_rec_desc_actividad = c.valor from cobis..cl_catalogo c, cobis..cl_tabla t
            where c.codigo = @w_rec_cod_actividad AND t.tabla = 'cl_actividad_mh' and c.tabla = t.codigo				

			if (@i_ide_tipo_dte = '01' and (@w_rec_desc_actividad = null or @w_rec_desc_actividad = ''))
			begin
			    select @w_rec_cod_actividad = null,
        	           @w_rec_desc_actividad = null
			end
			else if ((@i_ide_tipo_dte = '03' OR @i_ide_tipo_dte = '05') and (@w_rec_desc_actividad = null or @w_rec_desc_actividad = ''))
            begin
				select @w_return = 1720059  -- NO EXISTE ACTIVIDAD ECONOMICA
			    goto ERROR
            end			
        end
        		
        -- EXTENSION
        select @w_ext_nomb_entrega =  pa_char from cobis..cl_parametro with (nolock)
        where pa_nemonico = 'NOREFE' and pa_producto = 'CLI'
        select @w_ext_docu_entrega =  pa_char from cobis..cl_parametro with (nolock)
        where pa_nemonico = 'NIDEFE' and pa_producto = 'CLI'
        -- VENTA TERCERO
        if @i_ven_tercero = 'S' 
        begin
            select @w_ven_nit     = pa_char from cobis..cl_parametro with (nolock)
            where pa_nemonico = 'NITSEG' and pa_producto = 'CLI'
            select @w_ven_nombre  = pa_char from cobis..cl_parametro with (nolock)
            where pa_nemonico = 'NOMSEG' and pa_producto = 'CRE'
        end

		if (@w_req_correccion = 'N')
		begin
		    if @i_ide_tipo_dte = '05'
			begin
			    select  @w_doc_numero_documento = di_cod_generacion		
                from cob_externos..ex_dte_identificacion with (nolock)
                where di_cod_secuencial = @t_ssn_corr and di_fecha_proceso = @t_fecha_ssn_corr
				 
		        insert into cob_externos..ex_dte_detalle (dd_cod_secuencial, dd_fecha_proceso, dd_num_item, dd_tipo_item, dd_num_documento, dd_cantidad, dd_codigo, dd_cod_tributo, dd_uni_medida, dd_descripcion, dd_precio_unitario, dd_descuento, dd_venta_nosujeta, dd_venta_exenta, dd_venta_gravada, dd_tributos, dd_psv, dd_no_gravado, dd_iva_item)
                select @s_ssn, @w_fecha_proceso, dd_num_item, dd_tipo_item, @w_doc_numero_documento, dd_cantidad, dd_codigo, dd_cod_tributo, dd_uni_medida, dd_descripcion, dd_precio_unitario, dd_descuento, dd_venta_nosujeta, dd_venta_exenta, dd_venta_gravada, dd_tributos, dd_psv, dd_no_gravado, dd_iva_item
                from cob_externos..ex_dte_detalle where dd_cod_secuencial = @t_ssn_corr and dd_fecha_proceso = @t_fecha_ssn_corr
				if @@error <> 0
			    begin
					select @w_return = 710030 -- Error al insertar informacion de la transaccion
					goto ERROR
			    end
		    end
		    else
	        begin
	            DECLARE @aux_det_precio_uni    varchar(max) = null,
			    		@aux_det_iva_item      varchar(max) = null,
			    		@aux_det_venta_no_suj  varchar(max) = null,
			    		@aux_det_venta_exenta  varchar(max) = null,
			    		@aux_det_venta_gravada varchar(max) = null,
			    		@aux_det_no_gravado    varchar(max) = null
                -- CUERPO DOCUMENTO
                select @w_contador = 1;
                WHILE @w_contador <= 15
                begin
                    select @w_aux_registro = CASE @w_contador
          	            when 1 then @i_det_registro1
          	            when 2 then @i_det_registro2
          	            when 3 then @i_det_registro3
          	            when 4 then @i_det_registro4
          	            when 5 then @i_det_registro5
          	            when 6 then @i_det_registro6
          	            when 7 then @i_det_registro7
          	            when 8 then @i_det_registro8
          	            when 9 then @i_det_registro9
          	            when 10 then @i_det_registro10
			    		when 11 then @i_det_registro11
			    		when 12 then @i_det_registro12
			    		when 13 then @i_det_registro13
			    		when 14 then @i_det_registro14
			    		when 15 then @i_det_registro15
                        end
			    	
                    if @w_aux_registro <> '' and  @w_aux_registro IS NOT null
                    begin
			    	    select @aux_det_precio_uni    = null,
			    		       @aux_det_iva_item      = null,
			    		       @aux_det_venta_no_suj  = null,
			    		       @aux_det_venta_exenta  = null,
			    		       @aux_det_venta_gravada = null,
			    		       @aux_det_no_gravado    = null					
			    		
                        EXEC cob_externos..sp_retorno_registro_fac
                            @i_cadena = @w_aux_registro,
                            @o_valor_1  = @w_det_codigo        out,
                            @o_valor_2  = @w_det_descripcion   out,
                            @o_valor_3  = @aux_det_precio_uni    out,
                            @o_valor_4  = @aux_det_iva_item      out,
                            @o_valor_5  = @aux_det_venta_no_suj  out,
			    			@o_valor_6  = @aux_det_venta_exenta  out,
			    			@o_valor_7  = @aux_det_venta_gravada out,
			    			@o_valor_8  = @aux_det_no_gravado    out
			    		
			    		select @w_det_precio_uni    = convert(money,@aux_det_precio_uni),
                               @w_det_iva_item      = convert(money,@aux_det_iva_item),
			    		       @w_det_venta_no_suj  = convert(money,@aux_det_venta_no_suj),
			    		       @w_det_venta_exenta  = convert(money,@aux_det_venta_exenta),
			    		       @w_det_venta_gravada = convert(money,@aux_det_venta_gravada),
			    		       @w_det_no_gravado    = convert(money,@aux_det_no_gravado)
			    		
			    		select @w_res_total_exenta     = @w_res_total_exenta + @w_det_venta_exenta
			    		select @w_res_total_gravada    = @w_res_total_gravada + @w_det_venta_gravada
			    		select @w_res_total_no_suj     = @w_res_total_no_suj + @w_det_venta_no_suj
			    		select @w_res_total_no_gravado = @w_res_total_no_gravado + @w_det_no_gravado
			    		
			    		if (@w_det_no_gravado > 0)
			    		begin					    
			    			select @w_det_precio_uni = 0;
			    		end
			    		
			    		select @w_res_total_iva        = @w_res_total_iva + @w_det_iva_item
			    							
			    		--if exists (select 1 from cobis..cl_catalogo where codigo = @w_det_codigo
                        --and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_fac_venta_tercero'))
                        if exists (select 1 from cobis..cl_catalogo c, cobis..cl_tabla t where c.codigo = @w_det_codigo
                                   and t.tabla = 'cl_fac_venta_tercero' and c.tabla = t.codigo)
                            select @w_aux_seguro = 'S'						

        	            -- insert por cada regsitro
                        insert into cob_externos..ex_dte_detalle (dd_cod_secuencial, dd_fecha_proceso, dd_num_item, dd_tipo_item, dd_num_documento, dd_cantidad, dd_codigo, dd_cod_tributo, dd_uni_medida, dd_descripcion, dd_precio_unitario, dd_descuento, dd_venta_nosujeta, dd_venta_exenta, dd_venta_gravada, dd_tributos, dd_psv, dd_no_gravado, dd_iva_item)
                        values (@s_ssn, @w_fecha_proceso, @w_contador, @w_det_tipo_item, @w_det_numero_documento, @w_det_cantidad, @w_det_codigo, @w_det_cod_tributo, @w_det_uni_medida, @w_det_descripcion, @w_det_precio_uni, @w_det_monto_descu, @w_det_venta_no_suj, @w_det_venta_exenta, @w_det_venta_gravada, @w_det_tributos, @w_det_psv, @w_det_no_gravado, @w_det_iva_item)
                        if @@error <> 0
			    		begin
							select @w_return = 710030 -- Error al insertar informacion de la transaccion
					        goto ERROR
			    		end
			    		
                    end
                    select @w_contador = @w_contador + 1;
                end -- fin while
			    select @w_res_sub_total_ventas      = @w_res_total_no_suj + @w_res_total_exenta + @w_res_total_gravada
			    select @w_res_sub_total             = @w_res_sub_total_ventas --- (@w_res_descu_no_suj + @w_res_descu_exenta + @w_res_descu_gravada)
                select @w_res_monto_total_operacion = @w_res_sub_total + @w_res_total_iva
			    select @w_res_total_pagar           = @w_res_monto_total_operacion + @w_res_total_no_gravado
				
	            select @w_mont_max = pa_money from cobis..cl_parametro with (nolock) 
                where pa_nemonico = 'MOMAFE' and pa_producto = 'CLI'			
			    if (@w_res_total_pagar > @w_mont_max and (@w_rec_telefono is null or @w_rec_correo is null))
			    begin
					select @w_return = 1720644 -- MONTO INGRESADO REQUIERE ACTUALIZAR DATOS DE TELEFONO Y CORREO
					goto ERROR
			    end
			end
			
			-- numero control
            select @w_tipo_ofi = pa_char from cobis..cl_parametro with (nolock)
            where pa_nemonico = 'TOFIFE' and pa_producto = 'CLI'
		     
		    --select @w_aux_ofi = valor from cobis..cl_catalogo where codigo = @s_ofi --TODO: CAMBIAR
            --and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_fac_oficina_hacienda')
            select @w_aux_ofi = c.valor from cobis..cl_catalogo c, cobis..cl_tabla t
            where c.codigo = @s_ofi AND t.tabla = 'cl_fac_oficina_hacienda' and c.tabla = t.codigo
		     
		     exec cobis..sp_cseqnos
                @i_tabla      = 'ex_dte_identificacion_fcf',
		     	@o_siguiente  = @w_aux_ssn out
		     	
            select @w_aux_ssn = right('000000000000000' + convert(varchar, @w_aux_ssn), 15)
            select @w_ide_numero_control = CONCAT('DTE-', @i_ide_tipo_dte, '-', @w_aux_ofi, @w_tipo_ofi, '-', @w_aux_ssn) /*crear un case para pasar los codigos */
		
			-- IDENTIFICACION
            insert into cob_externos..ex_dte_identificacion (di_cod_secuencial, di_fecha_proceso, di_version, di_ambiente, di_tipo_dte, di_num_control, di_cod_generacion, di_tipo_modelo, di_tipo_operacion, di_tipo_contingencia, di_motivo_contin, di_fecha_emision, di_hora_emision, di_tipo_moneda)
            values (@s_ssn, @w_fecha_proceso, @w_ide_version, @w_ide_ambiente, @i_ide_tipo_dte, @w_ide_numero_control, @w_ide_codigo_generacion, @w_ide_tipo_modelo, @w_ide_tipo_operacion, @w_ide_tipo_contingencia, @w_ide_motivo_contin, @w_ide_fec_emi, @w_ide_hora_emi, @w_ide_tipo_moneda)
      	    if @@error <> 0
			begin
				select @w_return = 710030 -- Error al insertar informacion de la transaccion
				goto ERROR
			end
            
			-- EMISOR
            insert into cob_externos..ex_dte_emisor (dm_cod_secuencial, dm_fecha_proceso, dm_nit, dm_nrc, dm_nombre, dm_cod_actividad, dm_desc_ctividad, dm_nombre_comercial, dm_tipo_establecimiento, dm_dir_departamento, dm_dir_municipio, dm_dir_complemento, dm_telefono, dm_correo)
            values (@s_ssn, @w_fecha_proceso, @w_emi_nit, @w_emi_nrc, @w_emi_nombre, @w_emi_cod_actividad, @w_emi_desc_actividad, @w_emi_nombre_comercial, @w_emi_tipo_establecimiento, @w_emi_departamento, @w_emi_municipio, @w_emi_complemento, @w_emi_telefono, @w_emi_correo)
            if @@error <> 0
			begin
				select @w_return = 710030 -- Error al insertar informacion de la transaccion
				goto ERROR
			end
			
            -- RECEPTOR
            insert into cob_externos..ex_dte_receptor (dr_cod_secuencial, dr_fecha_proceso, dr_tipo_doc, dr_numero_doc, dr_nrc, dr_nombres, dr_cod_actividad, dr_desc_ctividad, dr_nombre_comercial, dr_dir_departamento, dr_dir_municipio, dr_dir_complemento, dr_telefono, dr_correo)
			values (@s_ssn, @w_fecha_proceso, @w_rec_tipo_documento, @w_rec_num_documento, @w_rec_nrc, @w_rec_nombre, @w_rec_cod_actividad, @w_rec_desc_actividad, @w_rec_nombre_comercial, @w_rec_departamento, @w_rec_municipio, @w_rec_complemento, @w_rec_telefono, @w_rec_correo)
            if @@error <> 0
			begin
				select @w_return = 710030 -- Error al insertar informacion de la transaccion
				goto ERROR
			end
			
            -- RESUMEN
			if @i_ide_tipo_dte = '05'
			begin
			    insert into cob_externos..ex_dte_total (dt_cod_secuencial, dt_fecha_proceso, dt_total_nosujetas, dt_total_exentas, dt_total_gravadas, dt_subtotal_ventas, dt_desc_nosujetas, dt_desc_exentas, dt_desc_gravadas, dt_porc_descuento, dt_total_descuento, dt_tributo_codigo, dt_tributo_descrip, dt_tributo_valor, dt_subtotal, dt_iva_percibido, dt_iva_retenido, dt_rete_renta, dt_monto_total_ope, dt_total_nogravado, dt_total_pagar, dt_total_letras, dt_total_iva, dt_saldo_favor, dt_cond_operacion)
				select @s_ssn, @w_fecha_proceso, dt_total_nosujetas, dt_total_exentas, dt_total_gravadas, dt_subtotal_ventas, dt_desc_nosujetas, dt_desc_exentas, dt_desc_gravadas, dt_porc_descuento, dt_total_descuento, dt_tributo_codigo, dt_tributo_descrip, dt_tributo_valor, dt_subtotal, dt_iva_percibido, dt_iva_retenido, dt_rete_renta, dt_monto_total_ope, dt_total_nogravado, dt_total_pagar, dt_total_letras, dt_total_iva, dt_saldo_favor, dt_cond_operacion
			    from cob_externos..ex_dte_total where dt_cod_secuencial = @t_ssn_corr and dt_fecha_proceso = @t_fecha_ssn_corr				
			    if @@error <> 0
			    begin
					select @w_return = 710030 -- Error al insertar informacion de la transaccion
				    goto ERROR
			    end
				
				select @w_res_total_pagar = dt_total_pagar from cob_externos..ex_dte_total 
				where dt_cod_secuencial = @s_ssn and dt_fecha_proceso = @w_fecha_proceso
			end
			else
			begin			
			    EXEC @w_res_total_letras = cob_pac..f_numero_a_letras 
                    @i_numero = @w_res_total_pagar,
                    @i_lenguaje = 'ESP'
                insert into cob_externos..ex_dte_total (dt_cod_secuencial, dt_fecha_proceso, dt_total_nosujetas, dt_total_exentas, dt_total_gravadas, dt_subtotal_ventas, dt_desc_nosujetas, dt_desc_exentas, dt_desc_gravadas, dt_porc_descuento, dt_total_descuento, dt_tributo_codigo, dt_tributo_descrip, dt_tributo_valor, dt_subtotal, dt_iva_percibido, dt_iva_retenido, dt_rete_renta, dt_monto_total_ope, dt_total_nogravado, dt_total_pagar, dt_total_letras, dt_total_iva, dt_saldo_favor, dt_cond_operacion)
                values (@s_ssn, @w_fecha_proceso, @w_res_total_no_suj, @w_res_total_exenta, @w_res_total_gravada, @w_res_sub_total_ventas, @w_res_descu_no_suj, @w_res_descu_exenta, @w_res_descu_gravada, @w_res_porcentaje_descuento, @w_res_total_descu, @w_res_codigo, @w_res_descripcion, @w_res_valor, @w_res_sub_total, @w_res_iva_perci_1, @w_res_iva_rete_1, @w_res_rete_renta, @w_res_monto_total_operacion, @w_res_total_no_gravado, @w_res_total_pagar, @w_res_total_letras, @w_res_total_iva, @w_res_saldo_favor, @w_res_condicion_operacion)
			    if @@error <> 0
			    begin
					select @w_return = 710030 -- Error al insertar informacion de la transaccion
				    goto ERROR
			    end
			end
	        -- EXTENSION
            insert into cob_externos..ex_dte_extension (de_cod_secuencial, de_fecha_proceso, de_nombre_entrega, de_docu_entrega, de_nombre_recibe, de_docu_recibe, de_observacion)
            values (@s_ssn, @w_fecha_proceso, @w_ext_nomb_entrega, @w_ext_docu_entrega, @w_ext_nomb_recibe, @w_ext_docu_recibe, @w_ext_observaciones)
		    if @@error <> 0
			begin
				select @w_return = 710030 -- Error al insertar informacion de la transaccion
				goto ERROR
			end
			
            -- APENDICE
			if @i_ide_tipo_dte = '05'
			begin
			    insert into cob_externos..ex_dte_apendice (da_cod_secuencial, da_fecha_proceso, da_campo, da_etiqueta, da_valor)
			    select @s_ssn, @w_fecha_proceso, da_campo, da_etiqueta, da_valor from cob_externos..ex_dte_apendice
			    where da_cod_secuencial = @t_ssn_corr and da_fecha_proceso = @t_fecha_ssn_corr
				if @@error <> 0
                begin
				   select @w_return = 710030 -- Error al insertar informacion de la transaccion
				   goto ERROR
			    end
			end
			else
			begin			
                select @w_contador = 1, @w_aux_registro = null;
                WHILE @w_contador <= 10
                begin
                    select @w_aux_registro = CASE @w_contador
                  	    when 1 then @i_ape_registro1
                  	    when 2 then @i_ape_registro2
                  	    when 3 then @i_ape_registro3
                  	    when 4 then @i_ape_registro4
                  	    when 5 then @i_ape_registro5
                  	    when 6 then @i_ape_registro6
                  	    when 7 then @i_ape_registro7
                  	    when 8 then @i_ape_registro8
                  	    when 9 then @i_ape_registro9
                  	    when 10 then @i_ape_registro10
                        end
                    if @w_aux_registro <> '' and @w_aux_registro IS NOT null
                    begin 
                        EXEC cob_externos..sp_retorno_registro_fac
                            @i_cadena = @w_aux_registro,
                            @o_valor_1  = @w_ape_campo    out,    
                            @o_valor_2  = @w_ape_etiqueta out,
                            @o_valor_3  = @w_ape_valor    out
                	    
						-- insert por cada regsitro						
                        insert into cob_externos..ex_dte_apendice (da_cod_secuencial, da_fecha_proceso, da_campo, da_etiqueta, da_valor)
                        values (@s_ssn, @w_fecha_proceso, @w_ape_campo, @w_ape_etiqueta, @w_ape_valor)
			    		if @@error <> 0
			            begin
							select @w_return = 710030 -- Error al insertar informacion de la transaccion
				            goto ERROR
			            end
                    end
                    select @w_contador = @w_contador + 1;
                end
            end
            -- VENTA TERCERO
            if @i_ven_tercero = 'S' and @w_aux_seguro = 'S'
            begin
                insert into cob_externos..ex_dte_venta_tercero (dv_cod_secuencial, dv_fecha_proceso, dv_nit, dv_nombre)
                values (@s_ssn, @w_fecha_proceso, @w_ven_nit, @w_ven_nombre)
				if @@error <> 0
			    begin
				   select @w_return = 710030 -- Error al insertar informacion de la transaccion
				   goto ERROR
			    end
            end
       
            -- DOCUMENTO RELACIONADO -- validar que si sea con el t_corr
            if @t_corr = 'S' and @i_ide_tipo_dte = '05'-- TO DO aumentar cuando sea NC dado que NC sustituye a CCF
            begin                
				select  @w_doc_numero_documento = di_cod_generacion,	    		        
	    		        @w_doc_fecha_emision    = di_fecha_emision			
                from cob_externos..ex_dte_identificacion where di_cod_secuencial = @t_ssn_corr and di_fecha_proceso = @t_fecha_ssn_corr
				
                insert into cob_externos..ex_dte_doc_relacionado (dc_cod_secuencial, dc_fecha_proceso, dc_tipo_documento, dc_tipo_generacion, dc_num_documento, dc_fecha_emision)
                values (@s_ssn, @w_fecha_proceso, @w_doc_tipo_documento, @w_doc_tipo_generacion, @w_doc_numero_documento, @w_doc_fecha_emision)
				if @@error <> 0
                begin
				   select @w_return = 710030 -- Error al insertar informacion de la transaccion
				   goto ERROR
			    end
            end
     
        end -- FIN if 1

        --else if (@t_corr = 'S' and ((@w_diferencia_tiempo <= @w_horas_diferencia and @i_ide_tipo_dte = '03') OR (@w_diferencia_tiempo < 90 and @i_ide_tipo_dte = '01'))) -- CONDICION DE FECHA 
		else if (@t_corr = 'S' and ((@w_tanquear_invalidacion_ccf = 'S' and @i_ide_tipo_dte = '03') OR (@w_diferencia_tiempo < 90 and @i_ide_tipo_dte = '01'))) -- CONDICION DE FECHA 
	    begin 
			select @w_ide_version = '2'
	    	-- insert IDENTIFICACION
            insert into cob_externos..ex_dte_identificacion (di_cod_secuencial, di_fecha_proceso, di_version, di_ambiente, di_tipo_dte, di_num_control, di_cod_generacion, di_tipo_modelo, di_tipo_operacion, di_tipo_contingencia, di_motivo_contin, di_fecha_emision, di_hora_emision, di_tipo_moneda)
            values (@s_ssn, @w_fecha_proceso, @w_ide_version, @w_ide_ambiente, '20', null, @w_ide_codigo_generacion, null, null, null, null, @w_ide_fec_emi, @w_ide_hora_emi, @w_ide_tipo_moneda)
            if @@error <> 0
			begin
				select @w_return = 710030 -- Error al insertar informacion de la transaccion
				goto ERROR
			end
			
            -- EMISOR
            insert into cob_externos..ex_dte_emisor (dm_cod_secuencial, dm_fecha_proceso, dm_nit, dm_nrc, dm_nombre, dm_cod_actividad, dm_desc_ctividad, dm_nombre_comercial, dm_tipo_establecimiento, dm_dir_departamento, dm_dir_municipio, dm_dir_complemento, dm_telefono, dm_correo)
            values (@s_ssn, @w_fecha_proceso, @w_emi_nit, @w_emi_nrc, @w_emi_nombre, @w_emi_cod_actividad, @w_emi_desc_actividad, @w_emi_nombre_comercial, @w_emi_tipo_establecimiento, @w_emi_departamento, @w_emi_municipio, @w_emi_complemento, @w_emi_telefono, @w_emi_correo)
	        if @@error <> 0
			begin
				select @w_return = 710030 -- Error al insertar informacion de la transaccion
				goto ERROR
			end
			
	        -- DOCUMENTO
            select  @w_anu_doc_tipo_dte          = di_tipo_dte, 
	                @w_anu_doc_numero_control    = di_num_control,
	    		    @w_anu_doc_codigo_generacion = di_cod_generacion,
	    		    @w_anu_doc_fec_emi           = di_fecha_emision			
            from cob_externos..ex_dte_identificacion where di_cod_secuencial = @t_ssn_corr and di_fecha_proceso = @t_fecha_ssn_corr
	    
            select  @w_anu_doc_tipo_documento = dr_tipo_doc,
                    @w_anu_doc_num_documento  = dr_numero_doc,
                    @w_anu_doc_nombre         = dr_nombres,
                    @w_anu_doc_telefono       = dr_telefono,
                    @w_anu_doc_correo         = dr_correo
            from cob_externos..ex_dte_receptor where dr_cod_secuencial = @t_ssn_corr and dr_fecha_proceso = @t_fecha_ssn_corr
	    
            select  @w_anu_doc_sello_recibido = dq_sello_recibido,
			        @w_res_total_pagar        = dq_monto
            from cob_externos..ex_dte_requerimiento where dq_ssn = @t_ssn_corr and dq_fecha_proceso = @t_fecha_ssn_corr
	    
	        --dt_total_pagar, 
            select @w_anu_doc_monto_iva = dt_total_iva
            from cob_externos..ex_dte_total where dt_cod_secuencial = @t_ssn_corr and dt_fecha_proceso = @t_fecha_ssn_corr
	        
            insert into cob_externos..ex_dte_documento_anula (du_cod_secuencial, du_fecha_proceso, du_tipo_dte, du_cod_generacion, du_sello_recibido, du_numero_control, du_fecha_emision, du_monto_iva, du_codigo_generacionR, du_tipo_documento, du_num_documento, du_nombre, du_telefono, du_correo)
            values (@s_ssn, @w_fecha_proceso, @w_anu_doc_tipo_dte, @w_anu_doc_codigo_generacion, @w_anu_doc_sello_recibido, @w_anu_doc_numero_control, @w_anu_doc_fec_emi, @w_anu_doc_monto_iva, @w_anu_doc_codigo_Generacion_r, @w_anu_doc_tipo_documento, @w_anu_doc_num_documento, @w_anu_doc_nombre, @w_anu_doc_telefono, @w_anu_doc_correo)
            if @@error <> 0
			begin
				select @w_return = 710030 -- Error al insertar informacion de la transaccion
				goto ERROR
			end
			
	        -- MOTIVO
            --select @w_anu_mot_motivo_anulacion = valor from cobis..cl_catalogo where codigo = @w_anu_mot_tipo_anulacion 
            --and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_fac_tipo_invalidacion')
            select @w_anu_mot_motivo_anulacion = c.valor from cobis..cl_catalogo c, cobis..cl_tabla t
            where c.codigo = @w_anu_mot_tipo_anulacion AND t.tabla = 'cl_fac_tipo_invalidacion' and c.tabla = t.codigo
	        
            select @w_anu_mot_nombre_responsable  = fu_nombre,
	               @w_anu_mot_num_doc_responsable = fu_cedruc
            from cobis..cl_funcionario where fu_login = @s_user
	        
	        /*validar que los datos enviados sean correctos*/
	        select @w_anu_mot_tip_doc_responsable = 13;
	        
            --select @w_anu_mot_tip_doc_solicita = codigo from cobis..cl_catalogo 
            --where valor = (select pa_char from cobis..cl_parametro where pa_nemonico = 'TIDEFE' and pa_producto = 'CLI')
            --and tabla = (select codigo from cobis..cl_tabla where tabla = 'cl_fac_tipo_doc_ident_recep')
            select @w_anu_mot_tip_doc_solicita = c.codigo from cobis..cl_catalogo c, cobis..cl_tabla t
            where c.valor = (select pa_char from cobis..cl_parametro where pa_nemonico = 'TIDEFE' and pa_producto = 'CLI')
            and t.tabla = 'cl_fac_tipo_doc_ident_recep' and c.tabla = t.codigo
	        
	        select @w_anu_mot_nombre_solicita     = @w_ext_nomb_entrega
	        select @w_anu_mot_num_doc_solicita    = @w_ext_docu_entrega
	    
            insert into cob_externos..ex_dte_motivo_anula (do_cod_secuencial, do_fecha_proceso, do_tipo_anulacion, do_motivo_anulacion, do_nombre_responsable, do_tip_doc_responsable, do_num_doc_responsable, do_nombre_solicita, do_tip_doc_solicita, do_num_doc_solicita)
            values (@s_ssn, @w_fecha_proceso, @w_anu_mot_tipo_anulacion, @w_anu_mot_motivo_anulacion, @w_anu_mot_nombre_responsable, @w_anu_mot_tip_doc_responsable, @w_anu_mot_num_doc_responsable, @w_anu_mot_nombre_solicita, @w_anu_mot_tip_doc_solicita, @w_anu_mot_num_doc_solicita)
	        if @@error <> 0
			begin
				select @w_return = 710030 -- Error al insertar informacion de la transaccion
				goto ERROR
			end
	    end -- FIN else

        -- REQUERIMIENTO        
        select @w_req_monto               = @w_res_total_pagar
        select @w_req_estado              = 'I'
        select @w_req_fecha_procesamiento = convert(varchar, @w_fecha_actual, 23) -- YYYY-MM-DD getDate
        select @w_req_version             = @w_ide_version
        select @w_req_ambiente            = @w_ide_ambiente
			    
        insert into cob_externos..ex_dte_requerimiento (dq_ssn, dq_fecha_proceso, dq_nro_cod_operacion, dq_producto, dq_sello_recibido, dq_monto, dq_estado, dq_num_reenvio, dq_num_impresion, dq_fecha_envio, dq_fecha_procesamiento, dq_clasifica_msg, dq_codigo_msg, dq_descripcion_msg, dq_observaciones, dq_version, dq_ambiente, dq_version_app, dq_usuario, dq_terminal, dq_correccion, dq_estado_correccion, dq_ssn_correccion, dq_fecha_ssn_corr, dq_hora_tanqueo_envio)
        values (@s_ssn, @w_fecha_proceso, @i_ope_banco, @i_prd_cobis, @w_req_sello_recibido, @w_req_monto, @w_req_estado, @w_req_num_reenvio, @w_req_num_impresion, @w_fecha_actual, @w_req_fecha_procesamiento, @w_req_clasifica_msg, @w_req_codigo_msg, @w_req_descripcion_msg, @w_req_observaciones, @w_req_version, @w_req_ambiente, @w_req_version_app, @w_req_usuario, @w_req_terminal, @t_corr, @w_req_estado_correccion, @w_req_ssn_correccion, @w_req_fecha_ssn_corr, @w_fecha_actual)
        if @@error <> 0
		begin
			select @w_return = 710030 -- Error al insertar informacion de la transaccion
			goto ERROR
		end
		
        if (@t_corr = 'S')
        begin
		    -- Se actualiza registro que se reversa
		    update cob_externos..ex_dte_requerimiento
            set dq_estado_correccion  = @w_req_estado_correccion,
				dq_estado             = 'A'
            where dq_ssn = @w_req_ssn_correccion and dq_fecha_proceso = @w_req_fecha_ssn_corr
		    if @@error <> 0
		    begin
				select @w_return = 710030 -- Error al insertar informacion de la transaccion
				goto ERROR
		    end
		end
	
		--Se inserta minuciosamente un registro de TS para posterior seguimiento y trasabilidad
        insert into cob_teller..re_tran_servicio_tel
		(
        ts_secuencial,     ts_cod_alterno, ts_tipo_transaccion, ts_terminal,       ts_origen,       ts_rol,
        ts_producto,       ts_correccion,  ts_filial,           ts_oficina,        ts_oficina_cta,    
        ts_tsfecha,        ts_hora,        ts_usuario,          ts_cta_banco_dep,
        ts_observacion,    ts_estado,      ts_descripcion_ec
		)
		values
		(
		@s_ssn,                  1,              @t_trn,              @s_term,           @s_org,          @s_rol,
		@i_prd_cobis,            @t_corr,        1,                   @s_ofi,            @s_ofi,
		@s_date,                 getdate(),      @s_user,             @i_ope_banco,
		@w_req_descripcion_msg,  @w_req_estado,  @w_ide_codigo_generacion
		)

    if @i_externo = 'S'	
    commit tran
end -- fin operacion I

-- Envio de datos al frontend
    select  @o_ssn             = @s_ssn,
            @o_fecha_registro  = @w_fecha_proceso,
			@o_guid            = @w_ide_codigo_generacion,
			@o_ejecutar_orq    = @w_aux_ejec_orq

SALIR:	
return 0

ERROR:
if @i_externo = 'S'
begin
    rollback tran
	exec cobis..sp_cerror
    @t_debug = 'N',    
    @t_file  = null,
    @t_from  = @w_sp_name,   
    @i_num   = @w_return
end

return @w_return
go
