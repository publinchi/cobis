/************************************************************************/
/*   Archivo            :        sp_reporte_declaracion.sp              */
/*   Stored procedure   :        sp_reporte_declaracion                 */
/*   Base de datos      :        cob_credito                            */
/*   Producto           :        Credito                                */
/*   Disenado por                Patricia Jarrin                        */
/*   Fecha de escritura :        Ene. 23                                */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'COBISCORP S.A'.                                                    */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de COBISCORP S.A                              */
/************************************************************************/ 
/*                             PROPOSITO                                */
/*   Obtener los datos necesarios para el reporte de Declaración Jurada */
/*   de Origen de los Fondos                                            */
/************************************************************************/
/*                            MODIFICACIONES                            */ 
/* Ene/12/2023    Patricia Jarrin      Emision inicial - S749426        */
/* Mar/23/2023    Dilan Morales        Se corrige orden y selects de    */
/*                                     participantes                    */
/* Ago/31/2023    Bruno Dueñas         R214412 Se corrigen selects      */
/* Dic/12/2024    GRO                  R248888:campos conozca su cliente*/ 
/************************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_reporte_declaracion')
   drop proc sp_reporte_declaracion  
go

create proc sp_reporte_declaracion (
   @t_show_version   bit       = 0, -- Mostrar la version del programa
   @s_ssn            int                = NULL,
   @s_user           login              = NULL,
   @s_sesn           int                = NULL,
   @s_term           varchar(30)        = NULL,
   @s_date           datetime           = NULL,
   @s_srv            varchar(30)        = NULL,
   @s_lsrv           varchar(30)        = NULL,
   @s_rol            smallint           = NULL,
   @s_ofi            smallint           = NULL,
   @s_org_err        char(1)            = NULL,
   @s_error          int                = NULL,
   @s_sev            tinyint            = NULL,
   @s_msg            descripcion        = NULL,
   @s_org            char(1)            = NULL,
   @t_debug          char(1)            = 'N',
   @t_file           varchar(14)        = null,
   @t_from           varchar(32)        = null,
   @t_trn            smallint           = NULL,
   @i_operacion      char(1),
   @i_tramite        int
   
)
as

declare @w_sp_name              varchar(32),
        @w_filial               varchar(200),
        @w_oficina              varchar(200),       
        @w_ciudad               varchar(200),       
        @w_fecha_liq            varchar(10),
        @w_fecha_liq_letras     varchar(200),       
        @w_negocio              varchar(200),               
        @w_pago                 varchar(200),       
        @w_cancela              varchar(200),
        @w_ente                 int,
        @w_valores_act          varchar(255),       
        @w_actividad            varchar(200),
        @w_actividad_p          varchar(200),       
        @w_actividad_s          varchar(200),               
        @w_error                int,
		@w_cod_negocio          char(10),    
		@w_cod_otro_ing          char(10)     

declare @w_tabla_datos as table(
        cliente              int,
        filial               varchar(200),
        oficina              varchar(200),
        nombre_completo      varchar(200),
        num_ident            varchar(200),
        domicilio            varchar(200),
        profesion            varchar(200),
        negocio              varchar(200),
        otros_negocios       varchar(200),
        ciudad               varchar(200),
        fecha_letras         varchar(200),
        pago_si              varchar(200),
        pago_no              varchar(200),
        cancela_si           varchar(200),
        cancela_no           varchar(200),
        actividad_principal  varchar(200),
        actividad_secundaria varchar(200),
        rol                  char(1),
        orden                smallint,
		departamento         varchar(200), 
		otros_ing            varchar(200), 
		ventasPromMes        money,        
		ImporteOtrosIng      money,        
		pagValor             money,        
		origenIng            varchar(200)  
)

select @w_sp_name = 'sp_reporte_declaracion',
       @w_pago    = '__',
       @w_cancela = '__',
       @w_ente    = 0,
       @w_valores_act = '',
       @w_actividad_p = '', 
       @w_actividad_s = ''
	   
       
if @t_show_version = 1
begin
   print 'Stored procedure sp_reporte_declaracion, Version 1.0.0'
end

if @t_trn <> 21859
begin
exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file = @t_file,
   @t_from = @w_sp_name,
   @i_num = 151051
   return 151051
end

if @i_operacion = 'S'
begin

    select 
           @w_oficina   = (select of_nombre from cobis..cl_oficina where of_oficina = op_oficina),
           @w_ciudad    = (select ci_descripcion from cobis..cl_ciudad where ci_ciudad =  op_ciudad),
           @w_fecha_liq = convert(varchar, FORMAT(op_fecha_liq, 'dd/MM/yyyy'))
     from cob_cartera..ca_operacion
    where op_tramite = @i_tramite


    if @@rowcount = 0
    begin
       select @w_error = 2110185
       goto ERROR
    end

    exec cob_credito..sp_conv_numero_letras
        @t_trn  = 9490,
        @i_opcion  = 7,
        @i_fecha   = @w_fecha_liq,
        @o_letras  = @w_fecha_liq_letras out

    if exists (select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
    begin
                   
        insert into @w_tabla_datos
        (
        cliente,
        filial,
        oficina,
        nombre_completo,
        num_ident,
        domicilio,
        profesion,
        negocio,
        otros_negocios,
        ciudad,
        fecha_letras,
        pago_si,
        pago_no,
        cancela_si,
        cancela_no,
        actividad_principal,
        actividad_secundaria,
        rol,
		departamento,
		otros_ing,
		ventasPromMes,
		ImporteOtrosIng,
		pagValor,
		origenIng
        )
        select 
        en_ente,
        (select top 1 fi_nombre from cobis..cl_filial),
        @w_oficina,     
        isnull(trim(en_nombre), '') + ' ' + isnull(trim(p_s_nombre), '') + ' ' + isnull(trim(p_p_apellido), '') + ' ' + isnull(trim(p_s_apellido), '') + ' ' + isnull(trim(p_c_apellido), ''),
        en_ced_ruc,           
        (select top 1 isnull(trim((SELECT c.valor
                                   FROM cobis..cl_tabla t, cobis..cl_catalogo c
                                   WHERE t.codigo = c.tabla
                                   AND t.tabla='cl_ciudad'
                                   and c.codigo = di_ciudad)),'') 
         from cobis..cl_direccion di where di_ente = en_ente and (di_principal = 'S' or (di_principal = 'N' and di_tipo <> 'CE') ) order by di.di_principal desc),
        (select top 1 isnull(trim(valor),'') from cobis..cl_catalogo c, cobis..cl_tabla t where c.tabla = t.codigo and t.tabla = 'cl_ocupacion' and c.codigo = trim(p_ocupacion)),
        (SELECT itr_orig_fondo FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente),
		'',
        @w_ciudad,
        @w_fecha_liq_letras,
        (SELECT replace (ea_ingreso_legal,'S','X') FROM cobis..cl_ente_aux WHERE ea_ente=en_ente AND ea_ingreso_legal='S'),
		(SELECT replace (ea_ingreso_legal,'N','X') FROM cobis..cl_ente_aux WHERE ea_ente=en_ente AND ea_ingreso_legal='N'),
        (SELECT replace (itr_can_anticipada,'S','X') FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente AND itr_can_anticipada='S'),
        (SELECT replace (itr_can_anticipada,'N','X') FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente AND itr_can_anticipada='N'),
        '',
        '',
        (select cg_rol from cobis..cl_cliente_grupo where  cg_ente = en_ente and cg_grupo = tg_grupo),
		
		(select top 1 isnull(trim((SELECT c.valor
                                   FROM cobis..cl_tabla t, cobis..cl_catalogo c
                                   WHERE t.codigo = c.tabla
                                   AND t.tabla='cl_provincia'
                                   and c.codigo = di_provincia)),'') 
         from cobis..cl_direccion di where di_ente = en_ente and (di_principal = 'S' or (di_principal = 'N' and di_tipo <> 'CE') ) order by di.di_principal desc),
		'',
		(SELECT TOP 1 an_ventas_prom_mes from cobis..cl_negocio_cliente, cobis..cl_analisis_negocio where nc_ente   = an_cliente_id and nc_codigo = an_negocio_codigo and nc_ente   = en_ente and nc_estado_reg = 'V' order by an_negocio_codigo DESC),
        (SELECT TOP 1 an_monto_extra from cobis..cl_negocio_cliente, cobis..cl_analisis_negocio where nc_ente = an_cliente_id and nc_codigo = an_negocio_codigo and nc_ente= en_ente and nc_estado_reg = 'V' order by an_negocio_codigo DESC),
		(SELECT itr_cuota_adi FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente),
        ''

	   from cobis..cl_ente,
        cob_credito..cr_tramite_grupal  
        where  tg_tramite = @i_tramite 
        and tg_participa_ciclo = 'S'        
        and en_ente = tg_cliente
        
        update @w_tabla_datos
        set orden = 1
        where rol = 'P'
        
        update @w_tabla_datos
        set orden = 2
        where rol not in ('P' , 'M')
        
        update @w_tabla_datos
        set orden = 3
        where rol = 'M'
    end 
    else
    begin
        insert into @w_tabla_datos
        (
        cliente,
        filial,
        oficina,
        nombre_completo,
        num_ident,
        domicilio,
        profesion,
        negocio,
        otros_negocios,
        ciudad,
        fecha_letras,
        pago_si,
        pago_no,
        cancela_si,
        cancela_no,
        actividad_principal,
        actividad_secundaria,
        rol,
		departamento,
		otros_ing,
		ventasPromMes,
		ImporteOtrosIng,
		pagValor,
		origenIng
        )
        select 
        en_ente,
        (select top 1 fi_nombre from cobis..cl_filial),
        @w_oficina,     
        isnull(trim(en_nombre), '') + ' ' + isnull(trim(p_s_nombre), '') + ' ' + isnull(trim(p_p_apellido), '') + ' ' + isnull(trim(p_s_apellido), '') + ' ' + isnull(trim(p_c_apellido), ''),
        en_ced_ruc,   
        (select top 1 isnull(trim((SELECT c.valor
                                   FROM cobis..cl_tabla t, cobis..cl_catalogo c
                                   WHERE t.codigo = c.tabla
                                   AND t.tabla='cl_ciudad'
                                   and c.codigo = di_ciudad)),'') 
         from cobis..cl_direccion di where di_ente = en_ente and (di_principal = 'S' or (di_principal = 'N' and di_tipo <> 'CE') ) order by di.di_principal desc),
        (select top 1 isnull(trim(valor),'') from cobis..cl_catalogo c, cobis..cl_tabla t where c.tabla = t.codigo and t.tabla = 'cl_ocupacion' and c.codigo = trim(p_ocupacion)),
        (SELECT itr_orig_fondo FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente),
		'',
        @w_ciudad,
        @w_fecha_liq_letras,
        (SELECT replace (ea_ingreso_legal,'S','X') FROM cobis..cl_ente_aux WHERE ea_ente=en_ente AND ea_ingreso_legal='S'),
		(SELECT replace (ea_ingreso_legal,'N','X') FROM cobis..cl_ente_aux WHERE ea_ente=en_ente AND ea_ingreso_legal='N'),
        (SELECT replace (itr_can_anticipada,'S','X') FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente AND itr_can_anticipada='S'),
        (SELECT replace (itr_can_anticipada,'N','X') FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente AND itr_can_anticipada='N'),
        '',
        '',
        de_rol,
		(select top 1 isnull(trim((SELECT c.valor
                                   FROM cobis..cl_tabla t, cobis..cl_catalogo c
                                   WHERE t.codigo = c.tabla
                                   AND t.tabla='cl_provincia'
                                   and c.codigo = di_provincia)),'') 
         from cobis..cl_direccion di where di_ente = en_ente and (di_principal = 'S' or (di_principal = 'N' and di_tipo <> 'CE') ) order by di.di_principal desc),
		'',
		(SELECT TOP 1 an_ventas_prom_mes from cobis..cl_negocio_cliente, cobis..cl_analisis_negocio where nc_ente   = an_cliente_id and nc_codigo = an_negocio_codigo and nc_ente   = en_ente and nc_estado_reg = 'V' order by an_negocio_codigo DESC),
        (SELECT TOP 1 an_monto_extra from cobis..cl_negocio_cliente, cobis..cl_analisis_negocio where nc_ente = an_cliente_id and nc_codigo = an_negocio_codigo and nc_ente= en_ente and nc_estado_reg = 'V' order by an_negocio_codigo DESC),
		(SELECT itr_cuota_adi FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente),
		''
        from cobis..cl_ente,
        cob_credito..cr_deudores 
        where de_tramite = @i_tramite 
          and en_ente    = de_cliente
          and de_rol = 'D'
          

        insert into @w_tabla_datos
        (
        cliente,
        filial,
        oficina,
        nombre_completo,
        num_ident,
        domicilio,
        profesion,
        negocio,
        otros_negocios,
        ciudad,
        fecha_letras,
        pago_si,
        pago_no,
        cancela_si,
        cancela_no,
        actividad_principal,
        actividad_secundaria,
        rol,
		departamento,
		otros_ing,
		ventasPromMes,
		ImporteOtrosIng,
		pagValor,
		origenIng
        )
        select 
        en_ente,
        (select top 1 fi_nombre from cobis..cl_filial),
        @w_oficina,     
        isnull(trim(en_nombre), '') + ' ' + isnull(trim(p_s_nombre), '') + ' ' + isnull(trim(p_p_apellido), '') + ' ' + isnull(trim(p_s_apellido), '') + ' ' + isnull(trim(p_c_apellido), ''),
        en_ced_ruc,   
        (select top 1 isnull(trim((SELECT c.valor
                                   FROM cobis..cl_tabla t, cobis..cl_catalogo c
                                   WHERE t.codigo = c.tabla
                                   AND t.tabla='cl_ciudad'
                                   and c.codigo = di_ciudad)),'') 
         from cobis..cl_direccion di where di_ente = en_ente and (di_principal = 'S' or (di_principal = 'N' and di_tipo <> 'CE') ) order by di.di_principal desc),
        (select top 1 isnull(trim(valor),'') from cobis..cl_catalogo c, cobis..cl_tabla t where c.tabla = t.codigo and t.tabla = 'cl_ocupacion' and c.codigo = trim(p_ocupacion)),
        (SELECT itr_orig_fondo FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente),
		'',
        @w_ciudad,
        @w_fecha_liq_letras,
        (SELECT replace (ea_ingreso_legal,'S','X') FROM cobis..cl_ente_aux WHERE ea_ente=en_ente AND ea_ingreso_legal='S'),
		(SELECT replace (ea_ingreso_legal,'N','X') FROM cobis..cl_ente_aux WHERE ea_ente=en_ente AND ea_ingreso_legal='N'),
        (SELECT replace (itr_can_anticipada,'S','X') FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente AND itr_can_anticipada='S'),
        (SELECT replace (itr_can_anticipada,'N','X') FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente AND itr_can_anticipada='N'),
        '',
        '',
        'X',
        (select top 1 isnull(trim((SELECT c.valor
                                   FROM cobis..cl_tabla t, cobis..cl_catalogo c
                                   WHERE t.codigo = c.tabla
                                   AND t.tabla='cl_provincia'
                                   and c.codigo = di_provincia)),'') 
         from cobis..cl_direccion di where di_ente = en_ente and (di_principal = 'S' or (di_principal = 'N' and di_tipo <> 'CE') ) order by di.di_principal desc),		
        '',
	   (SELECT TOP 1 an_ventas_prom_mes from cobis..cl_negocio_cliente, cobis..cl_analisis_negocio where nc_ente   = an_cliente_id and nc_codigo = an_negocio_codigo and nc_ente   = en_ente and nc_estado_reg = 'V' order by an_negocio_codigo DESC),
       (SELECT TOP 1 an_monto_extra from cobis..cl_negocio_cliente, cobis..cl_analisis_negocio where nc_ente = an_cliente_id and nc_codigo = an_negocio_codigo and nc_ente= en_ente and nc_estado_reg = 'V' order by an_negocio_codigo DESC),
		(SELECT itr_cuota_adi FROM cobis..cl_info_trn_riesgo WHERE itr_ente=en_ente),
		''
		from cob_custodia..cu_custodia  , cob_credito..cr_gar_propuesta , cobis..cl_ente 
        where  cu_codigo_externo = gp_garantia 
        and gp_tramite = @i_tramite  
        and cu_garante is not null
        and  en_ente = cu_garante
        
        update @w_tabla_datos
        set orden = 1
        where rol = 'D'
        
        update @w_tabla_datos
        set orden = 2
        where rol = 'X'
    end

    IF OBJECT_ID('tempdb..#tmp_otronegact') IS NOT NULL
    drop table #tmp_otronegact

    create table #tmp_otronegact(
    id                  int not null identity(1,1),
    codigo              varchar(200),
    otro_neg            varchar(200)
    )   

    IF OBJECT_ID('tempdb..#tmp_negact') IS NOT NULL
    drop table #tmp_negact

    create table #tmp_negact(
    id                  int not null identity(1,1),
    codigo              varchar(200),
    actividad           varchar(200)
    )       
    
    select @w_ente = min(cliente)
    from @w_tabla_datos
    
    
    while @w_ente is not null
    begin

        insert into #tmp_otronegact            
        select c.codigo, isnull(trim(valor),'') from cobis..cl_catalogo c, cobis..cl_tabla t where c.tabla = t.codigo and t.tabla = 'cl_fuente_ingreso' and c.codigo in (
        select trim(an_origen_extra) from cobis..cl_analisis_negocio 
         where an_cliente_id = @w_ente)
        
        select @w_valores_act = (select STUFF((SELECT CAST(',' AS varchar(MAX)) + otro_neg from #tmp_otronegact FOR XML PATH('') ), 1, 1, ''))
        
        update @w_tabla_datos set otros_negocios = isnull(@w_valores_act,'') where cliente = @w_ente
		update @w_tabla_datos set origenIng = isnull(@w_valores_act,'') where cliente = @w_ente
        truncate table #tmp_otronegact
        select @w_valores_act = ''      
          
        insert into #tmp_negact
        select top 2 trim(nc_actividad_ec) , (SELECT c.valor
                                              FROM cobis..cl_tabla t, cobis..cl_catalogo c
                                              WHERE t.codigo = c.tabla
                                              AND t.tabla='cl_actividad_ec'
                                              and c.codigo = nc_actividad_ec)
        from cobis..cl_negocio_cliente, cobis..cl_analisis_negocio
        where nc_ente   = an_cliente_id
        and nc_codigo = an_negocio_codigo
        and nc_ente   = @w_ente
        and nc_estado_reg = 'V'
        order by an_ventas_prom_mes desc

        select @w_actividad_p = actividad from #tmp_negact where id = 1 
        select @w_actividad_s = actividad from #tmp_negact where id = 2

        update @w_tabla_datos set actividad_principal =  @w_actividad_p, actividad_secundaria =  @w_actividad_s where cliente = @w_ente     
        truncate table #tmp_negact
        select @w_actividad_p = '', @w_actividad_s = ''
					
        --Siguiente registro
        select @w_ente = min(cliente)
        from @w_tabla_datos
        where cliente > @w_ente
    end
        
    select
        filial,
        oficina,
        nombre_completo = ltrim(rtrim(nombre_completo)),
        num_ident,
        domicilio       = isnull(domicilio,''),
        profesion       = isnull(profesion,''),
        negocio         = case negocio when '1' then 'X' 
									   when '3' then 'X'
									   else '' end ,
        otros_negocios  = case negocio when '2' then otros_negocios
		                               when '3' then otros_negocios
                                       else '-' end,		
        ciudad,
        fecha_letras,
        pago_si         = isnull(pago_si,''),
        pago_no         = isnull(pago_no,''),
        cancela_si      = isnull(cancela_si,''),
        cancela_no      = isnull(cancela_no,''),
        actividad_principal,
        actividad_secundaria,
		departamento,
		otros_ing       = case negocio when '2' then 'X' 
									   when '3' then 'X'
									   else '' end ,
		ventasPromMes   = isnull(ventasPromMes,'-'),
		ImporteOtrosIng = isnull(ImporteOtrosIng,'-'),
		pagValor        = isnull(pagValor,'-'),
		origenIng       = isnull(origenIng,'-') 
		
  from @w_tabla_datos order by orden asc 

end

return 0

ERROR:
   exec cobis..sp_cerror
      @t_debug = 'N',
      @t_file  = null,
      @t_from  = @w_sp_name,
      @i_num   = @w_error
   return @w_error
go
