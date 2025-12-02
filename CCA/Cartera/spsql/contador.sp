/************************************************************************/
/*	Archivo:		contador.sp				*/
/*	Stored procedure:	sp_contador 				*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Elcira Pelaez				*/
/*	Fecha de escritura:	2003	 				*/
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
/*	con una fecha enviada y una ciudad, valida cuantos feriados     */
/*      existen antes de esta						*/
/*                              ACTUALIZACIONES                         */
/*                              		                        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_contador')
   drop proc sp_contador
go

create proc sp_contador
@i_fecha_proceso	datetime,
@i_ciudad               int,
@o_contador 		int  out             

as

declare
@w_return        	int,
@w_fecha_proceso    	datetime,
@w_contador             int,
@w_salir                char(1)


/*INICIALIZACION VARIABLES */

select @w_fecha_proceso = dateadd(dd,+1,@i_fecha_proceso),
       @w_salir = 'S',
       @w_contador = 0


while @w_salir = 'S'  begin

      /* CUENTA DIAS CONTRA EL CALENDARIO NACIONAL */
      if exists(select 1 from cobis..cl_dias_feriados
                where df_fecha  = @w_fecha_proceso
                and   df_ciudad = @i_ciudad) begin
                select @w_contador = @w_contador + 1
                select @w_fecha_proceso = dateadd(dd,+1,@w_fecha_proceso)
      end else
          select @w_salir = 'N'

end 


select @o_contador  = @w_contador

return 0
go

