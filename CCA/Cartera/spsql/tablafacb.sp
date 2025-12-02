/************************************************************************/
/*	Archivo:		tablafacb.sp				                        */
/*	Stored procedure:	sp_tablafac_batch     			                */
/*	Base de datos:		cob_cartera				                        */
/*	Producto: 		Cartera					                            */
/*	Disenado por:  		Xavier Maldonado 			                    */
/*	Fecha de escritura:	Sep. 2000  				                        */
/************************************************************************/
/*				IMPORTANTE				                                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	"COBISCORP".							                            */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de COBISCORP o su representante.		        */
/************************************************************************/  
/*				PROPOSITO				                                */
/*	Procedimiento  que gerera la tabla de amortizacion para las         */ 
/*      operaciones FACTORING                                           */
/*                              CAMBIOS                                 */
/*    FECHA            AUTOR              CAMBIO	                    */
/*    01-Jun-2022      G. Fernandez    Se comenta prints                */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tablafac_batch')
	drop proc sp_tablafac_batch
go

create proc sp_tablafac_batch
        @i_operacionca                  int,
        @i_dist_gracia                  char(1)  = 'S',
        @i_dias_anio                    int      = 360,
        @i_num_dec                      int      = 0,
        @i_opcion_cap                   char(1)  = null,
        @i_tasa_cap                     float    = null,
        @i_base_calculo                 char(1)  = 'R', 
        @i_recalcular                   char(1)  = 'S', 
        @i_dias_interes                 smallint = null,
	@i_tipo_redondeo		tinyint  = 1,  
        @i_tramite_hijo                 int      = null
 
as
declare 
        @w_sp_name			descripcion,
	@w_return			int,
	@w_error			int,
        @w_num_dividendos               int,
        @w_di_num_dias                  int,
        @w_dividendo                    int,
        @w_cont_cap                     int,
        @w_cont_int                     int,
        @w_adicional                    money,
        @w_cuota_cap                    float,
        @w_float                        float,
        @w_monto_cap                    money,
        @w_saldo_cap                    float,
        @w_cap_aux                      money,
        @w_valor_rubro                  money,
        @w_porcentaje                   float,
        @w_valor_calc                   money,
        @w_valor_grcap                  money,
        @w_valor_grint                  money,
        @w_valor_gr                     money,
        @w_di_fecha_ini                 datetime,
        @w_di_fecha_ven                 datetime,
        @w_concepto                     catalogo,
        @w_estado                       tinyint,
        @w_tipo_rubro                   char(1),
        @w_fpago                        char(1),
        @w_de_capital                   char(1),
        @w_de_interes                   char(1),
        @w_aux_cuota_cap		money,
        @w_int_aux			money,
        @w_aux                          tinyint, 
        @w_factor                       tinyint,
        @w_provisiona                   char(1),
        @w_tasa_equivalente             char(1),
        @w_reajuste                     char(1),
        @w_cuota_int                    money,
        @w_tasa_tot_int                 float,
        @w_salir                        int,
        @w_periodo_int                  int,
        @w_tipo                         char(1),
        @w_div_ant                      int,
	@w_factor_redondeo		float,	
	@w_cuota_nueva			float,
	@w_parte_entera			float,
        @w_parte_decimal                float,
        @w_valor_base                   float, 
        @w_sobrante_faltante            float,  
        @w_dias_int                     float,
        @w_dias_anio                    smallint,
        @w_monto                        money,
	@w_opt_tramite			int,
        @w_int                          float,
        @w_monto1                       money,
        @w_monto2                       money,
        @w_moneda                       int,  --pga
        @w_num_dec                      int,  --pga
        @w_fecha_fin                    datetime,   ---EPB:nov-07-2001
        @w_saldo_operacion              char(1),
        @w_plazo_final                  int,
        @w_tasa_efa                     float,
        @w_causacion                    char(1),
        @w_tasa_dia                     float,
        @w_tramite_padre                int,
        @w_operacion_padre              int,
        @w_referencial                  catalogo,
        @w_factorp                      float,
        @w_signop                       char(1)

        

/* CARGA DE VARIABLES INICIALES */
select @w_sp_name   = 'sp_tablafac_batch'


/* DETERMINAR SI USA TASA EQUIVALENTE */ 
select @w_tasa_equivalente = isnull(opt_usar_tequivalente,'N'),
       @w_reajuste         = isnull(opt_reajustable,'N'),
       @w_periodo_int      = isnull(opt_periodo_int,0),
       @w_tipo             = opt_tipo,
       @w_dias_anio        = opt_dias_anio,
       @w_opt_tramite      = opt_tramite,
       @w_moneda           = opt_moneda,   --pga 6nov2001   
       @w_causacion        = opt_causacion
  from ca_operacion_tmp
 where opt_operacion  = @i_operacionca



/* CALCULAR EL MONTO DEL CAPITAL TOTAL */
select @w_saldo_cap = sum(rot_valor)
from ca_rubro_op_tmp
where rot_operacion  = @i_operacionca
and   rot_tipo_rubro = 'C'
and   rot_fpago      in ('P','A','T') -- PERIODICO VENCIDO O ANTICIPADO


/* HEREDAT LA TASA DEL PADRE */


  select   @w_tramite_padre = fa_tramite
           from cob_credito..cr_facturas
           where fa_tram_prov = @i_tramite_hijo
           if @@error != 0 begin
		       --GFP se suprime print
               --PRINT 'tablafab.sp Error al buscar tramite padre  No. trm_hijo' + cast(@i_tramite_hijo as varchar)
               return 710001 
           end

  select @w_operacion_padre  = op_operacion
  from ca_operacion
  where op_tramite = @w_tramite_padre
 
 select  @w_referencial = ro_referencial,
         @w_int         = ro_porcentaje ,
         @w_tasa_efa    = ro_porcentaje_efa,
         @w_signop       = ro_signo,
         @w_factorp      = ro_factor
 from ca_rubro_op
 where ro_operacion = @w_operacion_padre
 and ro_concepto = 'INTDES'
 if @@error != 0 begin
    --GFP se suprime print
    --PRINT 'tablafab.sp Error al heredar tasa de INTDES  No. trm_hijo' + cast(@i_tramite_hijo as varchar)
    return 710001 
 end

update ca_rubro_op_tmp
set  rot_referencial = @w_referencial,
     rot_referencial_reajuste = @w_referencial,
     rot_porcentaje  = @w_int,
     rot_porcentaje_aux = @w_int,
     rot_porcentaje_efa = @w_tasa_efa,
     rot_signo          = @w_signop,
     rot_factor         = @w_factorp
where rot_operacion = @i_operacionca
 and  rot_concepto = 'INTDES'
 if @@error != 0 begin
    --GFP se suprime print
    --PRINT 'tablafab.sp Error al actualizar tasa de INTDES  No. trm_hijo' + cast(@i_tramite_hijo as varchar)
    return 710001 
 end


/* DETERMINAR EL NUMERO DE DIVIDENDOS EXISTENTES */
select @w_num_dividendos = count (*)
  from ca_dividendo_tmp
 where dit_operacion = @i_operacionca

/*FACTOR DE REDONDEO*/
select @w_factor_redondeo = power(10, @i_tipo_redondeo)


exec @w_return = sp_decimales
@i_moneda      = @w_moneda,
@o_decimales   = @w_num_dec out

if @w_return != 0 return @w_return
   
declare cursor_dividendo cursor for
select
dit_dividendo,  dit_fecha_ini,  dit_fecha_ven,
dit_de_capital, dit_de_interes, dit_estado, dit_dias_cuota
from   ca_dividendo_tmp
where  dit_operacion  = @i_operacionca
for read only

open cursor_dividendo

fetch   cursor_dividendo into
@w_dividendo,  @w_di_fecha_ini, @w_di_fecha_ven,
@w_de_capital, @w_de_interes,   @w_estado,       @w_di_num_dias

while @@fetch_status = 0 begin /*WHILE CURSOR PRINCIPAL*/
   if (@@fetch_status = -1) begin
      select @w_error = 710004
      goto ERROR
   end


   /* CURSOR DE RUBROS TABLA CA_RUBRO_OP_TMP */
   declare cursor_rubros cursor for
   select rot_concepto, rot_tipo_rubro, rot_fpago, rot_provisiona,rot_porcentaje,rot_valor, rot_saldo_op,rot_porcentaje_efa
   from   ca_rubro_op_tmp
   where  rot_operacion  = @i_operacionca
   and    rot_fpago      in ('P','A','T') -- PERIODICO VENCIDO O ANTICIPADO
   and    rot_tipo_rubro in ('C','I','V','O','Q') --cap,int,valor,porcentaje
   order by rot_tipo_rubro desc
   for read only

   open    cursor_rubros
   fetch   cursor_rubros into
   @w_concepto, @w_tipo_rubro, @w_fpago,@w_provisiona,@w_int,@w_valor_rubro,@w_saldo_operacion,@w_tasa_efa
   
   while   @@fetch_status = 0 begin /*WHILE CURSOR RUBROS*/
   
      if (@@fetch_status = -1) begin
         select @w_error = 710004
         goto ERROR
      end
     
       select @w_porcentaje = @w_int

      /* RUBROS DE TIPO CAPITAL */
      if @w_tipo_rubro = 'C' begin
         select @w_valor_calc = isnull(fa_valor,0)
         from   cob_credito..cr_facturas
         where  fa_div_hijo =  @w_dividendo and
             fa_tram_prov = @i_tramite_hijo
      end


      /* RUBROS DE TIPO INTERES */
      if @w_tipo_rubro = 'I'  begin      

         select @w_dias_int =    @w_di_num_dias
        
        select @w_monto = isnull(fa_valor,0)
          from cob_credito..cr_facturas
         where fa_div_hijo =  @w_dividendo
         and   fa_tram_prov   = @i_tramite_hijo


        if @w_causacion = 'L'  begin


         --GFP se suprime print
		 /*
         PRINT 'tablafacb.sp Por Batch @w_dias_int  L --->' + cast(@w_di_num_dias as varchar)
         PRINT 'tablafacb.sp Por Batch @w_int L --->' + cast(@w_int as varchar)
         PRINT 'tablafacb.sp Por Batch @w_dias_int L --->' + cast(@w_monto as varchar)
         */


           exec @w_return = sp_calc_intereses
           @operacion = @i_operacionca,
           @tasa      = @w_int,               ---Tasa Nominal
           @monto     = @w_monto,
           @dias_anio = 360,
           @num_dias  = @w_di_num_dias,  
           @causacion = @w_causacion, 
           @intereses = @w_float out
           if @w_return != 0 return @w_return
        end
        else begin
         --GFP se suprime print
		 /*
         PRINT 'tablafacb.sp Por Batch @w_dias_int --->' + cast(@w_dias_int as varchar)
         PRINT 'tablafacb.sp Por Batch @w_tasa_efa --->' + cast(@w_tasa_efa as varchar)
         PRINT 'tablafacb.sp Por Batch @w_dias_int --->' + cast(@w_monto as varchar)
         */


         select @w_tasa_dia =(exp((-@w_dias_int/360)* log(1+((@w_tasa_efa/100.0)/(360/360))))-1)
         select @w_float = (@w_tasa_dia * @w_monto) * - 1
        end
 

         select @w_valor_calc = isnull(@w_float,0) 
         --GFP se suprime print
         --PRINT 'tablafacb.sp Por Batch INTDES --->' + cast(@w_valor_calc as varchar)


      end


      /* RUBROS DE TIPO PORCENTAJE, VALOR */
      if @w_tipo_rubro in ('O','V')  begin
         select @w_valor_calc = isnull(round (@w_valor_rubro,@w_num_dec),0) --pga
      end
      
      /* RUBROS CALCULADOS */
     if @w_tipo_rubro = 'Q'  and @w_saldo_operacion = 'S'  begin
         select @w_valor_rubro = @w_saldo_cap * @w_porcentaje/100
         select @w_valor_calc = round(@w_valor_rubro , @i_num_dec)
      end
      else  if @w_tipo_rubro = 'Q'   begin
         select @w_valor_calc = round(@w_valor_rubro , @i_num_dec)
      end 

      /* SI EL RUBRO NO PROVISIONA, ACUMULADO = CUOTA */
      if @w_provisiona = 'S'
         select  @w_factor = 0
      else
         select  @w_factor = 1

      /* INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP */

      select @w_valor_calc = round(@w_valor_calc, @w_num_dec) --pga


      insert into ca_amortizacion_tmp (
      amt_operacion, amt_dividendo,   amt_concepto, 
      amt_cuota,     amt_gracia,      amt_pagado,
      amt_acumulado, amt_estado,      amt_periodo,
      amt_secuencia)
      values (
      @i_operacionca, @w_dividendo,  @w_concepto,
      @w_valor_calc ,  0,   0,
      @w_valor_calc*@w_factor,     @w_estado,     0,
      1)

      if @@error != 0 return 710001   

      fetch   cursor_rubros into
      @w_concepto, @w_tipo_rubro, @w_fpago,@w_provisiona,@w_int,@w_valor_rubro,@w_saldo_operacion,@w_tasa_efa
   
   end /*WHILE CURSOR RUBROS*/
   close cursor_rubros
   deallocate cursor_rubros

   fetch   cursor_dividendo into
   @w_dividendo,  @w_di_fecha_ini, @w_di_fecha_ven,
   @w_de_capital, @w_de_interes,   @w_estado,        @w_di_num_dias

end /*WHILE CURSOR DIVIDENDOS*/
close cursor_dividendo
deallocate cursor_dividendo

  ---EPB:nov-07-2001

  select @w_fecha_fin = max(dit_fecha_ven)
  from ca_dividendo_tmp
  where dit_operacion = @i_operacionca

 --- PLAZO DE LA OPERACION


select @w_plazo_final = max(datediff(dd,dit_fecha_ini,dit_fecha_ven))
 from ca_dividendo_tmp
where dit_operacion = @i_operacionca

 /* ACTUALIZACION  FECHA DE VENCIMIENTO y PLAZO DE LA OP */
  update ca_operacion_tmp set 
         opt_fecha_fin  = @w_fecha_fin,
         opt_plazo       = @w_plazo_final,
         opt_periodo_cap = @w_plazo_final,
         opt_periodo_int = @w_plazo_final,
         opt_reajustable = 'N',
         opt_periodo_reajuste = 0
  where opt_operacion = @i_operacionca
  if @@error != 0 return  710002





return 0

ERROR:
   return @w_error
 
go

