/************************************************************************/
/*   Archivo:                 repodisper.sp                             */
/*   Stored procedure:        sp_reporte_dispersion                     */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Adrianag Giler.                           */
/*   Fecha de Documentacion:  Agosto 2019                               */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/* Generación de datos para la impresion del reporte de dispersi?n      */
/************************************************************************/
/*                            CAMBIOS                                   */
/*  28/Ago/2019  Adriana Giler       Ajuste Te Creemos                  */
/*  29/Oct/2019  Jose Calvillo       Ajuste Transaccion                 */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_reporte_dispersion')
   drop proc sp_reporte_dispersion
go

create proc sp_reporte_dispersion
(
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @t_trn              int          = 0,
   @i_banco            cuenta       = NULL,
   @i_operacion      char(1)
)
as declare
   @w_return                int,
   @w_sp_name               varchar(32),
   @w_error                 int,
   @w_grupo                 varchar(64),
   @w_sucursal              varchar(64),
   @w_promotor              varchar(64),
   @w_clasificacion         varchar(10),
   @w_domicilio             varchar(125),
   @w_fec_entrega           varchar(10),
   @w_ciclo                 smallint,
   @w_plazo                 varchar(30),
   @w_hora                  varchar(5),
   @w_est_vigente           int,
   @w_est_novigente         int,
   @w_est_anulado           int,
   @w_est_cancelado         int,
   @w_est_credito           int,
   @w_groupNum              int,
   @w_dia_reunion           varchar(64),
   @w_hora_reunion          varchar(64),
   @w_tasa_int              varchar(64),
   @w_presiName             varchar(400),
   @w_secreName             varchar(400),
   @w_tesoName              varchar(400),
   @w_monto_sol             money = 0,
   @w_ahorro                money = 0,
   @w_operacion             int


if @t_trn <> 8010
begin
   select @w_error = 151023
   goto ERROR
end

--Estados de Cartera
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_credito    = @w_est_credito   out,
@o_est_cancelado  = @w_est_cancelado


if exists (select 1 from ca_operacion where op_banco = @i_banco
           and op_estado  in (@w_est_novigente,@w_est_credito,@w_est_anulado, @w_est_cancelado)) --0,99,6,3
begin
   select @w_error =  171096
   goto ERROR
END

--Datos para reporte de Cabecera dispersion
if @i_operacion = 'C'
Begin
    --Obteniendo Datos Generales
    select @w_grupo          =  gr_nombre,
           @w_sucursal       =  of_nombre,
           @w_promotor       =  fu_nombre,
           @w_clasificacion  =  gr_clasificacion,
           @w_domicilio      =  gr_dir_reunion,
           @w_fec_entrega    =  convert(varchar,op_fecha_ini,103),
           @w_plazo          =  convert(varchar(3),op_plazo) + ' ' + substring(C_P.valor,1,10),
           @w_hora           =  substring(FORMAT(getdate(),N'hh:mm tt'),1,8),
           @w_dia_reunion    =  C_S.valor,
           @w_hora_reunion   =  substring(FORMAT(gr_hora_reunion,N'hh:mm tt'),1,8),
           @w_groupNum       =  isnull(A.op_grupo,0),
           @w_operacion      =  op_operacion,
           @w_monto_sol       = A.op_monto
    from ca_operacion A
    inner join cobis..cl_grupo on gr_grupo = op_grupo
    left join cobis..cl_oficina on gr_sucursal = of_oficina
    left join cobis..cc_oficial on gr_oficial = oc_oficial
    left join cobis..cl_funcionario on oc_funcionario = fu_funcionario
    left join cobis..cl_tabla T_P on T_P.tabla = 'cr_dividendo_report'
    left join cobis..cl_catalogo C_P on C_P.tabla = T_P.codigo and C_P.codigo = op_tplazo
    left join cobis..cl_tabla T_S on T_S.tabla = 'cr_dias_semana'
    left join cobis..cl_catalogo C_S on C_S.tabla = T_S.codigo and C_S.codigo = gr_dia_reunion
    where op_banco  = @i_banco
    and   op_grupal = 'S'
    if @@error != 0
    begin
        set @w_error =  70170
        goto ERROR
    end
    -- DATOS DE CICLO
    select @w_ciclo     = max(ci_ciclo)
    from   ca_ciclo
    where  ci_grupo     = @w_groupNum
    and    ci_operacion = @w_operacion

    select @w_ahorro    = ci_monto_ahorro
    from   ca_ciclo
    where  ci_grupo     = @w_groupNum
    and    ci_operacion = @w_operacion
    and    ci_ciclo     = @w_ciclo
    -- TASA DE INTERES
    select @w_tasa_int  = format(ro_porcentaje,'N2') + ' %'
    from   cob_cartera..ca_rubro_op
    where  ro_operacion = @w_operacion
    and    ro_concepto = 'INT'
    -- MIEMBROS DEL COMITÉ DE ADMINISTRACION
    select @w_presiName = en_nomlar
    from   cobis..cl_cliente_grupo
    inner join cobis..cl_ente on en_ente = cg_ente and cg_rol = 'P'
    where  cg_grupo = @w_groupNum

    select @w_secreName = en_nomlar
    from   cobis..cl_cliente_grupo
    inner join cobis..cl_ente on en_ente = cg_ente and cg_rol = 'S'
    where  cg_grupo = @w_groupNum

    select @w_tesoName = en_nomlar
    from   cobis..cl_cliente_grupo
    inner join cobis..cl_ente on en_ente = cg_ente and cg_rol = 'T'
    where  cg_grupo = @w_groupNum

    --Retornando Datos
    select isnull(@w_grupo,''),
           isnull(@w_sucursal,''),
           isnull(@w_promotor,''),
           isnull(@w_clasificacion,''),
           isnull(@w_domicilio,''),
           isnull(@w_fec_entrega,''),
           isnull(@w_ciclo,''),
           isnull(@w_plazo,''),
           isnull(@w_hora,''),
           isnull(@w_dia_reunion,''),
           isnull(@w_hora_reunion,''),
           isnull(@w_tasa_int,''),
           isnull(@w_presiName,''),
           isnull(@w_secreName,''),
           isnull(@w_tesoName,''),
           @w_monto_sol,
           @w_ahorro
    return 0
END

--Datos para reporte de la tabla dispersion
if @i_operacion = 'D'
BEGIN
    select @w_groupNum    = isnull(A.op_grupo,0),
           @w_operacion   = A.op_operacion,
           @w_monto_sol   = A.op_monto
    from   ca_operacion A
    where  op_banco  = @i_banco
    and    op_grupal = 'S'

    select @w_ciclo     = max(ci_ciclo)
    from   ca_ciclo
    where  ci_grupo     = @w_groupNum
    and    ci_operacion = @w_operacion

    declare @registros table (
       re_cliente      int,
       re_operacion    int,
       re_sexo         catalogo,
       re_nombre       varchar(256),
       re_esquema      catalogo null,
       re_destino      catalogo null,
       re_porcentaje   money    null,
       re_ahorro       money    null,
       re_F            money    null,
       re_A            money    null,
       re_B            money    default 0,
       re_D            money    default 0,
       re_G            money    default 0,
       re_H            money    default 0,
       re_s_basico     money    default 0,
       re_s_voluntario money    default 0
    )

    insert into @registros (re_cliente,  re_operacion,
                            re_sexo,     re_nombre,
                            re_esquema,  re_destino,
                            re_ahorro,   re_porcentaje,
                            re_F,        re_A,
                            re_B,        re_D,
                            re_G,        re_H)
    SELECT H.op_cliente,       H.op_operacion,
           EN.p_sexo,          EN.p_p_apellido + isnull(' ' + EN.p_s_apellido, '') + isnull(' ' + EN.en_nombre, ''),
           DR.dr_forma_retiro, H.op_destino,
           CI.ci_monto_ahorro, ((H.op_monto * 100)/@w_monto_sol),
           H.op_monto,         ((CI.ci_monto_ahorro*H.op_monto)/@w_monto_sol),
           0,                  0,
           0,                  0
    FROM cob_cartera..ca_ciclo CI
    inner join cob_cartera..ca_operacion H on H.op_grupal = 'S' and H.op_grupo = @w_groupNum and H.op_ref_grupal = @i_banco
    inner join cobis..cl_cliente_grupo CG on CG.cg_grupo = @w_groupNum and H.op_cliente = CG.cg_ente
    inner join cobis..cl_dispersion_retiro DR on DR.dr_grupo = @w_groupNum and DR.dr_cliente = CG.cg_ente and DR.dr_operacion = @w_operacion
    inner join cobis..cl_ente EN on EN.en_ente = DR.dr_cliente
    and   CI.ci_grupo     = @w_groupNum
    and   CI.ci_operacion = @w_operacion
    and   CI.ci_ciclo     =  @w_ciclo

    update @registros
    set    re_s_basico = so_monto_seguro
    from   cob_cartera..ca_seguros_op PB
    where  PB.so_cliente   = re_cliente
    and    PB.so_operacion = re_operacion
    and    PB.so_tipo_seguro = 'B'

    update @registros
    set    re_s_voluntario = so_monto_seguro
    from   cob_cartera..ca_seguros_op PB
    where  PB.so_cliente   = re_cliente
    and    PB.so_operacion = re_operacion
    and    PB.so_tipo_seguro != 'B'


    SELECT  'SEXO'         =  (select B.valor
                              from cobis..cl_tabla AS A, cobis..cl_catalogo AS B
                              WHERE A.codigo = B.tabla
                              AND A.tabla = 'cl_sexo'
                              AND B.codigo = re_sexo),
            'NAME'         =  re_nombre,
            'ESQUEMA'      =  case re_esquema when 'ODI' then 'BANCO' when 'ODP' then 'EXTERNO' else ' ' end,
            'DESTINO'      = (select valor
                                from cobis..cl_tabla AS A, cobis..cl_catalogo AS B
                                WHERE A.codigo = B.tabla
                                AND A.tabla = 'cr_destino'
                                AND B.codigo = re_destino),
            'MONTO_SOL   ' = re_F,                          -- MONTO SOLICITUD = (F)
            'PRESTAMO_CAM' = re_F,                          -- MONTO SOLICITUD = (F)
            'PORCENT_HIJA' = re_porcentaje,
            'AHORRO_ESPE ' = re_ahorro,
            'AHORRO_ACU  ' = re_A,                          -- (A)
            'TOTAL_GI    ' = re_B,                          -- (B)
            'TOTAL_AGI   ' = (re_A + re_B) ,                -- (C=A+B)
            'RETIRA_AGI  ' = re_D,                          -- (D)
            'BASE_AHO    ' = (re_A + re_B) - re_D,          -- (E=C-D)
            'MONTO_FIN   ' = re_G,                          -- (G)
            'PRESTAMO_PAQ' = re_H,                          -- (H)
            'PRESTAMO_TOT' = (re_F - re_G + re_H),          -- (I=F-G+H)
            'COSTO_PAQUE ' = re_s_voluntario,               -- (J)
            'PAQUETE_BAS'  = re_s_basico,                   -- (K)
            'RETIRO_DIS'   = (re_D + (re_F - re_G + re_H) - re_s_voluntario - re_s_basico )   -- (L=D+I-J-K)
    FROM @registros
    order by re_nombre

    if @@error != 0
    begin
        select @w_error =  70170
        goto ERROR
    end

    return 0
END
return 0

if @@error != 0
begin
    select @w_error =  70170
    goto ERROR
end

ERROR:
exec cobis..sp_cerror
     @t_debug = 'N',
     @t_file  = null,
     @t_from  = @w_sp_name,
     @i_num   = @w_error,
     @i_sev   = 0

return @w_error

go
