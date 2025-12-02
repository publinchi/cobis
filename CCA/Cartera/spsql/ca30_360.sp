/************************************************************************/
/*	Archivo:		ca30_360.sp				*/
/*	Stored procedure:	sp_calculo_30_360			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Diego Aguilar				*/
/*	Fecha de escritura:	26/ABR/1999				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA'.							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*      Obtener el numero exacto de dias de la cuota, para las operacion*/
/*      con base de calculo 30/360. Considera a cada mes compuesto por  */
/*      por 30 dias exactos.                                            */
/************************************************************************/
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	26/ABR/1999	Diego Aguilar	Emision inicial			*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calculo_30_360')
	drop proc sp_calculo_30_360
go


create proc sp_calculo_30_360 ( 
	@t_debug		char(1) 	='N',
	@t_file			varchar(14) 	= null,
	@i_fecha_ini		datetime 	= null,
	@i_fecha_ven		datetime 	= null,
	@i_dias_interes		smallint 	= 0,
        @o_dias_int             smallint        = null out 

)
as
declare @w_sp_name		descripcion,
	@w_return		int,
        @w_error                int,
        @w_fecha_aux            datetime,
        @w_fecha_hoy            datetime,
        @w_fecha_1              datetime,
        @w_fecha                datetime,
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
        @w_diferencia           int

/*  Inicializar nombre del stored procedure  */
select	@w_sp_name = 'sp_calculo_30_360'

if @i_dias_interes < 30
begin
   select @o_dias_int = datediff(dd, @i_fecha_ini, @i_fecha_ven)
   return 0
end

select @w_fecha_aux = @i_fecha_ini 
select @w_mes_aux = datepart(mm,@w_fecha_aux) 
select @w_anio_aux = datepart(yy,@w_fecha_aux) 

/*Dias del Periodo*/
select @w_dias_aux = @i_dias_interes

select @w_inicio = 0
select @w_fin_aux = @i_dias_interes / 30
select @w_residuo = @i_dias_interes % 30 

if @w_residuo > 0 
   select @w_fin = @w_fin_aux
else
   select @w_fin = @w_fin_aux - 1

while @w_inicio <= @w_fin begin
    select @w_fecha_1 = convert(varchar(2),@w_mes_aux) + '/01/' + convert(varchar(4),@w_anio_aux)

    select @w_fecha = dateadd(dd,30,@w_fecha_1)
    select @w_mes   = datepart(mm,@w_fecha)

    select @w_dias   = datepart(dd,@w_fecha)

    if @w_mes <= @w_mes_aux --ESTO ES PORQUE PUDO HABER CAMBIADO DE ANIO 
       select @w_num_dias = @w_dias_aux - 1
    else begin
     select @w_diferencia = @w_dias - 1
        select @w_num_dias = @w_dias_aux + @w_diferencia
   end

    select @w_fecha_aux = dateadd(mm,1,@w_fecha_aux)
    select @w_mes_aux = datepart(mm,@w_fecha_aux)
    select @w_anio_aux = datepart(yy,@w_fecha_aux)
    select @w_dias_aux = @w_num_dias

    select @w_inicio = @w_inicio + 1


end 

 select @o_dias_int = isnull(@w_dias_aux,0)
 return 0

go
