/************************************************************************/
/*  Archivo:                reporte_buro_int.sp                         */
/*  Stored procedure:       sp_reporte_buro_int                         */
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

if exists(select 1 from sysobjects where name ='sp_reporte_buro_int')
    drop proc sp_reporte_buro_int
go


create proc sp_reporte_buro_int (
   @s_ssn           int          = null,
   @s_user          login        = null,
   @s_sesn          int          = null,
   @s_term          descripcion  = null,
   @s_date          datetime     = null,
   @s_srv           varchar(30)  = null,
   @s_lsrv          varchar(30)  = null,
   @s_rol           smallint     = null,
   @s_ofi           smallint     = null,
   @s_org_err       char(1)      = null,
   @s_error         int          = null,
   @s_sev           tinyint      = null,
   @s_msg           descripcion  = null,
   @s_org           char(1)      = null,
   @t_rty           char(1)      = null,
   @t_trn           smallint     = null,
   @t_debug         char(1)      = 'N',
   @t_file          varchar(14)  = null,
   @t_from          varchar(30)  = null,
   @i_cliente       int          = null,
   @i_formato_fecha int          = 101   )
   as
   declare
   @w_fecha_reg    datetime,
   @w_dias_pol     smallint,
   @w_fecha_repore    datetime, 
   @w_sucursal        varchar(64),
   @w_nombre_func     varchar(255),
   @w_fecha_consulta  datetime,
   @w_oficial         int,
   @w_cod_sucursal    int
   
   select @w_fecha_repore = getdate()
   
   select @w_sucursal = of_nombre
   from cobis..cl_oficina
   where of_oficina   =   @s_ofi
   
   select @w_nombre_func = fu_nombre
   from cobis..cl_funcionario
   where fu_login = @s_user 
   
   if @w_sucursal is null or @w_nombre_func is null
   begin
         select @w_oficial = en_oficial
         from cobis..cl_ente
         where en_ente = @i_cliente
         
         select @w_nombre_func     = fu_nombre,
                @w_cod_sucursal    = fu_oficina
         from cobis..cc_oficial,cobis..cl_funcionario
         where oc_oficial = @w_oficial
         and oc_funcionario = fu_funcionario
         
         select @w_sucursal = of_nombre
         from cobis..cl_oficina
         where of_oficina   = @w_cod_sucursal
         
         
   end
   
   select @w_fecha_consulta = max(ib_fecha)
   from  cr_interface_buro
   where ib_cliente = @i_cliente
     
   --Creacion Tablas Temporales
   create table #cr_buro_cuenta
   (
      bc_numero                             int  identity   ,
      bc_id_cliente                         int             ,
      --bc_fecha_actualizacion                datetime        ,
      bc_forma_pago_actual                  varchar(2)   null,
      bc_desc_forma_pago_actual             varchar(255) null,
      bc_historico_pagos                    varchar(24)  null,
      bc_nombre_otorgante                   varchar(16)  null,
      bc_clave_observacion                  varchar(2)   null,
      bc_desc_clave_observacion             varchar(255) null,
      bc_saldo_actual                       varchar(9)   null, 
      bc_saldo_vencido                      varchar(9)   null,
      bc_tipo_contrato                      varchar(2)   null,
      bc_desc_tipo_contrato                 varchar(64)  null, 
      bc_fecha_apertura_cuenta              datetime     null,
      bc_tipo_cuenta                        varchar(1)   null,
      bc_desc_tipo_cuenta                   varchar(64)  null,
      bc_indicador_tipo_responsabilidad     varchar(1)   null,
      bc_desc_tipo_responsabilidad          varchar(64)  null,
      bc_numero_cuenta_actual               varchar(25)  null,
      bc_clave_unidad_monetaria             varchar(2)   null,
      bc_fecha_actualizacion                datetime     null,
      bc_fecha_ultimo_pago                  datetime     null,
      bc_fecha_ultima_compra                datetime     null,
      bc_fecha_cierre_cuenta                datetime     null,
      bc_ultima_fecha_saldo_cero            datetime     null,
      bc_limite_credito                     varchar(9)   null,
      bc_credito_maximo                     varchar(9)   null,
      bc_monto_pagar                        varchar(9)   null,
      bc_frecuencia_pagos                   varchar(1)   null,
      bc_numero_pagos                       varchar(4)   null,
      bc_fecha_mas_reciente_pago_historicos datetime     null,
      bc_fecha_mas_antigua_pago_historicos  datetime     null
   )
   
     
   create table #tmp_datos_generales
   (
      dg_codigo_cliente int               ,
      dg_nombres        varchar(255)  null,
      dg_apellidos      varchar(255)  null,
      dg_rfc            varchar(30)   null,
      dg_fecha_nac      datetime      null,
      dg_curp           varchar(30)   null,     
      dg_codigo_est_civ varchar(10)   null,
      dg_estado_civ     varchar(60)   null      
   )
   
   create table #tmp_direcciones
   (
      di_secuencial    int          identity,
      di_calle_y_num   varchar(255) null,
      di_colonia       varchar(100) null,
      di_delegacion    varchar(100) null,
      di_ciudad        varchar(100) null,
      di_estado        varchar(100) null,
      di_codigo_postal varchar(100) null,
      di_reg_fecha     datetime     null
   )
   
   
   create table #tmp_prestamos   
   (
     pr_seuencial          int identity    ,
     pr_banco              varchar(24)     ,
     pr_ciclo              int         null,
     pr_fecha_apertura     datetime    null,
     pr_fecha_fin          datetime    null,
     pr_fecha_liquida      datetime    null,
     pr_dias_atraso        int         null,
     pr_monto_aprobado     int         null,
     pr_estado             varchar(64) null,
     pr_saldo_capital      money       null,
     pr_saldo_capital_mora money       null,
     pr_dias_mora_acum     int         null,
     pr_dias_maximo_mora   int         null
   )
   
   
   create table #tmp_cuenta_persona
   (
     cp_cliente                 int            ,
     cp_mop                     varchar(2) null,
     cp_numero                  int        null,
     cp_cuentas_abiertas        int        null,
     cp_limite_cuentas_abiertas money      null,
     cp_saldo_actual_abiertas   money      null,
     cp_saldo_vencido_abiertas  money      null,
     cp_pago_relizar_abiertas   money      null,
     cp_pago_semanal            money      null,
     cp_pago_catorcenal         money      null,
     cp_pago_mensual            money      null,
     cp_cuentas_cerradas        int        null,
     cp_limite_cuentas_cerradas money      null,
     cp_saldo_actual_cerradas   money      null,
     cp_monto_cerradas          money      null
   )
   
   
    create table #tmp_consultas_efectuadas
   (
     ce_cliente               int              ,
     ce_otorgante             varchar(16)  null,   
     ce_fecha_consulta        datetime     null,
     ce_tipo_responsabilidad  varchar(64)  null,
     ce_tipo_contrato         varchar(64)  null, 
     ce_importe_contrato      varchar(64)  null, --??
     ce_tipo_unidad_monetaria varchar(2)   null
   )
   
   
   select @w_fecha_reg = max(do_fecha)
   from cob_conta_super..sb_dato_operacion op
   where do_codigo_cliente = @i_cliente
   
   
   insert into #tmp_prestamos   
   (        pr_banco              ,
            pr_ciclo              ,
            pr_fecha_apertura     ,
            pr_fecha_fin          ,
            pr_monto_aprobado     ,
            pr_estado             ,
            pr_saldo_capital      ,
            pr_saldo_capital_mora ,              
            pr_dias_mora_acum     
            )   
   select 
           'Id_Credito'     = do_banco,
           'Ciclos'         = isnull(do_numero_ciclos,1),
           'Fecha_Apertura' = do_fecha_concesion,
           'Fecha_Fin'      = do_fecha_vencimiento,
           'Monto'          = do_monto,
           'Estado'         = (select  es_descripcion
                               from cob_cartera..ca_estado
                               where es_codigo = do_estado_cartera
            ),
           'Saldo_Capital'  = do_saldo_cap,
           'Saldo_Cap_Mora' = do_cap_vencido,
           'Dias_Mora'      = do_edad_mora
                               
   from cob_conta_super..sb_dato_operacion op
   where do_fecha          = @w_fecha_reg
   and   do_codigo_cliente = @i_cliente
   and   do_aplicativo     = 7
    
   select banco     = dc_banco,
          dividendo = max(dc_num_cuota)
   into #tmp_cancelacion
   from  #tmp_prestamos, cob_conta_super..sb_dato_cuota_pry
   where dc_fecha = @w_fecha_reg
   and dc_banco   = pr_banco
   group by dc_banco
   
   update #tmp_prestamos
   set  pr_fecha_liquida= dc_fecha_can
   from  #tmp_cancelacion,
         cob_conta_super..sb_dato_cuota_pry
   where pr_banco  = banco
   and   dc_banco  = dc_banco  
   and   dividendo = dc_num_cuota
   and   dc_fecha  = @w_fecha_reg
   and   dc_fecha_can is not null     
  
   select banco     = dc_banco,
          fecha_min = min(dc_fecha_vto)
   into #tmp_dias_mora
   from  #tmp_prestamos, cob_conta_super..sb_dato_cuota_pry
   where dc_fecha   = @w_fecha_reg
   and   dc_banco   = pr_banco
   and   dc_estado  = 2
   group by dc_banco
   
   update #tmp_prestamos
   set  pr_dias_atraso = isnull(datediff(dd,fecha_min,@w_fecha_reg),0)
   from  #tmp_dias_mora
   where pr_banco  = banco
     
   select banco        = dc_banco    ,
          dividendo    = dc_num_cuota,
          dias_atraso  = isnull(datediff(dd,dc_fecha_vto,dc_fecha_can),0)          
   into #tmp_dias_atraso
   from  #tmp_prestamos, cob_conta_super..sb_dato_cuota_pry
   where dc_fecha     = @w_fecha_reg
   and   dc_banco     = pr_banco
   and   dc_estado    = 3
   and   dc_fecha_vto < dc_fecha_can
   
   select banco,
          atraso = max(dias_atraso)
   into #tmp_atraso
   from #tmp_dias_atraso
   group by banco
   
   update #tmp_prestamos
   set pr_dias_maximo_mora = atraso
   from #tmp_atraso
   where pr_banco = banco
   	
    -- Datos Buro
   insert into #cr_buro_cuenta
     (
      bc_id_cliente           ,
      --bc_fecha_actualizacion  ,
      bc_forma_pago_actual    ,
      bc_historico_pagos      ,
      bc_nombre_otorgante     ,
      bc_clave_observacion    ,
      bc_saldo_actual         ,
      bc_saldo_vencido        ,
      bc_tipo_contrato        ,
      --bc_fecha_apertura_cuenta,
      bc_tipo_cuenta          ,
      bc_indicador_tipo_responsabilidad,
      bc_numero_cuenta_actual   ,
      bc_clave_unidad_monetaria ,
      --bc_fecha_actualizacion    ,
      bc_fecha_ultimo_pago      ,
      bc_fecha_ultima_compra    ,
      bc_fecha_cierre_cuenta    ,
      bc_ultima_fecha_saldo_cero,
      bc_limite_credito         ,
      bc_credito_maximo         ,
      bc_monto_pagar            ,
      bc_frecuencia_pagos       ,
      bc_numero_pagos           ,
      bc_fecha_mas_reciente_pago_historicos,
      bc_fecha_mas_antigua_pago_historicos )   
   select ib_cliente AS bc_id_cliente,
          --ib_fecha   AS bc_fecha_actualizacion,
          bc_forma_pago_actual,
          bc_historico_pagos  ,
          bc_nombre_otorgante ,
          bc_clave_observacion,
          replace(replace(isnull(bc_saldo_actual,0),'+',''),'-',''),
          replace(replace(isnull(bc_saldo_vencido,0),'+',''),'-',''),
          bc_tipo_contrato,
          --bc_fecha_apertura_cuenta = convert(datetime,SUBSTRING(bc_fecha_apertura_cuenta,1,2) + '/' +SUBSTRING(bc_fecha_apertura_cuenta,3,2) + '/' + SUBSTRING(bc_fecha_apertura_cuenta,5,4),103),
          bc_tipo_cuenta,
          bc_indicador_tipo_responsabilidad,
          bc_numero_cuenta_actual,
          bc_clave_unidad_monetaria,
          --bc_fecha_actualizacion = convert(datetime,SUBSTRING(bc_fecha_actualizacion,1,2) + '/' +SUBSTRING(bc_fecha_actualizacion,3,2) + '/' + SUBSTRING(bc_fecha_actualizacion,5,4),103),
          bc_fecha_ultimo_pago   = case when bc_fecha_ultimo_pago is not null then
                               convert(datetime,SUBSTRING(bc_fecha_ultimo_pago,1,2) + '/' +SUBSTRING(bc_fecha_ultimo_pago,3,2) + '/' + SUBSTRING(bc_fecha_ultimo_pago,5,4),103)
                                   else
                                        null
                                   end,   
          bc_fecha_ultima_compra = case when bc_fecha_ultima_compra is not null then 
                                        convert(datetime,SUBSTRING(bc_fecha_ultima_compra,1,2) + '/' +SUBSTRING(bc_fecha_ultima_compra,3,2) + '/' + SUBSTRING(bc_fecha_ultima_compra,5,4),103)
                                   else
                                        null
                                   end,
          bc_fecha_cierre_cuenta = case when bc_fecha_cierre_cuenta is not null then
                                        convert(datetime,SUBSTRING(bc_fecha_cierre_cuenta,1,2) + '/' +SUBSTRING(bc_fecha_cierre_cuenta,3,2) + '/' + SUBSTRING(bc_fecha_cierre_cuenta,5,4),103)
                                   else
                                        null
                                   end,
          bc_ultima_fecha_saldo_cero = case when bc_ultima_fecha_saldo_cero is not null then
                                            convert(datetime,SUBSTRING(bc_ultima_fecha_saldo_cero,1,2) + '/' +SUBSTRING(bc_ultima_fecha_saldo_cero,3,2) + '/' + SUBSTRING(bc_ultima_fecha_saldo_cero,5,4),103)
                                       else
                                            null
                                       end,                                            
          replace(replace(isnull(bc_limite_credito,0),'+',''),'-',''),
          replace(replace(isnull(bc_credito_maximo,0),'+',''),'-',''),
          replace(replace(isnull(bc_monto_pagar,0),'+',''),'-',''),
          bc_frecuencia_pagos,
          bc_numero_pagos,
          bc_fecha_mas_reciente_pago_historicos = case when bc_fecha_mas_reciente_pago_historicos is not null then
                                                      convert(datetime,SUBSTRING(bc_fecha_mas_reciente_pago_historicos,1,2) + '/' +SUBSTRING(bc_fecha_mas_reciente_pago_historicos,3,2) + '/' + SUBSTRING(bc_fecha_mas_reciente_pago_historicos,5,4),103)
                                                  else
                                                      null
                                                  end,  
          bc_fecha_mas_antigua_pago_historicos  = case when bc_fecha_mas_antigua_pago_historicos is not null then
                                                        convert(datetime,SUBSTRING(bc_fecha_mas_antigua_pago_historicos,1,2) + '/' +SUBSTRING(bc_fecha_mas_antigua_pago_historicos,3,2) + '/' + SUBSTRING(bc_fecha_mas_antigua_pago_historicos,5,4),103)
                                                  else
                                                       null
                                                  end                                                       
   from   cr_buro_cuenta,cr_interface_buro
   where  bc_id_cliente = ib_cliente
   and    bc_id_cliente = @i_cliente
   order by bc_forma_pago_actual, convert(datetime,SUBSTRING(bc_fecha_apertura_cuenta,1,2) + '/' +SUBSTRING(bc_fecha_apertura_cuenta,3,2) + '/' + SUBSTRING(bc_fecha_apertura_cuenta,5,4),103) desc


   update #cr_buro_cuenta
   set    bc_desc_tipo_contrato = c.valor
   from   cobis..cl_tabla t, cobis..cl_catalogo c
   where  t.tabla          = 'cr_tipo_contrato'
   and    t.codigo         = c.tabla
   and    bc_tipo_contrato = c.codigo 
   
   update #cr_buro_cuenta
   set    bc_desc_tipo_cuenta = c.valor
   from   cobis..cl_tabla t, cobis..cl_catalogo c
   where  t.tabla        = 'cr_tipo_cuenta'
   and    t.codigo       = c.tabla
   and    bc_tipo_cuenta = c.codigo 
   
   update #cr_buro_cuenta
   set    bc_desc_tipo_responsabilidad = c.valor
   from   cobis..cl_tabla t, cobis..cl_catalogo c
   where  t.tabla          = 'cr_tipo_responsabilidad'
   and    t.codigo         = c.tabla
   and    bc_indicador_tipo_responsabilidad = c.codigo 
   
   update #cr_buro_cuenta
   set    bc_desc_forma_pago_actual = cb_descripcion  
   from   cobis..cl_tabla t, cob_credito..cr_catalogo_buro c
   where  t.tabla              = 'cr_forma_pago'
   and    t.codigo             = c.cb_tabla
   and    bc_forma_pago_actual = c.cb_codigo  

   update #cr_buro_cuenta
   set    bc_desc_clave_observacion = cb_descripcion  
   from   cobis..cl_tabla t, cob_credito..cr_catalogo_buro c
   where  t.tabla              = 'cr_clave_observacion'
   and    t.codigo             = c.cb_tabla
   and    bc_clave_observacion = c.cb_codigo  
   
   insert into #tmp_cuenta_persona
   ( cp_cliente ,
     cp_mop     ,
     cp_numero  )
   select bc_id_cliente, bc_forma_pago_actual, count(1)
   from #cr_buro_cuenta
   group by bc_id_cliente, bc_forma_pago_actual

   select bc_forma_pago_actual,
          cp_cuentas_abiertas_a        = count(1), 
          cp_limite_cuentas_abiertas_a = sum(convert(money,replace(replace(bc_limite_credito,'+',''),'-',''))),         
          cp_saldo_actual_abiertas_a   = sum(convert(money,replace(replace(bc_saldo_actual,'+',''),'-',''))),
          cp_saldo_vencido_abiertas_a  = sum(convert(money,replace(replace(bc_saldo_vencido,'+',''),'-',''))),
          cp_pago_relizar_abiertas_a   = sum(convert(money,replace(replace(bc_monto_pagar,'+',''),'-','')))          
   into #tmp_cuentas_abiertas
   from   #cr_buro_cuenta
   where   bc_tipo_cuenta in ('O', 'R') 
   group by bc_forma_pago_actual
   
   
   update #tmp_cuenta_persona
   set     cp_cuentas_abiertas        = cp_cuentas_abiertas_a       ,
           cp_limite_cuentas_abiertas = cp_limite_cuentas_abiertas_a,
           cp_saldo_actual_abiertas   = cp_saldo_actual_abiertas_a  ,
           cp_saldo_vencido_abiertas  = cp_saldo_vencido_abiertas_a ,
           cp_pago_relizar_abiertas   = cp_pago_relizar_abiertas_a
   from    #tmp_cuentas_abiertas
   where   cp_mop        = bc_forma_pago_actual
   

   select bc_forma_pago_actual,
          cp_cuentas_cerradas_c        = count(1), 
          cp_limite_cuentas_cerradas_c = sum(convert(money,replace(replace(isnull(bc_limite_credito,0),'+',''),'-',''))),          
          cp_saldo_actual_cerradas_c   = sum(convert(money,replace(replace(isnull(bc_saldo_actual,0),'+',''),'-',''))),
          cp_monto_cerradas_c          = sum(convert(money,replace(replace(isnull(bc_monto_pagar,0),'+',''),'-','')))          
   into #tmp_cuentas_cerradas
   from   #cr_buro_cuenta
   where  bc_tipo_cuenta not in ('O', 'R')
   group by bc_forma_pago_actual
   
   update #tmp_cuenta_persona
   set    cp_cuentas_cerradas        = cp_cuentas_cerradas_c       ,
          cp_limite_cuentas_cerradas = cp_limite_cuentas_cerradas_c,         
          cp_saldo_actual_cerradas   = cp_saldo_actual_cerradas_c  ,
          cp_monto_cerradas          = cp_monto_cerradas_c
   from   #tmp_cuentas_cerradas
   where   cp_mop         = bc_forma_pago_actual
   
   --Pago Semanal
   select bc_forma_pago_actual, 
          cp_pago_relizar   = sum(convert(money,replace(replace(isnull(bc_monto_pagar,0),'+',''),'-','')))
   into #tmp_pagos
   from  #cr_buro_cuenta
   where bc_frecuencia_pagos = 'W'
   group by bc_forma_pago_actual
   
   update #tmp_cuenta_persona
   set    cp_pago_semanal = cp_pago_relizar
   from   #tmp_pagos
   where  cp_mop =  bc_forma_pago_actual
   
   --Pago Catorcenal
   truncate table #tmp_pagos
   
   insert into #tmp_pagos(
               bc_forma_pago_actual,
               cp_pago_relizar)
   select bc_forma_pago_actual,
          sum(convert(money,replace(replace(isnull(bc_monto_pagar,0),'+',''),'-','')))
   from  #cr_buro_cuenta
   where bc_frecuencia_pagos = 'K'
   group by bc_forma_pago_actual 
     
   update #tmp_cuenta_persona
   set    cp_pago_catorcenal = cp_pago_relizar
   from   #tmp_pagos
   where  cp_mop =  bc_forma_pago_actual
   
   --Pago Mensual
   truncate table #tmp_pagos
   
   insert into #tmp_pagos(
               bc_forma_pago_actual,
               cp_pago_relizar)
   select bc_forma_pago_actual,
          sum(convert(money,replace(replace(isnull(bc_monto_pagar,0),'+',''),'-','')))
   from  #cr_buro_cuenta
   where bc_frecuencia_pagos = 'M'
   group by bc_forma_pago_actual 
   
   update #tmp_cuenta_persona
   set    cp_pago_mensual = cp_pago_relizar
   from   #tmp_pagos
   where  cp_mop =  bc_forma_pago_actual             
             
  -- Datos Generales
   
   insert into #tmp_datos_generales
   (
      dg_codigo_cliente, dg_nombres        ,      dg_apellidos     ,   dg_rfc       ,
      dg_fecha_nac      ,      dg_codigo_est_civ,   dg_curp      
   )
   select en_ente, en_nombre + ' ' + p_s_nombre   ,
          p_p_apellido + ' ' + p_s_apellido,
          en_rfc      ,
          p_fecha_nac ,        
          p_estado_civil,
          en_ced_ruc      
   from cobis..cl_ente 
   where en_ente = @i_cliente

  
   update #tmp_datos_generales
   set    dg_estado_civ = c.valor
   from   cobis..cl_tabla t, 
          cobis..cl_catalogo c
   where  t.tabla  = 'cl_ecivil'
   and    t.codigo = c.tabla
   and    c.codigo = dg_codigo_est_civ
   
   select @w_fecha_reg = max(ib_fecha)
   from cob_credito..cr_interface_buro
   where ib_cliente = @i_cliente 
  
   -- Direcciones
   
   
   insert into #tmp_direcciones
    (
      di_calle_y_num  ,
      di_colonia      ,
      di_delegacion   ,
      di_ciudad       ,
      di_estado       ,
      di_codigo_postal,
      di_reg_fecha    )      
   select 'Calle'      = rtrim(ltrim(isnull(di_calle,'') + ' ' + isnull(convert(varchar(255),di_nro),'SN')+ ' ' + isnull(convert(varchar(255),di_nro_interno),'SN'))),
          'Colonia'    = (select top 1 isnull(pq_descripcion,'AN') 
                          from cobis..cl_parroquia 
                          where pq_parroquia = d1.di_parroquia),
          'Delegacion' = (select isnull(ci_descripcion,'AN') from cobis..cl_ciudad where ci_ciudad = di_ciudad),
          'Ciudad'     = di_poblacion,
          'Estado'     = (select  top 1 upper(ltrim(rtrim(pv_descripcion )))
                          from  cobis..cl_provincia, 
                                cobis..cl_pais, 
                                cobis..cl_depart_pais
                          where pv_pais        = pa_pais
                          and   pv_depart_pais = dp_departamento
                          and   pv_pais        = di_pais
                          and   pv_provincia   = di_provincia),        
          'CodigoPost' = (select case
                                 when eq_descripcion != 'MX' and di_codpostal is null then '00000'
                                 else di_codpostal
                                 end
                          from cob_conta_super..sb_equivalencias
                          where eq_catalogo='CL_PAIS_A6'
                          and eq_valor_cat = di_pais),
           @w_fecha_reg                     
   from cobis..cl_direccion d1
   where d1.di_ente    = @i_cliente
   and d1.di_tipo      = 'RE'
   
   
   --Retorno  
   select  'Nombres'     = ltrim(rtrim(dg_nombres)),
           'Apellidos'   = ltrim(rtrim(dg_apellidos)),
           'RFC'         = dg_rfc,
           'F_NACIMIENTO'= convert(varchar(10),dg_fecha_nac,@i_formato_fecha),
           'ESTADO_CIVIL'= dg_estado_civ,
           'CURP'        = dg_curp,
		   convert(varchar(10),@w_fecha_repore,@i_formato_fecha) + ' ' + convert(varchar(5),@w_fecha_repore,108),
           @w_sucursal      ,
           @w_nombre_func   ,
		   convert(varchar(10),@w_fecha_consulta,@i_formato_fecha) + ' ' + convert(varchar(5),@w_fecha_consulta,108),
		   dg_codigo_cliente
   from #tmp_datos_generales
    
   
   select  di_secuencial   ,
           di_calle_y_num  ,
           di_colonia      ,
           di_delegacion   ,
           di_ciudad       ,
           di_estado       ,
           di_codigo_postal,
		   convert(varchar(10),di_reg_fecha,@i_formato_fecha)
   from #tmp_direcciones
   
   select pr_seuencial,
          pr_banco,
          pr_ciclo,
		  convert(varchar(10),pr_fecha_apertura,@i_formato_fecha),
          convert(varchar(10),pr_fecha_fin,@i_formato_fecha),
          convert(varchar(10),pr_fecha_liquida,@i_formato_fecha),
          isnull(pr_dias_atraso,0),
          pr_monto_aprobado,
          pr_estado,
          pr_saldo_capital,
          pr_saldo_capital_mora,
          pr_dias_mora_acum,
          isnull(pr_dias_maximo_mora,0)
   from  #tmp_prestamos   
   
      
   select cp_cliente                ,
          cp_mop                    ,
          cp_numero                 ,
          cp_cuentas_abiertas       ,
          cp_limite_cuentas_abiertas,         
          cp_saldo_actual_abiertas  ,
          cp_saldo_vencido_abiertas ,
          cp_pago_relizar_abiertas  ,
          cp_pago_semanal           ,
          cp_pago_catorcenal        ,
          cp_pago_mensual           ,
          cp_cuentas_cerradas       ,
          cp_limite_cuentas_cerradas,          
          cp_saldo_actual_cerradas  ,
          cp_monto_cerradas         
   from   #tmp_cuenta_persona
      
   return 0


GO
