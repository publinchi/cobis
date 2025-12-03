/************************************************************************/
/*	Archivo:		basecalc.sp				*/
/*	Stored procedure:	sp_base_calculo  			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera		                	*/
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
/*      Obtener el numero exacto de dias a devengar por el proceso batch*/
/*      de fin de dia para las operaciones de base de calculo 30/360    */
/*      Considera a cada mes de 30 dias exactos.                        */
/************************************************************************/
/*				MODIFICACIONES				*/
/*	FECHA		AUTOR		RAZON				*/
/*	26/ABR/1999	Diego Aguilar	Emision inicial			*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_base_calculo')
	drop proc sp_base_calculo
go


create proc sp_base_calculo ( 
	@i_di_fecha_ini		datetime 	= null,
	@i_dias_interes		smallint 	= null,
	@i_di_fecha_ven		datetime 	= null,
	@i_fecha_proceso	datetime 	= null,
        @o_dias_calc            smallint        = null out 

)
as
declare @w_sp_name		descripcion,
	@w_return		int,
        @w_error                int,
        @w_dia_hoy              smallint,
        @w_dia_manana           smallint,
        @w_manana               datetime


/*  Inicializar nombre del stored procedure  */
select	@w_sp_name = 'sp_base_calculo'

select @w_dia_hoy    = datepart(dd,@i_fecha_proceso) 
select @w_manana     = dateadd(dd,1,@i_fecha_proceso) 
select @w_dia_manana = datepart(dd,@w_manana) 

if @w_dia_manana = 1  begin
   if @w_dia_hoy < 30
      select @o_dias_calc = 30 - @w_dia_hoy + 1
   else if @w_dia_hoy > 30
        select @o_dias_calc = 0
   else if @w_dia_hoy = 30
        select @o_dias_calc = 1
end
else
   select @o_dias_calc = isnull(@o_dias_calc,0)
return 0

go
