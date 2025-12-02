/************************************************************************/
/*  Archivo:                reporte_buro.sp                             */
/*  Stored procedure:       sp_reporte_buro                             */
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

if exists(select 1 from sysobjects where name ='sp_reporte_buro')
    drop proc sp_reporte_buro
GO


create proc sp_reporte_buro (
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
   @w_fecha_reg       datetime,
   @w_dias_pol        smallint,
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
   
   print 'Creacion Tablas Temporales'  
   
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
      bc_frecuencia_pagos varchar(1)   null,
      bc_numero_pagos                       varchar(4)   null,
      bc_fecha_mas_reciente_pago_historicos datetime     null,
      bc_fecha_mas_antigua_pago_historicos  datetime     null
   )
   
   create table #cr_score_buro
   (
     sb_secuencial   int identity,
     sb_cliente      int ,
     sb_nombre       varchar(30) null,
     sb_codigo       varchar(3)  null,
     sb_valor        varchar(4)  null,
     sb_codigo_razon varchar(3)  null,
     sb_codigo_error varchar(2)  null
    )
      
   
   create table #tmp_datos_generales
   (
      dg_nombres        varchar(255)  null,
      dg_apellidos      varchar(255)  null,
      dg_rfc            varchar(30)   null,
      dg_fecha_nac      datetime      null,
      dg_ife            varchar(30)   null,
      dg_codigo_est_civ varchar(10)   null,
      dg_estado_civ     varchar(60)   null,
      dg_fecha_registro datetime      null,
	  dg_curp           varchar(30)   null,
	  dg_folio          varchar(30)   null
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
   
   
   create table #tmp_cuenta_persona
   (
     cp_cliente                 int            ,
     cp_mop                     varchar(2) null,
     cp_cuentas_abiertas        int        null,
     cp_limite_cuentas_abiertas money      null,
     cp_maximo_abiertas         money      null,
     cp_saldo_actual_abiertas   money      null,
     cp_saldo_vencido_abiertas  money      null,
     cp_pago_relizar_abiertas   money      null,
     cp_cuentas_cerradas        int        null,
     cp_limite_cuentas_cerradas money      null,
     cp_maximo_cerradas         money      null,
     cp_saldo_actual_cerradas   money      null,
     cp_monto_cerradas          money      null
   )
   
    create table #tmp_resumen_cuentas
   (
     rc_cliente                              int            ,
     rc_Numero_cuentas                       int        null,
     rc_Cuentas_Pagos_fijos_Hipotecas        int        null,
     rc_Cuentas_Revolventes_Abiertas         int        null,
     rc_Cuentas_Cerradas                     int        null,
     rc_Cuentas_Negativas_Actuales           int        null, 
     rc_Cuentas_Disputa                      int        null,
     rc_NumeroSolicitudesUltimos6Meses       int        null,
     rc_TotalSaldosActualesRevolventes       money      null,
     rc_TotalSaldosVencidosRevolventes       money      null,
     rc_TotalSaldosActualesPagosFijos        money      null,
     rc_TotalSaldosVencidosPagosFijos        money      null,
     rc_TotalPagosPagosFijos                 money      null,
     rc_TotalCreditosMaximosPagosFijos       money      null,
     rc_PctLimiteCreditoUtilizadoRevolventes float      null,
     rc_CuentasClavesHistoriaNegativa        int        null,
     rc_NumeroTotalCuentasDespachoCobranza   int        null,
     rc_FechaAperCtaMasRecienteDespachoCob   datetime   null,
     rc_NumeroTotalSolicitudesDespachosCob   int        null,
     rc_FechaSolMasRecienteDespachoCobranza  datetime   null,
     rc_FechaAperturaCuentaMasAntigua        datetime   null,
     rc_FechaSolicitudReporteMasReciente     datetime   null, 
     rc_TotalSolicitudesReporte              int        null, 
     rc_FechaSolicitudReporteMasRecienteCre  datetime   null         
   )
   
   
    create table #tmp_consultas_efectuadas
   (
     ce_cliente               int              ,
     ce_otorgante             varchar(16)  null,   
     ce_fecha_consulta        datetime     null,
     ce_tipo_responsabilidad  varchar(64)  null,
     ce_tipo_contrato         money        null, 
     ce_importe_contrato      varchar(64)  null, --??
     ce_tipo_unidad_monetaria varchar(2)   null
   )
   
   
   
   create table #tmp_empleo_buro
	(
	eb_secuencial          int           identity,
	eb_fecha               datetime          null,
	eb_cliente             int               null,
    eb_nombre_empresa      varchar(40)       null,
    eb_direccion_uno       varchar(40)       null,
    eb_direccion_dos       varchar(40)       null,
    eb_colonia             varchar(40)       null,
    eb_delegacion          varchar(40)       null,
    eb_ciudad              varchar(40)       null,
    eb_estado              varchar(4)        null,
    eb_codigo_postal       varchar(5)        null,
    eb_numero_telefono     varchar(11)       null,
    eb_extension           varchar(8)        null,
    eb_fax                 varchar(11)       null,
    eb_cargo               varchar(30)       null,
    eb_fecha_contratacion  varchar(8)        null,
    eb_clave_moneda        varchar(2)        null,
    eb_salario             varchar(9)        null,
    eb_base_salarial	   varchar(1)        null,
    eb_num_empleado 	   varchar(15)       null,
    eb_fecha_ult_dia 	   varchar(8)        null,
    eb_codigo_pais 	       varchar(2)        null,
    
	)
   	
    -- Datos Buro
   print 'Fecha Buro'   
   select @w_fecha_consulta = max(ib_fecha)
   from  cr_interface_buro
   where ib_cliente = @i_cliente
   
   print 'Insert #cr_buro_cuenta Paso 1'   
   
   insert into #cr_buro_cuenta
     (
      bc_id_cliente           , 
      bc_forma_pago_actual    ,
      bc_historico_pagos      ,
      bc_nombre_otorgante     ,
      bc_clave_observacion    ,
      bc_saldo_actual         ,
      bc_saldo_vencido        ,
      bc_tipo_contrato        ,
      bc_fecha_apertura_cuenta,
      bc_tipo_cuenta          ,
      bc_indicador_tipo_responsabilidad,
      bc_numero_cuenta_actual   ,
      bc_clave_unidad_monetaria ,
      bc_fecha_actualizacion    ,
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
          bc_forma_pago_actual,
          bc_historico_pagos  ,
          bc_nombre_otorgante ,
          bc_clave_observacion,
          replace(replace(isnull(bc_saldo_actual,0),'+',''),'-',''),
          replace(replace(isnull(bc_saldo_vencido,0),'+',''),'-',''),
          bc_tipo_contrato,
          bc_fecha_apertura_cuenta = convert(datetime,SUBSTRING(bc_fecha_apertura_cuenta,1,2) + '/' +SUBSTRING(bc_fecha_apertura_cuenta,3,2) + '/' + SUBSTRING(bc_fecha_apertura_cuenta,5,4),103),
          bc_tipo_cuenta,
          bc_indicador_tipo_responsabilidad,
          bc_numero_cuenta_actual,
          bc_clave_unidad_monetaria,
          bc_fecha_actualizacion = case when bc_fecha_actualizacion = '01010001' then '01/01/1900'
		                           when bc_fecha_actualizacion is not null and isdate(SUBSTRING(bc_fecha_actualizacion,1,2) + '/' +SUBSTRING(bc_fecha_actualizacion,3,2) + '/' + SUBSTRING(bc_fecha_actualizacion,5,4))=1 then
                                        convert(datetime,SUBSTRING(bc_fecha_actualizacion,1,2) + '/' +SUBSTRING(bc_fecha_actualizacion,3,2) + '/' + SUBSTRING(bc_fecha_actualizacion,5,4),103)
                                   else
                                        null 
                                   end,
          bc_fecha_ultimo_pago   = case when bc_fecha_ultimo_pago = '01010001' then '01/01/1900'
		                           when bc_fecha_ultimo_pago is not null then
            convert(datetime,SUBSTRING(bc_fecha_ultimo_pago,1,2) + '/' +SUBSTRING(bc_fecha_ultimo_pago,3,2) + '/' + SUBSTRING(bc_fecha_ultimo_pago,5,4),103)
                                   else
                                        null
                                   end, 
          bc_fecha_ultima_compra = case when bc_fecha_ultima_compra = '01010001' then '01/01/1900'
		                           when bc_fecha_ultima_compra is not null then
                                        convert(datetime,SUBSTRING(bc_fecha_ultima_compra,1,2) + '/' +SUBSTRING(bc_fecha_ultima_compra,3,2) + '/' + SUBSTRING(bc_fecha_ultima_compra,5,4),103)
                                   else
                                        null
                                   end,                                          
          bc_fecha_cierre_cuenta = case when bc_fecha_cierre_cuenta = '01010001' then '01/01/1900' -- por este campo se dio el problema
		                           when bc_fecha_cierre_cuenta is not null then
                                        convert(datetime,SUBSTRING(bc_fecha_cierre_cuenta,1,2) + '/' +SUBSTRING(bc_fecha_cierre_cuenta,3,2) + '/' + SUBSTRING(bc_fecha_cierre_cuenta,5,4),103)
                                   else
                                        null
                                   end,
          bc_ultima_fecha_saldo_cero =  case when bc_ultima_fecha_saldo_cero = '01010001' then '01/01/1900'
		                                when bc_ultima_fecha_saldo_cero is not null then          
                                             convert(datetime,SUBSTRING(bc_ultima_fecha_saldo_cero,1,2) + '/' +SUBSTRING(bc_ultima_fecha_saldo_cero,3,2) + '/' + SUBSTRING(bc_ultima_fecha_saldo_cero,5,4),103)
                                        else
                                             null
                                        end,
          replace(replace(isnull(bc_limite_credito,0),'+',''),'-',''),
          replace(replace(isnull(bc_credito_maximo,0),'+',''),'-',''),
          replace(replace(isnull(bc_monto_pagar,0),'+',''),'-',''),
          bc_frecuencia_pagos,
          bc_numero_pagos,
          bc_fecha_mas_reciente_pago_historicos = 	case when bc_fecha_mas_reciente_pago_historicos = '01010001' then '01/01/1900'
		                                            when bc_fecha_mas_reciente_pago_historicos is not null then
                                                         convert(datetime,SUBSTRING(bc_fecha_mas_reciente_pago_historicos,1,2) + '/' +SUBSTRING(bc_fecha_mas_reciente_pago_historicos,3,2) + '/' + SUBSTRING(bc_fecha_mas_reciente_pago_historicos,5,4),103)
                                                    else
                                                         null
                                                    end, 
          bc_fecha_mas_antigua_pago_historicos  =   case when bc_fecha_mas_antigua_pago_historicos = '01010001' then '01/01/1900'
		                                            when bc_fecha_mas_antigua_pago_historicos is not null then
                                                         convert(datetime,SUBSTRING(bc_fecha_mas_antigua_pago_historicos,1,2) + '/' +SUBSTRING(bc_fecha_mas_antigua_pago_historicos,3,2) + '/' + SUBSTRING(bc_fecha_mas_antigua_pago_historicos,5,4),103)
                                                    else
                                                         null
                                                    end    
   from   cr_buro_cuenta,cr_interface_buro
   where  bc_id_cliente = ib_cliente
   and    bc_id_cliente = @i_cliente
   order by bc_forma_pago_actual, convert(datetime,SUBSTRING(bc_fecha_apertura_cuenta,1,2) + '/' +SUBSTRING(bc_fecha_apertura_cuenta,3,2) + '/' + SUBSTRING(bc_fecha_apertura_cuenta,5,4),103) desc

   print 'Update #cr_buro_cuenta Paso 2'   

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
   
   print 'Insert #tmp_cuenta_persona Paso 3'   
   
   insert into #tmp_cuenta_persona
   ( cp_cliente ,
     cp_mop     )
   select bc_id_cliente, bc_forma_pago_actual
   from #cr_buro_cuenta
   group by bc_id_cliente, bc_forma_pago_actual

   print 'Insert #tmp_cuentas_abiertas Paso 4'
   
   select bc_forma_pago_actual,
          cp_cuentas_abiertas_a        = count(1), 
          cp_limite_cuentas_abiertas_a = sum(convert(money,replace(replace(isnull(bc_limite_credito,0),'+',''),'-',''))),
          cp_maximo_abiertas_a         = sum(convert(money,replace(replace(isnull(bc_credito_maximo,0),'+',''),'-',''))),
          cp_saldo_actual_abiertas_a   = sum(convert(money,replace(replace(isnull(bc_saldo_actual,0),'+',''),'-',''))),
          cp_saldo_vencido_abiertas_a  = sum(convert(money,replace(replace(isnull(bc_saldo_vencido,0),'+',''),'-',''))),
          cp_pago_relizar_abiertas_a   = sum(convert(money,replace(replace(isnull(bc_monto_pagar,0),'+',''),'-','')))          
   into #tmp_cuentas_abiertas
   from   #cr_buro_cuenta
   where   bc_tipo_cuenta in ('O', 'R') 
   group by bc_forma_pago_actual
   
   print 'Update #tmp_cuenta_persona 1 Paso 5'   
   
   update #tmp_cuenta_persona
   set     cp_cuentas_abiertas        = cp_cuentas_abiertas_a       ,
           cp_limite_cuentas_abiertas = cp_limite_cuentas_abiertas_a,
           cp_maximo_abiertas         = cp_maximo_abiertas_a        ,
           cp_saldo_actual_abiertas   = cp_saldo_actual_abiertas_a  ,
           cp_saldo_vencido_abiertas  = cp_saldo_vencido_abiertas_a ,
           cp_pago_relizar_abiertas   = cp_pago_relizar_abiertas_a
   from    #tmp_cuentas_abiertas
   where   cp_mop        = bc_forma_pago_actual
   
   print 'Insert #tmp_cuentas_cerradas Paso 6'
   
   select bc_forma_pago_actual,
          cp_cuentas_cerradas_c        = count(1), 
          cp_limite_cuentas_cerradas_c = sum(convert(money,replace(replace(isnull(bc_limite_credito,0),'+',''),'-',''))),
          cp_maximo_cerradas_c         = sum(convert(money,replace(replace(isnull(bc_credito_maximo,0),'+',''),'-',''))),
          cp_saldo_actual_cerradas_c   = sum(convert(money,replace(replace(isnull(bc_saldo_actual,0),'+',''),'-',''))),
          cp_monto_cerradas_c          = sum(convert(money,replace(replace(isnull(bc_monto_pagar,0),'+',''),'-','')))          
   into #tmp_cuentas_cerradas
   from   #cr_buro_cuenta
   where  bc_tipo_cuenta not in ('O', 'R')
   group by bc_forma_pago_actual
   
   print 'Update #tmp_cuenta_persona 1 Paso 7'   
      
   update #tmp_cuenta_persona
   set    cp_cuentas_cerradas        = cp_cuentas_cerradas_c       ,
          cp_limite_cuentas_cerradas = cp_limite_cuentas_cerradas_c,
          cp_maximo_cerradas         = cp_maximo_cerradas_c        ,
          cp_saldo_actual_cerradas   = cp_saldo_actual_cerradas_c  ,
          cp_monto_cerradas          = cp_monto_cerradas_c
   from   #tmp_cuentas_cerradas
   where   cp_mop         = bc_forma_pago_actual
   
   print 'Insert into #tmp_resumen_cuentas Paso 8'   
  
   insert into #tmp_resumen_cuentas
   (
     rc_cliente                             ,
     rc_Numero_cuentas                      ,
     rc_Cuentas_Pagos_fijos_Hipotecas       ,
     rc_Cuentas_Revolventes_Abiertas        ,
     rc_Cuentas_Cerradas                    ,
     rc_Cuentas_Negativas_Actuales          ,
     rc_Cuentas_Disputa                     ,
     rc_NumeroSolicitudesUltimos6Meses      ,
     rc_TotalSaldosActualesRevolventes      ,
     rc_TotalSaldosVencidosRevolventes      ,
     rc_TotalSaldosActualesPagosFijos       ,
     rc_TotalSaldosVencidosPagosFijos       ,
     rc_TotalPagosPagosFijos                ,
     rc_TotalCreditosMaximosPagosFijos      ,
     rc_PctLimiteCreditoUtilizadoRevolventes,
     rc_CuentasClavesHistoriaNegativa       ,
     rc_NumeroTotalCuentasDespachoCobranza  ,
     rc_FechaAperCtaMasRecienteDespachoCob  ,
     rc_NumeroTotalSolicitudesDespachosCob  ,
     rc_FechaSolMasRecienteDespachoCobranza ,
     rc_FechaAperturaCuentaMasAntigua       ,
     rc_FechaSolicitudReporteMasReciente    ,
     rc_TotalSolicitudesReporte             ,
     rc_FechaSolicitudReporteMasRecienteCre )   
   select br_id_cliente,
          case when ISNUMERIC(replace(replace(br_numero_cuentas,'+',''),'-',''))=1  then
                    convert(int,replace(replace(br_numero_cuentas,'+',''),'-',''))
          else 
               null
          end,
          case when ISNUMERIC(replace(replace(br_cuentas_pagos_fijos_hipotecas,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_cuentas_pagos_fijos_hipotecas,'+',''),'-',''))
          else
               null
          end,        
          case when ISNUMERIC(replace(replace(br_cuentas_revolventes_abiertas,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_cuentas_revolventes_abiertas,'+',''),'-',''))
          else
               null
          end,         
          case when ISNUMERIC(replace(replace(br_cuentas_cerradas,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_cuentas_cerradas,'+',''),'-',''))
          else
                     null
          end,
          case when ISNUMERIC(replace(replace(br_cuentas_negativas_actuales,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_cuentas_negativas_actuales,'+',''),'-',''))
          else
               null
          end,     
          case when ISNUMERIC(replace(replace(br_cuentas_disputa,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_cuentas_disputa,'+',''),'-',''))
          else
               null
          end,
          case when ISNUMERIC(replace(replace(br_numero_solicitudes_ultimos_6_meses,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_numero_solicitudes_ultimos_6_meses,'+',''),'-',''))
          else
               null
          end,
          case when ISNUMERIC(replace(replace(br_total_saldos_actuales_revolventes,'+',''),'-',''))=1  then
               convert(money,replace(replace(br_total_saldos_actuales_revolventes,'+',''),'-',''))
          else
               null
          end,            
          case when ISNUMERIC(replace(replace(br_total_saldos_vencidos_revolventes,'+',''),'-',''))=1  then
               convert(money,replace(replace(br_total_saldos_vencidos_revolventes,'+',''),'-',''))
          else
               null
          end,
          case when ISNUMERIC(replace(replace(br_total_saldos_actuales_pagos_fijos,'+',''),'-',''))=1  then
               convert(money,replace(replace(br_total_saldos_actuales_pagos_fijos,'+',''),'-',''))
          else
              null
          end,
          case when ISNUMERIC(replace(replace(br_total_saldos_vencidos_pagos_fijos,'+',''),'-',''))=1  then
               convert(money,replace(replace(br_total_saldos_vencidos_pagos_fijos,'+',''),'-',''))
          else
               null
          end,
          case when ISNUMERIC(replace(replace(br_total_pagos_pagos_fijos,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_total_pagos_pagos_fijos,'+',''),'-',''))
          else
               null
          end,
          case when ISNUMERIC(replace(replace(br_total_creditos_maximos_pagos_fijos,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_total_creditos_maximos_pagos_fijos,'+',''),'-',''))
          else
               null
          end,                
          case when ISNUMERIC(replace(replace(br_pct_limite_credito_utilizado_revolventes,'+',''),'-',''))=1  then
               convert(float,replace(replace(br_pct_limite_credito_utilizado_revolventes,'+',''),'-',''))
          else
               null
          end,
          case when ISNUMERIC(replace(replace(br_cuentas_claves_historia_negativa,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_cuentas_claves_historia_negativa,'+',''),'-',''))
          else
               null
          end,
          case when ISNUMERIC(replace(replace(br_numero_total_cuentas_despacho_cobranza,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_numero_total_cuentas_despacho_cobranza,'+',''),'-',''))
          else
               null
          end,
          br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza = case when isdate(SUBSTRING(br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza,1,2) + '/' +SUBSTRING(br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza,3,2) + '/' + SUBSTRING(br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza,5,4)) = 1 and br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza is not null then 
                                                                         convert(datetime,SUBSTRING(br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza,1,2) + '/' +SUBSTRING(br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza,3,2) + '/' + SUBSTRING(br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza,5,4),103)                                                                        
                                                                    else
                                                                         null
                                                                    end,
          case when ISNUMERIC(replace(replace(br_numero_total_solicitudes_despachos_cobranza,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_numero_total_solicitudes_despachos_cobranza,'+',''),'-',''))
          else
               null
          end,
          br_fecha_solicitud_mas_reciente_despacho_cobranza = case when isdate(SUBSTRING(br_fecha_solicitud_mas_reciente_despacho_cobranza,1,2) + '/' +SUBSTRING(br_fecha_solicitud_mas_reciente_despacho_cobranza,3,2) + '/' + SUBSTRING(br_fecha_solicitud_mas_reciente_despacho_cobranza,5,4)) = 1 and br_fecha_solicitud_mas_reciente_despacho_cobranza is not null then 
                                                                        convert(datetime,SUBSTRING(br_fecha_solicitud_mas_reciente_despacho_cobranza,1,2) + '/' +SUBSTRING(br_fecha_solicitud_mas_reciente_despacho_cobranza,3,2) + '/' + SUBSTRING(br_fecha_solicitud_mas_reciente_despacho_cobranza,5,4),103)                                                                       
                                                                   else
                                                                        null
                                                                   end,
          br_fecha_apertura_cuenta_mas_antigua = case when isdate(SUBSTRING(br_fecha_apertura_cuenta_mas_antigua,1,2) + '/' +SUBSTRING(br_fecha_apertura_cuenta_mas_antigua,3,2) + '/' + SUBSTRING(br_fecha_apertura_cuenta_mas_antigua,5,4)) = 1 then 
                                                           convert(datetime,SUBSTRING(br_fecha_apertura_cuenta_mas_antigua,1,2) + '/' +SUBSTRING(br_fecha_apertura_cuenta_mas_antigua,3,2) + '/' + SUBSTRING(br_fecha_apertura_cuenta_mas_antigua,5,4),103)                                                          
                                                 else
                                                      null
                                                 end,          
          br_fecha_apertura_cuenta_mas_reciente = case when isdate(SUBSTRING(br_fecha_apertura_cuenta_mas_reciente,1,2) + '/' +SUBSTRING(br_fecha_apertura_cuenta_mas_reciente,3,2) + '/' + SUBSTRING(br_fecha_apertura_cuenta_mas_reciente,5,4)) = 1 then 
                                                       convert(datetime,SUBSTRING(br_fecha_apertura_cuenta_mas_reciente,1,2) + '/' +SUBSTRING(br_fecha_apertura_cuenta_mas_reciente,3,2) + '/' + SUBSTRING(br_fecha_apertura_cuenta_mas_reciente,5,4),103)                                                      
                                                  else
                                                       null
                                                  end,
          case when ISNUMERIC(replace(replace(br_total_solicitudes_reporte,'+',''),'-',''))=1  then
               convert(int,replace(replace(br_total_solicitudes_reporte,'+',''),'-',''))
          else
               null
          end,
          br_fecha_solicitud_reporte_mas_reciente = case when isdate(SUBSTRING(br_fecha_solicitud_reporte_mas_reciente,1,2) + '/' +SUBSTRING(br_fecha_solicitud_reporte_mas_reciente,3,2) + '/' + SUBSTRING(br_fecha_solicitud_reporte_mas_reciente,5,4)) = 1 then 
                                                          convert(datetime,SUBSTRING(br_fecha_solicitud_reporte_mas_reciente,1,2) + '/' +SUBSTRING(br_fecha_solicitud_reporte_mas_reciente,3,2) + '/' + SUBSTRING(br_fecha_solicitud_reporte_mas_reciente,5,4),103)                                                        
                                                    else
                                                         null
                                                    end
   from cr_buro_resumen_reporte
   where br_id_cliente= @i_cliente
  
   print 'Insert into #tmp_consultas_efectuadas Paso 9'   
   
   insert into #tmp_consultas_efectuadas
   (
     ce_cliente               ,
     ce_otorgante             ,   
     ce_fecha_consulta        ,
     ce_tipo_responsabilidad  ,
     ce_tipo_contrato         , 
     ce_importe_contrato      , 
     ce_tipo_unidad_monetaria
     )
     select ce_cliente,
            ce_nombre_otorgante,
            ce_fecha_consulta       = case when ce_fecha_consulta is not null then
                                           convert(datetime,SUBSTRING(ce_fecha_consulta,1,2) + '/' +SUBSTRING(ce_fecha_consulta,3,2) + '/' + SUBSTRING(ce_fecha_consulta,5,4),103)
                                      else
                                           null
                                      end,                                           
            ce_tipo_responsabilidad =(select c.valor
                                      from   cobis..cl_tabla t, cobis..cl_catalogo c
                                      where  t.tabla          = 'cr_tipo_responsabilidad'
                                      and    t.codigo         = c.tabla
                                      and    c.codigo         = ce_ind_tipo_responsa),
            ce_importe_contrato = case when ISNUMERIC(replace(replace(ce_importe_contrato,'+',''),'-',''))=1  then
                                       convert(money,replace(replace(ce_importe_contrato,'+',''),'-',''))
                                  else
                     0
                                  end,
            ce_tipo_contrato,
            ce_clave_monetaria                 
     from cr_consultas_buro
     where   ce_cliente = @i_cliente
   
   -- Datos Generales
   print 'Insert into #tmp_datos_generales Paso 10'
   
   insert into #tmp_datos_generales
   (
      dg_nombres        ,      dg_apellidos,   dg_rfc       ,
      dg_fecha_nac      ,      dg_ife      ,   dg_codigo_est_civ,
      dg_curp	        ,      dg_folio
   )
   select en_nombre + ' ' + p_s_nombre   ,
          p_p_apellido + ' ' + p_s_apellido,
          en_rfc      ,
          p_fecha_nac ,
          null        ,
          p_estado_civil, 
          en_ced_ruc,
          ''		  
   from cobis..cl_ente 
   where en_ente = @i_cliente
   
   print 'Update #tmp_datos_generales Paso 11'

   update #tmp_datos_generales
   set    dg_estado_civ = c.valor
   from   cobis..cl_tabla t, 
          cobis..cl_catalogo c
   where  t.tabla  = 'cl_ecivil'
   and    t.codigo = c.tabla
   and    c.codigo = dg_codigo_est_civ
   
   update #tmp_datos_generales
   set    dg_folio = ib_folio
   from   cob_credito..cr_interface_buro 
   where ib_cliente = @i_cliente
   
   select @w_fecha_reg = min(bc_fecha_apertura_cuenta)
   from #cr_buro_cuenta  
   
   update #tmp_datos_generales
   set    dg_fecha_registro = @w_fecha_reg
   
   print 'Insert into #tmp_direcciones Paso 12'
   
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
   select db_direccion_uno + ' ' + db_direccion_dos,
          db_colonia,
          db_delegacion,
          db_ciudad,
          db_estado,
          db_codigo_postal,
          case when isdate(SUBSTRING(db_fecha_reporte,1,2) + '/' +SUBSTRING(db_fecha_reporte,3,2) + '/' + SUBSTRING(db_fecha_reporte,5,4)) = 1 then 
                    convert(datetime,SUBSTRING(db_fecha_reporte,1,2) + '/' +SUBSTRING(db_fecha_reporte,3,2) + '/' + SUBSTRING(db_fecha_reporte,5,4),103)                                                        
               else
                    db_fecha
               end
   from  cob_credito..cr_direccion_buro
   where db_cliente =   @i_cliente     
   
   print 'Insert into #cr_score_buro Paso 13'
   
   insert into #cr_score_buro
   (
     sb_cliente     ,
     sb_nombre      ,
     sb_codigo      ,
     sb_valor       ,
     sb_codigo_razon,
     sb_codigo_error
    )
    select sb_cliente,
           sb_nombre,
           sb_codigo,
           sb_valor,
           sb_codigo_razon,
           sb_codigo_error
    from cob_credito..cr_score_buro
    where sb_cliente = @i_cliente
    
    print 'Insert into #tmp_empleo_buro Paso 14'
    
    insert into #tmp_empleo_buro(
    	eb_nombre_empresa     ,    	  eb_cargo        ,
        eb_salario            ,       eb_base_salarial,
        eb_direccion_uno      ,       eb_colonia      ,
        eb_delegacion         ,       eb_ciudad       ,
        eb_estado             ,       eb_codigo_postal,
        eb_numero_telefono    ,       eb_fecha_contratacion)
   select
        eb_nombre_empresa     ,    	  eb_cargo        ,
        eb_salario            ,       eb_base_salarial,
        eb_direccion_uno      ,       eb_colonia      ,
        eb_delegacion         ,       eb_ciudad       ,
        eb_estado             ,       eb_codigo_postal,
        eb_numero_telefono    ,       eb_fecha_contratacion
   from  cr_empleo_buro
   where eb_cliente =    @i_cliente 
      
   print 'Select #tmp_datos_generales Paso 15'
   
   select  'Nombres'     = ltrim(rtrim(dg_nombres)),
           'Apellidos'   = ltrim(rtrim(dg_apellidos)),
           'RFC'         = dg_rfc,
           'F_NACIMIENTO'= convert(varchar(10),dg_fecha_nac,@i_formato_fecha),
         'IFE'         = dg_ife,
           'ESTADO_CIVIL'= dg_estado_civ, 
           'F_REGISTRO'  = convert(varchar(10),dg_fecha_registro,@i_formato_fecha),
           convert(varchar(10),@w_fecha_repore,@i_formato_fecha) + ' ' + convert(varchar(5),@w_fecha_repore,108),
           @w_sucursal      ,
           @w_nombre_func   ,
		   convert(varchar(10),@w_fecha_consulta,@i_formato_fecha) + ' ' + convert(varchar(5),@w_fecha_consulta,108),
		   'FolioConsultaBuro'     = dg_folio,
		   'CURP'       = dg_curp
   from #tmp_datos_generales 
    
   print 'Select #tmp_direcciones Paso 16'
   
   select  di_secuencial   ,
           di_calle_y_num  ,
           di_colonia      ,
           di_delegacion   ,
           di_ciudad       ,
           di_estado       ,
           di_codigo_postal,            
		   convert(varchar(10),di_reg_fecha,@i_formato_fecha)
   from #tmp_direcciones  
   
   print 'Select #tmp_empleo_buro Paso 17'
   
    select
        eb_nombre_empresa     ,    	  eb_cargo        ,
        eb_salario            ,       eb_base_salarial,
        eb_direccion_uno      ,       eb_colonia      ,
        eb_delegacion         ,       eb_ciudad       ,
        eb_estado             ,       eb_codigo_postal,
        eb_numero_telefono    ,       eb_fecha_contratacion
   from  #tmp_empleo_buro 
   
   print 'Select #cr_buro_cuenta Paso 18'
  
   select bc_numero            ,
          bc_desc_tipo_contrato,
          bc_desc_tipo_cuenta  ,
          bc_desc_tipo_responsabilidad,
          bc_nombre_otorgante,
          bc_numero_cuenta_actual,
          bc_clave_unidad_monetaria,
		  convert(varchar(10),bc_fecha_actualizacion,@i_formato_fecha),
		  convert(varchar(10),bc_fecha_apertura_cuenta,@i_formato_fecha),
          convert(varchar(10),bc_fecha_ultimo_pago,@i_formato_fecha),
          convert(varchar(10),bc_fecha_ultima_compra,@i_formato_fecha),
          convert(varchar(10),bc_fecha_cierre_cuenta,@i_formato_fecha),
          convert(varchar(10),bc_ultima_fecha_saldo_cero,@i_formato_fecha),
          convert(money,bc_limite_credito),
          convert(money,bc_credito_maximo),
          convert(money,bc_saldo_actual),
          convert(money,bc_saldo_vencido),
          convert(money,bc_monto_pagar),
          bc_frecuencia_pagos,
          bc_numero_pagos,
          bc_desc_forma_pago_actual,
          convert(varchar(10),bc_fecha_mas_reciente_pago_historicos,@i_formato_fecha),
          convert(varchar(10),bc_fecha_mas_antigua_pago_historicos,@i_formato_fecha),
          bc_historico_pagos,
          bc_desc_clave_observacion
   from #cr_buro_cuenta
  
  print 'Select #tmp_resumen_cuentas Paso 19'
  
    select rc_Numero_cuentas                ,
           rc_Cuentas_Pagos_fijos_Hipotecas ,
           rc_Cuentas_Revolventes_Abiertas  ,
           rc_Cuentas_Cerradas              ,
           rc_Cuentas_Negativas_Actuales    ,
           rc_Cuentas_Disputa               ,
           rc_NumeroSolicitudesUltimos6Meses,
           rc_TotalSaldosActualesRevolventes,
           rc_TotalSaldosVencidosRevolventes,
           rc_TotalSaldosActualesPagosFijos ,
           rc_TotalSaldosVencidosPagosFijos ,
           rc_TotalPagosPagosFijos          ,
           rc_TotalCreditosMaximosPagosFijos,
           rc_PctLimiteCreditoUtilizadoRevolventes,
           rc_CuentasClavesHistoriaNegativa,
           rc_NumeroTotalCuentasDespachoCobranza,
           rc_FechaAperCtaMasRecienteDespachoCob,
           rc_NumeroTotalSolicitudesDespachosCob,
           convert(varchar(10),rc_FechaSolMasRecienteDespachoCobranza,@i_formato_fecha),
           convert(varchar(10),rc_FechaAperturaCuentaMasAntigua,@i_formato_fecha),
           convert(varchar(10),rc_FechaSolicitudReporteMasReciente,@i_formato_fecha),
           rc_TotalSolicitudesReporte,
           rc_FechaSolicitudReporteMasRecienteCre
   from   #tmp_resumen_cuentas
   
   print 'Select #tmp_cuenta_persona Paso 20'  
   
   select cp_cliente                ,
          cp_mop                    ,
          cp_cuentas_abiertas       ,
          cp_limite_cuentas_abiertas,
          cp_maximo_abiertas        ,
          cp_saldo_actual_abiertas  ,
          cp_saldo_vencido_abiertas ,
          cp_pago_relizar_abiertas  ,
          cp_cuentas_cerradas       ,
          cp_limite_cuentas_cerradas,
          cp_maximo_cerradas        ,
          cp_saldo_actual_cerradas  ,
          cp_monto_cerradas         
   from   #tmp_cuenta_persona
   
   print 'Select #tmp_consultas_efectuadas Paso 21'  
   
   select
     ce_cliente               ,
     ce_otorgante             ,   
     convert(varchar(10),ce_fecha_consulta,@i_formato_fecha),
     ce_tipo_responsabilidad  ,
     ce_tipo_contrato         , 
     ce_importe_contrato      , 
     ce_tipo_unidad_monetaria
   from #tmp_consultas_efectuadas
   
   print 'Select #cr_score_buro Paso 22'  
   
   select sb_secuencial,
          sb_nombre,
          sb_codigo,
          sb_valor,
          sb_codigo_razon,
          sb_codigo_error
   from  #cr_score_buro
   
    print 'FIN'  

   return 0

GO
