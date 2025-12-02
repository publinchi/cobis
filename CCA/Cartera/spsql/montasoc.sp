/************************************************************************/
/*	Archivo:		montasoc.sp				*/
/*	Stored procedure:	sp_monto_asociado		        */
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		MPO					*/
/*	Fecha de escritura:	Diciembre / 1997			*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Procedimiento que permite consultar el monto de pago de una     */
/*	cuota, ya sea en valor presente, anticipado o proyectado	*/
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_monto_asociado')
   drop proc sp_monto_asociado
go

create proc sp_monto_asociado
@i_rubro          catalogo,
@i_monto          money,
@i_operacionca 	  int,
@i_fecha_proceso  datetime,
@i_num_dec	  smallint,
@o_monto_asoc	  money = null out,
@o_rubro_asoc     catalogo = null out,
@o_porcentaje	  float = null out
as
declare
@w_sp_name descripcion,
@w_return int,
@w_tipo_rubro char(1),
@w_valor money,
@w_factor float,
@w_signo char(1),
@w_referencial char(10),
@w_op_sector char(1),
@w_porcentaje float,
@w_tipo_val char(10),
@w_clase char(1),
@w_secuencial int,
@w_vr_valor float,
@w_fecha    datetime 

/** INICIALIZACION DE VARIABLES **/
select @w_sp_name = 'sp_monto_asociado'

/** INFORMACION DE OPERACION **/
select @w_op_sector = op_sector
from ca_operacion
where op_operacion = @i_operacionca

if @@rowcount = 0
   return 718899

/** INFORMACION RUBRO ASOCIADO **/
select @w_tipo_rubro = ro_tipo_rubro,
@w_porcentaje = ro_porcentaje,
@w_factor = ro_factor,
@w_signo = ro_signo,
@w_referencial = ro_referencial
from ca_rubro_op
where ro_operacion = @i_operacionca
and ro_concepto = @i_rubro

if @@rowcount = 0
   return 709987

/** INFORMACION DEL VALOR REFERENCIAL **/
select @w_tipo_val = vd_referencia,
@w_clase = va_clase
from ca_valor,ca_valor_det
where va_tipo = @w_referencial
and vd_tipo = @w_referencial
and vd_sector = @w_op_sector 

if @@rowcount = 0
   return 708909

/** DETERMINACION DE LA MAXIMA FECHA PARA LA TASA ENCONTRADA **/
select @w_fecha = max(vr_fecha_vig)
from ca_valor_referencial
where vr_tipo    = @w_tipo_val
and vr_fecha_vig <= @i_fecha_proceso


select @w_secuencial = max(vr_secuencial)
from ca_valor_referencial
where vr_tipo    = @w_tipo_val
and vr_fecha_vig = @w_fecha



/** DETERMINACION DEL VALOR DE TASA A APLICAR **/
select @w_vr_valor = vr_valor
from ca_valor_referencial
where vr_tipo    = @w_tipo_val
and vr_secuencial = @w_secuencial     


/** CALCULO DEL VALOR DEL RUBRO ASOCIADO **/
if @w_tipo_rubro = 'O' begin -- Tipo Porcentaje
   /** SELECCION DEL PORCENTAJE CORRESPONDIENTE **/
   if @w_clase = 'V' begin /* TIPO VALOR */
      select  @w_porcentaje = @w_porcentaje 
   end
   else begin /* TIPO FACTOR */
      if @w_signo = '+'
         select  @w_porcentaje =  @w_vr_valor + @w_factor
      if @w_signo = '-'
         select  @w_porcentaje =  @w_vr_valor - @w_factor
      if @w_signo = '/'
         select  @w_porcentaje =  @w_vr_valor / @w_factor
      if @w_signo = '*'
         select  @w_porcentaje =  @w_vr_valor * @w_factor
   end                             
   
   select @o_monto_asoc =round((@i_monto*@w_porcentaje/100),@i_num_dec)
   select @o_rubro_asoc = @i_rubro
   select @o_porcentaje = @w_porcentaje
end

return 0
go
