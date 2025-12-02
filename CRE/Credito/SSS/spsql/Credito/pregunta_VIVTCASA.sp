/************************************************************************/
/*      Archivo:                pregunta_VIVTCASA.sp                    */
/*      Stored procedure:       sp_pregunta_VIVTCASA                    */
/*      Base de datos:          cob_credito                             */
/*      Producto:               CREDITO                                 */
/*      Disenado por:           Jose Escobar                            */
/*      Fecha de escritura:     30-Abr-2019                             */
/************************************************************************/
/*                            IMPORTANTE                                */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de 'COBISCorp'.                                                     */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                             PROPOSITO                                */
/*  Guarda las respuesta del Cuestionario de Supervisor para cálculo de */
/*  puntuación del cliente del producto VIVTCASA para flujo INDIVUAL    */
/*                                                                      */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*    FECHA           AUTOR            RAZON                            */
/*  30/04/2019      José Escobar    Emisión Inicial                     */
/************************************************************************/
use cob_credito
go

if exists (select 1 from   sysobjects where  name = 'sp_pregunta_VIVTCASA')
    drop proc sp_pregunta_VIVTCASA
go

create proc sp_pregunta_VIVTCASA (
    @i_operacion    char(1)     = null,
    @i_cuestionario int         = null,
    @i_cliente      int         = null,
    @i_inst_proceso int         = null,
    @i_producto     catalogo    = null,  -- NEGOCIOS,VIVTCASA,etc.
    @i_tramite      int         = null,
    @i_modo         tinyint     = 0      -- ( 0 , 1 ) -- ( 'DESDE FRONTEND ORIGINADOR WEB' , 'DESDE TAREA AUTOMATICA' )
)

as
declare @w_error             int,
        @w_sp_name           varchar(32),
        @w_en_nomlar         varchar(250),
        @w_asesor            varchar(250),
        @w_product           varchar(64),
        @w_dom_calle         varchar(70),
        @w_dom_numero        int,
        @w_dom_colonia       descripcion,
        @w_dom_delegacion    descripcion,
        @w_neg_calle         varchar(70),
        @w_neg_numero        int,
        @w_neg_colonia       descripcion,
        @w_neg_delegacion    descripcion,
        @w_dir_casa          varchar(250),
        @w_dir_neg           varchar(250),
        @w_dir_id_casa       int,
        @w_dir_id_neg        int,
        @w_geo_dir_casa      varchar(250),
        @w_geo_dir_neg       varchar(250),
        @w_cat_parroq        int,
        @w_cat_ciudad        int,
        @w_cat_tpropi        int,
        @w_cat_activ         int,
        @w_cat_destino       int,
        @w_cat_respu         int,
        @w_tfl_tmp           varchar(16),
        @w_telefono          varchar(250),
        @w_activ_nego        varchar(250),
        @w_activ_tiem        varchar(250),
        @w_destino           varchar(250),
        @w_ventas_neg        varchar(250),
        @w_compras_neg       varchar(250),
        @w_deudas            varchar(250),
        @w_foto_neg          varchar(250),
        @w_foto_obra         varchar(250),
        @w_tpropiedad        varchar(250),
        @w_monto             varchar(250),
        @w_monto_numero      varchar(250),
        @w_plazo             varchar(250)

set @w_sp_name = 'sp_pregunta_VIVTCASA'

if @i_operacion = 'S'
begin
    select @w_cat_parroq  = codigo from cobis..cl_tabla where tabla = 'cl_parroquia'
    select @w_cat_ciudad  = codigo from cobis..cl_tabla where tabla = 'cl_ciudad'
    select @w_cat_tpropi  = codigo from cobis..cl_tabla where tabla = 'cl_tpropiedad'
    select @w_cat_activ   = codigo from cobis..cl_tabla where tabla = 'cl_actividad'
    select @w_cat_destino = codigo from cobis..cl_tabla where tabla = 'cr_destino'
    select @w_cat_respu   = codigo from cobis..cl_tabla where tabla = 'cr_respuesta_texto'

    ----------------------------------------------------------------------------
    -- DATOS GENERALES
    ----------------------------------------------------------------------------

    --  2 - Nombre del cliente
    select @w_en_nomlar = en_nomlar
    from   cobis..cl_ente
    where  en_ente = @i_cliente

    --  3 - Nombre del especialista/asesor
    select @w_asesor = fu_nombre
    from   cob_workflow..wf_inst_proceso
    inner join cobis..cl_funcionario on fu_login = io_usuario_crea
    where  io_id_inst_proc = @i_inst_proceso

    --  4 - Producto
    select @w_product = bp_description from cob_fpm..fp_bankingproducts where bp_product_id = @i_producto

    --  5 - Dirección Domicilio
    -- 21 - Tipo de vivienda
    select top 1
           @w_dir_id_casa     = di_direccion,
           @w_dom_calle       = di_calle,
           @w_dom_numero      = di_nro,
           @w_dom_colonia     = (select valor from cobis..cl_catalogo where tabla = @w_cat_parroq and codigo = convert(varchar(10),C.di_parroquia)),
           @w_dom_delegacion  = (select valor from cobis..cl_catalogo where tabla = @w_cat_ciudad and codigo = convert(varchar(10),C.di_ciudad)),
           @w_tpropiedad      = (select valor from cobis..cl_catalogo where tabla = @w_cat_tpropi and codigo = convert(varchar(10),C.di_tipo_prop))
    from   cobis..cl_direccion C
    where  di_ente = @i_cliente
    and    di_tipo = 'RE' -- cl_tdireccion - RE=DOMICILIO
    order by di_direccion asc
    if @w_dir_id_casa > 0
    begin
        set @w_dir_casa = isnull(@w_dom_delegacion+' / ','') + isnull(@w_dom_colonia+' / ','') + isnull(@w_dom_calle+' / ','') + isnull(convert(varchar,@w_dom_numero),'')
    end

    --  6 - Dirección Negocio
    select top 1
           @w_dir_id_neg     = di_direccion,
           @w_neg_calle      = di_calle,
           @w_neg_numero     = di_nro,
           @w_neg_colonia    = (select valor from cobis..cl_catalogo where tabla = @w_cat_parroq and codigo = convert(varchar(10),C.di_parroquia)),
           @w_neg_delegacion = (select valor from cobis..cl_catalogo where tabla = @w_cat_ciudad and codigo = convert(varchar(10),C.di_ciudad))
    from   cobis..cl_direccion C
    where  di_ente = @i_cliente
    and    di_tipo = 'AE' -- cl_tdireccion - AE=NEGOCIO
    order by di_direccion asc
    if @w_dir_id_neg > 0
    begin
        set @w_dir_neg = isnull(@w_neg_delegacion+' / ','') + isnull(@w_neg_colonia+' / ','') + isnull(@w_neg_calle+' / ','') + isnull(convert(varchar,@w_neg_numero),'')
    end

    --  7 - Teléfono
    set @w_telefono = ''
    declare cur_cl_telefono cursor READ_ONLY for
    select te_valor from cobis..cl_telefono where te_ente = @i_cliente
    open cur_cl_telefono
    fetch cur_cl_telefono into @w_tfl_tmp
    while (@@FETCH_STATUS = 0)
    begin
        set @w_telefono = @w_tfl_tmp + ' - ' + @w_telefono
        fetch cur_cl_telefono into @w_tfl_tmp
    end
    close cur_cl_telefono
    deallocate cur_cl_telefono


    -- DATOS GENERALES
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values ( 1, convert(varchar,@i_cliente) ) -- Número de cliente
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values ( 2, @w_en_nomlar )                -- Nombre del cliente
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values ( 3, @w_asesor )                   -- Nombre del especialista/asesor
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values ( 4, @w_product )                  -- Producto
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values ( 5, @w_dir_casa )                 -- Dirección Domicilio
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values ( 6, @w_dir_neg )                  -- Dirección Negocio
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values ( 7, @w_telefono )                 -- Teléfono

    ----------------------------------------------------------------------------
    -- SUPERVISIÓN NEGOCIO
    ----------------------------------------------------------------------------

    --  8 - Actividad
    --  9 - Antigüedad
    -- OJO - PENDIENTE DEFINIR CUAL ES EL NEGOCIO QUE SE  VA AELEGIR PARA UN TRAMITE
    select top 1
           @w_activ_nego   = (select valor from cobis..cl_catalogo where tabla = @w_cat_activ and codigo = nc_actividad_ec),
           @w_activ_tiem   = convert(varchar(250),nc_tiempo_actividad)
    from   cobis..cl_negocio_cliente
    where  nc_ente = @i_cliente
    order by nc_codigo desc

    -- 12 - Destino del Crédito
    select @w_destino = (select valor from cobis..cl_catalogo where tabla = @w_cat_destino and codigo = tr_destino),
           @w_monto   = format(tr_monto,'N2') + ' ' + ( select mo_descripcion from cobis..cl_moneda where mo_moneda = tr_moneda),
           @w_plazo   = convert(varchar,tr_plazo) + '  ' + (select td_descripcion from cob_cartera..ca_tdividendo  where td_tdividendo = tr_tplazo),
           @w_monto_numero = REPLACE(format(tr_monto,'N2') , ',' , '' )
    from   cr_tramite
    where  tr_tramite = @i_tramite

    -- 14 - Ventas
    -- 16 - Compras
    -- BUSCAR CON EL CODIGO DEL NEGOCIO A OBTENER EN EL SELECT ANTERIOR
    select @w_ventas_neg  = format(an_ventas_prom_mes,'N2'),
           @w_compras_neg = format(an_compras_prom_mes,'N2')
    from cobis..cl_analisis_negocio, cobis..cl_negocio_cliente
    where an_cliente_id = @i_cliente
    and an_negocio_codigo = nc_codigo
    and nc_estado_reg = 'V'

    -- OJO - POR DEFINIR
    -- 18 - Deudas

    -- 20 - Foto Negocio
    set @w_foto_neg = case when @i_modo = 0 then 'NO' else 'N' end
    if exists( select 1
               from cobis..cl_documento_digitalizado
               where dd_inst_proceso = @i_inst_proceso
               and   dd_producto     = @i_producto --'VIVTCASA'
               and   dd_codigo       = '006'  -- cobis..cl_documento_parametro
               and   dd_cargado      = 'S' )
    begin
        set @w_foto_neg = case when @i_modo = 0 then 'SI' else 'S' end
    end
    if @i_modo = 1
    begin
        -- REEMPLAZA EN TEXTO POR EL CODIGO EN LA IMAGEN(apk) PARA QUE PUEDA OBTENER SU DESCRIPCION
        -- Y ENVIAR ESTE MISMO CODIGO DE REGRESO CUANDO SE CARGUE LA IMAGEN
        update #cr_pregunta
        set    prt_descripcion = trim(dp_tipo +'_'+ dp_producto +'_'+ dp_codigo)
        from   cobis..cl_documento_parametro
        where  dp_tipo     = prt_tipo_respuesta
        and    dp_producto = @i_producto
        and    dp_codigo   = '020'
        and    prt_seccion = '02_SUP_NEG'
        and    prt_tipo_respuesta = 'I'
    end

    -- 21 - Geolocalización Negocio
    select @w_geo_dir_neg = 'LATITUD: ' + convert(varchar,dg_lat_seg) + ' - LONGITUD: ' + convert(varchar,dg_long_seg)
    from   cobis..cl_direccion_geo
    where  dg_direccion   = @w_dir_id_neg
    and    dg_ente        = @i_cliente
    and    dg_secuencial  = (select max(dg_secuencial) from cobis..cl_direccion_geo where dg_ente = @i_cliente and dg_direccion = @w_dir_id_neg)

    -- SUPERVISIÓN NEGOCIO
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values ( 8, @w_activ_nego )               -- Actividad
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values ( 9, @w_activ_tiem )               -- Antigüedad
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (12, @w_destino )                  -- Destino del Crédito
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (14, @w_ventas_neg )               -- Ventas
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (16, @w_compras_neg )              -- Compras
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (18, @w_deudas )                   -- Deudas
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (20, @w_foto_neg )                 -- Foto Negocio
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (21, @w_geo_dir_neg )              -- Geolocalización Negocio

    ----------------------------------------------------------------------------
    -- SUPERVISIÓN DOMICILIO
    ----------------------------------------------------------------------------

    -- 23 - Tipo de vivienda
    -- SE OBTUVO CON EL DATO 5

    -- 26 - Foto Obra
    set @w_foto_obra = case when @i_modo = 0 then 'NO' else 'N' end
    if exists( select 1
               from cobis..cl_documento_digitalizado
               where dd_inst_proceso = @i_inst_proceso
               and   dd_producto     = @i_producto --'VIVTCASA'
               and   dd_codigo       in ('009','010')  -- cobis..cl_documento_parametro
               and   dd_cargado      = 'S' )
    begin
        set @w_foto_obra = case when @i_modo = 0 then 'SI' else 'S' end
    end
    if @i_modo = 1
    begin
        -- REEMPLAZA EN TEXTO POR EL CODIGO EN LA IMAGEN(apk) PARA QUE PUEDA OBTENER SU DESCRIPCION
        -- Y ENVIAR ESTE MISMO CODIGO DE REGRESO CUANDO SE CARGUE LA IMAGEN
        update #cr_pregunta
        set    prt_descripcion = trim(dp_tipo +'_'+ dp_producto +'_'+ dp_codigo)
        from   cobis..cl_documento_parametro
        where  dp_tipo     = prt_tipo_respuesta
        and    dp_producto = @i_producto
        and    dp_codigo   = '025'
        and    prt_seccion = '03_SUP_DOM'
        and    prt_tipo_respuesta = 'I'
    end

    -- 27 - Geolocalización Domicilio
    select @w_geo_dir_casa = 'LATITUD: ' + convert(varchar,dg_lat_seg) + ' - LONGITUD: ' + convert(varchar,dg_long_seg)
    from   cobis..cl_direccion_geo
    where  dg_direccion   = @w_dir_id_casa
    and    dg_ente        = @i_cliente
    and    dg_secuencial  = (select max(dg_secuencial) from cobis..cl_direccion_geo where dg_ente = @i_cliente and dg_direccion = @w_dir_id_casa)

    -- SUPERVISIÓN DOMICILIO
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (23, @w_tpropiedad )               -- Tipo de vivienda
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (26, @w_foto_obra )                -- Foto Obra
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (27, @w_geo_dir_casa )             -- Geolocalización Domicilio

    ----------------------------------------------------------------------------
    -- DICTAMEN
    ----------------------------------------------------------------------------

    -- 31 - Monto Solicitado
    -- SE OBTUVO CON EL DATO 12
    -- 32 - Monto Recomendado
    -- SE OBTUVO CON EL DATO 12
    -- 33 - Monto Solicitado
    -- SE OBTUVO CON EL DATO 12

    -- DICTAMEN
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (31, @w_monto )                    -- Monto Solicitado
    insert into #cr_validacion( val_codigo , val_respuesta ) values (32, @w_monto_numero )             -- Monto Recomendado
    insert into #cr_respuesta ( ret_codigo , ret_respuesta ) values (33, @w_plazo )                    -- Plazo Solicitado


    ----------------------------------------------------------------------------
    -- DATOS YA LLENADOS POR LA APP MOVIL, EN CASO DE QUE YA EXISTAN
    ----------------------------------------------------------------------------
    insert into #cr_respuesta ( ret_codigo , ret_respuesta, ret_puntaje )
    select prc_codigo , case when @i_modo = 0 then trim(valor) else trim(codigo) end , pv_puntaje
    from   cr_pregunta_repuesta_c
    left join cr_pregunta_ver_dat on pv_tipo = 'I' and pv_producto = @i_producto and pv_codigo = prc_codigo and pv_valor = prc_respuesta
    left join cobis..cl_catalogo on tabla = @w_cat_respu and prc_respuesta = codigo
    where  prc_cuestionario = @i_cuestionario

    insert into #cr_respuesta ( ret_codigo , ret_respuesta )
    select prm_codigo , format(prm_respuesta,'N2')
    from   cr_pregunta_repuesta_m
    where  prm_cuestionario = @i_cuestionario

    insert into #cr_respuesta ( ret_codigo , ret_respuesta )
    select prn_codigo , convert(varchar,prn_respuesta)
    from   cr_pregunta_repuesta_n
    where  prn_cuestionario = @i_cuestionario

    insert into #cr_respuesta ( ret_codigo , ret_respuesta )
    select prt_codigo , prt_respuesta
    from   cr_pregunta_repuesta_t
    where  prt_cuestionario = @i_cuestionario

    return 0
end

return 0
ERROR:
    begin --Devolver mensaje de Error
        exec cobis..sp_cerror
             @t_debug = 'N',
             @t_file  = '',
             @t_from  = @w_sp_name,
             @i_num   = @w_error
        return @w_error
    end
go
