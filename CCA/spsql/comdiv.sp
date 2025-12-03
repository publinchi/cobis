/************************************************************************/
/*	Archivo:            comdiv.sp                                       */
/*	Stored procedure:   sp_completar_div                                */
/*	Base de datos:      cob_cartera                                     */
/*	Producto:           Cartera                                         */
/*	Disenado por:       Fabian de la Torre                              */
/*	Fecha de escritura:	Jul. 1997                                       */
/************************************************************************/
/*				IMPORTANTE                                              */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	"MACOSA".                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier alteracion o agregado hecho por alguno de sus             */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				PROPOSITO                                               */
/*	Completar los dividendos y amortizaciones necesarias para los       */
/*  prestamos tipo rotativos                                            */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_completar_div')
	drop proc sp_completar_div
go

create proc sp_completar_div
   @i_operacion_nueva              int,
   @i_operacion_orig               int,
   @i_diferencia                   smallint,
   @i_oficina                      smallint = null, 
   @i_plazo                        int= null,
   @i_tplazo                       catalogo= null,
   @i_tdividendo                   catalogo= null,
   @i_dias_gracia                  smallint = 0,
   @i_periodo_cap                  int= null,
   @i_periodo_int                  int= null,
   @i_mes_gracia    		   tinyint= null,
   @i_fecha_ini                    datetime= null,
   @i_dia_fijo                     int = 0,
   @i_evitar_feriados              char(1) = 'S',
   @i_cuota        		   money = 0
 
as
declare 
   @w_sp_name                      descripcion,
   @w_return                       int,
   @w_error                        int,
   @w_dias_op                      int,
   @w_dias_di                      int,
   @w_dias_paso                    int,
   @w_meses_di                     int,
   @w_num_dividendos               int,
   @w_dividendo                    int,
   @w_dividendo_ini                int,
   @w_cont                         int,
   @w_dia_fijo                     int,
   @w_di_de_cap                    char(1),
   @w_di_de_int                    char(1),
   @w_est_no_vigente               tinyint,
   @w_est_vigente                  tinyint,
   @w_est_vencido                  tinyint,
   @w_di_fecha_ini                 datetime,
   @w_di_fecha_ven                 datetime,
   @w_aux	                   smallint,
   @w_estado                       tinyint,
   @w_est_cancelado                tinyint,
   @w_prorroga                     char(1),
   @w_rowcount                     int


select @w_sp_name = 'sp_completar_div'

select 
@w_est_no_vigente = 0,
@w_est_vigente    = 1,
@w_est_vencido    = 2,
@w_est_cancelado  = 3

select @i_operacion_nueva = @i_operacion_nueva

select 
@i_oficina          = op_oficina,
@i_plazo            = op_plazo,
@i_tplazo           = op_tplazo,
@i_tdividendo       = op_tdividendo,
@i_dias_gracia      = 0,
@i_periodo_cap      = op_periodo_cap,
@i_periodo_int      = op_periodo_int,
@i_mes_gracia       = op_mes_gracia,
@i_dia_fijo         = op_dia_fijo,
@i_evitar_feriados  = op_evitar_feriados,
@i_cuota            = op_cuota
from ca_operacion
where op_operacion  = @i_operacion_orig

select @w_dividendo_ini = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @i_operacion_orig

select 
@w_estado    = di_estado,
@i_fecha_ini = di_fecha_ven
from   ca_dividendo 
where  di_operacion = @i_operacion_orig
and    di_dividendo = @w_dividendo_ini

if @w_estado = @w_est_vencido 
select @w_estado = @w_est_vigente
else 
if @w_estado = @w_est_vigente 
select @w_estado = @w_est_no_vigente
else if @w_estado = @w_est_cancelado 
select @w_estado = @w_est_vigente

/* MAYOR DIVIDENDO TEMPORAL */
select @w_dividendo_ini = max(dit_dividendo)
from   ca_dividendo_tmp
where  dit_operacion    = @i_operacion_nueva

if @w_dividendo_ini is null   /*AUMENTADO 26/Ene/99*/
   select @w_dividendo_ini = 0

/* VALIDAR DATOS DE ENTRADA */
if @i_periodo_cap < @i_periodo_int begin
   select @w_error = 710012 
   goto ERROR
end

if @i_periodo_cap % @i_periodo_int <> 0 begin
   select @w_error = 710013
   goto ERROR
end

/* CALCULAR NUMERO DE DIVIDENDOS */
select 
@w_dias_op = 0,
@w_dias_di = 0

select @w_dias_op = @i_plazo * td_factor
from ca_tdividendo
where td_tdividendo = @i_tplazo

if @w_dias_op = 0 begin
   select @w_error = 710007
   goto ERROR
end

select @w_dias_di = @i_periodo_int * td_factor
from ca_tdividendo
where td_tdividendo = @i_tdividendo

if @w_dias_di = 0 begin
   select @w_error = 710007
   goto ERROR
end

if @w_dias_op % @w_dias_di <> 0 begin
   select @w_error = 710008
   PRINT 'error en comdiv.sp'
   goto ERROR
end

select @w_num_dividendos = @w_dividendo_ini + @i_diferencia

/* CONTROL SOBRE TABLAS DE FECHA FIJA */
if @i_dia_fijo > 0 begin

   if @w_dias_di % 30 <> 0 begin
      select @w_error = 710009
      goto ERROR
   end

   select @w_meses_di = @w_dias_di / 30

   select @w_dias_paso = pa_tinyint
   from cobis..cl_parametro
   where pa_nemonico = 'NDO'
   and   pa_producto = 'CCA'
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 begin
      select @w_error = 710010
      goto ERROR
   end

   if @w_dias_paso > 27 begin
      select @w_error = 710011
      goto ERROR
   end

end

/* INSERTAR LOS DIVIDENDOS EN LA TABLA CA_DIVIDENDO_TMP */

select 
@w_dividendo = @w_dividendo_ini,
@w_di_fecha_ini = @i_fecha_ini,
@w_aux = 0

while @w_dividendo < @w_num_dividendos begin

   select @w_dividendo = @w_dividendo + 1

   /* CALCULAR FECHA DE VENCIMIENTO DEL DIVIDEDO ACTUAL */
   if @i_dia_fijo > 0 
   begin
      select @w_cont = 0

      while 2 = 2 begin
         select @w_dia_fijo = @i_dia_fijo

         select @w_di_fecha_ven = 
         dateadd (mm, @w_meses_di*
         ((@w_dividendo-@w_dividendo_ini) + @w_cont) + 1,@i_fecha_ini)
         
         select @w_di_fecha_ven =
         dateadd (dd, datepart(dd,@i_fecha_ini)*-1, @w_di_fecha_ven)

         if datepart(dd,@w_di_fecha_ven) < @w_dia_fijo 
            select @w_dia_fijo = datepart(dd,@w_di_fecha_ven)
      
         select @w_dia_fijo = @w_dia_fijo - datepart(dd,@w_di_fecha_ven)

         select @w_di_fecha_ven = dateadd(dd,@w_dia_fijo,@w_di_fecha_ven)
        
         if datediff(dd,@w_di_fecha_ini,@w_di_fecha_ven) < @w_dias_paso
            select @w_cont = @w_cont + 1
         else
            break
      end

   end else begin
      select 
      @w_di_fecha_ven = 
      dateadd(dd,@w_dias_di*(@w_dividendo-@w_dividendo_ini),@i_fecha_ini)

   end

   /* CONTROL PARA EVITAR DIAS FERIADOS */
   while  @i_evitar_feriados = 'S' begin
      if exists(select 1
      from  cobis..cl_dias_feriados,cobis..cl_oficina
      where  df_fecha = @w_di_fecha_ven
      and    df_ciudad = of_ciudad
      and    of_oficina = @i_oficina)
         select  @w_di_fecha_ven = dateadd(dd, 1, @w_di_fecha_ven)
      else
         break
   end

   /* VERIFICAR EL TIPO DEL DIVIDENDO */
   select 
   @w_di_de_cap = 'N',
   @w_di_de_int = 'N'

   /* SIN SON IGUALES ENTONCES SON DE CAPITAL E INTERES, REVISAR */
   if ((@w_dividendo ) % (@i_periodo_cap / @i_periodo_int)) = 0 
      select @w_di_de_cap = 'S'

   if ((@w_dividendo ) % (@i_periodo_int / @i_periodo_int)) = 0 
      select @w_di_de_int = 'S'

   if datepart(mm,@w_di_fecha_ven) = @i_mes_gracia begin

      select @w_num_dividendos = 
      @w_num_dividendos + (@i_periodo_cap / @i_periodo_int)

   end      

   if datepart(mm,@w_di_fecha_ven) <> @i_mes_gracia begin

       if exists (select 1 from ca_prorroga
                 where pr_operacion = @i_operacion_nueva
                 and   pr_nro_cuota = @w_dividendo+@w_aux)

          select @w_prorroga = 'S'
       else
          select @w_prorroga = 'N'
      

      /* INSERTAR REGISTRO */
      insert into ca_dividendo_tmp 
      (dit_operacion,dit_dividendo,dit_fecha_ini,
      dit_fecha_ven,dit_de_capital,dit_de_interes,
      dit_gracia,dit_gracia_disp,dit_estado,dit_prorroga,dit_dias_cuota,dit_intento, dit_fecha_can)
      values (
      @i_operacion_nueva,   @w_dividendo+@w_aux,   @w_di_fecha_ini,
      @w_di_fecha_ven,  @w_di_de_cap,   @w_di_de_int,
      @i_dias_gracia,   @i_dias_gracia, @w_estado, @w_prorroga,0,0,'01/01/1900')
      
      if @@error <> 0 begin
         select @w_error = 710001
         goto ERROR
      end
    
      select @w_estado = @w_est_no_vigente
 
      /* INSERTAR REGISTRO EN CASO DE NO EXISTIR */
      if not exists (select 1 from ca_cuota_adicional_tmp
      where cat_operacion = @i_operacion_nueva
      and   cat_dividendo = @w_dividendo+@w_aux) begin

         insert into ca_cuota_adicional_tmp 
         (cat_operacion,cat_dividendo,cat_cuota)
         values (
         @i_operacion_nueva,   @w_dividendo + @w_aux,   0.0  )

         if @@error <> 0 begin
            select @w_error = 710001
            goto ERROR
         end

      end

      select @w_di_fecha_ini = @w_di_fecha_ven

   end else
      select @w_aux = @w_aux - 1

end --Lazo de dividendos


return 0

ERROR:

return @w_error
 
go
