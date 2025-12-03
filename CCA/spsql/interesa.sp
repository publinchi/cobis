/************************************************************************/
/*	Archivo: 		interesa.sp				*/
/*	Stored procedure: 	sp_intereses_anticipados   	        */
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Elcira Pelaez Burbano                   */
/*	Fecha de escritura: 	Ago/05/2001				*/
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
/*	Retorna el calculo del Interes de interes anticiapdo para       */
/*      una cuota en especial y dias especificos  a la tasa del dia     */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_intereses_anticipados')
   drop proc sp_intereses_anticipados

go

create proc sp_intereses_anticipados (
@i_operacionca	       int,
@i_concepto            catalogo,
@i_novigente           char(1) = 'N',
@o_valor_intant        money output,
@o_tasa_intant         float =   null output,
@o_dias_recalcular     int   =   null output
)
as
declare	
@w_sp_name			varchar(32),
@w_return			int,
@w_error			int,
@w_dividendo_vig                int,
@w_fecha_ven                    datetime,
@w_di_fecha_ven                 datetime,
@w_concepto                     catalogo,
@w_saldo_cap                    money,
@w_est_novigente		tinyint,
@w_est_vigente                  tinyint,
@w_est_cancelado                tinyint,
@w_est_castigo_oper             tinyint,
@w_est_suspenso                 tinyint,
@w_moneda_op                    smallint,
@w_fecha_proceso                datetime,
@w_fpago                        char(1),
@w_tasa_prestamo                float,
@w_num_periodo_d                smallint,
@w_periodo_d                    catalogo,
@w_periodicidad_o               catalogo,
@w_dias_anio                    smallint,
@w_base_calculo                 char(1),
@w_modalidad                    char(1),
@w_modalidad_o                  char(1),
@w_est_vencido                  tinyint,
@w_causacion                    char(1),
@w_ro_modalidad                 char(1),
@w_di_fecha_ini                 datetime,
@w_tipo_rubro                   char(1),
@w_periodo			smallint,
@w_tperiodo			catalogo,
@w_toperacion                   catalogo,
@w_dias_calc                    smallint,
@w_valor_rubro                  money,
@w_num_dec                      tinyint,
@w_devolucion                   money,
@w_capital_dev                  money,
@w_intant                       varchar(30),
@w_sector                       catalogo,
@w_ro_referencial               catalogo,
@w_convierte_tasa               char(1),
@w_periodicidad_efa             catalogo,
@w_modalidad_efa                char(1),
@w_tipotasa_o                   char(1),
@w_ro_tipo_puntos               char(1),
@w_ro_signo                     char(1),
@w_tasa_referencial             catalogo,
@w_tipopuntos                   char(1),
@w_ro_factor                    float,
@w_forma_pago                   char(1),
@w_modalidad_d                  char(1),
@w_signo                        char(1),
@w_factor                       float,
@w_tasa_int                     float,
@w_tasa_d                       float,
@w_tasa_efa                     float,
@w_ro_porcentaje		float,
@w_tipo_cobro 			char(1),

/* VARIABLES INTANT*/

@w_dias_acumulados              int,
@w_dias_cuota                   int,
@w_dias_recalcular              int,
@w_valor_aplicar                catalogo,
@w_acumulado                    money,
@w_nombre_tasa                  catalogo,
@w_num_dec_tapl                 tinyint,
@w_tasa_recalculo               float,
@w_valor_calc                   money,
@w_monto_cap                    money,
@w_saldo_para_cuota             money,
@w_saldo_cap_ven                money,
@w_tasa_nom                     float,
@w_cuota                        money,
@w_dividendo_novig              smallint


/**INICIALIZACION DE VARIABLES**/
select	
@w_sp_name          = 'sp_qr_pagos',
@w_est_novigente    = 0,
@w_est_vigente      = 1,
@w_est_cancelado    = 3,
@w_est_vencido      = 2,
@w_dias_acumulados  = 0,
@w_dias_cuota       = 0


/** INFORMACION DE OPERACION **/
select 
@i_operacionca        = op_operacion,
@w_fecha_ven          = op_fecha_fin,
@w_moneda_op          = op_moneda,
@w_fecha_proceso      = op_fecha_ult_proceso,
@w_num_periodo_d      = op_periodo_int,
@w_periodo_d          = op_tdividendo,
@w_dias_anio          = op_dias_anio,
@w_base_calculo       = op_base_calculo,
@w_causacion          = op_causacion,
@w_sector             = op_sector,
@w_convierte_tasa     = op_convierte_tasa,
@w_tipo_cobro	      = op_tipo_cobro,
@w_monto_cap          = op_monto
from ca_operacion
where  op_operacion       = @i_operacionca

/** DECIMALES **/
exec sp_decimales
@i_moneda    = @w_moneda_op, 
@o_decimales = @w_num_dec out


---PRINT 'interesa.sp --> llego con @i_novigente %1!',@i_novigente

/** INFORMACION DEL DIVIDENDO VIGENTE **/
if @i_novigente = 'N' begin
   select 
   @w_di_fecha_ini  = di_fecha_ini,
   @w_di_fecha_ven  = di_fecha_ven,
   @w_dividendo_vig = di_dividendo,
   @w_dias_cuota    = di_dias_cuota

   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_estado    = @w_est_vigente
   if @@rowcount = 0 begin
     /* EXTRAER ULTIMO DIVIDENDO SI NO TIENE DIVIDENDO VIGENTE */
     select @w_di_fecha_ven = @w_fecha_ven
     select @w_dividendo_vig = max(di_dividendo) + 1
     from ca_dividendo
     where di_operacion = @i_operacionca
   end
end

if @i_novigente = 'S' begin

   select    @w_dividendo_vig = di_dividendo
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_estado    = @w_est_vigente

   select @w_dividendo_novig = @w_dividendo_vig + 1
  

   select 
   @w_di_fecha_ini  = di_fecha_ini,
   @w_di_fecha_ven  = di_fecha_ven,
   @w_dividendo_vig = di_dividendo,
   @w_dias_cuota    = di_dias_cuota,
   @w_est_vigente   = di_estado
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_dividendo = @w_dividendo_novig
   if @@rowcount = 0 begin
     /* EXTRAER ULTIMO DIVIDENDO SI NO TIENE DIVIDENDO VIGENTE */
     select @w_di_fecha_ven = @w_fecha_ven
     select @w_dividendo_vig = max(di_dividendo) + 1
     from ca_dividendo
     where di_operacion = @i_operacionca
   end
end


   select 
   @w_concepto      = ro_concepto,
   @w_fpago         = ro_fpago,
   @w_tipo_rubro    = ro_tipo_rubro,
   @w_ro_porcentaje = ro_porcentaje,
   @w_valor_aplicar = ro_referencial,
   @w_num_dec_tapl  = ro_num_dec
   from ca_rubro_op,
        ca_concepto
   where ro_operacion = @i_operacionca
   and ro_concepto  = @i_concepto
   and ro_fpago    <> 'L'
   and co_concepto = ro_concepto



           /*SALDO DE CAPITAL EN LA CUOTA VIGENTE */

	   select @w_saldo_cap_ven = sum(am_cuota )
	   from ca_amortizacion, ca_rubro_op
	   where  am_operacion  = @i_operacionca
           and    am_dividendo      < @w_dividendo_vig
           and    ro_operacion  = @i_operacionca
	   and    ro_concepto   = am_concepto
           and    ro_tipo_rubro = 'C'

           select @w_saldo_para_cuota  = (@w_monto_cap - @w_saldo_cap_ven)
   
            ---PRINT'interesa.sp @i_concepto %1! @w_est_vigente %2! @i_operacionca %3!',@i_concepto,@w_est_vigente,@i_operacionca

            select @w_acumulado = sum(isnull(am_acumulado,0))  ---EPB:feb-22-2002
            from  ca_amortizacion
            where am_operacion = @i_operacionca
            and   am_concepto  = @i_concepto
            and   am_dividendo = @w_dividendo_vig
            if @w_acumulado <= 0 begin
                /*HAY MAS VALOR PAGADO QUE ACUMULADO*/
               select @w_acumulado =  sum(isnull(am_pagado,0))
               from  ca_amortizacion
               where am_operacion = @i_operacionca
               and   am_concepto  = @i_concepto
               and   am_dividendo = @w_dividendo_vig

            end

            ----PRINT 'cap %1! acumulado %2!, @w_ro_porcentaje %3! @w_dividendo_vig %4!',@w_monto_cap, @w_acumulado ,@w_ro_porcentaje,@w_dividendo_vig
 
             exec @w_return =  sp_dias_calculo
                  @tasa        = @w_ro_porcentaje,
		  @monto       = @w_saldo_para_cuota, ---@w_monto_cap,
		  @interes     = @w_acumulado,
		  @dias_anio   = @w_dias_anio,
		  @dias        = @w_dias_acumulados  out
            if @w_return <> 0 begin
               PRINT '(interesa.sp) error ejecutando sp_dias_calculo'
            end
            
            ---PRINT '(interesa.sp ) @w_dias_acumulados %1!',@w_dias_acumulados

            select @w_dias_recalcular = @w_dias_cuota - @w_dias_acumulados


           ---PRINT '(interesa.sp )@w_dias_cuota %1! , @w_dias_acumulados %2!', @w_dias_cuota,@w_dias_acumulados


           if @i_novigente = 'S'
              select @w_dias_recalcular = @w_dias_cuota

          ---PRINT '(interesa.sp )  @w_saldo_para_cuota %1!',@w_saldo_para_cuota
 

            select @w_tasa_nom = @w_ro_porcentaje
            select @w_tasa_recalculo = @w_tasa_nom

         ---PRINT '(interesa.sp )  entro tasa <>  @w_dias_recalcular %1!,@w_tasa_recalculo %2! @w_saldo_para_cuota %3!',@w_dias_recalcular,@w_tasa_recalculo,@w_saldo_para_cuota


               exec @w_return = sp_calc_intereses
               @tasa      = @w_tasa_recalculo,
               @monto     = @w_saldo_para_cuota,
               @dias_anio = 360,
               @num_dias  = @w_dias_recalcular,
               @causacion = 'L', ---@w_causacion, 
               @causacion_acum = 0, 
               @intereses = @w_valor_calc out

               select @w_valor_calc = isnull(@w_valor_calc,0)

            
            /* FIN CALCULO INTANT A LA TASA DEL DIA*/


          ---PRINT '(interesa.sp )  @w_valor_calc %1!, @w_tasa_recalculo%2! ,@w_dias_recalcular%3!',@w_valor_calc,@w_tasa_recalculo,@w_dias_recalcular
           

            select @o_valor_intant = @w_valor_calc,
                   @o_tasa_intant  = @w_tasa_recalculo,
                   @o_dias_recalcular = @w_dias_recalcular



return 0

go

