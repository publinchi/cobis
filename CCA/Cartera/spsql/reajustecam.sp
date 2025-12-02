/************************************************************************/
/*   Archivo:                  reajustecam.sp                           */
/*   Stored procedure:         sp_reajuste_campana                      */
/*   Base de datos:            cob_cartera                              */
/*   Producto:                 Cartera                                  */
/*   Disenado por:             J Rocha                                  */
/*   Fecha de escritura:       Ene. 2012                                */
/************************************************************************/
/*                                IMPORTANTE                            */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                 PROPOSITO                            */
/*                                                                      */ 
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reajuste_campana')
   drop proc sp_reajuste_campana
go
---TIKET 167070 Mayo 2015

create proc sp_reajuste_campana
   @s_user           login,           
   @s_date           datetime,
   @s_ofi            smallint,
   @s_term           varchar(30),
   @i_operacionca    int,
   @i_fecha_proceso  datetime
as
declare 
   @w_return               int,
   @w_tramite              int,
   @w_fecha_ven            datetime,
   @w_campana              int,
   @w_dias_mora            int,      
   @w_dias_ven             int,
   @w_secuencial           int,
   @w_concepto             char(10),
   @w_refencial            char(10),
   @w_signo                char(1),
   @w_factor               float,
   @w_est_vencido          int,
   @w_error                int,
   @w_porcentaje_efa       float,
   @w_referencial          varchar(50),
   @w_referencia           varchar(50),
   @w_sector               char(1),
   @w_secuen_ref           int,
   @w_fecha_ref            datetime,
   @w_porcentaje_ref       float,
   @w_op_reajuste_especial    char(1),
   @w_estado_op            smallint


-- OBTIENE EL TRAMITE PARA LA OPERCION QUE RECIBE COMO PARAMETRO
select   @w_tramite              =  op_tramite ,
         @w_op_reajuste_especial = op_reajuste_especial,
         @w_estado_op            = op_estado
from     cob_cartera..ca_operacion 
where    op_operacion =  @i_operacionca

if @w_estado_op = 4
begin
   PRINT 'reajustecam.sp Atencion Operacion tiene estado CASTIGADO no se aplica cambio de tasa'
   return 0
end   

-- CON EL TRAMITE DETERMINAR SI HAY ALGUNA CAMPAÑA ASOCIADA
select   @w_campana  =  tr_campana 
from     cob_credito..cr_tramite 
where    tr_tramite  =  @w_tramite

if @w_campana is null return 0


-- CON LA CAMPAÑA OBTIENE LOS DIAS DE VIGENCIA
select @w_dias_mora=ca_altura_mora 
from cob_credito..cr_campana where ca_codigo= @w_campana

if @w_dias_mora is null return 0
   
-- ESTADO VENCIDO DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_vencido    = @w_est_vencido   out


-- CALCULA EL NUMERO DE DIAS TRANSCURRIDOS DESEDE LA CUOTA MAS VIEJA SIN PAGAR A HOY
select  @w_fecha_ven  =  min(di_fecha_ven)
from    cob_cartera..ca_dividendo
where   di_operacion  =  @i_operacionca 
and     di_estado     =  @w_est_vencido

if @w_fecha_ven is null return 0

select @w_dias_ven=datediff(day,@w_fecha_ven,@i_fecha_proceso)

if @w_dias_ven<=@w_dias_mora return 0

/*A CONTINUACIÒN SE BUSCA LA TASA EFECTIVA ANUAL DE LA OPERACION */
select @w_porcentaje_efa = ro_porcentaje_efa from ca_rubro_op 
where ro_operacion = @i_operacionca and ro_tipo_rubro = 'I'

/*A CONTINUACIÒN SE BUSCA LA REFERENCIAL ACTUAL Y SE GUARDA EN @w_porcentaje_ref*/
select @w_sector = op_sector from ca_operacion where  op_operacion = @i_operacionca  --clase de cartera


select @w_referencial = ro_referencial     
from cob_cartera..ca_rubro_op
where ro_operacion = @i_operacionca 
and ro_tipo_rubro = 'I'


/*XMA -- INC 246138   TASA INTERES = 0 */
if @w_referencial = 'TCERO' begin
   select @w_referencial = ro_referencial_reajuste     
   from cob_cartera..ca_rubro_op
   where ro_operacion = @i_operacionca 
   and ro_tipo_rubro = 'I'
end

/*FIN*/



select @w_referencia = vd_referencia --trae el verdadero nombre de la tasa referencial
from cob_cartera..ca_valor,
cob_cartera..ca_valor_det
where va_tipo = vd_tipo
and va_tipo = @w_referencial
and vd_sector = @w_sector

select  @w_secuen_ref  = max(vr_secuencial), @w_fecha_ref = max(vr_fecha_vig)  
from cob_cartera..ca_valor_referencial
where vr_tipo = @w_referencia

select  @w_porcentaje_ref = vr_valor
from cob_cartera..ca_valor_referencial
where vr_tipo = @w_referencia
and   vr_secuencial = @w_secuen_ref 
and   vr_fecha_vig = @w_fecha_ref

/*EVALUA SI ES NECESARIO HACER EL REAJUSTE*/
if abs(@w_porcentaje_ref - @w_porcentaje_efa) > 0.0001 begin

   
   exec @w_secuencial  = sp_gen_sec
   @i_operacion = @i_operacionca
   
   select @w_concepto =pa_char
   from  cobis..cl_parametro
   where pa_producto='CCA' and pa_nemonico='INT'
   
   select  @w_refencial  =  ro_referencial, 
           @w_signo      =  ro_signo_reajuste,  
           @w_factor     =  ro_factor_reajuste
   from cob_cartera..ca_rubro_op 
   where   ro_operacion  =  @i_operacionca 
   and     ro_concepto   =  @w_concepto

   
   insert into cob_cartera..ca_reajuste(
   re_secuencial,        re_operacion,   re_fecha, 
   re_reajuste_especial, re_desagio,     re_sec_aviso)
   values( 
   @w_secuencial,@i_operacionca, @i_fecha_proceso, 
   @w_op_reajuste_especial,   'E',   null)
   
   	
   if @@error <> 0 return 708154 --Error en insercion 
   
   insert into cob_cartera..ca_reajuste_det(
   red_secuencial,    red_operacion,   red_concepto,
   red_referencial,   red_signo,       red_factor,
   red_porcentaje)
   values(
   @w_secuencial,     @i_operacionca,  @w_concepto,
   @w_refencial,      @w_signo,        @w_factor,
   null)
   	
   if @@error <> 0 return 708154 --Error en insercion 
end	

return 0

go

