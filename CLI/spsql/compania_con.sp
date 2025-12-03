/************************************************************************/
/*  Archivo:            compania_con.sp                                 */
/*  Stored procedure:   sp_compania_cons                                */
/*  Base de datos:      cobis                                           */
/*  Producto:           CLIENTES                                        */
/*  Disenado por:       RIGG                                            */
/*  Fecha de escritura: 30-Abr-2019                                     */
/************************************************************************/
/*              IMPORTANTE                                              */
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
/*              PROPOSITO                                               */
/*  Este stored procedure procesa:                                      */
/*  Query de datos de compania                                          */
/*  Query de nombre completo de compania                                */
/************************************************************************/
/*               MODIFICACIONES                                         */
/*   FECHA          AUTOR                RAZON                          */
/*   30/Abr/2019    RIGG                 VersiÛn Inicial Te Creemos     */
/*   06/Jun/2019    ALD                  Se agrega operacion E para     */
/*                                       consulta de datos economicos   */
/*   08/Jul/2020    NRO                  Se agrega operacion F para     */
/*                                       datos de residencia fiscal     */
/*   08/Jul/2020    FSAP                 Estandarizacion Clientes       */
/************************************************************************/

use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select
             1
           from   sysobjects
           where  name = 'sp_compania_cons')
  drop proc sp_compania_cons
go

create proc sp_compania_cons
(
  @s_ssn              int = null,
  @s_user             login = null,
  @s_term             varchar(30) = null,
  @s_date             datetime = null,
  @s_srv              varchar(30) = null,
  @s_lsrv             varchar(30) = null,
  @s_ofi              smallint = null,
  @s_rol              smallint = null,
  @s_org_err          char(1) = null,
  @s_error            int = null,
  @s_sev              tinyint = null,
  @s_msg              descripcion = null,
  @s_org              char(1) = null,
  @t_debug            char(1) = 'N',
  @t_file             varchar(10) = null,
  @t_from             varchar(32) = null,
  @t_trn              int = null,
  @t_show_version     bit = 0,
  @i_operacion        char(1),
  @i_compania         int = null,
  @i_nombre           descripcion = null,
  @i_actividad        catalogo = null,
  @i_posicion         catalogo = null,
  @i_ruc              numero = null,
  @i_grupo            int = null,
  @i_rep_legal        int = null,
  @i_activo           money = null,
  @i_pasivo           money = null,
  @i_pais             smallint = null,
  @i_filial           tinyint = null,
  @i_oficina          smallint = null,
  @i_tipo             catalogo = null,
  @i_oficial          smallint = null,
  @i_es_grupo         char(1) = 'N',
  @i_comentario       varchar(254) = null,
  @i_retencion        char(1) = null,
  @i_asosciada        catalogo = null,
  @i_tipo_vinculacion catalogo = null,
  @i_tipo_nit         char(2) = null,
  @i_fecha_emision    datetime = null,
  @i_lugar_doc        int = null,
  @i_total_activos    money = null,
  @i_num_empleados    smallint = null,
  @i_sigla            varchar(25) = null,
  @i_oficial_sup      smallint = null,
  @i_exc_sipla        char(1) = null,
  @i_exc_por2         char(1) = null,
  @i_nivel_ing        money = null,
  @i_nivel_egr        money = null,
  @i_tipo_productor   catalogo = null,/* gsr Oct29/2002 */
  @i_impuesto_vtas    char(1) = null,
  @o_siguiente        int = null out,
  @o_dif_oficial      tinyint = null out
)
as
declare
  @w_today                 datetime,
  @w_sp_name               varchar(32),
  @w_sp_msg                varchar(132),
  @w_return                int,
  @o_es_grupo              char(1),
  @o_nombre                varchar(50),
  @o_actividad             catalogo,
  @o_posicion              catalogo,
  @o_tcompania             catalogo,
  @o_ruc                   numero,
  @o_ced_ruc               numero,
  @o_grupo                 int,
  @o_rep_legal             int,
  @o_pais                  smallint,
  @o_comentario            varchar(254),
  @o_oficial               smallint,
  @o_retencion             char(1),
  @o_tipo_vinculacion      catalogo,
  @o_desc_tipo_vinculacion descripcion,
  @o_mala_ref              char(1),
  @o_desc_act              descripcion,
  @o_desc_posi             descripcion,
  @o_desc_grupo            descripcion,
  @o_desc_func             descripcion,
  @o_desc_rep              descripcion,
  @o_desc_tcomp            descripcion,
  @o_nacionalidad          descripcion,
  @o_desc_lugar            descripcion,
  @o_fecha_crea            char(10),
  @o_cod_sector            catalogo,
  @o_sector                descripcion,
  @o_cod_tip_soc           catalogo,
  @o_tip_soc               descripcion,
  @o_tipo_nit              char(2),
  @o_cod_referido          smallint,
  @o_desc_referido         descripcion,
  @o_fecha_mod             char(10),
  @o_fecha_emision         char(10),
  @o_lugar_doc             int,
  @o_total_activos         money,
  @o_num_empleados         smallint,
  @o_sigla                 varchar(25),
  @o_rep_superban          char(1),
  @o_doc_validado          char(1),
  @o_gran_contribuyente    char(1),
  @o_situacion_cliente     catalogo,
  @o_patrim_tec            money,
  @o_fecha_patrimbruto     char(10),
  @o_desc_situacion_clie   varchar(25),
  @o_oficial_sup           smallint,
  @o_desc_func_sup         descripcion,
  @o_preferen              char(1),/* PREFE */
  @o_exc_sipla             char(1),
  @o_exc_por2              char(1),
  @o_nivel_ing             money,
  @o_nivel_egr             money,
  @o_tipo_productor        catalogo,/* gsr 29/Oct/2002 */
  @o_desc_tipo_productor   descripcion,/* gsr 29/Oct/2002 */
  @w_desc_tipo_productor   descripcion,/* gsr 29/Oct/2002 */
  @o_regimen_fiscal        catalogo,/* DDU  05/Nov/2002 */
  @o_des_regimen_fiscal    descripcion,/* DDU 05/Nov/2002 */
  @o_impuesto_vtas         char(1),
  @o_tipo_persona          char(3),/* EAL FEB/2009 REQ001*/
  @w_regimen_fiscal        catalogo,/* DDU  05/Nov/2002 */
  @w_des_regimen_fiscal    descripcion,/* DDU 05/Nov/2002 */
  @w_categoria             catalogo,/* jal feb 01 */
  @w_des_cate              descripcion,/* jal feb 01 */
  @w_total_pasivos         money,/*RIA01 */
  @w_oficina               smallint,
  @w_oficina_origen        smallint,
  @w_des_oficina           descripcion,
  @w_ofi_prod              smallint,
  @w_des_ofiprod           varchar(40),
  @w_filial                int,
  @w_rioe                  char(1),
  @w_pas_finan             money,
  @w_fpas_finan            datetime,
  @w_relinter              char(1),/* GustavoC */
  @w_cli_vip_A             catalogo,--CAMBIO LNP Jul. 2005
  @w_cli_vip_B             catalogo,--CAMBIO LNP Jul. 2005
  @w_otringr               descripcion,
  @w_doctos_carpeta        char(1),-- FCP 20/NOV/2005 REQ 445
  @w_exento_cobro          char(1),--Req. 880 Exento de Cobro
  @w_sgp                   catalogo,
  @w_vigencia              catalogo,
  @w_fatca                 char(1),
  @w_crs                   char(1),
  @w_s_inversion_ifi       char(1), 
  @w_s_inversion           char(1), 
  @w_ifid                  char(1), 
  @w_c_merc_valor          char(1),
  @w_c_nombre_merc_valor   varchar(100), 
  @w_ong_sfl               char(1),
  @w_ifi_np                char(1),
  @w_representante         varchar(100),
  @w_pais                  int,
  @w_pais_local            int,
  @w_nit_desc              varchar(100),
  @w_loc_pais              char(1),
  @w_nit_repre             varchar(100),
  @w_nro_ciclo             int
  --ream 05.abr.2010 control vigencia de datos del ente

select
  @w_today = getdate()
select
  @w_sp_name = 'sp_compania_cons'
  --Version/*  22/May/2009   E.Laguna              Caso 301 cambia 3x1000          */

/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_compania_upd'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/



if @i_operacion = 'Q'
/* datos completos de compania */
begin
  if @t_trn = 172109
  begin
    select
      @o_nombre = en_nombre,
      @o_actividad = en_actividad,
      @o_posicion = c_posicion,
      @o_ruc = en_ced_ruc,
      @o_es_grupo = c_es_grupo,
      @o_grupo = en_grupo,
      @o_oficial = en_oficial,
      @o_tcompania = c_tipo_compania,
      @o_pais = en_pais,
      @o_retencion = en_retencion,
      @o_mala_ref = en_mala_referencia,
      @o_comentario = en_comentario,
      @o_fecha_crea = convert(char(10), en_fecha_crea, 101),
      @o_fecha_mod = convert(char(10), en_fecha_mod, 101),
      @o_tipo_vinculacion = en_tipo_vinculacion,
      @o_cod_sector = en_sector,
      @o_cod_referido = en_referido,
      @o_tipo_nit = en_tipo_ced,/*M. Silva. Bco Estado */
      @o_cod_tip_soc = c_tipo_soc,
      @o_fecha_emision = convert(char(10), p_fecha_emision, 101),
      @o_lugar_doc = p_lugar_doc,
      @o_total_activos = c_total_activos,
      @o_num_empleados = c_num_empleados,
      @o_sigla = c_sigla,
      @o_rep_superban = en_rep_superban,
      @o_doc_validado = en_doc_validado,
      @o_gran_contribuyente = en_gran_contribuyente,
      @o_situacion_cliente = en_situacion_cliente,
      @o_patrim_tec = en_patrimonio_tec,
      @o_fecha_patrimbruto = convert(char(10), en_fecha_patri_bruto, 101),
      @o_oficial_sup = en_oficial_sup,
      @o_preferen = en_preferen,
      @o_exc_sipla = en_exc_sipla,
      @o_nivel_ing = p_nivel_ing,
      @o_nivel_egr = p_nivel_egr,
      @o_exc_por2 = en_exc_por2,
      @o_tipo_productor = en_casilla_def,/* GSR */
      @w_categoria = en_categoria,/*JAL*/
      @w_total_pasivos = c_total_pasivos,
      @o_regimen_fiscal = en_asosciada,/* DDU (55 mapeo arreglo)*/
      @w_oficina_origen = en_oficina,
      @w_filial = en_filial,
      @w_rioe = en_rep_sib,
      @o_impuesto_vtas = en_reestructurado,
      @w_pas_finan = en_pas_finan,
      @w_fpas_finan = en_fpas_finan,
      @w_relinter = en_relacint,/* Gustavoc */
      @w_otringr = en_otringr,
      @w_doctos_carpeta = en_doctos_carpeta,--FCP 20/NOV/2005 REQ 445
      @w_exento_cobro = en_exento_cobro,
      @w_sgp = convert(char(1), s_tipo_soc_hecho),
      @o_tipo_persona = p_tipo_persona,
      @w_vigencia = c_vigencia,
      -- ream 05.abr.2010 control vigencia de datos del ente
      @w_ofi_prod = en_oficina_prod,
      @w_nro_ciclo = isnull(en_nro_ciclo,0)
    from   cl_ente
    where  en_ente    = @i_compania
       and en_subtipo = 'C'
    /* si no se traen datos, error */
    if @@rowcount = 0
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720079
      /* 'No existe dato solicitado'*/
      return 1
    end

    select
      @w_des_oficina = of_nombre
    from   cl_oficina
    where  of_filial  = @w_filial
       and of_oficina = @w_oficina_origen
    if @@rowcount = 0
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720112
      /*  'No existe dato solicitado'*/
      return 1
    end

    /*if @o_posicion is not null
    begin
        begin
            select  @o_desc_posi = valor
            from    cl_catalogo, cl_tabla
            where   cl_tabla.tabla = 'cl_calif_cliente'
            and cl_catalogo.tabla  = cl_tabla.codigo
            and cl_catalogo.codigo = @o_posicion
        end
        if @@rowcount = 0
        begin
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 101172
            /* 'No existe dato solicitado'*/
         return 1
        end
    end
    */
    if @o_cod_sector is not null
    begin
      select
        @o_sector = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_sector_economico'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @o_cod_sector
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720042
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_grupo is not null
    begin
      select
        @o_desc_grupo = gr_nombre
      from   cl_grupo
      where  gr_grupo = @o_grupo
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720339
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    /*
    if @o_lugar_doc is not null
    begin
        select  @o_desc_lugar = ci_descripcion
        from    cl_ciudad
        where   ci_ciudad = @o_lugar_doc
        if @@rowcount = 0
        begin
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 101024
            /* 'No existe dato solicitado'*/
         return 1
        end
    end
    */

    if @o_tipo_vinculacion is not null
    begin
      select
        @o_desc_tipo_vinculacion = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_relacion_banco'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @o_tipo_vinculacion
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720037
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_oficial is not null
    begin
      select
        @o_desc_func = fu_nombre
      from   cl_funcionario,
             cc_oficial
      where  oc_oficial     = @o_oficial
         and oc_funcionario = fu_funcionario
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720037
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_oficial_sup is not null
    begin
      select
        @o_desc_func_sup = fu_nombre
      from   cl_funcionario,
             cc_oficial
      where  oc_oficial     = @o_oficial_sup
         and oc_funcionario = fu_funcionario
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720161
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_cod_referido is not null
    begin
      select
        @o_desc_referido = fu_nombre
      from   cl_funcionario
      where  fu_funcionario = @o_cod_referido
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720040
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_pais is not null
    begin
      select
        @o_nacionalidad = pa_descripcion
      from   cl_pais
      where  pa_pais = @o_pais
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720027
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    else
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720027
      /* 'No existe dato solicitado'*/
      return 1
    end

    if @o_tipo_productor is null
      select
        @o_desc_tipo_productor = null
    if @o_tipo_productor is not null
    begin
      select
        @w_desc_tipo_productor = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_tipo_productor'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @o_tipo_productor
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720162
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_regimen_fiscal is null
      select
        @o_des_regimen_fiscal = null
    if @o_regimen_fiscal is not null
    begin
      select
        @w_des_regimen_fiscal = rf_descripcion
      from   cob_conta..cb_regimen_fiscal
      where  rf_codigo = @o_regimen_fiscal
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720341
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_tcompania is not null
    begin
      select
        @o_desc_tcomp = c1.valor
      from   cl_catalogo c1,
             cl_tabla t1
      where  c1.codigo = @o_tcompania
         and c1.tabla  = t1.codigo
         and t1.tabla  = 'cl_nat_jur'
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720344
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_cod_tip_soc is not null
    begin
      select
        @o_tip_soc = c2.valor
      from   cl_catalogo c2,
             cl_tabla t2
      where  c2.tabla  = t2.codigo
         and c2.codigo = @o_cod_tip_soc
         and t2.tabla  = 'cl_tip_soc'
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720345
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    if @o_actividad is not null
    begin
      select
        @o_desc_act = c3.valor
      from   cl_catalogo c3,
             cl_tabla t3
      where  c3.codigo = @o_actividad
         and c3.tabla  = t3.codigo
         and t3.tabla  = 'cl_actividad_ec'
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720059
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_situacion_cliente is not null
    begin
      select
        @o_desc_situacion_clie = n1.valor
      from   cl_catalogo n1,
             cl_tabla t4
      where  n1.codigo = @o_situacion_cliente
         and n1.tabla  = t4.codigo
         and t4.tabla  = 'cl_situacion_cliente'
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720074
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @w_categoria is not null
    begin
      select
        @w_des_cate = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_tipo_cliente'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @w_categoria
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720348
        ---- 'No existe dato solicitado'
        return 1
      end

      -- PARAMETROS GENERALES PARA EVALUAR CLIENTE VIP    --CAMBIO LNP Jun. 2005
      select
        @w_cli_vip_A = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'ADM'
         and pa_nemonico = 'CLVIPA'
      --at isolation read uncommitted

      select
        @w_cli_vip_B = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'ADM'
         and pa_nemonico = 'CLVIPB'
    --at isolation read uncommitted
    end
    if @w_ofi_prod is null
      select
        @w_des_ofiprod = null
    else
    begin
      select
        @w_des_ofiprod = of_nombre
      from   cl_oficina
      where  of_filial  = @w_filial
         and of_oficina = @w_ofi_prod

      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720112 /*  'No existe Oficina'*/
        return 1
      end
    end

    select
      'Fecha Creaci¢n ' = @o_fecha_crea,
      'Tipo de Documento ' = @o_tipo_nit,
      'No. D. I.   ' = @o_ruc,
      'Sigla   ' = @o_sigla,
      'Nombre  ' = @o_nombre,
      'Cod. Actividad ' = @o_actividad,
      'Actividad      ' = @o_desc_act,
      'Cod. Sector Eco. ' = @o_cod_sector,
      'Sector Econ¢mico ' = @o_sector,
      'Cod. Tipo Sociedad ' = @o_cod_tip_soc,
      'Tipo de Sociedad ' = @o_tip_soc,
      'Cod.Nat. Juridica ' = @o_tcompania,
      'Tipo Nat. Juridica ' = @o_desc_tcomp,
      'Nacionalidad  ' = @o_nacionalidad,
      'Cod. Rel. con el Banco ' = @o_tipo_vinculacion,
      'Relaci¢n con el Banco. ' = @o_desc_tipo_vinculacion,
      'Cod. Presentado por    ' = @o_cod_referido,
      'Nombre Presentado  ' = @o_desc_referido,
      'Total Activos  ' = @o_total_activos,
      'N£mero de Empleados ' = @o_num_empleados,
      'Retenci¢n  ' = @o_retencion,
      'Comentarios  ' = @o_comentario,
      'Reportado SuperBan. ' = @o_rep_superban,
      'Documento Validado  ' = @o_doc_validado,
      'Cod. del Oficial    ' = @o_oficial,
      'Nombre del Oficial  ' = @o_desc_func,
      'Fecha Modificaci¢n ' = @o_fecha_mod,
      'Cod. Calificaci¢n  ' = @o_posicion,
      'Calificaci¢n ' = @o_desc_posi,
      'Es Grupo   ' = @o_es_grupo,
      'Cod. Grupo ' = @o_grupo,
      'Nombre Grupo ' = @o_desc_grupo,
      'Cod. Pais    ' = @o_pais,
      'Mala Referencia  ' = @o_mala_ref,
      'Fecha Emisi¢n Doc. ' = @o_fecha_emision,
      'Cod. Lugar Doc. ' = @o_lugar_doc,
      'Lugar Documento ' = @o_desc_lugar,
      'Grandes Contribuyts ' = @o_gran_contribuyente,
      'Situaci¢n Cliente  ' = @o_situacion_cliente,
      'Desc.Situac.Cliente ' = @o_desc_situacion_clie,
      'Patrimonio Bruto   ' = @o_patrim_tec,
      'Fecha Patrim-Bruto ' = @o_fecha_patrimbruto,
      'Cliente Preferencial ' = @o_preferen,
      'Excento Rep. Sipla  ' = @o_exc_sipla,
      'Ingresos   ' = @o_nivel_ing,/*(45)*/
      'Egresos    ' = @o_nivel_egr,/*(46)*/
      'Excento 3o/000  ' = @o_exc_por2,
      'Categoria  ' = @w_categoria,/* 48 JAL */
      'Desc.Categoria ' = @w_des_cate,
      'Total Pasivos' = @w_total_pasivos,/* RIA01 50 */
      'Cod Oficina Origen ' = @w_oficina_origen,/*INNAC */
      'Oficina Origen ' = @w_des_oficina,/* INNAC */
      'Cod Tipo Productor  ' = @o_tipo_productor,/* GSR */
      'Desc Tipo Productor ' = @w_desc_tipo_productor,/* GSR */
      'Cod Regimen Fiscal  ' = @o_regimen_fiscal,/* DDU */
      'Desc Regimen Fiscal ' = @w_des_regimen_fiscal,/* DDU */
      'Exento de RIOE  ' = @w_rioe,
      'Declara Impuesto Renta ' = @o_impuesto_vtas,
      'Endeudamiento Sector Finan.' = @w_pas_finan,
      'Fecha End. Sector Finan.' = convert(varchar(10), @w_fpas_finan, 101),
      'Maneja Op.Internacionales' = @w_relinter,/* GustavoC */
      'Cliente VIP A  ' = @w_cli_vip_A,--CAMBIO LNP Jun. 2005
      'Cliente VIP B  ' = @w_cli_vip_B,--CAMBIO LNP Jun. 2005
      'Ingresos no Operacionales' = @w_otringr,
      'Exento Cobro' = @w_exento_cobro,
      'Documentos en Carpeta' = @w_doctos_carpeta,--FCP 20/NOV/2005 REQ 445
      'Sist Gral participaciones' = @w_sgp,--req credito mallas
      'Tipo de Persona ' = @o_tipo_persona,
      'Datos Vigentes' = @w_vigencia,
      --ream 05.abr.2010 control vigencia de datos del ente
      'Ofi prod' = @w_ofi_prod,/* Pos 70 */
      'Des ofiprod' = @w_des_ofiprod, /* Pos 71 */
      'Nro ciclo'   = @w_nro_ciclo

  end
  else if @t_trn = 1218
  begin

  --Nombre representante y numero
  select @w_representante = en_nomlar,
  @w_nit_repre = en_ced_ruc
  from cl_ente 
  where en_ente = (select c_rep_legal from cl_ente where en_ente = @i_compania)

  --pais
  select @w_pais = en_pais
  from cl_ente 
  where en_ente = @i_compania

  select @w_pais_local = pa_smallint 
  from cl_parametro 
  where pa_nemonico = 'CP' 
  and pa_producto = 'CLI'

  select @w_loc_pais = (case @w_pais when @w_pais_local then 'N' else 'E' end)

  select @w_nit_desc = ti_descripcion
  from cl_tipo_identificacion, cl_ente
  where ti_tipo_cliente = 'C'
  and ti_tipo_documento = 'T'
  and ti_nacionalidad = @w_loc_pais
  and en_ente = @i_compania
  and en_tipo_ced = ti_codigo

  

     select NULL,
            en_tipo_ced,
            en_ced_ruc,
            en_nombre,
            en_nombre,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            en_retencion,
            en_comentario,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            en_pais,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,--'sipla',
            NULL,--'revenues',
            NULL,--'expenses',
            NULL,
            NULL,
            NULL,
            NULL, 
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            @w_nit_desc,
            NULL,
            NULL,
            NULL,
            NULL,
            en_nit,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            c_rep_legal,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            @w_nit_repre,--notary
            NULL, 
            NULL, 
            NULL,
            @w_representante
     from cl_ente a
     where a.en_ente = @i_compania

  end
  else
  begin
    exec sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1720075
    /*  'No corresponde codigo de transaccion' */
    return 1
  end
end

/* Help */
if @i_operacion = 'H'
begin
  if @t_trn = 172110
  begin
    select
      'Compania' = en_nombre
    from   cl_ente
    where  en_ente = @i_compania
    if @@rowcount = 0
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720349
      /*  'No existe dato solicitado'*/
      return 1
    end
    return 0
  end
  else
  begin
    exec sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1720075
    /*  'No corresponde codigo de transaccion' */
    return 1
  end
end

if @i_operacion = 'M'
begin
  if @t_trn = 172109
  begin
    select
      @o_nombre = en_nombre,
      @o_actividad = en_actividad,
      @o_posicion = c_posicion,
      @o_ruc = en_ced_ruc,
      @o_es_grupo = c_es_grupo,
      @o_grupo = en_grupo,
      @o_oficial = en_oficial,
      @o_tcompania = c_tipo_compania,
      @o_pais = en_pais,
      @o_retencion = en_retencion,
      @o_mala_ref = en_mala_referencia,
      @o_comentario = en_comentario,
      @o_fecha_crea = convert(char(10), en_fecha_crea, 101),
      @o_fecha_mod = convert(char(10), en_fecha_mod, 101),
      @o_tipo_vinculacion = en_tipo_vinculacion,
      @o_cod_sector = en_sector,
      @o_cod_referido = en_referido,
      @o_tipo_nit = en_tipo_ced,
      @o_cod_tip_soc = c_tipo_soc,
      @o_fecha_emision = convert(char(10), p_fecha_emision, 101),
      @o_lugar_doc = p_lugar_doc,
      @o_total_activos = c_total_activos,
      @o_num_empleados = c_num_empleados,
      @o_sigla = c_sigla,
      @o_rep_superban = en_rep_superban,
      @o_doc_validado = en_doc_validado,
      @o_gran_contribuyente = en_gran_contribuyente,
      @o_situacion_cliente = en_situacion_cliente,
      @o_patrim_tec = en_patrimonio_tec,
      @o_fecha_patrimbruto = convert(char(10), en_fecha_patri_bruto, 101),
      @o_oficial_sup = en_oficial_sup,
      @o_preferen = en_preferen,
      @o_exc_sipla = en_exc_sipla,
      @o_nivel_ing = p_nivel_ing,
      @o_nivel_egr = p_nivel_egr,
      @o_tipo_productor = en_casilla_def,/*GSR*/
      @w_regimen_fiscal = en_asosciada,/* DDU */
      @o_exc_por2 = en_exc_por2,
      @w_categoria = en_categoria,/*JAL*/
      @w_total_pasivos = c_total_pasivos,/*RIA01*/
      @w_rioe = en_rep_sib,
      @o_impuesto_vtas = en_reestructurado,
      @w_pas_finan = en_pas_finan,
      @w_fpas_finan = en_fpas_finan
    from   cl_ente
    where  en_ente    = @i_compania
       and en_subtipo = 'C'
    /* si no se traen datos, error */
    if @@rowcount = 0
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720074
      /* 'No existe dato solicitado'*/
      return 1
    end

    /*if @o_posicion is not null
    begin
        begin
            select  @o_desc_posi = valor
            from    cl_catalogo, cl_tabla
            where   cl_tabla.tabla = 'cl_calif_cliente'
            and cl_catalogo.tabla  = cl_tabla.codigo
            and cl_catalogo.codigo = @o_posicion
        end
        if @@rowcount = 0
        begin
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 101172
            /* 'No existe dato solicitado'*/
         return 1
        end
    end
    */
    if @o_cod_sector is not null
    begin
      select
        @o_sector = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_sector_economico'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @o_cod_sector
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720042
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_grupo is not null
    begin
      select
        @o_desc_grupo = gr_nombre
      from   cl_grupo
      where  gr_grupo = @o_grupo
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720339
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    /*if @o_lugar_doc is not null
    begin
        select  @o_desc_lugar = ci_descripcion
        from    cl_ciudad
        where   ci_ciudad = @o_lugar_doc
        if @@rowcount = 0
        begin
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
    
            @t_from     = @w_sp_name,
            @i_num      = 101024
            /* 'No existe dato solicitado'*/
         return 1
        end
    end*/

    if @o_tipo_vinculacion is not null
    begin
      select
        @o_desc_tipo_vinculacion = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_relacion_banco'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @o_tipo_vinculacion
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720037
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_oficial is not null
    begin
      select
        @o_desc_func = fu_nombre
      from   cl_funcionario,
             cc_oficial
      where  oc_oficial     = @o_oficial
         and oc_funcionario = fu_funcionario
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720037
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_oficial_sup is not null
    begin
      select
        @o_desc_func_sup = fu_nombre
      from   cl_funcionario,
             cc_oficial
      where  oc_oficial     = @o_oficial_sup
         and oc_funcionario = fu_funcionario
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720161
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_cod_referido is not null
    begin
      select
        @o_desc_referido = fu_nombre
      from   cl_funcionario
      where  fu_funcionario = @o_cod_referido
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720040
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_pais is not null
    begin
      select
        @o_nacionalidad = pa_descripcion
      from   cl_pais
      where  pa_pais = @o_pais
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720027
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    else
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720027
      /* 'No existe dato solicitado'*/
      return 1
    end

    select
      @o_desc_tcomp = c1.valor
    from   cl_catalogo c1,
           cl_tabla t1
    where  c1.codigo = @o_tcompania
       and c1.tabla  = t1.codigo
       and t1.tabla  = 'cl_nat_jur'
    if @@rowcount = 0
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720344
      /* 'No existe dato solicitado'*/
      return 1
    end

    select
      @o_tip_soc = c2.valor
    from   cl_catalogo c2,
           cl_tabla t2
    where  c2.tabla  = t2.codigo
       and c2.codigo = @o_cod_tip_soc
       and t2.tabla  = 'cl_tip_soc'
    if @@rowcount = 0
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720345
      /* 'No existe dato solicitado'*/
      return 1
    end

    select
      @o_desc_act = c3.valor
    from   cl_catalogo c3,
           cl_tabla t3
    where  c3.codigo = @o_actividad
       and c3.tabla  = t3.codigo
       and t3.tabla  = 'cl_actividad'
    if @@rowcount = 0
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720059
      /* 'No existe dato solicitado'*/
      return 1
    end

    if @o_situacion_cliente is not null
    begin
      select
        @o_desc_situacion_clie = n1.valor
      from   cl_catalogo n1,
             cl_tabla t4
      where  n1.codigo = @o_situacion_cliente
         and n1.tabla  = t4.codigo
         and t4.tabla  = 'cl_situacion_cliente'
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720347
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @w_categoria is not null
    begin
      select
        @w_des_cate = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_tipo_cliente'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @w_categoria
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720348
        ----'No existe dato solicitado'
        return 1
      end
    end

    if @o_tipo_productor is null
      select
        @o_desc_tipo_productor = null
    if @o_tipo_productor is not null
    begin
      select
        @o_desc_tipo_productor = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_tipo_productor'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @o_tipo_productor
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720162
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @w_regimen_fiscal is null
      select
        @w_des_regimen_fiscal = null
    if @w_regimen_fiscal is not null
    begin
      select
        @w_des_regimen_fiscal = rf_descripcion
      from   cob_conta..cb_regimen_fiscal
      where  rf_codigo = @w_regimen_fiscal
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720341
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    select
      'Fecha de Registro ' = @o_fecha_crea,
      'Tipo de Documento ' = @o_tipo_nit,
      'Numero Documento  ' = @o_ruc,
      'Sigla    ' = @o_sigla,
      'Raz¢n Social ' = @o_nombre,
      'Cod. Situaci¢n del Cliente ' = @o_situacion_cliente,
      'Situaci¢n del Cliente  ' = @o_desc_situacion_clie,
      'Cod. Actividad econ¢mica ' = @o_actividad,
      'Actividad Econ¢mica    ' = @o_desc_act,
      'Cod. Sector Econ¢mico. ' = @o_cod_sector,
      'Sector Econ¢mico       ' = @o_sector,
      'Cod. Naturaleza Jur°dica ' = @o_tcompania,
      'Naturaleza Jur°dica      ' = @o_desc_tcomp,
      'Cod Paçs  ' = @o_pais,
      'Pa°s   ' = @o_nacionalidad,
      'Cod. Tipo Sociedad ' = @o_cod_tip_soc,
      'Tipo Sociedad ' = @o_tip_soc,
      'Ingresos      ' = @o_nivel_ing,
      'Egresos       ' = @o_nivel_egr,
      'Total Activos ' = @o_total_activos,
      'Total Pasivos ' = @w_total_pasivos,
      'Patrimonio Bruto ' = @o_patrim_tec,
      'Fecha de Patrimonio Bruto  ' = convert(char(10), @o_fecha_patrimbruto,
                                      101)
      ,
      'N£mero de empleados    ' = @o_num_empleados,
      'Grandes contribuyentes ' = @o_gran_contribuyente,
      'Sujeto de Retenci¢n    ' = @o_retencion,
      'Cliente Preferencial ' = @o_preferen,
      'Excluir Reporte Sipla  ' = @o_exc_sipla,
      'Excento de 4x1000      ' = @o_exc_por2,
      'Presentado por     ' = @o_desc_referido,
      'Cod Relaci¢n con la Inst   ' = @o_tipo_vinculacion,
      'Relaci¢n con la Inst.  ' = @o_desc_tipo_vinculacion,
      'Cod de CalificaciΩn   ' = @o_posicion,
      'CalificaciΩn Cliente  ' = @o_desc_posi,
      'Es grupo?      ' = @o_es_grupo,
      'Cod Grupo EconΩmico ' = @o_grupo,
      'Grupo EconΩmico     ' = @o_desc_grupo,
      'Malas Referencias   ' = @o_mala_ref,
      'Gerente            ' = @o_oficial,
      'Nombre del Gerente ' = @o_desc_func,
      'Cod Tipo Productor     ' = @o_tipo_productor,/* GSR */
      'Desc. Tipo Productor   ' = @o_desc_tipo_productor,/* GSR */
      'Cod Regimen Fiscal ' = @w_regimen_fiscal,/* DDU */
      'Desc. Regimen Fiscal   ' = @w_des_regimen_fiscal,/* DDU */
      'Exento de RIOE         ' = @w_rioe,
      'Declara Impuesto Renta  ' = @o_impuesto_vtas,
      'Endeudamiento Sector Finan ' = @w_pas_finan,
      'Fecha End. Sector Finan    ' = convert(varchar(10), @w_fpas_finan, 101)

  end
  else
  begin
    exec sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1720075
    /*  'No corresponde codigo de transaccion' */
    return 1
  end
end

/*  consulta de todos los datos de una compania ATM */
if @i_operacion = 'V'
begin
  if @t_trn = 172109
  begin
    select
      @o_nombre = en_nombre,
      @o_actividad = en_actividad,
      @o_posicion = c_posicion,
      @o_ruc = en_ced_ruc,
      @o_es_grupo = c_es_grupo,
      @o_grupo = en_grupo,
      @o_oficial = en_oficial,
      @o_tcompania = c_tipo_compania,
      @o_pais = en_pais,
      @o_retencion = en_retencion,
      @o_mala_ref = en_mala_referencia,
      @o_comentario = en_comentario,
      @o_fecha_crea = convert(char(10), en_fecha_crea, 101),
      @o_fecha_mod = convert(char(10), en_fecha_mod, 101),
      @o_tipo_vinculacion = en_tipo_vinculacion,
      @o_cod_sector = en_sector,
      @o_cod_referido = en_referido,
      @o_tipo_nit = en_tipo_ced,
      @o_cod_tip_soc = c_tipo_soc,
      @o_fecha_emision = convert(char(10), p_fecha_emision, 101),
      @o_lugar_doc = p_lugar_doc,
      @o_total_activos = c_total_activos,
      @o_num_empleados = c_num_empleados,
      @o_sigla = c_sigla,
      @o_rep_superban = en_rep_superban,
      @o_doc_validado = en_doc_validado,
      @o_gran_contribuyente = en_gran_contribuyente,
      @o_situacion_cliente = en_situacion_cliente,
      @o_patrim_tec = en_patrimonio_tec,
      @o_fecha_patrimbruto = convert(char(10), en_fecha_patri_bruto, 101),
      @o_oficial_sup = en_oficial_sup,
      @o_preferen = en_preferen,
      @o_exc_sipla = en_exc_sipla,
      @o_nivel_ing = p_nivel_ing,
      @o_nivel_egr = p_nivel_egr,
      @o_exc_por2 = en_exc_por2,
      @o_tipo_productor = en_casilla_def,
      @w_categoria = en_categoria,
      @w_total_pasivos = c_total_pasivos,
      @o_regimen_fiscal = en_asosciada,
      @w_oficina_origen = en_oficina,
      @w_filial = en_filial,
      @w_rioe = en_rep_sib,
      @o_impuesto_vtas = en_reestructurado,
      @w_pas_finan = en_pas_finan,
      @w_fpas_finan = en_fpas_finan
    from   cl_ente
    where  en_ente    = @i_compania
       and en_subtipo = 'C'
    if @@rowcount = 0 /* si no se traen datos, error */
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720074
      /* 'No existe dato solicitado'*/
      return 1
    end

    select
      @w_des_oficina = of_nombre
    from   cl_oficina
    where  of_filial  = @w_filial
       and of_oficina = @w_oficina_origen
    if @@rowcount = 0
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720112
      /*  'No existe dato solicitado'*/
      return 1
    end

    /*if @o_posicion is not null
    begin
        begin
            select  @o_desc_posi = valor
            from    cl_catalogo, cl_tabla
            where   cl_tabla.tabla = 'cl_calif_cliente'
            and cl_catalogo.tabla  = cl_tabla.codigo
            and cl_catalogo.codigo = @o_posicion
        end
        if @@rowcount = 0
        begin
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 101172
            /* 'No existe dato solicitado'*/
         return 1
        end
    end
    */
    if @o_cod_sector is not null
    begin
      select
        @o_sector = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_sector_economico'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @o_cod_sector
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720042
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_grupo is not null
    begin
      select
        @o_desc_grupo = gr_nombre
      from   cl_grupo
      where  gr_grupo = @o_grupo
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720339
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    /*if @o_lugar_doc is not null
    begin
        select  @o_desc_lugar = ci_descripcion
        from    cl_ciudad
        where   ci_ciudad = @o_lugar_doc
        if @@rowcount = 0
        begin
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 101024
            /* 'No existe dato solicitado'*/
         return 1
        end
    end*/

    if @o_tipo_vinculacion is not null
    begin
      select
        @o_desc_tipo_vinculacion = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_relacion_banco'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @o_tipo_vinculacion
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720037
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_oficial is not null
    begin
      select
        @o_desc_func = fu_nombre
      from   cl_funcionario,
             cc_oficial
      where  oc_oficial     = @o_oficial
         and oc_funcionario = fu_funcionario
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720040
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_oficial_sup is not null
    begin
      select
        @o_desc_func_sup = fu_nombre
      from   cl_funcionario,
             cc_oficial
      where  oc_oficial     = @o_oficial_sup
         and oc_funcionario = fu_funcionario
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720161
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_cod_referido is not null
    begin
      select
        @o_desc_referido = fu_nombre
      from   cl_funcionario
      where  fu_funcionario = @o_cod_referido
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720040
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_pais is not null
    begin
      select
        @o_nacionalidad = pa_descripcion
      from   cl_pais
      where  pa_pais = @o_pais
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720027
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    else
    begin
      exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 1720027
      /* 'No existe dato solicitado'*/
      return 1
    end

    if @o_tipo_productor is null
      select
        @o_desc_tipo_productor = null
    if @o_tipo_productor is not null
    begin
      select
        @w_desc_tipo_productor = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_tipo_productor'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @o_tipo_productor
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720342
        /* 'No existe dato solicitado'*/
        return 1
      end
    end

    if @o_regimen_fiscal is null
      select
        @o_des_regimen_fiscal = null
    if @o_regimen_fiscal is not null
    begin
      select
        @w_des_regimen_fiscal = rf_descripcion
      from   cob_conta..cb_regimen_fiscal,
             cl_tabla
      where  cl_tabla.tabla = 'cb_regimen_fiscal'
         and rf_codigo      = @o_regimen_fiscal
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720343
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    if @o_tcompania is not null
    begin
      select
        @o_desc_tcomp = c1.valor
      from   cl_catalogo c1,
             cl_tabla t1
      where  c1.codigo = @o_tcompania
         and c1.tabla  = t1.codigo
         and t1.tabla  = 'cl_nat_jur'
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720344
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    if @o_cod_tip_soc is not null
    begin
      select
        @o_tip_soc = c2.valor
      from   cl_catalogo c2,
             cl_tabla t2
      where  c2.tabla  = t2.codigo
         and c2.codigo = @o_cod_tip_soc
         and t2.tabla  = 'cl_tip_soc'
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720345
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    if @o_actividad is not null
    begin
      select
        @o_desc_act = c3.valor
      from   cl_catalogo c3,
             cl_tabla t3
      where  c3.codigo = @o_actividad
         and c3.tabla  = t3.codigo
         and t3.tabla  = 'cl_actividad'
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720346
        /* 'No existe dato solicitado'*/
        return 1
      end
    end
    if @o_situacion_cliente is not null --REC
    begin
      select
        @o_desc_situacion_clie = n1.valor
      from   cl_catalogo n1,
             cl_tabla t4
      where  n1.codigo = @o_situacion_cliente
         and n1.tabla  = t4.codigo
         and t4.tabla  = 'cl_situacion_cliente'
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720347
        /* 'No existe dato solicitado'*/
        return 1
      end
    end --Fin REC

    if @w_categoria is not null
    begin
      select
        @w_des_cate = valor
      from   cl_catalogo,
             cl_tabla
      where  cl_tabla.tabla     = 'cl_tipo_cliente'
         and cl_catalogo.tabla  = cl_tabla.codigo
         and cl_catalogo.codigo = @w_categoria
      if @@rowcount = 0
      begin
        exec sp_cerror
          @t_debug = @t_debug,
          @t_file  = @t_file,
          @t_from  = @w_sp_name,
          @i_num   = 1720348
        ----'No existe dato solicitado'
        return 1
      end
    end

    select
      'Fecha Creaci¢n' = @o_fecha_crea,
      'Tipo de Documento' = @o_tipo_nit,
      'No. D. I.' = @o_ruc,
      'Sigla' = @o_sigla,
      'Nombre' = @o_nombre,
      'Cod. Actividad' = @o_actividad,
      'Actividad' = @o_desc_act,
      'Cod. Sector Eco.' = @o_cod_sector,
      'Sector Econ¢mico' = @o_sector,
      'Cod. Tipo Sociedad' = @o_cod_tip_soc,
      'Tipo de Sociedad' = @o_tip_soc,
      'Cod.Nat. Juridica' = @o_tcompania,
      'Tipo Nat. Juridica' = @o_desc_tcomp,
      'Nacionalidad' = @o_nacionalidad,
      'Cod. Rel. con el Banco' = @o_tipo_vinculacion,
      'Relaci¢n con el Banco.' = @o_desc_tipo_vinculacion,
      'Cod. Presentado por' = @o_cod_referido,
      'Nombre Presentado' = @o_desc_referido,
      'Total Activos' = @o_total_activos,
      'N£mero de Empleados' = @o_num_empleados,
      'Retenci¢n' = @o_retencion,
      'Comentarios' = @o_comentario,
      'Reportado SuperBan.' = @o_rep_superban,
      'Documento Validado' = @o_doc_validado,
      'Cod. del Oficial' = @o_oficial,
      'Nombre del Oficial' = @o_desc_func,
      'Fecha Modificaci¢n' = @o_fecha_mod,
      'Cod. Calificaci¢n' = @o_posicion,
      'Calificaci¢n' = @o_desc_posi,
      'Es Grupo' = @o_es_grupo,
      'Cod. Grupo' = @o_grupo,
      'Nombre Grupo' = @o_desc_grupo,
      'Cod. Pais' = @o_pais,
      'Mala Referencia' = @o_mala_ref,
      'Fecha Emisi¢n Doc.' = @o_fecha_emision,
      'Cod. Lugar Doc.' = @o_lugar_doc,
      'Lugar Documento' = @o_desc_lugar,
      'Grandes Contribuyts' = @o_gran_contribuyente,
      'Situaci¢n Cliente' = @o_situacion_cliente,
      'Desc.Situac.Cliente' = @o_desc_situacion_clie,
      'Patrimonio Bruto' = @o_patrim_tec,
      'Fecha Patrim-Bruto' = @o_fecha_patrimbruto,
      'Cliente Preferencial' = @o_preferen,
      'Excento Rep. Sipla' = @o_exc_sipla,
      'Ingresos' = @o_nivel_ing,
      'Egresos' = @o_nivel_egr,
      'Excento 3o/000' = @o_exc_por2,
      'Categoria' = @w_categoria,
      'Desc.Categoria' = @w_des_cate,
      'Total Pasivos' = @w_total_pasivos,
      'Cod Oficina Origen' = @w_oficina_origen,
      'Oficina Origen' = @w_des_oficina,
      'Cod Tipo Productor' = @o_tipo_productor,
      'Desc Tipo Productor' = @w_desc_tipo_productor,
      'Cod Regimen Fiscal' = @o_regimen_fiscal,
      'Desc Regimen Fiscal' = @w_des_regimen_fiscal,
      'Exento de RIOE     ' = @w_rioe,
      'Declara Impuesto Renta' = @o_impuesto_vtas,
      'Endeudamiento Sector Finan.' = @w_pas_finan,
      'Fecha End. Sector Finan.' = @w_fpas_finan,
      'Tipo de Persona ' = @o_tipo_persona

  end
  else
  begin
    exec sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1720075
    /*  'No corresponde codigo de transaccion' */
    return 1
  end
end

/* Help */
if @i_operacion = 'E'
begin
  if @t_trn = 172110
  begin
   if exists (select 1 from cobis..cl_ente_aux where ea_ente = @i_compania)
      begin
         select 
         'Ingresos Mensuales' = en_otros_ingresos,
         'Activos'                = c_total_activos,
         'Pasivos'                = c_pasivo, 
         'Gastos totales'     = ea_ct_ventas,
         'Gastos negocio'     = ea_ct_operativo,
         'Ventas'             = ea_ventas †††
       from cl_ente inner join cl_ente_aux on en_ente=ea_ente where en_ente=@i_compania
          if @@rowcount = 0
             begin
               exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 1720349
               /*  'No existe dato solicitado'*/
               return 1
             end
          return 0
     end
  else
     begin
         select 
         'Ingresos Mensuales' = en_otros_ingresos,
         'Activos'                = c_total_activos,
         'Pasivos'                = c_pasivo, 
         'Gastos totales'     = 0.00,
         'Gastos negocio'     = 0.00,
         'Ventas'             = 0.00
       from cl_ente 
      where en_ente=@i_compania
          if @@rowcount = 0
             begin
               exec sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 1720349
               /*  'No existe dato solicitado'*/
               return 1
             end
          return 0       
     end
  end
  else
  begin
    exec sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 1720075
    /*  'No corresponde codigo de transaccion' */
    return 1
  end
end
  
if @i_operacion = 'F' --  Datos de Residencia Fiscales-- 8/07/2020 NRO
begin
   --EVALUACION DEL TIPO DE TRANSACCION 
  if @t_trn <> 172110
    begin 
      /* Tipo de transaccion no corresponde */ 
      exec cobis..sp_cerror 
           @t_debug = @t_debug, 
           @t_file  = @t_file, 
           @t_from  = @w_sp_name,
           @i_num   = 1720075
      return 1720075
    end
  if exists (select ea_ente from cl_ente_aux where ea_ente=@i_compania)
  begin
    select @w_fatca               = aux.ea_fatca,
           @w_crs                 = aux.ea_crs,
           @w_s_inversion_ifi     = aux.ea_s_inversion_ifi,
           @w_s_inversion         = aux.ea_s_inversion,
           @w_ifid                = aux.ea_ifid, 
           @w_c_merc_valor        = aux.ea_c_merc_valor, 
           @w_c_nombre_merc_valor = aux.ea_c_nombre_merc_valor,
           @w_ong_sfl             = aux.ea_ong_sfl,
           @w_ifi_np              = aux.ea_ifi_np
           
      from cl_ente_aux aux
     where aux.ea_ente = @i_compania

    select 'pregunta1'          = @w_fatca,  -- 1
           'pregunta2'          = @w_crs,     -- 2,
           'question1'          = @w_s_inversion_ifi,  -- 3  
           'question2'          = @w_s_inversion,  -- 4      
           'question3'          = @w_ifid ,      -- 5        
           'question4'          = @w_c_merc_valor,   -- 6    
           'question5'          = @w_c_nombre_merc_valor, -- 7
           'question6'          = @w_ong_sfl,  -- 8          
           'question7'          = @w_ifi_np    -- 9          
           
  end

end

return 0


go
