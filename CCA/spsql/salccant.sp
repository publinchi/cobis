/************************************************************************/
/*	Archivo:		salccant.sp   				*/
/*	Stored procedure:	sp_saldo_op_anticipado  		*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Diego Aguilar   		   	*/
/*	Fecha de escritura:	Oct 1999	   			*/
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
/*	Obtener el saldo del prestamo en modalidadad anticipada en las  */
/*      tipos (Acumulada,Proyectada,Presente                            */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldo_op_anticipado')
	drop proc sp_saldo_op_anticipado
go

create proc sp_saldo_op_anticipado (
   @i_operacionca       int,
   @i_tipo_cobro        char(1), -- P,A,E
   @i_formato_fecha     int = 101, 
   @o_saldo_op          money = 0 out

)

as declare 
   @w_sp_name         descripcion,
   @w_operacionca     int,
   @w_return          int,
   @w_error           int,
   @w_di_dividendo    int,
   @w_fecha_ult_proceso datetime,
   @w_di_fecha_ini    datetime, 
   @w_di_estado       int,
   @w_pago            money,
   @w_pago2           money,
   @w_pagov           money,
   @w_pagoa           money,
   @w_valor_cap       money,
   @w_devolucion      money,
   @w_calculo_int_vig money, 
   @w_est_cancelado   int,
   @w_dividendo_can   int,
   @w_contador        int,
   @w_di_dividendo2   int,
   @w_dias_i          int,
   @w_di_fecha_ini2   datetime, 
   @w_di_fecha_ven2   datetime,
   @w_di_fecha_ven    datetime,
   @w_di_fecha_ven_aux  datetime,
   @w_di_fecha_ini_aux  datetime,
   @w_found           smallint,
   @w_dias_cuota      int,
   @w_periodo_int     int,
   @w_tdividendo      catalogo,
   @w_dividendo_vig   int,
   @w_dias            int,
   @w_est_vigente     int,
   @w_dividendo       int,
   @w_dd_antes        int,
   @w_dd_despues      int,
   @w_dias_anio       int,
   @w_base_calculo    char(1),
   @w_ro_tipo_rubro   char(1),
   @w_pago_presente   money,
   @w_estado          catalogo,
   @w_modalidad       char(1),
   @w_tasa_prepago    float,
   @w_dividendo_max   int,
   /*VARIABLES DE PROYECCION DE TOTAL DEL PRESTAMO*/
   @w_dividendo_max_ven   int,
   @w_dividendo_min_ven   int,
   @w_fecha_fin_op    datetime,
   @w_monto_venc_v    money,
   @w_monto_venc_a    money,
   @w_monto_vig_v    money,
   @w_monto_vig_a    money,
   @w_monto_proy_v   money,
   @w_monto_proy_a   money,
   @w_monto_vencido  money,
   @w_monto_vigente  money,
   @w_monto_proyectado money,
   @w_total_x_rubro   money,
   @w_ro_concepto    catalogo,
   @w_est_vencido    int,
   @w_sum_vencido    money,
   @w_sum_vigente    money,
   @w_sum_proyectado money,
   @w_sum_t_x_rubro  money,
   @w_tasa_vp        float,
   @w_moneda         int, 
   @w_num_dec        int,
   @w_num_dec_tapl   tinyint

/* INICIALIZACION DE VARIABLES */
select	
@w_sp_name       = 'sp_saldo_op_anticipado',
@w_est_cancelado = 3,
@w_est_vigente   = 1,
@w_est_vencido   = 2,
@w_contador      = 0,
@w_tasa_vp       = 0,
@w_num_dec_tapl  = null

select 
@w_operacionca        = op_operacion,
@w_fecha_ult_proceso  = op_fecha_ult_proceso,
@w_fecha_fin_op       = op_fecha_fin,
@w_periodo_int        = op_periodo_int,
@w_tdividendo         = op_tdividendo,
@w_moneda             = op_moneda,
@w_dias_anio          = op_dias_anio,
@w_base_calculo       = op_base_calculo
from   ca_operacion
where  op_operacion   = @i_operacionca

exec @w_return = sp_decimales
@i_moneda      = @w_moneda,
@o_decimales   = @w_num_dec out

if @w_return != 0 return @w_return

/*CALCULAR TASA DE INTERES PRESTAMO*/
select
   @w_tasa_prepago = isnull(sum(ro_porcentaje),0),
   @w_num_dec_tapl = ro_num_dec
   from ca_rubro_op
   where ro_operacion  = @w_operacionca
   and   ro_tipo_rubro = 'I'
   and   ro_fpago     in ('A','P')
   group by ro_fpago, ro_num_dec, ro_tipo_rubro, ro_porcentaje


/* BUSQUEDA DEL SIGUIENTE DIVIDENDO QUE NO SEA CANCELADO */
select @w_dividendo_can = isnull(max(di_dividendo),0)
from ca_dividendo
where di_operacion = @w_operacionca
and   di_estado    = @w_est_cancelado

select @w_dividendo = @w_dividendo_can

/*MAXIMO DIVIDENDO*/
select @w_dividendo_max = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @w_operacionca

/* BUSCAR DIVIDENDO VIGENTE */
select @w_dividendo_vig = di_dividendo
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vigente

if @@rowcount = 0 
   select @w_dividendo_vig = @w_dividendo_max + 1

select @w_dividendo_min_ven = min(di_dividendo)
from ca_dividendo
where di_operacion = @w_operacionca
and   di_estado    = @w_est_vencido 

select @w_dividendo_max_ven = max(di_dividendo)
from ca_dividendo
where di_operacion = @w_operacionca
and   di_estado    = @w_est_vencido 


/* VERIFICAR SI LA OPERACION TIENE RUBROS DE TIPO ANTICIPADO */
if exists(select 1 from ca_rubro_op
where ro_operacion  = @w_operacionca
and   ro_fpago      = 'A'
and   ro_tipo_rubro = 'I')
   select @w_modalidad = 'A'
else
   select @w_modalidad = 'V'

/*COVERTIR TASA DE LA OPERACION A EFECTIVA */
exec @w_return =  sp_conversion_tasas_int
@i_dias_anio      = @w_dias_anio,
@i_periodo_o      = @w_tdividendo,
@i_modalidad_o    = @w_modalidad,
@i_num_periodo_o  = @w_periodo_int,
@i_tasa_o         = @w_tasa_prepago, 
@i_periodo_d      = 'A',
@i_modalidad_d    = 'V',
@i_num_periodo_d  = 1,
@i_num_dec        = @w_num_dec_tapl,
@o_tasa_d         = @w_tasa_vp output

if @w_return <> 0 return @w_return 

select @w_tasa_vp = @w_tasa_vp / 100  --DAG

/*******************************************
/*COVERTIR TASA DE PREPAGO A TASA DIARIA VENCIDA */
exec @w_return =  sp_conversion_tasas_int
@i_dias_anio      = @w_dias_anio,
@i_periodo_o      = @w_tdividendo,
@i_modalidad_o    = @w_modalidad,
@i_num_periodo_o  = @w_periodo_int,
@i_tasa_o         = @w_tasa_prepago, 
@i_periodo_d      = 'D',
@i_modalidad_d    = 'V',
@i_num_periodo_d  = 1,
@i_num_dec        = @w_num_dec_tapl,
@o_tasa_d         = @i_tasa_prepago output

if @w_return <> 0 return @w_return 
*******************************************/

select @w_di_fecha_ini = @w_fecha_ult_proceso

select @w_calculo_int_vig = 0 

declare cursor_dividendo cursor for
  select
    di_dividendo, di_fecha_ven, di_estado
    from  ca_dividendo
    where di_operacion =  @w_operacionca
    and   di_dividendo >  @w_dividendo
    for read only

open cursor_dividendo

fetch cursor_dividendo into
@w_di_dividendo, @w_di_fecha_ven, @w_di_estado

while   @@fetch_status = 0 begin 

   if (@@fetch_status = -1) begin
      select @w_error = 708999
      goto ERROR
   end 

   if @i_tipo_cobro = 'A' begin

      if @w_modalidad = 'V' begin

         select @w_pago = 
         sum((abs(am_acumulado + am_gracia - am_pagado )
         +(am_acumulado + am_gracia - am_pagado ))/2)
         from ca_amortizacion
         where am_operacion = @w_operacionca
         and   am_dividendo > @w_dividendo_can
         and   am_dividendo <= @w_di_dividendo


      end 
      else begin

         --ESTO ES PARA SACAR TODOS LOS RUBROS A EXCEPCION DE ANTICIPADOS
         select @w_pago = 
         sum((abs(am_acumulado + am_gracia - am_pagado )
         +(am_acumulado + am_gracia - am_pagado ))/2)
         from ca_amortizacion, ca_rubro_op
         where ro_operacion = @w_operacionca
         and   ro_operacion = am_operacion
         and   ro_concepto  = am_concepto
         and   ro_fpago     <> 'A'
         and   am_dividendo > @w_dividendo_can
         and   am_dividendo <= @w_di_dividendo

         if @w_di_fecha_ven = @w_fecha_ult_proceso 
            select @w_dividendo_vig = @w_dividendo_vig + 1

         select @w_pago2 =
         isnull(sum(am_cuota + am_gracia - am_pagado ),0)
         from ca_amortizacion, ca_rubro_op
         where ro_operacion = @w_operacionca
         and   ro_operacion = am_operacion
         and   ro_concepto  = am_concepto
         and   ro_fpago     = 'A'
         and   am_dividendo > @w_dividendo_can
         and   am_dividendo <= @w_dividendo_vig

         if @w_di_dividendo >= @w_dividendo_vig
           /* CALCULAR SALDO DE CAPITAL */
            select @w_valor_cap = 
            isnull(sum(am_cuota + am_gracia - am_pagado ),0)
            from  ca_amortizacion, ca_rubro_op
            where ro_operacion = @w_operacionca
            and   ro_operacion = am_operacion
            and   ro_concepto  = am_concepto
            and   ro_tipo_rubro= 'C'
            and   am_dividendo >= @w_di_dividendo
         else
            select @w_valor_cap = 0

         select @w_di_fecha_ven_aux = di_fecha_ven,
         @w_di_fecha_ini_aux = di_fecha_ini,
         @w_dias_cuota       = di_dias_cuota
         from ca_dividendo 
         where di_operacion = @w_operacionca
         and   di_dividendo = @w_dividendo_vig

         if @@rowcount = 0 
            select @w_found = 0
         else 
            select @w_found = 1

         if @w_di_dividendo = @w_dividendo_vig begin
            if @w_found = 1 begin
               if @w_base_calculo = 'R' begin
                  select @w_dd_antes = datediff(dd,@w_di_fecha_ini_aux, @w_fecha_ult_proceso)
                  select @w_dd_despues = datediff(dd, @w_fecha_ult_proceso, @w_di_fecha_ven_aux)
               end
               else begin
                  exec @w_return = sp_dias_base_comercial
                  @i_fecha_ini = @w_di_fecha_ini_aux,
                  @i_fecha_ven = @w_fecha_ult_proceso,
                  @i_opcion    = 'D',
                  @o_dias_int  = @w_dd_antes out

                  exec @w_return = sp_dias_base_comercial
                  @i_fecha_ini = @w_fecha_ult_proceso,
                  @i_fecha_ven = @w_di_fecha_ven_aux,
                  @i_opcion    = 'D',
                  @o_dias_int  = @w_dd_despues out
               end

               if @w_dias_cuota = (@w_dd_antes + @w_dd_despues)
                  select @w_dias = @w_dd_despues
   
               if @w_dias_cuota < (@w_dd_antes + @w_dd_despues)
                  select @w_dias = @w_dd_despues - abs(@w_dias_cuota - (@w_dd_antes + @w_dd_despues))
 
               if @w_dias_cuota > (@w_dd_antes + @w_dd_despues)
                  select @w_dias = @w_dd_despues + abs(@w_dias_cuota - (@w_dd_antes + @w_dd_despues))
            end
            else
               select @w_dias = 0
         end
         else
            select @w_dias = di_dias_cuota
            from ca_dividendo 
            where di_operacion = @w_operacionca
            and   di_dividendo = @w_di_dividendo 

            select @w_devolucion = 
            @w_valor_cap * @w_tasa_prepago * @w_dias / (100 * @w_dias_anio)
   
            select @w_devolucion = round(@w_devolucion,@w_num_dec)
 
            if @w_di_dividendo = @w_dividendo_vig begin
               select @w_calculo_int_vig = @w_devolucion
               select @w_pago2 = @w_pago2 - @w_devolucion 
               select @w_pago = @w_pago + @w_pago2  
            end
            else
               select @w_pago = @w_pago + @w_pago2 - @w_calculo_int_vig
 
      end

   end

   if @i_tipo_cobro = 'P' begin

      select @w_pago =
      isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_rubro_op
      where ro_operacion = @w_operacionca
      and   ro_operacion = am_operacion
      and   ro_concepto  = am_concepto
      and   ro_fpago     <> 'A'
      and   am_dividendo > @w_dividendo_can
      and   am_dividendo <= @w_di_dividendo

      select @w_pago2 =
      isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_rubro_op
      where ro_operacion = @w_operacionca
      and   ro_operacion = am_operacion
      and   ro_concepto  = am_concepto
      and   ro_fpago     = 'A'
      and   am_dividendo > @w_dividendo_can
      and   am_dividendo <= @w_di_dividendo + 1

      select @w_pago = @w_pago + @w_pago2

   end


   if @i_tipo_cobro = 'E' begin
      select 
      @w_di_dividendo2 = @w_di_dividendo,
      @w_pago          = 0

      while @w_di_dividendo2 >= @w_dividendo_vig begin

         select 
         @w_di_fecha_ven2 = di_fecha_ven,
         @w_di_fecha_ini2 = di_fecha_ini
         from ca_dividendo
         where di_operacion = @w_operacionca
         and   di_dividendo = @w_di_dividendo2

         select @w_pago2 =
         isnull(sum(am_cuota + am_gracia - am_pagado ),0)
         from ca_amortizacion, ca_rubro_op
         where ro_operacion = @w_operacionca
         and   ro_operacion = am_operacion
         and   ro_concepto  = am_concepto
         and   am_dividendo = @w_di_dividendo2
         and   ro_fpago    <> 'A'

         select @w_pagoa =
         isnull(sum(am_cuota + am_gracia - am_pagado ),0)
         from ca_amortizacion, ca_rubro_op
         where ro_operacion = @w_operacionca
         and   ro_operacion = am_operacion
         and   ro_concepto  = am_concepto
         and   am_dividendo = @w_di_dividendo2 + 1
         and   ro_fpago     = 'A'

         select @w_pago = @w_pago + @w_pago2 + @w_pagoa

         if @w_di_dividendo2 = @w_dividendo_vig
            select @w_di_fecha_ini2 = @w_fecha_ult_proceso

         select @w_dias = datediff(dd, @w_di_fecha_ini2, @w_di_fecha_ven2)

         /** FORMULA: VP = VF / (1 + i) elevado a la n  **/
         select @w_pago = @w_pago / power( (1.0 + @w_tasa_vp), 
         convert(float,@w_dias) / @w_dias_anio)
         select @w_di_dividendo2 = @w_di_dividendo2 - 1

      end

      select @w_pagov =
      isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion
      where am_operacion = @w_operacionca
      and   am_dividendo > @w_dividendo_can
      and   am_dividendo <= @w_di_dividendo2

      select @w_pago = @w_pago + @w_pagov

   end

   select @w_estado = es_descripcion
   from ca_estado
   where es_codigo = @w_di_estado

   select @w_di_fecha_ini = @w_di_fecha_ven

   fetch cursor_dividendo into
   @w_di_dividendo, @w_di_fecha_ven, @w_di_estado
end

close cursor_dividendo
deallocate cursor_dividendo

select 
@o_saldo_op = isnull(@w_pago,0)     

return 0

ERROR:
exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error

go
