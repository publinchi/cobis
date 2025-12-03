/************************************************************************/
/*  Archivo:                situacion_gar.sp                            */
/*  Stored procedure:       sp_situacion_gar                            */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_situacion_gar')
    drop proc sp_situacion_gar
go

create proc sp_situacion_gar(
        @t_file               varchar(14) = null,
        @t_debug              char(1)  = 'N',
        @i_subopcion          char(1)  = null,
        @s_sesn	              int      = null,
        @s_ssn                int      = null,
        @s_date               datetime = null,
        @s_user		      login    = null,
        @i_tramite            int      = null,
        @i_impresion          char(1)  = 'S',  --Si se lo llama desde la impresion del MAC viene 'N'
        @i_operacion          char(1)  = 'G',
        @i_cliente            int      = null,	--Parametros para Situacion Consulta
        @i_cliente_sig        int      = 0,
        @i_modo_c             char(2)  = null,
        @i_en_tramite         char(1)  = null,
        @i_modo               int      = null,
        @i_usuario            login    = null,
        @i_secuencia          int      = null,
        @i_categoria          char(2)  = null,
        @i_formato_fecha      int      = null,
        @i_tramite_d          int      = null,
        @i_operacion_ban      cuenta   = ' ',
        @i_tipo_deuda         char(1)  = null,
        @i_vista_360	      char(1)  = 'N',
        @t_show_version       bit = 0, -- Mostrar la version del programa
        @i_act_can            char(1)  = 'N',    -- MCA: para determinar si se conuslta las operaciones canceladas
        @i_grupo              int      = null
)
as
declare
   @w_sp_name		    varchar(32),
   @w_cliente		    int,
   @w_def_moneda	    tinyint,
   @w_riesgo		    money,
   @w_archivo		    char(12),
   @w_mensaje		    varchar(24),
   @w_fecha		        datetime,
   @w_total_registros   int,
   @w_spid              smallint,
   @w_estado_garantia   varchar(64),
   @w_tipo_grupo		varchar(5),
   @w_tg_tramite        int,
   @w_sg_valor_ini 		money,
   @w_sg_valor_act 		money,
   @w_sg_valor_act_ml	money,
   @w_sg_tipo_gar		varchar(64),
   @w_sg_desc_gar		varchar(64),
   @w_sg_moneda			int,
   @w_sg_estado			varchar(5),
   @w_count_tramite		int,
   @w_est_cancelado     int,
   @w_tipo_custodia     varchar(15)


select @w_sp_name = 'sp_situacion_gar',
       @w_archivo = 'cr_sigar.sp'

if @t_show_version = 1
begin
    print 'Stored procedure sp_situacion_gar, Version 4.0.0.6'
    return 0
end

select @w_spid = @@spid

-- Cargo Moneda Local
select @w_def_moneda = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'MLOCR'

select @w_est_cancelado = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'ESTCAN'
and pa_producto = 'CRE'
--SRO. Inicio Grupo Solidario
select @w_tg_tramite = max(tg_tramite)
  from cob_credito..cr_tramite_grupal,
       cob_cartera..ca_operacion
 where tg_tramite   = op_tramite
   and tg_grupo 	= @i_grupo
   and op_estado 	= @w_est_cancelado
--SRO. Fin Grupo Solidario
if @@rowcount = 0
begin
   /*Registro no existe */
      exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file,
      @t_from  = @w_sp_name,
      @i_num   = 2101005
      return 1
end
--print 'SRO i_operacion: '+@i_operacion
--SRO Grupo Solidario
select @w_tipo_grupo = gr_tipo
from cobis..cl_grupo
where gr_grupo = @i_grupo

-- Cargo fecha de proceso
select @w_fecha = fp_fecha
from cobis..ba_fecha_proceso

select @i_tramite_d = isnull(@i_tramite_d,0)
if @i_vista_360 = 'S'
begin
    if @i_operacion = 'S'
    begin
       /**  GARANTIAS EN PRENDA **/
       if @i_modo_c = 'G' or @i_modo_c = 'T'
       begin

          insert into cr_gar_tmp
           (spid,     CLIENTE,     TIPO_GAR,     DESC_GAR,     CODIGO,     MONEDA,     VALOR_INI,
           VALOR_ACT,     VALOR_ACT_ML,     PORCENTAJE,     MRC,     ESTADO,     PLAZO_FIJO,
           TIPO_CTA,     FIADOR,     ID_FIADOR,     CUSTODIA,     nombre_cliente , fechaCancelacion , fechaActivacion   )
          select  @w_spid,
                  sc_cliente,  a.sg_tipo_gar,
                  a.sg_desc_gar,   a.sg_codigo,
                  (select mo_nemonico
                  from cobis..cl_moneda
                  where mo_moneda = a.sg_moneda),
                  a.sg_valor_ini,   a.sg_valor_act,   a.sg_valor_act_ml,
                  a.sg_porc_mrc,    a.sg_valor_mrc,
                  a.sg_estado,      a.sg_pfijo,
                  (case a.sg_tramite_gar when null then ' '
                                  when 14 then (select td_descripcion from cob_pfijo..pf_operacion, cob_pfijo..pf_tipo_deposito where op_toperacion = td_mnemonico and op_num_banco = a.sg_pfijo )
                                  when 4  then (select pb_descripcion from cob_ahorros..ah_cuenta, cob_remesas..pe_pro_bancario where ah_prod_banc = pb_pro_bancario and ah_cta_banco = a.sg_pfijo)
                                  when 3  then (select pb_descripcion from cob_cuentas..cc_ctacte, cob_remesas..pe_pro_bancario where cc_prod_banc = pb_pro_bancario and cc_cta_banco = a.sg_pfijo)
                                  else ' '
                  end ),
                  isnull( a.sg_fiador, ' '),isnull( a.sg_id_fiador, ' '), sg_custodia,sc_nombre_cliente,
                  isnull(a.sg_fechaCancelacion,''),
                  isnull(a.sg_fechaActivacion,'')
          from cr_situacion_cliente,
               cr_situacion_gar a
          where sc_cliente   = a.sg_cliente
          and   sc_usuario   = @s_user
          and   sc_secuencia = @s_sesn
          and   sc_tramite   = @i_tramite
          and   sc_usuario   = a.sg_usuario
          and   sc_secuencia = a.sg_secuencia
          and   sc_tramite   = a.sg_tramite
          and   sc_cliente_con = @i_cliente
          order by sc_cliente, a.sg_tipo_gar

          select @w_total_registros = count(*) from cr_gar_tmp where spid = @w_spid

          select DISTINCT 'CLIENTE'         =  CLIENTE,
                 'TIPO'            =  TIPO_GAR,
                 'MODULO'          =  'GAR',
                 'DESCRIPCION'     =  DESC_GAR,
                 'No. DE GARANTIA' =  CODIGO,
                 'MONEDA'          =  MONEDA,
                 'VALOR INICIAL'   =  VALOR_INI,
                 'VALOR ACTUAL'    =  VALOR_ACT,
                 'VALOR ACTUAL ML' =  VALOR_ACT_ML,
                 '% M.R.C.'        =  PORCENTAJE,
                 'VALOR M.R.C.'    =  MRC,
                 'ESTADO'          =  isnull( eg_descripcion, ' '),
                 'DEPOSITO/ CUENTA'=  PLAZO_FIJO,
                 'TIPO CUENTA'     =  TIPO_CTA,
                 'NOMBRE FIADOR/ GARANTE'   =  FIADOR,
                 'CEDULA FIADOR/ GARANTE'   =  ID_FIADOR,
                 'CUSTODIA'        = CUSTODIA,
                 'COD.ESTADO'      = eg_estado,
                     'NOMBRE CLIENTE'  = nombre_cliente
          from cr_gar_tmp LEFT JOIN cob_custodia..cu_estados_garantia ON ESTADO = eg_estado
              where CODIGO >  @i_operacion_ban --and ESTADO *= eg_estado
              and   spid   = @w_spid
              order by CODIGO
              set rowcount 0
       end

       /**  GARANTIAS PROPIAS **/
       if @i_modo_c = 'GP' or @i_modo_c =  'T'
       begin

          insert into cr_gar_p_tmp
           (spid,     CLIENTE,     TIPO_GAR,     DESC_GAR,     CODIGO,     MONEDA,     VALOR_INI,
           VALOR_ACT,     VALOR_ACT_ML,     PORCENTAJE,     MRC,     ESTADO,     PLAZO_FIJO,
           TIPO_CTA,     FIADOR,     ID_FIADOR,     nombre_cliente , fechaCancelacion , fechaActivacion  )
          select  @w_spid,
                  sc_cliente,         a.sg_p_tipo_gar,
                  a.sg_p_desc_gar,    a.sg_p_codigo,
                  (select mo_nemonico
                   from cobis..cl_moneda
                   where mo_moneda = a.sg_p_moneda),
                  a.sg_p_valor_ini,
                  a.sg_p_valor_act,   a.sg_p_valor_act_ml,
                  a.sg_p_porc_mrc,    a.sg_p_valor_mrc,
                  a.sg_p_estado,
                  a.sg_p_fijo,
                  (case a.sg_p_tramite_gar when null then ' '
                          when 14 then (select td_descripcion from cob_pfijo..pf_operacion, cob_pfijo..pf_tipo_deposito where op_toperacion = td_mnemonico and op_num_banco = a.sg_p_fijo )
                          when 4  then (select pb_descripcion from cob_ahorros..ah_cuenta, cob_remesas..pe_pro_bancario where ah_prod_banc = pb_pro_bancario and ah_cta_banco = a.sg_p_fijo)
                          when 3  then (select pb_descripcion from cob_cuentas..cc_ctacte, cob_remesas..pe_pro_bancario where cc_prod_banc = pb_pro_bancario and cc_cta_banco = a.sg_p_fijo)
                          else ' '
                   end ),
                  a.sg_p_fiador,
                  a.sg_p_id_fiador, sc_nombre_cliente,
                  a.sg_fechaCancelacion,
                  a.sg_fechaActivacion
          from cr_situacion_cliente,
               cr_situacion_gar_p a
          where  sc_cliente     = a.sg_p_cliente
          and    sc_usuario     = @s_user
          and    sc_secuencia   = @s_sesn
          and    sc_tramite     = @i_tramite
          and    sc_usuario     = a.sg_p_usuario
          and    sc_secuencia   = a.sg_p_secuencia
          and    sc_tramite     = a.sg_p_tramite
          AND sc_cliente_con = @i_cliente
          AND sg_p_cliente = @i_cliente
          order by sc_cliente, a.sg_p_tipo_gar

          select @w_total_registros = count(*) from cr_gar_p_tmp where spid = @w_spid

          select 'CLIENTE'         =  CLIENTE,
                 'TIPO'            =  TIPO_GAR,
                 'MODULO'          =  'GAR',
                 'DESCRIPCION'     =  DESC_GAR,
                 'No. DE GARANTIA' =  CODIGO,
                 'MONEDA'          =  MONEDA,
                 'VALOR INICIAL'   =  VALOR_INI,
                 'VALOR ACTUAL'    =  VALOR_ACT,
                 'VALOR ACTUAL ML' =  VALOR_ACT_ML,
                 '% M.R.C.'        =  PORCENTAJE,
                 'VALOR M.R.C.'    =  MRC,
                 'ESTADO'          =  isnull( eg_descripcion, ' '),
                 'DEPOSITO/ CUENTA'=  PLAZO_FIJO,
                 'TIPO CUENTA'     =  TIPO_CTA,
                 'COD.ESTADO'      = eg_estado,
                 'NOMBRE CLIENTE'  = nombre_cliente
          from cr_gar_p_tmp LEFT JOIN cob_custodia..cu_estados_garantia ON ESTADO = eg_estado
          where CODIGO >  @i_operacion_ban --and ESTADO *= eg_estado
          and   spid   = @w_spid
          order by CODIGO

          set rowcount 0
       end

       /** POLIZAS **/
       if @i_modo_c = 'P' or @i_modo_c =  'T'
       begin

          insert into cr_poliza_tmp
           (spid,        CLIENTE,     POLIZA,     TRAMITE,     COMENTARIO,
           ASEGURADORA, ESTADO,      TIPO_POLIZA,FECHA_VEN,   ANUALIDAD,
           VAL_ENDOSO,  VAL_ENDOSO_ML,GARANTIA,  AVALUO,      SEC_POL,
           nombre_cliente)
          select distinct
                 @w_spid,
                 sp_cliente,    sp_poliza,
                 sp_tramite_d,
                 sp_comentario, sp_aseguradora,
                 sp_estado,    sp_desc_pol,  sp_fecha_ven,
                 sp_anualidad,  sp_endoso,      sp_endoso_ml, sp_codigo,
                 case sp_avaluo
                   when 'S' then
                      'SI'
                   when 'N' then
                      'NO'
                 end,
                 sp_sec_poliza,
                 sc_nombre_cliente
           from  cob_credito..cr_situacion_poliza, cob_credito..cr_situacion_cliente
          where  sp_tramite   = @i_tramite
            and  sp_usuario   = @s_user
            and  sp_secuencia = @s_sesn
            and  sc_usuario   = @s_user
            and  sc_secuencia = @s_sesn
            and  sc_tramite   = @i_tramite
            AND  sc_cliente_con = @i_cliente
          order  by sp_sec_poliza, sp_tramite_d

          select @w_total_registros = count(*)
       from cr_poliza_tmp
           where spid = @w_spid

          select   'CLIENTE'          = CLIENTE,         'No. POLIZA'        = POLIZA,
             'NO. DE PRESTAMO O LINEA' = isnull(tr_numero_op_banco, convert(varchar(10),TRAMITE)),         'COMENTARIO'       = COMENTARIO,
             'ASEGURADORA'      = ASEGURADORA,     'TIPO DE POLIZA'   = TIPO_POLIZA,
             'ESTADO'           = ESTADO,          'FECHA VCTO.'      = FECHA_VEN,
             'ANUALIDAD'        = ANUALIDAD,       'ENDOSO'           = VAL_ENDOSO,
             'ENDOSO ML'        = VAL_ENDOSO_ML,   'GARANTIA'         = GARANTIA,
             'AVALUO'           = AVALUO,          'TRAMITE'          = TRAMITE,
             'SEC.POL'          = SEC_POL,         'SEC'              = SEC,
             'NOMBRE CLIENTE'   = nombre_cliente
          from cr_tramite RIGHT JOIN cr_poliza_tmp ON tr_tramite = TRAMITE
          where SEC >  @i_tramite_d
            and spid = @w_spid
          order by SEC

          set rowcount 0
       end
    end
end

if @i_operacion = 'G'
begin
    -- CREACION DE TABLA DE COTIZACIONES
    insert into cr_cotiz3_tmp
           (spid, moneda, cotizacion)
    select @w_spid, a.ct_moneda, a.ct_compra
      from cob_credito..cb_cotizaciones a

    if not exists(select 1 from cr_cotiz3_tmp where moneda = @w_def_moneda and spid = @w_spid)
    begin
       insert into cr_cotiz3_tmp (spid, moneda, cotizacion)
       values (@w_spid, @w_def_moneda, 1)
    end
    --Si vino por la VCC para históricos
    if @i_act_can = 'S' --(Activos y Cancelados)
          select @w_estado_garantia = 'A'
    else if @i_act_can = 'N' --(Activos )
          select @w_estado_garantia= 'C,A'

    if @i_subopcion = 'D'
    begin
        if @w_tipo_grupo = 'S'
        begin
            --Inicio Grupo Solidario
            insert into cr_situacion_gar
               (sg_cliente,    sg_tramite,     sg_usuario,     sg_secuencia,    sg_tipo_con,
                sg_cliente_con,sg_identico,    sg_producto,    sg_tipo_gar,     sg_desc_gar,
                sg_codigo,     sg_moneda,      sg_valor_ini,   sg_valor_act,    sg_valor_act_ml,
                sg_estado,     sg_pfijo,       sg_fiador,      sg_id_fiador,    sg_tramite_gar,
                sg_porc_mrc,   sg_valor_mrc,   sg_custodia)
            select
                min(sc_cliente_con),     min(sc_tramite),    min(sc_usuario),      min(sc_secuencia),    min(sc_tipo_con),
                min(sc_cliente_con),     min(sc_identico),    'GAR',          min(cu_tipo),         min(tc_descripcion),
                convert(varchar,tg.tg_tramite) + '-' + cu_tipo, min(cu_moneda),  sum(isnull(cu_valor_inicial,0)), sum(isnull(cu_valor_actual,0)),sum(isnull(cu_valor_actual,0) * cotizacion),
                min(cu_estado),  0,    min(cg.gr_nombre),    min(cg.gr_grupo),    min(tg.tg_tramite),
                0, 0 , min(tg.tg_tramite)
            from cr_gar_propuesta,
                 cr_situacion_cliente,
                 cob_custodia..cu_custodia,
                 cob_custodia..cu_tipo_custodia,
                 cob_custodia..cu_cliente_garantia,
                 cr_cotiz3_tmp,
                 cob_credito..cr_deudores,
                 cobis..cl_ente a,
                 cr_tramite_grupal tg,
                 cobis..cl_grupo cg,
                 cob_cartera..ca_operacion o
            where cu_codigo_externo = gp_garantia
              and gp_garantia       = cg_codigo_externo
              and cu_tipo           = tc_tipo
              and tg.tg_grupo       = cg.gr_grupo
              and tg.tg_operacion  = o.op_operacion
              and o.op_tramite      = gp_tramite
              and op_tramite        = de_tramite
              and cu_moneda         = moneda
              and sc_cliente        = tg.tg_grupo
              and sc_tramite        = isnull(@i_tramite, 0)
              and a.en_ente         = cg_ente
              and o.op_cliente     = cg_ente
              and spid              = @w_spid
              and sc_usuario        = @s_user
              and sc_secuencia      = @s_sesn
              and tg.tg_grupo       = @i_grupo
              and (tg.tg_tramite     = @w_tg_tramite or @i_act_can = 'S')
            group by cu_tipo, convert(varchar,tg.tg_tramite) + '-' + cu_tipo, gr_grupo
        end --Fin Grupo Solidario
        else
        begin
            insert into cr_situacion_gar
                (sg_cliente,    sg_tramite,     sg_usuario,     sg_secuencia,    sg_tipo_con,
                sg_cliente_con,sg_identico,    sg_producto,    sg_tipo_gar,     sg_desc_gar,
                sg_codigo,     sg_moneda,      sg_valor_ini,   sg_valor_act,    sg_valor_act_ml,
                sg_estado,     sg_pfijo,       sg_fiador,      sg_id_fiador,    sg_tramite_gar,
                sg_porc_mrc,   sg_valor_mrc,sg_custodia)
            select distinct
                sc_cliente,     sc_tramite,    sc_usuario,      sc_secuencia,    sc_tipo_con,
                sc_cliente_con, sc_identico,    'GAR',          cu_tipo,         tc_descripcion,
                cu_codigo_externo, cu_moneda,  cu_valor_inicial,cu_valor_actual, isnull(cu_valor_actual,0) * cotizacion,
                cu_estado,    cu_plazo_fijo,
                isnull(substring(b.en_nomlar,1,datalength(b.en_nomlar)),substring(a.en_nomlar,1,datalength(a.en_nomlar))),
                isnull( b.en_ced_ruc, a.en_ced_ruc),
                null , -- TEC (tc_producto)
                0, 0 * cu_valor_actual , cu_custodia
            from  cr_gar_propuesta,
                 cr_situacion_cliente,
                 cob_custodia..cu_custodia LEFT JOIN cobis..cl_ente b  ON  cu_garante = b.en_ente,
                 cob_custodia..cu_tipo_custodia,
                 cob_custodia..cu_cliente_garantia,
                 cr_cotiz3_tmp,
                 cob_credito..cr_deudores,
                 cobis..cl_ente    a
            where cu_codigo_externo = gp_garantia
            and   cu_tipo           = tc_tipo
            and   cu_estado not in ('C','A')
            and   cu_moneda = moneda
            --and   tc_clase_garantia <> '50'
            and   gp_tramite        = de_tramite
            and   gp_garantia       = cg_codigo_externo
            and   de_cliente        = sc_cliente
            and   sc_usuario        = @s_user
            and   sc_secuencia      = @s_sesn
            and   sc_tramite        = @i_tramite
            and   a.en_ente         = cg_ente
            --and   cu_garante       *= b.en_ente
            and   cg_principal   = 'S'
            and   spid           = @w_spid
            and sc_cliente_con = @i_cliente
            and sc_tipo_con <> 'S'

            --Garantias  sin deudas y vigentes

            UNION

            select distinct
                sc_cliente,          sc_tramite,      sc_usuario,        sc_secuencia,       sc_tipo_con,
                sc_cliente_con,      sc_identico,     'GAR',             cu_tipo,            tc_descripcion,
                cu_codigo_externo,   cu_moneda,       cu_valor_inicial,  cu_valor_actual,    isnull(cu_valor_actual,0) * cotizacion,
                cu_estado,           cu_plazo_fijo,
                isnull(substring(b.en_nomlar,1,datalength(b.en_nomlar)),substring(a.en_nomlar,1,datalength(a.en_nomlar))),
                isnull( b.en_ced_ruc, a.en_ced_ruc),
                null , -- TEC (tc_producto)
                0,
                0 * cu_valor_actual , cu_custodia
            from  cr_situacion_cliente,
                  cob_custodia..cu_custodia c LEFT JOIN cobis..cl_ente b ON cu_garante = b.en_ente,
                  cob_custodia..cu_tipo_custodia,
                  cob_custodia..cu_cliente_garantia,
                  cr_cotiz3_tmp,
                  cobis..cl_ente a
            where cu_codigo_externo = cg_codigo_externo
            and   cg_ente = sc_cliente
            and   cu_tipo = tc_tipo
            and   cu_estado in ('P','V')
            --and   tc_clase_garantia <> '50'
            and   cu_moneda     = moneda
            and   sc_usuario    = @s_user
            and   sc_secuencia  = @s_sesn
            and   sc_tramite    = @i_tramite
            and   a.en_ente     = cg_ente
            --and   cu_garante   *= b.en_ente
            and   cg_principal   = 'S' --D
            and   spid = @w_spid
            and cg_codigo_externo not in (select gp_garantia from cr_gar_propuesta)
            and sc_cliente_con = @i_cliente
            and sc_tipo_con <> 'S'
        end
        if @@error <> 0
        begin
        /* Error en insercion de registro */
         exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2103001
             rollback
         return 1
        end


        update cob_credito..cr_situacion_gar
            set sg_fechaCancelacion = (select max(tr_fecha_tran) from cob_custodia..cu_transaccion where tr_codigo_externo =g.sg_codigo group by tr_codigo_externo),
                sg_fechaActivacion = null
        from cob_credito..cr_situacion_gar g
        where g.sg_estado = 'C'
        if @@error <> 0
        begin
           /* Error en update de registro */
            exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 2103001
                 rollback
            return 1
        end

        update cob_credito..cr_situacion_gar
        set sg_fechaActivacion = (select max(tr_fecha_tran) from cob_custodia..cu_transaccion where tr_codigo_externo =g.sg_codigo group by tr_codigo_externo),
               sg_fechaCancelacion = null
        from cob_credito..cr_situacion_gar g
        where g.sg_estado = 'V'

        if @@error <> 0
        begin
            /* Error en update de registro */
            exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 2103001
            rollback
            return 1
        end

        update cob_credito..cr_situacion_gar
        set sg_fechaActivacion =  null,
            sg_fechaCancelacion = null
        from cob_custodia..cu_transaccion t
        where t.tr_codigo_externo = sg_codigo
          and sg_estado not in('V','C')

        if @@error <> 0
        begin
            /* Error en update de registro */
            exec cobis..sp_cerror
                 @t_debug = @t_debug,
                 @t_file  = @t_file,
                 @t_from  = @w_sp_name,
                 @i_num   = 2103001
            rollback
            return 1
        end

        /** BORRO GARANTIAS DUPLICADAS  PARA LA VINCULACION**/
        if @i_impresion = 'S'
        begin
           delete cr_situacion_gar
            where sg_usuario   = @s_user
              and sg_secuencia = @s_sesn
              and sg_tramite   = @i_tramite
              and sg_cliente  <> sg_cliente_con
              and sg_codigo in (select sg_codigo from cr_situacion_gar
                                 where sg_usuario = @s_user    and sg_secuencia = @s_sesn
                                   and sg_tramite = @i_tramite and sg_cliente   = sg_cliente_con )
        end
    end
    else  --@i_subopcion  = 'P'
    begin
       insert into cr_situacion_gar_p
       (sg_p_cliente,        sg_p_tramite,    sg_p_usuario,      sg_p_secuencia,    sg_p_tipo_con,
        sg_p_cliente_con,    sg_p_identico,   sg_p_producto,     sg_p_tipo_gar,     sg_p_desc_gar,
        sg_p_codigo,         sg_p_moneda,     sg_p_valor_ini,    sg_p_valor_act,    sg_p_valor_act_ml,
        sg_p_estado,         sg_p_fijo,       sg_p_fiador,       sg_p_id_fiador,    sg_p_tramite_gar,
        sg_p_porc_mrc,       sg_p_valor_mrc    )
       select distinct
        sc_cliente,          sc_tramite,      sc_usuario,        sc_secuencia,       sc_tipo_con,
        sc_cliente_con,      sc_identico,     'GAR',             cu_tipo,            tc_descripcion,
        cu_codigo_externo,   cu_moneda,       cu_valor_inicial,  cu_valor_actual,    isnull(cu_valor_actual,0) * cotizacion,
        cu_estado,           cu_plazo_fijo,
        isnull(substring(b.en_nomlar,1,datalength(b.en_nomlar)),substring(a.en_nomlar,1,datalength(a.en_nomlar))),
        isnull( b.en_ced_ruc, a.en_ced_ruc),
        null , -- TEC (tc_producto)
        0,
        0 * cu_valor_actual
       from  cr_situacion_cliente,
             cob_custodia..cu_custodia c LEFT JOIN cobis..cl_ente b ON  cu_garante = b.en_ente,
             cob_custodia..cu_tipo_custodia,
             cob_custodia..cu_cliente_garantia,
             cr_cotiz3_tmp,
             cobis..cl_ente a
       where cu_codigo_externo = cg_codigo_externo
       and   cg_ente = sc_cliente
       and   cu_tipo = tc_tipo
       --and   tc_clase_garantia = '50' IYU
       and   cu_estado not in ('C','A')
       and   cu_moneda     = moneda
       and   sc_usuario    = @s_user
       and   sc_secuencia  = @s_sesn
       and   sc_tramite    = @i_tramite
       and   a.en_ente     = cg_ente
    --   and   cu_garante   *= b.en_ente
       and   cg_principal   = 'D'
       and sc_cliente_con = @i_cliente
       and   spid = @w_spid

       if @@error <> 0
       begin
          /* Error en insercion de registro */
           exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_num   = 2103001
           rollback
           return 1
       end

       update cob_credito..cr_situacion_gar_p
          set sg_fechaActivacion = (select max(tr_fecha_tran) from cob_custodia..cu_transaccion where tr_codigo_externo =g.sg_p_estado group by tr_codigo_externo),
              sg_fechaCancelacion = null
         from cob_credito..cr_situacion_gar_p g
        where g.sg_p_estado = 'V'
       if @@error <> 0
       begin
          /* Error en update de registro */
           exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file,
                @t_from  = @w_sp_name,
                @i_num   = 2103001
           rollback
           return 1
       end

       update cob_credito..cr_situacion_gar_p
          set sg_fechaCancelacion= (select max(tr_fecha_tran) from cob_custodia..cu_transaccion where tr_codigo_externo =g.sg_p_estado group by tr_codigo_externo),
              sg_fechaActivacion  = null
         from cob_credito..cr_situacion_gar_p g
        where g.sg_p_estado = 'C'

       if @@error <> 0
       begin
          /* Error en update de registro */
          exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2103001
          rollback
          return 1
       end

       update cob_credito..cr_situacion_gar_p
       set sg_fechaActivacion =  null,
           sg_fechaCancelacion = null
       from cob_custodia..cu_transaccion t
       where t.tr_codigo_externo = sg_p_codigo
       and sg_p_estado not in ('V','C')

       if @@error <> 0
       begin
          /* Error en update de registro */
          exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2103001
          rollback
          return 1
       end
    end

end     --if @i_operacion = 'G'

delete from cr_cotiz3_tmp   where spid = @w_spid --tabla de cotizaciones
delete from cr_gar_tmp      where spid = @w_spid
delete from cr_gar_p_tmp    where spid = @w_spid
delete from cr_poliza_tmp   where spid = @w_spid

return 0

GO
