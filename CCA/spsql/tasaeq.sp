/************************************************************************/
/*	Archivo: 		tasaeq.sp		 		*/
/*	Stored procedure: 	sp_calcula_tasa_eq    			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Diego Aguilar 				*/
/*	Fecha de escritura: 	Mayo /99				*/
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
/*	Procedimiento interno para recalcular el ro_porcentaje de los   */
/*      rubros tipo interes con la tasa equivalente en modalidad y pe-  */
/*      riodicidad actual de la operacion                               */
/************************************************************************/  
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_calcula_tasa_eq')
	drop proc sp_calcula_tasa_eq
go
create proc sp_calcula_tasa_eq(
	@i_operacionca       int      = null,
        @i_dividendo         int      = null,
	@i_num_dias          int      = null,
        @i_concepto          catalogo = null,
        @o_tasa_o            float    out,
        @o_tasa_efa          float    out

)
as
declare	
   @w_sp_name        descripcion,
   @w_return 	     int,
   @w_tasa_int       float,
   @w_num_periodo_d  smallint,
   @w_periodo_d      varchar(10),
   @w_forma_pago     char(1),
   @w_valor_aplicar  catalogo,
   @w_concepto       catalogo,
   @w_sector         catalogo,
   @w_modalidad_o    char(1),
   @w_modalidad_efa  char(1),
   @w_periodicidad_o char(1),
   @w_periodicidad_efa char(1),
   @w_modalidad_d    char(1),
   @w_rot_tipo_puntos char(1),
   @w_tipopuntos      char(1),
   @w_tipopuntos_o    char(1),
   @w_tipotasa_o     char(1),
   @w_signo          char(1),
   @w_factor         float,
   @w_tasa_d         float,
   @w_tasa_aux       float,
   @w_tasa_efa       float,
   @w_tipo_amortizacion varchar(10),
   @w_dias_anio      smallint,
   @w_base_calculo   char(1),
   @w_monto_operacion money,
   @w_seguro         catalogo,
   @w_tasa_svda      float,
   @w_valor          money,
   @w_tasa_tot_int   float,
   @w_tasa_seguro    float,
   @w_moneda         tinyint,
   @w_update         tinyint,
   @w_uso_ibc        char(1),
   @w_num_dec        tinyint,
   @w_secuencial_reaj int,
   @w_fecha_ini       datetime,
   @w_fecha_fin       datetime,
   @w_num_dec_tapl    tinyint,
   @w_div_vig         int,
   @w_rot_signo       char(1),
   @w_rot_factor      float

/*  Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_calcula_tasa_eq'




/* PERIODICIDAD ANUAL*/
select @w_periodicidad_efa = pa_char
from    cobis..cl_parametro
where   pa_nemonico = 'PAN' --PERIODICIDAD ANUAL
and     pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_modalidad_efa = 'V' --VENCIDA
 
select
@w_num_periodo_d     = op_periodo_int,
@w_periodo_d         = op_tdividendo,
@w_sector            = op_sector,
@w_tipo_amortizacion = op_tipo_amortizacion,
@w_dias_anio         = op_dias_anio,
@w_base_calculo      = op_base_calculo,
@w_monto_operacion   = op_monto,
@w_moneda            = op_moneda
from ca_operacion
where op_operacion   = @i_operacionca

/*DECIMALES*/
exec @w_return = sp_decimales
@i_moneda      = @w_moneda,
@o_decimales   = @w_num_dec out

select  @w_tasa_int = ro_porcentaje_aux, 
        @w_forma_pago = ro_fpago,
        @w_valor_aplicar = ro_referencial,
        @w_concepto = ro_concepto ,
        @w_rot_tipo_puntos = ro_tipo_puntos,
	@w_num_dec_tapl = ro_num_dec,
        @w_rot_signo    = ro_signo,
        @w_rot_factor   = ro_factor
from  ca_rubro_op 
where ro_operacion  = @i_operacionca
and   ro_concepto   = @i_concepto
and   ro_fpago     in ('P','A')
and   ro_tipo_rubro = 'I'
and   ro_referencial is not null  --SOLO SI TIENE UN VALOR A APLICAR

if @@rowcount = 0
   return 701178 

   select @w_tasa_d = null

/*ORIGEN*/
select 
@w_modalidad_o         = tv_modalidad,
@w_periodicidad_o      = tv_periodicidad ,
@w_tipotasa_o          = tv_tipo_tasa,
@w_tipopuntos          = vd_tipo_puntos,
@w_signo               = vd_signo_default,
@w_factor              = vd_valor_default
from ca_valor_det,ca_tasa_valor
where vd_tipo       = @w_valor_aplicar
and   vd_sector     = @w_sector
and   vd_referencia = tv_nombre_tasa

if @@rowcount = 0 or @w_tipotasa_o = 'E' 
begin
   /* PERIODICIDAD ANUAL*/
   select
   @w_periodicidad_o = @w_periodicidad_efa, 
   @w_modalidad_o    = @w_modalidad_efa
end 


if @w_rot_tipo_puntos is not null
   select @w_tipopuntos = @w_rot_tipo_puntos

if @w_rot_signo is not null
   select @w_signo = @w_rot_signo

if @w_rot_factor is not null
   select @w_factor = @w_rot_factor

/*MODALIDAD ACTUAL DE LA OPERACION ro_porcentaje*/ 
if @w_forma_pago = 'P' 
   select @w_modalidad_d = 'V' --VENCIDO
else if @w_forma_pago = 'A' 
   select @w_modalidad_d = 'A' --ANTICIPADO


if @w_tipotasa_o <> 'N' 
begin
   exec @w_return =  sp_conversion_tasas_int
   @i_dias_anio      = @w_dias_anio,
   @i_periodo_o      = @w_periodicidad_o,
   @i_num_periodo_o  = 1, /* LA TASA ACTUAL ESTA YA INCLUIDA EL NUMERO*/
                          /* DE PERIODICIDAD*/    
   @i_modalidad_o    = @w_modalidad_o,
   @i_tasa_o         = @w_tasa_int,
   @i_periodo_d      = @w_periodo_d,
   @i_num_periodo_d  = @w_num_periodo_d,
   @i_modalidad_d    = @w_modalidad_d,
   @i_dias_periodo_d = @i_num_dias,
   @i_num_dec        = @w_num_dec_tapl,
   @o_tasa_d         = @w_tasa_d output

   if @w_return != 0 return @w_return

   /*VALOR EN EFECTIVO ANUAL DEL RUBRO ro_porcentaje_efa*/
   exec @w_return =  sp_conversion_tasas_int
   @i_dias_anio      = @w_dias_anio,
   @i_base_calculo   = @w_base_calculo,
   @i_periodo_o      = @w_periodicidad_o, 
   @i_num_periodo_o  = 1, 
   @i_modalidad_o    = @w_modalidad_o, 
   @i_tasa_o         = @w_tasa_int,
   @i_periodo_d      = 'A',
   @i_num_periodo_d  = 1, 
   @i_modalidad_d    = 'V',
   @i_num_dec        = @w_num_dec_tapl,
   @o_tasa_d         = @w_tasa_efa output

   if @w_return != 0 return @w_return

end  /*fin TASA != 'N'*/


if @w_tipopuntos = 'N'
begin
       if @w_tipotasa_o = 'E'
       begin
           if @w_signo = '+'
              select @w_tasa_d = @w_tasa_d + @w_factor
              if @w_signo = '-'
                 select @w_tasa_d = @w_tasa_d - @w_factor
                 if @w_signo = '*'
                    select @w_tasa_d = @w_tasa_d * @w_factor
                    if @w_signo = '/'
                       select @w_tasa_d = @w_tasa_d / @w_factor
       end
       else
       begin
          if @w_tipotasa_o = 'N'
          begin
            if @w_signo = '+'
              select @w_tasa_d = @w_tasa_d + @w_factor
              if @w_signo = '-'
                 select @w_tasa_d = @w_tasa_d - @w_factor
                 if @w_signo = '*'
                    select @w_tasa_d = @w_tasa_d * @w_factor
                    if @w_signo = '/'
                       select @w_tasa_d = @w_tasa_d / @w_factor
          end
       end
end
else
if @w_tipopuntos = 'E'
begin
          if @w_tipotasa_o = 'N'
          begin
            if @w_signo = '+'
              select @w_tasa_aux = @w_tasa_efa + @w_factor
              if @w_signo = '-'
                 select @w_tasa_aux = @w_tasa_efa - @w_factor
                 if @w_signo = '*'
                    select @w_tasa_aux = @w_tasa_efa * @w_factor
                    if @w_signo = '/'
                       select @w_tasa_aux = @w_tasa_efa / @w_factor
             
              exec @w_return =  sp_conversion_tasas_int
                  @i_dias_anio      = @w_dias_anio,
                  @i_base_calculo   = @w_base_calculo,
                  @i_periodo_o      = 'A',
                  @i_num_periodo_o  = 1, 
                  @i_modalidad_o    = 'V',
                  @i_tasa_o         = @w_tasa_aux,
                  @i_periodo_d      = @w_periodo_d,
                  @i_num_periodo_d  = @w_num_periodo_d,
                  @i_modalidad_d    = @w_modalidad_d,
                  @i_dias_periodo_d = @i_num_dias,
                  @i_num_dec        = @w_num_dec_tapl,
                  @o_tasa_d         = @w_tasa_d output

              if @w_return != 0 return @w_return
             


	      select @w_tasa_efa = @w_tasa_aux	

          end
end



if @w_tasa_d is not null and @w_tasa_d != 0 
begin
   select @w_div_vig = di_dividendo 
     from ca_dividendo
    where di_operacion = @i_operacionca
      and di_estado = 1

   if @@rowcount = 0
      select @w_div_vig = 1

   if @i_dividendo = @w_div_vig 
   begin
    update ca_rubro_op 
       set ro_porcentaje = isnull(@w_tasa_d,ro_porcentaje),
           ro_porcentaje_efa = isnull(@w_tasa_efa,ro_porcentaje_efa)
     where ro_operacion = @i_operacionca
       and ro_concepto  = @i_concepto
   end 
  
   select @o_tasa_o = @w_tasa_d,
          @o_tasa_efa = @w_tasa_efa
end

return 0

go
     
