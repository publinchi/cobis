/******************************************************************************************/
/* revisa_las las operaciones cuya cuota de la anualidad vencio y se perdio el            */  
/* valor del FNG                                                                          */   
/* FECHA VALOR EL BATCH ADELANTARA LA OPERACION                                           */
/******************************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_revi_data_boc_uno')
   drop proc sp_revi_data_boc_uno
go

create proc sp_revi_data_boc_uno 

as

declare
@w_operacion             int,   
@w_banco                 cuenta,
@w_di_dividendo          smallint,
@w_di_fecha_ven          datetime,
@w_fecha_hoy             datetime,
@w_fecha_ult_proceso     datetime,
@w_di_estado             tinyint,
@w_fecha_val             datetime,
@w_retroceder            char(1)

select @w_fecha_hoy = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

PRINT 'carevisa_data_BOC_tmp.sp INCIO PROCESO CARGA DE DATOS AUTOMATICO '
PRINT 'Seleccion de Datos'

select distinct  'oper' = op_operacion
into #operVenceCuota
from cob_cartera..ca_operacion with (nolock),
     cob_cartera..ca_dividendo with (nolock)
where op_operacion = di_operacion
and di_estado in (2,3)
and op_plazo <> di_dividendo
and op_estado  in (1,4,9)
and op_fecha_fin > di_fecha_ven
and di_fecha_ven between '05/01/2011' and '05/26/2011'

select *
into #operaciones_Revisar
from  #operVenceCuota,
      cob_cartera..ca_dividendo with (nolock)
where oper = di_operacion
and di_dividendo in (12,24,36,48)
and di_estado in (2,3)
and di_fecha_ven between '05/01/2011' and '05/26/2011'

select *
into #Operaciones1
from #operaciones_Revisar,
     cob_cartera..ca_operacion o with (nolock)
where oper = o.op_operacion
and  exists ( select 1 
              from cob_custodia..cu_custodia, 
              cob_credito..cr_gar_propuesta, 
              cob_credito..cr_tramite
              where gp_tramite  = o.op_tramite
              and gp_garantia = cu_codigo_externo 
              and cu_estado   in ('P','F','V','X','C')
              and tr_tramite  = gp_tramite
              and cu_tipo in ('2205','2210','2220','2230')
             )

select  op_operacion,op_banco,di_dividendo,di_fecha_ven,di_estado,op_fecha_ult_proceso
into #oper_analizarCuota
from #Operaciones1,ca_amortizacion
where am_operacion = di_operacion
and am_dividendo = di_dividendo
and am_concepto = 'COMFNGANU'
and am_cuota = 0

select * from #oper_analizarCuota


--- CURSOR DE OPERACIONES A ANALIZAR
declare 
   Cur_Icn_dato_uno cursor
   for select  
        op_operacion,
        op_banco,
        di_dividendo,
        di_fecha_ven,
        di_estado,
        op_fecha_ult_proceso
   from #oper_analizarCuota
   where op_operacion not in (850767,887690) ---tiene transaccines MAUALES revisar puntaulmente
   
open Cur_Icn_dato_uno

fetch Cur_Icn_dato_uno
into  @w_operacion,
      @w_banco,
      @w_di_dividendo,
      @w_di_fecha_ven,
      @w_di_estado,
      @w_fecha_ult_proceso

          
while @@fetch_status = 0
begin
        ----CONSULTA ANTES POR SI HAY OPERACIONES QUE YA SE LES CORRIO EL PROCESO
        select  @w_retroceder = 'S'
        if @w_di_dividendo = 12 
        begin
          ---REVISAR QUE NO TENGA LA COMISION EN LA CUOTA 13
	          if exists (select 1 
	                     from ca_amortizacion
	                     where am_operacion = @w_operacion
	                     and   am_dividendo = 13
	                     and   am_concepto = 'COMFNGANU'
	                     and   am_cuota > 0)
              select  @w_retroceder = 'N'

        end
        
        if @w_retroceder = 'S' 
        begin
           ---ANALIZAR SI LA COMISION SE TRASLADO 
           ---A OTRA CUOTA ANTERIOR NO IMPORTA EL ESTADO

           if exists (select 1 
	                     from ca_amortizacion
	                     where am_operacion = @w_operacion
	                     and   am_dividendo between 1 and 11
	                     and   am_concepto = 'COMFNGANU'
	                     and   am_cuota > 0)
              select  @w_retroceder = 'N'
        end        

        if @w_retroceder = 'S' 
        begin     
            select @w_fecha_val = dateadd (dd,-2,@w_di_fecha_ven)
            
		    PRINT 'A PROCESAR ' + CAST(  @w_banco as varchar) + 'FECHA:  ' +  CAST(  @w_fecha_val as varchar) 
	     
	       exec sp_fecha_valor 
			@s_user              = 'sa',        
			@i_fecha_valor       = @w_fecha_val,
			@s_term              = 'Terminal', 
			@s_date              = @w_fecha_hoy,
			@i_banco             = @w_banco,
			@i_operacion         = 'F',
			@i_en_linea          = 'S',
			@i_control_fecha     = 'N',
			@i_debug             = 'N',
			@i_observacion       = 'AUTOMATICO'

		end
		 
     fetch Cur_Icn_dato_uno
           into  @w_operacion,
           @w_banco,
           @w_di_dividendo,
           @w_di_fecha_ven,
           @w_di_estado,
           @w_fecha_ult_proceso
           
end --while @@fetch_status = 0

close Cur_Icn_dato_uno
deallocate Cur_Icn_dato_uno


return 0
go

