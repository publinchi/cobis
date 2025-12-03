/***********************************************************************/
/*    Archivo:                 cr_bocli.sp                             */
/*    Stored procedure:        sp_bus_oper_cliente                     */
/*    Base de Datos:           cob_credito                             */
/*    Producto:                Credito                                 */
/*    Disenado por:            Myriam Davila                           */
/*    Fecha de Documentacion:  20/Nov/95                               */
/***********************************************************************/
/*                            IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de    */
/*    COBISCORP.                                                       */
/*    Su uso no autorizado queda expresamente prohibido asi como       */
/*    cualquier autorizacion o agregado hecho por alguno de sus        */
/*    usuario sin el debido consentimiento por escrito de la           */
/*    Presidencia Ejecutiva de COBISCORP o su representante.           */
/***********************************************************************/
/*                             PROPOSITO                               */
/*    Este stored procedure permite Buscar las operaciones que         */
/*    tiene un cliente.                                                */
/***********************************************************************/
/*                          MODIFICACIONES                             */
/*      FECHA        AUTOR                RAZON                        */
/*    20/Nov/95    Ivonne Ordonez   Emision Inicial                    */
/*    10/sep/96    F.Arellano       Optimizaciones                     */
/*    21/ene/97    M.Davila         Optimizacion                       */
/*    28/Mar/97    I.Parra          Arreglo de consulta                */
/*    16/Dic/97    I.Ordonez        Upgrade estados CCA                */
/*    31/Oct/01    D.Ayala          Version Base                       */
/*    21/Ago/2007  S.Robayo         Se incluye opcion_b                */
/*                                  para cuando la busqueda            */
/*                                  tiene orig. Adelantos              */
/*    27/sep/2007  S.Robayo         se elimina control de tipo de      */
/*                                  operacion.                         */
/*    02-01-2018   ALF              Migracion.                         */
/*    29-09-2021   P.Mora           ORI-S473524-GFI                    */
/*    03/Mar/2022  Dilan Morales    Se corrige sumatario de otros      */
/*                                  rubros                             */
/*    24/Nov/2022  Dilan Morales    S736966: Se adapta consulta para   */
/*                                  grupales                           */
/*    27/Feb/2023  Dilan Morales    Se corrige querys para grupales    */
/*    13/Oct/2023  Dilan Morales    R217444:Se cambia estado 66 a 6    */
/*    12/Dic/2023  Dilan Morales    R220707:Se corrige validacion de   */
/*                                  consulta operaciones grupales      */
/***********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_bus_oper_cliente')
   drop procedure sp_bus_oper_cliente
go

create proc sp_bus_oper_cliente (
   @s_ssn                   int         = null,
   @s_user                  login       = null,
   @s_sesn                  int         = null,
   @s_term                  descripcion = null,
   @s_date                  datetime    = null,
   @s_srv                   varchar(30) = null,
   @s_lsrv                  varchar(30) = null,
   @s_rol                   smallint    = null,
   @s_ofi                   smallint    = null,
   @s_org_err               char(1)     = null,
   @s_error                 int         = null,
   @s_sev                   tinyint     = null,
   @s_msg                   descripcion = null,
   @s_org                   char(1)     = null,
   @s_culture               varchar(10) = null,
   @t_rty                   char(1)     = null,
   @t_trn                   smallint    = null,
   @t_debug                 char(1)     = 'N',
   @t_file                  varchar(14) = null,
   @t_from                  varchar(30) = null,
   @i_operacion             char(1)     = 'S',
   @i_opcion                tinyint     = null,
   @i_modo                  tinyint     = null,
   @i_cliente               int         = null,
   @i_banco                 cuenta      = null,
   @i_solo_cca              char(1)     = 'N',      --S TRAE SOLO OPERACIONES DE CARTERA
   @i_cobranza              char(1)     = 'N',
   @i_oficina               smallint    = null,     --ASB
   @i_linea                 varchar(24) = null,
   @i_formato_fecha         tinyint     = 103,
   @i_tramite               int         = null,
   @i_tipo                  descripcion = null,
   @i_impresion             char(1)     = 'N',      --S si viene desde la impresi¢n de Plantillas
   @i_refinanciamiento      char(1)     = 'N',
   @i_opcion_b              tinyint     = 1,
   @i_toperacion            catalogo    = null,
   @i_objeto_cre            catalogo    = null,
   @i_sector                catalogo    = null,
   @i_es_grupal             char(1)     = null
)
as
declare
   @w_sp_name               varchar(32),
   @w_est_vigente           tinyint,   
   @w_est_vencido           tinyint,
   @w_est_suspenso          tinyint,                -- SBU: 01/abr/99
   @w_est_credito           tinyint,                -- CUandO TRAMITE ESTA EN CRE NO LIQUIDADO
   @w_est_cancelado         tinyint,                -- PARA OP Y DIV DE CARTERA
   @w_est_ejecuion          tinyint,                -- PARA ESTADO EJECUCION
   @w_error                 int,
   @w_toperacion            catalogo,
   @w_calificacion_cliente  varchar(10),
   @w_MLO                   tinyint,
   @w_cotiz                 FLOAT,
   @w_empresa               int,
   @w_id_tabla_toperacion   int,
   @w_est_resolucion        tinyint,                -- cuando esta en resolucion
   @w_id_tabla_seg_credito  int,
   --CAMPOS PARA REESTRUCTURACION
   @w_est_judicial          tinyint,
   @w_est_castigado         TINYINT,
   @w_est_novigente         tinyint,
   @w_est_anulado           tinyint
   --*********************

/* INICIALIZACION DE VARIABLES */
select @w_sp_name = 'sp_bus_oper_cliente'

if  @i_cliente is null and @i_operacion = 'S'
 begin
   /* CAMPOS NOT null CON VALORES NULOS */
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = 2101001
   return 1
 end

    /* CONSULTA A CARTERA */
    -- ================== --

    select @w_est_vencido = isnull(es_codigo, 255)
      from cob_cartera..ca_estado
     where rtrim(ltrim(es_descripcion)) = 'VENCIDO'

    select @w_est_vigente = pa_tinyint
      from cobis..cl_parametro
     where pa_nemonico = 'ESTVG'
       and pa_producto = 'CRE'

    select @w_est_suspenso = pa_tinyint  --SBU: 01/abr/99
      from cobis..cl_parametro
     where pa_nemonico = 'ESTRES'
       and pa_producto = 'CRE'

    select @w_est_cancelado = pa_tinyint
      from cobis..cl_parametro
     where pa_nemonico = 'ESTCAN'
       and pa_producto = 'CRE'

    select @w_est_ejecuion = pa_tinyint
      from cobis..cl_parametro
     where pa_nemonico = 'ESTEJE'
       and pa_producto = 'CRE'
    
    select @w_est_resolucion  = pa_tinyint
      from cobis..cl_parametro
     where pa_nemonico = 'ESTRES'
    
    select @w_est_credito  = isnull(pa_tinyint,99)   --PQU se añade
      from cobis..cl_parametro
     where pa_nemonico = 'ESTCRE'
    
    select @w_est_anulado  = isnull(pa_tinyint,6)    --PQU se añade
      from cobis..cl_parametro
     where pa_nemonico = 'ESTANU'

    select @w_est_novigente  = isnull(pa_tinyint,0)  --PQU se añade
      from cobis..cl_parametro
     where pa_nemonico = 'ESTNVG'


if @i_operacion = 'S'
begin

    --Recupero el id de las tabla de los catalogos
    select @w_id_tabla_toperacion = codigo 
      from cobis..cl_tabla 
     where tabla = 'ca_toperacion'
    
    select @w_id_tabla_seg_credito = codigo 
      from cobis..cl_tabla 
     where tabla = 'ca_segmento_credito'

/* CREACION TABLA TEMPORAL DE CONSULTA */

    create table #cr_temp1 
    (
        producto              catalogo    null,
        toperacion            varchar(10) null,
        banco                 cuenta      null,
        fecha_fin             datetime    null,
        fecha_ini             datetime    null,
        monto                 money       null,
        saldo                 money       null,
        moneda                tinyint     null,
        renovacion            tinyint     null,
        renovable             char(1)     null,
        tipo                  char(1)     null,     -- DBA: 11/NOV/99
        oficina               smallint    null,     -- IOR 1/07/01; submodulo Cobranzas
        saldo_adelanto        money       null,
        saldo_moneda_local    money       null,
        monto_moneda_local    money       null,
        calificacion_cliente  varchar(10) null,
        oficial               int         null,
        tasa                  float       null,
        dias                  int         null,
        estado                varchar(64) null
    )

    create table #cotizacion_tmp 
    (
        ct_moneda             tinyint     null,
        ct_valor              money       null
    )

    /* OBTENER TODAS LAS OPERACIONES DEL CLIENTE CON
    EL SALDO DE LAS OPERACIONES DE CAPITAL */
    /* SYR CD242 Se divide para Adelantos y para otras consultas */

    if @i_opcion_b = 1
     begin
        delete from  #cr_temp1
        insert into  #cr_temp1 
       (
         producto,   toperacion, banco,
         fecha_fin,  fecha_ini,  monto,
         saldo,      
         moneda,     renovacion, renovable,  
         tipo,       oficina
       )
        select
         'CCA',         op_toperacion,  op_banco,
         op_fecha_fin,  op_fecha_ini,   op_monto,
         sum(isnull(am_cuota,0) +
         isnull(am_gracia,0) -
         isnull(am_pagado,0))/* -
         isnull(am_exponencial,0))*/,    -- FBO_TEC
         op_moneda,     op_num_renovacion,    op_renovacion,
         op_tipo,       op_oficina
        from cob_cartera..ca_operacion,
             cob_cartera..ca_rubro_op,
             cob_cartera..ca_amortizacion,
             cob_cartera..ca_dividendo
        where op_cliente = @i_cliente
          and op_estado  not in (0,3,4,5,6,7,8,9,12,99,98,16,17) --,18
          --IN (1,2,10,11,12,15, 13) -- @w_est_vigente, @w_est_suspenso, @w_est_vencido)
          and ro_tipo_rubro in ('C')               -- tipo de rubro capital
          and di_estado   != @w_est_cancelado      -- estado del dividendo
          and op_operacion = di_operacion
          and op_operacion = ro_operacion
          and am_operacion = ro_operacion
          and di_dividendo = am_dividendo
          and ro_concepto  = am_concepto
          --and     op_oficina = @i_oficina  --ASB
          and op_tipo not in ('V')
          and (op_lin_credito=@i_linea or @i_linea = null)
          and ((op_renovacion = 'S' and @i_refinanciamiento = 'S') or
                @i_refinanciamiento = 'N')
        group by op_toperacion,
                 op_banco,
                 op_oficina,
                 op_fecha_fin,
                 op_fecha_ini,
                 op_monto,
                 op_moneda,
                 op_num_renovacion,
                 op_renovacion,
                 op_tipo,
                 op_oficina
     end

    if @i_opcion_b = 2
     begin
        delete from #cr_temp1
        -- SYR 09/15/2007 Consultar Tipo de operacion del tramite
        select @w_toperacion = tr_toperacion
          from cob_credito..cr_tramite
         where tr_tramite = @i_tramite

        insert into  #cr_temp1 
        (
            producto,  toperacion,  banco,
            fecha_fin, fecha_ini,   monto,
            saldo,
            moneda,    renovacion,  renovable,
            tipo,      oficina
        )

        select
            'CCA',        op_toperacion,  op_banco,
            op_fecha_fin, op_fecha_ini,   op_monto,
            sum(isnull(am_cuota,0) +
            isnull(am_gracia,0) -
            isnull(am_pagado,0) ),
            op_moneda,    op_num_renovacion,  op_renovacion,
            op_tipo,      op_oficina
           from cob_cartera..ca_operacion,
                cob_cartera..ca_rubro_op,
                cob_cartera..ca_amortizacion,
                cob_cartera..ca_dividendo,
                cob_credito..cr_tramite
           where op_cliente = @i_cliente
             and op_estado  not in (0,1,3,4,5,6,7,8,9,12,16,17) --,18, 99, 98
             and ro_tipo_rubro in ('C')
             and di_estado != @w_est_cancelado      -- estado del dividendo
             and op_operacion = di_operacion
             and op_operacion = ro_operacion
             and am_operacion = ro_operacion
             and di_dividendo = am_dividendo
             and ro_concepto = am_concepto
             and op_tipo not in ('V')
             and (op_lin_credito=@i_linea or @i_linea = null)
             and ((op_renovacion = 'S' and @i_refinanciamiento = 'S') or
                   @i_refinanciamiento = 'N')
             and op_tramite not in (select an_tram_anticipo from cr_anticipo)
             and op_tramite != @i_tramite
             and op_tramite = tr_tramite
             and tr_estado = 'A'
             --and tr_toperacion = @w_toperacion   -- Tramites del mismo toperacion
            group by  op_toperacion,
                      op_banco,
                      op_tipo,
                      op_oficina,
                      op_fecha_fin,
                      op_fecha_ini,
                      op_monto,
                      op_moneda,
                      op_num_renovacion,
                      op_renovacion
     end

    if @i_opcion_b = 3
     begin
        delete from #cr_temp1
        select @w_calificacion_cliente = en_calif_cartera
          from cobis..cl_ente
         where en_ente = @i_cliente

        select @w_MLO = pa_tinyint
          from cobis..cl_parametro
         where pa_producto = 'ADM' and pa_nemonico = 'MLO'

        select @w_cotiz = ct_valor
          from cob_credito..cb_cotizaciones--PQU integracion cob_cartera..cotizacion
         where ct_moneda = @w_MLO

        select @w_empresa = of_filial
          from cobis..cl_oficina
         where of_oficina = @s_ofi

        insert into #cotizacion_tmp
                  (ct_moneda,ct_valor)
           select ct_moneda, ct_valor
             from cob_conta..cb_cotizacion
            where ct_fecha = (select max(b.ct_fecha)
                                from cob_conta..cb_cotizacion b
                               where b.ct_fecha <= @s_date)
              and ct_empresa = @w_empresa

            -- Coloca la data de tablas mas grandes para optimizar el query y se retira el group by porque no suma si consolida nada...
            select op_cliente, op_toperacion,     op_operacion,  op_banco, op_fecha_fin, op_fecha_ini, op_monto,
                   op_moneda,  op_num_renovacion, op_renovacion, op_tipo,  op_oficina,   op_oficial,   op_estado
              into #cr_operacion
              from cob_cartera..ca_operacion
             where op_cliente = @i_cliente
               and op_estado in (select es_codigo from cob_cartera..ca_estado where es_procesa = 'S')
               and op_estado not in (@w_est_ejecuion)
               and op_tipo   not in ('V')
               and (op_lin_credito=@i_linea or @i_linea = null)
               and op_banco  not in (select or_num_operacion from cob_credito..cr_op_renovar)

            select am_operacion, am_dividendo, am_concepto, am_cuota, am_gracia, am_pagado, 0--PQU integracion am_exponencial
              into #cr_amortizacion
              from #cr_operacion , cob_cartera..ca_amortizacion
             where op_cliente   = @i_cliente
               and op_operacion = am_operacion

            select ro_porcentaje , ro_operacion
              into #cr_rubro_op
              from cob_cartera..ca_rubro_op,#cr_operacion
             where ro_operacion = op_operacion
               and ro_concepto = 'INT'

            -- EJECUTAR LA CONSULTA CONTRA TABLAS TEMPORALES
           insert into  #cr_temp1 
            (
              producto,   toperacion, banco,
              fecha_fin,  fecha_ini,  monto,
              saldo,
              moneda,  renovacion,    renovable,
              tipo,    oficina,       saldo_moneda_local,
              monto_moneda_local,     calificacion_cliente, oficial,
              tasa, dias, estado
            )
           select
            'CCA',         op_toperacion,   op_banco,
            op_fecha_fin,  op_fecha_ini,    op_monto,
            sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),--PQU integracion - isnull(am_exponencial,0)),
            op_moneda,     op_num_renovacion,    op_renovacion,
            op_tipo,       op_oficina,
            (case when @w_MLO != op_moneda then (sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) )* ct_valor)
                else sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) ) end),
            (case when @w_MLO != op_moneda then op_monto * ct_valor else op_monto end),
            @w_calificacion_cliente,
            op_oficial,tasa = (select ro_porcentaje from #cr_rubro_op where ro_operacion = op.op_operacion),
            dias            = isnull((select max(di_dias_vencido) from cob_cartera..ca_dividendo where di_estado = 2 and di_operacion = op.op_operacion),0),
            estado          = (select es_descripcion from cob_cartera..ca_estado where es_codigo = op.op_estado)
            from #cr_operacion op,
                 cob_cartera..ca_rubro_op,
                 #cr_amortizacion,
                 cob_cartera..ca_dividendo,
                 #cotizacion_tmp
           where op_cliente = @i_cliente
             and ro_tipo_rubro in ('C')               -- tipo de rubro capital
             and di_estado   != @w_est_cancelado      -- estado del dividendo
             and op_operacion = di_operacion
             and op_operacion = ro_operacion
             and am_operacion = ro_operacion
             and di_dividendo = am_dividendo
             and ro_concepto  = am_concepto
             and op_moneda    = ct_moneda
            group by op_toperacion,
                     op_banco,
                     op_oficina, 
                     op_fecha_fin,
                     op_fecha_ini,
                     op_monto,
                     op_moneda,
                     ct_moneda,
                     op_num_renovacion,
                     op_renovacion,
                     op_tipo
     end

    if @i_opcion_b = 4
     begin
        if @i_cliente is not null  -- 'Datos requeridos en null'
         begin
            if(@i_es_grupal = 'S') --GRUPAL
            begin
                select distinct
                op_operacion,
                op_banco,
                op_toperacion,
                op_fecha_fin                = convert(char(10),op_fecha_fin,@i_formato_fecha),
                op_fecha_ini                = convert(char(10),op_fecha_ini,@i_formato_fecha),
                op_monto,                  
                Saldo                       = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)                    
                                               from cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
                                              where am_operacion = op_operacion and am_concepto = 'CAP' and 
                                              op_ref_grupal = ope.op_banco and  op_estado not in (0,3,4 ,6, 66, 99)),
                op_moneda,
                op_num_renovacion,
                op_renovacion,
                op_tipo,
                op_oficina,
                tr_objeto,
                'Calificacion Cart'         = '',
                OperacionBase=' ',
                op_tramite,
                op_oficial,
                Calificacion                = op_calificacion,
                Porcentaje                  = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) 
                                                 from cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
                                                 where am_operacion = op_operacion and am_concepto = 'CAP' and 
                                                      op_ref_grupal = ope.op_banco and  op_estado not in (0, 3, 6,99,66)),
                op_sector,
                Estado                      = (select max(es_descripcion) 
                                                 from cob_cartera..ca_estado 
                                                where es_codigo = ope.op_estado),
                Dias_Mora                   = (select isnull(datediff(dd,di_fecha_ven,getdate()), 0)
                                                 from cob_cartera..ca_dividendo
                                                where di_operacion = ope.op_operacion
                                                  --and di_estado    = 2
                                                  and di_dividendo = (select min(b.di_dividendo) 
                                                                        from cob_cartera..ca_dividendo b,
                                                                             cob_cartera..ca_operacion
                                                                       where b.di_operacion = op_operacion 
                                                                         and op_ref_grupal = ope.op_banco 
                                                                         and b.di_estado    = 2)),
                tipo_operacion              = (select max(valor) 
                                                 from cobis..cl_catalogo 
                                                where tabla = @w_id_tabla_toperacion 
                                                  and codigo = ope.op_toperacion),
                'Saldo interes'             = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)) 
                                                        from cob_cartera..ca_amortizacion, cob_cartera..ca_operacion -- DFL: Se agregan campos
                                                       where op_operacion = am_operacion 
                                                         and op_ref_grupal = ope.op_banco 
                                                         and  op_estado not in (0,3,4 ,6, 66, 99)
                                                         and am_concepto = 'INT'),0),
                'Saldo Otros Rubros'        = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                            from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo, cob_cartera..ca_operacion
                                            where am_operacion = di_operacion
                                            and am_operacion = op_operacion 
                                            and op_ref_grupal = ope.op_banco 
                                            and op_estado not in (0,3,4 ,6, 66, 99)
                                            and am_dividendo = di_dividendo 
                                            and am_concepto not in('CAP', 'INT')
                                            and di_estado not in (0)),0)
                from cob_cartera..ca_operacion ope,                     
                    cobis..cl_grupo,
                    cob_credito..cr_tr_datos_adicionales da 
                right join cob_credito..cr_tramite tr on tr.tr_tramite = da.tr_tramite
                where ope.op_banco   in ( select distinct padre.op_banco  from cob_cartera..ca_operacion padre
                                            inner join cob_cartera..ca_operacion hija on hija.op_ref_grupal = padre.op_banco 
                                            where padre.op_grupo = @i_cliente
                                            and hija.op_estado not in (0,3,4 ,6, 66, 99))
                and ope.op_grupo   = gr_grupo
                and ope.op_tramite = tr.tr_tramite
                if @@rowcount = 0
                 begin
                     exec cobis..sp_cerror
                          @t_debug = @t_debug,
                          @t_file  = @t_file,
                          @t_from  = @w_sp_name,
                          @i_num   = 2101008
                     return 
                 end
            end
            else
            begin --INDIVIDUAL
                if @i_refinanciamiento != 'S'
                begin
                        select distinct
                        op_operacion,
                        op_banco,
                        op_toperacion,
                        op_fecha_fin               = convert(char(10),op_fecha_fin,@i_formato_fecha),
                        op_fecha_ini               = convert(char(10),op_fecha_ini,@i_formato_fecha),
                        op_monto,                  
                        Saldo                      = isnull((select sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)) -- - isnull(am_exponencial,0))  -- FBO_TEC
                                                                from cob_cartera..ca_amortizacion
                                                            where am_operacion = ope.op_operacion 
                                                                and am_concepto = 'CAP'), 0),
                        op_moneda,
                        op_num_renovacion,
                        op_renovacion,
                        op_tipo,
                        op_oficina,
                        tr_objeto,
                        ltrim(en_calif_cartera),
                        OperacionBase=' ',
                        op_tramite,
                        op_oficial,
                        Calificacion               = op_calificacion,
                        Porcentaje                 = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) 
                                                        from cob_cartera..ca_amortizacion
                                                        where ope.op_operacion = am_operacion 
                                                        and am_concepto = 'CAP'),
                        op_sector,
                        Estado                     = (select max(es_descripcion) 
                                                        from cob_cartera..ca_estado 
                                                        where es_codigo = ope.op_estado),
                        Dias_Mora                  = (select isnull(datediff(dd,di_fecha_ven,getdate()), 0)
                                                        from cob_cartera..ca_dividendo
                                                        where di_operacion = ope.op_operacion
                                                        and di_estado    = 2
                                                        and di_dividendo = (select min(b.di_dividendo) 
                                                                                from cob_cartera..ca_dividendo b
                                                                            where b.di_operacion = ope.op_operacion 
                                                                                and b.di_estado    = 2)),
                        tipo_operacion             = (select max(valor) 
                                                        from cobis..cl_catalogo 
                                                        where tabla = @w_id_tabla_toperacion 
                                                        and codigo = ope.op_toperacion),
                                                                    da.tr_tipo_cartera,
                                                                    da.tr_descripcion_oficial, --Descripción del destino,
                                                                    da.tr_actividad,           --Es actividad de? o +A qué Actividad se Destinará el Crédito?
                                                                    tr.tr_destino,             --Actividad de Destino del Crédito
                        '',                        --Fuente de Financiamiento
                        'Saldo interes'            = isnull((select sum(am_acumulado + am_gracia - am_pagado) 
                                                                from cob_cartera..ca_amortizacion       -- DFL Se agregan campos
                                                            where ope.op_operacion = am_operacion 
                                                                and am_concepto = 'INT'),0),
                        'Saldo Otros Rubros'       = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                                                from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                                                where am_operacion = di_operacion and
                                                                am_operacion = ope.op_operacion and 
                                                                am_dividendo = di_dividendo and
                                                                am_concepto not in('CAP', 'INT') and
                                                                di_estado not in (0)),0)                -- DFL Fin
                        from cob_cartera..ca_operacion ope,                     
                            cobis..cl_ente,
                            cob_cartera..ca_rubro_op,
                            cob_cartera..ca_dividendo,
                            cob_credito..cr_tr_datos_adicionales da
                        right join cob_credito..cr_tramite tr on tr.tr_tramite = da.tr_tramite
                        where ope.op_cliente = @i_cliente
                        and ope.op_cliente = en_ente
                        and ope.op_tramite = tr.tr_tramite
                        and op_operacion   = ro_operacion
                        and op_operacion   = di_operacion
                        and di_estado     != isnull(@w_est_cancelado,0)
                        and ope.op_estado not in (@w_est_credito,@w_est_novigente, @w_est_cancelado, @w_est_anulado )  --PQU se cambia a estos estados
        
                        if @@rowcount = 0
                        begin
                            exec cobis..sp_cerror
                                @t_debug = @t_debug,
                                @t_file  = @t_file,
                                @t_from  = @w_sp_name,
                                @i_num   = 2101008
                            return 1
                        end
                end
                else
                begin
                    select distinct
                        op_operacion,
                        op_banco,
                        op_toperacion,
                        op_fecha_fin                = convert(char(10),op_fecha_fin,@i_formato_fecha),
                        op_fecha_ini                = convert(char(10),op_fecha_ini,@i_formato_fecha),
                        op_monto,
                        Saldo                       = isnull(  (select sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)) --  - isnull(am_exponencial,0))  -- FBO_TEC
                                                                from cob_cartera..ca_amortizacion
                                                                where am_operacion = ope.op_operacion 
                                                                and am_concepto = 'CAP'), 0),
                        op_moneda,
                        op_num_renovacion,
                        op_renovacion,
                        op_tipo,
                        op_oficina,
                        da.tr_objeto,
                        ltrim(en_calif_cartera),
                        OperacionBase=' ',
                        op_tramite,
                        op_oficial,
                        Calificacion                = (select cast(cast(round(avg(isnull(ca_calificacion,0)),1) as int) as varchar(1))
                                                        from cob_cartera..ca_calif_operacion
                                                        where ca_operacion = ope.op_operacion),
                        Porcentaje                  = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) 
                                                        from cob_cartera..ca_amortizacion
                                                        where ope.op_operacion = am_operacion 
                                                        and am_concepto = 'CAP'),
                        op_sector,                  
                        Estado                      = (select max(es_descripcion) 
                                                        from cob_cartera..ca_estado 
                                                        where es_codigo = ope.op_estado),
                        Dias_Mora                   = (select isnull(datediff(dd,di_fecha_ven,getdate()), 0)
                                                        from cob_cartera..ca_dividendo
                                                        where di_operacion = ope.op_operacion
                                                        and di_estado    = 2
                                                        and di_dividendo = (select min(b.di_dividendo) 
                                                                                from cob_cartera..ca_dividendo b
                                                                            where b.di_operacion = ope.op_operacion 
                                                                                and b.di_estado    = 2)),
                        da.tr_tipo_cartera,
                        da.tr_descripcion_oficial, --Descripción del destino,
                        da.tr_actividad,           --Es actividad de? o +A qué Actividad se Destinará el Crédito?
                        tr.tr_destino,             --Actividad de Destino del Crédito
                        ''                         --Fuente de Financiamiento
                    from cob_cartera..ca_operacion ope,                     
                        cobis..cl_ente,
                        cob_cartera..ca_rubro_op,
                        cob_cartera..ca_dividendo,
                        cob_credito..cr_tr_datos_adicionales da
                    right join cob_credito..cr_tramite tr on tr.tr_tramite = da.tr_tramite
                    where ope.op_cliente = @i_cliente
                    and ope.op_cliente = en_ente
                    and ope.op_tramite = tr.tr_tramite
                    and op_operacion   = ro_operacion
                    and op_operacion   = di_operacion
                    and di_estado     != isnull(@w_est_cancelado,0)
                    and ope.op_estado not in (@w_est_credito,@w_est_novigente, @w_est_cancelado, @w_est_anulado )  --PQU se cambia a estos estados
        
                    if @@rowcount = 0
                    begin
                    exec cobis..sp_cerror
                                @t_debug = @t_debug,
                                @t_file  = @t_file,
                                @t_from  = @w_sp_name,
                                @i_num   = 2101008
                    return 1
                    end
                end
        end
     end
     else
      begin
       exec cobis..sp_cerror
           @t_debug  =  @t_debug,
           @t_file   =  @t_file,
           @t_from   =  @w_sp_name,
           @i_num    =  2101001
       return 1
      end
    end -- opcion_b = 4

    if @i_opcion_b = 5
     begin
     
        
        if @i_tramite is null  -- 'Datos despued del insert'
        begin
             exec cobis..sp_cerror
              @t_debug  =  @t_debug,
              @t_file   =  @t_file,
              @t_from   =  @w_sp_name,
              @i_num    =  2101001
              return 1
        
        end
         
         
        if exists(select 1 from cob_cartera..ca_operacion with(nolock) where op_tramite = @i_tramite and op_grupal = 'S' and op_ref_grupal is null)
        begin
            select 
                    'Operacion'             = or_num_operacion,
                    'Operacion Banco'       = op_banco,
                    'Tipo Operacion'        = or_toperacion,
                    'Fecha Fin'             = convert(char(10),op_fecha_fin,@i_formato_fecha),
                    'Fecha Inicio'          = convert(char(10),op_fecha_ini,@i_formato_fecha),
                    'Monto'                 = or_monto_original,
                     Saldo                  = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)                    
                                                 from cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
                                                where am_operacion = op_operacion and am_concepto = 'CAP' and 
                                                      op_ref_grupal = ope.op_banco and  op_estado not in (0, 3,99,6)),-- DFL Se cambia a Saldo Capital Cod. Ant: or_saldo_original
                    'Moneda'                = op_moneda,
                    'Num Renovacion'        = op_num_renovacion,
                    'Renovacion'            = op_renovacion,
                    'Tipo'                  = op_tipo,
                    'Oficina'               = op_oficina,
                    'Objeto'                = da.tr_objeto,
                    'Calificacion Cart'     = '', ---ltrim(en_calif_cartera),
                    'Base'                  = or_base, -- DFL Cod. Ant.: or_base
                    'Tramite'               = op_tramite,
                    'Oficial'               = op_oficial,
                    'Calificacion'          = (select cast(cast(round(avg(isnull(ca_calificacion,0)),1) as int) as varchar(1))
                                                 from cob_cartera..ca_calif_operacion
                                                where ca_operacion = ope.op_operacion),
                    Porcentaje                  = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) 
                                                 from cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
                                                 where am_operacion = op_operacion and am_concepto = 'CAP' and 
                                                      op_ref_grupal = ope.op_banco and  op_estado not in (0, 3,99,6)),
                    'Sector'                = op_sector,
                                              da.tr_descripcion_oficial, --Descripción del destino,
                                              da.tr_actividad,           --Es actividad de? o +A qué Actividad se Destinará el Crédito?
                                              tr.tr_destino,             -- Actividad de Destino del Crédito
                    'Fuente Financ'         = tr.tr_origen_fondos,       --Fuente de Financiamiento
                                              op_cuota,
                                              gr_grupo,--en_ente,
                    'Abono'                 = or_abono, 
                    'Capitaliza'            = or_capitaliza,
                    'Estado'                = (select es_descripcion 
                                                 from cob_cartera..ca_estado 
                                                where es_codigo = ope.op_estado),
                    Dias_Mora               = (select isnull(datediff(dd,di_fecha_ven,getdate()), 0)
                                                 from cob_cartera..ca_dividendo
                                                where di_operacion = ope.op_operacion
                                                  --and di_estado    = 2
                                                  and di_dividendo = (select min(b.di_dividendo) 
                                                                        from cob_cartera..ca_dividendo b,
                                                                             cob_cartera..ca_operacion
                                                                       where b.di_operacion = op_operacion 
                                                                         and op_ref_grupal = ope.op_banco
                                                                         and b.di_estado    = 2)),
                     tipo_operacion         = (select max(valor) 
                                                 from cobis..cl_catalogo 
                                                where tabla = @w_id_tabla_toperacion 
                                                  and codigo = re.or_toperacion),
                    'Tasa'                  = (select max(ro_porcentaje) 
                                                 from cob_cartera..ca_rubro_op 
                                                where ro_tipo_rubro = 'I' 
                                                  and ro_operacion = ope.op_operacion),
                    'Saldo interes'         = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)) 
                                                        from cob_cartera..ca_amortizacion, cob_cartera..ca_operacion -- DFL: Se agregan campos
                                                       where op_operacion = am_operacion 
                                                         and op_ref_grupal = ope.op_banco 
                                                         and  op_estado not in (0, 3,99,6)
                                                         and am_concepto = 'INT'),0),
                    'Saldo Otros Rubros'    = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                            from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo, cob_cartera..ca_operacion
                                            where am_operacion = di_operacion
                                            and am_operacion = op_operacion 
                                            and op_ref_grupal =  ope.op_banco
                                            and op_estado not in (0, 3,99,6)
                                            and am_dividendo = di_dividendo 
                                            and am_concepto not in('CAP', 'INT')
                                            and di_estado not in (0)),0),
                    'Total Capitalizacion'  = isnull(or_saldo_original,0)                       -- DFL Fin
            from cob_credito..cr_op_renovar re
                    inner join cob_credito..cr_tramite tr    on tr.tr_tramite = or_tramite
                    inner join cob_cartera..ca_operacion ope on or_num_operacion = op_banco
                    inner join cobis..cl_grupo on op_grupo = gr_grupo
                    left join cob_credito..cr_tr_datos_adicionales da on or_tramite = da.tr_tramite
                where or_tramite = @i_tramite
            
            if @@rowcount = 0
             begin
              exec cobis..sp_cerror
                   @t_debug = @t_debug,
                   @t_file  = @t_file,
                   @t_from  = @w_sp_name,
                   @i_num   = 2101008
              return 1
             end
        end
        else
        begin
            select 
                    'Operacion'             = or_num_operacion,
                    'Operacion Banco'       = op_banco,
                    'Tipo Operacion'        = or_toperacion,
                    'Fecha Fin'             = convert(char(10),op_fecha_fin,@i_formato_fecha),
                    'Fecha Inicio'          = convert(char(10),op_fecha_ini,@i_formato_fecha),
                    'Monto'                 = or_monto_original,
                     Saldo                  = isnull((select sum(am_acumulado + am_gracia - am_pagado) 
                                                        from cob_cartera..ca_amortizacion
                                                       where ope.op_operacion = am_operacion 
                                                         and am_concepto = 'CAP'),0), -- DFL Se cambia a Saldo Capital Cod. Ant: or_saldo_original
                    'Moneda'                = op_moneda,
                    'Num Renovacion'        = op_num_renovacion,
                    'Renovacion'            = op_renovacion,
                    'Tipo'                  = op_tipo,
                    'Oficina'               = op_oficina,
                    'Objeto'                = da.tr_objeto,
                    'Calificacion Cart'     = ltrim(en_calif_cartera),
                    'Base'                  = or_base, -- DFL Cod. Ant.: or_base
                    'Tramite'               = op_tramite,
                    'Oficial'               = op_oficial,
                    'Calificacion'          = (select cast(cast(round(avg(isnull(ca_calificacion,0)),1) as int) as varchar(1))
                                                 from cob_cartera..ca_calif_operacion
                                                where ca_operacion = ope.op_operacion),
                    'Porcentaje'            = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) 
                                                 from cob_cartera..ca_amortizacion
                                                where ope.op_operacion = am_operacion 
                                                  and am_concepto = 'CAP'),
                    'Sector'                = op_sector,
                                              da.tr_descripcion_oficial, --Descripción del destino,
                                              da.tr_actividad,           --Es actividad de? o +A qué Actividad se Destinará el Crédito?
                                              tr.tr_destino,             -- Actividad de Destino del Crédito
                    'Fuente Financ'         = tr.tr_origen_fondos,       --Fuente de Financiamiento
                                              op_cuota,
                                              en_ente,
                    'Abono'                 = or_abono, 
                    'Capitaliza'            = or_capitaliza,
                    'Estado'                = (select es_descripcion 
                                                 from cob_cartera..ca_estado 
                                                where es_codigo = ope.op_estado),
                     Dias_Mora              = (select isnull(datediff(dd,di_fecha_ven,getdate()), 0)
                                                 from cob_cartera..ca_dividendo
                                                where di_operacion = ope.op_operacion
                                                  and di_estado    = 2
                                                  and di_dividendo = (select min(b.di_dividendo) 
                                                                        from cob_cartera..ca_dividendo b
                                                                       where b.di_operacion = ope.op_operacion 
                                                                         and b.di_estado    = 2)),
                     tipo_operacion         = (select max(valor) 
                                                 from cobis..cl_catalogo 
                                                where tabla = @w_id_tabla_toperacion 
                                                  and codigo = re.or_toperacion),
                    'Tasa'                  = (select max(ro_porcentaje) 
                                                 from cob_cartera..ca_rubro_op 
                                                where ro_tipo_rubro = 'I' 
                                                  and ro_operacion = ope.op_operacion),
                    'Saldo interes'         = isnull((select sum(am_acumulado + am_gracia - am_pagado) 
                                                        from cob_cartera..ca_amortizacion       -- DFL Se agregan campos
                                                       where ope.op_operacion = am_operacion 
                                                         and am_concepto = 'INT'),0),
                    'Saldo Otros Rubros'    = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                            from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                            where am_operacion = di_operacion and
                                            am_operacion = ope.op_operacion and 
                                            am_dividendo = di_dividendo and
                                            am_concepto not in('CAP', 'INT') and
                                            di_estado not in (0)),0),
                    'Total Capitalizacion'  = isnull(or_saldo_original,0)                       -- DFL Fin
            from cob_credito..cr_op_renovar re
                    inner join cob_credito..cr_tramite tr    on tr.tr_tramite = or_tramite
                    inner join cob_cartera..ca_operacion ope on or_num_operacion = op_banco
                    inner join cobis..cl_ente on op_cliente = en_ente
                    left join cob_credito..cr_tr_datos_adicionales da on or_tramite = da.tr_tramite
                where or_tramite = @i_tramite
                
            if @@rowcount = 0
             begin
              exec cobis..sp_cerror
                   @t_debug = @t_debug,
                   @t_file  = @t_file,
                   @t_from  = @w_sp_name,
                   @i_num   = 2101008
              return 1
             end
        end
       

     end -- opcion_b = 5

    if @i_opcion_b = 6
     begin
        if @i_cliente is not null  and @i_sector is not null and @i_objeto_cre is not null -- 'Datos requeridos en null'
         begin
            select op_operacion,
                   op_banco,
                   op_toperacion,
                   op_fecha_fin                 = convert(char(10),op_fecha_fin,@i_formato_fecha),
                   op_fecha_ini                 = convert(char(10),op_fecha_ini,@i_formato_fecha),
                   op_monto,
                                                --Saldo = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0)),0)  --FBO_TEC
                   Saldo                        = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)
                                                     from cob_cartera..ca_amortizacion
                                                    where am_operacion = ope.op_operacion and am_concepto = 'CAP'),
                   op_moneda,
                   op_num_renovacion,
                   op_renovacion,
                   op_tipo,
                   op_oficina,
                   da.tr_objeto,
                   ltrim(en_calif_cartera),
                   OperacionBase='',
                   op_tramite,
                   op_oficial,
                   Calificacion                 = (select cast(cast(round(avg(isnull(ca_calificacion,0)),1) as int) as varchar(1))
                                                     from cob_cartera..ca_calif_operacion
                                                    where ca_operacion = ope.op_operacion),
                   Porcentaje                   = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) from cob_cartera..ca_amortizacion
                                                    where ope.op_operacion = am_operacion and am_concepto = 'CAP'),
                   op_sector
            from cob_cartera..ca_operacion ope, cob_credito..cr_tr_datos_adicionales da,
                 cob_credito..cr_tramite tr,cobis..cl_ente
           where ope.op_cliente = @i_cliente
             and ope.op_cliente = en_ente
             and ope.op_tramite = da.tr_tramite
             and ope.op_estado = 1
             and tr.tr_tramite = da.tr_tramite
             and da.tr_objeto = @i_objeto_cre
             and ope.op_sector = @i_sector

            if @@rowcount = 0
              begin
                 exec cobis..sp_cerror
                      @t_debug = @t_debug,
                      @t_file  = @t_file,
                      @t_from  = @w_sp_name,
                      @i_num   = 2101008
                 return 1
              end
         end
        else
         begin
          exec cobis..sp_cerror
               @t_debug  =  @t_debug,
               @t_file   =  @t_file,
               @t_from   =  @w_sp_name,
               @i_num    =  2101001
               return 1
         end
     end -- opcion_b = 6

    if @i_opcion_b = 7
    begin
        if @i_banco is null  -- 'Datos requeridos en null'
        begin
            exec cobis..sp_cerror
                 @t_debug  =  @t_debug,
                 @t_file   =  @t_file,
                 @t_from   =  @w_sp_name,
                 @i_num    =  2101001
            return 1
        end
        
        
        if exists(select 1 from cob_cartera..ca_operacion with(nolock) where op_banco = @i_banco and op_grupal = 'S' and op_ref_grupal is null)
        begin 
        
           select distinct
                op_operacion,
                op_banco,
                op_toperacion,
                op_fecha_fin                = convert(char(10),op_fecha_fin,@i_formato_fecha),
                op_fecha_ini                = convert(char(10),op_fecha_ini,@i_formato_fecha),
                op_monto,                                            
                Saldo                       = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)                    
                                                 from cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
                                                where am_operacion = op_operacion and am_concepto = 'CAP' and 
                                                      op_ref_grupal = @i_banco and  op_estado not in (0, 3,99,6)),
                op_moneda,
                op_num_renovacion,
                op_renovacion,
                op_tipo,
                op_oficina,
                da.tr_objeto,  -- Objeto del Crédito
                '',--ltrim(en_calif_cartera),
                OperacionBase               = '',
                op_tramite,
                op_oficial,
                Calificacion                = (select cast(cast(round(avg(isnull(ca_calificacion,0)),1) as int) as varchar(1))
                                                 from cob_cartera..ca_calif_operacion
                                                where ca_operacion = ope.op_operacion),
                Porcentaje                  = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) 
                                                 from cob_cartera..ca_amortizacion, cob_cartera..ca_operacion
                                                 where am_operacion = op_operacion and am_concepto = 'CAP' and 
                                                      op_ref_grupal = @i_banco and  op_estado not in (0, 3,99,6)),
                op_sector,
                da.tr_tipo_cartera,
                da.tr_descripcion_oficial,  -- Descripción del destino,
                da.tr_actividad,            -- Es actividad de? o +A qué Actividad se Destinará el Crédito?
                tr.tr_destino,              -- Actividad de Destino del Crédito
                tr.tr_origen_fondos,        -- Fuente de Financiamiento
                Estado                      = (select max(es_descripcion) 
                                                 from cob_cartera..ca_estado 
                                                where es_codigo = ope.op_estado),
                Dias_Mora                   = (select isnull(datediff(dd,di_fecha_ven,getdate()), 0)
                                                 from cob_cartera..ca_dividendo
                                                where di_operacion = ope.op_operacion
                                                  --and di_estado    = 2
                                                  and di_dividendo = (select min(b.di_dividendo) 
                                                                        from cob_cartera..ca_dividendo b,
                                                                             cob_cartera..ca_operacion
                                                                       where b.di_operacion = op_operacion 
                                                                         and op_ref_grupal = @i_banco
                                                                         and b.di_estado    = 2)),
                tipo_operacion              = (select max(valor) 
                                                 from cobis..cl_catalogo 
                                                where tabla = @w_id_tabla_toperacion 
                                                  and codigo = ope.op_toperacion),
                'Saldo interes'             = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)) 
                                                        from cob_cartera..ca_amortizacion, cob_cartera..ca_operacion -- DFL: Se agregan campos
                                                       where op_operacion = am_operacion 
                                                         and op_ref_grupal = @i_banco 
                                                         and  op_estado not in (0, 3,99,6)
                                                         and am_concepto = 'INT'),0),
                'Saldo Otros Rubros'        = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                            from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo, cob_cartera..ca_operacion
                                            where am_operacion = di_operacion
                                            and am_operacion = op_operacion 
                                            and op_ref_grupal = @i_banco 
                                            and op_estado not in (0, 3,99,6)
                                            and am_dividendo = di_dividendo 
                                            and am_concepto not in('CAP', 'INT')
                                            and di_estado not in (0)),0)
            from cob_cartera..ca_operacion ope,                     
                  cobis..cl_grupo, --cobis..cl_ente,
                 --cob_cartera..ca_rubro_op,
                 --cob_cartera..ca_dividendo,
                 cob_credito..cr_tr_datos_adicionales da 
            right join cob_credito..cr_tramite tr on tr.tr_tramite = da.tr_tramite
            where ope.op_banco   = @i_banco
              and ope.op_grupo   = gr_grupo --and ope.op_cliente = en_ente
              and ope.op_tramite = tr.tr_tramite
              --and op_operacion   = ro_operacion
              --and op_operacion   = di_operacion
              
            
            if @@rowcount = 0
            begin
                exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file,
                     @t_from  = @w_sp_name,
                     @i_num   = 2101008
                 return 1
            end
        end
        else
        begin

            if exists(select 1 from cob_cartera..ca_operacion with(nolock) where op_banco = @i_banco
                      and  op_estado in (@w_est_credito,@w_est_novigente, @w_est_cancelado, @w_est_anulado ) 
            )
            begin
                exec cobis..sp_cerror
                  @t_debug  =  @t_debug,
                  @t_file   =  @t_file,
                  @t_from   =  @w_sp_name,
                  @i_num    =  2110013
            
            end

            select distinct
                op_operacion,
                op_banco,
                op_toperacion,
                op_fecha_fin                = convert(char(10),op_fecha_fin,@i_formato_fecha),
                op_fecha_ini                = convert(char(10),op_fecha_ini,@i_formato_fecha),
                op_monto,
                                            --Saldo = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0)),0)  --FBO_TEC
                Saldo                       = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)                    
                                                 from cob_cartera..ca_amortizacion
                                                where am_operacion = ope.op_operacion and am_concepto = 'CAP'),
                op_moneda,
                op_num_renovacion,
                op_renovacion,
                op_tipo,
                op_oficina,
                da.tr_objeto,  -- Objeto del Crédito
                ltrim(en_calif_cartera),
                OperacionBase               = '',
                op_tramite,
                op_oficial,
                Calificacion                = (select cast(cast(round(avg(isnull(ca_calificacion,0)),1) as int) as varchar(1))
                                                 from cob_cartera..ca_calif_operacion
                                                where ca_operacion = ope.op_operacion),
                Porcentaje                  = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) 
                                                 from cob_cartera..ca_amortizacion
                                                where ope.op_operacion = am_operacion and am_concepto = 'CAP'),
                op_sector,
                da.tr_tipo_cartera,
                da.tr_descripcion_oficial,  -- Descripción del destino,
                da.tr_actividad,            -- Es actividad de? o +A qué Actividad se Destinará el Crédito?
                tr.tr_destino,              -- Actividad de Destino del Crédito
                tr.tr_origen_fondos,        -- Fuente de Financiamiento
                Estado                      = (select max(es_descripcion) 
                                                 from cob_cartera..ca_estado 
                                                where es_codigo = ope.op_estado),
                Dias_Mora                   = (select isnull(datediff(dd,di_fecha_ven,getdate()), 0)
                                                 from cob_cartera..ca_dividendo
                                                where di_operacion = ope.op_operacion
                                                  and di_estado    = 2
                                                  and di_dividendo = (select min(b.di_dividendo) 
                                                                        from cob_cartera..ca_dividendo b
                                                                       where b.di_operacion = ope.op_operacion 
                                                                         and b.di_estado    = 2)),
                tipo_operacion              = (select max(valor) 
                                                 from cobis..cl_catalogo 
                                                where tabla = @w_id_tabla_toperacion 
                                                  and codigo = ope.op_toperacion),
                'Saldo interes'             = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)) 
                                                        from cob_cartera..ca_amortizacion -- DFL: Se agregan campos
                                                       where ope.op_operacion = am_operacion 
                                                         and am_concepto = 'INT'),0),
                'Saldo Otros Rubros'        = isnull((select sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0))
                                            from cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                            where am_operacion = di_operacion and
                                            am_operacion = ope.op_operacion and 
                                            am_dividendo = di_dividendo and
                                            am_concepto not in('CAP', 'INT') and
                                            di_estado not in (0)),0)
            from cob_cartera..ca_operacion ope,                     
                 cobis..cl_ente,
                 cob_cartera..ca_rubro_op,
                 cob_cartera..ca_dividendo,
                 cob_credito..cr_tr_datos_adicionales da 
            right join cob_credito..cr_tramite tr on tr.tr_tramite = da.tr_tramite
            where ope.op_banco   = @i_banco
              and ope.op_cliente = en_ente
              and ope.op_tramite = tr.tr_tramite
              and op_operacion   = ro_operacion
              and op_operacion   = di_operacion
              and isnull(di_estado, 0) != isnull(@w_est_cancelado, 0)
              and ope.op_estado not in (@w_est_credito,@w_est_novigente, @w_est_cancelado, @w_est_anulado )  --PQU se cambia a estos estados
            
            if @@rowcount = 0
            begin
                exec cobis..sp_cerror
                     @t_debug = @t_debug,
                     @t_file  = @t_file,
                     @t_from  = @w_sp_name,
                     @i_num   = 2101008
                 return 1
            end
        end
    end -- opcion_b = 7
       
    if @i_opcion_b = 8
     begin
      if @i_banco is not null  -- 'Datos requeridos en null'
        begin
            select  op_operacion,    --1
                    op_banco,
                    op_toperacion,
                    op_fecha_fin                = convert(char(10),op_fecha_fin,@i_formato_fecha),
                    op_fecha_ini                = convert(char(10),op_fecha_ini,@i_formato_fecha),
                    op_monto,
                                                --Saldo = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0)),0)  -- FBO_TEC
                    Saldo                       = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)
                                                     from cob_cartera..ca_amortizacion
                                                    where am_operacion = ope.op_operacion and am_concepto = 'CAP'),
                    op_moneda,
                    op_num_renovacion,
                    op_renovacion,              --10
                    op_tipo,
                    op_oficina,
                    da.tr_objeto,
                    ltrim(en_calif_cartera),
                    OperacionBase               = '',
                    op_tramite,
                    op_oficial,
                    Calificacion                = (select cast(cast(round(avg(isnull(ca_calificacion,0)),1) as int) as varchar(1))
                                                     from cob_cartera..ca_calif_operacion
                                                    where ca_operacion = ope.op_operacion),
                    Porcentaje                  = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) from cob_cartera..ca_amortizacion
                                                    where ope.op_operacion = am_operacion and am_concepto = 'CAP'),
                    op_sector,                     --20
                    da.tr_tipo_cartera,
                    da.tr_descripcion_oficial,  --Descripción del destino,
                    da.tr_actividad,            --Es actividad de? o +A qué Actividad se Destinará el Crédito?
                    tr.tr_destino,              -- Actividad de Destino del Crédito
                    tr.tr_origen_fondos,        -- Fuente de Financiamiento
                    da.tr_objeto,               -- Objeto del Crédito
                    sub_actividad               = '',--PQU integración (select ODA.op_sub_actividad from cob_cartera..ca_op_datos_adicionales ODA where ODA.op_operacion = ope.op_operacion),
                    sub_actividad_des           = '' --PQU integración (select se_descripcion from cobis..cl_subactividad_ec , cob_cartera..ca_op_datos_adicionales ODA where se_codigo = ODA.op_sub_actividad and ODA.op_operacion = ope.op_operacion)
            from cob_cartera..ca_operacion ope, 
                 cob_credito..cr_tramite tr left outer join cob_credito..cr_tr_datos_adicionales da     on (tr.tr_tramite    = da.tr_tramite),
                 cobis..cl_ente
           where ope.op_banco =@i_banco
             and ope.op_cliente = en_ente
             and ope.op_tramite = tr.tr_tramite

            if @@rowcount = 0
             begin
                exec cobis..sp_cerror
                      @t_debug = @t_debug,
                      @t_file  = @t_file,
                      @t_from  = @w_sp_name,
                      @i_num   = 2101008
                 return 1
             end
        end
         else
          begin
            exec cobis..sp_cerror
               @t_debug  =  @t_debug,
               @t_file   =  @t_file,
               @t_from   =  @w_sp_name,
               @i_num    =  2101001
            return 1
          end
     end -- opcion_b = 8

    if @i_opcion_b = 9
     begin
        if @i_tramite is not null  -- 'Datos requeridos en null'
         begin
         
            select @w_MLO = pa_tinyint
              from cobis..cl_parametro
             where pa_producto = 'ADM' and pa_nemonico = 'MLO'

            select @w_cotiz = ct_valor
              from cob_credito..cb_cotizaciones--PQU integracion cob_cartera..cotizacion
             where ct_moneda = @w_MLO

             insert into #cotizacion_tmp
                (ct_moneda,ct_valor )
                select ct_moneda,ct_valor
                  from cob_credito..cb_cotizaciones cot --PQU integracion cob_cartera..cotizacion
                 where ct_fecha = (select max(ct_fecha) from cob_credito..cb_cotizaciones--PQU integracion cob_cartera..cotizacion
                                    where ct_moneda = cot.ct_moneda)

              select    'op_operacion',
                        'op_banco',
                        'op_toperacion',
                         0,
                        Saldo = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) ),0)
                                   from cob_cartera..ca_amortizacion
                                  where am_operacion = ope.op_operacion and am_concepto = 'CAP'),
                        op_moneda,
                        1,
                        0,
                        0,
                        0
                from cobis..cl_ente,cob_cartera..ca_operacion ope,
                    cob_credito..cr_tr_datos_adicionales, cob_credito..cr_op_renovar,
                    #cotizacion_tmp tmp
               where ope.op_cliente = en_ente
                 and or_num_operacion = ope.op_banco
                 and or_tramite = @i_tramite
                 and tr_tramite = or_tramite
                 and op_moneda = ct_moneda

              if @@rowcount = 0
               begin
                exec cobis..sp_cerror
                      @t_debug = @t_debug,
                      @t_file  = @t_file,
                      @t_from  = @w_sp_name,
                      @i_num   = 2101008
                return 1
               end
         end
        else
         begin
            exec cobis..sp_cerror
               @t_debug  =  @t_debug,
               @t_file   =  @t_file,
               @t_from   =  @w_sp_name,
               @i_num    =  2101001
            return 1
         end
     end -- opcion_b = 9

    /* Operaciones por oficial de Comercio Exterior */

    /*if @i_solo_cca = 'N'
    begin
        --Consulta de Comercio Exterior
         --Tabla temporal para extraer los pagos del cliente 

        create table #abono
        (        valor money null,
                 operacion  int null,
             forma_pago tinyint null,
             plazo char(1) null,
             negociacion int null
        )

        insert into #abono
        select isnull(sum(ab_valor),0),
               fn_operacion,
               fn_sec_fpago,
               fn_plazo,
               fn_sec_negociacion
        from   cob_comext..ce_fp_negociacion LEFT  OUTER JOIN cob_comext..ce_abono     on (    fn_operacion       = ab_operacion  
                                                                                           and fn_sec_fpago       = ab_sec_fpago  
                                                                                           and fn_sec_negociacion = ab_negociacion
                                                                                           and fn_plazo           = ab_plazo),
               cob_comext..ce_operacion
        where  op_ordenante = @i_cliente
        and    ab_estado    = 'C' 
        and    fn_operacion = op_operacion
        group by fn_operacion, fn_sec_negociacion, fn_plazo, fn_sec_fpago

        insert into #cr_temp1
        (producto,     toperacion,    banco,            fecha_fin,
        fecha_ini,    monto,        saldo,            moneda,
        oficina )
        select
        'CEX',         op_tipo_oper,    op_operacion_banco,    op_fecha_expir,
        op_fecha_emis,    op_importe,
        sum(isnull(fn_valor,0) - isnull(valor,0)),
        op_moneda,     op_oficina
        from     cob_comext..ce_operacion,
            cob_comext..ce_fp_negociacion,
                #abono
        where     op_etapa != '50' -- Anulada
        and       op_etapa != '10' -- CRE
        and       op_operacion = fn_operacion
        and       operacion = fn_operacion
        and       negociacion = fn_sec_negociacion
        and       plazo  = fn_plazo
        and       forma_pago = fn_sec_fpago
        and       op_ordenante = @i_cliente
        group by    op_tipo_oper,
                op_operacion_banco,
                op_fecha_expir,
                op_fecha_emis,
                op_importe,
                op_moneda,
                op_oficina

        --Operaciones con riesgo o liquidado
        insert into #cr_temp1
        (producto,     toperacion,    banco,        fecha_fin,
        fecha_ini,    monto,        saldo,        moneda,
        oficina)
        select 'CEX',
                op_tipo_oper,
            op_operacion_banco,
            op_fecha_expir,
            op_fecha_emis,
            op_importe,
            op_importe_calc,
                op_moneda,
            op_oficina
        from    cob_comext..ce_operacion A
        where   op_tipo_oper in ('CCI','CCD')
        and     op_etapa in ('11','12','20','21')
        and     op_ordenante = @i_cliente
        and     op_importe_calc > 0
    --        and     op_oficina = @i_oficina  --ASB
        and     not exists (select * from cob_comext..ce_fp_negociacion
                            where fn_operacion = A.op_operacion)
    end*/

   set rowcount 20
   
   select @i_banco = isnull(@i_banco, ' ')
   
   if @i_cobranza = 'N'
     begin
        select
                '62290'   =  toperacion,
                '61257'   =  banco,
                '61258'   =  convert(char(10),fecha_fin,@i_formato_fecha),   --LIM 30/Mar/2006 Se cambia por 103 por @i_formato_fecha
                '61259'   =  monto,
                '61260'   =  saldo,
                '61261'   =  moneda,
                '61262'   =  renovacion,
                '61263'   =  renovable,
                '61264'   =  convert(char(10),fecha_ini,@i_formato_fecha),   --LIM 30/Mar/2006 Se cambia por 103 por @i_formato_fecha
                '61265'   =  producto,
                '61266'   =  oficina,
                '61267'   =  saldo_moneda_local,
                '61268'   =  monto_moneda_local,
                '61269'   =  calificacion_cliente,
                'oficial' =  oficial,
                'tasa'    =  tasa,
                'dias'    =  dias,
                'estado'  =  estado
            from #cr_temp1
           where banco > @i_banco
        order by banco
     end
    else
     begin
        -- ELIMINACION DE OPERACIONS YA REGISTRADAS EN COBRANZAS
        -- -----------------------------------------------------
        delete #cr_temp1
          from cr_operacion_cobranza
         where producto = oc_producto
           and banco    = oc_num_operacion

        select
                '61256' =  toperacion,
                '61257' =  banco,
                '61258' =  convert(char(10),fecha_fin,@i_formato_fecha),     --LIM 30/Mar/2006 Se cambia por 103 por @i_formato_fecha
                '61259' =  monto,
                '61260' =  saldo,
                '61261' =  moneda,
                '61262' =  renovacion,
                '61263' =  renovable,
                '61264' =  convert(char(10),fecha_ini,@i_formato_fecha),     --LIM 30/Mar/2006 Se cambia por 103 por @i_formato_fecha
                '61265' =  producto,
                '61266' =  oficina
            from #cr_temp1
           where banco > @i_banco
        order by banco
     end
   set rowcount 0
   return 0
     end

if @i_operacion = 'R'
 begin
    --Recupero el id de la tabla de los catalogo
    select  @w_id_tabla_toperacion  = codigo from cobis..cl_tabla where tabla = 'ca_toperacion'
    
   if @i_cliente is not null  -- 'Datos requeridos en null'
    begin
    --Consulta para no refinanciamiento
       select distinct 
            op_operacion,
            op_banco,
            op_toperacion,
            op_fecha_fin                    = convert(char(10),op_fecha_fin,@i_formato_fecha),
            op_fecha_ini                    = convert(char(10),op_fecha_ini,@i_formato_fecha),
            op_monto,                       
                                            --Saldo = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0)),0)  --FBO_TEC
            Saldo                           = (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)
                                               from cob_cartera..ca_amortizacion
                                               where am_operacion = ope.op_operacion and am_concepto = 'CAP'),
            op_moneda,
            op_num_renovacion,
            op_renovacion,
            op_tipo,
            op_oficina,
            da.tr_objeto,                   -- Objeto del Crédito
            ltrim(''),
            OperacionBase                   = '',
            op_tramite,
            op_oficial,
            Calificacion                    = op_calificacion,
            Porcentaje                      = (select ((sum(am_acumulado + am_gracia - am_pagado))*100)/sum(am_acumulado) from cob_cartera..ca_amortizacion
                                                where ope.op_operacion = am_operacion and am_concepto = 'CAP'),
            op_sector,
            Estado                          = (select max(es_descripcion) from cob_cartera..ca_estado where es_codigo = ope.op_estado),
            Dias_Mora                       = (select isnull(datediff(dd,di_fecha_ven,getdate()), 0)
                                                 from cob_cartera..ca_dividendo
                                                where di_operacion = ope.op_operacion
                                                  and di_estado    = 2
                                                  and di_dividendo = (select min(b.di_dividendo) 
                                                                        from cob_cartera..ca_dividendo b
                                                                       where b.di_operacion = ope.op_operacion 
                                                                         and b.di_estado    = 2)),
            tipo_operacion                  = (select max(valor) from cobis..cl_catalogo where tabla = @w_id_tabla_toperacion and codigo = ope.op_toperacion),
            da.tr_tipo_cartera,             
            da.tr_descripcion_oficial,      -- Descripción del destino,
            da.tr_actividad,                -- Es actividad de? o +A qué Actividad se Destinará el Crédito?
            tr.tr_destino,                  -- Actividad de Destino del Crédito
            '',                             -- Fuente de Financiamiento
                                            --(select isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0)),0)  -- FBO_TEC
              (select isnull(sum(isnull(am_acumulado,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)
                 from cob_cartera..ca_dividendo,
                      cob_cartera..ca_rubro_op,
                      cob_cartera..ca_amortizacion
                where di_operacion  = ope.op_operacion
                  and am_operacion  = ope.op_operacion
                  and ro_operacion  = ope.op_operacion
                  and di_operacion  = am_operacion
                  and di_dividendo  = am_dividendo
                  and ro_concepto   = am_concepto
                  and ro_operacion  = am_operacion
                  and di_estado    != isnull(@w_est_cancelado,0) -- estado del dividendo
                  and ro_tipo_rubro in ('I', 'M')), -- tipo de rubro capital
            --(select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0) - isnull(am_exponencial,0)),0) -- FBO_TEC
              (select isnull(sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0)),0)
                 from cob_cartera..ca_dividendo,
                     cob_cartera..ca_rubro_op,
                     cob_cartera..ca_amortizacion
                where di_operacion  = ope.op_operacion
                  and am_operacion  = ope.op_operacion
                  and ro_operacion  = ope.op_operacion
                  and di_operacion  = am_operacion
                  and di_dividendo  = am_dividendo
                  and ro_concepto   = am_concepto
                  and ro_operacion  = am_operacion
                  and di_estado    != @w_est_cancelado -- estado del dividendo
                  and ro_tipo_rubro not in ('I', 'C', 'M')) -- tipo de rubro capital
        from cob_cartera..ca_operacion ope,
             cob_credito..cr_tramite tr left outer join cob_credito..cr_tr_datos_adicionales da on (tr.tr_tramite = da.tr_tramite),
             cobis..cl_ente,
             cob_cartera..ca_rubro_op,
             cob_cartera..ca_dividendo
       where ope.op_cliente = @i_cliente
         and ope.op_cliente = en_ente
         and ope.op_tramite = tr.tr_tramite
         and op_operacion   = ro_operacion
         and op_operacion   = di_operacion
         and di_estado     != isnull(@w_est_cancelado,0)
         and ope.op_estado not in (@w_est_credito,@w_est_novigente,@w_est_cancelado, @w_est_anulado)

       if @@rowcount = 0
        begin
         exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file,
              @t_from  = @w_sp_name,
              @i_num   = 2101008
         return 1
        end
   end --if @i_cliente is not null
 end  --i_operacion = 'R'

if @i_operacion = 'O'
begin
 declare @w_interfaz varchar(64) 
   select @w_interfaz = 'sp_gar_otros'
    exec @w_error = @w_interfaz --sp_gar_otros
         @s_ssn           = @s_ssn,
         @s_user          = @s_user,
         @s_sesn          = @s_sesn,
         @s_term          = @s_term,
         @s_date          = @s_date,
         @s_srv           = @s_srv,
         @s_rol           = @s_rol,
         @s_ofi           = @s_ofi,
         @t_debug         = @t_debug,
         @i_operacion     = @i_operacion,
         @i_opcion        = @i_opcion,
         @i_modo          = @i_modo,
         @i_tramite       = @i_tramite,
         @i_formato_fecha = @i_formato_fecha,
         @i_tipo          = @i_tipo,
         @i_banco         = @i_banco,
         @i_impresion     = @i_impresion
    return @w_error
end

if @i_operacion = 'Q'
begin
    if exists(select 1 
                from cob_cartera..ca_operacion, cob_credito..cr_op_renovar
               where op_banco   = or_num_operacion
                 and op_banco=@i_banco)
    begin
        exec cobis..sp_cerror
             @t_debug  =  @t_debug,
             @t_file   =  @t_file,
             @t_from   =  @w_sp_name,
             @i_num    =  2107042
        return 1
    end
end

return 0

go
