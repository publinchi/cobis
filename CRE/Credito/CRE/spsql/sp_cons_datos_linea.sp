/************************************************************************/
/*  Archivo:                         sp_cons_datos_linea.sp             */
/*  Stored procedure:                sp_cons_datos_linea.sp             */
/*  Base de datos:                   cob_credito                        */
/*  Producto:                        Credito                            */
/*  Disenado por:                    PJA                                */
/*  Fecha de escritura:              22-11-2022                         */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                          PROPOSITO                                   */
/*  Consulta de Datos de Linea de Credito                               */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      22-11-2022      PJA             Emision Inicial - S736962       */
/************************************************************************/
use cob_credito
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_cons_datos_linea')
   drop proc sp_cons_datos_linea
go
CREATE PROCEDURE sp_cons_datos_linea (
        @s_ssn                           int          = null,
        @s_user                          login        = null,
        @s_term                          varchar(32)  = null,
        @s_sesn                          int          = null,
        @s_culture                       varchar(10)  = 'NEUTRAL',
        @s_date                          datetime     = null,
        @s_srv                           varchar(30)  = null,
        @s_lsrv                          varchar(30)  = null,
        @s_rol                           smallint     = NULL,
        @s_org_err                       char(1)      = NULL,
        @s_error                         int          = NULL,
        @s_sev                           tinyint      = NULL,
        @s_msg                           descripcion  = NULL,
        @s_org                           char(1)      = NULL,
        @s_ofi                           smallint     = NULL,
        @t_debug                         char(1)      = 'N',
        @t_file                          varchar(14)  = null,
        @t_from                          varchar(30)  = null,
        @t_trn                           int          = null,
        @t_show_version                  bit          = 0,
        @i_cliente                       int          = null,
        @i_num_banco                     varchar(24)  = null,   
        @i_tramite                       int          = null,
        @i_opcion                        int          = null,
        @i_modo                          int          = null
        )
as
declare 
        @w_sp_name                   varchar(32),
        @w_sp_msg                    varchar(100),
        @w_return                    int,
        @w_error                     int,
        @w_opcion                    int,
        @w_numero                    int,
        @w_tramite                   int,
        @w_tipo_personal             varchar(10)

select  @w_sp_name    = 'sp_cons_datos_linea',
        @w_opcion     = 0
        
select @w_opcion =  @i_opcion

  
-- Busqueda Datos de Linea
if @w_opcion = 1  
begin
    if (@i_cliente is null and @i_num_banco is null and @i_tramite is null)
    begin 
        select @w_error = 2110403
        goto ERROR_FIN
    end
    else 
    begin
        if(OBJECT_ID('tempdb..#temp_line') is not null)
           drop table #temp_line
   
        select 
            li_num_banco, 
            li_cliente,
            en_nomlar, 
            li_tramite,
            li_monto            = isnull(li_monto,0), 
            li_monto_disponible = isnull(li_monto,0) - isnull(li_utilizado,0) - isnull(li_reservado,0), 
            li_estado           = isnull(li_estado,''), 
            li_desc_estado      = (case isnull(li_estado,'') when 'V' then 'VIGENTE'
                                                             when 'C' then 'CANCELADA'
                                                             else 'EN ORIGINACION'
                               end),
            li_fecha_inicio, 
            li_fecha_vto,
            li_moneda,
            li_desc_moneda  = (select mo_descripcion from cobis..cl_moneda where mo_moneda = li_moneda)
         into #temp_line
         from cob_credito..cr_linea, cobis..cl_ente
        where  li_cliente   = en_ente
          and (li_cliente   = @i_cliente   or @i_cliente is null)
          and (li_num_banco = @i_num_banco or @i_num_banco is null)
          and (li_tramite   = @i_tramite   or @i_tramite is null)
        order by li_num_banco

        select 
            'NUM. LINEA'     = li_num_banco, 
            'CODIGO CLIENTE' = li_cliente,
            'NOMBRE CLIENTE' = en_nomlar, 
            'CODIGO TRAMITE' = li_tramite,
            'MONTO'          = li_monto, 
            'MONTO DISP'     = li_monto_disponible, 
            'CODIGO ESTADO'  = li_estado, 
            'ESTADO'         = li_desc_estado,
            'FECHA INICIO'   = li_fecha_inicio, 
            'FECHA VCTO'     = li_fecha_vto,
            'CODIGO MONEDA'  = li_moneda,
            'MONEDA'         = li_desc_moneda
         from #temp_line
    end
end 

-- Datos Generales - Datos de Linea
if @w_opcion = 2
begin
    select @w_numero = li_numero
      from cob_credito..cr_linea
     where li_num_banco =  @i_num_banco

    if(OBJECT_ID('tempdb..#temp_dat_line') is not null)
       drop table #temp_dat_line   
       
    select 
        li_tramite,
        li_num_banco,
        li_sector      = (select tr_sector from cob_credito..cr_tramite where tr_tramite = l.li_tramite),
        li_desc_sector = (select valor from  cobis..cl_tabla t, cobis..cl_catalogo c 
                           where t.codigo = c.tabla and t.tabla = 'cl_sector_neg' 
                            and c.codigo = (select tr_sector from cob_credito..cr_tramite where tr_tramite = l.li_tramite)),
        li_oficina,
        li_desc_oficina = (select of_nombre from cobis..cl_oficina where  of_oficina = li_oficina),
        li_ciudad       = (select tr_ciudad from cob_credito..cr_tramite where tr_tramite = l.li_tramite),
        li_desc_ciudad  = (select ci_descripcion from cobis..cl_ciudad 
                            where ci_ciudad = (select tr_ciudad from cob_credito..cr_tramite where tr_tramite = l.li_tramite)),
        li_oficial      = (select tr_oficial from cob_credito..cr_tramite where tr_tramite = l.li_tramite),
        li_desc_oficial = (select fu_nombre from cobis..cc_oficial, cobis..cl_funcionario
                            where oc_funcionario = fu_funcionario
                              and oc_oficial = (select tr_oficial from cob_credito..cr_tramite where tr_tramite = l.li_tramite)),
        li_fecha_inicio,
        li_dias,
        li_fecha_vto,
        li_moneda,
        li_desc_moneda  = (select mo_descripcion from cobis..cl_moneda where mo_moneda = li_moneda),
        li_monto        = isnull(li_monto,0), 
        li_fondos       = (select tr_origen_fondos from cob_credito..cr_tramite where tr_tramite = l.li_tramite), 
        li_desc_fondos  = (select valor from  cobis..cl_tabla t, cobis..cl_catalogo c 
                            where t.codigo = c.tabla and t.tabla = 'cr_origen_fondo' 
                              and c.codigo = (select tr_origen_fondos from cob_credito..cr_tramite where tr_tramite = l.li_tramite)),
        li_rotativa      = li_rotativa,
        li_desc_rotativa = (case li_rotativa when 'S' then 'Si' 
                                             when 'N' then 'No'
                            end),     
        li_monto_disponible = isnull(li_monto,0) - isnull(li_utilizado,0) - isnull(li_reservado,0), 
        li_estado        = isnull(li_estado,''),
        li_desc_estado   = (case isnull(li_estado,'') when 'V' then 'VIGENTE' 
                                                      when 'C' then 'CANCELADA'
                                                      else 'EN ORIGINACIÓN' 
                            end)
      into #temp_dat_line
     from cob_credito..cr_linea l
    where li_numero = @w_numero

    select 
        'NUM. TRAMITE'        = li_tramite,
        'NUM. LINEA'          = li_num_banco,
        'CODIGO SECTOR'       = li_sector,
        'SECTOR'              = li_desc_sector,
        'CODIGO OFICINA'      = li_oficina,
        'OFICINA'             = li_desc_oficina,
        'CODIGO MUNICIPIO'    = li_ciudad,
        'MUNICIPIO'           = li_desc_ciudad,
        'CODIGO OFICIAL'      = li_oficial,
        'OFICIAL'             = li_desc_oficial,
        'FECHA INICIO'        = li_fecha_inicio,
        'NRO. DIAS'           = li_dias,
        'FECHA VCTO'          = li_fecha_vto,
        'CODIGO MONEDA'       = li_moneda,
        'MONEDA'              = li_desc_moneda,
        'MONTO'               = li_monto, 
        'CODIGO ORG FONDOS'   = li_fondos,
        'ORG FONDOS'          = li_desc_fondos,
        'CODIGO ROT REV'      = li_rotativa,
        'ROT REV'             = li_desc_rotativa,
        'MONTO DISP.'         = li_monto_disponible,
        'CODIGO ESTADO'       = li_estado,
        'ESTADO'              = li_desc_estado
      from #temp_dat_line    
end

-- Datos Generales - Deudores
if @w_opcion = 3
begin
    select @w_numero = li_numero
      from cob_credito..cr_linea
     where li_num_banco =  @i_num_banco

    if(OBJECT_ID('tempdb..#temp_debtor') is not null)
       drop table #temp_debtor
       
    select 
         de_cliente,
         en_nomlar,
         de_rol = (select UPPER (valor) from  cobis..cl_tabla t, cobis..cl_catalogo c 
                         where t.codigo = c.tabla and t.tabla = 'cr_cat_deudor' 
                           and c.codigo = de_rol),
         de_identificacion = isnull((select ti_descripcion from cobis..cl_tipo_identificacion where ti_codigo = en_tipo_ced and ti_tipo_cliente = en_subtipo),''),
         de_ced_ruc
    into #temp_debtor
    from cob_credito..cr_linea, cob_credito..cr_deudores, cobis..cl_ente
   where de_cliente = en_ente
     and li_tramite = de_tramite
     and li_numero  = @w_numero
   order by de_rol desc
   
    select 
         'CODIGO'         = de_cliente,
         'NOMBRE'         = en_nomlar,
         'ROL'            = de_rol,
         'TIPO DOCUMENTO' = de_identificacion,
         'IDENTIFICACION' = de_ced_ruc
    from #temp_debtor   
 
end

-- Datos Generales - Distribucion de la Linea
if @w_opcion = 4
begin
    select @w_numero = li_numero
      from cob_credito..cr_linea
     where li_num_banco =  @i_num_banco
 
     if(OBJECT_ID('tempdb..#temp_dis_line') is not null)
       drop table #temp_dis_line
       
    select 
         om_producto = (select pd_descripcion from  cobis..cl_producto where pd_abreviatura = om_producto),
         om_toperacion,
         om_moneda   = (select mo_descripcion from cobis..cl_moneda where mo_moneda = om_moneda),
         om_monto,
         om_riesgo   = (select UPPER (valor) from  cobis..cl_tabla t, cobis..cl_catalogo c 
                         where t.codigo = c.tabla and t.tabla = 'fp_riesgos_licre' 
                           and c.codigo = (select pl_riesgo from cob_credito..cr_productos_linea where pl_producto = om_toperacion))
    into #temp_dis_line
    from cob_credito..cr_lin_ope_moneda
   where om_linea = @w_numero

    select 
        'PRODUCTO'  = om_producto,
        'OPERACION' = om_toperacion,
        'MONEDA'    = om_moneda,
        'MONTO'     = om_monto,
        'RIESGO'    = om_riesgo
    from #temp_dis_line      
end

-- Datos Generales - Garantias
if @w_opcion = 5
begin
   -- Datos Generales - Garantias Personales
   if @i_modo = 0
   begin   
        select @w_tipo_personal = pa_char
          from cobis..cl_parametro
         where pa_producto = 'GAR'
           and pa_nemonico = 'GPE' 
  
        select @w_numero = li_numero,
               @w_tramite = li_tramite 
          from cob_credito..cr_linea
         where li_num_banco =  @i_num_banco

        if(OBJECT_ID('tempdb..#temp_garp_line') is not null)
           drop table #temp_garp_line
           
        select g_codigo      = c.cu_codigo_externo,
               g_tipo        = tc_tipo,
               g_desc_tipo   = tc_descripcion,
               g_garante     = substring(convert(varchar(10),cu_garante) +  ' ' + (select en_nomlar from  cobis..cl_ente where en_ente = cu_garante) , 1, 64) ,
               g_estado      = c.cu_estado,
               g_desc_estado = (select UPPER (valor) from  cobis..cl_tabla t, cobis..cl_catalogo ct 
                                 where t.codigo = ct.tabla and t.tabla = 'cu_est_custodia' 
                                   and ct.codigo = c.cu_estado),
               g_moneda = c.cu_moneda,
               g_desc_moneda  = (select mo_descripcion from cobis..cl_moneda where mo_moneda = c.cu_moneda)
          into #temp_garp_line
          from cob_credito..cr_gar_propuesta G 
          left outer join cob_custodia..cu_cliente_garantia on cg_codigo_externo   = G.gp_garantia, 
          cob_custodia..cu_custodia c, cobis..cl_ente a, cob_custodia..cu_tipo_custodia
          where gp_tramite   = @w_tramite
            and gp_garantia  = cu_codigo_externo
            and a.en_ente    = gp_deudor
            and cg_principal = 'S'
            and cu_tipo      = tc_tipo
            and c.cu_estado not in ('A','C')
            and tc_tipo      = @w_tipo_personal
          order by gp_garantia 
    
          select 
          'CODIGO'        = g_codigo,
          'TIPO'          = g_tipo, 
          'DESCRIPCION'   = g_desc_tipo,
          'GARANTE'       = g_garante,
          'CODIGO ESTADO' = g_estado,
          'ESTADO'        = g_desc_estado,
          'CODIGO MONEDA' = g_moneda,
          'MONEDA'        = g_desc_moneda
          from #temp_garp_line              
   end 
   
   -- Datos Generales - Garantias Otros Tipos
   if @i_modo = 1
   begin   
        select @w_tipo_personal = pa_char
          from cobis..cl_parametro
         where pa_producto = 'GAR'
           and pa_nemonico = 'GPE' 
  
        select @w_numero = li_numero,
               @w_tramite = li_tramite 
          from cob_credito..cr_linea
         where li_num_banco =  @i_num_banco

        if(OBJECT_ID('tempdb..#temp_garo_line') is not null)
           drop table #temp_garo_line          
           
        select g_codigo      = c.cu_codigo_externo,
               g_tipo        = tc_tipo,
               g_desc_tipo   = tc_descripcion,
               g_valor_ini   = c.cu_valor_inicial,
               g_fecha_ava   = c.cu_fecha_avaluo,              
               g_estado      = c.cu_estado,
               g_desc_estado = (select UPPER (valor) from  cobis..cl_tabla t, cobis..cl_catalogo ct 
                                 where t.codigo = ct.tabla and t.tabla = 'cu_est_custodia' 
                                   and ct.codigo = c.cu_estado),
               g_moneda = c.cu_moneda,
               g_desc_moneda  = (select mo_descripcion from cobis..cl_moneda where mo_moneda = c.cu_moneda)
          into #temp_garo_line
          from cob_credito..cr_gar_propuesta G 
          left outer join cob_custodia..cu_cliente_garantia on cg_codigo_externo   = G.gp_garantia, 
          cob_custodia..cu_custodia c, cobis..cl_ente a, cob_custodia..cu_tipo_custodia
          where gp_tramite   = @w_tramite
            and gp_garantia  = cu_codigo_externo
            and a.en_ente    = gp_deudor
            and cg_principal = 'S'
            and cu_tipo      = tc_tipo
            and c.cu_estado not in ('A','C')
            and tc_tipo      <> @w_tipo_personal
          order by gp_garantia
    
          select 
          'CODIGO'        = g_codigo,
          'TIPO'          = g_tipo, 
          'DESCRIPCION'   = g_desc_tipo,
          'VALOR INICIAL' = g_valor_ini,
          'FECHA AVALUO'  = g_fecha_ava,
          'CODIGO ESTADO' = g_estado,
          'ESTADO'        = g_desc_estado,
          'CODIGO MONEDA' = g_moneda,
          'MONEDA'        = g_desc_moneda
          from #temp_garo_line  
   end     
end

-- Datos Generales - Transacciones
if @w_opcion = 6
begin
    select @w_numero = li_numero
      from cob_credito..cr_linea
     where li_num_banco =  @i_num_banco

     if(OBJECT_ID('tempdb..#temp_trn_line') is not null)
       drop table #temp_trn_line
       
    select 
        tl_secuencial,
        tl_fecha_tran,
        tl_transaccion,
        tl_desc_transaccion = (case tl_transaccion when 'D' then 'UTILIZACION' 
                                                   when 'A' then 'INSTRUMENTACION'
                                                   when 'V' then 'LIBERACION'
                               end),
        tl_valor,
        tl_estado,
        tl_desc_estado     = (case tl_estado when 'I' then 'INGRESADO' 
                                             when 'C' then 'CONTABILIZADO'
                              end),
        tl_usuario,
        tl_desc_usuario    = (select fu_nombre from cobis..cl_funcionario where fu_login = tl_usuario),
        tl_moneda,
        tl_desc_moneda  = (select mo_descripcion from cobis..cl_moneda where mo_moneda = tl_moneda)     
    into #temp_trn_line     
    from cob_credito..cr_transaccion_linea
   where tl_linea = @w_numero  

    select 
        'NUMERO'             = tl_secuencial,
        'FECHA'              = tl_fecha_tran,
        'CODIGO TRN'         = tl_transaccion,
        'TRN'                = tl_desc_transaccion,
        'MONTO'              = tl_valor,
        'CODIGO ESTADO'      = tl_estado,
        'ESTADO'             = tl_desc_estado,
        'CODIGO USUARIO'     = tl_usuario,
        'USUARIO'            = tl_desc_usuario,
        'CODIGO MONEDA'      = tl_moneda,
        'MONEDA'             = tl_desc_moneda
    from #temp_trn_line      
end

return 0

ERROR_FIN:
exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_error  
    
return @w_error

go
