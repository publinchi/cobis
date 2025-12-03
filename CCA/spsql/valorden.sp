/************************************************************************/
/*   Archivo:             valorden.sp                                 */
/*   Stored procedure:    sp_valida_orden                               */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Luis Carlos Moreno                            */
/*   Fecha de escritura:  2014/10                                       */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Realiza validaciones específicas del perfeccionamiento de la       */
/*   Normalizacion                                                      */ 
/************************************************************************/
/*            MODIFICACIONES                                            */
/*    FECHA                 AUTOR                     CAMBIO            */
/*   2014-09-24   Luis Carlos Moreno  Req436:Normalizacion Cartera      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valida_orden')
   drop proc sp_valida_orden
go

create proc sp_valida_orden
   @s_user           login          = null,
   @s_ofi            smallint       = null,
   @s_term           varchar(30)    = null,
   @s_date           datetime       = null,
   @i_tram_norm      int,
   @i_tram_oper      int,
   @i_banco          varchar(24),
   @i_operacion      int,
   @i_tipo_norm      int            = null,
   @i_debug          char           = 'N'
as
declare
   @w_error          int,
   @w_op_operacion   int,
   @w_cod_gar_fng       catalogo,
   @w_cod_gar_usaid     catalogo,
   @w_cod_iva_fng       catalogo,
   @w_parametro_fng     catalogo,
   @w_parametro_usaid   catalogo,
   @w_colateral         catalogo,
   @w_garantia          varchar(10),
   @w_tipo_garantia                varchar(10),
   @w_cto_asociado      catalogo,
   @w_monto_total       money,
   @w_smmlv             money,
   @w_fecha_proceso     datetime,
   @w_tasa_fng          float,
   @w_tasa_fng2         float,
   @w_porc_gar          float,
   @w_monto_gar         money,
   @w_num_smmlv         float,
   @w_cont              tinyint,
   @w_porc_iva_fng      float,
   @w_comision          money,
   @w_iva_comision      money,
   @w_generar           char(1),
   @w_val_cobro         money
   
begin
  
   select @w_generar = 'S'
   
   select @w_val_cobro = 0

   --SE OBTIENE VALOR DE COBRO DE LOS RUBROS NEGOCIADOS
   select @w_val_cobro = isnull(sum(rp_valor_cobro),0)
   from cob_credito..cr_rub_pag_reest
   where rp_tramite = @i_tram_oper
   
   if exists(select 1 from cob_credito..cr_tramite_cajas
             where  tc_tramite    = @i_tram_oper
             and    tc_estado = 'E'
             and    tc_causa  = '039'
             and    tc_pago_cobro = 'C'
             and    tc_valor = @w_val_cobro)
      select @w_generar = 'N'

   -- GENERA VALOR DE RUBROS A PAGAR
   if @w_generar = 'S'
   begin
            
      delete cob_credito..cr_rub_pag_reest
      where rp_tramite = @i_tram_oper
              
      delete cob_cartera..ca_rubro_norm_op
      where ro_operacion = @i_operacion
       
      select concepto=am_concepto, valor=round(sum(am_acumulado - am_pagado) * rn_porcent_cobro / 100.0,0), porc=rn_porcent_cobro
      into #conceptos
      from cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_normalizacion
      where am_operacion = @i_operacion
      and   am_concepto = rn_rubro
      and   rn_tipo_norm = @i_tipo_norm
      and   rn_estado    = 'V'
      group by am_concepto, rn_porcent_cobro
         
      insert into cob_cartera..ca_rubro_norm_op
      select @i_operacion, @i_tram_norm, concepto, valor
      from #conceptos
      
      insert into cob_credito..cr_rub_pag_reest
      select @i_tram_oper, concepto, porc, round(valor,0), 0.0
      from #conceptos

   end
   
   --GENERA ORDEN DE PAGO  
   exec @w_error = cob_credito..sp_trn_cj_reest
        @s_date         = @s_date,
	    @s_user         = @s_user,
	    @i_operacion    = 'I',
	    @i_cca          = 'S', --LLAMO EL PROCESO DESDE CARTERA
	    @i_banco        = @i_banco ,
	    @i_tramite      = @i_tram_oper,
	    @i_es_norm      = 'S' 
	   
   if @w_error <> 0
      return @w_error
   
   return 0
end
go