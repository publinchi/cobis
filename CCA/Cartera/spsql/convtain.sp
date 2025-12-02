/************************************************************************/
/*   NOMBRE LOGICO:      convtain.sp                                    */
/*   NOMBRE FISICO:      sp_conversion_tasas_int                        */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Christian De la Cruz                           */
/*   FECHA DE ESCRITURA: Mar. 1998                                      */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/  
/*                              PROPOSITO                               */
/* Conversion de la tasa de interes de una operacion de Cartera         */
/* entre sus diferentes periodicidades y modalidades                    */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*   FECHA           AUTOR             RAZON                            */  
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_conversion_tasas_int')
	drop proc sp_conversion_tasas_int
go
create proc sp_conversion_tasas_int
@i_periodo_o		char(1) ,
@i_modalidad_o	        char(1) ,
@i_periodo_d		char(10) ,
@i_tasa_o		float ,
@i_modalidad_d	        char(1) ,
@i_num_periodo_o	smallint = 1,
@i_num_periodo_d	smallint = 1,
@i_dias_anio            smallint = 360,
@i_base_calculo         char(1)  = 'P',
@i_dias_periodo_d       int      = 0,
@i_num_dec              tinyint  = 6,
@o_tasa_d               float    = null output

as
declare 
@w_sp_name		descripcion,
@w_tasa_o		float,
@w_periodo_o		float,
@w_periodo_d		float,
@w_dias_periodo_o	float,
@w_dias_periodo_d	float,
@w_tasa_d		float,
@w_tasa_d1		float,
@w_tasa_anticipada	float,
@w_tasa_vencida 	float,
@w_modalidad_o 		char(1),
@w_modalidad_d 		char(1),
@w_dias_base_calc       int, 
@w_error		int,
@w_aux1                 float,
@w_aux2                 float,
@w_anual                char(1),
@w_dias_periodo_d1      float

/* CARGAR VALORES INICIALES */
select @w_sp_name = 'sp_conversion_tasas_int'
select @i_num_dec = isnull(@i_num_dec,6)


/* PRINT 'convtain.sp datos que llegan No. 1 @i_periodo_o:  '+ @i_periodo_o +
				' @i_modalidad_o: ' + @i_modalidad_o+
				' @i_periodo_d: '  + @i_periodo_d	+
				' @i_tasa_o: '     + cast(@i_tasa_o		as varchar) +
				' @i_modalidad_d '+ cast(@i_modalidad_d	as varchar)

PRINT 'convtain.sp datos que llegan  No.2 @i_num_periodo_o: '+ cast(@i_num_periodo_o		as varchar) +
				' @i_num_periodo_d: '+ cast(@i_num_periodo_d		as varchar) +
				' @i_dias_anio: ' + cast(@i_dias_anio   	as varchar)+
				' @i_base_calculo: '+ cast(@i_base_calculo 	as varchar)+
				' @i_dias_periodo_d: '+ cast(@i_dias_periodo_d   	as varchar)  */

/*XMA NR_501*/
if @i_dias_anio is null  or @i_dias_anio = 0
   select @i_dias_anio = 365
/*NR501*/



if @i_modalidad_o = 'T'
   select @i_modalidad_o = 'V'

if @i_modalidad_d = 'T'
   select @i_modalidad_d = 'V'

if @i_num_periodo_o = 0
   select @i_num_periodo_o = 1
  
if @i_num_periodo_d = 0
   select @i_num_periodo_d = 1

select @w_dias_periodo_o = td_factor*@i_num_periodo_o 
from cob_cartera..ca_tdividendo  with (nolock)
where td_tdividendo = @i_periodo_o

if @@rowcount = 0 begin      
   select @w_error = 701000     
   goto ERROR                   
end                             


if @i_dias_periodo_d <= 0
   select @w_dias_periodo_d = td_factor*@i_num_periodo_d
   from cob_cartera..ca_tdividendo with (nolock)
   where td_tdividendo = @i_periodo_d
else
   select @w_dias_periodo_d = @i_dias_periodo_d

if @@rowcount = 0 begin         
   select @w_error = 701000     
   goto ERROR                   
end                             

/*PARAMETRO ANUAL */
select @w_anual = pa_char
from cobis..cl_parametro with (nolock)
where pa_nemonico = 'PAN'
and   pa_producto = 'CCA'
set transaction isolation level read uncommitted


/*MODALIDAD VENCIDO A VENCIDO*/
if (@i_modalidad_o = 'V' and @i_modalidad_d = 'V')begin

   select @w_tasa_d =(exp((@w_dias_periodo_d/@w_dias_periodo_o)*
                  log(1+((@i_tasa_o/100)/(@i_dias_anio/@w_dias_periodo_o))))-1)*(@i_dias_anio/@w_dias_periodo_d)


end


/*MODALIDAD ANTICIPADO A ANTICIPADO*/
if (@i_modalidad_o = 'A' and @i_modalidad_d = 'A') begin


   /* CONTROL DE LOGARITMO NEGATIVO */
   select @w_aux1 = 1-((@i_tasa_o/100)/(@i_dias_anio/@w_dias_periodo_o))
   select @w_aux2 = (@w_dias_periodo_d/@w_dias_periodo_o)

   if @w_aux1 > 0 begin
      select @w_tasa_d = (1 - exp(@w_aux2 * log(@w_aux1))) *
      (@i_dias_anio/@w_dias_periodo_d)
   end
   if (@w_aux1 < 0) and (floor(@w_aux2/2)= (@w_aux2/2)) begin
      select @w_tasa_d = (1 - exp(@w_aux2 * log(-1 * @w_aux1))) *
      (@i_dias_anio/@w_dias_periodo_d)
   end
   if (@w_aux1 <0) and (floor(@w_aux2/2) != (@w_aux2/2)) and (floor (@w_aux2)) = @w_aux2 begin
      select @w_tasa_d = (1 - exp(@w_aux2 *
                          -1 * log(@w_aux1))) *
                          (@i_dias_anio/@w_dias_periodo_d)
   end
   if (@w_aux1<0) and (floor(@w_aux2/2) != (@w_aux2/2)) and (floor (@w_aux2)) != @w_aux2   or (@w_aux1 = 0) begin
      select @w_error = 710098     
      goto ERROR
   end

end 

/*MODALIDAD VENCIDO A ANTICIPADO*/
if (@i_modalidad_o = 'V' and @i_modalidad_d = 'A') begin

  
   select @w_tasa_d = exp((@i_dias_anio/@w_dias_periodo_o)*
                    log(1+((@i_tasa_o/100)/(@i_dias_anio/@w_dias_periodo_o))))-1

   select @w_tasa_d = 100*@w_tasa_d

   /*PASO DE ANUAL VENCIDO A ANUAL ANTICIPADO*/
   select @w_tasa_anticipada = (1 - (1/(1+(@w_tasa_d/100))))*100
   select @w_tasa_o = round(@w_tasa_anticipada,@i_num_dec)

  
   /*PASO DE ANUAL ANTICIPADO A TASA DESTINO*/
   /*DIAS DE PERIODICIDAD ANUAL*/
   select @w_dias_periodo_o = td_factor
   from cob_cartera..ca_tdividendo with (nolock)
   where td_tdividendo = @w_anual


   /* CONTROL DE LOGARITMO NEGATIVO */
   select @w_aux1 = 1-((@w_tasa_o/100)/(@i_dias_anio/@w_dias_periodo_o))
   select @w_aux2 = (@w_dias_periodo_d/@w_dias_periodo_o)


   if @w_aux1 > 0 begin
      select @w_tasa_d = (1 - exp(@w_aux2 *
                          log(@w_aux1))) *
                          (@i_dias_anio/@w_dias_periodo_d)
   end

   if (@w_aux1 < 0) and (floor(@w_aux2/2))= (@w_aux2/2) begin
      select @w_tasa_d = (1 - exp(@w_aux2 *
                          log(-1 * @w_aux1))) *
                          (@i_dias_anio/@w_dias_periodo_d)
   end

   if (@w_aux1<0) and (floor(@w_aux2/2)) != (@w_aux2/2)  and 
   floor (@w_aux2) = @w_aux2 begin
      select @w_tasa_d = (1 - exp(@w_aux2 *
                          -1 * log(@w_aux1))) *
                          (@i_dias_anio/@w_dias_periodo_d)
   end
 
   if (@w_aux1)<0 and (floor(@w_aux2/2))!=(@w_aux2/2) and (floor(@w_aux2))!=@w_aux2 
      or @w_aux1 = 0 begin
      return 710098
   end

end 

/*MODALIDAD ANTICIPADO A VENCIDO*/

if (@i_modalidad_o = 'A' and @i_modalidad_d = 'V') begin


   /* CONTROL DE LOGARITMO NEGATIVO */
   select @w_aux1 = 1-((@i_tasa_o/100)/(@i_dias_anio/@w_dias_periodo_o))
   select @w_aux2 = (@i_dias_anio/@w_dias_periodo_o)

   if @w_aux1 > 0 begin
      select @w_tasa_d = (1 - exp(@w_aux2 * log(@w_aux1))) 
   end
   if (@w_aux1 < 0) and (floor(@w_aux2/2))= (@w_aux2/2)    begin
      select @w_tasa_d = (1 - exp(@w_aux2 *
                          log(-1 * @w_aux1))) *
                          (@i_dias_anio/@w_dias_periodo_d)
   end
   if (@w_aux1 < 0) and (floor(@w_aux2/2)) != (@w_aux2/2)  and (floor (@w_aux2)) = @w_aux2  begin
      select @w_tasa_d = (1 - exp(@w_aux2 *
                          -1 * log(@w_aux1))) *
                          (@i_dias_anio/@w_dias_periodo_d)
   end
   if (@w_aux1 < 0) and (floor(@w_aux2/2)) != (@w_aux2/2) and (floor (@w_aux2)) != @w_aux2 or (@w_aux1 = 0)  begin
      return 710098
   end

   select @w_tasa_d = 100*@w_tasa_d

   /*PASO DE ANUAL ANTICIPADO A ANUAL VENCIDO */
   select @w_tasa_vencida = ((1/(1-(@w_tasa_d/100)))-1)*100
 
   /*PASO DE ANUAL VENCIDO A TASA DESTINO*/
   select @w_tasa_o = @w_tasa_vencida/100
   select @w_tasa_d = (exp((@w_dias_periodo_d/@i_dias_anio)*
                      log(1+(@w_tasa_o/(1))))-1)*
                      (@i_dias_anio/@w_dias_periodo_d)


end 

if @i_num_dec is not null
   select @w_tasa_d = round(100*@w_tasa_d,@i_num_dec) 
else
   select @w_tasa_d = round(100*@w_tasa_d,6)

select @o_tasa_d = @w_tasa_d

return 0

ERROR:                                    
                                          
return @w_error                           
                                          
go
