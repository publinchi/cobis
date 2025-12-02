/************************************************************************/
/*  Archivo:            moparucpcj.sp                                   */
/*  Stored procedure:   sp_monto_pago_rubrocpcj                         */
/*  Base de datos:      cob_cartera                                     */     
/*  Producto:           Cartera                                         */
/*  Disenado por:       Ivonne Torres                                   */
/*  Fecha de escritura: 25-Ene-2010                                     */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA', representantes exclusivos para el Ecuador de              */
/*  AT&T GIS  .                                                         */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/              
/*                          PROPOSITO                                   */
/*  Este strored procedure realiza el cálculo del monto para los rubros */
/*  en estado prejuridico y juridico HONOCJ, HONOCP, IVAHOP, IVAHOJ     */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA         AUTOR                       RAZON                     */
/*  25/Ene/2010   Ivonne Torres          Emision Inicial                */
/************************************************************************/
     
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_monto_pago_rubrocpcj')
   drop proc sp_monto_pago_rubrocpcj
go
create proc sp_monto_pago_rubrocpcj(
   @i_operacionca       int,
   @i_monto_pago        float,
   @i_estado_cobranza   char(2),
   @i_dividendo         int,
   @o_monto_honorario   float    out,
   @o_monto_iva         float    out
)
as declare
   @w_sp_name           varchar(25),
   @w_estado_cob        char(2),
   @w_pariva            varchar(6),
   @w_porc_honorario    float,
   @w_porc_iva          float,
   @w_concepto          varchar(8),
   @w_monto_cuotah      float, 
   @w_monto_cuotai      float,
   @w_iva               float,
   @w_coeficiente       float,
   @w_monto_abogado     float,
   @w_di_dividendo      int,
   @w_monto_honorario   float,
   @w_monto_iva         float,
   @w_monto_cartera     float,
   @w_hono_cc           catalogo,
   @w_hono_cp           catalogo,
   @w_hono_cj           catalogo,
   @w_iva_cc            catalogo,
   @w_iva_cp            catalogo,
   @w_iva_cj            catalogo

   

select @w_sp_name = 'sp_monto_pago_rubrocpcj'

   
-- PARAMETROS GENERALES
select @w_hono_cc = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'HONOCC'
if @@rowcount = 0   
   return 710256
   
-- PARAMETROS GENERALES
select @w_hono_cp = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'HONOCP'
if @@rowcount = 0   
   return 710256
   
-- PARAMETROS GENERALES
select @w_hono_cj = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'HONOCJ'
if @@rowcount = 0    
   return 710256

   

   
-- PARAMETROS GENERALES
select @w_iva_cc = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAHOC'
if @@rowcount = 0   
   return 710256
   
-- PARAMETROS GENERALES
select @w_iva_cp = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAHOP'
if @@rowcount = 0  
   return 710256
   
-- PARAMETROS GENERALES
select @w_iva_cj = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAHOJ'
if @@rowcount = 0  
   return 710256
   
   

-- ESTADO PRE-JURIDICO
if @i_estado_cobranza in ('CP','CC')
begin
   select @w_concepto = @w_hono_cp
   select @w_pariva   = @w_iva_cp
end

-- ESTADO JURIDICO
if @i_estado_cobranza = 'CJ'
begin
   select @w_concepto = @w_hono_cj
   select @w_pariva   = @w_iva_cj
end

select @w_monto_cuotah = sum(am_cuota + am_gracia - am_pagado)
from ca_amortizacion
where  am_operacion = @i_operacionca
and    am_dividendo = @i_dividendo
and    am_concepto  = @w_concepto


select @w_monto_cuotai = sum(am_cuota + am_gracia - am_pagado)
from ca_amortizacion
where  am_operacion = @i_operacionca
and    am_dividendo = @i_dividendo
and    am_concepto  = @w_pariva


select @o_monto_honorario = @w_monto_honorario
select @o_monto_iva       = @w_monto_iva

   

return 0
go


