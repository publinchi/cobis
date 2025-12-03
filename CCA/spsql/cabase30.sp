/************************************************************************/
/*	Archivo:		cabase30.sp				*/
/*	Stored procedure:	sp_dias_base_comercial			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Diego Aguilar				*/
/*	Fecha de escritura:	10/JUL/1999				*/
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
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dias_base_comercial')
	drop proc sp_dias_base_comercial
go


create proc sp_dias_base_comercial ( 
	@t_debug		char(1) 	='N',
	@t_file			varchar(14) 	= null,
        @i_opcion               char(1)         = 'D',
	@i_fecha_ini		datetime 	= null,
	@i_fecha_ven		datetime 	= null,
        @i_dividendo            int             = 1,
        @i_fecha_pri_cuota      datetime        = null,
        @i_suma_dias            int             = 0,
	@i_dia_fijo		tinyint		= 0,
        @o_dias_int             smallint        = 0 out,
        @o_fecha_ven            datetime        = null out 

)
as
declare @w_sp_name		descripcion,
	@w_return		int,
        @w_error                int,
        @w_dias_count           int,
        @w_fecha_aux            datetime,
        @w_fecha_sig            datetime, 
        @w_fecha_start          datetime,
        @w_fecha_end            datetime,
        @w_paso                 smallint,
        @w_max_div              int

/*  Inicializar nombre del stored procedure  */
select	@w_sp_name = 'sp_dias_base_comercial'

if @i_opcion = 'D' begin

   select @w_dias_count = 0,
          @w_fecha_aux = @i_fecha_ini,
          @w_fecha_start = @i_fecha_ini,
          @w_fecha_end = @i_fecha_ven,
          @w_paso = 0



if @i_fecha_pri_cuota is not null
   select @w_max_div = 2
else
   select @w_max_div = 1

if @i_dia_fijo > 0
   if datepart(mm,@i_fecha_ini) = 2 and datepart(dd,@i_fecha_ini) >= 28
      if datepart(dd, dateadd(dd, 1, @i_fecha_ini)) = 1
	 if @i_dia_fijo > datepart(dd, @i_fecha_ini)
		select @w_max_div = 1
      

if datepart(dd,@i_fecha_ini) >= 30 begin
   select @w_fecha_aux = dateadd(mm,1,@i_fecha_ini)
   select @i_fecha_ini = convert(char(2),datepart(mm,@w_fecha_aux)) + '/01/' + convert(char(4),datepart(yy,@w_fecha_aux))
end
else
   --CONTROL DE ANIO BISIESTO PARA FEBRERO
   if datepart(mm,@i_fecha_ini) = 2 and datepart(dd,@i_fecha_ini) >= 28 begin
      if @i_dividendo <= @w_max_div
      	 select @w_dias_count=@w_dias_count + (30 - datepart(dd,@i_fecha_ini))
      select @w_fecha_aux = dateadd(mm,1,@i_fecha_ini)
      select @i_fecha_ini = convert(char(2),datepart(mm,@w_fecha_aux)) + '/01/' + convert(char(4),datepart(yy,@w_fecha_aux))
   end
   else
      select @i_fecha_ini = dateadd(dd,1,@i_fecha_ini)

      
   while @i_fecha_ini <= @i_fecha_ven begin

      if datepart(dd,@i_fecha_ini) <= 30
         select @w_dias_count = @w_dias_count + 1

      if datepart(mm,@i_fecha_ini) = 2 begin
         if (datepart(yy,@i_fecha_ini) % 4 ) = 0 begin
            if datepart(dd,@i_fecha_ini) = 29
               select @w_dias_count=@w_dias_count + 1
         end
         else begin
            if datepart(dd,@i_fecha_ini) = 28 begin
               select @w_dias_count = @w_dias_count + 2
            end
         end
      end

      select @i_fecha_ini = dateadd(dd,1,@i_fecha_ini)

   end

   select @o_dias_int = isnull(@w_dias_count,0)
end

if @i_opcion = 'F' begin
   select @w_dias_count = 0,
          @w_fecha_aux  = @i_fecha_ini,
          @w_fecha_sig  = @i_fecha_ini


   while @w_dias_count < @i_suma_dias begin

      select @w_fecha_sig = dateadd(dd,1,@w_fecha_sig) 

      if datepart(dd,@w_fecha_sig) <= 30 begin
         select @w_dias_count = @w_dias_count + 1 

        if datepart(mm,@w_fecha_sig) = 2 begin
           if (datepart(yy,@w_fecha_sig) % 4) = 0 begin
              if datepart(dd,@w_fecha_sig) = 29 begin
                 select @w_dias_count = @w_dias_count + 1
              end 
              else begin
                if datepart(dd,@w_fecha_sig) = 28
                   select @w_dias_count = @w_dias_count + 2
              end
           end
        end      

        select @w_fecha_aux = @w_fecha_sig
      end
      else
        select @w_fecha_sig = dateadd(dd,1,@w_fecha_sig) 
      
   end

   select @o_fecha_ven = @w_fecha_aux
end

return 0

go
