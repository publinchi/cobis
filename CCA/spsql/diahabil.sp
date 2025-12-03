/************************************************************************/
/*   Archivo:              diahabil.sp                                  */
/*   Stored procedure:     sp_dia_habil                                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Este stored procedure se encarga de verificar que la fecha         */
/*   ingresada sea dia laborable, si no lo es busca el siguiente        */
/*   dia laborable, retorna el dia laborable encontrado                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dia_habil')
   drop proc sp_dia_habil
go

create proc sp_dia_habil
(
   @i_fecha    datetime,
   @i_ciudad   int     =  11001,
   @i_real     char(1) = 'N',
   @o_fecha    datetime out
)
as declare 
   @w_ciudad_nacional  int

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select @o_fecha = @i_fecha
if @i_real = 'N'
begin
   while exists(select 1 from cobis..cl_dias_feriados
                where (df_ciudad = @i_ciudad or df_ciudad = @w_ciudad_nacional)
                and   df_fecha  = @o_fecha)
   begin
      select @o_fecha = dateadd(day,1,@o_fecha)
   end
end
ELSE
begin
   while exists(select 1 from cobis..cl_dias_feriados
                where (df_ciudad = @i_ciudad or df_ciudad = @w_ciudad_nacional)
                and   df_fecha  = @o_fecha
                and   df_real   = 'S')
   begin
      select @o_fecha = dateadd(day,1,@o_fecha)
   end
end

return 0
go

