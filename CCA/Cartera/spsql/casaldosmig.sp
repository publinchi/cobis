/************************************************************************/
/*   Archivo:              saldosmig.sp                                 */
/*   Stored procedure:     sp_saldos_mig                                */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Julio C Quintero                             */
/*   Fecha de escritura:   Feb. 2004                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Saldos de Activas por diferentes conceptos para Analisis del       */
/*   Proceso de Migraci¢n (Carga y Precarga).                           */
/*                            MODIFICACIONES                            */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists(SELECT 1 FROM sysobjects WHERE name = 'sp_saldos_mig')
   drop proc sp_saldos_mig
go


create proc sp_saldos_mig
@i_fecha      datetime
as
declare
   @w_error          int
begin

   truncate table cu_cargamigra
   truncate table ca_cargamigra
   truncate table cr_cargaprovision
   truncate table cr_cargatemporalidad 
   truncate table tmp_cr_califica_prov
   truncate table tmp_calif_op

  -- VALIDACION PROCESO DE GARANTIAS

  -- PRECARGA INSERCION VALOR FUTUROS CREDITOS

  INSERT INTO cu_cargamigra

  SELECT cu_oficina_contabili, 
         cu_clase_cartera,
         cu_estado,
         'P',
         count(distinct(cu_codigo_externo)),
         isnull(sum(cu_disponible),0)
  FROM   mig_garantias..cu_custodia
  WHERE  cu_estado    =  'F'
  GROUP  BY cu_oficina_contabili,cu_clase_cartera,cu_estado

  UNION

  -- PRECARGA VIGENTES CON OBLIGACION IDONEAS

  SELECT cu_oficina_contabili,
         cu_clase_cartera,
         substring(cu_estado,1,1)+ltrim(cu_clase_custodia),
         'P',
         count(distinct(cu_codigo_externo)),
         isnull(sum(gp_valor_resp_garant),0)
  FROM   mig_garantias..cu_custodia,
         mig_garantias..cr_gar_propuesta
  WHERE  cu_estado         = 'V'
  AND    cu_clase_custodia = 'I'
  AND    gp_garantia       = cu_codigo_externo
  GROUP  BY cu_oficina_contabili,cu_clase_cartera,substring(cu_estado,1,1)+ltrim(cu_clase_custodia)

  UNION

  -- PRECARGA VIGENTES CON OBLIGACION NO IDONEAS

  SELECT cu_oficina_contabili,
         cu_clase_cartera,
         substring(cu_estado,1,1)+ltrim(cu_clase_custodia),
         'P',
         count(distinct(cu_codigo_externo)),
         isnull(sum(cu_valor_inicial),0)
  FROM   mig_garantias..cu_custodia,
         mig_garantias..cr_gar_propuesta,
         mig_cartera..ca_operacion_mig,
         cob_custodia..cu_tipo_custodia
  WHERE  cu_estado         = 'V'
  AND    cu_clase_custodia = 'O'
  AND    cu_codigo_externo = gp_garantia 
  AND    cu_tipo           = tc_tipo
  AND    tc_clase          = 'I'
  AND    tc_contabilizar   = 'S'
  AND    opm_migrada       = gp_tramite
  GROUP  BY  cu_oficina_contabili,cu_clase_cartera,substring(cu_estado,1,1)+ltrim(cu_clase_custodia)

  UNION

  -- PRECARGA VIGENTES POR CANCELAR  (PENDIENTES)


  SELECT cu_oficina_contabili,
         cu_clase_cartera,
         cu_estado,
         'P',
         count(distinct(cu_codigo_externo)),
         isnull(sum(cu_valor_inicial),0) 
  FROM   mig_garantias..cu_custodia
  WHERE  cu_estado = 'X'
  GROUP  BY cu_oficina_contabili,cu_clase_cartera,cu_estado

  UNION

  -- CARGA INSERCION VALOR FUTUROS CREDITOS  

  SELECT cu_oficina_contabiliza, 
         cu_clase_cartera,
         cu_estado,        
         'C',
         count(distinct(cu_codigo_externo)),
         isnull(sum(cu_acum_ajuste) ,0)
  FROM   cob_custodia..cu_custodia
  WHERE  cu_estado =  'F'
  GROUP  BY  cu_oficina_contabiliza,cu_clase_cartera,cu_estado

  UNION

  -- CARGA VIGENTES CON OBLIGACION IDONEAS

  SELECT cu_oficina_contabiliza,
         dg_clase_cartera,
         substring(cu_estado,1,1)+ltrim(cu_clase_custodia),
         'C',         
         count(distinct(cu_codigo_externo)),
         isnull(sum(dg_valor_resp_garantia)  ,0)
  FROM   cob_custodia..cu_custodia,
         cob_custodia..cu_distr_garantia
  WHERE  cu_estado         = 'V'
  AND    cu_clase_custodia = 'I'
  AND    dg_garantia       = cu_codigo_externo
  GROUP  BY  cu_oficina_contabiliza,dg_clase_cartera,substring(cu_estado,1,1)+ltrim(cu_clase_custodia)

  UNION

  -- CARGA VIGENTES CON OBLIGACION NO IDONEAS

  SELECT cu_oficina_contabiliza,
         op_clase,
         substring(cu_estado,1,1)+ltrim(cu_clase_custodia),
         'C',
         count(distinct(cu_codigo_externo)),
         isnull(sum(cu_valor_inicial)  ,0)
  FROM   cob_custodia..cu_custodia,
         cob_custodia..cu_tipo_custodia,
         cob_credito..cr_gar_propuesta,
         cob_cartera..ca_operacion
  WHERE  cu_estado         = 'V'
  AND    cu_clase_custodia = 'O'
  AND    cu_tipo           = tc_tipo
  AND    tc_clase          = 'I'
  AND    tc_contabilizar   = 'S'
  AND    op_tramite        = gp_tramite
  AND    gp_garantia       = cu_codigo_externo
  GROUP  BY cu_oficina_contabiliza,op_clase,substring(cu_estado,1,1)+ltrim(cu_clase_custodia)



  UNION 


  -- CARGA VIGENTES POR CANCELAR  (PENDIENTES)

  SELECT cu_oficina_contabiliza,
         cu_clase_cartera,
         cu_estado,
         'C',
         count(distinct(cu_codigo_externo)),
         isnull(sum(cu_valor_inicial) ,0)
  FROM   cob_custodia..cu_custodia
  WHERE  cu_estado = 'X'
  GROUP  BY cu_oficina_contabiliza, cu_clase_cartera,cu_estado

  -- VALIDACION PROCESO DE CARTERA

  -- PASIVAS 

  -- INSERCION DE CAPITAL

  INSERT INTO  ca_cargamigra

  -- PRECARGA SALDO CAPITAL MONEDA PESOS
  SELECT opm_oficina,opm_clase,op_gar_admisible,'CAPP','P',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_capital_pac-amm_capital_pag),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         cob_cartera..ca_operacion
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_migrada    = op_migrada
  AND    amm_estado     <> 3
  AND    substring(opm_toperacion,10,1) = '2'
  GROUP  BY opm_oficina,opm_clase, op_gar_admisible,amm_estado

  UNION

  -- PRECARGA SALDO CAPITAL MONEDA UVR
  SELECT opm_oficina,opm_clase,op_gar_admisible,'CAPP','P',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         cob_cartera..ca_operacion                                     
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_migrada    = op_migrada
  AND    ct_fecha       = @i_fecha
  AND    amm_estado     <> 3
  AND    substring(opm_toperacion,10,1) = '2'
  GROUP  BY opm_oficina,opm_clase,op_gar_admisible,amm_estado

  UNION

  -- RECHAZOS SALDO CAPITAL MONEDA PESOS
  SELECT opm_oficina, opm_clase, cu_clase_custodia, 'CAPP','RP',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_capital_pac-amm_capital_pag),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, 
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    amm_estado     <> 3
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '2'
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION 

  -- RECHAZOS SALDO CAPITAL MONEDA UVR
  SELECT opm_oficina, opm_clase,cu_clase_custodia, 'CAPP','RP',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    ct_fecha       = @i_fecha
  AND    opm_migrada    = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '2'
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado


  UNION

  -- CARGA SALDO CAPITAL MONEDA PESOS
  SELECT op_oficina,op_clase,isnull(op_gar_admisible,'N'),'CAPP','C',am_estado,count(distinct(op_banco)),isnull(sum(am_acumulado-am_pagado),0)   
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_estado    <> 3
  AND    am_concepto  = 'CAP'
  AND    di_estado    <> 3
  AND    op_tipo      = 'R'
  AND    op_moneda    != 2
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado

  UNION

  -- CARGA SALDO CAPITAL MONEDA UVR
  SELECT op_oficina,op_clase,isnull(op_gar_admisible,'N'),'CAPP','C',am_estado,count(distinct(op_banco)),isnull(sum((am_acumulado-am_pagado) * ct_valor),0)
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo, cob_conta..cb_cotizacion
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_estado    <> 3
  AND    am_concepto  = 'CAP'
  AND    di_estado    <> 3
  AND    op_tipo      = 'R'
  AND    op_moneda    = 2
  AND    op_moneda    = ct_moneda
  AND    ct_fecha     = @i_fecha
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado

  UNION

  -- RECHAZOS SALDO CAPITAL MONEDA PESOS
  SELECT opm_oficina, opm_clase, cu_clase_custodia, 'CAPP','RC',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_capital_pac-amm_capital_pag),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, 
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    amm_estado     <> 3
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '2'
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION 

  -- RECHAZOS SALDO CAPITAL MONEDA UVR
  SELECT opm_oficina, opm_clase,cu_clase_custodia, 'CAPP','RC',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    ct_fecha       = @i_fecha
  AND    opm_migrada    = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '2'
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado



  -- ACTIVAS

  -- INSERCION DE CAPITAL

  INSERT INTO  ca_cargamigra

  -- PRECARGA SALDO CAPITAL MONEDA PESOS
  SELECT opm_oficina,opm_clase,op_gar_admisible,'CAPA','P',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_capital_pac-amm_capital_pag),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         cob_cartera..ca_operacion
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_migrada    = op_migrada
  AND    amm_estado     <> 3
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase, op_gar_admisible,amm_estado

  UNION

  -- PRECARGA SALDO CAPITAL MONEDA UVR
  SELECT opm_oficina,opm_clase,op_gar_admisible,'CAPA','P',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         cob_cartera..ca_operacion                                     
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_migrada    = op_migrada
  AND    ct_fecha       = @i_fecha
  AND    amm_estado     <> 3
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase,op_gar_admisible,amm_estado

  UNION

  -- RECHAZOS SALDO CAPITAL MONEDA PESOS
  SELECT opm_oficina, opm_clase, cu_clase_custodia, 'CAPA','RP',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_capital_pac-amm_capital_pag),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, 
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    amm_estado     <> 3
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION 

  -- RECHAZOS SALDO CAPITAL MONEDA UVR
  SELECT opm_oficina, opm_clase,cu_clase_custodia, 'CAPA','RP',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    ct_fecha       = @i_fecha
  AND    opm_migrada    = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado


  UNION

  -- CARGA SALDO CAPITAL MONEDA PESOS
  SELECT op_oficina,op_clase,isnull(op_gar_admisible,'N'),'CAPA','C',am_estado,count(distinct(op_banco)),isnull(sum(am_acumulado-am_pagado),0)   
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_estado    <> 3
  AND    am_concepto  = 'CAP'
  AND    di_estado    <> 3
  AND    op_tipo      <> 'R'
  AND    op_moneda    != 2
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado

  UNION

  -- CARGA SALDO CAPITAL MONEDA UVR
  SELECT op_oficina,op_clase,isnull(op_gar_admisible,'N'),'CAPA','C',am_estado,count(distinct(op_banco)),isnull(sum((am_acumulado-am_pagado) * ct_valor),0)
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo, cob_conta..cb_cotizacion
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_estado    <> 3
  AND    am_concepto  = 'CAP'
  AND    di_estado    <> 3
  AND    op_tipo      <> 'R'
  AND    op_moneda    = 2
  AND    op_moneda    = ct_moneda
  AND    ct_fecha     = @i_fecha
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado

  UNION

  -- RECHAZOS SALDO CAPITAL MONEDA PESOS
  SELECT opm_oficina, opm_clase, cu_clase_custodia, 'CAPA','RC',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_capital_pac-amm_capital_pag),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, 
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    amm_estado     <> 3
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION 

  -- RECHAZOS SALDO CAPITAL MONEDA UVR
  SELECT opm_oficina, opm_clase,cu_clase_custodia, 'CAPA','RC',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    ct_fecha       = @i_fecha
  AND    opm_migrada    = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado


  -- INSERCION DE INTERESES 

  -- ACTIVAS

  INSERT INTO  ca_cargamigra

  -- PRECARGA SALDO INTERES MONEDA PESOS
  SELECT opm_oficina, opm_clase, op_gar_admisible,'INTA','P',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         cob_cartera..ca_operacion
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda != 2
  AND    opm_migrada    = op_migrada 
  AND    amm_estado <> 3
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase, op_gar_admisible, amm_estado

  UNION

  -- PRECARGA SALDO INTERES MONEDA UVR
  SELECT opm_oficina,opm_clase,op_gar_admisible,'INTA','P',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         cob_cartera..ca_operacion
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda  = 2
  AND    opm_moneda  = ct_moneda
  AND    amm_estado  <> 3
  AND    ct_fecha    = @i_fecha
  AND    opm_migrada    = op_migrada  
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase, op_gar_admisible,amm_estado

  UNION 

  -- RECHAZOS SALDO INTERESES MONEDA PESOS
  SELECT opm_oficina,opm_clase,cu_clase_custodia,'INTA','RP',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '1'
  AND    opm_moneda    != 2
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION
  -- RECHAZOS SALDO INTERESES MONEDA UVR
  SELECT opm_oficina,opm_clase,cu_clase_custodia,'INTA','RP',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '1'
  AND    opm_moneda     = 2
  AND    amm_estado     <> 3
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    ct_fecha       = @i_fecha
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION

  -- CARGA SALDO INTERESES MONEDA PESOS
  SELECT op_oficina,op_clase, isnull(op_gar_admisible,'N'),'INTA','C',am_estado,count(distinct(op_banco)),isnull(sum(am_acumulado-am_pagado),0) 
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_concepto  in ('INT','INTANT','IMO')
  AND    di_estado    <> 3
  AND    op_tipo      <> 'R'
  AND    op_moneda    != 2
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado

  UNION

  -- CARGA SALDO INTERESES MONEDA UVR 
  SELECT op_oficina, op_clase,isnull(op_gar_admisible,'N'),'INTA','C',am_estado,count(distinct(op_banco)),isnull(sum((am_acumulado-am_pagado) * ct_valor),0)
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo, cob_conta..cb_cotizacion
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_concepto  in ('INT','INTANT','IMO')
  AND    di_estado    <> 3
  AND    op_tipo      <> 'R'
  AND    op_moneda    = 2
  AND    op_moneda    = ct_moneda
  AND    ct_fecha     = @i_fecha
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado

  UNION 

  -- RECHAZOS SALDO INTERESES MONEDA PESOS
  SELECT opm_oficina,opm_clase,cu_clase_custodia,'INTA','RC',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '1'
  AND    opm_moneda    != 2
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION
  -- RECHAZOS SALDO INTERESES MONEDA UVR
  SELECT opm_oficina,opm_clase,cu_clase_custodia,'INTA','RC',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '1'
  AND    opm_moneda     = 2
  AND    amm_estado     <> 3
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    ct_fecha       = @i_fecha
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado




  -- INSERCION DE INTERESES 

  -- PASIVAS

  INSERT INTO  ca_cargamigra

  -- PRECARGA SALDO INTERES MONEDA PESOS
  SELECT opm_oficina, opm_clase, op_gar_admisible,'INTP','P',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         cob_cartera..ca_operacion
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda != 2
  AND    opm_migrada    = op_migrada 
  AND    amm_estado <> 3
  AND    substring(opm_toperacion,10,1) = '2'
  GROUP  BY opm_oficina,opm_clase, op_gar_admisible, amm_estado

  UNION

  -- PRECARGA SALDO INTERES MONEDA UVR
  SELECT opm_oficina,opm_clase,op_gar_admisible,'INTP','P',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         cob_cartera..ca_operacion
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda  = 2
  AND    opm_moneda  = ct_moneda
  AND    amm_estado  <> 3
  AND    ct_fecha    = @i_fecha
  AND    opm_migrada    = op_migrada  
  AND    substring(opm_toperacion,10,1) = '2'
  GROUP  BY opm_oficina,opm_clase, op_gar_admisible,amm_estado

  UNION 

  -- RECHAZOS SALDO INTERESES MONEDA PESOS
  SELECT opm_oficina,opm_clase,cu_clase_custodia,'INTP','RP',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '2'
  AND    opm_moneda    != 2
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION
  -- RECHAZOS SALDO INTERESES MONEDA UVR
  SELECT opm_oficina,opm_clase,cu_clase_custodia,'INTP','RP',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '2'
  AND    opm_moneda     = 2
  AND    amm_estado     <> 3
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    ct_fecha       = @i_fecha
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION

  -- CARGA SALDO INTERESES MONEDA PESOS
  SELECT op_oficina,op_clase, isnull(op_gar_admisible,'N'),'INTP','C',am_estado,count(distinct(op_banco)),isnull(sum(am_acumulado-am_pagado),0) 
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_concepto  in ('INT','INTANT','IMO')
  AND    di_estado    <> 3
  AND    op_tipo      = 'R'
  AND    op_moneda    != 2
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado

  UNION

  -- CARGA SALDO INTERESES MONEDA UVR 
  SELECT op_oficina, op_clase,isnull(op_gar_admisible,'N'),'INTP','C',am_estado,count(distinct(op_banco)),isnull(sum((am_acumulado-am_pagado) * ct_valor),0)
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo, cob_conta..cb_cotizacion
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_concepto  in ('INT','INTANT','IMO')
  AND    di_estado    <> 3
  AND    op_tipo      = 'R'
  AND    op_moneda    = 2
  AND    op_moneda    = ct_moneda
  AND    ct_fecha     = @i_fecha
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado

  UNION 

  -- RECHAZOS SALDO INTERESES MONEDA PESOS
  SELECT opm_oficina,opm_clase,cu_clase_custodia,'INTP','RC',amm_estado,count(distinct(opm_migrada)),isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '2'
  AND    opm_moneda    != 2
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado

  UNION
  -- RECHAZOS SALDO INTERESES MONEDA UVR
  SELECT opm_oficina,opm_clase,cu_clase_custodia,'INTP','RC',amm_estado,count(distinct(opm_migrada)),isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '2'
  AND    opm_moneda     = 2
  AND    amm_estado     <> 3
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    ct_fecha       = @i_fecha
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo
  GROUP  BY opm_oficina,opm_clase, cu_clase_custodia,amm_estado


  -- INSERCION OTROS CARGOS

  INSERT INTO  ca_cargamigra

  -- PRECARGA SALDO OTROS CARGOS MONEDA PESOS

  SELECT opm_oficina, opm_clase, op_gar_admisible,'OTROC','P',amm_estado,count(distinct(opm_migrada)),isnull(sum(o.amm_monto),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_otros_cargos_mig o, mig_cartera..ca_amortizacion_mig a,
         cob_cartera..ca_operacion                                    
  WHERE  opm_migrada     = o.amm_operacion
  AND    opm_moneda      != 2
  AND    opm_migrada     = op_migrada 
  AND    o.amm_operacion = a.amm_operacion
  AND    o.amm_cuota     = a.amm_cuota
  AND    a.amm_estado   in (1,2,9)
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase,op_gar_admisible,amm_estado


  UNION
  -- PRECARGA SALDO OTROS CARGOS MONEDA UVR

  SELECT opm_oficina, opm_clase, op_gar_admisible, 'OTROC','P',amm_estado,count(distinct(opm_migrada)),isnull(sum((o.amm_monto) * ct_valor),0)
  FROM   mig_cartera..ca_operacion_mig,   mig_cartera..ca_otros_cargos_mig o, cob_conta..cb_cotizacion, mig_cartera..ca_amortizacion_mig a,
         cob_cartera..ca_operacion                                     
  WHERE  opm_migrada     = o.amm_operacion
  AND    opm_moneda      = 2
  AND    opm_moneda      = ct_moneda
  AND    opm_migrada     = op_migrada 
  AND    ct_fecha        = @i_fecha
  AND    o.amm_operacion = a.amm_operacion
  AND    o.amm_cuota     = a.amm_cuota
  AND    a.amm_estado    in (1,2,9)
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase,op_gar_admisible,amm_estado 

  UNION

  -- RECHAZOS SALDO OTROS CARGOS MONEDA PESOS

  SELECT opm_oficina, opm_clase, cu_clase_custodia,'OTROC','RP',amm_estado,count(distinct(opm_migrada)),isnull(sum(o.amm_monto),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_otros_cargos_mig o, mig_cartera..ca_amortizacion_mig a,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = o.amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    opm_oficina    = cu_oficina
  AND    opm_estado_mig = 101
  AND    gp_garantia    = cu_codigo_externo
  AND    o.amm_operacion = a.amm_operacion
  AND    o.amm_cuota     = a.amm_cuota
  AND    a.amm_estado    in (1,2,9)
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase,cu_clase_custodia,amm_estado


  UNION

  -- RECHAZOS SALDO OTROS CARGOS MONEDA UVR

  SELECT opm_oficina, opm_clase, cu_clase_custodia,'OTROC','RP',amm_estado,count(distinct(opm_migrada)),isnull((sum(o.amm_monto) * ct_valor),0)
  FROM   mig_cartera..ca_operacion_mig,   mig_cartera..ca_otros_cargos_mig o, cob_conta..cb_cotizacion, mig_cartera..ca_amortizacion_mig a,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = o.amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    ct_fecha       = @i_fecha
  AND    gp_garantia    = cu_codigo_externo
  AND    o.amm_operacion = a.amm_operacion
  AND    o.amm_cuota     = a.amm_cuota
  AND    a.amm_estado    in (1,2,9)
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase,cu_clase_custodia,amm_estado

  UNION 

  -- CARGA SALDO OTROS CARGOS MONEDA PESOS

  SELECT op_oficina,op_clase,isnull(op_gar_admisible,'N'),'OTROC','C',am_estado,count(distinct(op_banco)),isnull(sum(am_acumulado-am_pagado),0) 
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_estado    <> 3
  AND    am_concepto  not in ('CAP','INT','INTANT','IMO')
  AND    di_estado    <> 3
  AND    op_tipo      <> 'R'
  AND    op_moneda    != 2
  AND    am_estado    in (1,2,9)
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado

  UNION

  -- CARGA SALDO OTROS CARGOS MONEDA UVR 
  SELECT op_oficina, op_clase,isnull(op_gar_admisible,'N'),'OTROC','C',am_estado,count(distinct(op_banco)),isnull(sum((am_acumulado-am_pagado) * ct_valor),0)
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, 
         cob_cartera..ca_dividendo, cob_conta..cb_cotizacion
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_estado    <> 3
  AND    am_concepto  not in ('CAP','INT','INTANT','IMO')
  AND    di_estado    <> 3
  AND    op_tipo      <> 'R'
  AND    op_moneda    = 2
  AND    op_moneda    = ct_moneda
  AND    ct_fecha     = @i_fecha
  AND    am_estado    in (1,2,9)
  GROUP  BY op_oficina,op_clase,op_gar_admisible,am_estado


  UNION

  -- RECHAZOS SALDO OTROS CARGOS MONEDA PESOS

  SELECT opm_oficina, opm_clase, cu_clase_custodia,'OTROC','RC',amm_estado,count(distinct(opm_migrada)),isnull(sum(o.amm_monto),0)
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_otros_cargos_mig o, mig_cartera..ca_amortizacion_mig a,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = o.amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    opm_oficina    = cu_oficina
  AND    opm_estado_mig = 101
  AND    gp_garantia    = cu_codigo_externo
  AND    o.amm_operacion = a.amm_operacion
  AND    o.amm_cuota     = a.amm_cuota
  AND    a.amm_estado    in (1,2,9)
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase,cu_clase_custodia,amm_estado

  UNION

  -- RECHAZOS SALDO OTROS CARGOS MONEDA UVR

  SELECT opm_oficina, opm_clase, cu_clase_custodia,'OTROC','RC',amm_estado,count(distinct(opm_migrada)),isnull((sum(o.amm_monto) * ct_valor),0)
  FROM   mig_cartera..ca_operacion_mig,   mig_cartera..ca_otros_cargos_mig o, cob_conta..cb_cotizacion,  mig_cartera..ca_amortizacion_mig a,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = o.amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    ct_fecha       = @i_fecha
  AND    gp_garantia    = cu_codigo_externo
  AND    o.amm_operacion = a.amm_operacion
  AND    o.amm_cuota     = a.amm_cuota
  AND    a.amm_estado    in (1,2,9)
  AND    substring(opm_toperacion,10,1) = '1'
  GROUP  BY opm_oficina,opm_clase,cu_clase_custodia,amm_estado  


  -- VALIDACION PROCESO DE CONSOLIDADOR

  INSERT INTO cr_cargaprovision

  -- PRECARGA PROVISION BANCO

  SELECT 'BANCO',co_oficina, co_clase, co_tgarantia, cp_concepto, 'P', count(distinct(cp_num_banco)),isnull(sum(cp_prov),0)
  FROM   mig_credito..cr_calificacion_provision, mig_credito..cr_calificacion_op
  WHERE  co_num_op_banco  = cp_num_banco
  AND    co_producto   = cp_producto
  AND    co_producto        = 7
  GROUP  BY co_oficina, co_clase, co_tgarantia, cp_concepto

  UNION

  -- PRECARGA PROVISION CAJA AGRARIA
  
  SELECT 'CAJA AGRARIA',co_oficina, co_clase, co_tgarantia, cp_concepto, 'P', count(distinct(cp_num_banco)),isnull(sum(cp_prova),0)
  FROM   mig_credito..cr_calificacion_provision, mig_credito..cr_calificacion_op
  WHERE  co_num_op_banco  = cp_num_banco
  AND    co_producto   = cp_producto
  AND    co_producto        = 7
  GROUP  BY co_oficina, co_clase, co_tgarantia, cp_concepto

  -- PRECARGA TEMPORALIDAD (DIAS DE VENCIMIENTO)

  INSERT INTO cr_cargatemporalidad
  
  SELECT co_oficina,
         co_clase,
         co_tgarantia,
         ct_codigo,
         'P',
         count(distinct(co_operacion)),
         isnull(sum(co_saldo_cap),0), 
         isnull(sum(co_saldo_int),0), 
         isnull(sum(co_saldo_ctasxcob),0)         
  FROM   mig_credito..cr_calificacion_op,cob_credito..cr_param_cont_temp
  WHERE  co_clase           =  ct_clase
  AND    co_mes_vto_ant     >= ct_desde    
  AND    co_mes_vto_ant     <  ct_hasta
  AND    co_producto        = 7
  GROUP  BY  co_oficina, co_clase, co_tgarantia, ct_codigo


  INSERT INTO cr_cargaprovision

  -- CARGA PROVISION BANCO

  SELECT  'BANCO', do_oficina, do_clase_cartera, do_tipo_garantias, cp_concepto, 'C', count(distinct(do_numero_operacion)), isnull(sum(cp_prov),0)
  FROM     cob_credito..cr_calificacion_provision, --(index cr_calificacion_provision_K3), 
           cob_credito..cr_dato_operacion,--(index cr_dato_operacion_Key), 
           cob_credito..cr_calificacion_op --(index cr_calificacion_op_Key)
  WHERE    do_numero_operacion       = cp_operacion
  AND      co_producto               = cp_producto
  AND      co_producto        	     = do_codigo_producto
  AND      do_codigo_producto        = cp_producto
  AND      co_operacion              = cp_operacion
  AND      co_operacion              = do_numero_operacion       
  AND      cp_fecha                  = do_fecha
  AND      do_tipo_reg               = 'M'
  AND      do_estado_contable        <> 4
  AND      do_estado_contable        <> 3
  AND      cp_producto               = 7
  GROUP BY do_oficina, do_clase_cartera, do_tipo_garantias,cp_concepto

  UNION

  -- CARGA PROVISION CAJA AGRARIA

  SELECT  'CAJA AGRARIA', do_oficina, do_clase_cartera, do_tipo_garantias, cp_concepto, 'C', count(distinct(do_numero_operacion)), isnull(sum(cp_prova),0)
  FROM     cob_credito..cr_calificacion_provision, --(index cr_calificacion_provision_K3), 
           cob_credito..cr_dato_operacion,--(index cr_dato_operacion_Key), 
           cob_credito..cr_calificacion_op --(index cr_calificacion_op_Key)
  WHERE    do_numero_operacion       = cp_operacion
  AND      co_producto               = cp_producto
  AND      co_producto        	     = do_codigo_producto
  AND      do_codigo_producto        = cp_producto
  AND      co_operacion              = cp_operacion
  AND      co_operacion              = do_numero_operacion       
  AND      cp_fecha                  = do_fecha
  AND      do_tipo_reg               = 'M'
  AND      do_estado_contable        <> 4
  AND      do_estado_contable        <> 3
  AND      cp_producto               = 7
  GROUP BY do_oficina, do_clase_cartera, do_tipo_garantias,co_calif_final,cp_concepto

  -- CARGA TEMPORALIDAD (DIAS DE VENCIMIENTO)



  INSERT  INTO tmp_calif_op
  SELECT  co_calif_final,
          co_producto,
          co_operacion,
          co_fecha,
          co_mes_vto,
          co_clase
  FROM   cob_credito..cr_calificacion_op
  WHERE  co_producto  >= 1
  AND    co_operacion >= 1

 

  INSERT  INTO tmp_cr_califica_prov
  SELECT  distinct cp_operacion, 
	  cp_producto,
	  cp_concepto, 
	  cp_fecha
  FROM    cob_credito..cr_calificacion_provision
  WHERE   cp_concepto = '1'

  INSERT  INTO tmp_cr_califica_prov
  SELECT  distinct cp_operacion, 
	  cp_producto,
	  cp_concepto, 
	  cp_fecha
  FROM    cob_credito..cr_calificacion_provision
  WHERE   cp_concepto = '2'

  INSERT  INTO tmp_cr_califica_prov
  SELECT  distinct cp_operacion, 
	  cp_producto,
	  '5', 
	  cp_fecha
  FROM    cob_credito..cr_calificacion_provision
  WHERE   cp_concepto >= '3'

   

  INSERT INTO cr_cargatemporalidad

  SELECT do_oficina,
         do_clase_cartera,
	 do_tipo_garantias,
         ct_codigo,
         'C',
         count(distinct(do_numero_operacion)),
         isnull(sum(do_saldo_cap),0),
         isnull(sum(do_saldo_int),0),
         isnull(sum(do_saldo_otros),0)
  FROM   cob_cartera..tmp_cr_califica_prov, 
         cob_credito..cr_dato_operacion, 
         cob_cartera..tmp_calif_op,
         cob_credito..cr_param_cont_temp
  WHERE  do_numero_operacion = tc_operacion
  AND    do_numero_operacion = co_operacion
  AND    co_operacion        = tc_operacion
  AND    co_producto         = tc_producto
  AND    co_producto         = do_codigo_producto
  AND    do_codigo_producto  = tc_producto
  AND    tc_fecha            = do_fecha
  AND    co_fecha            = tc_fecha
  AND    do_fecha            = co_fecha
  AND    co_mes_vto 	       >= ct_desde    
  AND    co_mes_vto 	       <  ct_hasta    
  AND    co_clase 	       =  ct_clase
  AND    do_clase_cartera    =  ct_clase
  AND    do_clase_cartera    =  co_clase
  AND    do_tipo_reg         = 'M'
  AND    co_producto         = 7
  AND    do_codigo_producto  = 7
  AND    tc_producto         = 7
  AND    do_estado_contable  in (1,2,5)
  GROUP  BY do_oficina, do_clase_cartera, do_tipo_garantias, ct_codigo



/*  -- CONSULTAS

  -- CARGA Y PRECARGA GARANTIAS DETALLADO

  SELECT tipo                 TIPO,
         oficina              OFICINA,
         estado               ESTADO,
         isnull(sum(valor),0) VALOR
  FROM   cu_cargamigra
  WHERE  estado not in ('VI','VO')
  GROUP  BY oficina, estado, tipo


  SELECT oficina,
         clase,
         estado,
         tipo,
         isnull(sum(registros),0),
         isnull(sum(valor),0)
  FROM   cu_cargamigra
  WHERE  estado in ('VI','VO')
  GROUP  BY oficina, clase, estado, tipo



  -- ACTIVAS

  -- CAPITAL Y OTROSC

  SELECT oficina,tipo,concepto,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto in ('CAPA','OTROC')
  GROUP  BY oficina,tipo,concepto


  -- CAPITAL Y OTROSC CASTIGADOS

  SELECT oficina,tipo,concepto,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto in ('CAPA','OTROC')
  AND    estado   = 4
  GROUP  BY oficina,tipo,concepto

  -- INTERESES CAUSADOS

  SELECT oficina,tipo,concepto,estado,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto = 'INTA'
  AND    estado in (1,2)
  GROUP  BY oficina,tipo,concepto,estado

  -- INTERESES SUSPENSO

  SELECT oficina,tipo,concepto,estado,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto = 'INTA'
  AND    estado = 9
  GROUP  BY oficina,tipo,concepto,estado

  -- INTERESES CASTIGADOS

  SELECT oficina,tipo,concepto,estado,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto = 'INTA'
  AND    estado = 4
  GROUP  BY oficina,tipo,concepto,estado  


  -- PASIVAS

  -- ACTIVAS

  -- CAPITAL

  SELECT oficina,tipo,concepto,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto = ('CAPP')
  GROUP  BY oficina,tipo,concepto

  -- CAPITAL CASTIGADOS

  SELECT oficina,tipo,concepto,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto = ('CAPP')
  AND    estado   = 4
  GROUP  BY oficina,tipo,concepto

  -- INTERESES CAUSADOS

  SELECT oficina,tipo,concepto,estado,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto = 'INTP'
  AND    estado in (1,2)
  GROUP  BY oficina,tipo,concepto,estado

  -- INTERESES SUSPENSO

  SELECT oficina,tipo,concepto,estado,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto = 'INTP'
  AND    estado = 9
  GROUP  BY oficina,tipo,concepto,estado

  -- INTERESES CASTIGADOS

  SELECT oficina,tipo,concepto,estado,isnull(sum(registros),0),isnull(sum(valor),0) SALDO
  FROM   ca_cargamigra
  WHERE  concepto = 'INTP'
  AND    estado = 4
  GROUP  BY oficina,tipo,concepto,estado


  -- CONSOLIDADOR

  -- PROVISION CLASE CARTERA Y CLASE GARANTIA

  SELECT tipoempr, tipo, oficina, clase, tipogar, concepto, isnull(sum(registros),0), isnull(sum(valor),0)
  FROM   cr_cargaprovision
  GROUP  BY tipoempr, tipo, oficina, clase, tipogar, concepto


  -- TEMPORALIDAD CLASE CARTERA, CLASE GARANTIA Y DIAS DE VENCIMIENTO

  SELECT oficina, tipo, clase, tipogar, ct_desde, ct_hasta, isnull(sum(saldocap),0), isnull(sum(saldoint),0), isnull(sum(saldootr),0)
  FROM   cr_cargatemporalidad, cob_credito..cr_param_cont_temp
  WHERE  codedad        =    ct_codigo
  GROUP  BY oficina, tipo, clase, tipogar, ct_desde, ct_hasta  */

  return 0
end
go



