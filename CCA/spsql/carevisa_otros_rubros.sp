/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                carevisa_otros_rubros.sp                */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     JUNIO 2011                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      REvisar los otros rubros de la obligacion  para verificar que   */
/*     su valor este causado  en ca_transaccion_prv                     */
/*                                                                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*  FECHA            AUTOR            CAMBIO                            */
/* 01/20/2015         EPB    SE quitar la parte inferior del            */
/*                           programa porque este ajuste ya no es valido*/
/*                           si se presentan diferencias deben ajusterse*/
/*                           donde se originan. este proceso fue        */
/*                           necesario para estabilizar una data que se */
/*                           corrigio anos antes pero a la fecha ya no  */
/*                           aplica                                     */
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_revisa_otros_rubros')
   drop proc sp_revisa_otros_rubros
go

---ACT.ENE.20.2015

create proc sp_revisa_otros_rubros 
@i_operacion               int,
@i_fechaval                char(1) = 'N'


as
declare
@w_div_revisar           smallint,
@w_dividendo            smallint,
@w_concepto             catalogo,
@w_am_acumulado         money,
@w_fecha_ult_proceso    datetime,
@w_op_estado            smallint,
@w_fecha_hoy            datetime,
@w_banco                cuenta,
@w_val_reverso          money,
@w_val_contabilizar     money,
@w_div_fng              smallint,
@w_di_fecha_ini         datetime,
@w_tp_dividendo        smallint,
@w_tp_concepto         catalogo,
@w_tp_monto            money,
@w_am_dividendo        smallint,
@w_am_concepto         catalogo,
@w_tp_estado           catalogo,
@w_codvalor            int,
@w_diferencia           money,
@w_iva_honorario        catalogo,
@w_honabo               catalogo,
@w_se_pag               int



select @w_fecha_ult_proceso  = op_fecha_ult_proceso,
       @w_op_estado           = op_estado
from ca_operacion
where op_operacion = @i_operacion


select @w_fecha_hoy = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

if @i_fechaval    = 'S'
begin

     ---Inc. 26381
	---DESPUES DE RECUPERAR HISTORICOS Y MOVER LA OBLIGACION HASTA DONDE DEBE QUEDAR
	---SE DEBE ANALIZAR SI EL DIFERIDO ESTA CARGADO SINO SE CARGA solo para las operaciones
	---antes de 24 nov  que salio la funcionalidad de padre e hija en Reestructuraciones
	---Exclusivo de Bancamia de las nuevas se confia en el historico almacenado
	
		if exists (select 1 
					from ca_det_trn with (nolock),ca_transaccion with (nolock)
					where tr_operacion = @i_operacion
					and tr_operacion = dtr_operacion 
					and dtr_secuencial = tr_secuencial
					and tr_estado <> 'RV'
					and tr_secuencial >= 0
					and tr_estado  = 'CON'
		         and tr_tran <> 'PAG'			
					and dtr_estado = 8
					and tr_fecha_mov < '11/24/2012'
					)
        begin  
			if not exists (select 1 from ca_diferidos
			               where dif_operacion = @i_operacion)
          begin
				 insert into ca_diferidos 
				 select tr_operacion, dtr_monto_mn,0, dtr_concepto
				 from ca_det_trn with (nolock),ca_transaccion with (nolock)
				 where tr_operacion = @i_operacion
				 and tr_operacion = dtr_operacion 
				 and dtr_secuencial = tr_secuencial
				 and tr_estado <> 'RV'
				 and tr_secuencial >= 0
				 and tr_estado  = 'CON'
				 and tr_tran <> 'PAG'
				 and dtr_estado = 8
				 and tr_fecha_mov < '11/24/2012'
			
				 select tr_operacion, dtr_concepto,'pagado'=sum(dtr_monto_mn)
				 into #pagado
				 from ca_det_trn with (nolock),ca_transaccion with (nolock)
				 where tr_operacion = @i_operacion
				 and tr_operacion = dtr_operacion 
				 and dtr_secuencial = tr_secuencial
				 and tr_estado <> 'RV'
				 and tr_secuencial >= 0
				 and tr_estado  = 'CON'
				 and dtr_estado = 8
				 and tr_tran = 'PAG'
				 and tr_fecha_mov < '11/24/2012'
				 group by tr_operacion,dtr_concepto
				
				 update ca_diferidos
				 set dif_valor_pagado = pagado
				 from #pagado,ca_diferidos
				 where dif_operacion = tr_operacion
				 and   dif_concepto  = dtr_concepto
			end
        end			
	RETURN 0
end
return 0
go

