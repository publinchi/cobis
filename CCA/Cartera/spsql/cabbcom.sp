/************************************************************************/
/*	Archivo:		    cabaseco.sp				                        */
/*	Stored procedure:	sp_calculo_comercial			                */
/*	Base de datos:		cob_cartera				                        */
/*	Producto: 		    Credito y Cartera			                    */
/*	Disenado por:  		Diego Aguilar				                    */
/*	Fecha de escritura:	26/ABR/1999				                        */
/************************************************************************/
/*				IMPORTANTE				                                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	'MACOSA'.							                                */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				PROPOSITO				                                */
/*      Obtener el numero exacto de dias de la cuota, para las operacion*/
/*      con base de calculo 30/360. Considera a cada mes compuesto por  */
/*      por 30 dias exactos.                                            */
/************************************************************************/
/*				MODIFICACIONES				                            */
/*	FECHA		AUTOR		  RAZON				                        */
/*  - - -       N/R           Emisión Inicial                           */
/*  21/02/2021  K. Rodríguez  Días dividendo de tipos no divisibles a 30*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calculo_comercial')
	drop proc sp_calculo_comercial
go


create proc sp_calculo_comercial ( 
	@t_debug		char(1) 	='N',
	@t_file			varchar(14) 	= null,
	@i_fecha_ini_op		datetime 	= null,
        @i_tdividendo           char(1)         = null,
	@i_di_fecha_ini		datetime 	= null,
	@i_dias_interes		smallint 	= 0,
        @o_dias_int             smallint        = null out,
	@o_fecha_ven		datetime 	= null out
)
as
declare @w_sp_name		descripcion,
	@w_return		int,
        @w_error                int,
        @w_fecha_aux            datetime,
        @w_fecha_hoy            datetime,
        @w_fecha_1              datetime,
        @w_fecha                datetime,
	@w_fecha_mas		datetime,
        @w_mes_aux              smallint,
        @w_mes                  smallint,
        @w_mes_fin              smallint,
        @w_fin                  smallint,
        @w_fin_aux              smallint,
        @w_residuo              smallint,
        @w_inicio               smallint,
        @w_anio_aux             smallint,
        @w_dias_aux             int,
        @w_num_dias             int,
        @w_dias                 int,
        @w_diferencia           int,
	@w_meses                varchar(60),
	@w_mes_1		int,
        @w_dia_inicio           int,
        @w_dias_mes             int,
	@w_dia_venc             int,
	@w_dif			int,
	@w_dias_max_mes		int

/*  Inicializar nombre del stored procedure  */
select	@w_sp_name = 'sp_calculo_comercial',
        @w_meses   = '312831303130313130313031'	

select @w_dia_venc = datepart(dd,@i_fecha_ini_op) 


/*Dias del Periodo*/
select @w_dias_aux = @i_dias_interes

select @w_inicio = 0
select @w_fin_aux = @i_dias_interes / 30
select @w_residuo = @i_dias_interes % 30 

if @w_residuo > 0
   select @w_fin = @w_fin_aux
else
   select @w_fin = @w_fin_aux - 1

select @w_fecha_aux = @i_di_fecha_ini 
select @w_mes_aux = datepart(mm,@w_fecha_aux) 
select @w_dias_aux = datepart(dd,@w_fecha_aux) 
select @w_anio_aux = datepart(yy,@w_fecha_aux) 

if @i_tdividendo = 'D' or @i_dias_interes % 30 <> 0   -- KDR 21/02/2021 Para el cálculo de tipo dividendos no divisibles para 30 (35D)
   select @w_fin = 0

if @w_fin = 0 begin

   if @w_mes_aux = 2 begin
     --if datepart(yy,@i_di_fecha_ini) % 4 = 0
     if @w_anio_aux % 4 = 0 
        select @w_dias_mes = 29
     else
        select @w_dias_mes = 28
   end
   else
     select @w_dias_mes = convert(int,substring(@w_meses,(@w_mes_aux * 2) - 1,2))

   select @w_dias_max_mes = @w_dias_mes	 

   if @i_dias_interes - (@w_dias_mes - @w_dias_aux) > 0 begin

      select @w_dif = @i_dias_interes - (@w_dias_mes - @w_dias_aux)

      select @w_mes_1 = datepart(mm,dateadd(mm,1,@w_fecha_aux))    	
      select @w_fecha_1 = convert(varchar(2),@w_mes_aux) + '/' + 
                          convert(varchar(2),@w_dias_max_mes) + '/' + 
                          convert(varchar(4),@w_anio_aux)
      select @w_fecha_aux = dateadd(dd,@w_dif,@w_fecha_1) 
   end
   else
      select @w_fecha_aux = dateadd(dd,@i_dias_interes,@w_fecha_aux) 

      select @o_fecha_ven = @w_fecha_aux

   return 0
end

  

while @w_inicio <= @w_fin  begin

  select @w_mes_aux = datepart(mm,dateadd(mm,1,@w_fecha_aux)) 
  select @w_anio_aux = datepart(yy,dateadd(mm,1,@w_fecha_aux)) 

  if @w_mes_aux = 2 begin
     if @w_anio_aux % 4 = 0
        select @w_dias_mes = 29
     else
        select @w_dias_mes = 28
  end
  else
    select @w_dias_mes = convert(int,substring(@w_meses,(@w_mes_aux * 2) - 1,2))


  select @w_dia_inicio = @w_dia_venc


  if @w_dia_inicio > @w_dias_mes 
     select @w_dia_inicio = @w_dia_inicio - (@w_dia_inicio - @w_dias_mes)


  select @w_fecha_1 = convert(varchar(2),@w_mes_aux) + '/' + convert(varchar(2),@w_dia_inicio) + '/' 
         + convert(varchar(4),@w_anio_aux)


    select @w_fecha_aux = @w_fecha_1
    select @w_mes_aux = datepart(mm,@w_fecha_aux)
    select @w_anio_aux = datepart(yy,@w_fecha_aux)

    select @w_inicio = @w_inicio + 1


end /* end While */
 
 select @o_fecha_ven = @w_fecha_aux
 return 0

go
