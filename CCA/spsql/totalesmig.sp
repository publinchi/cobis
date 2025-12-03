/************************************************************************/
/*   Archivo:              saldosmig.sp                                 */
/*   Stored procedure:     sp_totales_mig                                */
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

if exists(SELECT 1 FROM sysobjects WHERE name = 'sp_totales_mig')
   drop proc sp_totales_mig
go

create proc sp_totales_mig
@i_fecha      datetime
as
declare
   @w_error          int
begin


  -- TOTALES --

  -- GARANTIAS

  -- PRECARGA GARANTIAS NUMERO DE REGISTROS Y VALOR TOTAL

  -- PRECARGA GARANTIAS FUTUROS CREDITOS

  SELECT 'P'                          TIPO,
         cu_estado                    ESTADO,
         count(1)                     NUMREG,
         isnull(sum(cu_disponible),0) VALOR
  FROM   mig_garantias..cu_custodia
  WHERE  cu_estado    =  'F'
  GROUP  BY cu_estado
  

  UNION

  -- PRECARGA VIGENTES CON OBLIGACION IDONEAS

  SELECT 'P'                                               TIPO,
         substring(cu_estado,1,1)+ltrim(cu_clase_custodia) ESTADO, 
         count(1)                                          NUMREG,
         isnull(sum(gp_valor_resp_garant),0)               VALOR
  FROM   mig_garantias..cu_custodia,
         mig_garantias..cr_gar_propuesta
  WHERE  cu_estado         = 'V'
  AND    cu_clase_custodia = 'I'
  AND    gp_garantia       = cu_codigo_externo
  GROUP  BY substring(cu_estado,1,1)+ltrim(cu_clase_custodia)

  UNION

  -- PRECARGA VIGENTES CON OBLIGACION NO IDONEAS

  SELECT 'P'                                                TIPO,
         substring(cu_estado,1,1)+ltrim(cu_clase_custodia)  ESTADO,
         count(1)                                           NUMREG,
         isnull(sum(cu_valor_inicial),0)                    VALOR
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
  GROUP  BY  substring(cu_estado,1,1)+ltrim(cu_clase_custodia)

  UNION

  -- PRECARGA VIGENTES POR CANCELAR  (PENDIENTES)


  SELECT 'P'                                TIPO, 
         cu_estado                          ESTADO,
         count(1)                           NUMREG,
         isnull(sum(cu_valor_inicial),0)    VALOR
  FROM   mig_garantias..cu_custodia
  WHERE  cu_estado = 'X'
  GROUP  BY cu_estado

  UNION

  -- CARGA INSERCION VALOR FUTUROS CREDITOS  

  SELECT 'C'                                TIPO,
         cu_estado                          ESTADO,        
         count(1)                           NUMREG,
         isnull(sum(cu_acum_ajuste) ,0)     VALOR
  FROM   cob_custodia..cu_custodia
  WHERE  cu_estado =  'F'
  GROUP  BY  cu_estado

  UNION

  -- CARGA VIGENTES CON OBLIGACION IDONEAS

  SELECT 'C'                                               TIPO,         
         substring(cu_estado,1,1)+ltrim(cu_clase_custodia) ESTADO,
         count(1)                                          NUMREG,
         isnull(sum(dg_valor_resp_garantia)  ,0)           VALOR
  FROM   cob_custodia..cu_custodia,
         cob_custodia..cu_distr_garantia
  WHERE  cu_estado         = 'V'
  AND    cu_clase_custodia = 'I'
  AND    dg_garantia       = cu_codigo_externo
  GROUP  BY  substring(cu_estado,1,1)+ltrim(cu_clase_custodia)

  UNION

  -- CARGA VIGENTES CON OBLIGACION NO IDONEAS

  SELECT 'C'                                                TIPO,
         substring(cu_estado,1,1)+ltrim(cu_clase_custodia)  ESTADO,
         count(1)                                           NUMREG,
         isnull(sum(cu_valor_inicial)  ,0)                  VALOR
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
  GROUP  BY substring(cu_estado,1,1)+ltrim(cu_clase_custodia)


  UNION 


  -- CARGA VIGENTES POR CANCELAR  (PENDIENTES)

  SELECT 'C'                                    TIPO,
         cu_estado                              ESTADO,
         count(1)                               NUMREG,
         isnull(sum(cu_valor_inicial) ,0)       VALOR
  FROM   cob_custodia..cu_custodia
  WHERE  cu_estado = 'X'
  GROUP  BY cu_estado



  -- CARTERA   

  -- PASIVAS

  -- CAPITAL

  -- NUMERO DE REGISTROS Y VALOR TOTAL

  -- PRECARGA SALDO CAPITAL MONEDA PESOS
  SELECT 'P'                                             TIPO,
         'CAPP'                                          CONCEPTO,
          count(1)                                       NUMREG,
          isnull(sum(amm_capital_pac-amm_capital_pag),0) VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         cob_cartera..ca_operacion
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_migrada    = op_migrada
  AND    amm_estado     <> 3
  AND    substring(opm_toperacion,10,1) = '2'

  UNION

  -- PRECARGA SALDO CAPITAL MONEDA UVR
  SELECT 'P'                                                          TIPO,
         'CAPP'                                                       CONCEPTO,
          count(1)                                                    NUMREG,
          isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0) VALOR 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         cob_cartera..ca_operacion                                     
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_migrada    = op_migrada
  AND    ct_fecha       = @i_fecha
  AND    amm_estado     <> 3
  AND    substring(opm_toperacion,10,1) = '2'


  UNION

  -- RECHAZOS SALDO CAPITAL MONEDA PESOS
  SELECT 'RP'                                             TIPO ,
         'CAPP'                                           CONCEPTO,
          count(1)                                        NUMREG,
          isnull(sum(amm_capital_pac-amm_capital_pag),0)  VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, 
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    amm_estado     <> 3
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '2'

  UNION 

  -- RECHAZOS SALDO CAPITAL MONEDA UVR
  SELECT 'RP'                                                        TIPO,
         'CAPP'                                                      CONCEPTO,
         count(1)                                                    NUMREG,
         isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0) VALOR
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


  UNION

  -- CARGA SALDO CAPITAL MONEDA PESOS
  SELECT 'C'                                   TIPO, 
         'CAPP'                                CONCEPTO,
         count(1)                              NUMREG,
         isnull(sum(am_acumulado-am_pagado),0) VALOR
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_estado    <> 3
  AND    am_concepto  = 'CAP'
  AND    di_estado    <> 3
  AND    op_tipo      = 'R'
  AND    op_moneda    != 2

  UNION

  -- CARGA SALDO CAPITAL MONEDA UVR
  SELECT 'C'                                                TIPO,
         'CAPP'                                             CONCEPTO,
         count(1)                                           NUMREG,
         isnull(sum((am_acumulado-am_pagado) * ct_valor),0) VALOR
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


  UNION

  -- RECHAZOS SALDO CAPITAL MONEDA PESOS
  SELECT 'RC'                                            TIPO,
         'CAPP'                                          CONCEPTO,
          count(1)                                       NUMREG,
          isnull(sum(amm_capital_pac-amm_capital_pag),0) VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, 
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    amm_estado     <> 3
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '2'


  UNION 

  -- RECHAZOS SALDO CAPITAL MONEDA UVR
  SELECT 'RC'                                                        TIPO,
        'CAPP'                                                       CONCEPTO,
         count(1)                                                    NUMREG,
         isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0) VALOR
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


  -- ACTIVAS

  -- INSERCION DE CAPITAL


  -- PRECARGA SALDO CAPITAL MONEDA PESOS
  SELECT 'P'                                            TIPO,
         'CAPA'                                         CONCEPTO,
         count(1)                                       NUMREG,
         isnull(sum(amm_capital_pac-amm_capital_pag),0) VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         cob_cartera..ca_operacion
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_migrada    = op_migrada
  AND    amm_estado     <> 3
  AND    substring(opm_toperacion,10,1) = '1'


  UNION

  -- PRECARGA SALDO CAPITAL MONEDA UVR
  SELECT 'P'                                                          TIPO,
         'CAPA'                                                       CONCEPTO,
          count(1)                                                    NUMREG,
          isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0) VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         cob_cartera..ca_operacion                                     
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda     = 2
  AND    opm_moneda     = ct_moneda
  AND    opm_migrada    = op_migrada
  AND    ct_fecha       = @i_fecha
  AND    amm_estado     <> 3
  AND    substring(opm_toperacion,10,1) = '1'


  UNION

  -- RECHAZOS SALDO CAPITAL MONEDA PESOS
  SELECT 'RP'                                            TIPO,
         'CAPA'                                          CONCEPTO,
          count(1)                                       NUMREG,
          isnull(sum(amm_capital_pac-amm_capital_pag),0) VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, 
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    amm_estado     <> 3
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '1'

  UNION 

  -- RECHAZOS SALDO CAPITAL MONEDA UVR
  SELECT 'RP'                                                        TIPO,
         'CAPA'                                                      CONCEPTO,
         count(1)                                                    NUMREG,
         isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0) VALOR
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



  UNION

  -- CARGA SALDO CAPITAL MONEDA PESOS
  SELECT 'C'                                   TIPO,
         'CAPA'                                CONCEPTO,
         count(1)                              NUMREG,
         isnull(sum(am_acumulado-am_pagado),0) VALOR   
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_estado    <> 3
  AND    am_concepto  = 'CAP'
  AND    di_estado    <> 3
  AND    op_tipo      <> 'R'
  AND    op_moneda    != 2


  UNION

  -- CARGA SALDO CAPITAL MONEDA UVR
  SELECT 'C'                                                TIPO,
         'CAPA'                                             CONCEPTO,
         count(1)                                           NUMREG,
         isnull(sum((am_acumulado-am_pagado) * ct_valor),0) VALOR
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


  UNION

  -- RECHAZOS SALDO CAPITAL MONEDA PESOS
  SELECT 'RC'                                            TIPO,
         'CAPA'                                          CONCEPTO,
         count(1)                                        NUMREG,
         isnull(sum(amm_capital_pac-amm_capital_pag),0)  VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, 
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    opm_moneda     != 2
  AND    opm_estado_mig = 101
  AND    opm_migrada    = gp_tramite
  AND    amm_estado     <> 3
  AND    gp_garantia    = cu_codigo_externo
  AND    substring(opm_toperacion,10,1) = '1'


  UNION 

  -- RECHAZOS SALDO CAPITAL MONEDA UVR
  SELECT 'RC'                                                        TIPO,
         'CAPA'                                                      CONCEPTO,
         count(1)                                                    NUMREG,
         isnull(sum((amm_capital_pac-amm_capital_pag) * ct_valor),0) VALOR
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


  -- INSERCION DE INTERESES 

  -- ACTIVAS


  -- PRECARGA SALDO INTERES MONEDA PESOS
  SELECT 'P'                                                                                               TIPO,
         'INTA'                                                                                            CONCEPTO,
         count(1)                                                                                          NUMREG,
         isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0) VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         cob_cartera..ca_operacion
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda != 2
  AND    opm_migrada    = op_migrada 
  AND    amm_estado <> 3
  AND    substring(opm_toperacion,10,1) = '1'


  UNION

  -- PRECARGA SALDO INTERES MONEDA UVR
  SELECT 'P'                                                                                                       TIPO,
         'INTA'                                                                                                    CONCEPTO,
          count(1)                                                                                                 NUMREG,
          isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0)  VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         cob_cartera..ca_operacion
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda  = 2
  AND    opm_moneda  = ct_moneda
  AND    amm_estado  <> 3
  AND    ct_fecha    = @i_fecha
  AND    opm_migrada    = op_migrada  
  AND    substring(opm_toperacion,10,1) = '1'


  UNION 

  -- RECHAZOS SALDO INTERESES MONEDA PESOS
  SELECT 'RP'                                                                                              TIPO,
         'INTA'                                                                                            CONCEPTO,
         count(1)                                                                                          NUMREG,
         isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0) VALOR 
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '1'
  AND    opm_moneda    != 2
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo


  UNION
  -- RECHAZOS SALDO INTERESES MONEDA UVR
  SELECT 'RP'                                                                                                      TIPO,
         'INTA'                                                                                                    CONCEPTO,
          count(1)                                                                                                 NUMREG,
          isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) VALOR
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


  UNION

  -- CARGA SALDO INTERESES MONEDA PESOS
  SELECT 'C'                                    TIPO,
        'INTA'                                  CONCEPTO,
         count(1)                               NUMREG,
         isnull(sum(am_acumulado-am_pagado),0)  VALOR
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_concepto  in ('INT','INTANT','IMO')
  AND    di_estado    <> 3
  AND    op_tipo      <> 'R'
  AND    op_moneda    != 2


  UNION

  -- CARGA SALDO INTERESES MONEDA UVR 
  SELECT 'C'                                                 TIPO,
         'INTA'                                              CONCEPTO,
         count(1)                                            NUMREG, 
         isnull(sum((am_acumulado-am_pagado) * ct_valor),0)  VALOR
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


  UNION 

  -- RECHAZOS SALDO INTERESES MONEDA PESOS
  SELECT 'RC'                                                                                               TIPO,
         'INTA'                                                                                             CONCEPTO,
         count(1)                                                                                           NUMREG,
         isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0)  VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '1'
  AND    opm_moneda    != 2
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo


  UNION
  -- RECHAZOS SALDO INTERESES MONEDA UVR
  SELECT 'RC'                                                                                                     TIPO,
         'INTA'                                                                                                   CONCEPTO,
         count(1)                                                                                                 NUMREG,
         isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) VALOR
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





  -- INSERCION DE INTERESES 

  -- PASIVAS

  -- PRECARGA SALDO INTERES MONEDA PESOS
  SELECT 'P'                                                                                                TIPO,
         'INTP'                                                                                             CONCEPTO,
         count(1)                                                                                           NUMREG,
         isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0)  VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         cob_cartera..ca_operacion
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda != 2
  AND    opm_migrada    = op_migrada 
  AND    amm_estado <> 3
  AND    substring(opm_toperacion,10,1) = '2'


  UNION

  -- PRECARGA SALDO INTERES MONEDA UVR
  SELECT 'P'                                                                                                  TIPO,
         'INTP'                                                                                               CONCEPTO,
         count(1)                                                                                             NUMREG,
         isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0)  VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig, cob_conta..cb_cotizacion,
         cob_cartera..ca_operacion
  WHERE  opm_migrada = amm_operacion
  AND    opm_moneda  = 2
  AND    opm_moneda  = ct_moneda
  AND    amm_estado  <> 3
  AND    ct_fecha    = @i_fecha
  AND    opm_migrada    = op_migrada  
  AND    substring(opm_toperacion,10,1) = '2'

  UNION 

  -- RECHAZOS SALDO INTERESES MONEDA PESOS
  SELECT 'RP'                                                                                               TIPO,
         'INTP'                                                                                             CONCEPTO,
         count(1)                                                                                           NUMREG,
         isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0)  VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '2'
  AND    opm_moneda    != 2
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo


  UNION
  -- RECHAZOS SALDO INTERESES MONEDA UVR
  SELECT 'RP'                                                                                                 TIPO,
         'INTP'                                                                                               CONCEPTO,
         count(1)                                                                                             NUMREG,
         isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) VALOR
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


  UNION

  -- CARGA SALDO INTERESES MONEDA PESOS
  SELECT 'C'                                   TIPO,
         'INTP'                                CONCEPTO,
         count(1)                              NUMREG,
         isnull(sum(am_acumulado-am_pagado),0) VALOR
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_concepto  in ('INT','INTANT','IMO')
  AND    di_estado    <> 3
  AND    op_tipo      = 'R'
  AND    op_moneda    != 2


  UNION

  -- CARGA SALDO INTERESES MONEDA UVR 
  SELECT 'C'                                                TIPO,
         'INTP'                                             CONCEPTO,
         count(1)                                           NUMREG,
         isnull(sum((am_acumulado-am_pagado) * ct_valor),0) VALOR
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


  UNION 

  -- RECHAZOS SALDO INTERESES MONEDA PESOS
  SELECT 'RC'                                                                                              TIPO,
         'INTP'                                                                                            CONCEPTO,
         count(1)                                                                                          NUMREG,
         isnull(sum(amm_int_corr_acu-amm_int_corr_pag),0)+isnull(sum(amm_int_mora_acu-amm_int_mora_pag),0) VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_amortizacion_mig,
         mig_garantias..cr_gar_propuesta, mig_garantias..cu_custodia
  WHERE  opm_migrada    = amm_operacion
  AND    substring(opm_toperacion,10,1) = '2'
  AND    opm_moneda    != 2
  AND    opm_estado_mig = 101
  AND    amm_estado     <> 3
  AND    opm_migrada   = gp_tramite
  AND    gp_garantia    = cu_codigo_externo


  UNION
  -- RECHAZOS SALDO INTERESES MONEDA UVR
  SELECT 'RC'                                                                                                    TIPO,
         'INTP'                                                                                                  CONCEPTO,
         count(1)                                                                                                NUMREG,  
         isnull(sum((amm_int_corr_acu-amm_int_corr_pag) * ct_valor),0)+isnull(sum((amm_int_mora_acu-amm_int_mora_pag) * ct_valor),0) VALOR
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



  -- INSERCION OTROS CARGOS


  -- PRECARGA SALDO OTROS CARGOS MONEDA PESOS

  SELECT 'P'                        TIPO,
         'OTROC'                    CONCEPTO,
         count(1)                   NUMREG,
         isnull(sum(o.amm_monto),0) VALOR
  FROM   mig_cartera..ca_operacion_mig,mig_cartera..ca_otros_cargos_mig o, mig_cartera..ca_amortizacion_mig a,
         cob_cartera..ca_operacion                                    
  WHERE  opm_migrada     = o.amm_operacion
  AND    opm_moneda      != 2
  AND    opm_migrada     = op_migrada 
  AND    o.amm_operacion = a.amm_operacion
  AND    o.amm_cuota     = a.amm_cuota
  AND    a.amm_estado   in (1,2)
  AND    substring(opm_toperacion,10,1) = '1'


  UNION
  -- PRECARGA SALDO OTROS CARGOS MONEDA UVR

  SELECT 'P'                                     TIPO,
         'OTROC'                                 CONCEPTO,
         count(1)                                NUMREG,
         isnull(sum((o.amm_monto) * ct_valor),0) VALOR
  FROM   mig_cartera..ca_operacion_mig,   mig_cartera..ca_otros_cargos_mig o, cob_conta..cb_cotizacion, mig_cartera..ca_amortizacion_mig a,
         cob_cartera..ca_operacion                                     
  WHERE  opm_migrada     = o.amm_operacion
  AND    opm_moneda      = 2
  AND    opm_moneda      = ct_moneda
  AND    opm_migrada     = op_migrada 
  AND    ct_fecha        = @i_fecha
  AND    o.amm_operacion = a.amm_operacion
  AND    o.amm_cuota     = a.amm_cuota
  AND    a.amm_estado    in (1,2)
  AND    substring(opm_toperacion,10,1) = '1'


  UNION

  -- RECHAZOS SALDO OTROS CARGOS MONEDA PESOS

  SELECT 'RP'                       TIPO,
         'OTROC'                    CONCEPTO,
         count(1)                   NUMREG,
         isnull(sum(o.amm_monto),0) VALOR
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
  AND    a.amm_estado    in (1,2)
  AND    substring(opm_toperacion,10,1) = '1'



  UNION

  -- RECHAZOS SALDO OTROS CARGOS MONEDA UVR

  SELECT 'RP'                              TIPO,
         'OTROC'                           CONCEPTO,
          count(1)                         NUMREG,
          isnull((sum(o.amm_monto) * ct_valor),0) VALOR
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
  AND    a.amm_estado    in (1,2)
  AND    substring(opm_toperacion,10,1) = '1'


  UNION 

  -- CARGA SALDO OTROS CARGOS MONEDA PESOS

  SELECT 'C'                                    TIPO,
         'OTROC'                                CONCEPTO,
          count(1)                              NUMREG,
          isnull(sum(am_acumulado-am_pagado),0) VALOR
  FROM   cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
  WHERE  am_operacion = op_operacion
  AND    am_operacion = di_operacion
  AND    am_dividendo = di_dividendo
  AND    am_estado    <> 3
  AND    am_concepto  not in ('CAP','INT','INTANT','IMO')
  AND    di_estado    <> 3
  AND    op_tipo      <> 'R'
  AND    op_moneda    != 2


  UNION

  -- CARGA SALDO OTROS CARGOS MONEDA UVR 
  SELECT 'C'                                                TIPO,
         'OTROC'                                            CONCEPTO,
         count(1)                                           NUMREG,
         isnull(sum((am_acumulado-am_pagado) * ct_valor),0) VALOR
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


  UNION

  -- RECHAZOS SALDO OTROS CARGOS MONEDA PESOS

  SELECT 'RC'                       TIPO,
         'OTROC'                    CONCEPTO,
         count(1)                   NUMREG,
         isnull(sum(o.amm_monto),0) VALOR
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
  AND    a.amm_estado    in (1,2)
  AND    substring(opm_toperacion,10,1) = '1'


  UNION

  -- RECHAZOS SALDO OTROS CARGOS MONEDA UVR

  SELECT 'RC'                                     TIPO,
         'OTROC'                                  CONCEPTO,
         count(1)                                 NUMREG,
         isnull((sum(o.amm_monto) * ct_valor),0)  VALOR
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
  AND    a.amm_estado    in (1,2)
  AND    substring(opm_toperacion,10,1) = '1'

  -- VALIDACION PROCESO DE CONSOLIDADOR


  -- PRECARGA PROVISION BANCO

  SELECT 'P'                     TIPO,
         'BANCO'                 TIPOEMP,
          cp_concepto            CONCEPTO,
          count(1)               NUMREG,
          isnull(sum(cp_prov),0) VALOR
  FROM   mig_credito..cr_calificacion_provision, mig_credito..cr_calificacion_op
  WHERE  co_num_op_banco  = cp_num_banco
  AND    co_producto   = cp_producto
  AND    co_producto   = 7
  GROUP  BY cp_concepto

  UNION

  -- PRECARGA PROVISION CAJA AGRARIA
  
  SELECT 'P'                      TIPO,
         'CAJA AGRARIA'           TIPOEMP,
          cp_concepto             CONCEPTO, 
          count(1)                NUMREG,
          isnull(sum(cp_prova),0) VALOR
  FROM   mig_credito..cr_calificacion_provision, mig_credito..cr_calificacion_op
  WHERE  co_num_op_banco  = cp_num_banco
  AND    co_producto   = cp_producto
  AND    co_producto   = 7
  GROUP  BY cp_concepto


  -- PRECARGA TEMPORALIDAD (DIAS DE VENCIMIENTO)
  
  SELECT 'P'                          TIPO,
         count(1)                     NUMREG,
         isnull(sum(co_saldo_cap),0)  CAPITAL, 
         isnull(sum(co_saldo_int),0)  INTERES, 
         isnull(sum(co_saldo_ctasxcob),0)  OTROS       
  FROM   mig_credito..cr_calificacion_op,cob_credito..cr_param_cont_temp
  WHERE  co_clase           =  ct_clase
  AND    co_mes_vto_ant     >= ct_desde    
  AND    co_mes_vto_ant     <  ct_hasta
  AND    co_producto        = 7
  

  -- CARGA PROVISION BANCO AGRARIO


  SELECT  'C'                      TIPO, 
          'BANCO'                  TIPOEMP, 
           cp_concepto             CONCEPTO, 
           count(1)                NUMREG, 
           isnull(sum(cp_prov),0)  VALOR
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
  GROUP BY cp_concepto

  UNION

  -- CARGA PROVISION CAJA AGRARIA

  SELECT  'C'                       TIPO,
          'CAJA AGRARIA'            TIPOEMP,
           cp_concepto              CONCEPTO, 
           count(1)                 NUMREG,
           isnull(sum(cp_prova),0)  VALOR
  FROM     cob_credito..cr_calificacion_provision, --(index cr_calificacion_provision_K3), 
           cob_credito..cr_dato_operacion, --(index cr_dato_operacion_Key), 
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
  GROUP BY cp_concepto


  -- CARGA TEMPORALIDAD (DIAS DE VENCIMIENTO)


  SELECT 'C',
         count(1),
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




 return 0
end
go