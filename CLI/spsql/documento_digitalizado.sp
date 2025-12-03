/************************************************************************/
/*      Archivo:                sp_documento_digitalizado.sp            */
/*      Stored procedure:       sp_documento_digitalizado               */
/*      Base de datos:          cobis                                   */
/*      Producto:               CLIENTES                                */
/*      Disenado por:           Jose Escobar                            */
/*      Fecha de escritura:     02-Abr-2019                             */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                             PROPOSITO                                */
/*    Este programa permite insertar los documentos digitalizados       */
/*    tanto del flujo grupal, flujo individual y para prospetos         */
/*                                                                      */
/************************************************************************/
/*                           MODIFICACIONES                             */
/*    FECHA           AUTOR            RAZON                            */
/*  02/04/2019      José Escobar    Emisión Inicial                     */
/*  23/10/2019      José Escobar    Documentos por etapas de un flujo   */
/*  06/07/2020      MBA             Estandarizacion sp y seguridades    */
/*  21/01/2021      MGB             Ajustes compatibilidad para mysql   */
/*  06/04/2021      ACA             Nuevos campos consulta              */
/*  18/05/2023      Bruno Duenas    Consulta nemonicos docs app         */
/*  09/09/2023      BDU             R214440-Sincronizacion automatica   */
/*  20/10/2023      BDU             R217831-Ajuste validacion error     */
/*  22/01/2024      BDU             R224055-Validar oficina app         */
/************************************************************************/
use cobis
go

if exists (select 1 from   sysobjects where  name = 'sp_documento_digitalizado')
    drop proc sp_documento_digitalizado
go

create proc sp_documento_digitalizado (
  @s_ssn          int         = null,
  @s_sesn         int         = null,
  @s_user         login       = null,
  @s_term         varchar(30) = null,
  @s_date         datetime    = null,
  @s_srv          varchar(30) = null,
  @s_lsrv         varchar(30) = null,
  @s_ofi          smallint    = null,
  @s_rol          smallint    = null,
  @s_org_err      char(1)     = null,
  @s_error        int         = null,
  @s_sev          tinyint     = null,
  @s_msg          descripcion = null,
  @s_org          char(1)     = null,
  @t_debug        char(1)     = 'N',
  @t_file         varchar(10) = null,
  @t_from         varchar(32) = null,
  @t_trn          int         = null,
  @t_show_version bit         = 0,
  @i_operacion    char(1)     = null,
  @i_modo         smallint    = null,
  @i_cliente      int         = null,
  @i_inst_proceso int         = null,
  @i_grupo        int         = null,
  @i_tipo         char(1)     = null, -- P=PROSPECTO, I=INDIVIDUAL, G=GRUPAL
  @i_codigo       catalogo    = null,
  @i_extension    char(8)     = null,
  @i_producto     catalogo    = null, -- CLIENTE,NEGOCIOS,VIVTCASA,LEGALetc.

  @i_codigo2      catalogo    = null,
  @i_detalle      descripcion = null,
  @i_requerido    char(1)     = null, -- S/N
  @i_tamanio      tinyint     = null,

  @i_actididad    int         = null,
  @i_visible      char(1)     = null, -- S/N
  @i_descarga     char(1)     = null, -- S/N
  @i_subida       char(1)     = null  -- S/N
)
as
declare @w_estado      char(1),
        @w_tramite     int,
        @w_fecha       datetime,
        @w_relacion    tinyint,
        @w_conyuge     int,
        @w_error       int,
        @w_sp_name     varchar(32),
        @w_return      int,
        @w_num         int,
        @w_param       int, 
        @w_diff        int,
        @w_date        datetime,
        @w_bloqueo     char(1),
        -- R214440-Sincronizacion automatica
        @w_sincroniza      char(1),
        @w_ofi_app         smallint


set @w_sp_name = 'sp_documento_digitalizado'

if @t_show_version = 1
begin
    print 'Stored procedure sp_documento_digitalizado, Version 5.0.0.0'
    return 0
end
-- Valida codigo de transaccion
if  (@t_trn !=  172103  or @i_operacion != 'I')
and (@t_trn !=  172104  or @i_operacion != 'U')
and (@t_trn !=  172105  or @i_operacion != 'D')
and (@t_trn !=  172106  or @i_operacion != 'Q')
and (@t_trn !=  172107  or @i_operacion != 'S')
begin
   select @w_return  = 107098
   goto ERROR
end
if @i_operacion = 'U'
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   if @i_cliente is not null and @i_cliente <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_cliente
      if @w_bloqueo = 'S'
      begin
         set @w_error = 1720604
         goto ERROR
      end
   end 
end

if @i_operacion in ( 'U' , 'Q' )
begin
    if @i_tipo is null
    begin
        set @w_error = 1720147 -- No existe Tipo de Documento
        goto ERROR
    end

    if @i_cliente is null
    begin
        set @w_error = 1720103 --No existe Codigo de Cliente del Banco
        goto ERROR
    end

    -- BUSCA PRODUCTO EN CASO DE QUE TENGA INSTANCIA DE PROCESO y EL @i_producto ESTE SIN VALOR
    if @i_inst_proceso >0 and isnull(@i_producto,'') = ''
    begin
        select @i_producto     = io_campo_4
        from   cob_workflow..wf_inst_proceso
        where  io_id_inst_proc = @i_inst_proceso
    end

    if @i_producto is null
    begin
        set @w_error = 1720326 --Existieron problemas con la identificación del tipo de producto
        goto ERROR
    end

end

select @w_fecha = fp_fecha from cobis..ba_fecha_proceso
select @w_fecha = convert(datetime,(convert(varchar,@w_fecha,101) + ' ' + convert(varchar,datepart(hh, getDate())) + ':' + convert(varchar,datepart(mi, getDate())) + ':' + convert(varchar,datepart(ss, getdate())) ))

if @i_operacion = 'U'
begin

    if @i_codigo is null
    begin
        set @w_error = 1720327 --No existen documentos de empresa
        goto ERROR
    end

    if @i_producto = 'CLIENTE'
       select @i_producto = 'PROSPECTO'

    if exists (select 1 from cl_documento_digitalizado
               where dd_inst_proceso = @i_inst_proceso
               and   dd_cliente      = @i_cliente
               and   dd_grupo        = @i_grupo
               and   dd_codigo       = @i_codigo
               and   dd_producto     = @i_producto
               and   dd_tipo         = @i_tipo)
    begin
        update cl_documento_digitalizado
        set   dd_cargado      = 'S',
              dd_extension    = @i_extension,
              dd_fecha        = @w_fecha
        where dd_inst_proceso = @i_inst_proceso
        and   dd_cliente      = @i_cliente
        and   dd_grupo        = @i_grupo
        and   dd_codigo       = @i_codigo
        and   dd_producto     = @i_producto
        and   dd_tipo         = @i_tipo
    end
    else
    begin
        insert into cl_documento_digitalizado
               ( dd_tipo , dd_inst_proceso , dd_cliente , dd_grupo , dd_codigo , dd_producto , dd_fecha , dd_cargado, dd_extension)
        values ( @i_tipo , @i_inst_proceso , @i_cliente , @i_grupo , @i_codigo , @i_producto , @w_fecha , 'S',        @i_extension)
    end
    goto SINC

end

if @i_operacion = 'Q'
begin
    --Obtener nemonicos de docs para el app
    if @i_tipo = 'N'
    begin
       select 'INS_PROCESO'   = 0,
              'CLIENTE'       = 0,
              'GRUPO'         = 0,
              'FECHA'         = getdate(),
              'NOMBRE'        = '',
              'CARGADO'       = '',
              'CODIGO'        = pa_char, --Aqui sacar el nemonico
              'EXTENSION'     = '',
              'REQUERIDO'     = '',
              'DESCARGA'      = '',
              'SUBIDA'        = '',
              'TAMANIO'       = 0
       from   cobis.dbo.cl_parametro
       where pa_char in ('DUI_DER', 'DUI_IZQ', 'FOTO_ADIC', 'FOT_NEGVIV', 'REC_SERV')
       
       return 0
    end
    create table #CLIENTE (
        cl_cliente       int       not null,
        cl_documento     catalogo  not null,
        cl_existe        char(1)   default 'N', -- S/N
        cl_fecha_carga   date      null,
        cl_tamanio       tinyint   null,
        cl_rol           catalogo  null,
        cl_producto      catalogo null
    )
    create table #ACTIVIDAD (
        ac_tipo             char(1)      not null,    -- cl_tramite_documento <-> I=INDIVIDUAL, G=GRUPAL
        ac_producto         catalogo     not null,    -- cl_producto_documento
        ac_codigo           catalogo     not null,    -- cobis..cl_documento_parametro..dp_codigo
        ac_requerido        char(1)      not null,    -- S/N
        ac_descarga         char(1)      not null,    -- S/N
        ac_subida           char(1)      not null     -- S/N
    )

    set @w_conyuge = 0

    if @i_tipo in ('I','G') or ( (@i_tipo = 'P') and (@i_producto != 'CLIENTE') )  --I=INDIVIDUAL, G=GRUPAL , P=PERSONA(NO NATURAL)
    begin
        -- BUSCA DOCUMENTOS PARAMETRIZADOS DE CLIENTE
        insert into #CLIENTE
             ( cl_cliente, cl_documento, cl_existe, cl_tamanio, cl_producto )
        select @i_cliente, dp_codigo   , 'N',       dp_tamanio, dp_producto
        from   cl_documento_parametro
        where  dp_tipo     = @i_tipo
        and    dp_producto = @i_producto
        and    dp_estado   = 'V'
    end
    else if (@i_tipo = 'P') and (@i_producto = 'CLIENTE')--P=PROSPECTO(SOLO CLIENTE NATURAL)
    begin
        -- BUSCA DOCUMENTOS PARAMETRIZADOS DE CLIENTE
        insert into #CLIENTE
             ( cl_cliente, cl_documento, cl_existe, cl_rol, cl_producto )
        select @i_cliente, dp_codigo   , 'N',       'CLIE', dp_producto
        from   cl_documento_parametro
        where  dp_tipo     = @i_tipo
        and    dp_producto = 'PROSPECTO'
        and    dp_estado   = 'V'

        -- VALIDA SI TIENE CONYUGUE
        select @w_relacion = pa_tinyint from cobis..cl_parametro where  pa_nemonico = 'CONY' and pa_producto = 'CLI' -- RELACION CONYUGUE
        select @w_conyuge  = in_ente_d
        from   cobis..cl_instancia
        where  in_relacion = @w_relacion
        and    in_ente_i   = @i_cliente

        set @w_conyuge = isnull(@w_conyuge,0)

        if(@w_conyuge > 0 )
        begin
            -- BUSCA DOCUMENTOS PARAMETRIZADOS DE CONYUGE
            insert into #CLIENTE
                 ( cl_cliente, cl_documento, cl_existe, cl_rol, cl_producto )
            select @w_conyuge, dp_codigo   , 'N',       'CONY', dp_producto
            from   cl_documento_parametro
            where  dp_tipo     = @i_tipo
            and    dp_producto = 'CONYUGE'
            and    dp_estado   = 'V'
        end
    end

    if @i_tipo in ('I','G','P') --I=INDIVIDUAL , G=GRUPAL , P=PROSPECTO
    begin
        -- MARCA DOCUMENTOS EN CASO DE QUE YA ESTEN CARGADOS
        update #CLIENTE
        set    cl_existe       = 'S',
               cl_fecha_carga  = dd_fecha
        from   cl_documento_digitalizado
        where  dd_cliente      = cl_cliente
        and    dd_codigo       = cl_documento
        and    dd_producto     = cl_producto
        and    dd_grupo        = @i_grupo
        and    dd_inst_proceso = @i_inst_proceso

        -- BORRA REGISTROS DE LA TEMPORAL QUE YA EXISTEN EN LA BB.DD.
        delete #CLIENTE
        where  cl_existe = 'S' -- Ya cargados en la BB.DD.

        -- INSERTA DOCUMENTOS QUE AUN NO ESTAN EN LA BB.DD. PARA PODER PARAMETRIZARLOS
        if ( (@i_tipo='P') and (@i_cliente>0) ) or ( (@i_tipo in ('G','I')) and (@i_inst_proceso>0) )
        begin
            insert into cl_documento_digitalizado
                 ( dd_tipo , dd_inst_proceso , dd_cliente , dd_grupo , dd_codigo    , dd_producto , dd_fecha , dd_cargado, dd_extension )
            select @i_tipo , @i_inst_proceso , cl_cliente , @i_grupo , cl_documento , cl_producto , @w_fecha , 'N',        @i_extension
            from   #CLIENTE
        end

        -- DESPLIEGA RESULTADOS
        if (@i_tipo = 'P') and (@i_producto = 'CLIENTE' )--P=PROSPECTO(SOLO CLIENTE NATURAL)
        begin
            if(isnull(@w_conyuge,0) > 0 )
            begin
                select 'INS_PROCESO'  = dd_inst_proceso,
                       'CLIENTE'      = dd_cliente,
                       'GRUPO'        = dd_grupo,
                       'FECHA'        = dd_fecha,
                       'NOMBRE'       = 'CLIENTE - ' + dp_detalle,
                       'CARGADO'      = dd_cargado,
                       'CODIGO'       = dd_codigo,
                       'EXTENSION'    = trim(dd_extension),
                       'REQUERIDO'    = dp_requerido,
                       'DESCARGA'     = 'S',
                       'SUBIDA'       = 'S',
                       'TAMANIO'      = dp_tamanio,
                       'PRODUCTO'     = isnull(dp_producto,'PROSPECTO')
                from  cl_documento_digitalizado
                inner join cl_documento_parametro on dp_tipo = @i_tipo and dp_producto = 'PROSPECTO' and dp_codigo = dd_codigo and dp_estado = 'V'
                where dd_cliente      = @i_cliente
                and   dd_inst_proceso = @i_inst_proceso
                and   dd_grupo        = @i_grupo
                and   dd_producto     = dp_producto
                and   dd_tipo         = @i_tipo
                union
                select 'INS_PROCESO'  = dd_inst_proceso,
                       'CLIENTE'      = dd_cliente,
                       'GRUPO'        = dd_grupo,
                       'FECHA'        = dd_fecha,
                       'NOMBRE'       = 'CONYUGE - ' + dp_detalle,
                       'CARGADO'      = dd_cargado,
                       'CODIGO'       = dd_codigo,
                       'EXTENSION'    = trim(dd_extension),
                       'REQUERIDO'    = dp_requerido,
                       'DESCARGA'     = 'S',
                       'SUBIDA'       = 'S',
                       'TAMANIO'      = dp_tamanio,
                       'PRODUCTO'     = isnull(dp_producto,'CONYUGE')
                from  cl_documento_digitalizado
                inner join cl_documento_parametro on dp_tipo = @i_tipo and dp_producto = 'CONYUGE' and dp_codigo = dd_codigo and dp_estado = 'V'
                where dd_cliente      = @w_conyuge
                and   dd_inst_proceso = @i_inst_proceso
                and   dd_grupo        = @i_grupo
                and   dd_producto     = dp_producto
                and   dd_tipo         = @i_tipo
                order by 13 desc , 9 desc , 6 desc
                return 0
            end
            else
            begin
                select 'INS_PROCESO'  = dd_inst_proceso,
                       'CLIENTE'      = dd_cliente,
                       'GRUPO'        = dd_grupo,
                       'FECHA'        = dd_fecha,
                       'NOMBRE'       = dp_detalle,
                       'CARGADO'      = dd_cargado,
                       'CODIGO'       = dd_codigo,
                       'EXTENSION'    = trim(dd_extension),
                       'REQUERIDO'    = dp_requerido,
                       'DESCARGA'     = 'S',
                       'SUBIDA'       = 'S',
                       'TAMANIO'      = dp_tamanio
                from  cl_documento_digitalizado
                inner join cl_documento_parametro on dp_tipo = @i_tipo and dp_producto = 'PROSPECTO' and dp_codigo = dd_codigo and dp_estado = 'V'
                where dd_cliente      = @i_cliente
                and   dd_inst_proceso = @i_inst_proceso
                and   dd_grupo        = @i_grupo
                and   dd_producto     = dp_producto
                and   dd_tipo         = @i_tipo
                order by 9 desc , 6 desc , 5
                return 0
            end
           
        end
        else if (@i_tipo = 'I') or ( (@i_tipo = 'P') and (@i_producto != 'CLIENTE') ) --I=INDIVIDUAL , P=PERSONA(NO NATURAL)
        begin
        
        if(@i_producto = 'LEGAL')
            begin
                select 'INS_PROCESO'  = dd_inst_proceso,
                       'CLIENTE'      = dd_cliente,
                       'GRUPO'        = dd_grupo,
                       'FECHA'        = dd_fecha,
                       'NOMBRE'       = dp_detalle,
                       'CARGADO'      = dd_cargado,
                       'CODIGO'       = dd_codigo,
                       'EXTENSION'    = trim(dd_extension),
                  'REQUERIDO'    = dp_requerido,
                       'DESCARGA'     = 'S',
                       'SUBIDA'       = 'S',
                       'TAMANIO'      = dp_tamanio
                from  cl_documento_digitalizado
                inner join cl_documento_parametro on dp_tipo = @i_tipo and dp_producto = 'LEGAL' and dp_codigo = dd_codigo and dp_estado = 'V'
                where dd_cliente      = @i_cliente
                and   dd_inst_proceso = @i_inst_proceso
                and   dd_grupo        = @i_grupo
                and   dd_producto     = @i_producto
                and   dd_tipo         = @i_tipo
                order by 9 desc , 6 desc , 5
                return 0
            end         

            if exists (select 1 from cobis..cl_documento_parametro where dp_producto = @i_producto )
            begin
                insert into #ACTIVIDAD
                      (ac_tipo , ac_producto , ac_codigo , ac_requerido , ac_descarga , ac_subida)
                select da_tipo , da_producto , da_codigo , da_requerido , da_descarga , da_subida
                from   cl_documento_actividad
                inner join cob_workflow..wf_inst_actividad on ia_id_inst_proc = @i_inst_proceso and da_actividad = ia_codigo_act and ia_estado = 'ACT' and ia_func_asociada is not null
                where  da_producto = @i_producto
                and    da_tipo     = @i_tipo
                and    da_visible  = 'S'

                if @@rowcount = 0  -- TEMPORAL HASTA QUE LA PLATAFORMA CAMBIE EL ESTADO 'INA' EN LA PRIMERA ETAPA DEL FLUJO
                begin
                    insert into #ACTIVIDAD
                          (ac_tipo , ac_producto , ac_codigo , ac_requerido , ac_descarga , ac_subida)
                    select da_tipo , da_producto , da_codigo , da_requerido , da_descarga , da_subida
                    from   cl_documento_actividad
                    inner join cob_workflow..wf_inst_actividad on ia_id_inst_proc = @i_inst_proceso and da_actividad = ia_codigo_act and ia_estado = 'INA' and ia_func_asociada is not null and ia_nombre_act = 'INGRESO DE SOLICITUD'
                    where  da_producto = @i_producto
                    and    da_tipo     = @i_tipo
                    and    da_visible  = 'S'
                end
            end
            else if (@i_producto = 'LOAN')
            begin
                select @i_inst_proceso = io_id_inst_proc , @i_producto = trim(io_campo_4)
                from   cob_workflow..wf_inst_proceso
                inner join cob_workflow..wf_proceso on pr_codigo_proceso = io_codigo_proc and pr_producto = 'CCA'
                where io_campo_3 = @i_inst_proceso

                insert into #ACTIVIDAD
                      (ac_tipo , ac_producto , ac_codigo , ac_requerido , ac_descarga , ac_subida)
                select da_tipo , da_producto , da_codigo , da_requerido , da_descarga , da_subida
                from   cl_documento_actividad
                where  da_actividad = -2
                and    da_producto  = @i_producto
                and    da_tipo      = @i_tipo
                and    da_visible   = 'S'
            end

            select 'INS_PROCESO'   = dd_inst_proceso,
                   'CLIENTE'       = dd_cliente,
                   'GRUPO'         = dd_grupo,
                   'FECHA'         = dd_fecha,
                   'NOMBRE'        = dp_detalle,
                   'CARGADO'       = dd_cargado,
                   'CODIGO'        = dd_codigo,
                   'EXTENSION'     = trim(dd_extension),
                   'REQUERIDO'     = ac_requerido,
                   'DESCARGA'      = ac_descarga,
                   'SUBIDA'        = ac_subida,
                   'TAMANIO'       = dp_tamanio
            from   cl_documento_digitalizado
            inner join cl_documento_parametro on dp_tipo = @i_tipo and dp_producto = dd_producto and dp_codigo = dd_codigo and dp_estado = 'V'
            inner join #ACTIVIDAD on ac_tipo = dp_tipo and ac_producto = dp_producto and ac_codigo = dp_codigo
            where  dd_cliente      = @i_cliente
            and    dd_inst_proceso = @i_inst_proceso
            and    dd_grupo        = @i_grupo
            and    dd_producto     = @i_producto
            and    dd_tipo         = @i_tipo
            order by 9 desc , 6 desc , 5
            return 0
        end
        else if @i_tipo = 'G' --GRUPAL
        begin
            select 'INS_PROCESO'   = dd_inst_proceso,
                   'CLIENTE'       = dd_cliente,
                   'GRUPO'         = dd_grupo,
                   'FECHA'         = dd_fecha,
                   'NOMBRE'        = dp_detalle,
                   'CARGADO'       = dd_cargado,
                   'CODIGO'        = dd_codigo,
                   'EXTENSION'     = trim(dd_extension),
                   'REQUERIDO'     = dp_requerido,
                   'DESCARGA'      = 'S',
                   'SUBIDA'        = 'S',
                   'TAMANIO'       = dp_tamanio
            from   cl_documento_digitalizado
            inner join cl_documento_parametro on dp_tipo = @i_tipo and dp_producto = dd_producto and dp_codigo = dd_codigo and dp_estado = 'V'
            where  dd_cliente      = @i_cliente
            and    dd_inst_proceso = @i_inst_proceso
            and    dd_grupo        = @i_grupo
            and    dd_producto     = @i_producto
            and    dd_tipo         = @i_tipo
            order by 9 desc , 6 desc , isnull(5,7)
            return 0
        end
        return 0
    end
    return 0
end -- @i_operacion = 'Q'


if @i_operacion = 'I' -- INSERTA O ACTUALIZA LA PARAMETRIZACION DOCUMENTOS
begin
    set @i_tipo = trim(@i_tipo)
    set @i_producto = trim(@i_producto)
    set @i_codigo   = trim(@i_codigo)

    if @i_modo = 0 -- INSERTA
    begin
        if exists ( select 1
                    from   cl_documento_parametro
                    where  dp_tipo     = @i_tipo
                    and    dp_producto = @i_producto
                    and    dp_codigo   = @i_codigo )
        begin
            set @w_error = 1720328 -- YA existe ese Registro
            goto ERROR
        end

        insert into  cl_documento_parametro
               (dp_tipo, dp_producto, dp_codigo, dp_detalle, dp_requerido, dp_tamanio, dp_estado)
        values (@i_tipo, @i_producto, @i_codigo, @i_detalle, @i_requerido, @i_tamanio, 'V')
        if @@rowcount!=1
        begin
            set @w_error = 1720329 -- Error en creacion de Documento
            goto ERROR
        end
        return 0
    end -- @i_modo = 0

    if @i_modo = 1 -- ACTUALIZA
    begin
        if exists ( select 1
                    from   cl_documento_digitalizado
                    where  dd_tipo     = @i_tipo
                    and    dd_producto = @i_producto
                    and    dd_codigo   = @i_codigo )
        begin
            if @i_codigo != @i_codigo2
            begin
                set @w_error = 1720330 -- EXISTEN DEPENDENCIAS DE OTRAS FUNCIONALIDADES CON ESTA FUNCIONALIDAD
                goto ERROR
            end
        end

        begin TRAN
        update cl_documento_parametro
        set    dp_codigo   = @i_codigo2,
               dp_detalle  = @i_detalle,
               dp_requerido= @i_requerido,
               dp_tamanio  = @i_tamanio
        where  dp_tipo     = @i_tipo
        and    dp_producto = @i_producto
        and    dp_codigo   = @i_codigo
        if @@rowcount!=1
        begin
            rollback TRAN
            set @w_error = 1720331 --Error en actualizacion de Documento Temporal
            goto ERROR
        end
        commit
        return 0
    end -- @i_modo = 1

    if @i_modo = 2 -- CAMBIA ESTADO
    begin
        if not exists ( select 1
                        from   cl_documento_parametro
                        where  dp_tipo     = @i_tipo
                        and    dp_producto = @i_producto
                        and    dp_codigo   = @i_codigo )
        begin
            set @w_error = 1720332 -- Documento de empresa consultado no existe
            goto ERROR
        end

        select @w_estado = case dp_estado when 'V' then 'A' else 'V' end -- A=ANULADO , V=VIGENTE
        from   cl_documento_parametro
        where  dp_tipo     = @i_tipo
        and    dp_producto = @i_producto
        and    dp_codigo   = @i_codigo

        begin TRAN
        update cl_documento_parametro
        set    dp_estado   = @w_estado
        where  dp_tipo     = @i_tipo
        and    dp_producto = @i_producto
        and    dp_codigo   = @i_codigo
        if @@rowcount!=1
        begin
            rollback TRAN
            set @w_error = 1720333 -- ERROR AL ACTUALIZAR ESTADO DE UNO O VARIOS REGISTROS
            goto ERROR
        end
        commit
        return 0
    end -- @i_modo = 2


    if @i_modo = 3 -- ACTUALIZA ACTIVIDAD
    begin
        if exists ( select 1
                    from   cl_documento_actividad
                    where  da_tipo     = @i_tipo
                    and    da_producto = @i_producto
                    and    da_codigo   = @i_codigo
                    and    da_actividad= @i_actididad )
        begin
            begin TRAN
            update cl_documento_actividad
            set    da_visible   = @i_visible,
                   da_requerido = @i_requerido,
                   da_descarga  = @i_descarga,
                   da_subida    = @i_subida
            where  da_tipo      = @i_tipo
            and    da_producto  = @i_producto
            and    da_codigo    = @i_codigo
            and    da_actividad = @i_actididad
            if @@rowcount!=1
            begin
                rollback TRAN
                set @w_error = 1720334 -- Error en actualización de actividad
                goto ERROR
            end
            commit
            return 0
        end
        else
        begin
            begin TRAN
            insert into cl_documento_actividad ( da_tipo    , da_producto  , da_codigo   , da_actividad ,
                                                 da_visible , da_requerido , da_descarga , da_subida )
            values ( @i_tipo    , @i_producto  , @i_codigo   , @i_actididad ,
                     @i_visible , @i_requerido , @i_descarga , @i_subida )
            if @@rowcount!=1
            begin
                rollback TRAN
                set @w_error = 1720335 -- Error en creación de actividad
                goto ERROR
            end
            commit
            return 0
        end
    end -- @i_modo = 3

    return 0
end -- @i_operacion = 'I'


if @i_operacion = 'S' -- BUSQUEDAS
begin
    set @i_tipo = trim(@i_tipo)
    set @i_producto = trim(@i_producto)
    set @i_codigo   = trim(@i_codigo)
    if @i_modo = 0 -- BUSQUEDA POR TIPO Y PRODUCTO
    begin
        select 'CODIGO'    = dp_codigo,
               'DETALLE'   = dp_detalle,
               'REQUERIDO' = dp_requerido,
               'TAMANIO'   = dp_tamanio,
               'ESTADO'    = dp_estado,
               'PRODUCTO'  = dp_producto,
               'TIPO'      = dp_tipo
        from   cl_documento_parametro
        where  dp_tipo     = @i_tipo
        and    dp_producto = @i_producto
        return 0
    end -- @i_modo = 0
    if @i_modo = 1 -- BUSQUEDA DETALLE DE DOCUMENTO POR ETAPA
    begin
        declare @w_actividad TABLE ( CODIGO int, ACTIVIDAD descripcion )

        insert into @w_actividad
        select distinct ac_codigo_actividad , ac_nombre_actividad
        from cob_workflow..wf_actividad
        inner join cob_workflow..wf_actividad_proc on ar_codigo_actividad = ac_codigo_actividad and ar_func_asociada is not null
        inner join cob_workflow..wf_proceso on ar_codigo_proceso = pr_codigo_proceso and pr_nemonico = 'SCITCE' and pr_producto = 'CCA'
        order by ac_codigo_actividad

        insert into @w_actividad
        values (-2,'CARTERA - Consulta de Datos Generales')

        select 'CODIGO'    = CODIGO,
               'ACTIVIDAD' = ACTIVIDAD,
               'VISIBLE'   = isnull(da_visible,'N'),
               'REQUERIDO' = isnull(da_requerido,'N'),
               'DESCARGA'  = isnull(da_descarga,'N'),
               'SUBIDA'    = isnull(da_subida,'N')
        from @w_actividad
        left join cl_documento_actividad on da_actividad = CODIGO and da_tipo = @i_tipo and da_producto = @i_producto and da_codigo = @i_codigo
        order by CODIGO
        return 0
    end -- @i_modo = 1

    return 0
end -- @i_operacion = 'S'

if @i_operacion = 'D' -- ELIMINAR
begin
    set @i_tipo = trim(@i_tipo)
    set @i_producto = trim(@i_producto)
    set @i_codigo   = trim(@i_codigo)
    if @i_modo = 0
    begin
        if not exists ( select 1
                        from   cl_documento_parametro
                        where  dp_tipo     = @i_tipo
                        and    dp_producto = @i_producto
                        and    dp_codigo   = @i_codigo )
        begin
            set @w_error = 1720336 -- Documento de empresa consultado no existe
            goto ERROR
        end

        if exists ( select 1
                    from   cl_documento_digitalizado
                    where  dd_tipo     = @i_tipo
                    and    dd_producto = @i_producto
                    and    dd_codigo   = @i_codigo )
        begin
            set @w_error = 1720337 --NO ES POSIBLE ELIMINAR EL REQUISITO PUESTO QUE TIENE INFORMACION ASOCIADA EN LA CARGA DE DOCUMENTOS
            goto ERROR
        end

        begin TRAN
        delete cl_documento_parametro
        where  dp_tipo     = @i_tipo
        and    dp_producto = @i_producto
        and    dp_codigo   = @i_codigo
        if @@rowcount!=1
        begin
            rollback TRAN
            set @w_error = 707022 -- Error en eliminacion de Documento
            goto ERROR
        end
        commit
        return 0
    end -- @i_modo = 0
end -- @i_operacion = 'D'


return 0

ERROR:
    begin --Devolver mensaje de Error
        print 'ERROR' + convert(varchar, isnull(@w_error, -1))
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = @w_error
        return @w_error
    end

--Proceso de sincronizacion Clientes
SINC:
   begin
      select @w_sincroniza = pa_char
      from cobis..cl_parametro
      where pa_producto = 'CLI'
      and pa_nemonico = 'HASIAU'
      
      select @w_ofi_app = pa_smallint 
      from cobis.dbo.cl_parametro cp 
      where cp.pa_nemonico = 'OFIAPP'
      and cp.pa_producto = 'CRE'
      
      if @i_operacion in ('U') and @i_cliente is not null and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
      begin
         exec @w_error = cob_sincroniza..sp_sinc_arch_json
            @i_opcion     = 'I',
            @i_cliente    = @i_cliente,
            @t_debug      = @t_debug
            
         if @w_error <> 0 and @w_error is not null
         begin
           goto ERROR
         end
         RETURN 0
      end
   end
go
